function [RXsci2,sci2err] = nrSCI2Decode(rxLLR,K,N,E) 

    % Rate matching, Section 8.4.4 TS 38.212
    I_BIL = true;
    decIn = nrRateRecoverPolar(rxLLR,K,N,I_BIL);

    % Polar decode
    L = 8;    
    nMAX = 9;
    iIL = true;
    crcLen = 24;
    decBits = nrPolarDecode(decIn,K,E,L,nMAX,iIL,crcLen);
    
    % Remove CRC
    [RXsci2, err] = nrCRCDecode([ones(24,1,class(decBits));decBits],"24C");
   % [RXsci2, err] = nrCRCDecode(decBits,"24C");   
    sci2err = (err ~= 0); % errored

end