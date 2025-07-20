import SwiftUI

struct DailyWeatherView: View {
    let dailyWeather: [DailyWeather]
    let useFahrenheit: Bool
    
    // 根据天数计算合适的图标大小
    private var iconSize: CGFloat {
        let dayCount = dailyWeather.count
        if dayCount <= 7 {
            return 32
        } else if dayCount <= 14 {
            return 28
        } else if dayCount <= 21 {
            return 24
        } else {
            return 20
        }
    }
    
    // 根据天数计算卡片宽度
    private var cardWidth: CGFloat {
        let dayCount = dailyWeather.count
        if dayCount <= 7 {
            return 80 // 大幅增加宽度以容纳完整文字
        } else if dayCount <= 14 {
            return 75
        } else if dayCount <= 21 {
            return 70
        } else {
            return 65
        }
    }
    
    // 根据天数计算卡片高度
    private var cardHeight: CGFloat {
        let dayCount = dailyWeather.count
        if dayCount <= 7 {
            return 140 // 进一步增加高度
        } else if dayCount <= 14 {
            return 130
        } else if dayCount <= 21 {
            return 120
        } else {
            return 110
        }
    }
    
    // 根据天数计算间距
    private var spacing: CGFloat {
        let dayCount = dailyWeather.count
        if dayCount <= 7 {
            return 16
        } else if dayCount <= 14 {
            return 12
        } else if dayCount <= 21 {
            return 10
        } else {
            return 8
        }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(dailyWeather) { day in
                    DailyWeatherCard(
                        day: day,
                        iconSize: iconSize,
                        cardWidth: cardWidth,
                        cardHeight: cardHeight,
                        useFahrenheit: useFahrenheit
                    )
                }
            }
            .padding(.horizontal, 8) // 添加水平padding给阴影留出空间
            .padding(.vertical, 4) // 添加垂直padding给阴影留出空间
        }
        .frame(height: cardHeight + 32) // 增加高度以容纳阴影
    }
}

