utwinColorbar = imread("Input\utwin\utwin-colorbar.png");
parfor i = 1:numFiles
    utwinFig = imread(strcat("Figures\utwin\",fileNames(i),"-utwin.png"));
    utwinFig = imresize(utwinFig, ...
        size(utwinColorbar,1)/size(utwinFig,1));
    utwin = cat(2,utwinFig,utwinColorbar);
    fig = figure('Visible','off');
    imshow(utwin);
    imsave(fileNames(i),figFolder,fig,'utwin-colormap',1,res);
end