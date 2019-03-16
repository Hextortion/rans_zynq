if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vlog -sv -sv12compat +incdir+rtl +incdir+sim +define+SIMULATION -work work sim/driver.sv
vlog -sv -sv12compat +incdir+rtl +incdir+sim +define+SIMULATION -work work sim/tb.sv
vlog -sv -sv12compat +incdir+rtl +incdir+sim +define+SIMULATION -work work rtl/rans.sv
vlog -sv -sv12compat +incdir+rtl +incdir+sim +define+SIMULATION -work work rtl/top.sv
vsim -t 100ps -lib work tb