
//
//  PassengerAnnotation.swift
//  htchhkr
//
//  Created by Aris Doxakis on 9/27/18.
//  Copyright © 2018 DASoftware. All rights reserved.
//

import Foundation
import MapKit

class PassengerAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var key: String
    
    init(coordinate: CLLocationCoordinate2D, withKey key: String) {
        self.coordinate = coordinate
        self.key = key
        super.init()
    }
}
