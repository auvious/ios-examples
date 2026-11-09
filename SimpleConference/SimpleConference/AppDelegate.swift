//
//  AppDelegate.swift
//  SimpleConference
//
//  Created by Michael Korkaris on 10/12/24.
//

import UIKit
import AuviousSDK

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        //Prevent device locking
        UIApplication.shared.isIdleTimerDisabled = true

        //Sentry: crashes in the SDK go to Auvious by default. Your own project with .custom(dsn:), none with .disabled
        AuviousDiagnostics.errorReporting = .auvious
        //What is sent: .minimal (default) or .full
        AuviousDiagnostics.logLevel = .minimal
        //SDK console logs: .none, .error, .warning (default), .info or .debug
        AuviousDiagnostics.consoleLogLevel = .warning

        return true
    }

    // MARK: Orientation

    //Co-browse holds the app in portrait; otherwise the orientations in Info.plist
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        let appOrientations: UIInterfaceOrientationMask = UIDevice.current.userInterfaceIdiom == .pad ? .all : .allButUpsideDown
        return AuviousCobrowse.shared.supportedInterfaceOrientations(otherwise: appOrientations)
    }
}
