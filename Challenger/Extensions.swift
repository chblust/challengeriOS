//
//  Extensions.swift
//  Challenger
//
//  Created by Chris Blust on 6/21/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import Foundation
import UIKit


class ChallengeImagePickerController: UIImagePickerController{
    var challenge: Challenge?
}

extension UIViewController{
    func presentUserList(challenge: Challenge, type: String){
        let userListViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "userList") as! UserListViewController
        userListViewController.listType = type
        userListViewController.challenge = challenge
        let nav = UINavigationController.init(rootViewController: userListViewController)
        
        self.present(nav, animated: true, completion: nil)
    }
    
    func presentUserList(user: User, type: String){
        let userListViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "userList") as! UserListViewController
        userListViewController.listType = type
        userListViewController.user = user
        let nav = UINavigationController.init(rootViewController: userListViewController)
        
        self.present(nav, animated: true, completion: nil)

    }
}
