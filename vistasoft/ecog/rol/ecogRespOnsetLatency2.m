clear,clc


BN{1}.sbj_name= 'CMM';BN{1}.block_name= 'ST07-07';BN{1}.ci= 40;
BN{2}.sbj_name= 'AC';BN{2}.block_name= 'AC0210_05';BN{2}.ci= 33;
BN{3}.sbj_name= 'RMM';BN{3}.block_name= 'STA06_47';BN{3}.ci= 45;
cl{1}='m';
cl{2}='y';
cl{3}='c';

%% category and threshold
categName= 'rest';
thr= 1.5;

for ii= 1:length(BN)
    sbj_name= BN{ii}.sbj_name;
    block_name= BN{ii}.block_name;
    ci= BN{ii}.ci;
    %% Reading response onset latencies
    dir= sprintf('/users/MO/Codes/rest/%s/%s',sbj_name,block_name);
    load(sprintf('%s/rspOnset_%3.1f_%s_%s_%.2d.mat',dir,thr,block_name,categName,ci));%'rsp_onset','rsp_shf','mdn_shf','sem_mdn_shf'
    
    if 1==1
        figure(1),
        tmp_rsp= rsp_onset(~isnan(rsp_onset));
        tmp_rsp_shf= rsp_shf(~isnan(rsp_shf));
        hold on,plot(sort(tmp_rsp),100*[1:length(tmp_rsp)]/length(tmp_rsp),cl{ii},'MarkerSize',5,'LineWidth',2)
        hold on,plot(sort(tmp_rsp_shf),100*[1:length(tmp_rsp_shf)]/length(tmp_rsp_shf),cl{ii},'LineStyle','--','LineWidth',1)
        xlim([-0.2 5]), ylim([0 105])
        set(gca,'FontSize',14)
        xlabel('Response Onset Latency(sec)'),ylabel('Sorted trials (%)')
        legend('CMM','random','AC','random','RMM','random','Location','SouthEast')
        title('Response Onset Latency')
        %saving
%         fp= './figures/rspOnset_CM_AC_RM.tiff';
%         print('-f1','-dtiff',fp);
%         saveas(gcf,'./figures/rspOnset_CM_AC_RM','fig')
        
    end
    
    if 1==1
        fprintf('\n%d trials not responding out of %d:%5.2f percent\n',sum(isnan(rsp_onset)),length(rsp_onset),sum(isnan(rsp_onset))/length(rsp_onset))
        mdn= median(rsp_onset(~isnan(rsp_onset)));
        mn_rsp= mean(rsp_onset(~isnan(rsp_onset)));
        sd= std(rsp_onset(~isnan(rsp_onset)));
        semdn= 1.253* ( sd/sqrt(length(rsp_onset)-sum(isnan(rsp_onset)))); %standard error of median
        fprintf('\nResponse onset latency:\n Median:%4.3f+-%4.3f\n mean:%4.3f\n std:%4.3f \n\n',mdn,semdn,mn_rsp ,sd);
        
        fprintf('\nRandom ROL:\n Median:%4.3f+-%4.3f\n\n',mdn_shf,sem_mdn_shf);
    end
    
    if 1==1
        %"mean of X is less than mean of Y" (left-tailed test)
        [H pval]=ttest2(rsp_onset,rsp_shf(:),[],'left');
        if H==1,fprintf('\nROL is smaller than random for %s pval=%4.3f\n',block_name,pval),
        else,fprintf('\nROL is not smaller than random\n'),
        end
    end
    
end


