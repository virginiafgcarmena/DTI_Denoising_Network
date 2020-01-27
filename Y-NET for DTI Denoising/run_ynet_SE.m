%Y-Net runner for the SE,STEA:SE training
%Author: Virginia Fernandez
%MSc Project - YNET 

maxNumCompThreads(1);

data = load('YNET_WHOLE_SE.mat');
data = data.YNET_WHOLE_SE;
% data = YNET_WHOLE_SE;
[ynet_SE, info_ynet_SE] = train_ynet_SE(data,0.7,0);

name_network = 'ynet_SE_SSIM95MAE5';
name_info = strcat(name_network, '_info');
save(name_network,'ynet_SE');
save(name_info,'info_ynet_SE');