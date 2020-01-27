function [datasetSE,datasetSTEAM] = create_sequence_dataset(subjects,denoised150,denoised450)

%This function generates a dataset of N images and their respective
%denoised image.
%It differentiates between the SE and STEAM images. 
%Just in case, a third column contains a string identifying the image:
%HS/PA_SY/SS/DI_SE/STEAM_DIR1/2/3/4/5/6_B1(150)/2(450)_N1/2...N. 


%Global parameters
directions = [0,1,2,3,4,5,6]; %The first one is the b0, and we want direction 1 to be the first actual direction.
subtype = ""; %Either patient or subject

%Dataset raw
datasetSE = {};
datasetSTEAM = {};

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
                                den_img = denoised150{subject_no}.(phase).(name_sequences{seq}).diffusiondata{average_no,direction}.im;
                                switch seq
                                    case 1 %SE
                                      datasetSE = [datasetSE;cell(1,3)]; 
                                      datasetSE{size(datasetSE,1),1}= img; %Our "noisy" image
                                      datasetSE{size(datasetSE,1),2}= den_img; %Denoised image
                                      datasetSE{size(datasetSE,1),3}= tag;
                                    case 2 %STEAM
                                      datasetSTEAM = [datasetSTEAM;cell(1,3)]; 
                                      datasetSTEAM{size(datasetSTEAM,1),1}= img; %Our "noisy" image
                                      datasetSTEAM{size(datasetSTEAM,1),2}= den_img; %Denoised image
                                      datasetSTEAM{size(datasetSTEAM,1),3}= tag;
                                 end
                                    case 450
                                        den_img = denoised450{subject_no}.(phase).(name_sequences{seq}).diffusiondata{average_no,direction}.im;
                                        switch seq
                                            case 1 %SE
                                              datasetSE = [datasetSE;cell(1,3)]; 
                                              datasetSE{size(datasetSE,1),1}= img; %Our "noisy" image
                                              datasetSE{size(datasetSE,1),2}= den_img; %Denoised image
                                              datasetSE{size(datasetSE,1),3}= tag;
                                            case 2 %STEAM
                                              datasetSTEAM = [datasetSTEAM;cell(1,3)]; 
                                              datasetSTEAM{size(datasetSTEAM,1),1}= img; %Our "noisy" image
                                              datasetSTEAM{size(datasetSTEAM,1),2}= den_img; %Denoised image
                                              datasetSTEAM{size(datasetSTEAM,1),3}= tag;
                                        end
                                end
                        end                 
                    end        
             end 
           end
        end
    end
end


