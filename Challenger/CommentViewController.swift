//
//  CommentViewController.swift
//  Challenger
//
//  Created by Chris Blust on 7/29/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit
import SwiftyJSON
class CommentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var replyTextField: UITextField!

    @IBOutlet weak var replyTableView: UITableView!
    let cellId = "cc"
    var comment: Comment!
    var commentDataSource: CommentTableViewDataSource!
    var refreshControl: UIRefreshControl!
    @IBOutlet weak var commentTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
        self.navigationController?.setToolbarHidden(false, animated: true)
        var items = [UIBarButtonItem]()
        items.append(UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped)))
        self.setToolbarItems(items, animated: true)

        commentTableView.dataSource = self
        commentTableView.delegate = self
        commentTableView.reloadData()

        commentDataSource = CommentTableViewDataSource(self)
        replyTableView.dataSource = commentDataSource
        replyTableView.delegate = commentDataSource
        refreshControl = UIRefreshControl()
        replyTableView.refreshControl = refreshControl
        replyTableView.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        fillReplyTable()
    }
    
    func fillReplyTable(){
        self.commentDataSource.comments = [Comment]()
        URLSession.shared.dataTask(with: Global.createServerRequest(params: [
            "type": "replys",
            "uuid": comment.uuid
            ], intent: "comments")){data, response, error in
                if let data = data{
                    let json = JSON(data: data)
                    
                    for commentJson in json.arrayValue{
                        self.commentDataSource.comments.insert(self.jsonToComment(commentJson), at: 0)
                    }
                    OperationQueue.main.addOperation {
                        self.replyTableView.reloadData()
                    }
                }
        
        }.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = commentTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! CommentTableViewCell
        cell.commentTextView.backgroundColor = UIColor.clear
        cell.setupDesign()
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
            cell.reportAction = {[weak self] (cell) in self?.deleteComment(comment: self!.comment)}
        }else{
            cell.reportButton.setTitle("report", for: .normal)
            cell.reportAction = {[weak self] (cell) in self?.reportComment(comment: self!.comment)}
        }

        cell.likeCountButton.setTitle(String(comment.likers.count), for: .normal)
        cell.replyCountButton.isHidden = true
        cell.replyButton.isHidden = true
        
        //cell button actions
        cell.userAction = self.usernameLabelTapped
        cell.likeAction = {[weak self] (cell) in self?.likeButtonTapped(cell: cell, comment: self!.comment)}
        commentTableView.isScrollEnabled = true
        commentTableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        commentTableView.isScrollEnabled = false
        return cell

    }
    
    func usernameLabelTapped(_ cell: CommentTableViewCell){
        self.presentOtherUser(username: cell.usernameLabel.text!)
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
    
    func deleteComment(comment: Comment){
        let alert = UIAlertController(title: "Delete Comment?", message: "Are you sure you want to remove this comment?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "delete", style: .destructive, handler: {(UIAlertAction) in
            URLSession.shared.dataTask(with: Global.createServerRequest(params: [
                "type": "remove",
                "uuid": comment.uuid
                ], intent: "comments")){data, response, error in
                    if data != nil{
                        self.dismiss(animated: true, completion: nil)
                    }
                }.resume()
            
        }))
        alert.addAction(UIAlertAction(title: "cancel", style: .default, handler: {(UIAlertAction) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func reportComment(comment: Comment){
        let params = [
                "type":"comment",
                "username":Global.global.loggedInUser.username!,
                "reason":"",
                "uuid":comment.uuid!
            ]
            URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "report")).resume()
            Global.global.showAlert(title: "Comment Reported", message: "justice has been served!", here: self)
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        if Global.textIsSafe(textField: replyTextField, here: self), let message = replyTextField.text{
            replyTextField.text = ""
            URLSession.shared.dataTask(with: Global.createServerRequest(params: [
                "type": "send",
                "username": Global.global.loggedInUser.username!,
                "challenge": comment.challengeName,
                "message": message,
                "replyingTo": comment.uuid
                ], intent: "comments")){data, response, error in
                    if data != nil{
                        OperationQueue.main.addOperation {
                            self.fillReplyTable()
                            self.replyTextField.resignFirstResponder()
                        }
                    }
                }.resume()
            
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func keyboardWillShow(_ notification: NSNotification){
        let info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        
        let keyboardHeight: CGFloat = keyboardSize.height
        
        let _: CGFloat = info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber as CGFloat
        
        
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
            self.replyTextField.frame.origin.y -= keyboardHeight
            self.sendButton.frame.origin.y -= keyboardHeight
        }, completion: nil)
        
    }
    
    func keyboardWillHide(_ notification: NSNotification){
        if replyTextField.isFirstResponder{
            let info = notification.userInfo!
            let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
            let keyboardHeight: CGFloat = keyboardSize.height
            let _: CGFloat = info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber as CGFloat
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations:{
                self.replyTextField.frame.origin.y += keyboardHeight
                self.sendButton.frame.origin.y += keyboardHeight
            }, completion: nil)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @IBAction func viewTapped(_ sender: UITapGestureRecognizer) {
        replyTextField.resignFirstResponder()
    }
    func doneButtonTapped(){
        self.dismiss(animated: true, completion: nil)
    }
    func handleRefresh(){
        fillReplyTable()
        refreshControl.endRefreshing()
    }

}
