function vesselSegments = weightedBranchIdentificationFunction(vesselSkeleton, binVasculature, radius)
    %----------------------------------------------------------------------
    % FUNCTION ARGUMENTS:
    % vesselSkeleton -  vasculatura com espessura de 1 pixel para extrair
    %                   coordenadas usando SE's;
    % binVasculature -  imagem binaria com vasculatura representada em
    %                   respectivas espessuras
    % radius         -  raio do SE circular usado para assinalar os 
    %                   T-points a fim de isolar os segmentos de 
    %                   vasculatura   
    %----------------------------------------------------------------------
    % testing script:   A = weightedBranchIdentificationFunction(vesselSkeleton,binVasculature,7); imshow(A)
    %----------------------------------------------------------------------
    % Load known bifurcation patterns
    load bifPts3x3.mat %#ok<LOAD>

    [rows, cols] = size(vesselSkeleton);
    %radius = 6;  % Circle radius in pixels
    img_size = size(binVasculature);

    % Create coordinate grid once for the whole image
    [xGrid, yGrid] = meshgrid(1:img_size(2), 1:img_size(1));
    
    % Copy original vasculature as background
    vesselSegments = binVasculature;

    % Loop over vessel skeleton, ignoring edges
    for i = 1:rows-2
        for j = 1:cols-2
            current_patch = vesselSkeleton(i:i+2, j:j+2);
            
            for d = 1:length(bifPts3x3)
                % Check if current local patch matches a bifurcation pattern
                if isequal(current_patch, bifPts3x3(:,:,d))
                    % Define circle mask centered at detected bifurcation pixel (j,i)
                    circle_mask = ((xGrid - j).^2 + (yGrid - i).^2) <= radius^2;

                    % Since you want black filled circles on existing background,
                    % set circle pixels to 0 (black) in the output image.
                    vesselSegments(circle_mask) = 0;
                    
                    % Break out of the pattern loop once matched
                    break;
                end
            end
        end
    end
end


%{
function vesselSegments = weightedBranchIdentificationFunction(vesselSkeleton, binVasculature)
skelet = vesselSkeleton;
[a,b] = size(skelet);
load bifPts3x3.mat %#ok<LOAD>
for i = 1:a-2
    for j=1:b-2
         for d = 1:length(bifPts3x3) %#ok<USENS>
            if skelet(i:i+2,j:j+2) == bifPts3x3(:,:,d)
                        
                        % Parameters
                        radius = 5;  % Circle radius in pixels
                        img_size = size(binVasculature); % Size of image (modify as needed)
                        center_x = j;  % X-coordinate of center (pixels)
                        center_y = i;  % Y-coordinate of center (pixels)

                        % Create coordinate grid
                        [x, y] = meshgrid(1:img_size(2), 1:img_size(1));

                        % Equation of circle (binary mask)
                        circle_mask = (((x - center_x).^2 + (y - center_y).^2) <= radius^2);
                        % circle_strel = ~circle_mask;
                        imshow(circle_mask);
                            pause(2)
                        imshow(binVasculature);
                            pause(3)

                        imSum = binVasculature + im2uint8(circle_mask);
                        % imSum = imSum == 0;
                        binVasculature = binVasculature + imSum;
                        
                         imshow(binVasculature);
                         pause(3)

                % binVasculature(i:i+2,j:j+2) = 0;
            end
        end
    end
end

vesselSegments = imSum;
%}