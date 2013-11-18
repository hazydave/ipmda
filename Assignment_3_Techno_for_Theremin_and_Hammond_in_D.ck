// Class:   Introduction to Programming for Musicians and Digital Artists
// Program: Assignment 3: Techno for Theremin and Hammond in D
// Date:    2013-11-04

// This program implements a player engine that processes an array of notes. It
// can play "chained" notes.. more than one in the same time period, based on the
// array contents. It also supports pitch shifting, octaves up or down from the
// standard D Dorian scale defined for the course (eg, it keeps the scale, but 
// changes the octave). You can find auto-panning in the introduction part of the 
// composition, and a few other places -- things move around, headphones recommended.
// There are random functions used for note attack (a negate ramp-in/attack
// value makes that random), and a few other functions. The tick and quantum variables
// (see line 432 and 967) set the period per line to 0.125, each line represents an 
// 1/8th note, and so the quarter note works out to 0.250 seconds, as per the assignment.
// Notes can play without gaps, so 1/8 note + 1/8 note can equal one 1/4 note, as long as
// other paramters don't change the decay or attack. 
// 
// Mini Tracker Too enhancements include specialized entries in the line table allow
// to allow control functions. A SKIP command allows a jump to a jump to a new line
// in the table, which can be probalistic, with up to four chances to jump per line. 
// A LOOP allows a sections of the table to be replayed multiple times, with an
// optional shift in octave, and a also an optional volume scaling, by percentage. 
// Synth modulation envelopes work now; I use the required modulo operator (%) to
// create a square wave modulation as a function, rather than needing an if/else, 
// and also support a sine wave modulation. 

// Since this is a refinement of last week's assignment, I'll answer some of the 
// questions I got in the feedback from last week here:
//
// Q: Is this really 0.25sec notes?
// A: Yes. Not ONLY 0.25sec notes, but that wasn't required. The basic musical idea
//    is built around quarter and half notes. A line in the note table plays for 
//    1/8 second or longer, broken into one hundred small events. This is what allows 
//    smooth panning, note slides, volume ramps, modulation, etc. That's the timbre
//    of the sound, not the music per se. 
//
// Q: Isn't this too complicated for the assignment? 
// A: I'm having fun, and it's not too complicated for me -- though there are still
//    a few bugs. I didn't use the broken parts in the musical composition. I try to
//    take MMOCs seriously, and find a challenge in any assignment. 
//
// Q: Isn't the point of programming this to play around with algorithmic composition? 
// A: For some, perhaps... and hey, I can do random right in the table. But I'm more
//    interesting in messing around with sound itself, which is also possible with
//    ChucK programming. 
// 
// Q: I hear clicks and pops
// A: Maybe. I've been working on it, but it seems pretty specific to the PC's hardware. 
//    I've read in the forums that the Mac implementation does AGC (automatic gain control) 
//    in the dac and maybe other components. PC's don't. So I'll admit it's not perfect,
//    but you might be hearing more clicks and pops than I do. Some of those from last
//    week are definitely gone -- save a WAV of your composition, load it up in a sound 
//    editor like Sound Forge, and you can get a pretty good idea of at least the simple
//    things that cause clicks and pops. Or at least where they're happening. 


<<< "start-> ", "Assignment 2: Mini Tracker Too" >>>;
now => time program_start;

// Define sound network variables. This allocates ten oscillators and ten pans
// to go with. Once we learn about reference variables and polymorphism, this
// could be extended to support different kinds of oscillators in the same
// array. 

// There are a fixed number of channels available. Right now, there are three 
// voices allocated per channel; all may not be used by each instrument. Also,
// there's a channel 0 reserved for an independent sound generator, like a 
// drum, that's not driven by the table... not used just yet. 

4 => int channel_max;                                       // Number of 3-voice synth channels
8 => int sound_max;                                         // Number of sample tracks
0 => int sound_min;                                         // Start of sample tracks
1 => int voice_min;                                         // Start of synth tracks
channel_max * 3 + 1 => int voice_max => int sound_offset;   // End of synth tracks, start of sample tracks
voice_max + sound_max => int track_max;                    // Total number of tracks

SinOsc voices[voice_max];                                   // Total tracks for synthesizer
SndBuf sounds[sound_max];                                   // Total tracks for samples
Pan2 pans[track_max];                                       // Pans for either of them. 

for (0 => int voice; voices.cap() > voice; ++voice) {       // Zero out the pan array, assign pan/dac
    0 => voices[voice].gain;
    0 => voices[voice].freq;
    voices[voice] => pans[voice] => dac;
}

for (0 => int sound; sounds.cap() > sound; ++sound) {        // Zero out the sample array, assign pan/dac
    0 => sounds[sound].gain;
    sounds[sound] => pans[sound+voice_max] => dac;
}

// Channel numbers, logical synth channels (3 voices each) and physical sample channels (8 total)
               0 => int  CH1;                1 => int  CH2;                2 => int CH3;              3 => int CH4;
sound_offset + 0 => int SND1; sound_offset + 1 => int SND2; sound_offset + 2 => int SND3; sound_offset + 3 => int SND4;
sound_offset + 4 => int SND5; sound_offset + 5 => int SND6; sound_offset + 6 => int SND7; sound_offset + 7 => int SND8;


// Each instrument gets up to three voices for sound generation. The voice is actually specified by the 
// note, but anciliary data is managed for each instrument here. 
// Mnemonics for the "instruments" in the notes table. 

-1 => int switchOFF;        // Used by the synthesis loop

0 => int simpleRest;        // No note
1 => int simpleNote;        // Just a note; the volume and wobble set a volume slide
2 => int slideyNote;        // Note slides into the next
4 => int simpleTrem;        // A tremolo; the wobble sets the percentage of note bend
5 => int randomTrem;        // As above, but the bend is randomly set, wobble is the max
6 => int tripleNote;        // Like simpleNote, but with a note and first two harmonics
7 => int tripleDamp;        // Like tripleNote, but with dampened harmonics
8 => int tripleTrem;        // Like simpleTrem, but with a note and first two harmonics
9 => int doubleBeat;        // Sets up a second oscillator based on "wobble" Hz from primary

// Notes controls, melody. Should be an object/structure array, but we're not there yet. 
 
// These are the legal notes. I'm giving them nemonic names to make the code to follow
// much easier to read. 
 
 50 => int D4; 52 => int E4; 53 => int F4; 55 => int G4;
 57 => int A4; 59 => int B4; 60 => int C4; 62 => int D5; 
 
// Mnemonics for common sample rate

 100 => int FWD;
-100 => int REV;
 
