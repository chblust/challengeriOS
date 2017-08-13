//
//  ChallengerTabBarController.swift
//  Challenger
//
//  Created by Chris Blust on 8/7/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit

class ChallengerTabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
   }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let vc = viewController as? UINavigationController{
            vc.popToRootViewController(animated: false)
        }
    }

}
