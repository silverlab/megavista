% dti_MM_FindHomotopicFibers
%
%
%
%

bd = '/biac3/wandell4/data/reading_longitude/dti_adults/';

%d = dir([bd '*0*']); subDirs = {d.name};

subDirs = {'aab050307','ah051003','am090121','ams051015','as050307','aw040809','bw040922','ct060309','db061209','dla050311',...
   'gd040901','gf050826','gm050308','jl040902','jm061209','jy060309','ka040923','mbs040503','me050126','mo061209',...
   'mod070307','mz040828','pp050208','rfd040630','rk050524','sc060523','sd050527','sn040831','sp050303','tl051015'};

% subDirs = {'aab050307'};

distThresh = .1;
for ii = 1:numel(subDirs)
disp(['Processing ' subDirs{ii} '...']);
    dd = fullfile(bd, subDirs{ii}, 'dti06', 'fibers', 'conTrack');
    
    occlName = fullfile(dd,'occ_MORI_clean','Mori_Occ_CC_100k_top1000_LEFT');
    occrName = fullfile(dd,'occ_MORI_clean','Mori_Occ_CC_100k_top1000_RIGHT');
%     parlName = fullfile(dd,'par_MORI_clean', 'Mori_PostPar_CC_100k_top1000_LEFT');
%     parrName = fullfile(dd,'par_MORI_clean', 'Mori_PostPar_CC_100k_top1000_RIGHT');
%     templName = fullfile(dd,'temp_MORI_clean', 'Mori_Temp_CC_100k_top1000_LEFT');
%     temprName = fullfile(dd,'temp_MORI_clean', 'Mori_Temp_CC_100k_top1000_RIGHT');

    lName = {occlName};%, parlName, templName};
    rName = {occrName};%, parrName, temprName};
    
    for kk=1:length(lName)
        lfg  = dtiReadFibers(lName{kk});
        rfg  = dtiReadFibers(rName{kk});
        lEnd = zeros(3,numel(lfg.fibers));
        rEnd = zeros(3,numel(rfg.fibers));
           
        % NOTE: we assume that the callosal endpoint is 'end' rather than '1'.
        % This seems to be true, but we should check...
        for jj=1:numel(lfg.fibers) 
            lEnd(:,jj) = lfg.fibers{jj}(:,end-1);
        end
        for jj=1:numel(rfg.fibers) 
            rEnd(:,jj) = rfg.fibers{jj}(:,end);
        end
        [lInd, lDist] = nearpoints(lEnd, rEnd);
        [rInd, rDist] = nearpoints(rEnd, lEnd);
        lHomInds      = lDist<distThresh.^2;
        rHomInds      = rDist<distThresh.^2;
        
        fg            = dtiNewFiberGroup([lName{kk} '_hom'], [20 200 100], [], [], {lfg.fibers{unique(find(lHomInds))}});
        [fd fg.name]  = fileparts(fg.name); 
        dtiWriteFiberGroup(fg, (fullfile(fd, fg.name)));
        
        fg            = dtiNewFiberGroup([lName{kk} '_het'], [20 100 200], [], [], {lfg.fibers{unique(find(~lHomInds))}});
        [fd fg.name]  = fileparts(fg.name); 
        dtiWriteFiberGroup(fg, (fullfile(fd, fg.name))); 
        
        fg            = dtiNewFiberGroup([rName{kk} '_hom'], [100 200 20], [], [], {rfg.fibers{unique(find(rHomInds))}});
        [fd fg.name]  = fileparts(fg.name); 
        dtiWriteFiberGroup(fg, (fullfile(fd, fg.name))); 
        
        fg            = dtiNewFiberGroup([rName{kk} '_het'], [200 100 20], [], [], {rfg.fibers{unique(find(~rHomInds))}});
        [fd fg.name]  = fileparts(fg.name); 
        dtiWriteFiberGroup(fg, (fullfile(fd, fg.name))); 
    end
end
disp('Done.');