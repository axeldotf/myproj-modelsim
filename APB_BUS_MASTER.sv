`define SER_MUL_START_ADDR  32'h00000000  
`define SER_MUL_END_ADDR    32'h00000FFF
`define PWM_START_ADDR      32'h00001000
`define PWM_END_ADDR        32'h00001FFF

// Handles APB Master functionality, connecting it to multiple APB slaves

module APB_BUS_MASTER #
(
    parameter NB_MASTER      = 2,    // Number of APB masters
    parameter APB_ADDR_WIDTH = 32,   // Width of APB address bus
    parameter APB_DATA_WIDTH = 32    // Width of APB data bus
)
(
    input logic                               M_PCLK,          // Master APB clock
    input logic                               M_PRESETn,       // Master APB reset (active low)
    input logic [APB_ADDR_WIDTH - 1:0]        M_PADDR,         // Master APB address
    input logic                               M_PSEL,          // Master APB select
    input logic                               M_PENABLE,       // Master APB enable
    input logic                               M_PWRITE,        // Master APB write enable
    input logic [APB_DATA_WIDTH - 1:0]        M_PWDATA,        // Master APB write data

    output logic                              M_PREADY,        // Master APB ready
    output logic [APB_DATA_WIDTH - 1:0]       M_PRDATA,        // Master APB read data
    output logic                              M_PSLAVEERR,     // Master APB slave error

    output logic [NB_MASTER-1:0]              S_PCLK,          // Slave APB clocks
    output logic [NB_MASTER-1:0]              S_PRESETn,       // Slave APB resets
    output logic [NB_MASTER-1:0][APB_ADDR_WIDTH-1:0] S_PADDR,  // Slave APB addresses
    output logic [NB_MASTER-1:0]              S_PSEL,          // Slave APB selects
    output logic [NB_MASTER-1:0]              S_PENABLE,       // Slave APB enables
    output logic [NB_MASTER-1:0]              S_PWRITE,        // Slave APB write enables
    output logic [NB_MASTER-1:0][APB_DATA_WIDTH-1:0] S_PWDATA, // Slave APB write data

    input logic [NB_MASTER-1:0]               S_PREADY,        // Slave APB ready signals
    input logic [NB_MASTER-1:0][APB_DATA_WIDTH-1:0] S_PRDATA,  // Slave APB read data
    // input wire [NB_MASTER-1:0][APB_DATA_WIDTH-1:0] S_PRDATA,   // Slave APB read data
    input logic [NB_MASTER-1:0]               S_PSLAVEERR      // Slave APB error signals
);

always_comb begin

    // Initialize APB signals for all slaves
    for (int i=0; i < NB_MASTER; i++) begin
        S_PCLK[i]    = M_PCLK;
        S_PRESETn[i] = M_PRESETn;
        S_PADDR[i]   = 0;
        S_PENABLE[i] = 0;
        S_PWRITE[i]  = 0;
        S_PWDATA[i]  = 0;

        M_PREADY    = 0;
        M_PRDATA    = 0;
        M_PSLAVEERR = 0;
    end
    
    S_PSEL = 1'b0;	// reset for S_PSEL, the default state has no slave selected

    // Address decoding for slave selection
    case(M_PADDR[12])
        1'b0: S_PSEL[0] = 1;	// slave 0 (SERMUL)
        1'b1: S_PSEL[1] = 1;	// slave 1 (PWM)
    endcase

    // Connect selected slave signals to the master
    for (int i = 0; i < NB_MASTER; i++) begin
        if (S_PSEL[i]) begin
            S_PRESETn[i] = M_PRESETn;
            S_PADDR[i]   = M_PADDR;
            S_PENABLE[i] = M_PENABLE;
            S_PWRITE[i]  = M_PWRITE;
            S_PWDATA[i]  = M_PWDATA;

            // Responses from slave
            M_PREADY    = S_PREADY[i];
            M_PRDATA    = S_PRDATA[i];
            M_PSLAVEERR = S_PSLAVEERR[i];
        end
    end
end

endmodule

