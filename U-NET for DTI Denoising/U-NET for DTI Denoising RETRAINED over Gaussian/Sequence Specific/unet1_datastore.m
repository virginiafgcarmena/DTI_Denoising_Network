classdef unet1_datastore < matlab.io.Datastore &...
                       matlab.io.datastore.MiniBatchable  & ...
                       matlab.io.datastore.Shuffleable %Necessary to get different MiniBatches
                   
    %Source: https://www.mathworks.com/help/deeplearning/ug/develop-custom-mini-batch-datastore.html
    
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
        function unet1_ds = unet1_datastore(noisy_ds,denoised_ds,mbs)
            unet1_ds.input = noisy_ds;
            unet1_ds.groundtruth = denoised_ds;
            unet1_ds.NumObservations = length(noisy_ds.Files);
            unet1_ds.CurrentFileIndex = 1;
            unet1_ds.MiniBatchSize = mbs;
            unet1_ds.input.ReadSize = mbs; %Necessary to read all the data in the read function
            unet1_ds.groundtruth.ReadSize = mbs;  
            
            %We shuffle the dataset once
            unet1_ds = shuffle(unet1_ds); %Change the first 5 MB taken
            
        end
        
        function tf = hasdata(unet1_ds)
           tf = hasdata(unet1_ds.input);             
        end
        
        function [data,info] = read(unet1_ds)
            %Read data from the datastore
            if ~(hasdata(unet1_ds))
                 error(sprintf(['No more data to read.\nUse the reset ',...
                    'method to reset the datastore to the start of ' ,...
                    'the data. \nBefore calling the read method, ',...
                    'check if data is available to read ',...
                    'by using the hasdata method.']))
            end
            
            %We select a subset of the input and output datastore to run the read function only on the mini-batch size
            
            %SUBSET INPUT
            inp_ss = subset(unet1_ds.input,unet1_ds.CurrentFileIndex:(unet1_ds.CurrentFileIndex+unet1_ds.MiniBatchSize-1));
            gtr_ss = subset(unet1_ds.groundtruth,unet1_ds.CurrentFileIndex:(unet1_ds.CurrentFileIndex+unet1_ds.MiniBatchSize-1));
            
            %Read information from datastores
            inputdata = read(inp_ss);
            outputdata = read(gtr_ss);
            
            noisy_im = cell(unet1_ds.MiniBatchSize,1);
            denoised_im = cell(unet1_ds.MiniBatchSize,1);
            resid = cell(unet1_ds.MiniBatchSize,1);
          
            for i=1:unet1_ds.MiniBatchSize
                img = double(inputdata{i});
                img_den = double(outputdata{i});
                noisy_im{i} =img;
                denoised_im{i}=img_den;
                resid{i} = img_den-img;
            end
            
            data = [table(noisy_im) table(resid)];
            info.datasetSize = size(data,1);
            unet1_ds.CurrentFileIndex = unet1_ds.CurrentFileIndex +info.datasetSize;
            info.CurrentFileIndex = unet1_ds.CurrentFileIndex;
            
            if (unet1_ds.CurrentFileIndex>=unet1_ds.NumObservations)
                reset(unet1_ds);
            end
            
            end
            
            function reset(unet1_ds)
                reset(unet1_ds.input);
                reset(unet1_ds.groundtruth);
                unet1_ds.CurrentFileIndex = 1;  
            end    
            
            function unet1_ds_shuffled = shuffle(unet1_ds) %Necessary for "suffleable" classes
                randomsort = randperm(unet1_ds.NumObservations);
                unet1_ds_shuffled = unet1_ds;
                unet1_ds_shuffled.input.Files = unet1_ds_shuffled.input.Files(randomsort);
                unet1_ds_shuffled.groundtruth.Files = unet1_ds_shuffled.groundtruth.Files(randomsort);
            end
     end
        
        methods (Hidden=true)
            function frac = progress(unet1_ds)
                frac = (unet1_ds.CurrentFileIndex-1)/unet1_ds.NumObservations;
            end
        end

    
    
end