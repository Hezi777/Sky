import SwiftUI
import Charts

struct WeatherWidget: View {
    @Environment(\.widgetSize) private var size
    @State private var location = LocationProvider()
    @State private var weather: OpenMeteoResponse?
    @State private var errorMessage: String?

    var body: some View {
        WidgetShell(title: "Weather", symbol: "cloud.sun", tint: Tokens.accent) {
            if !DemoMode.isEnabled, let err = location.error ?? errorMessage {
                WidgetError(message: err) {
                    Task { await fetchWeather() }
                }
            } else if let w = weather {
                WeatherContent(
                    size: size,
                    placeName: location.placeName ?? "Current Location",
                    current: w.current,
                    daily: w.daily,
                    hourly: w.hourly
                )
            } else {
                WidgetLoading()
            }
        }
        .task {
            if DemoMode.isEnabled {
                location.placeName = DemoFixtures.weatherPlaceName
                weather = DemoFixtures.weather
                return
            }
            location.start()
            await fetchWeather()
        }
    }

    private func fetchWeather() async {
        errorMessage = nil
        // Wait for coordinates
        for _ in 0..<50 {
            if location.coordinate != nil || location.error != nil { break }
            try? await Task.sleep(for: .milliseconds(100))
        }
        guard let coord = location.coordinate else { return }

        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(coord.latitude)&longitude=\(coord.longitude)&current=temperature_2m,weather_code,apparent_temperature&hourly=temperature_2m&forecast_hours=24&daily=temperature_2m_max,temperature_2m_min&timezone=auto"
        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            weather = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Content

private struct WeatherContent: View {
    let size: WidgetSize
    let placeName: String
    let current: OpenMeteoCurrent
    let daily: OpenMeteoDaily
    let hourly: OpenMeteoHourly?

    var body: some View {
        switch size {
        case .small:
            WeatherCompact(current: current)
        case .medium, .large:
            VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
                WeatherSummary(
                    placeName: placeName,
                    current: current,
                    daily: daily
                )
                if let hourly, hourly.temperature2m.count > 1 {
                    // Medium shares one row with the summary, so the curve drops
                    // its axes rather than being cropped by the card. Large has
                    // room for the full chart.
                    HourlyTempChart(
                        temps: hourly.temperature2m,
                        times: hourly.time,
                        density: size == .large ? .full : .sparkline
                    )
                    // Large lets the curve take the height the summary doesn't
                    // need, so the tile doesn't end in dead space.
                    .frame(
                        minHeight: size == .large
                            ? Tokens.Size.weatherChartExpandedHeight
                            : Tokens.Size.weatherChartHeight,
                        maxHeight: size == .large
                            ? .infinity
                            : Tokens.Size.weatherChartHeight
                    )
                }
            }
        }
    }
}

/// Small: icon + current temp + condition only.
private struct WeatherCompact: View {
    let current: OpenMeteoCurrent

