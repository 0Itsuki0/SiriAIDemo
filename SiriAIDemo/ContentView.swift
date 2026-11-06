//
//  ContentView.swift
//  SiriAIDemo
//
//  Created by Itsuki on 2026/11/04.
//

import AppIntents
import SwiftUI

// MARK: - App Entity
enum GroceryType: String, AppEnum {
    case vegetable
    case fruit

    static let typeDisplayRepresentation: TypeDisplayRepresentation =
        "Grocery Type"

    static let caseDisplayRepresentations:
        [GroceryType: DisplayRepresentation] = [
            .fruit: "Fruit", .vegetable: "Vegetable",
        ]
}

struct GroceryEntity: IndexedEntity, Hashable {

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Grocery"
    static let defaultQuery = GroceryEntityQuery()

    let id: String
    @Property(title: "grocery name", description: "The name of the grocery") var name: String
    @Property(title: "grocery type", description: "The type of the grocery") var type: GroceryType

    init(id: String, name: String, type: GroceryType) {
        self.id = id
        self.name = name
        self.type = type
    }

    static func == (lhs: GroceryEntity, rhs: GroceryEntity) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self)
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: type.localizedStringResource,
        )
    }

    struct GroceryEntityQuery: EntityQuery {
        @Dependency
        var manager: GroceryManager

        func entities(for identifiers: [GroceryEntity.ID]) async throws
            -> [GroceryEntity]
        {
            return await manager.groceries(for: identifiers)
        }
    }
}

extension GroceryEntity {
    static var all: [GroceryEntity] {
        let nameType: [(String, GroceryType)] = [
            ("apple", .fruit),
            ("asparagus", .vegetable),
            ("banana", .fruit),
            ("cabbage", .vegetable),
            ("carrot", .vegetable),
            ("grape", .fruit),
            ("kiwi", .fruit),
            ("onion", .vegetable),
            ("peach", .fruit),
            ("potato", .vegetable),
            ("pumpkin", .vegetable),
            ("spinach", .vegetable),
            ("watermelon", .fruit),
        ]

        return nameType.map {
            GroceryEntity(id: $0.0, name: $0.0, type: $0.1)
        }
    }
}

@AppIntent(.tool)
struct AddGrocery {
    static let title: LocalizedStringResource = "Add to Cart"
    static let description = IntentDescription(
        LocalizedStringResource("Adds a product to the shopping cart.")
    )

    @Parameter(
        title: "Item",
        description: LocalizedStringResource("The product to add")
    )
    var item: GroceryEntity

    @Parameter(
        title: "Quantity",
        description: LocalizedStringResource("How many to add"),
        default: 1
    )
    var quantity: Int

    @Dependency
    private var manager: GroceryManager

    func perform() async throws -> some IntentResult {
        print("AddGrocery", #function)
        await manager.addToCart(item, count: quantity)
        return .result()
    }
}

@AppIntent(.tool)
struct OpenCheckout: OpenIntent {
    static let title: LocalizedStringResource = "Open checkout."
    static let description: LocalizedStringResource = "Open the checkout page to finish purchase."

    @Dependency var manager: GroceryManager

    @Parameter(title: "Route", description: "In app route (page) to open.")
    var target: AppRoute

    func perform() async throws -> some IntentResult {
        print("OpenCheckout", #function)
        await manager.checkout()
        return .result()
    }
}

enum AppRoute: String, AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "App view"

    static let caseDisplayRepresentations: [AppRoute: DisplayRepresentation] = [
        .checkout: "Checkout"
    ]

    case checkout
}

// MARK: - Manager
@Observable
class GroceryManager {
    var selectedRoute: AppRoute?

    private(set) var groceries: [GroceryEntity] = GroceryEntity.all

    private(set) var cart: [GroceryEntity: Int] = [:]

    init() {}

    func checkout() {
        self.selectedRoute = .checkout
    }

    func groceries(for identifiers: [GroceryEntity.ID]) -> [GroceryEntity] {
        return self.groceries.filter({ grocery in
            identifiers.contains(grocery.id)
        })
    }

    @discardableResult
    func addToCart(_ grocery: GroceryEntity, count: Int) -> [GroceryEntity: Int]
    {
        self.cart[grocery] = (self.cart[grocery] ?? 0) + count
        return self.cart
    }
}

// MARK: - SwiftUI View
struct ContentView: View {
    @Environment(GroceryManager.self) private var manager

    var body: some View {
        @Bindable var manager = manager
        NavigationStack {
            VStack {
                Text("Tell Siri to add some Groceries and checkout!")

            }
            .navigationDestination(
                item: $manager.selectedRoute,
                destination: { route in
                    CheckoutView()
                        .environment(manager)
                }
            )
        }
    }
}

private struct CheckoutView: View {
    @Environment(GroceryManager.self) private var manager

    var body: some View {
        List {
            if manager.cart.isEmpty {
                Text("Nothing in cart yet!")
            }
            ForEach(Array(manager.cart.keys)) { grocery in
                let count = manager.cart[grocery] ?? 0
                LabeledContent(grocery.name, value: count.formatted())
            }
        }
        .navigationTitle("Checkout")
    }
}
