function boundI = findbound(baseTOF,searchI,searchJ,searchOrien, ...
    boundThresh,cscan,t,minProm,noiseThresh,maxWidth)
%FINDBOUND Find damage bounding box.
%    boundI = FINDBOUND(baseTOF,searchI,searchJ,searchOrien,boundThresh,...
%    cscan,t,minProm,noiseThresh,maxWidth) searches through rows or cols to
%    find damage bounding box index.
%
%    Inputs:
%
%    BASETOF    : Baseline, undamaged TOF established by small test area
%    SEARCHI    : Indices to search through in direction 1
%    SEARCHJ    : Indices to search through in direction 2
%    SEARCHORIEN: Direction to search along, 'row' or 'col'
%    BOUNDTHRESH: If abs(tof(i)-baseTOF)>= thresh, boundary index is found
%    CSCAN:       C-scan data, in 3D matrix form: [row x col x pts]
%    T:           Time, in vector form: [0:dt:tend], in microseconds
%    MINPROM    : Min prominence in findpeaks for a peak to be identified
%    NOISETHRESH: If average signal is lower, then point is not processed
%    MAXWIDTH   : Max width in findpeaks for a peak to be marked as wide

% Initialize variables
boundCandidates = NaN(1,length(searchJ));
ptTOF = NaN(1,length(searchJ));
tof = NaN(length(searchI),length(searchJ));

% Loop through designated search indices in row and col directions
for j = 1:length(searchJ)
    for i = 1:length(searchI)
        % Define C-scan depending on if searching across rows or cols
        if strcmp(searchOrien,'row')
            pt = cscan(searchI(i),searchJ(j),:);
        elseif strcmp(searchOrien,'col')
            pt = cscan(searchJ(j),searchI(i),:);
        end
        
        % Calculate time-of-flight
        tof(i,j) = calctof(pt,t,1,1,minProm,noiseThresh,maxWidth);
        
        % If TOF varies from baseline TOF more than threshold, save as a
        % boundary candidate and move on to the next row/col
        if abs(baseTOF - tof(i,j)) >= boundThresh
            boundCandidates(j) = i;
            ptTOF(j) = tof(i,j);
            break
        end
    end
end

% Pick smallest value from row/col candidates as boundary index
boundI = searchI(min(unique(boundCandidates)));

end