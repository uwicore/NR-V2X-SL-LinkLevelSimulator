function DMRSsym = nrPSCCHDMRS(Nslotsymb,nslot,SCI1params,numIndices)

    Nid = 0;  % DMRS Scramble ID, see TS 38.331 
    PSCCHsymbol_index_start = 2;
    PSCCHsymbol_index_stop = PSCCHsymbol_index_start + SCI1params.TimeResourcePSCCH - 1;
    N_DMRS_RB = 3;
    numDMRSperSlot = numIndices/SCI1params.TimeResourcePSCCH;
    r_real = zeros(numIndices,1);
    r_imm = zeros(numIndices,1);
    for l = PSCCHsymbol_index_start:PSCCHsymbol_index_stop                       % Iterate over the PSCCH symbols
        cinit = mod(2^17*(Nslotsymb*nslot + l + 1)*(2*Nid + 1) + 2*Nid,2^31);
        c = nrPRBS(cinit,SCI1params.FreqResourcePSCCH*N_DMRS_RB*2 + 1);
        offset = (l - PSCCHsymbol_index_start)*numDMRSperSlot;
        for m = 1:numDMRSperSlot
            index = m + offset;
            r_real(index) = 1/sqrt(2) * (1-2*c(2*m));
            r_imm(index) = 1/sqrt(2) * (1-2*c(2*m+1));           
        end
    end
  
    DMRSsym = complex(r_real,r_imm);

    assert(length(DMRSsym) == numIndices, "Number of PSCCH-DMRS symbols must match the number of allocated PSCCH-DMRS REs");

    % Plot the constellation (tx side)
%     figure(); 
%     scatter(real(DMRSsym),imag(DMRSsym),'or')

    % Skipped clause 8.4.1.3.2 TS 38.211
    
end 