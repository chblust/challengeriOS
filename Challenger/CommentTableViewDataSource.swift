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
            "uuid": comment.uuid
            ], intent: "like")).resume()
        
    }
    
    func replyButtonTapped(comment: Comment){
        viewController.presentComment(comment)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
