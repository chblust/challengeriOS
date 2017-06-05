//
//  User.swift
//  Challenger
//
//  Created by Chris Blust on 5/16/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import Foundation

class User {
    var username: String?
    var bio: String?
    var email: String?
    var followers: [String]?
    var following: [String]?
    
    init(username: String, bio: String, email: String, followers: [String], following: [String]){
        self.username = username
        self.bio = bio
        self.email = email
        self.followers = followers
        self.following = following
    }
}
