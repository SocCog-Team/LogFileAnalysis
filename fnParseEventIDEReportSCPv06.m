function [ report_struct ] = fnParseEventIDEReportSCPv06( ReportLog_FQN, ItemSeparator, ArraySeparator )
%PARSE_EVENTIDE_REPORT_SCP_V01 Summary of this function goes here
%   Try to read in eventIDE report files for DPZ SCP experiments
% hard code data types according to standard eventIDE columns
%TODO: implement and benchmark a textscan based method with after parsing
%	transfer into a data_struct (will require to implement add_column)
% Ideally each record type consist out of three lines, header, types, and
% data


global data_struct;	%% ATTENTION there can only be one concurrent user of this global variable, so reserve for the trial table
clear global data_struct % clear on return as well?

timestamps.(mfilename).start = tic;
disp(['Starting: ', mfilename]);
dbstop if error
fq_mfilename = mfilename('fullpath');
mfilepath = fileparts(fq_mfilename);


save_matfile = 1;
suffix_string = '';
test_timing = 0;
add_method = 'add_row_to_global_struct';		% add_row (really slow, just use for gold truth control), add_row_to_global_struct
pre_allocate_data = 0;
batch_grow_data_array = 1;	% should be default


if (test_timing)
	suffix_string = ['.', add_method];
end

% general log file information
info.logfile_FQN = [];
info.session_date_string = [];
info.session_date_vec = [];
info.experiment_eve = [];


% use the data log for the trial table, only use the global method for
% this?
data_struct.header = {};
data_struct.data = [];
% different types:
% TIMING, ENUM, CLISTATISTICS, TRIAL, SESSION, REWARD


if (~exist('ReportLog_FQN', 'var'))
	[ReportLog_Name, ReportLog_Dir] = uigetfile('*.log', 'Select the eventIDE log file to parse');
	ReportLog_FQN = fullfile(ReportLog_Dir, ReportLog_Name);
	%save_matfile = 1;
else
	[ReportLog_Dir, ReportLog_Name] = fileparts(ReportLog_FQN);
	%save_matfile = 0;
end
tmp_dir_ReportLog_FQN = dir(ReportLog_FQN);
ReportLog_size_bytes  = tmp_dir_ReportLog_FQN.bytes;

% default to semi-colon to separate the LogHeader and data lines
OverrideItemSeparator = 0;
if (~exist('ItemSeparator', 'var'))
	ItemSeparator = ';';
	OverrideItemSeparator = 1;
end
OverrideArraySeparator = 0;
if (~exist('ArraySeparator', 'var'))
	ArraySeparator = '|';
	OverrideArraySeparator = 1;
end


% open the file
ReportLog_fd = fopen(ReportLog_FQN, 'r');
if (ReportLog_fd == -1)
	error(['Could not open ', num2str(ReportLog_fd), ' none selected?']);
end
info.logfile_FQN = ReportLog_FQN;


CommentsList = {};

IDinfo_state = '';	% this is optional in eventIDE report file headers
LoggingInfo_state = '';
ReportRecords_state = '';
IDinfo_struct = struct([]);
LoggingInfo_struct = struct([]);
ProximitySensors_struct = struct();
Enums_struct = struct();	% this collects all structs for individual enums, in uniquelist format, a cell array of the names as strings with EnumName as list name
TmpEnum_struct = struct();	% lets use the existing machinery to parse
Screen_struct = struct();
Timing_struct = struct();
Session_struct = struct();
Trial_struct = struct();
CLIStatistics_struct = struct();
Setup_struct = struct();
Reward_struct = struct();
CurrentEnumFullyParsed = 0;

%loop over all lines in the ReportLog
while (~feof(ReportLog_fd))
	current_line = fgetl(ReportLog_fd);
	
	% skip empty lines
	if isempty(current_line)
		continue;
	end
	
	% allow comments initiated by the hash sign, but
	if isempty(strcmp(current_line(1), '#')) && ~strcmp(current_line, '###################');
		CommentsList{end+1} = current_line;	% comments should be rare, so no pre_allocation
		continue;
	end
	
	% info and header parts are whitespace separated
	[CurrentTokenWhiteSpace, remainWhiteSpace] = strtok(current_line);
	switch (CurrentTokenWhiteSpace)
		case '********************'
			% start of IDinfo
			IDinfo_struct = fnParseIDinfo(ReportLog_fd, current_line);
			IDinfo_state = 'parsed';
			continue
			%start up variables are unhandled strings before real data
			%records or the LOGGING section info
		case '###################'
			LoggingInfo_struct = fnParseLoggingInfo(ReportLog_fd, current_line);
			LoggingInfo_state = 'parsed';
			% use the separators defined in the logfile, unless they were
			% overriden by explicit scalling arguments
			if isfield(LoggingInfo_struct, 'ItemSeparator') && ~OverrideItemSeparator
				ItemSeparator = LoggingInfo_struct.ItemSeparator;
			end
			if isfield(LoggingInfo_struct, 'ArraySeparator') && ~ OverrideArraySeparator
				ArraySeparator = LoggingInfo_struct.ArraySeparator;
			end
			continue
	end
	
	% now look for known types
	[CurrentToken, remain] = strtok(current_line, ItemSeparator);
	
	switch (CurrentToken)
		case {'REWARD', 'REWARDHEADER', 'REWARDTYPES'}
			% currently those are manual rewards, skip them for now?
			% we want to build lists
			Reward_struct = fnParseHeaderTypeDataRecord(Reward_struct, current_line, 'REWARD', ItemSeparator, ArraySeparator);
			continue
		case {'PROXIMITYSENSORS', 'PROXIMITYSENSORSHEADER', 'PROXIMITYSENSORSTYPES'}
			ProximitySensors_struct = fnParseHeaderTypeDataRecord(ProximitySensors_struct, current_line, 'PROXIMITYSENSORS', ItemSeparator, ArraySeparator);
			continue
		case {'ENUMHEADER', 'ENUMTYPES', 'ENUM'}
			% needs special care as each individual enum reuses/redefines
			% ENUMHEADER, ENUMTYPES, and ENUM records, so for each
			% completed ENUM this requires clen-up (see below)
			% rthe 
			TmpEnum_struct = fnParseHeaderTypeDataRecord(TmpEnum_struct, current_line, 'ENUM', ItemSeparator);	
			if ((isfield(TmpEnum_struct, 'first_empty_row_idx')) && (TmpEnum_struct.first_empty_row_idx > 1))
				CurrentEnumFullyParsed = 1;
			else
				continue
			end
		case {'TIMING', 'TIMINGHEADER', 'TIMINGTYPES'}
			Timing_struct = fnParseHeaderTypeDataRecord(Timing_struct, current_line, 'TIMING', ItemSeparator, ArraySeparator);		
			continue
		case {'SESSION', 'SESSIONHEADER', 'SESSIONTYPES'}
			Session_struct = fnParseHeaderTypeDataRecord(Session_struct, current_line, 'SESSION', ItemSeparator, ArraySeparator);
			continue
		case {'CLISTATISTICS', 'CLISTATISTICSHEADER', 'CLISTATISTICSTYPES'}
			CLIStatistics_struct = fnParseHeaderTypeDataRecord(CLIStatistics_struct, current_line, 'CLISTATISTICS', ItemSeparator, ArraySeparator);
			continue
		case {'SETUP', 'SETUPHEADER', 'SETUPTYPES'}
			Setup_struct = fnParseHeaderTypeDataRecord(Setup_struct, current_line, 'SETUP', ItemSeparator, ArraySeparator);
			continue
		case {'SCREEN', 'SCREENHEADER', 'SCREENTYPES'}
			Screen_struct = fnParseHeaderTypeDataRecord(Screen_struct, current_line, 'SCREEN', ItemSeparator, ArraySeparator);
			continue
		case {'TRIAL', 'TRIALHEADER', 'TRIALTYPES', '\nTRIAL', '\nTRIALHEADER', '\nTRIALTYPES'}
			data_struct = fnParseHeaderTypeDataRecord(data_struct, current_line, 'TRIAL', ItemSeparator, ArraySeparator);
			continue
		otherwise
			%disp('Doh...');
	end
	
	% finalize the enum processing
	if (CurrentEnumFullyParsed)
		% now add TmpEnum_struct to Enums_struct, potentially also 
		CurrentEnumName = (TmpEnum_struct.unique_lists.EnumName{1});
		Enums_struct.Info = 'These can be used into columns that contain actual enum values [A|B]_${EnumName}(1:end-1); please note that C# enums are zero based';
		Enums_struct.(CurrentEnumName).unique_lists.(CurrentEnumName) = TmpEnum_struct.header(2:end);
		Enums_struct.(CurrentEnumName).EnumStruct = TmpEnum_struct;	% safety backup of parsed data
		% get ready for the next enum
		CurrentEnumFullyParsed = 0;
		TmpEnum_struct = struct();	% clear the tmp struct
		continue
	end
	
	
	
	% anything not parsed until here most likely is an eventIDE  startup
	% variable so just treat it like one
	[VariableName, VariableValue] = strtok(current_line, ':');
	SanitizedVariableName = sanitize_col_name_for_matlab(VariableName);
	StartUpVariables_struct.(SanitizedVariableName) = strtrim(VariableValue(2:end));
