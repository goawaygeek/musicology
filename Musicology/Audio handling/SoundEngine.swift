//
//  SoundEngine.swift
//  Musicology
//
//  Created by Scott Brewer on 5/16/25.
//

// local interface to audiokit; manages sound playback in a single class.


import AudioKit
import Foundation
import SoundpipeAudioKit
import DunneAudioKit

class SoundEngine {
    // Audio engine components
    private var engine: AudioEngine!
    private var mixer: Mixer!
    
    // Sound generators
    private var noteOscillator: Oscillator!
    private var noteADSR: AmplitudeEnvelope!
    
    private var cymbalNoise: WhiteNoise!
    private var cymbalFilter: HighPassFilter!
    private var cymbalADSR: AmplitudeEnvelope!
    
    private var snareNoise: WhiteNoise!
    private var snareFilter: BandPassFilter!
    private var snareADSR: AmplitudeEnvelope!
    
    private var kickOscillator: Oscillator!
    private var kickADSR: AmplitudeEnvelope!
    
    init() {
        setupAudioEngine()
        setupNotificationObserver()
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCollisionNotification(_:)),
            name: .itemCollisionOccurred,
            object: nil
        )
    }
    
    @objc private func handleCollisionNotification(_ notification: Notification) {
        guard let audioConfig = notification.userInfo?["audioConfiguration"] as? AudioConfiguration else {
            return
        }
        
        playSound(with: audioConfig)
    }
    
    func playSound(with configuration: AudioConfiguration) {
        switch configuration {
        case let drumConfig as DrumConfiguration:
            playDrum(with: drumConfig)
        case let cymbalConfig as CymbalConfiguration:
            playCymbal(with: cymbalConfig)
        case let noteConfig as NoteConfiguration:
            playNote(with: noteConfig)
        case is SilentConfiguration:
            break // Do nothing for silent items
        default:
            print("Unknown audio configuration type")
        }
    }
    
    private func playNote(with config: NoteConfiguration) {
        // Convert note string to frequency
        let frequency = noteStringToFrequency(config.note)
        noteOscillator.frequency = AUValue(frequency)
        
        // Apply volume
        noteOscillator.amplitude = AUValue(config.volume * 0.5) // Scale to reasonable range
        
        // Set waveform based on configuration
        // updateOscillatorWaveform(noteOscillator, waveShape: config.waveShape)
        
        // Start the ADSR envelope
        noteADSR.openGate()
        
        // Stop the note after configured duration
        let durationSeconds = config.duration / 1000.0 // Convert ms to seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + durationSeconds) {
            self.noteADSR.closeGate()
        }
    }
    
    private func playCymbal(with config: CymbalConfiguration) {
        // Adjust filter based on cymbal type
        switch config.cymbalType {
        case .hiHat:
            cymbalFilter.cutoffFrequency = 10000
            cymbalNoise.amplitude = AUValue(config.volume * 0.2)
        case .crash:
            cymbalFilter.cutoffFrequency = 8000
            cymbalNoise.amplitude = AUValue(config.volume * 0.3)
        case .ride:
            cymbalFilter.cutoffFrequency = 6000
            cymbalNoise.amplitude = AUValue(config.volume * 0.25)
        }
        
        // Adjust decay based on configuration
        cymbalADSR.decayDuration = AUValue(0.1 + (config.decay * 0.4)) // 0.1 to 0.5 seconds
        
        cymbalADSR.openGate()
        
        // Auto-release after decay time
        let releaseTime = cymbalADSR.decayDuration + 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(releaseTime)) {
            self.cymbalADSR.closeGate()
        }
    }
    
    private func playDrum(with config: DrumConfiguration) {
        switch config.drumType {
        case .snare:
            playSnare(volume: config.volume, pitch: config.pitch)
        case .kick:
            playKick(volume: config.volume, pitch: config.pitch)
        case .floor:
            playFloorTom(volume: config.volume, pitch: config.pitch)
        case .rack:
            playRackTom(volume: config.volume, pitch: config.pitch)
        }
    }
    
    private func playSnare(volume: Float, pitch: Float) {
        // Adjust frequency based on pitch (-1.0 to 1.0)
        let baseCenterFreq: AUValue = 1200
        let pitchMultiplier = pow(2.0, pitch) // Semitone adjustment
        snareFilter.centerFrequency = baseCenterFreq * AUValue(pitchMultiplier)
        
        snareNoise.amplitude = AUValue(volume * 0.4)
        snareADSR.openGate()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.snareADSR.closeGate()
        }
    }
    
    private func playKick(volume: Float, pitch: Float) {
        let baseFreq: AUValue = 60
        let pitchMultiplier = pow(2.0, pitch)
        let targetFreq = baseFreq * AUValue(pitchMultiplier)
        
        kickOscillator.amplitude = AUValue(volume * 0.8)
        kickOscillator.frequency = targetFreq * 2 // Start higher
        
        kickADSR.openGate()
        
        // Pitch slide effect
        let pitchSlideDuration = 0.1
        let pitchChangeSteps = 10
        let pitchStepTime = pitchSlideDuration / Double(pitchChangeSteps)
        let freqDiff = targetFreq
        
        for i in 1...pitchChangeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (pitchStepTime * Double(i))) {
                self.kickOscillator.frequency = (targetFreq * 2) - (freqDiff * AUValue(Double(i) / Double(pitchChangeSteps)))
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.kickADSR.closeGate()
        }
    }
    
    // New methods for additional drum types
    private func playFloorTom(volume: Float, pitch: Float) {
        // Floor tom - lower frequency than snare
        let baseCenterFreq: AUValue = 800
        let pitchMultiplier = pow(2.0, pitch)
        snareFilter.centerFrequency = baseCenterFreq * AUValue(pitchMultiplier)
        snareFilter.bandwidth = 400
        
        snareNoise.amplitude = AUValue(volume * 0.5)
        snareADSR.decayDuration = 0.4 // Longer decay for tom
        snareADSR.openGate()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.snareADSR.closeGate()
            // Reset decay for snare
            self.snareADSR.decayDuration = 0.2
        }
    }
    
    private func playRackTom(volume: Float, pitch: Float) {
        // Rack tom - higher than floor tom, lower than snare
        let baseCenterFreq: AUValue = 1000
        let pitchMultiplier = pow(2.0, pitch)
        snareFilter.centerFrequency = baseCenterFreq * AUValue(pitchMultiplier)
        snareFilter.bandwidth = 500
        
        snareNoise.amplitude = AUValue(volume * 0.45)
        snareADSR.decayDuration = 0.3
        snareADSR.openGate()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.snareADSR.closeGate()
            // Reset decay for snare
            self.snareADSR.decayDuration = 0.2
        }
    }
    
    // Helper method to convert note strings to frequencies
    private func noteStringToFrequency(_ noteString: String) -> Double {
        // Simple implementation - you might want to use a more comprehensive one
        let noteMap: [String: Double] = [
            "C4": 261.63, "C#4": 277.18, "D4": 293.66, "D#4": 311.13,
            "E4": 329.63, "F4": 349.23, "F#4": 369.99, "G4": 392.00,
            "G#4": 415.30, "A4": 440.00, "A#4": 466.16, "B4": 493.88,
            "C3": 130.81, "D3": 146.83, "E3": 164.81, "F3": 174.61,
            "G3": 196.00, "A3": 220.00, "B3": 246.94,
            "C5": 523.25, "D5": 587.33, "E5": 659.25, "F5": 698.46,
            "G5": 783.99, "A5": 880.00, "B5": 987.77
        ]
        
        return noteMap[noteString] ?? 261.63 // Default to C4
    }
    
    private func updateOscillatorWaveform(_ oscillator: Oscillator, waveShape: NoteConfiguration.WaveShape) {
        // TODO: this isn't being called for now, I would like to have the
        // ability to change waveshapes but it is definitely a P2 not a P0
//        let waveform: Table
//        switch waveShape {
//        case .sine:
//            waveform = Table(.sine)
//        case .square:
//            waveform = Table(.square)
//        case .sawtooth:
//            waveform = Table(.sawtooth)
//        case .triangle:
//            waveform = Table(.triangle)
//        }
        
        
    }
    
    private func setupAudioEngine() {
        // Initialize the audio engine
        engine = AudioEngine()
        mixer = Mixer()
        
        // Create the sound generators
        setupNoteGenerator()
        setupCymbalGenerator()
        setupSnareGenerator()
        setupKickGenerator()
        
        // Connect the mixer to the engine output
        engine.output = mixer
        
        // Start the engine
        do {
            try engine.start()
        } catch {
            print("AudioKit error: \(error.localizedDescription)")
        }
    }
    
    private func setupNoteGenerator() {
        // Note oscillator - C4 = 261.63 Hz
        noteOscillator = Oscillator(waveform: Table(.sine))
        noteOscillator.frequency = 261.63
        noteOscillator.amplitude = 0.5
        
        // ADSR envelope
        noteADSR = AmplitudeEnvelope(noteOscillator)
        noteADSR.attackDuration = 0.05
        noteADSR.decayDuration = 0.1
        noteADSR.sustainLevel = 0.7
        noteADSR.releaseDuration = 0.2
        
        // Add to mixer
        mixer.addInput(noteADSR)
        
        // Initialize oscillator but don't start it yet
        noteOscillator.start()
    }
    
    private func setupCymbalGenerator() {
        // White noise for cymbal
        cymbalNoise = WhiteNoise()
        cymbalNoise.amplitude = 0.3
        
        // High-pass filter to make it sound like a cymbal
        cymbalFilter = HighPassFilter(cymbalNoise)
        cymbalFilter.cutoffFrequency = 8000
        cymbalFilter.resonance = 0.3
        
        // Fast attack, medium decay for cymbal sound
        cymbalADSR = AmplitudeEnvelope(cymbalFilter)
        cymbalADSR.attackDuration = 0.001
        cymbalADSR.decayDuration = 0.3
        cymbalADSR.sustainLevel = 0.0
        cymbalADSR.releaseDuration = 0.1
        
        // Add to mixer
        mixer.addInput(cymbalADSR)
        
        // Start the noise but not the envelope
        cymbalNoise.start()
    }
    
    private func setupSnareGenerator() {
        // White noise for snare body
        snareNoise = WhiteNoise()
        snareNoise.amplitude = 0.4
        
        // Band-pass filter for snare character
        snareFilter = BandPassFilter(snareNoise)
        snareFilter.centerFrequency = 1200
        snareFilter.bandwidth = 600
        
        // Quick attack and decay for snare
        snareADSR = AmplitudeEnvelope(snareFilter)
        snareADSR.attackDuration = 0.001
        snareADSR.decayDuration = 0.2
        snareADSR.sustainLevel = 0.0
        snareADSR.releaseDuration = 0.05
        
        // Add to mixer
        mixer.addInput(snareADSR)
        
        // Start the noise but not the envelope
        snareNoise.start()
    }
    
    private func setupKickGenerator() {
        // Sine wave oscillator for the kick
        kickOscillator = Oscillator(waveform: Table(.sine))
        kickOscillator.frequency = 60
        kickOscillator.amplitude = 0.8
        
        // Quick attack and medium decay for kick
        kickADSR = AmplitudeEnvelope(kickOscillator)
        kickADSR.attackDuration = 0.001
        kickADSR.decayDuration = 0.15
        kickADSR.sustainLevel = 0.0
        kickADSR.releaseDuration = 0.1
        
        // Add to mixer
        mixer.addInput(kickADSR)
        
        // Start the oscillator but not the envelope
        kickOscillator.start()
    }
    
    // Play sound functions
    func playNote() {
        // Start the ADSR envelope
        noteADSR.openGate()
        
        // Stop the note after half a second
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.noteADSR.closeGate()
        }
    }
    
    func playCymbal() {
        cymbalADSR.openGate()
        
        // Auto-release after a short time
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.cymbalADSR.closeGate()
        }
    }
    
    func playSnare() {
        snareADSR.openGate()
        
        // Auto-release after a short time
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.snareADSR.closeGate()
        }
    }
    
    func playKick() {
        // Quick pitch envelope for the kick (manually done)
        let initialFreq = kickOscillator.frequency
        kickOscillator.frequency = 120 // Start higher
        
        kickADSR.openGate()
        
        // Slide the frequency down
        let pitchSlideDuration = 0.1
        let pitchChangeSteps = 10
        let pitchStepTime = pitchSlideDuration / Double(pitchChangeSteps)
        let freqDiff = (120 - 60) / Double(pitchChangeSteps)
        
        for i in 1...pitchChangeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (pitchStepTime * Double(i))) {
                self.kickOscillator.frequency = AUValue(120 - (freqDiff * Double(i)))
            }
        }
        
        // Auto-release after a short time
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.kickADSR.closeGate()
            
            // Reset frequency for next play
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.kickOscillator.frequency = initialFreq
            }
        }
    }
    
    // Optional generic play method
    func play(_ instrument: Instrument) {
        switch instrument {
        case .note:
            playNote()
        case .cymbal:
            playCymbal()
        case .snare:
            playSnare()
        case .kick:
            playKick()
        }
    }
}

// Enum for the optional play(instrument) function
enum Instrument {
    case note, cymbal, snare, kick
}
