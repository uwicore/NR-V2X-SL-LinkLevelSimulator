function [PSSCHind,DMRS_PSSCHind,PSCCHind,DMRS_PSCCHind,AGCind,GuardInd,DMRS_Counters] = nrSidelinkIndices(grid,PSSCHparams,SCI1params)

    gridSize = size(grid);
    numSymbols = gridSize(2);  % number of symbols is the number of columns in the grid
    numSC = gridSize(1);       % number of subcarriers is the number of rows in the grid

    %% Compute AGC indices (first symbol)
    AGCind = transpose( (1:1:numSC) );
    AGCind = uint32(AGCind);

    %% Compute guard symbol indices (last symbol)
    GuardInd_start = numSC*(numSymbols - 1) + 1;
    GuardInd_stop = GuardInd_start + numSC - 1;
    GuardInd = transpose( (GuardInd_start:1:GuardInd_stop) );
    GuardInd = uint32(GuardInd);

    %% Compute the PSCCH indices and PSCCH DMRS indices
    PSCCHind = zeros(SCI1params.TimeResourcePSCCH*SCI1params.FreqResourcePSCCH*12,1);            % Initialize empty vector
    jj = 1;

    % PSCCH indices, as indicated in clause 16.4 TS 38.213
    PSCCHsymbol_index_start = 2;
    PSCCHsymbol_index_stop = PSCCHsymbol_index_start + SCI1params.TimeResourcePSCCH - 1;
    for PSCCHsymbol_index = PSCCHsymbol_index_start:PSCCHsymbol_index_stop                       % Iterate over the PSCCH symbols
        PSCCHind_index_start = numSC*(PSCCHsymbol_index - 1) + 1;
        PSCCHind_index_stop = numSC*(PSCCHsymbol_index - 1) + SCI1params.FreqResourcePSCCH*12;
        for PSCCHind_index = PSCCHind_index_start:PSCCHind_index_stop                            % Iterate over the REs in the frequency domain
            PSCCHind(jj) = PSCCHind_index;                                                       % Assign the index value
            jj = jj + 1;
        end
    end
    PSCCHind = uint32(PSCCHind);

    % PSCCH DMRS indices
    DMRS_PSCCHind = uint32.empty;                                  % Initialize empty array for DMRS indices
    jj = 1;
    for PSCCHsymbol_index = PSCCHsymbol_index_start:PSCCHsymbol_index_stop                       % Iterate over the PSCCH symbols
        n = 0;
        k = 0;
        offset = (PSCCHsymbol_index-1)*numSC + 1;
        while k <= numSC     
            k_prime = 0;
            k = n*12 + 4*k_prime + 1;
      %      if ismember(k + offset, PSCCHind)
            if ismember(k + offset, PSCCHind) && not(ismember(k + offset, DMRS_PSCCHind))
                DMRS_PSCCHind(jj) = k + offset;
                jj = jj + 1;
            end
            k_prime = 1;
            k = n*12 + 4*k_prime + 1;
      %      if ismember(k + offset, PSCCHind)
            if ismember(k + offset, PSCCHind) && not(ismember(k + offset, DMRS_PSCCHind))                
                DMRS_PSCCHind(jj) = k + offset;
                jj = jj + 1;
            end
            k_prime = 2;
            k = n*12 + 4*k_prime + 1;
      %      if ismember(k + offset, PSCCHind) 
            if ismember(k + offset, PSCCHind) && not(ismember(k + offset, DMRS_PSCCHind))                
                DMRS_PSCCHind(jj) = k + offset;
                jj = jj + 1;
            end            
            n = n + 1;
        end
    end
    DMRS_PSCCHind = transpose(DMRS_PSCCHind);
    PSCCHind = setdiff(PSCCHind, DMRS_PSCCHind);                % Remove indices associated with DMRS symbols (data transmitted in empty DMRS)

    %% Compute the PSSCH and PSSCH DMRS indices
    DMRSpattern = getDMRSpattern(numSymbols, SCI1params.TimeResourcePSCCH, PSSCHparams.DMRSLength);  % see Table 8.4.1.1.2-1 TS 38.211

    % Get the list of PSSCH indices
    PSSCHind = transpose( (1:1:numSC*numSymbols) );
    PSSCHind = setdiff(PSSCHind,AGCind);              % Remove AGC indices
    PSSCHind = setdiff(PSSCHind,GuardInd);            % Remove guard symbol indices
    PSSCHind = setdiff(PSSCHind,PSCCHind);            % Remove PSCCH indices
    PSSCHind = setdiff(PSSCHind,DMRS_PSCCHind);       % Remove PSCCH DMRS indices
    PSSCHind = uint32(PSSCHind);


    
    % Initialize the reference list of DMRS indices (entire freq. axis)
    % Actually, DMRS symbols are allocated every 2 REs in the freq. domain
    DMRS_PSSCHind_ref = zeros(numSC*numel(DMRSpattern),1);
    jj = 1;
    for DMRSpattern_index = 1:numel(DMRSpattern)             % Iterate over the DMRS time locations
        DMRSsymbol_index = DMRSpattern(DMRSpattern_index);
        DMRSindex_start = numSC*(DMRSsymbol_index - 1) + 1;
        DMRSindex_stop = DMRSindex_start + numSC - 1;
        for DMRSindex = DMRSindex_start:DMRSindex_stop
            DMRS_PSSCHind_ref(jj) = DMRSindex;
            jj = jj + 1;
        end

    end

    DMRS_Counters = zeros(1,numel(DMRSpattern));  % Track the number of DMRS REs allocated at each symbol
    ii = 1;

    DMRS_PSSCHind = uint32.empty;                                  % Initialize empty array for DMRS indices
    jj = 1;
    for DMRSpattern_index = 1:numel(DMRSpattern)             % Iterate over the DMRS time locations
        DMRSsymbol_index = DMRSpattern(DMRSpattern_index);
        n = 0;
        k = 0;
        while k <= numSC                                     % Get the DMRS frequency location k, see clause 6.4.1.1.3 TS 38.211
            offset = (DMRSsymbol_index-1)*numSC + 1;
            k_prime = 0;
            k = 4*n + 2*k_prime;
            if ismember(k + offset, DMRS_PSSCHind_ref) && ismember(k + offset, PSSCHind)
                DMRS_PSSCHind(jj) = k + offset;
                jj = jj + 1;                
            end
            k_prime = 1;
            k = 4*n + 2*k_prime;
            if ismember(k + offset, DMRS_PSSCHind_ref) && ismember(k + offset, PSSCHind)
                DMRS_PSSCHind(jj) = k + offset;
                jj = jj + 1;
            end
            n = n + 1;
        end
        if ii == 1
            DMRS_Counters(ii) = jj - 1;
            ii = ii + 1;
        else
            DMRS_Counters(ii) = jj - 1 - sum(DMRS_Counters);
            ii = ii + 1;
        end
    end 
    DMRS_PSSCHind = transpose(DMRS_PSSCHind);

 %   PSSCHind = setdiff(PSSCHind, DMRSind_ref);           % Remove indices associated with DMRS symbols (no data transmitted in empty DMRS)
    PSSCHind = setdiff(PSSCHind, DMRS_PSSCHind);                % Remove indices associated with DMRS symbols (data transmitted in empty DMRS)

    for PSCCHsymbol_index = PSCCHsymbol_index_start:PSCCHsymbol_index_stop  
        if ismember(PSCCHsymbol_index,DMRSpattern)
            assert(PSSCHparams.SubchannelSize >= 20,...
                "Mapping of PSSCH DMRS and PSCCH to the same OFDM symbol is allowed only if the subchannel size is >= 20 PRBs")
        end        
    end
    % Plot the grid: upside down indexing order
%     figure()
%     plotGrid = grid(:,:,1);
%     plotGrid(AGCind) = 0;
%     plotGrid(GuardInd) = 0;
%     plotGrid(PSSCHind) = 1;
%     plotGrid(DMRS_PSSCHind) = 3.5;
%     plotGrid(DMRS_PSCCHind) = 2.75;
%     plotGrid(PSCCHind) = 4;
% 
%     imagesc(abs(plotGrid))
    
end
