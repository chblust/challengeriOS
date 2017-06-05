//
//  SearchViewController.swift
//  Challenger
//
//  Created by Chris Blust on 5/25/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit
import SwiftyJSON
class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource {

    @IBOutlet weak var queryTypeControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let cellId = "rc"
    var results = [String]()
    var challengeResults: [Challenge]!
    
    //sent to OtherUserViewController if user result selected
    var userPass: User!
    //sent to ChallengeViewController if challenge results selected
    var challengePass: Challenge!
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
      
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText != ""{
        var params = [
            "entry":searchText
        ]
        switch queryTypeControl.selectedSegmentIndex{
            case 0:
            params["queryType"] = "users"
            break
            case 1:
            params["queryType"] = "challenges"
            break
        default:break
        }
        URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "search")){data, response, error in
            if let data = data{
                OperationQueue.main.addOperation {
                    //clear previous results
                    self.results = [String]()
                    let json = JSON(data: data)
                    for username in json.arrayValue{
                        self.results.append(username.stringValue)
                    }
                    
                    self.tableView.reloadData()
                }
            }
        }.resume()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       let cell = tableView.dequeueReusableCell(withIdentifier: cellId) as! UserTableViewCell
        let name = results[indexPath.row]
        cell.usernameButton.setTitle(name, for: .normal)
        cell.userImage.image = UIImage(named: "defaultUserImage")
        
        switch queryTypeControl.selectedSegmentIndex{
        case 0:
            
           Global.global.getUserImage(username: name, view: cell.userImage)
            cell.tapAction = {[weak self] (cell) in self?.userCellTapped(username: name, cell: cell)}
            break
        case 1:
            cell.userImage.image = UIImage(named: "challengeImage")
            cell.tapAction = {[weak self] (cell) in self?.challengeCellTapped(name: name, cell: cell)}
            break
        default:break
        }
        return cell
    }
    func completeCellWithUserImage(data: Data, imageView: UIImageView){
        print("setting image")
        imageView.image = UIImage(data: data)
    }
    
    func userCellTapped(username: String, cell: UITableViewCell){
        if username != Global.global.loggedInUser.username!{
        let params = [
            "usernames[0]": username
            ]
        URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "getUsers")){data, response, error in
            if let data = data{
                OperationQueue.main.addOperation {
                    print(JSON(data: data))
                    
                        self.userPass = Global.jsonToUser(json: JSON(data: data)[0].dictionaryValue)
                        self.performSegue(withIdentifier: "searchToOtherUser", sender: cell)
                    
                }
                
            }
        }.resume()
        }else{
            self.performSegue(withIdentifier: "searchToHome", sender: cell)
        }
    }
    
    func challengeCellTapped(name: String, cell: UITableViewCell){
        let params = [
            "type": "list",
            "feedEntries[0]": name
        ]
        URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "getChallenges")){data, response, error in
            if let data = data{
                OperationQueue.main.addOperation {
                    self.challengePass = Global.jsonToChallenge(json: JSON(data: data)[0].dictionaryValue)
                    self.performSegue(withIdentifier: "searchToChallenge", sender: cell)
                }
            }
        }.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let next = segue.destination as? OtherUserViewController{
            next.user = userPass
        }else if let next = segue.destination as? ChallengeViewController{
            next.challenge = challengePass
        }
    }
}
