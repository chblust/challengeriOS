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
        uploadProcessDelegate = UploadProcessDelegate(self, "acceptedToUpload")
        feedDelegate = FeedDelegate(viewController: self, username: "=", tableController: self, upd: uploadProcessDelegate, view: "acceptedToView", list: "acceptedToUserList")
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
        if let nextViewController = segue.destination as? UploadViewController{
            nextViewController.challenge = uploadProcessDelegate.challengePass
            nextViewController.previewImage = uploadProcessDelegate.videoPreview
            nextViewController.videoData = uploadProcessDelegate.videoData
        }else if let next = segue.destination as? AcceptanceTableViewController{
            next.challenge = uploadProcessDelegate.challengePass
        }else if let next = segue.destination as? UserListViewController{
            next.listType = feedDelegate.listTypePass
            next.challenge = feedDelegate.challengePass
        }
    }
    
}
