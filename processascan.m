function processascan(filename,outfolder,figfolder,dt,bounds,incr,baserow, ...
    basecol,cropthresh,pad,minprom1,noisethresh,maxwidth,res)
%PROCESSASCAN Process A-scans to calculate TOF info.
%    PROCESSASCAN(filename,outfolder,dt,bounds,incr,baserow,basecol,
%    cropthresh,pad,minprom,noisethresh,maxwidth) Look for damage bounding
%    box within search area defined by bounds using a baseline TOF from an
%    area designated by baserow and basecol. Calculate and saves raw TOF 
%    and associated peak/location info for segmentcscan.
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
%    RES        : Image resolution setting in dpi

% Load C-scan
infile = strcat(outfolder,"\",'cscan\',filename,'-cscan.mat');
load(infile,'cscan');

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
temptof = calctof(cscan,t,baserow,basecol,minprom1,noisethresh,maxwidth);
basetof = mode(temptof,'all');

% Search for start row scanning from top to center row
startrow = findbound(basetof,t2c,l2r,'row',cropthresh,cscan,t,minprom1,...
    noisethresh,maxwidth);
% Search for end row scanning from bottom to center row
endrow   = findbound(basetof,b2c,l2r,'row',cropthresh,cscan,t,minprom1,...
    noisethresh,maxwidth);

% Set row indices to search
startrowi  = find(t2b == startrow);
endrowi    = find(t2b == endrow);
searchrows = t2b(startrowi:endrowi);

% Add padding in vertical direction
pad = floor((1+pad)*incr);
startrow = startrow - pad;
if startrow <=0
    startrow = 1;
end
endrow = endrow + pad;
if endrow > row
    endrow = row;
end

% Search for start col scanning from left to center
startcol = findbound(basetof,l2c,searchrows,'col',cropthresh,cscan,t,...
    minprom1,noisethresh,maxwidth);
% Search for end col scanning from right to center
endcol   = findbound(basetof,r2c,searchrows,'col',cropthresh,cscan,t,...
    minprom1,noisethresh,maxwidth);

% Add padding in horizontal direction
startcol = startcol - pad;
if startcol <= 0
    startcol = 1;
end
endcol = endcol + pad;
if endcol > col 
    endcol = col;
end

% Calculate raw TOF and corresponding peak/location info in crop region
[croptof,peak,locs,wide,npeaks] = calctof(cscan,t,startrow:endrow, ...
    startcol:endcol,minprom1,noisethresh,maxwidth); %#ok<ASGLU> 
rawtof = zeros(row,col);
rawtof(startrow:endrow,startcol:endcol) = croptof(1:end,1:end);

% Save raw TOF and corresponding peaks/location info
cropcoord = [startrow endrow startcol endcol]; %#ok<NASGU> 
savevar = ["rawtof";"peak";"locs";"wide";"npeaks";"cropcoord"];
for i = 1:length(savevar)
    outfile = strcat(outfolder,"\",savevar(i),"\",filename,'-',...
        savevar(i),'.mat');
    save(outfile,savevar(i),'-mat');
end

% Save png and figure of raw TOF
fig = figure('visible','off');
implot(rawtof,jet,row,col,filename,true);
imsave(figfolder,fig,'rawtof',filename,res);

end