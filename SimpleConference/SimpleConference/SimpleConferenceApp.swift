//
//  SimpleConferenceApp.swift
//  SimpleConference
//
//  Created by Epimenidis Voutsakis on 27/1/21.
//

import SwiftUI
import AuviousSDK

@main
struct SimpleConferenceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainView()
                .ignoresSafeArea()
        }
        // With the scene life cycle the app-level callbacks of the AppDelegate are not called,
        // so the SDK pause/resume calls live here.
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                AuviousConferenceSDK.sharedInstance.onApplicationPause()
            case .active:
                AuviousConferenceSDK.sharedInstance.onApplicationResume()
            default:
                break
            }
        }
    }
}
