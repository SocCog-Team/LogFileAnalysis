function [ output_args ] = fnRenameSCPDataFiles_201801( sessionlog_in_basedir_list, sessionlog_out_basedir_list, method_string )
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
%   what to do with analysis .mat files?
%   also allow to compress selected file types
%
% DONE:
%   add suffix to out put session directory
%   create sub directory for each year (to avoid too many files/subdirectories)
%   handle gzipped versions of the files as well
%   canonicalize the output path to
%   process and match the tracker log files



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
process_triallog = 1;    % this is required
session_suffix_string = '.sessiondir';
process_digitalinputlog = 1;
process_trackerlogs = 1;
process_eve_files = 1;
process_leftovers = 1;

if ~exist('sessionlog_out_basedir_list', 'var') || isempty(sessionlog_in_basedir_list)
    % where to start the search for the data files to process?
    sessionlog_in_basedir_list = {fullfile(SCP_dirs.SCP_DATA_BaseDir, 'SCP-CTRL-01', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS'), ...
        fullfile(SCP_dirs.SCP_DATA_BaseDir, 'SCP-CTRL-00', 'SCP_DATA', 'SCP-CTRL-00', 'SESSIONLOGS')};
end
if ~exist('sessionlog_out_basedir_list', 'var') || isempty(sessionlog_out_basedir_list)
    sessionlog_out_basedir_list = {fullfile(SCP_dirs.SCP_DATA_BaseDir, 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS'), ...
        fullfile(SCP_dirs.SCP_DATA_BaseDir, 'SCP_DATA', 'SCP-CTRL-00', 'SESSIONLOGS')};
end
if ~exist('method_string', 'var') || isempty(method_string)
    method_string = 'copy'; % either move, rename or copy, ignore
end
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
        
        [input_FQN_list, output_FQN_list, session_id_list, session_dir_list] = fnProcessLogFilesFromList(current_matching_file_list, ...
            current_sessionlog_in_basedir, current_sessionlog_out_basedir, session_suffix_string,...
            [current_setup_id, '.log'], [current_setup_id, '.triallog.txt'], method_string);
        
        
        % also process newer already properly named log files (relevant for moving and to collect the sessions for processing of other log file types)
        current_wildcardstring = ['*', current_setup_id, '.triallog.txt'];
        current_matching_file_list = find_all_files(current_sessionlog_in_basedir, current_wildcardstring, 0);
        % also collect potentially gzipped versions of this file
        current_matching_file_list = [current_matching_file_list, find_all_files(current_sessionlog_in_basedir, [current_wildcardstring, '.gz'], 0);];
        
        [tmp_input_FQN_list, tmp_output_FQN_list, tmp_session_id_list, tmp_session_dir_list] = fnProcessLogFilesFromList(current_matching_file_list, ...
            current_sessionlog_in_basedir, current_sessionlog_out_basedir, session_suffix_string,...
            [current_setup_id, '.triallog.txt'], [current_setup_id, '.triallog.txt'], method_string);
        
        input_FQN_list = [input_FQN_list, tmp_input_FQN_list];
        output_FQN_list = [output_FQN_list, tmp_output_FQN_list];
        session_id_list = [session_id_list, tmp_session_id_list];
        session_dir_list = [session_dir_list, tmp_session_dir_list];
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
    session_dir_list = session_dir_list(unique_session_idx);
    
    
    
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
            session_id_list, session_dir_list, input_FQN_list, output_FQN_list, processed_files_by_session_id_list, method_string);
    end
    
    
    % the tracker log files, these require renaming of the files and
    % potentially first a time based matching to the proper triallog
    if (process_trackerlogs)
        % how to detect a trackerlog, from the file name
        trackerlogs_options.input_name_match_regexp_list =  {'^TrackerLog--', '.trackerlog.txt'};
        % the current suffixes
        trackerlogs_options.input_name_suffix_list =  {'[0-9].txt$', '[0-9].txt.gz$'};
        % the new suffixes
        trackerlogs_options.output_name_suffix_list = {'.trackerlog.txt', '.trackerlog.txt.gz'};
        trackerlogs_options.output_subdirname = 'trackerlogfiles';
        processed_files_by_session_id_list = fnProcessLogtypeBySession('trackerlogs', trackerlogs_options, ...
            session_id_list, session_dir_list, input_FQN_list, output_FQN_list, processed_files_by_session_id_list, method_string);
    end
    
    if (process_eve_files)        
        % eve files
        % how to detect a trackerlog, from the file name
        eve_options.input_name_match_regexp_list =  {'.eve$', '.eve.gz$'};
        % the current suffixes
        eve_options.input_name_suffix_list =  {'.eve$', '.eve.gz$'};
        % the new suffixes
        eve_options.output_name_suffix_list = {'.eve', '.eve.gz'};
        processed_files_by_session_id_list = fnProcessLogtypeBySession('eve_files', eve_options, ...
            session_id_list, session_dir_list, input_FQN_list, output_FQN_list, processed_files_by_session_id_list, method_string);        
    end
    
    
    % all other files that might belong to the session
    % basically all files not in the processed_files_by_session_id_list for
    % each session...
    if (process_leftovers)
        % like the eve files and anything with the sessionID in the name
        leftover_options.input_wildcard_string = '*.*';
        processed_files_by_session_id_list = fnProcessLogtypeBySession('leftovers', leftover_options, ...
            session_id_list, session_dir_list, input_FQN_list, output_FQN_list, processed_files_by_session_id_list, method_string);                
    end
end

timestamps.(mfilename).end = toc(timestamps.(mfilename).start);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end), ' seconds.']);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end / 60), ' minutes. Done...']);

return
end


function [input_FQN_list, output_FQN_list, session_id_list, session_dir_list] = fnProcessLogFilesFromList( current_matching_file_list, current_sessionlog_in_basedir, current_sessionlog_out_basedir, session_suffix_string, in_name_expression, out_name_expression, method_string )

