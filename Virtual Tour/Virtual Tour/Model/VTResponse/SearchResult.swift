//
//  SearchResult.swift
//  Virtual Tour
//
//  Created by Juan Arcos on 12/12/19.
//  Copyright © 2019 Arcos. All rights reserved.
//

import Foundation

struct SearchResult: Codable {
    let photos: PhotosResult
    let stat: String
    
    enum CodingKeys: String, CodingKey {
        case photos
        case stat
    }
}
