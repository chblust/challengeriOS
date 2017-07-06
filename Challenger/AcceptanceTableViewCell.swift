//
//  AcceptanceTableViewCell.swift
//  Challenger
//
//  Created by Chris Blust on 5/29/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit

class AcceptanceTableViewCell: UITableViewCell {
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var userImage: UIImageView!{
        didSet{
            userImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userImageTapped)))
        }
    }
    @IBOutlet weak var usernameButton: UIButton!
    var usernameButtonAction: ((UITableViewCell)-> Void)?
    var likeButtonAction: ((UITableViewCell)->Void)?
    var removeButtonAction: ((UITableViewCell)->Void)?
    var userAction: ((AcceptanceTableViewCell)->Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func usernameButtonTapped(_ sender: UIButton) {
        usernameButtonAction?(self)
    }
    @IBAction func likeButtonTapped(_ sender: UIButton) {
        likeButtonAction?(self)
    }
    @IBAction func removeButtonTapped(_ sender: UIButton) {
        removeButtonAction?(self)
    }
    func userImageTapped(){
        userAction?(self)
    }
    
    
}
