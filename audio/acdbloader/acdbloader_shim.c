/*
 * libacdbloader.so for the CAF msm8996 R audio HAL on Gree G0215D.
 *
 * Gree's loader (Android 6, installed as libacdbloader_gree.so) only has
 * acdb_loader_init_v2. platform.c refuses to initialise ACDB unless
 * acdb_loader_init_v3 and acdb_loader_reload_acdb_files exist. Every other
 * symbol the HAL looks up with dlsym() resolves to libacdbloader_gree.so,
 * which this library depends on.
 */

#define LOG_TAG "acdbloader_shim"

#include <stdint.h>
#include <log/log.h>

struct listnode {
    struct listnode *next;
    struct listnode *prev;
};

/* hal/acdb.h: struct meta_key_list; cal_info starts with uint32_t nKey. */
struct meta_key_list {
    struct listnode list;
    uint32_t nKey;
};

int acdb_loader_init_v2(const char *snd_card_name, char *cvd_version,
                        int metaInfoKey);

int acdb_loader_init_v3(const char *snd_card_name, char *cvd_version,
                        struct listnode *metaKey_list)
{
    int key = 0;

    if (metaKey_list && metaKey_list->next != metaKey_list)
        key = ((struct meta_key_list *)metaKey_list->next)->nKey;

    return acdb_loader_init_v2(snd_card_name, cvd_version, key);
}

int acdb_loader_reload_acdb_files(char *new_acdb_file_path,
                                  char *snd_card_name, char *cvd_version,
                                  int metaInfoKey)
{
    (void)new_acdb_file_path;
    (void)snd_card_name;
    (void)cvd_version;
    (void)metaInfoKey;
    ALOGW("ACDB reload is not supported by the Gree loader");
    return -1;
}
