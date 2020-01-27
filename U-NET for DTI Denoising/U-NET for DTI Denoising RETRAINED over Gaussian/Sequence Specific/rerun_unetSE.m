maxNumCompThreads(12);
data = load('UNET_SE_6');
data = data.UNET_SE_6;
net = load('trained_network_SE.mat');
net = net.trained_network_SE;
[retrained_network_SE, info_ret_SE] = retrain_unetSE(data, net,0.9,0);
save('retrained_network_SE','retrained_network_SE');
save('info_SE','info_ret_SE');