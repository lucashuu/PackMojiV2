import SwiftUI

struct CreateTemplateView: View {
    @ObservedObject var viewModel: TemplateViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var selectedActivities: Set<String> = []
    
    let activities = [
        "activity_hiking",
        "activity_business",
        "activity_photography",
        "activity_beach",
        "activity_shopping",
        "activity_skiing",
        "activity_city",
        "activity_camping",
        "activity_party"
    ]
    
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
    
    private func activityBinding(for activity: String) -> Binding<Bool> {
        Binding(
            get: { selectedActivities.contains(activity) },
            set: { isSelected in
                if isSelected {
                    selectedActivities.insert(activity)
                } else {
                    selectedActivities.remove(activity)
                }
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("template_name_placeholder", text: $name)
                    TextField("template_description_placeholder", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("template_activities_title") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(activities, id: \.self) { activity in
                                Toggle(isOn: activityBinding(for: activity)) {
                                    HStack(spacing: 4) {
                                        Text(getActivityEmoji(for: activity))
                                            .font(.caption)
                                        Text(LocalizedStringKey(activity))
                                            .font(.caption)
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
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done") {
                        createTemplate()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func createTemplate() {
        viewModel.createTemplate(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            activities: Array(selectedActivities)
        )
        dismiss()
    }
}

#Preview {
    CreateTemplateView(viewModel: TemplateViewModel())
} 