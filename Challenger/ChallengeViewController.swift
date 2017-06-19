//
//  ChallengeViewController.swift
//  Challenger
//
//  Created by Chris Blust on 5/28/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit
import SwiftyJSON
class ChallengeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var challenge: Challenge!
    
    @IBOutlet weak var tableView: UITableView!
    
    var feedDelegate: FeedDelegate!
    var tableViewController: UITableViewController!
    var uploadProcessDelegate: UploadProcessDelegate!
    override func viewDidLoad() {
        super.viewDidLoad()
        Global.setupBannerAd(self, tab: false)
        uploadProcessDelegate = UploadProcessDelegate(self, "challengeToUpload")
        tableViewController = UITableViewController()
        tableViewController.tableView = tableView
        tableViewController.tableView.dataSource = self
        tableViewController.tableView.delegate = self
        feedDelegate = FeedDelegate(uploadProcessDelegate: uploadProcessDelegate, viewController: self, view: "challengeToView", list: "challengeToUserList")
        tableView.reloadData()
    }
    
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nextViewController = segue.destination as? UploadViewController{
            nextViewController.challenge = uploadProcessDelegate.challengePass
            nextViewController.previewImage = uploadProcessDelegate.videoPreview
            nextViewController.videoData = uploadProcessDelegate.videoData
        }
        else if let next = segue.destination as? AcceptanceTableViewController{
            next.challenge = uploadProcessDelegate.challengePass
        }
        else if let next = segue.destination as? UserListViewController{
            next.listType = feedDelegate.listTypePass
            next.challenge = feedDelegate.challengePass
        }
        
    }
    
    //misc methods
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return feedDelegate.getSingleChallengeCell(challenge: challenge, tableView: tableViewController.tableView, indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}
