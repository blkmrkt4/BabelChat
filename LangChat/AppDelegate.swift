//
//  AppDelegate.swift
//  LangChat
//
//  Created by Robin Hutchinson on 2025-09-26.
//

import UIKit
import CoreData
import AVFoundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure audio session for text-to-speech pronunciation
        // This ensures AVSpeechSynthesizer works on physical devices
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,  // Enables speaker output for TTS
                mode: .default,
                options: [.duckOthers, .defaultToSpeaker]  // Duck music, play even when muted
            )
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            print("✅ Audio session configured for text-to-speech")
        } catch {
            print("❌ Failed to configure audio session: \(error.localizedDescription)")
        }

        // Configure RevenueCat for subscriptions
        configureRevenueCat()

        // Override point for customization after application launch.
        return true
    }

    // MARK: - RevenueCat Configuration
    private func configureRevenueCat() {
        // SECURITY: RevenueCat API key must be stored securely
        // Option 1: Use Xcode environment variable (Recommended)
        guard let revenueCatAPIKey = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"],
              !revenueCatAPIKey.isEmpty else {
            fatalError("""
                ❌ REVENUECAT_API_KEY not found!

                To fix this:
                1. In Xcode, go to Product > Scheme > Edit Scheme
                2. Select "Run" on the left
                3. Go to "Arguments" tab
                4. Under "Environment Variables", click +
                5. Add: REVENUECAT_API_KEY = your-api-key-here
                6. Get your key from: https://app.revenuecat.com
                """)
        }

        // Initialize subscription service
        SubscriptionService.shared.configure(apiKey: revenueCatAPIKey)

        print("💳 RevenueCat configured successfully")
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

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentCloudKitContainer(name: "LangChat")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

