// Class:   Introduction to Programming for Musicians and Digital Artists
// Program: Assignment 5: Missing Pieces
// Date:    2013-11-21
// Note:    PLEASE KEEP IF YOU FIND IT USEFUL

// This program implements a build/play loop that abstracts different instruments. 
// Each instrument is effectively self-contained, called in abstract from the main
// loop to worry about just its own sound. 
// 
// There are two main phases in the main loop. The first section is the "build" 
// phase, which calls the build function for each instrument. This is called once
// per note period, and it sets up whatever is necessary for that instrument to
// play (or not, as the music dictates) in that segment. This part is what's
// primarily responsible for the musical content. 
//
// The second segment is the "play" phase. This actually breaks up the note into
// many independent segments, called ticks. Time is always advanced by just one
// tick. Each instrument's play function is called prior to that chucking of a 
// tick's worth of time, allowing things to be modified for that tick. These
// are things like adjusting volume to form modulation envelopes, that sort of
// thing. This part, along with the basic design of the instrument (oscillators,
// samples, etc) is largely responsible for the timbre of each instrument, though
// as we move to more capable instrument models, this is less important.

<<< "start-> ", "Assignment 5: Missing Pieces" >>>;
now => time program_start;

// This displays guitar MIDI notes as they play. If you're suspicious the guitar 
// model might be "cheating" with "illegal" notes, and want to see the actual notes
// being played (chord -> fretboard -> MIDI calculations), set this to 1.
0 => int chord_show_notes;

// Each Instrument has its own independent sound network variables. Here I'm
// just defining the global stuff. Yes, all the sound stuff is really global, 
// since we don't yet know how to do "static" variables within function or 
// objects, as one might in C (variables that are persistant within a function,
// rather than created and destroyed every time the function is used). 

// Master Volume. I'm using a Pan2 object rather than Gain, since it also 
// has a gain setting, but supports a stereo connection to synths and 
// samples. Adjustments to gain or the pan setting allow final control, 
// adjusted right here, over overall volume and L/R balance. 

Pan2 master => dac;
1.70 => master.gain;   // The total gain will vary a little each play. If it
0.08 => master.pan;    // distorts on your system, adjust here. 

// Notes controls, melody. Should be an object/structure array, but we're not there yet. 
 
// These are the legal notes, the Db Phrygian mode. I'm giving them mnemonic names to 
// make the code to follow much easier to read. Also in an array, in case that form
// is useful to an individual instrument definition. Some note arrays take one or more
// special codes: RST = rest, STP = stop, RND = random. 
 
 49 => int Db; 50 => int D; 52 => int E; 54 => int Gb;
 56 => int Ab; 57 => int A; 59 => int B; 61 => int DbH; 
999 => int RST;
998 => int STP;
997 => int RND;
 
[ 49, 50, 52, 54, 56, 57, 59, 61 ] @=> int note_table[];

// Guitar scales built from Db Phrygian
[ D,  E,    Gb,    A,     B,     D    ] @=> int  d_major_pentatonic[];
[ E,  Gb,   Ab,    B,     Db+12, E+12 ] @=> int  e_major_pentatonic[];
[ A,  B,    Db+12, E+12,  Gb+12, A+12 ] @=> int  a_major_pentatonic[];
[ Db, E,    Gb,    Ab,    B,     Db+12] @=> int db_minor_pentatonic[];
[ Gb, A,    B,     Db+12, E+12,  Gb+12] @=> int gb_minor_pentatonic[];
[ B,  D+12, E+12,  Gb+12, A+12,  B+12 ] @=> int  b_minor_pentatonic[];

// For guitar fretting notation

// String not played
-1 => int x; 

// This is the table of chords. The guitar model uses string offsets, not
// MIDI notes, to make chord transcription very easy. However, when used
// with standard tuning, all of these chords use notes only found in the
// Db Phrygian scale. You can trust me, or set the "chord_show_notes" 
// variable to 1, and they'll print out as they play. 

