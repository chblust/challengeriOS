//
//  NotificationsTableViewController.swift
//  Challenger
//
//  Created by Chris Blust on 7/22/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit
import SwiftyJSON
import AVKit
import AVFoundation
class NotificationsTableViewController: UITableViewController {
    var playerViewController: AVPlayerViewController!
    let cellId = "uc"
    var notifications = [Notification]()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 49, right: 0)
        self.refreshControl?.addTarget(self, action: #selector(NotificationsTableViewController.handleRefresh), for: .valueChanged)
        fillTable()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Global.global.currentViewController = self
    }
    
    func fillTable(){
        notifications = [Notification]()
        URLSession.shared.dataTask(with: Global.createServerRequest(params: [
            "username": Global.global.loggedInUser.username!,
            "type": "get"
            ], intent: "notifications")){data,response,error in
                if let data = data{
                    OperationQueue.main.addOperation {
                        let json = JSON(data: data)
                        Global.global.setNotificationsBadge(json.arrayValue.count)
                        for dictJson in json.arrayValue{
                            self.notifications.append(Global.jsonToNotification(dictJson))
                        }
                        self.tableView.reloadData()
                    }
                }
        }.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserTableViewCell
        let notification = notifications[indexPath.row]
        let type = Notification.NotificationType(rawValue: notification.type)
        switch type!{
        case .follow:
            cell.tapAction = {[weak self] (cell) in self?.followCellTapped(notification)}
            break
        case .acceptance:
            cell.tapAction = {[weak self] (cell) in self?.acceptanceCellTapped(notification)}
            break
        case .like:
            cell.tapAction = {[weak self] (cell) in self?.likeCellTapped(notification)}
            break
        case .video_like:
            cell.tapAction = {[weak self] (cell) in self?.likeCellTapped(notification)}
            break
        case .rechallenge:
            cell.tapAction = {[weak self] (cell) in self?.likeCellTapped(notification)}
            break
        case .comment,
             .comment_like,
             .reply:
            cell.tapAction = {[weak self] (cell) in self?.commentCellTapped(notification)}
            break
        }
        cell.usernameButton.setTitle(notification.getBody(), for: .normal)
        Global.global.getUserImage(username: notification.sender, view: cell.userImage)
        
       cell.setupDesign()
        
        return cell
    }
    
    //MARK: - Cell Actions
    func followCellTapped(_ notification: Notification){
        cellAction(notification)
        self.presentOtherUser(username: notification.sender)
    }
    
    func acceptanceCellTapped(_ notification: Notification){
        cellAction(notification)
        //the following brings up a stream of the user's uploaded video
        let path = "\(Global.ip)/uploads/\(Global.getServerSafeName(notification.challengeName))/\(notification.sender)/4-medium/4-medium.m3u8"
       
        let url = URL(string: path)
        let avasset = AVURLAsset(url: url!)
        let item = AVPlayerItem(asset: avasset)
        let player = AVPlayer(playerItem: item)
        playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        self.present(playerViewController, animated: true){() -> Void in
            self.playerViewController.player!.play()
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.playerDidFinish(_:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)

    }
    
    func likeCellTapped(_ notification: Notification){
        cellAction(notification)
        presentChallenge(challengeName: notification.challengeName)
    }
    
    func commentCellTapped(_ notification: Notification){
        cellAction(notification)
        presentComment(uuid: notification.uuid!)
    }
    
    func cellAction(_ notification: Notification){
        if let index = notifications.index(of: notification){
            notifications.remove(at: index)
            tableView.reloadData()
        }
        notification.remove()
    }
    
    func playerDidFinish(_ player: AVPlayer){
        playerViewController.dismiss(animated: true, completion: {})
    }
    
    @objc func handleRefresh(){
        fillTable()
        self.refreshControl?.endRefreshing()
    }

}
