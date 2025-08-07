import SwiftUI

struct PaymentSelectionView: View {
    @ObservedObject var coordinator: CheckoutCoordinator
    @State private var selectedPaymentType: PaymentMethod.PaymentType = .creditCard
    @State private var showAddNewCard = false
    @State private var savedPaymentMethods: [PaymentMethod] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                stepHeader
                
                orderSummarySection
                
                paymentMethodsSection
                
                if selectedPaymentType == .creditCard && savedPaymentMethods.isEmpty {
                    creditCardFormSection
                }
                
                Spacer(minLength: 20)
                
                continueButton
            }
            .padding()
        }
        .navigationTitle("Payment")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSavedPaymentMethods()
        }
        .sheet(isPresented: $showAddNewCard) {
            AddNewCardView { paymentMethod in
                savedPaymentMethods.append(paymentMethod)
                coordinator.selectedPaymentMethod = paymentMethod
                showAddNewCard = false
            }
        }
    }
    
    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step \(coordinator.currentStep.stepNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(coordinator.currentStep.title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
    
    private var orderSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Subtotal")
                        .font(.subheadline)
                    Spacer()
                    Text("$\(String(format: "%.2f", coordinator.orderData.subtotal))")
                        .font(.subheadline)
                }
                
                HStack {
                    Text("Shipping")
                        .font(.subheadline)
                    Spacer()
                    Text("$\(String(format: "%.2f", coordinator.orderData.shipping))")
                        .font(.subheadline)
                }
                
                HStack {
                    Text("Tax")
                        .font(.subheadline)
                    Spacer()
                    Text("$\(String(format: "%.2f", coordinator.orderData.tax))")
                        .font(.subheadline)
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("$\(String(format: "%.2f", coordinator.orderData.total))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Payment Method")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if selectedPaymentType == .creditCard && !savedPaymentMethods.isEmpty {
                    Button("Add New Card") {
                        showAddNewCard = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                }
            }
            
            paymentTypeSelector
            
            if selectedPaymentType == .creditCard && !savedPaymentMethods.isEmpty {
                savedCardsSection
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var paymentTypeSelector: some View {
        VStack(spacing: 12) {
            PaymentOptionRow(
                type: .creditCard,
                title: "Credit/Debit Card",
                icon: "creditcard",
                isSelected: selectedPaymentType == .creditCard
            ) {
                selectedPaymentType = .creditCard
                if let firstCard = savedPaymentMethods.first {
                    coordinator.selectedPaymentMethod = firstCard
                } else {
                    coordinator.selectedPaymentMethod = nil
                }
            }
            
            PaymentOptionRow(
                type: .applePay,
                title: "Apple Pay",
                icon: "applelogo",
                isSelected: selectedPaymentType == .applePay
            ) {
                selectedPaymentType = .applePay
                let applePayMethod = PaymentMethod(
                    id: UUID().uuidString,
                    type: .applePay,
                    isDefault: false,
                    cardInfo: nil,
                    digitalWalletInfo: DigitalWalletInfo(email: nil, displayName: "Apple Pay")
                )
                coordinator.selectedPaymentMethod = applePayMethod
            }
            
            PaymentOptionRow(
                type: .paypal,
                title: "PayPal",
                icon: "p.circle",
                isSelected: selectedPaymentType == .paypal
            ) {
                selectedPaymentType = .paypal
                let paypalMethod = PaymentMethod(
                    id: UUID().uuidString,
                    type: .paypal,
                    isDefault: false,
                    cardInfo: nil,
                    digitalWalletInfo: DigitalWalletInfo(email: "user@example.com", displayName: "PayPal")
                )
                coordinator.selectedPaymentMethod = paypalMethod
            }
        }
    }
    
    private var savedCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved Cards")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            LazyVStack(spacing: 8) {
                ForEach(savedPaymentMethods) { method in
                    SavedCardRow(
                        paymentMethod: method,
                        isSelected: coordinator.selectedPaymentMethod?.id == method.id
                    ) {
                        coordinator.selectedPaymentMethod = method
                    }
                }
            }
        }
    }
    
    private var creditCardFormSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Card Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            CreditCardForm { cardInfo in
                let paymentMethod = PaymentMethod(
                    id: UUID().uuidString,
                    type: .creditCard,
                    isDefault: false,
                    cardInfo: cardInfo,
                    digitalWalletInfo: nil
                )
                coordinator.selectedPaymentMethod = paymentMethod
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var continueButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                coordinator.goToNextStep()
            }) {
                HStack {
                    Text("Review Order")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding()
                .background(coordinator.canProceedFromCurrentStep() ? Color.accentColor : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!coordinator.canProceedFromCurrentStep())
            
            Button("Back to Shipping") {
                coordinator.goToPreviousStep()
            }
            .font(.subheadline)
            .foregroundColor(.accentColor)
        }
    }
    
    private func loadSavedPaymentMethods() {
        savedPaymentMethods = [
            PaymentMethod(
                id: "1",
                type: .creditCard,
                isDefault: true,
                cardInfo: CardInfo(
                    last4: "4242",
                    brand: "visa",
                    expiryMonth: 12,
                    expiryYear: 2027,
                    holderName: "John Doe"
                ),
                digitalWalletInfo: nil
            ),
            PaymentMethod(
                id: "2",
                type: .creditCard,
                isDefault: false,
                cardInfo: CardInfo(
                    last4: "0005",
                    brand: "mastercard",
                    expiryMonth: 8,
                    expiryYear: 2026,
                    holderName: "John Doe"
                ),
                digitalWalletInfo: nil
            )
        ]
        
        if let defaultMethod = savedPaymentMethods.first(where: { $0.isDefault }) ?? savedPaymentMethods.first {
            coordinator.selectedPaymentMethod = defaultMethod
        }
    }
}

