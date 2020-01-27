function [dataset150,dataset450] = create_unet_dataset(subjects,denoised150,denoised450)

%This function generates a dataset of N images and their respective
%denoised image.
%It differentiates between the BREF = 450 and the BREF = 150 images.
%Just in case, a third column contains a string identifying the image:
%HS/PA_SY/SS/DI_SE/STEAM_DIR1/2/3/4/5/6_N1/2...N. 

%Global parameters
directions = [0,1,2,3,4,5,6]; %The first one is the b0, and we want direction 1 to be the first actual direction.
subtype = ""; %Either patient or subject

%Dataset raw
dataset150 = {};
dataset450 = {};

    for p=1:length(subjects) %Loop over each patient
        name_phases = fieldnames(subjects{p});
        num_phases = size(name_phases,1);
        if num_phases ==3 subtype = "HS"; else subtype = "PA"; end
        
        for ph=1:num_phases %Loop over each phase 
            name_sequences = fieldnames(subjects{p}.(name_phases{ph}));
            num_sequences = size(name_sequences,1);
            
            for seq=1:num_sequences %Loop over each sequence
                
                diffusiondata = subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata;
                
                for i=2:size(diffusiondata,2) %Loop over each direction 
                    for j=1:size(diffusiondata,3) %Loop over each image
                        
                        if(~isempty(diffusiondata{1,i,j}))
                            img = diffusiondata{1,i,j}.data;
                            tag = diffusiondata{1,i,j}.tag;

                            %We extract the identity of our image
                            [type,subject_no,phase,sequence,direction,b_ref,average_no] = process_tag(tag);
                           
                            switch b_ref
                                case 150
                                      den_img = denoised150{p}.(phase).(name_sequences{seq}).diffusiondata{average_no,direction}.im;
                                      dataset150 = [dataset150;cell(1,3)]; 
                                      dataset150{size(dataset150,1),1}= img; %Our "noisy" image
                                      dataset150{size(dataset150,1),2}= den_img; %Denoised image
                                      dataset150{size(dataset150,1),3}= tag;
                                case 450
                                    %HEEERE (PROBABLY EMPTY)
                                    den_img = denoised450{p}.(phase).(name_sequences{seq}).diffusiondata{average_no,direction}.im;
                                    %disp(strcat(int2str(p),int2str(ph),int2str(seq),int2str(i),int2str(j)));
                                      dataset450 = [dataset450;cell(1,3)]; 
                                      dataset450{size(dataset450,1),1}= img; %Our "noisy" image
                                      dataset450{size(dataset450,1),2}= den_img; %Denoised image
                                      dataset450{size(dataset450,1),3}= tag;
                            end
                        end                 
                    end        
                end
            end
        end
    end
end



