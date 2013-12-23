// ================================================================================
// PUBLIC CLASS: ModBass
// File        : ModBass.ck
// Course      : Introduction to Programming for Musicians and Digital Artists
// Date        : 2013-Dec-14
// Program     : Assignment 8: Final Thing
// Note        : PLEASE KEEP IF YOU FIND IT USEFUL
// Dependencies: NONE
// ===========================================================================

// Not sure what kind of bass instrument this is supposed to be. I wanted something
// kind of mellow, to fill in the low-end of the piece. I screwed around with trying
// to use hand-rolled FM synthesis for a more bass-guitar-like bass, but didn't 
// really get there. I had the idea up to a point, but couldn't get the filtering right. 

public class ModBass extends Chubgraph {
    // Filter
    LPF lpf => ADSR adsr => Gain sw => Chorus chr => outlet;
    
    // Generator components    
    SinOsc osc   => lpf;
    SinOsc osc2x => lpf;
    SawOsc mod   => osc;
           mod   => osc2x;
    SinOsc sub   => lpf;
    mod => Gain modfb => mod;
    
    // slide tracking
    float target_freq;
    float last_freq;
    
    // FM modulation
    2 => osc.sync => osc2x.sync;
    50 => mod.gain;
    300 => mod.freq;
    10 => modfb.gain;
    2 => mod.sync;
    
    
    // slide paramters
    100::ms => dur slide_dur;
    10      => int slide_steps;
    
    0.6 => osc.gain;
    0.6 => osc2x.gain;
    0.7 => sub.gain;
    
    1.0 => lpf.gain;
    1800 => lpf.freq;
    
    adsr.set(5::ms, 10::ms, 0.5, 60::ms);

      
    // ===========================================================================
    // Slider
    
    fun void slide_freq() {
        
        if (0 == last_freq) {
            target_freq              => osc.freq;
            target_freq * 2          => osc2x.freq;
            target_freq / 2          => sub.freq;
        } else {            
            slide_dur / slide_steps => dur slider;
            (target_freq - osc.freq()) / slide_steps => float freq_step;
            
            for (0 => int i; i < slide_steps; ++i) {
                osc.freq() + freq_step  => osc.freq;
                osc.freq() * 2.0 => osc2x.freq;
                osc.freq() / 2   => sub.freq;       
       
                slider => now; 
            }
        }
    }
      
      
    // ===========================================================================
    //
    // Frequency 
    fun float freq(float f) {
        f => last_freq;
        return (f => target_freq);
    }
    fun float freq() {
        return osc.freq();
    }
        
    // Note play
    fun float noteOn(float vel) {
        vel => sw.gain;
        1 => adsr.keyOn;
        spork ~ slide_freq();
        return vel;
    }
    
    fun float noteOff(float vel) {
        1 => adsr.keyOff;
        0 => last_freq;
        return vel;
    }
}

/*

// Test code

Bass b => dac;

for (20 => int note; 80 > note; note + 12 => note) {
Math.mtof(note) => b.freq;
0.5 => b.noteOn;
150::ms => now; 
1.0 => b.noteOff;
50::ms => now;
0.5 => b.noteOn;
150::ms => now; 
1.0 => b.noteOff;
150::ms => now;

Math.mtof(note-2) => b.freq;
0.6 => b.noteOn;
250::ms => now;
0.5 => b.noteOff;
100::ms => now;

Math.mtof(note) => b.freq;
0.6 => b.noteOn;
150::ms => now;
0.5 => b.noteOff;
50::ms => now;

Math.mtof(note-2) => b.freq;
0.6 => b.noteOn;
150::ms => now;
0.5 => b.noteOff;
200::ms => now;
}
*/


