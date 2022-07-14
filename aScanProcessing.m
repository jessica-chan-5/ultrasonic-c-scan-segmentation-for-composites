function TOF = aScanProcessing(cScan,inFile,outFile,dt,vertScale, ...
    noiseThresh, cropDam, plotRow,plotCol,plotTOF,plotAScan,saveMat,saveFig)
% Take .csv C-scan input file, calculate time of flight (TOF), and save
% normalized TOF data as .mat file
% 
% Inputs:
%   inFile     : Name of .mat C-scan input file
%   outFile    : Name of .mat TOF output file
%   dt         : Sampling period [us]
%   vertScale  : Vertical scaling factor for TOF plot
%   noiseThresh: If mean signal value is below value of noise threshold, 
%                TOF is set to zero
%   plotRow    : Row of A-scan plot
%   plotCol    : Column of A-scan plot
%   plotTOF    : Plots TOF image
%   plotAScan  : Plots A-scan for specified row, column location on plate
%   saveMat    : Saves TOF as .mat file
%   saveFig    : Saves plotted figures

tic;

% Find row, column, and data points info from C-scan
[row, col, dataPointsPerAScan] = size(cScan);

% Use basic gating procedure similar to UTWin
firstPeak = zeros(row,col);
secondPeak = firstPeak;

tEnd = (dataPointsPerAScan-1)*dt;
t = 0:dt:tEnd;

scaleRatio = col/vertScale;

if cropDam == true
    % Search for rectangular bounding box of damage
    cropThresh = 0.05;
    padExtra = 1.25;
    
    % Calculate spacing
    numPts = 10;
    vertSpace = floor(min(row,vertScale)/numPts);
    horSpace = vertSpace*scaleRatio;

    % Calculate horizontal and vertical indices
    top2bot = 1:vertSpace:row-vertSpace;
    halfVert = floor(length(top2bot)/2);
    top2cent = top2bot(1:halfVert);
    bot2cent = top2bot(end:-1:halfVert+1);

    left2right = 1:horSpace:col-horSpace;
    halfHor = floor(length(left2right)/2);
    left2cent = left2right(1:halfHor);
    right2cent = left2right(end:-1:halfHor+1);

    % From top to center
    vertTop = NaN(1,length(left2right));

    for j = 1:length(left2right)
        tempTOF = zeros(1,length(top2cent));
        for i = 1:length(top2cent)
            rowSlice = squeeze(cScan(top2cent(i),left2right(j),:))';
            [tempFirstPeak, tempSecondPeak] = calcTOF(rowSlice,noiseThresh,t);
            tempTOF(i) = tempSecondPeak - tempFirstPeak;

            if (mean(tempTOF(1:i)) - tempTOF(i)) >= cropThresh
                vertTop(j) = i;
                break
            end
        end
    end
    startRow = top2cent(min(vertTop));

    % From bottom to center
    vertBot = NaN(1,length(left2right));
    for j = 1:length(left2right)
        tempTOF = zeros(1,length(bot2cent));
        for i = 1:length(bot2cent)
            rowSlice = squeeze(cScan(bot2cent(i),left2right(j),:))';
            [tempFirstPeak, tempSecondPeak] = calcTOF(rowSlice,noiseThresh,t);
            tempTOF(i) = tempSecondPeak - tempFirstPeak;
        
            if (mean(tempTOF(1:i)) - tempTOF(i)) >= cropThresh
                vertBot(j) = i;
                break
            end
        end
    end
    endRow = bot2cent(min(vertBot));
    
    % Set rows to search
    startRowI = find(top2bot==startRow);
    endRowI = find(top2bot==endRow);
    searchRows = top2bot(startRowI:endRowI);
    
    % Add padding
    vertPad = floor(vertSpace*padExtra);
    startRow = startRow - vertPad;
    endRow = endRow + vertPad;

    if startRow <= 0
        startRow = 1;
    end
    if endRow > row
        endRow = row;
    end

    % From left to center
    horLeft = NaN(1,length(searchRows));
    for j = 1:length(searchRows)
        tempTOF = zeros(1,length(left2cent));
        for i = 1:length(left2cent)
            rowSlice = squeeze(cScan(searchRows(j),left2cent(i),:))';
            [tempFirstPeak, tempSecondPeak] = calcTOF(rowSlice,noiseThresh,t);
            tempTOF(i) = tempSecondPeak - tempFirstPeak;
        
            if (mean(tempTOF(1:i)) - tempTOF(i)) >= cropThresh
                horLeft(j) = i;
                break
            end
        end
    end
    startCol = left2cent(min(horLeft));
    
    % From right to center
    horRight = NaN(1,length(searchRows));
    for j = 1:length(searchRows)
        tempTOF = zeros(1,length(right2cent));
        for i = 1:length(right2cent)
            rowSlice = squeeze(cScan(searchRows(j),right2cent(i),:))';
            [tempFirstPeak, tempSecondPeak] = calcTOF(rowSlice,noiseThresh,t);
            tempTOF(i) = tempSecondPeak - tempFirstPeak;
        
            if (mean(tempTOF(1:i)) - tempTOF(i)) >= cropThresh
                horRight(j) = i;
                break
            end
        end
    end
    endCol = right2cent(min(horRight));

    % Add padding
    horPad = floor(horSpace*padExtra);
    startCol = startCol - horPad;
    endCol = endCol + horPad;

    if startCol <= 0
        startCol = 1;
    end
    if endCol > col
        endCol = col;
    end

