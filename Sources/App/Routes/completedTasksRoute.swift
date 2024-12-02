import Vapor
import Fluent

func initTasksRoutes(_ app: Application) throws {

    let tasksRoute = app.grouped("tasks")

    // Create
    tasksRoute.post() { (req: Request) async throws -> Task in
        guard let taskmodel: Task = try? req.content.decode(Task.self) else {
            throw Abort(.custom(code: 422, reasonPhrase: "Request body sent by user is invalid"))
        }
        guard let taskcreated: () = try? await taskmodel.create(on: req.db) else {
            throw Abort(.custom(code: 500, reasonPhrase: "Request valid but unable to add new task to database"))
        }

        return taskmodel
    }

    // Read
    struct taskgetquery: Content {
        let preload: Bool? // Preload category information linked to this task
    }
    tasksRoute.get() { (req: Request) async throws -> [Task] in
        var preload: Bool = true
        if let query: taskgetquery = try? req.query.decode(taskgetquery.self) {
            if let querypreloadunwrapped = query.preload {
                preload = querypreloadunwrapped
            }
        }

        guard let tasksQueryBuilder: QueryBuilder<Task> = try? Task
                                                                .query(on: req.db)
        else {
            throw Abort(.custom(code: 500, reasonPhrase: "Failed to query tasks"))
        }
        guard let tasks: [Task] = preload ? try? await tasksQueryBuilder
                                                                .with(\.$category)
                                                                .all()
                                           : try? await tasksQueryBuilder
                                                                .all() 
        else {
            throw Abort(.custom(code: 200, reasonPhrase: "Task not found"))
        }

        return tasks
    }

    // Read Single
    tasksRoute.get(":id") { (req: Request) async throws -> Task in
        var preload: Bool = true
        if let query: taskgetquery = try? req.query.decode(taskgetquery.self) {
            if let querypreloadunwrapped = query.preload {
                preload = querypreloadunwrapped
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
        guard let task: Task = preload ? try? await taskQueryBuilder
                                                .with(\.$category)
                                                .filter(\.$id == idparam)
                                                .first()
                                       : try? await taskQueryBuilder
                                                .filter(\.$id == idparam)
                                                .first()
        else {
            throw Abort(.custom(code: 200, reasonPhrase: "Task not found"))
        }

        return task
    }

    // Update
    struct taskpatchquery: Content {
        let name: String?
        let category: UUID?
    }
    tasksRoute.patch(":id") { (req: Request) async throws -> Task in
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
    }

    // Delete
    tasksRoute.delete(":id") { (req: Request) async throws -> Task in
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
        guard let taskdeleted: () = try? await task.delete(on: req.db) else {
            throw Abort(.custom(code: 500, reasonPhrase: "Request valid but unable to delete task in database"))
        }

        return task
    }

}