int chord_table[1][1][1];

 [[  0,  x,  x,  x,  x,  x ],  [  2,  x,  x,  x,  x,  x ],  [  4,  x,  x,  x,  x,  x ],  [  5,  x,  x,  x,  x,  x ],  [  7,  x,  x,  x,  x,  x ]] @=> chord_table["E-str"];     // Single notes: E  Gb Ab A  B
 [[  x,  0,  x,  x,  x,  x ],  [  x,  2,  x,  x,  x,  x ],  [  x,  4,  x,  x,  x,  x ],  [  x,  5,  x,  x,  x,  x ],  [  x,  7,  x,  x,  x,  x ]] @=> chord_table["A-str"];     // Single notes: A  B  Db D  E
 [[  x,  x,  0,  x,  x,  x ],  [  x,  x,  2,  x,  x,  x ],  [  x,  x,  4,  x,  x,  x ],  [  x,  x,  6,  x,  x,  x ],  [  x,  x,  7,  x,  x,  x ]] @=> chord_table["D-str"];     // Single notes: D  E  Gb Ab A
 [[  x,  x,  x,  1,  x,  x ],  [  x,  x,  x,  2,  x,  2 ],  [  x,  x,  x,  4,  x,  x ],  [  x,  x,  x,  6,  x,  x ],  [  x,  x,  x,  7,  x,  x ]] @=> chord_table["G-str"];     // Single notes: Ab A  B  Db D
 [[  x,  x,  x,  x,  0,  x ],  [  x,  x,  x,  x,  2,  x ],  [  x,  x,  x,  x,  3,  x ],  [  x,  x,  x,  x,  5,  x ],  [  x,  x,  x,  x,  7,  x ]] @=> chord_table["B-str"];     // Single notes: B  Dd D  E  Gb
 [[  x,  x,  x,  x,  x,  0 ],  [  x,  x,  x,  x,  x,  2 ],  [  x,  x,  x,  x,  x,  4 ],  [  x,  x,  x,  x,  x,  5 ],  [  x,  x,  x,  x,  x,  7 ]] @=> chord_table["e-str"];     // Single notes: E  Gb Ab A  B
 
 [[  x,  0,  2,  2,  2,  0 ],  [  5,  7,  7,  6,  5,  5 ],  [  x,  x,  7,  9, 10,  9 ],  [  x, 12, 11,  9, 10,  9 ],  [  x, 12, 14, 14, 14, 12 ]] @=> chord_table["A"];         // A
 [[  x,  0,  2,  1,  2,  0 ],  [  x,  0,  2,  2,  2,  4 ],  [  5,  x,  6,  6,  5,  x ],  [  x,  x,  7,  6,  5,  4 ]]                              @=> chord_table["Amaj7"];     // Amaj7
 [[  x,  0,  2,  2,  2,  2 ],  [  5,  x,  4,  6,  5,  x ],  [  5,  7,  x,  6,  7,  5 ],  [  x, 12,  x, 11, 14, 12 ],  [  x, 12, 11,  9,  9,  9 ]] @=> chord_table["A6"];        // A6 
 [[  x,  0,  2,  2,  0,  0 ]]                                                                                                                     @=> chord_table["Asus2"];     // Asus2
 [[  x,  0,  0,  2,  3,  0 ],  [  x,  0,  2,  2,  3,  5 ],  [  5,  7,  7,  7,  5,  5 ],  [ 12, 12, 14, 15, 12,  x ]]                              @=> chord_table["Asus4"];     // Asus4
  
 [[  x,  2,  4,  4,  3,  2 ],  [  7,  9,  9,  7,  7,  7 ]]                                                                                        @=> chord_table["Bm"];        // Bm
 [[  x,  2,  x,  1,  3,  2 ],  [  x,  2,  4,  x,  3,  4 ],  [  7,  x,  6,  7,  7,  7 ],  [  7,  9,  9,  7,  9,  7 ]]                              @=> chord_table["Bm6"];       // Bm6
 [[  x,  2,  0,  2,  0,  2 ],  [  x,  2,  4,  2,  3,  2 ],  [  7,  x,  7,  7,  7,  x ],  [  7,  9,  7,  7, 10,  7 ]]                              @=> chord_table["Bm7"];       // Bm7
 [[  x,  2,  4,  4,  2,  2 ]]                                                                                                                     @=> chord_table["Bsus2"];     // Bsus2
 [[  x,  2,  2,  4,  5,  2 ],  [  7,  9,  9,  9,  7,  7 ],  [  x,  x,  9,  9,  7,  7 ]]                                                           @=> chord_table["Bsus4"];     // Bsus4
 [[  x,  2,  4,  2,  2,  5 ]]                                                                                                                     @=> chord_table["B7sus2"];    // B7sus2
 [[  x,  2,  4,  2,  5,  2 ],  [  7,  9,  7,  9,  7,  7 ]]                                                                                        @=> chord_table["B7sus4"];    // B7sus4
  
 [[  x,  4,  2,  1,  3,  x ],  [  x,  4,  6,  6,  5,  4 ],  [  9, 11, 11,  9,  9,  9 ],  [  x,  x, 11,  9,  9, 12 ],  [  x,  x, 11, 13, 14, 12 ]] @=> chord_table["C#m"];       // C#m
 [[  x,  4,  2,  1,  0,  0 ],  [  x,  4,  x,  4,  5,  4 ],  [  9,  x,  9,  9,  9,  x ],  [  9, 11,  9,  9, 12,  9 ]]                              @=> chord_table["C#m7"];      // C#m7
 [[  x,  4,  4,  6,  7,  4 ],  [  x,  4,  6,  6,  7,  x ],  [  9,  1,  1,  1,  9,  9 ]]                                                           @=> chord_table["C#sus4"];    // C#sus4
 [[  x,  4,  4,  4,  2,  4 ],  [  x,  4,  6,  4,  7,  4 ]]                                                                                        @=> chord_table["C#m7sus4"];  // C#m7sus4

 [[  x,  x,  0,  2,  3,  2 ],  [  x,  5,  4,  2,  3,  2 ],  [ x,   5,  7,  7,  7,  5 ],  [ 10,  9,  7,  7,  7,  x ],  [ 10, 12, 12, 11, 10, 10 ]] @=> chord_table["D"];         // D
 [[  x,  5,  4,  2,  2,  2 ],  [  x,  5,  7,  6,  7,  5 ],  [ 10,  x, 11, 11, 10,  x ],  [  x,  x, 12, 11, 10,  9 ]]                              @=> chord_table["Dmaj7"];     // Dmaj7
 [[  x,  5,  2,  2,  2,  2 ],  [ 10,  x, 11, 11,  x, 12 ]]                                                                                        @=> chord_table["Dmaj9"];     // Dmaj9 
 [[  x,  5,  x,  6,  7,  7 ],  [ 10,  9,  9,  9, 10,  9 ]]                                                                                        @=> chord_table["Dmaj13"];    // Dmaj13
 [[  x,  x,  0,  2,  3,  0 ]]                                                                                                                     @=> chord_table["D6"];        // D6
 [[  x,  x,  0,  2,  0,  2 ],  [  x,  5,  7,  7,  7,  7 ],  [ 10,  x,  9, 11, 10,  x ],  [ 10, 12,  x, 11, 12, 10 ]]                              @=> chord_table["Dsus2"];     // Dsus2
  
 [[  0,  2,  2,  1,  0,  0 ],  [  0,  2,  2,  4,  5,  4 ],  [  0,  7,  6,  4,  5,  4 ],  [  x,  7,  9,  9,  9,  7 ],  [ 12, 11,  9,  9,  9,  x ]] @=> chord_table["E"];         // E
 [[  0,  2,  2,  1,  2,  0 ],  [  x,  x,  2,  4,  2,  4 ],  [  x,  7,  9,  9,  9,  9 ]]                                                           @=> chord_table["E6"];        // E6
 [[  0,  2,  0,  1,  0,  0 ],  [  0,  2,  2,  1,  3,  0 ],  [  x,  7,  9,  7,  9,  7 ],  [  x,  7,  9,  9,  9, 10 ],  [ 12,  x, 12, 13, 12,  x ]] @=> chord_table["E7"];        // E7 
 [[  0,  2,  0,  1,  0,  2 ],  [  x,  7,  6,  7,  7,  7 ],  [ 12,  x, 12, 11,  9,  x ]]                                                           @=> chord_table["E9"];        // E9
 [[  0,  x,  0,  1,  2,  2 ],  [  0,  2,  0,  1,  2,  2 ],  [  x,  7,  x,  7,  9,  9 ],  [ 12,  x, 12, 13, 14, 14 ]]                              @=> chord_table["E13"];       // E13 
 [[  0,  2,  4,  4,  3,  2 ]]                                                                                                                     @=> chord_table["E7sus2"];    // E7sus2
 [[  0,  2,  2,  2,  3,  0 ],  [  x,  7,  9,  7, 10,  x ]]                                                                                        @=> chord_table["E7sus4"];    // E7sus4
 [[  0,  2,  4,  4,  0,  0 ],  [  x,  7,  9,  9,  7,  7 ]]                                                                                        @=> chord_table["Esus2"];     // Esus2
 [[  0,  2,  2,  2,  0,  0 ],  [  x,  x,  2,  4,  5,  5 ],  [  x,  7,  7,  9, 10,  7 ],  [  x,  7,  9,  9, 10,  x ]]                              @=> chord_table["Esus4"];     // Esus4
 
 [[  2,  4,  4,  2,  2,  2 ],  [  x,  x,  4,  2,  2,  5 ],  [  x,  x,  4,  6,  7,  5 ],  [  x,  9,  7,  6,  7,  x ], [  x,  9, 11, 11, 10,  9 ]]  @=> chord_table["F#m"];       // F#m 
 [[  2,  x,  2,  2,  2,  x ],  [  2,  4,  4,  2,  5,  2 ],  [  x,  x,  4,  6,  5,  5 ],  [  x,  9,  7,  9,  7,  9 ], [  x,  9, 11,  9, 10, 12 ]]  @=> chord_table["F#m7"];      // F#m7
 [[  x,  x,  4,  1,  2,  2 ],  [  x,  9, 11, 11,  9,  9 ]]                                                                                        @=> chord_table["F#sus2"];    // F#sus2
 [[  2,  4,  4,  4,  2,  2 ],  [  x,  x,  4,  6,  7,  7 ],  [  x,  9,  9, 11, 12,  9 ]]                                                           @=> chord_table["F#sus4"];    // F#sus4
 [[  x,  x,  4,  1,  2,  0 ]]                                                                                                                     @=> chord_table["F#7sus2"];   // F#7sus2
 [[  2,  4,  2,  4,  2,  2 ],  [  x,  x,  4,  6,  5,  7 ]]                                                                                        @=> chord_table["F#7sus4"];   // F#7sus4

 [[  4,  2,  0,  1,  0,  x ]]                                                                                                                     @=> chord_table["G#dim"];     // G#dim
 [[  x,  x,  6,  7,  7,  7 ],  [  x, 11, 12, 11, 12,  x ]]                                                                                        @=> chord_table["G#m7b5"];    // G#m7b5
 
