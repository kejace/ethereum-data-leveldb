
module Blockchain.SHA (
  SHA(..),
  hash,
  rlp2Word512,
  word5122RLP,
  sha2SHAPtr
  ) where

import Control.Monad
import qualified Crypto.Hash.SHA3 as C
import Data.Binary
import qualified Data.ByteString.Base16 as B16
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as BC
import qualified Data.ByteString.Lazy.Char8 as BLC
import Numeric
import Text.PrettyPrint.ANSI.Leijen hiding ((<$>))

import Blockchain.Data.RLP
import Blockchain.Database.MerklePatricia
import Blockchain.ExtWord
import Blockchain.Util

newtype SHA = SHA Word256 deriving (Show, Eq)

instance Pretty SHA where
  pretty (SHA x) = yellow $ text $ padZeros 64 $ showHex x ""

instance Binary SHA where
  put (SHA x) = sequence_ $ fmap put $ word256ToBytes $ fromIntegral x
  get = do
    bytes <- replicateM 32 get
    let byteString = B.pack bytes
    return (SHA $ fromInteger $ byteString2Integer byteString)

instance RLPSerializable SHA where
  rlpDecode (RLPString s) | length s == 32 = SHA $ decode $ BLC.pack s
  rlpDecode (RLPScalar 0) = SHA 0 --special case seems to be allowed, even if length of zeros is wrong
  rlpDecode x = error ("Missing case in rlpDecode for SHA: " ++ show x)
  --rlpEncode (SHA 0) = RLPNumber 0
  rlpEncode (SHA val) = RLPString $ BC.unpack $ fst $ B16.decode $ BC.pack $ padZeros 64 $ showHex val ""

sha2SHAPtr::SHA->SHAPtr
sha2SHAPtr (SHA x) = SHAPtr $ B.pack $ word256ToBytes x

hash::BC.ByteString->SHA
hash = SHA . fromIntegral . byteString2Integer . C.hash 256

--------------------- Word512 stuff

rlp2Word512::RLPObject->Word512
rlp2Word512 (RLPString s) | length s == 64 = decode $ BLC.pack s
rlp2Word512 x = error ("Missing case in rlp2Word512: " ++ show x)

word5122RLP::Word512->RLPObject
word5122RLP val = RLPString $ BLC.unpack $ encode val

