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
    static let global = Global()
    var loggedInUser: User!
    var userImages = [String: UIImage]()
    var imageQueues = [String: [UIImageView]]()
    static let ip = "http://96.249.48.217/"
    static let url = URL(string: Global.ip)
    static let securityKey = "4qfY2ASbr0VTqwItKrrMHSvPKgUj89aJ4QjlbOEHawx8V1Ef9ahy95JREJAZgycxYRCsj9OcgqKDQx75mOcZ0aObgv8Hv1576oJu"
    static let admobAdUnitId = "ca-app-pub-3025080868728529/9894486690"
    static let admobTestAdUnitId = "ca-app-pub-3940256099942544/6300978111"
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
    
    static func createServerRequest(params: [String: String], intent: String)->URLRequest{
        var finalParams = params
        finalParams["intent"] = intent
        finalParams["securityKey"] = Global.securityKey
        var request = URLRequest(url: Global.url!)
        request.httpMethod = "POST"
        request.httpBody = Global.createPostParameters(params: finalParams)
        return request
    }
    static func showAlert(title: String, message: String, here: UIViewController){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        here.present(alertController, animated: true, completion: nil)
    }
    static func jsonToUser(json: [String: JSON])->User{
        return User(username: json["username"]!.stringValue, bio: json["bio"]!.stringValue, email: json["email"]!.stringValue, followers: json["followers"]!.arrayObject as! [String], following: json["following"]!.arrayObject as! [String])
    }
    static func jsonToChallenge(json: [String: JSON])->Challenge{
        return Challenge(name: json["name"]!.stringValue, author: json["author"]!.stringValue, instructions: json["instructions"]!.stringValue, datePosted: json["datePosted"]!.stringValue, likers: json["likers"]!.arrayObject as! [String], rechallengers: json["rechallengers"]!.arrayObject as! [String], feedType: json["feedType"]!.stringValue, poster: json["poster"]!.stringValue, acceptedCount: json["acceptedCount"]!.stringValue)
    }
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
    static func textIsSafe(textField: UITextField, here: UIViewController)->Bool{
        if (textField.text == ""){
            showAlert(title: "Empty Field", message: "please fill out all required information", here: here)
            return false
        }
        if (textField.text!.contains("&") || textField.text!.contains("=")){
            showAlert(title: "Invalid Entry", message: "text entered contains illegal characters", here: here)
        }
        return true
    }
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
    func getUserImage(username: String, view: UIImageView){
        if userImages.keys.contains(username){
            setUserImage(image: userImages[username]!, view: view)
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
                                self.completeQueue(image: self.userImages[username]!, views: self.imageQueues[username]!)
                            }
                        }
                    }
                }.resume()
            }
        }
        
    }
    
    func completeQueue(image: UIImage, views: [UIImageView]){
        for imageView in views{
            imageView.image = image
        }
    }
    
    func setUserImage(image: UIImage, view: UIImageView){
        view.image = image
    }
    
    static func setupBannerAd(_ viewController: UIViewController, tab: Bool){
        let bannerView = GADBannerView(adSize: kGADAdSizeFullBanner)
        bannerView.frame.origin.x = 0
        if tab{
                bannerView.frame.origin.y = viewController.view.frame.height -  viewController.navigationController!.toolbar.frame.height - bannerView.frame.height
                 viewController.view.addSubview(bannerView)
            
        }else{
            
            bannerView.frame.origin.y = viewController.view.frame.height - bannerView.frame.height
             viewController.view.addSubview(bannerView)
        }
       
        bannerView.adUnitID = admobTestAdUnitId
        bannerView.rootViewController = viewController
        bannerView.load(GADRequest())
    }
}
