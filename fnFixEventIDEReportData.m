function [ output_struct ] = fnFixEventIDEReportData( input_struct )
%FNFIXEVENTIDEREPORTDATA Specific corrections of EventIDE report files
%   Detailed explanation goes here
output_struct = input_struct;
output_struct.FixUpReport = {};

% robustly estimate the session date
if isfield(input_struct.LoggingInfo, 'SessionDate')
    date_num = str2double(input_struct.LoggingInfo.SessionDate);
elseif isfield(input_struct.EventIDEinfo, 'DateVector')
    tmp_DateVector = input_struct.EventIDEinfo.DateVector;
    date_num = tmp_DateVector(1) * 10000+ tmp_DateVector(2) * 100 +tmp_DateVector(3) * 1;
end


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

ouput_struct.FixUpReport{end+1} = 'Fixed spradically wrong TrialType assignments using the stimuli struct';
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