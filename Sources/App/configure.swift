import Vapor
import Fluent
import FluentSQLiteDriver


// configures your application
public func configure(_ app: Application) async throws {

    // Setup database connection
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    // Setup database schema
    app.migrations.add(InitTask())

    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // register routes
    try routes(app)
}
