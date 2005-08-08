function handles = SpotIdentifier(handles)

% Help for the Spot Identifier module:
% Category: Object Identification and Modification
%
% Sorry, this module has not yet been fully documented. Its purpose is to
% label spots of cell microarrays with gene information or sample
% numbers so that interesting spots can be easily identified.
%
% To identify spots, there are two main choices:
% 
% (1) MANUAL (using SpotIdentifier module) In this mode, you manually
% mark a known location in the grid and have the rest of the positions
% calculated from those marks, no matter what the image itself looks
% like.  This mode requires manually clicking on a marker spot for
% each image (if it is not visible you have to click where it ought to
% be). Or, if your images are perfectly aligned you can just type in
% the pixel coordinates of the control spots once for all the images.
% This mode requires that the diameter of spots and distance between
% spots (in pixels) is consistent for every image - you type in these
% values before beginning. Right now the top left spot is the marker
% spot which must be used, but we could write code to allow any spot
% to be clicked (e.g. bottom right corner, or an arbitrary spot for
% each different image).  We could also write code so that you
% manually click on two control spots in each image and the
% spot-to-spot distance is calculated automatically.
% 
% (2) AUTOMATIC - (using IdentifyWellSpots module) Have the computer
% automatically identify all the spots - right now this requires that
% there is at least one nice spot present and easily visible to the
% software in the top and bottom row, and at least one nice spot in
% left and right columns. The computer will find as many spots as
% possible (some will initially not be found if they are faint due to
% the experiment). It will then calculate the average diameter of all
% spots that were found (or you can manually override this value). If
% the spots are slightly out of alignment with each other, this allows
% the identification to be a bit flexible and adapt to the real shape
% of the spots. Also, this method allows measuring the size of each
% spot (in theory - right now it�s overriden by the average diameter
% size because it assumes you want to measure intensity even if a spot
% is missing or faint. We could write new code to allow you to not
% override the natural shape and size of the spot).
% 
% It works for our basic needs right now, but improvements/fixes need
% to be made (in addition to the ones mentioned above):
% (0) I have not tested all of the various ways to rotate and mark the
% top, left corner spot.
% (1) I am not confident that the offsets and flipping left/right and
% top/bottom are accurate at the moment.
% (2) Loading gene names from an Excel file works only for a PC at the
% moment, although I think it can be adjusted by skipping or adding an
% entry to the imported data.
% (3) Right now the numbers are in columns, and I want to add the
% option of rows.
% (4) When clicking "Show coordinates" or "Show sample info", all the
% numbers across the whole image are displayed, which takes a while
% and slows down zoom functions. I would like to be able to click on
% the image and show the coordinates for that spot.
% (5) We would like to be able to show several images within the same
% figure window and toggle between them, so that controls and
% different wavelength images can be compared.
%
% SAVING IMAGES: The rotated image produced by this module can be
% easily saved using the Save Images module, using the name you
% assign. If you want to save other intermediate images, alter the
% code for this module to save those images to the handles structure
% (see the SaveImages module help) and then use the Save Images
% module.
%
% See also IMAGETILER or IDENTIFYWELLSPOTS.

% CellProfiler is distributed under the GNU General Public License.
% See the accompanying file LICENSE for details.
%
% Developed by the Whitehead Institute for Biomedical Research.
% Copyright 2003,2004,2005.
%
% Authors:
%   Anne Carpenter <carpenter@wi.mit.edu>
%   Thouis Jones   <thouis@csail.mit.edu>
%   In Han Kang    <inthek@mit.edu>
%
% $Revision$

% PROGRAMMING NOTE
% HELP:
% The first unbroken block of lines will be extracted as help by
% CellProfiler's 'Help for this analysis module' button as well as Matlab's
% built in 'help' and 'doc' functions at the command line. It will also be
% used to automatically generate a manual page for the module. An example
% image demonstrating the function of the module can also be saved in tif
% format, using the same name as the module, and it will automatically be
% included in the manual page as well.  Follow the convention of: purpose
% of the module, description of the variables and acceptable range for
% each, how it works (technical description), info on which images can be
% saved, and See also CAPITALLETTEROTHERMODULES. The license/author
% information should be separated from the help lines with a blank line so
% that it does not show up in the help displays.  Do not change the
% programming notes in any modules! These are standard across all modules
% for maintenance purposes, so anything module-specific should be kept
% separate.

% PROGRAMMING NOTE
% DRAWNOW:
% The 'drawnow' function allows figure windows to be updated and
% buttons to be pushed (like the pause, cancel, help, and view
% buttons).  The 'drawnow' function is sprinkled throughout the code
% so there are plenty of breaks where the figure windows/buttons can
% be interacted with.  This does theoretically slow the computation
% somewhat, so it might be reasonable to remove most of these lines
% when running jobs on a cluster where speed is important.
drawnow

%%%%%%%%%%%%%%%%
%%% VARIABLES %%%
%%%%%%%%%%%%%%%%

% PROGRAMMING NOTE
% VARIABLE BOXES AND TEXT:
% The '%textVAR' lines contain the variable descriptions which are
% displayed in the CellProfiler main window next to each variable box.
% This text will wrap appropriately so it can be as long as desired.
% The '%defaultVAR' lines contain the default values which are
% displayed in the variable boxes when the user loads the module.
% The line of code after the textVAR and defaultVAR extracts the value
% that the user has entered from the handles structure and saves it as
% a variable in the workspace of this module with a descriptive
% name. The syntax is important for the %textVAR and %defaultVAR
% lines: be sure there is a space before and after the equals sign and
% also that the capitalization is as shown.
% CellProfiler uses VariableRevisionNumbers to help programmers notify
% users when something significant has changed about the variables.
% For example, if you have switched the position of two variables,
% loading a pipeline made with the old version of the module will not
% behave as expected when using the new version of the module, because
% the settings (variables) will be mixed up. The line should use this
% syntax, with a two digit number for the VariableRevisionNumber:
% '%%%VariableRevisionNumber = 01'  If the module does not have this
% line, the VariableRevisionNumber is assumed to be 00.  This number
% need only be incremented when a change made to the modules will affect
% a user's previously saved settings. There is a revision number at
% the end of the license info at the top of the m-file for revisions
% that do not affect the user's previously saved settings files.

%%% Reads the current module number, because this is needed to find
%%% the variable values that the user entered.
CurrentModule = handles.Current.CurrentModuleNumber;
CurrentModuleNum = str2double(CurrentModule);

