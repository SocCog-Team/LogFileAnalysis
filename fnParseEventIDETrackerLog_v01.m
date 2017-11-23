function [ data_struct ] = fnParseEventIDETrackerLog_v01( TrackerLog_FQN, column_separator, force_number_of_columns )
%PARSE_PQLABTRACKER Summary of this function goes here
% Parse EventIDE tracker element style report files:
%   TrackerLog_FQN: the fully qualified name of the tracker log
%   column_separator: which charater to use to split lines into columns,
%       default to : if missing or empty
%   force_number_of_columns: force a specific number of columns, ignore if missing or empty

%   Try to read in eventIDE TrackerLog files for PQLabs touch panel
%   elements. This will try to also intrapolate. the timestamps per sample
%   and calculate the centroid positions?
% hard code data types according to standard eventIDE columns
% Measure the speed and compare with construction the format specifier list
% from the header line and then use textscan to read the whole thing into
% cell arrays, maybe merge these using the NIY add_column in
% fn_handle_data_struct.m
%
%TODO: 
%   Test and remove the old add_row and add_row_to_global_struct code, as
%   textscan is much faster...
%       -> make code more readable
%   After parsing try to convert User_Field_NN_idx columns into numeric
%   columns if they appear numeric, also delete completely empty columns
%   with User_Field_NN_idx headers
%
% DONE: 
%   implement and benchmark a textscan based method with after parsing
%	transfer into a data_struct (will require to implement add_column)
%   Multi-column UserFileds in EventIDE will result in a single ;; instance
%   before the user field is written to (the tracker starts before time 0)
%       Fix this by adding the missing separators to get to the correct
%       coumn number


global data_struct;

timestamps.(mfilename).start = tic;
disp(['Starting: ', mfilename]);
dbstop if error
fq_mfilename = mfilename('fullpath');
mfilepath = fileparts(fq_mfilename);


version_string = '.v002';	% we append this to the filename to figure out whether a report file should be re-parsed... this needs to be updated whenthe parser changes

% as long as the UserFields proxy variable of a tracker element is not written it is empty,
% hence in the log it appears as ";;" at the position of the UserField
% column, even if the UserField header contains multiple multiplexed column
% names. to fix this up find all lines with too few columns and add the
% missing ones

fixup_userfield_columns = 2;
delete_fixed_trackerlog = 0;    %TODO instead clone a header into the fixed data file, zip the original under a new name and save the fixed as the "normal" tracker log file
expand_GLM_coefficients = 1;   
suffix_string = '';
test_timing = 1;
add_method = 'add_row_to_global_struct';		% add_row (really slow, just use for gold truth control), add_row_to_global_struct, textscan
add_method = 'textscan';    % hopefully the future
OutOfBoundsValue = NaN; 
pre_allocate_data = 1;
batch_grow_data_array = 1;	% should be default

if (test_timing)
    suffix_string = [suffix_string, '.', add_method];
end

info.logfile_FQN = [];
info.session_date_string = [];
info.session_date_vec = [];
info.experiment_eve = [];
info.tracker_name = [];
info.parsing_date_vec = datevec(datetime('now'));
[sys_status, host_name] = system('hostname');
info.hostname = strtrim(host_name);


data_struct.header = {};
data_struct.data = [];

current_line_number = 0; % to get the data offset from the top

%%% header part of the PQTrackerLog
% Date and time: 2017.02.03 11:13
% Experiment: 0014_DAGDFGR.v014.11.20170302.01
% Tracker: PQLabTrackerA
% EventIDE TimeStamp;Gaze X;Gaze Y;Tracker Time Stamp;Touch Event Type;Touch Source ID;Raw position X;Raw position Y;Touch blob width;Touch blob height;Paradigm;TrialNum;DebugInfo;


if (~exist('TrackerLog_FQN', 'var'))
    [TrackerLog_Name, TrackerLog_Dir] = uigetfile('TrackerLog--*.txt', 'Select the tracker log file');
    TrackerLog_FQN = fullfile(TrackerLog_Dir, TrackerLog_Name);
    save_matfile = 1;
