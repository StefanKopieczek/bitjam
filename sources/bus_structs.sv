package peripherals;
    typedef struct {
        logic [31:0] red;
        logic [31:0] green;
        logic [31:0] blue;
    } color_led_data_t;
    
    typedef struct {
        logic red;
        logic green;
        logic blue;
    } color_led_pins_t;
    
    typedef struct {
        logic center;
        logic left;
        logic right;
        logic up;
        logic down;
    } buttons_t;    
    
    typedef struct {
        logic [31:0] display_control;
        logic [63:0] sevenseg_data;
        logic [31:0] mono_led_data;
        color_led_data_t color_led_data[1:0];            
    } peripheral_control_bus_t;       
        
    typedef struct {
        logic [15:0] switch_state;
        buttons_t button_state;
    } peripheral_status_bus_t;
endpackage

package internal_state;
    typedef struct {
        logic [31:0] pc;
        logic [31:0] registers[9:0];
        logic [31:0] cmd;
        logic [2:0] memory_state;
    } internal_state_bus_t;
endpackage

