function [ output_args ] = Test_eventIDE_ADC_signallog_v3( input_args )
%TEST_EVENTIDE_ADC_SIGNALLOG Summary of this function goes here
%   Detailed explanation goes here

% 	TrackerLog_FQN = fullfile('/', 'space', 'data_local', 'moeller', 'DPZ', 'taskcontroller', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', ...
% 		'2020', '200120', '20200120T164328.A_SMAccPhot.B_None.SCP_01.sessiondir', 'trackerlogfiles', ...
% 		'20200120T164328.A_SMAccPhot.B_None.SCP_01.TID_NISignalFileWriterADC.signallog'); % .txt.gz
% 	[ data_struct ] = fnParseEventIDETrackerLog_v01(TrackerLog_FQN, column_separator, force_number_of_columns, forced_header_string);


% load a test dat set
% initial test with PhotoDioda at IFT position, with full 1kHz test signal
% and thin accerlerometer probe
test_session_id = '20200123T111909.A_SMAccPhot.B_None.SCP_01';

test_session_id = '20200214T162129.A_SMAccPhot.B_None.SCP_01';

% Rendertrigger, instead of TestSignal_5kHz
%test_session_id = '20200214T165926.A_SMAccPhot.B_None.SCP_01';
%test_session_id = '20200214T171529.A_SMAccPhot.B_None.SCP_01'; % longer runtime

% Rendertrigger, during experient PhotoDiode active during dim IFT and dim
% choice targets
%test_session_id = '20200217T175057.A_SM.B_Curius.SCP_01'; % longer runtime

% new test
%test_session_id = '20200219T143249.A_SM.B_Elmo.SCP_01';


%test_session_id = '20200221T123925.A_Curius.B_Elmo.SCP_01';

test_session_id = '20200221T123925.A_Curius.B_Elmo.SCP_01';


% test whether the apparent high rate samples come from the chunk size
% Chunk size 5000
test_session_id = '20200317T183512.A_TestA.B_Chunk5000.SCP_01';
test_session_id = '20200317T183725.A_TestA.B_Chunk5000.SCP_01';
% % Chunk size 10000
%test_session_id = '20200317T183927.A_TestA.B_Chunk10000.SCP_01';
%test_session_id = '20200317T184059.A_TestA.B_Chunk10000.SCP_01';

% Chunk size 5000
test_session_id = '20200317T194146.A_TestA.B_Chunk5000.SCP_01';

test_session_id = '20200317T203809.A_TestA.B_Chunk5000.SCP_01';



% Chunk size 5000, direkt DiplayPort connection
test_session_id = '20200318T155509.A_TestA.B_DisplayPortDirect.SCP_01';
% Chunk size 5000,  DiplayPort connected via DP1.2a MST switch with NVidia
% clone group over both DP displays
test_session_id = '20200318T170842.A_TestA.B_DPSplitClone.SCP_01';
% ==> Trigger/Timestamp to PhotoDiode output delay still 32-75 ms, clone
% group versus direct, and DP versus HDMI do not have a noticeable effect


% new test 20200319, different DP configurations:

% DP direct single monitor, no splitter
test_session_id = '20200319T184552.A_TestA.B_DPdirectNoSplt.SCP_01';

% DP single monitor: DPout -> DP splitter -> Monitor
test_session_id = '20200319T183931.A_TestA.B_None.SCP_01';
test_session_id = '20200317T203809.A_TestA.B_Chunk5000.SCP_01';


% Test DP single direct connection, MP
test_session_id = '20200320T133526.A_MP.B_None.SCP_01';

% Test HDMI with splitter, old driver settings
test_session_id = '20200317T203809.A_TestA.B_Chunk5000.SCP_01';
% Test HDMI with splitter, driver settings as with MP DP tests
% test_session_id = '20200325T135933.A_TestA.B_HDMISplitter.SCP_01';



% Test HDMI with splitter, driver settings as with MP DP tests
% with touch accelerometer
% test_session_id = '20200325T143444.A_TestA.B_AccTest.SCP_01';




