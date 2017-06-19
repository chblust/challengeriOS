//
//  HomeViewController.swift
//  Challenger
//
//  Created by Chris Blust on 5/16/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import Foundation
import SwiftyJSON
import UIKit
import MobileCoreServices
import AVFoundation
import Photos
class HomeViewController: UIViewController, URLSessionDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, URLSessionTaskDelegate{
    //references to views
    @IBOutlet weak var imageUploadProgressView: UIProgressView!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var followersButton: UIButton!
    @IBOutlet weak var followingButton: UIButton!
    @IBOutlet weak var homeFeed: UITableView!
    
    //variable passed to user list indicating what kindof list is to follow
    var listTypePass: String?
    
    //references to the tableview and its data sources
    let cellId = "fc"
    var challenges = [Challenge]()
    var tableViewController = UITableViewController()
    
    //that thing that controls the upload process from feeds
    var uploadProcessDelegate: UploadProcessDelegate!
    //that thing i wrote that controls feeds uniformly
    var feedDelegate: FeedDelegate!
    
    //bool to prevent double user load in beginning
    var userSet: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Global.setupBannerAd(self, tab: true)
        //this only appears when setting your image
        imageUploadProgressView.isHidden = true
        
        uploadProcessDelegate = UploadProcessDelegate(self, "homeToUpload")
        homeFeed.dataSource = self
        tableViewController.tableView = homeFeed
        
        feedDelegate = FeedDelegate(viewController: self, username: Global.global.loggedInUser.username!, tableController: tableViewController, upd: uploadProcessDelegate, view: "homeToView", list: "userListFromHome")
       
        //set the user info labels to the logged in user metadata
        setupHome()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //ensure correct feed
        feedDelegate.handleRefresh()
        //this override exists so that the home metadata is updated on each tab click
        super.viewWillAppear(animated)
        if !userSet{
            let getLoginParams = [
                "usernames[0]": Global.global.loggedInUser.username!
            ]
            URLSession.shared.dataTask(with: Global.createServerRequest(params: getLoginParams, intent: "getUsers")){data, response, error in
                if let data = data{
                    let json = JSON(data: data)
                    OperationQueue.main.addOperation {
                        Global.global.loggedInUser = Global.jsonToUser(json: json[0].dictionaryValue)
                        self.setupHome()
                    }
                }
                }.resume()
        }
    }
    
    //takes care of setting all the home metadata
    func setupHome(){
        self.title = Global.global.loggedInUser.username!
        usernameLabel.text = Global.global.loggedInUser.username
        bioTextView.text = Global.global.loggedInUser.bio
        
        Global.global.getUserImage(username: Global.global.loggedInUser.username!, view: userImage)
        userSet = false
    }
    
    //determines what information needs to be passed to the next segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //if its a user list, pass the type and the logged in user
        if (sender as? UIButton == followersButton || sender as? UIButton == followingButton){
            let nextViewController = segue.destination as! UITableViewController
            let nextUserListController = nextViewController as? UserListViewController
            nextUserListController?.listType = listTypePass
            nextUserListController?.user = Global.global.loggedInUser
            
        //if its the upload page, pass the challenge, the video binary data, and a nice thumbnail for the video
        }else if let nextViewController = segue.destination as? UploadViewController{
            nextViewController.challenge = uploadProcessDelegate.challengePass
            nextViewController.videoData = uploadProcessDelegate.videoData
            nextViewController.previewImage = uploadProcessDelegate.videoPreview
            
        //if its the list of acceptances, then pass the challenge
        }else if let next = segue.destination as? AcceptanceTableViewController{
            next.challenge = uploadProcessDelegate.challengePass
        }
            
        //if its a generic user list, dont panic, the feed delegate initiated it, so just give it the info the feedDelegate has for it
        else if let next = segue.destination as? UserListViewController{
            next.listType = feedDelegate.listTypePass
            next.challenge = feedDelegate.challengePass
        }
    }
    
    //functions that initiate a segue to a user list
    @IBAction func followerButtonPressed(_ sender: UIButton) {
        listTypePass = "followers"
        performSegue(withIdentifier: "userListFromHome", sender: sender)
    }
    @IBAction func followingButtonPressed(_ sender: UIButton) {
        listTypePass = "following"
        performSegue(withIdentifier: "userListFromHome", sender: sender)
    }
    
    @IBAction func userImageTapped(_ sender: UITapGestureRecognizer) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: {})
    }
    
    //image setting functions
    
    //huge conveluded bucket of upload junk i need to encapsulate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else{
            fatalError("error retrieving selected image")
        }
        
        let imageData = UIImageJPEGRepresentation(selectedImage, 0.5)
        
        var request = URLRequest(url: Global.url!)
        request.httpMethod = "POST"
        let body = NSMutableData()
        let boundary = NSUUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        body.append("\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"intent\"\r\n\r\nimage".data(using: .utf8)!)
        body.append("\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"set\"\r\n\r\ntrue".data(using: .utf8)!)
        body.append("\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"securityKey\"\r\n\r\n\(Global.securityKey)".data(using: .utf8)!)
        body.append("\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"username\"\r\n\r\n\(Global.global.loggedInUser.username!)".data(using: .utf8)!)
        body.append("\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"image\"; filename=\"\(Global.global.loggedInUser.username!)\"\r\nContent-Type:\r\n\r\n".data(using: .utf8)!)
        body.append(imageData!)
        body.append("\r\n\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body as Data
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        imageUploadProgressView.isHidden = false
        session.dataTask(with: request){data, response, error in
            if let data = data{
                self.completeSettingImage(JSON(data: data))
                self.imageUploadProgressView.isHidden = true
                self.imageUploadProgressView.setProgress(0, animated: false)
            }
            }.resume()
        picker.dismiss(animated: true, completion: {})
        
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    //handles it if the server couldn't deal with the image for whatever reason
    func completeSettingImage(_ json: JSON){
        switch json["success"].stringValue{
        case "false":
            Global.showAlert(title: "Failed to set user image", message: "the user image could not be uploaded at this time", here: self)
            break
        default:
            Global.global.imageQueues.removeValue(forKey: Global.global.loggedInUser.username!)
            Global.global.userImages.removeValue(forKey: Global.global.loggedInUser.username!)
            setupHome()
            break
        }
    }
    
    //MARK: misc methods
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        userImage.removeFromSuperview()
        userImage.image = nil
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let uploadProgress = Double(totalBytesSent)/Double(totalBytesExpectedToSend)
        imageUploadProgressView.progress = Float(uploadProgress)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedDelegate.getNumRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        return feedDelegate.getChallengeCell(indexPath: indexPath)
    }
}
