function [trained_unet_STEAM,info_STEAM] = train_unetSTEAM(dataset,net,perc,ntest)
%Dataset: Structure with Nx3 image dataset
%Net: Pre-trained neural network 
%Perc: Percentage of training in the dataset
%Ntest: Number of test samples

%1. DATASET

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

[TR_NO_DS,TR_DE_DS,VA_NO_DS,VA_DE_DS]= generate_unet1_seqse(dataset,perc,ntest,'STEAM');

%Now, we create unet Datastore for training
training_datastore = unet1_datastore(TR_NO_DS,TR_DE_DS, 5);

size_minibatch_validation = round(length(VA_NO_DS.Files)/10);
validation_datastore = unet1_datastore(VA_NO_DS,VA_DE_DS,size_minibatch_validation);

toc

%2 Training Options
options = trainingOptions('sgdm',...
    'InitialLearnRate',0.004,...
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

[trained_unet_STEAM,info_STEAM] = trainNetwork(training_datastore,layerGraph(net),options);
    
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

