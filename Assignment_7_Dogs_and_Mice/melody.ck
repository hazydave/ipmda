// File   : melody.ck
// Class  : Introduction to Programming for Musicians and Digital Artists
// Program: Assignment 7: Dogs and Mice
// Date   : 2013-Dec-07
// Note   : PLEASE KEEP IF YOU FIND IT USEFUL

// ===========================================================================
// INSTRUMENT: Marimba... or is it a Xylophone?  

Marimba mb => Pan2 mb_pan => Pan2 master => Mixdac.in;

 1.5  => master.gain; 
-0.5  => mb_pan.pan;

0 => int RST;

0 => int poison_pill;

// This is the marimba player
fun void play_marimba(int notes[], int octave, int beats[], float hit[]) {
    BPM.eighthNote => dur marimbabeat;
    0 => int seq;

    while (!poison_pill) {
        if (RST != notes[seq]) { 
            Math.mtof(notes[seq]+12*octave) => mb.freq;
            hit[seq] => mb.strike;
        }
        beats[seq]/100.0 * marimbabeat => now; 
        (seq + 1) % beats.cap() => seq;
    }
}

// Launch the marimba

Comp.notes() @=> int notes[];
2 => int octave;

// Easy access notes

notes["C"] => int C;    notes["D"] => int D;    notes["E"]  => int E;    notes["F"] => int F;
notes["G"] => int G;    notes["A"] => int A;    notes["B"]  => int B; 

// Note tables

[   C,   C,   D,   G,   E,   F,   C,        C,   C,   D,   E,   F,   G,      C,   C,    F,   D,   F,        C,   G,   D,   G,   F,   E,   D,    C ] @=> int   mb_notes[]; 
[ 100,  25,  25,  25,  25, 100, 100,      100,  50,  25,  25, 100, 100,     100, 100,  50,  50, 100,      100,  50,  50,  25,  25,  25,  25,  100 ] @=> int   mb_beats[];
[ 0.4, 1.0, 0.8, 0.6, 0.4, 1.0, 1.0,      0.5, 1.0, 0.5, 0.7, 1.0, 0.3,     0.5, 1.0, 0.7, 0.5, 0.0,      0.5, 0.7, 0.7, 0.4, 0.5, 0.6, 0.7,  0.8 ] @=> float mb_hit[];

// Play the melody for part 1
spork ~ play_marimba(mb_notes, 1, mb_beats, mb_hit);
// Chuck to the bridge
(Comp.section("intro") + Comp.section("part1")) - (now - Comp.start()) => now; 
1 => poison_pill;

// Chuck to part 2.
Comp.section("bridge") => now;
0 => poison_pill;
spork ~ play_marimba(mb_notes, 2, mb_beats, mb_hit);
Comp.section("part2") => now; 
1 => poison_pill;

// Wait 'till it's over
//Comp.section("total") => now; 
    