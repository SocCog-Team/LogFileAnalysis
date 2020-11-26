function [ output_args ] = Test_eventIDE_ADC_signallog_v4( input_args )
%TEST_EVENTIDE_ADC_SIGNALLOG Summary of this function goes here
%   Detailed explanation goes here

% 	TrackerLog_FQN = fullfile('/', 'space', 'data_local', 'moeller', 'DPZ', 'taskcontroller', 'SCP_DATA', 'SCP-CTRL-01', 'SESSIONLOGS', ...
% 		'2020', '200120', '20200120T164328.A_SMAccPhot.B_None.SCP_01.sessiondir', 'trackerlogfiles', ...
% 		'20200120T164328.A_SMAccPhot.B_None.SCP_01.TID_NISignalFileWriterADC.signallog'); % .txt.gz
% 	[ data_struct ] = fnParseEventIDETrackerLog_v01(TrackerLog_FQN, column_separator, force_number_of_columns, forced_header_string);

% 
% TODO:
% get gravity/range readings for all three dimensions and orientations to
% calculate bias/zero point and scale for each dimension.




% load a test dat set

% RP VGA with splitter 1920x1080, 60Hz (Win10 driver interface), 
%	Nvidia Control panel: eMotionST3: 60.00 Hz; DELL U2412M: 59.95Hz
%	60Hz EventIDE graphics mode, OLED reports 60.0Hz
%	-> photo diode implies 120/60Hz, Oscilloscope measured 60.24Hz
% -> ??? tight refresh time histograms BUT high latency ~50ms (3-4 frames)
test_session_id = '20200513T130845.A_AccXYZ.B_TestB.SCP_01.sessiondir';
% EventIDE touches first after ripple later before, that is hard to
% interpret and potentially driven by the acceleratio sensor "touching" the
% sensitive air-space too early/slowly.



% RP VGA with splitter 1920x1080, 60Hz (Win10 driver interface), 
%	Nvidia Control panel: eMotionST3: 60.00 Hz; DELL U2412M: 59.95Hz
%	60Hz EventIDE graphics mode, OLED reports 60.0Hz
%	-> photo diode implies 120/60Hz, Oscilloscope measured 60.24Hz
% -> ??? tight refresh time histograms BUT high latency ~50ms (3-4 frames)
test_session_id = '20200522T130417.A_AccXYZ.B_TestB.SCP_01';
% slow rotation from sensor PCP(z) aligned to gravity to PCB(x) aligned to
% gravity


% RP VGA with splitter 1920x1080, 60Hz (Win10 driver interface), 
%	Nvidia Control panel: eMotionST3: 60.00 Hz; DELL U2412M: 59.95Hz
%	60Hz EventIDE graphics mode, OLED reports 60.0Hz
%	-> photo diode implies 120/60Hz, Oscilloscope measured 60.24Hz
% -> ??? tight refresh time histograms BUT high latency ~50ms (3-4 frames)
% sensor PCB(x) aligned to gravity
test_session_id = '20200522T143126.A_AccXYZ.B_TestB.SCP_01';

test_session_id = '20200602T095621.A_None.B_Elmo.SCP_01';


% None VGA with splitter 1920x1080, 60Hz (Win10 driver interface), 
%	Nvidia Control panel: eMotionST3: 60.00 Hz; DELL U2412M: 59.95Hz
%	60Hz EventIDE graphics mode, OLED reports 60.0Hz
%	-> photo diode implies 60Hz
% -> ??? tight refresh time histograms BUT high latency ~50ms (3-4 frames)
% sensor PCB(x) aligned to gravity
test_session_id = '20200604T164637.A_TestA.B_OLEDVGA60HzLevel.SCP_01';




% None VGA with splitter 1920x1080, 60Hz (Win10 driver interface), 
%	Nvidia Control panel: eMotionST3: 60.00 Hz; DELL U2412M: 59.95Hz
%	60Hz EventIDE graphics mode, IIyama reports 60.0Hz
%	Iiyama HM204DT @ 60HZ, with phtodiode (Monitor Spot Detector, CRT/Pulse output)
%		in LCD/Level mode each pulse was only ~0.7ms long to short for the 2k sampling rate
%	-> photo diode implies 60Hz
% -> OKAY tight refresh time histograms BUT high latency ~50ms (3-4 frames)
% sensor PCB(x) aligned to gravity
test_session_id = '20200604T162529.A_TestA.B_CRTVGA60HzPulse.SCP_01';