% new log file format, with different PhotoDiode switching behaviour and
% tracking of individual renderer state and timings
% this works somewhat, but misses out on PhotoDiode data, as in the task
% there is no constant photo diode for IFT dim periods...
test_session_id = '20200421T134355.A_Elmo.B_None.SCP_01';

% HDMI
test_session_id = '20200422T180017.A_TestA.B_HDMISplit.SCP_01';
% VGA: graphigs-borad-DVI-I -> DVI-I-2-VGA -> VGA-cable -> VGA-2-DVI-I -> OLED
test_session_id = '20200422T184239.A_TestA.B_VGA60Hz.SCP_01';


% elmo HDMI 59Hz -> GOOD tight refresh time histograms
test_session_id = '20200423T120405.A_Elmo.B_None.SCP_01';


% % none HDMI 59Hz -> GOOD tight refresh time histograms
% test_session_id = '20200423T161050.A_TestA.B_HDMIs59Hz.SCP_01';
% 
% % none HDMI 60Hz -> BAD tight refresh time histograms
% test_session_id = '20200423T165715.A_TestA.B_HDMIs60Hz.SCP_01';
%  
% % none HDMI 59Hz, -> BAD tight refresh time histograms 
% test_session_id = '20200423T171805.A_TestA.B_HDMIs59Hz.SCP_01';

% none HDMI 59Hz, -> BAD tight refresh time histograms 
test_session_id = '20200424T100659.A_TestA.B_HDMI59Hz.SCP_01';


% none HDMI 59.94Hz, Ueberprueft durch SRC toggling on the OLED during
% experiment execution, OSD reports 59.94 Hz
% -> BAD tight refresh time histograms 
test_session_id = '20200424T103555.A_TestA.B_HDMI59_9Hz.SCP_01';


% none VGA splitter 60Hz, 
% -> BAD tight refresh time histograms 
test_session_id = '20200424T120828.A_TestA.B_VGAs60Hz.SCP_01';

% none VGA splitter 58.9Hz, 
% -> BAD tight refresh time histograms 
test_session_id = '20200424T123054.A_TestA.B_VGAs58_9Hz.SCP_01';

% elmo HDMI 59Hz -> GOOD tight refresh time histograms
test_session_id = '20200423T120405.A_Elmo.B_None.SCP_01';

% % VGA: graphigs-borad-DVI-I -> DVI-I-2-VGA -> VGA-cable -> VGA-2-DVI-I -> OLED
% test_session_id = '20200422T184239.A_TestA.B_VGA60Hz.SCP_01';

% none VGA splitter 58.9Hz, 
% -> BAD tight refresh time histograms 
% PhotoDiodeRenderer was out of sight
%test_session_id = '20200424T130358.A_TestA.B_VGAs58_9Hz.SCP_01';

% Elmo VGA splitter 58.9Hz, 
% -> ??? tight refresh time histograms 
% PhotoDiodeRenderer was out of sight for the first half of the experiment
%test_session_id = '20200424T134712.A_Elmo.B_None.SCP_01';

% None DVI no splitter 60.0Hz, 
% -> ??? tight refresh time histograms 
test_session_id = '20200424T164805.A_TestA.B_DVI60Hz.SCP_01';



% None DVI no splitter 60.0Hz, OLED reports 60.0Hz as well
% -> ??? tight refresh time histograms 
test_session_id = '20200424T172453.A_TestA.B_DVI60Hz.SCP_01';


% None DVI no splitter 60.0Hz, OLED reports 60.0Hz as well
% -> BAD tight refresh time histograms 
test_session_id = '20200427T115757.A_TestA.B_DVI60Hz.SCP_01';


% None HDMI with splitter 1920x1080, 59Hz (Win10 driver interface), 59Hz EventIDE graphics mode, OLED reports 59.9Hz
% -> Bad tight refresh time histograms 
test_session_id = '20200427T123353.A_TestA.B_HDMIs59.SCP_01';


% None HDMI with splitter 1920x1080, 59Hz (Win10 driver interface), 50Hz EventIDE graphics mode, OLED reports 50Hz
%	-> photo diode implies 120/60Hz!!!
% -> ??? tight refresh time histograms 
test_session_id = '20200427T125126.A_TestA.B_HDMIs50.SCP_01';


