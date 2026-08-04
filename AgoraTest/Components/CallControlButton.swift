//
//  CallControlButton.swift
//  AgoraTest
//
//  Created by MOKSHA on 03/08/26.
//

import SwiftUI

struct CallControlButton: View {

    let title: String
    let systemImage: String
    let style: Style
    let isDisabled: Bool
    let action: () -> Void

    enum Style {
        case normal
        case active
        case destructive
    }

    init(
        title: String,
        systemImage: String,
        style: Style = .normal,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 68, height: 68)

                    Image(systemName: systemImage)
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
    }

    private var backgroundColor: Color {
        switch style {
        case .normal:
            return Color.secondary.opacity(0.14)

        case .active:
            return Color.orange.opacity(0.2)

        case .destructive:
            return .red
        }
    }

    private var iconColor: Color {
        switch style {
        case .normal:
            return .primary

        case .active:
            return .orange

        case .destructive:
            return .white
        }
    }
}

#Preview {
    HStack(spacing: 28) {
        CallControlButton(
            title: "Mute",
            systemImage: "mic.fill"
        ) {}

        CallControlButton(
            title: "Unmute",
            systemImage: "mic.slash.fill",
            style: .active
        ) {}

        CallControlButton(
            title: "End",
            systemImage: "phone.down.fill",
            style: .destructive
        ) {}
    }
    .padding()
}
