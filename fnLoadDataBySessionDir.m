function [ out_struct, session_id, session_id_list, session_struct_list ] = fnLoadDataBySessionDir( session_id , override_directive, merge_command )
%FNLOADDATABYSESSIONDIR Summary of this function goes here
%   Detailed explanation goes here
% given a sesssion directory load all data files

%TODO:
%	add automatic evaluation of calibration sessions to gaze data? (maybe add to fnParseEventIDETrackerLog_v01 instead)
%	with a merged_session_id flag given, merge the data of those sessions
%	Also add *.digitalinchangelog.txt files to the parsed and merged data
%
%	SESSION MERGING:
%	expect a session, with a session_merge_list (list of sessionIDs, or full paths, one per row)
%		if this is found, iteratively load each sessions data, adjust time
%		stamps (by calculating milliseconds from 2010.01.01 00:00:00) and
%		trial numbers (consequtively), keep a copy of the
%		session_merge_list in the resulting matfile, as well as copies of
%		the individual session data_structs.
%		Try to also adjust all substructures containing
%		For touch and gaze merging, also adjust time stamps and trial
%		numbers. Apply any re-recalibration before merging...




timestamps.(mfilename).start = tic;
disp(['Starting: ', mfilename]);
dbstop if error
fq_mfilename = mfilename('fullpath');
mfilepath = fileparts(fq_mfilename);

out_struct = struct();
session_struct_list = {};
session_id_list = {};

% % the idea here is to merge all session in session_id and save out as merged_session_id
% if ~exist('merged_session_id', 'var') || isempty(merged_session_id)
% 	merged_session_id = [];	% make sure merged_session_id exists
% else
% 	error('session merging not implemented yet...');
% end

% if a list of session_ids is given, report individual session data, or
% merge all of them?
if ~exist('override_directive', 'var') || isempty(override_directive)
	%override_directive = 'local'; %this allows to override automatically using the network, requires host specific changes to GetDirectoriesByHostName
	override_directive = 'local_code'; %this allows to override automatically using the network, requires host specific changes to GetDirectoriesByHostName
	%override_directive = 'local';
end

% to allow looping over a list of session_ids this should be packaged as a
% cell
if ~exist('session_id', 'var')
	session_id = '';
end

% this is for a potential remerge
if ~exist('merge_command', 'var') || isempty(merge_command)
	merge_command = '';
else
	if ~(ismember(merge_command, {'merge', 'MERGE'}))
		error(['unhandled merge_command (', merge_command, ') encountered, bailing out.']);
	end
end


if ~iscell(session_id)
	session_id_list = {session_id};
else
	session_id_list = session_id;
end



SCPDirs = GetDirectoriesByHostName(override_directive);
SCP_DATA_sub_dir = 'SCP_DATA';
session_dir_label = '.sessiondir';
% which identifiers to use to select data files from the base session_dir
base_match_string_list = {'.triallog'};	% these will also be used to truncate the filename for "magic" loading (needs support in the parsing functions)
trackerlog_sub_dir = 'trackerlogfiles';
% which identifiers to use to select data files from the trackerlog_sub_dir
tracker_match_string_list = {'.trackerlog', '.signallog'};	% these will also be used to truncate the filename for "magic" loading (needs support in the parsing functions)
[~, cur_eventide_report_parser_version_string] = fnParseEventIDEReportSCPv06([]);


merge_session_list_suffix = '.session_merge_list.txt';	% the suffix for the session merge
session_merge_list = [];	% if this is ~empty we should be in a merged/to-be-merged session

% check for a merged session
if (numel(session_id_list) == 1)
	cur_session_id = session_id_list{1};
	merge_session_id = cur_session_id;
	% now check for existence of the merge_session_list
	[ merge_session_dir, merge_session_info, merge_SETUP_sub_dir, cur_session_id ] = fn_get_session_dir_info_from_session_id(cur_session_id, SCPDirs, SCP_DATA_sub_dir, session_dir_label);
	proto_session_merge_list_name = [cur_session_id, merge_session_list_suffix];
	proto_session_merge_list_fqn = fullfile(merge_session_dir, proto_session_merge_list_name);
	proto_session_merge_list_dir_stat = dir(proto_session_merge_list_fqn);
	if ~isempty(proto_session_merge_list_dir_stat)
		% found a merge list, now read it in
		session_merge_table = readtable(proto_session_merge_list_fqn, 'FileType', 'text', 'ReadVariableNames', 0, 'Delimiter', ';'); % one session identifier per row
		session_merge_list = table2cell(session_merge_table);
	end
end	
	
