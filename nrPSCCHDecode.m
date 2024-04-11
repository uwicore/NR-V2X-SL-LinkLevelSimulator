function [SCI1bits, SCI1symbols] = nrPSCCHDecode(RxSymbols,nVar)
    %% Demodulation, see clause 8.3.2.2 TS 38.211
    SCI1symbols = RxSymbols;
    DemodBits = nrSymbolDemodulate(RxSymbols,"QPSK",nVar);

    %% Descrambling, see clause 8.3.2.1 TS 38.211  
    % Create scrambling sequence
    opts.MappingType = 'signed';
    opts.OutputDataType = class(DemodBits);
    Cinit = 1010;
    cwLen = length(DemodBits);
    c = nrPRBS(Cinit,cwLen,opts);  % pseudorandom binary sequence (PRBS)
    SCI1bits = DemodBits;
%    dataIndex = (1:end)
    SCI1bits(1:end) = DemodBits(1:end) .* c(1:end);  % soft bits
end