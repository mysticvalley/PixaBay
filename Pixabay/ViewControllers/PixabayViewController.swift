import UIKit

// MARK: - Constants
private enum Constants {
    static let reuseIdentifier = "PixaCell"
}

class PixabayViewController: UICollectionViewController {

    var pixaItems: [PixaItem] = [
        PixaItem(authorName: "Rajan", tags:["crime", "thriller", "drama"], image: nil),
        PixaItem(authorName: "Jeena", tags:["crime", "thriller", "drama"], image: nil),
        PixaItem(authorName: "JK Rowling", tags:["crime", "thriller", "drama"], image: nil),
        PixaItem(authorName: "Sherlock", tags:["crime", "thriller", "drama"], image: nil),
        PixaItem(authorName: "Brad", tags:["crime", "thriller", "drama"], image: nil),
        PixaItem(authorName: "Havana", tags:["crime", "thriller", "drama"], image: nil),
        PixaItem(authorName: "Transpiration", tags:["crime", "thriller", "drama"], image: nil),
        PixaItem(authorName: "Oman", tags:["crime", "thriller", "drama"], image: nil),
        PixaItem(authorName: "Manatwa", tags:["crime", "thriller", "drama"], image: nil),
        PixaItem(authorName: "Lynda", tags:["crime", "thriller", "drama"], image: nil),
    ]
    let spacingOffset: CGFloat = 5
    
    @IBOutlet weak var collectionLayout: UICollectionViewFlowLayout! {
        didSet {
            collectionLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
    }
    
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
        //TODO: For label updates with response to large texts
        super.traitCollectionDidChange(previousTraitCollection)
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
    
        // Configure the cell
        cell.authorLabel.text = pixaItems[indexPath.row].authorName
        cell.tagsLabel.text = "Tags: \(pixaItems[indexPath.row].tags.joined(separator: ", "))"
        cell.imageView.layer.cornerRadius = 5.0
        
        cell.layer.borderColor = UIColor.lightGray.cgColor
        cell.maxWidth = getWidthBasedOnTraitCollection
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
