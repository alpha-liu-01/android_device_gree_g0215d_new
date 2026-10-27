/*
 * sensors.ssc.so (Android 6) links liblocationservice.so and calls
 * izat_manager::getIzatManager() for the fused-location sensors. The rest of
 * that GPS stack is not on this build. Returning null makes those sensors
 * stay absent; the SSC sensors (accel, gyro, mag, light, proximity,
 * barometer, humidity) do not need it.
 */
class izat_manager {
 public:
    class IOSFramework;
    static izat_manager* getIzatManager(IOSFramework*);
};

izat_manager* izat_manager::getIzatManager(IOSFramework*) {
    return nullptr;
}