// Special note-less line functions
 
9990 => int LOOP;           // Special looping function. 
9991 => int SKIP;           // Special skippin function. 
9992 => int LABL;           // Special label function.
 
// This is the value for a generic "no-op" or "NAN" value.
 
9993 => int nNOP;

// This is the value for "NC" or "No Change"

9994 => int NC;
 
// Various things to support the note table. 

// Mnemonics for the inner note table array indices, for synthesized notes. Mnemonics
// give friendly names to things like array indices, particularly when used in this
// way. When we get to structures/classes, the need for this will go away. That is a
// more powerful format, too, because you're working directly on the mnemonic names,
// and there's no need to work in the same units: strings, ints, floats, and other
// datatypes will be in the same class definition. 

// Mnemonics for a synthesizer entry in the notes table. 
// [note, octave, instrument, channel, ramp, volmax, volmin, wobble, panstart, panstop, chain]

0 => int ntNote;        // This is the root note 
1 => int ntOctave;      // An octave adjustment, + or -
2 => int ntInstrument;  // The algorithm used
3 => int ntChannel;     // Polyphonic channel, 0-3
4 => int ntRamp;        // Attack ramp; if negative, this is randomized
5 => int ntVolMax;      // Peak volume for note
6 => int ntVolMin;      // Minimum volume for note
7 => int ntWobble;      // Used as a wobble volume or frequency, instrument-specific
8 => int ntPanStart;    // Starting pan position, 180 to -180 degrees
9 => int ntPanStop;     // Ending   pan position, 180 to -180 degrees
10=> int ntChain;       // Chain -- next note is in the same time slice when 1

// Mnemonics for the loop function. A loop runs a segment of the notes table more
// than once, and will overlay multiple such segments, for polyphany. 
// [LOOP, length, pass, vadj, start1, start2, start3, start4, start5,  

1 => int lpOctave;      // An octave shift for the whole loop
2 => int lpLength;      // Last note in the slice of the main note table to be looped
3 => int lpPass;        // Count of passes through this loop
4 => int lpVAdj;        // Volume adjustment, as a percentage. 
5 => int lpLine1;       // First line of the first looped segment
6 => int lpLine2;       // Optional first line of the 2nd looped segment
7 => int lpLine3;       // Optional first line of the 3rd looped segment
8 => int lpLine4;       // Optional first line of the 4th looped segment
9 => int lpLine5;       // Optional first line of the 5th looped segment
10=> int lpLine6;       // Optional first line of the 6th looped segment

// Mnemonics for the skip function. SKIP is used instead of a note in a SKIP line. 

1 => int skChance1;     // Percent chance of skipping
2 => int skLine1;       // Line to skip to next if the "dice roll" wins.
3 => int skChance2;     // Percent chance of skipping
4 => int skLine2;       // Line to skip to next if the "dice roll" loses. 
5 => int skChance3;     // Percent chance of skipping
6 => int skLine3;       // Line to skip to next if the "dice roll" wins.
7 => int skChance4;     // Percent chance of skipping
8 => int skLine4;       // Line to skip to next if the "dice roll" loses. 
9 => int skRES1;        // Reserved field
10=> int skRES2;        // Reserved field

// Mnemonics for the sample entry.

0 => int smRate;        // Sample rate, as a percentage
1 => int smDelay;       // Delay, in ticks, before starting note.
2 => int smInstrument;  // The sample to play, encoded below.
3 => int smTrack;       // Track to assign
4 => int smRamp;        // Attack ramp; if negative, this is randomized.
5 => int smVolMax;      // Maximum volume for sample
6 => int smVolMin;      // Minimum volume for sample
7 => int smWobble;      // Used as a wobble volume
8 => int smPanStart;    // Starting pan position, 180 to -180 degrees
9 => int smPanStop;     // Ending   pan position, 180 to -180 degrees
10=> int smChain;       // Chain -- next note is in the same time slice when 1

// Mnemonics for label.

1 => int lbLabel;       // Numeric label

// Samples are represented as negative instruments, which are translated to
// entries in the sample table. 

[ "", "clap_01.wav",
  "click_01.wav",     "click_02.wav",     "click_03.wav",     "click_04.wav",     "click_05.wav",
  "cowbell_01.wav",
  "hihat_01.wav",     "hihat_02.wav",     "hihat_03.wav",     "hihat_04.wav",     
  "kick_01.wav",      "kick_02.wav",      "kick_03.wav",      "kick_04.wav",      "kick_05.wav",
  "snare_01.wav",     "snare_02.wav",     "snare_03.wav", 
  "stereo_fx_01.wav", "stereo_fx_02.wav", "stereo_fx_03.wav", "stereo_fx_04.wav", "stereo_fx_05.wav"
 ] @=> string wave_table[];
  
// Mnemonics for waves. This is manually built to match the wave table. This is used in the
// Instrument field for the main notes table. 

 -1 => int CLAP_01;
 -2 => int CLICK_01;      -3 => int CLICK_02;      -4 => int CLICK_03;      -5 => int CLICK_04;      -6 => int CLICK_05;
 -7 => int COWBELL_01;
 -8 => int HIHAT_01;      -9 => int HIHAT_02;     -10 => int HIHAT_03;     -11 => int HIHAT_04; 
-12 => int KICK_01;      -13 => int KICK_02;      -14 => int KICK_03;      -15 => int KICK_04;      -16 => int KICK_05;
-17 => int SNARE_01;     -18 => int SNARE_02;     -19 => int SNARE_03; 
-20 => int STEREO_FX_01; -21 => int STEREO_FX_02; -22 => int STEREO_FX_03; -23 => int STEREO_FX_04; -24 => int STEREO_FX_05;
  
