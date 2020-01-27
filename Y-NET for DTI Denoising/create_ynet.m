%Y-NET TEST SCRIPT 
%Creates a network (graph) object forked 
%Date: 28 Jun 2019
%Author: Virginia Fernandez
%MSc Project = Y-NET
%This script only creates the network. Creation + training is in
%train_ynet1

img_size = [120,88,2]; %2 channels: 1st, SE image, 2nd STEAM image
lgraph = layerGraph;

%-------------------------INPUT LAYER----------------------------
inp1 = imageInputLayer(img_size,'Name','inp1');
lgraph = addLayers(lgraph,inp1);
%------------------------SPLITTER PIPELINE-----------------------
%Extracted from: https://www.mathworks.com/matlabcentral/answers/369328-how-to-use-multiple-input-layers-in-dag-net-as-shown-in-the-figure
ch_1_splitter = convolution2dLayer(1,1,'Name','split1','WeightLearnRateFactor',0,'WeightL2Factor',0,'BiasLearnRateFactor',0,'WeightL2Factor',0,'BiasL2Factor',0);
ch_2_splitter = convolution2dLayer(1,1,'Name','split2','WeightLearnRateFactor',0,'WeightL2Factor',0,'BiasLearnRateFactor',0,'WeightL2Factor',0,'BiasL2Factor',0);
ch_1_splitter.Weights = zeros(1,1,2,1); ch_2_splitter.Weights = zeros(1,1,2,1);
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
relu9 = reluLayer('Name','relu9');
conv10 = convolution2dLayer(3,1024,'Padding',[1 1],'Name','conv10', 'BiasL2Factor',0);
conv10.Weights = randn([conv10.FilterSize,1024,conv10.NumFilters])*sqrt(2/(n_elements_kernel*conv10.NumFilters));    
relu10 = reluLayer('Name','relu10');
dro1 = dropoutLayer(0.5,'Name', 'dro1');
upsa1 = transposedConv2dLayer(2,512,'Stride',2,'Name','upsa1');

%Upsampling Level 2
conca1 = concatenationLayer(3,2,'Name','conca1'); %in1 will be relu8 and in2 upsa1
conv11 = convolution2dLayer(3,512,'Padding',[1 1],'Name','conv11', 'BiasL2Factor',0);
conv11.Weights = randn([conv11.FilterSize,1024,conv11.NumFilters])*sqrt(2/(n_elements_kernel*conv11.NumFilters));    
relu11 = reluLayer('Name','relu11');
conv12 = convolution2dLayer(3,512,'Padding',[0 0],'Name','conv12', 'BiasL2Factor',0);
conv12.Weights = randn([conv12.FilterSize,512,conv12.NumFilters])*sqrt(2/(n_elements_kernel*conv12.NumFilters));    
relu12 = reluLayer('Name','relu12');
upsa2 = transposedConv2dLayer(2,256,'Stride',2,'Name','upsa2');


%Upsampling Level 3
conca2 = concatenationLayer(3,2,'Name','conca2'); %in1 will be relu6 and in2 upsa2
conv13 = convolution2dLayer(3,256,'Padding',[1 1],'Name','conv13', 'BiasL2Factor',0);
conv13.Weights = randn([conv13.FilterSize,512,conv13.NumFilters])*sqrt(2/(n_elements_kernel*conv13.NumFilters));    
relu13 = reluLayer('Name','relu13');
conv14 = convolution2dLayer(3,256,'Padding',[0 0],'Name','conv14', 'BiasL2Factor',0);
conv14.Weights = randn([conv14.FilterSize,256,conv14.NumFilters])*sqrt(2/(n_elements_kernel*conv14.NumFilters));    
relu14 = reluLayer('Name','relu14');
upsa3 = transposedConv2dLayer(2,128,'Stride',2,'Name','upsa3');

%Upsampling Level 4
conca3 = concatenationLayer(3,2,'Name','conca3'); %in1 will be relu4 and in2 upsa3
conv15 = convolution2dLayer(3,128,'Padding',[1 1],'Name','conv15', 'BiasL2Factor',0);
conv15.Weights = randn([conv15.FilterSize,256,conv15.NumFilters])*sqrt(2/(n_elements_kernel*conv15.NumFilters));    
relu15 = reluLayer('Name','relu15');
conv16 = convolution2dLayer(3,128,'Padding',[1 1],'Name','conv16', 'BiasL2Factor',0);
conv16.Weights = randn([conv16.FilterSize,128,conv16.NumFilters])*sqrt(2/(n_elements_kernel*conv16.NumFilters));    
relu16 = reluLayer('Name','relu16');
upsa4 = transposedConv2dLayer(2,64,'Stride',2,'Name','upsa4');

%Upsampling Level 5
conca4 = concatenationLayer(3,2,'Name','conca4'); %in1 will be relu2 and in2 upsa4
conv17 = convolution2dLayer(3,64,'Padding',[1 1],'Name','conv17', 'BiasL2Factor',0);
conv17.Weights = randn([conv17.FilterSize,128,conv17.NumFilters])*sqrt(2/(n_elements_kernel*conv17.NumFilters));    
relu17 = reluLayer('Name','relu17');
conv18 = convolution2dLayer(3,64,'Padding',[1 1],'Name','conv18', 'BiasL2Factor',0);
conv18.Weights = randn([conv18.FilterSize,64,conv18.NumFilters])*sqrt(2/(n_elements_kernel*conv18.NumFilters));    
relu18 = reluLayer('Name','relu18');

