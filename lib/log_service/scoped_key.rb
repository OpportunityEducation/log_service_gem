require 'multi_json'
require 'log_service/aes_helper'
require 'log_service/aes_helper_old'

module LogService
  class ScopedKey

    attr_accessor :api_key
    attr_accessor :data

    class << self
      def decrypt!(api_key, scoped_key)
        if api_key.length == 64
          decrypted = LogService::AESHelper.aes256_decrypt(api_key, scoped_key)
        else
          decrypted = LogService::AESHelperOld.aes256_decrypt(api_key, scoped_key)
        end
        data = MultiJson.load(decrypted)
        self.new(api_key, data)
      end
    end

    def initialize(api_key, data)
      self.api_key = api_key
      self.data = data
    end

    def encrypt!(iv = nil)
      json_str = MultiJson.dump(self.data)
      if self.api_key.length == 64
        LogService::AESHelper.aes256_encrypt(self.api_key, json_str, iv)
      else
        LogService::AESHelperOld.aes256_encrypt(self.api_key, json_str, iv)
      end
    end
  end
end
