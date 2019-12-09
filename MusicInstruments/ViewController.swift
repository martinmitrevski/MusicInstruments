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
    var streamAnalyzer: SNAudioStreamAnalyzer!
    let queue = DispatchQueue(label: "com.mitrevski.musicinstruments")
    var results = [(label: String, confidence: Float)]() {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Music instruments"
    }
    
    private func startAudioEngine() {
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            showAudioError()
        }
    }
    
    private func prepareForRecording() {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        streamAnalyzer = SNAudioStreamAnalyzer(format: recordingFormat)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            [unowned self] (buffer, when) in
            self.queue.async {
                self.streamAnalyzer.analyze(buffer,
                                            atAudioFramePosition: when.sampleTime)
            }
        }
        startAudioEngine()
    }
    
    private func createClassificationRequest() {
        do {
            let request = try SNClassifySoundRequest(mlModel: soundClassifier.model)
            try streamAnalyzer.add(request, withObserver: self)
        } catch {
            fatalError("error adding the classification request")
        }
    }
    
    @IBAction func startRecordingButtonTapped(_ sender: UIButton) {
        prepareForRecording()
        createClassificationRequest()
    }

}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "ResultCell")
        }
        
        let result = results[indexPath.row]
        let label = convert(id: result.label)
        cell!.textLabel!.text = "\(label): \(result.confidence)"
        return cell!
    }
    
    private func convert(id: String) -> String {
        let mapping = ["cel" : "drum", "cla" : "clarinet", "flu" : "flute",
                       "gac" : "acoustic guitar", "gel" : "electric guitar",
                       "org" : "organ", "pia" : "piano", "sax" : "saxophone",
                       "tru" : "trumpet", "vio" : "violin", "voi" : "human voice"]
        return mapping[id] ?? id
    }
    
}

extension ViewController: SNResultsObserving {
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult else { return }
        var temp = [(label: String, confidence: Float)]()
        let sorted = result.classifications.sorted { (first, second) -> Bool in
            return first.confidence > second.confidence
        }
        for classification in sorted {
            let confidence = classification.confidence * 100
            if confidence > 5 {
                temp.append((label: classification.identifier, confidence: Float(confidence)))
            }
        }
        results = temp
    }
}

extension ViewController {
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    func showAudioError() {
        let errorTitle = "Audio Error"
        let errorMessage = "Recording is not possible at the moment."
        self.showAlert(title: errorTitle, message: errorMessage)
    }
    
}
