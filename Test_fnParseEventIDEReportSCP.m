function [ output_args ] = Test_fnParseEventIDEReportSCP( input_args )
%TEST_FNPARSEEVENTIDEREPORTSCP Summary of this function goes here
%   Detailed explanation goes here

BaseDir = fullfile('/', 'space', 'data_local', 'moeller', 'DPZ', 'taskcontroller');


% % example without reward logging A and B, without *TYPE records, so this
% exercises the default type assignment, also this contains REWARD records
% without an explicit REWARDHEADER, tests REWARDHEADER synthesis
tmp_data = fnParseEventIDEReportSCPv06( fullfile(BaseDir, 'SCP-CTRL-01', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', ...
 	'20170315', '20170315T175822.A_Curius.B_Igor.SCP_01.log'));


% % example with reward logging only B
tmp_data = fnParseEventIDEReportSCPv06( fullfile(BaseDir, 'SCP-CTRL-01', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', ...
 	'20170505', '20170505T123712.A_None.B_Test.SCP_01.log'));


% example with reward logging A and B, human human BoS type game
tmp_data = fnParseEventIDEReportSCPv06( fullfile(BaseDir, 'SCP-CTRL-00', 'SCP_DATA', 'SCP-CTRL-00', 'SESSIONLOGS', ...
	'20170425', '20170425T160951.A_21001.B_22002.SCP_00.log'));



end