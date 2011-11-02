% dti_STS_ComputeRoiVolume
% 
% This script will loop through a group of subjects and compute the volume
% of the ROIs given in Roi1 and Roi2. The results will be output to a text
% file that can be read into excel.
% 
% HISTORY:
% 8/24/2010 LMP wrote the thing
% 


%% Directory Structure

logDir = '/biac3/wandell4/data/reading_longitude/STS_Project';
baseDir = '/biac3/wandell4/data/reading_longitude/';
yr = {'dti_y1'};
subs = {'ab0','ad0','ada0','ajs0','am0','an0','ao0','ar0','at0','bg0','ch0','clr0','cp0','crb0','ctb0','ctr0','da0','dh0','dm0','es0','hy0','jh0','js0','jt0','kj0','ks0','lg0','lj0','ll0','mb0','md0','mh0','mho0','mm0','mn0','nad0','nf0','nid0','pf0','pt0','rd0','rh0','rs0','rsh0','sg0','sl0','ss0','sy0','tk0','tm0','tv0','vh0','vr0','vt0','zs0'};
dirs = 'dti06trilinrt'; 

% ROIs
Roi1 = {'CC_clipMid.mat'};
Roi2 = {'CC.mat'};


%% Text File

dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
textFileName = fullfile(logDir,'STS_CcRoiVolume.txt');
      
[fid1 message] = fopen(textFileName, 'w');
fprintf(fid1, 'Subject Code \t R1.name \t R1 Area \t R2.name \t R2 Area\n');


%% Working Loop

for ii=1:numel(subs)
    for dd=1:numel(yr)
        sub = dir(fullfile(baseDir,yr{dd},[subs{ii} '*']));
        subDir = fullfile(baseDir,yr{dd},sub.name);
        dt6Dir = fullfile(subDir,dirs);
        roiDir = fullfile(dt6Dir,'ROIs');

        dt = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));
        t1 = readFileNifti(fullfile(subDir,'t1','t1.nii.gz'));

        for jj = 1:numel(Roi1)
            if exist(fullfile(roiDir,Roi1{jj}),'file') && exist(fullfile(roiDir,Roi2{:}),'file')
                fprintf('Processing %s...\n', sub.name);
                R1 = dtiReadRoi(fullfile(roiDir,Roi1{jj}));
                R1v = dtiGetRoiVolume(R1,t1,dt);
                R1a = R1v.volume;

                R2 = dtiReadRoi(fullfile(roiDir,Roi2{:}));
                R2v = dtiGetRoiVolume(R2,t1,dt);
                R2a = R2v.volume;

                fprintf(fid1,'%s\t%s\t%.6f\t%s\t%.6f\n', subs{ii},R1.name,R1a,R2.name,R2a);
            else
                disp([Roi1{jj} ' or ' Roi2{:} ' does not exist in ' roiDir '. Skipping.']);
            end
        end
    end
end
disp(['Done! Results contained in: ' textFileName]);
fclose(fid1);

%%



        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
%%     
%         r1Pts = numel(R1.coords(:,1));
% 
%         r2Pts = numel(R2.coords(:,1));
%         ind = {};
%         count = 0;
%         %         %%
%         %         for kk = 1:r1Pts
%         %             overlap = find(R1.coords(kk,:) == R1.coords(kk,:));
%         %             ind{kk} = overlap;
%         %             if sum(ind{kk}) == 6
%         %                 c = c+1;
%         %             end
%         %
%         %             disp(overlap);
%         %         end
% 
%         %%
%         if r1Pts >= r2Pts
%             for kk=1:r1Pts
%                 a = horzcat(R1.coords(kk,1));
%                 b = horzcat(R1.coords(kk,2));
%                 c = horzcat(R1.coords(kk,3));
% 
%                 for jj=1:r2Pts
%                     aa = horzcat(R2.coords(jj,1));
%                     bb = horzcat(R2.coords(jj,2));
%                     cc = horzcat(R2.coords(jj,3));
% 
%                     if aa==a && bb==b && cc==c
%                         count = count+1;
%                     else
%                     end
%                 end
%             end
%         end
% 
%         % %                         overlap = find(R1.coords(kk,:) == R1.coords(kk,:));
%         % %                         ind{kk} = overlap;
%         % %                         if sum(ind{kk}) == 6
%         % %                             c = c+1;
%         % %                         end
%         %
%         %                         disp(overlap);
%         % %                     end
%         % %                 end
%         %             end
%     end
% end
