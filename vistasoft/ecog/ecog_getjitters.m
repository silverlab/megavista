
function dif = getjitters(flinit,initevents)

for n = 1:3
    a1 = flinit(n).init-flinit(1).init(1);
    a1 = a1 .* 3051.76;
    i1 = initevents-initevents(1);
    dif(n,:) = a1-i1((n-1)*4+1:(n-1)*4+4);
end