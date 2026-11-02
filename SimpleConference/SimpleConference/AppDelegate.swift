//
//  AppDelegate.swift
//  SimpleConference
//
//  Created by Michael Korkaris on 10/12/24.
//

import UIKit
import Sentry
import AuviousSDK

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        //Prevent device locking
        UIApplication.shared.isIdleTimerDisabled = true

        SentrySDK.start { options in
            options.dsn = "https://74765e10688d4f828efd5bc5320c607c@sentry.auvious.com/9"
            options.debug = false
            options.environment = "staging"
            #if DEBUG
            // Xcode re-runs kill the app without a version change, which Sentry reports as a watchdog termination
            options.enableWatchdogTerminationTracking = false
            #endif
        }

        return true
    }

    // MARK: Orientation

    //Co-browse holds the app in portrait; otherwise the orientations in Info.plist
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        let appOrientations: UIInterfaceOrientationMask = UIDevice.current.userInterfaceIdiom == .pad ? .all : .allButUpsideDown
        return AuviousCobrowse.shared.supportedInterfaceOrientations(otherwise: appOrientations)
    }
}
