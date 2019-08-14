function [success, com_obj] = fw_com_connect(com_obj, type, address, port, input_buffer_size, output_buffer_size, timeout, print_status)

	if(strcmpi(type, 'tcpip'))
		[success, com_obj] = tcp_connect(com_obj, address, port, input_buffer_size, output_buffer_size, timeout, print_status);
	elseif(strcmpi(type, 'uart'))
		[success, com_obj] = uart_connect(com_obj, [], address(4), input_buffer_size, output_buffer_size, timeout, print_status);
	else
		error('unknown communication protocol')
	end
	
end

