cmd_nop = uint8(hex2dec('01'));

cmd_file = uint8(hex2dec('02'));
cmd_file_store = uint8(hex2dec('01'));
cmd_file_delete = uint8(hex2dec('F1'));

cmd_bin = uint8(hex2dec('03'));
cmd_bin_insert = uint8(hex2dec('01'));
cmd_bin_delete = uint8(hex2dec('F1'));
cmd_bin_delete_all = uint8(hex2dec('F0'));

cmd_meas = uint8(hex2dec('04'));
cmd_meas_insert = uint8(hex2dec('01'));
cmd_meas_delete = uint8(hex2dec('F1'));
cmd_meas_delete_all = uint8(hex2dec('F0'));
cmd_meas_start = uint8(hex2dec('02'));
cmd_meas_start_all = uint8(hex2dec('03'));

cmd_cont = uint8(hex2dec('05'));
cmd_cont_stuck = uint8(hex2dec('01'));
cmd_cont_resend = uint8(hex2dec('02'));

mode_seq = 0;
mode_par = 1;


time_1us = 0;
time_10us = 1;
time_100us = 2;
time_1ms = 3;
time_30us = 4;
time_50us = 5;
% time_1s = 6;
time_70us = 7;