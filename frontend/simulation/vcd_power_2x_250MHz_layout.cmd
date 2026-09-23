database -open power_2x_250MHz_layout -vcd -into power_2x_250MHz_layout.vcd -default
probe -create multiplier32fp_tb.DUV -all -depth all
run
exit
