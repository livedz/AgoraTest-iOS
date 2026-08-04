//
//  CallState.swift
//  AgoraTest
//
//  Created by MOKSHA on 03/08/26.
//

import Foundation
import SwiftUI

struct Assistant {
    let name: String
    let subtitle: String
    let image: Image?
}

enum CallState: Equatable {
    case idle
    case connecting
    case connected
    case reconnecting
    case ended

    var title: String {
        switch self {
        case .idle:
            return "Ready"

        case .connecting:
            return "Connecting…"

        case .connected:
            return "Connected"

        case .reconnecting:
            return "Reconnecting…"

        case .ended:
            return "Call ended"
        }
    }
}
