// File:    drum_part.ck
// Class:   Introduction to Programming for Musicians and Digital Artists
// Program: Assignment 8: A Chase Would Be Nice
// Date:    2013-Dec-15
// Note:    PLEASE KEEP IF YOU FIND IT USEFUL
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
// INSTRUMENT: Drums.. something for the low end...

DrumKit bongo  => Pan2 bongo_pan  => Pan2 master => Mixdac.in;
DrumKit kick   => Pan2 kick_pan   => Dyno kick_comp => master;
SndBuf hihat   => Pan2 hat_pan    => master;
SndBuf snare   => Pan2 snare_pan  => master;

1.0  => master.gain; 

// Settings for drum soundfield
-0.5 => bongo_pan.pan;
0.05  => bongo_pan.gain;

-0.3 => kick_pan.pan;
0.75 => kick_pan.gain;
kick_comp.compress();

-0.2 => hat_pan.pan;
0.15 => hat_pan.gain;

-0.4 => snare_pan.pan;
0.15  => snare.gain;

// Thread control


// This is the kick player
fun void kick_me(dur runtime) {
    BPM.quarterNote => dur kickbeat;
    0 => int seq;
    0 => int beat;
    dur skew; 
    now + runtime => time endtime;

    while (now < endtime) {  
        Math.random2f(0.0, kickbeat/ms * 1/32)::ms => skew; 
        skew => now;
       
        Math.random2f(0.5, 1.0) => kick.bass;
        if (beat % 2) {
            Math.random2f(0.6, 0.9) => kick.strike;
        } else if (Math.random2f(0,1) < 0.1) {
            Math.random2f(0.2, 0.4) => kick.strike;
        } else {
            0.0 => kick.strike;
        }
        kickbeat - skew => now; 
        (beat + 1) % 4 => beat;
    }
}

// Hi-hat player, similarly simple
// This is the kick player

fun void play_wav(SndBuf buf, int sample, int hits[], dur basis, dur runtime) {
    0 => int seq;
    0 => int beat;
    dur skew; 
    now + runtime => time endtime; 
    
    wave_table[sample] => buf.read;
    buf.samples() => buf.pos;

    while (now < endtime) {  
        Math.random2f(0.0, basis/ms * 1/32)::ms => skew; 
        skew => now;
       
        if (1 == hits[beat] || 2 == hits[beat]) {
            1 => buf.pos;     
            Math.random2f(0.75, 1.0) => buf.gain;
            
            if (Math.random2f(0,1) < 0.2 && 2 == hits[beat]) {
               basis - basis * Math.random2f(0.45, 0.55) => dur dubby;
               dubby => now; 
               1 => buf.pos;
               Math.random2f(0.75, 1.0) => buf.gain;
               dubby +=> skew;
            }
        } else if (3 == hits[beat] && Math.random2f(0,1) < 0.2) {
            1 => buf.pos;     
            Math.random2f(0.3, 0.6) => buf.gain;
        } 
        basis - skew => now;         
        (beat + 1) % 8 => beat;
    }
}

// This is the bongo player
fun void bingo_bango(dur bongobeat, dur runtime) {
    0 => int beat;
    dur skew;
    now + runtime => time endtime; 

    while (now < endtime) {
        Math.random2f(0.6, 1.0) => bongo.bongo;
        Math.random2f(10.0, 25.0)::ms => skew;
        skew => now; 
       
        if (0 == beat % 2) {
            Math.random2f(0.6, 1.0) => bongo.strike;
        } else if (Math.random2f(0,1) < 0.1) {
            Math.random2f(0.2, 0.5) => bongo.strike;
        } else {
            0 => bongo.strike;
        }
                   
        bongobeat - skew => now; 
        
        ++beat;
    }
}
                
// Launch the drums

// The HiHat
[ 1, 3, 2, 2, 1, 3, 2, 3 ] @=> int hathits[];

// The Snare
[ 3, 2, 3, 2, 3, 2, 3, 2 ] @=> int snarehits1[];
[ 1, 3, 2, 3, 1, 3, 2, 3 ] @=> int sharehits2[];

// Click
[ 1, 2, 2, 3, 2, 2, 2, 3 ] @=> int clickhits[];

spork ~ kick_me(Comp.section("part1"));
spork ~ play_wav(hihat,HIHAT_01,hathits,BPM.eighthNote, Comp.section("part1"));
spork ~ play_wav(snare,SNARE_01,snarehits1,BPM.eighthNote, Comp.section("part1"));

// Play for part 1.
Comp.section("part1") => now; 

spork ~ bingo_bango(BPM.quarterNote,Comp.section("bridge"));
spork ~ play_wav(snare,SNARE_02,sharehits2,BPM.eighthNote,Comp.section("bridge"));
Comp.section("bridge") => now;


spork ~ kick_me(Comp.section("part1"));
spork ~ play_wav(hihat,HIHAT_01,hathits,BPM.eighthNote, Comp.section("part2"));
spork ~ play_wav(snare,SNARE_01,snarehits1,BPM.eighthNote, Comp.section("part2"));
Comp.section("part2") => now;

0.1 => snare_pan.gain;
spork ~ play_wav(snare,CLICK_01,clickhits, BPM.eighthNote, Comp.section("coda"));
Comp.section("coda") => now;

    