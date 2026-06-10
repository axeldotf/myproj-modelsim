module testbench_v3();

    // Parameter Definitions
    parameter NB_MASTER       = 2;                 // Number of APB masters
    parameter APB_ADDR_WIDTH  = 32;                // Address bus width
    parameter APB_DATA_WIDTH  = 32;                // Data bus width

    // Signal Declarations
    logic                      PCLK;               // APB clock
    logic                      PRESETn;            // Active-low reset

    logic [APB_ADDR_WIDTH-1:0] PADDR;              // Address bus
    logic                      PSEL;               // APB select signal
    logic                      PENABLE;            // APB enable signal
    logic                      PWRITE;             // Write enable

    logic [APB_DATA_WIDTH-1:0] PWDATA;             // Write data bus
    
    logic [APB_DATA_WIDTH-1:0] PRDATA;             // Read data bus

    logic                      PREADY;             // Ready signal
    logic                      PSLAVEERR;          // Slave error signal

    logic [7:0]                PWM;                // PWM output
    logic [31:0]               mult_res;           // Result of multiplication

    // DUT (Device Under Test) Instantiation
    APB_BUS_SERMUL_PWM #(
        .NB_MASTER(NB_MASTER),
        .APB_ADDR_WIDTH(APB_ADDR_WIDTH),
        .APB_DATA_WIDTH(APB_DATA_WIDTH)
    ) bus_mult_pwm (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PADDR(PADDR),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PREADY(PREADY),
        .PRDATA(PRDATA),
        .PSLAVEERR(PSLAVEERR),
        .PWM(PWM)
    );

    // Clock Generation
    initial begin
        PCLK = 0; 		// clk initialization
    end

    always begin
        #5 PCLK = ~PCLK; 	// alternate clk
    end

    // Simulation Procedure
    initial begin
        // Initialization
        PRESETn  = 0;
        PADDR    = 0;
        PENABLE  = 0;
        PSEL     = 0;
        PWRITE   = 0;
        PWDATA   = 0;
        mult_res = 0;

        // Reset Sequence
        #50 PRESETn = 0;
        #50 PRESETn = 1;

        // -----------------
        // SERMUL (step 1-4)
        // -----------------

        // 1) Write 1st operand A = 5
        #100;
        PADDR   = 32'h0000_0000;   // Address for A
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 1;
        PWDATA  = 32'd5;           // Write value 5

        #50 PENABLE = 1;

        // 2) Write 2nd operand B = 4
        #100;
        PADDR   = 32'h0000_0004;   // Address for B
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 1;
        PWDATA  = 32'd4;           // Write value 4

        #100 PENABLE = 1;

        // 3) Start multiplication
        #100;
        PADDR   = 32'h0000_000C;   // Address for START reg.
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 1;
        PWDATA  = 32'd1;           // Start multiplication

        #50 PENABLE = 1;

        // 3.1) Clear START
        #100;
        PADDR   = 32'h0000_000C;   // Address for START reg.
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 1;
        PWDATA  = 32'd0;	   // Clear START

        #50 PENABLE = 1;

        // 3.2) Wait for mult. Result
        @(posedge PREADY);
        PADDR   = 32'h0000_0008;   // Address for RESULT reg.
        PSEL    = 1;
        PWRITE  = 0;

	// 4) Read result of multiplication
        #200;
        mult_res = PRDATA;         // Read result
        $display("PRDATA: %d\tMult result: %d", PRDATA, mult_res);

        // --------------
        // PWM (step 5-8)
        // --------------

        // 5) Configure PWM Period = mult_res
        #100;
        PADDR   = 32'h0000_1000;   // Address for PERIOD reg.
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 1;
        PWDATA  = mult_res;        // Period = mult_res

        #50 PENABLE = 1;

        // 6) Configure PWM Pulse Width = mult_res / 2
        #100;
        PADDR   = 32'h0000_1004;   // Address for PULSE reg.
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 1;
        PWDATA  = mult_res / 2;    // Pulse Width = mult_res / 2

        #100 PENABLE = 1;

        // 7) Configure PWM Size = mult_res / 4
        #50;
        PADDR   = 32'h0000_1008;   // Address for SIZE reg.
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 1;
        PWDATA  = mult_res / 4;    // PWM Size = mult_res / 4

        #50 PENABLE = 1;

        // 8) Start PWM
        #100;
        PADDR   = 32'h0000_100C;   // Address for Enable Signal
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 1;
        PWDATA  = 32'd1;           // Enable PWM

        #50 PENABLE = 1;

        // Run PWM for some time
        #2000;

        $stop;

    end

endmodule

