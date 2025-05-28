# Musicology
## Purpose
Musicology was started as a project to get my Swift understanding up to date.  The main things I hoped to accomplish were:
 * Investigating modern Swift practices (it had been a while since I had written any Swift!)
 * Use the Apple Pencil as an interface tool (which I decided to do from scratch rather than use PencilKit)
 * Leveraging CreateML to do *something* with ML on device.
 * Work with Packages
 * Try out some AI coding assistants
 * Make something fun :)

## What is it?!
Well, it is designed to be a game, but the 'game' element isn't in there yet so it is basically just a musical battlefield with no way to win, think of it as a practice range.  
The point of the game is to use gestures (with the Apple Pencil, although your finger works too) to draw symbols that get deciphered by the ML model to become elements in a music making gameboard.
The 'game' would eventually have a target track at the top that you would listen to and try to match by placing items on your gameboard.  Your output would eventually show up down the bottom and comparisons would give you a score out of 100.

## How does it look now?
Here's a terrible YouTube video of the current state (filming with one hand while drawing with the other isn't my strong suit!). 

[![Live demo](https://img.youtube.com/vi/0xNNp8R0BGs/0.jpg)](https://www.youtube.com/watch?v=0xNNp8R0BGs)

## How was it built?
So first things first, this thing has been hacked together and will always need refactoring, but what you're seeing now is where it's at...now!

The development was undertaken in the five key phases:
1. Gesture capture / recognition
2. ML training & implementation
3. Animation and collision detection
4. Audio Engine rev. 1 & integration
5. Audio controls / editing

The following phases haven't been implemented yet:
1. All items (currently only sound items and emitters have been implemented, effects have not)
2. Output mapping (turning your loop into a waveform / sonogram)
3. Track matching (matching your output to the 'goal' or 'target' input).
4. Game physics (making collisions do more than just play audio)
5. Sharing (under the hood everything will end up mapping to flat files to be easily shared).

## Architecture
### Views
For initial simplicity all the views are laid out and handled by the RootViewController.  It holds the GameBoardViewController, EditPanelViewController, and the Target and Output ViewControllers.  This would definitely get refactored at a later date to make it more adaptable to other devices and orientations, I currently feel like this might be more fun on the phone than on the iPad. This would be a whole different beast but everything here could be refactored pretty quickly to accomodate that.

### Gesture Recognition
A 'DrawingView' sits on top of the GameBoardViewController and captures gestures. Initially this was written with an algorithm (in RecognizeablePath) that monitored input and analysed the Points to work out what shape was being drawn.  It worked pretty nicely but finding an algorithm to differentiate between some of the shapes (like a circle and 'U') was tricky.

### ML training
Years ago I had ported an neural network from Python into Objective-C for fun and my desire was to implement something akin to MNIST and do some image recognition (on shapes/gestures instead of handwriting). So I forked the build I had for capturing the gestures, wrote DrawingClassifier.swift to output them to images then drew 100 triangles, 100 circles, 100 equals signs, etc. fed them all into CreateML and made a model that recognizes the items inside ItemType.swift.  It worked suprisingly well!  I could optimize for speed, but honestly, adding an animation during processing would likely be enough to make the delay feel more engaging.

### Animating the gameboard
This is where the 'game' started to take shape I guess.  I *could* have used a game engine for this but given what I was wanting to do, particularly for testing I figured the easiest thing was to start writing my game items and then handle the animation and collision detection.  I ummed and ahhed a bit before deciding to just bite down on using the 'quickest' way to get things going and that, to begin with, meant using CADisplayLink as the timer inside the GameBoardViewController to control all the animations.  This was done to keep things in sync visually, however, now that the Audio system is in place I would rearchitect this timing system and extract it out of GameBoardViewContoller so I could use higher precision timing and then schedule things to take place with a CADisplayLink for the visuals and one of the more precise audio timers found in AudioKit (there's a separate question as to whether or not I would implement a grid system to keep a more rigid time system for the audio, but, I personally kind of like the free for all that this currently creates).

### Recognising collisions
I built this by having game elements conform to a CollisionObject protocol registering themselves as elements within the CollisionManager.  For now I'm only using the initial collision to trigger audio; however thought has gone into building this so it is ready for a future where collisions also impact the velocity of the balls so that we can impact their speed and direction based on the items they're colliding with.  

### Audio Engine
Now that we had items printing hit statements with they collided it was time for some sound!  I'll be honest and say I had always hated the way iOS development had worked with external libraries like CocoaPods so I wanted to see how this was handled in modern Swift.  Using [AudioKit](https://www.audiokit.io) seemed like a really nice way to get started and man, was it impressive to see all the work they'd done.  Handling audio in iOS used to be a nightmare and I have spent many (MANY!) hours pulling my hair out trying to wrangle it to get done what I wanted, but this gave me a synth engine in like an hour.  The next step was to create some generic patches for using synthesis to play snare, cymbal, kick and synth notes using AudioKit...Claude gave me that code in literal seconds, it kind of blew my mind.

### Audio Controls & Editing
This was the next step in getting things 'real time' (in quotes because of what I said up there about timing, nothing is 'real time' from an audio perspective by any means).  Breaking out the control of the game items and the audio into the edit panel and decoupling it from the gameboard allowed for things to really start feeling 'personal'.  This was when I finally got to the stage that I would consider 'MVP' from a playability perspective and gave me the controls I wanted to start having fun with it.

## What's next?
Right now I'm at a point where I want to heavily refactor the code base.  This was really the 'throw things at the wall to see what sticks' and, well, the playability of the game itself is pretty fun.  It's running better than I possibly would have expected (hovering around 20% CPU on an old (7th gen?) iPad).  I had an itch I wanted to scratch and this definitely scratched it.  

For the refactor I would like to start focussing on minimising the reliance on using GameBoardViewController to do so much.  It's already there, but as I said earlier I would like to rethink the way the app handles it's time management.  Running everything off visual timing (CADisplayLink) isn't the way to make a great 'audio' game.  I *could* have built the audio features first and then it would have started with a much higher precision timing.

Once the refactor is done I would add the effects items (splitters and delays) and then I would attack the visuals, everything is super placeholder.  Then I would move onto the 'gameplay' of matching audio tracks.













