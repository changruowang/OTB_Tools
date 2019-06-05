function RGB = insertShape(I, shape, position, varargin)
%insertShape Insert shapes in image or video stream.
%  This function draws multiple shapes on images by overwriting pixel
%  values. You can use it with either a grayscale or truecolor image input.
%
%  RGB = insertShape(I, SHAPE, POSITION) returns a truecolor image with
%  SHAPE drawn in it. The input image, I, can be either a truecolor or
%  grayscale image. The supported values for SHAPE and POSITION are
%  described below:
%
%  ------------------------------------------------------------------------
%  SHAPE             | POSITION
%  ------------------|-----------------------------------------------------
%  'Rectangle'       | M-by-4 matrix where each row specifies a rectangle
%  'FilledRectangle' | as [x y width height]. [x y] is the upper-left 
%                    | corner of the rectangle.
%  ------------------|-----------------------------------------------------
%  'Line'            | If all sets of lines or polygons have same number of 
%  'Polygon'         | vertices, they can be specified as an M-by-2L matrix 
%  'FilledPolygon'   | where each row specifies a set of connected lines or 
%                    | a polygon as a series of consecutive point locations, 
%                    | [x1,y1,x2,y2...xL,yL].
%                    | These shapes can also be specified as a cell array  
%                    | of M vectors, for example:
%                    |  {[x11,y11,x12,y12,...,x1p,y1p], 
%                    |   [x21,y21,x22,y22,......,x2q,y2q], 
%                    |   ... ... ...
%                    |   [xM1,yM1,xM2,yM2,.........,xMr,yMr]}
%                    |  Here p,q,r specify the number of vertices.
%  ------------------|-----------------------------------------------------
%  'Circle'          | M-by-3 matrix where each row specifies a circle as
%  'FilledCircle'    | [x y radius], where [x y] are the coordinates of the
%                    | center.
%  ------------------------------------------------------------------------
%
%  RGB = insertShape(...,'Name',Value,...) specifies additional name-value
%  pair arguments described below:
%
%  'LineWidth'       Line width for the border of a shape, specified as a
%                    positive scalar integer, in pixels. This property
%                    applies when you select the 'Rectangle', 'Line',
%                    'Polygon', or 'Circle' shapes.
%                         
%                    Default: 1
%
%  'Color'           Defines shape's color. It can be specified as:
%                    - a 'color' string or an [R, G, B] vector defining a
%                      color for all shapes, or
%                    - a cell array of M strings or an M-by-3 matrix of 
%                      RGB values for each shape
%
%                    RGB values must be in the range of the image data type.
%
%                    Supported color strings are: 'blue', 'green', 'red', 
%                    'cyan', 'magenta', 'yellow', 'black', 'white'
%
%                    Default: 'yellow'
% 
%  'Opacity'         A scalar defining the opacity of the filled shape. It
%                    is in the range 0 to 1. It is applicable when shape is
%                    'FilledRectangle', 'FilledPolygon', or 'FilledCircle'
%                         
%                    Default: 0.6
%
%  'SmoothEdges'     A logical scalar with value true or false. A true
%                    value enables anti-aliasing filter for smoothing edge
%                    of the shapes. This applies to non-rectangular shapes.
%                    Enabling anti-aliasing requires additional time to
%                    draw the shapes.
%
%                    Default: true
%
%  Class Support
%  -------------
%  The class of input I can be uint8, uint16, int16, double, single. Output
%  RGB matches the class of I.
%
%  Examples: insert shape
%  ----------------------
%  I = imread('peppers.png');
%
%  % draw circle
%  RGB = insertShape(I, 'circle', [150 280 35], 'LineWidth', 5); 
%
%  % draw filled triangle and filled hexagon
%  pos_triangle = [183 297 302 250 316 297];
%  pos_hexagon = [340 163 305 186 303 257 334 294 362 255 361 191];
%  RGB = insertShape(RGB, 'FilledPolygon', {pos_triangle, pos_hexagon}, ...
%                   'Color', {'white', 'green'}, 'Opacity', 0.7); 
%  imshow(RGB);
%
%  See also insertObjectAnnotation, insertMarker, insertText

