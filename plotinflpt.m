function plotinflpt(inflpt,row,col,cropCoord)

% Save inflpt in full size plate
tempinflpt = ones(row,col);
tempinflpt(cropCoord(1):cropCoord(2),cropCoord(3):cropCoord(4)) = inflpt;
inflpt = tempinflpt;

% Plot inflpt using imshow
r = size(inflpt,1);
c = size(inflpt,2);
figure('visible','on');
im = imshow(inflpt);
im.CDataMapping = "scaled"; axis on;
colormap(gray); hold on;

% Plot inflpt as scatter
infl = reshape(int8(inflpt),r*c,1);
y = repmat((1:r)',c,1);
x = repelem(1:c,r)';
rawTab = table(x,y,infl);
scatter(rawTab,'x','y','filled','ColorVariable','infl');
colormap(gca,'gray');

end