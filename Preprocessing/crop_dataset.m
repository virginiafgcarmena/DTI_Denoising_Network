%Crop_dataset
%Author: Virginia Fernandez
%MSc Project. Dataset processing (2019)

%Selects the maximum width and height from the healthys and patients
%datasets and crops each image within the structure using the upper-left
%corner coordinates in each cropinfo file, and the defined height and
%widths.

function [healthys, patients] = crop_dataset(healthys,patients)
  
[maximum_xh, maximum_yh] = select_maxboundaries(healthys);
[maximum_xp, maximum_yp] = select_maxboundaries(patients);
 
maximum_x = max([maximum_xh, maximum_xp]);
maximum_y = max([maximum_yh, maximum_yp]);
 
%  maximum_x = 88;
%  maximum_y = 120;

 healthys = crop_dataset_s(healthys,maximum_x,maximum_y);
 patients = crop_dataset_s(patients, maximum_x,maximum_y);
 
end

function [subjects] = crop_dataset_s(subjects,maximum_x,maximum_y)

%Global parameters
additional_pixels = 16;

parity_maxx = mod(maximum_x,2);
parity_maxy = mod(maximum_y,2);

    for p=1:length(subjects) %Loop accross patients
            
        name_phases = fieldnames(subjects{p});
        num_phases = size(name_phases,1);
        
        for  ph=1:num_phases %We loop accross the number of phases
        
        name_sequences = fieldnames(subjects{p}.(name_phases{ph}));
        num_sequences = size(name_sequences,1);
            
            for seq=1:num_sequences %We loop accross the number of sequences
             
            diffd =  subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata;
                
                for i=1:size(diffd,2) %Directions
                    for j=1:size(diffd,3) %Averages 
                        if(~isempty(subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{1,i,j}))
                        
                        %Retrieval of the image
                        image_dwld = subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{1,i,j}.data;
                        cropinfo =  subjects{p}.(name_phases{ph}).(name_sequences{seq}).cropinfo;                            
            
                        %Center pixel of cropinfo
                        XC = round(cropinfo(1))+ceil(cropinfo(3)/2);
                        YC = round(cropinfo(2))+ceil(cropinfo(4)/2);    
                        
                        switch parity_maxx
                            case 0 %If maximum_x is an even number     
                                X1 = XC-(maximum_x/2-1);
                                X2 = XC+(maximum_x/2);   
                            case 1 %If maximum_x is an odd number
                                X1 = XC-((maximum_x-1)/2);
                                X2 = XC+((maximum_x-1)/2);
                        end
                        switch parity_maxy
                            case 0 %If maximum_x is an even number               
                                Y1 = YC-(maximum_y/2-1);
                                Y2 = YC+(maximum_y/2);   
                                %Before registration of non-denoised images, we decrease Y1 by 12 pixels
                                %because we will then crop them due to the registration.
                                Y1 = Y1-additional_pixels;
                            case 1 %If maximum_x is an odd number
                                Y1 = YC-((maximum_y-1)/2);
                                Y2 = YC+((maximum_y-1)/2);
                                %Before registration of non-denoised images, we decrease Y1 by 12 pixels
                                %because we will then crop them due to the registration.
                                Y1 = Y1-additional_pixels;
                        end           
                          if(X1<1)
                              spare_pixels = 1-X1;
                              X1 = 1;
                              X2 = X2+spare_pixels;
                          end
                          if(X2>size(image_dwld,2))   
                              spare_pixels = size(image_dwld,2)-X2;
                              X2 = size(image_dwld,2);
                              X1 = X1-spare_pixels;
                          end
                          if(Y1<1)
                              spare_pixels = 1-Y1;
                              Y1 = 1;
                              Y2 = Y2+spare_pixels;                            
                          end
                          if(Y2> size(image_dwld,1))
                              spare_pixels = size(image_dwld,1)-Y2;
                              Y2 = size(image_dwld,1);
                              Y1 = Y1-spare_pixels;
                          end
                          
                          image_dwld = image_dwld(Y1:Y2,X1:X2);
                          subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{1,i,j}.data = image_dwld;
                          
                        end
                    end
                end
            end
        end        
    end  
    
   %Display of random images 
   subj_ran = randi(length(subjects)); 
   phase_ran = randi(2); 
   name_phases = fieldnames(subjects{subj_ran});
   dif_steam = subjects{subj_ran}.(name_phases{phase_ran}).STEAM.diffusiondata;
   
    rand_av = randi(size(dif_steam,3));
    figure
    square_plot = ceil(sqrt(size(dif_steam,2)));
    
    for i=1:size(dif_steam,2)
        if ~isempty(dif_steam{1,i,rand_av})
            subplot(square_plot,square_plot,i);
            imshow(dif_steam{1,i,rand_av}.data,[]);
            title(strcat("P",int2str(subj_ran),", PH ",int2str(phase_ran), " STEAM, av. ", int2str(rand_av),", dir. ", int2str(i)));
        end
    end
    
    dif_se = subjects{subj_ran}.(name_phases{phase_ran}).STEAM.diffusiondata;
    rand_av = randi(size(dif_se,3));
    figure
    square_plot = ceil(sqrt(size(dif_steam,2)));
    
    for i=1:size(dif_se,2)
        if ~isempty(dif_se{1,i,rand_av})
            subplot(square_plot,square_plot,i);
            imshow(dif_se{1,i,rand_av}.data,[]);
            title(strcat("P",int2str(subj_ran),", PH ",int2str(phase_ran), " STEAM, av. ", int2str(rand_av),", dir. ", int2str(i)));
        end
    end
   
    disp(strcat("Region size: X:",int2str(maximum_x)," Y:",int2str(maximum_y)));
end

function [maxx,maxy] = select_maxboundaries(subjects)

%Retrieves the maximum height and width of the boundary 

maxx = 0;
maxy = 0; %Initialization at 1000px 

    for p=1:length(subjects) %Loop accross patients            
        name_phases = fieldnames(subjects{p});
        num_phases = size(name_phases,1);        
        for  ph=1:num_phases %We loop accross the number of phases       
        name_sequences = fieldnames(subjects{p}.(name_phases{ph}));
        num_sequences = size(name_sequences,1);            
            for seq=1:num_sequences %We loop accross the number of sequences             
            cropinformation =  subjects{p}.(name_phases{ph}).(name_sequences{seq}).cropinfo;            
               if cropinformation(3)>maxx
                   maxx = cropinformation(2);
               end
               if cropinformation(4)>maxy
                   maxy = cropinformation(4);
               end               
            end
        end       
    end
    
    maxx=ceil(maxx);
    maxy=ceil(maxy);
    
   
end


