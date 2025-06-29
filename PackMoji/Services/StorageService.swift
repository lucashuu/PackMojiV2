import Foundation

class StorageService {
    static let shared = StorageService()
    private let userDefaults = UserDefaults.standard
    
    // Keys for UserDefaults
    private enum StorageKey {
        static let templates = "user_templates"
        static let offlineLists = "offline_lists"
        static let lastSyncTime = "last_sync_time"
        static let isPremium = "is_premium"
    }
    
    // MARK: - Template Management
    
    /// Save a template
    func saveTemplate(_ template: PackingTemplate) throws {
        var templates = loadTemplates()
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        } else {
            templates.append(template)
        }
        try saveTemplates(templates)
    }
    
    /// Load all templates
    func loadTemplates() -> [PackingTemplate] {
        guard let data = userDefaults.data(forKey: StorageKey.templates),
              let templates = try? JSONDecoder().decode([PackingTemplate].self, from: data) else {
            return []
        }
        return templates
    }
    
    /// Delete a template
    func deleteTemplate(id: String) throws {
        var templates = loadTemplates()
        templates.removeAll { $0.id == id }
        try saveTemplates(templates)
    }
    
    /// Share a template
    func shareTemplate(_ template: PackingTemplate) -> String {
        // Convert template to shareable format (e.g., JSON string)
        guard let data = try? JSONEncoder().encode(template),
              let jsonString = String(data: data, encoding: .utf8) else {
            return ""
        }
        return jsonString
    }
    
    /// Import a shared template
    func importTemplate(from jsonString: String) throws -> PackingTemplate {
        guard let data = jsonString.data(using: .utf8),
              let template = try? JSONDecoder().decode(PackingTemplate.self, from: data) else {
            throw StorageError.invalidTemplateData
        }
        try saveTemplate(template)
        return template
    }
    
    // MARK: - Offline Storage
    
    /// Save a checklist for offline use
    func saveOfflineChecklist(_ checklist: ChecklistResponse) throws {
        var offlineLists = loadOfflineChecklists()
        offlineLists.append(checklist)
        
        let data = try JSONEncoder().encode(offlineLists)
        userDefaults.set(data, forKey: StorageKey.offlineLists)
    }
    
    /// Load all offline checklists
    func loadOfflineChecklists() -> [ChecklistResponse] {
        guard let data = userDefaults.data(forKey: StorageKey.offlineLists),
              let lists = try? JSONDecoder().decode([ChecklistResponse].self, from: data) else {
            return []
        }
        return lists
    }
    
    /// Update sync time
    func updateLastSyncTime() {
        userDefaults.set(Date(), forKey: StorageKey.lastSyncTime)
    }
    
    /// Get last sync time
    func getLastSyncTime() -> Date? {
        return userDefaults.object(forKey: StorageKey.lastSyncTime) as? Date
    }
    
    // MARK: - Premium Features
    
    /// Check if user has premium access
    var isPremium: Bool {
        get {
            userDefaults.bool(forKey: StorageKey.isPremium)
        }
        set {
            userDefaults.set(newValue, forKey: StorageKey.isPremium)
        }
    }
    
    // MARK: - Private Helpers
    
    private func saveTemplates(_ templates: [PackingTemplate]) throws {
        let data = try JSONEncoder().encode(templates)
        userDefaults.set(data, forKey: StorageKey.templates)
    }
}

// MARK: - Errors

enum StorageError: Error {
    case invalidTemplateData
    case saveFailed
    case loadFailed
    case notFound
    
    var localizedDescription: String {
        switch self {
        case .invalidTemplateData:
            return "Invalid template data"
        case .saveFailed:
            return "Failed to save data"
        case .loadFailed:
            return "Failed to load data"
        case .notFound:
            return "Data not found"
        }
    }
} 