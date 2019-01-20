import Reusable
import UIKit

final class WaveCollectionViewCell: UICollectionViewCell, NibReusable {
    enum State {
        case Recording
        case Paused
    }

    var waveState: State = .Recording {
        didSet {
            switch waveState {
            case .Recording:
                line.backgroundColor = .red
            case .Paused:
                line.backgroundColor = .white
            }
        }
    }

    var value: CGFloat = 0 {
        didSet {
            let height = frame.height * value
            lineHeightConstraint.constant = height
        }
    }

    @IBOutlet var lineHeightConstraint: NSLayoutConstraint!

    @IBOutlet var line: UIView!
}
