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
    
    // Activity emoji mapping
    private func getActivityEmoji(for activity: String) -> String {
        switch activity {
        case "activity_travel":
            return "✈️"
        case "activity_business":
            return "💼"
        case "activity_vacation":
            return "🏖️"
        case "activity_camping":
            return "⛺️"
        case "activity_beach":
            return "🏖️"
        case "activity_city":
            return "🏙️"
        case "activity_hiking":
            return "🥾"
        case "activity_skiing":
            return "⛷️"
        case "activity_photography":
            return "📸"
        case "activity_shopping":
            return "🛍️"
        case "activity_party":
            return "🎉"
        default:
            return "🎯"
        }
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
            // Combined Template Info and Travel Types Section
            VStack(alignment: .leading, spacing: 16) {
                // Template Header
                VStack(alignment: .leading, spacing: 12) {
                    Text(template.name)
                        .font(.system(size: 28, weight: .bold))
                    Text(template.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Travel Types Section
                if !template.activities.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("template_travel_types")
                            .font(.system(size: 17, weight: .bold))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(template.activities, id: \.self) { activity in
                                    HStack(spacing: 4) {
                                        Text(getActivityEmoji(for: activity))
                                            .font(.caption)
                                        Text(LocalizedStringKey(activity))
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .listRowBackground(Color(UIColor.systemBackground))
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
        .listStyle(.grouped)
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
        .padding(.vertical, 4)
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
            Text(category.name)
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