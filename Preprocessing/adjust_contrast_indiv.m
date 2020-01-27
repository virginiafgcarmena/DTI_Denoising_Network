%Adjust_contrast_indiv
%Author: Virginia Fernandez (2019)
%MSc Project. Dataset processing. 

%Adjusts subject/patient so that the heart is visible (improves contrast
%maintaining the scale). 
%The extremes are fetched with extract_extremes.m, so that the contrast
%between 150 and 450 images of the same (subject, phase, sequence) dataset
%are preserved. 
%Works directly on the main structure (HCM_patients or healthy_volunteers).

%Parameters
structure = HCM_patients; %Name of the structure
subject_number = 3;
phase = "diastole";
sequence = "SE";
map_in = [0, 40]; %We zero what's below, and set the maximum value of the dataset for what's above.
%Change the structure name if healthy subjects or other structure is being
%used
subject = structure{subject_number}.(phase).(sequence).diffusiondata;

[totalmax, totalmin] = extract_extremes(subject);

%Loop around the structure
for i=1:size(subject,2)
    for j=1:size(subject,3)       
        if ~isempty(subject{1,i,j})
            image = subject{1,i,j}.data;
            adjusted_sample_image = max(map_in(1),min(map_in(2),image));
            adjusted_sample_image = ((adjusted_sample_image-map_in(1))./(map_in(2)-map_in(1)))*(totalmax-totalmin)+totalmin;
            subject{1,i,j}.data =  adjusted_sample_image;
        end
    end
end

HCM_patients{subject_number}.(phase).(sequence).diffusiondata = subject;

for i=1:size(subject,3)
    if ~isempty(subject{1,5,i})
        figure; imshow(subject{1,5,i}.data,[]);
    end
end

