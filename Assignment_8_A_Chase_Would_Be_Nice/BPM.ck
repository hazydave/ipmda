// ================================================================================
// PUBLIC CLASS: BPM
// Class:        Introduction to Programming for Musicians and Digital Artists
// Program:      Assignment 8: A Chase Would Be Nice
// Date:         2013-Dec-06
// Dependencies: NONE
// ================================================================================
// This is a slightly modified version of the BPM class presented in, er, 
// class. While I am using this to meet a requirement of the rubik ("Your two
// class files should include one from the lectures...", this is actually a great
// use of public classes. I've rewritten this to be a static-only class, so there's
// no need to create objects... it just works. Like "Math" or "Std", etc. 

public class BPM {
    // global variables
    static dur myDuration[];
    static dur quarterNote, eighthNote, sixteenthNote, thirtysecondNote;
    
    fun static dur dotted(dur note) {
        return 1.5 * note;
    }
    fun static dur triplet(dur note) {
        return 2/3 * note;
    }
    
    // Set the tempo. Argument "beat" is BPM, example 120 beats per minute
    fun static float tempo(float beat)  {
        60.0/(beat) => float SPB; // seconds per beat
        
        SPB :: second       => quarterNote;
        quarterNote   * 0.5 => eighthNote;
        eighthNote    * 0.5 => sixteenthNote;
        sixteenthNote * 0.5 => thirtysecondNote;
        
        // store data in array that actually works
        [quarterNote, eighthNote, sixteenthNote, thirtysecondNote] @=> myDuration;
        
        return 60.0 / (quarterNote/second);
    }
    
    // Read back the tempo
    fun static float tempo() {
        return 60.0 / (quarterNote/second);
    }
    
    // Set the tempo using the value of a quarter note
    fun static dur tempoQN(dur qnote) {
        tempo(60.0 / (qnote/second));
        return quarterNote;
    }
    
    // Return the tempo as a quarter note duration (just to be complete)
    fun static dur tempoQN() {
        return quarterNote;
    }
}
/*
// Test code

BPM bpm;

96.0 => bpm.tempo;

<<< "BPM 96: quarterNote=",BPM.quarterNote/second,"sec, BPM =", BPM.tempo() >>>;

0.625::second => bpm.tempoQN;

<<< "BPM 0.625: quarterNote=",BPM.quarterNote/second,"sec, BPM =", BPM.tempo() >>>;

*/