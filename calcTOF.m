function [TOF, fits] = calcTOF(cScan,t,row,col)

% Initialize values
TOF = zeros(length(row),length(col));
fits = cell(length(row),length(col));

% Sensitivity parameters
minPeakPromP = 0.03; % For finding peaks of a-scan
minPeakPromPeak = 0.02; % For finding peaks of spline fit
baseTOFthresh = 0.1; % For replacing values greater than baseTOF with zeros
smoothSplineParam = 1; % For smoothparam when using fit with smoothingspline option
noiseThresh = 0.01; % To check if signal is above noise threshold

for i = 1:length(row)
    
    cScanSlice = squeeze(cScan(row(i),:,:));

    parfor j = 1:length(col)
        if mean(cScanSlice(col(j),:)) > noiseThresh

            point = cScanSlice(col(j),:);
    
            % Find and save peaks/locations in signal
            [p, l] = findpeaks(point,t);
        
            % Force signal to be zero at beginning and end
            p = [0 p 0];
            l = [0 l t(end)];

            
            % Fit smoothing spline to find peak values
            fits{i,j} = fit(l',p',"smoothingspline");
    
            % Evaluate smoothing spline for t
            pfit = feval(fits{i,j},t);
    
            % Find and save locations of peaks in previously found peaks
            [peak,loc] = findpeaks(pfit,t,'MinPeakProminence',minPeakPromPeak);
        
            % Count number of peaks
            numPeaks = length(peak);
    
            if numPeaks > 1
                [~, loc2i] = max(peak(2:end));
                TOF(i,j) = loc(loc2i+1)-loc(1);
            end
        end
    end
end

% Replace all values higher than baseTOF with 0
baseTOF = mode(mode(TOF));
TOF((TOF-baseTOF)>baseTOFthresh) = 0;

end