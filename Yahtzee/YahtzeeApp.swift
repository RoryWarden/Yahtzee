//
//  YahtzeeApp.swift
//  Yahtzee
//
//  Created by Matthew Parker on 12/24/25.
//

import SwiftUI

@main
struct YahtzeeApp: App {
    var body: some Scene {
        WindowGroup {
            MainMenu()
        }
        .defaultSize(width: 950, height: 800)
        .windowResizability(.contentMinSize)
    }
}
