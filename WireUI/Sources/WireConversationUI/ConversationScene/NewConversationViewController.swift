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

public final class NewConversationViewController<ConversationModel: NSManagedObject>: UITableViewController, NSFetchedResultsControllerDelegate {

    enum SectionIdentifier {
        case single
    }

    typealias ItemIdentifier = ConversationCellModel

    let itemIdentifiers = [ItemIdentifier]()

    /// don't use
    public let conversationModel: ConversationModel!


    private let persistentContainer: NSPersistentContainer
    private let conversationObjectID: NSManagedObjectID

    private var fetchedResultsController: NSFetchedResultsController<ConversationModel>!
    private var dataSource: UITableViewDiffableDataSource<SectionIdentifier, ItemIdentifier>!

    public init(
        conversationModel: ConversationModel,
        persistentContainer: NSPersistentContainer
    ) {
        self.conversationModel = conversationModel
        self.persistentContainer = persistentContainer
        conversationObjectID = conversationModel.objectID

        super.init(style: .plain)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        initializeFetchedResultsController()
        loadItems()
    }

    private func setupTableView() {
        registerCellTypes()
        setupDataSource()
        tableView.separatorStyle = .none
    }

    private func registerCellTypes() {
        for itemIdentifier in itemIdentifiers {
            itemIdentifier.registerIfNeeded(in: tableView)
        }
    }

    private func initializeFetchedResultsController() {
        let fetchRequest = NSFetchRequest<ConversationModel>()
        fetchRequest.entity = ConversationModel.entity()
        let sortDescriptor = NSSortDescriptor(key: "serverTimestamp", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let context = persistentContainer.viewContext

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
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
            let cell = tableView.dequeueReusableCell(withIdentifier: itemIdentifier.cellReuseIdentifier, for: indexPath)
            itemIdentifier.configureCell(cell)
            return cell
        }
    }

    private func loadItems() {
        var snapshot = dataSource.snapshot()
        snapshot.appendSections([.single])
        snapshot.appendItems(itemIdentifiers)
        dataSource.applySnapshotUsingReloadData(snapshot)
    }

    nonisolated public func controller(
        _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
        didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
    ) {
        fatalError()
    }

}
