function [ data_struct, version_string ] = fnParseEventIDETrackerLog_v01( TrackerLog_FQN, column_separator, force_number_of_columns, forced_header_string)
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
%   Gzip the TrackerLog_FQN after parsing to save space...
%
%TODO:
%   Test and remove the old add_row and add_row_to_global_struct code, as
%   textscan is much faster...
%       -> make code more readable
%   After parsing try to convert User_Field_NN_idx columns into numeric
%   columns if they appear numeric, also delete completely empty columns
%   with User_Field_NN_idx headers
%	Add generation of "corrected" sample timestamps in eventide time (needs 
%		to be handled separatly for each tracker type)
%		The idea is to use the tracker supplied timestamps as better
%		estimates for the real data acquisition time points
%		The general approach is to assign an earlieast (e_EventIDE_ts) and a latest
%		eventide timestamps (l_EventIDE_ts) and the according tracker timestamps e_Tracker_ts l_Tracker_ts, then
%		calculate a corrected eventide timestamp by simply doing:
%		cor_EventIDE_ts = cur_Tracker_ts * (l_EventIDE_ts-e_EventIDE_ts)/(l_Tracker_ts-e_Tracker_ts) + e_EventIDE_ts
%		the challenge now is getting the according l_*_ts and e_8_ts pairs
%		between both series...
%		(and this relies on trustworthy tracker time stamps so will not work for PQLabs at all)
%
% DONE:
%   implement and benchmark a textscan based method with after parsing
%	transfer into a data_struct (will require to implement add_column)
%   Multi-column UserFileds in EventIDE will result in a single ;; instance
%   before the user field is written to (the tracker starts before time 0)
%       Fix this by adding the missing separators to get to the correct
%       coumn number
%   allow to pass a header string to allow easy expansion of Userfield
%   multiplexed columns, this will partially override force_number_of_columns
%   handle gzipped trackerlogfiles by automatically use gunzip to extract
%   them, also optinally conserve the extracted trackerlog.txt version.


global data_struct;

timestamps.(mfilename).start = tic;
disp(['Starting: ', mfilename]);
dbstop if error
fq_mfilename = mfilename('fullpath');
mfilepath = fileparts(fq_mfilename);


version_string = '.v008';	% we append this to the filename to figure out whether a report file should be re-parsed... this needs to be updated whenthe parser changes

% in case 2 output arguments were given only return the version string
if (nargout == 2)
	return
end


% as long as the UserFields proxy variable of a tracker element is not written it is empty,
% hence in the log it appears as ";;" at the position of the UserField
% column, even if the UserField header contains multiple multiplexed column
% names. to fix this up find all lines with too few columns and add the
% missing ones

delete_txt_versions_of_gzip = 1; % delete the extracted txt file versions of gzipped ones to save space
replace_decimal_coma_by_dot = 1;
trackername_start_string = '.TID_';
trackername_stop_string = '.trackerlog';


fixup_userfield_columns = 2;
delete_fixed_trackerlog = 1;    %TODO instead clone a header into the fixed data file, zip the original under a new name and save the fixed as the "normal" tracker log file
expand_GLM_coefficients = 1;
suffix_string = '';
test_timing = 0;
%add_method = 'add_row_to_global_struct';		% add_row (really slow, just use for gold truth control), add_row_to_global_struct, textscan
add_method = 'textscan';    % hopefully the future
OutOfBoundsValue = NaN;
pre_allocate_data = 1;
batch_grow_data_array = 1;	% should be default

add_corrected_tracker_timestamps = 1;


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
	[TrackerLog_Name, TrackerLog_Dir] = uigetfile({'*trackerlog.txt';'*signallog.txt';'*trackerlog.txt.gz';'*signallog.txt.gz'}, 'Select the tracker log file');
	TrackerLog_FQN = fullfile(TrackerLog_Dir, TrackerLog_Name);
	save_matfile = 1;
else
	[TrackerLog_Dir, TrackerLog_Name, TrackerLog_Ext] = fileparts(TrackerLog_FQN);
	save_matfile = 1;
end

if (test_timing)
	save_matfile = 1;
end


[TrackerLog_path, TrackerLog_name, TrackerLog_ext] = fileparts(TrackerLog_FQN);
if strcmp(TrackerLog_ext, '.mat')
	% this seems to be an existing parsed trackerlog so just read it in if
	% it is current
	data_struct = load(TrackerLog_FQN);
	if ~isempty(regexp(TrackerLog_name, version_string))
		disp(['Requested TrackerLog/Signallog is a .mat file of the most recent version, just loading it...']);
	else
		display(['WARNING: the requested TrackerLog/Signallog (', TrackerLog_name, ') is not of the current version, still loading it...']);
	end
	return
end


return_most_processed = 0;

