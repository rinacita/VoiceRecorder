//
//  ViewController.swift
//  VoiceRecorder
//
//  Created by 垰尚太朗 on 2018/11/26.
//  Copyright © 2018 垰尚太朗. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    var audioRec: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var meterTimer: Timer?
    
    var records: [String] = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var functionButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    
    var isAudioRecordingGranted = false
    
    var selected: Int? {
        didSet {
            if let selected = selected {
                stopRec()
                audioPlayer?.stop()
                playRec(name: records[selected])
                functionButton.backgroundColor = #colorLiteral(red: 1, green: 0.8014014959, blue: 0.001512364484, alpha: 1)
                functionButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
            } else {
                audioPlayer?.stop()
                functionButton.backgroundColor = #colorLiteral(red: 0.9985577464, green: 0.178073734, blue: 0.3343303204, alpha: 1)
                functionButton.setImage(#imageLiteral(resourceName: "Rec"), for: .normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        functionButton.addTarget(self, action: #selector(actionFunction), for: .touchUpInside)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
    }
    
    @objc func actionFunction() {
        
        if let selected = selected {
            if audioPlayer!.isPlaying {
                audioPlayer?.pause()
                functionButton.backgroundColor = #colorLiteral(red: 1, green: 0.8014014959, blue: 0.001512364484, alpha: 1)
                functionButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
            } else {
                playRec(name: records[selected])
                functionButton.backgroundColor = #colorLiteral(red: 1, green: 0.8014014959, blue: 0.001512364484, alpha: 1)
                functionButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
            }
        } else {
            guard let isRecording = audioRec?.isRecording else {
                startRec()
                functionButton.backgroundColor = #colorLiteral(red: 0.3532704413, green: 0.7826827168, blue: 0.9799864888, alpha: 1)
                functionButton.setImage(#imageLiteral(resourceName: "stop"), for: .normal)
                return
            }
            if isRecording {
                stopRec()
                functionButton.backgroundColor = #colorLiteral(red: 0.9985577464, green: 0.178073734, blue: 0.3343303204, alpha: 1)
                functionButton.setImage(#imageLiteral(resourceName: "Rec"), for: .normal)
            } else {
                startRec()
                functionButton.backgroundColor = #colorLiteral(red: 0.3532704413, green: 0.7826827168, blue: 0.9799864888, alpha: 1)
                functionButton.setImage(#imageLiteral(resourceName: "stop"), for: .normal)
            }
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
    
    // return and request permission state
    func permission() -> Bool {
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSession.RecordPermission.granted:
            return true
        case AVAudioSession.RecordPermission.denied:
            return false
        case AVAudioSession.RecordPermission.undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { permission in
                return permission
            }
        default:
            return false
        }
        return false
    }
    
    // Play Recorded
    func playRec(name: String) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: getFileUrl(name: name))
            audioPlayer?.delegate = self
            meterTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateAudioMeter), userInfo: nil, repeats: true)
            audioPlayer?.play()
        } catch {
            print("Error")
        }
    }
    
    // Stop Record
    func stopRec() {
        audioRec?.stop()
        meterTimer?.invalidate()
        timeLabel.text = "00:00:00"
    }
    
    // Start Record
    func startRec() {
        if permission() {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
                try session.setActive(true)
                let settings = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                
                // Generate random Name
                let recName: String = .randomName()
                records.append(recName)
                
                audioRec = try AVAudioRecorder(url: getFileUrl(name: recName), settings: settings)
                meterTimer = Timer.scheduledTimer(timeInterval: 0.1, target:self, selector: #selector(updateAudioMeter), userInfo:nil, repeats:true)
                audioRec?.delegate = self
                audioRec?.isMeteringEnabled = true
                audioRec?.record()
            } catch {
                print("Error")
            }
        }
    }
    
    // Time
    @objc func updateAudioMeter(timer: Timer) {
        
        if audioPlayer?.isPlaying ?? false {
            let hr = Int((audioPlayer!.currentTime / 60) / 60)
            let min = Int(audioPlayer!.currentTime / 60)
            let sec = Int(audioPlayer!.currentTime.truncatingRemainder(dividingBy: 60))
            let totalTimeString = String(format: "%02d:%02d:%02d", hr, min, sec)
            timeLabel.text = totalTimeString
            audioPlayer?.updateMeters()
        } else if audioRec?.isRecording ?? false {
            let hr = Int((audioRec!.currentTime / 60) / 60)
            let min = Int(audioRec!.currentTime / 60)
            let sec = Int(audioRec!.currentTime.truncatingRemainder(dividingBy: 60))
            let totalTimeString = String(format: "%02d:%02d:%02d", hr, min, sec)
            timeLabel.text = totalTimeString
            audioRec?.updateMeters()
        }
        
    }
}

extension ViewController: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let cell = tableView.cellForRow(at: IndexPath(row: selected!, section: 0))
        cell?.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        selected = nil
        timeLabel.text = "00:00:00"
    }
    
}

extension ViewController: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            tableView.reloadData()
        } else {
            records.removeLast()
        }
    }
    
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = records[indexPath.row]
        cell.textLabel?.textColor = #colorLiteral(red: 0.1490196078, green: 0.1490196078, blue: 0.1490196078, alpha: 1)
        cell.selectionStyle = .none
        cell.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        return cell
    }
    
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = selected != nil ? .white : #colorLiteral(red: 1, green: 0.8014014959, blue: 0.001512364484, alpha: 1)
        selected = selected != nil ? nil : indexPath.row
    }
    
}
