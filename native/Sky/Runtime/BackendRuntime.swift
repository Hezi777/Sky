import Foundation
import Observation

#if os(macOS)
import Darwin
#endif

private final class RedactingLogWriter: @unchecked Sendable {
    private let lock = NSLock()
    private let handle: FileHandle
    private let secrets: [[UInt8]]
    private let replacement = Array("[REDACTED]".utf8)
    private var pending: [UInt8] = []
    private var isClosed = false

    init(url: URL, secrets: [String]) throws {
        handle = try FileHandle(forWritingTo: url)
        try handle.seekToEnd()
        self.secrets = secrets
            .filter { $0.utf8.count >= 4 }
            .map { Array($0.utf8) }
            .sorted { $0.count > $1.count }
    }

    func write(_ data: Data) {
        guard !data.isEmpty else { return }
        lock.lock()
        defer { lock.unlock() }
        guard !isClosed else { return }
        pending.append(contentsOf: data)
        drain(flush: false)
    }

    func close() {
        lock.lock()
        defer { lock.unlock() }
        guard !isClosed else { return }
        drain(flush: true)
        try? handle.close()
        isClosed = true
    }

    private func drain(flush: Bool) {
        let retainedByteCount = flush ? 0 : max(0, (secrets.first?.count ?? 1) - 1)
        let safeStartLimit = pending.count - min(pending.count, retainedByteCount)
        guard safeStartLimit > 0 else { return }

        var output: [UInt8] = []
        var index = 0
        while index < safeStartLimit {
            if let secret = secrets.first(where: { candidate in
                let end = index + candidate.count
                return end <= pending.count && pending[index..<end].elementsEqual(candidate)
            }) {
                output.append(contentsOf: replacement)
                index += secret.count
            } else {
                output.append(pending[index])
                index += 1
            }
        }

        if !output.isEmpty {
            try? handle.write(contentsOf: Data(output))
        }
        pending.removeFirst(index)
    }
}

enum BackendRuntimeState: Equatable {
    case idle
    case starting
    case ready(URL)
    case failed(String)
    case disabled

    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }
}

@MainActor
@Observable
final class BackendRuntime {
    private(set) var state: BackendRuntimeState
    private(set) var logURL: URL?

    #if os(macOS)
    private var launchGeneration = 0
    private var process: Process?
    private var logPipe: Pipe?
    private var logWriter: RedactingLogWriter?
    #endif

    init() {
        #if os(macOS)
        state = .idle
        #else
        state = .disabled
        #endif
    }

    func start(environment: [String: String]) async {
        #if os(macOS)
        launchGeneration += 1
        let generation = launchGeneration
        stopActiveProcess()
        state = .starting

        do {
            let resources = try resourcePaths()
            let port = try availablePort()
            let log = try prepareLogFile()
            let pipe = Pipe()
            let writer = try RedactingLogWriter(url: log, secrets: Array(environment.values))
            pipe.fileHandleForReading.readabilityHandler = { handle in
                writer.write(handle.availableData)
            }

            let child = Process()
            child.executableURL = resources.node
            child.arguments = [resources.server.path]
            child.currentDirectoryURL = resources.root
            child.standardOutput = pipe
            child.standardError = pipe
            child.terminationHandler = { [weak self, weak child] terminatedProcess in
                guard let child else { return }
                Task { @MainActor [weak self] in
                    self?.processDidExit(child, status: terminatedProcess.terminationStatus)
                }
            }

            let parentEnvironment = ProcessInfo.processInfo.environment
            var childEnvironment = [
                "HOME": parentEnvironment["HOME"] ?? NSHomeDirectory(),
                "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
                "TMPDIR": parentEnvironment["TMPDIR"] ?? NSTemporaryDirectory(),
            ]
            for (key, value) in environment {
                childEnvironment[key] = value
            }
            childEnvironment["PORT"] = String(port)
            childEnvironment["HOSTNAME"] = "127.0.0.1"
            childEnvironment["NODE_ENV"] = "production"
            child.environment = childEnvironment

            try child.run()
            process = child
            logPipe = pipe
            logWriter = writer
            logURL = log

            let origin = URL(string: "http://127.0.0.1:\(port)")!
            try await waitUntilReady(origin: origin, process: child)
            guard generation == launchGeneration, process === child else { return }
            APIClient.shared.configure(baseURL: origin)
            state = .ready(origin)
        } catch {
            guard generation == launchGeneration else { return }
            stopActiveProcess()
            state = error is CancellationError ? .idle : .failed(error.localizedDescription)
        }
        #else
        state = .disabled
        #endif
    }

