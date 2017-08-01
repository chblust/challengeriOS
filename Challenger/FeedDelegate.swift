//
//  FeedDelegate.swift
//  Challenger
//
//  Created by Chris Blust on 5/28/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import AVKit
import AVFoundation
enum FeedType{
    case feed
    case top
    case accepted
    case home
}
class FeedDelegate{
    var feedType: FeedType!
    var refreshing = false;
    let cellID = "fc"
    //the modeled list of challenges
    var challenges = [Challenge]()
    //holds the username of the home feed, or the special symbol that means a certain kindof feed
    var username: String!
    var uploadProcessDelegate: UploadProcessDelegate!
    //references so that segues can be executed correctly
    var viewSegueName: String!
    var listSegueName: String!
    var refreshControl: UIRefreshControl!
    var tableViewController: UITableViewController!
    var viewController: UIViewController!
    var feedPosition = 1
    //tells feed whether or not to display loadMore
    var end = false
    
    //variables passed to future view controllers through segues
    var listTypePass:String!
    var challengePass: Challenge!
    init(viewController: UIViewController, username: String, tableController: UITableViewController, upd: UploadProcessDelegate){
        self.viewController = viewController
        tableViewController = tableController
        self.username = username
        feedType = .home
        self.uploadProcessDelegate = UploadProcessDelegate(viewController)
        
        refreshControl = UIRefreshControl()
        tableViewController.refreshControl = refreshControl
        self.refreshControl.addTarget(self, action: #selector(FeedDelegate.handleRefresh), for: .valueChanged)
        fillTable()
    }
    
    init(viewController: UIViewController, tableController: UITableViewController, upd: UploadProcessDelegate, type: FeedType){
        self.viewController = viewController
        self.tableViewController = tableController
        self.uploadProcessDelegate = UploadProcessDelegate(viewController)
        self.feedType = type
        refreshControl = UIRefreshControl()
        tableViewController.refreshControl = refreshControl
        self.refreshControl.addTarget(self, action: #selector(FeedDelegate.handleRefresh), for: .valueChanged)
//        fillTable()
    }
    
    init(uploadProcessDelegate: UploadProcessDelegate, viewController: UIViewController){
        //only to be used for challengeViewController
        self.uploadProcessDelegate = UploadProcessDelegate(viewController)
        self.viewController = viewController
    
    }
    
    func fillTable(){
        if !refreshing{
            refreshing = true
            //sets up the params to get the correct kindof challenges from the server
            var params = [String: String]()
            switch feedType!{
            case FeedType.feed:
                //retrieves the logged in user's feed
                params = [
                    "type":"feed",
                    "username":Global.global.loggedInUser.username!
                ]
            break
            case FeedType.top:
                params = [
                    "type": "top",
                    "username": Global.global.loggedInUser.username!
                ]
                break
            case FeedType.accepted:
                params = [
                    "type":"accepted",
                    "username":Global.global.loggedInUser.username!
                ]
            break
            case FeedType.home:
                params = [
                    "type":"home",
                    "username": username
                ]
                break
            }
            
            params["setLimit"] = "\(feedPosition)"
            self.feedPosition = self.feedPosition + 30
            //gets those challenges, puts them in the model array
            URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "getChallenges")){data, response, error in
                self.refreshing = false
                if let data = data{
                    let json = JSON(data: data)
                    OperationQueue.main.addOperation {
                            for i in 0..<json["challenges"].arrayValue.count{
                                self.challenges.append(Global.jsonToChallenge(json["challenges"][i].dictionaryValue))
                            }
                        if json["end"].stringValue == "true"{
                            self.end = true
                        }else{
                            self.end = false
                        }

                        
                        self.tableViewController.tableView.reloadData()
                        
                    }
                    
                }
                }.resume()
        }
    }
    
