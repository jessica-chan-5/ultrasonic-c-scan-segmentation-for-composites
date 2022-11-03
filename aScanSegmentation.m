function aScanSegmentation(TOF,inFile,numLayers,plateThick,baseTOF,vertScale,saveFig)
    
    % Calculate material velocity
    matVel = 2*plateThick/baseTOF; % mm/us

    % Calculate ply thickness
    plyThick = plateThick/numLayers;

    % Calculate TOF for each layer
    dtTOF = plyThick/matVel*2;

    % Calculate bins centered at TOF for each layer
    layersTOF = baseTOF-numLayers*dtTOF-dtTOF/2:dtTOF:baseTOF+dtTOF/2;
    binTOF = discretize(TOF,layersTOF);
    
    % Create custom colormap that shows baseline TOF as white = [1, 1, 1]
    customColorMap = jet(numLayers);
    customColorMap = [customColorMap; [1 1 1]];

    if saveFig == false
        figure('visible','on');
        imshow(binTOF,customColorMap,'XData',[0 vertScale],'YData',[385 0]);
        title(strcat("TOF ",inFile));
    else
        figure('visible','off');
        imshow(binTOF,customColorMap,'XData',[0 vertScale],'YData',[385 0]);
        title(strcat("TOF ",inFile));
        ax = gca;
        exportgraphics(ax,strcat('Figures\',inFile,'.png'),'Resolution',300);
    end

end