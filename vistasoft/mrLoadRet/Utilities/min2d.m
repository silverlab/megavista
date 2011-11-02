function [y i] = min2d(x)

% extention of 'min' into matrix

[ytmp itmp] = min(x);
[y itmp2] = min(min(x));
i(1) = itmp(itmp2);
i(2) = itmp2;
