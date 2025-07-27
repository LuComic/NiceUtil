import Cocoa

class MenuToggleView: NSView {
    let toggleSwitch = NSSwitch()
    let helpButton = NSButton()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        // Configure the switch
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
        toggleSwitch.target = self
        toggleSwitch.action = #selector(toggleChanged(_:))
        toggleSwitch.state = UserDefaults.standard.bool(forKey: "openNewWindows") ? .on : .off

        let label = NSTextField(labelWithString: "Open New Windows")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.isSelectable = false
        label.drawsBackground = false
        label.bezelStyle = .roundedBezel

        // Configure the help button
        helpButton.translatesAutoresizingMaskIntoConstraints = false
        helpButton.image = NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: "Help")
        helpButton.bezelStyle = .regularSquare // Use a regular square style
        helpButton.isBordered = false // Remove border
        helpButton.isTransparent = true // Make the background transparent
        helpButton.toolTip = "Open a new window when an occurrence of the app is already running"
        helpButton.target = self
        helpButton.action = #selector(helpButtonClicked(_:))

        // Create a stack view to arrange the elements horizontally
        let stackView = NSStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .horizontal
        stackView.alignment = .centerY // Align items vertically in the center
        stackView.spacing = 5

        stackView.addView(label, in: .leading)
        stackView.addView(toggleSwitch, in: .leading)
        stackView.addView(helpButton, in: .leading)

        addSubview(stackView)

        // Add constraints to the stack view to fill the custom view
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10), // Left align with padding
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -10),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        ])
    }

    @objc private func toggleChanged(_ sender: NSSwitch) {
        UserDefaults.standard.set(sender.state == .on, forKey: "openNewWindows")
    }

    @objc private func helpButtonClicked(_ sender: NSButton) {
        // The help button's primary function is its tooltip. No action needed on click.
        // If a specific action is desired, it would be implemented here.
    }
}