import SwiftUI

struct DailyWeatherView: View {
    let dailyWeather: [DailyWeather]
    
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
            return 60
        } else if dayCount <= 14 {
            return 55
        } else if dayCount <= 21 {
            return 50
        } else {
            return 45
        }
    }
    
    // 根据天数计算卡片高度
    private var cardHeight: CGFloat {
        let dayCount = dailyWeather.count
        if dayCount <= 7 {
            return 100
        } else if dayCount <= 14 {
            return 90
        } else if dayCount <= 21 {
            return 80
        } else {
            return 70
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
                        cardHeight: cardHeight
                    )
                }
            }
        }
        .frame(height: cardHeight + 16)
    }
}

struct DailyWeatherCard: View {
    let day: DailyWeather
    let iconSize: CGFloat
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: day.date) {
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        }
        return day.date
    }
    
    var body: some View {
        VStack(spacing: 6) {
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
            Text("\(day.temperature)°")
                .font(.system(size: max(12, iconSize * 0.4), weight: .semibold))
                .foregroundColor(.primary)
            
            // Condition (shortened)
            Text(shortenedCondition)
                .font(.system(size: max(8, iconSize * 0.25)))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: cardWidth, height: cardHeight)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
    }
    
    private var shortenedCondition: String {
        let condition = day.condition
        if condition.contains("晴") {
            return "晴"
        } else if condition.contains("多云") {
            return "多云"
        } else if condition.contains("雨") {
            return "雨"
        } else if condition.contains("雪") {
            return "雪"
        } else if condition.contains("雾") {
            return "雾"
        } else if condition.contains("雷") {
            return "雷"
        } else {
            return condition.count > 4 ? String(condition.prefix(4)) : condition
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // 5天行程
        VStack(alignment: .leading) {
            Text("5天行程").font(.headline)
            DailyWeatherView(dailyWeather: Array(repeating: DailyWeather(date: "2024-01-15", dayOfWeek: "周一", temperature: 18, condition: "晴天", conditionCode: "clear", icon: "01d"), count: 5))
        }
        
        // 10天行程
        VStack(alignment: .leading) {
            Text("10天行程").font(.headline)
            DailyWeatherView(dailyWeather: Array(repeating: DailyWeather(date: "2024-01-15", dayOfWeek: "周一", temperature: 18, condition: "晴天", conditionCode: "clear", icon: "01d"), count: 10))
        }
        
        // 20天行程
        VStack(alignment: .leading) {
            Text("20天行程").font(.headline)
            DailyWeatherView(dailyWeather: Array(repeating: DailyWeather(date: "2024-01-15", dayOfWeek: "周一", temperature: 18, condition: "晴天", conditionCode: "clear", icon: "01d"), count: 20))
        }
        
        // 30天行程
        VStack(alignment: .leading) {
            Text("30天行程").font(.headline)
            DailyWeatherView(dailyWeather: Array(repeating: DailyWeather(date: "2024-01-15", dayOfWeek: "周一", temperature: 18, condition: "晴天", conditionCode: "clear", icon: "01d"), count: 30))
        }
    }
    .padding()
} 