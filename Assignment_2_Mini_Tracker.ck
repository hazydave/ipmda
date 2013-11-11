// Class:   Introduction to Programming for Musicians and Digital Artists
// Program: Assignment 2: Mini Tracker 
// Date:    2013-11-04

// This program implements a player engine that processes an array of notes. It
// can play "chained" notes.. more than one in the same time period, based on the
// array contents. It also supports pitch shifting, octaves up or down from the
// standard D Dorian scale defined for the course (eg, it keeps the scale, but 
// changes the octave). You can find auto-panning in the introduction part of the 
// composition, and a few other places -- things move around, headphones recommended.
// There are random functions used for note attack (a negate ramp-in/attack
// value makes that random), and a few other functions. The tick and quantum variables
// (line 646) set the period per line to 0.125, each line represents an 1/8th note,
// and so the quarter note works out to 0.250 seconds, as per the assignment. Notes
// can play without gaps, so 1/8 note + 1/8 note can equal one 1/4 note, as long as
// other paramters don't change the decay or attack. 


<<< "start-> ", "Assignment 2: Mini Tracker" >>>;
now => time program_start;

// Define sound network variables. This allocates ten oscillators and ten pans
// to go with. Once we learn about reference variables and polymorphism, this
// could be extended to support different kinds of oscillators in the same
// array. 

// There are a fixed number of channels available. Right now, there are three 
// voices allocated per channel; all may not be used by each instrument. Also,
// there's a channel 0 reserved for an independent sound generator, like a 
// drum, that's not driven by the table... not used just yet. 

4 => int channel_max;
channel_max * 3 + 1 => int voice_max;
SinOsc voices[voice_max];
Pan2 pans[voice_max];

for (0 => int voice; voices.cap() > voice; ++voice) {
    0 => voices[voice].gain;
    0 => voices[voice].freq;
    voices[voice] => pans[voice] => dac;
}

// Each instrument gets up to three voices for sound generation. The voice is actually specified by the 
// note, but anciliary data is managed for each instrument here. 

// Mnemonics for the "instruments" in the notes table. 

-1 => int switchOFF;        // Used by the synthesis loop

0 => int simpleRest;        // No note
1 => int simpleNote;        // Just a note; the volume and wobble set a volume slide
2 => int simpleVibe;        // A vibrato; the wobble sets the secondary volume
3 => int randomVibe;        // A random vibrato; volume moves randomly off the primary value
4 => int simpleTrem;        // A tremolo; the wobble sets the percentage of note bend
5 => int randomTrem;        // As above, but the bend is randomly set, wobble is the max
6 => int threeNote;         // Like simpleNote, but with a note and first two harmonics
7 => int threeVibe;         // Like simpleVibe, but with a note and first two harmonics
8 => int threeTrem;         // Like simpleTrem, but with a note and first two harmonics
9 => int twoBeat;           // Sets up a second oscillator based on "wobble" Hz from primary

// Notes controls, melody. Should be an object/structure array, but we're not there yet. 
 
// These are the legal notes. I'm giving them nemonic names to make the code to follow
// much easier to read. 
 
 50 => int D4; 52 => int E4; 53 => int F4; 55 => int G4;
 57 => int A4; 59 => int B4; 60 => int C4; 62 => int D5; 
 
 // This is the value for "no wobble for anyone", since I wanted to have it possible for
 // a wobble value of zero and below zero (for realy cut-off). 
 
9999 => int nWOB;
 
// Here's the whole song, note for note. This is a bit like a "tracker" -- kind of an
// early note sequencer from the dawn of post-MIDI electronic music, first used on
// Amiga computers in the mid-1980s.

