//
//  PostViewController.swift
//  Challenger
//
//  Created by Chris Blust on 5/18/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit
import SwiftyJSON
class PostViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    @IBOutlet weak var challengeNameTextField: UITextField!
    @IBOutlet weak var challengeInstructionsTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        Global.setupBannerAd(self, tab: true)
        challengeNameTextField.delegate = self
        challengeInstructionsTextView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func postButtonPressed(_ sender: UIButton) {
        //get information to send to server
        if (Global.textIsSafe(textField: challengeNameTextField, here: self) && Global.textIsSafe(textView: challengeInstructionsTextView, here: self)){
            let params = [
                "name": challengeNameTextField.text!,
                "instructions":challengeInstructionsTextView.text!,
                "username":Global.global.loggedInUser.username!
            ]
            let task = URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "createChallenge")){data, response, error in
                if let data = data{
                    let json = JSON(data: data)
                    OperationQueue.main.addOperation {
                        self.completePost(json: json);
                    }
                }
            }
            task.resume()
        }
    }
    
    func completePost(json: JSON){
        switch json["success"]{
        case "true":
            challengeNameTextField.text = ""
            challengeInstructionsTextView.text = ""
            Global.showAlert(title: "Challenge Posted", message: "your challenge is now public!", here: self)
            break
        case "false":
            Global.showAlert(title: "Challenge name Taken!", message: "a challenge already exists with this name", here: self)
            break
        default:break
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let str = textField.text
        
            if str!.characters.count <= 40 {
                return true
            }
            textField.text = str!.substring(to: str!.index(str!.startIndex, offsetBy: 40))
        
        
        return false
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
                let str = textView.text
        
                    if str!.characters.count <= 200 {
                        return true
                    }
                    textView.text = str!.substring(to: str!.index(str!.startIndex, offsetBy: 200))
                
                
                return false
    }
}
