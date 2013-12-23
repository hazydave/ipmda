// ================================================================================
// PUBLIC CLASS: Guitar
// File        : Guitar.ck
// Course      : Introduction to Programming for Musicians and Digital Artists
// Program     : Assignment 8: A Chase Would Be Nice
// Note        : PLEASE KEEP IF YOU FIND IT USEFUL
// Dependencies: NONE
// ================================================================================
// Guitar
// Basic 6-string rhythm guitar model


public class Guitar extends Chubgraph {
    
    int notes_in_chord;    // Notes actually played in current chord    
    int capo_bar;          // If there's a capo, what bar is it on? 
    int tuning_midi[];     // Guitar tuning, in MIDI notes. 
    dur max_delay;         // Maximum string to string delay. 
    
    float base_filter;     // Basic filter for all strings
    float peak_filter;     // Peak filter for just one string    
    float strum_decay;     // Loss of velocity from string to string
    float model_bal;       // Balance between the models used. 
    
    dur arpeggio_dur;      // If we set an arpeggio, we have to control time. 
    int arpeggio_alive;    // Is the argeggiator running? 

    // This is the primary guitar model. Each string is modeled, 
    // with a delay added to allow for strumming. 
    Mandolin model[6];
    StifKarp stk[model.cap()];
    Delay dly[model.cap()];
    
    // Create the basic output chain
    LPF flt => outlet;  
      
    // Add all strings on the input chain
    for (0 => int index; index < model.cap(); ++index) {
        stk[index]   => dly[index] => flt;
        model[index] => dly[index];
        1.0 => stk[index].gain => model[index].gain;
    }
    
    // Defaults for various settings
    1.0  => flt.gain;
    0::ms => arpeggio_dur; 
    0 => arpeggio_alive;
    
    // Settings for adaptive filter
    baseFilter(1500.0);
    peakFilter(5000.0); 
    
    // Default parameters
    capo(0);
    tuningStandard();
    delay(50::ms);

    balance(0.75);
    baseLoopGain(1.2);
    strumDecay(0.8);
    stringDamping(0.75);
    pluckPos(0.6);
    bodySize(0.4);
    
    // ===================================================================================================
    
    // Set the guitar tuning
    fun int[] tuning(int notes[]) {
        return (notes @=> tuning_midi);
    }
    fun int[] tuning() {
        return tuning_midi;
    }
    
    // Some useful tuning presets
    fun int[] tuningStandard() {
        //       E   A   D   G   B   e
        return ([40, 45, 50, 55, 59, 64] => tuning);
    }
    fun int[] tuningDropd() {
        //       D   A   D   G   B   e
        return ([38, 45, 50, 55, 59, 64] => tuning);
    }
    fun int[] tuningOpenG() {
        //       D   G   D   G   B   d
        return ([38, 43, 50, 55, 59, 62] => tuning);
    }
    fun int[] tuningOpenC() {
        //       C   G   C   G   C   e
        return ([36, 43, 48, 55, 57, 64] => tuning);
    }
    
    // Set or get a capo setting
    fun int capo(int c) {
        return (c => capo_bar);
    }
    fun int capo() {
        return capo_bar;
    }
    
    // Set an arpeggio
    fun dur arpeggio(dur ap) {
        return (ap => arpeggio_dur);
    }
    fun dur arpeggio() {
        return arpeggio_dur;
    }
    
    // Set the base filter
    fun float baseFilter(float f) {
        return (f => base_filter);
    }
    fun float baseFilter() {
        return base_filter;
    }

    // Set the peak filter
    fun float peakFilter(float f) {
        return (f => peak_filter);
    }
    fun float peakFilter() {
        return peak_filter;
    }
    
    // Set the peak filter
    
