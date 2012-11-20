#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#ifdef __APPLE__
#include <libgen.h>
#endif
#include <curl/curl.h>
#include <curl/types.h>
#include <curl/easy.h>
#include <string.h>
#include <time.h>

int ui_index = 0;
int dl_bytes;    

int format_size(void) {
    char buffer[2048];

    if (dl_bytes < 1024)
        sprintf(buffer, "%d bytes", dl_bytes);
    else if (dl_bytes > 1024 && dl_bytes < (1024*1024))
        sprintf(buffer, "%d KBytes", (dl_bytes / 1024));
    else if (dl_bytes > (1024*1024) && dl_bytes <= ((1024*1024)*1024))
        sprintf(buffer, "%.02f MBytes", (((float)dl_bytes / 1024.0) / 1024.0));
    else
        sprintf(buffer, "%d bytes", dl_bytes);

    if (strcmp(getenv("CPKG_VERBOSE"), "1") == 0) {
        printf("\r\33[32;1m+++\33[0m %s", buffer);
        fflush(stdout);
    }
}

size_t write_data(void *ptr, size_t size, size_t nmemb, FILE *stream) {
    int written;
    written = fwrite(ptr, size, nmemb, stream);
    dl_bytes = (dl_bytes + written);
    format_size();
    return written;
}

int main(int argc, char **argv) {
    CURL *curl;
    FILE *fp;
    CURLcode res;
    int index;

    for (index=1; index < argc; index++) {
        dl_bytes = 0;
        curl = curl_easy_init();
        if (curl) {
            fp = fopen(strdup(basename(argv[index])), "wb");
            curl_easy_setopt(curl, CURLOPT_URL, strdup(argv[index]));
            if (strcmp(getenv("CPKG_VERBOSE"), "1") == 0)
                printf("\33[32;1m+++\33[0m Fetching ... %s\n", strdup(argv[index]));
            curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data);
            curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
            res = curl_easy_perform(curl);
            /* always cleanup */
            curl_easy_cleanup(curl);
            fclose(fp);
        }
        if (strcmp(getenv("CPKG_VERBOSE"), "1") == 0) {
            printf("\r");
            fflush(stdout);
        }
    }

    return 0;
}
