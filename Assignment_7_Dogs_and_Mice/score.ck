// File        : score.ck
// Class       : Introduction to Programming for Musicians and Digital Artists
// Program     : Assignment 7: Dogs and Mice
// Date        : 2013-Dec-08
// Note        : PLEASE KEEP IF YOU FIND IT USEFUL
// Dependencies: IFB Mixdac BPM Comp 
// ================================================================================
// MASTER MIXING BUS
// This is for master volume control and level metering. Mixdac combines a final
// mixdown bus with the dac in one global object. 
1   => Mixdac.init;
0.5 => Mixdac.gain;     // VolAuto object is going to set this, see below. 
0.2 => float mix_max;   // Master mixer, peak value. 
1   => Mixdac.agc;      // Keep everhting quiet
0   => Mixdac.meter;    // Not really needed

// ===========================================================================
// SONG COMPOSITION CONSTANTS
// The song is defined to be 30 seconds with 0.625 second per quarter note, so 48 quarter notes, 
// 11 measures in 4/4 time. So the structure is:
// Intro :  4 quarter notes
// Part 1: 16 quarter notes
// Solo  :  8 quarter notes
// Part 2: 16 quarter notes
// Coda  :  4 quarter notes

//Set global time (My BPM class takes either qnote time or bpm).
0.625::second => BPM.tempoQN;  

// Other useful compositional timing in the Comp class
[  48,  50,  52,  53,  55,  57,  59 ] => Comp.notes;   // Scale for this project
[ "C", "D", "E", "F", "G", "A", "B" ] => Comp.names;   // Enhance with string names
[      4,      16,        8,      16,     4 ] => Comp.sectionLengths; // Notes per musical section
["intro", "part1", "bridge", "part2", "coda"] => Comp.sectionNames;   // Text names of different sections
now                                           => Comp.start;          // When did this start playing?

// Automation for master volume control. Make a subclass of the public Automate
// class to control a "slider" of your choice. Here, I'm moving master volume. 

class Masterauto extends Automate {
    fun float adj(float f) {
       return (f => Mixdac.gain);
    }
    fun float adj() {
       return Mixdac.gain();
    }
}

Masterauto master_auto;
[0::second,   Comp.section("total") - 0.5::second] => master_auto.times;
[2.0::second, 0.5::second]                         => master_auto.fades;
[mix_max,    0.0]                                  => master_auto.levels;
1                                                  => master_auto.enable;

// ===========================================================================
// MUSIC SECTION

<<< "Assignment 7: ", "Dogs and Mice" >>>;

// Instruments for intro
Machine.add(me.dir() + "/sticks.ck")    => int stickID;
Machine.add(me.dir() + "/sugar.ck")     => int sugarID;
Machine.add(me.dir() + "/theshakes.ck") => int shakeyID;
// Play the intro
Comp.timeReport("Playing: Intro");
Comp.section("intro") => now;

// Intruments for part 1
Machine.add(me.dir() + "/handdrum.ck") => int handdrumID;
// Play part 1
Comp.timeReport("Playing: Part 1:");
4 * BPM.quarterNote => now;

// Next Instrument for part 1
Machine.add(me.dir() + "/melody.ck") => int melodyID;
Comp.section("part1") - 4 * BPM.quarterNote => now;

Comp.timeReport("Playing: Bridge:");
Comp.section("bridge") => now;

Comp.timeReport("Playing: Part 2:");
Comp.section("part2") => now; 

// Play the coda
Comp.timeReport("Playing: Coda  :");
Comp.section("coda") => now;

// Finished playing
Comp.timeReport("Elapsed time:");
Mixdac.meterReport();



