function [ro_bin, ro_constr, ro_map, valid_ind] = import_config(filename)

%% Initialize variables.
delimiter = ',';


%% Format for each line of text:
%   column1: text (%s)
%	column2: text (%s)
%   column3: double (%f)
%	column4: double (%f)
%   column5: double (%f)
%	column6: double (%f)
% For more information, see the TEXTSCAN documentation.
% formatSpec = '%s%s%f%f%f%f%[^\n\r]'; old variant, also reads end-of-line
formatSpec = '%s%s%f%f%f%f';

%% Open the text file.
fileID = fopen(sprintf('%s\\%s', pwd, filename),'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'HeaderLines', 1, 'ReturnOnError', false, 'EndOfLine', '\r\n');

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post
% processing code is included. To generate code which works for
% unimportable data, select unimportable cells in a file and regenerate the
% script.

%% Create output variable
dataArray([3, 4, 5, 6]) = cellfun(@(x) num2cell(x), dataArray([3, 4, 5, 6]), 'UniformOutput', false);
config = [dataArray{1:end}];

ro_map = cell2mat(config(:,3:6));
valid = cell2mat(config(:,6));
[valid_ind,~] = find(valid==1);
ro_bin = config(:,2);
ro_constr = config(:,1);

end