% None HDMI with splitter 1920x1080, 59Hz (Win10 driver interface), 
%	59.94 Nvidis Control panel
%	59Hz EventIDE graphics mode, OLED reports 59.9Hz
%	-> photo diode implies 120/60Hz
% -> ??? tight refresh time histograms 
test_session_id = '20200427T131113.A_TestA.B_HDMIs59.SCP_01';


% None HDMI with splitter 1920x1080, 60Hz (Win10 driver interface), 
%	59.80 Nvidis Control panel
%	60Hz EventIDE graphics mode, OLED reports 60.0Hz
%	-> photo diode implies 120/60Hz
% -> ??? tight refresh time histograms 
test_session_id = '20200427T190634.A_TestA.B_HDMIs60.SCP_01';



% Elmo HDMI with splitter 1920x1080, 59Hz (Win10 driver interface), 
%	59.80 Nvidia Control panel (manually set for both displays)
%	60Hz EventIDE graphics mode, OLED reports 59.8Hz
%	-> photo diode implies 120/60Hz
% -> ??? tight refresh time histograms 
test_session_id = '20200428T140704.A_Elmo.B_None.SCP_01';


% none VGA without splitter 1920x1080, 60Hz (Win10 driver interface), 
%	Nvidia Control panel: eMotionST3: 60.00 Hz; DELL U2412M: 59.95Hz
%	60Hz EventIDE graphics mode, OLED reports 60.0Hz
%	-> photo diode implies 120/60Hz, Oscilloscope measured 60.24Hz
% -> GOOD tight refresh time histograms BUT high latency ~70ms
test_session_id = '20200429T121957.A_TestA.B_VGA60.SCP_01';


% reboot and replug vga cable
% none VGA without splitter 1920x1080, 60Hz (Win10 driver interface), 
%	Nvidia Control panel: eMotionST3: 60.00 Hz; DELL U2412M: 59.95Hz
%	60Hz EventIDE graphics mode, OLED reports 60.0Hz
%	-> photo diode implies 120/60Hz, Oscilloscope measured 60.24Hz
% -> GOOD tight refresh time histograms BUT high latency ~50ms (3-4 frames)
test_session_id = '20200429T130217.A_TestA.B_VGA60.SCP_01';


% % elmo HDMI 59Hz -> GOOD tight refresh time histograms
% test_session_id = '20200423T120405.A_Elmo.B_None.SCP_01';


% reboot and replug vga cable
% ELMO VGA without splitter 1920x1080, 60Hz (Win10 driver interface), 
%	Nvidia Control panel: eMotionST3: 60.00 Hz; DELL U2412M: 59.95Hz
%	60Hz EventIDE graphics mode, OLED reports 60.0Hz
%	-> photo diode implies 120/60Hz, Oscilloscope measured 60.24Hz
% -> GOOD tight refresh time histograms BUT high latency ~50ms (3-4 frames)
test_session_id = '20200429T140031.A_Elmo.B_None.SCP_01';


% ELMO VGA without splitter 1920x1080, 60Hz (Win10 driver interface), 
%	Nvidia Control panel: eMotionST3: 60.00 Hz; DELL U2412M: 59.95Hz
%	60Hz EventIDE graphics mode, OLED reports 60.0Hz
%	-> photo diode implies 120/60Hz, Oscilloscope measured 60.24Hz
% -> ??? tight refresh time histograms BUT high latency ~50ms (3-4 frames)
%test_session_id = '20200430T135317.A_Elmo.B_None.SCP_01';



% ELMO VGA without splitter 1920x1080, 60Hz (Win10 driver interface), 
%	Nvidia Control panel: eMotionST3: 60.00 Hz; DELL U2412M: 59.95Hz
%	60Hz EventIDE graphics mode, OLED reports 60.0Hz
%	-> photo diode implies 120/60Hz, Oscilloscope measured 60.24Hz
% -> ??? tight refresh time histograms BUT high latency ~50ms (3-4 frames)
test_session_id = '20200505T162500.A_Elmo.B_None.SCP_01';


