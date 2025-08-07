import SwiftUI

struct PaymentMethodsView: View {
    @StateObject private var profileManager = UserProfileManager()
    @State private var showingDeleteAlert = false
    @State private var paymentMethodToDelete: PaymentMethod?
    @State private var showingAddPayment = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if profileManager.paymentMethods.isEmpty && !profileManager.isLoading {
                    emptyStateView
                } else {
                    paymentMethodsList
                }
                
                if profileManager.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground).opacity(0.8))
                }
            }
            .navigationTitle("Payment Methods")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddPayment = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPayment) {
                AddPaymentMethodView()
            }
            .alert("Delete Payment Method", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let paymentMethod = paymentMethodToDelete {
                        Task {
                            await profileManager.deletePaymentMethod(id: paymentMethod.id)
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this payment method? This action cannot be undone.")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Payment Methods")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add a payment method to make checkout faster and more secure")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                showingAddPayment = true
            } label: {
                Text("Add Payment Method")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var paymentMethodsList: some View {
        List {
            ForEach(profileManager.paymentMethods) { paymentMethod in
                PaymentMethodRowView(paymentMethod: paymentMethod) {
                    paymentMethodToDelete = paymentMethod
                    showingDeleteAlert = true
                }
            }
        }
        .refreshable {
            await profileManager.loadPaymentMethods()
        }
    }
}

struct PaymentMethodRowView: View {
    let paymentMethod: PaymentMethod
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Payment method icon
            Image(systemName: paymentMethodIcon)
                .font(.title2)
                .foregroundColor(paymentMethodColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(paymentMethodTitle)
                    .font(.headline)
                
                Text(paymentMethodSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if paymentMethod.isDefault {
                    Text("Default")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
                
                Button("Delete") {
                    onDelete()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var paymentMethodIcon: String {
        switch paymentMethod.type {
        case .creditCard, .debitCard:
            return "creditcard"
        case .applePay:
            return "applelogo"
        case .paypal:
            return "globe"
        case .stripe:
            return "creditcard.and.123"
        }
    }
    
    private var paymentMethodColor: Color {
        switch paymentMethod.type {
        case .creditCard, .debitCard:
            return .blue
        case .applePay:
            return .black
        case .paypal:
            return .indigo
        case .stripe:
            return .purple
        }
    }
    
    private var paymentMethodTitle: String {
        if let cardInfo = paymentMethod.cardInfo {
            return cardInfo.displayName
        } else if let digitalWalletInfo = paymentMethod.digitalWalletInfo {
            return digitalWalletInfo.displayName
        } else {
            return paymentMethod.type.rawValue.capitalized
        }
    }
    
    private var paymentMethodSubtitle: String {
        if let cardInfo = paymentMethod.cardInfo {
            return "Expires \(String(format: "%02d", cardInfo.expiryMonth))/\(cardInfo.expiryYear)"
        } else if let digitalWalletInfo = paymentMethod.digitalWalletInfo {
            return digitalWalletInfo.email ?? "Digital Wallet"
        } else {
            return paymentMethod.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

struct AddPaymentMethodView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var paymentType: PaymentMethod.PaymentType = .creditCard
    @State private var cardNumber: String = ""
    @State private var expiryDate: String = ""
    @State private var cvv: String = ""
    @State private var cardholderName: String = ""
    @State private var isDefault: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Payment Type") {
                    Picker("Type", selection: $paymentType) {
                        Text("Credit Card").tag(PaymentMethod.PaymentType.creditCard)
                        Text("Debit Card").tag(PaymentMethod.PaymentType.debitCard)
                        Text("Apple Pay").tag(PaymentMethod.PaymentType.applePay)
                        Text("PayPal").tag(PaymentMethod.PaymentType.paypal)
                        Text("Stripe").tag(PaymentMethod.PaymentType.stripe)
                    }
                    .pickerStyle(.segmented)
                }
                
                if paymentType == .creditCard || paymentType == .debitCard {
                    cardInformationSection
                } else {
                    digitalWalletSection
                }
                
                Section {
                    Toggle("Set as default payment method", isOn: $isDefault)
                }
            }
            .navigationTitle("Add Payment Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePaymentMethod()
                        dismiss()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var cardInformationSection: some View {
        Section("Card Information") {
            HStack {
                Image(systemName: "creditcard")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                TextField("Card Number", text: $cardNumber)
                    .keyboardType(.numberPad)
                    .onChange(of: cardNumber) { _, newValue in
                        cardNumber = formatCardNumber(newValue)
                    }
            }
            
            HStack {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    TextField("MM/YY", text: $expiryDate)
                        .keyboardType(.numberPad)
                        .onChange(of: expiryDate) { _, newValue in
                            expiryDate = formatExpiryDate(newValue)
                        }
                }
                
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    SecureField("CVV", text: $cvv)
                        .keyboardType(.numberPad)
                        .onChange(of: cvv) { _, newValue in
                            cvv = String(newValue.prefix(4))
                        }
                }
            }
            
            HStack {
                Image(systemName: "person")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                TextField("Cardholder Name", text: $cardholderName)
                    .textContentType(.name)
                    .autocapitalization(.words)
            }
        }
    }
    
    private var digitalWalletSection: some View {
        Section("Digital Wallet") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: paymentType == .applePay ? "applelogo" : "globe")
                        .foregroundColor(paymentType == .applePay ? .black : .blue)
                    
                    Text("Connect your \(paymentType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized) account")
                        .font(.body)
                }
                
                Text(paymentType == .stripe ? "Stripe provides secure payment processing" : "You'll be redirected to authenticate with \(paymentType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
    
    private var isFormValid: Bool {
        if paymentType == .creditCard || paymentType == .debitCard {
            return !cardNumber.isEmpty &&
                   !expiryDate.isEmpty &&
                   !cvv.isEmpty &&
                   !cardholderName.isEmpty &&
                   cardNumber.count >= 15 &&
                   expiryDate.count == 5 &&
                   cvv.count >= 3
        } else {
            return true // Digital wallets just need authentication
        }
    }
    
    private func formatCardNumber(_ input: String) -> String {
        let digitsOnly = input.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
        let truncated = String(digitsOnly.prefix(16))
        
        var formatted = ""
        for (index, character) in truncated.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(character)
        }
        
        return formatted
    }
    
    private func formatExpiryDate(_ input: String) -> String {
        let digitsOnly = input.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
        let truncated = String(digitsOnly.prefix(4))
        
        if truncated.count >= 2 {
            let month = String(truncated.prefix(2))
            let year = String(truncated.suffix(truncated.count - 2))
            return "\(month)/\(year)"
        } else {
            return truncated
        }
    }
    
    private func savePaymentMethod() {
        // In a real app, this would integrate with Stripe or another payment processor
        // For now, this is just a mock implementation
        print("Saving payment method: \(paymentType)")
    }
}

#Preview {
    PaymentMethodsView()
}