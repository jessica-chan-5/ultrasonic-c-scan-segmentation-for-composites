function segcscan(fileName,outFolder,figFolder,minProm2,peakThresh, ...
    modeThresh,seEl,test,fontSize,res)
%SEGCSCAN Segment C-scan.
%   SEGCSCAN(filename,outfolder,figfolder,minprom2,peakthresh, ...
%   modethresh,seEl,test,res) Finds inflection points by combining two
%   techniques: (1) changes in peak labels for first and second peak at
%   each point along a row or column and (2) peaks in the graph of the 
%   magnitude of the second peak along a row or column. Using the 
%   inflection points found, finds the outline of the damage area. Then
%   in the interior of the damage area, cleans up stray points, closes 
%   gaps, and labels connected areas using image processing morphological 
%   operations. Calculates the mode TOF for each labeled connected area. If
%   difference between TOF at a point and the mode TOF for the area the
%   point is part of is less than modeThresh, the TOF at that point is set
%   to the mode TOF. Otherwise, the original TOF is kept.
%
%   There is an option to close gaps using line structuring elements of
%   varying lengths and angles (45/-45/0/90 degrees) using the seEl param.
%
%   Saves segmented TOF, inflection points, the damage area (mask and 
%   boundary), and the magnitude of the second peak at each point.
%
%   Plots inflection points separately by technique used and combined, a
%   queryable figure of inflection points, the mask and boundary of the
%   damage area, the process of segmenting TOF, a comparison between
%   the raw TOF and the segmented TOF, and the segmented TOF.
%
%   Inputs:
%
%   FILENAME  : Name of .mat file to read
%   OUTFOLDER : Folder path to .mat output files
%   FIGFOLDER : Folder path to .fig and .png files
%   MINPROM2  : Min prominence in findpeaks for a peak to be identified
%   PEAKTHRESH: If the difference between the time a peak appears in the
%               first point and the time the same peak appears in the
%               next point is greater than peakThresh, label as new peak
%   MODETHRESH: If difference between TOF at current point and mode TOF of
%               the area the current point belongs to is less than
%               modeThresh, set TOF at current point to mode TOF
%   SEEL      : Vector in the form: [length45 lengthNeg45 length90 length0]
%               indicating length of structuring element for morphological
%               closing of gaps if needed
%   TEST      : If true, shows figures
%   RES       : Image resolution setting in dpi for saving image

% Load raw TOF and associated info
loadVar = ["rawTOF";"peak";"locs";"wide";"nPeaks";"cropCoord"];
for i = 1:length(loadVar)
    inFile = strcat(outFolder,"\",loadVar(i),"\",fileName,'-',...
        loadVar(i),'.mat');
    load(inFile,loadVar(i))
end

% Calculate full size of raw TOF
rowF = size(rawTOF,1); colF = size(rawTOF,2); %#ok<NODEF> 

% Work with damage bounding box area of raw TOF only
startRow = cropCoord(1); endRow = cropCoord(2);
startCol = cropCoord(3); endCol = cropCoord(4);
rawTOF = rawTOF(startRow:endRow,startCol:endCol);

% Calculate cropped size of raw TOF
rowC = size(rawTOF,1); colC = size(rawTOF,2);

% If testing, set testing figures to be visible
if test == true
    visFig = 'on';
else
    visFig = 'off';
end

% Plot rawTOF as queryable scatter + imshow
if test == true
    fig = figure('visible','on');
    imscatter(fileName,figFolder,fig,' ',rawTOF,'jet'); colorbar;
end

% Find locations of 2nd peak and peak changes using label technique
[peak2,inflptLabR] = labelpeaks('row',rowC,colC,locs,peak,nPeaks,wide,...
    peakThresh);
[  ~  ,inflptLabC] = labelpeaks('col',rowC,colC,locs,peak,nPeaks,wide,...
    peakThresh);

% Find peak changes using 2nd peak magnitude technique
inflptMagR = magpeaks('row',rowC,colC,peak2,minProm2);
inflptMagC = magpeaks('col',rowC,colC,peak2,minProm2);

% Combine all methods used to find inflection points
inflpt = inflptLabR | inflptLabC | inflptMagR | inflptMagC;

% Plot and save figure of all methods used to find inflection points
fig = figure('visible',visFig);
tl = tiledlayout(2,3,'TileSpacing','tight','Padding','tight');
t1 = nexttile; implot(t1,inflptLabR,gray,rowC,colC,'Label Row',false,fontSize);
t1 = nexttile; implot(t1,inflptLabC,gray,rowC,colC,'Label Col',false,fontSize);
t1 = nexttile; implot(t1,inflpt,gray,rowC,colC,'Inflection Points',false,fontSize);
t1 = nexttile; implot(t1,inflptMagR,gray,rowC,colC,'Magnitude Row',false,fontSize);
t1 = nexttile; implot(t1,inflptMagC,gray,rowC,colC,'Magnitude Col',false,fontSize);
t1 = nexttile; implot(t1,rawTOF,jet,rowC,colC,'Raw TOF',false,fontSize); colorbar;
title(tl,fileName,'FontSize',fontSize);
imsave(fileName,figFolder,fig,'comboInflpt',1,res);