% check if the requested files exists at all
TrackerLog_FQN_dirstruct = dir(TrackerLog_FQN);
if (isempty(TrackerLog_FQN_dirstruct))
	disp(['File not found: ', TrackerLog_FQN]);
	if ~isempty(regexp(TrackerLog_FQN, 'trackerlog$')) || ~isempty(regexp(TrackerLog_FQN, 'signallog$'))
		% the user requested a *.trackerlog, which means use the most
		% processed version available
		return_most_processed = 1;
	else
		return
	end
end


if (return_most_processed)
	% try to load the existing mat file, if current.
	tmp = dir(fullfile(TrackerLog_Dir, [TrackerLog_Name, TrackerLog_Ext, version_string, '.mat']));
	if ~isempty(tmp)
		disp(['Found current mat version of the trackerlog, loading: ', fullfile(TrackerLog_Dir, [TrackerLog_Name, TrackerLog_Ext, version_string, '.mat'])]);
		load(fullfile(TrackerLog_Dir, [TrackerLog_Name, TrackerLog_Ext, version_string, '.mat']))
		return
	end
	% for the time being fall back to full processing if no mat file was
	% found
	% unpacked file exisys?
	TrackerLog_FQN = [TrackerLog_FQN, '.txt'];
	[TrackerLog_Dir, TrackerLog_Name, TrackerLog_Ext] = fileparts(TrackerLog_FQN);
	if (exist(TrackerLog_FQN, 'file') ~= 2)
		if strcmp(TrackerLog_Ext, '.txt')
			% fall back to the gzipped version
			TrackerLog_FQN = [TrackerLog_FQN, '.gz'];
			[TrackerLog_Dir, TrackerLog_Name, TrackerLog_Ext] = fileparts(TrackerLog_FQN);
		end
	end	
end


% check for gzipped file
logfile_is_gzipped = 0;
[orig_TrackerLog_path, orig_TrackerLog_name, orig_TrackerLog_ext] = fileparts(TrackerLog_FQN);


if strcmp(orig_TrackerLog_ext, '.gz')
	logfile_is_gzipped = 1;
	gzip_TrackerLog_FQN = TrackerLog_FQN;
	TrackerLog_FQN = fullfile(orig_TrackerLog_path, orig_TrackerLog_name);
	[TrackerLog_Dir, TrackerLog_Name] = fileparts(TrackerLog_FQN);
	% only unzip if the unzipped file does not exist yet:
	if (exist(TrackerLog_FQN, 'file') ~= 2)
		% found a gziped file, now uncompress
		disp(['Current trackerlog/signallog file: ', gzip_TrackerLog_FQN]);
		disp(['Gunzipping the compressed trackerlog/signallog file, might take a while...']);
		gunzip(gzip_TrackerLog_FQN);
	else
		disp(['Gzipped log file selected: skipping the unzipping since unzipped version already exists,.']);
		disp(['                           to force unzipping simply delete ', TrackerLog_FQN]);
	end
else
	switch orig_TrackerLog_ext
		case '.txt'
			gzip_TrackerLog_FQN = [TrackerLog_FQN, '.gz'];
		case {'.trackerlog', '.signallog'}
			gzip_TrackerLog_FQN = [TrackerLog_FQN, '.txt.gz'];
	end
end

disp(TrackerLog_FQN);
TmpTrackerLog_FQN = [TrackerLog_FQN, '.Fixed.txt'];

%check for a gzipped version of this file and unzip unless a .txt already
%exists.
gzip_TmpTrackerLog_FQN = [TmpTrackerLog_FQN, '.gz'];
if ~exist(TmpTrackerLog_FQN, 'file')
	if exist(gzip_TmpTrackerLog_FQN, 'file')
		disp(['Gunzipping compressed fixed trackerlog/signallog: ', gzip_TmpTrackerLog_FQN])
		gunzip(gzip_TmpTrackerLog_FQN);
	end
end


tmp_dir_TrackerLog_FQN = dir(TrackerLog_FQN);
TrackerLog_size_bytes  = tmp_dir_TrackerLog_FQN.bytes;

% default to semi-colon to separate the LogHeader and data lines
if (~exist('column_separator', 'var')) || isempty(column_separator)
	column_separator = ';';
end

if ~exist('force_number_of_columns', 'var') || isempty(force_number_of_columns)
	force_number_of_columns = [];
end

if ~exist('forced_header_string', 'var') || isempty(forced_header_string)
	forced_header_string = [];
end

% signallog files are more structured
log_type = 'trackerlog';
if ~isempty(regexp(TrackerLog_Name, 'signallog'))
	log_type = 'signallog';
	trackername_stop_string = '.signallog';
	column_separator = ',';
	replace_decimal_coma_by_dot = 0;
	fixup_userfield_columns = 0;
	%fixup_userfield_columns = 2; % to deal with partially written files where the last line might be incomplete
	%TODO test for the last line being incomplete and only fix incomplete
	%lines.
end
% extract the tracker name from the file name
info.tracker_name = fn_extract_trackername_from_filename(TrackerLog_Name, '.TID_', ['.', log_type]);