end

if ~(exist('StartUpVariables_struct', 'var'))
	StartUpVariables_struct = struct([]);
end

% % parse the informative header part
% info_header_parsed = 0;
% while (~info_header_parsed)
% 	current_line = fgetl(ReportLog_fd);
% 	[token, remain] = strtok(current_line, ':');
% 	found_header_line = 0;
% 	switch token
% 		case 'Date and time'
% 			DateVector = datevec(strtrim(remain(2:end)), 'yyyy.dd.mm HH:MM');
% 			info.session_date_string = strtrim(remain(2:end)); %TODO: maybe clean up/ reconstitute from datevec?
% 			info.session_date_vec = DateVector;
% 			found_header_line = 1;
% 		case 'Experiment'
% 			info.experiment_eve = [remain(2:end), '.eve'];
% 			found_header_line = 1;
% 		case 'Tracker'
% 			info.tracker_name = remain(2:end);
% 			found_header_line = 1;
% 	end
%
% 	if (~found_header_line)
% 		info_header_parsed = 1;
% 	end
% end
%
% % parse the LogHeader line (if it exists), we already have the current_line
% % NOTE we assume the string 'EventIDE TimeStamp' to be part of the LogHeader bot not
% % the data lines
% if ~isempty(strfind(current_line, 'EventIDE TimeStamp'))
% 	[header, LogHeader_list, ] = process_LogHeader(current_line, column_separator);
% 	info.LogHeader = LogHeader_list;
% 	% create the data structure
% 	data_struct = fn_handle_data_struct('create', header);
% 	current_line = fgetl(ReportLog_fd); % we need this for the next section where we wantto start with a loaded log line
% end
%
% data_start_offset = ftell(ReportLog_fd) - length(current_line);
%
%
% % now read and parse each data line in sequence, we already have the first
% % line loaded
% n_lines = 1;
%
% % estimate the number of lines in the ReportLog
% bytes_per_line = length(current_line);
% estimated_data_lines = (ReportLog_size_bytes - data_start_offset) / bytes_per_line;
% if (pre_allocate_data)
% 	data_struct.data = zeros([round(1.2 * estimated_data_lines) size(data_struct.data, 2)]);
% 	if (test_timing)
% 		suffix_string = [suffix_string, '.preallocated_data_array'];
% 	end
% end
%
% if (batch_grow_data_array)
% 	batch_size = floor(estimated_data_lines/10);
% 	batch_size = 500000; % needs tweaking, but 100000 should work
% 	suffix_string = [suffix_string, '.data_grow_batch_size_', num2str(batch_size)];
% else
% 	batch_size = 1;
% end
%
% report_every_n_lines = 1000;
% while (~feof(ReportLog_fd))
%
% 	current_row_data = extract_row_data_from_Log_line(current_line, data_struct.header, column_separator);
%
% 	switch add_method
% 		case 'add_row'
% 			report_every_n_lines = 100;
% 			data_struct = fn_handle_data_struct('add_row', data_struct, current_row_data, batch_size); % do not batch as we copy every byte multiple times
% 		case 'add_row_to_global_struct'
% 			report_every_n_lines = 10000;
% 			fn_handle_data_struct('add_row_to_global_struct', current_row_data, batch_size);
% 	end
%
% 	% get the next line
% 	current_line = fgetl(ReportLog_fd);
% 	n_lines = n_lines + 1;
% 	% add progress indicator
% 	if ~(mod(n_lines, report_every_n_lines))
% 		cur_fpos = ftell(ReportLog_fd);
% 		processed_size_pct = 100 * (cur_fpos / (ReportLog_size_bytes - data_start_offset));
% 		disp(['Processed ', num2str(n_lines), ' lines of the ReportLog file (', num2str(processed_size_pct, '%5.2f'),' %).']);
% 	end
% end
%


% clean up
fclose(ReportLog_fd);
%data_struct = fn_handle_data_struct('truncate_to_actual_size', data_struct);


