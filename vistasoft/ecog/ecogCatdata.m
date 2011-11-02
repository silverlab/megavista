
clear
cd('/matlab_users/ECoG');
ecogpath
samplerate = 3051.76;

for t=1:2
    
idata = [];
adata = [];

    for b = 1:5
        switch b
            case 1
                thePath.block = fullfile(thePath.data, 'ST03_bl18'); % ITEM
                tfile = 'ain.2.out.txt';
                condtype = 'ITEM';
            case 2
                thePath.block = fullfile(thePath.data, 'ST03_bl29'); % ITEM
                tfile = 'ain.3.out.txt';
                condtype = 'ITEM';
            case 3
                thePath.block = fullfile(thePath.data, 'ST03_bl30'); % ASSOC
                tfile = 'ain.4.out.txt';
                condtype = 'ASSOC';
            case 4
                thePath.block = fullfile(thePath.data, 'ST03_bl31'); % ASSOC
                tfile = 'ain.5.out.txt';
                condtype = 'ASSOC';
            case 5
                thePath.block = fullfile(thePath.data, 'ST03_bl32'); % ITEM
                tfile = 'ain.6.out.txt';
                condtype = 'ITEM';
                % thePath.block = fullfile(thePath.data, 'ST03_bl65'); % ITEM (monset suspect)
                % tfile = 'ain.7.out.txt';
            case 6
                thePath.block = fullfile(thePath.data, 'ST03_bl66'); % ASSOC
                tfile = 'ain.8.out.txt';
                condtype = 'ASSOC';
            case 7
                thePath.block = fullfile(thePath.data, 'ST03_bl69'); % ASSOC
                tfile = 'ain.9.out.txt';
                condtype = 'ASSOC';
                % thePath.block = fullfile(thePath.data, 'ST03_bl69'); % ITEM (do not use for now)
                % tfile = 'ain.10.out.txt';
        end
        cd(thePath.block);
        fprintf([thePath.block '\n']);

        chandata = [];
        for q = 1:4
            startchan = (q-1)*(64/4)+1;
            endchan = startchan +(64/4)-1;
            switch t
                case 1 % HITS
                    % eegname = ['eeg_' num2str(startchan) 't' num2str(endchan) '.mat'];
                    eegname = ['filt100_eeg_' num2str(startchan) 't' num2str(endchan) '.mat'];
                case 2 % CR
                    % eegname = ['cr_eeg_' num2str(startchan) 't' num2str(endchan) '.mat'];
                    eegname = ['filt100_cr_eeg_' num2str(startchan) 't' num2str(endchan) '.mat'];
            end
            cd(thePath.block);
            eval(['load ' eegname]);
            chandata = cat(1,chandata,EEG.data);
        end
        fprintf([condtype ' ' num2str(size(chandata,3)) '\n\n']);
        if strcmp(condtype,'ITEM')
            idata = cat(3,idata,chandata);
        elseif strcmp(condtype,'ASSOC')
            adata = cat(3,adata,chandata);
        end
    end
    cd(thePath.data)
    switch t
        case 1
            save filt100_hits_allchans adata idata
        case 2
            save filt100_cr_allchans adata idata
    end
end

% save hits_allchans adata idata
% save filt_hits_allchans adata idata
% save cr_allchans adata idata
% save filt_cr_allchans adata idata






