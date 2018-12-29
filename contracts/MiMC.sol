// Copyright (c) 2018 HarryR
// License: LGPL-3.0+

pragma solidity ^0.5.0;

/**
* Implements MiMC-p/p over the altBN scalar field used by zkSNARKs
*
* See: https://eprint.iacr.org/2016/492.pdf
*
* Round constants are generated in sequence from a seed
*/
contract MiMC
{
    function MiMCpe7( uint256 in_x, uint256 in_k )
        public pure returns(uint256 out_x)
    {
        return MiMCpe7( in_x, in_k, keccak256("mimc"), 91 );
    }

    /**
    * MiMC-p/p with exponent of 7
    * 
    * Recommended at least 46 rounds, for a polynomial degree of 2^126
    */
    function MiMCpe7( uint256 in_x, uint256 in_k, uint256 in_seed, uint256 round_count )
        public pure returns(uint256 out_x)
    {
        assembly {
            if lt(round_count, 3) { revert(0, 0) }
            
            // Initialise round constants, k will be hashed 
            let c := mload(0x40)
            mstore(0x40, add(c, 32))
            mstore(c, in_seed)
            
            let localQ := 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
            
            // First round doesn't include a round constant
            // x = pow(x + k, 7, p)
            let t := addmod(in_x, in_k, localQ)                                     // t = x + k
            let a := mulmod(t, t, localQ)                                           // t^2
            let r := mulmod(mulmod(a, mulmod(a, a, localQ), localQ), t, localQ)     // t^7
            
            // Further n-2 subsequent rounds include a round constant
            for { let i := sub(round_count, 2) } gt(i, 0) { i := sub(i, 1) } {
                // c = H(c)
                mstore(c, keccak256(c, 32))

                // x = pow(x + c_i, 7, p) + k
                t := addmod(addmod(r, mload(c), localQ), in_k, localQ)              // t = x + h_i + k
                a := mulmod(t, t, localQ)                                           // t^2
                r := mulmod(mulmod(a, mulmod(a, a, localQ), localQ), t, localQ)     // t^7
            }
            
            // Result adds key again
            out_x := addmod(r, in_k, localQ)
        }
    }
       
    function MiMCpe7_mp( uint256[] memory in_x, uint256 in_k, uint256 in_seed, uint256 round_count )
        public pure returns (uint256)
    {
        uint256 r = in_k;
        uint256 localQ = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

        for( uint256 i = 0; i < in_x.length; i++ )
        {
            r = (r + in_x[i] + MiMCpe7(in_x[i], r, in_seed, round_count)) % localQ;
        }
        
        return r;
    }

    function MiMCpe7_mp( uint256[] memory in_x, uint256 in_k )
        public pure returns(uint256 out_x)
    {
        return MiMCpe7_mp( in_x, in_k, keccak256("mimc"), 91 );
    }
}