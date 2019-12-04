//
//  VirtualTourPointAnnotation.swift
//  Virtual Tour
//
//  Created by Juan Arcos on 12/4/19.
//  Copyright © 2019 Arcos. All rights reserved.
//

import Foundation
import MapKit

class VirtualTourPointAnnotation: MKPointAnnotation {
    
    var pinModel: Pin?
 
    init(pinModel: Pin) {
        self.pinModel = pinModel
        super.init()
    }
}
