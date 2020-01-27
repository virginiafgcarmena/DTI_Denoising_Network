function [h_gui,diffusion_data,prot,diff_param,info,switches]...
    =organise_diff_dicoms...
    (file_path,h_gui,info,diff_param,switches,prot)

gui_message{1}='Organising Diffusion data...';
% update_gui_output(h_gui,gui_message);
gui_message=[];

cd(file_path);

%store all series numbers used (might be useful to know what was used and what was discarded)
series_number_all=zeros(info.number_of_files,1);

warning_spoiler_b_value_flag_header=0;
warning_spoiler_b_value_flag_no_header=0;
warning_b_value_flag_no_header=0;
warning_spoiler_direction_flag=0;
warning_no_direction_info_flag=0;

stored_slice_position=[];
stored_directions=[];
diff_param.stored_b_values=[];
slice_direction_matrix=zeros(256,256); %should be enough!

no_rotation_flag=0;

%if ex-vivo show progress bar
if switches.ex_vivo_data == 1
    f = waitbar(0.5,'Loading dicom files...');
end

for file_index=1:info.number_of_files
    
    if switches.ex_vivo_data == 1
        waitbar(file_index/info.number_of_files,f,'Loading dicom files...');
    end
    
    %read dicom image data and header
    image_data = double(dicomread(info.diffusion_files(file_index).name));
    
    %V: If the image has more than 1 channel (R,G,B? useful for diffusion
    %maps)
    if size(image_data,3)>1
        movefile(info.diffusion_files(file_index).name,'../extra_maps');
        continue
    end
    
    %V: Stores all images in average_all_images (a X x Y x Number of images
    %array)
    if file_index==1
        average_all_images = zeros(size(image_data,1),size(image_data,2),info.number_of_files);
        average_all_images(:,:,file_index)=image_data;
        prot.original_n_lines = size(image_data,1);
        prot.original_n_cols = size(image_data,2);
    else
        average_all_images(:,:,file_index)=image_data;
    end
    
    
    % % % %     % to test some stuff, make sure it is commented once finishing testing
    % % % %     image_data=imrotate(image_data,270);
    
    
    % % %     %in case the data is not zero filled, it is interpolated by a factor of
    % % %     %two
    % % %     if max(size(image_data))<200
    % % %
    % % %         if file_index==1
    % % %             % % %             oldmsgs = cellstr(get(h_gui.output_text,'String'));
    % % %             % % %             set(h_gui.output_text,'String',[oldmsgs;{'     Zero-padding was not used! Resizing image data by a factor of 2...'}]);
    % % %             fprintf(2,'     Zero-padding was not used! Resizing image data by a factor of 2...\n')
    % % %         end
    % % %
    % % %         image_data=imresize(image_data,2,'nearest');
    % % %     end
    
    %Stores the dicominfo of the file in question in image_header.  
    image_header=dicominfo(info.diffusion_files(file_index).name);
    
    %%%SPIRAL READOUT
    if  switches.spiral==1      %MG
        if(isfield(image_header, 'SliceLocation')==0)
            image_header.SliceLocation=69.594;
        end
        if numel(image_header.Private_0019_100c)==8
            image_header.Private_0019_100c=typecast(image_header.Private_0019_100c', 'double');
        end
        if isfield(image_header, 'Private_0019_100e')==1 && numel(image_header.Private_0019_100e)==24
            image_header.Private_0019_100e=typecast(image_header.Private_0019_100e', 'double');
            image_header.Private_0019_100e=image_header.Private_0019_100e.';
        end
    end
    
    
    %check if image is a primary dicom, and not a map. If a derived image,
    %for example an FA map, then copy image to another folder, and then
    %bail out to next index in the for loop
    image_type=image_header.ImageType;
    slash_pos=strfind(image_type,'\');
    if isempty(slash_pos)
        slash_pos=length(image_type);
    end
    image_type=image_type(1:slash_pos(1));
    if strcmp(image_type,'DERIVED\')
        
        cd ..
        if ~exist('extra_maps','dir')
            mkdir('extra_maps');
        end
        cd('diffusion_images')
        
        movefile(info.diffusion_files(file_index).name,'../extra_maps');
        
        continue
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     b-values
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %check if there is a b-value in a text file. If not:
    %check if there is a b-value in the header and store it, if not bail out with error.
    %If there is one but it is zero, assume we are in the reference image.
    %Therefore we either read the diff_param.b_value_ref from the header if there is
    %one or give it a previous manually attributed one (in the main function at the top).
    
    %check for hard coded b-values on a text file
    if file_index==1
        skip_b_values_flag=0;
        cd ..
        if exist('b_values.txt')==2
            all_b_values=load('b_values.txt','-ascii');
            fprintf(2,['     b_values found in a text file, ignoring header info\n'])
            skip_b_values_flag=1;
        end
        cd('diffusion_images');
    end
    
    if skip_b_values_flag==0
        %try to extract the b-value
        if isfield(image_header,'Private_0019_100c')==1
            image_b_value=image_header.Private_0019_100c;
            
            if image_b_value(1)==0 || max(size(image_b_value))==2
                
                %V : Extract the value of the Spoiled gradient or the BSP
                %gradient("Constrained deformation field")
                if isfield(image_header,'ImageComments')==1
                    %ADS
                    if(~isempty(strfind(image_header.ImageComments, 'bsp=')))
                        bsp_string=cell2mat(regexp(image_header.ImageComments, 'bsp=(\d|\.)+', 'match'));
                        image_b_value=str2num(bsp_string(numel('bsp=')+1:end));
                        image_b_value=image_b_value/3;
                        image_header.Private_0019_100c=image_b_value;
                        if warning_spoiler_b_value_flag_header==0
                            % % %                         oldmsgs = cellstr(get(h_gui.output_text,'String'));
                            % % %                         set(h_gui.output_text,'String',[oldmsgs;{['     Using diff_param.b_value_ref found in header : ' num2str(image_b_value)]}]);
                            fprintf(2,['     Using diff_param.b_value_ref found in header : ' num2str(image_b_value) '\n'])
                            warning_spoiler_b_value_flag_header=1;
                        end
                        RR_string=cell2mat(regexp(image_header.ImageComments, 'RR:(\d|\.)+', 'match'));
                        assumed_RR=str2num(RR_string(numel('RR:')+1:end));
                        image_header.assumed_RR=assumed_RR;     %ADS - this may not be the best place for this!
                        
                    else
                        if(~isempty(strfind(image_header.ImageComments, 'bspoil')))
                            image_b_value=str2num(cell2mat(regexp(image_header.ImageComments, '(\d|\.)+', 'match')));
                            image_b_value=image_b_value/3;
                            image_header.Private_0019_100c=image_b_value;
                            
                            if warning_spoiler_b_value_flag_header==0
                                % % %                         oldmsgs = cellstr(get(h_gui.output_text,'String'));
                                % % %                         set(h_gui.output_text,'String',[oldmsgs;{['     Using diff_param.b_value_ref found in header : ' num2str(image_b_value)]}]);
                                fprintf(2,['     Using diff_param.b_value_ref found in header : ' num2str(image_b_value) '\n'])
                                warning_spoiler_b_value_flag_header=1;
                            end
                            
                        else
                            image_b_value=diff_param.b_value_ref;
                            image_header.Private_0019_100c=image_b_value;
                            if warning_spoiler_b_value_flag_no_header==0
                                % % %                         oldmsgs = cellstr(get(h_gui.output_text,'String'));
                                % % %                         set(h_gui.output_text,'String',[oldmsgs;{['     diff_param.b_value_ref not found in header, using hard-coded value : ' num2str(image_b_value)]}]);
                                fprintf(2,['     diff_param.b_value_ref not found in header, using hard-coded value : ' num2str(image_b_value) '\n'])
                                warning_spoiler_b_value_flag_no_header=1;
                            end
                        end
                    end
                else
                    image_b_value=diff_param.b_value_ref;
                    image_header.Private_0019_100c=image_b_value;
                    if warning_spoiler_b_value_flag_no_header==0
                        % % %                     oldmsgs = cellstr(get(h_gui.output_text,'String'));
                        % % %                     set(h_gui.output_text,'String',[oldmsgs;{['     diff_param.b_value_ref not found in header, using hard-coded value : ' num2str(image_b_value)]}]);
                        fprintf(2,['     diff_param.b_value_ref not found in header, using hard-coded value : ' num2str(image_b_value) '\n'])
                        warning_spoiler_b_value_flag_no_header=1;
                    end
                end
                
            elseif max(size(image_b_value))==4
                image_b_value=350;
                image_header.Private_0019_100c=image_b_value;
                if warning_b_value_flag_no_header==0
                    % % %                 oldmsgs = cellstr(get(h_gui.output_text,'String'));
                    % % %                 set(h_gui.output_text,'String',[oldmsgs;{['     b_value also not found in header, using hard-coded value : ' num2str(image_b_value)]}]);
                    fprintf(2,['     b_value also not found in header, using hard-coded value : ' num2str(image_b_value) '\n'])
                    warning_b_value_flag_no_header=1;
                end
                
            end
            
        else
            error(['Missing b-values in file: ' image_header.Filename]);
        end
        
    elseif skip_b_values_flag==1
        image_b_value=all_b_values(file_index);
    end
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     diffusion directions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %create a rotational matrix to rotate the diffusion directions from the PCS
    %to the image plane
    if file_index==1
        first_column=image_header.ImageOrientationPatient(1:3);
        second_column=image_header.ImageOrientationPatient(4:6);
        third_column=cross(first_column,second_column);
        rotational_matrix=[first_column,second_column,third_column];
    end
    
    if file_index==1
        skip_directions_flag=0;
        cd ..
        if exist('diffusion_directions.txt')==2
            all_diff_directions=load('diffusion_directions.txt','-ascii');
            
            if switches.varian==0
                %if phase encode along rows, then swap X and Y
                if strcmp(image_header.InPlanePhaseEncodingDirection,'ROW')
                    all_diff_directions_new(:,1)=all_diff_directions(:,2);
                    all_diff_directions_new(:,2)=all_diff_directions(:,1);
                    all_diff_directions_new(:,3)=all_diff_directions(:,3);
                    all_diff_directions=all_diff_directions_new;
                    clear all_diff_directions_new
                end
            else
                all_diff_directions_new(:,1)=all_diff_directions(:,2);
                all_diff_directions_new(:,2)=all_diff_directions(:,1);
                all_diff_directions_new(:,3)=all_diff_directions(:,3);
                all_diff_directions=all_diff_directions_new;
                clear all_diff_directions_new
            end
            
            %Flip z direction
            all_diff_directions(:,3)=-all_diff_directions(:,3);
            
            fprintf(2,['     diffusion directions found in a text file, ignoring header info\n'])
            skip_directions_flag=1;
        end
        cd('diffusion_images');
    end
    
    if skip_directions_flag==0
        %check for the direction, if there isn't one assume it is the reference
        %one with direction [1 1 1]. This direction comes from the spoiler
        %gradients.
        if isfield(image_header,'Private_0019_100e')==0
            image_direction=[1;1;1];
            
            %no need for rotation at spoilers
            no_rotation_flag=1;
            
            if warning_spoiler_direction_flag==0
%                 oldmsgs = cellstr(get(h_gui.output_text,'String'));
                % % %             set(h_gui.output_text,'String',[oldmsgs;{['     Spoiler direction used : ' num2str(image_direction')]}]);
                % % %             fprintf(2,['     Spoiler direction used : ' num2str(image_direction') '\n'])
                warning_spoiler_direction_flag=1;
            end
            
        elseif isempty(image_header.Private_0019_100e) || length(image_header.Private_0019_100e)~=3
            
            error(['Missing direction information: ' image_header.Filename]);
            
        else
            image_direction=image_header.Private_0019_100e;
        end
        
        
    elseif skip_directions_flag==1
        image_direction=all_diff_directions(file_index,:)';
        if image_direction(1)==1 && image_direction(2)==1 && image_direction(3)==1
            no_rotation_flag=1;
        elseif image_direction(1)==0 && image_direction(2)==0 && image_direction(3)==0
            no_rotation_flag=1;
        else
            if switches.diff_dir_rot==1
                no_rotation_flag=0;
            elseif switches.diff_dir_rot==0
                no_rotation_flag=1;
            end
        end
    end
    
    %V: Normally, there should not be new slices (there should be a single
    %slice per image)
    
    %is this a new slice?
    current_slice_pos=round(image_header.SliceLocation*10)/10;
    [a_is,a_pos]=ismember(current_slice_pos,stored_slice_position);
    if a_is==1
        slice_number=a_pos;
    else
        stored_slice_position=[stored_slice_position current_slice_pos];
        slice_number=length(stored_slice_position);
    end
    
    %is this a new direction?
    current_direction=image_direction;
    if isempty(stored_directions)
        [a_is,a_pos]=ismember(current_direction,stored_directions);
    else
        [a_is,a_pos]=ismember(current_direction',stored_directions','rows');
    end
    
    if a_is==1
        direction_number=a_pos(1);
    else
        %ADS check if dot product between this and any of the other
        %directions is close enough to be effec
        tolerance=1e-5;
        withintol=[];
        if(~isempty(stored_directions))
            withintol=find(current_direction'*stored_directions>(1-tolerance) & current_direction'*stored_directions<(1+tolerance));    %ADS had to add this & +tolerance part because [1 1 1] is not normalised and therefore the dot product may be >1 in some directions.
        end
        if(isempty(withintol))
            stored_directions=[stored_directions current_direction];
            direction_number=size(stored_directions,2);
        else
            direction_number=withintol;
        end
    end
    
    %is this a new average?
    slice_direction_matrix(slice_number,direction_number)=slice_direction_matrix(slice_number,direction_number)+1;
    
    average_number=slice_direction_matrix(slice_number,direction_number);
    
    %store the b-values read
    current_b_value=round(image_b_value*1000)/1000;
    [a_is,a_pos]=ismember(current_b_value,diff_param.stored_b_values);
    if a_is==1
        
    else
        diff_param.stored_b_values=[diff_param.stored_b_values current_b_value];
        diff_param.n_b_values=length(diff_param.stored_b_values);
    end
    
    
    
    %finally store everything in a cell with structures
    diffusion_data{slice_number,direction_number,average_number}.info=image_header;
    
    %rotate diffusion gradient to logical coordinates (image plane)
    if no_rotation_flag==0
        diffusion_data{slice_number,direction_number,average_number}.dir=image_direction'*rotational_matrix;
        diffusion_data{slice_number,direction_number,average_number}.dir_before_rotation=image_direction';
        stored_directions_rotated(:,direction_number)=(stored_directions(:,direction_number)'*rotational_matrix)';
    elseif no_rotation_flag==1
        diffusion_data{slice_number,direction_number,average_number}.dir=image_direction';
        diffusion_data{slice_number,direction_number,average_number}.dir_before_rotation=image_direction';
        stored_directions_rotated(:,direction_number)=stored_directions(:,direction_number);
        no_rotation_flag=0; %put flag back
    end
    
    diffusion_data{slice_number,direction_number,average_number}.b_val=round(image_b_value*1000)/1000;
    diffusion_data{slice_number,direction_number,average_number}.data=image_data;
    
    %finally store the series number
    series_number_all(file_index)=image_header.SeriesNumber;
    
end %next file

%close progress bar
if switches.ex_vivo_data == 1
    close(f);
end


average_all_images=mean(average_all_images,3);

cd ..


%remove unwanted slices before anything else
if ~isempty(prot.unwanted_slices)
    for slice_index=fliplr(prot.unwanted_slices)
        diffusion_data(slice_index,:,:)=[];
    end
end


%we have all the data gathered in a structure, but depending on the switch
%or text file we may have to remove some of the reference b-value data,
%store those positions in a variable
diff_param.exclude_ref_b_value_position=[];
for file_index=1:length(diffusion_data(:))
    if ~isempty(diffusion_data{file_index}) && ismember(round(diffusion_data{file_index}.b_val),round(diff_param.b_value_exclude))
        diff_param.exclude_ref_b_value_position=[diff_param.exclude_ref_b_value_position file_index];
    end
end


% Number of slices, directions and averages
prot.n_slices=size(diffusion_data,1);
prot.n_directions=size(diffusion_data,2);
prot.n_averages=size(diffusion_data,3);


%remove repeated entries of the series number
info.series_numbers=unique(series_number_all,'stable');



%find out the slice order (we need to order as the apical first always for
%in vivo data only)
slice_location=zeros(prot.n_slices,1);
for slice_index=1:prot.n_slices
    slice_location(slice_index)=diffusion_data{slice_index,1,1}.info.SliceLocation;
end
[location,prot.slice_order]=sort(slice_location,'descend');
prot.slice_order=prot.slice_order';

%organise the diffusion data from apical to base
diffusion_data_new=diffusion_data;
for slice_index=1:prot.n_slices
    for direction_index=1:prot.n_directions
        for average_index=1:prot.n_averages
            diffusion_data_new{slice_index,direction_index,average_index}=...
                diffusion_data{prot.slice_order(slice_index),direction_index,average_index};
        end
    end
end

diffusion_data=diffusion_data_new;
prot.slice_order=1:prot.n_slices;
clear diffusion_data_new;



switch switches.ex_vivo_data
    case 1
        
        %we need to check the slice distance, if lower than 6 mm, then
        %only do ROIs for every n slices, and then propagate the ROIs
        %between the gaps.
        for slice_index=1:prot.n_slices
            slice_location(slice_index)=abs(diffusion_data{slice_index,1,1}.info.SliceLocation);
            if slice_index>1
                slice_distance(slice_index-1)=abs(slice_location(slice_index)-slice_location(slice_index-1));
            end
        end
        
        if prot.n_slices==1
            slice_distance=0;
        end
        
        mean_distance=mean(slice_distance);
        
        if switches.allow_roi_interp==1
            %propagate ROIs if slice distance less than 6 mm if switch is
            %ON
            if mean_distance<6 && mean_distance>0
                diff_param.roi_slice_jump=floor(6/mean_distance);
            end
        end
        
end


% [h_gui,diffusion_data,info,prot]...
%     = crop_dicoms...
%     (h_gui,prot,diffusion_data,info,switches,average_all_images);



[s,mess,messid]=mkdir('qa_stuff');
cd('qa_stuff');

%finally store all the cropped frames in a huge image
image_data_matrix=cell(prot.n_slices,diff_param.n_b_values,prot.n_directions,prot.n_averages,1);
for slice_index=1:prot.n_slices
    for b_value_index=1:diff_param.n_b_values
        for direction_index=1:prot.n_directions
            for average_index=1:prot.n_averages
                if ~isempty(diffusion_data{slice_index,direction_index,average_index})
                    if diffusion_data{slice_index,direction_index,average_index}.b_val==diff_param.stored_b_values(b_value_index);
                        image_data_matrix{slice_index,b_value_index,direction_index}=[image_data_matrix{slice_index,b_value_index,direction_index};...
                            diffusion_data{slice_index,direction_index,average_index}.data];
                    end
                end
            end
        end
    end
end

%save_images
b_values_and_directions=[];
for slice_index=1:prot.n_slices
    
    n_non_empty=0;
    for b_value_index=1:diff_param.n_b_values
        for direction_index=1:prot.n_directions
            n_non_empty=n_non_empty+~isempty(image_data_matrix{slice_index,b_value_index,direction_index});
        end
    end
    
    if n_non_empty< 10
        montage_n_columns=n_non_empty;
        montage_n_lines=1;
    else
        montage_n_columns=10;
        montage_n_lines=ceil(n_non_empty/montage_n_columns);
    end
    
    h=figure('Visible','off');
    counter=1;
    for b_value_index=1:diff_param.n_b_values
        for direction_index=1:prot.n_directions
            if ~isempty(image_data_matrix{slice_index,b_value_index,direction_index})
                subplot(montage_n_lines,montage_n_columns,counter)
                imshow(image_data_matrix{slice_index,b_value_index,direction_index},[])
                title(['b: ',num2str(diff_param.stored_b_values(b_value_index)),' / dir: ',num2str(direction_index)],'FontSize',10);
                b_values_and_directions(counter,:)=[diff_param.stored_b_values(b_value_index) stored_directions_rotated(:,direction_index)'];
                counter=counter+1;
            end
        end
    end
    % I need to prevent the title and colorbar from being cut
    set(gcf,'Units','points')
    set(gcf,'PaperUnits','points')
    set(gcf,'OuterPosition',[1 1 2000 1000])
    size_fig = get(gcf,'OuterPosition');
    size_fig = size_fig(3:4);
    set(gcf,'PaperSize',size_fig)
    set(gcf,'PaperPosition',[0,0,size_fig(1),size_fig(2)])
    set(gcf, 'PaperPositionMode', 'auto');
    print(gcf,'-dpng','-r75',strcat('01_Diffusion_sorted_data_slice_',sprintf('%02d',slice_index),'.png'))
    close(h)
end

%store a matrix with the b-values and respective directions in prot
diff_param.b_values_and_directions=b_values_and_directions;

% % % %put this in the GUI
% % % h_gui.panel_3.Title='DTI directions'
% % % h_gui.directions=axes('parent',h_gui.panel_3);
% % % scatter3(diff_param.b_values_and_directions(:,2),diff_param.b_values_and_directions(:,3),...
% % %     diff_param.b_values_and_directions(:,4),50,'filled')
% % % box on
% % % axis equal
% % % axis([-1 1 -1 1 -1 1])
% % % grid off
% % % view(3)
% % % for az=-37.5:10:360
% % % view(az,30)
% % % pause(0.5)
% % % end



cd ..





%determine the file re-ordering
info.number_of_files=sum(sum(sum(~cellfun('isempty',diffusion_data)))); %in case we removed slices I need to update the number of files

if switches.varian==0
    time=zeros(1,info.number_of_files);
    position=zeros(1,info.number_of_files);
    counter=1;
    for iindex=1:length(diffusion_data(:))
        if ~isempty(diffusion_data{iindex})
            time(counter)=str2num(diffusion_data{iindex}.info.AcquisitionTime);
            position(counter)=iindex;
            counter=counter+1;
        end
    end
    [~,file_order]=sort(time);
    time_ordered_struct_position=position(file_order);
elseif switches.varian==1
    time_ordered_struct_position=1:info.number_of_files;
end

if switches.disable_rr_correction==0
    
    %determine the Heart-Rate
    %there are two methods potentially available, the dicom acquisition time
    %and the dicom header nominal time
    if(switches.use_nominal_interval)
        correct_nominal_values_flag=1;
    else
        correct_nominal_values_flag=0;
    end
    
    acq_time=zeros(1,info.number_of_files);
    diff_param.RR_interval=zeros(prot.n_slices,prot.n_directions,prot.n_averages);
    diff_param.RR_nominal=zeros(prot.n_slices,prot.n_directions,prot.n_averages);
    
    counter=1;
    
    for iindex=time_ordered_struct_position
        acq_time_temp=cell2mat({diffusion_data{iindex}.info.AcquisitionTime});
        %I need to convert from the format HHmmss.frac to ss.frac
        hh=60*60*str2num(acq_time_temp(1:2));
        mm=60*str2num(acq_time_temp(3:4));
        ss=str2num(acq_time_temp(5:end));
        acq_time(counter)=hh+mm+ss;
        
        [i,j,k]=ind2sub([prot.n_slices prot.n_directions prot.n_averages],iindex);
        if(counter>1)
            diff_param.RR_interval(i,j,k)=(diff_param.RR_interval_factor)*(acq_time(counter)-acq_time(counter-1));
        end
        
        if isfield(diffusion_data{iindex}.info,'NominalInterval') && diffusion_data{iindex}.info.NominalInterval ~= 0
            diff_param.RR_nominal(i,j,k)=diffusion_data{iindex}.info.NominalInterval./1000;
        else
            diff_param.RR_nominal(i,j,k)=diff_param.RR_interval(i,j,k);
        end
        counter = counter + 1;
    end
    
    %sometimes there is a problem and it seems that the nominal RR value is
    %always the same exact number which does not make sense, check for this. If
    %this is the case, then use the dicom header acquisition times instead.
    [~,~,RR_nominals]=find(diff_param.RR_nominal(:));
    if std(RR_nominals) < 5E-3
        correct_nominal_values_flag=0;
        fprintf(2,['     Nominal interval values seem to be wrong! Always the same value! Reverting to the header acquisition times...' '\n'])
    end
    
    
    %remove outliers from the RR interval (whenever there is an outlier, use
    %the value ahead.)
    [~,~,RR_intervals]=find(diff_param.RR_interval(:));
    
    median_RR_interval=median(RR_intervals);
    counter=1;
    for iindex=time_ordered_struct_position
        stored_counter=counter;
        while diff_param.RR_interval(iindex)>1.30*median_RR_interval || diff_param.RR_interval(iindex)<0.70*median_RR_interval
            if counter < length(time_ordered_struct_position)
                [i,j,k]=ind2sub([prot.n_slices prot.n_directions prot.n_averages],time_ordered_struct_position(counter+1));
            else
                [i,j,k]=ind2sub([prot.n_slices prot.n_directions prot.n_averages],time_ordered_struct_position(stored_counter-1));
            end
            diff_param.RR_interval(iindex)=diff_param.RR_interval(i,j,k);
            counter=counter+1;
        end
        counter=stored_counter+1;
    end
    
    median_RR_nominal=median(RR_nominals);
    counter=1;
    for iindex=time_ordered_struct_position
        stored_counter=counter;
        while diff_param.RR_nominal(iindex)>1.30*median_RR_nominal || diff_param.RR_nominal(iindex)<0.70*median_RR_nominal
            if counter < length(time_ordered_struct_position)
                [i,j,k]=ind2sub([prot.n_slices prot.n_directions prot.n_averages],time_ordered_struct_position(counter+1));
            else
                [i,j,k]=ind2sub([prot.n_slices prot.n_directions prot.n_averages],time_ordered_struct_position(stored_counter-1));
            end
            diff_param.RR_nominal(iindex)=diff_param.RR_nominal(i,j,k);
            counter=counter+1;
        end
        counter=stored_counter+1;
    end
    
    
else
    %if RR correction is off
    diff_param.RR_interval=ones(prot.n_slices,prot.n_directions,prot.n_averages).*diff_param.assumed_RR_interval;
    diff_param.RR_nominal=ones(prot.n_slices,prot.n_directions,prot.n_averages).*diff_param.assumed_RR_interval;
    correct_nominal_values_flag = 0;
end


%plot all RR-intervals and save it in the QA folder
switch switches.ex_vivo_data
    case 0
        [s,mess,messid]=mkdir('qa_stuff/hr');
        cd('qa_stuff/hr');
        
%         if strcmp(h_gui.save_option,'+ QA')
%             h=figure('Visible','off');
%             counter=1;
%             RR_interval_sort2 = reshape(diff_param.RR_interval,prot.n_averages*(prot.n_directions),prot.n_slices);
%             RR_nominal_sort2 = reshape(diff_param.RR_nominal,prot.n_averages*(prot.n_directions),prot.n_slices);
%             for slice_index=1:prot.n_slices
%                 subplot(1,prot.n_slices,counter)
%                 plot(RR_interval_sort2(:,slice_index),'LineWidth',2,'Color',[0.18 0.39 0.69]);
%                 hold on, plot(RR_nominal_sort2(:,slice_index),'LineWidth',2,'Color',[0.69 0.39 0.18]);
%                 % % %         ylim([0.3 2]);
%                 title(['RR interval slice: ',num2str(slice_index)],'FontName','Helvetica Neue','FontSize',10)
%                 legend({'RR time', 'RR nominal'}, 'FontName','Helvetica Neue','FontSize',10);
%                 set(gca, ...
%                     'Box'         , 'off'     , ...
%                     'TickDir'     , 'out'     , ...
%                     'XMinorTick'  , 'on'      , ...
%                     'YMinorTick'  , 'on'      , ...
%                     'YGrid'       , 'on'      , ...
%                     'XColor'      , [.3 .3 .3], ...
%                     'YColor'      , [.3 .3 .3], ...
%                     'LineWidth'   , 1         );
%                 set(gca,'FontName','Helvetica Neue','FontSize',13);
%                 counter=counter+1;
%             end
%             saveas(gcf,strcat('RR_intervals_before_frame_rejection.png'))
%             close(h)
%         end
        
        cd ../..
        
end


%correct the b-values from variablity of the RR-interval
%ADS store the prescribed b-value as well in the struct.
for ind=1:numel(diffusion_data)
    if(~isempty(diffusion_data{ind}))
        diffusion_data{ind}.b_pres=diffusion_data{ind}.b_val;
    end
end
for iindex=time_ordered_struct_position
    if(~isempty(diffusion_data{iindex}))
        if(switches.use_nominal_interval) && correct_nominal_values_flag==1
            diffusion_data{iindex}.b_val=diffusion_data{iindex}.b_val*diff_param.RR_nominal(iindex)/diff_param.assumed_RR_interval;
        else
            diffusion_data{iindex}.b_val=diffusion_data{iindex}.b_val*diff_param.RR_interval(iindex)/diff_param.assumed_RR_interval;
        end
    end
end

%ADS copy assumed RR interval from diffusion_data now.
validframes=find(~cellfun(@isempty, diffusion_data));
counter=0;
for ind=1:numel(validframes)
    if(isfield(diffusion_data{validframes(ind)}.info, 'assumed_RR'))
        counter=counter+1;
        assumed_RR_vect(counter)=diffusion_data{validframes(ind)}.info.assumed_RR;
    end
end
if(counter) %If we don't detect any assumed_RR elements then just carry on as before.
    assumed_RR=unique(assumed_RR_vect);
    if(numel(assumed_RR)>1)
        error('Unequal assumed RR over the dataset not supported (yet)');
    end
    diff_param.assumed_RR_interval=assumed_RR/1000;
end
%ADS




%export directions, b-values, normalised directions, filenames for tortoise
%analysis
if switches.export_tortoise_text_file == 1
    
    [~,~,~]=mkdir('diffusion_info_export');
    cd('diffusion_info_export')
    
    %maximum b-value
    max_b_value=max(b_values_and_directions(:,1));
    
    
    filename=['file_order.txt'];
    fid = fopen(filename,'wt');
    
    filename=['diffusion_directions.txt'];
    fid2 = fopen(filename,'wt');
    
    filename=['b_values.txt'];
    fid3 = fopen(filename,'wt');
    
    filename=['tortoise.txt'];
    fid4 = fopen(filename,'wt');
    
    for iindex=time_ordered_struct_position
        
        %dicom file order (fid)
        current_file = diffusion_data{iindex}.info.Filename;
        dashes = strfind(current_file,'/');
        current_file = current_file((dashes(end)+1):end);
        fprintf(fid,'%s\n',current_file);
        
        %diffusion_direction (fid2)
        current_dir = diffusion_data{iindex}.dir;
        fprintf(fid2,'%-10.5f\t',current_dir(1));
        fprintf(fid2,'%-10.5f\t',current_dir(2));
        fprintf(fid2,'%-10.5f\n',current_dir(3));
        
        %diffusion_direction (fid3)
        current_b_val = diffusion_data{iindex}.b_val;
        fprintf(fid3,'%-10.5f\n',current_b_val);
        
        %tortoise file
        if iindex==1
            fprintf(fid4,'%-10.0f\n',length(time_ordered_struct_position));
        end
        %normalise direction
        factor=max_b_value/current_b_val;
        current_dir_norm = (diffusion_data{iindex}.dir)./sqrt(factor);
        fprintf(fid4,'%-10.5f\t',current_dir_norm(1));
        fprintf(fid4,'%-10.5f\t',current_dir_norm(2));
        fprintf(fid4,'%-10.5f\n',current_dir_norm(3));
        
        
    end
    
    fclose(fid);
    fclose(fid2);
    fclose(fid3);
    fclose(fid4);
    
    cd ..
end


%save pixel spacing in the prot variable
prot.pixel_spacing = image_header.PixelSpacing;

end







