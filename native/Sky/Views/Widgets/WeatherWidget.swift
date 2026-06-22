import SwiftUI
import Charts

struct WeatherWidget: View {
    @State private var location = LocationProvider()
    @State private var weather: OpenMeteoResponse?
    @State private var errorMessage: String?

    var body: some View {
        WidgetShell(title: "Weather", symbol: "cloud.sun", tint: Tokens.accent) {
            if let err = location.error ?? errorMessage {
                WidgetError(message: err) {
                    Task { await fetchWeather() }
                }
            } else if let w = weather {
                WeatherContent(
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
            location.start()
            await fetchWeather()
        }
    }

    private func fetchWeather() async {
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
    let placeName: String
    let current: OpenMeteoCurrent
    let daily: OpenMeteoDaily
    let hourly: OpenMeteoHourly?

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
            topRow
            if let hourly, hourly.temperature2m.count > 1 {
                HourlyTempChart(temps: hourly.temperature2m, times: hourly.time)
                    .frame(height: 72)
            }
        }
    }

    private var topRow: some View {
        HStack(alignment: .top, spacing: Tokens.wideSpacing) {
            VStack(alignment: .leading, spacing: Tokens.tight) {
                Text(placeName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("\(Int(current.temperature2m.rounded()))°")
                    .font(.system(size: 48, weight: .thin, design: .rounded))
                    .contentTransition(.numericText())

                Label {
                    Text("Feels like \(Int(current.apparentTemperature.rounded()))°")
                } icon: {
                    Image(systemName: "thermometer.variable")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: Tokens.snug)

            VStack(alignment: .trailing, spacing: Tokens.snug) {
                Image(systemName: weatherSymbol(for: current.weatherCode))
                    .font(.system(size: 36))
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
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                }
            }
        }
    }
}

// MARK: - Hourly temperature curve (next 24h)

private struct HourlyTempChart: View {
    let temps: [Double]
    let times: [String]

    var body: some View {
        let points = Array(temps.enumerated())
        let lo = temps.min() ?? 0
        let hi = temps.max() ?? 1
        let padding = max((hi - lo) * 0.15, 0.5)

        Chart(points, id: \.offset) { index, temp in
            AreaMark(
                x: .value("Hour", index),
                yStart: .value("lo", lo - padding),
                yEnd: .value("Temp", temp)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                .linearGradient(
                    colors: [Tokens.accent.opacity(0.18), Tokens.accent.opacity(0.0)],
                    startPoint: .top, endPoint: .bottom
                )
            )

            LineMark(x: .value("Hour", index), y: .value("Temp", temp))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Tokens.accent)
                .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
        .chartYScale(domain: (lo - padding)...(hi + padding))
        .chartXAxis {
            AxisMarks(values: .stride(by: 6)) { value in
                AxisValueLabel {
                    if let idx = value.as(Int.self), idx < times.count {
                        Text(hourLabel(times[idx]))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(Int(v.rounded()))°")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                    .foregroundStyle(.quaternary)
            }
        }
        .chartLegend(.hidden)
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

// MARK: - API Models

private struct OpenMeteoResponse: Codable, Sendable {
    let current: OpenMeteoCurrent
    let daily: OpenMeteoDaily
    let hourly: OpenMeteoHourly?
}

private struct OpenMeteoHourly: Codable, Sendable {
    let time: [String]
    let temperature2m: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
    }
}

private struct OpenMeteoCurrent: Codable, Sendable {
    let temperature2m: Double
    let weatherCode: Int
    let apparentTemperature: Double

    enum CodingKeys: String, CodingKey {
        case temperature2m = "temperature_2m"
        case weatherCode = "weather_code"
        case apparentTemperature = "apparent_temperature"
    }
}

private struct OpenMeteoDaily: Codable, Sendable {
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]

    enum CodingKeys: String, CodingKey {
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
    }
}
