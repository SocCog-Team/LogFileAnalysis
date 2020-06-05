function [ out_struct, session_id, out_session_id_list, out_session_struct_list ] = fn_merge_session_struct_list( merge_session_id, merge_session_dir, session_struct_list, session_id_list )
%FN_MERGE_SESSION_STRUCT_LIST Summary of this function goes here
%   Detailed explanation goes here

out_struct = struct();
session_id = merge_session_id;
out_session_id_list = [];
out_session_struct_list = [];


n_sessions = numel(session_struct_list);

if (n_sessions == 0)
	disp('Empty session_struct_list, nothing to merge...');
	session_id = [];
	return
elseif (n_sessions == 1)
	out_struct = session_struct_list{1};
	session_id = merge_session_id;
	
	out_struct.merged_session_id_list = session_id_list;
else
	% this is the normal case
	session_id = merge_session_id;
	out_struct = fn_merge_outstruct_list(session_struct_list);
end



% also fill the struct versions
out_session_struct_list{end+1} = out_struct;
out_session_id_list{end+1} = session_id;

% now save the merged files
log_file_list = fieldnames(out_struct);
n_log_files = length(log_file_list);

% allow .sessiondir extensions...
[~, tmp_cur_session_id, session_dir_extension] = fileparts(merge_session_id);
if strcmp(session_dir_extension, '.sessiondir')
	merge_session_id = tmp_cur_session_id;
end



% now save out the actual files
for i_log = 1 : n_log_files
	cur_struct = out_struct.(log_file_list{i_log});
	cur_struct.merged_session_id_list = session_id_list;	% save
	[src_dir, src_name, src_ext] = fileparts(cur_struct.src_fqn);
	% for tracker and signal log get the tracker ID
	if ismember(src_ext, {'.signallog', '.trackerlog'})
		TID_idx = regexp(src_name, '.TID_');
		tracker_TID = src_name(TID_idx:end);
	end
	
	if ~isempty(regexp(cur_struct.src_fqn, '.triallog'))
		% the triallog file
		log_type = 'triallog';
		[~, report_parser_version_string] = fnParseEventIDEReportSCPv06([]);
		cur_log_mat_fqn = fullfile(merge_session_dir, [merge_session_id, '.triallog', report_parser_version_string, '.mat']);
		report_struct = cur_struct;
		cur_struct_name = 'report_struct';
	elseif ~isempty(regexp(cur_struct.src_fqn, '.signallog'))
		log_type = 'signallog';
		[~, trackerlog_parser_version_string] = fnParseEventIDETrackerLog_v01([]);
		cur_log_mat_fqn = fullfile(merge_session_dir, 'trackerlogfiles', [merge_session_id, tracker_TID,'.signallog', trackerlog_parser_version_string, '.mat']);
		data_struct = cur_struct;
		cur_struct_name = 'data_struct';
	elseif ~isempty(regexp(cur_struct.src_fqn, '.trackerlog'))
		log_type = 'trackerlog';
		[~, trackerlog_parser_version_string] = fnParseEventIDETrackerLog_v01([]);
		cur_log_mat_fqn = fullfile(merge_session_dir, 'trackerlogfiles', [merge_session_id, tracker_TID, '.trackerlog', trackerlog_parser_version_string, '.mat']);
		data_struct = cur_struct;
		cur_struct_name = 'data_struct';
	end
	%
	if ~isempty(cur_struct.data)
		disp(['Saving merged session ', log_type, ' as: ', cur_log_mat_fqn]);
		[tmp_out_dir, tmp_out_name, tmp_out_ext] = fileparts(cur_log_mat_fqn);
		disp(['ID: ', tmp_out_name, tmp_out_ext]);
		if isempty(dir(tmp_out_dir)),
			mkdir(tmp_out_dir);
		end
		save(cur_log_mat_fqn, cur_struct_name, '-v7.3');
	end
end

return
end


function [ out_struct ] = fn_merge_outstruct_list( session_struct_list )
% the heavy lifting, merge sessions...

global_reference_date_string = '20100101T000000.001';	% take one millisecond after midnight January first 2010 as reference date
out_struct = struct();


n_sessions = numel(session_struct_list);

% keep continupus trial numbers over all sessions
aggregate_trial_offset = 0;

