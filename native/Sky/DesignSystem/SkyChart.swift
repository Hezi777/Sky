import SwiftUI
import Charts

// The one time-series chart in Sky. Weather's hourly curve and the Stocks
// sparkline are the same chart at two densities — they were duplicated before
// this type existed, and drifted apart.
//
// House rules baked in so no caller has to remember them:
// • Shape-preserving interpolation. `.catmullRom` overshoots between points and
//   invents highs and lows the data never had, which on a price series is a
//   plain misstatement. `.monotone` stays smooth without inventing extrema.
// • A 10% area wash under a 2pt line — never a saturated block.
// • Solid hairline gridlines. A dashed grid reads as a threshold or projection
//   when it is only a grid.
// • Text never wears the series color; the colored mark beside it carries
//   identity.

/// One point on a Sky time series.
struct SkyChartPoint: Identifiable, Equatable {
    let index: Int
    let value: Double
    /// Axis / tooltip label for this position ("2 PM", "10:30").
    let label: String

    var id: Int { index }

    init(index: Int, value: Double, label: String = "") {
        self.index = index
        self.value = value
        self.label = label
    }
}

/// Area + line time series with a pointer-tracking readout.
///
/// The readout **enhances and never gates**: every value it shows is also
/// reachable from the axis ticks, the widget's own summary values, and the
/// accessibility value below.
struct SkyChart: View {
    /// How much chrome the chart carries. A sparkline is the same marks with
    /// the axes and readout stripped — it rides inside a row that already names
    /// the value, so a second copy of the number would be noise.
    enum Density {
        case sparkline
        case full
    }

    let points: [SkyChartPoint]
    var tint: Color = Tokens.accent
    var density: Density = .full
    /// Position of a reference rule ("now" on a forecast). Nil draws none.
    var referenceIndex: Int?
    var referenceLabel: String = "Now"
    /// Renders a value for the axis and the readout.
    var format: (Double) -> String = { $0.formatted(.number.precision(.fractionLength(0))) }
    /// Spoken description of the series as a whole.
    var accessibilityDescription: String = "Time series"

    @State private var selection: SkyChartPoint?

    private var values: [Double] { points.map(\.value) }

    /// Padded domain so the curve never touches the frame edge.
    private var domain: ClosedRange<Double> {
        let lo = values.min() ?? 0
        let hi = values.max() ?? 1
        let pad = max((hi - lo) * Tokens.Chart.domainPaddingFraction, Tokens.Chart.minimumDomainPadding)
        return (lo - pad)...(hi + pad)
    }

