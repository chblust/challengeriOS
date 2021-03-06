//
//  ChallengeViewController.swift
//  Challenger
//
//  Created by Chris Blust on 5/28/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit
import SwiftyJSON
class ChallengeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var commentTextField: UITextField!
    var challenge: Challenge!
    var commentsDataSource: CommentTableViewDataSource!
    var refreshControl: UIRefreshControl!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var commentsTableView: UITableView!
    var feedDelegate: FeedDelegate!
    var tableViewController: UITableViewController!
    var uploadProcessDelegate: UploadProcessDelegate!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = challenge.name!
        self.navigationItem.title = challenge.name!
        commentsDataSource = CommentTableViewDataSource(self)
        self.commentTextField.delegate = self
        uploadProcessDelegate = UploadProcessDelegate(self)
        tableViewController = UITableViewController()
        tableViewController.tableView = tableView
        tableViewController.tableView.dataSource = self
        tableViewController.tableView.delegate = self
        feedDelegate = FeedDelegate(uploadProcessDelegate: uploadProcessDelegate, viewController: self)
        tableView.reloadData()
        commentsTableView.dataSource = commentsDataSource
        commentsTableView.delegate = commentsDataSource
        refreshControl = UIRefreshControl()
        commentsTableView.refreshControl = refreshControl
        commentsTableView.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        fillCommentsTable()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    func fillCommentsTable(){
        commentsDataSource.comments = [Comment]()
        URLSession.shared.dataTask(with: Global.createServerRequest(params: [
            "type": "get",
            "challenge": challenge.name!
            ], intent: "comments")){data, response, error in
                if let data = data{
                    let json = JSON(data: data)
                    
                    for commentJson in json.arrayValue{
                        print(commentJson)
                        self.commentsDataSource.comments.insert(self.jsonToComment(commentJson), at: 0)
                    }
                    OperationQueue.main.addOperation {
                        self.commentsTableView.reloadData()
                        
                    }
                }
            }.resume()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Global.global.currentViewController = self
    }
    
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let next = segue.destination as? UserListViewController{
            next.listType = feedDelegate.listTypePass
            next.challenge = feedDelegate.challengePass
        }
        
    }
    
    @IBAction func sendButtonPressed(_ sender: UIButton) {
        if Global.textIsSafe(textField: commentTextField, here: self), let message = commentTextField.text{
            commentTextField.text = ""
            URLSession.shared.dataTask(with: Global.createServerRequest(params: [
                "type": "send",
                "username": Global.global.loggedInUser.username!,
                "challenge": challenge.name!,
                "message": message,
                "replyingTo": ""
                ], intent: "comments")){data, response, error in
                    if data != nil{
                        OperationQueue.main.addOperation {
                            self.fillCommentsTable()
                            self.commentTextField.resignFirstResponder()
                        }
                }
            }.resume()
            
        }else{
        }
    }
    
    func keyboardWillShow(_ notification: NSNotification){
        if (commentTextField.isFirstResponder){
            let info = notification.userInfo!
            let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        
            let keyboardHeight: CGFloat = keyboardSize.height
        
            let _: CGFloat = info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber as CGFloat
        
        
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
                self.commentTextField.frame.origin.y -= keyboardHeight - 45
                self.sendButton.frame.origin.y -= keyboardHeight - 45
            }, completion: nil)
        }else{
            print("not first responder")
        }

    }
    
    func keyboardWillHide(_ notification: NSNotification){
        if commentTextField.isFirstResponder{
            let info = notification.userInfo!
            let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
            let keyboardHeight: CGFloat = keyboardSize.height
            let _: CGFloat = info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber as CGFloat
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations:{
                self.commentTextField.frame.origin.y += keyboardHeight - 45
                self.sendButton.frame.origin.y += keyboardHeight - 45
            }, completion: nil)
        }
    }
    
    
    //MARK: - misc methods
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return feedDelegate.getSingleChallengeCell(challenge: challenge, tableView: tableViewController.tableView, indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func doneButtonTapped(){
        self.dismiss(animated: true, completion: nil)
    }
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    @IBAction func viewTapped(_ sender: UITapGestureRecognizer) {
        commentTextField.resignFirstResponder()
    }
    func handleRefresh(){
        fillCommentsTable()
        refreshControl.endRefreshing()
    }
}
