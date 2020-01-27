%Creates and trains a Y-NET. Main input-output is a SE image. 
%Version for training on residuals
%Date: 28 Jun 2019
%Author: Virginia Fernandez 
function [trained_ynet_SE,info] = train_ynet_SE_res(dataset,perc,ntest)

%PART 0: GLOBAL TUNING PARAMETERS

img_size = [120,88,3]; %2 channels: 1st, SE image, 2nd STEAM image
lgraph = layerGraph;

%trained_networks must be contained in trained_nets! The reason is that the
%output layer that was used with them is necessary to correctly load the
%network into the workspace 

input_weights_SE = 'UNETSE_RETGA_E30_MB15_LR01_DF98-1_SD_MO98_SSIM9MAE_nores'; %If not blank, path to the U-network that must be loaded to copy its weights
input_weights_STEAM = 'UNETSTEAM_RETGA_E30_MB15_LR01_DF98-1_SD_MO98_SSIM9MAE1_nores'; %If not blank, path to the U-network that must be loaded to copy its weights

%% 

%PART 1: Network generation

%-------------------------INPUT LAYER----------------------------
inp1 = imageInputLayer(img_size,'Name','inp1');
lgraph = addLayers(lgraph,inp1);
%------------------------SPLITTER PIPELINE-----------------------
%Extracted from: https://www.mathworks.com/matlabcentral/answers/369328-how-to-use-multiple-input-layers-in-dag-net-as-shown-in-the-figure
ch_1_splitter = convolution2dLayer(1,1,'Name','split1','WeightLearnRateFactor',0,'WeightL2Factor',0,'BiasLearnRateFactor',0,'WeightL2Factor',0,'BiasL2Factor',0);
ch_2_splitter = convolution2dLayer(1,1,'Name','split2','WeightLearnRateFactor',0,'WeightL2Factor',0,'BiasLearnRateFactor',0,'WeightL2Factor',0,'BiasL2Factor',0);
ch_1_splitter.Weights = zeros(1,1,3,1); ch_2_splitter.Weights = zeros(1,1,3,1);
ch_1_splitter.Weights(1,1,1,1) = 1; ch_1_splitter.Bias = zeros(1,1,1,1);
ch_2_splitter.Weights(1,1,2,1) = 1; ch_2_splitter.Bias = zeros(1,1,1,1);
lgraph = addLayers(lgraph, ch_1_splitter);
lgraph = addLayers(lgraph, ch_2_splitter);
lgraph = connectLayers(lgraph,'inp1','split1');
lgraph = connectLayers(lgraph,'inp1','split2');

%-----------------------DOWNSAMPLING PIPELINE---------------------

n_elements_kernel = 9; %Number of elements in a filter 
ds_SE = createDownSamplingBranch(n_elements_kernel,'SE_');
ds_STEAM = createDownSamplingBranch(n_elements_kernel,'STEAM_');

%Update weights from pre-trained networks:
if ~isempty(input_weights_SE)
 ds_SE = updateNetworkWeights(ds_SE, fullfile('trained_nets',input_weights_SE),'conv1','pool4');
end 
if ~isempty(input_weights_STEAM)
 ds_STEAM = updateNetworkWeights(ds_STEAM, fullfile('trained_nets',input_weights_STEAM),'conv1','pool4');
end

lgraph = addLayers(lgraph, ds_SE);
lgraph = addLayers(lgraph, ds_STEAM);
lgraph = connectLayers(lgraph, 'split1','SE_conv1');
lgraph = connectLayers(lgraph, 'split2','STEAM_conv1');

%-------------------CONCATENATION BETWEEN BRANCH------------------

%Concatenation between Inputs
conca_SEQ = concatenationLayer(3,2,'Name','conca_SEQ'); %The number of feature channels is doubled here

