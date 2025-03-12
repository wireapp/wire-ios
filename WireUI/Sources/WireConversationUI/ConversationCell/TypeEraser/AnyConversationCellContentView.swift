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

//struct AnyConversationCellContentView: ConversationCellContentViewProtocol {
//
//
//}
/*
struct AnyConversationCellContentView: ConversationCellContentViewProtocol {

    let model: Model
    let _body: () -> any View

    var body: some View {
        //Model.ContentView(model: model)
        _body()
    }

    init<Model: ConversationCellModelProtocol>(model: Model) {
        _body = {
            model.buildView()
        }
    }

}
 */

/*
#Preview("TimeDivider") {
    let model = TimeDividerModel(text: "Date/Time")
    AnyConversationCellContentView(
        model: AnyConversationCellModel(model)
    )
}
 */

@MainActor
public func testtt0() -> UIViewController {
    let model = TimeDividerModel(text: "Date/Time")
    return UIHostingController(rootView: AnyConversationCellModel(model).buildView())
}

@MainActor
public func testtt1() -> UIViewController {
    ConversationCellPreviews(
        models: [
            .guestsAllowed,
            .timeDivider(text: "Friday"),
            .timeDivider(text: "Saturday"),
            .timeDivider(text: "Sunday")
        ]
    )
}
