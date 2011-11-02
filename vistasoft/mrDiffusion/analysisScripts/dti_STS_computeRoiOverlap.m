% dtiComputeRoiOverlap
% 
% This code will take a pair of rois and compute the area of overlap. ROIs
% will be read in and their coordinates will be compared (somehow) to
% compute the area of overlap. 
% 
% Each of these particular ROIs are only 1mm thick and are on the central
% plane. This would lead one to assume that it's an operation only
% involving the Y and Z coordinates. The Z coordinate for all of the points
% should be 0.
% 
% This particular task should then be to compare the points in R1 to R2 and
% determine which porportion of the points exist in both ROIs.



%% Directory Structure

logDir = '/biac3/wandell4/data/reading_longitude/STS_Project';
baseDir = '/biac3/wandell4/data/reading_longitude/';
yr = {'dti_y3'};
subs = {'at0','js0','md0','mh0','mho0','mm0','rh0','ss0'};
dirs = 'dti06trilinrt'; 

% ROIs
Roi1 = textread((fullfile(logDir,'Roi1Names.txt')),'%s');
% Roi2 = textread((fullfile(logDir,'Roi2TemporalStt.txt')),'%s');
% if numel(Roi1) ~= numel(Roi2), error('Must have an equal number of ROIs in each list.'); end

Roi2 = {'Mori_LTemp_clean_CCroi.mat'};


%% Text File

dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
textFileName = fullfile(logDir,['STS_RoiOverlap_MoriTemp',dateAndTime,'.txt']);
      
[fid1 message] = fopen(textFileName, 'w');
fprintf(fid1, 'Subject Code \t R1.name \t R2.name \t R1 Area \t R2 Area \t R3 (Intersect) Area \t R3/R1 \t R3/R2 \t R3/(R1+R2) \t \n');


%% Working Loop

for ii=1:numel(subs)
    for dd=1:numel(yr)
        sub = dir(fullfile(baseDir,yr{dd},[subs{ii} '*']));
        subDir = fullfile(baseDir,yr{dd},sub.name);
        dt6Dir = fullfile(subDir,dirs);
        roiDir = fullfile(dt6Dir,'ROIs');

        dt = dtiLoadDt6(fullfile(dt6Dir,'dt6.mat'));
        t1 = readFileNifti(fullfile(subDir,'t1','t1.nii.gz'));

        CC = dtiReadRoi(fullfile(roiDir,'CC_clipMid.mat'));

        for jj = 1:numel(Roi1)
            if exist(fullfile(roiDir,Roi1{jj}),'file') && exist(fullfile(roiDir,Roi2{:}),'file')
                R1 = dtiReadRoi(fullfile(roiDir,Roi1{jj}));
                R1v = dtiGetRoiVolume(R1,t1,dt);
                R1a = R1v.volume;

                R2 = dtiReadRoi(fullfile(roiDir,Roi2{:}));
                R2v = dtiGetRoiVolume(R2,t1,dt);
                R2a = R2v.volume;

                R3 = dtiIntersectROIs(R1,R2);
                R3v = dtiGetRoiVolume(R3,t1,dt);
                R3a = R3v.volume;

                ola = (R3a/(R1a+R2a));
                R3R1 = (R3a/R1a);
                R3R2 = (R3a/R2a);

                fprintf(fid1,'%s\t %s\t %s\t %.6f\t %.6f\t %.6f\t %.6f\t %.6f\t %.6f\t\n', subs{ii},R1.name,R2.name,R1a,R2a,R3a,R3R1,R3R2,ola);
            else
                disp([Roi1{jj} ' or ' Roi2{:} ' does not exist in ' roiDir '. Skipping.']);
            end
        end
    end
end
disp(['Done! Results contained in: ' textFileName]);


        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
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
