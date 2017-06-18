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
    var playerViewController: AVPlayerViewController!
    var users: JSON?
    let cellId = "ac"
    var userPass: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
            
            if user.username! == Global.global.loggedInUser.username! || challenge.author! == Global.global.loggedInUser.username!{
                cell.removeButton.setTitle("remove", for: .normal)
            }else{
                cell.removeButton.setTitle("report", for: .normal)
            }
            
            cell.removeButtonAction = {[weak self] (cell) in self?.removeButtonTapped(user: user, cell: cell)}
            
           Global.global.getUserImage(username: user.username!, view: cell.userImage)
            
            //constraints for cell
            let cellwidth = cell.frame.width
            cell.removeButton.frame.origin.x = cellwidth - cell.removeButton.frame.width - cell.likeCountLabel.frame.width - cell.likeButton.frame.width - 25
            cell.likeCountLabel.frame.origin.x = cellwidth - cell.likeCountLabel.frame.width - cell.likeButton.frame.width - 15
            cell.likeButton.frame.origin.x = cellwidth - cell.likeButton.frame.width - 5
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
    
    func playerDidFinish(_ player: AVPlayer){
        playerViewController.dismiss(animated: true, completion: {})
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
    
    func removeButtonTapped(user: Acceptance, cell: UITableViewCell){
        var params = [String: String]()

        if user.username! == Global.global.loggedInUser.username! || challenge.author! == Global.global.loggedInUser.username!{
            let alert = UIAlertController(title: "Delete Video", message: "are you sure you want to permanently remove this video?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: {(UIAlertAction) in
                params = [
                    "uploader": user.username!,
                    "challengeName": self.challenge.name!
                ]
                URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "removeVideo")).resume()
            }))
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: {(UIAlertAction) in alert.dismiss(animated: true, completion: {})}))
            present(alert, animated: true, completion: {})
        }else{
            let alert = UIAlertController(title: "Report a Video", message: "please enter a reason for this challenge to be removed below", preferredStyle: .alert)
            alert.addTextField(configurationHandler: {(textField) in
                textField.placeholder = "reason"
            })
            alert.addAction(UIAlertAction(title: "Report", style: .destructive, handler: {(UIAlertAction) in
                let params = [
                    "type":"video",
                    "username":Global.global.loggedInUser.username!,
                    "reason":alert.textFields![0].text!,
                    "challenge":self.challenge.name!,
                    "offender":user.username!
                ]
                URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "report")).resume()
                Global.showAlert(title: "Video Reported", message: "justice has been served!", here: self)
            }))
            alert.addAction(UIAlertAction(title: "cancel", style: .default, handler: { (UIAlertAction) in
                alert.dismiss(animated: true, completion: {})
            }))
            present(alert, animated: true, completion: {})

        }
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