%textVAR01 = What did you call the image to be rotated and labeled with spot information?
%infotypeVAR01 = imagegroup
ImageName = char(handles.Settings.VariableValues{CurrentModuleNum,1});
%inputtypeVAR01 = popupmenu

%textVAR02 = Choose rotation method.
%choiceVAR02 = No rotation
%choiceVAR02 = Coordinates
%choiceVAR02 = Mouse
RotateMethod = char(handles.Settings.VariableValues{CurrentModuleNum,2});
RotateMethod = RotateMethod(1);
%inputtypeVAR02 = popupmenu

%textVAR03 = What do you want to call the rotated image?
%infotypeVAR03 = imagegroup indep
%defaultVAR03 = RotatedImage
RotatedImageName = char(handles.Settings.VariableValues{CurrentModuleNum,3});

%textVAR04 = What do you want to call the objects identified by this module?
%infotypeVAR04 = objectgroup indep
%defaultVAR04 = Spots
ObjectName = char(handles.Settings.VariableValues{CurrentModuleNum,4});

%textVAR05 = What is the radius of each object in pixels?
%defaultVAR05 = 80
RadiusSize = char(handles.Settings.VariableValues{CurrentModuleNum,5});

%textVAR06 = Mark the control spot by coordinates or by mouse?
%choiceVAR06 = Coordinates
%choiceVAR06 = Mouse
MarkingMethod = char(handles.Settings.VariableValues{CurrentModuleNum,6});
MarkingMethod = MarkingMethod(1);
%inputtypeVAR06 = popupmenu

%textVAR07 = Enter the number of rows, columns
%defaultVAR07 = 40,140
RowsColumns = char(handles.Settings.VariableValues{CurrentModuleNum,7});
%%% Extracts the rows and columns from the user's input.
try
    RowsColumnsNumerical = str2num(RowsColumns);%#ok We want to ignore MLint error checking for this line.
    NumberRows = RowsColumnsNumerical(1);
    NumberColumns = RowsColumnsNumerical(2);
catch error('Image processing was canceled because your entry for rows, columns in the Spot Identifier module was not understood.')
end

%textVAR08 = Enter the spacing between rows, columns (vertical spacing, horizontal spacing)
%defaultVAR08 = 57,57
HorizVertSpacing = char(handles.Settings.VariableValues{CurrentModuleNum,8});
%%% Extracts the vertical and horizontal spacing from the user's input.
try
    HorizVertSpacingNumerical = str2num(HorizVertSpacing);%#ok We want to ignore MLint error checking for this line.
    VertSpacing = HorizVertSpacingNumerical(1);
    HorizSpacing = HorizVertSpacingNumerical(2);
catch error('Image processing was canceled because your entry for the spacing between rows, columns (vertical spacing, horizontal spacing) in the Spot Identifier module was not understood.')
end

%textVAR09 = Will you be specifying the distance (the next option) in units of pixels or spots?
%choiceVAR09 = Pixels
%choiceVAR09 = Spots
SpacingUnits = char(handles.Settings.VariableValues{CurrentModuleNum,9});
%inputtypeVAR09 = popupmenu

%textVAR10 = Enter the distance from the top left marker to the center of the nearest spot (vertical, horizontal)
%defaultVAR10 = 57,0
HorizVertOffset = char(handles.Settings.VariableValues{CurrentModuleNum,10});
%%% Extracts the vertical and horizontal offset from the user's input.
try
    HorizVertOffsetNumerical = str2num(HorizVertOffset);%#ok We want to ignore MLint error checking for this line.
    VertOffset = HorizVertOffsetNumerical(1);
    HorizOffset = HorizVertOffsetNumerical(2);
catch error('Image processing was canceled because your entry for the distance from the top left marker to the center of the nearest spot (vertical, horizontal) in the Spot Identifier module was not understood.')
end
if strcmp(SpacingUnits,'Spots')
    VertOffset = VertOffset*VertSpacing;
    HorizOffset = HorizOffset*HorizSpacing;
end

%textVAR11 = Is the first spot at the Left or Right?
%choiceVAR11 = Left
%choiceVAR11 = Right
LeftOrRight = char(handles.Settings.VariableValues{CurrentModuleNum,11});
LeftOrRight = LeftOrRight(1);
%inputtypeVAR11 = popupmenu

%textVAR12 = Is the first spot at the Bottom or Top?
%choiceVAR12 = Top
%choiceVAR12 = Bottom
TopOrBottom = char(handles.Settings.VariableValues{CurrentModuleNum,12});
TopOrBottom = TopOrBottom(1);
%inputtypeVAR12 = popupmenu

%textVAR13 = Would you like to count by rows or columns?
%choiceVAR13 = Rows
%choiceVAR13 = Columns
RowsOrColumns = char(handles.Settings.VariableValues{CurrentModuleNum,13});
%inputtypeVAR13 = popupmenu

%textVAR14 = Enter the Excel file name from which to load spot information (you can type a file name here if the file is in the default image directory and if you want to use the first sheet of the file).
%choiceVAR14 = Do not load
%infotypeVAR14 = datagroup
DataName = char(handles.Settings.VariableValues{CurrentModuleNum,14});
%inputtypeVAR14 = popupmenu

%textVAR15 = Do you want to label the spots only (takes less memory) or will you be using them in downstream modules (e.g. saving an image of them or measuring them)?
%choiceVAR15 = Label only
%choiceVAR15 = Use downstream
LabelOrUseDownstream = char(handles.Settings.VariableValues{CurrentModuleNum,15});
%inputtypeVAR15 = popupmenu

%textVAR16 = If you are using the spots downstream, what do you want to call the image of the outlines of the objects?
%infotypeVAR16 = imagegroup indep
%defaultVAR16 = Do not save
SaveOutlined = char(handles.Settings.VariableValues{CurrentModuleNum,16}); 

%textVAR17 =  If you are using the spots downstream, what do you want to call the label matrix image?
%infotypeVAR17 = imagegroup indep
%defaultVAR17 = Do not save
SaveColored = char(handles.Settings.VariableValues{CurrentModuleNum,17}); 

%textVAR18 = If you are using the spots downstream and saving the label matrix image, do you want to save it in RGB or grayscale?
%choiceVAR18 = RGB
%choiceVAR18 = Grayscale
SaveMode = char(handles.Settings.VariableValues{CurrentModuleNum,18}); 
%inputtypeVAR18 = popupmenu

%%%VariableRevisionNumber = 4

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PRELIMINARY CALCULATIONS & FILE HANDLING %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow


