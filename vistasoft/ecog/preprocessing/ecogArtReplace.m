function outMat = ecogArtReplace(par,elecs,doreplace,threshstd,rejectwins,showme)
% Removing artifacts
% outMat = cogArtReplace(par,elecs,doreplace,threshstd,rejectwins)
% Suggested parameters: outMat = ecogArtReplace(par,elecs,1,5,0,1);
%  Replace waveform values that exceed threshold with mean of artifact
%  start&endpoints. Like chopping off the peak.
%  doreplace = 1/0 --> 1:replace affected timepoints; 0:don't replace (just return info)
%  threshstd = 5 --> # stdevs outside of which timepoints will be tagged for replacement
%  rejectwins = 0.5 --> window of 500ms before and after timepoints will be replaced
%  showme = 1/0 --> 1:plot the original and altered wave for every elec
%  outMat: indices of affected timepoints for each elec (includes indices
%  that fell into rejectwins)
%
% Old method:
% This function reads each channel from the FiltData
% directory and locates timepoints that are >5 s.d. from the mean. These
% values are replaced with the mean of the *remaining* points.
% e.g. [1 1 1 9 2 2 2] --> [1 1 1 1.5 2 2 2]
% j.chen Mar 2010
%
% Update: Chop method. Returns a list of affected indices so that entire trials can be
% dropped later if desired. Added doreplace, threshstd, rejectwinms and showme as args.
% j.chen Jul 2010
%

% Update path info based on par.basepath
par = ecogPathUpdate(par);

if ~exist('doreplace','var')
    doreplace = 1;
end
if ~exist('threshstd','var')
    threshstd = 5;
end
if ~exist('rejectwins','var')
    rejectwins = 0.5;
end
if ~exist('showme','var')
    showme = 1;
end

outMat(1).doreplace = doreplace;
outMat(1).threshstd = threshstd;
outMat(1).rejectwins = rejectwins;

rejectWindow = ceil(par.ieegrate*rejectwins);  % 500 milliseconds, in samples-- don't trust samples in +/- this time window from an outlier

fprintf('Starting artifact rejection\n');
if ~exist('elecs','var')
    elecs= [1:par.nchan];
end
elecs=elecs(~ismember(elecs,par.refchan));

if showme
    figure
    clf
end

for ci = elecs
    savefile = sprintf('%s/aiEEG%s_%.2d.mat',par.ArtData,par.block,ci);
    if (exist(savefile,'file'))&&(doreplace==0)
        fprintf('Skipping- file exists:  %s\n',savefile)
    else
        fname = sprintf('%s/fiEEG%s_%.2d.mat',par.FiltData,par.block,ci);
        load(fname); % var name is 'wave'
        if showme
            plot(wave,'r'); hold on
        end
        thresh = threshstd*std(wave);
        outliers = or((wave>(mean(wave)+thresh)),(wave<(mean(wave)-thresh)));
        
        outInds = find(outliers==1);  % indices of outliers
        
        % Reject timepoints before and after each outlier, making sure we don't go past the beginning or end
        plusRejects = [max(outInds):max(outInds+rejectWindow)];
        plusRejects(plusRejects>length(outliers))=length(outliers);
        outliers(plusRejects)=1;
        
        minusRejects = [min(outInds-rejectWindow):min(outInds)];
        minusRejects(minusRejects<1)=1;
        outliers(minusRejects)=1;
        
        %outInds = find(outliers==1);  % new indices  % size(outInds)
        
        keepers = ~outliers;
        % Used to replace artifacts with newmean
        %   newmean = mean(wave(keepers));
        %   wave(outliers) = newmean;
        % Now replace artifacts with mean of start&endpoints
        % Like chopping off the peak
        shiftoutliers = [0 (outliers(1:end-1))];
        artonsets = find((outliers-shiftoutliers)>0);
        artoffsets = find((outliers-shiftoutliers)<0);
        for a = 1:length(artoffsets)
            wave(artonsets(a):artoffsets(a)) =...
                mean([wave(artonsets(a)) wave(artoffsets(a))]);
        end
        outMat(ci).elecs = find(outliers==1);
        
        if showme
            plot(wave,'b');
            fprintf(['Elec ' num2str(ci) ':']);
            pause
            clf
        end
        
        % saving cleaned data
        save(savefile,'wave','outliers')
        
        clear wave
        clear outliers
    end
    fprintf('%.2d of %.3d channels\n',ci,par.nchan)
end

fprintf('Artifact rejection finished \n')
