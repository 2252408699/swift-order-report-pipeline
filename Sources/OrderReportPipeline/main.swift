import Foundation

struct LineItem: Codable {
    let name: String
    let category: String
    let unitPriceCents: Int
    let quantity: Int
}

struct Order: Codable {
    let id: String
    let status: String
    let customerEmail: String?
    let items: [LineItem]
}

struct OrderRow: Equatable {
    let id: String
    let itemCount: Int
    let totalCents: Int
}

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
    print("PASS: \(message)")
}

let json = #"""
[
  {
    "id": "A-100",
    "status": "paid",
    "customerEmail": "ana@example.com",
    "items": [
      {"name": "House Beans", "category": "coffee", "unitPriceCents": 1299, "quantity": 2},
      {"name": "Paper Filters", "category": "accessories", "unitPriceCents": 799, "quantity": 1}
    ]
  },
  {
    "id": "A-101",
    "status": "refunded",
    "customerEmail": "refund@example.com",
    "items": [
      {"name": "Travel Mug", "category": "accessories", "unitPriceCents": 1899, "quantity": 1}
    ]
  },
  {
    "id": "A-102",
    "status": "paid",
    "customerEmail": null,
    "items": [
      {"name": "Hand Grinder", "category": "equipment", "unitPriceCents": 4999, "quantity": 1},
      {"name": "Paper Filters", "category": "accessories", "unitPriceCents": 799, "quantity": 1}
    ]
  }
]
"""#

let orders = try JSONDecoder().decode([Order].self, from: Data(json.utf8))

let paidOrders = orders.filter { $0.status == "paid" }

let rows = paidOrders.map { order in
    OrderRow(
        id: order.id,
        itemCount: order.items.reduce(0) { $0 + $1.quantity },
        totalCents: order.items.reduce(0) { $0 + ($1.unitPriceCents * $1.quantity) }
    )
}

let paidItems = paidOrders.flatMap(\.items)

let emailDomains = paidOrders.compactMap { order -> String? in
    guard let email = order.customerEmail,
          let atIndex = email.lastIndex(of: "@") else { return nil }
    return String(email[email.index(after: atIndex)...])
}

let grossCents = paidItems.reduce(0) {
    $0 + ($1.unitPriceCents * $1.quantity)
}

let quantityByCategory = paidItems.reduce(into: [String: Int]()) { totals, item in
    totals[item.category, default: 0] += item.quantity
}

check(orders.count == 3, "JSON decoder loads all orders")
check(paidOrders.map(\.id) == ["A-100", "A-102"], "filter keeps only paid orders")
check(rows.count == 2, "map creates one report row per paid order")
check(rows[0] == OrderRow(id: "A-100", itemCount: 3, totalCents: 3397), "first report row is correct")
check(paidItems.count == 4, "flatMap produces one item sequence")
check(emailDomains == ["example.com"], "compactMap drops missing email values")
check(grossCents == 9195, "reduce calculates gross revenue in cents")
check(quantityByCategory == ["coffee": 2, "accessories": 2, "equipment": 1], "reduce(into:) groups quantities")

print("Paid order rows: \(rows)")
print("Gross revenue: $\(String(format: "%.2f", Double(grossCents) / 100))")
print("All order report checks passed.")
