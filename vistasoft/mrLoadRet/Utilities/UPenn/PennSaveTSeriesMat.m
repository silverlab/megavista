function PennSavetSeriesMat(fileName,tSeries,nRows,nCols,scaleFactor,VERBOSE)
% function PennSavetSeriesMat(fileName,tSeries,[nRows,nCols],[scaleFactor],[VERBOSE]) 
%
% Save the tSeries in tat MATLAB .mat file.
%
% nRows and nCols are optional arguments.  If not supplied, the
% header will contain: nRows=1, nCols=real#rows * real#cols.
%
% 12/23/98        Written by Bill and Bob. 
% 01/02/02   arw  Changed to allow passing of a scale factor
% 5/16/03    dhb  Added Penn prefix, local modifications.  Clean up.
%            dhb  Added explicit VERBOSE flag.
%            dhb  Use MATLAB imresize rather than local copy MYimresize.
%            dhb  Rename to PennSavetSeriesMat and get rid of .dat step.

% Check VERBOSE mode
if (~exist('VERBOSE','var'))
    VERBOSE = 1;
end
if (VERBOSE)
    fprintf('PennSaveTSeriesMat\n');
end

if (nargin < 3 | isempty(nRows))
    nRows = 1;
    nCols = size(tSeries,2);
end
nFrames = size(tSeries,1);

% Rescale data if non-unity scale factor was passed.
if (exist('scaleFactor','var') & any(scaleFactor ~= 1))
    %if (VERBOSE)
        fprintf('\tApplying scale factor %d by %d\n',scaleFactor(1),scaleFactor(2));
    %end
    oldTSeries=tSeries;   
    nRows=nRows*scaleFactor(1);
    nCols=nCols*scaleFactor(2);
    tSeries=zeros(nFrames,nRows,nCols);
   
    for thisFrame=1:nFrames
        imSlice=squeeze(oldTSeries(thisFrame,:,:));
        tSeries(thisFrame,:,:) = imresize(imSlice,[nRows,nCols],'nearest');
        fprintf('.');     
    end
end

% Write that sucker as a .mat file
if (VERBOSE)
    fprintf('\tWriting tSeries\n');
end

% Reshape tSeries
tSeries = reshape(tSeries,size(tSeries,1),size(tSeries,2)*size(tSeries,3));

% Save itdsb
save(fileName,'tSeries');