% PROGRAMMING NOTE
% TO TEMPORARILY SHOW IMAGES DURING DEBUGGING:
% figure, imshow(BlurredImage, []), title('BlurredImage')
% TO TEMPORARILY SAVE IMAGES DURING DEBUGGING:
% imwrite(BlurredImage, FileName, FileFormat);
% Note that you may have to alter the format of the image before
% saving.  If the image is not saved correctly, for example, try
% adding the uint8 command:
% imwrite(uint8(BlurredImage), FileName, FileFormat);
% To routinely save images produced by this module, see the help in
% the SaveImages module.

%%% Reads (opens) the image you want to analyze and assigns it to a variable,
%%% "OrigImage".
%%% Checks whether the image exists in the handles structure.
if isfield(handles.Pipeline, ImageName) == 0
    error(['Image processing has been canceled. Prior to running the Spot Identifier module, you must have previously run a module to load an image. You specified in the Spot Identifier module that this image was called ', ImageName, ' which should have produced a field in the handles structure called ', ImageName, '. The Spot Identifier module cannot find this image.']);
end
OrigImage = handles.Pipeline.(ImageName);
FinalLabelMatrix = zeros(size(OrigImage,1),size(OrigImage,2));

if handles.Current.SetBeingAnalyzed == handles.Current.StartingImageSet
    %%% Determines the figure number to display in.
    fieldname = ['FigureNumberForModule',CurrentModule];
    ThisModuleFigureNumber = handles.Current.(fieldname);
    FigureHandle = CPfigure(handles,ThisModuleFigureNumber);subplot(2,3,[1 2 4 5]);ImageHandle = imagesc(OrigImage); colormap(gray), axis image, pixval off;%#ok We want to ignore MLint error checking for this line.
else
    %%% A new figure is opened each time through the pipeline so that the
    %%% resulting labeled figures are all available to the user for
    %%% viewing.
    FigureHandle = figure; subplot(2,3,[1 2 4 5]);ImageHandle = imagesc(OrigImage); colormap(gray), axis image, pixval off;%#ok We want to ignore MLint error checking for this line.
    %%% Tag new figure so "Close Windows" knows to delete it.
    userData.Application = 'CellProfiler';
    set(FigureHandle,'UserData',userData);
end
drawnow
RotateMethod = upper(RotateMethod);
if strncmp(RotateMethod, 'N',1) == 1
    RotatedImage = OrigImage;
elseif strncmp(RotateMethod, 'M',1) == 1
    Answer2 = CPquestdlg('After closing this window by clicking OK, click on points in the image that are supposed to be aligned horizontally (e.g. a marker spot at the top left and the top right of the image). Then press the Enter key. If you make an error, the Delete or Backspace key will delete the previously selected point. You can use the zoom tools of matlab before clicking on this point by selecting Tools > Zoom in, click to zoom as desired, then select Tools > Zoom in again to deselect the tool. This will return you to the regular cursor so you can click the marker points.','Rotate image using the mouse','OK','Cancel','OK');
    waitfor(Answer2)
    if strcmp(Answer2, 'Cancel') == 1
        error('Image processing was canceled during the Spot Identifier module.')
    end
    [x,y] = getpts(FigureHandle);
    if length(x) ~=2
        error('The Spot Identifier was canceled because you must click on two points then press enter.')
    end
    LowerLeftX = x(1);
    LowerRightX = x(2);
    LowerLeftY = y(1);
    LowerRightY = y(2);
    HorizLeg = LowerRightX - LowerLeftX;
    VertLeg = LowerLeftY - LowerRightY;
    Hypotenuse = sqrt(HorizLeg^2 + VertLeg^2);
    AngleToRotateRadians = asin(VertLeg/Hypotenuse);
    AngleToRotateDegrees = AngleToRotateRadians*180/pi;
    PatienceHandle = CPmsgbox('Image rotation in progress');
    drawnow
    RotatedImage = imrotate(OrigImage, -AngleToRotateDegrees);
    figure(FigureHandle); 
    subplot(2,3,[1 2 4 5]);
    ImageHandle = imagesc(RotatedImage); 
    colormap(gray);
    axis image;
    title('Rotated Image');
    pixval off;
    try %#ok We want to ignore MLint error checking for this line.
        delete(PatienceHandle)
    end
elseif strncmp(RotateMethod, 'C',1) == 1
    %%% Rotates the image based on user-entered coordinates.
    Prompts = {'Enter the X coordinate of the lower left marker', 'Enter the Y coordinate of the lower left marker', 'Enter the X coordinate of the lower right marker', 'Enter the Y coordinate of the lower right marker'};
    Height = size(OrigImage,1);
    Width = size(OrigImage,2);
    Defaults = {'0', num2str(Height), num2str(Width), num2str(Height)};
    Answers = inputdlg(Prompts, 'Enter coordinates', 1, Defaults);
    if isempty(Answers) == 1
        error('Image processing was canceled during the Spot Identifier module.')
    end
    LowerLeftX = str2double(Answers{1});
    LowerLeftY = str2double(Answers{2});
    LowerRightX = str2double(Answers{3});
    LowerRightY = str2double(Answers{4});
    HorizLeg = LowerRightX - LowerLeftX;
    VertLeg = LowerLeftY - LowerRightY;
    Hypotenuse = sqrt(HorizLeg^2 + VertLeg^2);
    AngleToRotateRadians = asin(VertLeg/Hypotenuse);
    AngleToRotateDegrees = AngleToRotateRadians*180/pi;
    PatienceHandle = CPmsgbox('Please be patient; Image rotation in progress');
    drawnow
    RotatedImage = imrotate(OrigImage, -AngleToRotateDegrees);
    figure(FigureHandle); 
    subplot(2,3,[1 2 4 5]);
    ImageHandle = imagesc(RotatedImage);
    colormap(gray);
    axis image;
    title('Rotated Image');
    pixval off;
    try, delete(PatienceHandle), end %#ok We want to ignore MLint error checking for this line.
else
    error('Image processing was canceled because your entry relating to image rotation was not one of the options: No, C, or M.')
end
drawnow
set(ImageHandle,'Tag','MainImage');
if strncmp(MarkingMethod,'C',1) == 1
    %%% Sets the top, left of the grid based on user-entered coordinates.
    Prompts = {'Enter the X coordinate of the top left marker', 'Enter the Y coordinate of the top left marker'};
    Defaults = {'0', '0'};
    Answers = inputdlg(Prompts, 'Top left marker', 1, Defaults);
    if isempty(Answers) == 1
        error('Image processing was canceled during the Spot Identifier module.')
    end
    TopLeftX = str2double(Answers{1});
    TopLeftY = str2double(Answers{2});
