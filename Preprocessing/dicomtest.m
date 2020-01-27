%Dicomtest
%Author: Virginia Fernandez 
%MSc Project. Dataset processing (2019)
%Loads the test data and creates a dataset folder SUBJECT>PHASE>SEQ system with:
% - All the (ref+6 directions) averages stored in an "average_noisy" folder
% - The averaged (denoised) images stored together in an
% "averaged_denoised" folder. In this case we make sure that we have 1
% direction and one reference for b=450 AND b=150.

%Note: comment healthy (l.37) or patients storage (l.152) if only one is necessary

HCMP_4TESTR_CLEAN = load('HCMP_4TESTR_CLEAN_2.mat'); %Clean and registered test set for patients
HCMP_4TESTR_CLEAN = HCMP_4TESTR_CLEAN.HCMP_4TESTR_CLEAN_2;
HS_4TESTR_CLEAN = load('HS_4TESTR_CLEAN_2.mat'); %Clean and registered test set for subjects
HS_4TESTR_CLEAN = HS_4TESTR_CLEAN.HS_4TESTR_CLEAN_2;
HCMP_4TEST_DN450 = load('HCMP_4TEST_DN450_2.mat'); %Denoised 450 test set for patients
HCMP_4TEST_DN450 = HCMP_4TEST_DN450.HCMP_4TEST_DN450_2;
HS_4TEST_DN450 = load('HS_4TEST_DN450_2.mat'); %Denoised 450 test set for subjects
HS_4TEST_DN450 = HS_4TEST_DN450.HS_4TEST_DN450_2; 
HCMP_4TEST_DN150 = load('HCMP_4TEST_DN150_2.mat'); %Denoised 150 test set for subjects
HCMP_4TEST_DN150 = HCMP_4TEST_DN150.HCMP_4TEST_DN150_2; 
HS_4TEST_DN150 = load('HS_4TEST_DN150_2.mat'); %Denoised 150 test set for subjects
HS_4TEST_DN150 = HS_4TEST_DN150.HS_4TEST_DN150_2; 

if  exist('test_imgs_2') ~= 7
    mkdir('test_imgs_2');
end

cd 'test_imgs_2';

number_patients = length(HCMP_4TESTR_CLEAN);
number_hsubjects = length(HS_4TESTR_CLEAN);
phases_p = ["diastole","systole"];
phases_h = ["diastole","SS","systole"];
sequences = ["SE","STEAM"];

%STORAGE OF PATIENT DATA
for p=1:number_patients
    namedir = strcat('p',int2str(p));
    mkdir(namedir);
    cd(namedir);   
    for ph=1:length(phases_p)
        mkdir(phases_p(ph)); %Create phase folder
        cd(phases_p(ph));
        for seq=1:length(sequences)
            mkdir(sequences(seq)); %Create sequence folder
            cd(sequences(seq));            
            %"NOISY" case
            diffusiondata = HCMP_4TESTR_CLEAN{p,1}.(phases_p(ph)).(sequences(seq)).diffusiondata;
            acquisitions_150 = {};
            indexes_150 = [];
            
            %The 150 images need to be added to each 450 average (it's that
            %or the b0, that have been removed)
            
            for j=1:size(diffusiondata,3) %Average            
                for i=1:size(diffusiondata,2) %Directions 
                    if ~isempty(diffusiondata{1,i,j}) %If not empty                 
                        if(diffusiondata{1,i,j}.b_pres == 150)
                            acquisitions_150 = [acquisitions_150; diffusiondata(1,:,j)];
                            indexes_150 = [indexes_150,j];
                            diffusiondata(1,:,j)=cell(1,7); %We blank this in our dataset 
                            break; %We get out (we already have this average)
                        end
                    end    
                end
            end
            
            n_averages_150 = size(acquisitions_150,1);
            
            for j=1:size(diffusiondata,3) %Average
                if ~ismember(j,indexes_150) %We ignore the 150 indexes
                    mkdir(strcat('average_',int2str(j)));
                    cd(strcat('average_',int2str(j)));
                    mkdir('diffusion_images'); 
                    cd('diffusion_images');
                    random_150 = randi(n_averages_150);

                    for i=1:size(diffusiondata,2) %Directions   
                        if ~isempty(diffusiondata{1,i,j})
                        name = strcat('noisy',int2str(p),'_',phases_p(ph),'_',sequences(seq),'_',int2str(j),'_450_',int2str(i),'.dcm');
                        imag = diffusiondata{1,i,j}.data;
                        zeropix = imag<0;
                        imag(zeropix) = 0;
                        dicomwrite(uint16(imag),name,diffusiondata{1,i,j}.info,'WritePrivate',true);
                        end
                        if (~isempty(acquisitions_150{random_150,i}))&&(i~=1)
                        %Write the 150 images
                         name = strcat('noisy',int2str(p),'_',phases_p(ph),'_',sequences(seq),'_',int2str(j),'_150_',int2str(i),'.dcm');
                         imag = acquisitions_150{random_150,i}.data;
                         zeropix = acquisitions_150{random_150,i}.data<0;
                         imag(zeropix) = 0;
                         dicomwrite(uint16(imag),name,acquisitions_150{random_150,i}.info,'WritePrivate',true);                   
                        end  
                    end
                    %There needs to be 12 images (minimum: 6 directions each)
                    %We erase the folder otherwise
                    numfiles = length(dir('*.dcm'));
                    cd .. %Out of diffusion_images
                    cd .. %Out of this particular average
