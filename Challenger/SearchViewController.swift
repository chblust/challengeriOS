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
    //references to the views
    @IBOutlet weak var queryTypeControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let cellId = "rc"
    ///array that holds username and challengeName results
    var results = [String]()
    
    //sent to OtherUserViewController if user result selected
    var userPass: User!
    //sent to ChallengeViewController if challenge results selected
    var challengePass: Challenge!
    override func viewDidLoad() {
        super.viewDidLoad()
        Global.setupBannerAd(self, tab: true)
        searchBar.delegate = self
        tableView.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Global.global.currentViewController = self
    }
    
  
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText != ""{
            //determine the query type and setup the post params accordingly
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
            
            //query the server database with the text entered in the search bar
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
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId) as! UserTableViewCell
        //setup the name and default image
        let name = results[indexPath.row]
        cell.usernameButton.setTitle(name, for: .normal)
        cell.userImage.image = UIImage(named: "defaultUserImage")
        
        //set image and action to challenge image or user image depending on which segment is selected
        switch queryTypeControl.selectedSegmentIndex{
        //user case
        case 0:
            Global.global.getUserImage(username: name, view: cell.userImage)
            cell.tapAction = {[weak self] (cell) in self?.userCellTapped(username: name, cell: cell)}
            break
        //challenge case
        case 1:
            //cell.userImage.image = UIImage(named: "challengeImage")
            Global.global.setUserImage(image: UIImage(named: "challengeImage")!, imageView: cell.userImage)
            cell.tapAction = {[weak self] (cell) in self?.challengeCellTapped(name: name, cell: cell)}
            break
        default:break
        }
        return cell
    }
    
    func userCellTapped(username: String, cell: UITableViewCell){
        //if its the logged in user, go to home. if not, get selected user metadata from server and go to other user view
        if username != Global.global.loggedInUser.username!{
            self.presentOtherUser(username: username)
        }else{
            self.tabBarController?.selectedIndex = 0
        }
    }
    
    func challengeCellTapped(name: String, cell: UITableViewCell){
        //get the challenge data from the server and go to single challenge view
            URLSession.shared.dataTask(with: Global.createServerRequest(params: [
                "type": "list",
                "feedEntries[0]": name
                ], intent: "getChallenges")){data, response, error in
            if let data = data{
                OperationQueue.main.addOperation {
                    let challengeViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "challengeViewController") as! ChallengeViewController
                    challengeViewController.challenge = Global.jsonToChallenge(JSON(data: data)["challenges"][0].dictionaryValue)
                    let nav = UINavigationController.init(rootViewController: challengeViewController)
                    
                    self.present(nav, animated: true, completion: nil)
                }
            }
            }.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //if its the other user view, pass the user
        if let next = segue.destination as? OtherUserViewController{
            next.user = userPass
        //if its the single challenge view, pass the challenge
        }else if let next = segue.destination as? ChallengeViewController{
            next.challenge = challengePass
        }
    }
    
    //misc methods
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    @IBAction func viewTapped(_ sender: UITapGestureRecognizer) {
        searchBar.resignFirstResponder()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}
