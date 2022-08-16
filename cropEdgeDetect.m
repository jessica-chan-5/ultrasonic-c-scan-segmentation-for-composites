function edgeIndex = cropEdgeDetect(baseTOF,searchi,searchj,cScan,noiseThresh,t,cropThresh,row)

edgeCandidates = NaN(1,length(searchj));
for j = 1:length(searchj)
    tof = zeros(1,length(searchi));
    for i = 1:length(searchi)
        if row == 0
            point = squeeze(cScan(searchi(i),searchj(j),:))';
        else
            point = squeeze(cScan(searchj(j),searchi(i),:))';
        end
        tof(i) = calcTOF(point,noiseThresh,t);
        if abs(baseTOF - tof(i)) >= cropThresh
            edgeCandidates(j) = i;
            break
        end
    end
end
edgeIndex = searchi(min(edgeCandidates));

end