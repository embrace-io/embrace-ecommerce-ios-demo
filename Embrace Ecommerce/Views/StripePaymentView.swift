import SwiftUI
import Stripe

struct StripePaymentView: View {
    @ObservedObject var coordinator: CheckoutCoordinator
    @ObservedObject private var stripeService = StripePaymentService.shared
    @State private var isProcessingPayment = false
    @State private var showTestCardsInfo = false
    @State private var paymentError: String?
    @State private var showSuccessAlert = false

    private let embraceService = EmbraceService.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                stepHeader
                
                orderSummarySection
                
                stripePaymentSection
                
                testEnvironmentInfo
                
                Spacer(minLength: 20)
                
                continueButton
            }
            .padding()
        }
        .navigationTitle("Payment")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Payment Successful", isPresented: $showSuccessAlert) {
            Button("Continue") {
                coordinator.goToNextStep()
            }
        } message: {
            Text("Your payment has been processed successfully!")
        }
        .alert("Payment Error", isPresented: .constant(paymentError != nil)) {
            Button("OK") {
                paymentError = nil
            }
        } message: {
            Text(paymentError ?? "")
        }
    }
    
    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step \(coordinator.currentStep.stepNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Stripe Payment")
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
    
    private var stripePaymentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stripe Payment")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Secure payment powered by Stripe")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "lock.shield")
                    .foregroundColor(.green)
                Text("Your payment information is secure and encrypted")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(action: processStripePayment) {
                HStack {
                    if isProcessingPayment {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    }
                    
                    Text(isProcessingPayment ? "Processing..." : "Pay with Stripe")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if !isProcessingPayment {
                        Spacer()
                        
                        Image(systemName: "creditcard")
                            .font(.headline)
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(isProcessingPayment ? Color.gray : Color.blue)
                .cornerRadius(12)
            }
            .disabled(isProcessingPayment)
            
            Button(action: testFailurePayment) {
                HStack {
                    if isProcessingPayment {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    }
                    
                    Text(isProcessingPayment ? "Processing..." : "Test Payment Failure")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if !isProcessingPayment {
                        Spacer()
                        
                        Image(systemName: "xmark.circle")
                            .font(.subheadline)
                    }
                }
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isProcessingPayment ? Color.gray : Color.red)
                .cornerRadius(8)
            }
            .disabled(isProcessingPayment)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var testEnvironmentInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.orange)
                Text("Test Environment")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Button("Test Cards") {
                    showTestCardsInfo.toggle()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            Text("This is a test environment. No real payments will be processed.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if showTestCardsInfo {
                testCardsSection
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var testCardsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Test Card Numbers:")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ForEach(StripeTestCards.allTestCards, id: \.0) { card in
                HStack {
                    Text(card.0)
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Text(card.1)
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Use any future expiry date and any 3-digit CVC.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var continueButton: some View {
        VStack(spacing: 12) {
            Button("Back to Shipping") {
                coordinator.goToPreviousStep()
            }
            .font(.subheadline)
            .foregroundColor(.accentColor)
        }
    }
    
    private func processStripePayment() {
        isProcessingPayment = true

        // Flow 2: Track payment processing start
        embraceService.addBreadcrumb(message: "STRIPE_PAYMENT_PROCESSING_STARTED")

        Task {
            let result = await stripeService.processPayment(amount: coordinator.orderData.total)

            await handlePaymentResult(result)
        }
    }
    
    private func testFailurePayment() {
        isProcessingPayment = true
        
        Task {
            let result = await stripeService.simulatePaymentFailure()
            
            await handlePaymentResult(result)
        }
    }
    
    @MainActor
    private func handlePaymentResult(_ result: Result<StripePaymentResult, StripePaymentError>) {
        isProcessingPayment = false
        
        switch result {
        case .success(let paymentResult):
            // Flow 2: Track successful payment processing
            embraceService.addBreadcrumb(message: "STRIPE_PAYMENT_PROCESSING_SUCCESS")

            let stripePaymentMethod = PaymentMethod(
                id: UUID().uuidString,
                type: .stripe,
                isDefault: false,
                cardInfo: nil,
                digitalWalletInfo: nil,
                stripePaymentMethodId: paymentResult.paymentMethodId
            )
            coordinator.selectedPaymentMethod = stripePaymentMethod
            showSuccessAlert = true

        case .failure(let error):
            // Flow 2: Track payment processing failure
            embraceService.addBreadcrumb(message: "STRIPE_PAYMENT_PROCESSING_FAILED")
            paymentError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationView {
        StripePaymentView(coordinator: CheckoutCoordinator(cartManager: CartManager()))
    }
}