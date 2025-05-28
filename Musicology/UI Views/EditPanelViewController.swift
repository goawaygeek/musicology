//
//  EditPanelViewController.swift
//  Musicology
//
//  Created by Scott Brewer on 5/6/25.
//
import UIKit

class EditPanelViewController: UIViewController, LabelProviding {
    weak var delegate: EditPanelDelegate?
    private var currentItem: GameItem?
    private var currentConfiguration: AudioConfiguration?
    
    private lazy var configurationStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        addLabel(text: "Edit Panel", color: .systemPurple, style: .title1)
        setupConfigurationUI()
    }
    
    private func setupConfigurationUI() {
        view.addSubview(configurationStackView)
        
        NSLayoutConstraint.activate([
            configurationStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            configurationStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            configurationStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // Main method to configure the panel for an item
    func configure(for item: GameItem) {
        currentItem = item
        currentConfiguration = item.audioConfiguration
        
        print("Configured panel for item:", item.type)
        
        // Clear existing configuration UI
        configurationStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Build UI based on configuration type
        buildConfigurationUI(for: item.audioConfiguration)
    }
    
    private func buildConfigurationUI(for configuration: AudioConfiguration) {
        switch configuration {
        case let drumConfig as DrumConfiguration:
            buildDrumConfigurationUI(drumConfig)
        case let cymbalConfig as CymbalConfiguration:
            buildCymbalConfigurationUI(cymbalConfig)
        case let noteConfig as NoteConfiguration:
            buildNoteConfigurationUI(noteConfig)
        case is SilentConfiguration:
            buildSilentConfigurationUI()
        case let emitterConfig as EmitterConfiguration:
            buildEmitterConfigurationUI(emitterConfig)
        default:
            break
        }
    }
    
    // In EditPanelViewController.swift

    private func buildEmitterConfigurationUI(_ config: EmitterConfiguration) { // config is initial state
        // Staggered Checkbox
        let staggeredCheckbox = createCheckbox(
            title: "Staggered Emission",
            isChecked: config.isStaggered // Initial value from the passed config
        ) { [weak self] isChecked in
            print("🔄 Emitter checkbox changed to: \(isChecked)")
            guard let self = self, let emitterItem = self.currentItem as? EmitterItem else {
                print("❌ Self or currentItem (as EmitterItem) is nil in checkbox closure")
                return
            }
            // 1. Get the most current configuration from the item.
            // EmitterItem.audioConfiguration.get creates a new EmitterConfiguration instance.
            guard var updatedConfig = emitterItem.audioConfiguration as? EmitterConfiguration else {
                print("❌ Could not get EmitterConfiguration from emitterItem")
                return
            }
            // 2. Modify the relevant property.
            updatedConfig.isStaggered = isChecked
            // 3. Push the fully updated configuration back.
            self.updateConfiguration(updatedConfig)
        }
        configurationStackView.addArrangedSubview(staggeredCheckbox)
        
        // BPM Slider
        let bpmControl = createBPMControl(
            title: "BPM",
            currentValue: Float(config.bpm), // Initial value from the passed config
            range: 30...250
        ) { [weak self] newBPM in
            print("🔄 BPM slider changed to: \(newBPM)")
            guard let self = self, let emitterItem = self.currentItem as? EmitterItem else {
                print("❌ Self or currentItem (as EmitterItem) is nil in BPM slider closure")
                return
            }
            // 1. Get the most current configuration from the item.
            guard var updatedConfig = emitterItem.audioConfiguration as? EmitterConfiguration else {
                print("❌ Could not get EmitterConfiguration from emitterItem")
                return
            }
            // 2. Modify the relevant property.
            updatedConfig.bpm = Double(newBPM)
            // 3. Push the fully updated configuration back.
            self.updateConfiguration(updatedConfig)
        }
        configurationStackView.addArrangedSubview(bpmControl)
    }
//    private func buildEmitterConfigurationUI(_ config: EmitterConfiguration) {
//        let staggeredCheckbox = createCheckbox(
//            title: "Staggered Emission",
//            isChecked: config.isStaggered
//        ) { [weak self] isChecked in
//            print("🔄 Emitter checkbox changed to: \(isChecked)")
//            guard let emitter = self?.currentItem as? EmitterItem else {
//                print("❌ Self is nil in closure")
//                return }
//            emitter.isStaggered = isChecked
//        }
//        
//        // Add to your container view
//        configurationStackView.addArrangedSubview(staggeredCheckbox)
//        
//        // BPM Slider
//        let bpmControl = createBPMControl(
//            title: "BPM",
//            currentValue: Float(config.bpm),
//            range: 30...250
//        ) { [weak self] newBPM in
//            print("🔄 BPM slider changed to: \(newBPM)")
//            guard let self = self, var currentEmitterConfig = self.currentConfiguration as? EmitterConfiguration else {
//                print("❌ Self is nil or configuration type mismatch in BPM slider closure")
//                return
//            }
//            currentEmitterConfig.bpm = Double(newBPM)
//            self.updateConfiguration(currentEmitterConfig)
//        }
//        configurationStackView.addArrangedSubview(bpmControl)
//    }
    
    private func buildDrumConfigurationUI(_ config: DrumConfiguration) {
    }
    
    private func buildCymbalConfigurationUI(_ config: CymbalConfiguration) {
    }
    
    private func buildNoteConfigurationUI(_ config: NoteConfiguration) {
    }
    
    private func buildSilentConfigurationUI() {
    }
    
    
    private func updateConfiguration(_ configuration: AudioConfiguration) {
        currentConfiguration = configuration
        
        guard let item = currentItem else { return }
        
        // Update the item immediately for real-time preview
        if let draggableItem = item as? DraggableGameItem {
            draggableItem.updateAudioConfiguration(configuration)
        }
        
        // Notify delegate of the change
        delegate?.editPanel(self, didUpdateConfiguration: configuration, for: item)
    }
    
    private func createCheckbox(
        title: String,
        isChecked: Bool,
        onChange: @escaping (Bool) -> Void
    ) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 12
        container.alignment = .center
        
        let checkbox = CheckboxButton(type: .system)
        checkbox.isChecked = isChecked
        checkbox.onChange = onChange
        
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 16)
        
        container.addArrangedSubview(checkbox)
        container.addArrangedSubview(label)
        
        return container
    }
    
    private func createBPMControl(
        title: String,
        currentValue: Float,
        range: ClosedRange<Float>,
        onChange: @escaping (Float) -> Void
    ) -> BPMControl { // Return BPMControl directly
        let bpmControl = BPMControl(title: title, value: currentValue, range: range)
        bpmControl.valueChanged = onChange
        
        // Add any additional styling for the BPMControl itself if needed here
        // For example, setting a specific height or background if not handled internally by BPMControl.
        // bpmControl.heightAnchor.constraint(equalToConstant: 80).isActive = true // Example
        
        return bpmControl
    }
}

