import AudioKit
import Foundation

class AudioRecorder {
    
    enum State {
        case readyToRecord
        case recording
        case pauseRecording
        case readyToPlay
        case playing
        case overRecording
    }
    
    var state: State = .readyToRecord
    
    var micMixer: AKMixer!
    var recorder: AKNodeRecorder!
    var player: AKPlayer!
    var tape: AKAudioFile!
    var micBooster: AKBooster!
    var moogLadder: AKMoogLadder!
    var mainMixer: AKMixer!
    
    let mic = AKMicrophone()
    
    init(playerCompleated: @escaping () -> ()) {
        
        // Clean tempFiles !
        AKAudioFile.cleanTempDirectory()
        
        // Session settings
        AKSettings.bufferLength = .medium
        
        do {
            try AKSettings.setSession(category: .playAndRecord, with: .allowBluetoothA2DP)
        } catch {
            AKLog("Could not set session category.")
        }
        
        AKSettings.defaultToSpeaker = true
        
        // Patching
        let monoToStereo = AKStereoFieldLimiter(mic, amount: 1)
        micMixer = AKMixer(monoToStereo)
        micBooster = AKBooster(micMixer)
        
        // Will set the level of microphone monitoring
        micBooster.gain = 0
        recorder = try? AKNodeRecorder(node: micMixer)
        if let file = recorder.audioFile {
            player = AKPlayer(audioFile: file)
        }
        player.isLooping = false
        player.completionHandler = playerCompleated
        
        moogLadder = AKMoogLadder(player)
        
        mainMixer = AKMixer(moogLadder, micBooster)
        
        AudioKit.output = mainMixer
        do {
            try AudioKit.start()
        } catch {
            AKLog("AudioKit did not start!")
        }
        
    }
    
    func startRecord() {
        if AKSettings.headPhonesPlugged {
            micBooster.gain = 1
        }
        do {
            try recorder.record()
        } catch {
            AKLog("Errored recording.")
        }
    }
    
    func stopRecord() {
        micBooster.gain = 0
        if let _ = player.audioFile?.duration {
            recorder.stop()
        }
    }
    
    func saveRecord() {
        tape = recorder.audioFile!
    }
    
    func startOverrideRecord() {
        try? recorder.reset()
        startRecord()
    }
    
    func stopOverrideRecord() {
        recorder.stop()
        guard let audio = recorder.audioFile else { return }
        tape = try? tape.appendedBy(file: audio)
    }
    
    func startPlayer() {
        player.load(audioFile: tape)
        player.play()
    }
    
    func stopPlayer() {
        player.stop()
    }
    
}
