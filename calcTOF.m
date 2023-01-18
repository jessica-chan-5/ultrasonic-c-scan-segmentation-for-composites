function [rawTOF,fits] = calcTOF(cScan,t,row,col)

% Initialize values
rawTOF = zeros(length(row),length(col));
fits = cell(length(row),length(col));

% Sensitivity parameters
minPeakPromPeak = 0.02; % For finding peaks of spline fit
noiseThresh = 0.01; % To check if signal is above noise threshold

for i = 1:length(row)
    
    cScanSlice = cScan(row(i),:,:);

    parfor j = 1:length(col)
        if mean(cScanSlice(:,col(j),:)) > noiseThresh %#ok<PFBNS> 

            point = squeeze(cScanSlice(:,col(j),:))';
    
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
                rawTOF(i,j) = loc(loc2i+1)-loc(1);
            end
        end
    end
end

% Set values greater than baseline TOF to zero
baseTOF = mode(rawTOF,'all');
rawTOF(rawTOF>(baseTOF+0.1)) = 0;

end