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

struct MainView: View {
    @State private var ticket: String = ""
    @State private var showingAuviousSimpleConferenceView: Bool = false
    @State private var showingAlert = false
    @State private var error: Error?

    private var disposeBag = DisposeBag()
    
    var body: some View {
        VStack {
            Text("SimpleConference")
                .font(.title)
            
            Text("Would you like some help? Click on the button below to start a video call")
                .frame(width: 300, height: 100)
            
            TextField("ticket", text: $ticket)
                .frame(width: 100, height: 20)
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke())
            Button("VideoCall", action: {
                PermissionsManager.checkAVPermission(AVMediaType.audio)
                    .andThen(PermissionsManager.checkAVPermission(AVMediaType.video))
                    .subscribe {
                        os_log("all permissions granted")
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
            .frame(width: 100, height: 33)
            .padding(4)
            .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke())
        }
        .fullScreenCover(isPresented: $showingAuviousSimpleConferenceView, onDismiss: showAlertFunction) {
            AuviousSimpleConferenceView(ticket: self.$ticket, error: self.$error)
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
