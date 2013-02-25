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
 * Current transfer speed.
 * Total and percentage.
 */

/*
 * Globals, yes I do hate this.
 */
int dl_bytes = 0;
int flag = 0;
char prog_line[20];

/* Time tracking */
time_t start_t, end_t;

/* Needed by CURL, unused */
void *noop;

/*
 * output functions
 */
void info(char *str) { 
  if (getenv("CPKG_VERBOSE") != NULL && strcmp(getenv("CPKG_VERBOSE"), "1") == 0) {
    printf("\33[32;1m+++\33[0m %s", str);
    fflush(stdout);
  }
}

void error(char *str) { 
  if (getenv("CPKG_VERBOSE") != NULL && strcmp(getenv("CPKG_VERBOSE"), "1") == 0) {
    printf("\33[31;1m***\33[0m %s", str);
    fflush(stdout);
  }
}

void prog(char *str) { 
  if (getenv("CPKG_VERBOSE") != NULL && strcmp(getenv("CPKG_VERBOSE"), "1") == 0) {
    printf("\r\33[32;1m>\33[0m %s", str);
  } else {
    printf("\r%s", str);
  }
  fflush(stdout);
}

/*
 * output formatting functions
 */
char *
format_size(unsigned long s) { 
  int b = 1024;
  char buffer[2048];
  
  if (s < b) {
    sprintf(buffer, "%dB", s);
  } 
  if ( s > 1024 && s < ( 1024*1024 ) ) {
    sprintf(buffer, "%dKB", (s / 1024));
  } 
  if (s > (b*b) && s < ((b*b)*b)) {
    sprintf(buffer, "%.02fMB", (((float)s / (float)b) / (float)b));
  } 
  /* printf("\r\33[32;1m+++\33[0m %s", buffer); */
  return strdup(buffer);
}

/*
 * TODO: um...the functon?
 */
char *
format_time(size_t *s) { return ""; }

char *
gauge(int s) {
  char buffer[12];
  int  idx;
  
  if ((s / 10) > 0) {
    for (idx = 0; idx <= (s / 10); idx++) {
      sprintf(&buffer[idx], "#");
    }
  } else {
    sprintf(buffer, "");
  }
  return strdup(buffer);
}

/*
 * Function: write_data()
 * Arguments: void *ptr, size_t size, size_t nmemb, FILE *stream
 * Returns: size_t written
 * Notes: CURL write callback
 */
size_t write_data(void *ptr, size_t size, size_t nmemb, FILE *stream) { 
  int written;
  written = fwrite(ptr, size, nmemb, stream);
  dl_bytes = (dl_bytes + written);
  /* prog(strdup(format_size(dl_bytes))); */
  return written;
}

/*
 * Function: progress_data()
 * Arguments: void *clientp, double dltotal, double dlnow, double ultotal, double ulnow
 * Returns: (int)0
 * Notes: CURL progress callback
 */
int progress_data(void *clientp, double dltotal, double dlnow, double ultotal, double ulnow) {
  char buffer[1024];
  
  if (dltotal > 1024 && dlnow > 0) {
    if (flag == 1 && strcmp(getenv("CPKG_VERBOSE"), "1") == 0) {
	  strcat(prog_line, format_size(dltotal));
      /* printf("%s\n", format_size(dltotal)); */
      flag = 0;
    }
    
    sprintf(buffer, 
	    "%s (%3d%%) [%-11s] %s @ %s/sec", 
	    prog_line, (int)(((float)dlnow / (float)dltotal) * (float)100), 
	    gauge((int)(((float)dlnow / (float)dltotal) * (float)100)), 
	    format_size(dlnow), 
	    format_size((dlnow / (time(&end_t) - start_t))));
    prog(strdup(buffer));
    /* prog(strcat(format_size(dlnow))); old progress output */
  }
  return 0;
}

/*
 * Function: process_uri()
 * Arguments: char *uri
 * Returns: void
 * Notes: Main worker function
 */
void process_uri(char *uri) { 
  char buffer[1024];
  char fn_buff[7];
  CURL *curl;
  FILE *fp;
  CURLcode res;
  
  curl = curl_easy_init();
  
  if (curl) {
    fp = fopen(strdup(basename(strdup(uri))), "wb");
    

    /* status output */
	if (strlen(strdup(basename(uri))) > 20) {
		sprintf(buffer, "%s...: ", strncat(fn_buff, strdup(basename(uri)), 17));
  	} else {
	    sprintf(buffer, "%s: ", strdup(basename(uri)));
	}
	/* prog(buffer); let everyone know */
	strcat(prog_line, buffer);
    
    /* CURL options */
    curl_easy_setopt(curl, CURLOPT_URL, strdup(uri));
    curl_easy_setopt(curl, CURLOPT_NOPROGRESS, (long)0);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
    /* CURL callbacks */
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data);
    curl_easy_setopt(curl, CURLOPT_PROGRESSFUNCTION, progress_data);
    /* CURL actions */
    res = curl_easy_perform(curl);
    /* CURL cleanup */
    curl_easy_cleanup(curl);
    
    printf("\n");
  }
  
  /* One final bit of cleanup */
  fflush(fp);
  fclose(fp);
  
  /* And for good form */
  return;
}

/*
 * Main entry code, and argument handling
 */
int main(int argc, char **argv) {
  int idx;
  
  for (idx = 1; idx < argc; idx++) {
    dl_bytes = 0;
    flag = 1;
    start_t = time(&start_t);
    process_uri(strdup(argv[idx]));
  }
  
  return 0;
}
