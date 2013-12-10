// File:    drums.ck
// Class:   Introduction to Programming for Musicians and Digital Artists
// Program: Assignment 6: Cocktail I.V.
// Date:    2013-28-21
// Note:    PLEASE KEEP IF YOU FIND IT USEFUL
// ===========================================================================
// COMMON CODE
// Since we can't coordinate actively between modules this week, this code is 
// used to synchronize things. 


// High level sound network
Pan2 module_bus => Mixdac.in;           // The sub-bus for this module
0.0 => module_bus.pan;                  // Module pan position.
0.0 => module_bus.gain;                 // Start out quiet for fade-in
3.0 => float module_level;              // Peak level for this specific module.

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

// Fader settings
 time_quarter_note * 4 => dur time_fade_in;
 time_quarter_note * 4 => dur time_fade_out;
 1.0/(time_ticks_per_qnote * 4) => float fader_inc; 

// Fader function
fun void fader(UGen ug) {
    // fade in
    while (now - time_start < time_fade_in) {
        ug.gain() + fader_inc => ug.gain;
        time_quantum => now;
    }
    // Play normally
    module_level => ug.gain;
    (time_play - time_fade_in - time_fade_out) => now;
        
    // Fade out
    while (ug.gain() > 0.0001) {
        ug.gain() - fader_inc => ug.gain;
        time_quantum => now;
    }
}

spork ~ fader(module_bus);

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
// SNDBUF SETUP
// This is my standard cut & paste for the class samples, with the directory
// adjusted for life down in the JazzBand directory.
// Samples are represented as negative instruments, which are translated to
// entries in the sample table. Paths are now included.

me.dir(-1) + "/audio/" => string samplepath;

[ samplepath +      "clap_01.wav", samplepath +     "click_01.wav", samplepath +     "click_02.wav", 
  samplepath +     "click_03.wav", samplepath +     "click_04.wav", samplepath +     "click_05.wav",
  samplepath +   "cowbell_01.wav", samplepath +     "hihat_01.wav", samplepath +     "hihat_02.wav",
  samplepath +     "hihat_03.wav", samplepath +     "hihat_04.wav", samplepath +      "kick_01.wav",
  samplepath +      "kick_02.wav", samplepath +      "kick_03.wav", samplepath +      "kick_04.wav",
  samplepath +      "kick_05.wav", samplepath +     "snare_01.wav", samplepath +     "snare_02.wav",
  samplepath +     "snare_03.wav", samplepath + "stereo_fx_01.wav", samplepath + "stereo_fx_02.wav", 
  samplepath + "stereo_fx_03.wav", samplepath + "stereo_fx_04.wav", samplepath + "stereo_fx_05.wav"
 ] @=> string wave_table[];
  
// Mnemonics for waves. This is manually built to match the wave table. This is used in the
// Instrument field for the main notes table. 

  0 => int CLAP_01;
  1 => int CLICK_01;       2 => int CLICK_02;       3 => int CLICK_03;       4 => int CLICK_04;       5 => int CLICK_05;
  6 => int COWBELL_01;
  7 => int HIHAT_01;       8 => int HIHAT_02;       9 => int HIHAT_03;      10 => int HIHAT_04; 
 11 => int KICK_01;       12 => int KICK_02;       13 => int KICK_03;       14 => int KICK_04;       15 => int KICK_05;
 16 => int SNARE_01;      17 => int SNARE_02;      18 => int SNARE_03; 
 19 => int STEREO_FX_01;  20 => int STEREO_FX_02;  21 => int STEREO_FX_03;  22 => int STEREO_FX_04;  23 => int STEREO_FX_05;

// ===========================================================================
// INSTRUMENT CODE
// PERCUSSION SECTION

// ---------------------------------------------------------------------------
// RIDE CYMBAL
// The idea of playing some jazz without many of the appropriate jazz 
// instruments yields insanity like this experiment. 

