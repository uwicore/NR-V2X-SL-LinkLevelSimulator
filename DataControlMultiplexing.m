function outCW = DataControlMultiplexing(TBbits,SCI2bits,NumLayers)
% DataControlMultiplexing implemented according to clause 8.2.1 TS 38.212
% Multiplexes SCH and 2nd-stage SCI in a single output codeword, outCW

    G_TB = length(TBbits);
    G_SCI2 = length(SCI2bits);
    G = G_TB + G_SCI2;
    Qm_SCI2 = 2;

    outCW = zeros(G,1);

    assert(NumLayers == 1,"Number of layers cannot be larger than 1");
    
    if NumLayers == 1
        for i = 1:G
            if (i >= 1) && (i < G_SCI2+1)
                outCW(i) = SCI2bits(i);
            end
            if (i >= G_SCI2+1) && (i <= G)
                 outCW(i) = TBbits(i-G_SCI2);
            end
        end
        assert(numel(outCW) == numel(TBbits) + numel(SCI2bits), "Mismatch between output codeword length and input size")
    end

%     if NumLayers == 2
%         % Not implemented yet
%     end



end