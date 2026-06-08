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
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    
                    VStack(alignment: .leading, spacing: 6) {
                        
                        Text("Dinner Planner")
                            .font(.largeTitle.bold())
                        
                        Text("Pick saved dinners or type a simple meal for the week.")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        
                        Label("\(plannedCount)", systemImage: "fork.knife")
                        
                        Spacer()
                        
                        Text("\(7 - plannedCount) days open")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline.bold())
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    ForEach(days, id: \.self) { day in
                        dayCard(day)
                    }
                }
                .padding(.vertical)
            }
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
    
    private func dayCard(_ day: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text(day)
                .font(.title3.bold())
            
            Picker("Saved Dinner", selection: savedDinnerBinding(for: day)) {
                Text("No saved dinner").tag(UUID?.none)
                
                ForEach(store.dinners) { dinner in
                    Text(dinner.name).tag(UUID?.some(dinner.id))
                }
            }
            
            TextField("Or type something simple, like tacos", text: manualMealBinding(for: day))
                .textFieldStyle(.roundedBorder)
            
            if let dinner = dinnerFor(day) {
                NavigationLink {
                    DinnerDetailView(dinner: dinner, store: store)
                } label: {
                    Label("View \(dinner.name)", systemImage: "fork.knife")
                        .font(.headline)
                }
            } else if !manualMeal(for: day).isEmpty {
                Label(manualMeal(for: day), systemImage: "pencil")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal)
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
    
    private var plannedCount: Int {
        
        days.filter { day in
            
            let meal = weeklyPlan[day]
            
            return meal?.savedDinnerID != nil ||
            !(meal?.manualMealName ?? "").isEmpty
        }
        .count
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
