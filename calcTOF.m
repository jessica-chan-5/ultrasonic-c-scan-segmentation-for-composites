function TOF = calcTOF(cScan,noiseThresh,t,row,col)

TOF = zeros(length(row),length(col));

for i = 1:length(row)

    startI = 1;

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
            thresh = 0.04;
        %     [p, l] = findCenter(p,l,4,thresh,false);
        %     [p, l] = findCenter(p,l,3,thresh,false);
        %     [p, l] = findCenter(p,l,2,thresh,false);
            [p, l] = findCenter(p,l,1,thresh,false);
        
            p = rmmissing(p);
            l = rmmissing(l);
        
            % Find and save locations of peaks in previously found peaks
            [peak, loc,~] = findpeaks(p,l,'MinPeakProminence',0.09,...
                'MinPeakHeight',0.16,'WidthReference','halfheight');
            if length(loc) >= 2
                for k = 1:length(loc)-1
                    if (loc(k+1)-loc(k)) <= 0.28
                        peak(k+1) = NaN;
                        loc(k+1) = NaN;
                    end
                end

                peak = rmmissing(peak);
                loc = rmmissing(loc);
                
                [~, loc2i] = max(peak(2:end));
                tof = loc(loc2i+1)-loc(1);

                if j == 1
                    pastTOF = tof+0.16;
                end
                currentTOF = tof;
        
                if widePeak == false || (widePeak == true && widePeakI > loc(1))
                    if abs(pastTOF-currentTOF) >= 0.16
                        TOF(i,startI:j) = pastTOF;
                        startI = j;
                        pastTOF = currentTOF;
                    else
                        TOF(i,j) = tof;
                    end
                else
                    startI = j;
                    pastTOF = 0;
                    TOF(i,j) = 0;
                end
            else
                startI = j;
                pastTOF = 0;
                TOF(i,j) = 0;
            end
        else
            startI = j;
            pastTOF = 0;
            TOF(i,j) = 0;
        end
    end
end

% If TOF is too small to resolve, set to zero
TOF(TOF < 0.12*2) = 0;

end