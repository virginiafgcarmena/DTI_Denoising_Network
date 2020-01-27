classdef unet1output < nnet.layer.RegressionLayer
        
    properties %Layer properies          
            n_bits; %Number of bits in a pixel (In case of SINGLE values)
            size_f; %Size filter (Regulated parameter). MUST BE AN ODD number
            k1; %Normalization coefficient variable 1
            k2; %Normalization coefficient variable 2
            %Coefficients
            c1; %Normalization coefficient 1
            c2; %Normalization coefficient 2  
    end
 
    methods   
         function layer = unet1output(name)  %Construction Function
                layer.Name = name;
                layer.n_bits = 8; %Number of bits in a pixel (In case of SINGLE values)
                layer.size_f = [120,88]; %Size filter (Regulated parameter). MUST BE AN ODD number
                layer.k1 = 0.01; %Normalization coefficient variable 1
                layer.k2 = 0.02; %Normalization coefficient variable 2
                %Coefficients
                layer.c1 = (layer.k1*2^layer.n_bits)^2; %Normalization coefficient 1
                layer.c2 = (layer.k2*2^layer.n_bits)^2; %Normalization coefficient 2                 
            
            layer.Description = "U-Net Output Layer";
         end
        
        function loss = forwardLoss(layer, Y, T)
            %L1 Loss
            %Mean absolute value betweeen pixels
            %Just in case our network contains more than 1 channel, we do
            %the mean absolute values between pixels of the same image in
            %each of the channels
            %We divide by the number of mini-batches (4th dimension)
            
            %SSIM 
            results = getSSIM(layer,Y,T);
            
            %Loss SSIM: Structural similarity is bigger when the images are
            %more similar, we want our loss to be opposite, thus:
            loss_SSIM = sum(1-results(:,:,:,:,1),4)/size(Y,4);
            
            n_pixels = size(Y,1)*size(Y,2);
            averaged_img = sum(sum(abs(Y-T),1),2);
            loss_MAE = (1/n_pixels)*sum(averaged_img,4)/size(Y,4);
            
            weights_MAE = 1;
            weights_SSIM = 0;           
            loss = weights_SSIM*loss_SSIM+weights_MAE*loss_MAE;
        
        end
        
        function dLdY = backwardLoss(layer, Y, T)
            % Backward propagate the derivative of the loss function.
            % Inputs: layer - Output layer, Y�Predictions made by network, T� Training targets
            % Output: dLdY  - Derivative of the loss with respect to the predictions Y        
            % Loss is calculated over ALL mini batches            
            
            %Get SSIM values again
            SSIMres = getSSIM(layer,Y,T);
            minib = size(Y,4); %Number of minibatches 
            
            individual_filter = fspecial('gaussian',layer.size_f,100); %Gaussian Filter 
            gaussian_f = repmat(individual_filter, [1,1,1,size(Y,4)]); %We repeat the filter along MB direction
            
            dldx = gpuArray(single(zeros(size(gaussian_f))));
            dcdx = gpuArray(single(zeros(size(gaussian_f))));
            dLdX = gpuArray(single(zeros(size(gaussian_f))));
            
            for i=1:size(gaussian_f,4) %Loop Minibatches
                dldx(:,:,:,i) = 2*gaussian_f(:,:,:,i)*(SSIMres(:,:,:,i,4)*SSIMres(:,:,:,i,2))/(SSIMres(:,:,:,i,4)^2+SSIMres(:,:,:,i,5)^2+layer.c1);
                dcdx(:,:,:,i) = (2/(SSIMres(:,:,:,i,6)^2+SSIMres(:,:,:,i,7)^2+layer.c2))*gaussian_f(:,:,:,i).*((T(:,:,:,i)-SSIMres(:,:,:,i,4))...
                -SSIMres(:,:,:,i,3)*(Y(:,:,:,i)-SSIMres(:,:,:,i,5)));
                dLdX(:,:,:,i) = -dldx(:,:,:,i)*SSIMres(:,:,:,i,3)-dcdx(:,:,:,i)*SSIMres(:,:,:,i,2);
            end            
            dLdY_SSIM =  -dLdX./minib; 
            
            %Loss MAE
            
            weights_MAE = 1.0;
            weights_SSIM = 0;
            dLdY_MAE = (sign(Y-T)/(size(Y,1)*size(Y,2)))/minib;
            dLdY = weights_SSIM*dLdY_SSIM+weights_MAE*dLdY_MAE;
        end      
    end
  
    methods (Access= public)
        function SSIMRes = getSSIM(layer,Y,T)         
            %Create a gaussian filter
            individual_filter = fspecial('gaussian',layer.size_f,100); %Gaussian Filter 
            gaussian_f = repmat(individual_filter, [1,1,1,size(Y,4)]); %We repeat the filter along MB direction
            
            %SSIM Value: means and standard deviations are needed             
            muT = filterImageCentralPixel(layer,gaussian_f,T); %Mean of targets
            muY = filterImageCentralPixel(layer,gaussian_f,Y); %Mean of predictions     
            sigmaT = filterImageCentralPixel(layer,gaussian_f,T.^2); %Variance of image 1
            sigmaY = filterImageCentralPixel(layer,gaussian_f,Y.^2); %Variance of image 2
            sigmaTY = filterImageCentralPixel(layer,gaussian_f,T.*Y); %Covariance  
            %Luminance component
            lp = (2*muT.*muY+layer.c1)./(muT.^2+muY.^2+layer.c1);  
            %Contrast similarity
            cs = (2*sigmaTY+layer.c2)./(sigmaT.^2+sigmaY.^2+layer.c2);  
            SSIM = lp.*cs;     
            
            SSIMRes = cat(5,SSIM,lp,cs,muY,muT,sigmaT,sigmaY,sigmaTY);
        end
        
        function filtered_value = filterImageCentralPixel(layer,gaussian_f, image_n)
             filtered_value = [];
             %Filters an image with the given filter centered at pixel p
             if length(size(image_n))==4 %If minibatch>1   
                 for i=1:size(image_n,4)
                     image_sing = image_n(:,:,:,i);
                     filtered_img = imfilter(image_sing, gaussian_f(:,:,:,i));
                     if isempty(filtered_value)
                        filtered_value = sum(filtered_img(:))/(size(filtered_img,1)*size(filtered_img,2));
                     else
                        filtered_value = cat(4,filtered_value,sum(filtered_img(:))/(size(filtered_img,1)*size(filtered_img,2)));
                     end
                 end
             end
        end

        function p = findCentralPixel(layer,image1)
        %Finds the central pixel of an image, defaults one of the two
        %central pixels in even sized images (smaller). 
        %Returns p, a vector with two coordinates.   
            sx = size(image1,2);
            sy = size(image1,1);
            
            if mod(sx,2)==0 %Even
                x = sx/2;   
            else
                x = ceil(sx/2); %Odd
            end
            if mod(sy,2)==0 %Even
                y = sy/2;   
            else
                y = ceil(sy/2); %Odd
            end
            p = [x,y];
        end        
    end 
end