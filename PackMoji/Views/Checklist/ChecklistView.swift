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
            // Trip Info Header
            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.tripInfo.destinationName)
                    .font(.system(size: 28, weight: .bold))
                HStack {
                    Image(systemName: "calendar")
                    Text("\(viewModel.tripInfo.durationDays) \(String(localized: "checklist_days_suffix"))")
                    Spacer()
                    Image(systemName: "cloud.sun")
                    Text(viewModel.tripInfo.weatherSummary)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding()
            .listRowBackground(Color(UIColor.secondarySystemBackground))
            .cornerRadius(14)
            .listRowSeparator(.hidden)
            
            // Daily Weather Section
            if !viewModel.tripInfo.dailyWeather.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("checklist_weather_title")
                        .font(.system(size: 17, weight: .bold))
                    
                    DailyWeatherView(dailyWeather: viewModel.tripInfo.dailyWeather)
                    
                    if viewModel.tripInfo.isHistorical {
                        Text("checklist_partial_forecast_summary")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(14)
                .listRowSeparator(.hidden)
            } else if viewModel.tripInfo.isHistorical {
                VStack(alignment: .leading, spacing: 4) {
                    Text("checklist_historical_weather_title")
                        .font(.system(size: 17, weight: .bold))
                    Text("checklist_historical_weather_summary")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(14)
                .listRowSeparator(.hidden)
            }
            
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
                            ChecklistItemRow(item: item, isChecked: viewModel.isChecked(item: item), categoryIndex: categoryIndex, viewModel: viewModel) {
                                viewModel.toggleCheck(item: item)
                            } onDelete: {
                                viewModel.deleteItem(at: IndexSet(integer: itemIndex), from: categoryIndex)
                            }
                        }
                    } header: {
                        CategoryHeaderView(category: category, viewModel: viewModel, categoryIndex: categoryIndex)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .navigationTitle("\(viewModel.tripInfo.destinationName) \(String(localized: "checklist_title_suffix"))")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, isPresented: $showSearch, prompt: Text("search_placeholder"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        showSearch.toggle()
                    } label: {
                        Image(systemName: "magnifyingglass")
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
        .sheet(isPresented: $showAddCategory) {
            NavigationStack {
                VStack(spacing: 20) {
                    Text("选择类别图标")
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
                    
                    TextField("类别名称", text: $newCategoryName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button("创建类别") {
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
                .navigationTitle("添加新类别")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("取消") {
                            showAddCategory = false
                        }
                    }
                }
                .sheet(isPresented: $showEmojiPicker) {
                    NavigationStack {
                        EmojiPickerView(selectedEmoji: $selectedEmoji)
                            .navigationTitle("选择图标")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("完成") {
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
                    Section(header: Text("基本信息")) {
                        TextField("模版名称", text: $templateName)
                        TextField("模版描述", text: $templateDescription, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    
                    Section(header: Text("活动标签")) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(["旅行", "商务", "度假", "露营", "海滩", "城市", "徒步", "滑雪"], id: \.self) { activity in
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
                                        Text(activity)
                                    }
                                    .toggleStyle(.button)
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .navigationTitle("保存为模版")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("取消") {
                            showSaveTemplate = false
                            resetTemplateForm()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("保存") {
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
    }
    
    private func resetTemplateForm() {
        templateName = ""
        templateDescription = ""
        selectedActivities = []
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
                        Text("选择物品图标")
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
                        
                        TextField("物品名称", text: $newItemName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        Button("添加") {
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
                    .navigationTitle("添加自定义物品")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("取消") {
                                newItemName = ""
                                selectedEmoji = "📝"
                                showAddItemSheet = false
                            }
                        }
                    }
                    .sheet(isPresented: $showEmojiPicker) {
                        NavigationStack {
                            EmojiPickerView(selectedEmoji: $selectedEmoji)
                                .navigationTitle("选择图标")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button("完成") {
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
        .padding(.vertical, 4)
    }
}

struct ChecklistItemRow: View {
    @State var item: ChecklistItem
    let isChecked: Bool
    let categoryIndex: Int
    @ObservedObject var viewModel: ChecklistViewModel
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
                // Checkbox
                Button(action: onToggle) {
                    Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isChecked ? .green : .accentColor)
                        .font(.system(size: 20))
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
                    Text("x\(item.quantity)")
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
                
                // Delete Button
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 18))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
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
        .padding(.vertical, 8)
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
                            Text("数量")
                            Spacer()
                            Text("\(item.quantity)")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    
                    Button("完成") {
                        showQuantityEditor = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .navigationTitle("调整数量")
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
                    
                    Button("保存") {
                        print("保存备注：\(editingNote)")  // Debug log
                        viewModel.updateItemNote(in: categoryIndex, itemId: item.id, note: editingNote.isEmpty ? nil : editingNote)
                        isEditingNote = false
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                .navigationTitle("添加备注")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("取消") {
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
            Text("还没有任何物品，点击下方 + 按钮添加吧！")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .padding()
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
                    DailyWeather(date: "2024-01-15", dayOfWeek: "周一", temperature: 18, condition: "晴天", conditionCode: "clear", icon: "01d"),
                    DailyWeather(date: "2024-01-16", dayOfWeek: "周二", temperature: 15, condition: "多云", conditionCode: "clouds", icon: "02d"),
                    DailyWeather(date: "2024-01-17", dayOfWeek: "周三", temperature: 12, condition: "小雨", conditionCode: "rain", icon: "10d"),
                    DailyWeather(date: "2024-01-18", dayOfWeek: "周四", temperature: 20, condition: "晴天", conditionCode: "clear", icon: "01d"),
                    DailyWeather(date: "2024-01-19", dayOfWeek: "周五", temperature: 16, condition: "多云", conditionCode: "clouds", icon: "03d")
                ],
                isHistorical: false
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
                DailyWeather(date: "2024-01-15", dayOfWeek: "周一", temperature: 14, condition: "多云", conditionCode: "clouds", icon: "03d"),
                DailyWeather(date: "2024-01-16", dayOfWeek: "周二", temperature: 12, condition: "小雨", conditionCode: "rain", icon: "10d"),
                DailyWeather(date: "2024-01-17", dayOfWeek: "周三", temperature: 16, condition: "晴天", conditionCode: "clear", icon: "01d"),
                DailyWeather(date: "2024-01-18", dayOfWeek: "周四", temperature: 13, condition: "多云", conditionCode: "clouds", icon: "02d"),
                DailyWeather(date: "2024-01-19", dayOfWeek: "周五", temperature: 15, condition: "晴天", conditionCode: "clear", icon: "01d"),
                DailyWeather(date: "2024-01-20", dayOfWeek: "周六", temperature: 11, condition: "小雨", conditionCode: "rain", icon: "09d"),
                DailyWeather(date: "2024-01-21", dayOfWeek: "周日", temperature: 17, condition: "多云", conditionCode: "clouds", icon: "04d")
            ],
            isHistorical: true
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
