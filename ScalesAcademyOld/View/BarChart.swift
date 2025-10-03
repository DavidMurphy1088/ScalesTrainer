import SwiftUI
class BarChartData {
    var label:String
    var value:Int
    init(label:String, value:Int) {
        self.label = label
        self.value = value
    }
}
struct BarChartView: View {
    var data: [BarChartData]
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                let maxValue = data.map { $0.value }.max() ?? 1
                let barWidth = geometry.size.width / CGFloat(data.count)
                
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(data.indices, id: \.self) { index in
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: barWidth, height: CGFloat(data[index].value) / CGFloat(maxValue) * geometry.size.height)
                            Text(data[index].label)
                                .font(.caption)
                                .frame(width: barWidth)
                                .rotationEffect(.degrees(-45))
                                .offset(y: 20)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            HStack {
                ForEach(data.indices, id: \.self) { index in
                    Text(data[index].label)
                        .font(.caption)
                        .frame(width: 20, alignment: .center)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct BarChartView_Previews: PreviewProvider {
    static var previews: some View {
        BarChartView(data: [
            BarChartData(label: "Jan", value: 10),
            BarChartData(label: "Feb", value: 20),
            BarChartData(label: "Mar", value: 15),
            BarChartData(label: "Apr", value: 30),
            BarChartData(label: "May", value: 25)
        ])
        .frame(height: 300)
    }
}
