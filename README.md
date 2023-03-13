# Ultrasonic C-scan Segmentation for Composites

## Description

This code was developed as part of Jessica Chan’s master’s thesis in Dr Hyonny Kim’s lab at UC San Diego. The code takes pulse-echo ultrasonic C-scan data in character delimited formats (.csv, .txt, .dat) of aerospace composites with impact damage and creates a 3D reconstruction of the damage state. The code also calculates time-of-flight, creates a mask of the overall damaged region, and merges front and back C-scans of a sample when available. The code was developed in MATLAB 2022b, but works for 2019b or later.

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

4. Open `test.m` and edit Section ii to be a string array list of your file names, when adjusting parameters, you will only have one file name, but in general it will look like this:

   ` fileNames = ["sample-1";"sample-2",”sample-3”];  `

5. In Section A, update `delim` and `fileExt` to the character delimiter and file extension (including '.', i.e. '.csv')

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

6. If intersted in creating a dent depth map, set `t1` equal to true. This will increase run time significantly as it requires the whole sample to be processed.

7. Set `res` to the desired resolution for all saved figures in dpi (dots per inch).

8. In test.m, Section iii, edit all read function values to be false except for `runProcess` and `testProcess`

9. Use the damage bounding box figure to adjust `bounds`, `incr`, `baseRow`, `baseCol`, and `pad` accordingly. An example of the figure is shown below:

<p align="center">
   <img src=assets/dam-bound-box-ex.png  width="50%">
</p>

   If regions of damage are being cropped by the damage bounding box, increase `pad` by the number of `incr` needed to expand the bounding box, in blue, to include the whole damage area. Decrease `pad` if desired to create a tighter bounding box. `pad` should be a whole number and is defined as (1 + `pad` x `incr`) added to all sides of the damage bounding box.

10. Use the damage bounding box figure and queryable raw TOF figure to check if `cropThresh` should be increased or decreased by querying TOF values at relevant points. If the difference between the current grid search point and the calculated baseline TOF is greater than `cropThresh`, then the point is detected as damaged.

*Note: The helper figures produced by this code will be flipped about the x-axis (rows) because of MATLAB plotting idiosyncrasies, but the row, column and TOF values are correct.

### plottest
0. Skip ahead to `plottest`, it will be useful for adjusting `minProm1`, `noiseThresh`, `maxWidth` from `processcscan`

1. Shown below is a raw TOF figure showing the results of setting `minProm1` too low (`minProm1` = 0):

<p align="center">
   <img src=assets/low-minProm1.png  width="50%">
</p>

2. Using the queryable raw TOF figure, query the row and column locations of a light blue artifact region. In `test.m`, in Section D, set `rowRange` and `colRange` to the rows and columns of interest.

3. In Section iii, edit all read function values to be false except for `runSeg`

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

### segcscan


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
