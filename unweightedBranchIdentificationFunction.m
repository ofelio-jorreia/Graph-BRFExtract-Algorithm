function vesselSegments = branchIdentificationFunction(vesselSkeleton)
skelet = vesselSkeleton;
[a,b] = size(skelet);
load bifPts3x3.mat %#ok<LOAD>
for i = 1:a-2
    for j=1:b-2
         for d = 1:length(bifPts3x3) %#ok<USENS>
            if skelet(i:i+2,j:j+2) == bifPts3x3(:,:,d)
                skelet(i:i+2,j:j+2) = 0;
            end
        end
    end
end
vesselSegments = skelet;