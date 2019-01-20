import AudioKit
import UIKit

class Engine {
    
    var micMixer: AKMixer!
    var recorder: AKNodeRecorder!
    var player: AKPlayer!
    var tape: AKAudioFile!
    var micBooster: AKBooster!
    var moogLadder: AKMoogLadder!
    var mainMixer: AKMixer!
    
    let mic = AKMicrophone()
    
    var timer: Timer!
    
    enum State {
        case readyToRecord
        case recording
        case readyToPlay
        case playing
    }
    
    var state = State.readyToRecord
    
    var finishPlaying: () -> Void
    var trackMic: (_ aaa: Double) -> Void
    let tracker: AKFrequencyTracker
    
    init(finishPlaying: @escaping () -> Void, trackMic: @escaping (_ aaa: Double) -> Void) {
        self.finishPlaying = finishPlaying
        self.trackMic = trackMic
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
        tracker = AKFrequencyTracker(micMixer)
        micBooster = AKBooster(tracker)
        
        // Will set the level of microphone monitoring
        micBooster.gain = 0
        recorder = try? AKNodeRecorder(node: micMixer)
        if let file = recorder.audioFile {
            player = AKPlayer(audioFile: file)
        }
        player.isLooping = false
        
        moogLadder = AKMoogLadder(player)
        //
        mainMixer = AKMixer(moogLadder, micBooster)
        
        player.completionHandler = playingEnded
        
        AudioKit.output = mainMixer
        do {
            try AudioKit.start()
        } catch {
            AKLog("AudioKit did not start!")
        }
    }
    
    func playingEnded() {
        DispatchQueue.main.async {
            self.setupUIForPlaying ()
            self.finishPlaying()
        }
    }
    
    
    
    func startRec() {
//        infoLabel.text = "Recording"
//        mainButton.setTitle("Stop", for: .normal)
        state = .recording
        micBooster.gain = 0
        // microphone will be monitored while recording
        // only if headphones are plugged
        if AKSettings.headPhonesPlugged {
            micBooster.gain = 1
        }
        do {
            try recorder.record()
        } catch { AKLog("Errored recording.") }
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(findSilences), userInfo: nil, repeats: true)
    }
    
    @objc func findSilences() {
        trackMic(tracker.amplitude)
    }
    
    func stopRec(at: Int64? = nil) {
        recorder.stop()
        
        timer.invalidate()
        
        if tape == nil {
            tape = recorder.audioFile!
        } else {
            guard let recBuffer = recorder.audioFile else { return }
            if let at = at {
                if at == 0 {
                    tape = recBuffer
                } else {
                    tape = try! addFrom(this: recBuffer, to: tape, at: at)
                }
            } else {
                tape = try! tape.appendedBy(file: recBuffer)
            }
            
        }
        player.load(audioFile: tape)
        
        try! recorder.reset()
        
        setupUIForPlaying()
    }
    
    func startPlay() {
        player.play()
        state = .playing
//        plot?.node = player
    }
    
    func stopPlay() {
        player.stop()
        setupUIForPlaying()
//        plot?.node = mic
    }
    
    func reset() {
        player.stop()
//        plot?.node = mic
        do {
            try recorder.reset()
        } catch { AKLog("Errored resetting.") }
        tape = nil
        setupUIForRecording()
    }
    
    func setupUIForPlaying () {
//        let recordedDuration = player != nil ? player.audioFile?.duration  : 0
//        infoLabel.text = "Recorded: \(String(format: "%0.1f", recordedDuration!)) seconds"
//        mainButton.setTitle("Play", for: .normal)
        state = .readyToPlay
//        resetButton.isHidden = false
//        resetButton.isEnabled = true
    }
    
    func setupUIForRecording () {
        state = .readyToRecord
//        infoLabel.text = "Ready to record"
//        mainButton.setTitle("Record", for: .normal)
//        resetButton.isEnabled = false
//        resetButton.isHidden = true
        micBooster.gain = 0
    }
    
    func addFrom(this: AKAudioFile, to: AKAudioFile, at: AVAudioFramePosition, baseDir: AKAudioFile.BaseDirectory = .temp,
                 name: String = UUID().uuidString) throws -> AKAudioFile {
        var sourceLeft: AKAudioFile
        
        do {
            sourceLeft = try to.extracted(fromSample: 0, toSample: at, baseDir: .temp, name: "sourceLeftBuffer")
        } catch let error as NSError {
            AKLog("ERROR AKAudioFile: Cannot extract from sourceFile")
            throw error
        }
        
        var sourceBuffer = sourceLeft.pcmBuffer
        var appendedBuffer = this.pcmBuffer
        
        if sourceLeft.fileFormat != this.fileFormat {
            AKLog("WARNING AKAudioFile.append: appended file should be of same format as source file")
            AKLog("WARNING AKAudioFile.append: trying to fix by converting files...")
            // We use extract method to get a .CAF file with the right format for appending
            // So sourceFile and appended File formats should match
            do {
                // First, we convert the source file to .CAF using extract()
                let convertedFile = try sourceLeft.extracted()
                sourceBuffer = convertedFile.pcmBuffer
                AKLog("AKAudioFile.append: source file has been successfully converted")
                
                if convertedFile.fileFormat != this.fileFormat {
                    do {
                        // If still don't match we convert the appended file to .CAF using extract()
                        let convertedAppendFile = try this.extracted()
                        appendedBuffer = convertedAppendFile.pcmBuffer
                        AKLog("AKAudioFile.append: appended file has been successfully converted")
                    } catch let error as NSError {
                        AKLog("ERROR AKAudioFile.append: cannot set append file format match source file format")
                        throw error
                    }
                }
            } catch let error as NSError {
                AKLog("ERROR AKAudioFile: Cannot convert sourceFile to .CAF")
                throw error
            }
        }
        
        // We check that both pcm buffers share the same format
        if appendedBuffer.format != sourceBuffer.format {
            AKLog("ERROR AKAudioFile.append: Couldn't match source file format with appended file format")
            let userInfo: [AnyHashable: Any] = [
                NSLocalizedDescriptionKey: NSLocalizedString(
                    "AKAudioFile append process Error",
                    value: "Couldn't match source file format with appended file format",
                    comment: ""),
                NSLocalizedFailureReasonErrorKey: NSLocalizedString(
                    "AKAudioFile append process Error",
                    value: "Couldn't match source file format with appended file format",
                    comment: "")
            ]
            throw NSError(domain: "AKAudioFile ASync Process Unknown Error", code: 0, userInfo: userInfo as? [String: Any])
        }
        
        let outputFile = try AKAudioFile (writeIn: baseDir, name: name)
        
        // Write the buffer in file
        do {
            try outputFile.write(from: sourceBuffer)
        } catch let error as NSError {
            AKLog("ERROR AKAudioFile: cannot writeFromBuffer Error: \(error)")
            throw error
        }
        
        do {
            try outputFile.write(from: appendedBuffer)
        } catch let error as NSError {
            AKLog("ERROR AKAudioFile: cannot writeFromBuffer Error: \(error)")
            throw error
        }
        
        return try AKAudioFile(forReading: outputFile.url)
    }
    
    
    func export() {
        //            if let _ = player.audioFile?.duration {
        //                recorder.stop()
        //                tape.exportAsynchronously(name: "TempTestFile.m4a",
        //                                          baseDir: .documents,
        //                                          exportFormat: .m4a) {_, exportError in
        //                    if let error = exportError {
        //                        AKLog("Export Failed \(error)")
        //                    } else {
        //                        AKLog("Export succeeded")
        //                    }
        //                }
        //                setupUIForPlaying()
        //            }
    }
    
}
