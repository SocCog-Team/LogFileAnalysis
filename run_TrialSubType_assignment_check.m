% run_TrialSubType_assignment_check
%
% Feed a list of session directories, force re-parse each triallog, and
% write one CSV file per session with selected FixUpReport lines.
% If a session has no matching FixUpReport lines, an empty CSV file is created.
% Also writes one combined CSV across all sessions.
%
% Output directory:
%   C:\SCP_CODE\LogFileAnalysis\TrialSubType_assignment_check

timestamps.(mfilename).start = tic;
disp(['Starting: ', mfilename]);
dbstop if error
fq_mfilename = mfilename('fullpath');
[mfilepath, mfilename_name] = fileparts(fq_mfilename);

% in case of pure sessiondir names like '20210423T105645.A_Elmo.B_KN.SCP_01.sessiondir'
% use this as base for generating the FQN
base_SESSIONLOGS_dir = fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS');
if ~(ispc)
	base_SESSIONLOGS_dir = fullfile('/', base_SESSIONLOGS_dir);	% this works as I added Y: to the root directory... but we still need the leading root.
end


%% User input: session list
% Replace this with your own list, e.g. the spike_sorted_session_ID_list.
% spike_sorted_session_ID_list sorted on ascending date time
spike_sorted_session_ID_list = {...
	...%fullfile('F:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2020', '201218', '20201218T130348.A_Elmo.B_FS.SCP_01.sessiondir'), ...			% Elmo  : SoloA, Dyadic(BLOCKED), SoloBRewardAB(PASSIVE);
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2020', '201218', '20201218T130348.A_Elmo.B_FS.SCP_01.sessiondir'), ...		% Elmo  : SoloA, Dyadic(BLOCKED), SoloBRewardAB(PASSIVE);
	...%fullfile('G:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2021', '210127', '20210127T130717.A_Elmo.B_FS.SCP_01.sessiondir'), ...			% Elmo  : SoloA, Dyadic(BLOCKED), DyadicBlockedView(BLOCKED);
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2021', '210127', '20210127T130717.A_Elmo.B_FS.SCP_01.sessiondir'), ...		% Elmo  : SoloA, Dyadic(BLOCKED), DyadicBlockedView(BLOCKED);
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2021', '210129', '20210129T150949.A_Elmo.B_FS.SCP_01.sessiondir'), ...		% Elmo  : SoloA, Dyadic(BLOCKED), DyadicBlockedView(BLOCKED);
	...%fullfile('G:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2021', '210205', '20210205T151709.A_Elmo.B_DL.SCP_01.sessiondir'), ...			% Elmo  : SoloA, Dyadic(SHUFFLED); Shuffled only
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2021', '210205', '20210205T151709.A_Elmo.B_DL.SCP_01.sessiondir'), ...		% Elmo  : SoloA, Dyadic(SHUFFLED); Shuffled only
	...%fullfile('D:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2021', '210219', '20210219T145809.A_Elmo.B_DL.SCP_01.sessiondir'), ...			% Elmo  : SoloA, Dyadic(BLOCKED/SHUFFLED); Shuffled/Blocked
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2021', '210219', '20210219T145809.A_Elmo.B_DL.SCP_01.sessiondir'), ...		% Elmo  : SoloA, Dyadic(BLOCKED/SHUFFLED); Shuffled/Blocked
	...%fullfile('F:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2021', '210416', '20210416T105525.A_Elmo.B_KN.SCP_01.sessiondir'), ...		% SemiSolo
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2021', '210416', '20210416T105525.A_Elmo.B_KN.SCP_01.sessiondir'), ...		% Elmo  : SoloA, Dyadic(BLOCKED), SemiSolo(BLOCKED);
	...%fullfile('E:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2021', '210423', '20210423T105645.A_Elmo.B_KN.SCP_01.sessiondir'), ...			% Elmo  : SoloA, Dyadic(BLOCKED), SemiSolo(BLOCKED);
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2021', '210423', '20210423T105645.A_Elmo.B_KN.SCP_01.sessiondir'), ...		% Elmo  : SoloA, Dyadic(BLOCKED), SemiSolo(BLOCKED);
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2021', '210625', '20210625T141512.A_Elmo.B_KN.SCP_01.sessiondir'), ...		% Elmo  : SoloA, Dyadic(SHUFFLED), SemiSolo(SHUFFLED); Santiago
	...%fullfile('D:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2021', '211006', '20211006T143535.A_Elmo.B_None.SCP_01.sessiondir'), ...			% Elmo  : SoloA; SoloA only.... electrode check...
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2021', '211006', '20211006T143535.A_Elmo.B_None.SCP_01.sessiondir'), ...		% Elmo  : SoloA; SoloA only.... electrode check...
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2023', '230406', '20230406T152452.A_Curius.B_AE.SCP_01.sessiondir'), ...		% Curius: SoloA, Dyadic(BLOCKED); 4 Arrays only
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2023', '230504', '20230504T131733.A_Curius.B_AE.SCP_01.sessiondir'), ...		% Curius: SoloA, Dyadic(BLOCKED); SantiagoTDT\SCP_DAG_v20_PZ504-230504-131718
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2023', '230525', '20230525T103049.A_Curius.B_SM.SCP_01.sessiondir'), ...		% Curius: SoloA, Dyadic(BLOCKED), DyadicBlockedView(BLOCKED); Santiago xsession_show_cycle_spatial_trajectories
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2023', '230607', '20230607T115959.A_Curius.B_VC.SCP_01.sessiondir'), ...		% Curius: SoloA, Dyadic(SHUFFLED); Shuffled only SantiagoTDT\SCP_DAG_v25_PZ504-230607-115927
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2023', '230616', '20230616T094811.A_Curius.B_VC.SCP_01.sessiondir'), ...		% Curius: Dyadic(SHUFFLED), SoloBRewardAB(PASSIVE);
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2023', '230623', '20230623T124557.A_Curius.B_Elmo.SCP_01.sessiondir'), ...	% Curius: Dyadic(DUAL_NHP), SoloARewardAB(ACTIVE), SoloBRewardAB(PASSIVE);
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2023', '230623', '20230623T124557U.A_Curius.B_Elmo.SCP_01.sessiondir'), ...	% Curius: Dyadic(DUAL_NHP), SoloARewardAB(ACTIVE), SoloBRewardAB(PASSIVE); SM: Re sorted with ultrasort, for comaprison with 20230623T124557.A_Curius.B_Elmo.SCP_01.sessiondir
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2023', '230623', '20230623T124557B.A_Curius.B_Elmo.SCP_01.sessiondir'), ...	% Elmo  : Dyadic(DUAL_NHP), SoloARewardAB(PASSIVE), SoloBRewardAB(ACTIVE); SoloXRewardAB
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2023', '230630', '20230630T115937.A_Curius.B_Elmo.SCP_01.sessiondir'),...		% Curius: Dyadic(DUAL_NHP), SoloARewardAB(ACTIVE)
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2023', '230630', '20230630T115937B.A_Curius.B_Elmo.SCP_01.sessiondir'),...		% Elmo  : Dyadic(DUAL_NHP), SoloARewardAB(PASSIVE)
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2023', '230703', '20230703T122644.A_Curius.B_MK.SCP_01.sessiondir'), ...		% Curius: SoloA, Dyadic(BLOCKED/SHUFFLED); SantiagoTDT\SCP_DAG_v26_PZ504-230703-122611	
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2023', '230704', '20230704T130229.A_Curius.B_Elmo.SCP_01.sessiondir'), ...	% Curius: SoloA, Dyadic(DUAL_NHP); Santiago
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2023', '230704', '20230704T130229B.A_Curius.B_Elmo.SCP_01.sessiondir'), ...	% Elmo  : SoloB, Dyadic(DUAL_NHP); SantiagoTDT\SCP_DAG_v26_2x160-230704-130151_Elmo
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2023', '230705', '20230705T134053.A_Curius.B_RS.SCP_01.sessiondir'), ...		% Curius: SoloA, SemiSolo(BLOCKED/SHUFFLED); SemiSolo blocked/shuffled
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2023', '230707', '20230707T102457.A_Curius.B_Elmo.SCP_01.sessiondir'),...		% Curius: Dyadic(DUAL_NHP), SoloARewardAB(ACTIVE)
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2023', '230707', '20230707T102457B.A_Curius.B_Elmo.SCP_01.sessiondir'),...		% Elmo  : Dyadic(DUAL_NHP), SoloARewardAB(PASSIVE)
	};


