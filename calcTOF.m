function TOF = calcTOF(cScan,noiseThresh,t,row,col)

TOF = zeros(length(row),length(col));

% Sensitivity parameters
neighThresh = 0.08; % 8 percent
minpeakheight = 0.16;

for i = 1:length(row)

    % Intialize check values
    startI = 1;
    l2i = zeros(1,length(col));
    loc2i = l2i;
    peak2 = 12i;
    pastTOF = 0;
    pastNumPeaks = 0;

    for j = 1:length(col)
        
        point = squeeze(cScan(row(i),col(j),:))';

        inflection = false;
        widePeak = false;
        widePeakLoc = t(end);
        
        % Check if mean signal value is above noise threshold
        if mean(point) > noiseThresh
            
            % Set values greater than 1 equal to 1
            point(point>1) = 1;
        
            % Find and save peaks/locations in signal
            [p, l] = findpeaks(point,t);
            % Manually add 0 point to peaks list in case signal is cut off on
            % left side
            p = [0 p]; %#ok<AGROW> 
            l = [0 l]; %#ok<AGROW> 
        
            % Flag wide peaks if max diff from 1 is less than neighoring threshold value
            for k = 1:length(p)-2
                if max(1 - p(k:k+2)) <= neighThresh
                    widePeak = true;
                    widePeakLoc = l(k);
                    break;
                end
            end
            
            % Find neighboring peaks that are within 8%
            % Set peak location and value to be at max of the neighboring peaks
            [p, l] = findCenter(p,l,1,neighThresh,false);
        
            % Find and save locations of peaks in previously found peaks
            [peak, loc] = findpeaks(p,l,...
                'MinPeakHeight',minpeakheight,...
                'WidthReference','halfheight');

            % Count number of peaks
            currentNumPeaks = length(peak)-1;

            if length(loc) >= 2
                
                [peak2(j), loc2i(j)] = max(peak(2:end)); %#ok<AGROW> 
                loc2i(j) = loc2i(j) + 1;
                currentTOF = loc(loc2i(j))-loc(1);

                if j > 5
                    if currentNumPeaks > 0
                        if currentNumPeaks == pastNumPeaks && loc2i(j) ~= loc2i(j-1)
                            inflection = true;
                        elseif peak2(j-4) > peak2(j-3) && ...
                            peak2(j-3) > peak2(j-2) && ...
                            peak2(j-1) > peak2(j-2) && ...
                            peak2(j) > peak2(j-1)
                            
                            inflection = true;
                        elseif (peak2(j-3)-peak2(j)) == 0 && ...
                                (peak2(j-2)-peak2(j-1)) == 0
                            inflection = true;
                        end
                    end
                end

                pastNumPeaks = currentNumPeaks;
        
                if widePeak == false || (widePeak == true && widePeakLoc > loc(1))
                    if inflection == true ...
                        || j == 1 || j == length(col) ...
                        || (pastTOF == 0 && currentTOF ~= 0)

                        TOF(i,startI:j-1) = mode(round(TOF(i,startI:j-1),2));
                        TOF(i,j) = currentTOF;
                        startI = j;
                        pastTOF = currentTOF;
                    else
                        TOF(i,j) = currentTOF;
                    end
                else
                    if pastTOF ~= 0
                        TOF(i,startI:j-1) = mode(round(TOF(i,startI:j-1),2));
                    end
                    startI = j;
                    pastTOF = 0;
                    TOF(i,j) = 0;
                end
            else
                if pastTOF ~= 0
                    TOF(i,startI:j-1) = mode(round(TOF(i,startI:j-1),2));
                end
                startI = j;
                pastTOF = 0;
                TOF(i,j) = 0;
            end
        else
            if pastTOF ~= 0
                TOF(i,startI:j-1) = mode(round(TOF(i,startI:j-1),2));
            end
            startI = j;
            pastTOF = 0;
            TOF(i,j) = 0;
        end
    end
end

end