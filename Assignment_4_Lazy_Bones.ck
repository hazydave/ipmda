// Class:   Introduction to Programming for Musicians and Digital Artists
// Program: Assignment 4: Lazy Bones
// Date:    2013-11-12


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
// samples, etc) is largely responsible for the timbre of each instrument. 

<<< "start-> ", "Assignment 4: Lazy Bones" >>>;
now => time program_start;

// Each Instrument has its own independent sound network variables. Here I'm
// just defining the global stuff. Yes, all the sound stuff is really global, 
// since we don't yet know how to do "static" variables within function or 
// objects, as one might in C (variables that are persistant within a function,
// rather than created and destroyed every time the function is used). 

// Master Volume. I'm using a Pan2 object rather than Gain, since it also 
// has a gain setting, but supports a stereo connection to synths and 
// samples. Adjustments to gain or the pan setting allow final control, 
// adjusted right here, over overall volume and L/R balance. In previous
// assignments, I did global volume by scaling every gain setting. This 
// is much less ugly. 


class LevelMeter extends Chugen {
    0 => float max_level; 
    
    fun float tick(float in) {
       Math.max(max_level, in) => max_level;
       return in;
    }
    
    fun float max() {
        return max_level;
    }
}

Pan2 master;
master.left => LevelMeter meter_left => dac.left;
master.right => LevelMeter meter_right => dac.right;

0.9 => master.gain; 
0.0 => master.pan;

// Notes controls, melody. Should be an object/structure array, but we're not there yet. 
 
// These are the legal notes, the Eb Mixolydian mode. I'm giving them nemonic names to 
// make the code to follow much easier to read. Also in an array, in case that form
// is useful to an individual instrument definition. Some note arrays take one or more
// special codes: RST = rest, STP = stop, RND = random. 
 
 51 => int Eb; 53 => int F; 55 => int G;  56 => int Ab;
 58 => int Bb; 60 => int C; 61 => int Db; 63 => int EbH; 
999 => int RST;
998 => int STP;
997 => int RND;
 
[ 51, 53, 55, 56, 58, 60, 61, 63 ] @=> int note_table[];
 
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

640        => int ticks;
30.0       => float time_limit_sec;
0.60       => float time_quarter_note_sec;
4          => int time_qnote_per_measure; 
4 * ticks  => int time_ticks_per_qnote;

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

// This function returns the note count in the current bar, where "note"
// is 2 = half note, 4 = quarter note, etc. If there's an off note count
// for the intro, this should be set here. 

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

// This function returns the current bar/measure in the composition. 
fun int now_bar() {
   return Math.trunc((now - time_start)  / (time_quarter_note * time_qnote_per_measure)) $ int;
}

// -------------------------------------------------------------------------------------------------
// Basic ramping functions
// This function does a linear volume ramp up or down. 

fun float ramp_vol_linear(float start_tick, float end_tick, float current_tick, float start_vol, float end_vol) {
    float result;
    
    start_vol + (end_vol - start_vol) * (current_tick / (end_tick - start_tick)) => result;
    Math.max(0.0,result) => result;

    return result;
}

// This function does an exponential volume ramp up or down. 

fun float ramp_vol_exp(float start_tick, float end_tick, float current_tick, float start_vol, float end_vol) {
    float result;
    
    if (start_vol > end_vol) {
        (start_vol - end_vol) * Math.exp((start_tick - current_tick)/((end_tick - start_tick)/4.0)) + end_vol => result; 
        Math.max(end_vol, result) => result;
    } else {
        (end_vol - start_vol) * Math.exp(end_tick - current_tick/((end_tick - start_tick)/4.0)) + end_vol => result;
        Math.min(end_vol, result) => result;
    }
    return Math.max(0.0,result);
}

// This slides one frequency into another

fun float ramp_freq_linear(float start_tick, float end_tick, float current_tick, float start_freq, float end_freq) {
    float result;
    
    start_freq + (end_freq - start_freq) * (current_tick / (end_tick - start_tick)) => result;
    
    return Math.max(0.0,result);    
}

// This function computes a running sin() modulation. The adjustment volume is specified as a
// percentage of the max. 

