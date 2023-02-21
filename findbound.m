function boundI = findbound(baseTOF,searchI,searchJ,searchOrien, ...
    cropThresh,cscan,t,minProm,noiseThresh,maxWidth)
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
%    CROPTHRESH : If difference between baseline TOF and TOF at a point is 
%                 greater than cropThresh, then the point is damaged
%    CSCAN:       C-scan data, in 3D matrix form: [row x col x pts]
%    T:           Time, in vector form: [0:dt:tend], in microseconds
%    MINPROM    : Min prominence in findpeaks for a peak to be identified
%    NOISETHRESH: If the average signal at a point is lower than 
%                 noiseThresh, then the point is ignored
%    MAXWIDTH   : If a peak's width is greater, then it is noted as wide

% Initialize variables
boundCandidates = NaN(1,length(searchJ));
ptTOF           = NaN(1,length(searchJ));
tof             = NaN(length(searchI),length(searchJ));

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
        if abs(baseTOF - tof(i,j)) >= cropThresh
            boundCandidates(j) = i;
            ptTOF(j) = tof(i,j);
            break
        end
    end
end

% Pick smallest value from row/col candidates as boundary index
boundI = searchI(min(unique(boundCandidates)));

end