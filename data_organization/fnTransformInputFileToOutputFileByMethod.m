function [status] = fnTransformInputFileToOutputFileByMethod(input_file_FQN, output_file_FQN, method_string)
%FNTRANSFORMINPUTFILETOOUTPUTFILEBYMETHOD wrapps around fnDoTransformInputFileToOutputFileByMethod
%to handle a few unfortunate possibilities, like windows path length
%exceeded.
%   Detailed explanation goes here

% Use method to transform input_file to output_file

persistent AssignedWinDriveLettersList input_subst_drive_letter output_subst_drive_letter

if (ispc)
    % only do these things once...
    if isempty(AssignedWinDriveLettersList)
        AssignedWinDriveLettersList = fnGetWindowsDriveLetterList();
    end
    if isempty(input_subst_drive_letter)
        input_subst_drive_letter = fnSubstDrivePathToNextFreeDriveLetter(input_file_FQN, 'SESSIONLOGS', 'delete');
    end
    if isempty(output_subst_drive_letter)
        output_subst_drive_letter = fnSubstDrivePathToNextFreeDriveLetter(output_file_FQN, 'SESSIONLOGS', 'delete');
    end
end

%TODO: make sure that the output_directory actually exists
% [out_path, ~, ~] = fileparts(output_file_FQN)
%if isempty(dir(out_path))
%    mkdir(out_path)
%end

% instead of trying to gzip a file twice, just copy/move it
[in_path, in_name, in_ext] = fileparts(input_file_FQN);
if (length(in_path) > 247)
    % with only one level of substs we can not actually deal with that so
    % error out, see https://msdn.microsoft.com/en-us/library/aa365247%28VS.85%29.aspx?f=255&MSPPError=-2147217396#maxpath
    error('Encountered input path > 247 characters, too long to currently handle...');
end

[out_path, out_name, out_ext] = fileparts(output_file_FQN);
if (length(out_path) > 247)
    % with only one level of substs we can not actually deal with that so
    % error out, see https://msdn.microsoft.com/en-us/library/aa365247%28VS.85%29.aspx?f=255&MSPPError=-2147217396#maxpath
    error('Encountered output path > 247 characters, too long to currently handle...');
end


% make sure the output path exists
if ~strcmp(method_string, 'ignore') && ~isdir(out_path)
    mkdir(out_path);
end

if strcmp(in_ext, '.gz')
    switch lower(method_string)
        case {'gzip', 'gzip_copy'}
            disp('Input file is already gzipped, copying instead of zipping again.');
            method_string = 'copy';
        case {'gzip_move'}
            disp('Input file is already gzipped, moving instead of zipping again.');
            method_string = 'move';
    end
end


% now try to process the files
[status, cmd_output] = fnDoTransformInputFileToOutputFileByMethod(input_file_FQN, output_file_FQN, method_string);

if (ispc) && (status == 0)
    % the initial attempt at transfering the file failed, if on windows
    % this might be related to the path length limit,
    % windows seems to enforce that absolute filenames (including the drive
    % letter) are <= 260 characters long, this is less than ideal, but
    % can be worked around by using the subst command to turn the over-long
    % paths into short drive letters.
    
    if ((length(output_file_FQN) > 259) || ((length(input_file_FQN) > 259)))
        disp(['The initial attempt to process ', input_file_FQN, ' failed!']);
        disp('We encountered path component(s) larger than windows'' traditional limit of ~260 characters.');
        disp(['Input FQN length: ', num2str(length(input_file_FQN)), '; Output FQN length: ', num2str(length(output_file_FQN))]);
        
        
        %[in_path, in_name, in_ext] = fileparts(input_file_FQN);
        if ~isempty(input_subst_drive_letter) && (length(input_file_FQN) > 260)
            disp(['Substituting ', input_subst_drive_letter, ' for ', in_path]);
            [subst_status, subst_output] = system(['subst ', input_subst_drive_letter, ' ', in_path]);
            tmp_input_file_FQN = fullfile(input_subst_drive_letter, [in_name, in_ext]);
        else
            tmp_input_file_FQN = input_file_FQN;
        end
        
        %[out_path, out_name, out_ext] = fileparts(output_file_FQN);
        if ~isempty(output_subst_drive_letter) && (length(output_file_FQN) > 260)
            disp(['Substituting ', output_subst_drive_letter, ' for ', out_path]);
            [subst_status, subst_output] = system(['subst ', output_subst_drive_letter, ' ', out_path]);
            tmp_output_file_FQN = fullfile(output_subst_drive_letter, [out_name, out_ext]);
        else
            tmp_output_file_FQN = output_file_FQN;
        end
        % now try again
        [status, cmd_output] = fnDoTransformInputFileToOutputFileByMethod(tmp_input_file_FQN, tmp_output_file_FQN, method_string);
        
        % clean up the subst junk
        if ~isempty(input_subst_drive_letter) && (length(input_file_FQN) > 260)
            [subst_status, subst_output] = system(['subst ', input_subst_drive_letter, ' /d']);
            tmp_input_file_FQN = [];
        end
        
        if ~isempty(output_subst_drive_letter) && (length(output_file_FQN) > 260)
            [subst_status, subst_output] = system(['subst ', output_subst_drive_letter, ' /d']);
            tmp_output_file_FQN = [];
        end
        
        
    end
end

if ~status
    if strcmp(method_string, 'fail')
        disp(['Succeeded to ', method_string, ' ', input_file_FQN, ' to ', output_file_FQN]);
    else
        disp(['Failed to ', method_string, ' ', input_file_FQN, ' to ', output_file_FQN]);
        keyboard ; % use dbcont to resume execution
    end
end

return
end

