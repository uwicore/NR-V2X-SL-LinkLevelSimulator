function sciCW = nrSCIEncode(sciBits,rnti,E)
%nrDCIEncode Downlink control information encoding
%   DCICW = nrDCIEncode(DCIBITS,RNTI,E) encodes the input DCI bits,
%   DCIBITS, as per TS 38.212 Sections 7.3.2, 7.3.3 and 7.3.4 to output the
%   rate-matched coded block, DCICW, of specified length E. The processing
%   includes CRC attachment, polar coding and rate matching.
%   RNTI specifies the Radio Network Temporary Identifier that is used to
%   mask the appended CRC bits.
%   The input DCIBITS must be a binary column vector corresponding to the
%   DCI bits and the output is a binary column vector of length E.
%
%   % Example:
%   % Perform DCI encoding for RNTI as 100 and output length E as 240.
%
%   RNTI = 100;
%   E = 240;
%   dcicw = nrDCIEncode(randi([0 1],32,1),RNTI,E);
%
%   See also nrDCIDecode, nrPDCCH, nrPDCCHDecode.

%   Copyright 2018 The MathWorks, Inc.

%#codegen

%   Reference:
%   [1] 3GPP TS 38.212, "3rd Generation Partnership Project; Technical
%   Specification Group Radio Access Network; NR; Multiplexing and channel
%   coding (Release 15). Section 7.3.

    % Validate inputs
  %  validateInputs(sciBits,rnti,E);

    % CRC attachment, Section 7.3.2, [1]
%    bitscrcPad = nrCRCEncode([ones(24,1,class(sciBits));sciBits], ...
%        '24C',rnti);                        % prepend 1s
%    cVec = bitscrcPad(25:end,1);            % remove 1s

    % Channel coding, Section 7.3.3, [1]
%    K = length(cVec);
%    encOut = nrPolarEncode(cVec,E);

    % Rate matching, Section 7.3.4, [1]
 %   sciCW = nrRateMatchPolar(encOut,K,E);

end


% function validateInputs(sciBits,rnti,E)
% % Check inputs
% 
%     fcnName = 'nrSCIEncode';
% 
%     % Validate input DCI message bits, length must be greater than or equal
%     % to 12 and less than or equal to 140
%     validateattributes(sciBits,{'int8','double'},{'binary','column'}, ...
%         fcnName,'SCIBITS');
%     Kin = length(sciBits);
%     coder.internal.errorIf( Kin<12 || Kin>140, ...
%         'nr5g:nrDCIEncode:InvalidInputLength',Kin);
% 
%     % Validate radio network temporary identifier RNTI (0...65535)
%     validateattributes(rnti,{'numeric'}, ...
%         {'scalar','nonnegative','integer','<=',2^16-1},fcnName,'RNTI');
% 
%     % Validate rate matched output length which must be greater than K+24
%     validateattributes(E,{'numeric'}, ...
%         {'scalar','integer','>',Kin+24},fcnName,'E');
% 
% end
