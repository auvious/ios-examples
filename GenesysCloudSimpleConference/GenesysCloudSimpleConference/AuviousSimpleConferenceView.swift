//
//  AuviousSimpleConferenceView.swift
//  GenesysCloudSimpleConference
//
//  Created by Epimenidis Voutsakis on 1/2/21.
//

import SwiftUI
import AuviousSDK

struct AuviousSimpleConferenceView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var ticket: String
    @Binding var error: Error?

    func makeUIViewController(context: Context) -> AuviousConferenceVCNew {
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

    class Coordinator: NSObject, AuviousSimpleConferenceDelegate, UINavigationControllerDelegate {
        var parent: AuviousSimpleConferenceView;

        init(_ parent: AuviousSimpleConferenceView) {
            self.parent = parent
        }

        func onConferenceError(_ error: AuviousSDKGenericError) {
            parent.error = error
            parent.presentationMode.wrappedValue.dismiss()
        }

        func onConferenceSuccess() {
            parent.error = nil
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}