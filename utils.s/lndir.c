/*	$OpenBSD: lndir.c,v 1.19 2010/08/22 21:25:37 tedu Exp $	*/
/* $XConsortium: lndir.c /main/15 1995/08/30 10:56:18 gildea $ */

/*
 * Create shadow link tree (after X11R4 script of the same name)
 * Mark Reinhold (mbr@lcs.mit.edu)/3 January 1990
 * Stupid and unnecessary UI crap: Mike 'Fuzzy' Partin
 */

/*
 Copyright (c) 1990,  X Consortium
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
 X CONSORTIUM BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
 AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Except as contained in this notice, the name of the X Consortium shall not be
 used in advertising or otherwise to promote the sale, use or other dealings
 in this Software without prior written authorization from the X Consortium.
 
 */

/* From the original /bin/sh script:
 
 Used to create a copy of the a directory tree that has links for all
 non-directories (except those named RCS, SCCS or CVS.adm).  If you are
 building the distribution on more than one machine, you should use
 this technique.
 
 If your master sources are located in /usr/local/src/X and you would like
 your link tree to be in /usr/local/src/new-X, do the following:
 
 %  mkdir /usr/local/src/new-X
 %  cd /usr/local/src/new-X
 %  lndir ../X
 */

#include <sys/param.h>
#include <sys/stat.h>

#include <dirent.h>
#include <err.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>

extern char *__progname;

int silent;			/* -silent */
int ignore_links;		/* -ignorelinks */
int dir_count, lnk_count, dot_count = 0;

char *rcurdir;
char *curdir;

int equivalent(char *, char *);
void addexcept(char *);
int dodir(char *, struct stat *, struct stat *, int, char *);
void usage(void);

struct except {
	char *name;
	struct except *next;
};

struct except *exceptions;

int
main(int argc, char *argv[])
{
	struct stat fs, ts;
	char *fn, *tn, *bn;
    int retv;
	
	while (++argv, --argc) {
		if ((strcmp(*argv, "-silent") == 0) ||
		    (strcmp(*argv, "-s") == 0))
			silent = 1;
		else if ((strcmp(*argv, "-ignorelinks") == 0) ||
                 (strcmp(*argv, "-i") == 0))
			ignore_links = 1;
		else if (strcmp(*argv, "-e") == 0) {
			++argv, --argc;
            
			if (argc < 2)
				usage();
			addexcept(*argv);
		} else if (strcmp(*argv, "--") == 0) {
			++argv, --argc;
			break;
		} else
			break;
	}
    
	if (argc < 1 || argc > 3)
		usage();
    
	fn = argv[0];
	if (argc >= 2)
		tn = argv[1];
	else
		usage();
	
	if (argc == 3)
		bn = argv[2];
	else
		bn = "";
    
	/* to directory */
	if (stat(tn, &ts) < 0)
		err(1, "%s", tn);
	if (!(S_ISDIR(ts.st_mode)))
		errx(2, "%s: %s", tn, strerror(ENOTDIR));
	if (chdir(tn) < 0)
		err(1, "%s", tn);
    
	/* from directory */
	if (stat(fn, &fs) < 0)
		err(1, "%s", fn);
	if (!(S_ISDIR(fs.st_mode)))
		errx(2, "%s: %s", fn, strerror(ENOTDIR));
    
	retv = dodir(fn, &fs, &ts, 0, bn);
	if (strcmp(getenv("CPKG_VERBOSE"), "1") == 0)
		fprintf(stderr, "\n");
	exit(retv);
	/* exit(dodir(fn, &fs, &ts, 0)); */
}

int
equivalent(char *lname, char *rname)
{
	char *s, *ns;
    
	if (strcmp(lname, rname) == 0)
		return(1);
	for (s = lname; *s && (s = strchr(s, '/')); s++) {
		if (s[1] == '/') {
			/* collapse multiple slashes in lname */
			for (ns = s + 1; *ns == '/'; ns++)
				;
			memmove(s + 1, ns, strlen(ns) + 1);
		}
	}
	return (strcmp(lname, rname) == 0);
}

void
addexcept(char *name)
{
	struct except *new;
    
	new = malloc(sizeof(struct except));
	if (new == NULL)
		err(1, NULL);
	new->name = strdup(name);
	if (new->name == NULL)
		err(1, NULL);
    
	new->next = exceptions;
	exceptions = new;
}


/*
 * Recursively create symbolic links from the current directory to the "from"
 * directory.  Assumes that files described by fs and ts are directories.
 */
#if 0
char *fn;		/* name of "from" directory, either absolute or
                 relative to cwd */
