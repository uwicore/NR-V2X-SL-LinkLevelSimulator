function validateSidelinkInputs(simParams)
    % Check that the number of layers is 1 (maximum 2 later)
    assert(simParams.PSSCH.NumLayers == 1, "Only one layer is supported");

    % Check that the number of subchannels is not larger than the total
    % number of subchannels
    assert(simParams.PSSCH.NumSubchannels <= simParams.PSSCH.TotalNumSubchannels, ...
        "Number of subchannels cannot be larger than the total number of available sub-channels");

    % Check the number of sidelink symbols
    % see sl-TimeResourcePSCCH in TS 38.331
    assert((simParams.SCI1.TimeResourcePSCCH == 2) || (simParams.SCI1.TimeResourcePSCCH == 3),...
        "Invalid input for simulation parameter: TimeResourcePSCCH");

    % Check the number of sidelink symbols
    % see sl-FreqResourcePSCCH in TS 38.331    
%     assert((simParams.SCI1.FreqResourcePSCCH == 10) || (simParams.SCI1.FreqResourcePSCCH == 12) || ...
%         (simParams.SCI1.FreqResourcePSCCH == 15) || (simParams.SCI1.FreqResourcePSCCH == 20) || (simParams.SCI1.FreqResourcePSCCH == 25),...
%         "Invalid input for simulation parameter: FreqResourcePSCCH");    

    % Check the 2nd-stage SCI format
    assert(strcmp(simParams.SCI2.Format,"2A") || strcmp(simParams.SCI2.Format,"2B"), "Invalid 2nd-stage SCI format");

    % Check the number of sidelink symbols
    % see sl-LengthSymbols in TS 38.331
    assert(simParams.Carrier.SymbolsPerSlot == 14, "Invalid number of symbols per slot. The simulator works only with 14 symbols (TBC)")
%    assert((simParams.PSSCH.LengthSymbols >= 7) && (simParams.PSSCH.LengthSymbols <= 14), "Invalid number of symbols per slot")

    % Check the subchannel size
    % see sl-SubchannelSize in TS 38.331
    assert((simParams.PSSCH.SubchannelSize == 10) || (simParams.PSSCH.SubchannelSize == 12) || (simParams.PSSCH.SubchannelSize == 15) || ...
        (simParams.PSSCH.SubchannelSize == 20) || (simParams.PSSCH.SubchannelSize == 25) || (simParams.PSSCH.SubchannelSize == 50) || ...
        (simParams.PSSCH.SubchannelSize == 75) || (simParams.PSSCH.SubchannelSize == 100), "Invalid subchannel size")

    % Check the PSCCH frequency size,
    % see sl-FreqResourcePSCCH in TS 38.331
%     assert(simParams.SCI1.FreqResourcePSCCH <= simParams.PSSCH.SubchannelSize, "FreqResourcePSCCH must be smaller than SubchannelSize")


    % Check the DMRS pattern
    % see Table 8.4.1.1.2-1 in TS 38.331
    if (simParams.Carrier.SymbolsPerSlot == 6) || (simParams.Carrier.SymbolsPerSlot == 7) || (simParams.Carrier.SymbolsPerSlot == 8)
       assert (simParams.PSSCH.DMRSLength == 2, "Invalid number of PSSCH DM-RS")
    elseif (simParams.Carrier.SymbolsPerSlot == 9) || (simParams.Carrier.SymbolsPerSlot == 10)
       assert ((simParams.PSSCH.DMRSLength == 2) || (simParams.PSSCH.DMRSLength == 3), "Invalid number of PSSCH DM-RS")
    else
       assert (simParams.PSSCH.DMRSLength <= 4, "Invalid number of PSSCH DM-RS")
    end
end
