extends Node

func _ready():
	var aes = AESContext.new()
	var crypto = Crypto.new()
	var text = "This is test txt"
	var key = crypto.generate_random_bytes(32)
	var iv = crypto.generate_random_bytes(16)
	var key_b64 = Marshalls.raw_to_base64(key)
	var iv_b64 = Marshalls.raw_to_base64(iv)
	var combined_string = "%s:%s" % [key_b64, iv_b64]

	aes.start(AESContext.MODE_CBC_ENCRYPT, key, iv)
	var encrypted = aes.update(text.to_utf8_buffer())
	aes.finish()

	aes.start(AESContext.MODE_CBC_DECRYPT, key, iv)
	var decrypted = aes.update(encrypted)
	aes.finish()