% check for existence of merged results, of sufficient recency, if one is
% found, only merge if the merge_command is not empty
if ~isempty(session_merge_list)
	% 
	triallog_file_list = fn_find_matching_files(base_match_string_list, merge_session_dir);
	% construct the most recent mat file name
	cur_triallog_mat_fqn = fullfile(merge_session_dir, [cur_session_id, base_match_string_list{1}, cur_eventide_report_parser_version_string, '.mat']);
	cur_triallog_mat_fqn_dir_stat = dir(cur_triallog_mat_fqn);
	if isempty(cur_triallog_mat_fqn_dir_stat) || ~isempty(merge_command)
		merge_command = 'merge';
		session_id_list = session_merge_list;	% swap in the to-be-merged-sessions
	end
end

tmp_session_id_list = [];
% now load all the listed non commented-out sessions
for i_session = 1 : length(session_id_list)
	cur_session_id = session_id_list{i_session};
	
	% to allow using a #-prefix in the session_merge_list to temporarily
	% de-select specific rows and to add comments
 	if strcmp(cur_session_id(1), '#')
		disp(['Current session_id starts with #, so ignore it: ', cur_session_id]);
		continue
	end
	
	% allow for the merged session identifier to exist in the session list
 	if (strcmp(cur_session_id, session_id) && strcmp(merge_command, 'merge'))
		disp(['Found meta merge session in session_id_list, so commenting and skipping: ', cur_session_id]);
		session_id_list{i_session} = ['#', session_id_list{i_session};];
		continue
	end

	
	
	% if empty ask for file
	if (~exist('cur_session_id', 'var')) || isempty(cur_session_id)
		session_dir = uigetdir(fullfile(SCPDirs.SCP_DATA_BaseDir, SCP_DATA_sub_dir), 'Select the session directory.');
		
		if (isnumeric(session_dir) && (session_dir == 0))
			disp(['No sessiondir selected, bailing out.']);
			return
		end
		[~, cur_session_id, session_dir_extension] = fileparts(session_dir);
		
		if isempty(regexp(session_dir_extension, session_dir_label))
			error(['Selected session directory (', session_dir,') does not end in sessiondir, bailing out.']);
		end
		session_info = fn_parse_session_id(cur_session_id);
	else
		[ session_dir, session_info, SETUP_sub_dir, cur_session_id ] = fn_get_session_dir_info_from_session_id(cur_session_id, SCPDirs, SCP_DATA_sub_dir, session_dir_label);
	end
	
	% find the relevant files
	unique_file_list = fn_find_matching_files(base_match_string_list, session_dir);
	unique_file_list = [unique_file_list, fn_find_matching_files(tracker_match_string_list, fullfile(session_dir, trackerlog_sub_dir))];
	
	% now load the files
	for i_unique_file = 1:length(unique_file_list)
		cur_unique_file_fqn = unique_file_list{i_unique_file};
		[~, ~, cur_match_string] = fileparts(cur_unique_file_fqn);
		switch cur_match_string
			case '.triallog'
				out_struct.(cur_match_string(2:end)) = fnParseEventIDEReportSCPv06(cur_unique_file_fqn);
				out_struct.(cur_match_string(2:end)).src_fqn = cur_unique_file_fqn;
			case '.trackerlog'
				tmp_data = fnParseEventIDETrackerLog_v01( cur_unique_file_fqn, [], [], []);
				out_struct.([cur_match_string(2:end), '_', tmp_data.info.tracker_name]) = tmp_data;
				out_struct.([cur_match_string(2:end), '_', tmp_data.info.tracker_name]).src_fqn = cur_unique_file_fqn;
			case '.signallog'
				tmp_data = fnParseEventIDETrackerLog_v01( cur_unique_file_fqn, [], [], []);
				out_struct.([cur_match_string(2:end), '_', tmp_data.info.tracker_name]) = tmp_data;
				out_struct.([cur_match_string(2:end), '_', tmp_data.info.tracker_name]).src_fqn = cur_unique_file_fqn;
			otherwise
				error(['Unhandled match string encountered (', cur_match_string, '), FIXME.']);
		end
	end
	
	
	session_struct_list{end+1} = out_struct;
	tmp_session_id_list{end+1} = cur_session_id;
	
end

session_id_list = tmp_session_id_list;

% merge sessions and save merged files into the appropriate sub-directory
% of merge_session_dir
if strcmp(merge_command, 'merge')
	% merge the data and create the expected outputs
	[out_struct, session_id, session_id_list, session_struct_list] = fn_merge_session_struct_list(merge_session_id, merge_session_dir, session_struct_list, session_id_list);
	%[tmp_out_struct, tmp_session_id, tmp_session_id_list, tmp_session_struct_list] = fn_merge_session_struct_list(merge_session_id, merge_session_dir, session_struct_list, session_id_list);

end	


timestamps.(mfilename).end = toc(timestamps.(mfilename).start);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end), ' seconds.']);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end / 60), ' minutes. Done...']);

end


