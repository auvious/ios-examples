//
//  ChatOptions.swift
//  GenesysCloudSimpleConference
//
//  Created by Epimenidis Voutsakis on 2/2/21.
//

import SwiftUI
import os

struct OptionsView: View {
    @State var targetType = Options.get("targetType")!
    @State var targetAddress = Options.get("targetAddress")!

    @State var displayName = Options.get("displayName")!
    @State var firstName = Options.get("firstName")!
    @State var lastName = Options.get("lastName")!
    @State var email = Options.get("email")!
    @State var phoneNumber = Options.get("phoneNumber")!
    @State var avatarImageUrl = Options.get("avatarImageUrl")!

    @State var pcEnvironment = Options.get("pcEnvironment")!
    @State var organizationId = Options.get("organizationId")!
    @State var deploymentId = Options.get("deploymentId")!

    var body: some View {
        VStack {
        Form {
            Section {
                HStack {
                    Text("targetType: ")
                    TextField("targetType", text: $targetType)
                }
                HStack {
                    Text("targetAddress: ")
                    TextField("targetAddress", text: $targetAddress)
                }
            }

            Section {
                HStack {
                    Text("displayName: ")
                    TextField("displayName", text: $displayName)
                }
                HStack {
                    Text("firstName: ")
                    TextField("firstName", text: $firstName)
                }
                HStack {
                    Text("lastName: ")
                    TextField("lastName", text: $lastName)
                }
                HStack {
                    Text("email: ")
                    TextField("email", text: $email)
                }
                HStack {
                    Text("phoneNumber: ")
                    TextField("phoneNumber", text: $phoneNumber)
                }
                HStack {
                    Text("avatarImageUrl: ")
                    TextField("avatarImageUrl", text: $avatarImageUrl)
                }
            }

            Section {
                HStack {
                    Text("pcEnvironment: ")
                    TextField("pcEnvironment", text: $pcEnvironment)
                }
                HStack {
                    Text("organizationId: ")
                    TextField("organizationId", text: $organizationId)
                }
                HStack {
                    Text("deploymentId: ")
                    TextField("deploymentId", text: $deploymentId)
                }
            }
        }
        HStack {
            Button("Save", action: {
                os_log("saving options...")
                Options.set("targetType", targetType)
                Options.set("targetAddress", targetAddress)

                Options.set("displayName", displayName)
                Options.set("firstName", firstName)
                Options.set("lastName", lastName)
                Options.set("email", email)
                Options.set("phoneNumber", phoneNumber)
                Options.set("avatarImageUrl", avatarImageUrl)

                Options.set("pcEnvironment", pcEnvironment)
                Options.set("organizationId", organizationId)
                Options.set("deploymentId", deploymentId)
            })

            Button("Reset", action: {
                os_log("resetting options...")
                Options.reset()

                targetType = Options.get("targetType")!
                targetAddress = Options.get("targetAddress")!

                displayName = Options.get("displayName")!
                firstName = Options.get("firstName")!
                lastName = Options.get("lastName")!
                email = Options.get("email")!
                phoneNumber = Options.get("phoneNumber")!
                avatarImageUrl = Options.get("avatarImageUrl")!

                pcEnvironment = Options.get("pcEnvironment")!
                organizationId = Options.get("organizationId")!
                deploymentId = Options.get("deploymentId")!
            })
        }
        }
    }
}

struct ChatOptions_Previews: PreviewProvider {
    static var previews: some View {
        OptionsView()
    }
}