else
    [TrackerLog_Dir, TrackerLog_Name] = fileparts(TrackerLog_FQN);
    save_matfile = 0;
end

if (test_timing)
    save_matfile = 1;
end


disp(TrackerLog_FQN);
TmpTrackerLog_FQN = [TrackerLog_FQN, '.Fixed.txt'];


tmp_dir_TrackerLog_FQN = dir(TrackerLog_FQN);
TrackerLog_size_bytes  = tmp_dir_TrackerLog_FQN.bytes;


% default to semi-colon to separate the LogHeader and data lines
if (~exist('column_separator', 'var')) || isempty(column_separator)
    column_separator = ';';
end

if ~ exist('force_number_of_columns', 'var')
    force_number_of_columns = [];
end

% open the file
TrackerLog_fd = fopen(TrackerLog_FQN, 'r');
if (TrackerLog_fd == -1)
    error(['Could not open ', num2str(TrackerLog_fd), ' none selected?']);
end
info.logfile_FQN = TrackerLog_FQN;
[sys_status, host_name] = system('hostname');
info.hostname = strtrim(host_name);

% parse the informative header part
info_header_parsed = 0;
while (~info_header_parsed)
    current_line = fgetl(TrackerLog_fd);
    current_line_number = current_line_number + 1;
    [token, remain] = strtok(current_line, ':');
    found_header_line = 0;
    switch token
        case 'Date and time'
            DateVector = datevec(strtrim(remain(2:end)), 'yyyy.dd.mm HH:MM');
            info.session_date_string = strtrim(remain(2:end)); %TODO: maybe clean up/ reconstitute from datevec?
            info.session_date_vec = DateVector;
            found_header_line = 1;
        case 'Experiment'
            info.experiment_eve = [strtrim(remain(2:end)), '.eve'];
            found_header_line = 1;
        case 'Tracker'
            info.tracker_name = strtrim(remain(2:end));
            found_header_line = 1;
    end
    
    if (~found_header_line)
        info_header_parsed = 1;
    end
end

% parse the LogHeader line (if it exists), we already have the current_line
% NOTE we assume the string 'EventIDE TimeStamp' to be part of the LogHeader bot not
% the data lines
if ~isempty(strfind(current_line, 'EventIDE TimeStamp'))
    [header, LogHeader_list, column_type_list, column_type_string] = process_LogHeader(current_line, column_separator, force_number_of_columns, 1);
    info.LogHeader = LogHeader_list;
    
    % for fast parsing we want not expand the GLM Coefficients just yet for
    % the column_type_string
    [tmp_fast.header, tmp_fast.LogHeader_list, tmp_fast.column_type_list, tmp_fast.column_type_string] = process_LogHeader(current_line, column_separator, force_number_of_columns, 0);
    
    % create the data structure
    data_struct = fn_handle_data_struct('create', header);
    data_struct.out_of_bounds_marker = OutOfBoundsValue;
    
    data_start_offset = ftell(TrackerLog_fd);
    current_line = fgetl(TrackerLog_fd); % we need this for the next section where we want to start with a loaded log line
    current_line_number = current_line_number + 1;
end
data_start_line = current_line_number;

% str2double and str2num expect "." as decimal separator and "," as thousands
% separator, but eventIDE will take the decimal sparator from windows, so
% might use "," instead of "." for german language settings;
% here we try a heuristic to detect and fix that.
n_cols = length(strfind(current_line, column_separator));
n_commata = length(strfind(current_line, ','));

if abs((n_commata - n_cols)/(n_cols)) <= 0.2
    replace_coma_by_dot = 1;
    disp(['It seems this log file uses commata as decimal separators, replace by dots...']);
else
    replace_coma_by_dot = 0;
end

info.replace_coma_by_dot = replace_coma_by_dot;


