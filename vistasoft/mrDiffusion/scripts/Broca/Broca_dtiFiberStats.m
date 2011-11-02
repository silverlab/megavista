% for computing FA on a fiber group

baseDir = '//snarp/u1/data/reading_longitude/dti_adults';%on teal
%baseDir = 'U:\data\reading_longitude\dti_adults';% on cyan
%baseDir = '//snarp/u1/data/reading_longitude/dti'; % for kids, if needed

f = {'ab050307','as050307','aw040809','bw040806','bw040922','gm050308',...
        'jl040902','ka040923','mbs040503','mbs040908','me050126','mz040604','mz040828',...
        'pp050208','pp050228','rd040630','sn040831','sp050303'};% 14 subjects 6 directions only (add rd040901?). run again for 23?
%f = {'mbs040503'}; %for debug
%f = findSubjects('','',{'mb040927'}); % for kids

nFibers = zeros(length(f),1);
nCoordsWM = zeros(length(f),1);
maxLength = zeros(length(f),1);
minLength = zeros(length(f),1);
meanLength = zeros(length(f),1);
medianLength = zeros(length(f),1);
stdLength = zeros(length(f),1);
histLengthFibers = zeros(length(f),20);

for(ii=1:length(f))
    %fname = f{ii}; %for kids when using findsubjects
    fname = fullfile(baseDir, f{ii}, [f{ii} '_dt6_acpc_2x2x2mm.mat']);
    disp(['Processing ' fname '...']);
    dt = load(fname);
    dt.dt6(isnan(dt.dt6)) = 0;
    dt.xformToAcPc = dt.anat.xformToAcPc*dt.xformToAnat;

    fg = dtiReadFibers;
    
    fgFA = dtiGetValFromFibers(dt.dt6, fg, inv(dt.xformToAcPc), 'FA');
    
    % mean fa across all fibers
    for(ii=1:length(fgFA))
        %badVal = [fgFA{ii}<=0];
        %if(any(badVal))
        %   fprintf('%d is zero (fiber length %d)\n', find(badVal), length(fgFA{ii}));
        %end
        % Sometimes a fiber endpoint (index 1 or end-1) has an ill-defined
        % FA because it is up against the brain mask. So, we drop the
        % endpoints from analysis.
        fiberFA(ii) = mean(fgFA{ii}(2:end-1));
    end
    grandMeanFA = mean(fiberFA);
    fiberLen = cellfun('length', fgFA);
    figure;
    % fiber length-to-FA scatterplot
    plot(fiberLen, fiberFA, '.');
    % histogram of fibers
    hist(fiberFA, 50);
    
    %Get stats
    fibers = fg.fibers;
    nFibers(ii) = length(fibers);
    lengths = zeros(1,nFibers(ii));
    for(i_fiber = 1:nFibers(ii))
        fiber = fibers{i_fiber};
        lengths(i_fiber) = length(fiber);
    end
    maxLength(ii) = max(lengths)
    minLength(ii) = min(lengths)
    meanLength(ii) = mean(lengths)
    medianLength(ii) = median(lengths)
    stdLength(ii) = std(lengths)
    histLengthFibers(ii,:) = hist(lengths,20);
    save(fullfile(baseDir, 'AdultsWholeBrainStats.mat'), 'f', 'nCoordsWM', 'nFibers', 'maxLength', 'minLength',...
        'meanLength', 'medianLength', 'stdLength', 'histLengthFibers');
    clear fg lengths fibers mask roi wm x y z dt;
end
