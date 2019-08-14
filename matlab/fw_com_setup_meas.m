function [success, expected_bytes] = fw_com_setup_meas(com_obj, mode, readouts, repetitions, time, heatup, cooldown, partialCounter)
	
	global expected_bytes_bin

	expected_bytes = 0;

	fw_board_commands;
		
	%% flush measurements
	command = cmd_meas;
	sub_command = cmd_meas_delete_all;
 	send_packet = [command sub_command];
 	fwrite(com_obj, [value2byte(length(send_packet), 'u32') send_packet]);
	
	success = fw_com_check_answer(com_obj, command, sub_command); 
	if(~success)
		return
	end

	%% transmit meas insert
	command = cmd_meas;
	sub_command = cmd_meas_insert;
	id = 1;
	
	% expected static bytes: 2 bytes temperature start,2 bytes temperature end, 33 * 4 bytes average for compression
	% expected dynamic bytes (parallel): readouts * (32 (ro_per_bin) * 1 byte (data) + 1 byte (reference))
	% expected dynamic bytes (serial): readouts * 2 bytes (ro + ref) * 32 (ro_per_bin)
	if(mode == mode_par)
		expected_bytes = (repetitions + 1) * partialCounter * (4 + 4 * readouts * (32 + 1));
		expected_bytes_bin = (repetitions + 1) * (4 + 4 * readouts * (32 + 1));
	else
		expected_bytes = (repetitions + 1) * partialCounter * (4 + 4 * readouts * 2 * 32);
		expected_bytes_bin = (repetitions + 1) * (4 + 4 * readouts * 2 * 32);
	end
	
	send_packet = [command sub_command value2byte(id,'u16') value2byte(mode,'u8') value2byte(readouts,'u32') value2byte(time,'u32') value2byte(heatup,'u32') value2byte(cooldown,'u32') value2byte(repetitions,'u32')];
	fwrite(com_obj, [value2byte(length(send_packet), 'u32') send_packet]);
	
	success = fw_com_check_answer(com_obj, command, sub_command); 

end

