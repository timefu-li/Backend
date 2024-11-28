import Vapor
import Fluent
import FluentSQLiteDriver

final class CompletedTask: Model, Content {
    // Name of the table or collection.
    static let schema = "completedtasks"

    // Unique identifier for this Task.
    @ID(key: .id)
    var id: UUID?

    // The Task's name.
    @Field(key: "name")
    var name: String

    // The Task's date when it was started.
    @Field(key: "started")
    var started: Date

    // The Task's date when it was completed.
    @Field(key: "completed")
    var completed: Date

    // Creates a new, empty Task
    init() { }

    // Creates a new Task with all properties set.
    init(id: UUID? = nil, name: String, started: Date, completed: Date) {
        self.id = id
        self.completed = completed
        self.started = started
        self.name = name
    }
}

struct InitCompletedTask: AsyncMigration {
    // Prepares the database for storing Task models.
    func prepare(on database: Database) async throws {
        // Setup tasks table
        try await database.schema("completedtasks")
            .id()
            .field("name", .string)
            .field("started", .date)
            .field("completed", .date)
            .create()

        // Seed Database
        let seed: CompletedTask = CompletedTask(name: "Completed Test Task", started: Date(), completed: Date() + TimeInterval(60*60*24))
        try await seed.create(on: database)
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) async throws {
        try await database.schema("tasks").delete()
    }
}
