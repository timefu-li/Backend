import Vapor
import Fluent
import FluentSQLiteDriver

final class Task: Model, Content {
    // Name of the table or collection.
    static let schema = "tasks"

    // Unique identifier for this Task.
    @ID(key: .id)
    var id: UUID?

    // The Task's name.
    @Field(key: "name")
    var name: String

    // Creates a new, empty Task
    init() { }

    // Creates a new Task with all properties set.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

struct InitTask: AsyncMigration {
    // Prepares the database for storing Task models.
    func prepare(on database: Database) async throws {
        // Setup tasks table
        try await database.schema("tasks")
            .id()
            .field("name", .string)
            .create()

        // Seed Database
        let seed: Task = Task(name: "Test Task")
        try await seed.create(on: database)
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) async throws {
        try await database.schema("tasks").delete()
    }
}