% open the file
TrackerLog_fd = fopen(TrackerLog_FQN, 'r');
if (TrackerLog_fd == -1)
	error(['Could not open ', num2str(TrackerLog_fd), ' none selected?']);
end
info.logfile_FQN = TrackerLog_FQN;
[sys_status, host_name] = system('hostname');
info.hostname = strtrim(host_name);

% parse the informative header part
info_header_line_list = {};
info_header_parsed = 0;
while (~info_header_parsed)
	current_line = fgetl(TrackerLog_fd);
	info_header_line_list{end+1} = current_line;
	current_line_number = current_line_number + 1;
	found_header_line = 0;
	switch log_type
		case 'trackerlog'
			[token, remain] = strtok(current_line, ':');
			%found_header_line = 0;
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
					info.tracker_name_from_filename = info.tracker_name;				
					info.tracker_name = strtrim(remain(2:end));
					found_header_line = 1;
			end
		case 'signallog'
			% signal log header look different (line starting with [ are optional):
			%[Title],20200117T114559.A_TestA.B_None.SCP_01
			%[Patient ID],AccelerationSensor_Y, MotitorSpotDetector_LCD_level, TestSignal_5kHz
			%Timestamp,Dev1/ai0,Dev1/ai1,Dev1/ai2,
			[token, remain] = strtok(current_line, ']');
			switch token
				case '[Title'
					info.title = remain(3:end);
					found_header_line = 1;
				case '[Patient ID'
					info.patient_id = remain(3:end);
					found_header_line = 1;
			end	
	end
	if (~found_header_line)
		info_header_parsed = 1;
	end
end

% parse the LogHeader line (if it exists), we already have the current_line
% NOTE we assume the string 'EventIDE TimeStamp' to be part of the LogHeader bot not
% the data lines
if ~isempty(strfind(current_line, 'EventIDE TimeStamp')) || ~isempty(strfind(current_line, 'Timestamp'))
	[header, LogHeader_list, column_type_list, column_type_string, orig_LogHeader_line] = process_LogHeader(current_line, column_separator, force_number_of_columns, forced_header_string, 1);
	info.LogHeader = LogHeader_list;
	
	% for fast parsing we want not expand the GLM Coefficients just yet for
	% the column_type_string
	[tmp_fast.header, tmp_fast.LogHeader_list, tmp_fast.column_type_list, tmp_fast.column_type_string, tmp_fast.orig_LogHeader_line] = process_LogHeader(current_line, column_separator, force_number_of_columns, forced_header_string, 0);
	
	% create the data structure
	data_struct = fn_handle_data_struct('create', header);
	data_struct.out_of_bounds_marker = OutOfBoundsValue;
	
	data_start_offset = ftell(TrackerLog_fd);
	current_line = fgetl(TrackerLog_fd); % we need this for the next section where we want to start with a loaded log line
	current_line_number = current_line_number + 1;
	% if a modified header exists, store it for the fixed file
	if ~isempty(forced_header_string)
		info_header_line_list{end} = forced_header_string;
	end
end
data_start_line = current_line_number;

% str2double and str2num expect "." as decimal separator and "," as thousands
% separator, but eventIDE will take the decimal sparator from windows, so
% might use "," instead of "." for german language settings;
% here we try a heuristic to detect and fix that.
n_cols = length(strfind(current_line, column_separator));
n_commata = length(strfind(current_line, ','));

% signal writer defaults to CSV so disable this heuristic for signallogs
if (abs((n_commata - n_cols)/(n_cols)) <= 0.2) && replace_decimal_coma_by_dot
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
	
	for i_header_line = 1 : length(info_header_line_list)
		fprintf(FixedTrackerLog_fd, '%s\r\n', info_header_line_list{i_header_line});
	end
	
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
				% this line is missing columns, most likely at the UserField position
				UserField_pos_idx = strfind(tmp_fast.orig_LogHeader_line, 'User Field');
				% okay the column is really called user field, that allows
				% us to place the "missing" empty columns at a better place
				% than everywhere
				if ~isempty(UserField_pos_idx)
					LogHeader_line_separator_idx = strfind(tmp_fast.orig_LogHeader_line, column_separator);
					UserField_col_idx = find(LogHeader_line_separator_idx == (UserField_pos_idx - 1)) + 1;
					EmptyUserFieldDAtaReplacement_string = repmat(column_separator, [1 (2 + length(tmp_fast.header) - length(separator_idx))]);
					tmp_current_line_start = current_line(1:separator_idx(UserField_col_idx)-2);
					tmp_current_line_end = current_line(separator_idx(UserField_col_idx)+1:end);
					current_line = [tmp_current_line_start, EmptyUserFieldDAtaReplacement_string, tmp_current_line_end];
				else
					% note that the PupilLabs trackerlogfiles do have real
					% empty data fields which leads to multiple
					% replacements by this code, these errors are real and
					% impossible to fix without additional information
					% the following will replace each ;; with 
					%current_line = strrep(current_line, [column_separator, column_separator], repmat(column_separator, [1 (2 + length(tmp_fast.header) - length(separator_idx))]));
					
					% here we just assume that the UserField was at the last
					% position and just append the missing fields to the
					% end
					n_missing_cols = length(tmp_fast.header) - length(separator_idx);
					current_line = [current_line, repmat(column_separator, [1 n_missing_cols])];				
				end
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

	tmpToc = toc(timestamps.(mfilename).start);
	
	disp(['Trackerlog fix-ups took: ', num2str(tmpToc), ' seconds (', num2str(floor(tmpToc / 60), '%3.0f'),' minutes, ', num2str(tmpToc - (60 * floor(tmpToc / 60))),' seconds)']);
end


if (exist(TmpTrackerLog_FQN, 'file') == 2) && (~(exist(gzip_TmpTrackerLog_FQN, 'file') == 2))
	disp(['Gzipping compressed fixed trackerlog: ', TmpTrackerLog_FQN])
	gzip(TmpTrackerLog_FQN);	
end


% make sure to jump into the fixed trackerlog even if that existed already
if (fixup_userfield_columns == 2) && (exist(TmpTrackerLog_FQN, 'file') == 2)
	fclose(TrackerLog_fd);
	TrackerLog_fd = fopen(TmpTrackerLog_FQN, 'r');
	
% 	% just skip over the header and start with the first data line
% 	fseek(TrackerLog_fd, data_start_offset, 'bof');
% 	if ismember(add_method, {'add_row_to_global_struct', 'add_row'})
% 		current_line = fgetl(TrackerLog_fd); % we need this for the next section where we want to start with a loaded log line
% 	end
end

% just skip over the header and start with the first data line
fseek(TrackerLog_fd, 0, 'eof');
TrackerLog_fd_size = ftell(TrackerLog_fd);
if ((TrackerLog_fd_size - data_start_offset) < 50)
	disp('Data file contains less than 50 data bytes, aborting the parser.');
	data_struct.data = [];
	data_struct.info = info;
	return
end

status = fseek(TrackerLog_fd, data_start_offset, 'bof');
if ismember(add_method, {'add_row_to_global_struct', 'add_row'})
	current_line = fgetl(TrackerLog_fd); % we need this for the next section where we want to start with a loaded log line
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
		if (exist(TmpTrackerLog_FQN, 'file') == 2) || (fixup_userfield_columns == 0)
			% if the following fails chech whether the type assignments in
			% tmp_fast.column_type_list are correct
			TrackerLogCell = textscan(TrackerLog_fd, tmp_fast.column_type_string, 'Delimiter', column_separator, 'HeaderLines', length(info_header_line_list), 'ReturnOnError', 0);
			tmpToc = toc(timestamps.(mfilename).start);
			disp(['Trackerlog textscan took: ', num2str(tmpToc), ' seconds (', num2str(floor(tmpToc / 60), '%3.0f'),' minutes, ', num2str(tmpToc - (60 * floor(tmpToc / 60))),' seconds)']);
			
			%[cells_are_of_equal_length, numel_per_cell_list] = fn_get_numel_per_cell(TrackerLogCell);
			n_cells = length(TrackerLogCell);
			cells_are_of_equal_length = 0;
			numel_per_cell_list = zeros(size(TrackerLogCell));
			
			for i_cell = 1 : n_cells
				numel_per_cell_list(i_cell) = length(TrackerLogCell{i_cell});
			end
			
			if (min(numel_per_cell_list(:) == max(numel_per_cell_list(:))))
				cells_are_of_equal_length = 1;
			end
			
			if ~cells_are_of_equal_length
				if ismember(log_type, {'signallog'})
					% make sure all cells are of equal length
					disp(['Forcing all textscan cells to minimum length of ', num2str(min(numel_per_cell_list(:))), ', (', num2str(n_cells), ' cells, max ', num2str(max(numel_per_cell_list(:))), ').']);

					for i_cell = 1 : n_cells
						if (numel_per_cell_list(i_cell) > min(numel_per_cell_list(:)))
							disp(['Adjusting cell ', num2str(i_cell), ' of ', num2str(n_cells), ' from ', num2str(numel_per_cell_list(i_cell)), ' to ', num2str(min(numel_per_cell_list(:))), '.']);
							TrackerLogCell{i_cell} = TrackerLogCell{i_cell}(1:min(numel_per_cell_list(:)));
						end
					end
				else
					% figure out how to deal with that properly later,
					% could be used to make the fix-up step conditional on
					% naive parsing failing?
					error(['Individual columns are of different length, but the log type is not tolerant to this condition.']);
				end
			end
			% do not try to convert empty log files
			if ~isempty(TrackerLogCell{1})
				data_struct = fnConvertTextscanOutputToDataStruct(TrackerLogCell, tmp_fast.header, tmp_fast.column_type_list, expand_GLM_coefficients, replace_coma_by_dot, OutOfBoundsValue);
				% now turn this into a proper data_struct
			end
		end
end

% clean up
fclose(TrackerLog_fd);




% delete the temporary fixed up tracker log file?
if (delete_fixed_trackerlog) && (exist(TmpTrackerLog_FQN, 'file') == 2) && (exist(gzip_TmpTrackerLog_FQN, 'file') == 2)
	disp(['Deleting: ', TmpTrackerLog_FQN]);
	delete(TmpTrackerLog_FQN);
end

data_struct = fn_handle_data_struct('truncate_to_actual_size', data_struct);

% add the additional information structure
data_struct.info = info;


% EventIDE timestamps basically record when eventIDE got hold of the
% samples, not when they happened, try to use tracker time stamps to
% created corrected eventIDE timestamps
if (add_corrected_tracker_timestamps)
	% we need the tracker type the event ide time stamp and tracker
	% timestamp columns
	
	tracker_timestamp_column = [];
	if isfield(data_struct.cn, 'Tracker_Time_Stamp')
		tracker_timestamp_column = data_struct.cn.Tracker_Time_Stamp;
	elseif isfield(data_struct.cn, 'Tracker_time_stamp')
		tracker_timestamp_column = data_struct.cn.Tracker_time_stamp;
	end
	
	
	tracker_type = '';
	% first deduce the type
	if ~isempty(regexpi(info.tracker_name, 'PupilLabs', 'match'))
		tracker_type = 'pupillabs';
	end
	if ~isempty(regexpi(info.tracker_name, 'EyeLink', 'match'))
		tracker_type = 'eyelink';
	end
	if ~isempty(regexpi(info.tracker_name, 'PQLab', 'match'))
		tracker_type = 'pqlab';
	end
	if ~isempty(regexpi(info.tracker_name, 'NISignalFileWriter', 'match'))
		tracker_type = 'nisignalfilewriter';
	end
	
	
	
	
	% error out for unhandled types
	switch tracker_type
		case {'pupillabs', 'eyelink'}
			% for the eyetrackers with reasonably reliable timestamps we
			% only need eventIDe and tracker times for corrections
			[col_header, col_data] = fn_extract_corrected_eventIDE_timestamps(info.tracker_name, data_struct.data(:, data_struct.cn.EventIDE_TimeStamp), ...
				data_struct.data(:, tracker_timestamp_column), TrackerLog_FQN);
		case 'pqlab'
			% here it gets complicated we need to look at some data columns
			% as well as timing columns
			% to deduce and track on and offsets for each finger... (we really only want/need the centroid/average)
			col_data = [];
		case 'nisignalfilewriter'
			% here the issue is that the spacing og the NI sampling
			% probably is relative precise, but the event ide time stamps
			% are not, so we simply try to spece the error out, by taking
			% first and last timestamps and just interpoate the values
			% inbetween
			tracker_timestamp_column = data_struct.cn.EventIDE_TimeStamp;
			[col_header, col_data] = fn_extract_corrected_eventIDE_timestamps(info.tracker_name, data_struct.data(:, data_struct.cn.EventIDE_TimeStamp), ...
				data_struct.data(:, tracker_timestamp_column), TrackerLog_FQN);
			
		otherwise
			error(['Encountered unhandled tracker type: ', tracker_name, ' please handle gracefully']);
	end
	
	
	if ~isempty(col_data)
		disp('Corrected EventIDE_TimeStamp based on tracker timestamps or sample clock precision.');
		% only add if we were successful
		data_struct = fn_handle_data_struct('add_columns', data_struct, col_data, {col_header});
		% save the original uncorrected Timestamps
		data_struct = fn_handle_data_struct('add_columns', data_struct, data_struct.data(:, data_struct.cn.EventIDE_TimeStamp), {'UncorrectedEventIDE_TimeStamp'});
		% now move the corrected timestamps to the canonical timestamp column
		data_struct.data(:, data_struct.cn.EventIDE_TimeStamp) = data_struct.data(:, data_struct.cn.(col_header));
		% in case we resort we want/need to preserve the original sequence,
		% and EventIDE_TimeStamp is not guaranteed to be strongly monotonic
		% and might contain multiple rows with same timestamp
		data_struct = fn_handle_data_struct('add_columns', data_struct, (1:1:size(data_struct.data, 1))', {'OriginalRowOrder'});
		
		% potentially re-sort
		[sorted_col_data, sort_idx] = sort(col_data);
		if ~isequal(sorted_col_data, col_data)
			disp('Corrected timestamp series is not temporally montonic, re-sorting the full data-table.');
			data_struct.data = data_struct.data(sort_idx, :);
		end
		
	end
end


data_struct.info.processing_time_ms = toc(timestamps.(mfilename).start);
if (save_matfile)
	disp(['Saving parsed data as: ', fullfile(TrackerLog_Dir, [TrackerLog_Name, suffix_string, version_string, '.mat'])]);
	save(fullfile(TrackerLog_Dir, [TrackerLog_Name, suffix_string, version_string, '.mat']), 'data_struct', '-v7.3');
end


% now delete the uncompressed files
if (delete_txt_versions_of_gzip) && (exist(TrackerLog_FQN, 'file') == 2) && (exist(gzip_TrackerLog_FQN, 'file') == 2)
	disp(['Deleting: ', TrackerLog_FQN]);
	delete(TrackerLog_FQN);
end

timestamps.(mfilename).end = toc(timestamps.(mfilename).start);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end), ' seconds.']);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end / 60), ' minutes. Done...']);

