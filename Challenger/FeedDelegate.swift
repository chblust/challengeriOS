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
class FeedDelegate{
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
    
    //variables passed to future view controllers through segues
    var listTypePass:String!
    var challengePass: Challenge!
    init(viewController: UIViewController, username: String, tableController:
        UITableViewController, upd: UploadProcessDelegate, view: String, list: String){
        self.viewController = viewController
        tableViewController = tableController
        self.username = username
        uploadProcessDelegate = upd
        viewSegueName = view
        
        listSegueName = list
        refreshControl = UIRefreshControl()
        tableViewController.refreshControl = refreshControl
        self.refreshControl.addTarget(self, action: #selector(FeedDelegate.handleRefresh), for: .valueChanged)
        fillTable()
    }
    
    init(uploadProcessDelegate: UploadProcessDelegate, viewController: UIViewController, view: String, list: String){
        //only to be used for challengeViewController
        self.uploadProcessDelegate = uploadProcessDelegate
        self.viewController = viewController
        viewSegueName = view
        listSegueName = list
    }
    
    func fillTable(){
        if !refreshing{
            refreshing = true
        //sets up the params to get the correct kindof challenges from the server
        var params = [String: String]()
        if username == ""{
            //retrieves the logged in user's feed
            params = [
                "type":"feed",
                "username":Global.global.loggedInUser.username!
            ]
        }else if username == "[]"{
            params = [
                "type": "top",
                "username": Global.global.loggedInUser.username!
            ]
        }else if username == "="{
            params = [
                "type":"accepted",
                "username":Global.global.loggedInUser.username!
            ]
        }else{
            params = [
                "type":"home",
                "username": username
            ]
        }
        //gets those challenges, puts them in the model array
        URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "getChallenges")){data, response, error in
            if let data = data{
                let json = JSON(data: data)
                //reversed to keep latest posted challenges on top of feed
                for i in (0..<json.count).reversed(){
                    self.challenges.append(Global.jsonToChallenge(json: json[i].dictionaryValue))
                }
                OperationQueue.main.addOperation {
                    self.refreshing = false
                    self.tableViewController.tableView.reloadData()
                }
                
            }
            }.resume()
        }
    }
    
    func getChallengeCell(indexPath: IndexPath)->UITableViewCell{
        let challenge = challenges[indexPath.row]
        if challenge.feedType! == "acceptance"{
                //set the cell to the correct height
                self.tableViewController.tableView.rowHeight = 62
                //get the correct kindof cell
                let cell = tableViewController.tableView.dequeueReusableCell(withIdentifier: "ac", for: indexPath) as! FollowingAcceptanceTableViewCell
            
                //set the data and tap action
                cell.messageButton.setTitle("\(challenge.poster!) has accepted the challenge: \(challenge.name!)", for: .normal)
                cell.messageButtonAction = {[weak self] (cell) in self?.messageButtonTapped(challenge: challenge, cell: cell)}
                Global.global.getUserImage(username: challenge.poster!, view: cell.userImage)
            
                return cell
        }else{
            //set the cell to the correct height
                self.tableViewController.tableView.rowHeight = 199
            //get the correct kindof cell
                let cell = tableViewController.tableView.dequeueReusableCell(withIdentifier: "fc", for: indexPath) as! FeedTableViewCell
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
                    cell.reportButtonAction = {[weak self] (cell) in self?.deleteChallenge(challenge: challenge)}
                }else{
                    cell.reportButton.setTitle("report", for: .normal)
                    cell.reportButtonAction = {[weak self] (cell) in self?.reportChallenge(challenge: challenge)}
                }
            
            //differentiate if the challenge is a rechallenge or a challenge
                if challenge.feedType! == "challenge"{
                    cell.rechallengerLabel.text = ""
                    cell.rechallengeImageView.image = nil
                    cell.backgroundColor = UIColor(colorLiteralRed: 255, green: 255, blue: 255, alpha: 1)
                    cell.challengeInstructionsLabel.backgroundColor = UIColor(colorLiteralRed: 255, green: 255, blue: 255, alpha: 1)
                }else{
                    cell.rechallengerLabel.text = challenge.poster!
                    cell.rechallengeImageView.image = UIImage(named: "rechallenged")
                    cell.backgroundColor = UIColor(colorLiteralRed: 0, green: 237, blue: 255, alpha: 1)
                    cell.challengeInstructionsLabel.backgroundColor = UIColor(colorLiteralRed: 0, green: 237, blue: 255, alpha: 1)
                }
            
            //set all the button actions
                cell.acceptButtonAction = {[weak self] (cell) in self?.acceptButtonTapped(challenge: challenge, sender: cell)}
                cell.viewButtonAction = {[weak self] (cell) in self?.viewButtonTapped(challenge: challenge, sender: cell)}
                cell.likeButtonAction = {[weak self] (cell) in self?.likeButtonTapped(challenge: challenge, cell: cell)}
                cell.viewLikersButtonAction = {[weak self] (cell) in self?.viewLikersButtonTapped(challenge: challenge, sender: cell)}
                cell.rechallengeButtonAction = {[weak self] (cell) in self?.rechallengeButtonTapped(challenge: challenge, cell: cell)}
                cell.viewRechallengersButtonAction = {[weak self] (cell) in self?.viewRechallengersButtonTapped(challenge: challenge, sender: cell)}
                Global.global.getUserImage(username: challenge.author!, view: cell.userImage)
            
                //below are manual cell constraints
                let cellwidth = cell.frame.width
                cell.rechallengeButton.frame.origin.x = cellwidth - cell.rechallengeButton.frame.width - cell.viewRechallengersButton.frame.width
                cell.viewRechallengersButton.frame.origin.x = cellwidth - cell.viewRechallengersButton.frame.width
                cell.likeButton.frame.origin.x = cellwidth - cell.likeButton.frame.width - cell.viewLikersButton.frame.width
                cell.viewLikersButton.frame.origin.x = cellwidth - cell.viewLikersButton.frame.width
                cell.acceptButton.frame.origin.x = cellwidth - cell.acceptButton.frame.width - 10 - cell.acceptCountLabel.frame.width - 10
                cell.acceptCountLabel.frame.origin.x = cellwidth - cell.acceptCountLabel.frame.width - 10
                cell.viewButton.frame.origin.x = cellwidth - cell.viewButton.frame.width - 10
                        
                return cell
        }
    }
    
    func getSingleChallengeCell(challenge: Challenge, tableView: UITableView, indexPath: IndexPath)->FeedTableViewCell{
        //get cell
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! FeedTableViewCell
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
        Global.global.getUserImage(username: challenge.author!, view: cell.userImage)
        
        //below are manual cell constraints
        let cellwidth = cell.frame.width
        cell.rechallengeButton.frame.origin.x = cellwidth - cell.rechallengeButton.frame.width - cell.viewRechallengersButton.frame.width
        cell.viewRechallengersButton.frame.origin.x = cellwidth - cell.viewRechallengersButton.frame.width
        cell.likeButton.frame.origin.x = cellwidth - cell.likeButton.frame.width - cell.viewLikersButton.frame.width
        cell.viewLikersButton.frame.origin.x = cellwidth - cell.viewLikersButton.frame.width
        cell.acceptButton.frame.origin.x = cellwidth - cell.acceptButton.frame.width - 10 - cell.acceptCountLabel.frame.width - 10
        cell.acceptCountLabel.frame.origin.x = cellwidth - cell.acceptCountLabel.frame.width - 10
        cell.viewButton.frame.origin.x = cellwidth - cell.viewButton.frame.width - 10
        return cell
    }
    
    //methods that handle feed button taps
    func acceptButtonTapped(challenge: Challenge, sender: Any?){
        uploadProcessDelegate.acceptButtonTapped(challenge: challenge, sender: sender)
    }
    
    func viewButtonTapped(challenge: Challenge, sender: Any?){
        uploadProcessDelegate.challengePass = challenge
        viewController.performSegue(withIdentifier: viewSegueName, sender: sender)
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
        let params = [
            "username":Global.global.loggedInUser.username!,
            "type":"challenge",
            "challengeName":challenge.name!
        ]
        URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "like")){data, response, error in
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
            
            let params = [
                "username":Global.global.loggedInUser.username!,
                "challengeName":challenge.name!
            ]
            URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "rechallenge")){
                data, response, error in
                }.resume()
        }
    }
    
    //show a user list of the challenge likers
    func viewLikersButtonTapped(challenge: Challenge, sender: Any?){
        listTypePass = "challengeLikers"
        challengePass = challenge
        viewController.performSegue(withIdentifier: listSegueName, sender: sender)
    }
    
    //show a user list of the challenge rechallengers
    func viewRechallengersButtonTapped(challenge: Challenge, sender: Any?){
        listTypePass = "rechallengers"
        challengePass = challenge
        viewController.performSegue(withIdentifier: listSegueName, sender: sender)
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
    func deleteChallenge(challenge: Challenge){
        let alert = UIAlertController(title: "Delete Challenge", message: "are you sure you want to permanently remove this challenge?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: {(UIAlertAction) in
            let params = [
                "challengeName":challenge.name!
            ]
            URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "removeChallenge")).resume()
            self.handleRefresh()
        }))
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: {(UIAlertAction) in alert.dismiss(animated: true, completion: {})}))
        viewController.present(alert, animated: true, completion: {})
    }
    
    //handles a challenge report
    func reportChallenge(challenge: Challenge){
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
    
    //method called on table view refresh
    @objc func handleRefresh(){
        challenges = [Challenge]()
        fillTable()
        tableViewController.tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    //misc methods
    func getNumRows()->Int{
        return challenges.count
    }
    
    func getNumSections()->Int{
        return 1
    }
    
}