function [ unique_file_list ] = fn_find_matching_files( match_string_list, session_data_dir )
% find the relevant files
unique_file_list = {};
for i_match_string = 1: length(match_string_list)
	cur_match_string = match_string_list{i_match_string};
	%/Users/smoeller/DPZ/taskcontroller/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2020/200117/20200117T134623.A_SM.B_Curius.SCP_01.sessiondir
	
	% now find all filenames containing the match string
	proto_file_list = dir(fullfile(session_data_dir, ['*', cur_match_string, '*']));
	
	% ignore the suffixes past the match string
	file_list = {};
	for i_proto_file = 1 : length(proto_file_list)
		cur_name = proto_file_list(i_proto_file).name;
		% find the start of the match string
		cur_match_string_idx = strfind(cur_name, cur_match_string);
		file_list{end + 1} = fullfile(session_data_dir, cur_name(1:cur_match_string_idx-1+length(cur_match_string)));
	end
	% find and ignore duplicates
	unique_file_list = [unique_file_list, unique(file_list)];
end
return
end




function [ session_info ] = fn_parse_session_id( session_id )
%Extract the information from the session_id, e.g. from 20200106T154947.A_None.B_Curius.SCP_01

unprocessed_session_id = session_id;

% extract the session date and time
[session_date_time_string, unprocessed_session_id] = strtok(unprocessed_session_id, '.');
session_info.session_date_time_string = session_date_time_string;
[tmp_date, tmp_T_time] = strtok(session_info.session_date_time_string, 'T');
session_info.year_string = tmp_date(1:4);
session_info.month_string = tmp_date(5:6);
session_info.day_string = tmp_date(7:8);
session_info.hour_string = tmp_T_time(2:3);	% offset by the leading T
session_info.minute_string = tmp_T_time(4:5);
session_info.second_string = tmp_T_time(6:7);
session_info.YYMMDD_string = [session_info.year_string(3:4), session_info.month_string, session_info.day_string];

% get the marker for a merged session (needs to be concise)
if strcmp('M', session_date_time_string(end))
	session_info.merged_session = 1;
	session_info.merged_session_id = tmp_T_time;
else
	session_info.merged_session = 0;
	session_info.merged_session_id = [];
end

% extract the subjects
[subject_A_string, unprocessed_session_id] = strtok(unprocessed_session_id, '.');
session_info.subject_A_string = subject_A_string;
session_info.subject_A = subject_A_string(3:end);
% subject B
[subject_B_string, unprocessed_session_id] = strtok(unprocessed_session_id, '.');
session_info.subject_B_string = subject_B_string;
session_info.subject_B = subject_B_string(3:end);
session_info.subjects_string = [subject_A_string, '.', subject_B_string];

% the set-up
session_info.setup_id_string = unprocessed_session_id(2:end);

return
end

function [ session_dir, session_info, SETUP_sub_dir, cur_session_id ] = fn_get_session_dir_info_from_session_id( cur_session_id, SCPDirs, SCP_DATA_sub_dir, session_dir_label )

%test if cur_session_id is a full directory, treat as session_dir in that
%case
if isdir(cur_session_id)
	session_dir = cur_session_id;
	[~, cur_session_id, session_dir_extension] = fileparts(session_dir);
	
	if isempty(regexp(session_dir_extension, session_dir_label))
		disp(['Selected session directory (', session_dir,') does not end in sessiondir, odd, but continue as this directory was requested explicitly.']);
	end
	session_info = fn_parse_session_id(cur_session_id);
    
    switch session_info.setup_id_string
		case 'SCP_00'
			SETUP_sub_dir = 'SCP-CTRL-00';
		case 'SCP_01'
			SETUP_sub_dir = 'SCP-CTRL-01';
	end
    
    
else
	% allow .sessiondir extensions...
	[~, tmp_cur_session_id, session_dir_extension] = fileparts(cur_session_id);
	if strcmp(session_dir_extension, '.sessiondir')
		cur_session_id = tmp_cur_session_id;
		disp(['Session_id ended in .sessiondir, ignoring that part...']);
	end
	
	% try to find/construct the session_dir
	session_info = fn_parse_session_id(cur_session_id);
	switch session_info.setup_id_string
		case 'SCP_00'
			SETUP_sub_dir = 'SCP-CTRL-00';
		case 'SCP_01'
			SETUP_sub_dir = 'SCP-CTRL-01';
	end
	
	% construct the FQ session directory
	
	[tmp_path, tmp_name, tmp_ext] = fileparts(SCPDirs.SCP_DATA_BaseDir);
	if strcmp(tmp_name, SCP_DATA_sub_dir)
		% new style where the data directoty last level is SCP_DATA
		session_dir = fullfile(SCPDirs.SCP_DATA_BaseDir, SETUP_sub_dir, 'SESSIONLOGS', ...
			session_info.year_string, session_info.YYMMDD_string, [cur_session_id, session_dir_label]);
		
	else
		session_dir = fullfile(SCPDirs.SCP_DATA_BaseDir, SCP_DATA_sub_dir, SETUP_sub_dir, 'SESSIONLOGS', ...
			session_info.year_string, session_info.YYMMDD_string, [cur_session_id, session_dir_label]);
	end
end
return
end