% try to make all intermediary fix ups into a temporary file without a
% header
if (fixup_userfield_columns == 2) && (exist(TmpTrackerLog_FQN, 'file') ~= 2)
    disp('Checking each line for the correct number of columns; in case of missing columns add empty columns (might take a while...)');
    FixedTrackerLog_fd = fopen(TmpTrackerLog_FQN, 'w');
    
    % just skip over the header and start with the first data line
    fseek(TrackerLog_fd, data_start_offset, 'bof');
    
    %TODO copy the header lines verbatim but note the number of lines and
    %use those for skipping in textscan, or rather write out fast.header
    %which will have column names for the additional forced columns
    
    while (~feof(TrackerLog_fd))
        current_line = fgetl(TrackerLog_fd);
        if (fixup_userfield_columns == 2)
            separator_idx = strfind(current_line, column_separator);
            if length(separator_idx) < length(tmp_fast.header)
                % this line is missing columns, most likely at the UserField
                % position
                current_line = strrep(current_line, [column_separator, column_separator], repmat(column_separator, [1 (2 + length(tmp_fast.header) - length(separator_idx))]));
            end
        end
        
        if (replace_coma_by_dot)
            comma_idx = strfind(current_line, ',');
            comma_space_idx = strfind(current_line, ', ');
            current_line(comma_idx) = '.';
            % some data fields use commata as internal separators (clPoint), so
            % make sure these stay commata
            if ~isempty(comma_space_idx)
                current_line(comma_space_idx) = ',';
            end
            % this still does not fully handle clPoint type data: 739,445 (28,94°, 156,739?°)
            % but these should not really exist in a tracker log file..., so
            % just ignore...
            replace_coma_by_dot = 2;
        end
        fprintf(FixedTrackerLog_fd, '%s\r\n', current_line);
    end
    fclose(FixedTrackerLog_fd);
    fclose(TrackerLog_fd);
    TrackerLog_fd = fopen(TmpTrackerLog_FQN, 'r');
    tmpToc = toc(timestamps.(mfilename).start);
    disp(['Trackerlog fix-ups took: ', num2str(tmpToc), ' seconds (', num2str(floor(tmpToc / 60), '%3.0f'),' minutes, ', num2str(tmpToc - (60 * floor(tmpToc / 60))),' seconds)']);
    
    if ismember(add_method, {'add_row_to_global_struct', 'add_row'})
        current_line = fgetl(TrackerLog_fd); % we need this for the next section where we want to start with a loaded log line
  
    end
end

