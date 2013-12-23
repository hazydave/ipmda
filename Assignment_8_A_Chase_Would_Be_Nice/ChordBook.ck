// ================================================================================
// PUBLIC CLASS: ChordBook
// File        : ChordBook.ck
// Class       : Introduction to Programming for Musicians and Digital Artists
// Program     : Assignment 8: A Chase Would Be Nice
// Date        : 2013-Dec-12
// Note        : PLEASE KEEP IF YOU FIND IT USEFUL
// Dependencies: NONE
// ================================================================================
//
// This class maintains a library of guitar chord fingerings. Given a guitar tuning, 
// it can return an array of MIDI notes for a given chord. This is an upgrade from a
// version of this from some weeks ago, as well as being a class now. The only 
// methods usually needed are get_fingering(string) or get_MIDI(string, tuning). 
// There are several forms of chord string:
//
//    "E", "Bm"          plain string, gets the default chord
//    "1.E", "0.Bm"      qualified string, gets a specific chord variant
//    ". x x 2 2 x x"    tabbed entry, 2-characters per string
//    ".2x 2 22x"        same thing, x multiplier

public class ChordBook {
    // The chord table
    static int chord_table[][][];
    
    // Special variables
    static int x;

    // Has it been initialized?
    static int class_init;
 
    // The init function loads the table... do this just once. 
    fun static void init() {
        if (!class_init) {
            // Allocated chord memory
            
            new int[1][1][1] @=> chord_table;
            
            // String not played
            -1  => x; 
            [[  x,  0,  x,  x,  x,  x ],  [  x,  x,  x,  2,  x,  x ],  [  x,  x,  x,  x,  x,  5 ]] @=> chord_table["A*"];     // Single notes: A  B  Db D  E
            [[  x,  1,  x,  x,  x,  x ],  [  x,  x,  x,  3,  x,  x ],  [  x,  x,  x,  x,  x,  6 ]] @=> chord_table["Bb*"];
            [[  x,  2,  x,  x,  x,  x ],  [  x,  x,  x,  x,  0,  x ],  [  x,  x,  x,  x,  x,  7 ]] @=> chord_table["B*"];  
            [[  x,  3,  x,  x,  x,  x ],  [  x,  x,  x,  x,  1,  x ],  [  x,  x,  x,  x,  x,  8 ]] @=> chord_table["C*"];
            [[  x,  4,  x,  x,  x,  x ],  [  x,  x,  x,  x,  2,  x ],  [  x,  x,  x,  x,  x,  9 ]] @=> chord_table["Db*"];
            [[  x,  x,  0,  x,  x,  x ],  [  x,  x,  x,  x,  3,  x ],  [  x,  x,  x,  x,  x, 10 ]] @=> chord_table["D*"];  
            [[  x,  x,  1,  x,  x,  x ],  [  x,  x,  x,  x,  4,  x ],  [  x,  x,  x,  x,  x, 11 ]] @=> chord_table["Db*"];  
            [[  0,  x,  x,  x,  x,  x ],  [  x,  x,  2,  x,  x,  x ],  [  x,  x,  x,  x,  x,  1 ],  [  x,  x,  x,  x,  x, 12 ]] @=> chord_table["E*"]; 
            [[  1,  x,  x,  x,  x,  x ],  [  x,  x,  3,  x,  x,  x ],  [  x,  x,  x,  x,  x,  2 ],  [  x,  x,  x,  x,  x, 13 ]] @=> chord_table["F*"];            
            [[  2,  x,  x,  x,  x,  x ],  [  x,  x,  x,  0,  x,  x ],  [  x,  x,  x,  x,  x,  3 ],  [  x,  x,  x,  x,  x, 14 ]] @=> chord_table["G*"];
            [[  x,  0,  x,  x,  x,  x ],  [  x,  x,  x,  1,  x,  x ],  [  x,  x,  x,  x,  x,  4 ],  [  x,  4,  x,  x,  x, 15 ]] @=> chord_table["Gb*"];  

 
            [[  x,  0,  2,  2,  2,  0 ],  [  5,  7,  7,  6,  5,  5 ],  [  x,  x,  7,  9, 10,  9 ],  [  x, 12, 11,  9, 10,  9 ],  [  x, 12, 14, 14, 14, 12 ]] @=> chord_table["A"];         // A
            [[  x,  0,  2,  2,  1,  0 ],  [  x,  3,  2,  2,  1,  0 ],  [  x,  0,  x,  2,  1,  x ],  [  5,  7,  7,  5,  5,  5 ],  [  x,  x,  x,  5,  5,  5 ]] @=> chord_table["Am"];        // Am
            [[  x,  0,  2,  1,  2,  0 ],  [  x,  0,  2,  2,  2,  4 ],  [  5,  x,  6,  6,  5,  x ],  [  x,  x,  7,  6,  5,  4 ]]                              @=> chord_table["Amaj7"];     // Amaj7
            [[  x,  0,  2,  2,  2,  2 ],  [  5,  x,  4,  6,  5,  x ],  [  5,  7,  x,  6,  7,  5 ],  [  x, 12,  x, 11, 14, 12 ],  [  x, 12, 11,  9,  9,  9 ]] @=> chord_table["A6"];        // A6 
            [[  x,  0,  2,  2,  0,  0 ]]                                                                                                                     @=> chord_table["Asus2"];     // Asus2
            [[  x,  0,  0,  2,  3,  0 ],  [  x,  0,  2,  2,  3,  5 ],  [  5,  7,  7,  7,  5,  5 ],  [ 12, 12, 14, 15, 12,  x ]]                              @=> chord_table["Asus4"];     // Asus4
     
            [[  x,  2,  4,  4,  3,  2 ],  [  7,  9,  9,  7,  7,  7 ]]                                                                                        @=> chord_table["Bm"];        // Bm
            [[  x,  2,  x,  1,  3,  2 ],  [  x,  2,  4,  x,  3,  4 ],  [  7,  x,  6,  7,  7,  7 ],  [  7,  9,  9,  7,  9,  7 ]]                              @=> chord_table["Bm6"];       // Bm6
            [[  x,  2,  0,  2,  0,  2 ],  [  x,  2,  4,  2,  3,  2 ],  [  7,  x,  7,  7,  7,  x ],  [  7,  9,  7,  7, 10,  7 ]]                              @=> chord_table["Bm7"];       // Bm7
            [[  x,  2,  4,  4,  2,  2 ]]                                                                                                                     @=> chord_table["Bsus2"];     // Bsus2
            [[  x,  2,  2,  4,  5,  2 ],  [  7,  9,  9,  9,  7,  7 ],  [  x,  x,  9,  9,  7,  7 ]]                                                           @=> chord_table["Bsus4"];     // Bsus4
            [[  x,  2,  4,  2,  2,  5 ]]                                                                                                                     @=> chord_table["B7sus2"];    // B7sus2
            [[  x,  2,  4,  2,  5,  2 ],  [  7,  9,  7,  9,  7,  7 ]]                                                                                        @=> chord_table["B7sus4"];    // B7sus4
  
            [[  x,  3,  2,  0,  1,  0 ],  [  x,  x,  x,  0,  1,  0 ],  [  x,  3,  5,  5,  5,  3 ],  [  8, 10, 10,  9,  8,  8 ]]                              @=> chord_table["C"];         // C
            [[  x,  3,  2,  0,  1,  0 ],  [  x,  x,  x,  0,  1,  0 ],  [  x,  3,  5,  5,  5,  3 ],  [  8, 10, 10,  9,  8,  8 ]]                              @=> chord_table["Cmaj"];      // Cmaj
            [[  x,  4,  2,  1,  3,  x ],  [  x,  4,  6,  6,  5,  4 ],  [  9, 11, 11,  9,  9,  9 ],  [  x,  x, 11,  9,  9, 12 ],  [  x,  x, 11, 13, 14, 12 ]] @=> chord_table["C#m"];       // C#m
            [[  x,  4,  2,  1,  0,  0 ],  [  x,  4,  x,  4,  5,  4 ],  [  9,  x,  9,  9,  9,  x ],  [  9, 11,  9,  9, 12,  9 ]]                              @=> chord_table["C#m7"];      // C#m7
            [[  x,  4,  4,  6,  7,  4 ],  [  x,  4,  6,  6,  7,  x ],  [  9,  1,  1,  1,  9,  9 ]]                                                           @=> chord_table["C#sus4"];    // C#sus4
            [[  x,  4,  4,  4,  2,  4 ],  [  x,  4,  6,  4,  7,  4 ]]                                                                                        @=> chord_table["C#m7sus4"];  // C#m7sus4

            [[  x,  x,  0,  2,  3,  2 ],  [  x,  5,  4,  2,  3,  2 ],  [ x,   5,  7,  7,  7,  5 ],  [ 10,  9,  7,  7,  7,  x ],  [ 10, 12, 12, 11, 10, 10 ]] @=> chord_table["D"];         // D
            [[  x,  x,  0,  2,  1,  2 ],  [  x,  3,  0,  2,  3,  2 ],  [ x,   5,  4,  5,  3,  x ],  [  x,  5,  7,  5,  7,  5 ],  [ 10, 12, 10, 11, 14, 10 ]] @=> chord_table["D7"];        // D7
            [[  x,  5,  4,  2,  2,  2 ],  [  x,  5,  7,  6,  7,  5 ],  [ 10,  x, 11, 11, 10,  x ],  [  x,  x, 12, 11, 10,  9 ]]                              @=> chord_table["Dmaj7"];     // Dmaj7
            [[  x,  5,  2,  2,  2,  2 ],  [ 10,  x, 11, 11,  x, 12 ]]                                                                                        @=> chord_table["Dmaj9"];     // Dmaj9 
            [[  x,  5,  x,  6,  7,  7 ],  [ 10,  9,  9,  9, 10,  9 ]]                                                                                        @=> chord_table["Dmaj13"];    // Dmaj13
            [[  x,  x,  0,  2,  3,  0 ]]                                                                                                                     @=> chord_table["D6"];        // D6
            [[  x,  x,  0,  2,  0,  2 ],  [  x,  5,  7,  7,  7,  7 ],  [ 10,  x,  9, 11, 10,  x ],  [ 10, 12,  x, 11, 12, 10 ]]                              @=> chord_table["Dsus2"];     // Dsus2
  
            [[  0,  2,  2,  1,  0,  0 ],  [  0,  2,  2,  4,  5,  4 ],  [  0,  7,  6,  4,  5,  4 ],  [  x,  7,  9,  9,  9,  7 ],  [ 12, 11,  9,  9,  9,  x ]] @=> chord_table["E"];         // E
            [[  0,  2,  2,  0,  0,  0 ],  [  x,  2,  5,  4,  5,  x ],  [  x,  x,  5,  4,  5,  3 ],  [  x,  7,  9,  9,  8,  7 ],  [  x,  x,  9,  9,  8,  7 ]] @=> chord_table["Em"];        // Em 
            [[  0,  2,  0,  0,  0,  0 ],  [  0,  2,  2,  0,  3,  0 ],  [  x,  7,  5,  7,  x,  x ],  [ 12,  x, 12, 12, 12, 12 ],  [ 12, 14, 12, 12, 12, 12 ]] @=> chord_table["Em7"];       // Em7 
            [[  0,  2,  2,  1,  2,  0 ],  [  x,  x,  2,  4,  2,  4 ],  [  x,  7,  9,  9,  9,  9 ]]                                                           @=> chord_table["E6"];        // E6
            [[  0,  2,  0,  1,  0,  0 ],  [  0,  2,  2,  1,  3,  0 ],  [  x,  7,  9,  7,  9,  7 ],  [  x,  7,  9,  9,  9, 10 ],  [ 12,  x, 12, 13, 12,  x ]] @=> chord_table["E7"];        // E7 
            [[  0,  2,  0,  1,  0,  2 ],  [  x,  7,  6,  7,  7,  7 ],  [ 12,  x, 12, 11,  9,  x ]]                                                           @=> chord_table["E9"];        // E9
            [[  0,  x,  0,  1,  2,  2 ],  [  0,  2,  0,  1,  2,  2 ],  [  x,  7,  x,  7,  9,  9 ],  [ 12,  x, 12, 13, 14, 14 ]]                              @=> chord_table["E13"];       // E13 
            [[  0,  2,  4,  4,  3,  2 ]]                                                                                                                     @=> chord_table["E7sus2"];    // E7sus2
            [[  0,  2,  2,  2,  3,  0 ],  [  x,  7,  9,  7, 10,  x ]]                                                                                        @=> chord_table["E7sus4"];    // E7sus4
            [[  0,  2,  4,  4,  0,  0 ],  [  x,  7,  9,  9,  7,  7 ]]                                                                                        @=> chord_table["Esus2"];     // Esus2
            [[  0,  2,  2,  2,  0,  0 ],  [  x,  x,  2,  4,  5,  5 ],  [  x,  7,  7,  9, 10,  7 ],  [  x,  7,  9,  9, 10,  x ]]                              @=> chord_table["Esus4"];     // Esus4
 
            [[  1,  4,  4,  3,  1,  1 ],  [  x,  x,  4,  3,  2,  2 ],  [  x,  9,  8,  6,  7,  6 ],  [  x,  9, 11, 11, 11,  x ]]                              @=> chord_table["F#"];        // F#
            [[  2,  3,  4,  2,  x,  2 ],  [  2,  0,  x,  x,  1,  2 ],  [  x,  0,  4,  5,  7,  5 ],  [  x,  x,  7,  5,  7,  x ], [ 14,  x, 16, 14, 13,  x ]]  @=> chord_table["F#dim"];     // F#dim 
            [[  2,  4,  4,  2,  2,  2 ],  [  x,  x,  4,  2,  2,  5 ],  [  x,  x,  4,  6,  7,  5 ],  [  x,  9,  7,  6,  7,  x ], [  x,  9, 11, 11, 10,  9 ]]  @=> chord_table["F#m"];       // F#m 
            [[  2,  x,  2,  2,  2,  x ],  [  2,  4,  4,  2,  5,  2 ],  [  x,  x,  4,  6,  5,  5 ],  [  x,  9,  7,  9,  7,  9 ], [  x,  9, 11,  9, 10, 12 ]]  @=> chord_table["F#m7"];      // F#m7
            [[  2,  0,  2,  2,  1,  x ],  [  0,  3,  4,  2,  1,  0 ],  [  x,  x,  4,  5,  5,  5 ],  [  0,  9,  7,  9,  7,  8 ], [ 14,  x, 14, 14, 13,  x ]]  @=> chord_table["F#m7b5"];    // F#m7b5
            [[  x,  x,  4,  1,  2,  2 ],  [  x,  9, 11, 11,  9,  9 ]]                                                                                        @=> chord_table["F#sus2"];    // F#sus2
            [[  2,  4,  4,  4,  2,  2 ],  [  x,  x,  4,  6,  7,  7 ],  [  x,  9,  9, 11, 12,  9 ]]                                                           @=> chord_table["F#sus4"];    // F#sus4
            [[  x,  x,  4,  1,  2,  0 ]]                                                                                                                     @=> chord_table["F#7sus2"];   // F#7sus2
            [[  2,  4,  2,  4,  2,  2 ],  [  x,  x,  4,  6,  5,  7 ]]                                                                                        @=> chord_table["F#7sus4"];   // F#7sus4

            [[  3,  2,  0,  0,  0,  3 ],  [  3,  x,  0,  0,  0,  3 ],  [  3,  5,  5,  4,  3,  3 ],  [  x,  x,  x,  7,  8,  7 ], [  x, 10, 12, 12, 12,  x ]]  @=> chord_table["G"];         // G
            [[  3,  2,  0,  0,  0,  1 ],  [  3,  2,  3,  0,  0,  4 ],  [  3,  5,  3,  4,  6,  4 ],  [  x,  x,  5,  4,  6,  1 ], [  x, 10,  9, 10,  6,  x ]]  @=> chord_table["G7"];        // G7 
            [[  4,  2,  0,  1,  0,  x ]]                                                                                                                     @=> chord_table["G#dim"];     // G#dim
            [[  x,  x,  6,  7,  7,  7 ],  [  x, 11, 12, 11, 12,  x ]]                                                                                        @=> chord_table["G#m7b5"];    // G#m7b5
 
            1 => class_init;
        }
    }
    