    func restart(environment: [String: String]) async {
        await start(environment: environment)
    }

    /// Marks the runtime "ready" without spawning the bundled backend process
    /// or configuring `APIClient` with a real base URL. Only used by
    /// `DemoMode`, so the UI renders as if data is available while every
    /// widget's data actually comes from `DashboardStore.loadDemoFixtures()`.
    func enableDemo() {
        state = .ready(URL(string: "http://demo.invalid")!)
    }

    func stop() {
        #if os(macOS)
        launchGeneration += 1
        stopActiveProcess()
        state = .idle
        #endif
    }

    #if os(macOS)
    private func stopActiveProcess() {
        APIClient.shared.configure(baseURL: nil)
        let child = process
        process = nil
        if let child, child.isRunning {
            child.terminate()
        }
        clearLoggingResources()
    }
    private struct ResourcePaths {
        let node: URL
        let server: URL
        let root: URL
    }

    private func processDidExit(_ child: Process, status: Int32) {
        guard process === child else { return }
        process = nil
        APIClient.shared.configure(baseURL: nil)
        clearLoggingResources()
        state = .failed(RuntimeError.exited(status).localizedDescription)
    }

    private func clearLoggingResources() {
        logPipe?.fileHandleForReading.readabilityHandler = nil
        logPipe = nil
        logWriter?.close()
        logWriter = nil
    }

    private enum RuntimeError: LocalizedError {
        case missingResource(String)
        case noPort
        case exited(Int32)
        case readinessTimeout

        var errorDescription: String? {
            switch self {
            case .missingResource(let path): "Bundled backend resource is missing: \(path)"
            case .noPort: "Could not reserve a local backend port."
            case .exited(let status): "The local backend exited with status \(status)."
            case .readinessTimeout: "The local backend did not become ready in time."
            }
        }
    }

    private func resourcePaths() throws -> ResourcePaths {
        guard let resources = Bundle.main.resourceURL else {
            throw RuntimeError.missingResource("Resources")
        }
        let root = resources.appendingPathComponent("SkyBackend", isDirectory: true)
        let node = root.appendingPathComponent("node")
        let serverRoot = root.appendingPathComponent("server", isDirectory: true)
        let server = serverRoot.appendingPathComponent("server.js")
        guard FileManager.default.isExecutableFile(atPath: node.path) else {
            throw RuntimeError.missingResource("SkyBackend/node")
        }
        guard FileManager.default.fileExists(atPath: server.path) else {
            throw RuntimeError.missingResource("SkyBackend/server/server.js")
        }
        return ResourcePaths(node: node, server: server, root: serverRoot)
    }

    private func availablePort() throws -> UInt16 {
        let descriptor = socket(AF_INET, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw RuntimeError.noPort }
        defer { close(descriptor) }

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = in_port_t(0)
        address.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))

        let bindResult = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(descriptor, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindResult == 0 else { throw RuntimeError.noPort }

        var resolved = sockaddr_in()
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let nameResult = withUnsafeMutablePointer(to: &resolved) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                getsockname(descriptor, $0, &length)
            }
        }
        guard nameResult == 0 else { throw RuntimeError.noPort }
        return UInt16(bigEndian: resolved.sin_port)
    }

    private func prepareLogFile() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent("Sky/Logs", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("backend.log")
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        return url
    }

    private func waitUntilReady(origin: URL, process: Process) async throws {
        let healthURL = origin.appendingPathComponent("api/health")
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(20))

        while clock.now < deadline {
            guard process.isRunning else { throw RuntimeError.exited(process.terminationStatus) }
            if let (_, response) = try? await URLSession.shared.data(from: healthURL),
               let http = response as? HTTPURLResponse,
               http.statusCode == 200 {
                return
            }
            try await Task.sleep(for: .milliseconds(250))
        }
        throw RuntimeError.readinessTimeout
    }
    #endif
}