switch add_method
    case {'add_row_to_global_struct', 'add_row'}
        
        % now read and parse each data line in sequence, we already have the first
        % line loaded
        n_lines = 1;
        
        % estimate the number of lines in the TrackerLog
        bytes_per_line = length(current_line);
        estimated_data_lines = (TrackerLog_size_bytes - data_start_offset) / bytes_per_line;
        if (pre_allocate_data)
            data_struct.data = zeros([round(1.2 * estimated_data_lines) size(data_struct.data, 2)]);
            if (test_timing)
                suffix_string = [suffix_string, '.preallocated_data_array'];
            end
        end
        
        if (batch_grow_data_array)
            batch_size = floor(estimated_data_lines/10);
            batch_size = 500000; % needs tweaking, but 100000 should work
            suffix_string = [suffix_string, '.data_grow_batch_size_', num2str(batch_size)];
        else
            batch_size = 1;
        end
        
        
        report_every_n_lines = 1000;
        while (~feof(TrackerLog_fd))
            
            if (fixup_userfield_columns == 1)
                separator_idx = strfind(current_line, column_separator);
                if length(separator_idx) < length(tmp_fast.header)
                    % this line is missing columns, most likely at the UserField
                    % position
                    current_line = strrep(current_line, [column_separator, column_separator], repmat(column_separator, [1 (2 + length(tmp_fast.header) - length(separator_idx))]));
                end
            end
            
            if (replace_coma_by_dot == 1)
                comma_idx = strfind(current_line, ',');
                comma_space_idx = strfind(current_line, ', ');
                current_line(comma_idx) = '.';
                % some data fields use commata as internal separators (clPoint), so
                % make sure these stay commata
                if ~isempty(comma_space_idx)
                    current_line(comma_space_idx) = ',';
                end
                % this still does not fuly handle clPoint type data: 739,445 (28,94°, 156,739?°)
                % but these should not really exist in a tracker log file..., so
                % just ignore...
            end
            
            current_row_data = extract_row_data_from_Log_line(current_line, data_struct.header, column_separator);
            
            switch add_method
                case 'add_row'
                    report_every_n_lines = 100;
                    data_struct = fn_handle_data_struct('add_row', data_struct, current_row_data, batch_size); % do not batch as we copy every byte multiple times
                case 'add_row_to_global_struct'
                    report_every_n_lines = 10000;
                    fn_handle_data_struct('add_row_to_global_struct', current_row_data, batch_size);
            end
            
            % get the next line
            current_line = fgetl(TrackerLog_fd);
            current_line_number = current_line_number + 1;
            n_lines = n_lines + 1;
            % add progress indicator
            if ~(mod(n_lines, report_every_n_lines))
                cur_fpos = ftell(TrackerLog_fd);
                processed_size_pct = 100 * (cur_fpos / (TrackerLog_size_bytes - data_start_offset));
                disp(['Processed ', num2str(n_lines), ' lines of the TrackerLog file (', num2str(processed_size_pct, '%5.2f'),' %).']);
            end
        end
    case 'textscan'        
        if (exist(TmpTrackerLog_FQN, 'file') == 2)
            TrackerLogCell = textscan(TrackerLog_fd, tmp_fast.column_type_string, 'Delimiter', column_separator);
            tmpToc = toc(timestamps.(mfilename).start);
            disp(['Trackerlog textscan took: ', num2str(tmpToc), ' seconds (', num2str(floor(tmpToc / 60), '%3.0f'),' minutes, ', num2str(tmpToc - (60 * floor(tmpToc / 60))),' seconds)']);
            data_struct = fnConvertTextscanOutputToDataStruct(TrackerLogCell, tmp_fast.header, tmp_fast.column_type_list, expand_GLM_coefficients, replace_coma_by_dot, OutOfBoundsValue);
            % now turn this into a proper data_struct
        end
end

% clean up
fclose(TrackerLog_fd);

% delete the temporary fixed up tracker log file?
if (delete_fixed_trackerlog) && (exist(TmpTrackerLog_FQN, 'file') == 2)
    delete(TmpTrackerLog_FQN);
end

data_struct = fn_handle_data_struct('truncate_to_actual_size', data_struct);

% add the additional information structure
data_struct.info = info;

data_struct.info.processing_time_ms = toc(timestamps.(mfilename).start);
if (save_matfile)
    disp(['Saving parsed data as: ', fullfile(TrackerLog_Dir, [TrackerLog_Name, suffix_string, version_string, '.mat'])]);
    save(fullfile(TrackerLog_Dir, [TrackerLog_Name, suffix_string, version_string, '.mat']), 'data_struct');
end

timestamps.(mfilename).end = toc(timestamps.(mfilename).start);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end), ' seconds.']);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end / 60), ' minutes. Done...']);

return
end



function 	[ header, LogHeader_list, column_type_list, column_type_string ] = process_LogHeader( LogHeader_line, column_separator, number_of_data_columns, expand_GLMCoefficientsString)
% LogHeader found, so parse it
% special field names:
% string:	'Current Event', 'Paradigm', 'DebugInfo'

header = {};			% this is the prcessed and expanded header readf for fn_handle_data_struct
LogHeader_list = {};	% just a cell array of the individual columns of the LogHeader string, dissected at column_separator
column_type_list = {};
column_type_string = '';


if ~exist('expand_GLMCoefficientsString', 'var') || isempty(expand_GLMCoefficientsString)
    expand_GLMCoefficientsString = 0;
end


% find the protonumber of columns from the header
Separator_idx = strfind(LogHeader_line, column_separator);
number_orig_header_columns = length(Separator_idx);

% since we expand the GLM Coefficients, account for that in the
% number_of_columns
if isempty(number_of_data_columns)
    number_of_data_columns = number_orig_header_columns;
end


