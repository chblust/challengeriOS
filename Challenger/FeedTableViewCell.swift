//
//  FeedTableViewCell.swift
//  Challenger
//
//  Created by Chris Blust on 5/18/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit

class FeedTableViewCell: UITableViewCell {
    @IBOutlet weak var challengeNameLabel: UILabel!
    @IBOutlet weak var challengeInstructionsLabel: UITextView!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
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
    
    @IBOutlet weak var rechallengerLabel: UILabel!
    @IBOutlet weak var rechallengeImageView: UIImageView!
    var reportButtonAction: ((UITableViewCell)->Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
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

}
