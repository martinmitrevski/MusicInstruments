//
//  ViewController.swift
//  MusicInstruments
//
//  Created by Martin Mitrevski on 12/9/19.
//  Copyright © 2019 Martin Mitrevski. All rights reserved.
//

import UIKit
import AVKit
import SoundAnalysis

class ViewController: UIViewController {
    
    private let audioEngine = AVAudioEngine()
    private var soundClassifier = MySoundClassifier()
    var inputFormat: AVAudioFormat!
    var streamAnalyzer: SNAudioStreamAnalyzer!
    let queue = DispatchQueue(label: "com.mitrevski.musicinstruments")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    private func startAudioEngine() {
        do {
            try audioEngine.start()
        }
        catch {
            fatalError("error starting the audio engine")
        }
        
        inputFormat = audioEngine.inputNode.inputFormat(forBus: 0)
        streamAnalyzer = SNAudioStreamAnalyzer(format: inputFormat)
        
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 8000, format: inputFormat) { buffer, time in
                self.queue.async {
                    self.streamAnalyzer.analyze(buffer,
                                                atAudioFramePosition: time.sampleTime)
                }
        }
        
    }
    
    private func createClassificationRequest() {
        do {
            let request = try SNClassifySoundRequest(mlModel: soundClassifier.model)
            try streamAnalyzer.add(request, withObserver: self)
        } catch {
            fatalError("error adding the classification request")
        }
    }


}

extension ViewController: SNResultsObserving {
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult else { return }
        print(result.classifications)
    }
}

