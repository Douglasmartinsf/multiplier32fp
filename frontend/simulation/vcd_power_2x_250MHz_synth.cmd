database -open power_2x_250MHz_synth -vcd -into power_2x_250MHz_synth.vcd -default
probe -create multiplier32fp_tb.DUV -all -depth all
run
exit