% add the sessionID (create from time and setupID
TmpDateVector = IDinfo_struct.DateVector;
SessionDataTimeValue = TmpDateVector(6)*10 + TmpDateVector(5) * 100 + TmpDateVector(4) * 10000 + ...
	TmpDateVector(3) * 1000000 + TmpDateVector(2) * 100000000 + TmpDateVector(1) * 10000000000;
SessionSetUpIdCode =  str2double(IDinfo_struct.Computer(end-1:end));
% create a numeric ID for the different set-ups
SessionIdValue = SessionDataTimeValue + SessionSetUpIdCode * 100000000000000;
%num2str(SessionIdValue)
NewDataColumn = ones([size(data_struct.data, 1), 1]) * SessionIdValue;
data_struct = fn_handle_data_struct('add_columns', data_struct, NewDataColumn, {'SessionID'});


% also add reward information to the trial table
% for this we nned to parse the Reward_struct and create columns to add to
% te data table
if ~isempty(Reward_struct)
	RewardPerTrialInfo_struct = fnExtractPerTrialRewardInfo(Reward_struct, size(data_struct.data, 1));
	data_struct = fn_handle_data_struct('add_columns', data_struct, RewardPerTrialInfo_struct.data, RewardPerTrialInfo_struct.header);
end

% now try to add columns to the main data table, for enum indices
% (zero-based), 
if ~isempty(Enums_struct)
	% for all named enums find matching columns and create and add the
	% corresponding _idx column (add one to the C# indices), add the enum
	% header to the unique_list with the appropriate name
	data_struct = fnAddEnumsToDataStruct(data_struct, Enums_struct, {'A_', 'B_'}, {'s'});
end


report_struct = data_struct;
report_struct.EventIDEinfo = IDinfo_struct;
report_struct.LoggingInfo = LoggingInfo_struct;
report_struct.StartUpVariables = StartUpVariables_struct;
report_struct.ProximitySensors = ProximitySensors_struct;
report_struct.Screen = Screen_struct;
report_struct.Timing = Timing_struct;
report_struct.Session = Session_struct;
report_struct.CLIStatistics = CLIStatistics_struct;
report_struct.Setup = Setup_struct;
report_struct.Enums = Enums_struct;
report_struct.Reward = Reward_struct;


% add the additional information structure
report_struct.info = info;

report_struct.info.processing_time_ms = toc(timestamps.(mfilename).start);
if (save_matfile)
	save(fullfile(ReportLog_Dir, [ReportLog_Name, suffix_string, '.mat']), 'report_struct');
end

timestamps.(mfilename).end = toc(timestamps.(mfilename).start);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end), ' seconds.']);
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end / 60), ' minutes. Done...']);

return
end



function 	[ header, LogHeader_list ] = process_LogHeader( LogHeader_line, column_separator )
% LogHeader found, so parse it
% special field names:
% string:	'Current Event', 'Paradigm', 'DebugInfo'

header = {};			% this is the prcessed and expanded header readf for fn_handle_data_struct
LogHeader_list = {};	% just a cell array of the individual columns of the LogHeader string, dissected at column_separator

LogHeader_parsed = 0;
raw_LogHeader = LogHeader_line;
while (~LogHeader_parsed)
	[current_raw_column_name, raw_LogHeader] = strtok(raw_LogHeader, column_separator); % strtok will ignore leading column_separator
	LogHeader_list{end+1} = current_raw_column_name;
	current_raw_column_name = strtrim(current_raw_column_name);% ignore leading and trailing white space
	% some column names are special
	switch current_raw_column_name
		case {'Current Event', 'Paradigm', 'DebugInfo'}
			current_raw_column_name = sanitize_col_name_for_matlab(current_raw_column_name);
			current_raw_column_name = [current_raw_column_name, '_idx'];
			header{end+1} = current_raw_column_name;
		case {'GLM Coefficients'}
			% complex:	'GLM Coefficients' (GainX=1 OffsetX=0 GainY=1 OffsetY=0)
			header{end+1} = 'GLM_Coefficients_GainX';
			header{end+1} = 'GLM_Coefficients_OffsetX';
			header{end+1} = 'GLM_Coefficients_GainY';
			header{end+1} = 'GLM_Coefficients_OffsetY';
		otherwise
			current_raw_column_name = sanitize_col_name_for_matlab(current_raw_column_name);
			header{end+1} = current_raw_column_name;
	end
	if isempty(raw_LogHeader) || (length(raw_LogHeader) ==  length(column_separator)) || strcmp(raw_LogHeader, column_separator)
		LogHeader_parsed = 1;
	end
	%disp(current_raw_column_name);
end

return
end


function [ row_data ] = extract_row_data_from_Log_line(log_line, column_name_list, column_separator)
% process the raw line from the ReportLog and transform into a form
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
			GLM_values(i_glm) = str2double(GLM_value);
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

if (strcmp(raw_column_name, ' '))
	sanitized_column_name = 'EmptyString';
	disp('Found empty string as column/variable name, replacing with "EmptyString"...');
end

return
end

function [ IDinfo_struct ] = fnParseIDinfo( ReportLog_fd, current_line )
% ******************** % this is in current line
% Experiment:   0014_DAGDFGR.v014.14.20170322.02
% Computer:  SCP-CTRL-01
% Date:  3/22/2017
% Time:  11:43 AM
% *******************
IDinfo_struct = struct();

while ~(feof(ReportLog_fd))
	current_line = fgetl(ReportLog_fd);
	if strcmp(current_line(1:10), '**********')
		% we reached the end of the ID info
		% ATTENTION the end marker are 19 stars...
		break
	end
	[Key, Value] = strtok(current_line, ':');
	switch (Key)
		case 'Experiment'
			IDinfo_struct.Experiment = strtrim(Value(2:end));
		case 'Computer'
			IDinfo_struct.Computer = strtrim(Value(2:end));
		case 'Date'
			IDinfo_struct.DateString = strtrim(Value(2:end));
		case 'Time'
			IDinfo_struct.TimeString = strtrim(Value(2:end));
	end
end

if isfield(IDinfo_struct, 'DateString') && isfield(IDinfo_struct, 'TimeString')
    
    TmpDateTimeString = [IDinfo_struct.DateString, ', ', IDinfo_struct.TimeString];
    if ~isempty(findstr(TmpDateTimeString, '/'))
        IDinfo_struct.DateVector = datevec(TmpDateTimeString, 'mm/dd/yyyy, HH:MM PM');
    end

    if ~isempty(findstr(TmpDateTimeString, '-'))
        IDinfo_struct.DateVector = datevec(TmpDateTimeString, 'yyyy-mm-dd, HH:MM');
    end
end



return
end


