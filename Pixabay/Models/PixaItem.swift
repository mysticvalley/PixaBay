struct PixaItem : Codable {
    let authorName: String
    let tags: String
    let imageURL: String
    
    private enum CodingKeys: String, CodingKey {
        case authorName = "user"
        case tags
        case imageURL = "webformatURL"
    }
}

struct PixaBayService: Decodable {
    let hits: [PixaItem]
}
