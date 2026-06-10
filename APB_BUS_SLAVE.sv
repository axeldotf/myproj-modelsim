// SERMUL and PWM FSMs functioning

// 1st Module: Serial Multiplier (SERMUL)
// Reads operands from Registers and performs a serial multiply operation

module APB_BUS_SERMUL #(
    parameter logic ID,                           // ID for address matching
    parameter int unsigned APB_ADDR_WIDTH = 32,   // Address bus width
    parameter int unsigned APB_DATA_WIDTH = 32    // Data bus width
)(
    input  logic                          PCLK,     // APB clock
    input  logic                          PRESETn,  // Active-low reset
    input  logic [APB_ADDR_WIDTH-1:0]     PADDR,    // Address bus
    input  logic                          PSEL,     // Select signal
    input  logic                          PENABLE,  // Enable signal
    input  logic                          PWRITE,   // Write enable
    input  logic [APB_DATA_WIDTH-1:0]     PWDATA,   // Write data
    output logic                          PREADY,   // Ready signal
    output logic [APB_DATA_WIDTH-1:0]     PRDATA,   // Read data
    output logic                          PSLAVEERR // Slave error signal
);

    // Internal registers and signals
    reg [31:0] reg_a, new_reg_a;   // Operand A
    reg [15:0] reg_b, new_reg_b;   // Operand B
    reg [31:0] result, new_result; // Result register
    logic start_mul;               // Start multiplication flag
    logic load;                    // Load flag
    reg [3:0] count;               // 4-bit counter

    // State definitions for FSM
    typedef enum logic [1:0] { IDLE, CALC, DONE } SERMUL_state;
    SERMUL_state cs, ns;

    // Register update logic (sequential)
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (~PRESETn) begin
            new_reg_a  <= 0;
            new_reg_b  <= 0;
            start_mul  <= 0;
            PRDATA     <= 0;
        end else if (PWRITE & PSEL & PENABLE & load) begin
            case (PADDR[3:0])
                4'h0: new_reg_a <= {16'd0, PWDATA[15:0]}; // Operand A
                4'h4: new_reg_b <= PWDATA[15:0];          // Operand B
                4'hC: start_mul <= PWDATA[0];             // Start flag
            endcase
        end else begin
            new_reg_a  <= reg_a;
            new_reg_b  <= reg_b;
            start_mul  <= start_mul;
            PRDATA     <= (~PWRITE & PSEL & PENABLE & PREADY & (PADDR[3:0] == 4'h8)) ? result : 0;
        end
    end

    // Counter logic for calculation state
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (~PRESETn || cs != CALC)
            count <= 0;
        else if (cs == CALC)
            count <= count + 1;
    end

    // Error signal logic
    always_comb begin
        PSLAVEERR = 0;
        if (ID == PADDR[13:12])
            PSLAVEERR = 0; // Correct ID
        else if (PADDR[13:12] != 2'bxx)
            PSLAVEERR = 1; // Incorrect ID
    end

    // FSM Logic
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (~PRESETn) begin
            ns         <= IDLE;
            new_result <= 0;
            PREADY     <= 0;
            load       <= 1;
        end else begin
            case (cs)
                IDLE: begin
                    if (start_mul) begin
                        ns     <= CALC;
                        load   <= 1;
                        PREADY <= 0;
                    end
                end
                CALC: begin
                    load       <= 0;
                    new_reg_a  <= reg_a << 1; // Shift left A
                    new_reg_b  <= reg_b >> 1; // Shift right B
                    new_result <= reg_b[0] ? (result + reg_a) : result; // Add if LSB is 1
                    PREADY     <= 0;

                    // Transition to DONE if calculation is complete
                    if (count == 4'd15 || reg_a == 32'd0 || reg_b == 16'd0)
                        ns <= DONE;
                end
                DONE: begin
                    PREADY <= 1;
                    ns     <= IDLE;
                end
            endcase
        end
    end

    // Output assignments
    assign cs      = ns;
    assign reg_a   = new_reg_a;
    assign reg_b   = new_reg_b;
    assign result  = new_result;

endmodule


// 2nd module: PWM (Pulse Width Modulation) Generator
// PWM duty cycle (pulse) and period can be configured via APB interface

module APB_BUS_PWM #(
    parameter logic ID,                           // ID for address matching
    parameter int unsigned APB_ADDR_WIDTH = 32,   // Address bus width
    parameter int unsigned APB_DATA_WIDTH = 32    // Data bus width
)(
    input  logic                          PCLK,     // APB clock
    input  logic                          PRESETn,  // Active-low reset
    input  logic [APB_ADDR_WIDTH-1:0]     PADDR,    // Address bus
    input  logic                          PSEL,     // Select signal
    input  logic                          PENABLE,  // Enable signal
    input  logic                          PWRITE,   // Write enable
    input  logic [APB_DATA_WIDTH-1:0]     PWDATA,   // Write data
    output logic                          PREADY,   // Ready signal
    output logic [APB_DATA_WIDTH-1:0]     PRDATA,   // Read data
    output logic                          PSLAVEERR,// Slave error signal
    output logic [7:0]                    PWM       // PWM output
);

    // Internal registers and signals
    reg [31:0] period;    // PWM period
    reg [31:0] pulse;     // PWM pulse width
    reg [31:0] size;      // PWM duty cycle size
    reg [31:0] enable;    // Enable flag
    reg [31:0] count;     // Counter
    logic restart;        // Restart flag

    // State definitions for FSM
    typedef enum logic [1:0] { IDLE, HIGH, LOW } PWM_state;
    PWM_state cs, ns;

    // APB Interface Read/Write Logic
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (~PRESETn) begin
            period  <= 0;
            pulse   <= 0;
            size    <= 0;
            enable  <= 0;
            PRDATA  <= 0;
        end else if (PENABLE & PWRITE & PSEL) begin
            case (PADDR[3:2])
                2'b00: period <= PWDATA;          // Write period
                2'b01: pulse  <= PWDATA;          // Write pulse width
                2'b10: size   <= PWDATA[7:0];     // Write duty cycle size
                2'b11: enable <= PWDATA[0];       // Write enable flag
            endcase
        end else if (~PWRITE & PSEL & PENABLE & PREADY) begin
            case (PADDR[3:0])
                4'h0: PRDATA <= period;           // Read period
                4'h4: PRDATA <= pulse;            // Read pulse width
                4'h8: PRDATA <= size;             // Read duty cycle size
                4'hC: PRDATA <= enable;           // Read enable flag
                default: PRDATA <= 0;
            endcase
        end else
            PRDATA <= 0;
    end

    // Counter Logic
    always_ff @(posedge PCLK or negedge PRESETn or negedge restart) begin
        if (!PRESETn || restart)
            count <= 0;
        else
            count <= count + 1;
    end

    // Error Signal Logic
    always_comb begin
        PSLAVEERR = 0;
        if (PADDR[13:12] != 2'bxx)
            PSLAVEERR = 1; // Invalid address
    end

    // FSM Logic
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (~PRESETn) begin
            PWM     <= 0;
            ns      <= IDLE;
            restart <= 0;
        end else begin
            case (cs)
                IDLE: begin
                    if (enable) begin
                        ns      <= HIGH;
                        restart <= 1;
                    end
                end
                HIGH: begin
                    restart <= 0;
                    PWM     <= size; // Set PWM high
                    if (!enable)
                        ns <= IDLE;
                    else if (count == (pulse - 1))
                        ns <= LOW;
                end
                LOW: begin
                    PWM <= 0; // Set PWM low
                    if (!enable)
                        ns <= IDLE;
                    else if (count == (period - 1)) begin
                        ns      <= HIGH;
                        restart <= 1;
                    end
                end
            endcase
        end
    end

    // Output Assignments
    assign cs     = ns;
    assign PREADY = PENABLE;

endmodule
