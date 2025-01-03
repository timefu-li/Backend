import Vapor
import VaporToOpenAPI
import Fluent

func initCompletedTasksRoute(_ app: Application) throws {

    let completedTasksRoute = app.grouped("completedtasks")

    // Create
    completedTasksRoute.post(use: { (req: Request) async throws -> CompletedTask in
        // Custom decoder to handle dates properly
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        print(req.content)

        guard let completedtaskmodel: CompletedTask = try? req.content.decode(CompletedTask.self, using: decoder) else {
            throw Abort(.custom(code: 400, reasonPhrase: "INVALIDREQUESTBODY:Request body sent by user is invalid"))
        }
        guard let completedtaskcreated: () = try? await completedtaskmodel.create(on: req.db) else {
            throw Abort(.custom(code: 500, reasonPhrase: "INTERNALSERVERERROR:Request valid but unable to add new task to database"))
        }

        return completedtaskmodel
    }).openAPI(
        summary: "Create a completed task",
        description: "Create a new completed task with the provided data",
        body: .type(CompletedTask.self),
        response: .type(CompletedTask.self)
    )

    // Read All
    struct completedtaskgetquery: Content {
        let preload: Bool? // Preload category information linked to this task
        let latest: Bool? // Get latest or oldest results first
    }
    completedTasksRoute.get(use: { (req: Request) async throws -> [CompletedTask] in
        var preload: Bool = true
        var latest: Bool = true
        if let query: completedtaskgetquery = try? req.query.decode(completedtaskgetquery.self) {
            if let querypreloadunwrapped = query.preload {
                preload = querypreloadunwrapped
            }
            if let querylatestunwrapped = query.latest {
                latest = querylatestunwrapped
            }
        }

        guard let tasksQueryBuilder: QueryBuilder<CompletedTask> = try? CompletedTask
            .query(on: req.db)
        else {
            throw Abort(.custom(code: 500, reasonPhrase: "INTERNALSERVERERROR:Failed to query completed tasks"))
        }

        guard let tasks: [CompletedTask] = try? await tasksQueryBuilder
            .preloadAssociationData(preload: preload) // Check if we need to preload all data
            .all()
        else {
            throw Abort(.custom(code: 200, reasonPhrase: "NOTFOUND:No completed tasks found"))
        }

        return latest ? tasks.reversed() : tasks
    }).openAPI(
        summary: "Get all completed tasks",
        description: "Get an array of all completed tasks currently in the database",
        response: .type([CompletedTask].self)
    )

    // Read Single
    completedTasksRoute.get(":id", use: { (req: Request) async throws -> CompletedTask in
        var preload: Bool = true
        if let query: completedtaskgetquery = try? req.query.decode(completedtaskgetquery.self) {
            if let querypreloadunwrapped = query.preload {
                preload = querypreloadunwrapped
            }
        }

        guard let idparam: UUID = try? req.parameters.get("id") else {
            throw Abort(.custom(code: 400, reasonPhrase: "INVALIDID:Provided ID is not in a valid UUID format"))
        }

        guard let taskQueryBuilder: QueryBuilder<CompletedTask> = try? CompletedTask
            .query(on: req.db)
        else {
            throw Abort(.custom(code: 500, reasonPhrase: "INTERNALSERVERERROR:Failed to query completed tasks"))
        }

        guard let task: CompletedTask = try? await taskQueryBuilder
            .preloadAssociationData(preload: preload) // Check if we need to preload all data
            .filter(\.$id == idparam)
            .first()
        else {
            throw Abort(.custom(code: 200, reasonPhrase: "NOTFOUND:Completed task not found"))
        }

        return task
    }).openAPI(
        summary: "Get completed task",
        description: "Get a specific completed task based on the ID",
        response: .type(CompletedTask.self)
    )

    // Update
    struct taskpatchquery: Content {
        let name: String?

        // I'll just handle dates as strings in the query
        let started: String?
        let completed: String?

        let task: UUID?
    }
    completedTasksRoute.patch(":id", use: { (req: Request) async throws -> CompletedTask in
        guard let idparam: UUID = try? req.parameters.get("id") else {
            throw Abort(.custom(code: 400, reasonPhrase: "INVALIDID:Provided ID is not in a valid UUID format"))
        }
        guard let task: CompletedTask = try? await CompletedTask
            .query(on: req.db)
            .filter(\.$id == idparam)
            .first()
        else {
            throw Abort(.custom(code: 200, reasonPhrase: "NOTFOUND:Requested completed task not found"))
        }

        guard let query: taskpatchquery = try? req.query.decode(taskpatchquery.self) else {
            throw Abort(.custom(code: 400, reasonPhrase: "INVALIDREQUESTQUERY:Request queries sent by user is invalid"))
        }
        // TODO: I don't like how manual this is so maybe needs some custom function to iterate over the content struct, but it's simple and it works
        if let unwrappedquery = query.name {
            task.name = unwrappedquery
        }
        if let unwrappedquery = query.started {
            // Convert query string to date
            task.started = ISO8601DateFormatter().date(from: unwrappedquery) ?? Date()
        }
        if let unwrappedquery = query.completed {
            // Convert query string to date
            task.completed = ISO8601DateFormatter().date(from: unwrappedquery) ?? Date()
        }
        if let unwrappedquery = query.task {
            task.$task.id = unwrappedquery
        }

        guard let taskupdated: () = try? await task.update(on: req.db) else {
            throw Abort(.custom(code: 500, reasonPhrase: "INTERNALSERVERERROR:Request valid but unable to update completed task in database"))
        }

        return task
    }).openAPI(
        summary: "Update completed task",
        description: "Update a specific completed task based on the ID",
        response: .type(CompletedTask.self)
    )

    // Delete
    completedTasksRoute.delete(":id", use: { (req: Request) async throws -> CompletedTask in
        guard let idparam: UUID = try? req.parameters.get("id") else {
            throw Abort(.custom(code: 400, reasonPhrase: "INVALIDID:Provided ID is not in a valid UUID format"))
        }
        guard let task: CompletedTask = try? await CompletedTask
            .query(on: req.db)
            .filter(\.$id == idparam)
            .first()
        else {
            throw Abort(.custom(code: 200, reasonPhrase: "NOTFOUND:Requested completed task not found"))
        }
        guard let taskdeleted: () = try? await task.delete(on: req.db) else {
            throw Abort(.custom(code: 500, reasonPhrase: "INTERNALSERVERERROR:Request valid but unable to delete completed task in database"))
        }

        return task
    }).openAPI(
        summary: "Delete completed task",
        description: "Delete a specific completed task based on the ID",
        response: .type(CompletedTask.self)
    )

}