struct DailyWeatherCard: View {
    let day: DailyWeather
    let iconSize: CGFloat
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let useFahrenheit: Bool
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: day.date) {
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        }
        return day.date
    }
    
    private var displayTemperature: String {
        if useFahrenheit {
            let fahrenheit = Int(Double(day.temperature) * 9.0 / 5.0 + 32)
            return "\(fahrenheit)°F"
        } else {
            return "\(day.temperature)°C"
        }
    }
    
    var body: some View {
        VStack(spacing: 6) { // 减少整体间距，给底部文字留出更多空间
            // Day of week
            Text(day.dayOfWeek)
                .font(.system(size: max(10, iconSize * 0.3)))
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            // Date (e.g., 6/26)
            Text(formattedDate)
                .font(.system(size: max(9, iconSize * 0.28)))
                .foregroundColor(.secondary)
            
            // Weather icon
            WeatherIconView(
                conditionCode: day.conditionCode,
                icon: day.icon,
                size: iconSize
            )
            
            // Temperature
            Text(displayTemperature)
                .font(.system(size: max(12, iconSize * 0.4), weight: .semibold))
                .foregroundColor(.primary)
                .padding(.bottom, 2) // 减少与底部文字的间距
            
            // Condition (shortened)
            Text(shortenedCondition)
                .font(.system(size: max(8, iconSize * 0.25))) // 稍微减小字体
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(4) // 增加行数限制
                .fixedSize(horizontal: false, vertical: true) // 确保文字不被截断
        }
        .frame(width: cardWidth, height: cardHeight)
        .padding(.vertical, 4) // 减少垂直padding
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: UIColor { traitCollection in
                    if traitCollection.userInterfaceStyle == .dark {
                        return UIColor.tertiarySystemBackground
                    } else {
                        return UIColor.systemBackground
                    }
                }))
        )
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var shortenedCondition: String {
        let condition = day.condition
        
        // Handle special historical weather cases
        if condition == "historical_average" {
            return String(localized: "weather_historical_average")
        }
        
        if condition == "weather_monthly_average" {
            return String(localized: "weather_monthly_average")
        }
        
        if condition == "weather_historical_monthly_average" {
            return String(localized: "weather_historical_monthly_average")

        }
        
        // Handle monthly average conditions (e.g., "Clear_monthly_average")
        if condition.hasSuffix("_monthly_average") {
            let baseCondition = String(condition.dropLast("_monthly_average".count))
            let localizedBase = getLocalizedWeatherCondition(baseCondition)
            return localizedBase + String(localized: "weather_monthly_average_suffix")
        }
        
        // For historical data, add suffix to localized weather conditions
        var localizedCondition: String
        
        // Check for Chinese weather conditions and return localized versions
        if condition.contains("晴") {
            localizedCondition = String(localized: "weather_sunny")
        } else if condition.contains("多云") {
            localizedCondition = String(localized: "weather_cloudy")
        } else if condition.contains("雨") {
            localizedCondition = String(localized: "weather_rainy")
        } else if condition.contains("雪") {
            localizedCondition = String(localized: "weather_snowy")
        } else if condition.contains("雾") {
            localizedCondition = String(localized: "weather_foggy")
        } else if condition.contains("雷") {
            localizedCondition = String(localized: "weather_stormy")
        } else {
            // 不再截断文字，保持完整
            localizedCondition = condition
        }
        
        // Add historical suffix for historical data
        if day.dataSource == "historical" && condition != "historical_average" && !condition.hasSuffix("_monthly_average") {
            localizedCondition += String(localized: "weather_historical_suffix")
        }
        
        return localizedCondition
    }
    
    private func getLocalizedWeatherCondition(_ condition: String) -> String {
        switch condition.lowercased() {
        case "clear", "sunny":
            return String(localized: "weather_sunny")
        case "cloudy", "overcast":
            return String(localized: "weather_cloudy")
        case "rain", "rainy":
            return String(localized: "weather_rainy")
        case "snow", "snowy":
            return String(localized: "weather_snowy")
        case "fog", "foggy":
            return String(localized: "weather_foggy")
        case "storm", "stormy":
            return String(localized: "weather_stormy")
        default:
            return condition
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // 5天行程
        VStack(alignment: .leading) {
            Text("5天行程").font(.headline)
            DailyWeatherView(dailyWeather: Array(repeating: DailyWeather(date: "2024-01-15", dayOfWeek: "周一", temperature: 18, condition: "晴天", conditionCode: "clear", icon: "01d", dataSource: "forecast"), count: 5), useFahrenheit: false)
        }
        
        // 10天行程
        VStack(alignment: .leading) {
            Text("10天行程").font(.headline)
            DailyWeatherView(dailyWeather: Array(repeating: DailyWeather(date: "2024-01-15", dayOfWeek: "周一", temperature: 18, condition: "晴天", conditionCode: "clear", icon: "01d", dataSource: "forecast"), count: 10), useFahrenheit: false)
        }
        
        // 20天行程
        VStack(alignment: .leading) {
            Text("20天行程").font(.headline)
            DailyWeatherView(dailyWeather: Array(repeating: DailyWeather(date: "2024-01-15", dayOfWeek: "周一", temperature: 18, condition: "晴天", conditionCode: "clear", icon: "01d", dataSource: "historical"), count: 20), useFahrenheit: false)
        }
        
        // 30天行程
        VStack(alignment: .leading) {
            Text("30天行程").font(.headline)
            DailyWeatherView(dailyWeather: Array(repeating: DailyWeather(date: "2024-01-15", dayOfWeek: "周一", temperature: 18, condition: "晴天", conditionCode: "clear", icon: "01d", dataSource: "historical"), count: 30), useFahrenheit: false)
        }
    }
    .padding()
} 