// File:    clarinet.ck
// Class:   Introduction to Programming for Musicians and Digital Artists
// Program: Assignment 6: Cocktail I.V.
// Date:    2013-28-21
// Note:    PLEASE KEEP IF YOU FIND IT USEFUL

// ===========================================================================
// COMMON CODE
// Since we can't coordinate actively between modules this week, this code is 
// used to synchronize things. 

// High level sound network
Pan2 module_bus => Mixdac.in;   // The sub-bus for this module
2.5  => module_bus.gain;        // Gain for this module
-0.4 => module_bus.pan;         // Pan for this module

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
// SONG NAVIGATION FUNCTIONS
// The song is defined to be 30 seconds with 0.625 second per quarter note, so 48 quarter notes, 
// 11 measures in 4/4 time. So the structure is:
// Intro :  4 quarter notes
// Part 1: 16 quarter notes
// Solo  :  8 quarter notes
// Part 2: 16 quarter notes
// Coda  :  2 quarter notes

// This function returns the current time, in slices
fun int now_slice() {
    return Math.trunc((now - time_start) / time_slice) $ int;
}

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
// HORN SYNTH MODEL
// Not sure what kind of sax-like instrument this is supposed to be. I wanted a jazzesque horn-ish thing
// to play the lead melody,

Clarinet horn;
    1.0   => horn.clear;
    0.700 => horn.reed;
    0.360 => horn.noiseGain;
    9.000 => horn.vibratoFreq;
    0.20  => horn.vibratoGain;
    0.900 => horn.pressure; 
    1     => horn.noteOff; 
    0.5   => horn.gain; 
    
Pan2 pan;                     // Instrument-chain pan
    -0.4 => pan.pan;
    1.5 => pan.gain;
    
NRev rvb;                         // Reverb
    0.4 => rvb.mix;
    1.0 => rvb.gain;
    
// Additonal sound for thicker horn
SqrOsc h2;
    0.5 => h2.gain;
    
LPF flt;
    3000 => flt.freq;
    0.2 => flt.gain;
    
ADSR env;
    env.set(50::ms, 500::ms, 0.5, 10::ms);
    1 => env.keyOff;

// De-shredify the current bass
0 => int horn_poison_pill; 

// Horn signal chain
horn => rvb => pan => module_bus; 
//h2 => flt => env => rvb;


// Parameters to swing and basic players, to offer some control over the samples played
0 => int prmGain;       // Output gain setting
1 => int prmPan;        // Pan setting for this instrument
2 => int prmRvbMix;     // Reverb mix setting
3 => int prmRvbGain;    // Reverb gain setting
4 => int prmCadance;    // Length of notes in the note table
5 => int prmCmpRatio;   // Ratio of compression
6 => int prmCmpThrsh;   // Threshold of compression
7 => int prmTimeOff;    // Time slop for additional swingyness
8 => int prmTimeSlide;  // Note to note slide
9 => int prmLength;     // Length of the param array

// ---------------------------------------------------------------------------
// HORN Player
// This is the horn player, which allows swing timing. It's 
// the design of the note array to get the timing correct. The global variable
// "horn_poison_pill" set to 1 will cause this player to quit. 

fun void play_horn(int pitch[], int mod[], int tim[], int len[], int vol[], float param[]) {
    // Note slop offset;
    dur offset;
    dur note_on;
    dur note_off;
    dur note_play;
        
    // Make sure we'll play
    0 => horn_poison_pill;
    
    // Basic time setting
    time_slice * param[prmCadance]  => dur full_time;

    // Index for the various arrays.
    0 => int index;
    
    // Parameter changes
    param[prmRvbGain] => rvb.gain;
    param[prmRvbMix]  => rvb.mix;
    
    while (!horn_poison_pill) {
        // Time for this pass, total
        full_time * tim[index] / 100.0 => note_play;
 
        // Is this a rest?
        if (RST == pitch[index] || 0 == pitch[index]) {
            note_play => now; 
            1 => horn.noteOff;
            1 => env.keyOff;
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
               Math.mtof(pitch[index] + 12 * mod[index]) => horn.freq;
               horn.freq() * 1.02 => h2.freq; 
               vol[index] / 100.0 => horn.noteOn;
               // 1.0 => horn.noteOn;
               vol[index] / 100.0 => h2.gain => horn.gain;
               1 => env.keyOn;
            }
            
            // Advance note time
            note_on - offset => now;
           
            // Shut things off
            1 => horn.noteOff;
            1 => env.keyOff;
            note_off => now;
       }
        
       (index + 1) % pitch.cap() => index;
    }

}


// Horn Score

[ RST,  Bb,   Db,   Eb,   Db,     RST,     F,     Ab,   F,  Gb,  Eb,        Bb,   C,  Eb,  Gb  ] @=> int horn_pitch[];
[  0,    1,    1,    1,    1,      0,      1,      1,   1,   1,   1,         1,   1,   1,   1  ] @=> int horn_mods[];
[100,  100,   50,   100,  80,    150,    250,     50,  50,  50,  50,       100, 100, 100, 100  ] @=> int horn_notes[];
[  0,   40,   40,    40,  90,      0,     90,    100, 100, 100, 100,        40,  40,  40,  70  ] @=> int horn_len[];
[  0,   40,   60,    70,  60,      0,     50,     50,  35,  60,  35,        70,  50,  70,  50  ] @=> int horn_vol[]; 

[1.0, -0.4, 0.05, 0.6, 8.0, 0.0, 0.0, 25.0, 50.0] @=> float horn_controls[];

// Main loop... just playing this. 
spork ~ play_horn(horn_pitch, horn_mods, horn_notes, horn_len, horn_vol, horn_controls);

time_part1 + time_solo + time_part2 + time_coda => now;


