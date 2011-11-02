% Define new ROI that is the center of the disk ROI (one voxel)
% Use ROITOROIDIST to compute distances of each gray node from center
% Get max of these distances

% params
if ispc
    dataDir='W:\projects\Kids\fmri';
else
    dataDir = fullfile('/biac1','kgs','projects','Kids','fmri');
end

sessions={fullfile('adults','acg_38yo_012008_2'),...
    fullfile('adults','gg_37yo_110907'),...
    fullfile('adults','kw_25yo_120407'),...
    fullfile('adults','kw_25yo_120407'),...
    fullfile('adolescents','ar_12yo_011908_2'),...
    fullfile('adolescents','dw_14yo_102707_2'),...
    fullfile('adolescents','is_16yo_121607_2'),...
    fullfile('adolescents','jpb_16yo_033008_2'),...
    fullfile('adolescents','kwl_14yo_011208_2'),...
    fullfile('adolescents','kll_18yo_011908')};

rois={{'RFFA_MCvOJIO_p3d.mat','LFFA_MCvOJIO_p3d.mat'},...
    {'RFFA_MCvOJIO_p3d.mat','LFFA_MCvOJIO_p3d.mat'},...
    {'RFFAant_MCvOJIO_p3d.mat','LFFAant_MCvOJIO_p3d.mat'},...
    {'RFFApost_MCvOJIO_p3d.mat','LFFApost_MCvOJIO_p3d.mat'},...
    {'RFFA_MCvOJIO_p3d.mat','LFFA_MCvOJIO_p3d.mat'},...
    {'RFFA_MCvOJIO_p3d.mat','LFFA_MCvOJIO_p3d.mat'},...
    {'RFFA_MCvOJIO_p3d.mat','LFFA_MCvOJIO_p3d.mat'},...
    {'RFFA_MCvOJIO_p3d.mat','LFFA_MCvOJIO_p3d.mat'},...
    {'RFFA_MCvOJIO_p3d.mat','LFFA_MCvOJIO_p3d.mat'},...
    {'RFFA_MCvOJIO_p3d.mat','LFFA_MCvOJIO_p3d.mat'}};

roiname={'RFFA','LFFA'};
scan=1;

% Parameters
useSpecifiedPath=1; % otherwise, will 'guess' where to look for ROI
makeRoiCurrent=1; % otherwise, makeROIdiskGray might use different source ROI
growradius=20; % radius of the gray disk ROIs -- make them bigger, as we restrict to perimeter distances in layer 1
radius=10;
perimeter=[9 10]; % perimeter boundary (1mm of slop)

% Loop through each session
for ii=1:length(sessions)
    cd(fullfile(dataDir,sessions{ii}));
    hG = initHiddenGray('GLMs', scan);
    % Loop through each ROI
    for jj=1:2
        % THEROIDIR is where all ROIs will be saved
        theroiDir=fullfile(dataDir,sessions{ii},'Gray','ROIs','Davie');
        theroi=rois{ii}{jj};
        theroi=fullfile(theroiDir,theroi);
        if ~exist(theroi,'file')
            fprintf(1,'%s not found \n',theroi);
        else % if file exists, load ROI and proceed
            [hG , ok, FFAROI] = loadROI(hG,theroi,makeRoiCurrent,[],useSpecifiedPath,[]);
            % Build (but don't save) disk ROI on gray of GROWRADIUS, from center of FFAROI
            diskCenter = round(mean(FFAROI.coords'))'; 
            diskname = [roiname{jj} '_disk' num2str(growradius)];
            [hG, ROI]=makeROIdiskGray(hG,growradius,diskname,[],[],diskCenter);
            diskroi = ROI; clear ROI
            % Build and save disk ROI on gray of RADIUS, from center of FFAROI
            disk10name = [roiname{jj} '_disk' num2str(radius)];
            [hG, ROI]=makeROIdiskGray(hG,radius,disk10name,[],[],diskCenter);
            save(fullfile(theroiDir,disk10name),'ROI'); clear ROI
            % Build a center point ROI for calculating distances
            center.coords = diskCenter;
            % Calculate distances of each point on the disk ROI to the center
            % This works if you put the ROIS in the right order (center ROI
            % = target). Find the points along the perimeter
            distances = RoiToRoiDist(center, diskroi, hG);
            maxdists = find(distances>perimeter(1) & distances<perimeter(2));
            maxdistcoords = diskroi.coords(:,maxdists);
            
%             % Use this if you wish to view the perimeter on the mesh
%             VOLUME{1}=newROI(VOLUME{1},'perimeter',[],[],maxdistcoords)
            
            % Calculate coordinate of point most anterior (min Y coord)
            minY = min(maxdistcoords(2,:));
            buildminY = find(maxdistcoords(2,:) == minY);
            buildminY = maxdistcoords(:,buildminY);
            if min(size(buildminY))>1 % only transpose/round if more than one voxel
                buildminY = round(mean(buildminY'))';
            end

            % Calculate coordinate of point most posterior (max Y coord)
            maxY = max(maxdistcoords(2,:));
            buildmaxY = find(maxdistcoords(2,:) == maxY);
            buildmaxY = maxdistcoords(:,buildmaxY);
            if min(size(buildmaxY))>1
                buildmaxY = round(mean(buildmaxY'))';
            end

            % Calculate coordinate of point on one extreme, medial-laterally (minX)
            % This will be most medial on the LH, and most lateral on the RH
            minX = min(maxdistcoords(1,:));
            buildminX = find(maxdistcoords(1,:) == minX);
            buildminX = maxdistcoords(:,buildminX);
            if min(size(buildminX))>1
                buildminX = round(mean(buildminX'))';
            end
            if jj==1 % RFFA
                buildL = buildminX;
            elseif jj==2 % LFFA
                buildM = buildminX;
            end

            % Calculate coordinate of point on other extreme, medial-laterally (maxX)
            % This will be most medial on the RH, and most lateral on the LH
            maxX = max(maxdistcoords(1,:));
            buildmaxX = find(maxdistcoords(1,:) == maxX);
            buildmaxX = maxdistcoords(:,buildmaxX);
            if min(size(buildmaxX))>1
                buildmaxX = round(mean(buildmaxX'))';
            end
            if jj==1 % RFFA
                buildM = buildmaxX;
            elseif jj==2 % LFFA
                buildL = buildmaxX;
            end

            % Build and save disk ROIs around these A,P,M,L points
            diskAname=[roiname{jj} '_disk' num2str(radius) '_A10'];
            diskPname=[roiname{jj} '_disk' num2str(radius) '_P10'];
            diskMname=[roiname{jj} '_disk' num2str(radius) '_M10'];
            diskLname=[roiname{jj} '_disk' num2str(radius) '_L10'];
            [hG,ROI]=makeROIdiskGray(hG,radius,diskAname,[],[],buildminY);
            save(fullfile(theroiDir,diskAname),'ROI'); clear ROI;
            [hG,ROI]=makeROIdiskGray(hG,radius,diskPname,[],[],buildmaxY);
            save(fullfile(theroiDir,diskPname),'ROI'); clear ROI;
            [hG,ROI]=makeROIdiskGray(hG,radius,diskMname,[],[],buildM);
            save(fullfile(theroiDir,diskMname),'ROI'); clear ROI;
            [hG,ROI]=makeROIdiskGray(hG,radius,diskLname,[],[],buildL);
            save(fullfile(theroiDir,diskLname),'ROI'); clear ROI;
            
            clear FFAROI diskroi diskCenter buildminY buildmaxY buildM buildL
        end
    end
end



