//
//  ContentView.swift
//  Elementum
//
//  Created by Test on 29/01/25.
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationView {
            ZStack {
                
                VStack(alignment: .leading, spacing: 50) {
                    
                    Text("Elementum")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    // Placeholder rectangles
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.darkGray)) // Use darkGray for rectangles
                            .frame(height: 80)
                    }
                    
                    Spacer() // Push content to the top
                    
                    // Bottom navigation bar
                    HStack {
                        Button(action: {}) {
                            Text("Home")
                                .foregroundColor(.blue)
                        }
                        Spacer()
                        Button(action: {}) {
                            Text("Blocks")
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: {}) {
                            Text("Combination")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom)
                    
                }
                .padding(.horizontal)
            }
            .navigationBarHidden(true) // Hide the default navigation bar
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
