
  #(parameter
    DATA_WIDTH = 8);

   logic                  sig; // сигнал передачи/приема.
   logic [DATA_WIDTH-1:0] data; // передаваемые или принимаемые данные.
   logic                  valid; // флаг, сигнализирующий о готовности данных для передачи.
   logic                  ready; // флаг готовности устройства к передаче или приему.

   modport tx(output sig,
              input  data,
              input  valid,
              output ready);

   modport rx(input  sig,
              output data,
              output valid,
              input  ready);

endinterface