%-----------------------Upsampling part------------------------
%Upsampling Level 1
conv9 = convolution2dLayer(3,1024,'Padding',[1 1],'Name','conv9', 'BiasL2Factor',0);
conv9.Weights = randn([conv9.FilterSize,1024,conv9.NumFilters])*sqrt(2/(n_elements_kernel*conv9.NumFilters));    
conv9.Bias = randn([1,1,conv9.NumFilters])*sqrt(2/conv9.NumFilters);
batn9 = batchNormalizationLayer('Name','batn9');
relu9 = reluLayer('Name','relu9');
conv10 = convolution2dLayer(3,1024,'Padding',[1 1],'Name','conv10', 'BiasL2Factor',0);
conv10.Weights = randn([conv10.FilterSize,1024,conv10.NumFilters])*sqrt(2/(n_elements_kernel*conv10.NumFilters));    
conv10.Bias = randn([1,1,conv10.NumFilters])*sqrt(2/conv10.NumFilters);
batn10 = batchNormalizationLayer('Name','batn10');
relu10 = reluLayer('Name','relu10');
dro1 = dropoutLayer(0.5,'Name', 'dro1');
upsa1 = transposedConv2dLayer(2,512,'Stride',2,'Name','upsa1');

%Upsampling Level 2
conca1 = concatenationLayer(3,2,'Name','conca1'); %in1 will be relu8 and in2 upsa1
conv11 = convolution2dLayer(3,512,'Padding',[1 1],'Name','conv11', 'BiasL2Factor',0);
conv11.Weights = randn([conv11.FilterSize,1024,conv11.NumFilters])*sqrt(2/(n_elements_kernel*conv11.NumFilters));    
conv11.Bias = randn([1,1,conv11.NumFilters])*sqrt(2/conv11.NumFilters);
batn11 = batchNormalizationLayer('Name','batn11');
relu11 = reluLayer('Name','relu11');
conv12 = convolution2dLayer(3,512,'Padding',[0 0],'Name','conv12', 'BiasL2Factor',0);
conv12.Weights = randn([conv12.FilterSize,512,conv12.NumFilters])*sqrt(2/(n_elements_kernel*conv12.NumFilters));    
conv12.Bias = randn([1,1,conv12.NumFilters])*sqrt(2/conv12.NumFilters);
batn12 = batchNormalizationLayer('Name','batn12');
relu12 = reluLayer('Name','relu12');
upsa2 = transposedConv2dLayer(2,256,'Stride',2,'Name','upsa2');


%Upsampling Level 3
conca2 = concatenationLayer(3,2,'Name','conca2'); %in1 will be relu6 and in2 upsa2
conv13 = convolution2dLayer(3,256,'Padding',[1 1],'Name','conv13', 'BiasL2Factor',0);
conv13.Weights = randn([conv13.FilterSize,512,conv13.NumFilters])*sqrt(2/(n_elements_kernel*conv13.NumFilters));    
conv13.Bias = randn([1,1,conv13.NumFilters])*sqrt(2/conv13.NumFilters);
batn13 = batchNormalizationLayer('Name','batn13');
relu13 = reluLayer('Name','relu13');
conv14 = convolution2dLayer(3,256,'Padding',[0 0],'Name','conv14', 'BiasL2Factor',0);
conv14.Weights = randn([conv14.FilterSize,256,conv14.NumFilters])*sqrt(2/(n_elements_kernel*conv14.NumFilters));    
conv14.Bias = randn([1,1,conv14.NumFilters])*sqrt(2/conv14.NumFilters);
batn14 = batchNormalizationLayer('Name','batn14');
relu14 = reluLayer('Name','relu14');
upsa3 = transposedConv2dLayer(2,128,'Stride',2,'Name','upsa3');

%Upsampling Level 4
conca3 = concatenationLayer(3,2,'Name','conca3'); %in1 will be relu4 and in2 upsa3
conv15 = convolution2dLayer(3,128,'Padding',[1 1],'Name','conv15', 'BiasL2Factor',0);
conv15.Weights = randn([conv15.FilterSize,256,conv15.NumFilters])*sqrt(2/(n_elements_kernel*conv15.NumFilters));    
conv15.Bias = randn([1,1,conv15.NumFilters])*sqrt(2/conv15.NumFilters);
batn15 = batchNormalizationLayer('Name','batn15');
relu15 = reluLayer('Name','relu15');
conv16 = convolution2dLayer(3,128,'Padding',[1 1],'Name','conv16', 'BiasL2Factor',0);
conv16.Weights = randn([conv16.FilterSize,128,conv16.NumFilters])*sqrt(2/(n_elements_kernel*conv16.NumFilters));    
conv16.Bias = randn([1,1,conv16.NumFilters])*sqrt(2/conv16.NumFilters);
batn16 = batchNormalizationLayer('Name','batn16');
relu16 = reluLayer('Name','relu16');
upsa4 = transposedConv2dLayer(2,64,'Stride',2,'Name','upsa4');

