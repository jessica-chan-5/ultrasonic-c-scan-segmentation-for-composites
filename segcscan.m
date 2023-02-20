function segcscan(fileName,outFolder,figFolder,minProm2,peakThresh, ...
    modeThresh,seEl,test,res)
%SEGCSCAN Process raw TOF.
%
%   SEGCSCAN(filename,outfolder,figurefolder,minprom2,peakthresh,
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
loadVar = ["rawTOF";"peak";"locs";"wide";"nPeaks";"cropCoord"];
for i = 1:length(loadVar)
    inFile = strcat(outFolder,"\",loadVar(i),"\",fileName,'-',...
        loadVar(i),'.mat');
    load(inFile,loadVar(i))
end

% Save full size of raw TOF
rowF = size(rawTOF,1); %#ok<NODEF> 
colF = size(rawTOF,2);

% Work with damage bounding box area of raw TOF only
startRow = cropCoord(1);
endRow = cropCoord(2);
startCol = cropCoord(3);
endCol = cropCoord(4);
rawTOF = rawTOF(startRow:endRow,startCol:endCol);

% Calculate size of raw TOF
row = size(rawTOF,1);
col = size(rawTOF,2);

% Find locations of 2nd peak and peak changes using label technique
[peak2,inflptLabRow] = labelpeaks('row',row,col,locs,peak,nPeaks,wide, ...
    peakThresh);
[  ~  ,inflptLabCol] = labelpeaks('col',row,col,locs,peak,nPeaks,wide, ...
    peakThresh);

% Find peak changes using 2nd peak magnitude technique
inflptMagRow = magpeaks('row',row,col,peak2,minProm2);
inflptMagCol = magpeaks('col',row,col,peak2,minProm2);

inflpt = inflptLabRow | inflptLabCol | inflptMagRow | inflptMagCol;

% Set 1 pixel border equal to zero to prevent 
inflpt(1,:) = 0;
inflpt(:,1) = 0;
inflpt(end,:) = 0;
inflpt(:,end) = 0;

% Set numPeaks < 2 to be inflection points
inflpt(nPeaks < 2) = 1;

% Plot and save figures of inflection points
if test == true
    % Save inflpt in full size plate
    tempinflpt = ones(rowF,colF);
    tempinflpt(startRow:endRow,startCol:endCol) = inflpt;
    visFig = 'on';
    imscatter(visFig,figFolder,fileName,' ',tempinflpt,'gray');
else
    visFig = 'off';
end

fig = figure('visible','off');
implot([],inflpt,gray,row,col,fileName,false);
imsave(figFolder,fig,"inflpt",fileName,true,res);

% Create concave hull of damage area
maskInflpt = inflpt;
maskInflpt = bwmorph(maskInflpt,'clean',inf); % Remove isolated pixels
if strcmp(fileName,'RPR-H-20J-2') == true
    se90 = strel('line',4,90);
    maskInflpt = imclose(maskInflpt,se90);
elseif strcmp(fileName,'RPR-S-15J-2-back') == true
    maskInflpt = bwmorph(maskInflpt,'spur',inf); % Remove spurs
    maskInflpt = bwmorph(maskInflpt,'clean',inf); % Remove isolated pixels
    se0 = strel('line',6,0);
    maskInflpt = imclose(maskInflpt,se0);
end
maskInflpt = bwmorph(maskInflpt,'spur',inf); % Remove spurs

% Trace exterior boundary, ignore interior holes
[concBoundC,~] = bwboundaries(maskInflpt,'noholes');
% Convert boundaries from cell to binary image
concBound = zeros(size(maskInflpt));
for i = 1:length(concBoundC)
    for k = 1:size(concBoundC{i},1)
        concBound(concBoundC{i}(k,1),concBoundC{i}(k,2)) = 1;
    end
end
% Flood-fill boundary
mask = imfill(concBound,4);
mask = bwmorph(mask,'clean',inf); % Remove isolated pixels

% Find perimeter using 8 pixel connectivity
bound = bwperim(mask,8);

% Plot and save figure of modified inflection points, mask, boundary
fig = figure('visible','off');
subplot(1,3,1); implot([],inflpt,gray,row,col,"Infl Pts",false);
subplot(1,3,2); implot([],mask,gray,row,col,"Mask",false);
subplot(1,3,3); implot([],bound,gray,row,col,"Boundary",false);
sgtitle(fileName);
imsave(figFolder,fig,'masks',fileName,true,res);

% Apply mask to inflection points map before morphological operations
J = inflpt & mask;

% Close gaps in inflection points using morphological operations
if ~(seEl(1) == 0 && seEl(2) == 0 && seEl(3) == 0 && seEl(4) == 0)
    if seEl(1) ~= 0
        se45p = strel('line',seEl(1), 45); J45p = imclose(J,se45p);
    else
        J45p = J;
    end
    if seEl(2) ~= 0
        se45n = strel('line',seEl(2),-45); J45n = imclose(J,se45n);
    else
        J45n = J;
    end
    if seEl(3) ~= 0
        se90  = strel('line',seEl(3), 90); J90 = imclose(J,se90);
    else
        J90 = J;
    end
    if seEl(4) ~= 0
        se0   = strel('line',seEl(4),  0); J0 = imclose(J,se0);
    else
        J0 = J;
    end
    J = J45p | J45n | J90 | J0;
end

J = bwmorph(J,'clean',inf);  % Remove isolated pixels
J = bwmorph(J,'bridge',inf); % Bridge pixels

% Remove excess pixels outside concave hull and add outline where missing
J = J | bound;

% Clean up w/ a few operations
J = bwmorph(J,'fill');      % Fill in isolated pixels
J = bwmorph(J,'spur',2);    % Remove spurs
J = bwmorph(J,'clean',inf); % Remove isolated pixels

% Add any missing zero TOF values
J(nPeaks < 2) = 1;

% Label separate layer regions of C-scan
[L,n] = bwlabel(uint8(~J),4);

% Apply mode TOF to each labeled region of the C-scan
tof = rawTOF;
for i = 1:n
    [areaI, areaJ] = find(L==i);
    areaind = sub2ind(size(L),areaI,areaJ);
    areamode = mode(round(rawTOF(areaind),2),'all');
    for k = 1:length(areaI)
        if abs(tof(areaI(k),areaJ(k)) - areamode) < modeThresh
            tof(areaI(k),areaJ(k)) = areamode;
        end
    end
end

% Set numPeaks < 2 and widePeak to be zero TOF
tof(nPeaks < 2) = 0;

% Plot and save figure of inflpts, processed inflpts, labeled regions, TOF
fig = figure('visible',visFig);
subplot(1,4,1); implot([],inflpt,gray,row,col,"Original",false);
subplot(1,4,2); implot([],J,gray,row,col,"Processed",false);
subplot(1,4,3); implot([],L,colorcube,row,col,"Labeled",false);
subp = subplot(1,4,4); implot(subp,tof,jet,row,col,"Mode",true);
sgtitle(fileName);
imsave(figFolder,fig,'process',fileName,true,res);

% Plot and save figure of raw and processed TOF
fig = figure('visible',visFig);
subp = subplot(1,2,1); implot(subp,rawTOF,jet,row,col,"Unprocessed",true);
subp = subplot(1,2,2); implot(subp,tof,jet,row,col,"Processed",true);
sgtitle(fileName);
imsave(figFolder,fig,'compare',fileName,true,res);

% Plot and save figure of processed TOF
fig = figure('visible','off');
implot(fig,tof,jet,row,col,fileName,true);
imsave(figFolder,fig,'tof',fileName,true,res);

% Save TOF, inflection points, and masks to .mat file
savevar = ["tof","inflpt","mask","bound","peak2"];
temptof = zeros(rowF,colF);
temptof(startRow:endRow,startCol:endCol) = tof;
tof = temptof; %#ok<NASGU> 
for i = 1:length(savevar)
    outfile = strcat(outFolder,"\",savevar(i),"\",fileName,'-',...
        savevar(i),'.mat');
    save(outfile,savevar(i),'-mat');
end

end