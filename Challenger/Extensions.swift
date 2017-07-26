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
        Global.global.currentViewController = userListViewController
        self.present(nav, animated: true, completion: nil)
    }
    
    func presentUserList(user: User, type: String){
        let userListViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "userList") as! UserListViewController
        userListViewController.listType = type
        userListViewController.user = user
        let nav = UINavigationController.init(rootViewController: userListViewController)
        Global.global.currentViewController = userListViewController
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
                            otherUserViewController.user = Global.jsonToUser(json[0].dictionaryValue)
                            let nav = UINavigationController(rootViewController: otherUserViewController)
                            Global.global.currentViewController = otherUserViewController
                            self.present(nav, animated: true, completion: nil)
                        }else{
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
        Global.global.currentViewController = otherUserViewController
        self.present(nav, animated: true, completion: nil)

    }
    
    func presentChallenge(challengeName: String){
        //get the challenge data from the server and go to single challenge view
        URLSession.shared.dataTask(with: Global.createServerRequest(params: [
            "type": "list",
            "feedEntries[0]": challengeName
            ], intent: "getChallenges")){data, response, error in
                if let data = data{
                    OperationQueue.main.addOperation {
                        let challengeViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "challengeViewController") as! ChallengeViewController
                        challengeViewController.challenge = Global.jsonToChallenge(JSON(data: data)["challenges"][0].dictionaryValue)
                        let nav = UINavigationController.init(rootViewController: challengeViewController)
                        Global.global.currentViewController = challengeViewController
                        self.present(nav, animated: true, completion: nil)
                    }
                }
            }.resume()

    }
}

extension UITableViewCell{
    func setupDesign(){
        self.contentView.backgroundColor = UIColor.clear
        
        let whiteRoundedView : UIView = UIView(frame: CGRect(x: 10, y: 8, width: self.superview!.frame.size.width - 20, height: self.frame.size.height - 16))
        
        whiteRoundedView.layer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 1.0, 0.8])
        whiteRoundedView.layer.masksToBounds = false
        whiteRoundedView.layer.cornerRadius = 2.0
        whiteRoundedView.layer.shadowOffset = CGSize(width: -1, height: 1)
        whiteRoundedView.layer.shadowOpacity = 0.2
        
        self.contentView.addSubview(whiteRoundedView)
        self.contentView.sendSubview(toBack: whiteRoundedView)
        

    }
}
