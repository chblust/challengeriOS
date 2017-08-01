//
//  AppDelegate.swift
//  Challenger
//
//  Created by Chris Blust on 5/15/17.
//  Copyright © 2017 ChallengerGroup. All rights reserved.
//

import UIKit
import GoogleMobileAds
import PusherSwift
import UserNotifications
import BRYXBanner
import AVKit
import AVFoundation
@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    let NOTIFICATION_COLOR = UIColor.magenta
        var window: UIWindow?
    var playerViewController: AVPlayerViewController!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // Initialize the Google Mobile Ads SDK.
        // Sample AdMob app ID: ca-app-pub-3940256099942544~1458002511
        registerForPushNotifications()
        application.registerForRemoteNotifications()
        GADMobileAds.configure(withApplicationID: "ca-app-pub-3940256099942544/6300978111")

        return true
    }
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Global.pusher.nativePusher.register(deviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if let aps = userInfo["aps"] as? [String: Any]{
            Global.global.addToNotificationBadge()
            let params = [
                "username": aps["sender"] as! String,
                "set" : "false"
            ]
            URLSession.shared.dataTask(with: Global.createServerRequest(params: params, intent: "image")){data, response, error in
                if let data = data{
                    if (String(data: data, encoding: .utf8) != "false"){
                        //set userImageView to userImage from server
                        OperationQueue.main.addOperation {
                            let image = UIImage(data: data)!
                            Global.global.userImages[aps["sender"] as! String] = image
                            self.displayNotification(aps, image, completionHandler)
                        }
                    }
                }
                }.resume()
        }
    }
    
    func displayNotification(_ aps: [String: Any], _ image: UIImage, _ completionHandler: @escaping (UIBackgroundFetchResult) -> Void){
            var banner: Banner!
        let notification = Notification(type: aps["type"] as! String!, sender: aps["sender"] as! String, challengeName: aps["challenge"] as! String, uuid: aps["uuid"] as! String)
            if let type = Notification.NotificationType(rawValue: notification.type){
                switch type{
                case .follow:
                    banner = Banner(title: "New Follower!", subtitle: "\(notification.sender!) started following you", image: image, backgroundColor: NOTIFICATION_COLOR, didTapBlock: {
                        notification.remove()
                        Global.global.currentViewController!.presentOtherUser(username: notification.sender!)
                    })
                    break
                case .acceptance:
                    banner = Banner(title: notification.getBody(), image: image, backgroundColor: NOTIFICATION_COLOR, didTapBlock: {
                        notification.remove()
                        
                        //the following brings up a stream of the user's uploaded video
                        let path = "\(Global.ip)/uploads/\(Global.getServerSafeName(notification.challengeName!))/\(notification.sender!)/4-medium/4-medium.m3u8"
                        
                        let url = URL(string: path)
                        let avasset = AVURLAsset(url: url!)
                        let item = AVPlayerItem(asset: avasset)
                        let player = AVPlayer(playerItem: item)
                        self.playerViewController = AVPlayerViewController()
                        self.playerViewController.player = player
                        
                        Global.global.currentViewController.present(self.playerViewController, animated: true){() -> Void in
                            self.playerViewController.player!.play()
                        }
                        
                        NotificationCenter.default.addObserver(self,
                                                               selector: #selector(self.playerDidFinish(_:)),
                                                               name: .AVPlayerItemDidPlayToEndTime,
                                                               object: player.currentItem)

                    })
                    break
                case .like:
                    banner = Banner(title: notification.getBody(), subtitle: "", image: image, backgroundColor: NOTIFICATION_COLOR, didTapBlock: {
                        notification.remove()
                        Global.global.currentViewController.presentChallenge(challengeName: notification.challengeName!)
                    })
                    break
                case .video_like:
                    banner = Banner(title: notification.getBody(), subtitle: "", image: image, backgroundColor: NOTIFICATION_COLOR, didTapBlock: {
                        notification.remove()
                        Global.global.currentViewController.presentChallenge(challengeName: notification.challengeName!)
                    })
                    break;
                case .rechallenge:
                    banner = Banner(title: notification.getBody(), image: image, backgroundColor: NOTIFICATION_COLOR, didTapBlock: {
                        notification.remove()
                        Global.global.currentViewController.presentOtherUser(username: notification.sender!)
                    })
                    break
                case .comment:
                    banner = Banner(title: notification.getBody(), subtitle: "", image: image, backgroundColor: NOTIFICATION_COLOR, didTapBlock: {
                        notification.remove()
                        Global.global.currentViewController.presentComment(uuid: notification.uuid!)
                    })
                    break
                case .comment_like:
                    banner = Banner(title: notification.getBody(), subtitle: "", image: image, backgroundColor: NOTIFICATION_COLOR, didTapBlock: {
                        notification.remove()
                        Global.global.currentViewController.presentComment(uuid: notification.uuid!)
                    })
                    break
                case .reply:
                    banner = Banner(title: notification.getBody(), subtitle: "", image: image, backgroundColor: NOTIFICATION_COLOR, didTapBlock: {
                        notification.remove()
                        Global.global.currentViewController.presentComment(uuid: notification.uuid!)
                    })
                }
                banner.show()
            }else{
                fatalError("Notification Type was set to invalid value")
            }
        
            completionHandler(.newData)
    }
    
    func playerDidFinish(_ player: AVPlayer){
        playerViewController.dismiss(animated: true, completion: {})
    }


    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {

    }
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            print("Permission granted: \(granted)")
            
            guard granted else { return }
            self.getNotificationSettings()
        }
    }
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

}

