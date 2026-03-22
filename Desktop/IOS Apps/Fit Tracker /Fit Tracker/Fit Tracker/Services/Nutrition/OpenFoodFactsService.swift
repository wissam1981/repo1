import Foundation

// MARK: - Open Food Facts API Service
// Free, open-source global food database for barcode lookups.
// API docs: https://wiki.openfoodfacts.org/API

enum OpenFoodFactsService {

    /// Look up a product by barcode (EAN/UPC).
    /// Returns nil when the product isn't in the database.
    static func searchByBarcode(_ barcode: String) async -> FoodItem? {
        let urlString = "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=product_name,brands,nutriments,serving_size,serving_quantity"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("FuelIQ iOS App", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

            let decoded = try JSONDecoder().decode(OFFResponse.self, from: data)
            guard decoded.status == 1, let product = decoded.product else { return nil }

            return product.toFoodItem(barcode: barcode)
        } catch {
            print("[OpenFoodFacts] Lookup failed: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Response Models

private struct OFFResponse: Decodable {
    let status: Int           // 1 = found, 0 = not found
    let product: OFFProduct?
}

private struct OFFProduct: Decodable {
    let product_name: String?
    let brands: String?
    let serving_size: String?
    let serving_quantity: Double?
    let nutriments: OFFNutriments?

    func toFoodItem(barcode: String) -> FoodItem? {
        let name = product_name ?? "Unknown Product"
        guard let n = nutriments else { return nil }

        // Prefer per-serving values, fall back to per-100g
        let hasServing = (n.energy_kcal_serving ?? 0) > 0
        let servingG = serving_quantity ?? 100

        let cal   = hasServing ? (n.energy_kcal_serving ?? 0) : (n.energy_kcal_100g ?? 0)
        let prot  = hasServing ? (n.proteins_serving ?? 0)    : (n.proteins_100g ?? 0)
        let carbs = hasServing ? (n.carbohydrates_serving ?? 0) : (n.carbohydrates_100g ?? 0)
        let fat   = hasServing ? (n.fat_serving ?? 0)         : (n.fat_100g ?? 0)
        let fiber = hasServing ? (n.fiber_serving ?? 0)       : (n.fiber_100g ?? 0)
        let sugar = hasServing ? n.sugars_serving             : n.sugars_100g
        let sodium = hasServing ? n.sodium_serving            : n.sodium_100g

        // Skip if all macros are zero (bad data)
        guard cal > 0 || prot > 0 || carbs > 0 || fat > 0 else { return nil }

        return FoodItem(
            id: "off_\(barcode)",
            name: name,
            brandName: brands,
            barcode: barcode,
            servingSizeG: hasServing ? servingG : 100,
            servingUnit: "g",
            calories: cal,
            proteinG: prot,
            carbsG: carbs,
            fatG: fat,
            fiberG: fiber,
            sugarG: sugar,
            sodiumMg: sodium.map { $0 * 1000 }, // OFF stores sodium in g, convert to mg
            isVerified: false,
            isCustom: false,
            source: .community
        )
    }
}

private struct OFFNutriments: Decodable {
    // Per 100g
    let energy_kcal_100g: Double?
    let proteins_100g: Double?
    let carbohydrates_100g: Double?
    let fat_100g: Double?
    let fiber_100g: Double?
    let sugars_100g: Double?
    let sodium_100g: Double?

    // Per serving
    let energy_kcal_serving: Double?
    let proteins_serving: Double?
    let carbohydrates_serving: Double?
    let fat_serving: Double?
    let fiber_serving: Double?
    let sugars_serving: Double?
    let sodium_serving: Double?

    enum CodingKeys: String, CodingKey {
        case energy_kcal_100g = "energy-kcal_100g"
        case proteins_100g
        case carbohydrates_100g
        case fat_100g
        case fiber_100g
        case sugars_100g
        case sodium_100g

        case energy_kcal_serving = "energy-kcal_serving"
        case proteins_serving
        case carbohydrates_serving
        case fat_serving
        case fiber_serving
        case sugars_serving
        case sodium_serving
    }
}
