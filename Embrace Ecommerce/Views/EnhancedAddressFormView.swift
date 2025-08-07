import SwiftUI

struct EnhancedAddressFormView: View {
    let address: Address?
    let addressType: Address.AddressType
    let onSave: (Address) -> Void
    let onValidationResult: ((AddressValidationResult) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var validationService = AddressValidationService()
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var street: String = ""
    @State private var street2: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var country: String = "US"
    @State private var isDefault: Bool = false
    
    @State private var showingValidationResults = false
    @State private var validationResult: AddressValidationResult?
    @State private var showingAddressSuggestions = false
    @State private var addressSuggestions: [AddressSuggestion] = []
    @State private var streetSearchText = ""
    
    @State private var fieldErrors: [String: String] = [:]
    @State private var isValidating = false
    
    private var isEditing: Bool {
        address != nil
    }
    
    private var isFormValid: Bool {
        return !firstName.isEmpty &&
               !lastName.isEmpty &&
               !street.isEmpty &&
               !city.isEmpty &&
               !state.isEmpty &&
               !zipCode.isEmpty &&
               fieldErrors.isEmpty
    }
    
    init(address: Address? = nil, 
         addressType: Address.AddressType = .both,
         onSave: @escaping (Address) -> Void,
         onValidationResult: ((AddressValidationResult) -> Void)? = nil) {
        self.address = address
        self.addressType = addressType
        self.onSave = onSave
        self.onValidationResult = onValidationResult
    }
    
    var body: some View {
        NavigationView {
            Form {
                personalInformationSection
                addressInformationSection
                addressValidationSection
                settingsSection
            }
            .navigationTitle(isEditing ? "Edit Address" : "Add Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveAddress()
                        }
                    }
                    .disabled(!isFormValid || isValidating)
                }
            }
            .onAppear {
                loadAddressData()
            }
            .sheet(isPresented: $showingValidationResults) {
                if let validationResult = validationResult {
                    AddressValidationResultView(
                        result: validationResult,
                        originalAddress: getCurrentAddress(),
                        onAcceptSuggestion: { suggestedAddress in
                            applySuggestedAddress(suggestedAddress)
                            showingValidationResults = false
                        },
                        onKeepOriginal: {
                            showingValidationResults = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showingAddressSuggestions) {
                AddressSuggestionsView(
                    suggestions: addressSuggestions,
                    onSelectSuggestion: { suggestion in
                        applyAddressSuggestion(suggestion)
                        showingAddressSuggestions = false
                    }
                )
            }
        }
    }
    
    private var personalInformationSection: some View {
        Section("Personal Information") {
            HStack {
                Image(systemName: "person")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                TextField("First Name", text: $firstName)
                    .onChange(of: firstName) {
                        validateField("firstName", value: firstName)
                    }
            }
            if let error = fieldErrors["firstName"] {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            HStack {
                Image(systemName: "person")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                TextField("Last Name", text: $lastName)
                    .onChange(of: lastName) {
                        validateField("lastName", value: lastName)
                    }
            }
            if let error = fieldErrors["lastName"] {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
    
    private var addressInformationSection: some View {
        Section("Address Information") {
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                TextField("Street Address", text: $street)
                    .onChange(of: street) { _, newValue in
                        validateField("street", value: newValue)
                        streetSearchText = newValue
                        if newValue.count > 3 {
                            searchAddressSuggestions()
                        }
                    }
                
                if !addressSuggestions.isEmpty {
                    Button {
                        showingAddressSuggestions = true
                    } label: {
                        Image(systemName: "location.magnifyingglass")
                            .foregroundColor(.blue)
                    }
                }
            }
            if let error = fieldErrors["street"] {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                TextField("Apt, Suite, Unit (Optional)", text: $street2)
            }
            
            HStack {
                Image(systemName: "building.2")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                TextField("City", text: $city)
                    .onChange(of: city) {
                        validateField("city", value: city)
                    }
            }
            if let error = fieldErrors["city"] {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            HStack {
                HStack {
                    Image(systemName: "map")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    TextField("State", text: $state)
                        .onChange(of: state) {
                            validateField("state", value: state)
                        }
                        .textCase(.uppercase)
                        .autocapitalization(.allCharacters)
                }
                
                TextField("ZIP Code", text: $zipCode)
                    .keyboardType(.numberPad)
                    .onChange(of: zipCode) {
                        validateField("zipCode", value: zipCode)
                    }
            }
            if let error = fieldErrors["state"] ?? fieldErrors["zipCode"] {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Picker("Country", selection: $country) {
                Text("United States").tag("US")
                Text("Canada").tag("CA")
                Text("United Kingdom").tag("GB")
            }
        }
    }
    
    private var addressValidationSection: some View {
        Section {
            Button {
                Task {
                    await validateAddress()
                }
            } label: {
                HStack {
                    if isValidating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.shield")
                    }
                    Text("Validate Address")
                }
            }
            .disabled(isValidating || !canValidateAddress())
            
            if let result = validationResult {
                ValidationStatusView(result: result) {
                    showingValidationResults = true
                }
            }
        } header: {
            Text("Address Validation")
        }
    }
    
    private var settingsSection: some View {
        Section {
            Toggle("Set as default address", isOn: $isDefault)
        }
    }
    
    private func loadAddressData() {
        guard let address = address else { return }
        
        firstName = address.firstName
        lastName = address.lastName
        street = address.street
        street2 = address.street2 ?? ""
        city = address.city
        state = address.state
        zipCode = address.zipCode
        country = address.country
        isDefault = address.isDefault
    }
    
    private func getCurrentAddress() -> Address {
        return Address(
            id: address?.id ?? UUID().uuidString,
            firstName: firstName,
            lastName: lastName,
            street: street,
            street2: street2.isEmpty ? nil : street2,
            city: city,
            state: state,
            zipCode: zipCode,
            country: country,
            isDefault: isDefault,
            type: addressType
        )
    }
    
    private func saveAddress() async {
        if validationResult == nil {
            await validateAddress()
        }
        
        guard let result = validationResult else { return }
        
        if result.hasErrors && !result.hasSuggestion {
            return
        }
        
        let addressToSave = result.suggestedAddress ?? getCurrentAddress()
        onSave(addressToSave)
        dismiss()
    }
    
    private func validateAddress() async {
        isValidating = true
        
        let addressToValidate = getCurrentAddress()
        
        do {
            let result = try await validationService.validateAddress(addressToValidate)
            validationResult = result
            onValidationResult?(result)
            
            if result.hasErrors || result.hasSuggestion {
                showingValidationResults = true
            }
        } catch {
            fieldErrors["validation"] = error.localizedDescription
        }
        
        isValidating = false
    }
    
    private func searchAddressSuggestions() {
        Task {
            do {
                let suggestions = try await validationService.searchAddressSuggestions(query: streetSearchText)
                await MainActor.run {
                    addressSuggestions = suggestions
                }
            } catch {
                print("Address suggestion search failed: \(error)")
            }
        }
    }
    
    private func applySuggestedAddress(_ address: Address) {
        firstName = address.firstName
        lastName = address.lastName
        street = address.street
        street2 = address.street2 ?? ""
        city = address.city
        state = address.state
        zipCode = address.zipCode
        country = address.country
        
        validationResult = AddressValidationResult(
            isValid: true,
            suggestedAddress: nil,
            confidence: 1.0,
            errors: []
        )
    }
    
    private func applyAddressSuggestion(_ suggestion: AddressSuggestion) {
        street = suggestion.street
        street2 = suggestion.street2 ?? ""
        city = suggestion.city
        state = suggestion.state
        zipCode = suggestion.zipCode
        country = suggestion.country
        
        addressSuggestions = []
    }
    
    private func canValidateAddress() -> Bool {
        return !street.isEmpty && !city.isEmpty && !state.isEmpty && !zipCode.isEmpty
    }
    
    private func validateField(_ field: String, value: String) {
        fieldErrors.removeValue(forKey: field)
        
        switch field {
        case "firstName", "lastName":
            if value.isEmpty {
                fieldErrors[field] = "This field is required"
            }
        case "street":
            if value.isEmpty {
                fieldErrors[field] = "Street address is required"
            } else if value.count < 5 {
                fieldErrors[field] = "Please enter a complete street address"
            }
        case "city":
            if value.isEmpty {
                fieldErrors[field] = "City is required"
            } else if value.count < 2 {
                fieldErrors[field] = "Please enter a valid city name"
            }
        case "state":
            if value.isEmpty {
                fieldErrors[field] = "State is required"
            } else if value.count != 2 {
                fieldErrors[field] = "Please enter a 2-letter state code"
            }
        case "zipCode":
            if value.isEmpty {
                fieldErrors[field] = "ZIP code is required"
            } else if value.count != 5 || !value.allSatisfy(\.isNumber) {
                fieldErrors[field] = "Please enter a valid 5-digit ZIP code"
            }
        default:
            break
        }
    }
}

struct ValidationStatusView: View {
    let result: AddressValidationResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                
                VStack(alignment: .leading) {
                    Text(statusText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(statusDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusIcon: String {
        if result.isValid {
            return "checkmark.circle.fill"
        } else if result.hasSuggestion {
            return "exclamationmark.triangle.fill"
        } else {
            return "x.circle.fill"
        }
    }
    
    private var statusColor: Color {
        if result.isValid {
            return .green
        } else if result.hasSuggestion {
            return .orange
        } else {
            return .red
        }
    }
    
    private var statusText: String {
        if result.isValid {
            return "Address Verified"
        } else if result.hasSuggestion {
            return "Suggestion Available"
        } else {
            return "Address Issues Found"
        }
    }
    
    private var statusDescription: String {
        if result.isValid {
            return "Confidence: \(Int(result.confidence * 100))%"
        } else if result.hasSuggestion {
            return "Tap to review suggestion"
        } else {
            return "Tap to view errors"
        }
    }
}

#Preview {
    EnhancedAddressFormView(onSave: { _ in })
}