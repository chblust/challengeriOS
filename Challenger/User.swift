//
//  User.swift
//  Challenger
//
//  Created by Chris Blust on 5/16/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

/***
 holds the information for a user; used to setup home pages and hold login info
 ***/

import Foundation

class User {
    var username: String?
    var bio: String?
    var email: String?
    var followers: [String]?
    var following: [String]?
    var acceptedCount: Int?
    
    init(username: String, bio: String, email: String, followers: [String], following: [String], acceptedCount: Int){
        self.username = username
        self.bio = bio
        self.email = email
        self.followers = followers
        self.following = following
        self.acceptedCount = acceptedCount
    }
    
    init(){
        self.username = "User has been Removed"
        self.bio = "This user no longer exists"
        self.email = ""
        self.followers = [String]()
        self.following = [String]()
    }
}