if ~isempty(strfind(LogHeader_line, 'GLM Coefficients')) && (expand_GLMCoefficientsString)
    number_of_data_columns = number_of_data_columns + 3;% the GLM expansion results in three more columns
    number_orig_header_columns = number_orig_header_columns + 3;
end



LogHeader_parsed = 0;
raw_LogHeader = LogHeader_line;
while (~LogHeader_parsed)
    [current_raw_column_name, raw_LogHeader] = strtok(raw_LogHeader, column_separator); % strtok will ignore leading column_separator
    LogHeader_list{end+1} = current_raw_column_name;
    current_raw_column_name = strtrim(current_raw_column_name);% ignore leading and trailing white space
    % some column names are special
    switch current_raw_column_name
        % put all named string columns here
        case {'Current Event', 'Paradigm', 'DebugInfo'}
            current_raw_column_name = sanitize_col_name_for_matlab(current_raw_column_name);
            current_raw_column_name = [current_raw_column_name, '_idx'];
            header{end+1} = current_raw_column_name;
            column_type_list{end + 1} = 'string';
            column_type_string = [column_type_string, '%s'];
        case {'GLM Coefficients'}
            if (expand_GLMCoefficientsString)
                % complex:	'GLM Coefficients' (GainX=1 OffsetX=0 GainY=1 OffsetY=0)
                header{end+1} = 'GLM_Coefficients_GainX';
                header{end+1} = 'GLM_Coefficients_OffsetX';
                header{end+1} = 'GLM_Coefficients_GainY';
                header{end+1} = 'GLM_Coefficients_OffsetY';
                column_type_list{end + 1} = 'double';
                column_type_list{end + 1} = 'double';
                column_type_list{end + 1} = 'double';
                column_type_list{end + 1} = 'double';
                column_type_string = [column_type_string, '%f%f%f%f'];
            else
                current_raw_column_name = sanitize_col_name_for_matlab(current_raw_column_name);
                current_raw_column_name = [current_raw_column_name, '_idx'];
                header{end+1} = current_raw_column_name;
                column_type_list{end + 1} = 'string';
                column_type_string = [column_type_string, '%s'];
            end
        case {'User Field'}
            % naively assume all extra columns are multiplexed into the
            % user field column
            for i_userfield_columns = 1 : (number_of_data_columns - number_orig_header_columns) + 1
                header{end+1} = ['User_Field_', num2str(i_userfield_columns, '%02d'), '_idx'];
                column_type_list{end + 1} = 'string';
                column_type_string = [column_type_string, '%s'];
            end
        otherwise
            % default to floating point numbers...
            current_raw_column_name = sanitize_col_name_for_matlab(current_raw_column_name);
            header{end+1} = current_raw_column_name;
            column_type_list{end + 1} = 'double';   % matlab default
            column_type_string = [column_type_string, '%f'];
    end
    if isempty(raw_LogHeader) || (length(raw_LogHeader) ==  length(column_separator)) || strcmp(raw_LogHeader, column_separator)
        LogHeader_parsed = 1;
    end
    
    
    % in case the UserField has been renamed just add the empty column
    % names at the end
    if (LogHeader_parsed) && (number_of_data_columns > length(header))
        for i_missing_columns = 1 : (number_of_data_columns - length(header))
            header{end+1} = ['anonymous_column_', num2str(i_userfield_columns, '%02d'), 'idx'];
            column_type_list{end + 1} = 'string';
            column_type_string = [column_type_string, '%s'];
        end
    end
    
    %disp(current_raw_column_name);
end

return
end


function [ row_data ] = extract_row_data_from_Log_line(log_line, column_name_list, column_separator)
% process the raw line from the TrackerLog and transform into a form
% fn_handle_data_struct will accept as row_data (either a numeric vector or a cell array of numeric vectors and singleton string cells)

row_data = cell([1 1]);

log_line_remain = log_line;


