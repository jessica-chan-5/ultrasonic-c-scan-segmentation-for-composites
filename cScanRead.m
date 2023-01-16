function cScanRead(fileName,delimiter,inFolder,outFolder)
% Converts C-scan from 2D .csv file to 3D .mat file. Trims non-numeric
% values and takes absolute value of A-scan signal.
% 
% Inputs:
%   fileName : Name of .csv C-scan input file
%   delimiter: Sequence of characters separating each value
%              (i.e. "," or " ")
%   inFile   : Folder path to .csv C-scan input file
%   outFile  : Folder path to .mat C-scan output file
    
% Concatenate file names/paths
inFile = strcat(inFolder,"\",fileName,".csv");
outFile = strcat(outFolder,"\",fileName,"-cScan.mat");

% Read C-scan data from input .csv file
rawCScan = readmatrix(inFile,'Delimiter',delimiter,'TrimNonNumeric',true);

% Calculate number of A-scans along x (row) and y (col) scan directions
% Add 1 to change indexing from starting at 0 to starting at 1
row = rawCScan(end,1) + 1;
col = rawCScan(end,2) + 1;

% Calculate # of data points per A-scan
% Subtract 2 b/c first two values of each line are (row, col) info
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
save(outFile,'cScan','-mat');

end
