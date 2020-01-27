function [trained_unet_SE,info_SE] = train_unetSE(dataset,perc,ntest)

%1. DEFINITION OF LAYERS 

%Weights are initialized as per rule stipulated in O. Ronneberger U-NET
%paper. 
n_elements_kernel = 9;

%Input
inp1 = imageInputLayer(img_size,'Name','input1');

%Downsampling Level 1

conv1 = convolution2dLayer(3,64,'Padding',[1 1],'Name','conv1', 'BiasL2Factor',0);
conv1.Weights = randn([conv1.FilterSize,1,conv1.NumFilters])*sqrt(2/(n_elements_kernel*conv1.NumFilters));    
conv1.Bias = randn([1,1,conv1.NumFilters])*sqrt(2/conv1.NumFilters);
batn1 = batchNormalizationLayer('Name','batn1');
relu1 = reluLayer('Name','relu1');
conv2 = convolution2dLayer(3,64,'Padding',[1 1],'Name','conv2', 'BiasL2Factor',0);
conv2.Weights = randn([conv2.FilterSize,64,conv1.NumFilters])*sqrt(2/(n_elements_kernel*conv1.NumFilters));
conv2.Bias = randn([1,1,conv2.NumFilters])*sqrt(2/conv2.NumFilters);
batn2 = batchNormalizationLayer('Name','batn2');
relu2 = reluLayer('Name','relu2');
pool1 = maxPooling2dLayer(2,'Name','pool1','Stride',2);

%Downsampling Level 2
conv3 = convolution2dLayer(3,128,'Padding',[1 1],'Name','conv3', 'BiasL2Factor',0);
conv3.Weights = randn([conv3.FilterSize,64,conv3.NumFilters])*sqrt(2/(n_elements_kernel*conv3.NumFilters));    
conv3.Bias = randn([1,1,conv3.NumFilters])*sqrt(2/conv3.NumFilters);
batn3 = batchNormalizationLayer('Name','batn3');
relu3 = reluLayer('Name','relu3');
conv4 = convolution2dLayer(3,128,'Padding',[1 1],'Name','conv4', 'BiasL2Factor',0);
conv4.Weights = randn([conv4.FilterSize,128,conv4.NumFilters])*sqrt(2/(n_elements_kernel*conv4.NumFilters));    
conv4.Bias = randn([1,1,conv4.NumFilters])*sqrt(2/conv4.NumFilters);
batn4 = batchNormalizationLayer('Name','batn4');
relu4 = reluLayer('Name','relu4');
pool2 = maxPooling2dLayer(2,'Name','pool2','Stride',2);

%Downsampling Level 3
conv5 = convolution2dLayer(3,256,'Padding',[1 1],'Name','conv5', 'BiasL2Factor',0);
conv5.Weights = randn([conv4.FilterSize,128,conv5.NumFilters])*sqrt(2/(n_elements_kernel*conv5.NumFilters));    
conv5.Bias = randn([1,1,conv5.NumFilters])*sqrt(2/conv5.NumFilters);
batn5 = batchNormalizationLayer('Name','batn5');
relu5 = reluLayer('Name','relu5');
conv6 = convolution2dLayer(3,256,'Padding',[2 2],'Name','conv6', 'BiasL2Factor',0);
conv6.Weights = randn([conv6.FilterSize,256,conv6.NumFilters])*sqrt(2/(n_elements_kernel*conv6.NumFilters));    
conv6.Bias = randn([1,1,conv6.NumFilters])*sqrt(2/conv6.NumFilters);
batn6 = batchNormalizationLayer('Name','batn6');
relu6 = reluLayer('Name','relu6');
pool3 = maxPooling2dLayer(2,'Name','pool3','Stride',2);

%Downsampling Level 4
conv7 = convolution2dLayer(3,512,'Padding',[1 1],'Name','conv7', 'BiasL2Factor',0);
conv7.Weights = randn([conv7.FilterSize,256,conv7.NumFilters])*sqrt(2/(n_elements_kernel*conv7.NumFilters));    
conv7.Bias = randn([1,1,conv7.NumFilters])*sqrt(2/conv7.NumFilters);
batn7 = batchNormalizationLayer('Name','batn7');
relu7 = reluLayer('Name','relu7');
conv8 = convolution2dLayer(3,512,'Padding',[2 2],'Name','conv8', 'BiasL2Factor',0);
conv8.Weights = randn([conv8.FilterSize,512,conv8.NumFilters])*sqrt(2/(n_elements_kernel*conv8.NumFilters));    
conv8.Bias = randn([1,1,conv8.NumFilters])*sqrt(2/conv8.NumFilters);
batn8 = batchNormalizationLayer('Name','batn8');
relu8 = reluLayer('Name','relu8');
pool4 = maxPooling2dLayer(2,'Name','pool4','Stride',2,'Padding',[0 0]);

