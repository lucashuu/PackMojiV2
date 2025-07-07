import SwiftUI
import Foundation

struct TemplatesView: View {
    @StateObject private var viewModel = TemplateViewModel()
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var isSelectionMode = false
    @State private var selectedTemplates: Set<String> = []
    @State private var showDeleteConfirmation = false
    
    var filteredTemplates: [PackingTemplate] {
        if searchText.isEmpty {
            return viewModel.templates
        }
        return viewModel.templates.filter { template in
            template.name.localizedCaseInsensitiveContains(searchText) ||
            template.description.localizedCaseInsensitiveContains(searchText) ||
            template.activities.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            templateListView
        }
    }
    
    private var templateListView: some View {
        List {
            if filteredTemplates.isEmpty {
                emptyStateView
            } else {
                templateSectionView
            }
        }
        .listStyle(.grouped)
        .navigationTitle("templates_title")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, isPresented: $showSearch, prompt: Text("search_placeholder"))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isSelectionMode {
                    Button("cancel") {
                        isSelectionMode = false
                        selectedTemplates.removeAll()
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 8) {
                    if isSelectionMode {
                        Button {
                            if !selectedTemplates.isEmpty {
                                showDeleteConfirmation = true
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 17))
                                .foregroundColor(selectedTemplates.isEmpty ? .gray : .red)
                        }
                        .disabled(selectedTemplates.isEmpty)
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
                        
                        NavigationLink(destination: CreateTemplateView(viewModel: viewModel)) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 17))
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.refreshTemplates()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TemplateCreated"))) { _ in
            viewModel.refreshTemplates()
        }
        .alert("confirm_delete_title", isPresented: $showDeleteConfirmation) {
            Button("cancel", role: .cancel) { }
            Button("delete", role: .destructive) {
                deleteSelectedTemplates()
            }
        } message: {
            Text(String(format: NSLocalizedString("confirm_delete_templates", comment: ""), selectedTemplates.count))
        }
    }
    
    private var emptyStateView: some View {
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
    
    private var templateSectionView: some View {
        Section {
            ForEach(filteredTemplates) { template in
                TemplateListItemView(
                    template: template,
                    isSelectionMode: isSelectionMode,
                    isSelected: selectedTemplates.contains(template.id),
                    onSelectionToggle: { toggleSelection(for: template) },
                    onDelete: { deleteTemplate(template) }
                )
            }
            .onDelete { indexSet in
                viewModel.deleteTemplates(at: indexSet)
            }
        } header: {
            Text("templates_swipe_to_delete")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(nil)
        }
    }
    
    private func toggleSelection(for template: PackingTemplate) {
        if selectedTemplates.contains(template.id) {
            selectedTemplates.remove(template.id)
        } else {
            selectedTemplates.insert(template.id)
        }
    }
    
    private func deleteTemplate(_ template: PackingTemplate) {
        guard let index = filteredTemplates.firstIndex(where: { $0.id == template.id }) else { return }
        viewModel.deleteTemplates(at: IndexSet([index]))
    }
    
    private func deleteSelectedTemplates() {
        let indicesToDelete = IndexSet(filteredTemplates.enumerated().compactMap { index, template in
            selectedTemplates.contains(template.id) ? index : nil
        })
        
        viewModel.deleteTemplates(at: indicesToDelete)
        
        // 清理选择状态
        selectedTemplates.removeAll()
        isSelectionMode = false
    }
}

struct TemplateRowView: View {
    let template: PackingTemplate
    
    // Activity emoji mapping (consistent with HomeView)
    private func getActivityEmoji(for activity: String) -> String {
        switch activity {
        case "activity_beach":
            return "🏖️"
        case "activity_hiking":
            return "🏃"
        case "activity_camping":
            return "⛺️"
        case "activity_business":
            return "💼"
        case "activity_skiing":
            return "⛷️"
        case "activity_party":
            return "🎉"
        case "activity_city":
            return "🏙️"
        case "activity_photography":
            return "📸"
        case "activity_shopping":
            return "🛍️"
        default:
            return "🎯"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Template Info Card
            VStack(alignment: .leading, spacing: 8) {
                Text(template.name)
                    .font(.headline)
                
                Text(template.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Travel Types Card
            if !template.activities.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("template_travel_types")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
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
                .padding(.vertical, 8)
            }
        }
        .padding(.vertical, 8)
    }
}

struct TemplateListItemView: View {
    let template: PackingTemplate
    let isSelectionMode: Bool
    let isSelected: Bool
    let onSelectionToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // Selection Circle
            if isSelectionMode {
                selectionButton
            }
            
            // Template Content
            templateContent
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("delete", systemImage: "trash")
            }
            .tint(.red)
        }
    }
    
    private var selectionButton: some View {
        Button {
            onSelectionToggle()
        } label: {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .accentColor : .gray)
                .font(.system(size: 20))
        }
        .buttonStyle(.plain)
        .padding(.trailing, 8)
    }
    
    private var templateContent: some View {
        Group {
            if isSelectionMode {
                TemplateRowView(template: template)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectionToggle()
                    }
            } else {
                NavigationLink(destination: TemplateDetailView(template: template)) {
                    TemplateRowView(template: template)
                }
            }
        }
    }
}

struct EmptyTemplatesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("templates_empty")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .listRowBackground(Color.clear)
    }
}

#Preview {
    NavigationStack {
        TemplatesView()
    }
} 