return
end



function 	[ header, LogHeader_list, column_type_list, column_type_string, orig_LogHeader_line ] = process_LogHeader( LogHeader_line, column_separator, number_of_data_columns, forced_header_string, expand_GLMCoefficientsString)
% LogHeader found, so parse it
% special field names:
% string:	'Current Event', 'Paradigm', 'DebugInfo'

header = {};			% this is the prcessed and expanded header readf for fn_handle_data_struct
LogHeader_list = {};	% just a cell array of the individual columns of the LogHeader string, dissected at column_separator
column_type_list = {};
column_type_string = '';

orig_LogHeader_line = LogHeader_line;

if ~exist('expand_GLMCoefficientsString', 'var') || isempty(expand_GLMCoefficientsString)
	expand_GLMCoefficientsString = 0;
end

if ~exist('forced_header_string', 'var') || isempty(forced_header_string)
	forced_header_string = [];
else
	LogHeader_line = forced_header_string;
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
		case {'Current Event', 'Paradigm', 'DebugInfo', 'Multitouch mode', 'Sample Type', 'Fiducial Surface', 'Detection Method'} % 'Source ID'
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
		
		% signallog csv calls the Timestamp column Timestamp, unlike what
		% the log designer defaults to for tracker elements, so
		% canonicalize this
		case {'Timestamp'}
			% rename to the canonical "EventIDE TimeStamp"
			current_raw_column_name = sanitize_col_name_for_matlab('EventIDE TimeStamp');
			header{end+1} = current_raw_column_name;
			column_type_list{end + 1} = 'double';   % matlab default
			column_type_string = [column_type_string, '%f'];
	
			
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
taboo_char_list =		{' ', '-', '.', '=', '/'};
replacement_char_list = {'_', '_', '_dot_', '_eq_', '_'};

