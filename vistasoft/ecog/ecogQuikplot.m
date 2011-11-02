
cd('/Volumes/Tweedledee/ECoG/data');
% load cr_allchans.mat

figure(1);
% set(1,'Position',[10         269        1665         943]);
set(1,'Position',[496         744        1170         454]);

% % ASSOC
% for chan = 1:64
%     ntrials = size(adata,3);
%     for trial = 1:24
%         if trial<=ntrials
%             subplot(6,4,trial);
%             plot(adata(chan,:,trial));
%         end
%     end
%     pause
% end

% % ITEM
% for chan = 1:64
%     ntrials = size(idata,3);
%     for trial = 1:54
%         if trial<=ntrials
%             subplot(9,6,trial);
%             plot(idata(chan,:,trial));
%         end
%     end
%     pause
% end

samplerate = 1000;
sonset = round(.5*samplerate);
bonset = round(.4*samplerate);
% load hits_allchans.mat;
load filt_hits_allchans.mat;

ahits = mean(adata,3); ahits = ahits(:,sonset:2000);
fprintf(['ahits ' num2str(size(adata,3)) '\n\n']);
        
ihits = mean(idata,3); ihits = ihits(:,sonset:2000);
fprintf(['ihits ' num2str(size(idata,3)) '\n\n']);

load filt_cr_allchans.mat;

acr = mean(adata,3); acr = acr(:,sonset:2000);
fprintf(['acr ' num2str(size(adata,3)) '\n\n']);

icr = mean(idata,3); icr = icr(:,sonset:2000);
fprintf(['icr ' num2str(size(idata,3)) '\n\n']);

% i = [11:16 21:24 37:39 47:52];
i = [14 37];
    
% bline = .4*samplerate;
for n = 1:length(i)
    chan = i(n)
    clf
    hold on
    plot(ahits(chan,:),'g-','LineWidth',2);
%     plot(ihits(chan,:),'g:','LineWidth',2);
    plot(acr(chan,:),'r-','LineWidth',2);
%     plot(icr(chan,:),'r:','LineWidth',2);
%     plot([sonset sonset],[-10*10^-5 5*10^-5],'m-');
%     plot([100 100],[-10*10^-5 25*10^-5],'b-');
    axis auto
    pause
end

