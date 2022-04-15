//
//  Api.swift
//  News
//
//  Created by Арина Соколова on 06.02.2022.
//

import Foundation

final class API {
    static let shared = API()
    
    struct Constants {
        static let topHeadlinesURL = URL(string: "https://newsapi.org/v2/top-headlines?country=ru&apiKey=152597ac65754746805032b073a2ddc6")
    }
    
    public func getTopStories(completion: @escaping (Result<[Article], Error>) -> Void) {
        guard let url = Constants.topHeadlinesURL else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(Result.failure(error))
            }
            else if let data = data {
                do {
                    let result = try JSONDecoder().decode(APIResponse.self, from: data)
                    var articles = result.articles
                    if (articles.count > 20) {
                        articles = Array(articles.prefix(20))
                    }
                    completion(.success(articles))
                }
                catch {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
}

struct APIResponse: Codable {
    let articles: [Article]
}

//{
//    "articles": [
//        {
//            "source": {
//                "name": "..."
//            },
//            "title": "...",
//            "description": "...",
//            ...
//        },
//        {
//            ...
//        }
//    ]
//}

struct Article: Codable {
    let source: Source
    let title: String
    let description: String?
    let url: String?
    let urlToImage: String?
    let publishedAt: String
    var views: Int?
}

struct Source: Codable {
    let name: String
}