% None VGA with splitter 1920x1080, 60Hz (Win10 driver interface), 
%	Nvidia Control panel: eMotionST3: 60.00 Hz; DELL U2412M: 59.95Hz
%	60Hz EventIDE graphics mode, IIyama reports 60.0Hz
%	Eyevis OLED @ 60Hz LCD/Level
%	-> photo diode implies 60Hz
% -> OKAY tight refresh time histograms BUT high latency ~50ms (3-4 frames)
% sensor PCB(x) aligned to gravity
test_session_id = '20200604T162529.A_TestA.B_CRTVGA60HzPulse.SCP_01';

%test_session_id = '20200716T123615.A_TestA.B_None.SCP_01';


% None VGA with splitter 1920x1080, 60Hz (Win10 driver interface), 
%	Nvidia Control panel: eMotionST3: 60.00 Hz; DELL U2412M: 59.95Hz
%	60Hz EventIDE graphics mode, IIyama reports 60.0Hz
%	Iiyama HM204DT @ 60HZ, with phtodiode (Monitor Spot Detector, CRT/Pulse output)
%	-> photo diode implies 60Hz
% -> OKAY tight refresh time histograms BUT high latency ~50ms (3-4 frames)
% sensor PCB(x) aligned to gravity
test_session_id = '20200717T120139.A_TestA.B_CRT60HzVGA.SCP_01';


test_session_id = '20200722T145419.A_SM.B_Elmo.SCP_01';


% Elmo VGA with splitter 1920x1080, 60Hz (Win10 driver interface), 
%	Nvidia Control panel: eMotionST3: 60.00 Hz; DELL U2412M: 59.95Hz
%	60Hz EventIDE graphics mode, IIyama reports 60.0Hz
%	Eyevis OLED @ 60Hz LCD/Level
%	-> photo diode implies 60Hz
% -> OKAY tight refresh time histograms BUT high latency ~50ms (3-4 frames)
% sensor PCB(x) aligned to gravity
test_session_id = '20201014T163327.A_Elmo.B_SM.SCP_01';





session_struct = fnLoadDataBySessionDir(test_session_id);


chan_names = {'EventIDE_TimeStamp', 'MotitorSpotDetector_LCD_level', 'RenderTriggerDO', 'AccelerationSensor_X', 'AccelerationSensor_Y', 'AccelerationSensor_Z'};
			
%LogHeader: {'Timestamp'  'Dev1/ai0'  'Dev1/ai1'  'Dev1/ai2'}
ADC_data = session_struct.signallog_NISignalFileWriterADC;
corr_time_list = ADC_data.data(:, ADC_data.cn.Tracker_corrected_EventIDE_TimeStamp);
uncorr_time_list = ADC_data.data(:, ADC_data.cn.UncorrectedEventIDE_TimeStamp);

% tmp = [diff(corr_time_list), diff(uncorr_time_list)];
% plot([diff(corr_time_list), diff(uncorr_time_list)]);
time_vec = uncorr_time_list;
%time_vec = corr_time_list;




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

if (isfield(trial_log, 'cn') && isfield(trial_log.cn, 'A_InitialFixationTouchTime_ms'))
	IF_touch_onset_list = trial_log.data(:, trial_log.cn.A_InitialFixationTouchTime_ms) ;
	IF_touch_offset_list = trial_log.data(:, trial_log.cn.A_InitialFixationAdjReleaseTime_ms);
	
	IF_touch_onset_list(IF_touch_onset_list == 0) = [];
	IF_touch_offset_list(IF_touch_offset_list == 0) = [];
else
	IF_touch_onset_list = [];
	IF_touch_offset_list = [];
end

