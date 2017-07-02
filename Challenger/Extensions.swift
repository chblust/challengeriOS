//
//  Extensions.swift
//  Challenger
//
//  Created by Chris Blust on 6/21/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

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
    
    func presentOtherUser(username: String){
        URLSession.shared.dataTask(with: Global.createServerRequest(params: [
            "usernames[0]": username
            ], intent: "getUsers")){data, response, error in
                if let data = data{
                    OperationQueue.main.addOperation {
                        let json = JSON(data: data)
                        if json[0]["username"].exists(){
                            let otherUserViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "otherUserViewController") as! OtherUserViewController
                            otherUserViewController.user = Global.jsonToUser(json: json[0].dictionaryValue)
                            let nav = UINavigationController(rootViewController: otherUserViewController)
                            self.present(nav, animated: true, completion: nil)
                        }else{
                            print(json)
                            Global.showAlert(title: "User Removed!", message: "This user no longer exists.", here: self)
                        }
                    }
                }
            }.resume()

    }
    
    func presentOtherUser(user: User){
        let otherUserViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "otherUserViewController") as! OtherUserViewController
        otherUserViewController.user = user
        let nav = UINavigationController(rootViewController: otherUserViewController)
        self.present(nav, animated: true, completion: nil)

    }
}
