import UIKit

protocol QuantitySelectorDelegate: AnyObject {
    func quantityDidChange(to quantity: Int)
}

class QuantitySelectorView: UIView {
    
    // MARK: - Properties
    weak var delegate: QuantitySelectorDelegate?
    
    private var quantity: Int = 1 {
        didSet {
            updateUI()
            delegate?.quantityDidChange(to: quantity)
        }
    }
    
    private let minQuantity = 1
    private let maxQuantity = 10
    
    // MARK: - UI Components
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 8
        view.accessibilityIdentifier = "quantitySelectorContainer"
        return view
    }()
    
    private lazy var decreaseButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "minus"), for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(self, action: #selector(decreaseTapped), for: .touchUpInside)
        button.accessibilityIdentifier = "quantityDecreaseButton"
        return button
    }()
    
    private lazy var quantityLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.accessibilityIdentifier = "quantityLabel"
        return label
    }()
    
    private lazy var increaseButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(self, action: #selector(increaseTapped), for: .touchUpInside)
        button.accessibilityIdentifier = "quantityIncreaseButton"
        return button
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        updateUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        updateUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        accessibilityIdentifier = "quantitySelectorView"
        addSubview(containerView)
        containerView.addSubview(decreaseButton)
        containerView.addSubview(quantityLabel)
        containerView.addSubview(increaseButton)
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Decrease Button
            decreaseButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            decreaseButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            decreaseButton.widthAnchor.constraint(equalToConstant: 32),
            decreaseButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Quantity Label
            quantityLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            quantityLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            quantityLabel.leadingAnchor.constraint(greaterThanOrEqualTo: decreaseButton.trailingAnchor, constant: 8),
            quantityLabel.trailingAnchor.constraint(lessThanOrEqualTo: increaseButton.leadingAnchor, constant: -8),
            
            // Increase Button
            increaseButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            increaseButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            increaseButton.widthAnchor.constraint(equalToConstant: 32),
            increaseButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    // MARK: - Actions
    @objc private func decreaseTapped() {
        guard quantity > minQuantity else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        quantity -= 1
        
        animateButton(decreaseButton)
    }
    
    @objc private func increaseTapped() {
        guard quantity < maxQuantity else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        quantity += 1
        
        animateButton(increaseButton)
    }
    
    // MARK: - Helper Methods
    private func updateUI() {
        quantityLabel.text = "\(quantity)"
        
        decreaseButton.isEnabled = quantity > minQuantity
        increaseButton.isEnabled = quantity < maxQuantity
        
        decreaseButton.tintColor = decreaseButton.isEnabled ? .systemBlue : .systemGray3
        increaseButton.tintColor = increaseButton.isEnabled ? .systemBlue : .systemGray3
    }
    
    private func animateButton(_ button: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {
            button.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                button.transform = .identity
            }
        }
    }
    
    // MARK: - Public Methods
    func setQuantity(_ newQuantity: Int) {
        let clampedQuantity = max(minQuantity, min(maxQuantity, newQuantity))
        quantity = clampedQuantity
    }
    
    func getQuantity() -> Int {
        return quantity
    }
}

// MARK: - QuantitySelectorDelegate Extension
extension ProductDetailViewController: QuantitySelectorDelegate {
    func quantityDidChange(to quantity: Int) {
        selectedQuantity = quantity
        updateAddToCartButton()
    }
}