import Foundation
import Combine

class ChecklistViewModel: ObservableObject {
    @Published var tripInfo: TripInfo
    @Published var categories: [ChecklistCategory]
    @Published var checkedItems: Set<String> = []
    private let storageService = StorageService.shared
    
    init(tripInfo: TripInfo, categories: [ChecklistCategory]) {
        self.tripInfo = tripInfo
        self.categories = categories
        print("初始化清单：\(categories)")  // Debug log
    }
    
    func toggleCheck(item: ChecklistItem) {
        if checkedItems.contains(item.id) {
            checkedItems.remove(item.id)
        } else {
            checkedItems.insert(item.id)
        }
    }
    
    func isChecked(item: ChecklistItem) -> Bool {
        checkedItems.contains(item.id)
    }
    
    func deleteItem(at offsets: IndexSet, from categoryIndex: Int) {
        // 确保 categoryIndex 是有效的
        guard categories.indices.contains(categoryIndex) else { return }
        
        // 复制一份 items 以便修改
        var items = categories[categoryIndex].items
        let itemIdsToDelete = offsets.map { items[$0].id }
        
        // 从 checkedItems 中移除
        for id in itemIdsToDelete {
            checkedItems.remove(id)
        }
        
        // 从数据源中删除
        items.remove(atOffsets: offsets)
        
        // 更新 category 的 items
        categories[categoryIndex] = ChecklistCategory(category: categories[categoryIndex].category, items: items)
    }
    
    // 新增：添加自定义物品到指定分类
    func addCustomItem(to categoryIndex: Int, name: String, emoji: String = "📝") {
        
                guard categories.indices.contains(categoryIndex) else {
            print("无效的分类索引：\(categoryIndex)")
            return
        }

        let categoryName = categories[categoryIndex].category
        let newItem = ChecklistItem(
            id: UUID().uuidString,
            emoji: emoji,
            name: name,
            quantity: 1,
            note: nil,
            url: nil,
            category: categoryName,
        )
        print("添加自定义物品 - 分类：\(categoryName), 名称：\(name), 图标：\(emoji)")

        
        categories[categoryIndex].items.append(newItem)    
        // 强制触发视图更新
        objectWillChange.send()
    }

    // 新增：修改物品数量
    func updateQuantity(for item: ChecklistItem, in categoryIndex: Int, quantity: Int) {
        guard categories.indices.contains(categoryIndex) else { return }
        if let idx = categories[categoryIndex].items.firstIndex(where: { $0.id == item.id }) {
            categories[categoryIndex].items[idx].quantity = quantity
        }
    }

    // 修改：更新物品备注
    func updateItemNote(in categoryIndex: Int, itemId: String, note: String?) {
        guard categories.indices.contains(categoryIndex) else {
            print("无效的分类索引：\(categoryIndex)")  // Debug log
            return
        }
        
        guard let itemIndex = categories[categoryIndex].items.firstIndex(where: { $0.id == itemId }) else {
            print("未找到物品ID：\(itemId)")  // Debug log
            return
        }
        
        print("更新备注 - 之前：\(categories[categoryIndex].items[itemIndex].note ?? "nil")")  // Debug log
        
        // 创建新的物品实例
        let updatedItem = ChecklistItem(
            id: itemId,
            emoji: categories[categoryIndex].items[itemIndex].emoji,
            name: categories[categoryIndex].items[itemIndex].name,
            quantity: categories[categoryIndex].items[itemIndex].quantity,
            note: note,
            url: categories[categoryIndex].items[itemIndex].url,
            category: categories[categoryIndex].items[itemIndex].category
        )
        
        // 更新分类中的物品
        var updatedItems = categories[categoryIndex].items
        updatedItems[itemIndex] = updatedItem
        
        // 更新分类
        categories[categoryIndex] = ChecklistCategory(
            category: categories[categoryIndex].category,
            items: updatedItems
        )
        
        print("更新备注 - 之后：\(categories[categoryIndex].items[itemIndex].note ?? "nil")")  // Debug log
        
        // 强制触发视图更新
        objectWillChange.send()
    }

    func updateItemName(for item: ChecklistItem, in categoryIndex: Int, name: String) {
        if let itemIndex = categories[categoryIndex].items.firstIndex(where: { $0.id == item.id }) {
            categories[categoryIndex].items[itemIndex].name = name
        }
    }

