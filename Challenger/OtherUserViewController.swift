//
//  OtherUserViewController.swift
//  Challenger
//
//  Created by Chris Blust on 5/20/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

class OtherUserViewController:  UIViewController, URLSessionDelegate, UITableViewDataSource, UITableViewDelegate {
    //the user that's page is being displayed, set ahead of time by previous view controller
    var user: User!
    
    //userMetaData view references
    @IBOutlet weak var userImage: UIImageView!
//    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var followersButton: UIButton!
    @IBOutlet weak var followingButton: UIButton!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var followerCountButton: UIButton!
    @IBOutlet weak var followingCountButton: UIButton!
    
    
    
    //string passed to any future userListViewControllers
    var listTypePass: String?
    
    //references and variables for the homeFeed
    @IBOutlet weak var homeFeed: UITableView!
    let cellId = "fc"
    var challenges = [Challenge]()
    var tableViewController = UITableViewController()
    var feedDelegate: FeedDelegate!
    
    //object that handles uploading from the home feed
    var uploadProcessDelegate: UploadProcessDelegate!
    
    //methods that set up metadata views
    override func viewDidLoad() {
        super.viewDidLoad()
        Global.setupBannerAd(self, tab: true)
        followerCountButton.setTitle("\(user.followers!.count)", for: .normal)
        followingCountButton.setTitle("\(user.following!.count)", for: .normal)
        //set the image for the follow button depending on whether or not the login is following the user
        if (user.followers!.contains(Global.global.loggedInUser.username!)){
            followButton.setTitle("Following", for: .normal)
            followButton.backgroundColor = UIColor.green
        }else{
            followButton.setTitle("Follow", for: .normal)
            followButton.backgroundColor = UIColor.yellow
        }
        
        //i dont know if i still need this; too scared to delete it
        if user.username! == Global.global.loggedInUser.username!{
            followButton.removeFromSuperview()
        }
        
        uploadProcessDelegate = UploadProcessDelegate(self)
        
        homeFeed.dataSource = self
        homeFeed.delegate = self
        
        tableViewController.tableView = homeFeed
        
        //set the user info labels to the logged in user metadata
//        usernameLabel.text = user!.username
        self.title = user!.username
        bioTextView.text = user!.bio
        //retrieve the userImage from the server
        Global.global.getUserImage(username: user.username!, view: userImage)
        feedDelegate = FeedDelegate(viewController: self, username: user.username!, tableController: tableViewController, upd: uploadProcessDelegate, view: "otherUserToView", list: "userListFromOtherUser")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        feedDelegate.handleRefresh()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedDelegate.getNumRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        return feedDelegate.getChallengeCell(indexPath: indexPath)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //if its a user list, pass the type and the user
        if (sender as? UIButton == followersButton || sender as? UIButton == followingButton){
            let nextViewController = segue.destination as! UITableViewController
            let nextUserListController = nextViewController as? UserListViewController
            nextUserListController?.listType = listTypePass
            nextUserListController?.user = self.user

        //if its a generic user list, the feedDelegate has achieved sentience and all control should immediately be handed over to it
        }else if let next = segue.destination as? UserListViewController{
            next.listType = feedDelegate.listTypePass
            next.challenge = feedDelegate.challengePass
        }
        
    }
    
    //MARK: Button Methods
    
    @IBAction func followerButtonPressed(_ sender: UIButton) {
        self.presentUserList(user: user, type: "followers")
    }
    @IBAction func followingButtonPressed(_ sender: UIButton) {
        self.presentUserList(user: user, type: "following")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        userImage.removeFromSuperview()
        tableViewController.tableView.removeFromSuperview()
    }
    @IBAction func followButtonPressed(_ sender: UIButton) {
        if user.followers!.contains(Global.global.loggedInUser.username!){
//            followButton.setImage(UIImage(named: "follow"), for: .normal)
            followButton.setTitle("Follow", for: .normal)
            followButton.backgroundColor = UIColor.yellow
            user.followers!.remove(at: user.followers!.index(of: Global.global.loggedInUser.username!)!)
            followerCountButton.setTitle("\(user.followers!.count)", for: .normal)
            Global.global.loggedInUser.following!.remove(at: Global.global.loggedInUser.following!.index(of: user.username!)!)
            
        }else{
            //followButton.setImage(UIImage(named: "following"), for: .normal)
            followButton.setTitle("Following", for: .normal)
            followButton.backgroundColor = UIColor.green
            user.followers!.append(Global.global.loggedInUser.username!)
            followerCountButton.setTitle("\(user.followers!.count)", for: .normal)
            Global.global.loggedInUser.following!.append(user.username!)
        }
        self.updateFollowStatus()
    }
    
    //MARK: functions that tell server to follow or unfollow this user
    func updateFollowStatus(){
        let params = [
            "username": Global.global.loggedInUser.username!,
            "userToFollow":user.username!
        ]
        let task = URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "follow")){data, response, error in
        }
        task.resume()
    }
    
    @IBAction func reportButtonPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "Report a User", message: "please enter a reason for this user to be removed below", preferredStyle: .alert)
        alert.addTextField(configurationHandler: {(textField) in
            textField.placeholder = "reason"
        })
        alert.addAction(UIAlertAction(title: "Report", style: .destructive, handler: {(UIAlertAction) in
            let params = [
                "type":"user",
                "username":Global.global.loggedInUser.username!,
                "reason":alert.textFields![0].text!,
                "offender":self.user.username!
            ]
            URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "report")).resume()
            Global.showAlert(title: "User Reported", message: "justice has been served!", here: self)
        }))
        alert.addAction(UIAlertAction(title: "cancel", style: .default, handler: { (UIAlertAction) in
            alert.dismiss(animated: true, completion: {})
        }))
        present(alert, animated: true, completion: {})
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row < feedDelegate.challenges.count{
            switch feedDelegate.challenges[indexPath.row].feedType!{
            case "acceptance":
                return 62
            default:
                return 199
            }
        }
        return 62
    }
}
