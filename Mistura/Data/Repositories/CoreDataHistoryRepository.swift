import CoreData

protocol HistoryRepositoryType {
    func recentMeals() throws -> [MealSummary]
    func save(_ meal: MealSummary) throws
    func clearHistory() throws
}

final class CoreDataHistoryRepository: HistoryRepositoryType {
    private let stack: CoreDataStack
    private let limit: Int
    private let now: () -> Date

    private var context: NSManagedObjectContext {
        stack.viewContext
    }

    init(stack: CoreDataStack, limit: Int = 10, now: @escaping () -> Date = Date.init) {
        self.stack = stack
        self.limit = limit
        self.now = now
    }

    func recentMeals() throws -> [MealSummary] {
        let request = sortedRequest()
        request.fetchLimit = limit
        return try context.fetch(request).compactMap(\.summary)
    }

    func save(_ meal: MealSummary) throws {
        let request: NSFetchRequest<ViewedMealEntity> = ViewedMealEntity.fetchRequest()
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(ViewedMealEntity.mealID), meal.id)
        request.fetchLimit = 1

        let entity = try context.fetch(request).first ?? ViewedMealEntity(context: context)
        entity.mealID = meal.id
        entity.name = meal.name
        entity.thumbnailURL = meal.thumbnailURL?.absoluteString
        entity.viewedAt = now()

        try removeEntriesBeyondLimit()
        try context.save()
    }
    
    func clearHistory() throws {
        let request: NSFetchRequest<NSFetchRequestResult> = ViewedMealEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        try context.execute(deleteRequest)
        try context.save()
    }

    private func removeEntriesBeyondLimit() throws {
        try context.fetch(sortedRequest()).dropFirst(limit).forEach(context.delete)
    }

    private func sortedRequest() -> NSFetchRequest<ViewedMealEntity> {
        let request: NSFetchRequest<ViewedMealEntity> = ViewedMealEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(ViewedMealEntity.viewedAt), ascending: false)]
        return request
    }
}

private extension ViewedMealEntity {
    var summary: MealSummary? {
        guard let mealID, let name else { return nil }
        return MealSummary(id: mealID,
                           name: name,
                           thumbnailURL: thumbnailURL.flatMap(URL.init(string:)))
    }
}