%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>

%% == Parse inputs and validate ==
checkNumArgin(I, shape, position, varargin{:});
 
[tmpRGB,shapeOut,fillShape,positionOut, ...
    lineWidth,color,opacity,smoothEdges,isEmpty]= ...
    validateAndParseInputs(I, shape, position, varargin{:});
fillShape= coder.internal.const(fillShape);

% handle empty I or empty position
if isEmpty 
    RGB = tmpRGB;
    return;
end

%% == Setup System Objects ==
dtClass = coder.internal.const(class(I));
h_ShapeInserter = getSystemObjects(shapeOut, fillShape, ...
                            lineWidth, opacity, smoothEdges, dtClass, ...
                            tmpRGB, positionOut,color);

%% == Output ==
if (fillShape)
    tuneOpacity(h_ShapeInserter, opacity);
end
if (~fillShape)
    tuneLineWidth(h_ShapeInserter, lineWidth);
end
RGB = h_ShapeInserter.step(tmpRGB, positionOut, color);

%==========================================================================
function checkNumArgin(varargin)

if (isSimMode())
    narginchk(3,9);
else
   eml_lib_assert(nargin >= 3 && nargin <= 9, ...
       'vision:insertShape:NotEnoughArgs', 'Not enough input arguments.');
end

%==========================================================================
function [RGB,shapeOut,fillShape,positionOut,lineWidth,colorOut,opacity, ...
   smoothEdges,isEmpty] = validateAndParseInputs(I,shape,position,varargin)

%--input image--
checkImage(I);
RGB = convert2RGB(I);
inpClass = coder.internal.const(class(I));

%--shape--
if ~isSimMode()
    eml_invariant(eml_is_const(shape),...
            eml_message('vision:insertShape:shapeNonConst'));
end
shape1 = validatestring(shape,{'Rectangle','FilledRectangle', ...
                         'Line', ...
                         'Polygon','FilledPolygon', ...
                         'Circle','FilledCircle'},'insertShape','SHAPE',2);
shape2 = coder.internal.const(shape1);                     
 
%--position--
checkPosition(position);

%--isEmpty--
isEmpty = anyEmpty(I, position);

%--other optional parameters--
if isEmpty    
    shapeOut    = shape2;
    fillShape   = coder.internal.const(true); % not used
    positionOut = int32(position);
    lineWidth   = 1;
    colorOut    = ones(1,3, inpClass); % not used
    opacity     = 0.6;% not used
    smoothEdges = true; % not used
else
    % lineWidth ignored for ~fillShape
    [lineWidth, color, opacity, smoothEdges] = ...
               validateAndParseOptInputs(inpClass,varargin{:});     
    crossCheckInputs(shape2, position, color);
    
    [shapeOut, fillShape] = remapShape(shape2);
    positionOut = convertPositionToMatrix(position);
    
    numPosition = size(positionOut, 1);
    colorOut = getColorMatrix(inpClass, numPosition, color);
end

%==========================================================================
function isAnyEmpty = anyEmpty(I, position)
% for fixS, check max size
% for varS, check run-time size

if isSimMode()
    isAnyEmpty = isempty(I) || isempty(position);
else
    isAnyEmpty = false;% no suitable function
end

%==========================================================================
function checkPosition(position)
% Validate label

if isnumeric(position)
   validateattributes(position, {'numeric'}, ...
       {'real','nonsparse', '2d', 'finite'}, ...
       'insertShape', 'POSITION');  
else
   if ~isSimMode()
       % codegen does not support cell array
       errIf0(~isnumeric(position), 'vision:insertShape:posNotNumeric');
   else    
        validateattributes(position,{'cell'}, {'nonempty', 'vector'}, ...
                                               'insertShape', 'POSITION');
        numCell = length(position);
        for ii=1:numCell
            % each cell must be numeric and vector
            errCond = ~isnumeric(position{ii}) || ~isvector(position{ii});
            errIf0(errCond, 'vision:insertShape:posCellNonNumVec');

            % each cell (a vector) must be non-empty        
            errCond = isempty(position{ii});
            errIf0(errCond, 'vision:insertShape:positionCellEmpty');        
        end
   end
