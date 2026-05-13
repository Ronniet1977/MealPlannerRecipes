import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            
            NavigationStack {
                VideoImporterView()
                    .navigationTitle("Recipe Catcher")
            }
            .tabItem {
                Label("Scan", systemImage: "camera")
            }
            
            SavedDinnersView()
                .tabItem {
                    Label("Dinners", systemImage: "fork.knife")
                }
            
            DinnerPlannerView()
                .tabItem {
                    Label("Planner", systemImage: "calendar")
                }
        }
    }
}
// new commit
