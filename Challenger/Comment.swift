//
//  Comment.swift
//  Challenger
//
//  Created by Chris Blust on 7/28/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import Foundation

class Comment{
    var uuid: String!
    var author: String!
    var challengeName: String!
    var message: String!
    var date: String!
    var replyingTo: String!
    var likers: [String]!
    var replys: [String]!
    
    init(uuid: String, author: String, challengeName: String, message: String, date: String, replyingTo: String, likers: [String], replys: [String]){
        self.uuid = uuid
        self.author = author
        self.challengeName = challengeName
        self.message = message
        self.date = date
        self.replyingTo = replyingTo
        self.likers = likers
        self.replys = replys
    }
}
