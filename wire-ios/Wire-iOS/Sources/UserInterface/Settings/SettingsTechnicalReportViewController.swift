//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import MessageUI
import WireSystem
import WireCommonComponents

typealias TechnicalReport = [String: String]

final class SettingsTechnicalReportViewController: UITableViewController {
    private let includedVoiceLogCell: UITableViewCell
    private let sendReportCell: UITableViewCell

    init() {
        sendReportCell = UITableViewCell(style: .default, reuseIdentifier: nil)
        sendReportCell.backgroundColor = SemanticColors.View.backgroundUserCell
        sendReportCell.textLabel?.text = L10n.Localizable.Self.Settings.TechnicalReport.sendReport
        sendReportCell.textLabel?.textColor = UIColor.accent()
        sendReportCell.backgroundView = UIView()
        sendReportCell.selectedBackgroundView = UIView()

        includedVoiceLogCell = UITableViewCell(style: .default, reuseIdentifier: nil)
        includedVoiceLogCell.accessoryType = .checkmark
        includedVoiceLogCell.textLabel?.text = L10n.Localizable.Self.Settings.TechnicalReport.includeLog
        includedVoiceLogCell.textLabel?.textColor = SemanticColors.Label.textDefault
        includedVoiceLogCell.backgroundColor = SemanticColors.View.backgroundUserCell
        includedVoiceLogCell.backgroundView = UIView()
        includedVoiceLogCell.selectedBackgroundView = UIView()

        [sendReportCell, includedVoiceLogCell].forEach { cell in
            cell.addBorder(for: .bottom)
        }

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationTitle()
        tableView.backgroundColor = UIColor.clear
        tableView.isScrollEnabled = false
        tableView.separatorColor = UIColor(white: 1, alpha: 0.1)
    }

    func sendReport(sourceView: UIView? = nil) {
        presentMailComposer(withLogs: includedVoiceLogCell.accessoryType == .checkmark,
                            sourceView: sourceView)
    }

    private func setupNavigationTitle() {
        navigationItem.setupNavigationBarTitle(title: L10n.Localizable.Self.Settings.TechnicalReportSection.title.capitalized)
    }

    // MARK: - TableView Delegates

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return indexPath.row == 0 ? includedVoiceLogCell : sendReportCell
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = L10n.Localizable.Self.Settings.TechnicalReport.privacyWarning
        label.textColor = SemanticColors.Label.textSectionFooter
        label.backgroundColor = .clear
        label.font = FontSpec(.small, .light).font!

        let container = UIView()
        container.addSubview(label)
        container.layoutMargins = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        container.backgroundColor = .clear

        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([label.topAnchor.constraint(equalTo: container.layoutMarginsGuide.topAnchor),
                                     label.bottomAnchor.constraint(equalTo: container.layoutMarginsGuide.bottomAnchor),
                                     label.leadingAnchor.constraint(equalTo: container.layoutMarginsGuide.leadingAnchor),
                                     label.trailingAnchor.constraint(equalTo: container.layoutMarginsGuide.trailingAnchor)])
        return container
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            includedVoiceLogCell.accessoryType = includedVoiceLogCell.accessoryType == .none ? .checkmark : .none
        } else {
            let cell = tableView.cellForRow(at: indexPath)
            sendReport(sourceView: cell)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: Mail Delegate

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.presentingViewController?.dismiss(animated: true, completion: nil)
    }

}

protocol SendTechnicalReportPresenter: MFMailComposeViewControllerDelegate {
    func presentMailComposer(withLogs logsIncluded: Bool)
}


extension SettingsTechnicalReportViewController: SendTechnicalReportPresenter {}


extension SendTechnicalReportPresenter where Self: UIViewController {
    func presentMailComposer(withLogs logsIncluded: Bool) {
        presentMailComposer(withLogs: logsIncluded, sourceView: nil)
    }

    func presentMailComposer(withLogs logsIncluded: Bool, sourceView: UIView?, fallback: ((Bool) -> Void)? = nil) {
        let mailRecipient = WireEmail.shared.callingSupportEmail

        guard MFMailComposeViewController.canSendMail() else {
            DebugAlert.displayFallbackActivityController(logPaths: ZMSLog.pathsForExistingLogs, email: mailRecipient, from: self, sourceView: sourceView)
            return
        }

        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self
        mailComposeViewController.setToRecipients([mailRecipient])
        mailComposeViewController.setSubject(NSLocalizedString("self.settings.technical_report.mail.subject", comment: ""))

        if logsIncluded {
            mailComposeViewController.attachLogs()
        }
        mailComposeViewController.setMessageBody("Debug report", isHTML: false)
        self.present(mailComposeViewController, animated: true, completion: nil)
    }
}