    var body: some View {
        HStack(spacing: Tokens.snug) {
            Image(systemName: weatherSymbol(for: current.weatherCode))
                .font(Tokens.Font.primaryValue(size: 22, weight: .regular))
                .foregroundStyle(Tokens.accent)
                .symbolRenderingMode(.hierarchical)

            VStack(alignment: .leading, spacing: Tokens.extraTight) {
                Text("\(Int(current.temperature2m.rounded()))°")
                    .font(Tokens.Font.primaryValue(size: 36, weight: .thin))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text(weatherCondition(for: current.weatherCode))
                    .font(Tokens.Font.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Int(current.temperature2m.rounded()))°, \(weatherCondition(for: current.weatherCode))")
    }
}

private struct WeatherSummary: View {
    let placeName: String
    let current: OpenMeteoCurrent
    let daily: OpenMeteoDaily

    var body: some View {
        HStack(alignment: .top, spacing: Tokens.wideSpacing) {
            VStack(alignment: .leading, spacing: Tokens.tight) {
                Text(placeName)
                    .font(Tokens.Font.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("\(Int(current.temperature2m.rounded()))°")
                    .font(Tokens.Font.primaryValue(size: 48, weight: .thin))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Label {
                    Text("Feels like \(Int(current.apparentTemperature.rounded()))°")
                } icon: {
                    Image(systemName: "thermometer.variable")
                }
                .font(Tokens.Font.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: Tokens.snug)

            VStack(alignment: .trailing, spacing: Tokens.snug) {
                Image(systemName: weatherSymbol(for: current.weatherCode))
                    .font(Tokens.Font.primaryValue(size: 34, weight: .regular))
                    .foregroundStyle(Tokens.accent)
                    .symbolRenderingMode(.hierarchical)

                if let hi = daily.temperature2mMax.first,
                   let lo = daily.temperature2mMin.first {
                    VStack(alignment: .trailing, spacing: Tokens.tight) {
                        Label {
                            Text("\(Int(hi.rounded()))°")
                                .contentTransition(.numericText())
                        } icon: {
                            Image(systemName: "arrow.up")
                                .foregroundStyle(Tokens.warning)
                        }
                        Label {
                            Text("\(Int(lo.rounded()))°")
                                .contentTransition(.numericText())
                        } icon: {
                            Image(systemName: "arrow.down")
                                .foregroundStyle(Tokens.chartColor(2))
                        }
                    }
                    .font(Tokens.Font.rowTrailingValue)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Hourly temperature curve (next 24h)

private struct HourlyTempChart: View {
    let temps: [Double]
    let times: [String]
    var density: SkyChart.Density = .full

    private var points: [SkyChartPoint] {
        temps.enumerated().map { index, temp in
            SkyChartPoint(
                index: index,
                value: temp,
                label: index < times.count ? hourLabel(times[index]) : ""
            )
        }
    }

    /// The warmest hour ahead — the answer to "when does today peak?".
    ///
    /// Only marked when it lands well inside the window. A rule drawn on the
    /// first or last point sits on the frame edge, where it reads as a border
    /// rather than as a reading, and its label collides with the axis.
    private var peak: SkyChartPoint? {
        guard let peak = points.max(by: { $0.value < $1.value }) else { return nil }
        let margin = max(Int(Double(points.count) * 0.15), 1)
        let isInterior = peak.index >= margin && peak.index < points.count - margin
        return isInterior ? peak : nil
    }

    var body: some View {
        SkyChart(
            points: points,
            tint: Tokens.accent,
            density: density,
            referenceIndex: peak?.index,
            referenceLabel: peak?.label ?? "",
            format: { "\(Int($0.rounded()))°" },
            accessibilityDescription: "Hourly temperature, next 24 hours"
        )
    }

    private func hourLabel(_ isoTime: String) -> String {
        // "2026-06-20T14:00" → "2 PM"
        guard let range = isoTime.range(of: "T") else { return "" }
        let hourStr = String(isoTime[range.upperBound...].prefix(2))
        guard let hour = Int(hourStr) else { return "" }
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }
}

// MARK: - WMO weather code -> SF Symbol

private func weatherSymbol(for code: Int) -> String {
    switch code {
    case 0:           "sun.max.fill"
    case 1...3:       "cloud.sun.fill"
    case 45, 48:      "cloud.fog.fill"
    case 51...57:     "cloud.drizzle.fill"
    case 61...67:     "cloud.rain.fill"
    case 71...77:     "cloud.snow.fill"
    case 80...82:     "cloud.heavyrain.fill"
    case 95...99:     "cloud.bolt.fill"
    default:          "cloud.fill"
    }
}

// MARK: - WMO weather code -> human condition label

private func weatherCondition(for code: Int) -> String {
    switch code {
    case 0:           "Clear"
    case 1:           "Mostly Clear"
    case 2:           "Partly Cloudy"
    case 3:           "Overcast"
    case 45, 48:      "Foggy"
    case 51...57:     "Drizzle"
    case 61...67:     "Rain"
    case 71...77:     "Snow"
    case 80...82:     "Showers"
    case 95...99:     "Thunderstorm"
    default:          "Cloudy"
    }
}

// MARK: - API Models

struct OpenMeteoResponse: Codable, Sendable {
    let current: OpenMeteoCurrent
    let daily: OpenMeteoDaily
    let hourly: OpenMeteoHourly?
}

struct OpenMeteoHourly: Codable, Sendable {
    let time: [String]
    let temperature2m: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
    }
}

struct OpenMeteoCurrent: Codable, Sendable {
    let temperature2m: Double
    let weatherCode: Int
    let apparentTemperature: Double

    enum CodingKeys: String, CodingKey {
        case temperature2m = "temperature_2m"
        case weatherCode = "weather_code"
        case apparentTemperature = "apparent_temperature"
    }
}

struct OpenMeteoDaily: Codable, Sendable {
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]

    enum CodingKeys: String, CodingKey {
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
    }
}
