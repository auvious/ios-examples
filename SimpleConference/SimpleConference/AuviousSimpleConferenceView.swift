//
//  AuviousSimpleConferenceView.swift
//  SimpleConference
//
//  Created by Epimenidis Voutsakis on 27/1/21.
//

import SwiftUI
import AuviousSDK

// Container view controller that hosts AuviousConferenceVCNew as a child VC.
// Using addChild() gives the conference view a constraint-free superview,
// which is required for the SDK's PiP frame manipulation to work correctly.
class ConferenceContainerViewController: UIViewController {
    var conferenceVC: AuviousConferenceVCNew?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let vc = conferenceVC, vc.parent == nil else { return }

        addChild(vc)
        let screenBounds = view.bounds
        vc.view.frame = CGRect(x: 0, y: screenBounds.height, width: screenBounds.width, height: screenBounds.height)
        view.addSubview(vc.view)
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            vc.view.frame = screenBounds
        }, completion: { _ in
            vc.didMove(toParent: self)
        })
    }

    func dismissConferenceVC() {
        guard let vc = conferenceVC, vc.parent == self else { return }
        let screenBounds = view.bounds
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn], animations: {
            vc.view.frame.origin.y = screenBounds.height
        }, completion: { _ in
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        })
    }
}

struct AuviousSimpleConferenceView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var ticket: String
    @Binding var callMode: AuviousCallMode
    @Binding var cameraAvailable: Bool
    @Binding var microphoneAvailable: Bool
    @Binding var speakerAvailable: Bool
    @Binding var customBackground: Bool
    @Binding var speakerEnabled: Bool
    @Binding var pipEnabled: Bool
    @Binding var screenShareEnabled: Bool
    @Binding var backgroundAudioEnabled: Bool
    @Binding var environment: String

    @Binding var error: Error?

    func makeUIViewController(context: Context) -> ConferenceContainerViewController {
        let clientId: String = "customer"
        let baseEndpoint: String = "https://"+environment+"/"
        let mqttEndpoint: String = environment

        var conf = AuviousConferenceConfiguration()
        conf.username = ticket
        conf.password = "b"
        conf.grantType = "password"
        conf.clientId = clientId
        conf.baseEndpoint = baseEndpoint
        conf.mqttEndpoint = mqttEndpoint
        conf.conferenceBackgroundColor = customBackground ? .blue : .black
        conf.enableSpeaker = speakerEnabled
        conf.callMode = callMode
        conf.cameraAvailable = cameraAvailable
        conf.microphoneAvailable = microphoneAvailable
        conf.speakerAvailable = speakerAvailable
        conf.pipAvailable = pipEnabled
        conf.screenSharingAvailable = screenShareEnabled
        conf.backgroundAudioEnabled = backgroundAudioEnabled

        let container = ConferenceContainerViewController()
        container.conferenceVC = AuviousConferenceVCNew(configuration: conf, delegate: context.coordinator)
        return container
    }

    func updateUIViewController(_ uiViewController: ConferenceContainerViewController, context: Context) {
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
