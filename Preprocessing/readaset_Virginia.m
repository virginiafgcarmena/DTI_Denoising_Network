%readaset_Virginia (2019)
%Author: Virginia Fernandez
%Version: 2
%MSc Project. Dataset Processing.
%Reads through the folders output by: organise_diff_dicoms.m. 
%Arguments: File path where the final structures can be saved
%Output: healthy, patients cell structures. Each cell structure contains N
%cardiac phase, and each phase, SE and STEAM sequences diffusiondata
%structures containing cells with the DICOM info and the image, the average matrix with the quality labels, and the crop information.

%IMPORTANT!
%This function is meant to be embedded in a folder named 'SCRIPTS' (name is
%not relevant), that is contained in the same folder as the Healthy and HCM
%patients dataset. This is important because the program will then navigate
%through the structure. 
%Correct structures:
%HCMpatients: HCMpatients>SEdiastole>p1>diffusion_images
%healthypatients: healthy>h1>M012diastole>diffusion_images

function [healthy, patients] = readaset_Virginia(varargin)

%PARAMETERS:
npatients = 11; %Number of patients of the dataset
nhealthy = 15; %Number of healthy subjects of the dataset
phases_healthy = ["diastole", "SS", "systole"];
phases_patient = ["diastole", "systole"];
sequences = ["M012","STEAM"];
scripts_pathfile = pwd; %Necessary to run the scripts (run is not useful because of the arguments

%The data are saved in destination_file
destination_file = pwd;

    if ~isempty(varargin)
        if (isString(varargin{1})&&(varargin{1}(a)=='\'))
           destination_file = varargin{1};
        else
            error("The input argument must be a folder path");       
        end  
    end
    


%Initialization of our output structures

healthy = cell(nhealthy,1); 
patients= cell(npatients,1); 

%1. HEALTHY PATIENT RETRIEVAL OF DIFFUSION DATA

% cd('..');cd('healthy');
% healthys_dirs = dir('*h*');
% 
%     for hsu = 1:length(healthys_dirs)
%         hsubject_index = str2num(strtok(healthys_dirs(hsu).name,'h')); %The order of dir is alphabetical, not numeric (h1, h10, h11 etc.)         
%         if healthys_dirs(hsu).isdir %We ignore files in case there are any
%             subjectfolder = cd(healthys_dirs(hsu).name); %Contains folders with patients     
%             
%             for ph=1:length(phases_healthy) %Loop over the phases
%                 hsubject_folder = pwd; %Stores the content of the healthy subject    
%                 
%                 %Initialize healthy.phase
%                 switch ph
%                        case 'diastole'
%                              healthy{hsubject_index}.diastole = struct('SE',struct,'STEAM');     
%                        case 'systole'
%                              healthy{hsubject_index}.systole = struct('SE',struct,'STEAM');                                                                             
%                        case 'SS'
%                               healthy{hsubject_index}.SS = struct('SE',struct,'STEAM');                                    
%                 end
%                       
%                 for seq=1:length(sequences)%Loop over the sequences (STEAM, SE)
%                     phase_folder = strcat(sequences(seq),'_',phases_healthy(ph));%Folder storing the diff. phases and sequences                    
%                     images_folder = fullfile(hsubject_folder,phase_folder,'diffusion_images'); %Folder storing the images
%                     averages_folder = fullfile(hsubject_folder,phase_folder,'matlab_data'); %Folder storing the average matrix
%                     try                  
%                         cd(scripts_pathfile); %We need to run pre_organise_diff_dicoms from its folder
%                         [info, switches,diff_param,prot]=pre_organise_diff_dicoms(images_folder); %Pre-script. Loads the arguments that are passed to the function
%                         cd(scripts_pathfile); %Again, we need to run organise_diff_dicoms from its folder
%                         [h_gui,diffusion_data,prot,diff_param,info,switches] = organise_diff_dicoms(images_folder,[],info,diff_param,switches,prot);
%                         
%                         %The only thing we are interested in is diffusion_dat a structure that contains our images.                         
%                         switch phases_healthy(ph)
%                             case 'diastole'    
%                                 switch sequences(seq)
%                                     case 'M012'
%                                      healthy{hsubject_index}.diastole.SE.diffusiondata = diffusion_data;   
%                                      cd(averages_folder)
%                                      avm = load('average_matrix');
%                                      healthy{hsubject_index}.diastole.SE.averagematrix = avm.new_average_matrix;
%                                      cropinfo = load('crop_info');
%                                      healthy{hsubject_index}.diastole.SE.cropinfo = cropinfo.crop_positions;                                    
%                                     case 'STEAM' 
%                                      healthy{hsubject_index}.diastole.STEAM.diffusiondata = diffusion_data; 
%                                      cd(averages_folder)
%                                      avm = load('average_matrix');
%                                      healthy{hsubject_index}.diastole.STEAM.averagematrix = avm.new_average_matrix;
%                                      cropinfo = load('crop_info');
%                                      healthy{hsubject_index}.diastole.STEAM.cropinfo = cropinfo.crop_positions;
%                                 end   
%                             case 'systole'
%                                 switch sequences(seq)
%                                     case 'M012'
%                                      healthy{hsubject_index}.systole.SE.diffusiondata = diffusion_data;                       
%                                      cd(averages_folder)
%                                      avm = load('average_matrix');
%                                      healthy{hsubject_index}.systole.SE.averagematrix = avm.new_average_matrix;
%                                      cropinfo = load('crop_info');
%                                      healthy{hsubject_index}.systole.SE.cropinfo = cropinfo.crop_positions;                                   
%                                     case 'STEAM' 
%                                      healthy{hsubject_index}.systole.STEAM.diffusiondata = diffusion_data; 
%                                      cd(averages_folder)
%                                      avm = load('average_matrix');
%                                      healthy{hsubject_index}.systole.STEAM.averagematrix = avm.new_average_matrix;
%                                      cropinfo = load('crop_info');
%                                      healthy{hsubject_index}.systole.STEAM.cropinfo = cropinfo.crop_positions; 
%                                 end
%                             case 'SS'
%                                 switch sequences(seq)
%                                     case 'M012'
%                                      healthy{hsubject_index}.SS.SE.diffusiondata = diffusion_data;                       
%                                      cd(averages_folder)
%                                      avm = load('average_matrix');
%                                      healthy{hsubject_index}.SS.SE.averagematrix = avm.new_average_matrix;
%                                      cropinfo = load('crop_info');
%                                      healthy{hsubject_index}.SS.SE.cropinfo = cropinfo.crop_positions;                           
%                                     case 'STEAM' 
%                                      healthy{hsubject_index}.SS.STEAM.diffusiondata = diffusion_data;                      
%                                      cd(averages_folder)
%                                      avm = load('average_matrix');
%                                      healthy{hsubject_index}.SS.STEAM.averagematrix = avm.new_average_matrix;
%                                      cropinfo = load('crop_info');
%                                      healthy{hsubject_index}.SS.STEAM.cropinfo = cropinfo.crop_positions;                       
%                                 end
%                             otherwise
%                                 error("Non existent phase or sequence");
%                         end
%                     catch
%                         error(strcat("Error processing ",healthys_dirs(hsu).name," in ",phases_healthy(ph), " ",sequences(seq)));
%                     end
%                     disp(strcat(healthys_dirs(hsu).name,",",phases_healthy(ph),"-",sequences(seq)," processed."));
%                     cd(hsubject_folder);
%                 end
%             end  
%             cd(subjectfolder);
%         end       
%     end
    
    %2. Patients
    
    cd('..');cd('HCMpatients');
    
    %The first thing we encounter are the folders with the phase and
    %sequences
    %To avoid including '..','.', present when doing 'dir', we will build
    %an array with all the subfolders we'll have
    
    ph_seq_folders = strings(length(sequences),length(phases_patient));
    for i=1:length(phases_patient)
        for j=1:length(sequences)
            ph_seq_folders(i,j) = strcat(sequences(i),'_',phases_patient(j));
        end
    end
    
    %Now we loop along that ph_seq_folder
    for ph=1:length(phases_patient)
        for seq=1:length(sequences) %arreglar. Poner BP aqui. Hay un PB!
            subjectfolder = cd(ph_seq_folders(seq,ph)); %Choose a (phase,sequence) combination
            patients_dirs = dir('*p*');
            for pat=1:length(patients_dirs)
                patient_index = str2num(strtok(patients_dirs(pat).name,'p')); %We save the patient index
                %We initialize structure healthy with all the phases

                patients_path = cd(patients_dirs(pat).name); %We save the path to the patients list and cd. 
                images_folder = fullfile(patients_path,patients_dirs(pat).name,'diffusion_images');
                averages_folder = fullfile(patients_path,patients_dirs(pat).name,'matlab_data');   
                    try
                        cd(scripts_pathfile); %We need to run pre_organise_diff_dicoms from its folder
                        [info, switches,diff_param,prot]=pre_organise_diff_dicoms(images_folder); %Pre-script. Loads the arguments that are passed to the function
                        cd(scripts_pathfile); %Again, we need to run organise_diff_dicoms from its folder
                        [h_gui,diffusion_data,prot,diff_param,info,switches] = organise_diff_dicoms(images_folder,[],info,diff_param,switches,prot);
                        
                        %The only thing we are interested in is diffusion_dat a structure that contains our images.                         
                        switch phases_patient(ph)
                            case 'diastole'    
                                switch sequences(seq)
                                    case 'M012'
                                     patients{patient_index}.diastole.SE.diffusiondata = diffusion_data;                       
                                     cd(averages_folder);
                                     avm = load('average_matrix');
                                     patients{patient_index}.diastole.SE.averagematrix = avm.new_average_matrix;
                                     cropinfo = load('crop_info');
                                     patients{patient_index}.diastole.SE.cropinfo = cropinfo.crop_positions;
                                    case 'STEAM' 
                                     patients{patient_index}.diastole.STEAM.diffusiondata = diffusion_data; 
                                     cd(averages_folder);
                                     avm = load('average_matrix');
                                     patients{patient_index}.diastole.STEAM.averagematrix = avm.new_average_matrix;
                                     cropinfo = load('crop_info');
                                     patients{patient_index}.diastole.STEAM.cropinfo = cropinfo.crop_positions;
                                end   
                            case 'systole'
                                switch sequences(seq)
                                    case 'M012'
                                     patients{patient_index}.systole.SE.diffusiondata = diffusion_data;                       
                                     cd(averages_folder);
                                     avm = load('average_matrix');
                                     patients{patient_index}.systole.SE.averagematrix = avm.new_average_matrix;
                                     cropinfo = load('crop_info');
                                     patients{patient_index}.systole.SE.cropinfo = cropinfo.crop_positions;
                                    case 'STEAM' 
                                     patients{patient_index}.systole.STEAM.diffusiondata = diffusion_data; 
                                     cd(averages_folder);
                                     avm = load('average_matrix');
                                     patients{patient_index}.systole.STEAM.averagematrix = avm.new_average_matrix;
                                     cropinfo = load('crop_info');
                                     patients{patient_index}.systole.STEAM.cropinfo = cropinfo.crop_positions;
                                end
                        end                   
                   catch 
                        error(strcat("Error processing patient ",int2str(patient_index)," in ",phases_patient(ph),"-",sequences(seq)));                  
                   end
                disp(strcat(int2str(patient_index)," in ",phases_patient(ph),"-",sequences(seq)," processed."));  
                cd(patients_path);
            end
            cd(subjectfolder);
        end
    end
    
    %Save the structures
    cd(destination_file);
    save('HEALTHY_SUBJECTS', 'healthy');
    save('HCM_PATIENTS','patients');
    
end