elseif strncmp(MarkingMethod,'M',1) == 1
    %%% Sets the top, left of the grid based on mouse clicks.
    Answer3 = CPquestdlg('After closing this window by clicking OK, click on the top left marker in the image then press the Enter key. If you make an error, the Delete or Backspace key will delete the previously selected point.  You can use the zoom tools of matlab before clicking on this point by selecting Tools > Zoom in, click to zoom as desired, then select Tools > Zoom in again to deselect the tool. This will return you to the regular cursor so you can click the marker point.', 'Choose marker point', 'OK', 'Cancel', 'OK');
    if strcmp(Answer3, 'Cancel') == 1
        error('Image processing was canceled during the Spot Identifier module.')
    end
    pixval off;
    [x,y] = getpts(FigureHandle);
    if length(x) ~=1
        error('SpotIdentifier was canceled because you must click on one point then press enter.')
    end
    %%% The numbers must be rounded to the nearest integer to prevent
    %%% errors.
    TopLeftX = round(x(1));
    TopLeftY = round(y(1));
else
    error('Image processing was canceled because your entry relating to marking the top, left corner of the grid was not one of the options: C or M.')
end
drawnow
%%% Calculates the numbers to be displayed on the image and shapes them
%%% properly for display.
OriginX = TopLeftX + HorizOffset;
OriginY = TopLeftY + VertOffset;
NumberSpots = NumberRows*NumberColumns;
Numbers = 1:NumberSpots;
if strcmp(RowsOrColumns,'Columns')
    NumbersGridShape = reshape(Numbers, NumberRows, NumberColumns);
elseif strcmp(RowsOrColumns,'Rows')
    NumbersGridShape = reshape(Numbers,NumberColumns,NumberRows);
    NumbersGridShape = NumbersGridShape';
end
if strcmp(TopOrBottom,'B') == 1
    NumbersGridShape = flipud(NumbersGridShape);
end
if strcmp(LeftOrRight,'R') == 1
    NumbersGridShape = fliplr(NumbersGridShape);
end
%%% Converts to a single column.
LinearNumbers = reshape(NumbersGridShape, 1, NumberSpots);
%%% Converts to text for display purposes.
PositionList{length(LinearNumbers)} = num2str(LinearNumbers(length(LinearNumbers)));
for i = 1:length(LinearNumbers)
    PositionList{i} = num2str(LinearNumbers(i));
end
drawnow

%%% Calculates the locations for all the sample labelings (whether it is
%%% numbers, spot identifying information, or coordinates).
GridXLocations = NumbersGridShape;
for g = 1:size(GridXLocations,2)
    GridXLocations(:,g) = OriginX + (g-1)*HorizSpacing;
end
%%% Converts to a single column.
XLocations = reshape(GridXLocations, 1, NumberSpots);

% %%% Shifts if necessary.
% if strcmp(LeftOrRight,'R') == 1
% XLocations = XLocations - (NumberRows-1)*VertSpacing;
% end
%%% Same routine for Y.
GridYLocations = NumbersGridShape;
for h = 1:size(GridYLocations,1)
    GridYLocations(h,:) = OriginY + (h-1)*VertSpacing;
end
YLocations = reshape(GridYLocations, 1, NumberSpots);

% %%% Shifts if necessary.
% if strcmp(TopOrBottom,'B') == 1
% YLocations = YLocations - (NumberColumns-1)*HorizSpacing;
% end

%%% Draws the Numbers, though they are initially invisible until the
%%% user clicks "Show".
figure(FigureHandle);
text(XLocations, YLocations, PositionList, ...
    'HorizontalAlignment','center', 'Color', 'red','visible','off', ...
    'UserData','PositionListHandles');
drawnow

%%% Identifies the spots as objects for use by downstream modules, if
%%% desired.
if strcmpi(LabelOrUseDownstream,'Use downstream') == 1
    r = str2num(RadiusSize);
    %%% N = 0 is used for the final argument of strel because it makes
    %%% more round-looking disks. It is much slower and so perhaps
    %%% ought to be avoided.
    circle = getnhood(strel('disk',r,0));
    for i = 1:length(LinearNumbers)
        FinalLabelMatrix(YLocations(i)-r:YLocations(i)+r,XLocations(i)-r:XLocations(i)+r)=LinearNumbers(i)*circle;
    end
    %%% It's possible that the boundaries of some objects will be outside
    %%% the bounds of the original image, which might cause downstream
    %%% modules to fail, so an error check is performed and notifies the
    %%% user.  Image processing is not canceled because it may not be
    %%% a problem that some objects are outside.
    if size(OrigImage) ~= size(FinalLabelMatrix)
        errordlg(['Image processing will continue, but some objects identified using the SpotIdentifier module are outside the boundaries of the image. This may cause downstream modules to fail. For example, it is impossible to measure the intensity of an object when part of it lies outside the image.  The size of the original image is (height, width): ', num2str(size(OrigImage)), ' but the farthest object boundaries are at: ', num2str(size(FinalLabelMatrix))])
    end
    figure(FigureHandle);
    subplot(2,3,3);
    FinalColorLabelMatrix=label2rgb(FinalLabelMatrix,'jet', 'k', 'shuffle');
    ObjectImageHandle = imagesc(FinalColorLabelMatrix);
    axis image
    title(['Segmented ',ObjectName]);
    %%% Calculates the object outlines.
    %%% Creates the structuring element that will be used for dilation.
    StructuringElement = strel('square',3);
    %%% Converts the FinalLabelMatrixImage to binary.
    FinalBinaryImage = im2bw(FinalLabelMatrix,.5);
    %%% Dilates the FinalBinaryImage by one pixel (8 neighborhood).
    DilatedBinaryImage = imdilate(FinalBinaryImage, StructuringElement);
    %%% Subtracts the FinalBinaryImage from the DilatedBinaryImage,
    %%% which leaves the ObjectOutlines.
    ObjectOutlines = DilatedBinaryImage - FinalBinaryImage;
    figure(FigureHandle);
    subplot(2,3,6);
    ObjectOutlinesHandle = imagesc(ObjectOutlines);
    title(['Outlined ',ObjectName]);
    axis image
end

