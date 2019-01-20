import Reusable
import UIKit

final class WaveViewController: UIViewController, StoryboardBased {
    @IBOutlet var backgroudView: UIView! {
        didSet {
            backgroudView.clipsToBounds = true
            backgroudView.layer.cornerRadius = 18
            backgroudView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        }
    }

    @IBOutlet var bar: UIView! {
        didSet {
            bar.clipsToBounds = true
            bar.layer.cornerRadius = 2.5
        }
    }

    @IBOutlet var timeLabel: UILabel!

    @IBOutlet var waveView: WaveView!
}