for i_sess = 1 : n_sessions
	cur_sess_struct = session_struct_list{i_sess};
	disp(['Processing: ', num2str(i_sess), '. file in merge list: ', cur_sess_struct.triallog.LoggingInfo.SessionLogFileName]);
	[timestamp_additive_correction_offset, first_eventIDE_timestamp, first_adjusted_system_time_ms, first_system_time_string] = fn_get_eventIDE_and_system_time_from_trialllog_struct(cur_sess_struct.triallog, global_reference_date_string);
		
	% correct cur_sess_struct timestamps and trial numbers
	cur_adjusted_sess_struct = fn_correct_timestamps_and_trialnumbers(cur_sess_struct, timestamp_additive_correction_offset, aggregate_trial_offset);
	% track the trialnumbers, incomplete trials can have 0 as
	% trialnumber...
	aggregate_trial_offset = max(cur_adjusted_sess_struct.triallog.data(:, cur_adjusted_sess_struct.triallog.cn.TrialNumber));
	
		
	if (i_sess == 1)
		out_struct = cur_adjusted_sess_struct;
	else
		% merge the time and trialnumber adjusted cur_sess_struct into out_struct
		% check for missing comuns and other clashes?
		log_file_list = fieldnames(cur_adjusted_sess_struct);
		n_log_files = length(log_file_list);

		for i_log = 1 : n_log_files
			cur_log_type = log_file_list{i_log};
			cur_log = cur_adjusted_sess_struct.(log_file_list{i_log});
			disp(['Merging: ', log_file_list{i_log}]);
			
			% if the old entry for cur_log_type was empty, just replace
			% with the current
			if isempty(out_struct.(cur_log_type).data)
				out_struct.(cur_log_type) = cur_adjusted_sess_struct.(cur_log_type);
				disp(['Missing ', cur_log_type, ' data record in early sessions...']);
				continue
			end
			
			
			% check header equality, and if equal merge
			if isfield(cur_log, 'header') && isfield(cur_log, 'data') && ~isempty(cur_log.data)
				if isequal(cur_log.header, out_struct.(cur_log_type).header)
					[out_struct.(cur_log_type), new_data_struct.(cur_log_type)] = fn_merge_indexed_cols_and_unique_lists(out_struct.(cur_log_type), cur_adjusted_sess_struct.(cur_log_type));
					out_struct.(cur_log_type).data = [out_struct.(cur_log_type).data; new_data_struct.(cur_log_type).data];
					out_struct.(cur_log_type).first_empty_row_idx = size(out_struct.(cur_log_type).data, 1) + 1;
				else
					error('To be merged data tables have unequal column make-up, FIXME');
				end
			end
			
			% now process other record types
			record_type_list = fieldnames(cur_log);
			for i_record_type = 1 : length(record_type_list)
				cur_record_type = record_type_list{i_record_type};
				cur_record = cur_log.(cur_record_type);
				% only correct columns in the data records
				if (isfield(cur_record, 'header') && isfield(cur_record, 'data')) && ~isempty(cur_record.data)
					if isequal(cur_record.header, out_struct.(cur_log_type).(cur_record_type).header)
						[out_struct.(cur_log_type).(cur_record_type), new_data_struct.(cur_log_type).(cur_record_type)] = fn_merge_indexed_cols_and_unique_lists(out_struct.(cur_log_type).(cur_record_type), cur_adjusted_sess_struct.(cur_log_type).(cur_record_type));
						out_struct.(cur_log_type).(cur_record_type).data = [out_struct.(cur_log_type).(cur_record_type).data; new_data_struct.(cur_log_type).(cur_record_type).data];
						out_struct.(cur_log_type).(cur_record_type).first_empty_row_idx = size(out_struct.(cur_log_type).(cur_record_type).data, 1) + 1;
					else
						error('To be merged data tables have unequal column make-up, FIXME');
					end
				else
					% for non-data carrying record types just create lists
					% of the individual copies
					if ismember(cur_record_type, {'data'})
						% nothing to do
					else
						if ~isfield(out_struct.(cur_log_type), 'InfoRecordsBySessionList')
							out_struct.(cur_log_type).InfoRecordsBySessionList = [];
						end
						if ~isfield(out_struct.(cur_log_type).InfoRecordsBySessionList, cur_record_type)
							out_struct.(cur_log_type).InfoRecordsBySessionList.(cur_record_type) = [];
							% copy the data itmes from the first session to cell # 1
							out_struct.(cur_log_type).InfoRecordsBySessionList.(cur_record_type){end+1} = out_struct.(cur_log_type).(cur_record_type);
						end
						out_struct.(cur_log_type).InfoRecordsBySessionList.(cur_record_type){end+1} = cur_record;
					end
				end
			end
			
			
			% 		[out_struct, new_data_struct] = fn_merge_indexed_cols_and_unique_lists(out_struct, cur_adjusted_sess_struct);
			% 		tmp_maintask_datastruct.report_struct = new_data_struct;
			% 		% Reward substruct
