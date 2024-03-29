//
//  VTClient.swift
//  Virtual Tour
//
//  Created by Juan Arcos on 12/9/19.
//  Copyright © 2019 Arcos. All rights reserved.
//

import Foundation
import UIKit

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
                + "&lon=\(searchParams.lon)&radius=\(searchParams.radius)&format=\(searchParams.format)&nojsoncallback=\(searchParams.nojsoncallback)&per_page=\(searchParams.per_page)&page=\(searchParams.page)"
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
    
    
    class func loadLargeImage(photo: Photo, completion: @escaping (Result<Data>) -> Void) {
        
        guard let urlPhotoStr = photo.url, let urlPhoto = URL(string: urlPhotoStr) else {
            DispatchQueue.main.async {
                completion(Result.success(false))
            }
            
            return
        }
        
        let loadRequest = URLRequest(url:urlPhoto)
        
        URLSession.shared.dataTask(with: loadRequest) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    completion(Result.error(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(Result.success(false))
                }
                return
            }
            
            
            DispatchQueue.main.async {
                completion(Result.results(data))
            }
            
            /*guard let returnedImage = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(Result.success(false))
                }
                return
            }
            
            photo.imageData = data
            DispatchQueue.main.async {
                completion(Result.results(returnedImage))
            }
            try? self.dataController.viewContext.save()
            */
        }.resume()
    }
}
