//
//  UploadProcessDelegate.swift
//  Challenger
//
//  Created by Chris Blust on 5/23/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit
import SwiftyJSON
import AVFoundation
import MobileCoreServices

class UploadProcessDelegate:NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    var videoMethod: String?
    //variables that are set in the UploadViewController ahead of time
    var viewController: UIViewController!
    var segueIdentifier: String!
    
    var challengePass: Challenge?
    var videoPreview: UIImage?
    var videoData: Data?
    
    init(_ viewController: UIViewController, _ segue: String){
        self.viewController = viewController
        self.segueIdentifier = segue
    }
    func acceptButtonTapped(challenge: Challenge, sender: Any?){
        //check to make sure user has not already uploaded to this challenge
        let params = [
            "username":Global.global.loggedInUser.username!,
            "challengeName": challenge.name!,
            "type":"check"
        ]
        let task = URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "acceptance")){data, response, error in
            if let data = data{
                let json = JSON(data: data)
                OperationQueue.main.addOperation {
                    switch json["response"].stringValue{
                    case "false":
                        self.acceptChallenge(challenge: challenge, sender: sender)
                        break
                    case "true":
                        Global.showAlert(title: "Challenge already accepted!", message: "You cannot accept a challenge more than once!", here: self.viewController!)
                        break
                    default:break
                    }
                }
            }
        }
        task.resume()
    }
    
    func acceptChallenge(challenge: Challenge, sender: Any?){
        challengePass = challenge
        let videoChoice = UIAlertController(title: "Upload a video", message: "choose a video from your library, or capture one right now", preferredStyle: UIAlertControllerStyle.alert)
        videoChoice.addAction(UIAlertAction(title: "Choose", style: .default, handler: { (action: UIAlertAction!) in
           
            videoChoice.dismiss(animated: true, completion: nil)
            self.completeVideoChoice("choose")
        }))
        
        videoChoice.addAction(UIAlertAction(title: "Capture", style: .default, handler: { (action: UIAlertAction!) in
           
            videoChoice.dismiss(animated: true, completion: nil)
            self.completeVideoChoice("capture")
        }))
        
        videoChoice.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction!) in
            
            videoChoice.dismiss(animated: true, completion: nil)
            self.completeVideoChoice("cancel")
        }))
        viewController.present(videoChoice, animated: true, completion: nil)
    }
    
    func completeVideoChoice(_ choice: String){
        self.videoMethod = choice
        switch choice{
        case "choose":
            //setup and display the video picker
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .photoLibrary
            imagePickerController.delegate = self
            imagePickerController.mediaTypes = ["public.movie"]
            viewController.present(imagePickerController, animated: true, completion: nil)
            
            //next, the imagePickerControllerDelegate method gets the video info and executes the segue
            
            break
        case "capture":
            //check for camera
            if (UIImagePickerController.isSourceTypeAvailable(.camera)){
                //setup and present camera
                let captureVideoPicker = UIImagePickerController()
                captureVideoPicker.sourceType = .camera
                captureVideoPicker.mediaTypes = [kUTTypeMovie as String]
                captureVideoPicker.delegate = self
                viewController.present(captureVideoPicker, animated: true, completion: nil)
                
            }else{
                Global.showAlert(title: "No Camera!", message: "application could not access a camera", here: viewController)
            }
            
            //next, the imagePickerControllerDelegate method gets the video info and executes the segue
            
            break;
        default:
            
            break;
        }
    }
    
    //finishes picking of video and executes the segue to upload
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        switch videoMethod!{
        case "choose":
            //get the video url
            guard let selectedVideoUrl = info[UIImagePickerControllerMediaURL] as? URL else{
                fatalError("Fatal Error selecting media")
            }
            //get the binary data the video consists of
            do{
                videoData = try Data(contentsOf: selectedVideoUrl)
            }catch{
                fatalError("Fatal Error loading selected media")
            }
            let asset = AVAsset(url: selectedVideoUrl)
            let duration = CMTimeGetSeconds(asset.duration)
            if duration < 21{
                //get the thumbnail for the video
                let assetImageGenerator = AVAssetImageGenerator(asset: asset)
                var time = asset.duration
                time.value = min(time.value, 2)
                do{
                    let imageRef = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
                    videoPreview = UIImage(cgImage: imageRef)
                }catch{
                    fatalError("Fatal Error setting image preview to selected media thumbnail")
                    
                }
                //dismiss controller and execute the segue
                viewController.dismiss(animated: true, completion: nil)
                viewController.performSegue(withIdentifier: segueIdentifier, sender: picker)
            }else{
                picker.dismiss(animated: true, completion: nil)
                Global.showAlert(title: "Video too long", message: "please choose a video 20 seconds or shorter", here: viewController)
            }
            
            break
            
            
            
            
        case "capture":
            if let pickedVideo:URL = (info[UIImagePickerControllerMediaURL] as? URL){
                //save video to main photo album
                UISaveVideoAtPathToSavedPhotosAlbum(pickedVideo.relativePath, self, nil, nil)
                do{
                    videoData = try Data(contentsOf: pickedVideo)
                }catch{
                    fatalError("Could not retrieve video data")
                }
                let asset = AVAsset(url: pickedVideo)
                let duration = CMTimeGetSeconds(asset.duration)
                if duration < 21{
                let assetImageGenerator = AVAssetImageGenerator(asset: asset)
                var time = asset.duration
                time.value = min(time.value, 2)
                do{
                    let imageRef = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
                    let uiImage = UIImage(cgImage: imageRef)
                    
                    videoPreview = uiImage
                }catch{
                    fatalError("Fatal Error setting image preview to selected media thumbnail")
                    
                }
                //dismiss controller and execute the segue
                viewController.dismiss(animated: true, completion: nil)
                if let segueIdentifier = self.segueIdentifier{
                     viewController.performSegue(withIdentifier: segueIdentifier, sender: picker)
                }
                }else{
                    picker.dismiss(animated: true, completion: nil)
                    Global.showAlert(title: "Video too long", message: "please choose a video 20 seconds or shorter", here: viewController)
                }
               
                
            }else{
                fatalError("Could not retrieve video url")
            }
            
            
            break
        default:break
        }
    }
    
}
