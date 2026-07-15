function [ output_struct ] = fnFixEventIDEReportData( input_struct, fixup_struct )
%FNFIXEVENTIDEREPORTDATA Specific corrections of EventIDE report files
%   Detailed explanation goes here
output_struct = input_struct;

if isfield(output_struct, 'FixUpReport')
	disp([mfilename, ': WARN: input data already contained a FixUpReport, that is not expected, so we clear this out']);
end
output_struct.FixUpReport = {};	% note, this is the only place intended to write FixUpReport

% robustly estimate the session date
if isfield(input_struct.LoggingInfo, 'SessionDate')
	date_num = str2double(input_struct.LoggingInfo.SessionDate);
elseif isfield(input_struct.EventIDEinfo, 'DateVector')
	tmp_DateVector = input_struct.EventIDEinfo.DateVector;
	date_num = tmp_DateVector(1) * 10000+ tmp_DateVector(2) * 100 +tmp_DateVector(3) * 1;
end




% a few sessions have inconsistent TrialSubType information, e.g. when EventIDE
% was set to dyadic, but only a single name was registered then the code
% fell back to Solo mode, but did not actually record that as the used
% trial sub type (taht stayed as dyadic), so try to fix this here
% The syndrom is TrialSubType implies two players, but the reward information 
% e.g. for Side_A: A_NumberRewardPulsesDelivered_HI, and
% A_NumberRewardPulsesDelivered_HITOTHER indicate that a given trial
% was Dyadic (of any kind, including SemiSolo), Solo, or SoloARewardAB/SoloBRewardAB


% 20201218T130348.A_Elmo.B_FS.SCP_01 
% has SoloBRewardAB, Dyadic and SoloA
% with human partner still registered, but is marked correctly

% 20201217T135022.A_Elmo.B_FS.SCP_01
% has Dyadic, SoloA but no original TrialSubTypeENUM_idx

fixed_TrialSubTypes = 0;

cur_per_trial_subject_A_list = output_struct.unique_lists.A_Name(output_struct.data(:, output_struct.cn.A_Name_idx));
%cur_per_trial_isActive_A_list = output_struct.data(:, output_struct.cn.A_IsActive);
cur_per_trial_isPlaying_A_list = output_struct.data(:, output_struct.cn.A_IsPlaying);
cur_per_trial_RawA_HIT = output_struct.data(:, output_struct.cn.A_NumberRewardPulsesDelivered_HIT);
cur_per_trial_RawA_HITOTHER = output_struct.data(:, output_struct.cn.A_NumberRewardPulsesDelivered_HITOTHER);

cur_per_trial_subject_B_list = output_struct.unique_lists.B_Name(output_struct.data(:, output_struct.cn.B_Name_idx));
if (size(cur_per_trial_subject_B_list, 1) ~= size(cur_per_trial_subject_A_list, 1)) && (numel(cur_per_trial_subject_A_list) == numel(cur_per_trial_subject_B_list))
	cur_per_trial_subject_B_list = cur_per_trial_subject_B_list';
end

%cur_per_trial_isactive_B_list = output_struct.data(:, output_struct.cn.B_IsActive);
cur_per_trial_isPlaying_B_list = output_struct.data(:, output_struct.cn.B_IsPlaying);
cur_per_trial_RawB_HIT = output_struct.data(:, output_struct.cn.B_NumberRewardPulsesDelivered_HIT);
cur_per_trial_RawB_HITOTHER = output_struct.data(:, output_struct.cn.B_NumberRewardPulsesDelivered_HITOTHER) ;

total_reward_HIT = cur_per_trial_RawA_HIT + cur_per_trial_RawB_HIT;
total_reward_HITOTHER = cur_per_trial_RawA_HITOTHER + cur_per_trial_RawB_HITOTHER;
total_reward_HITANY = total_reward_HIT + total_reward_HITOTHER;
RewA_ANY_ldx = cur_per_trial_RawA_HIT > 0 |  cur_per_trial_RawA_HITOTHER > 0;
RewB_ANY_ldx = cur_per_trial_RawB_HIT > 0 |  cur_per_trial_RawB_HITOTHER > 0;

non_zero_joint_reward_HIT_ldx = total_reward_HIT ~= 0;
non_zero_joint_reward_ANY_ldx = RewA_ANY_ldx | RewB_ANY_ldx;

% the main problem are trials classified as Dyadic that actually are solo
Dyadic_trial_ldx = cur_per_trial_RawA_HIT > 0 & cur_per_trial_RawB_HIT > 0;	% any od Dyadic, SemiSolo, DyadicBlockedView
SoloA_trial_ldx = cur_per_trial_RawA_HIT > 0 & ~cur_per_trial_RawB_HIT > 0;
SoloARewardAB_trial_ldx = SoloA_trial_ldx > 0 & cur_per_trial_RawB_HITOTHER > 0;
SoloA_trial_ldx(SoloARewardAB_trial_ldx) = false;	% only one can be true
SoloB_trial_ldx = ~cur_per_trial_RawA_HIT > 0 & cur_per_trial_RawB_HIT > 0;
SoloBRewardAB_trial_ldx = SoloB_trial_ldx > 0 & cur_per_trial_RawA_HITOTHER > 0;
SoloB_trial_ldx(SoloBRewardAB_trial_ldx) = false;	% only one can be true





% if two names are registerd we can have either dyadic or solo rewards , if
% only a single name is registered we only get solo type rewards...
[unique_IsPlaying_Combination_list, ~, IsPlaying_Combination_list_row_idx] = unique([cur_per_trial_isPlaying_A_list, cur_per_trial_isPlaying_B_list], 'rows', 'stable');
merged_name_list = append(cur_per_trial_subject_A_list, '_', cur_per_trial_subject_B_list);
[unique_Name_Combination_list, ~, Name_Combination_list_row_idx] = unique(merged_name_list, 'stable');

% % these are the columns we might need to fix
% TrialSubType_col_ldx = contains(output_struct.header, '_TrialSubType');
% TrialSubType_col_idx = find(TrialSubType_col_ldx);

% the user can enter invalid TrialSubType numbers, but the task does not
% progress so can safely ignore them
if isfield(output_struct.cn, 'A_TrialSubTypeENUM_idx')
	invalid_TrialSubType_ldx = output_struct.data(:, output_struct.cn.A_TrialSubTypeENUM_idx) > length(output_struct.Enums.TrialSubTypes.unique_lists.TrialSubTypes);
	if any(invalid_TrialSubType_ldx)
		NONE_idx = find(ismember(lower(output_struct.Enums.TrialSubTypes.unique_lists.TrialSubTypes), {'none'}));
		output_struct.data(invalid_TrialSubType_ldx, output_struct.cn.A_TrialSubTypeENUM_idx) = NONE_idx;
		output_struct.FixUpReport{end+1} = ['TrialSubType Validity: Fixed invalid TrialSubType A_TrialSubTypeENUM_idx'];
	end
end
if isfield(output_struct.cn, 'B_TrialSubTypeENUM_idx')
	invalid_TrialSubType_ldx = output_struct.data(:, output_struct.cn.B_TrialSubTypeENUM_idx) > length(output_struct.Enums.TrialSubTypes.unique_lists.TrialSubTypes);
	if any(invalid_TrialSubType_ldx)
		NONE_idx = find(ismember(lower(output_struct.Enums.TrialSubTypes.unique_lists.TrialSubTypes), {'none'}));
		output_struct.data(invalid_TrialSubType_ldx, output_struct.cn.B_TrialSubTypeENUM_idx) = NONE_idx;
		output_struct.FixUpReport{end+1} = ['TrialSubType Validity: Fixed invalid TrialSubType B_TrialSubTypeENUM_idx'];
	end
end