log_line_parsed = 0;
column_idx = 0;
while ~(log_line_parsed)
    [current_column_data, log_line_remain] = strtok(log_line_remain, column_separator);
    column_idx = column_idx + 1;
    cur_col_name = column_name_list{column_idx};
    
    column_is_GLM = 0;
    if (length(cur_col_name) >= 17) && (strcmp(cur_col_name(1:17), 'GLM_Coefficients_'))
        % we need to parse all four sub-elements
        column_is_GLM = 1;
        GLM_keywords = current_column_data;
        GLM_values = zeros([1 4]);
        for i_glm = 1 : 4
            [GLM_keyvaluepair, GLM_keywords] = strtok(GLM_keywords, ' ');
            [GLM_key, GLM_value] = strtok(GLM_keyvaluepair, '=');
            GLM_values(i_glm) = str2double(GLM_value(2:end));   % exclude the leading separator
        end
        column_idx = column_idx + 3;
        if isempty(row_data{end})
            row_data{end} = GLM_values;
        else
            row_data{end + 1} = GLM_values;
        end
    end
    
    column_is_string = 0;
    if strcmp(cur_col_name(end-3:end), '_idx')
        column_is_string = 1;
        if isempty(row_data{end})
            row_data{end} = current_column_data;
        else
            row_data{end + 1} = current_column_data;
        end
    end
    
    % catch UserFields containing string data
    if ~(column_is_GLM) && ~(column_is_string) && isnan(str2double(current_column_data))
        column_is_string = 1;
        error('Found string type data in non handled column type (', cur_col_name, '); true string column names end with _idx.');
        if isempty(row_data{end})
            row_data{end} = current_column_data;
        else
            row_data{end + 1} = current_column_data;
        end
    end
    
    
    if (~column_is_GLM && ~column_is_string)
        % simple numeric data, append if poosible
        if isempty(row_data{end})
            row_data{end} = str2double(current_column_data);
        else
            % if the previous data is numeric append to last/current cell
            % instead of appending a new cell
            if isnumeric(row_data{end})
                row_data{end}(end+1) = str2double(current_column_data);
            else
                row_data{end + 1} = str2double(current_column_data);
            end
        end
    end
    
    
    if isempty(log_line_remain) || (length(log_line_remain) ==  length(column_separator)) || strcmp(log_line_remain, column_separator)
        log_line_parsed = 1;
    end
end

return
end

function [ sanitized_column_name ]  = sanitize_col_name_for_matlab( raw_column_name )
% some characters are not really helpful inside matlab variable names, so
% replace them with something that should not cause problems
taboo_char_list =		{' ', '-', '.', '='};
replacement_char_list = {'_', '_', '_dot_', '_eq_'};

sanitized_column_name = raw_column_name;

for i_taboo_char = 1: length(taboo_char_list)
    current_taboo_string = taboo_char_list{i_taboo_char};
    current_replacement_string = replacement_char_list{i_taboo_char};
    current_taboo_processed = 0;
    remain = sanitized_column_name;
    tmp_string = '';
    while (~current_taboo_processed)
        [token, remain] = strtok(remain, current_taboo_string);
        tmp_string = [tmp_string, token, current_replacement_string];
        if isempty(remain)
            current_taboo_processed = 1;
            % we add one superfluous replaceent string at the end, so
            % remove that
            tmp_string = tmp_string(1:end-length(current_replacement_string));
        end
    end
    sanitized_column_name = tmp_string;
end

return
end

function [ out_data_struct, TextscanOutputCellArray, cell_header, cell_type_list] = fnConvertTextscanOutputToDataStruct( TextscanOutputCellArray, cell_header, cell_type_list, expand_GLM_coefficients, replace_coma_by_dot, OutOfBoundsValue )
% convert the TrackerLogCell into a data_struct, by saddiing column by
% column

if ~exist('OutOfBoundsValue', 'var')
    OutOfBoundsValue = NaN; % default to NaN, even though it can be quite slow...
end


out_data_struct = struct();
n_columns = size(TextscanOutputCellArray, 2);
if (n_columns ~= length(cell_header))
    disp('Textscan returned a different number of columns than expected from the header parsing, skipping...');
    return
end

