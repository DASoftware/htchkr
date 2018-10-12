//
//  RoundedShadowView.swift
//  htchhkr
//
//  Created by Aris Doxakis on 9/21/18.
//  Copyright © 2018 DASoftware. All rights reserved.
//

import UIKit

class RoundedShadowView: UIView {

    override func awakeFromNib() {
        setupView()
    }
    
    func setupView() {
        // rounding
        self.layer.cornerRadius = 5.0
        
        // Shadow
        self.layer.shadowOpacity = 0.3
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 5.0
        self.layer.shadowOffset = CGSize(width: 0, height: 5)
    }

}
