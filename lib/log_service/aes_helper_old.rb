require 'openssl'
require 'digest'
require 'base64'

module LogService
  class AESHelperOld

    BLOCK_SIZE = 32

    class << self
      def aes256_decrypt(key, iv_plus_encrypted)
        padded_key = pad(key)
        unhexed_iv_plus_encrypted = unhexlify(iv_plus_encrypted)
        iv = unhexed_iv_plus_encrypted[0, 16]
        encrypted = unhexed_iv_plus_encrypted[16, unhexed_iv_plus_encrypted.length]
        aes = OpenSSL::Cipher::AES.new(256, :CBC)
        aes.decrypt
        aes.key = padded_key
        aes.iv = iv
        aes.update(encrypted) + aes.final
      end

      def aes256_encrypt(key, plaintext, iv = nil)
        padded_key = pad(key)
        aes = OpenSSL::Cipher::AES.new(256, :CBC)
        aes.encrypt
        aes.key = padded_key
        aes.iv = iv unless iv.nil?
        iv ||= aes.random_iv
        encrypted = aes.update(plaintext) + aes.final
        hexlify(iv) + hexlify(encrypted)
      end

      def hexlify(msg)
        msg.unpack('H*')[0]
      end

      def unhexlify(msg)
        [msg].pack('H*')
      end

      def pad(msg)
        pad_len = BLOCK_SIZE - (msg.length % BLOCK_SIZE)
        padding = pad_len.chr * pad_len
        padded = msg + padding
        padded
      end
    end
  end
end