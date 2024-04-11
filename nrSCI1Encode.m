function [SCI1cw,K,N,E,CRCdec] = nrSCI1Encode(Nsubchannel,PSCCHindices)
% nrSCI1 1st-stage SCI encoding
% sci1CW = nrSCI1(simParams,PSCCHindices) first determines the 1st-stage SCI size,
% then encodes its content according to clause 8.3.2, 8.3.3, 8.3.4 TS 38.212
% This function returns the encoded bits, sci1CW

    % First, determine the 1st-stage SCI size, see clause 8.3.1.1 TS 38.212
    Priority = 3;
    MaxNumPerReserve = 2; % see ETSI recommendations
    if MaxNumPerReserve == 2
        FreqResAssignment = ceil( log2( Nsubchannel*(Nsubchannel+1)/2 ) );
    elseif MaxNumPerReserve == 3
        FreqResAssignment = ceil( log2( Nsubchannel*(Nsubchannel+1)*(2*Nsubchannel+1)/6 ) );
    end
    if MaxNumPerReserve == 2
        TimeResAssignment = 5;
    elseif MaxNumPerReserve == 3
        TimeResAssignment = 9;
    end
    ResReservPeriod = 0;
    DMRSpattern = ceil(log2(3)); % see ETSI recommendations
    SCI2format = 2;
    BetaOffsetIndicator = 2;
    NumDMRSport = 1;
    MCSscheme = 5;
    AdditionalMCSTableIndicator = 1; % see ETSI recommendations
    PSFCHoverhead = 0;
    NumReservedBits = 4; % see ETSI recommendations

    SCI1_size = Priority + FreqResAssignment + TimeResAssignment + ResReservPeriod + ...
        DMRSpattern + SCI2format + BetaOffsetIndicator + NumDMRSport + MCSscheme + AdditionalMCSTableIndicator + ...
        PSFCHoverhead + NumReservedBits;
    
    % Then, encode the 1st-stage SCI
    sci1Bits = randi([0 1],SCI1_size,1);
    Qm_SCI1 = 2;                           % 1st-stage SCI employs QPSK, see clause 8.3.2.2 TS 38.211
    E = numel(PSCCHindices)*Qm_SCI1;

    % CRC attachment, Section 8.3.2 TS 38.212
    bitscrcPad = nrCRCEncode([ones(24,1,class(sci1Bits));sci1Bits],'24C'); % prepend 1s
    cVec = bitscrcPad(25:end,1);            % remove 1s. cVec is the 2nd-stage SCI after CRC attachment

    CRC = cVec(length(sci1Bits)+1:end);
    CRCdec = bi2de(CRC');
    
    % Channel coding, Section 8.3.3 TS 38.212
    K = length(cVec);
    nMAX = 9;
    iIL = true;
    encOut = nrPolarEncode(cVec,E,nMAX,iIL);
    N = length(encOut);

    % Rate matching, Section 8.3.4 TS 38.212
    I_BIL = false;
    SCI1cw = nrRateMatchPolar(encOut,K,E,I_BIL);

end