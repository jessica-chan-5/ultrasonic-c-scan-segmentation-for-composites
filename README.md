# Ultrasonic C-scan Segmentation for Composites
[![View Ultrasonic C-scan Segmentation for Composites on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/125985-ultrasonic-c-scan-segmentation-for-composites)

## Description

This code was developed as part of Jessica Chan’s master’s thesis in Dr Hyonny Kim’s lab at UC San Diego. The code takes pulse-echo ultrasonic C-scan data in character delimited formats (.csv, .txt, .dat) of aerospace composites with impact damage and creates a 3D reconstruction of the damage state. The code also calculates time-of-flight, creates a mask of the overall damaged region, and merges front and back C-scans of a sample when available. The code was developed in MATLAB 2022b, but works for 2019b or later.

<p align="center">
   <img src=assets/graphical-summary.png  width="100%">
</p>

## Background
Despite a high strength to weight ratio, aerospace composites are susceptible to impact damage which can be barely visible while still adversely affecting their strength, therefore detecting and characterizing damage is important. Non-destructive evaluation, specifically single-sided pulse-echo ultrasonic C-scans, can be used to detect damage. The main characteristic of barely visible impact damage is that it occurs from impacts that leave little to no visual indication on the front side that damage has occurred, when in fact there is internal damage, namely planar delaminations between the lamina, and there can be visual indication of damage on the back side of the component. Examples of barely visible impact damage include damage to a component impacted by runway debris, hail, or accidentally dropped maintenance tools [^1].

<p align="center">
   <img src=assets/bvid-xray-ct.png  width="60%">
</p>

(A) Example through-thickness X-ray CT scan slice showing barely visible impact damage labeled with impact direction and front/back side with respect to impact direction. Reprinted with permission [^2]. (B) Processed UT C-scan of the same sample as in (A) showing front side damage and representative location for section cut shown in (A).

Pulse-echo UT C-scans are made of a 2D array of A-scans taken at points in a uniform grid across a sample. Each A-scan is the measurement of the reflection(s) from the initial ultrasonic signal emitted by the transducer. The first reflected peak is from the top layer of the sample and the second reflected peak is the topmost damaged interface within the sample. An example of the A-scan signal and time-of-flight (TOF) calculation for an undamaged and damaged A-scan point is shown in below. A map of the depth of damaged areas can be created by calculating the difference between the first peak and the second peak, the TOF, which then can be converted to damage depth by using the material’s through-thickness wave velocity.

<p align="center">
   <img src=assets/cscan-explanation.png  width="60%">
</p>

(A) Photo of a sample with manually mapped damage region outline, (B) UT C-scan time-of-flight map, (C) C-scan process and calculating TOF for undamaged scan point (right) and damaged scan point (left) using the A-scan signal at each scan point.


[^1]: Federal Aviation Administration, "Advisory Circular: Composite Aircraft Structure," *U.S. Department of Transportation*, 2009.
[^2]: A. Ellison, "Segmentation of X-ray CT and Ultrasonic Scans of Impacted Composite Structures for Damage State Interpretation and Model Generation," PhD Dissertation, *UC San Diego*, 2020.

## Relevant Links
1. [UC San Diego Research Data Collection (RDCP)](https://doi.org/10.6075/J0G16118): Code development and testing dataset along with processed output/figures are posted here with documentation about how the data was collected and created
   
2. Jessica Chan’s master’s thesis: Link to be posted shortly when published, Chapter 3: Code development is a detailed description of how the code functions
   
3. [Barrett Romasko’s master’s thesis](https://escholarship.org/uc/item/16h2v5xf): Used 26 of 81 C-scans from this dataset collected by Barrett to develop and test the code (this is part of what is posted in the UC San Diego RDCP collection)
   
4. [Mac Delany’s master’s thesis](https://escholarship.org/uc/item/6q32d5q5): Used front and back C-scan from sample LV-162 to validate code in conjunction with Andrew’s work on the same sample
   
5. [Andrew Ellison’s PhD dissertation](https://escholarship.org/uc/item/3433636k): Used CT X-ray scan and processed UT C-scan of the front side of LV-162 to validate code
   
6. [Andrew Ellison’s shadow delamination paper](https://doi.org/10.1177/0021998319865311): Paper presents a shadow extension algorithm demonstrated using the LV-162 sample for predicting shape of shadowed damaged regions which could be combined with this code in the future to create a more complete 3D reconstruction of the damage state
   
7. [MathWorks File Exchange](https://www.mathworks.com/matlabcentral/fileexchange/125985-ultrasonic-c-scan-segmentation-for-composites): Releases of the code are also published here

## Acknowledgments

Thank you to:

- Professor Hyonny Kim for advising me on the development of this code
- Barrett Romasko for testing and scanning the composite sample dataset used for testing and development
- Andrew Ellison for explaining to me how to process C-scans and processing the C-scans and X-ray CT scan of the sample used to validate the code
- Mac Delany for testing and scanning the composite sample dataset used for validating the code

## User Guide

The overall structure of the code is shown below as a summary:

<p align="center">
   <img src=assets/code_diag.png  width="90%">
</p>

0. Install the following MATLAB toolboxes if you don’t have them already:
-  Curve Fitting Toolbox
- Image Processing Toolbox
- Parallel Computing Toolbox
- Signal Processing Toolbox

1. When running the code for the first time, it is suggested to test one sample first before attempting to process all samples in order to adjust parameters. Pick a sample you would like to use.

2. We will be using `test.m` to adjust parameters, which is an exact copy of `main.m` but with parallel for loops removed to allow for helper figures to appear. Parallel for loops do not allow for figures to appear. Parameters can be copied over after finishing adjusting.

3. Just like MATLAB built in functions, type `help functionName` into the Command Window for documentation

### readcscan
1. Format your raw UT C-scan data in a supported character delimited file type (.csv, .txt, .dat) following the format below (header information is okay and will be trimmed automatically):

<p align="center">
   <img src=assets/csv_format.png  width="70%">
</p>

2. Run `foldersetup.m` in the same directory as the code to create the required folder structure for inputs, outputs, and figures.

3. Move all formatted raw UT C-scan data into the Input folder

4. Open `test.m` and edit Section ii to be a string array list of your file names. When adjusting parameters, you will only have one file name, but in general it will look like this:

   ` fileNames = ["sample-1";"sample-2","sample-3"];  `

If there is a sample with front and back side C-scans, `fileNames` should be formatted as the following:

   ` fileNames = ["sample-1";"sample-1-back"];  `

5. In Section A, update `delim` and `fileExt` to the character delimiter (i.e. ' ', ',') and file extension (including '.', i.e. '.csv')

6. If your data does not have equal resolution along both dimensions, calculate the appropriate down sampling required to have equal resolution. Update `dRow` and `dCol` accordingly. For example, if the data has equal resolution, leave both to 1. If you would like to sample every point along the row direction, set `dRow` to 1, but you would like to sample every 5th point along the column direction, set `dCol` to 5.

7. In `test.m`, Section iii, edit all read function values to be false except for `runRead`

8. Run `test.m` and go to `Output\cscan` to check if the saved .mat files are the expected size. They should be size `[row x column x data points per A-scan]`.

### processcscan
0. In `test.m`, Section B, enter the sampling period, `dt`, in microseconds used to collect the A-scan signals

1. First we will set the parameters for finding a rectangular box bounding the damaged region. The relevant parameters are illustrated below:

<p align="center">
   <img src=assets/dam-bound-box.png  width="90%">
</p>

2. The purpose of `bounds`, in red, is to define a search area that excludes artifacts that may be erroneously detected as damage such as the foam tape plate orientation indicator and standoffs the sample may be resting on. You can make an initial guess for an appropriate search area using the sampling resolution to convert to matrix indices. It should be in `[startRow endRow startCol endCol]` format in Section B.

3. Choose a reasonable value for `incr`, this is in matrix indices and will define the coarse grid size, in yellow, used to search for the start of damage. The search method is shown below:

<p align="center">
   <img src=assets/dam-box-search.png  width="60%">
</p>

Damage bounding box search process. (A) Search along columns, (B) picking start row and end row indices, (C) search along rows, (D) picking start and end column indices.

4. Pick a grid of points using `baseRow` and `baseCol` that represent a grid of points in an undamaged region of the sample, shown as green dots. A baseline TOF will be calculated using the mode of these points

5. Leave `pad`, `cropThresh`, `minProm1`, `noiseThresh`, `maxWidth` at the orginal value, this will be adjusted later.

6. If intersted in creating a dent depth map, set `t1` equal to true. This will increase run time significantly as it requires the whole sample to be processed. An example of a first peak TOF figure is shown below:

<p align="center">
   <img src=assets/t1.png  width="70%">
</p>

7. Set `res` to the desired resolution for all saved figures in dpi (dots per inch). Set `fontSize` to desired font size for all saved figures in pixels (same font size measurements as in Microsoft Word or Google Docs)

8. In `test.m`, Section iii, edit all read function values to be false except for `runProcess` and `testProcess` then run `test.m`

9. Use the damage bounding box figure to adjust `bounds`, `incr`, `baseRow`, `baseCol`, and `pad` accordingly. An example of the figure is shown below:

<p align="center">
   <img src=assets/dam-bound-box-ex.png  width="50%">
</p>

   If regions of damage are being cropped by the damage bounding box, increase `pad` by the number of `incr` needed to expand the bounding box, in blue, to include the whole damage area. Decrease `pad` if desired to create a tighter bounding box. `pad` should be a whole number and is defined as (1 + `pad` x `incr`) added to all sides of the damage bounding box.

10. Use the damage bounding box figure and queryable raw TOF figure to check if `cropThresh` should be increased or decreased by querying TOF values at relevant points. If the difference between the current grid search point and the calculated baseline TOF is greater than `cropThresh`, then the point is detected as damaged.

*Note: The helper figures produced by this code will be flipped about the x-axis (rows) because of MATLAB plotting idiosyncrasies, but the row, column and TOF values are correct.

### plottest (plotascan)
0. Skip ahead to `plottest`, it will be useful for adjusting `minProm1`, `noiseThresh`, `maxWidth` from `processcscan`

1. Shown below is a raw TOF figure showing the results of setting `minProm1` too low (`minProm1` = 0):

<p align="center">
   <img src=assets/low-minProm1.png  width="30%">
</p>

2. Using the queryable raw TOF figure, query the row and column locations of a light blue artifact region. In `test.m`, in Section D, set `rowRange` and `colRange` to the rows and columns of interest.

3. In Section iii, edit all read function values to be false except for `runTest` then run `test.m`

4. An example of the output is shown below with the figure and the Command Window output side-by-side:

<p align="center">
   <img src=assets/plotascans.png  width="90%">
</p>

In the above example, the first, third, and fifth peaks are a result of noise and slight changes in the data and do not represent peaks of interest. Prominence is a measure of how much a peak stands out because of its height and location relative to neighboring peaks. Any peaks with a prominence less than `minProm1` is not detected. By looking at the corresponding prominence value printed in the Command Window, a good choice for `minProm1` is 0.03, so that only the second and fourth peak are detected.

5. Steps 2-4 can be repeated, if necessary, for setting `noiseThresh`. If the average of the signal at a point is less than `noiseThresh`, the point is not processed and set to zero. An example is seen in the bottom left corner of the figure showing raw TOF results with a too low `minProm1`

6. Steps 2-4 can be repeated for setting `maxWidth`. If the width of a peak is greater than `maxWidth`, then the peak is marked as "wide". These peaks be be skipped when segmenting the TOF in `segcscan`. An example of a "wide" peak is shown below. These peaks represent damage that is close to the surface, blue, but where more than one peak is detected.

<p align="center">
   <img src=assets/plotascans-wide.png  width="90%">
</p>

### segcscan (Part 1 of 2)

0. An overview of how `segcscan` works is shown below:

<p align="center">
   <img src=assets/segcscan-code-diag.png  width="100%">
</p>

Inflection points in this code refer to points that outline where the damage changes from one layer to another in the laminate. `labelpeaks` and `magpeaks` process the raw TOF from `processcscan` row-wise and column-wise in order to obtain an inflection point map. All four resulting inflection point maps are combined using an OR operation. Morphological processing is used to clean up, close gaps, and label connected regions in the inflection point map. The TOF value in each labeled connected region is assigned to the mode value of the region it is a part of. For details of the process, see Section 3.6 of [Jessica's MS thesis]() (Link to be included when published).

[//]: # (Link to be included when published)

1. In `test.m`, in Section C, leave `minProm2`, `peakThresh` at original value. This will be adjusted later.

2. Set `modeThresh` to `hig` and seEl to `[0 0 0 0]`

3. In Section iii, edit all read function values to be false except for `runSeg` and `testSeg` then run `test.m`

4. Adjust `peakThresh` using the combination inflection point figure. Below is an example of `peakThresh` set too low (`peakThresh` = 0.02) and an adjusted optimal `peakThresh` value (`peakThresh` = 0.04):

<p align="center">
   <img src=assets/peakthresh.png  width="50%">
</p>

A figure explaining how `peakThresh` is used is shown below:

<p align="center">
   <img src=assets/labpeak-peakthresh.png  width="80%">
</p>

In the peak labeling process, each peak in each A-scan receives a unique numerical label. If a peak location change is greater than `peakThresh`, then the peak is considered a new unique peak and given a different label. Inflection points are marked when the second peak changes labels such as Column 96-97 and Column 98-99 in the example above. As mentioned in the summary of `segcscan`, the peak labeling and inflection point finding process occurs twice, once along rows and once along columns.

It is recommended to adjust `peakThresh` as a multiple of the sampling period, `dt`. In the example above the two different values of `peakThresh` were 1 x `dt` (0.02) and 2 x `dt` (0.04) respectively.

### plottest (plotpeak2)

0. Skip to `plottest` again. It will be used to help adjust `minProm2`. A figure explaining how `minProm2` is shown below:

<p align="center">
   <img src=assets/magpeak-minprom2.png  width="90%">
</p>

`minProm2` is used to exclude noisy peaks when looking at the magnitude of the second peak across a row or column. In this example, the layer change occurs at Column 118, where the magnitude of the second peak is at a local mininum.

*Note: in the plot of second peak magnitude, the negative value is taken to turn local mininum into local maximums so that the built-in MATLAB function `findpeaks` can detect them.

1. Pick a direction for `dir` ('row' or 'col') and a row or column number for `num` in Section D. A good starting point is to look at the centerline along the row or column direction.

2. In Section iii, edit all read function values to be false except for `runTest` then run `test.m`

3. Use the second peak magnitude figure and Command Window output to adjust `minProm2`.  An example is shown below:

<p align="center">
   <img src=assets/plotpeak2-fig.png  width="70%">
</p>

4. The combination inflection point figure from `segcscan`, shown below, should also be used in tandem to adjust the `minProm2` value. A higher `minProm2` value will create a less noisy inflection points map, but with more gaps and a lower `minProm2` value will create a noisier map, but with less gaps.

<p align="center">
   <img src=assets/inflection-pts.png  width="70%">
</p>

### segcsan (2 of 2)

1. Use the process and queryable inflection points figure to adjust `seEl` input. The `seEl` input is in `[45 -45 90 0]` format, where each value designates the length of the structuring element in pixels. The first value is a structuring element in the shape of a one pixel wide line angled at 45 degrees, with the rest in the same form. If there are gaps not filled by the default morphological processing steps in the code, then the user should use the least number and shortest elements necessary to close the gaps.

For example, if there is a 4 pixel gap at 45 degrees, then a 5 pixel, 45 degree structuring element should be used. If values are left as zero, that structuring element is not used. The length should always be one pixel longer than the biggest gap present.

An example of the process figure is shown below, where the top right plot is the morphologically processed inflection points map and the bottom left plot is a plot of the labeled connected regions plotted by color. Each color represents an enclosed damaged region.

<p align="center">
   <img src=assets/process.png  width="50%">
</p>

2. Use the process, compare, queryable raw TOF and queryable inflection points figure to adjust the `modeThresh` input. This input can be used for gradually transitioning regions that are not currently detectable by the code or near surface damage that is also currently unable to be detected. Examples of near surface damage requiring lower `modeThresh` input is shown below.

<p align="center">
   <img src=assets/lo-modethresh1.png  width="50%">
</p>

`modeThresh` is used to process the TOF map. If the difference between the TOF value of the current point and the mode value of the connected region it belongs to is greater than `modeThresh`, then the TOF value at the point is not changed to the mode value of the connected region. Additionally, the boundaries of the connected regions are not included in any connected regions, so all TOF values located at a boundary are not changed.

<p align="center">
   <img src=assets/lo-modethresh2.png  width="50%">
</p>

A lower `modeThresh` value means that the processed TOF map will look more similar to the raw TOF map and that less artifacts will be removed. A higher `modeThresh` value means that the processed TOF map will have more artifacts removed, but gradual changes in TOF value or close to surface damage regions may merge together.

Suggested `modeThresh` values of `hig`, `med`, and `low` are included in the `test.m` file in Section C.

A compare figure is shown below as an example of where more artifacts are removed:

<p align="center">
   <img src=assets/compare.png  width="70%">
</p>

### plotfig
1. Update `plateThick` to the thickness of your sample in mm and `nLayers` to the number of layers in the sample layup.

2. In Section iii, edit all read function values to be false except for `runFig` then run `test.m`

3. Check damage layer figures in 2D and 3D to see if results are as expected. Examples are shown below:

<p align="center">
   <img src=assets/plotfig.png  width="70%">
</p>

### mergecscan
0. This section is only applicable if there are front and back side C-scans of sample(s).

1. In Section iii, edit `filesMerge` to be 1. When processing more than one sample with front and back C-scans, the file indices included should be front C-scans only. So if `fileName` was:

`fileName = ["sample-1","sample-2","sample-1-back","sample-2-back"]`

Then, `filesMerge` should be:

`filesMerge = 1:2`

Adjust the file index offset, `di`, if there is a mix of front side C-scans only samples and front/back side C-scan samples. For example, if `fileName` was:

`fileName = ["sample-1","sample-2","sample-3","sample-4","sample-3-back","sample-4-back"]`

Then `di` should be equal to 2 (index of first front/back scan - 1).

2. Set `dx` and `dyMergeCscan` for each sample to be equal to zero.

3. In Section iii, edit all read function values to be false except for `runMerge` and `testMerge` then run `test.m`

4. Use the merge check figure to adjust the front side C-scan damage outline vertically and horizontally relative to the back side C-scan.

<p align="center">
   <img src=assets/merge-check.png  width="90%">
</p>

Units are in pixels. `dx` left is negative, right is positive. `dyMergeCscan` down is negative, right is positive. The darker grey outline is the front outline and the lighter grey outline is the back outline.

5. When the outlines match up, check the front, back and hybrid 3D reconstruction figure. An example is shown below:

<p align="center">
   <img src=assets/front-back-hybrid.png  width="90%">
</p>

### plotcustom
0. This section may not be of interest to everyone, but can be adapted to plot other figures. The original purpose was to plot the unprocessed damage layer map, the processed damage layer map, and the Mistras/UTWin damage layer map side by side for comparison.

This function was kept in the code in case others want to plot comparisons with commercial C-scan processing sofware

1. Set `startRowUT`, `endRowUT`, `startColUT`, `endColUT` to pixel row/col values to crop the UTWin screenshots to only include the damage layer map. GIMP or similar software can be used to find the appropriate crop values.

2. In Section iii, edit all read function values to be false except for `runCustom` and `testCustom` then run `test.m`

3. Similar to `mergecscan`, update `dyPlotCustom` to adjust the UTWin image vertically where up is positive and down is negative.

4. Check the UTWin comparison figure to see if all damage maps are vertically aligned. An example is shown below:

<p align="center">
   <img src=assets/utwin.png  width="100%">
</p>

As shown in the figure, the code is able to define lobes of damage near the surface that appear as dark blue and black in the UTWin image, which the sofware is unable to resolve. The processed damage map removes donut artifcats while retaining detail in the lobes near the top surface of the sample.

## Input/Output Files & Figures Summary

### readcscan
```
readcscan(fileName,inFolder,outFolder,delim,dRow,dCol)
   
   Requirement: Down sample to equal resolution along row and col

   Input: \inFolder\fileName.csv
   Output: \outFolder\fileName-
                               cscan.mat 3D matrix - [row x col x # data pts/A-scan]
```

### processcscan
```
processcscan(fileName,outFolder,figFolder,dt,bounds,incr,baseRow,baseCol,cropThresh,pad,minProm1,noiseThresh,maxWidth,calcT1,test,fontSize,res)

   Input: \outFolder\fileName-cscan.mat
   Output: \outFolder\fileName-
                               rawTOF   .mat 2D matrix – [row x col]
                               peak     .mat 2D matrix – [row x col]
                               locs     .mat 2D matrix – [row x col]
                               wide     .mat 2D matrix – [row x col]
                               nPeaks   .mat 2D matrix – [row x col]
                               cropCoord.mat 2D matrix – [1 x 4]
                               t1       .mat 2D matrix – [row x col]
   Figures: \figFolder\fileName-
                                t1.        .fig/.png
                                damBoundBox.fig/.png
                                rawTOFquery.fig
                                rawTOF     .fig/.png
   Functions:
      - calct1
      - calctof
      - findbound
      - implot
      - imsave
      - imscatter
      - plotbounds
```

### segcsan
```
segcscan(fileName,outFolder,figFolder,minProm2,peakThresh,modeThresh,seEl,test,fontSize,res)
   Input: \outFolder\fileName-
                               rawTOF   .mat 2D matrix – [row x col]
                               peak     .mat 2D matrix – [row x col]
                               locs     .mat 2D matrix – [row x col]
                               wide     .mat 2D matrix – [row x col]
                               nPeaks   .mat 2D matrix – [row x col]
                               cropCoord.mat 2D matrix – [1 x 4]
   Output: \outFolder\fileName-
                               tof   .mat 2D matrix – [row x col]
                               inflpt.mat 2D matrix – [cropRow x cropCol]
                               mask  .mat 2D matrix – [cropRow x cropCol]
                               bound .mat 2D matrix – [cropRow x cropCol]
                               peak2 .mat 2D matrix – [cropRow x cropCol]
   Figures: \figFolder\fileName-
                                comboInflpt         .fig/.png
                                inflptQuery         .fig
                                masks               .fig/.png
                                process             .fig/.png
                                compare             .fig/.png
                                tof                 .fig/.png
   Functions:
      - implot
      - imsave
      - imscatter
      - labelpeaks
      - magpeaks
```

### plotfig
```
plotfig (fileName,outFolder,figFolder,plateThick,nLayers,fontSize,res)
   Input: \outFolder\fileName-
                               tof      .mat 2D matrix – [row x col]
                               cropCoord.mat 2D matrix – [1 x 4]
                               mask     .mat 2D matrix – [cropRow x cropCol]
   Output: \outFolder\fileName-
                               damLayers.mat 2D matrix – [row x col]
   Figures: \figFolder\fileName-
                                damLayers.fig/.png
                                3Dplot   .fig/.png
   Functions:
      - implot
      - imsave
```

### mergecscan
```
mergecscan (fileName,outFolder,figFolder,dx,dy,test,fontSize,res)
   
   Requirement: Same front and back C-scan dimensions [row x col]
   
   Input: \outFolder\fileName-
                               mask     .mat 2D matrix – [cropRow x cropCol]
                               damLayers.mat 2D matrix – [row x col]
                               cropCoord.mat 2D matrix – [1 x 4]
                               bound    .mat 2D matrix – [cropRow x cropCol]
   Output: \outFolder\fileName-
                               hybridCscan.mat 2D matrix – [cropRow x cropCol]
   Figures: \figFolder\fileName-
                                hybridCscan    .fig/.png
                                frontBackHybrid.fig/.png
   Functions:
      - imsave
```

### plotcustom
```
plotcustom (fileName,inFolder,outFolder,figFolder,utwincrop,dy,plateThick,test,fontSize,res)
   Input:   \outFolder\fileName-
                                 rawTOF   .mat 2D matrix – [row x col]
                                 tof      .mat 2D matrix – [row x col]
                                 cropCoord.mat 2D matrix – [1 x 4]
            \inFolder\utwin\fileName      .bmp image file
   Figures: \figFolder\fileName- 
                                 utwin    .fig/.png
   Functions:
      - implot
      - imsave
```
