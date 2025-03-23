//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

struct PreferredSizeKey: PreferenceKey {
    static var defaultValue: CGSize?

    static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
        let next = nextValue()
        print("🍒 reducer", value, next)
        
        if next != nil {
            value = next
        }
    }
}

struct PreferredSizeModifier: ViewModifier {
    @State var size: CGSize = .init(width: 390, height: 420)
    
    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .frame(width: size.width, height: size.height)
                .onPreferenceChange(PreferredSizeKey.self) { value in
                    DispatchQueue.main.async {
                        if let value {
                            self.size.height = value.height
                        }
                    }
                }
        } else {
            content
                .onPreferenceChange(PreferredSizeKey.self) { value in
                    DispatchQueue.main.async {
                        if let value {
                            self.size.height = value.height
                        }
                    }
                }
                .presentationDetents([.height(self.size.height)])
        }
    }
}

extension View {
    
    @ViewBuilder
    func setPreferredSize(navigationBarHidden: Bool = true) -> some View {
            self.background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: PreferredSizeKey.self,
                                    value: CGSize(width: proxy.size.width, height: navigationBarHidden ? proxy.size.height : proxy.size.height + 44))
                }
            )
    }
    
    @ViewBuilder
    func adjustiPadFrame() -> some View {
            self.modifier(PreferredSizeModifier())
    }
}
