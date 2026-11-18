# Usage: yosys -c asic.tcl -- rtl.sv top cells.lib outdir
if {$argc != 4} {error "Expected RTL TOP LIBERTY OUTDIR"}
lassign $argv rtl top lib out
file mkdir $out
yosys read_verilog -sv $rtl
yosys hierarchy -check -top $top
yosys synth -top $top -noabc
yosys dfflibmap -liberty $lib
yosys abc -liberty $lib
yosys clean
yosys stat -liberty $lib
yosys write_verilog -noattr -noexpr -nohex -nodec [file join $out mapped.v]