// Guitar standard tuning, in MIDI notes. These are never played directly unless they're legal notes, they're just
// fundamental to the guitar model. 

[40, 45, 50, 55, 59, 64] @=> int gtr_tuning_std[];
    
// Samples are represented as negative instruments, which are translated to
// entries in the sample table. Paths are now included.

me.dir() + "/audio/" => string samplepath;

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

// Duration of quantum and a tick, which set the timing for the system. I want to play and change things 
// seemingly at the same time. These control the rate and resolution of the playback. 

640        => int   ticks;
32.0       => float time_limit_sec;
0.75       => float time_quarter_note_sec;
4          => int   time_qnote_per_measure; 
4 * ticks  => int   time_ticks_per_qnote;
4          => int   time_slices_per_qnote;

0::second  => dur time_intro;

time_limit_sec::second        => dur time_limit;
time_quarter_note_sec::second => dur time_quarter_note;
time_quarter_note/2           => dur time_eighth_note;
time_eighth_note/2            => dur time_sixteenth_note;

time_sixteenth_note           => dur time_slice;
time_slice/ticks              => dur time_quantum; 

time time_start;

// ===================================================================================================
// BASIC FUNCTIONS
// These are primarily different ways of looking at time. In the past, I was using counters and
// other things to walk though arrays, make musical decisions, etc. This worked, but it pretty 
// much made the program run like a sequencer or tracker, with one big main program that did
// everything with a coordinated sense of time specific to the program. But ChucK already knows
// what time it is.. it's an intrinsic function of ChucK. These functions provide different ways
// of looking at that time. 

// These also allow each "instrument" to deal with the note timing it's worried about... a main
// melody perhaps playing quarter notes doens't have to deal with the fact some other 
// instrument may want 1/8th or 1/16th note resolution. 

// This function returns the current time, in ticks
fun int now_tick() {
    return Math.trunc((now - time_start) / time_quantum) $ int;
}

// This function returns the current time, in slices
fun int now_slice() {
    return Math.trunc((now - time_start) / time_slice) $ int;
}

// This function returns the current note count in the composition, where "note"
// is 2 = half note, 4 = quarter note, etc. 
fun int now_note(int note) {
    return Math.trunc((now - time_start) * note / (4 * time_quarter_note)) $ int;
}

// This function returns the current tick within the given even note boundary

fun int now_tick_note(int note) {
    return now_tick() - now_note(note) * time_ticks_per_qnote * 4 / note;
}

// This function returns the total number of ticks in the note

fun int max_tick_note(int note) {
    return ticks * 8 / note;
}