end

%==========================================================================
function [lineWidth,color,opacity,smoothEdges] = ...
                     validateAndParseOptInputs(inpClass,varargin)
% Validate and parse optional inputs

defaults = getDefaultParameters(inpClass);
if nargin>1 % varargin{:} is non-empty
    if (isSimMode())
        [lineWidth,color,opacity,smoothEdges] = ...
                      validateAndParseOptInputs_sim(defaults, varargin{:});

    else
        [lineWidth,color,opacity,smoothEdges] = ...
                  validateAndParseOptInputs_codegen(defaults, varargin{:});
    end
else % varargin{:} is empty (no name-value pair)
    lineWidth   = defaults.LineWidth;
    color       = defaults.Color;
    opacity     = defaults.Opacity;
    smoothEdges = defaults.smoothEdges;
end

%==========================================================================
function flag = isSimMode()

flag = isempty(coder.target);

%==========================================================================
function [lineWidth, color,opacity,smoothEdges] = ...
                           validateAndParseOptInputs_sim(defaults,varargin)
    
% Setup parser
parser = inputParser;
parser.CaseSensitive = false;
parser.FunctionName  = 'insertShape';

parser.addParamValue('LineWidth',defaults.LineWidth,@checkLineWidth);
parser.addParamValue('Color',defaults.Color);
parser.addParamValue('Opacity',defaults.Opacity,@checkOpacity);
parser.addParamValue('SmoothEdges',defaults.smoothEdges,@checkSmoothEdges);

%Parse input
parser.parse(varargin{:});

lineWidth   = double(parser.Results.LineWidth);
color       = checkColor(parser.Results.Color, 'Color');
opacity     = double(parser.Results.Opacity);
smoothEdges = logical(parser.Results.SmoothEdges);
  
%==========================================================================
function [lineWidth, color,opacity,smoothEdges] = ...
                       validateAndParseOptInputs_codegen(defaults,varargin)

defaultsNoVal = getDefaultParametersNoVal();
properties    = getEmlParserProperties();

optarg = eml_parse_parameter_inputs(defaultsNoVal, properties, varargin{:});

lineWidth1  = tolower(eml_get_parameter_value(optarg.LineWidth, ...
            defaults.LineWidth, varargin{:}));
checkLineWidth(lineWidth1);
lineWidth = double(lineWidth1);

color  = tolower(eml_get_parameter_value(optarg.Color, ...
            defaults.Color, varargin{:}));
color  = checkColor(color, 'Color');
% opacity and smoothEdges (i.e., useAntiAliasing) are input mask params
% (not from port); that's why convert these to eml_const at parsing stage

opacity1    = tolower(eml_get_parameter_value( ...
               optarg.Opacity, defaults.Opacity, varargin{:}));
checkOpacity(opacity1);
opacity = double(opacity1);

smoothEdges = coder.internal.const(tolower(eml_get_parameter_value( ...
               optarg.smoothEdges, defaults.smoothEdges, varargin{:}))); 
checkSmoothEdges(smoothEdges);         
        
%==========================================================================
function checkImage(I)
% Validate input image

validateattributes(I,{'uint8', 'uint16', 'int16', 'double', 'single'}, ...
    {'real','nonsparse'}, 'insertShape', 'I', 1)

% input image must be 2d or 3d (with 3 planes)
errCond = (ndims(I) > 3) || ((size(I,3) ~= 1) && (size(I,3) ~= 3));
errIf0(errCond, 'vision:dims:imageNot2DorRGB');

%==========================================================================
function crossCheckInputs(shape, position, color)
% Cross validate inputs

crossCheckShapePosition(shape, position);
crossCheckPositionColor(position, color);

