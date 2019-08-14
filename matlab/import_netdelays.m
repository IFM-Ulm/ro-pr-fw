function [netdelays, clb_type, slc_type, feedback] = import_netdelays(filename)

%% Open the text file.
fileID = fopen(filename,'r');

%% test for version
test_line = fgets(fileID);
frewind(fileID);

spaceFound = false;
counter = 0;

for t = 1 : size(test_line,2)
	if(test_line(1,t) == ',')
		counter = counter + 1;
	end
	if(test_line(1,t) == ' ')
		spaceFound = true;
	end
end

if(spaceFound)
	error('new format of netdelays found but whitespace not replaced with '','': open the text file and manually replace each ''space'' with '',''');
end

if(counter ~= 23)
	error('unknown netdelay format');
end

%% set delimiter and format
% expected input example: 99,117,234,280,58,67,135,159,157 70,187 79,376 147,455 172,236,287,559,684,1,1,child_impl_1_constr_00_0000,0
formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%s%f';

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.

dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'HeaderLines', 0, 'ReturnOnError', false, 'EndOfLine', '\r\n');

%% Close the text file.
fclose(fileID);

%% Create output variable
netdelays = cellfun(@(x) num2cell(x), dataArray([1:8 9 11 13 15 17:20]), 'UniformOutput', false);
netdelays = cell2mat([netdelays{1:end}]);
feedback = cellfun(@(x) num2cell(x), dataArray([10 12 14 16]), 'UniformOutput', false);
feedback = cell2mat([feedback{1:end}]);
clb_type = cellfun(@(x) num2cell(x), dataArray(21), 'UniformOutput', false);
clb_type = cell2mat([clb_type{1:end}]);
slc_type = cellfun(@(x) num2cell(x), dataArray(22), 'UniformOutput', false);
slc_type = cell2mat([slc_type{1:end}]);

end





