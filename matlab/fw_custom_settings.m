%% folder settings

save_folder = 'D:\FPGA_PUFs\RO\RO_PR\data';
save_folder = sprintf('%s/%s', normalizeFolder(save_folder), datestr(now, 'yyyy_mm_dd_HH_MM_SS'));

%% email settings

%% board settings

% board_ids = [ 1 2 3 4 5 6 ];
board_ids = [ 1 ];

% board_type = 'zybo';
% board_type = 'pynq';
board_type = 'zyboz720';

% static information from implementation
ro_per_bin = 32;

connection_type = 'tcpip';
% connection_type = 'uart';

%% com settings - tcpip
ip_boards_common = [192 168 0];

ip_boards = [1 2 3 4 5 6]; % individual last nibblets of the ip-addresses

tcpip_port = 7; % ECHO-Port used

%% com settings - uart
com_boards_common = [0 0 0];

com_boards = [4 0 0 0 0 0]; % COM-port indizes for uart, e.g. 4 for COM4

%% temperature device settings

%% debug settings

dbg_ignore_time = true;
dbg_omit_save = false;
dbg_reconnect_after_meas = true;
dbg_measure_sequential = false;


%% measurement settings

readout_number = 100000;

readout_repetitions = 0;

heatups = 0;
cooldowns = 0;

temperatures_all = [ 20 -10 0 10 20 30 40 50 60 20 ];

temperature_use = false;

time_all = [ time_1us time_1us time_10us time_10us time_100us time_100us ];

identifier = 'reference';
% identifier = 'long';


%% output settings 

percent_increment = 1;


%% buffer settings
% 0 = no buffering
% 1 = buffering
% 2 = buffer to file
% 3 = buffer to file, only complete binary readout
use_buffering = 2;

%% calculations, do not touch

mode_all = zeros(1, size(time_all,2));
mode_all(1,1:2:end) = mode_par;
mode_all(1,2:2:end) = mode_seq;

readouts_all = readout_number * ones(1, size(time_all,2));

repetitions_all = readout_repetitions * ones(1, size(time_all,2));

heatup_all = heatups * ones(1, size(time_all,2));

cooldown_all = cooldowns * ones(1, size(time_all,2));

number_boards = length(board_ids);
number_active_boards = sum(board_ids > 0);

%% check for errorneous settings
if(use_buffering >= 3)
	error('do not use buffering == 3 (experimental feature never completed)');
end