// Each line specifies the note, an octave shift from our basis ocative, the "instrument"
// to use (determines how the sound is made), the logical sound channel to use (0-3), 
// the volume, a secondary "wobble" adjustment -- instrument specific, and start/stop 
// pan values, which run -180 to 180 degrees. The last field is a "chain" field... if 1,
// the following note is in the same time quantum (presumably on a different channel), 
// if 0, the following note will be the next note in time. A voice left blank will play
// nothing, but an explicit rest can also be in the table for any voice. 
 
 [[SKIP,100,-1, 0,0,0,0,0,0,0,0],  // Skip past the chunks used as loops
 
  [FWD,   0,      KICK_02, SND1,  0, 100,   NC,   0,   0,   0, 0 ],   // Kick loop 1, line 1
  [FWD,   0,   simpleRest, SND1,  0,  80,   NC,   0,   0,   0, 0 ],
  [FWD,   0,      KICK_03, SND1,  0,  80,   NC,   0,   0,   0, 0 ],
  [FWD,   0,   simpleRest, SND1,  0,  80,   NC,   0,   0,   0, 0 ],

  [FWD,   0,      KICK_04, SND1,  0, 100,   NC,   0,   0,   0, 0 ],   // Kick loop 2, line 5
  [FWD,   0,      KICK_04, SND1,  0,  80,   NC,   0,   0,   0, 0 ],
  [FWD,   0,   simpleRest, SND1,  0,  80,   NC,   0,   0,   0, 0 ],
  [FWD,   0,   simpleRest, SND1,  0,  80,   NC,   0,   0,   0, 0 ],
  
  [FWD,   0,      KICK_01, SND1,  0,  80,   NC,   0,   0,   0, 0 ],   // Kick loop 3, line 9
  [FWD,   0,   simpleRest, SND1,  0,  80,   NC,   0,   0,   0, 0 ],
  [FWD,   0,   simpleRest, SND1,  0,  80,   NC,   0,   0,   0, 0 ],
  [FWD,   0,      KICK_03, SND1,  0,  60,   NC,   0,   0,   0, 0 ],
  
  [FWD,   0,      KICK_05, SND1,  0, 100,   NC,   0,   0,   0, 0 ],   // Kick loop 4, line 13
  [FWD,   0,   simpleRest, SND1,  0,  80,   NC,   0,   0,   0, 0 ],
  [FWD,   0,      KICK_05, SND1,  0,  80,   NC,   0,   0,   0, 0 ],
  [FWD,   0,      KICK_03, SND1,  0,  60,   NC,   0,   0,   0, 0 ],
  
  [FWD,   0,     SNARE_02, SND3,  0,  20,   NC,   0, 180, 135, 0 ],   // Snare loop 1, line 17
  [FWD,   0,     SNARE_01, SND3,  0,  30,   NC,   0, 135,  90, 0 ], 
  [FWD,   0,     SNARE_02, SND3,  0,  40,   NC,   0,  90,  45, 0 ],   
  [FWD,   0,     SNARE_01, SND3,  0,  50,   NC,   0,  45,   0, 0 ],   
  
  [FWD,   0,     SNARE_01, SND3,  0,  50,   NC,   0,   0, -45, 0 ],   // Snare loop 1, line 21
  [FWD,   0,     SNARE_03, SND3,  0,  40,   NC,   0, -45, -90, 0 ], 
  [FWD,   0,     SNARE_01, SND3,  0,  30,   NC,   0, -90,-135, 0 ],   
  [FWD,   0,     SNARE_03, SND3,  0,  20,   NC,   0,-135,-180, 0 ],   
  
  [FWD,   0,     SNARE_02, SND3,  0,  20,   NC,   0,-180,-135, 0 ],   // Snare loop 1, line 25
  [FWD,   0,     SNARE_01, SND3,  0,  30,   NC,   0,-135, -90, 0 ], 
  [FWD,   0,     SNARE_02, SND3,  0,  40,   NC,   0, -90, -45, 0 ],   
  [FWD,   0,     SNARE_01, SND3,  0,  50,   NC,   0, -45,   0, 0 ],   
  
  [FWD,   0,     SNARE_01, SND3,  0,  50,   NC,   0,   0,  45, 0 ], // Snare loop 1, line 29
  [FWD,   0,     SNARE_03, SND3,  0,  40,   NC,   0,  45,  90, 0 ], 
  [FWD,   0,     SNARE_01, SND3,  0,  30,   NC,   0,  90, 135, 0 ],   
  [FWD,   0,     SNARE_03, SND3,  0,  20,   NC,   0, 135, 180, 0 ],   

  [FWD,   0,   simpleRest, SND4,  0,  50,   NC,   0,   0,  0,  0 ], // FX loop 1, line 33
  [REV,   0, STEREO_FX_01, SND4,  0,  50,   NC,   0,   0,  0,  0 ], // These play in reverse, for that weird drone at the start
  [REV,   0,   simpleRest, SND4,  0,  50,   NC,   0,   0,  0,  0 ], 
  [REV,   0, STEREO_FX_01, SND4,  0,  50,   NC,   0,   0,  0,  0 ],
  
  [ D4,   1,   slideyNote,  CH1,  0,  40,   60,  50,   0,   0, 0 ], // Melody loop for two measure, line 37
  [ D4,   1,   slideyNote,  CH1,  0,  60,   80,  50,   0,   0, 0 ], 
  [ E4,   1,   slideyNote,  CH1,  0,  80,  100,  50,   0,   0, 0 ], 
  [ E4,   1,   slideyNote,  CH1,  0, 100,   NC,  50,   0,   0, 0 ], 
    
  [ F4,   1,   slideyNote,  CH1,  0, 100,   NC,  50,   0,   0, 0 ], // Line 41
  [ F4,   1,   slideyNote,  CH1,  0, 100,   80,  50,   0,   0, 0 ], 
  [ F4,   1,   slideyNote,  CH1,  0,  80,   60,  50,   0,   0, 0 ], 
  [ F4,   1,   slideyNote,  CH1,  0,  60,   40,  50,   0,   0, 0 ], 
   
  [ G4,   1,   slideyNote,  CH1,  0,  40,   60,  50,   0,   0, 0 ], // Line 45
  [ G4,   1,   slideyNote,  CH1,  0,  60,   80,  50,   0,   0, 0 ], 
  [ C4,   1,   slideyNote,  CH1,  0,  80,  100,  50,   0,   0, 0 ], 
  [ C4,   1,   slideyNote,  CH1,  0, 100,   NC,  50,   0,   0, 0 ], 
   
  [ D4,   1,   slideyNote,  CH1,  0, 100,   NC,  50,   0,   0, 0 ],  // Line 49
  [ D4,   1,   slideyNote,  CH1,  0, 100,   80,  50,   0,   0, 0 ], 
  [ D4,   1,   slideyNote,  CH1,  0,  80,   60,  50,   0,   0, 0 ], 
  [ G4,   1,   slideyNote,  CH1,  0,  60,   40,  50,   0,   0, 0 ], 
 
  [ F4,   0,   tripleNote,  CH2,  0,  70,   40, -30,-100,-100, 0 ], // Harmony for two measure, square-wave modulation, line 53
  [ F4,   0,   tripleNote,  CH2,  0,  70,   40, -30,-100,-100, 0 ], 
  [ G4,   0,   tripleNote,  CH2,  0,  70,   40, -30,-100,-100, 0 ], 
  [ G4,   0,   tripleNote,  CH2,  0,  70,   40, -30,-100,-100, 0 ], 
    
  [ A4,   0,   tripleNote,  CH2,  0,  70,   40, -50,-100,-100, 0 ], // Line 57
  [ A4,   0,   tripleNote,  CH2,  0,  70,   40, -50,-100,-100, 0 ], 
  [ A4,   0,   tripleNote,  CH2,  0,  70,   40, -50,-100,-100, 0 ], 
  [ A4,   0,   tripleNote,  CH2,  0,  70,   40, -50,-100,-100, 0 ], 
   
  [ B4,   0,   tripleNote,  CH2,  0,  70,   40,  30,-100,-100, 0 ], // Line 61, sine-wave modulation
  [ B4,   0,   tripleNote,  CH2,  0,  70,   40,  30,-100,-100, 0 ], 
  [ E4,   0,   tripleNote,  CH2,  0,  70,   40,  30,-100,-100, 0 ], 
  [ E4,   0,   tripleNote,  CH2,  0,  70,   40,  30,-100,-100, 0 ], 
   
  [ F4,   0,   tripleNote,  CH2,  0,  70,   40,  50,-100,-100, 0 ], // Line 65
  [ F4,   0,   tripleNote,  CH2,  0,  70,   40,  50,-100,-100, 0 ], 
  [ F4,   0,   tripleNote,  CH2,  0,  70,   40,  50,-100,-100, 0 ], 
  [ B4,   0,   tripleNote,  CH2,  0,  70,   40,  50,-100,-100, 0 ], 
   
  [ F4,   0,   tripleNote,  CH2,-50,  70, -120,   0, 100,-100, 0 ], // Bridge loops,  line 69
  [ F4,   0,   tripleNote,  CH2,-50,  70, -120,   0,-100, 100, 0 ], // The -50 yields a randomized attack
  [ E4,   0,   tripleNote,  CH2,-50,  70, -120,   0, 100,-100, 0 ], 
  [ E4,   0,   tripleNote,  CH2,-50,  70, -120,   0,-100, 100, 0 ], 
    
  [ G4,   0,   tripleNote,  CH3,-50,  70, -120,   0, 100,-100, 0 ], // Line 73
  [ G4,   0,   tripleNote,  CH3,-50,  70, -120,   0,-100, 100, 0 ], 
  [ D4,   0,   tripleNote,  CH3,-50,  70, -120,   0, 100,-100, 0 ], 
  [ D4,   0,   tripleNote,  CH3,-50,  70, -120,   0,-100, 100, 0 ], 
   
  [ E4,   0,   tripleNote,  CH3,-50,  70, -120,   0, 100,-100, 0 ], // Line 77
  [ E4,   0,   tripleNote,  CH3,-50,  70, -120,   0,-100, 100, 0 ], 
  [ F4,   0,   tripleNote,  CH3,-50,  70, -120,   0, 100,-100, 0 ], 
  [ F4,   0,   tripleNote,  CH3,-50,  70, -120,   0,-100, 100, 0 ], 
   
  [ D4,   0,   tripleNote,  CH3,-50,  70, -120,   0, 100,-100, 0 ], // Line 81
  [ D4,   0,   tripleNote,  CH3,-50,  70, -120,   0,-100, 100, 0 ], 
  [ D4,   0,   tripleNote,  CH3,-50,  70, -120,   0, 100,-100, 0 ], 
  [ G4,   0,   tripleNote,  CH3,-50,  70, -120,   0,-100, 100, 0 ], 
    
  [ B4,  -1,   simpleNote,  CH4,  5, 120, -150,   0, 100, 100, 0 ], // Bass loops Line 85
  [ B4,  -1,   simpleNote,  CH4,  5, 120, -150,   0, 100, 100, 0 ], 
  [ E4,  -1,   simpleNote,  CH4,  5, 120, -150,   0, 100, 100, 0 ], 
  [ E4,  -1,   simpleNote,  CH4,  5, 120, -150,   0, 100, 100, 0 ], 
   
  [ F4,  -1,   simpleNote,  CH4,  5, 120, -150,   0, 100, 100, 0 ], // Line 89
  [ F4,  -1,   simpleNote,  CH4,  5, 120, -150,   0, 100, 100, 0 ], 
  [ F4,  -1,   simpleNote,  CH4,  5, 120, -150,   0, 100, 100, 0 ], 
  [ B4,  -1,   simpleNote,  CH4,  5, 120, -150,   0, 100, 100, 0 ], 

  [FWD,   0,      CLAP_01, SND5,  0, 100,   NC,   0, 180, 180, 0 ], // Actually did need more cowbell, line 93
  [FWD,  20,   COWBELL_01, SND6,  0,  50,   NC,   0, 180, 180, 0 ],  
  [FWD,   0,   simpleRest, SND5,  0, 100,   NC,   0, 180, 180, 0 ],   
  [FWD,  20,   COWBELL_01, SND6,  0,  50,   NC,   0, 180, 180, 0 ], 
  
  [ C4,   1,   slideyNote,  CH1,  0,  40,   60,  50,   0,   0, 0 ], // Line 97
  [ C4,   1,   slideyNote,  CH1,  0,  60,   80,  50,   0,   0, 0 ], 
  [ G4,   1,   slideyNote,  CH1,  0,  80,  100,  50,   0,   0, 0 ], 
  [ G4,   1,   slideyNote,  CH1,  0, 100,   NC,  50,   0,   0, 0 ], 
  
  [ E4,   0,   tripleNote,  CH2,  0,  70,   40,  30,-100,-100, 0 ], // Line 101
  [ E4,   0,   tripleNote,  CH2,  0,  70,   40,  30,-100,-100, 0 ], 
  [ B4,   0,   tripleNote,  CH2,  0,  70,   40,  30,-100,-100, 0 ], 
  [ B4,   0,   tripleNote,  CH2,  0,  70,   40,  30,-100,-100, 0 ], 

  [FWD,   0,   simpleRest, SND6,  0,  15,   NC,   0, -90, -90, 0 ], // HiHat Line 105
  [FWD,   0,   simpleRest, SND6,  0,  15,   NC,   0, -90, -90, 0 ], 
  [FWD,   0,     HIHAT_02, SND6,  0,  15,   NC,   0, -90, -90, 0 ],  
  [FWD,   0,   simpleRest, SND6,  0,  15,   NC,   0, -90, -90, 0 ], 
  
  [FWD,   0,     HIHAT_03, SND6,  0,  15,   NC,   0, -90, -90, 0 ], // Line 109
  [FWD,   0,   simpleRest, SND6,  0,  15,   NC,   0, -90, -90, 0 ],   
  [FWD,   0,     HIHAT_03, SND6,  0,  15,   NC,   0, -90, -90, 0 ],  
  [FWD,   0,   simpleRest, SND6,  0,  15,   NC,   0, -90, -90, 0 ],   
 
  [FWD,   0,     HIHAT_02, SND6,  0,  15,   NC,   0, -90, -90, 0 ], //  Line 113
  [FWD,   0,     HIHAT_04, SND6,  0,  15,   NC,   0, -90, -90, 0 ], 
  [FWD,   0,     HIHAT_02, SND6,  0,  15,   NC,   0, -90, -90, 0 ],  
  [FWD,   0,     HIHAT_04, SND6,  0,  15,   NC,   0, -90, -90, 0 ],  

 
  [LABL,  1,0,0,0,0,0,0,0,0,0 ],  // This is a label for the SKIP at the top 
 
  [LOOP,  0,  4,  1,  20,  1,  0,  0,   0,  0,   0 ], // Introduction
  [LOOP,  0,  4,  1,  30,  1, 93,  0,   0,  0,   0 ],
  [LOOP,  0,  4,  1,  40,  5, 93,  0,   0,  0,   0 ],
  [LOOP,  0,  4,  1,  50,  5,  0,  0,   0,  0,   0 ],
  [LOOP,  0,  4,  2,  60,  1, 33,  0,   0,  0,   0 ],
  [LOOP,  0,  2,  2,  80, 13,105,  0,   0,  0,   0 ],
  
  [LOOP,  0,  4,  2, 100,  1, 17, 37, 105,  0,   0 ], // Part 1
  [LOOP,  0,  4,  2, 100,  5, 21, 41, 105,  0,   0 ],
  [LOOP,  0,  4,  2, 100,  1, 25, 45, 105,  0,   0 ],
  [LOOP,  0,  4,  2, 100,  5, 29, 49, 109,  0,   0 ],
  
  [LOOP,  0,  4,  2, 100,  1, 17, 37, 105,  0,   0 ],
  [LOOP,  0,  4,  2, 100,  5, 21, 41, 85, 105,   0 ],
  [LOOP,  0,  4,  2, 100,  1, 25, 97, 105,  0,   0 ],
  [LOOP,  0,  4,  2, 100, 13, 29, 49, 89, 109,  33 ],
  
  [LOOP,  1,  4,  2, 100,  1, 17, 37, 53, 105,   0 ], // Part 2
  [LOOP,  1,  4,  2, 100,  9, 21, 41, 57,  85, 105 ],
  [LOOP,  1,  4,  2, 100, 13, 25, 45, 61, 105,   0 ],
  [LOOP,  1,  4,  2, 100,  5, 29, 49, 65,  89, 109 ],
  
  [LOOP,  0,  4,  2, 100,  1, 17, 37, 53, 105,   0 ],
  [LOOP,  0,  4,  2, 100,  5, 21, 41, 57,  85, 105 ],
  [LOOP,  0,  4,  2, 100,  1, 25, 97,101, 105,  33 ],
  [LOOP,  0,  4,  2, 100, 13, 29, 49, 65,  89, 109 ],
  
  [LOOP,  0,  4,  1, 100,  1, 69,  0,105,   0,   0 ], // Bridge
  [LOOP,  0,  4,  1, 100,  1, 69, 85,109,   0,   0 ],
  [LOOP,  0,  4,  1, 100,  1, 73, 89,113,   0,   0 ],
  [LOOP,  0,  4,  1, 100,  1, 73, 85,113,   0,   0 ],
  [LOOP,  0,  4,  1, 100,  1, 75, 85,109,   0,   0 ],
  [LOOP,  0,  4,  1, 100,  1, 75, 89,113,   0,   0 ],

  [LOOP,  0,  4,  2, 100,  1, 17, 37, 85, 105,   0 ], // Part 3
  [LOOP,  0,  4,  2, 100,  5, 21, 41, 89, 105,   0 ],
  [LOOP,  0,  4,  2, 100, 13, 25, 45, 85, 105,   0 ],
  [LOOP,  0,  4,  2, 100,  5, 29, 49, 89, 109,  33 ],
  
  [LOOP,  0,  4,  2, 100,  1, 17, 53, 85, 105,   0 ],
  [LOOP,  0,  4,  2, 100,  5, 21, 57, 89, 105,   0 ],
  [LOOP,  0,  4,  2, 100,  1, 25, 61, 85, 105,   0 ],
  [LOOP,  0,  2,  1, 100, 13, 29, 65, 89, 109,   0 ],
  
  [LOOP,  0,  5,  1, 100,  1, 85,  0,  0,   0,   0 ] // Coda
 ] @=> int note_table[][];


