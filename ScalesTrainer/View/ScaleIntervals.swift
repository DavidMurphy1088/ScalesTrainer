import Foundation
import SwiftUI

struct ScalesIntervalsView: View {
    @State private var numberOfLayers = 13 // State variable to control the number of layers

    var body: some View {
        VStack(spacing: 0) {
            ForEach((0..<numberOfLayers).reversed(), id: \.self) { index in
                ZStack {
                    Rectangle()
                        .fill(self.getColor(for: index))  // Dynamic color based on index
                        .frame(height: 50)  // Set a fixed height for each rectangle
                    Text("\(index)")  // Display the index inside the rectangle
                        .foregroundColor(.purple)  // Ensure the text is visible on colored backgrounds
                        .bold()
                }
                .border(Color.black, width: 1)
            }
        }
        .frame(width: 200, height: 200) // Set the width of the entire box and ensure total height
        
    }

    // Function to determine the color of each rectangle based on its index
    func getColor(for index: Int) -> Color {
        return [0,2,4,5,7,9,11,12].contains(index) ? .blue : .white
    }
}