    // The chord table looks up the given note and the variation of that note, in the chord
    // table by chord name. If found, it returns the list of 6 offsets on the guitar fretboard. If not
    // found, it returns a list of all "x" fingerings -- nothing to play. 

    fun static int[] get_fingering(string chord, int var) {
        [x, x, x, x, x, x] @=> int result[];
        init();
        
        if ('.' == chord.charAt(0)) {
            get_fingering(chord) @=> result;
        } else {
            if ("RST" != chord && chord_table[chord].cap() > var) {
                chord_table[chord][var] @=> result;
            }
        }
        return result;   
    }
    
    // Compact string form of fingering, converts to array format   
    fun static int[] get_fingering(string chord) {
        [ x, x, x, x, x, x ] @=> int result[];

        if ('.' != chord.charAt(0)) {
            if (chord.length() > 1 && '.' == chord.charAt(1)) {
                get_fingering(chord.substring(2),chord.charAt(0) - '0') @=> result;
            } else {
                get_fingering(chord,0) @=> result;
            }
        } else {
            string sub;  
            0 => int res_pos;
            
            for (1 => int i; i < chord.length(); 2 +=> i) {
                chord.substring(i,2) => sub;

                if ("x" == sub.substring(1,1)) {
                    if (" " != sub.substring(0,1)) {
                        Std.atoi(sub.substring(0,1)) +=> res_pos;
                    } else {
                        res_pos++;
                    }
                } else {
                    Std.atoi(sub) => result[res_pos++];
                }
            }
        }
        return result;       
    } 
    