fun float sin_mod(float max_vol, float period, float adj_pct) {
    max_vol * adj_pct/200.0 => float adj_vol;
    max_vol => float result;
    
    if (0 < adj_pct && 0 < period) {
        max_vol - adj_vol + adj_vol * Math.sin(2.0 * 3.14159 / period * now_tick()) => result;
    }
    return Math.max(0.0,result);
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
// INSTRUMENTS
// Each instrument is modeled by three functions. The init function initializes the function's data.
// The build function is called once per slice, and usually sets the note or sample to play. The
// play function is called once per tick, and does any in-note/sample adjustments needed to realize
// the specific instrument. 

// ---------------------------------------------------------------------------------------------------
// Simple note with modulation

// This function takes in the "basis" for the simple instrument, 
fun void init_simple(Osc osc, Pan2 pan, float pos) {
    osc => pan => master;
    pos => pan.pan; 
    1 => osc.gain;
    0 => pan.gain;
}

// The simple builder takes in an array of notes and the note basis (2 = half note, 4 = quarter note, etc).
// Load up the MIDI note from the notes array, and go.
fun void build_simple(Osc osc, int notes[], int basis, int octave) {
    if (now_note_edge(basis)) { // time for a new note?
        notes[now_note(basis) % notes.cap()] => int note;
         
        if (RST == note) {
            0.0 => osc.freq;
        } else if (RND == note) {
            Std.mtof(note_table[Math.random2(0,note_table.cap())] + octave * 12) => osc.freq;
        } else {
            Std.mtof(note + octave * 12) => osc.freq;
        }
    }        
}

// This is the per-tick adjustment, taking in the basic and the modulation values array
fun void play_simple(Pan2 pan, float vol_max, int mod_per, int mod_gain) {
    sin_mod(vol_max, mod_per, mod_gain) => pan.gain;
}

// ---------------------------------------------------------------------------------------------------
// Simple sample with modulation. This just plays a sample with sine
// modulation. An array of rates (including stops) allows this to play from 
// a time-base array just like synth notes are. 

// This function takes in the "basis" for the simple instrument, 
fun void init_samp(SndBuf buf, Pan2 pan, Pan2 bus, float pos) {
    buf => pan => bus;
    pos => pan.pan; 
    1 => buf.gain;
    0 => pan.gain;
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
    sin_mod(vol_max, mod_per, mod_gain) => pan.gain;
}

// ---------------------------------------------------------------------------------------------------
// BasicADSR
// This instrument creates an oscillator, then modulates it. Startup parameters control the notes
// and the ADSR envelope. This instrument is designed for multiple instances.

// ADSR here is controlled by an array. 

 0 => int adsrBasis;         // The basis of the note, 2 = 1/2, 4 = 1/4, etc.
 1 => int adsrOp;            // Basic shape of the ASDR envelope
 2 => int adsrAttack;        // This is the count, in ticks, for the attack.
 3 => int adsrDecay;         // This is the count, in ticks, for the decay.
 4 => int adsrSustain;       // This is the count, in ticks, for the sustain
 5 => int adsrRelease;       // This is the count, in ticks, for the release
 6 => int adsrAttGain;       // This is the gain peak at the end of the attack.
 7 => int adsrSusGain;       // This is the gain at the sustain level.
 8 => int adsrModPer;        // Might as well toss in a modulation
 9 => int adsrModGain;       // Change based on modulation, as a percentage
10 => int adsrNote;          // Note selected
11 => int adsrOctave;        // Note octave, subject to tweaks.
12 => int adsrMax;           // Length of the array

// ASDR operator types
 0 => int adopLinear;        // Linear everything
 1 => int adopExpDecay;      // Exponential decay

// This function takes in the "basis" for the ADSR instrument, 
fun void init_ADSR(Osc osc, Pan2 pan, float pos, float basevol) {
    osc => pan => master;
    pos => pan.pan;
    0 => pan.gain; 
    basevol => osc.gain;
}

// The ADSR builder takes in an array of notes and the note basis (2 = half note, 4 = quarter note, etc).
// Load up the MIDI note from the notes array, and start the oscillator out at zero gain. 
fun void build_ADSR(Osc osc, int notes[], int adsr[]) {
    if (now_note_edge(adsr[adsrBasis])) { // time for a new note?
        now_note(adsr[adsrBasis]) % notes.cap() => int note;
        
        if (10 > notes[note]) {
            notes[note++] => adsr[adsrOctave];
        }
        
        if (RST == notes[note]) {
            0.0 => osc.freq;
        } else {
            Std.mtof(notes[note] + 12*adsr[adsrOctave]) => osc.freq;
        }
    }
}

// This is the per-tick adjustment, taking in the ADSR array
fun void play_ADSR(Osc osc, Pan2 pan, int adsr[]) {
    adsr[adsrBasis]             => int basis;
    now_tick_note(basis)        => int note_tick;
    adsr[adsrAttack]            => int attack;      // This are expressed in relative ticks in the
    adsr[adsrDecay]   + attack  => int decay;       // array, here they're converted to absolute
    adsr[adsrSustain] + decay   => int sustain;     // ticks.
    adsr[adsrRelease] + sustain => int release;
    float gain; 

    if (0 == osc.freq()) {
        0.0 => gain;
    } else if (note_tick <= attack) {      
        // Ramp up volume on attack    
        ramp_vol_linear(0, attack, note_tick, 0.0, adsr[adsrAttGain]/100.0) => gain;
    } else if (note_tick <= decay) { 
        // Ramp down volume to sustain levels
        if (adopExpDecay == adsr[adsrOp]) {
            ramp_vol_exp(attack-attack, decay-attack, note_tick-attack, adsr[adsrAttGain]/100.0, adsr[adsrSusGain]/100.0) => gain;    
        } else {
            ramp_vol_linear(attack, decay, note_tick-attack, adsr[adsrAttGain]/100.0, adsr[adsrSusGain]/100.0) => gain;    
        }
            
    } else if (note_tick <= sustain) {
        // Hold the sustain gain
        adsr[adsrSusGain] / 100.0 => gain;
    } else if (note_tick <= release) {
        // Ramp volume down during release
        ramp_vol_linear(sustain, release, note_tick-sustain, adsr[adsrSusGain]/100.0, 0.0) => gain;
    } else {
        0.0 => gain;
    }
    
    sin_mod(gain, adsr[adsrModPer], adsr[adsrModGain]) => pan.gain;
}

// ---------------------------------------------------------------------------------------------------
// Simple note with modulation

// This function takes in the "basis" for the simple instrument, 
fun void init_simple(Osc osc, Pan2 pan, float pos) {
    osc => pan => master;
    pos => pan.pan; 
    0 => osc.gain;
}

// The simple builder takes in an array of notes and the note basis (2 = half note, 4 = quarter note, etc).
// Load up the MIDI note from the notes array, and go.
fun void build_simple(Osc osc, int notes[], int basis, int octave) {
    if (now_note_edge(basis)) { // time for a new note?
        now_note(basis) % notes.cap() => int note;
         
        if (RST == notes[note]) {
            0.0 => osc.freq;
        } else {
            Std.mtof(notes[note] + octave * 12) => osc.freq;
        }
    }        
}

// This is the per-tick adjustment, taking in the basic and the modulation values array
fun void play_simple(Osc osc, float vol_max, int mod_per, int mod_gain) {
    sin_mod(vol_max, mod_per, mod_gain) => float gain;
    gain => osc.gain;
}

// ---------------------------------------------------------------------------------------------------
// Harmonic note with modulation

// This function takes in the "basis" for the simple instrument, 
fun void init_harmonic(SinOsc osc[], Pan2 pan, float pos, float vscale, float basevol) {
    basevol/(osc.cap() * vscale) => float gain;
    
    for (0 => int voice; osc.cap() > voice; ++voice) {
        osc[voice] => pan => master;
        gain => osc[voice].gain;
        gain * vscale => gain;
    }
    pos => pan.pan; 
    0   => pan.gain;
}

// The simple builder takes in an array of notes and the note basis (2 = half note, 4 = quarter note, etc).
// Load up the MIDI note from the notes array, and start the oscillator out at zero gain. 
fun void build_harmonic(SinOsc osc[], int notes[], int basis, int octave) {
    if (now_note_edge(basis)) { // time for a new note?
        now_note(basis) % notes.cap() => int note;
        for (0 => int voice; osc.cap() > voice; ++voice) {
            
            if (RST == notes[note]) {
                0.0 => osc[voice].freq;
            } else {
                Std.mtof(notes[note] + (voice + octave) * 12) => osc[voice].freq;
            }
        }
    }        
}

// This is the per-tick adjustment, taking in the basic and the modulation values array
fun void play_harmonic(Pan2 pan, float vol_max, int mod_per, int mod_gain) {
    sin_mod(vol_max, mod_per, mod_gain) => pan.gain;
}

// ---------------------------------------------------------------------------------------------------
// Sample with "echo" and modulation. This just plays a sample with sine
// modulation. An array of rates (including stops) allows this to play from 
// a time-base array just like synth notes are. 

// This function takes in the "basis" for the simple instrument, 
fun void init_samp_echo(SndBuf buf[], Pan2 pan, Pan2 bus, float pos, float vscale) {
    1.0 / (vscale * buf.cap()) => float gain;
    
    for (0 => int voice; buf.cap() > voice; ++voice) {
        buf[voice] => pan => bus;
        gain => buf[voice].gain;
        gain * vscale => gain;
    }
    pos => pan.pan; 
    0 => pan.gain;
}

// The simple builder takes a sample index (from the wave table), an optional note
// basis (2 = half note, 4 = quarter note, etc... -1 means always play) and a
// rate array (0 or RST means don't play), and sets up the sample to play.
fun void build_samp_echo(SndBuf buf[], int smp, int basis, float rate) {  
    // The -1 basis lets us just cancel this play
    if (-1 == basis) {
       return;
    }
       
    if (now_note_edge(basis)) {
        for (1 => int voice; buf.cap() > voice; ++voice) {
            wave_table[smp] => buf[voice].read;
            set_sample(buf[voice],rate,0);
        } 
        set_sample(buf[0],rate,1);
    }    
}

// The simple builder takes a sample index (from the wave table), an optional note
// basis (2 = half note, 4 = quarter note, etc... -1 means always play) and a
// rate array (0 or RST means don't play), and sets up the sample to play.
fun void build_samp_echo(SndBuf buf[], int smp, int basis, float ratelist[]) {   
    // The -1 basis lets us just cancel this play
    if (-1 == basis) {
       return;
    }
    build_samp_echo(buf, smp, basis, ratelist[now_note(basis) % ratelist.cap()] );
}

// This is the per-tick adjustment, taking in the basic and the modulation values array
fun void play_samp_echo(SndBuf buf[], Pan2 pan, int tdelay, int basis, float vol_max, int mod_per, int mod_gain) {
    sin_mod(vol_max, mod_per, mod_gain) => pan.gain;
    
    for (1 => int voice; buf.cap() > voice; ++voice) {
        if (now_tick_note(basis) == voice * tdelay) {
            set_sample(buf[voice],buf[voice].rate(),1);
        }
    } 
}

// ---------------------------------------------------------------------------------------------------
// Xylophone... sorta-kinda
// Here's the initialization; a Xylophone is made from two ADSR envelopes. This init
// sets up the ADSR envelopes, no need to pre-initialize them. 
fun void init_xylophone(SinOsc osc[], Pan2 pan, float pos, int basis, int octave, float basevol, int adsr[][]) {
    init_ADSR(osc[0], pan, pos, basevol);
    init_ADSR(osc[1], pan, pos, basevol);
    
    basis => adsr[0][adsrBasis] => adsr[1][adsrBasis];
    octave => adsr[0][adsrOctave];
    octave + 2 => adsr[1][adsrOctave];
    
    adopExpDecay => adsr[0][adsrOp] => adsr[1][adsrOp];
    
    100 => adsr[0][adsrAttack] => adsr[1][adsrAttack];
    500 => adsr[0][adsrDecay];
    250 => adsr[1][adsrDecay];
      0 => adsr[0][adsrSustain] => adsr[1][adsrSustain];
      0 => adsr[0][adsrRelease] => adsr[1][adsrRelease];
     50 => adsr[0][adsrAttGain] => adsr[1][adsrAttGain];
      0 => adsr[0][adsrSusGain] => adsr[1][adsrSusGain];
}

// The built and play functions just run both ADSRs. 
fun void build_xylophone(SinOsc osc[], int notes[], int adsr[][]) {
    build_ADSR(osc[0], notes, adsr[0]);
    build_ADSR(osc[1], notes, adsr[1]);
}
fun void play_xylophone(SinOsc osc[], Pan2 pan, int adsr[][]) {
    play_ADSR(osc[0], pan, adsr[0]);
    play_ADSR(osc[1], pan, adsr[1]);
}

// ===================================================================================================
// SONG NAVIGATION FUNCTIONS
// The song is defined to be 30 seconds with 0.6 second per quarter note, so that's 50 quarter notes, 
// 12.5 measures in 4/4 time. So I break this up into a part1 and part2, with a two-beat intro, a 
// two measure bridge, and a two measure coda. Keep in mind the first note is note 0. 

// Are we in the intro?
fun int now_intro() {
    return (now_note(4) < 2);
}

// Are we in part 1? 
fun int now_part1() {
    return (now_note(4) >= 2 && now_note(4) < 18);
}

// Are we in the bridge? 
fun int now_bridge() {
    return (now_note(4) >= 18 && now_note(4) < 26);
}

// Are we in part 2? 
fun int now_part2() {
    return (now_note(4) >= 26 && now_note(4) < 42);
}

// Are we in the coda? 
fun int now_coda() {
    return (now_note(4) >= 42);
}

// ===================================================================================================
// MAIN PROGRAM

// INITS
// All instrument init() functions are called here. Inits are called just once, and add the specific
// instrument to the sound network. 

// Hook all drums into a sub-bus
Pan2 drum_bus;
drum_bus => master;
0.5 => drum_bus.gain;

// Initialize cowbell
SndBuf cow1_buf;
Pan2   cow1_pan;
[ 1.0, 1.0, 0, 1.0,   1.0, 1.0, 0, 1.0,   1.0, 0, 1.0, 1.0,   0, 1.0, 0, 1.0 ] @=> float cow1_rate[];

init_samp(cow1_buf, cow1_pan, drum_bus, -1.0);

// Initialize kick drum
SndBuf kick_buf;
Pan2   kick_pan;
[0.0, 0.0, 1.0, 0 ] @=> float kick_rate[];

init_samp(kick_buf, kick_pan, drum_bus, 0);

// Initialize hat
SndBuf hat_buf;
Pan2   hat_pan;
[1.0, 0.0, 1, 1, 1, 0, 1, 0 ] @=> float hat_rate[];

init_samp(hat_buf, hat_pan, drum_bus, 0.2);

// Initialize snare with echo
SndBuf snare_buf[5];
Pan2   snare_pan;
[ 0.0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0 ] @=> float snare_rate[];

init_samp_echo(snare_buf, snare_pan, drum_bus, 0.3, -0.2);

// This is the main instrument, a harmonic set
SinOsc organ_osc[5];
Pan2   organ_pan;
0.0 => float  organ_volume;
0.3 => float  organ_volume_max;
0.005 => float organ_volume_adj;

[ RST,Eb, Db,F, Eb,G,  G,Ab,  Ab,C,  Eb,Bb, Bb,C, C,Eb ] @=> int organ_notes[];
[C, Db, Eb, G, Ab, G, Bb, F ]                            @=> int organ_bridge[];
[Db, RST, Eb, RST, Ab, RST, Bb, RST ]                    @=> int organ_coda[];

init_harmonic(organ_osc, organ_pan, 0.4, 0.65, 0.2);

// Initialize xylophone, which is a custom ASDR pair. There are different notes
// played for different parts of the piece. 
SinOsc xylophone_osc[2];
Pan2   xylophone_pan;
int    xylophone_adsr[2][adsrMax];

[ Eb, Db, Eb, Eb,   Db, Eb, Db, Db,    Bb, RST,  Bb, RST,    Db, Db, Bb, Eb, 
  Ab, Db, Ab, Ab,   Db, Ab, Db, Db,   RST,  Bb, RST,  Bb,    Ab, Bb, Ab, Bb,  
   G,  C,  G,  G,    C,  G,  C,  C,     F, RST,   F, RST,     G,  F,  G,  G,   
  Bb, Db, Bb, Bb,   Db, Bb, Bb, Bb,   RST,  Bb, RST,  Bb,    Eb, Bb, Eb, Eb ] @=> int xylophone_notes[];
  
[ Eb,    G, Db,  Bb, RST,  Eb,  C, G   ] @=> int xylophone_intro[];
[ Eb,  RST, Db, RST,  Bb, RST,  G, RST ] @=> int xylophone_bridge[];
[ RST, RST, Eb,  Eb, RST, RST, Ab, Ab  ] @=> int xylophone_coda[];

init_xylophone(xylophone_osc, xylophone_pan, 0.75, 16, 1, 0.1, xylophone_adsr);

// This is the bass, which is made from an ADSR. 
SinOsc bass_osc;
Pan2   bass_pan;

[ 4, adopExpDecay, 100,1000,600,400,   100,25,  0,0,   0,-1 ] @=> int bass_adsr[];
[ RST,    Db,   Eb,    G,     Ab,    RST,   Bb,   C ] @=> int bass_riff[];

init_ADSR(bass_osc, bass_pan, -0.5, 0.5);

// This is the main process loop. Everything is based on ChucK time, so there's not much need to 
// pass information to/from the instruments themselves. 

now => time_start;

while (now < time_start + time_limit) {    
    // BUILDS
    // All instrument build() functions are called here. Builds are called for each note event; it's
    // up to the individual instrument to play or not. 
    
    // This is the bass
    build_ADSR(bass_osc, bass_riff, bass_adsr);
    
    // Build for harmonic
    if (now_part1() || now_part2()) {
        build_harmonic(organ_osc, organ_notes, 8, 0);
        if (organ_volume < organ_volume_max) {
            organ_volume_adj +=> organ_volume;
        }
    } else if (now_bridge()) {
        organ_volume_max * 0.75 => organ_volume;
        build_harmonic(organ_osc, organ_bridge, 4, 0);
    } else if (now_coda()) {
        if (organ_volume > 0) {
            organ_volume_adj -=> organ_volume;
        }
        build_harmonic(organ_osc, organ_coda, 4, 0);
    }
    // Build for xylophone
    if (now_intro()) {
        build_xylophone(xylophone_osc, xylophone_intro, xylophone_adsr); 
    } else if (now_part1() || now_part2()) {
        build_xylophone(xylophone_osc, xylophone_notes, xylophone_adsr);
    } else if (now_bridge()) {
        build_xylophone(xylophone_osc, xylophone_bridge, xylophone_adsr);
    } else if (now_coda()) {
        build_xylophone(xylophone_osc, xylophone_coda, xylophone_adsr);
    } 
    
    // Build for Cowbell
    if (now_intro() || now_bridge()) {
        build_samp(cow1_buf, COWBELL_01, 8, cow1_rate);
    }
    
    // Build for Kick Drum and Hi-Hat
    if (now_part1() || now_part2()) {
        build_samp(kick_buf, KICK_02, 4, kick_rate);
        build_samp(hat_buf, HIHAT_01, 8, hat_rate);
    }  
    
    // Build for the echoy snare
    build_samp_echo(snare_buf, SNARE_01, 8, snare_rate);
       
    // PLAYS
    // All instrument play() functions are called in this loop. Each function is called once for
    // each tick. Timing is entirely based on ChucK time and the few setup variables for note
    // lengths, etc. Thus, each instrument can be self contained, rather than dependent on things
    // provided by this loop, other than the passage of time of course. 
    
    now => time tick_start;
    while (now < tick_start + time_slice) {
        // The bass is only in on the verses
        if (now_part1() || now_part2()) {
            play_ADSR(bass_osc, bass_pan, bass_adsr);
        }
        
        // The organ starts after the 2-note intro. There's a little random wobble to it, 
        // maybe suggesting a real organ a little more. 
        if (!now_intro()) {
            play_harmonic(organ_pan, organ_volume, 300, 50);
        }
        
        // The xylophone always plays... why miss a beat? 
        play_xylophone(xylophone_osc, xylophone_pan, xylophone_adsr);
        
        // Play the cowbell when needed, shut it down when not. 
        if (now_intro() || now_bridge()) {
            play_samp(cow1_pan, 0.4, 0, 0);
        }
        
        // Play the kick drum as needed. 
        if (now_part1() || now_part2()) {
            play_samp(kick_pan, 0.8, 0, 0);
            play_samp(hat_pan, 0.2, 0, 0);
        } 

        // Play the echoy snare
        play_samp_echo(snare_buf, snare_pan, 200,160, 0.4, 0, 0);
        
        // Play a single quantum of music
        time_quantum => now;
    }
}

<<< "end-> ", (now - time_start) / second, "sec, max volume: (L: ", meter_left.max(), ", R: ", meter_right.max(), ")" >>>;
