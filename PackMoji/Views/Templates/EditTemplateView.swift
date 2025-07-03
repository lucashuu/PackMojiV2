import SwiftUI

struct EditTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TemplateViewModel
    @State private var template: PackingTemplate
    @State private var showAddCategory = false
    @State private var showAddItem = false
    @State private var selectedCategoryIndex: Int?
    @State private var newItemName = ""
    @State private var selectedEmoji = "📝"
    @State private var showEmojiPicker = false
    @State private var newCategoryName = ""
    @State private var searchText = ""
    @State private var showSearch = false
    
    init(template: PackingTemplate, viewModel: TemplateViewModel) {
        self.template = template
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    var filteredCategories: [CustomCategory] {
        if searchText.isEmpty {
            return template.categories
        }
        return template.categories.compactMap { category in
            let filteredItems = category.items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText)
            }
            if filteredItems.isEmpty {
                return nil
            }
            return CustomCategory(
                id: category.id,
                name: category.name,
                emoji: category.emoji,
                items: filteredItems,
                sortOrder: category.sortOrder
            )
        }
    }
    
    var body: some View {
        List {
            Section {
                TextField("template_name_placeholder", text: Binding(
                    get: { template.name },
                    set: { template.name = $0 }
                ))
                
                TextField("template_description_placeholder", text: Binding(
                    get: { template.description },
                    set: { template.description = $0 }
                ))
                .lineLimit(3)
            }
            
            Section(header: Text("template_activities_title")) {
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
                    .padding(.vertical, 4)
                }
            }
            
            if filteredCategories.isEmpty && !searchText.isEmpty {
                Section {
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
                }
            } else {
                ForEach(Array(filteredCategories.enumerated()), id: \.element.id) { index, category in
                    Section {
                        ForEach(category.items) { item in
                            EditItemRow(
                                item: item,
                                categoryIndex: index,
                                template: $template
                            )
                        }
                        .onDelete { indexSet in
                            template.categories[index].items.remove(atOffsets: indexSet)
                        }
                        
                        Button(action: {
                            selectedCategoryIndex = index
                            showAddItem = true
                        }) {
                            Label("item_add", systemImage: "plus.circle")
                        }
                    } header: {
                        HStack {
                            Text(category.emoji)
                            Text(category.name)
                                .textCase(.none)
                        }
                    }
                }
                .onMove { from, to in
                    template.categories.move(fromOffsets: from, toOffset: to)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("templates_edit")
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
                    
                    Button("save") {
                        viewModel.updateTemplate(template)
                        dismiss()
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
                            let newCategory = CustomCategory(
                                id: UUID().uuidString,
                                name: newCategoryName,
                                emoji: selectedEmoji,
                                items: [],
                                sortOrder: template.categories.count
                            )
                            template.categories.append(newCategory)
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
        .sheet(isPresented: $showAddItem) {
            if let categoryIndex = selectedCategoryIndex {
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
                                let newItem = CustomItem(
                                    id: UUID().uuidString,
                                    name: newItemName,
                                    emoji: selectedEmoji,
                                    quantity: 1,
                                    note: nil,
                                    isRequired: false
                                )
                                template.categories[categoryIndex].items.append(newItem)
                                newItemName = ""
                                selectedEmoji = "📝"
                                showAddItem = false
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
                                showAddItem = false
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
    }
}

struct EditItemRow: View {
    let item: CustomItem
    let categoryIndex: Int
    @Binding var template: PackingTemplate
    @State private var isEditing = false
    @State private var editingText = ""
    @State private var showEmojiPicker = false
    @State private var showQuantityEditor = false
    
    var body: some View {
        HStack(spacing: 12) {
            Text(item.emoji)
                .font(.title2)
                .onTapGesture {
                    showEmojiPicker = true
                }
            
            if isEditing {
                TextField("", text: $editingText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        if let itemIndex = template.categories[categoryIndex].items.firstIndex(where: { $0.id == item.id }) {
                            template.categories[categoryIndex].items[itemIndex].name = editingText
                        }
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
            
            Button(action: { showQuantityEditor = true }) {
                Text("x\(item.quantity)")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(6)
            }
        }
        .sheet(isPresented: $showEmojiPicker) {
            NavigationStack {
                EmojiPickerView(selectedEmoji: Binding(
                    get: { item.emoji },
                    set: { newEmoji in
                        if let itemIndex = template.categories[categoryIndex].items.firstIndex(where: { $0.id == item.id }) {
                            template.categories[categoryIndex].items[itemIndex].emoji = newEmoji
                        }
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
                                if let itemIndex = template.categories[categoryIndex].items.firstIndex(where: { $0.id == item.id }) {
                                    template.categories[categoryIndex].items[itemIndex].quantity = max(1, min(99, newValue))
                                }
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
    }
}

#Preview {
    let mockTemplate = PackingTemplate(
        id: "preview",
        name: "Preview Template",
        description: "A template for preview",
        categories: [
            CustomCategory(
                id: "cat1",
                name: "Category 1",
                emoji: "📦",
                items: [
                    CustomItem(
                        id: "item1",
                        name: "Item 1",
                        emoji: "👕",
                        quantity: 1,
                        note: nil,
                        isRequired: true
                    )
                ],
                sortOrder: 0
            )
        ],
        activities: ["activity_hiking"],
        isShared: false,
        createdAt: Date(),
        updatedAt: Date()
    )
    
    return NavigationStack {
        EditTemplateView(template: mockTemplate, viewModel: TemplateViewModel())
    }
} 