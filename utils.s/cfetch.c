/*
 * License:
 *
 * This code is based off of a small snippet of curl example code
 * that I found online. I claim no ownership rights over any of 
 * the following code, be it the original snippet or the modifications,
 * and instead release it all as public domain in recognition of
 * the developer who posted the original bit to wherever it was that
 * I happened to find it at.
 */
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <libgen.h>
#include <string.h>
#ifdef __sun
#include <strings.h>
#endif
#ifdef __APPLE__
#include <curl/types.h>
#endif
#include <curl/curl.h>
#include <curl/easy.h>
/*
 * TODO:
 */

/*
 * Globals, yes I do hate this.
 */
int dl_bytes = 0;

/*
 * output functions
 */
void info(char *str) { 
	if (strcmp(getenv("CPKG_VERBOSE"), "1") == 0)
		printf("\33[32;1m+++\33[0m %s\n", str);
  	fflush(stdout);
}

void error(char *str) { 
	if (strcmp(getenv("CPKG_VERBOSE"), "1") == 0)
		printf("\33[31;1m***\33[0m %s\n", str);
  	fflush(stdout);
}

void prog(char *str) { 
	if (strcmp(getenv("CPKG_VERBOSE"), "1") == 0)
		printf("\r\33[32;1m+++\33[0m %s", str);
  	fflush(stdout);
}

/*
 * output formatting functions
 */
char *
format_size(unsigned long s) { 
    int b = 1024;
    float c = 1024.0;
    char buffer[2048];

    if (s < b) {
        sprintf(buffer, "%d bytes", s);
    } 
    if ( s > 1024 && s < ( 1024*1024 ) ) {
        sprintf(buffer, "%d KBytes", (s / 1024));
    } 
    if (s > (b*b) && s < ((b*b)*b)) {
        sprintf(buffer, "%.02f MBytes", (((float)s / c) / c));
    } 
    /* printf("\r\33[32;1m+++\33[0m %s", buffer); */
    return strdup(buffer);
}

char *
format_time(size_t *s) { return ""; }

size_t write_data(void *ptr, size_t size, size_t nmemb, FILE *stream) { 
	int written;
	written = fwrite(ptr, size, nmemb, stream);
    dl_bytes = (dl_bytes + written);
    prog(strdup(format_size(dl_bytes)));
    return written;
}

/*
 * Main worker function
 */
int process_uri(char *uri) { 
    char buffer[1024];
    CURL *curl;
    FILE *fp;
    CURLcode res;

    curl = curl_easy_init();
    
	if (curl) {
		fp = fopen(strdup(basename(strdup(uri))), "wb");
		curl_easy_setopt(curl, CURLOPT_URL, strdup(uri));
		sprintf(buffer, "Fetching ... %s", strdup(uri)); /* let everyone know */
		info(buffer);

		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data);
		curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
		res = curl_easy_perform(curl);
		/* always cleanup */
		curl_easy_cleanup(curl);

		if (strcmp(getenv("CPKG_VERBOSE"), "1") == 0)
			printf("\n");

    }

	fflush(fp);
	fclose(fp);
    return 0;
}

/*
 * Main entry code, and argument handling
 */
int main(int argc, char **argv) {
	int idx;

	for (idx = 1; idx < argc; idx++) {
		dl_bytes = 0;
		process_uri(strdup(argv[idx]));
	}

	return 0;
}
