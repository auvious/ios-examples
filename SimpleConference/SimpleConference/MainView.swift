//
//  ContentView.swift
//  SimpleConference
//
//  Created by Epimenidis Voutsakis on 27/1/21.
//

import SwiftUI

struct MainView: View {
    @State private var ticket: String = ""
    @State private var showingAuviousSimpleConferenceView: Bool = false
    
    var body: some View {
        VStack {
            Text("Would you like some help? Click on the button below to start a video call")
            TextField("ticket", text: $ticket)
            Button("VideoCall", action: {
                self.showingAuviousSimpleConferenceView = true
            })
        }
        .fullScreenCover(isPresented: $showingAuviousSimpleConferenceView, onDismiss: {
            showingAuviousSimpleConferenceView = false
        }) {
            AuviousSimpleConferenceView(ticket: self.$ticket)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