IF_touch_onset_list = IF_touch_onset_list - time_offset;
IF_touch_offset_list = IF_touch_offset_list - time_offset;



%touch_dur = IF_touch_offset_list - IF_touch_onset_list;

% render events
if isfield(trial_log.Render, 'data')
	render_timestamps = trial_log.Render.data(:, trial_log.Render.cn.Timestamp);
	render_timestamps = render_timestamps - time_offset;
end

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
	if ~isfield(trial_log.Render, 'data')
		render_timestamps = pd_render_timestamps;
	end
else
	use_PhotoDiodeRenderer = 0;
	pd_render_timestamps = render_timestamps;
end

figure('Name', 'ADC Test');
subplot(3, 1, 1)
title(chan_names{2});
plot(time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai3));
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
plot(time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai0));
hold on
for i_render_timestamps = 1 : length(render_timestamps)
	plot([render_timestamps(i_render_timestamps), render_timestamps(i_render_timestamps)], y_lim, 'Color', [0 1 0]);
end

hold off
xlabel('Samples');

subplot(3, 1, 3)
title(chan_names{4});
plot(time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai1));
xlabel('Samples');


%sample_subset = (500000:1:length(time_vec));

figure('Name', 'RenderTrigger')
plot(time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai0)); % the photo diode signal
hold on
for i_render_timestamps = 1 : length(render_timestamps)
	plot([render_timestamps(i_render_timestamps), render_timestamps(i_render_timestamps)], y_lim, 'Color', [0 1 0]);
end
plot(time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai1), 'Color', [1 0 0]);

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
photo_diode_voltage = ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai0);
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
% the OLED operates at 120Hz so 
avg_interframe_delay_ms = mean(tmp_data(find(tmp_data <= 16 & tmp_data >= 5)));
refresh2frame_ratio = 2;	% the 120 Hz OLED only gets new inputs every other OLED-frame
% assume CRT @60Hz
if isnan(avg_interframe_delay_ms)
	avg_interframe_delay_ms = mean(tmp_data(find(tmp_data <= 20 & tmp_data >= 12)));
	refresh2frame_ratio = 1;
end


avg_screen_framerate = 1000/avg_interframe_delay_ms;
disp(['PhotoDiode pulses coming in at ~' num2str(avg_screen_framerate), ' Hz, with ', num2str(avg_interframe_delay_ms), 'ms inter pulse delay']);
% the OLED panel runds at ~ 120 Hz, so get the best matching 
disp(['Actual screen refreshes at ~' num2str((1/refresh2frame_ratio) * avg_screen_framerate), ' Hz, with ', num2str(2.0 * avg_interframe_delay_ms), 'ms inter pulse delay']);


% assume that at 2KHz sampling and 60Hz screen refresh and break is at
% least one frame
sampling_rate_hz = 2000;
if isnan(avg_screen_framerate)
	frame_rate_hz = 60.0;
else
	frame_rate_hz = ((1/refresh2frame_ratio) * avg_screen_framerate); % take the empirically measured frame rate instead?
end

samples_per_frame = sampling_rate_hz / frame_rate_hz;
switch refresh2frame_ratio
	case 1
		min_frames_per_gap = 3;
	case 2
		min_frames_per_gap = 1.5;
	otherwise
		min_frames_per_gap = 2;
end

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
plot(time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai0)); % the photo diode signal
hold on

% what is going on with the timestamps


plot(uncorr_time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai0), 'Color', [0 0 0.33]); % the photo diode signal


y_lim = get(gca(), 'YLim');
for i_render_timestamps = 1 : length(render_timestamps)
	plot([render_timestamps(i_render_timestamps), render_timestamps(i_render_timestamps)], y_lim, 'Color', [0 1 0]);
end
plot(time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai1), 'Color', [1 0 0]);
plot(uncorr_time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai1), 'Color', [0.33 0 0]);


for i_pd_block_onset_timestamp = 1 : length(pd_block_onset_timestamp_list)
	plot([pd_block_onset_timestamp_list(i_pd_block_onset_timestamp), pd_block_onset_timestamp_list(i_pd_block_onset_timestamp)], y_lim, 'Color', [1 0 1]);
