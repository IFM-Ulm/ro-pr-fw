%% header

clc
fw_board_commands;

%% settings

fw_custom_settings;

%% check for correct settings

save_folder = sprintf('%s_%s', save_folder, identifier);
for board_index = 1 : number_boards
	
	if(board_ids(board_index) <= 0)
		continue
	end
	
	save_folder = sprintf('%s_%02d', save_folder, board_ids(board_index));
end

if(~exist(save_folder, 'dir'))
	try
		[success, ~, ~] = mkdir(save_folder);
		if(~success)
			error('invalid data folder settings')
		end
	catch e
		error('invalid data folder settings')
	end
	
end

if(length(ip_boards) < number_boards)
	error('invalid settings')
end

if(length(board_ids) < number_boards)
	error('invalid settings')
end

if(length(readouts_all) ~= length(mode_all) || length(readouts_all) ~= length(time_all) || length(readouts_all) ~= length(heatup_all))
	error('invalid settings')
end

if(number_boards < 1)
	error('invalid settings')
end

%% connection setup

% increase heap space available for tcpip: MATLAB Preferences > General > Java Heap Memory

clear com_obj_all

max_readouts = max(readouts_all);

%% get number of bins from board type
if(strcmp(board_type, 'zybo'))
	partials_top1 = 1 : 52;
	partials_top2 = 1 : 72;
	number_partials_top1 = 52;
	number_partials_top2 = 72;
elseif(strcmp(board_type, 'pynq') || strcmp(board_type, 'zyboz720'))
	partials_top1 = 1 : 136;
	partials_top2 = 1 : 260;
	number_partials_top1 = 136;
	number_partials_top2 = 260;
else
	error('unknown board in fw_com_setup_bin');
end

number_bin = number_partials_top1 + number_partials_top2;

%% get paths and connections

if(strcmp(connection_type, 'tcpip'))
	port = tcpip_port;
	address_common = ip_boards_common;
	address_indv = ip_boards;
elseif(strcmp(connection_type, 'uart'))
	port = 0;
	address_common = com_boards_common;
	address_indv = com_boards;
else
	error('unknown connection type');
end

%%
max_input_size = 262144000; % set to static 250MB
max_input_size = max_input_size + 1024^2; % add 1MB for safety

max_output_size = 10 * 1024^2; % hold space for 10MB output

waitTime_start = zeros(1, number_boards);
waitTime_end = zeros(1, number_boards);

ref_counter = 0;

total_meas_counter = 0;
fail_counter = zeros(1, number_boards);

printN = false;

tic;

if((exist('com_obj', 'var')))
	fw_com_disconnect(com_obj, false);
end

if(strcmp(connection_type, 'tcpip') && number_boards > 0)
	
	boards_found = 0;
	
	for board_index = 1 : number_boards
		
		if(board_ids(board_index) <= 0)
			continue
		end
		
		fprintf('testing connection to %d.%d.%d.%d\n', ip_boards_common(1), ip_boards_common(2), ip_boards_common(3), ip_boards(board_index));
		test_ping = evalc(sprintf('!ping -w 1 -n 1 %d.%d.%d.%d', ip_boards_common(1), ip_boards_common(2), ip_boards_common(3), ip_boards(board_index)));

		if(contains(test_ping, '(100%') || contains(test_ping, 'host'))
			warning('\tboard %d not reachable by ping', board_index)
		else
			fprintf('\tboard %d found\n', board_index);
			boards_found = boards_found + 1;
		end
	end
	
	if(boards_found < number_boards)
		error('connection failed');
	end
end

if(number_boards > 0)
	
	for board_index = 1 : number_boards
		
		if(board_ids(board_index) <= 0)
			continue
		end
		
		fprintf('connecting to board %d (id %d)\n', board_index, board_ids(board_index));

		[success, com_obj] = fw_com_connect(0, connection_type, [address_common address_indv(board_index)], port, max_input_size, max_output_size, 3, true);

		if(~success)
			error('connection failed for board %d (id %d)\n', board_index, board_ids(board_index));
		end

		success = fw_com_check_Zybo(com_obj);
		if(~success)
			error('connection check failed for board %d (id %d)\n', board_index, board_ids(board_index));
		end

		fprintf('\n');

		com_obj_all(board_index) = com_obj;
		clear com_obj
	
	end
