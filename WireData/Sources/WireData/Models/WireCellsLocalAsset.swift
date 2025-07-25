import CoreData
import Foundation

/// Information of a Wire Cells local asset (e.g file) including whether it is downloaded.
///
/// It's download location is determined by its `nodeID` and `eTag` properties.

public final class WireCellsLocalAsset: NSManagedObject {

    /// The name of the associated Core Data entity.

    public static let entityName = "WireCellsLocalAsset"

    /// The identifier of the asset on the Wire Cells backend.

    @NSManaged public var nodeID: UUID

    /// The eTag of the asset.
    ///
    /// If this changes the file represented by `nodeID` has changed and should be re-downloaded.

    @NSManaged public var eTag: String

    /// The path representing the asset in the Wire Cells file system.
    ///
    /// This is **not** the path on the local file system. It encodes information such as file name and extension.

    @NSManaged public var path: String

    /// The content type of the asset as defined by the backend.
    ///
    /// This is a MIME type (e.g. "image/png", "application/pdf").

    @NSManaged public var contentType: String?

    /// The size of the asset in bytes as defined by the backend or `-1` if unknown.

    @NSManaged public var size: Int64

    /// Whether the asset is downloaded or not.

    @NSManaged public var isDownloaded: Bool

}
