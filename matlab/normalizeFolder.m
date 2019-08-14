function [ folder_out ] = normalizeFolder( folder_in )
	
	folder_out = strrep(folder_in, '\', '/');
	if(folder_out(size(folder_out,2)) == '/')
		folder_out = folder_out(1:size(folder_out,2)-1);
	end
	
end

