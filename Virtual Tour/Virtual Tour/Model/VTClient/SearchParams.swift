//
//  SearchParams.swift
//  Virtual Tour
//
//  Created by Juan Arcos on 12/9/19.
//  Copyright © 2019 Arcos. All rights reserved.
//

import Foundation

struct SearchParams {
    var lat: Double
    var lon: Double
    var radius: Int
    var format: String
    var nojsoncallback: String
    var per_page: Int
    var page: Int
}