% 		[out_struct.Reward, new_data_struct] = fn_merged_indexed_cols_and_unique_lists(out_struct.Reward, cur_adjusted_sess_struct.Reward);
% 		tmp_maintask_datastruct.report_struct.Reward = new_data_struct;
% 		% Stimuli substruct
% 		[out_struct.Stimuli, new_data_struct] = fn_merged_indexed_cols_and_unique_lists(out_struct.Stimuli, tmp_maintask_datastruct.report_struct.Stimuli);
% 		tmp_maintask_datastruct.report_struct.Stimuli = new_data_struct;
% 
% 		out_struct.data = [out_struct.data; tmp_main_dataStruct.data];
% 		out_struct.Reward.data = [out_struct.Reward.data; tmp_main_dataStruct.Reward.data];
% 		out_struct.Stimuli.data = [out_struct.Stimuli.data; tmp_main_dataStruct.Stimuli.data];
% 		
% 		dataStruct.data = [dataStruct.data; tmp_dataStruct.data];
% 		touch_A_Struct.data = [touch_A_Struct.data; tmp_touch_A.data];
% 		touch_B_Struct.data = [touch_B_Struct.data; tmp_touch_B.data];
% 		recalibration_struct.data = [recalibration_struct.data ; tmp_recalibration_struct.data];

		end
		
	end
end

return
end


function [ timestamp_additive_correction_offset, first_eventIDE_timestamp, first_adjusted_system_time_ms, first_system_time_string ] = fn_get_eventIDE_and_system_time_from_trialllog_struct( cur_triallog, global_reference_date_string )
% eventIDE timestamps are all over the place from zero based to global time
% stamps either year 0 based or 1970 based, so correct all of this, right
% now, right here.

first_eventIDE_timestamp = [];
first_system_time = [];
first_system_time_string = '';

% get the time of the first trial in eventIDE and System wall clock time
if isfield(cur_triallog, 'Timing') && ~isempty(cur_triallog.Timing)
	first_eventIDE_timestamp = cur_triallog.Timing.data(1, cur_triallog.Timing.cn.Timestamp);
	first_system_time_string = cur_triallog.Timing.unique_lists.SystemTime(cur_triallog.Timing.data(1, cur_triallog.Timing.cn.SystemTime_idx));
else
	% okay, precise timing is missing, so take the eventIDE time from the
	% first trial and the time from the log file creation, which will be
	% slightly off
	first_eventIDE_timestamp = cur_triallog.data(1, cur_triallog.cn.Timestamp);
	first_system_time_string = cur_triallog.LoggingInfo.SessionLogFileName(1:regexp(cur_triallog.LoggingInfo.SessionLogFileName, '.A_')-1);
	first_system_time_string = [first_system_time_string, '.000000'];
end

% convert the systemtime string into something meaningful
first_system_time_datenum_fractional_days = datenum(first_system_time_string, 'yyyymmddTHHMMSS.FFF');
global_reference_date_datenum_fractional_days = datenum(global_reference_date_string, 'yyyymmddTHHMMSS.FFF');

% this is the reference
delta_datenum_fractional_days = first_system_time_datenum_fractional_days - global_reference_date_datenum_fractional_days;

first_adjusted_system_time_ms = delta_datenum_fractional_days * (24 * 60 * 60 * 1000);

% add this to the eventIDE timestamps to get global coordinated times.
timestamp_additive_correction_offset = first_adjusted_system_time_ms - first_eventIDE_timestamp;

return
end

function [ 	cur_sess_struct ] = fn_correct_timestamps_and_trialnumbers( cur_sess_struct, timestamp_additive_correction_offset, aggregate_trial_offset )
% find columns with timestamps and trialnumbers and add the respective
% offsets

%
log_file_list = fieldnames(cur_sess_struct);
n_log_files = length(log_file_list);

