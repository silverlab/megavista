function [s_mm, ve, CMF, sigma,roiCoords]=rmGetPointImage(vw,model, roiCoords, smoothParams, varExpThresh, mshDist)
%  rmNeighborsCompare - compute pRF size in mm (point image) or cortical 
% magnification factor locally, based on visual field distances from 
% neighbouring voxels 
%
%
%
%
%
% 2009/02: SD & BH wrote it.

if ~exist('vw','var') || isempty(vw), error('Need view struct'); end
if ~exist('model','var') || isempty(model), error('Need rm model file'); end
if ~exist('varExpThresh', 'var')
    varExpThresh=0;
end

% get gray connection structure
gNodes = viewGet(vw,'nodes');
gEdges = viewGet(vw,'edges');
coords = viewGet(vw,'coords');
nGnodes=length(gNodes);

% load model params
x = rmGet(model,'x');
y = rmGet(model,'y');
s = rmGet(model,'sigma');
ve = rmGet(model,'varexp');

% output
s_mm = zeros(size(s));
sigma = zeros(size(s));
CMF = zeros(size(s));
posdif = zeros(size(s));
sigmadif = zeros(size(s));

%Remove any zero results (typically bad fits)
for t=1:nGnodes    
    if ismember(t, roiCoords)
        if x(t)==double(0)||y(t)==double(0)||s(t)<0.1;
            roiCoords(roiCoords==t)=nan;
        end
    end
end
roiCoords=roiCoords(~isnan(roiCoords));
 
%Smooth pRF sigma
if exist('smoothParams', 'var') && ~isempty(smoothParams)
    [s conMat]=dhkGraySmooth(vw,s,smoothParams, []);
end

%To get cortical surface distances along a smoothed mesh. Not typically
%used
if exist('mshDist', 'var') && mshDist==1
    %complex but accurate way, requires open mesh, slow
    msh = viewGet(vw,'currentmesh');
    v = msh.vertices;
end

tic;
fprintf('[%s]:Computing...',mfilename);

