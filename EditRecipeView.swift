//
//  EditRecipeView.swift
//  MealPlannerRecipes
//
//  Created by Ronald Thayer Jr on 4/30/26.
//

import SwiftUI

struct EditRecipeView: View {
    
    @Binding var recipeText: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            TextEditor(text: $recipeText)
                .padding()
                .navigationTitle("Edit Recipe")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
