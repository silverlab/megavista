% script
% 
% Initialize the path for mrData
%
% Bob Dougherty <bob@white.stanford.edu>

disp('Setting mrData path')

switch computer
  case 'LNX86'
    homeDir = '/usr/local/matlab/toolbox/mri/';
  case 'PCWIN'
    homeDir = 'Y:\';
  otherwise
    error('Go see Bob');
end

addpath([homeDir 'mrData']);

clear homeDir