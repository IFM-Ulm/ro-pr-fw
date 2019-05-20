`ifndef PORTARRAY_PACK_UNPACK_V
// `ifdef PACK_PORTARRAY
// $finish; // macro PACK_ARRAY already exists. refusing to redefine.
// `endif
// `ifdef UNPACK_PORTARRAY
// $finish; // macro UNPACK_ARRAY already exists. refusing to redefine.
// `endif



`define PORTARRAY_PACK_UNPACK_V 1


// `define PACK_PORTARRAY(PK_WIDTH,PK_LEN,PK_SRC,PK_DEST) generate for (pk_idx=0; pk_idx<(PK_LEN); pk_idx=pk_idx+1) begin; assign PK_DEST[((PK_WIDTH)*pk_idx+((PK_WIDTH)-1)):((PK_WIDTH)*pk_idx)] = PK_SRC[pk_idx][((PK_WIDTH)-1):0]; end; endgenerate
`define PACK_PORTARRAY(PK_WIDTH,PK_LEN,PK_SRC,PK_DEST) \
`ifndef PACK_PORTARRAY_CALLED \
`define PACK_PORTARRAY_CALLED 1 \
genvar pk_idx; generate for (pk_idx=0; pk_idx<(PK_LEN); pk_idx=pk_idx+1) begin; assign PK_DEST[((PK_WIDTH)*pk_idx+((PK_WIDTH)-1)):((PK_WIDTH)*pk_idx)] = PK_SRC[pk_idx][((PK_WIDTH)-1):0]; end; endgenerate \
`else \
generate for (pk_idx=0; pk_idx<(PK_LEN); pk_idx=pk_idx+1) begin; assign PK_DEST[((PK_WIDTH)*pk_idx+((PK_WIDTH)-1)):((PK_WIDTH)*pk_idx)] = PK_SRC[pk_idx][((PK_WIDTH)-1):0]; end; endgenerate \
`endif



// `define UNPACK_PORTARRAY(PK_WIDTH,PK_LEN,PK_DEST,PK_SRC) genvar unpk_idx; generate for (unpk_idx=0; unpk_idx<(PK_LEN); unpk_idx=unpk_idx+1) begin; assign PK_DEST[unpk_idx][((PK_WIDTH)-1):0] = PK_SRC[((PK_WIDTH)*unpk_idx+(PK_WIDTH-1)):((PK_WIDTH)*unpk_idx)]; end; endgenerate
`define UNPACK_PORTARRAY(PK_WIDTH,PK_LEN,PK_DEST,PK_SRC) \
`ifndef PACK_PORTARRAY_CALLED \
`define PACK_PORTARRAY_CALLED 1 \
genvar unpk_idx; generate for (unpk_idx=0; unpk_idx<(PK_LEN); unpk_idx=unpk_idx+1) begin; assign PK_DEST[unpk_idx][((PK_WIDTH)-1):0] = PK_SRC[((PK_WIDTH)*unpk_idx+(PK_WIDTH-1)):((PK_WIDTH)*unpk_idx)]; end; endgenerate \
`else \
generate for (unpk_idx=0; unpk_idx<(PK_LEN); unpk_idx=unpk_idx+1) begin; assign PK_DEST[unpk_idx][((PK_WIDTH)-1):0] = PK_SRC[((PK_WIDTH)*unpk_idx+(PK_WIDTH-1)):((PK_WIDTH)*unpk_idx)]; end; endgenerate \
`endif

`else

`undef PACK_PORTARRAY_CALLED

`endif





/*
module example (
    input  [63:0] pack_4_16_in,
    output [31:0] pack_16_2_out
    );

wire [3:0] in [0:15];
`UNPACK_PORTARRAY(4,16,in,pack_4_16_in)

wire [15:0] out [0:1];
`PACK_PORTARRAY(16,2,in,pack_16_2_out)


// useful code goes here

endmodule // example
*/