defmodule StreamClosedCaptionerPhoenix.Encryption.AES do
  @moduledoc """
  Provides AES-256-GCM encryption for sensitive data fields.
  
  This module implements field-level encryption for sensitive data like API keys.
  Uses AES-256 in GCM mode for authenticated encryption.
  """

  @aad "StreamClosedCaptionerPhoenix"

  @doc """
  Encrypts a value using AES-256-GCM.
  Returns the encrypted binary with IV and tag prepended.
  """
  def encrypt(nil), do: nil
  def encrypt(""), do: nil
  
  def encrypt(plaintext) when is_binary(plaintext) do
    key = get_encryption_key()
    iv = :crypto.strong_rand_bytes(16)
    
    {ciphertext, tag} = 
      :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, @aad, true)
    
    # Format: IV (16 bytes) + Tag (16 bytes) + Ciphertext
    iv <> tag <> ciphertext
  end

  @doc """
  Decrypts a value encrypted with encrypt/1.
  Returns the original plaintext or nil if decryption fails.
  """
  def decrypt(nil), do: nil
  def decrypt(""), do: nil
  
  def decrypt(<<iv::binary-16, tag::binary-16, ciphertext::binary>>) do
    key = get_encryption_key()
    
    case :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, ciphertext, @aad, tag, false) do
      plaintext when is_binary(plaintext) -> plaintext
      :error -> nil
    end
  rescue
    _ -> nil
  end
  
  def decrypt(_), do: nil

  # Gets the encryption key from configuration.
  # Key must be 32 bytes (256 bits) for AES-256.
  defp get_encryption_key do
    key = 
      Application.get_env(:stream_closed_captioner_phoenix, :encryption_key) ||
      System.get_env("ENCRYPTION_KEY")
    
    case key do
      nil ->
        raise """
        Encryption key not configured!
        
        Set ENCRYPTION_KEY environment variable or configure in config/runtime.exs:
        
        config :stream_closed_captioner_phoenix, encryption_key: "your-32-byte-base64-key"
        
        Generate a key with:
        
        mix run -e "IO.puts(:crypto.strong_rand_bytes(32) |> Base.encode64())"
        """
      
      key when is_binary(key) ->
        case Base.decode64(key) do
          {:ok, decoded} when byte_size(decoded) == 32 ->
            decoded
          
          {:ok, decoded} ->
            raise "Encryption key must be 32 bytes, got #{byte_size(decoded)} bytes"
          
          :error ->
            raise "Encryption key must be base64 encoded"
        end
    end
  end
end