%                     if numfiles<12
%                         rmdir(strcat('average_',int2str(j)),'s');
%                     end
                end
            end
                       
            %DENOISED case
                          
            diffusiondata_450 = HCMP_4TEST_DN450{1,p}.(phases_p(ph)).(sequences(seq)).diffusiondata; 
            diffusiondata_150 = HCMP_4TEST_DN150{1,p}.(phases_p(ph)).(sequences(seq)).diffusiondata; 
            
            n_averages_150 = size(diffusiondata_150,1); %Number of 150 images

            for j=1:size(diffusiondata_450,1) %Averages
                mkdir(strcat('average_denoised_',int2str(j)));
                cd(strcat('average_denoised_',int2str(j)));
                mkdir('diffusion_images');
                cd('diffusion_images');  
                for i=1:size(diffusiondata_450,2) %Directions
                    if ~isempty(diffusiondata_450{j,i})
                    name = strcat('noisy',int2str(p),'_',phases_p(ph),'_',sequences(seq),'_',int2str(j),'_450_',int2str(i),'.dcm');
                    imag = diffusiondata_450{j,i}.im;
                    zeropix = imag<0;
                    imag(zeropix) = 0;
                    dicomwrite(uint16(imag),name,diffusiondata_450{j,i}.info,'WritePrivate',true);
                    end
                    random_150 = randi(n_averages_150);
                    if ~isempty(diffusiondata_150{random_150,i})
                    name = strcat('noisy',int2str(p),'_',phases_p(ph),'_',sequences(seq),'_',int2str(j),'_150_',int2str(i),'.dcm');
                    imag = diffusiondata_150{random_150,i}.im;
                    zeropix = imag<0;
                    imag(zeropix) = 0;                    
                    dicomwrite(uint16(imag),name,diffusiondata_150{random_150,i}.info, 'WritePrivate',true);
                    end
                end
                %There needs to be 12 images (minimum: 6 directions each)
                %We erase the folder otherwise
                numfiles = length(dir('*.dcm'));
                cd .. %Out of diffusion_images
                cd .. %Out of this particular average
                if numfiles<12
                    rmdir(strcat('average_denoised_',int2str(j)),'s');
                end
            end           
            cd ..
        end
        cd ..
    end
    cd ..    
end