function [ LoggingInfo_struct ] = fnParseLoggingInfo( ReportLog_fd, current_line )
% ################### % this is in current line
% LOGGING.SessionDate: 20170322
% LOGGING.SessionLogFileName: 20170322T114239.A_TestA.B_None.SCP_01
% LOGGING.SessionDir: C:\SCP_DATA\SCP-CTRL01\SESSIONLOGS\20170322
% LOGGING.SessionFQN: C:\SCP_DATA\SCP-CTRL01\SESSIONLOGS\20170322\20170322T114239.A_TestA.B_None.SCP_01.log
% LOGGING.SessionTrackerLogDir: C:\SCP_DATA\SCP-CTRL01\SESSIONLOGS\20170322\TrackerLogs
% LOGGING.ItemSeparator: ;
% LOGGING.ArraySeparator: |
% LOGGING.ReportVersion: 2
% ###################

LoggingInfo_struct = struct();

while ~(feof(ReportLog_fd))
	current_line = fgetl(ReportLog_fd);
	if strcmp(current_line, '###################')
		% we reached the end of the ID info
		break
	end
	[FullKey, Value] = strtok(current_line, ':');
	[KeyPrefix, Key] = strtok(FullKey, '.');
	SanitizedKey = sanitize_col_name_for_matlab(Key(2:end));
	LoggingInfo_struct.(SanitizedKey) = strtrim(Value(2:end));
	
	switch (SanitizedKey)
		case 'ReportVersion'
			LoggingInfo_struct.(SanitizedKey) = double(strtrim(Value(2:end)));
		case 'SessionDate'
			LoggingInfo_struct.SessionDateVec = datevec(strtrim(Value(2:end)), 'yyyymmdd');
	end
end

return
end


function [ local_data_struct ] = fnParseHeaderTypeDataRecord( local_data_struct, current_line, RecordTypeHint, ItemSeparator, ArraySeparator )
% TODO store reference types for reference headers, in case of non types
% headers create the types list by matching header names to the reference
% sets

persistent ReferenceHeaderAndTypesByRecordType_struct
RemoveEmptyHeaderColumns = 1;
batch_size = 1;
DoSanitizeNames = 1;

if strcmp(RecordTypeHint, 'TRIAL')
	tmp = 'Doh...';
end

if isempty(ReferenceHeaderAndTypesByRecordType_struct)
	% only do this once and only if needed
	ReferenceHeaderAndTypesByRecordType_struct = fnDefineReferenceHeaderAndTypesByRecordType_struct();
end

[RecordName, remain] = strtok(current_line, ItemSeparator);

if ~isempty(regexp(RecordName, 'HEADER$'))
	RecordType = 'header';
	
	tmp_current_line = fnFixLogFileErrors(current_line);
	if ~strcmp(tmp_current_line, current_line)
		local_data_struct.raw.UnfixedHeaderString = current_line;
		current_line = tmp_current_line;
	end
	
	local_data_struct.raw.HeaderString = current_line;
	tmp_raw_header = fnSplitDelimitedStringToCells(current_line, ItemSeparator);
	tmp_header = fnSplitDelimitedStringToCells(current_line, ItemSeparator, DoSanitizeNames);	% DoSanitize names
	local_data_struct.raw.header = tmp_raw_header(2:end);
	tmp_header = tmp_header(2:end);
	if isempty(tmp_raw_header{end}) && RemoveEmptyHeaderColumns
		local_data_struct.raw.header = tmp_raw_header(2:end-1);
		tmp_header = tmp_header(1:end-1);
	end
	
	
	
	local_data_struct.raw.header4matlab = tmp_header;
	%local_data_struct = fn_handle_data_struct('create', tmp_header); % do not use batching, as we will only have relatively few trials anyway
	
	
elseif ~isempty(regexp(RecordName, 'TYPES$'))
	RecordType = 'types';
	
	tmp_current_line = fnFixLogFileErrors(current_line);
	if ~strcmp(tmp_current_line, current_line)
		local_data_struct.raw.UnfixedTypesString = current_line;
		current_line = tmp_current_line;
	end
	
	local_data_struct.raw.TypesString = current_line;
	tmp_types = fnSplitDelimitedStringToCells(current_line, ItemSeparator);
	local_data_struct.raw.types = tmp_types(2:end);
	if isempty(tmp_types{end}) && RemoveEmptyHeaderColumns
		local_data_struct.raw.types = tmp_types(2:end-1);
	end
	
else
	RecordType = 'data';
end

% without header information the data columns are impossible to generically
% parse, so punt...
if strcmp(RecordType, 'data') && (~isfield(local_data_struct, 'header') || isempty(local_data_struct.header))
	error(['Encountered a data record type before/without a defining header record: \n', current_line]);
end

% older report logs had headers but no explicit type information, try to
% get this by matching
if strcmp(RecordType, 'data') && ~isempty(local_data_struct.header) && ~isfield(local_data_struct.raw, 'types')
	%no types defined in this report file, try to deduce them from the
	%header list
	local_data_struct.raw.types = fnMatchHeaderTypesFromReference(local_data_struct.raw.header, ReferenceHeaderAndTypesByRecordType_struct.(RecordTypeHint));
end

% okay now we know the types and need to adjust the header entries that
% will contain indexed values
if (~isfield(local_data_struct, 'header') || isempty(local_data_struct.header)) && isfield(local_data_struct.raw, 'types')
	tmp_header = {};
	for iColumn = 1 : length(local_data_struct.raw.header4matlab)
		CurrentProtoHeaderColumn = local_data_struct.raw.header4matlab{iColumn};
		
% 		if strcmp(RecordTypeHint, 'TRIAL')
% 			disp('Doh...');
% 		end
		
		switch (local_data_struct.raw.types{iColumn})
			case {''}
				if strcmp(CurrentProtoHeaderColumn, 'EmptyString')
					tmp_header{end+1} = CurrentProtoHeaderColumn;
				else
					error('Found unexpected empty type, please investigate and fix the code...');
				end
			case {'String', 'Int32[]', 'clPoint[]'}
				% strings need to to be indexed and variable length arrays
				% should as well
				if  length(CurrentProtoHeaderColumn) < 4 || ~strcmp(CurrentProtoHeaderColumn(end-3:end), '_idx')
					CurrentProtoHeaderColumn = [CurrentProtoHeaderColumn, '_idx'];
				end
				tmp_header{end+1} = CurrentProtoHeaderColumn;
			case {'clPoint'}
				tmp_header{end+1} = [CurrentProtoHeaderColumn, '_X'];
				tmp_header{end+1} = [CurrentProtoHeaderColumn, '_Y'];
			case {'Boolean'}
				% no special treatment for header, only for data
				tmp_header{end+1} = CurrentProtoHeaderColumn;
			otherwise
				% everything else (Int32, Double, clTime)
				tmp_header{end+1} = CurrentProtoHeaderColumn;
		end
	end
	tmp_raw_struct = local_data_struct.raw;
	local_data_struct = fn_handle_data_struct('create', tmp_header, batch_size);
	local_data_struct.raw = tmp_raw_struct; % 'create' will return a squeeky clean structure
