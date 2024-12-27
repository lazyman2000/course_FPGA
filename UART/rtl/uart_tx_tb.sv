timeunit 1ns;
timeprecision 1ns;

module uart_tx_tb;

  // ���������
  parameter DATA_WIDTH = 8;
  parameter BAUD_RATE  = 115200;
  parameter CLK_FREQ   = 100_000_000;

  // ��������� ���������
  localparam PULSE_WIDTH = CLK_FREQ / BAUD_RATE;

  // ������� ��� �����
  logic clk;
  logic rstn;
  logic [DATA_WIDTH-1:0] data_from_sensor;
  logic valid_from_sensor;
  logic ready_to_sensor;
  logic tx_sig;

  // ����������� ������
  uart_tx #(DATA_WIDTH, BAUD_RATE, CLK_FREQ) uut (
    .clk(clk),
    .rstn(rstn),
    .data_from_sensor(data_from_sensor),
    .valid_from_sensor(valid_from_sensor),
    .ready_to_sensor(ready_to_sensor),
    .tx_sig(tx_sig)
  );

  // ��������� ��������� �������
  initial clk = 0;
  always #(5) clk = ~clk; // ������ 10 �� -> 100 ���

  // ������������� ��������
  initial begin
    rstn = 0;
    data_from_sensor = 0;
    valid_from_sensor = 0;

    // �����
    #(PULSE_WIDTH * 10);
    rstn = 1;
    // �������� ��������

    // �������� 1: ������ �� ���������� ������
    $display("Scenario 1: Sensor is not sending data");
    #(PULSE_WIDTH * 50);

    // �������� 2: ������ ���������� ������ ����� ����� �� ���������
    $display("Scenario 2: Sensor sends data immediately");
    data_from_sensor = 8'ha5;
    valid_from_sensor = 1;
    #(PULSE_WIDTH * 20);
    valid_from_sensor = 0; // ������ ����������
    #(PULSE_WIDTH * 70);

    // �������� 3: ������ ����� ��������� ������, �� ������ �� �����
    /*$display("Scenario 3: Sensor waits for readiness");
    data_from_sensor = 8'hb3;
    valid_from_sensor = 1;
    #(PULSE_WIDTH * 10);
    valid_from_sensor = 0; // ������ �� ����� ������� ����� ������
    #(PULSE_WIDTH * 70);
    valid_from_sensor = 1; // ������� ��������� ������ �����
    #(PULSE_WIDTH * 140);*/
    
    // �������� 4: ������ ������� ������� ��������� ���� ������
    $display("Scenario 4: Sensor prepares multiple bytes in advance");
    data_from_sensor = 8'hc4;
    valid_from_sensor = 1;
    #(PULSE_WIDTH * 20);
    valid_from_sensor = 0; // ��������� ������ ����

    #(PULSE_WIDTH * 20);
    data_from_sensor = 8'hb5;
    valid_from_sensor = 1;
    #(PULSE_WIDTH * 20);
    valid_from_sensor = 0; // ��������� ������ ����

    #(PULSE_WIDTH * 50);
    data_from_sensor = 8'h9a;
    valid_from_sensor = 1;
    #(PULSE_WIDTH * 30);
    valid_from_sensor = 0; // ��������� ������ ����
    
    // ���������� ���������
    #(PULSE_WIDTH * 50);
    $finish;
  end

  // ���������� ��������
  initial begin
    $monitor($time, 
             " valid_from_sensor=%b, ready_to_sensor=%b, data_from_sensor=%h, tx_sig=%b", 
             valid_from_sensor, ready_to_sensor, data_from_sensor, tx_sig);
  end

endmodule
