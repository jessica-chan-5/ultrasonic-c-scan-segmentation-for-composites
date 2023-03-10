% Sets up Figure, Input, and Output folders including subfolders

mkdir Figures
mkdir Input
mkdir Output

figFolders = ["3Dplot","combingInflpt","compare","cscan","damBoundBox",...
"damLayers","frontBackHybrid","hybridCscan","inflpt","inflptsQuery",...
"masks","mergeCheck","process","rawTOF","rawTOFquery","t1","tof","utwin"];

outFolders = ["bound","cropCoord","cscan","damLayers","hybridCscan",...
"inflpt","locs","mask","nPeaks","peak","peak2","rawTOF","t1","tof","wide"];

for i = 1:length(figFolders)
    eval(strcat("mkdir Figures ",figFolders(i)));
end

for i = 1:length(outFolders)
    eval(strcat("mkdir Output ",outFolders(i)));
end