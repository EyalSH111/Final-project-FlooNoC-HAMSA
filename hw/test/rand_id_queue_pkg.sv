package rand_id_queue_pkg;
  class rand_id_queue #(parameter type data_t = logic, parameter int unsigned ID_WIDTH = 1);
    typedef data_t queue_t[$];
    queue_t queues [2**ID_WIDTH];
    function void push(logic [ID_WIDTH-1:0] id, data_t val); queues[id].push_back(val); endfunction
    function data_t pop(logic [ID_WIDTH-1:0] id); return queues[id].pop_front(); endfunction
  endclass
endpackage
