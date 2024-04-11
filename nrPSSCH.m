function [sym,TBsym,SCI2sym] = nrPSSCH(NumLayers, Modulation, PSSCHcw, SCI2len, SCI1crc, SCI2Enable)
    %% Scrambling, see clause 8.3.1.1 TS 38.211
    Nid = mod(SCI1crc,2^16);  % Decimal representation of the CRC on the PSCCH associated with the PSSCH
    Cinit = (double(Nid) * 2^15) + 1010;
    cwLen = length(PSSCHcw);
    scrambledCW = true(cwLen,1);    

    % Standard-compliant implementation that supports multiple layers (slow)
%     i = 0;
%     j = 0;
%     while i < length(PSSCHcw)
%         if false % If it's an SCI placeholder bit
%           % Not yet implemented
%           j = j +1;
%         else
%             if i < SCI2len
%                 Mij = j;
%                 c = nrPRBS(Cinit,SCI2len);  % pseudorandom binary sequence (PRBS)
%                 out(i+1) = xor(PSSCHcw(i+1),c(i+1-Mij));               
%             else                
%                 Mij = SCI2len;
%                 c = nrPRBS(Cinit,cwLen-SCI2len);  % pseudorandom binary sequence (PRBS)
%                 out(i+1) = xor(PSSCHcw(i+1),c(i+1-Mij));
%             end
%         end
%         i = i +1;
%     end

    % Faster implementation that works only with 1 layer
    assert(NumLayers == 1, "nrPSSCH works only with 1 layer");
    if SCI2Enable
        % 2nd-stage SCI and TB employ two different scrambling sequences
        c = nrPRBS(Cinit,SCI2len);         % pseudorandom binary sequence (PRBS) for scrambling the 2nd-stage SCI
        scrambledCW(1:SCI2len) = xor(PSSCHcw(1:SCI2len),c(1:end));
        c = nrPRBS(Cinit,cwLen-SCI2len);   % pseudorandom binary sequence (PRBS) for scrambling the TB
        scrambledCW(SCI2len+1:end) = xor(PSSCHcw(SCI2len+1:end),c(1:end));
    else
        c = nrPRBS(Cinit,cwLen);   % pseudorandom binary sequence (PRBS) for scrambling the TB
        scrambledCW = xor(PSSCHcw,c);
    end

    %scrambledCW = PSSCHcw; % uncomment to skip scrambling process
   
    %% Modulation, see clause 8.3.1.2 TS 38.211   
    if SCI2Enable
        SCI2 = scrambledCW(1:SCI2len); % 2nd-stage SCI is in front
        TB = scrambledCW(SCI2len+1:end);
        SCI2sym = nrSymbolModulate(SCI2,"QPSK");  % 2nd-stage SCI uses QPSK modulation
        TBsym = nrSymbolModulate(TB,Modulation);

        Msymb1 = length(SCI2sym);
        Msymb2 = length(TBsym);
        Msymb = Msymb1 + Msymb2;

        ModulationOut = cat(1,SCI2sym,TBsym);
    else
        TB = scrambledCW;
        TBsym = nrSymbolModulate(TB,Modulation);
        ModulationOut = TBsym;
        SCI2sym = TBsym;
    end

    % Plot the two constellations (tx side)
%     figure(); hold on;
%     scatter(real(TBsym),imag(TBsym),'*b')
%     scatter(real(sci2sym),imag(sci2sym),'or')

    %% Layer mapping, see clause 8.3.1.3 TS 38.211   
    % Standard-compliant implementation
%     if NumLayers == 1
%         % Initialize output
%         Msymb_layer = Msymb;
%         LayerMappingOut = zeros(Msymb_layer,1,'like',ModulationOut);
%         for ii = 0:Msymb_layer-1
%             LayerMappingOut(ii+1) = ModulationOut(ii+1);
%         end
%     elseif NumLayers == 2
%         Msymb_layer = Msymb/2;
%         LayerMappingOut = zeros(Msymb_layer,2,'like',ModulationOut);
%         for ii = 0:Msymb_layer-1
%             index = 2*ii;
%             LayerMappingOut(ii+1,1) = ModulationOut(index+1);
%             LayerMappingOut(ii+1,2) = ModulationOut(index+2);
%         end
%     else
%         assert(false, "The number of layers should be 1 or 2")
%     end

    % Implementation using Matlab built-in function
    LayerMappingOut = nrLayerMap(ModulationOut,NumLayers);

    %% Precoding, see clause 8.3.1.4 TS 38.211
%    Msymb_ap = Msymb_layer;
    W = eye(NumLayers); % For non-codebook-based transmission, the precoding matrix equals the identity matrix.
    PrecodingOut = LayerMappingOut * W;  % Check the functioning with 2 layers

    sym = PrecodingOut;

end