%==========================================================================
function crossCheckPositionColor(position, color)
% Cross validate inputs
% here position must be non-empty

if isnumeric(position)
    numPositions = size(position, 1); 
    msgID = 'vision:insertShape:invalidNumPosMatrixNumColor';
else
    numPositions = length(position); 
    msgID = 'vision:insertShape:invalidNumPosCellNumColor';
end
numColors = getNumColors(color);
errCond = (numColors ~= 1) && (numPositions ~= numColors);
errIf0(errCond, msgID);

%==========================================================================
function crossCheckShapePosition(shape, position)
% Cross validate inputs
% here position must be non-empty
     
switch shape
   case {'Rectangle', 'FilledRectangle'} 
     errCond = iscell(position);
     errIf1(errCond, 'vision:insertShape:positionCell', shape);

     errCond = size(position, 2) ~= 4; % rectangle: [x y width height]
     errIf1(errCond, 'vision:insertShape:posColsNot4ForRect', shape);
     
   case {'Circle', 'FilledCircle'}
     errCond = iscell(position);
     errIf1(errCond, 'vision:insertShape:positionCell', shape);

     errCond = size(position, 2) ~= 3; % circle: [x y radius]
     errIf1(errCond, 'vision:insertShape:posColsNot4ForCir', shape);
 
   otherwise % Line, Polygon, FilledPolygon
     if isnumeric(position)
       % row vector must have even numbered elements
       errCond = mod(size(position, 2), 2) ~= 0;
       errIf1(errCond, 'vision:insertShape:posPolyNumPtsNotEven',shape);
 
       % For line: minimum 2 points (4 values: x1 y1 x2 y2)
       % For polygon: minimum 3 points (6 values: x1 y1 x2 y2 x3 y3)
       numMinPts = getMinNumPoints(shape);
       errCond = size(position, 2) < numMinPts;
       errIf2(errCond,'vision:insertShape:posPolyNumPtsLT2', ...
              numMinPts,shape);
           
     else % must be cell of numeric vectors
       errCond = ~isvector(position);
       errIf0(errCond, 'vision:insertShape:posPolyCellNonNumVec');

       numCell = length(position);
       for ii=1:numCell
          cell_ii = position{ii};                
          % each cell must be a numeric vector
          errCond = (~isnumeric(cell_ii)) && (~isvector(cell_ii));
          errIf0(errCond, 'vision:insertShape:posPolyCellNonNumVec');
                          
          % each cell must have even numbered elements
          errCond = mod(length(cell_ii), 2) ~= 0;
          errIf0(errCond, 'vision:insertShape:posPolyCellNumPtsOdd');
          
          numMinPts = getMinNumPoints(shape);
          errCond = length(cell_ii) < numMinPts;
          errIf2(errCond, 'vision:insertShape:posPolyCellNumPtsLT2', ...
                 numMinPts, shape);
              
       end            
     end
end

%==========================================================================
function numMinPts = getMinNumPoints(shape)

if strcmpi(shape, 'Line')
    numMinPts = 4;
else
    numMinPts = 6;
end
%==========================================================================
function colorOut = getColorMatrix(inpClass, numShapes, color)

colorRGB = colorRGBValue(color, inpClass);
if (size(colorRGB, 1)==1)
    colorOut = repmat(colorRGB, [numShapes 1]);
else
    colorOut = colorRGB;
end

%==========================================================================
function numColors = getNumColors(color)

% Get number of colors
numColors = 1;
if isnumeric(color)
    numColors = size(color,1);
elseif iscell(color) % if color='red', it is converted to cell earlier
    numColors = length(color);
end

%==========================================================================
function defaults = getDefaultParameters(inpClass)

% Get default values for optional parameters

% default color 'yellow'
switch inpClass
   case {'double', 'single'}
       yellow = [1 1 0];  
   case 'uint8'
       yellow = [255 255 0];  
   case 'uint16'
       yellow = [65535  65535  0];          
   case 'int16'
       yellow = [32767  32767 -32768];
end
       
