//
//  AppDelegate.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 6/11/21.
//

import UIKit
import AVFoundation
import BlackBox

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        /// Prevent audio interruptions.
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
         } catch {
             Logger.general.error("Failed to set audio category!")
             assert(false)
         }
        
        /// Make opaque so that custom refresh controller doesn't show through.
        setOpaqueNavbar()
        
        #if DEBUG
//        loadAppData()
        #endif
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

/**
    Though setting global styles is bad practice, it's the only way this worked.
    Source: https://nemecek.be/blog/126/how-to-disable-automatic-transparent-navbar-in-ios-15
    Source: https://developer.apple.com/forums/thread/682420
 */
@MainActor /// UI code.
func setOpaqueNavbar() -> Void {
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = .secondarySystemBackground
    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
}

