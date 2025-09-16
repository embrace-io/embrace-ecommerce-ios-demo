import UIKit

class ProductImageCarouselView: UIView {
    
    // MARK: - Properties
    private var imageUrls: [String] = []
    private var currentPage = 0
    
    // MARK: - UI Components
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .systemGray6
        cv.register(ImageCarouselCell.self, forCellWithReuseIdentifier: "ImageCell")
        cv.accessibilityIdentifier = "productImageCarouselCollection"
        return cv
    }()
    
    private lazy var pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.translatesAutoresizingMaskIntoConstraints = false
        pc.currentPageIndicatorTintColor = .systemBlue
        pc.pageIndicatorTintColor = .systemGray4
        pc.addTarget(self, action: #selector(pageControlChanged(_:)), for: .valueChanged)
        pc.accessibilityIdentifier = "productImagePageControl"
        return pc
    }()
    
    private lazy var placeholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "photo.artframe")
        imageView.tintColor = .systemGray3
        imageView.backgroundColor = .systemGray6
        imageView.accessibilityIdentifier = "productImagePlaceholder"
        return imageView
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .systemGray6
        layer.cornerRadius = 12
        clipsToBounds = true
        accessibilityIdentifier = "productImageCarousel"

        addSubview(placeholderImageView)
        addSubview(collectionView)
        addSubview(pageControl)
        
        NSLayoutConstraint.activate([
            // Placeholder
            placeholderImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            placeholderImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            placeholderImageView.widthAnchor.constraint(equalToConstant: 80),
            placeholderImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Collection View
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Page Control
            pageControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            pageControl.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
    
    // MARK: - Public Methods
    func configure(with imageUrls: [String]) {
        self.imageUrls = imageUrls
        
        if imageUrls.isEmpty {
            collectionView.isHidden = true
            pageControl.isHidden = true
            placeholderImageView.isHidden = false
        } else {
            collectionView.isHidden = false
            pageControl.isHidden = imageUrls.count <= 1
            placeholderImageView.isHidden = true
            
            pageControl.numberOfPages = imageUrls.count
            pageControl.currentPage = 0
            currentPage = 0
            
            collectionView.reloadData()
        }
    }
    
    // MARK: - Actions
    @objc private func pageControlChanged(_ sender: UIPageControl) {
        let indexPath = IndexPath(item: sender.currentPage, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension ProductImageCarouselView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCarouselCell
        cell.configure(with: imageUrls[indexPath.item])
        cell.accessibilityIdentifier = "productImageCell_\(indexPath.item)"
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ProductImageCarouselView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.width)
        pageControl.currentPage = page
        currentPage = page
    }
}

// MARK: - ImageCarouselCell
class ImageCarouselCell: UICollectionViewCell {
    
    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray6
        iv.accessibilityIdentifier = "productImageCarouselCellImage"
        return iv
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.accessibilityIdentifier = "productImageCarouselCellLoading"
        return indicator
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(activityIndicator)
        accessibilityIdentifier = "productImageCarouselCell"
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with imageUrl: String) {
        // For demo purposes, show placeholder
        imageView.image = UIImage(systemName: "photo.artframe")
        imageView.tintColor = .systemGray3
        
        // In a real app, you would load the image from the URL here
        // activityIndicator.startAnimating()
        // loadImage(from: imageUrl)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        activityIndicator.stopAnimating()
    }
}