// This function does all the significant setup on the ride cymbal sound chain, then plays it. 
// The ride sound is fairly complicated; it uses a Modal bar, a noise generator, and a hi-hat
// sample. The hi-hat and the noise generator are mixed into an ADSR envelope, which 
// has a slow-enough attack to allow the modal bar to dominate early, then a longer decay
// to ensure the noise-i-fied high-hat characteristic comes through as the sound fades. 
fun void play_ride(int pat[], int tim[]) {
    // Main ride cymbal sound chain
    ModalBar cymbal;
    Noise noise;
    SndBuf buf;
    Pan2 pan;
    -0.1 => pan.pan;
    
    // Swing setting
    time_eighth_note         => dur full_time;

    // Index for the various arrays. 
    0  => int index;

    // Additional variables for this signal chain. 
    ADSR env;
        env.set(25::ms, 50::ms, 0, 0::ms);
    NRev rvb;
        0.30 => rvb.mix;
        0.95 => rvb.gain;
    Delay dly;
        5::ms => dly.delay;
    Gain dgain;
        0.3 => dgain.gain;
    Dyno comp;
        comp.compress();

    // Set up the root signal chain.
    dly => rvb => pan => module_bus;
    
    // And the delay feedback
    dly => dgain => dly;
    
    // Set the component signal chain.  
    cymbal => dly;        
    noise  => env => dly;
    buf    => env;

    // Parameters for the modal bar
    1.0    => cymbal.stickHardness;
    0.4    => cymbal.strikePosition;
    1000.0 => cymbal.vibratoFreq;
    0.9    => cymbal.vibratoGain;
    0.5    => cymbal.damp;
    3      => cymbal.preset; 
    1500   => cymbal.freq;
    1      => cymbal.gain;
    
    // Parameters for the noise
    0.0   => noise.gain;
    
    // Parameter for the sound buffer
    wave_table[HIHAT_03] => buf.read;
    buf.samples() => buf.pos;
    0.3 => buf.gain;
    
    while (true) {
         // Enable playing when it's time to play. 
        if (now_slice() == slices_at_solo) {
           time_solo => now; 
        }
        //if (start_part2()) 1 => play;
        
        // Right now the pattern table has one entry for each slice, so ther'e 
        // no need to check note boundaries. 
        if (pat[index] != 0) {  
            1 => cymbal.noteOn;
            1 => env.keyOn;
            0 => buf.pos;
            pat[index]/100.0 => pan.gain;
        }
        full_time * tim[index]/100.0 => now;
        1 => cymbal.noteOff;
        (index + 1) % pat.cap() => index;
    }
}

// ---------------------------------------------------------------------------
// BASIC DRUM
// The basic drum can do interesting things with most any sample. 

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

// This function does all the significant setup for a basic sampled "drum" sound chain, then plays it. 
fun void play_basic(int drum, int pat[], float param[]) {
    // Main Drum sound chain
    SndBuf buf;
    Pan2 pan;
    Dyno cmp; 
    dur offset;

    param[prmPan] => pan.pan;

    // Index for the various arrays
    0 => int index;

    // Additional variables for this signal chain. 
    NRev rvb;
        param[prmRvbMix] => rvb.mix;

    // Set the signal chain.  
    if (param[prmCmpRatio]) {
        buf => rvb => cmp => pan => module_bus;
        cmp.compress();
        param[prmCmpRatio] => cmp.slopeAbove;
        param[prmCmpThrsh] => cmp.thresh;
        <<< "Compression used" >>>;
    } else {
        buf => rvb => pan => module_bus;
    }
    param[prmRvbGain] => rvb.gain;

    // The actual samples to play
    wave_table[drum] => buf.read;
    buf.samples() => buf.pos;
    
    while (true) {
        // Random note offset
        Math.random2f(0,param[prmTimeOff])::ms => offset;
        offset => now;
        
        // Arm if we're playing this note
        if (pat[index]) {
            0 => buf.pos;
            param[prmGain] * pat[index]/100.0 => buf.gain;
        }
        (index+1) % pat.cap() => index;
        
        (time_slice * param[prmCadance]) - offset => now;
    }
}

