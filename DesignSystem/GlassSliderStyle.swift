import SwiftUI

/// A slider style label that shows the current value alongside the label.
struct GlassSliderStyle<Label: View>: View {
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let label: Label

    init(value: Binding<Double>, in range: ClosedRange<Double>, @ViewBuilder label: () -> Label) {
        self.value = value
        self.range = range
        self.label = label()
    }

    var body: some View {
        HStack {
            label
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Slider(value: value, in: range)
            Text(String(format: "%.2f", value.wrappedValue))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
    }
}
