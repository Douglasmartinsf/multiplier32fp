SHELL := /bin/bash
.DEFAULT_GOAL := help

help sim sim-flags sim-protocol test synth layout sim-post-synth sim-post-layout power validate:
	@bash scripts/run.sh $@

sim-pre-synth sim-presyn: sim

.PHONY: help sim sim-flags sim-protocol test synth layout sim-post-synth sim-post-layout power validate sim-pre-synth sim-presyn