// Duration of quantum and a tick, which set the timing for the system. I want to play and change things 
// seemingly at the same time. Each note in the note table is broken up into individual "ticks", which is
// the smallest unit of time in the system. The time each tick plays and the number of ticks per note
// yield the duration of each note in the table, which is current a 1/8 note playing for 1/8th second. 
// The reason for this is to allow things to change during the playing of a note, without having the
// ability to run multiple threads (shreds). 

100 => int ticks;
(0.125/ticks)::second => dur quantum;
     
// Basic constants for ramping volume up or down. 
10  => int dampen;
5   => int ramp;

// This is the maximum volume to ever use. This is scaled down when there are more channels,
// and equal to the MIDI-like max of 100 (MIDI goes to 127, but I'm just scaling it 0-100). 
// Eventually, this out to be scaled by the number of voices in use. 
0.3 => float max_volume; 

// This is the minimum volume to ever use. Used for "flooring" a volume calculation. 
0 => float ZERO_VOL;

// Working variables
int   note_count;                       // Current ticks in a note
int   note_max;                         // Total ticks in a note
int   note_channel;                     // Channel of working note
int   note_mod_counter;                 // Counter for note modulation
int   note_mod_ramp;                    // Direction for note modulation, as applicable

int   note_voice[voice_max];            // The primary voice for the current note