end
for i_pd_block_offset_timestamp = 1 : length(pd_block_offset_timestamp_list)
	plot([pd_block_offset_timestamp_list(i_pd_block_offset_timestamp), pd_block_offset_timestamp_list(i_pd_block_offset_timestamp)], y_lim, 'Color', [0 0 0]);
end
xlim([time_vec(1+sample_offset), time_vec(sample_end)]);
hold off
xlabel('Samples');



% the accelerometer traces
figure('Name', 'ADC Test');
%subplot(3, 1, 1)
title(chan_names{2});
plot(time_vec(sample_subset), ADC_data.data(sample_subset, ADC_data.cn.Dev1_ai3));
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



% the accelerometer traces
figure('Name', 'ADC Acceleration data 333 mV/g, midpoint 166.5 mV');
%subplot(3, 1, 1)
title(chan_names{2});
my_sample_subset = (1:1:6000);
my_sample_subset = sample_subset;

last_touch_release_time = IF_touch_offset_list(end-1);
acc_delay_ms = 200;
proto_last_sample = find(time_vec >= (last_touch_release_time + acc_delay_ms));
last_sample = proto_last_sample(1);


first_touch_acq_time = IF_touch_onset_list(1);
acc_pre_delay_ms = 200;
proto_first_sample = find(time_vec >= (first_touch_acq_time - acc_delay_ms));
first_sample = proto_first_sample(1);

start_idx = 1;
start_idx = first_sample; % (larger than the chunk size of 5000)
end_idx = length(sample_subset);
end_idx = last_sample;

start_idx = 1;
end_idx = length(sample_subset);

my_sample_subset = (start_idx:1:end_idx); % avoid the initial junk 
cur_xvec = time_vec(my_sample_subset);

%plot(time_vec(my_sample_subset), ADC_data.data(my_sample_subset, ADC_data.cn.Dev1_ai2));
%plot(cur_xvec, ADC_data.data(my_sample_subset, ADC_data.cn.Dev1_ai0));
hold on
%plot(cur_xvec, ADC_data.data(my_sample_subset, ADC_data.cn.Dev1_ai1));
plot(cur_xvec, ADC_data.data(my_sample_subset, ADC_data.cn.Dev1_ai2));	% X
plot(cur_xvec, ADC_data.data(my_sample_subset, ADC_data.cn.Dev1_ai3));	% Y
plot(cur_xvec, ADC_data.data(my_sample_subset, ADC_data.cn.Dev1_ai4));	% Z

legend_list = chan_names(4:end);

y_lim = get(gca(), 'YLim');

for i_IFtouch_onset = 1 : length(IF_touch_onset_list)
	plot([IF_touch_onset_list(i_IFtouch_onset), IF_touch_onset_list(i_IFtouch_onset)], y_lim, 'Color', [0 1 0]);
end
legend_list{end+1} = 'IFT_touch_onset';
for i_IFtouch_offset = 1 : length(IF_touch_offset_list)
	plot([IF_touch_offset_list(i_IFtouch_offset), IF_touch_offset_list(i_IFtouch_offset)], y_lim, 'Color', [1 0 1]);	
end
legend_list{end+1} = 'IFT_touch_offset';

legend(legend_list, 'Interpreter', 'none');

hold off
xlabel('Samples');
y_lim = get(gca(), 'YLim');


% get velocity?
acc_x = ADC_data.data(:, ADC_data.cn.Dev1_ai2);
acc_y = ADC_data.data(:, ADC_data.cn.Dev1_ai3);
acc_z = ADC_data.data(:, ADC_data.cn.Dev1_ai4);




% these need to be filtered
% low pass based on sampling frequency (2kHz) and impulse response function
% of the DE-ACCM3D (~500 Hz)
% high pass to reduce slow transients, below 0.5 Hz?

% bpFilt = designfilt('bandpassfir','FilterOrder',300, ...
%          'CutoffFrequency1',10,'CutoffFrequency2',500, ...
%          'SampleRate',2000);
% fvtool(bpFilt)