% ELMO VGA without splitter 1920x1080, 60Hz (Win10 driver interface), 
%	Nvidia Control panel: eMotionST3: 60.00 Hz; DELL U2412M: 59.95Hz
%	60Hz EventIDE graphics mode, OLED reports 60.0Hz
%	-> photo diode implies 120/60Hz, Oscilloscope measured 60.24Hz
% -> GOOD tight refresh time histograms BUT high latency ~50ms (3-4 frames)
test_session_id = '20200507T160339.A_Elmo.B_None.SCP_01';



% ELMO VGA without splitter 1920x1080, 60Hz (Win10 driver interface), 
%	Nvidia Control panel: eMotionST3: 60.00 Hz; DELL U2412M: 59.95Hz
%	60Hz EventIDE graphics mode, OLED reports 60.0Hz
%	-> photo diode implies 120/60Hz, Oscilloscope measured 60.24Hz
% -> ??? tight refresh time histograms BUT high latency ~50ms (3-4 frames)
test_session_id = '20200506T160241.A_Elmo.B_None.SCP_01';


% Test HDMI with splitter, driver settings as with MP DP tests
% with touch accelerometer
test_session_id = '20200325T143444.A_TestA.B_AccTest.SCP_01';


% ELMO VGA with splitter 1920x1080, 60Hz (Win10 driver interface), 
%	Nvidia Control panel: eMotionST3: 60.00 Hz; DELL U2412M: 59.95Hz
%	60Hz EventIDE graphics mode, OLED reports 60.0Hz
%	-> photo diode implies 120/60Hz, Oscilloscope measured 60.24Hz
% -> ??? tight refresh time histograms BUT high latency ~50ms (3-4 frames)
test_session_id = '20200506T160241.A_Elmo.B_None.SCP_01';



session_struct = fnLoadDataBySessionDir(test_session_id);

chan_names = {'EventIDE_TimeStamp', 'AccelerationSensor_Y', 'MotitorSpotDetector_LCD_level', 'RenderTriggerDO'};

%LogHeader: {'Timestamp'  'Dev1/ai0'  'Dev1/ai1'  'Dev1/ai2'}
ADC_data = session_struct.signallog_NISignalFileWriterADC;
corr_time_list = ADC_data.data(:, ADC_data.cn.Tracker_corrected_EventIDE_TimeStamp);
uncorr_time_list = ADC_data.data(:, ADC_data.cn.UncorrectedEventIDE_TimeStamp);

% tmp = [diff(corr_time_list), diff(uncorr_time_list)];
% plot([diff(corr_time_list), diff(uncorr_time_list)]);
time_vec = uncorr_time_list;
time_vec = corr_time_list;




corr_time_offset = corr_time_list(1);
corr_time_vec = corr_time_list - corr_time_offset;
corr_sample_subset = (1:1:length(corr_time_vec));

uncorr_time_offset = uncorr_time_list(1);
uncorr_time_vec = uncorr_time_list - uncorr_time_offset;
uncorr_sample_subset = (1:1:length(uncorr_time_vec));




%time_offset = 0;
time_offset = time_vec(1);
time_vec = time_vec - time_offset;
sample_subset = (1:1:length(time_vec));

%sample_subset(20000:1:200000);
% also plot render times as vertical lines

% also plot RTs/ touch traces


% data offset

% touches as registered by eventide
trial_log = session_struct.triallog;
IF_touch_onset_list = trial_log.data(:, trial_log.cn.A_InitialFixationTouchTime_ms) ;
IF_touch_offset_list = trial_log.data(:, trial_log.cn.A_InitialFixationAdjReleaseTime_ms);

IF_touch_onset_list(IF_touch_onset_list == 0) = [];
IF_touch_offset_list(IF_touch_offset_list == 0) = [];


IF_touch_onset_list = IF_touch_onset_list - time_offset;
IF_touch_offset_list = IF_touch_offset_list - time_offset;



%touch_dur = IF_touch_offset_list - IF_touch_onset_list;

