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
    let cellID = "fc"
    var challenges = [Challenge]()
    var username: String!
    var uploadProcessDelegate: UploadProcessDelegate!
    var viewSegueName: String!
    var listSegueName: String!
    var refreshControl: UIRefreshControl!
    var tableViewController: UITableViewController!
    var viewController: UIViewController!
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
        }else{
            params = [
                "type":"home",
                "username": username
            ]
        }
        URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "getChallenges")){data, response, error in
            if let data = data{
                let json = JSON(data: data)
                //reversed to keep latest posted challenges on top of feed
                for i in (0..<json.count).reversed(){
                    self.challenges.append(Global.jsonToChallenge(json: json[i].dictionaryValue))
                }
                OperationQueue.main.addOperation {
                    self.tableViewController.tableView.reloadData()
                }
                
            }
            }.resume()
    }
    
    func getChallengeCell(indexPath: IndexPath)->UITableViewCell{
        let challenge = challenges[indexPath.row]
        if challenge.feedType == "challenge"{
            //self.tableViewController.tableView.estimatedRowHeight = 199
        self.tableViewController.tableView.rowHeight = 199
        let cell = tableViewController.tableView.dequeueReusableCell(withIdentifier: "fc", for: indexPath) as! FeedTableViewCell
        
        cell.challengeNameLabel.text = challenge.name
        cell.challengeInstructionsLabel.text = challenge.instructions
        cell.usernameLabel.text = challenge.author
        cell.datePostedLabel.text = challenge.datePosted
        cell.viewLikersButton.setTitle("\(challenge.likers!.count)", for: .normal)
        cell.viewRechallengersButton.setTitle(String(challenge.rechallengers!.count), for: .normal)
        
        if challenge.likers!.contains(Global.global.loggedInUser.username!){
            cell.likeButton.setImage(UIImage(named: "liked"), for: .normal)
        }else{
            cell.likeButton.setImage(UIImage(named: "like"), for: .normal)
        }
        
        if challenge.rechallengers!.contains(Global.global.loggedInUser.username!){
            cell.rechallengeButton.setImage(UIImage(named: "rechallenged"), for: .normal);
        }else{
            cell.rechallengeButton.setImage(UIImage(named: "rechallenge"), for: .normal)
        }
            
            if challenge.author! == Global.global.loggedInUser.username!{
                cell.reportButton.setTitle("remove", for: .normal)
                cell.reportButtonAction = {[weak self] (cell) in self?.deleteChallenge(challenge: challenge)}
            }else{
                cell.reportButton.setTitle("report", for: .normal)
                cell.reportButtonAction = {[weak self] (cell) in self?.reportChallenge(challenge: challenge)}
            }
            
        cell.rechallengerLabel.text = ""
        cell.rechallengeImageView.image = nil
        
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
            cell.acceptButton.frame.origin.x = cellwidth - cell.acceptButton.frame.width - 10
            cell.viewButton.frame.origin.x = cellwidth - cell.viewButton.frame.width - 10
            
        return cell
        }else if challenge.feedType == "acceptance"{
//            self.tableViewController.tableView.estimatedRowHeight = 62
            self.tableViewController.tableView.rowHeight = 62
            let cell = tableViewController.tableView.dequeueReusableCell(withIdentifier: "ac", for: indexPath) as! FollowingAcceptanceTableViewCell
            cell.messageButton.setTitle("\(challenge.poster!) has accepted the challenge: \(challenge.name!)", for: .normal)
            cell.messageButtonAction = {[weak self] (cell) in self?.messageButtonTapped(challenge: challenge, cell: cell)}
            Global.global.getUserImage(username: challenge.poster!, view: cell.userImage)
            
            return cell
        }else if challenge.feedType == "reChallenge"{
//            self.tableViewController.tableView.estimatedRowHeight = 199
            self.tableViewController.tableView.rowHeight = 199
            let cell = tableViewController.tableView.dequeueReusableCell(withIdentifier: "fc", for: indexPath) as! FeedTableViewCell
            
            cell.challengeNameLabel.text = challenge.name
            cell.challengeInstructionsLabel.text = challenge.instructions
            cell.usernameLabel.text = challenge.author
            cell.datePostedLabel.text = challenge.datePosted
            cell.viewLikersButton.setTitle("\(challenge.likers!.count)", for: .normal)
            cell.viewRechallengersButton.setTitle(String(challenge.rechallengers!.count), for: .normal)
            
            if challenge.likers!.contains(Global.global.loggedInUser.username!){
                cell.likeButton.setImage(UIImage(named: "liked"), for: .normal)
            }else{
                cell.likeButton.setImage(UIImage(named: "like"), for: .normal)
            }
            
            if challenge.rechallengers!.contains(Global.global.loggedInUser.username!){
                cell.rechallengeButton.setImage(UIImage(named: "rechallenged"), for: .normal);
            }else{
                cell.rechallengeButton.setImage(UIImage(named: "rechallenge"), for: .normal)
            }
            
            if challenge.author! == Global.global.loggedInUser.username!{
                cell.reportButton.setTitle("remove", for: .normal)
                cell.reportButtonAction = {[weak self] (cell) in self?.deleteChallenge(challenge: challenge)}
            }else{
                cell.reportButton.setTitle("report", for: .normal)
                cell.reportButtonAction = {[weak self] (cell) in self?.reportChallenge(challenge: challenge)}
            }
            
            cell.rechallengerLabel.text = challenge.poster!
            cell.rechallengeImageView.image = UIImage(named: "rechallenged")
            cell.backgroundColor = UIColor(colorLiteralRed: 0, green: 237, blue: 255, alpha: 1)
            cell.challengeInstructionsLabel.backgroundColor = UIColor(colorLiteralRed: 0, green: 237, blue: 255, alpha: 1)
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
            cell.acceptButton.frame.origin.x = cellwidth - cell.acceptButton.frame.width - 10
            cell.viewButton.frame.origin.x = cellwidth - cell.viewButton.frame.width - 10
            return cell
        }
        return UITableViewCell()
    }
    
    func getSingleChallengeCell(challenge: Challenge, tableView: UITableView, indexPath: IndexPath)->FeedTableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! FeedTableViewCell
        cell.challengeNameLabel.text = challenge.name
        cell.challengeInstructionsLabel.text = challenge.instructions
        cell.usernameLabel.text = challenge.author
        cell.datePostedLabel.text = challenge.datePosted
        cell.viewLikersButton.setTitle("\(challenge.likers!.count)", for: .normal)
        cell.viewRechallengersButton.setTitle(String(challenge.rechallengers!.count), for: .normal)
        
        if challenge.likers!.contains(Global.global.loggedInUser.username!){
            cell.likeButton.setImage(UIImage(named: "liked"), for: .normal)
        }else{
            cell.likeButton.setImage(UIImage(named: "like"), for: .normal)
        }
        
        if challenge.rechallengers!.contains(Global.global.loggedInUser.username!){
            cell.rechallengeButton.setImage(UIImage(named: "rechallenged"), for: .normal);
        }else{
            cell.rechallengeButton.setImage(UIImage(named: "rechallenge"), for: .normal)
        }
        
        cell.rechallengerLabel.text = ""
        cell.rechallengeImageView.image = nil
        
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
        cell.acceptButton.frame.origin.x = cellwidth - cell.acceptButton.frame.width - 10
        cell.viewButton.frame.origin.x = cellwidth - cell.viewButton.frame.width - 10
        return cell
    }
    
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
    
    func viewLikersButtonTapped(challenge: Challenge, sender: Any?){
        listTypePass = "challengeLikers"
        challengePass = challenge
        viewController.performSegue(withIdentifier: listSegueName, sender: sender)
    }
    
    func viewRechallengersButtonTapped(challenge: Challenge, sender: Any?){
        listTypePass = "rechallengers"
        challengePass = challenge
       viewController.performSegue(withIdentifier: listSegueName, sender: sender)
    }
    
    func messageButtonTapped(challenge: Challenge, cell: UITableViewCell){
        //the following brings up a stream of the user's uploaded video
        let path = "\(Global.ip)/uploads/\(Global.getServerSafeName(challenge.name!))/\(challenge.poster!)/4-medium/4-medium.m3u8"
        let url = URL(string: path)
        let avasset = AVURLAsset(url: url!)
        let item = AVPlayerItem(asset: avasset)
        let player = AVPlayer(playerItem: item)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        viewController.present(playerViewController, animated: true){() -> Void in
            playerViewController.player!.play()
        }

    }
    
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
    @objc func handleRefresh(){
        challenges = [Challenge]()
        fillTable()
        tableViewController.tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    func getNumRows()->Int{
        return challenges.count
    }
    
    func getNumSections()->Int{
        return 1
    }
    
}