// Each line specifies the note, an octave shift from our basis ocative, the "instrument"
// to use (determines how the sound is made), the logical sound channel to use (0-3), 
// the volume, a secondary "wobble" adjustment -- instrument specific, and start/stop 
// pan values, which run -180 to 180 degrees. The last field is a "chain" field... if 1,
// the following note is in the same time quantum (presumably on a different channel), 
// if 0, the following note will be the next note in time. A voice left blank will play
// nothing, but an explicit rest can also be in the table for any voice. 
 
 [[ A4,   0, simpleNote, 0,-50,   1,   20, 140, 135, 0 ], // Introduction
  [ A4,   0, simpleNote, 0,-50,  20,   40, 135, 130, 0 ], 
  [ A4,   0, simpleNote, 0,-50,  40,   60, 130, 125, 0 ],
  [ A4,   0, simpleNote, 0,-50,  60,   80, 125, 120, 0 ],
   
  [ C4,   0, simpleNote, 0,-25,   1,   40, 120, 115, 0 ],
  [ C4,   0, simpleNote, 0,-25,  40,   80, 115, 110, 0 ], 
  [ C4,   0, simpleNote, 0,-25,  80,  100, 110, 105, 0 ],
  [ C4,   0, simpleNote, 0,-25, 100, nWOB, 105, 100, 0 ],
   
  [ E4,   0, simpleNote, 0, 25, 100, nWOB, 100,  95, 0 ],
  [ E4,   0, simpleRest, 0, 25, 100, nWOB,  95,  90, 0 ], 
  [ E4,   0, simpleNote, 0, 25, 100, nWOB,  90,  85, 0 ],
  [ E4,   0, simpleRest, 0, 25,   0,    0,  85,  80, 0 ],
   
  [ A4,   0, simpleNote, 0, 25,  80, nWOB,  80,  75, 0 ],
  [ A4,   0, simpleNote, 0, 25, 100, nWOB,  75,  70, 0 ], 
  [ A4,   0, simpleNote, 0, 25, 100, nWOB,  70,  65, 0 ],
  [ A4,   0, simpleRest, 0, 25, 100, nWOB,  65,  60, 0 ],
   
  [ A4,   0, simpleNote, 0,  5,   1,   20,  60,  55, 0 ],
  [ A4,   0, simpleNote, 0,  0,  20,   40,  55,  50, 0 ], 
  [ A4,   0, simpleNote, 0, 25,  40,   60,  50,  45, 0 ],
  [ A4,   0, simpleNote, 0,  0,  60,   80,  45,  40, 0 ],
   
  [ C4,   0, simpleNote, 0, 25,   1,   40,  40,  35, 0 ],
  [ C4,   0, simpleRest, 0, 25,  40,   80,  35,  30, 0 ], 
  [ C4,   0, simpleNote, 0, 25,  80,  100,  30,  25, 0 ],
  [ C4,   0, simpleNote, 0, 25, 100,   50,  25,  20, 0 ],
   
  [ E4,   0, simpleNote, 0, 25, 100,   50,  20,  15, 0 ],
  [ E4,   0, simpleRest, 0, 25, 100,   50,  15,  10, 0 ], 
  [ E4,   0, simpleNote, 0, 25, 100,   50,  10,   5, 0 ],
  [ E4,   0, simpleRest, 0, 25,   0,    0,   5,   0, 0 ],
   
  [ A4,   0, simpleNote, 0, 25,  80,   50,   0,   0, 0 ],
  [ A4,   0, simpleNote, 0, 25, 100,   50,   0,   0, 0 ], 
  [ A4,   0, simpleNote, 0, 25, 100,   50,   0,   0, 0 ],
  [ A4,   0, simpleRest, 0,  0,   0,    0,   0,   0, 0 ],
  
  [ F4,   0, simpleVibe, 0,  0, 100,   70,  45,  45, 1 ], // Part 1.1
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ], 
  [ F4,   0, simpleVibe, 0,  0, 120,   80,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ F4,   0, simpleVibe, 0,  0, 140,   90,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ F4,   0, simpleVibe, 0,  0, 160,  100,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ B4,   0, simpleVibe, 0,  0, 100,   70,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ],
  [ B4,   0, simpleVibe, 0,  0, 120,   80,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ B4,   0, simpleVibe, 0,  0, 140,   90,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ B4,   0, simpleVibe, 0,  0, 160,  100,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ G4,   0, simpleVibe, 0,  0, 100,   70,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ],
  [ G4,   0, simpleVibe, 0,  0, 120,   80,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ C4,   0, simpleVibe, 0,  0, 140,   90,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ C4,   0, simpleVibe, 0,  0, 160,  100,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ F4,   0, simpleVibe, 0,  0, 100,   70,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ F4,   0, simpleVibe, 0,  0, 120,   80,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,  0,  0 ],
  [ B4,   0, simpleVibe, 0,  0, 140,   90,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ B4,   0, simpleVibe, 0,  0, 160,  100,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],

  [ F4,   0, simpleVibe, 0, 25, 120,   70,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ], 
  [ F4,   0, simpleVibe, 0,  0,  70,  120,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ F4,   0, simpleVibe, 0, 25, 120,   70,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ F4,   0, simpleVibe, 0,  0,  70,  120,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ B4,   0, simpleVibe, 0, 25, 120,   70,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, nWOB, -45, -45, 0 ],
  [ B4,   0, simpleVibe, 0,  0,  70,  120,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ B4,   0, simpleVibe, 0, 25, 120,   70,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ B4,   0, simpleVibe, 0,  0,  70,  120,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ G4,   0, simpleVibe, 0, 25, 120,   70,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  80, nWOB, -45, -45, 0 ],
  [ G4,   0, simpleVibe, 0,  0,  70,  120,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  80, -300, -45, -45, 0 ],
  [ C4,   0, simpleVibe, 0, 25, 120,   70,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  [ C4,   0, simpleVibe, 0,  0,  70,  120,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  
  [ F4,   0, simpleVibe, 0, 25, 120,   70,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ F4,   0, simpleVibe, 0, 25,  70,  120,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ B4,   0, simpleVibe, 0, 25, 120,   70,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ B4,   0, simpleVibe, 0, 25,  70,  120,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  
  [ F4,   1, simpleNote, 0, 50, 100, nWOB,  45,  45, 1 ], // Part 1.2
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ], 
  [ F4,   1, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ F4,   1, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ F4,   1, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ B4,   1, simpleNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ],
  [ B4,   1, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0,  80,  10, -120,-120, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ B4,   1, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ B4,   1, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ G4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  80,   75, -45, -45, 0 ],
  [ G4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  80, -300, -45, -45, 0 ],
  [ C4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  [ C4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ A4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  
  [ F4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0, -45, -45, 0 ],
  [ F4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ D4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0, -45, -45, 0 ],
  [ B4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0, -45, -45, 0 ],
  [ B4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ G4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0, -45, -45, 0 ],
  
  [ F4,   1, simpleNote, 0, 50, 100,   75,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ], 
  [ F4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ], 
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ F4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ F4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],

  [ B4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ],
  [ B4,   1, simpleNote, 0,  0, 100,   75,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ B4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ B4,   1, simpleNote, 0,  0, 100,   75,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ G4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  80, nWOB, -45, -45, 0 ],
  [ G4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  80, -300, -45, -45, 0 ],
  [ C4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  [ C4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  
  [ F4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ F4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ D4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ B4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ B4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ G4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],

  
  [ F4,   0, simpleNote, 0, 50, 100,   50,  45,  45, 1 ], // Part 2.1
  [ D4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ], 
  [ F4,   0, simpleNote, 0, 25, 100,   50,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ F4,   0, simpleNote, 0, 25, 100,   50,  45,  45, 1 ],
  [ D4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ F4,   0, simpleNote, 0, 25, 100,   50,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ B4,   0, simpleNote, 0, 25, 100,   50,  45,  45, 1 ],
  [ G4,   2, simpleNote, 1, 50,  80, nWOB, 120, 120, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ],
  [ B4,   0, simpleNote, 0,  0, 100,   50,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ B4,   0, simpleNote, 0, 25, 100,   50,  45,  45, 1 ],
  [ G4,   2, simpleNote, 1, 50,  80, nWOB, 120, 120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ B4,   0, simpleNote, 0,  0, 100,   50,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  
  [ G4,   0, simpleNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ E4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  80, nWOB, -45, -45, 0 ],
  [ G4,   0, simpleNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  80, -300, -45, -45, 0 ],
  [ C4,   0, simpleNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ A4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  [ C4,   0, simpleNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  
  [ F4,   0, simpleNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ D4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ F4,   0, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,  0,  0 ],
  [ B4,   0, simpleNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ G4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ B4,   0, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],

  [ F4,   0, simpleNote, 0, 50, 100,   50,  45,  45, 1 ],
  [ D4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],  
  [ D4,  -1,  threeNote, 3, 10,  80, nWOB, -45, -45, 0 ], 
  [ F4,   0, simpleNote, 0, 25, 100,   50,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  80, -300, -45, -45, 0 ],
  [ F4,   0, simpleNote, 0, 25, 100,   50,  45,  45, 1 ],
  [ D4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ], 
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  [ F4,   0, simpleNote, 0, 25, 100,   50,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  
  [ B4,   0, simpleNote, 0, 25, 100,   50,  45,  45, 1 ],
  [ G4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  80, nWOB, -45, -45, 0 ],
  [ B4,   0, simpleNote, 0,  0, 100,   50,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  80, -300, -45, -45, 0 ],
  [ B4,   0, simpleNote, 0, 25, 100,   50,  45,  45, 1 ],
  [ G4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  [ B4,   0, simpleNote, 0,  0, 100,   50,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  
  [ G4,   0, simpleNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ F4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  80, nWOB, -45, -45, 0 ],
  [ G4,   0, simpleNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  80, -300, -45, -45, 0 ],
  [ C4,   0, simpleNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ A4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  [ C4,   0, simpleNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  
  [ F4,   0, simpleNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ D4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ F4,   0, simpleNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ B4,   0, simpleNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ G4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ B4,   0, simpleNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  
  [ D4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ], // Part 2.2
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ], 
  [ F4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ D4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ F4,   1, simpleNote, 0, 25, 100,   75,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ G4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],  
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ],
  [ B4,   1, simpleNote, 0,  0, 100,   75,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ G4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ B4,   1, simpleNote, 0,  0, 100,   75,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ E4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],  
  [ D4,  -1,  threeNote, 3, 10,  80, nWOB, -45, -45, 0 ],
  [ G4,   1, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  80, -300, -45, -45, 0 ],
  [ A4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  [ C4,   1, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  
  [ D4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ F4,   1, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ G4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ B4,   1, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  
  [ D4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ], 
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ], 
  [ F4,   1, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ D4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ F4,   1, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ G4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ],
  [ B4,   1, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ G4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ B4,   1, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ E4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  80, nWOB, -45, -45, 0 ],
  [ G4,   1, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  80, -300, -45, -45, 0 ],
  [ A4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  [ C4,   1, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],

  [ D4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ F4,   1, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ G4,   2, simpleNote, 1,-50,  80, nWOB, 120, 120, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ B4,   1, simpleNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  
  [  0,   0, simpleRest, 0,  0,   0,    0,   0,   0, 0 ], // Have you seen the bridge? 
  [  0,   0, simpleRest, 0,  0,   0,    0,   0,   0, 0 ],
  [ A4,   0, simpleNote, 0, 25,  10,   60,  90,  90, 0 ],
  [ A4,   0, simpleNote, 0, 25,  60,  100,  90,  90, 0 ],
  [  0,   0, simpleRest, 0,  0,   0,    0,   0,   0, 0 ],  
  [  0,   0, simpleRest, 0,  0,   0,    0,   0,   0, 0 ], 
  [ C4,   0, simpleNote, 0, 25,  60,  100, -90, -90, 0 ],
  [ C4,   0, simpleNote, 0, 25, 100, nWOB, -90,  90, 0 ],
  [  0,   0, simpleRest, 0,  0,   0,    0,   0,   0, 0 ],
  [  0,   0, simpleRest, 0,  0,   0,    0,   0,   0, 0 ],
  [ E4,   0, simpleNote, 0, 25, 100, nWOB,  90,  45, 0 ],
  [ E4,   0, simpleNote, 0, 25, 100, nWOB,  45,   0, 0 ],
  [  0,   0, simpleRest, 0,  0,   0,    0,   0,   0, 0 ],
  [  0,   0, simpleRest, 0,  0,   0,    0,   0,   0, 0 ],
  [ A4,   0, simpleNote, 0, 25, 100, nWOB,   0, -45, 0 ],
  [ A4,   0, simpleNote, 0, 25, 100, nWOB, -45, -90, 0 ],

  [ F4,   0,  threeNote, 0, 50, 100, nWOB,  45,  45, 1 ], // Part 3.1
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ], 
  [ F4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ F4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ F4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ B4,   0,  threeNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ],
  [ B4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  60, -300, -45, -45, 0 ],
  [ B4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  70, -300, -45, -45, 0 ],
  [ B4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  
  [ G4,   0,  threeNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  80, nWOB, -45, -45, 0 ],
  [ G4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  80, -300, -45, -45, 0 ],
  [ C4,   0,  threeNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  [ C4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  
  [ F4,   0,  threeNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ F4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,  0,  0 ],
  [ B4,   0,  threeNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ B4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],

  [ F4,   0,  threeNote, 0, 50, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ], 
  [ F4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ F4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ F4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ B4,   0,  threeNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ],
  [ B4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ B4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ B4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ G4,   0,  threeNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  80, nWOB, -45, -45, 0 ],
  [ G4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  80, -300, -45, -45, 0 ],
  [ C4,   0,  threeNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  [ C4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  
  [ F4,   0,  threeNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ F4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ B4,   0,  threeNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ B4,   0,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  
  [ F4,   1,  threeNote, 0, 50, 100, nWOB,  45,  45, 1 ], // Part 3.2
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ], 
  [ F4,   1,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],  
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ F4,   1,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ F4,   1,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],  
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ B4,   1,  threeNote, 0, 50, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ],
  [ B4,   1,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ], 
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ B4,   1,  threeNote, 0, 50, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ B4,   1,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ], 
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ G4,   1,  threeNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  80,   75, -45, -45, 0 ],
  [ G4,   1,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ], 
  [ D4,  -1,  threeNote, 3,  0,  80, -300, -45, -45, 0 ],
  [ C4,   1,  threeNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  [ C4,   1,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ], 
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  
  [ F4,   1,  threeNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0, -45, -45, 0 ],
  [ F4,   1,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0, -45, -45, 0 ],
  [ B4,   1,  threeNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0, -45, -45, 0 ],
  [ B4,   1,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ G4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0, -45, -45, 0 ],
  
  [ F4,   1,  threeNote, 0, 50, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  80, nWOB, -45, -45, 0 ], 
  [ F4,   1,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  80, -300, -45, -45, 0 ],
  [ F4,   1,  threeNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  [ F4,   1,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ B4,   1,  threeNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  50, nWOB, -45, -45, 0 ],
  [ B4,   1,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  50, -300, -45, -45, 0 ],
  [ B4,   1,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  [ B4,   1,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  50, -300, -45, -45, 0 ],
  
  [ G4,   1,  threeNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3, 10,  80, nWOB, -45, -45, 0 ],
  [ G4,   1,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ D4,  -1,  threeNote, 3,  0,  80, -300, -45, -45, 0 ],
  [ C4,   1,  threeNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  [ C4,   1,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ D4,  -1,  threeNote, 3,  5,  80, -300, -45, -45, 0 ],
  
  [ F4,   1,  threeNote, 0, 25, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ F4,   1,  threeNote, 0,  0,  75, nWOB,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ D4,   1,  threeNote, 0,  0, 100, nWOB,  45,  45, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ],
  [ D4,   1,  threeNote, 0,  0,  75, nWOB,  45,  45, 1 ],
  [ B4,  -2,    twoBeat, 2,  0, 100,   10,-120,-120, 1 ],
  [ 0,    0, simpleRest, 3,  0,   0,    0,   0,   0, 0 ]   // No Coda 
 ] @=> int note_table[][];

// Mnemonics for the inner note table array indices. 

0 => int ntNote;        // This is the root note 
1 => int ntOctave;      // An octave adjustment, + or -
2 => int ntInstrument;  // The algorithm used
3 => int ntChannel;     // Polyphonic channel, 0-3
4 => int ntRamp;        // Attack ramp; if negative, this is randomized
5 => int ntVol;         // Peak volume for note
6 => int ntWobble;      // Used as a wobble volume or frequency, instrument-specific
7 => int ntPanStart;    // Starting pan position, 180 to -180 degrees
8 => int ntPanStop;     // Ending   pan position, 180 to -180 degrees
9 => int ntChain;       // Chain -- next note is in the same time slice when 1
 
// Duration of quantum and a tick, which set the timing for the system. I want to play and change things 
// seemingly at the same time. Each note in the note table is broken up into individual "ticks", which is
// the smallest unit of time in the system. The time each tick plays and the number of ticks per note
// yield the duration of each note in the table, which is current a 1/8 note playing for 1/8th second. 
// The reason for this is to allow things to change during the playing of a note, without having the
// ability to run multiple threads (shreds). 

100 => int ticks;
(0.125/ticks)::second => dur quantum;
     
// For tremolos and vibes, the modulation variable sets half the effective "LFO" period, in ticks. 
10  => int modulation;

// Basic constants for ramping volume up or down. 
10  => int dampen;
5   => int ramp;

// This is the maximum volume to ever use. This is scaled down when there are more channels,
// and equal to the MIDI-like max of 100 (MIDI goes to 127, but I'm just scaling it 0-100). 
// Eventually, this out to be scaled by the number of voices in use. 
0.25 => float max_volume; 

// This is the minimum volume to ever use. Used for "flooring" a volume calculation. 
0 => float ZERO_VOL;

// Working variables
int   note_count;                       // Current ticks in a note
int   note_max;                         // Total ticks in a note
int   note_channel;                     // Channel of working note
int   note_mod_counter;                 // Counter for note modulation
int   note_mod_ramp;                    // Direction for note modulation, as applicable
int   note_instrument[voice_max];       // The instrument number for the current note.
int   note_voice[voice_max];            // The primary voice for the current note
int   note_used[voice_max];             // Voices in use for any cycle
int   note_ramp[voice_max];             // Ramp-up count, in ticks

float note_freq[voice_max];             // Actual note frequency
float note_freq_adj[voice_max];         // Change in frequency for special functions
float note_vol[voice_max];              // Note's volume
float note_vol_adj[voice_max];          // Change in,volume for special functions
float note_ramp_adj[voice_max];         // Ramp-up value
float note_pan[voice_max];              // Note's pan
float note_pan_adj[voice_max];          // Change in pan per tick

// Process the array, one element at a time. 
0 => int note;
0 => int more_notes;
1 => int note_mod_new;
0 => int channel;
0 => int voice;
0 => float temp_volume;

// This loop processes each note in turn. The process is essentially converting the notes table into a
// voice table for the current time slide, which is set by "ticks" and "quantum" variables, up above.
// The first part of this processes the current note and any chained notes, allocating them to the 
// various voice variables above. This looks more complicated than it should be, because we aren't 
// allows to use structures/classes yet. Once that's allowed, there would be a single array of structures
// that include every per-voice parameter (freq, pan, etc). 

while (note_table.cap() > note) {    
    // Set the number of ticks for this note
    ticks => note_count => note_max;
    0 => note_mod_counter;
    1 => more_notes;
    1 => note_mod_ramp;

    // Clear previous settings, to avoid clicks or holdovers. Note that volume isn't adjusted; that's actually
    // dampened in the slot after a voice has been disabled, to prevent any clicking. 
    for (0 => int voice; voices.cap() > voice; ++voice) {
        0 => note_pan_adj[voice];
        0 => note_freq_adj[voice];
        0 => note_vol_adj[voice];
        0 => note_used[voice];
    }
    
    // Initialize all of the per-note information. Keep in mind that the notes table thinks in channels, while
    // most of the synthesis engine below thinks in voices. This loop sets up at least one voice (which could 
    // actually be a rest, so no guarantee anything plays), and any chained notes. The presumption is that each
    // note uses a different channel, but there's no checking done. 
    while (more_notes) {  
        // Get the working channel number;
        note_table[note][ntChannel] => channel;
        channel * 3 + 1 => voice;
        1 => note_used[voice];
          
        // Set the note, including octave adjustment
        Std.mtof(note_table[note][ntNote]) * Math.pow(2.0,note_table[note][ntOctave]) => note_freq[voice];
    
        // Set the ramp-up variables
        note_table[note][ntRamp] => note_ramp[voice];
        
        // Set the volume. This may include a volume ramp-up (a simple attack setting), which will
        // build to the final volume based on the ramp count. 
        note_table[note][ntVol] * max_volume/100.00 => temp_volume;
        if (0 == note_ramp[voice]) {
             temp_volume => note_vol[voice];
             0 => note_ramp_adj[voice];
        } else {
            if (note_ramp[voice] < 0) {
                Math.random2(-1 * note_ramp[voice]/2, -1 * note_ramp[voice]) => note_ramp[voice];
            }   
            temp_volume / note_ramp[voice] => note_ramp_adj[voice];
            0 => note_vol[voice];
        }
        
        // Set the pan. If start and stop pan aren't the same, the pan will sweep duing the note
        note_table[note][ntPanStart]/180.0 => note_pan[voice];
        (note_table[note][ntPanStart] - note_table[note][ntPanStop])/(180.0 * note_max) => note_pan_adj[voice];
    
        // Set the instrument and voice.
        note_table[note][ntInstrument]   => note_instrument[voice];
        note_table[note][ntChannel]*3+1  => note_voice[voice];
        
        // Instrument-specific setup. There are different sounds.
        
        // The simpleNote plays a one-oscillator note. It can also do automatic volume fading, fading from the
        // volume setting down to the "wobble" value. This is always a linear fade. 
        if (simpleNote == note_instrument[voice]) {
            if (nWOB != note_table[note][ntWobble]) {
                (temp_volume - (note_table[note][ntWobble] * max_volume/100.00))/note_max => note_vol_adj[voice];
            } else {
                0 => note_vol_adj[voice];
            }
        } 

        // The simpleVibe switches the voice's volume between the volume value and the wobble value from the
        // table. This happens smoothly, based on the value of "modulation".
        if (simpleVibe == note_instrument[voice]) {
            (temp_volume - (note_table[note][ntWobble] * max_volume/100.00))/modulation => note_vol_adj[voice];
        } 
        
        // Essentially the same as simpleVibe, but with a randomly selected wobble
        if (randomVibe == note_instrument[voice]) {
            temp_volume => note_vol[voice];
            (note_table[note][ntWobble] * max_volume/100.00) => note_vol_adj[voice];
        } 
        
        // The simpleTrem switches the voice's frequency between the note value and a change based on the wobble
        // value as a percentage of the difference between this note and the next one. Still some bugs in this
        // one. The randomTrem does the same, only with a random shift. 
        if (simpleTrem == note_instrument[voice] || randomTrem == note_instrument[voice]) {
            (Std.mtof(note_table[note][ntNote]+1) * Math.pow(2.0,note_table[note][ntOctave]) - note_freq[voice])*(note_table[note][ntWobble]/(200.0)) => note_freq_adj[voice];  
            note_freq_adj[voice] +=> note_freq[voice]; 
        }
 
        // This instrument type basically builds three simpleNote or simpleVibe instruments. Most parameters will be the same, but the
        // volume applies to all three channels mixed (so these don't sound louder than single-voice instruments) and the frequencies
        // set is the note and the first two harmonics. 
        if (threeNote == note_instrument[voice] || threeVibe == note_instrument[voice]) {
            if (threeVibe == note_instrument[voice]) {
               (temp_volume - (note_table[note][ntWobble] * max_volume/100.00))/modulation => note_vol_adj[voice];
            } else if (nWOB != note_table[note][ntWobble]) {
               (temp_volume - (note_table[note][ntWobble] * max_volume/100.00))/note_max => note_vol_adj[voice] => note_vol_adj[voice+1] => note_vol_adj[voice+2];
            } else {
                0 => note_vol_adj[voice] => note_vol_adj[voice+1] => note_vol_adj[voice+2]; 
            }
            note_voice[voice]+1 => note_voice[voice+1];
            note_voice[voice]+2 => note_voice[voice+2];
            1 => note_used[voice+1] => note_used[voice+2];         
           
            note_vol[voice]/3 => note_vol[voice]  => note_vol[voice+1] => note_vol[voice+2];
            note_ramp[voice] => note_ramp[voice+1] => note_ramp[voice+2];
            note_ramp_adj[voice]/3 => note_ramp_adj[voice] => note_ramp_adj[voice+1] => note_ramp_adj[voice+2];
            
            note_pan[voice] => note_pan[voice+1] => note_pan[voice+2];
            note_pan_adj[voice] => note_pan_adj[voice+1] => note_pan_adj[voice+2];
            
            note_freq[voice] * 2 => note_freq[voice+1];
            note_freq[voice] * 4 => note_freq[voice+2];
            
            // This is now treated as three independent simpleNotes or simpleVibes
            if (threeNote == note_instrument[voice]) {
                simpleNote => note_instrument[voice] => note_instrument[voice+1] => note_instrument[voice+2];
            } else {
                simpleVibe => note_instrument[voice] => note_instrument[voice+1] => note_instrument[voice+2];
            }
        }  
        
        // This does a similar 3-voice thing, only with Tremolo. The simpleTrem bug currently messes this up, too. 
        if (threeTrem == note_instrument[voice]) {
            (Std.mtof(note_table[note][ntNote]+1) * Math.pow(2.0,note_table[note][ntOctave]) - note_freq[voice])*(note_table[note][ntWobble]/(200.0)) => note_freq_adj[voice];  

            note_freq_adj[voice] * 2 => note_freq_adj[voice+1];
            note_freq_adj[voice] * 4 => note_freq_adj[voice+2];       
            note_freq[voice] * 2 + note_freq_adj[voice+1] => note_freq[voice+1];
            note_freq[voice] * 4 + note_freq_adj[voice+2] => note_freq[voice+2];
 
            note_freq_adj[voice] +=> note_freq[voice]; 
            
            note_voice[voice]+1 => note_voice[voice+1];
            note_voice[voice]+2 => note_voice[voice+2];
            1 => note_used[voice+1] => note_used[voice+2];
            
            note_vol[voice] / 3 => note_vol[voice]  => note_vol[voice+1] => note_vol[voice+2];
            note_ramp[voice] => note_ramp[voice+1] => note_ramp[voice+2];
            note_ramp_adj[voice] /3 => note_ramp_adj[voice] => note_ramp_adj[voice+1] => note_ramp_adj[voice+2];
            
            note_pan[voice] => note_pan[voice+1] => note_pan[voice+2];
            note_pan_adj[voice] => note_pan_adj[voice+1] => note_pan_adj[voice+2];
            
            // This is now treated as three independent simpleTrems
            simpleTrem => note_instrument[voice] => note_instrument[voice+1] => note_instrument[voice+2];   
        }

        // This creates two simpleNote instruments at a frequency difference set by the wobble parameter... which will
        // be the beat frequency between the two. 
        if (twoBeat == note_instrument[voice]) {
            note_voice[voice]+1 => note_voice[voice+1];
            1 => note_used[voice+1];
            
            note_vol[voice] / 2 => note_vol[voice]  => note_vol[voice+1];
            note_ramp[voice] => note_ramp[voice+1];
            note_ramp_adj[voice] / 2 => note_ramp_adj[voice] => note_ramp_adj[voice+1];
            
            note_pan[voice] => note_pan[voice+1];
            note_pan_adj[voice] => note_pan_adj[voice+1];
            
            note_freq[voice] +  note_table[note][ntWobble] => note_freq[voice+1];
                       
            // This is now treated as two independent simpleNotes or simpleVibes
            simpleNote => note_instrument[voice] => note_instrument[voice+1];
        }  
    
        // This allows a rest to be programmed in the notes table. This allows notes to be shut off without 
        // changing any parameters, or note periods where nothing plays. 
        if (simpleRest == note_instrument[voice]) {
            0 => note_freq[voice];
        }
               
        // Chained slice or next? 
        if (!note_table[note][ntChain]) {
            0 => more_notes;
        }
        
        ++note;
    }
    
    // Nicely close off unused voices. Any voice that was playing in the last segment but not the current
    // gets a ramp-down on volume
    for (1 => voice; voice_max > voice; ++voice) {
        if (!note_used[voice]) {
            voices[note_voice[voice]].gain() / dampen => note_vol_adj[voice];
            voices[note_voice[voice]].gain() - note_vol_adj[voice] => note_vol[voice];
            switchOFF => note_instrument[voice];
        }
    }            

    // This is the "player" loop. This loops over each tick and each voice, adjusting any parameters that
    // change during a note. Each pass through the outer loop runs in one "quantum".   
    while (note_count--) {
        // Update global modulation variables (since we can't use % yet...)
        if (0 >= note_mod_counter) {
           modulation => note_mod_counter;
           !note_mod_ramp => note_mod_ramp;
           1 => note_mod_new;
        }     
             
        for (1 => voice; voice_max > voice; ++voice) {
            // Set the frequency, with random wobble if requested.         
            note_freq[voice] => voices[note_voice[voice]].freq;        
        
            // Apply current pan setting, update for next pass
            note_pan[voice] => pans[note_voice[voice]].pan;
            note_pan_adj[voice] -=> note_pan[voice];
            
            // Standard output gain control
            if (note_used[voice]) {
                Math.max(ZERO_VOL,note_vol[voice]) => voices[note_voice[voice]].gain;
            }
            
            // Instrument-specific stuff?
            
            // A simpleNote needs to update the volume, if we're ramping down volume. This floors at zero,
            // to allow a negative final volume value to be used to cut notes shorter than a whole cycle. 
            if (simpleNote == note_instrument[voice]) {
                if (0 == note_ramp[voice]) {
                    note_vol_adj[voice] -=> note_vol[voice];
                } else {
                    note_ramp_adj[voice] +=> note_vol[voice];
                }
                if (note_vol[voice] <= ZERO_VOL) {
                   0 => voices[note_voice[voice]].freq;
                } 
            }
            // A simple Vibe looks at the phase of the modulation (note_mod_ramp) to determine whether 
            // the volume is going up or down, and applies that at every tick. 
            if (simpleVibe == note_instrument[voice]) {
                   if (0 != note_ramp[voice]) {
                    note_ramp_adj[voice] +=> note_vol[voice];
                } else if (0 == note_mod_ramp) {
                    note_vol_adj[voice] -=> note_vol[voice];
                } else {
                    note_vol_adj[voice] +=> note_vol[voice];
                }
            }
            // The randomVibe sets a random gain adjustment with every modulation period. This currently has problems,
            // doesn't co-exist with volume ramp-up. 
            if (randomVibe == note_instrument[voice]) {
                if (0 != note_ramp[voice]) {
                    Math.max(ZERO_VOL,Math.random2f(note_vol_adj[voice],note_vol[voice])) => voices[note_voice[voice]].gain;
                } else if (note_mod_new) {
                    Math.max(ZERO_VOL,Math.random2f(note_vol_adj[voice],note_vol[voice])) => voices[note_voice[voice]].gain;
                }
            }
            // Simple tremolo ramps pitch up or down based on the phase of modulation. 
            if (simpleTrem == note_instrument[voice]) {
                if (0 != note_ramp[voice]) {
                    note_ramp_adj[voice] +=> note_vol[voice];
                    0 => note_mod_ramp;
                } else if (0 == note_mod_ramp) {
                    note_freq[voice] + note_freq_adj[voice] => voices[note_voice[voice]].freq;   
                } else {
                    note_freq[voice] - note_freq_adj[voice] => voices[note_voice[voice]].freq;   
                }
            }
            // The randomTrem randomizes the pitch adjustment, alternating up and down adjustments. 
            if (randomTrem == note_instrument[voice]) {
                if (0 != note_ramp[voice]) {
                    note_ramp_adj[voice] +=> note_vol[voice];
                    0 => note_mod_ramp;
                } else if (0 == note_mod_ramp) {
                    note_freq[voice] + Math.random2f(note_freq_adj[voice]/3,note_freq_adj[voice]) => voices[note_voice[voice]].freq;   
                } else {
                    note_freq[voice] - Math.random2f(note_freq_adj[voice]/3,note_freq_adj[voice]) => voices[note_voice[voice]].freq;   
                }
            }
            // The switchOFF is just decaying the voices volume to zero. 
            if (switchOFF == note_instrument[voice]) {
                Math.max(ZERO_VOL,note_vol[voice]) => voices[note_voice[voice]].gain;
                note_vol_adj[voice] -=> note_vol[voice];
            }
            
            // Decrement the ramp-in period, floor it at zero. 
            if (0 != note_ramp[voice]) {
                --note_ramp[voice];
            }
       
        } 
        // Adjust the modulation counters;
        0 => note_mod_new;
        --note_mod_counter;
        
        // Play one quantum of music. 
        quantum => now;
    }
}

<<< "end-> ", (now - program_start) / second, "sec" >>>;
