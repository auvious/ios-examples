//
//  Options.swift
//  GenesysCloudSimpleConference
//
//  Created by Epimenidis Voutsakis on 2/2/21.
//
import SwiftUI

class Options {
    private static let defaults = UserDefaults.standard

    private static let defaultOptions = [
        "pcEnvironment": "mypurecloud.de",
        "organizationId": "6e6d5224-1909-48fa-a982-66cef3fa4c08",
        "deploymentId": "6820a6a6-3755-4152-8d3f-53e7e8d2bedc",
        "targetType": "queue",
        "targetAddress": "AppFoundry",
        "displayName": "Bender Bending Rodriguez",
        "avatarImageUrl": "https://upload.wikimedia.org/wikipedia/en/a/a6/Bender_Rodriguez.png",
        "firstName": "Bender",
        "lastName": "Rodriguez",
        "email": "bender.bending.rodriguez@example.com",
        "phoneNumber" : "+66 666666"
    ]

    static func get(_ key: String) -> String? {
        return defaults.string(forKey: key) ?? defaultOptions[key]
    }

    static func set(_ key: String, _ value: String) {
        defaults.setValue(value, forKey: key)
    }

    static func reset() {
        defaultOptions.forEach { (key, value) in
            defaults.setValue(value, forKey: key)
        }
    }
}