% bpFilt = designfilt('lowpassiir','FilterOrder',20, ...
%          'HalfPowerFrequency1',0.0001,'HalfPowerFrequency2',250, ...
%          'SampleRate',2000);
	 
lpFilt = designfilt('lowpassiir', ...        % Response type
       'PassbandFrequency',250, ...     % Frequency constraints
       'StopbandFrequency',300, ...
       'PassbandRipple',1, ...          % Magnitude constraints
       'StopbandAttenuation',55, ...
       'DesignMethod','ellip', ...      % Design method
       'MatchExactly','passband', ...   % Design method options
       'SampleRate',2000);               % Sample rate
%fvtool(lpFilt)	 
	 

hpFilt = designfilt('highpassiir','FilterOrder',20, ...
         'PassbandFrequency', 1,'PassbandRipple',0.2, ...
         'SampleRate',2000);
%fvtool(hpFilt)
%fvtool(lpFilt)	 


% acc.x = acc_x;
% acc.y = acc_y;
% acc.z = acc_z;

orig_acc_xyz = [acc_x, acc_y, acc_z];
% get the length of the euclidian acceleration vector
orig_acc_3d = sqrt(orig_acc_xyz(:,1).^2 + orig_acc_xyz(:,2).^2 + orig_acc_xyz(:,3).^2);

% TODO properly scale & debias each channel
x_max = 1.97;
x_min = 1.3;
y_max = 1.97;
y_min = 1.3;
z_max = 2.07;
z_min = 1.42;

x_zero = x_min + ((x_max-x_min) * 0.5);
y_zero = y_min + ((y_max-y_min) * 0.5);
z_zero = z_min + ((z_max-z_min) * 0.5);

x_scale = (x_max-x_min) * 0.5;
y_scale = (y_max-y_min) * 0.5;
z_scale = (z_max-z_min) * 0.5;



% debias the acceleration signals
%acc_xyz = [(acc_x - (x_max-x_min)*0.5), (acc_y - (y_max-y_min)*0.5), (acc_z - (z_max-z_min)*0.5)];
acc_xyz = [(acc_x - x_zero)/x_scale, (acc_y - y_zero)/y_scale, (acc_z - z_zero)/z_scale];


orig_acc_3d = sqrt(acc_xyz(:,1).^2 + acc_xyz(:,2).^2 + acc_xyz(:,3).^2);


% remove gravity's acceleration

%pre_test_gravity = mean(acc_3d(6000:6000+(2000*120)));
%post_test_gravity = mean(acc_3d(end-(2000*60):end-20000));

around_test_gravity = mean([orig_acc_3d(6000:6000+(2000*120)); orig_acc_3d(end-(2000*60):end-20000)]);
acc_3d = orig_acc_3d - around_test_gravity;


figure('Name', '3d acceleration magnitude data');
hold on
plot(cur_xvec, acc_3d(my_sample_subset));
fn_plot_eventIDE_touch_acq_rel_times(IF_touch_onset_list, IF_touch_offset_list, []);
xlabel('Samples time');
y_lim = get(gca(), 'YLim');
hold off

% try to get rid of "HF" noise
filt_acc_xyz = [filtfilt(lpFilt, acc_xyz(:,1)), filtfilt(lpFilt, acc_xyz(:,2)), filtfilt(lpFilt, acc_xyz(:,3))];
% get the length of the euclidian acceleration vector
orig_filt_acc_3d = sqrt(filt_acc_xyz(:,1).^2 + filt_acc_xyz(:,2).^2 + filt_acc_xyz(:,3).^2);

around_test_gravity = mean([orig_filt_acc_3d(6000:6000+(2000*120)); orig_filt_acc_3d(end-(2000*60):end-20000)]);
filt_acc_3d = orig_filt_acc_3d - around_test_gravity;

figure('Name', 'filtered 3d acceleration magnitude data');
hold on
plot(cur_xvec, filt_acc_3d(my_sample_subset));
fn_plot_eventIDE_touch_acq_rel_times(IF_touch_onset_list, IF_touch_offset_list, []);
xlabel('Samples time');
y_lim = get(gca(), 'YLim');
hold off


