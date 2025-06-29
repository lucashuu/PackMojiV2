import Foundation
import Combine
import MapKit // Import MapKit for MKLocalSearchCompletion

class HomeViewModel: ObservableObject {
    @Published var destination: String = ""
    @Published var startDate: Date?
    @Published var endDate: Date?
    @Published var selectedTags: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // For showing error alerts
    @Published var showErrorAlert: Bool = false

    // Flag to prevent search from re-triggering on programmatic selection
    private var isSelectingCompletion = false
    
    // Flag to prevent search when date picker is being opened
    private var isOpeningDatePicker = false

    // Use a DispatchWorkItem for debouncing to have full control over cancellation
    private var searchWorkItem: DispatchWorkItem?
    
    // Main cancellables set for long-lived subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // The location service for search completions
    @Published var locationService = LocationService()

    // The generated checklist response from the server
    @Published var checklistResponse: ChecklistResponse? = nil

    // Location-related properties
    @Published private(set) var userCountryCode: String?

    init() {
        // Request user's location on init
        locationService.requestUserLocation()

        // Subscribe to destination text changes for search debouncing
        $destination
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self = self, !self.isSelectingCompletion, !self.isOpeningDatePicker else {
                    self?.locationService.completions = []
                    return
                }
                
                // Only search if text is not empty and we're not in the middle of a programmatic change
                if !text.isEmpty {
                    self.locationService.updateQuery(text)
                } else {
                    self.locationService.completions = []
                }
            }
            .store(in: &cancellables)
            
        // Subscribe to the country code published by the location service
        locationService.$userCountryCode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] countryCode in
                self?.userCountryCode = countryCode
            }
            .store(in: &cancellables)
    }
    
    /// Handles the selection of a location from the suggestion list.
    func select(completion: MKLocalSearchCompletion) {
        // 1. Cancel any pending search before changing the text.
        searchWorkItem?.cancel()
        
        // 2. Set flag to prevent the text change from triggering a new search.
        isSelectingCompletion = true
        
        var fullTitle = completion.title
        if !completion.subtitle.isEmpty {
            fullTitle += ", \(completion.subtitle)"
        }
        // 3. Set the destination text. This fires the publisher, which will be ignored due to the flag.
        destination = fullTitle
        
        // 4. Clear the suggestions list immediately.
        locationService.completions = []
        
        // 5. Reset the flag on the next run loop, after the text change has been processed.
        DispatchQueue.main.async {
            self.isSelectingCompletion = false
        }
    }

    /// Call this when the destination text field loses focus.
    func destinationFieldLostFocus() {
        // When focus is lost, we should always cancel any pending search and hide the list.
        searchWorkItem?.cancel()
        locationService.completions = []
    }

    /// Call this when opening the date picker to prevent location suggestions from appearing
    func openDatePicker() {
        isOpeningDatePicker = true
        locationService.completions = []
    }
    
    /// Call this when closing the date picker
    func closeDatePicker() {
        isOpeningDatePicker = false
        locationService.completions = []
    }

    func generateChecklist() {
        guard let startDate = startDate, let endDate = endDate else {
            self.errorMessage = String(localized: "home_error_date_required")
            self.showErrorAlert = true
            return
        }
        
        guard !destination.isEmpty else {
            self.errorMessage = String(localized: "home_error_destination_required")
            self.showErrorAlert = true
            return
        }
        
        guard let originCountry = userCountryCode else {
            self.errorMessage = String(localized: "home_error_location_required")
            self.showErrorAlert = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let activities = Array(selectedTags)

        APIService.shared.generateChecklist(
            destination: destination,
            startDate: startDate,
            endDate: endDate,
            activities: activities,
            originCountry: originCountry
        )
        .sink(receiveCompletion: { [weak self] completion in
            self?.isLoading = false
            switch completion {
            case .failure(let error):
                print("API Error: \(error)")  // Add logging
                if let networkError = error as? NetworkError {
                    self?.errorMessage = networkError.localizedDescription
                } else {
                    self?.errorMessage = String(localized: "home_error_network")
                }
                self?.showErrorAlert = true
            case .finished:
                break
            }
        }, receiveValue: { [weak self] response in
            self?.checklistResponse = response
        })
        .store(in: &cancellables)
    }
} 