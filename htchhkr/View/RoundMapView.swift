//
//  RoundMapView.swift
//  htchhkr
//
//  Created by Aris Doxakis on 10/1/18.
//  Copyright © 2018 DASoftware. All rights reserved.
//

import UIKit
import MapKit

class RoundMapView: MKMapView {

    override func awakeFromNib() {
        setupView()
    }
    
    func setupView() {
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 10.0
    }

}