% integrate acceleration to velocity
% coarsely debias
tmp_acc = filtfilt(hpFilt, filt_acc_3d);
% 
tmp_acc_mag = abs(tmp_acc);

figure('Name', 'halfway rectified 3d acceleration magnitude data');
hold on
plot(cur_xvec, tmp_acc_mag(my_sample_subset));
fn_plot_eventIDE_touch_acq_rel_times(IF_touch_onset_list, IF_touch_offset_list, []);
xlabel('Samples time');
set(gca(), 'YLim', [0, 1]);
y_lim = get(gca(), 'YLim');
hold off


% try thresholding this?





vel_3d = cumsum(filtfilt(hpFilt, tmp_acc));

vel_3d = cumsum(filt_acc_3d);
%vel_3d = cumsum(filtfilt(hpFilt, vel_3d));



figure('Name', 'filtered 3d velocity magnitude data');
hold on
plot(cur_xvec, vel_3d(my_sample_subset));
y_lim = get(gca(), 'YLim');
fn_plot_eventIDE_touch_acq_rel_times(IF_touch_onset_list, IF_touch_offset_list, y_lim);
xlabel('Samples time');
%set(gca(), 'YLim', []);
y_lim = get(gca(), 'YLim');
hold off





% figure('Name', '3d acceleration magnitude data');
% hold on
% plot(cur_xvec, acc_3d(my_sample_subset));
% fn_plot_eventIDE_touch_acq_rel_times(IF_touch_onset_list, IF_touch_offset_list, []);
% xlabel('Samples time');
% y_lim = get(gca(), 'YLim');
% hold off

% now we need to get rid of 
filt_acc_3d = filtfilt(bpFilt, acc_3d);
figure('Name', 'filtered 3d acceleration magnitude data');
hold on
plot(cur_xvec, filt_acc_3d(my_sample_subset));
fn_plot_eventIDE_touch_acq_rel_times(IF_touch_onset_list, IF_touch_offset_list, []);
xlabel('Samples time');
y_lim = get(gca(), 'YLim');
hold off

figure('Name', 'filtered acceleration data');
hold on
fil_acc_xyz = zeros(size(acc_xyz));
for i_dim = 1 : size(acc_xyz, 2)
	fil_acc_xyz(:, i_dim) = filtfilt(bpFilt, acc_xyz(:, i_dim));
	plot(cur_xvec, fil_acc_xyz(my_sample_subset, i_dim));
end
fn_plot_eventIDE_touch_acq_rel_times(IF_touch_onset_list, IF_touch_offset_list, []);
xlabel('Samples time');
y_lim = get(gca(), 'YLim');
hold off

figure('Name', 'filtered velocity: integrated filtered acceleration data');
hold on
filt_int_fil_vel_xyz = zeros(size(acc_xyz));
for i_dim = 1 : size(acc_xyz, 2)
	filt_int_fil_vel_xyz(:, i_dim) = cumsum(fil_acc_xyz(:, i_dim));
	%filt_int_fil_vel_xyz(:, i_dim) = filtfilt(bpFilt, cumsum(fil_acc_xyz(:, i_dim)));
	plot(cur_xvec, filt_int_fil_vel_xyz(my_sample_subset, i_dim));
end
fn_plot_eventIDE_touch_acq_rel_times(IF_touch_onset_list, IF_touch_offset_list, []);
xlabel('Samples time');
y_lim = get(gca(), 'YLim');
hold off

figure('Name', 'filtered positiom: integrated filtered velocity data');
hold on
filt_int_fil_pos_xyz = zeros(size(acc_xyz));
for i_dim = 1 : size(acc_xyz, 2)
	filt_int_fil_pos_xyz(:, i_dim) = cumsum(detrend(filt_int_fil_vel_xyz(:, i_dim)));
	%filt_int_fil_pos_xyz(:, i_dim) = filtfilt(bpFilt, cumsum(filt_int_fil_vel_xyz(:, i_dim)));
	plot(cur_xvec, filt_int_fil_pos_xyz(my_sample_subset, i_dim));
