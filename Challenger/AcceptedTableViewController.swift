//
//  AcceptedTableViewController.swift
//  Challenger
//
//  Created by Chris Blust on 6/14/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit

class AcceptedTableViewController: UITableViewController {
    
    //object that controls the feed
    var feedDelegate: FeedDelegate!
    
    //object that constrols the upload process for challenges
    var uploadProcessDelegate: UploadProcessDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        uploadProcessDelegate = UploadProcessDelegate(self)
//        feedDelegate = FeedDelegate(viewController: self, username: "=", tableController: self, upd: uploadProcessDelegate, view: "acceptedToView", list: "acceptedToUserList")
        feedDelegate = FeedDelegate(viewController: self, tableController: self, upd: uploadProcessDelegate, type: .accepted)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Global.global.currentViewController = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return feedDelegate.getNumSections()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedDelegate.getNumRows()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return feedDelegate.getChallengeCell(indexPath: indexPath)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if let next = segue.destination as? UserListViewController{
            next.listType = feedDelegate.listTypePass
            next.challenge = feedDelegate.challengePass
        }
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row < feedDelegate.challenges.count{
            switch feedDelegate.challenges[indexPath.row].feedType!{
            case "acceptance":
                return 62
            default:
                return 199
            }
        }
        return 62
    }
    
}
