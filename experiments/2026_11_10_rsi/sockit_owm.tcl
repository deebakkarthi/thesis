clear -all

check_cov -init -type mutation -model all

analyze -v2k -f sockit_owm.f

if { [file exists sockit_owm_sva.f] == 1 } {
	analyze -sv -f sockit_owm_sva.f
}

# Blackbox missing modules instead of erroring out
elaborate -bbox 1
clock clk
reset rst==1'b1

sanity_check -analyze simple_reset

prove -all

check_cov -measure

report -json -file ./metrics/[exec date +%Y%m%dT%H%M%S].json
