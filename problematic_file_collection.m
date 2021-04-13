function [ ] = problematic_file_collection( )
%PROBLEMATC_FILE_COLLECTION Summary of this function goes here
%   Detailed explanation goes here
% store problematic sessions here with a short description of the issue at
% hand and the current status (OPEN or FIXED)


% here the signallog's last line is incomplete and requires special care fnParseEventIDETrackerLog_v01 is modified to handle this 
% (FIXED)
% also issues with GLM_Coefficients parsing, seems to contain empty fields
% (FIXED)
fnLoadDataBySessionDir(fullfile('/Users/smoeller/DPZ/taskcontroller/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2020/201009','20201009T151508.A_Elmo.B_SM.SCP_01.sessiondir'));


% gaze calibration session, empty triallog, works
% (FIXED)
fnLoadDataBySessionDir(fullfile('/Users/smoeller/DPZ/taskcontroller/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2021/212005','20210205T151033.A_Elmo.B_None.SCP_01.sessiondir'));


% too few trials for the population analysis, fn_population_per_session_aggregates_per_trialsubset_wrapper failed to deal with essentially empty data 
% (FIXED)
session_dir = fullfile('/Volumes/taskcontroller$/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2021/210202', '20210202T154019.A_Elmo.B_DL.SCP_01.sessiondir');
triallog_struct = fnAnalyseIndividualSCPSession( fullfile(session_dir, '20210202T154019.A_Elmo.B_DL.SCP_01.triallog'), fullfile(session_dir, 'ANALYSIS'), 'SfN2008');


% gzip error in 20200722T145419.A_SM.B_Elmo.SCP_01.TID_NISignalFileWriterADC.signallog.txt; recopied data files. Seems to fix the problem 
% (FIXED)
fnLoadDataBySessionDir(fullfile('/space/data_local/moeller/DPZ/taskcontroller/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2020/200722','20200722T145419.A_SM.B_Elmo.SCP_01.sessiondir'));
% gzip error
session_dir = fullfile('/space/data_local/moeller/DPZ/taskcontroller/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2020/200716/20200716T143856.A_Elmo.B_SM.SCP_01.sessiondir');
fnLoadDataBySessionDir(session_dir);
% gzip errors probably simply caused by running out of disk space to store
% the unzipped data fully.


% short session, with "Unrecognized function or variable 'cur_corrected_time'." error in fnFixVisualChangeTimesFromPhotodiodeSignallog 
% the photodiode amplifier was probably shut off, no transitions were
% recorded..., fnFixVisualChangeTimesFromPhotodiodeSignallog did not deal
% well with files without meaningful transitions
% (FIXED)
session_dir = fullfile('/space/data_local/moeller/DPZ/taskcontroller/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2020/200720/', '20200720T140417.A_SM.B_Elmo.SCP_01.sessiondir');
fnLoadDataBySessionDir(session_dir);


% Index exceeds matrix dimensions.
% Error in fnFixEventIDEReportData>fnFixVisualChangeTimesFromPhotodiodeSignallog (line 205)
% (FIXED) contains no triggered PhotoDiode traces, detect that and skip
% timing correction for those files...
% the fix-up stage truncates the file (and introduces stray new lines)
% bash-3.2$ wc -l ./20200921T133850.A_Elmo.B_None.SCP_01.TID_EyeLinkTrackerA.trackerlog.txt -> 1632522 ./20200921T133850.A_Elmo.B_None.SCP_01.TID_EyeLinkTrackerA.trackerlog.txt
% bash-3.2$ wc -l ./20200921T133850.A_Elmo.B_None.SCP_01.TID_EyeLinkTrackerA.trackerlog.txt.Fixed.txt -> 45915 ./20200921T133850.A_Elmo.B_None.SCP_01.TID_EyeLinkTrackerA.trackerlog.txt.Fixed.txt
% after deleting
% 20200921T133850.A_Elmo.B_None.SCP_01.TID_EyeLinkTrackerA.trackerlog.txt.Fixed.*
% rerunning thing seems to have fixed the truncation issue issue
% wc -l ./20200921T133850.A_Elmo.B_None.SCP_01.TID_EyeLinkTrackerA.trackerlog.txt.Fixed.txt -> 1632522 ./20200921T133850.A_Elmo.B_None.SCP_01.TID_EyeLinkTrackerA.trackerlog.txt.Fixed.txt
% still puzzling the duplication of lines (FIXED)
session_dir = fullfile('/Volumes/taskcontroller$/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2020/200921', '20200921T133850.A_Elmo.B_None.SCP_01.sessiondir');
fnLoadDataBySessionDir(session_dir);