for i_log = 1 : n_log_files
	cur_log = cur_sess_struct.(log_file_list{i_log});
	disp(['Adjusting timestamps and trialnumbers: ', log_file_list{i_log}]);
	% store information about the adjustments
	cur_log.MergeInfo.timestamp_additive_correction_offset = timestamp_additive_correction_offset;
	cur_log.MergeInfo.aggregate_trial_offset = aggregate_trial_offset;
	
	
	% now find candidate subfields for corrections
	record_type_list = fieldnames(cur_log);
	for i_record_type = 1 : length(record_type_list)
		% we need to fixup timestamp and trialnumber fields in data tables
		cur_record_type = record_type_list{i_record_type};
		cur_record = cur_log.(cur_record_type);
		% only correct columns in the data records
		if isfield(cur_record, 'data') || strcmp(cur_record_type, 'data')
			if strcmp(cur_record_type, 'data')
				cur_header = cur_log.header;
				cur_log.MergeInfo.adjusted_timestamp_col_names = [];
				cur_log.MergeInfo.adjusted_trialnumber_col_names = [];
				is_main_data = 1;
			else
				cur_header = cur_record.header;
				is_main_data = 0;
				cur_record.MergeInfo.timestamp_additive_correction_offset = timestamp_additive_correction_offset;
				cur_record.MergeInfo.aggregate_trial_offset = aggregate_trial_offset;
				cur_record.MergeInfo.adjusted_timestamp_col_names = [];
				cur_record.MergeInfo.adjusted_trialnumber_col_names = [];
			end
			
			% find and correct timestamp related fields
			matching_ts_header_col_idx_list = regexp(cur_header, '[tT]ime_ms|Timestamp|EventIDE_TimeStamp'); % ATM all relevant columns are contain either Timestamp or Time_ms in the column name
			for i_header_col = 1 : length(matching_ts_header_col_idx_list)
				% now correct to be corrected columns while saving the
				% column names
				if ~isempty(matching_ts_header_col_idx_list{i_header_col})
					if (is_main_data)
						cur_log.MergeInfo.adjusted_timestamp_col_names{end+1} = cur_header{i_header_col};
						if ~isempty(cur_log.data)
							cur_log.data(:, i_header_col) = cur_log.data(:, i_header_col) + timestamp_additive_correction_offset;
						end
					else
						cur_record.MergeInfo.adjusted_timestamp_col_names{end+1} = cur_header{i_header_col};
						if ~isempty(cur_record.data)
							cur_record.data(:, i_header_col) = cur_record.data(:, i_header_col) + timestamp_additive_correction_offset;
						end
					end
				end
			end
			
			% find and correct trialnumber related fields
			matching_tn_header_col_idx_list = regexp(cur_header, '[tT]rial[nN]umber|TrialNum'); % ATM all relevant columns are contain either TrialNumber in the column name
			for i_header_col = 1 : length(matching_tn_header_col_idx_list)
				% now correct to be corrected columns while saving the
				% column names
				if ~isempty(matching_tn_header_col_idx_list{i_header_col})
					if (is_main_data)
						cur_log.MergeInfo.adjusted_trialnumber_col_names{end+1} = cur_header{i_header_col};
						if ~isempty(cur_log.data)
							% allow for trialnumber zero but conserve
							zero_trialnum_idx = find(cur_log.data(:, i_header_col) == 0);
							cur_log.data(:, i_header_col) = cur_log.data(:, i_header_col) + aggregate_trial_offset;
							if ~isempty(zero_trialnum_idx)
								cur_log.data(zero_trialnum_idx, i_header_col) = 0;
							end
						end
					else
						cur_record.MergeInfo.adjusted_trialnumber_col_names{end+1} = cur_header{i_header_col};
						if ~isempty(cur_record.data)
							% allow for trialnumber zero but conserve
							zero_trialnum_idx = find(cur_record.data(:, i_header_col) == 0);
							cur_record.data(:, i_header_col) = cur_record.data(:, i_header_col) + aggregate_trial_offset;
							if ~isempty(zero_trialnum_idx)
								cur_record.data(zero_trialnum_idx, i_header_col) = 0;
							end
						end
					end
				end
			end
			
			%
			if (is_main_data)
				% nothing to do...
			else
				cur_log.(cur_record_type) = cur_record;
			end
		end
	end
	% save modified data back to struct
	cur_sess_struct.(log_file_list{i_log}) = cur_log;
end

return
end


function [out_list, in_list_idx] = fnUnsortedUnique(in_list)
% unsorted_unique auto-undo the sorting in the return values of unique
% the outlist gives the unique elements of the in_list at the relative
% position of the last occurrence in the in_list, in_list_idx gives the
% index of that position in the in_list

[sorted_unique_list, sort_idx] = unique(in_list);
[in_list_idx, unsort_idx] = sort(sort_idx);
out_list = sorted_unique_list(unsort_idx);

return
end