// Set the number of quarter notes in the introduction

fun void now_set_intro(int notes) {
    (notes * time_quarter_note_sec)::second => time_intro;
}

// This function returns the note count in the current bar, where "note"
// is 2 = half note, 4 = quarter note, etc. This is always zero for the
// introduction. 

fun int now_note_bar(int note) {
    return now_note(note) % ( note * time_qnote_per_measure / 4 );
}

fun int now_note_bar(int note, int intro) {
    return (now_note(note) - intro) % ( note * time_qnote_per_measure / 4 );
}

// This function returns "1" if we're at a note start/edge of the given type, 
// "0" otherwise.

fun int now_note_edge(int note) {
    1 => int last_tick;
    
    if (now > time_start) {
        Math.trunc((now - time_start - time_quantum) / (4 * time_quarter_note / note)) $ int => last_tick;
    }
    
    return last_tick != now_note(note);
}

// Are we in the introduction? 
fun int now_intro() {
    return (now < time_intro + time_start);
}

// This function returns the current bar/measure in the composition. 
fun int now_bar() {
    if (now_intro()) 
        return 0;
    
   return Math.trunc((now - time_start - time_intro)  / (time_quarter_note * time_qnote_per_measure)) $ int + 1;
}

// This just sets a sample on or off, based on the rate. 

fun void set_sample(SndBuf buf, float rate, int state) {
    rate => buf.rate;
    
    if (0.0 == rate || RST == rate) {
        0 => state;
    } else if (RND == rate) {
        if (Math.random2(0,2)) {
            1.0 => rate;
        }
    }
    
    if ((1 == state && rate > 0) || (0 == state && 0 > rate)) {
        0 => buf.pos;
    } else {
        buf.samples() => buf.pos;
    }
}

// ===================================================================================================
// GUITAR CHORD TABLE
// The chord table looks up the given note and the variation of that note, in the chord
// table by chord name. If found, it returns the list of 6 offsets on the guitar fretboard. If not
// found, it returns a list of all "x" fingerings -- nothing to play. There should be an easy
// way to test if chord_table[chord] doesn't exist (you can, actually, by printing it), but
// everythig I've tried so far is rejected. 

fun int[] chord_get_fingering(string chord, int var) {  
    [x, x, x, x, x, x] @=> int result[];
    
    if ("RST" != chord && chord_table[chord].cap() > var) {
        chord_table[chord][var] @=> result;
    }
    return result;   
}

// This gets an array of MIDI notes to play

fun int[] chord_get_MIDI(string chord, int var, int tuning[]) {
    chord_get_fingering(chord, var) @=> int offsets[];
    [RST, RST, RST, RST, RST, RST ] @=> int result[];
    
    for (0 => int i; i < tuning.cap(); ++i) {
        if (x == offsets[i]) {
            RST => result[i];
        } else {
            tuning[i] + offsets[i] => result[i];
        }
    }
    return result;
}

// This formats a MIDI note

fun int[] midi_note_format(int note) {
    0 => int offset;
    
    if (note == RST || note == 0 || note == x) {
        return [RST,0];
    }
    while (note < note_table[0]) {
        12 +=> note;
        12 -=> offset;
    }
    while (note > note_table[note_table.cap() -1]) {
        12 -=> note; 
        12 +=> offset;
    }
    
    return [note,offset];
}

// This function pretty-prints a chord name and content, based on the 
// set of legal notes for this assignment. 

fun void midi_print_notes(string chord, int mod, int notes[]) {
    int tmp[2];
    string result;
    
    for (0 => int i; i < notes.cap(); ++i) {
        midi_note_format(notes[i]) @=> tmp; 
        
        if (RST == tmp[0]) {
            result + "RST " @=> result;
        } else if (0 == tmp[1]) {
            result + tmp[0] + " " @=> result;
        } else if (0 < tmp[1]) {
            result + tmp[0] + "+" + tmp[1] + " " @=> result;
        } else {
            result + tmp[0] + "" + tmp[1] + " " @=> result;
        }
    }
    <<< "    SLICE:", now_slice(), "\t  ", chord, "(", mod, ")\tMIDI:", result>>>;            
}

// ===================================================================================================
// INSTRUMENTS
// Each instrument is modeled by three functions. The init function initializes the function's data.
// The build function is called once per slice, and usually sets the note or sample to play. The
// play function is called once per tick, and does any in-note/sample adjustments needed to realize
// the specific instrument. 

// ---------------------------------------------------------------------------------------------------
// Simple sample with modulation. This just plays a sample with sine
// modulation. An array of rates (including stops) allows this to play from 
// a time-base array just like synth notes are. 

// This function takes in the "basis" for the simple instrument, 
fun void init_samp(SndBuf buf, Pan2 pan, Pan2 bus, float pos) {
    buf => pan => bus;
    pos => pan.pan; 
    1 => buf.gain;
    1 => pan.gain;
}

// The simple builder takes a sample index (from the wave table), an optional note
// basis (2 = half note, 4 = quarter note, etc... -1 means always play) and a
// rate array (0 or RST means don't play), and sets up the sample to play.
fun void build_samp(SndBuf buf, int smp, int basis, float rate) {  
    // The -1 basis lets us just cancel this play
    if (-1 == basis) {
       return;
    }
       
    if (now_note_edge(basis)) {
        wave_table[smp] => buf.read;
        set_sample(buf,rate,1);
    }        
}

// The simple builder takes a sample index (from the wave table), an optional note
// basis (2 = half note, 4 = quarter note, etc... -1 means always play) and a
// rate array (0 or RST means don't play), and sets up the sample to play.
fun void build_samp(SndBuf buf, int smp, int basis, float ratelist[]) {   
    // The -1 basis lets us just cancel this play
    if (-1 == basis) {
       return;
    }    
    build_samp(buf, smp, basis, ratelist[now_note(basis) % ratelist.cap()] );
}


