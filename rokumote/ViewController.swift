//
//  ViewController.swift
//  rokumote
//
//  Created by Jeremy Kelley on 4/12/15.
//  Copyright (c) 2015 Jeremy Kelley. All rights reserved.
//

import Cocoa

import Alamofire

extension String {
    
    subscript (i: Int) -> Character {
        if i < 0 {
            return self[advance(self.endIndex, i)]
        }
        return self[advance(self.startIndex, i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substringWithRange(Range(start: advance(startIndex, r.startIndex), end: advance(startIndex, r.endIndex)))
    }
}



func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}


class RokuApi: NSObject {
    
    var host : String?

    init(rokuhost: String) {
        super.init()
        self.host = rokuhost
    }
    
    func getUri(host: String, cmd: String) -> String {
        return "http://\(host):8060/\(cmd)"
    }
    
    func sendcmd(cmd: String) {
        let uri = self.getUri(self.host!, cmd: cmd)
        Alamofire.request(.POST, uri )
        .responseString { (request, response, string, error) in
            println("response: \(response)")
            println("cmd: \(cmd) returned \(string)")
        }
    }
    
    func play() {
        self.sendcmd("keypress/Play")
    }
    
    func rewind() {
        self.sendcmd("keypress/Rev")
    }
    
    func forward() {
        self.sendcmd("keypress/Fwd")
    }
    
    func home() {
        self.sendcmd("keypress/Home")
    }

    func left() {
        self.sendcmd("keypress/Left")
    }
    
    func right() {
        self.sendcmd("keypress/Right")
    }
    
    func up() {
        self.sendcmd("keypress/Up")
    }
    
    func down() {
        self.sendcmd("keypress/Down")
    }
    
    func back() {
        self.sendcmd("keypress/Back")
    }

    func replay() {
        self.sendcmd("keypress/InstantReplay")
    }
    
    func enter() {
        self.sendcmd("keypress/Select")
    }
    
    func info() {
        self.sendcmd("keypress/Info")
    }

    func literal(str: String) {
        var i: Int = 0
        for c in str.capitalizedString {
            delay(0.01 * Double(i)) {
                self.sendcmd("keypress/Lit_\(c)")
            }
            i++
        }
    }
    
    func backspace() {
        self.sendcmd("keypress/Backspace")
    }
    
    func launchApp(appCode: String) {
        // netflix is 12
        // cinemac is ... ya
        self.sendcmd("launch/\(appCode)")
    }
    
    func launchNetflix() {
        self.launchApp("12")
    }

}


class PrefsController: NSViewController {

    @IBOutlet var hostfield: NSTextField!
    
    override func viewDidAppear() {
        let defs = NSUserDefaults.standardUserDefaults()
        if let host = defs.stringForKey("ROKUHOST") {
            self.hostfield.stringValue = host
        }
    }
    
    @IBAction func clickSave(sender: NSButton) {
        let defs = NSUserDefaults.standardUserDefaults()
        defs.setObject(self.hostfield.stringValue, forKey: "ROKUHOST")
        self.dismissController(nil)
    }
}


class ViewController: NSViewController, NSTextFieldDelegate {

    @IBOutlet var inputField: NSTextField!
    var roku : RokuApi?
    var oldText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewDidAppear() {
        let defs = NSUserDefaults.standardUserDefaults()
        if let host = defs.stringForKey("ROKUHOST") {
            self.roku = RokuApi(rokuhost: host)
        } else {
            self.getRokuHost()
        }
        super.viewDidAppear()
        self.inputField.delegate = self
        self.view.window?.titlebarAppearsTransparent = true
        self.view.window?.movableByWindowBackground = true
        self.inputField.refusesFirstResponder()
        self.inputField.resignFirstResponder()
    }

    func getRokuHost() {
        var alert = NSAlert()
        alert.messageText = "Set the IP of your Roku in preferences"
        alert.runModal()
    }
    
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func sendText(sender: NSButton) {
        self.roku?.literal(self.inputField.stringValue)
        self.inputField.stringValue = ""
    }
    
    override func controlTextDidChange(obj: NSNotification) {
        var currstr = self.inputField.stringValue
        if currstr == oldText {
            return
        }
        if count(currstr) < count(oldText) {
            // send delete
            roku?.backspace()
            oldText = currstr
        }
        if count(currstr) > count(oldText) {
            var char:String = currstr[-1]
            oldText = currstr
            roku?.literal(char)
        }
    }
    
    @IBAction func clickPlay(sender: NSButton) {
        self.roku?.play()
    }
    
    @IBAction func clickHome(sender: NSButton) {
        self.roku?.home()
    }
    
    @IBAction func clickLeft(sender: NSButton) {
        self.roku?.left()
    }
    
    @IBAction func clickRight(sender: NSButton) {
        self.roku?.right()
    }

    @IBAction func clickUp(sender: NSButton) {
        self.roku?.up()
    }

    @IBAction func clickDown(sender: NSButton) {
        self.roku?.down()
    }
    
    @IBAction func clickRewind(sender: NSButton) {
        self.roku?.rewind()
    }

    @IBAction func clickForward(sender: NSButton) {
        self.roku?.forward()
    }
    
    @IBAction func clickEnter(sender: NSButton) {
        self.roku?.enter()
    }
    
    @IBAction func clickInfo(sender: NSButton) {
        self.roku?.info()
    }
    
    @IBAction func clickBack(sender: NSButton) {
        self.roku?.back()
    }
    
    @IBAction func clickNetflix(sender: NSButton) {
        self.roku?.launchNetflix()
    }
    
}

