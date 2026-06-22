import SwiftUI

#if os(macOS)
import UniformTypeIdentifiers
#endif

struct EnvironmentImportOnboardingStep: View {
    let model: OnboardingModel

    var body: some View {
        #if os(macOS)
        MacEnvironmentImportSection(model: model)
        #else
        RemoteIntegrationsUnavailableSection()
        #endif
    }
}

#if os(macOS)
private struct MacEnvironmentImportSection: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
            Text("Import your integrations")
                .font(.title2.weight(.semibold))
            Text("Choose an existing .env or .env.local file. Sky imports only recognized settings and stores each value separately in Keychain.")
                .foregroundStyle(.secondary)
            Button("Choose .env file") {
                model.isFileImporterPresented = true
            }
            .buttonStyle(.borderedProminent)
            .fileImporter(
                isPresented: $model.isFileImporterPresented,
                allowedContentTypes: [.item]
            ) { result in
                if case .success(let url) = result {
                    model.importFile(at: url)
                } else {
                    model.markImportFailed()
                }
            }
            EnvironmentImportResultSection(
                importedCount: model.importResult?.importedKeyNames.count,
                ignoredCount: model.importResult?.ignoredKeyNames.count,
                invalidLineCount: model.importResult?.invalidLineNumbers.count,
                importFailed: model.importFailed
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EnvironmentImportResultSection: View {
    let importedCount: Int?
    let ignoredCount: Int?
    let invalidLineCount: Int?
    let importFailed: Bool

    var body: some View {
        if let importedCount {
            Label("Imported \(importedCount) settings.", systemImage: "checkmark.circle.fill")
                .foregroundStyle(Tokens.positive)
            if let ignoredCount, ignoredCount > 0 {
                Text("Ignored \(ignoredCount) unrecognized settings.")
                    .foregroundStyle(.secondary)
            }
            if let invalidLineCount, invalidLineCount > 0 {
                Text("Skipped \(invalidLineCount) lines that weren’t valid assignments.")
                    .foregroundStyle(.secondary)
            }
        } else if importFailed {
            Label("Sky couldn’t read that file.", systemImage: "exclamationmark.triangle")
                .foregroundStyle(Tokens.negative)
        }
    }
}
#endif

struct RemoteIntegrationsUnavailableSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
            Label("Remote integrations are unavailable on iPhone and iPad", systemImage: "iphone.slash")
                .font(.title2.weight(.semibold))
            Text("This version of Sky doesn’t connect to the local backend, so there is no remote integration setup on iOS.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
