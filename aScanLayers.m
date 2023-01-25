function [TOF,inflectionpts,inflectionptsRow] = aScanLayers(fileName,outFolder,...
    dataPtsPerAScan,saveTOF,saveInflectionPts)

% Concatenate file names/paths
inFile = strcat(outFolder,"\",fileName,'-fits.mat');
outFileTOF = strcat(outFolder,"\",fileName,'-TOF.mat');
outFileInflectionPts = strcat(outFolder,'\',fileName,'-InflectionPts.mat');

% Load cScan
load(inFile,'fits');

row = size(fits,1);
col = size(fits,2);

% Time vector
dt = 0.02;
tEnd = (dataPtsPerAScan-1)*dt;
t = 0:dt:tEnd;

% Initialize values
TOF = zeros(row,col);
numPeaks = TOF;
widePeak = false(row,col);
inflectionpts = TOF;
peaks = cell(row,col);
locs = cell(row,col);

% Sensitivity parameters
minPeakPromPeak = 0.03;
minPeakPromPeak2 = 0.1;
peakThresh = 0.08;
maxPeakWidth = 0.7;

for i = 1:row    
    for j = 1:col
        fit = fits{i,j};

        if isempty(fit) == false
            % Evaluate smoothing spline for t
            pfit = feval(fit,t);
            % Find and save locations of peaks in spline fit
            [peaks{i,j}, locs{i,j}, width] = findpeaks(pfit,t,'MinPeakProminence',minPeakPromPeak,'WidthReference','halfheight');
            
            if length(width) >= 1 && width(1) > maxPeakWidth
                widePeak(i,j) = true;
            end
        
            % Count number of peaks
            numPeaks(i,j) = length(peaks{i,j});
        end
    end
end

[peak2,unprocessedTOF,locs2i] = labelPeaks(row,col,locs,peaks,numPeaks,widePeak,peakThresh);
inflectionpts = findInflectionPts(inflectionpts,'row',row,col,peak2,minPeakPromPeak2,numPeaks,locs2i);

inflectionptsRow = inflectionpts; % temp testing

inflectionpts = findInflectionPts(inflectionpts,'col',row,col,peak2,minPeakPromPeak2,numPeaks,locs2i);

TOF = unprocessedTOF;

for i = 1:row

    startI = 2;
    pastTOF = 0;
    locI = 1;

    for j = startI:col

        inflection = false;
        elseFlag = false;

        if numPeaks(i,j) >= 2
            
            locLocs = find(inflectionpts(i,:)==1);
            if locI <= length(locLocs) && j == locLocs(locI)
                inflection = true;
                locI = locI + 1;
            end

            if widePeak(i,j) == false
                if inflection == true ...
                    || j == 2 || j == col
                    
                    modeRow = unprocessedTOF(i,startI:j-1);

                    for k = startI:j-1
                        upLoc = find(inflectionpts(i:-1:1,k)==1,1);
                        downLoc = find(inflectionpts(i:end,k)==1,1)+i-1;
                        modeCol = repmat(unprocessedTOF(upLoc:downLoc,k)',1,5);
                        localMode = mode(round([modeCol,modeRow],2));

                        if abs(unprocessedTOF(i,k)-localMode) < 0.04
                            TOF(i,k) = localMode;
                        end
                    end
                    startI = j;
                    pastTOF = unprocessedTOF(i,j);
                end
            else
                elseFlag = true;
            end
        else
            elseFlag = true;
        end

        if elseFlag == true
            if pastTOF ~= 0

                modeRow = unprocessedTOF(i,startI:j-1);

                for k = startI:j-1
                    upLoc = find(inflectionpts(i:-1:1,k)==1,1);
                    downLoc = find(inflectionpts(i:end,k)==1,1)+i-1;
                    modeCol = repmat(unprocessedTOF(upLoc:downLoc,k)',1,5);
                    localMode = mode(round([modeCol,modeRow],2));

                    if abs(unprocessedTOF(i,k)-localMode) < 0.04
                        TOF(i,k) = localMode;
                    end
                end
            end
            startI = j;
            pastTOF = 0;
            TOF(i,j) = 0;
        end

    end
end

% Save TOF and inflection points to .mat file
if saveTOF == true
    save(outFileTOF,'TOF','-mat');
end

if saveInflectionPts == true
    save(outFileInflectionPts,'fits','-mat');
end

end