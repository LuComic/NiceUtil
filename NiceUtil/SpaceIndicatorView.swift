import SwiftUI

struct SpaceIndicatorView: View {
    let activeSpace: Int
    let totalSpaces: Int
    
    var body: some View {
        HStack(spacing: 10) { // Increased spacing from 6 to 14
            ForEach(1...totalSpaces, id: \.self) { i in
                Text("\(i)")
                    .font(.system(size: 12))
                    .fontWeight(i == activeSpace ? .bold : .regular)
                    .foregroundColor(i == activeSpace ? .primary : .secondary)
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 22)
    }
}