return_unique_sessions_only = 0;
input_FQN_list = current_matching_file_list;
output_FQN_list = cell([size(input_FQN_list)]);
session_id_list = cell([size(input_FQN_list)]);
session_dir_list = cell([size(input_FQN_list)]);

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
                if (isunix)
                    session_id_string = regexprep(current_log_name_ext, '.triallog.txt', '');
                else
                    session_id_string = strrep(current_log_name_ext, '.triallog.txt', '');
                end
            else
                disp('Could not deduce the session id from the log file name');
                session_id_string = '';
            end
    end
    session_id_list{i_logfile} = session_id_string;
    session_dir_list{i_logfile} = current_log_pathstr;
    
    % replace the current_sessionlog_in_basedir string with the
    % current_sessionlog_out_basedir string
    if ~strcmp(current_sessionlog_in_basedir, current_sessionlog_out_basedir)
        if (isunix)
            current_log_pathstr = regexprep(current_log_pathstr, current_sessionlog_in_basedir, current_sessionlog_out_basedir);
        else
            current_log_pathstr = strrep(current_log_pathstr, current_sessionlog_in_basedir, current_sessionlog_out_basedir);
        end
    end
    
    
    % separate the date YYYYMMDD into YYYY/YYMMDD
    [tmp_pathstr, tmp_last_level_dir, tmp_last_level_dir_ext] = fileparts(current_log_pathstr);
    session_date_string = session_id_string(1:8);
    % replace any /YYYYMMMDD/ string with /YYYY/YYMMDD, add a final / to
    % avoid failure if a path ends with ".../YYYYMMDD"
    if (isunix)
        current_log_pathstr = regexprep([current_log_pathstr, filesep], [filesep, session_date_string, filesep], [filesep, session_id_string(1:4), filesep, session_id_string(3:8), filesep]);
    else
        current_log_pathstr = strrep([current_log_pathstr, filesep], [filesep, session_date_string, filesep], [filesep, session_id_string(1:4), filesep, session_id_string(3:8), filesep]);
    end
    if strcmp(current_log_pathstr(end), filesep)
        current_log_pathstr(end) = [];
    end
    
    
    [tmp_pathstr, tmp_last_level_dir, tmp_last_level_dir_ext] = fileparts(current_log_pathstr);
    % we want ${session_id_string}${session_dir_suffix}
    if ~strcmp([tmp_last_level_dir, tmp_last_level_dir_ext], [session_id_string, session_suffix_string])
        % make sure that the session id is added to the path
        
        if (strcmp(session_id_string, [tmp_last_level_dir, tmp_last_level_dir_ext]))
            current_log_pathstr = fullfile(tmp_pathstr, [session_id_string, session_suffix_string]);
        else
            current_log_pathstr = fullfile(current_log_pathstr, [session_id_string, session_suffix_string]);
        end
    end
    
    % modify the name and extension
    if ~strcmp(in_name_expression, out_name_expression)
        if (isunix)
            current_log_name_ext = regexprep(current_log_name_ext, in_name_expression, out_name_expression);
        else
            current_log_name_ext = strrep(current_log_name_ext, in_name_expression, out_name_expression);
        end
    end
    
    % construct the current_triallog_out_FQN
    current_log_out_FQN = fullfile(current_log_pathstr, [current_log_name_ext, current_file_gz_ext_string]);
    [current_log_out_pathstr, current_log_out_name, current_log_out_FQN_ext] = fileparts(current_log_out_FQN);
    
    % make sure the output path actually exists.
    if isempty(dir(current_log_out_pathstr)),
        mkdir(current_log_out_pathstr);
    end
    
    
    output_FQN_list{i_logfile} = current_log_out_FQN;
    
    status = fnTransformInputFileToOutputFileByMethod(current_log_in_FQN, current_log_out_FQN, method_string);
end

if (return_unique_sessions_only)
    % now make sure that the ouputs only contain unique sessions
    % this is possible since we can have multiple log files per session (.log, log.gz)
    [~, unique_session_idx, ~] = unique(session_id_list);
    
    input_FQN_list = input_FQN_list(unique_session_idx);
    output_FQN_list = output_FQN_list(unique_session_idx);
    session_id_list = session_id_list(unique_session_idx);
    session_dir_list = session_dir_list(unique_session_idx);
end

return
end

% function [status, out_struct] = fnDoTransformInputFileToOutputFileByMethod(input_file_FQN, output_file_FQN, method_string)
% 
% out_struct.status = 1;  % 1 success 0 failure
% out_struct.message = '';
% out_struct.messageid = '';
% 
% % depending on the method either move/rename or copy
% switch lower(method_string)
%     case {'rename', 'move'}
%         disp(['Moving: ', input_file_FQN]);
%         disp(['    to: ', output_file_FQN]);
%         [out_struct.status, out_struct.message, out_struct.messageid] = movefile(input_file_FQN, output_file_FQN);
%     case 'copy'
%         disp(['Copying: ', input_file_FQN]);
%         disp(['     to: ', output_file_FQN]);
%         [out_struct.status, out_struct.message, out_struct.messageid] = copyfile(input_file_FQN, output_file_FQN);
%     case {'none', 'ignore'}
%         disp(['Ignoring: ', input_file_FQN]);
%         disp(['      to: ', output_file_FQN]);
%     case {'fail', 'break'}
%         % this is for debugging
%         disp(['Failing: ', input_file_FQN]);
%         disp(['     to: ', output_file_FQN]);
%         out_struct.status = 0;
%     case {'gzip', 'gzip_copy'}
%         disp(['Gzipping : ', input_file_FQN]);
%         disp(['(copy) to: ', [output_file_FQN, '.gz']]);
%         gzip(input_file_FQN, fileparts(output_file_FQN));
%         % did we actually write the target file
%         if ~exist([output_file_FQN, '.gz'], 'file') || isdir([output_file_FQN, '.gz'])
%             out_struct.status = 0;
%         end
%     case {'gzip_move'}
%         disp(['Gzipping : ', input_file_FQN]);
%         disp(['(move) to: ', [output_file_FQN, '.gz']]);
%         gzip(input_file_FQN, fileparts(output_file_FQN));
%         if ~exist([output_file_FQN, '.gz'], 'file') || isdir([output_file_FQN, '.gz'])
%             out_struct.status = 0;
%         end
%         delete(input_file_FQN);
%     otherwise
%         error(['Processing method: ', method_string, ' not handled yet...']);
% end
% 
% % to allow easier use of this function as boolean
% status = out_struct.status;
% 
% return
% end

