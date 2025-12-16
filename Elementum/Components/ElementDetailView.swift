import SwiftUI

struct ElementDetailView: View {
    @Environment(\.dismiss) private var dismiss
    var element: Element
    var animation: Namespace.ID
    
    var body: some View {
        List {
            Button {
                dismiss()
            } label: {
                ElementCellView(element: element.element, symbol: element.symbol, atomicNumber: element.id, atomicMass: "\(element.mass)", block: element.block)
            }
            .matchedTransitionSource(id: element.id, in: animation)
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowBackground(Color.clear)
            
            Section("General") {
                Group {
                    LabeledContent("Name", value: element.element)
                    LabeledContent("Symbol", value: element.symbol)
                    LabeledContent("Atomic Number", value: "\(element.id)")
                    LabeledContent("Atomic Mass", value: "\(element.mass) u")
                }
                .textSelection(.enabled)
            }
            
            Section("Scientific Properties") {
                Group {
                    if let config = element.electronicConfiguration {
                        LabeledContent("Electron Config", value: config)
                    }
                    
                    LabeledContent("Block", value: element.block)
                    LabeledContent("Bonds Type", value: element.bonds)
                    LabeledContent("Noble Gas", value: element.noble)
                }
                .textSelection(.enabled)
            }
            
            Section("Physical Attributes") {
                Group {
                    if let phase = element.phase {
                        LabeledContent("Phase", value: phase)
                    }
                    if let appearance = element.appearance {
                        LabeledContent("Appearance", value: appearance.capitalized)
                    }
                }
                .textSelection(.enabled)
            }
            
            Section("History & Overview") {
                Group {
                    if let discoveredBy = element.discoveredBy {
                        LabeledContent("Discovered By", value: discoveredBy)
                    }
                    
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Description")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                        Text(element.description)
//                            .font(.body)
//                    }
//                    .padding(.vertical, 4)
                    
                    LabeledContent("Description", value: element.description)
                    
                    if let source = element.source, let url = URL(string: source) {
                        Link(destination: url) {
                            HStack {
                                Text("Read more on Wikipedia")
                                Spacer()
                                Image(systemName: "arrow.up.right.square.fill")
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                .textSelection(.enabled)
            }
        }
        .allowLandscape()
        .navigationTransition(.automatic)
        .toolbarVisibility(.visible, for: .navigationBar)
        .presentationDragIndicator(.visible)
    }
}
