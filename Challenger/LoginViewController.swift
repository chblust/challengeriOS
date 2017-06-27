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
class LoginViewController: UIViewController, UITextFieldDelegate, URLSessionDelegate {
    //references to views
    @IBOutlet weak var usernameField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Global.setupBannerAd(self, tab: false)
        
        self.navigationController?.setToolbarHidden(true, animated: true)
        
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
                            Global.showAlert(title: "Invalid User", message: "the logged in user no longer exists!", here:  self)
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
                URLSession.shared.dataTask(with: Global.createServerRequest(params: [
                    "usernames[0]": username
                    ], intent: "getUsers")){data, response, error in
                if let data = data{
                    let json = JSON(data: data)
                    
                    Global.global.loggedInUser = Global.jsonToUser(json: json[0].dictionaryValue)
                    
                    OperationQueue.main.addOperation {
                        self.performSegue(withIdentifier: "login", sender: sender)
                    }
                }
                }.resume()
            
            break
        case "false":
            Global.showAlert(title: "Login failed!", message: "credentials didn't match", here: self)
            break
        default:
            //if server returns null
            Global.showAlert(title: "Invalid Username", message: "the entered username does not exist", here: self)
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let next = segue.destination as? HomeViewController{
            //tell the home view controller that it doesnt need to get the logged in user metadata again
            next.userSet = true
        }else if let next = segue.destination as? UITabBarController{
            print("ay\n\n\n\n\n")
            next.selectedIndex = 2
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
}
