//
//  Challenger.swift
//  Challenger
//
//  Created by Chris Blust on 5/18/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import Foundation

class Challenge {
    var name: String?
    var author: String?
    var instructions: String?
    var datePosted: String?
    var likers: [String]?
    var rechallengers: [String]?
    var feedType: String?
    var poster: String?
    
    init(name: String, author: String, instructions: String, datePosted: String, likers: [String], rechallengers: [String], feedType: String, poster: String){
        self.name = name
        self.author = author
        self.instructions = instructions
        self.datePosted = datePosted
        self.likers = likers
        self.rechallengers = rechallengers
        self.feedType = feedType
        self.poster = poster
    }
}
