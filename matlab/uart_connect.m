function [success, uart_obj] = uart_connect(uart_obj, ~, port, input_buffer_size, output_buffer_size, ~, print_status)
	
	success = false;

	if(nargin < 4 || isempty(input_buffer_size) || input_buffer_size == 0)
		input_buffer_size = 1048576;
	end
	if(nargin < 5 || isempty(output_buffer_size) || output_buffer_size == 0)
		output_buffer_size = 1048576;
	end

	if(nargin < 7 || isempty(print_status))
		print_status = false;
	end
		
	if(isa(uart_obj, 'serial'))
		if(isvalid(uart_obj))
			if(strcmp(uart_obj.Status, 'open'))
				try
					flushinput(uart_obj);
					flushoutput(uart_obj);
					fclose(uart_obj);
					delete(uart_obj);
				catch e
					if(print_status) 
						fprintf('closing valid and open uart object failed with message:');
						fprintf('%s\n', e.identifier);
						fprintf('%s\n', e.message)
					end
				end
			end
		end
	end

	try
		addr_full = sprintf('COM%d', port(1));

		
		if(print_status) 
			fprintf('opening connection to %s ... ', addr_full);
		end
		
		uart_obj = serial(addr_full);
		uart_obj.BaudRate = 115200;
		uart_obj.Parity = 'none';
		uart_obj.DataBits = 8;
		uart_obj.FlowControl = 'none';
		uart_obj.ReadAsyncMode = 'continuous';
		uart_obj.InputBufferSize = input_buffer_size;
		uart_obj.OutputBufferSize = output_buffer_size;
		uart_obj.BytesAvailableFcnMode = 'terminator'; % terminator | byte

		fopen(uart_obj);

		if(print_status) 
			fprintf('succcess\n');
		end
		
		success = true;
	catch e1
		
		if(strcmp(e1.identifier, 'MATLAB:serial:fopen:opfailed'))
			
			try
				instr_all = instrfind;
				found_port = 0;
				
				for instr = instr_all

					if(strcmp(instr.Name, sprintf('Serial-COM%d', port))) % e.g. Serial-COM4
						found_port = found_port + 1;
						fclose(instr);
						delete(instr);
					end

				end
				
				if(found_port > 1)
					[success, uart_obj] = uart_connect(uart_obj, [], port, input_buffer_size, output_buffer_size, [], print_status);
				else
					success = false;
					uart_obj = [];
				end
				
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