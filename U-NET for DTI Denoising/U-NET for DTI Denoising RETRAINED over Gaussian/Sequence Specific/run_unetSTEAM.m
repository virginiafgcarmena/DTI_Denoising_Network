maxNumCompThreads(12);
data = load('UNET_STEAM');
data = data.UNET_STEAM;
[trained_network_STEAM, info_STEAM] = train_unetSTEAM(data, 0.9,0);
save('trained_network_STEAM','trained_network_STEAM');
save('info_STEAM','info_STEAM');