// This is the per-tick adjustment, taking in the basic and the modulation values array
fun void play_samp(Pan2 pan, float vol_max, int mod_per, int mod_gain) {   
}


// ===================================================================================================
// Guitar
// Basic 6-string rhythm guitar model

 6 => int gtrCtxBasis;    // Basis note, stored in context
 7 => int gtrCtxMute;     // Mute time, stored in context
 8 => int gtrCtxFade;     // Audio fade down
 9 => int gtrCtxCodaFade; // Coda fade down
10 => int gtrCtxCodaTime; // Coda fade start time
11 => int gtrCtxSize;     // Size of guitar context vector

1500 => int gtrFilter;

ticks*20 => int NOCTX;   // Large value, pushed out of possible note context

// Helper function for random string volume. There's a small chance of any one
// guitar string not being strummed. Most strings are hit at close to full
// volume, a few maybe a bit quieter. 
fun float gtr_string_vol(int one_played) {   
    if (!one_played) {
        return Math.random2f(0.95, 1.0);
    } 
    Math.random2(0,19) => int flip;
    
    if (0 == flip) {
        return 0.0;
    }
    if (12 < flip) {
        return Math.random2f(0.9, 1.0);
    }
        
    return Math.random2f(0.5,0.9);    
}

// This function builds the guitar signal chain
fun void init_gtr(StifKarp stk[], Pan2 pan, NRev rvb, LPF flt) {
    flt => rvb => pan => master;
    for (0 => int index; index < stk.cap(); ++index) {
        stk[index] => flt;
    }
     
    1.0 => pan.gain;
    1.0 => flt.gain;
    gtrFilter => flt.freq;
}

// This is the guitar builder function. Basically, I'm using the stiff string model for a 6-sting guitar -- sorta. The sound
// isn't right yet, but it's about as close as it's getting this week. Sometimes it sounds more like some Asian hammered
// string instrument, maybe. The strum can go up or down, just like a real guitar, and the timing for each string and the
// whole strum can vary. Like a real guitar, a strum can sustain into the next note period, if that's a rest and not a new
// strum, but it will be decaying in volume at that point. A strum can occasionally miss a note or two, but I don't let it
// miss every node. The "bass_in" parameter can also let it intentionally skip the bass string. 
fun int build_gtr(StifKarp stk[], Pan2 pan, LPF flt, int basis, string chord, int chord_mod, int strum_offset, int mute_offset, int bass_in, int coda_time, int coda_fade, int context[]) {
    chord_get_MIDI(chord, chord_mod, gtr_tuning_std) @=> int midi_notes[];
    0 => int strum_pos;
    0 => int rst_cnt;
    1 => int first_note;
    0 => int one_played;
        
    basis => context[gtrCtxBasis]; 
    mute_offset => context[gtrCtxMute];
    coda_time => context[gtrCtxCodaTime];
    coda_fade => context[gtrCtxCodaFade];
    100000 => context[gtrCtxFade];
    
    if (chord_show_notes) {
        midi_print_notes(chord, chord_mod, midi_notes);
    }
              
    if (0.0 < strum_offset) {
        0 => strum_pos;
    } else if (0.0 > strum_offset) {
        -5 * strum_offset => strum_pos; 
    }           
    for (0 => int index; index < stk.cap(); ++index) {
        if (RST != midi_notes[index]) {
            if (first_note) {
                0 => first_note;
                if (!bass_in) {
                    -1 => context[index];
                    continue;
                }
            }
            Std.mtof(midi_notes[index]) => stk[index].freq;
            Math.random2f( 0.6, 0.8 ) => stk[index].pluck;   
            Math.random2f( 0.5, 1.0 ) => stk[index].pickupPosition;
            Math.random2f( 0.7, 1.0 ) => stk[index].sustain;
            gtr_string_vol(one_played) => stk[index].gain;
            1.2 => stk[index].baseLoopGain; 
 
            if (one_played) {
                strum_pos => context[index];
                Math.random2(strum_offset/2, (strum_offset*4)/3) +=> strum_pos;
            } else {
                1 => one_played;
                0 => context[index];
                Math.random2(strum_offset/2, (strum_offset*4)/3) +=> strum_pos;
            }
        } else {
            NOCTX => context[index];
            ++rst_cnt;
        }
    }
        
    if (rst_cnt < stk.cap()) {
        0.75 => pan.gain;
    } else {
        99999 => context[gtrCtxFade];
    }
    
    if (rst_cnt > 4) {
        5000 => flt.freq;
    } else {
        gtrFilter => flt.freq;
    }
    
    return (time_slices_per_qnote * 4 / basis)-1;
}

// This is the guitar player function. This plays each string according to its computed
// offset. It'll only hit each string once, and there's no noteOff event... on a guitar,
// notes just decay unless you mute them, or of course, start another chord. 
fun void play_gtr(StifKarp stk[], Pan2 pan, int context[]) {
    for (0 => int index; index < stk.cap(); ++index) {
        if (context[index] <= now_tick_note(context[gtrCtxBasis])) {
            1.0 => stk[index].noteOn;
            NOCTX => context[index];
        } else if (context[gtrCtxCodaTime] < now_slice()) {
            pan.gain() * (context[gtrCtxCodaFade]/100000.0) => pan.gain;
        } else if (context[gtrCtxMute] <= now_tick_note(context[gtrCtxBasis])) {
            pan.gain() * (context[gtrCtxFade]/100000.0) => pan.gain;
        }
    }
}

// ===================================================================================================
// Bass thing
// Bass synth model... not sure what kind of bass instrument this is supposed to be. I wanted something
// kind of mellow, to fill in the low-end of the piece. I screwed around with trying to use hand-rolled
// FM synthesis for a more bass-guitar-like bass, but didn't really get there. I had the idea up to a 
// point, but couldn't get the filtering right. 

// Musically, the interesting thing about this bass is that I'm controlling the note period, so I can
// play shot notes even at a long note interval... part of what's cool about the bass sound is that
// staccto potential, which I didn't have in other instrument models. 

