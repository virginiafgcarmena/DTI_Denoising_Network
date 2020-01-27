function [retrained_unet1,info,options] = retrain_unet1(net,dataset,lastLR,perc,ntest)

%Retrain Unet:
% Returns a U-NET network retrained on a network that has non-initial weights.
% The network must be propperly loaded with the Output function it used
% ARGUMENTS:
% Net: DAG Network
% Dataset: The dataset to train. If it's a new dataset, make sure there are no "training_imgs" or "val_imgs" folders in the current directory.
% LastLR: Initial Learning Rate for this re-training must ideally match the last learning rate used by the original network. 
% For this, check the "info" file of the network, and on the "Base Learning rate" column, check the last one.
% Perc: If the dataset is new, percentage of training/validation
% ntest: number of test images kept aside (leave blank)

%DATASET

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

[TR_NO_DS,TR_DE_DS,VA_NO_DS,VA_DE_DS]= generate_unet1_datastore(dataset,perc,ntest);

%Now, we create unet Datastore for training
training_datastore = unet1_datastore(TR_NO_DS,TR_DE_DS, 15);

size_minibatch_validation = round(length(VA_NO_DS.Files)/10);
validation_datastore = unet1_datastore(VA_NO_DS,VA_DE_DS,size_minibatch_validation);

toc
%3 Training Options
options = trainingOptions('sgdm',...
    'InitialLearnRate',lastLR,...
    'MiniBatchSize',15,...
    'L2Regularization',10e-6,...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropFactor',0.98, ...
    'LearnRateDropPeriod',5, ...
    'MaxEpochs',30,...
    'Plots','none',...
    'ValidationData',validation_datastore,...
    'ValidationFrequency',(round(training_datastore.NumObservations/10)),...
    'Momentum',0.97);
 

[retrained_unet1,info] = trainNetwork(training_datastore,layerGraph(net),options);
    

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
