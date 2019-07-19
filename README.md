
An AXIS based 128-bit AES encrypter.

A 40 stage intra-pipelined AES-128 encrypter (designed as a hardware accelerator), with an AXI stream interface.

To operate, the 128 bit key should be appended to the beginning of the data to be encrypted, and then streamed to this IP. The encrypted text is also sent back through the AXIS interface.

Synthesizes successfully at 200MHz on the Zynq 7000 based ZedBoard (although the DMA engine may not synthesise at this clock speed).

Synthesized at 150Mhz, this IP achieves a throughput of 298.5 MB/s for an input size of 8KB. Benchmarked against kokke's tiny-aes software implementation running on the ZedBoard, this is a 757.4x speedup.

The C program that runs on the Zedboard can be found under `program`, and implements reading and writing files off the SD card interface. The software encryption mode uses kokke's tiny-aes repository. Comment `software_encrypt()` and uncomment `use-hardware()` to use hardware encryption.