// Bass context accessors
0 => int bassCtxBasis;
1 => int bassCtxOn;
2 => int bassCtxOff;
3 => int bassCtxSize;

// Init the bass thing.
fun void bass_init(TriOsc bass, Pan2 pan, ADSR env, NRev rvb, LPF flt) {
    bass => env => flt => rvb => pan => master;
    
    1.0 => bass.gain;
    1.0 => pan.gain;
    1.0 => flt.gain;
    1000 => flt.freq;
}

// Make the bass for one note
fun int build_bass(TriOsc bass, Pan2 pan, int basis, int note, int note_mod, int note_length, int context[]) {
    basis => context[bassCtxBasis];
    Math.random2(0,100) => context[bassCtxOn];
    
    (time_ticks_per_qnote * 4 / basis) * note_length / 100 + context[bassCtxOn] => context[bassCtxOff];
    
    if (RST == note) {
        0 => bass.freq;
        NOCTX => context[bassCtxOn];
    } else {    
        Math.mtof(note + note_mod*12) => bass.freq;
    }
    
    return (time_slices_per_qnote * 4 / basis)-1;    
}


// This is the bass player function
fun void play_bass(Pan2 pan, ADSR env, int context[]) {
    if (context[bassCtxOn] <= now_tick_note(context[bassCtxBasis])) {
        env.keyOn();
        NOCTX => context[bassCtxOn];
    } else if (context[bassCtxOff] <= now_tick_note(context[bassCtxBasis])) {
        env.keyOff();
    }
}

// ===================================================================================================
// SONG NAVIGATION FUNCTIONS
// The song is defined to be 30 seconds with 0.75 second per quarter note, so 40 quarter notes, 
// 11 measures in 4/4 time. So the structure is:
// Intro:   4 quarter notes
// Part 1: 16 quarter notes
// Bridge:  4 quarter notes
// Part 2: 16 quarter notes
// Coda  :  2 quarter notes

time_slices_per_qnote * 4                     => int slices_at_part1;
time_slices_per_qnote * 16 + slices_at_part1  => int slices_at_bridge;
time_slices_per_qnote * 4  + slices_at_bridge => int slices_at_part2;
time_slices_per_qnote * 16 + slices_at_part2  => int slices_at_coda;

// This is true for any time in the introduction
fun int now_intro() {
    return (now_slice() < slices_at_part1);
}

// This is used check for the first slice in part1
fun int start_part1() {
    return (now_slice() == slices_at_part1);
}

// This is true for any time in part 1. 
fun int now_part1() {
    return (now_slice() >= slices_at_part1 && now_slice() < slices_at_bridge);
}

// This is used to check for the first slice in the bridge
fun int start_bridge() {
    return (now_slice() == slices_at_bridge);
}

// This is true for any time in the bridge.
fun int now_bridge() {
    return (now_slice() >= slices_at_bridge && now_slice() < slices_at_part2);
}

// This is used to check for the first slice in part2
fun int start_part2() {
    return (now_slice() == slices_at_part2);
}

// This is true for any time in part 2.
fun int now_part2() {
    return (now_slice() >= slices_at_part2 && now_slice() < slices_at_coda);
}

// This is used to check for the first slice in the coda
fun int start_coda() {
    return (now_slice() == slices_at_coda);
}

// This is true for any time in the coda. 
fun int now_coda() {
    return (now_slice() >= slices_at_coda);
}

// ===================================================================================================
// MAIN PROGRAM

// INITS
// All instrument init() functions are called here. Inits are called just once, and add the specific
// instrument to the sound network. 

// GUITAR
// Lots of inits for the 6-string acoustic guitar

StifKarp gtr_stk[6];                // One stiff string voice for each, well, string on the guitar
int      gtr_ctx[gtrCtxSize];       // Functional context for sharing between instrument functions
Pan2     gtr_pan;                   // Pan and mix all voices
NRev     gtr_rvb;                   // A little overall reverb
LPF      gtr_flt;

init_gtr(gtr_stk,gtr_pan,gtr_rvb,gtr_flt);

-0.4 => gtr_pan.pan;                // Put the guitar somewhere in the sound field. 
0.04 => gtr_rvb.mix;                // Add that aforementioned little bit o'reverb
0.6 => gtr_rvb.gain;               // Overall guitar volume. 

4 => int gtr_note_basis;
0 => int gtr_note_index;
0 => int gtr_next_note;

// This is the introductory part
["A-str", "e-str", "RST", "A-str", "e-str", "RST" ] @=> string gtr_chords_intro[];
[ 2,       0,       0,     2,       0,       0    ] @=> int    gtr_mods_intro[];
[ 1,       1,       0,     1,       1,       0    ] @=> int    gtr_strum_intro[];
[ 8,       8,       8,     8,       4,       4    ] @=> int    gtr_notes_intro[];

// This is part 1
[ "Bm7", "Dmaj7", "RST", "A",  "A",  "Dmaj9",     "Bm7", "Dmaj7", "RST", "A", "A", "Bm",     "Dsus2", "F#m", "C#m", "Dmaj7" ] @=> string gtr_chords_pt1[];
[  1,     0,       0,     1,    3,    0,           1,     3,       0,     1,   2,   0,        1,       2,     1,     2      ] @=> int gtr_mods_pt1[];
[  1,    -1,       0,     1,   -1,    1,           1,    -1,       0,     1,  -1,   1,        1,      -1,     1,    -1      ] @=> int gtr_strum_pt1[];
[  8,     8,       8,     8,    4,    4,           8,     8,       8,     8,   4,   4,        4,       4,     4,     4      ] @=> int gtr_notes_pt1[];

