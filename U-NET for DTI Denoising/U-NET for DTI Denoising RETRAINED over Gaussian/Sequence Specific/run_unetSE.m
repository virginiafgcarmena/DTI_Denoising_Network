maxNumCompThreads(12);
data = load('UNET_SE');
data = data.UNET_SE;
[trained_network_SE, info_SE] = train_unetSE(data, 0.9,0);
save('trained_network_SE','trained_network_SE');
save('info_SE','info_SE');