    var body: some View {
        chart
            .chartYScale(domain: domain)
            .chartLegend(.hidden)
            .animation(Tokens.Chart.dataChangeAnimation, value: points)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityDescription)
            .accessibilityValue(accessibilitySummary)
    }

    @ViewBuilder
    private var chart: some View {
        switch density {
        case .sparkline:
            marks
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
        case .full:
            marks
                .chartXAxis { xAxis }
                .chartYAxis { yAxis }
                .chartOverlay { proxy in scrubOverlay(proxy: proxy) }
        }
    }

    // MARK: Marks

    private var marks: some View {
        Chart {
            ForEach(points) { point in
                AreaMark(
                    x: .value("Position", point.index),
                    yStart: .value("Floor", domain.lowerBound),
                    yEnd: .value("Value", point.value)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            tint.opacity(Tokens.Chart.areaOpacityTop),
                            tint.opacity(Tokens.Chart.areaOpacityBottom),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Position", point.index),
                    y: .value("Value", point.value)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(tint)
                .lineStyle(StrokeStyle(lineWidth: Tokens.Chart.lineWidth, lineCap: .round, lineJoin: .round))
            }

            if let referenceIndex, density == .full {
                RuleMark(x: .value("Reference", referenceIndex))
                    .foregroundStyle(.secondary.opacity(Tokens.Chart.crosshairOpacity))
                    .lineStyle(StrokeStyle(lineWidth: Tokens.Chart.crosshairWidth))
                    .annotation(
                        position: .top,
                        alignment: .center,
                        spacing: Tokens.extraTight,
                        // Keep the label inside the plot instead of letting it
                        // run under the y-axis ticks.
                        overflowResolution: .init(x: .fit(to: .plot), y: .disabled)
                    ) {
                        Text(referenceLabel)
                            .font(Tokens.Font.microLabel)
                            .foregroundStyle(.tertiary)
                    }
            }

            if let selection {
                RuleMark(x: .value("Selected", selection.index))
                    .foregroundStyle(.secondary.opacity(Tokens.Chart.crosshairOpacity))
                    .lineStyle(StrokeStyle(lineWidth: Tokens.Chart.crosshairWidth))

                // Ring first, marker on top: the ring is surface-colored so the
                // dot stays legible where it sits on the line.
                PointMark(
                    x: .value("Selected", selection.index),
                    y: .value("Value", selection.value)
                )
                .symbolSize(markerArea(diameter: Tokens.Chart.markerSize + Tokens.Chart.markerRingWidth * 2))
                .foregroundStyle(Tokens.cardFill)

                PointMark(
                    x: .value("Selected", selection.index),
                    y: .value("Value", selection.value)
                )
                .symbolSize(markerArea(diameter: Tokens.Chart.markerSize))
                .foregroundStyle(tint)
            }
        }
    }

    private func markerArea(diameter: CGFloat) -> CGFloat {
        let radius = diameter / 2
        return .pi * radius * radius
    }

    // MARK: Axes

    /// Roughly four ticks, landing on real positions so every label has a point.
    private var tickPositions: [Int] {
        guard !points.isEmpty else { return [] }
        let step = max(points.count / 4, 1)
        return stride(from: 0, to: points.count, by: step).map { points[$0].index }
    }

    private var xAxis: some AxisContent {
        AxisMarks(values: tickPositions) { value in
            AxisValueLabel {
                if let index = value.as(Int.self), let point = points.first(where: { $0.index == index }) {
                    Text(point.label)
                        .font(Tokens.Chart.axisFont)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var yAxis: some AxisContent {
        AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
            AxisValueLabel {
                if let raw = value.as(Double.self) {
                    Text(format(raw))
                        .font(Tokens.Chart.axisFont)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }
            // Solid hairline, one step off the surface. Never dashed.
            AxisGridLine(stroke: StrokeStyle(lineWidth: Tokens.Chart.gridWidth))
                .foregroundStyle(.quaternary)
        }
    }

    // MARK: Scrub

    /// Pointer tracking only — no drag gesture. The dashboard grid owns drag for
    /// moving widgets, and a chart-local `DragGesture` would race it.
    private func scrubOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        withAnimation(Tokens.Chart.scrubAnimation) {
                            selection = nearestPoint(to: location, proxy: proxy, geometry: geometry)
                        }
                    case .ended:
                        withAnimation(Tokens.Chart.scrubAnimation) { selection = nil }
                    }
                }
                .overlay(alignment: .topLeading) {
                    if let selection {
                        readout(for: selection, proxy: proxy, geometry: geometry)
                    }
                }
        }
    }

    /// Snap to the nearest position so the reader aims at a time, not at a line.
    private func nearestPoint(
        to location: CGPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) -> SkyChartPoint? {
        guard let plotFrame = proxy.plotFrame else { return nil }
        let plot = geometry[plotFrame]
        guard plot.contains(location) else { return nil }
        guard let raw = proxy.value(atX: location.x - plot.minX, as: Double.self) else { return nil }
        return points.min { lhs, rhs in
            abs(Double(lhs.index) - raw) < abs(Double(rhs.index) - raw)
        }
    }

    /// Value leads, label follows — the reader already has the series and wants
    /// the number. The series is keyed by a short stroke of its own color; the
    /// text itself stays in ink tokens.
    private func readout(
        for point: SkyChartPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) -> some View {
        let plot = proxy.plotFrame.map { geometry[$0] } ?? .zero
        let x = proxy.position(forX: point.index).map { $0 + plot.minX } ?? plot.midX

        return VStack(alignment: .leading, spacing: Tokens.microSpacing) {
            HStack(spacing: Tokens.tight) {
                Capsule()
                    .fill(tint)
                    .frame(width: Tokens.Size.legendLineKey, height: Tokens.Chart.lineWidth)
                Text(format(point.value))
                    .font(Tokens.Font.rowTrailingValue)
                    .foregroundStyle(.primary)
            }
            if !point.label.isEmpty {
                Text(point.label)
                    .font(Tokens.Font.microLabel)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, Tokens.compact)
        .padding(.vertical, Tokens.tight)
        .background(
            RoundedRectangle(cornerRadius: Tokens.compactRadius, style: .continuous)
                .fill(Tokens.cardFill)
                .shadow(color: Tokens.cardShadowColor, radius: Tokens.smallRadius, y: Tokens.microSpacing)
        )
        .fixedSize()
        .alignmentGuide(.leading) { $0.width / 2 - x }
        .allowsHitTesting(false)
    }

    // MARK: Accessibility

    /// Every value the readout can show is reachable here without a pointer.
    private var accessibilitySummary: String {
        guard let low = values.min(), let high = values.max(), let last = values.last else {
            return "No data"
        }
        return "Now \(format(last)), ranging \(format(low)) to \(format(high)) across \(points.count) points"
    }
}
