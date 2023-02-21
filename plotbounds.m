function plotbounds(fileName,figFolder,rawTOF,bounds,damBound, ...
    cropCoord,l2r,t2b,baseRow,baseCol,figVis,res)
%PLOTBOUNDS Plots boundary elements.
%   PLOTBOUNDS(fileName,figFolder,rawTOF,bounds,damBound,cropCoord,l2r,...
%   t2b,baseRow,baseCol,figVis,res) Plots boundary elements such as the
%   search area, damage bounding box, damage bounding box with padding
%   added, search grid, and grid of points used to calculate baseline TOF.
%
%   Inputs:
%
%   FILENAME:  Name of .mat file to read
%   FIGFOLDER: Folder path to .fig and .png files
%   RAWTOF:    Unprocessed TOF in [row x col] matrix form
%   BOUNDS:    Indices of search area for damage bounding box in format:
%              [startX endX startY endY]
%   DAMBOUND:  Indices of damage bounding box
%   CROPCOORD: Indices of damage bounding box with padding added
%   L2R:       Column search indices from left to right 
%   T2B:       Row search indices from top to bottom
%   BASEROW:   Row indices across which to calculate baseline TOF
%   BASECOL:   Column indices across which to calculate baseline TOF
%   FIGVIS:    If true, shows testing figures
%   RES:       Image resolution setting in dpi for saving image

% Break up start/end variables
startx = bounds(1);
endx   = bounds(2);
starty = bounds(3);
endy   = bounds(4);

startrow = damBound(1);
endrow   = damBound(2);
startcol = damBound(3);
endcol   = damBound(4);

startr = cropCoord(1);
endr   = cropCoord(2);
startc = cropCoord(3);
endc   = cropCoord(4);

% Plot raw TOF using imshow
fig = figure('visible',figVis);
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

% Add legend and title
legend([p1 p2 p3 p4 p5], ...
    {'bounds','incr','baseRow/baseCol','Damage bound box','pad'}, ...
    'Location','bestoutside'); axis on;
title(fileName);

% Save figure
imsave(figFolder,fig,'damBoundBox',fileName,true,res);

end