    func getChallengeCell(indexPath: IndexPath)->UITableViewCell{
        if indexPath.row == challenges.count{
            let cell = tableViewController.tableView.dequeueReusableCell(withIdentifier: "lm", for: indexPath) as! LoadMoreTableViewCell
            cell.buttonAction = {[weak self] (cell) in self?.loadMore()}
            
            //programmed constraints

            cell.button.frame.origin.y = (cell.frame.height/2) - 15
            cell.button.frame.origin.x = (cell.frame.width/2) - 36.5
            cell.button.isHidden = end
            
            return cell
        }else {
            let challenge = challenges[indexPath.row]
            if challenge.feedType! == "acceptance"{

                //get the correct kindof cell
                let cell = tableViewController.tableView.dequeueReusableCell(withIdentifier: "ac", for: indexPath) as! FollowingAcceptanceTableViewCell
                cell.setupDesign()
                //set the data and tap action
                cell.messageButton.setTitle("\(challenge.poster!) has accepted the challenge: \(challenge.name!)", for: .normal)
                cell.messageButtonAction = {[weak self] (cell) in self?.messageButtonTapped(challenge: challenge, cell: cell)}
                cell.userImageAction = {[weak self] (cell) in self?.userTapped(challenge.poster!)}
                
                Global.global.getUserImage(username: challenge.poster!, view: cell.userImage)
                
                return cell
            }else{
                //get the correct kindof cell
                let cell = tableViewController.tableView.dequeueReusableCell(withIdentifier: "fc", for: indexPath) as! FeedTableViewCell
                cell.setupDesign()

                //set the cell metadata correctly
                cell.challengeNameLabel.text = challenge.name
                cell.challengeInstructionsLabel.text = challenge.instructions
                cell.usernameLabel.text = challenge.author
                cell.datePostedLabel.text = challenge.datePosted
                cell.viewLikersButton.setTitle("\(challenge.likers!.count)", for: .normal)
                cell.viewRechallengersButton.setTitle(String(challenge.rechallengers!.count), for: .normal)
                cell.acceptCountLabel.text = challenge.acceptedCount!
                
                //determine which like button should show based on the login's likes
                if challenge.likers!.contains(Global.global.loggedInUser.username!){
                    cell.likeButton.setImage(UIImage(named: "liked"), for: .normal)
                }else{
                    cell.likeButton.setImage(UIImage(named: "like"), for: .normal)
                }
                
                //determine which rechallenge button should show based on the login's rechallenges
                if challenge.rechallengers!.contains(Global.global.loggedInUser.username!){
                    cell.rechallengeButton.setImage(UIImage(named: "rechallenged"), for: .normal);
                }else{
                    cell.rechallengeButton.setImage(UIImage(named: "rechallenge"), for: .normal)
                }
                
                //determine which destructive button should appear based on if the login posted the video or the challenge
                if challenge.author! == Global.global.loggedInUser.username!{
                    cell.reportButton.setTitle("remove", for: .normal)
                    cell.reportButtonAction = {[weak self] (cell) in self?.deleteChallenge(challenge: challenge, refresh: true, dismiss: false)}
                }else{
                    cell.reportButton.setTitle("report", for: .normal)
                    cell.reportButtonAction = {[weak self] (cell) in self?.reportChallenge(challenge: challenge)}
                }
                
                //differentiate if the challenge is a rechallenge or a challenge
                if challenge.feedType! == "challenge"{
                    cell.rechallengerLabel.text = ""
                    cell.rechallengeImageView.image = nil
                    cell.backgroundColor = UIColor.clear
                    cell.challengeInstructionsLabel.backgroundColor = UIColor.clear
                }else{
                    cell.rechallengerLabel.text = challenge.poster!
                    cell.rechallengeImageView.image = UIImage(named: "rechallenged")
                    cell.backgroundColor = UIColor.clear//UIColor(colorLiteralRed: 0, green: 237, blue: 255, alpha: 1)
                    cell.challengeInstructionsLabel.backgroundColor = UIColor.clear//UIColor(colorLiteralRed: 0, green: 237, blue: 255, alpha: 1)
                }
                
                //set all the button actions
                cell.acceptButtonAction = {[weak self] (cell) in self?.acceptButtonTapped(challenge: challenge, sender: cell)}
                cell.viewButtonAction = {[weak self] (cell) in self?.viewButtonTapped(challenge: challenge, sender: cell)}
                cell.likeButtonAction = {[weak self] (cell) in self?.likeButtonTapped(challenge: challenge, cell: cell)}
                cell.viewLikersButtonAction = {[weak self] (cell) in self?.viewLikersButtonTapped(challenge: challenge, sender: cell)}
                cell.rechallengeButtonAction = {[weak self] (cell) in self?.rechallengeButtonTapped(challenge: challenge, cell: cell)}
                cell.viewRechallengersButtonAction = {[weak self] (cell) in self?.viewRechallengersButtonTapped(challenge: challenge, sender: cell)}
                cell.userImageAction = {[weak self] (cell) in self?.userTapped(cell.usernameLabel.text!)}
                cell.rechallengerAction = {[weak self] (cell) in self?.userTapped(cell.rechallengerLabel.text!)}
                cell.cellAction = {[weak self] (cell) in self?.cellAction(challenge: challenge)}
                Global.global.getUserImage(username: challenge.author!, view: cell.userImage)
                
                //below are manual cell constraints
                let cellwidth = cell.frame.width
                cell.reportButton.frame.origin.x = cellwidth - 10 - cell.reportButton.frame.width
                cell.challengeInstructionsLabel.frame = CGRect(x: cell.challengeInstructionsLabel.frame.origin.x, y: cell.challengeInstructionsLabel.frame.origin.y, width: cellwidth - 20, height: cell.challengeInstructionsLabel.frame.height)
                
                return cell
            }

        }
    }
    
