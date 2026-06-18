//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import SwiftUI
import WireDesign

/// A button used for in-call actions (mute, video, speaker, hang up).
struct CallActionButton: View {
    
    let systemImage: String
    let isSelected: Bool
    let isDestructive: Bool
    var isEnabled: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 56, height: 40)
                .background(
                    RoundedRectangle(cornerSize: CGSize(width: 100, height: 100))
                        .fill(backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerSize: CGSize(width: 100, height: 100))
                                .stroke(borderColor, lineWidth: 1)
                        )
                )
        }
        .disabled(!isEnabled)
    }
    
    private var backgroundColor: Color {
        if isDestructive {
            return Color(SemanticColors.Button.backgroundLikeHighlighted)
        }
        return isSelected
        ? Color(SemanticColors.Button.backgroundCallingSelected)
        : Color(SemanticColors.Button.backgroundCallingNormal)
    }
    
    private var iconColor: Color {
        if isDestructive {
            return Color(SemanticColors.View.backgroundDefaultWhite)
        }
        return isSelected
        ? Color(SemanticColors.Button.iconCallingSelected)
        : Color(SemanticColors.Button.iconCallingNormal)
    }
    
    private var borderColor: Color {
        if isDestructive { return .clear }
        return isSelected
        ? Color(SemanticColors.Button.borderCallingSelected)
        : Color(SemanticColors.Button.borderCallingNormal)
    }
}

// MARK: - Preview

#Preview("States") {
    VStack(spacing: 16) {
        HStack(spacing: 8) {
            CallActionButton(systemImage: "mic.slash.fill", isSelected: false, isDestructive: false) {}
            CallActionButton(systemImage: "mic.slash.fill", isSelected: true, isDestructive: false) {}
            CallActionButton(systemImage: "mic.slash.fill", isSelected: false, isDestructive: false, isEnabled: false) {}
        }
        HStack(spacing: 8) {
            CallActionButton(systemImage: "video.fill", isSelected: false, isDestructive: false) {}
            CallActionButton(systemImage: "video.fill", isSelected: true, isDestructive: false) {}
        }
        HStack(spacing: 8) {
            CallActionButton(systemImage: "phone.down.fill", isSelected: false, isDestructive: true) {}
        }
    }
    .padding()
    .background(Color(.systemGray6))
}
