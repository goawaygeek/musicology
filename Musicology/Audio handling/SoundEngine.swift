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
