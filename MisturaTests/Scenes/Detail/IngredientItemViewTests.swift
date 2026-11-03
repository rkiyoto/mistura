import Nimble
import Quick
import UIKit
@testable import Mistura

nonisolated final class IngredientItemViewTests: QuickSpec {
    override class func spec() {
        var sut: IngredientItemView!

        let rowSize = CGSize(width: 362, height: 44)

        beforeEach {
            sut = IngredientItemView(ingredient: "2 cups Rice")
        }

        describe("initial state") {
            it("exposes the ingredient and starts unchecked") {
                expect(sut.ingredient).to(equal("2 cups Rice"))
                expect(sut.isChecked).to(beFalse())
            }

            it("shows the unchecked layout") {
                assertRenderSnapshot(of: sut, named: "unchecked", size: rowSize)
            }
        }

        describe("checkbox") {
            it("checks the ingredient when tapped") {
                sut.firstView(of: UIButton.self)?.simulateTap()

                expect(sut.isChecked).to(beTrue())
            }

            it("strikes through the text when checked") {
                sut.firstView(of: UIButton.self)?.simulateTap()

                expect(strikethroughStyle(in: sut)).to(equal(NSUnderlineStyle.single.rawValue))
            }

            it("shows the checked layout") {
                sut.firstView(of: UIButton.self)?.simulateTap()

                assertRenderSnapshot(of: sut, named: "checked", size: rowSize)
            }

            it("unchecks the ingredient when tapped again") {
                let button = sut.firstView(of: UIButton.self)
                button?.simulateTap()

                button?.simulateTap()

                expect(sut.isChecked).to(beFalse())
                expect(strikethroughStyle(in: sut)).to(beNil())
                expect(sut.label(showing: "2 cups Rice")).toNot(beNil())
            }

            it("shows the unchecked layout again when tapped twice") {
                let button = sut.firstView(of: UIButton.self)
                button?.simulateTap()

                button?.simulateTap()

                assertRenderSnapshot(of: sut, named: "unchecked-again", size: rowSize)
            }
        }
    }
}

private func strikethroughStyle(in view: UIView) -> Int? {
    let text = view.firstView(of: UILabel.self)?.attributedText
    return text?.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) as? Int
}
