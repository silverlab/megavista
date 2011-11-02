function imStack=PennAnalyze2mrLoadRetTSeries(inFileRoot,outFileRoot,nVols,firstVolIndex, ...
    doRotate,scaleFact,flipFlag,VERBOSE)
% imStack=Pennnalyze2mrLoadRetTSeries(inFileRoot,outFileRoot,nVols,[firstVolIndex], ...
%   [doRotate],[scaleFact],[flipFlag],[VERBOSE])
%
% Converts from analyze functional image data to mrLoadRet TSeries format.
% Analyze functional data are stored as N individual volumes, each with S slices
% mrLoadRet has S individual files with N acquisitions in each.
%
% The doRotate param allows to you roate the functional data by doRotate*90 degrees
%
% Reads the the first volume to see if it's there and get the dimensions of all the rest
%
% 5/16/03  dhb  This came from Stanford.  Added Penn prefix.
%          dhb  Save tSeries directly as .mat, forget .dat step.

% Set default values for optional variables
if (~exist('firstVolIndex','var'))
    firstVolIndex=1;
end
if (~exist('doRotate','var'))
    doRotate=1;
end
if (~exist('scaleFact','var'))
    scaleFact=[1 1];
end
if (length(scaleFact)~=2)
    scaleFact=repmat(scaleFact(1),2);
end
if (~exist('flipFlag','var'))
    flipFlag=1; % This is on by default. Flips up/down after rotation
end
if (~exist('VERBOSE','var'))
    VERBOSE = 1;
end
if (VERBOSE)
    fprintf('PennAnalyze2mrLoadRetTSeries\n');
end

% Get suffix
suffix=sprintf('%03d',firstVolIndex);
fileName=[inFileRoot,suffix,'.hdr'];

% Read first volume
V=spm_vol(fileName);
im=spm_read_vols(V);

[y,x,nSlices]=size(im);
if (VERBOSE)
    fprintf('\tRead in a volume of size %d, %d, %d\n',y,x,nSlices);
end

% Pre-allocate memory. This is a monster and will fail on many machines. 
if (VERBOSE)
    fprintf('\tTrying to allocate an array with %d elements ...',y*x*nSlices*nVols);
end
if (mod(doRotate,2))
    funcVol=zeros(x,y,nSlices,nVols);
else
    funcVol=zeros(y,x,nSlices,nVols);
end
if (VERBOSE)
    fprintf(' done\n');
    fprintf('\tWill rotate by %d x 90, flipFlag=%d\n',doRotate,flipFlag);
end

% Read in the volumes
if (VERBOSE)
    fprintf('\tReading %d volumes ...',nVols);
end
for t=0:(nVols-1)
    thisImIndex=t+firstVolIndex;
    suffix=sprintf('%03d',thisImIndex);
    fileName=[inFileRoot,suffix];
    V=spm_vol(fileName);
    im=spm_read_vols(V);
    
    % Do the rotation and scaling   
    if (mod(doRotate,2))
        im2=zeros(x,y,nSlices);
    else
        im2=zeros(y,x,nSlices);
    end
   
    for thisSlice=1:nSlices
        imSlice=squeeze(im(:,:,thisSlice));
        im2(:,:,thisSlice)=rot90(imSlice,doRotate);
        if (flipFlag) 
            im2(:,:,thisSlice)=flipud(im2(:,:,thisSlice));
        end      
    end
    funcVol(:,:,:,t+1)=im2;
end
[y x nSlices nVols]=size(funcVol);
if (VERBOSE)
    fprintf(' done\n');
end

% Now write them out in a different format
if (VERBOSE)
    fprintf('\tWriting %g slices ...',nSlices);
end
for t=1:nSlices
    suffix=['tSeries' int2str(t)];
    fileName=[outFileRoot,suffix];
    tSeries=squeeze(funcVol(:,:,t,:)); 
    tSeries=squeeze(shiftdim(tSeries,2));
    PennSaveTSeriesMat(fileName,tSeries,y,x,scaleFact,0);
end
if (VERBOSE)
    fprintf(' done\n');
end