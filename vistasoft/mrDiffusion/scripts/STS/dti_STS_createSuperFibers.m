% dti_STS_createSuperFibers
% 
% This code creates a suber fiber from four fiber groups of interest in the
% RL study and checks that superfiber against the temporal ROI to see if
% they intersect one another. The results of this analysis are printed to
% screen. 
% 
% Loads the conTrack generated fiber groups, (2) creates a super-fiber
% group from those fibers using dtiComputeSuperFiberRepresentation, (3)
% saves that super-fiber, (4) creates an roi from that super-fiber group
% restricted to the mid-sagital slice, (5) loads the temporal CC ROI -
% which was previously created, (6) checks to see if the SFG ROI falls
% within the temporal CC ROI and makes not of it finally (7) printing the
% results to the screen.
% 
% HISTORY:
% LMP - 12/17/2010
% LMP - 06/15/2011 - Commented and cleaned up code.
%

%% 
baseDir = '/biac3/wandell4/data/reading_longitude/';
dtiYr = 'dti_y1';
subs =  {'ab0','ad0','ada0','ajs0','am0','an0','ao0','ar0','at0','bg0','ch0','clr0','cp0','crb0','ctb0','ctr0','da0','dh0','dm0','es0','hy0','jh0','js0','jt0','kj0','ks0','lg0','lj0','ll0','mb0','md0','mh0','mho0','mm0','mn0','nad0','nf0','nid0','pf0','pt0','rd0','rh0','rs0','rsh0','sl0','ss0','sy0','tk0','tm0','tv0','vh0','vr0','vt0','zs0'}; % 'sg0', has no roi.
dtDir = 'dti06trilinrt';

fiberGroups = {'scoredFG_STS__border1008to1031node3_CC_clipRight_top1000_cleaned.pdb',...
               'scoredFG_STS_STSnode4_CC_clipRight_top1000_cleaned.pdb'...
               'scoredFG_STS_LpOTS_y1_funcBasedSphere5mm_CC_clipRight_top1000_cleaned.pdb'...
               'scoredFG_MTproject_100k_200_5_top1000_LEFT_clean_hom.pdb'};
           
fiberNames  = {'SuperFG_AngularGyrus','SuperFG_pSTC','SuperFG_VWFA','SuperFG_MT'};
TemporalRoi = 'Mori_LTemp_CCroi.mat';
rgb         = {'b','r','m','g'}; % Colors for the ROIs

numNodes = 60; % Number of nodes for superFiber (max = 64)
ag=0; stc=0; vwfa=0; mt=0; agT=0; stcT=0; vwfaT=0; mtT=0; % Initialize counters.


for ii = 1:numel(subs)
    sub = dir(fullfile(baseDir,dtiYr,[subs{ii} '*']));
    if ~isempty(sub) % If there is no data for dtiYr, skip.
        subDir = fullfile(baseDir,dtiYr,sub.name);
        dt6Dir = fullfile(subDir,dtDir);
        roiDir = fullfile(dt6Dir, 'ROIs');
        fibersDir = fullfile(dt6Dir, 'fibers','conTrack');
        
        tpRoi = dtiReadRoi(fullfile(roiDir,TemporalRoi)); % Read in temporal CC ROI.
%         tpRoi = dtiRoiClean(tpRoi,0,{'removeSatellites','fillHoles'});
        a=tpRoi.coords;b=a;b(:,1)=1;c=a;c(:,1)=-1;tpRoi.coords=cat(1,a,b,c); % Temporal roi now ranges from X=-1:x=1
        
        for jj=1:numel(fiberGroups)
            if exist(fullfile(fibersDir,fiberGroups{jj}),'file')
                if jj==1; agT   = agT+1; end
                if jj==2; stcT  = stcT+1; end
                if jj==3; vwfaT = vwfaT+1; end
                if jj==4; mtT   = mtT+1; end
                
                % Create superfiber
                fg = mtrImportFibers(fullfile(fibersDir,fiberGroups{jj}));
                [SuperFiber, sfg] = dtiComputeSuperFiberRepresentation(fg, [], numNodes);
                sFg = dtiNewFiberGroup(fiberNames{jj},[0 0 155],[],[],SuperFiber.fibers);
                
                % Save the superfiber to the fibers directory as pdb, can use
                % .mat for colors etc. 
                dtiWriteFibersPdb(sFg,[],(fullfile(fibersDir,sFg.name))); 
                                                                     
                % create roi from the fibers and clip that roi to the
                % midsagital plane. 
                roi = dtiCreateRoiFromFibers(sFg);
                [centerCC roiNot] = dtiRoiClip(roi, [2 80], [], []);
                [newCC roiNot]    = dtiRoiClip(centerCC, [-80 -2], [], []);
                roi       = newCC;
                roi.name  = [fiberNames{jj} '_CCroi'];
                roi.color = rgb{jj};
                
                % Save the ROI
                dtiWriteRoi(roi,fullfile(roiDir,roi.name));
                fprintf('%s has been saved \n', roi.name);                 
                
                % Code to check if the super fiber has any points within
                % the temporal CC ROI. ** Not used, see 95-103 **
                % Get the points closest to the midline (x)
                % c   = sFg.fibers{1};
                % lst = find(abs(c(1,:))<5);
                % coi = c(:,lst);
                
                % For some ROIs the method of rounding the coords when
                % creating the fibers roi fails to put a point down at X=0.
                % This causes problems given that the roi with which we are
                % comparing only has coords at X=0. We could try to expand
                % the tpRoi to include X=1 and X=-1, but that will take
                % some effort and result in some ugliness. SEE LINES 29 75
               
                if numel(roi.coords)>3 % only if it has more than two poins
                    % here I hackishly take the roi coords and average
                    % across the X dimension and round it to get a whole #
                    x=roi.coords; x=mean(x); x=round(x); roi.coords=x; 
                end
                if ismember(roi.coords,tpRoi.coords,'rows') && jj==1; ag   = ag+1; end
                if ismember(roi.coords,tpRoi.coords,'rows') && jj==2; stc  = stc+1; end
                if ismember(roi.coords,tpRoi.coords,'rows') && jj==3; vwfa = vwfa+1; end
                if ismember(roi.coords,tpRoi.coords,'rows') && jj==4; mt   = mt+1; end
            
            else
                fprintf('\nSubject %s does not have FG: %s \n',sub.name,fiberGroups{jj});
            end
        end
    end
end

% Write out the totals to the command window. (Could write it out to text
% file, but not now); 
fprintf('\nTOTALS:\nAG Total: \t%d\n',agT);
fprintf('AG InRoi: \t%d\n',ag);
fprintf('AG Percent: \t%4.2f\n',(ag/agT*100));

fprintf('\nSTC Total: \t%d\n',stcT);
fprintf('STC InRoi: \t%d\n',stc);
fprintf('STC Percent: \t%4.2f\n',(stc/stcT*100));

fprintf('\nVWFA Total: \t%d\n',vwfaT);
fprintf('VWFA InRoi: \t%d\n',vwfa);
fprintf('VWFA Percent: \t%4.2f\n',(vwfa/vwfaT*100));

fprintf('\nMT Total: \t%d\n',mtT);
fprintf('MT InRoi: \t%d\n',mt);
fprintf('MT Percent: \t%4.2f\n',(mt/mtT*100));
