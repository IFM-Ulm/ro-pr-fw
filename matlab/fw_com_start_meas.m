function [success] = fw_com_start_meas(com_obj)
	
	fw_board_commands;

	command = cmd_meas;
	sub_command = cmd_meas_start_all;

	send_packet = [command sub_command];
	fwrite(com_obj, [value2byte(length(send_packet), 'u32') send_packet]);
	
	success = fw_com_check_answer(com_obj, command, sub_command); 

end