%%% Retrieves the spot identifying info from a file, if requested.
if ~strcmp(DataName,'Do not load')
    SpotIdentifyingInfo = handles.Measurements.Image.(DataName);  
    
    [NumberRowsSpotIdentifyingInfo, NumberColumnsSpotIdentifyingInfo] = size(SpotIdentifyingInfo);
    if NumberRowsSpotIdentifyingInfo*NumberColumnsSpotIdentifyingInfo ~= NumberRows*NumberColumns
        error(['There were ', num2str(NumberRowsSpotIdentifyingInfo*NumberColumnsSpotIdentifyingInfo), ' imported data entries, but you specified that there are ', num2str(NumberRows*NumberColumns), ' data entries.']);
    end
    
    if strcmp(RowsOrColumns,'Columns')
        SpotIdentifyingInfo = reshape(SpotIdentifyingInfo, NumberRows, NumberColumns);
    elseif strcmp(RowsOrColumns,'Rows')
        SpotIdentifyingInfo = reshape(SpotIdentifyingInfo,NumberColumns,NumberRows);
        SpotIdentifyingInfo = SpotIdentifyingInfo';
    end
    if strcmp(TopOrBottom,'B')
        SpotIdentifyingInfo = flipud(SpotIdentifyingInfo);
    end
    if strcmp(LeftOrRight,'R')
        SpotIdentifyingInfo = fliplr(SpotIdentifyingInfo);
    end
    %%% Converts to a single column.
    SpotIdentifyingInfo = reshape(SpotIdentifyingInfo, 1, NumberSpots);
    
    %%% Draws the SpotIdentifyingInfo, though they are initially invisible until the
    %%% user clicks "Show".
    figure(FigureHandle);
    
    %%% Text3
    uicontrol('Parent',FigureHandle, ...
        'BackgroundColor',get(FigureHandle,'Color'), ...
        'Position',[330 28 145 14], ...
        'HorizontalAlignment','center', ...
        'String','Spot identifying info:', ...
        'Style','text', ...
        'FontSize',handles.Current.FontSize,'BackgroundColor',[.7,.7,.9]);
    
    ShowSpotIdentifyingInfoButtonFunction = 'Handles = findobj(''UserData'',''SpotIdentifyingInfoHandles''); if isempty(Handles) == 1, CPwarndlg(''No Spot Identifying information was loaded.''), else set(Handles,''visible'',''on''); end, clear Handles';
    uicontrol('Style', 'pushbutton', ...
        'String', 'Show', 'Position', [330 6 45 20], ...
        'Callback', ShowSpotIdentifyingInfoButtonFunction, 'parent',FigureHandle, ...
        'FontSize',handles.Current.FontSize,'BackgroundColor',[.7,.7,.9]);
    HideSpotIdentifyingInfoButtonFunction = 'Handles = findobj(''UserData'',''SpotIdentifyingInfoHandles''); if isempty(Handles) == 1, CPwarndlg(''No Spot Identifying information was loaded.''), else set(Handles,''visible'',''off''); end, clear Handles';
    uicontrol('Style', 'pushbutton', ...
        'String', 'Hide', 'Position', [380 6 45 20], ...
        'Callback', HideSpotIdentifyingInfoButtonFunction, 'parent',FigureHandle, ...
        'FontSize',handles.Current.FontSize,'BackgroundColor',[.7,.7,.9]);
    ChangeSpotIdentifyingInfoButtonFunction = 'Handles = findobj(''UserData'',''SpotIdentifyingInfoHandles''); if isempty(Handles) == 1, CPwarndlg(''No Spot Identifying information was loaded.''), else try, propedit(Handles), catch, CPmsgbox(''A bug in Matlab is preventing this function from working. Service Request #1-RR6M1''), end; end, clear Handles';
    uicontrol('Style', 'pushbutton', ...
        'String', 'Change', 'Position', [430 6 45 20], ...
        'Callback', ChangeSpotIdentifyingInfoButtonFunction, 'parent',FigureHandle, ...
        'FontSize',handles.Current.FontSize,'BackgroundColor',[.7,.7,.9]);

    text(XLocations, YLocations, SpotIdentifyingInfo, ...
        'HorizontalAlignment','center', 'Color', 'white','visible','off', ...
        'UserData','SpotIdentifyingInfoHandles');
end

%%%%%%%%%%%%%%%%%%%%%%
%%% DISPLAY RESULTS %%%
%%%%%%%%%%%%%%%%%%%%%%

% PROGRAMMING NOTE
% DRAWNOW BEFORE FIGURE COMMAND:
% The "drawnow" function executes any pending figure window-related
% commands.  In general, Matlab does not update figure windows until
% breaks between image analysis modules, or when a few select commands
% are used. "figure" and "drawnow" are two of the commands that allow
% Matlab to pause and carry out any pending figure window- related
% commands (like zooming, or pressing timer pause or cancel buttons or
% pressing a help button.)  If the drawnow command is not used
% immediately prior to the figure(ThisModuleFigureNumber) line, then
% immediately after the figure line executes, the other commands that
% have been waiting are executed in the other windows.  Then, when
% Matlab returns to this module and goes to the subplot line, the
% figure which is active is not necessarily the correct one. This
% results in strange things like the subplots appearing in the timer
% window or in the wrong figure window, or in help dialog boxes.
drawnow
%%% Sets the figure to take up most of the screen.
ScreenSize = get(0,'ScreenSize');
NewFigureSize = [ScreenSize(3)*1/6,ScreenSize(4)*1/3, ScreenSize(3)*2/3, ScreenSize(4)*2/3];
set(FigureHandle, 'Position', NewFigureSize)

%PointsPerPixel = 72/get(0,'ScreenPixelsPerInch');
InteractiveZoomButton = findobj(get(FigureHandle,'Children'),'Tag','InteractiveZoom');
set(InteractiveZoomButton,'Visible','off');
%ButtonPos = get(InteractiveZoomButton,'Position');
%ButtonPos(1) = PointsPerPixel*(NewFigureSize(1)-108);
%set(findobj(get(FigureHandle,'Children'),'Tag','InteractiveZoom'),'Position',ButtonPos);
Font = handles.Current.FontSize;
axis image
ShowGridButtonFunction = 'Handles = findobj(''type'',''line''); set(Handles,''visible'',''on''); clear Handles';
uicontrol('Style', 'pushbutton', ...
    'String', 'Show', 'Position', [10 6 45 20], ...
    'Callback', ShowGridButtonFunction, 'parent',FigureHandle, ...
    'FontSize',Font,'BackgroundColor',[.7,.7,.9]);