    func getSingleChallengeCell(challenge: Challenge, tableView: UITableView, indexPath: IndexPath)->FeedTableViewCell{
        //get cell
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! FeedTableViewCell
        cell.contentView.backgroundColor = UIColor.clear
        
        cell.setupDesign()
        cell.challengeInstructionsLabel.backgroundColor = UIColor.clear
        //set cell metadata
        cell.challengeNameLabel.text = challenge.name
        cell.challengeInstructionsLabel.text = challenge.instructions
        cell.usernameLabel.text = challenge.author
        cell.datePostedLabel.text = challenge.datePosted
        cell.viewLikersButton.setTitle("\(challenge.likers!.count)", for: .normal)
        cell.viewRechallengersButton.setTitle(String(challenge.rechallengers!.count), for: .normal)
        cell.acceptCountLabel.text = challenge.acceptedCount!
        
        //determine which like button should show based on the login's likes
        if challenge.likers!.contains(Global.global.loggedInUser.username!){
            cell.likeButton.setImage(UIImage(named: "liked"), for: .normal)
        }else{
            cell.likeButton.setImage(UIImage(named: "like"), for: .normal)
        }
        
        //determine which rechallenge button should show based on the login's rechallenges
        if challenge.rechallengers!.contains(Global.global.loggedInUser.username!){
            cell.rechallengeButton.setImage(UIImage(named: "rechallenged"), for: .normal);
        }else{
            cell.rechallengeButton.setImage(UIImage(named: "rechallenge"), for: .normal)
        }
        
        //determine which destructive button should appear based on if the login posted the video or the challenge
        if challenge.author! == Global.global.loggedInUser.username!{
            cell.reportButton.setTitle("remove", for: .normal)
            cell.reportButtonAction = {[weak self] (cell) in self?.deleteChallenge(challenge: challenge, refresh: false, dismiss: true)}
        }else{
            cell.reportButton.setTitle("report", for: .normal)
            cell.reportButtonAction = {[weak self] (cell) in self?.reportChallenge(challenge: challenge)}
        }
        
        //this stuff isn't relevant here
        cell.rechallengerLabel.text = ""
        cell.rechallengeImageView.image = nil
        
        //set the button actions
        cell.acceptButtonAction = {[weak self] (cell) in self?.acceptButtonTapped(challenge: challenge, sender: cell)}
        cell.viewButtonAction = {[weak self] (cell) in self?.viewButtonTapped(challenge: challenge, sender: cell)}
        cell.likeButtonAction = {[weak self] (cell) in self?.likeButtonTapped(challenge: challenge, cell: cell)}
        cell.viewLikersButtonAction = {[weak self] (cell) in self?.viewLikersButtonTapped(challenge: challenge, sender: cell)}
        cell.rechallengeButtonAction = {[weak self] (cell) in self?.rechallengeButtonTapped(challenge: challenge, cell: cell)}
        cell.viewRechallengersButtonAction = {[weak self] (cell) in self?.viewRechallengersButtonTapped(challenge: challenge, sender: cell)}
        cell.userImageAction = {[weak self] (cell) in self?.userTapped(cell.usernameLabel.text!)}
        cell.rechallengerAction = {[weak self] (cell) in self?.userTapped(cell.rechallengerLabel.text!)}
        Global.global.getUserImage(username: challenge.author!, view: cell.userImage)
        
        //below are manual cell constraints
        let cellwidth = cell.frame.width
        cell.reportButton.frame.origin.x = cellwidth - 10 - cell.reportButton.frame.width
        cell.challengeInstructionsLabel.frame = CGRect(x: cell.challengeInstructionsLabel.frame.origin.x, y: cell.challengeInstructionsLabel.frame.origin.y, width: cellwidth - 16, height: cell.challengeInstructionsLabel.frame.height)
        
        return cell
    }
    
