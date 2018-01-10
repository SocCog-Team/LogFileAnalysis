function [ output_args ] = fnRenameSCPDataFiles_201801( input_args )
%FNRENAMESCPDATAFILES_201801 Make sure the renaming function will work on
%all plattforms (windows, linux, macos)
%   To make the naming of the log files more consistent in 2018 a few
%   changes are implemtented:
%
%   all ascii/text files will end with .txt
%   the eventide per trial logs (was *.log) are renamed to *.triallog.txt
%   the proximity sensor logs go from
%       *log.ProximitySensorChanges.log/*triallog.txt.ProximitySensorChanges.log
%       to *.digitalinchangelog.txt (also remove the extension of the triallog file from this name)
%   Also rename the tracker logs to sessionname.${TRACKERNAME}.trackerlog.txt
%   Potentially also put very old sessions into the new format

% TODO:
%   save a copy of the output to file (use diary)
%   process and match the tracker log files
%
% DONE:
%   add suffix to out put session directory
%   create sub directory for each year (to avoid too many files/subdirectories)
%   handle gzipped versions of the files as well
%   canonicalize the output path to



timestamps.(mfilename).start = tic;
disp(['Starting: ', mfilename]);
dbstop if error
fq_mfilename = mfilename('fullpath');
mfilepath = fileparts(fq_mfilename);


% get the code and data base directories
override_directive = 'local_code';
override_directive = 'local';
SCP_dirs = GetDirectoriesByHostName(override_directive);

% control variables
method_string = 'copy'; % either move, rename or copy
process_triallog = 1;    % this is required
session_suffix_string = '.sessiondir';
process_digitalinputlog = 1;
process_trackerlogs = 1;
process_leftovers = 1;

% where to start the search for the data files to process?
sessionlog_in_basedir_list = {fullfile(SCP_dirs.SCP_DATA_BaseDir, 'SCP-CTRL-01', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS'), ...
    fullfile(SCP_dirs.SCP_DATA_BaseDir, 'SCP-CTRL-00', 'SCP_DATA', 'SCP-CTRL-00', 'SESSIONLOGS')};

sessionlog_out_basedir_list = {fullfile(SCP_dirs.SCP_DATA_BaseDir, 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS'), ...
    fullfile(SCP_dirs.SCP_DATA_BaseDir, 'SCP_DATA', 'SCP-CTRL-00', 'SESSIONLOGS')};
% or just do the conversion in-place
%sessionlog_out_basedir_list = sessionlog_in_basedir_list;


% process all SessionLogBaseDirs
for i_sessionlog_basedir = 1 : length(sessionlog_in_basedir_list)
    current_sessionlog_in_basedir = sessionlog_in_basedir_list{i_sessionlog_basedir};
    current_sessionlog_out_basedir = sessionlog_out_basedir_list{i_sessionlog_basedir};
    
    
    if ~isempty(strfind(current_sessionlog_in_basedir, 'SCP-CTRL-01'))
        current_setup_id = 'SCP_01';
    end
    if ~isempty(strfind(current_sessionlog_in_basedir, 'SCP-CTRL-00'))
        current_setup_id = 'SCP_00';
    end
    
    % the trial log files, also rename the parsed .mat versions?
    % this also handles the creation of the out put directory structure
    if (process_triallog)
        % get all the files that match
        current_wildcardstring = ['*', current_setup_id, '.log'];
        current_matching_file_list = find_all_files(current_sessionlog_in_basedir, current_wildcardstring, 0);
        % also collect potentially gzipped versions of this file
        current_matching_file_list = [current_matching_file_list, find_all_files(current_sessionlog_in_basedir, [current_wildcardstring, '.gz'], 0);];
        
        [input_FQN_list, output_FQN_list, session_id_list] = fnProcessLogFilesFromList(current_matching_file_list, ...
            current_sessionlog_in_basedir, current_sessionlog_out_basedir, session_suffix_string,...
            [current_setup_id, '.log'], [current_setup_id, '.triallog.txt'], method_string);
        
        
        % also process newer already properly named log files (relevant for moving and to collect the sessions for processing of other log file types)
        current_wildcardstring = ['*', current_setup_id, '.triallog.txt'];
        current_matching_file_list = find_all_files(current_sessionlog_in_basedir, current_wildcardstring, 0);
        % also collect potentially gzipped versions of this file
        current_matching_file_list = [current_matching_file_list, find_all_files(current_sessionlog_in_basedir, [current_wildcardstring, '.gz'], 0);];
        
        [tmp_input_FQN_list, tmp_output_FQN_list, tmp_session_id_list] = fnProcessLogFilesFromList(current_matching_file_list, ...
            current_sessionlog_in_basedir, current_sessionlog_out_basedir, session_suffix_string,...
            [current_setup_id, '.triallog.txt'], [current_setup_id, '.triallog.txt'], method_string);
        
        input_FQN_list = [input_FQN_list, tmp_input_FQN_list];
        output_FQN_list = [output_FQN_list, tmp_output_FQN_list];
        session_id_list = [session_id_list, tmp_session_id_list];
    end
    
    % with the gzpped/unzipped, old/new suffixes there might be multiple
    % triallog files per session_id, so reduce to the unique sessions as
    % the other file types should also be session unique
    [unique_session_id_list, unique_session_idx, unique_to_instance_list_idx] = unique(session_id_list);
    % collect all the processed files per unique session_id
    if ~exist('', 'var')
        processed_files_by_session_id_list = cell(size(unique_session_id_list));
    end
    
    for i_unique_session_id = 1 : length(unique_session_id_list)
        current_session_id_instance_idx = find(unique_to_instance_list_idx == i_unique_session_id);
        % add all input files for this session to the list of processed
        % files per session
        if ~isempty(processed_files_by_session_id_list{i_unique_session_id})
            processed_files_by_session_id_list{i_unique_session_id} = [processed_files_by_session_id_list(i_unique_session_id), input_FQN_list(current_session_id_instance_idx)];
        else
            processed_files_by_session_id_list{i_unique_session_id} = input_FQN_list(current_session_id_instance_idx);
        end
    end
    input_FQN_list = input_FQN_list(unique_session_idx);
    output_FQN_list = output_FQN_list(unique_session_idx);
    session_id_list = session_id_list(unique_session_idx);
    
    
    
    
    % the proximity sensor/digitalinput log files
    if (process_digitalinputlog) && ~isempty(session_id_list)
        % the names to find, the final $ anchors the regexprep at the end
        % of the filename, also add the final names to the input_name_match_regexp_list
        % to enforce copies of the properly named files
        digitalinputlog_options.input_name_match_regexp_list =  {'.log.ProximitySensorChanges.log$', '.log.ProximitySensorChanges.log.gz$', ...
            '.triallog.txt.ProximitySensorChanges.log$', '.triallog.txt.ProximitySensorChanges.log.gz$', ...
            '.digitalinchangelog.txt', '.digitalinchangelog.txt.gz'};
        % the names to replace
        digitalinputlog_options.output_name_match_regexp_list = {'.digitalinchangelog.txt', '.digitalinchangelog.txt.gz', ...
            '.digitalinchangelog.txt', '.digitalinchangelog.txt.gz', ...
            '.digitalinchangelog.txt', '.digitalinchangelog.txt.gz'};
        processed_files_by_session_id_list = fnProcessLogtypeBySession('digitalinchangelog', digitalinputlog_options, ...
            session_id_list, input_FQN_list, output_FQN_list, processed_files_by_session_id_list, method_string);
    end
    
    
    % the tracker log files, these require renaming of the files and
    % potentially first a time based matching to the proper triallog
    if (process_trackerlogs)
        % how to detect a trackerlog, from the file name
        trackerlogs_options.input_name_match_regexp_list =  {'^TrackerLog--', '.trackerlog.txt$'};
        % the current suffixes
        trackerlogs_options.input_name_suffix_list =  {'[0-9].txt$', '[0-9].txt.gz$'};
        % the new suffixes
        trackerlogs_options.output_name_suffix_list = {'.trackerlog.txt', '.trackerlog.txt.gz'};
        
        processed_files_by_session_id_list = fnProcessLogtypeBySession('trackerlogs', trackerlogs_options, ...
            session_id_list, input_FQN_list, output_FQN_list, processed_files_by_session_id_list, method_string);
    end
    
    % all other files that might belong to the session
    % basically all files not in the processed_files_by_session_id_list for
    % each session...
    if (process_leftovers)
        
    end
end

timestamps.(mfilename).end = toc(timestamps.(mfilename).start);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end), ' seconds.']);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end / 60), ' minutes. Done...']);

return
end


function [input_FQN_list, output_FQN_list, session_id_list] = fnProcessLogFilesFromList( current_matching_file_list, current_sessionlog_in_basedir, current_sessionlog_out_basedir, session_suffix_string, in_name_expression, out_name_expression, method_string )

return_unique_sessions_only = 0;
input_FQN_list = current_matching_file_list;
output_FQN_list = cell([size(input_FQN_list)]);
session_id_list = cell([size(input_FQN_list)]);

for i_logfile = 1 : length(current_matching_file_list)
    current_log_in_FQN = current_matching_file_list{i_logfile};
    current_log_out_FQN = [];
    
    [current_log_pathstr, current_log_name, current_log_FQN_ext] = fileparts(current_log_in_FQN);
    % special case gzipped triallog files
    current_file_gz_ext_string = '';
    if strcmp(current_log_FQN_ext, '.gz')
        [~, current_log_name, current_log_FQN_ext]  = fileparts(current_log_name);
        current_file_gz_ext_string = '.gz';
    end
    
    if ~isempty(current_log_FQN_ext)
        current_log_name_ext = [current_log_name, current_log_FQN_ext];
    else
        current_log_name_ext = current_log_name;
    end
    
    % the session ID is either in the current directory name, or in the
    % actual file name
    switch in_name_expression
        case {'SCP_00.log', 'SCP_01.log'}
            % legacy
            session_id_string = current_log_name;
        otherwise
            if ~isempty(strfind(in_name_expression, '.triallog.txt'))
                session_id_string = regexprep(current_log_name_ext, '.triallog.txt', '');
            else
                disp('Could not deduce the session id from the log file name');
                session_id_string = '';
            end
    end
    session_id_list{i_logfile} = session_id_string;
    
    % replace the current_sessionlog_in_basedir string with the
    % current_sessionlog_out_basedir string
    if ~strcmp(current_sessionlog_in_basedir, current_sessionlog_out_basedir)
        current_log_pathstr = regexprep(current_log_pathstr, current_sessionlog_in_basedir, current_sessionlog_out_basedir);
    end
    
    
    % separate the date YYYYMMDD into YYYY/YYMMDD
    [tmp_pathstr, tmp_last_level_dir, tmp_last_level_dir_ext] = fileparts(current_log_pathstr);
    session_date_string = session_id_string(1:8);
    % replace any /YYYYMMMDD/ string with /YYYY/YYMMDD, add a final / to
    % avoid failure if a path ends with ".../YYYYMMDD"
    current_log_pathstr = regexprep([current_log_pathstr, filesep], [filesep, session_date_string, filesep], [filesep, session_id_string(1:4), filesep, session_id_string(3:8), filesep]);
    if strcmp(current_log_pathstr(end), filesep)
        current_log_pathstr(end) = [];
    end
    
    
    [tmp_pathstr, tmp_last_level_dir, tmp_last_level_dir_ext] = fileparts(current_log_pathstr);
    % we want ${session_id_string}${session_dir_suffix}
    if ~strcmp([tmp_last_level_dir, tmp_last_level_dir_ext], [session_id_string, session_suffix_string])
        % make sure that the session id is added to the path
        if ~strcmp(session_id_string, [tmp_last_level_dir, tmp_last_level_dir_ext])
            current_log_pathstr = fullfile(current_log_pathstr, [session_id_string, session_suffix_string]);
        end
    end
    
    % modify the name and extension
    if ~strcmp(in_name_expression, out_name_expression)
        current_log_name_ext = regexprep(current_log_name_ext, in_name_expression, out_name_expression);
    end
    
    % construct the current_triallog_out_FQN
    current_log_out_FQN = fullfile(current_log_pathstr, [current_log_name_ext, current_file_gz_ext_string]);
    [current_log_out_pathstr, current_log_out_name, current_log_out_FQN_ext] = fileparts(current_log_out_FQN);
    
    % make sure the output path actually exists.
    if isempty(dir(current_log_out_pathstr)),
        mkdir(current_log_out_pathstr);
    end
    
    
    output_FQN_list{i_logfile} = current_log_out_FQN;
    
    fnTransformInputFileToOutputFileByMethod(current_log_in_FQN, current_log_out_FQN, method_string)
end

if (return_unique_sessions_only)
    % now make sure that the ouputs only contain unique sessions
    % this is possible since we can have multiple log files per session (.log, log.gz)
    [~, unique_session_idx, ~] = unique(session_id_list);
    
    input_FQN_list = input_FQN_list(unique_session_idx);
    output_FQN_list = output_FQN_list(unique_session_idx);
    session_id_list = session_id_list(unique_session_idx);
end

return
end

function [] = fnTransformInputFileToOutputFileByMethod(input_file_FQN, output_file_FQN, method_string)
% Use method to transform input_file to output_file

% depending on the method either move/rename or copy
switch lower(method_string)
    case {'rename', 'move'}
        disp(['Moving: ', input_file_FQN]);
        disp(['    to: ', output_file_FQN]);
        movefile(input_file_FQN, output_file_FQN);
    case 'copy'
        disp(['Copying: ', input_file_FQN]);
        disp(['     to: ', output_file_FQN]);
        copyfile(input_file_FQN, output_file_FQN);
    case {'none', 'ignore'}
        disp(['Ignoring: ', input_file_FQN]);
        disp(['      to: ', output_file_FQN]);
    otherwise
        error(['Processing method: ', method_string, ' not handled yet...']);
end
return
end

function [ processed_files_by_session_id_list ] = fnProcessLogtypeBySession( logtype_string, option_struct, session_id_list, input_FQN_list, output_FQN_list, processed_files_by_session_id_list, method_string )

for i_session_id = 1 : length(session_id_list)
    current_session_id = session_id_list{i_session_id};
    [current_in_path, current_in_triallog_name, current_in_triallog_ext] = fileparts(input_FQN_list{i_session_id});
    [current_out_path, current_out_triallog_name, current_out_triallog_ext] = fileparts(output_FQN_list{i_session_id});
    
    current_processed_in_file_list = [];
    switch logtype_string
        case 'digitalinchangelog'
            current_processed_in_file_list = fnProcessDIChangelog(current_session_id, current_in_path, current_out_path, option_struct.input_name_match_regexp_list, option_struct.output_name_match_regexp_list, method_string);
            
        case 'trackerlogs'
            current_processed_in_file_list = fnProcessTrackerLogs(current_session_id, current_in_path, current_out_path, option_struct, method_string);
            
        case {'ignore this', 'ignore_this_too'}
            % just an example to show how to add log types to completely
            % ignore
        otherwise
            error(['Encountered yet unhandled log file type: ', logtype_string, ', fix me.']);
    end
    
    % add any newly processed files to the list of processed files
    if ~isempty(current_processed_in_file_list)
        if ~isempty(processed_files_by_session_id_list{i_session_id})
            processed_files_by_session_id_list{i_session_id} = [processed_files_by_session_id_list{i_session_id}, current_processed_in_file_list];
        else
            processed_files_by_session_id_list{i_session_id} = current_processed_in_file_list;
        end
        
    end
end

return
end

function [ current_processed_file_list ] = fnProcessDIChangelog(current_session_id, current_in_path, current_out_path, input_name_match_regexp_list, output_name_match_regexp_list, method_string)

current_processed_file_list = {};

% find all proximity sensor/ digitalin change log files
all_files_in_input_dir = dir(current_in_path);
% loop over all files and test whether their name matches with any of the
% entries in the input_name_match_regexp_list

for i_file = 1 : length(all_files_in_input_dir)
    current_file_struct = all_files_in_input_dir(i_file);
    for i_match_regexp = 1 : length(input_name_match_regexp_list)
        % if this matches act on this
        current_input_name_match_regexp = input_name_match_regexp_list{i_match_regexp};
        current_output_name_match_regexp = output_name_match_regexp_list{i_match_regexp};
        current_input_name_match_regexp_idx = regexp(current_file_struct.name, current_input_name_match_regexp);
        current_name_ext = [];
        % only copy if the current file name ends in the defined suffix and
        % starts with the current session_id (to pick the correct files from old sessions that stored a full days worth of sessions in a single directory)
        if ~isempty(current_input_name_match_regexp_idx) && ~isempty(regexp(current_file_struct.name, ['^', current_session_id]))
            disp(['Found match for: ', current_file_struct.name, ' -> ', current_input_name_match_regexp]);
            %[~, current_file_name, current_file_ext] = fileparts(current_file_struct.name);
            current_output_name_ext = regexprep(current_file_struct.name, current_input_name_match_regexp, current_output_name_match_regexp);
            input_file_FQN = fullfile(current_in_path, current_file_struct.name);
            output_file_FQN = fullfile(current_out_path, current_output_name_ext);
            fnTransformInputFileToOutputFileByMethod(input_file_FQN, output_file_FQN, method_string);
            current_processed_file_list{end+1} = input_file_FQN;
        end
    end
end

return
end

function [ current_processed_in_file_list ] = fnProcessTrackerLogs( current_session_id, current_in_path, current_out_path, option_struct, method_string )
% process the tracker log files
% create the canonical fullfile(current_out_path, trackerlogfiles) sub
% directory and place all trackerlogs that belong to that session there

% search for all trackerlog files in the known locations in order of ease:
%   current_in_path/trackerlogfiles/${SESSION_ID_STRING}.trackerlog.[txt|txt.gz]

%   current_in_path/${SESSION_ID_STRING}_TrackerLogs/TrackerLog--*.[txt|txt.gz]

%   current_in_path/TrackerLogs/TrackerLog--*.[txt|txt.gz]

%   current_in_path/TrackerLog--*.[txt|txt.gz]





return
end