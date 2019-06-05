function out = getFeatureMap1(im_patch, feature_type, cf_response_size, hog_cell_size)

% code from DSST

% allocate space
switch feature_type
    case 'fhog'
%         temp = fhog(single(im_patch), hog_cell_size);
%         h = cf_response_size(1);
%         w = cf_response_size(2);
%         out = zeros(h, w, 28, 'single');
%         out(:,:,2:28) = temp(:,:,1:27);
%         if hog_cell_size > 1
%             im_patch = mexResize(im_patch, [h, w] ,'auto');
%         end
%         % if color image
%         if size(im_patch, 3) > 1
%             im_patch = rgb2gray(im_patch);
%         end
%         out(:,:,1) = single(im_patch)/255 - 0.5;
        
    x = double(fhog(single(im_patch) / 255, hog_cell_size, 9));
    x(:,:,end) = [];  %remove all-zeros channel ("truncation feature")

    if size(im_patch,3) > 1, 
        im_gray = rgb2gray(im_patch); 
    else
        im_gray=im_patch;
    end
        
    h = cf_response_size(1);
    w = cf_response_size(2);
    % pixel intensity histogram, from Piotr's Toolbox
    h1=histcImWin(im_gray,5,ones(6,6),'same');        
    h1=h1(hog_cell_size:hog_cell_size:end,hog_cell_size:hog_cell_size:end,:);

    % intensity ajusted hitorgram

    im_gray= 255-calcIIF(im_gray,[hog_cell_size,hog_cell_size],32);
    h2=histcImWin(im_gray,5,ones(6,6),'same');
    h2=h2(hog_cell_size:hog_cell_size:end,hog_cell_size:hog_cell_size:end,:);

    out=cat(3,x,h1,h2);
    case 'gray'
        if hog_cell_size > 1, im_patch = mexResize(im_patch,cf_response_size,'auto');   end
        if size(im_patch, 3) == 1
            out = single(im_patch)/255 - 0.5;
        else
            out = single(rgb2gray(im_patch))/255 - 0.5;
        end        
end
        
end

