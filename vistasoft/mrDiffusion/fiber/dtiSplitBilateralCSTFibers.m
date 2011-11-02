function fg=dtiSplitBilateralCSTFibers(fg, dt)

%fg=dtiSplitBilateralCSTFibers(fg, dt)
%Due to tractography artifacts, whole brain tractography often produces
%fibers which connect homologous motor cortices, crossing between
%hemispheres at the pons level. This is anatomically implausible: these
%fibers mostl likely cross at the pons level, connecting spinal tract and
%contralateral moter cortex. This function splits fibers with a saggital plane
%below ac. We assume that no interhemispheric fiber should connect below
%AC. Note: cerebellar fibers WILL be split as well. Too bad. 

%ER 08/2009 wrote it

roiName='MidSaggitalBelowACPC';
cornerCoords=[0,dt.bb(1, 2),dt.bb(1, 3); 0,dt.bb(2, 2),0];
roi = dtiRoiMakePlane(cornerCoords, roiName , 'red');

[fgOut,contentiousFibers, keep, keepID] = dtiIntersectFibersWithRoi([], {'SPLIT'}, [], roi, fg)



%% METHOD 1 - UNPROVEN
% Split by current ROI: 
% 
% Bounding Box = dt.bb  x = [-80 0]; y = [-120 90]; z = [-60 90];

fg = dtiReadFibers('CSTdifference.mat');
fg=dtiCleanFibers(fg);
dt = dtiLoadDt6('/biac3/wandell4/data/reading_longitude/dti_y4/at070815/dti06trilinrt/dt6.mat');

x = [-1 1]; 
y = [-120 90]; 
z = [-60 0];

[X,Y,Z] = meshgrid([x(1):x(2)],[y(1):y(2)],[z(1):z(2)]);
roiCoords = [X(:), Y(:), Z(:)];

roi = dtiNewRoi('MidSaggitalBelowACPC', 'b', roiCoords);

newFgRemains = dtiNewFiberGroup('NewFG');
newFgRight = dtiNewFiberGroup('NewFG');
newFgLeft = dtiNewFiberGroup('NewFG');


for i=1:size(fg.fibers)
    pointsRightAndBelow= (fg.fibers{i}(1, :)>0) & (fg.fibers{i}(3, :)<0);
    if sum(pointsRightAndBelow)==0 || sum(pointsRightAndBelow)==size(fg.fibers{i}, 2) || fg.fibers{i}(3, find(fg.fibers{i}(1, :)==min(fg.fibers{i}(1, pointsRightAndBelow))))>0 %dont need to cut
        %newFg.fibers{newi, 1}=fg.fibers{i};
        %  newi=newi+1;
        newFgRemains.fibers=[newFgRemains.fibers(:); fg.fibers(i)];  
    else %chop chop
           display('Chopchop'); 
        cuttingpoint=find(fg.fibers{i}(1, :)==min(fg.fibers{i}(1, pointsRightAndBelow)));
        %newFg.fibers{newi, 1} = fg.fibers{i}(:, fg.fibers{i}(1, :)>0); %Right chunk
        %newFg.fibers{newi+1, 1} = fg.fibers{i}(:, fg.fibers{i}(1, :)<0); %Left chunk
        RightChunk{1}=fg.fibers{i}(:, cuttingpoint:end); 
        newFgRight.fibers= [newFgRight.fibers(:);RightChunk] ; %Right chunk
        LeftChunk{1}=fg.fibers{i}(:,  1:cuttingpoint);
        newFgLeft.fibers = [newFgLeft.fibers(:); LeftChunk]; %Left chunk
        %%Left chunk
        %newi=newi+2;
    end

  
end


newFgRemains.name  = ['CSTdifference_SPLITT_Remain'];
newFgLeft.name  = ['CSTdifference_SPLITT_L'];
newFgRight.name  = ['CSTdifference_SPLITT_R'];

dtiWriteFibersPdb(newFgRemains,dt.xformToAcpc,newFgRemains.name);
dtiWriteFiberGroup(newFgRemains,newFgRemains.name);
dtiWriteFibersPdb(newFgLeft,dt.xformToAcpc,newFgLeft.name);
dtiWriteFiberGroup(newFgLeft,newFgLeft.name);
dtiWriteFibersPdb(newFgRight,dt.xformToAcpc,newFgRight.name);
dtiWriteFiberGroup(newFgRight,newFgRight.name);


%% METHOD 2 - PROVEN
% Code that LMP wrote to take a fiber group, remove callosal fibers, split
% the remaining groups, then merge the two groups to create one set that
% is cut down the mid-line but retains the callosal fibers.
fg = dtiReadFibers('allConnectingGM_withCST.mat');
dt = dtiLoadDt6('/biac3/wandell4/data/reading_longitude/dti_y4/at070815/dti06trilinrt/dt6.mat');

ccCoords = dtiFindCallosum(dt.dt6,dt.b0,dt.xformToAcpc);
ccRoi = dtiNewRoi('CC','c',ccCoords);

fg1 = dtiIntersectFibersWithRoi([], {'and'}, [], ccRoi, fg);
fg2 = dtiIntersectFibersWithRoi([], {'not'}, [], ccRoi, fg);
fgR = dtiClipFiberGroup(fg2, [-80 2],[],[]);
fgL = dtiClipFiberGroup(fg2, [-2 80],[],[]);
fg3 = dtiMergeFiberGroups(fgR,fgL);

newFg = dtiMergeFiberGroups(fg1,fg3,'allConnectingGM_withCST_cutAndMerged');

dtiWriteFibersPdb(newFg,[],newFg.name);


%% METHOD 3 - TO DEVELOP
% Code that (1) creates an ROI that covers one hemisphere below the ac/pc
% line, (2) clips fibers one a given side that encounter that ROI and (3)
% joins the fibers so that the fibers are clipped below the ac/pc line but
% are still joined above the line. 
% With dtiClipFibers: 




