function [ output_args ] = fnRecursivelyGzipFilesByWildcard( search_root, dir_wildcard_string, regexp_match_string )
%FNRECURSIVELYGZIPFILESBYWILDCARD Summary of this function goes here
%   Detailed explanation goes here

timestamps.(mfilename).start = tic;
disp(['Starting: ', mfilename]);
dbstop if error
fq_mfilename = mfilename('fullpath');
mfilepath = fileparts(fq_mfilename);

if ~exist('dir_wildcard_string', 'var') || isempty(dir_wildcard_string)
    dir_wildcard_string = '*';
end

if ~exist('regexp_match_string', 'var') || isempty(regexp_match_string)
    regexp_match_string = '.trackerlog.txt$';
end

% get the code and data base directories
override_directive = 'local_code';
override_directive = 'local';
SCP_dirs = GetDirectoriesByHostName(override_directive);
if ~exist('search_root', 'var') || isempty(search_root)
    search_root = fullfile(SCP_dirs.SCP_DATA_BaseDir, 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS');
end
 

method_string = 'gzip_move_optimistic'; % 'gzip_move', 'ignore', 'gzip_move_optimistic'


% find all files in the tree based on searc_root that match the dir_wildcard_string
proto_file_list = find_all_files(search_root, dir_wildcard_string, 0);

% then gzip all files that match regexp_match_string
for i_file = 1 : length(proto_file_list)
    current_file_FQN = proto_file_list{i_file};
    [current_file_path, current_file_name, current_file_ext] = fileparts(current_file_FQN);
    current_file_name_ext = [current_file_name, current_file_ext];
    
    % ignore . and .. dir results
    if ismember(current_file_name_ext, {'.', '..'})
        continue
    end
    
    if isdir(current_file_FQN)
        continue
    end
    
    if ~isempty(regexp(current_file_name_ext, regexp_match_string))
        [status] = fnTransformInputFileToOutputFileByMethod(current_file_FQN, current_file_FQN, method_string);
    end    
end

timestamps.(mfilename).end = toc(timestamps.(mfilename).start);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end), ' seconds.']);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end / 60), ' minutes. Done...']);


end

