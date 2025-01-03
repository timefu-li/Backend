import Vapor
import VaporToOpenAPI
import Fluent

func initCategoriesRoute(_ app: Application) throws {

    let categoriesRoute = app.grouped("categories")

    // Create
    categoriesRoute.post(use: { (req: Request) async throws -> Category in
        guard let categorymodel: Category = try? req.content.decode(Category.self) else {
            throw Abort(.custom(code: 400, reasonPhrase: "INVALIDREQUESTBODY:Request body sent by user is invalid"))
        }
        guard let categorycreated: () = try? await categorymodel.create(on: req.db) else {
            throw Abort(.custom(code: 500, reasonPhrase: "INTERNALSERVERERROR:Request valid but unable to add new category to database"))
        }

        return categorymodel
    }).openAPI(
        summary: "Create a category",
        description: "Create a new category with the provided data",
        body: .type(Category.self),
        response: .type(Category.self)
    )

    // Read All
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
            throw Abort(.custom(code: 500, reasonPhrase: "INTERNALSERVERERROR:Failed to query categories"))
        }

        guard let categories: [Category] = try? await categoriesQueryBuilder
            .preloadAssociationData(preload: preload) // Check if we need to preload all data
            .all()
        else {
            throw Abort(.custom(code: 200, reasonPhrase: "NOTFOUND:No categories found"))
        }

        return categories
    }).openAPI(
        summary: "Get all categories",
        description: "Get an array of all categories currently in the database",
        response: .type([Category].self)
    )

    // Read Single
    categoriesRoute.get(":id", use: { (req: Request) async throws -> Category in
        var preload: Bool = true
        if let query: categorygetquery = try? req.query.decode(categorygetquery.self) {
            if let querypreloadunwrapped = query.preload {
                preload = querypreloadunwrapped
            }
        }

        guard let idparam: UUID = try? req.parameters.get("id") else {
            throw Abort(.custom(code: 400, reasonPhrase: "INVALIDID:Provided ID is not in a valid UUID format"))
        }

        guard let categoriesQueryBuilder: QueryBuilder<Category> = try? Category
            .query(on: req.db) 
        else {
            throw Abort(.custom(code: 500, reasonPhrase: "INTERNALSERVERERROR:Failed to query categories"))
        }

        guard let category: Category = try? await categoriesQueryBuilder
            .preloadAssociationData(preload: preload) // Check if we need to preload all data
            .filter(\.$id == idparam)
            .first()
        else {
            throw Abort(.custom(code: 200, reasonPhrase: "NOTFOUND:No categories found"))
        }

        return category
    }).openAPI(
        summary: "Get category",
        description: "Get a specific category based on the ID",
        response: .type(Category.self)
    )

    // Update
    struct categorypatchquery: Content {
        let name: String?
        let emoji: String?
        let colour: ColourRGB?
    }
    categoriesRoute.patch(":id", use: { (req: Request) async throws -> Category in
        guard let idparam: UUID = try? req.parameters.get("id") else {
            throw Abort(.custom(code: 400, reasonPhrase: "INVALIDID:Provided ID is not in a valid UUID format"))
        }
        guard let category: Category = try? await Category
            .query(on: req.db)
            .filter(\.$id == idparam)
            .first() 
        else {
            throw Abort(.custom(code: 200, reasonPhrase: "NOTFOUND:Requested category not found"))
        }

        guard let query: categorypatchquery = try? req.query.decode(categorypatchquery.self) else {
            throw Abort(.custom(code: 400, reasonPhrase: "INVALIDREQUESTQUERY:Request queries sent by user is invalid"))
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
            throw Abort(.custom(code: 500, reasonPhrase: "INTERNALSERVERERROR:Request valid but unable to update task in database"))
        }

        return category
    }).openAPI(
        summary: "Update category",
        description: "Update a specific category based on the ID",
        response: .type(Category.self)
    )

    // Delete
    categoriesRoute.delete(":id", use: { (req: Request) async throws -> Category in
        guard let idparam: UUID = try? req.parameters.get("id") else {
            throw Abort(.custom(code: 400, reasonPhrase: "INVALIDID:Provided ID is not in a valid UUID format"))
        }

        guard let categoriesQueryBuilder: QueryBuilder<Category> = try? Category
            .query(on: req.db)
        else {
            throw Abort(.custom(code: 500, reasonPhrase: "INTERNALSERVERERROR:Failed to query categories"))
        }

        guard let category: Category = try? await categoriesQueryBuilder
            .preloadAssociationData(preload: true)
            .filter(\.$id == idparam)
            .first()
        else {
            throw Abort(.custom(code: 200, reasonPhrase: "NOTFOUND:Requested category not found"))
        }

        if (category.tasks.count != 0) {
            throw Abort(.custom(code: 500, reasonPhrase: "REFERENCEFOUND:Currently tasks referencing this category. Please remove all references to this task."))
        }

        guard let categorydeleted: () = try? await category.delete(on: req.db) else {
            throw Abort(.custom(code: 500, reasonPhrase: "INTERNALSERVERERROR:Request valid but unable to delete category in database"))
        }

        return category
    }).openAPI(
        summary: "Delete category",
        description: "Delete a specific category based on the ID",
        response: .type(Category.self)
    )

}