%STORAGE OF HEALTHY SUBJECTS 
for p=1:number_hsubjects
    namedir = strcat('h',int2str(p));
    mkdir(namedir);
    cd(namedir);   
    for ph=1:length(phases_h)
        mkdir(phases_h(ph)); %Create phase folder
        cd(phases_h(ph));
        for seq=1:length(sequences)
            mkdir(sequences(seq)); %Create sequence folder
            cd(sequences(seq));            
            %"NOISY" case
            diffusiondata = HS_4TESTR_CLEAN{p,1}.(phases_h(ph)).(sequences(seq)).diffusiondata;
            acquisitions_150 = {};
            indexes_150 = [];
            
            %The 150 images need to be added to each 450 average (it's that
            %or the b0, that have been removed)
            
            for j=1:size(diffusiondata,3) %Average            
                for i=1:size(diffusiondata,2) %Directions 
                    if ~isempty(diffusiondata{1,i,j}) %If not empty                 
                        if(diffusiondata{1,i,j}.b_pres == 150)
                            acquisitions_150 = [acquisitions_150; diffusiondata(1,:,j)];
                            indexes_150 = [indexes_150,j];
                            diffusiondata(1,:,j)=cell(1,7); %We blank this in our dataset 
                            break; %We get out (we already have this average)
                        end
                    end    
                end
            end
            
            n_averages_150 = size(acquisitions_150,1);
            
            for j=1:size(diffusiondata,3) %Average
                if ~ismember(j,indexes_150) %We ignore the 150 indexes
                    mkdir(strcat('average_',int2str(j)));
                    cd(strcat('average_',int2str(j)));
                    mkdir('diffusion_images'); 
                    cd('diffusion_images');
                    random_150 = randi(n_averages_150);

                    for i=1:size(diffusiondata,2) %Directions   
                        if ~isempty(diffusiondata{1,i,j})
                        name = strcat('noisy',int2str(p),'_',phases_h(ph),'_',sequences(seq),'_',int2str(j),'_450_',int2str(i),'.dcm');
                        imag = diffusiondata{1,i,j}.data;
                        zeropix = imag<0;
                        imag(zeropix) = 0;  
                        dicomwrite(uint16(imag),name,diffusiondata{1,i,j}.info,'WritePrivate',true);
                        end
                        if ~isempty(acquisitions_150{random_150,i})&&(i~=1)
                        %Write the 150 images
                         name = strcat('noisy',int2str(p),'_',phases_h(ph),'_',sequences(seq),'_',int2str(j),'_150_',int2str(i),'.dcm');
                         imag = acquisitions_150{random_150,i}.data;
                         zeropix = imag<0;
                         imag(zeropix) = 0;                          
                         dicomwrite(uint16(imag),name,acquisitions_150{random_150,i}.info,'WritePrivate',true);                   
                        end  
                    end
                %There needs to be 12 images (minimum: 6 directions each)
                %We erase the folder otherwise
                numfiles = length(dir('*.dcm'));
                cd .. %Out of diffusion_images
                cd .. %Out of this particular average
%                 if numfiles<12
%                     rmdir(strcat('average_',int2str(j)),'s');
%                 end
                end
            end
                       
            %DENOISED case
                
            diffusiondata_450 = HS_4TEST_DN450{1,p}.(phases_h(ph)).(sequences(seq)).diffusiondata; 
            diffusiondata_150 = HS_4TEST_DN150{1,p}.(phases_h(ph)).(sequences(seq)).diffusiondata; 
            
            n_averages_150 = size(diffusiondata_150,1); %Number of 150 images

            for j=1:size(diffusiondata_450,1) %Averages
                mkdir(strcat('average_denoised_',int2str(j)));
                cd(strcat('average_denoised_',int2str(j)));
                mkdir('diffusion_images');
                cd('diffusion_images');  
                for i=1:size(diffusiondata_450,2) %Directions
                    if ~isempty(diffusiondata_450{j,i})
                    name = strcat('noisy',int2str(p),'_',phases_h(ph),'_',sequences(seq),'_',int2str(j),'_450_',int2str(i),'.dcm');
                    imag = diffusiondata_450{j,i}.im;
                    zeropix = imag<0;
                    imag(zeropix) = 0;      
                    dicomwrite(uint16(imag),name,diffusiondata_450{j,i}.info,'WritePrivate',true);
                    end
                    random_150 = randi(n_averages_150);
                    if ~isempty(diffusiondata_150{random_150,i})
                    name = strcat('noisy',int2str(p),'_',phases_h(ph),'_',sequences(seq),'_',int2str(j),'_150_',int2str(i),'.dcm');
                    imag = diffusiondata_150{random_150,i}.im;
                    zeropix = imag<0;
                    imag(zeropix) = 0;                      
                    dicomwrite(uint16(imag),name,diffusiondata_150{random_150,i}.info, 'WritePrivate',true);
                    end
                end
                %There needs to be 12 images (minimum: 6 directions each)
                %We erase the folder otherwise
                numfiles = length(dir('*.dcm'));
                cd .. %Out of diffusion_images
                cd .. %Out of this particular average
                if numfiles<12
                    rmdir(strcat('average_denoised_',int2str(j)),'s');
                end
            end           
            cd ..
        end
        cd ..
    end
    cd ..    
end




