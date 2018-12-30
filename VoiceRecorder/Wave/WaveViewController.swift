import Reusable
import UIKit

final class WaveViewController: UIViewController, StoryboardBased {

    @IBOutlet weak var backgroudView: UIView! {
        didSet {
            backgroudView.clipsToBounds = true
            backgroudView.layer.cornerRadius = 18
            backgroudView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        }
    }
    
    @IBOutlet weak var bar: UIView! {
        didSet {
            bar.clipsToBounds = true
            bar.layer.cornerRadius = 2.5
        }
    }
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var waveView: WaveView!
    
}
