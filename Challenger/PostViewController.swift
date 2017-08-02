//
//  PostViewController.swift
//  Challenger
//
//  Created by Chris Blust on 5/18/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit
import SwiftyJSON
class PostViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var challengeNameTextField: UITextField!
    @IBOutlet weak var challengeInstructionsTextField: UITextField!
    @IBOutlet weak var postButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Global.setupBannerAd(self, tab: true)
        challengeNameTextField.delegate = self
        challengeInstructionsTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Global.global.currentViewController = self
    }
    
    @IBAction func postButtonPressed(_ sender: UIButton) {
        //get information to send to server
        
        if (Global.textIsSafe(textField: challengeNameTextField, here: self) && Global.textIsSafe(textField: challengeInstructionsTextField, here: self)){
                URLSession.shared.dataTask(with: Global.createServerRequest(params: [
                    "name": challengeNameTextField.text!,
                    "instructions":challengeInstructionsTextField.text!,
                    "username":Global.global.loggedInUser.username!
                    ], intent: "createChallenge")){data, response, error in
                if let data = data{
                    let json = JSON(data: data)
                    OperationQueue.main.addOperation {
                        self.completePost(json: json);
                    }
                }
            }.resume()
        }
    }
    
    //handles the server response, tells the user if it posted or if there already is a challenge with this name
    func completePost(json: JSON){
        switch json["success"]{
        case "true":
            challengeNameTextField.text = ""
            challengeInstructionsTextField.text = ""
           tabBarController?.selectedIndex = 2
           if let next = tabBarController?.viewControllers?[2] as? FeedViewController{
                next.feedDelegate.handleRefresh()
           }
            break
        case "false":
            Global.global.showAlert(title: "Challenge name Taken!", message: "a challenge already exists with this name", here: self)
            break
        default:break
        }
    }
    
    //methods that limit the character input of the field and view
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let str = textField.text
        if textField == challengeNameTextField{
            if str!.characters.count <= 30 {
                return true
            }
            textField.text = str!.substring(to: str!.index(str!.startIndex, offsetBy: 30))
        }else if textField == challengeInstructionsTextField{
            if str!.characters.count <= 200{
                return true
            }
            textField.text = str!.substring(to: str!.index(str!.startIndex, offsetBy: 200))
        }
        
        return false
    }
    
    //misc methods
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
//    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
//        textView.resignFirstResponder()
//        return true
//    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    @IBAction func viewTapped(_ sender: UITapGestureRecognizer) {
        challengeInstructionsTextField.resignFirstResponder()
        challengeNameTextField.resignFirstResponder()
    }
}
