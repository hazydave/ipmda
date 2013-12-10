// File:    bass.ck
// Class:   Introduction to Programming for Musicians and Digital Artists
// Program: Assignment 6: Cocktail I.V.
// Date:    2013-28-21
// Note:    PLEASE KEEP IF YOU FIND IT USEFUL

// ===========================================================================
// COMMON CODE
// Since we can't coordinate actively between modules this week, this code is 
// used to synchronize things. 

// Level settings
0.5              => float master_level;  // Overall adjustment of per-module output level,                            
1 * master_level => float module_level;     // Master level for this specific module. 

// High level sound network

Pan2 module_bus => dac;                 // The sub-bus for this module
0.4 => module_bus.pan;                  // Where does the bass live in the sound field?
module_level => module_bus.gain;        // Bass isn't in intro or coda, so it starts out loud

// Time this starts.                            
now => time time_start;
30::second => dur time_play;

// Duration of quantum and a tick, which set the timing for the system. 

628        => int   ticks;
0.625      => float time_quarter_note_sec;
4          => int   time_qnote_per_measure; 
4 * ticks  => int   time_ticks_per_qnote;
4          => int   time_slices_per_qnote;

time_quarter_note_sec::second => dur time_quarter_note;
time_quarter_note/2           => dur time_eighth_note;
time_eighth_note/2            => dur time_sixteenth_note;
time_sixteenth_note           => dur time_slice;
time_slice/ticks              => dur time_quantum; 

// Notes in the Bb Aeolian mode

 46 => int  Bb;  48 => int   C;  49 => int  Db; 51 => int Eb;
 53 => int   F;  54 => int  Gb;  56 => int  Ab;  
999 => int RST; 998 => int STP; 997 => int RND;
[ 46, 48, 49, 51, 53, 54, 56, 58 ] @=> int note_table[];

// ===================================================================================================
// SONG NAVIGATION CONSTANTS
// The song is defined to be 30 seconds with 0.625 second per quarter note, so 48 quarter notes, 
// 11 measures in 4/4 time. So the structure is:
// Intro :  4 quarter notes
// Part 1: 16 quarter notes
// Solo  :  8 quarter notes
// Part 2: 16 quarter notes
// Coda  :  2 quarter notes

time_quarter_note  * 4 => dur time_intro;
time_quarter_note * 16 => dur time_part1;
time_quarter_note *  8 => dur time_solo;
time_quarter_note * 16 => dur time_part2;
time_quarter_note *  2 => dur time_coda;

time_slices_per_qnote * 4                     => int slices_at_part1;
time_slices_per_qnote * 16 + slices_at_part1  => int slices_at_solo;
time_slices_per_qnote * 4  + slices_at_solo   => int slices_at_part2;
time_slices_per_qnote * 16 + slices_at_part2  => int slices_at_coda;

// ===========================================================================
// INSTRUMENT CODE
// BASS SYNTH MODEL
// Not sure what kind of bass instrument this is supposed to be. I wanted something
// kind of mellow, to fill in the low-end of the piece. I screwed around with trying to use hand-rolled
// FM synthesis for a more bass-guitar-like bass, but didn't really get there. I had the idea up to a 
// point, but couldn't get the filtering right. 

// Musically, the interesting thing about this bass is that I'm controlling the note period, so I can
// play shot notes even at a long note interval... part of what's cool about the bass sound is that
// staccto potential, which I didn't have in other instrument models. 

// Initializations for simple bass sound
Mandolin bass;                     // Model for bass
    0.7  => bass.gain;
    0.05 => bass.bodySize;
    0.05 => bass.stringDetune;
    0.9  => bass.stringDamping;
    0.8  => bass.pluckPos;
    
    
SinOsc bass_osc[3];    
    0.9  => bass_osc[0].gain;
    0.7  => bass_osc[1].gain;
    0.5  => bass_osc[2].gain;
    
ADSR bass_adsr;
    bass_adsr.set(25::ms, 250::ms, 0.2, 10::ms);
    
Pan2 pan;                         // Pan/volume for bass
    1.0 => pan.gain;
NRev rvb;                         // Reverb
    0.0 => rvb.mix;
    1.0 => rvb.gain;
LPF flt;                          // Low-pass filter for bass
    1.0  => flt.gain;  
    2500 => flt.freq;
    
Chorus chrs;
    0.8 => chrs.mix;
    
0 => int bass_poison_pill;        // De-shredify the current bass

// Bass signal chain
bass => rvb => flt => pan => module_bus;
bass_adsr => chrs => rvb;
for (0 => int i; bass_osc.cap() < i; ++i) bass_osc[i] => bass_adsr;

// Parameters to swing and basic players, to offer some control over the samples played
0 => int prmGain;       // Output gain setting
1 => int prmPan;        // Pan setting for this instrument
2 => int prmRvbMix;     // Reverb mix setting
3 => int prmRvbGain;    // Reverb gain setting
4 => int prmCadance;    // Length of notes in the note table
5 => int prmCmpRatio;   // Ratio of compression
6 => int prmCmpThrsh;   // Threshold of compression
7 => int prmTimeOff;    // Time slop for additional swingyness
8 => int prmLength;     // Length of the param array

