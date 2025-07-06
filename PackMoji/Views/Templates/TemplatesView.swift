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
                                    Label("delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                        }
                    } header: {
                        Text("templates_swipe_to_delete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(nil)
                    }
                }
            }
            .listStyle(.grouped)
            .navigationTitle("templates_title")
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
            .onAppear {
                viewModel.refreshTemplates()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TemplateCreated"))) { _ in
                viewModel.refreshTemplates()
            }
        }
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
                .background(Color(.systemBackground))
                .cornerRadius(10)
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