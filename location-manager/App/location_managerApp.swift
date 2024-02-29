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
    @StateObject var viewModel: ViewModel
    
    init() {
        let context = persistenceController.container.viewContext
        _viewModel = StateObject(wrappedValue: ViewModel(context: context))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
