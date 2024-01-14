`ifndef alu
`define alu
`include "Mydefine.v"
        module ALU(
                input wire clk,
                input wire rst,
                input wire rdy,
                input wire rollback,


                //from RS

                input wire alu_en,
                input wire [`OP_WID]opcode,
                input wire [`FUNCT3_WID]funct3,
                input wire funct7,
                input wire [31:0]val1,
                input wire [31:0]val2,
                input wire [31:0]imm,//立即数
                input wire [31:0]pc,//指令地址
                input wire [`ROB_POS_WID]rob_pos,//在ROB所属位置

                //发送结果

                output reg result,
                output reg [`ROB_POS_WID] result_rob_pos,
                output reg [31:0] result_val,
                output reg result_jump,
                output reg[31:0]result_pc

            );
            // `define OPCODE_L 7'b0000011
            //         //load
            // `define OPCODE_S 7'b0100011
            //         //store
            // `define OPCODE_ARITHI 7'b0010011
            //         //算术立即数
            // `define OPCODE_ARITH 7'b0110011
            //         //算术
            // `define OPCODE_BRANCH 7'b1100011
            //         //分支
            // `define OPCODE_BR 7'b1100011

            // `define OPCODE_JALR 7'b1100111
            //         //JALR
            // `define OPCODE_JAL 7'b1101111
            //         //JAL
            // `define OPCODE_LUI 7'b0110111
            //         //LUI 将立即数加载到上半字
            // `define OPCODE_AUIPC 7'b0010111
            //         //AUIPC 将立即数加到程序计数器
            // `define FUNCT3_ADD  3'h0
            // `define FUNCT3_SUB  3'h0
            // `define FUNCT3_XOR  3'h4
            // `define FUNCT3_OR   3'h6
            // `define FUNCT3_AND  3'h7
            // `define FUNCT3_SLL  3'h1
            // `define FUNCT3_SRL  3'h5
            // `define FUNCT3_SRA  3'h5
            // `define FUNCT3_SLT  3'h2
            // `define FUNCT3_SLTU 3'h3

            // `define FUNCT7_ADD 1'b0
            // `define FUNCT7_SUB 1'b1
            // `define FUNCT7_SRL 1'b0
            // `define FUNCT7_SRA 1'b1

            wire [31:0]arith_op1=val1;
            wire [31:0]arith_op2=(opcode==7'b0110011)?val2:imm;//判断是否是计算
            reg [31:0] arith_res;
            always @(*) begin
                case(funct3)
                    3'b000: begin//add
                        if(funct7==0) begin
                            arith_res=arith_op1+arith_op2;
                        end
                        else begin
                            arith_res=arith_op1-arith_op2;
                        end
                        // arith_res=arith_op1+arith_op2;
                    end
                    3'b001: begin//sll
                        arith_res=arith_op1<<arith_op2;
                    end
                    3'b010: begin//slt
                        arith_res = ($signed(arith_op1) < $signed(arith_op2));
                    end
                    3'b011: begin//sltu
                        arith_res=(arith_op1<arith_op2)?1:0;
                    end
                    3'b100: begin//xor
                        arith_res=arith_op1^arith_op2;
                    end
                    3'b101: begin//srl or sra
                        if(funct7==0) begin  //逻辑右移
                            arith_res=arith_op1>>arith_op2[5:0];
                        end
                        else begin
                            arith_res=arith_op1>>>arith_op2[5:0];//算术右移
                        end
                        // arith_res=arith_op1>>arith_op2[4:0];
                    end
                    3'b110: begin//or
                        arith_res=arith_op1|arith_op2;
                    end
                    3'b111: begin//and
                        arith_res=arith_op1&arith_op2;
                    end
                    default: begin
                        arith_res=0;
                    end
                endcase
                //     case (funct3)
                //   `FUNCT3_ADD:  // ADD or SUB
                //   if (opcode == `OPCODE_ARITH && funct7)   arith_res = arith_op1 - arith_op2;
                //   else          arith_res = arith_op1 + arith_op2;
                //   `FUNCT3_XOR:  arith_res = arith_op1 ^ arith_op2;
                //   `FUNCT3_OR:   arith_res = arith_op1 | arith_op2;
                //   `FUNCT3_AND:  arith_res = arith_op1 & arith_op2;
                //   `FUNCT3_SLL:  arith_res = arith_op1 << arith_op2;
                //   `FUNCT3_SRL:  // SRL or SRA
                //   if (funct7)   arith_res = $signed(arith_op1) >> arith_op2[5:0];
                //   else          arith_res = arith_op1 >> arith_op2[5:0];
                //   `FUNCT3_SLT:  arith_res = ($signed(arith_op1) < $signed(arith_op2));
                //   `FUNCT3_SLTU: arith_res = (arith_op1 < arith_op2);
                // endcase
            end


            reg jump;
            always @(*) begin
                case (funct3)
                    `FUNCT3_BEQ: begin
                        jump = (val1 == val2);
                    end
                    `FUNCT3_BNE: begin
                        jump = (val1 != val2);
                    end
                    `FUNCT3_BLT: begin
                        jump = ($signed(val1) < $signed(val2));
                    end
                    `FUNCT3_BGE: begin
                        jump = ($signed(val1) >= $signed(val2));
                    end
                    `FUNCT3_BLTU: begin
                        jump = (val1 < val2);
                    end
                    `FUNCT3_BGEU: begin
                        jump = (val1 >= val2);
                    end
                    default:
                        jump = 0;
                endcase
            end

            always @(posedge clk) begin
                if(rst||rollback) begin
                    result<=0;
                    result_rob_pos<=0;
                    result_val<=0;
                    result_jump <= 0;
                    result_pc <= 0;
                end
                else if(rdy==0) begin

                end
                else if  begin
                    result<=0;
                    if(alu_en) begin
                        result <= 1;
                            result_rob_pos<=rob_pos;
                            result_jump <= 0;
                            case(opcode)
                                //ARITH  ARITHI:
                                7'b0110011: begin//计算
                                    result_val<=arith_res;
                                end
                                7'b0010011: begin//立即数
                                    result_val<=arith_res;
                                end


                                7'b1101111: begin//jal
                                    result_jump <= 1;
                                    result_val <= pc + 4;
                                    result_pc  <= pc + imm;
                                end
                                7'b1100111: begin//jalr
                                    result_jump <= 1;
                                    result_val <= pc + 4;
                                    result_pc  <= val1 + imm;
                                end
                                7'b1100011: begin
                                    //branch
                                    if (jump) begin
                                        result_jump <= 1;
                                        result_pc   <= pc + imm;
                                    end
                                    else begin
                                        result_pc   <= pc + 4;
                                    end
                                end
                                7'b0110111: begin//lui
                                    result_val<=imm;
                                end
                                7'b0010111: begin//auipc
                                    result_val<=pc+imm;
                                end
                                // 7'b0000011:begin//load
                                //     result_val<=arith_res;
                                // end
                                default: begin
                                    result_val=0;
                                end
                            endcase
                        end
                end
            end

        endmodule
`endif //ALU
