function readcscan(filename,delim,infolder,outfolder)
%READCSCAN Convert C-scan from .csv to .mat file. 
%    READCSCAN(FILENAME,DELIM,INFOLDER,OUTFOLDER) Reads in C-scan from .csv
%    file using readmatrix with designated delimiter. Trims non-numeric 
%    values and takes absolute value of A-scan signals. Reshapes into 3D 
%    matrix with dimensions row by col by number of data points per A-scan.
%    Saves as .mat file.
%
%    Inputs:
%
%    FILENAME: Name of .csv C-scan file to read
%    DELIM: Field delimiter characters (i.e. "," or " ")
%    INFOLDER: Folder path to read .csv C-scan input file
%    OUTFOLDER: Folder path to write .mat C-scan output file

% Read C-scan .csv file
inpath = strcat(infolder,'\',filename,'.csv');
rawcscan = readmatrix(inpath,'Delimiter',delim,'TrimNonNumeric',true);

% Calculate # A-scans along row & col scan directions, add 1 to adjust 
% indexing to start @ 1
row = rawcscan(end,1) + 1;
col = rawcscan(end,2) + 1;

% Calculate # of data points/A-scan, subtract 2 b/c first 2 values of each 
% line are (row, col) info
pts = size(rawcscan,2)-2;

% Reshape C-scan into 3D matrix
cScan = zeros(row,col,pts);

% Take abs value & remove redundant (row, col) info
for i = 1:row
    for j = 1:col
        cScan(i,j,:) = abs(rawcscan(j+(i-1)*col,3:end));
    end
end

% Save 3D matrix to .mat file
outpath = strcat(outfolder,'\',filename,'-cscan.mat');
save(outpath,'cScan','-mat');

end
