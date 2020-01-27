function layer = splitLayer(varargin)
%   This layer takes a 2 channel input and splits it into 2 different branches of
%   the network
%
%   layer = depthConcatenationLayer(numInputs,'PARAM1', VAL1) specifies
%   optional parameter name/value pairs for creating the layer:
%
%       'Name'                    - A name for the layer. The default is
%                                   ''.
%
%   A depth concatenation layer has the following inputs:
%       'in1','in2',...,'inN'   - Inputs to be concatenated. Note that all
%                                 of the inputs must have the same 
%                                 dimensions. See the example below for 
%                                 usage.
%
%   Example:
%       Create a depth concatenation layer with two inputs that
%       concatenates the output from two ReLU layers.
%
%       depth_1 = depthConcatenationLayer(2,'Name','depth_1');
%       relu_1 = reluLayer('Name','relu_1');
%       relu_2 = reluLayer('Name','relu_2');
%
%       lgraph = layerGraph();
%       lgraph = addLayers(lgraph, relu_1);
%       lgraph = addLayers(lgraph, relu_2);
%       lgraph = addLayers(lgraph, depth_1);
%
%       lgraph = connectLayers(lgraph, 'relu_1', 'depth_1/in1');
%       lgraph = connectLayers(lgraph, 'relu_2', 'depth_1/in2');
%
%       plot(lgraph);
%
%   See also nnet.cnn.layer.DepthConcatenationLayer, convolution2dLayer,
%   reluLayer.

%   Copyright 2017 The MathWorks, Inc.


% Parse the input arguments.
inputArguments = iParseInputArguments(varargin{:});

% Create an internal representation of a depth concatenation layer.
splittingAxis = 3;
internalLayer = nnet.internal.cnn.layer.Concatenation(inputArguments.Name, concatenationAxis, inputArguments.NumInputs);

% Pass the internal layer to a function to construct a user visible depth
% concatenation layer.
layer = nnet.cnn.layer.DepthConcatenationLayer(internalLayer);

end

function inputArguments = iParseInputArguments(varargin)
varargin = nnet.internal.cnn.layer.util.gatherParametersToCPU(varargin);
p = inputParser;
addRequired(p, 'NumInputs', @iAssertValidNumInputs);
addParameter(p, 'Name', '', @nnet.internal.cnn.layer.paramvalidation.validateLayerName);
p.parse(varargin{:});
inputArguments = struct;
inputArguments.Name = convertStringsToChars(p.Results.Name); % make sure strings get converted to char vectors
inputArguments.NumInputs = p.Results.NumInputs;
end

function iAssertValidNumInputs(value)
validateattributes(value, {'numeric'}, ...
    {'positive', 'real', 'integer', 'nonempty', 'scalar','>',1});
end