%------------------------------OUTPUT--------------------------------------
ooco1 = convolution2dLayer(1,1,'Name','ooco1');
ooco1.Weights = randn([ooco1.FilterSize,64,ooco1.NumFilters])*sqrt(2/(n_elements_kernel*ooco1.NumFilters));    
cout1 = unet1output('cout1');

%===========CONNECTION BETWEEEN BRANCHES AND LAYERS========================
layers = [
    conca_SEQ
    conv9 
    relu9 
    conv10 
    relu10 
    dro1
    upsa1 
    conca1 
    conv11 
    relu11 
    conv12 
    relu12     
    upsa2 
    conca2 
    conv13 
    relu13 
    conv14 
    relu14 
    upsa3 
    conca3 
    conv15 
    relu15    
    conv16 
    relu16 
    upsa4 
    conca4 %Uncomment if training is not on residuals
    conv17 
    relu17
    conv18 
    relu18 
    ooco1
    cout1];

lgraph = addLayers(lgraph, layers);

%Attach concatenation layers
lgraph = connectLayers(lgraph,'SE_pool4','conca_SEQ/in1');
lgraph = connectLayers(lgraph,'STEAM_pool4','conca_SEQ/in2');
lgraph = connectLayers(lgraph,'SE_relu8','conca1/in2');
lgraph = connectLayers(lgraph,'SE_relu6','conca2/in2');
lgraph = connectLayers(lgraph,'SE_relu4','conca3/in2');
lgraph = connectLayers(lgraph,'SE_relu2','conca4/in2');

plot(lgraph);
clearvars -except img_size lgraph;

function downsampling_unet = createDownSamplingBranch(n_elements_kernel,rootname)

%Downsampling Level 1

conv1 = convolution2dLayer(3,64,'Padding',[1 1],'Name',strcat(rootname,'conv1'), 'BiasL2Factor',0);
conv1.Weights = randn([conv1.FilterSize,1,conv1.NumFilters])*sqrt(2/(n_elements_kernel*conv1.NumFilters));    
relu1 = reluLayer('Name',strcat(rootname,'relu1'));
conv2 = convolution2dLayer(3,64,'Padding',[1 1],'Name',strcat(rootname,'conv2'), 'BiasL2Factor',0);
conv2.Weights = randn([conv2.FilterSize,64,conv1.NumFilters])*sqrt(2/(n_elements_kernel*conv1.NumFilters));
relu2 = reluLayer('Name',strcat(rootname,'relu2'));
pool1 = maxPooling2dLayer(2,'Name',strcat(rootname,'pool1'),'Stride',2);

%Downsampling Level 2
conv3 = convolution2dLayer(3,128,'Padding',[1 1],'Name',strcat(rootname,'conv3'), 'BiasL2Factor',0);
conv3.Weights = randn([conv3.FilterSize,64,conv3.NumFilters])*sqrt(2/(n_elements_kernel*conv3.NumFilters));    
relu3 = reluLayer('Name',strcat(rootname,'relu3'));
conv4 = convolution2dLayer(3,128,'Padding',[1 1],'Name',strcat(rootname,'conv4'), 'BiasL2Factor',0);
conv4.Weights = randn([conv4.FilterSize,128,conv4.NumFilters])*sqrt(2/(n_elements_kernel*conv4.NumFilters));    
relu4 = reluLayer('Name',strcat(rootname,'relu4'));
pool2 = maxPooling2dLayer(2,'Name',strcat(rootname,'pool2'),'Stride',2);

%Downsampling Level 3
conv5 = convolution2dLayer(3,256,'Padding',[1 1],'Name',strcat(rootname,'conv5'), 'BiasL2Factor',0);
conv5.Weights = randn([conv4.FilterSize,128,conv5.NumFilters])*sqrt(2/(n_elements_kernel*conv5.NumFilters));    
relu5 = reluLayer('Name',strcat(rootname,'relu5'));
conv6 = convolution2dLayer(3,256,'Padding',[2 2],'Name',strcat(rootname,'conv6'), 'BiasL2Factor',0);
conv6.Weights = randn([conv6.FilterSize,256,conv6.NumFilters])*sqrt(2/(n_elements_kernel*conv6.NumFilters));    
relu6 = reluLayer('Name',strcat(rootname,'relu6'));
pool3 = maxPooling2dLayer(2,'Name',strcat(rootname,'pool3'),'Stride',2);

%Downsampling Level 4
conv7 = convolution2dLayer(3,512,'Padding',[1 1],'Name',strcat(rootname,'conv7'), 'BiasL2Factor',0);
conv7.Weights = randn([conv7.FilterSize,256,conv7.NumFilters])*sqrt(2/(n_elements_kernel*conv7.NumFilters));    
relu7 = reluLayer('Name',strcat(rootname,'relu7'));
conv8 = convolution2dLayer(3,512,'Padding',[2 2],'Name',strcat(rootname,'conv8'), 'BiasL2Factor',0);
conv8.Weights = randn([conv8.FilterSize,512,conv8.NumFilters])*sqrt(2/(n_elements_kernel*conv8.NumFilters));    
relu8 = reluLayer('Name',strcat(rootname,'relu8'));
pool4 = maxPooling2dLayer(2,'Name',strcat(rootname,'pool4'),'Stride',2,'Padding',[0 0]);

%Connection 

downsampling_unet = [conv1 
    relu1 
    conv2 
    relu2 
    pool1 
    conv3 
    relu3 
    conv4 
    relu4 
    pool2     
    conv5 
    relu5 
    conv6 
    relu6 
    pool3 
    conv7 
    relu7 
    conv8 
    relu8 
    pool4];


end