%Calculates point image measures
for t=1:nGnodes % for each gNode...
    if exist('roiCoords', 'var') && ~isempty(roiCoords)
        
        %Only calculate point image for layer 1 nodes (on gray-white
        %border) within the ROI (if passed in) and with good model fits
        if gNodes(6,t)==1 && ismember(t, roiCoords) && ve(t)>=varExpThresh
            
            % Find its edges (the nodes of the things that it's connected to...)
            thisOffset=gNodes(5,t);
            thisNumEdges=gNodes(4,t);
            theseEdges=gEdges(thisOffset:(thisOffset-1+thisNumEdges)); %thisoffset-1 or 0?
            
            %Exclude neighbours outside layer 1 or outside ROI
            edgeindices=gNodes(6,theseEdges)==1 & ismember(theseEdges, roiCoords);
            
            
            % variance explained for the neighbors
            ven = ve(theseEdges(edgeindices));
            aboveThreshold=ven>=varExpThresh;
            ven = ven(aboveThreshold);
            ven = ven./sum(ven);
            
            %If any neighbours have good model fit
            if ~isempty(ven)
                
                
                %Compute cortical distances from neighbours along smoothed
                %mesh or along straight line. Straight line is fine.
                if exist('mshDist', 'var') && mshDist==1
                    %complex way, requires open mesh, slow
                    cdist = theseEdges(edgeindices);
                    cdist = cdist(:,aboveThreshold);
                    segLen=zeros(size(cdist,2),1);
                    meshPosT=v(:,find(msh.vertexGrayMap==t));
                    for n=1:size(cdist,2)
                        meshPosN=v(:,find(msh.vertexGrayMap==cdist(n)));
                        segLenTmp=zeros((size(meshPosT,2)*size(meshPosN,2)),1);
                        for m=1:size(meshPosT,2)
                            for o=1:size(meshPosN,2)
                                segLenTmp((m-1)*size(meshPosN,2)+o)=sqrt(sum((meshPosT(:,m)-meshPosN(:,o)).^2));
                            end
                        end
                        segLen(n) = mean(segLenTmp);
                    end
                    cdist=sum(segLen'.*ven);
                else
                    cdist = coords(:,theseEdges(edgeindices));
                    cdist = cdist(:,aboveThreshold);
                    cdist = cdist - (coords(:,t)*ones(1,size(cdist,2)));
                    cdist = sum(sqrt(sum(cdist.^2)).*ven);    % distance
                end
                
                
                % Compute visual field distance from neighbors
                vfdist = [x(theseEdges(edgeindices)); y(theseEdges(edgeindices))];
                vfdist = vfdist(:,aboveThreshold);
                vfdist = vfdist - ([x(t); y(t)]*ones(1,size(vfdist,2)));
                vfdist = sum(sqrt(sum(vfdist.^2)).*ven);
                
                
                %Compute point image from visual field distances, cortical
                %surface distances and pRF sigma. Record pRF sigma for
                %voxels involved
                CMF(t)  = cdist./vfdist;
                
                %s(t)=s(t)-fwhm2sd(2.5./(CMF(t)));
                
                s_mm(t) = s(t)*CMF(t);
                sigma(t)= s(t);
                
            end
        end
        
        %If not restricting measures to a particular ROI. Good for surface plots.
    elseif gNodes(6,t)==1 && ve(t)>=varExpThresh
        % Find its edges (the nodes of the things that it's connected to...)
        thisOffset=gNodes(5,t);
        thisNumEdges=gNodes(4,t);
        theseEdges=gEdges(thisOffset:(thisOffset-1+thisNumEdges)); %thisoffset-1 or 0?
        
        %Exclude neighbours outside layer 1
        edgeindices=gNodes(6,theseEdges)==1;
        
        
        % variance explained for the neighbors
        ven = ve(theseEdges(edgeindices));
        aboveThreshold=ven>=varExpThresh;
        ven = ven(aboveThreshold);
        ven = ven./sum(ven);
        
        %If any neighbours have good model fit
        if ~isempty(ven)
            
            
            %Compute cortical distances from neighbours along smoothed
            %mesh or along straight line. Straight line is fine.
            if exist('mshDist', 'var') && mshDist==1
                %complex way, requires open mesh, slow
                cdist = theseEdges(edgeindices);
                cdist = cdist(:,aboveThreshold);
                segLen=zeros(size(cdist,2),1);
                meshPosT=v(:,find(msh.vertexGrayMap==t));
                for n=1:size(cdist,2)
                    meshPosN=v(:,find(msh.vertexGrayMap==cdist(n)));
                    segLenTmp=zeros((size(meshPosT,2)*size(meshPosN,2)),1);
                    for m=1:size(meshPosT,2)
                        for o=1:size(meshPosN,2)
                            segLenTmp((m-1)*size(meshPosN,2)+o)=sqrt(sum((meshPosT(:,m)-meshPosN(:,o)).^2));
                        end
                    end
                    segLen(n) = mean(segLenTmp);
                end
                cdist=sum(segLen'.*ven);
            else
                cdist = coords(:,theseEdges(edgeindices));
                cdist = cdist(:,aboveThreshold);
                cdist = cdist - (coords(:,t)*ones(1,size(cdist,2)));
                cdist = sum(sqrt(sum(cdist.^2)).*ven);    % distance
            end
            
            
            % Compute visual field distance from neighbors
            vfdist = [x(theseEdges(edgeindices)); y(theseEdges(edgeindices))];
            vfdist = vfdist(:,aboveThreshold);
            vfdist = vfdist - ([x(t); y(t)]*ones(1,size(vfdist,2)));
            vfdist = sum(sqrt(sum(vfdist.^2)).*ven);
            
            
            %Compute point image from visual field distances, cortical
            %surface distances and pRF sigma. Record pRF sigma for
            %voxels involved
            s_mm(t) = s(t)*(cdist./vfdist);
            CMF(t)  = cdist./vfdist;
            sigma(t)= s(t);
            
        end
    end
end


% some are not finite when vfdist == 0, we interpolate these values
% we do this only for spurious voxels, large patches will be set to global
% mean
ii = find(isnan(s_mm));
for n=1:5
    for t=ii
        % Find its edges (the nodes of the things that it's connected to...)
        thisOffset=gNodes(5,t);
        thisNumEdges=gNodes(4,t);
        theseEdges=gEdges(thisOffset:(thisOffset-1+thisNumEdges)); %thisoffset-1 or 0?
        edgeindices=gNodes(6,theseEdges)==1;
        
        % lookup neighboring values with data
        nb = s_mm(theseEdges(edgeindices));
        nb = nb(isfinite(nb));
        
        nbsigma = sigma(theseEdges(edgeindices));
        nbsigma = nbsigma(isfinite(nbsigma));
        
        nbCMF = CMF(theseEdges(edgeindices));
        nbCMF = nbCMF(isfinite(nbCMF));
        
        if ~isempty(nb)
            s_mm(t) = mean(nb);
            sigma(t) = mean(nbsigma);
            CMF(t) = mean(nbCMF);
        end
    end
    ii = find(isnan(s_mm));
end


%Exclude any zeros from analysis
s_mm(s_mm==0)=nan;


fprintf('Done[%dsecs].\n',round(toc));

% rmGet(model,'s_mm');

return


