clear; close all;

load("Output\hybridCscan\BL-S-10J-2-hybridCscan.mat");
load("Output\cropCoord\BL-S-10J-2-cropCoord.mat")

xcoord = hybridCscan(:,1);
ycoord = hybridCscan(:,2);
cscanval = hybridCscan(:,3);

cscan3d = ones(cropCoord(4)-cropCoord(3),cropCoord(2)-cropCoord(1), ...
    max(cscanval)).*0.5;
cscancell = cell(1,max(cscanval));
backgroundcell = cell(1,max(cscanval));

for i = 1:length(cscanval)
    cscan3d(ycoord(i),xcoord(i),cscanval(i)) = 1;
end

c = colormap(jet(max(cscanval)));

for i = 1:max(cscanval)
    [I,J] = find(cscan3d(:,:,i) == 1);
    [II,JJ] = find(cscan3d(:,:,i) == 0);
    cscancell{i} = ones(cropCoord(4)-cropCoord(3), ...
        cropCoord(2)-cropCoord(1),3);
    backgroundcell{i} = ones(cropCoord(4)-cropCoord(3), ...
        cropCoord(2)-cropCoord(1),3);
    for j = 1:length(I)
        cscancell{i}(I(j),J(j),:) = c(i,:);
    end
%     for k = 1:length(II)
%         backgroundcell{i}(II(j),JJ(j),:) = c(i,:);
%     end
end

hold on;
xIm = [cropCoord(1) cropCoord(2); cropCoord(1) cropCoord(2)];
yIm = [cropCoord(3) cropCoord(3); cropCoord(4) cropCoord(4)];

for i = 1:max(cscanval)
    zIm = [i i; i i];
    surf(xIm,yIm,zIm,'CData',cscancell{i}, ...
        'FaceColor','texturemap', ...
        'EdgeColor','none', ...
        'FaceAlpha','texturemap', ...
        'AlphaData',cscan3d(:,:,i));
%     surf(xIm,yIm,zIm,'CData',backgroundcell{i}, ...
%         'FaceColor','texturemap', ...
%         'EdgeColor','none', ...
%         'FaceAlpha','texturemap', ...
%         'AlphaData',cscan3d(:,:,i));
end
