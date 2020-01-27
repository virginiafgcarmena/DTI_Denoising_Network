maxNumCompThreads(12);

%Load data
data = load('UNET_WHOLE');
data = data.UNET_WHOLE;

%Load network
net = load('GAUSS_E40_MB15_LR01_DF98-1_SD_MO1_SSIM3MAE7');
net = net.trained_network_gauss;
[trained_network, info] = retrain_unet1(net,data, 0.0455, 0.9,0);


save('UNET_E30_MB15_LR01_DF98-1_SD97_RES_MAE','trained_network');
save('UNET_E30_MB15_LR01_DF98-1_SD97_RES_MAE_info','info');
