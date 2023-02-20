function processcscan(fileName,outFolder,figFolder,dt,bounds,incr,baseRow, ...
    baseCol,cropThresh,pad,minProm1,noiseThresh,maxWidth,test,calcT1,res)
%PROCESSCSCAN Process A-scans to calculate TOF info.
%    PROCESSCSCAN(fileName,outFolder,figFolder,dt,bounds,incr,baseRow, ...
%    baseCol,cropThresh,pad,minProm1,noiseThresh,maxWidth,res) Look for
%    damage bounding box within search area defined by bounds using a
%    baseline TOF from an area designated by baserow and basecol. Calculate
%    and saves raw TOF and associated peak/location info for segmentcscan.
% 
%    Inputs:
% 
%    FILENAME   : Name of sample, same as readcscan
%    OUTFOLDER  : Folder path to .mat output files
%    FIGFOLDER  : Folder path to .fig and .png files
%    DT         : Sampling period in microseconds
%    BOUNDS     : Indices of search area for damage bounding box in format:
%                 [startX endX startY endY]
%    INCR       : Increment for damage bounding box search in indices
%    BASEROW    : Vector of row indices to calculate baseline TOF
%    BASECOL    : Vector of cols indices to calculate baseline TOF
%    CROPTHRESH : If abs(basetof-tof(i)) > cropthresh, point is damaged
%    PAD        : (1+pad)*incr added to calculated damage bounding box
%    MINPROM1   : Min prominence in findpeaks for a peak to be identified
%    NOISETHRESH: If average signal is lower, then point is not processed
%    MAXWIDTH   : Max width in findpeaks for a peak to be marked as wide
%    TEST       : If true, shows figures
%    RES        : Image resolution setting in dpi

% Load C-scan
name = 'cscan';
infile = strcat(outFolder,"\",name,'\',fileName,'-',name,'.mat');
load(infile,name);

% Find # rows, col, & data points/A-scan
[row, col, pts] = size(cscan);

% Create time vector
tend = (pts-1)*dt;
t = 0:dt:tend;

% Save search bounds and increments
startx = bounds(1);
endx   = bounds(2);
starty = bounds(3);
endy   = bounds(4);

% Calculate horizontal and vertical search indices
% Note: t=top,b=bottom,l=left,r=right,c=center
t2b   = starty:incr:endy;      % hor
halfy = floor(length(t2b)/2);
t2c   = t2b(1:halfy);
b2c   = t2b(end:-1:halfy+1);
l2r   = startx:incr:endx;      % ver
halfx = floor(length(l2r)/2);
l2c   = l2r(1:halfx);
r2c   = l2r(end:-1:halfx+1);

% Calculate baseline TOF
temptof = calctof(cscan,t,baseRow,baseCol,minProm1,noiseThresh,maxWidth);
basetof = mode(temptof,'all');

% Search for start row scanning from top to center row
startrow = findbound(basetof,t2c,l2r,'row',cropThresh,cscan,t,minProm1,...
    noiseThresh,maxWidth);
% Search for end row scanning from bottom to center row
endrow   = findbound(basetof,b2c,l2r,'row',cropThresh,cscan,t,minProm1,...
    noiseThresh,maxWidth);

% Set row indices to search
startrowi  = find(t2b == startrow);
endrowi    = find(t2b == endrow);
searchrows = t2b(startrowi:endrowi);

% Add padding in vertical direction
pad = floor((1+pad)*incr);
startr = startrow; endr = endrow;
startrow = startrow - pad;
if startrow <= 0
    startrow = 1;
end
endrow = endrow + pad;
if endrow > row
    endrow = row;
end

% Search for start col scanning from left to center
startcol = findbound(basetof,l2c,searchrows,'col',cropThresh,cscan,t,...
    minProm1,noiseThresh,maxWidth);
% Search for end col scanning from right to center
endcol   = findbound(basetof,r2c,searchrows,'col',cropThresh,cscan,t,...
    minProm1,noiseThresh,maxWidth);

% Add padding in horizontal direction
startc = startcol; endc = endcol;
startcol = startcol - pad;
if startcol <= 0
    startcol = 1;
end
endcol = endcol + pad;
if endcol > col 
    endcol = col;
end

% Calculate raw TOF and corresponding peak/location info in crop region
[cropTOF,peak,locs,wide,nPeaks] = calctof(cscan,t,startrow:endrow, ...
    startcol:endcol,minProm1,noiseThresh,maxWidth); %#ok<ASGLU> 
rawTOF = zeros(row,col);
rawTOF(startrow:endrow,startcol:endcol) = cropTOF(1:end,1:end);

if test == true
    figVis = 'on';
else
    figVis = 'off';
end

if calcT1 == true
    calct1(figFolder,outFolder,fileName,cscan,t,minProm1,noiseThresh, ...
        maxWidth,'jet',res)
end

% Plot bonds, incr, baseRow, baseCol, pad, start/end row/col
damBound = [startrow endrow startcol endcol]; 
cropCoord = [startr endr startc endc];
plotbounds(figVis,figFolder,fileName,rawTOF,bounds,damBound,cropCoord, ...
    l2r,t2b,baseRow,baseCol,res);

% Plot rawTOF as scatter + imshow
imscatter(figVis,figFolder,fileName,rawTOF,'jet');

% Save png and figure of raw TOF
fig = figure('visible','off');
implot(fig,rawTOF,jet,row,col,fileName,true);
imsave(figFolder,fig,'rawTOF',fileName,true,res);

% Save raw TOF and corresponding peaks/location info
savevar = ["rawTOF";"peak";"locs";"wide";"nPeaks";"cropCoord"];
for i = 1:length(savevar)
    outfile = strcat(outFolder,"\",savevar(i),"\",fileName,'-',...
        savevar(i),'.mat');
    save(outfile,savevar(i),'-mat');
end

end