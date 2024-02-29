//
//  ContentView.swift
//  location-manager
//
//  Created by Robert Brennan on 2/28/24.
//

import SwiftUI
import CoreData

struct ContentView: View {

    var body: some View {
        NavigationStack {
            NavigationLink {
                LocationView()
            } label: {
                Text("Open LocationView()")
            }
            .padding()
        }
    }


}

//#Preview {
//    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//}
