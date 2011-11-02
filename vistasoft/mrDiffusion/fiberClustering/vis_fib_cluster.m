function vis_fib_cluster(clustrlabel, T, fg_fibers)
%Display a group of fibers (clustrlabel) from the clustering solution T on
%fibers population fg_fibers
%ER 11/2007

figure; 
for fbindex = find(T==clustrlabel)'
curve=fg_fibers{fbindex};

tubeplot(curve(1, :), curve(2, :), curve(3, :), 1); 
hold on; 
end

%TODO: impose geometry