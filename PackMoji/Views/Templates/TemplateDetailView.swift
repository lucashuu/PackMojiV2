import SwiftUI

struct TemplateDetailView: View {
    let template: PackingTemplate
    @StateObject private var viewModel: TemplateViewModel
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var showAddCategory = false
    @State private var newCategoryName = ""
    @State private var selectedEmoji = "📝"
    @State private var showEmojiPicker = false
    
    init(template: PackingTemplate) {
        self.template = template
        _viewModel = StateObject(wrappedValue: TemplateViewModel(template: template))
    }
    
    var filteredCategories: [CustomCategory] {
        if searchText.isEmpty {
            return viewModel.categories
        }
        
        return viewModel.categories.compactMap { category in
            let filteredItems = category.items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText)
            }
            if filteredItems.isEmpty {
                return nil
            }
            return CustomCategory(id: category.id, name: category.name, emoji: category.emoji, items: filteredItems, sortOrder: category.sortOrder)
        }
    }
    
    var body: some View {
        List {
            // Template Info Header
            VStack(alignment: .leading, spacing: 12) {
                Text(template.name)
                    .font(.system(size: 28, weight: .bold))
                Text(template.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Activities Tags
                if !template.activities.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(template.activities, id: \.self) { activity in
                                Text(activity)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
            }
            .padding()
            .listRowBackground(Color(UIColor.secondarySystemBackground))
            .cornerRadius(14)
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
                            TemplateItemRow(item: item, categoryIndex: categoryIndex, viewModel: viewModel)
                        }
                    } header: {
                        TemplateCategoryHeaderView(category: category, viewModel: viewModel, categoryIndex: categoryIndex)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .navigationTitle(template.name)
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
                            .foregroundColor(.accentColor)
                    }
                    
                    Button {
                        showAddCategory = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 17))
                            .foregroundColor(.accentColor)
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
    }
}

struct TemplateItemRow: View {
    @State var item: CustomItem
    let categoryIndex: Int
    @ObservedObject var viewModel: TemplateViewModel
    @State private var isEditing = false
    @State private var editingText = ""
    @State private var showEmojiPicker = false
    @State private var showQuantityEditor = false
    
    var body: some View {
        HStack(spacing: 12) {
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
                        viewModel.updateItemName(for: item, in: categoryIndex, name: editingText)
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
            
            // Delete Button
            Button(action: {
                viewModel.deleteItem(at: IndexSet(integer: categoryIndex), from: categoryIndex)
            }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 18))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.clear)
        .cornerRadius(8)
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
    }
}

struct TemplateCategoryHeaderView: View {
    let category: CustomCategory
    @ObservedObject var viewModel: TemplateViewModel
    var categoryIndex: Int
    @State private var showAddItemSheet = false
    @State private var newItemName = ""
    @State private var selectedEmoji = "📝"
    @State private var showEmojiPicker = false

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Text(category.emoji)
                    .font(.system(size: 17))
                Text(category.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color.primary)
            }
            
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