int   note_instrument[track_max];       // The instrument number for the current note.
int   note_used[track_max];             // Voices in use for any cycle
int   note_ramp[track_max];             // Ramp-up count, in ticks
int   note_mod[track_max];              // Wobble from the table
int   note_delay[track_max];            // Delay of sound playback or slide-in period

float note_freq[track_max];             // Actual note frequency
float node_last_freq[track_max];        // Frequency of last note
float note_freq_adj[track_max];         // Change in frequency for special functions
float note_vol[track_max];              // Note's volume
float note_vol_adj[track_max];          // Change in,volume for special functions
float note_ramp_adj[track_max];         // Ramp-up value
float note_pan[track_max];              // Note's pan
float note_pan_adj[track_max];          // Change in pan per tick
float note_mod_amp[track_max];          // Amplitude of modulation
float note_mod_per[track_max];          // Period of modulation

float note_rate[sound_max];             // Rate of sound playback

me.dir() + "/audio/" => string smpdir;  // Sample directory

// Looping variables
0 => int loop_root;                     // Line number of current loop
0 => int loop_new_pass;                 // Start of a loop pass
0 => int loop_new_line;                 // Start of a loop line
0 => int loop_pass_count;               // Cycles in a loop
0 => int loop_sets;                     // Number of lines to merge
0 => int loop_line_max;                 // Total of lines in a loop
0 => int loop_line_count;               // Count of lines in a loop
0 => int loop_octave_adj;               // Integer octave adjustment
1.0 => float loop_vol_adj;              // Floating point volume adjustment

