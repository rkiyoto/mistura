import Nimble
import Quick
import UIKit
@testable import Mistura

nonisolated final class HistoryHeaderViewTests: QuickSpec {
    override class func spec() {
        var sut: HistoryHeaderView!

        beforeEach {
            sut = HistoryHeaderView(title: "Vistos recentemente")
        }

        describe("layout") {
            it("shows the title and the clear button") {
                assertRenderSnapshot(of: sut, named: "default", size: CGSize(width: 402, height: 60))
            }
        }

        describe("clear button") {
            it("calls onClearHistory once when tapped") {
                var clearCount = 0
                sut.onClearHistory = { clearCount += 1 }

                sut.firstView(of: UIButton.self)?.simulateTap()

                expect(clearCount).to(equal(1))
            }

            it("has an accessibility label") {
                expect(sut.button(accessibilityLabel: TextStrings.clearHistoryAccessibilityLabel)).toNot(beNil())
            }
        }
    }
}
