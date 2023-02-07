function readcscan(filename,delim,infolder,outfolder,drow,dcol)
%READCSCAN Convert C-scan from .csv to .mat file. 
%    READCSCAN(FILENAME,DELIM,INFOLDER,OUTFOLDER,DROW,DCOL) Reads in C-scan
%    from .csv file using readmatrix with designated delimiter. Trims 
%    non-numeric values and takes absolute value of A-scan signals. 
%    Reshapes into 3D matrix with dimensions row by col by number of data 
%    points per A-scan. Down samples rows and col. Saves as .mat file.
%
%    Inputs:
%
%    FILENAME:  Name of .csv C-scan file to read
%    DELIM:     Field delimiter characters (i.e. "," or " ")
%    INFOLDER:  Folder location of .csv C-scan input file
%    OUTFOLDER: Folder to write .mat C-scan output file
%    DROW:      # rows to down sample (i.e. 5 means every 5th row is saved)
%    DCOL:      # col to down sample  (and 1 means no down sampling)

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
cscan = zeros(row,col,pts);

% Take abs value & remove redundant (row, col) info
for i = 1:row
    for j = 1:col
        cscan(i,j,:) = abs(rawcscan(j+(i-1)*col,3:end));
    end
end

% Down sample C-scan
if drow == 1
    saverow = 1:row;
else
    saverow = [1,drow:drow:row];
end

if dcol == 1
    savecol = 1:col;
else
    savecol = [1,dcol:dcol:col];
end

cscan = cscan(saverow,savecol,:);

% Save 3D matrix to .mat file
outpath = strcat(outfolder,'\','cscan',filename,'-cscan.mat');
save(outpath,'cscan','-mat');

end
