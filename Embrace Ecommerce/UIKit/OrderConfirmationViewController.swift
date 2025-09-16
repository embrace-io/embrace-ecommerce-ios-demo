import UIKit
import SwiftUI

class OrderConfirmationViewController: UIViewController {
    private let coordinator: CheckoutCoordinator
    private let cartManager: CartManager
    
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var stackView: UIStackView!
    
    private var orderSummaryView: OrderSummaryView!
    private var shippingDetailsView: ShippingDetailsView!
    private var paymentDetailsView: PaymentDetailsView!
    private var placeOrderButton: UIButton!
    private var backButton: UIButton!
    
    @Published private var isProcessingOrder = false
    @Published private var orderError: Error?
    
    init(coordinator: CheckoutCoordinator, cartManager: CartManager) {
        self.coordinator = coordinator
        self.cartManager = cartManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "orderConfirmationView"
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Order Confirmation"
        
        setupScrollView()
        setupStepHeader()
        setupOrderSummaryView()
        setupShippingDetailsView()
        setupPaymentDetailsView()
        setupButtons()
        setupNavigationBar()
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.accessibilityIdentifier = "orderConfirmationScrollView"
        view.addSubview(scrollView)

        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.accessibilityIdentifier = "orderConfirmationContentView"
        scrollView.addSubview(contentView)

        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.accessibilityIdentifier = "orderConfirmationStackView"
        contentView.addSubview(stackView)
    }
    
