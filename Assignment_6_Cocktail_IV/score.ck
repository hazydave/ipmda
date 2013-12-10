// File:    score.ck
// Class:   Introduction to Programming for Musicians and Digital Artists
// Program: Assignment 6: Cocktail I.V.
// Date:    2013-28-21
// Note:    PLEASE KEEP IF YOU FIND IT USEFUL

// ===========================================================================
// SONG NAVIGATION CONSTANTS
// The song is defined to be 30 seconds with 0.625 second per quarter note, so 48 quarter notes, 
// 11 measures in 4/4 time. So the structure is:
// Intro :  4 quarter notes
// Part 1: 16 quarter notes
// Solo  :  8 quarter notes
// Part 2: 16 quarter notes
// Coda  :  4 quarter notes

0.625      => float time_quarter_note_sec;
4          => int   time_qnote_per_measure; 
4          => int   time_slices_per_qnote;

now => time time_start;

time_quarter_note_sec::second => dur time_quarter_note;
time_quarter_note/2           => dur time_eighth_note;
time_eighth_note/2            => dur time_sixteenth_note;

time_quarter_note *  4 => dur time_intro;
time_quarter_note * 16 => dur time_part1;
time_quarter_note *  8 => dur time_solo;
time_quarter_note * 16 => dur time_part2;
time_quarter_note *  4 => dur time_coda;

time_slices_per_qnote * 4                     => int slices_at_part1;
time_slices_per_qnote * 16 + slices_at_part1  => int slices_at_solo;
time_slices_per_qnote * 4  + slices_at_solo   => int slices_at_part2;
time_slices_per_qnote * 16 + slices_at_part2  => int slices_at_coda;

// ===========================================================================
// MUSIC SECTION

<<< "Assignment 6: ", "Cocktail I.V." >>>;

// Add the drum kit
Machine.add(me.dir() + "/drums.ck") => int drumID;

// Play the intro
<<< "Playing: ", "Intro" >>>;
time_intro => now;

// Add the bass
Machine.add(me.dir() + "/bass.ck") => int bassID;
// And the horns
Machine.add(me.dir() + "/clarinet.ck") => int clarinetID;

// Play the main tune
<<< "Playing: ", "Part 1" >>>;
time_part1 => now;

<<< "Playing: ", "Solo" >>>;
time_solo => now;

<<< "Playing: ", "Part 2" >>>;
time_part2 => now; 

// Remove some stuff for the coda.
Machine.remove(clarinetID);

// Play the coda
<<< "Playing: ", "Coda" >>>;
time_coda => now;

<<< "Time: ", (now - time_start)/second, " seconds." >>>;

