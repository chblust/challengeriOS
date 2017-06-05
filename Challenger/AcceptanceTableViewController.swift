//
//  File.swift
//  Challenger
//
//  Created by Chris Blust on 5/25/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//



//
//  AcceptanceTableViewController.swift
//  Challenger
//
//  Created by Chris Blust on 5/23/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit
import SwiftyJSON
import AVFoundation
import AVKit
class AcceptanceTableViewController: UITableViewController, URLSessionDelegate{
    var challenge: Challenge!
    
    var users: JSON?
    let cellId = "ac"
    var userPass: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Global.setupBannerAd(self, tab: false)
        //get the users that have accepted that challenge from the server
        let params = [
            "challengeName": challenge.name!,
            "type": "get"
        ]
        URLSession(configuration: .default, delegate: self, delegateQueue: .main).dataTask(with: Global.createServerRequest(params: params, intent: "acceptance")){data, response, error in
            if let data = data{
                let json = JSON(data: data)
                self.users = json
                self.tableView.reloadData()
            }
        }.resume()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? AcceptanceTableViewCell else{
            fatalError("Cell was not an AcceptanceTableViewCell")
        }
        let user: Acceptance!
        if (indexPath.row < users!.arrayValue.count){
            user = Acceptance(users![indexPath.row])
            cell.usernameButton.setTitle(user.username, for: .normal)
            cell.likeCountLabel.text = String(user.likers!.count)
            cell.usernameButtonAction = { [weak self] (cell) in self?.cellTapped(user: user.username!, sender: cell)}
            cell.likeButtonAction = { [weak self] (cell) in self?.likeButtonTapped(user: user, cell: cell)}
            
            if(user.likers!.contains(Global.global.loggedInUser.username!)){
                cell.likeButton.setImage(UIImage(named: "liked"), for: .normal)
            }else{
                cell.likeButton.setImage(UIImage(named: "like"), for: .normal)
            }
            
           Global.global.getUserImage(username: user.username!, view: cell.userImage)
        }
        return cell
    }
    
    func cellTapped(user: String, sender: UITableViewCell){
        //the following brings up a stream of the user's uploaded video
        let path = "\(Global.ip)/uploads/\(Global.getServerSafeName(challenge.name!))/\(user)/4-medium/4-medium.m3u8"
        print(path)
        let url = URL(string: path)
        let avasset = AVURLAsset(url: url!)
        let item = AVPlayerItem(asset: avasset)
        let player = AVPlayer(playerItem: item)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        self.present(playerViewController, animated: true){() -> Void in
            playerViewController.player!.play()
        }
        
    }
    
    func likeButtonTapped(user: Acceptance, cell: UITableViewCell){
        let cell = cell as! AcceptanceTableViewCell
        if user.likers!.contains(Global.global.loggedInUser.username!){
            cell.likeButton.setImage(UIImage(named: "like"), for: .normal)
            user.likers.remove(at: user.likers.index(of: Global.global.loggedInUser.username!)!)
        }else{
            cell.likeButton.setImage(UIImage(named: "liked"), for: .normal)
            user.likers.append(Global.global.loggedInUser.username!)
        }
        
        let params = [
            "username":Global.global.loggedInUser.username!,
            "type":"video",
            "challengeName":challenge.name!,
            "uploader":user.username!
        ]
        URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "like")){data, response, error in}.resume()
        cell.likeCountLabel.text = String(user.likers!.count)
    }
    
    func completeCellWithUserImage(data: Data, imageView: UIImageView){
        imageView.image = UIImage(data: data)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if users == nil{
            return 0
        }else{
            return users!.arrayValue.count
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
}
