function edgeIndex = cropEdge(baseTOF,searchi,searchj,cScan,t,cropThresh,searchOrien,minprom,noisethresh,maxwidth)

edgeCandidates = NaN(1,length(searchj));
ptTOF = NaN(1,length(searchj));
TOF = NaN(length(searchi),length(searchj));

for j = 1:length(searchj)
    for i = 1:length(searchi)
        if strcmp(searchOrien,'row')
            point = cScan(searchi(i),searchj(j),:);
        elseif strcmp(searchOrien,'col')
            point = cScan(searchj(j),searchi(i),:);
        end

        TOF(i,j) = calctof(point,t,1,1,minprom,noisethresh,maxwidth);

        if abs(baseTOF - TOF(i,j)) >= cropThresh
            edgeCandidates(j) = i;
            ptTOF(j) = TOF(i,j);
            break
        end
    end
end

edgeIndex = searchi(min(edgeCandidates));

end