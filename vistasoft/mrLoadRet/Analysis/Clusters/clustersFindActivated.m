function [foundList, clusterList, clustersize] = clustersFindActivated(vw,whichMap,thresh)
%
%
% [foundList, clusterList, clustersize] = clustersFindActivated(vw,whichMap,thresh)
%
% Warning: This function works only in the gray view!
% 
% Takes an activity map & the nodes and edges (the gray matter connectivity
% mesh) to find connected activation clusters on the gray matter
% returns the cluster number, a cell array of connected gray nodes of an
% activation map & the number of nodes in each cluster
%
% foundList     : an array containing the cluster number of activeNodes
% clusterList   : a cell array of the nodes that form the clusters.
% clustersize   : number of nodes in each cluster. 
% Currently gray is 1 cubic mm - number of nodes = volume in cubic mm.
% 
% INPUT
% vw      : gray view
% whichMap: (optional) a particular map
% thres   : (optional) threshold value for map
% if not specified,  whichMap and thres will be determined from current
% window slides
%
% Examples:
% [foundList, clusterList] = clustersFindActivated(VOLUME{1},'statisticalMap',3)
%    

if ieNotDefined('vw'), error('Must send in a view'); end
if ieNotDefined('whichMap'), whichMap = 'mapn'; end
if ieNotDefined('thresh')
    % Go read the sliders
    cothresh = getCothresh(vw);
    phWindow = getPhWindow(vw);
    mapWindow = getMapWindow(vw);
    curScan = getCurScan(vw);
end

% load nodes and edges
nodes = viewGet(vw,'nodes');
edges = viewGet(vw,'edges');

% get active nodes according to map type and sliders
if ~isempty(vw.co) & cothresh~=0,
    data = viewGet(vw,'co',viewGet(vw,'curScan'));
    activeNodes = find(data{2} > cothresh);
end;

% phase
if ~isempty(vw.ph),
    data = viewGet(vw,'co',viewGet(vw,'curScan'));
    activeNodes = (find(data{2}>=phWindow(1) & data{2}<=phWindow(2)));
end;

% map
if ~isempty(vw.map),
    data = viewGet(vw,'mapn',viewGet(vw,'curScan'));
    activeNodes = find(data>=mapWindow(1) & data<=mapWindow(2));  
end;

foundList = zeros(size(activeNodes));
whichNode = activeNodes(1);
foundList(1) = 1;
lNumber = 1;
%connectedActiveNodes{lNumber} = whichNode;
connectedActiveNodes=whichNode;
nodenum=1;

while length(foundList==0)>0
    curconnect=  findConnectedPoints(whichNode,nodes,edges,activeNodes);
    newnodes=setdiff(curconnect,connectedActiveNodes);
    if ~isempty(newnodes) % update list
        connectedActiveNodes=[connectedActiveNodes newnodes ];
        nodenum=nodenum+1;
        whichNode=connectedActiveNodes(nodenum);
    elseif find(connectedActiveNodes==whichNode)<length(connectedActiveNodes)
        % need to check connectivity of other nodes in the current list
        nodenum=nodenum+1;
        whichNode=connectedActiveNodes(nodenum);
        
    else 
         % no more points that connect to current liost- update foundlist 
         % move to next connected list
        for i=1:length(connectedActiveNodes)
            ii=find(activeNodes==connectedActiveNodes(i));
            foundList(ii)=lNumber;
        end
        clusterList{lNumber}=num2cell(connectedActiveNodes);
        % set starting node for next list
        nodeIndex=min(find(foundList == 0));
        lNumber=lNumber+1;
        nodenum=1; % first node in new list
        if ~isempty(whichNode)
            whichNode = activeNodes(nodeIndex);
            connectedActiveNodes=whichNode;
        else
           break % no more nodes
        end
    end
end % while

% calculate cluster size (on the gray each node is 1 cubic mm - this will
% translate to volumein cubic mm
numclusters=lNumber-1;
clustersize=zeros(numclusters,1)
for i=1:numclusters
    clustersize(i)=length(find(foundList==i))
end
return;
