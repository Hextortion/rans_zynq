if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vlog -sv +define+SIMULATION -y rtl -y sim -work work sim/tb.sv
vlog -sv +define+SIMULATION -y rtl -y sim -work work rtl/rans.sv
vlog -sv +define+SIMULATION -y rtl -y sim -work work rtl/top.sv
vsim -t 100ps -lib work tb