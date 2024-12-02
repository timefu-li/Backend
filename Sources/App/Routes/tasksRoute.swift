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
    tasksRoute.get() { (req: Request) async throws -> [Task] in
        guard let tasks: [Task] = try? await Task.query(on: req.db).all() else {
            throw Abort(.custom(code: 200, reasonPhrase: "No tasks found"))
        }

        return tasks
    }

    // Read Single
    tasksRoute.get(":id") { (req: Request) async throws -> Task in
        guard let idparam: UUID = try? req.parameters.get("id") else {
            throw Abort(.custom(code: 422, reasonPhrase: "Provided ID is not in a valid UUID format"))
        }
        guard let task: Task = try? await Task.query(on: req.db).filter(\.$id == idparam).first() else {
            throw Abort(.custom(code: 200, reasonPhrase: "Requested task not found"))
        }

        return task
    }

    // Update
    struct taskpatchquery: Content {
        var name: String?
        var category: UUID?
    }
    tasksRoute.patch(":id") { (req: Request) async throws -> Task in
        guard let idparam: UUID = try? req.parameters.get("id") else {
            throw Abort(.custom(code: 422, reasonPhrase: "Provided ID is not in a valid UUID format"))
        }
        guard let task: Task = try? await Task.query(on: req.db).filter(\.$id == idparam).first() else {
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
        guard let task: Task = try? await Task.query(on: req.db).filter(\.$id == idparam).first() else {
            throw Abort(.custom(code: 200, reasonPhrase: "Requested task not found"))
        }
        guard let taskdeleted: () = try? await task.delete(on: req.db) else {
            throw Abort(.custom(code: 500, reasonPhrase: "Request valid but unable to delete task in database"))
        }

        return task
    }

}
