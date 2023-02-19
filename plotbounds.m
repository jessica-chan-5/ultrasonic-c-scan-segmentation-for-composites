function plotbounds(figVis,figFolder,fileName,rawTOF,bounds,damBound, ...
    cropCoord,l2r,t2b,baseRow,baseCol,res)
% PLOTBOUNDS Plots bonds, incr, baseRow, baseCol, pad, start/end row/col

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