// This is the bridge, has anyone seen the bridge?
["A-str", "e-str", "RST", "A-str", "e-str", "RST" ] @=> string gtr_chords_bridge[];
[ 4,       0,       0,     4,       0,       0    ] @=> int    gtr_mods_bridge[];
[ 1,       1,       0,     1,       1,       0    ] @=> int    gtr_strum_bridge[];
[ 8,       8,       8,     8,       4,       4    ] @=> int    gtr_notes_bridge[];

// This is part 2
[ "Bm7", "Dmaj7", "RST", "A",  "A",  "Dmaj13",    "Bm7", "Dmaj7", "RST", "A", "A", "Bm",     "Dsus2", "F#m", "C#m", "Dmaj7" ] @=> string gtr_chords_pt2[];
[  3,     3,       0,     4,    2,    1,           3,     3,       0,     2,   4,   1,        3,       4,     3,     2      ] @=> int gtr_mods_pt2[];
[  1,    -1,       0,     1,   -1,    1,           1,    -1,       0,     1,  -1,   1,        1,      -1,     1,    -1      ] @=> int gtr_strum_pt2[];
[  8,     8,       8,     8,    4,    4,           8,     8,       8,     8,   4,   4,        4,       4,     4,     4      ] @=> int gtr_notes_pt2[];

// This is the coda
["A-str", "e-str", "RST"] @=> string gtr_chords_coda[];
[ 2,       0,       0,     4,       0,       0    ] @=> int    gtr_mods_coda[];
[ 1,       1,       0,     1,       1,       0    ] @=> int    gtr_strum_coda[];
[ 8,       8,       8,     8,       4,       4    ] @=> int    gtr_notes_coda[];

// Starter notes
gtr_chords_intro @=> string gtr_chords[];   // Chords are the guitar notes or chords to play
gtr_mods_intro   @=> int    gtr_mods[];     // Modes are chord modifiers, for different fingering of the same chord
gtr_strum_intro  @=> int    gtr_strum[];    // This is for strums, up or down right now, eventually maybe other options
gtr_notes_intro  @=> int    gtr_notes[];    // This is note duration

// Guitar fader
99990 => int gtr_fader;                    // Fade out at the end.
164   => int gtr_fade_time;                // When do I start? 

// BASS
// Initializations for simple bass sound

TriOsc bass_osc;                   // Oscillator for bass
int bass_ctx[bassCtxSize];         // Bass context vector
Pan2 bass_pan;                     // Pan/volume for bass
ADSR bass_env;                     // ADSR envelope generator for bass
NRev bass_rvb;                     // Reverb for bass
LPF bass_flt;                      // Low-pass filter for bass

bass_init(bass_osc, bass_pan, bass_env, bass_rvb, bass_flt);

0.4  => bass_pan.pan;              // Put the bass somewhere in the sound field. 
0.04 => bass_rvb.mix;              // Balance reverb
0.1  => bass_rvb.gain;             // Overall volume. 

4 => int bass_note_basis;
0 => int bass_note_index;
0 => int bass_next_note;
0 => int bass_play;

// This is part 1
[ Db,  D,  E, Gb, Db,  D, Db,   E,  Ab,   B,  E  ] @=> int bass_pitch_pt1[];
[ -1, -1, -1, -1, -1, -1, -1,  -1,  -1,  -1, -1  ] @=> int bass_mods_pt1[];
[  4,  4, 16, 16, 16, 16,  4,   4,   4,   4,  4  ] @=> int bass_notes_pt1[];
[ 80, 80, 80, 80, 80, 80, 80,  30,  30,  30, 30  ] @=> int bass_len_pt1[];

// This is the bridge 4 1/4 notes
[ RST, Db, RST,  D, RST, Db, RST,  D, RST, Db, RST,  D ] @=> int bass_pitch_bridge[];
[   0, -1,   0, -1,   0, -1,   0, -1,   0, -1,   0, -1 ] @=> int bass_mods_bridge[];
[  16, 16,  16, 16,  16, 16,  16, 16,   8,  8,   8,  8 ] @=> int bass_notes_bridge[];
[   0, 50,   0, 50,   0, 50,   0, 50,   0, 50,   0, 50 ] @=> int bass_len_bridge[];

// This is part 2
[ Db,  D, RST, Gb, RST,  B, Db,   E,  Ab,  B,  E ] @=> int bass_pitch_pt2[];
[ -1, -1,  -1, -1,   0, -1, -1,  -1, -1,  -1, -1 ] @=> int bass_mods_pt2[];
[  4,  4,  16, 16,  16, 16,  4,   4,  4,   4,  4 ] @=> int bass_notes_pt2[];
[ 80, 80,  80, 80,  80, 80, 80,  30, 80,  30, 80 ] @=> int bass_len_pt2[];

// Starter notes (bass kicks in on part 1)
bass_pitch_pt1 @=> int bass_pitch[];
bass_mods_pt1  @=> int bass_mods[];
bass_notes_pt1 @=> int bass_notes[];
bass_len_pt1   @=> int bass_len[];

// PERCUSSION
// Initializations for sample-based percussion

// Hook all drums into a sub-bus
Pan2 drum_bus;
drum_bus.left  => LPF drum_lpf_left => Dyno drum_dyno_left => NRev drum_rvb_left  => master;
drum_bus.right => LPF drum_lpf_right => Dyno drum_dyno_right => NRev drum_rvb_right => master;

0.2  => drum_bus.gain;                                            // Overall level
0    => drum_bus.pan;                                             // Position of drums in the sound field
0.04 => drum_rvb_left.mix         => drum_rvb_right.mix;          // Amount of reverb
0.8  => drum_rvb_left.gain        => drum_rvb_right.gain;         // Reverb gain
4000 => drum_lpf_left.freq        => drum_lpf_right.freq;         // Low pass filter
drum_dyno_left.compress();   // Set up for compression
drum_dyno_right.compress();


// Initialize cowbell
SndBuf click_buf;
Pan2   click_pan;
0 => int click_play;
[ 1.0, 1.0, 0, 1.0,   1.0, 1.0, 0, 1.0,   1.0, 0, 1.0, 1.0,   0, 1.0, 0, 1.0 ] @=> float click_rate[];

