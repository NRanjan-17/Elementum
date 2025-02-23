import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack {
                ScrollView{
                    NavigationLink(destination: Elements()) {
                        ImageButton(image: "Table", text: "Periodic Table")
                    }
                    .padding()
                    
                    NavigationLink(destination: S_Group()) {
                        ImageButton(image: "S_Block", text: "S Group Elements")
                    }
                    .padding()
                    
                    NavigationLink(destination: P_Group()) {
                        ImageButton(image: "P_Block", text: "P Group Elements")
                    }
                    .padding()
                    
                    NavigationLink(destination: D_Group()) {
                        ImageButton(image: "D_Block", text: "D Group Elements")
                    }
                    .padding()
                    NavigationLink(destination: F_Group()) {
                        ImageButton(image: "F_Block", text: "F Group Elements")
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
            Image(image)
                .resizable()
                .scaledToFill()
                .clipped()
                .overlay(
                    Color.black.opacity(0.2)
                )
            
            
            Text(text)
                .foregroundColor(.white)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(width: 350, height: 150)
        .cornerRadius(10)
    }
}


