function [success, partialCounter] = fw_com_setup_bin(com_obj, partials_top1, partials_top2)
	
	fw_board_commands;

	partialCounter = length(partials_top1) + length(partials_top2);
	
	id = 0; 
	
	%% flush bin files
	command = cmd_bin;
	sub_command = cmd_bin_delete_all;
 	send_packet = [command sub_command];
 	fwrite(com_obj, [value2byte(length(send_packet), 'u32') send_packet]);
	
	success = fw_com_check_answer(com_obj, command, sub_command); 
	if(~success)
		return
	end
	
	
	%% transmit bin infos
	command = cmd_bin;
	sub_command = cmd_bin_insert;
	
	if(~isempty(partials_top1))
		
		% transmit toplevel 1
		id = id + 1;
		isPartial = 0;
		filename = 'T1.BIN';

		send_packet = [command sub_command value2byte(id,'u16') value2byte(isPartial,'u8') value2byte(length(filename),'u16') uint8(filename)];
		fwrite(com_obj, [value2byte(length(send_packet), 'u32') send_packet]);

		success = fw_com_check_answer(com_obj, command, sub_command); 
		if(~success)
			return
		end
		
		% transmit partials of toplevel 1
		for ind = partials_top1
			id = id + 1;
			isPartial = 1;
			filename = sprintf('T1I1R%02d.BIN', ind);

			send_packet = [command sub_command value2byte(id,'u16') value2byte(isPartial,'u8') value2byte(length(filename),'u16') uint8(filename)];
			fwrite(com_obj, [value2byte(length(send_packet), 'u32') send_packet]);

			success = fw_com_check_answer(com_obj, command, sub_command); 
			if(~success)
				return
			end
		end
	end

	if(~isempty(partials_top2))
		
		% transmit toplevel 2
		id = id + 1;
		isPartial = 0;
		filename = 'T2.BIN';

		send_packet = [command sub_command value2byte(id,'u16') value2byte(isPartial,'u8') value2byte(length(filename),'u16') uint8(filename)];
		fwrite(com_obj, [value2byte(length(send_packet), 'u32') send_packet]);

		success = fw_com_check_answer(com_obj, command, sub_command); 
		if(~success)
			return
		end

		% transmit partials of toplevel 2
		for ind = partials_top2
			id = id + 1;
			isPartial = 1;
			filename = sprintf('T2I1R%02d.BIN', ind);

			send_packet = [command sub_command value2byte(id,'u16') value2byte(isPartial,'u8') value2byte(length(filename),'u16') uint8(filename)];
			fwrite(com_obj, [value2byte(length(send_packet), 'u32') send_packet]);

			success = fw_com_check_answer(com_obj, command, sub_command); 
			if(~success)
				return
			end
		end
	end

	
end

