//
//
//	ViewController.swift
//	
//
//	Created By Rakesh Kumar Raushan on 5/28/22
//	
//

//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var inputField: UITextField!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var gameWinnerLabel: UILabel!
    
    private var timer: Timer?
    private var seconds: Int = 0
    private var player: Player = .computer
    private var gameStatus: GameStatus = .Stopped
    private var isTimerStopped = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            if self?.isTimerStopped ?? true {
                self?.seconds = 0
                self?.timerLabel.text = "00:00"
            }else {
                self?.seconds += 1
                self?.timerLabel.text = self?.getMMSS(from: self?.seconds ?? 0)
            }
        }
        self.inputField.isUserInteractionEnabled = false
    }
    
    /* Load Words from API for search text */
    private func loadWords(searchText:String,success:@escaping([WordDetail])->()) {
        ServerTask.shared.doRequestForWords(searchText:searchText) { [weak self] words in
            DispatchQueue.main.async {
                self?.startStopButton.isUserInteractionEnabled = true
            }
            success(words)
        }
    }
    
    /* Set Timer is stopped */
    private func stopTimer() {
        isTimerStopped = true
    }
    
    /* Start Timer */
    private func startTimer() {
        isTimerStopped = false
        resetTime()
        timer?.fire()
    }
    
    /* Reset Timer */
    private func resetTime() {
        seconds = 0
    }
    
    /* Play/Stop button action */
    @IBAction func startStopGame(_ sender: UIButton) {
        gameWinnerLabel.text = ""
        if gameStatus == .Stopped {
            self.inputField.isUserInteractionEnabled = true
            inputField.text = ""
            startStopButton.setTitle("Stop", for: .normal)
            gameStatus = .Running
            startTimer()
            player = .computer
            computerTurn()
        }else {
            self.inputField.resignFirstResponder()
            self.inputField.isUserInteractionEnabled = false
            startStopButton.setTitle("Play", for: .normal)
            gameStatus = .Stopped
            stopTimer()
        }
    }
    
    /* It returns in mm:ss format */
    private func getMMSS(from seconds: Int) -> String {
        let s = seconds % 60
        let m = seconds / 60
        var res = ""
        
        res = m < 10 ? "0\(m)" : m.description
        res += ":" + (s < 10 ? "0\(s)" : s.description)
        return res
    }
    
    /* Computer Turn Task */
    private func computerTurn() {
        resetTime()
        self.inputField.resignFirstResponder()
        if let text = inputField.text,text.isValidWith(regex: #"^[A-Za-z]+$"#),text.count > 1 {
            loadWords(searchText: text) { words in
                self.computerTask(words: words)
            }
        }else {
            let x = "abcdefghijklmnopqrstuvw".randomElement()?.description ?? ""
            self.inputField.text = x
            DispatchQueue.main.async {[weak self] in
                self?.inputField.isUserInteractionEnabled = true
                self?.inputField.becomeFirstResponder()
            }
            self.player = .user
            self.resetTime()
        }
    }
    
    /* Coputer Task */
    private func computerTask(words: [WordDetail]) {
        DispatchQueue.main.async { [self] in
            let text = (self.inputField.text ?? "")
            let randomElement = words.filter{$0.word.starts(with:text)}.randomElement()?.word
            if let endIndex = randomElement?.endIndex(of: text) {
                let index = endIndex.utf16Offset(in: randomElement!)
                if index < ((randomElement?.count ?? 0) - 1) {
                    let char = Array(randomElement!)[index]
                    self.inputField.text = (self.inputField.text ?? "") + "\(char)"
                    if let _ = words.filter({$0.word.lowercased() == self.inputField.text?.lowercased()}).first {
                        self.postLostExecution(player: .computer)
                        return
                    }
                    self.inputField.becomeFirstResponder()
                }
                self.resetTime()
            }else {
                self.postLostExecution(player: .computer)
            }
            self.player = .user
        }
    }
    
    /* Post Lost Execution */
    private func postLostExecution(player: Player) {
        if player == .computer {
            print("You Won!,Computer lost.")
            self.gameWinnerLabel.text = "You Won!,Computer lost."
            self.gameStatus = .Stopped
            self.startStopButton.setTitle("Play", for: .normal)
            self.inputField.isUserInteractionEnabled = false
            self.stopTimer()
        }else {
            self.gameWinnerLabel.text = "You Lost!,Computer Won."
            self.gameStatus = .Stopped
            self.startStopButton.setTitle("Play", for: .normal)
            self.inputField.isUserInteractionEnabled = false
            self.stopTimer()
        }
    }
    
}

/* UITextFieldDelegate Methods */
extension ViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isValidWith(regex: #"^[A-Za-z]+$"#) {
            textField.text = (textField.text ?? "") + string
            loadWords(searchText: textField.text ?? "") { words in
                DispatchQueue.main.async {
                    if let _ = words.filter({$0.word.lowercased() == textField.text}).first {
                        self.postLostExecution(player: .user)
                    }else {
                        if words.isEmpty {
                            self.postLostExecution(player: .user)
                            return
                        }
                        self.player = .computer
                        self.computerTurn()
                        textField.resignFirstResponder()
                    }
                }
            }
            return false
        }
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.view.endEditing(true)
    }
    
}

/* Players */
enum Player {
    case user,computer
}

/* Game Status */
enum GameStatus {
    case Running,Stopped
}

