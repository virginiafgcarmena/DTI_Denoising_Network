function [TR_NO_DS,TR_DE_DS,VA_NO_DS,VA_DE_DS]= generate_unet1_seqse(unified_dataset,perc,ntest,SEQ)
%RESCALED DATASTORE CREATION

%unified_dataset: data from patients, healthy subjects, 150 and 450
%b-values. Data does not need to be randomly permutated: that is done here.
%perc: percentage of training/(test+validation) images. 
%ntest: number of images left for test. This number is typically small
%(i.e. 20,30)
%THESE VALUES ARE ONLY USED IF YOU DON'T HAVE FOLDERS ALREADY CREATED!

%Current Folders used:
%Perc: 0.80 = 80%
%Ntest: 30 Observations

%output: ds stands for "datastore". Datastore object containing the indexes
%of the images and their corresponding ground-truths, stored in folders
%that are created in this program.

%Suffle dataset

 random_sort = randperm(numel(unified_dataset(:,1)));
 unified_dataset = unified_dataset(random_sort,:,:);

%Make directories

%Remove the directories if they exist to create the dataset again
% if exist('training_imgs')==7 %If the folder exists
%     rmdir('training_imgs','s');
%     rmdir('test_imgs','s');
%     rmdir('val_imgs','s');
% end

%Don't store the images in folders if they are already stored!
if exist(strcat('training_imgs',SEQ))==7 %If the folder exists
    training_done = 1;
else
    training_done = 0; mkdir(strcat('training_imgs',SEQ)); mkdir(fullfile(strcat('training_imgs',SEQ),'denoised_imgs')); %LINUX
end
if exist(strcat('val_imgs',SEQ))==7 %If the folder exists
    validation_done = 1;
else
    validation_done = 0;  mkdir(strcat('val_imgs',SEQ)); mkdir(fullfile(strcat('val_imgs',SEQ),'denoised_imgs')); %LINUX
end
if exist(strcat('test_imgs',SEQ))==7 %If the folder exists
    test_done = 1;
else
    test_done = 0;  mkdir(strcat('test_imgs',SEQ)); mkdir(fullfile(strcat('test_imgs',SEQ),'denoised_imgs')); %LINUX
end

%Put the data in folders to later generate the datastore
    if ~training_done
       training_data = unified_dataset(1:round(perc*size(unified_dataset,1)),:); 
       %Data Augmentation for the training data
       %Depending on the sequence we augment more (STEAM) or less (SE)
       switch SEQ
           case 'SE'
              value = 0.8;
           case 'STEAM'
              value = 1.5;
       end
       training_data = augmentation_unet(training_data,12,value);
       %We shuffle again (we don't want all the augmented data at the end!)
        random_sort = randperm(numel(training_data(:,1)));
        training_data = training_data(random_sort,:,:);
        
       dataset2folders(training_data,fullfile(pwd,strcat('training_imgs',SEQ)));  %LINUX      
    end
    if ~validation_done
        validation_data = unified_dataset(round(perc*size(unified_dataset,1)):(size(unified_dataset,1)-ntest),:);
        dataset2folders(validation_data,fullfile(pwd,strcat('val_imgs',SEQ)));  %LINUX   
    end
%     if ~test_done
%         test_data = unified_dataset((size(unified_dataset,1)-ntest+1):size(unified_dataset,1),:);
%         dataset2folders(test_data,fullfile(pwd,strcat('test_imgs',SEQ)));  %LINUX    
%     end
    
%Creation of the datastore objects for the noisy images and the denoised
%ground truth images, that will be entered as input in the Custom Datastore
%creator.

TR_NO_DS = imageDatastore(strcat('training_imgs',SEQ));
TR_DE_DS = imageDatastore(fullfile(strcat('training_imgs',SEQ),'denoised_imgs'));
%TE_NO_DS = imageDatastore(strcat('test_imgs',SEQ));
%TE_DE_DS = imageDatastore(fullfile(strcat('test_imgs',SEQ),'denoised_imgs'));
VA_NO_DS = imageDatastore(strcat('val_imgs',SEQ));
VA_DE_DS = imageDatastore(fullfile(strcat('val_imgs',SEQ),'denoised_imgs'));



end

function training_data = augmentation_unet(training_data, type,augmentation_factor)

%Performs data augmentation on the training dataset to increment it in an augmentation_factor size. 
%This function can either cover mirroring or shearing.

%The new images and denoised images that have been processed are added to
%the dataset. The tag is modified: a new number is added at the end, with
%the type of data augmentation performed (0: nothing,
%1:mirroring,2:shearing)

%Type: 
%1: Mirroring
%2: Shearing
%12: Both 
%3:Rotating
%123: All three

%PREDEFINED VALUES
shear_factor = 10; %Number of pixels of shearing
max_size = size(training_data,1)*(1+augmentation_factor);
angle_rot = 5; %angle of rotation 

original_nimgs = size(training_data,1);

for i=1:original_nimgs
    if numel(num2str(training_data{i,3}))==9
        training_data{i,3} = training_data{i,3}*10;
    end
    
    tag = num2str(training_data{i,3});
    if tag(10)=='0'
        if (type==1 || type==12 || type==123) %Mirroring
            img = training_data{i,1};
            denimg = training_data{i,2};
            training_data = [training_data; {flip(img,2), flip(denimg,2),training_data{i,3}+1}];
        end
        if (type==2 || type==12 || type==123) %Shearing
            img = training_data{i,1};
            denimg = training_data{i,2};    
            transformation_arr = [1 1; size(img,1) 1; round(size(img,1)/shear_factor) size(img,2); size(img,1)-round(size(img,1)/shear_factor) size(img,2)];
            transformation = maketform('projective',[1 1; size(img,1) 2; 1 size(img,2); size(img,1) size(img,2)],transformation_arr);
            shearim = imtransform(img,transformation,'bicubic','udata',[0 1],'vdata',[0 1],'size',size(img),'fill',0);
            shearim_den = imtransform(denimg,transformation,'bicubic','udata',[0 1],'vdata',[0 1],'size',size(img),'fill', 0);
            training_data = [training_data; {shearim, shearim_den,training_data{i,3}+2}];            
        end
        if (type==3 || type==123)%Rotation
            img = training_data{i,1};
            denimg = training_data{i,2};   
            rotim = imrotate(img, angle_rot, 'crop');
            rotim_den = imrotate(denimg,angle_rot,'crop');
            training_data = [training_data; {rotim, rotim_den,training_data{i,3}+3}];               
            
        end
    end
    if size(training_data,1)>= max_size 
       break;
    end
end
end

function dataset2folders(dataset,folder)

%This function reads a dataset of the type "UNET" (create_unet_dataset)
%with the "noisy" image, then the "denoised" one and then the identifying
%tag in the folder specified by filename. 

    for i=1:size(dataset)
%       denoised_folder = fullfile(folder,'denoised_imgs\');
        denoised_folder = fullfile(folder,'denoised_imgs');
        noisy_filename = fullfile(folder,strcat('noisy_',num2str(i),'.png'));
        denoised_filename = fullfile(denoised_folder,strcat('denoised_',num2str(i),'.png'));    
        %Scaling to maintain precision 
        imwrite(dataset{i,1}*2,noisy_filename);
        imwrite(dataset{i,2}*2,denoised_filename);    
    end

end




















