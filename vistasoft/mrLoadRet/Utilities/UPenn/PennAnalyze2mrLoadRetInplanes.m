function im = PennAnalyze2mrLoadRetInplanes(inFileRoot,outFileRoot,VERBOSE)
% im = PennAnalyze2mrLoadRetInplanes(inFileRoot,outFileRoot,[VERBOSE])
%
% Returns a set of anatommical inplanes from analyze format image stack
% These are used to fool mrInitRet into generating a project when we only have 
% analyze format data.
% 
% See also PennAnalyze2mrLoadRetTSeries.
%
% Requires SPM99 routines.
%
% 1/23/03  dhb, gc  This came from Stanford.
% 1/23/03  dhb, gc  Added some comments, got it to run.
% xx/xx/03 gc       Remove write step, as we only need data one level up.
% 5/16/03  dhb      Added Penn prefix.

% Defaults
if (~exist('VERBOSE','var'))
    VERBOSE = 1;
end

% Get the image header
V=spm_vol(inFileRoot);

% Get the image stack
im=spm_read_vols(V);