// MARK: - Reusable Control Components

class CheckboxButton: UIButton {
    var isChecked: Bool = false {
        didSet {
            updateAppearance()
        }
    }
    var onChange: ((Bool) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        updateAppearance()
    }
    
    private func updateAppearance() {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20) 
        if isChecked {
            setImage(UIImage(systemName: "checkmark.square.fill", withConfiguration: symbolConfig), for: .normal)
            tintColor = .systemBlue // Or your app's accent color
        } else {
            setImage(UIImage(systemName: "square", withConfiguration: symbolConfig), for: .normal)
            tintColor = .gray
        }
    }
    
    @objc private func tapped() {
        isChecked.toggle()
        onChange?(isChecked)
    }
}


class BPMControl: UIControl {
    private let titleLabel = UILabel()
    private let slider = UISlider()
    private let valueLabel = UILabel()
    
    private let mainStackView: UIStackView = { // Holds title and slider+value
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let sliderValueStackView: UIStackView = { // Horizontal stack for slider and its value label
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        return stack
    }()

    var value: Float {
        get { slider.value }
        set {
            let clampedValue = max(slider.minimumValue, min(slider.maximumValue, newValue))
            slider.value = clampedValue
            updateValueLabel()
        }
    }
    
    var valueChanged: ((Float) -> Void)?
    
    init(title: String, value: Float, range: ClosedRange<Float>) {
        super.init(frame: .zero)
        setupViews(title: title, initialValue: value, range: range)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews(title: String, initialValue: Float, range: ClosedRange<Float>) {
        // Configure Title Label
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)

        // Configure Slider
        slider.minimumValue = range.lowerBound
        slider.maximumValue = range.upperBound
        slider.value = initialValue
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        slider.setContentHuggingPriority(.defaultLow, for: .horizontal)


        // Configure Value Label (displays the integer BPM)
        valueLabel.font = .systemFont(ofSize: 16)
        valueLabel.textAlignment = .right
        valueLabel.text = "\(Int(initialValue))"
        // Set a minimum width for the value label to prevent layout jumps
        valueLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 35).isActive = true
        valueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)


        // Assemble the UI
        addSubview(mainStackView)
        
        // Arrange slider and its value label horizontally
        sliderValueStackView.addArrangedSubview(slider)
        sliderValueStackView.addArrangedSubview(valueLabel)

        // Add title and the slider+value group to the main vertical stack
        mainStackView.addArrangedSubview(titleLabel)
        mainStackView.addArrangedSubview(sliderValueStackView)
        
        // Layout for mainStackView within BPMControl
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8), // Add some padding
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
        
        updateValueLabel() // Initial update
    }
    
    private func updateValueLabel() {
        valueLabel.text = "\(Int(slider.value))"
    }
    
    @objc private func sliderChanged(_ sender: UISlider) {
        let steppedValue = round(slider.value)
        slider.value = steppedValue
        updateValueLabel()
        valueChanged?(steppedValue)
    }
}
