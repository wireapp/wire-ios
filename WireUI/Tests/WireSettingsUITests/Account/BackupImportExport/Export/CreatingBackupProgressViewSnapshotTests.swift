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

import XCTest
import SwiftUI
import WireTestingPackage

@testable import WireSettingsUI

@MainActor
final class CreatingBackupProgressViewSnapshotTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper!

    override func setUp() async throws {
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() async throws {
        snapshotHelper = nil
        UIView.setAnimationsEnabled(true)
    }

    func testOngoingColorSchemeVariants() async throws {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }

//        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        //let window = try XCTUnwrap(windowScene.keyWindow)

        let rootView = CreatingBackupProgressPreview(.ongoing(0.25))
//        let hostingController = UIHostingController(rootView: rootView)
        let hostingController = UIHostingController(rootView: S())
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()

        try! await Task.sleep(for: .milliseconds(4000))

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: renderedImage(hostingController.view), named: "light")

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: renderedImage(hostingController.view), named: "dark")

        window.isHidden = true
    }

    struct S: View {
        @State private var isSheetPresented = false
        var body: some View {
            Color.white
                .sheet(isPresented: $isSheetPresented) {
                    CreatingBackupProgressView(progress: .ongoing(0.25)) {}
                        .presentationDetents([.medium])
                        .interactiveDismissDisabled()
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        isSheetPresented = true
                    }
                }
        }
    }

    func testFinishedColorSchemeVariants() {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }

        let rootView = CreatingBackupProgressPreview(.ongoing(0.25))
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.frame = UIScreen.main.bounds

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: hostingController, named: "light")
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: hostingController, named: "dark")
    }

    //    @MainActor
    //    func testDynamicTypeVariants() {
    //        let screenBounds = UIScreen.main.bounds
    //
    //        let view = AuthenticationIdentityInputPreview()
    //            .frame(width: screenBounds.width)
    //
    //        for dynamicTypeSize in DynamicTypeSize.allCases {
    //            snapshotHelper
    //                .verify(
    //                    matching: view.dynamicTypeSize(dynamicTypeSize),
    //                    named: "\(dynamicTypeSize)"
    //                )
    //        }
    //    }


    /// Without this helper the layout around the navigation item's search bar breaks when rendering the snapshot.
    private func renderedImage(_ view: UIView) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        return renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
    }

}
