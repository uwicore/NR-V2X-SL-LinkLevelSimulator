function plotSLgrid(grid,PSSCHind,DMRS_PSSCHind,PSCCHind,DMRS_PSCCHind,AGCind,GuardInd)     % Reverse the index order and plot the resource grid

    gridSize = size(grid);
    numSC = gridSize(1);     % number of subcarriers is the number of rows in the grid
    
    UpsideDown = true;
    
    if ~UpsideDown
        % AGC indices
        AGCind_plot = revertIndices(AGCind, numSC);
        % Guard symbol indices
        GuardInd_plot = revertIndices(GuardInd, numSC);
        % PSCCH DMRS indices
        DMRS_PSCCHind_plot = revertIndices(DMRS_PSCCHind, numSC);
        % PSCCH indices
        PSCCHind_plot = revertIndices(PSCCHind, numSC);
        % PSSCH DMRS indices
        DMRS_PSSCHind_plot = revertIndices(DMRS_PSSCHind, numSC);
        % PSSCH indices
        PSSCHind_plot = revertIndices(PSSCHind, numSC);    
    else
        AGCind_plot = AGCind;
        GuardInd_plot = GuardInd;
        DMRS_PSCCHind_plot = DMRS_PSCCHind;
        PSCCHind_plot = PSCCHind;
        DMRS_PSSCHind_plot = DMRS_PSSCHind;
        PSSCHind_plot = PSSCHind;
    end

    % Correct indexing order
    figure()
    plotGrid = grid(:,:,1);  % Always plot only the first layer
    plotGrid(AGCind_plot) = 0;
    plotGrid(GuardInd_plot) = 0;
    plotGrid(PSSCHind_plot) = 1;
    plotGrid(DMRS_PSSCHind_plot) = 3.5; 
    plotGrid(DMRS_PSCCHind_plot) = 2.75;
    plotGrid(PSCCHind_plot) = 4;

    imagesc(abs(plotGrid))    
end

function outputInd = revertIndices(inputInd, numSC)
    outputInd = zeros(numel(inputInd),1);
    for i = 1:numel(inputInd)
        index = cast(inputInd(i),'double');
        OFDMsymbol_index = floor((index-1)/numSC);
        SC_start = OFDMsymbol_index*numSC + 1;
        SC_stop = SC_start + numSC - 1;
        outputInd(i) = (SC_start - 1) + SC_stop + 1 - index;
    end
    outputInd = sort(outputInd);
    outputInd = uint32(outputInd);
end