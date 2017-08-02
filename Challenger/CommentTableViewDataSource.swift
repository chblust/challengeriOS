//
//  CommentsTableViewController.swift
//  Challenger
//
//  Created by Chris Blust on 7/26/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit
import SwiftyJSON

class CommentTableViewDataSource: NSObject,UITableViewDataSource, UITableViewDelegate {
    let cellId = "cc"
    var comments = [Comment]()
    var challenge: Challenge!
    var viewController: UIViewController!

    init(_ viewController: UIViewController!){
        self.viewController = viewController
    }
    

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! CommentTableViewCell
        let comment = comments[indexPath.row]
        Global.global.getUserImage(username: comment.author!, view: cell.userImage)
        cell.usernameLabel.text = comment.author
        cell.commentTextView.text = comment.message
        cell.dateLabel.text! = comment.date
        if comment.likers.contains(Global.global.loggedInUser.username!){
            cell.likeButton.setImage(UIImage(named: "liked"), for: .normal)
        }else{
            cell.likeButton.setImage(UIImage(named: "like"), for: .normal)
        }
        
        if comment.author == Global.global.loggedInUser.username!{
            cell.reportButton.setTitle("remove", for: .normal)
            cell.reportAction = {[weak self] (cell) in self?.deleteComment(comment: comment)}
        }else{
            cell.reportButton.setTitle("report", for: .normal)
            cell.reportAction = {[weak self] (cell) in self?.reportComment(comment: comment)}
        }
        cell.likeCountButton.setTitle(String(comment.likers.count), for: .normal)
        cell.replyCountButton.setTitle(String(comment.replys.count), for: .normal)
        
        //cell button actions
        cell.userAction = self.usernameLabelTapped
        cell.likeAction = {[weak self] (cell) in self?.likeButtonTapped(cell: cell, comment: comment)}
        cell.replyAction = {[weak self] (cell) in self?.replyButtonTapped(comment: comment)}
        
        return cell
    }
    
    //MARK: - cell actions
    
    func usernameLabelTapped(_ cell: CommentTableViewCell){
        viewController.presentOtherUser(username: cell.usernameLabel.text!)
    }
    
    func likeButtonTapped(cell: CommentTableViewCell, comment: Comment){
        if comment.likers.contains(Global.global.loggedInUser.username!){
            cell.likeButton.setImage(UIImage(named: "like"), for: .normal)
            comment.likers.remove(at: comment.likers.index(of: Global.global.loggedInUser.username!)!)
        }else{
            cell.likeButton.setImage(UIImage(named: "liked"), for: .normal)
            comment.likers.append(Global.global.loggedInUser.username!)
        }
        
        cell.likeCountButton.setTitle(String(comment.likers.count), for: .normal)
        
        URLSession.shared.dataTask(with: Global.createServerRequest(params: [
            "username": Global.global.loggedInUser.username!,
            "type": "comment",
            "challenge": comment.challengeName,
            "uuid": comment.uuid
            ], intent: "like")).resume()
        
    }
    
    func replyButtonTapped(comment: Comment){
        viewController.presentComment(comment: comment)
    }
    
    func deleteComment(comment: Comment){
        let alert = UIAlertController(title: "Delete Comment?", message: "Are you sure you want to remove this comment?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "delete", style: .destructive, handler: {(UIAlertAction) in
            URLSession.shared.dataTask(with: Global.createServerRequest(params: [
                "type": "remove",
                "uuid": comment.uuid
                ], intent: "comments")){data, response, error in
                    if data != nil{
                        if let challengeViewController = self.viewController as? ChallengeViewController{
                            challengeViewController.handleRefresh()
                        }else if let commentViewController = self.viewController as? CommentViewController{
                            commentViewController.handleRefresh()
                        }
                    }
                }.resume()

        }))
        alert.addAction(UIAlertAction(title: "cancel", style: .default, handler: {(UIAlertAction) in
            alert.dismiss(animated: true, completion: nil)
        }))
        viewController.present(alert, animated: true, completion: nil)
    }
    
    func reportComment(comment: Comment){
        let params = [
            "type":"comment",
            "username":Global.global.loggedInUser.username!,
            "reason":"",
            "uuid":comment.uuid!
        ]
        URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "report")).resume()
        Global.global.showAlert(title: "Comment Reported", message: "justice has been served!", here: viewController)
    }
}
