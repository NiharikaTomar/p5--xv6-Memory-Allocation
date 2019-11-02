// Physical memory allocator, intended to allocate
// memory for user processes, kernel stacks, page table pages,
// and pipe buffers. Allocates 4096-byte pages.

#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "spinlock.h"

void freerange(void *vstart, void *vend);
extern char end[]; // first address after kernel loaded from ELF file
                   // defined by the kernel linker script in kernel.ld

int frames[16385];
int pids[16385];
int index = 0;
uint framenumber;
uint pfn_kfree;
uint pidNum;

struct run {
  struct run *next;
  uint pfn;
};

struct {
  struct spinlock lock;
  int use_lock;
  struct run *freelist;
} kmem;

// Initialization happens in two phases.
// 1. main() calls kinit1() while still using entrypgdir to place just
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
  initlock(&kmem.lock, "kmem");
  kmem.use_lock = 0;
  freerange(vstart, vend);
}

void
kinit2(void *vstart, void *vend)
{
  freerange(vstart, vend);
  kmem.use_lock = 1;
}

void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
    kfree(p);
}
// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);

  if(kmem.use_lock)
    acquire(&kmem.lock);
  r = (struct run*)v;


  // // V2P and shift, and mask off
  // pfn_kfree = (uint)(V2P(r) >> 12 & 0xffff);

  // int freeInd = 0;
  // for(int i =0; i < 16834; i++){
  //   if(frames[i] == pfn_kfree){
  //     frames[i] = -1;
  //     pids[i] = -1;
  //     freeInd = i;
  //     break;
  //   }
  // }

  // for(int i = freeInd; i < 16834; i++){
  //   frames[i] = frames[i+1];
  //   pids[i] = pids[i+1];
  // }

  //add to free list
  r->next = kmem.freelist;
  kmem.freelist = r;


  if(kmem.use_lock)
    release(&kmem.lock);
}

uint updatePid(uint pid){
	return pidNum = pid;
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
  struct run *r;

  if(kmem.use_lock)
    acquire(&kmem.lock);
  r = kmem.freelist;
  
  if(r){
    kmem.freelist = r->next;
  }

  // V2P and shift, and mask off
  framenumber = (uint)(V2P(r) >> 12 & 0xffff);

  updatePid(1);

  frames[index] = framenumber;
  pids[index] = pidNum;
  index++;

  if(kmem.use_lock) {
    release(&kmem.lock);
  }
  return (char*)r;
}


// PID
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc2(uint pid)
{
  struct run *r;
  struct run *prev; // head of the freelist
  uint nextPid = -2;
  uint prevPid = -2;

  if(kmem.use_lock)
    acquire(&kmem.lock);
  r = kmem.freelist; // head which acts as a current pointer

  // Update global pid
  uint currPid = updatePid(pid);

  prev = r;
   // cprintf("before while: %p", r);
  while(r){

    // V2P and shift, and mask off
    framenumber = (uint)(V2P(r) >> 12 & 0xffff);
    r->pfn = framenumber;

    frames[index] = framenumber;
    pids[index] = pidNum;
    index++;

    // looking at 1 frame before current to check for same process
    for(int i = 0; i < 16384; i++){

      if (frames[i] == r->pfn - 1) {
        prevPid = pids[i];
        // cprintf("check prev: %d\n", prevPid);
        break;
      }
    }
    // looking at 1 frame after current to check for same process
    for(int j = 0; j < 16384; j++){

      if(frames[j] == r->pfn + 1){
        nextPid = pids[j];
        // cprintf("check next: %d\n", nextPid);
        break;
      }
    }
    
    // if((prevPid == -1 && prevPid ==  currPid) || (nextPid == -1 && nextPid == currPid)){
    // cprintf("outside if: (%d, %d), (%d, %d) %d\n", pids[i], i,  pids[j], j, currPid);
    if(((prevPid != -2 && prevPid ==  currPid) && (nextPid != -2 && nextPid == currPid)) ||
      (prevPid == -2 && nextPid == -2) || (prevPid != -2 && currPid == prevPid && nextPid == -2) ||
      (prevPid == -2 && nextPid != -2 && currPid == nextPid)){
    // cprintf("inside if: (%d, %d), (%d, %d) %d\n", pids[i], i,  pids[j], j, currPid);
      // cprintf("after if: %d", prevPid);
      if(r == kmem.freelist){
        kmem.freelist = r->next;
      } else {
        prev->next = r->next;
      }
      break;
    }
    prev = r;
    r = r->next;  
      // cprintf("after while: %d\n", currPid);
      // cprintf("after while: %d", nextPid);
      // cprintf("after while: %d", prevPid);
  }
  //cprintf("after while: %p", prev);


  if(kmem.use_lock) {
    release(&kmem.lock);
  }

  return (char*)r;
}

int
dump_physmem(int *frs, int *pds, int numframes)
{
  if(numframes <= 0 || frs == 0 || pds == 0)
    return -1;
  for (int i = 0; i < numframes; i++) {
    frs[i] = frames[i];
    pds[i] = pids[i];
  }
  return 0;
}