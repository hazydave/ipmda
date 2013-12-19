// File:    theshakes.ck
// Class:   Introduction to Programming for Musicians and Digital Artists
// Program: Assignment 7: Dogs and Mice
// Date:    2013-Dec-07
// Note:    PLEASE KEEP IF YOU FIND IT USEFUL
// ===========================================================================
// INSTRUMENT: Shakin' things up!


Shakers casaba => Pan2 casaba_pan => Pan2 master => Mixdac.in;
Shakers wd     => Pan2 wd_pan     => master;
Shakers tam    => Pan2 tam_pan    => master;

1.0  => master.gain; 

// Settinsg for log and bongos
0.0  => casaba_pan.pan;
1.0  => casaba_pan.gain;
2    => casaba.preset;

-0.5 => wd_pan.pan;
4    => wd.preset;

0.2 => tam_pan.pan;
6   => tam.preset;

999.9 => float RST;

// Thread control

// Bongo data

[ 100, 100,  50,  50, 100,      100,  50,  50, 100, 100,     100, 100,  50,  50, 100,     100,  50,  50, 100, 100 ] @=> int   shake_beats1[];
[ 0.4, 0.8, 0.5, 1.0, 0.3,      0.5, 0.8, 0.4, 0.4, 0.3,     0.5, 0.7, 1.0, 0.5, 0.0,     0.5, 0.7, 1.0, 0.4, 0.8 ] @=> float shake_hit1[];
[ 0.7, RST, 0.3, RST, RST,      0.7, RST, 0.0, 0.7, RST,     0.9, RST, 0.3, 0.2, RST,     0.6, RST, 0.7, RST, 1.0 ] @=> float shake_hit2[];

// This is the bongo player
fun void shake_and_bake(Shakers shk, dur tempo, int beats[], float hit[], dur playtime) {
    tempo => dur shakeybeat;
    0 => int seq;
    dur shakt;

    while (0::ms < playtime) {
        if (hit[seq] != RST) {
            hit[seq] => shk.energy;
        
            beats[seq]/100.0 * shakeybeat => shakt;
            1 => shk.noteOn;
        }
        shakt => now; 
        shakt -=> playtime;
        
        (seq + 1) % beats.cap() => seq;
    }
}
                
// Launch the shakers drum

Comp.section("intro") => now; 

// Play for part 1.

spork ~ shake_and_bake(casaba, BPM.quarterNote, shake_beats1, shake_hit2, Comp.section("part1"));
Comp.section("part1") => now; 

spork ~ shake_and_bake(wd, BPM.eighthNote, shake_beats1, shake_hit2, Comp.section("bridge"));
Comp.section("bridge") => now;

spork ~ shake_and_bake(casaba, BPM.quarterNote, shake_beats1, shake_hit2, Comp.section("part2"));
spork ~ shake_and_bake(tam, BPM.quarterNote, shake_beats1, shake_hit1, Comp.section("part2"));
Comp.section("part2") => now;

    