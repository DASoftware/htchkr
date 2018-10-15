//
//  ContainerVC.swift
//  htchhkr
//
//  Created by Aris Doxakis on 9/21/18.
//  Copyright © 2018 DASoftware. All rights reserved.
//

import UIKit
import QuartzCore

enum SlideOutState {
    case collapsed
    case leftPanelExpanded
}

enum ShowWhichVC {
    case homeVC
}

var showVC: ShowWhichVC = .homeVC

class ContainerVC: UIViewController {

    var homeVC: HomeVC!
    var leftVC: LeftSidePanelVC!
    var centerController: UIViewController!
    var currentState: SlideOutState = .collapsed {
        didSet {
            let shouldShowShadow = (currentState != .collapsed)
            
            shouldShowShadowForCenterViewController(status: shouldShowShadow)
        }
    }
    
    var isHidden = false
    let centerPanelExpandedOffset: CGFloat = 160
    
    var tap: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initCenter(screen: showVC)
    }

    func initCenter(screen: ShowWhichVC) {
        var presentingController: UIViewController
        showVC = screen
        
        if homeVC == nil {
            homeVC = UIStoryboard.homeViewController()
            homeVC.delegate = self
        }
        
        presentingController = homeVC
        
        if let con = centerController {
            con.view.removeFromSuperview()
            con.removeFromParentViewController()
        }
        
        centerController = presentingController
        
        view.addSubview(centerController.view)
        addChildViewController(centerController)
        centerController.didMove(toParentViewController: self)
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
    override var prefersStatusBarHidden: Bool {
        return isHidden
    }
}

extension ContainerVC: CenterVCDelegate {
    func toggleLeftPanel() {
        let notAlreadyExpanded = (currentState != .leftPanelExpanded)
        
        if notAlreadyExpanded {
            addLeftPanelViewController()
        }
        
        animateLeftPanel(shouldExpand: notAlreadyExpanded)
    }
    
    func addLeftPanelViewController() {
        if leftVC == nil {
            leftVC = UIStoryboard.leftViewController()
            addChildSidePanelViewController(leftVC)
        }
    }
    
    func animateLeftPanel(shouldExpand: Bool) {
        if shouldExpand {
            isHidden = !isHidden
            animateStatusBar()
            
            setupWhiteCoverView()
            currentState = .leftPanelExpanded
            
            animateCenterPanelXPosition(targetPosition: centerController.view.frame.width - centerPanelExpandedOffset)
        } else {
            isHidden = !isHidden
            animateStatusBar()
            
            hideWhiteCoverView()
            animateCenterPanelXPosition(targetPosition: 0) { (finished) in
                if finished {
                    self.currentState = .collapsed
                    self.leftVC = nil
                }
            }
        }
    }
    
    @objc func animateLeftPanelSelector() {
        animateLeftPanel(shouldExpand: isHidden)
    }
    
    func animateCenterPanelXPosition(targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.centerController.view.frame.origin.x = targetPosition
        }, completion: completion)
    }
    
    func animateStatusBar() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    func setupWhiteCoverView() {
        let whiteCoverView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        whiteCoverView.alpha = 0
        whiteCoverView.backgroundColor = UIColor.white
        whiteCoverView.tag = 25
        
        self.centerController.view.addSubview(whiteCoverView)
        whiteCoverView.fadeTo(alphaValue: 0.75, withDuration: 0.2)
        
        tap = UITapGestureRecognizer(target: self, action: #selector(animateLeftPanelSelector))
        tap.numberOfTapsRequired = 1
        
        self.centerController.view.addGestureRecognizer(tap)
    }
    
    func hideWhiteCoverView() {
        centerController.view.removeGestureRecognizer(tap)
        for subView in self.centerController.view.subviews {
            if subView.tag == 25 {
                UIView.animate(withDuration: 0.2, animations: {
                    subView.alpha = 0.0
                }) { (finished) in
                    if finished {
                        subView.removeFromSuperview()
                    }
                }
            }
        }
    }
    
    func shouldShowShadowForCenterViewController(status: Bool) {
        if status {
            centerController.view.layer.shadowOpacity = 0.6
        } else {
            centerController.view.layer.shadowOpacity = 0
        }
    }
    
    func addChildSidePanelViewController(_ sidePanleController: LeftSidePanelVC) {
        view.insertSubview(sidePanleController.view, at: 0)
        addChildViewController(sidePanleController)
        sidePanleController.didMove(toParentViewController: self)
    }
}

private extension UIStoryboard {
    
    class func mainStoryboard() -> UIStoryboard {
        return UIStoryboard(name: MAIN_STORYBOARD, bundle: Bundle.main)
    }
    
    class func leftViewController() -> LeftSidePanelVC? {
        return mainStoryboard().instantiateViewController(withIdentifier: VC_LEFT_PANEL) as? LeftSidePanelVC
    }
    
    class func homeViewController() -> HomeVC? {
        return mainStoryboard().instantiateViewController(withIdentifier: VC_HOME) as? HomeVC
    }
    
    
}
