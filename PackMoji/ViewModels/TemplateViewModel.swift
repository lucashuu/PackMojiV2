import Foundation
import Combine

class TemplateViewModel: ObservableObject {
    @Published var templates: [PackingTemplate] = []
    @Published var categories: [CustomCategory] = []
    @Published var selectedTemplate: PackingTemplate?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var showError = false
    
    private var template: PackingTemplate?
    
    let activities = [
        "activity_beach",
        "activity_hiking",
        "activity_camping",
        "activity_business",
        "activity_skiing",
        "activity_party",
        "activity_city",
        "activity_photography",
        "activity_shopping"
    ]
    
    private let storageService = StorageService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(template: PackingTemplate? = nil) {
        self.template = template
        loadData()
    }
    
    private func loadData() {
        if let template = template {
            // Load categories for a specific template
            self.categories = template.categories
        } else {
            // Load all templates
            loadTemplates()
        }
    }
    
    private func loadTemplates() {
        templates = storageService.loadTemplates()
    }
    
    func refreshTemplates() {
        loadTemplates()
    }
    
    // MARK: - Template Management
    
    func deleteTemplates(at indexSet: IndexSet) {
        for index in indexSet {
            let template = templates[index]
            do {
                try storageService.deleteTemplate(id: template.id)
            } catch {
                print("Failed to delete template: \(error.localizedDescription)")
            }
        }
        templates.remove(atOffsets: indexSet)
    }
    
    func createTemplate(name: String, description: String, activities: [String]) {
        let newTemplate = PackingTemplate(
            id: UUID().uuidString,
            name: name,
            description: description,
            categories: [],
            activities: activities,
            isShared: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try storageService.saveTemplate(newTemplate)
            loadTemplates()
            // Post notification to refresh templates list in other views
            NotificationCenter.default.post(name: NSNotification.Name("TemplateCreated"), object: nil)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func updateTemplate(_ template: PackingTemplate) {
        var updatedTemplate = template
        updatedTemplate.updatedAt = Date()
        
        do {
            try storageService.saveTemplate(updatedTemplate)
            loadTemplates()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func deleteTemplate(_ template: PackingTemplate) {
        do {
            try storageService.deleteTemplate(id: template.id)
            loadTemplates()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func duplicateTemplate(_ template: PackingTemplate) {
        let newTemplate = template.duplicate()
        do {
            try storageService.saveTemplate(newTemplate)
            loadTemplates()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // MARK: - Category Management
    
    func addCategory(name: String, emoji: String) {
        let newCategory = CustomCategory(
            id: UUID().uuidString,
            name: name,
            emoji: emoji,
            items: [],
            sortOrder: categories.count
        )
        categories.append(newCategory)
        // TODO: Update storage
    }
    
    func deleteCategory(at indexSet: IndexSet) {
        categories.remove(atOffsets: indexSet)
        // TODO: Update storage
    }
    
    func reorderCategories(in template: PackingTemplate, from source: IndexSet, to destination: Int) {
        var updatedTemplate = template
        updatedTemplate.categories.move(fromOffsets: source, toOffset: destination)
        
        // Update sort order
        for (index, var category) in updatedTemplate.categories.enumerated() {
            category.sortOrder = index
        }
        
        updateTemplate(updatedTemplate)
    }
    
    // MARK: - Item Management
    
    func addCustomItem(to categoryIndex: Int, name: String, emoji: String) {
        guard categoryIndex < categories.count else { return }
        
        let newItem = CustomItem(
            id: UUID().uuidString,
            name: name,
            emoji: emoji,
            quantity: 1,
            note: nil,
            isRequired: false
        )
        
        categories[categoryIndex].items.append(newItem)
        // TODO: Update storage
    }
    
    func deleteItem(at indexSet: IndexSet, from categoryIndex: Int) {
        guard categoryIndex < categories.count else { return }
        categories[categoryIndex].items.remove(atOffsets: indexSet)
        // TODO: Update storage
    }
    
    func updateItemName(for item: CustomItem, in categoryIndex: Int, name: String) {
        guard categoryIndex < categories.count,
              let itemIndex = categories[categoryIndex].items.firstIndex(where: { $0.id == item.id }) else { return }
        
        categories[categoryIndex].items[itemIndex].name = name
        // TODO: Update storage
    }
    
    func updateItemEmoji(in categoryIndex: Int, itemId: String, newEmoji: String) {
        guard categoryIndex < categories.count,
              let itemIndex = categories[categoryIndex].items.firstIndex(where: { $0.id == itemId }) else { return }
        
        categories[categoryIndex].items[itemIndex].emoji = newEmoji
        // TODO: Update storage
    }
    
    func updateQuantity(for item: CustomItem, in categoryIndex: Int, quantity: Int) {
        guard categoryIndex < categories.count,
              let itemIndex = categories[categoryIndex].items.firstIndex(where: { $0.id == item.id }) else { return }
        
        categories[categoryIndex].items[itemIndex].quantity = quantity
        // TODO: Update storage
    }
    
    // MARK: - Sharing
    
    func shareTemplate(_ template: PackingTemplate) -> String {
        return storageService.shareTemplate(template)
    }
    
    func importTemplate(from jsonString: String) throws {
        do {
            _ = try storageService.importTemplate(from: jsonString)
            loadTemplates()
            // Post notification to refresh templates list in other views
            NotificationCenter.default.post(name: NSNotification.Name("TemplateCreated"), object: nil)
        } catch {
            throw error
        }
    }
} 