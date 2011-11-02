function selectButton(buttonHandles,buttonNum)
%% selectButton(buttonHandles,buttonNum)%% selects button buttonNum and deselects the others% buttonHandles is a vector of button handles% buttonNum is an integer%% djh, 1/10/97
for i=1:length(buttonHandles)  set(buttonHandles(i),'Value',0);endset(buttonHandles(buttonNum),'Value',1);
return;

