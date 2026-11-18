# Usage: vivado -mode batch -source fpga.tcl -tclargs rtl.sv top clock part period_ns outdir
if {$argc != 6} {error "Expected RTL TOP CLOCK PART PERIOD_NS OUTDIR"}
lassign $argv rtl top clock part period out
file mkdir $out
read_verilog -sv $rtl
synth_design -mode out_of_context -top $top -part $part
create_clock -name core_clk -period $period [get_ports $clock]
# Reserve 20% of a cycle on each external interface for this teaching budget.
set_input_delay -clock core_clk -max [expr {0.2 * $period}] [filter [all_inputs] "NAME != $clock"]
set_input_delay -clock core_clk -min 0 [filter [all_inputs] "NAME != $clock"]
set_output_delay -clock core_clk -max [expr {0.2 * $period}] [all_outputs]
set_output_delay -clock core_clk -min 0 [all_outputs]
opt_design
place_design
route_design
report_timing_summary -file [file join $out timing.rpt]
report_utilization -file [file join $out utilization.rpt]
report_route_status -file [file join $out routing.rpt]
write_checkpoint -force [file join $out routed.dcp]


