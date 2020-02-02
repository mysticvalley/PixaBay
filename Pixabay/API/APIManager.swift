import Foundation

enum APIConstructor: String {
    case key = "15080632-bb0898e902c6899a1372d7911"
    case baseURL = "https://pixabay.com/api/"
    
    static var apiBaseURL : URL {
        guard let url = URL(string: self.baseURL.rawValue) else { preconditionFailure("Base URL couldn't be nil!")}
        return url
    }
}

enum QueryParamKeys: String {
    case key
    case perPage = "per_page"
    case query = "q"
}

final class APIManager {
    
    private let httpClient: HttpClient
    
    init(with httpClient: HttpClient) {
        self.httpClient = httpClient
    }
    
    func searchImages(with query: String, completion: @escaping APIResultCompletionHandler) {
        let urlParams = [
            QueryParamKeys.key.rawValue: APIConstructor.key.rawValue,
            QueryParamKeys.perPage.rawValue: "100",
            QueryParamKeys.query.rawValue : query
            
            ] as [String : Any]
        httpClient.get(url: APIConstructor.apiBaseURL, urlParams: urlParams, completion: completion)
    }
}


