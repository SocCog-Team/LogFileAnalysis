function [ output_args ] = Test_fnParseEventIDEReportSCP( input_args )
%TEST_FNPARSEEVENTIDEREPORTSCP Summary of this function goes here
%   Detailed explanation goes here
% The idea is to collect parser invocations that exercise specific
% capabilities to easily test for regressions


% ready this for unix systems...
[sys_status, host_name] = system('hostname');
switch host_name(1:end-1) % last char of host name result is ascii 10 (LF)
	case {'hms-beagle2', 'hms-beagle2.local', 'hms-beagle2.lan'}
		if isdir('/Volumes/social_neuroscience_data/taskcontroller')
			% remote data repository
			BaseDir = fullfile('/', 'Volumes', 'social_neuroscience_data', 'taskcontroller');
		else
			% local data copy
			disp('SCP data server share not mounted, falling back to local copy...');
			BaseDir = fullfile('/', 'space', 'data_local', 'moeller', 'DPZ', 'taskcontroller');
		end
	case 'SCP-CTRL-00'
		BaseDir = fullfile('Z:', 'taskcontroller');
	case 'SCP-CTRL-01'
		BaseDir = fullfile('Z:', 'taskcontroller');
    case 'SCP-VIDEO-01-A'
		BaseDir = fullfile('Z:', 'taskcontroller');
	case 'SCP-VIDEO-01-B'
		BaseDir = fullfile('Z:', 'taskcontroller');
	otherwise
		error(['Hostname ', host_name(1:end-1), ' not handeled yet']);
end


% % % example without reward logging A and B, without *TYPE records, so this
% % exercises the default type assignment, also this contains REWARD records
% % without an explicit REWARDHEADER, tests REWARDHEADER synthesis
% tmp_data = fnParseEventIDEReportSCPv06( fullfile(BaseDir, 'SCP-CTRL-01', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', ...
%  	'20170315', '20170315T175822.A_Curius.B_Igor.SCP_01.log'));
% 
% 
% % % example with reward logging only B
% tmp_data = fnParseEventIDEReportSCPv06( fullfile(BaseDir, 'SCP-CTRL-01', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', ...
%  	'20170505', '20170505T123712.A_None.B_Test.SCP_01.log'));
% 
% 
% % example with reward logging A and B, human human BoS type game
% tmp_data = fnParseEventIDEReportSCPv06( fullfile(BaseDir, 'SCP-CTRL-00', 'SCP_DATA', 'SCP-CTRL-00', 'SESSIONLOGS', ...
% 	'20170425', '20170425T160951.A_21001.B_22002.SCP_00.log'));
% 
% 
% % example with stimulus position logging
% tmp_data = fnParseEventIDEReportSCPv06( fullfile(BaseDir, 'SCP-CTRL-01', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', ...
% % 	'20170519', '20170519T115737.A_TestPositionalElementsReporting6.B_None.SCP_01', '20170519T115737.A_TestPositionalElementsReporting6.B_None.SCP_01.log'));
% 
% 
% % 2 Human subjects with REWARD and STIMULUS record types
% tmp_data = fnParseEventIDEReportSCPv06( fullfile(BaseDir, 'SCP-CTRL-01', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', ...
% 	'20170519', '20170519T130613.A_Daniela.B_Sebastian.SCP_01', '20170519T130613.A_Daniela.B_Sebastian.SCP_01.log'));

% % 2 NHP subjects with REWARD and STIMULUS record types
% tmp_data = fnParseEventIDEReportSCPv06( fullfile(BaseDir, 'SCP-CTRL-01', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', ...
%  	'20170519', '20170519T141401.A_Magnus.B_Curius.SCP_01', '20170519T141401.A_Magnus.B_Curius.SCP_01.log'));

% % example with arrington tracker and overloaded UserField (string)
% TrackerLog_FQN = '/space/data_local/moeller/DPZ/taskcontroller/DAG-3/PrimatarData/Cornelius_20170714_1250/TrackerLog--ArringtonTracker--2017-14-07--12-50.txt';
% tmp_data = fnParseEventIDETrackerLog_v01(TrackerLog_FQN );

% % german language setting file with comma as decimal separator
% tmp_data = fnParseEventIDETrackerLog_v01( fullfile(BaseDir, 'SCP-CTRL-01', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', ...
%  	'20170707', '20170707T111529.A_Magnus.B_None.SCP_01', '20170707T111529.A_Magnus.B_None.SCP_01_TrackerLogs', 'TrackerLog--EyeLinkProxyTrackerA--2017-07-07--11-16.txt'));


% german language setting file with comma as decimal separator
tmp_data = fnParseEventIDEReportSCPv06( fullfile(BaseDir, 'SCP-CTRL-01', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', ...
 	'20170707', '20170707T111529.A_Magnus.B_None.SCP_01', '20170707T111529.A_Magnus.B_None.SCP_01.log'));


end