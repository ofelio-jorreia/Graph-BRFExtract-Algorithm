clear all;
clc;
t = now;
d_init = datetime(t,'ConvertFrom','datenum')
%% --- Preprocessamento
% Definição de paths e ficheiros
artIm  = '/media/ofelio/dragonfly/pt🇵🇹/uc-pt/2025-2026/betaFiles/av_split_data/split_29/avseg_output/out_art';
artExt   = '.png';
imageNumb   = 566; % Selecionar imagem
grayArt        = imread(fullfile(artIm, sprintf('%d%s', imageNumb, artExt)));
binArt  = imbinarize(grayArt);
    shortSegs = 90;   % Remover segmentos curtos
binArt = bwareaopen(binArt,shortSegs,8);
%% Up and down padding for image 4288x2848pxl 
I = binArt;
topPad    = zeros(20, size(I, 2), class(I));
bottomPad = zeros(20, size(I, 2), class(I));

I_padded = [topPad; I; bottomPad];

binArt = I_padded;


%% Carregar padrões de bifurcação
% load('/home/ofelio/Documents/WStation2024/matlab_files_2024/mat_files/extractMxInput.mat');                                                    
load('/media/ofelio/dragonfly/pt🇵🇹/uc-pt/2025-2026/betaFiles/av_split_data/bifPts3x3.mat');


%%
% Esqueletização
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
                    end
                end
           
        end
    
end



%% Simetrizar matriz de adjacências
%PredictedAdjacencyMatrix = PredictedAdjacencyMatrix | PredictedAdjacencyMatrix';
PredictedAdjacencyMatrix = max(PredictedAdjacencyMatrix, PredictedAdjacencyMatrix.');
%%
outFileName = strcat('arteryAdjMatrixData_', num2str(imageNumb), '.mat');
save(outFileName, 'PredictedAdjacencyMatrix', 'coorPoints');

%%
%{
%% Calcular espessura usando distance transform - output em nr de pixels
function thickness = measureVesselMaxThickness(segMask)
    % Skeletonize the segment
    skel = bwmorph(segMask,'skel',true);
    % Compute the distance transform
    D = bwdist(~segMask);
    % Measure thickness at each skeleton pixel
    thickness = max(D(skel)); % Local thickness at skeleton pixels
end
%}
%%
t = now;
d_end = datetime(t,'ConvertFrom','datenum')
