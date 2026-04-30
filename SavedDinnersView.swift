import SwiftUI

struct SavedDinnersView: View {
    
    @StateObject private var store = DinnerStore()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.dinners) { dinner in
                    NavigationLink {
                        DinnerDetailView(dinner: dinner, store: store)
                    } label: {
                        HStack {
                            Text(dinner.name)
                            Spacer()
                            if dinner.isFavorite {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        store.delete(store.dinners[index])
                    }
                }
            }
            .navigationTitle("Saved Dinners")
            .toolbar {
                EditButton()
            }
            .onAppear {
                store.loadDinners()
            }
        }
    }
}
