import SnapshotTesting
import UIKit

func assertRenderSnapshot(
    of view: UIView,
    named name: String,
    size: CGSize = CGSize(width: 402, height: 874),
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let traits = UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceStyle: .light),
        UITraitCollection(preferredContentSizeCategory: .large),
        UITraitCollection(displayScale: 2)
    ])

    assertSnapshot(
        of: view,
        as: .image(perceptualPrecision: 0.98, size: size, traits: traits),
        named: name,
        file: file,
        testName: "render",
        line: line
    )
}