% Set 1 pixel border equal to zero to prevent morphological operations from
% connecting stray pixels to border
inflpt(1,:) = 0; inflpt(end,:) = 0; 
inflpt(:,1) = 0; inflpt(:,end) = 0;

% Set points with only 1 peak to be inflection points
inflpt(nPeaks < 2) = 1;

% Plot inflection points as queryable scatter + imshow
if test == true
    % Save inflpt in full size plate
    tempinflpt = ones(rowF,colF);
    tempinflpt(startRow:endRow,startCol:endCol) = inflpt;
    fig = figure('visible',visFig);
    imscatter(fileName,figFolder,fig,'inflptsQuery',tempinflpt,'gray');
end

% Plot inflection points
fig = figure('visible','off');
implot(fig,inflpt,gray,rowC,colC,fileName,false,fontSize);
imsave(fileName,figFolder,fig,"inflpt",1,res);

% Create concave hull of damage area
maskInflpt = inflpt;
% Take care of edge cases where outer contour is not fully closed
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
maskInflpt = bwmorph(maskInflpt,'clean'); % Remove isolated pixels

% Trace exterior boundary, ignore interior holes
[concBoundC,~] = bwboundaries(maskInflpt,'noholes');
% Convert boundaries from cell format to binary 2D matrix
concBound = zeros(size(maskInflpt));
for i = 1:length(concBoundC)
    for k = 1:size(concBoundC{i},1)
        concBound(concBoundC{i}(k,1),concBoundC{i}(k,2)) = 1;
    end
end
% Flood-fill boundary
mask = imfill(concBound,4);

% Find perimeter using 8 pixel connectivity
bound = bwperim(mask,8);

% Plot figure of modified inflection points, mask, boundary
fig = figure('visible',visFig);
tl = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
t1 = nexttile; implot(t1,inflpt,gray,rowC,colC,"Infl Pts",false,fontSize);
t1 = nexttile; implot(t1,mask,gray,rowC,colC,"Mask",false,fontSize);
t1 = nexttile; implot(t1,maskInflpt,gray,rowC,colC,"Cleaned Infl Pts",false,fontSize);
t1 = nexttile; implot(t1,bound,gray,rowC,colC,"Boundary",false,fontSize);
title(tl,fileName,'FontSize',fontSize);
imsave(fileName,figFolder,fig,'masks',0.5,res);

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

% Clean up and fill in gaps
J = bwmorph(J,'clean',inf);  % Remove isolated pixels
J = bwmorph(J,'bridge',inf); % Bridge pixels

% Add outline where missing
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
tl = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
t1 = nexttile; implot(t1,inflpt,gray,rowC,colC,"Original",false,fontSize);
t1 = nexttile; implot(t1,J,gray,rowC,colC,"Processed",false,fontSize);
t1 = nexttile; implot(t1,L,colorcube,rowC,colC,"Labeled",false,fontSize);
t1 = nexttile; implot(t1,tof,jet,rowC,colC,"Mode",true,fontSize); colorbar;
title(tl,fileName,'FontSize',fontSize);
imsave(fileName,figFolder,fig,'process',0.5,res);

% Plot and save figure of raw and processed TOF
fig = figure('visible',visFig);
tl = tiledlayout(1,2,'TileSpacing','tight','Padding','tight');
t1 = nexttile; implot(t1,rawTOF,jet,rowC,colC,"Unprocessed",true,fontSize);
t1 = nexttile; implot(t1,tof,jet,rowC,colC,"Processed",true,fontSize);
title(tl,fileName,'FontSize',fontSize); colorbar;
imsave(fileName,figFolder,fig,'compare',1,res);

% Plot and save figure of processed TOF
fig = figure('visible','off');
implot(fig,tof,jet,rowC,colC,fileName,true,fontSize); colorbar;
imsave(fileName,figFolder,fig,'tof',1,res);

% Save TOF, inflection points, and masks to .mat file
savevar = ["tof","inflpt","mask","bound","peak2"];
% Save tof in full size plate
temptof = zeros(rowF,colF);
temptof(startRow:endRow,startCol:endCol) = tof;
tof = temptof; %#ok<NASGU> 
for i = 1:length(savevar)
    outfile = strcat(outFolder,"\",savevar(i),"\",fileName,'-',...
        savevar(i),'.mat');
    save(outfile,savevar(i),'-mat');
end

end