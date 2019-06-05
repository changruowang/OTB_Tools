function [ flow ] = getFlow( img1, img2 )
%GETFLOW a wrapper to integrate different flow algorithm

flow = mex_LDOF(double(img1),double(img2));

end

