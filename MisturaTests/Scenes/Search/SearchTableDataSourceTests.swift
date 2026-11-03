import Nimble
import Quick
import UIKit
@testable import Mistura

nonisolated final class SearchTableDataSourceTests: AsyncSpec {
    override class func spec() {
        nonisolated(unsafe) var loader: ImageLoaderStub!
        nonisolated(unsafe) var tableView: UITableView!
        nonisolated(unsafe) var sut: SearchTableDataSource!

        let imageURL = URL(string: "https://example.com/soup.jpg/small")!
        let meals = [
            MealCellModel(id: "1", title: "Soup", imageURL: imageURL),
            MealCellModel(id: "2", title: "Rice", imageURL: nil)
        ]

        beforeEach { @MainActor in
            loader = ImageLoaderStub()
            sut = SearchTableDataSource(imageLoader: loader)
            tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 402, height: 874), style: .plain)
            tableView.register(MealCell.self, forCellReuseIdentifier: MealCell.reuseIdentifier)
            tableView.dataSource = sut
            tableView.delegate = sut
        }

        describe("numberOfRowsInSection") {
            it("is zero before any update") { @MainActor in
                expect(sut.tableView(tableView, numberOfRowsInSection: 0)).to(equal(0))
            }

            it("follows the updated items") { @MainActor in
                sut.update(items: meals, sectionTitle: nil)

                expect(sut.tableView(tableView, numberOfRowsInSection: 0)).to(equal(2))
            }

            it("replaces the previous items") { @MainActor in
                sut.update(items: meals, sectionTitle: nil)

                sut.update(items: [], sectionTitle: nil)

                expect(sut.tableView(tableView, numberOfRowsInSection: 0)).to(equal(0))
            }
        }

        describe("cellForRowAt") {
            it("configures the cell with the item of the row") { @MainActor in
                sut.update(items: meals, sectionTitle: nil)
                tableView.reloadData()

                let cell = sut.tableView(tableView, cellForRowAt: IndexPath(row: 1, section: 0))

                expect(cell).to(beAKindOf(MealCell.self))
                expect(cell.label(showing: "Rice")).toNot(beNil())
            }

            it("loads the image with the injected loader") { @MainActor in
                sut.update(items: meals, sectionTitle: nil)
                tableView.reloadData()

                _ = sut.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0))

                await expect { @MainActor in loader.requestedURLs }.toEventually(contain(imageURL))
            }

            it("returns a plain cell when the identifier belongs to another class") { @MainActor in
                let otherTableView = UITableView(frame: tableView.frame, style: .plain)
                otherTableView.register(UITableViewCell.self, forCellReuseIdentifier: MealCell.reuseIdentifier)
                otherTableView.dataSource = sut
                sut.update(items: meals, sectionTitle: nil)

                let cell = sut.tableView(otherTableView, cellForRowAt: IndexPath(row: 0, section: 0))

                expect(cell).toNot(beAKindOf(MealCell.self))
            }
        }

        describe("didSelectRowAt") {
            it("calls onSelectItem with the row") { @MainActor in
                var selectedIndexes: [Int] = []
                sut.onSelectItem = { selectedIndexes.append($0) }
                sut.update(items: meals, sectionTitle: nil)

                sut.tableView(tableView, didSelectRowAt: IndexPath(row: 1, section: 0))

                expect(selectedIndexes).to(equal([1]))
            }

            it("deselects the row") { @MainActor in
                let indexPath = IndexPath(row: 0, section: 0)
                sut.update(items: meals, sectionTitle: nil)
                tableView.reloadData()
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)

                sut.tableView(tableView, didSelectRowAt: indexPath)

                expect(tableView.indexPathForSelectedRow).to(beNil())
            }
        }

        describe("header") {
            context("with a section title") {
                beforeEach { @MainActor in
                    sut.update(items: meals, sectionTitle: "Vistos recentemente")
                }

                it("returns a history header showing the title") { @MainActor in
                    let header = sut.tableView(tableView, viewForHeaderInSection: 0)

                    expect(header).to(beAKindOf(HistoryHeaderView.self))
                    expect(header?.label(showing: "Vistos recentemente")).toNot(beNil())
                }

                it("calls onClearHistory when the header button is tapped") { @MainActor in
                    var clearCount = 0
                    sut.onClearHistory = { clearCount += 1 }
                    let header = sut.tableView(tableView, viewForHeaderInSection: 0)

                    header?.firstView(of: UIButton.self)?.simulateTap()

                    expect(clearCount).to(equal(1))
                }

                it("uses an automatic height") { @MainActor in
                    expect(sut.tableView(tableView, heightForHeaderInSection: 0))
                        .to(equal(UITableView.automaticDimension))
                    expect(sut.tableView(tableView, estimatedHeightForHeaderInSection: 0)).to(equal(44))
                }
            }

            context("without a section title") {
                beforeEach { @MainActor in
                    sut.update(items: meals, sectionTitle: nil)
                }

                it("has no header") { @MainActor in
                    expect(sut.tableView(tableView, viewForHeaderInSection: 0)).to(beNil())
                }

                it("has no header height") { @MainActor in
                    expect(sut.tableView(tableView, heightForHeaderInSection: 0)).to(equal(0))
                    expect(sut.tableView(tableView, estimatedHeightForHeaderInSection: 0)).to(equal(0))
                }
            }
        }
    }
}
