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

import Testing
import SwiftUI

struct Test {

    @MainActor
    @Test func testSomething() async throws {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        window.rootViewController = UIHostingController(rootView: Text(verbatim: "hello"))
        await Task.yield()

        let second = UIHostingController(rootView: Text(verbatim: "hi"))
//        second.modalPresentationStyle = .pageSheet
//        if let sheetPresentationController = second.sheetPresentationController {
//            sheetPresentationController.detents = [.medium()]
//        }
        window.rootViewController?.present(second, animated: false)


        print("sleeping")
        try await Task.sleep(for: .seconds(5))
        print("done")
    }

}
