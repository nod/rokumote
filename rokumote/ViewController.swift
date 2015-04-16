//
//  ViewController.swift
//  rokumote
//
//  Created by Jeremy Kelley on 4/12/15.
//  Copyright (c) 2015 Jeremy Kelley. All rights reserved.
//

import Cocoa

import Alamofire
import SWXMLHash


// MARK: - helpers

// KEY DETECTION NOT WORKING RIGHT NOW

class KeyPressView : NSVisualEffectView {
    var keypressed : ((key: String) -> ())?
    
    override func keyDown(theEvent: NSEvent) {
        if theEvent.keyCode == 32 {
            self.keypressed?(key:" ")
        }
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }

}



// string multiline join syntactic sugar
// found http://stackoverflow.com/questions/24091233/swift-split-string-over-multiple-lines
extension String {
    init(sep:String, _ lines:String...){
        self = ""
        for (idx, item) in enumerate(lines) {
            self += "\(item)"
            if idx < lines.count-1 {
                self += sep
            }
        }
    }
    
    init(_ lines:String...){
        self = ""
        for (idx, item) in enumerate(lines) {
            self += "\(item)"
            if idx < lines.count-1 {
                self += "\n"
            }
        }
    }
}

// string subscript, inspired by stackoverflow
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

func alert(msg: String) {
    var alert = NSAlert()
    alert.messageText = msg
    alert.runModal()
}

// MARK: - Roku API

let ST_DIAL = "urn:dial-multiscreen-org:service:dial:1"

class RokuApi: NSObject {
    
    var host : String?
    
    init(rokuhost: String) {
        super.init()
        self.host = rokuhost
    }

    override init() {
        super.init()
    }

    /*
     * WARNING unfinished, does not work...
     */
    func discover() -> String {
        let message = "\r\n".join([
            "M-SEARCH * HTTP/1.1",
            "HOST: 239.255.255.250:1900",
            "MAN: \"ssdp:discover\"",
            "ST: roku:ecp",
            "MX: 3",
            "", "" ])
        
        let client = UDPClient(addr: "239.255.255.250", port: 1900)
        var (success,errmsg)=client.send(str:message)
        if success{
            let (data, addr, port)=client.recv(1024*10)
            let sdata = String.fromCString(UnsafePointer(data!))
            /*
            HTTP/1.1 200 OK.
                Cache-Control: max-age=3600.
            ST: roku:ecp.
            USN: uuid:roku:ecp:1GU451101041.
            Ext: .
            Server: Roku UPnP/1.0 MiniUPnPd/1.4.
            LOCATION: http://10.77.77.48:8060/.
            */
            if sdata!.rangeOfString("Server: Roku") != nil {
                println("Found rokuhost: ", addr)
                return addr
            }
        } else {
            println(errmsg)
        }
        return ""
    }

    
    func getUri(host: String, cmd: String) -> String {
        return "http://\(host):8060/\(cmd)"
    }
    
    func sendcmd(cmd: String) {
        if self.host == nil {
            // try to get from defaults
            let def = NSUserDefaults.standardUserDefaults()
            self.host = def.stringForKey("ROKUHOST")
            if self.host == nil {
                alert("You must set the Roku IP in preferences first")
                return
            }
        }

        let uri = self.getUri(self.host!, cmd: cmd)
        Alamofire.request(.POST, uri )
        .responseString { (request, response, string, error) in
            println("response: \(response)")
            println("cmd: \(cmd) returned \(string)")
        }
    }

    func getApps(callback: ([String: String])->()) {
        if self.host == nil {
            // try to get from defaults
            let def = NSUserDefaults.standardUserDefaults()
            self.host = def.stringForKey("ROKUHOST")
        }
        let uri = self.getUri(self.host!, cmd: "query/apps")
        Alamofire.request(.GET, uri )
        .validate()
        .responseString { (_, _, string, error) in
            if (error != nil) { return }
            let xml = SWXMLHash.parse(string!)
            var apps = [String: String]()
            for app in xml["apps"]["app"] {
                if let appname=app.element?.text {
                    apps[appname] = app.element?.attributes["id"]
                }
            }
            callback(apps)
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

// MARK: - About

class AboutController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.window?.titlebarAppearsTransparent = true
        self.view.window?.movableByWindowBackground = true
    }
}

// MARK: - Prefs

class PrefsController: NSViewController {

    @IBOutlet var hostfield: NSTextField!
    @IBOutlet var theme: NSSegmentedControl!
    
    let roku = RokuApi()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.window?.titlebarAppearsTransparent = true
        self.view.window?.movableByWindowBackground = true
    }

    override func viewDidAppear() {
        let defs = NSUserDefaults.standardUserDefaults()
        if let host = defs.stringForKey("ROKUHOST") {
            self.hostfield.stringValue = host
        }
        
        if let theme = defs.stringForKey("ROKUTHEME") {
            if theme == "translight" {
                self.theme.selectedSegment = 0
            }
        }

    }
    
