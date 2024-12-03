import Vapor
import VaporToOpenAPI
import Fluent

func initTasksRoutes(_ app: Application) throws {

    let tasksRoute = app.grouped("tasks")

    // Create
    tasksRoute.post(use: { (req: Request) async throws -> Task in
        guard let taskmodel: Task = try? req.content.decode(Task.self) else {
            throw Abort(.custom(code: 422, reasonPhrase: "Request body sent by user is invalid"))
        }
        guard let taskcreated: () = try? await taskmodel.create(on: req.db) else {
            throw Abort(.custom(code: 500, reasonPhrase: "Request valid but unable to add new task to database"))
        }

        return taskmodel
    }).openAPI(
        summary: "Create a task",
        description: "Create a new task with the provided data",
        body: .type(Task.self),
        response: .type(Task.self)
    )

    // Read All
    struct taskgetquery: Content {
        let preloadCategory: Bool? // Preload category information linked to this task
        let preloadCompletedTasks: Bool? // Preload completed tasks information linked to this task
    }
    tasksRoute.get(use: { (req: Request) async throws -> [Task] in
        var preloadCategory: Bool = true
        var preloadCompletedTasks: Bool = false
        if let query: taskgetquery = try? req.query.decode(taskgetquery.self) {
            if let querypreloadunwrapped = query.preloadCategory {
                preloadCategory = querypreloadunwrapped
            }
            if let querypreloadunwrapped = query.preloadCompletedTasks {
                preloadCompletedTasks = querypreloadunwrapped
            }
        }

        guard let tasksQueryBuilder: QueryBuilder<Task> = try? Task
            .query(on: req.db)
        else {
            throw Abort(.custom(code: 500, reasonPhrase: "Failed to query tasks"))
        }

        guard let tasks: [Task] = try? await tasksQueryBuilder
            .preloadAssociationCategory(preload: preloadCategory) // Check if we need to preload all category data
            .preloadAssociationCompletedTasks(preload: preloadCompletedTasks) // Check if we need to preload all completed tasks data
            .all()
        else {
            throw Abort(.custom(code: 200, reasonPhrase: "No tasks found"))
        }

        return tasks
    }).openAPI(
        summary: "Get all tasks",
        description: "Get an array of all tasks currently in the database",
        response: .type([Task].self)
    )

    // Read Single
    tasksRoute.get(":id", use: { (req: Request) async throws -> Task in
        var preloadcategory: Bool = true
        var preloadcompletedtasks: Bool = false
        if let query: taskgetquery = try? req.query.decode(taskgetquery.self) {
            if let querypreloadunwrapped = query.preloadCategory {
                preloadcategory = querypreloadunwrapped
            }
            if let querypreloadunwrapped = query.preloadCompletedTasks {
                preloadcompletedtasks = querypreloadunwrapped
            }
        }

        guard let idparam: UUID = try? req.parameters.get("id") else {
            throw Abort(.custom(code: 422, reasonPhrase: "Provided ID is not in a valid UUID format"))
        }

        guard let taskQueryBuilder: QueryBuilder<Task> = try? Task
            .query(on: req.db)
        else {
            throw Abort(.custom(code: 500, reasonPhrase: "Failed to query tasks"))
        }

        guard let task: Task = try? await taskQueryBuilder
            .preloadAssociationCategory(preload: preloadcategory) // Check if we need to preload all category data
            .preloadAssociationCompletedTasks(preload: preloadcompletedtasks) // Check if we need to preload all completed tasks data
            .filter(\.$id == idparam)
            .first()
        else {
            throw Abort(.custom(code: 200, reasonPhrase: "Task not found"))
        }

        return task
    }).openAPI(
        summary: "Get task",
        description: "Get a specific task based on the ID",
        response: .type(Task.self)
    )

    // Update
    struct taskpatchquery: Content {
        let name: String?
        let category: UUID?
    }
    tasksRoute.patch(":id", use: { (req: Request) async throws -> Task in
        guard let idparam: UUID = try? req.parameters.get("id") else {
            throw Abort(.custom(code: 422, reasonPhrase: "Provided ID is not in a valid UUID format"))
        }
        guard let task: Task = try? await Task
            .query(on: req.db)
            .filter(\.$id == idparam)
            .first()
        else {
            throw Abort(.custom(code: 200, reasonPhrase: "Requested task not found"))
        }

        guard let query: taskpatchquery = try? req.query.decode(taskpatchquery.self) else {
            throw Abort(.custom(code: 422, reasonPhrase: "Request queries sent by user is invalid"))
        }
        // TODO: I don't like how manual this is so maybe needs some custom function to iterate over the content struct, but it's simple and it works
        if let unwrappedquery = query.name {
            task.name = unwrappedquery
        }
        if let unwrappedquery = query.category {
            task.$category.id = unwrappedquery
        }

        guard let taskupdated: () = try? await task.update(on: req.db) else {
            throw Abort(.custom(code: 500, reasonPhrase: "Request valid but unable to update task in database"))
        }

        return task
    }).openAPI(
        summary: "Update task",
        description: "Update a specific task based on the ID",
        response: .type(Task.self)
    )

    // Delete
    tasksRoute.delete(":id", use: { (req: Request) async throws -> Task in
        guard let idparam: UUID = try? req.parameters.get("id") else {
            throw Abort(.custom(code: 422, reasonPhrase: "Provided ID is not in a valid UUID format"))
        }
        guard let task: Task = try? await Task
            .query(on: req.db)
            .filter(\.$id == idparam)
            .first()
        else {
            throw Abort(.custom(code: 200, reasonPhrase: "Requested task not found"))
        }

        if (task.completedtasks.count != 0) {
            throw Abort(.custom(code: 500, reasonPhrase: "Currently completed tasks referencing this task. Please remove all references to this task."))
        }

        guard let taskdeleted: () = try? await task.delete(on: req.db) else {
            throw Abort(.custom(code: 500, reasonPhrase: "Request valid but unable to delete task in database"))
        }

        return task
    }).openAPI(
        summary: "Delete task",
        description: "Delete a specific task based on the ID",
        response: .type(Task.self)
    )

}
