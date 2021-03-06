//
//  FeedViewController.swift
//  Challenger
//
//  Created by Chris Blust on 5/18/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit
import SwiftyJSON
import AVFoundation
import MobileCoreServices
class FeedViewController: UITableViewController{
    
    //variable that does most of the feed stuff behind the scenes
    var feedDelegate: FeedDelegate!
    
    
    //object that controls the upload process for a feed
    var uploadProcessDelegate: UploadProcessDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 49, right: 0)
        
        uploadProcessDelegate = UploadProcessDelegate(self)
//        feedDelegate = FeedDelegate(viewController: self, username: "", tableController: self, upd: uploadProcessDelegate, view: "feedToView", list: "feedToUserList")
        feedDelegate = FeedDelegate(viewController: self, tableController: self, upd: uploadProcessDelegate, type: .feed)
        feedDelegate.handleRefresh()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.popToRootViewController(animated: true)
//        feedDelegate.handleRefresh()
        Global.global.currentViewController = self
    }
    
    //makes sure the upload viewcontorller knows which challenge to upload to
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let next = segue.destination as? UserListViewController{
            next.listType = feedDelegate.listTypePass
            next.challenge = feedDelegate.challengePass
        }
        
    }
    
    //misc methods
    @IBAction func unwindToFeed(segue: UIStoryboardSegue){}
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return feedDelegate.getNumSections()
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedDelegate.getNumRows()
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return feedDelegate.getChallengeCell(indexPath: indexPath)
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
