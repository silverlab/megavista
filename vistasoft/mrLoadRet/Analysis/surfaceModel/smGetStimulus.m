function [stimulus vw] = smGetStimulus(vw, model, scans)
% Returns the stimulus in a matrix timePoints x pixelValues
% Assumes that the retinotopy model is already loaded via mrvista
% Analysis -> Retinotopy Model -> Set Parameters -> (change fields
% accordingly). Check 'save to dataTypes box'. click done. click close

%an optional argument can be passed with specific scans for which stimulus
%is needed. so in this case the stimulus matrix will only reflect values
%from these scans.

if notDefined('scans'), scans = smGet(model, 'scans'); end
if isempty(scans)
    scans = 1:viewGet(vw, 'nscans');
end

sParams = viewGet(vw, 'rmParams');

if isempty(sParams)
    vw      = rmLoadParameters(vw);
    sParams = viewGet(vw, 'rmParams');
end

stim = sParams.stim;

im = [];
for scan = 1:length(scans)
    thisScan = scans(scan);
    nUniqueRep = stim(thisScan).nUniqueRep;
    thisIm = repmat(stim(thisScan).images, 1, nUniqueRep);
    if scan == 1,
        im = thisIm;
    else 
        im = [im thisIm];
    end
        
end

%this is needed because regression expects timePoints x pixelValues
im = im';

stimulus.tSeries.pixelTcs = im;
stimulus.instimwindow     = stim(1).instimwindow;
stimulus.stimsize         = stim(1).stimSize;
stimulus.stimwindow       = stim(1).stimwindow;
stimulus.stimres          = 1+2*sParams.analysis.numberStimulusGridPoints;

return