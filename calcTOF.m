function TOF = calcTOF(cScan,noiseThresh,t,row,col)

TOF = zeros(length(row),length(col));

% Sensitivity parameters
neighThresh = 0.08; % 8%
minpeakheight = 0.16;
resolutionThresh = 0.12*2;

for i = 1:length(row)

    % Intialize check values
    startI = 1;
    l2i = zeros(1,length(col));
    loc2i = l2i;
    peak2 = 12i;
    pastTOF = 0;

    for j = 1:length(col)
        
        point = squeeze(cScan(row(i),col(j),:))';

        inflection = false;
        widePeak = false;
        widePeakI = t(end);
        
        % Check if mean signal value is above noise threshold
        if mean(point) > noiseThresh
            
            % Set values greater than 1 equal to 1
            point(point>1) = 1;
        
            % Find and save peaks/locations in signal
            [p, l] = findpeaks(point,t);
            % Manually add 0 point to peaks list in case signal is cut off on
            % left side
            p = [0 p];
            l = [0 l];
        
            % Flag wide peaks if max diff from 1 is less than neighoring threshold value
            for k = 1:length(p)-2
                if max(1 - p(k:k+2)) <= neighThresh
                    widePeak = true;
                    widePeakI = l(k);
                    break;
                end
            end
            
            % Find neighboring peaks that are within 8%
            % Set peak location and value to be at leftmost of the neighboring peaks
            [p, l] = findCenter(p,l,1,neighThresh,false);
        
            % Find and save locations of peaks in previously found peaks
            [peak, loc,width] = findpeaks(p,l,...
                'MinPeakHeight',minpeakheight,...
                'WidthReference','halfheight');
            
            for k = 1:length(width)
                if width(k) >= 0.80
                    widePeak = true;
                    widePeakI = loc(k);
                    break;
                end
            end

            if length(loc) >= 2
                
                loc1 = loc(1);
                [peak2(j), loc2i(j)] = max(peak(2:end)); %#ok<AGROW> 
                loc2i(j) = loc2i(j) + 1;
                l2i(j) = find(l==loc(loc2i(j)));
                tof = loc(loc2i(j))-loc1;
                
                if j > 1
                    if(l2i(j-1)) <= 0
                        inflection = true;
                    elseif p(l2i(j-1)) < peak2(j)
                        inflection = true;
                    end
                end
                currentTOF = tof;
        
                if widePeak == false || (widePeak == true && widePeakI > loc1)
                    if inflection == true ...
                        || j == 1 || j == length(col) ...
                        || (pastTOF == 0 && currentTOF ~= 0)

                        TOF(i,startI:j-1) = mode(round(TOF(i,startI:j-1),2));
                        TOF(i,j) = currentTOF;
                        startI = j;
                        pastTOF = currentTOF;
                    else
                        TOF(i,j) = tof;
                    end
                else
                    currentTOF = 0;
                    if pastTOF ~= 0
                        TOF(i,startI:j-1) = mode(round(TOF(i,startI:j-1),2));
                    end
                    startI = j;
                    pastTOF = 0;
                    TOF(i,j) = currentTOF;
                end
            else
                currentTOF = 0;
                if pastTOF ~= 0
                    TOF(i,startI:j-1) = mode(round(TOF(i,startI:j-1),2));
                end
                startI = j;
                pastTOF = 0;
                TOF(i,j) = currentTOF;
            end
        else
            currentTOF = 0;
            if pastTOF ~= 0
                TOF(i,startI:j-1) = mode(round(TOF(i,startI:j-1),2));
            end
            startI = j;
            pastTOF = 0;
            TOF(i,j) = currentTOF;
        end
    end
end

% If TOF is too small to resolve, set to zero
TOF(TOF < resolutionThresh) = 0;

end