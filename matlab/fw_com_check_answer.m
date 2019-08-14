function [success] = fw_com_check_answer(com_obj, command, sub_command, timeout)
	
	if(nargin < 4 || isempty(timeout))
		timeout = 10;
	end

	[success, ~] = fw_com_receive_bytes(com_obj, 3, 0, 0, false, timeout);
	if(success)
		[success, ~] = fw_com_read_bytes(com_obj, 0, 0, 3, [command sub_command 6]);
	else
		fw_com_read_bytes(com_obj);
		return;
	end
	
end

