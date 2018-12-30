import AVFoundation
import Reusable
import UIKit

final class ViewController: UIViewController, StoryboardBased {
    
    @IBOutlet weak var stopButton: UIButton! {
        didSet {
            stopButton.clipsToBounds = true
            stopButton.layer.cornerRadius = 26
            stopButton.addTarget(self, action: #selector(stopFunction), for: .touchUpInside)
        }
    }
    @IBOutlet weak var playButton: UIButton! {
        didSet {
            playButton.clipsToBounds = true
            playButton.layer.cornerRadius = 26
            playButton.addTarget(self, action: #selector(playFunction), for: .touchUpInside)
        }
    }
    @IBOutlet weak var audioButton: UIButton! {
        didSet {
            audioButton.clipsToBounds = true
            audioButton.layer.cornerRadius = 38
            audioButton.addTarget(self, action: #selector(audioFunction), for: .touchUpInside)
        }
    }
    
    var audioRecorder: AudioRecorder!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        audioRecorder = AudioRecorder(playerCompleated: {
            self.audioRecorder.state = .pauseRecording
            self.playButton.setImage(#imageLiteral(resourceName: "Start"), for: .normal)
        })
        
    }
    
    @objc func stopFunction() {
        
    }
    
    @objc func playFunction() {
        switch audioRecorder.state {
        case .pauseRecording:
            playButton.setImage(#imageLiteral(resourceName: "StartPause"), for: .normal)
            audioRecorder.startPlayer()
            audioRecorder.state = .playing
        case .playing:
            playButton.setImage(#imageLiteral(resourceName: "Start"), for: .normal)
            audioRecorder.stopPlayer()
            audioRecorder.state = .pauseRecording
        default:
            return
        }
    }
    
    @objc func audioFunction() {
        
        switch audioRecorder.state {
        case .readyToRecord:
            audioButton.setImage(#imageLiteral(resourceName: "MicPause"), for: .normal)
            audioRecorder.startRecord()
            audioRecorder.state = .recording
        case .recording:
            audioButton.setImage(#imageLiteral(resourceName: "Mic"), for: .normal)
            audioRecorder.stopRecord()
            audioRecorder.state = .pauseRecording
            audioRecorder.saveRecord()
        case .pauseRecording:
            audioButton.setImage(#imageLiteral(resourceName: "MicPause"), for: .normal)
            audioRecorder.startOverrideRecord()
            audioRecorder.state = .overRecording
        case .overRecording:
            audioButton.setImage(#imageLiteral(resourceName: "Mic"), for: .normal)
            audioRecorder.stopOverrideRecord()
            audioRecorder.state = .pauseRecording
        default:
            return
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func getFileUrl(name: String) -> URL {
        let filename = name + ".m4a"
        let filePath = getDocumentsDirectory().appendingPathComponent(filename)
        return filePath
    }
    
}
