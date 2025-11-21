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
    
    // Detect the device's width class (iPad vs iPhone)
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        ZStack {
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, minHeight: 150)
                .clipped()
                .overlay(
                    Color.black.opacity(0.2)
                )
            
            
            Text(text)
                .foregroundColor(.white)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        // Logic: If iPad/Desktop (Regular), use 25. If iPhone (Compact), use 12.5.
        // We also use 'style: .continuous' for that smooth Apple look.
        .clipShape(RoundedRectangle(cornerRadius: sizeClass == .regular ? 25 : 12.5, style: .continuous))
    }
}