Curius_BLOCKED_CONF_top_10 = {...
	'20230330T133602.A_Curius.B_AE.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10
	'20230413T142422.A_Curius.B_AE.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10
	'20230505T123505.A_Curius.B_AE.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10
	'20230509T130346.A_Curius.B_SM.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10
	'20230511T142916.A_Curius.B_SM.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10
	'20230518T135808.A_Curius.B_SM.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10
	'20230523T145755.A_Curius.B_SM.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10
	'20230525T103049.A_Curius.B_SM.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10
	'20230622T111856.A_Curius.B_SM.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10 DOUBLE
	'20230703T122644.A_Curius.B_MK.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10 DOUBLE
	};
% wrong sort order
Curius_BLOCKED_CONF_top_10_wrong = {...
	... %'20230330T133602.A_Curius.B_AE.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10
	'20230412T143018.A_Curius.B_AE.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10
	... %'20230509T130346.A_Curius.B_SM.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10
	'20230517T130621.A_Curius.B_RB.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10
	... %'20230525T103049.A_Curius.B_SM.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10
	'20230526T102829.A_Curius.B_SM.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10
	'20230620T101238.A_Curius.B_VC.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10
	... %'20230622T111856.A_Curius.B_SM.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10
	'20230627T094057.A_Curius.B_MK.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10
	... %'20230703T122644.A_Curius.B_MK.SCP_01.sessiondir', ... % Curius_BLOCKED_CONF_top_10
	};

% all with >= 195 hit trials and agoB_SaME_pct >= 66%
% commented out sessions already processed
Curius_BLOCKED_CONF = {...
...	'20230330T133602.A_Curius.B_AE.SCP_01', ... % Curius_BLOCKED_CONF_top_10
...	'20230331T131059.A_Curius.B_AE.SCP_01', ... % 
...	'20230404T150951.A_Curius.B_AE.SCP_01', ... % 
...	'20230405T145014.A_Curius.B_AE.SCP_01', ... % 
...	'20230412T143018.A_Curius.B_AE.SCP_01', ... % 
...	'20230413T142422.A_Curius.B_AE.SCP_01', ... % Curius_BLOCKED_CONF_top_10
...	'20230504T131733.A_Curius.B_AE.SCP_01', ... % spike_sorted: Curius: SoloA, Dyadic(BLOCKED); SantiagoTDT\SCP_DAG_v20_PZ504-230504-131718
...	'20230505T123505.A_Curius.B_AE.SCP_01', ... % Curius_BLOCKED_CONF_top_10
...	'20230509T130346.A_Curius.B_SM.SCP_01', ... % Curius_BLOCKED_CONF_top_10
...	'20230510T144106.A_Curius.B_SM.SCP_01', ... % 
...	'20230511T142916.A_Curius.B_SM.SCP_01', ... % Curius_BLOCKED_CONF_top_10
...	'20230512T125943.A_Curius.B_SM.SCP_01', ... % 
...	'20230516T133503.A_Curius.B_RB.SCP_01', ... % 
...	'20230517T130621.A_Curius.B_RB.SCP_01', ... % 
...	'20230518T135808.A_Curius.B_SM.SCP_01', ... % Curius_BLOCKED_CONF_top_10
...	'20230523T145755.A_Curius.B_SM.SCP_01', ... % Curius_BLOCKED_CONF_top_10
...	'20230525T103049.A_Curius.B_SM.SCP_01', ... % Curius_BLOCKED_CONF_top_10
	'20230620T101238.A_Curius.B_VC.SCP_01' ...
...	'20230621T100721.A_Curius.B_MK.SCP_01', ... % 
...	'20230622T111856.A_Curius.B_SM.SCP_01', ... % Curius_BLOCKED_CONF_top_10 DOUBLE
...	'20230628T101631.A_Curius.B_VC.SCP_01', ... % 
...	'20230703T122644.A_Curius.B_MK.SCP_01', ... % Curius_BLOCKED_CONF_top_10 DOUBLE
	};