function [columnnames_struct, n_fields] = local_get_column_name_indices(name_list, start_val)
% return a structure with each field for each member if the name_list cell
% array, giving the position in the name_list, then the columnnames_struct
% can serve as to address the columns, so the functions assigning values
% to the columns do not have to care too much about the positions, and it
% becomes easy to add fields.
% name_list: cell array of string names for the fields to be added
% start_val: numerical value to start the field values with (if empty start
%            with 1 so the results are valid indices into name_list)

if nargin < 2
	start_val = 1;  % value of the first field
end
n_fields = length(name_list);
for i_col = 1 : length(name_list)
	cur_name = name_list{i_col};
	% skip empty names, this allows non consequtive numberings
	if ~isempty(cur_name)
		columnnames_struct.(cur_name) = i_col + (start_val - 1);
	end
end
return
end



function [ existing_data_struct, new_data_struct ] = fn_merge_indexed_cols_and_unique_lists( existing_data_struct, new_data_struct )
% note this potentially changes existing_data_struct unique_lists and
% matching indexed fields

idx_col_list = regexp(new_data_struct.header, '_idx$');

for i_idx_col = 1 : length(idx_col_list)
	if ~isempty(idx_col_list{i_idx_col})
		current_col_name = new_data_struct.header{i_idx_col};
		
		if isempty(regexp(current_col_name, 'ENUM_idx$'));
			%disp(['Non ENUM _idx column: ', current_col_name]);
			unique_list_name = current_col_name(1:end-4);
			
			tmp_main_cur_col_idx_list = (existing_data_struct.data(:, existing_data_struct.cn.(current_col_name)));
			tmp_main_cur_col_idx_list_zero_idx = find(tmp_main_cur_col_idx_list == 0);
			if ~isempty(tmp_main_cur_col_idx_list_zero_idx)
				existing_data_struct.data(tmp_main_cur_col_idx_list_zero_idx, existing_data_struct.cn.(current_col_name)) = length(existing_data_struct.unique_lists.(unique_list_name)) + 1;
				existing_data_struct.unique_lists.(unique_list_name){end+1} ='EMPTY';
			end
			
			tmp_main_cur_col_idx_list = (new_data_struct.data(:, new_data_struct.cn.(current_col_name)));
			tmp_main_cur_col_idx_list_zero_idx = find(tmp_main_cur_col_idx_list == 0);
			if ~isempty(tmp_main_cur_col_idx_list_zero_idx)
				new_data_struct.data(tmp_main_cur_col_idx_list_zero_idx, new_data_struct.cn.(current_col_name)) = length(new_data_struct.unique_lists.(unique_list_name)) + 1;
				new_data_struct.unique_lists.(unique_list_name){end+1} = 'EMPTY';
			end
			
			
			existing_data_struct_cur_idx_col_list = existing_data_struct.unique_lists.(unique_list_name)(existing_data_struct.data(:, existing_data_struct.cn.(current_col_name)));
			new_data_struct_cur_idx_col_list = new_data_struct.unique_lists.(unique_list_name)(new_data_struct.data(:, new_data_struct.cn.(current_col_name)));
			
			
			if size(existing_data_struct_cur_idx_col_list, 1) < size(existing_data_struct_cur_idx_col_list, 2)
				existing_data_struct_cur_idx_col_list = existing_data_struct_cur_idx_col_list';
			end
			if size(new_data_struct_cur_idx_col_list, 1) < size(new_data_struct_cur_idx_col_list, 2)
				new_data_struct_cur_idx_col_list = new_data_struct_cur_idx_col_list';
			end
			
			tmp_list = [existing_data_struct_cur_idx_col_list; new_data_struct_cur_idx_col_list];
			[out_list, in_list_idx] = fnUnsortedUnique(tmp_list);
			
			existing_data_struct.unique_lists.(unique_list_name) = out_list';
			tmp_idx = zeros(size(tmp_list));
			for i_unique_val = 1 : length(out_list)
				unique_val_idx = strcmp(tmp_list, out_list{i_unique_val});
				tmp_idx(unique_val_idx) = i_unique_val;
			end
			
			existing_data_struct.data(:, existing_data_struct.cn.(current_col_name)) = tmp_idx(1: size(existing_data_struct.data, 1));
			new_data_struct.data(:, new_data_struct.cn.(current_col_name)) = tmp_idx(size(existing_data_struct.data, 1) + 1 : end);
			
		end
	end
end
%tmp_maintask_datastruct.report_struct = new_data_struct;

return
end
