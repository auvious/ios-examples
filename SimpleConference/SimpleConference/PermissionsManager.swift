//
//  PermissionsManager.swift
//  SimpleConference
//
//  Created by Epimenidis Voutsakis on 28/1/21.
//

import AVFoundation
import RxSwift

struct AVPermissionError: LocalizedError {
    let kind: AVMediaType

    var errorDescription: String? {
        get { "User denied permission for \(kind == .video ? "camera" : "microphone"))" }
    }
}

class PermissionsManager {
    static func checkAVPermission(_ kind: AVMediaType) -> Completable {
        return Completable.create { completable in
            let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            if cameraAuthorizationStatus != .authorized {
                AVCaptureDevice.requestAccess(for: kind, completionHandler: { success in
                    guard success == true else {
                        completable(.error(AVPermissionError(kind: kind)))
                        return
                    }
                    completable(.completed)
                })
            } else {
                completable(.completed)
            }

            return Disposables.create { }
        }
    }
}