defaults = struct(...
    'LineWidth', 1, ... 
    'Color', yellow, ... 
    'Opacity', 0.6,...
    'smoothEdges', true);

%==========================================================================
function defaultsNoVal = getDefaultParametersNoVal()

defaultsNoVal = struct(...
    'LineWidth', uint32(0), ... 
    'Color', uint32(0), ... 
    'Opacity', uint32(0),...
    'smoothEdges', uint32(0));

%==========================================================================
function properties = getEmlParserProperties()

properties = struct( ...
    'CaseSensitivity', false, ...
    'StructExpand',    true, ...
    'PartialMatching', false);

%==========================================================================
function str = tolower(str)
% convert a string to lower case 

if isSimMode()
    str = lower(str);
else
    str = eml_tolower(str);
end

%==========================================================================
function tf = checkLineWidth(lineWidth)
% Validate 'LineWidth'
validateattributes(lineWidth, {'numeric'}, ...
   {'nonsparse', 'integer', 'scalar', 'real', 'positive'}, ...
   'insertShape', 'LineWidth');

tf = true;

%==========================================================================
function colorOut = checkColor(color, paramName) 
% Validate 'Color'

if isnumeric(color)
   % must have 6 columns
   validateattributes(color, ...
       {'uint8','uint16','int16','double','single'},...
       {'real','nonsparse','nonnan', 'finite', '2d', 'size', [NaN 3]}, ...
       'insertShape', paramName);
   colorOut = color;
else
   if ~isSimMode()
       % codegen does not support cell array
       errIf0(~isnumeric(color), 'vision:insertShape:colorNotNumeric');
       colorOut = color;
   else    
       if ischar(color)
           colorCell = {color};
       else
           validateattributes(color, {'cell'}, {}, 'insertShape', 'Color');
           colorCell = color;
       end
       supportedColorStr = {'blue','green','red','cyan','magenta', ...
                            'yellow','black','white'};
       numCells = length(colorCell);
       colorOut = cell(1, numCells);
       for ii=1:numCells
           colorOut{ii} =  validatestring(colorCell{ii}, ...
                              supportedColorStr, 'insertShape', paramName);
       end
   end
end

%==========================================================================
function tf = checkOpacity(opacity)
% Validate 'TextBoxOpacity'

validateattributes(opacity, {'numeric'}, {'nonempty', 'nonnan', ...
    'finite', 'nonsparse', 'real', 'scalar', '>=', 0, '<=', 1}, ...
    'insertShape', 'TextBoxOpacity');
tf = true;

%==========================================================================
function tf = checkSmoothEdges(smoothEdges)
% Validate 'SmoothEdges'

validateattributes(smoothEdges, {'logical'}, {'scalar'}, 'insertShape', ...
                                                        'SmoothEdges');
tf = true;

%==========================================================================
function sizeOfCache = getCacheSizeForShapeInserter()
% Shape inserter object needs to be created for the following
% parameters:
% input data type: double,single,uint8,uint16,int16
% shape: Rectangle, Line, Polygon, Circle
% Fill: yes, no
% Anti-aliasing: yes, no

numInDTypes       = 5;
numShapes         = 4;
numFillOption     = 2;
numAliasingOption = 2;
sizeOfCache = [numInDTypes numShapes numFillOption numAliasingOption];  
  
%========================================================================== 
function tuneOpacity(h_ShapeInserter, opacity)

% tunability not fully supported in codegen
if (opacity ~= h_ShapeInserter.Opacity)
    h_ShapeInserter.Opacity = opacity;
end

%========================================================================== 
function tuneLineWidth(h_ShapeInserter, lineWidth)

% tunability not fully supported in codegen
if (lineWidth ~= h_ShapeInserter.LineWidth)
    h_ShapeInserter.LineWidth = double(lineWidth);
end

%========================================================================== 
function rgb = convert2RGB(I)

if ismatrix(I)
    rgb = cat(3, I , I, I);
else
    rgb = I;
end