// ---------------------------------------------------------------------------
// SWING DRUM
// This is just like the BASIC drum, but allows notes to take up only a precentage of
// the note time, to allow construction of swing rhythms. 

// The swing player... just like the basic player, but with an array of play time
// percentages. 
fun void play_swing(int drum, int pat[], int tim[], float param[]) {
    // Main Drum sound chain
    SndBuf buf;
    Pan2 pan;
    Dyno cmp;
    dur offset;
    
    // Output pan setting
    param[prmPan] => pan.pan;
            
    // Basic time setting
    time_slice * param[prmCadance]  => dur full_time;

    // Index for the various arrays
    0 => int index;

    // Additional variables for this signal chain. 
    NRev rvb;
        param[prmRvbMix] => rvb.mix;
        param[prmRvbGain] => rvb.gain;

    // Set the signal chain.     
   
 // Set the signal chain.  
    if (param[prmCmpRatio]) {
        buf => rvb => cmp => pan => module_bus;
        cmp.compress();
        param[prmCmpRatio] => cmp.slopeAbove;
        param[prmCmpThrsh] => cmp.thresh;
        
    } else {
        buf => rvb => pan => module_bus;
    }  
  
    // The actual samples to play
    wave_table[drum] => buf.read;
    buf.samples() => buf.pos; 
    param[prmGain] => buf.gain;
        
    while (true) {
        // Random note offset
        Math.random2f(0,param[prmTimeOff])::ms => offset;
        offset => now;
        
        // We count real time here, so there's no need to check for note 
        // edges. 
        if (pat[index]) {  
            0 => buf.pos;
            param[prmGain] * pat[index]/100.0 => buf.gain;
        }
        (full_time * tim[index]/100.0) - offset => now;
        (index + 1) % pat.cap() => index;
    }
}

// ===========================================================================
// LAUNCH CODE
// MAIN PROGRAM

// Main section for actually playing things. 

// The ride cymbal is custom made, with swing, to deliver a credible ride 
// cymbal sound. 
[ 75,   0,  100,   0,  75] @=> int ride_pattern[];
[100, 100,  100,  40,  60 ] @=> int ride_time[];
spork ~ play_ride(ride_pattern, ride_time);

// The Hi-Hat is a "basic" sample that plays from a note loop and a parameter array. 
[0, 90, 0, 50, 0, 100, 0, 75 ] @=> int hat_pattern[];
[0.7, -0.1, 0.4, 0.3, 8.0, 0.0, 0.0, 25.0] @=> float hat_controls[];
spork ~ play_basic(HIHAT_04, hat_pattern, hat_controls);

// The Snare is played with a swing pattern
[  0,  0, 20, 25, 30, 50,   0,   0, 20,   0,  75,   0, 25,   0,   0,      0,   0, 25,  0, 25,   0,    0,     75,   0,  95,   0, 30, 20, 40, 20 ] @=> int snare_pattern[];
[100, 10, 10, 10, 10, 60, 100,  40, 60,   25, 75,  90, 10, 100, 100,    100,  30, 20, 20, 30,  100, 100,    100, 100, 100,  15, 15, 15, 15, 40 ] @=> int snare_time[];

[0.9, 0.1, 0.1, 1.0, 8.0, 0.0, 0.0, 10.0 ] @=> float snare_controls[];
spork ~ play_swing(SNARE_03, snare_pattern, snare_time, snare_controls);

// Kick is also a swing drum
[ 90,   0,    0,   0,  60,      0,   0,   0,   0,         0,  0,  70,    0,    0,  50,     0,   0,   0,   0 ] @=> int kick_pattern[];
[100, 100,  100,  30,  70,    100, 100, 100, 100,       100, 30,  70,  100,   30,  70,    100, 100, 100, 100 ] @=> int kick_time[];
[0.5, 0.1, 0.1, 1.0, 4.0, 0.0, 0.0, 10.0] @=> float kick_controls[];
spork ~ play_swing(KICK_03, kick_pattern, kick_time, kick_controls);

30::second => now;