% function [status] = fnTransformInputFileToOutputFileByMethod(input_file_FQN, output_file_FQN, method_string)
% % Use method to transform input_file to output_file
% 
% persistent AssignedWinDriveLettersList input_subst_drive_letter output_subst_drive_letter
% 
% if (ispc)
%     % only do these things once...
%     if isempty(AssignedWinDriveLettersList)
%         AssignedWinDriveLettersList = fnGetWindowsDriveLetterList();
%     end
%     if isempty(input_subst_drive_letter)
%         input_subst_drive_letter = fnSubstDrivePathToNextFreeDriveLetter(input_file_FQN, 'SESSIONLOGS', 'delete');
%     end
%     if isempty(output_subst_drive_letter)
%         output_subst_drive_letter = fnSubstDrivePathToNextFreeDriveLetter(output_file_FQN, 'SESSIONLOGS', 'delete');
%     end
% end
% 
% %TODO: make sure that the output_directory actually exists
% % [out_path, ~, ~] = fileparts(output_file_FQN)
% %if isempty(dir(out_path))
% %    mkdir(out_path)
% %end
% 
% % instead of trying to gzip a file twice, just copy/move it
% [in_path, in_name, in_ext] = fileparts(input_file_FQN);
% if (length(in_path) > 247)
%     % with only one level of substs we can not actually deal with that so
%     % error out, see https://msdn.microsoft.com/en-us/library/aa365247%28VS.85%29.aspx?f=255&MSPPError=-2147217396#maxpath
%     error('Encountered input path > 247 characters, too long to currently handle...');
% end
% 
% [out_path, out_name, out_ext] = fileparts(output_file_FQN);
% if (length(out_path) > 247)
%     % with only one level of substs we can not actually deal with that so
%     % error out, see https://msdn.microsoft.com/en-us/library/aa365247%28VS.85%29.aspx?f=255&MSPPError=-2147217396#maxpath
%     error('Encountered output path > 247 characters, too long to currently handle...');
% end
% 
% 
% % make sure the output path exists
% if ~strcmp(method_string, 'ignore') && ~isdir(out_path)
%     mkdir(out_path);
% end
% 
% if strcmp(in_ext, '.gz')
%     switch lower(method_string)
%         case {'gzip', 'gzip_copy'}
%             disp('Input file is already gzipped, copying instead of zipping again.');
%             method_string = 'copy';
%         case {'gzip_move'}
%             disp('Input file is already gzipped, moving instead of zipping again.');
%             method_string = 'move';
%     end
% end
% 
% 
% % now try to process the files
% [status, cmd_output] = fnDoTransformInputFileToOutputFileByMethod(input_file_FQN, output_file_FQN, method_string);
% 
% if (ispc) && (status == 0)
%     % the initial attempt at transfering the file failed, if on windows
%     % this might be related to the path length limit,
%     % windows seems to enforce that absolute filenames (including the drive
%     % letter) are <= 260 characters long, this is less than ideal, but
%     % can be worked around by using the subst command to turn the over-long
%     % paths into short drive letters.
%     
%     if ((length(output_file_FQN) > 259) || ((length(input_file_FQN) > 259)))
%         disp(['The initial attempt to process ', input_file_FQN, ' failed!']);
%         disp('We encountered path component(s) larger than windows'' traditional limit of ~260 characters.');
%         disp(['Input FQN length: ', num2str(length(input_file_FQN)), '; Output FQN length: ', num2str(length(output_file_FQN))]);
%         
%         
%         %[in_path, in_name, in_ext] = fileparts(input_file_FQN);
%         if ~isempty(input_subst_drive_letter) && (length(input_file_FQN) > 260)
%             disp(['Substituting ', input_subst_drive_letter, ' for ', in_path]);
%             [subst_status, subst_output] = system(['subst ', input_subst_drive_letter, ' ', in_path]);
%             tmp_input_file_FQN = fullfile(input_subst_drive_letter, [in_name, in_ext]);
%         else
%             tmp_input_file_FQN = input_file_FQN;
%         end
%         
%         %[out_path, out_name, out_ext] = fileparts(output_file_FQN);
%         if ~isempty(output_subst_drive_letter) && (length(output_file_FQN) > 260)
%             disp(['Substituting ', output_subst_drive_letter, ' for ', out_path]);
%             [subst_status, subst_output] = system(['subst ', output_subst_drive_letter, ' ', out_path]);
%             tmp_output_file_FQN = fullfile(output_subst_drive_letter, [out_name, out_ext]);
%         else
%             tmp_output_file_FQN = output_file_FQN;
%         end
%         % now try again
%         [status, cmd_output] = fnDoTransformInputFileToOutputFileByMethod(tmp_input_file_FQN, tmp_output_file_FQN, method_string);
%         
%         % clean up the subst junk
%         if ~isempty(input_subst_drive_letter) && (length(input_file_FQN) > 260)
%             [subst_status, subst_output] = system(['subst ', input_subst_drive_letter, ' /d']);
%             tmp_input_file_FQN = [];
%         end
%         
%         if ~isempty(output_subst_drive_letter) && (length(output_file_FQN) > 260)
%             [subst_status, subst_output] = system(['subst ', output_subst_drive_letter, ' /d']);
%             tmp_output_file_FQN = [];
%         end
%         
%         
%     end
% end
% 
% if ~status
%     if strcmp(method_string, 'fail')
%         disp(['Succeeded to ', method_string, ' ', input_file_FQN, ' to ', output_file_FQN]);
%     else
%         disp(['Failed to ', method_string, ' ', input_file_FQN, ' to ', output_file_FQN]);
%         keyboard ; % use dbcont to resume execution
%     end
% end
% 
% return
% end

