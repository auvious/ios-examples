//
//  ContentView.swift
//  SimpleConference
//
//  Created by Epimenidis Voutsakis on 27/1/21.
//

import SwiftUI
import os
import RxSwift
import AVFoundation
import AuviousSDK

struct MainView: View {
    @State private var ticket: String = ""
    @State private var showingAuviousSimpleConferenceView: Bool = false
    @State private var showingAlert = false
    @State private var error: Error?
    @State private var callMode: AuviousCallMode = .audioVideo
    @State private var isAudioOutputToSpeaker = true
    @State private var isCameraEnabled = true
    @State private var isMicrophoneEnabled = true
    @State private var isSpeakerEnabled = true
    @State private var isCustomBackground = false
    @State private var environment = "auvious.video"
    
    
    private var disposeBag = DisposeBag()
    
    
    var body: some View {
        VStack {
            Text("SimpleConference")
                .font(.title)
            
            Text("Click on the buttons below to start a call")
                .frame( height: 10)
            
            HStack {
                // Text Field
                TextField("ticket", text: $ticket)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(.leading)
                
                // Dismiss Button
                Button(action: {
                    hideKeyboard()
                }) {
                    Text("Dismiss")
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                }
            }
            .padding()
            
            TextField("environment", text: $environment)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true) 
                .padding(.leading)
            
            HStack {
                Button("Audio Call", action: {
                    PermissionsManager.checkAVPermission(AVMediaType.audio)
                        .subscribe {
                            os_log("audio permission granted")
                            self.callMode = .audio
                            self.showingAuviousSimpleConferenceView = true
                        } onError: { (error) in
                            os_log("permission not granted: \(error.localizedDescription)")
                            self.error = error
                            self.showAlertFunction()
                        } onDisposed: {
                            os_log("permissions completable disposed")
                        }
                        .disposed(by: disposeBag)
                })
//                .frame(width: 100)
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button ("Camera Call", action: {
                    PermissionsManager.checkAVPermission(AVMediaType.video)
                        .subscribe {
                            os_log("video permission granted")
                            self.callMode = .video
                            self.showingAuviousSimpleConferenceView = true
                        } onError: { (error) in
                            os_log("permission not granted: \(error.localizedDescription)")
                            self.error = error
                            self.showAlertFunction()
                        } onDisposed: {
                            os_log("permissions completable disposed")
                        }
                        .disposed(by: disposeBag)
                })
//                .frame(width: 100)
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("Video Call", action: {
                    PermissionsManager.checkAVPermission(AVMediaType.audio)
                        .andThen(PermissionsManager.checkAVPermission(AVMediaType.video))
                        .subscribe {
                            os_log("all permissions granted")
                            self.callMode = .audioVideo
                            self.showingAuviousSimpleConferenceView = true
                        } onError: { (error) in
                            os_log("permissions not granted: \(error.localizedDescription)")
                            self.error = error
                            self.showAlertFunction()
                        } onDisposed: {
                            os_log("permissions completable disposed")
                        }
                        .disposed(by: disposeBag)
                })
//                .frame(width: 100)
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }.padding()
            
            Toggle(isOn: $isAudioOutputToSpeaker) {
                Text("audio output to speaker")
                    .font(.body)
            }
            .padding(.vertical, 8)
            
            Text("Conference controls")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.vertical, 4)
                .padding(.leading, 4)
                .disabled(true) // To indicate it's not clickable
            
            VStack(spacing: 16) {
                Toggle(isOn: $isCameraEnabled) {
                    Text("camera")
                        .font(.body)
                }
                Toggle(isOn: $isMicrophoneEnabled) {
                    Text("microphone")
                        .font(.body)
                }
                Toggle(isOn: $isSpeakerEnabled) {
                    Text("speaker")
                        .font(.body)
                }
                Toggle(isOn: $isCustomBackground) {
                    Text("custom background")
                        .font(.body)
                }
            }
        }
        .padding()
        .toggleStyle(SwitchToggleStyle(tint: .green))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .fullScreenCover(isPresented: $showingAuviousSimpleConferenceView, onDismiss: showAlertFunction) {
            AuviousSimpleConferenceView(
                ticket: self.$ticket,
                callMode: self.$callMode,
                cameraAvailable: self.$isCameraEnabled,
                microphoneAvailable: self.$isMicrophoneEnabled,
                speakerAvailable: self.$isSpeakerEnabled,
                customBackground: self.$isCustomBackground,
                speakerEnabled: self.$isAudioOutputToSpeaker,
                environment: self.$environment,
                error: self.$error)
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text("\(error?.localizedDescription ?? "unknown")"))
        }
    }
    
    func showAlertFunction() {
        DispatchQueue.main.async {
            self.showingAlert = self.error != nil
        }
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

