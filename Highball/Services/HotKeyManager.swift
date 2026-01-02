import AppKit
import SwiftUI

@MainActor
final class HotKeyManager: ObservableObject {
    static let shared = HotKeyManager()

    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "hotKeyEnabled")
            if isEnabled {
                registerHotKey()
            } else {
                unregisterHotKey()
            }
        }
    }

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var panelWindow: NSPanel?
    private var clickMonitor: Any?
    weak var statusMonitor: StatusMonitor?

    private init() {
        self.isEnabled = UserDefaults.standard.object(forKey: "hotKeyEnabled") as? Bool ?? true

        if isEnabled {
            registerHotKey()
        }
    }

    private func registerHotKey() {
        unregisterHotKey()

        // Cmd+Shift+H
        let flags: NSEvent.ModifierFlags = [.command, .shift]
        let keyCode: UInt16 = 4 // 'H' key

        // Global monitor (when app is not focused)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == flags &&
               event.keyCode == keyCode {
                Task { @MainActor in
                    self?.handleHotKey()
                }
            }
        }

        // Local monitor (when app is focused)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == flags &&
               event.keyCode == keyCode {
                Task { @MainActor in
                    self?.handleHotKey()
                }
                return nil // consume the event
            }
            return event
        }
    }

    private func unregisterHotKey() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    private func handleHotKey() {
        if let panel = panelWindow, panel.isVisible {
            closePanel()
        } else {
            showPanel()
        }
    }

    private func closePanel() {
        panelWindow?.close()
        panelWindow = nil
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }

    private func showPanel() {
        guard let monitor = statusMonitor else { return }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 400),
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear

        let hostingView = NSHostingView(rootView:
            StatusDropdownView(monitor: monitor)
                .background(VisualEffectView())
                .clipShape(RoundedRectangle(cornerRadius: 10))
        )

        panel.contentView = hostingView

        // Position near mouse cursor
        let mouseLocation = NSEvent.mouseLocation
        panel.setFrameOrigin(NSPoint(
            x: mouseLocation.x - 140,
            y: mouseLocation.y - 200
        ))

        panel.makeKeyAndOrderFront(nil)
        panelWindow = panel

        // Close when clicking outside
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let panel = self.panelWindow else { return }
            let clickLocation = event.locationInWindow
            if !panel.frame.contains(NSEvent.mouseLocation) {
                Task { @MainActor in
                    self.closePanel()
                }
            }
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
