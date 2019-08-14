function [success, output_bytes] = fw_com_read_bytes(com_obj, use_buffering, index_buffering, number_bytes, expected_bytes)
	
	global buffer_received_bytes

	if(nargin < 3)
		use_buffering = 0;
	end
	
	if(use_buffering > 0 && index_buffering < 1 || use_buffering > 3 || use_buffering < 0)
		use_buffering = 0;
		warning('disabled buffering due to incorrect parameter index_buffering: %d', index_buffering);
	end

	if(nargin < 4)
		number_bytes = 0;
	end

	if(nargin < 5)
		expected_bytes = [];
	end

	output_bytes = [];
	
	if(use_buffering > 0)
		if(use_buffering == 1)
			bytesav = length(buffer_received_bytes{index_buffering});
		elseif(use_buffering == 2)
			bytesav = buffer_received_bytes{index_buffering};
		end
	else
		bytesav = com_obj.BytesAvailable;
	end
	
	if(~isempty(expected_bytes))
		if(bytesav < length(expected_bytes))
			success = false;			
			return
		end
	end
	
	if(use_buffering > 0)
		
		if(use_buffering == 1)
			output_bytes = buffer_received_bytes{index_buffering};

			if(length(output_bytes) == number_bytes)
				if(isempty(expected_bytes))
					success = true;
				else
					if(length(expected_bytes) == length(output_bytes))
						if(sum(expected_bytes == output_bytes) == length(expected_bytes))
							success = true;
						else
							success = false;
						end
					else
						success = false;
					end
				end
			else
				success = false;
			end
		elseif(use_buffering == 2 || use_buffering == 3)
			output_bytes = [];
			if(buffer_received_bytes{index_buffering} == number_bytes)
				success = true;
			else
				success = false;
			end
		end
		
	elseif(bytesav < number_bytes)
		output_bytes = fread(com_obj, bytesav);
		success = false;
	else
		if(bytesav > 0)
			if(number_bytes > 0)
				
				if(number_bytes < 1048576)					
					output_bytes = fread(com_obj, number_bytes);
				else
					output_bytes = zeros(1, number_bytes);
					offset_read = 1;
					read_size = 1048576;
					bytesrem = bytesav;
					
					while(bytesrem > 0)

						output_bytes(1, offset_read : offset_read + read_size - 1) = fread(com_obj, read_size);
						offset_read = offset_read + read_size;
						bytesrem = bytesrem - read_size;

						if(bytesrem > 0 && bytesrem < read_size)
							read_size = bytesrem;
							output_bytes(1, offset_read : offset_read + read_size - 1) = fread(com_obj, read_size);
							bytesrem = 0;
						end

					end
				end
				
			else
				output_bytes = fread(com_obj, bytesav);
			end
		

			if(size(output_bytes,1) > 1)
				output_bytes = output_bytes.';
			end

			if(isempty(expected_bytes))
				success = true;
			else
				if(length(expected_bytes) == length(output_bytes))
					if(sum(expected_bytes == output_bytes) == length(expected_bytes))
						success = true;
					else
						success = false;
					end
				else
					success = false;
				end
			end
		else
			success = false;
		end
	end
end

