import SwiftUI

struct ElementCellView: View {
    let element: String
    let symbol: String
    let atomicNumber: Int
    let atomicMass: String
    let block: String
    
    var body: some View {
        VStack {
            HStack {
                Text("\(atomicNumber)")
                    .bold()
                Spacer()
                Text(atomicMass)
            }
    
            Text(symbol)
                .fontWeight(.bold)
                .font(.system(size: 45))
            
            Text(element)
        }
        .foregroundStyle(.white)
        .padding(10)
        .frame(width: 100, height: 100)
        .font(.footnote)
        .background(ElementColor.color(for: block).gradient.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 15.0))
    }
}
