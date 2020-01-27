%register_dataset
%Author: Virginia Fernandez
%MSc Project. Registration
%Original name: register_dataset_v2 (v1 was deleted due to failure)
%Performs a within-sequence and then a cross sequence registration on each
%image
%Arguments:
%Subjects: {subjects}.(phases).sequence.diffusiondata structure. All the
%images must have been processed by process_averaged_matrix, and cropped by
%function crop_dataset, with the original size+additional pixels.
%Type_ref: 1 if we want the reference image to be a b-value = 150 image
%(more SNR), 2 if we want the program to take the first image of the
%dataset
%Upsample: upsampling ratio (set 30 as default)
%Display code: [A,B] array with A: subject that we are interested in
%showing as an example, B: phase that we are interested in showing (1,
%diastole, 2 sweet spot/systole (if healthy/patient), 3 systole (if
%healthy volunteer).
%Output:
%Subjects: registered sturcture (within sequence)
%Subjects: cross-sequence registered structure (preferable)
%movie_SE: Spin-Echo movie of subject A, phase B
%movie_STEAM: STEAM movie of subject A, phase B
%movie_MIXED: movie of all cross-sequence registered SE and STEAM images of all patients for phase
%B. 

function [subjects, subjects_cs, movie_SE, movie_STEAM,movie_MIXED] = register_dataset(subjects,type_ref,upsample,displaycode)  


    %Global parameters
    
    phases = ["diastole", "SS", "systole"];
    chosen_sequence = 2; %STEAM
    additional_pixels = 16; %Pixels that we added in crop_dataset to overcome the translation of dftregistration
    subjects_cs = subjects; %Structure to separate subjects registered by cross-sequence method from the others
    
    try
        subjects_labels = label_subjects();
    catch
        subjects_labels = zeros(120,88,size(subjects)); %WARNING: Image size is directly entered here!
    end

    %Initialisation 
    frame_SE = [];
    frame_STEAM = [];   
    frame_MIXED = [];
    
    for p=1:length(subjects) %Loop over all subjects
     
    frame_MIXED = cat(3,frame_MIXED,subjects_labels(:,:,p)); 
    frame_SE = cat(3,frame_SE,subjects_labels(:,:,p));
    frame_STEAM = cat(3,frame_STEAM,subjects_labels(:,:,p));
    
        name_phases = fieldnames(subjects{p});
        num_phases = size(name_phases,1);
        if (num_phases == 3) subjtype="hs"; elseif (num_phases==2)  subjtype="pat"; end
        
        for ph=1:num_phases %Loop over all phases
            
            %We loop over each sequence
            name_sequences = fieldnames(subjects{p}.(name_phases{ph}));
            num_sequences = size(name_sequences,1);
            average_SE = [];
            average_STEAM = [];
            
            for seq=1:num_sequences 
                diffusiondata = subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata;       
                    try
                        reference_image = find_reference_image(subjtype,diffusiondata,type_ref,p,name_phases{ph},name_sequences{seq});
                    catch
                        %No b=150, we use option 2 (first image)
                         reference_image = find_reference_image(subjtype,diffusiondata,2,p,name_phases{ph},name_sequences{seq});
                    end
                    %To erase the bumps between images of the same sequence, caused by the brightness of
                    %the chest wall, we apply the registration program to a grayscale version of the images. 
                    reference_image_gs = mat2gray(reference_image); 
                    reference_image_gs_chestwall = reference_image_gs(1:round(0.22*size(reference_image_gs,1)),:);
                    reference_image_gs_chestwall =  reference_image_gs_chestwall*0.4;
                    reference_image_gs(1:round(0.22*size(reference_image_gs,1)),:) = reference_image_gs_chestwall;                    
                    reference_image_gs = imadjust(reference_image_gs,[0 0.6]);

                    n_images_averaged = 0;
                    averaged_image = 0;
                    for i=1:size(diffusiondata,2) %Direction
                        for j=1:size(diffusiondata,3) 
                            if ~isempty(diffusiondata{1,i,j})
                                image = diffusiondata{1,i,j}.data;
                                %Registration                              
                                %To erase the bumps between images of the same sequence, caused by the brightness of
                                %the chest wall, we apply the registration program to a grayscale version of the images.
                                image_gs = mat2gray(image); %Grayscale version of the image          
                                
                                %We adjust the dynamic range in the upper part of the image (15%) which corresponds
                                %to the chest wall. 
                                image_gs_chestwall = image_gs(1:round(0.20*size(image_gs,1)),:);
                                image_gs_chestwall =  image_gs_chestwall*0.35;
                                image_gs(1:round(0.20*size(image_gs,1)),:) = image_gs_chestwall;
                                image_gs = imadjust(image_gs,[0 0.4]);
                                [translations,regimg_gs, regimg] = dftregistration(fft2(reference_image_gs),fft2(image_gs),upsample,fft2(image));
                                %Inverse Fourier Transform (result from previous function is Fourier domain)
                                regimg = real(ifft2(regimg)); %Real part (imaginary part is noise coming from fft)
                                
                                %We add the registered image to "subjects" 
                                regimg_c = crop_image(regimg,0,additional_pixels);
                                subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{1,i,j}.data = regimg_c;
                                
                                    %MOVIE DISPLAY. Comment from 86 to 105 for no use. 
                                    if (ph==displaycode)
                                        switch seq %We add the frames to our frame objects for the movie
                                            case 1
                                                if isempty(frame_SE)
                                                    regimg_norm=uint8(mat2gray(regimg_c)*255+1);
                                                    frame_SE = regimg_norm;
                                                else
                                                    regimg_norm=uint8(mat2gray(regimg_c)*255+1);
                                                    frame_SE = cat(3,frame_SE,regimg_norm);
                                                end
                                            case 2
                                                if isempty(frame_STEAM)
                                                    regimg_norm=uint8(mat2gray(regimg_c)*255+1);
                                                    frame_STEAM = regimg_norm;
                                                else
                                                    regimg_norm=uint8(mat2gray(regimg_c)*255+1);
                                                    frame_STEAM = cat(3,frame_STEAM,regimg_norm);
                                                end
                                        end
                                    end
                                %We stack each image
                                averaged_image = averaged_image+regimg;                       
                                n_images_averaged = n_images_averaged + 1;  
                            end
                        end  
                    end
                    %We divide by the total averages to get a "mean" sequence image
                    averaged_image = averaged_image/n_images_averaged; 
                    
                    if seq==1 %If it's SE
                       average_SE = averaged_image; 
                    elseif seq==2 %If it's STEAM
                       average_STEAM = averaged_image; 
                    end                                        
            end %End sequence loop
            
            %We register the averaged STEAM image with the averaged SE
            %We register the averaged SE image with the averaged STEAM
            %Parameter chosen_sequence will define which average will be
            %used for croseq registration.
            
            %Reference: SE; Registered: STEAM
            [trans_croseqSTEAM,reg_STEAM_croseq,reg_STEAM_croseq_TRASH] = dftregistration(fft2(average_SE),fft2(average_STEAM),upsample,fft2(average_STEAM));
            reg_STEAM_croseq = real(ifft2(reg_STEAM_croseq)); %Grayscale conversion neglected here        
            %Reference: STEAM; Registered:SE 
            [trans_croseqSE,reg_SE_croseq,reg_SE_croseq_TRASH] = dftregistration(fft2(average_STEAM),fft2(average_SE),upsample,fft2(average_SE));  
            reg_SE_croseq = real(ifft2(reg_SE_croseq));

            croseq_references = cat(3,reg_SE_croseq,reg_STEAM_croseq);

            %We reloop over each sequence and register each image from a sequence with the registered averaged from the other. 
            
            %CROSS SEQUENCE REGISTRATION (COMMENT FROM 139 TO 192 IF NOT REQUIRED)
            for seq=1:num_sequences
                %Already registered images (intra-sequence registration has been performed)
                
                reference_image_gs = mat2gray(croseq_references(:,:,chosen_sequence)); 
                reference_image_gs_chestwall = reference_image_gs(1:round(0.22*size(reference_image_gs,1)),:);
                reference_image_gs_chestwall =  reference_image_gs_chestwall*0.4;
                reference_image_gs(1:round(0.22*size(reference_image_gs,1)),:) = reference_image_gs_chestwall;                    
                reference_image_gs = imadjust(reference_image_gs,[0 0.6]);
                
                diffusiondata = subjects_cs{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata;       
                for i=1:size(diffusiondata,2) %Direction
                        for j=1:size(diffusiondata,3) 
                            ap = additional_pixels; %Additional pixels to crop
                            if ~isempty(diffusiondata{1,i,j})
                                image = diffusiondata{1,i,j}.data; 
                                
                                image_gs = mat2gray(image); %Grayscale version of the image
                                %We lower the intensity in the upper part of the image (15%) which corresponds
                                %to the chest wall. 
                                image_gs_chestwall = image_gs(1:round(0.15*size(image_gs,1)),:);
                                image_gs_chestwall =  image_gs_chestwall*0.4;
                                image_gs(1:round(0.15*size(image_gs,1)),:) = image_gs_chestwall;
            
                                %We adjust the dynamic range of the image
                                image_gs = imadjust(image_gs,[0 0.4]);                                
                                                                
                                %We register the image with the registered averaged image chosen 
                                [translations,regimg_trash,regimg] = dftregistration(fft2(reference_image_gs),fft2(image_gs),upsample,fft2(image));
                                % (Grayscale conversion here is neglected)
                                regimg = real(ifft2(regimg)); %Real part (imaginary part is noise coming from fft)
                                %Image needs to be cropped to match the number of original pixels and remove translation band 
                                regimg = crop_image(regimg,0,ap);
                                subjects_cs{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{1,i,j}.data = regimg;
                                    %MOVIE DISPLAY. Comment from 173 to 183 for no use. 
                                    %Adds the cross-sequence registered images to the movies
                                    if  ph==displaycode
                                        switch seq
                                               case 1
                                                    regimg_norm=uint8(mat2gray(regimg)*255+1);
                                                    frame_MIXED = cat(3,frame_MIXED,regimg_norm);
                                                case 2
                                                    regimg_norm=uint8(mat2gray(regimg)*255+1);
                                                    frame_MIXED = cat(3,frame_MIXED,regimg_norm);                                            
                                        end
                                    end
                            end
                        end  
                end                              
            end %End sequence loop   
        end  %End phases loop 
    end %End subject loop 
   
    %MOVIE DISPLAY: Comment between 192 and 194 for no use. 
    movie_SE = immovie(reshape(frame_SE,[size(frame_SE,1),size(frame_SE,2),1,size(frame_SE,3)]),gray(256));
    movie_STEAM = immovie(reshape(frame_STEAM,[size(frame_STEAM,1),size(frame_STEAM,2),1,size(frame_STEAM,3)]),gray(256));
    movie_MIXED = immovie(reshape(frame_MIXED,[size(frame_MIXED,1),size(frame_MIXED,2),1,size(frame_MIXED,3)]),gray(256));
end

function reference_image = find_reference_image(subjtype,diffusiondata,type_ref,subj,phase,sequence)
    
   %This function fetches a reference image for registration, for a
   %specific subject and phase.
   %It returns the reference image, and saves a normalised copy in folder
   %"references_for_registration".
   
   %Arguments:
   %subjtype: pat/hs (patient or healthy subject). Relevant for name of
   %saved file only
   %subjects: structure with the images
   %type_ref: 1 or 2 if we want a SE/STEAM b=150 image, 3 and 4 if the want
   %the first SE/STEAM image
   %subj: subject index
   %phase: phase in question (string)
   
   if ~(exist('references_for_registration')==7) %If the folder exists
       mkdir('references_for_registration');
   end

    %We loop over the subjects structure to fetch the image.
    
    switch type_ref     
        case 1
            for i=1:size(diffusiondata,2)
                for j=1:size(diffusiondata,3)
                    if ~isempty(diffusiondata{1,i,j})
                        if diffusiondata{1,i,j}.b_pres == 150
                            reference_image = diffusiondata{1,i,j}.data;
                            name_image = strcat(subjtype,int2str(subj),"_",phase,"_",sequence,'.jpg');
                            %Save reference images: Comment from 189 to 192 for no use
                            %Normalise image to be able to save it
%                             img = reference_image - min(reference_image(:));
%                             img = img/max(reference_image(:));
%                             imwrite(img, fullfile('references_for_registration',name_image),'jpg');
                            break;
                        end
                    end
                end
            end  
         case 2
           for i=1:size(diffusiondata,2)
                for j=1:size(diffusiondata,3)
                    if ~isempty(diffusiondata{1,i,j})
                        reference_image = diffusiondata{1,i,j}.data;
                        name_image = strcat(subjtype,int2str(subj),"_",phase,"_",sequence,'.jpg');
                        %Save reference images: Comment from 205 to 207 for no use
                        %Normalise image to be able to save it
%                         img = reference_image - min(reference_image(:));
%                         img = img/max(reference_image(:));
%                         imwrite(img, fullfile('references_for_registration',name_image),'jpg');
                        break;
                    end
                end
            end
    end   
end



function img = crop_image(img,c_x,c_y)

%Removes pixels from above/down - left/right of image (amount: c_x or c_y)
%Convention: Above: Negative, Down: Positive; Left: Negative, Right:
%Positive
   %X CROP
    if c_x<0
        c_x = abs(c_x);
        img = img(:,c_x:size(img,2));
    elseif c_x>0
        img = img(:,1:(size(img,2)-c_x));
    end
    %Y CROP
    if c_y<0
       c_y = abs(c_y);
       img = img((c_y+1):size(img,1),:);
    elseif c_y>0
       img = img(1:(size(img,1)-c_y),:);
    end
end

function label_subjects = label_subjects()

    %Patient frames (comment out of debugging mode)
    P1 = imread('P1.png'); P1 = rgb2gray(P1); 
    P2 = imread('P2.png'); P2 = rgb2gray(P2); 
    P3 = imread('P3.png'); P3 = rgb2gray(P3); 
    P4 = imread('P4.png'); P4 = rgb2gray(P4);
    P5 = imread('P5.png'); P5 = rgb2gray(P5);
    P6 = imread('P6.png'); P6 = rgb2gray(P6); 
    P7 = imread('P7.png'); P7 = rgb2gray(P7); 
    P8 = imread('P8.png'); P8 = rgb2gray(P8); 
    P9 = imread('P9.png'); P9 = rgb2gray(P9); 
    P10 = imread('P10.png'); P10 = rgb2gray(P10); 
    P11 = imread('P11.png'); P11 = rgb2gray(P11); 
    P12 = imread('P12.png'); P12 = rgb2gray(P12);    
    P13 = imread('P13.png'); P13 = rgb2gray(P13); 
    P14 = imread('P14.png'); P14 = rgb2gray(P14); 
    P15 = imread('P15.png'); P15 = rgb2gray(P15); 
    
    label_subjects = cat(3,P1,P2,P3,P4,P5,P6,P7,P8,P9,P10,P11,P12,P13,P14,P15);    

end

function [max,min] = extract_extremes(dataset)

%Extracts the maximum and minimum intensities from a the
%(patient,phase,sequence) diffusion data dataset.
%Necessary to keep the consistent intensities between b150 and b450 images.

    max = 0;
    min = 500; 
    for i=1:size(dataset,2)
        for j=1:size(dataset,3)
            image = dataset{1,i,j}.data;
            max_i = max(image(:));
            min_i = min(image(:));
            if max<max_i
                max = max_i;
            end
            if min>min_i
                min = min_i;
            end
        end   
    end    
end