function [ output_args ] = fnTestTrakerLogParsing( input_args )
%FNTESTTRAKERLOGPARSING Summary of this function goes here
%   Detailed explanation goes here



forced_header_string = ['EventIDE TimeStamp;Gaze X;Gaze Y;Gaze Theta;Gaze R;Gaze CX;Gaze CY;Gaze CVX;Gaze CVY;Gaze Validity;Current Event;GLM Coefficients;', ...
                        'Tracker Time Stamp;Left Eye Raw X;Left Eye Raw Y;Left Eye Pupil Size;Left Eye Pupil Center X;Left Eye Pupil Center Y;', ...
                        'Right Eye Raw X;Right Eye Raw Y;Right Eye Pupil Size;Right Eye Pupil Center X;Right Eye Pupil Center Y;Binocular Raw X;Binocular Raw Y;', ...
                        'HEADREF Angular Left Eye X;HEADREF Angular Left Eye Y;HEADREF Angular Right Eye X;HEADREF Angular Right Eye Y;', ...
                        'group;block;trial;User Field;EMPTY;'];


TrackerLog_FQN = fullfile('/', 'Volumes', 'social_neuroscience_data', 'taskcontroller', 'Projekts', 'Primatar', 'PrimatarData', 'Session_on_30-8--14-22', 'TrackerLog--EyeLink--2018-30-08--14-23.txt');


%/Volumes/social_neuroscience_data/taskcontroller/Projekts/Primatar/PrimatarData/Session_on_30-8--14-22
%TrackerLog--EyeLink--2018-30-08--14-23.txt
column_separator = ';';
force_number_of_columns = [];

[ data_struct ] = fnParseEventIDETrackerLog_v01(TrackerLog_FQN, column_separator, force_number_of_columns, forced_header_string);

return
end

