//
//  HW4_2App.swift
//  HW4_2
//
//  Created by Anannya Patra on 08/04/24.
//

import SwiftUI

@main
struct HW4_2App: App {
    var navigationManager = NavigationManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(navigationManager)
        }
    }
}


//import SwiftUI
//
//@main
//struct HW4_2App: App {
//    init() {
//        // Sleep for 2 seconds to delay the app launch for development/testing purposes
//        sleep(2)
//    }
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}


