//
//  Notification.swift
//  Challenger
//
//  Created by Chris Blust on 7/23/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import Foundation

class Notification: Equatable{
    static func ==(lhs: Notification, rhs: Notification) -> Bool {
        if lhs.sender == rhs.sender && lhs.type == rhs.type && lhs.challengeName == rhs.challengeName && lhs.uuid == rhs.uuid{
            return true
        }
        return false
    }

    enum NotificationType: String{
        case follow = "follow"
        case acceptance = "acceptance"
        case like = "like"
        case video_like = "vlike"
        case rechallenge = "rechallenge"
        case comment = "comment"
        case comment_like = "clike"
        case reply = "reply"
    }
    var type: String!
    var sender: String!
    var challengeName: String!
    var uuid: String!
    
    init(type: String, sender: String, challengeName: String, uuid: String){
        self.type = type
        self.sender = sender
        self.challengeName = challengeName
        self.uuid = uuid
    }
    
    func remove(){
        URLSession.shared.dataTask(with: Global.createServerRequest(params: [
            "type": "remove",
            "username": Global.global.loggedInUser.username!,
            "notificationType": self.type!,
            "sender": self.sender!,
            "challenge": self.challengeName!,
            "uuid": self.uuid!
            ], intent: "notifications")){data, response, error in
                if let message = String(data: data!, encoding: .utf8){
                    print(message)
                }
            }.resume()
        Global.global.subtractFromNotificationBadge()
    }
    
    func getBody() -> String{
        if let type = NotificationType(rawValue: self.type){
            switch type{
            case .follow:
                return "\(sender!) started following you!"
                
            case .acceptance:
                return "\(sender!) accepted your challenge: \(challengeName!)"
                
            case .like:
                return "\(sender!) liked your challenge: \(challengeName!)"
                
            case .video_like:
                return "\(sender!) liked your video you posted to \(challengeName!)"
                
            case .rechallenge:
                return "\(sender!) rechallenged your challenge: \(challengeName!)"
                
            case .comment:
                return "\(sender!) commented on your challenge: \(challengeName!)"
                
            case .comment_like:
                return "\(sender!) liked the comment you posted to \(challengeName!)"
                
            case .reply:
                return "\(sender!) replied to the comment you posted to \(challengeName!)"
            }
        }else{
            fatalError("Notification Type was set to invalid value")
        }
    }
}
