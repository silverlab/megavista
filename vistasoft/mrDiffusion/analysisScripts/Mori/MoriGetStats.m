function MoriGetStats(subInitials)

% MoriGetStats('subInitials')
% EXAMPLE USAGE: >> MoriGetStats('CK');
% 
% This script will load the fibers, and compute the fiber statistics using
% dtiFiberProperties.m, for a subject that has been through
% dti_FindMoriTracts and dti_CullMoriFibers and save a struct containing
% those statistics to that subjects fiber directory with the name
% FiberGroupStats_[subInitials].mat. 
%
% The struct (fgs) is now written to a text file that is saved to the
% subjects fibers directory. This .txt file (tab delimeted) can be read
% into excel creating a very nice, organized spreadsheet.
% 
% The emphasis will be on:
% 1) loading a given subjects fiber groups
% 2) computing the statistics for that subjects fiber groups
% 3) storing those statistics in a structure
% 4) Writing those statistics to a text file that can be opened in excel.
%  
% 
% 2009.02.06 MP Wrote it
% 2009.02.10 MP Added the ability for the structure to be written and saved
% to a text file.
% 2009.04.21 ER passed in study-specific fiberDiameter parameter

%% Set Directory Structure and FiberGroup info 

batchDir = '/biac3/gotlib4/moriah/PINE/';
dtDir = 'anatomy/dti_analysis/dti25';
fiberName = 'MoriTracts_Cull.mat';

if (~exist('subInitials','var'))
    error('You have to provide the subjects initials!'); 
end

%% Run the Fiber Properties function.

    sub = dir(fullfile(batchDir,[subInitials '*']));
    subDir = fullfile(batchDir,sub.name);
    dt6Dir = fullfile(subDir, dtDir);
    fiberDir = fullfile(dt6Dir,'fibers');
    dt6 = fullfile(dt6Dir,'dt6.mat'); % Full path to dt6.mat

    dt = dtiLoadDt6(dt6);
    fg = fullfile(fiberDir,fiberName);
    fg = load(fg);
    fg = fg.fg;
    fgs.(subInitials) = dtiFiberProperties(fg,dt, [], 2.7);
    
    cd(fiberDir); %
    
 % Save the structure
    fName = fullfile(fiberDir,['FiberGroupStats_', subInitials, '.mat']);
            
    save(fName,'fgs');
    
 % Create the stats text file
    fNameTextFile = fullfile(fiberDir,['moriFiberGroupStats_', subInitials, '.txt']);
            
    fid = fopen(fNameTextFile, 'w');
    
    fprintf(fid, 'Subject Initials \t Fiber Name \t Num Fibers \t Fiber Length(min) \t Fiber Length(mean) \t Fiber Length(max) \t FA(min) \t FA(mean) \t FA(max) \t MD(min) \t MD(mean) \t MD(max) \t AxialADC(min) \t AxialADC(mean) \t AxialADC(max) \t RadialADC(min) \t RadialADC(mean) \t RadialADC(max) \t Linearity(min) \t Linearity(mean) \t Linearity(max) \t Planarity(min) \t Planarity(mean) \t Planarity(max) \t Fiber Group Vol\n');

    subIn = subInitials;   
    
    for ii=1:numel(fgs.(subIn))
    
    a1	=	subIn; 
    b1	=	fgs.(subIn)(ii).name; 
    c1	=	fgs.(subIn)(ii).numberOfFibers; 
    d1	=	fgs.(subIn)(ii).fiberLength(1); 
    e1	=	fgs.(subIn)(ii).fiberLength(2); 
    f1	=	fgs.(subIn)(ii).fiberLength(3); 
    g1	=	fgs.(subIn)(ii).FA(1); 
    h1	=	fgs.(subIn)(ii).FA(2); 
    i1	=	fgs.(subIn)(ii).FA(3); 
    j1	=	fgs.(subIn)(ii).MD(1); 
    k1	=	fgs.(subIn)(ii).MD(2); 
    l1	=	fgs.(subIn)(ii).MD(3); 
    m1	=	fgs.(subIn)(ii).axialADC(1); 
    n1	=	fgs.(subIn)(ii).axialADC(2); 
    o1	=	fgs.(subIn)(ii).axialADC(3); 
    p1	=	fgs.(subIn)(ii).radialADC(1); 
    q1	=	fgs.(subIn)(ii).radialADC(2); 
    r1	=	fgs.(subIn)(ii).radialADC(3); 
    s1	=	fgs.(subIn)(ii).linearity(1); 
    t1	=	fgs.(subIn)(ii).linearity(2); 
    u1	=	fgs.(subIn)(ii).linearity(3); 
    v1	=	fgs.(subIn)(ii).planarity(1); 
    w1	=	fgs.(subIn)(ii).planarity(2); 
    x1	=	fgs.(subIn)(ii).planarity(3); 
    y1	=	fgs.(subIn)(ii).fiberGroupVolume;
    
    fprintf(fid,'%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t\n',a1,b1,c1,d1,e1,f1,g1,h1,i1,j1,k1,l1,m1,n1,o1,p1,q1,r1,s1,t1,u1,v1,w1,x1,y1);
    
    end
    fclose(fid);

    
return




        
%% Scratch [ignore]
% 
% fName = fullfile('/home/lmperry/Desktop/',['FiberGroupStats_', subInitials, '.mat']);

% fNameTextFile = fullfile('/home/lmperry/Desktop/',['MoriFiberGroupStats_', subInitials, '.txt']);
% 
%     for ii=1:numel(fgs.(subInitials))
%     
%         fprintf(fid,'%s\t %s\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t\n', subInitials, 
% fgs.(subInitials)(ii).name, fgs.(subInitials)(ii).numberOfFibers, fgs.(subInitials)(ii).fiberLength(1), fgs.(subInitials)(ii).fiberLength(2), fgs.(subInitials)(ii).fiberLength(3), 
% fgs.(subInitials)(ii).FA(1), fgs.(subInitials)(ii).FA(2), fgs.(subInitials)(ii).FA(3), fgs.(subInitials)(ii).MD(1), fgs.(subInitials)(ii).MD(2), fgs.(subInitials)(ii).MD(3), 
% fgs.(subInitials)(ii).axialADC(1), fgs.(subInitials)(ii).axialADC(2), fgs.(subInitials)(ii).axialADC(3), fgs.(subInitials)(ii).radialADC(1), fgs.(subInitials)(ii).radialADC(2), 
% fgs.(subInitials)(ii).radialADC(3), fgs.(subInitials)(ii).linearity(1), fgs.(subInitials)(ii).linearity(2), fgs.(subInitials)(ii).linearity(3), fgs.(subInitials)(ii).planarity(1), 
% fgs.(subInitials)(ii).planarity(2), fgs.(subInitials)(ii).planarity(3), fgs.(subInitials)(ii).fiberGroupVolume);
%         
%     end
% 




























