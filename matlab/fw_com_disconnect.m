function [success] = fw_com_disconnect(com_obj, print_status)

	if(isa(com_obj, 'tcpip'))
		[success] = tcp_disconnect(com_obj, print_status);
	elseif(isa(com_obj, 'serial'))
		[success] = uart_disconnect(com_obj, print_status);
	elseif(isa(com_obj, 'double'))
		success = true;
	else
		error('unknown communication protocol')
	end	
	
end

