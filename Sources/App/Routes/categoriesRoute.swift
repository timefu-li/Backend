import Vapor
import Fluent

func initCategoriesRoute(_ app: Application) throws {

    let categoriesRoute = app.grouped("categories")

    // Create
    categoriesRoute.post(use: { (req: Request) async throws -> Category in
        guard let categorymodel: Category = try? req.content.decode(Category.self) else {
            throw Abort(.custom(code: 422, reasonPhrase: "Request body sent by user is invalid"))
        }
        guard let categorycreated: () = try? await categorymodel.create(on: req.db) else {
            throw Abort(.custom(code: 500, reasonPhrase: "Request valid but unable to add new category to database"))
        }

        return categorymodel
    })

    // Read
    struct categorygetquery: Content {
        let preload: Bool? // Preload all tasks information linked to this category
    }
    categoriesRoute.get(use: { (req: Request) async throws -> [Category] in
        var preload: Bool = true
        if let query: categorygetquery = try? req.query.decode(categorygetquery.self) {
            if let querypreloadunwrapped = query.preload {
                preload = querypreloadunwrapped
            }
        }

        guard let categoriesQueryBuilder: QueryBuilder<Category> = try? Category
                                                                        .query(on: req.db)
        else {
            throw Abort(.custom(code: 500, reasonPhrase: "Failed to query categories"))
        }
        guard let categories: [Category] = preload ? try? await categoriesQueryBuilder
                                                                        .with(\.$tasks)
                                                                        .all()
                                                    : try? await categoriesQueryBuilder
                                                                        .all() 
        else {
            throw Abort(.custom(code: 200, reasonPhrase: "No categories found"))
        }

        return categories
    })

    // Read Single
    categoriesRoute.get(":id", use: { (req: Request) async throws -> Category in
        var preload: Bool = true
        if let query: categorygetquery = try? req.query.decode(categorygetquery.self) {
            if let querypreloadunwrapped = query.preload {
                preload = querypreloadunwrapped
            }
        }

        guard let idparam: UUID = try? req.parameters.get("id") else {
            throw Abort(.custom(code: 422, reasonPhrase: "Provided ID is not in a valid UUID format"))
        }

        guard let categoriesQueryBuilder: QueryBuilder<Category> = try? Category
                                                                        .query(on: req.db) 
        else {
            throw Abort(.custom(code: 500, reasonPhrase: "Failed to query categories"))
        }
        guard let category: Category = preload ? try? await categoriesQueryBuilder
                                                            .with(\.$tasks)
                                                            .filter(\.$id == idparam)
                                                            .first()
                                                : try? await categoriesQueryBuilder
                                                            .filter(\.$id == idparam)
                                                            .first() 
        else {
            throw Abort(.custom(code: 200, reasonPhrase: "No categories found"))
        }

        return category
    })

    // Update
    struct categorypatchquery: Content {
        let name: String?
        let emoji: String?
        let colour: String?
    }
    categoriesRoute.patch(":id", use: { (req: Request) async throws -> Category in
        guard let idparam: UUID = try? req.parameters.get("id") else {
            throw Abort(.custom(code: 422, reasonPhrase: "Provided ID is not in a valid UUID format"))
        }
        guard let category: Category = try? await Category
                                                    .query(on: req.db)
                                                    .filter(\.$id == idparam)
                                                    .first() 
        else {
            throw Abort(.custom(code: 200, reasonPhrase: "Requested category not found"))
        }

        guard let query: categorypatchquery = try? req.query.decode(categorypatchquery.self) else {
            throw Abort(.custom(code: 422, reasonPhrase: "Request queries sent by user is invalid"))
        }
        // TODO: I don't like how manual this is so maybe needs some custom function to iterate over the content struct, but it's simple and it works
        if let unwrappedquery = query.name {
            category.name = unwrappedquery
        }
        if let unwrappedquery = query.emoji {
            category.emoji = unwrappedquery
        }
        if let unwrappedquery = query.colour {
            category.colour = unwrappedquery
        }

        guard let taskupdated: () = try? await category.update(on: req.db) else {
            throw Abort(.custom(code: 500, reasonPhrase: "Request valid but unable to update task in database"))
        }

        return category
    })

    // Delete
    categoriesRoute.delete(":id", use: { (req: Request) async throws -> Category in
        guard let idparam: UUID = try? req.parameters.get("id") else {
            throw Abort(.custom(code: 422, reasonPhrase: "Provided ID is not in a valid UUID format"))
        }
        guard let category: Category = try? await Category
                                                    .query(on: req.db)
                                                    .filter(\.$id == idparam)
                                                    .first() else {
            throw Abort(.custom(code: 200, reasonPhrase: "Requested category not found"))
        }
        guard let categorydeleted: () = try? await category.delete(on: req.db) else {
            throw Abort(.custom(code: 500, reasonPhrase: "Request valid but unable to delete category in database"))
        }

        return category
    })

}
