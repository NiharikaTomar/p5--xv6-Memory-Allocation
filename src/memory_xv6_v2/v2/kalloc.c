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

int frames[16385] = {[0 ... 16385-1] = -1};
int pids[16385] = {[0 ... 16385-1] = -1};
int index = 0;
uint framenumber;
uint pfn_kfree;
int flag = 0;

struct run {
  struct run *next;
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
  flag = 0;
  initlock(&kmem.lock, "kmem");
  kmem.use_lock = 0;
  freerange(vstart, vend);
}

void
kinit2(void *vstart, void *vend)
{
  flag = 1;
  freerange(vstart, vend);
  kmem.use_lock = 1;
}
void
kfree2(char *v)
{
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);

  if(kmem.use_lock)
    acquire(&kmem.lock);
  r = (struct run*)v;

  //add to free list
  r->next = kmem.freelist;
  kmem.freelist = r;



  if(kmem.use_lock)
    release(&kmem.lock);
}

void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
    kfree2(p);
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

  //add to free list
  r->next = kmem.freelist;
  kmem.freelist = r;

  if(flag == 1){
    // V2P and shift, and mask off
    pfn_kfree = (uint)(V2P(r) >> 12 & 0xffff);

    //int freeInd = 0;
    for(int i =0; i < 16835; i++){
      if(frames[i] == pfn_kfree){
        frames[i] = -1;
        pids[i] = -1;
        //freeInd = i;
        break;
      }
    }
  }

  // for(int i = freeInd; i < 16835; i++){
  //   frames[i] = frames[i+1];
  //   pids[i] = pids[i+1];
  // }

  // frames[16384] = -1;
  // pids[16384] = -1;

  if(kmem.use_lock)
    release(&kmem.lock);
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
  
  // V2P and shift, and mask off
  framenumber = (uint)(V2P(r) >> 12 & 0xffff);

  if(r){
    kmem.freelist = r->next;
  }

  if(kmem.use_lock) {
    for(int i =0 ; i < 16385; i++){
      if(frames[i] == -1){
        //cprintf("kalloc1 frame_number = %x  and fames[i] = %x and index = %d\n", framenumber, frames[i], i);
        frames[i] = framenumber;
        pids[i] = -2;
        break;
      }
    }
    //cprintf("index in kalloc is %d \n", index);    
    // frames[index] = framenumber;
    // pids[index] = 1;
    // index++;
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
  struct run *r; // current head of the freelist
  struct run *prev; // previous head of the freelist
  struct run *head; // stores current head of the freelist
  uint nextPid = -1;
  uint prevPid = -1;

  if(kmem.use_lock)
    acquire(&kmem.lock);
  r = kmem.freelist; // head which acts as a current pointer
  head = kmem.freelist;
  prev = head;
  int skip = 1;
  while(r){
    //V2P and shift, and mask off
    framenumber = (uint)(V2P(r) >> 12 & 0xffff);

      //looking at 1 frame before current to check for same process
      for(int i = 0; i < 16385; i++){
        if (frames[i] == framenumber - 1) {
          prevPid = pids[i];
          cprintf("prevp %d", prevPid);
          break;
        }
      }
      //looking at 1 frame after current to check for same process
      for(int j = 0; j < 16385; j++){
        if(frames[j] == framenumber + 1){
          nextPid = pids[j];
          cprintf("nextp %d", nextPid);
          break;
        }
      }

    // if(pid == -2 ||
    //   (prevPid == -1 && nextPid == -1) // if both are free
    //       || ((pid == prevPid || prevPid == -2) && nextPid == -1) // if left is not free
    //       || ((prevPid == -1 && (pid == nextPid || nextPid == -2)))) // if right is not free
    //       || ((prevPid == pid || prevPid == -2) && (nextPid == pid || nextPid == -2)) // if both are not free
    //       {
    if(pid == -2 
      //|| 
      /*((prevPid == -1 || prevPid == -2 || prevPid == pid) && (nextPid == -1 || nextPid == -2 || nextPid == pid))*/ ){

        if (skip){
          kmem.freelist = r->next;
        }
        else{
          prev->next = r->next;
        }

      //if(flag == 1){    
        for(int i = 0 ; i < 16385; i++){
          if(frames[i] == -1){
            frames[i] = framenumber;
            pids[i] = pid;
           // cprintf("kalloc2 frame_number = %x  and pid = %d \n", framenumber, pid);
            break;
          }
        }
      //}
      
      break;
      }
      skip = 0;
      prev = r;
      r = r->next;  
    }

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
  int c = 0;
  int oldMax = 100000;
  while(c < numframes){
    int curr_max = 0; 
    for(int i = 0; i < 16385; i++){
      if(frames[i] != -1 && frames[i] > curr_max && frames[i] < oldMax){
        frs[c] = frames[i];
        pds[c] = pids[i];
        curr_max = frames[i];
      }
    }
    c++;
    oldMax = curr_max;
  }
  return 0;
}