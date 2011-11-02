clear,clc

%% Defining variables in structure format
A.sbj(1).name= 'CMM';
A.sbj(1).block(1).name= 'ST07-03';
A.sbj(1).block(2).name= 'ST07-07';
A.sbj(1).elec= [40 41 37];

A.sbj(2).name= 'RMM';
A.sbj(2).block(1).name= 'ST06_43';
A.sbj(2).block(2).name= 'STA06_47';
A.sbj(2).elec= [45 46 35];

A.sbj(3).name= 'AC';
A.sbj(3).block(1).name= 'AC0210_03';
A.sbj(3).block(2).name= 'AC0210_05';
A.sbj(3).elec= [40 33 38 39 35 46];

%% category and threshold
categName= 'rest';
thr= 1.5;

kk=1;
%% Reading Response Onset Latencies (ROL)
for ij=1:3
    sbj_name= A.sbj(ij).name;
    elec= A.sbj(ij).elec;
    for ib=1:2
        block_name= A.sbj(ij).block(ib).name;
        dir= sprintf('./%s/%s',sbj_name,block_name);
        for ci = elec
            %loading variables: 'rsp_onset','rsp_shf','mdn_shf','sem_mdn_shf'
            load(sprintf('%s/rspOnset_%3.1f_%s_%s_%.2d.mat',dir,thr,block_name,categName,ci));
            
            mdn(kk)= median(rsp_onset(~isnan(rsp_onset)));
            sd= std(rsp_onset(~isnan(rsp_onset)));
            semdn(kk)= 1.253* ( sd/sqrt(length(rsp_onset)-sum(isnan(rsp_onset)))); %standard error of median
            mdnShf(kk)= mdn_shf;
            sem_mdnShf(kk)= sem_mdn_shf;
            
            if 1==2
                fprintf('\n%d trials not responding out of %d:%5.2f percent\n',sum(isnan(rsp_onset)),length(rsp_onset),sum(isnan(rsp_onset))/length(rsp_onset))
                mdn= median(rsp_onset(~isnan(rsp_onset)));
                mn_rsp= mean(rsp_onset(~isnan(rsp_onset)));
                sd= std(rsp_onset(~isnan(rsp_onset)));
                semdn= 1.253* ( sd/sqrt(length(rsp_onset)-sum(isnan(rsp_onset)))); %standard error of median
                fprintf('\nResponse onset latency:\n Median:%4.3f+-%4.3f\n mean:%4.3f\n std:%4.3f \n\n',mdn,semdn,mn_rsp ,sd);
                
                fprintf('\nRandom ROL:\n Median:%4.3f+-%4.3f\n\n',mdn_shf,sem_mdn_shf);
            end
                       
            clear 'rsp_onset' 'rsp_shf' 'mdn_shf' 'sem_mdn_shf'
            
            load(sprintf('./%s/%s/mnpower_rest-bgn0.5-0.0-4.5.mat',sbj_name,block_name))
            M_tmp= MP.elec(ci).mean;
            O_tmp= MP.elec(ci).overall;
            M_rest(kk)= M_tmp(7)/O_tmp(7); %gamma range
            clear MP
            
            kk= kk+1;
            
        end
    end
end

%Histogram of ROL
[ni]=histc(mdn,[0 .5 1 1.5 2 2.5]);
barh(0.25+[0 0.5 1 1.5 2 2.5],ni)
set(gca,'FontSize',14)
set(gca,'Xtick',[0 2 4 6 8])
set(gca,'Xticklabel',{'0' '2' '4' '6' '8'})
ylim([0 2.5])
xlim([0 8])
xlabel('Count')
%saveas(gcf,'./figures/ROL_hist','fig')
%print('-f1','-djpeg','./figures/ROL_hist.jpg')
%return
        
[R,pval]= corrcoef(M_rest,mdn);
r=[R(2,1) pval(2,1)]
B= regress(mdn',M_rest');
[P,S]= polyfit(M_rest,mdn,1);
x= linspace(min(M_rest)-0.1,max(M_rest)+0.1,100);
[y delta]= polyval(P,x,S);

mdnShf_sem= std(mdnShf);
%mdnShf_sem= std(mdnShf)/sqrt(length(mdnShf));
%mdnShf_sem= sqrt(sum(sem_mdnShf.^2));


figure(2),errorbar(M_rest,mdn,semdn,'ko','LineWidth',3,'MarkerSize',7)
line([min(M_rest)-0.1 max(M_rest)+0.1],[mean(mdnShf) mean(mdnShf)], ...
    'Color','g','LineStyle','-','LineWidth',3)
line([min(M_rest)-0.1 max(M_rest)+0.1],[mean(mdnShf)-mdnShf_sem mean(mdnShf)-mdnShf_sem], ...
    'Color','g','LineStyle',':','LineWidth',2)
line([min(M_rest)-0.1 max(M_rest)+0.1],[mean(mdnShf)+mdnShf_sem mean(mdnShf)+mdnShf_sem], ...
    'Color','g','LineStyle',':','LineWidth',2)
hold on, plot(x,y,'r-','LineWidth',1.5)
%H=shadedErrorBar(x,y,delta,'y-',0.9);
xlim([min(M_rest)-0.1 max(M_rest)+0.1])
ylim([0 2.5])
set(gca,'FontSize',14)
xlabel('Relative Gamma Power')
ylabel('Response Onset Latency (sec)')
text(1.25,2.4,sprintf('corr-coeff = %3.2f  (%4.3f)',r(1),r(2)),'FontSize',14)
%text(1.25,2.2,sprintf('regress-coeff= %3.1f, %3.1f',P(1),P(2)),'FontSize',14)
% saveas(gcf,'./figures/ROL_RGP','fig')
% print('-f2','-djpeg','./figures/ROL_RGP.jpg')
