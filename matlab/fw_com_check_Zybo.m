function [success] = fw_com_check_Zybo(com_obj)

	fw_board_commands;

	flushinput(com_obj);

	command = cmd_nop;
	sub_command = cmd_nop;
	send_packet = [command sub_command];
	fwrite(com_obj, [value2byte(length(send_packet), 'u32') send_packet]);

	success = fw_com_check_answer(com_obj, command, sub_command, 3); 
	
end