%Upsampling Level 5
conca4 = concatenationLayer(3,2,'Name','conca4'); %in1 will be relu2 and in2 upsa4
conv17 = convolution2dLayer(3,64,'Padding',[1 1],'Name','conv17', 'BiasL2Factor',0);
conv17.Weights = randn([conv17.FilterSize,128,conv17.NumFilters])*sqrt(2/(n_elements_kernel*conv17.NumFilters));    
conv17.Bias = randn([1,1,conv17.NumFilters])*sqrt(2/conv17.NumFilters);
batn17 = batchNormalizationLayer('Name','batn17');
relu17 = reluLayer('Name','relu17');
conv18 = convolution2dLayer(3,64,'Padding',[1 1],'Name','conv18', 'BiasL2Factor',0);
conv18.Weights = randn([conv18.FilterSize,64,conv18.NumFilters])*sqrt(2/(n_elements_kernel*conv18.NumFilters));    
conv18.Bias = randn([1,1,conv18.NumFilters])*sqrt(2/conv18.NumFilters);
batn18 = batchNormalizationLayer('Name','batn18');
relu18 = reluLayer('Name','relu18');

%------------------------------OUTPUT--------------------------------------
ooco1 = convolution2dLayer(1,1,'Name','ooco1');
ooco1.Weights = randn([ooco1.FilterSize,64,ooco1.NumFilters])*sqrt(2/(n_elements_kernel*ooco1.NumFilters));
%Last layer is a 1:1 convolution that adds two numb layers to the output
%image (image needs to be XxYx3)
%ooco2 = convolution2dLayer(1,3,'Name','ooco2','WeightLearnRateFactor',0,'WeightL2Factor',0,'BiasLearnRateFactor',0,'WeightL2Factor',0,'BiasL2Factor',0);
% ooco2.Weights = ones([ooco1.FilterSize,64,3]);
% ooco2.Weights(:,:,:,2:3) = zeros([ooco1.FilterSize,64,2]);
% ooco2.Bias(:,:,:) = zeros(1,1,3);

%Output
cout1 = unet1output('cout1');

%===========CONNECTION BETWEEEN BRANCHES AND LAYERS========================
layers = [
    conca_SEQ
    conv9
    batn9
    relu9 
    conv10 
    batn10
    relu10 
    dro1
    upsa1 
    conca1 
    conv11
    batn11
    relu11 
    conv12 
    batn12
    relu12     
    upsa2 
    conca2 
    conv13 
    batn13
    relu13 
    conv14 
    batn14
    relu14 
    upsa3 
    conca3 
    conv15
    batn15
    relu15    
    conv16 
    batn16
    relu16 
    upsa4 
    conca4 %Uncomment if training is not on residuals
    conv17
    batn17
    relu17
    conv18
    batn18
    relu18 
    ooco1
%    ooco2
    cout1];

lgraph = addLayers(lgraph, layers);

%Attach concatenation layers
%In this case, the concatenation layers go from SE to SE. 

lgraph = connectLayers(lgraph,'SE_pool4','conca_SEQ/in1');
lgraph = connectLayers(lgraph,'STEAM_pool4','conca_SEQ/in2');
lgraph = connectLayers(lgraph,'SE_relu8','conca1/in2');
lgraph = connectLayers(lgraph,'SE_relu6','conca2/in2');
lgraph = connectLayers(lgraph,'SE_relu4','conca3/in2');
lgraph = connectLayers(lgraph,'SE_relu2','conca4/in2');

%plot(lgraph);
clearvars -except img_size lgraph dataset perc ntest;

%% DATASET CREATION

disp("Dataset creation time: ");
tic
dataset = removeTooBrightImages(dataset);

%We remove too bright pixels 
dataset = removeTooBrightImages(dataset);

[TR_NO_DS,TR_DE_DS,VA_NO_DS,VA_DE_DS]= generate_ynet1_datastore(dataset,perc,ntest);

%Now, we create unet Datastore for training
training_datastore = ynet1_datastore(TR_NO_DS,TR_DE_DS, 15);

size_minibatch_validation = round(length(VA_NO_DS.Files)/13);
validation_datastore = ynet1_datastore(VA_NO_DS,VA_DE_DS,size_minibatch_validation);

