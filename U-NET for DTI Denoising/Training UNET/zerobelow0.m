function dataset = zerobelow0(dataset)

%Date: June 2019
%Author: Virginia Fernandez
%Removes pixels that are negative in value from the dataset and converts
%them to uint
%Shuffles

random_sort = randperm(numel(dataset(:,1)));
dataset = dataset(random_sort,:,:);

for i=1:size(dataset,1)
     
    noisy_image = dataset{i,1};
    denoised_image = dataset{i,2};
    
    noisy_image(find(noisy_image<0))=0;
    denoised_image(find(denoised_image<0))=0;
    
    dataset{i,1}=uint8(noisy_image);
    dataset{i,2}=uint8(denoised_image); 
    
   
    
end

end