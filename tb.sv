module testbench();

    parameter NB_MASTER       = 2;
    parameter APB_ADDR_WIDTH  = 32;
    parameter APB_DATA_WIDTH  = 32;

    logic                      PCLK;
    logic                      PRESETn;
    logic [APB_ADDR_WIDTH-1:0] PADDR;
    logic                      PSEL;
    logic                      PENABLE;
    logic                      PWRITE;
    logic [APB_DATA_WIDTH-1:0] PWDATA;
    logic                      PREADY;
    logic [APB_DATA_WIDTH-1:0] PRDATA;
    logic                      PSLAVEERR;
    logic [7:0]                PWM;
    logic [31:0]               mult_res;

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

    initial begin
        PCLK = 0;
    end

    always begin
        #5 PCLK = ~PCLK;
    end

    initial begin
        PRESETn  = 0;
        PADDR    = 0;
        PENABLE  = 0;
        PSEL     = 0;
        PWRITE   = 0;
        PWDATA   = 0;
        mult_res = 0;

        #5 PRESETn = 0;
        #5 PRESETn = 1;

        #10;
        PADDR   = 32'h0000_0000;
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 1;
        PWDATA  = 32'd5;

        #5 PENABLE = 1;

        #10;
        PADDR   = 32'h0000_0004;
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 1;
        PWDATA  = 32'd4;

        #10 PENABLE = 1;

        #10;
        PADDR   = 32'h0000_000C;
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 1;
        PWDATA  = 32'd1;

        #5 PENABLE = 1;

        #10;
        PADDR   = 32'h0000_000C;
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 1;
        PWDATA  = 32'd0;

        #5 PENABLE = 1;

        @(posedge PREADY);
        PADDR   = 32'h0000_0008;
        PSEL    = 1;
        PWRITE  = 0;
        #20;
        mult_res = PRDATA;
        $display("PRDATA: %d\tMult result: %d", PRDATA, mult_res);

        #10;
        PADDR   = 32'h0000_1000;
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 1;
        PWDATA  = mult_res;

        #5 PENABLE = 1;

        #10;
        PADDR   = 32'h0000_1004;
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 1;
        PWDATA  = mult_res / 2;

        #10 PENABLE = 1;

        #5;
        PADDR   = 32'h0000_1008;
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 1;
        PWDATA  = mult_res / 4;

        #5 PENABLE = 1;

        #10;
        PADDR   = 32'h0000_100C;
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 1;
        PWDATA  = 32'd1;

        #5 PENABLE = 1;

        #500;

        $stop;
    end
endmodule