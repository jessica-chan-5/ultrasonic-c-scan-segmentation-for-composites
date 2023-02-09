function processtof(filename,outfolder,figfolder,minprom2, ...
    peakthresh,modethresh)
%PROCESSTOF 
%
%   PROCESSTOF(filename,outfolder,figurefolder,minprom2,peakthresh,
%   modethresh)
%
%   Inputs:
%
%   FILENAME:
%   OUTFOLDER:
%   FIGUREFOLDER:
%   MINPROM2:
%   PEAKTHRESH:
%   MODETHRESH:

% Image resolution setting in dpi
res = 300;

% Load raw TOF and associated info
loadvar = ["rawtof";"peak";"locs";"wide";"npeaks";"cropcoord"];
for i = 1:length(loadvar)
    infile = strcat(outfolder,"\",loadvar(i),"\",filename,'-',...
        loadvar(i),'.mat');
    load(infile,loadvar(i))
end

% Work with damage bounding box area of raw TOF only
startrow = cropcoord(1);
endrow = cropcoord(2);
startcol = cropcoord(3);
endcol = cropcoord(4);
rawtof = rawtof(startrow:endrow,startcol:endcol); %#ok<NODEF> 

% Calculate size of raw TOF
row = size(rawtof,1);
col = size(rawtof,2);

% Find locations of 2nd peak and peak changes using label technique
[peak2,inflptlabrow] = labelpeaks('row',row,col,locs,peak,npeaks,wide, ...
    peakthresh);
[  ~  ,inflptlabcol] = labelpeaks('col',row,col,locs,peak,npeaks,wide, ...
    peakthresh);

% Find peak changes using 2nd peak magnitude technique
inflptmagrow = magpeaks('row',row,col,peak2,minprom2);
inflptmagcol = magpeaks('col',row,col,peak2,minprom2);

inflpt = inflptlabrow | inflptlabcol | inflptmagrow | inflptmagcol;

% Set 1 pixel border equal to zero to prevent 
inflpt(1,:) = 0;
inflpt(:,1) = 0;
inflpt(end,:) = 0;
inflpt(:,end) = 0;

% Set numPeaks < 2 to be inflection points
inflpt(npeaks < 2) = 1;

% Plot and save figure of inflection points
fig = figure('visible','off');
implot(inflpt,gray,row,col,filename);
imsave(figfolder,fig,"inflpt",filename,res);

% Create concave hull of damage area
maskinflpt = inflpt;
maskinflpt = bwmorph(maskinflpt,'clean',inf); % Remove isolated pixels
if strcmp(filename,'CSAI-RPR-H-20J-2-waveform-CH1') == true
    se90 = strel('line',2,90);
    maskinflpt = imclose(maskinflpt,se90);
end
maskinflpt = bwmorph(maskinflpt,'spur',inf); % Remove spurs

% Trace exterior boundary, ignore interior holes
[concBoundC,~] = bwboundaries(maskinflpt,'noholes');
% Convert boundaries from cell to binary image
boundary = zeros(size(maskinflpt));
for i = 1:length(concBoundC)
    for k = 1:size(concBoundC{i},1)
        boundary(concBoundC{i}(k,1),concBoundC{i}(k,2)) = 1;
    end
end
% Flood-fill boundary
mask = imfill(boundary,4);

