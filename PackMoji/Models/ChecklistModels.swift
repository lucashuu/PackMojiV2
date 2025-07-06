import Foundation
import SwiftUI

// MARK: - Server Response Models
struct ChecklistResponse: Codable, Equatable {
    let tripInfo: TripInfo
    let categories: [ChecklistCategory]
}

struct TripInfo: Codable, Equatable {
    var destinationName: String
    var durationDays: Int
    var weatherSummary: String
    var dailyWeather: [DailyWeather]
    var isHistorical: Bool
    var isMixedData: Bool?
    var forecastDays: Int?
    var historicalDays: Int?
}

struct DailyWeather: Codable, Identifiable, Equatable {
    var id: String { date }
    let date: String
    let dayOfWeek: String
    let temperature: Int
    let condition: String
    let conditionCode: String
    let icon: String
    let dataSource: String? // "forecast" or "historical"
}

struct ChecklistCategory: Codable, Equatable, Identifiable {
    var id: String { category }
    var category: String
    var items: [ChecklistItem]
}

struct ChecklistItem: Codable, Equatable, Identifiable {
    var id: String
    var emoji: String
    var name: String
    var quantity: Int
    var note: String?
    var url: String?
    var category: String
}

// MARK: - Template & Custom Category Models
struct PackingTemplate: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var description: String
    var categories: [CustomCategory]
    var activities: [String]
    var isShared: Bool
    var createdAt: Date
    var updatedAt: Date
    
    func duplicate(withName name: String? = nil) -> PackingTemplate {
        PackingTemplate(
            id: UUID().uuidString,
            name: name ?? "\(self.name) Copy",
            description: self.description,
            categories: self.categories,
            activities: self.activities,
            isShared: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

struct CustomCategory: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var emoji: String
    var items: [CustomItem]
    var sortOrder: Int
}

struct CustomItem: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var emoji: String
    var quantity: Int
    var note: String?
    var isRequired: Bool
} 