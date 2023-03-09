function processcscan(fileName,outFolder,figFolder,dt,bounds,incr, ...
    baseRow,baseCol,cropThresh,pad,minProm1,noiseThresh,maxWidth, ...
    calcTone,test,fontSize,res)
%PROCESSCSCAN Process C-scans to calculate TOF.
%   PROCESSCSCAN(fileName,outFolder,figFolder,dt,bounds,incr,baseRow, ...
%   baseCol,cropThresh,pad,minProm1,noiseThresh,maxWidth,calcTone,test,res)
%   Look for damage bounding box within search area defined by bounds and a
%   search grid with increments defined by incr. Calculate a baseline TOF 
%   from an gridded area designated by baseRow and baseCol. If difference
%   between the TOF at search grid point and the baseline TOF is greater
%   than cropThresh, then the point is identified as part of the damage
%   bounding box. Extra padding is added to the damage bounding box as a 
%   pad factor of incr.
%   
%   Calculates TOF for points within damage bounding box using a smoothing 
%   spline fit and findpeaks. Peaks with prominence lower than minProm1 are
%   ignored. Points with average signal lower than noiseThresh are ignored.
%   Peaks wider than maxWidth are noted.
% 
%   If requested, calculates and plots t1, the time of the first peak.
%   
%   Saves raw TOF data along with magnitude, location, wide peak locations,
%   number of peaks and damage bounding box coordinates.
%
%   Plots raw TOF with bounds, incr, baseRow/Col, pad, and damage bounding 
%   box info overlaid, queryable figure of raw TOF, and image of raw TOF.
% 
%   Inputs:
% 
%   FILENAME   : Name of .mat file to read
%   OUTFOLDER  : Folder path to .mat C-scan output file
%   FIGFOLDER  : Folder path to .fig and .png files
%   DT         : Sampling period in microseconds
%   BOUNDS     : Indices of search area for damage bounding box in format:
%                [startX endX startY endY]
%   INCR       : Increment for damage bounding box search in indices
%   BASEROW    : Row indices across which to calculate baseline TOF
%   BASECOL    : Column indices across which to calculate baseline TOF
%   CROPTHRESH : If difference between baseline TOF and TOF at a point is 
%                greater than cropThresh, then the point is damaged
%   PAD        : (1+pad)*incr added to all sides of damage bounding box
%   MINPROM1   : Min prominence in findpeaks for a peak to be identified
%   NOISETHRESH: If the average signal at a point is lower than 
%                noiseThresh, then the point is ignored
%   MAXWIDTH   : If a peak's width is greater, then it is noted as wide
%   CALCTONE   : If true, calculates and plots time of first peak 
%   TEST       : If true, shows figures
%   RES        : Image resolution setting in dpi for saving image

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

% If testing, set testing figures to be visible
if test == true
    figVis = 'on';
else
    figVis = 'off';
end

% Calculate t1, time of first peak if requested
if calcTone == true
    calct1(fileName,outFolder,figFolder,cscan,t,minProm1,noiseThresh, ...
        maxWidth,'jet',res)
end

cropCoord = [startrow endrow startcol endcol]; 
damBound = [startr endr startc endc];

if test == true
% Plot bonds, incr, baseRow, baseCol, pad, start/end row/col
plotbounds(fileName,figFolder,rawTOF,bounds,damBound,cropCoord,l2r,t2b, ...
    baseRow,baseCol,figVis,res);

% Plot rawTOF as queryable scatter + imshow
fig = figure('visible',figVis);
imscatter(fileName,figFolder,fig,'rawTOFquery',rawTOF,'jet'); colorbar;
end

% Save png and figure of raw TOF
fig = figure('visible','off');
implot(fig,cropTOF,jet,endrow-startrow,endcol-startcol, ...
    ' ',true,fontSize); colorbar;
title(strcat("Raw TOF (\mus): ",fileName),'FontSize',fontSize);
imsave(fileName,figFolder,fig,'rawTOF',true,res);

% Save raw TOF and corresponding peaks/location info
savevar = ["rawTOF";"peak";"locs";"wide";"nPeaks";"cropCoord"];
for i = 1:length(savevar)
    outfile = strcat(outFolder,"\",savevar(i),"\",fileName,'-',...
        savevar(i),'.mat');
    save(outfile,savevar(i),'-mat');
end

end