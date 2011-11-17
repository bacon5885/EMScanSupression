%% Compute SUM1 and MAX1 maps
close all; 
disp('===============> Getting the SUM1 and MAX1 maps for testing images');
for img = 1:numImage
    multipleResolutionImageName = ['working/multipleResolutionImage' num2str(img)];
    load(multipleResolutionImageName,'J'); 
    for s = 1 : numScale
        storeExponentialModelName = ['storedExponentialModel' num2str(s)];   
        load(storeExponentialModelName,'allFilter','halfFilterSize');
        %% Prepare spaces for variables
        allSizex = zeros(1, numResolution); allSizey = zeros(1, numResolution);        
        %% Compute SUM1 maps
        % use non-inscribed images to compute SUM1 maps, to avoid boundary effects 
        disp(['start filtering image ' num2str(img) ' at Gabor length ' num2str(halfFilterSize*2+1) ' at all resolutions']); tic
		SUM1map = cell(numResolution,numOrient);
		for iRes = 1:numResolution
			SUM1map(iRes,:) = ApplyFilterfftSame(J(iRes), allFilter, localOrNot, localHalfx, localHalfy, doubleOrNot, thresholdFactor);  % filter testing image at all resolutions
        end
		
        disp(['filtering time: ' num2str(toc) ' seconds']);
        %{
        %% inscribe the SUM1 maps into a square bounding box
        % change allSizex and allSizey
        for r = 1:size(SUM1map,1)
            for j = 1:size(SUM1map,2)
                currentOuterBBsize = max(size(SUM1map{r,j}));
                SUM1map{r,j} = single(inscribe([currentOuterBBsize currentOuterBBsize], SUM1map{r,j}, 0));
            end
            allSizex(r) = currentOuterBBsize;
            allSizey(r) = currentOuterBBsize;
        end
        %% also inscribe the source images
        for r = 1:size(SUM1map,1)
            currentOuterBBsize = max(size(J{r}));
            J{r} = single(inscribe([currentOuterBBsize currentOuterBBsize],J{r},255));
        end
        % don't forget to save
        multipleResolutionImageName = ['working/multipleResolutionImage' num2str(img)]; 
        save(multipleResolutionImageName, 'J');
        %}
        
        %% Compute MAX1 maps and track maps
        disp(['start maxing image ' num2str(img) ' at Gabor length ' num2str(halfFilterSize*2+1) ' at all resolutions']); tic
        subsampleM1 = 1;  % to be safe, please refrain from setting it to be larger than 1 
		MAX1map = cell(numResolution,numOrient);
		ARGMAX1map = cell(numResolution,numOrient);
		for iRes = 1:numResolution
			[MAX1map(iRes,:) ARGMAX1map(iRes,:) M1RowShift M1ColShift M1OriShifted] = ...
				mexc_ComputeMAX1( numOrient, SUM1map(iRes,:), locationShiftLimit,... 
				orientShiftLimit, subsampleM1 );
        end
		
        %% sigmoid transformation (modified! was not here before)
        for ii = 1:numel(MAX1map)
            MAX1map{ii} = single( saturation*(2./(1.+exp(-2.*MAX1map{ii}/saturation))-1.) );
            SUM1map{ii} = single( saturation*(2./(1.+exp(-2.*SUM1map{ii}/saturation))-1.) );
        end
        disp(['maxing time: ' num2str(toc) ' seconds']);
        
        % soft thresholding
        for ii = 1:numel(SUM1map)
        	SUM1map{ii}(:) = max(0,SUM1map{ii}(:)-S1softthres);
            MAX1map{ii}(:) = max(0,MAX1map{ii}(:)-S1softthres);
        end
        
        %% Save the maps and spaces
        SUM1MAX1mapName = ['working/SUM1MAX1map' 'image' num2str(img) 'scale' num2str(s)];   
        save(SUM1MAX1mapName, 'SUM1map', 'MAX1map', 'M1RowShift', 'M1ColShift',...
			'M1OriShifted', 'ARGMAX1map', 'J');
    end
end
