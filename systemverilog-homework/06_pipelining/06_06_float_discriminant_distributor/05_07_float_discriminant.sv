//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module float_discriminant (
    input                     clk,
    input                     rst,

    input                     arg_vld,
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,
    input        [FLEN - 1:0] c,

    output logic              res_vld,
    output logic [FLEN - 1:0] res,
    output logic              res_negative,
    output logic              err,

    output logic              busy
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs their discriminant.
    // The resulting value res should be calculated as a discriminant of the quadratic polynomial.
    // That is, res = b^2 - 4ac == b*b - 4*a*c
    //
    // Note:
    // If any argument is not a valid number, that is NaN or Inf, the "err" flag should be set.
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.



    real ra, rb, rc, rd;

    always @(posedge clk) begin
        if (rst) begin
            res_vld <= 1'b0;
            res <= 0;
            res_negative <= 1'b0;
            err <= 1'b0;
            busy <= 1'b0;
        end else begin
            res_vld <= 1'b0;
            busy <= 1'b0;

            if (arg_vld) begin
                busy <= 1'b1;

                // Assign to real variables
                ra = $bitstoreal(a);
                rb = $bitstoreal(b);
                rc = $bitstoreal(c);
                rd = rb * rb - 4.0 * ra * rc;

                res <= $realtobits(rd);

                // Error: exponent all ones
                err <= res[FLEN-2 -: NE] == {NE{1'b1}};

                // Negative: sign=1, non-zero, not error
                res_negative <= res[FLEN-1] && (res != 0) && ~err;

                res_vld <= 1'b1;
            end
        end
    end
endmodule
