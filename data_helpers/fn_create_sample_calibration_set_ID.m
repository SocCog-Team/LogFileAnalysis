function [ out_data_struct ] = fn_create_sample_calibration_set_ID( tracker_type, data_struct )
%FN_CREATE_SAMPLE_CALIBRATION_SET_ID Summary of this function goes here
%   Different trackerlog types contain different sets of rows that require
%   matching sets of calbrating transformations. Here we try to generate a
%   column containing that information, so we can simply use that in
%   consumers like the generation of calibrations and the application of
%   same...

out_data_struct = data_struct;
n_samples = size(out_data_struct.data, 1);


% error out for unhandled types
switch tracker_type
	case 'eyelink'
		% all records are identical, but still add this to make the
		% consumer code simpler...
		% define calibration_set_ID_list
		calibration_set_ID_idx_list = ones([n_samples, 1]);
		if size(calibration_set_ID_idx_list, 1) < size(calibration_set_ID_idx_list, 2)
			calibration_set_ID_idx_list = calibration_set_ID_idx_list';
		end		
		unique_claibration_set_ID = {'ALL'};
		calibration_set_ID_list = unique_claibration_set_ID(calibration_set_ID_idx_list);
		
	case 'pupillabs'
		% two eye cameras, world camera fiducial/surfaces
		% collect the names of data columns containing registerable data
		%% these are just for documentation...
% 		data_struct.cn.Source_ID
% 		data_struct.cn.Sample_Type_idx
% 		data_struct.cn.Fiducial_Surface_idx
% 		data_struct.cn.Detection_Method_idx
% 
% 		data_struct.unique_lists.Sample_Type
% 		data_struct.unique_lists.Fiducial_Surface
% 		data_struct.unique_lists.Detection_Method
		
		% construct a string out of the relevant columns to identify
		% to make things easy we will use unique to index these, but that
		% means we really need a cell of strings
		
		% mandatory, so needs to exist
		% value mapping: 0, 1 -> Pupil[0|1], 2 World Gaze; 3 Fiducial Gaze
		Source_ID_idx_list = data_struct.data(:, data_struct.cn.Source_ID);
		Source_ID_list = cellstr(num2str(Source_ID_idx_list));
		if size(Source_ID_list, 1) < size(Source_ID_list, 2)
			Source_ID_list = Source_ID_list';
		end
		
		
		% mandatory, needs to exist
		Sample_Type_idx_list = data_struct.data(:, data_struct.cn.Sample_Type_idx);
		Sample_Type_list = data_struct.unique_lists.Sample_Type(Sample_Type_idx_list);
		if size(Sample_Type_list, 1) < size(Sample_Type_list, 2)
			Sample_Type_list = Sample_Type_list';
		end
		
		% optional, only for fiducial, otherwise the idx value is all zeros
		Fiducial_Surface_idx_list = data_struct.data(:, data_struct.cn.Fiducial_Surface_idx);
		tmp_data_struct_unique_lists_Fiducial_Surface = ['NoSurface', data_struct.unique_lists.Fiducial_Surface];	% replace zero indices by empty strings does not work
		Fiducial_Surface_list =  tmp_data_struct_unique_lists_Fiducial_Surface(Fiducial_Surface_idx_list + 1);
		if size(Fiducial_Surface_list, 1) < size(Fiducial_Surface_list, 2)
			Fiducial_Surface_list = Fiducial_Surface_list';
		end		
		
		% mixed, contains Zeros, index to NONE
		Detection_Method_idx_list = data_struct.data(:, data_struct.cn.Detection_Method_idx);
		tmp_data_struct_unique_lists_Detection_Method = ['NoDetectionMethod', data_struct.unique_lists.Detection_Method];	% replace zero indices by empty strings
		Detection_Method_list = tmp_data_struct_unique_lists_Detection_Method(Detection_Method_idx_list + 1);
		if size(Detection_Method_list, 1) < size(Detection_Method_list, 2)
			Detection_Method_list = Detection_Method_list';
		end		
		
		% collect the unique IDs, but keep the Source_ID_list order
		% just prefix Source_ID_list to keep a more static order
		calibration_set_ID_list = strcat(Source_ID_list, Sample_Type_list, '_', Source_ID_list, '_', Fiducial_Surface_list, '_', Detection_Method_list);
		[unique_calibration_set_IDs, calibration_set_ID_list_ia, calibration_set_ID_idx_list] = unique(calibration_set_ID_list, 'stable');
		% remove the prefixed Source_ID from the start of the names
		for i_calibration_set = 1 : length(unique_calibration_set_IDs)
			unique_calibration_set_IDs{i_calibration_set} = unique_calibration_set_IDs{i_calibration_set}(2:end);
		end
% 		% now make these suitable as matlab variable names
% 		sanitized_unique_calibration_set_IDs = fn_sanitize_string_as_matlab_variable_name(unique_calibration_set_IDs);
		
	case 'pqlab'
		% Nothing to do here, these have a fixed calibration, do we really
		% want to change these? Probably not, as the original calibration
		% was actually in effect during the experiement for determining
		% target choices.
		return
	case 'nisignalfilewriter'
		% Nothing to do here, no calibration applicable
		return
	otherwise
		error([mfilename, ': Encountered unhandled tracker type: ', tracker_name, ' please handle gracefully']);
end


% now add the calibration_set_ID_idx column to the data and the unique
% lists
out_data_struct = fn_handle_data_struct('add_columns', out_data_struct, calibration_set_ID_list, {'calibration_setID_idx'});
% now make these suitable as matlab variable names
%out_data_struct.unique_lists.calibration_setID = out_data_struct.unique_lists.calibration_setID;
out_data_struct.unique_lists.calibration_setID_sanitized = fn_sanitize_string_as_matlab_variable_name(out_data_struct.unique_lists.calibration_setID);

return
end

