//
//  PhotosResult.swift
//  Virtual Tour
//
//  Created by Juan Arcos on 12/12/19.
//  Copyright © 2019 Arcos. All rights reserved.
//

import Foundation

struct PhotosResult: Codable {
    
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [PhotoModel]
    
}


struct PhotoModel: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
    
}
