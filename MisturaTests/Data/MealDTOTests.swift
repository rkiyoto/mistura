import Foundation
import Nimble
import Quick
@testable import Mistura

nonisolated final class MealDTOTests: QuickSpec {
    override class func spec() {
        describe("MealListResponseDTO") {
            context("when the API returns null meals") {
                it("decodes meals as nil") {
                    let json = """
                    {
                        "meals": null
                    }
                    """
                    let response = try decode(json)

                    expect(response.meals).to(beNil())
                }
            }

            context("when the response comes from the filter endpoint") {
                it("decodes only the summary fields") {
                    let json = """
                    {
                        "meals": [
                            {
                                "idMeal": "1",
                                "strMeal": "Soup",
                                "strMealThumb": "https://example.com/soup.jpg"
                            }
                        ]
                    }
                    """
                    let response = try decode(json)

                    expect(response.meals?.first?.summary).to(equal(
                        MealSummary(
                            id: "1",
                            name: "Soup",
                            thumbnailURL: URL(string: "https://example.com/soup.jpg/small")
                        )
                    ))
                    expect(response.meals?.first?.ingredients).to(beEmpty())
                }
            }

            context("when the response comes from the lookup endpoint") {
                it("maps the full size image and the thumbnail") {
                    let json = """
                    {
                        "meals": [
                            {
                                "idMeal": "1",
                                "strMeal": "Soup",
                                "strMealThumb": "https://example.com/soup.jpg"
                            }
                        ]
                    }
                    """
                    let response = try decode(json)
                    let detail = response.meals?.first?.detail

                    expect(detail?.imageURL).to(equal(URL(string: "https://example.com/soup.jpg")))
                    expect(detail?.thumbnailURL).to(equal(URL(string: "https://example.com/soup.jpg/small")))
                    expect(detail?.summary.thumbnailURL).to(equal(detail?.thumbnailURL))
                }
            }

            context("when the title is missing") {
                it("keeps the meal with an empty name") {
                    let json = """
                    {
                        "meals": [
                            { "idMeal": "1" },
                            { "idMeal": "2", "strMeal": null }
                        ]
                    }
                    """
                    let response = try decode(json)

                    expect(response.meals?.map(\.strMeal)).to(equal(["", ""]))
                }
            }

            context("when an item is invalid") {
                it("discards only the invalid item") {
                    let json = """
                    {
                        "meals": [
                            { "strMeal": "No id" },
                            { "idMeal": "2", "strMeal": "Rice" },
                            null,
                            "invalid"
                        ]
                    }
                    """
                    let response = try decode(json)

                    expect(response.meals?.map(\.idMeal)).to(equal(["2"]))
                }

                it("decodes meals as nil when every item is invalid") {
                    let json = """
                    {
                        "meals": [
                            { "strMeal": "No id" }
                        ]
                    }
                    """
                    let response = try decode(json)

                    expect(response.meals).to(beNil())
                }
            }

            context("when the list is empty") {
                it("decodes meals as nil") {
                    let json = """
                    {
                        "meals": []
                    }
                    """
                    let response = try decode(json)

                    expect(response.meals).to(beNil())
                }
            }

            context("when the meals key is missing") {
                it("decodes meals as nil") {
                    let response = try decode("{}")

                    expect(response.meals).to(beNil())
                }
            }

            context("when the response itself is invalid") {
                it("throws a decoding error when meals is not a list") {
                    let json = """
                    {
                        "meals": "invalid"
                    }
                    """
                    expect { try decode(json) }.to(throwError())
                }

                it("throws a decoding error when the root is not an object") {
                    let json = "[]"
                    expect { try decode(json) }.to(throwError())
                }
            }
        }

        describe("MealDTO ingredients") {
            it("pairs each ingredient with its measure") {
                let json = """
                    "strIngredient1": "Rice",
                    "strMeasure1": "2 cups",
                    "strIngredient2": "Salt",
                    "strMeasure2": "1 tsp"
                """
                let detail = try decodeDetail(json)

                expect(detail.ingredients).to(equal([
                    Ingredient(name: "Rice", measure: "2 cups"),
                    Ingredient(name: "Salt", measure: "1 tsp")
                ]))
            }

            it("ignores null ingredients") {
                let json = """
                    "strIngredient1": "Rice",
                    "strMeasure1": "2 cups",
                    "strIngredient2": null,
                    "strMeasure2": null
                """
                let detail = try decodeDetail(json)

                expect(detail.ingredients).to(haveCount(1))
            }

            it("keeps empty ingredients as empty strings") {
                let json = """
                    "strIngredient1": "Rice",
                    "strMeasure1": "2 cups",
                    "strIngredient2": "",
                    "strMeasure2": ""
                """
                let detail = try decodeDetail(json)

                expect(detail.ingredients).to(equal([
                    Ingredient(name: "Rice", measure: "2 cups"),
                    Ingredient(name: "", measure: "")
                ]))
            }

            it("trims ingredients containing only whitespace to empty strings") {
                let json = """
                    "strIngredient1": "Rice",
                    "strMeasure1": "2 cups",
                    "strIngredient2": "  ",
                    "strMeasure2": " "
                """
                let detail = try decodeDetail(json)

                expect(detail.ingredients).to(equal([
                    Ingredient(name: "Rice", measure: "2 cups"),
                    Ingredient(name: "", measure: "")
                ]))
            }

            it("uses an empty measure when it is missing") {
                let json = """
                    "strIngredient1": "Salt",
                    "strMeasure1": null
                """
                let detail = try decodeDetail(json)

                expect(detail.ingredients).to(equal([Ingredient(name: "Salt", measure: "")]))
            }
        }

        describe("MealDTO tags") {
            it("splits and trims the tags") {
                let json = """
                    "strTags": "Meat, Casserole"
                """
                let detail = try decodeDetail(json)

                expect(detail.tags).to(equal(["Meat", "Casserole"]))
            }

            it("returns no tags when the field is null") {
                let json = """
                    "strTags": null
                """
                let detail = try decodeDetail(json)

                expect(detail.tags).to(beEmpty())
            }
        }

        describe("MealDTO optional fields") {
            it("keeps an empty category as an empty string") {
                let json = """
                    "strCategory": ""
                """
                let detail = try decodeDetail(json)

                expect(detail.category).to(equal(""))
            }

            it("maps an empty YouTube link to nil") {
                let json = """
                    "strYoutube": ""
                """
                let detail = try decodeDetail(json)

                expect(detail.youtubeURL).to(beNil())
            }
        }
    }

    @MainActor
    private static func decode(_ json: String) throws -> MealListResponseDTO {
        try JSONDecoder().decode(MealListResponseDTO.self, from: Data(json.utf8))
    }

    @MainActor
    private static func decodeDetail(_ fields: String) throws -> MealDetail {
        let json = """
        {
            "meals": [
                {
                    "idMeal": "1",
                    "strMeal": "Soup",
                    \(fields)
                }
            ]
        }
        """
        let response = try decode(json)
        return try unwrap(response.meals?.first).detail
    }
}
