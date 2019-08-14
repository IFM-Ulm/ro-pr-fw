function [success] = uart_disconnect(uart_obj, print_status)
	
	if(nargin < 2 || isempty(print_status))
		print_status = false;
	end

	success = true;

	if(isa(uart_obj, 'serial'))
		
		if(isvalid(uart_obj))
			
			if(strcmp(uart_obj.Status, 'open'))
				
				if(print_status)
					fprintf('uart_obj is an open and valid "serial", closing ... ');
				end
				
				try
					flushinput(uart_obj);
					flushoutput(uart_obj);
					fclose(uart_obj);
					
					if(print_status)
						fprintf('success\n');
					end
					
				catch e
					
					if(print_status)
						fprintf('failed with message:\n');
						fprintf('%s\n', e.identifier);
						fprintf('%s\n', e.message);
					end
					
					success = false;
				end
			else
				if(print_status)
					fprintf('uart_obj is a closed valid "tcpip"\n');
				end	
			end
			
			delete(uart_obj);

		else
			if(print_status)
				fprintf('failed to disconnect, uart_obj is not valid\n');
			end
		end
	else
		if(print_status)
			fprintf('failed to disconnect, uart_obj is not an object of "serial"\n');
		end
	end


end