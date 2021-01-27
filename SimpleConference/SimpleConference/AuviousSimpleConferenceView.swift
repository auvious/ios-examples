//
//  AuviousSimpleConferenceView.swift
//  SimpleConference
//
//  Created by Epimenidis Voutsakis on 27/1/21.
//

import SwiftUI
import AuviousSDK

struct AuviousSimpleConferenceView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var ticket: String
    
    func makeUIViewController(context: Context) -> AuviousConferenceVCNew {
        checkPermissions()
        
        let clientId: String = "customer"
        let baseEndpoint: String = "https://genesys.dev.auvious.com/"
        let mqttEndpoint: String = "wss://events.genesys.dev.auvious.com/ws"
        let params: [String: String] = ["username" : ticket, "password": "something",  "grant_type" : "password"]
        let vc = AuviousConferenceVCNew(clientId: clientId, params: params, baseEndpoint: baseEndpoint, mqttEndpoint: mqttEndpoint, delegate: context.coordinator)
                
        return vc
    }
    
    func updateUIViewController(_ uiViewController: AuviousConferenceVCNew, context: Context) {
        // nothing to do here
    }
    
    //Request for camera/mic permissions if needed
    private func checkPermissions() {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraAuthorizationStatus != .authorized {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { accessGranted in
                guard accessGranted == true else {
                    self.checkPermissions()
                    return
                }
            })
        }
        
        let micPermission = AVAudioSession.sharedInstance().recordPermission
        if micPermission != .granted {
            AVAudioSession.sharedInstance().requestRecordPermission({ accessGranted in
                guard accessGranted == true else {
                    self.checkPermissions()
                    return
                }
            })
        }
    }
    
    class Coordinator: NSObject, AuviousSimpleConferenceDelegate, UINavigationControllerDelegate {
        var parent: AuviousSimpleConferenceView;
        
        init(_ parent: AuviousSimpleConferenceView) {
            self.parent = parent
        }
        
        func onConferenceError(_ error: AuviousSDKGenericError) {
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func onConferenceSuccess() {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
