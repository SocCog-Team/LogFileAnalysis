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
session_info.YYYYMMDD_string = [session_info.year_string(1:4), session_info.month_string, session_info.day_string];
session_info.HHmmSS_string = tmp_T_time(2:end);

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

% the full session_id just in case
session_info.session_id = session_id;

[~, session_info.species_A] = fn_is_NHP(session_info.subject_A);
[~, session_info.species_B] = fn_is_NHP(session_info.subject_B);

return
end