    @IBAction func clickSave(sender: NSButton) {
        let defs = NSUserDefaults.standardUserDefaults()
        defs.setObject(self.hostfield.stringValue, forKey: "ROKUHOST")
        
        if 0 == self.theme.selectedSegment {
            defs.setObject("translight", forKey: "ROKUTHEME")
        } else {
            defs.setObject("transdark", forKey: "ROKUTHEME")
        }

        self.dismissController(nil)
    }
    
    @IBAction func clickSearch(sender: NSButton) {
        let host = self.roku.discover()
        if host != "" {
            let defs = NSUserDefaults.standardUserDefaults()
            defs.setObject(self.hostfield.stringValue, forKey: "ROKUHOST")
            self.hostfield.stringValue = host
            
        }
    }
    func setupConnection(){
       
    }
    
}

// MARK: - App View Controller

class ViewController: NSViewController, NSTextFieldDelegate {

    @IBOutlet var inputField: NSTextField!
    @IBOutlet var appsPopup: NSPopUpButton!
    @IBOutlet var bgview: NSVisualEffectView!
    
    
    override func resignFirstResponder() -> Bool {
        return true
    }

    var apps : [String:String] = [:]
    let roku = RokuApi()
    var oldText = ""
    

    func setTheme(theme: String) {
        var mainview:NSVisualEffectView = self.view as! NSVisualEffectView
        mainview.blendingMode = NSVisualEffectBlendingMode.BehindWindow
        if "transdark" == theme {
            // set it to always be blurry regardless of window state
            mainview.state = NSVisualEffectState.Active
            // set the background to always be the dark blur
            mainview.material = NSVisualEffectMaterial.Dark
        } else if "translight" == theme {
            // set it to always be blurry regardless of window state
            mainview.state = NSVisualEffectState.Active
            // set the background to always be the dark blur
            mainview.material = NSVisualEffectMaterial.Light
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        let defs = NSUserDefaults.standardUserDefaults()

        // cast our main vew ref correctly, it's already set in the storyboard
        
        if let theme = defs.stringForKey("ROKUTHEME") {
            setTheme(theme)
        } else {
            setTheme("transdark")
        }
        
        var kpview = self.view as! KeyPressView
        kpview.becomeFirstResponder()
        kpview.keypressed = {(key: String) in
            println("key:" + key)
        }
    }

    override func viewDidAppear() {
        let defs = NSUserDefaults.standardUserDefaults()
        if let host = defs.stringForKey("ROKUHOST") {
            self.roku.host = host
            // setup our dropdown
            self.roku.getApps() { (apps:[String:String]) in
                for name in sorted(apps.keys) {
                    self.apps[name] = apps[name]!
                    println(name)
                    self.appsPopup.addItemWithTitle(name)
                }
            }
        } else {
            self.getRokuHost()
        }
        super.viewDidAppear()
        
        self.view.window?.titlebarAppearsTransparent = true
        self.view.window?.movableByWindowBackground = true
        self.view.window?.styleMask = NSBorderlessWindowMask
        self.inputField.delegate = self
    }
    
    func getRokuHost() {
        alert("Set the IP of your Roku in preferences")
    }
    
   /* override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }*/
    
    // MARK: uitextfield delegate
    
    override func controlTextDidChange(obj: NSNotification) {
        var currstr = self.inputField.stringValue
        if currstr == oldText {
            return
        }
        if count(currstr) < count(oldText) {
            // send delete
            roku.backspace()
            oldText = currstr
        }
        if count(currstr) > count(oldText) {
            var char:String = currstr[-1]
            oldText = currstr
            roku.literal(char)
        }
    }
    
    // MARK: clicks
    
    @IBAction func clickPlay(sender: NSButton) {
        self.roku.play()
    }
    
    @IBAction func clickHome(sender: NSButton) {
        self.roku.home()
    }
    
    @IBAction func clickLeft(sender: NSButton) {
        self.roku.left()
    }
    
    @IBAction func clickRight(sender: NSButton) {
        self.roku.right()
    }

    @IBAction func clickUp(sender: NSButton) {
        self.roku.up()
    }

    @IBAction func clickDown(sender: NSButton) {
        self.roku.down()
    }
    
    @IBAction func clickRewind(sender: NSButton) {
        self.roku.rewind()
    }

    @IBAction func clickForward(sender: NSButton) {
        self.roku.forward()
    }
    
    @IBAction func clickEnter(sender: NSButton) {
        self.roku.enter()
    }
    
    @IBAction func clickInfo(sender: NSButton) {
        self.roku.info()
    }
    
    @IBAction func clickBack(sender: NSButton) {
        self.roku.back()
    }
    
    @IBAction func clickReplay(sender: NSButton) {
        self.roku.replay()
    }
    
    @IBAction func clickQuickLaunch(sender: NSButton) {
        let name = self.appsPopup.selectedItem?.title
        if (count(self.apps) > 0) &&  name != nil{
            if name == "..quickapp" { return }
            print("name: ")
            print(name)
            let id = self.apps[name!]!
            println("APPS:")
            println(self.apps)
            print(" id: ")
            println(id)
            self.roku.launchApp(id)
            }
    }
}