Curius_SHUFFLED_CONF_top_10 = {...
	'20230607T115959.A_Curius.B_VC.SCP_01.sessiondir', ... % Curius_SHUFFLED_CONF_top_10 TDT Matlab SDK issue, updated SDK
	'20230609T101610.A_Curius.B_VC.SCP_01.sessiondir', ... % Curius_SHUFFLED_CONF_top_10
	'20230614T114327.A_Curius.B_VC.SCP_01.sessiondir', ... % Curius_SHUFFLED_CONF_top_10
	'20230619T102732.A_Curius.B_VC.SCP_01.sessiondir', ... % Curius_SHUFFLED_CONF_top_10
	'20230620T101238.A_Curius.B_VC.SCP_01.sessiondir', ... % Curius_SHUFFLED_CONF_top_10
	'20230621T100721.A_Curius.B_MK.SCP_01.sessiondir', ... % Curius_SHUFFLED_CONF_top_10
	'20230622T111856.A_Curius.B_SM.SCP_01.sessiondir', ... % Curius_SHUFFLED_CONF_top_10 DOUBLE Curius showed prediction with blocked and no prediction with shuffled partner
	'20230628T101631.A_Curius.B_VC.SCP_01.sessiondir', ... % Curius_SHUFFLED_CONF_top_10
	'20230629T100435.A_Curius.B_VC.SCP_01.sessiondir', ... % Curius_SHUFFLED_CONF_top_10
	'20230703T122644.A_Curius.B_MK.SCP_01.sessiondir', ... % Curius_SHUFFLED_CONF_top_10 DOUBLE Curius showed prediction with blocked and no prediction&side bias with shuffled partner, spike_sorted: Curius: SoloA, Dyadic(BLOCKED/SHUFFLED); SantiagoTDT\SCP_DAG_v26_PZ504-230703-122611	
	};
Curius_SHUFFLED_CONF_top_10_wrong = {...
	... %'20230609T101610.A_Curius.B_VC.SCP_01.sessiondir', ...
	'20230616T094811.A_Curius.B_VC.SCP_01.sessiondir', ...
	... %'20230619T102732.A_Curius.B_VC.SCP_01.sessiondir', ...
	... %'20230620T101238.A_Curius.B_VC.SCP_01.sessiondir', ... % DOUBLE
	... %'20230621T100721.A_Curius.B_MK.SCP_01.sessiondir', ...
	... %'20230622T111856.A_Curius.B_SM.SCP_01.sessiondir', ... % DOUBLE
	'20230627T094057.A_Curius.B_MK.SCP_01.sessiondir', ... % DOUBLE
	... %'20230628T101631.A_Curius.B_VC.SCP_01.sessiondir', ... % no PupilLabs.trackerlog data for A.Curius..., fist TDT tank is super small, just take 2nd tank
	... %'20230629T100435.A_Curius.B_VC.SCP_01.sessiondir', ...
	... %'20230703T122644.A_Curius.B_MK.SCP_01.sessiondir', ... % DOUBLE
	};

Curius_SHUFFLED_CONF = {...
	'20230329T134429.A_Curius.B_None.SCP_01', ... %
...	'20230607T115959.A_Curius.B_VC.SCP_01', ... % Curius_SHUFFLED_CONF_top_10
	'20230608T102315.A_Curius.B_VC.SCP_01', ... %
...	'20230609T101610.A_Curius.B_VC.SCP_01', ... % Curius_SHUFFLED_CONF_top_10
	'20230613T104336.A_Curius.B_VC.SCP_01', ... %
...	'20230614T114327.A_Curius.B_VC.SCP_01', ... % Curius_SHUFFLED_CONF_top_10
	'20230615T122340.A_Curius.B_VC.SCP_01', ... %
...	'20230616T094811.A_Curius.B_VC.SCP_01', ... % spike_sorterd: Curius: Dyadic(SHUFFLED), SoloBRewardAB(PASSIVE);
...	'20230619T102732.A_Curius.B_VC.SCP_01', ... % Curius_SHUFFLED_CONF_top_10
...	'20230620T101238.A_Curius.B_VC.SCP_01', ... % Curius_SHUFFLED_CONF_top_10
...	'20230621T100721.A_Curius.B_MK.SCP_01', ... % Curius_SHUFFLED_CONF_top_10
...	'20230622T111856.A_Curius.B_SM.SCP_01', ... % Curius_SHUFFLED_CONF_top_10 DOUBLE Curius showed prediction with blocked and no prediction with shuffled partner
	'20230627T094057.A_Curius.B_MK.SCP_01', ... %
...	'20230628T101631.A_Curius.B_VC.SCP_01', ... % Curius_SHUFFLED_CONF_top_10
...	'20230629T100435.A_Curius.B_VC.SCP_01', ... % Curius_SHUFFLED_CONF_top_10
...	'20230703T122644.A_Curius.B_MK.SCP_01', ... % Curius_SHUFFLED_CONF_top_10 DOUBLE Curius showed prediction with blocked and no prediction&side bias with shuffled partner, spike_sorted: Curius: SoloA, Dyadic(BLOCKED/SHUFFLED); SantiagoTDT\SCP_DAG_v26_PZ504-230703-122611	
	};

