// File:    guitar_part.ck
// Class:   Introduction to Programming for Musicians and Digital Artists
// Program: Assignment 8: A Chase Would Be Nice
// Date:    2013-Dec-15
// Note:    PLEASE KEEP IF YOU FIND IT USEFUL
// ===========================================================================
// INSTRUMENT: Guitar Part1

// The main guitar chain
Guitar gtr => NRev rvb => Pan2 pan => Mixdac.in;
ModBass bass => NRev bass_rvb => Pan2 bass_pan => Mixdac.in; 

-1 => int x; 
-1 => int RST;

// Some guitar parameters to adjust
5 => gtr.gain;
gtr.tuningStandard();
20::ms => gtr.delay;
0.85 => gtr.balance;

// Set a little reverb, position the soundfield
0.03 => rvb.mix;
0.4  => pan.pan;
0.04 => bass_rvb.mix;
0.3  => bass_pan.pan;
0.8  => bass_pan.gain;

// Volume automation for the guitar
class gtr_fader extends Automate {
    fun float adj(float s) {
       return (s => pan.gain);
    }
    fun float adj() {
        return pan.gain();
    }
}

// Fade in and out. 
0.0 => pan.gain; 

gtr_fader gf;
5::ms => gf.resolution;
[0::ms, Comp.section("intro") - 1500::ms, 0::ms, Comp.section("part1") + Comp.section("bridge") + Comp.section("part2") + Comp.section("coda") - 1100::ms]  => gf.times;
[500::ms, 1000::ms, 100::ms, 1000::ms]   => gf.fades;
[1.0,     0.3,      1.0,     0.0 ]       => gf.levels;
1     => gf.enable;

// ===============================================================================================
// This is the bass player. Pretty simple, nearly all the good stuff happens in the
// Guitar class itself. 
fun void play_bass(int notes[], int beats[], float hit[], dur bassbeat, dur runtime) {
    0 => int seq;
    dur note_play;
    dur note_mute;
    dur note_dur;
    now + runtime => time endtime;

    while (now < endtime) {
        beats[seq]/100.0 * bassbeat => note_dur;
        note_dur / 4 => note_mute;
        note_mute => note_play; 
        
        if (RST != notes[seq]) { 
            Math.mtof(notes[seq]) => bass.freq;
            hit[seq] => bass.noteOn;
        } else {
            hit[seq] => bass.noteOff;
        }
        note_play => now;
        1 => bass.noteOff;
        note_mute => now;
        hit[seq] => bass.noteOn;
        note_play => now; 
        1 => bass.noteOff;
        note_mute => now;  
        
        (seq + 1) % beats.cap() => seq;
    }
}

// ===============================================================================================
// This is the guitar player. Pretty simple, nearly all the good stuff happens in the
// Guitar class itself. 
fun void play_guitar(string chords[], int beats[], float hit[], dur arp[], dur gtrbeat, dur runtime) {
    0 => int seq;
    20::ms => dur mute;
    now + runtime => time endtime;

    while (now < endtime) {
        if ("RST" != chords[seq]) { 
            chords[seq] => ChordBook.get_fingering => gtr.chord;
            
            Math.max((arp[seq] - mute)/ms, 0)::ms => gtr.arpeggio;
            hit[seq] => gtr.noteOn;
        } else {
            hit[seq] => gtr.noteOff;
        }
        (beats[seq]/100.0 * gtrbeat) - mute => now;
        hit[seq] => gtr.noteOff;
        mute => now;
        
        (seq + 1) % beats.cap() => seq;
    }
}


// ======================================================================================
// Composition notes
Comp.notes() @=> int notes[];
2 => int octave;

// Easy access notes
notes["G"] -  12 => int G;    notes["A"] - 12 => int A;    notes["B"] - 12 => int B; 
notes["C"] -  12 => int C;    notes["D"] - 12 => int D;    notes["E"] - 12 => int E;
notes["F#"] - 12 => int Fs;

// ======================================================================================
// Section data

// INTRO
// Play the intro; this is slow, the basis is a 1/2 note, but with arpeggios and a few
// 1/4 notes tossed in. 

BPM.quarterNote * 2 => dur ibeat; 
ibeat * 0.95        => dur iarp;
0::ms               => dur noarp;

[   "G",   "3.G",  "Cmaj",    "D",      "G",    "G",  "Em", "1.C",    "D7",   "2.G"   ] @=> string intro_chords[];
[   100,     100,    100,     100,       50,     50,   100,   100,    100,      400   ] @=> int intro_beats[];
[   0.5,     0.7,   -0.5,     0.7,      0.5,   -0.5,   0.7,  -0.5,    0.4,      0.4   ] @=> float intro_hit[]; 
[ noarp,    iarp,  noarp,    iarp,    noarp,  noarp, noarp,  iarp,  noarp,     iarp   ] @=> dur intro_arp[];

100::ms => gtr.delay;
spork ~ play_guitar(intro_chords, intro_beats, intro_hit, intro_arp, ibeat, Comp.section("intro"));
Comp.section("intro") => now; 

