`timescale 1ns/1ps

module CPU(dout,led,digi,switch,din,clk,reset);
	output	dout;
	output	[7:0]led;
	output	[11:0]digi;
	input	[7:0]switch;
	input	din;
	input	clk;
	input	reset;

	wire	[31:0]ConBA;
	wire	[31:0]DatabusA;
	wire	[25:0]JT;
	parameter	ILLOP = 32'h80000004;
	parameter	XADR = 32'h80000008;
	wire	[31:0]ALUOut;
	wire	[2:0]PCSrc;
	wire	[31:0]PC;
	wire	[31:0]PCplus4;
	assign	PCplus4 = PC + 4;

	ProgramCounter	programconuter(
							//output
							.PC(PC),
							//input
							.clk(clk),
							.reset(reset), 
							.PCplus4(PCplus4),
							.ConBA(ConBA), 
							.JT(JT), 
							.DatabusA(DatabusA), 
							.ILLOP(ILLOP), 
							.XADR(XADR), 
							.ALUOut(ALUOut[0]), 
							.PCSrc(PCSrc)
	);

	wire	[31:0]Instruction;

	/*InstructionMemorg instructionMemorg(
								//output
								.Instruction(Instruction), 
								//input
								.PC(PC)
	);*/
	
	ROM rom(
	     .addr(PC),
	     .data(Instruction)
	     );

	assign	JT[25:0] = Instruction[25:0];
	wire	[15:0]Imm16;
	assign	Imm16[15:0] = Instruction[15:0];
	wire	[4:0]Shamt;
	assign	Shamt[4:0] = Instruction[10:6];
	wire	[4:0]Rd;
	assign	Rd[4:0] = Instruction[15:11];
	wire	[4:0]Rt;
	assign	Rt[4:0] = Instruction[20:16];
	wire	[4:0]Rs;
	assign	Rs[4:0] = Instruction[25:21];

	wire	[1:0]RegDst;
	wire	RegWr;
	wire	ALUSrc1;
	wire	ALUSrc2;
	wire	[5:0]ALUFun;
	wire	Sign;
	wire	MemWr;
	wire	MemRd;
	wire	[1:0]MemToReg;
	wire	EXTOp;
	wire	LUOp;
	wire	IRQ;

	Control control(
			//output
			.PCSrc(PCSrc),
			.RegDst(RegDst),
			.RegWr(RegWr),
			.ALUSrc1(ALUSrc1),
			.ALUSrc2(ALUSrc2),
			.ALUFun(ALUFun),
			.Sign(Sign),
			.MemWr(MemWr),
			.MemRd(MemRd),
			.MemToReg(MemToReg),
			.EXTOp(EXTOp),
			.LUOp(LUOp),
			//input
			.Instruction(Instruction),
			.IRQ(IRQ), 
			.supervisor(PC[31])
	);

	parameter	[4:0]Xp = 5'b11010;
	parameter	[4:0]Ra = 5'b11111;
	wire	[31:0]DatabusB;
	wire	[31:0]writedata;
	wire	[4:0]addrb;
	assign	addrb = (Instruction[31:26] == 6'h01) ? 0 : Rt;
	wire	[4:0]addrc;
	assign	addrc = (RegDst == 2'b00) ? Rd : 
					(RegDst == 2'b01) ? Rt : 
					(RegDst == 2'b10) ? Ra : 
					Xp;

	RegFile regfile(
			.reset(reset),
			.clk(clk),
			.addr1(Rs),
			.data1(DatabusA),
			.addr2(addrb),
			.data2(DatabusB),
			.wr(RegWr),
			.addr3(addrc),
			.data3(writedata)
	);

	wire	[31:0]EXTout;

	EXT ext(
		//output
		.EXTout(EXTout),
		.ConBA(ConBA),
		//input
		.Imm16(Imm16),
		.PCplus4(PCplus4),
		.EXTOp(EXTOp),
		.LUOp(LUOp)
	);

	wire	[31:0]ALUin1;
	wire	[31:0]ALUin2;
	assign	ALUin1 = (ALUSrc1 == 0) ? DatabusA : {27'b0,Shamt[4:0]};
	assign	ALUin2 = (ALUSrc2 == 0) ? DatabusB : EXTout;

	alu alu1(
		.Z(ALUOut),
		.A(ALUin1), 
		.B(ALUin2), 
		.ALUFun(ALUFun), 
		.Sign(Sign)
	);

	wire	[31:0]readdata;
	wire	[31:0]readdata1;
	wire	[31:0]readdata2;

	DataMem	datamem(
			.reset(reset),
			.clk(clk),
			.rd(MemRd),
			.wr(MemWr),
			.addr(ALUOut),
			.wdata(DatabusB),
			.rdata(readdata1)
	);

	Peripheral peripheral(
			.reset(reset),
			.clk(clk),
			.rd(MemRd),
			.wr(MemWr),
			.addr(ALUOut),
			.wdata(DatabusB),
			.rdata(readdata2),
			.led(led),
			.switch(switch),
			.digi(digi),
			.irqout(IRQ), 
			.din(din), 
			.dout(dout)
	);

	assign	readdata = (ALUOut[31:28] == 4'b0100) ? readdata2 : readdata1;

	assign writedata = (MemToReg == 2'b00) ? ALUOut : 
						(MemToReg == 2'b01) ? readdata : 
						(MemToReg == 2'b10) ? PCplus4 : 
						PC;

endmodule






