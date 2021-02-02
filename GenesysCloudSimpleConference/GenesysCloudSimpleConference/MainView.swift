//
//  ContentView.swift
//  GenesysCloudSimpleConference
//
//  Created by Epimenidis Voutsakis on 29/1/21.
//

import SwiftUI
import os
import RxSwift
import AVFoundation

struct MainView: View {
    private static let INITIAL_PROGRESS_STATUS = "offline"
    private static let INITIAL_PROGRESS = 0.0

    @State private var showingError = false
    @State private var showingProgress = false
    @State private var showingAuviousSimpleConferenceView = false
    @State private var showingOptions = false

    @State private var error: Error?
    @State private var progressStatus: String = INITIAL_PROGRESS_STATUS
    @State private var progress: Double = INITIAL_PROGRESS
    @State private var ticket: String = ""
    @State private var videoCallDisabled = false
    @State private var disposable: Disposable?
    @State private var chat: GenesysCloudGuestChatTicketProvider?

    var body: some View {
        NavigationView {
            VStack {
                Text("GenesysCloud")
                    .font(.title)
                Text("SimpleConference")
                    .font(.title)

                Text("Would you like some help? Click on the button below to start a video call")
                    .frame(width: 300, height: 100)
                    .padding()

                Button("VideoCall", action: {
                    self.videoCallDisabled = true
                    self.updateProgress("checking permissions", 0.0)
                    self.disposable = PermissionsManager.checkAVPermission(AVMediaType.audio)
                        .andThen(PermissionsManager.checkAVPermission(AVMediaType.video))
                        .do(onCompleted: {
                            os_log("all permissions granted")
                            self.updateProgress("permissions granted", 0.1)
                        })
                        .andThen(GenesysCloudGuestChatTicketProvider.create(MyTicketProgressDelegate(self)))
                        .subscribe (onSuccess: { chat in
                            os_log("chat created")
                            self.chat = chat
                            chat.connect()
                        }, onFailure: { (error) in
                            os_log("error while trying to get permissions and chat for ticket: \(error.localizedDescription)")
                            self.reset()
                            self.showError(error)
                        }, onDisposed: {
                            os_log("permissions/ticket completable disposed")
                        })
                })
                .disabled(self.videoCallDisabled)
                .frame(width: 100, height: 33)
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke())

                VStack {
                    Text("\(progressStatus)")
                        .padding()
                    ProgressView(value: progress)
                        .padding()
                    Button("Cancel") {
                        self.reset()
                    }
                }
                .opacity(self.showingProgress ? 1 : 0)

                Text("\(error?.localizedDescription ?? "unknown")")
                    .padding()
                    .opacity(self.showingError ? 1 : 0)

                NavigationLink(destination: OptionsView()) { Text("Options") }
                    .disabled(videoCallDisabled)
            }
            .fullScreenCover(isPresented: $showingAuviousSimpleConferenceView, onDismiss: self.onVideoCallDismiss) {
                AuviousSimpleConferenceView(ticket: self.$ticket, error: self.$error)
            }
        }
    }

    func onVideoCallDismiss() {
        self.reset()
        self.showError()
    }

    func reset() {
        self.showingProgress = false
        self.progressStatus = MainView.INITIAL_PROGRESS_STATUS
        self.progress = MainView.INITIAL_PROGRESS
        self.videoCallDisabled = false
        self.disposable?.dispose()
        self.disposable = nil
        self.chat?.disconnect()
        self.chat = nil
    }

    func showError() {
        self.showError(nil)
    }

    func showError(_ error: Error? = nil) {
        if (error != nil) {
            self.error = error
        }

        self.showingError = self.error != nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.showingError = false
            self.error = nil
        }
    }

    func updateProgress(_ status: String, _ progress: Double) {
        self.progressStatus = status;
        self.progress = progress
        self.showingProgress = true
    }

    class MyTicketProgressDelegate: TicketProgressDelegate {
        private static let INITIAL_NOTICE = "This is a video call request from the Auvious Video Counselor Widget. Open Auvious and start a video call. The customer will join once you join the call."

        let parent: MainView

        init(_ parent: MainView) {
            self.parent = parent
        }

        func onSocketConnected() {
            os_log("socket connected")
            parent.updateProgress("socket connected", 0.25)
        }

        func onQueued() {
            os_log("on queue")
            parent.updateProgress("video call queued", 0.5)
        }

        func onAgentConnected() -> String {
            os_log("agent connected")
            parent.updateProgress("agent connected", 0.75)
            return MyTicketProgressDelegate.INITIAL_NOTICE
        }

        func onTicket(_ ticket: String) {
            os_log("got ticket from guest chat: \(ticket)")
            parent.updateProgress("received ticket", 1.0)
            parent.ticket = ticket
            parent.showingAuviousSimpleConferenceView = true
        }

        func onError(_ error: Error) {
            os_log("Error while trying to get ticket: \(error.localizedDescription)")
            parent.reset()
            parent.showError(error)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
