// File   : sticks.ck
// Class  : Introduction to Programming for Musicians and Digital Artists
// Program: Assignment 7: Dogs and Mice
// Date   : 2013-Dec-07
// Note   : PLEASE KEEP IF YOU FIND IT USEFUL

// ===========================================================================
// INSTRUMENT: Sticks... Antmusic Lives! Feeble attempt at a Burundi beat here.

DrumKit stick1 => NRev stick1_rvb => Pan2 stick1_pan => Pan2 master => Mixdac.in;
DrumKit stick2 => NRev stick2_rvb => Pan2 stick2_pan => master;

0.03 => stick1_rvb.mix;  2.0 => stick1.gain;  0.5 => stick1_pan.pan;
0.03 => stick2_rvb.mix;  2.0 => stick2.gain;  0.6 => stick2_pan.pan;

stick1.stick(0.2);
stick2.stick(0.8);

// Automation for stock panning. Make a subclass of the public Automate
// class to control a "slider" of your choice. Here, I'm moving master volume. 

class Stickpanner extends Automate {
    fun float adj(float f) {
        f => stick1_pan.pan;
        f + 0.1 => stick2_pan.pan;
       return stick1_pan.pan();
    }
    fun float adj() {
       return stick1_pan.pan();
    }
}

Stickpanner stick_auto;
[0::second]               => stick_auto.times;
[Comp.section("intro")]   => stick_auto.fades;
[-0.5]                    => stick_auto.levels;
1                         => stick_auto.enable;


// This adds a couple kinds of controlled randomness to a double-stick hit. It returns
// the time used in that, which is in theory always the same as beat. 
fun dur random_double_stick(float range, float vol2, float vol1, dur beat, dur intvl) {
    Math.random2f(0.0,range)::ms => dur flop1; 
    Math.random2f(0.5,range)::ms => dur flop2;
    flop1 => now;
    Math.random2f(vol2*0.7, vol2) => stick2.strike; 
    intvl + flop2 => now; 
    Math.random2f(vol1*0.7, vol1) => stick1.strike;
    beat - intvl - flop1 - flop2 => now; 
    return beat;
}

// This is the main stick player function. 
fun dur play_burundi(float vol, dur beat) {
    beat                => dur burbeat; 
    burbeat * 3.0/11.0  => dur dblbeat;
    burbeat - dblbeat   => dur dblrest;    
    
    0::ms => dur loop;
    vol => master.gain;
            
    repeat (4) {
        random_double_stick(20, 0.5, 0.6, burbeat, dblbeat) +=> loop;
    }

    random_double_stick(10, 0.4, 0.8, dblbeat, dblbeat/20.0) +=> loop;
    random_double_stick(20, 0.6, 0.9, dblrest + 1.5 * burbeat, 0::ms) +=> loop;
        

    random_double_stick(20, 0.4, 0.8, dblbeat * 0.5, 0::ms) +=> loop;
    random_double_stick(20, 0.6, 0.9, dblbeat * 1.5, 0::ms) +=> loop;

    random_double_stick(20, 0.4, 0.8, dblbeat * 0.5, 0::ms) +=> loop;
    random_double_stick(20, 0.6, 0.9, dblrest, 0::ms) +=> loop;
       
    burbeat * 8 - loop => now;
    return burbeat * 8;    
}

// This is the simple stick player
fun void hit_me_with_your_rhythm_stick(int beats[], float hit1[], float hit2[], dur playtime) {
    BPM.eighthNote => dur stickobeato;
    0 => int seq;
    dur hitme; 

    while (0::ms < playtime) {
        Math.random2f(0,   0.3) => stick1.stick;
        Math.random2f(0.6, 1.0) => stick2.stick;
        hit1[seq] => stick1.strike;
        hit2[seq] => stick2.strike;
        
        beats[seq]/100.0 * stickobeato => hitme;
        hitme => now; 
        hitme -=> playtime;       
        (seq + 1) % beats.cap() => seq;
    }
}
        
// Play at intro
0.50 => stick1_pan.pan;
0.40 => stick2_pan.pan;
play_burundi(0.8, BPM.eighthNote) => dur btime;

// Play at Bridge
0.50 => stick1_pan.pan;
0.40 => stick2_pan.pan;
Comp.section("intro") + Comp.section("part1") - btime => now;
play_burundi(0.5, BPM.quarterNote);

// Play at Coda
[ 100, 100,  50,  50, 100,      100,  50,  50, 100, 100 ] @=> int   stick_beats[];
[ 0.4, 1.0, 0.5, 0.0, 1.0,      0.5, 1.0, 0.4, 1.0, 0.3 ] @=> float stick_hit1[];
[ 0.7, 0.3, 0.0, 0.7, 1.0,      0.7, 0.4, 0.1, 0.0, 1.0 ] @=> float stick_hit2[];
Comp.section("part2") => now; 
// Play at coda
hit_me_with_your_rhythm_stick(stick_beats, stick_hit1, stick_hit2, Comp.section("coda"));
  
    
    