% now we want to check things for consistency
for i_unique_Name_Combination = 1 : length(unique_Name_Combination_list)
	%cur_unique_Name_Combination = unique_Name_Combination_list(i_unique_Name_Combination, :);
	cur_unique_Name_Combination = unique_Name_Combination_list{i_unique_Name_Combination};
	[cur_Name_A, rem] = strtok(cur_unique_Name_Combination, '_');
	cur_Name_B = regexprep(rem, '^_', '');

	cur_trial_ldx = Name_Combination_list_row_idx == i_unique_Name_Combination;

	% the assigned trial subtypes that might be incorrect...
	if isfield(output_struct.cn, 'A_TrialSubType_idx')
		cur_TrialSubType_list = output_struct.unique_lists.A_TrialSubType(output_struct.data(cur_trial_ldx, output_struct.cn.A_TrialSubType_idx));
	elseif isfield(output_struct.cn, 'A_TrialSubTypeENUM_idx')
		cur_TrialSubType_list = output_struct.Enums.TrialSubTypes.unique_lists.TrialSubTypes(output_struct.data(cur_trial_ldx, output_struct.cn.A_TrialSubTypeENUM_idx));
	end
	unique_cur_TrialSubType_list = unique(cur_TrialSubType_list, 'stable');
	% however these might be wrong...


	% SOLO trials can happen with any name combination except None, None...
	% especially with two names... but since we can disambiguate by 

	% check SoloA trials
	cur_selected_trials_ldx = SoloA_trial_ldx & cur_trial_ldx;
	if any(cur_selected_trials_ldx)
		SoloA_class_TrialSubType_list = {'SoloA', 'SoloAHighReward', 'SoloA_PresentB'};
		% OK found SoloA trials, check the assigned TrialSubTypes
		cur_unique_TrialSubTypes_in_data_list = unique(output_struct.Enums.TrialSubTypes.unique_lists.TrialSubTypes(output_struct.data(cur_selected_trials_ldx, output_struct.cn.A_TrialSubTypeENUM_idx)));
		for i_unique_TrialSubTypes_in_data = 1 : length(cur_unique_TrialSubTypes_in_data_list)
				cur_unique_TrialSubTypes_in_data = cur_unique_TrialSubTypes_in_data_list{i_unique_TrialSubTypes_in_data};
				% find the subset of trials of this type
				cur_unique_TrialSubTypes_in_data_list_ldx = ismember(output_struct.Enums.TrialSubTypes.unique_lists.TrialSubTypes(output_struct.data(:, output_struct.cn.A_TrialSubTypeENUM_idx))', {cur_unique_TrialSubTypes_in_data});
				if ismember(cur_unique_TrialSubTypes_in_data, SoloA_class_TrialSubType_list)
					% nothing to do these are already correct
					disp([mfilename, ': INFO: Existing ', cur_unique_TrialSubTypes_in_data,' labeled trials OK.']);
				elseif ~ismember(cur_unique_TrialSubTypes_in_data, SoloA_class_TrialSubType_list)
					disp([mfilename, ': INFO: Existing ', cur_unique_TrialSubTypes_in_data,' labeled trials changed to: ', 'SoloA']);
					output_struct = fn_change_TrialSubType_information(output_struct, cur_selected_trials_ldx & cur_unique_TrialSubTypes_in_data_list_ldx, '_TrialSubType', 'SoloA');
					fixed_TrialSubTypes = 1;
				else
					error([mfilename, ': ERROR: multiple cur_unique_TrialSubTypes_in_data, should not happen']);
				end
			end
	end

	% check SoloARewardAB trials
	cur_selected_trials_ldx = SoloARewardAB_trial_ldx & cur_trial_ldx;
	if any(cur_selected_trials_ldx)
		SoloARewardAB_class_TrialSubType_list = {'SoloARewardAB'};
		% OK found SoloARewardAB trials, check the assigned TrialSubTypes
		cur_unique_TrialSubTypes_in_data_list = unique(output_struct.Enums.TrialSubTypes.unique_lists.TrialSubTypes(output_struct.data(cur_selected_trials_ldx, output_struct.cn.A_TrialSubTypeENUM_idx)));
		for i_unique_TrialSubTypes_in_data = 1 : length(cur_unique_TrialSubTypes_in_data_list)
				cur_unique_TrialSubTypes_in_data = cur_unique_TrialSubTypes_in_data_list{i_unique_TrialSubTypes_in_data};
				% find the subset of trials of this type
				cur_unique_TrialSubTypes_in_data_list_ldx = ismember(output_struct.Enums.TrialSubTypes.unique_lists.TrialSubTypes(output_struct.data(:, output_struct.cn.A_TrialSubTypeENUM_idx))', {cur_unique_TrialSubTypes_in_data});
				if ismember(cur_unique_TrialSubTypes_in_data, SoloARewardAB_class_TrialSubType_list)
					% nothing to do these are already correct
					disp([mfilename, ': INFO: Existing ', cur_unique_TrialSubTypes_in_data,' labeled trials OK.']);
				elseif ~ismember(cur_unique_TrialSubTypes_in_data, SoloARewardAB_class_TrialSubType_list)
					disp([mfilename, ': INFO: Existing ', cur_unique_TrialSubTypes_in_data,' labeled trials changed to: ', 'SoloARewardAB']);
					output_struct = fn_change_TrialSubType_information(output_struct, cur_selected_trials_ldx & cur_unique_TrialSubTypes_in_data_list_ldx, '_TrialSubType', 'SoloARewardAB');
					fixed_TrialSubTypes = 1;
				else
					error([mfilename, ': ERROR: multiple cur_unique_TrialSubTypes_in_data, should not happen']);
				end
			end
	end

	% check SoloB trials
	cur_selected_trials_ldx = SoloB_trial_ldx & cur_trial_ldx;
	if any(cur_selected_trials_ldx)
		SoloB_class_TrialSubType_list = {'SoloB', 'SoloBHighReward', 'SoloB_PresentA'};
		% OK found SoloB trials, check the assigned TrialSubTypes
		cur_unique_TrialSubTypes_in_data_list = unique(output_struct.Enums.TrialSubTypes.unique_lists.TrialSubTypes(output_struct.data(cur_selected_trials_ldx, output_struct.cn.A_TrialSubTypeENUM_idx)));
		for i_unique_TrialSubTypes_in_data = 1 : length(cur_unique_TrialSubTypes_in_data_list)
				cur_unique_TrialSubTypes_in_data = cur_unique_TrialSubTypes_in_data_list{i_unique_TrialSubTypes_in_data};
				% find the subset of trials of this type
				cur_unique_TrialSubTypes_in_data_list_ldx = ismember(output_struct.Enums.TrialSubTypes.unique_lists.TrialSubTypes(output_struct.data(:, output_struct.cn.A_TrialSubTypeENUM_idx))', {cur_unique_TrialSubTypes_in_data});
				if ismember(cur_unique_TrialSubTypes_in_data, SoloB_class_TrialSubType_list)
					% nothing to do these are already correct
					disp([mfilename, ': INFO: Existing ', cur_unique_TrialSubTypes_in_data,' labeled trials OK.']);
				elseif ~ismember(cur_unique_TrialSubTypes_in_data, SoloB_class_TrialSubType_list)
					disp([mfilename, ': INFO: Existing ', cur_unique_TrialSubTypes_in_data,' labeled trials changed to: ', 'SoloB']);
					output_struct = fn_change_TrialSubType_information(output_struct, cur_selected_trials_ldx & cur_unique_TrialSubTypes_in_data_list_ldx, '_TrialSubType', 'SoloB');
					fixed_TrialSubTypes = 1;					
				else
					error([mfilename, ': ERROR: multiple cur_unique_TrialSubTypes_in_data, should not happen']);
				end
			end
	end


	% check SoloBRewardAB trials
	cur_selected_trials_ldx = SoloBRewardAB_trial_ldx & cur_trial_ldx;
	if any(cur_selected_trials_ldx)
		SoloBRewardAB_class_TrialSubType_list = {'SoloBRewardAB'};
		% OK found SoloBRewardAB trials, check the assigned TrialSubTypes
		cur_unique_TrialSubTypes_in_data_list = unique(output_struct.Enums.TrialSubTypes.unique_lists.TrialSubTypes(output_struct.data(cur_selected_trials_ldx, output_struct.cn.A_TrialSubTypeENUM_idx)));
		for i_unique_TrialSubTypes_in_data = 1 : length(cur_unique_TrialSubTypes_in_data_list)
				cur_unique_TrialSubTypes_in_data = cur_unique_TrialSubTypes_in_data_list{i_unique_TrialSubTypes_in_data};
				% find the subset of trials of this type
				cur_unique_TrialSubTypes_in_data_list_ldx = ismember(output_struct.Enums.TrialSubTypes.unique_lists.TrialSubTypes(output_struct.data(:, output_struct.cn.A_TrialSubTypeENUM_idx))', {cur_unique_TrialSubTypes_in_data});
				if ismember(cur_unique_TrialSubTypes_in_data, SoloBRewardAB_class_TrialSubType_list)
					% nothing to do these are already correct
					disp([mfilename, ': INFO: Existing ', cur_unique_TrialSubTypes_in_data,' labeled trials OK.']);
				elseif ~ismember(cur_unique_TrialSubTypes_in_data, SoloBRewardAB_class_TrialSubType_list)
					disp([mfilename, ': INFO: Existing ', cur_unique_TrialSubTypes_in_data,' labeled trials changed to: ', 'SoloBRewardAB']);
					output_struct = fn_change_TrialSubType_information(output_struct, cur_selected_trials_ldx & cur_unique_TrialSubTypes_in_data_list_ldx, '_TrialSubType', 'SoloBRewardAB');
					fixed_TrialSubTypes = 1;
				else
					error([mfilename, ': ERROR: multiple cur_unique_TrialSubTypes_in_data, should not happen']);
				end
			end
	end


	% dyadic trials require both names different from None
	if ~strcmp(cur_Name_A, 'None') && ~strcmp(cur_Name_B, 'None')
		cur_selected_trials_ldx = Dyadic_trial_ldx & cur_trial_ldx;
		dyadic_class_TrialSubType_list = {'Dyadic', 'DyadicBlockedView', 'SemiSolo'};
		if any(cur_selected_trials_ldx)
			% OK found Dyadic trials, check the assigned TrialSubTypes
			cur_unique_TrialSubTypes_in_data_list = unique(output_struct.Enums.TrialSubTypes.unique_lists.TrialSubTypes(output_struct.data(cur_selected_trials_ldx, output_struct.cn.A_TrialSubTypeENUM_idx)));
			for i_unique_TrialSubTypes_in_data = 1 : length(cur_unique_TrialSubTypes_in_data_list)
				cur_unique_TrialSubTypes_in_data = cur_unique_TrialSubTypes_in_data_list{i_unique_TrialSubTypes_in_data};
				% find the subset of trials of this type
				cur_unique_TrialSubTypes_in_data_list_ldx = ismember(output_struct.Enums.TrialSubTypes.unique_lists.TrialSubTypes(output_struct.data(:, output_struct.cn.A_TrialSubTypeENUM_idx))', {cur_unique_TrialSubTypes_in_data});
				if ismember(cur_unique_TrialSubTypes_in_data, dyadic_class_TrialSubType_list)
					% nothing to do these are already correct
					disp([mfilename, ': INFO: Existing ', cur_unique_TrialSubTypes_in_data,' labeled trials OK.']);
				elseif ~ismember(cur_unique_TrialSubTypes_in_data, dyadic_class_TrialSubType_list)
					disp([mfilename, ': INFO: Existing ', cur_unique_TrialSubTypes_in_data,' labeled trials changed to: ', 'Dyadic']);
					output_struct = fn_change_TrialSubType_information(output_struct, cur_selected_trials_ldx & cur_unique_TrialSubTypes_in_data_list_ldx, '_TrialSubType', 'Dyadic');
					fixed_TrialSubTypes = 1;
				else
					error([mfilename, ': ERROR: multiple cur_unique_TrialSubTypes_in_data, should not happen']);
				end
			end
		end
	end
end

% if (fixed_TrialSubTypes)
% 	output_struct.FixUpReport{end+1} = ['TrialSubType: Fixed assignment of TrialSubType from reward data (HIT and HITOTHER)'];
% end



% 20170912 to 20171010: data TrialType and TrialTypeString are not
% necessarily correct if TrialTypeSets used and ReportVersion < 8
if (((isfield(input_struct.SessionByTrial, 'cn')) && (isfield(input_struct.SessionByTrial.cn, 'TrialTypeSet')) && (date_num <= 20171010) && (date_num >= 20170912)))
	% SubjectX.TrialType and SubjectX.TrialTypeString are potentialy
	% incorrect, but the STIMULUS structure will contain the necessary
	% information: if two targets => choice trial, if red or yellow ring
	% informed trial
	disp(['Current report file requires fix-up of TrialTypes: ', input_struct.info.logfile_FQN]);
	output_struct = fnFixTrialTypesFromStimuli(output_struct);
end


% correct TargetOffsetTimes_ms from RendererState
if isfield(fixup_struct, 'correct_TargetOffsetTimes_ms_from_RenderState') && (fixup_struct.correct_TargetOffsetTimes_ms_from_RenderState)
	output_struct = fn_correct_TargetOffsetTimes_ms_from_RenderState(output_struct);
end


% The TOLED5500 has a relative large variable delay, between receiving a
% video frame (independent of signal source) and actually rendering the
% frame, to account for that we measure visual state changes with a
% photodiode, we can then try to use the timing of these recorded
% photodioge signals to correct stimulus onset and offset times.
if isfield(fixup_struct, 'correct_visual_stimulus_change_ts_from_photodiode') && (fixup_struct.correct_visual_stimulus_change_ts_from_photodiode)
	% construct the exected name for the signallog file
	[session_dir, triallog_name_stem] = fileparts(input_struct.info.logfile_FQN);
	[~, session_id] = fileparts(triallog_name_stem);
	% by omitting the final extension this defaults to loading the highest
	% processed version of the signallog
	signallog_base_FQN = fullfile(session_dir, 'trackerlogfiles', [session_id, '.TID_NISignalFileWriterADC.signallog']);
	
	% check if signallog exists and load it if it does
	proto_signallog_dir_struct = dir([signallog_base_FQN, '*']);
	if ~isempty(proto_signallog_dir_struct)
		output_struct = fnFixVisualChangeTimesFromPhotodiodeSignallog(output_struct, signallog_base_FQN);
	end
end

% sanitize TrialStart timestamp to data table

% add trial end timestamp to data table 
% use the Paradigm start time of the ITI state unless trialend is defined.
% to get a over inclusive trial definition, a trial starts with the ITI...
% this definition is not useful for temporal alignment, but sufficient for
% sanity checking
if isfield(fixup_struct, 'add_trial_start_and_end_times') && (fixup_struct.add_trial_start_and_end_times)
	if isfield(output_struct, 'ParadigmState') && isfield(output_struct.ParadigmState, 'data')
		
		if isfield(input_struct.Enums, 'ParadigmStates')
			ITI_ParadigmStateENUM_idx = input_struct.Enums.ParadigmStates.EnumStruct.data(input_struct.Enums.ParadigmStates.EnumStruct.cn.ITI)+1;
		elseif (isfield(input_struct.Enums, 'DAGDirectFreeGazeReaches'))
			ITI_ParadigmStateENUM_idx = input_struct.Enums.DAGDirectFreeGazeReaches.EnumStruct.data(input_struct.Enums.DAGDirectFreeGazeReaches.EnumStruct.cn.ITI)+1;
		end
		
		ITI_para_instance_idx = find(output_struct.ParadigmState.data(:, output_struct.ParadigmState.cn.ParadigmStateENUM_idx) == ITI_ParadigmStateENUM_idx);
		n_trials = size(output_struct.data, 1);
		% these pairs should be correct
		TrialStartTime_ms = output_struct.ParadigmState.data(ITI_para_instance_idx(1:end-1), output_struct.ParadigmState.cn.Timestamp);
		TrialEndTime_ms = output_struct.ParadigmState.data(ITI_para_instance_idx(2:end), output_struct.ParadigmState.cn.Timestamp);
		if (length(ITI_para_instance_idx) == n_trials + 1)
			% add to the output struct
			output_struct = fn_handle_data_struct('add_columns', output_struct, [TrialStartTime_ms, TrialEndTime_ms], {'TrialStartTime_ms', 'TrialEndTime_ms'});
		else
			% we probably have more ITI instances than recorded trials
			% we need to match these pairs around known trial times
			matched_trial_idx = [];
			for i_trial = 1 : n_trials
				cur_trial_start_time = output_struct.data(i_trial, output_struct.cn.Timestamp);
				proto_trial_idx = find(TrialEndTime_ms > cur_trial_start_time, 1, 'first');
				if (TrialStartTime_ms(proto_trial_idx) <= cur_trial_start_time)
					matched_trial_idx = union(matched_trial_idx, proto_trial_idx);
				end
			end
			output_struct = fn_handle_data_struct('add_columns', output_struct, [TrialStartTime_ms(matched_trial_idx), TrialEndTime_ms(matched_trial_idx)], {'TrialStartTime_ms', 'TrialEndTime_ms'});
		end
		output_struct.FixUpReport{end+1} = ['add_trial_start_and_end_times: Added TrialStartTime_ms and TrialStartEnd_ms to the triallog data table, based on the ITI.'];
	else
		output_struct.FixUpReport{end+1} = ['add_trial_start_and_end_times: NOT added TrialStartTime_ms and TrialStartEnd_ms to the triallog data table, based on the ITI. Triallog is missing relevant information.'];
	end
end

% add estimated Reward start times unless they exist already

return
end

function [ output_struct ] = fnFixVisualChangeTimesFromPhotodiodeSignallog( output_struct, signallog_base_FQN )


% check for sufficient information, for the new complete PhotoDiodeRenderer
% information.
if ~isfield(output_struct, 'PhotoDiodeRenderer') || ~isfield(output_struct.PhotoDiodeRenderer, 'cn')
	disp(['fnFixVisualChangeTimesFromPhotodiodeSignallog: PhotoDiodeRenderer does not exist or is empty, no timing correction possible.']);
	output_struct.FixUpReport{end+1} = 'fnFixVisualChangeTimesFromPhotodiodeSignallog: PhotoDiodeRenderer does not exist or is empty, no timing correction possible.';
	return
end	

debug = 0;

[signallog_base_dir, signallog_base_name]  = fileparts(signallog_base_FQN);


% load the most refined version of the signallog
signallog = fnParseEventIDETrackerLog_v01( signallog_base_FQN, [], [], []);
n_samples = size(signallog.data, 1);

% get the relevant channel/column
if isfield(signallog, 'info') && isfield(signallog.info, 'patient_id')
	%signallog.info.patient_id
	channel_name_list = textscan(signallog.info.patient_id, '%s','Delimiter',',')';
	channel_name_list = channel_name_list{1};
	photo_diode_signal_col = [];
	tmp_list = strfind(channel_name_list, 'SpotDetector');
	for i_col = 1 : length(channel_name_list)
		if ~isempty(tmp_list{i_col})
			photo_diode_signal_col = i_col;
		end
	end
	
	timestamp_col = [];
	tmp_list = strfind(channel_name_list, 'EventIDE_TimeStamp');
	for i_col = 1 : length(channel_name_list)
		if ~isempty(tmp_list{i_col})
			timestamp_col = i_col;
		end
	end
else
	error('Find the photodiode column for old data, not implemented yet');
end

% for testing the uncorrcted eventIDE timestamps
% these show no drift, while the corrected timestamps change a bit over
% time, linerly, so the correction code needs a bit of corrective work
%timestamp_col = signallog.cn.UncorrectedEventIDE_TimeStamp;


if (debug)
	% sanity check, plot some of the data, say 5 minutes from the middle
	midtime_ms = signallog.data(floor(n_samples*0.5), timestamp_col);
	start_idx = find(signallog.data(:, timestamp_col) >= (midtime_ms - (5 * 60 * 2000)));
	start_idx = start_idx(1);
	end_idx = find(signallog.data(:, timestamp_col) < (midtime_ms + (5 * 60 * 2000)));
	end_idx = end_idx(end);
	figure('Name', 'PhotodiodeSignal?');
	plot(signallog.data(start_idx:end_idx, timestamp_col), signallog.data(start_idx:end_idx, photo_diode_signal_col));
end

% now detect onsets and offsets of photodiode (pd) pulse trains
diff_pd_voltage = diff(signallog.data(:, photo_diode_signal_col));

if (debug)
	hold on
	plot(diff_pd_voltage);
	%plot(signallog.data(:, :));
	plot(signallog.data(:, photo_diode_signal_col));
	hold off
end

% the rising flank is nice and steep but the falling flank is a bit
% broader


positive_threshold_value_volts = 2.5;	% this is the change in amlitude between two samples.
% note on the falling edge the photodiode/spot detector box has
% noticeable skew
pd_onset_sample_idx = find(diff_pd_voltage >= positive_threshold_value_volts) + 1; % +1 accounts for diff chopping off the first element
%% this is unprecise
%pd_offset_sample_idx = find(diff_pd_voltage <= -positive_threshold_value_volts) + 1;

pd_offset_sample_idx = zeros(size(pd_onset_sample_idx));
for i_pd_onset = 1 : length(pd_onset_sample_idx)
	cur_pd_onset_idx = pd_onset_sample_idx(i_pd_onset);
	sample_offset = 1;
	% 3.45 Volts seems to work
	
	% the last value recorded is a rising flank
	if ((cur_pd_onset_idx+sample_offset) > n_samples)
		% or use NaN
		pd_offset_sample_idx(i_pd_onset) = cur_pd_onset_idx + 0;
		disp('The last sample of the photodiode data in the signallog is a rising flank (pd_onset). Setting the pd_offset to the same idx.');
	else
		while (signallog.data(cur_pd_onset_idx+sample_offset, photo_diode_signal_col) >= 3.45)
			sample_offset = sample_offset + 1;
			if ((cur_pd_onset_idx+sample_offset) >= n_samples)
				if ((cur_pd_onset_idx+sample_offset) > n_samples)
					sample_offset = sample_offset -1;
				end
				% we reached the end and pretend that there is an pd offset
				% here, so onsets and offsets are paired
				break
			end
		end
		pd_offset_sample_idx(i_pd_onset) = cur_pd_onset_idx + sample_offset;
	end
end

pd_onset_sample_timestamp_list = signallog.data(pd_onset_sample_idx, timestamp_col);
pd_offset_sample_timestamp_list = signallog.data(pd_offset_sample_idx, timestamp_col);


pd_puls_dur_list = pd_offset_sample_timestamp_list - pd_onset_sample_timestamp_list;
diff_pd_onset_sample_timestamp_list = diff(pd_onset_sample_timestamp_list);
diff_pd_offset_sample_timestamp_list = diff(pd_offset_sample_timestamp_list);

same_onset_sample_timestamp_list = find(abs(diff_pd_onset_sample_timestamp_list) <= 0.0 + (2 * eps));
same_offset_sample_timestamp_list = find(abs(diff_pd_offset_sample_timestamp_list) <= 0.0 + (2 * eps));

if ~isempty(same_onset_sample_timestamp_list) || ~isempty(same_offset_sample_timestamp_list)
	disp('Photodiode pulse detection seems to have cought the same onset of offset twice. This should not be, so investigate!');
	keyboard
end


if isempty(pd_onset_sample_timestamp_list) && isempty(pd_offset_sample_timestamp_list)
	disp(['fnFixVisualChangeTimesFromPhotodiodeSignallog: No photodiode onsets or offsets detected, bailing out...']);
	output_struct.FixUpReport{end+1} = 'fnFixVisualChangeTimesFromPhotodiodeSignallog: No PhotoDiode data found; could not correct the PhotoDiodeRenderer times from recorded PhotoDiode data';
	return
end
	
pd_pulse_dur_ms_list = pd_offset_sample_timestamp_list - pd_onset_sample_timestamp_list;
%histogram(pd_pulse_dur_ms_list)
% these should all be canonical, so averaging will work
avg_pulse_duration = mean(pd_pulse_dur_ms_list);
%median_pulse_duration = median(pd_pulse_dur_ms_list);


% these start at pd_offset_sample_timestamp_list timestamps
pd_inter_pulse_dur_ms_list = [(pd_onset_sample_timestamp_list(2:end) - pd_offset_sample_timestamp_list(1:end-1)); 0];
%max(pd_inter_pulse_dur_ms_list)
% these contain much larger variations, like real interstate delays
median_pd_inter_pulse_dur_ms = median(pd_inter_pulse_dur_ms_list);
%histogram(pd_inter_pulse_dur_ms_list)


% find the display periods of the PhotoDiodeDriver stimulus
% the first sample is an offset of offset by definition, so make sure we
% get a delta showing this
pd_onset_diff = diff([pd_onset_sample_idx(1); pd_onset_sample_idx]);
pd_offset_diff = diff([pd_offset_sample_idx(1); pd_offset_sample_idx]);

pd_onset_sample_timestamp_diff_list = diff([pd_onset_sample_timestamp_list(1); pd_onset_sample_timestamp_list]);
pd_offset_sample_timestamp_diff_list = diff([pd_offset_sample_timestamp_list(1); pd_offset_sample_timestamp_list]);


histogram_fh = figure('Name', 'PhotoDiodeInterOnsetInterval');
%histogram((pd_onset_sample_timestamp_diff_list(find((pd_onset_sample_timestamp_diff_list * 1000) < 30)) * 1000));
%pd_onset_sample_timestamp_diff_list * 1000
tmp_data_idx = pd_onset_sample_timestamp_diff_list <= (30); % 30 ms would be 1/0.03sec or 33.3 Hz, we use refreshrates larger than that
tmp_data = pd_onset_sample_timestamp_diff_list(tmp_data_idx);
histogram( tmp_data );

if ~debug
	close(histogram_fh);
end

% this should be
median_inter_onset_dur_ms = median(pd_onset_sample_timestamp_diff_list);
%mean_inter_onset_dur_ms = mean(pd_onset_sample_timestamp_diff_list);
mean_inter_onset_dur_ms = mean(tmp_data);

% calculate the screen refresh times:
% the OLED operates at 120Hz so
avg_interframe_delay_ms = mean(tmp_data(find(tmp_data <= 16 & tmp_data >= 5)));
refresh2frame_ratio = 2;	% the 120 Hz OLED only gets new inputs every other OLED-frame
% assume CRT @60Hz
if isnan(avg_interframe_delay_ms)
	avg_interframe_delay_ms = mean(tmp_data(find(tmp_data <= 20 & tmp_data >= 12)));
	refresh2frame_ratio = 1;
end

avg_screen_framerate = 1000/avg_interframe_delay_ms;
disp(['PhotoDiode pulses coming in at ~' num2str(avg_screen_framerate), ' Hz, with ', num2str(avg_interframe_delay_ms), 'ms inter pulse delay']);
% the OLED panel runds at ~ 120 Hz, so get the best matching
disp(['Actual screen probably refreshes at ~' num2str((1/refresh2frame_ratio) * avg_screen_framerate), ' Hz, with ', num2str(2.0 * avg_interframe_delay_ms), 'ms inter pulse delay']);

% now find the gaps in the pulse patterns caused by changes of the
% PhotoDiodeDriver stimulus


% special case CRTs?
switch refresh2frame_ratio
	case 1
		min_frames_per_gap = 3;
	case 2
		min_frames_per_gap = 1.9;
	otherwise
		min_frames_per_gap = 2;
end

% initialize too large, will be pruned later
pd_block_onset_ms_list = zeros(size(pd_pulse_dur_ms_list));
pd_block_offset_ms_list = pd_block_onset_ms_list;
block_counter = 0;
pd_block_onset_ms_list(1) = pd_onset_sample_timestamp_list(1); % the first block starts with the first recorded pulse
for i_pulse = 1 : length(pd_inter_pulse_dur_ms_list)
	cur_inter_pulse_dur_ms = pd_inter_pulse_dur_ms_list(i_pulse);
	% EventIDE paradigm state changes with visible elements will toggle the
	% stimulus beow the photodiode, so we want to look for longer switches
	% between on and off states
	if (cur_inter_pulse_dur_ms >= median_inter_onset_dur_ms * min_frames_per_gap)
		% seems to be a genuine block start, get the matching onset and
		% offset times
		% pd_inter_pulse_dur_ms_list = [(pd_onset_sample_timestamp_list(2:end) - pd_offset_sample_timestamp_list(1:end-1)); 0];
		block_counter = block_counter + 1;
		pd_block_onset_ms_list(block_counter + 1) = pd_onset_sample_timestamp_list(i_pulse + 1);
		pd_block_offset_ms_list(block_counter) = pd_offset_sample_timestamp_list(i_pulse);
	end
	
end
% prune the lists to remove unfilled rows.
pd_block_onset_ms_list = pd_block_onset_ms_list(1:block_counter);
pd_block_offset_ms_list = pd_block_offset_ms_list(1:block_counter);
pd_block_dur_ms = pd_block_offset_ms_list - pd_block_onset_ms_list;
pd_inter_block_dur_ms = [(pd_block_onset_ms_list(2:end) - pd_block_offset_ms_list(1:end-1)); 0];


pd_fh = figure('Name', 'PhotoDiode Signal with Block Onset and Offset');
legend_list = {};
hold on
legend_list{end+1} = 'PhotoDiode';
plot(signallog.data(:, timestamp_col), signallog.data(:, photo_diode_signal_col));

% show the detected block onsets and offsets
y_lim = get(gca, 'YLim');
set(gca, 'YLim', [-0.5 y_lim(2)]);

y_lim = get(gca, 'YLim');

% plot the detected block borders
for i_PD_block_onset = 1 : length(pd_block_onset_ms_list)
	plot([pd_block_onset_ms_list(i_PD_block_onset), pd_block_onset_ms_list(i_PD_block_onset)], [0 y_lim(2)], 'Color', [0 1 0]);
end
legend_list{end+1} = 'PD_block_onset';
for i_PD_block_offset = 1 : length(pd_block_offset_ms_list)
	plot([pd_block_offset_ms_list(i_PD_block_offset), pd_block_offset_ms_list(i_PD_block_offset)], [0 y_lim(2)], 'Color', [1 0 0]);
end
legend_list{end+1} = 'PD_block_offset';

% plot the photo diode times as well
PD_transition_visibility = output_struct.PhotoDiodeRenderer.data(:, output_struct.PhotoDiodeRenderer.cn.Visible);
PD_onset_timestamps = output_struct.PhotoDiodeRenderer.data((PD_transition_visibility == 1), output_struct.PhotoDiodeRenderer.cn.Timestamp);
PD_offset_timestamps = output_struct.PhotoDiodeRenderer.data((PD_transition_visibility == 0), output_struct.PhotoDiodeRenderer.cn.Timestamp);
for i_PhotoDiodeRenderer_onset = 1 : length(PD_onset_timestamps)
	plot([PD_onset_timestamps(i_PhotoDiodeRenderer_onset), PD_onset_timestamps(i_PhotoDiodeRenderer_onset)], [y_lim(1) 0], 'Color', [0 0.6 0]);
end
legend_list{end+1} = 'PhotoDiodeRenderer_onset';
for i_PhotoDiodeRenderer_offset = 1 : length(PD_offset_timestamps)
	plot([PD_offset_timestamps(i_PhotoDiodeRenderer_offset), PD_offset_timestamps(i_PhotoDiodeRenderer_offset)], [y_lim(1) 0], 'Color', [0.6 0 0]);
end
legend_list{end+1} = 'PhotoDiodeRenderer_offset';

hold off
%scrollplot;
write_out_figure(pd_fh, fullfile(signallog_base_dir, ['PhotoDiode_Signal_with_Block_Onset_and_Offset', '.pdf']));
if ~debug
	close(pd_fh);
end

% now find the corresponding events for the photodiode

if isfield(output_struct, 'PhotoDiodeRenderer') && (size(output_struct.PhotoDiodeRenderer.data, 1) > 1)
	% we need to correct output_struct.PhotoDiodeRenderer.cn.Timestamp and output_struct.PhotoDiodeRenderer.cn.RenderTimestamp_ms
	% Visible denotes the state transition
	% we need to correct RendererState and (main) data onset and offsets
	% as well as Render
	
	% prepare the PhotoDiodeRenderer record
	output_struct.PhotoDiodeRenderer.header{end + 1} = 'uncorrected_Timestamp';
	output_struct.PhotoDiodeRenderer.header{end + 1} = 'uncorrected_RenderTimestamp_ms';
	output_struct.PhotoDiodeRenderer.cn = local_get_column_name_indices(output_struct.PhotoDiodeRenderer.header);
	output_struct.PhotoDiodeRenderer.data(:, output_struct.PhotoDiodeRenderer.cn.uncorrected_Timestamp) = output_struct.PhotoDiodeRenderer.data(:, output_struct.PhotoDiodeRenderer.cn.Timestamp);
	output_struct.PhotoDiodeRenderer.data(:, output_struct.PhotoDiodeRenderer.cn.uncorrected_RenderTimestamp_ms) = output_struct.PhotoDiodeRenderer.data(:, output_struct.PhotoDiodeRenderer.cn.RenderTimestamp_ms);
	
	PD_transition_timestamps = output_struct.PhotoDiodeRenderer.data(:, output_struct.PhotoDiodeRenderer.cn.Timestamp);
	PD_transition_visibility = output_struct.PhotoDiodeRenderer.data(:, output_struct.PhotoDiodeRenderer.cn.Visible);
	
	RenderTimestamp_ms_photodiode_diff_list = zeros(size(PD_transition_timestamps));
	
	for i_PD_transition = 1 : length(PD_transition_timestamps)
		cur_PD_transition_timestamp = PD_transition_timestamps(i_PD_transition);
		
		if (PD_transition_visibility(i_PD_transition) == 1)
			% Visible == 1 means the renderer was activated -> pd_block_onset
			tmp_idx = find(pd_block_onset_ms_list >= cur_PD_transition_timestamp, 1);
			if ~isempty(tmp_idx)
				cur_corrected_time = pd_block_onset_ms_list(tmp_idx);
				output_struct.PhotoDiodeRenderer.data(i_PD_transition, output_struct.PhotoDiodeRenderer.cn.Timestamp) = cur_corrected_time;
				output_struct.PhotoDiodeRenderer.data(i_PD_transition, output_struct.PhotoDiodeRenderer.cn.RenderTimestamp_ms) = cur_corrected_time;
			end
		else
			% Visible == 0 means the renderer was deactivated -> pd_block_offset
			tmp_idx = find(pd_block_offset_ms_list >= cur_PD_transition_timestamp, 1);
			if ~isempty(tmp_idx)
				cur_corrected_time = pd_block_offset_ms_list(tmp_idx);
				output_struct.PhotoDiodeRenderer.data(i_PD_transition, output_struct.PhotoDiodeRenderer.cn.Timestamp) = cur_corrected_time;
				output_struct.PhotoDiodeRenderer.data(i_PD_transition, output_struct.PhotoDiodeRenderer.cn.RenderTimestamp_ms) = cur_corrected_time;
			end
		end
		% save the time correction, if one was made
		if ~isempty(tmp_idx)
			RenderTimestamp_ms_photodiode_diff_list(i_PD_transition) = cur_corrected_time - cur_PD_transition_timestamp;
		end
	end
	output_struct.FixUpReport{end+1} = 'fnFixVisualChangeTimesFromPhotodiodeSignallog: Corrected the PhotoDiodeRenderer times from recorded PhotoDiode data';
	
	
	PD_overview_fh = figure('Name', 'PhotoDiodeBlockTimes minus EventIDE RenderTimes');
	subplot(2, 2, 1)
	histogram(RenderTimestamp_ms_photodiode_diff_list(find(PD_transition_visibility == 1)), (30:1:100)),
	title('Block Onset: difference histogram between PhotoDiode Time and RenderTimes');
	
	subplot(2, 2, 2)
	plot(PD_transition_timestamps(find(PD_transition_visibility == 1)), RenderTimestamp_ms_photodiode_diff_list(find(PD_transition_visibility == 1))),
	title('Block Onset: difference between PhotoDiode Time and RenderTimes over time');
	
	subplot(2, 2, 3)
	histogram(RenderTimestamp_ms_photodiode_diff_list(find(PD_transition_visibility == 0)), (30:1:100)),
	title('Block Offset: difference histogram between PhotoDiode Time and RenderTimes');
	
	subplot(2, 2, 4)
	plot(PD_transition_timestamps(find(PD_transition_visibility == 0)), RenderTimestamp_ms_photodiode_diff_list(find(PD_transition_visibility == 0))),
	title('Block Offset: difference between PhotoDiode Time and RenderTimes over time');
	
	write_out_figure(PD_overview_fh, fullfile(signallog_base_dir, [signallog_base_name, '.VisualOnsetOffset.pdf']))
	
	if ~debug
		close(PD_overview_fh);
	end
	
	
	% now correct
	
	% we need to correct RendererState and (main) data onset and offsets
	% as well as Render
	
	% prepare the Render record
	output_struct.Render.header{end + 1} = 'uncorrected_Timestamp';
	output_struct.Render.cn = local_get_column_name_indices(output_struct.Render.header);
	output_struct.Render.data(:, output_struct.Render.cn.uncorrected_Timestamp) = output_struct.Render.data(:, output_struct.Render.cn.Timestamp);
	
	for i_PhotoDiodeRendererChange = 1 : size(output_struct.PhotoDiodeRenderer.data, 1)
		cur_corrected_RenderTimestamp_ms = output_struct.PhotoDiodeRenderer.data(i_PhotoDiodeRendererChange, output_struct.PhotoDiodeRenderer.cn.RenderTimestamp_ms);
		cur_uncorrected_RenderTimestamp_ms  = output_struct.PhotoDiodeRenderer.data(i_PhotoDiodeRendererChange, output_struct.PhotoDiodeRenderer.cn.uncorrected_RenderTimestamp_ms);
		% find the occurance of uncorrected timestamp and replace with
		% corrected value
		tmp_idx = find(output_struct.Render.data(:, output_struct.Render.cn.Timestamp) == cur_uncorrected_RenderTimestamp_ms);
		if ~isempty(tmp_idx)
			output_struct.Render.data(tmp_idx, output_struct.Render.cn.Timestamp) = cur_corrected_RenderTimestamp_ms;
		end
	end
	output_struct.FixUpReport{end+1} = 'fnFixVisualChangeTimesFromPhotodiodeSignallog: Corrected the Render times from recorded PhotoDiode data';
	
	
	to_be_corrected_data_filed_list = {'Timestamp', 'RenderTimestamp_ms'};
	for i_field = 1 : length(to_be_corrected_data_filed_list)
		if isfield(output_struct, 'RendererState') && isfield(output_struct.RendererState, 'data')
			cur_fieldname = to_be_corrected_data_filed_list{i_field};
			cur_uncorrected_fieldname = ['uncorrected_', cur_fieldname];
			if isfield(output_struct.RendererState.cn, cur_fieldname)
				output_struct.RendererState.header{end + 1} = cur_uncorrected_fieldname;
				output_struct.RendererState.cn = local_get_column_name_indices(output_struct.RendererState.header);
				output_struct.RendererState.data(:, output_struct.RendererState.cn.(cur_uncorrected_fieldname)) = output_struct.RendererState.data(:, output_struct.RendererState.cn.(cur_fieldname));
				
				for i_PhotoDiodeRendererChange = 1 : size(output_struct.PhotoDiodeRenderer.data, 1)
					cur_corrected_RenderTimestamp_ms = output_struct.PhotoDiodeRenderer.data(i_PhotoDiodeRendererChange, output_struct.PhotoDiodeRenderer.cn.RenderTimestamp_ms);
					cur_uncorrected_RenderTimestamp_ms  = output_struct.PhotoDiodeRenderer.data(i_PhotoDiodeRendererChange, output_struct.PhotoDiodeRenderer.cn.uncorrected_RenderTimestamp_ms);
					% find the occurance of uncorrected timestamp and replace with
					% corrected value
					tmp_idx = find(output_struct.RendererState.data(:, output_struct.RendererState.cn.(cur_uncorrected_fieldname)) == cur_uncorrected_RenderTimestamp_ms);
					if ~isempty(tmp_idx)
						output_struct.RendererState.data(tmp_idx, output_struct.RendererState.cn.(cur_fieldname)) = cur_corrected_RenderTimestamp_ms;
					end
				end
				output_struct.FixUpReport{end+1} = ['fnFixVisualChangeTimesFromPhotodiodeSignallog: Corrected the RendererState times from recorded PhotoDiode data for ', cur_fieldname];
			end
		end
	end
	
	
	
	% prepare the data record
	to_be_corrected_data_filed_list = {'A_InitialFixationOnsetTime_ms', 'B_InitialFixationOnsetTime_ms', ...
		'A_TargetOnsetTime_ms', 'B_TargetOnsetTime_ms', ...
		'A_TargetOffsetTime_ms', 'B_TargetOffsetTime_ms', ...
		'A_GoSignalTime_ms', 'B_GoSignalTime_ms'};
	for i_field = 1 : length(to_be_corrected_data_filed_list)
		cur_fieldname = to_be_corrected_data_filed_list{i_field};
		% only try to correct existing fields.
		if isfield(output_struct.cn, cur_fieldname)
			cur_uncorrected_fieldname = ['uncorrected_', cur_fieldname];
			output_struct.header{end + 1} = cur_uncorrected_fieldname;
			output_struct.cn = local_get_column_name_indices(output_struct.header);
			output_struct.data(:, output_struct.cn.(cur_uncorrected_fieldname)) = output_struct.data(:, output_struct.cn.(cur_fieldname));
			
			for i_PhotoDiodeRendererChange = 1 : size(output_struct.PhotoDiodeRenderer.data, 1)
				cur_corrected_RenderTimestamp_ms = output_struct.PhotoDiodeRenderer.data(i_PhotoDiodeRendererChange, output_struct.PhotoDiodeRenderer.cn.RenderTimestamp_ms);
				cur_uncorrected_RenderTimestamp_ms  = output_struct.PhotoDiodeRenderer.data(i_PhotoDiodeRendererChange, output_struct.PhotoDiodeRenderer.cn.uncorrected_RenderTimestamp_ms);
				% find the occurance of uncorrected timestamp and replace with
				% corrected value
				tmp_idx = find(output_struct.data(:, output_struct.cn.(cur_uncorrected_fieldname)) == cur_uncorrected_RenderTimestamp_ms);
				if ~isempty(tmp_idx)
					output_struct.data(tmp_idx, output_struct.cn.(cur_fieldname)) = cur_corrected_RenderTimestamp_ms;
				end
			end
			output_struct.FixUpReport{end+1} = ['fnFixVisualChangeTimesFromPhotodiodeSignallog: Corrected the data times from recorded PhotoDiode data for: ', cur_fieldname];
		end
	end
	
elseif isfield(output_struct, 'PhotoDiodeDriver') && (size(output_struct.PhotoDiodeDriver.data, 1) > 1)
	% old style photodiode data, can we actually correct anything?
	error('Not Implemented yet.');
	return
end


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

function [ ouput_struct ] = fnFixTrialTypesFromStimuli( input_struct )
% SubjectX.TrialType and SubjectX.TrialTypeString are potentialy
% incorrect, but the STIMULUS structure will contain the necessary
% information: if two targets => choice trial, if red or yellow ring
% informed trial
ouput_struct = input_struct;

TargetsPerTrialList = zeros([size(input_struct.data, 1), 1]);
InformativeTargetsPerTrialList = zeros([size(input_struct.data, 1), 1]);

for i_trial = 1: size(input_struct.data, 1)
	% find all stimuli for the current trial
	CurrentTrialStimuliIdx = find(input_struct.Stimuli.data(:, input_struct.Stimuli.cn.TrialNumber) == i_trial);
	% find the stimuli actively used/intended as targets
	CurrentTrialIsTargetList = input_struct.Stimuli.data(CurrentTrialStimuliIdx, input_struct.Stimuli.cn.IsTarget);
	% how many target?
	NumTargetsInTrial = sum(CurrentTrialIsTargetList);
	TargetsPerTrialList(i_trial) = sum(CurrentTrialIsTargetList);
	% get the stimulus names
	CurrentTrialStimulusNameIdxList = input_struct.Stimuli.data(CurrentTrialStimuliIdx, input_struct.Stimuli.cn.StimulusName_idx);
	CurrentTargetStimulusList = input_struct.Stimuli.unique_lists.StimulusName(CurrentTrialStimulusNameIdxList(logical(CurrentTrialIsTargetList)));
	
	if sum(ismember(CurrentTargetStimulusList, {'LeftHandTouchTargetLessDim_RedRing', 'LeftHandTouchTargetLessDim_YellowRing', 'RightHandTouchTargetLessDim_RedRing', 'RightHandTouchTargetLessDim_YellowRing'})) > 0
		CurrentTrialTargetInformative = 1;
		InformativeTargetsPerTrialList(i_trial) = 1;
	end
	
	if (CurrentTrialTargetInformative)
		if (NumTargetsInTrial == 1)
			CurrentTrialTypeString = 'InformedDirectedReach';
		elseif (NumTargetsInTrial == 2)
			CurrentTrialTypeString = 'InformedChoice';
		end
	else
		if (NumTargetsInTrial == 1)
			CurrentTrialTypeString = 'DirectFreeGazeReaches';
		elseif (NumTargetsInTrial == 2)
			CurrentTrialTypeString = 'DirectFreeGazeFreeChoice';
		end
	end
	
	CurrentTrialTypeENUM_idx = find(strcmp(CurrentTrialTypeString, input_struct.unique_lists.A_TrialTypeENUM));
	CurrentTrialTypeString_idx = find(strcmp(CurrentTrialTypeString, input_struct.unique_lists.A_TrialTypeString));
	
	ouput_struct.data(i_trial, ouput_struct.cn.A_TrialType) = CurrentTrialTypeENUM_idx - 1;
	ouput_struct.data(i_trial, ouput_struct.cn.A_TrialTypeENUM_idx) = CurrentTrialTypeENUM_idx;
	ouput_struct.data(i_trial, ouput_struct.cn.A_TrialTypeString_idx) = CurrentTrialTypeString_idx;
	
	
	ouput_struct.data(i_trial, ouput_struct.cn.B_TrialType) = CurrentTrialTypeENUM_idx - 1;
	ouput_struct.data(i_trial, ouput_struct.cn.B_TrialTypeENUM_idx) = CurrentTrialTypeENUM_idx;
	ouput_struct.data(i_trial, ouput_struct.cn.B_TrialTypeString_idx) = CurrentTrialTypeString_idx;
	
	
end

ouput_struct.FixUpReport{end+1} = 'TrialType: Fixed sporadically wrong TrialType assignments using the stimuli struct';
return
end


function [ 	ByTrial_struct ] = fnConvertTimestampedChangeDataToByTrialData(TimestampedChanges_struct, NameString, TimestampList, TrialNumberList)
% Take timestamped row data and expand it to a table that repeats the same
% data for all trials with a TrialTimestamp >= Timestamp (for efficiency's
% sake this will only touch each trial once).

ByTrial_struct = struct();
ByTrial_struct.unique_lists = TimestampedChanges_struct.unique_lists;
ByTrial_struct.name = [NameString, 'ByTrial'];
ByTrial_struct.header = ['TrialTimestamp', 'TrialNumber', TimestampedChanges_struct.header];
% we know the size and the content of the first two columns already
ByTrial_struct.data = zeros([length(TimestampList) length(ByTrial_struct.header)]);
ByTrial_struct.data(:,1) = TimestampList;
ByTrial_struct.data(:,2) = TrialNumberList;

% here we assume that the Timestamped changes are going to affect trials
% with starttimes after the change timestamp only

TrialOffset = length(TimestampList);
for iSessionRecord = size(TimestampedChanges_struct.data, 1) : -1 : 1;
	CurrentSessionRecordTS = TimestampedChanges_struct.data(iSessionRecord, TimestampedChanges_struct.cn.Timestamp);
	% loop over all not yet processed trials
	for iTrial = TrialOffset : -1 : 1
		CurrentTrialTS = TimestampList(iTrial);
		% CurrentTrialTS == 0 these are trials aborted before the animal
		% had the chance to intialize the trial (e.g. MANUAL_TRIAL_ABORT)
		% in that case simply keep the current session information as it
		% will not matter anyway, (Note, all trials should have a timestamp even aborted ones)
		if ((CurrentTrialTS >= CurrentSessionRecordTS) || (CurrentTrialTS == 0))
			% found a related trial so fill in the data
			ByTrial_struct.data(iTrial,3:end) = TimestampedChanges_struct.data(iSessionRecord, :);
		else
			TrialOffset = iTrial - 1;
			break
		end
	end
end

ByTrial_struct.cn = local_get_column_name_indices(ByTrial_struct.header);

return
end


function [ output_struct ] = fn_correct_TargetOffsetTimes_ms_from_RenderState( input_struct )
output_struct = input_struct;

%check whether TargetOffsetTimes are believable


trial_starttime_ms = input_struct.data(:, input_struct.cn.Timestamp);
TargetOffsetTimes_ms = input_struct.data(:, input_struct.cn.A_TargetOffsetTime_ms);
TargetOnsetTimes_ms = input_struct.data(:, input_struct.cn.A_TargetOnsetTime_ms);

TargetOnsetOffsetDuration_ms = TargetOffsetTimes_ms - TargetOnsetTimes_ms;

%isequal(input_struct.data(:, input_struct.cn.A_TargetOffsetTime_ms), input_struct.data(:, input_struct.cn.B_TargetOffsetTime_ms));

delta_TargetOffsetTimes_ms = TargetOffsetTimes_ms - trial_starttime_ms;

% zeros are  special values and we can safely ignore them
zero_TargetOffsetTimes_ms_idx = find(TargetOffsetTimes_ms ~= 0);
zero_trial_starttime_ms_idx = find(trial_starttime_ms ~= 0);
good_trial_idx = intersect(zero_TargetOffsetTimes_ms_idx, zero_trial_starttime_ms_idx);

% but only for non reawarded trials
% ENUM_idx allows for C# enums starting at 0, by adding an offset of one to
% the values
REWARD_OutcomeENUM_idx = input_struct.Enums.Outcomes.EnumStruct.data(input_struct.Enums.Outcomes.EnumStruct.cn.REWARD)+1;
% input_struct.unique_lists.A_OutcomeENUM{REWARD_OutcomeENUM_idx}
A_rewarded_trial_idx = find(input_struct.data(:, input_struct.cn.A_OutcomeENUM_idx) == REWARD_OutcomeENUM_idx);
B_rewarded_trial_idx = find(input_struct.data(:, input_struct.cn.B_OutcomeENUM_idx) == REWARD_OutcomeENUM_idx);
rewarded_trial_idx = intersect(A_rewarded_trial_idx, B_rewarded_trial_idx);
% rewarded trials should have no zero TargetOffsetTimes_ms or trial_starttime_ms
good_trial_idx = union(good_trial_idx, rewarded_trial_idx);


% negative deltas should not exist
max_delta = max(delta_TargetOffsetTimes_ms(good_trial_idx));
min_delta = min(delta_TargetOffsetTimes_ms(good_trial_idx));
if (min_delta < 0)
	fix_TargetOffsetTimes_ms = 1;
else
	fix_TargetOffsetTimes_ms = 0;
end
	
if (fix_TargetOffsetTimes_ms)
	% in any given trial TargetOffsetTimes_ms should correspond roughly
	% with the start of 
	error('Not implemented yet...');
	output_struct.FixUpReport{end+1} = ['fn_correct_TargetOffsetTimes_ms_from_RenderState: Corrected TargetOffsetTimes_ms from RenderState'];
end
return
end


function [ output_struct ] = fn_change_TrialSubType_information( output_struct, cur_trial_ldx, TrialSubType_col_match_string, TrialSubType_class )
verbose = 1;

if verbose
	disp(['Changing to TrialSubType information to: ', TrialSubType_class]);
end
% these are the columns we might need to fix
TrialSubType_col_ldx = contains(output_struct.header, '_TrialSubType');
TrialSubType_col_idx = find(TrialSubType_col_ldx);

cur_ENUM_idx = find(ismember(output_struct.Enums.TrialSubTypes.unique_lists.TrialSubTypes, {TrialSubType_class}));
for i_TrialSubType_col = 1 : length(TrialSubType_col_idx)
	cur_TrialSubType_col = TrialSubType_col_idx(i_TrialSubType_col);
	cur_header_col = output_struct.header{cur_TrialSubType_col};
	cur_side = cur_header_col(1);

	switch cur_header_col
		case {'A_TrialSubType_idx', 'B_TrialSubType_idx', 'A_TrialSubTypeString_idx', 'B_TrialSubTypeString_idx'}
			% ATTENTION likely wrong for sessions with multiple human
			% partners, but we want A_TrialSubTypeENUM_idx anywazs
			% per session ordered values indexing
			%keyboard	% needs some testing
			mod_cur_header_col = cur_header_col(1:end-4);
			if ~isfield(output_struct.unique_lists, mod_cur_header_col)
				output_struct.unique_lists.(mod_cur_header_col) = {};				
			end
			cur_mod_cur_header_col_idx = find(ismember(output_struct.unique_lists.(mod_cur_header_col), {TrialSubType_class}));
			if isempty(cur_mod_cur_header_col_idx)
				output_struct.unique_lists.(mod_cur_header_col)(end+1) = {TrialSubType_class};	% only add if this does not yet exist
				%output_struct.data(cur_trial_ldx, output_struct.cn.(cur_header_col)) = find(ismember(output_struct.unique_lists.(mod_cur_header_col), {TrialSubType_class}));
			else
				%disp('Doh...');
			end
			output_struct.data(cur_trial_ldx, output_struct.cn.(cur_header_col)) = find(ismember(output_struct.unique_lists.(mod_cur_header_col), {TrialSubType_class}));

		case {'A_TrialSubType', 'B_TrialSubType'}
			% original zero-based ENUM_idx	, so correct
			output_struct.data(cur_trial_ldx, output_struct.cn.(cur_header_col)) = cur_ENUM_idx - 1;

		case {'A_TrialSubTypeENUM_idx', 'B_TrialSubTypeENUM_idx'}
			% matlab style 1-based ENUM_idx
			output_struct.data(cur_trial_ldx, output_struct.cn.(cur_header_col)) = cur_ENUM_idx;
	end
end

output_struct.FixUpReport{end+1} = ['fn_change_TrialSubType_information: Fixed assignment of TrialSubType from reward data (HIT and HITOTHER): corrected TrialSubType: ', TrialSubType_class, ' (', num2str(sum(cur_trial_ldx)), ' trials)'];


end



