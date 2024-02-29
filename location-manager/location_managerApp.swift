//
//  location_managerApp.swift
//  location-manager
//
//  Created by Robert Brennan on 2/28/24.
//

import SwiftUI

@main
struct location_managerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
