import SwiftUI
import Combine
import UIKit
import ElegantCalendar

// MARK: - Color System
extension Color {
    static let theme = ColorTheme()
    
    // Helper to initialize Color from a hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

struct ColorTheme {
    // System-adaptive colors
    let background = Color(UIColor.systemGray6)
    let cardBackground = Color(UIColor.secondarySystemBackground)
    
    // Custom adaptive colors from Assets
    let buttonBackground = Color("ThemeButton")
    let tagText = Color(UIColor.label) // Text on tags should also adapt
    
    let tagGreen = Color("TagGreen")
    let tagGray = Color("TagGray")
    let tagOrange = Color("TagOrange")
    let tagYellow = Color("TagYellow")
    let tagPink = Color("TagPink")
    let tagBlue = Color("TagBlue")
    let tagRed = Color("TagRed")
    let tagParty = Color("TagParty")
}

// MARK: - Models
struct Tag: Identifiable, Hashable {
    let name: LocalizedStringKey
    let icon: String
    let color: Color
    
    var id: String { name.stringKey }
    
    // Hashable implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }
}

extension LocalizedStringKey {
    var stringKey: String {
        let mirror = Mirror(reflecting: self)
        let key = mirror.children.first(where: { $0.label == "key" })?.value as? String
        return key ?? "unknown"
    }
}

// MARK: - Home View
struct HomeHeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("PackMoji")
                    .font(.system(size: 32, weight: .bold))
                Text("✈️")
                    .font(.system(size: 28))
            }
            Text("home_tagline")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .padding(.horizontal, 16)
    }
}

struct HomeDestinationView: View {
    @ObservedObject var viewModel: HomeViewModel
    let isDestinationFocused: FocusState<Bool>.Binding
    @Binding var showDateRangePicker: Bool
    
    private var dateRangeString: String {
        guard let startDate = viewModel.startDate, let endDate = viewModel.endDate else {
            return String(localized: "home_date_placeholder")
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.red)
                TextField("home_destination_placeholder", text: $viewModel.destination)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .focused(isDestinationFocused)
            }
            .padding(12)
            .onChange(of: isDestinationFocused.wrappedValue) {
                if !isDestinationFocused.wrappedValue {
                    viewModel.destinationFieldLostFocus()
                }
            }
            
