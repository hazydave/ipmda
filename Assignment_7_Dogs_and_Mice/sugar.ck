// File   : sugar.ck
// Class  : Introduction to Programming for Musicians and Digital Artists
// Program: Assignment 7: Dogs and Mice
// Date   : 2013-Dec-07
// Note   : PLEASE KEEP IF YOU FIND IT USEFUL

// ===========================================================================
// INSTRUMENT: Samples, used as "sugar" in the mix 
//
// SNDBUF SETUP
// This is my standard cut & paste for the class samples, with the directory
// adjusted for life down in a subdirectory..

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
// COWBELL

SndBuf cow => Pan2 cow_pan => Pan2 master => Mixdac.in;
-0.4 => cow_pan.pan;
 0.6 => cow_pan.gain;
 
// ==========================================================================
// CLAP
  SndBuf clap => Pan2 clap_pan => master;
 -0.7 => clap_pan.pan;
  0.5 => clap_pan.gain;

// ==========================================================================
// CLICK
  SndBuf click => Pan2 click_pan => master;
  -0.2 => click_pan.pan;
   0.8 => click_pan.gain;

// ===========================================================================
// Sample player

1.0     => master.gain; 
999.999 => float RST;

// This is the sample player
fun void play_sound(int smp, SndBuf snd, dur beat, int beats[], float rate[], dur playtime) {
    beat => dur sndbeat;
    0 => int seq;
    dur sndtime;
    wave_table[smp] => snd.read;
    snd.samples() => snd.pos;

    while (playtime > 0::ms) {
        if (RST != rate[seq]) {
            0 => snd.pos;
            rate[seq] => snd.rate;
            if (rate[seq] > 0) {
                0 => snd.pos;
            } else {
                snd.samples() => snd.pos;
            }
        }
        beats[seq]/100.0 * sndbeat => sndtime;
        sndtime => now;
        sndtime -=> playtime;  
        (seq + 1) % beats.cap() => seq;
    }
}

// Sample tables

// Cowbell tables
[ 100, 100, 100, 100, 100, 100, 100, 100 ] @=> int   cb_intro_beats[];
[ RST, RST, RST, RST, 1.0, 1.0, RST, 1.0 ] @=> float cb_intro_rate[];

[ 100, 100, 100, 100, 100, 100, 100, 100,    100, 100, 100, 100, 100, 100, 100, 100 ] @=> int   cb_bridge_beats[];
[ RST, 1.0, RST, 1.0, 1.0, 1.0, RST, 1.0,    RST, 1.0, RST, 1.0, RST, 1.0, RST, 1.0 ] @=> float cb_bridge_rate[];

[  50,  50,   100,   100,   50,  50,     100,   50,   50,  50,  50,    50,  50,   100,   100,   50,  50,     150,   50,  500 ] @=> int   cb_coda_beats[]; 
[ RST, 1.0,   RST,   1.0,  RST,  1.0,    RST,  RST,  1.0, RST, 1.0,   RST, 1.0,   RST,   1.0,  RST,  1.0,    RST,  1.0,  RST ] @=> float cb_coda_rate[];

// Hand clap tables.
[  75,  25,   100,   100,   75,  25,     100,   75,   25,  50,  50 ] @=> int   hc_coda_beats[]; 
[ RST, 1.0,   1.0,   RST,  RST,  1.0,    RST,  RST,  1.0, 1.0, RST ] @=> float hc_coda_rate[];

// Clicks
//[ 100,  25,  25,   25,  25,  100,  50,  20,  30,   100,  50,  25,  25, 100, 100,     100, 100,  50,  50, 100,      100,  50,  50,  25,  25,  25,  25,  100 ] @=> int  click_beats[];
//[ RST, RST,  RST, RST, RST,  RST, RST, 1.0, 1.0,   RST,  RST, RST, RST, RST ] @=> float click_rate[];

[ 100,  25,  25,   25,  25,  100,  50,  20,  30,   100,  25,  25,   25,  25,  100,  50,  20,  30 ] @=> int  click_beats[];
[ RST, RST,  RST, RST, RST,  RST, RST, 1.0, 1.0,   RST, RST,  RST, 1.0, RST,  RST, RST, 1.0, 1.0 ] @=> float click_rate[];

// Extra effects for intro
spork ~ play_sound(COWBELL_01, cow, BPM.eighthNote, cb_intro_beats, cb_intro_rate, Comp.section("intro"));

// Play intro
Comp.section("intro") => now; 

// Play part 1
spork ~ play_sound(CLICK_02, click, BPM.eighthNote, click_beats, click_rate, Comp.section("part1"));
Comp.section("part1") => now; 

// Setup for the bridge
spork ~ play_sound(COWBELL_01, cow, BPM.eighthNote, cb_bridge_beats, cb_bridge_rate, Comp.section("bridge"));
// Play the bridge
Comp.section("bridge") => now;


// Play part 2.
spork ~ play_sound(CLICK_02, click, BPM.eighthNote, click_beats, click_rate, Comp.section("part2"));
Comp.section("part2") => now; 

// Setup for coda
spork ~ play_sound(COWBELL_01, cow, BPM.eighthNote, cb_coda_beats, cb_coda_rate, Comp.section("coda"));
spork ~ play_sound(CLAP_01,   clap, BPM.eighthNote, hc_coda_beats, hc_coda_rate, Comp.section("coda"));
// Play us out
Comp.section("coda") => now; 

    