%==========================================================================
function outColor = colorRGBValue(inColor, inpClass)

if isnumeric(inColor)
    outColor = cast(inColor, inpClass);
else    
    if iscell(inColor)
        colorCell = inColor;
    else
        colorCell = {inColor};
    end

   numColors = length(colorCell);
   outColor = zeros(numColors, 3, inpClass);

   for ii=1:numColors
    supportedColorStr = {'blue','green','red','cyan','magenta','yellow',...
                         'black','white'};  
    % http://www.mathworks.com/help/techdoc/ref/colorspec.html
    colorValuesFloat = [0 0 1;0 1 0;1 0 0;0 1 1;1 0 1;1 1 0;0 0 0;1 1 1];                    
    idx = strcmp(colorCell{ii}, supportedColorStr);
    switch inpClass
       case {'double', 'single'}
           outColor(ii, :) = colorValuesFloat(idx, :);
       case {'uint8', 'uint16'} 
           colorValuesUint = colorValuesFloat*double(intmax(inpClass));
           outColor(ii, :) = colorValuesUint(idx, :);
       case 'int16'
           colorValuesInt16 = im2int16(colorValuesFloat);
           outColor(ii, :) = colorValuesInt16(idx, :);           
    end
   end
end

%==========================================================================
function OutPosition = convertPositionToMatrix(inPosition)

if isnumeric(inPosition)
    OutPosition = int32(inPosition);
else 
    numCell       = length(inPosition);
    maxCellLength = max(cellfun(@length,inPosition));
    OutPosition   = zeros(numCell, maxCellLength, 'int32');
    for ii=1:numCell
        OutPosition(ii,:) = copyCellAndRepeatLastPoint(...
            int32(inPosition{ii}), maxCellLength);
    end
end

%==========================================================================
function out = copyCellAndRepeatLastPoint(in, outLen)

inLen = length(in);
out   = zeros(1, outLen, class(in));
out(1:inLen) = in;
for ii = (inLen+1): 2 : (outLen-1)
    out(ii) = in(end-1);
    out(ii+1) = in(end);
end

%==========================================================================
% Setup System Objects (simulation + code generation)
%==========================================================================
function h_ShapeInserter = getSystemObjects(shape, fillShape, ...
                           lineWidth, opacity, smoothEdges, inpClass, ...
                           rgb, position, color)

fillShape= coder.internal.const(fillShape);
if isSimMode()
    h_ShapeInserter = getSystemObjects_sim(shape, fillShape,  lineWidth, ...
                              opacity, smoothEdges, inpClass);
else
    h_ShapeInserter = getSystemObjects_cg(shape, fillShape, ...
                                          smoothEdges, inpClass, ...
                                           rgb, position, color);  
end
%==========================================================================
% Setup System Objects (simulation)
%==========================================================================
function h_ShapeInserter = getSystemObjects_sim(shape, fillShape, ...
                                 lineWidth, opacity, smoothEdges, inpClass)

persistent cache % cache for storing System Objects

if isempty(cache)
    cache.shapeInserterObjects  = cell(getCacheSizeForShapeInserter());
end

inDTypeIdx = getDTypeIdx(inpClass);
shapeIdx   = getShapeIdx(shape);
fillIdx    = double(fillShape) + 1;
smoothIdx  = double(smoothEdges) + 1;

if isempty(cache.shapeInserterObjects{inDTypeIdx,shapeIdx,fillIdx,smoothIdx})
  h_ShapeInserter = createShapeInserter_sim(shape, fillShape, ...
                          lineWidth, opacity, smoothEdges);
  % cache the ShapeInserter object in cell array
  cache.shapeInserterObjects{inDTypeIdx,shapeIdx,fillIdx,smoothIdx}= ...
        h_ShapeInserter;
else
  % point to the existing object
  h_ShapeInserter = ...
      cache.shapeInserterObjects{inDTypeIdx,shapeIdx,fillIdx,smoothIdx};    
end