    // Set the guitar chord. This also calculates delays based on the given max
    // delay.
    fun int[] chord(int fingering[]) {    
        0 => notes_in_chord;     
        for (0 => int i; i < fingering.cap(); ++i) {
            if (-1 == fingering[i]) {
                1 => model[i].freq;
            } else if (capo() <= fingering[i]) {
                ++notes_in_chord;
                Math.mtof(tuning_midi[i] + fingering[i]) => model[i].freq => stk[i].freq; 
            } else {
                ++notes_in_chord;
                Math.mtof(tuning_midi[i] + capo()) => model[i].freq => stk[i].freq;
            }
            
        }

        // Adaptive filter... cut the high frequencies as the sound gets complex. 
        if (0::ms == arpeggio_dur)
            (peakFilter() - baseFilter())/model.cap() * (model.cap() - notes_in_chord) + baseFilter() => flt.freq;

        return fingering;
    }
    
    // The base loop gain
    fun float baseLoopGain(float bg) {
        for (0 => int i; i < model.cap(); ++i) {
            bg => stk[i].baseLoopGain;
        }
        return bg;
    }
    fun float baseLoopGain() {
        return stk[0].baseLoopGain();
    }
    
    // Set/get the string damping
    fun float stringDamping(float d) {
        for (0 => int i; i < model.cap(); ++i) {
            d => model[i].stringDamping;
            d => stk[i].sustain;
        }
        return d;
    }
    fun float stringDamping() {
        return model[0].stringDamping();
    }

    // Set/get the pluck position
    fun float pluckPos(float p) {
        for (0 => int i; i < model.cap(); ++i) {
            p => model[i].pluckPos;
            p => stk[i].pickupPosition;
        }
        return p;
    }
    fun float pluckPos() {
        return model[0].pluckPos();
    }
    
    // Set/get the body size
    fun float bodySize(float b) {
        for  (0 => int i; i < model.cap(); ++i) {
            b => model[i].bodySize;
        }
        return b;
    }
    fun float bodySize() {
        return model[0].bodySize();
    }
    
    // Set/get strum decay
    fun float strumDecay(float s) {
        return (s => strum_decay);
    }
    fun float strumDecay() {
        return strum_decay;
    } 
  
    // Set/get model balance
    fun float balance(float b) {
        b => model_bal;
        for  (0 => int i; i < model.cap(); ++i) {
            1 * model_bal / model.cap() => stk[i].gain;
            1  * (1-model_bal) / model.cap() => model[i].gain;
        }
        return b;
    }
    fun float balance() {
        return model_bal;
    }        
    
    // Set the max delay, which is string-to-string delay. The maximum 
    // overall delay is six times as much, of course. 
    fun dur delay(dur d) {
        d => max_delay;
        for (0 => int i; i < 6; ++i) {
           max_delay * 6 => dly[i].max;
        }
        return d;
    }
    fun dur delay() {
        return max_delay;
    }   
 
    // This does an arpeggiated strum. Velocity is positive for a downward strum, 
    // negative for an upward strum. 
    fun void arpeggiator(float vel) {
        Math.fabs(vel) => float current_vel;
        dur slop; 
        arpeggio_dur / notes_in_chord => dur arp_note_dur;
        
        if (vel < 0) {
            0::ms => slop; 
            for (model.cap() - 1 => int i; 0 <= i && arpeggio_alive; --i) {
                if (model[i].freq() > 1) {
                    slop => now;
                    current_vel => stk[i].pluck;
                    current_vel => model[i].pluck;
                    current_vel * strumDecay() => current_vel;
                                
                    Math.random2f(delay()/ms * 0.25, delay()/ms * 0.50)::ms => slop; 
                    arp_note_dur - slop => now; 
                    if (i != 0) {
                        1.0 => model[i].noteOff;
                        1.0 => stk[i].noteOff;
                    }
                }
            }
        } else {
            0::ms => slop; 
            for (0 => int i; i < model.cap() && arpeggio_alive; ++i) {
                if (model[i].freq() > 1) {
                    slop => now; 
                    current_vel => stk[i].pluck;
                    current_vel => model[i].pluck;
                    current_vel * strumDecay() => current_vel;
                                  
                    Math.random2f(delay()/ms * 0.25, delay()/ms * 0.50)::ms => slop;                     
                    arp_note_dur - slop => now;
                    if (i < model.cap() - 1) {
                        1.0 => model[i].noteOff;
                        1.0 => stk[i].noteOff;
                    }
                }
            }
  
        } 
        // Restore balance. 
        0 => arpeggio_alive;      
    }   
    
