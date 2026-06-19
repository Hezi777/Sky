import SwiftUI
import Charts

struct WeatherWidget: View {
    @State private var location = LocationProvider()
    @State private var weather: OpenMeteoResponse?
    @State private var errorMessage: String?

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                CardHeader(title: "Weather", symbol: "cloud.sun.fill", tint: Theme.accent)

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
        VStack(alignment: .leading, spacing: 12) {
            topRow
            if let hourly, hourly.temperature2m.count > 1 {
                HourlyTempChart(temps: hourly.temperature2m, times: hourly.time)
                    .frame(height: 56)
            }
        }
    }

    private var topRow: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
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

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                Image(systemName: weatherSymbol(for: current.weatherCode))
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.accent)
                    .symbolRenderingMode(.hierarchical)

                if let hi = daily.temperature2mMax.first,
                   let lo = daily.temperature2mMin.first {
                    VStack(alignment: .trailing, spacing: 4) {
                        Label {
                            Text("\(Int(hi.rounded()))°")
                                .contentTransition(.numericText())
                        } icon: {
                            Image(systemName: "arrow.up")
                                .foregroundStyle(.orange)
                        }
                        Label {
                            Text("\(Int(lo.rounded()))°")
                                .contentTransition(.numericText())
                        } icon: {
                            Image(systemName: "arrow.down")
                                .foregroundStyle(Theme.chartColor(2))
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

        Chart(points, id: \.offset) { index, temp in
            AreaMark(
                x: .value("Hour", index),
                yStart: .value("lo", lo - 1),
                yEnd: .value("Temp", temp)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                .linearGradient(
                    colors: [Theme.accent.opacity(0.25), Theme.accent.opacity(0.0)],
                    startPoint: .top, endPoint: .bottom
                )
            )

            LineMark(x: .value("Hour", index), y: .value("Temp", temp))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Theme.accent)
                .lineStyle(StrokeStyle(lineWidth: 2))
        }
        .chartYScale(domain: (lo - 1)...(hi + 1))
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
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