toc

%% TRAINING OPTIONS

options = trainingOptions('sgdm',...
    'InitialLearnRate',0.5,...
    'MiniBatchSize',15,...
    'L2Regularization',10e-5,...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropFactor',0.1, ...
    'Momentum',0.98,...
    'LearnRateDropPeriod',5, ...
    'MaxEpochs',40,...
    'Plots','none',...
    'ValidationData',validation_datastore,...
    'ValidationFrequency',1800);
 
%% TRAINING


[trained_ynet_SE,info] = trainNetwork(training_datastore,lgraph,options);
    


%% EXTRA FUNCTIONS


function downsampling_unet = createDownSamplingBranch(n_elements_kernel,rootname)

%Creates a Downsampling branch.

%Downsampling Level 1

conv1 = convolution2dLayer(3,64,'Padding',[1 1],'Name',strcat(rootname,'conv1'), 'BiasL2Factor',0);
conv1.Weights = randn([conv1.FilterSize,1,conv1.NumFilters])*sqrt(2/(n_elements_kernel*conv1.NumFilters));    
conv1.Bias = randn([1,1,conv1.NumFilters])*sqrt(2/conv1.NumFilters);
batn1 = batchNormalizationLayer('Name',strcat(rootname,'batn1'));
relu1 = reluLayer('Name',strcat(rootname,'relu1'));
conv2 = convolution2dLayer(3,64,'Padding',[1 1],'Name',strcat(rootname,'conv2'), 'BiasL2Factor',0);
conv2.Weights = randn([conv2.FilterSize,64,conv1.NumFilters])*sqrt(2/(n_elements_kernel*conv1.NumFilters));
conv2.Bias = randn([1,1,conv2.NumFilters])*sqrt(2/conv2.NumFilters);
batn2 = batchNormalizationLayer('Name',strcat(rootname,'batn2'));
relu2 = reluLayer('Name',strcat(rootname,'relu2'));
pool1 = maxPooling2dLayer(2,'Name',strcat(rootname,'pool1'),'Stride',2);

%Downsampling Level 2
conv3 = convolution2dLayer(3,128,'Padding',[1 1],'Name',strcat(rootname,'conv3'), 'BiasL2Factor',0);
conv3.Weights = randn([conv3.FilterSize,64,conv3.NumFilters])*sqrt(2/(n_elements_kernel*conv3.NumFilters));    
conv3.Bias = randn([1,1,conv3.NumFilters])*sqrt(2/conv3.NumFilters);
batn3 = batchNormalizationLayer('Name',strcat(rootname,'batn3'));
relu3 = reluLayer('Name',strcat(rootname,'relu3'));
conv4 = convolution2dLayer(3,128,'Padding',[1 1],'Name',strcat(rootname,'conv4'), 'BiasL2Factor',0);
conv4.Weights = randn([conv4.FilterSize,128,conv4.NumFilters])*sqrt(2/(n_elements_kernel*conv4.NumFilters));    
conv4.Bias = randn([1,1,conv4.NumFilters])*sqrt(2/conv4.NumFilters);
batn4 = batchNormalizationLayer('Name',strcat(rootname,'batn4'));
relu4 = reluLayer('Name',strcat(rootname,'relu4'));
pool2 = maxPooling2dLayer(2,'Name',strcat(rootname,'pool2'),'Stride',2);

%Downsampling Level 3
conv5 = convolution2dLayer(3,256,'Padding',[1 1],'Name',strcat(rootname,'conv5'), 'BiasL2Factor',0);
conv5.Weights = randn([conv4.FilterSize,128,conv5.NumFilters])*sqrt(2/(n_elements_kernel*conv5.NumFilters));    
conv5.Bias = randn([1,1,conv5.NumFilters])*sqrt(2/conv5.NumFilters);
batn5 = batchNormalizationLayer('Name',strcat(rootname,'batn5'));
relu5 = reluLayer('Name',strcat(rootname,'relu5'));
conv6 = convolution2dLayer(3,256,'Padding',[2 2],'Name',strcat(rootname,'conv6'), 'BiasL2Factor',0);
conv6.Weights = randn([conv6.FilterSize,256,conv6.NumFilters])*sqrt(2/(n_elements_kernel*conv6.NumFilters));    
conv6.Bias = randn([1,1,conv6.NumFilters])*sqrt(2/conv6.NumFilters);
batn6 = batchNormalizationLayer('Name',strcat(rootname,'batn6'));
relu6 = reluLayer('Name',strcat(rootname,'relu6'));
pool3 = maxPooling2dLayer(2,'Name',strcat(rootname,'pool3'),'Stride',2);

