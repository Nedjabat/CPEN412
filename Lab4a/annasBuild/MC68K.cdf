/* Quartus Prime Version 18.1.0 Build 625 09/12/2018 SJ Lite Edition */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Ign)
		Device PartName(SOCVHPS) MfrSpec(OpMask(0));
	P ActionCode(Cfg)
		Device PartName(5CSEMA5F31) Path("C:/M68K/") File("MC68K.sof") MfrSpec(OpMask(1) SEC_Device(EPCS128) Child_OpMask(1 0));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
