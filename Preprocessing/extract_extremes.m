%Extract_extremes
%Author: Virginia Fernandez (2019)
%MSc Project. Dataset processing. 
%Extracts the maximum and minimum values of a specific (subject, phase,
%sequence) dataset
%Arguments:
%dataset: Diffusion data of a subject, phase and sequence
%Output:
%max_to, min_to: minimum and maximums



function [max_to,min_to] = extract_extremes(dataset)

    max_to = 0;
    min_to = 500; 
    
    for i=1:size(dataset,2)
        for j=1:size(dataset,3)
            if ~isempty(dataset{1,i,j})
                image = dataset{1,i,j}.data;
                max_i = max(image(:));
                min_i = min(image(:));
                if max_to<max_i
                    max_to = max_i;
                end
                if min_to>min_i
                    min_to = min_i;
                end
            end
        end   
    end    
end