% need to subparse the GLM Coefficients data record?
if (expand_GLM_coefficients)
    GLM_CoefficientsColumnIdx = find(strcmp(cell_header, 'GLM_Coefficients_idx'));
    
    if ~isempty(GLM_CoefficientsColumnIdx)
        %TmpGLMCoefficientsUnparsedStringCell = TextscanOutputCellArray{GLM_CoefficientsColumnIdx};
        TmpGLMCoefficientsUnparsedStringCharArray = char(TextscanOutputCellArray{GLM_CoefficientsColumnIdx});
        if (replace_coma_by_dot)
            TmpGLMCoefficientsUnparsedStringCharArray = strrep(TmpGLMCoefficientsUnparsedStringCharArray, ',', '.');
        end
        TmpGLMCoefficientsCellArray = textscan(TmpGLMCoefficientsUnparsedStringCharArray','GainX=%f OffsetX=%f GainY=%f OffsetY=%f', size(TextscanOutputCellArray{GLM_CoefficientsColumnIdx}, 1));
        
        % now merge the expanded columns into TextscanOutputCellArray,
        % cell_header and cell_type_list
        if (GLM_CoefficientsColumnIdx == 1)
            TmpTextscanOutputCellArray = [TmpGLMCoefficientsCellArray, TextscanOutputCellArray(2:end)];
            tmp_cell_header = ['GLM_Coefficients_GainX', 'GLM_Coefficients_OffsetX', 'GLM_Coefficients_GainY', 'GLM_Coefficients_OffsetY', cell_header(2:end)];
            tmp_cell_type_list = ['double', 'double', 'double', 'double', cell_type_list(2:end)];
        elseif (GLM_CoefficientsColumnIdx == length(cell_header))
            TmpTextscanOutputCellArray = [TextscanOutputCellArray(1:end-1), TmpGLMCoefficientsCellArray];
            tmp_cell_header = [cell_header(1:end-1), 'GLM_Coefficients_GainX', 'GLM_Coefficients_OffsetX', 'GLM_Coefficients_GainY', 'GLM_Coefficients_OffsetY'];
            tmp_cell_type_list = [cell_type_list(1:end-1), 'double', 'double', 'double', 'double'];
        else
            TmpTextscanOutputCellArray = [TextscanOutputCellArray(1:GLM_CoefficientsColumnIdx-1), TmpGLMCoefficientsCellArray, TextscanOutputCellArray(GLM_CoefficientsColumnIdx+1:end)];
            tmp_cell_header = [cell_header(1:GLM_CoefficientsColumnIdx-1), 'GLM_Coefficients_GainX', 'GLM_Coefficients_OffsetX', 'GLM_Coefficients_GainY', 'GLM_Coefficients_OffsetY', cell_header(GLM_CoefficientsColumnIdx+1:end)];
            tmp_cell_type_list = [cell_type_list(1:GLM_CoefficientsColumnIdx-1), 'double', 'double', 'double', 'double', cell_type_list(GLM_CoefficientsColumnIdx+1:end)];        
        end
        TextscanOutputCellArray = TmpTextscanOutputCellArray;
        cell_header = tmp_cell_header;
        cell_type_list = tmp_cell_type_list;
        %clear(TmpTextscanOutputCellArray);
    end
end
n_columns = size(TextscanOutputCellArray, 2);


out_data_struct = fn_handle_data_struct('create', {'REMOVEME'});
out_data_struct.out_of_bounds_marker = OutOfBoundsValue;

% now add the columns one by one
for i_column = 1 : n_columns
    CurrentColumnData = TextscanOutputCellArray{i_column};
    if ~isnan(OutOfBoundsValue)
        NaN_idx = isnan(CurrentColumnData);
        CurrentColumnData(NaN_idx) = OutOfBoundsValue;
    end
    CurrentColumnName = cell_header{i_column};
    CurrentColumnType = cell_type_list{i_column};
    out_data_struct = fn_handle_data_struct('add_columns', out_data_struct, CurrentColumnData, {CurrentColumnName});
end

% we started with a dummy column so reove this before continuing
out_data_struct = fn_handle_data_struct('remove_columns', out_data_struct, {'REMOVEME'});

return
end