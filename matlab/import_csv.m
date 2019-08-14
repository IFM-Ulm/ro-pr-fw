% exemplary calls:
% import_csv('config.csv', 'netdelays.csv', 'netdelays_ref.csv', 'ro_config.mat', 'netdelays.mat')
% import_csv('config_zybo.csv', 'netdelays_zybo.csv', 'netdelays_ref_zybo.csv', 'ro_config_zybo.mat', 'netdelays_zybo.mat')

function import_csv(filename_config, filename_netdelays, filename_netdelays_ref, savename_config, savename_netdelays)
	
	[ro_bin, ro_constr, ro_map, valid_ind] = import_config(filename_config);
	
	ro_bin_v = ro_bin(valid_ind,:);
	ro_map_v = ro_map(valid_ind,:);
	ro_constr_v = ro_constr(valid_ind,:);
	
	[netdelays, clbtype, slctype, feedback] = import_netdelays(filename_netdelays);
	
	netdelays_v = netdelays(valid_ind,:);
	clbtype_v = clbtype(valid_ind,:);
	slctype_v = slctype(valid_ind,:);
	
	if(~isempty(feedback))
		feedback_v = feedback(valid_ind,:);
	else
		feedback_v = [];
	end
	
	[netdelaysref, clbtype_ref, slctype_ref, feedback_ref] = import_netdelays(filename_netdelays_ref);
	
	save(savename_config, 'ro_bin', 'ro_bin_v', 'ro_constr', 'ro_constr_v', 'ro_map', 'ro_map_v', 'valid_ind', '-v7.3');
	save(savename_netdelays, 'clbtype', 'clbtype_v', 'netdelays', 'netdelays_v', 'slctype', 'slctype_v', 'feedback', 'feedback_v', 'clbtype_ref', 'slctype_ref', 'netdelaysref', 'feedback_ref', '-v7.3');
	
end

