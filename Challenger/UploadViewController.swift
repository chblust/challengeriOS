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
class UploadViewController: UIViewController, URLSessionDelegate, URLSessionTaskDelegate{
    //here are the references to the views
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var uploadProgressView: UIProgressView!
    @IBOutlet weak var uploadButton: UIButton!
    //here are the variables passed from the previous class before the segue
    var previewImage: UIImage?
    var videoData: Data?
    var challenge: Challenge?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Global.setupBannerAd(self, tab: false)
        //set the image to the preview of the selected video
        imageView.image = previewImage
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func uploadButtonTapped(_ sender: UIButton) {
        if videoData != nil{
            //ensure user cannot initiate a second upload
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
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
            let task = session.dataTask(with: request){data, response, error in
                if let data = data{
                    let json = JSON(data: data)
                    
                    OperationQueue.main.addOperation {
                        self.completeUpload(success: json["success"].stringValue, sender: sender)
                    }
                    
                }
            }
            task.resume()
        }else{
            Global.showAlert(title: "No Video Selected", message: "please select a video", here: self)
        }
    }
    
    func completeUpload(success: String, sender: Any?){
        //alerts the user on whether or not the challenge was uploaded, returns to the user's feed
        switch success{
            case "true":
                let alertController = UIAlertController(title: "Success!", message: "your video has been uploaded to the challenge: \(challenge!.name!)", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {(UIAlertAction) in
                    self.performSegue(withIdentifier: "unwindToFeed", sender: sender)
                }))
                present(alertController, animated: true, completion: nil)
            break
            case "false":
                
                let alertController = UIAlertController(title: "Failure!", message: "your video could not be uploaded to the challenge at this time", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {(UIAlertAction) in
                    self.performSegue(withIdentifier: "unwindToFeed", sender: sender)
                }))
                present(alertController, animated: true, completion: nil)
        default:
            break
        }
    }
    
    //method that allows the progress of the upload to be sent to the progress bar
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let uploadProgress = Double(totalBytesSent)/Double(totalBytesExpectedToSend)
        uploadProgressView.progress = Float(uploadProgress)
    }
}
