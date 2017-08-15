//
//  UploadViewController.swift
//  Challenger
//
//  Created by Chris Blust on 5/20/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit
import SwiftyJSON
import AVFoundation
import BRYXBanner
class UploadViewController: UIViewController, URLSessionDelegate, URLSessionTaskDelegate{
    //here are the references to the views
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var uploadProgressView: UIProgressView!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var processingActivityIndicatorView: UIActivityIndicatorView!
    
    //here are the variables passed from the previous class before the segue
    var previewImage: UIImage?
    var videoData: Data?
    var challenge: Challenge?
    var feed: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        Global.setupBannerAd(self, tab: false)
        
        //set the image to the preview of the selected video
//        imageView.image = previewImage
        Global.global.setUserImage(image: previewImage!, imageView: imageView)
        
        //ensures the processing indicator is hidden
        processingActivityIndicatorView.hidesWhenStopped = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //ensures the processing indicator is hidden
        processingActivityIndicatorView.stopAnimating()
        Global.global.currentViewController = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //method to demonstrate how not to write code below:
    @IBAction func uploadButtonTapped(_ sender: UIButton) {
        if videoData != nil{
            //ensure user cannot initiate a second upload or cancel upload
            cancelButton.isHidden = true
            uploadButton.isUserInteractionEnabled = false
            uploadButton.setTitle("Uploading...", for: .normal)
            //create http mult-part form request
            var request = URLRequest(url: Global.url!)
            request.httpMethod = "POST"
            let body = NSMutableData()
            let boundary = NSUUID().uuidString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            body.append("\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"intent\"\r\n\r\nupload".data(using: .utf8)!)
            body.append("\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"securityKey\"\r\n\r\n\(Global.securityKey)".data(using: .utf8)!)
            body.append("\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"username\"\r\n\r\n\(Global.global.loggedInUser.username!)".data(using: .utf8)!)
            body.append("\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"challengeName\"\r\n\r\n\(challenge!.name!)".data(using: .utf8)!)
            body.append("\r\n--\(boundary)\r\nContent-Disposition: form-data; name=\"upload\"; filename=\"\(Global.global.loggedInUser.username!)\"\r\nContent-Type: video/quicktime\r\nMedia type: video/quicktime\r\n\r\n".data(using: .utf8)!)
            body.append(videoData!)
            body.append("\r\n\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            request.httpBody = body as Data
            
            //create a urlsession that can be referenced to send progress to the progress bar, send post request
            URLSession(configuration: .default, delegate: self, delegateQueue: .main).dataTask(with: request){data, response, error in
                if let data = data{
                    let json = JSON(data: data)
                    
                    OperationQueue.main.addOperation {
                        self.completeUpload(success: json["success"].stringValue, sender: sender)
                    }
                    
                }
            }.resume()
        }else{
            Global.global.showAlert(title: "No Video Selected", message: "please select a video", here: self)
        }
    }
    
    //tells the user if the video upload was a succes or not
    func completeUpload(success: String, sender: Any?){
        //alerts the user on whether or not the challenge was uploaded, returns to the user's feed
        processingActivityIndicatorView.stopAnimating()
        switch success{
        case "true":
            Banner(title: "Video Successfully Uploaded!", subtitle: self.challenge?.name, image: nil, backgroundColor: UIColor.darkGray, didTapBlock: {
                Global.global.currentViewController.presentAcceptances(challenge: self.challenge!)
            }).show(duration: 1.5)
            for cell in feed.visibleCells{
                if let cell = cell as? FeedTableViewCell{
                    if cell.challengeNameLabel.text == self.challenge?.name!{
                        cell.acceptCountLabel.text = "\(Int(cell.acceptCountLabel.text!)! + 1)"
                    }
                }
            }
            break
        case "false":
            Banner(title: "Error Uploading Video", subtitle: "Please try again later", image: nil, backgroundColor: UIColor.red, didTapBlock: {}).show(duration: 1.5)
        default:
            break
        }
        self.dismiss(animated: true, completion: {})
    }
    
    //method that allows the progress of the upload to be sent to the progress bar
    var processingPresented = false
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let uploadProgress = Double(totalBytesSent)/Double(totalBytesExpectedToSend)
        uploadProgressView.progress = Float(uploadProgress)
        
        //if the upload is done, show that the server must now process the uploaded video
        if uploadProgress == 1.0 && !processingPresented{
            processingPresented = true
            uploadButton.setTitle("Processing...", for: .normal)
            processingActivityIndicatorView.startAnimating()
        }
    }
}
