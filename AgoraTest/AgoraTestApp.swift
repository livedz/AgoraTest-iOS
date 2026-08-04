//
//  AgoraTestApp.swift
//  AgoraTest
//
//  Created by MOKSHA on 03/08/26.
//

import SwiftUI

@main
struct AgoraTestApp: App {

    var body: some Scene {
        WindowGroup {
            AudioCallView(
                assistant: Assistant(
                    name: "Mio",
                    subtitle: "Voice Assistant",
                    image: nil
                )
            )
        }
    }
}
