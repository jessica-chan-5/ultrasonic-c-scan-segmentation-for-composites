function processtof(filename,outfolder,figfolder,minprom2,peakthresh, ...
    modethresh,res)
%PROCESSTOF Process raw TOF.
%
%   PROCESSTOF(filename,outfolder,figurefolder,minprom2,peakthresh,
%   modethresh) finds inflection points using unique peak labels and peaks
%   in the graph of second peak magnitude along rows/cols. Using inflection
%   point map, cleans up, closes, and labels connected regions with
%   image processing morphological operations. Sets each labeled region to
%   mode TOF of region if value of TOF at point is within a threshold.
%
%   Inputs:
%
%   FILENAME  : Name of sample, same as readcscan
%   OUTFOLDER : Folder path to .mat output files
%   FIGFOLDER : Folder path to .fig and .png files
%   MINPROM2  : Min prominence in findpeaks for a peak to be identified
%   PEAKTHRESH: Threshold of dt for peak to be labeled as unique
%   MODETHRESH: Threshold for TOF to be set to mode TOF
%   RES       : Image resolution setting in dpi

% Load raw TOF and associated info
loadvar = ["rawtof";"peak";"locs";"wide";"npeaks";"cropcoord"];
for i = 1:length(loadvar)
    infile = strcat(outfolder,"\",loadvar(i),"\",filename,'-',...
        loadvar(i),'.mat');
    load(infile,loadvar(i))
end

% Save full size of raw TOF
rowf = size(rawtof,1); %#ok<NODEF> 
colf = size(rawtof,2);

% Work with damage bounding box area of raw TOF only
startrow = cropcoord(1);
endrow = cropcoord(2);
startcol = cropcoord(3);
endcol = cropcoord(4);
rawtof = rawtof(startrow:endrow,startcol:endcol);

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
implot(fig,inflpt,gray,row,col,filename,false);
imsave(figfolder,fig,"inflpt",filename,res);

% Create concave hull of damage area
maskinflpt = inflpt;
maskinflpt = bwmorph(maskinflpt,'clean',inf); % Remove isolated pixels
if strcmp(filename,'RPR-H-20J-2') == true
    se90 = strel('line',2,90);
    maskinflpt = imclose(maskinflpt,se90);
end
maskinflpt = bwmorph(maskinflpt,'spur',inf); % Remove spurs

% Trace exterior boundary, ignore interior holes
[concBoundC,~] = bwboundaries(maskinflpt,'noholes');
% Convert boundaries from cell to binary image
concbound = zeros(size(maskinflpt));
for i = 1:length(concBoundC)
    for k = 1:size(concBoundC{i},1)
        concbound(concBoundC{i}(k,1),concBoundC{i}(k,2)) = 1;
    end
end
% Flood-fill boundary
mask = imfill(concbound,4);
mask = bwmorph(mask,'clean',inf); % Remove isolated pixels

% Find perimeter using 8 pixel connectivity
bound = bwperim(mask,8);

% Plot and save figure of modified inflection points, mask, boundary
fig = figure('visible','off');
subp = subplot(1,3,1); implot(subp,inflpt,gray,row,col,"Infl Pts",false);
subp = subplot(1,3,2); implot(subp,mask,gray,row,col,"Mask",false);
subp = subplot(1,3,3); implot(subp,bound,gray,row,col,"Boundary",false);
imsave(figfolder,fig,'masks',filename,res);

% Apply mask to inflection points map before morphological operations
J = inflpt & mask;

% Close gaps in inflection points using morphological operations
J = bwmorph(J,'clean',inf);  % Remove isolated pixels
J = bwmorph(J,'bridge',inf); % Bridge pixels
if strcmp(filename,'RPR-S-20J-2-back') == true
    se45 = strel('line',6,-45);
    J = imclose(J,se45);
end
if strcmp(filename,'RPR-S-15J-2-back') == true
    se45 = strel('line',6,45);
    J = imclose(J,se45);
end

% Remove excess pixels outside concave hull and add outline where missing
J = J | bound;

% Clean up w/ a few operations
J = bwmorph(J,'fill');      % Fill in isolated pixels
J = bwmorph(J,'spur',2);    % Remove spurs
J = bwmorph(J,'clean',inf); % Remove isolated pixels

% Add any missing zero TOF values
J(npeaks < 2) = 1;

% Label separate layer regions of C-scan
[L,n] = bwlabel(uint8(~J),4);

% Apply mode TOF to each labeled region of the C-scan
tof = rawtof;
for i = 1:n
    [areaI, areaJ] = find(L==i);
    areaind = sub2ind(size(L),areaI,areaJ);
    areamode = mode(round(rawtof(areaind),2),'all');
    for k = 1:length(areaI)
        if abs(tof(areaI(k),areaJ(k)) - areamode) < modethresh
            tof(areaI(k),areaJ(k)) = areamode;
        end
    end
end

% Set numPeaks < 2 and widePeak to be zero TOF
tof(npeaks < 2) = 0;

% Plot and save figure of inflpts, processed inflpts, labeled regions, TOF
fig = figure('visible','off');
subp = subplot(1,4,1); implot(subp,inflpt,gray,row,col,"Original",false);
subp = subplot(1,4,2); implot(subp,J,gray,row,col,"Processed",false);
subp = subplot(1,4,3); implot(subp,L,colorcube,row,col,"Labeled",false);
subp = subplot(1,4,4); implot(subp,tof,jet,row,col,"Mode",true);
imsave(figfolder,fig,'process',filename,res);

% Plot and save figure of raw and processed TOF
fig = figure('visible','off');
subp = subplot(1,2,1); implot(subp,rawtof,jet,row,col,"Unprocessed",true);
subp = subplot(1,2,2); implot(subp,tof,jet,row,col,"Processed",true);
imsave(figfolder,fig,'compare',filename,res);

% Plot and save figure of processed TOF
fig = figure('visible','off');
implot(fig,tof,jet,row,col,filename,true);
imsave(figfolder,fig,'tof',filename,res);

% Save TOF, inflection points, and masks to .mat file
savevar = ["tof","inflpt","mask","bound"];
temptof = zeros(rowf,colf);
temptof(startrow:endrow,startcol:endcol) = tof;
tof = temptof; %#ok<NASGU> 
for i = 1:length(savevar)
    outfile = strcat(outfolder,"\",savevar(i),"\",filename,'-',...
        savevar(i),'.mat');
    save(outfile,savevar(i),'-mat');
end

end