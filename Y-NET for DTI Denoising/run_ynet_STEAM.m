%Y-Net runner for the STEAM, SE: STEAM training
%Author: Virginia Fernandez
%MSc Project - YNET 

maxNumCompThreads(1);

data = load('YNET_WHOLE_STEAM.mat');
data = data.YNET_WHOLE_STEAM;
% data = YNET_WHOLE_SE;
[ynet_STEAM, info_ynet_STEAM] = train_ynet_STEAM(data,0.7,0);

name_network = 'ynet_STEAM_SSIM95MAE5';
name_info = strcat(name_network, '_info');
save(name_network,'ynet_STEAM');
save(name_info,'info_ynet_STEAM');