    // Turns a fingering array into a fingering string
    fun static string print_fingering(int fingering[]) {
        "" => string result; 
        
        for (0 => int i; i < fingering.cap(); ++i) {
            if (-1 == fingering[i]) {
                " x" +=> result;
            } else {
                "  " => string add;
                if (fingering[i] >= 10) {
                    add.setCharAt(0, '0' + fingering[i] / 10);
                }
                add.setCharAt(1, '0' + fingering[i] % 10);
                add +=> result;
            }            
        }
        return result;
    }

    // This gets an array of MIDI notes to play

    fun static int[] get_MIDI(string chord, int var, int tuning[]) {        
        get_fingering(chord, var) @=> int offsets[];
        [-1, -1, -1, -1, -1, -1 ] @=> int result[];
    
        for (0 => int i; i < tuning.cap(); ++i) {
            if (x == offsets[i]) {
                x => result[i];
            } else {
                tuning[i] + offsets[i] => result[i];
            }
        }
        return result;
    }
    
    // This uses the smart system to do the same thing
    fun static int[] get_MIDI(string chord, int tuning[]) {
        get_fingering(chord) @=> int offsets[];
        [-1, -1, -1, -1, -1, -1 ] @=> int result[];

        for (0 => int i; i < tuning.cap(); ++i) {
            if (x == offsets[i]) {
                x => result[i];
            } else {
                tuning[i] + offsets[i] => result[i];
            }
        }
        return result;
    }
        
}


    