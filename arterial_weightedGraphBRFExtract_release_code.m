clear; 
clc;
t_start = datetime('now');

%% --- Preprocessing
    fileList = dir(strcat('/path/to/out_art/*.png'));
    allNames = {fileList.name};
    extractedCells = regexp(allNames, '\d+', 'match');
    imageNumbers = str2double([extractedCells{:}]);
%% --
    artIm  = strcat('/path/to/out_art/');
    artExt   = '.png';

    for ii = 1:length(imageNumbers)
    
        imageNumb   = imageNumbers(ii); % select image
        grayArt        = imread(fullfile(artIm, sprintf('%d%s', imageNumb, artExt)));
        binArt  = imbinarize(grayArt);
            shortSegs = 90;   % remove short segments
        binArt = bwareaopen(binArt,shortSegs,8);

        %% Up and down padding for image 
        I = binArt;
        topPad    = zeros(20, size(I, 2), class(I));
        bottomPad = zeros(20, size(I, 2), class(I));
        I_padded = [topPad; I; bottomPad];
        binArt = I_padded;
        
        
        %% Load structuring elements
        load('/path/to/bifPts3x3.mat');
        
        
        %% Vascular skeletonization
        arterySkeleton  = bwmorph(binArt, 'skeleton', Inf);
        arterySkeleton  = bwmorph(arterySkeleton, 'spur', 5);
        arteryMask      = unweightedBranchIdentificationFunction(arterySkeleton);
        labeledSegs     = bwlabel(arteryMask);
        arteryMask      = unweightedBranchIdentificationFunction(arterySkeleton);
        arterySplit  = weightedBranchIdentificationFunction(arterySkeleton,binArt,25);
        weiSegs         = labeledSegs + arterySplit;
        weiLabeledSegs  = bwlabel(weiSegs > 0);
        
        
        %% Identification of the Tpoints
        [m,n] = size(arterySkeleton);
        targetPointCoors = [];
        
        for a = 1:(m-2)
            for b = 1:(n-2)
                window = arterySkeleton(a:a+2, b:b+2);
                matches = all(bsxfun(@eq, window, bifPts3x3), [1 2]);
                if any(matches)
                    targetPointCoors = [targetPointCoors; a+1, b+1];
                end
            end
        end
        targetPointCoors = round(targetPointCoors);
        
        
        %%
        arterySkelEndPoints = endPointFunction(arterySkeleton);
        [o,p] = size(arterySkelEndPoints);
        arteryEndPCoords = zeros(1,2);
        endPointExtractorStrel = [0 1 0;1 1 1;0 1 0];
        
        for g = 1:(o-2)
            for h = 1:(p-2)
                if arterySkelEndPoints(g:g+2,h:h+2) == endPointExtractorStrel
                  arteryEndPCoords = [arteryEndPCoords;[g+1 h+1]];                                      
               end
            end
        end
        arteryEndPCoords(1,:) = [];
        arteryEndPCoords = round(arteryEndPCoords);
        
        coorPoints = [targetPointCoors;arteryEndPCoords];
        coorPoints = sortrows(coorPoints);
        
        %% Variables init
        nTPts     = size(coorPoints,1);
        nSegments = max(weiLabeledSegs(:));
        PredictedAdjacencyMatrix = zeros(nTPts, nTPts);
        dilateSE = strel('disk',5);
        
        %% Bottleneck issue optimization
        % 1. Pre-calculate widths and dilated masks for all segments
        segmentWidths = zeros(nSegments, 1);
        dilatedMasks = cell(nSegments, 1);
        
        for k = 1:nSegments
            segMask = (weiLabeledSegs == k);
            segmentWidths(k) = measureVesselMaxThickness(segMask);
            % Pre-dilate the segment once
            dilatedMasks{k} = imdilate(labeledSegs == k, dilateSE);
        end
        
        % 2. Pre-calculate Point-to-Segment Membership
        % We check which points 'l' fall into the dilated mask of segment 'k'
        % pointMember(i, k) is true if point i is connected to segment k
        pointMember = false(nTPts, nSegments);
        for k = 1:nSegments
            currentMask = dilatedMasks{k};
            for i = 1:nTPts
                % Get coordinates
                py = coorPoints(i, 1); 
                px = coorPoints(i, 2);
                
                % Check if the point (with its 7x7 neighborhood) touches the mask
                % Instead of modifying the mask, we check the mask at that location
                yRange = max(1, py-3):min(size(currentMask,1), py+3);
                xRange = max(1, px-3):min(size(currentMask,2), px+3);
                
                if any(any(currentMask(yRange, xRange)))
                    pointMember(i, k) = true;
                end
            end
        end
        
        % 3. Construct the Adjacency Matrix using Matrix Multiplication
        % If point i and point j both share segment k, they are connected.
        % We iterate through segments to apply the specific 'width'
        PredictedAdjacencyMatrix = zeros(nTPts, nTPts);
        
        for k = 1:nSegments
            % Find all points that belong to this segment
            members = find(pointMember(:, k));
            if ~isempty(members)
                % All pairs of these members are connected via segment k
                % We take the max width if multiple segments connect the same points
                PredictedAdjacencyMatrix(members, members) = ...
                    max(PredictedAdjacencyMatrix(members, members), segmentWidths(k));
            end
        end
        
        % Remove self-loops if necessary
        PredictedAdjacencyMatrix(logical(eye(nTPts))) = 0;
        %%
        
        %% Finalize
        % outFileName = strcat('left_',num2str(iii),'/left_', num2str(imageNumb), '_arteryAdjMatrixData.mat');
        outFileName = strcat('/path/to/out_art/',num2str(imageNumb), '_arteryAdjMatrixData.mat');
        % Gather back to CPU for saving
        PredictedAdjacencyMatrix = gather(PredictedAdjacencyMatrix);
        coorPoints = gather(coorPoints);
        save(outFileName, 'PredictedAdjacencyMatrix', 'coorPoints');
    end
% end
%% Duration
d_end = datetime('now');
fprintf('Duration: %s\n', d_end - t_start);