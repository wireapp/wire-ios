import UIKit

final class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let delegate = SupportedOrientationsDelegatingNavigationControllerDelegate()
        delegate.setAsDelegateAndNontomicRetainedAssociatedObject(navigationController!)
    }

    @IBAction func offset(_ sender: UIButton) {

        splitViewController?.view.frame.size.height -= 20
        splitViewController?.view.frame.origin.y += 20
        print(splitViewController?.view.frame)
    }

    @IBAction func secondaryIfPrimary(_ sender: UIButton) {

        guard self === splitViewController?.viewController(for: .primary) else { return }

        let vc = storyboard!.instantiateViewController(identifier: "ViewController")
        splitViewController!.showDetailViewController(vc, sender: sender)
    }
}