% render events
render_timestamps = trial_log.Render.data(:, trial_log.Render.cn.Timestamp);
render_timestamps = render_timestamps - time_offset;

use_PhotoDiodeRenderer = 1;
% get the photo diode information render information from evenIDE, if available
if isfield(trial_log, 'PhotoDiodeRenderer') && ~isempty(trial_log.PhotoDiodeRenderer)
	pd_render_timestamps = trial_log.PhotoDiodeRenderer.data(:, trial_log.PhotoDiodeRenderer.cn.RenderTimestamp_ms);
	pd_render_timestamps = pd_render_timestamps - time_offset;
	% onsets	
	onset_tmp_idx = find(trial_log.PhotoDiodeRenderer.data(:, trial_log.PhotoDiodeRenderer.cn.Visible) == 1);
	pd_render_onset_timestamps = trial_log.PhotoDiodeRenderer.data(onset_tmp_idx, trial_log.PhotoDiodeRenderer.cn.RenderTimestamp_ms);
	pd_render_onset_timestamps = pd_render_onset_timestamps - time_offset;
	% offsets
	offset_tmp_idx = find(trial_log.PhotoDiodeRenderer.data(:, trial_log.PhotoDiodeRenderer.cn.Visible) == 1);
	pd_render_offset_timestamps = trial_log.PhotoDiodeRenderer.data(offset_tmp_idx, trial_log.PhotoDiodeRenderer.cn.RenderTimestamp_ms);
	pd_render_offset_timestamps = pd_render_offset_timestamps - time_offset;
else
	use_PhotoDiodeRenderer = 0;
	pd_render_timestamps = render_timestamps;
end

figure('Name', 'ADC Test');
subplot(3, 1, 1)
title(chan_names{2});
plot(time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai0));
hold on
xlabel('Samples');
y_lim = get(gca(), 'YLim');

for i_IFtouch_onset = 1 : length(IF_touch_onset_list)
	plot([IF_touch_onset_list(i_IFtouch_onset), IF_touch_onset_list(i_IFtouch_onset)], y_lim, 'Color', [0 1 0]);
end
for i_IFtouch_offset = 1 : length(IF_touch_offset_list)
	plot([IF_touch_offset_list(i_IFtouch_offset), IF_touch_offset_list(i_IFtouch_offset)], y_lim, 'Color', [1 0 0]);
end


hold off



subplot(3, 1, 2)
title(chan_names{3});
plot(time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai1));
hold on
for i_render_timestamps = 1 : length(render_timestamps)
	plot([render_timestamps(i_render_timestamps), render_timestamps(i_render_timestamps)], y_lim, 'Color', [0 1 0]);
end

hold off
xlabel('Samples');

subplot(3, 1, 3)
title(chan_names{4});
plot(time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai2));
xlabel('Samples');


%sample_subset = (500000:1:length(time_vec));

figure('Name', 'RenderTrigger')
plot(time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai1)); % the photo diode signal
hold on
for i_render_timestamps = 1 : length(render_timestamps)
	plot([render_timestamps(i_render_timestamps), render_timestamps(i_render_timestamps)], y_lim, 'Color', [0 1 0]);
end
plot(time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai2), 'Color', [1 0 0]);

hold off
xlabel('Samples');



% avoid the initial period that contains gunk (sampling started before output triggers asserted)
sample_offset = 1000000;
sample_offset = 0;
sample_subset = (1+sample_offset:1:length(time_vec));
cut_off_time = time_vec(1+sample_offset);
time = time_vec(sample_subset);

% the render time stamps
render_timestamps_list = render_timestamps(render_timestamps >= cut_off_time);


% threshold the render trigger
render_trigger_voltage = ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai1);
rt_high_samples_idx = find(render_trigger_voltage >= 3);

% get the differences
delta_rt_voltage = diff(render_trigger_voltage);
rt_onset_sample_idx = find(delta_rt_voltage >= 3) + 1;
rt_offset_sample_idx = find(delta_rt_voltage <= -3) + 1;
rt_onset_sample_timestamp_list = time(rt_onset_sample_idx);
rt_offset_sample_timestamp_list = time(rt_offset_sample_idx);



