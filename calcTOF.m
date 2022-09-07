function TOF = calcTOF(cScan,noiseThresh,t,row,col)

TOF = zeros(length(row),length(col));
loc2i = TOF;
peak2 = TOF;
widePeak = false(size(TOF));
noiseFlag = widePeak;
widePeakLoc = TOF;
numPeaks = TOF;
loc1 = TOF;

% Sensitivity parameters
neighThresh = 0.08; % 8 percent
minpeakheight = 0.16;

for i = 1:length(row)
    for j = 1:length(col)
        
        point = squeeze(cScan(row(i),col(j),:))';
        
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
                    widePeak(i,j) = true;
                    widePeakLoc(i,j) = l(k);
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
            numPeaks(i,j) = length(peak)-1;

            if numPeaks(i,j)+1 >= 2
                loc1(i,j) = loc(1);
                [peak2(i,j), loc2i(i,j)] = max(peak(2:end));
                loc2i(i,j) = loc2i(i,j) + 1;
                TOF(i,j) = loc(loc2i(i,j))-loc1(i,j);
            end
        else
            noiseFlag(i,j) = true;
        end
    end
end

for i = 1:length(row)

    startI = 3;
    pastTOF = 0;

    for j = 3:length(col)-2

        inflection = false;
        elseFlag = false;

        if numPeaks(i) + 1 >= 2
            if numPeaks(i,j) > 0
                if numPeaks(i,j) == numPeaks(i,j-1) && loc2i(i,j) ~= loc2i(i,j-1)
                    inflection = true;
                elseif issorted(peak2(i,j-2:j),'descend') && issorted(peak2(i,j+1:j+2))
                    inflection = true;
                end
            end
        
            if noiseFlag(i,j) == true
                if pastTOF ~= 0
                    TOF(i,startI:j-1) = mode(round(TOF(i,startI:j-1),2));
                end
                startI = j;
                pastTOF = 0;
                TOF(i,j) = 0;
            elseif widePeak(i,j) == false || (widePeak(i,j) == true && widePeakLoc(i,j) > loc1(i,j))
                if inflection == true ...
                    || j == 1 || j == length(col)-5 ...
                    || (pastTOF == 0 && TOF(i,j) ~= 0)
    
                    TOF(i,startI:j-1) = mode(round(TOF(i,startI:j-1),2));
                    startI = j;
                    pastTOF = TOF(i,j);
                end
            else
                elseFlag = true;
            end
        else
            elseFlag = true;
        end
        if elseFlag == true
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