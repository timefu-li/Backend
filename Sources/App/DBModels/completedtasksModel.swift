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

    // Reference to the task this Completed Task belongs to
    @Parent(key: "task_id")
    var task: Task

    // Creates a new, empty Task
    init() { }

    // Creates a new Task with all properties set.
    init(id: UUID? = nil, name: String, started: Date, completed: Date, taskID: UUID) {
        self.name = name
        self.started = started
        self.completed = completed
        self.id = id
        self.$task.id = taskID
    }
}

enum InitCompletedTaskSeedingError: Error {
    case categoryMissing
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
            .field("task_id", .uuid, .references("tasks", "id"))
            .create()

        // Seed Database
        if let task_id: UUID = try await Task.query(on: database).first()?.id {
            let seed: CompletedTask = CompletedTask(name: "Completed Test Task", started: Date(), completed: Date() + TimeInterval(60*60*24), taskID: task_id)
            try await seed.create(on: database)
        } else {
            throw InitCompletedTaskSeedingError.categoryMissing
        }
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) async throws {
        try await database.schema("tasks").delete()
    }
}

// Extensions ontop of QueryBuilder for Completed Task to allow us to retrieve additional data etc. Like a middleware before a query is finalised.
public extension QueryBuilder<CompletedTask> {

    // Check to see if we need to preload all association data into query or not - By default we will
    internal func preloadAssociationData(preload: Bool = true) -> Self {
        if preload {
            return self.with(\.$task, { (task) in
                task.with(\.$category)
            })
        } else {
            return self
        }
    }

}
