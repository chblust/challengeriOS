//
//  UserTableViewController.swift
//  Challenger
//
//  Created by Chris Blust on 5/16/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit
import SwiftyJSON
class UserListViewController: UITableViewController, URLSessionDelegate {
    //passed parameters
    var listType: String?
    var user: User?
    var challenge: Challenge!
    
    var users = [User]()
    let cellId = "uc"
    var userPass: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var getUsersParams = [String:String]()
        
        let userList: [String]?
        switch listType!{
        case "followers":
            userList = user?.followers!
            break
        case "following":
            userList = user?.following!
            break
        case "challengeLikers":
            userList = challenge.likers!
            break
        case "rechallengers":
            userList = challenge.rechallengers!
            break
        default:
            fatalError("list type not set!")
            break
        }
        var index = 0
        
        for user in userList!{
            getUsersParams["usernames[\(index)]"] = user
            index = index + 1
        }
        
        let getUsersRequest = Global.createServerRequest(params: getUsersParams, intent: "getUsers")
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        let getUsersTask = session.dataTask(with: getUsersRequest){data, response, error in
            if let data = data{
                let json = JSON(data: data)
                for index in 0..<json.count{
                    self.users.append(Global.jsonToUser(json: json[index].dictionaryValue))
                }

                self.tableView.reloadData()
            }
        }
        getUsersTask.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        tableView.removeFromSuperview()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch listType!{
        case "followers":
            return user!.followers!.count
        
        case "following":
            return user!.following!.count
       
            case "challengeLikers":
                return challenge!.likers!.count
           
            case "rechallengers":
                return challenge!.rechallengers!.count
        
        default:
            return 0
            
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? UserTableViewCell else{
            fatalError("Cell was not a UserTableViewCell")
        }
        let user: User?
        if (indexPath.row < users.count && users[indexPath.row].username != nil){
            user = users[indexPath.row]
            cell.usernameButton.setTitle(user?.username!, for: .normal)
            
            
            cell.tapAction = { [weak self] (cell) in self?.cellTapped(user: user!, sender: cell)}
            
            Global.global.getUserImage(username: (user?.username)!, view: cell.userImage)
        }
        return cell
    }
    func completeCellWithUserImage(data: Data, imageView: UIImageView){
        imageView.image = UIImage(data: data)
    }
    
    func cellTapped(user: User, sender: Any?){
        userPass = user
        performSegue(withIdentifier: "otherUserFromUserList", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let nextViewController = segue.destination as! OtherUserViewController
        nextViewController.user = userPass
        
    }
}