init_samp(click_buf, click_pan, drum_bus, -6.0);

// Initialize snare drum
SndBuf snare_buf;
Pan2   snare_pan;
0 => int snare_play;
[1.0, 0.0, 1.0, 0 ] @=> float snare_rate[];

init_samp(snare_buf, snare_pan, drum_bus, 0);

// Initialize hat
SndBuf hat_buf;
Pan2   hat_pan;
0 => int hat_play;
[1.0, 0.0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0 ] @=> float hat_rate[];

init_samp(hat_buf, hat_pan, drum_bus, 0.2);

// This is the main process loop. Everything is based on ChucK time, so there's not much need to 
// pass information to/from the instruments themselves. 

now => time_start;

<<< "Intro:  slice=", now_slice() >>>;

while (now < time_start + time_limit) {  
    // SECTIONS
    // The use of array assignments lets the section code de-couple from the build code, which ought to make
    // for a somewhat clearer function. 
 
    if (start_part1()) {
        <<< "Part 1: slice=", now_slice() >>>;
        0 => gtr_note_index;
        gtr_chords_pt1 @=> gtr_chords;   gtr_mods_pt1 @=> gtr_mods;  gtr_strum_pt1 @=> gtr_strum;  gtr_notes_pt1  @=> gtr_notes;
        0 => bass_note_index;
        1 => bass_play;
        1 => snare_play;
        1 => hat_play;
        
    }
    if (start_bridge()) {
        <<< "Bridge: slice=", now_slice() >>>;
        0 => gtr_note_index;
        gtr_chords_bridge @=> gtr_chords;    gtr_mods_bridge @=> gtr_mods;    gtr_strum_bridge @=> gtr_strum;  gtr_notes_bridge @=> gtr_notes;
        0 => bass_note_index;
        bass_pitch_bridge @=> bass_pitch;  bass_mods_bridge  @=> bass_mods;  bass_notes_bridge @=> bass_notes;  bass_len_bridge @=> bass_len;
        1 => bass_play;
        1 => click_play;
    }
    if (start_part2()) {
        <<< "Part 2: slice=", now_slice() >>>;
        0 => gtr_note_index;
        gtr_chords_pt2 @=> gtr_chords;   gtr_mods_pt2 @=> gtr_mods;    gtr_strum_pt2 @=> gtr_strum;  gtr_notes_pt2 @=> gtr_notes;
        0 => bass_note_index;
        bass_pitch_pt2 @=> bass_pitch;  bass_mods_pt2 @=> bass_mods;  bass_notes_pt2 @=> bass_notes;  bass_len_pt2 @=> bass_len;
        1 => bass_play;
        0 => click_play;
        1 => snare_play;
        1 => hat_play;
    }
    if (start_coda()) {
        <<< "Coda:   slice=", now_slice() >>>;
        0 => gtr_note_index;
        gtr_chords_coda @=> gtr_chords;   gtr_mods_coda @=> gtr_mods;  gtr_strum_coda @=> gtr_strum;  gtr_notes_coda  @=> gtr_notes;
        0 => bass_play;
        0 => snare_play;
        0 => hat_play;
    }
    
    // BUILDS
    // All instrument build() functions are called here. Builds are called for each note event; it's
    // up to the individual instrument to play or not. 
    
    // The next guitar note
    if (!gtr_next_note--) {
        build_gtr(gtr_stk, gtr_pan, gtr_flt, gtr_notes[gtr_note_index], gtr_chords[gtr_note_index], gtr_mods[gtr_note_index], 
                  gtr_strum[gtr_note_index] * Math.random2(5,50), time_ticks_per_qnote - Math.random2(0,10)*20, 
                  now_note_bar(gtr_notes[gtr_note_index])%2, gtr_fade_time, gtr_fader, gtr_ctx) => gtr_next_note;

        (gtr_note_index +1) % gtr_chords.cap() => gtr_note_index;
    }
    
    // The next bass note
    if (bass_play && !bass_next_note--) {
         build_bass(bass_osc, bass_pan, bass_notes[bass_note_index], bass_pitch[bass_note_index],
                    bass_mods[bass_note_index], bass_len[bass_note_index], bass_ctx) => bass_next_note;
        (bass_note_index + 1) % bass_pitch.cap() => bass_note_index;
    }
    
    // Build for click
    if (click_play) {
        build_samp(click_buf, CLICK_01, 8, click_rate);
    }
    
    // Build for snare drum
    if (snare_play) {
        build_samp(snare_buf, SNARE_01,  4, snare_rate);
    }
    
    // Built for Hi-Hat
    if (hat_play) {
        build_samp(hat_buf, HIHAT_02,  16, hat_rate);
    }  
      
    // PLAYS
    // All instrument play() functions are called in this loop. Each function is called once for
    // each tick. Timing is entirely based on ChucK time and the few setup variables for note
    // lengths, etc. Thus, each instrument can be self contained, rather than dependent on things
    // provided by this loop, other than the passage of time of course. 
    
    now => time tick_start;
    while (now < tick_start + time_slice) {
        // The guitar player is pretty smart, and just rests when not playing, so no need to
        // qualify based on sections. 
        play_gtr(gtr_stk, gtr_pan, gtr_ctx);
        
        // Play the bass when needed
        if (bass_play) {
            play_bass(bass_pan, bass_env, bass_ctx);
        }
        
        // Play the click when needed
        if (click_play) {
            play_samp(click_pan, 0.4, 0, 0);
        }
        
        // Play the snare as needed. 
        if (snare_play) {
            play_samp(snare_pan, 0.8, 0, 0);
        }
        
        // Play the high-hat as needed
        if (hat_play) {
            play_samp(hat_pan, 0.2, 0, 0);
        } 
        
        // Play a single quantum of music
        time_quantum => now;
    }
}

<<< "end-> ", (now - time_start) / second, "sec" >>>;

