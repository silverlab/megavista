function buttonNum=findSelectedButton(buttonHandles)
%
% buttonNum=findSelectedButton(buttonHandles)
%
% Loops through buttonHandles, returns the first one whose Value
% is 1.
%
% djh, 1/16/97

for buttonNum=1:length(buttonHandles)
  val = get(buttonHandles(buttonNum),'Value');
  if val
    return;
  end
end
