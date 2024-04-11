function DMRSsym = nrPSSCHDMRS(DMRSvector,Nslotsymb,nslot,SCI1crc,PSSCHparams,SCI1params)
    Nid = mod(SCI1crc,2^16);
    DMRSpattern = getDMRSpattern(Nslotsymb, SCI1params.TimeResourcePSCCH, PSSCHparams.DMRSLength);  % see Table 8.4.1.1.2-1 TS 38.211       

    offset = 0;
    r_real = zeros(sum(DMRSvector),1);
    r_imm = zeros(sum(DMRSvector),1);
    for DMRSpattern_index = 1:numel(DMRSpattern)             % Iterate over the DMRS time locations
        l = DMRSpattern(DMRSpattern_index);
        numREs = DMRSvector(DMRSpattern_index);
        cinit = mod(2^17*(Nslotsymb*nslot + l + 1)*(2*Nid + 1) + 2*Nid,2^31);
        c = nrPRBS(cinit,numREs*2+1);
        for m = 1:numREs
            index = m + offset;
            r_real(index) = 1/sqrt(2) * (1-2*c(2*m));
            r_imm(index) = 1/sqrt(2) * (1-2*c(2*m+1));           
        end
        offset = offset + numREs;

    end
    DMRSsym = complex(r_real,r_imm)';

    assert(length(DMRSsym) == sum(DMRSvector), "Number of PSSCH-DMRS symbols must match the number of allocated PSSCH-DMRS REs");

    NumLayers = PSSCHparams.NumLayers;  
    W = eye(NumLayers);
    PrecodingOut = W*DMRSsym;  % Check the functioning with 2 layers

    DMRSsym = PrecodingOut';

    % Plot the constellation (tx side)
%     figure(); 
%     scatter(real(DMRSsym),imag(DMRSsym),'or')
end
