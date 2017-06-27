//
//  LoadMoreTableViewCell.swift
//  Challenger
//
//  Created by Chris Blust on 6/26/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit

class LoadMoreTableViewCell: UITableViewCell {
    @IBOutlet weak var button: UIButton!
    var buttonAction: ((UITableViewCell)->Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
       
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    @IBAction func buttonAction(_ sender: UIButton) {
        buttonAction?(self)
    }

}
