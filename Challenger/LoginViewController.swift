///
//  ViewController.swift
//  Challenger
//
//  Created by Chris Blust on 5/13/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit
import SwiftyJSON
import GoogleMobileAds
import PusherSwift
import MediaPlayer
class LoginViewController: UIViewController, UITextFieldDelegate, URLSessionDelegate {
    //references to views
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var welcomeToChallengerLabel: UILabel!
    
    @IBOutlet weak var indicatorLabel: UILabel!
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var createUserButton: UIButton!
    var moviePlayer: MPMoviePlayerController!
    override func viewDidLoad() {
        super.viewDidLoad()
        indicatorLabel.isHidden = true
        let videoUrl = Bundle.main.url(forResource: "loginVideo", withExtension: "mp4")
        self.moviePlayer = MPMoviePlayerController(contentURL: videoUrl)
        self.moviePlayer.controlStyle = .none
        self.moviePlayer.scalingMode = .aspectFill
        self.moviePlayer.view.frame = self.view.frame
        self.view.insertSubview(moviePlayer.view, at: 0)
        self.moviePlayer.play()
        NotificationCenter.default.addObserver(self, selector: #selector(loopVideo), name: NSNotification.Name.MPMoviePlayerPlaybackDidFinish, object: self.moviePlayer)
        self.navigationItem.title = "Login"
        Global.global.currentViewController = self
        Global.setupBannerAd(self, tab: false)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.setToolbarHidden(true, animated: true)
        self.usernameField.center.x -= self.view.bounds.width
        self.passwordField.center.x -= self.view.bounds.width
        self.loginButton.center.x -= self.view.bounds.width
        self.createUserButton.center.x -= self.view.bounds.width
        welcomeToChallengerLabel.center.x -= self.view.bounds.width
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {  self.welcomeToChallengerLabel.center.x += self.view.bounds.width}, completion: nil)
        UIView.animate(withDuration: 0.5, delay: 0.1,
                       options: [.curveEaseIn],
                       animations: {
                        self.usernameField.center.x += self.view.bounds.width
                        
        },
                       completion: nil
        )
        UIView.animate(withDuration: 0.5, delay: 0.2, options: .curveEaseInOut, animations: { self.passwordField.center.x += self.view.bounds.width}, completion: nil)
        UIView.animate(withDuration: 0.5, delay: 0.3, options: .curveEaseInOut, animations: {  self.loginButton.center.x += self.view.bounds.width}, completion: nil)
        UIView.animate(withDuration: 0.5, delay: 0.4, options: .curveEaseInOut, animations: {  self.createUserButton.center.x += self.view.bounds.width}, completion: nil)
        //establish control over text fields
        usernameField.delegate = self
        passwordField.delegate = self
        
        //checks to see if user has previous login saved, logs in with that username if so
        if let username = UserDefaults.standard.value(forKey: "loginUsername") as? String{
            let params = [
                "username": username
            ]
            
            URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "checkUser")){data, response, error in
                if let data = data{
                    let response = String(data: data, encoding: .utf8)
                    switch response!{
                    case "bool(false)\n":
                        OperationQueue.main.addOperation {
                            Global.pusher.nativePusher.unsubscribe(interestName: username)
                            Global.global.showAlert(title: "Invalid User", message: "the logged in user no longer exists!", here:  self)
                        }
                        break
                    default:
                        OperationQueue.main.addOperation {
                            self.completeLogin(response: "true", username: username, sender: self.loginButton)
                        }
                        break
                    }
                }
                }.resume()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        
    }
    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        if Global.textIsSafe(textField: usernameField, here: self){
            if Global.textIsSafe(textField: passwordField, here: self){
                //get username for later
                let username = usernameField.text!
                //attempt login with server
                URLSession.shared.dataTask(with: Global.createServerRequest(params: [
                    "username": usernameField.text!,
                    "password": passwordField.text!
                    ], intent: "login")){data, response, error in
                    if let data = data{
                        let json = JSON(data: data)
                        //completion handler
                        OperationQueue.main.addOperation {
                            //set the username for automatic login
                            UserDefaults.standard.set(username, forKey: "loginUsername")
                            self.completeLogin(response: json["success"].stringValue, username: username, sender: sender)
                        }
                    }
                }.resume()
            }
        }
    }
    
    func completeLogin(response: String, username: String, sender: UIButton){
        switch response{
        case "true":
            //get the user metadata, set login, go to home page
            indicatorLabel.isHidden = true
                URLSession.shared.dataTask(with: Global.createServerRequest(params: [
                    "usernames[0]": username
                    ], intent: "getUsers")){data, response, error in
                if let data = data{
                    let json = JSON(data: data)
                    
                    Global.global.loggedInUser = Global.jsonToUser(json[0].dictionaryValue)
                    
                    OperationQueue.main.addOperation {
                        Global.pusher.nativePusher.subscribe(interestName: Global.global.loggedInUser.username!)
                        self.performSegue(withIdentifier: "login", sender: sender)
                    }
                }
                }.resume()
            
            break
        case "false":
            indicatorLabel.text = "Password Incorrect"
            indicatorLabel.isHidden = false
            break
        default:
            //if server returns null
            indicatorLabel.text = "User does not exist"
            indicatorLabel.isHidden = false
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let next = segue.destination as? HomeViewController{
            //tell the home view controller that it doesnt need to get the logged in user metadata again
            
            
            next.userSet = true
        }else if let next = segue.destination as? UITabBarController{
            //print(next.tabBarController?.viewControllers)
            Global.global.setupNotificationsBadge(next.tabBar.items![4])
            next.selectedIndex = 2
            next.customizableViewControllers = nil
        }
    }
    
    //misc methods
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        loginButtonPressed(loginButton)
        return true
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    @IBAction func unwindToVC1(segue:UIStoryboardSegue) { }
    func loopVideo(){
        self.moviePlayer.play()
    }
}
