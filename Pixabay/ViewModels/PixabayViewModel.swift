import Foundation
import UIKit

final class PixabayViewModel: NSObject {
    
    private var apiManager: APIManager!
    private (set) var imageCache: [String: Any] = [String: Any]()
    private (set) var pixaItems = [PixaItem]()
    
    init(httpClient: HttpClient) {
        super.init()
        apiManager = APIManager(with: httpClient)
    }
    
    // MARK: - PixaItems
    func savePixaItem(item: PixaItem) {
        pixaItems.append(item)
    }
    
    func clearPixaItems() {
        pixaItems.removeAll()
    }
    
    // MARK: Image Cache
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
    
    func saveImageToCache(with key: String, cacheInfo: [String: Any]) {
        self.imageCache[key] = cacheInfo
    }
    
    // MARK: - Download task
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
    
    // MARK: - API Calls
    func searchImages(with text:String, completion: @escaping APIResultCompletionHandler) {
        apiManager.searchImages(with: text, completion: completion)
    }
}