% fnLoadDataBySessionDir worked
session_dir = fullfile('/Volumes/taskcontroller$/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2020/200702/20200702T145053.A_Elmo.B_SM.SCP_01.sessiondir');
fnLoadDataBySessionDir(session_dir);
% fnAnalyseIndividualSCPSession, worked, no issue
triallog_struct = fnAnalyseIndividualSCPSession( fullfile(session_dir, '20200702T145053.A_Elmo.B_SM.SCP_01.triallog'), fullfile(session_dir, 'ANALYSIS'), 'SfN2008');


% fnFixEventIDEReportData: fixup_struct.add_trial_start_and_end_times, more ITIs than num_trial +1
% (FIXED)
session_dir = fullfile('/Volumes/taskcontroller$/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2020/200624/20200624T141830.A_Elmo.B_SM.SCP_01.sessiondir');
fnLoadDataBySessionDir(session_dir);
triallog_struct = fnAnalyseIndividualSCPSession( fullfile(session_dir, '20200624T141830.A_Elmo.B_SM.SCP_01.triallog'), fullfile(session_dir, 'ANALYSIS'), 'SfN2008');


%Reference to non-existent field 'A_GoSignalTime_ms'.
%Error in fnFixEventIDEReportData>fnFixVisualChangeTimesFromPhotodiodeSignallog (line 472)
% (FIXED)
session_dir = fullfile('/Volumes/taskcontroller$/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2020/200430/20200430T135317.A_Elmo.B_None.SCP_01.sessiondir');
triallog_struct = fnAnalyseIndividualSCPSession( fullfile(session_dir, '20200430T135317.A_Elmo.B_None.SCP_01.triallog'), fullfile(session_dir, 'ANALYSIS'), 'SfN2008');
fnLoadDataBySessionDir(session_dir);

% Reference to non-existent field 'Timestamp'.
% Error in fnFixEventIDEReportData>fnFixVisualChangeTimesFromPhotodiodeSignallog (line 452)
% (FIXED)
session_dir = fullfile('/Volumes/taskcontroller$/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2020/200417/20200417T135845.A_Elmo.B_None.SCP_01.sessiondir');
triallog_struct = fnAnalyseIndividualSCPSession( fullfile(session_dir, '20200417T135845.A_Elmo.B_None.SCP_01.triallog'), fullfile(session_dir, 'ANALYSIS'), 'SfN2008');

% Reference to non-existent field 'cn'.
% Error in fnFixEventIDEReportData>fnFixVisualChangeTimesFromPhotodiodeSignallog (line 332)
% (FIXED)
session_dir = fullfile('/Volumes/taskcontroller$/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2020/200416/20200416T170220.A_Elmo.B_None.SCP_01.sessiondir');
triallog_struct = fnAnalyseIndividualSCPSession( fullfile(session_dir, '20200416T170220.A_Elmo.B_None.SCP_01.triallog'), fullfile(session_dir, 'ANALYSIS'), 'SfN2008');


% 911             error(['The ', RecordTypeHint, '-type data record does not match the length of the respective types list, investigate \n ', current_line]);
% In fnParseEventIDEReportSCPv06>fnParseHeaderTypeDataRecord (line 911)
% (FIXED)
session_dir = fullfile('/Volumes/taskcontroller$/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2020/200213/20200213T132429.A_Elmo.B_SM.SCP_01.sessiondir');
triallog_struct = fnAnalyseIndividualSCPSession( fullfile(session_dir, '20200213T132429.A_Elmo.B_SM.SCP_01.triallog'), fullfile(session_dir, 'ANALYSIS'), 'SfN2008');





