//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import UIKit

// MARK: - TabBarControllerDelegate

protocol TabBarControllerDelegate: AnyObject {
    func tabBarController(_ controller: TabBarController, tabBarDidSelectIndex: Int)
}

extension UIPageViewController {
    var scrollView: UIScrollView? {
        view.subviews
            .lazy
            .compactMap { $0 as? UIScrollView }
            .first
    }
}

extension UIViewController {
    func takeFirstResponder() {
        if UIAccessibility.isVoiceOverRunning {
            return
        }
    }
}

// MARK: - TabBarController

final class TabBarController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource,
    UIScrollViewDelegate {
    weak var delegate: TabBarControllerDelegate?

    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

    private(set) var viewControllers: [UIViewController]
    private(set) var selectedIndex: Int

    var isInteractive = true {
        didSet {
            pageViewController.dataSource = isInteractive ? self : nil
            pageViewController.delegate = isInteractive ? self : nil
            tabBar?.animatesTransition = isInteractive
        }
    }

    var isTabBarHidden = false {
        didSet {
            tabBar?.isHidden = isTabBarHidden
            tabBarHeight?.isActive = isTabBarHidden
        }
    }

    var isEnabled = true {
        didSet {
            tabBar?.isUserInteractionEnabled = isEnabled
            isInteractive = isEnabled // Shouldn't be interactive when it's disabled
        }
    }

    // MARK: - Views

    private var tabBar: TabBar!
    private var contentView = UIView()
    private var isSwiping = false
    private var startOffset: CGFloat = 0
    private var tabBarHeight: NSLayoutConstraint!

    // MARK: - Initialization

    init(viewControllers: [UIViewController]) {
        self.viewControllers = viewControllers
        self.selectedIndex = 0
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        createViews()
        createConstraints()
        selectIndex(selectedIndex, animated: false)
    }

    fileprivate func createViews() {
        view.addSubview(contentView)
        contentView.backgroundColor = viewControllers.first?.view?.backgroundColor
        add(pageViewController, to: contentView)
        pageViewController.scrollView?.delegate = self

        if isInteractive {
            pageViewController.dataSource = self
            pageViewController.delegate = self
        }

        let items = viewControllers.map { $0.tabBarItem! }
        tabBar = TabBar(items: items, selectedIndex: selectedIndex)
        tabBar?.animatesTransition = isInteractive
        tabBar?.isHidden = isTabBarHidden
        tabBar?.delegate = self
        tabBar?.isUserInteractionEnabled = isEnabled && items.count > 1
        view.addSubview(tabBar!)
    }

    fileprivate func createConstraints() {
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false

        tabBarHeight = tabBar.heightAnchor.constraint(equalToConstant: 0)
        tabBarHeight?.isActive = isTabBarHidden

        pageViewController.view.fitIn(view: contentView)

        NSLayoutConstraint.activate([
            // tabBar
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.topAnchor.constraint(equalTo: view.topAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // contentView
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Interacting with the Tab Bar

    func selectIndex(_ index: Int, animated: Bool) {
        selectedIndex = index

        let toViewController = viewControllers[index]
        let fromViewController = pageViewController.viewControllers?.first

        guard toViewController != fromViewController else { return }

        let toIndex = viewControllers.firstIndex(of: toViewController) ?? 0
        let fromIndex = fromViewController.flatMap(viewControllers.firstIndex) ?? 0

        let forward = toIndex > fromIndex
        let direction = forward ? UIPageViewController.NavigationDirection.forward : .reverse

        pageViewController.setViewControllers([toViewController], direction: direction, animated: isInteractive) { [
            delegate,
            tabBar
        ] complete in
            guard complete else { return }
            tabBar?.setSelectedIndex(index, animated: animated)
            delegate?.tabBarController(self, tabBarDidSelectIndex: index)
        }
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        viewControllers.firstIndex(of: viewController).flatMap {
            let index = $0 + 1
            guard index >= 0, index < viewControllers.count else { return nil }
            return viewControllers[index]
        }
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        viewControllers.firstIndex(of: viewController).flatMap {
            let index = $0 - 1
            guard index >= 0, index < viewControllers.count else { return nil }
            return viewControllers[index]
        }
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard let selected = pageViewController.viewControllers?.first else { return }
        guard let index = viewControllers.firstIndex(of: selected) else { return }

        if completed {
            isSwiping = false
            delegate?.tabBarController(self, tabBarDidSelectIndex: index)
            selectedIndex = index
            tabBar?.setSelectedIndex(selectedIndex, animated: isInteractive)
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isSwiping = true
        startOffset = scrollView.contentOffset.x
    }

    func scrollViewDidEndDecelerating(_: UIScrollView) {
        isSwiping = false
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard isSwiping else { return }

        let startPosition = abs(startOffset - scrollView.contentOffset.x)
        let numberOfItems = CGFloat(viewControllers.count)
        let percent = (startPosition / view.frame.width) / numberOfItems

        // Percentage occupied by one page, e.g. 33% when we have 3 controllers.
        let increment = 1.0 / numberOfItems
        // Start percentage, for example 50% when starting to swipe from the last of 2 controllers.
        let startPercentage = increment * CGFloat(selectedIndex)

        // The adjusted percentage of the movement based on the scroll direction
        let adjustedPercent: CGFloat = if startOffset <= scrollView.contentOffset.x {
            startPercentage + percent // going right or not moving
        } else {
            startPercentage - percent // going left
        }

        tabBar?.setOffsetPercentage(adjustedPercent)
    }
}

// MARK: TabBarDelegate

extension TabBarController: TabBarDelegate {
    func tabBar(_ tabBar: TabBar, didSelectItemAt index: Int) {
        selectIndex(index, animated: tabBar.animatesTransition)
    }
}
