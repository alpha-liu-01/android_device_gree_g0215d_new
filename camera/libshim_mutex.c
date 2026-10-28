/*
 * mm-qcamera-daemon was built for Android 6.
 *
 * pthread_mutex_destroy: Android 11 aborts when this stack destroys a
 * mutex twice. The check is skipped for target SDK < 28, but a vendor
 * binary gets the platform SDK. An already-destroyed mutex is success.
 *
 * pthread_cond_timedwait: the sensor module adds a nanosecond timeout
 * onto tv_nsec and does not carry into tv_sec. Android 11 rejects a
 * tv_nsec outside [0, 1000000000) before waiting, so the open_done wait
 * returns at once and the session is torn down.
 */
#include <dlfcn.h>
#include <pthread.h>
#include <stdint.h>
#include <time.h>

int pthread_mutex_destroy(pthread_mutex_t* mutex) {
    static int (*real_destroy)(pthread_mutex_t*) = 0;
    uint16_t state;

    if (mutex == 0)
        return 22; /* EINVAL */

    /* bionic marks a destroyed mutex with 0xffff in the low half of state. */
    state = *(uint16_t*)mutex;
    if (state == 0xffff)
        return 0;

    if (real_destroy == 0)
        real_destroy = dlsym(RTLD_NEXT, "pthread_mutex_destroy");
    return real_destroy(mutex);
}

int pthread_cond_timedwait(pthread_cond_t* cond, pthread_mutex_t* mutex,
                           const struct timespec* abstime) {
    static int (*real_wait)(pthread_cond_t*, pthread_mutex_t*,
                            const struct timespec*) = 0;
    struct timespec fixed;

    if (real_wait == 0)
        real_wait = dlsym(RTLD_NEXT, "pthread_cond_timedwait");

    if (abstime == 0)
        return real_wait(cond, mutex, abstime);

    fixed = *abstime;
    if (fixed.tv_nsec >= 1000000000L || fixed.tv_nsec < 0) {
        long long nsec = (long long)fixed.tv_sec * 1000000000LL + fixed.tv_nsec;
        fixed.tv_sec = (time_t)(nsec / 1000000000LL);
        fixed.tv_nsec = (long)(nsec % 1000000000LL);
        if (fixed.tv_nsec < 0) {
            fixed.tv_nsec += 1000000000L;
            fixed.tv_sec--;
        }
    }
    return real_wait(cond, mutex, &fixed);
}
