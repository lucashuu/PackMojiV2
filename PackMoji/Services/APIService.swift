import Foundation
import Combine

// The main network service for the app
class APIService {
    static let shared = APIService()
    private var cancellables = Set<AnyCancellable>()
    
    // Base URL for the backend API
    private let baseURL = "http://192.168.1.156:3000/api/v1"
    
    // Network request timeout in seconds
    private let timeoutInterval: TimeInterval = 10

    private init() {}

    /**
     Generates a checklist by sending user inputs to the backend.
     - Parameters:
        - destination: The travel destination.
        - startDate: The start date of the trip.
        - endDate: The end date of the trip.
        - activities: An array of selected activities.
        - originCountry: The origin country of the trip.
     - Returns: A Combine publisher that emits a `ChecklistResponse` or an `Error`.
     */
    func generateChecklist(destination: String, startDate: Date, endDate: Date, activities: [String], originCountry: String) -> AnyPublisher<ChecklistResponse, Error> {
        let url = URL(string: "\(baseURL)/generate-checklist")!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let body = APIRequestBody(
            destination: destination,
            startDate: dateFormatter.string(from: startDate),
            endDate: dateFormatter.string(from: endDate),
            activities: activities,
            originCountry: originCountry
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval
        
        // Pass the user's language preference to the backend
        if let languageCode = Locale.current.language.languageCode?.identifier {
            request.setValue(languageCode, forHTTPHeaderField: "Accept-Language")
        }
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return Fail(error: NetworkError.encodingFailed).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200:
                    return data
                case 400:
                    // Try to decode error message from response
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw NetworkError.serverError(errorResponse.msg)
                    }
                    throw NetworkError.badRequest
                case 401:
                    throw NetworkError.unauthorized
                case 404:
                    throw NetworkError.notFound
                case 500...599:
                    throw NetworkError.serverError("Internal server error")
                default:
                    throw NetworkError.invalidResponse
                }
            }
            .mapError { error -> Error in
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .timedOut:
                        return NetworkError.timeout
                    case .notConnectedToInternet:
                        return NetworkError.noInternet
                    default:
                        return NetworkError.networkError(urlError.localizedDescription)
                    }
                }
                return error
            }
            .decode(type: ChecklistResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // Helper to format dates to "YYYY-MM-DD"
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// Private struct to match the API's expected request body
private struct APIRequestBody: Codable {
    let destination: String
    let startDate: String
    let endDate: String
    let activities: [String]
    let originCountry: String
}

// Define custom network errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case encodingFailed
    case decodingFailed
    case badRequest
    case unauthorized
    case notFound
    case serverError(String)
    case timeout
    case noInternet
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("The URL provided was invalid.", comment: "")
        case .invalidResponse:
            return NSLocalizedString("The server returned an invalid response.", comment: "")
        case .encodingFailed:
            return NSLocalizedString("Failed to encode the request body.", comment: "")
        case .decodingFailed:
            return NSLocalizedString("Failed to decode the server response.", comment: "")
        case .badRequest:
            return NSLocalizedString("Invalid request. Please check your input.", comment: "")
        case .unauthorized:
            return NSLocalizedString("Unauthorized access.", comment: "")
        case .notFound:
            return NSLocalizedString("The requested resource was not found.", comment: "")
        case .serverError(let message):
            return message
        case .timeout:
            return NSLocalizedString("The request timed out. Please try again.", comment: "")
        case .noInternet:
            return NSLocalizedString("No internet connection. Please check your network.", comment: "")
        case .networkError(let message):
            return message
        }
    }
}

// Error response from server
private struct ErrorResponse: Codable {
    let msg: String
} 