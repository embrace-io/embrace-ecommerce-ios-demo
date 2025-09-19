import UIKit
import SwiftUI

class ShippingInformationViewController: UIViewController {
    private let coordinator: CheckoutCoordinator
    private let embraceService = EmbraceService.shared
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var stackView: UIStackView!
    
    private var shippingAddressSection: AddressSelectionView!
    private var billingAddressSection: AddressSelectionView!
    private var shippingMethodSection: ShippingMethodSelectionView!
    private var continueButton: UIButton!
    
    private var billingAddressSameAsShipping = true
    
    init(coordinator: CheckoutCoordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "shippingInformationView"
        setupUI()
        setupConstraints()
        updateContinueButton()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Shipping Information"
        
        setupScrollView()
        setupStepHeader()
        setupShippingAddressSection()
        setupBillingAddressSection()
        setupShippingMethodSection()
        setupContinueButton()
        setupNavigationBar()
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.accessibilityIdentifier = "shippingInformationScrollView"
        view.addSubview(scrollView)

        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.accessibilityIdentifier = "shippingInformationContentView"
        scrollView.addSubview(contentView)

        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.accessibilityIdentifier = "shippingInformationStackView"
        contentView.addSubview(stackView)
    }
    
    private func setupStepHeader() {
        let stepLabel = UILabel()
        stepLabel.text = "Step \(coordinator.currentStep.stepNumber)"
        stepLabel.font = .systemFont(ofSize: 12, weight: .medium)
        stepLabel.textColor = .secondaryLabel
        stepLabel.accessibilityIdentifier = "shippingInformationStepLabel"

        let titleLabel = UILabel()
        titleLabel.text = coordinator.currentStep.title
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.accessibilityIdentifier = "shippingInformationTitleLabel"

        let headerStack = UIStackView(arrangedSubviews: [stepLabel, titleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 4
        headerStack.accessibilityIdentifier = "shippingInformationHeaderStack"

        stackView.addArrangedSubview(headerStack)
    }
    
    private func setupShippingAddressSection() {
        shippingAddressSection = AddressSelectionView(
            title: "Shipping Address",
            addressType: .shipping
        )
        shippingAddressSection.delegate = self
        shippingAddressSection.accessibilityIdentifier = "shippingAddressSection"
        stackView.addArrangedSubview(shippingAddressSection)
    }
    
    private func setupBillingAddressSection() {
        let sameAsShippingSwitch = UISwitch()
        sameAsShippingSwitch.isOn = billingAddressSameAsShipping
        sameAsShippingSwitch.addTarget(self, action: #selector(billingAddressSwitchChanged(_:)), for: .valueChanged)
        sameAsShippingSwitch.accessibilityIdentifier = "billingAddressSameAsShippingSwitch"

        let switchLabel = UILabel()
        switchLabel.text = "Billing address same as shipping"
        switchLabel.font = .systemFont(ofSize: 16)
        switchLabel.accessibilityIdentifier = "billingAddressSameAsShippingLabel"
        
        let switchStack = UIStackView(arrangedSubviews: [switchLabel, sameAsShippingSwitch])
        switchStack.axis = .horizontal
        switchStack.spacing = 8
        switchStack.accessibilityIdentifier = "billingAddressSwitchStack"
        switchLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        billingAddressSection = AddressSelectionView(
            title: "Billing Address",
            addressType: .billing
        )
        billingAddressSection.delegate = self
        billingAddressSection.isHidden = billingAddressSameAsShipping
        billingAddressSection.accessibilityIdentifier = "billingAddressSection"
        
        stackView.addArrangedSubview(switchStack)
        stackView.addArrangedSubview(billingAddressSection)
    }
    
    private func setupShippingMethodSection() {
        shippingMethodSection = ShippingMethodSelectionView()
        shippingMethodSection.delegate = self
        shippingMethodSection.accessibilityIdentifier = "shippingMethodSection"
        stackView.addArrangedSubview(shippingMethodSection)
    }
    
    private func setupContinueButton() {
        continueButton = UIButton(type: .system)
        continueButton.setTitle("Continue to Payment", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueButton.backgroundColor = .systemBlue
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.setTitleColor(.lightGray, for: .disabled)
        continueButton.layer.cornerRadius = 12
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        continueButton.accessibilityIdentifier = "continueToPaymentButton"

        continueButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(continueButton)
    }
    
    private func setupNavigationBar() {
        let backBarButton = UIBarButtonItem(
            title: "Back",
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backBarButton.accessibilityIdentifier = "shippingInformationBackButton"
        navigationItem.leftBarButtonItem = backBarButton
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -16),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func billingAddressSwitchChanged(_ sender: UISwitch) {
        billingAddressSameAsShipping = sender.isOn
        billingAddressSection.isHidden = billingAddressSameAsShipping
        
        if billingAddressSameAsShipping {
            coordinator.selectedBillingAddress = coordinator.selectedShippingAddress
        } else {
            coordinator.selectedBillingAddress = nil
        }
        
        updateContinueButton()
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func continueButtonTapped() {
        // Flow 1: Track shipping information completion
        embraceService.addBreadcrumb(message: "SHIPPING_INFORMATION_COMPLETED")
        coordinator.goToNextStep()
    }
    
    private func updateContinueButton() {
        let canProceed = coordinator.canProceedFromCurrentStep()
        continueButton.isEnabled = canProceed
        continueButton.backgroundColor = canProceed ? .systemBlue : .systemGray4
    }
}

extension ShippingInformationViewController: AddressSelectionDelegate {
    func didSelectAddress(_ address: Address, for type: Address.AddressType) {
        switch type {
        case .shipping, .both:
            coordinator.selectedShippingAddress = address
            if billingAddressSameAsShipping {
                coordinator.selectedBillingAddress = address
            }
        case .billing:
            coordinator.selectedBillingAddress = address
        }
        updateContinueButton()
    }
}

extension ShippingInformationViewController: ShippingMethodSelectionDelegate {
    func didSelectShippingMethod(_ method: ShippingMethod) {
        coordinator.selectedShippingMethod = method
        updateContinueButton()
    }
}

protocol AddressSelectionDelegate: AnyObject {
    func didSelectAddress(_ address: Address, for type: Address.AddressType)
}

class AddressSelectionView: UIView {
    weak var delegate: AddressSelectionDelegate?
    private let title: String
    private let addressType: Address.AddressType
    private var selectedAddress: Address?
    
    private var titleLabel: UILabel!
    private var selectedAddressLabel: UILabel!
    private var selectButton: UIButton!
    
    init(title: String, addressType: Address.AddressType) {
        self.title = title
        self.addressType = addressType
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        accessibilityIdentifier = "addressSelectionContainer"

        titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.accessibilityIdentifier = "addressSelectionTitleLabel"

        selectedAddressLabel = UILabel()
        selectedAddressLabel.text = "No address selected"
        selectedAddressLabel.font = .systemFont(ofSize: 14)
        selectedAddressLabel.textColor = .secondaryLabel
        selectedAddressLabel.numberOfLines = 3
        selectedAddressLabel.translatesAutoresizingMaskIntoConstraints = false
        selectedAddressLabel.accessibilityIdentifier = "selectedAddressLabel"

        selectButton = UIButton(type: .system)
        selectButton.setTitle("Select Address", for: .normal)
        selectButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        selectButton.addTarget(self, action: #selector(selectButtonTapped), for: .touchUpInside)
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        selectButton.accessibilityIdentifier = "selectAddressButton"
        
        addSubview(titleLabel)
        addSubview(selectedAddressLabel)
        addSubview(selectButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            selectedAddressLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            selectedAddressLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            selectedAddressLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            selectButton.topAnchor.constraint(equalTo: selectedAddressLabel.bottomAnchor, constant: 12),
            selectButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            selectButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            selectButton.widthAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    @objc private func selectButtonTapped() {
        let sampleAddress = Address(
            id: UUID().uuidString,
            firstName: "John",
            lastName: "Doe",
            street: "123 Main St",
            street2: nil,
            city: "San Francisco",
            state: "CA",
            zipCode: "94105",
            country: "US",
            isDefault: true,
            type: addressType
        )
        
        selectedAddress = sampleAddress
        selectedAddressLabel.text = sampleAddress.formattedAddress
        selectedAddressLabel.textColor = .label
        selectButton.setTitle("Change Address", for: .normal)
        
        delegate?.didSelectAddress(sampleAddress, for: addressType)
    }
}

protocol ShippingMethodSelectionDelegate: AnyObject {
    func didSelectShippingMethod(_ method: ShippingMethod)
}

class ShippingMethodSelectionView: UIView {
    weak var delegate: ShippingMethodSelectionDelegate?
    private var selectedMethod: ShippingMethod?
    private let shippingMethods = [
        ShippingMethod(id: "standard", name: "Standard Shipping", description: "5-7 business days", cost: 0.0, estimatedDays: 7, isAvailable: true, trackingIncluded: true, insuranceIncluded: false),
        ShippingMethod(id: "express", name: "Express Shipping", description: "2-3 business days", cost: 9.99, estimatedDays: 3, isAvailable: true, trackingIncluded: true, insuranceIncluded: false),
        ShippingMethod(id: "overnight", name: "Overnight Shipping", description: "1 business day", cost: 24.99, estimatedDays: 1, isAvailable: true, trackingIncluded: true, insuranceIncluded: true)
    ]
    
    private var titleLabel: UILabel!
    private var methodsStackView: UIStackView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        accessibilityIdentifier = "shippingMethodSelectionContainer"

        titleLabel = UILabel()
        titleLabel.text = "Shipping Method"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.accessibilityIdentifier = "shippingMethodSelectionTitleLabel"

        methodsStackView = UIStackView()
        methodsStackView.axis = .vertical
        methodsStackView.spacing = 12
        methodsStackView.translatesAutoresizingMaskIntoConstraints = false
        methodsStackView.accessibilityIdentifier = "shippingMethodsStack"
        
        addSubview(titleLabel)
        addSubview(methodsStackView)
        
        for (index, method) in shippingMethods.enumerated() {
            let methodView = createMethodView(method: method, isSelected: index == 0)
            methodView.accessibilityIdentifier = "shippingMethod\(method.id)View"
            methodsStackView.addArrangedSubview(methodView)
            
            if index == 0 {
                selectedMethod = method
                delegate?.didSelectShippingMethod(method)
            }
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            methodsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            methodsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            methodsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            methodsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    private func createMethodView(method: ShippingMethod, isSelected: Bool) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = 8
        container.layer.borderWidth = isSelected ? 2 : 1
        container.layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : UIColor.systemGray4.cgColor
        
        let nameLabel = UILabel()
        nameLabel.text = method.displayName
        nameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.accessibilityIdentifier = "shippingMethod\(method.id)NameLabel"

        let descriptionLabel = UILabel()
        descriptionLabel.text = method.description
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.accessibilityIdentifier = "shippingMethod\(method.id)DescriptionLabel"
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(methodTapped(_:)))
        container.addGestureRecognizer(tapGesture)
        container.tag = shippingMethods.firstIndex { $0.id == method.id } ?? 0
        container.accessibilityIdentifier = "shippingMethod\(method.id)Container"
        
        container.addSubview(nameLabel)
        container.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            descriptionLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
        
        return container
    }
    
    @objc private func methodTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view else { return }
        let selectedIndex = tappedView.tag
        let method = shippingMethods[selectedIndex]
        
        selectedMethod = method
        delegate?.didSelectShippingMethod(method)
        
        for (index, subview) in methodsStackView.arrangedSubviews.enumerated() {
            subview.layer.borderWidth = index == selectedIndex ? 2 : 1
            subview.layer.borderColor = index == selectedIndex ? UIColor.systemBlue.cgColor : UIColor.systemGray4.cgColor
        }
    }
}