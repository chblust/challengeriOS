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
        fillReplyTable()
    }
    
    func fillReplyTable(){
        URLSession.shared.dataTask(with: Global.createServerRequest(params: [
            "type": "replys",
            "uuid": comment.uuid
            ], intent: "comments")){data, response, error in
                if let data = data{
                    let json = JSON(data: data)
                    
                    for commentJson in json.arrayValue{
                        print(commentJson)
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
        cell.likeCountButton.setTitle(String(comment.likers.count), for: .normal)
        cell.replyCountButton.setTitle(String(comment.replys.count), for: .normal)
        
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
            "uuid": comment.uuid
            ], intent: "like")).resume()
        
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
        
        
        UIView.animate(withDuration: 0.25, delay: 0.25, options: .curveEaseInOut, animations: {
            self.replyTextField.frame.origin.y += keyboardHeight
            self.sendButton.frame.origin.y += keyboardHeight
        }, completion: nil)
        
    }
    
    func keyboardWillHide(_ notification: NSNotification){
        let info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let keyboardHeight: CGFloat = keyboardSize.height
        let _: CGFloat = info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber as CGFloat
        UIView.animate(withDuration: 0.25, delay: 0.25, options: .curveEaseInOut, animations:{
            self.replyTextField.frame.origin.y -= keyboardHeight
            self.sendButton.frame.origin.y -= keyboardHeight
        }, completion: nil)
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

}
