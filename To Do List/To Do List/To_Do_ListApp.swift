//
//  To_Do_ListApp.swift
//  To Do List
//
//  Created by 李熙欣 on 2024/12/7.
//

import SwiftUI

@main
struct To_Do_ListApp: App {
    var body: some Scene {
        WindowGroup {
            ToDoListView()
                .onAppear {
                    debugAvailableFonts()
                }
        }
    }
    
    // Function to debug fonts
    func debugAvailableFonts() {
        for family in UIFont.familyNames {
            print("Family: \(family)")
            for font in UIFont.fontNames(forFamilyName: family) {
                print("    Font: \(font)")
            }
        }
    }
}
