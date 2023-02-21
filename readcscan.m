function readcscan(fileName,inFolder,outFolder,delim,dRow,dCol)
%READCSCAN Convert C-scan from .csv to .mat file. 
%    READCSCAN(fileName,inFolder,outFolder,delim,dRow,dCol) Reads in C-scan
%    from .csv file located in inFolder using readmatrix with designated 
%    delimiter. Trims non-numeric values and takes absolute value of each 
%    A-scan signal. Reshapes into 3D matrix with dimensions row by col by 
%    number of data points per A-scan. Down samples rows and coloumns. For 
%    example, if dRow = 1 and dCol = 5, save every row and every 5th 
%    column. Saves 3D matrix as as .mat file in outFolder.
%
%    Inputs:
%
%    FILENAME:  Name of .csv C-scan file to read
%    INFOLDER:  Folder location of .csv C-scan input file
%    OUTFOLDER: Folder to save .mat C-scan output file
%    DELIM:     Field delimiter characters (i.e. "," or " ")
%    DROW:      # rows to down sample (i.e. 5 means every 5th row is saved)
%    DCOL:      # col to down sample  (and 1 means no down sampling)

% Read C-scan .csv file
inPath = strcat(inFolder,'\',fileName,'.csv');
rawcscan = readmatrix(inPath,'Delimiter',delim,'TrimNonNumeric',true);

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
if dRow == 1
    saverow = 1:row;
else
    saverow = [1,dRow:dRow:row];
end

if dCol == 1
    savecol = 1:col;
else
    savecol = [1,dCol:dCol:col];
end

cscan = cscan(saverow,savecol,:); %#ok<NASGU> 

% Save 3D matrix to .mat file
name = "cscan";
outpath = strcat(outFolder,'\',name,'\',fileName,'-',name,'.mat');
save(outpath,name,'-mat');

end
