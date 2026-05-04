# ``WireImages-ios``

Process images for transport over the network.

## Overview

WireImages provides functionality for performing transformations (such as downscaling and compression) on images to facilitate transport to the Wire backend.

### Usage:

Consumers of this framework should mostly interact with the `LinkPreviewDetector` type, it can be used to check if a given text contains a link using the `containsLink:inText` method and if it does it can be used to download the previews asynchronously using `downloadLinkPreviews:inText:completion`.

```swift
let text = "Text containing a link to your awesome tweet"
let detector = LinkPreviewDetector(resultsQueue: .main)

guard detector.containsLink(inText: text) else { return }
detector.downloadLinkPreviews(inText: text) { previews in
    // Do something with the previews
}
```

A call to this method will also download the images specified in the Open Graph data. The completion returns an array of `LinkPreview` objects which currently are either of type `ArticleMetadata` or `TwitterStatusMetadata`, while the count of elements in the array is also limited to one at for now. Note, use the delegate `LinkPreviewDetectorDelegate` to control which which detected links will have their preview generated.

## Topics
