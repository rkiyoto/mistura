import CoreData

final class CoreDataStack {
    // Carregar o modelo mais de uma vez no mesmo processo torna a entidade ambígua para o Core Data
    private static let model: NSManagedObjectModel = {
        guard let model = NSManagedObjectModel.mergedModel(from: [Bundle(for: CoreDataStack.self)]) else {
            fatalError("Modelo do Core Data não encontrado")
        }
        return model
    }()

    private let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// - Parameter inMemory for testing purposes
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Mistura", managedObjectModel: Self.model)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("Falha ao carregar o Core Data: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