% Undefined function or variable 'DataStruct'.
% Error in fnAnalyseIndividualSCPSession (line 83)
% TrialSets = fnCollectTrialSets(DataStruct);
% (TODO)
session_dir = fullfile('/Volumes/taskcontroller$/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2018/180103/20180103T071337.A_None.B_Elmo.SCP_01.sessiondir');
triallog_struct = fnAnalyseIndividualSCPSession( fullfile(session_dir, '20180103T071337.A_None.B_Elmo.SCP_01.triallog'), fullfile(session_dir, 'ANALYSIS'), 'SfN2008');

session_dir = fullfile('/Volumes/taskcontroller$/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2021/210212/20210212T153711.A_Elmo.B_DL.SCP_01.sessiondir');
triallog_struct = fnAnalyseIndividualSCPSession( fullfile(session_dir, '20210212T153711.A_Elmo.B_DL.SCP_01.triallog'), fullfile(session_dir, 'ANALYSIS'), 'SfN2008');

session_dir = fullfile('/Volumes/taskcontroller$/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2018/180103/20180103T071337.A_None.B_Elmo.SCP_01.sessiondir');
triallog_struct = fnAnalyseIndividualSCPSession( fullfile(session_dir, '20180103T071337.A_None.B_Elmo.SCP_01.triallog'), fullfile(session_dir, 'ANALYSIS'), 'SfN2008');


% this was trying to search before the first SessionRecord to generate the
% SessionDataByTrial table and failed.
session_dir = fullfile('/Volumes/taskcontroller$/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2020/200115/20200115T150823.A_SM.B_Curius.SCP_01.sessiondir'); 
triallog_struct = fnAnalyseIndividualSCPSession( fullfile(session_dir, '20200115T150823.A_SM.B_Curius.SCP_01.triallog'), fullfile(session_dir, 'ANALYSIS'), 'SfN2008');


session_dir = fullfile('/Volumes/taskcontroller$/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2017/170315/20170315T175822.A_Curius.B_Igor.SCP_01.sessiondir'); 
triallog_struct = fnAnalyseIndividualSCPSession( fullfile(session_dir, '20170315T175822.A_Curius.B_Igor.SCP_01.triallog'), fullfile(session_dir, 'ANALYSIS'), 'SfN2008');


% empty triall log without a single valid trial
session_dir = fullfile('/Volumes/taskcontroller$/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2021/210412/20210412T135618.A_Elmo.B_None.SCP_01.sessiondir'); 
triallog_struct = fnAnalyseIndividualSCPSession( fullfile(session_dir, '20210412T135618.A_Elmo.B_None.SCP_01.triallog'), fullfile(session_dir, 'ANALYSIS'), 'SfN2008');
fnLoadDataBySessionDir(fullfile('/Volumes/taskcontroller$/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2021/210412','20210412T135618.A_Elmo.B_None.SCP_01.sessiondir'));

% BAD: no TrialType record, failed in fnCollectTrialSets.m
session_dir = fullfile('/Volumes/taskcontroller$/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2017/170314/20170314T120641.A_Sebastian.B_Iryna.SCP_01.sessiondir'); 
triallog_struct = fnAnalyseIndividualSCPSession( fullfile(session_dir, '20170314T120641.A_Sebastian.B_Iryna.SCP_01.triallog'), fullfile(session_dir, 'ANALYSIS'), 'SfN2008');
% GOOD: TrialTYpe record exists, no issues
session_dir = fullfile('/Volumes/taskcontroller$/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2017/170315/20170315T160814.A_None.B_StefanTreue.SCP_01.sessiondir'); 
triallog_struct = fnAnalyseIndividualSCPSession( fullfile(session_dir, '20170315T160814.A_None.B_StefanTreue.SCP_01.triallog'), fullfile(session_dir, 'ANALYSIS'), 'SfN2008');


session_dir = fullfile('/Volumes/taskcontroller$/SCP_DATA/SCP-CTRL-01/SESSIONLOGS/2017/170314/20170314T115957.A_Sebastian.B_Iryna.SCP_01.sessiondir'); 
triallog_struct = fnAnalyseIndividualSCPSession( fullfile(session_dir, '20170314T115957.A_Sebastian.B_Iryna.SCP_01.triallog'), fullfile(session_dir, 'ANALYSIS'), 'SfN2008');



end

