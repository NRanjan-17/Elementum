import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack {
                ScrollView{
                    NavigationLink(destination: S_Group(text: "View 1 Details")) {
                        ImageButton(image: "PeriodicTable", text: "Periodic Table")
                    }
                    .padding()
                    
                    NavigationLink(destination: S_Group(text: "View 2 Details")) {
                        ImageButton(image: "pencil", text: "S Group Elements")
                    }
                    .padding()
                    
                    NavigationLink(destination: S_Group(text: "View 3 Details")) {
                        ImageButton(image: "heart", text: "P Group Elements")
                    }
                    .padding()
                    
                    NavigationLink(destination: S_Group(text: "View 4 Details")) {
                        ImageButton(image: "heart", text: "D Group Elements")
                    }
                    .padding()
                    NavigationLink(destination: S_Group(text: "View 4 Details")) {
                        ImageButton(image: "heart", text: "F Group Elements")
                    }
                    .padding()
                    
                }
            }
            .navigationTitle("Elementum")
        }
    }
}

struct ImageButton: View {
    let image: String
    let text: String
    
    var body: some View {
        ZStack {
            Image(systemName: image)
                .resizable()
                .scaledToFill()
                .clipped()
                .overlay(
                    Color.black.opacity(0.2)
                )
            
            
            Text(text)
                .foregroundColor(.white)
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(width: 350, height: 150)
        .cornerRadius(10)
    }
}
