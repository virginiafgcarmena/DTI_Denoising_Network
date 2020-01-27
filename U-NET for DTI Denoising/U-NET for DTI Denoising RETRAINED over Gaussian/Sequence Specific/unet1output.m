classdef unet1output < nnet.layer.RegressionLayer
        
    properties %Layer properies
        
    end
 
    methods
        function layer = unet1output(name)  %Construction Function
            if nargin == 1
                layer.Name = name;
            end
            
            layer.Description = "U-Net Output Layer";
        end

        function loss = forwardLoss(layer, Y, T)
            %L1 Loss
            %Mean absolute value betweeen pixels
            %Just in case our network contains more than 1 channel, we do
            %the mean absolute values between pixels of the same image in
            %each of the channels
            %We divide by the number of mini-batches (4th dimension)
            
            n_pixels = size(Y,1)*size(Y,2);
            averaged_img = sum(sum((Y-T).^2),2);
            loss = (1/n_pixels)*sum(averaged_img,4)/size(Y,4);
            %loss = sum(averaged_img,4)/size(Y,4);
            % Return the loss between the predictions Y and the 
            % training targets T.
            %
            % Inputs:
            %         layer - Output layer
            %         Y     – Predictions made by network
            %         T     – Training targets
            %
            % Output:
            %         loss  - Loss between Y and T

            % Layer forward loss function goes here.
            
            
        end
        
        function dLdY = backwardLoss(layer, Y, T)
            % Backward propagate the derivative of the loss function.
            % Inputs: layer - Output layer, Y–Predictions made by network, T– Training targets
            % Output: dLdY  - Derivative of the loss with respect to the predictions Y        
            % Loss is calculated over ALL mini batches
            
            %Loss L1
            minib = size(Y,4);
            dLdY = (2*(Y-T)/(size(Y,1)*size(Y,2)))/minib;
            
        end
    end
end