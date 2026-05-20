%% Calcular espessura usando distance transform - output em nr de pixels
function thickness = measureVesselMaxThickness(segMask)
    % Skeletonize the segment
    skel = bwmorph(segMask,'skel',true);
    % Compute the distance transform
    D = bwdist(~segMask);
    % Measure thickness at each skeleton pixel
    thickness = max(D(skel)); % Local thickness at skeleton pixels
end
