function TOF = calcTOF(cScan,t,row,col)

% Initialize values
TOF = zeros(length(row),length(col));
% loc1 = TOF;
% loc2i = TOF;
% locs2i = TOF;
% peak2 = TOF;
% numPeaks = TOF;
% widePeakLoc = TOF;
% widePeak = false(length(row),length(col));
% peakLabels = cell(length(row),length(col));
% locs = peakLabels;

% inflectionpts = TOF;

% Sensitivity parameters
% wideThresh = 0.08; % For checking for wide peaks of peaks
% neighThresh = 0; % For checking find centers
% minpeakheight = 0.1; % For finding peaks of peaks
% peakThresh = 0.14; % For setting peak IDs
minPeakProm = 0.012; % For finding peaks in 2nd peak magnitude

for i = 1:length(row)
    
%     labelList = 1:20;
    
    cScanSlice = squeeze(cScan(row(i),:,:));

    parfor j = 1:length(col)
                
        point = cScanSlice(col(j),:);

        % Set values greater than 1 equal to 1
%         point(point>1) = 1;
    
        % Find and save peaks/locations in signal
        [p, l] = findpeaks(point,t);
    
        % Manually add 0 point to peaks list in case signal is cut off on left
        p = [0 p]; 
        l = [0 l];
        
        % Fit smoothing spline to find peak values
        f = fit(l',p',"smoothingspline");

        % Evaluate smoothing spline for t
        pfit = feval(f,t);

        % Flag wide peaks if max diff from max value is less than neighors by 8%
%         for k = 1:length(p)-2
%             if max(max(p(k:k+2)) - p(k:k+2)) <= wideThresh*max(p(k:k+2))
%                 widePeak(i,j) = true;
%                 widePeakLoc(i,j) = l(k);
%                 break;
%             end
%         end
    
        % Find neighboring peaks that are within 8%
        % Set peak location and value to be at max of the neighboring peaks
%         [p, l] = findCenter(p,l,1,neighThresh,false);

        % Find and save locations of peaks in previously found peaks
        [peak,loc] = findpeaks(pfit,t,'MinPeakProminence',minPeakProm);
%         locs{i,j} = loc;
    
        % Count number of peaks
        numPeaks = length(peak);
    %{
        % Assign unique peak IDs
    
        if j == 1
            peakLabels{i,j} = 1:length(locs{i,j});
            labelList = labelList(length(locs{i,j})+1:end);
        else
            tempCurr = locs{i,j};
            tempPrev = locs{i,j-1};
    
            for k = 1:length(tempPrev)
                minDiff = min(abs(locs{i,j-1}(k)-tempCurr));
                if minDiff > peakThresh
                    labelList = sort([peakLabels{i,j-1}(k), labelList]);
                end
            end
    
            for k = 1:length(tempCurr)
                [minDiff, minI] = min(abs(locs{i,j}(k)-tempPrev));
                if minDiff < peakThresh
                    tempCurr(minI) = NaN;
                    peakLabels{i,j} = [peakLabels{i,j}, peakLabels{i,j-1}(minI)];
                else
                    peakLabels{i,j} = [peakLabels{i,j}, labelList(1)];
                    labelList = labelList(2:end);
                end
            end
        end
    %}
        if numPeaks > 1
%             loc1(i,j) = loc(1);
            [~, loc2i] = max(peak(2:end));
%             loc2i(i,j) = loc2i(i,j) + 1;
            TOF(i,j) = loc(loc2i+1)-loc(1);
%             locs2i(i,j) = peakLabels{i,j}(loc2i(i,j));
        end
    end
end

%{
magVertLocCell = cell(1,length(row));

for j = 1:length(col)
    [~,magVertLocTemp] = findpeaks(-peak2(:,j),'MinPeakProminence',minPeakProm);
    
    for k = 1:length(magVertLocTemp)
        magVertLocCell{magVertLocTemp(k)} = [magVertLocCell{magVertLocTemp(k)}, col(j)];
    end
end

for i = 1:length(row)
    
    magVertLoc = magVertLocCell{i};

    % Find layer edges using peaks in 2nd peak mag values
    [~,magHorLoc] = findpeaks(-peak2(i,:),'MinPeakProminence',minPeakProm);
    magHorLoc = col(magHorLoc);
    
    % Find layer edges using 2nd peak label changes
    peakLoc = [];

    for k = 2:length(col)
        if numPeaks(i,k) >= 2
            if locs2i(i,k) ~= locs2i(i,k-1)
                peakLoc = [peakLoc, col(k)]; %#ok<AGROW> 
            end
        end
    end

    % Merge both methods and remove neighboring values differing by 1
    % When both methods detect a layer change, the peak change is correct and
    % the index is peakLoc = magLoc+1, not sure why
    locLocs = sort([magHorLoc, peakLoc]);
    locLocs(diff(locLocs)<=1) = [];
    locLocs = unique(locLocs);

%}
%{
% Temp remove
%     startI = 2;
    pastTOF = 0;

    for j = 2:length(col)
    
%         inflection = false;
        elseFlag = false;
    
        if numPeaks(i,j) >= 2

%             if sum(col(j) == locLocs)==1
%                 inflection = true;
%             end
            
%             if widePeak(i,j) == false || (widePeak(i,j) == true && widePeakLoc(i,j) > loc1(i,j))
%                 if inflection == true ...
%                     || j == 2 || j == length(col) ...
%                     || (pastTOF == 0 && TOF(i,j) ~= 0)
    
%                     TOF(i,startI:j-1) = median(filloutliers(TOF(i,startI:j-1),'center','median'));
%                     startI = j;
                    pastTOF = TOF(i,j);

%                     inflectionpts(i,j) = 1;
%                 end
%             else
%                 elseFlag = true;
%             end
        else
            elseFlag = true;
        end
    
        if elseFlag == true
            if pastTOF ~= 0
%                 TOF(i,startI:j-1) = median(filloutliers(TOF(i,startI:j-1),'center','median'));
                inflectionpts(i,j) = 1;
            end
%             startI = j;
            pastTOF = 0;
            TOF(i,j) = 0;
        end
    end
% end
% Temp remove
%}
end