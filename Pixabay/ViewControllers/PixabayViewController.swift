import UIKit

private let reuseIdentifier = "PixaCell"

class PixabayViewController: UICollectionViewController {

    var collectionData: [String] = ["rajan long", "cat long", "dog long", "duck long"]
    let spacingOffset: CGFloat = 5.0
    var cellSize: CGFloat = 0.0
    
    @IBOutlet weak var collectionLayout: UICollectionViewFlowLayout! {
        didSet {
            collectionLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
    }
    
    private func widthForCompactRegular() -> CGFloat {
        return UIScreen.main.bounds.size.width - (2 * spacingOffset)
    }
    
    private func widthForRegularRegular() -> CGFloat {
        return (UIScreen.main.bounds.size.width - (4 * spacingOffset)) / 3
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cellSize = widthForCompactRegular()
        
        setUpSelfSizingCell()
        setupNavigationBarWithSearchController()
        configureViewBasedOnTraitCollection()
    }
    
    private func setUpSelfSizingCell() {
                
//        let flowLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
//        flowLayout.estimatedItemSize
        
    }
    
    // setup SearchController
    func setupNavigationBarWithSearchController() {
        title = "Pixabay"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "©Essenstial Energy", style: .plain, target: nil, action: nil)
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "Search"
        searchController.hidesNavigationBarDuringPresentation = false
                
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureViewBasedOnTraitCollection()
    }
    
    private func configureViewBasedOnTraitCollection() {
        let isTraitCompactRegular = traitCollection.horizontalSizeClass == .compact &&
        traitCollection.verticalSizeClass == .regular
        
        cellSize = isTraitCompactRegular ? widthForCompactRegular() : widthForRegularRegular()
        
        print(widthForRegularRegular())
        print(cellSize)
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
    }
}

// MARK: UICollectionViewDataSource

extension PixabayViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PixaCollectionCell
    
        // Configure the cell
        cell.authorLabel.text = collectionData[indexPath.row]
    
        return cell
    }
}
    
// MARK: UICollectionViewDelegateFlowLayout
extension PixabayViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        // Height should be self sizing height
        return CGSize(width: cellSize, height: cellSize)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.init(top: 5, left: 5, bottom: 5, right: 5)
    }
}
