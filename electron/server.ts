import fs from "node:fs";
import http from "node:http";
import net from "node:net";
import path from "node:path";
import { app, dialog, utilityProcess } from "electron";

const PREFERRED_PORT = 21847;
const READY_TIMEOUT_MS = 20_000;
const READY_POLL_INTERVAL_MS = 250;

/** Resolve an available port: prefer PREFERRED_PORT, fall back to a random free port. */
function getAvailablePort(): Promise<number> {
  return new Promise((resolve, reject) => {
    const tester = net.createServer();
    tester.unref();
    tester.on("error", () => {
      const fallback = net.createServer();
      fallback.unref();
      fallback.on("error", reject);
      fallback.listen(0, "127.0.0.1", () => {
        const address = fallback.address();
        const port = typeof address === "object" && address ? address.port : PREFERRED_PORT;
        fallback.close(() => resolve(port));
      });
    });
    tester.listen(PREFERRED_PORT, "127.0.0.1", () => {
      tester.close(() => resolve(PREFERRED_PORT));
    });
  });
}

/** Poll the server until it responds with any HTTP status, or time out. */
function waitForServerReady(port: number): Promise<void> {
  return new Promise((resolve, reject) => {
    const startTime = Date.now();

    const poll = (): void => {
      const request = http.get(`http://127.0.0.1:${port}/`, (response) => {
        response.resume();
        resolve();
      });

      request.on("error", () => {
        if (Date.now() - startTime >= READY_TIMEOUT_MS) {
          reject(new Error("Server did not become ready in time"));
          return;
        }
        setTimeout(poll, READY_POLL_INTERVAL_MS);
      });
    };

    poll();
  });
}

/** Spawn the standalone Next.js server as a utility process and wait for it to be ready. */
export async function startServer(
  parsedEnv: Record<string, string>,
): Promise<{ port: number; child: Electron.UtilityProcess }> {
  const port = await getAvailablePort();
  const standaloneDir = path.join(process.resourcesPath, "standalone");
  const serverPath = path.join(standaloneDir, "server.js");

  const logsDir = path.join(app.getPath("userData"), "logs");
  fs.mkdirSync(logsDir, { recursive: true });
  const logStream = fs.createWriteStream(path.join(logsDir, "sky-server.log"), { flags: "a" });

  const child = utilityProcess.fork(serverPath, [], {
    cwd: standaloneDir,
    stdio: "pipe",
    env: {
      ...process.env,
      ...parsedEnv,
      PORT: String(port),
      HOSTNAME: "127.0.0.1",
      NODE_ENV: "production",
    },
  });

  child.stdout?.pipe(logStream);
  child.stderr?.pipe(logStream);

  app.on("before-quit", () => {
    child.kill();
  });

  try {
    await waitForServerReady(port);
  } catch {
    dialog.showErrorBox(
      "Sky - Server Error",
      `The server failed to start in time.\n\nCheck the log file for details:\n${path.join(logsDir, "sky-server.log")}`,
    );
    app.quit();
    throw new Error("Server failed to become ready");
  }

  return { port, child };
}
