/* $Id: colorize.c 3816 2004-07-03 17:01:32Z lefevre $
 *
 * Colorize the standard input. Written for zsh stderr coloring.
 * Found at http://www.zsh.org/mla/users/2004/msg00804.html
 * Compile with `gcc colorize.c -o colorize` and move to bin folder
 */

#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <errno.h>
#include <signal.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/select.h>
#include <sys/types.h>

#define BUFFSIZE 1024

static volatile sig_atomic_t usr1;

static void sigusr1(int sig)
{
  usr1 = 1;
}

static void writepid(char *tmpfile)
{
  FILE *f;

  f = fopen(tmpfile, "w");
  if (f == NULL)
    {
      perror("colorize (fopen)");
      exit(EXIT_FAILURE);
    }
  fprintf(f, "%ld\n", (long) getpid());
  if (fclose(f) != 0)
    {
      perror("colorize (fclose)");
      exit(EXIT_FAILURE);
    }
}

int main(int argc, char **argv)
{
  pid_t zshpid = 0;
  char *begstr, *endstr;
  fd_set rfds;
  int ret;

  if (argc != 3 && argc != 5)
    {
      fprintf(stderr,
              "Usage: colorize <begstr> <endstr> [ <zshpid> <tmpfile> ]\n");
      exit(EXIT_FAILURE);
    }

  /* Assume that the arguments are correct. Anyway, it is not possible
     to check them entirely. */
  begstr = argv[1];
  endstr = argv[2];
  if (argc == 5)
    {
      /* To do the synchronization with the zsh prompt output...
         Seems to be useless in practice, hence the argc == 3 case. */
      zshpid = atol(argv[3]);
      signal(SIGUSR1, sigusr1);
      writepid(argv[4]);
    }

  fcntl(0, F_SETFL, fcntl(0, F_GETFL) | O_NONBLOCK);

  /* To watch stdin (fd 0). */
  FD_ZERO(&rfds);
  FD_SET(0, &rfds);

  for (;;)
    {
      ret = select(1, &rfds, NULL, NULL, NULL);

      if (ret < 0 && errno != EINTR)
        {
          perror("colorize (pselect)");
          exit(EXIT_FAILURE);
        }

      if (ret > 0)
        {
          static unsigned char buffer[BUFFSIZE];
          static int dontcol = 0;
          ssize_t n;

          while ((n = read(0, buffer, BUFFSIZE)) >= 0)
            {
              ssize_t i;

              if (n == 0)
                return 0;  /* stdin has been closed */
              for (i = 0; i < n; i++)
                {
                  if (buffer[i] == 27)
                    dontcol = 1;
                  if (buffer[i] == '\n')
                    dontcol = 0;
                  if (!dontcol)
                    fputs(begstr, stdout);
                  putchar(buffer[i]);
                  if (!dontcol)
                    fputs(endstr, stdout);
                }
            }
          fflush(stdout);
        }

      if (usr1)
        {
          usr1 = 0;
          if (kill(zshpid, SIGUSR1) != 0)
            {
              perror("colorize (kill)");
              exit(EXIT_FAILURE);
            }
        }
    }
}
