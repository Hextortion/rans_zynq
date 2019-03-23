if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vlog -vopt +acc -sv -sv12compat +incdir+rtl +incdir+sim +define+SIMULATION -work work sim/rans_test_package.sv
vlog -vopt +acc -sv -sv12compat +incdir+rtl +incdir+sim +define+SIMULATION -work work sim/tb.sv
vlog -vopt +acc -sv -sv12compat +incdir+rtl +incdir+sim +define+SIMULATION -work work rtl/rans_stream.sv
vlog -vopt +acc -sv -sv12compat +incdir+rtl +incdir+sim +define+SIMULATION -work work rtl/rans_multi_stream.sv
vsim -t 100ps -lib work tb