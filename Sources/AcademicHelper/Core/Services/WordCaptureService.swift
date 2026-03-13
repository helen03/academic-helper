import Foundation
import AppKit
import ApplicationServices

protocol WordCaptureServiceProtocol {
    func startMonitoring()
    func stopMonitoring()
    var capturedWord: ((String, String?) -> Void)? { get set }
}

@MainActor
final class WordCaptureService: WordCaptureServiceProtocol {
    private let permissionManager: PermissionManager
    private var isMonitoring = false
    private var lastSelectedText: String = ""
    private var checkTimer: Timer?
    
    var capturedWord: ((String, String?) -> Void)?
    
    init(permissionManager: PermissionManager) {
        self.permissionManager = permissionManager
    }
    
    func startMonitoring() {
        guard permissionManager.hasAccessibilityPermission else {
            print("Accessibility permission not granted")
            return
        }
        
        isMonitoring = true
        
        checkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkSelectedText()
            }
        }
        
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.command) && event.keyCode == 8 {
                self?.captureCurrentSelection()
            }
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    private func checkSelectedText() {
        guard isMonitoring else { return }
        
        let systemWide = AXUIElementCreateSystemWide()
        var focusedElement: AXUIElement?
        var result = AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        guard result == .success, let element = focusedElement else { return }
        
        var selectedTextValue: AnyObject?
        result = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedTextValue)
        
        guard result == .success, let selectedText = selectedTextValue as? String else { return }
        
        if !selectedText.isEmpty && selectedText != lastSelectedText {
            lastSelectedText = selectedText
            if isValidWord(selectedText) {
                capturedWord?(selectedText, nil)
            }
        }
    }
    
    private func captureCurrentSelection() {
        let pasteboard = NSPasteboard.general
        let oldContent = pasteboard.string(forType: .string)
        
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if let text = pasteboard.string(forType: .string), text != oldContent {
                if self?.isValidWord(text) == true {
                    self?.capturedWord?(text, nil)
                }
            }
            
            if let oldContent = oldContent {
                pasteboard.setString(oldContent, forType: .string)
            }
        }
    }
    
    private func isValidWord(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        let wordPattern = "^[a-zA-Z]+(-[a-zA-Z]+)*$"
        let regex = try? NSRegularExpression(pattern: wordPattern)
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        
        return regex?.firstMatch(in: trimmed, options: [], range: range) != nil
    }
}
