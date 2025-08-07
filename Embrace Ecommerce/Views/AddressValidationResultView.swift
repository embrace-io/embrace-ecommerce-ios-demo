import SwiftUI

struct AddressValidationResultView: View {
    let result: AddressValidationResult
    let originalAddress: Address
    let onAcceptSuggestion: (Address) -> Void
    let onKeepOriginal: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerSection
                
                if result.hasSuggestion {
                    suggestionSection
                } else if result.hasErrors {
                    errorsSection
                } else {
                    validSection
                }
                
                Spacer()
                
                actionButtons
            }
            .padding()
            .navigationTitle("Address Validation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: result.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(result.isValid ? .green : .orange)
            
            Text(result.isValid ? "Address Verified" : "Address Needs Review")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Confidence: \(Int(result.confidence * 100))%")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("We found a suggested correction:")
                .font(.headline)
            
            VStack(spacing: 12) {
                AddressComparisonCard(
                    title: "Your Address",
                    address: originalAddress,
                    isSelected: false,
                    showCheckmark: false
                )
                
                Image(systemName: "arrow.down")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                if let suggested = result.suggestedAddress {
                    AddressComparisonCard(
                        title: "Suggested Address",
                        address: suggested,
                        isSelected: true,
                        showCheckmark: true
                    )
                }
            }
        }
    }
    
    private var errorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Address Issues Found:")
                .font(.headline)
                .foregroundColor(.red)
            
            ForEach(Array(result.errors.enumerated()), id: \.offset) { index, error in
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    
                    Text(error.localizedDescription)
                        .font(.subheadline)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            AddressComparisonCard(
                title: "Your Address",
                address: originalAddress,
                isSelected: false,
                showCheckmark: false
            )
        }
    }
    
    private var validSection: some View {
        VStack(spacing: 16) {
            Text("Your address has been verified and is ready to use.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            AddressComparisonCard(
                title: "Verified Address",
                address: originalAddress,
                isSelected: true,
                showCheckmark: true
            )
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if result.hasSuggestion, let suggested = result.suggestedAddress {
                Button {
                    onAcceptSuggestion(suggested)
                    dismiss()
                } label: {
                    Text("Use Suggested Address")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            
            Button {
                onKeepOriginal()
                dismiss()
            } label: {
                Text(result.hasSuggestion ? "Keep My Address" : "Continue Anyway")
                    .font(.headline)
                    .foregroundColor(result.hasErrors ? .red : .blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(result.hasErrors ? Color.red : Color.blue, lineWidth: 1)
                    )
            }
        }
    }
}

struct AddressComparisonCard: View {
    let title: String
    let address: Address
    let isSelected: Bool
    let showCheckmark: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if showCheckmark {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(address.fullName)
                    .font(.headline)
                
                Text(address.formattedAddress)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .cornerRadius(12)
    }
}

struct AddressSuggestionsView: View {
    let suggestions: [AddressSuggestion]
    let onSelectSuggestion: (AddressSuggestion) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(suggestions) { suggestion in
                        SuggestionRow(suggestion: suggestion) {
                            onSelectSuggestion(suggestion)
                        }
                    }
                } header: {
                    Text("Address Suggestions")
                } footer: {
                    Text("Select an address to auto-fill the form")
                        .font(.caption)
                }
            }
            .navigationTitle("Address Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SuggestionRow: View {
    let suggestion: AddressSuggestion
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.formattedAddress)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        
                        Text("Confidence: \(Int(suggestion.confidence * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let sampleAddress = Address(
        id: "1",
        firstName: "John",
        lastName: "Doe",
        street: "123 Main St",
        street2: nil,
        city: "San Francisco",
        state: "CA",
        zipCode: "94105",
        country: "US",
        isDefault: false,
        type: .shipping
    )
    
    let sampleResult = AddressValidationResult(
        isValid: false,
        suggestedAddress: sampleAddress,
        confidence: 0.85,
        errors: []
    )
    
    AddressValidationResultView(
        result: sampleResult,
        originalAddress: sampleAddress,
        onAcceptSuggestion: { _ in },
        onKeepOriginal: { }
    )
}