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

//struct DeveloperDebugActionsView: View {
//
//    @ObservedObject var viewModel: DeveloperDebugActionsViewModel
//
//    var body: some View {
//        List(viewModel.buttons) { button in
//            Button(action: button.action) {
//                Text(button.title)
//            }
//        }
//    }
//}

struct DeveloperDebugActionsView: View {

    @ObservedObject var viewModel: DeveloperDebugActionsViewModel
    @State private var showSheet: Bool = false // State to track the sheet presentation

    var body: some View {
        Button("Show Small Sheet") {
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            SmallSheetView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(true) 
        }
    }
}

struct SmallSheetView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("This is a small sheet!")
                .font(.title2)
                .bold()
            Text("Using a custom detent to make the sheet small.")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
    }
}

// MARK: - Previews

#Preview {
    DeveloperDebugActionsView(viewModel: DeveloperDebugActionsViewModel(selfClient: nil))
}
