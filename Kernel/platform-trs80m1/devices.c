#include <kernel.h>
#include <tty.h>
#include <version.h>
#include <kdata.h>
#include <devfd.h>
#include <devhd.h>
#include <devsys.h>
#include <devlpr.h>
#include <vt.h>
#include <devtty.h>
#include <devgfx.h>
#include <devfd3.h>
#include <devstringy.h>
#include <blkdev.h>
#include <trs80.h>

struct devsw dev_tab[] =  /* The device driver switch table */
{
  /* 0: /dev/hd		Hard disc block devices */
  {  hd_open,     no_close,     hd_read,   hd_write,   no_ioctl  },
  /* 1: /dev/fd		Floppy disc block devices */
  {  fd_open,     no_close,     fd_read,   fd_write,   no_ioctl  },
  /* 2: /dev/tty	TTY devices */
  {  trstty_open, trstty_close, tty_read,  tty_write,  gfx_ioctl },
  /* 3: /dev/lpr	Printer devices */
  {  lpr_open,    lpr_close,    no_rdwr,   lpr_write,  no_ioctl  },
  /* 4: /dev/mem etc	System devices (one offs) */
  {  no_open,     no_close,     sys_read,  sys_write,  sys_ioctl },
  /* 5: reserved */
  {  nxio_open,     no_close,   no_rdwr,   no_rdwr,    no_ioctl },
  /* 6: reserved */
  {  nxio_open,     no_close,   no_rdwr,   no_rdwr,    no_ioctl },
  /* 7: reserved */
  {  nxio_open,     no_close,   no_rdwr,   no_rdwr,    no_ioctl },
  /* 8: tape (for now - may move to 5 if lots of boxes have tape) */
  {  tape_open,     tape_close, tape_read, tape_write, tape_ioctl },
  /* 9: ide block devices (temporarily until we make /dev/hd a blkdev device */
  {  blkdev_open, no_close,     blkdev_read,   blkdev_write,   blkdev_ioctl  },
};

bool validdev(uint16_t dev)
{
    /* This is a bit uglier than needed but the right hand side is
       a constant this way */
    if(dev > ((sizeof(dev_tab)/sizeof(struct devsw)) << 8) - 1)
	return false;
    else
        return true;
}

void floppy_setup(void)
{
  if (trs80_model == TRS80_MODEL3) {
    dev_tab[1].dev_open = fd3_open;
    dev_tab[1].dev_read = fd3_read;
    dev_tab[1].dev_write = fd3_write;
    dev_tab[8].dev_open = nxio_open;
  }
}
