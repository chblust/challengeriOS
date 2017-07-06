//
//  FeedTableViewCell.swift
//  Challenger
//
//  Created by Chris Blust on 5/18/17.
//  Copyright © 2017 Chris Blust. All rights reserved.
//

import UIKit

class FeedTableViewCell: UITableViewCell {
    @IBOutlet weak var acceptCountLabel: UILabel!
    @IBOutlet weak var challengeNameLabel: UILabel!
    @IBOutlet weak var challengeInstructionsLabel: UITextView!
    @IBOutlet weak var userImage: UIImageView!{
        didSet{
            userImage.addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(userTapped)))
            print("set")
        }
    }
    @IBOutlet weak var usernameLabel: UILabel!{
        didSet{
            usernameLabel.addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(userTapped)))
        }
    }
    @IBOutlet weak var datePostedLabel: UILabel!
    @IBOutlet weak var reportButton: UIButton!
    var acceptButtonAction: ((UITableViewCell)->Void)?
    var viewButtonAction: ((UITableViewCell)->Void)?
    var likeButtonAction: ((UITableViewCell)->Void)?
    var viewLikersButtonAction: ((UITableViewCell)->Void)?
    var rechallengeButtonAction: ((UITableViewCell)->Void)?
    var viewRechallengersButtonAction: ((UITableViewCell)->Void)?
    
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var viewLikersButton: UIButton!
    @IBOutlet weak var rechallengeButton: UIButton!
    @IBOutlet weak var viewRechallengersButton: UIButton!
    
    @IBOutlet weak var rechallengerLabel: UILabel!{
        didSet{
            rechallengerLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(rechallengerTapped)))
        }
    }
    @IBOutlet weak var rechallengeImageView: UIImageView!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var viewButton: UIButton!
    var reportButtonAction: ((UITableViewCell)->Void)?
    var userImageAction: ((FeedTableViewCell)->Void)?
    var rechallengerAction: ((FeedTableViewCell)->Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        //let tapGesture = UITapGestureRecognizer(target: self, action: #selector(userTapped))
        //userImage.addGestureRecognizer(tapGesture)
       // usernameLabel.addGestureRecognizer(tapGesture)
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    @IBAction func acceptButtonPressed(_ sender: Any) {
        acceptButtonAction?(self)
    }
    
    @IBAction func viewButtonPressed(_ sender: UIButton) {
        viewButtonAction?(self)
    }
    @IBAction func likeButtonPressed(_ sender: UIButton) {
        likeButtonAction?(self)
    }
    @IBAction func viewLikersButtonPressed(_ sender: UIButton) {
        viewLikersButtonAction?(self)
    }
    @IBAction func rechallengeButtonPressed(_ sender: UIButton) {
        rechallengeButtonAction?(self)
    }
    @IBAction func viewRechallengersButtonPressed(_ sender: UIButton) {
        viewRechallengersButtonAction?(self)
    }
    @IBAction func reportButtonPressed(_ sender: UIButton) {
        reportButtonAction?(self)
    }
    func userTapped(){
        print("bees!")
        userImageAction?(self)
    }
    func rechallengerTapped(){
        rechallengerAction?(self)
    }
    
    
}
