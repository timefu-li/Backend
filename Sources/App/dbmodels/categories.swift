import Vapor
import Fluent
import FluentSQLiteDriver

final class Category: Model, Content {
    // Name of the table or collection.
    static let schema = "categories"

    // Unique identifier for this Task.
    @ID(key: .id)
    var id: UUID?

    // The Task's name.
    @Field(key: "name")
    var name: String

    // The Task's emoji.
    @Field(key: "emoji")
    var emoji: String

    // The Task's colour.
    @Field(key: "colour")
    var colour: String

    // Reference to all the tasks belonging to this category.
    @Children(for: \.$category)
    var tasks: [Task]

    // Creates a new, empty Task
    init() { }

    // Creates a new Task with all properties set.
    init(id: UUID? = nil, name: String, emoji: String, colour: String) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.colour = colour
    }
}

struct InitCategory: AsyncMigration {
    // Prepares the database for storing Task models.
    func prepare(on database: Database) async throws {
        // Setup tasks table
        try await database.schema("categories")
            .id()
            .field("name", .string)
            .field("emoji", .string)
            .field("colour", .string)
            .create()

        // Seed Database
        let seed: Category = Category(name: "Test Category", emoji: "placeholder", colour: "red")
        try await seed.create(on: database)
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) async throws {
        try await database.schema("tasks").delete()
    }
}
