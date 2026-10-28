/*
 * camera.msm8996.so was built against the Android 6 libgui, whose
 * DisplayEventReceiver default constructor no longer exists. Android 11
 * requires a vsync source. eVsyncSourceApp and eConfigChangedSuppress are
 * both 0, which is what the old constructor used.
 */
extern void _ZN7android20DisplayEventReceiverC1ENS_16ISurfaceComposer11VsyncSourceENS1_13ConfigChangedE(
        void *thiz, int vsync_source, int config_changed);

void _ZN7android20DisplayEventReceiverC1Ev(void *thiz) {
    _ZN7android20DisplayEventReceiverC1ENS_16ISurfaceComposer11VsyncSourceENS1_13ConfigChangedE(
            thiz, 0, 0);
}
