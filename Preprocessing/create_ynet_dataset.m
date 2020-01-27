%create_ynet_dataset
%Generates 4 Nx3 datasets for the SE,STEAM:SE and STEAM,SE:STEAM Y-NETS
%based on the denoised outputs of process_average_matrix and the
%clean-registered outputs (noisy) of the same.
%Arguments: 150, 450 denoised and noisy outputs of process_average_matrix 
%Outputs: Nx3 datasets with the 1st column: 120x88x3 image with the main
%sequence in the first channel, the auxiliary sequence in the second and
%zeroes in the last, and the denoised main sequence in the second column.
%Third column is the tag.

function [dataset_150_YSE,dataset_450_YSE,dataset_150_YSTEAM,dataset_450_YSTEAM] = create_ynet_dataset(subjects,denoised150,denoised450)

dataset_150_YSE = {};
dataset_450_YSE = {};
dataset_150_YSTEAM = {};
dataset_450_YSTEAM = {};

for p=1:length(subjects)   
    name_phases = fieldnames(subjects{p});
    num_phases = size(name_phases,1);       
     for ph=1:num_phases %Loop over each phase  
        name_sequences = {"SE","STEAM"};
        num_sequences = size(name_sequences,1);       
        for seq=1:num_sequences %Loop over each sequence       
             diffusiondata = subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata; 
             
             switch name_sequences{seq}
                 case "SE"
                     %SE images go in the first channel of the image in the
                     %YSE dataset, and on the second in the YSTEAM dataset.   
                     nonnullSTEAMdirections = checkDiffusiondataEmptiness(subjects{p}.(name_phases{ph}).STEAM.diffusiondata);
                     
                     for i=2:size(diffusiondata,2) %Loop over each direction 
                            number_of_STEAM = size(subjects{p}.(name_phases{ph}).STEAM.diffusiondata,3); %Number of averages in a STEAM dd. 
                            counter_STEAM = 1;
                 
                            for j=1:size(diffusiondata,3) %Loop over each image 
                                if((~isempty(diffusiondata{1,i,j}))&&nonnullSTEAMdirections(i,1)) %If there are no STEAM images we can't do this either!     
                                    tag = diffusiondata{1,i,j}.tag;  
                                               
                                    %Images that will go into the structure
                                    img_SE = zeros([size(diffusiondata{1,i,j}.data),3]); %"RGB" image, fake 3-channel image with the SE image on the 1st channel 
                                    img_STEAM = zeros([size(diffusiondata{1,i,j}.data),3]); %"RGB" image, fake 3-channel image with the SE image on the 2d channel 
                                    
                                    %Put the original SE images into the images for the SE and the STEAM channel
                                    img_SE(:,:,1) = diffusiondata{1,i,j}.data; %Spin-Echo image (goes to the YSE)
                                    img_STEAM(:,:,2)= diffusiondata{1,i,j}.data; %STEAM image (goes to the YSTEAM)
                                    
                                    %Put the original SE images into the images for the SE and the STEAM channel
                                    
                                    %If it's empty, we go to the next
                                    while (isempty(subjects{p}.(name_phases{ph}).STEAM.diffusiondata{1,i,counter_STEAM}))
                                        counter_STEAM = counter_STEAM+1; 
                                        if counter_STEAM>=number_of_STEAM
                                            counter_STEAM=1;
                                        end
                                    end
                                   
                                    img_SE(:,:,2) = subjects{p}.(name_phases{ph}).STEAM.diffusiondata{1,i,counter_STEAM}.data; %Spin-Echo image (goes to the YSE)
                                    img_STEAM(:,:,1)= subjects{p}.(name_phases{ph}).STEAM.diffusiondata{1,i,counter_STEAM}.data; %STEAM image (goes to the YSTEAM)
                                    
                                    %TAG
                                    [type,subject_no,phase,sequence,direction,b_ref,average_no] = process_tag(tag);
                                    tagSTEAM = subjects{p}.(name_phases{ph}).STEAM.diffusiondata{1,i,counter_STEAM}.tag;
                                    [typeST,subject_noST,phaseST,sequenceST,directionST,b_refST,average_noST] = process_tag(tagSTEAM);                                    
                                    
                                    %Modify 
                                    counter_STEAM = counter_STEAM+1; 
                                    if counter_STEAM>=number_of_STEAM
                                        counter_STEAM=1;
                                    end

                                   %Non Null directions for denoised 150 and 450
                                    nonNullSTEAMdirections_dn150 = checkDiffusiondataEmptinessDenoised(denoised150{subject_no}.(phase).STEAM.diffusiondata);
                                    nonNullSTEAMdirections_dn450 = checkDiffusiondataEmptinessDenoised(denoised450{subject_no}.(phase).STEAM.diffusiondata);
                                                             
                                    switch b_ref
                                           case 150
                                             if (nonNullSTEAMdirections_dn150(direction,1)) 
                                                den_img_SE = denoised150{subject_no}.(phase).SE.diffusiondata{average_no,direction}.im;
                                                den_img_STEAM = denoised150{subject_no}.(phase).STEAM.diffusiondata{average_noST,direction}.im;
                                                
                                                %3 Channel conversion
