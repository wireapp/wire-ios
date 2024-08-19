//
//  ViewController.swift
//  StatusWindow
//
//  Created by Christoph Aldrian on 19.08.24.
//

import UIKit

final class ViewController: UIViewController {

    var callStatusWindowPresenter: CallStatusWindowPresenter!

    var interfaceOrientations: UIInterfaceOrientationMask = .portrait

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        interfaceOrientations
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let delegate = SupportedOrientationsDelegatingNavigationControllerDelegate()
        delegate.setAsDelegateAndNontomicRetainedAssociatedObject(navigationController!)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard sender is UIButton, let viewController = segue.destination as? Self else { return }

        viewController.interfaceOrientations = .all
    }

    @IBAction func statusB(_ sender: UIButton) {

        callStatusWindowPresenter = callStatusWindowPresenter ?? .init(mainWindow: view.window!)

        if callStatusWindowPresenter.isHidden {
            callStatusWindowPresenter.show()
        } else {
            callStatusWindowPresenter.hide()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        setNeedsStatusBarAppearanceUpdate()
        //setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}

final class CallStatusWindowPresenter {

    let mainWindow: UIWindow

    private var statusWindow: UIWindow?

    var isHidden: Bool { statusWindow?.isHidden ?? true }

    init(mainWindow: UIWindow) {
        self.mainWindow = mainWindow
    }

    func show() {
        guard isHidden else { return }

        let labelViewController = LabelViewController(text: "Connecting")
        statusWindow = .init(windowScene: mainWindow.windowScene!)
        statusWindow?.rootViewController = labelViewController
        statusWindow?.windowLevel = mainWindow.windowLevel + 1
        //statusWindow?.isOpaque = false
        statusWindow?.frame = .init(
            origin: .zero,
            size: .init(
                width: mainWindow.windowScene!.screen.bounds.width,
                height: .zero
            )
        )

        print("mainWindow.windowScene!.statusBarManager!.statusBarFrame", mainWindow.windowScene!.statusBarManager!.statusBarFrame)

        statusWindow?.isHidden = false
        //statusWindow?.makeKeyAndVisible()

        mainWindow.setNeedsUpdateConstraints()
        mainWindow.setNeedsLayout()

        UIView.animate(withDuration: 0.5) { [self] in
            statusWindow?.frame.size.height = mainWindow.windowScene!.statusBarManager!.statusBarFrame.height + 30
            mainWindow.frame.origin.y += statusWindow!.frame.height - mainWindow.windowScene!.statusBarManager!.statusBarFrame.height
            mainWindow.frame.size.height = mainWindow.windowScene!.screen.bounds.height - statusWindow!.frame.height + mainWindow.windowScene!.statusBarManager!.statusBarFrame.height
            mainWindow.layoutIfNeeded()
            mainWindow.updateConstraintsIfNeeded()
            //mainWindow.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            //statusWindow!.rootViewController?.setNeedsStatusBarAppearanceUpdate()
        } completion: { isCompleted in
            labelViewController.isLabelHidden = false
        }
    }

    func hide() {
        guard !isHidden else { return }

        mainWindow.setNeedsUpdateConstraints()
        mainWindow.setNeedsLayout()

        let labelViewController = statusWindow!.rootViewController as! LabelViewController
        labelViewController.isLabelHidden = true

        // self.statusWindow?.isHidden = true
        //mainWindow.rootViewController?.setNeedsStatusBarAppearanceUpdate()
        //statusWindow!.rootViewController?.setNeedsStatusBarAppearanceUpdate()

        UIView.animate(withDuration: 0.5) { [self] in
            statusWindow!.frame.size.height = 0
            mainWindow.frame = mainWindow.windowScene!.screen.bounds
            mainWindow.layoutIfNeeded()
            mainWindow.updateConstraintsIfNeeded()
        } completion: { [self] isCompleted in
            self.statusWindow?.isHidden = true
            self.statusWindow = nil
        }
    }

    final class LabelViewController: UIViewController {

        var text: String {
            get { label.text ?? "" }
            set { label.text = newValue }
        }

        var isLabelHidden: Bool {
            get { label.isHidden }
            set { label.isHidden = newValue }
        }

        private let label = UILabel()

        //override var shouldAutorotate: Bool { false }
        //override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        //    [.portrait]
        //}

        init(text: String) {
            label.text = text
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) is not supported")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            view.backgroundColor = .green

            label.isHidden = true
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor),

                label.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: view.leadingAnchor, multiplier: 1),
                label.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: view.topAnchor, multiplier: 1),
                view.trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: label.trailingAnchor, multiplier: 1),
                view.bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: label.bottomAnchor, multiplier: 1)
            ])
        }

        override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)

            print("LabelViewController.viewWillTransition")
            //view.window?.alpha = 0

            coordinator.animate { context in
                //self.view.window?.frame =
                let windowScene = UIApplication.shared.connectedScenes.first as! UIWindowScene
                windowScene.keyWindow?.frame = windowScene.screen.bounds
            } completion: { context in
                //
            }
        }
    }
}