%Downsampling Level 4
conv7 = convolution2dLayer(3,512,'Padding',[1 1],'Name',strcat(rootname,'conv7'), 'BiasL2Factor',0);
conv7.Weights = randn([conv7.FilterSize,256,conv7.NumFilters])*sqrt(2/(n_elements_kernel*conv7.NumFilters));    
conv7.Bias = randn([1,1,conv7.NumFilters])*sqrt(2/conv7.NumFilters);
batn7 = batchNormalizationLayer('Name',strcat(rootname,'batn7'));
relu7 = reluLayer('Name',strcat(rootname,'relu7'));
conv8 = convolution2dLayer(3,512,'Padding',[2 2],'Name',strcat(rootname,'conv8'), 'BiasL2Factor',0);
conv8.Weights = randn([conv8.FilterSize,512,conv8.NumFilters])*sqrt(2/(n_elements_kernel*conv8.NumFilters));    
conv8.Bias = randn([1,1,conv8.NumFilters])*sqrt(2/conv8.NumFilters);
batn8 = batchNormalizationLayer('Name',strcat(rootname,'batn8'));
relu8 = reluLayer('Name',strcat(rootname,'relu8'));
pool4 = maxPooling2dLayer(2,'Name',strcat(rootname,'pool4'),'Stride',2,'Padding',[0 0]);

%Connection 

downsampling_unet = [conv1 
    batn1
    relu1 
    conv2
    batn2
    relu2 
    pool1 
    conv3
    batn3
    relu3 
    conv4
    batn4
    relu4 
    pool2     
    conv5
    batn5
    relu5 
    conv6
    batn6
    relu6 
    pool3 
    conv7
    batn7
    relu7 
    conv8 
    batn8
    relu8 
    pool4];

end
function branch = updateNetworkWeights(branch, path_net,first,last)
    
    %Adds the weights and biases of a pre-trained network to the branches
    %of the Y-NET
    %Branch: Branch (SE, STEAM) to update. Must be a Nx1 Layer object
    %Path_net: path to the network. Must have format 'trained_nets/X.mat'
    %First: name of the first layer of interest of the imported network
    %Last: name of the last layer of interest of the imported network
    %OUT: Branch (biases and weights updated)
    
    %Importation
    trained_network = load(path_net); %Gives a 1x1 struct
    namestruct = fieldnames(trained_network);
   
    trained_network = layerGraph(trained_network.(namestruct{1,1}));
    
    first_in = 0;
    last_in = 0;
    %We find the indexes of the first and last
    for i=1:size(trained_network.Layers)
        name = trained_network.Layers(i,1).Name;
        if isequal(name,first)
            first_in = i;
        elseif isequal(name,last)
            last_in = i;
        end
    end
    
    n_layers = last_in-first_in+1;
    if size(branch,1)~=n_layers
        error("Unmatching pre-trained network and branch layer graph! Check network and 'first' and 'last' arguments!");
    end
    
    for i=first_in:last_in
        try 
            weights = trained_network.Layers(i,1).Weights;
            biases =  trained_network.Layers(i,1).Bias;           
            try
                branch(i-first_in+1,1).Weights = double(weights);
            catch
                error("Cannot assign the weights of layer i to branch-layer. Unmatching weights");
            end
            try
                branch(i-first_in+1,1).Bias = double(biases);
            catch
                error("Cannot assign the bias of layer i to branch-layer. Unmatching bias");
            end            
        catch
        end
    end
    
end
function dataset_new = removeTooBrightImages(dataset)
%Removes images that are too bright and can endanger the training
%Global parameters:
threshold = 900; %Number of pixels
threshold_value = 90; %Value at which we count pixels
dataset_new = [];

    for i=1:size(dataset,1)
        relevant_image = dataset{i,1};
        relevant_image = relevant_image(:,:,1); %First channel 
        n_highpix =  sum(sum(relevant_image>threshold_value));
        if n_highpix<threshold
            dataset_new = [dataset_new;dataset(i,:)];
        end
    end

end

end