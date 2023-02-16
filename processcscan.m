function processcscan(fileName,outFolder,figFolder,dt,bounds,incr,baseRow, ...
    baseCol,cropThresh,pad,minProm1,noiseThresh,maxWidth,test,res)
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

% Plot bonds, incr, baseRow, baseCol, pad, start/end row/col
fig = figure('visible','off');
implot(fig,rawTOF,jet,row,col,fileName,true)
modeData = mode(rawTOF(rawTOF~=0),'all');
im = imshow(rawTOF,[0 modeData+0.1]);
im.CDataMapping = "scaled";
colormap(jet); hold on;
% Plot bounds
boundLW = 2;
boundLS = '-r';
p1 = plot([startx endx],[starty starty],boundLS,'LineWidth',boundLW);
plot([startx endx],[endy endy],boundLS,'LineWidth',boundLW);
plot([startx startx],[starty endy],boundLS,'LineWidth',boundLW);
plot([endx endx],[starty endy],boundLS,'LineWidth',boundLW);
% Plot incr
incrLW = 0.25;
incrLS = '-y';
for i = 1:length(t2b)
    if i == 1
    p2 = plot([l2r(1) l2r(end)],[t2b(i) t2b(i)],incrLS,'LineWidth',incrLW);
    end
    plot([l2r(1) l2r(end)],[t2b(i) t2b(i)],incrLS,'LineWidth',incrLW);
end
for i = 1:length(l2r)
    plot([l2r(i) l2r(i)],[t2b(1) t2b(end)],incrLS,'LineWidth',incrLW);
end
% Plot baseRow/baseCol
baseMSt = '.g';
baseMSi = 10;
for i = 1:length(baseRow)
    for j = 1:length(baseCol)
        if i == 1 && j == 1
            p3 = plot(baseRow(i),baseCol(j),baseMSt,'MarkerSize',baseMSi);
        end
        plot(baseRow(i),baseCol(j),baseMSt,'MarkerSize',baseMSi);
    end
end
% Plot start/end row/col (no pad)
damBoxLW = 2;
damBoxLS = '-m';
p4 = plot([startc startc],[startr endr],damBoxLS,'LineWidth',damBoxLW);
plot([endc endc],[startr endr],damBoxLS,'LineWidth',damBoxLW);
plot([startc endc],[startr startr],damBoxLS,'LineWidth',damBoxLW);
plot([startc endc],[endr endr],damBoxLS,'LineWidth',damBoxLW);
% Plot start/end row/col (pad)
padLW = 2;
padLS = '-c';
p5 = plot([startcol startcol],[startrow endrow],padLS,'LineWidth',padLW);
plot([endcol endcol],[startrow endrow],padLS,'LineWidth',padLW);
plot([startcol endcol],[startrow startrow],padLS,'LineWidth',padLW);
plot([startcol endcol],[endrow endrow],padLS,'LineWidth',padLW);
% Add legend
legend([p1 p2 p3 p4 p5], ...
    {'bounds','incr','baseRow/baseCol','Damage bound box','pad'}, ...
    'Location','bestoutside')
imsave(figFolder,fig,'damBoundBox',fileName,true,res);

% Save png and figure of raw TOF
fig = figure('visible','off');
implot(fig,rawTOF,jet,row,col,fileName,true);
imsave(figFolder,fig,'rawTOF',fileName,true,res);

% Save raw TOF and corresponding peaks/location info
cropCoord = [startrow endrow startcol endcol]; %#ok<NASGU> 
savevar = ["rawTOF";"peak";"locs";"wide";"nPeaks";"cropCoord"];
for i = 1:length(savevar)
    outfile = strcat(outFolder,"\",savevar(i),"\",fileName,'-',...
        savevar(i),'.mat');
    save(outfile,savevar(i),'-mat');
end

end