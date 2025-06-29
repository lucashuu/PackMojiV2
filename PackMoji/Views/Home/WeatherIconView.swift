import SwiftUI

struct WeatherIconView: View {
    let conditionCode: String
    let icon: String
    let size: CGFloat
    
    init(conditionCode: String, icon: String, size: CGFloat = 24) {
        self.conditionCode = conditionCode
        self.icon = icon
        self.size = size
    }
    
    var body: some View {
        Text(weatherEmoji)
            .font(.system(size: size))
    }
    
    private var weatherEmoji: String {
        // Map OpenWeather icon codes to emojis
        switch icon {
        case "01d", "01n": // clear sky
            return "☀️"
        case "02d", "02n": // few clouds
            return "⛅️"
        case "03d", "03n": // scattered clouds
            return "☁️"
        case "04d", "04n": // broken clouds
            return "☁️"
        case "09d", "09n": // shower rain
            return "🌧️"
        case "10d", "10n": // rain
            return "🌦️"
        case "11d", "11n": // thunderstorm
            return "⛈️"
        case "13d", "13n": // snow
            return "❄️"
        case "50d", "50n": // mist
            return "🌫️"
        default:
            // Fallback based on condition code
            switch conditionCode {
            case "clear":
                return "☀️"
            case "clouds":
                return "☁️"
            case "rain":
                return "🌧️"
            case "snow":
                return "❄️"
            case "thunderstorm":
                return "⛈️"
            case "drizzle":
                return "🌦️"
            case "mist", "fog":
                return "🌫️"
            default:
                return "🌤️"
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        WeatherIconView(conditionCode: "clear", icon: "01d", size: 40)
        WeatherIconView(conditionCode: "clouds", icon: "02d", size: 40)
        WeatherIconView(conditionCode: "rain", icon: "10d", size: 40)
        WeatherIconView(conditionCode: "snow", icon: "13d", size: 40)
        WeatherIconView(conditionCode: "thunderstorm", icon: "11d", size: 40)
    }
} 