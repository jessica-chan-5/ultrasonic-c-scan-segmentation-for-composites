function boundi = findbound(basetof,searchi,searchj,searchorien, ...
    boundthresh,cscan,t,minprom,noisethresh,maxwidth)
%FINDBOUND Find damage bounding box.
%    boundi = FINDBOUND(basetof,searchi,searchj,cscan,t,cropthresh, ...
%    searchorien,minprom,noisethresh,maxwidth) searches through rows or
%    cols to find damage bounding box index.
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
boundcandidates = NaN(1,length(searchj));
pttof = NaN(1,length(searchj));
tof = NaN(length(searchi),length(searchj));

% Loop through designated search indices in row and col directions
for j = 1:length(searchj)
    for i = 1:length(searchi)
        % Define C-scan depending on if searching across rows or cols
        if strcmp(searchorien,'row')
            pt = cscan(searchi(i),searchj(j),:);
        elseif strcmp(searchorien,'col')
            pt = cscan(searchj(j),searchi(i),:);
        end
        
        % Calculate time-of-flight
        tof(i,j) = calctof(pt,t,1,1,minprom,noisethresh,maxwidth);
        
        % If TOF varies from baseline TOF more than threshold, save as a
        % boundary candidate and move on to the next row/col
        if abs(basetof - tof(i,j)) >= boundthresh
            boundcandidates(j) = i;
            pttof(j) = tof(i,j);
            break
        end
    end
end

% Pick smallest value from row/col candidates as boundary index
boundi = searchi(min(unique(boundcandidates)));

end