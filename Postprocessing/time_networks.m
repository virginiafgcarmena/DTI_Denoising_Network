image_yse = imread('image_yse.png');
image_yse = single(image_yse);
image_test = image_yse(:,:,1);

SE_95SSIM5MAE = load("D:\Documentos\MSC_IMPERIAL\Project\Virginia_data\SCRIPTS\U-NET\Run_HPC\RETRAINED_FGAUSS\AVERAGES_4\NORES_SSIM95_5MAE\SE and STEAM separated Networks\UNETSE_RETGA_E30_MB15_LR01_DF98-1_SD_MO98_SSIM95MAE5_nores.mat");
SE_95SSIM5MAE = SE_95SSIM5MAE.trained_network;
SE_9SSIM1MAE = load("D:\Documentos\MSC_IMPERIAL\Project\Virginia_data\SCRIPTS\U-NET\Run_HPC\RETRAINED_FGAUSS\AVERAGES_4\NORES_SSIM9_1MAE\SE_STEAM_Separated_Networks\UNETSE_RETGA_E30_MB15_LR01_DF98-1_SD_MO98_SSIM9MAE1_nores.mat");
SE_9SSIM1MAE = SE_9SSIM1MAE.trained_network;
SE_0SSIM1MAE = load("D:\Documentos\MSC_IMPERIAL\Project\Virginia_data\SCRIPTS\U-NET\Run_HPC\RETRAINED_FGAUSS\AVERAGES_4\RES_SSIM0_MAE1\SE and STEAM Separated Networks\UNETSE_RETGA_E40_MB15_LR01_DF98-1_SD_MO1_1MAE_0SSIM.mat");
SE_0SSIM1MAE = SE_0SSIM1MAE.trained_network;
ynet_SE_SSIM95MAE5 = load("D:\Documentos\MSC_IMPERIAL\Project\Virginia_data\SCRIPTS\Y-NET\TRAINED_YNETS\SSIM95MAE5\ynet_SE_SSIM95MAE5.mat");
ynet_SE_SSIM95MAE5 = ynet_SE_SSIM95MAE5.ynet_SE_SSIM95MAE5;
ynet_SE_SSIM9MAE1 = load("D:\Documentos\MSC_IMPERIAL\Project\Virginia_data\SCRIPTS\Y-NET\TRAINED_YNETS\SSIM9MAE1\ynet_SE_SSIM9MAE1.mat");
ynet_SE_SSIM9MAE1 = ynet_SE_SSIM9MAE1.ynet_SE_SSIM9MAE1;
ynet_SE_SSIM0MAE1_res = load("D:\Documentos\MSC_IMPERIAL\Project\Virginia_data\SCRIPTS\Y-NET\TRAINED_YNETS\SSIM0MAE1\ynet_SE_SSIM0MAE1_res.mat");
ynet_SE_SSIM0MAE1_res = ynet_SE_SSIM0MAE1_res.ynet_SE_SSIM0MAE1_res;

disp('95/5');
tic
image_955 = predict(SE_95SSIM5MAE,image_test);
toc

disp('9/1');
tic
image_91 = predict(SE_9SSIM1MAE,image_test);
toc

disp('0/1');
tic
noise_image_955 = predict(SE_0SSIM1MAE,image_test);
toc

disp('NLM');
tic
dosmo = degreeOfSmoothing(image_test);
image_NLM = imnlmfilt(image_test,'ComparisonWindowSize',3,'SearchWindowSize',27,'DegreeOfSmoothing',dosmo*4);
toc

disp('YNET 95')
tic
image_y95 = predict(ynet_SE_SSIM95MAE5, image_yse);
toc

disp('YNET 9/1')
tic
image_y91 = predict(ynet_SE_SSIM9MAE1, image_yse);
toc

disp('YNET 0/1');
tic
image_y01 = predict(ynet_SE_SSIM0MAE1_res, image_yse);
toc

function out = degreeOfSmoothing(imag)

    h = [1,-2,1;-2,4,-2;1,-2,1]; %Fast Noie Variance Estimation, John Immerker (1995) Elsevier. 
    c = conv2(imag,h);
    out = sqrt((1/(36*(size(imag,1)-2)*(size(imag,2)-2)))*sum(c(:).^2));

end