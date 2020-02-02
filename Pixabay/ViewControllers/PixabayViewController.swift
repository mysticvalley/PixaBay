import UIKit

// MARK: - Constants
private enum Constants {
    static let reuseIdentifier = "PixaCell"
    static let labelTopSpacing: CGFloat = 150.0
    static let maxCacheImageCount = 1000
}

class PixabayViewController: UICollectionViewController {
    
    @IBOutlet weak var collectionLayout: UICollectionViewFlowLayout! {
        didSet {
            collectionLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
    }
    
    var pixaItems = [PixaItem]()
    let spacingOffset: CGFloat = 5
    var apiManager: APIManager? = nil
    
    var activityIndicator: UIActivityIndicatorView? = nil
    var infoLabel: UILabel? = nil
    
    var imageCache: [String: Any] = [String: Any]()
    
    private var getWidthBasedOnTraitCollection: CGFloat {
        let isTraitCompactRegular = traitCollection.horizontalSizeClass == .compact &&
            traitCollection.verticalSizeClass == .regular
        return isTraitCompactRegular ? widthForCompactRegular() : widthForRegularRegular()
    }
    
    private func widthForCompactRegular() -> CGFloat {
        return self.collectionView.bounds.width - 2 * spacingOffset
    }
    
    private func widthForRegularRegular() -> CGFloat {
        return self.collectionView.bounds.width / 3 - (2 * spacingOffset)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBarWithSearchController()
        apiManager = APIManager(with: HttpClient(with: URLSession.shared))
    }
    
    func displayIndicator(with text: String, showLoading: Bool) {
        // Show no results label
        if let infoLabel = infoLabel {
            infoLabel.isHidden = false
            infoLabel.text = text
            infoLabel.sizeToFit()
        }
        else {
            let label = UILabel(frame: .zero)
            label.text = text
            label.sizeToFit()
            label.textColor = .gray
            
            label.frame = CGRect(x: collectionView.bounds.width / 2 - label.frame.width / 2, y: Constants.labelTopSpacing, width: label.frame.width, height: label.frame.height)
            
            infoLabel = label
            view.addSubview(infoLabel!)
        }
        
        if let activityIndicator = activityIndicator {
            if showLoading { activityIndicator.startAnimating() }
            else { activityIndicator.stopAnimating() }
        }
            
        else {
            let indicator = UIActivityIndicatorView(style: .gray)
            indicator.hidesWhenStopped = true
            
            if showLoading { indicator.startAnimating() }
            else { indicator.stopAnimating() }
            
            indicator.frame.origin = CGPoint(x: collectionView.bounds.width / 2 - infoLabel!.frame.width / 2 - indicator.frame.width - spacingOffset, y: Constants.labelTopSpacing)
            
            activityIndicator = indicator
            view.addSubview(activityIndicator!)
        }
    }
    
    func hideIndicator() {
        activityIndicator?.stopAnimating()
        infoLabel?.isHidden = true
    }
    
    // setup SearchController
    func setupNavigationBarWithSearchController() {
        title = "Pixabay"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "©Essenstial Energy", style: .plain, target: nil, action: nil)
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "Search"
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        //TODO: For label updates with response to large texts
        super.traitCollectionDidChange(previousTraitCollection)
    }
    
    func downloadImage(with urlString: String, completion: @escaping (Error?, UIImage?)->Void ) {
        guard let url = URL(string: urlString) else { return }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let imageData = data else {
                if let error = error {
                    completion(error, nil)
                }
                return
            }
            
            let image = UIImage(data: imageData)
            completion(nil, image)
        }
        task.resume()
    }
    
    func configurePixaCollectionCell(_ cell: PixaCollectionCell, indexPath: IndexPath) {
        // Configure the cell
        let item = pixaItems[indexPath.row]
        cell.authorLabel.text = item.authorName
        cell.tagsLabel.text = item.tags
        cell.imageView.layer.cornerRadius = 5.0
        
        if let cacheImage = imageCache[item.imageURL] as? [String: Any] {
            cell.imageView.image = cacheImage["image"] as? UIImage
        }
        else {
            downloadImage(with: item.imageURL) { (error, image) in
                if let image = image {
                    DispatchQueue.main.async {
                        cell.imageView.image = image
                    }
                    
                    // OptimizeCache before adding new to check limit of maxCacheImageCount
                    self.optimizeCache()
                    
                    // Save image to cache
                    let cacheInfo = [
                        "image" : image,
                        "date" : Date()
                        ] as [String : Any]
                    self.imageCache[item.imageURL] = cacheInfo
                }
            }
        }
        
        cell.layer.borderColor = UIColor.lightGray.cgColor
        cell.maxWidth = getWidthBasedOnTraitCollection
    }
    
    func optimizeCache() {
        if imageCache.count >= Constants.maxCacheImageCount {
            let imagesCacheArray = imageCache.sorted { (arg0, arg1) -> Bool in
                guard
                    let firstValue = arg0.value as? [String: Any],
                    let secondValue = arg1.value as? [String: Any],
                    let firstDate = firstValue["date"] as? Date,
                    let secondDate = secondValue["date"] as? Date
                    else { return false }
                
                return firstDate < secondDate
            }
            
            // Retrive oldest key to delete
            guard let oldestKey = imagesCacheArray.first?.key else { return }
            
            // Flush oldest key after reaching maximum cache count limit
            // before adding new image on cache
            imageCache.removeValue(forKey: oldestKey)
        }
    }
}

// MARK: UISearchBarDelegate
extension  PixabayViewController: UISearchBarDelegate {
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return false
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // clear items here
        pixaItems.removeAll()
        collectionView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let apiManager = apiManager else { preconditionFailure("API Manager not instantiated") }
        guard let searchText = searchBar.text else { print(" No results"); return }
        
        searchBar.resignFirstResponder()
        displayIndicator(with: "Searching ...", showLoading: true)
        
        apiManager.searchImages(with: searchText) { result in
            
            switch result {
            case .success(let response):
                guard let items = response["hits"] as? [[String: Any]] else { return }
                
                if items.count > 0 {
                    for dict in items {
                        guard
                            let user = dict["user"] as? String,
                            let tags = dict["tags"] as? String,
                            let imageURLString = dict["webformatURL"] as? String
                            else { return }
                        self.pixaItems.append(PixaItem(authorName: user  , tags: tags, imageURL: imageURLString))
                    }
                    
                    DispatchQueue.main.async {
                        self.hideIndicator()
                        self.collectionView.reloadData()
                    }
                }
                else {
                    DispatchQueue.main.async {
                        self.displayIndicator(with: "No Results", showLoading: false)
                        self.collectionView.reloadData()
                    }
                }
                
            case .failure(let error):
                print(error)
                self.hideIndicator()
            }
        }
    }
}

// MARK: UICollectionViewDataSource

extension PixabayViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pixaItems.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.reuseIdentifier, for: indexPath) as! PixaCollectionCell
        
        configurePixaCollectionCell(cell, indexPath: indexPath)
        return cell
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension PixabayViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
    }
}
