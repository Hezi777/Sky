# SwiftUI 2026 Cheatsheet (iOS 26 / macOS 26 Tahoe)

Xcode 26, Swift 6.x. All APIs verified against Apple documentation as of June 2025 (WWDC25).

---

## 1. Liquid Glass

> Refs: [Applying Liquid Glass](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views) | [Glass type](https://developer.apple.com/documentation/swiftui/glass) | [GlassEffectContainer](https://developer.apple.com/documentation/swiftui/glasseffectcontainer) | [glassEffect(\_:in:)](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)) | [backgroundExtensionEffect()](https://developer.apple.com/documentation/SwiftUI/View/backgroundExtensionEffect())

### Core modifier

```swift
.glassEffect(_ glass: Glass = .regular, in shape: some Shape = .rect, isEnabled: Bool = true)
```

- **`Glass` styles**: `.regular` (default translucent), `.clear`, `.identity`
- **Tint**: `.regular.tint(.blue)` or `.regular.tint(.red.opacity(0.3))`
- **Interactive** (iOS -- bounce/shimmer on touch): `.regular.interactive()`
- Combine: `.regular.tint(.blue).interactive()`

### Button styles

```swift
Button("Save") { }
    .buttonStyle(.glass)           // standard glass button

Button("Primary") { }
    .buttonStyle(.glassProminent)  // higher-visibility glass
```

### GlassEffectContainer

Groups nearby glass elements so they share sampling (glass cannot sample other glass).

```swift
GlassEffectContainer(spacing: 12) {
    HStack(spacing: 12) {
        // child views with .glassEffect(...)
    }
}
```

### glassEffectID + @Namespace (morphing)

Animate glass between states. Assign the same `glassEffectID` string to indicate "same logical element."

```swift
@Namespace private var ns

// inside body
ForEach(tabs.indices, id: \.self) { i in
    Button(tabs[i]) { withAnimation(.smooth) { selected = i } }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glassEffect(
            selected == i
                ? .regular.tint(.accentColor.opacity(0.4)).interactive()
                : .regular.interactive(),
            in: .capsule
        )
        .glassEffectID(selected == i ? "active" : "tab\(i)", in: ns)
}
```

### backgroundExtensionEffect

Mirrors + blurs a view to fill safe-area edges behind toolbars/sidebars.

```swift
NavigationSplitView {
    SidebarView()
} detail: {
    DetailImage()
        .backgroundExtensionEffect()   // image bleeds under sidebar
}
```

Conditional variant: `.backgroundExtensionEffect(isEnabled: showEffect)`

### macOS-specific

- **Toolbars adopt glass automatically** when built with Xcode 26. Toolbar items in the same `ToolbarItemGroup` share a glass container.
- Set window-level background: `.containerBackground(.ultraThinMaterial, for: .window)` or use a color/gradient.
- Sidebars get floating Liquid Glass on macOS 26 by default.

### Snippet: Glass card

```swift
struct GlassCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weather").font(.headline)
            Text("22 C, Sunny").font(.title2)
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}
```

### Snippet: Glass toolbar button

```swift
struct ToolbarButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 44, height: 44)
        }
        .glassEffect(.regular.interactive(), in: .circle)
    }
}
```

### Snippet: Glass segmented control

```swift
struct GlassSegments: View {
    @Binding var selection: Int
    let labels: [String]
    @Namespace private var ns

    var body: some View {
        GlassEffectContainer(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(labels.indices, id: \.self) { i in
                    Button(labels[i]) {
                        withAnimation(.smooth) { selection = i }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .glassEffect(
                        selection == i
                            ? .regular.tint(.accentColor.opacity(0.4)).interactive()
                            : .regular.interactive(),
                        in: .capsule
                    )
                    .glassEffectID(
                        selection == i ? "selected" : "opt\(i)", in: ns
                    )
                }
            }
            .padding(4)
        }
    }
}
```

### Backward compatibility helper

```swift
extension View {
    @ViewBuilder
    func glassOrMaterial(
        _ glass: Glass = .regular,
        in shape: some Shape = .rect,
        fallback: Material = .ultraThinMaterial
    ) -> some View {
        if #available(iOS 26, macOS 26, *) {
            self.glassEffect(glass, in: shape)
        } else {
            self.background(fallback, in: shape)
        }
    }
}
```

---

## 2. Swift Charts -- Apple-style polish

> Refs: [Swift Charts](https://developer.apple.com/documentation/Charts) | [SectorMark](https://developer.apple.com/documentation/charts/sectormark) | [InterpolationMethod](https://developer.apple.com/documentation/charts/interpolationmethod) | [chartLegend(\_:)](https://developer.apple.com/documentation/swiftui/view/chartlegend(_:)) | [chartYAxis(\_:)](https://developer.apple.com/documentation/swiftui/view/chartyaxis(_:))

### Key modifiers for minimal/clean look

```swift
Chart { ... }
    .chartXAxis(.hidden)                    // hide x axis
    .chartYAxis(.hidden)                    // hide y axis
    .chartLegend(.hidden)                   // hide legend
    .chartPlotStyle { plot in
        plot.frame(height: 200)
    }
```

Minimal grid (y only):

```swift
.chartYAxis {
    AxisMarks { AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)) }
}
.chartXAxis {
    AxisMarks { AxisValueLabel() }          // labels only, no grid
}
```

### Gradient fill (Apple Health / Fitness style)

Use `AreaMark` behind a `LineMark`, both with `.interpolationMethod(.catmullRom)`:

```swift
Chart(dataPoints) { pt in
    AreaMark(
        x: .value("Time", pt.date),
        y: .value("Value", pt.value)
    )
    .foregroundStyle(
        .linearGradient(
            colors: [.blue.opacity(0.3), .blue.opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
        )
    )
    .interpolationMethod(.catmullRom)

    LineMark(
        x: .value("Time", pt.date),
        y: .value("Value", pt.value)
    )
    .foregroundStyle(.blue)
    .lineStyle(StrokeStyle(lineWidth: 2))
    .interpolationMethod(.catmullRom)
}
.chartXAxis(.hidden)
.chartYAxis(.hidden)
.chartLegend(.hidden)
```

### Rounded bar corners

```swift
BarMark(
    x: .value("Day", item.day),
    y: .value("Steps", item.steps)
)
.cornerRadius(6, style: .continuous)
.foregroundStyle(
    .linearGradient(
        colors: [Color("BarBottom"), .accentColor],
        startPoint: .bottom,
        endPoint: .top
    )
)
```

### Donut / ring chart

```swift
Chart(categories, id: \.name) { cat in
    SectorMark(
        angle: .value("Amount", cat.value),
        innerRadius: .ratio(0.618),
        angularInset: 1.5
    )
    .cornerRadius(5)
    .foregroundStyle(by: .value("Category", cat.name))
}
.chartLegend(.hidden)
.frame(width: 200, height: 200)
```

- `innerRadius: .ratio(0.618)` -- golden-ratio hole makes it a donut.
- `angularInset: 1.5` -- small gap between sectors.
- `.cornerRadius(5)` -- rounded sector edges.

### Rolling number animation

```swift
Text("\(value, format: .number)")
    .font(.largeTitle.monospacedDigit())
    .contentTransition(.numericText(countsDown: false))
    .animation(.snappy, value: value)
```

Variants: `.numericText()`, `.numericText(countsDown:)`, `.numericText(value:)`.

---

## 3. App architecture (2026 patterns)

> Refs: [@Observable](https://developer.apple.com/documentation/Observation/Observable()) | [@State with Observable](https://developer.apple.com/documentation/SwiftUI/State) | [@Environment with Observable](https://developer.apple.com/documentation/swiftui/environment)

### @Observable store

```swift
import Observation

@Observable
class DashboardStore {
    var weather: WeatherData?
    var isLoading = false
    var error: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let (data, _) = try await URLSession.shared.data(from: weatherURL)
            weather = try JSONDecoder().decode(WeatherData.self, from: data)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
```

### Wiring: @State owns it, .environment passes it

```swift
@main
struct SkyApp: App {
    @State private var store = DashboardStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}

struct ContentView: View {
    @Environment(DashboardStore.self) private var store

    var body: some View {
        // store.weather etc. -- auto-tracks changes
    }
}
```

### Async data loading

```swift
struct WeatherCard: View {
    @Environment(DashboardStore.self) private var store

    var body: some View {
        Group {
            if store.isLoading {
                ProgressView()
            } else if let w = store.weather {
                Text("\(w.temp, format: .number) C")
            }
        }
        .task { await store.load() }   // cancelled on disappear
    }
}
```

### URLSession JSON pattern

```swift
func fetch<T: Decodable>(_ url: URL) async throws -> T {
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }
    return try JSONDecoder().decode(T.self, from: data)
}
```

---

## 4. Multiplatform layout (macOS + iOS)

### NavigationSplitView vs NavigationStack

```swift
struct RootView: View {
    @State private var selectedTab: Tab? = .weather

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            SidebarList(selection: $selectedTab)
        } detail: {
            DetailView(tab: selectedTab)
                .backgroundExtensionEffect()
        }
        #else
        NavigationStack {
            DashboardGrid()
        }
        #endif
    }
}
```

Or use `NavigationSplitView` on both and let iPadOS/macOS show the sidebar while iPhone collapses it.

### Adaptive card grid with LazyVGrid

```swift
struct DashboardGrid: View {
    // 2-column on compact, 3+ on regular
    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 300, maximum: 500))]
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                WeatherCard()
                CalendarCard()
                TasksCard()
                // ...
            }
            .padding()
        }
    }
}
```

`GridItem(.adaptive(minimum:maximum:))` reflows automatically based on available width -- works across iPhone, iPad, and macOS windows.

### Size classes (if needed)

```swift
@Environment(\.horizontalSizeClass) private var sizeClass

var body: some View {
    if sizeClass == .compact {
        // single column
    } else {
        // multi column
    }
}
```

Note: `horizontalSizeClass` is available on iOS/iPadOS. On macOS it is always `.regular`.

### Platform-conditional frame

```swift
.frame(
    minWidth: 300,
    idealWidth: 400,
    maxWidth: .infinity,
    minHeight: 200
)
```

---

## Quick reference table

| What | API |
|---|---|
| Glass on any view | `.glassEffect(.regular, in: .capsule)` |
| Interactive glass (iOS) | `.glassEffect(.regular.interactive(), in: .circle)` |
| Tinted glass | `.glassEffect(.regular.tint(.blue))` |
| Glass button | `.buttonStyle(.glass)` / `.buttonStyle(.glassProminent)` |
| Glass container | `GlassEffectContainer(spacing:) { }` |
| Glass morph | `.glassEffectID("id", in: namespace)` |
| Background extension | `.backgroundExtensionEffect()` |
| Window background (macOS) | `.containerBackground(.ultraThinMaterial, for: .window)` |
| Hide chart axis | `.chartXAxis(.hidden)` / `.chartYAxis(.hidden)` |
| Hide legend | `.chartLegend(.hidden)` |
| Smooth line | `.interpolationMethod(.catmullRom)` |
| Donut chart | `SectorMark(angle:, innerRadius: .ratio(0.618), angularInset: 1.5)` |
| Rolling numbers | `.contentTransition(.numericText())` |
| Observable store | `@Observable class Store { }` |
| Inject store | `@State private var s = Store()` + `.environment(s)` |
| Read store | `@Environment(Store.self) private var store` |
| Async load | `.task { await store.load() }` |
| Adaptive grid | `LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))])` |
