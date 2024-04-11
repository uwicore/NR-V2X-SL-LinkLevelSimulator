function [SCIrx,SCIerr,CRCdec] = nrSCIDecode(rxLLR,K,N,E,SCItype) 
    % Rate recovery
    if SCItype == 1
      I_BIL = false;
    else
      I_BIL = true;
    end
   
    decIn = nrRateRecoverPolar(rxLLR,K,N,I_BIL);

    % Polar decode
    L = 8;    % Possible values: [1 2 4 8]
    nMAX = 9;
    iIL = true;
    crcLen = 24;
    decBits = nrPolarDecode(decIn,K,E,L,nMAX,iIL,crcLen);
    
    CRC = decBits(end-24+1:end);
    CRCdec = bi2de(CRC');

    % Compute and remove the CRC. Accordingly, determine if the information
    % was correctly received
    [SCIrx, err] = nrCRCDecode([ones(24,1,class(decBits));decBits],"24C");    
    SCIerr = (err ~= 0); % errored
    SCIrx = SCIrx(25:end);

end