HideGridButtonFunction = 'Handles = findobj(''type'',''line''); set(Handles,''visible'',''off''); clear Handles';
uicontrol('Style', 'pushbutton', ...
    'String', 'Hide', 'Position', [60 6 45 20], ...
    'Callback', HideGridButtonFunction, 'parent',FigureHandle, ...
    'FontSize',Font,'BackgroundColor',[.7,.7,.9]);
ChangeGridButtonFunction = 'Handles = findobj(''type'',''line''); try, propedit(Handles), catch, CPmsgbox(''A bug in Matlab is preventing this function from working. Service Request #1-RR6M1''), end; clear Handles';
uicontrol('Style', 'pushbutton', ...
    'String', 'Change', 'Position', [110 6 45 20], ...
    'Callback', ChangeGridButtonFunction, 'parent',FigureHandle, ...
    'FontSize',Font,'BackgroundColor',[.7,.7,.9]);
ShowCoordinatesButtonFunction = 'Handles = findobj(''UserData'',''PositionListHandles''); set(Handles,''visible'',''on''); clear Handles';
uicontrol('Style', 'pushbutton', ...
    'String', 'Show', 'Position', [170 6 45 20], ...
    'Callback', ShowCoordinatesButtonFunction, 'parent',FigureHandle, ...
    'FontSize',Font,'BackgroundColor',[.7,.7,.9]);
HideCoordinatesButtonFunction = 'Handles = findobj(''UserData'',''PositionListHandles''); set(Handles,''visible'',''off''); clear Handles';
uicontrol('Style', 'pushbutton', ...
    'String', 'Hide', 'Position', [220 6 45 20], ...
    'Callback', HideCoordinatesButtonFunction, 'parent',FigureHandle, ...
    'FontSize',Font,'BackgroundColor',[.7,.7,.9]);
ChangeCoordinatesButtonFunction = 'Handles = findobj(''UserData'',''PositionListHandles''); try, propedit(Handles), catch, CPmsgbox(''A bug in Matlab is preventing this function from working. Service Request #1-RR6M1''), end; clear Handles';
uicontrol('Style', 'pushbutton', ...
    'String', 'Change', 'Position', [270 6 45 20], ...
    'Callback', ChangeCoordinatesButtonFunction, 'parent',FigureHandle, ...
    'FontSize',Font,'BackgroundColor',[.7,.7,.9]);

ChangeColormapButtonFunction = 'ImageHandle = findobj(gca, ''type'',''image''); if strcmp(get(ImageHandle,''UserData''),''Color'') == 1, CPmsgbox(''This image was loaded as a color image, so the colormap cannot be changed. You can use an RGB Split or RGB to Grayscale module to change the format of the image prior to running the Spot Identifier module.''), else propedit(ImageHandle), end';
uicontrol('Style', 'pushbutton', ...
    'String', 'Change', 'Position', [490 6 45 20], ...
    'Callback', ChangeColormapButtonFunction, 'parent',FigureHandle, ...
    'FontSize',Font,'BackgroundColor',[.7,.7,.9]);

%%% Text1
uicontrol('Parent',FigureHandle, ...
    'BackgroundColor',get(FigureHandle,'Color'), ...
    'Position',[10 28 145 14], ...
    'HorizontalAlignment','center', ...
    'String','Gridlines:', ...
    'Style','text', ...
    'FontSize',Font,'BackgroundColor',[.7,.7,.9]);
%%% Text2
uicontrol('Parent',FigureHandle, ...
    'BackgroundColor',get(FigureHandle,'Color'), ...
    'Position',[170 28 145 14], ...
    'HorizontalAlignment','center', ...
    'String','Coordinates:', ...
    'Style','text', ...
    'FontSize',Font,'BackgroundColor',[.7,.7,.9]);
%%% Text4
uicontrol('Parent',FigureHandle, ...
    'BackgroundColor',get(FigureHandle,'Color'), ...
    'Position',[485 28 55 14], ...
    'HorizontalAlignment','center', ...
    'String','Colormap:', ...
    'Style','text', ...
    'FontSize',Font,'BackgroundColor',[.7,.7,.9]);

SizeOfImage = size(OrigImage);
TotalHeight = SizeOfImage(1);
TotalWidth = SizeOfImage(2);

if length(SizeOfImage) == 3   
    set(ImageHandle,'UserData','Color')
else
    set(ImageHandle,'UserData','Gray')
end

%%% Draws the grid on the image.  The 0.5 accounts for the fact that
%%% pixels are labeled where the middle of the pixel is a whole number,
%%% and the left hand side of each pixel is 0.5.

%%% Draws the Vertical Lines.
VertLinesX(1,:) = [GridXLocations(1,:),GridXLocations(1,end)+HorizSpacing];
VertLinesX(2,:) = [GridXLocations(1,:),GridXLocations(1,end)+HorizSpacing];
VertLinesX = VertLinesX - HorizSpacing/2;
VertLinesY(1,:) = repmat(0,1,size(GridXLocations,2)+1);
VertLinesY(2,:) = repmat(TotalHeight,1,size(GridXLocations,2)+1);
figure(FigureHandle);
axes(get(ImageHandle,'parent'));
line(VertLinesX,VertLinesY);
if strcmpi(LabelOrUseDownstream,'Use downstream') == 1
    axes(get(ObjectImageHandle,'parent'));
end
line(VertLinesX,VertLinesY);

