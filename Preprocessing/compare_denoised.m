function compare_denoised(SUBJ,type,original_filename)

%Compares the number of images from Spin-Echo and STEAM sequences in either
%the patients or the healthy subjects.

switch type
    case 1 %Patients
        phases = ["diastole","systole"];
    case 2 %Healthy subjects
        phases = ["diastole","SS","systole"];
    otherwise
        error("Type can only be 1 - patients - or 2 - healthy subjects");
end

if exist('DENOISED_ANALYSIS')==7
     rmdir('DENOISED_ANALYSIS','s');
end
mkdir("DENOISED_ANALYSIS"); 

        for p=1:length(SUBJ) %Loop accross patients
            filename = fullfile('DENOISED_ANALYSIS',strcat(original_filename,int2str(p),'.xlsx'));
            for ph=1:length(phases) %Loop accross healthy subjects
                t = compare_denoised_single(SUBJ{p}.(phases(ph)).SE.diffusiondata, SUBJ{p}.(phases(ph)).STEAM.diffusiondata);
                writetable(t, filename, 'Sheet', ph, 'Range','B2');
            end
        end
end


function out = compare_denoised_single(SE,STEAM)

%Out is a table that contains the number of SE images and STEAM images for
%a specific diffusiondata dataset (patient, phases, sequence). 

SEv = []; STEAMv = [];
out = table(SEv,STEAMv);

if size(SE,2)~=size(STEAM,2)
    error("Mismatch of the direction size! The number of encoding directions must be the same (2nd dim).");
end

    for i=1:size(SE,2) %Directions (should be the same for SE and STEAM)
        countSE = 0;
        countSTEAM = 0;
        for j=1:size(SE,1)
            if ~isempty(SE{j,i})
                countSE = countSE+1;
            end
        end
        for j=1:size(STEAM,1)
            if ~isempty(STEAM{j,i})
                countSTEAM = countSTEAM+1;
            end
        end
        
        out = [out; {countSE,countSTEAM}];
    end    
end
