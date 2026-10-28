/* The Gree libcneapiclient CreateCneNetworkRequest takes (netType, observer).
 * The OnePlus imsdatadaemon calls the newer (netType, observer, slot) form.
 * Slot is ignored: this modem's CNE client has no per-SIM argument. */
void *dlsym(void *handle, const char *symbol);

void *_ZN10CneFactory23CreateCneNetworkRequestE10CnoNetTypeP27ICneNetworkObserverNotifier17CnoSimSlotIdxType(
        int nettype, void *notifier, int slot) {
    void *(*fn)(int, void *);
    (void)slot;
    fn = dlsym((void *)0, "_ZN10CneFactory23CreateCneNetworkRequestE10CnoNetTypeP27ICneNetworkObserverNotifier");
    if (!fn)
        return 0;
    return fn(nettype, notifier);
}