end
fn_plot_eventIDE_touch_acq_rel_times(IF_touch_onset_list, IF_touch_offset_list, []);
xlabel('Samples time');
y_lim = get(gca(), 'YLim');
hold off


%clean up acceleration:
detrend_xvec= cur_xvec(120000:end-120000);
[p, S, mu] = polyfit(acc_x(120000:end-120000), detrend_xvec, 0);
cur_trend = polyval(p, cur_xvec,[], mu);
detrended_acc_x = acc_x - cur_trend;

[p, S, mu] = polyfit(acc_y(120000:end-120000), detrend_xvec, 0);
cur_trend = polyval(p, cur_xvec,[], mu);
detrended_acc_y = acc_y - cur_trend;

[p, S, mu] = polyfit(acc_z(120000:end-120000), detrend_xvec, 0);
cur_trend = polyval(p, cur_xvec,[], mu);
detrended_acc_z = acc_z - cur_trend;

figure; 
%plot(cur_xvec, cur_trend);
hold on
plot(cur_xvec, acc_y);
plot(cur_xvec, detrended_acc_y);



% the accelerometer traces
figure('Name', 'ADC Acceleration data 333 mV/g, midpoint 166.5 mV');
%subplot(3, 1, 1)
title(chan_names{2});
my_sample_subset = (1:1:6000);
my_sample_subset = sample_subset;

my_sample_subset = sample_subset;
cur_xvec = time_vec(my_sample_subset);

%plot(time_vec(my_sample_subset), ADC_data.data(my_sample_subset, ADC_data.cn.Dev1_ai2));
%plot(cur_xvec, ADC_data.data(my_sample_subset, ADC_data.cn.Dev1_ai0));
hold on
%plot(cur_xvec, ADC_data.data(my_sample_subset, ADC_data.cn.Dev1_ai1));
plot(cur_xvec, detrended_acc_x);	% X
plot(cur_xvec, detrended_acc_y);	% Y
plot(cur_xvec, detrended_acc_z);	% Z

legend_list = chan_names(4:end);

y_lim = get(gca(), 'YLim');

for i_IFtouch_onset = 1 : length(IF_touch_onset_list)
	plot([IF_touch_onset_list(i_IFtouch_onset), IF_touch_onset_list(i_IFtouch_onset)], y_lim, 'Color', [0 1 0]);
end
% legend_list{end+1} = 'IFT_touch_onset';
for i_IFtouch_offset = 1 : length(IF_touch_offset_list)
	plot([IF_touch_offset_list(i_IFtouch_offset), IF_touch_offset_list(i_IFtouch_offset)], y_lim, 'Color', [1 0 1]);	
end
% legend_list{end+1} = 'IFT_touch_offset';

legend(legend_list, 'Interpreter', 'none');

hold off
xlabel('Samples');
y_lim = get(gca(), 'YLim');




% get velocity?
int_acc_x = cumsum(ADC_data.data(:, ADC_data.cn.Dev1_ai2) - 3.33*0.5);
int_acc_y = cumsum(ADC_data.data(:, ADC_data.cn.Dev1_ai3) - 3.33*0.5);
int_acc_z = cumsum(ADC_data.data(:, ADC_data.cn.Dev1_ai4) - 3.33*0.5);


figure('Name', 'ADC Velocity by axis data 333 mV/g, midpoint 166.5 mV');

%plot(time_vec(my_sample_subset), ADC_data.data(my_sample_subset, ADC_data.cn.Dev1_ai2));
%plot(cur_xvec, ADC_data.data(my_sample_subset, ADC_data.cn.Dev1_ai0));
hold on
%plot(cur_xvec, ADC_data.data(my_sample_subset, ADC_data.cn.Dev1_ai1));
plot(cur_xvec, int_acc_x(my_sample_subset));	% X
plot(cur_xvec, int_acc_y(my_sample_subset));	% Y
plot(cur_xvec, int_acc_z(my_sample_subset));	% Z

y_lim = get(gca(), 'YLim');

