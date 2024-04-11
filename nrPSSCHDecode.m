function [TBbits, SCI2bits, TBsymbols, SCI2symbols] = nrPSSCHDecode(Modulation,RxSymbols,SCI2len,nVar,SCI1crc,SCI2Enable,NumLayers)
    %% MIMO deprecoding
    W = eye(NumLayers);
    deprecoded = RxSymbols * pinv(W);
        
    % When transform precoding is disabled, all the symbols are data symbols
    detransformedData = deprecoded;

    %% Layer demapping
    % Implementation using Matlab built-in function
    symbols = nrLayerDemap(detransformedData);
    symbols = symbols{1};

    %% Demodulation
    if SCI2Enable
        SCI2symbols_length = SCI2len/2; % QPSK modulation
        SCI2symbols = symbols(1:SCI2symbols_length);
        TBsymbols = symbols(SCI2symbols_length+1:end);
        SCI2demod = nrSymbolDemodulate(SCI2symbols,"QPSK",nVar);
        TBdemod = nrSymbolDemodulate(TBsymbols,Modulation,nVar);    
        PSSCHcw = cat(1,SCI2demod,TBdemod);
    else
        TBsymbols = symbols;
        SCI2symbols = TBsymbols;
        TBdemod = nrSymbolDemodulate(TBsymbols(:),Modulation,nVar);    
        PSSCHcw = TBdemod;
    end
    
    %% Descrambling
    % Create scrambling sequence
    xInd = zeros(0,1);
    yInd = zeros(0,1);

    opts.MappingType = 'signed';
    opts.OutputDataType = class(PSSCHcw);
    Nid = mod(SCI1crc,2^16);
    Cinit = (double(Nid) * 2^15) + 1010;
    cwLen = length(PSSCHcw);

    if SCI2Enable
        SCI2bits = SCI2demod;
        c = nrPRBS(Cinit,SCI2len,opts);  % pseudorandom binary sequence (PRBS)
        SCI2bits(1:end) = SCI2demod(1:end) .* c(1:end);  % soft bits

        TBbits = TBdemod;
        c = nrPRBS(Cinit,cwLen-SCI2len,opts);  % pseudorandom binary sequence (PRBS)
        TBbits(1:end) = TBdemod(1:end) .* c(1:end);  % soft bits
    else
        TBbits = TBdemod;
        c = nrPRBS(Cinit,cwLen,opts);  % pseudorandom binary sequence (PRBS)
        TBbits(1:end) = TBdemod(1:end) .* c(1:end);  % soft bits
        SCI2bits = TBbits;
    end
    %SCI2bits = PSSCHcw(1:SCI2len);  % uncomment to skip descrambling
    %TBbits = PSSCHcw(SCI2len+1:end);  % uncomment to skip descrambling

end