// Main control variables
0 => int note;                          // Position in the note table
0 => int more_notes;                    // Note chaining indicator
0 => int channel;                       // Synth channel, 1-4
0 => int voice;                         // Voice, same as track, 0-19
0 => int sound;                         // Sound channel, 12-19
0 => float temp_volume;                 // Intermediate volume calculation
0 => int king_of_all_ticks;             // Free running tick counter
0 => int frame_start_tick;              // Start of frame, in elapsed ticks

// This loop processes each note in turn. The process is essentially converting the notes table into a
// voice table for the current time slide, which is set by "ticks" and "quantum" variables, up above.
// The first part of this processes the current note and any chained notes, allocating them to the 
// various voice variables above. This looks more complicated than it should be, because we aren't 
// allows to use structures/classes yet. Once that's allowed, there would be a single array of structures
// that include every per-voice parameter (freq, pan, etc). 

while (note_table.cap() > note) {    
    // Set the number of ticks for this note, and other setups for the build and play loops
    ticks => note_count => note_max;
	king_of_all_ticks => frame_start_tick;
    1 => more_notes;

    // Clear previous settings, to avoid clicks or holdovers. Note that volume isn't adjusted; that's actually
    // dampened in the slot after a voice has been disabled, to prevent any clicking. 
    for (0 => int voice; voices.cap() > voice; ++voice) {
        0 => note_pan_adj[voice];
        0 => note_freq_adj[voice];
        0 => note_vol_adj[voice];
        0 => note_used[voice];
    }

    // BUILD LOOP. This Initialize all of the per-voice information. Keep in mind that the notes table thinks
    // in channels, while most of the synthesis engine below thinks in tracks (samples or voices). This loop
    // sets up at least one voice, sample, or rest, and any chained notes or samples. The presumption is that each
    // track/voice/channel in a chained set uses a different channel, but there's no checking done. 
    while (more_notes) {
        // Special magick

        // LABL is for labels, targets of SKIP. A label is just ignored when passed in-line
        if (LABL == note_table[note][ntNote]) {
            ++note;
        }

        // The LOOP function. A loop references a set of note table lines to repeat, one or more
        // times. Loops do not currently nest. Once a loop exits, the table continues at the next
        // line after the loop statement. 
        if (0 != loop_root) {                                  // Are we in the loop?
            if (loop_new_pass) {                               // Starting again at the top of the loop
                0 => loop_line_count;
                0 => loop_new_pass;
                1 => loop_new_line;
            }
            if (loop_new_line) {
                loop_sets + 1 => more_notes;    // The +1 is to get control back here to end the loop
                0 => loop_new_line;
            }
 
            // There's one extra pass 
            if (1 < more_notes) {
                note_table[loop_root][lpLine1 + loop_sets - more_notes + 1] + loop_line_count => note;
            } else {                                          // End of this logical line
                1 => loop_new_line;
                if (++loop_line_count >= loop_line_max) {     // End of this pass
                    1 => loop_new_pass;
                    if (0 >= --loop_pass_count) {             // End of whole loop
                        0 => loop_octave_adj;
                        1.0 => loop_vol_adj;
                        loop_root+1 => note;                       
                        0 => loop_root;
                    }
                }
                break;
            }
        } else if (LOOP == note_table[note][ntNote]) {  // New loop? 
            note => loop_root;
            1 + (note_table[note][lpLine2] != 0) + (note_table[note][lpLine3] != 0) + (note_table[note][lpLine4] != 0) 
              + (note_table[note][lpLine5] != 0) + (note_table[note][lpLine6] != 0) => loop_sets;
            loop_sets + 1 => more_notes;
            1 => loop_new_pass;
            1 => loop_new_line;
            
            note_table[note][lpLength] => loop_line_max;                   // Number of lines in the loop
            note_table[note][lpOctave] => loop_octave_adj;                 // Integer octave adjustment for loop
            note_table[note][lpPass]  => loop_pass_count;                  // Loop passes
            note_table[note][lpVAdj]/100.00 => loop_vol_adj;               // Volume adjustment for loop
            
            0 => loop_line_count;                                          // Line increment of the loop
            continue;                                                      // Go to end of loop
        }  
              
        // The CHAIN function is pretty simple...run this loop one more time if there's a chained note
        if (LOOP != note_table[note][ntNote] && note_table[note][ntChain]) {
            1 => more_notes;
        } 

        // The SKIP function. The "chance" field, if not zero, is the percent chance of the skip being
        // taken. There are four possible skips per line, each with its own chance, 0-100%. 
        if (SKIP == note_table[note][ntNote]) {
            note + 1 => int next_note;
            for (0 => int chance; 8 > chance; 2 +=> chance) {
                if (note_table[note][skChance1 + chance] == 0) break;       // No more skips
            
                if (Math.random2(1,100) <= note_table[note][skChance1 + chance]) {
                    note_table[note][skLine1 + chance] => int jump;
                    // Skip to a line number
                    if (jump >= 0 && jump <= note_table.cap() -1) {
                        jump => next_note;
                        break;
                    } else if (jump < 0) {
                        // Skip to a label
                        for (0 => int i; note_table.cap() > i; ++i) {
                            if (LABL == note_table[i][ntNote] && note_table[i][lbLabel] == -1 * jump) {
                                i + 1 => next_note;
                                break;                  // Break out of for loop
                            }
                        }
                        break;                      // Break out of for loop
                    }
                }
            } 
            next_note => note;
        }

        // Get the working channel number;
        note_table[note][ntChannel] => channel;
        
        // Is this a sample or synth channel? 
        if (channel >= voice_max) {
            channel - voice_max => sound;
            channel => voice;
            -1 => channel;
            note_table[note][smTrack] => note_rate[sound];
        } else {
            -1 => sound;
            channel*3+1 => voice;
            note_table[note][ntChannel]*3+1  => note_voice[voice];
            // Set the note, including octave adjustment
            Std.mtof(note_table[note][ntNote]) * Math.pow(2.0,note_table[note][ntOctave]+loop_octave_adj) => note_freq[voice];
        }
        
        // This allows a rest to be programmed in the notes table. This allows notes to be shut off without 
        // changing any parameters, or note periods where nothing plays. simpleRest can also be used to shut
        // off a sample, so it's checked here first, to prevent errors further down. 
        if (simpleRest == note_table[note][ntInstrument]) {
            --more_notes; 
            ++note; 
            0 => note_used[voice];
            continue;               // Go to end of loop
        }

        // This is used.
        1 => note_used[voice];
                
        // Get the wobble
        note_table[note][ntWobble] => note_mod[voice];
        
        // Set the ramp-up variables
        note_table[note][ntRamp] => note_ramp[voice];
        
        // Set the volume. This may include a volume ramp-up (a simple attack setting), which will
        // build to the final volume based on the ramp count. 
        note_table[note][ntVolMax] * max_volume/100.00 * loop_vol_adj => temp_volume;
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

        // Set the instrument.
        note_table[note][ntInstrument]   => note_instrument[voice];
        
        // Modulation value... used for things like volume modulation, eg, vibrato. This specifies a
        // period, in ticks.
        if (0 != note_mod[voice] && slideyNote != note_instrument[voice]) {
            2.0 * 3.141597/note_table[note][ntWobble]  => note_mod_per[voice];
            (note_table[note][ntVolMax]-note_table[note][ntVolMin])*max_volume/200.0 => note_mod_amp[voice];
        } else {
            0.0 => note_mod_amp[voice];
            0.0 => note_mod_per[voice];
        }
        
        // Set the pan. If start and stop pan aren't the same, the pan will sweep duing the note
        note_table[note][ntPanStart]/180.0 => note_pan[voice];
        (note_table[note][ntPanStart] - note_table[note][ntPanStop])/(180.0 * note_max) => note_pan_adj[voice];

        // Instrument-specific setup. There are different sounds.
        


	    // This is for a sampled sound. The instrument number is actually the negative index into the table of
	    // samples, while sound is the index into the sound array for that.
        if (-1 == channel) {
			// Set up the wave
            smpdir + wave_table[-1* note_instrument[voice]] => sounds[sound].read;
   
			// Set the volume metrics
            if (NC != note_table[note][smVolMin] && 0 == note_mod[voice]) {
                (temp_volume - (note_table[note][smVolMin] * max_volume/100.00) * loop_vol_adj)/note_max => note_vol_adj[voice];
            } else {
                0 => note_vol_adj[voice];
            }

		    // Note speed is the same as the note field, negative indicated reversed sample. 
			note_table[note][smRate] / 100.0 => note_rate[sound] => sounds[sound].rate;

		
		    // Ensure the sound is off.
		    if (0 > note_rate[sound]) {
				0 => sounds[sound].pos;
			} else {
				sounds[sound].samples() => sounds[sound].pos;
			}
 
		    // Get the offset/delay for starting the sample
		    note_table[note][smDelay] => note_delay[sound];
		}
        
        // The simpleNote plays a one-oscillator note. It can also do automatic volume fading, fading from the
        // volume setting down to the "wobble" value. This is always a linear fade. 
        if (simpleNote == note_instrument[voice]) {
            if (NC != note_table[note][ntVolMin] && 0 == note_mod[voice]) {
                (temp_volume - (note_table[note][ntVolMin] * max_volume/100.00) * loop_vol_adj)/note_max => note_vol_adj[voice];
            } else {
                0 => note_vol_adj[voice];
            }
        } 
        
        // The slideyNote slips from one single-tone note to another. In this case, the wobble value is actually the
        // slide period, measured in ticks. 
        if (slideyNote == note_instrument[voice]) {
            note_freq[voice] => float curr_note;
            
            // Slide-in period
            note_table[note][ntWobble] => note_delay[voice];
            
            // Swap notes
            if (voices[note_voice[voice]].gain() > 0.0 && 0.0 != voices[note_voice[voice]].freq()) {  
                voices[note_voice[voice]].freq() => note_freq[voice];
                (curr_note - note_freq[voice]) / note_delay[voice] => note_freq_adj[voice];
            }
            0 => note_vol_adj[voice];
            simpleNote => note_instrument[voice];
        }

        // The simpleTrem switches the voice's frequency between the note value and a change based on the wobble
        // value as a percentage of the difference between this note and the next one. Still some bugs in this
        // one. The randomTrem does the same, only with a random shift. 
        if (simpleTrem == note_instrument[voice] || randomTrem == note_instrument[voice]) {
            (Std.mtof(note_table[note][ntNote]+1) * Math.pow(2.0,note_table[note][ntOctave])+loop_octave_adj - note_freq[voice])*(note_table[note][ntVolMin]/(200.0)) => note_freq_adj[voice];  
            note_freq_adj[voice] +=> note_freq[voice]; 
        }
 
        // This instrument type basically builds three simpleNote instruments. Most parameters will be the same, but the
        // volume applies to all three channels mixed (so these don't sound louder than single-voice instruments) and the frequencies
        // set is the note and the first two harmonics. 
        if (tripleNote == note_instrument[voice] || tripleDamp == note_instrument[voice]) {
            if (NC != note_table[note][ntVolMin] && tripleDamp == note_instrument[voice]) {
               (temp_volume - (note_table[note][ntVolMin] * max_volume/100.00 * loop_vol_adj))/note_max => note_vol_adj[voice] => note_vol_adj[voice+1] => note_vol_adj[voice+2];
            } else {
                0 => note_vol_adj[voice] => note_vol_adj[voice+1] => note_vol_adj[voice+2]; 
            }
            note_voice[voice]+1 => note_voice[voice+1];
            note_voice[voice]+2 => note_voice[voice+2];
            1 => note_used[voice+1] => note_used[voice+2];         
           
            if (tripleDamp == note_instrument[voice]) {
                note_table[note][ntVolMin]/100.0 => float scale; 
                
                note_vol[voice]/(1 + scale + scale * scale) => note_vol[voice];
                note_vol[voice]   * scale => note_vol[voice+1];
                note_vol[voice+1] * scale => note_vol[voice+2];
                note_mod_amp[voice] / (1 + scale + scale * scale) => note_mod_amp[voice] => note_mod_amp[voice+1] => note_mod_amp[voice+2];
            } else {
                note_vol[voice]/2 => note_vol[voice]  => note_vol[voice+1] => note_vol[voice+2];
                note_mod_amp[voice]/2 => note_mod_amp[voice] => note_mod_amp[voice+1] => note_mod_amp[voice+2];
            }
            note_ramp[voice] => note_ramp[voice+1] => note_ramp[voice+2];
            note_ramp_adj[voice]/2 => note_ramp_adj[voice] => note_ramp_adj[voice+1] => note_ramp_adj[voice+2];
            

            note_mod_per[voice] => note_mod_per[voice+1] => note_mod_per[voice+2];
            
            note_pan[voice] => note_pan[voice+1] => note_pan[voice+2];
            note_pan_adj[voice] => note_pan_adj[voice+1] => note_pan_adj[voice+2];
            
            note_freq[voice] * 2 => note_freq[voice+1];
            note_freq[voice] * 4 => note_freq[voice+2];
            
            // This is now treated as three independent simpleNotes
            simpleNote => note_instrument[voice] => note_instrument[voice+1] => note_instrument[voice+2];
        }  
   
        // This does a similar 3-voice thing, only with Tremolo. The simpleTrem bug currently messes this up, too. 
        if (tripleTrem == note_instrument[voice]) {
            (Std.mtof(note_table[note][ntNote]+1) * Math.pow(2.0,note_table[note][ntOctave]+loop_octave_adj) - note_freq[voice])*(note_table[note][ntVolMin]/(200.0)) => note_freq_adj[voice];  

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
        if (doubleBeat == note_instrument[voice]) {
            note_voice[voice]+1 => note_voice[voice+1];
            1 => note_used[voice+1];
            
            note_vol[voice] / 2 => note_vol[voice]  => note_vol[voice+1];
            note_ramp[voice] => note_ramp[voice+1];
            note_ramp_adj[voice] / 2 => note_ramp_adj[voice] => note_ramp_adj[voice+1];
            
            note_pan[voice] => note_pan[voice+1];
            note_pan_adj[voice] => note_pan_adj[voice+1];
            
            // Wobble is used to set the beat frequency here, not an amplitude envelope
            note_freq[voice] +  note_mod[voice] => note_freq[voice+1];
            0.0 => note_mod_amp[voice] => note_mod_amp[voice+1];
            0.0 => note_mod_per[voice] => note_mod_per[voice+1];
                       
            // This is now treated as two independent simpleNotes or simpleVibes
            simpleNote => note_instrument[voice] => note_instrument[voice+1];
        }  
       
        // Notes in the same time slice.. it's one, unless we have chanined note or a loop merge 
        --more_notes; 
        ++note;
    }
    
    // DAMPEN HELD NOTES. Nicely close off unused voices. Any voice that was playing in the last segment but not the current
    // gets a ramp-down on volume. This isn't applied to samples, since they're allow to play as long as they'll play. 
    for (voice_min => voice; voice_max > voice; ++voice) {
        if (!note_used[voice]) {
            voices[note_voice[voice]].gain() / dampen => note_vol_adj[voice];
            voices[note_voice[voice]].gain() - note_vol_adj[voice] => note_vol[voice];
            switchOFF => note_instrument[voice];
        }
    }            
    
    // PLAY LOOP. This loops over each tick and each voice, adjusting any parameters that
    // change during a note. Each pass through the outer loop runs in one "quantum".   
    while (note_count--) {
            
		// SYNTH LOOP. This plays every voice in use, and 
        for (voice_min => voice; voice_max > voice; ++voice) {			
            // Set the frequency, with random wobble if requested.         
            note_freq[voice] => voices[note_voice[voice]].freq;        
        
            // Apply current pan setting, update for next pass
            note_pan[voice] => pans[note_voice[voice]].pan;
            note_pan_adj[voice] -=> note_pan[voice];

            // Standard output gain control. This only sets volume on active notes, but the rest of the loop still works with
			// volume adjustments, to support the auto-fade feature. This is a sine modulation when the mod value is positive,
            // a step/square modulation when the mod value is negative
            if (note_used[voice]) {
                if (0 > note_mod[voice]) {
                    Math.max(ZERO_VOL,note_vol[voice]-note_mod_amp[voice]*(((king_of_all_ticks/(-1 * note_mod[voice])) % 2))) => voices[note_voice[voice]].gain;                  
                } else {
                    Math.max(ZERO_VOL,note_vol[voice]-note_mod_amp[voice]*Math.sin(note_mod_per[voice]*king_of_all_ticks)) => voices[note_voice[voice]].gain;
                }
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
                // Process the slideyNote
                if (note_delay[voice]) {
                    --note_delay[voice];
                    note_freq_adj[voice] +=> note_freq[voice];
                }
                
                if (note_vol[voice] <= ZERO_VOL) {
                   0 => voices[note_voice[voice]].freq;
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

	    // SAMPLE LOOP. This loop plays the samples. All samples are pretty much the same, with some of the same
        // wave envelope stuff available on the "synth" notes. The rate setting in the notes array is used to
        // position the note for playing, based on sign of the rate. Samples can last out past a single note
        // period, so they're not actually cleared out when done. However, immediately after playing, the sample
        // is tagged as not used, so that it won't be retriggered in 0.125 sec, the next time this part of the 
        // player is entered. 
        for (sound_min => sound; sound_max > sound; ++sound) {
            sound + sound_offset => voice;
            
            // Apply current pan setting, update for next pass
            note_pan[voice] => pans[voice].pan;
            note_pan_adj[voice] -=> note_pan[voice];

            // Set the volume
            Math.max(ZERO_VOL,note_vol[voice]-note_mod_amp[voice]*Math.sin(note_mod_per[voice]*king_of_all_ticks)) => sounds[sound].gain;
            
            // Adjust the volume as set 
            if (0 == note_ramp[voice]) {
                note_vol_adj[voice] -=> note_vol[voice];
            } else {
                note_ramp_adj[voice] +=> note_vol[voice];
            }

		    if (note_used[voice] && king_of_all_ticks - frame_start_tick == note_delay[sound]) {               
                // Enable the sound via pos settinsg
				if (0 > note_rate[sound]) {
					sounds[sound].samples() => sounds[sound].pos;
			    } else {
					0 => sounds[sound].pos;
				}
                // Prevent a re-trigger
                0 => note_used[voice];
            }
        }
        
        // Play one quantum of music.
        ++king_of_all_ticks;
        quantum => now;
    }
}

<<< "end-> ", (now - program_start) / second, "sec" >>>;
