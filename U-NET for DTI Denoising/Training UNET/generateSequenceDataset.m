%EXTRACT SE or STEAM datasets

UNET_WHOLE_6 = load('UNET_WHOLE_6');
UNET_WHOLE_6 = UNET_WHOLE_6.UNET_WHOLE_6;

%The sequence is in the 5th element of the tag

UNET_SE = cell(1,3);
UNET_STEAM = cell(1,3);

for i=1:size(UNET_WHOLE_6,1)
    
   tag = num2str(UNET_WHOLE_6{i,3});
   if tag(5) == '1' %SE
       UNET_SE = [UNET_SE; UNET_WHOLE_6(i,:)];
   end
   if tag(5) == '2' %SE
       UNET_STEAM = [UNET_STEAM; UNET_WHOLE_6(i,:)];
   end   
    
end