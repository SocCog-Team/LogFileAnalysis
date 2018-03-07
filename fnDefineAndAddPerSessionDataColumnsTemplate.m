function [ data_struct ] = fnDefineAndAddPerSessionDataColumns( data_struct, current_sessionID )
%FNDEFINEANDADDPERSESSIONDATACOLUMNS if this file exists in the same
%directory as a triallog file the log parser will call this and pass in the
%main trial data_struct to allow addition of more per-trial columns. Since
%the name is generic each of these files need a local definition of the
%target_sessionID and only if both match run the rest
%   Copy this Template to a sessiondir and edit target_sessionID to match
%   that sessionID, also add the actual data that should be added.

[mfilename_dir, mfilename_name] = fileparts(mfilename('fullpath'));

if (nargin<2)
   disp([mfilename_name ' called without specifying the currenly processed triallog sessionID.']);
   return
end
if (nargin<1)
   disp([mfilename_name ' called without specifying the data-struct.']);
   return
end

% the following needs to be manually set and it should match the sessionID
% as described in the LOGGING section of the trial log file:
% LOGGING.SessionLogFileName: 20171213T112521.A_SM.B_Curius.SCP_01
target_sessionID = '20180126T132629.A_SM.B_Curius.SCP_01';

if ~strcmp(target_sessionID, current_sessionID)
    disp(['The currently processed session''s ID (', current_sessionID, ') does not match the target_sessionID (', target_sessionID, ') defined in ', fullfile(mfilename_dir, [mfilename_name, mfilename_ext])]);
    return
else
    disp(['Processing extra columns for sessionID: ', current_sessionID, ' (', fullfile(mfilename_dir, [mfilename_name, '.m']),')']);
end

% okay now actually create data columns and fill them

n_trials = size(data_struct.data, 1);
c_cols = size(data_struct.data, 2);


% EDIT START: FILL local_header and local_data here
local_header = {'paper_between_AB', 'A_invisible', 'B_invisible'};

local_data = zeros([n_trials length(local_header)]);

Range_start_idx_list = {201};
Range_end_idx_list = {401};

active_trials_idx = [];
for i_range = 1 : length(Range_start_idx_list)
    current_active_trials_idx = (Range_start_idx_list{i_range}:1:Range_end_idx_list{i_range});
    
    active_trials_idx = [active_trials_idx, current_active_trials_idx];
    
end

%active_trials_idx = (151:1:360-1);

local_data(active_trials_idx, 1) = 1;
local_data(active_trials_idx, 2) = 1;
local_data(active_trials_idx, 3) = 1;



% EDIT END:


% now add the new column to the data structure
data_struct = fn_handle_data_struct('add_columns', data_struct, local_data, local_header);

return
end



