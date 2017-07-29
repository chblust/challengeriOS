//
//  CommentTableViewCell.swift
//  Challenger
//
//  Created by Chris Blust on 7/26/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit

class CommentTableViewCell: UITableViewCell {
    @IBOutlet weak var userImage: UIImageView!{
        didSet{
            userImage.addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(userTapped)))
        }
    }
    @IBOutlet weak var usernameLabel: UILabel!{
        didSet{
            usernameLabel.addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(userTapped)))
        }
    }
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likeCountButton: UIButton!
    
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var replyCountButton: UIButton!
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    
    var userAction: ((CommentTableViewCell) -> Void)?
    var likeAction: ((CommentTableViewCell) -> Void)?
    var likeCountAction: ((CommentTableViewCell) -> Void)?
    var replyAction: ((CommentTableViewCell) -> Void)?
    var replyCountAction: ((CommentTableViewCell) -> Void)?
    var reportAction: ((CommentTableViewCell) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func userTapped(){
        userAction?(self)
    }
    @IBAction func likeButtonPressed(_ sender: UIButton) {
        likeAction?(self)
    }
    @IBAction func likeCountButtonPressed(_ sender: UIButton) {
        likeCountAction?(self)
    }
    @IBAction func replyButtonPressed(_ sender: UIButton) {
        replyAction?(self)
    }
    @IBAction func replyCountButtonPressed(_ sender: UIButton) {
        replyCountAction?(self)
    }
    @IBAction func reportButtonPressed(_ sender: UIButton) {
        reportAction?(self)
    }

    
}