end

% now we have the header and the type list and a line of data that needs
% processing
if strcmp(RecordType, 'data')
	DataCells = fnSplitDelimitedStringToCells(current_line, ItemSeparator, ~DoSanitizeNames);
	DataCells = DataCells(2:end);% chop off the TRIAL cell
	if isempty(DataCells{end}) && RemoveEmptyHeaderColumns
		DataCells = DataCells(1:end-1);
	end
	OutDataCells = {};
	
	if length(DataCells) ~= length(local_data_struct.raw.types)
		
		error(['The ', RecordTypeHint, '-type data record does not match the length of the respective types list, investigate \n ', current_line]);
	end
	
	
	for iColumn = 1 : length(DataCells)
		CurrentData = DataCells{iColumn};
		CurrentType = local_data_struct.raw.types{iColumn};
		switch (CurrentType)
			case {''}
				OutDataCells{end+1} = 0;	% just zero empty fields
			case {'String', 'string', 'Int32[]', 'clPoint[]'}
				% strings need to to be indexed and variable length arrays
				% should as well
				OutDataCells{end+1} = CurrentData;
			case {'clPoint'}
				%"1182,445 (6.029°, 23.167?°)"
				tmp_XY_string = strtok(CurrentData, ' ('); % remove the DVA values
				OutDataCells{end+1} = str2num(tmp_XY_string);
			case {'Boolean'}
				% do not treat this as a String or indexed value
				if strcmp(CurrentData, 'True')
					OutDataCells{end+1} = 1;
				elseif strcmp(CurrentData, 'False')
					OutDataCells{end+1} = 0;
				end
			otherwise
				% everything else (Int32, Double, clTime)
				OutDataCells{end+1} = str2double(CurrentData);
				
		end
		
		if isnan(OutDataCells{end})
			Error(['Failed while trying to convert: ', CurrentData, ' to double, please investigate and fix']);
		end
		
	end
	local_data_struct = fn_handle_data_struct('add_row', local_data_struct, OutDataCells, batch_size);
end

return
end


function [ OutStruct ] = fnDefineReferenceHeaderAndTypesByRecordType_struct()
% for old ReportLogs without explicitly logged C# data types per reported
% value use the existing header to find the matching reference header and
% create the matching type list, by finding the index of logged header name
% in OutStruct.XXX.header and then use that index to grab the according
% type from OutStruct.XXX.types...
%TODO: instead of manually formatting the data copy in a full string and
%split into cell programmatically... probably not worth it...


OutStruct.PROXIMITYSENSORS.header = {'DI_line_address', 'InvertSignal', 'IsHigh', 'ChangeTime_ms', 'Name'};
OutStruct.PROXIMITYSENSORS.types = {'Byte', 'Boolean', 'Boolean', 'clTime', 'String'};

OutStruct.TIMING.header = {'Timestamp', 'SystemTime'};
OutStruct.TIMING.types = {'clTime', 'String'};

OutStruct.CLISTATISTICS.header = {'Timestamp', 'TrialNumber', 'IntervalStartTime', 'IntervalEndTime', 'NumIntervals', 'Minimum', ...
	'LowerQuartile', 'Median', 'UpperQuartile', 'Maximum'};
OutStruct.CLISTATISTICS.types = {'clTime', 'Int32', 'clTime', 'clTime', 'Int32', 'Double', 'Double', 'Double', 'Double', 'Double'};

OutStruct.SCREEN.header = {'Timestamp', 'Name', 'ScreenWidth_mm', 'ScreenHeight_mm', 'ScreenWidth_pixel', 'ScreenHeight_pixel', 'ScreenPixel2MM', 'ScreenMM2Pixel'};
OutStruct.SCREEN.types = {'clTime', 'String', 'Double', 'Double', 'Int32', 'Int32', 'Double', 'Double'};


OutStruct.SESSIONH.header = {'Timestamp', 'Name', 'TrialType', 'TouchTargetsNum', 'CuePositionalElementsIndices', ...
	'TouchPositionalElementsIndices', 'CurrentlyHeldTouchPositionalElementsIndices', 'TrialNumber', 'InitialHoldDur_ms', 'CueAcqTouchDur_ms', ...
	'CueHoldTouchDur_ms', 'CueTargetDelay_ms', 'TargetAcqTouchDur_ms', 'TargetHoldTouchDur_ms', 'TargetOffsetRewardDelay_ms', 'AbortTimeOut_ms; ITI_ms', ...
	'TouchDotSize_mm', 'FixationDotSize_mm', 'TouchDotSize_pixel', 'TouchROISize_pixel', 'TouchROISize_mm', 'FixationDotSize_pixel', 'CorrectionTrialMethod', ...
	'TouchCuePosition', 'NumTouchTargetPositions', 'TouchTargetPositions', 'TouchTargetPositioningMethod'};
OutStruct.SESSION.types = {'clTime', 'String', 'Int32', 'Int32', 'Int32[]', 'Int32[]', 'Int32[]', 'Int32', 'Int32', 'Int32', 'Int32', ...
	'Int32', 'Int32', 'Int32', 'Int32', 'Int32', 'Int32', 'Int32', 'Int32', 'Int32', 'Int32', 'Int32', 'Int32', 'Int32', 'clPoint', 'Int32', ...
	'clPoint[]', 'String'};


