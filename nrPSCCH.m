function sym = nrPSCCH(SCI1cw)
    %% Scrambling, see clause 8.3.2.1 TS 38.211  
    Cinit = 1010;
    cwLen = length(SCI1cw);
    c = nrPRBS(Cinit,cwLen);  % pseudorandom binary sequence (PRBS)
    out = true(cwLen,1);
    out((1:end)) = xor(SCI1cw((1:end)), c((1:end)));

    %% Modulation, see clause 8.3.2.2 TS 38.211
    sym = nrSymbolModulate(out,"QPSK");

end