
import SwiftUI
import Observation

@MainActor
@Observable
final class AlertManager {
    var isPresented = false
    
    private(set) var title = Text("")
    private(set) var message: Text? = nil
    private(set) var buttons: [AlertButton] = []
    
    func show(title: Text, message: Text? = nil, buttons: [AlertButton]) {
        self.title = title
        self.message = message
        self.buttons = buttons
        self.isPresented = true
    }
}
