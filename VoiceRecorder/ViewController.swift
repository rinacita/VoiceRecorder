import AVFoundation
import Reusable
import UIKit

final class ViewController: UIViewController, StoryboardBased {
//    @IBOutlet var stopButton: UIButton! {
//        didSet {
//            stopButton.clipsToBounds = true
//            stopButton.layer.cornerRadius = 26
//            stopButton.addTarget(self, action: #selector(stopFunction), for: .touchUpInside)
//            stopButton.setImage(#imageLiteral(resourceName: "Stop"), for: .normal)
//            stopButton.setImage(#imageLiteral(resourceName: "Stop-gray"), for: .disabled)
//        }
//    }

    @IBOutlet var playButton: UIButton! {
        didSet {
            playButton.clipsToBounds = true
            playButton.layer.cornerRadius = 26
            playButton.addTarget(self, action: #selector(playFunction), for: .touchUpInside)
            playButton.setImage(#imageLiteral(resourceName: "play_paused"), for: .normal)
            playButton.setImage(UIImage(), for: .disabled)
//            playButton.setImage(#imageLiteral(resourceName: "StartPause"), for: .focused)
        }
    }

    @IBOutlet var audioButton: UIButton! {
        didSet {
            audioButton.clipsToBounds = true
            audioButton.layer.cornerRadius = 38
            audioButton.addTarget(self, action: #selector(audioFunction), for: .touchUpInside)
            audioButton.setImage(#imageLiteral(resourceName: "rec_paused"), for: .normal)
            audioButton.setImage(#imageLiteral(resourceName: "rec_disabled"), for: .disabled)
//            audioButton.setImage(#imageLiteral(resourceName: "MicPause"), for: .focused)
        }
    }
    
    @IBOutlet weak var waveView: WaveView! {
        didSet {
            waveView.delegate = self
        }
    }

    var audioRecorder: Engine!
    
//    var nowTime: Int64? = nil
//
//    var cellIndex: Int? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) != .authorized {
            AVCaptureDevice.requestAccess(for: AVMediaType.audio,
                                          completionHandler: { (granted: Bool) in
            })
        }

        audioRecorder = Engine(finishPlaying: finishPlaying, trackMic: trackMic)
    }
    
    func trackMic(aaa: Double) {
        waveView.addWave(wave: CGFloat(aaa) * 2)
    }

    @objc func stopFunction() {
        print("STOP PLAY")
    }

    @objc func playFunction() {
        if audioRecorder.state == .readyToPlay {
            print("Button Play PUSH")
            waveView.play()
            audioRecorder.startPlay(at: getWaveTime())
            playButton.setImage(#imageLiteral(resourceName: "play_playing"), for: .normal)
        } else if audioRecorder.state == .playing {
            audioRecorder.stopPlay()
            playButton.setImage(#imageLiteral(resourceName: "play_paused"), for: .normal)
        }
    }
    
    func finishPlaying() {
        playButton.setImage(#imageLiteral(resourceName: "play_paused"), for: .normal)
    }

    @objc func audioFunction() {
        if audioRecorder.state == .readyToRecord || audioRecorder.state == .readyToPlay {
            waveView.remove(from: getWaveCellIndex())
            audioRecorder.startRec()
            playButton.isEnabled = false
//            stopButton.isEnabled = false
            audioButton.setImage(#imageLiteral(resourceName: "rec_recording"), for: .normal)
            waveView.collectionView.isScrollEnabled = false
        } else if audioRecorder.state == .recording {
            waveView.collectionView.isScrollEnabled = true
            audioRecorder.stopRec(at: getWaveTime())
            playButton.isEnabled = true
//            stopButton.isEnabled = true
            audioButton.setImage(#imageLiteral(resourceName: "rec_paused"), for: .normal)
        }
    }
    
    func getWaveTime() -> Int64 {
        return Int64(waveView.now * 44100)
    }
    
    func getWaveCellIndex() -> Int {
        return Int(waveView.now / 0.1)
    }
}

extension ViewController: WaveViewDelegate {
    
    
    func timeChangeBegin() {
        if audioRecorder.player.isPlaying {
            audioRecorder.pausePlay()
        }
    }
    
    func timeChnageEnd() {
        if audioRecorder.state == .playing {
            audioRecorder.startPlay(at: getWaveTime())
            waveView.play()
        }
    }
    
//    func timeChanged(time: CGFloat) {
//        nowTime = Int64(time * 44100)
//        cellIndex = Int(time / 0.1)
//    }
//
}
