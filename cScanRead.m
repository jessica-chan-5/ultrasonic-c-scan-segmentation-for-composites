function cScanRead(inFile,outFile)
% Reads .csv file format C-scan and saves 3D matrix C-scan as .mat file
% 
% Inputs:
%   inFile : Name of .csv C-scan input file
%   outFile: Name of .mat TOF output file

    % Read C-scan data from input .csv file
    rawCScan = readmatrix(inFile,'Delimiter','   ','TrimNonNumeric',true);

    % Calculate number of scans along x (row) and y (col) scan directions
    % Add 1 for x and 2 for y because the last line begins with (row,col)
    col = rawCScan(end,2) + 1;
    row = rawCScan(end,1) + 1;
    
    % Calculate # of A-scans and # of data points per A-scan
    % Subtract 2 because 1st two values of each line are (row, col) info
    dataPointsPerAScan = size(rawCScan,2)-2;

    % Reshape C-scan data into 3D matrix
    % Take abs value and remove (row, col) info b/c redundant
    cScan = zeros(row,col,dataPointsPerAScan);

    for i = 1:row
        for j = 1:col
            cScan(i,j,:) = abs(rawCScan((i-1)*col+j,3:end));
        end
    end
    
    % Save C-scan to .mat file
    save(strcat(outFile,"-cScan.mat"),'cScan','-mat');

end