    //methods that handle feed button taps
    func acceptButtonTapped(challenge: Challenge, sender: Any?){
        uploadProcessDelegate.acceptButtonTapped(challenge: challenge, sender: sender)
    }
    
    func viewButtonTapped(challenge: Challenge, sender: Any?){
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let acceptanceViewController = storyBoard.instantiateViewController(withIdentifier: "acceptanceViewController") as! AcceptanceTableViewController
        acceptanceViewController.challenge = challenge
        let nav = UINavigationController.init(rootViewController: acceptanceViewController)
        
        viewController.present(nav, animated: true, completion: nil)
    }
    
    func likeButtonTapped(challenge: Challenge, cell: UITableViewCell){
        //first update client info
        let cell = cell as! FeedTableViewCell
        if challenge.likers!.contains(Global.global.loggedInUser.username!){
            cell.likeButton.setImage(UIImage(named: "like"), for: .normal)
            challenge.likers!.remove(at: challenge.likers!.index(of: Global.global.loggedInUser.username!)!)
        }else{
            cell.likeButton.setImage(UIImage(named: "liked"), for: .normal)
            challenge.likers!.append(Global.global.loggedInUser.username!)
        }
        cell.viewLikersButton.setTitle(String(challenge.likers!.count), for: .normal)
        
        //update like count on server
        URLSession.shared.dataTask(with: Global.createServerRequest(params: [
            "username":Global.global.loggedInUser.username!,
            "type":"challenge",
            "challengeName":challenge.name!
            ], intent: "like")){data, response, error in
            }.resume()
    }
    
    func rechallengeButtonTapped(challenge: Challenge, cell: UITableViewCell){
        //if login did not post it, rechallenge if not rechallenged, unrechallenge if rechallenged
        if challenge.author! == Global.global.loggedInUser.username!{
            Global.showAlert(title: "You posted this Challenge", message: "you cannot rechallenge your own challenges", here: viewController)
        }else{
            let cell = cell as! FeedTableViewCell
            if challenge.rechallengers!.contains(Global.global.loggedInUser.username!){
                cell.rechallengeButton.setImage(UIImage(named: "rechallenge"), for: .normal)
                challenge.rechallengers!.remove(at: challenge.rechallengers!.index(of: Global.global.loggedInUser.username!)!)
            }else{
                cell.rechallengeButton.setImage(UIImage(named: "rechallenged"), for: .normal)
                challenge.rechallengers!.append(Global.global.loggedInUser.username!)
            }
            cell.viewRechallengersButton.setTitle(String(challenge.rechallengers!.count), for: .normal)
            
            URLSession.shared.dataTask(with: Global.createServerRequest(params: [
                "username":Global.global.loggedInUser.username!,
                "challengeName":challenge.name!
                ], intent: "rechallenge")){
                    data, response, error in
                }.resume()
        }
    }
    
