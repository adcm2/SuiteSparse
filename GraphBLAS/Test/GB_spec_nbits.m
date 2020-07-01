function bits = GB_spec_nbits (type)
%GB_SPEC_NBITS number of bits in an integer type
%
% bits = GB_spec_nbits ('int16') returns 16.

% SuiteSparse:GraphBLAS, Timothy A. Davis, (c) 2017-2020, All Rights Reserved.
% http://suitesparse.com   See GraphBLAS/Doc/License.txt for license.

switch (type)

    case { 'int8', 'uint8' }
        bits = 8 ;

    case { 'int16', 'uint16' }
        bits = 16 ;

    case { 'int32', 'uint32' }
        bits = 32 ;

    case { 'int64', 'uint64' }
        bits = 64 ;

    otherwise
        error ('invalid type') ;
end