% threshold the PhotoDiode signal and get 
photo_diode_voltage = ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai1);
sample_subset_time = time(sample_subset);
%pd_high_samples_idx = find(photo_diode_voltage >= 3);
% get the differences
delta_pd_voltage = diff(photo_diode_voltage);
% find the transients
pd_onset_sample_idx = find(delta_pd_voltage >= 3) + 1; % shift by one to account for diff output being 1 shorter that its inputs
pd_offset_sample_idx = find(delta_pd_voltage <= -3) + 1;

pd_onset_sample_timestamp_list = sample_subset_time(pd_onset_sample_idx);
pd_offset_sample_timestamp_list = sample_subset_time(pd_offset_sample_idx);

% find the display periods of the PhotoDiodeDriver stimulus
% the first sample is an offset of offset by definition, so make sure we
% get a delta showing this
pd_onset_diff = diff([pd_onset_sample_idx(1); pd_onset_sample_idx]);
pd_offset_diff = diff([pd_offset_sample_idx(1); pd_offset_sample_idx]);

pd_onset_sample_timestamp_diff_list = diff([pd_onset_sample_timestamp_list(1); pd_onset_sample_timestamp_list]);
pd_offset_sample_timestamp_diff_list = diff([pd_offset_sample_timestamp_list(1); pd_offset_sample_timestamp_list]);


figure('Name', 'PhotoDiodeInterOnsetInterval')
%histogram((pd_onset_sample_timestamp_diff_list(find((pd_onset_sample_timestamp_diff_list * 1000) < 30)) * 1000));
%pd_onset_sample_timestamp_diff_list * 1000
tmp_data_idx = pd_onset_sample_timestamp_diff_list <= (30);
tmp_data = pd_onset_sample_timestamp_diff_list(tmp_data_idx);
histogram( tmp_data );
% calculate the screen refresh times:
avg_interframe_delay_ms = mean(tmp_data(find(tmp_data <= 16 & tmp_data >= 5)));
avg_screen_framerate = 1000/avg_interframe_delay_ms;
disp(['PhotoDiode pulses coming in at ~' num2str(avg_screen_framerate), ' Hz, with ', num2str(avg_interframe_delay_ms), 'ms inter pulse delay']);
% the OLED panel runds at ~ 120 Hz, so get the best matching 
disp(['Actual screen refreshes at ~' num2str(0.5 * avg_screen_framerate), ' Hz, with ', num2str(2.0 * avg_interframe_delay_ms), 'ms inter pulse delay']);


% assume that at 2KHz sampling and 60Hz screen refresh and break is at
% least one frame
sampling_rate_hz = 2000;
frame_rate_hz = 58.9;
frame_rate_hz = (0.5 * avg_screen_framerate); % take the empirically measured frame rate instead?
samples_per_frame = sampling_rate_hz / frame_rate_hz;
min_frames_per_gap = 1.5;


proto_pd_block_onset_idx = find(pd_onset_diff >= (samples_per_frame * (min_frames_per_gap)));
proto_pd_block_offset_idx = find(pd_offset_diff >= (samples_per_frame * (min_frames_per_gap)));

pd_block_onset_sample_idx = pd_onset_sample_idx(proto_pd_block_onset_idx);
pd_block_offset_sample_idx = pd_offset_sample_idx(proto_pd_block_offset_idx);
pd_block_onset_timestamp_list = time(pd_block_onset_sample_idx);
pd_block_offset_timestamp_list = time(pd_block_offset_sample_idx);


onset_rendertrigger_rendertime_delta = zeros(size(rt_onset_sample_timestamp_list));
for i_onset = 1 : length(rt_onset_sample_timestamp_list)
	cur_onset_time = rt_onset_sample_timestamp_list(i_onset);
	onset_photodiode_rendertime_delta(i_onset) = min(abs(cur_onset_time - render_timestamps_list));
end
figure('Name', 'RenderTrigger versus RendeTimes');
histogram(onset_photodiode_rendertime_delta, (0:0.1:20));


