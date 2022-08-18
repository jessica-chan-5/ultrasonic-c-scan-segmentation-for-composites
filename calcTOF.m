function TOF = calcTOF(aScan,noiseThresh,t)

widePeak = false;
widePeakI = t(end);

% Check if mean signal value is above noise threshold
if mean(aScan) > noiseThresh
    
    % Set values greater than 1 equal to 1
    aScan(aScan>1) = 1;

    % Find and save peaks/locations in signal
    [p, l] = findpeaks(aScan,t);
    % Manually add 0 point to peaks list in case signal is cut off on
    % left side
    p = [0 p];
    l = [0 l];

    for k = 1:length(p)-2
        if mean(p(k:k+2)) >= 0.98 && max(1 - p(k:k+2)) <= (10*0.0039)
            widePeak = true;
            widePeakI = l(k);
            break;
        end
    end
    
    % Find neighboring peaks that are within 10 x 0.0039
    % Set peak location to be at center of the two neighboring peaks
    % Set peak value as max of two neighboring peaks
    thresh = 10*0.0039;
    [p, l] = findCenter(p,l,4,thresh);
    [p, l] = findCenter(p,l,3,thresh);
    [p, l] = findCenter(p,l,2,thresh);
    [p, l] = findCenter(p,l,1,thresh);

    % Find and save locations of peaks in previously found peaks
    [peak, loc,width] = findpeaks(p,l,'MinPeakProminence',0.09,...
        'MinPeakHeight',0.16,'SortStr','descend','WidthReference','halfheight');
    if length(loc) >= 2
        loc1 = min([loc(1),loc(2)]);
        loc2 = max([loc(1),loc(2)]);

        if widePeak == false
            firstPeak = loc1;
            secondPeak = loc2;
        elseif widePeak == true && widePeakI > loc1
            firstPeak = loc1;
            secondPeak = loc2;
        else
            firstPeak = 1;
            secondPeak = 1;
        end
    else
        firstPeak = 1;
        secondPeak = 1;
    end
else
    firstPeak = 1;
    secondPeak = 1;
end

% Calculate TOF
TOF = secondPeak-firstPeak;

% If TOF is too small to resolve, set to zero
TOF(TOF < 0.12*2) = 0;

end