OutStruct.TRIAL.header = {'Timestamp', 'TrialNumber', ...
	'A_Name', 'A_CurrentParadigm', 'A_IsActive', 'A_IsHoldingAll', 'A_IsHoldingLeft', 'A_IsHoldingRight', ...
	'A_IsTrialInitiated', 'A_PlaySuccessSound', 'A_PlayAbortSound', 'A_TrialType', 'A_TriaTypeString', 'A_TmpNextParadigmState', 'A_PerfectTrial', ...
	'A_EvaluateProximitySensors', 'A_EvaluateTouchPanel', 'A_AllowedReachEffectors', 'A_ReachEffector', 'A_ReachEffectorString', 'A_IsTouchingCue', ...
	'A_IsTouchingTarget01', 'A_Outcome', 'A_OutcomeString', 'A_NumCorrectResponses', 'A_AbortReason', 'A_AbortReasonString', 'A_AbortedState', ...
	'A_AbortedStateString', 'A_NumInitiatedTrials', 'A_NumCorrectRewards', 'A_NumTotalRewards', 'A_TotalRewardActiveDur_ms', ...
	'A_DualSubjectProgressConditional', 'A_DualSubjectAbortConditional', 'A_AbortTime_ms', 'A_CueOnsetTime_ms', 'A_HoldReleaseTime_ms', 'A_CueTouchTime_ms', ...
	'A_CueReleaseTime_ms', 'A_TargetOnsetTime_ms', 'A_TargetTouchTime_ms', 'A_TargetOffsetTime_ms', 'A_TmpTouchReleaseTime_ms', 'A_TouchROIAllowedReleases_ms', ...
	'A_TouchCuePosition', 'A_TouchTarget01Position', ...
	'B_Name', 'B_CurrentParadigm', 'B_IsActive', 'B_IsHoldingAll', 'B_IsHoldingLeft', 'B_IsHoldingRight', ...
	'B_IsTrialInitiated', 'B_PlaySuccessSound', 'B_PlayAbortSound', 'B_TrialType', 'B_TriaTypeString', 'B_TmpNextParadigmState', 'B_PerfectTrial', ...
	'B_EvaluateProximitySensors', 'B_EvaluateTouchPanel', 'B_AllowedReachEffectors', 'B_ReachEffector', 'B_ReachEffectorString', 'B_IsTouchingCue', ...
	'B_IsTouchingTarget01', 'B_Outcome; B_OutcomeString', 'B_NumCorrectResponses', 'B_AbortReason', 'B_AbortReasonString', 'B_AbortedState', ...
	'B_AbortedStateString', 'B_NumInitiatedTrials', 'B_NumCorrectRewards', 'B_NumTotalRewards', 'B_TotalRewardActiveDur_ms', ...
	'B_DualSubjectProgressConditional', 'B_DualSubjectAbortConditional', 'B_AbortTime_ms', 'B_CueOnsetTime_ms', 'B_HoldReleaseTime_ms', 'B_CueTouchTime_ms', ...
	'B_CueReleaseTime_ms', 'B_TargetOnsetTime_ms', 'B_TargetTouchTime_ms', 'B_TargetOffsetTime_ms', 'B_TmpTouchReleaseTime_ms', 'B_TouchROIAllowedReleases_ms', ...
	'B_TouchCuePosition', 'B_TouchTarget01Position'};
OutStruct.TRIAL.types = {'clTime', 'Int32String', 'String', ' Boolean', ' Boolean', ' Boolean', ' Boolean', ' Boolean', ' Boolean', ' Boolean', ' Int32', ...
	' String', ' Int32', ' Boolean', ' Boolean', ' Boolean', ' Int32', ' Int32', ' String', ' Boolean', ' Boolean', ' Int32', ' String', ' Int32', ' Int32', ...
	' String', ' Int32', ' String', ' Int32', ' Int32', ' Int32', ' Int32', ' String', ' String', ' clTime', ' clTime', ' clTime', ' clTime', ' clTime', ...
	' clTime', ' clTime', ' clTime', ' clTime', ' clTime', ' clPoint', ' clPoint', ' String', ' String', ' Boolean', ' Boolean', ' Boolean', ' Boolean', ...
	' Boolean', ' Boolean', ' Boolean', ' Int32', ' String', ' Int32', ' Boolean', ' Boolean', ' Boolean', ' Int32', ' Int32', ' String', ' Boolean', ...
	' Boolean', ' Int32', ' String', ' Int32', ' Int32', ' String', ' Int32', ' String', ' Int32', ' Int32', ' Int32', ' Int32', ' String', ' String', ...
	' clTime', ' clTime', ' clTime', ' clTime', ' clTime', ' clTime', ' clTime', ' clTime', ' clTime', ' clTime', ' clPoint', ' clPoint'};


return
end

function [ CellList ] = fnSplitDelimitedStringToCells( InputString, ItemSeparator, DoSanitizeNames )
% split a delimited string into components and return as cell array
remain = InputString;
CellList = {};

if ~exist('DoSanitizeNames', 'var')
	DoSanitizeNames = 0;
end

while ~isempty(remain)
	[CurrentValue, remain] = strtok(remain, ItemSeparator);
	if (DoSanitizeNames)
		CurrentValue = sanitize_col_name_for_matlab(CurrentValue);
	end
	CellList{end + 1} = strtrim(CurrentValue);
end

return
end

function [ TypeCell ] = fnMatchHeaderTypesFromReference(CurrentHeader, ReferenceStruct)
% get the index of the current
TypeCell = {};
for i_Column = 1: length(CurrentHeader)
	MatchIdx = find(strcmp(CurrentHeader{i_Column}, ReferenceStruct.header));
	TypeCell{i_Column} = ReferenceStruct.types{MatchIdx};
end

return
end


function [ current_line ] = fnFixLogFileErrors( current_line )
% any fixups to Report file entries go here

BadStrings = {'TRIALHEADER; Timestamp; TrialNumber; A_Name; A_CurrentParadigm; A_IsActive; A_IsHoldingAll; A_IsHoldingLeft; A_IsHoldingRight; A_IsTrialInitiated; A_PlaySuccessSound; A_PlayAbortSound; A_TrialType; A_TriaTypeString; A_TmpNextParadigmState; A_PerfectTrial; A_EvaluateProximitySensors; A_EvaluateTouchPanel; A_AllowedReachEffectors; A_ReachEffector; A_ReachEffectorString; A_IsTouchingCue; A_IsTouchingTarget01; A_Outcome; A_OutcomeString; A_NumCorrectResponses; A_AbortReason; A_AbortReasonString; A_AbortedState; A_AbortedStateString; A_NumInitiatedTrials; A_NumCorrectRewards; A_NumTotalRewards; A_TotalRewardActiveDur_ms; A_DualSubjectProgressConditional; A_DualSubjectAbortConditional; A_AbortTime_ms; A_CueOnsetTime_ms; A_HoldReleaseTime_ms; A_CueTouchTime_ms; A_CueReleaseTime_ms; A_TargetOnsetTime_ms; A_TargetTouchTime_ms; A_TargetOffsetTime_ms; A_TmpTouchReleaseTime_ms; A_TouchROIAllowedReleases_ms; A_TouchCuePosition; A_TouchTarget01Position; ; B_Name; B_CurrentParadigm; B_IsActive; B_IsHoldingAll; B_IsHoldingLeft; B_IsHoldingRight; B_IsTrialInitiated; B_PlaySuccessSound; B_PlayAbortSound; B_TrialType; B_TriaTypeString; B_TmpNextParadigmState; B_PerfectTrial; B_EvaluateProximitySensors; B_EvaluateTouchPanel; B_AllowedReachEffectors; B_ReachEffector; B_ReachEffectorString; B_IsTouchingCue; B_IsTouchingTarget01; B_Outcome; B_OutcomeString; B_NumCorrectResponses; B_AbortReason; B_AbortReasonString; B_AbortedState; B_AbortedStateString; B_NumInitiatedTrials; B_NumCorrectRewards; B_NumTotalRewards; B_TotalRewardActiveDur_ms; B_DualSubjectProgressConditional; B_DualSubjectAbortConditional; B_AbortTime_ms; B_CueOnsetTime_ms; B_HoldReleaseTime_ms; B_CueTouchTime_ms; B_CueReleaseTime_ms; B_TargetOnsetTime_ms; B_TargetTouchTime_ms; B_TargetOffsetTime_ms; B_TmpTouchReleaseTime_ms; B_TouchROIAllowedReleases_ms; B_TouchCuePosition; B_TouchTarget01Position; ; ', ...
	'TRIALTYPES; clTime; Int32; String; String; Boolean; Boolean; Boolean; Boolean; Boolean; Boolean; Boolean; Int32; String; Int32; Boolean; Boolean; Boolean; Int32; Int32; String; Boolean; Boolean; Int32; String; Int32; Int32; String; Int32; String; Int32; Int32; Int32; Int32; String; String; clTime; clTime; clTime; clTime; clTime; clTime; clTime; clTime; clTime; clTime; clPoint; clPoint; ; String; String; Boolean; Boolean; Boolean; Boolean; Boolean; Boolean; Boolean; Int32; String; Int32; Boolean; Boolean; Boolean; Int32; Int32; String; Boolean; Boolean; Int32; String; Int32; Int32; String; Int32; String; Int32; Int32; Int32; Int32; String; String; clTime; clTime; clTime; clTime; clTime; clTime; clTime; clTime; clTime; clTime; clPoint; clPoint; ; ', ...
	' TrialNumberA_Name;', ' Int32String;'};
