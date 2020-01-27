maxNumCompThreads(12);
data = load('UNET_STEAM');
data = data.UNET_STEAM;
net = load('trained_network_STEAM.mat');
net = net.trained_network_STEAM;
[retrained_network_STEAM, info_ret_STEAM] = retrain_unetSTEAM(data, net,0.9,0);
save('retrained_network_STEAM','retrained_network_STEAM');
save('info_STEAM','info_ret_STEAM');