else
	error('number of boards == 0')
end

steps_succeeded = zeros(1, number_boards);

fprintf('\n\n');

global buffer_received_bytes
global buffer_fID

%% measurements
for temp_index = 1 : size(temperatures_all, 2)

	temperature = temperatures_all(temp_index);
	
	% add temperature control here if required

	measurement_size = size(readouts_all, 2);
	
	for measurement = 1 : measurement_size
		
		if(use_buffering > 0)
			buffer_received_bytes = cell(1,number_boards);
			if(use_buffering == 2)
				
				fIDs = fopen('all');
				for f = fIDs
					fName = fopen(f);
					if(contains(fName, 'temp_buf_board'))
						fprintf('closing file %s abnormally\n', fName);
						fclose(f);
					end
				end
				
				buffer_fID = cell(1,number_boards);
				
				for b = 1 : number_boards
					buffer_received_bytes{b} = 0;
					buffer_fID{b} = -1;
				end
			end
		end

		mode = mode_all(measurement);
		readouts = readouts_all(measurement);
		time = time_all(measurement);
		heatup = heatup_all(measurement);
		cooldown = cooldown_all(measurement);
		repetitions = repetitions_all(measurement);

		fprintf('\n\nnew measurement: %d / %d (%d) - (%.0f°C)\n', measurement, measurement_size, total_meas_counter, temperature);
		if(mode == mode_seq)
			fprintf(' - sequential\n');
		else
			fprintf(' - parallel\n');
		end
		fprintf(' - %d readouts\n', readouts);
		if(time == time_1us)
			fprintf(' - 1us\n');
			time_value = 1e-6;
		elseif(time == time_10us)
			fprintf(' - 10us\n');
			time_value = 10e-6;
		elseif(time == time_100us)
			fprintf(' - 100us\n');
			time_value = 100e-6;
		elseif(time == time_30us)
			fprintf(' - 30us\n');
			time_value = 30e-6;
		elseif(time == time_50us)
			fprintf(' - 50us\n');
			time_value = 50e-6;
		elseif(time == time_70us)
			fprintf(' - 70us\n');
			time_value = 70e-6;
		elseif(time == time_1ms)
			fprintf(' - 1ms\n');
			time_value = 1000e-6;
		else
			fprintf('unknown time\n');
			error('invalid time settings')
		end
		
		fprintf(' - %d repetitions\n', repetitions);		
		fprintf(' - %d heatup\n', heatup);
		fprintf(' - %d cooldown\n', cooldown);
		fprintf('\n');

		% estimated_time per partial bitfile, not the whole measurement
		if(mode == mode_seq)
			estimated_time = heatup * time_value + 32 * readouts * repetitions * (time_value + cooldown * 100e-6);
		else
			estimated_time = heatup * time_value + readouts * repetitions * (time_value + cooldown * 100e-6);
		end
		if(estimated_time < 20)
			estimated_time = 20;
		end
		
		threshold_time = 3 * estimated_time;

		last_bytes_av = zeros(1,number_boards);
		last_bytes_percent = zeros(1,number_boards);
		last_time_change = zeros(1,number_boards);
		fail_counter = zeros(1,number_boards);
		timediff = 0;
		
		while(sum(steps_succeeded == 5) < number_active_boards)

			printN = false;
			
			pause(0.01); % just in case for updating values
			
			%% error handling
			for board_index = 1 : number_boards
				
				if(board_ids(board_index) <= 0)
					continue
				end
				
				while(steps_succeeded(board_index) < 0)
					
					printN = true;
					
					fprintf('step %d failed on board %d (id %d), handling errors ...\n', abs(steps_succeeded(board_index)), board_index, board_ids(board_index));
					
					fail_counter(1, board_index) = fail_counter(1, board_index) + 1;
					
					if(fail_counter(1, board_index) > 3)
					
						fprintf('failcounter > 3, entering manual debug mode ...\n');						
						fprintf('step %d failed on board %d (id %d), failcounter > 3, waiting for board reset\n', abs(steps_succeeded(board_index)), board_index, board_ids(board_index))
						
						keyboard
						
						last_time_change(1 : number_boards) = toc;
						
						fail_counter(1, board_index) = 0;
					end
					
					fprintf('disconnecting ...\n');
					fw_com_disconnect(com_obj_all(board_index), true);
					
					pause(1)
					
					fprintf('reconnecting ...\n');
										
					[success, com_obj] = fw_com_connect(0, connection_type, [address_common address_indv(board_index)], port, max_input_size, max_output_size, 3, true);
					
					if(success)
                        
						fprintf('reconnecting sucessful\n');
                        
						fprintf('checking board ...\n');

						success = fw_com_check_Zybo(com_obj);

						if(success)
						    fprintf('board check sucessful\n');
						    com_obj_all(board_index) = com_obj;

						else
						    fprintf('reconnecting failed\n');
						end
                        
					else
						
						steps_succeeded(board_index) = -1;
						
						fprintf('reconnecting failed\n');
						fprintf('step %d failed on board %d (id %d), waiting for board reset\n', abs(steps_succeeded(board_index)), board_index, board_ids(board_index))
						
						fprintf('entering manual debug mode: restart board and continue by typing "dbcont" in the command line\n');
						
						keyboard
						
						fail_counter(1, board_index) = 0;
						
						last_time_change(1 : number_boards) = toc;
					end

					if(success)
												
						last_bytes_av(board_index) = 0;
						last_bytes_percent(board_index) = 0;
						last_time_change(board_index) = toc;
						
						if(use_buffering == 1)
							
							buffer_received_bytes{board_index} = [];
							steps_succeeded(board_index) = 0;
							
						elseif(use_buffering == 2)
							
							if(buffer_fID{board_index} > 0)
								fclose(buffer_fID{board_index});
								buffer_fID{board_index} = -1;
							end
							
							buffer_received_bytes{board_index} = 0;
							steps_succeeded(board_index) = 0;
							
						end
						
						
					end
						
					if(success)
						fprintf('step %d failed on board %d (id %d) (failcounter = %d), reset successful, trying to continue\n', abs(steps_succeeded(board_index)), board_index, board_ids(board_index), fail_counter(1, board_index))
					end
					
				end
			end
			
			if(printN)
				fprintf('\n');
				printN = false;
			end
			
			%% bitfile setup
			for board_index = 1 : number_boards
				
				if(board_ids(board_index) <= 0)
					continue
				end
				
				if(steps_succeeded(board_index) == 0)

					fprintf('setting bitfiles on board %d (id %d) ...', board_index, board_ids(board_index));
					printN = true;

					[success, partialCounter] = fw_com_setup_bin(com_obj_all(board_index), partials_top1, partials_top2);

					if(success)
						fprintf(' success\n');

						steps_succeeded(board_index) = 1;
					else
						fprintf(' failed\n');

						steps_succeeded(board_index) = -1;
					end

				end
			end
			
			if(printN)
				fprintf('\n');
				printN = false;
			end
			
			%% setup measurement
			for board_index = 1 : number_boards
				
				if(board_ids(board_index) <= 0)
					continue
				end
				
				if(steps_succeeded(board_index) == 1)
										
					fprintf('setup measurement on board %d (id %d) ...', board_index, board_ids(board_index));
					printN = true;

					[success, expected_bytes] = fw_com_setup_meas(com_obj_all(board_index), mode, readouts, repetitions, time, heatup, cooldown, partialCounter);

					if(success)
						fprintf(' success\n');

						steps_succeeded(board_index) = 2;
					else
						fprintf(' failed\n');
						
						steps_succeeded(board_index) = -2;
					end

				end
			end
			
			if(printN)
				fprintf('\n');
				printN = false;
			end
			

			%% start measurement
			for board_index = 1 : number_boards
				
				if(board_ids(board_index) <= 0)
					continue
				end
				
				if(dbg_measure_sequential > 0)
					if(sum(steps_succeeded == 5) + dbg_measure_sequential < board_index)
						break;
					end
				end
				
				if(steps_succeeded(board_index) == 2)

					waitTime_start(board_index) = toc;
					
					fprintf('starting measurement on board %d (id %d)... ', board_index, board_ids(board_index));
					printN = true;

					[success] = fw_com_start_meas(com_obj_all(board_index));

					if(success)
						fprintf('success\n');
						
						steps_succeeded(board_index) = 3;					
					else
						fprintf('failed\n');
						
						steps_succeeded(board_index) = -3;
					end
					
				end
			end
			
			if(printN)
				fprintf('\n');
				printN = false;
			end


			%% wait for data
			for board_index = 1 : number_boards
				
				if(board_ids(board_index) <= 0)
					continue
				end
				
				if(steps_succeeded(board_index) == 3)
					
					if(timediff == 0)
						fprintf('waiting for data (%.0f Mb) from boards\n', expected_bytes / 1024^2);
						printN = true;
						timediff = 1;
					end
					
					[success, bytesav, bytes_percent] = fw_com_receive_bytes(com_obj_all(board_index), expected_bytes, use_buffering, board_index, false, 0, true);
					
					if(success)
	
						waitTime_end(board_index) = toc;
						waitTime_diff = waitTime_end(board_index) - waitTime_start(board_index);
						data_rate = (expected_bytes / 1024^2) / waitTime_diff;
						data_rate_unit = 'Mb';
						if(data_rate < 1)
							data_rate = data_rate * 1024;
							data_rate_unit = 'Kb';
						end

						fprintf('received complete data from board %d (id %d)\n', board_index, board_ids(board_index));
						
						fprintf('estimated datarate of board %d (id %d): %.0f Mb - %.1f s - %.1f %s/s\n', board_index, board_ids(board_index), ...
							expected_bytes / 1024^2, waitTime_diff, data_rate, data_rate_unit);
						printN = true;
						
						steps_succeeded(board_index) = 4;
						
						last_bytes_av(board_index) = 0;
						
					else

						if(bytesav == last_bytes_av(board_index))
							if(last_time_change(board_index) > 0)
								timediff = toc - last_time_change(board_index);
								if(dbg_ignore_time)
									last_time_change(board_index) = toc;
								else
									if(timediff > threshold_time)
										fprintf('data transfer from board %d (id %d) timeout after %d bytes (%.1fs, threshold %.1fs)\n', board_index, board_ids(board_index), bytesav, timediff, threshold_time);
										printN = true;
										steps_succeeded(board_index) = -4;
									end
								end
							else
								last_time_change(board_index) = toc;
							end
						else
							last_time_change(board_index) = toc;
							last_bytes_av(board_index) = bytesav;
							
							if(last_bytes_percent(board_index) + percent_increment < bytes_percent)
								fprintf('[%s] bytes board %d (id %d): %.0f / %.0f (%.1f%%)\n', datestr(now,'HH:MM:SS'), board_index, board_ids(board_index), bytesav, expected_bytes, bytes_percent);
								printN = true;
								last_bytes_percent(board_index) = last_bytes_percent(board_index) + percent_increment;
							end							
						end
						
					end
				end				
			end
			
			if(printN)
				fprintf('\n');
				printN = false;
			end
			
			%% read data
			for board_index = 1 : number_boards
				
				if(board_ids(board_index) <= 0)
					continue
				end
				
				if(steps_succeeded(board_index) == 4)
					
					fprintf('reading data from board %d (id %d) ... ', board_index, board_ids(board_index));
					printN = true;

					[success, output_bytes] = fw_com_read_bytes(com_obj_all(board_index), use_buffering, board_index, expected_bytes);

					if(success)
						fprintf('success\n');

						steps_succeeded(board_index) = 5;
					else
						fprintf('failed\n');
						
						steps_succeeded(board_index) = -5;
						
						% error handling
					end
					
					output_bytes = output_bytes.';

					date_str = datestr(now,'yyyymmddHHMMSS');
					filename = sprintf('%s_board_%02d_te_%06d_m_%d_ti_%d_r_%d_x%d_%s', board_type, board_ids(board_index), 1000 * temperature + 273150, ...
						mode, time, readouts, repetitions, date_str);
					
					filepath = sprintf('%s/%s.mat', save_folder, filename);

					measurement_type = mode;
					measurement_number = readouts;
									
					if(time == 7)
						measurement_time = 100e-9;
						measurement_time_string = '100 ns';
					elseif(time < 7)
						measurement_time = 10^time * 1e-6;

						if(measurement_time >= 1e-3)
							measurement_time_string = sprintf('%d ms', floor(measurement_time/1e-3));
						elseif(measurement_time >= 1e-6)
							measurement_time_string = sprintf('%d us', floor(measurement_time/1e-6));
						else
							measurement_time_string = sprintf('%d ns', floor(measurement_time/1e-9));
						end

					else
						measurement_time_string = '?';
					end
					
					if(measurement_type == 1)
						measurement_type_string = 'parallel';
					else
						measurement_type_string = 'serial';
					end
					
					id = sprintf('%s%d%d_%s', date_str, floor(measurement_time*1e7), measurement_type, filename);
					
					if(use_buffering > 1)
						data_file = sprintf('%s.dat', filename);
					else
						data_file = sprintf('%s.mat', filename);
					end
					
					board_id = board_ids(board_index);

					if(~dbg_omit_save)
						fprintf('saving data from board %d (id %d) to file %s.mat in folder %s\n', board_index, board_ids(board_index), filename, save_folder);
						
						save(filepath, 'output_bytes', 'board_id', 'identifier', 'board_type', 'date_str', 'temperature', 'measurement_type', 'measurement_type_string', 'measurement_number', ...
							'measurement_time', 'measurement_time_string', 'heatup', 'cooldown', 'number_bin', 'ro_per_bin', 'partials_top1', 'partials_top2', ...
							'number_partials_top1', 'number_partials_top2', 'repetitions', 'data_file', '-v7.3')

						if(use_buffering > 1)
							try
								movefile(sprintf('temp_buf_board%d.dat', board_index), sprintf('%s/%s.dat', save_folder, filename));
							catch
								fIDs = fopen('all');
								for f = fIDs
									fName = fopen(f);
									if(contains(fName, sprintf('temp_buf_board%d.dat', board_index)))
										fprintf('closing file %s abnormally\n', fName);
										fclose(f);
									end
								end
								movefile(sprintf('temp_buf_board%d.dat', board_index), sprintf('%s/%s.dat', save_folder, filename));
							end
						end
					else
						fprintf('omitting save due to debug settings');
					end

					
				end			
			end

			if(printN)
				fprintf('\n');
				printN = false;
			end
		
		end
		
		fprintf('fail_counter sum: %d\n', sum(fail_counter));
		
		% skip bin-file setup on next measurement
		if(dbg_reconnect_after_meas)
			
			for board_index = 1 : number_boards
			
				fprintf('disconnecting ...\n');
				
				fw_com_disconnect(com_obj_all(board_index), true);

				pause(1)

				fprintf('reconnecting ...\n');

				[success, com_obj] = fw_com_connect(0, connection_type, [address_common address_indv(board_index)], port, max_input_size, max_output_size, 3, true);

				if(success)

					fprintf('reconnecting sucessful\n');

					fprintf('checking board ...\n');

					success = fw_com_check_Zybo(com_obj);

					if(success)
						fprintf('board check sucessful\n');
						com_obj_all(board_index) = com_obj;
						steps_succeeded(board_index) = 0;
					else
						steps_succeeded(board_index) = -5;
						fprintf('reconnecting failed\n');
					end

					
				else
					fprintf('reconnecting failed\n');
					steps_succeeded(board_index) = -5;
				end
			end
			
		else
			steps_succeeded = ones(1,number_boards);
		end
		
		total_meas_counter = total_meas_counter + 1;
		
	end
	
	if(~temperature_use)
		break
	end
	
end

%% close connection
for board_index = 1 : number_boards
	
	if(board_ids(board_index) <= 0)
		continue
	end

	fprintf('closing connection to board %d (id %d) ...', board_index, board_ids(board_index));
	
	[success] = fw_com_disconnect(com_obj_all(board_index), true);
	if(success)
		fprintf('success\n');
	else
		fprintf('failed\n');
	end
	
	fprintf('\n');
end

%% set temperature to "normal"
if(temperature_use)
	% add temperature control here (set temperature to room temperature)
end

%% switch of temperature chamber
if(temperature_use)
	% add temperature control here (switch off temperature device)
end

%% notify
fprintf('measurements on all boards successfully finished\n');

endTime = toc;

fprintf(' - all done - total run time: %.1fs\n', endTime);
