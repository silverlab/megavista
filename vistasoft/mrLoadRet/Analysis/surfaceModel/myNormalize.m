function [myStandardize, myNormalize] = myNormalize(inptMtrx)

meanVec = mean(inptMtrx);

%set the mean to zero. i.e., normalize
for i=1:size(inptMtrx(:,1),1)
    myNormalize(i,:) = inptMtrx(i,:) - meanVec;
end


varVec = var(myNormalize);
stddVec = sqrt(varVec);

%set the standard deviation to 1. i.e., standardize
for i=1:size(myNormalize(:,1),1)
   for j=1:size(myNormalize(1,:),2)
       myStandardize(i,j) = myNormalize(i,j)/stddVec(1,j);
   end
end