// ================================================================================
// PUBLIC CLASS: Comp
// Class:        Introduction to Programming for Musicians and Digital Artists
// Program:      Assignment 7: Dogs and Mice
// Date:         2013-Dec-06
// Dependencies: BPM
// ================================================================================
// This class is designed to centralize components of the a compostion. The class
// is pure static, no need to create instances. This records the composition's
// notes, the compositional sections (right now, pretty much hard-wired to the
// 30-second time frame, but easy enough to adjust for other song structures), 
// and the stating time of the playback. It can also prettyprint a timing report
// when finished. 

public class Comp {
    // global variables
    static int    notesInKey[];
    static string namesInKey[];
    static int    notesPerSec[];
    static string namesPerSec[];
    static dur    durPerSec[];
    static time   start_time;
    static dur    quarterNote;
       
    // Reset the composition from the linked BPM
    fun static void tempoChange() {
        if (BPM.quarterNote != quarterNote) {
            0::ms => dur totalDur;
            
            BPM.quarterNote => quarterNote;
            new dur[notesPerSec.cap()+1] @=> durPerSec;
        
            for (0 => int i; i < notesPerSec.cap(); ++i) {
                notesPerSec[i] * quarterNote => durPerSec[i];
                durPerSec[i] +=> totalDur;
            }
            totalDur => durPerSec[notesPerSec.cap()];
        }
    }
    
    // Notes per section
    fun static int[] sectionLengths(int notetime[]) {        
        notetime @=> notesPerSec;
        tempoChange();
        return notesPerSec;
    }  
    
    // The start time for the song.       
    fun static time start(time st) {
        return (st => start_time);
    }
    fun static time start() {
        return start_time;
    }
    fun static void timeReport(string title) {
        <<< title, (now - start_time)/second, "sec." >>>;
    }
    
    // set/get the array of legal notes
    fun static int[] notes(int n[]) {
        return (n @=> notesInKey);
    }
        
    fun static int[] notes() {
        return notesInKey;
    }
    
    // set/get the array of legal note names
    fun static string[] names(string s[]) {
        s @=> namesInKey;
    
        for (0 => int i; i < notesInKey.cap(); ++i) {
            notesInKey[i] => notesInKey[s[i]];
        }    
        return namesInKey;
    }
    fun static string[] names() {
        return namesInKey;
    }
    
    // set/get the array of section names, if we decide to name the sections
    fun static string[] sectionNames(string s[]) {
        s @=> namesPerSec;
             
        for (0 => int i; i < namesPerSec.cap(); ++i) {
            durPerSec[i] => durPerSec[namesPerSec[i]];
        }
        durPerSec[notesPerSec.cap()] => durPerSec["total"];
        return (s @=> namesPerSec);
    }
    fun static string[] sectionNames() {
        return namesPerSec;
    }
    
    // Make it easier to get a single section 
    fun static dur section(string name) {
        return durPerSec[name];
    }
}

/*// Test code
80 => BPM.tempo;

[4,12,8,12,4] => Comp.notesPerSection;
now => Comp.start;

<<< "intro : ", Comp.intro/second >>>;
Comp.intro => now;

<<< "part 1: ", Comp.part1/second >>>;
Comp.part1 => now;

<<< "bridge: ", Comp.bridge/second >>>;
Comp.bridge => now; 

<<< "part 2: ", Comp.part2/second >>>;
Comp.part2 => now;

<<< "coda  : ", Comp.coda/second >>>;
Comp.coda => now;

<<< "Time : ", (now - Comp.start())/second >>>;
*/



