import SwiftUI

struct ChecklistView: View {
    @ObservedObject var viewModel: ChecklistViewModel
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var showAddCategory = false
    @State private var newCategoryName = ""
    @State private var selectedEmoji = "📝"
    @State private var showEmojiPicker = false
    @State private var showSaveTemplate = false
    @State private var templateName = ""
    @State private var templateDescription = ""
    @State private var selectedActivities: Set<String> = []
    @State private var useFahrenheit = false
    @State private var isSelectionMode = false
    @State private var selectedItems: Set<String> = []
    @State private var showDeleteConfirmation = false
    
    var filteredCategories: [ChecklistCategory] {
        if searchText.isEmpty {
            return viewModel.categories
        }
        
        return viewModel.categories.compactMap { category in
            let filteredItems = category.items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.note?.localizedCaseInsensitiveContains(searchText) == true
            }
            if filteredItems.isEmpty {
                return nil
            }
            return ChecklistCategory(category: category.category, items: filteredItems)
        }
    }
    
    var body: some View {
        List {
            // Combined Trip Info and Weather Section
            VStack(alignment: .leading, spacing: 16) {
                // Trip Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(viewModel.tripInfo.destinationName)
                            .font(.system(size: 28, weight: .bold))
                        Spacer()
                        Button {
                            useFahrenheit.toggle()
                        } label: {
                            Text(useFahrenheit ? "°F" : "°C")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                        }
                    }
                    HStack {
                        Image(systemName: "calendar")
                        Text("\(viewModel.tripInfo.durationDays) \(String(localized: "checklist_days_suffix"))")
                        Spacer()
                        Image(systemName: "cloud.sun")
                        Text(convertTemperatureInText(viewModel.tripInfo.weatherSummary))
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                
                // Weather Section
                if !viewModel.tripInfo.dailyWeather.isEmpty && !viewModel.tripInfo.isHistorical {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("checklist_weather_title")
                            .font(.system(size: 17, weight: .bold))
                        
                        DailyWeatherView(dailyWeather: viewModel.tripInfo.dailyWeather, useFahrenheit: useFahrenheit)
                    }
                } else if viewModel.tripInfo.isHistorical {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("checklist_historical_weather_title")
                            .font(.system(size: 17, weight: .bold))
                        Text("checklist_historical_weather_summary")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Monthly average cards
                        if let monthlyAverages = viewModel.tripInfo.monthlyAverages, !monthlyAverages.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("weather_monthly_average")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    ForEach(monthlyAverages) { monthlyAverage in
                                        MonthlyAverageCard(monthlyAverage: monthlyAverage, useFahrenheit: useFahrenheit)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .listRowSeparator(.hidden)
            
            if filteredCategories.isEmpty && !searchText.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("search_no_results")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(Array(filteredCategories.enumerated()), id: \.element.id) { categoryIndex, category in
                    Section {
                        ForEach(Array(category.items.enumerated()), id: \.element.id) { itemIndex, item in
                            ChecklistItemRow(
                                item: item, 
                                isChecked: viewModel.isChecked(item: item), 
                                categoryIndex: categoryIndex, 
                                viewModel: viewModel,
                                isSelectionMode: isSelectionMode,
                                isSelected: selectedItems.contains(item.id)
                            ) {
                                if isSelectionMode {
                                    if selectedItems.contains(item.id) {
                                        selectedItems.remove(item.id)
                                    } else {
                                        selectedItems.insert(item.id)
                                    }
                                } else {
                                    viewModel.toggleCheck(item: item)
                                }
                            } onDelete: {
                                viewModel.deleteItem(at: IndexSet(integer: itemIndex), from: categoryIndex)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteItem(at: IndexSet(integer: itemIndex), from: categoryIndex)
                                } label: {
                                    Label("delete", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { indexSet in
                            viewModel.deleteItem(at: indexSet, from: categoryIndex)
                        }
                    } header: {
                        CategoryHeaderView(category: category, viewModel: viewModel, categoryIndex: categoryIndex)
                    }
                }
            }
        }
        .listStyle(.grouped)
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .navigationTitle("\(viewModel.tripInfo.destinationName) \(String(localized: "checklist_title_suffix"))")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, isPresented: $showSearch, prompt: Text("search_placeholder"))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isSelectionMode {
                    Button("cancel") {
                        isSelectionMode = false
                        selectedItems.removeAll()
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 8) {
                    if isSelectionMode {
                        Button {
                            if !selectedItems.isEmpty {
                                showDeleteConfirmation = true
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 17))
                                .foregroundColor(selectedItems.isEmpty ? .gray : .red)
                        }
                        .disabled(selectedItems.isEmpty)
                    } else {
                        Button {
                            showSearch.toggle()
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 17))
                        }
                        
                        Button {
                            isSelectionMode = true
                        } label: {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 17))
                        }
                        
                        Button {
                            showAddCategory = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 17))
                        }
                        
                        Button {
                            showSaveTemplate = true
                        } label: {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 17))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            NavigationStack {
                VStack(spacing: 20) {
                    Text("category_select_icon")
                        .font(.headline)
                    
                    Button(action: {
                        showEmojiPicker = true
                    }) {
                        Text(selectedEmoji)
                            .font(.system(size: 60))
                            .frame(width: 80, height: 80)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    TextField("category_name_placeholder", text: $newCategoryName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button("category_create") {
                        if !newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            viewModel.addCategory(name: newCategoryName, emoji: selectedEmoji)
                            newCategoryName = ""
                            selectedEmoji = "📝"
                            showAddCategory = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("category_add_new")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("cancel") {
                            showAddCategory = false
                        }
                    }
                }
                .sheet(isPresented: $showEmojiPicker) {
                    NavigationStack {
                        EmojiPickerView(selectedEmoji: $selectedEmoji)
                            .navigationTitle("emoji_picker_title")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("emoji_picker_done") {
                                        showEmojiPicker = false
                                    }
                                }
                            }
                    }
                    .presentationDetents([.medium])
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showSaveTemplate) {
            NavigationStack {
                Form {
                                    Section(header: Text("template_basic_info")) {
                    TextField("template_name_placeholder", text: $templateName)
                    TextField("template_description_placeholder", text: $templateDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("template_activities_title")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([
                                ("activity_beach", "🏖️"),
                                ("activity_hiking", "🏃"),
                                ("activity_camping", "⛺️"),
                                ("activity_business", "💼"),
                                ("activity_skiing", "⛷️"),
                                ("activity_party", "🎉"),
                                ("activity_city", "🏙️"),
                                ("activity_photography", "📸"),
                                ("activity_shopping", "🛍️")
                            ], id: \.0) { activity, emoji in
                                    Toggle(isOn: Binding(
                                        get: { selectedActivities.contains(activity) },
                                        set: { isSelected in
                                            if isSelected {
                                                selectedActivities.insert(activity)
                                            } else {
                                                selectedActivities.remove(activity)
                                            }
                                      }
                                    )) {
                                        HStack(spacing: 4) {
                                            Text(emoji)
                                            Text(LocalizedStringKey(activity))
                                        }
                                    }
                                    .toggleStyle(.button)
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .navigationTitle("templates_create")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("cancel") {
                            showSaveTemplate = false
                            resetTemplateForm()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("save") {
                            let _ = viewModel.saveAsTemplate(
                                name: templateName,
                                description: templateDescription,
                                activities: Array(selectedActivities)
                            )
                            showSaveTemplate = false
                            resetTemplateForm()
                        }
                        .disabled(templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .alert("confirm_delete_title", isPresented: $showDeleteConfirmation) {
            Button("cancel", role: .cancel) { }
            Button("delete", role: .destructive) {
                deleteSelectedItems()
            }
        } message: {
            Text(String(format: NSLocalizedString("confirm_delete_items", comment: ""), selectedItems.count))
        }
    }
    
    private func deleteSelectedItems() {
        // 按分类组织要删除的items
        var itemsToDelete: [Int: [String]] = [:]
        
        for categoryIndex in filteredCategories.indices {
            let category = filteredCategories[categoryIndex]
            let itemIdsToDelete = category.items.filter { selectedItems.contains($0.id) }.map { $0.id }
            if !itemIdsToDelete.isEmpty {
                itemsToDelete[categoryIndex] = itemIdsToDelete
            }
        }
        
        // 执行删除
        for (categoryIndex, itemIds) in itemsToDelete {
            let category = filteredCategories[categoryIndex]
            let indices = IndexSet(category.items.enumerated().compactMap { index, item in
                itemIds.contains(item.id) ? index : nil
            })
            viewModel.deleteItem(at: indices, from: categoryIndex)
        }
        
        // 清理选择状态
        selectedItems.removeAll()
        isSelectionMode = false
    }
    
    private func resetTemplateForm() {
        templateName = ""
        templateDescription = ""
        selectedActivities = []
    }
    
    private func convertTemperatureInText(_ text: String) -> String {
        // First, handle localization of weather condition keys
        var result = localizeWeatherConditionsInText(text)
        
        // Then, handle temperature conversion if needed
        if !useFahrenheit {
            return result
        }
        
        // 使用正则表达式匹配温度数字
        let pattern = #"(-?\d+)(?:°C|°)"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: result.utf16.count)
        
        regex?.enumerateMatches(in: result, options: [], range: range) { match, _, _ in
            guard let match = match,
                  let tempRange = Range(match.range(at: 1), in: result),
                  let celsius = Int(result[tempRange]) else { return }
            
            let fahrenheit = Int(Double(celsius) * 9.0 / 5.0 + 32)
            let originalTemp = String(result[Range(match.range, in: result)!])
            let newTemp = "\(fahrenheit)°F"
            result = result.replacingOccurrences(of: originalTemp, with: newTemp)
        }
        
        return result
    }
    
    private func localizeWeatherConditionsInText(_ text: String) -> String {
        var result = text
        
        // Handle specific weather localization keys
        if result.contains("weather_historical_monthly_average") {
            let localizedCondition = NSLocalizedString("weather_historical_monthly_average", comment: "Historical monthly average weather")
            result = result.replacingOccurrences(of: "weather_historical_monthly_average", with: localizedCondition)
        }
        
        if result.contains("weather_monthly_average") {
            let localizedCondition = NSLocalizedString("weather_monthly_average", comment: "Monthly average weather")
            result = result.replacingOccurrences(of: "weather_monthly_average", with: localizedCondition)
        }
        
        if result.contains("historical_average") {
            let localizedCondition = NSLocalizedString("weather_historical_average", comment: "Historical average weather")
            result = result.replacingOccurrences(of: "historical_average", with: localizedCondition)
        }
        
        // Handle Chinese weather conditions
        if result.contains("晴") {
            let localizedCondition = NSLocalizedString("weather_sunny", comment: "Sunny weather")
            result = result.replacingOccurrences(of: "晴", with: localizedCondition)
        }
        
        if result.contains("多云") {
            let localizedCondition = NSLocalizedString("weather_cloudy", comment: "Cloudy weather")
            result = result.replacingOccurrences(of: "多云", with: localizedCondition)
        }
        
        if result.contains("雨") {
            let localizedCondition = NSLocalizedString("weather_rainy", comment: "Rainy weather")
            result = result.replacingOccurrences(of: "雨", with: localizedCondition)
        }
        
        if result.contains("雪") {
            let localizedCondition = NSLocalizedString("weather_snowy", comment: "Snowy weather")
            result = result.replacingOccurrences(of: "雪", with: localizedCondition)
        }
        
        if result.contains("雾") {
            let localizedCondition = NSLocalizedString("weather_foggy", comment: "Foggy weather")
            result = result.replacingOccurrences(of: "雾", with: localizedCondition)
        }
        
        if result.contains("雷") {
            let localizedCondition = NSLocalizedString("weather_stormy", comment: "Stormy weather")
            result = result.replacingOccurrences(of: "雷", with: localizedCondition)
        }
        
        return result
    }
}

struct CategoryHeaderView: View {
    let category: ChecklistCategory
    @ObservedObject var viewModel: ChecklistViewModel
    var categoryIndex: Int
    @State private var showAddItemSheet = false
    @State private var newItemName = ""
    @State private var selectedEmoji = "📝"
    @State private var showEmojiPicker = false

    var body: some View {
        HStack {
            Text(LocalizedStringKey(category.category))
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color.primary)
            Spacer()
            Button(action: { showAddItemSheet = true }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 20))
            }
            .sheet(isPresented: $showAddItemSheet) {
                NavigationStack {
                    VStack(spacing: 20) {
                        Text("item_select_icon")
                            .font(.headline)
                        
                        Button(action: {
                            showEmojiPicker = true
                        }) {
                            Text(selectedEmoji)
                                .font(.system(size: 60))
                                .frame(width: 80, height: 80)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(12)
                        }
                        
                        TextField("item_name_placeholder", text: $newItemName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        Button("item_add") {
                            if !newItemName.trimmingCharacters(in: .whitespaces).isEmpty {
                                viewModel.addCustomItem(to: categoryIndex, name: newItemName, emoji: selectedEmoji)
                                newItemName = ""
                                selectedEmoji = "📝"
                                showAddItemSheet = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                        
                        Spacer()
                    }
                    .padding()
                    .navigationTitle("item_add_custom")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("cancel") {
                                newItemName = ""
                                selectedEmoji = "📝"
                                showAddItemSheet = false
                            }
                        }
                    }
                    .sheet(isPresented: $showEmojiPicker) {
                        NavigationStack {
                            EmojiPickerView(selectedEmoji: $selectedEmoji)
                                .navigationTitle("emoji_picker_title")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button("emoji_picker_done") {
                                            showEmojiPicker = false
                                        }
                                    }
                                }
                        }
                        .presentationDetents([.medium])
                    }
                }
                .presentationDetents([.medium])
            }
        }
        .textCase(nil)
        .padding(.vertical, 2)
    }
}

struct ChecklistItemRow: View {
    @State var item: ChecklistItem
    let isChecked: Bool
    let categoryIndex: Int
    @ObservedObject var viewModel: ChecklistViewModel
    let isSelectionMode: Bool
    let isSelected: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    @State private var isEditing = false
    @State private var editingText = ""
    @State private var isEditingNote = false
    @State private var editingNote = ""
    @State private var showEmojiPicker = false
    @State private var showQuantityEditor = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Main Item Row
            HStack(spacing: 12) {
                // Checkbox or Selection Circle
                Button(action: onToggle) {
                    if isSelectionMode {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? .accentColor : .gray)
                            .font(.system(size: 20))
                    } else {
                        Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isChecked ? .green : .accentColor)
                            .font(.system(size: 20))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Emoji
                Text(item.emoji)
                    .font(.title2)
                    .onTapGesture {
                        showEmojiPicker = true
                    }
                
                // Item Name
                if isEditing {
                    TextField("", text: $editingText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            item.name = editingText
                            isEditing = false
                        }
                } else {
                    Text(item.name)
                        .onTapGesture {
                            editingText = item.name
                            isEditing = true
                        }
                }
                
                Spacer()
                
                // Quantity
                Button(action: { showQuantityEditor = true }) {
                    Text("\(NSLocalizedString("item_quantity_prefix", comment: ""))\(item.quantity)")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(6)
                }
                
                // Note/Edit Button
                Button(action: {
                    print("点击备注：\(item.note ?? "")")  // Debug log
                    editingNote = item.note ?? ""
                    isEditingNote = true
                }) {
                    Image(systemName: item.note?.isEmpty == false ? "note.text" : "square.and.pencil")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                
                // Delete Button (hidden in selection mode)
                if !isSelectionMode {
                    Button(action: onDelete) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 18))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Note Display (if exists)
            if let note = item.note, !note.isEmpty {
                Button(action: {
                    print("点击备注：\(note)")  // Debug log
                    editingNote = note
                    isEditingNote = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "text.quote")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                        
                        Text(note)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Image(systemName: "pencil")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(Color(UIColor.systemGray6).opacity(0.5))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .padding(.leading, 44)
                .padding(.trailing, 12)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
        .background(isChecked ? Color(UIColor.systemGray6) : .clear)
        .cornerRadius(8)
        .opacity(isChecked ? 0.6 : 1.0)
        .onChange(of: viewModel.categories[categoryIndex].items) { newItems in
            if let updatedItem = newItems.first(where: { $0.id == item.id }) {
                print("物品更新 - ID: \(updatedItem.id), 备注: \(updatedItem.note ?? "nil")")  // Debug log
                item = updatedItem
            }
        }
        .sheet(isPresented: $showEmojiPicker) {
            NavigationStack {
                EmojiPickerView(selectedEmoji: Binding(
                    get: { item.emoji },
                    set: { newEmoji in
                        viewModel.updateItemEmoji(in: categoryIndex, itemId: item.id, newEmoji: newEmoji)
                    }
                ))
            }
        }
        .sheet(isPresented: $showQuantityEditor) {
            NavigationStack {
                VStack(spacing: 20) {
                    Stepper(
                        value: Binding(
                            get: { item.quantity },
                            set: { newValue in
                                item.quantity = max(1, min(99, newValue))
                                viewModel.updateQuantity(for: item, in: categoryIndex, quantity: item.quantity)
                            }
                        ),
                        in: 1...99
                    ) {
                        HStack {
                            Text("item_quantity")
                            Spacer()
                            Text("\(item.quantity)")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    
                    Button("done") {
                        showQuantityEditor = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .navigationTitle("item_adjust_quantity")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.height(200)])
        }
        .sheet(isPresented: $isEditingNote) {
            NavigationStack {
                VStack {
                    TextEditor(text: $editingNote)
                        .frame(minHeight: 100)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .padding()
                    
                    Button("save") {
                        print("保存备注：\(editingNote)")  // Debug log
                        viewModel.updateItemNote(in: categoryIndex, itemId: item.id, note: editingNote.isEmpty ? nil : editingNote)
                        isEditingNote = false
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                .navigationTitle("item_add_note")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("cancel") {
                            isEditingNote = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
            .interactiveDismissDisabled()
        }
    }
}

// ChecklistView 空状态提示
struct EmptyChecklistView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("checklist_empty_state")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct MonthlyAverageCard: View {
    let monthlyAverage: MonthlyAverage
    let useFahrenheit: Bool
    
    private var displayTemperature: String {
        if useFahrenheit {
            let fahrenheit = Int(Double(monthlyAverage.temperature) * 9.0 / 5.0 + 32)
            return "\(fahrenheit)°F"
        } else {
            return "\(monthlyAverage.temperature)°C"
        }
    }
    
    private var localizedCondition: String {
        let condition = monthlyAverage.condition
        
        // Debug logging
        print("🌤️ MonthlyAverageCard - Original condition: '\(condition)'")
        
        if condition == "weather_monthly_average" {
            print("🌤️ MonthlyAverageCard - Matched weather_monthly_average")
            return NSLocalizedString("weather_monthly_average", comment: "Monthly average weather")
        }
        
        if condition == "weather_historical_monthly_average" {
            print("🌤️ MonthlyAverageCard - Matched weather_historical_monthly_average")
            let localized = NSLocalizedString("weather_historical_monthly_average", comment: "Historical monthly average weather")
            print("🌤️ MonthlyAverageCard - Localized result: '\(localized)'")
            return localized
        }
        
        // Check for Chinese weather conditions and return localized versions
        if condition.contains("晴") {
            print("🌤️ MonthlyAverageCard - Matched 晴")
            return NSLocalizedString("weather_sunny", comment: "Sunny weather")
        } else if condition.contains("多云") {
            print("🌤️ MonthlyAverageCard - Matched 多云")
            return NSLocalizedString("weather_cloudy", comment: "Cloudy weather")
        } else if condition.contains("雨") {
            print("🌤️ MonthlyAverageCard - Matched 雨")
            return NSLocalizedString("weather_rainy", comment: "Rainy weather")
        } else if condition.contains("雪") {
            print("🌤️ MonthlyAverageCard - Matched 雪")
            return NSLocalizedString("weather_snowy", comment: "Snowy weather")
        } else if condition.contains("雾") {
            print("🌤️ MonthlyAverageCard - Matched 雾")
            return NSLocalizedString("weather_foggy", comment: "Foggy weather")
        } else if condition.contains("雷") {
            print("🌤️ MonthlyAverageCard - Matched 雷")
            return NSLocalizedString("weather_stormy", comment: "Stormy weather")
        } else {
            print("🌤️ MonthlyAverageCard - No match found, returning original condition")
            return condition
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(monthlyAverage.monthName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            WeatherIconView(
                conditionCode: monthlyAverage.conditionCode,
                icon: monthlyAverage.icon,
                size: 24
            )
            
            Text(displayTemperature)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(localizedCondition)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 90, height: 110)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct ChecklistView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            let mockTrip = TripInfo(
                destinationName: "东京", 
                durationDays: 5, 
                weatherSummary: "晴天, 15-25°C",
                dailyWeather: [
                    DailyWeather(date: "2024-01-15", dayOfWeek: "周一", temperature: 18, condition: "晴天", conditionCode: "clear", icon: "01d", dataSource: "forecast"),
                    DailyWeather(date: "2024-01-16", dayOfWeek: "周二", temperature: 15, condition: "多云", conditionCode: "clouds", icon: "02d", dataSource: "forecast"),
                    DailyWeather(date: "2024-01-17", dayOfWeek: "周三", temperature: 12, condition: "小雨", conditionCode: "rain", icon: "10d", dataSource: "forecast"),
                    DailyWeather(date: "2024-01-18", dayOfWeek: "周四", temperature: 20, condition: "晴天", conditionCode: "clear", icon: "01d", dataSource: "forecast"),
                    DailyWeather(date: "2024-01-19", dayOfWeek: "周五", temperature: 16, condition: "多云", conditionCode: "clouds", icon: "03d", dataSource: "forecast")
                ],
                isHistorical: false,
                monthlyAverages: nil
            )
            
            let mockCategories = [
                ChecklistCategory(category: "必需品", items: [
                    ChecklistItem(id: "passport", emoji: "🛂", name: "护照与签证", quantity: 1, note: nil, url: nil, category: "必需品"),
                    ChecklistItem(id: "tickets", emoji: "🎟️", name: "机票/车票", quantity: 1, note: nil, url: nil, category: "必需品"),
                    ChecklistItem(id: "cash", emoji: "💴", name: "日元现金", quantity: 1, note: nil, url: nil, category: "必需品"),
                ]),
                ChecklistCategory(category: "衣物", items: [
                    ChecklistItem(id: "tshirt", emoji: "👕", name: "T恤", quantity: 5, note: nil, url: nil, category: "衣物"),
                    ChecklistItem(id: "jeans", emoji: "👖", name: "牛仔裤", quantity: 2, note: nil, url: nil, category: "衣物"),
                    ChecklistItem(id: "jacket", emoji: "🧥", name: "薄外套", quantity: 1, note: nil, url: nil, category: "衣物"),
                ])
            ]
            
            let vm = ChecklistViewModel(tripInfo: mockTrip, categories: mockCategories)
            ChecklistView(viewModel: vm)
        }
    }
}

#Preview {
    NavigationStack {
        let mockTrip = TripInfo(
            destinationName: "伦敦", 
            durationDays: 7, 
            weatherSummary: "多云, 12-18°C",
            dailyWeather: [
                DailyWeather(date: "2024-01-15", dayOfWeek: "周一", temperature: 14, condition: "多云", conditionCode: "clouds", icon: "03d", dataSource: "historical"),
                DailyWeather(date: "2024-01-16", dayOfWeek: "周二", temperature: 12, condition: "小雨", conditionCode: "rain", icon: "10d", dataSource: "historical"),
                DailyWeather(date: "2024-01-17", dayOfWeek: "周三", temperature: 16, condition: "晴天", conditionCode: "clear", icon: "01d", dataSource: "historical"),
                DailyWeather(date: "2024-01-18", dayOfWeek: "周四", temperature: 13, condition: "多云", conditionCode: "clouds", icon: "02d", dataSource: "historical"),
                DailyWeather(date: "2024-01-19", dayOfWeek: "周五", temperature: 15, condition: "晴天", conditionCode: "clear", icon: "01d", dataSource: "historical"),
                DailyWeather(date: "2024-01-20", dayOfWeek: "周六", temperature: 11, condition: "小雨", conditionCode: "rain", icon: "09d", dataSource: "historical"),
                DailyWeather(date: "2024-01-21", dayOfWeek: "周日", temperature: 17, condition: "多云", conditionCode: "clouds", icon: "04d", dataSource: "historical")
            ],
            isHistorical: true,
            monthlyAverages: [
                MonthlyAverage(monthName: "1月", temperature: 15, condition: "weather_historical_monthly_average", conditionCode: "clouds", icon: "03d"),
                MonthlyAverage(monthName: "2月", temperature: 12, condition: "weather_historical_monthly_average", conditionCode: "rain", icon: "09d")
            ]
        )
        
        let mockCategories = [
            ChecklistCategory(category: "电子产品", items: [
                ChecklistItem(id: "phone", emoji: "📱", name: "手机", quantity: 1, note: nil, url: nil, category: "电子产品"),
                ChecklistItem(id: "charger", emoji: "🔌", name: "充电器", quantity: 1, note: nil, url: nil, category: "电子产品"),
                ChecklistItem(id: "powerbank", emoji: "🔋", name: "充电宝", quantity: 1, note: nil, url: nil, category: "电子产品"),
            ])
        ]
        
        let vm = ChecklistViewModel(tripInfo: mockTrip, categories: mockCategories)
        ChecklistView(viewModel: vm)
    }
} 
