//
//  Acceptance.swift
//  Challenger
//
//  Created by Chris Blust on 5/29/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import Foundation
import SwiftyJSON
class Acceptance {
    var username: String!
    var likers: [String]!
    init(_ json: JSON){
        username = json["username"].stringValue
        likers = [String]()
        print(json)
        for index in 0..<json["likers"].arrayValue.count{
            likers.append(json["likers"].arrayValue[index].stringValue)
        }
    }
}
