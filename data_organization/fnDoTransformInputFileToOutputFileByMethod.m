function [status, out_struct] = fnDoTransformInputFileToOutputFileByMethod(input_file_FQN, output_file_FQN, method_string)
%FNDOTRANSFORMINPUTFILETOOUTPUTFILEBYMETHOD transform inputFQN into
%outputFQN using the requested method. This is a wrapper around different
%file procesing functions in matlab to allow easier switching between
%different operations.
%   Detailed explanation goes here

out_struct.status = 1;  % 1 success 0 failure
out_struct.message = '';
out_struct.messageid = '';

% depending on the method either move/rename or copy
switch lower(method_string)
    case {'rename', 'move'}
        disp(['Moving: ', input_file_FQN]);
        disp(['    to: ', output_file_FQN]);
        [out_struct.status, out_struct.message, out_struct.messageid] = movefile(input_file_FQN, output_file_FQN);
    case 'copy'
        disp(['Copying: ', input_file_FQN]);
        disp(['     to: ', output_file_FQN]);
        [out_struct.status, out_struct.message, out_struct.messageid] = copyfile(input_file_FQN, output_file_FQN);
    case {'none', 'ignore'}
        disp(['Ignoring: ', input_file_FQN]);
        disp(['      to: ', output_file_FQN]);
    case {'fail', 'break'}
        % this is for debugging
        disp(['Failing: ', input_file_FQN]);
        disp(['     to: ', output_file_FQN]);
        out_struct.status = 0;
    case {'gzip', 'gzip_copy'}
        disp(['Gzipping : ', input_file_FQN]);
        disp(['(copy) to: ', [output_file_FQN, '.gz']]);
        gzip(input_file_FQN, fileparts(output_file_FQN));
        % did we actually write the target file
        if ~exist([output_file_FQN, '.gz'], 'file') || isdir([output_file_FQN, '.gz'])
            out_struct.status = 0;
        end
    case {'gzip_move'}
        disp(['Gzipping : ', input_file_FQN]);
        disp(['(move) to: ', [output_file_FQN, '.gz']]);
        gzip(input_file_FQN, fileparts(output_file_FQN));
        if ~exist([output_file_FQN, '.gz'], 'file') || isdir([output_file_FQN, '.gz'])
            out_struct.status = 0;
        end
        delete(input_file_FQN);
    otherwise
        error(['Processing method: ', method_string, ' not handled yet...']);
end

% to allow easier use of this function as boolean
status = out_struct.status;

return
end