    // 新增：更新物品的 emoji
    func updateItemEmoji(in categoryIndex: Int, itemId: String, newEmoji: String) {
        guard categories.indices.contains(categoryIndex),
              let itemIndex = categories[categoryIndex].items.firstIndex(where: { $0.id == itemId }) else { return }
        
        var updatedItems = categories[categoryIndex].items
        let item = updatedItems[itemIndex]
        let updatedItem = ChecklistItem(
            id: item.id,
            emoji: newEmoji,
            name: item.name,
            quantity: item.quantity,
            note: item.note,
            url: item.url,
            category: item.category
        )
        updatedItems[itemIndex] = updatedItem
        
        categories[categoryIndex] = ChecklistCategory(
            category: categories[categoryIndex].category,
            items: updatedItems
        )
    }

    // 添加新类别
    func addCategory(name: String, emoji: String) {
        // 确保类别名称不重复
        let categoryExists = categories.contains { $0.category == name }
        guard !categoryExists else {
            print("类别已存在：\(name)")
            return
        }
        
        // 创建新类别
        let newCategory = ChecklistCategory(
            category: name,
            items: []
        )
        
        // 添加到类别列表
        categories.append(newCategory)
        print("添加新类别：\(name)")
        
        // 强制触发视图更新
        objectWillChange.send()
    }
    
    // 删除类别
    func deleteCategory(at index: Int) {
        guard categories.indices.contains(index) else {
            print("无效的类别索引：\(index)")
            return
        }
        
        // 删除该类别中所有物品的选中状态
        let itemIds = categories[index].items.map { $0.id }
        itemIds.forEach { checkedItems.remove($0) }
        
        // 删除类别
        categories.remove(at: index)
        print("删除类别：\(index)")
        
        // 强制触发视图更新
        objectWillChange.send()
    }
    
    // 重命名类别
    func renameCategory(at index: Int, newName: String) {
        guard categories.indices.contains(index) else {
            print("无效的类别索引：\(index)")
            return
        }
        
        // 确保新名称不与其他类别重复
        let nameExists = categories.enumerated().contains { (i, category) in
            i != index && category.category == newName
        }
        guard !nameExists else {
            print("类别名称已存在：\(newName)")
            return
        }
        
        // 更新类别名称
        let oldCategory = categories[index]
        let updatedCategory = ChecklistCategory(
            category: newName,
            items: oldCategory.items.map { item in
                ChecklistItem(
                    id: item.id,
                    emoji: item.emoji,
                    name: item.name,
                    quantity: item.quantity,
                    note: item.note,
                    url: item.url,
                    category: newName
                )
            }
        )
        
        categories[index] = updatedCategory
        print("重命名类别：\(oldCategory.category) -> \(newName)")
        
        // 强制触发视图更新
        objectWillChange.send()
    }

    func saveAsTemplate(name: String, description: String, activities: [String]) -> PackingTemplate {
        let templateCategories = categories.map { category in
            // 根据类别名称选择合适的emoji
            let emoji = getCategoryEmoji(for: category.category)
            
            return CustomCategory(
                id: UUID().uuidString,
                name: category.category,
                emoji: emoji,
                items: category.items.map { item in
                    CustomItem(
                        id: UUID().uuidString,
                        name: item.name,
                        emoji: item.emoji,
                        quantity: item.quantity,
                        note: item.note,
                        isRequired: false
                    )
                },
                sortOrder: 0
            )
        }
        
        let template = PackingTemplate(
            id: UUID().uuidString,
            name: name,
            description: description,
            categories: templateCategories,
            activities: activities,
            isShared: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Save the template
        do {
            try storageService.saveTemplate(template)
        } catch {
            print("Failed to save template: \(error.localizedDescription)")
        }
        
        return template
    }
    
    private func getCategoryEmoji(for category: String) -> String {
        switch category.lowercased() {
        case "衣物", "服装":
            return "👕"
        case "电子", "数码":
            return "📱"
        case "洗漱", "个护":
            return "🧴"
        case "证件", "文件":
            return "📄"
        case "药品", "医疗":
            return "💊"
        case "购物":
            return "🛍️"
        case "运动":
            return "⚽️"
        case "娱乐":
            return "🎮"
        case "食品", "零食":
            return "🍪"
        case "工作":
            return "💼"
        case "其他":
            return "📦"
        default:
            // 如果找不到匹配的类别，返回一个通用的emoji
            return "📦"
        }
    }
} 
