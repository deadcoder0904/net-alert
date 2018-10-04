import Cocoa
import Reachability
import Defaults
import LaunchAtLogin

extension Defaults.Keys {
	static let launchAtLogin = Defaults.Key<Bool>("launchAtLogin", default: false)
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	let REMOTE_URL: String = "http://captive.apple.com"
	
	var launchAtLoginMenuItem: NSMenuItem = NSMenuItem()
	
	let statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

	let reachability: Reachability = Reachability()!
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		constructMenu()
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	func constructMenu() {
		if let button = statusItem.button {
			button.image = NSImage(named: NSImage.Name("green"))
		}
		
		let menu = NSMenu()
		launchAtLoginMenuItem = NSMenuItem(title: "Launch At Login", action: #selector(self.toggleLaunchAtLogin), keyEquivalent: "")
		launchAtLoginMenuItem.state = defaults[.launchAtLogin] ? .on : .off
		menu.addItem(launchAtLoginMenuItem)
		menu.addItem(NSMenuItem.separator())
		menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
		
		statusItem.menu = menu
		checkConnection()
	}
	
	@objc func toggleLaunchAtLogin() {
		let launchAtLogin = defaults[.launchAtLogin]
		launchAtLoginMenuItem.title = "Launch At Login"
		launchAtLoginMenuItem.state = !launchAtLogin ? .on : .off
		LaunchAtLogin.isEnabled = !launchAtLogin
		defaults[.launchAtLogin] = !launchAtLogin
	}
	
	func setStatusIcon(color: String) {
		if let button = self.statusItem.button {
			if button.image?.name() != color {
				button.image = NSImage(named: NSImage.Name(color))
			}
		}
	}
	
	func pingHost(_ fullURL: String) {

		if let url = URL(string: fullURL) {
			var request = URLRequest(url: url)
			request.httpMethod = "HEAD"

			URLSession(configuration: .default)
				.dataTask(with: request) { (_, response, error) in
					guard error == nil else {
						print("Error:", error ?? "")
						DispatchQueue.main.async {
							self.setStatusIcon(color: "yellow")
						}
						return
					}

					guard (response as? HTTPURLResponse)?
						.statusCode == 200 else {
							print("Offline")
							DispatchQueue.main.async {
								self.setStatusIcon(color: "red")
							}
							return
					}

					print("Online")
					DispatchQueue.main.async {
						self.setStatusIcon(color: "green")
					}
				}
				.resume()
		}
		else {
			 self.setStatusIcon(color: "yellow")
		}
	}

	func checkConnection() {
		reachability.whenReachable = { reachability in
			if reachability.connection == .wifi {
				print("Reachable via WiFi")
				self.pingHost(self.REMOTE_URL)
			} else {
				print("Reachable via Cellular")
				self.pingHost(self.REMOTE_URL)
			}
		}
		
		reachability.whenUnreachable = { _ in
			print("Not reachable")
			self.setStatusIcon(color: "red")
		}
		
		do {
			try reachability.startNotifier()
		} catch {
			print("Unable to start notifier")
			self.setStatusIcon(color: "yellow")
		}
	}
}
