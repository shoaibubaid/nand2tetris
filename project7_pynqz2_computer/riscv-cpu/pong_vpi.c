#include <vpi_user.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <fcntl.h>

#define PORT 50007
#define FB_WORDS 19200
#define FRAME_BYTES 76800
#define CYCLES_PER_FRAME 33000

static vpiHandle clk_h, valid_h, ready_h, data_h, memory_h;
static int listen_fd = -1, client_fd = -1;
static unsigned long cycle_count = 0;
static int event_valid_raised = 0;
static uint8_t frame[FRAME_BYTES];
static uint8_t input_buf[512];
static size_t input_used = 0;
static s_cb_data clock_cb; /* Must outlive start_of_sim(). */

static void put_int(vpiHandle h, int value) {
    s_vpi_value v;
    v.format = vpiIntVal;
    v.value.integer = value;
    vpi_put_value(h, &v, NULL, vpiNoDelay);
}

static int get_int(vpiHandle h) {
    s_vpi_value v;
    v.format = vpiIntVal;
    vpi_get_value(h, &v);
    return v.value.integer;
}

static int send_all(int fd, const uint8_t *p, size_t n) {
    while (n) {
        ssize_t k = send(fd, p, n, MSG_NOSIGNAL);
        if (k < 0) {
            if (errno == EINTR) continue;
            return -1;
        }
        if (k == 0) return -1;
        p += k;
        n -= (size_t)k;
    }
    return 0;
}

static void accept_client(void) {
    if (client_fd >= 0 || listen_fd < 0) return;

    client_fd = accept(listen_fd, NULL, NULL);
    if (client_fd >= 0) {
        int flags = fcntl(client_fd, F_GETFL, 0);
        if (flags >= 0) fcntl(client_fd, F_SETFL, flags | O_NONBLOCK);
        vpi_printf("[pong_vpi] Pygame connected.\n");
    }
}

static void read_keyboard(void) {
    uint8_t tmp[256];

    if (client_fd < 0) return;

    for (;;) {
        ssize_t n = recv(client_fd, tmp, sizeof(tmp), 0);
        if (n > 0) {
            size_t copy = (size_t)n;
            if (copy > sizeof(input_buf) - input_used)
                copy = sizeof(input_buf) - input_used;
            memcpy(input_buf + input_used, tmp, copy);
            input_used += copy;
        } else {
            if (n == 0) {
                close(client_fd);
                client_fd = -1;
                input_used = 0;
            } else if (errno != EAGAIN && errno != EWOULDBLOCK &&
                       errno != EINTR) {
                close(client_fd);
                client_fd = -1;
                input_used = 0;
            }
            break;
        }
    }
}

static void push_one_key(void) {
    if (client_fd < 0 || event_valid_raised) return;

    if (input_used >= 2 && get_int(ready_h) == 1) {
        unsigned int event =
            ((unsigned int)input_buf[0] << 8) | input_buf[1];

        memmove(input_buf, input_buf + 2, input_used - 2);
        input_used -= 2;

        put_int(data_h, (int)(event & 0x1ff));
        put_int(valid_h, 1);
        event_valid_raised = 1;
    }
}

static int read_frame(void) {
    int i;

    for (i = 0; i < FB_WORDS; ++i) {
        vpiHandle word = vpi_handle_by_index(memory_h, i);
        s_vpi_value v;
        uint32_t w;

        if (!word) return -1;

        v.format = vpiIntVal;
        vpi_get_value(word, &v);
        w = (uint32_t)v.value.integer;

        frame[4 * i + 0] = (uint8_t)(w & 0xff);
        frame[4 * i + 1] = (uint8_t)((w >> 8) & 0xff);
        frame[4 * i + 2] = (uint8_t)((w >> 16) & 0xff);
        frame[4 * i + 3] = (uint8_t)((w >> 24) & 0xff);
    }

    return 0;
}

static PLI_INT32 on_clock(p_cb_data cb) {
    s_vpi_value cv;
    struct timespec pause_time = {0, 33000000};

    (void)cb;

    cv.format = vpiScalarVal;
    vpi_get_value(clk_h, &cv);
    if (cv.value.scalar != vpi1) return 0;

    ++cycle_count;

    /* Deassert after the bridge has consumed the asserted event. */
    if (event_valid_raised && get_int(ready_h) == 1) {
        put_int(valid_h, 0);
        put_int(data_h, 0);
        event_valid_raised = 0;
    }

    if ((cycle_count % CYCLES_PER_FRAME) != 0) return 0;

    /* Pace the RTL simulation to approximately 30 framebuffer updates/sec. */
    nanosleep(&pause_time, NULL);

    accept_client();
    read_keyboard();
    push_one_key();

    if (client_fd >= 0 && read_frame() == 0) {
        if (send_all(client_fd, frame, FRAME_BYTES) < 0) {
            close(client_fd);
            client_fd = -1;
            input_used = 0;
            vpi_printf("[pong_vpi] Pygame client disconnected.\n");
        }
    }

    return 0;
}

static PLI_INT32 start_of_sim(p_cb_data cb) {
    struct sockaddr_in addr;

    (void)cb;

    clk_h = vpi_handle_by_name("cpu_pong_tb.clk", NULL);
    valid_h = vpi_handle_by_name("cpu_pong_tb.ps_event_valid", NULL);
    ready_h = vpi_handle_by_name("cpu_pong_tb.ps_event_ready", NULL);
    data_h = vpi_handle_by_name("cpu_pong_tb.ps_event_data", NULL);
    memory_h = vpi_handle_by_name(
        "cpu_pong_tb.dut.dmem.framebuffer_controller.memory", NULL);

    if (!clk_h || !valid_h || !ready_h || !data_h || !memory_h) {
        vpi_printf("[pong_vpi] ERROR: Could not find expected testbench/CPU/framebuffer hierarchy.\n");
        vpi_control(vpiFinish, 1);
        return 0;
    }

    listen_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (listen_fd < 0) {
        vpi_printf("[pong_vpi] ERROR: socket() failed.\n");
        vpi_control(vpiFinish, 1);
        return 0;
    }

    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    addr.sin_port = htons(PORT);

    if (bind(listen_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0 ||
        listen(listen_fd, 1) < 0) {
        vpi_printf("[pong_vpi] ERROR: bind/listen failed on 127.0.0.1:%d (is another session running?).\n",
                   PORT);
        close(listen_fd);
        listen_fd = -1;
        vpi_control(vpiFinish, 1);
        return 0;
    }

    {
        int flags = fcntl(listen_fd, F_GETFL, 0);
        if (flags >= 0) fcntl(listen_fd, F_SETFL, flags | O_NONBLOCK);
    }

    memset(&clock_cb, 0, sizeof(clock_cb));
    clock_cb.reason = cbValueChange;
    clock_cb.cb_rtn = on_clock;
    clock_cb.obj = clk_h;
    vpi_register_cb(&clock_cb);

    vpi_printf("[pong_vpi] Listening on 127.0.0.1:%d\n", PORT);
    return 0;
}

static void register_pong_vpi(void) {
    static s_cb_data start_cb;

    memset(&start_cb, 0, sizeof(start_cb));
    start_cb.reason = cbStartOfSimulation;
    start_cb.cb_rtn = start_of_sim;
    vpi_register_cb(&start_cb);
}

void (*vlog_startup_routines[])(void) = {
    register_pong_vpi,
    0
};
