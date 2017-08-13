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
    //determines the list of users to be displayed
    var listType: String?
    //the user to which these users have this relationship if its a user related list
    var user: User?
    //the challenge to which these users have this relationship if its a challenge related list
    var challenge: Challenge!
    
    //the list of users
    var users = [User]()
    let cellId = "uc"
    
    //variable that is passed the other user page when a cell is tapped
    var userPass: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //setup the post request based on the type of user list to be displayed
        var getUsersParams = [String:String]()
        
        let userList: [String]?
        switch listType!{
        case "followers":
            userList = user?.followers!
//            self.title = "Followers"
            self.navigationItem.title = "Followers"
            break
        case "following":
            userList = user?.following!
//            self.title = "Following"
            self.navigationItem.title  = "Following"
            break
        case "challengeLikers":
            userList = challenge.likers!
//            self.title = "Likers"
            self.navigationItem.title  = "Likers"
            break
        case "rechallengers":
            userList = challenge.rechallengers!
//            self.title = "ReChallengers"
            self.navigationItem.title  = "Rechallengers"
            break
        default:
            fatalError("list type not set!")
            break
        }
        self.title = self.navigationItem.title
        var index = 0
        
        for user in userList!{
            getUsersParams["usernames[\(index)]"] = user
            index = index + 1
        }
        
        //get them users
        let getUsersRequest = Global.createServerRequest(params: getUsersParams, intent: "getUsers")
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        let getUsersTask = session.dataTask(with: getUsersRequest){data, response, error in
            if let data = data{
                let json = JSON(data: data)
                for index in 0..<json.count{
                    //handles the situation where the user has been deleted from the server
                    if json[index]["username"].exists(){
                        self.users.append(Global.jsonToUser(json[index].dictionaryValue))
                    }else{
                        self.users.append(User())
                    }
                }
                
                self.tableView.reloadData()
            }
        }
        getUsersTask.resume()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Global.global.currentViewController = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        tableView.removeFromSuperview()
    }
    
    //Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
        if (indexPath.row < users.count){
            user = users[indexPath.row]
            
                cell.usernameButton.setTitle(user?.username!, for: .normal)
            
            
                cell.tapAction = { [weak self] (cell) in self?.cellTapped(user: user!, sender: cell)}
            
                Global.global.getUserImage(username: user!.username!, view: cell.userImage)
        }
        return cell
    }
    
    //misc methods
    func cellTapped(user: User, sender: Any?){
        self.presentOtherUser(user: user)

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // pass the user onto the other user view
        let nextViewController = segue.destination as! OtherUserViewController
        nextViewController.user = userPass
        
    }
    func doneButtonTapped(){
        self.dismiss(animated: true, completion: nil)
    }
}