ReplacementStrings = {'TRIALHEADER; Timestamp; TrialNumber; A_Name; A_CurrentParadigm; A_IsActive; A_IsHoldingAll; A_IsHoldingLeft; A_IsHoldingRight; A_IsTrialInitiated; A_PlaySuccessSound; A_PlayAbortSound; A_TrialType; A_TriaTypeString; A_TmpNextParadigmState; A_PerfectTrial; A_EvaluateProximitySensors; A_EvaluateTouchPanel; A_AllowedReachEffectors; A_ReachEffector; A_ReachEffectorString; A_IsTouchingCue; A_IsTouchingTarget01; A_Outcome; A_OutcomeString; A_NumCorrectResponses; A_AbortReason; A_AbortReasonString; A_AbortedState; A_AbortedStateString; A_NumInitiatedTrials; A_NumCorrectRewards; A_NumTotalRewards; A_TotalRewardActiveDur_ms; A_DualSubjectProgressConditional; A_DualSubjectAbortConditional; A_AbortTime_ms; A_CueOnsetTime_ms; A_HoldReleaseTime_ms; A_CueTouchTime_ms; A_CueReleaseTime_ms; A_TargetOnsetTime_ms; A_TargetTouchTime_ms; A_TargetOffsetTime_ms; A_TmpTouchReleaseTime_ms; A_TouchROIAllowedReleases_ms; A_TouchCuePosition; A_TouchTarget01Position; ; B_Name; B_CurrentParadigm; B_IsActive; B_IsHoldingAll; B_IsHoldingLeft; B_IsHoldingRight; B_IsTrialInitiated; B_PlaySuccessSound; B_PlayAbortSound; B_TrialType; B_TriaTypeString; B_TmpNextParadigmState; B_PerfectTrial; B_EvaluateProximitySensors; B_EvaluateTouchPanel; B_AllowedReachEffectors; B_ReachEffector; B_ReachEffectorString; B_IsTouchingCue; B_IsTouchingTarget01; B_Outcome; B_OutcomeString; B_NumCorrectResponses; B_AbortReason; B_AbortReasonString; B_AbortedState; B_AbortedStateString; B_NumInitiatedTrials; B_NumCorrectRewards; B_NumTotalRewards; B_TotalRewardActiveDur_ms; B_DualSubjectProgressConditional; B_DualSubjectAbortConditional; B_AbortTime_ms; B_CueOnsetTime_ms; B_HoldReleaseTime_ms; B_CueTouchTime_ms; B_CueReleaseTime_ms; B_TargetOnsetTime_ms; B_TargetTouchTime_ms; B_TargetOffsetTime_ms; B_TmpTouchReleaseTime_ms; B_TouchROIAllowedReleases_ms; B_TouchCuePosition; B_TouchTarget01Position; ', ...
	'TRIALTYPES; clTime; Int32; String; String; Boolean; Boolean; Boolean; Boolean; Boolean; Boolean; Boolean; Int32; String; Int32; Boolean; Boolean; Boolean; Int32; Int32; String; Boolean; Boolean; Int32; String; Int32; Int32; String; Int32; String; Int32; Int32; Int32; Int32; String; String; clTime; clTime; clTime; clTime; clTime; clTime; clTime; clTime; clTime; clTime; clPoint; clPoint; ; String; String; Boolean; Boolean; Boolean; Boolean; Boolean; Boolean; Boolean; Int32; String; Int32; Boolean; Boolean; Boolean; Int32; Int32; String; Boolean; Boolean; Int32; String; Int32; Int32; String; Int32; String; Int32; Int32; Int32; Int32; String; String; clTime; clTime; clTime; clTime; clTime; clTime; clTime; clTime; clTime; clTime; clPoint; clPoint; ', ...
	' TrialNumber; A_Name;', ' Int32; String;'};

for i_BadString = 1 : length(BadStrings)
	CurrentBadString = BadStrings{i_BadString};
	CurrentReplacementString = ReplacementStrings{i_BadString};
	
	BadStringStartIdx = strfind(current_line, CurrentBadString);
	%[BadStringStartIdx2, BadStringStartIdx2] = regexp(current_line, CurrentBadString);
	
	if ~isempty(BadStringStartIdx)
		%loop over from the back
		for i_BadStringInstance = length(BadStringStartIdx) : -1 : 1
			tmp_current_line = current_line;
			
			CurrentBadStringStartIdx = BadStringStartIdx(i_BadStringInstance);
			CurrentBadStringEndIdx = CurrentBadStringStartIdx + length(CurrentBadString) - 1;
			
			if (CurrentBadStringStartIdx == 1)
				current_line = [CurrentReplacementString, tmp_current_line(CurrentBadStringEndIdx+1:end)];
			else
				current_line = [tmp_current_line(1:CurrentBadStringStartIdx-1), CurrentReplacementString, tmp_current_line(CurrentBadStringEndIdx+1:end)];
			end			
			disp(['Replaced unwanted string: "', CurrentBadString, '" with "', CurrentReplacementString, '".']);			
		end
	end
	
end

return
end


function [ data_struct ] = fnAddEnumsToDataStruct( data_struct, Enums_struct, DataHeaderPrefixList, EnumKeyIgnoredSuffixList )
% for all named enums find columns in the data table that contain zero
% based indices in the respective Enum, translate into the _idx plus
% matching unique_list format of data_struct
% DataHeaderPrefixList list of prefixes to add to the EnumName to generate
% the matching column name
% EnumKeyIgnoredSuffixList list of suffixes of the EnumName that does not
% match the data_struct.header