    private func setupStepHeader() {
        let stepLabel = UILabel()
        stepLabel.text = "Step \(coordinator.currentStep.stepNumber)"
        stepLabel.font = .systemFont(ofSize: 12, weight: .medium)
        stepLabel.textColor = .secondaryLabel
        stepLabel.accessibilityIdentifier = "orderConfirmationStepLabel"

        let titleLabel = UILabel()
        titleLabel.text = coordinator.currentStep.title
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.accessibilityIdentifier = "orderConfirmationTitleLabel"

        let headerStack = UIStackView(arrangedSubviews: [stepLabel, titleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 4
        headerStack.accessibilityIdentifier = "orderConfirmationHeaderStack"

        stackView.addArrangedSubview(headerStack)
    }
    
    private func setupOrderSummaryView() {
        orderSummaryView = OrderSummaryView(coordinator: coordinator)
        orderSummaryView.accessibilityIdentifier = "orderConfirmationSummaryView"
        stackView.addArrangedSubview(orderSummaryView)
    }
    
    private func setupShippingDetailsView() {
        shippingDetailsView = ShippingDetailsView(coordinator: coordinator)
        shippingDetailsView.accessibilityIdentifier = "orderConfirmationShippingDetailsView"
        stackView.addArrangedSubview(shippingDetailsView)
    }
    
    private func setupPaymentDetailsView() {
        paymentDetailsView = PaymentDetailsView(coordinator: coordinator)
        paymentDetailsView.accessibilityIdentifier = "orderConfirmationPaymentDetailsView"
        stackView.addArrangedSubview(paymentDetailsView)
    }
    
    private func setupButtons() {
        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        placeOrderButton = UIButton(type: .system)
        placeOrderButton.setTitle("Place Order", for: .normal)
        placeOrderButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        placeOrderButton.backgroundColor = .systemGreen
        placeOrderButton.setTitleColor(.white, for: .normal)
        placeOrderButton.layer.cornerRadius = 12
        placeOrderButton.addTarget(self, action: #selector(placeOrderTapped), for: .touchUpInside)
        placeOrderButton.translatesAutoresizingMaskIntoConstraints = false
        placeOrderButton.accessibilityIdentifier = "placeOrderButton"

        backButton = UIButton(type: .system)
        backButton.setTitle("Back to Payment", for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 16)
        backButton.setTitleColor(.systemBlue, for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.accessibilityIdentifier = "backToPaymentButton"
        
        buttonStack.addArrangedSubview(placeOrderButton)
        buttonStack.addArrangedSubview(backButton)
        buttonStack.accessibilityIdentifier = "orderConfirmationButtonStack"

        view.addSubview(buttonStack)
        
        NSLayoutConstraint.activate([
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            placeOrderButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupNavigationBar() {
        navigationItem.hidesBackButton = true
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -120),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    @objc private func placeOrderTapped() {
        Task {
            await placeOrder()
        }
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func placeOrder() async {
        DispatchQueue.main.async {
            self.isProcessingOrder = true
            self.placeOrderButton.isEnabled = false
            self.placeOrderButton.setTitle("Processing...", for: .normal)
            self.placeOrderButton.backgroundColor = .systemGray
        }
        
        let result = await coordinator.placeOrder()
        
        DispatchQueue.main.async {
            self.isProcessingOrder = false
            self.placeOrderButton.isEnabled = true
            self.placeOrderButton.setTitle("Place Order", for: .normal)
            self.placeOrderButton.backgroundColor = .systemGreen
            
            switch result {
            case .success(let order):
                self.handleOrderSuccess(order)
            case .failure(let error):
                self.handleOrderError(error)
            }
        }
    }
    
    private func handleOrderSuccess(_ order: Order) {
        cartManager.clearCart()
        
        let alert = UIAlertController(
            title: "Order Placed Successfully!",
            message: "Your order #\(order.orderNumber) has been placed. You'll receive a confirmation email shortly.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Continue Shopping", style: .default) { _ in
            self.navigationController?.popToRootViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func handleOrderError(_ error: Error) {
        let alert = UIAlertController(
            title: "Order Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Try Again", style: .default))
        
        present(alert, animated: true)
    }
}

class OrderSummaryView: UIView {
    private let coordinator: CheckoutCoordinator
    
    init(coordinator: CheckoutCoordinator) {
        self.coordinator = coordinator
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        accessibilityIdentifier = "orderSummaryContainer"

        let titleLabel = UILabel()
        titleLabel.text = "Order Summary"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.accessibilityIdentifier = "orderSummaryTitleLabel"
        
        let itemsStackView = UIStackView()
        itemsStackView.axis = .vertical
        itemsStackView.spacing = 8
        itemsStackView.translatesAutoresizingMaskIntoConstraints = false
        itemsStackView.accessibilityIdentifier = "orderSummaryItemsStack"
        
        for item in coordinator.orderData.items.prefix(3) {
            let itemView = createItemView(for: item)
            itemsStackView.addArrangedSubview(itemView)
        }
        
        if coordinator.orderData.items.count > 3 {
            let moreItemsLabel = UILabel()
            moreItemsLabel.text = "... and \(coordinator.orderData.items.count - 3) more items"
            moreItemsLabel.font = .systemFont(ofSize: 12)
            moreItemsLabel.textColor = .secondaryLabel
            moreItemsLabel.accessibilityIdentifier = "orderSummaryMoreItemsLabel"
            itemsStackView.addArrangedSubview(moreItemsLabel)
        }
        
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.accessibilityIdentifier = "orderSummaryDivider"
        
        let totalsStackView = createTotalsView()
        
        addSubview(titleLabel)
        addSubview(itemsStackView)
        addSubview(divider)
        addSubview(totalsStackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            itemsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            itemsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            itemsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            divider.topAnchor.constraint(equalTo: itemsStackView.bottomAnchor, constant: 16),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            divider.heightAnchor.constraint(equalToConstant: 1),
            
            totalsStackView.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 16),
            totalsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            totalsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            totalsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    private func createItemView(for item: OrderItem) -> UIView {
        let container = UIView()
        container.accessibilityIdentifier = "orderSummaryItemContainer"
        
        let nameLabel = UILabel()
        nameLabel.text = item.productName
        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.accessibilityIdentifier = "orderSummaryItemNameLabel"

        let qtyLabel = UILabel()
        qtyLabel.text = "Qty: \(item.quantity)"
        qtyLabel.font = .systemFont(ofSize: 12)
        qtyLabel.textColor = .secondaryLabel
        qtyLabel.translatesAutoresizingMaskIntoConstraints = false
        qtyLabel.accessibilityIdentifier = "orderSummaryItemQtyLabel"

        let priceLabel = UILabel()
        priceLabel.text = "$\(String(format: "%.2f", item.totalPrice))"
        priceLabel.font = .systemFont(ofSize: 14, weight: .medium)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.accessibilityIdentifier = "orderSummaryItemPriceLabel"
        
        container.addSubview(nameLabel)
        container.addSubview(qtyLabel)
        container.addSubview(priceLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: container.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: priceLabel.leadingAnchor, constant: -8),
            
            qtyLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            qtyLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            qtyLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            priceLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        return container
    }
    
    private func createTotalsView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.accessibilityIdentifier = "orderSummaryTotalsStack"
        
        stackView.addArrangedSubview(createTotalRow("Subtotal", value: coordinator.orderData.subtotal))
        stackView.addArrangedSubview(createTotalRow("Shipping", value: coordinator.orderData.shipping))
        stackView.addArrangedSubview(createTotalRow("Tax", value: coordinator.orderData.tax))
        
        let totalRow = createTotalRow("Total", value: coordinator.orderData.total, isTotal: true)
        stackView.addArrangedSubview(totalRow)
        
        return stackView
    }
    
    private func createTotalRow(_ title: String, value: Double, isTotal: Bool = false) -> UIView {
        let container = UIView()
        container.accessibilityIdentifier = "orderSummary\(title.replacingOccurrences(of: " ", with: ""))Row"
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = isTotal ? .systemFont(ofSize: 16, weight: .semibold) : .systemFont(ofSize: 14)
        titleLabel.textColor = isTotal ? .label : .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.accessibilityIdentifier = "orderSummary\(title.replacingOccurrences(of: " ", with: ""))TitleLabel"

        let valueLabel = UILabel()
        valueLabel.text = "$\(String(format: "%.2f", value))"
        valueLabel.font = isTotal ? .systemFont(ofSize: 16, weight: .semibold) : .systemFont(ofSize: 14)
        valueLabel.textColor = isTotal ? .label : .secondaryLabel
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.accessibilityIdentifier = "orderSummary\(title.replacingOccurrences(of: " ", with: ""))ValueLabel"
        
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
}

class ShippingDetailsView: UIView {
    private let coordinator: CheckoutCoordinator
    
    init(coordinator: CheckoutCoordinator) {
        self.coordinator = coordinator
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        accessibilityIdentifier = "shippingDetailsContainer"

        let titleLabel = UILabel()
        titleLabel.text = "Shipping Details"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.accessibilityIdentifier = "shippingDetailsTitleLabel"

        let addressLabel = UILabel()
        addressLabel.text = coordinator.selectedShippingAddress?.formattedAddress ?? "No address selected"
        addressLabel.font = .systemFont(ofSize: 14)
        addressLabel.numberOfLines = 0
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.accessibilityIdentifier = "shippingDetailsAddressLabel"

        let methodLabel = UILabel()
        methodLabel.text = coordinator.selectedShippingMethod?.displayName ?? "No shipping method selected"
        methodLabel.font = .systemFont(ofSize: 14)
        methodLabel.translatesAutoresizingMaskIntoConstraints = false
        methodLabel.accessibilityIdentifier = "shippingDetailsMethodLabel"
        
        addSubview(titleLabel)
        addSubview(addressLabel)
        addSubview(methodLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            addressLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            addressLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            addressLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            methodLabel.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 8),
            methodLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            methodLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            methodLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
}

class PaymentDetailsView: UIView {
    private let coordinator: CheckoutCoordinator
    
    init(coordinator: CheckoutCoordinator) {
        self.coordinator = coordinator
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        accessibilityIdentifier = "paymentDetailsContainer"

        let titleLabel = UILabel()
        titleLabel.text = "Payment Method"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.accessibilityIdentifier = "paymentDetailsTitleLabel"

        let paymentLabel = UILabel()
        if let paymentMethod = coordinator.selectedPaymentMethod {
            if let cardInfo = paymentMethod.cardInfo {
                paymentLabel.text = cardInfo.displayName
            } else if let walletInfo = paymentMethod.digitalWalletInfo {
                paymentLabel.text = walletInfo.displayName
            } else {
                paymentLabel.text = paymentMethod.type.rawValue.capitalized
            }
        } else {
            paymentLabel.text = "No payment method selected"
        }
        paymentLabel.font = .systemFont(ofSize: 14)
        paymentLabel.translatesAutoresizingMaskIntoConstraints = false
        paymentLabel.accessibilityIdentifier = "paymentDetailsPaymentLabel"
        
        addSubview(titleLabel)
        addSubview(paymentLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            paymentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            paymentLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            paymentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            paymentLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
}