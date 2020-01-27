function training_dataset = crop_denoised_dataset_YOLO(healthys,patients)

%Version 2
%Compatible with Version 2 of process_average_matrix (including tags)

%Enter either 150s or 450s. They can be then attached

%Returns a training dataset with 3 cells per row:
% - 1st cell: image (not cropped)
% - 2d cell: crop information (X1, Y1, WIDTH HEIGHT), necessary for YOLO 
% - 3d cell: SE or STEAM

 %We select the maximum sizes of crops we have in our dataset
 [maximum_xh, maximum_yh] = select_maxboundaries(healthys);
 [maximum_xp, maximum_yp] = select_maxboundaries(patients);
 
 maximum_x = max([maximum_xh, maximum_xp]);
 maximum_y = max([maximum_yh, maximum_yp]);


 td1 = crop_dataset_s(healthys,maximum_x,maximum_y);
 td2 = crop_dataset_s(patients, maximum_x,maximum_y);
 
 training_dataset = vertcat(td1,td2);
 
end

function [td1] = crop_dataset_s(subjects,maximum_x,maximum_y)

td1 = {}; %Training dataset contains: image, boundaries, steam/se

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
                    for j=1:size(diffd,1) %Averages 
                        if(~isempty(subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{j,i}))
                        
                        %Retrieval of the image
                        image_dwld = subjects{p}.(name_phases{ph}).(name_sequences{seq}).diffusiondata{j,i};
                        cropinfo =  subjects{p}.(name_phases{ph}).(name_sequences{seq}).cropinfo;                            
                        
                        if size(image_dwld,1)<size(image_dwld,2)
                            disp("Reversed images!");
                        end 
                        
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
                            case 1 %If maximum_x is an odd number
                                Y1 = YC-((maximum_y-1)/2);
                                Y2 = YC+((maximum_y-1)/2);
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
                          
                          %image_dwld = image_dwld(Y1:Y2,X1:X2);
                          %Y1 and MAXIMUM_Y go first because in Matlab, the
                          %"Y"s are the rows and are the first index
                          box = [Y1,X1,maximum_y,maximum_x]; 
                          td1 = [td1; cell(1,3)];
                          td1{size(td1,1),1} = image_dwld; %First column, image
                          td1{size(td1,1),2} = box; 
                          td1{size(td1,1),3} = name_sequences{seq};
                        end
                    end
                end
            end
        end        
    end  
    
   %Display of 6 random images 
   subj_ran = randi(size(td1,1),3,1); 
    
    for i=1:length(subj_ran)
       subplot(3,1,i);
       image = td1{subj_ran(i),1};
       box = td1{subj_ran(i),2};
       imshow(image(box(1):(box(1)+box(3)),box(2):(box(2)+box(4))),[]);    
    end
    
    %In YOLO, it's necessary to adapt our dataset to the base network we've
    %used (which has mandatory 299x299)
    
    %See mynet, training_dataset_Create.m and images2inception
    
    td1 = images2inception(td1,[299,299]);
    
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
                       maxx = cropinformation(3);
                   end
                   if cropinformation(4)>maxy
                       maxy = cropinformation(4);
                   end    
                   if maxx>96
                       disp(strcat("S",int2str(p),name_phases{ph},name_sequences{seq}));
                   end
            end
        end       
    end
    
    maxx=ceil(maxx);
    maxy=ceil(maxy);
    
   
end