Elmo_BLOCKED_CONF_top_10 = {...
	'20210401T124246.A_Elmo.B_KN.SCP_01.sessiondir', ... % Elmo_BLOCKED_CONF_top_10
	'20210416T105525.A_Elmo.B_KN.SCP_01.sessiondir', ... % Elmo_BLOCKED_CONF_top_10
	'20210423T105645.A_Elmo.B_KN.SCP_01.sessiondir', ... % Elmo_BLOCKED_CONF_top_10
	'20210520T120659.A_Elmo.B_KN.SCP_01.sessiondir', ... % Elmo_BLOCKED_CONF_top_10
	'20210604T143542.A_Elmo.B_KN.SCP_01.sessiondir', ... % Elmo_BLOCKED_CONF_top_10
	'20210708T131736.A_Elmo.B_KN.SCP_01.sessiondir', ... % Elmo_BLOCKED_CONF_top_10
	'20210709T103307.A_Elmo.B_ST.SCP_01.sessiondir', ... % Elmo_BLOCKED_CONF_top_10
	'20210715T105108.A_Elmo.B_ST.SCP_01.sessiondir', ... % Elmo_BLOCKED_CONF_top_10
	'20210716T103652.A_Elmo.B_KN.SCP_01.sessiondir', ... % Elmo_BLOCKED_CONF_top_10
	'20210828T135335.A_Elmo.B_KN.SCP_01.sessiondir', ... % Elmo_BLOCKED_CONF_top_10
	};
Elmo_BLOCKED_CONF_top_10_wrong = {...
	... %'20210401T124246.A_Elmo.B_KN.SCP_01.sessiondir', ...
	... %'20210416T105525.A_Elmo.B_KN.SCP_01.sessiondir', ...
	... %'20210520T120659.A_Elmo.B_KN.SCP_01.sessiondir', ...
	... %'20210604T143542.A_Elmo.B_KN.SCP_01.sessiondir', ...
	'20210608T131158.A_Elmo.B_KN.SCP_01.sessiondir', ...
	'20210616T124854.A_Elmo.B_ST.SCP_01.sessiondir', ...
	... %'20210708T131736.A_Elmo.B_KN.SCP_01.sessiondir', ...
	... %'20210709T103307.A_Elmo.B_ST.SCP_01.sessiondir', ...
	... %'20210715T105108.A_Elmo.B_ST.SCP_01.sessiondir', ...
	... %'20210716T103652.A_Elmo.B_KN.SCP_01.sessiondir', ...
	};


Elmo_SHUFFLED_CONF_top_10 = {...
	'20210204T131620.A_Elmo.B_DL.SCP_01.sessiondir', ... % Elmo_SHUFFLED_CONF_top_10
	'20210205T151709.A_Elmo.B_DL.SCP_01.sessiondir', ... % Elmo_SHUFFLED_CONF_top_10
	'20210211T163501.A_Elmo.B_DL.SCP_01.sessiondir', ... % Elmo_SHUFFLED_CONF_top_10
	'20210212T153711.A_Elmo.B_DL.SCP_01.sessiondir', ... % Elmo_SHUFFLED_CONF_top_10
	'20210218T131636.A_Elmo.B_FS.SCP_01.sessiondir', ... % Elmo_SHUFFLED_CONF_top_10
	'20210219T145809.A_Elmo.B_DL.SCP_01.sessiondir', ... % Elmo_SHUFFLED_CONF_top_10
	'20210610T132106.A_Elmo.B_ST.SCP_01.sessiondir', ... % Elmo_SHUFFLED_CONF_top_10
	'20210618T123111.A_Elmo.B_ST.SCP_01.sessiondir', ... % Elmo_SHUFFLED_CONF_top_10
	'20210623T140144.A_Elmo.B_ST.SCP_01.sessiondir', ... % Elmo_SHUFFLED_CONF_top_10
	'20210625T141512.A_Elmo.B_KN.SCP_01.sessiondir', ... % Elmo_SHUFFLED_CONF_top_10
	};
Elmo_SHUFFLED_CONF_top_10_wrong = {...
	... %'20210211T163501.A_Elmo.B_DL.SCP_01.sessiondir', ...
	... %'20210212T153711.A_Elmo.B_DL.SCP_01.sessiondir', ...
	... %'20210218T131636.A_Elmo.B_FS.SCP_01.sessiondir', ...
	... %'20210219T145809.A_Elmo.B_DL.SCP_01.sessiondir', ...
	'20210609T134704.A_Elmo.B_KN.SCP_01.sessiondir', ...
	... %'20210610T132106.A_Elmo.B_ST.SCP_01.sessiondir', ...
	'20210611T135443.A_Elmo.B_KN.SCP_01.sessiondir', ...
	... %'20210618T123111.A_Elmo.B_ST.SCP_01.sessiondir', ...
	... %'20210623T140144.A_Elmo.B_ST.SCP_01.sessiondir', ...
	... %'20210625T141512.A_Elmo.B_KN.SCP_01.sessiondir', ...
	};

Elmo_SHUFFLED_CONF = {...
	'20210203T151622.A_Elmo.B_DL.SCP_01', ... % 
...	'20210204T131620.A_Elmo.B_DL.SCP_01', ... % Elmo_SHUFFLED_CONF_top_10
...	'20210205T151709.A_Elmo.B_DL.SCP_01', ... % Elmo_SHUFFLED_CONF_top_10, spike_sorted: Elmo  : SoloA, Dyadic(SHUFFLED); Shuffled only
...	'20210211T163501.A_Elmo.B_DL.SCP_01', ... % Elmo_SHUFFLED_CONF_top_10
...	'20210212T153711.A_Elmo.B_DL.SCP_01', ... % Elmo_SHUFFLED_CONF_top_10
...	'20210218T131636.A_Elmo.B_FS.SCP_01', ... % Elmo_SHUFFLED_CONF_top_10
...	'20210219T145809.A_Elmo.B_DL.SCP_01', ... % Elmo_SHUFFLED_CONF_top_10, spike sorted: Elmo  : SoloA, Dyadic(BLOCKED/SHUFFLED); Shuffled/Blocked
...	'20210610T132106.A_Elmo.B_ST.SCP_01', ... % Elmo_SHUFFLED_CONF_top_10
...	'20210611T135443.A_Elmo.B_KN.SCP_01', ... % Elmo_SHUFFLED_CONF_top_10_wrong
...	'20210618T123111.A_Elmo.B_ST.SCP_01', ... % Elmo_SHUFFLED_CONF_top_10
...	'20210623T140144.A_Elmo.B_ST.SCP_01', ... % Elmo_SHUFFLED_CONF_top_10
...	'20210625T141512.A_Elmo.B_KN.SCP_01', ... % Elmo_SHUFFLED_CONF_top_10, Elmo  : SoloA, Dyadic(SHUFFLED), SemiSolo(SHUFFLED); Santiago
};



