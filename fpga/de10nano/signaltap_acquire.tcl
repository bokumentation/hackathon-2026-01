# signaltap_acquire.tcl - run one SignalTap capture on the DE10-Nano over JTAG.
#
# Prerequisites:
#   1. de10nano_top.stp exists (created in the Quartus GUI).
#   2. quartus_stp de10nano_top --stp_file de10nano_top.stp --enable
#      has been run and the design recompiled and programmed.
#   3. The board is connected and visible to jtagconfig.
#
# Usage:
#   quartus_stp -t signaltap_acquire.tcl
#
# The instance, signal set, and trigger names are defined by the .stp file.
# Check them in the SignalTap GUI and adjust the variables below if they differ.
# If the system has only one signal set and one trigger, those two options can be
# omitted from the run command.

package require ::quartus::stp

set stp_file   "de10nano_top.stp"
set instance   "auto_signaltap_0"
set signal_set "signal_set_1"
set trigger    "trigger_1"
set data_log   "log_1"
set out_vcd    "output_files/signaltap_capture.vcd"
set timeout_s  30

if {[catch {open_session -name $stp_file} msg]} {
    puts "ERROR: open_session failed: $msg"
    exit 1
}

if {[catch {run -instance $instance -signal_set $signal_set -trigger $trigger -data_log $data_log -timeout $timeout_s} msg]} {
    puts "ERROR: run failed: $msg"
    catch {close_session}
    exit 1
}

if {[catch {export_data_log -instance $instance -signal_set $signal_set -trigger $trigger -data_log $data_log -filename $out_vcd -format vcd} msg]} {
    puts "WARN: export_data_log failed: $msg"
}

close_session
puts "SignalTap capture written to $out_vcd"
