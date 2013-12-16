// File   : handdrum.ck
// Class  : Introduction to Programming for Musicians and Digital Artists
// Program: Assignment 7: Dogs and Mice
// Date   : 2013-Dec-07
// Note   : PLEASE KEEP IF YOU FIND IT USEFUL
// ===========================================================================
// INSTRUMENT: Log Drum.. something for the low end... what rolls down stairs
// alone or in pairs, rolls over your neighbors dog. It's great for a snack,
// it fits on your back, it's log, Log, LOG!

DrumKit log    => Pan2 log_pan => Pan2 master => Mixdac.in;
DrumKit bongo1 => Pan2 bongo_pan1 => master;
DrumKit bongo2 => Pan2 bongo_pan2 => master;

1.0 => master.gain; 

// Settinsg for log and bongos
0.3    => log_pan.pan;
2.0    => log_pan.gain;

-0.5 => bongo_pan1.pan;
 1.0 => bongo_pan1.gain;
-0.2 => bongo_pan2.pan;
 1.0 => bongo_pan2.gain;

// Thread control

0 => int poison_pill;

// Bongo data

[ 100, 100,  50,  50, 100,      100,  50,  50, 100, 100,     100, 100,  50,  50, 100,     100,  50,  50, 100, 100 ] @=> int   bongo_beats[];
[ 0.4, 1.0, 0.5, 0.0, 1.0,      0.5, 1.0, 0.4, 1.0, 0.3,     0.5, 1.0, 0.0, 0.5, 0.0,     0.5, 0.7, 0.0, 0.4, 0.8 ] @=> float bongo_hit1[];
[ 0.7, 0.3, 0.0, 0.7, 1.0,      0.7, 0.4, 0.1, 0.0, 1.0,     1.0, 0.4, 1.0, 0.0, 0.7,     0.7, 0.0, 1.0, 0.8, 0.4 ] @=> float bongo_hit2[];

// This is the log player function. 
fun void play_log(float vol) {
    BPM.quarterNote  => dur logbeat;
    float tweak; 
    int prog;
    0 => int beat;
    
    while (!poison_pill) {     
        Math.random2f(0,0.5) => tweak;
        Math.random2(0,2)    => prog;
        
        if (0 == beat || 0 == prog) {
            tweak => log.log;
            Math.random2f(0.8, 1.0) => log.strike;    
            2 * logbeat => now; 
        } else if (1 == prog) {
            tweak => log.log;
            Math.random2f(0.4, 0.7) => log.strike;    
            logbeat => now;
            tweak + Math.random2f(0,0.4) => log.log;
            Math.random2f(0.5, 0.6) => log.strike;
            logbeat => now;
        } else {
            tweak => log.log;
            Math.random2f(0.4, 0.6) => log.strike;
            BPM.triplet(logbeat) => now;
            tweak + Math.random2f(0,0.2) => log.log;
            Math.random2f(0.6, 0.8) => log.strike;
            BPM.triplet(logbeat) => now;
            tweak + Math.random2f(0,0.3) => log.log;
            Math.random2f(0.7, 1.0) => log.strike;
            BPM.triplet(logbeat) => now;
        }
        
        (beat + 1) % 4 => beat;
    }    
}

// This is the bongo player
fun void bingo_bango(int beats[], float hit1[], float hit2[]) {
    BPM.eighthNote => dur bongobeat;
    0 => int seq;

    while (!poison_pill) {
        Math.random2f(0,   0.3) => bongo1.bongo;
        Math.random2f(0.6, 1.0) => bongo2.bongo;
        hit1[seq] => bongo1.strike;
        hit2[seq] => bongo2.strike;
        
        beats[seq]/100.0 * bongobeat => now; 
        
        (seq + 1) % beats.cap() => seq;
    }
}
                
// Launch the log drum
spork ~ play_log(1.0);
spork ~ bingo_bango(bongo_beats, bongo_hit1, bongo_hit2);

// Play for part 1.
Comp.section("part1") => now; 
1 => poison_pill;
Comp.section("bridge") => now;
0 => poison_pill;

spork ~ bingo_bango(bongo_beats, bongo_hit1, bongo_hit2);
8 * BPM.quarterNote => now; 
spork ~ play_log(1.0);
Comp.section("part2") - 8 * BPM.quarterNote => now;
1 => poison_pill; 

    