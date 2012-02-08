% rd_voxsInGroupForTopo.m

j = 1;
for i=1:length(voxelSelector)
    if voxelSelector(i)==1
        a(i,:) = double(voxsInGroup(j,:));
        j = j + 1;
    else
        a(i,:) = [.5 .5];
    end
end




for i=1:length(figData.coordsInplane)
    x = figData.coordsInplane(1,i);
    y = figData.coordsInplane(2,i);
    z = figData.coordsInplane(3,i);
    
    coData(i,1) = INPLANE{1}.co{1}(x,y,z);
end
