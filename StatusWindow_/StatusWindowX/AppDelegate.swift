//
//  AppDelegate.swift
//  StatusWindowX
//
//  Created by Christoph Aldrian on 19.08.24.
//

import UIKit
import Combine

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var cancellables = Set<AnyCancellable>()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {

            let rvc = UIApplication.shared.windows.first!.rootViewController!

            let view = UIView()
            view.backgroundColor = .green
            view.frame = UIApplication.shared.windows.first!.screen.bounds
            rvc.view.superview!.insertSubview(view, at: 0)
            rvc.view.publisher(for: \.frame).sink { frame in
                print("rvc.view.frame", rvc.view.frame)
                view.frame = view.window!.screen.bounds
            }.store(in: &self.cancellables)

            let label = UILabel()
            view.addSubview(label)
            label.text = "test"
            label.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
            label.frame = .init(x: 0, y: 0, width: 100, height: 30)
        }

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

extension AppDelegate: UINavigationControllerDelegate {

}
