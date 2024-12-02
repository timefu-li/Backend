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

    // Reference to the category this Task belongs to
    @Parent(key: "category_id")
    var category: Category

    // Reference to all the completed tasks belonging to this task.
    @Children(for: \.$task)
    var tasks: [CompletedTask]

    // Creates a new, empty Task
    init() { }

    // Creates a new Task with all properties set.
    init(id: UUID? = nil, name: String, categoryID: UUID) {
        self.id = id
        self.name = name
        self.$category.id = categoryID
    }
}

enum InitTaskSeedingError: Error {
    case categoryMissing
}

struct InitTask: AsyncMigration {
    // Prepares the database for storing Task models.
    func prepare(on database: Database) async throws {
        // Setup tasks table
        try await database.schema("tasks")
            .id()
            .field("name", .string)
            .field("category_id", .uuid, .references("categories", "id"))
            .create()

        // Seed Database
        if let category_id: UUID = try await Category.query(on: database).first()?.id {
            let seed: Task = Task(name: "Test Task", categoryID: category_id)
            try await seed.create(on: database)
        } else {
            throw InitTaskSeedingError.categoryMissing
        }
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) async throws {
        try await database.schema("tasks").delete()
    }
}