    // This does a strum... velocity is positive for a downward strum, negative for an
    // upward strum. 
    fun float noteOn(float vel) {
        0.0 => float total_dly;
        float one_dly;
        Math.fabs(vel) => float current_vel;
        
        if (arpeggio_alive) {
            <<< "Arpeggio too slow, still running" >>>;
            while (arpeggio_alive) 1::ms => now; 
        }
        if (vel < 0) {
            for (model.cap() - 1 => int i; 0 <= i; --i) {
                if (model[i].freq() > 1 && 0::ms == arpeggio_dur) {
                    current_vel => stk[i].pluck;
                    current_vel => model[i].pluck;
                    current_vel * strumDecay() => current_vel;
                     Math.random2f(delay()/ms * 0.5, delay()/ms) => one_dly;
                     one_dly +=> total_dly;
                     total_dly::ms => dly[i].delay;
                } else {
                    0::ms => dly[i].delay;
                }
            }
        } else {
            for (0 => int i; model.cap() > i; ++i) {
                if (model[i].freq() > 1 && 0::ms == arpeggio_dur) {
                    current_vel => model[i].pluck;
                    current_vel => stk[i].pluck;
                    current_vel * strumDecay() => current_vel;
                    
                    Math.random2f(delay()/ms * 0.5, delay()/ms) => one_dly;
                    one_dly +=> total_dly;
                    total_dly::ms => dly[i].delay;
                } else {
                    0::ms => dly[i].delay;
                }
            }
        }
        
        if (0::ms != arpeggio_dur) {
            spork ~ arpeggiator(vel);
            1 => arpeggio_alive;
        }
        
        return vel;
    } 
    
    // This is basically a mute
    fun float noteOff(float vel) {
        // Explicitly kill the arpeggiator
        0 => arpeggio_alive;
        // Stop the instruments. 
        for (0 => int i; i < model.cap(); ++i) {
            if (model[i].freq() > 1) {
                Math.fabs(vel) => model[i].noteOff;
                Math.fabs(vel) => stk[i].noteOff;
            }
        }
        return vel;
    }
}

/*
// Test function

Guitar gtr => dac;
1 => gtr.gain;
gtr.tuningStandard();

[ -1, 3, 2, 0, 0, 0 ] => gtr.chord;   // Cmaj7
0.8 => gtr.noteOn;
500::ms => now;

1000::ms => now; 

[ 1, 0, 2, 2, 1, 0 ] => gtr.chord;    // Fmaj7
0.6 => gtr.noteOn;
500::ms => now;

[ -1, 3, 2, 0, 0, 0 ] => gtr.chord;   // Cmaj7
-0.8 => gtr.noteOn;
500::ms => now;

[ 1, 0, 2, 2, 1, 0 ] => gtr.chord;    // Fmaj7
0.6 => gtr.noteOn;
500::ms => now;
0.1 => gtr.noteOff;
1000::ms => now; 

[ 1,-1,-1,-1,-1,-1 ] => gtr.chord;    // Lone strings
0.6 => gtr.noteOn;
500::ms => now;
[-1, 2,-1,-1,-1,-1 ] => gtr.chord; 
0.7 => gtr.noteOn;
500::ms => now;
[-1,-1, 3,-1,-1,-1 ] => gtr.chord;    // Lone strings
0.8 => gtr.noteOn;
500::ms => now;
[ 1,-1,-1, 1,-1,-1 ] => gtr.chord;    // Lone strings
0.9 => gtr.noteOn;
1000::ms => now;


[ -1, 3, 2, 0, 0, 0 ] => gtr.chord;   // Cmaj7
0.8 => gtr.noteOn;
500::ms => now;
0.1 => gtr.noteOff;
1000::ms => now; 

[ 1, 3, 3, 2, 1, 1 ] => gtr.chord;    // F
0.6 => gtr.noteOn;
500::ms => now;

[ 0, 0, 0, 2, 3, 1 ] => gtr.chord;   // Dm
-0.8 => gtr.noteOn;
500::ms => now;

[ 3, 2, 0, 0, 0, 3 ] => gtr.chord;    // G
0.6 => gtr.noteOn;
1500::ms => now;

*/
