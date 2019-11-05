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

extern char end[];  // first address after kernel loaded from ELF file
                    // defined by the kernel linker script in kernel.ld

struct run {
    struct run *next;
    int pid; // keep pid (frames)
    struct run *pfn; // page frame number (frames)
};

struct run frames[17000];

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
void kinit1(void *vstart, void *vend) {
    initlock(&kmem.lock, "kmem");
    kmem.use_lock = 0;
    freerange(vstart, vend);
}

void kinit2(void *vstart, void *vend) {
    freerange(vstart, vend);

    struct run *p;
    p = kmem.freelist;
    int c = 0;
    while (c < 17000) {
        frames[c].pid = -1;
        frames[c].pfn = p;
        p = p->next;
        c++;
    }

    kmem.use_lock = 1;
}

void freerange(void *vstart, void *vend) {
    char *p;
    p = (char *) PGROUNDUP((uint) vstart);
    for (; p + PGSIZE <= (char *) vend; p += PGSIZE) {
        kfree2(p);
    }
}

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(char *v) {

    if ((uint) v % PGSIZE || v < end || V2P(v) >= PHYSTOP) {
        panic("kfree");
    }

    // Fill with junk to catch dangling refs.
    memset(v, 1, PGSIZE);

    if (kmem.use_lock) {
        acquire(&kmem.lock);
    }
    
    // Find the pid with the junk pfn and set it to -1
    for (int i = 0; i < 17000; i++) {
        if (frames[i].pfn == (struct run *) v) {
            frames[i].pid = -1;
            break;
        }
    }

    if (kmem.use_lock) {
        release(&kmem.lock);
    }
}

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
//
// Only for freerange because slow without it.
void kfree2(char *v) {
    struct run *r;

    if ((uint) v % PGSIZE || v < end || V2P(v) >= PHYSTOP) {
        panic("kfree");
    }

    // Fill with junk to catch dangling refs.
    memset(v, 1, PGSIZE);

    if (kmem.use_lock){
        acquire(&kmem.lock);
    }

    r = (struct run *) v;

    r->next = kmem.freelist;
    kmem.freelist = r;

    if (kmem.use_lock){
        release(&kmem.lock);
    }
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char *
kalloc(void) {
    struct run *r;

    if (kmem.use_lock) {
        acquire(&kmem.lock);
    }

    r = kmem.freelist;

    if (!kmem.use_lock){
        if (r) {
            kmem.freelist = r->next;
        }
    } else {
        // SECURITY CHECKS
        int c = 0;
        while (c < 17000) {
            // current frame is not allocated or unknown
            if ((frames[c].pid == -1) ||
            // OR left is not allocated or unknown
            ((frames[c-1].pid == -2 || frames[c-1].pid == -1) &&
            // AND right is not allocated or unknown
            (frames[c+1].pid == -2 || frames[c+1].pid == -1) &&
            // AND current frame is not allocated
            frames[c].pid == -1)) {
                frames[c].pid = -2;
                r = frames[c].pfn;
                break;
            }
            c++;
        }
    }

    if (kmem.use_lock) {
        release(&kmem.lock);
    }
    return (char *) r;
}

// Same as kalloc but takes in pid as a parameter
char *
kalloc2(int pid) {
    struct run *r;

    if (kmem.use_lock) {
        acquire(&kmem.lock);
    }

    r = kmem.freelist;

    if (!kmem.use_lock){
        if (r) {
            kmem.freelist = r->next;
        }
    } else {
        // SECURITY CHECKS
        int c = 0;
        while (c < 17000) {
            // first frame
            if (c == 0) {
                // both frames (current and right) not allocated
                if (frames[c].pid == -1 && frames[c+1].pid == -1) {
                    frames[c].pid = pid;
                    r = frames[c].pfn;
                    break;
                }
            }
            // current pid is not allocated and pid is -2
            if ((frames[c].pid == -1 && pid == -2) ||
            // OR left is the same or left is not allocated or unknown
            ((frames[c-1].pid == pid || frames[c-1].pid == -1 || frames[c-1].pid == -2) &&
            // AND right is the same or not allocated or unknown
            (frames[c+1].pid == pid || frames[c+1].pid == -1 || frames[c+1].pid == -2) &&
            // AND current frame is not allocated
            frames[c].pid == -1)) {
                frames[c].pid = pid;
                r = frames[c].pfn;
                break;
            }
            c++;
        }
    }

    if (kmem.use_lock) {
        release(&kmem.lock);
    }
    return (char *) r;
}

// System Call dump_physmem
int
dump_physmem(int *frs, int *pids, int numframes)
{
    // Check if needs to return -1 
    if(numframes <= 0 || frs == 0 || pids == 0) {
        return -1;
    }

    int c = 0; // keep track of frame number and pid
    int i = 0; // keep track of current index
    uint framenumber; // to store framenumber at position i

    // Loop through numframes and update frs[] and pids[] 
    while(c < numframes){
        // Update framenumber
        framenumber = (uint) (V2P(frames[i].pfn) >> 12);
        // Update frs[] and pids[]
        if (frames[i].pid != -1) {
            frs[c] = framenumber;
            pids[c++] = frames[i].pid;
        }
        i++;
    }

  return 0;
}