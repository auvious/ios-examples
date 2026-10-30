//
//  MainView.swift
//  SimpleConference
//
//  Created by Epimenidis Voutsakis on 27/1/21.
//

import SwiftUI

/// Hosts the UIKit conference demo (`ViewController`) inside a navigation controller, which the
/// call and the co-browse sample screens use to push and pop.
struct MainView: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UINavigationController {
        return UINavigationController(rootViewController: ViewController())
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // nothing to do here
    }
}
