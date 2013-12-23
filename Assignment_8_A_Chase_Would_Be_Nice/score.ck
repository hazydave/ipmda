// File        : score.ck
// Class       : Introduction to Programming for Musicians and Digital Artists
// Program     : Assignment 8: A Chase Would Be Nice
// Date        : 2013-Dec-08
// Note        : PLEASE KEEP IF YOU FIND IT USEFUL
// Dependencies: IFB Mixdac BPM Comp 
// ================================================================================
// MASTER MIXING BUS
// This is for master volume control and level metering. Mixdac combines a final
// mixdown bus with the dac in one global object. 
1    => Mixdac.init;
0.75 => Mixdac.gain;       
1    => Mixdac.agc;
1    => Mixdac.meter;
//0    => Mixdac.log;

// ===========================================================================
// SONG COMPOSITION CONSTANTS
// The song is defined to be 60 seconds at 120bpm. The structure 
// defined in the composition class below. 

//Set global time (My BPM class takes either qnote time or bpm).
120 => float BEAT => BPM.tempo;  

// Other useful compositional timing in the Comp class
[  43,  45,  47,  48,  50,  52,  53 ] @=> int MELODY[] => Comp.notes;          // MELODY Scale for this project
[ "G", "A", "B", "C", "D", "E", "F#" ]                 => Comp.names;          // Enhance with string names
[     20,     36,        20,      36,     8 ]          => Comp.sectionLengths; // Notes per musical section
["intro", "part1", "bridge", "part2", "coda"]          => Comp.sectionNames;   // Text names of different sections
now                                                    => Comp.start;          // When did this start playing?

// ===========================================================================
// MUSIC SECTION

<<< "Assignment 8: ", "A Chase Would Be Nice" >>>;

// Instruments for intro

// Machine.add(me.dir()+"/lead.ck") => int leadID;
// Play the intro

Machine.add(me.dir() + "/guitar_part.ck") => int gtrID;
Comp.timeReport("Playing: Intro");
Comp.section("intro") => now;

// Intro cleanup

// Intruments for part 1
Machine.add(me.dir() + "/drum_part.ck") => int drumID;

// Play part 1
Comp.timeReport("Playing: Part 1:");
Comp.section("part1") => now;

Comp.timeReport("Playing: Bridge:");
Comp.section("bridge") => now;

Comp.timeReport("Playing: Part 2:");
Comp.section("part2") => now; 

// Play the coda
Comp.timeReport("Playing: Coda  :");
Comp.section("coda") => now;

// Anything to clean up

// Finished playing
Comp.timeReport("Elapsed time:");
Mixdac.meterReport();




