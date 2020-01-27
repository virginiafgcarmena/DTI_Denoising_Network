function [subjects, av_images450, av_images150] = process_average_matrix(subjects,type)

%Input: subjects (structure coming from readaset_Virginia)
%Output: subjects (with "bad" images deleted, according to the average
%matrix)
%Average Matrices: denoised dataset _DENOISED_150 or _DENOISED_450
%Type: 1 if patient, 2 if healthy (to save the tags necessary for the unet
%dataset)

%Parameters
averaged_index = 2; %The number of averages that will be extracted
av_images450 = cell(1,length(subjects));
av_images150 = cell(1,length(subjects));

%Subject numbers for which we have at least one average per direction,
%phase and sequence in the 450 case.
valid_subs = [];

for p=1:length(subjects) %We loop accross all patients
    %Validity measure for each subject. If no average is found for a phase,
    %sequence, direction triplet, it becomes 0
    valid_tag = 1;
    valid_tag_1150 = 1;
                
    total_150 = 0; %Number of b=150 images we have
    
    av_images450{p} = struct;
    av_images150{p} = struct; 
    
    name_phases = fieldnames(subjects{p});
    num_phases = size(name_phases,1);
    
    for ph=1:num_phases %We loop accross the number of sequences
        av_images450{p}.(name_phases{ph}) = struct;
        av_images150{p}.(name_phases{ph}) = struct;    
        
        name_sequences = fieldnames(subjects{p}.(name_phases{ph}));
        num_sequences = size(name_sequences,1);
        
        for seq=1:num_sequences %We loop accross the number of sequences
            avmat = subjects{p}.(name_phases{ph}).(name_sequences{seq}).averagematrix;
            diffd = subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata;
            av_images450{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata = cell(1,size(diffd,2));
            av_images450{p}.(name_phases{ph}).(name_sequences{seq}).cropinfo = subjects{p}.(name_phases{ph}).(name_sequences{seq}).cropinfo;
            av_images150{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata = cell(1,size(diffd,2));  
            av_images150{p}.(name_phases{ph}).(name_sequences{seq}).cropinfo = subjects{p}.(name_phases{ph}).(name_sequences{seq}).cropinfo;
            
            %Counter: if the image is [96,256] instead of [256,96], we need
            %to "crop" cropinfo ONCE per (SUBJECT,PHASE,SEQUENCE). We check
            %the size for non-empty images, so this counter is necessary:
            %cropinfo will only be updated the FIRST time
            
            cropped_counter = 0;
            
            %Check valid images and empty diffusion_data of images labelled
            %with 0 and b0 images
            
            for i=1:size(diffd,2)    %Loop accross directions                     
              
            n_450 = [];
            n_150 = [];
            
            %STEP 1: Note down the number of 450, 150 images. Empty data
            %with b = 5 or b = 11.141 (b0)
            
                for j=1:size(diffd,3) %Loop accoss averages
                  if ~isempty(diffd{1,i,j})
                    %NEW
                    [sy,sx] = size(subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{1,i,j}.data);   
                    %NEW
                    switch diffd{1,i,j}.b_pres %450, 150 or b0?
                        case 450
                           if avmat(i,j)==1
                            n_450 = [n_450,j];
                  
                            if (sy<sx) %If image is horizontal, we rotate it and rotate cropinfo
                               image = subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{1,i,j}.data;
                               image = imrotate(image,90);
                               subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{1,i,j}.data = image;
                               if (cropped_counter==0) %If this is the first image we crop
                                    cropinfo = subjects{p}.(name_phases{ph}).(name_sequences{seq}).cropinfo;
                                    %We must have the X (Matlab's 'Y') first,
                                    %then the Y. First element of the box, then
                                    %width and height
                                    if (cropinfo(1)>40)  %In some cases (patient 9), cropinfo is fine even though the image is rotated. Control code line                                   
                                        cropinfo = [cropinfo(2),(sx-cropinfo(1))-cropinfo(3),cropinfo(4),cropinfo(3)];
                                        subjects{p}.(name_phases{ph}).(name_sequences{seq}).cropinfo = cropinfo;
                                        av_images450{p}.(name_phases{ph}).(name_sequences{seq}).cropinfo = cropinfo;
                                        av_images150{p}.(name_phases{ph}).(name_sequences{seq}).cropinfo = cropinfo;
                                        cropped_counter=cropped_counter+1;
                                        
                                    end
                               end
                            end
                            %NEW
                           else
                            subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{1,i,j} = [];
                           end
                        case 150
                           if avmat(i,j)==1
                            n_150 = [n_150,j];    
                            if (sy<sx) %If image is horizontal, we rotate it and rotate cropinfo
                               image = subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{1,i,j}.data;
                               image = imrotate(image,90);
                               subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{1,i,j}.data = image;
                               if (cropped_counter==0) %If this is the first image we crop
                                    cropinfo = subjects{p}.(name_phases{ph}).(name_sequences{seq}).cropinfo;
                                    %We must have the X (Matlab's 'Y') first,
                                    %then the Y. First element of the box, then
                                    %width and height
                                    if (cropinfo(1)>40)  %In some cases (patient 9), cropinfo is fine even though the image is rotated. Control code line                                   
                                        cropinfo = [cropinfo(2),cropinfo(1),cropinfo(4),cropinfo(3)];
                                        subjects{p}.(name_phases{ph}).(name_sequences{seq}).cropinfo = cropinfo;
                                        av_images450{p}.(name_phases{ph}).(name_sequences{seq}).cropinfo = cropinfo;
                                        av_images150{p}.(name_phases{ph}).(name_sequences{seq}).cropinfo = cropinfo;
                                        cropped_counter=cropped_counter+1;
                                    end
                               end
                             end                            
                           else %Wrong according to average_matrix
                            subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{1,i,j} = [];   
                           end
                        otherwise %For b0 cases, we empty the cells
                           subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{1,i,j} = [];
                    end
                  end
                end
                
                %In this section, we store the denoised images
                %We need to redefine diffd because images might have been
                %rotated in case they're inverted 
                
                diffd_corr = subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata;
                counter_450 = 0; 
                bref = 2;
                tag_last_image = 0;
                %n_images = floor(length(n_450)/averaged_index); 
                if length(n_450)>=averaged_index
                    n_images = ceil(length(n_450)/averaged_index); %Sliding window method
                    tag_last_image = mod(length(n_450),averaged_index);
                    if tag_last_image==averaged_index tag_last_image=0; end;
                else
                    n_images = 0;
                end
                counter_image = 1;  
                
                %Validity tag (at least one direction has no average)
                if (n_images==0)&&(i~=1) valid_tag=0; end
                
                %We take care of the 450 images
                for a=1:length(n_450)                   
                    if length(n_450)>= averaged_index
                       if counter_450 ==averaged_index %Last item of one image has just passed
                          counter_450 = 0;
                          counter_image = counter_image+1;
                       end
                       if (counter_450 == 0) %If we are on one first item of one average
                            if counter_image==1
                                %i-1 is because the first row is always b0!
                                av_images450{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.im = diffd_corr{1,i,n_450(a)}.data;
                                av_images450{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.tag = type*10e7+10e5*p+10e4*ph+10e3*seq+i*10e2+bref*10e1+counter_image;
                            else
                                %New image implies new row!
                                if (size(av_images450{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata,1)<counter_image)
                                    %We add a new row 
                                    av_images450{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata = vertcat(av_images450{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata,cell(1,size(diffd_corr,2)));
                                end
                                av_images450{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.im = diffd_corr{1,i,n_450(a)}.data;
                                av_images450{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.tag = type*10e7+10e5*p+10e4*ph+10e3*seq+i*10e2+bref*10e1+counter_image;
                            end                            
                       else %If we are on another item
                            av_images450{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.im = av_images450{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.im+diffd_corr{1,i,n_450(a)}.data;
                       end
                       
                       counter_450 = counter_450+1;
                       %Last image-case 
                       if ((n_images==counter_image)&&(tag_last_image~=0)&&((counter_450)==mod(length(n_450),averaged_index))) %Sliding window method        
                            while (averaged_index-tag_last_image)>0 %We add the remaining images to complete an averaged_index package 
                                  av_images450{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.im = av_images450{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.im+diffd_corr{1,i,n_450(a-tag_last_image)}.data;
                                  tag_last_image = tag_last_image+1;
                                  counter_450=counter_450+1;
                            end    
                       end
                       
                       subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{1,i,n_450(a)}.tag = type*10e7+10e5*p+10e4*ph+10e3*seq+i*10e2+bref*10e1+counter_image;
                       if (counter_450==averaged_index) %We normalize, dividing by average_index 
                           av_images450{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.im= av_images450{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.im./averaged_index; 
                       end
                    else
                        %If there are not enough images for the average, we
                        %abort  
                        subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{1,i,n_450(a)} = [];                
                    end
                end 
                
                counter_150 = 0; 
                bref=1;
                %n_images = floor(length(n_450)/averaged_index); 
                tag_last_image = 0;
                if length(n_150)>=averaged_index
                    n_images = ceil(length(n_150)/averaged_index); %Sliding window method
                    tag_last_image = averaged_index-mod(length(n_150),averaged_index);
                    if tag_last_image==averaged_index tag_last_image=0; end;
                else
                    n_images = 0;
                end
                if (isempty(n_150)&&(i~=1)) valid_tag_1150=0; end
                total_150 = total_150+n_images;
                counter_image = 1;                
                for a=1:length(n_150)                   
                    if length(n_150)>= averaged_index
                       if counter_150 ==averaged_index %Last item of one image has just passed
                          counter_150 = 0;
                          counter_image = counter_image+1;
                       end
                       if (counter_150 == 0) %If we are on one first item of one average
                            if counter_image==1
                                %i-1 is because the first row is always b0!
                                av_images150{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.im = diffd_corr{1,i,n_150(a)}.data;
                                av_images150{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.tag = type*10e7+10e5*p+10e4*ph+10e3*seq+i*10e2+bref*10e1+counter_image;
                            else
                                %New image implies new row!
                                if (size(av_images150{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata,1)<counter_image)
                                    %We add a new row 
                                    av_images150{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata = vertcat(av_images150{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata,cell(1,size(diffd_corr,2)));
                                end
                                av_images150{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.im = diffd_corr{1,i,n_150(a)}.data;
                                av_images150{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.tag = type*10e7+10e5*p+10e4*ph+10e3*seq+i*10e2+bref*10e1+counter_image;
                            end                            
                       else %If we are on another item
                            av_images150{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.im = av_images150{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.im+diffd_corr{1,i,n_150(a)}.data;
                       end
                       
                       counter_150 = counter_150+1;
                       %Last image-case 
                       if ((n_images==counter_image)&&(tag_last_image~=0)&&((counter_150)==mod(length(n_150),averaged_index))) %Sliding window method        
                            while (averaged_index-tag_last_image)>0 %We add the remaining images to complete an averaged_index package 
                                  av_images150{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.im = av_images150{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.im+diffd_corr{1,i,n_150(a-tag_last_image)}.data;
                                  tag_last_image = tag_last_image+1;
                                  counter_150=counter_150+1;
                            end    
                       end
                       
                       subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{1,i,n_150(a)}.tag = type*10e7+10e5*p+10e4*ph+10e3*seq+i*10e2+bref*10e1+counter_image;
                       if (counter_150==averaged_index) %We normalize, dividing by average_index 
                           av_images150{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.im= av_images150{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{counter_image,i}.im./averaged_index; 
                       end
                    else
                        %If there are not enough images for the average, we
                        %abort  
                        subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{1,i,n_150(a)} = [];                
                    end
                end 
            end  
        end        
    end
    disp(strcat("Subject ",int2str(p)," has ",int2str(total_150)," 150-images"));
    if (valid_tag==1)&&(valid_tag_1150==1) valid_subs = [valid_subs p]; end
end

disp(strcat("Valid subjects: ", int2str(valid_subs)));
end