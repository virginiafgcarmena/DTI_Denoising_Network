%Process Virginia output data stats
clear
clc
cd ('/Users/as443/Documents/Students/Virginia/SCMR')
load raw_data_comparison.mat

combinationsmatrix=[1 2; 1 3; 1 4; 2 3; 2 4; 3 4];
BFcorrfact=size(combinationsmatrix, 1);
genericlabels={'UNET', 'NLM', 'YNET', 'Groundtruth'};
variables={'FA', 'MD', 'HA-Endo', 'HA-Epi', 'HAG', 'E2A', 'NegEV'};

% subindex=1:size(raw, 1);    %find(isSE)
subindex=find(~isSE);
disp('FOR STEAM');
% disp('FA');
for indv=1:numel(variables)
    
    ctable=raw(subindex,(1+(indv-1)*4):(indv*4));
    disp(variables{indv})
    ctable.Properties.VariableNames=genericlabels;
    % rm=fitrm(ctable(find(~isSE),:), 'UNET-Groundtruth ~ 1');
    rm=fitrm(ctable, 'UNET-Groundtruth ~ 1');
    ranovatbl = ranova(rm);
    disp(['1-way repeated measures ANOVA p=', num2str(ranovatbl.pValue(1))]);
    for ind=1:size(combinationsmatrix, 1)

        [h, p]=ttest(table2array(ctable(:,combinationsmatrix(ind,1))), table2array(ctable(:,combinationsmatrix(ind,2))));
        p=p*BFcorrfact;
        if(p<0.05)
            addition='***';
        else
            addition='';
        end
        disp([addition, '  ', genericlabels{combinationsmatrix(ind,1)}, ' vs. ', genericlabels{combinationsmatrix(ind,2)}, ' p=', num2str(p)]);
    end
    disp('--')
end     %indv