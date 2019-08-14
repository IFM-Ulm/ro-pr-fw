function [success, bytesav, bytes_percent] = fw_com_receive_bytes(com_obj, expected_bytes, use_buffering, index_buffering, print_progress, timeout, oneshot)
	
	global buffer_received_bytes
	global buffer_fID
	global expected_bytes_bin

	if(nargin < 4)
		use_buffering = 0;
	end
	
	if(use_buffering > 0 && index_buffering < 1 || use_buffering > 3 || use_buffering < 0)
		use_buffering = 0;
		warning('disabled buffering due to incorrect parameter index_buffering: %d', index_buffering);
	end
	
	if(nargin < 5 || isempty(print_progress))
		print_progress = false;
	end
		
	if(nargin < 6)
		timeout_used = false;
		timeout = 3;
	else
		if(~isempty(timeout))
			if(timeout > 0)
				timeout_used = true;
			else
				timeout_used = false;
				timeout = 10;
			end
		end
	end

	if(nargin < 7 || isempty(oneshot))
		oneshot = false;
	end
	
	if(use_buffering > 0 && ~oneshot)
		warning('do not use buffering without oneshot, as it possibly negates advantage of buffering');
	end
	
	bytesav = com_obj.BytesAvailable;
	
	
	bytes_at_start = bytesav;
	
	
	time_at_start = toc;
	
	bytes_percent = 100 * (bytesav / expected_bytes);

	last_bytesav = bytesav;

	last_percent = 0;
	last_percent_increment = 10;

	interval = 0.001;
	timeout_count = timeout / interval;
	
	success = true;
	
	if(oneshot)
		
		if(use_buffering > 0)
			
			if(use_buffering == 1)
				if(size(buffer_received_bytes{index_buffering},1) == 0)
					length_buffer = 0;
				elseif(size(buffer_received_bytes{index_buffering},1) == 1)
					length_buffer = size(buffer_received_bytes{index_buffering},2);
				else
					length_buffer = size(buffer_received_bytes{index_buffering},1);
				end
				
			elseif(use_buffering == 2 || use_buffering == 3)
				length_buffer = buffer_received_bytes{index_buffering};
			end
			
			if(length_buffer + bytesav > expected_bytes)
				bytesav = expected_bytes - length_buffer;
			end
			
			if(bytesav > 0)

				if(use_buffering == 1)
					
					output_bytes = fread(com_obj, bytesav);
					
					if(size(buffer_received_bytes{index_buffering},1) == 0)
						buffer_received_bytes{index_buffering} = output_bytes;
					elseif(size(buffer_received_bytes{index_buffering},1) == 1)
						buffer_received_bytes{index_buffering} = [buffer_received_bytes{index_buffering} output_bytes];
					else
						buffer_received_bytes{index_buffering} = [buffer_received_bytes{index_buffering}; output_bytes];
					end
					
				elseif(use_buffering == 2  || use_buffering == 3)

					if(buffer_fID{index_buffering} < 0)
						if(length_buffer == 0)
							fID = fopen(sprintf('temp_buf_board%d.dat', index_buffering), 'w+');
						else
							fID = fopen(sprintf('temp_buf_board%d.dat', index_buffering), 'a');
						end
						buffer_fID{index_buffering} = fID;
					end
					
					if(use_buffering == 2)
						output_bytes = fread(com_obj, bytesav);
						fwrite(buffer_fID{index_buffering}, output_bytes);
					else
						if(bytesav >= expected_bytes_bin)
							output_bytes = fread(com_obj, bytesav);
							fwrite(buffer_fID{index_buffering}, output_bytes);
						else
							bytesav = 0;
						end
					end
					
					%fclose(fID);
					
					buffer_received_bytes{index_buffering} = buffer_received_bytes{index_buffering} + bytesav;
					
				end
			end
			
			if(use_buffering == 1)
				bytesav = length(buffer_received_bytes{index_buffering});
			elseif(use_buffering == 2 || use_buffering == 3)
				
				bytesav = buffer_received_bytes{index_buffering};
				
				if(bytesav >= expected_bytes)
					fclose(buffer_fID{index_buffering});
					buffer_fID{index_buffering} = -1;
				end
			end
			
			bytes_percent = 100 * (bytesav / expected_bytes);
		end
		
		if(bytesav < expected_bytes)
			success = false;
		end
		
		if(print_progress)
			fprintf('bytes received: %d / %d (%.1f%%)\n', bytesav, expected_bytes, bytes_percent);
		end
		
		return
	end
	
	waited = 0;
		
	if(print_progress)
		fprintf('bytes received: %d / %d (%.1f%%)\n', bytesav, expected_bytes, bytes_percent);
	end
	
	while(bytesav < expected_bytes)

		bytes_percent = 100 * (bytesav / expected_bytes);
		if(bytes_percent >= (last_percent + last_percent_increment))
			if(print_progress)
				bytes_diff = com_obj.BytesAvailable - bytes_at_start;
				time_diff = toc - time_at_start;
				data_rate = (bytes_diff / 1024^2) / time_diff;
				data_rate_unit = 'Mb';
				if(data_rate < 1)
					data_rate = data_rate * 1024;
					data_rate_unit = 'Kb';
				end
				fprintf('bytes received: %d / %d (%.1f%%) - %.1f %s/s - %.1f s\n', bytesav, expected_bytes, bytes_percent, data_rate, data_rate_unit, time_diff);
			end
			last_percent = last_percent + last_percent_increment;
		end
		
		pause(interval)
		bytesav = com_obj.BytesAvailable;

		if(bytesav == last_bytesav)
			waited = waited + 1;
		else
			last_bytesav = bytesav;
			waited = 0;
		end

		if(timeout_used && waited > timeout_count)
			
			fprintf('timeout (error) after %d bytes (%.1f%%)!\n', bytesav, bytes_percent);
			
			success = false;
			break;
		else
			if(waited > timeout_count)
				fprintf('timeout (warning) after %d bytes (%.1f%%)!\n', bytesav, bytes_percent);
				waited = 0;
			end
		end

	end
	
	if(print_progress)
		bytes_diff = bytesav - bytes_at_start;
		time_diff = toc - time_at_start;
		data_rate = (bytes_diff / 1024^2) / time_diff;
		data_rate_unit = 'Mb';
		if(data_rate < 1)
			data_rate = data_rate * 1024;
			data_rate_unit = 'Kb';
		end
		fprintf('bytes received: %d / %d (%.1f%%) - %.1f %s/s - %.1f s\n', bytesav, expected_bytes, 100 * (bytesav / expected_bytes), data_rate, data_rate_unit, time_diff);
	end
end

