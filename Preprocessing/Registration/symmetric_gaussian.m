%Creates a 2-Dimensional symmetric Gaussian function

function out = symmetric_gaussian(nc,nr,sigma)

%nc: number of columns(total output will be size 2nc)
%nr: number of rows (total output will be size 2nr)
%sigma: standard deviation of the gaussian

[x1,x2] = meshgrid(1:2*nc,1:2*nr);
out =  1/(2*sigma^2)*exp(-(((x1-1).^2)/sigma)-(((x2-1).^2)/sigma)); %1st quadrant gaussian

%Second quadrant Gaussian (upper right)
[q2x1,q2x2] = meshgrid(nc:2*nc,1:nr); 
q2x1 = ones(size(q2x1))*max(q2x1(:))-q2x1+1; %Second quadrant variables (ascending from corner to center)

out(1:nr,nc:size(out,2))= 1/(2*sigma^2)*exp(-(((1-(q2x1-1)).^2)/sigma)-(((q2x2-1).^2)/sigma));

%Third quadrant Gaussian (lower left)
[q3x1,q3x2] = meshgrid(1:nc,nr:2*nr); 
q3x2 = ones(size(q3x2))*max(q3x2(:))-q3x2+1; %Third quadrant variables (ascending from corner to center)
out(nr:size(out,1),1:nc)= 1/(2*sigma^2)*exp(-(((q3x1-1).^2)/sigma)-(((1-(q3x2-1)).^2)/sigma));

%Fourth quadrant Gaussian (lower right)
[q4x1,q4x2] = meshgrid(nc:2*nc,nr:2*nr);
q4x1 = ones(size(q4x1))*max(q4x1(:))-q4x1+1; %Fourth quadrant variables (ascending from corner to center)
q4x2 = ones(size(q4x2))*max(q4x2(:))-q4x2+1; %Fourth quadrant variables (ascending from corner to center)
out(nr:size(out,1),nc:size(out,2))= 1/(2*sigma^2)*exp(-(((1-(q4x1-1)).^2)/sigma)-(((1-(q4x2-1)).^2)/sigma));

end