function automatedWhiteMatterSeg(subjectID,mprageFile)
% ------------------------------------------------------------------------------------------------------------
% fMRI processing pipeline whose goal is to automatize steps as much as
% possible
% ------------------------------------------------------------------------------------------------------------
% Sara Popham, October 2015
% From the work made by Adrien Chopin, Eunice Yang, Rachel Denison, Kelly 
% Byrne, Summer Sheremata
% ------------------------------------------------------------------------------------------------------------

answer = input('Have you already aligned high-res and low-res anatomicals? (y/n)   ','s');
if strmatch('y',lower(answer))
    disp('Hooray, you are competent! We will now continue to white matter segmentation...');
elseif strmatch('n',lower(answer))
    error('Go do that first, you dummy.');
else
    error('Input not understood.');
end

% set freesurfer environment in terminal window
% CANNOT FIGURE OUT HOW TO GET tcsh TO WORK SO AM TRYING ALTERNATIVE
% Let me know if this is bad, but I don't think it will change anything

% need a personal pathFile with freesurfer_folder variable
load('pathFile.mat')

success = system(['recon-all -i ' mprageFile ' -subjid ' subjectID ' -all']);
if success~=0
    error('Error in white matter segmenation... See other messages in command window for details.');
end




