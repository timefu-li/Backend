import Vapor
import Fluent
import FluentSQLiteDriver

struct ColourRGB: Encodable, Decodable {
    let red: uint8;
    let green: uint8;
    let blue: uint8;
}

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
    var colour: ColourRGB

    // Reference to all the tasks belonging to this category.
    @Children(for: \.$category)
    var tasks: [Task]

    // Creates a new, empty Task
    init() { }

    // Creates a new Task with all properties set.
    init(id: UUID? = nil, name: String, emoji: String, colour: ColourRGB) {
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
            .field("colour", .dictionary(of: .uint8))
            .create()

        // Seed Database
        // As an assumption, "No Category" will always be the first ever category in the schema
        let seed: Category = Category(name: "No Category", emoji: "placeholder", colour: ColourRGB(red: 128, green: 128, blue: 128))
        try await seed.create(on: database)
    }

    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) async throws {
        try await database.schema("tasks").delete()
    }
}
