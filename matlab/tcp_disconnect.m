function [success] = tcp_disconnect(tcpip_obj, print_status)
	
	if(nargin < 2 || isempty(print_status))
		print_status = false;
	end

	success = true;

	if(isa(tcpip_obj, 'tcpip'))
		
		if(isvalid(tcpip_obj))
			
			if(strcmp(tcpip_obj.Status, 'open'))
				
				if(print_status)
					fprintf('tcpip_obj is an open and valid "tcpip", closing ... ');
				end
				
				try
					flushinput(tcpip_obj);
					flushoutput(tcpip_obj);
					fclose(tcpip_obj);
					
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
					fprintf('tcpip_obj is a closed valid "tcpip"\n');
				end	
			end
			
			delete(tcpip_obj);

		else
			if(print_status)
				fprintf('failed to disconnect, tcpip_obj is not valid\n');
			end
		end
	else
		if(print_status)
			fprintf('failed to disconnect, tcpip_obj is not an object of "tcpip"\n');
		end
	end


end

