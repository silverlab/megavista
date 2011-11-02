function [y i] = max2d(x)

% extention of 'max' into matrix

[ytmp itmp] = max(x);
[y itmp2] = max(max(x));
i(1) = itmp(itmp2);
i(2) = itmp2;