EnumNamesList = fieldnames(Enums_struct);

for iEnumName = 1 : length(EnumNamesList) 
	CurrentEnumName = EnumNamesList{iEnumName};
	% the first 
	if strcmp(CurrentEnumName, 'Info')
		if (iEnumName ~= 1)
			error(['The Info struct we created is at the wrong position, this needs investigation...'])
		end
		continue
	end
	% create the search names
	NumSearchStrings = length(DataHeaderPrefixList) * length(EnumKeyIgnoredSuffixList);
	SearchStringList = cell([1 NumSearchStrings]);
	MatchingEnumNameList = cell([1 NumSearchStrings]);
	SearchStringCounter = 0;
	for iDataPrefix = 1 : length(DataHeaderPrefixList)
		CurrentPrefix = DataHeaderPrefixList{iDataPrefix};
		
		CurrentSearchString = [CurrentPrefix, CurrentEnumName];
		for iEnumIgnoredSuffix = 1 : length(EnumKeyIgnoredSuffixList)
			CurrentIgnoredSuffix = EnumKeyIgnoredSuffixList{iEnumIgnoredSuffix};
			NumCharsInIgnoredSuffix = length(CurrentIgnoredSuffix);
			if strcmp(CurrentSearchString(end-NumCharsInIgnoredSuffix+1:end), CurrentIgnoredSuffix)
				CurrentSearchString = CurrentSearchString(1:end-NumCharsInIgnoredSuffix);
			end
			
			SearchStringCounter = SearchStringCounter + 1;
			MatchingEnumNameList{SearchStringCounter} = CurrentEnumName;
			SearchStringList{SearchStringCounter} = CurrentSearchString;
		end
	end	
	
	% now go and search the matching columns in the data_struct.header
	for iSearchString = 1 : NumSearchStrings
		CurrentSearchString = SearchStringList{iSearchString};
		% find the column
		CurrentColumnIdx = find(strcmp(CurrentSearchString, data_struct.header));
		
		if ~isempty(CurrentColumnIdx)		
			% create an matching _idx column (C# is zero based!) also add to
			% the column name struct
			NewDataColumnName = [data_struct.header{CurrentColumnIdx}, '_idx'];
			NewDataColumn = data_struct.data(:, CurrentColumnIdx) + 1; % Change from zero based index to matlab one based indexing
			
			data_struct = fn_handle_data_struct('add_columns', data_struct, NewDataColumn, {NewDataColumnName});
			
			%% add the column name to the header
			%data_struct.header{end+1} = NewDataColumnName;
			%% add the new data to the data table
			%data_struct.data(:,end+1) = NewDataColumn;
			%% add the column name to the column name structure
			%data_struct.cn.NewDataColumnName = length(data_struct.header);
		
			% add to the unique lists
			data_struct.unique_lists.NewDataColumnName = Enums_struct.(CurrentEnumName).unique_lists.(CurrentEnumName);
			
		end
		
	end	
end

return
end


function [ RewardPerTrialInfo_struct ] = fnExtractPerTrialRewardInfo( Reward_struct, NumTrials )
% create a table giving for each trial the numbers od TASK_HIT and MANUAL
% rewards per side, so or A and B

header = {'A_NumberRewardPulsesDelivered_HIT', 'B_NumberRewardPulsesDelivered_HIT', ...
		'A_NumberRewardPulsesDelivered_MANUAL', 'B_NumberRewardPulsesDelivered_MANUAL'};
cn.A_NumberRewardPulsesDelivered_HIT = 1;
cn.B_NumberRewardPulsesDelivered_HIT = 2;
cn.A_NumberRewardPulsesDelivered_MANUAL = 3;
cn.B_NumberRewardPulsesDelivered_MANUAL = 4;

CommonColumnFragmentString = 'NumberRewardPulsesDelivered';

% get the indices for Names A and B, since the Name_idx columns guarantee
% no sorting we have to dig in manually...
CodeA = find(strcmp(Reward_struct.unique_lists.Name, 'A'));
CodeB = find(strcmp(Reward_struct.unique_lists.Name, 'B'));
CodeHIT = find(strcmp(Reward_struct.unique_lists.RewardReasonString, 'TASK_HIT'));
CodeMANUAL = find(strcmp(Reward_struct.unique_lists.RewardReasonString, 'MANUAL'));



data = zeros([NumTrials, length(header)]);

for iTrial = 1 : NumTrials
	CurrentTrialNum = iTrial;
	
	CurrentTrialRewardLogIdx = find(Reward_struct.data(:, Reward_struct.cn.TrialNumber) == CurrentTrialNum);
	
	% there can be multiple reward log lines per trial so accumulate over
	% all of them
	for iMatchedTrial = 1 : length(CurrentTrialRewardLogIdx)
		CurrentRewardLogLineIdx = CurrentTrialRewardLogIdx(iMatchedTrial);
		
		ColPrefix = [];
		ColSufffix = [];
		
		if ~isempty(CodeA)
			if Reward_struct.data(CurrentRewardLogLineIdx, Reward_struct.cn.Name_idx) == CodeA;
				ColPrefix = 'A_';
			end
		end
		if ~isempty(CodeB)
			if Reward_struct.data(CurrentRewardLogLineIdx, Reward_struct.cn.Name_idx) == CodeB;
				ColPrefix = 'B_';
			end
		end
		
		if ~isempty(CodeHIT)
			if Reward_struct.data(CurrentRewardLogLineIdx, Reward_struct.cn.RewardReasonString_idx) == CodeHIT;
				ColSufffix = '_HIT';
			end
		end
		if ~isempty(CodeMANUAL)
			if Reward_struct.data(CurrentRewardLogLineIdx, Reward_struct.cn.RewardReasonString_idx) == CodeMANUAL;
				ColSufffix = '_MANUAL';
			end
		end
	
		if (~isempty(ColPrefix) && ~isempty(ColSufffix))
			CurrentNumPulsesDelivered = Reward_struct.data(CurrentRewardLogLineIdx, Reward_struct.cn.NumberRewardPulsesDelivered);
			tmp = data(CurrentTrialNum, cn.([ColPrefix, CommonColumnFragmentString, ColSufffix]));
			data(CurrentTrialNum, cn.([ColPrefix, CommonColumnFragmentString, ColSufffix])) = tmp + CurrentNumPulsesDelivered;
		end
	end
end

RewardPerTrialInfo_struct.header = header;
RewardPerTrialInfo_struct.cn = cn;
RewardPerTrialInfo_struct.data = data;

return
end