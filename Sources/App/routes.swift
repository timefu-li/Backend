import Vapor
import Fluent

func routes(_ app: Application) throws {

    app.get("tasks") { (req: Request) async throws -> [Task] in
        guard let tasks: [Task] = try? await Task.query(on: req.db).all() else {
            throw Abort(.custom(code: 200, reasonPhrase: "No tasks found"))
        }

        return tasks
    }

    app.get("tasks", ":id") { (req: Request) async throws -> Task in
        guard let idparam: UUID = try? req.parameters.get("id") else {
            throw Abort(.custom(code: 422, reasonPhrase: "Provided ID is not in a valid UUID format"))
        }
        guard let task: Task = try? await Task.query(on: req.db).filter(\.$id == idparam).first() else {
            throw Abort(.custom(code: 200, reasonPhrase: "Requested task not found"))
        }

        return task
    }

    app.post("tasks") { (req: Request) async throws -> Task in
        guard let taskmodel: Task = try? req.content.decode(Task.self) else {
            throw Abort(.custom(code: 422, reasonPhrase: "Request body sent by user is invalid"))
        }
        guard let taskcreated: () = try? await taskmodel.create(on: req.db) else {
            throw Abort(.custom(code: 500, reasonPhrase: "Request body valid but unable to add new task to database"))
        }

        return taskmodel
    }


}