    //show a user list of the challenge likers
    func viewLikersButtonTapped(challenge: Challenge, sender: Any?){
        viewController.presentUserList(challenge: challenge, type: "challengeLikers")
    }
    
    //show a user list of the challenge rechallengers
    func viewRechallengersButtonTapped(challenge: Challenge, sender: Any?){
        viewController.presentUserList(challenge: challenge, type: "rechallengers")
    }
    
    func cellAction(challenge: Challenge){
        viewController.presentChallenge(challengeName: challenge.name!)
    }
    var playerViewController: AVPlayerViewController!
    //shows the video associated with an acceptance feed entry
    func messageButtonTapped(challenge: Challenge, cell: UITableViewCell){
        //the following brings up a stream of the user's uploaded video
        let path = "\(Global.ip)/uploads/\(Global.getServerSafeName(challenge.name!))/\(challenge.poster!)/4-medium/4-medium.m3u8"
        let url = URL(string: path)
        let avasset = AVURLAsset(url: url!)
        let item = AVPlayerItem(asset: avasset)
        let player = AVPlayer(playerItem: item)
        playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        viewController.present(playerViewController, animated: true){() -> Void in
            self.playerViewController.player!.play()
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.playerDidFinish(_:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)
    }
    
    @objc func playerDidFinish(_ player: AVPlayer){
        playerViewController.dismiss(animated: true, completion: {})
    }
    
    //handles a challenge delete
    func deleteChallenge(challenge: Challenge, refresh: Bool, dismiss: Bool){
        let alert = UIAlertController(title: "Delete Challenge", message: "are you sure you want to permanently remove this challenge?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: {(UIAlertAction) in
            let params = [
                "challengeName":challenge.name!
            ]
            URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "removeChallenge")){data, response, error in
                if data != nil{
                    OperationQueue.main.addOperation {
                        if refresh{
                            self.handleRefresh()
                        }
                        if dismiss{
                            self.viewController.dismiss(animated: true, completion: nil)
                        }
                    }
                    
                }
                }.resume()
        }))
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: {(UIAlertAction) in alert.dismiss(animated: true, completion: {})}))
        viewController.present(alert, animated: true, completion: {})
    }
    
    //handles a challenge report
    func reportChallenge(challenge: Challenge){
        NotificationCenter.default.removeObserver(viewController, name: .UIKeyboardWillShow, object: nil)
        let alert = UIAlertController(title: "Report a Challenge", message: "please enter a reason for this challenge to be removed below", preferredStyle: .alert)
        alert.addTextField(configurationHandler: {(textField) in
            textField.placeholder = "reason"
        })
        alert.addAction(UIAlertAction(title: "Report", style: .destructive, handler: {(UIAlertAction) in
            let params = [
                "type":"challenge",
                "username":Global.global.loggedInUser.username!,
                "reason":alert.textFields![0].text!,
                "challenge":challenge.name!
            ]
            URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "report")).resume()
            Global.showAlert(title: "Challenge Reported", message: "justice has been served!", here: self.viewController)
        }))
        alert.addAction(UIAlertAction(title: "cancel", style: .default, handler: { (UIAlertAction) in
            alert.dismiss(animated: true, completion: {})
        }))
        viewController.present(alert, animated: true, completion: {})
    }
    
    func userTapped(_ username: String){
        viewController.presentOtherUser(username: username)
    }
    
    func loadMore(){
        fillTable()
    }
    
    //method called on table view refresh
    @objc func handleRefresh(){
        feedPosition = 1
        challenges = [Challenge]()
        fillTable()
        tableViewController.tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    //misc methods
    func getNumRows()->Int{
        return challenges.count + 1
    }
    
    func getNumSections()->Int{
        return 1
    }
    
    
}