%==========================================================================
% Setup System Objects (code generation)
%==========================================================================
function h_ShapeInserter = getSystemObjects_cg(shape, fillShape, ...
                                        smoothEdges, inpClass, ...
                                        rgb, position, color)

inDTypeIdx  = coder.internal.const(getDTypeIdx(inpClass));
shapeIdx    = coder.internal.const(getShapeIdx(shape));
fillShape   = coder.internal.const(fillShape);
smoothEdges = coder.internal.const(smoothEdges);

h_ShapeInserter = vision.internal.textngraphics.createShapeInserter_cg...
    (inDTypeIdx, shapeIdx, fillShape, smoothEdges, rgb, position, color);

%==========================================================================
function h_ShapeInserter = createShapeInserter_sim(shape, fillShape, ...
                                 lineWidth, opacity, smoothEdges)
                                   
if (fillShape)
    colorSourcePropName = 'FillColorSource';
else
    colorSourcePropName = 'BorderColorSource';
end

[IDX_RECTANGLE, IDX_LINE] = deal(1, 3);
shapeIdx   = getShapeIdx(shape);

if (shapeIdx == IDX_RECTANGLE)
  % Rectangles have no antialiasing property
   h_ShapeInserter  = vision.ShapeInserter('Shape', 'Rectangles', ...
       'Fill', fillShape, colorSourcePropName,'Input port', ...
       'useFltptMath4IntImage', 1);
elseif (shapeIdx == IDX_LINE)
  % Lines have no fill property
  h_ShapeInserter  = vision.ShapeInserter('Shape', 'Lines', ...
      'BorderColorSource','Input port','Antialiasing',smoothEdges, ...
      'useFltptMath4IntImage', 1); 
else % Circle or polygon
  % use both antialiasing and fill property       
  h_ShapeInserter  = vision.ShapeInserter('Shape', shape, ...
      'Fill', fillShape, colorSourcePropName,'Input port', ...
      'Antialiasing', smoothEdges, 'useFltptMath4IntImage', 1);       
end
if (fillShape)
  h_ShapeInserter.Opacity = double(opacity);
end
if (~fillShape)
  h_ShapeInserter.LineWidth = double(lineWidth);
end

%==========================================================================
function dtIdx = getDTypeIdx(dtClass)

switch dtClass
    case 'double',
        dtIdx = 1;
    case 'single',
        dtIdx = 2;
    case 'uint8',
        dtIdx = 3;
    case 'uint16',
        dtIdx = 4;
    case 'int16',
        dtIdx = 5;
end

%==========================================================================
function shapeIdx = getShapeIdx(shape)

shapeIdx = coder.internal.const(0);

switch lower(shape(1))
    case 'r' %'rectangles'
        shapeIdx = 1;
    case 'c' %'circles'
        shapeIdx = 2;
    case 'l' %'lines'
        shapeIdx = 3;        
    case 'p' %'polygons'
        shapeIdx = 4;         
end

%==========================================================================
function [shapeOut, fillShape] = remapShape(shapeIn)

% output shape string is for ShapeInserter system object
switch shapeIn
    case 'Rectangle'
        shapeOut = 'Rectangles';
        fillShape = false;
    case 'FilledRectangle'
        shapeOut = 'Rectangles';
        fillShape = true;
    case 'Line'
        shapeOut = 'Lines';
        fillShape = false;
    case 'Polygon'
        shapeOut = 'Polygons';
        fillShape = false;
    case 'FilledPolygon'
        shapeOut = 'Polygons';
        fillShape = true;
    case 'Circle'
        shapeOut = 'Circles';    
        fillShape = false;
    case 'FilledCircle'
        shapeOut = 'Circles';
        fillShape = true;
end

%==========================================================================
function errIf0(condition, msgID)

coder.internal.errorIf(condition, msgID);

%==========================================================================
function errIf1(condition, msgID, strArg)

coder.internal.errorIf(condition, msgID, strArg);

%==========================================================================
function errIf2(condition, msgID, strArg1, strArg2)

coder.internal.errorIf(condition, msgID, strArg1, strArg2);