if (use_PhotoDiodeRenderer)
	
	figure('Name', 'PhotoDiodeSignalOnset versus PhotoDiodeRenderTimestamp')
	onset_photodiode_rendertrigger_delta = zeros(size(pd_block_onset_timestamp_list));
	onset_photodiodeAI_photodiode_rendertrigger_delta = zeros(size(pd_block_onset_timestamp_list));
	% try to find the best matching photo diode render timestamp in pd_render_onset_timestamps
	for i_onset = 1 : length(pd_block_onset_timestamp_list)
		cur_pd_block_onset_time = pd_block_onset_timestamp_list(i_onset);
		onset_photodiode_rendertrigger_delta(i_onset) = min(abs(cur_pd_block_onset_time - rt_onset_sample_timestamp_list));
		onset_photodiodeAI_photodiode_rendertrigger_delta(i_onset) = min(abs(cur_pd_block_onset_time - pd_render_onset_timestamps));
	end
	legend_text = {};
	subplot(1, 2, 1)
	histogram(onset_photodiode_rendertrigger_delta, (30:1:100));
	legend_text{end+1} = 'NIRenderTriggerDO';
	hold on
	histogram(onset_photodiodeAI_photodiode_rendertrigger_delta, (30:1:100));
	legend_text{end+1} = 'PhotoDiodeOnset';
	hold off
	legend(legend_text);
	subplot(1, 2, 2)
	
	%plot(onset_photodiode_rendertrigger_delta, 'Color', [0 1 0]);
	plot(onset_photodiodeAI_photodiode_rendertrigger_delta, 'Color', [0 1 0]);

	hold on
	x_lim = get(gca(), 'XLim');
	frame_period_ms = 1000 / frame_rate_hz;
	for i_frame = 2 : 5
		plot(x_lim, [frame_period_ms*i_frame, frame_period_ms*i_frame], 'Color', [0 0 0]);
	end
	%plot(onset_photodiode_rendertime_delta, 'Color', [1 0 0]);
	x_lim = get(gca(), 'XLim');
	frame_period_ms = 1000 / frame_rate_hz;
	for i_frame = 2 : 5
		plot(x_lim, [frame_period_ms*i_frame, frame_period_ms*i_frame], 'Color', [0 0 0]);
	end
	set(gca(), 'YLim', [0 100]);
	hold off
	

end


onset_photodiode_rendertrigger_delta = zeros(size(pd_block_onset_timestamp_list));
onset_photodiode_rendertime_delta = zeros(size(pd_block_onset_timestamp_list));
for i_onset = 1 : length(pd_block_onset_timestamp_list)
	cur_pd_block_onset_time = pd_block_onset_timestamp_list(i_onset);
	onset_photodiode_rendertrigger_delta(i_onset) = min(abs(cur_pd_block_onset_time - rt_onset_sample_timestamp_list));
	onset_photodiode_rendertime_delta(i_onset) = min(abs(cur_pd_block_onset_time - render_timestamps_list));
end
figure('Name', 'BlockOnset versus Trigger/Time');
histogram(onset_photodiode_rendertrigger_delta, (30:1:100));
hold on
histogram(onset_photodiode_rendertime_delta, (30:1:100));
hold off


offset_photodiode_rendertrigger_delta = zeros(size(pd_block_offset_timestamp_list));
offset_photodiode_rendertime_delta = zeros(size(pd_block_offset_timestamp_list));
for i_offset = 1 : length(pd_block_offset_timestamp_list)
	cur_pd_block_offset_time = pd_block_offset_timestamp_list(i_offset);
	offset_photodiode_rendertrigger_delta(i_offset) = min(abs(cur_pd_block_offset_time - rt_onset_sample_timestamp_list));
	offset_photodiode_rendertime_delta(i_offset) = min(abs(cur_pd_block_offset_time - render_timestamps_list));
end
figure('Name', 'BlockOffset versus Trigger/Time');
histogram(offset_photodiode_rendertrigger_delta, (30:1:100));
hold on
histogram(offset_photodiode_rendertime_delta, (30:1:100));
hold off


