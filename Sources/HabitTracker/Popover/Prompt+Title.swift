import Foundation
import HabitCore

extension Prompt {
    var title: LocalizedStringResource {
        switch self {
        case .morning: "Morning"
        case .evening: "Evening"
        }
    }
}