Elmo_BLOCKED_CONF_not_top_10 = {...
...	'20201216T114911.A_Elmo.B_FS.SCP_01', ...	% has issues Error in SCP_ephys_base_analysis (line 1122), Index exceeds the number of array elements. Index must not exceed 3. TrialSubType was missing None with index 0: more issues: Unrecognized field name "TrialSubTypes".
	...%'20201218T130348.A_Elmo.B_FS.SCP_01', ... % ELMO_blocked_spike_sorted
	'20210127T130717.A_Elmo.B_FS.SCP_01', ... % ELMO_blocked_spike_sorted
	...%'20210129T150949.A_Elmo.B_FS.SCP_01', ... % ELMO_blocked_spike_sorted
	'20210218T131636.A_Elmo.B_FS.SCP_01', ...	
	...%'20210219T145809.A_Elmo.B_DL.SCP_01', ... % ELMO_blocked_spike_sorted
	'20210316T134225.A_Elmo.B_FS.SCP_01', ...	
	'20210317T140755.A_Elmo.B_FS.SCP_01', ...	
	'20210318T131335.A_Elmo.B_FS.SCP_01', ...
	'20210319T132345.A_Elmo.B_FS.SCP_01', ...
	'20210331T130804.A_Elmo.B_KN.SCP_01', ...
	...%'20210401T124246.A_Elmo.B_KN.SCP_01', ... % Elmo_BLOCKED_CONF_top_10
	'20210415T112453.A_Elmo.B_KN.SCP_01', ...
	...%'20210416T105525.A_Elmo.B_KN.SCP_01', ... % Elmo_BLOCKED_CONF_top_10 % ELMO_blocked_spike_sorted
	'20210421T105506.A_Elmo.B_KN.SCP_01', ...
	'20210422T131844.A_Elmo.B_KN.SCP_01', ...
	...%'20210423T105645.A_Elmo.B_KN.SCP_01', ... % Elmo_BLOCKED_CONF_top_10 % ELMO_blocked_spike_sorted
	...%'20210519T112804.A_Elmo.B_KN.SCP_01', ...
	'20210520T120659.A_Elmo.B_KN.SCP_01', ... % Elmo_BLOCKED_CONF_top_10
	'20210521T102025.A_Elmo.B_KN.SCP_01', ...
	...%'20210604T143542.A_Elmo.B_KN.SCP_01', ... % Elmo_BLOCKED_CONF_top_10
	...%'20210608T131158.A_Elmo.B_KN.SCP_01', ... % Elmo_BLOCKED_CONF_top_10_wrong
	...%'20210616T124854.A_Elmo.B_ST.SCP_01', ... % Elmo_BLOCKED_CONF_top_10_wrong
	'20210617T125407.A_Elmo.B_ST.SCP_01', ...
	'20210622T132359.A_Elmo.B_ST.SCP_01', ...
	'20210624T130705.A_Elmo.B_KN.SCP_01', ...
	'20210707T125533.A_Elmo.B_ST.SCP_01', ...
	'20210707T125533.A_Elmo.B_ST.SCP_01', ...
	...%'20210708T131736.A_Elmo.B_KN.SCP_01', ... % Elmo_BLOCKED_CONF_top_10
	...%'20210709T103307.A_Elmo.B_ST.SCP_01', ... % Elmo_BLOCKED_CONF_top_10
	...%'20210715T105108.A_Elmo.B_ST.SCP_01', ... % Elmo_BLOCKED_CONF_top_10
	...%'20210716T103652.A_Elmo.B_KN.SCP_01', ... % Elmo_BLOCKED_CONF_top_10
	...%'20210828T135335.A_Elmo.B_KN.SCP_01', ... % Elmo_BLOCKED_CONF_top_10
};

Curius_BLOCKED_selection = { ...
	'20230330T133602.A_Curius.B_AE.SCP_01', ... % 
	'20230331T131059.A_Curius.B_AE.SCP_01', ... % 
	'20230404T150951.A_Curius.B_AE.SCP_01', ... % 
	'20230405T145014.A_Curius.B_AE.SCP_01', ... % 
	'20230412T143018.A_Curius.B_AE.SCP_01', ... % 
	'20230413T142422.A_Curius.B_AE.SCP_01', ... % 
	'20230504T131733.A_Curius.B_AE.SCP_01', ... % 
	'20230505T123505.A_Curius.B_AE.SCP_01', ... % 
	'20230509T130346.A_Curius.B_SM.SCP_01', ... % 
	'20230510T144106.A_Curius.B_SM.SCP_01', ... % 
	'20230511T142916.A_Curius.B_SM.SCP_01', ... % 
	'20230512T125943.A_Curius.B_SM.SCP_01', ... % 
	'20230516T133503.A_Curius.B_RB.SCP_01', ... % 
	'20230517T130621.A_Curius.B_RB.SCP_01', ... % 
	'20230518T135808.A_Curius.B_SM.SCP_01', ... % 
	'20230523T145755.A_Curius.B_SM.SCP_01', ... % 
	'20230525T103049.A_Curius.B_SM.SCP_01', ... % 
	'20230620T101238.A_Curius.B_VC.SCP_01', ... % 
	'20230621T100721.A_Curius.B_MK.SCP_01', ... % 
	'20230622T111856.A_Curius.B_SM.SCP_01', ... % 
	'20230628T101631.A_Curius.B_VC.SCP_01', ... % 
	'20230703T122644.A_Curius.B_MK.SCP_01', ... % 
};

