import SwiftUI
import UniformTypeIdentifiers

struct FairWidget: View {
    @Environment(DashboardStore.self) private var store
    @Environment(FairStore.self) private var fairStore

    @State private var showingAdd = false
    @State private var showingSettings = false

    private var effectivePrice: Double? {
        if let manual = fairStore.config.manualPrice { return manual }
        if case .loaded(let fair) = store.fair { return fair.price }
        return nil
    }

    private var priceMode: PriceMode {
        if fairStore.config.manualPrice != nil { return .manual }
        if case .loaded = store.fair { return .live }
        return .none
    }

    private var liveFair: FairPrice? {
        if case .loaded(let fair) = store.fair { return fair }
        return nil
    }

    var body: some View {
        WidgetShell(title: "Fund", symbol: "building.columns", tint: Tokens.accent) {
            toolbarButtons
        } content: {
            if showingSettings {
                settingsForm
            } else if showingAdd {
                addTransactionForm
            } else if fairStore.config.contributions.isEmpty {
                emptyState
            } else {
                mainContent
            }
        }
        .task(id: fairStore.config.fundNumber) {
            await store.load(.fair, force: true, fairFund: fairStore.config.fundNumber)
        }
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var toolbarButtons: some View {
        HStack(spacing: Tokens.tight) {
            GlassButton(
                systemImage: showingAdd ? "xmark" : "plus",
                accessibilityLabel: showingAdd ? "Close add transaction" : "Add transaction"
            ) {
                showingSettings = false
                showingAdd.toggle()
            }
            GlassButton(
                systemImage: showingSettings ? "xmark" : "gearshape",
                accessibilityLabel: showingSettings ? "Close settings" : "Fund settings"
            ) {
                showingAdd = false
                showingSettings.toggle()
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Tokens.rowSpacing) {
            Text("Start tracking Fair")
                .font(Tokens.Font.bodyRowStrong)
            Text("Add your first contribution to track your DCA investment.")
                .font(Tokens.Font.caption)
                .foregroundStyle(.secondary)
            GlassButton("Add contribution", systemImage: "plus") {
                showingAdd = true
            }
            .accessibilityLabel("Add first contribution")

            priceLine
        }
    }

    // MARK: - Main content

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
            // Fund subtitle
            Text("\(fairStore.config.fundName) · \(fairStore.config.fundNumber)")
                .font(Tokens.Font.caption)
                .foregroundStyle(.secondary)

            // Value headline
            if let price = effectivePrice {
                let currentValue = fairStore.value(at: price)
                Text(currentValue, format: .currency(code: "ILS").precision(.fractionLength(0)))
                    .font(.system(.title, design: .rounded).weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: currentValue))
                    .animation(.snappy, value: currentValue)
                    .accessibilityLabel("Current value")
                    .accessibilityValue(
                        currentValue.formatted(.currency(code: "ILS").precision(.fractionLength(0)))
                    )
            } else {
                Text("—")
                    .font(.system(.title, design: .rounded).weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            // Invested + gain row
            HStack(spacing: Tokens.rowSpacing) {
                VStack(alignment: .leading, spacing: Tokens.microSpacing) {
                    Text("Invested")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(fairStore.invested, format: .currency(code: "ILS").precision(.fractionLength(0)))
                        .font(Tokens.Font.bodyRowStrong)
                        .monospacedDigit()
                }

                if let price = effectivePrice, let pct = fairStore.gainPercent(at: price) {
                    let gainVal = fairStore.gain(at: price)
                    VStack(alignment: .leading, spacing: Tokens.microSpacing) {
                        Text("Gain")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        HStack(spacing: Tokens.extraTight) {
                            Image(systemName: gainVal >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption2.weight(.semibold))
                            Text(pct / 100, format: .percent.precision(.fractionLength(2)))
                                .font(Tokens.Font.bodyRowStrong)
                                .monospacedDigit()
                        }
                        .foregroundStyle(gainVal >= 0 ? Tokens.positive : Tokens.negative)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Gain")
                        .accessibilityValue(
                            "\(gainVal >= 0 ? "plus" : "minus") \(abs(pct).formatted(.number.precision(.fractionLength(2)))) percent"
                        )
                    }
                }
            }

            priceLine

            // Contributions list
            contributionsList
        }
    }

    // MARK: - Price line

    private var priceLine: some View {
        HStack(spacing: Tokens.snug) {
            switch priceMode {
            case .none:
                HStack(spacing: Tokens.tight) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Tokens.warning)
                    Text("No price — set manual in settings")
                }
                .font(Tokens.Font.caption)
                .foregroundStyle(.secondary)

            case .manual, .live:
                if let price = effectivePrice {
                    Text(symbol(for: liveFair?.currency ?? "ILS"))
                        .font(Tokens.Font.bodyRow)
                        .foregroundStyle(.secondary)
                    Text(price, format: .number.precision(.fractionLength(2)))
                        .font(Tokens.Font.bodyRowStrong)
                        .monospacedDigit()
                    Text("/ unit")
                        .font(Tokens.Font.caption)
                        .foregroundStyle(.tertiary)

                    Text(priceMode == .manual ? "manual" : "live")
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, Tokens.headerSpacing)
                        .padding(.vertical, Tokens.extraTight)
                        .background(.secondary.opacity(0.12), in: Capsule())
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: Tokens.tight)

                if priceMode == .live, let fair = liveFair, let asOf = asOfText(fair.asOf) {
                    Text("\(fair.source) · \(asOf)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Text("\(fairStore.units.formatted(.number.precision(.fractionLength(4)))) units")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Unit price")
    }

    // MARK: - Contributions list

    private var contributionsList: some View {
        let sorted = fairStore.config.contributions.sorted { $0.date > $1.date }
        return VStack(alignment: .leading, spacing: Tokens.compact) {
            Text("Contributions")
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            ForEach(sorted) { contrib in
                HStack(spacing: Tokens.compact) {
                    Text(contrib.date)
                        .font(Tokens.Font.caption)
                        .lineLimit(1)
                    Spacer(minLength: Tokens.tight)
                    Text(contrib.amount, format: .currency(code: "ILS").precision(.fractionLength(0)))
                        .font(Tokens.Font.bodyRow)
                        .monospacedDigit()
                    Text("\(contrib.units.formatted(.number.precision(.fractionLength(4)))) u")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Button {
                        fairStore.remove(id: contrib.id)
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove contribution on \(contrib.date)")
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    // MARK: - Add transaction form

    private var addTransactionForm: some View {
        AddTransactionFormView(fairStore: fairStore) {
            showingAdd = false
        }
    }

    // MARK: - Settings form

    private var settingsForm: some View {
        SettingsFormView(fairStore: fairStore)
    }

    // MARK: - Helpers

    private func symbol(for currency: String) -> String {
        switch currency.uppercased() {
        case "ILS": "₪"
        case "USD": "$"
        case "EUR": "€"
        case "GBP": "£"
        default: "\(currency) "
        }
    }

    private func asOfText(_ iso: String) -> String? {
        guard let date = ISO8601DateFormatter.parse(iso) else { return nil }
        return "as of \(date.formatted(date: .abbreviated, time: .omitted))"
    }

    private enum PriceMode { case manual, live, none }
}

// MARK: - Add Transaction Form

private struct AddTransactionFormView: View {
    let fairStore: FairStore
    let onDone: () -> Void

    @State private var date = Date.now
    @State private var amountText = ""
    @State private var unitsText = ""
    @State private var buyPriceText = ""

    private var canAdd: Bool {
        guard let amt = Double(amountText), amt > 0 else { return false }
        if let u = Double(unitsText), u > 0 { return true }
        if let bp = Double(buyPriceText), bp > 0 { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.rowSpacing) {
            Text("Add transaction")
                .font(Tokens.Font.bodyRowStrong)

            DatePicker("Date", selection: $date, displayedComponents: .date)
                .labelsHidden()
                .accessibilityLabel("Transaction date")

            TextField("Amount invested ₪", text: $amountText)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Amount invested in shekels")
            #if os(iOS)
                .keyboardType(.decimalPad)
            #endif

            HStack(spacing: Tokens.snug) {
                TextField("Units bought", text: $unitsText)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Units bought")
                #if os(iOS)
                    .keyboardType(.decimalPad)
                #endif
                TextField("…or buy price ₪", text: $buyPriceText)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Buy price per unit in shekels")
                #if os(iOS)
                    .keyboardType(.decimalPad)
                #endif
            }

            HStack(spacing: Tokens.snug) {
                GlassButton("Add", systemImage: "plus") {
                    addContribution()
                }
                .disabled(!canAdd)

                GlassButton("Cancel") {
                    onDone()
                }
            }

            Text("Enter units directly, or a buy price to compute units = amount ÷ price.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func addContribution() {
        guard let amt = Double(amountText), amt > 0 else { return }

        var resolvedUnits: Double
        if let u = Double(unitsText), u > 0 {
            resolvedUnits = u
        } else if let bp = Double(buyPriceText), bp > 0 {
            resolvedUnits = amt / bp
        } else {
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let contribution = FairContribution(
            id: UUID().uuidString,
            date: formatter.string(from: date),
            amount: amt,
            units: resolvedUnits
        )
        fairStore.add(contribution: contribution)
        onDone()
    }
}

// MARK: - Settings Form

private struct SettingsFormView: View {
    let fairStore: FairStore

    @State private var fundNumber: String
    @State private var fundName: String
    @State private var manualPriceText: String
    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var importError: String?

    init(fairStore: FairStore) {
        self.fairStore = fairStore
        _fundNumber = State(initialValue: fairStore.config.fundNumber)
        _fundName = State(initialValue: fairStore.config.fundName)
        _manualPriceText = State(
            initialValue: fairStore.config.manualPrice.map { String($0) } ?? ""
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.rowSpacing) {
            Text("Fund settings")
                .font(Tokens.Font.bodyRowStrong)

            HStack(spacing: Tokens.snug) {
                TextField("Fund number", text: $fundNumber)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Fund number")
                #if os(iOS)
                    .keyboardType(.numberPad)
                #endif
                TextField("Fund name", text: $fundName)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Fund name")
            }

            HStack(spacing: Tokens.snug) {
                TextField("Manual price ₪ (optional)", text: $manualPriceText)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Manual override price in shekels")
                #if os(iOS)
                    .keyboardType(.decimalPad)
                #endif
                if fairStore.config.manualPrice != nil {
                    GlassButton("Clear") {
                        manualPriceText = ""
                        fairStore.updateConfig(manualPrice: .some(nil))
                    }
                }
            }

            GlassButton("Save fund", systemImage: "checkmark") {
                saveFund()
            }

            Text("Set a manual price to override the live Maya/TASE price.")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Divider()

            // Import / Export
            HStack(spacing: Tokens.snug) {
                GlassButton("Export", systemImage: "square.and.arrow.up") {
                    showingExporter = true
                }
                .accessibilityLabel("Export fund data as JSON")

                GlassButton("Import", systemImage: "square.and.arrow.down") {
                    showingImporter = true
                }
                .accessibilityLabel("Import fund data from JSON")
            }

            if let importError {
                Text(importError)
                    .font(.caption2)
                    .foregroundStyle(Tokens.negative)
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: JSONDocument(data: fairStore.exportJSON()),
            contentType: .json,
            defaultFilename: "fair-config.json"
        ) { _ in }
    }

    private func saveFund() {
        let trimmedNum = fundNumber.trimmingCharacters(in: .whitespaces)
        let num = trimmedNum.allSatisfy(\.isNumber) && !trimmedNum.isEmpty ? trimmedNum : nil
        let name = fundName.trimmingCharacters(in: .whitespaces)
        let manual = Double(manualPriceText.trimmingCharacters(in: .whitespaces))
        let resolvedManual: Double?? = manualPriceText.trimmingCharacters(in: .whitespaces).isEmpty
            ? .some(nil)
            : (manual.map { $0 > 0 ? .some($0) : .some(nil) } ?? .none)

        fairStore.updateConfig(
            fundNumber: num,
            fundName: name.isEmpty ? nil : name,
            manualPrice: resolvedManual
        )
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        importError = nil
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                importError = "Could not access file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                let data = try Data(contentsOf: url)
                try fairStore.importJSON(data)
            } catch {
                importError = "Invalid JSON: \(error.localizedDescription)"
            }
        case .failure(let error):
            importError = error.localizedDescription
        }
    }
}

// MARK: - JSON File Document (for export)

private struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