            if !showDateRangePicker && !viewModel.locationService.completions.isEmpty {
                Divider().padding(.leading)
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.locationService.completions.enumerated()), id: \.offset) { index, completion in
                            Button(action: {
                                viewModel.select(completion: completion)
                                isDestinationFocused.wrappedValue = false
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(completion.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    if !completion.subtitle.isEmpty {
                                        Text(completion.subtitle)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            if index < viewModel.locationService.completions.count - 1 {
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                }
                .frame(height: min(CGFloat(viewModel.locationService.completions.count) * 60, 240))
            }
            
            Divider()
            
            Button(action: {
                isDestinationFocused.wrappedValue = false
                viewModel.destinationFieldLostFocus()
                showDateRangePicker = true
            }) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.red)
                    Text(dateRangeString)
                        .font(.system(size: 16))
                        .foregroundColor(viewModel.startDate == nil ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(12)
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}

struct HomeGenerateButton: View {
    @ObservedObject var viewModel: HomeViewModel
    let isDestinationFocused: FocusState<Bool>.Binding
    
    var body: some View {
        Button(action: {
            isDestinationFocused.wrappedValue = false
            viewModel.destinationFieldLostFocus()
            viewModel.generateChecklist()
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("home_generate_button")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.theme.buttonBackground)
            .cornerRadius(12)
        }
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .disabled(viewModel.isLoading)
        .padding(.bottom, 32)
        .padding(.horizontal, 16)
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTags = Set<String>()
    @FocusState private var isDestinationFocused: Bool
    @State private var showDateRangePicker = false
    @State private var isChecklistPresented = false
    
    private let tags: [Tag] = [
        Tag(name: LocalizedStringKey("activity_beach"), icon: "🏖️", color: .theme.tagBlue),
        Tag(name: LocalizedStringKey("activity_hiking"), icon: "🏃", color: .theme.tagGreen),
        Tag(name: LocalizedStringKey("activity_camping"), icon: "⛺️", color: .theme.tagOrange),
        Tag(name: LocalizedStringKey("activity_business"), icon: "💼", color: .theme.tagGray),
        Tag(name: LocalizedStringKey("activity_skiing"), icon: "⛷️", color: .theme.tagBlue),
        Tag(name: LocalizedStringKey("activity_party"), icon: "🎉", color: .theme.tagParty),
        Tag(name: LocalizedStringKey("activity_city"), icon: "🏙️", color: .theme.tagGreen),
        Tag(name: LocalizedStringKey("activity_photography"), icon: "📸", color: .theme.tagPink),
        Tag(name: LocalizedStringKey("activity_shopping"), icon: "🛍️", color: .theme.tagYellow)
    ]
    
    private var isDestinationFocusedBinding: Binding<Bool> {
        Binding(
            get: { isDestinationFocused },
            set: { isDestinationFocused = $0 }
        )
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: UIColor { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
                } else {
                    return UIColor.systemGroupedBackground
                }
            }).ignoresSafeArea()
                .onTapGesture {
                    isDestinationFocused = false
                }
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 16)
                    
                    HomeHeaderView()
                    
                    HomeDestinationView(
                        viewModel: viewModel,
                        isDestinationFocused: $isDestinationFocused,
                        showDateRangePicker: $showDateRangePicker
                    )
                    
                    HomeTagCloudView(
                        tags: tags,
                        selectedTags: $selectedTags,
                        isDestinationFocused: isDestinationFocusedBinding,
                        viewModel: viewModel
                    )
                    .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    HomeGenerateButton(
                        viewModel: viewModel,
                        isDestinationFocused: $isDestinationFocused
                    )
                }
                .padding(.top, 24)
            }
        }
        .sheet(isPresented: $showDateRangePicker) {
            DateRangePickerSheet(
                startDate: Binding(
                    get: { viewModel.startDate ?? Date() },
                    set: { viewModel.startDate = $0 }
                ),
                endDate: Binding(
                    get: { viewModel.endDate ?? (viewModel.startDate ?? Date()).addingTimeInterval(86400) },
                    set: { viewModel.endDate = $0 }
                )
            )
        }
        .alert(isPresented: $viewModel.showErrorAlert) {
            Alert(
                title: Text("home_error_alert_title"),
                message: Text(viewModel.errorMessage ?? "An unknown error occurred."),
                dismissButton: .default(Text("home_error_alert_button"))
            )
        }
        .navigationDestination(isPresented: $isChecklistPresented) {
            if let checklist = viewModel.checklistResponse?.categories,
               let tripInfo = viewModel.checklistResponse?.tripInfo {
                ChecklistView(viewModel: ChecklistViewModel(tripInfo: tripInfo, categories: checklist))
            }
        }
        .onChange(of: isChecklistPresented) {
            if !isChecklistPresented {
                viewModel.checklistResponse = nil
            }
        }
        .onChange(of: viewModel.checklistResponse) {
            if viewModel.checklistResponse != nil {
                isChecklistPresented = true
            }
        }
        .onChange(of: selectedTags) {
            viewModel.selectedTags = selectedTags
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Tag Cloud View (Upgraded with LazyVGrid)
struct TagCloudView: View {
    let tags: [Tag]
    @Binding var selectedTags: Set<String>
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(tags) { tag in
                Button(action: {
                    if selectedTags.contains(tag.id) {
                        selectedTags.remove(tag.id)
                    } else {
                        selectedTags.insert(tag.id)
                    }
                }) {
                    HStack(spacing: 8) {
                        Text(tag.icon)
                            .font(.system(size: 20))
                        Text(tag.name)
                            .font(.system(size: 15, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .padding(.horizontal, 16)
                    .background(tag.color)
                    .foregroundColor(Color.theme.tagText)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.theme.tagText, lineWidth: selectedTags.contains(tag.id) ? 2 : 0)
                    )
                }
            }
        }
    }
}

struct HomeTagCloudView: View {
    let tags: [Tag]
    @Binding var selectedTags: Set<String>
    @Binding var isDestinationFocused: Bool
    @ObservedObject var viewModel: HomeViewModel
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(tags) { tag in
                Button(action: {
                    isDestinationFocused = false
                    viewModel.destinationFieldLostFocus()
                    if selectedTags.contains(tag.id) {
                        selectedTags.remove(tag.id)
                    } else {
                        selectedTags.insert(tag.id)
                    }
                }) {
                    HStack(spacing: 8) {
                        Text(tag.icon)
                            .font(.system(size: 20))
                        Text(tag.name)
                            .font(.system(size: 15, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .padding(.horizontal, 16)
                    .background(tag.color)
                    .foregroundColor(Color.theme.tagText)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.theme.tagText, lineWidth: selectedTags.contains(tag.id) ? 2 : 0)
                    )
                }
            }
        }
    }
}

#Preview {
    HomeView()
} 