%                                                 den_img_SE = cat(3,den_img_SE,zeros(size(den_img_SE)),zeros(size(den_img_SE)));
%                                                 den_img_STEAM = cat(3,den_img_STEAM,zeros(size(den_img_STEAM)),zeros(size(den_img_STEAM)));
                                                
                                                %Add the other image in the channel
                                                dataset_150_YSE = [dataset_150_YSE;cell(1,3)]; 
                                                dataset_150_YSE{size(dataset_150_YSE,1),1}= img_SE; %Our "noisy" image
                                                dataset_150_YSE{size(dataset_150_YSE,1),2}= den_img_SE; %Denoised image
                                                
                                                dataset_150_YSTEAM = [dataset_150_YSTEAM;cell(1,3)]; 
                                                dataset_150_YSTEAM{size(dataset_150_YSTEAM,1),1}= img_STEAM; %Our "noisy" image
                                                dataset_150_YSTEAM{size(dataset_150_YSTEAM,1),2}= den_img_STEAM; %Denoised image    
                                                
                                                %Add th eaverage of the other image to the tag
                                                dataset_150_YSE{size(dataset_150_YSE,1),3}= tag;
                                                dataset_150_YSTEAM{size(dataset_150_YSTEAM,1),3}= tagSTEAM;
                                             end 
                                           case 450
                                               if (nonNullSTEAMdirections_dn450(direction,1)) 
                                                den_img_SE = denoised450{subject_no}.(phase).SE.diffusiondata{average_no,direction}.im;
                                                den_img_STEAM = denoised450{subject_no}.(phase).STEAM.diffusiondata{average_noST,direction}.im;
                                                
                                                %3 Channel conversion
%                                                 den_img_SE = cat(3,den_img_SE,zeros(size(den_img_SE)),zeros(size(den_img_SE)));
%                                                 den_img_STEAM = cat(3,den_img_STEAM,zeros(size(den_img_STEAM)),zeros(size(den_img_STEAM)));
                                                
                                                %Add the other image in the channel
                                                dataset_450_YSE = [dataset_450_YSE;cell(1,3)]; 
                                                dataset_450_YSE{size(dataset_450_YSE,1),1}= img_SE; %Our "noisy" image
                                                dataset_450_YSE{size(dataset_450_YSE,1),2}= den_img_SE; %Denoised image
                                                
                                                dataset_450_YSTEAM = [dataset_450_YSTEAM;cell(1,3)]; 
                                                dataset_450_YSTEAM{size(dataset_450_YSTEAM,1),1}= img_STEAM; %Our "noisy" image
                                                dataset_450_YSTEAM{size(dataset_450_YSTEAM,1),2}= den_img_STEAM; %Denoised image    
                                                
                                                %Add th eaverage of the other image to the tag
                                                dataset_450_YSE{size(dataset_450_YSE,1),3}= tag;
                                                dataset_450_YSTEAM{size(dataset_450_YSTEAM,1),3}= tagSTEAM;
                                               end  
                                    end   
                                end

                                %Assign denoised, either SE or STEAM (with a case)
                            end
                     end
                 case "STEAM"
                 continue;   
             end
        end
     end  
end

end


function out = checkDiffusiondataEmptiness(diffusiondata)
%For diffusion data (not denoised)
out = zeros(size(diffusiondata,2),1); %Number of directions
for i=1:size(diffusiondata,2)
    for j=1:size(diffusiondata,3)
        if ~isempty(diffusiondata{1,i,j})
            out(i,1)=1;
        end
    end
end

end

function out = checkDiffusiondataEmptinessDenoised(diffusiondata)
%For diffusion data (denoised structures)
out = zeros(size(diffusiondata,2),1); %Number of directions
for i=1:size(diffusiondata,2)
    for j=1:size(diffusiondata,1)
        if ~isempty(diffusiondata{j,i})
            out(i,1)=1;
        end
    end
end

end