%Upsampling Level 1
conv9 = convolution2dLayer(3,1024,'Padding',[1 1],'Name','conv9', 'BiasL2Factor',0);
conv9.Weights = randn([conv9.FilterSize,512,conv9.NumFilters])*sqrt(2/(n_elements_kernel*conv9.NumFilters));    
conv9.Bias = randn([1,1,conv9.NumFilters])*sqrt(2/conv9.NumFilters);
batn9 = batchNormalizationLayer('Name','batn9');
relu9 = reluLayer('Name','relu9');
conv10 = convolution2dLayer(3,1024,'Padding',[1 1],'Name','conv10', 'BiasL2Factor',0);
conv10.Weights = randn([conv10.FilterSize,1024,conv10.NumFilters])*sqrt(2/(n_elements_kernel*conv10.NumFilters));    
conv10.Bias = randn([1,1,conv10.NumFilters])*sqrt(2/conv10.NumFilters);
batn10 = batchNormalizationLayer('Name','batn10');
relu10 = reluLayer('Name','relu10');
dro1 = dropoutLayer(0.2,'Name', 'dro1');
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
%conca4 = concatenationLayer(3,2,'Name','conca4'); %in1 will be relu2 and in2 upsa4
conv17 = convolution2dLayer(3,64,'Padding',[1 1],'Name','conv17', 'BiasL2Factor',0);
conv17.Weights = randn([conv17.FilterSize,64,conv17.NumFilters])*sqrt(2/(n_elements_kernel*conv17.NumFilters));    
conv17.Bias = randn([1,1,conv17.NumFilters])*sqrt(2/conv17.NumFilters);
batn17 = batchNormalizationLayer('Name','batn17');
relu17 = reluLayer('Name','relu17');
conv18 = convolution2dLayer(3,64,'Padding',[1 1],'Name','conv18', 'BiasL2Factor',0);
conv18.Weights = randn([conv18.FilterSize,64,conv18.NumFilters])*sqrt(2/(n_elements_kernel*conv18.NumFilters));    
conv18.Bias = randn([1,1,conv18.NumFilters])*sqrt(2/conv18.NumFilters);
batn18 = batchNormalizationLayer('Name','batn18');
relu18 = reluLayer('Name','relu18');

%Output 
ooco1 = convolution2dLayer(1,1,'Name','ooco1');
ooco1.Weights = randn([ooco1.FilterSize,64,ooco1.NumFilters])*sqrt(2/(n_elements_kernel*ooco1.NumFilters));    
cout1 = unet1output('cout1');

%2. CREATION OF LAYER OBJECT

lgraph = layerGraph;
layers = [inp1 
    conv1
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
    pool4    
    conv9
    batn9
    relu9 
    conv10
    batn10
    relu10 
    dro1;
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
%    conca4 
    conv17
    batn17
    relu17
    conv18
    batn18
    relu18 
    ooco1
    cout1];
lgraph = addLayers(lgraph,layers);

%Attach concatenation layers
lgraph = connectLayers(lgraph,'relu8','conca1/in2');
lgraph = connectLayers(lgraph,'relu6','conca2/in2');
lgraph = connectLayers(lgraph,'relu4','conca3/in2');
%lgraph = connectLayers(lgraph,'relu2','conca4/in2');
 
clearvars -except lgraph img_size dataset perc ntest;

%plot(lgraph); %Plot the network

%2. DATASET

%Uses the output of generate_unet1_datastore
%Percentage and Ntest aren't important as the generation of the dataset
%itself has been disabled. Values correspond to those that were used to
%create them.


%****TO CREATE A NEW DATASET****
%Go to generate_unet1_datastore: uncomment lines 27 to 30
disp("Dataset creation time: ");
tic

%We remove too bright pixels 
dataset = removeTooBrightImages(dataset);

[TR_NO_DS,TR_DE_DS,VA_NO_DS,VA_DE_DS]= generate_unet1_seqse(dataset,perc,ntest,'SE');

%Now, we create unet Datastore for training
training_datastore = unet1_datastore(TR_NO_DS,TR_DE_DS, 5);

size_minibatch_validation = round(length(VA_NO_DS.Files)/10);
validation_datastore = unet1_datastore(VA_NO_DS,VA_DE_DS,size_minibatch_validation);

toc
%3 Training Options
options = trainingOptions('sgdm',...
    'InitialLearnRate',0.005,...
    'MiniBatchSize',5,...
    'L2Regularization',10e-6,...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropFactor',0.98, ...
    'LearnRateDropPeriod',5, ...
    'MaxEpochs',50,...
    'Verbose',false,...
    'Plots','none',...
    'ValidationData',validation_datastore,...
    'ValidationFrequency',(round(training_datastore.NumObservations/10)),...
    'Momentum',0.98);
 

%4 Training

[trained_unet_SE,info_SE] = trainNetwork(training_datastore,lgraph,options);
    

end

function dataset_new = removeTooBrightImages(dataset)

%Removes images that are too bright and can endanger the training
%Global parameters:
threshold = 900; %Number of pixels
threshold_value = 90; %Value at which we count pixels
dataset_new = [];

    for i=1:size(dataset,1)
        n_highpix =  sum(sum(dataset{i,1}>threshold_value));
        if n_highpix<threshold
            dataset_new = [dataset_new;dataset(i,:)];
        end
    end

end

