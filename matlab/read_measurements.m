function [temp_data, volt_data, ro_data, ref_data] = read_measurements(filename, filepath_data, overwrite_extract)

	% overwrite_extract
	% < 0 : never extract ro_data, only copy binary files
	%   0 : always extract ro_data
	% > 0 : extract if total number of readout per ro is smaller than overwrite_extract

	if(nargin < 3)
		overwrite_extract = [];
	end
	
	load(filename)
	
	extract_threshold = 11500;
	
	if(~isempty(overwrite_extract))
		if(overwrite_extract < 0)
			extract_ro_data = false;
		elseif(overwrite_extract > 0)
			extract_threshold = overwrite_extract;
			
			if(measurement_number * (repetitions + 1) < extract_threshold)
				extract_ro_data = true;
			else
				extract_ro_data = false;
			end
			
		else
			extract_ro_data = true;
		end
	else
		if(measurement_number * (repetitions + 1) < extract_threshold)
			extract_ro_data = true;
		else
			extract_ro_data = false;
		end
	end
	
	
	if(extract_ro_data)
		ro_data = cell(1, number_bin * ro_per_bin);
		ref_data = cell(1, number_bin * ro_per_bin);
	else
		ro_data = [];
		ref_data = [];
	end
	
	temp_data = cell(1, number_bin * ro_per_bin);
	volt_data = 0;
	
	if(measurement_type == 1)
            read_size = measurement_number * (ro_per_bin + 1) * 4 + 4;
	else
            read_size = 2 * measurement_number * ro_per_bin * 4 + 4;
	end
	

	if(~isempty(filepath_data))
		if(exist(filepath_data, 'file'))
			output_bytes_from_file = true;
			output_bytes_dat_file = filepath_data;
			output_bytes_dat_fID = fopen(output_bytes_dat_file, 'r');
		else
			error('missing .dat file')		
		end
	else
		output_bytes_from_file = false;
		
		if(isempty(output_bytes))
			error('output_bytes empty, missing .dat file')
		end
		
		if(size(output_bytes,2) > 1 && size(output_bytes,1) == 1)
			output_bytes = output_bytes.';
		elseif(size(output_bytes,1) > 1 && size(output_bytes,2) > 1)
			error('wrong byte format')
		end
	end
		
	readOffset = 1;
	
	for bins = [partials_top1 number_partials_top1 + partials_top2]
		
		binIndex = bins;
		
		for ro = 1 : ro_per_bin
			ro_index = (binIndex - 1) * ro_per_bin + ro;
			
			if(extract_ro_data)
				ro_data{ro_index} = zeros(measurement_number, repetitions + 1);
				ref_data{ro_index} = zeros(measurement_number, repetitions + 1);
			end
			
			temp_data{ro_index} = zeros(repetitions + 1, 2);
		end

		for rep = 1 : (repetitions + 1)
			
			if(output_bytes_from_file)
				if(extract_ro_data)
					readData = fread(output_bytes_dat_fID, read_size);
				else
					readData = fread(output_bytes_dat_fID, 4);
					fseek(output_bytes_dat_fID, read_size - 4, 0);
				end
			else
				readData = output_bytes(readOffset : readOffset + read_size - 1,1);
				readOffset = readOffset + read_size;
			end
			
			byteIndex = 1;
			
			temp_start = readData(byteIndex : byteIndex + 1);
			byteIndex = byteIndex + 2;
			temp_end = readData(byteIndex : byteIndex + 1);
			byteIndex = byteIndex + 2;
			
			temp_start = (((temp_start(2) * 2^8 + temp_start(1)) * 503.975) / 65536.0) - 273.15;
			temp_end = (((temp_end(2) * 2^8 + temp_end(1)) * 503.975) / 65536.0) - 273.15;
			
			for ro = 1 : ro_per_bin
				ro_index = (binIndex - 1) * ro_per_bin + ro;
				temp_data{ro_index}(rep, 1) = temp_start;
				temp_data{ro_index}(rep, 2) = temp_end;
			end
			
			if(extract_ro_data)

				for ind = 1 : measurement_number

					if(measurement_type == 1) % parallel readout, one reference value for all readouts

						for ro = 1 : ro_per_bin

							ro_index = (binIndex - 1) * ro_per_bin + ro;

							val_ro = readData(byteIndex : byteIndex + 4 - 1, 1);
							byteIndex = byteIndex + 4;

							ro_val = val_ro(1) + val_ro(2) * 2^8 + val_ro(3) * 2^16 + val_ro(4) * 2^24;

							ro_data{ro_index}(ind, rep) = ro_val;

						end

						val_ref = readData(byteIndex : byteIndex + 4 - 1, 1);
						byteIndex = byteIndex + 4;

						ref_val = val_ref(1) + val_ref(2) * 2^8 + val_ref(3) * 2^16 + val_ref(4) * 2^24;
						for ro = 1 : ro_per_bin
							ro_index = (binIndex - 1) * ro_per_bin + ro;

							ref_data{ro_index}(ind, rep) = ref_val;
						end

					else % serial readout, each readout has its own reference value

						for ro = 1 : ro_per_bin

							ro_index = (binIndex - 1) * ro_per_bin + ro;

							val_ro = readData(byteIndex : byteIndex + 4 - 1, 1);
							byteIndex = byteIndex + 4;

							ro_val = val_ro(1) + val_ro(2) * 2^8 + val_ro(3) * 2^16 + val_ro(4) * 2^24;
							ro_data{ro_index}(ind, rep) = ro_val;

							val_ref = readData(byteIndex : byteIndex + 4 - 1, 1);
							byteIndex = byteIndex + 4;

							ref_val = val_ref(1) + val_ref(2) * 2^8 + val_ref(3) * 2^16 + val_ref(4) * 2^24;
							ref_data{ro_index}(ind, rep) = ref_val;
						end

					end

				end
			
			end
			
		end

	end

	if(output_bytes_from_file)
		fclose(output_bytes_dat_fID);
	else
	
end

