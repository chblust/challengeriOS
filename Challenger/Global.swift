//
//  Global.swift
//  Challenger
//
//  Created by Chris Blust on 5/14/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import GoogleMobileAds
class Global: NSObject{
    //server information
    static let ip = "http://96.249.48.217/"
    static let url = URL(string: Global.ip)
    static let securityKey = "4qfY2ASbr0VTqwItKrrMHSvPKgUj89aJ4QjlbOEHawx8V1Ef9ahy95JREJAZgycxYRCsj9OcgqKDQx75mOcZ0aObgv8Hv1576oJu"
    
    //admob ad ids
    static let admobAdUnitId = "ca-app-pub-3025080868728529/9894486690"
    static let admobTestAdUnitId = "ca-app-pub-3940256099942544/6300978111"
    
    //instantiated object to hold program-wide used info such as login
    static let global = Global()
    //holds the currently logged in user metadata
    var loggedInUser: User!
    //holds the cache of userImages loaded from the server
    var userImages = [String: UIImage]()
    //list of views waiting for a specific user image to return from the server
    var imageQueues = [String: [UIImageView]]()
    
    //correctly formats an associative array into post request parameters and returns the binary data
    static func createPostParameters(params: [String: String])->Data{
        var postString = ""
        var x = 0
        for key in params.keys{
            postString += key + "=" + params[key]!
            if x != params.count - 1{
                postString += "&"
            }
            x += 1
        }
        return postString.data(using: .utf8)!
    }
    
    //returns a post request to be used with the challenger server
    static func createServerRequest(params: [String: String], intent: String)->URLRequest{
        var finalParams = params
        finalParams["intent"] = intent
        finalParams["securityKey"] = Global.securityKey
        var request = URLRequest(url: Global.url!)
        request.httpMethod = "POST"
        request.httpBody = Global.createPostParameters(params: finalParams)
        return request
    }
    
    //shows a simple pop-up view with an OK button to dismiss
    static func showAlert(title: String, message: String, here: UIViewController){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        here.present(alertController, animated: true, completion: nil)
    }
    
    //takes in json formatted data from the server and translates it into a user object
    static func jsonToUser(json: [String: JSON])->User{
        
        return User(username: json["username"]!.stringValue, bio: json["bio"]!.stringValue, email: json["email"]!.stringValue, followers: json["followers"]!.arrayObject as! [String], following: json["following"]!.arrayObject as! [String])
         
    }
    
    //takes in json formatted data from the server and translates it into a challenge object
    static func jsonToChallenge(json: [String: JSON])->Challenge{
        return Challenge(name: json["name"]!.stringValue, author: json["author"]!.stringValue, instructions: json["instructions"]!.stringValue, datePosted: json["datePosted"]!.stringValue, likers: json["likers"]!.arrayObject as! [String], rechallengers: json["rechallengers"]!.arrayObject as! [String], feedType: json["feedType"]!.stringValue, poster: json["poster"]!.stringValue, acceptedCount: json["acceptedCount"]!.stringValue)
    }
    
    //ensures the passed text field is not empty and does not include characters that will mess with the post request
    static func textIsSafe(textView: UITextView, here: UIViewController)->Bool{
        if (textView.text == ""){
            showAlert(title: "Empty Field", message: "please fill out all required information", here: here)
            return false
        }
        if (textView.text!.contains("&") || textView.text!.contains("=")){
            showAlert(title: "Invalid Entry", message: "text entered contains illegal characters", here: here)
        }
        return true
    }
    
    //same as above but with a textView
    static func textIsSafe(textField: UITextField, here: UIViewController)->Bool{
        if (textField.text == ""){
            showAlert(title: "Empty Field", message: "please fill out all required information", here: here)
            return false
        }
        if (textField.text!.contains("&") || textField.text!.contains("=")){
            showAlert(title: "Invalid Entry", message: "text entered contains illegal characters", here: here)
            return false
        }
        return true
    }
    
    //takes in a string and returns the string but with spaces replaced by underscores
    static func getServerSafeName(_ name: String)->String{
        var ret = "";
        
        for char in name.characters{
            if (char == " "){
                ret = "\(ret)_";
            }else{
                ret = "\(ret)\(char)";
            }
        }
        return ret;
    }
    
    /***
     this one is cool:
     -takes in the imageview that needs a userimage and the username of that user
     -if the userimage exists in the cache, set the imageview to it and send it on its way
     -if other views are already waiting for the same image (a queue exists for it), put this view in that queue
     -if this is the first imageview that's requested this image, start a queue, put it in it, and request the image from the server
     -when an image is downloaded, it is applied to all the images in its queue, the queue is destroyed, and the image is put in the cache
     ***/
    func getUserImage(username: String, view: UIImageView){
        if userImages.keys.contains(username){
            setUserImage(image: userImages[username]!, imageView: view)
        }else{
            if imageQueues.keys.contains(username){
                imageQueues[username]!.append(view)
            }else{
                
                imageQueues[username] = [UIImageView]()
                imageQueues[username]!.append(view)
                let params = [
                    "username": username,
                    "set" : "false"
                ]
                URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "image")){data, response, error in
                    if let data = data{
                        if (String(data: data, encoding: .utf8) != "false"){
                            //set userImageView to userImage from server
                            OperationQueue.main.addOperation {
                                self.userImages[username] = UIImage(data: data)!
                                self.completeQueue(image: self.userImages[username]!, username: username)
                            }
                        }
                    }
                    }.resume()
            }
        }
        
    }
    
    //method called on completion of userimage retrieval from server
    func completeQueue(image: UIImage, username: String){
        let views = self.imageQueues[username]!
        for imageView in views{
            setUserImage(image: image, imageView: imageView)
        }
        self.imageQueues.removeValue(forKey: username)
    }
    
    func setUserImage(image: UIImage, imageView: UIImageView){
        imageView.layer.borderWidth = 1
        imageView.layer.masksToBounds = false
        imageView.layer.borderColor = UIColor.black.cgColor
        imageView.layer.cornerRadius = imageView.frame.height/2
        imageView.clipsToBounds = true
        imageView.image = image
    }
    
    //sets up the admob banner at the bottom of a view, with a bool to indicate the banner must appear above tabs
    //note- dont delete, it makes us money
    static func setupBannerAd(_ viewController: UIViewController, tab: Bool){
        let bannerView = GADBannerView(adSize: kGADAdSizeFullBanner)
        bannerView.frame.origin.x = 0
        if tab{
            //49 is the tab bar height
            bannerView.frame.origin.y = viewController.view.frame.height -  49 - bannerView.frame.height
            viewController.view.addSubview(bannerView)
            
        }else{
            
            bannerView.frame.origin.y = viewController.view.frame.height - bannerView.frame.height
            viewController.view.addSubview(bannerView)
        }
        bannerView.frame.size.width = viewController.view.frame.width
        
        bannerView.adUnitID = admobTestAdUnitId
        bannerView.rootViewController = viewController
        bannerView.load(GADRequest())
    }
}
