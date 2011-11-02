
for b = 2:10
    switch b
        case 2
            thePath.block = fullfile(thePath.data, 'ST03_bl18'); % ITEM
            tfile = 'ain.2.out.txt';
            condtype = 'ITEM';
        case 3
            thePath.block = fullfile(thePath.data, 'ST03_bl29'); % ITEM
            tfile = 'ain.3.out.txt';
            condtype = 'ITEM';
        case 4
            thePath.block = fullfile(thePath.data, 'ST03_bl30'); % ASSOC
            tfile = 'ain.4.out.txt';
            condtype = 'ASSOC';
        case 5
            thePath.block = fullfile(thePath.data, 'ST03_bl31'); % ASSOC
            tfile = 'ain.5.out.txt';
            condtype = 'ASSOC';
        case 6
            thePath.block = fullfile(thePath.data, 'ST03_bl32'); % ITEM
            tfile = 'ain.6.out.txt';
            condtype = 'ITEM';
        case 7
            thePath.block = fullfile(thePath.data, 'ST03_bl65'); % ITEM (monset suspect)
            tfile = 'ain.7.out.txt';
        case 8
            thePath.block = fullfile(thePath.data, 'ST03_bl66'); % ASSOC
            tfile = 'ain.8.out.txt';
            condtype = 'ASSOC';
        case 9
            thePath.block = fullfile(thePath.data, 'ST03_bl69'); % ASSOC
            tfile = 'ain.9.out.txt';
            condtype = 'ASSOC';
        case 10
            thePath.block = fullfile(thePath.data, 'ST03_bl69'); % ITEM (do not use for now)
            tfile = 'ain.10.out.txt';
    end
    cd(thePath.block);
    mdat = [];
    mmin = [];
    mmax = [];
    for n = 1:64
        gname = ['gdat_' num2str(n)];
        load([gname '.mat']);
        eval(['g = ' gname ';']);
        mdat = [mdat mean(g)];
        mmin = [mmin min(g)];
        mmax = [mmax max(g)];
        clear(gname);
    end
    bdat(b,:) = mdat;
    bmin(b,:) = mmin;
    bmax(b,:) = mmax;
end





