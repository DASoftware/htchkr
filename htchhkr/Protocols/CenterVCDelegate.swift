//
//  CenterVCDelegate.swift
//  htchhkr
//
//  Created by Aris Doxakis on 9/21/18.
//  Copyright © 2018 DASoftware. All rights reserved.
//

import Foundation
import UIKit

protocol CenterVCDelegate {
    func toggleLeftPanel()
    func addLeftPanelViewController()
    func animateLeftPanel(shouldExpand: Bool)
}
