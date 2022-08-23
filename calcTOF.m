function TOF = calcTOF(cScan,noiseThresh,t,row,col)

TOF = zeros(length(row),length(col));

% Sensitivity parameters
neighThresh = 0.04; % 10 x 0.0039 (1/2^8)
layerThresh = 0.16; % 0.10 + 0.02*3
minpeakprom = 0.09;
minpeakheight = 0.16;
resolutionThresh = 0.12*2;

for i = 1:length(row)

    % Intialize check values
    startI = 1;
    l2i = zeros(1,length(col));
    pastTOF = 0;

    for j = 1:length(col)
        
        point = squeeze(cScan(row(i),col(j),:))';

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
        
            % Flag wide peaks if mean is close to 1 and max diff from 1 is less
            % than neighoring threshold value
            for k = 1:length(p)-2
                if mean(p(k:k+2)) >= 0.98 && max(1 - p(k:k+2)) <= neighThresh
                    widePeak = true;
                    widePeakI = l(k);
                    break;
                end
            end
            
            % Find neighboring peaks that are within ~10 x 0.0039
            % Set peak location and value to be at leftmost of the neighboring peaks
            thresh = 0.04;
            [p, l] = findCenter(p,l,1,thresh,false);
%             p = rmmissing(p);
%             l = rmmissing(l);
        
            % Find and save locations of peaks in previously found peaks
            [peak, loc] = findpeaks(p,l,...
                'MinPeakProminence',minpeakprom,...
                'MinPeakHeight',minpeakheight,...
                'WidthReference','halfheight');

            if length(loc) >= 2
                
                loc1 = loc(1);
                [~, loc2i] = max(peak(2:end));
                loc2i = loc2i + 1;
                l2i(j) = find(l==loc(loc2i));
                tof = loc(loc2i)-loc1;

                currentTOF = tof;
        
                if widePeak == false || (widePeak == true && widePeakI > loc1)
                    if (range(l2i(startI:j)) > 2 && abs(pastTOF-currentTOF) > layerThresh) ...
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
                        TOF(i,j) = currentTOF;
                    end
                    startI = j;
                    pastTOF = 0;
                    TOF(i,j) = 0;
                end
            else
                currentTOF = 0;
                if pastTOF ~= 0
                    TOF(i,startI:j-1) = mode(round(TOF(i,startI:j-1),2));
                    TOF(i,j) = currentTOF;
                end
                startI = j;
                pastTOF = 0;
                TOF(i,j) = 0;
            end
        else
            currentTOF = 0;
            if pastTOF ~= 0
                TOF(i,startI:j-1) = mode(round(TOF(i,startI:j-1),2));
                TOF(i,j) = currentTOF;
            end
            startI = j;
            pastTOF = 0;
            TOF(i,j) = 0;
        end
    end
end

% If TOF is too small to resolve, set to zero
TOF(TOF < resolutionThresh) = 0;

end