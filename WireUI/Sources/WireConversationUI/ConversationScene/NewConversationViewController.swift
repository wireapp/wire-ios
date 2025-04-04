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

public import UIKit

import CoreData

public protocol NewConversationModel: NSManagedObject {
    var visibleMessagesPredicate: NSPredicate? { get }
}

public protocol NewConversationMessageModel: NSManagedObject {
    var conversationCellModel: ConversationCellModel { get }
    var todo: SectionIdentifier { get }
}

//@objc
//public enum SectionIdentifier: Int, Sendable {
//    case intro
//    case messages
//}
public typealias SectionIdentifier = String

typealias ItemIdentifier = NSManagedObjectID // ConversationCellModel

public final class NewConversationViewController<
    ConversationModel: NewConversationModel,
    ConversationMessageModel: NewConversationMessageModel
>: UITableViewController, NSFetchedResultsControllerDelegate {

    let itemIdentifiers = [ItemIdentifier]()

    /// don't use
    public let conversationModel: ConversationModel!


    private let persistentContainer: NSPersistentContainer
    private let conversationObjectID: NSManagedObjectID
    private let backButtonAction: () -> Void

    private var fetchedResultsController: NSFetchedResultsController<ConversationMessageModel>!
    private var dataSource: UITableViewDiffableDataSource<SectionIdentifier, ItemIdentifier>!

    public init(
        conversationModel: ConversationModel,
        conversationMessageType _: ConversationMessageModel.Type,
        persistentContainer: NSPersistentContainer,
        backButtonAction: @escaping () -> Void
    ) {
        self.conversationModel = conversationModel
        self.persistentContainer = persistentContainer
        self.backButtonAction = backButtonAction
        conversationObjectID = conversationModel.objectID

        super.init(style: .plain)

        navigationItem.backBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.backward"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped(_:))
        )
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        initializeFetchedResultsController()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

//        if let sections = fetchedResultsController.sections, !sections.isEmpty {
//            let lastSection = sections.count - 1
//            let lastRow = sections[lastSection].numberOfObjects - 1
//            let indexPath = IndexPath(row: lastRow, section: lastSection)
//            DispatchQueue.main.async {
//                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
//            }
//        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.backward"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped(_:))
        )
    }

    @objc private func backButtonTapped(_ barButtonItem: UIBarButtonItem) {
        backButtonAction()
    }

    private func setupTableView() {
        registerCellTypes()
        setupDataSource()
        tableView.separatorStyle = .none
    }

    private func registerCellTypes() {
        ConversationCellModel.timeDivider(.init()).registerIfNeeded(in: tableView)
//        for itemIdentifier in itemIdentifiers {
//            itemIdentifier.registerIfNeeded(in: tableView)
//        }
    }

    private func initializeFetchedResultsController() {
        let fetchRequest = NSFetchRequest<ConversationMessageModel>()
        fetchRequest.entity = ConversationMessageModel.entity()
        fetchRequest.predicate = conversationModel.visibleMessagesPredicate
        fetchRequest.fetchBatchSize = 30
        let sortDescriptor = NSSortDescriptor(key: "serverTimestamp", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let context = persistentContainer.viewContext

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: "todo",
            cacheName: nil
        )
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Failed to perform fetch: \(error)")
        }
    }

    private func setupDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, itemIdentifier in
            let message = self.persistentContainer.viewContext.object(with: itemIdentifier) as! ConversationMessageModel
            let m = message.conversationCellModel
            let cell = tableView.dequeueReusableCell(withIdentifier: m.cellReuseIdentifier, for: indexPath)
            m.configureCell(cell)
            return cell
        }
    }

    private var isFirstApply = true

    nonisolated public func controller(
        _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        assert(Thread.isMainThread)
        var snapshot = snapshot as NSDiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>
        if snapshot.numberOfSections == 0 {
            snapshot.appendSections(["intro"])
        } else if snapshot.indexOfSection("intro") == .none {
            snapshot.insertSections(["intro"], beforeSection: snapshot.sectionIdentifiers[0])
        }
        dataSource.apply(snapshot, animatingDifferences: true) {
            if self.isFirstApply, snapshot.numberOfSections > 1 {
                if let sections = self.fetchedResultsController.sections {
                    let lastSection = sections.count - 1
                    let lastRow = sections[lastSection].numberOfObjects - 1
                    let indexPath = IndexPath(row: lastRow, section: lastSection)
                    self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
                    self.isFirstApply = false
                }
            }
        }
    }

}