for i_IFtouch_onset = 1 : length(IF_touch_onset_list)
	plot([IF_touch_onset_list(i_IFtouch_onset), IF_touch_onset_list(i_IFtouch_onset)], y_lim, 'Color', [0 1 0]);
end
%legend_list{end+1} = 'IFT_touch_onset';
for i_IFtouch_offset = 1 : length(IF_touch_offset_list)
	plot([IF_touch_offset_list(i_IFtouch_offset), IF_touch_offset_list(i_IFtouch_offset)], y_lim, 'Color', [1 0 1]);	
end
%legend_list{end+1} = 'IFT_touch_offset';

legend(legend_list, 'Interpreter', 'none');

hold off
xlabel('Samples');
y_lim = get(gca(), 'YLim');



% these need to be filtered
% low pass based on sampling frequency (2kHz) and impulse response function
% of the DE-ACCM3D (~500 Hz)
% high pass to reduce slow transients, below 0.5 Hz?

bpFilt = designfilt('bandpassfir','FilterOrder',300, ...
         'CutoffFrequency1',1,'CutoffFrequency2',500, ...
         'SampleRate',2000);
fvtool(bpFilt)

bpFilt = designfilt('bandpassiir','FilterOrder',200, ...
         'HalfPowerFrequency1',1,'HalfPowerFrequency2',500, ...
         'SampleRate',2000);
fvtool(bpFilt)


filt_int_acc_x = filtfilt(bpFilt, int_acc_x);
filt_int_acc_y = filtfilt(bpFilt, int_acc_y);
filt_int_acc_z = filtfilt(bpFilt, int_acc_z);



figure('Name', 'ADC bandfiltered Velocity by axis data 333 mV/g, midpoint 166.5 mV');

%plot(time_vec(my_sample_subset), ADC_data.data(my_sample_subset, ADC_data.cn.Dev1_ai2));
%plot(cur_xvec, ADC_data.data(my_sample_subset, ADC_data.cn.Dev1_ai0));
hold on
%plot(cur_xvec, ADC_data.data(my_sample_subset, ADC_data.cn.Dev1_ai1));
plot(cur_xvec, filt_int_acc_x(my_sample_subset));	% X
plot(cur_xvec, filt_int_acc_y(my_sample_subset));	% Y
%plot(cur_xvec, filt_int_acc_z(my_sample_subset));	% Z

y_lim = get(gca(), 'YLim');

for i_IFtouch_onset = 1 : length(IF_touch_onset_list)
	plot([IF_touch_onset_list(i_IFtouch_onset), IF_touch_onset_list(i_IFtouch_onset)], y_lim, 'Color', [0 1 0]);
end
%legend_list{end+1} = 'IFT_touch_onset';
for i_IFtouch_offset = 1 : length(IF_touch_offset_list)
	plot([IF_touch_offset_list(i_IFtouch_offset), IF_touch_offset_list(i_IFtouch_offset)], y_lim, 'Color', [1 0 1]);	
end
%legend_list{end+1} = 'IFT_touch_offset';

legend(legend_list, 'Interpreter', 'none');

hold off
xlabel('Samples');
y_lim = get(gca(), 'YLim');

end


% function [cur_fh] = fn_plot_over_time(start_ts_idx, end_ts_idx, time_vec, pd_data, )
% 
% 
% 
% end

function [] = fn_plot_eventIDE_touch_acq_rel_times( IF_touch_onset_list, IF_touch_offset_list, y_lim )


if isempty(y_lim)
	y_lim = get(gca(), 'YLim');
end

for i_IFtouch_onset = 1 : length(IF_touch_onset_list)
	plot([IF_touch_onset_list(i_IFtouch_onset), IF_touch_onset_list(i_IFtouch_onset)], y_lim, 'Color', [0 1 0]);
end
% legend_list{end+1} = 'IFT_touch_onset';
for i_IFtouch_offset = 1 : length(IF_touch_offset_list)
	plot([IF_touch_offset_list(i_IFtouch_offset), IF_touch_offset_list(i_IFtouch_offset)], y_lim, 'Color', [1 0 1]);	
end
% legend_list{end+1} = 'IFT_touch_offset';
end
