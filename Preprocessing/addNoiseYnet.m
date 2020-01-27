function [dataset_YSE, dataset_YSTEAM] = addNoiseYnet(denoised, rangn)

%Sigma MIN and Sigma MAX are the maximum and minimum standard deviations
%applied to the Gaussian noise generation. Values too high might remove any
%meaning to the image, so beware!

sigmin = 0.00001;
sigmax = 0.001;
noises = [sigmin:(sigmax-sigmin)/rangn:sigmax-(sigmax-sigmin)/rangn];

dataset_YSE = {};
dataset_YSTEAM = {};

for p=1:length(denoised)
    name_phases = fieldnames(denoised{p});
    num_phases = size(name_phases,1);
    for ph=1:num_phases %Loop over each phase
        name_sequences = {"SE","STEAM"};
        num_sequences = size(name_sequences,1);
        for seq=1:num_sequences %Loop over each sequence
            diffusiondata = denoised{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata;
            switch name_sequences{seq}
                case "SE"
                    %SE images go in the first channel of the image in the
                    %YSE dataset, and on the second in the YSTEAM dataset.
                    %%CHECK THIS
                    for i=2:size(diffusiondata,2) %Loop over each direction
                        number_of_STEAM = size(denoised{p}.(name_phases{ph}).STEAM.diffusiondata,1); %Number of averages in a STEAM denoised dataset.
                        counter_STEAM = 1;
                        nonNullSTEAM = checkDiffusiondataEmptinessDenoised(denoised{p}.(name_phases{ph}).STEAM.diffusiondata);
                        for j=1:size(diffusiondata,1) %Loop over each average
                            if((~isempty(diffusiondata{j,i}))&&nonNullSTEAM(i,1)) %If there are no STEAM images we can't do this either!
                                tag = diffusiondata{j,i}.tag;
                                %Images that will go into the structure
                                img_SE = single(zeros([size(diffusiondata{j,i}.im),3])); %"RGB" image, fake 3-channel image with the SE image on the 1st channel
                                img_STEAM = single(zeros([size(diffusiondata{j,i}.im),3])); %"RGB" image, fake 3-channel image with the SE image on the 2d channel
                                %Put the original SE images into the images for the SE and the STEAM channel
                                img_SE(:,:,1) = diffusiondata{j,i}.im; %Spin-Echo image (goes to the YSE)
                                img_STEAM(:,:,2)= diffusiondata{j,i}.im; %STEAM image (goes to the YSTEAM)
                                
                                %Put the original SE images into the images for the SE and the STEAM channel
                                %If it's empty, we go to the next
                                while (isempty(denoised{p}.(name_phases{ph}).STEAM.diffusiondata{counter_STEAM,i}))
                                    counter_STEAM = counter_STEAM+1;
                                    if counter_STEAM>=number_of_STEAM
                                        counter_STEAM=1;
                                    end
                                end
                                
                                img_SE(:,:,2) = denoised{p}.(name_phases{ph}).STEAM.diffusiondata{1,i,counter_STEAM}.im; %Spin-Echo image (goes to the YSE)
                                img_STEAM(:,:,1)= denoised{p}.(name_phases{ph}).STEAM.diffusiondata{1,i,counter_STEAM}.im; %STEAM image (goes to the YSTEAM)
                                tagSTEAM = denoised{p}.(name_phases{ph}).STEAM.diffusiondata{1,i,counter_STEAM}.tag;
                                
                                [min_SE, max_SE] = findExtremes(diffusiondata);
                                [min_STEAM,max_STEAM] = findExtremes(denoised{p}.(name_phases{ph}).STEAM.diffusiondata);
                                
                                for n=1:length(noises)
                                    base_SE = single(img_SE(:,:,1));
                                    base_SE = (base_SE-min([min_SE,0]))/(max_SE-min([min_SE,0]));
                                    base_SE(base_SE<0)=0;
                                    denoised_SE = base_SE;                                   
                                    base_SE = imnoise(base_SE,'gaussian',0,noises(n));
                                    base_SE = base_SE*(max_SE-min([min_SE,0]))+min([min_SE,0]);
                                    denoised_SE = denoised_SE*(max_SE-min([min_SE,0]))+min([min_SE,0]);
                                    
                                    base_STEAM = single(img_STEAM(:,:,1));
                                    base_STEAM = (base_STEAM-min([min_STEAM,0]))/(max_STEAM-min([min_STEAM,0]));
                                    base_STEAM(base_STEAM<0)=0;
                                    denoised_STEAM = base_STEAM;
                                    base_STEAM = imnoise(base_STEAM,'gaussian',0,noises(n));
                                    base_STEAM = base_STEAM*(max_STEAM-min([min_STEAM,0]))+min([min_STEAM,0]);
                                    denoised_STEAM = denoised_STEAM*(max_STEAM-min([min_STEAM,0]))+min([min_STEAM,0]); 
                                    
                                    %We have created the noisy images for
                                    %each channel. Next, channel merging!
                                    img_SE(:,:,1) = base_SE;
                                    img_STEAM(:,:,2) = base_SE;
                                    img_SE(:,:,2) = base_STEAM;
                                    img_STEAM(:,:,1) = base_STEAM;
                                    
                                    %Add the "Ground Truths"
                                    dataset_YSE = [dataset_YSE;cell(1,3)];
                                    dataset_YSE{size(dataset_YSE,1),1}= img_SE; %Our "noisy" 3-channel image
                                    dataset_YSE{size(dataset_YSE,1),2}= denoised_SE; %Denoised image
                                    
                                    dataset_YSTEAM = [dataset_YSTEAM;cell(1,3)];
                                    dataset_YSTEAM{size(dataset_YSTEAM,1),1}= img_STEAM; %Our "noisy" image
                                    dataset_YSTEAM{size(dataset_YSTEAM,1),2}= denoised_STEAM; %Our "denoised" image
                                    
                                    %Add th eaverage of the other image to the tag
                                    dataset_YSE{size(dataset_YSE,1),3}= tag;
                                    dataset_YSTEAM{size(dataset_YSTEAM,1),3}= tagSTEAM;
                                end
                            end
                        end
                    end
                case "STEAM"
                    continue;
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
end

    function out = checkDiffusiondataEmptinessDenoised(diffusiondata)
        %For diffusion data (denoised structures)
        out = zeros(size(diffusiondata,2),1); %Number of directions
        for i=1:size(diffusiondata,2)
            for j=1:size(diffusiondata,1)
                if ~isempty(diffusiondata{j,i})
                    out(i,1)=1;
                    break;
                end
            end
        end
        
    end

    function [min_dataset, max_dataset] = findExtremes(diffusiondata)
        
        %Returns the maximum and minimum values of a diffusion data dataset. This
        %is necessary in case you want to "normalize" the images of a particular
        %(subject, phase, sequence) case because the intensities of 150 images
        %aren't the same as those of the 450 images and thus normal normalization
        %fails to keep the ratio between them.
        
        min_dataset = 255;
        max_dataset = 0;
        
        for i=2:size(diffusiondata,2) %Loop over each direction
            for j=1:size(diffusiondata,1) %Loop over each 4-image average
                if ~isempty(diffusiondata{j,i})
                    im = diffusiondata{j,i}.im;
                    if max(im(:))>max_dataset
                        max_dataset = max(im(:));
                    end
                    if min(im(:))<min_dataset
                        min_dataset = min(im(:));
                    end
                end
            end
        end
    end