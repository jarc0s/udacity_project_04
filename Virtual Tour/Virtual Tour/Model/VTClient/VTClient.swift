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
        static let basePhoto = "https://farm%@.staticflickr.com/%@/%@_%@_%@.jpg"//
        
        case searchPhoto(SearchParams)
        case getPhoto
        
        var stringValue: String {
            switch self {
            case .searchPhoto(let params): return Endpoints.baseSearch + Endpoints.apiKeyParam
            case .getPhoto: return Endpoints.basePhoto
            }
        }
        
    }
}
