import SwiftUI
import SwiftData

@main
struct AcademicHelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        ServiceContainer.shared.initialize()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1400, height: 900)
        
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    @Inject private var wordCaptureService: WordCaptureServiceProtocol
    @Inject private var eventBus: EventBus
    
    private var captureWindowController: WordCaptureWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        EventBus.shared.publish(AppEvents.Application.didFinishLaunching)
        
        // Setup word capture
        setupWordCapture()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        EventBus.shared.publish(AppEvents.Application.willTerminate)
        wordCaptureService.stopMonitoring()
    }
    
    private func setupWordCapture() {
        wordCaptureService.capturedWord = { [weak self] word, context in
            Task { @MainActor in
                self?.showWordCapturePopup(word: word)
            }
        }
        
        wordCaptureService.startMonitoring()
    }
    
    private func showWordCapturePopup(word: String) {
        // Close existing popup
        captureWindowController?.close()
        
        // Create and show new popup
        captureWindowController = WordCaptureWindowController(word: word)
        captureWindowController?.showWindow(nil)
    }
}
