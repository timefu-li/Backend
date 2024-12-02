import Vapor
import VaporToOpenAPI
import Fluent
import FluentSQLiteDriver


// configures your application
public func configure(_ app: Application) async throws {

    // Setup database connection
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    // Setup database schema
    app.migrations.add(InitCategory())
    app.migrations.add(InitTask())
    app.migrations.add(InitCompletedTask())

    // CORS Configuration
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    // cors middleware should come before default error middleware using `at: .beginning`
    app.middleware.use(cors, at: .beginning)

    // Serve swagger UI
    let swagger = FileMiddleware(publicDirectory: app.directory.publicDirectory + "swagger-ui/", defaultFile: "index.html")
    app.middleware.use(swagger)

    // generate OpenAPI documentation
    app.get("Swagger", "swagger.json") { req in
      req.application.routes.openAPI(
        info: InfoObject(
          title: "Timefu-li Backend API",
          description: "Backend service for https://github.com/timefu-li",
          version: "0.1.0"
        )
      )
    }
    .excludeFromOpenAPI()

    // register routes
    try initTasksRoutes(app)
    try initCompletedTasksRoute(app)
    try initCategoriesRoute(app)

    print("Now serving following routes succesfully:")
    print(app.routes.all)
}
