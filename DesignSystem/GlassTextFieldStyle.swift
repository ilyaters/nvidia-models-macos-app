import SwiftUI

/// A text field style with a subtle glass background.
struct GlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.roundedBorder)
            .font(.system(size: 13))
    }
}