else
    startCol = 1;
    endCol   = col;
    startRow = 1;
    endRow   = row;
end

% Step through each A-scan to calculate time of flight (TOF)
for i = startRow:endRow
    for j = startCol:endCol
        aScan = squeeze(cScan(i,j,:))';
        [firstPeak(i,j), secondPeak(i,j)] = calcTOF(aScan,noiseThresh,t);
    end
end

% Calculate raw TOF
rawTOF = secondPeak - firstPeak;

% Find baseline TOF for undamaged plate
baseTOF = mode(rawTOF,'all');
rawTOF(abs(rawTOF-baseTOF)<2*dt) = baseTOF;

% Reshape and normalize raw TOF by max TOF
TOF = (1/max(rawTOF,[],'all')) .* rawTOF;

% Fill in area outside of crop with TOF = 1 (white)
if cropDam == true
    for i = [1:col, 1:startCol-1, endCol+1:col, 1:col]
        for j = [1:startRow-1,endRow+1:row]
            TOF(j,i) = 1;
        end
    end
    for i = [1:startCol-1, endCol+1:col]
        for j = startRow-1:endRow+1
            TOF(j,i) = 1;
        end
    end
    % Vertical lines
    for i = [1:scaleRatio, col-scaleRatio+1:col]
        for j = 1:row
            TOF(j,i) = 0;
        end
    end
    % Horizontal lines
    for i = 1:col
        for j = [1, row]
            TOF(j,i) = 0;
        end
    end
end

% Save TOF to .mat file
if saveMat == true
    save(outFile,'TOF','-mat');
end

sampleName = inFile{1}(8:end-10);

% Plot TOF
if plotTOF == true && saveFig == false
    figure('visible','on');
    imshow(TOF,'XData',[vertScale 0]);
    title(strcat("TOF ",sampleName));
elseif plotTOF == true && saveFig == true
    figure('visible','off');
    imshow(TOF,'XData',[vertScale 0]);
    title(strcat("TOF ",sampleName));
    ax = gca;
    exportgraphics(ax,strcat('Figures\',sampleName,'.png'),'Resolution',300);
end

toc;

% Plot A-scan for max value of signal
if plotAScan == true
    titleStr = strcat("A-scan at row ",num2str(plotRow)," column ",num2str(plotCol));

    figure("Name",titleStr);
    plot(t,abs(cScan(plotRow,plotCol,:)));

    title(titleStr);
    xlabel("Time [us]");
    ylabel("Amplitude");
    xlim([0,tEnd]);
end

end





