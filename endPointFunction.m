function output = endPointFunction(skeleton)

%k = labeledSegs();
% k = vesselMask;
k = skeleton;
[a,b] = size(k);
output = zeros(a,b);
for i = 2:a-1
    for j = 2:b-1
        ws = [k(i-1,j-1),k(i-1,j),k(i-1,j+1),k(i,j-1),k(i,j),k(i,j+1)...
            k(i+1,j-1),k(i+1,j),k(i+1,j+1)];
        kg = sum(ws);
        if (k(i,j) == 1 && kg ==2)
            output(i,j) = 1;
        end
    end
end
%figure;
output = imdilate(output, strel('diamond',1));    % strel('disk',3));
%imshow (output+k)