import Foundation
import EmbraceIO
import OpenTelemetryApi

enum AddressValidationError: LocalizedError {
    case invalidStreetAddress
    case invalidCity
    case invalidState
    case invalidZipCode
    case unserviceableArea
    case networkTimeout
    case serviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidStreetAddress:
            return "Please enter a valid street address"
        case .invalidCity:
            return "Please enter a valid city name"
        case .invalidState:
            return "Please enter a valid state"
        case .invalidZipCode:
            return "Please enter a valid ZIP code"
        case .unserviceableArea:
            return "We don't deliver to this area"
        case .networkTimeout:
            return "Address validation timed out. Please try again"
        case .serviceUnavailable:
            return "Address validation service is temporarily unavailable"
        }
    }
}

struct AddressValidationResult {
    let isValid: Bool
    let suggestedAddress: Address?
    let confidence: Double
    let errors: [AddressValidationError]
    
    var hasErrors: Bool {
        return !errors.isEmpty
    }
    
    var hasSuggestion: Bool {
        return suggestedAddress != nil
    }
}

struct AddressSuggestion: Identifiable {
    let id = UUID()
    let formattedAddress: String
    let street: String
    let street2: String?
    let city: String
    let state: String
    let zipCode: String
    let country: String
    let confidence: Double
}

@MainActor
class AddressValidationService: ObservableObject {
    private let mockNetworkService: MockNetworkService
    private let embraceService = EmbraceService.shared

    @Published var isValidating = false
    @Published var validationResults: [String: AddressValidationResult] = [:]

    init(mockNetworkService: MockNetworkService = .shared) {
        self.mockNetworkService = mockNetworkService
    }

    func validateAddress(_ address: Address, simulateError: Bool = false) async throws -> AddressValidationResult {
        isValidating = true
        defer { isValidating = false }

        let span = Embrace.client?.buildSpan(name: "address_validation", type: .performance).startSpan()
        span?.setAttribute(key: "address.city", value: address.city)
        span?.setAttribute(key: "address.state", value: address.state)
        span?.setAttribute(key: "address.zip_code", value: address.zipCode)
        span?.setAttribute(key: "address.country", value: address.country)

        do {
            let result = try await performValidation(address, simulateError: simulateError)
            validationResults[address.id] = result

            span?.setAttribute(key: "validation.is_valid", value: String(result.isValid))
            span?.setAttribute(key: "validation.confidence", value: String(result.confidence))
            span?.setAttribute(key: "validation.has_suggestion", value: String(result.hasSuggestion))
            span?.setAttribute(key: "validation.errors_count", value: String(result.errors.count))

            if result.hasErrors {
                embraceService.logWarning(
                    "Address validation completed with errors",
                    properties: [
                        "address_id": address.id,
                        "error_count": String(result.errors.count),
                        "errors": result.errors.map { $0.localizedDescription }.joined(separator: ", "),
                        "city": address.city,
                        "state": address.state
                    ]
                )
            } else {
                embraceService.logInfo(
                    "Address validation successful",
                    properties: [
                        "address_id": address.id,
                        "confidence": String(result.confidence),
                        "has_suggestion": String(result.hasSuggestion)
                    ]
                )
            }

            span?.end()
            return result

        } catch {
            span?.setAttribute(key: "error.type", value: String(describing: type(of: error)))
            span?.setAttribute(key: "error.message", value: error.localizedDescription)
            span?.end(errorCode: .failure)

            embraceService.logError(
                "Address validation failed",
                properties: [
                    "address_id": address.id,
                    "error_type": String(describing: type(of: error)),
                    "error_message": error.localizedDescription,
                    "city": address.city,
                    "state": address.state
                ]
            )

            throw error
        }
    }
    