struct PaymentOptionRow: View {
    let type: PaymentMethod.PaymentType
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SavedCardRow: View {
    let paymentMethod: PaymentMethod
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                if let cardInfo = paymentMethod.cardInfo {
                    Image(systemName: "creditcard")
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cardInfo.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Expires \(cardInfo.expiryMonth)/\(cardInfo.expiryYear)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CreditCardForm: View {
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var cardholderName = ""
    
    let onCardInfoEntered: (CardInfo) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            TextField("Card Number", text: $cardNumber)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: cardNumber) { _, newValue in
                    validateAndUpdateCardInfo()
                }
            
            HStack {
                TextField("MM/YY", text: $expiryDate)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: expiryDate) { _, newValue in
                        validateAndUpdateCardInfo()
                    }
                
                TextField("CVV", text: $cvv)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: cvv) { _, newValue in
                        validateAndUpdateCardInfo()
                    }
            }
            
            TextField("Cardholder Name", text: $cardholderName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: cardholderName) { _, newValue in
                    validateAndUpdateCardInfo()
                }
        }
        .onAppear {
            cardNumber = "4242424242424242"
            expiryDate = "12/27"
            cvv = "123"
            cardholderName = "John Doe"
            validateAndUpdateCardInfo()
        }
    }
    
    private func validateAndUpdateCardInfo() {
        guard cardNumber.count >= 16,
              expiryDate.count >= 5,
              cvv.count >= 3,
              !cardholderName.isEmpty else {
            return
        }
        
        let expiryComponents = expiryDate.split(separator: "/")
        guard expiryComponents.count == 2,
              let month = Int(expiryComponents[0]),
              let year = Int("20\(expiryComponents[1])") else {
            return
        }
        
        let cardInfo = CardInfo(
            last4: String(cardNumber.suffix(4)),
            brand: determineBrand(from: cardNumber),
            expiryMonth: month,
            expiryYear: year,
            holderName: cardholderName
        )
        
        onCardInfoEntered(cardInfo)
    }
    
    private func determineBrand(from cardNumber: String) -> String {
        if cardNumber.hasPrefix("4") {
            return "visa"
        } else if cardNumber.hasPrefix("5") {
            return "mastercard"
        } else if cardNumber.hasPrefix("3") {
            return "amex"
        }
        return "unknown"
    }
}

struct AddNewCardView: View {
    let onCardAdded: (PaymentMethod) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Add New Card")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                CreditCardForm { cardInfo in
                    let paymentMethod = PaymentMethod(
                        id: UUID().uuidString,
                        type: .creditCard,
                        isDefault: false,
                        cardInfo: cardInfo,
                        digitalWalletInfo: nil
                    )
                    onCardAdded(paymentMethod)
                }
                .padding()
                
                Spacer()
            }
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

#Preview {
    NavigationView {
        PaymentSelectionView(coordinator: CheckoutCoordinator(cartManager: CartManager()))
    }
}