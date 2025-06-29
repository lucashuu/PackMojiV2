//
//  PackMojiApp.swift
//  PackMoji
//
//  Created by Ziwei Mao on 6/19/25.
//

import SwiftUI

@main
struct PackMojiApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    HomeView()
                }
                .tabItem {
                    Label(String(localized: "tab_home"), systemImage: "house")
                }
                
                NavigationStack {
                    TemplatesView()
                }
                .tabItem {
                    Label(String(localized: "tab_templates"), systemImage: "list.bullet")
                }
            }
            .tint(.accentColor)
        }
    }
}
