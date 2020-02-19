import UIKit

// MARK: - Constants
enum Constants {
    static let reuseIdentifier = "PixaCell"
    static let labelTopSpacing: CGFloat = 160.0
    static let maxCacheImageCount = 1000
    static let spacingOffset: CGFloat = 5
}

class PixabayViewController: UICollectionViewController {
    
    @IBOutlet weak var collectionLayout: UICollectionViewFlowLayout! {
        didSet {
            collectionLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
    }
    
    var viewModel: PixabayViewModel!
    
    var activityIndicator: UIActivityIndicatorView? = nil
    var infoLabel: UILabel? = nil
    
    private var getWidthBasedOnTraitCollection: CGFloat {
        let isTraitCompactRegular = traitCollection.horizontalSizeClass == .compact &&
            traitCollection.verticalSizeClass == .regular
        return isTraitCompactRegular ? widthForCompactRegular() : widthForRegularRegular()
    }
    
    private func widthForCompactRegular() -> CGFloat {
        return self.collectionView.bounds.width - 2 * Constants.spacingOffset
    }
    
    private func widthForRegularRegular() -> CGFloat {
        return self.collectionView.bounds.width / 3 - (2 * Constants.spacingOffset)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup ViewModel
        viewModel = PixabayViewModel(httpClient: HttpClient(with: URLSession.shared))
        
        setupNavigationBarWithSearchController()
    }
    
    // MARK: - View Configurations
    func displayInformation(with text: String, showLoading: Bool) {
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
            
            indicator.frame.origin = CGPoint(x: collectionView.bounds.width / 2 - infoLabel!.frame.width / 2 - indicator.frame.width - Constants.spacingOffset, y: Constants.labelTopSpacing)
            
            activityIndicator = indicator
            view.addSubview(activityIndicator!)
        }
    }
    
    func hideInformation() {
        activityIndicator?.stopAnimating()
        infoLabel?.isHidden = true
    }
    
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
    
    func configurePixaCollectionCell(_ cell: PixaCollectionCell, indexPath: IndexPath) {
        // Configure the cell
        let item = viewModel.pixaItems[indexPath.row]
        cell.authorLabel.text = item.authorName
        
        // Update cell trait to change dynamic font to italic
        cell.tagsLabel.text = item.tags
        cell.tagsLabel.font = UIFont.preferredFont(forTextStyle: .body).italic()
        
        cell.imageView.layer.cornerRadius = 5.0
        if let cacheImage = viewModel.imageCache[item.imageURL] as? [String: Any] {
            cell.imageView.image = cacheImage["image"] as? UIImage
        }
        else {
            viewModel.downloadImage(with: item.imageURL) { (error, image) in
                if let error = error {
                    print("Error downloading image: \(error.localizedDescription)")
                    return
                }
                
                guard let image = image else { return }
                DispatchQueue.main.async {
                    cell.imageView.image = image
                }
                
                // OptimizeCache before adding new to check limit of maxCacheImageCount
                self.viewModel.optimizeCache()
                
                // Save image to cache
                let cacheInfo = [
                    "image" : image,
                    "date" : Date()
                    ] as [String : Any]
                
                self.viewModel.saveImageToCache(with: item.imageURL, cacheInfo: cacheInfo)
            }
        }
        
        cell.layer.borderColor = UIColor.lightGray.cgColor
        cell.maxWidth = getWidthBasedOnTraitCollection
    }
}

// MARK: UISearchBarDelegate
extension  PixabayViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // clear items here
        viewModel.clearPixaItems()
        collectionView.reloadData()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        navigationItem.searchController?.isActive = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else { print(" No results"); return }
        
        searchBar.resignFirstResponder()
        displayInformation(with: "Searching ...", showLoading: true)
        
        viewModel.searchImages(with: searchText) { result in
            switch result {
            case .success(let data):
                do {
                    let service = try JSONDecoder().decode(PixaBayService.self, from: data)
                    if service.hits.count > 0 {
                        let _ = service.hits.map { self.viewModel.savePixaItem(item: $0) }
                        self.reloadCollection(showInformation: false)
                    }
                    else {
                        self.reloadCollection(showInformation: true, text: "No Results")
                    }
                }
                catch let error {
                    print("Error decoding issue: \(error.localizedDescription)")
                    self.hideInformation()
                }
            case .failure(let error):
                print(error)
                self.hideInformation()
            }
        }
    }
    
    func reloadCollection(showInformation: Bool, text: String? = nil, showLoading: Bool = false) {
        DispatchQueue.main.async {
            if showInformation {
                self.displayInformation(with: text!, showLoading: showLoading)
            } else {
                self.hideInformation()
            }
            self.collectionView.reloadData()
        }
    }
}

// MARK: UICollectionViewDataSource

extension PixabayViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.pixaItems.count
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