struct stat *fs, *ts;	/* stats for the "from" directory and cwd */
int rel;		/* if true, prepend "../" to fn before using */
#endif
int
dodir(char *fn, struct stat *fs, struct stat *ts, int rel, char *bn)
{
	char buf[MAXPATHLEN + 1], symbuf[MAXPATHLEN + 1];
	char basesym[MAXPATHLEN + 1];
	/* int dir_count, lnk_count = 0; */
	int n_dirs, symlen, basesymlen = -1;
	struct stat sb, sc;
	struct except *cur;
	struct dirent *dp;
	char *ocurdir, *p;
	DIR *df;
    
	if (fs->st_dev == ts->st_dev && fs->st_ino == ts->st_ino) {
		warnx("%s: From and to directories are identical!", fn);
		return(1);
	}
    
	if (rel)
#ifdef __GNUC__
		strncpy(buf, "../", sizeof(buf));
#else
		strlcpy(buf, "../", sizeof(buf));
#endif
	else
		buf[0] = '\0';
#ifdef __GNUC__
	strncat(buf, fn, sizeof(buf));
#else
	strlcat(buf, fn, sizeof(buf));
#endif

	if (!(df = opendir(buf))) {
		warn("%s: Cannot opendir", buf);
		return(1);
	}
    
	p = buf + strlen(buf);
	*p++ = '/';
	n_dirs = fs->st_nlink;
	while ((dp = readdir(df))) {
#ifdef __GNUC__
		if (dp->d_reclen == 0 || dp->d_name[dp->d_reclen - 1] == '~' ||
#else
		if (dp->d_namlen == 0 || dp->d_name[dp->d_namlen - 1] == '~' ||
#endif
			strncmp(dp->d_name, ".#", 2) == 0)
			continue;
		for (cur = exceptions; cur != NULL; cur = cur->next) {
			if (!strcmp(dp->d_name, cur->name))
				goto next;	/* can't continue */
		}
#ifdef __GNUC__
		strncpy(p, dp->d_name, buf + sizeof(buf) - p);
#else
		strlcpy(p, dp->d_name, buf + sizeof(buf) - p);
#endif

		if (n_dirs > 0) {
			if (stat(buf, &sb) < 0) {
				warn("%s", buf);
				continue;
			}
            
			if (S_ISDIR(sb.st_mode)) {
				/* directory */
				n_dirs--;
				if (dp->d_name[0] == '.' &&
				    (dp->d_name[1] == '\0' ||
                     (dp->d_name[1] == '.' &&
                      dp->d_name[2] == '\0')))
					continue;
				if (!strcmp(dp->d_name, "RCS"))
					continue;
				if (!strcmp(dp->d_name, "SCCS"))
					continue;
				if (!strcmp(dp->d_name, "CVS"))
					continue;
				if (!strcmp(dp->d_name, "CVS.adm"))
					continue;
				ocurdir = rcurdir;
				rcurdir = buf;
				curdir = silent ? buf : NULL;
				if (!silent)
					printf("%s:\n", buf);
				if (stat(dp->d_name, &sc) < 0 &&
				    errno == ENOENT) {
					if (mkdir(dp->d_name, 0777) < 0 ||
					    stat(dp->d_name, &sc) < 0) {
						warn("%s", dp->d_name);
						curdir = rcurdir = ocurdir;
						continue;
					}
					dir_count++;
				}
				if (readlink(dp->d_name, symbuf,
                             sizeof(symbuf) - 1) >= 0) {
					fprintf(stderr,
                            "%s: is a link instead of a "
                            "directory\n",
                            dp->d_name);
					curdir = rcurdir = ocurdir;
					continue;
				}
				if (chdir(dp->d_name) < 0) {
					warn("%s", dp->d_name);
					curdir = rcurdir = ocurdir;
					continue;
				}
				dodir(buf, &sb, &sc, (buf[0] != '/'), bn);
				if (chdir("..") < 0)
					err(1, "..");
				curdir = rcurdir = ocurdir;
				continue;
			}
		}
        
		/* non-directory */
		symlen = readlink(dp->d_name, symbuf, sizeof(symbuf) - 1);
		if (symlen >= 0)
			symbuf[symlen] = '\0';
        
		/*
		 * The option to ignore links exists mostly because
		 * checking for them slows us down by 10-20%.
		 * But it is off by default because this is a useful check.
		 */
		if (!ignore_links) {
			/* see if the file in the base tree was a symlink */
			basesymlen = readlink(buf, basesym,
                                  sizeof(basesym) - 1);
			if (basesymlen >= 0)
				basesym[basesymlen] = '\0';
		}
        
		if (symlen >= 0) {
			/*
			 * Link exists in new tree.  Print message if
			 * it doesn't match.
			 */
			if (!equivalent(basesymlen >= 0 ? basesym : buf,
                            symbuf))
				fprintf(stderr,"%s: %s\n", dp->d_name, symbuf);
		} else {
			if (symlink(basesymlen >= 0 ? basesym : buf,
                        dp->d_name) < 0)
				warn("%s", dp->d_name);
			lnk_count++;
		}
    next:
        ;
		if (strcmp(getenv("CPKG_VERBOSE"), "1") == 0)
			fprintf(stderr, "\33[32;1m>\33[0m %-35s: %7d\r", bn, (dir_count+lnk_count));
	}
    
	closedir(df);
	return (0);
}

void
usage(void)
{
	fprintf(stderr, "usage: %s [-is] [-e exceptfile] fromdir todir [pkgname]\n",
            __progname);
	exit(1);
}