Curius_SHUFFLED_selection = { ...
 	'20230607T115959.A_Curius.B_VC.SCP_01', ...
 	'20230608T102315.A_Curius.B_VC.SCP_01', ...
 	'20230609T101610.A_Curius.B_VC.SCP_01', ...
 	'20230613T104336.A_Curius.B_VC.SCP_01', ...
 	'20230614T114327.A_Curius.B_VC.SCP_01', ...
 	'20230615T122340.A_Curius.B_VC.SCP_01', ...
 	'20230616T094811.A_Curius.B_VC.SCP_01', ...
 	'20230619T102732.A_Curius.B_VC.SCP_01', ...
 	'20230620T101238.A_Curius.B_VC.SCP_01', ...
 	'20230621T100721.A_Curius.B_MK.SCP_01', ...
 	'20230622T111856.A_Curius.B_SM.SCP_01', ...
 	'20230627T094057.A_Curius.B_MK.SCP_01', ...
 	'20230628T101631.A_Curius.B_VC.SCP_01', ...
 	'20230629T100435.A_Curius.B_VC.SCP_01', ...
 	'20230703T122644.A_Curius.B_MK.SCP_01', ...
};

DualNHP_selection = {...
 	'20230623T124557B.A_Curius.B_Elmo.SCP_01', ...
 	'20230623T124557U.A_Curius.B_Elmo.SCP_01', ...
 	'20230630T115937.A_Curius.B_Elmo.SCP_01', ...
 	'20230630T115937B.A_Curius.B_Elmo.SCP_01', ...
 	'20230704T130229.A_Curius.B_Elmo.SCP_01', ...
 	'20230704T130229B.A_Curius.B_Elmo.SCP_01', ...
 	'20230707T102457.A_Curius.B_Elmo.SCP_01', ...
 	'20230707T102457B.A_Curius.B_Elmo.SCP_01', ...
	};

Elmo_BLOCKED_selection = {...
 	'20201204T125624.A_Elmo.B_FS.SCP_01', ...
 	'20201208T125551.A_Elmo.B_FS.SCP_01', ...
 	'20201209T131446.A_Elmo.B_FS.SCP_01', ...
 	'20201211T104906.A_Elmo.B_FS.SCP_01', ...
 	'20201215T110936.A_Elmo.B_FS.SCP_01', ...
 	'20201216T114911.A_Elmo.B_FS.SCP_01', ...
 	'20201217T135022.A_Elmo.B_FS.SCP_01', ...
 	'20201218T130348.A_Elmo.B_FS.SCP_01', ...
 	'20210119T110839.A_Elmo.B_FS.SCP_01', ...%
 	'20210120T112418.A_Elmo.B_FS.SCP_01', ...%
 	'20210121T115414.A_Elmo.B_FS.SCP_01', ...%
 	'20210122T125644.A_Elmo.B_FS.SCP_01', ...%
 	'20210126T132146.A_Elmo.B_FS.SCP_01', ...%
 	'20210127T130717.A_Elmo.B_FS.SCP_01', ...
 	'20210129T150949.A_Elmo.B_FS.SCP_01', ...
 	'20210318T131335.A_Elmo.B_FS.SCP_01', ...
 	'20210319T132345.A_Elmo.B_FS.SCP_01', ...
 	'20210331T130804.A_Elmo.B_KN.SCP_01', ...
 	'20210401T124246.A_Elmo.B_KN.SCP_01', ...
 	'20210415T112453.A_Elmo.B_KN.SCP_01', ...
 	'20210416T105525.A_Elmo.B_KN.SCP_01', ...
 	'20210421T105506.A_Elmo.B_KN.SCP_01', ...
 	'20210422T131844.A_Elmo.B_KN.SCP_01', ...
 	'20210423T105645.A_Elmo.B_KN.SCP_01', ...
 	'20210519T112804.A_Elmo.B_KN.SCP_01', ...%
 	'20210520T120659.A_Elmo.B_KN.SCP_01', ...
 	'20210521T102025.A_Elmo.B_KN.SCP_01', ...
 	'20210604T143542.A_Elmo.B_KN.SCP_01', ...
 	'20210608T131158.A_Elmo.B_KN.SCP_01', ...% Index exceeds the number of array elements. Index must not exceed 12. 29
 	'20210616T124854.A_Elmo.B_ST.SCP_01', ...
 	'20210617T125407.A_Elmo.B_ST.SCP_01', ...
 	'20210624T130705.A_Elmo.B_KN.SCP_01', ...
 	'20210707T125533.A_Elmo.B_ST.SCP_01', ...
 	'20210708T131736.A_Elmo.B_KN.SCP_01', ...
 	'20210709T103307.A_Elmo.B_ST.SCP_01', ...
 	'20210715T105108.A_Elmo.B_ST.SCP_01', ...
 	'20210716T103652.A_Elmo.B_KN.SCP_01', ...
 	'20210828T135335.A_Elmo.B_KN.SCP_01', ...
 	'20230628T144009.A_MK.B_Elmo.SCP_01', ...
 	'20230629T152509.A_MK.B_Elmo.SCP_01', ...
};

Elmo_SHUFFLED_selection = {...
 	'20210202T154700.A_Elmo.B_DL.SCP_01', ...
 	'20210203T151622.A_Elmo.B_DL.SCP_01', ...
 	'20210204T131620.A_Elmo.B_DL.SCP_01', ...
 	'20210205T151709.A_Elmo.B_DL.SCP_01', ...
 	'20210211T163501.A_Elmo.B_DL.SCP_01', ...
 	'20210212T153711.A_Elmo.B_DL.SCP_01', ...
 	'20210218T131636.A_Elmo.B_FS.SCP_01', ...
 	'20210219T145809.A_Elmo.B_DL.SCP_01', ...
 	'20210610T132106.A_Elmo.B_ST.SCP_01', ...
 	'20210611T135443.A_Elmo.B_KN.SCP_01', ...
 	'20210618T123111.A_Elmo.B_ST.SCP_01', ...
 	'20210623T140144.A_Elmo.B_ST.SCP_01', ...
 	'20210625T141512.A_Elmo.B_KN.SCP_01', ...	
};


