function processascan(filename,outfolder,dt,bounds,incr,baserow, ...
    basecol,cropthresh,pad,minprom,noisethresh,maxwidth)
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
%    DT         : Sampling period in microseconds
%    BOUNDS     : Indices of search area for damage bounding box in format:
%                 [startX endX startY endY]
%    INCR       : Increment for damage bounding box search in indices
%    BASEROW    : Vector of row indices to calculate baseline TOF
%    BASECOL    : Vector of cols indices to calculate baseline TOF
%    CROPTHRESH : If abs(basetof-tof(i)) > cropthresh, point is damaged
%    PAD        : (1+pad)*incr added to calculated damage bounding box
%    MINPROM    : Min prominence in findpeaks for a peak to be identified
%    NOISETHRESH: If average signal is lower, then point is not processed
%    MAXWIDTH   : Max width in findpeaks for a peak to be marked as wide

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
dx     = incr(1);
dy     = incr(2);

% Calculate horizontal and vertical search indices
% Note: t=top,b=bottom,l=left,r=right,c=center
t2b   = starty:dy:endy;      % hor
halfy = floor(length(t2b)/2);
t2c   = t2b(1:halfy);
b2c   = t2b(end:-1:halfy+1);
l2r   = startx:dx:endx;      % ver
halfx = floor(length(l2r)/2);
l2c   = l2r(1:halfx);
r2c   = l2r(end:-1:halfx+1);

% Calculate baseline TOF
temptof = calctof(cscan,t,baserow,basecol,minprom,noisethresh,maxwidth);
basetof = mode(temptof,'all');

% Search for start row scanning from top to center row
startrow = cropEdge(basetof,t2c,l2r,cscan,t,cropthresh,'row',minprom,...
    noisethresh,maxwidth);
% Search for end row scanning from bottom to center row
endrow   = cropEdge(basetof,b2c,l2r,cscan,t,cropthresh,'row',minprom,...
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
startcol = cropEdge(basetof,l2c,searchrows,cscan,t,cropthresh,'col',...
    minprom,noisethresh,maxwidth);
% Search for end col scanning from right to center
endcol   = cropEdge(basetof,r2c,searchrows,cscan,t,cropthresh,'col', ...
    minprom,noisethresh,maxwidth);

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
[croptof,peaks,locs,wide,npeaks] = calctof(cscan,t,startrow:endrow, ...
    startcol:endcol,minprom,noisethresh,maxwidth); %#ok<ASGLU> 
rawtof = zeros(row,col);
rawtof(startrow:endrow,startcol:endcol) = croptof(1:end,1:end); %#ok<NASGU> 

% Save damage bounding box row/col info
cropcoord = [startrow startcol; endrow, endcol]; %#ok<NASGU> 

% Save raw TOF and corresponding peaks/location info
saveVar = ["rawtof";"peaks";"locs";"wide";"npeaks";"cropcoord"];
for i = 1:length(saveVar)
    outfile = strcat(outfolder,"\",saveVar(i),"\",filename,'-',...
        saveVar(i),'.mat');
    save(outfile,saveVar(i),'-mat');
end

end