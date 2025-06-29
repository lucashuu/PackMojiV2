import SwiftUI

struct TemplatesView: View {
    @StateObject private var viewModel = TemplateViewModel()
    @State private var searchText = ""
    @State private var showSearch = false
    
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
            List {
                if filteredTemplates.isEmpty {
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
                    Section {
                        ForEach(filteredTemplates) { template in
                            NavigationLink(destination: TemplateDetailView(template: template)) {
                                TemplateRowView(template: template)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteTemplates(at: IndexSet([filteredTemplates.firstIndex(where: { $0.id == template.id })!]))
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                        }
                    } header: {
                        Text("向左滑动可删除模版")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(nil)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("模版")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, isPresented: $showSearch, prompt: Text("search_placeholder"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSearch.toggle()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 17))
                    }
                }
            }
        }
    }
}

struct TemplateRowView: View {
    let template: PackingTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(template.name)
                .font(.headline)
            
            Text(template.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
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
        .padding(.vertical, 8)
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