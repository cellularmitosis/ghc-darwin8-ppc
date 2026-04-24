/* Tiger-compatible splitmix init: /dev/urandom instead of Security/SecRandom.
 * Tiger (10.4) has /dev/urandom since always; Security/SecRandom requires
 * the Security framework which Tiger predates.
 */
#include <stdint.h>
#include <stdio.h>
#include <string.h>

uint64_t splitmix_init() {
    uint64_t result = 0;
    FILE *f = fopen("/dev/urandom", "rb");
    if (f) {
        size_t n = fread(&result, 1, sizeof(result), f);
        fclose(f);
        if (n == sizeof(result)) {
            return result;
        }
    }
    return 0xfeed1000;
}
