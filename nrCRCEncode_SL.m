function blkcrc = nrCRCEncode_SL(blk, poly, varargin)
%nrCRCEncode Cyclic redundancy check calculation and appending
%   BLKCRC = nrCRCEncode(...) calculates a CRC for the input data block and
%   returns a copy of the data block with the CRC parity bits,
%   p0,p1...pL-1, appended to it. The function provides an option for the
%   CRC parity bits to be masked.
%
%   BLKCRC = nrCRCEncode(BLK,POLY) calculates the CRC defined by POLY for
%   input data block BLK and returns a copy of the input with the CRC
%   appended in BLKCRC. BLK is a matrix (double, int8 or logical) where
%   each column is treated as a separate data block and processed
%   independently. For the purpose of CRC calculation, any non-zero element
%   of the input is treated as logical 1 while zeros are treated as logical
%   0. The CRC polynomial is defined by a value from the set
%   ('6','11','16','24A','24B','24C'). See TS 38.212 Section 5.1 for the
%   associated polynomials.
%
%   BLKCRC = nrCRCEncode(BLK,POLY,MASK) behaves as above except the third
%   parameter allows the appended CRC bits to be xor masked with the scalar
%   nonnegative integer value of MASK. This mask is typically an RNTI. The
%   MASK value is applied to the CRC bits MSB first/LSB last, i.e. (p0 xor
%   m0),(p1 xor m1),...(pL-1 xor mL-1), where m0 is the MSB on the binary
%   representation of the mask. If the mask value is greater than 2^L - 1,
%   then LSB 'L' bits are considered for mask.
%
%   Example 1:
%   % The CRC associated with an all zero matrix of two data blocks, return
%   % an all zero matrix of size 124x2.
%
%   crc1 = nrCRCEncode(zeros(100,2),'24C');
%   any(crc1(:,1:2))
%
%   Example 2:
%   % The CRC bits are masked in a MSB first order, resulting in all zeros
%   % apart from a single one in the last element position.
%
%   crc2 = nrCRCEncode(zeros(100,2),'24C',1);
%   crc2(end-5:end,1:2)
%
%   See also nrCRCDecode, nrCodeBlockSegmentLDPC, nrPolarEncode,
%   nrLDPCEncode, nrRateMatchPolar, nrRateMatchLDPC, nrBCH, nrDCIEncode.

%   Copyright 2018 The MathWorks, Inc.

%#codegen

    % Persistent variable to store CRC system objects for all polynomials
    persistent encoders;
    narginchk(2,3);

    % Initialize inputs
    if nargin == 3 && ~isempty(varargin{1})
        mask = varargin{1};
    else
        mask = 0;
    end

    % Validate inputs and get properties
    polyIndex = nr5g.internal.validateCRCinputs(blk,poly,mask,'nrCRCEncode');
    polyLengths = [6 11 16 24 24 24];
    gLen = 0;   % Initialize for codegen
    gLen(:) = polyLengths(polyIndex);

    % Perform cyclic redundancy check
    [codeLen,numCodeBlocks] = size(blk);
    blkL = logical(blk);
    if isempty(blk)
        blkcrc = zeros([0,numCodeBlocks],'like',blk);
    else
        blkcrcL = false(codeLen+gLen,numCodeBlocks);

        if isempty(coder.target) % Simulation path

            % Initialize CRC encoder system objects for each NR polynomial
            if isempty(encoders)
                encoders = cell(1,6);
                polyCell = {[1 1 0 0 0 0 1]', ...                             % '6'
                    [1 1 1 0 0 0 1 0 0 0 0 1]', ...                           % '11'
                    [1 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 1]', ....                % '16'
                    [1 1 0 0 0 0 1 1 0 0 1 0 0 1 1 0 0 1 1 1 1 1 0 1 1]', ... % '24A'
                    [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 1 1]', ... % '24B'
                    [1 1 0 1 1 0 0 1 0 1 0 1 1 0 0 0 1 0 0 0 1 0 1 1 1]'};    % '24C'
                for i = 1:6
                    encoders{i} = comm.CRCGenerator('Polynomial',polyCell{i});
                end
            end
            encoder = encoders{polyIndex};

            for i = 1:numCodeBlocks
                blkcrcL(:,i) = encoder(blkL(:,i));
            end

        else    % Codegen path

            gPoly = getPoly(poly);
            for i = 1:numCodeBlocks
                blkcrcL(:,i) = crcEncode(double(blkL(:,i)),gPoly,gLen);
            end

        end

        if mask
            % Convert decimal mask to bits
            maskBits = comm.internal.utilities.de2biBase2LeftMSB( ...
                double(mask),gLen)';
            blkcrcL(end-gLen+1:end,:) = xor(blkcrcL(end-gLen+1:end,:), ...
                repmat(maskBits>0,[1 numCodeBlocks]));
        end
        blkcrc = [blk; cast(blkcrcL(end-gLen+1:end,:),class(blk))];
    end

end

function out = crcEncode(in,gPoly,gLen)
% CRC Encode with all doubles inputs, logical out.

    % Append zeros to the data block
    inPad = [in; zeros(gLen,1)];

    % Perform cyclic redundancy check
    remBits = [0; inPad(1:gLen,1)];
    for i = 1:length(inPad)-gLen
        dividendBlk = [remBits(2:end); inPad(i+gLen)];
        if dividendBlk(1) == 1
            remBits = rem(gPoly+dividendBlk,2);
        else
            remBits = dividendBlk;
        end
    end
    parityBits = remBits(2:end);

    out = logical([in; parityBits]);

end

function gPoly = getPoly(poly)
% Initialize CRC polynomial (gPoly)

    switch poly
        case '6'
            gPoly = [1 1 0 0 0 0 1]';
        case '11'
            gPoly = [1 1 1 0 0 0 1 0 0 0 0 1]';
        case '16'
            gPoly = [1 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 1]';
        case {'24a','24A'}
            gPoly = [1 1 0 0 0 0 1 1 0 0 1 0 0 1 1 0 0 1 1 1 1 1 0 1 1]';
        case {'24b','24B'}
            gPoly = [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 1 1]';
        otherwise % {'24c','24C'}
            gPoly = [1 1 0 1 1 0 0 1 0 1 0 1 1 0 0 0 1 0 0 0 1 0 1 1 1]';
    end

end
