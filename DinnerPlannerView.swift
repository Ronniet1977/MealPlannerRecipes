import SwiftUI

struct PlannedMeal: Codable {
    var savedDinnerID: UUID?
    var manualMealName: String = ""
}

struct DinnerPlannerView: View {
    
    @StateObject private var store = DinnerStore()
    @AppStorage("weeklyMealPlanData") private var weeklyPlanData = Data()
    
    @State private var weeklyPlan: [String: PlannedMeal] = [:]
    
    private let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(days, id: \.self) { day in
                    ForEach(days, id: \.self) { day in
                        Section(day) {
                            Picker("Saved Dinner", selection: savedDinnerBinding(for: day)) {
                                Text("None").tag(UUID?.none)
                                
                                ForEach(store.dinners) { dinner in
                                    Text(dinner.name).tag(UUID?.some(dinner.id))
                                }
                            }
                            
                            TextField("Or type manual meal", text: manualMealBinding(for: day))
                            
                            if let dinner = dinnerFor(day) {
                                NavigationLink("View \(dinner.name)") {
                                    DinnerDetailView(dinner: dinner, store: store)
                                }
                            } else if !manualMeal(for: day).isEmpty {
                                Text("Planned: \(manualMeal(for: day))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                weeklyPlan[day] = PlannedMeal()
                                savePlan()
                            } label: {
                                Label("Clear", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Dinner Planner")
            .toolbar {
                Button("Clear") {
                    weeklyPlan = [:]
                    savePlan()
                }
            }
            .onAppear {
                store.loadDinners()
                loadPlan()
            }
        }
    }
    
    private func savedDinnerBinding(for day: String) -> Binding<UUID?> {
        Binding(
            get: {
                weeklyPlan[day]?.savedDinnerID
            },
            set: { newValue in
                var meal = weeklyPlan[day] ?? PlannedMeal()
                meal.savedDinnerID = newValue
                
                if newValue != nil {
                    meal.manualMealName = ""
                }
                
                weeklyPlan[day] = meal
                savePlan()
            }
        )
    }
    
    private func manualMealBinding(for day: String) -> Binding<String> {
        Binding(
            get: {
                weeklyPlan[day]?.manualMealName ?? ""
            },
            set: { newValue in
                var meal = weeklyPlan[day] ?? PlannedMeal()
                meal.manualMealName = newValue
                
                if !newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                    meal.savedDinnerID = nil
                }
                
                weeklyPlan[day] = meal
                savePlan()
            }
        )
    }
    
    private func dinnerFor(_ day: String) -> SavedDinner? {
        guard let id = weeklyPlan[day]?.savedDinnerID else { return nil }
        return store.dinners.first { $0.id == id }
    }
    
    private func manualMeal(for day: String) -> String {
        weeklyPlan[day]?.manualMealName ?? ""
    }
    
    private func savePlan() {
        if let data = try? JSONEncoder().encode(weeklyPlan) {
            weeklyPlanData = data
        }
    }
    
    private func loadPlan() {
        if let decoded = try? JSONDecoder().decode([String: PlannedMeal].self, from: weeklyPlanData) {
            weeklyPlan = decoded
        }
    }
}
