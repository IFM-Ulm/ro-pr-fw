function [success, tcpip_obj] = tcp_connect(tcpip_obj, ip, port, input_buffer_size, output_buffer_size, timeout, print_status)
	
	success = false;

	if(nargin < 4 || isempty(input_buffer_size) || input_buffer_size == 0)
		input_buffer_size = 1048576;
	end
	if(nargin < 5 || isempty(output_buffer_size) || output_buffer_size == 0)
		output_buffer_size = 1048576;
	end
	if(nargin < 6 || isempty(timeout) || timeout == 0)
		timeout = 1;
	end
	if(nargin < 7 || isempty(print_status))
		print_status = false;
	end
	
	
	if(isa(tcpip_obj, 'tcpip'))
		if(isvalid(tcpip_obj))
			if(strcmp(tcpip_obj.Status, 'open'))
				try
					flushinput(tcpip_obj);
					flushoutput(tcpip_obj);
					fclose(tcpip_obj);
					delete(tcpip_obj);
				catch e
					if(print_status) 
						fprintf('closing valid and open tcpip failed with message:');
						fprintf('%s\n', e.identifier);
						fprintf('%s\n', e.message)
					end
				end
			end
		end
	end

	try
		ip_full = sprintf('%d.%d.%d.%d', ip(1), ip(2), ip(3), ip(4));
		
		if(print_status) 
			fprintf('opening connection to %s ... ', ip_full);
		end
		
		tcpip_obj = tcpip(ip_full, port, 'NetworkRole', 'client', 'InputBufferSize', input_buffer_size, 'OutputBufferSize', output_buffer_size, 'Timeout', timeout, 'TransferDelay', 'on');
		
		fopen(tcpip_obj);

		if(print_status) 
			fprintf('succcess\n');
		end
		
		success = true;
	catch e1
		if(strcmp(e1.identifier, 'MATLAB:serial:fopen:opfailed'))
			
			try
				instr_all = instr_find;

				for instr = instr_all

					if(strcmp(instr.Name, sprintf('TCPIP-%s', ip_full))) % e.g. TCPIP-134.60.26.167
						fclose(instr);
						delete(instr);
					end

				end
				
				[success, tcpip_obj] = tcp_connect(tcpip_obj, ip, port, input_buffer_size, output_buffer_size, timeout, print_status);
				
			catch e2
				if(print_status) 
					fprintf('failed after try to close with message(s):\n');
					fprintf('%s\n', e1.identifier);
					fprintf('%s\n', e1.message);
					fprintf('%s\n', e2.identifier);
					fprintf('%s\n', e2.message);
				end
			end
		else
		
			if(print_status) 
				fprintf('failed with message:\n');
				fprintf('%s\n', e1.identifier);
				fprintf('%s\n', e1.message);
			end
		end
	end
	
end

