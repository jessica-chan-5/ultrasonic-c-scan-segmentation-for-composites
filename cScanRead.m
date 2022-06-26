function cScanRead(inFile,outFile)
% Reads .csv file format C-scan and saves C-scan as .mat file
% 
% Inputs:
%   inFile : Name of .csv C-scan input file
%   outFile: Name of .mat TOF output file
%

    % Read C-scan data from input .csv file
    cScan = readmatrix(inFile,'Delimiter','   ','TrimNonNumeric',true);
    % Save C-scan to .mat file
    save(strcat(outFile,"-cScan.mat"),'cScan','-mat');

    sampleName = inFile{1}(7:end-4);
    disp(sampleName);

end
