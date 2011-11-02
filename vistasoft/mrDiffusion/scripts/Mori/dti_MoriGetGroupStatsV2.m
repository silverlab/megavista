
% dti_MoriGetGroupStatsV2
% 
% Example Usage: User should edit the script and add the initials of the
% subjects to be run being mindful of redundant subject codes.
%
% This script will load fibers and compute the fiber statistics (using
% dtiFiberProperties.m) for a group of subjects that have been through
% dti_FindMoriTracts and dti_CullMoriFibers and combine them to form one
% big struct. Those values will then be sent to a text file where they are
% tab delimited and saved. The resulting
% .._Struct.mat and ...Stats.txt files will be saved to the dti_logs directory. 
% 
% The emphasis will be on:
% 1) loading a given subject's fiber groups
% 2) computing the statistics for that subject's fiber groups
% 3) storing those statistics in a structure
% 4) loading and computing statistics for another subject and adding that
% to the structure.
% 5) saving the struct values to a text file. 
% 
% Some possible future directions would be to compute averages and
% correlations on the fly and print those out to a text file. [diary]
% 
% 2009.02.06 MP Wrote it
% 2009.02.10 MP Added the ability for the structure to be written and saved
% to a text file.
% 2009.04.21 ER passed in study-specific fiberDiameter parameter

%% The initials of the subjects you would like to get the stats for.
% Be mindful of redundant Initials.
subInitials = {'AJ041407','CA101407','CZ101407','GD082507','IE111807','KB052007',...
               'MF041507','MP081907','MT092307','RP102707','RS022107','SP022407' ...
               '00003-PT2','00009-PT2','00014-PT2','00017-PT2','00020-PT2',...
               '00030-PT2','00037-PT2','00047-PT2','00048-PT2','00049-PT2',...
               '00052-PT2','00054-PT2'};

subInitials2 = {'AJ041407','CA101407','CZ101407','GD082407','IE111807','KB052007',...
               'MF041507','MP081907','MT092307','RP102707','RS022107','SP022407' ...
               'PT200003','PT200009','PT200014','PT200017','PT200020',...
               'PT200030','PT200037','PT200047','PT200048','PT200049',...
               'PT200052','PT200054'};


%% Set Directory Structure and FiberGroup info 
dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
batchDir = '/biac3/gotlib4/moriah/PINE/';
dtDir = 'anatomy/dti_analysis/dti25';
fiberName = 'MoriTracts_Cull.mat';

statsFileName = fullfile(batchDir,'dti_logs',['MoriFiberGroupStats_Struct_',date,'.mat']);
textFileName = fullfile(batchDir,'dti_logs',['MoriFiberGroupStats_',dateAndTime,'.txt']);


%% Run the Fiber Properties function and create the stats file.

% Open the stats text file        
    fid = fopen(textFileName, 'w');

    fprintf(fid, 'Subject Initials \t Fiber Name \t Num Fibers \t Fiber Length(min) \t Fiber Length(mean) \t Fiber Length(max) \t FA(min) \t FA(mean) \t FA(max) \t MD(min) \t MD(mean) \t MD(max) \t AxialADC(min) \t AxialADC(mean) \t AxialADC(max) \t RadialADC(min) \t RadialADC(mean) \t RadialADC(max) \t Linearity(min) \t Linearity(mean) \t Linearity(max) \t Planarity(min) \t Planarity(mean) \t Planarity(max) \t Fiber Group Vol\n');
    
    for i=1:length(subInitials)
        try
            sub = dir(fullfile(batchDir,[subInitials{i} '*']));
            subDir = fullfile(batchDir,sub.name);
            dt6Dir = fullfile(subDir, dtDir);
            if ~exist(dt6Dir,'file')
                dt6Dir = fullfile(subDir,'anatomy','dti_analysis','dti25trilin');
            end
            fiberDir = fullfile(dt6Dir,'fibers');
            dt6 = fullfile(dt6Dir,'dt6.mat');
            
            dt = dtiLoadDt6(dt6);
            if ~exist(dt.files.t1,'file')
                dt.files.t1 = fullfile(mrvdirup(dt6,2),'t1.nii.gz');
                if ~exist(dt.files.t1,'file')
                    [f,p] = uigetfile({'*.nii.gz','NIFTI';'*.*', 'All Files (*.*)'}, 'T1 File not where expected. Select T1 NIFTI file...', subDir);
                    if(isnumeric(f))
                        disp('User canceled.'); return; end
                    dt.files.t1 = fullfile(p,f);
                end
            end
            
            fg = fullfile(fiberDir,fiberName);
            fg = load(fg);
            fg = fg.fg;
            
            try
                fgs.(subInitials{i}) = dtiFiberProperties(fg,dt, [], 2.7);
                subIn = subInitials{i};
            catch ME
                subInd = subInitials2{i};
                fgs.(subInd) = dtiFiberProperties(fg,dt, [], 2.7);
                subIn = subInd;
            end
            
            
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
        catch ME
            disp(ME);
            fprintf('\n\n CHECK THAT FILE EXISTS FOR SUBJECT %s. \n MOVING ON!\n\n\n', sub.name);
        end
        
    end

    save(statsFileName,'fgs'); % save the structure to a .mat file

    fclose(fid); % close and save the stats text file
    
    cd(mrvDirup(statsFileName)); % Change to the directory where the files are saved.










%% Scratch [ignore]

% textFileName = fullfile('/home/lmperry/Desktop/',['MoriFiberGroupStats_',dateAndTime,'.txt']);


%  for ii=1:numel(fgs.(subIn))
%    fprintf(fid,'%s\t %s\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t\n', subIn, fgs.(subIn)(ii).name, 
% fgs.(subIn)(ii).numberOfFibers, fgs.(subIn)(ii).fiberLength(1), fgs.(subIn)(ii).fiberLength(2), fgs.(subIn)(ii).fiberLength(3), fgs.(subIn)(ii).FA(1), fgs.(subIn)(ii).FA(2), 
% fgs.(subIn)(ii).FA(3), fgs.(subIn)(ii).MD(1), fgs.(subIn)(ii).MD(2), fgs.(subIn)(ii).MD(3), fgs.(subIn)(ii).axialADC(1), fgs.(subIn)(ii).axialADC(2), fgs.(subIn)(ii).axialADC(3), 
% fgs.(subIn)(ii).radialADC(1), fgs.(subIn)(ii).radialADC(2), fgs.(subIn)(ii).radialADC(3), fgs.(subIn)(ii).linearity(1), fgs.(subIn)(ii).linearity(2), fgs.(subIn)(ii).linearity(3), 
% fgs.(subIn)(ii).planarity(1), fgs.(subIn)(ii).planarity(2), fgs.(subIn)(ii).planarity(3), fgs.(subIn)(ii).fiberGroupVolume);
%     end