% Plot and save modified inflection points, mask, boundary
figure('visible','off'); subplot(1,3,1);
im = imshow(maskinflpt,gray,'XData',[0 col],'YData',[row 0]);
im.CDataMapping = "scaled"; title("Mask Inflpts"); 
subplot(1,3,2); im = imshow(boundary,gray,'XData',[0 col],'YData',[row 0]);
im.CDataMapping = "scaled"; title("Boundary");
subplot(1,3,3); im = imshow(mask,gray,'XData',[0 col],'YData',[row 0]);
im.CDataMapping = "scaled"; title("Mask");
name = strcat(figfolder,"\masks\",filename,'-mask');
fig.CreateFcn = 'set(gcf,''visible'',''on'')';
savefig(fig,strcat(name,'.fig'));
exportgraphics(gcf,strcat(name,'.png'),'Resolution',res);

% Find perimeter using 8 pixel connectivity
concPerim = bwperim(mask,8);
subplot(1,2,2); im = imshow(concPerim,gray,'XData',[0 col],'YData',[row 0]);
im.CDataMapping = "scaled"; title("Boundary");
exportgraphics(gcf,strcat('Masks\',filename,'.png'),'Resolution',res);

% Apply mask to inflection points map before morphological operations
J = inflpt & mask;

% Close gaps in inflection points using morphological operations

J = bwmorph(J,'clean',inf);
J = bwmorph(J,'bridge',inf); % Remove isolated pixels

if strcmp(filename,'CSAI-RPR-S-20J-2-backside-CH1') == true
    se45 = strel('line',6,-45);
    J = imclose(J,se45);
end
if strcmp(filename,'CSAI-RPR-S-15J-2-backside-CH1') == true
    se45 = strel('line',6,45);
    J = imclose(J,se45);
end

% Remove excess pixels outside concave hull and add outline where missing
J = J | concPerim;

% Clean up w/ a few operations
J = bwmorph(J,'fill'); % Fill in isolated pixels
J = bwmorph(J,'spur',2); % Remove spurs
J = bwmorph(J,'clean',inf); % Remove isolated pixels

% Add any missing zero TOF values
J(nPeaks < 2) = 1;
figure('visible','off');
subplot(1,4,1); im = imshow(inflpt,gray,'XData',[0 col],'YData',[row 0]);
im.CDataMapping = "scaled"; title("Original");
subplot(1,4,2); im = imshow(J,gray,'XData',[0 col],'YData',[row 0]);
im.CDataMapping = "scaled"; title("Processed");

% Label separate layer regions of C-scan
[L,n] = bwlabel(uint8(~J),4);
subplot(1,4,3); im = imshow(L,colorcube,'XData',[0 col],'YData',[row 0]);
im.CDataMapping = "scaled"; title("Labeled");

TOF = unprocessedTOF;

for i = 1:n
    [areaI, areaJ] = find(L==i);
    areaInd = sub2ind(size(L),areaI,areaJ);
    areaMode = mode(round(unprocessedTOF(areaInd),2),'all');
    for k = 1:length(areaI)
        if abs(TOF(areaI(k),areaJ(k)) - areaMode) < modethresh
            TOF(areaI(k),areaJ(k)) = areaMode;
        end
    end
end

% Set numPeaks < 2 and widePeak to be zero TOF
TOF(nPeaks < 2) = 0;

subplot(1,4,4); im = imshow(TOF,jet,'XData',[0 col],'YData',[row 0]);
im.CDataMapping = "scaled"; title("Mode");
exportgraphics(gcf,strcat('Processed\',filename,'.png'),'Resolution',res);

% Save TOF and inflection points to .mat file
outFileTOF = strcat(outfolder,"\",filename,'-TOF.mat');
outFileInflectionPts = strcat(outfolder,'\',filename,'-InflectionPts.mat');
save(outFileTOF,'TOF','-mat');
save(outFileInflectionPts,'inflpt','-mat');

figure('Visible','off');
subplot(1,2,1); im = imshow(unprocessedTOF,jet,'XData',[0 col],'YData',[row 0]);
im.CDataMapping = "scaled"; title("Unprocessed");
exportgraphics(gcf,strcat('NewFigures\',filename,'.png'),'Resolution',res);
subplot(1,2,2); im = imshow(TOF,jet,'XData',[0 col],'YData',[row 0]);
im.CDataMapping = "scaled"; title("Processed");
sgtitle(filename);
exportgraphics(gcf,strcat('Comparison\',filename,'.png'),'Resolution',res);

% Save
% mask
end