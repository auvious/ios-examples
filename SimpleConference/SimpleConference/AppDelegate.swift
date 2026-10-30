//
//  AppDelegate.swift
//  SimpleConference
//
//  Created by Michael Korkaris on 10/12/24.
//

import UIKit
import Sentry

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        //Prevent device locking
        UIApplication.shared.isIdleTimerDisabled = true

        SentrySDK.start { options in
            options.dsn = "https://74765e10688d4f828efd5bc5320c607c@sentry.auvious.com/9"
            options.debug = false
            options.environment = "staging"
        }

        return true
    }
}
