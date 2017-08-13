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
import BRYXBanner
class UploadProcessDelegate:NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    //var videoMethod: String?
    var videoExists: Bool?
    //variables that are set in the UploadViewController ahead of time
    var viewController: UIViewController!
    var segueIdentifier: String!
    init(_ viewController: UIViewController){
        self.viewController = viewController
    }
    
    //universal method that is called whenever an accept button is tapped
    func acceptButtonTapped(challenge: Challenge, sender: Any?){
        //check to make sure user has not already uploaded to this challenge
        URLSession.shared.dataTask(with: Global.createServerRequest(params: [
            "username":Global.global.loggedInUser.username!,
            "challengeName": challenge.name!,
            "type":"check"
        ], intent: "acceptance")){data, response, error in
            if let data = data{
                let json = JSON(data: data)
                OperationQueue.main.addOperation {
                    switch json["response"].stringValue{
                    case "false":
                        self.acceptChallenge(challenge: challenge, sender: sender)
                        break
                    case "true":
                       // Global.global.showAlert(title: "Challenge already accepted!", message: "You cannot accept a challenge more than once!", here: self.viewController!)
                        Banner(title: "You've already accepted this challenge!", subtitle: "", image: UIImage(named: "challengeImage"), backgroundColor: UIColor.blue, didTapBlock: nil).show(duration: 1.5);
                        break
                    default:break
                    }
                }
            }
        }.resume()
    }
    //presents the two methods of getting the video to upload in a pop up
    func acceptChallenge(challenge: Challenge, sender: Any?){
       // challengePass = challenge
        let videoChoice = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        videoChoice.addAction(UIAlertAction(title: "Choose Video", style: .default, handler: { (action: UIAlertAction!) in
            
            videoChoice.dismiss(animated: true, completion: nil)
            self.videoExists = true
            self.completeVideoChoice(challenge)
            
        }))
        
        videoChoice.addAction(UIAlertAction(title: "Capture Video", style: .default, handler: { (action: UIAlertAction!) in
            
            videoChoice.dismiss(animated: true, completion: nil)
            self.videoExists = false
            self.completeVideoChoice(challenge)
           
        }))
        
        videoChoice.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            
            videoChoice.dismiss(animated: true, completion: nil)
        }))
        viewController.present(videoChoice, animated: true, completion: nil)
    }
    
    func completeVideoChoice(_ challenge: Challenge){
        let imagePickerController = ChallengeImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.challenge = challenge
        
        switch videoExists!{
        case true:
            //setup and display the video picker
            imagePickerController.sourceType = .photoLibrary
            
            imagePickerController.mediaTypes = ["public.movie"]
        
            viewController.present(imagePickerController, animated: true, completion: nil)
            //next, the imagePickerControllerDelegate method gets the video info and executes the segue
            
            break
        case false:
            //check for camera
            if (UIImagePickerController.isSourceTypeAvailable(.camera)){
                //setup and present camera
                imagePickerController.sourceType = .camera
                imagePickerController.mediaTypes = [kUTTypeMovie as String]
                
                viewController.present(imagePickerController, animated: true, completion: nil)
                
            }else{
                Global.global.showAlert(title: "No Camera!", message: "application could not access a camera", here: viewController)
            }
            
            //next, the imagePickerControllerDelegate method gets the video info and executes the segue
            
            break;
        }
        
    }
    
    //finishes picking of video and executes the segue to upload
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let picker = picker as! ChallengeImagePickerController
        var videoPreview: UIImage!
        var videoData: Data!
        switch videoExists!{
        case true:
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
               // viewController.performSegue(withIdentifier: segueIdentifier, sender: picker)
              showUploadViewController(challenge: picker.challenge!, previewImage: videoPreview!, videoData: videoData)
            }else{
                picker.dismiss(animated: true, completion: nil)
                Global.global.showAlert(title: "Video too long", message: "please choose a video 20 seconds or shorter", here: viewController)
            }
            
            break
            
            
        case false:
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
                               //limit the upload to 20 seconds
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
                    showUploadViewController(challenge: picker.challenge!, previewImage: videoPreview!, videoData: videoData)

                }else{
                    picker.dismiss(animated: true, completion: nil)
                    Global.global.showAlert(title: "Video too long", message: "please choose a video 20 seconds or shorter", here: viewController)
                }
                
                
            }else{
                fatalError("Could not retrieve video url")
            }
            break
        }
    }
    
    func showUploadViewController(challenge: Challenge, previewImage: UIImage, videoData: Data){
        let storyBoardReference = UIStoryboard(name: "Main", bundle: nil)
        let uploadViewController = storyBoardReference.instantiateViewController(withIdentifier: "uploadViewController") as! UploadViewController
        uploadViewController.challenge = challenge
        uploadViewController.previewImage = previewImage
        uploadViewController.videoData = videoData
        viewController.present(uploadViewController, animated: true, completion: nil)

    }
    
}
