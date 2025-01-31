import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: .constant(""))
                ScrollView{
                    NavigationLink(destination: S_Group(text: "View 1 Details")) {
                        ImageButton(image: "PeriodicTable", text: "View 1")
                    }
                    .padding()
                    
                    NavigationLink(destination: S_Group(text: "View 2 Details")) {
                        ImageButton(image: "pencil", text: "View 2")
                    }
                    .padding()
                    
                    NavigationLink(destination: S_Group(text: "View 3 Details")) {
                        ImageButton(image: "heart", text: "View 3")
                    }
                    .padding()
                    
                    NavigationLink(destination: S_Group(text: "View 4 Details")) {
                        ImageButton(image: "heart", text: "View 4")
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
                .frame(width:350, height:150)
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

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        TextField("Search for Elements", text: $text)
            .padding(8)
            .frame(width: 375)
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }
}


#Preview {
    HomeView()
}
