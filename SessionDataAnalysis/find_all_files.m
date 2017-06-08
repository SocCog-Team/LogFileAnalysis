function fileList = find_all_files(folder, filePattern)
  % Get list of all subfolders.
  allSubFolders = genpath(folder);
  % Parse into a cell array.
  remain = allSubFolders;
  folderNameList = {};
  while true
    [singleSubFolder, remain] = strtok(remain, ';');
    if isempty(singleSubFolder)
      break;
    end
    folderNameList = [folderNameList singleSubFolder];
  end
  nFolder = length(folderNameList);
  
  fileList = {};
  % Process all files in those folders.
  for iFolder = 1:nFolder
    % Get this folder and print it out.
    thisFolder = folderNameList{iFolder};
    fprintf('Processing folder %s\n', thisFolder);
	
    % Get ALL files.
    currentPattern = [thisFolder, '\\', filePattern];
    baseFileNames = dir(currentPattern);	
    nFile = length(baseFileNames);
    if nFile >= 1
      % Go through all those files.
      for iFile = 1:nFile
        fullFileName = fullfile(thisFolder, baseFileNames(iFile).name);
        fprintf('     Processing file %s\n', fullFileName);
        fileList = [fileList fullFileName];
      end
    else
      fprintf('     Folder %s has no files in it.\n', thisFolder);
    end
  end  
end
