clear; 
clc;
t_start = datetime('now');

%% --- Preprocessamento
% Definição de paths e ficheiros 
for iii = 0:72

    fileList = dir(strcat('/media/ofelio/dragonfly/pt🇵🇹/uc-pt/2025-2026/betaFiles/ocular_disease_intelligent_recognition_ODIR_dataset/odir_dataset/av_segm_left_exposed_vasculature/left_', num2str(iii),'/out_art/*_left.png'));
    allNames = {fileList.name};
    extractedCells = regexp(allNames, '\d+', 'match');
    imageNumbers = str2double([extractedCells{:}]);
%% --



    
    artIm  = strcat('/media/ofelio/dragonfly/pt🇵🇹/uc-pt/2025-2026/betaFiles/ocular_disease_intelligent_recognition_ODIR_dataset/odir_dataset/av_segm_left_exposed_vasculature/left_',num2str(iii),'/out_art');
    artExt   = '_left.png';

    for ii = 1:length(imageNumbers)
    
        imageNumb   = imageNumbers(ii); % Selecionar imagem
        grayArt        = imread(fullfile(artIm, sprintf('%d%s', imageNumb, artExt)));
        binArt  = imbinarize(grayArt);
            shortSegs = 90;   % Remover segmentos curtos
        binArt = bwareaopen(binArt,shortSegs,8);
        %% Up and down padding for image 
        I = binArt;
        topPad    = zeros(20, size(I, 2), class(I));
        bottomPad = zeros(20, size(I, 2), class(I));
        I_padded = [topPad; I; bottomPad];
        binArt = I_padded;
        
        
        %% Carregar padrões de bifurcação
        % load('/home/ofelio/Documents/WStation2024/matlab_files_2024/mat_files/extractMxInput.mat');                                                    
        load('/media/ofelio/dragonfly/pt🇵🇹/uc-pt/2025-2026/betaFiles/ocular_disease_intelligent_recognition_ODIR_dataset/odir_dataset/av_segm_left_exposed_vasculature/bifPts3x3.mat');
        
        
        %% Esqueletização
        arterySkeleton  = bwmorph(binArt, 'skeleton', Inf);
        arterySkeleton  = bwmorph(arterySkeleton, 'spur', 5);
        arteryMask      = unweightedBranchIdentificationFunction(arterySkeleton);
        labeledSegs     = bwlabel(arteryMask);
        arteryMask      = unweightedBranchIdentificationFunction(arterySkeleton);
        arterySplit  = weightedBranchIdentificationFunction(arterySkeleton,binArt,25);
        weiSegs         = labeledSegs + arterySplit;
        weiLabeledSegs  = bwlabel(weiSegs > 0);
        
        
        %% Identificação de pontos candidatos
        [m,n] = size(arterySkeleton);
        targetPointCoors = [];
        
        for a = 1:(m-2)
            for b = 1:(n-2)
                window = arterySkeleton(a:a+2, b:b+2);
                matches = all(bsxfun(@eq, window, bifPts3x3), [1 2]);   % vetoriza comparação
                if any(matches)
                    targetPointCoors = [targetPointCoors; a+1, b+1]; %#ok<AGROW>
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
               if arterySkelEndPoints(g:g+2,h:h+2) == endPointExtractorStrel %#ok<BDSCI>
                  arteryEndPCoords = [arteryEndPCoords;[g+1 h+1]];                                       %#ok<AGROW> % extraccao das coordenadas
               end
            end
        end
        arteryEndPCoords(1,:) = [];
        arteryEndPCoords = round(arteryEndPCoords);
        
        coorPoints = [targetPointCoors;arteryEndPCoords];
        coorPoints = sortrows(coorPoints);
        
        %% Inicialização de variáveis
        nTPts     = size(coorPoints,1);
        nSegments = max(weiLabeledSegs(:));
        PredictedAdjacencyMatrix = zeros(nTPts, nTPts);
        %predictedBifurcations    = [];
        
        % Structuring element para dilatação
        dilateSE = strel('disk',5);
        
        %{
        %% Loop paralelo (classificação + matriz de adjacência)
        for i = 1:nTPts
            l = coorPoints(i,:);
            
            
                   
                % Testar ligação com outros pontos candidatos
                for j = 1:nTPts
                    m = coorPoints(j,:);
                        for k = 1:nSegments
                            segMask = (weiLabeledSegs == k);
                            % stats = regionprops(segMask,'MinorAxisLength');
                            width = measureVesselMaxThickness(segMask);
        
                            maskTest = imdilate(labeledSegs==k, dilateSE);
                            maskTest(l(1)-3:l(1)+3, l(2)-3:l(2)+3) = 1;
                            maskTest(m(1)-3:m(1)+3, m(2)-3:m(2)+3) = 1;
                            if bwconncomp(maskTest).NumObjects == 1
                                PredictedAdjacencyMatrix(i,j) = width;
                                PredictedAdjacencyMatrix(j,i) = width;
                            end
                        end
                   
                end
            
        end
        %}
        
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
        outFileName = strcat('left_',num2str(iii),'/left_', num2str(imageNumb), '_arteryAdjMatrixData.mat');
        % Gather back to CPU for saving
        PredictedAdjacencyMatrix = gather(PredictedAdjacencyMatrix);
        coorPoints = gather(coorPoints);
        save(outFileName, 'PredictedAdjacencyMatrix', 'coorPoints');
    end
end
%% Duration
d_end = datetime('now');
fprintf('Duration: %s\n', d_end - t_start);