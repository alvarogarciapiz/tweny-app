//
//  twenyApp.swift
//  tweny
//
//  Created by Álvaro García Pizarro on 29/11/25.
//

import SwiftUI
import CoreData

@main
struct twenyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
