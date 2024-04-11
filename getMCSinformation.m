function [TargetCR, Modulation, ModulationOrder] = getMCSinformation(MCSindex, AdditionalMCSTable)

    Qm_Table1 = [2*ones(1,10) 4*ones(1,7) 6*ones(1,12)];                          % Table 5.1.3.1-1 TS 38.214
    R_Table1 = [120 157 193 251 308 379 449 526 602 679 340 378 434 490 553 ...   % Table 5.1.3.1-1 TS 38.214
        616 658 438 466 517 567 616 666 719 772 822 873 910 948];

    Qm_Table2 = [2*ones(1,5) 4*ones(1,6) 6*ones(1,9) 8*ones(1,8)];                % Table 5.1.3.2-1 TS 38.214
    R_Table2 = [120 193 308 449 602 378 434 490 553 616 658 466 517 567 616 ...   % Table 5.1.3.2-1 TS 38.214
        666 719 772 822 873 682.5 711 754 797 841 885 916.5 948];

    assert((AdditionalMCSTable == 0) || (AdditionalMCSTable == 1), "Additional MCS Table parameter can only be set to 0 or 1");
    if AdditionalMCSTable == 0  % use Table 5.1.3.1-1 TS 38.214
        assert(MCSindex <= 28, "MCS index is out of bound for Table 5.1.3.1-1");
        TargetCR = R_Table1(MCSindex+1) / 1024;
        ModulationOrder = Qm_Table1(MCSindex+1);
    elseif AdditionalMCSTable == 1  % use Table 5.1.3.2-1 TS 38.214
        assert(MCSindex <= 27, "MCS index is out of bound for Table 5.1.3.2-1");
        TargetCR = R_Table2(MCSindex+1) / 1024;
        ModulationOrder = Qm_Table2(MCSindex+1);
    end

    if ModulationOrder == 2
        Modulation = 'QPSK';
    elseif ModulationOrder == 4
        Modulation = '16QAM';
    elseif ModulationOrder == 6
        Modulation = '64QAM';
    elseif ModulationOrder == 8
        Modulation = '256QAM';
    end

end