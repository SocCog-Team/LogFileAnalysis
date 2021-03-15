function [ 	ByTrial_struct ] = fnConvertTimestampedChangeDataToByTrialData2(TimestampedChanges_struct, NameString, TimestampList, TrialNumberList)
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

% n_ts = length(TimestampList);
% n_session_records = size(TimestampedChanges_struct.data, 1);
% session_record_offset = 1;
% for i_ts = 1 : n_ts
% 	cur_TimestampList_ts = TimestampList(i_ts);
% 
% 	% session record information
% 	cur_session_record_ts = TimestampedChanges_struct.data(session_record_offset, TimestampedChanges_struct.cn.Timestamp);
% 	if session_record_offset < size(n_session_records)
% 		next_session_record_ts =  TimestampedChanges_struct.data(session_record_offset + 1, TimestampedChanges_struct.cn.Timestamp);
% 	else
% 		% enforce this, so (cur_trial_start_ts < next_session_record_ts) is true for the last
% 		next_session_record_ts = TimestampList(end) + 1;
% 	end
% 
% 	
% 	if (cur_trial_start_ts >= cur_session_ts) && (cur_trial_start_ts < next_session_record_ts)
% 		ByTrial_struct.data(i_ts,3:end) = TimestampedChanges_struct.data(session_record_offset, :);
% 		
% 	end
% 	
% end

TimestampList_offset = TrialOffset;
for iSessionRecord = size(TimestampedChanges_struct.data, 1) : -1 : 1
    CurrentSessionRecordTS = TimestampedChanges_struct.data(iSessionRecord, TimestampedChanges_struct.cn.Timestamp);
	LastTrialTS = TimestampList(TrialOffset);
	
	% find the earliest CurrentSessionRecordTS still >= LastTrialTS and use
	% that to assign values
	while (TimestampedChanges_struct.data(iSessionRecord, TimestampedChanges_struct.cn.Timestamp) >= LastTrialTS)
		iSessionRecord = iSessionRecord -1;
		CurrentSessionRecordTS = TimestampedChanges_struct.data(iSessionRecord, TimestampedChanges_struct.cn.Timestamp);
	end
	
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
            TrialOffset = iTrial;
            break
        end
	end
	% reached the end of the for loop, so all trials are assigned
	% break out of the iSessionRecord loop
	break
end

%ByTrial_struct.cn = local_get_column_name_indices(ByTrial_struct.header);

return
end

