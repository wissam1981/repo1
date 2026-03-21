import SwiftUI

// MARK: - Custom Food View
// Allows user to create a custom food item with manual macro entry.

struct CustomFoodView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (FoodItem) -> Void

    let initialFood: FoodItem?

    @State private var name: String
    @State private var brandName: String
    @State private var servingSize: Double
    @State private var servingUnit: String
    @State private var calories: Double
    @State private var protein: Double
    @State private var carbs: Double
    @State private var fat: Double
    @State private var fiber: Double

    init(initialFood: FoodItem? = nil, onSave: @escaping (FoodItem) -> Void) {
        self.initialFood = initialFood
        self.onSave = onSave
        
        if let food = initialFood {
            self._name = State(initialValue: food.name)
            self._brandName = State(initialValue: food.brandName ?? "")
            self._servingSize = State(initialValue: food.servingSizeG)
            self._servingUnit = State(initialValue: food.servingUnit)
            self._calories = State(initialValue: food.calories)
            self._protein = State(initialValue: food.proteinG)
            self._carbs = State(initialValue: food.carbsG)
            self._fat = State(initialValue: food.fatG)
            self._fiber = State(initialValue: food.fiberG)
        } else {
            self._name = State(initialValue: "")
            self._brandName = State(initialValue: "")
            self._servingSize = State(initialValue: 100)
            self._servingUnit = State(initialValue: "g")
            self._calories = State(initialValue: 0)
            self._protein = State(initialValue: 0)
            self._carbs = State(initialValue: 0)
            self._fat = State(initialValue: 0)
            self._fiber = State(initialValue: 0)
        }
    }

    private let servingUnits = ["g", "ml", "oz", "cup", "piece", "tbsp", "tsp"]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && servingSize > 0 && calories > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section("Food Info") {
                    TextField("Food Name *", text: $name)
                    TextField("Brand (optional)", text: $brandName)
                }

                // Serving
                Section("Serving") {
                    HStack {
                        Text("Size")
                        Spacer()
                        TextField("100", value: $servingSize, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    Picker("Unit", selection: $servingUnit) {
                        ForEach(servingUnits, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                }

                // Nutrition per serving
                Section("Nutrition (per serving)") {
                    macroField(label: "Calories *", value: $calories, unit: "kcal")
                    macroField(label: "Protein", value: $protein, unit: "g")
                    macroField(label: "Carbs", value: $carbs, unit: "g")
                    macroField(label: "Fat", value: $fat, unit: "g")
                    macroField(label: "Fiber", value: $fiber, unit: "g")
                }

                // Preview
                if isValid {
                    Section("Preview") {
                        HStack {
                            Text(name)
                                .font(.headline)
                            Spacer()
                            Text("\(Int(calories)) kcal")
                                .foregroundStyle(.cyan)
                        }
                        HStack(spacing: 16) {
                            Text("P: \(Int(protein))g").foregroundStyle(.orange)
                            Text("C: \(Int(carbs))g").foregroundStyle(.green)
                            Text("F: \(Int(fat))g").foregroundStyle(.purple)
                        }
                        .font(.caption)
                    }
                }
            }
            .navigationTitle(initialFood != nil ? "Edit Food" : "Custom Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveFood()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - Macro Field

    private func macroField(label: String, value: Binding<Double>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .leading)
        }
    }

    // MARK: - Save

    private func saveFood() {
        let food = FoodItem(
            id: initialFood?.id ?? UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespaces),
            brandName: brandName.isEmpty ? nil : brandName.trimmingCharacters(in: .whitespaces),
            barcode: initialFood?.barcode,
            fdcId: initialFood?.fdcId,
            servingSizeG: servingSize,
            servingUnit: servingUnit,
            calories: calories,
            proteinG: protein,
            carbsG: carbs,
            fatG: fat,
            fiberG: fiber,
            sugarG: initialFood?.sugarG,
            sodiumMg: initialFood?.sodiumMg,
            isVerified: initialFood?.isVerified ?? false,
            isCustom: true,
            source: initialFood?.source ?? .custom
        )
        onSave(food)
    }
}
