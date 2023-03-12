function plotcustom(fileName,inFolder,outFolder,figFolder,utwincrop,dy, ...
    plateThick,test,fontSize,res)
%PLOTCUSTOM Plot custom figures.
%    PLOTCUSTOM(fileName,inFolder,outFolder,figFolder,utwincrop,dy, ...
%    plateThick,test,fontSize,res) Plots custom figures comparing UTWin 
%    screenshots to unsegmented and segmented TOF plots from this code. 
%    Allows for adjustments in the y direction to align UTWin screenshots 
%    with figures from this code.
% 
%    Inputs:
% 
%    FILENAME : Name of .mat file to read
%    INFOLDER : Folder location of UTWin screenshots
%    OUTFOLDER: Folder path to .mat output files
%    FIGFOLDER: Folder path to .fig and .png files
%    UTWINCROP: Indices to crop UTWin screenshot in format:
%               [startRow endRow startCol endCol]
%    DY       : Amount to adjust UTWin screenshots (+) = up, (-) = down
%    TEST     : If test is true, shows figures
%    RES      : Image resolution setting in dpi for saving image

% Load raw TOF and associated info
loadVar = ["rawTOF";"tof";"cropCoord"];
for i = 1:length(loadVar)
    inFile = strcat(outFolder,"\",loadVar(i),"\",fileName,'-',...
        loadVar(i),'.mat');
    load(inFile,loadVar(i))
end

% Save size of full TOF
rowF = size(tof,1); colF = size(tof,2); %#ok<NODEF> 

% Work with damage bounding box area only
startRow = cropCoord(1); endRow = cropCoord(2);
startCol = cropCoord(3); endCol = cropCoord(4);
rawTOF = rawTOF(startRow:endRow,startCol:endCol); %#ok<NODEF> 
tof = tof(startRow:endRow,startCol:endCol); 

% Save size of cropped TOF
rowC = size(tof,1); colC = size(tof,2);

% Get coordinates of UTWin image
startRowUT = utwincrop(1); endRowUT = utwincrop(2);
startColUT = utwincrop(3); endColUT = utwincrop(4);

% Scale coordinates for UTWin image from crop coordinates of C-scan
rowUT = endRowUT-startRowUT+1; ratiorow = rowUT/rowF; 
colUT = endColUT-startColUT+1; ratiocol = colUT/colF; 
startRow = floor(startRow*ratiorow); endRow = floor(endRow*ratiorow);
startCol = floor(startCol*ratiocol); endCol = floor(endCol*ratiocol);

% Read in UTWin image
inFile = strcat(inFolder,"\utwin\",fileName,'.bmp');
utwin = imread(inFile);

% Crop UTWin image
utwin = utwin(startRowUT:endRowUT,startColUT:endColUT,:);
utwin = utwin(startRow+dy:endRow+dy,startCol:endCol,:);

% If testing, set testing figures to be visible
if test == true
    figVis = 'on';
else
    figVis = 'off';
end

% Convert TOF to thickness
baseTOF = mode((nonzeros(tof)),'all'); % Calculate baseline TOF
matVel = plateThick/baseTOF;         % Calculate material velocity

% Flip left to right if is back scan
if strcmp('back',extractAfter(fileName,strlength(fileName)-4)) == true
    rawTOF = fliplr(rawTOF);
    tof = fliplr(tof);
    utwin = fliplr(utwin);
end

% Plot and save raw TOF, TOF, and UTWin images side-by-side
fig = figure('visible',figVis);
tiledlayout(1,3,'TileSpacing','tight');
t1 = nexttile; implot(t1,rawTOF*matVel,jet,rowC,colC, ...
    "Raw Damage Depth (mm)",true,fontSize); colorbar;
t1 = nexttile; implot(t1,tof*matVel,jet,rowC,colC, ...
    "Processed Damage Depth (mm)",true,fontSize); colorbar;
nexttile; imshow(utwin); 
title("UTWin Damage Depth (mm)"); ax = gca; ax.FontSize = fontSize;
if test == true
    axis on;
end
imsave(fileName,figFolder,fig,'utwin',1,res);

end