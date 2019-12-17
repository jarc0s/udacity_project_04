//
//  ResultPhoto.swift
//  Virtual Tour
//
//  Created by Juan Arcos on 12/17/19.
//  Copyright © 2019 Arcos. All rights reserved.
//

import Foundation

enum Result<ResultType> {
    case results(ResultType)
    case error(Error)
    case success(Bool)
}
