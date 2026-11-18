# Program the first device on the first JTAG target
open_hw_manager
connect_hw_server
open_hw_target

set dev [lindex [get_hw_devices] 0]
current_hw_device $dev
set_property PROGRAM.FILE $::env(BITFILE) $dev
program_hw_devices $dev

close_hw_target
disconnect_hw_server
close_hw_manager
