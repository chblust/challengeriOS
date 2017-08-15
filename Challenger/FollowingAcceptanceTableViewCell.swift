//
//  FollowingAcceptanceTableViewCell.swift
//  Challenger
//
//  Created by Chris Blust on 5/29/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit

class FollowingAcceptanceTableViewCell: UITableViewCell {
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var userImage: UIImageView!{
        didSet{
            userImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userImageTapped)))
        }
    }
    @IBOutlet weak var challengeButton: UIButton!
    var messageButtonAction: ((UITableViewCell)->Void)?
    var userImageAction: ((FollowingAcceptanceTableViewCell)->Void)?
    var challengeAction: ((FollowingAcceptanceTableViewCell)->Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    @IBAction func messageButtonPressed(_ sender: UIButton) {
        messageButtonAction?(self)
    }
    func userImageTapped(){
        userImageAction?(self)
    }
    @IBAction func challengeButtonTapped(_ sender: UIButton) {
        challengeAction?(self)
    }
}
