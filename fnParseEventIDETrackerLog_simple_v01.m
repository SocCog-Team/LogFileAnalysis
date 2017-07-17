function ds = fnParseEventIDETrackerLog_simple_v01(logfile_path,logfile_version)
% https://de.mathworks.com/help/stats/dataset.html
% simple and quick reading of EventIDE eyetracker log without loop
% Example:  
% ds = fnParseEventIDETrackerLog_simple_v01('S:\taskcontroller\DAG-3\PrimatarData\Cornelius_20170714_1336_incomplete\TrackerLog--ArringtonTracker--2017-14-07--13-36.txt','Primatar_20170714');


SpecialCases = [];
switch logfile_version,
	
	case 'Primatar_20170714'
		n_skip_lines = 3; % header lines
		delimiter = ';';
		format = '%f%f%f%f%f%f%f%f%f%d%s%s%s%f%d%f%f%f%f'; 
		% 19 columns
		% EventIDE TimeStamp;Gaze X;Gaze Y;Gaze Theta;Gaze R;Gaze CX;Gaze CY;Gaze CVX;Gaze CVY;Gaze Validity;Current Event;GLM Coefficients;User Field;Tracker Time Stamp;Is Sample Valid;Eye Raw X;Eye Raw Y;Eye Pupil Size X;Eye Pupil Size Y;
		% special cases:
		SpecialCases.GLM_Coefficients = true;
		
		
end

ds = dataset('File',logfile_path,'HeaderLines',n_skip_lines,'Delimiter',delimiter,'ReadVarNames',true,'ReadObsNames',false,'Format',format);

% deal with fields containing multiple variables
if ~isempty(SpecialCases),
	SpecialCasesFields = fieldnames(SpecialCases);
	
	for k = 1:length(SpecialCasesFields),
		switch SpecialCasesFields{k},
			
			case 'GLM_Coefficients'
				C = textscan(char(ds.GLM_Coefficients)','GainX=%f OffsetX=%f GainY=%f OffsetY=%f');
				ds.GLM_GainX	= C{1};
				ds.GLM_OffsetX	= C{2};
				ds.GLM_GainY	= C{3};
				ds.GLM_OffsetY	= C{4};	
				
		end
		
	end
	
end