function [ processed_files_by_session_id_list ] = fnProcessLogtypeBySession( logtype_string, option_struct, session_id_list, session_dir_list, input_FQN_list, output_FQN_list, processed_files_by_session_id_list, method_string )

for i_session_id = 1 : length(session_id_list)
    current_session_id = session_id_list{i_session_id};
    [current_in_path, current_in_triallog_name, current_in_triallog_ext] = fileparts(input_FQN_list{i_session_id});
    [current_out_path, current_out_triallog_name, current_out_triallog_ext] = fileparts(output_FQN_list{i_session_id});
    
    current_processed_in_file_list = [];
    switch logtype_string
        case 'digitalinchangelog'
            current_processed_in_file_list = fnProcessDIChangelog(current_session_id, current_in_path, current_out_path, option_struct.input_name_match_regexp_list, option_struct.output_name_match_regexp_list, method_string);
            
        case 'trackerlogs'
            current_processed_in_file_list = fnProcessTrackerLogs(current_session_id, current_in_path, current_out_path, ...
                option_struct.input_name_match_regexp_list, option_struct.input_name_suffix_list, ...
                option_struct.output_subdirname, method_string);

        case 'eve_files'
            current_processed_in_file_list = fnProcessEveFiles(current_session_id, current_in_path, current_out_path, ...
                option_struct.input_name_match_regexp_list, option_struct.input_name_suffix_list, ...
                method_string);

        case 'leftovers'
            % find all sessions that got data from the same directory
            current_session_dir = session_dir_list{i_session_id};
            same_dir_session_idx = find(strcmp(session_dir_list, current_session_dir));
            processed_files_in_current_session_dir = {};
            for i_same_dir_session = 1 : length(same_dir_session_idx)
                processed_files_in_current_session_dir = [processed_files_in_current_session_dir, processed_files_by_session_id_list{same_dir_session_idx(i_same_dir_session)}];
            end
            
            current_processed_in_file_list = fnProcessLeftovers(current_session_id, processed_files_in_current_session_dir, current_in_path, current_out_path, ...
                option_struct.input_wildcard_string, ...
                method_string);
            
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

function [ current_processed_in_file_list ] = fnProcessDIChangelog(current_session_id, current_in_path, current_out_path, input_name_match_regexp_list, output_name_match_regexp_list, method_string)

current_processed_in_file_list = {};

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
            if (isunix)
                current_output_name_ext = regexprep(current_file_struct.name, current_input_name_match_regexp, current_output_name_match_regexp);
            else
                current_output_name_ext = strrep(current_file_struct.name, current_input_name_match_regexp, current_output_name_match_regexp);
            end
            input_file_FQN = fullfile(current_in_path, current_file_struct.name);
            output_file_FQN = fullfile(current_out_path, current_output_name_ext);
            status = fnTransformInputFileToOutputFileByMethod(input_file_FQN, output_file_FQN, method_string);
            if (status)
                current_processed_in_file_list{end+1} = input_file_FQN;
            end
        end
    end
end

return
end

