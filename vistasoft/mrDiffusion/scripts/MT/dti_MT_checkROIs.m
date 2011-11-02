function dti_MT_checkROIs

% This fucntion will overlay ROIs on the b0 map of a given dt6 file to
% allow the user to determine if the alignment of the functionally defined
% ROIs onto the b0 is reasonable. 
%
% History:
% 2008.12.05 MP Wrote the thing.
% 

baseDir = '/biac3/wandell4/data/reading_longitude/';
dtiYr = {'dti_y1','dti_y2','dti_y3','dti_y4'};
dtDir = 'dti06';
ROIs = {'LMT.mat','RMT.mat'};
subs = {'ao0','am0','bg0','crb0','ctb0','da0','es0','hy0','js0','jt0','kj0','ks0',...
    'lg0','lj0','mb0','md0','mh0','mho0','mm0','nf0','pt0','rh0','rs0','sg0',...
    'sl0','sy0','tk0','tv0','vh0','vr0'};

for ii=1:length(subs)
    % Loop through for each year of dti data
    for jj=1:length(dtiYr)
        subDir = dir(fullfile(baseDir,dtiYr{jj},[subs{ii} '*']));
        if ~isempty(subDir) % If there is no data for dtiYr{kk}, skip.
            subDir = fullfile(baseDir,dtiYr{jj},subDir.name);
            dt6Dir = fullfile(subDir, dtDir);
            dt6File = fullfile(dt6Dir,'dt6.mat');
            roiDir = fullfile(dt6Dir,'ROIs','MT');
            
            % Load the dt6 file and each of the ROIs and show the montage HERE
            for kk=1:length(ROIs)
                roiFile = fullfile(roiDir, ROIs{kk});
                dt = dtiLoadDt6(dt6File);
                roi = dtiReadRoi(roiFile);

                ic = round(mrAnatXformCoords(dt.xformToAcpc, roi.coords));
                imin = sub2ind(size(dt.b0), ic(1,:), ic(2,:), ic(3,:));
                
                r = mrAnatHistogramClip(imin, 0.4, 0.98);
                %r = mrAnatHistogramClip(dt.b0, 0.4, 0.98);
                g = r;
                b = r;

                r(ind) = 1.0;

                makeMontage3(r, g, b);
            end
        else
            disp(sprintf(['\n No data for ' subs{ii} ' in '  dtiYr{kk} '! Skipping.']));
        end
    end
end
return


% TEST
dt6File = '/biac3/wandell4/data/reading_longitude/dti_y3/ao061023/dti06/dt6.mat';
roiFile = '/biac3/wandell4/data/reading_longitude/dti_y3/ao061023/dti06/ROIs/MT/LMT.mat';

dt = dtiLoadDt6(dt6File);
roi = dtiReadRoi(roiFile);

ic = round(mrAnatXformCoords(dt.xformToAcpc, roi.coords));
imin = sub2ind(size(dt.b0), ic(:,1), ic(:,2), ic(:,3));

r = mrAnatHistogramClip(imin, 0.4, 0.98);
g = r;
b = r;

r(ind) = 1.0;

makeMontage3(r, g, b);
