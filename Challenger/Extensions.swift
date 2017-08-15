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
        Global.global.currentViewController = userListViewController
        self.navigationController!.pushViewController(userListViewController, animated: true)
    }
    
    func presentUserList(user: User, type: String){
        let userListViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "userList") as! UserListViewController
        userListViewController.listType = type
        userListViewController.user = user
        Global.global.currentViewController = userListViewController
        self.navigationController!.pushViewController(userListViewController, animated: true)
    }
    
    func presentOtherUser(username: String){
        URLSession.shared.dataTask(with: Global.createServerRequest(params: [
            "usernames[0]": username
            ], intent: "getUsers")){data, response, error in
                if let data = data{
                    OperationQueue.main.addOperation {
                        let json = JSON(data: data)
                        if json[0]["username"].exists(){
                            self.presentOtherUser(user: Global.jsonToUser(json[0].dictionaryValue))
                        }else{
                            Global.global.showAlert(title: "User Removed!", message: "This user no longer exists.", here: self)
                        }
                    }
                }
            }.resume()

    }
    
    func presentOtherUser(user: User){
        let otherUserViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "otherUserViewController") as! OtherUserViewController
        otherUserViewController.user = user
        Global.global.currentViewController = otherUserViewController
        self.navigationController!.pushViewController(otherUserViewController, animated: true)
    }
    
    func presentChallenge(challengeName: String){
        //get the challenge data from the server and go to single challenge view
        URLSession.shared.dataTask(with: Global.createServerRequest(params: [
            "type": "list",
            "feedEntries[0]": challengeName
            ], intent: "getChallenges")){data, response, error in
                if let data = data{
                    OperationQueue.main.addOperation {
                        let json = JSON(data: data)
                        
                        if json["challenges"][0]["name"].exists(){
                            let challengeViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "challengeViewController") as! ChallengeViewController
                            challengeViewController.challenge = Global.jsonToChallenge(json["challenges"][0].dictionaryValue)
                            Global.global.currentViewController = challengeViewController
                            self.navigationController!.pushViewController(challengeViewController, animated: true)
                        }else{
                            Global.global.showAlert(title: "Challenge Removed!", message: "This challenge no longer exists.", here: self)
                        }
                    }
                }
            }.resume()

    }
    
    func presentComment(comment: Comment){
        let commentViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "commentViewController") as! CommentViewController
        commentViewController.comment = comment
        Global.global.currentViewController = commentViewController
        self.navigationController!.pushViewController(commentViewController, animated: true)
    }
    
    func presentComment(uuid: String){
        URLSession.shared.dataTask(with: Global.createServerRequest(params: [
                "uuid": uuid,
                "type": "single"
            ], intent: "comments")){data, response, error in
                if let data = data{
                    OperationQueue.main.addOperation {
                        let comment = self.jsonToComment(JSON(data: data).arrayValue[0])
                        self.presentComment(comment: comment)
                    }
                }
        }.resume()
    }
    
    func presentAccepted(username: String){
        let acceptedTableViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "accepted") as! AcceptedTableViewController
        acceptedTableViewController.username = username
        Global.global.currentViewController = acceptedTableViewController
        self.navigationController?.pushViewController(acceptedTableViewController, animated: true)
    }
    
    func presentAcceptances(challenge: Challenge){
        let acceptanceViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "acceptanceViewController") as! AcceptanceTableViewController
        acceptanceViewController.challenge = challenge
        self.navigationController!.pushViewController(acceptanceViewController, animated: true)
    }
    
    func presentTop(){
        let topViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "top") as! TopChallengesViewController
        Global.global.currentViewController = topViewController
        self.navigationController?.pushViewController(topViewController, animated: true)
    }
    
    func jsonToComment(_ json: JSON) -> Comment{
        let jsonArray = json.dictionaryObject
        return Comment(uuid: jsonArray!["uuid"] as! String, author: jsonArray!["author"] as! String, challengeName: jsonArray!["challenge"] as! String, message: jsonArray!["message"] as! String, date: jsonArray!["date"] as! String, replyingTo: jsonArray!["replyingTo"] as! String, likers: jsonArray!["likers"] as! [String], replys: jsonArray!["replys"] as! [String])
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