figure('Name', 'BlockOnset versus Trigger/Time per event');
plot(onset_photodiode_rendertrigger_delta, 'Color', [0 1 0]);
hold on
x_lim = get(gca(), 'XLim');
frame_period_ms = 1000 / frame_rate_hz;
for i_frame = 2 : 5
	plot(x_lim, [frame_period_ms*i_frame, frame_period_ms*i_frame], 'Color', [0 0 0]);
end
plot(onset_photodiode_rendertrigger_delta, 'Color', [0 1 0]);
%plot(onset_photodiode_rendertime_delta, 'Color', [1 0 0]);
x_lim = get(gca(), 'XLim');
frame_period_ms = 1000 / frame_rate_hz;
for i_frame = 2 : 5
	plot(x_lim, [frame_period_ms*i_frame, frame_period_ms*i_frame], 'Color', [0 0 0]);
end
set(gca(), 'YLim', [0 100]);
hold off

sample_offset = 0;
sample_offset = 1000000;
sample_offset = 2000000;
sample_offset = 0;

sample_end = length(time_vec);
%sample_end = 30000;
sample_subset = (1+sample_offset:1:sample_end);

figure('Name', 'RenderTrigger')
plot(time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai1)); % the photo diode signal
hold on

% what is going on with the timestamps


plot(uncorr_time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai1), 'Color', [0 0 0.33]); % the photo diode signal


y_lim = get(gca(), 'YLim');
for i_render_timestamps = 1 : length(render_timestamps)
	plot([render_timestamps(i_render_timestamps), render_timestamps(i_render_timestamps)], y_lim, 'Color', [0 1 0]);
end
plot(time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai2), 'Color', [1 0 0]);
plot(uncorr_time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai2), 'Color', [0.33 0 0]);


for i_pd_block_onset_timestamp = 1 : length(pd_block_onset_timestamp_list)
	plot([pd_block_onset_timestamp_list(i_pd_block_onset_timestamp), pd_block_onset_timestamp_list(i_pd_block_onset_timestamp)], y_lim, 'Color', [1 0 1]);
end
for i_pd_block_offset_timestamp = 1 : length(pd_block_offset_timestamp_list)
	plot([pd_block_offset_timestamp_list(i_pd_block_offset_timestamp), pd_block_offset_timestamp_list(i_pd_block_offset_timestamp)], y_lim, 'Color', [0 0 0]);
end
xlim([time_vec(1+sample_offset), time_vec(sample_end)]);
hold off
xlabel('Samples');




figure('Name', 'ADC Test');
%subplot(3, 1, 1)
title(chan_names{2});
plot(time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai0));
hold on
xlabel('Samples');
y_lim = get(gca(), 'YLim');

for i_IFtouch_onset = 1 : length(IF_touch_onset_list)
	plot([IF_touch_onset_list(i_IFtouch_onset), IF_touch_onset_list(i_IFtouch_onset)], y_lim, 'Color', [0 1 0]);
end
for i_IFtouch_offset = 1 : length(IF_touch_offset_list)
	plot([IF_touch_offset_list(i_IFtouch_offset), IF_touch_offset_list(i_IFtouch_offset)], y_lim, 'Color', [1 0 0]);
end
for i_pd_block_onset_timestamp = 1 : length(pd_block_onset_timestamp_list)
	plot([pd_block_onset_timestamp_list(i_pd_block_onset_timestamp), pd_block_onset_timestamp_list(i_pd_block_onset_timestamp)], y_lim, 'Color', [1 0 1]);
end
for i_pd_block_offset_timestamp = 1 : length(pd_block_offset_timestamp_list)
	plot([pd_block_offset_timestamp_list(i_pd_block_offset_timestamp), pd_block_offset_timestamp_list(i_pd_block_offset_timestamp)], y_lim, 'Color', [0 0 0]);
end




end


% function [cur_fh] = fn_plot_over_time(start_ts_idx, end_ts_idx, time_vec, pd_data, )
% 
% 
% 
% end