taboo_first_char_list = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'};
replacement_firts_char_list = {'Zero', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine'};

sanitized_column_name = raw_column_name;
% check first character to not be a number
taboo_first_char_idx = find(ismember(taboo_first_char_list, raw_column_name(1)));
if ~isempty(taboo_first_char_idx)
	sanitized_column_name = [replacement_firts_char_list{taboo_first_char_idx}, raw_column_name(2:end)];
end



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

% we started with a dummy column so reomve this before continuing
out_data_struct = fn_handle_data_struct('remove_columns', out_data_struct, {'REMOVEME'});

return
end

function [ col_header, corrected_EventIDE_TimeStamp_list ] = fn_extract_corrected_eventIDE_timestamps( tracker_name, EventIDE_TimeStamp_list, Tracker_Time_Stamp_list, TrackerLog_FQN )
% EventIDE_TimeStamps only recodr the time eventide imported a sample,
% while Tracker_Time_Stamps (for reliable Trackers) are closer to the real
% time of acquisition, use the traker timestamps to adjust the eventide
% timestamps
debug = 1;

col_header = 'Tracker_corrected_EventIDE_TimeStamp';
corrected_EventIDE_TimeStamp_list = [];

% gracefully deal with empty trackerlogs
if isempty(EventIDE_TimeStamp_list)
	return
end
	
tracker_type = '';
% first deduce the type
if ~isempty(regexpi(tracker_name, 'PupilLabs', 'match'))
	tracker_type = 'pupillabs';
end
if ~isempty(regexpi(tracker_name, 'EyeLink', 'match'))
	tracker_type = 'eyelink';
end
if ~isempty(regexpi(tracker_name, 'PQLab', 'match'))
	tracker_type = 'pqlab';
end
if ~isempty(regexpi(tracker_name, 'NISignalFileWriter', 'match'))
	tracker_type = 'nisignalfilewriter';
end



% error out for unhandled types
switch tracker_type
	case 'pupillabs'
	case 'eyelink'
	case 'pqlab'
	case 'nisignalfilewriter'
	
	otherwise
		error(['Encountered unhandled tracker type: ', tracker_name, ' please handle gracefully']);
end


%corrected_EventIDE_TimeStamp_list = zeros(size(EventIDE_TimeStamp_list));

% matching the end should be the simplest, we simlpy take the youngest
% timestamps we find for each tracker
last_EventIDE_ts = max(EventIDE_TimeStamp_list);
last_Tracker_ts = max(Tracker_Time_Stamp_list);
% now to better match get the EventIDE_TimeStamp from the last_Tracker_ts
% sample
last_Tracker_ts_idx = find(Tracker_Time_Stamp_list == last_Tracker_ts); % if multiple pick the first one
closest_matching_last_EventIDE_ts = EventIDE_TimeStamp_list(last_Tracker_ts_idx(1));

if (Tracker_Time_Stamp_list(end) ~= last_Tracker_ts)
	disp('fn_extract_corrected_eventIDE_timestamps: last timestamp order of eventide and tracker not aligned, expected for PupilLabs data.');
end

first_EventIDE_ts = min(EventIDE_TimeStamp_list);	% again simple, as this is 
first_Tracker_ts = min(Tracker_Time_Stamp_list);	% again simple, as this is 
% and now we want the highest Tracker_Time_Stamp with an EventIDE_TimeStamp
% <= first_EventIDE_ts, we need to do this is especially pupillabs samples
% are not strictly ordered in time
first_EventIDE_ts_sample_idx = find(EventIDE_TimeStamp_list <= first_EventIDE_ts);
% now get the highest Tracker_Time_Stamp in that subset
closest_matching_first_Tracker_ts = max(Tracker_Time_Stamp_list(first_EventIDE_ts_sample_idx));

if (closest_matching_first_Tracker_ts ~= first_Tracker_ts)
	disp('fn_extract_corrected_eventIDE_timestamps: first timestamps of eventide and tracker not aligned, expected for PupilLabs data.');
end

ts_offset = first_EventIDE_ts;
ts_scale = (closest_matching_last_EventIDE_ts - first_EventIDE_ts) / (last_Tracker_ts - closest_matching_first_Tracker_ts);

% the actual correction will be different for the different trackers
switch tracker_type
	case 'pupillabs'
		% pupillabs data is unordered, but the main idea about aligning the
		% two timestamp series still should apply.
		corrected_EventIDE_TimeStamp_list = (Tracker_Time_Stamp_list - closest_matching_first_Tracker_ts) * ts_scale + ts_offset;
	case 'eyelink'
		corrected_EventIDE_TimeStamp_list = (Tracker_Time_Stamp_list - closest_matching_first_Tracker_ts) * ts_scale + ts_offset;
	case 'pqlab'
	case 'nisignalfilewriter'
		
		ts_range = last_EventIDE_ts - first_EventIDE_ts;
		n_timestamps = size(Tracker_Time_Stamp_list, 1);
		ts_scale = ts_range / (n_timestamps - 1);
		corrected_EventIDE_TimeStamp_list = ((0:1:n_timestamps-1)' * ts_scale) + ts_offset;
	
		% here we only have EventIDE Timestamps, but these are not equally
		% spaced temporally, as they should (assuming the NI card has a
		% reasonably stable clock) so just interpolate eventIDE timestamps
		% between start and end
		% but EventIDE might start with a different (arbitrary?) sampling rate, so try
		% to correct for that as well
		sample_interval_list = diff(Tracker_Time_Stamp_list);
		first_sample_interval = sample_interval_list(1);
		last_sample_interval = sample_interval_list(end);
		n_samples = size(sample_interval_list, 1);
		% assume that at most 1/3 of the samples are from the wrong rate
		reliable_min = min(sample_interval_list(floor(n_samples*0.33):end));
		reliable_mean = mean(sample_interval_list(floor(n_samples*0.33):end)); 
		
		correct_for_chunkSize = 0;
		chunk_error_type = '';
		pre_rate_to_main_rate_factor = 1.2;
		% this is just a bad heuristic to catch too high/low initial sampling
		if (first_sample_interval < reliable_mean) && (pre_rate_to_main_rate_factor * first_sample_interval < reliable_mean)
			correct_for_chunkSize = 1;
			chunk_error_type = 'too_low';
		end
		
		pre_rate_to_main_rate_factor_high = 0.99;
		% this is just a bad heuristic to catch too high/low initial sampling
		if (first_sample_interval > reliable_mean) && (pre_rate_to_main_rate_factor_high * first_sample_interval > reliable_mean)
			correct_for_chunkSize = 1;
			chunk_error_type = 'too_high';
		end
			
		if (correct_for_chunkSize)
		corrected_EventIDE_TimeStamp_list = ones(size(corrected_EventIDE_TimeStamp_list)) * -1000;
			i_bad_interval_sample = 0;
			% find the initial stretch of too low values
			% maybe better search for the first stretch of X samples that
			% are closer to the reliable_mean than to the first_sample_interval
			switch chunk_error_type
				case 'too_low'
					for i_bad_interval_sample = 1 : n_samples
						if (pre_rate_to_main_rate_factor * sample_interval_list(i_bad_interval_sample) < reliable_mean)
						else
							% break so i_sample contains the last offending
							% interval idx
							break
						end
					end
				case 'too_high'
					for i_bad_interval_sample = 1 : n_samples
						if (pre_rate_to_main_rate_factor_high * sample_interval_list(i_bad_interval_sample) > reliable_mean)
						else
							% break so i_sample contains the last offending
							% interval idx
							break
						end
					end
			end
			
			rate_change_idx = i_bad_interval_sample;
			disp(['Detected apparent rate change at around sample ', num2str(rate_change_idx+1)]);
			% there was a rate switch, so adjust both parts independently
			rate_change_ts = Tracker_Time_Stamp_list(rate_change_idx+1);
			mean_pre_switch_interval = mean(sample_interval_list(1:rate_change_idx));
			corrected_EventIDE_TimeStamp_list(1:rate_change_idx) = (0:1:rate_change_idx-1)' * mean_pre_switch_interval + ts_offset;
			
			mean_post_switch_interval = mean(sample_interval_list(rate_change_idx+1 : end));
			corrected_EventIDE_TimeStamp_list(rate_change_idx+1 : end) = ((0:1:(n_timestamps - rate_change_idx-1))' * mean_post_switch_interval) + rate_change_ts;	
		end
						
	otherwise
		error(['Encountered unhandled tracker type: ', tracker_name, ' please handle gracefully']);
end



if (debug)
	timestamp_correction_fh = figure('Name', 'EventIDE_TimeStamp_list - corrected_EventIDE_TimeStamp_list');
	subplot(4, 1, 1)
	hold on 
	plot(EventIDE_TimeStamp_list - EventIDE_TimeStamp_list(1), 'Color', [1 0 0]);
	legend_text = {'original EventIDE timestamps'};
	plot(corrected_EventIDE_TimeStamp_list - corrected_EventIDE_TimeStamp_list(1), 'Color', [0 1 0]);
	legend_text{end+1} = 'corrected_EventIDE_timestamps';
	plot(sort(corrected_EventIDE_TimeStamp_list) - corrected_EventIDE_TimeStamp_list(1), 'Color', [0 0 1]);
	legend_text{end+1} = 'sorted  corrected_EventIDE_timestamps';
	legend(legend_text);
	title('original and corrected timestamp series (offset by smalles timestamp)');
	hold off
	
	subplot(4, 1, 2)
	hold on 
	plot((EventIDE_TimeStamp_list - EventIDE_TimeStamp_list(1)) - (corrected_EventIDE_TimeStamp_list - corrected_EventIDE_TimeStamp_list(1)));
	title('original and corrected timestamp series');
	hold off

	subplot(4, 1, 3)
	h1 = histogram(diff(EventIDE_TimeStamp_list));
	hold on
	h2 = histogram(diff(sort(corrected_EventIDE_TimeStamp_list)));
	hold off
	
	subplot(4, 1, 4)
	h3 = histogram((EventIDE_TimeStamp_list - EventIDE_TimeStamp_list(1)) - (sort(corrected_EventIDE_TimeStamp_list) - corrected_EventIDE_TimeStamp_list(1)));
	
	
	[TrackerLog_path, TrackerLog_name] = fileparts(TrackerLog_FQN);
	write_out_figure(timestamp_correction_fh, fullfile(TrackerLog_path, [TrackerLog_name, 'Delta_corrected_ubcorrected_EventIDE_TimeStamps.pdf']));
	% for automated processing, rather save a plot than keep a figure
	% open...
	close(timestamp_correction_fh);
end

return
end



function [ tracker_name ] = fn_extract_trackername_from_filename( TrackerLog_Name, trackername_start_string, trackername_stop_string )
%tracker_start_string = '.TID_';
%tracker_stop_string = '.signallog';
tracker_name = [];

proto_start_idx = strfind(TrackerLog_Name, trackername_start_string);
if ~isempty(proto_start_idx)
	start_idx = proto_start_idx + length(trackername_start_string);
else
	disp(['Tracker name start identifier: ', trackername_start_string, ' not found in: ', TrackerLog_Name]);
	return
end

proto_stop_idx = strfind(TrackerLog_Name, trackername_stop_string);
if ~isempty(proto_stop_idx)
	stop_idx = proto_stop_idx - 1;
else
	disp(['Tracker name stop identifier: ', trackername_stop_string, ' not found in: ', TrackerLog_Name]);
	return
end

tracker_name = TrackerLog_Name(start_idx:stop_idx);

return
end

% function [ cells_are_of_equal_length, numel_per_cell_list ] = fn_get_numel_per_cell( TrackerLogCell )
% 
% n_cells = length(TrackerLogCell);
% cells_are_of_equal_length = 0;
% numel_per_cell_list = zeros(size(TrackerLogCell));
% 
% for i_cell = 1 : n_cells
% 	numel_per_cell_list(i_cell) = length(TrackerLogCell{i_cell});
% end
% 
% if (min(numel_per_cell_list(:) == max(numel_per_cell_list(:))))
% 	cells_are_of_equal_length = 1;
% end	
% return
% end