    func searchAddressSuggestions(query: String) async throws -> [AddressSuggestion] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let span = Embrace.client?.buildSpan(name: "address_suggestions_search", type: .performance).startSpan()
        span?.setAttribute(key: "search.query", value: query)
        span?.setAttribute(key: "search.query_length", value: String(query.count))

        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...800_000_000))

        let suggestions = generateMockSuggestions(for: query)
        span?.setAttribute(key: "search.results_count", value: String(suggestions.count))
        span?.end()

        embraceService.logInfo(
            "Address suggestions retrieved",
            properties: [
                "query": query,
                "results_count": String(suggestions.count),
                "query_length": String(query.count)
            ]
        )

        return suggestions
    }
    
    private func performValidation(_ address: Address, simulateError: Bool) async throws -> AddressValidationResult {
        try await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...1_500_000_000))
        
        if simulateError {
            let randomError = [
                AddressValidationError.networkTimeout,
                AddressValidationError.serviceUnavailable,
                AddressValidationError.unserviceableArea
            ].randomElement()!
            throw randomError
        }
        
        let scenario = ValidationScenario.allCases.randomElement()!
        
        switch scenario {
        case .valid:
            return AddressValidationResult(
                isValid: true,
                suggestedAddress: nil,
                confidence: 0.95,
                errors: []
            )
            
        case .validWithSuggestion:
            let suggestion = generateSuggestedAddress(from: address)
            return AddressValidationResult(
                isValid: false,
                suggestedAddress: suggestion,
                confidence: 0.85,
                errors: []
            )
            
        case .invalidAddress:
            let errors = generateValidationErrors(for: address)
            return AddressValidationResult(
                isValid: false,
                suggestedAddress: nil,
                confidence: 0.2,
                errors: errors
            )
            
        case .partialMatch:
            let suggestion = generateSuggestedAddress(from: address)
            return AddressValidationResult(
                isValid: false,
                suggestedAddress: suggestion,
                confidence: 0.7,
                errors: [.invalidZipCode]
            )
        }
    }
    
    private func generateSuggestedAddress(from original: Address) -> Address {
        var suggestedStreet = original.street
        var suggestedZip = original.zipCode
        
        if original.street.contains("123") {
            suggestedStreet = original.street.replacingOccurrences(of: "123", with: "125")
        }
        
        if original.zipCode == "94105" {
            suggestedZip = "94104"
        }
        
        return Address(
            id: UUID().uuidString,
            firstName: original.firstName,
            lastName: original.lastName,
            street: suggestedStreet,
            street2: original.street2,
            city: original.city,
            state: original.state,
            zipCode: suggestedZip,
            country: original.country,
            isDefault: original.isDefault,
            type: original.type
        )
    }
    
    private func generateValidationErrors(for address: Address) -> [AddressValidationError] {
        var errors: [AddressValidationError] = []
        
        if address.street.count < 5 {
            errors.append(.invalidStreetAddress)
        }
        
        if address.zipCode.count != 5 || !address.zipCode.allSatisfy(\.isNumber) {
            errors.append(.invalidZipCode)
        }
        
        if address.city.count < 2 {
            errors.append(.invalidCity)
        }
        
        if address.state.count != 2 {
            errors.append(.invalidState)
        }
        
        if errors.isEmpty {
            errors.append(.unserviceableArea)
        }
        
        return errors
    }
    
    private func generateMockSuggestions(for query: String) -> [AddressSuggestion] {
        let commonStreets = [
            "Main Street", "Oak Street", "First Street", "Second Street",
            "Park Avenue", "Elm Street", "Washington Street", "Lincoln Avenue"
        ]
        
        let cities = [
            ("San Francisco", "CA", "94105"),
            ("New York", "NY", "10001"),
            ("Los Angeles", "CA", "90210"),
            ("Chicago", "IL", "60601"),
            ("Houston", "TX", "77001"),
            ("Phoenix", "AZ", "85001")
        ]
        
        var suggestions: [AddressSuggestion] = []
        
        for _ in 1...Int.random(in: 3...8) {
            let street = commonStreets.randomElement()!
            let (city, state, zipCode) = cities.randomElement()!
            let number = Int.random(in: 100...9999)
            
            let suggestion = AddressSuggestion(
                formattedAddress: "\(number) \(street), \(city), \(state) \(zipCode)",
                street: "\(number) \(street)",
                street2: nil,
                city: city,
                state: state,
                zipCode: zipCode,
                country: "US",
                confidence: Double.random(in: 0.7...0.95)
            )
            
            suggestions.append(suggestion)
        }
        
        return suggestions.sorted { $0.confidence > $1.confidence }
    }
    
    enum ValidationScenario: CaseIterable {
        case valid
        case validWithSuggestion
        case invalidAddress
        case partialMatch
    }
}