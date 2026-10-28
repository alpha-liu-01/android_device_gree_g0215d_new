#define LOG_TAG "lights.msm8996"

#include <cutils/properties.h>
#include <errno.h>
#include <fcntl.h>
#include <hardware/lights.h>
#include <log/log.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static pthread_once_t g_init = PTHREAD_ONCE_INIT;
static pthread_mutex_t g_lock = PTHREAD_MUTEX_INITIALIZER;
static int g_last_backlight = -1;

static const char* const LCD_FILE = "/sys/class/leds/lcd-backlight/brightness";
static const char* const LCD_ALT_FILE =
    "/sys/devices/soc/900000.qcom,mdss_mdp/900000.qcom,mdss_mdp:qcom,mdss_fb_primary/leds/lcd-backlight/brightness";
static const char* const FB_BLANK_FILE = "/sys/class/graphics/fb0/blank";
static const char* const RED_LED_FILE = "/sys/class/leds/red/brightness";
static const char* const GREEN_LED_FILE = "/sys/class/leds/green/brightness";
static const char* const BLUE_LED_FILE = "/sys/class/leds/blue/brightness";

static int write_int(const char* path, int value) {
    int fd = open(path, O_RDWR);
    if (fd < 0) {
        return -errno;
    }
    char buffer[20];
    int bytes = snprintf(buffer, sizeof(buffer), "%d\n", value);
    ssize_t amt = write(fd, buffer, (size_t)bytes);
    close(fd);
    return amt == -1 ? -errno : 0;
}

static void init_globals(void) {
    pthread_mutex_init(&g_lock, NULL);
}

static int rgb_to_brightness(const struct light_state_t* state) {
    int color = state->color & 0x00ffffff;
    return ((77 * ((color >> 16) & 0x00ff)) +
            (150 * ((color >> 8) & 0x00ff)) +
            (29 * (color & 0x00ff))) >> 8;
}

static int set_light_backlight(struct light_device_t* dev,
                               const struct light_state_t* state) {
    if (!dev) {
        return -1;
    }
    int brightness = rgb_to_brightness(state);
    pthread_mutex_lock(&g_lock);
    if (brightness > 0 && g_last_backlight == 0) {
        write_int(FB_BLANK_FILE, 0);
    }
    int err = write_int(LCD_FILE, brightness);
    if (err < 0) {
        err = write_int(LCD_ALT_FILE, brightness);
    }
    if (brightness == 0 && g_last_backlight != 0 &&
        property_get_bool("sys.boot_completed", 0)) {
        write_int(FB_BLANK_FILE, 4);
    }
    g_last_backlight = brightness;
    pthread_mutex_unlock(&g_lock);
    return err;
}

static int set_light_leds(struct light_device_t* dev,
                          const struct light_state_t* state) {
    if (!dev) {
        return -1;
    }
    unsigned int colorRGB = state->color & 0x00ffffff;
    int red = (colorRGB >> 16) & 0xff;
    int green = (colorRGB >> 8) & 0xff;
    int blue = colorRGB & 0xff;
    pthread_mutex_lock(&g_lock);
    write_int(RED_LED_FILE, red);
    write_int(GREEN_LED_FILE, green);
    write_int(BLUE_LED_FILE, blue);
    pthread_mutex_unlock(&g_lock);
    return 0;
}

static int set_light_buttons(struct light_device_t* dev,
                             const struct light_state_t* state) {
    (void)state;
    if (!dev) {
        return -1;
    }
    /* Capacitive keys have no LED. PowerManager still writes this light
     * on user activity, and a missing id logs an error on every gesture. */
    return 0;
}

static int close_lights(struct light_device_t* dev) {
    if (dev) {
        free(dev);
    }
    return 0;
}

static int open_lights(const struct hw_module_t* module, const char* name,
                       struct hw_device_t** device) {
    int (*set_light)(struct light_device_t* dev,
                     const struct light_state_t* state);

    if (0 == strcmp(LIGHT_ID_BACKLIGHT, name)) {
        set_light = set_light_backlight;
    } else if (0 == strcmp(LIGHT_ID_BATTERY, name) ||
               0 == strcmp(LIGHT_ID_NOTIFICATIONS, name) ||
               0 == strcmp(LIGHT_ID_ATTENTION, name)) {
        set_light = set_light_leds;
    } else if (0 == strcmp(LIGHT_ID_BUTTONS, name)) {
        set_light = set_light_buttons;
    } else {
        return -EINVAL;
    }

    pthread_once(&g_init, init_globals);

    struct light_device_t* dev = calloc(1, sizeof(struct light_device_t));
    if (!dev) {
        return -ENOMEM;
    }

    dev->common.tag = HARDWARE_DEVICE_TAG;
    dev->common.version = 0;
    dev->common.module = (struct hw_module_t*)module;
    dev->common.close = (int (*)(struct hw_device_t*))close_lights;
    dev->set_light = set_light;

    *device = (struct hw_device_t*)dev;
    return 0;
}

static struct hw_module_methods_t lights_module_methods = {
    .open = open_lights,
};

struct hw_module_t HAL_MODULE_INFO_SYM = {
    .tag = HARDWARE_MODULE_TAG,
    .version_major = 1,
    .version_minor = 0,
    .id = LIGHTS_HARDWARE_MODULE_ID,
    .name = "G0215D Lights Module",
    .author = "LineageOS",
    .methods = &lights_module_methods,
};
