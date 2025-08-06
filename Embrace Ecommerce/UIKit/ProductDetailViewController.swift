import UIKit
import SwiftUI

class ProductDetailViewController: UIViewController {
    
    // MARK: - Properties
    var product: Product?
    var onAddToCart: ((Product, Int, [String: String]) -> Void)?
    var onClose: (() -> Void)?
    
    var selectedQuantity = 1
    var selectedVariants: [String: String] = [:]
    
    // MARK: - UI Components
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = true
        scroll.bounces = true
        return scroll
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var imageCarousel: ProductImageCarouselView = {
        let carousel = ProductImageCarouselView()
        carousel.translatesAutoresizingMaskIntoConstraints = false
        return carousel
    }()
    
    private lazy var productInfoStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        return stack
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var brandLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var priceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 28)
        label.textColor = .systemBlue
        return label
    }()
    
    private lazy var stockStatusView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 12
        return view
    }()
    
    private lazy var stockLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var ratingView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var variantsContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var quantitySelector: QuantitySelectorView = {
        let selector = QuantitySelectorView()
        selector.translatesAutoresizingMaskIntoConstraints = false
        selector.delegate = self
        return selector
    }()
    
    private lazy var addToCartButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(addToCartTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        button.tintColor = .systemRed
        button.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureProduct()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        setupStockStatusView()
        setupRatingView()
        setupProductInfoStack()
        
        contentView.addSubview(imageCarousel)
        contentView.addSubview(productInfoStackView)
        contentView.addSubview(variantsContainerView)
        contentView.addSubview(quantitySelector)
        contentView.addSubview(addToCartButton)
        contentView.addSubview(favoriteButton)
        
        setupConstraints()
    }
    
    private func setupStockStatusView() {
        stockStatusView.addSubview(stockLabel)
        NSLayoutConstraint.activate([
            stockLabel.leadingAnchor.constraint(equalTo: stockStatusView.leadingAnchor, constant: 8),
            stockLabel.trailingAnchor.constraint(equalTo: stockStatusView.trailingAnchor, constant: -8),
            stockLabel.topAnchor.constraint(equalTo: stockStatusView.topAnchor, constant: 4),
            stockLabel.bottomAnchor.constraint(equalTo: stockStatusView.bottomAnchor, constant: -4)
        ])
    }
    
    private func setupRatingView() {
        for i in 0..<5 {
            let starImageView = UIImageView()
            starImageView.image = UIImage(systemName: i < 4 ? "star.fill" : "star")
            starImageView.tintColor = .systemYellow
            starImageView.contentMode = .scaleAspectFit
            starImageView.translatesAutoresizingMaskIntoConstraints = false
            starImageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
            starImageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
            ratingView.addArrangedSubview(starImageView)
        }
        
        let ratingLabel = UILabel()
        ratingLabel.text = "4.0 (127 reviews)"
        ratingLabel.font = UIFont.systemFont(ofSize: 14)
        ratingLabel.textColor = .secondaryLabel
        ratingView.addArrangedSubview(ratingLabel)
    }
    
    private func setupProductInfoStack() {
        productInfoStackView.addArrangedSubview(titleLabel)
        productInfoStackView.addArrangedSubview(brandLabel)
        productInfoStackView.addArrangedSubview(priceLabel)
        productInfoStackView.addArrangedSubview(stockStatusView)
        productInfoStackView.addArrangedSubview(ratingView)
        productInfoStackView.addArrangedSubview(descriptionLabel)
    }
    
    private func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never
        
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        
        let shareButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareTapped)
        )
        
        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItem = shareButton
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Image Carousel
            imageCarousel.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageCarousel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageCarousel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageCarousel.heightAnchor.constraint(equalToConstant: 300),
            
            // Product Info Stack
            productInfoStackView.topAnchor.constraint(equalTo: imageCarousel.bottomAnchor, constant: 20),
            productInfoStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            productInfoStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Variants Container
            variantsContainerView.topAnchor.constraint(equalTo: productInfoStackView.bottomAnchor, constant: 24),
            variantsContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            variantsContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Quantity Selector
            quantitySelector.topAnchor.constraint(equalTo: variantsContainerView.bottomAnchor, constant: 24),
            quantitySelector.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            quantitySelector.widthAnchor.constraint(equalToConstant: 120),
            quantitySelector.heightAnchor.constraint(equalToConstant: 44),
            
            // Favorite Button
            favoriteButton.centerYAnchor.constraint(equalTo: quantitySelector.centerYAnchor),
            favoriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            favoriteButton.widthAnchor.constraint(equalToConstant: 44),
            favoriteButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Add to Cart Button
            addToCartButton.topAnchor.constraint(equalTo: quantitySelector.bottomAnchor, constant: 24),
            addToCartButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            addToCartButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            addToCartButton.heightAnchor.constraint(equalToConstant: 52),
            addToCartButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    // MARK: - Configuration
    private func configureProduct() {
        guard let product = product else { return }
        
        titleLabel.text = product.name
        brandLabel.text = product.brand
        priceLabel.text = "$\(String(format: "%.2f", product.price))"
        descriptionLabel.text = product.description
        
        // Configure stock status
        if product.inStock {
            if let stockCount = product.stockCount, stockCount < 10 {
                stockLabel.text = "Only \(stockCount) left in stock"
                stockStatusView.backgroundColor = .systemOrange.withAlphaComponent(0.2)
                stockLabel.textColor = .systemOrange
            } else {
                stockLabel.text = "In Stock"
                stockStatusView.backgroundColor = .systemGreen.withAlphaComponent(0.2)
                stockLabel.textColor = .systemGreen
            }
        } else {
            stockLabel.text = "Out of Stock"
            stockStatusView.backgroundColor = .systemRed.withAlphaComponent(0.2)
            stockLabel.textColor = .systemRed
            addToCartButton.isEnabled = false
            addToCartButton.backgroundColor = .systemGray3
        }
        
        // Configure images
        imageCarousel.configure(with: product.imageUrls)
        
        // Configure variants
        setupVariants(product.variants)
        
        // Update add to cart button
        updateAddToCartButton()
    }
    
    private func setupVariants(_ variants: [ProductVariant]) {
        // Clear existing variants
        variantsContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        guard !variants.isEmpty else { return }
        
        let groupedVariants = Dictionary(grouping: variants, by: { $0.type })
        var currentY: CGFloat = 0
        
        for (variantType, variantOptions) in groupedVariants {
            let variantSection = createVariantSection(type: variantType, options: variantOptions)
            variantsContainerView.addSubview(variantSection)
            
            NSLayoutConstraint.activate([
                variantSection.topAnchor.constraint(equalTo: variantsContainerView.topAnchor, constant: currentY),
                variantSection.leadingAnchor.constraint(equalTo: variantsContainerView.leadingAnchor),
                variantSection.trailingAnchor.constraint(equalTo: variantsContainerView.trailingAnchor)
            ])
            
            currentY += 80
        }
        
        if currentY > 0 {
            variantsContainerView.heightAnchor.constraint(equalToConstant: currentY).isActive = true
        }
    }
    
    private func createVariantSection(type: ProductVariant.VariantType, options: [ProductVariant]) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = type.rawValue.capitalized
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let optionsStackView = UIStackView()
        optionsStackView.axis = .horizontal
        optionsStackView.spacing = 8
        optionsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        for option in options {
            let button = createVariantButton(for: option, type: type)
            optionsStackView.addArrangedSubview(button)
        }
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(optionsStackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            optionsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            optionsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            optionsStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    private func createVariantButton(for variant: ProductVariant, type: ProductVariant.VariantType) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(variant.value, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.backgroundColor = .systemBackground
        button.setTitleColor(.label, for: .normal)
        
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        
        button.addTarget(self, action: #selector(variantButtonTapped(_:)), for: .touchUpInside)
        button.tag = variant.hashValue
        
        return button
    }
    
    func updateAddToCartButton() {
        guard let product = product else { return }
        
        if product.inStock {
            let basePrice = product.price
            let variantAdjustment = selectedVariants.values.reduce(0.0) { total, _ in
                total // For now, we'll assume no price adjustments
            }
            let totalPrice = (basePrice + variantAdjustment) * Double(selectedQuantity)
            
            addToCartButton.setTitle("Add to Cart - $\(String(format: "%.2f", totalPrice))", for: .normal)
            addToCartButton.isEnabled = true
            addToCartButton.backgroundColor = .systemBlue
        } else {
            addToCartButton.setTitle("Out of Stock", for: .normal)
            addToCartButton.isEnabled = false
            addToCartButton.backgroundColor = .systemGray3
        }
    }
    
    // MARK: - Actions
    @objc private func addToCartTapped() {
        guard let product = product else { return }
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Animate button
        UIView.animate(withDuration: 0.1, animations: {
            self.addToCartButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.addToCartButton.transform = .identity
            }
        }
        
        onAddToCart?(product, selectedQuantity, selectedVariants)
        
        // Show success feedback
        showAddToCartSuccess()
    }
    
    @objc private func variantButtonTapped(_ sender: UIButton) {
        // Find the variant and update selection
        guard let product = product else { return }
        
        if let variant = product.variants.first(where: { $0.hashValue == sender.tag }) {
            selectedVariants[variant.type.rawValue] = variant.value
            
            // Update UI for selected state
            updateVariantButtonStates()
            updateAddToCartButton()
        }
    }
    
    @objc private func favoriteTapped() {
        favoriteButton.isSelected.toggle()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        UIView.animate(withDuration: 0.2) {
            self.favoriteButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.favoriteButton.transform = .identity
            }
        }
    }
    
    @objc private func closeTapped() {
        onClose?()
    }
    
    @objc private func shareTapped() {
        guard let product = product else { return }
        
        let activityViewController = UIActivityViewController(
            activityItems: [product.name, "Check out this amazing product!"],
            applicationActivities: nil
        )
        
        present(activityViewController, animated: true)
    }
    
    // MARK: - Helper Methods
    private func updateVariantButtonStates() {
        guard let product = product else { return }
        
        for case let button as UIButton in variantsContainerView.subviews.flatMap({ $0.subviews }).flatMap({ $0.subviews }) {
            if let variant = product.variants.first(where: { $0.hashValue == button.tag }) {
                let isSelected = selectedVariants[variant.type.rawValue] == variant.value
                
                button.backgroundColor = isSelected ? .systemBlue : .systemBackground
                button.setTitleColor(isSelected ? .white : .label, for: .normal)
                button.layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : UIColor.systemGray4.cgColor
            }
        }
    }
    
    private func showAddToCartSuccess() {
        let alertController = UIAlertController(
            title: "Added to Cart",
            message: "Item successfully added to your cart!",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
}
