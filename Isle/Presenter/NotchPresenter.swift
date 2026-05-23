import Foundation
import Observation

@MainActor
@Observable
final class NotchPresenter {
    enum State: Equatable {
        case collapsed
        case hovered
    }

    private(set) var state: State = .collapsed

    func setHovered(_ hovered: Bool) {
        let target: State = hovered ? .hovered : .collapsed
        guard target != state else { return }
        state = target
    }
}
