classdef ynet1_datastore < matlab.io.Datastore &...
                       matlab.io.datastore.MiniBatchable  & ...
                       matlab.io.datastore.Shuffleable %Necessary to get different MiniBatches
                   
    %Source: https://www.mathworks.com/help/deeplearning/ug/develop-custom-mini-batch-datastore.html
    
    %Genrates the datastore necessary for the Y-NET training. Needs input
    %images to be formed by 3 channels, where the first two are the SE or
    %STEAM sequence.
    
    properties 
        size_obs
        MiniBatchSize
    end
    
    properties (SetAccess = protected)
        NumObservations
    end
    
    properties (SetAccess = private)
        CurrentFileIndex
        input
        groundtruth
    end
    
    methods
        function ynet1_ds = ynet1_datastore(noisy_ds,denoised_ds,mbs)
            ynet1_ds.input = noisy_ds;
            ynet1_ds.groundtruth = denoised_ds;
            ynet1_ds.NumObservations = length(noisy_ds.Files);
            ynet1_ds.CurrentFileIndex = 1;
            ynet1_ds.MiniBatchSize = mbs;
            ynet1_ds.input.ReadSize = mbs; %Necessary to read all the data in the read function
            ynet1_ds.groundtruth.ReadSize = mbs;  
            
            %We shuffle the dataset once
            ynet1_ds = shuffle(ynet1_ds); %Change the first 5 MB taken
            
        end
        
        function tf = hasdata(ynet1_ds)
           tf = hasdata(ynet1_ds.input);             
        end
        
        function [data,info] = read(ynet1_ds)
            %Read data from the datastore
            if ~(hasdata(ynet1_ds))
                 error(sprintf(['No more data to read.\nUse the reset ',...
                    'method to reset the datastore to the start of ' ,...
                    'the data. \nBefore calling the read method, ',...
                    'check if data is available to read ',...
                    'by using the hasdata method.']))
            end
            
            %We select a subset of the input and output datastore to run the read function only on the mini-batch size
            
            %SUBSET INPUT
            inp_ss = subset(ynet1_ds.input,ynet1_ds.CurrentFileIndex:(ynet1_ds.CurrentFileIndex+ynet1_ds.MiniBatchSize-1));
            gtr_ss = subset(ynet1_ds.groundtruth,ynet1_ds.CurrentFileIndex:(ynet1_ds.CurrentFileIndex+ynet1_ds.MiniBatchSize-1));
            
            %Read information from datastores
            inputdata = read(inp_ss);
            outputdata = read(gtr_ss);
            
            noisy_im = cell(ynet1_ds.MiniBatchSize,1);
            denoised_im = cell(ynet1_ds.MiniBatchSize,1);
            %Uncomment next line to get a training on residuals (WARNING:
            %Layers need to be changed as well)
            resid = cell(ynet1_ds.MiniBatchSize,1);
          
            for i=1:ynet1_ds.MiniBatchSize
                img = double(inputdata{i});
                img_den = double(outputdata{i});
                noisy_im{i} =img;
                denoised_im{i}=img_den;
                %Uncomment next line to get a training on residuals
                resid{i} = img_den-img(:,:,1);
            end
            data = [table(noisy_im) table(denoised_im)];
            %Uncomment next line to get a training on residuals
            %data = [table(noisy_im) table(resid)];
            info.datasetSize = size(data,1);
            ynet1_ds.CurrentFileIndex = ynet1_ds.CurrentFileIndex +info.datasetSize;
            info.CurrentFileIndex = ynet1_ds.CurrentFileIndex;
            
            if (ynet1_ds.CurrentFileIndex>=ynet1_ds.NumObservations)
                reset(ynet1_ds);
            end
            
            end
            
            function reset(ynet1_ds)
                reset(ynet1_ds.input);
                reset(ynet1_ds.groundtruth);
                ynet1_ds.CurrentFileIndex = 1;  
            end    
            
            function ynet1_ds_shuffled = shuffle(ynet1_ds) %Necessary for "suffleable" classes
                randomsort = randperm(ynet1_ds.NumObservations);
                ynet1_ds_shuffled = ynet1_ds;
                ynet1_ds_shuffled.input.Files = ynet1_ds_shuffled.input.Files(randomsort);
                ynet1_ds_shuffled.groundtruth.Files = ynet1_ds_shuffled.groundtruth.Files(randomsort);
            end
     end
        
        methods (Hidden=true)
            function frac = progress(ynet1_ds)
                frac = (ynet1_ds.CurrentFileIndex-1)/ynet1_ds.NumObservations;
            end
        end

    
    
end