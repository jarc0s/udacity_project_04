//
//  VTClient.swift
//  Virtual Tour
//
//  Created by Juan Arcos on 12/9/19.
//  Copyright © 2019 Arcos. All rights reserved.
//

import Foundation

class VTClient {
    static let apiKey = "64e86546085a352e7e9aee4cf8b24096" //"YOUR_TMDB_API_KEY"
    
    enum Endpoints {
        static let baseSearch = "https://www.flickr.com/services/rest/?method=flickr.photos.search"
        static let apiKeyParam = "&api_key=\(VTClient.apiKey)"
        static let basePhoto = "https://farm%@.staticflickr.com/%@/%@_%@_%@.jpg"
        
        case searchPhoto(SearchParams)
        case getPhoto(PhotoParams)
        
        var stringValue: String {
            switch self {
            case .searchPhoto(let searchParams): return Endpoints.baseSearch + Endpoints.apiKeyParam + "&lat=\(searchParams.lat)"
                + "&lon=\(searchParams.lon)&radius=\(searchParams.radius)&format=\(searchParams.format)&nojsoncallback=\(searchParams.nojsoncallback)&per_page=\(searchParams.per_page)"
            case .getPhoto(let photoParams): return NSString(format: Endpoints.basePhoto as NSString, photoParams.farmId, photoParams.serverId, photoParams.id, photoParams.secret, photoParams.size) as String
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
        
    }
    
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                do {
                    let errorResponse = try decoder.decode(VTResponse.self, from: data) as Error
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
        task.resume()
        
        return task
    }
    
    class func getSearchPhotos(params: SearchParams, pinModel: Pin, completion: @escaping(PhotosResult?, Error?, Pin) -> Void){
        _ = taskForGETRequest(url: Endpoints.searchPhoto(params).url, responseType: SearchResult.self) { response, error in
            if let response = response {
                completion(response.photos, nil, pinModel)
            } else {
                completion(nil, error, pinModel)
            }
        }
    }
}