%%% Draws the Horizontal Lines.
HorizLinesY(1,:) = [GridYLocations(:,1)',GridYLocations(end,1)+VertSpacing];
HorizLinesY(2,:) = [GridYLocations(:,1)',GridYLocations(end,1)+VertSpacing];
HorizLinesY = HorizLinesY - VertSpacing/2;
HorizLinesX(1,:) = repmat(0,1,size(GridXLocations,1)+1);
HorizLinesX(2,:) = repmat(TotalWidth,1,size(GridXLocations,1)+1);
figure(FigureHandle);
axes(get(ImageHandle,'parent'));
line(HorizLinesX,HorizLinesY);
if strcmpi(LabelOrUseDownstream,'Use downstream') == 1
    axes(get(ObjectImageHandle,'parent'));
end
line(HorizLinesX,HorizLinesY);

%%% Sets the line color.
Handles = findobj('type','line');
set(Handles, 'color',[.15 .15 .15])

%%% Sets the location of Tick marks.
set(gca, 'XTick', GridXLocations(1,:))
set(gca, 'YTick', GridYLocations(:,1))

%%% Sets the Tick Labels.
if strcmp(LeftOrRight,'R') == 1
    set(gca, 'XTickLabel',fliplr(1:NumberColumns))
else
    set(gca, 'XTickLabel',{1:NumberColumns})
end
if strcmp(TopOrBottom,'B') == 1
    set(gca, 'YTickLabel',{fliplr(1:NumberRows)})
else
    set(gca, 'YTickLabel',{1:NumberRows})
end

%%% Adds the toolbar to the figure, which is lost after some of the
%%% steps above.
set(FigureHandle,'toolbar','figure')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SAVE DATA TO HANDLES STRUCTURE %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow

% PROGRAMMING NOTE
% HANDLES STRUCTURE:
%       In CellProfiler (and Matlab in general), each independent
% function (module) has its own workspace and is not able to 'see'
% variables produced by other modules. For data or images to be shared
% from one module to the next, they must be saved to what is called
% the 'handles structure'. This is a variable, whose class is
% 'structure', and whose name is handles. The contents of the handles
% structure are printed out at the command line of Matlab using the
% Tech Diagnosis button. The only variables present in the main
% handles structure are handles to figures and gui elements.
% Everything else should be saved in one of the following
% substructures:
%
% handles.Settings:
%       Everything in handles.Settings is stored when the user uses
% the Save pipeline button, and these data are loaded into
% CellProfiler when the user uses the Load pipeline button. This
% substructure contains all necessary information to re-create a
% pipeline, including which modules were used (including variable
% revision numbers), their setting (variables), and the pixel size.
%   Fields currently in handles.Settings: PixelSize, ModuleNames,
% VariableValues, NumbersOfVariables, VariableRevisionNumbers.
%
% handles.Pipeline:
%       This substructure is deleted at the beginning of the
% analysis run (see 'Which substructures are deleted prior to an
% analysis run?' below). handles.Pipeline is for storing data which
% must be retrieved by other modules. This data can be overwritten as
% each image set is processed, or it can be generated once and then
% retrieved during every subsequent image set's processing, or it can
% be saved for each image set by saving it according to which image
% set is being analyzed, depending on how it will be used by other
% modules. Any module which produces or passes on an image needs to
% also pass along the original filename of the image, named after the
% new image name, so that if the SaveImages module attempts to save
% the resulting image, it can be named by appending text to the
% original file name.
%   Example fields in handles.Pipeline: FileListOrigBlue,
% PathnameOrigBlue, FilenameOrigBlue, OrigBlue (which contains the actual image).
%
% handles.Current:
%       This substructure contains information needed for the main
% CellProfiler window display and for the various modules to
% function. It does not contain any module-specific data (which is in
% handles.Pipeline).
%   Example fields in handles.Current: NumberOfModules,
% StartupDirectory, DefaultOutputDirectory, DefaultImageDirectory,
% FilenamesInImageDir, CellProfilerPathname, ImageToolHelp,
% DataToolHelp, FigureNumberForModule01, NumberOfImageSets,
% SetBeingAnalyzed, TimeStarted, CurrentModuleNumber.
%
% handles.Preferences:
%       Everything in handles.Preferences is stored in the file
% CellProfilerPreferences.mat when the user uses the Set Preferences
% button. These preferences are loaded upon launching CellProfiler.
% The PixelSize, DefaultImageDirectory, and DefaultOutputDirectory
% fields can be changed for the current session by the user using edit
% boxes in the main CellProfiler window, which changes their values in
% handles.Current. Therefore, handles.Current is most likely where you
% should retrieve this information if needed within a module.
%   Fields currently in handles.Preferences: PixelSize, FontSize,
% DefaultModuleDirectory, DefaultOutputDirectory,
% DefaultImageDirectory.
%
% handles.Measurements
%      Data extracted from input images are stored in the
% handles.Measurements substructure for exporting or further analysis.
% This substructure is deleted at the beginning of the analysis run
% (see 'Which substructures are deleted prior to an analysis run?'
% below). The Measurements structure is organized in two levels. At
% the first level, directly under handles.Measurements, there are
% substructures (fields) containing measurements of different objects.
% The names of the objects are specified by the user in the Identify
% modules (e.g. 'Cells', 'Nuclei', 'Colonies').  In addition to these
% object fields is a field called 'Image' which contains information
% relating to entire images, such as filenames, thresholds and
% measurements derived from an entire image. That is, the Image field
% contains any features where there is one value for the entire image.
% As an example, the first level might contain the fields
% handles.Measurements.Image, handles.Measurements.Cells and
% handles.Measurements.Nuclei.
%      In the second level, the measurements are stored in matrices
% with dimension [#objects x #features]. Each measurement module
% writes its own block; for example, the MeasureAreaShape module
% writes shape measurements of 'Cells' in
% handles.Measurements.Cells.AreaShape. An associated cell array of
% dimension [1 x #features] with suffix 'Features' contains the names
% or descriptions of the measurements. The export data tools, e.g.
% ExportData, triggers on this 'Features' suffix. Measurements or data
% that do not follow the convention described above, or that should
% not be exported via the conventional export tools, can thereby be
% stored in the handles.Measurements structure by leaving out the
% '....Features' field. This data will then be invisible to the
% existing export tools.
%      Following is an example where we have measured the area and
% perimeter of 3 cells in the first image and 4 cells in the second
% image. The first column contains the Area measurements and the
% second column contains the Perimeter measurements.  Each row
% contains measurements for a different cell:
% handles.Measurements.Cells.AreaShapeFeatures = {'Area' 'Perimeter'}
% handles.Measurements.Cells.AreaShape{1} = 	40		20
%                                               100		55
%                                              	200		87
% handles.Measurements.Cells.AreaShape{2} = 	130		100
%                                               90		45
%                                               100		67
%                                               45		22
%
% Which substructures are deleted prior to an analysis run?
%       Anything stored in handles.Measurements or handles.Pipeline
% will be deleted at the beginning of the analysis run, whereas
% anything stored in handles.Settings, handles.Preferences, and
% handles.Current will be retained from one analysis to the next. It
% is important to think about which of these data should be deleted at
% the end of an analysis run because of the way Matlab saves
% variables: For example, a user might process 12 image sets of nuclei
% which results in a set of 12 measurements ("ImageTotalNucArea")
% stored in handles.Measurements. In addition, a processed image of
% nuclei from the last image set is left in the handles structure
% ("SegmNucImg"). Now, if the user uses a different algorithm which
% happens to have the same measurement output name "ImageTotalNucArea"
% to analyze 4 image sets, the 4 measurements will overwrite the first
% 4 measurements of the previous analysis, but the remaining 8
% measurements will still be present. So, the user will end up with 12
% measurements from the 4 sets. Another potential problem is that if,
% in the second analysis run, the user runs only a module which
% depends on the output "SegmNucImg" but does not run a module that
% produces an image by that name, the module will run just fine: it
% will just repeatedly use the processed image of nuclei leftover from
% the last image set, which was left in handles.Pipeline.

%%% Saves the adjusted image to the handles structure so it can be used by
%%% subsequent modules.
handles.Pipeline.(RotatedImageName) = RotatedImage;

%%% Saves the label matrix image to the handles if requested.
if strcmpi(LabelOrUseDownstream,'Use downstream') == 1
    fieldname = ['Segmented',ObjectName];
    handles.Pipeline.(fieldname) = FinalLabelMatrix;
end

%%% Saves images to the handles structure so they can be saved to the hard
%%% drive, if the user requested.
try
    if ~strcmpi(SaveColored,'Do not save')
        if strcmp(SaveMode,'RGB')
            handles.Pipeline.(SaveColored) = FinalColorLabelMatrix;
        else
            handles.Pipeline.(SaveColored) = FinalLabelMatrix;
        end
    end
    if ~strcmpi(SaveOutlined,'Do not save')
        handles.Pipeline.(SaveOutlined) = ObjectOutlines;
    end
catch errordlg('The object outlines or colored objects were not calculated by an identify module (possibly because the window is closed) so these images were not saved to the handles structure. The Save Images module will therefore not function on these images. This is just for your information - image processing is still in progress, but the Save Images module will fail if you attempted to save these images.')
end

%%% Storing the MarkerSpotLocation XY locations is a little more complicated
%%% than storing other measurements because several different modules
%%% might write to the handles.Measurements.Image.MarkerSpotLocation
%%% structure, and we should therefore append the current
%%% measurements to an existing structure.
%%% First, if the MarkerSpotLocation fields don't exist, initialize them.
if ~isfield(handles.Measurements.Image,'MarkerSpotLocationFeatures')                        
    handles.Measurements.Image.MarkerSpotLocationFeatures = {};
    handles.Measurements.Image.MarkerSpotLocation = {};
end
%%% Search the MarkerSpotLocationFeatures to find the column for this object
%%% type.
column = find(~cellfun('isempty',strfind(handles.Measurements.Image.MarkerSpotLocationFeatures,ObjectName)));  
%%% If column is empty it means that this particular object has not been segmented before. This will
%%% typically happen for the first image set. Append the feature name in the
%%% handles.Measurements.Image.MarkerSpotLocationFeatures matrix
if isempty(column)
    handles.Measurements.Image.MarkerSpotLocationFeatures(end+1) = {['TopLeftX ' ObjectName]};
    handles.Measurements.Image.MarkerSpotLocationFeatures(end+1) = {['TopLeftY ' ObjectName]};
end
%%% Search the MarkerSpotLocationFeatures again to find the column for this
%%% object type. It should now exist under all circumstances.
column = find(~cellfun('isempty',strfind(handles.Measurements.Image.MarkerSpotLocationFeatures,ObjectName)));  
%%% There will be two fields found with the ObjectName (TopLeftX and
%%% TopLeftY). TopLeftX will always be the first one found and TopLeftY
%%% will always be one column after it.
handles.Measurements.Image.MarkerSpotLocation{handles.Current.SetBeingAnalyzed}(1,column(1)) = TopLeftX;
handles.Measurements.Image.MarkerSpotLocation{handles.Current.SetBeingAnalyzed}(1,column(2)) = TopLeftY;

%%% Saves the Rotation coordinates to the handles structure in a similar manner.
if strncmp(RotateMethod, 'N', 1) ~= 1
    if ~isfield(handles.Measurements.Image,'RotatingMarkerSpotLocationFeatures')
        handles.Measurements.Image.RotatingMarkerSpotLocationFeatures = {};
        handles.Measurements.Image.RotatingMarkerSpotLocation = {};
    end
    column = find(~cellfun('isempty',strfind(handles.Measurements.Image.RotatingMarkerSpotLocationFeatures,ObjectName)));
    if isempty(column)
        handles.Measurements.Image.RotatingMarkerSpotLocationFeatures(end+1) = {['LowerLeftX ' ObjectName]};
        handles.Measurements.Image.RotatingMarkerSpotLocationFeatures(end+1) = {['LowerRightX ' ObjectName]};
        handles.Measurements.Image.RotatingMarkerSpotLocationFeatures(end+1) = {['LowerLeftY ' ObjectName]};
        handles.Measurements.Image.RotatingMarkerSpotLocationFeatures(end+1) = {['LowerRightY ' ObjectName]};
    end
    column = find(~cellfun('isempty',strfind(handles.Measurements.Image.RotatingMarkerSpotLocationFeatures,ObjectName)));
    handles.Measurements.Image.RotatingMarkerSpotLocation{handles.Current.SetBeingAnalyzed}(1,column(1)) = LowerLeftX;
    handles.Measurements.Image.RotatingMarkerSpotLocation{handles.Current.SetBeingAnalyzed}(1,column(2)) = LowerRightX;
    handles.Measurements.Image.RotatingMarkerSpotLocation{handles.Current.SetBeingAnalyzed}(1,column(3)) = LowerLeftY;
    handles.Measurements.Image.RotatingMarkerSpotLocation{handles.Current.SetBeingAnalyzed}(1,column(4)) = LowerRightY;
end

%%% Saves the ObjectCount, i.e. the number of segmented objects.
%%% See comments for the Threshold saving above
if ~isfield(handles.Measurements.Image,'ObjectCountFeatures')                        
    handles.Measurements.Image.ObjectCountFeatures = {};
    handles.Measurements.Image.ObjectCount = {};
end
column = find(~cellfun('isempty',strfind(handles.Measurements.Image.ObjectCountFeatures,ObjectName)));  
if isempty(column)
    handles.Measurements.Image.ObjectCountFeatures(end+1) = {['ObjectCount ' ObjectName]};
    column = length(handles.Measurements.Image.ObjectCountFeatures);
end
handles.Measurements.Image.ObjectCount{handles.Current.SetBeingAnalyzed}(1,column) = max(FinalLabelMatrix(:));

%%% Saves the location of each segmented object
handles.Measurements.(ObjectName).LocationFeatures = {'CenterX','CenterY'};
tmp = regionprops(FinalLabelMatrix,'Centroid');
Centroid = cat(1,tmp.Centroid);
handles.Measurements.(ObjectName).Location(handles.Current.SetBeingAnalyzed) = {Centroid};