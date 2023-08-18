#pragma once
#include <cstdint>

namespace Flags{
	enum Flags : uint8_t{
		 L = 0b100,
		 E = 0b010,
		 G = 0b001
	};

	constexpr uint8_t all = (Flags::L | Flags::E | Flags::G);
};

enum class Opcode : uint8_t{
 NOP = 0x00,
 HLT = 0x01,

 MOV = 0x05,
 RDM = 0x06,
 WRM = 0x07,

 RDX = 0x0C,
 WRX = 0x0D,
 PSH = 0x0E,
 POP = 0x0F,
 MUL = 0x10,
 CMP = 0x11,

 TST = 0x13,
 JMP = 0x14,
 CAL = 0x15,
 RET = 0x16,

 ADD = 0x18,
 SUB = 0x19,
 NOT = 0x1A,
 AND = 0x1B,
 ORR = 0x1C,
 XOR = 0x1D,
 SLL = 0x1E,
 SLR = 0x1F
};

constexpr int val(Opcode const op)
{
	return static_cast<int>(op);
}