// ---------------------------------------------------------------------------
// BASS GUITAR
// This is the bass guitar player, which allows swing timing. It's up to
// the design of the note array to get the timing correct. The global variable
// "bass_poison_pill" set to 1 will cause this player to quit. 

fun void play_bass(int pitch[], int mod[], int tim[], int len[], int vol[], float param[]) {
    // Note slop offset;
    dur offset;
    dur note_on;
    dur note_off;
    dur note_play;

    // Make sure we'll play
    0 => bass_poison_pill;
    
    // Basic time setting
    time_slice * param[prmCadance]  => dur full_time;

    // Index for the various arrays. 
    0 => int index;
    
    // Parameter changes
    param[prmRvbGain] => rvb.gain;
    param[prmRvbMix]  => rvb.mix;
          
    while (!bass_poison_pill) {
        // Time for this pass, total
        full_time * tim[index] / 100.0 => note_play;
 
        // Is this a rest?
        if (RST == pitch[index] || 0 == pitch[index]) {
            note_play => now; 
            0 => bass.gain;
            0 => bass_adsr.gain;
            0 => bass.noteOff;
            0 => bass_adsr.keyOff;
        } else {
           // Figure the play and rest times

           note_play * len[index] / 100.0 => note_on;
           note_play - note_on => note_off;
       
           // Random note offset
           Math.random2f(0,param[prmTimeOff])::ms => offset;
           offset => now;
        
           // We count real time here, so there's no need to check for note 
           // edges. 
           if (pitch[index]) {  
               Math.mtof(pitch[index] + 12 * mod[index]) => bass.freq => bass_osc[0].freq;
               bass_osc[0].freq() * 2 => bass_osc[1].freq;
               bass_osc[1].freq() * 2 => bass_osc[2].freq;
               param[prmGain] * vol[index]/100.0 => bass.gain;
               bass.gain() => bass_adsr.gain;
               1 => bass.noteOn;
               1 => bass_adsr.keyOn;
           }
           note_on - offset => now;
           1 => bass.noteOff;
           1 => bass_adsr.keyOff;
           note_off => now;
       }
        
       (index + 1) % pitch.cap() => index;
    }
}

// 46 => int  Bb;  48 => int   C;  49 => int  Db; 51 => int Eb;
// 53 => int   F;  54 => int  Gb;  56 => int  Ab; 

// This is part 1
[ Bb, RST, Db,      RST,     F,     Ab,   F,  Gb,  Eb,        Bb,   C,  Eb,  Gb  ] @=> int bass_pitch_pt1[];
[ -1,  -1,  -1,       0,    -1,     -1,  -1,  -1,  -1,        -1,  -1,  -1,  -1  ] @=> int bass_mods_pt1[];
[200, 125,  75,     400,   400,    100, 100, 100, 100,       400, 400, 400, 400  ] @=> int bass_notes_pt1[];
[ 50,   0, 100,       0,   100,     70,  70,  70,  70,        40,  40,  40,  70  ] @=> int bass_len_pt1[];
[ 80,   0, 100,       0,   100,     50,  35,  60,  35,       100,  50, 100,  50  ] @=> int bass_vol_pt1[]; 

[1.0, -0.4, 0.05, 0.6, 1.0, 0.0, 0.0, 25.0] @=> float bass_controls_pt1[];

// This is part 2
[RST,  Bb,      C, RST,     Eb, RST,    Ab,  RST,     Bb, RST,      Db,   F, RST,     Ab,  Db,    C  ] @=> int bass_pitch_pt2[];
[ -1,  -1,     -1,   0,      0,   0,    -1,   0,      -1,   0,      -1,  -1,   0,     -1,  -1,   -1  ] @=> int bass_mods_pt2[];
[200, 200,    200, 200,    200, 200,   200, 200,     200, 200,     200, 100, 100,    200, 200,  400  ] @=> int bass_notes_pt2[];
[ 80,  80,     80,   0,     80,   0,    50,   0,      80,   0,      50,  80,   0,     30,  80,   60  ] @=> int bass_len_pt2[];
[ 0,   70,    100,   0,     80,   0,   100,   0,      50,   0,     100,  50,   0,     80,  50,   90  ] @=> int bass_vol_pt2[];

[1.0, -0.4, 0.05, 0.6, 1.0, 0.0, 0.0, 25.0] @=> float bass_controls_pt2[];

// Play the first part
spork ~ play_bass(bass_pitch_pt1, bass_mods_pt1, bass_notes_pt1, bass_len_pt1, bass_vol_pt1, bass_controls_pt1);
time_part1 => now;
1 => bass_poison_pill;

// No bass solo
time_solo => now;
    
// Play the second part
spork ~ play_bass(bass_pitch_pt2, bass_mods_pt2, bass_notes_pt2, bass_len_pt2, bass_vol_pt2, bass_controls_pt2);
time_part2 => now;
0 => bass_poison_pill;

// Done (no bass in coda)
