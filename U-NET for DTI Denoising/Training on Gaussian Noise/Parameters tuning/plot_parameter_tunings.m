%Loads the networks and plots their comparisons
%The names must be manually changed if they are modified

f = figure;

UNETG2000_SDGM = load('UNETG2000_SDGM');
UNETG2000_SDGM = UNETG2000_SDGM.trained_network_gauss;
UNETG2000_SDGM_info = load('UNETG2000_SDGM_info');
UNETG2000_SDGM_info = UNETG2000_SDGM_info.info_gauss;

UNETG2000_ADAM = load('UNETG2000_ADAM');
UNETG2000_ADAM = UNETG2000_ADAM.trained_network_gauss;
UNETG2000_ADAM_info = load('UNETG2000_ADAM_info');
UNETG2000_ADAM_info = UNETG2000_ADAM_info.info_gauss;

subplot(221);
plot(smooth(UNETG2000_SDGM_info.TrainingLoss(1:200), 30),'g');
hold on;
plot(smooth(UNETG2000_ADAM_info.TrainingLoss(1:200), 30),'r');
xlabel("Iterations");
ylabel("Loss");
legend("Training Loss SDGM", "Training Loss ADAM");
title("Influence of the Optimizer");

%MiniBatches

UNETG2000_MB5 = load('UNETG2000_MB5_info');
UNETG2000_MB5 = UNETG2000_MB5.info_gauss;
UNETG2000_MB10 = load('UNETG2000_MB10_info');
UNETG2000_MB10 = UNETG2000_MB10.info_gauss;
UNETG2000_MB15 = load('UNETG2000_MB15_info');
UNETG2000_MB15 = UNETG2000_MB15.info_gauss;
UNETG2000_MB25 = load('UNETG2000_MB25_info');
UNETG2000_MB25 = UNETG2000_MB25.info_gauss;

subplot(222);
plot(smooth(UNETG2000_MB5.TrainingLoss(1:150), 30),'g');
hold on;
plot(smooth(UNETG2000_MB10.TrainingLoss(1:150), 30),'r');
hold on;
plot(smooth(UNETG2000_MB15.TrainingLoss(1:150), 30),'b');
hold on;
plot(smooth(UNETG2000_MB25.TrainingLoss(1:150), 30),'m');
title("Influence of the Mini Batch Size");
legend("5", "10", "15", "25");
xlabel("Iterations");
ylabel("Loss");

UNETG2000_LR001 = load('UNETG2000_LR001_info');
UNETG2000_LR001 = UNETG2000_LR001.info_gauss;
UNETG2000_LR01 = load('UNETG2000_LR01_info');
UNETG2000_LR01 = UNETG2000_LR01.info_gauss;
UNETG2000_LR1 = load('UNETG2000_LR1_info');
UNETG2000_LR1 = UNETG2000_LR1.info_gauss;
UNETG2000_LR5 = load('UNETG2000_LR5_info');
UNETG2000_LR5 = UNETG2000_LR5.info_gauss;

subplot(223);
plot(smooth(UNETG2000_LR001.TrainingLoss(1:200), 30),'m');
hold on;
plot(smooth(UNETG2000_LR01.TrainingLoss(1:200), 30),'g');
hold on;
plot(smooth(UNETG2000_LR1.TrainingLoss(1:200), 30),'r');
hold on;
plot(smooth(UNETG2000_LR5.TrainingLoss(1:200), 30),'b');
title("Influence of the learning rate");
xlabel("Iterations");
ylabel("Loss");
legend("0.001","0.01", "0.1","0.5");

UNETG2000_WOCL = load('UNETG2000_WOCL_info');
UNETG2000_WOCL = UNETG2000_WOCL.info_gauss;

subplot(224);
plot(smooth(UNETG2000_SDGM_info.TrainingLoss(1:200), 30),'r');
hold on;
plot(smooth(UNETG2000_WOCL.TrainingLoss(1:200), 30),'b');
title("Influence of the Last Concatenation layer");
xlabel("Iterations");
ylabel("Loss");
legend("With the last layer", "Without the last layer");

figure

UNETG2000_DF9 = load('UNETG2000_DF9_info');
UNETG2000_DF9 = UNETG2000_DF9.info_gauss;
UNETG2000_DF5 = load('UNETG2000_DF5_info');
UNETG2000_DF5 = UNETG2000_DF5.info_gauss;
UNETG2000_DF1 = load('UNETG2000_DF1_info');
UNETG2000_DF1 = UNETG2000_DF1.info_gauss;
UNETG2000_DF01 = load('UNETG2000_DF01_info');
UNETG2000_DF01 = UNETG2000_DF01.info_gauss;

plot(smooth(UNETG2000_DF9.TrainingLoss(1:200), 30),'m');
hold on;
plot(smooth(UNETG2000_DF5.TrainingLoss(1:200), 30),'g');
hold on;
plot(smooth(UNETG2000_DF1.TrainingLoss(1:200), 30),'r');
hold on;
plot(smooth(UNETG2000_DF01.TrainingLoss(1:200), 30),'b');
title("Influence of the drop factor");
xlabel("Iterations");
ylabel("Loss");
legend("e-0.9","e-0.5", "e-0.1","e-0.01");


