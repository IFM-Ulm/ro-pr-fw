% parameters
% top_folder - folder where the measurement results (from fw_meas_control) are stored (can be in sub-folders)
% save_folder - target folder to store the extracted measurements
% move_folder - target folder where to move the processed files
% overwrite_extract - numberic value indicating if huge measurements should be extracted or left untouched as binary files

function read_data(top_folder, save_folder, move_folder, overwrite_extract)
	
	if(nargin < 3)
		error('wrong amount of arguments, provide top_folder, save_folder and move_folder')
	end

	if(nargin < 4)
		overwrite_extract = [];
	end
	
	searchpattern = '*.mat';
	if(~isempty(top_folder))
		searchpattern = sprintf('%s/%s', top_folder, searchpattern);
	end
	
	files = dir(searchpattern);
	fprintf('searching %s\n', searchpattern);
	for f = 1 : size(files,1)
				
		filename = files(f).name;
		filefolder = normalizeFolder(files(f).folder);
		filepath = sprintf('%s/%s', filefolder, filename);
		
		fprintf('checking file %s\n', filename);
		pause(0.01)

		load(filepath, 'board_id', 'identifier', 'board_type', 'data_file', 'date_str', 'measurement_number', 'repetitions', 'measurement_time', 'measurement_time_string', ...
			'measurement_type', 'measurement_type_string', 'number_bin', 'ro_per_bin', 'partials_top1', 'partials_top2', 'temperature', 'heatup', 'cooldown');
		
		switch(identifier)
			case 'temperature'
				sub_folder = sprintf('temperature/t%02d', temperature);
			otherwise
				sub_folder = identifier;	
		end
		
		board_folder = board_type;
		
		switch(board_type)
			
			case 'zybo'

				load('ro_config_ro4_zybo.mat');
				load('netdelays_ro4_zybo.mat');
				
			case 'pynq'

				load('ro_config_ro4_pynq.mat');
				load('netdelays_ro4_pynq.mat');
			
			case 'zyboz720'

				load('ro_config_ro4_zyboz720.mat');
				load('netdelays_ro4_zyboz720.mat');
				
			otherwise
				error('unknown board_type: %s', board_type)
				
		end
		
		id_folder = sprintf('b%02d', board_id);
		
		save_path = sprintf('%s/%s/%s/%s', save_folder, board_folder, sub_folder, id_folder);
		
		save_name = sprintf('mode_%d_time_%.0fus_meas_%s.mat', measurement_type, measurement_time*1e6, date_str);
		
		save_full = sprintf('%s/%s', save_path, save_name);
		
		if(~isempty(data_file))
			filepath_data = sprintf('%s/%s', filefolder, data_file);
		else
			filepath_data = '';
		end
		
		if(exist(save_full, 'file'))
			fprintf('\tfile already extracted, skipping\n\n');
			continue
		end
		
		fprintf('\textracting data\n');
		
		[temp_data, volt_data, ro_data_all, ref_data_all] = read_measurements(filepath, filepath_data, overwrite_extract);
		
		ind_vector = find(ro_map(:,4)==1);
		
		ro_x = ro_map(ind_vector, 2);
		ro_x = ro_x.';
		ro_y = ro_map(ind_vector, 3);
		ro_y = ro_y.';

		if(~isempty(ro_data_all))
			ro_data = ro_data_all(1, ind_vector);
			ref_data = ref_data_all(1, ind_vector);
			data_file_old = data_file;			
			data_file = '';			
		else
			ro_data = [];
			ref_data = [];
			data_file_old = '';
		end
		
		temp_data = temp_data(1, ind_vector);

		id = filename;
		impl = 'ro4';
		version = '20190801';

		if(~exist(save_path, 'dir'))
			mkdir(save_path)
		end
		
		fprintf('\tsaving data as:\n\t\t%s\n\t\t%s\n', save_name, save_path);

		save(save_full, 'impl', 'heatup', 'cooldown', 'identifier', 'board_type', 'data_file', 'data_file_old', 'date_str', 'id', 'measurement_number', 'repetitions', 'measurement_time', 'measurement_time_string', ...
			'measurement_type', 'measurement_type_string', 'number_bin', 'ro_per_bin', 'partials_top1', 'partials_top2', 'temperature', ...
			'ro_data', 'ref_data', 'ro_x', 'ro_y', 'temp_data', 'volt_data', 'ind_vector', 'version', '-v7.3');
		
		fprintf('\tmoving .mat file to:\n\t\t%s\n', move_folder);
		movefile(filepath, sprintf('%s/%s', move_folder, filename));
		if(~isempty(ro_data))
			fprintf('\tmoving .dat file to:\n\t\t%s\n', move_folder);
			movefile(filepath_data, sprintf('%s/%s', move_folder, data_file));
		else
			fprintf('\tmoving .dat file to:\n\t\t%s\n', save_path);
			movefile(filepath_data, sprintf('%s/%s', save_path, data_file));
		end
		fprintf('\tdone\n\n');
	end

	
	%% recursion
	files = dir(top_folder);
	for f = 1 : size(files,1)

		foldername = files(f).name;

		if(strcmp(foldername, '.'))
			continue
		end
		
		if(strcmp(foldername, '..'))
			continue
		end

		if(strncmp(foldername, 'extracted', length('extracted')))
			continue
		end
		
		if(strcmp(foldername, 'old'))
			continue
		end
				
		folder = sprintf('%s/%s', top_folder, foldername);
		if(exist(folder, 'dir'))
			read_data(folder, save_folder, move_folder, overwrite_extract)
		end

	end
	
end



