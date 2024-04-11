function TBS = nrTBS_SL(simParams,availableREs,SCI2_REs)
% nrTBS_SL nrSCI2Encode 2nd-stage SCI control information encoding
% TBS = nrTBS_SL(simParams,availableREs,SCI2_REs) evaluates the transport
% block size according to clause 8.1.3.2 TS 38.214. Depending on the
% number of available REs for PSSCH transmission and the number of REs
% allocated for the 2nd-stage SCI, the TB size, TBS, is determined

    if simParams.PSSCH.DMRSLength == 2
        N_RE_DMRS = 12;
    elseif simParams.PSSCH.DMRSLength == 3
        N_RE_DMRS = 18;
    else
        N_RE_DMRS = 24;
    end

    N_prime_RE = 12*(14-2-0) - 0 - N_RE_DMRS;      % see clause 8.1.3.2 TS 38.214
    N_RE = N_prime_RE*simParams.PSSCH.SubchannelSize*simParams.PSSCH.NumSubchannels...
        - simParams.SCI1.TimeResourcePSCCH*simParams.SCI1.FreqResourcePSCCH*12;   % see clause 8.1.3.2 TS 38.214
    assert(availableREs == N_RE, "PSSCH: mismatch between the number of allocated REs and the number of expected REs");
    N_RE = N_RE - SCI2_REs; % Now remove the REs dedicated to the 2nd-stage SCI

    % Now run steps 2), 3) and 4) of clause 5.1.3.2 TS 38.214

    R = simParams.PSSCH.TargetCodeRate;
    Qm = simParams.PSSCH.ModulationOrder;
    v = simParams.PSSCH.NumLayers;   

    % Table 5.1.3.2-1 TS 38.214 
    TBStable = [24 32 40 48 56 64 72 80 88 96 104 112 120 128 136 144 152 160 168 ... 
        176 184 192 208 224 240 256 272 288 304 320 336 352 368 384 408 432 456 ...
        480 504 528 552 576 608 640 672 704 736 768 808 848 888 928 984 1032 1064 ...
        1128 1160 1192 1224 1256 1288 1320 1352 1416 1480 1544 1608 1672 1736 1800 ...
        1864 1928 2024 2088 2152 2216 2280 2408 2472 2536 2600 2664 2728 2792 2856 ...
        2976 3104 3240 3368 3496 3624 3752 3824];

    % Step 2)
    Ninfo = N_RE*R*Qm*v; % intermediate number of information bits

    if Ninfo <= 3824 % Step 3)
        n = max(3, floor( log2(Ninfo) ) - 6);
        Ninfo_prime = max(24, (2^n) * floor( Ninfo/(2^n) ) );
        TableIndex = find(TBStable >= Ninfo_prime,1);         % Get the first TBS index not smaller than Ninfo_prime
        TBS = TBStable(TableIndex);                           % Get the smallest TBS that is not smaller than Ninfo_prime
    else  % Step 4)
        n = floor( log2(Ninfo-24) ) - 5;
        Ninfo_prime = max(3840, (2^n)*round( (Ninfo-24)/(2^n) ) );
   
        if R <= (1/4)
            C = ceil( (Ninfo_prime+24)/3816 );
            TBS = 8*C*ceil( (Ninfo_prime+24)/(8*C) ) - 24;
        else
            if Ninfo_prime > 8424
                C = ceil( (Ninfo_prime+24)/8424 );
                TBS = 8*C*ceil( (Ninfo_prime+24)/(8*C) ) - 24;
            else
                TBS = 8*ceil( (Ninfo_prime+24)/8 ) - 24;
            end
        end
    end



end 