function [ current_processed_in_file_list ] = fnProcessTrackerLogs( current_session_id, current_in_path, current_out_path, input_name_match_regexp_list, input_name_suffix_list, output_subdirname, method_string )
% process the tracker log files
% create the canonical fullfile(current_out_path, trackerlogfiles) sub
% directory and place all trackerlogs that belong to that session there
% TODO: if the experiment was started early but the subject not in the
% set-up the triallog sessionID time will be too early (but the start time
% in the header should be okay

% overridable defaults
if ~exist('input_name_match_regexp_list', 'var') || isempty(input_name_match_regexp_list)
    input_name_match_regexp_list =  {'^TrackerLog--', '.trackerlog.txt$', '.trackerlog.txt.gz$'};
end
if ~exist('input_name_suffix_list', 'var') || isempty(input_name_suffix_list)
    input_name_suffix_list =  {'[0-9].txt$', '[0-9].txt.gz$'};
end
if ~exist('output_name_suffix_list', 'var') || isempty(output_name_suffix_list)
    output_name_suffix_list =  {'.trackerlog.txt', '.trackerlog.txt.gz'};
end
if ~exist('output_subdirname', 'var') || isempty(output_subdirname)
    output_subdirname =  'trackerlogfiles';
end

current_processed_in_file_list = {};
% the pattern for the dir() used to collect the proto_tracker_logfiles
trackerlog_file_dir_wildcard_string = '*racker*og*.*';
current_session_path = current_in_path;

% where to store the trackerlog files
output_path = fullfile(current_out_path, output_subdirname);
% make sure the output path actually exists.
if isempty(dir(output_path)),
    mkdir(output_path);
end

input_file_FQN_list = {};
%output_file_FQN_list = {};

trackerlog_sessionID_confirmed = {};

% search for all trackerlog files in the known locations in order of ease:
%   current_in_path/trackerlogfiles/${SESSION_ID_STRING}.TID_${TRACKER_ID_STRING}.trackerlog.[txt|txt.gz]
current_trackerlog_subdir = fullfile(current_in_path, 'trackerlogfiles');
if isdir(current_trackerlog_subdir)
    tmp_file_list = dir(fullfile(current_trackerlog_subdir, trackerlog_file_dir_wildcard_string));
    for i_file_in_dir = 1 : length(tmp_file_list)
        if ~(tmp_file_list(i_file_in_dir).isdir)
            input_file_FQN_list{end + 1} = fullfile(current_trackerlog_subdir, tmp_file_list(i_file_in_dir).name);
            trackerlog_sessionID_confirmed{end+1} = 1;
        end
    end
end

%   current_in_path/${SESSION_ID_STRING}_TrackerLogs/TrackerLog--*.[txt|txt.gz]
current_trackerlog_subdir = fullfile(current_in_path, [current_session_id, '_TrackerLogs']);
if isdir(current_trackerlog_subdir)
    tmp_file_list = dir(fullfile(current_trackerlog_subdir, trackerlog_file_dir_wildcard_string));
    for i_file_in_dir = 1 : length(tmp_file_list)
        if ~(tmp_file_list(i_file_in_dir).isdir)
            input_file_FQN_list{end + 1} = fullfile(current_trackerlog_subdir, tmp_file_list(i_file_in_dir).name);
            trackerlog_sessionID_confirmed{end+1} = 1;
        end
    end
end

%   current_in_path/TrackerLogs/TrackerLog--*.[txt|txt.gz
current_trackerlog_subdir = fullfile(current_in_path, 'TrackerLogs');
if isdir(current_trackerlog_subdir)
    tmp_file_list = dir(fullfile(current_trackerlog_subdir, trackerlog_file_dir_wildcard_string));
    for i_file_in_dir = 1 : length(tmp_file_list)
        if ~(tmp_file_list(i_file_in_dir).isdir)
            input_file_FQN_list{end + 1} = fullfile(current_trackerlog_subdir, tmp_file_list(i_file_in_dir).name);
            trackerlog_sessionID_confirmed{end+1} = 0;
        end
    end
end

% search directly in current_in_path
% current_in_path/TrackerLog--*.[txt|txt.gz]
%proto_trackerlogfile_list = dir(fullfile(current_in_path, 'TrackerLog--*.txt'));
current_trackerlog_subdir = fullfile(current_in_path);
tmp_file_list = dir(fullfile(current_trackerlog_subdir, trackerlog_file_dir_wildcard_string));
for i_file_in_dir = 1 : length(tmp_file_list)
    if ~(tmp_file_list(i_file_in_dir).isdir)
        input_file_FQN_list{end + 1} = fullfile(current_trackerlog_subdir, tmp_file_list(i_file_in_dir).name);
        trackerlog_sessionID_confirmed{end+1} = 0;
    end
end


% do the actual file processing
for i_input_file_FQN = 1 : length(input_file_FQN_list)
    current_input_file_FQN = input_file_FQN_list{i_input_file_FQN};
    %current_output_file_FQN = output_file_FQN_list{i_input_file_FQN};
    
    [current_input_path, current_input_name, current_input_ext] = fileparts(current_input_file_FQN);
    current_input_name_ext = [current_input_name, current_input_ext];
    % if the input file name already contains the sessionID, believe it
    if ~isempty(regexp(current_input_name_ext, ['^', current_session_id]))
        trackerlog_sessionID_confirmed{i_input_file_FQN} = 1;
    end
    
    
    for i_input_name_match_regexp = 1 : length(input_name_match_regexp_list)
        current_input_name_match_regexp = input_name_match_regexp_list{i_input_name_match_regexp};
        
        % check whther the name matches the wildcard
        if (regexp(current_input_name_ext, current_input_name_match_regexp))
            % test whether current_input_file_FQN matches the sessionID
            current_trackerlog_info = fnParseEventideTracklogName(current_input_name_ext);
            
            %extract the time of day in ms from the session id
            current_session_time_string = current_session_id(10:15);
            current_session_time_ms = 1000 * ((str2double(current_session_time_string(1:2)) * 60 * 60) + (str2double(current_session_time_string(3:4)) * 60) + (str2double(current_session_time_string(5:6))));

            % TODO: also look inside the triallog's header to get
            % eventIDE's idea about the start time
            % search for the triallog file in the ouput directory (so the name is less variable)
            if ~strcmp(method_string, 'ignore')
                current_triallog_session_start_time_string = fnExtractEventIDEStartTimeFromReport(current_out_path, [current_session_id, '*.triallog.txt']);
            else
                current_triallog_session_start_time_string = fnExtractEventIDEStartTimeFromReport(current_in_path, [current_session_id, '*.triallog.txt']);
                if isempty(current_triallog_session_start_time_string)
                    current_triallog_session_start_time_string = fnExtractEventIDEStartTimeFromReport(current_in_path, [current_session_id, '.log']);
                end
            end
            if ~isempty(current_triallog_session_start_time_string)
                current_triallog_session_start_time_ms = 1000 * ((str2double(current_triallog_session_start_time_string(1:2)) * 60 * 60) + (str2double(current_triallog_session_start_time_string(3:4)) * 60) + (str2double(current_triallog_session_start_time_string(5:6))));
                current_session_time_ms = current_triallog_session_start_time_ms;
            end
            
            % if the time difference from session time to trackerlog file
            % name time is less than a minute then assume a match
            % do not check if the sessionID of the trackrelogs was already
            % confirmed bu other means
            if (abs(current_trackerlog_info.time_ms/60000 - round(current_session_time_ms/60000)) <= 1) || trackerlog_sessionID_confirmed{i_input_file_FQN}
                disp(['TrackerLog: ', current_input_name_ext, ' is matched to sessionID: ', current_session_id]);
                out_extension = '.trackerlog.txt';
                if (current_trackerlog_info.ext_is_gz)
                    out_extension = [out_extension, '.gz'];
                end
                
                output_file_FQN = fullfile(output_path, [current_session_id, '.TID_', current_trackerlog_info.trackerID, out_extension]);
                status = fnTransformInputFileToOutputFileByMethod(current_input_file_FQN, output_file_FQN, method_string);
                if (status)
                    current_processed_in_file_list{end+1} = current_input_file_FQN;
                end
            end
        end
    end
end

return
end

function [ current_processed_in_file_list ] = fnProcessEveFiles( current_session_id, current_in_path, current_out_path, input_name_match_regexp_list, input_name_suffix_list, method_string )
% process the eve files
% if an eve file's name is not containing the current sessionID refrain
% from moving/renaming it, but copy it instead, it might be actually been
% used by multiple experiments.


% overridable defaults
if ~exist('input_name_match_regexp_list', 'var') || isempty(input_name_match_regexp_list)
    input_name_match_regexp_list =  {'.eve$', '.eve.gz$'};
end
if ~exist('input_name_suffix_list', 'var') || isempty(input_name_suffix_list)
    input_name_suffix_list =  {'.eve$', '.eve.gz$'};
end
if ~exist('output_name_suffix_list', 'var') || isempty(output_name_suffix_list)
    output_name_suffix_list =  {'.eve', '.eve.gz'};
end
if ~exist('output_subdirname', 'var') || isempty(output_subdirname)
    output_subdirname =  'trackerlogfiles';
end

current_processed_in_file_list = {};
% the pattern for the dir() used to collect the proto_tracker_logfiles
eve_file_dir_wildcard_string = '*.*';

% where to store the trackerlog files
output_path = fullfile(current_out_path);
% make sure the output path actually exists.
if isempty(dir(output_path)),
    mkdir(output_path);
end



input_file_FQN_list = {};
%output_file_FQN_list = {};


% search directly in current_in_path
% current_in_path/TrackerLog--*.[txt|txt.gz]
%proto_trackerlogfile_list = dir(fullfile(current_in_path, 'TrackerLog--*.txt'));
current_eve_subdir = fullfile(current_in_path);
tmp_file_list = dir(fullfile(current_eve_subdir, eve_file_dir_wildcard_string));
for i_file_in_dir = 1 : length(tmp_file_list)
    if ~(tmp_file_list(i_file_in_dir).isdir)
        input_file_FQN_list{end + 1} = fullfile(current_eve_subdir, tmp_file_list(i_file_in_dir).name);
    end
end


% do the actual file processing
for i_input_file_FQN = 1 : length(input_file_FQN_list)
    current_input_file_FQN = input_file_FQN_list{i_input_file_FQN};
    %current_output_file_FQN = output_file_FQN_list{i_input_file_FQN};
    
    [current_input_path, current_input_name, current_input_ext] = fileparts(current_input_file_FQN);
    current_input_name_ext = [current_input_name, current_input_ext];
    
    
    for i_input_name_match_regexp = 1 : length(input_name_match_regexp_list)
        current_input_name_match_regexp = input_name_match_regexp_list{i_input_name_match_regexp};
        
        current_method_string = method_string;
        % check whther the name matches the wildcard
        if (regexp(current_input_name_ext, current_input_name_match_regexp))

 
                disp(['EVE: ', current_input_name_ext, ' is matched to sessionID: ', current_session_id]);
                
                out_extension = '.eve';
                if (strcmp(current_input_ext, '.gz'))
                    out_extension = [out_extension, '.gz'];
                end
                
                % if the eve does not have the session identifier in the
                % name the eve might have been used from multiple
                % experiments in that case never move, but copy to all
                % sessionIDs that have trillog files in the current
                % directory
                if isempty(strfind(current_input_name_ext, current_session_id))
                   if ismember(current_method_string, {'rename', 'move'})
                       disp(['Ambiguous EVE file (missing session identifier in filename), will not be moved but copied: ', current_input_name_ext]);
                       current_method_string = 'copy';
                   end
                end
                
                
                % do not modify the eve file names as they are referenced
                % from inside the triallog file
                output_file_FQN = fullfile(output_path, current_input_name_ext);
                status = fnTransformInputFileToOutputFileByMethod(current_input_file_FQN, output_file_FQN, current_method_string);
                if (status)
                    current_processed_in_file_list{end+1} = current_input_file_FQN;
                end
        end
    end
end

return
end


function [ current_processed_in_file_list ] = fnProcessLeftovers( current_session_id, processed_files_in_current_session_dir, current_in_path, current_out_path, input_wildcard_string, method_string )
% process the eve files
% if an eve file's name is not containing the current sessionID refrain
% from moving/renaming it, but copy it instead, it might be actually been
% used by multiple experiments.


% overridable defaults
if ~exist('input_wildcard_string', 'var') || isempty(input_wildcard_string)
    input_wildcard_string =  [current_session_id, '*.*'];
end

current_processed_in_file_list = {};
% the pattern for the dir() used to collect the proto_tracker_logfiles
session_file_dir_wildcard_string = '*.*';

% where to store the trackerlog files
output_path = fullfile(current_out_path);
% make sure the output path actually exists.
if isempty(dir(output_path)),
    mkdir(output_path);
end

input_file_FQN_list = {};
%output_file_FQN_list = {};

% this is a bit rough, but should catch all leftovers
input_file_FQN_list = find_all_files(current_in_path, input_wildcard_string, 0);


% do the actual file processing
for i_input_file_FQN = 1 : length(input_file_FQN_list)
    current_input_file_FQN = input_file_FQN_list{i_input_file_FQN};
    %current_output_file_FQN = output_file_FQN_list{i_input_file_FQN};
    
    [current_input_path, current_input_name, current_input_ext] = fileparts(current_input_file_FQN);
    current_input_name_ext = [current_input_name, current_input_ext];
    % ignore . and .. dir results
    if ismember(current_input_name_ext, {'.', '..'})
        continue
    end
    
    % test whether this is a TrackerLog, as all matching trackerlogs should
    % be handled already move this into its own directory structure
    % these mnost likely belong to triallogs that were not saved and hence
    % could be ignored
    if (regexp(current_input_name_ext, '^TrackerLog--'))
        % all trackerlogs should already been processed, so put these into a
        % dedicated directory just as a safety measure
        current_trackerlog_info = fnParseEventideTracklogName(current_input_name_ext);
        % now modify the output path
        setup_name_start_idx = strfind(current_session_id, '.SCP_');
        setup_string = current_session_id(setup_name_start_idx+1: end);
        proto_session_id = [current_trackerlog_info.session_time_string, '.A_Name.B_Name.', setup_string];
        orig_output_path = output_path;
        output_path = strrep(output_path, [filesep, 'SESSIONLOGS', filesep], [filesep, 'LEFTOVERS', filesep]);
        output_path = strrep(output_path, [filesep, current_session_id, '.sessiondir'], [filesep, proto_session_id, '.sessiondir']);       
    end
    
    
    % keep existing sub directory unless they are empty.
    current_output_path = output_path;
    if ~strcmp(current_input_path, current_in_path)
        % so we found something in a sub directory
        if (isunix)
            current_in_sub_dir = regexprep(current_input_path, ['^', current_in_path], '');
        else
            current_in_sub_dir = strrep(current_input_path, current_in_path, '');
        end
        current_output_path = fullfile(current_output_path, current_in_sub_dir);
        % does the output directory already exist?
        if (length(dir(current_output_path)) == 2)
            % if there are actual entries in the input_dir create the
            % output_dir
            if (length(dir(current_input_path)) > 2)
                mkdir(current_output_path);
            end
        end
    end
    
    current_method_string = method_string;
    
    % check whther the file has not been copied already
    if ~ismember(current_input_file_FQN, processed_files_in_current_session_dir) && ~isdir(current_input_file_FQN)
        
        % if the eve does not have the session identifier in the
        % name the file might have been used from multiple
        % experiments in that case never move, but copy to all
        % sessionIDs that have triallog files in the current
        % directory
        if isempty(strfind(current_input_name_ext, current_session_id))
            if ismember(current_method_string, {'rename', 'move'})
                disp(['Ambiguous file name (missing session identifier in filename), will not be moved but copied: ', current_input_name_ext]);
                current_method_string = 'copy';
            end
        end
        
        
        % do not modify the eve file names as they are referenced
        % from inside the triallog file
        output_file_FQN = fullfile(current_output_path, current_input_name_ext);
        status = fnTransformInputFileToOutputFileByMethod(current_input_file_FQN, output_file_FQN, current_method_string);
        if (status)
            current_processed_in_file_list{end+1} = current_input_file_FQN;
        end
    end
end

return
end


function [tracker_info] = fnParseEventideTracklogName( trackerlog_file_name )
% event ide tracker log file names are constructed like:
%TrackerLog--EyeLinkProxyTrackerA--2018-02-01--08-52.txt.gz
% new non eventIDe style since 2018
%20180124T072414.A_None.B_Elmo.SCP_01.TID_SecondaryPQLabTrackerB.trackerlog.txt.gz

% with TRACKERMARKER--TrackerID--Year-Month-day--Hour-Minute.suffix
% Note that Hour-Minute seems to be the rounded version of the start time
% wall clock that becomes part of the sessionID

% fill: trackerID/TID, sessionID, date, time, suffixes
tracker_info.filename = trackerlog_file_name;
[~, ~, tracker_info.fileextension] = fileparts(trackerlog_file_name);
tracker_info.ext_is_gz = strcmp(tracker_info.fileextension, '.gz');


if (regexp(trackerlog_file_name, '^TrackerLog--'))
    % canonical eventIDE auto generated names
    % e.g. TrackerLog--EyeLinkProxyTrackerA--2018-02-01--08-52.txt.gz
    eventIDEInfoSeparatorString = '--';
    InfoSeparatorIdx = strfind(trackerlog_file_name, eventIDEInfoSeparatorString);
    if length(InfoSeparatorIdx) ~= 3
        error(['The following trackerlog not recognized as proper eventIDE tracker name: ', trackerlog_file_name]);
    else
        tracker_info.sessionID = [];
        tracker_info.trackerID = trackerlog_file_name(InfoSeparatorIdx(1)+length(eventIDEInfoSeparatorString): InfoSeparatorIdx(2)-1);
        % eventide reports date as YYYY--DD--MM, so undo this
        tmp_yyyyddmm_string = trackerlog_file_name(InfoSeparatorIdx(2)+length(eventIDEInfoSeparatorString): InfoSeparatorIdx(3)-1);
        tmp_yyyyddmm_string(strfind(tmp_yyyyddmm_string, '-')) = [];
        tracker_info.yyyymmdd_string = [tmp_yyyyddmm_string(1:4), tmp_yyyyddmm_string(7:8), tmp_yyyyddmm_string(5:6)];
        %tracker_info.yyyymmdd_string = trackerlog_file_name(InfoSeparatorIdx(2)+length(eventIDEInfoSeparatorString): InfoSeparatorIdx(3)-1);
        %tracker_info.yyyymmdd_string(strfind(tracker_info.yyyymmdd_string, '-')) = [];
        
        dotIdx = strfind(trackerlog_file_name, '.');
        tracker_info.hhmmss_string = [trackerlog_file_name(InfoSeparatorIdx(3)+length(eventIDEInfoSeparatorString): dotIdx-1), '-00'];
        tracker_info.hhmmss_string(strfind(tracker_info.hhmmss_string, '-')) = [];
        tmp = tracker_info.hhmmss_string;
        tracker_info.time_ms = 1000 * ((str2double(tmp(1:2)) * 60 * 60) + (str2double(tmp(3:4)) * 60) + (str2double(tmp(5:6))));
        tracker_info.session_time_string = [tracker_info.yyyymmdd_string, 'T', tracker_info.hhmmss_string];
    end
    
    
elseif (regexp(trackerlog_file_name, '.trackerlog.txt'))
    % local style,
    % e.g.: 20180124T072414.A_None.B_Elmo.SCP_01.TID_EyeLinkProxyTrackerA.trackerlog.txt
    TID_idx = strfind(trackerlog_file_name, '.TID');
    extension_idx = strfind(trackerlog_file_name, '.trackerlog.txt');
    
    tracker_info.sessionID = trackerlog_file_name(1:TID_idx(1)-1);
    tracker_info.trackerID = trackerlog_file_name(TID_idx+length('.TID')+1: extension_idx-1);
    tracker_info.yyyymmdd_string = trackerlog_file_name(1:8);
    tracker_info.hhmmss_string = trackerlog_file_name(10:15);
    tmp = tracker_info.hhmmss_string;
    tracker_info.time_ms = 1000 * ((str2double(tmp(1:2)) * 60 * 60) + (str2double(tmp(3:4)) * 60) + (str2double(tmp(5:6))));
    tracker_info.session_time_string = trackerlog_file_name(1:15);
else
    disp(['Trackerlogfile name (', trackerlog_file_name, ') not recognized by parser, please implement.']);
    return
end

return
end


% function [ AssignedWinDriveLettersList ] = fnGetWindowsDriveLetterList()     
%     [system_status, AssignedWinDriveLetters] = system('wmic logicaldisk get caption');
%         % this might need checking for sanity
%         colon_idx = strfind(AssignedWinDriveLetters, ':');
%         AssignedWinDriveLettersList = cell(size(colon_idx));
%         for i_colon = 1 : length(colon_idx)
%             AssignedWinDriveLettersList{i_colon} = AssignedWinDriveLetters(colon_idx(i_colon)-1);
%         end
% return 
% end

% function [ SubstitutedDriveLetter ] = fnSubstDrivePathToNextFreeDriveLetter(input_file_FQN, subst_finalpathcomponent_string, mode_string)
% SubstitutedDriveLetter = [];
% if (ispc)    
%     if ~exist('mode_string', 'var') || isempty(mode_string)
%         mode_string = '';
%     end
%     
%     if ~isempty(subst_finalpathcomponent_string)
%         subst_anchor_idx = strfind(input_file_FQN, subst_finalpathcomponent_string);
%         subst_anchor_string = input_file_FQN(1:(subst_anchor_idx(1) + length(subst_finalpathcomponent_string) - 1));
%     else
%         if isdir(input_file_FQN)
%             subst_anchor_string = input_file_FQN;
%         end
%     end
%     
%     PossibleDiveLetterList = {  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',...
%                                 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'};
%       
%     for i_ProtoSubstitutedDriveLetter = 1 : length(PossibleDiveLetterList)
%         current_SubstitutedDriveLetter = [PossibleDiveLetterList{i_ProtoSubstitutedDriveLetter}, ':'];
%         [subst_status, subst_output] = system(['subst ', current_SubstitutedDriveLetter, ' ', subst_anchor_string]);
%         if (subst_status == 0)
%             % we found our candidate
%             SubstitutedDriveLetter = current_SubstitutedDriveLetter;
%             if (strcmp(mode_string, 'delete'))
%                 [subst_status, subst_output] = system(['subst ', current_SubstitutedDriveLetter, ' /d']);
%             end
%             break
%         end       
%     end
% end
% 
%     return
% end


function [ session_start_time_HHMMSS_string ] = fnExtractEventIDEStartTimeFromReport( in_path, name_dir_wildcard, time_key_regexp, n_lines)
% This uses detailled intimate knowledge about event ide tril log files it
% is in no way generic, use carefully

if ~exist('time_key_regexp', 'var') || isempty(time_key_regexp)
    % unless otherwise requested only load the first 64 lines
    time_key_regexp = '^Time:';
end

if ~exist('n_lines', 'var') || isempty(n_lines)
    % unless otherwise requested only load the first 64 lines
    n_lines = 32;
end

session_start_time_HHMMSS_string = [];
% try to find the file to search:
tmp_dir_struct = dir(fullfile(in_path, name_dir_wildcard));
if isempty(tmp_dir_struct)
    % file not found, do nothing...
    return
end

% textscan!
log_fid = fopen(fullfile(in_path, tmp_dir_struct.name), 'r');
tmp_data_list = textscan(log_fid, '%s', n_lines, 'Delimiter',{'\n','\b'});
fclose(log_fid);
tmp_data_list = tmp_data_list{1};

for i_line = 1 : n_lines
    current_line = tmp_data_list{i_line};
    time_key_idx  = regexp(current_line, time_key_regexp);
    if ~isempty(time_key_idx)
        TimeString = strtrim(current_line((time_key_idx+length(time_key_regexp)-1):end));
        % 'Time:  3:25 PM' -> '3:25 PM'
        if strcmp(TimeString(end), 'M')
            colon_idx = strfind(TimeString, ':');
            hours = str2num(TimeString(1:colon_idx-1));
            if strcmp(TimeString(end-1:end), 'PM') && ~strcmp(TimeString(1:2), '12')
                hours = hours + 12;
            end
            minutes = str2num(TimeString(colon_idx+1:colon_idx+3));   
            session_start_time_HHMMSS_string = [num2str(hours, '%02d'), num2str(minutes, '%02d'), '00'];
        elseif (~isempty(regexp(TimeString, '[0-9]*:[0-9][0-9]$')))
            TimeString(strfind(TimeString, ':')) = [];
            session_start_time_HHMMSS_string = [TimeString, '00'];
        else
            error('Not sure what to do the time string does not seem to be well formed...');
        end
        break
    end
end

    
return
end