% sessions in which we expect significant FixUps
FixUpReport_session_list = { ...
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2023', '230413', '20230413T142422.A_Curius.B_AE.SCP_01.sessiondir'), ...
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2020', '201216', '20201216T114911.A_Elmo.B_FS.SCP_01.sessiondir'), ...
	fullfile('Y:', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', '2020', '201217', '20201217T135022.A_Elmo.B_FS.SCP_01.sessiondir'), ...
};

sessions_with_spurious_TrialSubTypeIssues = { ...
...	'20201217T135022.A_Elmo.B_FS.SCP_01', ... % 
	'20230413T142422.A_Curius.B_AE.SCP_01', ...
	'20210125T152032.A_Elmo.B_None.SCP_01', ...
	'20230112T133959.A_Elmo.B_None.SCP_01', ...
	'20230329T134429.A_Curius.B_None.SCP_01', ...
	'20230418T130456.A_Curius.B_None.SCP_01', ...
	'20230615T170548.A_None.B_Elmo.SCP_01', ...
	'20201204T125624.A_Elmo.B_FS.SCP_01', ... % 
	'20201208T125551.A_Elmo.B_FS.SCP_01', ... % 
	'20201209T131446.A_Elmo.B_FS.SCP_01', ... % 
	'20201211T104906.A_Elmo.B_FS.SCP_01', ... % 
	'20201215T110936.A_Elmo.B_FS.SCP_01', ... % 
	'20201216T114911.A_Elmo.B_FS.SCP_01', ... % has issues Error in SCP_ephys_base_analysis (line 1122), Index exceeds the number of array elements. Index must not exceed 3. TrialSubType was missing None with index 0: more issues: Unrecognized field name "TrialSubTypes".
	'20201217T135022.A_Elmo.B_FS.SCP_01', ... % 
};


%sessiondir_list = FixUpReport_session_list;
%sessiondir_list = sessions_with_spurious_TrialSubTypeIssues;

%sessiondir_list = spike_sorted_session_ID_list;
%set_name = 'spike_sorted_session_ID_list'; 


sessiondir_list = Curius_BLOCKED_CONF_top_10;
set_name = 'Curius_BLOCKED_CONF_top_10'; 
sessiondir_list = Curius_SHUFFLED_CONF_top_10;
set_name = 'Curius_SHUFFLED_CONF_top_10'; 

sessiondir_list = Elmo_BLOCKED_CONF_top_10;
set_name = 'Elmo_BLOCKED_CONF_top_10'; 
sessiondir_list = Elmo_SHUFFLED_CONF_top_10;
set_name = 'Elmo_SHUFFLED_CONF_top_10'; 



sessiondir_list = Curius_BLOCKED_selection;
set_name = 'Curius_BLOCKED_selection'; 
sessiondir_list = Curius_SHUFFLED_selection;
set_name = 'Curius_SHUFFLED_selection'; 

sessiondir_list = Elmo_SHUFFLED_selection;
set_name = 'Elmo_SHUFFLED_selection'; 
sessiondir_list = Elmo_BLOCKED_selection;
set_name = 'Elmo_BLOCKED_selection'; 


% make sure these are valid names and do exist
sessiondir_list = fn_expand_session_list(base_SESSIONLOGS_dir, sessiondir_list);
if isempty(sessiondir_list)
	error([mfilename, ': sessiondir_list is empty. Paste your session list and rerun.']);
end

% Configure reporting scope:
% - [] or '' => include all FixUpReport lines
% - char/string/cellstr => include lines containing any token
fixup_report_search_string = 'TrialSubType';

%% Setup output folder and parser settings
repo_dir = fileparts(mfilename('fullpath'));
out_dir = fullfile(repo_dir, 'TrialSubType_assignment_check');
if ~isempty(set_name)
	out_dir = fullfile(out_dir, set_name);
end

if ~isfolder(out_dir)
	mkdir(out_dir);
end

% Get current parser version string for consistent output naming.
[~, parser_version] = fnParseEventIDEReportSCPv06([]);

force_request_list = {'force_parsing'};
item_separator = []; %';';
array_separator = []; %'|';
override_directive = 'local_code';
[filter_list, include_all_fixups] = local_normalize_filter_list(fixup_report_search_string);
filter_tag = local_make_filter_tag(filter_list, include_all_fixups);

combined_session_id_list = {};
combined_session_dir_list = {};
combined_fixup_line_number_list = [];
combined_fixup_line_list = {};

%% Process sessions
n_sessions = numel(sessiondir_list);
fprintf('%s: Processing %d sessions.\n', mfilename, n_sessions);

for i_session = 1:n_sessions
	cur_session_dir = sessiondir_list{i_session};
	fprintf('%s: [%d/%d] %s\n', mfilename, i_session, n_sessions, cur_session_dir);

	if ~isfolder(cur_session_dir)
		warning('%s: Session directory not found, skipping: %s', mfilename, cur_session_dir);
		continue;
	end

	[~, session_id, session_ext] = fileparts(cur_session_dir);
	if ~strcmp(session_ext, '.sessiondir')
		% Keep behavior permissive; still try to parse using directory basename.
		warning('%s: Directory does not end in .sessiondir, using basename as session id: %s', mfilename, cur_session_dir);
	end

	triallog_base_fqn = fullfile(cur_session_dir, [session_id, '.triallog']);
	if include_all_fixups
		report_scope_suffix = '.FixUpReport.csv';
	else
		report_scope_suffix = ['.FixUpReport.', filter_tag, '.csv'];
	end
	out_csv_fqn = fullfile(out_dir, [session_id, '.triallog', parser_version, report_scope_suffix]);

	try
		report_struct = fnParseEventIDEReportSCPv06( ...
			triallog_base_fqn, item_separator, array_separator, override_directive, force_request_list);
	catch parse_error
		warning('%s: Parse failed for %s\n%s', mfilename, triallog_base_fqn, parse_error.message);
		% Keep the contract: create an empty output file if no usable result.
		local_create_empty_file(out_csv_fqn);
		continue;
	end

	if ~isfield(report_struct, 'FixUpReport') || isempty(report_struct.FixUpReport)
		local_create_empty_file(out_csv_fqn);
		continue;
	end

	fixup_lines = report_struct.FixUpReport(:);
	if include_all_fixups
		selected_fixup_ldx = true(size(fixup_lines));
	else
		selected_fixup_ldx = false(size(fixup_lines));
		for i_filter = 1:numel(filter_list)
			selected_fixup_ldx = selected_fixup_ldx | contains(fixup_lines, filter_list{i_filter}, 'IgnoreCase', true);
		end
	end
	selected_fixup_lines = fixup_lines(selected_fixup_ldx);
	selected_fixup_line_numbers = find(selected_fixup_ldx);

	if isempty(selected_fixup_lines)
		local_create_empty_file(out_csv_fqn);
	else
		n_lines = numel(selected_fixup_lines);
		out_table = table( ...
			repmat({session_id}, n_lines, 1), ...
			selected_fixup_line_numbers, ...
			selected_fixup_lines, ...
			'VariableNames', {'SessionID', 'FixUpReportLineNumber', 'FixUpReportLine'});
		writetable(out_table, out_csv_fqn);

		combined_session_id_list = [combined_session_id_list; repmat({session_id}, n_lines, 1)];
		combined_session_dir_list = [combined_session_dir_list; repmat({cur_session_dir}, n_lines, 1)];
		combined_fixup_line_number_list = [combined_fixup_line_number_list; selected_fixup_line_numbers];
		combined_fixup_line_list = [combined_fixup_line_list; selected_fixup_lines];
	end
end

fprintf('%s: Done. Output written to: %s\n', mfilename, out_dir);
combined_csv_fqn = fullfile(out_dir, ['combined.fixup_report', parser_version, '.', filter_tag, '.csv']);
if isempty(combined_fixup_line_list)
	local_create_empty_file(combined_csv_fqn);
else
	combined_table = table( ...
		combined_session_id_list, ...
		combined_session_dir_list, ...
		combined_fixup_line_number_list, ...
		combined_fixup_line_list, ...
		'VariableNames', {'SessionID', 'SessionDir', 'FixUpReportLineNumber', 'FixUpReportLine'});
	writetable(combined_table, combined_csv_fqn);
end
fprintf('%s: Combined CSV written to: %s\n', mfilename, combined_csv_fqn);

% final end...
timestamps.(mfilename).end = toc(timestamps.(mfilename).start);
cur_duration_s = timestamps.(mfilename).end;
disp([mfilename, ' took: ', num2str(timestamps.(mfilename).end), ' seconds (', num2str(floor(cur_duration_s/(60*60))), ' hours ', num2str(floor(rem(cur_duration_s, 3600)/60)), ' minutes ', num2str(mod(cur_duration_s, 60)), ' seconds).']);





function local_create_empty_file(target_fqn)
% Create an empty file (0 bytes), overwriting if it exists.
fd = fopen(target_fqn, 'w');
if fd == -1
	error('Could not create output file: %s', target_fqn);
end
fclose(fd);
end


function [filter_list, include_all_fixups] = local_normalize_filter_list(raw_filter)
% Normalize filter inputs to a trimmed cellstr list.
% Empty input means "include all FixUpReport lines".
if ~exist('raw_filter', 'var') || isempty(raw_filter)
	filter_list = {};
	include_all_fixups = true;
	return
end

if ischar(raw_filter)
	filter_list = {raw_filter};
elseif isstring(raw_filter)
	filter_list = cellstr(raw_filter(:));
elseif iscell(raw_filter)
	filter_list = raw_filter(:);
else
	error('%s: fixup_report_search_string must be char/string/cellstr or empty.', mfilename);
end

for i_filter = 1:numel(filter_list)
	if isstring(filter_list{i_filter})
		filter_list{i_filter} = char(filter_list{i_filter});
	end
	if ~ischar(filter_list{i_filter})
		error('%s: fixup_report_search_string cell elements must be text.', mfilename);
	end
	filter_list{i_filter} = strtrim(filter_list{i_filter});
end

filter_list = filter_list(~cellfun(@isempty, filter_list));
include_all_fixups = isempty(filter_list);
end


function [filter_tag] = local_make_filter_tag(filter_list, include_all_fixups)
% Build a filename-safe tag that encodes the chosen scope.
if include_all_fixups
	filter_tag = 'all_fixups';
	return
end

safe_parts = cell(size(filter_list));
for i_filter = 1:numel(filter_list)
	safe_parts{i_filter} = regexprep(filter_list{i_filter}, '[^a-zA-Z0-9]+', '_');
	safe_parts{i_filter} = regexprep(safe_parts{i_filter}, '^_+|_+$', '');
	if isempty(safe_parts{i_filter})
		safe_parts{i_filter} = 'filter';
	end
end
filter_tag = strjoin(safe_parts, '__');
end


function [ session_FQD_list ] = fn_expand_session_list( base_SESSIONLOGS_dir, session_list )
% iterate over the members of session_list
% if the member points to an existing directory, keep it
% otherwise try to parse it with fn_parse_session_id and construct the
% output name

session_FQD_list = cell(size(session_list));

for i_session = 1 : length(session_list)
	cur_session_list_member = session_list{i_session};
	% existing directory, just keep it, even if not canoncal, the user
	% asked for it and it exists, so deliver it
	if isfolder(cur_session_list_member)
		session_FQD_list(i_session) = {cur_session_list_member};
		continue
	end
	% this should accept session names ending in .sessiondir as well as
	% names without that suffix
	cur_session_info = fn_parse_session_id(cur_session_list_member);

	% again only add if the directoy we constructed actually exists
	if isfolder(fullfile(base_SESSIONLOGS_dir, cur_session_info.SESSIONLOGS_relative_sessiondir))
		session_FQD_list(i_session) = {fullfile(base_SESSIONLOGS_dir, cur_session_info.SESSIONLOGS_relative_sessiondir)};
		continue
	end

	% left overs should not happen:
	error([mfilename, ': ERROR: proto session ID string could not be canoncalized, it might not point to an existing session: ', cur_session_list_member]);

end

end





