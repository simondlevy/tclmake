# Usage: vivado -mode batch -source build.tcl -tclargs <synth|impl|bit>
set stage   [lindex $argv 0]
set project $::env(PROJECT)
set top     $::env(TOP)
set part    $::env(PART)
set jobs    $::env(JOBS)
set build   $::env(BUILD_DIR)

set rtl_srcs $::env(RTL_SRCS)
set xdc_srcs $::env(XDC_SRCS)

set_param general.maxThreads $jobs

switch $stage {
    synth {
        foreach f $rtl_srcs {
            switch -- [string tolower [file extension $f]] {
                .v           { read_verilog $f }
                .sv          { read_verilog -sv $f }
                .vhd - .vhdl { read_vhdl $f }
            }
        }
        foreach f $xdc_srcs { read_xdc $f }

        synth_design -top $top -part $part
        write_checkpoint -force $build/post_synth.dcp
        report_utilization    -file $build/post_synth_util.rpt
        report_timing_summary -file $build/post_synth_timing.rpt
    }

    impl {
        open_checkpoint $build/post_synth.dcp
        opt_design
        place_design
        phys_opt_design
        write_checkpoint -force $build/post_place.dcp
        route_design
        write_checkpoint -force $build/post_route.dcp

        report_utilization      -file $build/post_route_util.rpt
        report_timing_summary   -file $build/post_route_timing.rpt
        report_clock_utilization -file $build/post_route_clock.rpt
        report_drc              -file $build/post_route_drc.rpt
        report_power            -file $build/post_route_power.rpt

        set wns [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
        puts "INFO: Worst negative slack = $wns ns"
        if {$wns < 0} {
            puts "WARNING: Timing not met (WNS = $wns ns)"
        }
    }

    bit {
        open_checkpoint $build/post_route.dcp
        write_bitstream -force $build/$project.bit
    }

    default {
        puts "ERROR: unknown stage '$stage' (expected synth, impl or bit)"
        exit 1
    }
}
