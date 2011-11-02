%% Down sampling a signal after low pass filtering
function output= ecogCompressSignal(input,compress)

if length(size(input))==1
    if size(input,1)>1 & size(input,2)==1
        input= input';
    end
elseif size(input,1)>1 & size(input,2)>1
       fprintf('compresions is along the second dimension\n')
elseif length(size(input))>2
    error('The input has more than 2 dimensions\n')
end

for ii=1:size(input,1)
    output(ii,:)= decimate(double(input(ii,:)),compress);
end
