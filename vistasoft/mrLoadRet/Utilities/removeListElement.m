function newList = removeListElement(list,t)
%
%   newList = removeListElement(list,t)
%
% Remove an element from the cell array list of

newList = cell(size(list,1)-1,1);
jj = 1;
for ii=1:size(list,1)
   if ii ~= t
      newList{jj} = list{ii};
   end
   jj = jj+1;
end


return;
