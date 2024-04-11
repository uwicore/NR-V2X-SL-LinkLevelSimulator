function DMRSpattern = getDMRSpattern(LengthSymbols, PSCCHduration, DMRSnumber)

    l_d = [6; 7; 8; 9; 10; 11; 12; 13];
    l_bar_PSCCH2_DMRS2 = [1 5; 1 5; 1 5; 3 8; 3 8; 3 10; 3 10; 3 10];
    l_bar_DMRS3 = [nan nan nan; nan nan nan; nan nan nan; 1 4 7; 1 4 7; 1 5 9; 1 5 9; 1 6 11];
    l_bar_DMRS4 = [nan nan nan nan; nan nan nan nan; nan nan nan nan; nan nan nan nan; nan nan nan nan; ...
        1 4 7 10; 1 4 7 10; 1 4 7 10];
    l_bar_PSCCH3_DMRS2 = [1 5; 1 5; 1 5; 4 8; 4 8; 4 10; 4 10; 4 10];

    T = table(l_d, l_bar_PSCCH2_DMRS2, l_bar_DMRS3, l_bar_DMRS4, l_bar_PSCCH3_DMRS2);
    T.Properties.VariableNames = ["l_d in symbols", "PSCCH 2, DMRS 2", "PSCCH 2/3, DMRS 3", "PSCCH 2/3, DMRS 4", "PSCCH 3, DMRS 2"];
    
    if DMRSnumber == 2
        if PSCCHduration == 2
            colIndex = 2;
        else
            colIndex = 5;
        end
    elseif DMRSnumber == 3
        colIndex = 3;
    else
        colIndex = 4;
    end

    rowIndex = LengthSymbols - 6;
    DMRSpattern = table2array(T(rowIndex, colIndex));

    for i = 1:numel(DMRSpattern)              % Add 1 to the symbol time-domain location for proper indexing
        DMRSpattern(i) = DMRSpattern(i) + 1;
    end
end 