// PART 1
// Play the main part 1 

BPM.quarterNote     => dur pbeat; 

[   "G",   "2.G",    "C",     "D",        "2.G",    "G",  "Em",   "C",   "D7",    "Am",   "D7",  "Am",  "D7",   "D7",  "G7",  "G7",     "G", "2.G",  "2.C", "1.D"  ] @=> string part1_chords[];
[   100,     100,    100,     100,           50,     50,   100,   100,    100,     100,     50,    50,    50,     50,    50,    50,     100,   100,    100,    100 ] @=> int part1_beats[];
[   0.9,     0.5,   -0.9,     0.7,          0.9,   -0.5,   0.5,  -0.9,    0.6,     0.9,    0.6,  -0.7,   0.8,   -0.9,   0.6,  -0.5,     0.6,  -0.8,    0.7,   -0.9 ] @=> float part1_hit[]; 
[ noarp,    noarp,  noarp,   noarp,       noarp,  noarp, noarp, noarp,  noarp,   noarp,  noarp, noarp, noarp,  noarp, noarp, noarp,   noarp, noarp,  noarp, noarp  ] @=> dur part1_arp[];

[   G,   E,   C,   E,      G,   B,   E,   D,      A,   D,   C,   D,     G,   D,   C,   D ] @=> int bass_pt1_notes[];
[ 100, 100, 100, 100,    100, 100, 100, 100,    100, 100, 100, 100,   100, 100, 100, 100 ] @=> int bass_pt1_beats[];
[ 1.0, 0.5, 1.0, 0.5,    1.0, 0.5, 1.0, 0.5,    1.0, 0.5, 1.0, 0.5,   1.0, 0.5, 1.0, 0.5 ] @=>  float bass_pt1_hit[];

20::ms => gtr.delay;
spork ~ play_guitar(part1_chords, part1_beats, part1_hit, part1_arp, pbeat, Comp.section("part1"));
spork ~ play_bass(bass_pt1_notes, bass_pt1_beats, bass_pt1_hit, pbeat, Comp.section("part1"));
Comp.section("part1") => now; 

// BRIDGE
pbeat * 0.95  => dur barp;

[ "2.G",   "3.G",  "Cmaj",  "2.D",      "G",  "2.G",  "Em", "1.C",    "D7" ] @=> string bridge_chords[];
[   100,     100,    100,     100,       50,     50,   100,   100,    100  ] @=> int bridge_beats[];
[   0.5,     0.7,   -0.5,     0.7,      0.5,   -0.5,   0.7,  -0.5,    0.4  ] @=> float bridge_hit[]; 
[ noarp,    barp,  noarp,    barp,    noarp,  noarp, noarp,  barp,  noarp  ] @=> dur bridge_arp[];

15::ms => gtr.delay;
spork ~ play_guitar(bridge_chords, bridge_beats, bridge_hit, bridge_arp, pbeat, Comp.section("bridge"));
Comp.section("bridge") => now; 

// PART 2 
[ "1.G",   "2.G",  "2.C",   "2.D",        "2.G",  "3.G",  "2.Em", "1.C", "1.D7",  "2.Am",   "D7", "2.Am",  "1.D7",   "2.D7",  "2.G7",  "3.G7",   "1.G", "2.G",  "2.C", "1.D"  ] @=> string part2_chords[];
[   100,     100,    100,     100,           50,     50,     100,   100,    100,     100,     50,     50,      50,       50,      50,      50,     100,   100,    100,    100 ] @=> int part2_beats[];
[   0.9,     0.5,   -0.9,     0.7,          0.9,   -0.5,     0.5,  -0.9,    0.6,     0.9,    0.6,   -0.7,     0.8,     -0.9,     0.6,    -0.5,     0.6,  -0.8,    0.7,   -0.9 ] @=> float part2_hit[]; 
[ noarp,    noarp,  noarp,   noarp,       noarp,  noarp,   noarp, noarp,  noarp,   noarp,  noarp,  noarp,   noarp,    noarp,   noarp,   noarp,   noarp, noarp,  noarp, noarp  ] @=> dur part2_arp[];

20::ms => gtr.delay;
spork ~ play_guitar(part2_chords, part2_beats, part2_hit, part2_arp, pbeat, Comp.section("part2"));
spork ~ play_bass(bass_pt1_notes, bass_pt1_beats, bass_pt1_hit, pbeat, Comp.section("part2"));
Comp.section("part2") => now; 

// CODA
[   "G", "Cmaj",     "D", "RST"   ] @=> string coda_chords[];
[   100,    100,     100,   400   ] @=> int coda_beats[];
[   0.5,   -0.5,     0.7,   0.0   ] @=> float coda_hit[]; 
[  iarp,   noarp,    iarp, noarp  ] @=> dur coda_arp[];

100::ms => gtr.delay;
spork ~ play_guitar(coda_chords, coda_beats, coda_hit, coda_arp, ibeat, Comp.section("coda"));
Comp.section("coda") => now; 
