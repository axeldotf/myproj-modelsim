// Connects SERMUL and PWM modules to the APB bus
// 3rd diagram

module APB_BUS_SERMUL_PWM #
(
    parameter NB_MASTER       = 2,      // Number of APB masters
    parameter APB_ADDR_WIDTH  = 32,     // Width of APB address bus
    parameter APB_DATA_WIDTH  = 32      // Width of APB data bus
) (
    input logic                       PCLK,        // APB clock
    input logic                       PRESETn,     // APB reset (active low)

    input logic [APB_ADDR_WIDTH-1:0]  PADDR,       // APB address
    input logic                       PSEL,        // APB select
    input logic                       PENABLE,     // APB enable
    input logic                       PWRITE,      // APB write enable
    output logic                      PREADY,      // APB ready
    output logic                      PSLAVEERR,   // APB slave error

    input logic [APB_DATA_WIDTH-1:0]  PWDATA,      // APB write data

    output logic [APB_DATA_WIDTH-1:0] PRDATA,      // APB read data
    
    output logic [7:0]                PWM          // PWM output
);

    // Internal signals for APB master interfaces
    logic [NB_MASTER-1:0]                       S_PCLK;
    logic [NB_MASTER-1:0]                       S_PRESETn;
    logic [NB_MASTER-1:0][APB_ADDR_WIDTH-1:0]   S_PADDR;
    logic [NB_MASTER-1:0]                       S_PSEL;
    logic [NB_MASTER-1:0]                       S_PENABLE;
    logic [NB_MASTER-1:0]                       S_PWRITE;
    logic [NB_MASTER-1:0][APB_DATA_WIDTH-1:0]   S_PWDATA;

    logic [NB_MASTER-1:0]                       S_PREADY;
    logic [NB_MASTER-1:0][APB_DATA_WIDTH-1:0]   S_PRDATA;
    logic [NB_MASTER-1:0]                       S_PSLAVEERR;

    // APB Bus Master
    APB_BUS_MASTER master (
        .M_PCLK      (PCLK), 
        .M_PRESETn   (PRESETn), 
        .M_PADDR     (PADDR), 
        .M_PSEL      (PSEL), 
        .M_PENABLE   (PENABLE), 
        .M_PWRITE    (PWRITE), 
        .M_PWDATA    (PWDATA),

        .M_PREADY    (PREADY),
        .M_PRDATA    (PRDATA), 
        .M_PSLAVEERR (PSLAVEERR), 

        .S_PCLK      (S_PCLK), 
        .S_PRESETn   (S_PRESETn), 
        .S_PADDR     (S_PADDR), 
        .S_PSEL      (S_PSEL), 
        .S_PENABLE   (S_PENABLE),
        .S_PWRITE    (S_PWRITE), 
        .S_PWDATA    (S_PWDATA),
        
        .S_PREADY    (S_PREADY), 
        .S_PRDATA    (S_PRDATA), 
        .S_PSLAVEERR (S_PSLAVEERR)
    );

    // APB Bus SERMUL (slave 0)
    APB_BUS_SERMUL #(0, APB_ADDR_WIDTH, APB_DATA_WIDTH) slave_mult (
        .PCLK       (PCLK), 
        .PRESETn    (S_PRESETn[0]), 
        .PADDR      (S_PADDR[0]), 
        .PSEL       (S_PSEL[0]), 
        .PENABLE    (S_PENABLE[0]),
        
        .PWRITE     (S_PWRITE[0]), 
        .PWDATA     (S_PWDATA[0]), 
        .PREADY     (S_PREADY[0]), 
        .PRDATA     (S_PRDATA[0]), 
        .PSLAVEERR  (S_PSLAVEERR[0])
    );

    // APB Bus PWM (slave 1)
    APB_BUS_PWM #(1, APB_ADDR_WIDTH, APB_DATA_WIDTH) slave_pwm (
        .PCLK       (PCLK), 
        .PRESETn    (S_PRESETn[1]), 
        .PADDR      (S_PADDR[1]), 
        .PSEL       (S_PSEL[1]), 
        .PENABLE    (S_PENABLE[1]),
        .PWRITE     (S_PWRITE[1]), 
        .PWDATA     (S_PWDATA[1]), 

        .PREADY     (S_PREADY[1]), 
        .PRDATA     (S_PRDATA[1]), 
        .PSLAVEERR  (S_PSLAVEERR[1]), 

        .PWM        (PWM)
    );

endmodule

