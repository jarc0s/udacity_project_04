//
//  VTResponse.swift
//  Virtual Tour
//
//  Created by Juan Arcos on 12/12/19.
//  Copyright © 2019 Arcos. All rights reserved.
//

import Foundation

import Foundation

struct VTResponse: Codable {
    let statusCode: Int
    let statusMessage: String
    
    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case statusMessage = "status_message"
    }
}

extension VTResponse: LocalizedError {
    var errorDescription: String? {
        return statusMessage
    }
}
