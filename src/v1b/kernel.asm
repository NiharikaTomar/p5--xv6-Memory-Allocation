
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4                   	.byte 0xe4

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 80 10 00       	mov    $0x108000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc d0 a5 10 80       	mov    $0x8010a5d0,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 a3 2b 10 80       	mov    $0x80102ba3,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	57                   	push   %edi
80100038:	56                   	push   %esi
80100039:	53                   	push   %ebx
8010003a:	83 ec 18             	sub    $0x18,%esp
8010003d:	89 c6                	mov    %eax,%esi
8010003f:	89 d7                	mov    %edx,%edi
  struct buf *b;

  acquire(&bcache.lock);
80100041:	68 e0 a5 10 80       	push   $0x8010a5e0
80100046:	e8 91 3c 00 00       	call   80103cdc <acquire>

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010004b:	8b 1d 30 ed 10 80    	mov    0x8010ed30,%ebx
80100051:	83 c4 10             	add    $0x10,%esp
80100054:	eb 03                	jmp    80100059 <bget+0x25>
80100056:	8b 5b 54             	mov    0x54(%ebx),%ebx
80100059:	81 fb dc ec 10 80    	cmp    $0x8010ecdc,%ebx
8010005f:	74 30                	je     80100091 <bget+0x5d>
    if(b->dev == dev && b->blockno == blockno){
80100061:	39 73 04             	cmp    %esi,0x4(%ebx)
80100064:	75 f0                	jne    80100056 <bget+0x22>
80100066:	39 7b 08             	cmp    %edi,0x8(%ebx)
80100069:	75 eb                	jne    80100056 <bget+0x22>
      b->refcnt++;
8010006b:	8b 43 4c             	mov    0x4c(%ebx),%eax
8010006e:	83 c0 01             	add    $0x1,%eax
80100071:	89 43 4c             	mov    %eax,0x4c(%ebx)
      release(&bcache.lock);
80100074:	83 ec 0c             	sub    $0xc,%esp
80100077:	68 e0 a5 10 80       	push   $0x8010a5e0
8010007c:	e8 c0 3c 00 00       	call   80103d41 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 3c 3a 00 00       	call   80103ac8 <acquiresleep>
      return b;
8010008c:	83 c4 10             	add    $0x10,%esp
8010008f:	eb 4c                	jmp    801000dd <bget+0xa9>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100091:	8b 1d 2c ed 10 80    	mov    0x8010ed2c,%ebx
80100097:	eb 03                	jmp    8010009c <bget+0x68>
80100099:	8b 5b 50             	mov    0x50(%ebx),%ebx
8010009c:	81 fb dc ec 10 80    	cmp    $0x8010ecdc,%ebx
801000a2:	74 43                	je     801000e7 <bget+0xb3>
    if(b->refcnt == 0 && (b->flags & B_DIRTY) == 0) {
801000a4:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801000a8:	75 ef                	jne    80100099 <bget+0x65>
801000aa:	f6 03 04             	testb  $0x4,(%ebx)
801000ad:	75 ea                	jne    80100099 <bget+0x65>
      b->dev = dev;
801000af:	89 73 04             	mov    %esi,0x4(%ebx)
      b->blockno = blockno;
801000b2:	89 7b 08             	mov    %edi,0x8(%ebx)
      b->flags = 0;
801000b5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
      b->refcnt = 1;
801000bb:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
      release(&bcache.lock);
801000c2:	83 ec 0c             	sub    $0xc,%esp
801000c5:	68 e0 a5 10 80       	push   $0x8010a5e0
801000ca:	e8 72 3c 00 00       	call   80103d41 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 ee 39 00 00       	call   80103ac8 <acquiresleep>
      return b;
801000da:	83 c4 10             	add    $0x10,%esp
    }
  }
  panic("bget: no buffers");
}
801000dd:	89 d8                	mov    %ebx,%eax
801000df:	8d 65 f4             	lea    -0xc(%ebp),%esp
801000e2:	5b                   	pop    %ebx
801000e3:	5e                   	pop    %esi
801000e4:	5f                   	pop    %edi
801000e5:	5d                   	pop    %ebp
801000e6:	c3                   	ret    
  panic("bget: no buffers");
801000e7:	83 ec 0c             	sub    $0xc,%esp
801000ea:	68 00 66 10 80       	push   $0x80106600
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 11 66 10 80       	push   $0x80106611
80100100:	68 e0 a5 10 80       	push   $0x8010a5e0
80100105:	e8 96 3a 00 00       	call   80103ba0 <initlock>
  bcache.head.prev = &bcache.head;
8010010a:	c7 05 2c ed 10 80 dc 	movl   $0x8010ecdc,0x8010ed2c
80100111:	ec 10 80 
  bcache.head.next = &bcache.head;
80100114:	c7 05 30 ed 10 80 dc 	movl   $0x8010ecdc,0x8010ed30
8010011b:	ec 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010011e:	83 c4 10             	add    $0x10,%esp
80100121:	bb 14 a6 10 80       	mov    $0x8010a614,%ebx
80100126:	eb 37                	jmp    8010015f <binit+0x6b>
    b->next = bcache.head.next;
80100128:	a1 30 ed 10 80       	mov    0x8010ed30,%eax
8010012d:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
80100130:	c7 43 50 dc ec 10 80 	movl   $0x8010ecdc,0x50(%ebx)
    initsleeplock(&b->lock, "buffer");
80100137:	83 ec 08             	sub    $0x8,%esp
8010013a:	68 18 66 10 80       	push   $0x80106618
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 4d 39 00 00       	call   80103a95 <initsleeplock>
    bcache.head.next->prev = b;
80100148:	a1 30 ed 10 80       	mov    0x8010ed30,%eax
8010014d:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
80100150:	89 1d 30 ed 10 80    	mov    %ebx,0x8010ed30
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100156:	81 c3 5c 02 00 00    	add    $0x25c,%ebx
8010015c:	83 c4 10             	add    $0x10,%esp
8010015f:	81 fb dc ec 10 80    	cmp    $0x8010ecdc,%ebx
80100165:	72 c1                	jb     80100128 <binit+0x34>
}
80100167:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010016a:	c9                   	leave  
8010016b:	c3                   	ret    

8010016c <bread>:

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
8010016c:	55                   	push   %ebp
8010016d:	89 e5                	mov    %esp,%ebp
8010016f:	53                   	push   %ebx
80100170:	83 ec 04             	sub    $0x4,%esp
  struct buf *b;

  b = bget(dev, blockno);
80100173:	8b 55 0c             	mov    0xc(%ebp),%edx
80100176:	8b 45 08             	mov    0x8(%ebp),%eax
80100179:	e8 b6 fe ff ff       	call   80100034 <bget>
8010017e:	89 c3                	mov    %eax,%ebx
  if((b->flags & B_VALID) == 0) {
80100180:	f6 00 02             	testb  $0x2,(%eax)
80100183:	74 07                	je     8010018c <bread+0x20>
    iderw(b);
  }
  return b;
}
80100185:	89 d8                	mov    %ebx,%eax
80100187:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010018a:	c9                   	leave  
8010018b:	c3                   	ret    
    iderw(b);
8010018c:	83 ec 0c             	sub    $0xc,%esp
8010018f:	50                   	push   %eax
80100190:	e8 77 1c 00 00       	call   80101e0c <iderw>
80100195:	83 c4 10             	add    $0x10,%esp
  return b;
80100198:	eb eb                	jmp    80100185 <bread+0x19>

8010019a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
8010019a:	55                   	push   %ebp
8010019b:	89 e5                	mov    %esp,%ebp
8010019d:	53                   	push   %ebx
8010019e:	83 ec 10             	sub    $0x10,%esp
801001a1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001a4:	8d 43 0c             	lea    0xc(%ebx),%eax
801001a7:	50                   	push   %eax
801001a8:	e8 a5 39 00 00       	call   80103b52 <holdingsleep>
801001ad:	83 c4 10             	add    $0x10,%esp
801001b0:	85 c0                	test   %eax,%eax
801001b2:	74 14                	je     801001c8 <bwrite+0x2e>
    panic("bwrite");
  b->flags |= B_DIRTY;
801001b4:	83 0b 04             	orl    $0x4,(%ebx)
  iderw(b);
801001b7:	83 ec 0c             	sub    $0xc,%esp
801001ba:	53                   	push   %ebx
801001bb:	e8 4c 1c 00 00       	call   80101e0c <iderw>
}
801001c0:	83 c4 10             	add    $0x10,%esp
801001c3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801001c6:	c9                   	leave  
801001c7:	c3                   	ret    
    panic("bwrite");
801001c8:	83 ec 0c             	sub    $0xc,%esp
801001cb:	68 1f 66 10 80       	push   $0x8010661f
801001d0:	e8 73 01 00 00       	call   80100348 <panic>

801001d5 <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
801001d5:	55                   	push   %ebp
801001d6:	89 e5                	mov    %esp,%ebp
801001d8:	56                   	push   %esi
801001d9:	53                   	push   %ebx
801001da:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001dd:	8d 73 0c             	lea    0xc(%ebx),%esi
801001e0:	83 ec 0c             	sub    $0xc,%esp
801001e3:	56                   	push   %esi
801001e4:	e8 69 39 00 00       	call   80103b52 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 1e 39 00 00       	call   80103b17 <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
80100200:	e8 d7 3a 00 00       	call   80103cdc <acquire>
  b->refcnt--;
80100205:	8b 43 4c             	mov    0x4c(%ebx),%eax
80100208:	83 e8 01             	sub    $0x1,%eax
8010020b:	89 43 4c             	mov    %eax,0x4c(%ebx)
  if (b->refcnt == 0) {
8010020e:	83 c4 10             	add    $0x10,%esp
80100211:	85 c0                	test   %eax,%eax
80100213:	75 2f                	jne    80100244 <brelse+0x6f>
    // no one is waiting for it.
    b->next->prev = b->prev;
80100215:	8b 43 54             	mov    0x54(%ebx),%eax
80100218:	8b 53 50             	mov    0x50(%ebx),%edx
8010021b:	89 50 50             	mov    %edx,0x50(%eax)
    b->prev->next = b->next;
8010021e:	8b 43 50             	mov    0x50(%ebx),%eax
80100221:	8b 53 54             	mov    0x54(%ebx),%edx
80100224:	89 50 54             	mov    %edx,0x54(%eax)
    b->next = bcache.head.next;
80100227:	a1 30 ed 10 80       	mov    0x8010ed30,%eax
8010022c:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
8010022f:	c7 43 50 dc ec 10 80 	movl   $0x8010ecdc,0x50(%ebx)
    bcache.head.next->prev = b;
80100236:	a1 30 ed 10 80       	mov    0x8010ed30,%eax
8010023b:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
8010023e:	89 1d 30 ed 10 80    	mov    %ebx,0x8010ed30
  }
  
  release(&bcache.lock);
80100244:	83 ec 0c             	sub    $0xc,%esp
80100247:	68 e0 a5 10 80       	push   $0x8010a5e0
8010024c:	e8 f0 3a 00 00       	call   80103d41 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 26 66 10 80       	push   $0x80106626
80100263:	e8 e0 00 00 00       	call   80100348 <panic>

80100268 <consoleread>:
  }
}

int
consoleread(struct inode *ip, char *dst, int n)
{
80100268:	55                   	push   %ebp
80100269:	89 e5                	mov    %esp,%ebp
8010026b:	57                   	push   %edi
8010026c:	56                   	push   %esi
8010026d:	53                   	push   %ebx
8010026e:	83 ec 28             	sub    $0x28,%esp
80100271:	8b 7d 08             	mov    0x8(%ebp),%edi
80100274:	8b 75 0c             	mov    0xc(%ebp),%esi
80100277:	8b 5d 10             	mov    0x10(%ebp),%ebx
  uint target;
  int c;

  iunlock(ip);
8010027a:	57                   	push   %edi
8010027b:	e8 c3 13 00 00       	call   80101643 <iunlock>
  target = n;
80100280:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  acquire(&cons.lock);
80100283:	c7 04 24 20 95 10 80 	movl   $0x80109520,(%esp)
8010028a:	e8 4d 3a 00 00       	call   80103cdc <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 c0 ef 10 80       	mov    0x8010efc0,%eax
8010029f:	3b 05 c4 ef 10 80    	cmp    0x8010efc4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 91 30 00 00       	call   8010333d <myproc>
801002ac:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801002b0:	75 17                	jne    801002c9 <consoleread+0x61>
        release(&cons.lock);
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
801002b2:	83 ec 08             	sub    $0x8,%esp
801002b5:	68 20 95 10 80       	push   $0x80109520
801002ba:	68 c0 ef 10 80       	push   $0x8010efc0
801002bf:	e8 1d 35 00 00       	call   801037e1 <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 95 10 80       	push   $0x80109520
801002d1:	e8 6b 3a 00 00       	call   80103d41 <release>
        ilock(ip);
801002d6:	89 3c 24             	mov    %edi,(%esp)
801002d9:	e8 a3 12 00 00       	call   80101581 <ilock>
        return -1;
801002de:	83 c4 10             	add    $0x10,%esp
801002e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  release(&cons.lock);
  ilock(ip);

  return target - n;
}
801002e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
801002e9:	5b                   	pop    %ebx
801002ea:	5e                   	pop    %esi
801002eb:	5f                   	pop    %edi
801002ec:	5d                   	pop    %ebp
801002ed:	c3                   	ret    
    c = input.buf[input.r++ % INPUT_BUF];
801002ee:	8d 50 01             	lea    0x1(%eax),%edx
801002f1:	89 15 c0 ef 10 80    	mov    %edx,0x8010efc0
801002f7:	89 c2                	mov    %eax,%edx
801002f9:	83 e2 7f             	and    $0x7f,%edx
801002fc:	0f b6 8a 40 ef 10 80 	movzbl -0x7fef10c0(%edx),%ecx
80100303:	0f be d1             	movsbl %cl,%edx
    if(c == C('D')){  // EOF
80100306:	83 fa 04             	cmp    $0x4,%edx
80100309:	74 14                	je     8010031f <consoleread+0xb7>
    *dst++ = c;
8010030b:	8d 46 01             	lea    0x1(%esi),%eax
8010030e:	88 0e                	mov    %cl,(%esi)
    --n;
80100310:	83 eb 01             	sub    $0x1,%ebx
    if(c == '\n')
80100313:	83 fa 0a             	cmp    $0xa,%edx
80100316:	74 11                	je     80100329 <consoleread+0xc1>
    *dst++ = c;
80100318:	89 c6                	mov    %eax,%esi
8010031a:	e9 73 ff ff ff       	jmp    80100292 <consoleread+0x2a>
      if(n < target){
8010031f:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
80100322:	73 05                	jae    80100329 <consoleread+0xc1>
        input.r--;
80100324:	a3 c0 ef 10 80       	mov    %eax,0x8010efc0
  release(&cons.lock);
80100329:	83 ec 0c             	sub    $0xc,%esp
8010032c:	68 20 95 10 80       	push   $0x80109520
80100331:	e8 0b 3a 00 00       	call   80103d41 <release>
  ilock(ip);
80100336:	89 3c 24             	mov    %edi,(%esp)
80100339:	e8 43 12 00 00       	call   80101581 <ilock>
  return target - n;
8010033e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100341:	29 d8                	sub    %ebx,%eax
80100343:	83 c4 10             	add    $0x10,%esp
80100346:	eb 9e                	jmp    801002e6 <consoleread+0x7e>

80100348 <panic>:
{
80100348:	55                   	push   %ebp
80100349:	89 e5                	mov    %esp,%ebp
8010034b:	53                   	push   %ebx
8010034c:	83 ec 34             	sub    $0x34,%esp
}

static inline void
cli(void)
{
  asm volatile("cli");
8010034f:	fa                   	cli    
  cons.locking = 0;
80100350:	c7 05 54 95 10 80 00 	movl   $0x0,0x80109554
80100357:	00 00 00 
  cprintf("lapicid %d: panic: ", lapicid());
8010035a:	e8 5e 21 00 00       	call   801024bd <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 2d 66 10 80       	push   $0x8010662d
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 7b 6f 10 80 	movl   $0x80106f7b,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 27 38 00 00       	call   80103bbb <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 41 66 10 80       	push   $0x80106641
801003aa:	e8 5c 02 00 00       	call   8010060b <cprintf>
  for(i=0; i<10; i++)
801003af:	83 c3 01             	add    $0x1,%ebx
801003b2:	83 c4 10             	add    $0x10,%esp
801003b5:	83 fb 09             	cmp    $0x9,%ebx
801003b8:	7e e4                	jle    8010039e <panic+0x56>
  panicked = 1; // freeze other CPU
801003ba:	c7 05 58 95 10 80 01 	movl   $0x1,0x80109558
801003c1:	00 00 00 
801003c4:	eb fe                	jmp    801003c4 <panic+0x7c>

801003c6 <cgaputc>:
{
801003c6:	55                   	push   %ebp
801003c7:	89 e5                	mov    %esp,%ebp
801003c9:	57                   	push   %edi
801003ca:	56                   	push   %esi
801003cb:	53                   	push   %ebx
801003cc:	83 ec 0c             	sub    $0xc,%esp
801003cf:	89 c6                	mov    %eax,%esi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801003d1:	b9 d4 03 00 00       	mov    $0x3d4,%ecx
801003d6:	b8 0e 00 00 00       	mov    $0xe,%eax
801003db:	89 ca                	mov    %ecx,%edx
801003dd:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801003de:	bb d5 03 00 00       	mov    $0x3d5,%ebx
801003e3:	89 da                	mov    %ebx,%edx
801003e5:	ec                   	in     (%dx),%al
  pos = inb(CRTPORT+1) << 8;
801003e6:	0f b6 f8             	movzbl %al,%edi
801003e9:	c1 e7 08             	shl    $0x8,%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801003ec:	b8 0f 00 00 00       	mov    $0xf,%eax
801003f1:	89 ca                	mov    %ecx,%edx
801003f3:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801003f4:	89 da                	mov    %ebx,%edx
801003f6:	ec                   	in     (%dx),%al
  pos |= inb(CRTPORT+1);
801003f7:	0f b6 c8             	movzbl %al,%ecx
801003fa:	09 f9                	or     %edi,%ecx
  if(c == '\n')
801003fc:	83 fe 0a             	cmp    $0xa,%esi
801003ff:	74 6a                	je     8010046b <cgaputc+0xa5>
  else if(c == BACKSPACE){
80100401:	81 fe 00 01 00 00    	cmp    $0x100,%esi
80100407:	0f 84 81 00 00 00    	je     8010048e <cgaputc+0xc8>
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010040d:	89 f0                	mov    %esi,%eax
8010040f:	0f b6 f0             	movzbl %al,%esi
80100412:	8d 59 01             	lea    0x1(%ecx),%ebx
80100415:	66 81 ce 00 07       	or     $0x700,%si
8010041a:	66 89 b4 09 00 80 0b 	mov    %si,-0x7ff48000(%ecx,%ecx,1)
80100421:	80 
  if(pos < 0 || pos > 25*80)
80100422:	81 fb d0 07 00 00    	cmp    $0x7d0,%ebx
80100428:	77 71                	ja     8010049b <cgaputc+0xd5>
  if((pos/80) >= 24){  // Scroll up.
8010042a:	81 fb 7f 07 00 00    	cmp    $0x77f,%ebx
80100430:	7f 76                	jg     801004a8 <cgaputc+0xe2>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80100432:	be d4 03 00 00       	mov    $0x3d4,%esi
80100437:	b8 0e 00 00 00       	mov    $0xe,%eax
8010043c:	89 f2                	mov    %esi,%edx
8010043e:	ee                   	out    %al,(%dx)
  outb(CRTPORT+1, pos>>8);
8010043f:	89 d8                	mov    %ebx,%eax
80100441:	c1 f8 08             	sar    $0x8,%eax
80100444:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
80100449:	89 ca                	mov    %ecx,%edx
8010044b:	ee                   	out    %al,(%dx)
8010044c:	b8 0f 00 00 00       	mov    $0xf,%eax
80100451:	89 f2                	mov    %esi,%edx
80100453:	ee                   	out    %al,(%dx)
80100454:	89 d8                	mov    %ebx,%eax
80100456:	89 ca                	mov    %ecx,%edx
80100458:	ee                   	out    %al,(%dx)
  crt[pos] = ' ' | 0x0700;
80100459:	66 c7 84 1b 00 80 0b 	movw   $0x720,-0x7ff48000(%ebx,%ebx,1)
80100460:	80 20 07 
}
80100463:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100466:	5b                   	pop    %ebx
80100467:	5e                   	pop    %esi
80100468:	5f                   	pop    %edi
80100469:	5d                   	pop    %ebp
8010046a:	c3                   	ret    
    pos += 80 - pos%80;
8010046b:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100470:	89 c8                	mov    %ecx,%eax
80100472:	f7 ea                	imul   %edx
80100474:	c1 fa 05             	sar    $0x5,%edx
80100477:	8d 14 92             	lea    (%edx,%edx,4),%edx
8010047a:	89 d0                	mov    %edx,%eax
8010047c:	c1 e0 04             	shl    $0x4,%eax
8010047f:	89 ca                	mov    %ecx,%edx
80100481:	29 c2                	sub    %eax,%edx
80100483:	bb 50 00 00 00       	mov    $0x50,%ebx
80100488:	29 d3                	sub    %edx,%ebx
8010048a:	01 cb                	add    %ecx,%ebx
8010048c:	eb 94                	jmp    80100422 <cgaputc+0x5c>
    if(pos > 0) --pos;
8010048e:	85 c9                	test   %ecx,%ecx
80100490:	7e 05                	jle    80100497 <cgaputc+0xd1>
80100492:	8d 59 ff             	lea    -0x1(%ecx),%ebx
80100495:	eb 8b                	jmp    80100422 <cgaputc+0x5c>
  pos |= inb(CRTPORT+1);
80100497:	89 cb                	mov    %ecx,%ebx
80100499:	eb 87                	jmp    80100422 <cgaputc+0x5c>
    panic("pos under/overflow");
8010049b:	83 ec 0c             	sub    $0xc,%esp
8010049e:	68 45 66 10 80       	push   $0x80106645
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 44 39 00 00       	call   80103e03 <memmove>
    pos -= 80;
801004bf:	83 eb 50             	sub    $0x50,%ebx
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801004c2:	b8 80 07 00 00       	mov    $0x780,%eax
801004c7:	29 d8                	sub    %ebx,%eax
801004c9:	8d 94 1b 00 80 0b 80 	lea    -0x7ff48000(%ebx,%ebx,1),%edx
801004d0:	83 c4 0c             	add    $0xc,%esp
801004d3:	01 c0                	add    %eax,%eax
801004d5:	50                   	push   %eax
801004d6:	6a 00                	push   $0x0
801004d8:	52                   	push   %edx
801004d9:	e8 aa 38 00 00       	call   80103d88 <memset>
801004de:	83 c4 10             	add    $0x10,%esp
801004e1:	e9 4c ff ff ff       	jmp    80100432 <cgaputc+0x6c>

801004e6 <consputc>:
  if(panicked){
801004e6:	83 3d 58 95 10 80 00 	cmpl   $0x0,0x80109558
801004ed:	74 03                	je     801004f2 <consputc+0xc>
  asm volatile("cli");
801004ef:	fa                   	cli    
801004f0:	eb fe                	jmp    801004f0 <consputc+0xa>
{
801004f2:	55                   	push   %ebp
801004f3:	89 e5                	mov    %esp,%ebp
801004f5:	53                   	push   %ebx
801004f6:	83 ec 04             	sub    $0x4,%esp
801004f9:	89 c3                	mov    %eax,%ebx
  if(c == BACKSPACE){
801004fb:	3d 00 01 00 00       	cmp    $0x100,%eax
80100500:	74 18                	je     8010051a <consputc+0x34>
    uartputc(c);
80100502:	83 ec 0c             	sub    $0xc,%esp
80100505:	50                   	push   %eax
80100506:	e8 b7 4c 00 00       	call   801051c2 <uartputc>
8010050b:	83 c4 10             	add    $0x10,%esp
  cgaputc(c);
8010050e:	89 d8                	mov    %ebx,%eax
80100510:	e8 b1 fe ff ff       	call   801003c6 <cgaputc>
}
80100515:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100518:	c9                   	leave  
80100519:	c3                   	ret    
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010051a:	83 ec 0c             	sub    $0xc,%esp
8010051d:	6a 08                	push   $0x8
8010051f:	e8 9e 4c 00 00       	call   801051c2 <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 92 4c 00 00       	call   801051c2 <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 86 4c 00 00       	call   801051c2 <uartputc>
8010053c:	83 c4 10             	add    $0x10,%esp
8010053f:	eb cd                	jmp    8010050e <consputc+0x28>

80100541 <printint>:
{
80100541:	55                   	push   %ebp
80100542:	89 e5                	mov    %esp,%ebp
80100544:	57                   	push   %edi
80100545:	56                   	push   %esi
80100546:	53                   	push   %ebx
80100547:	83 ec 1c             	sub    $0x1c,%esp
8010054a:	89 d7                	mov    %edx,%edi
  if(sign && (sign = xx < 0))
8010054c:	85 c9                	test   %ecx,%ecx
8010054e:	74 09                	je     80100559 <printint+0x18>
80100550:	89 c1                	mov    %eax,%ecx
80100552:	c1 e9 1f             	shr    $0x1f,%ecx
80100555:	85 c0                	test   %eax,%eax
80100557:	78 09                	js     80100562 <printint+0x21>
    x = xx;
80100559:	89 c2                	mov    %eax,%edx
  i = 0;
8010055b:	be 00 00 00 00       	mov    $0x0,%esi
80100560:	eb 08                	jmp    8010056a <printint+0x29>
    x = -xx;
80100562:	f7 d8                	neg    %eax
80100564:	89 c2                	mov    %eax,%edx
80100566:	eb f3                	jmp    8010055b <printint+0x1a>
    buf[i++] = digits[x % base];
80100568:	89 de                	mov    %ebx,%esi
8010056a:	89 d0                	mov    %edx,%eax
8010056c:	ba 00 00 00 00       	mov    $0x0,%edx
80100571:	f7 f7                	div    %edi
80100573:	8d 5e 01             	lea    0x1(%esi),%ebx
80100576:	0f b6 92 70 66 10 80 	movzbl -0x7fef9990(%edx),%edx
8010057d:	88 54 35 d8          	mov    %dl,-0x28(%ebp,%esi,1)
  }while((x /= base) != 0);
80100581:	89 c2                	mov    %eax,%edx
80100583:	85 c0                	test   %eax,%eax
80100585:	75 e1                	jne    80100568 <printint+0x27>
  if(sign)
80100587:	85 c9                	test   %ecx,%ecx
80100589:	74 14                	je     8010059f <printint+0x5e>
    buf[i++] = '-';
8010058b:	c6 44 1d d8 2d       	movb   $0x2d,-0x28(%ebp,%ebx,1)
80100590:	8d 5e 02             	lea    0x2(%esi),%ebx
80100593:	eb 0a                	jmp    8010059f <printint+0x5e>
    consputc(buf[i]);
80100595:	0f be 44 1d d8       	movsbl -0x28(%ebp,%ebx,1),%eax
8010059a:	e8 47 ff ff ff       	call   801004e6 <consputc>
  while(--i >= 0)
8010059f:	83 eb 01             	sub    $0x1,%ebx
801005a2:	79 f1                	jns    80100595 <printint+0x54>
}
801005a4:	83 c4 1c             	add    $0x1c,%esp
801005a7:	5b                   	pop    %ebx
801005a8:	5e                   	pop    %esi
801005a9:	5f                   	pop    %edi
801005aa:	5d                   	pop    %ebp
801005ab:	c3                   	ret    

801005ac <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
801005ac:	55                   	push   %ebp
801005ad:	89 e5                	mov    %esp,%ebp
801005af:	57                   	push   %edi
801005b0:	56                   	push   %esi
801005b1:	53                   	push   %ebx
801005b2:	83 ec 18             	sub    $0x18,%esp
801005b5:	8b 7d 0c             	mov    0xc(%ebp),%edi
801005b8:	8b 75 10             	mov    0x10(%ebp),%esi
  int i;

  iunlock(ip);
801005bb:	ff 75 08             	pushl  0x8(%ebp)
801005be:	e8 80 10 00 00       	call   80101643 <iunlock>
  acquire(&cons.lock);
801005c3:	c7 04 24 20 95 10 80 	movl   $0x80109520,(%esp)
801005ca:	e8 0d 37 00 00       	call   80103cdc <acquire>
  for(i = 0; i < n; i++)
801005cf:	83 c4 10             	add    $0x10,%esp
801005d2:	bb 00 00 00 00       	mov    $0x0,%ebx
801005d7:	eb 0c                	jmp    801005e5 <consolewrite+0x39>
    consputc(buf[i] & 0xff);
801005d9:	0f b6 04 1f          	movzbl (%edi,%ebx,1),%eax
801005dd:	e8 04 ff ff ff       	call   801004e6 <consputc>
  for(i = 0; i < n; i++)
801005e2:	83 c3 01             	add    $0x1,%ebx
801005e5:	39 f3                	cmp    %esi,%ebx
801005e7:	7c f0                	jl     801005d9 <consolewrite+0x2d>
  release(&cons.lock);
801005e9:	83 ec 0c             	sub    $0xc,%esp
801005ec:	68 20 95 10 80       	push   $0x80109520
801005f1:	e8 4b 37 00 00       	call   80103d41 <release>
  ilock(ip);
801005f6:	83 c4 04             	add    $0x4,%esp
801005f9:	ff 75 08             	pushl  0x8(%ebp)
801005fc:	e8 80 0f 00 00       	call   80101581 <ilock>

  return n;
}
80100601:	89 f0                	mov    %esi,%eax
80100603:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100606:	5b                   	pop    %ebx
80100607:	5e                   	pop    %esi
80100608:	5f                   	pop    %edi
80100609:	5d                   	pop    %ebp
8010060a:	c3                   	ret    

8010060b <cprintf>:
{
8010060b:	55                   	push   %ebp
8010060c:	89 e5                	mov    %esp,%ebp
8010060e:	57                   	push   %edi
8010060f:	56                   	push   %esi
80100610:	53                   	push   %ebx
80100611:	83 ec 1c             	sub    $0x1c,%esp
  locking = cons.locking;
80100614:	a1 54 95 10 80       	mov    0x80109554,%eax
80100619:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  if(locking)
8010061c:	85 c0                	test   %eax,%eax
8010061e:	75 10                	jne    80100630 <cprintf+0x25>
  if (fmt == 0)
80100620:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80100624:	74 1c                	je     80100642 <cprintf+0x37>
  argp = (uint*)(void*)(&fmt + 1);
80100626:	8d 7d 0c             	lea    0xc(%ebp),%edi
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100629:	bb 00 00 00 00       	mov    $0x0,%ebx
8010062e:	eb 27                	jmp    80100657 <cprintf+0x4c>
    acquire(&cons.lock);
80100630:	83 ec 0c             	sub    $0xc,%esp
80100633:	68 20 95 10 80       	push   $0x80109520
80100638:	e8 9f 36 00 00       	call   80103cdc <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 5f 66 10 80       	push   $0x8010665f
8010064a:	e8 f9 fc ff ff       	call   80100348 <panic>
      consputc(c);
8010064f:	e8 92 fe ff ff       	call   801004e6 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100654:	83 c3 01             	add    $0x1,%ebx
80100657:	8b 55 08             	mov    0x8(%ebp),%edx
8010065a:	0f b6 04 1a          	movzbl (%edx,%ebx,1),%eax
8010065e:	85 c0                	test   %eax,%eax
80100660:	0f 84 b8 00 00 00    	je     8010071e <cprintf+0x113>
    if(c != '%'){
80100666:	83 f8 25             	cmp    $0x25,%eax
80100669:	75 e4                	jne    8010064f <cprintf+0x44>
    c = fmt[++i] & 0xff;
8010066b:	83 c3 01             	add    $0x1,%ebx
8010066e:	0f b6 34 1a          	movzbl (%edx,%ebx,1),%esi
    if(c == 0)
80100672:	85 f6                	test   %esi,%esi
80100674:	0f 84 a4 00 00 00    	je     8010071e <cprintf+0x113>
    switch(c){
8010067a:	83 fe 70             	cmp    $0x70,%esi
8010067d:	74 48                	je     801006c7 <cprintf+0xbc>
8010067f:	83 fe 70             	cmp    $0x70,%esi
80100682:	7f 26                	jg     801006aa <cprintf+0x9f>
80100684:	83 fe 25             	cmp    $0x25,%esi
80100687:	0f 84 82 00 00 00    	je     8010070f <cprintf+0x104>
8010068d:	83 fe 64             	cmp    $0x64,%esi
80100690:	75 22                	jne    801006b4 <cprintf+0xa9>
      printint(*argp++, 10, 1);
80100692:	8d 77 04             	lea    0x4(%edi),%esi
80100695:	8b 07                	mov    (%edi),%eax
80100697:	b9 01 00 00 00       	mov    $0x1,%ecx
8010069c:	ba 0a 00 00 00       	mov    $0xa,%edx
801006a1:	e8 9b fe ff ff       	call   80100541 <printint>
801006a6:	89 f7                	mov    %esi,%edi
      break;
801006a8:	eb aa                	jmp    80100654 <cprintf+0x49>
    switch(c){
801006aa:	83 fe 73             	cmp    $0x73,%esi
801006ad:	74 33                	je     801006e2 <cprintf+0xd7>
801006af:	83 fe 78             	cmp    $0x78,%esi
801006b2:	74 13                	je     801006c7 <cprintf+0xbc>
      consputc('%');
801006b4:	b8 25 00 00 00       	mov    $0x25,%eax
801006b9:	e8 28 fe ff ff       	call   801004e6 <consputc>
      consputc(c);
801006be:	89 f0                	mov    %esi,%eax
801006c0:	e8 21 fe ff ff       	call   801004e6 <consputc>
      break;
801006c5:	eb 8d                	jmp    80100654 <cprintf+0x49>
      printint(*argp++, 16, 0);
801006c7:	8d 77 04             	lea    0x4(%edi),%esi
801006ca:	8b 07                	mov    (%edi),%eax
801006cc:	b9 00 00 00 00       	mov    $0x0,%ecx
801006d1:	ba 10 00 00 00       	mov    $0x10,%edx
801006d6:	e8 66 fe ff ff       	call   80100541 <printint>
801006db:	89 f7                	mov    %esi,%edi
      break;
801006dd:	e9 72 ff ff ff       	jmp    80100654 <cprintf+0x49>
      if((s = (char*)*argp++) == 0)
801006e2:	8d 47 04             	lea    0x4(%edi),%eax
801006e5:	89 45 e0             	mov    %eax,-0x20(%ebp)
801006e8:	8b 37                	mov    (%edi),%esi
801006ea:	85 f6                	test   %esi,%esi
801006ec:	75 12                	jne    80100700 <cprintf+0xf5>
        s = "(null)";
801006ee:	be 58 66 10 80       	mov    $0x80106658,%esi
801006f3:	eb 0b                	jmp    80100700 <cprintf+0xf5>
        consputc(*s);
801006f5:	0f be c0             	movsbl %al,%eax
801006f8:	e8 e9 fd ff ff       	call   801004e6 <consputc>
      for(; *s; s++)
801006fd:	83 c6 01             	add    $0x1,%esi
80100700:	0f b6 06             	movzbl (%esi),%eax
80100703:	84 c0                	test   %al,%al
80100705:	75 ee                	jne    801006f5 <cprintf+0xea>
      if((s = (char*)*argp++) == 0)
80100707:	8b 7d e0             	mov    -0x20(%ebp),%edi
8010070a:	e9 45 ff ff ff       	jmp    80100654 <cprintf+0x49>
      consputc('%');
8010070f:	b8 25 00 00 00       	mov    $0x25,%eax
80100714:	e8 cd fd ff ff       	call   801004e6 <consputc>
      break;
80100719:	e9 36 ff ff ff       	jmp    80100654 <cprintf+0x49>
  if(locking)
8010071e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100722:	75 08                	jne    8010072c <cprintf+0x121>
}
80100724:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100727:	5b                   	pop    %ebx
80100728:	5e                   	pop    %esi
80100729:	5f                   	pop    %edi
8010072a:	5d                   	pop    %ebp
8010072b:	c3                   	ret    
    release(&cons.lock);
8010072c:	83 ec 0c             	sub    $0xc,%esp
8010072f:	68 20 95 10 80       	push   $0x80109520
80100734:	e8 08 36 00 00       	call   80103d41 <release>
80100739:	83 c4 10             	add    $0x10,%esp
}
8010073c:	eb e6                	jmp    80100724 <cprintf+0x119>

8010073e <consoleintr>:
{
8010073e:	55                   	push   %ebp
8010073f:	89 e5                	mov    %esp,%ebp
80100741:	57                   	push   %edi
80100742:	56                   	push   %esi
80100743:	53                   	push   %ebx
80100744:	83 ec 18             	sub    $0x18,%esp
80100747:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&cons.lock);
8010074a:	68 20 95 10 80       	push   $0x80109520
8010074f:	e8 88 35 00 00       	call   80103cdc <acquire>
  while((c = getc()) >= 0){
80100754:	83 c4 10             	add    $0x10,%esp
  int c, doprocdump = 0;
80100757:	be 00 00 00 00       	mov    $0x0,%esi
  while((c = getc()) >= 0){
8010075c:	e9 c5 00 00 00       	jmp    80100826 <consoleintr+0xe8>
    switch(c){
80100761:	83 ff 08             	cmp    $0x8,%edi
80100764:	0f 84 e0 00 00 00    	je     8010084a <consoleintr+0x10c>
      if(c != 0 && input.e-input.r < INPUT_BUF){
8010076a:	85 ff                	test   %edi,%edi
8010076c:	0f 84 b4 00 00 00    	je     80100826 <consoleintr+0xe8>
80100772:	a1 c8 ef 10 80       	mov    0x8010efc8,%eax
80100777:	89 c2                	mov    %eax,%edx
80100779:	2b 15 c0 ef 10 80    	sub    0x8010efc0,%edx
8010077f:	83 fa 7f             	cmp    $0x7f,%edx
80100782:	0f 87 9e 00 00 00    	ja     80100826 <consoleintr+0xe8>
        c = (c == '\r') ? '\n' : c;
80100788:	83 ff 0d             	cmp    $0xd,%edi
8010078b:	0f 84 86 00 00 00    	je     80100817 <consoleintr+0xd9>
        input.buf[input.e++ % INPUT_BUF] = c;
80100791:	8d 50 01             	lea    0x1(%eax),%edx
80100794:	89 15 c8 ef 10 80    	mov    %edx,0x8010efc8
8010079a:	83 e0 7f             	and    $0x7f,%eax
8010079d:	89 f9                	mov    %edi,%ecx
8010079f:	88 88 40 ef 10 80    	mov    %cl,-0x7fef10c0(%eax)
        consputc(c);
801007a5:	89 f8                	mov    %edi,%eax
801007a7:	e8 3a fd ff ff       	call   801004e6 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801007ac:	83 ff 0a             	cmp    $0xa,%edi
801007af:	0f 94 c2             	sete   %dl
801007b2:	83 ff 04             	cmp    $0x4,%edi
801007b5:	0f 94 c0             	sete   %al
801007b8:	08 c2                	or     %al,%dl
801007ba:	75 10                	jne    801007cc <consoleintr+0x8e>
801007bc:	a1 c0 ef 10 80       	mov    0x8010efc0,%eax
801007c1:	83 e8 80             	sub    $0xffffff80,%eax
801007c4:	39 05 c8 ef 10 80    	cmp    %eax,0x8010efc8
801007ca:	75 5a                	jne    80100826 <consoleintr+0xe8>
          input.w = input.e;
801007cc:	a1 c8 ef 10 80       	mov    0x8010efc8,%eax
801007d1:	a3 c4 ef 10 80       	mov    %eax,0x8010efc4
          wakeup(&input.r);
801007d6:	83 ec 0c             	sub    $0xc,%esp
801007d9:	68 c0 ef 10 80       	push   $0x8010efc0
801007de:	e8 63 31 00 00       	call   80103946 <wakeup>
801007e3:	83 c4 10             	add    $0x10,%esp
801007e6:	eb 3e                	jmp    80100826 <consoleintr+0xe8>
        input.e--;
801007e8:	a3 c8 ef 10 80       	mov    %eax,0x8010efc8
        consputc(BACKSPACE);
801007ed:	b8 00 01 00 00       	mov    $0x100,%eax
801007f2:	e8 ef fc ff ff       	call   801004e6 <consputc>
      while(input.e != input.w &&
801007f7:	a1 c8 ef 10 80       	mov    0x8010efc8,%eax
801007fc:	3b 05 c4 ef 10 80    	cmp    0x8010efc4,%eax
80100802:	74 22                	je     80100826 <consoleintr+0xe8>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100804:	83 e8 01             	sub    $0x1,%eax
80100807:	89 c2                	mov    %eax,%edx
80100809:	83 e2 7f             	and    $0x7f,%edx
      while(input.e != input.w &&
8010080c:	80 ba 40 ef 10 80 0a 	cmpb   $0xa,-0x7fef10c0(%edx)
80100813:	75 d3                	jne    801007e8 <consoleintr+0xaa>
80100815:	eb 0f                	jmp    80100826 <consoleintr+0xe8>
        c = (c == '\r') ? '\n' : c;
80100817:	bf 0a 00 00 00       	mov    $0xa,%edi
8010081c:	e9 70 ff ff ff       	jmp    80100791 <consoleintr+0x53>
      doprocdump = 1;
80100821:	be 01 00 00 00       	mov    $0x1,%esi
  while((c = getc()) >= 0){
80100826:	ff d3                	call   *%ebx
80100828:	89 c7                	mov    %eax,%edi
8010082a:	85 c0                	test   %eax,%eax
8010082c:	78 3d                	js     8010086b <consoleintr+0x12d>
    switch(c){
8010082e:	83 ff 10             	cmp    $0x10,%edi
80100831:	74 ee                	je     80100821 <consoleintr+0xe3>
80100833:	83 ff 10             	cmp    $0x10,%edi
80100836:	0f 8e 25 ff ff ff    	jle    80100761 <consoleintr+0x23>
8010083c:	83 ff 15             	cmp    $0x15,%edi
8010083f:	74 b6                	je     801007f7 <consoleintr+0xb9>
80100841:	83 ff 7f             	cmp    $0x7f,%edi
80100844:	0f 85 20 ff ff ff    	jne    8010076a <consoleintr+0x2c>
      if(input.e != input.w){
8010084a:	a1 c8 ef 10 80       	mov    0x8010efc8,%eax
8010084f:	3b 05 c4 ef 10 80    	cmp    0x8010efc4,%eax
80100855:	74 cf                	je     80100826 <consoleintr+0xe8>
        input.e--;
80100857:	83 e8 01             	sub    $0x1,%eax
8010085a:	a3 c8 ef 10 80       	mov    %eax,0x8010efc8
        consputc(BACKSPACE);
8010085f:	b8 00 01 00 00       	mov    $0x100,%eax
80100864:	e8 7d fc ff ff       	call   801004e6 <consputc>
80100869:	eb bb                	jmp    80100826 <consoleintr+0xe8>
  release(&cons.lock);
8010086b:	83 ec 0c             	sub    $0xc,%esp
8010086e:	68 20 95 10 80       	push   $0x80109520
80100873:	e8 c9 34 00 00       	call   80103d41 <release>
  if(doprocdump) {
80100878:	83 c4 10             	add    $0x10,%esp
8010087b:	85 f6                	test   %esi,%esi
8010087d:	75 08                	jne    80100887 <consoleintr+0x149>
}
8010087f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100882:	5b                   	pop    %ebx
80100883:	5e                   	pop    %esi
80100884:	5f                   	pop    %edi
80100885:	5d                   	pop    %ebp
80100886:	c3                   	ret    
    procdump();  // now call procdump() wo. cons.lock held
80100887:	e8 57 31 00 00       	call   801039e3 <procdump>
}
8010088c:	eb f1                	jmp    8010087f <consoleintr+0x141>

8010088e <consoleinit>:

void
consoleinit(void)
{
8010088e:	55                   	push   %ebp
8010088f:	89 e5                	mov    %esp,%ebp
80100891:	83 ec 10             	sub    $0x10,%esp
  initlock(&cons.lock, "console");
80100894:	68 68 66 10 80       	push   $0x80106668
80100899:	68 20 95 10 80       	push   $0x80109520
8010089e:	e8 fd 32 00 00       	call   80103ba0 <initlock>

  devsw[CONSOLE].write = consolewrite;
801008a3:	c7 05 8c f9 10 80 ac 	movl   $0x801005ac,0x8010f98c
801008aa:	05 10 80 
  devsw[CONSOLE].read = consoleread;
801008ad:	c7 05 88 f9 10 80 68 	movl   $0x80100268,0x8010f988
801008b4:	02 10 80 
  cons.locking = 1;
801008b7:	c7 05 54 95 10 80 01 	movl   $0x1,0x80109554
801008be:	00 00 00 

  ioapicenable(IRQ_KBD, 0);
801008c1:	83 c4 08             	add    $0x8,%esp
801008c4:	6a 00                	push   $0x0
801008c6:	6a 01                	push   $0x1
801008c8:	e8 b1 16 00 00       	call   80101f7e <ioapicenable>
}
801008cd:	83 c4 10             	add    $0x10,%esp
801008d0:	c9                   	leave  
801008d1:	c3                   	ret    

801008d2 <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
801008d2:	55                   	push   %ebp
801008d3:	89 e5                	mov    %esp,%ebp
801008d5:	57                   	push   %edi
801008d6:	56                   	push   %esi
801008d7:	53                   	push   %ebx
801008d8:	81 ec 0c 01 00 00    	sub    $0x10c,%esp
  uint argc, sz, sp, ustack[3+MAXARG+1];
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;
  struct proc *curproc = myproc();
801008de:	e8 5a 2a 00 00       	call   8010333d <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 ff 1f 00 00       	call   801028ed <begin_op>

  if((ip = namei(path)) == 0){
801008ee:	83 ec 0c             	sub    $0xc,%esp
801008f1:	ff 75 08             	pushl  0x8(%ebp)
801008f4:	e8 e8 12 00 00       	call   80101be1 <namei>
801008f9:	83 c4 10             	add    $0x10,%esp
801008fc:	85 c0                	test   %eax,%eax
801008fe:	74 4a                	je     8010094a <exec+0x78>
80100900:	89 c3                	mov    %eax,%ebx
    end_op();
    cprintf("exec: fail\n");
    return -1;
  }
  ilock(ip);
80100902:	83 ec 0c             	sub    $0xc,%esp
80100905:	50                   	push   %eax
80100906:	e8 76 0c 00 00       	call   80101581 <ilock>
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
8010090b:	6a 34                	push   $0x34
8010090d:	6a 00                	push   $0x0
8010090f:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
80100915:	50                   	push   %eax
80100916:	53                   	push   %ebx
80100917:	e8 57 0e 00 00       	call   80101773 <readi>
8010091c:	83 c4 20             	add    $0x20,%esp
8010091f:	83 f8 34             	cmp    $0x34,%eax
80100922:	74 42                	je     80100966 <exec+0x94>
  return 0;

 bad:
  if(pgdir)
    freevm(pgdir);
  if(ip){
80100924:	85 db                	test   %ebx,%ebx
80100926:	0f 84 dd 02 00 00    	je     80100c09 <exec+0x337>
    iunlockput(ip);
8010092c:	83 ec 0c             	sub    $0xc,%esp
8010092f:	53                   	push   %ebx
80100930:	e8 f3 0d 00 00       	call   80101728 <iunlockput>
    end_op();
80100935:	e8 2d 20 00 00       	call   80102967 <end_op>
8010093a:	83 c4 10             	add    $0x10,%esp
  }
  return -1;
8010093d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100942:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100945:	5b                   	pop    %ebx
80100946:	5e                   	pop    %esi
80100947:	5f                   	pop    %edi
80100948:	5d                   	pop    %ebp
80100949:	c3                   	ret    
    end_op();
8010094a:	e8 18 20 00 00       	call   80102967 <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 81 66 10 80       	push   $0x80106681
80100957:	e8 af fc ff ff       	call   8010060b <cprintf>
    return -1;
8010095c:	83 c4 10             	add    $0x10,%esp
8010095f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100964:	eb dc                	jmp    80100942 <exec+0x70>
  if(elf.magic != ELF_MAGIC)
80100966:	81 bd 24 ff ff ff 7f 	cmpl   $0x464c457f,-0xdc(%ebp)
8010096d:	45 4c 46 
80100970:	75 b2                	jne    80100924 <exec+0x52>
  if((pgdir = setupkvm()) == 0)
80100972:	e8 26 5a 00 00       	call   8010639d <setupkvm>
80100977:	89 85 ec fe ff ff    	mov    %eax,-0x114(%ebp)
8010097d:	85 c0                	test   %eax,%eax
8010097f:	0f 84 06 01 00 00    	je     80100a8b <exec+0x1b9>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100985:	8b 85 40 ff ff ff    	mov    -0xc0(%ebp),%eax
  sz = 0;
8010098b:	bf 00 00 00 00       	mov    $0x0,%edi
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100990:	be 00 00 00 00       	mov    $0x0,%esi
80100995:	eb 0c                	jmp    801009a3 <exec+0xd1>
80100997:	83 c6 01             	add    $0x1,%esi
8010099a:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
801009a0:	83 c0 20             	add    $0x20,%eax
801009a3:	0f b7 95 50 ff ff ff 	movzwl -0xb0(%ebp),%edx
801009aa:	39 f2                	cmp    %esi,%edx
801009ac:	0f 8e 98 00 00 00    	jle    80100a4a <exec+0x178>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
801009b2:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
801009b8:	6a 20                	push   $0x20
801009ba:	50                   	push   %eax
801009bb:	8d 85 04 ff ff ff    	lea    -0xfc(%ebp),%eax
801009c1:	50                   	push   %eax
801009c2:	53                   	push   %ebx
801009c3:	e8 ab 0d 00 00       	call   80101773 <readi>
801009c8:	83 c4 10             	add    $0x10,%esp
801009cb:	83 f8 20             	cmp    $0x20,%eax
801009ce:	0f 85 b7 00 00 00    	jne    80100a8b <exec+0x1b9>
    if(ph.type != ELF_PROG_LOAD)
801009d4:	83 bd 04 ff ff ff 01 	cmpl   $0x1,-0xfc(%ebp)
801009db:	75 ba                	jne    80100997 <exec+0xc5>
    if(ph.memsz < ph.filesz)
801009dd:	8b 85 18 ff ff ff    	mov    -0xe8(%ebp),%eax
801009e3:	3b 85 14 ff ff ff    	cmp    -0xec(%ebp),%eax
801009e9:	0f 82 9c 00 00 00    	jb     80100a8b <exec+0x1b9>
    if(ph.vaddr + ph.memsz < ph.vaddr)
801009ef:	03 85 0c ff ff ff    	add    -0xf4(%ebp),%eax
801009f5:	0f 82 90 00 00 00    	jb     80100a8b <exec+0x1b9>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
801009fb:	83 ec 04             	sub    $0x4,%esp
801009fe:	50                   	push   %eax
801009ff:	57                   	push   %edi
80100a00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a06:	e8 2a 58 00 00       	call   80106235 <allocuvm>
80100a0b:	89 c7                	mov    %eax,%edi
80100a0d:	83 c4 10             	add    $0x10,%esp
80100a10:	85 c0                	test   %eax,%eax
80100a12:	74 77                	je     80100a8b <exec+0x1b9>
    if(ph.vaddr % PGSIZE != 0)
80100a14:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100a1a:	a9 ff 0f 00 00       	test   $0xfff,%eax
80100a1f:	75 6a                	jne    80100a8b <exec+0x1b9>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100a21:	83 ec 0c             	sub    $0xc,%esp
80100a24:	ff b5 14 ff ff ff    	pushl  -0xec(%ebp)
80100a2a:	ff b5 08 ff ff ff    	pushl  -0xf8(%ebp)
80100a30:	53                   	push   %ebx
80100a31:	50                   	push   %eax
80100a32:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a38:	e8 c6 56 00 00       	call   80106103 <loaduvm>
80100a3d:	83 c4 20             	add    $0x20,%esp
80100a40:	85 c0                	test   %eax,%eax
80100a42:	0f 89 4f ff ff ff    	jns    80100997 <exec+0xc5>
 bad:
80100a48:	eb 41                	jmp    80100a8b <exec+0x1b9>
  iunlockput(ip);
80100a4a:	83 ec 0c             	sub    $0xc,%esp
80100a4d:	53                   	push   %ebx
80100a4e:	e8 d5 0c 00 00       	call   80101728 <iunlockput>
  end_op();
80100a53:	e8 0f 1f 00 00       	call   80102967 <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 bc 57 00 00       	call   80106235 <allocuvm>
80100a79:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
80100a7f:	83 c4 10             	add    $0x10,%esp
80100a82:	85 c0                	test   %eax,%eax
80100a84:	75 24                	jne    80100aaa <exec+0x1d8>
  ip = 0;
80100a86:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(pgdir)
80100a8b:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100a91:	85 c0                	test   %eax,%eax
80100a93:	0f 84 8b fe ff ff    	je     80100924 <exec+0x52>
    freevm(pgdir);
80100a99:	83 ec 0c             	sub    $0xc,%esp
80100a9c:	50                   	push   %eax
80100a9d:	e8 8b 58 00 00       	call   8010632d <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 69 59 00 00       	call   8010642a <clearpteu>
  for(argc = 0; argv[argc]; argc++) {
80100ac1:	83 c4 10             	add    $0x10,%esp
80100ac4:	bb 00 00 00 00       	mov    $0x0,%ebx
80100ac9:	8b 45 0c             	mov    0xc(%ebp),%eax
80100acc:	8d 34 98             	lea    (%eax,%ebx,4),%esi
80100acf:	8b 06                	mov    (%esi),%eax
80100ad1:	85 c0                	test   %eax,%eax
80100ad3:	74 4d                	je     80100b22 <exec+0x250>
    if(argc >= MAXARG)
80100ad5:	83 fb 1f             	cmp    $0x1f,%ebx
80100ad8:	0f 87 0d 01 00 00    	ja     80100beb <exec+0x319>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100ade:	83 ec 0c             	sub    $0xc,%esp
80100ae1:	50                   	push   %eax
80100ae2:	e8 43 34 00 00       	call   80103f2a <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 31 34 00 00       	call   80103f2a <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 6d 5a 00 00       	call   80106578 <copyout>
80100b0b:	83 c4 20             	add    $0x20,%esp
80100b0e:	85 c0                	test   %eax,%eax
80100b10:	0f 88 df 00 00 00    	js     80100bf5 <exec+0x323>
    ustack[3+argc] = sp;
80100b16:	89 bc 9d 64 ff ff ff 	mov    %edi,-0x9c(%ebp,%ebx,4)
  for(argc = 0; argv[argc]; argc++) {
80100b1d:	83 c3 01             	add    $0x1,%ebx
80100b20:	eb a7                	jmp    80100ac9 <exec+0x1f7>
  ustack[3+argc] = 0;
80100b22:	c7 84 9d 64 ff ff ff 	movl   $0x0,-0x9c(%ebp,%ebx,4)
80100b29:	00 00 00 00 
  ustack[0] = 0xffffffff;  // fake return PC
80100b2d:	c7 85 58 ff ff ff ff 	movl   $0xffffffff,-0xa8(%ebp)
80100b34:	ff ff ff 
  ustack[1] = argc;
80100b37:	89 9d 5c ff ff ff    	mov    %ebx,-0xa4(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100b3d:	8d 04 9d 04 00 00 00 	lea    0x4(,%ebx,4),%eax
80100b44:	89 f9                	mov    %edi,%ecx
80100b46:	29 c1                	sub    %eax,%ecx
80100b48:	89 8d 60 ff ff ff    	mov    %ecx,-0xa0(%ebp)
  sp -= (3+argc+1) * 4;
80100b4e:	8d 04 9d 10 00 00 00 	lea    0x10(,%ebx,4),%eax
80100b55:	29 c7                	sub    %eax,%edi
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100b57:	50                   	push   %eax
80100b58:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
80100b5e:	50                   	push   %eax
80100b5f:	57                   	push   %edi
80100b60:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b66:	e8 0d 5a 00 00       	call   80106578 <copyout>
80100b6b:	83 c4 10             	add    $0x10,%esp
80100b6e:	85 c0                	test   %eax,%eax
80100b70:	0f 88 89 00 00 00    	js     80100bff <exec+0x32d>
  for(last=s=path; *s; s++)
80100b76:	8b 55 08             	mov    0x8(%ebp),%edx
80100b79:	89 d0                	mov    %edx,%eax
80100b7b:	eb 03                	jmp    80100b80 <exec+0x2ae>
80100b7d:	83 c0 01             	add    $0x1,%eax
80100b80:	0f b6 08             	movzbl (%eax),%ecx
80100b83:	84 c9                	test   %cl,%cl
80100b85:	74 0a                	je     80100b91 <exec+0x2bf>
    if(*s == '/')
80100b87:	80 f9 2f             	cmp    $0x2f,%cl
80100b8a:	75 f1                	jne    80100b7d <exec+0x2ab>
      last = s+1;
80100b8c:	8d 50 01             	lea    0x1(%eax),%edx
80100b8f:	eb ec                	jmp    80100b7d <exec+0x2ab>
  safestrcpy(curproc->name, last, sizeof(curproc->name));
80100b91:	8b b5 f4 fe ff ff    	mov    -0x10c(%ebp),%esi
80100b97:	89 f0                	mov    %esi,%eax
80100b99:	83 c0 6c             	add    $0x6c,%eax
80100b9c:	83 ec 04             	sub    $0x4,%esp
80100b9f:	6a 10                	push   $0x10
80100ba1:	52                   	push   %edx
80100ba2:	50                   	push   %eax
80100ba3:	e8 47 33 00 00       	call   80103eef <safestrcpy>
  oldpgdir = curproc->pgdir;
80100ba8:	8b 5e 04             	mov    0x4(%esi),%ebx
  curproc->pgdir = pgdir;
80100bab:	8b 8d ec fe ff ff    	mov    -0x114(%ebp),%ecx
80100bb1:	89 4e 04             	mov    %ecx,0x4(%esi)
  curproc->sz = sz;
80100bb4:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100bba:	89 0e                	mov    %ecx,(%esi)
  curproc->tf->eip = elf.entry;  // main
80100bbc:	8b 46 18             	mov    0x18(%esi),%eax
80100bbf:	8b 95 3c ff ff ff    	mov    -0xc4(%ebp),%edx
80100bc5:	89 50 38             	mov    %edx,0x38(%eax)
  curproc->tf->esp = sp;
80100bc8:	8b 46 18             	mov    0x18(%esi),%eax
80100bcb:	89 78 44             	mov    %edi,0x44(%eax)
  switchuvm(curproc);
80100bce:	89 34 24             	mov    %esi,(%esp)
80100bd1:	e8 a7 53 00 00       	call   80105f7d <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 4f 57 00 00       	call   8010632d <freevm>
  return 0;
80100bde:	83 c4 10             	add    $0x10,%esp
80100be1:	b8 00 00 00 00       	mov    $0x0,%eax
80100be6:	e9 57 fd ff ff       	jmp    80100942 <exec+0x70>
  ip = 0;
80100beb:	bb 00 00 00 00       	mov    $0x0,%ebx
80100bf0:	e9 96 fe ff ff       	jmp    80100a8b <exec+0x1b9>
80100bf5:	bb 00 00 00 00       	mov    $0x0,%ebx
80100bfa:	e9 8c fe ff ff       	jmp    80100a8b <exec+0x1b9>
80100bff:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c04:	e9 82 fe ff ff       	jmp    80100a8b <exec+0x1b9>
  return -1;
80100c09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100c0e:	e9 2f fd ff ff       	jmp    80100942 <exec+0x70>

80100c13 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100c13:	55                   	push   %ebp
80100c14:	89 e5                	mov    %esp,%ebp
80100c16:	83 ec 10             	sub    $0x10,%esp
  initlock(&ftable.lock, "ftable");
80100c19:	68 8d 66 10 80       	push   $0x8010668d
80100c1e:	68 e0 ef 10 80       	push   $0x8010efe0
80100c23:	e8 78 2f 00 00       	call   80103ba0 <initlock>
}
80100c28:	83 c4 10             	add    $0x10,%esp
80100c2b:	c9                   	leave  
80100c2c:	c3                   	ret    

80100c2d <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100c2d:	55                   	push   %ebp
80100c2e:	89 e5                	mov    %esp,%ebp
80100c30:	53                   	push   %ebx
80100c31:	83 ec 10             	sub    $0x10,%esp
  struct file *f;

  acquire(&ftable.lock);
80100c34:	68 e0 ef 10 80       	push   $0x8010efe0
80100c39:	e8 9e 30 00 00       	call   80103cdc <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c3e:	83 c4 10             	add    $0x10,%esp
80100c41:	bb 14 f0 10 80       	mov    $0x8010f014,%ebx
80100c46:	81 fb 74 f9 10 80    	cmp    $0x8010f974,%ebx
80100c4c:	73 29                	jae    80100c77 <filealloc+0x4a>
    if(f->ref == 0){
80100c4e:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80100c52:	74 05                	je     80100c59 <filealloc+0x2c>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c54:	83 c3 18             	add    $0x18,%ebx
80100c57:	eb ed                	jmp    80100c46 <filealloc+0x19>
      f->ref = 1;
80100c59:	c7 43 04 01 00 00 00 	movl   $0x1,0x4(%ebx)
      release(&ftable.lock);
80100c60:	83 ec 0c             	sub    $0xc,%esp
80100c63:	68 e0 ef 10 80       	push   $0x8010efe0
80100c68:	e8 d4 30 00 00       	call   80103d41 <release>
      return f;
80100c6d:	83 c4 10             	add    $0x10,%esp
    }
  }
  release(&ftable.lock);
  return 0;
}
80100c70:	89 d8                	mov    %ebx,%eax
80100c72:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100c75:	c9                   	leave  
80100c76:	c3                   	ret    
  release(&ftable.lock);
80100c77:	83 ec 0c             	sub    $0xc,%esp
80100c7a:	68 e0 ef 10 80       	push   $0x8010efe0
80100c7f:	e8 bd 30 00 00       	call   80103d41 <release>
  return 0;
80100c84:	83 c4 10             	add    $0x10,%esp
80100c87:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c8c:	eb e2                	jmp    80100c70 <filealloc+0x43>

80100c8e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100c8e:	55                   	push   %ebp
80100c8f:	89 e5                	mov    %esp,%ebp
80100c91:	53                   	push   %ebx
80100c92:	83 ec 10             	sub    $0x10,%esp
80100c95:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&ftable.lock);
80100c98:	68 e0 ef 10 80       	push   $0x8010efe0
80100c9d:	e8 3a 30 00 00       	call   80103cdc <acquire>
  if(f->ref < 1)
80100ca2:	8b 43 04             	mov    0x4(%ebx),%eax
80100ca5:	83 c4 10             	add    $0x10,%esp
80100ca8:	85 c0                	test   %eax,%eax
80100caa:	7e 1a                	jle    80100cc6 <filedup+0x38>
    panic("filedup");
  f->ref++;
80100cac:	83 c0 01             	add    $0x1,%eax
80100caf:	89 43 04             	mov    %eax,0x4(%ebx)
  release(&ftable.lock);
80100cb2:	83 ec 0c             	sub    $0xc,%esp
80100cb5:	68 e0 ef 10 80       	push   $0x8010efe0
80100cba:	e8 82 30 00 00       	call   80103d41 <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 94 66 10 80       	push   $0x80106694
80100cce:	e8 75 f6 ff ff       	call   80100348 <panic>

80100cd3 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100cd3:	55                   	push   %ebp
80100cd4:	89 e5                	mov    %esp,%ebp
80100cd6:	53                   	push   %ebx
80100cd7:	83 ec 30             	sub    $0x30,%esp
80100cda:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct file ff;

  acquire(&ftable.lock);
80100cdd:	68 e0 ef 10 80       	push   $0x8010efe0
80100ce2:	e8 f5 2f 00 00       	call   80103cdc <acquire>
  if(f->ref < 1)
80100ce7:	8b 43 04             	mov    0x4(%ebx),%eax
80100cea:	83 c4 10             	add    $0x10,%esp
80100ced:	85 c0                	test   %eax,%eax
80100cef:	7e 1f                	jle    80100d10 <fileclose+0x3d>
    panic("fileclose");
  if(--f->ref > 0){
80100cf1:	83 e8 01             	sub    $0x1,%eax
80100cf4:	89 43 04             	mov    %eax,0x4(%ebx)
80100cf7:	85 c0                	test   %eax,%eax
80100cf9:	7e 22                	jle    80100d1d <fileclose+0x4a>
    release(&ftable.lock);
80100cfb:	83 ec 0c             	sub    $0xc,%esp
80100cfe:	68 e0 ef 10 80       	push   $0x8010efe0
80100d03:	e8 39 30 00 00       	call   80103d41 <release>
    return;
80100d08:	83 c4 10             	add    $0x10,%esp
  else if(ff.type == FD_INODE){
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
80100d0b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100d0e:	c9                   	leave  
80100d0f:	c3                   	ret    
    panic("fileclose");
80100d10:	83 ec 0c             	sub    $0xc,%esp
80100d13:	68 9c 66 10 80       	push   $0x8010669c
80100d18:	e8 2b f6 ff ff       	call   80100348 <panic>
  ff = *f;
80100d1d:	8b 03                	mov    (%ebx),%eax
80100d1f:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d22:	8b 43 08             	mov    0x8(%ebx),%eax
80100d25:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d28:	8b 43 0c             	mov    0xc(%ebx),%eax
80100d2b:	89 45 ec             	mov    %eax,-0x14(%ebp)
80100d2e:	8b 43 10             	mov    0x10(%ebx),%eax
80100d31:	89 45 f0             	mov    %eax,-0x10(%ebp)
  f->ref = 0;
80100d34:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
  f->type = FD_NONE;
80100d3b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  release(&ftable.lock);
80100d41:	83 ec 0c             	sub    $0xc,%esp
80100d44:	68 e0 ef 10 80       	push   $0x8010efe0
80100d49:	e8 f3 2f 00 00       	call   80103d41 <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 8a 1b 00 00       	call   801028ed <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 f4 1b 00 00       	call   80102967 <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 e1 21 00 00       	call   80102f69 <pipeclose>
80100d88:	83 c4 10             	add    $0x10,%esp
80100d8b:	e9 7b ff ff ff       	jmp    80100d0b <fileclose+0x38>

80100d90 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80100d90:	55                   	push   %ebp
80100d91:	89 e5                	mov    %esp,%ebp
80100d93:	53                   	push   %ebx
80100d94:	83 ec 04             	sub    $0x4,%esp
80100d97:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(f->type == FD_INODE){
80100d9a:	83 3b 02             	cmpl   $0x2,(%ebx)
80100d9d:	75 31                	jne    80100dd0 <filestat+0x40>
    ilock(f->ip);
80100d9f:	83 ec 0c             	sub    $0xc,%esp
80100da2:	ff 73 10             	pushl  0x10(%ebx)
80100da5:	e8 d7 07 00 00       	call   80101581 <ilock>
    stati(f->ip, st);
80100daa:	83 c4 08             	add    $0x8,%esp
80100dad:	ff 75 0c             	pushl  0xc(%ebp)
80100db0:	ff 73 10             	pushl  0x10(%ebx)
80100db3:	e8 90 09 00 00       	call   80101748 <stati>
    iunlock(f->ip);
80100db8:	83 c4 04             	add    $0x4,%esp
80100dbb:	ff 73 10             	pushl  0x10(%ebx)
80100dbe:	e8 80 08 00 00       	call   80101643 <iunlock>
    return 0;
80100dc3:	83 c4 10             	add    $0x10,%esp
80100dc6:	b8 00 00 00 00       	mov    $0x0,%eax
  }
  return -1;
}
80100dcb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100dce:	c9                   	leave  
80100dcf:	c3                   	ret    
  return -1;
80100dd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100dd5:	eb f4                	jmp    80100dcb <filestat+0x3b>

80100dd7 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80100dd7:	55                   	push   %ebp
80100dd8:	89 e5                	mov    %esp,%ebp
80100dda:	56                   	push   %esi
80100ddb:	53                   	push   %ebx
80100ddc:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->readable == 0)
80100ddf:	80 7b 08 00          	cmpb   $0x0,0x8(%ebx)
80100de3:	74 70                	je     80100e55 <fileread+0x7e>
    return -1;
  if(f->type == FD_PIPE)
80100de5:	8b 03                	mov    (%ebx),%eax
80100de7:	83 f8 01             	cmp    $0x1,%eax
80100dea:	74 44                	je     80100e30 <fileread+0x59>
    return piperead(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100dec:	83 f8 02             	cmp    $0x2,%eax
80100def:	75 57                	jne    80100e48 <fileread+0x71>
    ilock(f->ip);
80100df1:	83 ec 0c             	sub    $0xc,%esp
80100df4:	ff 73 10             	pushl  0x10(%ebx)
80100df7:	e8 85 07 00 00       	call   80101581 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80100dfc:	ff 75 10             	pushl  0x10(%ebp)
80100dff:	ff 73 14             	pushl  0x14(%ebx)
80100e02:	ff 75 0c             	pushl  0xc(%ebp)
80100e05:	ff 73 10             	pushl  0x10(%ebx)
80100e08:	e8 66 09 00 00       	call   80101773 <readi>
80100e0d:	89 c6                	mov    %eax,%esi
80100e0f:	83 c4 20             	add    $0x20,%esp
80100e12:	85 c0                	test   %eax,%eax
80100e14:	7e 03                	jle    80100e19 <fileread+0x42>
      f->off += r;
80100e16:	01 43 14             	add    %eax,0x14(%ebx)
    iunlock(f->ip);
80100e19:	83 ec 0c             	sub    $0xc,%esp
80100e1c:	ff 73 10             	pushl  0x10(%ebx)
80100e1f:	e8 1f 08 00 00       	call   80101643 <iunlock>
    return r;
80100e24:	83 c4 10             	add    $0x10,%esp
  }
  panic("fileread");
}
80100e27:	89 f0                	mov    %esi,%eax
80100e29:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100e2c:	5b                   	pop    %ebx
80100e2d:	5e                   	pop    %esi
80100e2e:	5d                   	pop    %ebp
80100e2f:	c3                   	ret    
    return piperead(f->pipe, addr, n);
80100e30:	83 ec 04             	sub    $0x4,%esp
80100e33:	ff 75 10             	pushl  0x10(%ebp)
80100e36:	ff 75 0c             	pushl  0xc(%ebp)
80100e39:	ff 73 0c             	pushl  0xc(%ebx)
80100e3c:	e8 80 22 00 00       	call   801030c1 <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 a6 66 10 80       	push   $0x801066a6
80100e50:	e8 f3 f4 ff ff       	call   80100348 <panic>
    return -1;
80100e55:	be ff ff ff ff       	mov    $0xffffffff,%esi
80100e5a:	eb cb                	jmp    80100e27 <fileread+0x50>

80100e5c <filewrite>:

// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
80100e5c:	55                   	push   %ebp
80100e5d:	89 e5                	mov    %esp,%ebp
80100e5f:	57                   	push   %edi
80100e60:	56                   	push   %esi
80100e61:	53                   	push   %ebx
80100e62:	83 ec 1c             	sub    $0x1c,%esp
80100e65:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->writable == 0)
80100e68:	80 7b 09 00          	cmpb   $0x0,0x9(%ebx)
80100e6c:	0f 84 c5 00 00 00    	je     80100f37 <filewrite+0xdb>
    return -1;
  if(f->type == FD_PIPE)
80100e72:	8b 03                	mov    (%ebx),%eax
80100e74:	83 f8 01             	cmp    $0x1,%eax
80100e77:	74 10                	je     80100e89 <filewrite+0x2d>
    return pipewrite(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100e79:	83 f8 02             	cmp    $0x2,%eax
80100e7c:	0f 85 a8 00 00 00    	jne    80100f2a <filewrite+0xce>
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * 512;
    int i = 0;
80100e82:	bf 00 00 00 00       	mov    $0x0,%edi
80100e87:	eb 67                	jmp    80100ef0 <filewrite+0x94>
    return pipewrite(f->pipe, addr, n);
80100e89:	83 ec 04             	sub    $0x4,%esp
80100e8c:	ff 75 10             	pushl  0x10(%ebp)
80100e8f:	ff 75 0c             	pushl  0xc(%ebp)
80100e92:	ff 73 0c             	pushl  0xc(%ebx)
80100e95:	e8 5b 21 00 00       	call   80102ff5 <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 46 1a 00 00       	call   801028ed <begin_op>
      ilock(f->ip);
80100ea7:	83 ec 0c             	sub    $0xc,%esp
80100eaa:	ff 73 10             	pushl  0x10(%ebx)
80100ead:	e8 cf 06 00 00       	call   80101581 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80100eb2:	89 f8                	mov    %edi,%eax
80100eb4:	03 45 0c             	add    0xc(%ebp),%eax
80100eb7:	ff 75 e4             	pushl  -0x1c(%ebp)
80100eba:	ff 73 14             	pushl  0x14(%ebx)
80100ebd:	50                   	push   %eax
80100ebe:	ff 73 10             	pushl  0x10(%ebx)
80100ec1:	e8 aa 09 00 00       	call   80101870 <writei>
80100ec6:	89 c6                	mov    %eax,%esi
80100ec8:	83 c4 20             	add    $0x20,%esp
80100ecb:	85 c0                	test   %eax,%eax
80100ecd:	7e 03                	jle    80100ed2 <filewrite+0x76>
        f->off += r;
80100ecf:	01 43 14             	add    %eax,0x14(%ebx)
      iunlock(f->ip);
80100ed2:	83 ec 0c             	sub    $0xc,%esp
80100ed5:	ff 73 10             	pushl  0x10(%ebx)
80100ed8:	e8 66 07 00 00       	call   80101643 <iunlock>
      end_op();
80100edd:	e8 85 1a 00 00       	call   80102967 <end_op>

      if(r < 0)
80100ee2:	83 c4 10             	add    $0x10,%esp
80100ee5:	85 f6                	test   %esi,%esi
80100ee7:	78 31                	js     80100f1a <filewrite+0xbe>
        break;
      if(r != n1)
80100ee9:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
80100eec:	75 1f                	jne    80100f0d <filewrite+0xb1>
        panic("short filewrite");
      i += r;
80100eee:	01 f7                	add    %esi,%edi
    while(i < n){
80100ef0:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100ef3:	7d 25                	jge    80100f1a <filewrite+0xbe>
      int n1 = n - i;
80100ef5:	8b 45 10             	mov    0x10(%ebp),%eax
80100ef8:	29 f8                	sub    %edi,%eax
80100efa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      if(n1 > max)
80100efd:	3d 00 06 00 00       	cmp    $0x600,%eax
80100f02:	7e 9e                	jle    80100ea2 <filewrite+0x46>
        n1 = max;
80100f04:	c7 45 e4 00 06 00 00 	movl   $0x600,-0x1c(%ebp)
80100f0b:	eb 95                	jmp    80100ea2 <filewrite+0x46>
        panic("short filewrite");
80100f0d:	83 ec 0c             	sub    $0xc,%esp
80100f10:	68 af 66 10 80       	push   $0x801066af
80100f15:	e8 2e f4 ff ff       	call   80100348 <panic>
    }
    return i == n ? n : -1;
80100f1a:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100f1d:	75 1f                	jne    80100f3e <filewrite+0xe2>
80100f1f:	8b 45 10             	mov    0x10(%ebp),%eax
  }
  panic("filewrite");
}
80100f22:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100f25:	5b                   	pop    %ebx
80100f26:	5e                   	pop    %esi
80100f27:	5f                   	pop    %edi
80100f28:	5d                   	pop    %ebp
80100f29:	c3                   	ret    
  panic("filewrite");
80100f2a:	83 ec 0c             	sub    $0xc,%esp
80100f2d:	68 b5 66 10 80       	push   $0x801066b5
80100f32:	e8 11 f4 ff ff       	call   80100348 <panic>
    return -1;
80100f37:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f3c:	eb e4                	jmp    80100f22 <filewrite+0xc6>
    return i == n ? n : -1;
80100f3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f43:	eb dd                	jmp    80100f22 <filewrite+0xc6>

80100f45 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80100f45:	55                   	push   %ebp
80100f46:	89 e5                	mov    %esp,%ebp
80100f48:	57                   	push   %edi
80100f49:	56                   	push   %esi
80100f4a:	53                   	push   %ebx
80100f4b:	83 ec 0c             	sub    $0xc,%esp
80100f4e:	89 d7                	mov    %edx,%edi
  char *s;
  int len;

  while(*path == '/')
80100f50:	eb 03                	jmp    80100f55 <skipelem+0x10>
    path++;
80100f52:	83 c0 01             	add    $0x1,%eax
  while(*path == '/')
80100f55:	0f b6 10             	movzbl (%eax),%edx
80100f58:	80 fa 2f             	cmp    $0x2f,%dl
80100f5b:	74 f5                	je     80100f52 <skipelem+0xd>
  if(*path == 0)
80100f5d:	84 d2                	test   %dl,%dl
80100f5f:	74 59                	je     80100fba <skipelem+0x75>
80100f61:	89 c3                	mov    %eax,%ebx
80100f63:	eb 03                	jmp    80100f68 <skipelem+0x23>
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
    path++;
80100f65:	83 c3 01             	add    $0x1,%ebx
  while(*path != '/' && *path != 0)
80100f68:	0f b6 13             	movzbl (%ebx),%edx
80100f6b:	80 fa 2f             	cmp    $0x2f,%dl
80100f6e:	0f 95 c1             	setne  %cl
80100f71:	84 d2                	test   %dl,%dl
80100f73:	0f 95 c2             	setne  %dl
80100f76:	84 d1                	test   %dl,%cl
80100f78:	75 eb                	jne    80100f65 <skipelem+0x20>
  len = path - s;
80100f7a:	89 de                	mov    %ebx,%esi
80100f7c:	29 c6                	sub    %eax,%esi
  if(len >= DIRSIZ)
80100f7e:	83 fe 0d             	cmp    $0xd,%esi
80100f81:	7e 11                	jle    80100f94 <skipelem+0x4f>
    memmove(name, s, DIRSIZ);
80100f83:	83 ec 04             	sub    $0x4,%esp
80100f86:	6a 0e                	push   $0xe
80100f88:	50                   	push   %eax
80100f89:	57                   	push   %edi
80100f8a:	e8 74 2e 00 00       	call   80103e03 <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 64 2e 00 00       	call   80103e03 <memmove>
    name[len] = 0;
80100f9f:	c6 04 37 00          	movb   $0x0,(%edi,%esi,1)
80100fa3:	83 c4 10             	add    $0x10,%esp
80100fa6:	eb 03                	jmp    80100fab <skipelem+0x66>
  }
  while(*path == '/')
    path++;
80100fa8:	83 c3 01             	add    $0x1,%ebx
  while(*path == '/')
80100fab:	80 3b 2f             	cmpb   $0x2f,(%ebx)
80100fae:	74 f8                	je     80100fa8 <skipelem+0x63>
  return path;
}
80100fb0:	89 d8                	mov    %ebx,%eax
80100fb2:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100fb5:	5b                   	pop    %ebx
80100fb6:	5e                   	pop    %esi
80100fb7:	5f                   	pop    %edi
80100fb8:	5d                   	pop    %ebp
80100fb9:	c3                   	ret    
    return 0;
80100fba:	bb 00 00 00 00       	mov    $0x0,%ebx
80100fbf:	eb ef                	jmp    80100fb0 <skipelem+0x6b>

80100fc1 <bzero>:
{
80100fc1:	55                   	push   %ebp
80100fc2:	89 e5                	mov    %esp,%ebp
80100fc4:	53                   	push   %ebx
80100fc5:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, bno);
80100fc8:	52                   	push   %edx
80100fc9:	50                   	push   %eax
80100fca:	e8 9d f1 ff ff       	call   8010016c <bread>
80100fcf:	89 c3                	mov    %eax,%ebx
  memset(bp->data, 0, BSIZE);
80100fd1:	8d 40 5c             	lea    0x5c(%eax),%eax
80100fd4:	83 c4 0c             	add    $0xc,%esp
80100fd7:	68 00 02 00 00       	push   $0x200
80100fdc:	6a 00                	push   $0x0
80100fde:	50                   	push   %eax
80100fdf:	e8 a4 2d 00 00       	call   80103d88 <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 2a 1a 00 00       	call   80102a16 <log_write>
  brelse(bp);
80100fec:	89 1c 24             	mov    %ebx,(%esp)
80100fef:	e8 e1 f1 ff ff       	call   801001d5 <brelse>
}
80100ff4:	83 c4 10             	add    $0x10,%esp
80100ff7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100ffa:	c9                   	leave  
80100ffb:	c3                   	ret    

80100ffc <balloc>:
{
80100ffc:	55                   	push   %ebp
80100ffd:	89 e5                	mov    %esp,%ebp
80100fff:	57                   	push   %edi
80101000:	56                   	push   %esi
80101001:	53                   	push   %ebx
80101002:	83 ec 1c             	sub    $0x1c,%esp
80101005:	89 45 d8             	mov    %eax,-0x28(%ebp)
  for(b = 0; b < sb.size; b += BPB){
80101008:	be 00 00 00 00       	mov    $0x0,%esi
8010100d:	eb 14                	jmp    80101023 <balloc+0x27>
    brelse(bp);
8010100f:	83 ec 0c             	sub    $0xc,%esp
80101012:	ff 75 e4             	pushl  -0x1c(%ebp)
80101015:	e8 bb f1 ff ff       	call   801001d5 <brelse>
  for(b = 0; b < sb.size; b += BPB){
8010101a:	81 c6 00 10 00 00    	add    $0x1000,%esi
80101020:	83 c4 10             	add    $0x10,%esp
80101023:	39 35 e0 f9 10 80    	cmp    %esi,0x8010f9e0
80101029:	76 75                	jbe    801010a0 <balloc+0xa4>
    bp = bread(dev, BBLOCK(b, sb));
8010102b:	8d 86 ff 0f 00 00    	lea    0xfff(%esi),%eax
80101031:	85 f6                	test   %esi,%esi
80101033:	0f 49 c6             	cmovns %esi,%eax
80101036:	c1 f8 0c             	sar    $0xc,%eax
80101039:	03 05 f8 f9 10 80    	add    0x8010f9f8,%eax
8010103f:	83 ec 08             	sub    $0x8,%esp
80101042:	50                   	push   %eax
80101043:	ff 75 d8             	pushl  -0x28(%ebp)
80101046:	e8 21 f1 ff ff       	call   8010016c <bread>
8010104b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010104e:	83 c4 10             	add    $0x10,%esp
80101051:	b8 00 00 00 00       	mov    $0x0,%eax
80101056:	3d ff 0f 00 00       	cmp    $0xfff,%eax
8010105b:	7f b2                	jg     8010100f <balloc+0x13>
8010105d:	8d 1c 06             	lea    (%esi,%eax,1),%ebx
80101060:	89 5d e0             	mov    %ebx,-0x20(%ebp)
80101063:	3b 1d e0 f9 10 80    	cmp    0x8010f9e0,%ebx
80101069:	73 a4                	jae    8010100f <balloc+0x13>
      m = 1 << (bi % 8);
8010106b:	99                   	cltd   
8010106c:	c1 ea 1d             	shr    $0x1d,%edx
8010106f:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80101072:	83 e1 07             	and    $0x7,%ecx
80101075:	29 d1                	sub    %edx,%ecx
80101077:	ba 01 00 00 00       	mov    $0x1,%edx
8010107c:	d3 e2                	shl    %cl,%edx
      if((bp->data[bi/8] & m) == 0){  // Is block free?
8010107e:	8d 48 07             	lea    0x7(%eax),%ecx
80101081:	85 c0                	test   %eax,%eax
80101083:	0f 49 c8             	cmovns %eax,%ecx
80101086:	c1 f9 03             	sar    $0x3,%ecx
80101089:	89 4d dc             	mov    %ecx,-0x24(%ebp)
8010108c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010108f:	0f b6 4c 0f 5c       	movzbl 0x5c(%edi,%ecx,1),%ecx
80101094:	0f b6 f9             	movzbl %cl,%edi
80101097:	85 d7                	test   %edx,%edi
80101099:	74 12                	je     801010ad <balloc+0xb1>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010109b:	83 c0 01             	add    $0x1,%eax
8010109e:	eb b6                	jmp    80101056 <balloc+0x5a>
  panic("balloc: out of blocks");
801010a0:	83 ec 0c             	sub    $0xc,%esp
801010a3:	68 bf 66 10 80       	push   $0x801066bf
801010a8:	e8 9b f2 ff ff       	call   80100348 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
801010ad:	09 ca                	or     %ecx,%edx
801010af:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801010b2:	8b 75 dc             	mov    -0x24(%ebp),%esi
801010b5:	88 54 30 5c          	mov    %dl,0x5c(%eax,%esi,1)
        log_write(bp);
801010b9:	83 ec 0c             	sub    $0xc,%esp
801010bc:	89 c6                	mov    %eax,%esi
801010be:	50                   	push   %eax
801010bf:	e8 52 19 00 00       	call   80102a16 <log_write>
        brelse(bp);
801010c4:	89 34 24             	mov    %esi,(%esp)
801010c7:	e8 09 f1 ff ff       	call   801001d5 <brelse>
        bzero(dev, b + bi);
801010cc:	89 da                	mov    %ebx,%edx
801010ce:	8b 45 d8             	mov    -0x28(%ebp),%eax
801010d1:	e8 eb fe ff ff       	call   80100fc1 <bzero>
}
801010d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010d9:	8d 65 f4             	lea    -0xc(%ebp),%esp
801010dc:	5b                   	pop    %ebx
801010dd:	5e                   	pop    %esi
801010de:	5f                   	pop    %edi
801010df:	5d                   	pop    %ebp
801010e0:	c3                   	ret    

801010e1 <bmap>:
{
801010e1:	55                   	push   %ebp
801010e2:	89 e5                	mov    %esp,%ebp
801010e4:	57                   	push   %edi
801010e5:	56                   	push   %esi
801010e6:	53                   	push   %ebx
801010e7:	83 ec 1c             	sub    $0x1c,%esp
801010ea:	89 c6                	mov    %eax,%esi
801010ec:	89 d7                	mov    %edx,%edi
  if(bn < NDIRECT){
801010ee:	83 fa 0b             	cmp    $0xb,%edx
801010f1:	77 17                	ja     8010110a <bmap+0x29>
    if((addr = ip->addrs[bn]) == 0)
801010f3:	8b 5c 90 5c          	mov    0x5c(%eax,%edx,4),%ebx
801010f7:	85 db                	test   %ebx,%ebx
801010f9:	75 4a                	jne    80101145 <bmap+0x64>
      ip->addrs[bn] = addr = balloc(ip->dev);
801010fb:	8b 00                	mov    (%eax),%eax
801010fd:	e8 fa fe ff ff       	call   80100ffc <balloc>
80101102:	89 c3                	mov    %eax,%ebx
80101104:	89 44 be 5c          	mov    %eax,0x5c(%esi,%edi,4)
80101108:	eb 3b                	jmp    80101145 <bmap+0x64>
  bn -= NDIRECT;
8010110a:	8d 5a f4             	lea    -0xc(%edx),%ebx
  if(bn < NINDIRECT){
8010110d:	83 fb 7f             	cmp    $0x7f,%ebx
80101110:	77 68                	ja     8010117a <bmap+0x99>
    if((addr = ip->addrs[NDIRECT]) == 0)
80101112:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101118:	85 c0                	test   %eax,%eax
8010111a:	74 33                	je     8010114f <bmap+0x6e>
    bp = bread(ip->dev, addr);
8010111c:	83 ec 08             	sub    $0x8,%esp
8010111f:	50                   	push   %eax
80101120:	ff 36                	pushl  (%esi)
80101122:	e8 45 f0 ff ff       	call   8010016c <bread>
80101127:	89 c7                	mov    %eax,%edi
    if((addr = a[bn]) == 0){
80101129:	8d 44 98 5c          	lea    0x5c(%eax,%ebx,4),%eax
8010112d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80101130:	8b 18                	mov    (%eax),%ebx
80101132:	83 c4 10             	add    $0x10,%esp
80101135:	85 db                	test   %ebx,%ebx
80101137:	74 25                	je     8010115e <bmap+0x7d>
    brelse(bp);
80101139:	83 ec 0c             	sub    $0xc,%esp
8010113c:	57                   	push   %edi
8010113d:	e8 93 f0 ff ff       	call   801001d5 <brelse>
    return addr;
80101142:	83 c4 10             	add    $0x10,%esp
}
80101145:	89 d8                	mov    %ebx,%eax
80101147:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010114a:	5b                   	pop    %ebx
8010114b:	5e                   	pop    %esi
8010114c:	5f                   	pop    %edi
8010114d:	5d                   	pop    %ebp
8010114e:	c3                   	ret    
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
8010114f:	8b 06                	mov    (%esi),%eax
80101151:	e8 a6 fe ff ff       	call   80100ffc <balloc>
80101156:	89 86 8c 00 00 00    	mov    %eax,0x8c(%esi)
8010115c:	eb be                	jmp    8010111c <bmap+0x3b>
      a[bn] = addr = balloc(ip->dev);
8010115e:	8b 06                	mov    (%esi),%eax
80101160:	e8 97 fe ff ff       	call   80100ffc <balloc>
80101165:	89 c3                	mov    %eax,%ebx
80101167:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010116a:	89 18                	mov    %ebx,(%eax)
      log_write(bp);
8010116c:	83 ec 0c             	sub    $0xc,%esp
8010116f:	57                   	push   %edi
80101170:	e8 a1 18 00 00       	call   80102a16 <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 d5 66 10 80       	push   $0x801066d5
80101182:	e8 c1 f1 ff ff       	call   80100348 <panic>

80101187 <iget>:
{
80101187:	55                   	push   %ebp
80101188:	89 e5                	mov    %esp,%ebp
8010118a:	57                   	push   %edi
8010118b:	56                   	push   %esi
8010118c:	53                   	push   %ebx
8010118d:	83 ec 28             	sub    $0x28,%esp
80101190:	89 c7                	mov    %eax,%edi
80101192:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  acquire(&icache.lock);
80101195:	68 00 fa 10 80       	push   $0x8010fa00
8010119a:	e8 3d 2b 00 00       	call   80103cdc <acquire>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010119f:	83 c4 10             	add    $0x10,%esp
  empty = 0;
801011a2:	be 00 00 00 00       	mov    $0x0,%esi
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011a7:	bb 34 fa 10 80       	mov    $0x8010fa34,%ebx
801011ac:	eb 0a                	jmp    801011b8 <iget+0x31>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ae:	85 f6                	test   %esi,%esi
801011b0:	74 3b                	je     801011ed <iget+0x66>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011b2:	81 c3 90 00 00 00    	add    $0x90,%ebx
801011b8:	81 fb 54 16 11 80    	cmp    $0x80111654,%ebx
801011be:	73 35                	jae    801011f5 <iget+0x6e>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801011c0:	8b 43 08             	mov    0x8(%ebx),%eax
801011c3:	85 c0                	test   %eax,%eax
801011c5:	7e e7                	jle    801011ae <iget+0x27>
801011c7:	39 3b                	cmp    %edi,(%ebx)
801011c9:	75 e3                	jne    801011ae <iget+0x27>
801011cb:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801011ce:	39 4b 04             	cmp    %ecx,0x4(%ebx)
801011d1:	75 db                	jne    801011ae <iget+0x27>
      ip->ref++;
801011d3:	83 c0 01             	add    $0x1,%eax
801011d6:	89 43 08             	mov    %eax,0x8(%ebx)
      release(&icache.lock);
801011d9:	83 ec 0c             	sub    $0xc,%esp
801011dc:	68 00 fa 10 80       	push   $0x8010fa00
801011e1:	e8 5b 2b 00 00       	call   80103d41 <release>
      return ip;
801011e6:	83 c4 10             	add    $0x10,%esp
801011e9:	89 de                	mov    %ebx,%esi
801011eb:	eb 32                	jmp    8010121f <iget+0x98>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ed:	85 c0                	test   %eax,%eax
801011ef:	75 c1                	jne    801011b2 <iget+0x2b>
      empty = ip;
801011f1:	89 de                	mov    %ebx,%esi
801011f3:	eb bd                	jmp    801011b2 <iget+0x2b>
  if(empty == 0)
801011f5:	85 f6                	test   %esi,%esi
801011f7:	74 30                	je     80101229 <iget+0xa2>
  ip->dev = dev;
801011f9:	89 3e                	mov    %edi,(%esi)
  ip->inum = inum;
801011fb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801011fe:	89 46 04             	mov    %eax,0x4(%esi)
  ip->ref = 1;
80101201:	c7 46 08 01 00 00 00 	movl   $0x1,0x8(%esi)
  ip->valid = 0;
80101208:	c7 46 4c 00 00 00 00 	movl   $0x0,0x4c(%esi)
  release(&icache.lock);
8010120f:	83 ec 0c             	sub    $0xc,%esp
80101212:	68 00 fa 10 80       	push   $0x8010fa00
80101217:	e8 25 2b 00 00       	call   80103d41 <release>
  return ip;
8010121c:	83 c4 10             	add    $0x10,%esp
}
8010121f:	89 f0                	mov    %esi,%eax
80101221:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101224:	5b                   	pop    %ebx
80101225:	5e                   	pop    %esi
80101226:	5f                   	pop    %edi
80101227:	5d                   	pop    %ebp
80101228:	c3                   	ret    
    panic("iget: no inodes");
80101229:	83 ec 0c             	sub    $0xc,%esp
8010122c:	68 e8 66 10 80       	push   $0x801066e8
80101231:	e8 12 f1 ff ff       	call   80100348 <panic>

80101236 <readsb>:
{
80101236:	55                   	push   %ebp
80101237:	89 e5                	mov    %esp,%ebp
80101239:	53                   	push   %ebx
8010123a:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, 1);
8010123d:	6a 01                	push   $0x1
8010123f:	ff 75 08             	pushl  0x8(%ebp)
80101242:	e8 25 ef ff ff       	call   8010016c <bread>
80101247:	89 c3                	mov    %eax,%ebx
  memmove(sb, bp->data, sizeof(*sb));
80101249:	8d 40 5c             	lea    0x5c(%eax),%eax
8010124c:	83 c4 0c             	add    $0xc,%esp
8010124f:	6a 1c                	push   $0x1c
80101251:	50                   	push   %eax
80101252:	ff 75 0c             	pushl  0xc(%ebp)
80101255:	e8 a9 2b 00 00       	call   80103e03 <memmove>
  brelse(bp);
8010125a:	89 1c 24             	mov    %ebx,(%esp)
8010125d:	e8 73 ef ff ff       	call   801001d5 <brelse>
}
80101262:	83 c4 10             	add    $0x10,%esp
80101265:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101268:	c9                   	leave  
80101269:	c3                   	ret    

8010126a <bfree>:
{
8010126a:	55                   	push   %ebp
8010126b:	89 e5                	mov    %esp,%ebp
8010126d:	56                   	push   %esi
8010126e:	53                   	push   %ebx
8010126f:	89 c6                	mov    %eax,%esi
80101271:	89 d3                	mov    %edx,%ebx
  readsb(dev, &sb);
80101273:	83 ec 08             	sub    $0x8,%esp
80101276:	68 e0 f9 10 80       	push   $0x8010f9e0
8010127b:	50                   	push   %eax
8010127c:	e8 b5 ff ff ff       	call   80101236 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
80101281:	89 d8                	mov    %ebx,%eax
80101283:	c1 e8 0c             	shr    $0xc,%eax
80101286:	03 05 f8 f9 10 80    	add    0x8010f9f8,%eax
8010128c:	83 c4 08             	add    $0x8,%esp
8010128f:	50                   	push   %eax
80101290:	56                   	push   %esi
80101291:	e8 d6 ee ff ff       	call   8010016c <bread>
80101296:	89 c6                	mov    %eax,%esi
  m = 1 << (bi % 8);
80101298:	89 d9                	mov    %ebx,%ecx
8010129a:	83 e1 07             	and    $0x7,%ecx
8010129d:	b8 01 00 00 00       	mov    $0x1,%eax
801012a2:	d3 e0                	shl    %cl,%eax
  if((bp->data[bi/8] & m) == 0)
801012a4:	83 c4 10             	add    $0x10,%esp
801012a7:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
801012ad:	c1 fb 03             	sar    $0x3,%ebx
801012b0:	0f b6 54 1e 5c       	movzbl 0x5c(%esi,%ebx,1),%edx
801012b5:	0f b6 ca             	movzbl %dl,%ecx
801012b8:	85 c1                	test   %eax,%ecx
801012ba:	74 23                	je     801012df <bfree+0x75>
  bp->data[bi/8] &= ~m;
801012bc:	f7 d0                	not    %eax
801012be:	21 d0                	and    %edx,%eax
801012c0:	88 44 1e 5c          	mov    %al,0x5c(%esi,%ebx,1)
  log_write(bp);
801012c4:	83 ec 0c             	sub    $0xc,%esp
801012c7:	56                   	push   %esi
801012c8:	e8 49 17 00 00       	call   80102a16 <log_write>
  brelse(bp);
801012cd:	89 34 24             	mov    %esi,(%esp)
801012d0:	e8 00 ef ff ff       	call   801001d5 <brelse>
}
801012d5:	83 c4 10             	add    $0x10,%esp
801012d8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801012db:	5b                   	pop    %ebx
801012dc:	5e                   	pop    %esi
801012dd:	5d                   	pop    %ebp
801012de:	c3                   	ret    
    panic("freeing free block");
801012df:	83 ec 0c             	sub    $0xc,%esp
801012e2:	68 f8 66 10 80       	push   $0x801066f8
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 0b 67 10 80       	push   $0x8010670b
801012f8:	68 00 fa 10 80       	push   $0x8010fa00
801012fd:	e8 9e 28 00 00       	call   80103ba0 <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 12 67 10 80       	push   $0x80106712
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 40 fa 10 80       	add    $0x8010fa40,%eax
80101321:	50                   	push   %eax
80101322:	e8 6e 27 00 00       	call   80103a95 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
80101327:	83 c3 01             	add    $0x1,%ebx
8010132a:	83 c4 10             	add    $0x10,%esp
8010132d:	83 fb 31             	cmp    $0x31,%ebx
80101330:	7e da                	jle    8010130c <iinit+0x20>
  readsb(dev, &sb);
80101332:	83 ec 08             	sub    $0x8,%esp
80101335:	68 e0 f9 10 80       	push   $0x8010f9e0
8010133a:	ff 75 08             	pushl  0x8(%ebp)
8010133d:	e8 f4 fe ff ff       	call   80101236 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
80101342:	ff 35 f8 f9 10 80    	pushl  0x8010f9f8
80101348:	ff 35 f4 f9 10 80    	pushl  0x8010f9f4
8010134e:	ff 35 f0 f9 10 80    	pushl  0x8010f9f0
80101354:	ff 35 ec f9 10 80    	pushl  0x8010f9ec
8010135a:	ff 35 e8 f9 10 80    	pushl  0x8010f9e8
80101360:	ff 35 e4 f9 10 80    	pushl  0x8010f9e4
80101366:	ff 35 e0 f9 10 80    	pushl  0x8010f9e0
8010136c:	68 78 67 10 80       	push   $0x80106778
80101371:	e8 95 f2 ff ff       	call   8010060b <cprintf>
}
80101376:	83 c4 30             	add    $0x30,%esp
80101379:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010137c:	c9                   	leave  
8010137d:	c3                   	ret    

8010137e <ialloc>:
{
8010137e:	55                   	push   %ebp
8010137f:	89 e5                	mov    %esp,%ebp
80101381:	57                   	push   %edi
80101382:	56                   	push   %esi
80101383:	53                   	push   %ebx
80101384:	83 ec 1c             	sub    $0x1c,%esp
80101387:	8b 45 0c             	mov    0xc(%ebp),%eax
8010138a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  for(inum = 1; inum < sb.ninodes; inum++){
8010138d:	bb 01 00 00 00       	mov    $0x1,%ebx
80101392:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
80101395:	39 1d e8 f9 10 80    	cmp    %ebx,0x8010f9e8
8010139b:	76 3f                	jbe    801013dc <ialloc+0x5e>
    bp = bread(dev, IBLOCK(inum, sb));
8010139d:	89 d8                	mov    %ebx,%eax
8010139f:	c1 e8 03             	shr    $0x3,%eax
801013a2:	03 05 f4 f9 10 80    	add    0x8010f9f4,%eax
801013a8:	83 ec 08             	sub    $0x8,%esp
801013ab:	50                   	push   %eax
801013ac:	ff 75 08             	pushl  0x8(%ebp)
801013af:	e8 b8 ed ff ff       	call   8010016c <bread>
801013b4:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + inum%IPB;
801013b6:	89 d8                	mov    %ebx,%eax
801013b8:	83 e0 07             	and    $0x7,%eax
801013bb:	c1 e0 06             	shl    $0x6,%eax
801013be:	8d 7c 06 5c          	lea    0x5c(%esi,%eax,1),%edi
    if(dip->type == 0){  // a free inode
801013c2:	83 c4 10             	add    $0x10,%esp
801013c5:	66 83 3f 00          	cmpw   $0x0,(%edi)
801013c9:	74 1e                	je     801013e9 <ialloc+0x6b>
    brelse(bp);
801013cb:	83 ec 0c             	sub    $0xc,%esp
801013ce:	56                   	push   %esi
801013cf:	e8 01 ee ff ff       	call   801001d5 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
801013d4:	83 c3 01             	add    $0x1,%ebx
801013d7:	83 c4 10             	add    $0x10,%esp
801013da:	eb b6                	jmp    80101392 <ialloc+0x14>
  panic("ialloc: no inodes");
801013dc:	83 ec 0c             	sub    $0xc,%esp
801013df:	68 18 67 10 80       	push   $0x80106718
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 92 29 00 00       	call   80103d88 <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 11 16 00 00       	call   80102a16 <log_write>
      brelse(bp);
80101405:	89 34 24             	mov    %esi,(%esp)
80101408:	e8 c8 ed ff ff       	call   801001d5 <brelse>
      return iget(dev, inum);
8010140d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101410:	8b 45 08             	mov    0x8(%ebp),%eax
80101413:	e8 6f fd ff ff       	call   80101187 <iget>
}
80101418:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010141b:	5b                   	pop    %ebx
8010141c:	5e                   	pop    %esi
8010141d:	5f                   	pop    %edi
8010141e:	5d                   	pop    %ebp
8010141f:	c3                   	ret    

80101420 <iupdate>:
{
80101420:	55                   	push   %ebp
80101421:	89 e5                	mov    %esp,%ebp
80101423:	56                   	push   %esi
80101424:	53                   	push   %ebx
80101425:	8b 5d 08             	mov    0x8(%ebp),%ebx
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101428:	8b 43 04             	mov    0x4(%ebx),%eax
8010142b:	c1 e8 03             	shr    $0x3,%eax
8010142e:	03 05 f4 f9 10 80    	add    0x8010f9f4,%eax
80101434:	83 ec 08             	sub    $0x8,%esp
80101437:	50                   	push   %eax
80101438:	ff 33                	pushl  (%ebx)
8010143a:	e8 2d ed ff ff       	call   8010016c <bread>
8010143f:	89 c6                	mov    %eax,%esi
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80101441:	8b 43 04             	mov    0x4(%ebx),%eax
80101444:	83 e0 07             	and    $0x7,%eax
80101447:	c1 e0 06             	shl    $0x6,%eax
8010144a:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
  dip->type = ip->type;
8010144e:	0f b7 53 50          	movzwl 0x50(%ebx),%edx
80101452:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101455:	0f b7 53 52          	movzwl 0x52(%ebx),%edx
80101459:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
8010145d:	0f b7 53 54          	movzwl 0x54(%ebx),%edx
80101461:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101465:	0f b7 53 56          	movzwl 0x56(%ebx),%edx
80101469:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
8010146d:	8b 53 58             	mov    0x58(%ebx),%edx
80101470:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101473:	83 c3 5c             	add    $0x5c,%ebx
80101476:	83 c0 0c             	add    $0xc,%eax
80101479:	83 c4 0c             	add    $0xc,%esp
8010147c:	6a 34                	push   $0x34
8010147e:	53                   	push   %ebx
8010147f:	50                   	push   %eax
80101480:	e8 7e 29 00 00       	call   80103e03 <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 89 15 00 00       	call   80102a16 <log_write>
  brelse(bp);
8010148d:	89 34 24             	mov    %esi,(%esp)
80101490:	e8 40 ed ff ff       	call   801001d5 <brelse>
}
80101495:	83 c4 10             	add    $0x10,%esp
80101498:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010149b:	5b                   	pop    %ebx
8010149c:	5e                   	pop    %esi
8010149d:	5d                   	pop    %ebp
8010149e:	c3                   	ret    

8010149f <itrunc>:
{
8010149f:	55                   	push   %ebp
801014a0:	89 e5                	mov    %esp,%ebp
801014a2:	57                   	push   %edi
801014a3:	56                   	push   %esi
801014a4:	53                   	push   %ebx
801014a5:	83 ec 1c             	sub    $0x1c,%esp
801014a8:	89 c6                	mov    %eax,%esi
  for(i = 0; i < NDIRECT; i++){
801014aa:	bb 00 00 00 00       	mov    $0x0,%ebx
801014af:	eb 03                	jmp    801014b4 <itrunc+0x15>
801014b1:	83 c3 01             	add    $0x1,%ebx
801014b4:	83 fb 0b             	cmp    $0xb,%ebx
801014b7:	7f 19                	jg     801014d2 <itrunc+0x33>
    if(ip->addrs[i]){
801014b9:	8b 54 9e 5c          	mov    0x5c(%esi,%ebx,4),%edx
801014bd:	85 d2                	test   %edx,%edx
801014bf:	74 f0                	je     801014b1 <itrunc+0x12>
      bfree(ip->dev, ip->addrs[i]);
801014c1:	8b 06                	mov    (%esi),%eax
801014c3:	e8 a2 fd ff ff       	call   8010126a <bfree>
      ip->addrs[i] = 0;
801014c8:	c7 44 9e 5c 00 00 00 	movl   $0x0,0x5c(%esi,%ebx,4)
801014cf:	00 
801014d0:	eb df                	jmp    801014b1 <itrunc+0x12>
  if(ip->addrs[NDIRECT]){
801014d2:	8b 86 8c 00 00 00    	mov    0x8c(%esi),%eax
801014d8:	85 c0                	test   %eax,%eax
801014da:	75 1b                	jne    801014f7 <itrunc+0x58>
  ip->size = 0;
801014dc:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
  iupdate(ip);
801014e3:	83 ec 0c             	sub    $0xc,%esp
801014e6:	56                   	push   %esi
801014e7:	e8 34 ff ff ff       	call   80101420 <iupdate>
}
801014ec:	83 c4 10             	add    $0x10,%esp
801014ef:	8d 65 f4             	lea    -0xc(%ebp),%esp
801014f2:	5b                   	pop    %ebx
801014f3:	5e                   	pop    %esi
801014f4:	5f                   	pop    %edi
801014f5:	5d                   	pop    %ebp
801014f6:	c3                   	ret    
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
801014f7:	83 ec 08             	sub    $0x8,%esp
801014fa:	50                   	push   %eax
801014fb:	ff 36                	pushl  (%esi)
801014fd:	e8 6a ec ff ff       	call   8010016c <bread>
80101502:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    a = (uint*)bp->data;
80101505:	8d 78 5c             	lea    0x5c(%eax),%edi
    for(j = 0; j < NINDIRECT; j++){
80101508:	83 c4 10             	add    $0x10,%esp
8010150b:	bb 00 00 00 00       	mov    $0x0,%ebx
80101510:	eb 03                	jmp    80101515 <itrunc+0x76>
80101512:	83 c3 01             	add    $0x1,%ebx
80101515:	83 fb 7f             	cmp    $0x7f,%ebx
80101518:	77 10                	ja     8010152a <itrunc+0x8b>
      if(a[j])
8010151a:	8b 14 9f             	mov    (%edi,%ebx,4),%edx
8010151d:	85 d2                	test   %edx,%edx
8010151f:	74 f1                	je     80101512 <itrunc+0x73>
        bfree(ip->dev, a[j]);
80101521:	8b 06                	mov    (%esi),%eax
80101523:	e8 42 fd ff ff       	call   8010126a <bfree>
80101528:	eb e8                	jmp    80101512 <itrunc+0x73>
    brelse(bp);
8010152a:	83 ec 0c             	sub    $0xc,%esp
8010152d:	ff 75 e4             	pushl  -0x1c(%ebp)
80101530:	e8 a0 ec ff ff       	call   801001d5 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101535:	8b 06                	mov    (%esi),%eax
80101537:	8b 96 8c 00 00 00    	mov    0x8c(%esi),%edx
8010153d:	e8 28 fd ff ff       	call   8010126a <bfree>
    ip->addrs[NDIRECT] = 0;
80101542:	c7 86 8c 00 00 00 00 	movl   $0x0,0x8c(%esi)
80101549:	00 00 00 
8010154c:	83 c4 10             	add    $0x10,%esp
8010154f:	eb 8b                	jmp    801014dc <itrunc+0x3d>

80101551 <idup>:
{
80101551:	55                   	push   %ebp
80101552:	89 e5                	mov    %esp,%ebp
80101554:	53                   	push   %ebx
80101555:	83 ec 10             	sub    $0x10,%esp
80101558:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&icache.lock);
8010155b:	68 00 fa 10 80       	push   $0x8010fa00
80101560:	e8 77 27 00 00       	call   80103cdc <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
80101575:	e8 c7 27 00 00       	call   80103d41 <release>
}
8010157a:	89 d8                	mov    %ebx,%eax
8010157c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010157f:	c9                   	leave  
80101580:	c3                   	ret    

80101581 <ilock>:
{
80101581:	55                   	push   %ebp
80101582:	89 e5                	mov    %esp,%ebp
80101584:	56                   	push   %esi
80101585:	53                   	push   %ebx
80101586:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || ip->ref < 1)
80101589:	85 db                	test   %ebx,%ebx
8010158b:	74 22                	je     801015af <ilock+0x2e>
8010158d:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101591:	7e 1c                	jle    801015af <ilock+0x2e>
  acquiresleep(&ip->lock);
80101593:	83 ec 0c             	sub    $0xc,%esp
80101596:	8d 43 0c             	lea    0xc(%ebx),%eax
80101599:	50                   	push   %eax
8010159a:	e8 29 25 00 00       	call   80103ac8 <acquiresleep>
  if(ip->valid == 0){
8010159f:	83 c4 10             	add    $0x10,%esp
801015a2:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801015a6:	74 14                	je     801015bc <ilock+0x3b>
}
801015a8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801015ab:	5b                   	pop    %ebx
801015ac:	5e                   	pop    %esi
801015ad:	5d                   	pop    %ebp
801015ae:	c3                   	ret    
    panic("ilock");
801015af:	83 ec 0c             	sub    $0xc,%esp
801015b2:	68 2a 67 10 80       	push   $0x8010672a
801015b7:	e8 8c ed ff ff       	call   80100348 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
801015bc:	8b 43 04             	mov    0x4(%ebx),%eax
801015bf:	c1 e8 03             	shr    $0x3,%eax
801015c2:	03 05 f4 f9 10 80    	add    0x8010f9f4,%eax
801015c8:	83 ec 08             	sub    $0x8,%esp
801015cb:	50                   	push   %eax
801015cc:	ff 33                	pushl  (%ebx)
801015ce:	e8 99 eb ff ff       	call   8010016c <bread>
801015d3:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801015d5:	8b 43 04             	mov    0x4(%ebx),%eax
801015d8:	83 e0 07             	and    $0x7,%eax
801015db:	c1 e0 06             	shl    $0x6,%eax
801015de:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
    ip->type = dip->type;
801015e2:	0f b7 10             	movzwl (%eax),%edx
801015e5:	66 89 53 50          	mov    %dx,0x50(%ebx)
    ip->major = dip->major;
801015e9:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801015ed:	66 89 53 52          	mov    %dx,0x52(%ebx)
    ip->minor = dip->minor;
801015f1:	0f b7 50 04          	movzwl 0x4(%eax),%edx
801015f5:	66 89 53 54          	mov    %dx,0x54(%ebx)
    ip->nlink = dip->nlink;
801015f9:	0f b7 50 06          	movzwl 0x6(%eax),%edx
801015fd:	66 89 53 56          	mov    %dx,0x56(%ebx)
    ip->size = dip->size;
80101601:	8b 50 08             	mov    0x8(%eax),%edx
80101604:	89 53 58             	mov    %edx,0x58(%ebx)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101607:	83 c0 0c             	add    $0xc,%eax
8010160a:	8d 53 5c             	lea    0x5c(%ebx),%edx
8010160d:	83 c4 0c             	add    $0xc,%esp
80101610:	6a 34                	push   $0x34
80101612:	50                   	push   %eax
80101613:	52                   	push   %edx
80101614:	e8 ea 27 00 00       	call   80103e03 <memmove>
    brelse(bp);
80101619:	89 34 24             	mov    %esi,(%esp)
8010161c:	e8 b4 eb ff ff       	call   801001d5 <brelse>
    ip->valid = 1;
80101621:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
    if(ip->type == 0)
80101628:	83 c4 10             	add    $0x10,%esp
8010162b:	66 83 7b 50 00       	cmpw   $0x0,0x50(%ebx)
80101630:	0f 85 72 ff ff ff    	jne    801015a8 <ilock+0x27>
      panic("ilock: no type");
80101636:	83 ec 0c             	sub    $0xc,%esp
80101639:	68 30 67 10 80       	push   $0x80106730
8010163e:	e8 05 ed ff ff       	call   80100348 <panic>

80101643 <iunlock>:
{
80101643:	55                   	push   %ebp
80101644:	89 e5                	mov    %esp,%ebp
80101646:	56                   	push   %esi
80101647:	53                   	push   %ebx
80101648:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
8010164b:	85 db                	test   %ebx,%ebx
8010164d:	74 2c                	je     8010167b <iunlock+0x38>
8010164f:	8d 73 0c             	lea    0xc(%ebx),%esi
80101652:	83 ec 0c             	sub    $0xc,%esp
80101655:	56                   	push   %esi
80101656:	e8 f7 24 00 00       	call   80103b52 <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 a6 24 00 00       	call   80103b17 <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 3f 67 10 80       	push   $0x8010673f
80101683:	e8 c0 ec ff ff       	call   80100348 <panic>

80101688 <iput>:
{
80101688:	55                   	push   %ebp
80101689:	89 e5                	mov    %esp,%ebp
8010168b:	57                   	push   %edi
8010168c:	56                   	push   %esi
8010168d:	53                   	push   %ebx
8010168e:	83 ec 18             	sub    $0x18,%esp
80101691:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquiresleep(&ip->lock);
80101694:	8d 73 0c             	lea    0xc(%ebx),%esi
80101697:	56                   	push   %esi
80101698:	e8 2b 24 00 00       	call   80103ac8 <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 61 24 00 00       	call   80103b17 <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
801016bd:	e8 1a 26 00 00       	call   80103cdc <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
801016d2:	e8 6a 26 00 00       	call   80103d41 <release>
}
801016d7:	83 c4 10             	add    $0x10,%esp
801016da:	8d 65 f4             	lea    -0xc(%ebp),%esp
801016dd:	5b                   	pop    %ebx
801016de:	5e                   	pop    %esi
801016df:	5f                   	pop    %edi
801016e0:	5d                   	pop    %ebp
801016e1:	c3                   	ret    
    acquire(&icache.lock);
801016e2:	83 ec 0c             	sub    $0xc,%esp
801016e5:	68 00 fa 10 80       	push   $0x8010fa00
801016ea:	e8 ed 25 00 00       	call   80103cdc <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
801016f9:	e8 43 26 00 00       	call   80103d41 <release>
    if(r == 1){
801016fe:	83 c4 10             	add    $0x10,%esp
80101701:	83 ff 01             	cmp    $0x1,%edi
80101704:	75 a7                	jne    801016ad <iput+0x25>
      itrunc(ip);
80101706:	89 d8                	mov    %ebx,%eax
80101708:	e8 92 fd ff ff       	call   8010149f <itrunc>
      ip->type = 0;
8010170d:	66 c7 43 50 00 00    	movw   $0x0,0x50(%ebx)
      iupdate(ip);
80101713:	83 ec 0c             	sub    $0xc,%esp
80101716:	53                   	push   %ebx
80101717:	e8 04 fd ff ff       	call   80101420 <iupdate>
      ip->valid = 0;
8010171c:	c7 43 4c 00 00 00 00 	movl   $0x0,0x4c(%ebx)
80101723:	83 c4 10             	add    $0x10,%esp
80101726:	eb 85                	jmp    801016ad <iput+0x25>

80101728 <iunlockput>:
{
80101728:	55                   	push   %ebp
80101729:	89 e5                	mov    %esp,%ebp
8010172b:	53                   	push   %ebx
8010172c:	83 ec 10             	sub    $0x10,%esp
8010172f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  iunlock(ip);
80101732:	53                   	push   %ebx
80101733:	e8 0b ff ff ff       	call   80101643 <iunlock>
  iput(ip);
80101738:	89 1c 24             	mov    %ebx,(%esp)
8010173b:	e8 48 ff ff ff       	call   80101688 <iput>
}
80101740:	83 c4 10             	add    $0x10,%esp
80101743:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101746:	c9                   	leave  
80101747:	c3                   	ret    

80101748 <stati>:
{
80101748:	55                   	push   %ebp
80101749:	89 e5                	mov    %esp,%ebp
8010174b:	8b 55 08             	mov    0x8(%ebp),%edx
8010174e:	8b 45 0c             	mov    0xc(%ebp),%eax
  st->dev = ip->dev;
80101751:	8b 0a                	mov    (%edx),%ecx
80101753:	89 48 04             	mov    %ecx,0x4(%eax)
  st->ino = ip->inum;
80101756:	8b 4a 04             	mov    0x4(%edx),%ecx
80101759:	89 48 08             	mov    %ecx,0x8(%eax)
  st->type = ip->type;
8010175c:	0f b7 4a 50          	movzwl 0x50(%edx),%ecx
80101760:	66 89 08             	mov    %cx,(%eax)
  st->nlink = ip->nlink;
80101763:	0f b7 4a 56          	movzwl 0x56(%edx),%ecx
80101767:	66 89 48 0c          	mov    %cx,0xc(%eax)
  st->size = ip->size;
8010176b:	8b 52 58             	mov    0x58(%edx),%edx
8010176e:	89 50 10             	mov    %edx,0x10(%eax)
}
80101771:	5d                   	pop    %ebp
80101772:	c3                   	ret    

80101773 <readi>:
{
80101773:	55                   	push   %ebp
80101774:	89 e5                	mov    %esp,%ebp
80101776:	57                   	push   %edi
80101777:	56                   	push   %esi
80101778:	53                   	push   %ebx
80101779:	83 ec 1c             	sub    $0x1c,%esp
8010177c:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(ip->type == T_DEV){
8010177f:	8b 45 08             	mov    0x8(%ebp),%eax
80101782:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101787:	74 2c                	je     801017b5 <readi+0x42>
  if(off > ip->size || off + n < off)
80101789:	8b 45 08             	mov    0x8(%ebp),%eax
8010178c:	8b 40 58             	mov    0x58(%eax),%eax
8010178f:	39 f8                	cmp    %edi,%eax
80101791:	0f 82 cb 00 00 00    	jb     80101862 <readi+0xef>
80101797:	89 fa                	mov    %edi,%edx
80101799:	03 55 14             	add    0x14(%ebp),%edx
8010179c:	0f 82 c7 00 00 00    	jb     80101869 <readi+0xf6>
  if(off + n > ip->size)
801017a2:	39 d0                	cmp    %edx,%eax
801017a4:	73 05                	jae    801017ab <readi+0x38>
    n = ip->size - off;
801017a6:	29 f8                	sub    %edi,%eax
801017a8:	89 45 14             	mov    %eax,0x14(%ebp)
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
801017ab:	be 00 00 00 00       	mov    $0x0,%esi
801017b0:	e9 8f 00 00 00       	jmp    80101844 <readi+0xd1>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
801017b5:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801017b9:	66 83 f8 09          	cmp    $0x9,%ax
801017bd:	0f 87 91 00 00 00    	ja     80101854 <readi+0xe1>
801017c3:	98                   	cwtl   
801017c4:	8b 04 c5 80 f9 10 80 	mov    -0x7fef0680(,%eax,8),%eax
801017cb:	85 c0                	test   %eax,%eax
801017cd:	0f 84 88 00 00 00    	je     8010185b <readi+0xe8>
    return devsw[ip->major].read(ip, dst, n);
801017d3:	83 ec 04             	sub    $0x4,%esp
801017d6:	ff 75 14             	pushl  0x14(%ebp)
801017d9:	ff 75 0c             	pushl  0xc(%ebp)
801017dc:	ff 75 08             	pushl  0x8(%ebp)
801017df:	ff d0                	call   *%eax
801017e1:	83 c4 10             	add    $0x10,%esp
801017e4:	eb 66                	jmp    8010184c <readi+0xd9>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801017e6:	89 fa                	mov    %edi,%edx
801017e8:	c1 ea 09             	shr    $0x9,%edx
801017eb:	8b 45 08             	mov    0x8(%ebp),%eax
801017ee:	e8 ee f8 ff ff       	call   801010e1 <bmap>
801017f3:	83 ec 08             	sub    $0x8,%esp
801017f6:	50                   	push   %eax
801017f7:	8b 45 08             	mov    0x8(%ebp),%eax
801017fa:	ff 30                	pushl  (%eax)
801017fc:	e8 6b e9 ff ff       	call   8010016c <bread>
80101801:	89 c1                	mov    %eax,%ecx
    m = min(n - tot, BSIZE - off%BSIZE);
80101803:	89 f8                	mov    %edi,%eax
80101805:	25 ff 01 00 00       	and    $0x1ff,%eax
8010180a:	bb 00 02 00 00       	mov    $0x200,%ebx
8010180f:	29 c3                	sub    %eax,%ebx
80101811:	8b 55 14             	mov    0x14(%ebp),%edx
80101814:	29 f2                	sub    %esi,%edx
80101816:	83 c4 0c             	add    $0xc,%esp
80101819:	39 d3                	cmp    %edx,%ebx
8010181b:	0f 47 da             	cmova  %edx,%ebx
    memmove(dst, bp->data + off%BSIZE, m);
8010181e:	53                   	push   %ebx
8010181f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
80101822:	8d 44 01 5c          	lea    0x5c(%ecx,%eax,1),%eax
80101826:	50                   	push   %eax
80101827:	ff 75 0c             	pushl  0xc(%ebp)
8010182a:	e8 d4 25 00 00       	call   80103e03 <memmove>
    brelse(bp);
8010182f:	83 c4 04             	add    $0x4,%esp
80101832:	ff 75 e4             	pushl  -0x1c(%ebp)
80101835:	e8 9b e9 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010183a:	01 de                	add    %ebx,%esi
8010183c:	01 df                	add    %ebx,%edi
8010183e:	01 5d 0c             	add    %ebx,0xc(%ebp)
80101841:	83 c4 10             	add    $0x10,%esp
80101844:	39 75 14             	cmp    %esi,0x14(%ebp)
80101847:	77 9d                	ja     801017e6 <readi+0x73>
  return n;
80101849:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010184c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010184f:	5b                   	pop    %ebx
80101850:	5e                   	pop    %esi
80101851:	5f                   	pop    %edi
80101852:	5d                   	pop    %ebp
80101853:	c3                   	ret    
      return -1;
80101854:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101859:	eb f1                	jmp    8010184c <readi+0xd9>
8010185b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101860:	eb ea                	jmp    8010184c <readi+0xd9>
    return -1;
80101862:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101867:	eb e3                	jmp    8010184c <readi+0xd9>
80101869:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010186e:	eb dc                	jmp    8010184c <readi+0xd9>

80101870 <writei>:
{
80101870:	55                   	push   %ebp
80101871:	89 e5                	mov    %esp,%ebp
80101873:	57                   	push   %edi
80101874:	56                   	push   %esi
80101875:	53                   	push   %ebx
80101876:	83 ec 0c             	sub    $0xc,%esp
  if(ip->type == T_DEV){
80101879:	8b 45 08             	mov    0x8(%ebp),%eax
8010187c:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101881:	74 2f                	je     801018b2 <writei+0x42>
  if(off > ip->size || off + n < off)
80101883:	8b 45 08             	mov    0x8(%ebp),%eax
80101886:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101889:	39 48 58             	cmp    %ecx,0x58(%eax)
8010188c:	0f 82 f4 00 00 00    	jb     80101986 <writei+0x116>
80101892:	89 c8                	mov    %ecx,%eax
80101894:	03 45 14             	add    0x14(%ebp),%eax
80101897:	0f 82 f0 00 00 00    	jb     8010198d <writei+0x11d>
  if(off + n > MAXFILE*BSIZE)
8010189d:	3d 00 18 01 00       	cmp    $0x11800,%eax
801018a2:	0f 87 ec 00 00 00    	ja     80101994 <writei+0x124>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801018a8:	be 00 00 00 00       	mov    $0x0,%esi
801018ad:	e9 94 00 00 00       	jmp    80101946 <writei+0xd6>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
801018b2:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801018b6:	66 83 f8 09          	cmp    $0x9,%ax
801018ba:	0f 87 b8 00 00 00    	ja     80101978 <writei+0x108>
801018c0:	98                   	cwtl   
801018c1:	8b 04 c5 84 f9 10 80 	mov    -0x7fef067c(,%eax,8),%eax
801018c8:	85 c0                	test   %eax,%eax
801018ca:	0f 84 af 00 00 00    	je     8010197f <writei+0x10f>
    return devsw[ip->major].write(ip, src, n);
801018d0:	83 ec 04             	sub    $0x4,%esp
801018d3:	ff 75 14             	pushl  0x14(%ebp)
801018d6:	ff 75 0c             	pushl  0xc(%ebp)
801018d9:	ff 75 08             	pushl  0x8(%ebp)
801018dc:	ff d0                	call   *%eax
801018de:	83 c4 10             	add    $0x10,%esp
801018e1:	eb 7c                	jmp    8010195f <writei+0xef>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801018e3:	8b 55 10             	mov    0x10(%ebp),%edx
801018e6:	c1 ea 09             	shr    $0x9,%edx
801018e9:	8b 45 08             	mov    0x8(%ebp),%eax
801018ec:	e8 f0 f7 ff ff       	call   801010e1 <bmap>
801018f1:	83 ec 08             	sub    $0x8,%esp
801018f4:	50                   	push   %eax
801018f5:	8b 45 08             	mov    0x8(%ebp),%eax
801018f8:	ff 30                	pushl  (%eax)
801018fa:	e8 6d e8 ff ff       	call   8010016c <bread>
801018ff:	89 c7                	mov    %eax,%edi
    m = min(n - tot, BSIZE - off%BSIZE);
80101901:	8b 45 10             	mov    0x10(%ebp),%eax
80101904:	25 ff 01 00 00       	and    $0x1ff,%eax
80101909:	bb 00 02 00 00       	mov    $0x200,%ebx
8010190e:	29 c3                	sub    %eax,%ebx
80101910:	8b 55 14             	mov    0x14(%ebp),%edx
80101913:	29 f2                	sub    %esi,%edx
80101915:	83 c4 0c             	add    $0xc,%esp
80101918:	39 d3                	cmp    %edx,%ebx
8010191a:	0f 47 da             	cmova  %edx,%ebx
    memmove(bp->data + off%BSIZE, src, m);
8010191d:	53                   	push   %ebx
8010191e:	ff 75 0c             	pushl  0xc(%ebp)
80101921:	8d 44 07 5c          	lea    0x5c(%edi,%eax,1),%eax
80101925:	50                   	push   %eax
80101926:	e8 d8 24 00 00       	call   80103e03 <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 e3 10 00 00       	call   80102a16 <log_write>
    brelse(bp);
80101933:	89 3c 24             	mov    %edi,(%esp)
80101936:	e8 9a e8 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010193b:	01 de                	add    %ebx,%esi
8010193d:	01 5d 10             	add    %ebx,0x10(%ebp)
80101940:	01 5d 0c             	add    %ebx,0xc(%ebp)
80101943:	83 c4 10             	add    $0x10,%esp
80101946:	3b 75 14             	cmp    0x14(%ebp),%esi
80101949:	72 98                	jb     801018e3 <writei+0x73>
  if(n > 0 && off > ip->size){
8010194b:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010194f:	74 0b                	je     8010195c <writei+0xec>
80101951:	8b 45 08             	mov    0x8(%ebp),%eax
80101954:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101957:	39 48 58             	cmp    %ecx,0x58(%eax)
8010195a:	72 0b                	jb     80101967 <writei+0xf7>
  return n;
8010195c:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010195f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101962:	5b                   	pop    %ebx
80101963:	5e                   	pop    %esi
80101964:	5f                   	pop    %edi
80101965:	5d                   	pop    %ebp
80101966:	c3                   	ret    
    ip->size = off;
80101967:	89 48 58             	mov    %ecx,0x58(%eax)
    iupdate(ip);
8010196a:	83 ec 0c             	sub    $0xc,%esp
8010196d:	50                   	push   %eax
8010196e:	e8 ad fa ff ff       	call   80101420 <iupdate>
80101973:	83 c4 10             	add    $0x10,%esp
80101976:	eb e4                	jmp    8010195c <writei+0xec>
      return -1;
80101978:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010197d:	eb e0                	jmp    8010195f <writei+0xef>
8010197f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101984:	eb d9                	jmp    8010195f <writei+0xef>
    return -1;
80101986:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010198b:	eb d2                	jmp    8010195f <writei+0xef>
8010198d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101992:	eb cb                	jmp    8010195f <writei+0xef>
    return -1;
80101994:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101999:	eb c4                	jmp    8010195f <writei+0xef>

8010199b <namecmp>:
{
8010199b:	55                   	push   %ebp
8010199c:	89 e5                	mov    %esp,%ebp
8010199e:	83 ec 0c             	sub    $0xc,%esp
  return strncmp(s, t, DIRSIZ);
801019a1:	6a 0e                	push   $0xe
801019a3:	ff 75 0c             	pushl  0xc(%ebp)
801019a6:	ff 75 08             	pushl  0x8(%ebp)
801019a9:	e8 bc 24 00 00       	call   80103e6a <strncmp>
}
801019ae:	c9                   	leave  
801019af:	c3                   	ret    

801019b0 <dirlookup>:
{
801019b0:	55                   	push   %ebp
801019b1:	89 e5                	mov    %esp,%ebp
801019b3:	57                   	push   %edi
801019b4:	56                   	push   %esi
801019b5:	53                   	push   %ebx
801019b6:	83 ec 1c             	sub    $0x1c,%esp
801019b9:	8b 75 08             	mov    0x8(%ebp),%esi
801019bc:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if(dp->type != T_DIR)
801019bf:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
801019c4:	75 07                	jne    801019cd <dirlookup+0x1d>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019c6:	bb 00 00 00 00       	mov    $0x0,%ebx
801019cb:	eb 1d                	jmp    801019ea <dirlookup+0x3a>
    panic("dirlookup not DIR");
801019cd:	83 ec 0c             	sub    $0xc,%esp
801019d0:	68 47 67 10 80       	push   $0x80106747
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 59 67 10 80       	push   $0x80106759
801019e2:	e8 61 e9 ff ff       	call   80100348 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019e7:	83 c3 10             	add    $0x10,%ebx
801019ea:	39 5e 58             	cmp    %ebx,0x58(%esi)
801019ed:	76 48                	jbe    80101a37 <dirlookup+0x87>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801019ef:	6a 10                	push   $0x10
801019f1:	53                   	push   %ebx
801019f2:	8d 45 d8             	lea    -0x28(%ebp),%eax
801019f5:	50                   	push   %eax
801019f6:	56                   	push   %esi
801019f7:	e8 77 fd ff ff       	call   80101773 <readi>
801019fc:	83 c4 10             	add    $0x10,%esp
801019ff:	83 f8 10             	cmp    $0x10,%eax
80101a02:	75 d6                	jne    801019da <dirlookup+0x2a>
    if(de.inum == 0)
80101a04:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101a09:	74 dc                	je     801019e7 <dirlookup+0x37>
    if(namecmp(name, de.name) == 0){
80101a0b:	83 ec 08             	sub    $0x8,%esp
80101a0e:	8d 45 da             	lea    -0x26(%ebp),%eax
80101a11:	50                   	push   %eax
80101a12:	57                   	push   %edi
80101a13:	e8 83 ff ff ff       	call   8010199b <namecmp>
80101a18:	83 c4 10             	add    $0x10,%esp
80101a1b:	85 c0                	test   %eax,%eax
80101a1d:	75 c8                	jne    801019e7 <dirlookup+0x37>
      if(poff)
80101a1f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80101a23:	74 05                	je     80101a2a <dirlookup+0x7a>
        *poff = off;
80101a25:	8b 45 10             	mov    0x10(%ebp),%eax
80101a28:	89 18                	mov    %ebx,(%eax)
      inum = de.inum;
80101a2a:	0f b7 55 d8          	movzwl -0x28(%ebp),%edx
      return iget(dp->dev, inum);
80101a2e:	8b 06                	mov    (%esi),%eax
80101a30:	e8 52 f7 ff ff       	call   80101187 <iget>
80101a35:	eb 05                	jmp    80101a3c <dirlookup+0x8c>
  return 0;
80101a37:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101a3c:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a3f:	5b                   	pop    %ebx
80101a40:	5e                   	pop    %esi
80101a41:	5f                   	pop    %edi
80101a42:	5d                   	pop    %ebp
80101a43:	c3                   	ret    

80101a44 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80101a44:	55                   	push   %ebp
80101a45:	89 e5                	mov    %esp,%ebp
80101a47:	57                   	push   %edi
80101a48:	56                   	push   %esi
80101a49:	53                   	push   %ebx
80101a4a:	83 ec 1c             	sub    $0x1c,%esp
80101a4d:	89 c6                	mov    %eax,%esi
80101a4f:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101a52:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  struct inode *ip, *next;

  if(*path == '/')
80101a55:	80 38 2f             	cmpb   $0x2f,(%eax)
80101a58:	74 17                	je     80101a71 <namex+0x2d>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
80101a5a:	e8 de 18 00 00       	call   8010333d <myproc>
80101a5f:	83 ec 0c             	sub    $0xc,%esp
80101a62:	ff 70 68             	pushl  0x68(%eax)
80101a65:	e8 e7 fa ff ff       	call   80101551 <idup>
80101a6a:	89 c3                	mov    %eax,%ebx
80101a6c:	83 c4 10             	add    $0x10,%esp
80101a6f:	eb 53                	jmp    80101ac4 <namex+0x80>
    ip = iget(ROOTDEV, ROOTINO);
80101a71:	ba 01 00 00 00       	mov    $0x1,%edx
80101a76:	b8 01 00 00 00       	mov    $0x1,%eax
80101a7b:	e8 07 f7 ff ff       	call   80101187 <iget>
80101a80:	89 c3                	mov    %eax,%ebx
80101a82:	eb 40                	jmp    80101ac4 <namex+0x80>

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
      iunlockput(ip);
80101a84:	83 ec 0c             	sub    $0xc,%esp
80101a87:	53                   	push   %ebx
80101a88:	e8 9b fc ff ff       	call   80101728 <iunlockput>
      return 0;
80101a8d:	83 c4 10             	add    $0x10,%esp
80101a90:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
80101a95:	89 d8                	mov    %ebx,%eax
80101a97:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a9a:	5b                   	pop    %ebx
80101a9b:	5e                   	pop    %esi
80101a9c:	5f                   	pop    %edi
80101a9d:	5d                   	pop    %ebp
80101a9e:	c3                   	ret    
    if((next = dirlookup(ip, name, 0)) == 0){
80101a9f:	83 ec 04             	sub    $0x4,%esp
80101aa2:	6a 00                	push   $0x0
80101aa4:	ff 75 e4             	pushl  -0x1c(%ebp)
80101aa7:	53                   	push   %ebx
80101aa8:	e8 03 ff ff ff       	call   801019b0 <dirlookup>
80101aad:	89 c7                	mov    %eax,%edi
80101aaf:	83 c4 10             	add    $0x10,%esp
80101ab2:	85 c0                	test   %eax,%eax
80101ab4:	74 4a                	je     80101b00 <namex+0xbc>
    iunlockput(ip);
80101ab6:	83 ec 0c             	sub    $0xc,%esp
80101ab9:	53                   	push   %ebx
80101aba:	e8 69 fc ff ff       	call   80101728 <iunlockput>
    ip = next;
80101abf:	83 c4 10             	add    $0x10,%esp
80101ac2:	89 fb                	mov    %edi,%ebx
  while((path = skipelem(path, name)) != 0){
80101ac4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101ac7:	89 f0                	mov    %esi,%eax
80101ac9:	e8 77 f4 ff ff       	call   80100f45 <skipelem>
80101ace:	89 c6                	mov    %eax,%esi
80101ad0:	85 c0                	test   %eax,%eax
80101ad2:	74 3c                	je     80101b10 <namex+0xcc>
    ilock(ip);
80101ad4:	83 ec 0c             	sub    $0xc,%esp
80101ad7:	53                   	push   %ebx
80101ad8:	e8 a4 fa ff ff       	call   80101581 <ilock>
    if(ip->type != T_DIR){
80101add:	83 c4 10             	add    $0x10,%esp
80101ae0:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80101ae5:	75 9d                	jne    80101a84 <namex+0x40>
    if(nameiparent && *path == '\0'){
80101ae7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101aeb:	74 b2                	je     80101a9f <namex+0x5b>
80101aed:	80 3e 00             	cmpb   $0x0,(%esi)
80101af0:	75 ad                	jne    80101a9f <namex+0x5b>
      iunlock(ip);
80101af2:	83 ec 0c             	sub    $0xc,%esp
80101af5:	53                   	push   %ebx
80101af6:	e8 48 fb ff ff       	call   80101643 <iunlock>
      return ip;
80101afb:	83 c4 10             	add    $0x10,%esp
80101afe:	eb 95                	jmp    80101a95 <namex+0x51>
      iunlockput(ip);
80101b00:	83 ec 0c             	sub    $0xc,%esp
80101b03:	53                   	push   %ebx
80101b04:	e8 1f fc ff ff       	call   80101728 <iunlockput>
      return 0;
80101b09:	83 c4 10             	add    $0x10,%esp
80101b0c:	89 fb                	mov    %edi,%ebx
80101b0e:	eb 85                	jmp    80101a95 <namex+0x51>
  if(nameiparent){
80101b10:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101b14:	0f 84 7b ff ff ff    	je     80101a95 <namex+0x51>
    iput(ip);
80101b1a:	83 ec 0c             	sub    $0xc,%esp
80101b1d:	53                   	push   %ebx
80101b1e:	e8 65 fb ff ff       	call   80101688 <iput>
    return 0;
80101b23:	83 c4 10             	add    $0x10,%esp
80101b26:	bb 00 00 00 00       	mov    $0x0,%ebx
80101b2b:	e9 65 ff ff ff       	jmp    80101a95 <namex+0x51>

80101b30 <dirlink>:
{
80101b30:	55                   	push   %ebp
80101b31:	89 e5                	mov    %esp,%ebp
80101b33:	57                   	push   %edi
80101b34:	56                   	push   %esi
80101b35:	53                   	push   %ebx
80101b36:	83 ec 20             	sub    $0x20,%esp
80101b39:	8b 5d 08             	mov    0x8(%ebp),%ebx
80101b3c:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if((ip = dirlookup(dp, name, 0)) != 0){
80101b3f:	6a 00                	push   $0x0
80101b41:	57                   	push   %edi
80101b42:	53                   	push   %ebx
80101b43:	e8 68 fe ff ff       	call   801019b0 <dirlookup>
80101b48:	83 c4 10             	add    $0x10,%esp
80101b4b:	85 c0                	test   %eax,%eax
80101b4d:	75 2d                	jne    80101b7c <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b4f:	b8 00 00 00 00       	mov    $0x0,%eax
80101b54:	89 c6                	mov    %eax,%esi
80101b56:	39 43 58             	cmp    %eax,0x58(%ebx)
80101b59:	76 41                	jbe    80101b9c <dirlink+0x6c>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101b5b:	6a 10                	push   $0x10
80101b5d:	50                   	push   %eax
80101b5e:	8d 45 d8             	lea    -0x28(%ebp),%eax
80101b61:	50                   	push   %eax
80101b62:	53                   	push   %ebx
80101b63:	e8 0b fc ff ff       	call   80101773 <readi>
80101b68:	83 c4 10             	add    $0x10,%esp
80101b6b:	83 f8 10             	cmp    $0x10,%eax
80101b6e:	75 1f                	jne    80101b8f <dirlink+0x5f>
    if(de.inum == 0)
80101b70:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101b75:	74 25                	je     80101b9c <dirlink+0x6c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b77:	8d 46 10             	lea    0x10(%esi),%eax
80101b7a:	eb d8                	jmp    80101b54 <dirlink+0x24>
    iput(ip);
80101b7c:	83 ec 0c             	sub    $0xc,%esp
80101b7f:	50                   	push   %eax
80101b80:	e8 03 fb ff ff       	call   80101688 <iput>
    return -1;
80101b85:	83 c4 10             	add    $0x10,%esp
80101b88:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101b8d:	eb 3d                	jmp    80101bcc <dirlink+0x9c>
      panic("dirlink read");
80101b8f:	83 ec 0c             	sub    $0xc,%esp
80101b92:	68 68 67 10 80       	push   $0x80106768
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 f9 22 00 00       	call   80103ea7 <strncpy>
  de.inum = inum;
80101bae:	8b 45 10             	mov    0x10(%ebp),%eax
80101bb1:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101bb5:	6a 10                	push   $0x10
80101bb7:	56                   	push   %esi
80101bb8:	57                   	push   %edi
80101bb9:	53                   	push   %ebx
80101bba:	e8 b1 fc ff ff       	call   80101870 <writei>
80101bbf:	83 c4 20             	add    $0x20,%esp
80101bc2:	83 f8 10             	cmp    $0x10,%eax
80101bc5:	75 0d                	jne    80101bd4 <dirlink+0xa4>
  return 0;
80101bc7:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101bcc:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101bcf:	5b                   	pop    %ebx
80101bd0:	5e                   	pop    %esi
80101bd1:	5f                   	pop    %edi
80101bd2:	5d                   	pop    %ebp
80101bd3:	c3                   	ret    
    panic("dirlink");
80101bd4:	83 ec 0c             	sub    $0xc,%esp
80101bd7:	68 74 6d 10 80       	push   $0x80106d74
80101bdc:	e8 67 e7 ff ff       	call   80100348 <panic>

80101be1 <namei>:

struct inode*
namei(char *path)
{
80101be1:	55                   	push   %ebp
80101be2:	89 e5                	mov    %esp,%ebp
80101be4:	83 ec 18             	sub    $0x18,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80101be7:	8d 4d ea             	lea    -0x16(%ebp),%ecx
80101bea:	ba 00 00 00 00       	mov    $0x0,%edx
80101bef:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf2:	e8 4d fe ff ff       	call   80101a44 <namex>
}
80101bf7:	c9                   	leave  
80101bf8:	c3                   	ret    

80101bf9 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80101bf9:	55                   	push   %ebp
80101bfa:	89 e5                	mov    %esp,%ebp
80101bfc:	83 ec 08             	sub    $0x8,%esp
  return namex(path, 1, name);
80101bff:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80101c02:	ba 01 00 00 00       	mov    $0x1,%edx
80101c07:	8b 45 08             	mov    0x8(%ebp),%eax
80101c0a:	e8 35 fe ff ff       	call   80101a44 <namex>
}
80101c0f:	c9                   	leave  
80101c10:	c3                   	ret    

80101c11 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80101c11:	55                   	push   %ebp
80101c12:	89 e5                	mov    %esp,%ebp
80101c14:	89 c1                	mov    %eax,%ecx
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101c16:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101c1b:	ec                   	in     (%dx),%al
80101c1c:	89 c2                	mov    %eax,%edx
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY)
80101c1e:	83 e0 c0             	and    $0xffffffc0,%eax
80101c21:	3c 40                	cmp    $0x40,%al
80101c23:	75 f1                	jne    80101c16 <idewait+0x5>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80101c25:	85 c9                	test   %ecx,%ecx
80101c27:	74 0c                	je     80101c35 <idewait+0x24>
80101c29:	f6 c2 21             	test   $0x21,%dl
80101c2c:	75 0e                	jne    80101c3c <idewait+0x2b>
    return -1;
  return 0;
80101c2e:	b8 00 00 00 00       	mov    $0x0,%eax
80101c33:	eb 05                	jmp    80101c3a <idewait+0x29>
80101c35:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101c3a:	5d                   	pop    %ebp
80101c3b:	c3                   	ret    
    return -1;
80101c3c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101c41:	eb f7                	jmp    80101c3a <idewait+0x29>

80101c43 <idestart>:
}

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80101c43:	55                   	push   %ebp
80101c44:	89 e5                	mov    %esp,%ebp
80101c46:	56                   	push   %esi
80101c47:	53                   	push   %ebx
  if(b == 0)
80101c48:	85 c0                	test   %eax,%eax
80101c4a:	74 7d                	je     80101cc9 <idestart+0x86>
80101c4c:	89 c6                	mov    %eax,%esi
    panic("idestart");
  if(b->blockno >= FSSIZE)
80101c4e:	8b 58 08             	mov    0x8(%eax),%ebx
80101c51:	81 fb e7 03 00 00    	cmp    $0x3e7,%ebx
80101c57:	77 7d                	ja     80101cd6 <idestart+0x93>
  int read_cmd = (sector_per_block == 1) ? IDE_CMD_READ :  IDE_CMD_RDMUL;
  int write_cmd = (sector_per_block == 1) ? IDE_CMD_WRITE : IDE_CMD_WRMUL;

  if (sector_per_block > 7) panic("idestart");

  idewait(0);
80101c59:	b8 00 00 00 00       	mov    $0x0,%eax
80101c5e:	e8 ae ff ff ff       	call   80101c11 <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101c63:	b8 00 00 00 00       	mov    $0x0,%eax
80101c68:	ba f6 03 00 00       	mov    $0x3f6,%edx
80101c6d:	ee                   	out    %al,(%dx)
80101c6e:	b8 01 00 00 00       	mov    $0x1,%eax
80101c73:	ba f2 01 00 00       	mov    $0x1f2,%edx
80101c78:	ee                   	out    %al,(%dx)
80101c79:	ba f3 01 00 00       	mov    $0x1f3,%edx
80101c7e:	89 d8                	mov    %ebx,%eax
80101c80:	ee                   	out    %al,(%dx)
  outb(0x3f6, 0);  // generate interrupt
  outb(0x1f2, sector_per_block);  // number of sectors
  outb(0x1f3, sector & 0xff);
  outb(0x1f4, (sector >> 8) & 0xff);
80101c81:	89 d8                	mov    %ebx,%eax
80101c83:	c1 f8 08             	sar    $0x8,%eax
80101c86:	ba f4 01 00 00       	mov    $0x1f4,%edx
80101c8b:	ee                   	out    %al,(%dx)
  outb(0x1f5, (sector >> 16) & 0xff);
80101c8c:	89 d8                	mov    %ebx,%eax
80101c8e:	c1 f8 10             	sar    $0x10,%eax
80101c91:	ba f5 01 00 00       	mov    $0x1f5,%edx
80101c96:	ee                   	out    %al,(%dx)
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80101c97:	0f b6 46 04          	movzbl 0x4(%esi),%eax
80101c9b:	c1 e0 04             	shl    $0x4,%eax
80101c9e:	83 e0 10             	and    $0x10,%eax
80101ca1:	c1 fb 18             	sar    $0x18,%ebx
80101ca4:	83 e3 0f             	and    $0xf,%ebx
80101ca7:	09 d8                	or     %ebx,%eax
80101ca9:	83 c8 e0             	or     $0xffffffe0,%eax
80101cac:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101cb1:	ee                   	out    %al,(%dx)
  if(b->flags & B_DIRTY){
80101cb2:	f6 06 04             	testb  $0x4,(%esi)
80101cb5:	75 2c                	jne    80101ce3 <idestart+0xa0>
80101cb7:	b8 20 00 00 00       	mov    $0x20,%eax
80101cbc:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101cc1:	ee                   	out    %al,(%dx)
    outb(0x1f7, write_cmd);
    outsl(0x1f0, b->data, BSIZE/4);
  } else {
    outb(0x1f7, read_cmd);
  }
}
80101cc2:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101cc5:	5b                   	pop    %ebx
80101cc6:	5e                   	pop    %esi
80101cc7:	5d                   	pop    %ebp
80101cc8:	c3                   	ret    
    panic("idestart");
80101cc9:	83 ec 0c             	sub    $0xc,%esp
80101ccc:	68 cb 67 10 80       	push   $0x801067cb
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 d4 67 10 80       	push   $0x801067d4
80101cde:	e8 65 e6 ff ff       	call   80100348 <panic>
80101ce3:	b8 30 00 00 00       	mov    $0x30,%eax
80101ce8:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101ced:	ee                   	out    %al,(%dx)
    outsl(0x1f0, b->data, BSIZE/4);
80101cee:	83 c6 5c             	add    $0x5c,%esi
  asm volatile("cld; rep outsl" :
80101cf1:	b9 80 00 00 00       	mov    $0x80,%ecx
80101cf6:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101cfb:	fc                   	cld    
80101cfc:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80101cfe:	eb c2                	jmp    80101cc2 <idestart+0x7f>

80101d00 <ideinit>:
{
80101d00:	55                   	push   %ebp
80101d01:	89 e5                	mov    %esp,%ebp
80101d03:	83 ec 10             	sub    $0x10,%esp
  initlock(&idelock, "ide");
80101d06:	68 e6 67 10 80       	push   $0x801067e6
80101d0b:	68 80 95 10 80       	push   $0x80109580
80101d10:	e8 8b 1e 00 00       	call   80103ba0 <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101d15:	83 c4 08             	add    $0x8,%esp
80101d18:	a1 80 1d 13 80       	mov    0x80131d80,%eax
80101d1d:	83 e8 01             	sub    $0x1,%eax
80101d20:	50                   	push   %eax
80101d21:	6a 0e                	push   $0xe
80101d23:	e8 56 02 00 00       	call   80101f7e <ioapicenable>
  idewait(0);
80101d28:	b8 00 00 00 00       	mov    $0x0,%eax
80101d2d:	e8 df fe ff ff       	call   80101c11 <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d32:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
80101d37:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d3c:	ee                   	out    %al,(%dx)
  for(i=0; i<1000; i++){
80101d3d:	83 c4 10             	add    $0x10,%esp
80101d40:	b9 00 00 00 00       	mov    $0x0,%ecx
80101d45:	81 f9 e7 03 00 00    	cmp    $0x3e7,%ecx
80101d4b:	7f 19                	jg     80101d66 <ideinit+0x66>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101d4d:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101d52:	ec                   	in     (%dx),%al
    if(inb(0x1f7) != 0){
80101d53:	84 c0                	test   %al,%al
80101d55:	75 05                	jne    80101d5c <ideinit+0x5c>
  for(i=0; i<1000; i++){
80101d57:	83 c1 01             	add    $0x1,%ecx
80101d5a:	eb e9                	jmp    80101d45 <ideinit+0x45>
      havedisk1 = 1;
80101d5c:	c7 05 60 95 10 80 01 	movl   $0x1,0x80109560
80101d63:	00 00 00 
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d66:	b8 e0 ff ff ff       	mov    $0xffffffe0,%eax
80101d6b:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d70:	ee                   	out    %al,(%dx)
}
80101d71:	c9                   	leave  
80101d72:	c3                   	ret    

80101d73 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80101d73:	55                   	push   %ebp
80101d74:	89 e5                	mov    %esp,%ebp
80101d76:	57                   	push   %edi
80101d77:	53                   	push   %ebx
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80101d78:	83 ec 0c             	sub    $0xc,%esp
80101d7b:	68 80 95 10 80       	push   $0x80109580
80101d80:	e8 57 1f 00 00       	call   80103cdc <acquire>

  if((b = idequeue) == 0){
80101d85:	8b 1d 64 95 10 80    	mov    0x80109564,%ebx
80101d8b:	83 c4 10             	add    $0x10,%esp
80101d8e:	85 db                	test   %ebx,%ebx
80101d90:	74 48                	je     80101dda <ideintr+0x67>
    release(&idelock);
    return;
  }
  idequeue = b->qnext;
80101d92:	8b 43 58             	mov    0x58(%ebx),%eax
80101d95:	a3 64 95 10 80       	mov    %eax,0x80109564

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101d9a:	f6 03 04             	testb  $0x4,(%ebx)
80101d9d:	74 4d                	je     80101dec <ideintr+0x79>
    insl(0x1f0, b->data, BSIZE/4);

  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80101d9f:	8b 03                	mov    (%ebx),%eax
80101da1:	83 c8 02             	or     $0x2,%eax
  b->flags &= ~B_DIRTY;
80101da4:	83 e0 fb             	and    $0xfffffffb,%eax
80101da7:	89 03                	mov    %eax,(%ebx)
  wakeup(b);
80101da9:	83 ec 0c             	sub    $0xc,%esp
80101dac:	53                   	push   %ebx
80101dad:	e8 94 1b 00 00       	call   80103946 <wakeup>

  // Start disk on next buf in queue.
  if(idequeue != 0)
80101db2:	a1 64 95 10 80       	mov    0x80109564,%eax
80101db7:	83 c4 10             	add    $0x10,%esp
80101dba:	85 c0                	test   %eax,%eax
80101dbc:	74 05                	je     80101dc3 <ideintr+0x50>
    idestart(idequeue);
80101dbe:	e8 80 fe ff ff       	call   80101c43 <idestart>

  release(&idelock);
80101dc3:	83 ec 0c             	sub    $0xc,%esp
80101dc6:	68 80 95 10 80       	push   $0x80109580
80101dcb:	e8 71 1f 00 00       	call   80103d41 <release>
80101dd0:	83 c4 10             	add    $0x10,%esp
}
80101dd3:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101dd6:	5b                   	pop    %ebx
80101dd7:	5f                   	pop    %edi
80101dd8:	5d                   	pop    %ebp
80101dd9:	c3                   	ret    
    release(&idelock);
80101dda:	83 ec 0c             	sub    $0xc,%esp
80101ddd:	68 80 95 10 80       	push   $0x80109580
80101de2:	e8 5a 1f 00 00       	call   80103d41 <release>
    return;
80101de7:	83 c4 10             	add    $0x10,%esp
80101dea:	eb e7                	jmp    80101dd3 <ideintr+0x60>
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101dec:	b8 01 00 00 00       	mov    $0x1,%eax
80101df1:	e8 1b fe ff ff       	call   80101c11 <idewait>
80101df6:	85 c0                	test   %eax,%eax
80101df8:	78 a5                	js     80101d9f <ideintr+0x2c>
    insl(0x1f0, b->data, BSIZE/4);
80101dfa:	8d 7b 5c             	lea    0x5c(%ebx),%edi
  asm volatile("cld; rep insl" :
80101dfd:	b9 80 00 00 00       	mov    $0x80,%ecx
80101e02:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101e07:	fc                   	cld    
80101e08:	f3 6d                	rep insl (%dx),%es:(%edi)
80101e0a:	eb 93                	jmp    80101d9f <ideintr+0x2c>

80101e0c <iderw>:
// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80101e0c:	55                   	push   %ebp
80101e0d:	89 e5                	mov    %esp,%ebp
80101e0f:	53                   	push   %ebx
80101e10:	83 ec 10             	sub    $0x10,%esp
80101e13:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct buf **pp;

  if(!holdingsleep(&b->lock))
80101e16:	8d 43 0c             	lea    0xc(%ebx),%eax
80101e19:	50                   	push   %eax
80101e1a:	e8 33 1d 00 00       	call   80103b52 <holdingsleep>
80101e1f:	83 c4 10             	add    $0x10,%esp
80101e22:	85 c0                	test   %eax,%eax
80101e24:	74 37                	je     80101e5d <iderw+0x51>
    panic("iderw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80101e26:	8b 03                	mov    (%ebx),%eax
80101e28:	83 e0 06             	and    $0x6,%eax
80101e2b:	83 f8 02             	cmp    $0x2,%eax
80101e2e:	74 3a                	je     80101e6a <iderw+0x5e>
    panic("iderw: nothing to do");
  if(b->dev != 0 && !havedisk1)
80101e30:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80101e34:	74 09                	je     80101e3f <iderw+0x33>
80101e36:	83 3d 60 95 10 80 00 	cmpl   $0x0,0x80109560
80101e3d:	74 38                	je     80101e77 <iderw+0x6b>
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);  //DOC:acquire-lock
80101e3f:	83 ec 0c             	sub    $0xc,%esp
80101e42:	68 80 95 10 80       	push   $0x80109580
80101e47:	e8 90 1e 00 00       	call   80103cdc <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 95 10 80       	mov    $0x80109564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 ea 67 10 80       	push   $0x801067ea
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 00 68 10 80       	push   $0x80106800
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 15 68 10 80       	push   $0x80106815
80101e7f:	e8 c4 e4 ff ff       	call   80100348 <panic>
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e84:	8d 50 58             	lea    0x58(%eax),%edx
80101e87:	8b 02                	mov    (%edx),%eax
80101e89:	85 c0                	test   %eax,%eax
80101e8b:	75 f7                	jne    80101e84 <iderw+0x78>
    ;
  *pp = b;
80101e8d:	89 1a                	mov    %ebx,(%edx)

  // Start disk if necessary.
  if(idequeue == b)
80101e8f:	39 1d 64 95 10 80    	cmp    %ebx,0x80109564
80101e95:	75 1a                	jne    80101eb1 <iderw+0xa5>
    idestart(b);
80101e97:	89 d8                	mov    %ebx,%eax
80101e99:	e8 a5 fd ff ff       	call   80101c43 <idestart>
80101e9e:	eb 11                	jmp    80101eb1 <iderw+0xa5>

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
80101ea0:	83 ec 08             	sub    $0x8,%esp
80101ea3:	68 80 95 10 80       	push   $0x80109580
80101ea8:	53                   	push   %ebx
80101ea9:	e8 33 19 00 00       	call   801037e1 <sleep>
80101eae:	83 c4 10             	add    $0x10,%esp
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80101eb1:	8b 03                	mov    (%ebx),%eax
80101eb3:	83 e0 06             	and    $0x6,%eax
80101eb6:	83 f8 02             	cmp    $0x2,%eax
80101eb9:	75 e5                	jne    80101ea0 <iderw+0x94>
  }


  release(&idelock);
80101ebb:	83 ec 0c             	sub    $0xc,%esp
80101ebe:	68 80 95 10 80       	push   $0x80109580
80101ec3:	e8 79 1e 00 00       	call   80103d41 <release>
}
80101ec8:	83 c4 10             	add    $0x10,%esp
80101ecb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101ece:	c9                   	leave  
80101ecf:	c3                   	ret    

80101ed0 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80101ed0:	55                   	push   %ebp
80101ed1:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80101ed3:	8b 15 54 16 11 80    	mov    0x80111654,%edx
80101ed9:	89 02                	mov    %eax,(%edx)
  return ioapic->data;
80101edb:	a1 54 16 11 80       	mov    0x80111654,%eax
80101ee0:	8b 40 10             	mov    0x10(%eax),%eax
}
80101ee3:	5d                   	pop    %ebp
80101ee4:	c3                   	ret    

80101ee5 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80101ee5:	55                   	push   %ebp
80101ee6:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80101ee8:	8b 0d 54 16 11 80    	mov    0x80111654,%ecx
80101eee:	89 01                	mov    %eax,(%ecx)
  ioapic->data = data;
80101ef0:	a1 54 16 11 80       	mov    0x80111654,%eax
80101ef5:	89 50 10             	mov    %edx,0x10(%eax)
}
80101ef8:	5d                   	pop    %ebp
80101ef9:	c3                   	ret    

80101efa <ioapicinit>:

void
ioapicinit(void)
{
80101efa:	55                   	push   %ebp
80101efb:	89 e5                	mov    %esp,%ebp
80101efd:	57                   	push   %edi
80101efe:	56                   	push   %esi
80101eff:	53                   	push   %ebx
80101f00:	83 ec 0c             	sub    $0xc,%esp
  int i, id, maxintr;

  ioapic = (volatile struct ioapic*)IOAPIC;
80101f03:	c7 05 54 16 11 80 00 	movl   $0xfec00000,0x80111654
80101f0a:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80101f0d:	b8 01 00 00 00       	mov    $0x1,%eax
80101f12:	e8 b9 ff ff ff       	call   80101ed0 <ioapicread>
80101f17:	c1 e8 10             	shr    $0x10,%eax
80101f1a:	0f b6 f8             	movzbl %al,%edi
  id = ioapicread(REG_ID) >> 24;
80101f1d:	b8 00 00 00 00       	mov    $0x0,%eax
80101f22:	e8 a9 ff ff ff       	call   80101ed0 <ioapicread>
80101f27:	c1 e8 18             	shr    $0x18,%eax
  if(id != ioapicid)
80101f2a:	0f b6 15 e0 17 13 80 	movzbl 0x801317e0,%edx
80101f31:	39 c2                	cmp    %eax,%edx
80101f33:	75 07                	jne    80101f3c <ioapicinit+0x42>
{
80101f35:	bb 00 00 00 00       	mov    $0x0,%ebx
80101f3a:	eb 36                	jmp    80101f72 <ioapicinit+0x78>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80101f3c:	83 ec 0c             	sub    $0xc,%esp
80101f3f:	68 34 68 10 80       	push   $0x80106834
80101f44:	e8 c2 e6 ff ff       	call   8010060b <cprintf>
80101f49:	83 c4 10             	add    $0x10,%esp
80101f4c:	eb e7                	jmp    80101f35 <ioapicinit+0x3b>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80101f4e:	8d 53 20             	lea    0x20(%ebx),%edx
80101f51:	81 ca 00 00 01 00    	or     $0x10000,%edx
80101f57:	8d 74 1b 10          	lea    0x10(%ebx,%ebx,1),%esi
80101f5b:	89 f0                	mov    %esi,%eax
80101f5d:	e8 83 ff ff ff       	call   80101ee5 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80101f62:	8d 46 01             	lea    0x1(%esi),%eax
80101f65:	ba 00 00 00 00       	mov    $0x0,%edx
80101f6a:	e8 76 ff ff ff       	call   80101ee5 <ioapicwrite>
  for(i = 0; i <= maxintr; i++){
80101f6f:	83 c3 01             	add    $0x1,%ebx
80101f72:	39 fb                	cmp    %edi,%ebx
80101f74:	7e d8                	jle    80101f4e <ioapicinit+0x54>
  }
}
80101f76:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101f79:	5b                   	pop    %ebx
80101f7a:	5e                   	pop    %esi
80101f7b:	5f                   	pop    %edi
80101f7c:	5d                   	pop    %ebp
80101f7d:	c3                   	ret    

80101f7e <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80101f7e:	55                   	push   %ebp
80101f7f:	89 e5                	mov    %esp,%ebp
80101f81:	53                   	push   %ebx
80101f82:	8b 45 08             	mov    0x8(%ebp),%eax
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80101f85:	8d 50 20             	lea    0x20(%eax),%edx
80101f88:	8d 5c 00 10          	lea    0x10(%eax,%eax,1),%ebx
80101f8c:	89 d8                	mov    %ebx,%eax
80101f8e:	e8 52 ff ff ff       	call   80101ee5 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80101f93:	8b 55 0c             	mov    0xc(%ebp),%edx
80101f96:	c1 e2 18             	shl    $0x18,%edx
80101f99:	8d 43 01             	lea    0x1(%ebx),%eax
80101f9c:	e8 44 ff ff ff       	call   80101ee5 <ioapicwrite>
}
80101fa1:	5b                   	pop    %ebx
80101fa2:	5d                   	pop    %ebp
80101fa3:	c3                   	ret    

80101fa4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80101fa4:	55                   	push   %ebp
80101fa5:	89 e5                	mov    %esp,%ebp
80101fa7:	53                   	push   %ebx
80101fa8:	83 ec 04             	sub    $0x4,%esp
80101fab:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80101fae:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80101fb4:	75 4c                	jne    80102002 <kfree+0x5e>
80101fb6:	81 fb 28 45 13 80    	cmp    $0x80134528,%ebx
80101fbc:	72 44                	jb     80102002 <kfree+0x5e>
80101fbe:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80101fc4:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80101fc9:	77 37                	ja     80102002 <kfree+0x5e>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80101fcb:	83 ec 04             	sub    $0x4,%esp
80101fce:	68 00 10 00 00       	push   $0x1000
80101fd3:	6a 01                	push   $0x1
80101fd5:	53                   	push   %ebx
80101fd6:	e8 ad 1d 00 00       	call   80103d88 <memset>

  if(kmem.use_lock)
80101fdb:	83 c4 10             	add    $0x10,%esp
80101fde:	83 3d 94 16 11 80 00 	cmpl   $0x0,0x80111694
80101fe5:	75 28                	jne    8010200f <kfree+0x6b>
    acquire(&kmem.lock);
  r = (struct run*)v;
  r->next = kmem.freelist;
80101fe7:	a1 98 16 11 80       	mov    0x80111698,%eax
80101fec:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
80101fee:	89 1d 98 16 11 80    	mov    %ebx,0x80111698
  if(kmem.use_lock)
80101ff4:	83 3d 94 16 11 80 00 	cmpl   $0x0,0x80111694
80101ffb:	75 24                	jne    80102021 <kfree+0x7d>
    release(&kmem.lock);
}
80101ffd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102000:	c9                   	leave  
80102001:	c3                   	ret    
    panic("kfree");
80102002:	83 ec 0c             	sub    $0xc,%esp
80102005:	68 66 68 10 80       	push   $0x80106866
8010200a:	e8 39 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010200f:	83 ec 0c             	sub    $0xc,%esp
80102012:	68 60 16 11 80       	push   $0x80111660
80102017:	e8 c0 1c 00 00       	call   80103cdc <acquire>
8010201c:	83 c4 10             	add    $0x10,%esp
8010201f:	eb c6                	jmp    80101fe7 <kfree+0x43>
    release(&kmem.lock);
80102021:	83 ec 0c             	sub    $0xc,%esp
80102024:	68 60 16 11 80       	push   $0x80111660
80102029:	e8 13 1d 00 00       	call   80103d41 <release>
8010202e:	83 c4 10             	add    $0x10,%esp
}
80102031:	eb ca                	jmp    80101ffd <kfree+0x59>

80102033 <freerange>:
{
80102033:	55                   	push   %ebp
80102034:	89 e5                	mov    %esp,%ebp
80102036:	56                   	push   %esi
80102037:	53                   	push   %ebx
80102038:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  p = (char*)PGROUNDUP((uint)vstart);
8010203b:	8b 45 08             	mov    0x8(%ebp),%eax
8010203e:	05 ff 0f 00 00       	add    $0xfff,%eax
80102043:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102048:	eb 0e                	jmp    80102058 <freerange+0x25>
    kfree(p);
8010204a:	83 ec 0c             	sub    $0xc,%esp
8010204d:	50                   	push   %eax
8010204e:	e8 51 ff ff ff       	call   80101fa4 <kfree>
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102053:	83 c4 10             	add    $0x10,%esp
80102056:	89 f0                	mov    %esi,%eax
80102058:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
8010205e:	39 de                	cmp    %ebx,%esi
80102060:	76 e8                	jbe    8010204a <freerange+0x17>
}
80102062:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102065:	5b                   	pop    %ebx
80102066:	5e                   	pop    %esi
80102067:	5d                   	pop    %ebp
80102068:	c3                   	ret    

80102069 <kinit1>:
{
80102069:	55                   	push   %ebp
8010206a:	89 e5                	mov    %esp,%ebp
8010206c:	83 ec 10             	sub    $0x10,%esp
  initlock(&kmem.lock, "kmem");
8010206f:	68 6c 68 10 80       	push   $0x8010686c
80102074:	68 60 16 11 80       	push   $0x80111660
80102079:	e8 22 1b 00 00       	call   80103ba0 <initlock>
  kmem.use_lock = 0;
8010207e:	c7 05 94 16 11 80 00 	movl   $0x0,0x80111694
80102085:	00 00 00 
  freerange(vstart, vend);
80102088:	83 c4 08             	add    $0x8,%esp
8010208b:	ff 75 0c             	pushl  0xc(%ebp)
8010208e:	ff 75 08             	pushl  0x8(%ebp)
80102091:	e8 9d ff ff ff       	call   80102033 <freerange>
}
80102096:	83 c4 10             	add    $0x10,%esp
80102099:	c9                   	leave  
8010209a:	c3                   	ret    

8010209b <kinit2>:
{
8010209b:	55                   	push   %ebp
8010209c:	89 e5                	mov    %esp,%ebp
8010209e:	83 ec 10             	sub    $0x10,%esp
  freerange(vstart, vend);
801020a1:	ff 75 0c             	pushl  0xc(%ebp)
801020a4:	ff 75 08             	pushl  0x8(%ebp)
801020a7:	e8 87 ff ff ff       	call   80102033 <freerange>
  kmem.use_lock = 1;
801020ac:	c7 05 94 16 11 80 01 	movl   $0x1,0x80111694
801020b3:	00 00 00 
}
801020b6:	83 c4 10             	add    $0x10,%esp
801020b9:	c9                   	leave  
801020ba:	c3                   	ret    

801020bb <updatePid>:

void updatePid(uint pid){
801020bb:	55                   	push   %ebp
801020bc:	89 e5                	mov    %esp,%ebp
	pidNum = pid;
801020be:	8b 45 08             	mov    0x8(%ebp),%eax
801020c1:	a3 a0 16 11 80       	mov    %eax,0x801116a0
}
801020c6:	5d                   	pop    %ebp
801020c7:	c3                   	ret    

801020c8 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
801020c8:	55                   	push   %ebp
801020c9:	89 e5                	mov    %esp,%ebp
801020cb:	53                   	push   %ebx
801020cc:	83 ec 04             	sub    $0x4,%esp
  struct run *r;

  if(kmem.use_lock)
801020cf:	83 3d 94 16 11 80 00 	cmpl   $0x0,0x80111694
801020d6:	75 23                	jne    801020fb <kalloc+0x33>
    acquire(&kmem.lock);
  r = kmem.freelist;
801020d8:	8b 1d 98 16 11 80    	mov    0x80111698,%ebx
  if(r)
801020de:	85 db                	test   %ebx,%ebx
801020e0:	74 09                	je     801020eb <kalloc+0x23>
    kmem.freelist = r->next->next;
801020e2:	8b 03                	mov    (%ebx),%eax
801020e4:	8b 00                	mov    (%eax),%eax
801020e6:	a3 98 16 11 80       	mov    %eax,0x80111698

  if(kmem.use_lock) {
801020eb:	83 3d 94 16 11 80 00 	cmpl   $0x0,0x80111694
801020f2:	75 19                	jne    8010210d <kalloc+0x45>
    pids[index] = pidNum;
    index++;
    release(&kmem.lock);
  }
  return (char*)r;
}
801020f4:	89 d8                	mov    %ebx,%eax
801020f6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801020f9:	c9                   	leave  
801020fa:	c3                   	ret    
    acquire(&kmem.lock);
801020fb:	83 ec 0c             	sub    $0xc,%esp
801020fe:	68 60 16 11 80       	push   $0x80111660
80102103:	e8 d4 1b 00 00       	call   80103cdc <acquire>
80102108:	83 c4 10             	add    $0x10,%esp
8010210b:	eb cb                	jmp    801020d8 <kalloc+0x10>
    framenumber = (uint)(V2P(r) >> 12 & 0xffff);
8010210d:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80102113:	c1 e8 0c             	shr    $0xc,%eax
80102116:	0f b7 c0             	movzwl %ax,%eax
80102119:	a3 9c 16 11 80       	mov    %eax,0x8011169c
    updatePid(-2);
8010211e:	83 ec 0c             	sub    $0xc,%esp
80102121:	6a fe                	push   $0xfffffffe
80102123:	e8 93 ff ff ff       	call   801020bb <updatePid>
    frames[index] = framenumber;
80102128:	a1 b4 95 10 80       	mov    0x801095b4,%eax
8010212d:	8b 15 9c 16 11 80    	mov    0x8011169c,%edx
80102133:	89 14 85 c0 16 11 80 	mov    %edx,-0x7feee940(,%eax,4)
    pids[index] = pidNum;
8010213a:	8b 15 a0 16 11 80    	mov    0x801116a0,%edx
80102140:	89 14 85 e0 16 12 80 	mov    %edx,-0x7fede920(,%eax,4)
    index++;
80102147:	83 c0 01             	add    $0x1,%eax
8010214a:	a3 b4 95 10 80       	mov    %eax,0x801095b4
    release(&kmem.lock);
8010214f:	c7 04 24 60 16 11 80 	movl   $0x80111660,(%esp)
80102156:	e8 e6 1b 00 00       	call   80103d41 <release>
8010215b:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
8010215e:	eb 94                	jmp    801020f4 <kalloc+0x2c>

80102160 <kalloc2>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc2(uint pid)
{
80102160:	55                   	push   %ebp
80102161:	89 e5                	mov    %esp,%ebp
80102163:	53                   	push   %ebx
80102164:	83 ec 04             	sub    $0x4,%esp
  struct run *r;

  if(kmem.use_lock)
80102167:	83 3d 94 16 11 80 00 	cmpl   $0x0,0x80111694
8010216e:	75 31                	jne    801021a1 <kalloc2+0x41>
    acquire(&kmem.lock);
  r = kmem.freelist;
80102170:	8b 1d 98 16 11 80    	mov    0x80111698,%ebx
  if(r)
80102176:	85 db                	test   %ebx,%ebx
80102178:	74 09                	je     80102183 <kalloc2+0x23>
    kmem.freelist = r->next->next;
8010217a:	8b 03                	mov    (%ebx),%eax
8010217c:	8b 00                	mov    (%eax),%eax
8010217e:	a3 98 16 11 80       	mov    %eax,0x80111698
  
  // Update global pid
  updatePid(pid);
80102183:	83 ec 0c             	sub    $0xc,%esp
80102186:	ff 75 08             	pushl  0x8(%ebp)
80102189:	e8 2d ff ff ff       	call   801020bb <updatePid>

  if(kmem.use_lock) {
8010218e:	83 c4 10             	add    $0x10,%esp
80102191:	83 3d 94 16 11 80 00 	cmpl   $0x0,0x80111694
80102198:	75 19                	jne    801021b3 <kalloc2+0x53>
    index++;
    release(&kmem.lock);
  }
    
  return (char*)r;
}
8010219a:	89 d8                	mov    %ebx,%eax
8010219c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010219f:	c9                   	leave  
801021a0:	c3                   	ret    
    acquire(&kmem.lock);
801021a1:	83 ec 0c             	sub    $0xc,%esp
801021a4:	68 60 16 11 80       	push   $0x80111660
801021a9:	e8 2e 1b 00 00       	call   80103cdc <acquire>
801021ae:	83 c4 10             	add    $0x10,%esp
801021b1:	eb bd                	jmp    80102170 <kalloc2+0x10>
    framenumber = (uint)(V2P(r) >> 12 & 0xffff);
801021b3:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801021b9:	c1 e8 0c             	shr    $0xc,%eax
801021bc:	0f b7 c0             	movzwl %ax,%eax
801021bf:	a3 9c 16 11 80       	mov    %eax,0x8011169c
    frames[index] = framenumber;
801021c4:	8b 15 b4 95 10 80    	mov    0x801095b4,%edx
801021ca:	89 04 95 c0 16 11 80 	mov    %eax,-0x7feee940(,%edx,4)
    pids[index] = pidNum;
801021d1:	a1 a0 16 11 80       	mov    0x801116a0,%eax
801021d6:	89 04 95 e0 16 12 80 	mov    %eax,-0x7fede920(,%edx,4)
    index++;
801021dd:	83 c2 01             	add    $0x1,%edx
801021e0:	89 15 b4 95 10 80    	mov    %edx,0x801095b4
    release(&kmem.lock);
801021e6:	83 ec 0c             	sub    $0xc,%esp
801021e9:	68 60 16 11 80       	push   $0x80111660
801021ee:	e8 4e 1b 00 00       	call   80103d41 <release>
801021f3:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
801021f6:	eb a2                	jmp    8010219a <kalloc2+0x3a>

801021f8 <dump_physmem>:

int
dump_physmem(int *frs, int *pds, int numframes)
{
801021f8:	55                   	push   %ebp
801021f9:	89 e5                	mov    %esp,%ebp
801021fb:	57                   	push   %edi
801021fc:	56                   	push   %esi
801021fd:	53                   	push   %ebx
801021fe:	8b 75 08             	mov    0x8(%ebp),%esi
80102201:	8b 7d 0c             	mov    0xc(%ebp),%edi
80102204:	8b 5d 10             	mov    0x10(%ebp),%ebx
  if(numframes <= 0 || frs == 0 || pids == 0)
80102207:	85 db                	test   %ebx,%ebx
80102209:	0f 9e c2             	setle  %dl
8010220c:	85 f6                	test   %esi,%esi
8010220e:	0f 94 c0             	sete   %al
80102211:	08 c2                	or     %al,%dl
80102213:	75 33                	jne    80102248 <dump_physmem+0x50>
    return -1;
  for (int i = 0; i < numframes; i++) {
80102215:	b8 00 00 00 00       	mov    $0x0,%eax
8010221a:	eb 1e                	jmp    8010223a <dump_physmem+0x42>
    frs[i] = frames[i];
8010221c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80102223:	8b 0c 85 c0 16 11 80 	mov    -0x7feee940(,%eax,4),%ecx
8010222a:	89 0c 16             	mov    %ecx,(%esi,%edx,1)
    pds[i] = pids[i];
8010222d:	8b 0c 85 e0 16 12 80 	mov    -0x7fede920(,%eax,4),%ecx
80102234:	89 0c 17             	mov    %ecx,(%edi,%edx,1)
  for (int i = 0; i < numframes; i++) {
80102237:	83 c0 01             	add    $0x1,%eax
8010223a:	39 d8                	cmp    %ebx,%eax
8010223c:	7c de                	jl     8010221c <dump_physmem+0x24>
  }
  return 0;
8010223e:	b8 00 00 00 00       	mov    $0x0,%eax
80102243:	5b                   	pop    %ebx
80102244:	5e                   	pop    %esi
80102245:	5f                   	pop    %edi
80102246:	5d                   	pop    %ebp
80102247:	c3                   	ret    
    return -1;
80102248:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010224d:	eb f4                	jmp    80102243 <dump_physmem+0x4b>

8010224f <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
8010224f:	55                   	push   %ebp
80102250:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102252:	ba 64 00 00 00       	mov    $0x64,%edx
80102257:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
80102258:	a8 01                	test   $0x1,%al
8010225a:	0f 84 b5 00 00 00    	je     80102315 <kbdgetc+0xc6>
80102260:	ba 60 00 00 00       	mov    $0x60,%edx
80102265:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
80102266:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
80102269:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
8010226f:	74 5c                	je     801022cd <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
80102271:	84 c0                	test   %al,%al
80102273:	78 66                	js     801022db <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
80102275:	8b 0d b8 95 10 80    	mov    0x801095b8,%ecx
8010227b:	f6 c1 40             	test   $0x40,%cl
8010227e:	74 0f                	je     8010228f <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102280:	83 c8 80             	or     $0xffffff80,%eax
80102283:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
80102286:	83 e1 bf             	and    $0xffffffbf,%ecx
80102289:	89 0d b8 95 10 80    	mov    %ecx,0x801095b8
  }

  shift |= shiftcode[data];
8010228f:	0f b6 8a a0 69 10 80 	movzbl -0x7fef9660(%edx),%ecx
80102296:	0b 0d b8 95 10 80    	or     0x801095b8,%ecx
  shift ^= togglecode[data];
8010229c:	0f b6 82 a0 68 10 80 	movzbl -0x7fef9760(%edx),%eax
801022a3:	31 c1                	xor    %eax,%ecx
801022a5:	89 0d b8 95 10 80    	mov    %ecx,0x801095b8
  c = charcode[shift & (CTL | SHIFT)][data];
801022ab:	89 c8                	mov    %ecx,%eax
801022ad:	83 e0 03             	and    $0x3,%eax
801022b0:	8b 04 85 80 68 10 80 	mov    -0x7fef9780(,%eax,4),%eax
801022b7:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
801022bb:	f6 c1 08             	test   $0x8,%cl
801022be:	74 19                	je     801022d9 <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
801022c0:	8d 50 9f             	lea    -0x61(%eax),%edx
801022c3:	83 fa 19             	cmp    $0x19,%edx
801022c6:	77 40                	ja     80102308 <kbdgetc+0xb9>
      c += 'A' - 'a';
801022c8:	83 e8 20             	sub    $0x20,%eax
801022cb:	eb 0c                	jmp    801022d9 <kbdgetc+0x8a>
    shift |= E0ESC;
801022cd:	83 0d b8 95 10 80 40 	orl    $0x40,0x801095b8
    return 0;
801022d4:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
801022d9:	5d                   	pop    %ebp
801022da:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
801022db:	8b 0d b8 95 10 80    	mov    0x801095b8,%ecx
801022e1:	f6 c1 40             	test   $0x40,%cl
801022e4:	75 05                	jne    801022eb <kbdgetc+0x9c>
801022e6:	89 c2                	mov    %eax,%edx
801022e8:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
801022eb:	0f b6 82 a0 69 10 80 	movzbl -0x7fef9660(%edx),%eax
801022f2:	83 c8 40             	or     $0x40,%eax
801022f5:	0f b6 c0             	movzbl %al,%eax
801022f8:	f7 d0                	not    %eax
801022fa:	21 c8                	and    %ecx,%eax
801022fc:	a3 b8 95 10 80       	mov    %eax,0x801095b8
    return 0;
80102301:	b8 00 00 00 00       	mov    $0x0,%eax
80102306:	eb d1                	jmp    801022d9 <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
80102308:	8d 50 bf             	lea    -0x41(%eax),%edx
8010230b:	83 fa 19             	cmp    $0x19,%edx
8010230e:	77 c9                	ja     801022d9 <kbdgetc+0x8a>
      c += 'a' - 'A';
80102310:	83 c0 20             	add    $0x20,%eax
  return c;
80102313:	eb c4                	jmp    801022d9 <kbdgetc+0x8a>
    return -1;
80102315:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010231a:	eb bd                	jmp    801022d9 <kbdgetc+0x8a>

8010231c <kbdintr>:

void
kbdintr(void)
{
8010231c:	55                   	push   %ebp
8010231d:	89 e5                	mov    %esp,%ebp
8010231f:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
80102322:	68 4f 22 10 80       	push   $0x8010224f
80102327:	e8 12 e4 ff ff       	call   8010073e <consoleintr>
}
8010232c:	83 c4 10             	add    $0x10,%esp
8010232f:	c9                   	leave  
80102330:	c3                   	ret    

80102331 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102331:	55                   	push   %ebp
80102332:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102334:	8b 0d e4 16 13 80    	mov    0x801316e4,%ecx
8010233a:	8d 04 81             	lea    (%ecx,%eax,4),%eax
8010233d:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
8010233f:	a1 e4 16 13 80       	mov    0x801316e4,%eax
80102344:	8b 40 20             	mov    0x20(%eax),%eax
}
80102347:	5d                   	pop    %ebp
80102348:	c3                   	ret    

80102349 <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
80102349:	55                   	push   %ebp
8010234a:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010234c:	ba 70 00 00 00       	mov    $0x70,%edx
80102351:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102352:	ba 71 00 00 00       	mov    $0x71,%edx
80102357:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
80102358:	0f b6 c0             	movzbl %al,%eax
}
8010235b:	5d                   	pop    %ebp
8010235c:	c3                   	ret    

8010235d <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
8010235d:	55                   	push   %ebp
8010235e:	89 e5                	mov    %esp,%ebp
80102360:	53                   	push   %ebx
80102361:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
80102363:	b8 00 00 00 00       	mov    $0x0,%eax
80102368:	e8 dc ff ff ff       	call   80102349 <cmos_read>
8010236d:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
8010236f:	b8 02 00 00 00       	mov    $0x2,%eax
80102374:	e8 d0 ff ff ff       	call   80102349 <cmos_read>
80102379:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
8010237c:	b8 04 00 00 00       	mov    $0x4,%eax
80102381:	e8 c3 ff ff ff       	call   80102349 <cmos_read>
80102386:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
80102389:	b8 07 00 00 00       	mov    $0x7,%eax
8010238e:	e8 b6 ff ff ff       	call   80102349 <cmos_read>
80102393:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
80102396:	b8 08 00 00 00       	mov    $0x8,%eax
8010239b:	e8 a9 ff ff ff       	call   80102349 <cmos_read>
801023a0:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
801023a3:	b8 09 00 00 00       	mov    $0x9,%eax
801023a8:	e8 9c ff ff ff       	call   80102349 <cmos_read>
801023ad:	89 43 14             	mov    %eax,0x14(%ebx)
}
801023b0:	5b                   	pop    %ebx
801023b1:	5d                   	pop    %ebp
801023b2:	c3                   	ret    

801023b3 <lapicinit>:
  if(!lapic)
801023b3:	83 3d e4 16 13 80 00 	cmpl   $0x0,0x801316e4
801023ba:	0f 84 fb 00 00 00    	je     801024bb <lapicinit+0x108>
{
801023c0:	55                   	push   %ebp
801023c1:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801023c3:	ba 3f 01 00 00       	mov    $0x13f,%edx
801023c8:	b8 3c 00 00 00       	mov    $0x3c,%eax
801023cd:	e8 5f ff ff ff       	call   80102331 <lapicw>
  lapicw(TDCR, X1);
801023d2:	ba 0b 00 00 00       	mov    $0xb,%edx
801023d7:	b8 f8 00 00 00       	mov    $0xf8,%eax
801023dc:	e8 50 ff ff ff       	call   80102331 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801023e1:	ba 20 00 02 00       	mov    $0x20020,%edx
801023e6:	b8 c8 00 00 00       	mov    $0xc8,%eax
801023eb:	e8 41 ff ff ff       	call   80102331 <lapicw>
  lapicw(TICR, 10000000);
801023f0:	ba 80 96 98 00       	mov    $0x989680,%edx
801023f5:	b8 e0 00 00 00       	mov    $0xe0,%eax
801023fa:	e8 32 ff ff ff       	call   80102331 <lapicw>
  lapicw(LINT0, MASKED);
801023ff:	ba 00 00 01 00       	mov    $0x10000,%edx
80102404:	b8 d4 00 00 00       	mov    $0xd4,%eax
80102409:	e8 23 ff ff ff       	call   80102331 <lapicw>
  lapicw(LINT1, MASKED);
8010240e:	ba 00 00 01 00       	mov    $0x10000,%edx
80102413:	b8 d8 00 00 00       	mov    $0xd8,%eax
80102418:	e8 14 ff ff ff       	call   80102331 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
8010241d:	a1 e4 16 13 80       	mov    0x801316e4,%eax
80102422:	8b 40 30             	mov    0x30(%eax),%eax
80102425:	c1 e8 10             	shr    $0x10,%eax
80102428:	3c 03                	cmp    $0x3,%al
8010242a:	77 7b                	ja     801024a7 <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
8010242c:	ba 33 00 00 00       	mov    $0x33,%edx
80102431:	b8 dc 00 00 00       	mov    $0xdc,%eax
80102436:	e8 f6 fe ff ff       	call   80102331 <lapicw>
  lapicw(ESR, 0);
8010243b:	ba 00 00 00 00       	mov    $0x0,%edx
80102440:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102445:	e8 e7 fe ff ff       	call   80102331 <lapicw>
  lapicw(ESR, 0);
8010244a:	ba 00 00 00 00       	mov    $0x0,%edx
8010244f:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102454:	e8 d8 fe ff ff       	call   80102331 <lapicw>
  lapicw(EOI, 0);
80102459:	ba 00 00 00 00       	mov    $0x0,%edx
8010245e:	b8 2c 00 00 00       	mov    $0x2c,%eax
80102463:	e8 c9 fe ff ff       	call   80102331 <lapicw>
  lapicw(ICRHI, 0);
80102468:	ba 00 00 00 00       	mov    $0x0,%edx
8010246d:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102472:	e8 ba fe ff ff       	call   80102331 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102477:	ba 00 85 08 00       	mov    $0x88500,%edx
8010247c:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102481:	e8 ab fe ff ff       	call   80102331 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102486:	a1 e4 16 13 80       	mov    0x801316e4,%eax
8010248b:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
80102491:	f6 c4 10             	test   $0x10,%ah
80102494:	75 f0                	jne    80102486 <lapicinit+0xd3>
  lapicw(TPR, 0);
80102496:	ba 00 00 00 00       	mov    $0x0,%edx
8010249b:	b8 20 00 00 00       	mov    $0x20,%eax
801024a0:	e8 8c fe ff ff       	call   80102331 <lapicw>
}
801024a5:	5d                   	pop    %ebp
801024a6:	c3                   	ret    
    lapicw(PCINT, MASKED);
801024a7:	ba 00 00 01 00       	mov    $0x10000,%edx
801024ac:	b8 d0 00 00 00       	mov    $0xd0,%eax
801024b1:	e8 7b fe ff ff       	call   80102331 <lapicw>
801024b6:	e9 71 ff ff ff       	jmp    8010242c <lapicinit+0x79>
801024bb:	f3 c3                	repz ret 

801024bd <lapicid>:
{
801024bd:	55                   	push   %ebp
801024be:	89 e5                	mov    %esp,%ebp
  if (!lapic)
801024c0:	a1 e4 16 13 80       	mov    0x801316e4,%eax
801024c5:	85 c0                	test   %eax,%eax
801024c7:	74 08                	je     801024d1 <lapicid+0x14>
  return lapic[ID] >> 24;
801024c9:	8b 40 20             	mov    0x20(%eax),%eax
801024cc:	c1 e8 18             	shr    $0x18,%eax
}
801024cf:	5d                   	pop    %ebp
801024d0:	c3                   	ret    
    return 0;
801024d1:	b8 00 00 00 00       	mov    $0x0,%eax
801024d6:	eb f7                	jmp    801024cf <lapicid+0x12>

801024d8 <lapiceoi>:
  if(lapic)
801024d8:	83 3d e4 16 13 80 00 	cmpl   $0x0,0x801316e4
801024df:	74 14                	je     801024f5 <lapiceoi+0x1d>
{
801024e1:	55                   	push   %ebp
801024e2:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
801024e4:	ba 00 00 00 00       	mov    $0x0,%edx
801024e9:	b8 2c 00 00 00       	mov    $0x2c,%eax
801024ee:	e8 3e fe ff ff       	call   80102331 <lapicw>
}
801024f3:	5d                   	pop    %ebp
801024f4:	c3                   	ret    
801024f5:	f3 c3                	repz ret 

801024f7 <microdelay>:
{
801024f7:	55                   	push   %ebp
801024f8:	89 e5                	mov    %esp,%ebp
}
801024fa:	5d                   	pop    %ebp
801024fb:	c3                   	ret    

801024fc <lapicstartap>:
{
801024fc:	55                   	push   %ebp
801024fd:	89 e5                	mov    %esp,%ebp
801024ff:	57                   	push   %edi
80102500:	56                   	push   %esi
80102501:	53                   	push   %ebx
80102502:	8b 75 08             	mov    0x8(%ebp),%esi
80102505:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102508:	b8 0f 00 00 00       	mov    $0xf,%eax
8010250d:	ba 70 00 00 00       	mov    $0x70,%edx
80102512:	ee                   	out    %al,(%dx)
80102513:	b8 0a 00 00 00       	mov    $0xa,%eax
80102518:	ba 71 00 00 00       	mov    $0x71,%edx
8010251d:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
8010251e:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
80102525:	00 00 
  wrv[1] = addr >> 4;
80102527:	89 f8                	mov    %edi,%eax
80102529:	c1 e8 04             	shr    $0x4,%eax
8010252c:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
80102532:	c1 e6 18             	shl    $0x18,%esi
80102535:	89 f2                	mov    %esi,%edx
80102537:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010253c:	e8 f0 fd ff ff       	call   80102331 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102541:	ba 00 c5 00 00       	mov    $0xc500,%edx
80102546:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010254b:	e8 e1 fd ff ff       	call   80102331 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
80102550:	ba 00 85 00 00       	mov    $0x8500,%edx
80102555:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010255a:	e8 d2 fd ff ff       	call   80102331 <lapicw>
  for(i = 0; i < 2; i++){
8010255f:	bb 00 00 00 00       	mov    $0x0,%ebx
80102564:	eb 21                	jmp    80102587 <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
80102566:	89 f2                	mov    %esi,%edx
80102568:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010256d:	e8 bf fd ff ff       	call   80102331 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80102572:	89 fa                	mov    %edi,%edx
80102574:	c1 ea 0c             	shr    $0xc,%edx
80102577:	80 ce 06             	or     $0x6,%dh
8010257a:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010257f:	e8 ad fd ff ff       	call   80102331 <lapicw>
  for(i = 0; i < 2; i++){
80102584:	83 c3 01             	add    $0x1,%ebx
80102587:	83 fb 01             	cmp    $0x1,%ebx
8010258a:	7e da                	jle    80102566 <lapicstartap+0x6a>
}
8010258c:	5b                   	pop    %ebx
8010258d:	5e                   	pop    %esi
8010258e:	5f                   	pop    %edi
8010258f:	5d                   	pop    %ebp
80102590:	c3                   	ret    

80102591 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
80102591:	55                   	push   %ebp
80102592:	89 e5                	mov    %esp,%ebp
80102594:	57                   	push   %edi
80102595:	56                   	push   %esi
80102596:	53                   	push   %ebx
80102597:	83 ec 3c             	sub    $0x3c,%esp
8010259a:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
8010259d:	b8 0b 00 00 00       	mov    $0xb,%eax
801025a2:	e8 a2 fd ff ff       	call   80102349 <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
801025a7:	83 e0 04             	and    $0x4,%eax
801025aa:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
801025ac:	8d 45 d0             	lea    -0x30(%ebp),%eax
801025af:	e8 a9 fd ff ff       	call   8010235d <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
801025b4:	b8 0a 00 00 00       	mov    $0xa,%eax
801025b9:	e8 8b fd ff ff       	call   80102349 <cmos_read>
801025be:	a8 80                	test   $0x80,%al
801025c0:	75 ea                	jne    801025ac <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
801025c2:	8d 5d b8             	lea    -0x48(%ebp),%ebx
801025c5:	89 d8                	mov    %ebx,%eax
801025c7:	e8 91 fd ff ff       	call   8010235d <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
801025cc:	83 ec 04             	sub    $0x4,%esp
801025cf:	6a 18                	push   $0x18
801025d1:	53                   	push   %ebx
801025d2:	8d 45 d0             	lea    -0x30(%ebp),%eax
801025d5:	50                   	push   %eax
801025d6:	e8 f3 17 00 00       	call   80103dce <memcmp>
801025db:	83 c4 10             	add    $0x10,%esp
801025de:	85 c0                	test   %eax,%eax
801025e0:	75 ca                	jne    801025ac <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
801025e2:	85 ff                	test   %edi,%edi
801025e4:	0f 85 84 00 00 00    	jne    8010266e <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801025ea:	8b 55 d0             	mov    -0x30(%ebp),%edx
801025ed:	89 d0                	mov    %edx,%eax
801025ef:	c1 e8 04             	shr    $0x4,%eax
801025f2:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025f5:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025f8:	83 e2 0f             	and    $0xf,%edx
801025fb:	01 d0                	add    %edx,%eax
801025fd:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
80102600:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80102603:	89 d0                	mov    %edx,%eax
80102605:	c1 e8 04             	shr    $0x4,%eax
80102608:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010260b:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010260e:	83 e2 0f             	and    $0xf,%edx
80102611:	01 d0                	add    %edx,%eax
80102613:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
80102616:	8b 55 d8             	mov    -0x28(%ebp),%edx
80102619:	89 d0                	mov    %edx,%eax
8010261b:	c1 e8 04             	shr    $0x4,%eax
8010261e:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102621:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102624:	83 e2 0f             	and    $0xf,%edx
80102627:	01 d0                	add    %edx,%eax
80102629:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
8010262c:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010262f:	89 d0                	mov    %edx,%eax
80102631:	c1 e8 04             	shr    $0x4,%eax
80102634:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102637:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010263a:	83 e2 0f             	and    $0xf,%edx
8010263d:	01 d0                	add    %edx,%eax
8010263f:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
80102642:	8b 55 e0             	mov    -0x20(%ebp),%edx
80102645:	89 d0                	mov    %edx,%eax
80102647:	c1 e8 04             	shr    $0x4,%eax
8010264a:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010264d:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102650:	83 e2 0f             	and    $0xf,%edx
80102653:	01 d0                	add    %edx,%eax
80102655:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
80102658:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010265b:	89 d0                	mov    %edx,%eax
8010265d:	c1 e8 04             	shr    $0x4,%eax
80102660:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102663:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102666:	83 e2 0f             	and    $0xf,%edx
80102669:	01 d0                	add    %edx,%eax
8010266b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
8010266e:	8b 45 d0             	mov    -0x30(%ebp),%eax
80102671:	89 06                	mov    %eax,(%esi)
80102673:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102676:	89 46 04             	mov    %eax,0x4(%esi)
80102679:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010267c:	89 46 08             	mov    %eax,0x8(%esi)
8010267f:	8b 45 dc             	mov    -0x24(%ebp),%eax
80102682:	89 46 0c             	mov    %eax,0xc(%esi)
80102685:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102688:	89 46 10             	mov    %eax,0x10(%esi)
8010268b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010268e:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
80102691:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
80102698:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010269b:	5b                   	pop    %ebx
8010269c:	5e                   	pop    %esi
8010269d:	5f                   	pop    %edi
8010269e:	5d                   	pop    %ebp
8010269f:	c3                   	ret    

801026a0 <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
801026a0:	55                   	push   %ebp
801026a1:	89 e5                	mov    %esp,%ebp
801026a3:	53                   	push   %ebx
801026a4:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
801026a7:	ff 35 34 17 13 80    	pushl  0x80131734
801026ad:	ff 35 44 17 13 80    	pushl  0x80131744
801026b3:	e8 b4 da ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
801026b8:	8b 58 5c             	mov    0x5c(%eax),%ebx
801026bb:	89 1d 48 17 13 80    	mov    %ebx,0x80131748
  for (i = 0; i < log.lh.n; i++) {
801026c1:	83 c4 10             	add    $0x10,%esp
801026c4:	ba 00 00 00 00       	mov    $0x0,%edx
801026c9:	eb 0e                	jmp    801026d9 <read_head+0x39>
    log.lh.block[i] = lh->block[i];
801026cb:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
801026cf:	89 0c 95 4c 17 13 80 	mov    %ecx,-0x7fece8b4(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
801026d6:	83 c2 01             	add    $0x1,%edx
801026d9:	39 d3                	cmp    %edx,%ebx
801026db:	7f ee                	jg     801026cb <read_head+0x2b>
  }
  brelse(buf);
801026dd:	83 ec 0c             	sub    $0xc,%esp
801026e0:	50                   	push   %eax
801026e1:	e8 ef da ff ff       	call   801001d5 <brelse>
}
801026e6:	83 c4 10             	add    $0x10,%esp
801026e9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801026ec:	c9                   	leave  
801026ed:	c3                   	ret    

801026ee <install_trans>:
{
801026ee:	55                   	push   %ebp
801026ef:	89 e5                	mov    %esp,%ebp
801026f1:	57                   	push   %edi
801026f2:	56                   	push   %esi
801026f3:	53                   	push   %ebx
801026f4:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
801026f7:	bb 00 00 00 00       	mov    $0x0,%ebx
801026fc:	eb 66                	jmp    80102764 <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801026fe:	89 d8                	mov    %ebx,%eax
80102700:	03 05 34 17 13 80    	add    0x80131734,%eax
80102706:	83 c0 01             	add    $0x1,%eax
80102709:	83 ec 08             	sub    $0x8,%esp
8010270c:	50                   	push   %eax
8010270d:	ff 35 44 17 13 80    	pushl  0x80131744
80102713:	e8 54 da ff ff       	call   8010016c <bread>
80102718:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
8010271a:	83 c4 08             	add    $0x8,%esp
8010271d:	ff 34 9d 4c 17 13 80 	pushl  -0x7fece8b4(,%ebx,4)
80102724:	ff 35 44 17 13 80    	pushl  0x80131744
8010272a:	e8 3d da ff ff       	call   8010016c <bread>
8010272f:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80102731:	8d 57 5c             	lea    0x5c(%edi),%edx
80102734:	8d 40 5c             	lea    0x5c(%eax),%eax
80102737:	83 c4 0c             	add    $0xc,%esp
8010273a:	68 00 02 00 00       	push   $0x200
8010273f:	52                   	push   %edx
80102740:	50                   	push   %eax
80102741:	e8 bd 16 00 00       	call   80103e03 <memmove>
    bwrite(dbuf);  // write dst to disk
80102746:	89 34 24             	mov    %esi,(%esp)
80102749:	e8 4c da ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
8010274e:	89 3c 24             	mov    %edi,(%esp)
80102751:	e8 7f da ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
80102756:	89 34 24             	mov    %esi,(%esp)
80102759:	e8 77 da ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
8010275e:	83 c3 01             	add    $0x1,%ebx
80102761:	83 c4 10             	add    $0x10,%esp
80102764:	39 1d 48 17 13 80    	cmp    %ebx,0x80131748
8010276a:	7f 92                	jg     801026fe <install_trans+0x10>
}
8010276c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010276f:	5b                   	pop    %ebx
80102770:	5e                   	pop    %esi
80102771:	5f                   	pop    %edi
80102772:	5d                   	pop    %ebp
80102773:	c3                   	ret    

80102774 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80102774:	55                   	push   %ebp
80102775:	89 e5                	mov    %esp,%ebp
80102777:	53                   	push   %ebx
80102778:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
8010277b:	ff 35 34 17 13 80    	pushl  0x80131734
80102781:	ff 35 44 17 13 80    	pushl  0x80131744
80102787:	e8 e0 d9 ff ff       	call   8010016c <bread>
8010278c:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
8010278e:	8b 0d 48 17 13 80    	mov    0x80131748,%ecx
80102794:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
80102797:	83 c4 10             	add    $0x10,%esp
8010279a:	b8 00 00 00 00       	mov    $0x0,%eax
8010279f:	eb 0e                	jmp    801027af <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
801027a1:	8b 14 85 4c 17 13 80 	mov    -0x7fece8b4(,%eax,4),%edx
801027a8:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
801027ac:	83 c0 01             	add    $0x1,%eax
801027af:	39 c1                	cmp    %eax,%ecx
801027b1:	7f ee                	jg     801027a1 <write_head+0x2d>
  }
  bwrite(buf);
801027b3:	83 ec 0c             	sub    $0xc,%esp
801027b6:	53                   	push   %ebx
801027b7:	e8 de d9 ff ff       	call   8010019a <bwrite>
  brelse(buf);
801027bc:	89 1c 24             	mov    %ebx,(%esp)
801027bf:	e8 11 da ff ff       	call   801001d5 <brelse>
}
801027c4:	83 c4 10             	add    $0x10,%esp
801027c7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801027ca:	c9                   	leave  
801027cb:	c3                   	ret    

801027cc <recover_from_log>:

static void
recover_from_log(void)
{
801027cc:	55                   	push   %ebp
801027cd:	89 e5                	mov    %esp,%ebp
801027cf:	83 ec 08             	sub    $0x8,%esp
  read_head();
801027d2:	e8 c9 fe ff ff       	call   801026a0 <read_head>
  install_trans(); // if committed, copy from log to disk
801027d7:	e8 12 ff ff ff       	call   801026ee <install_trans>
  log.lh.n = 0;
801027dc:	c7 05 48 17 13 80 00 	movl   $0x0,0x80131748
801027e3:	00 00 00 
  write_head(); // clear the log
801027e6:	e8 89 ff ff ff       	call   80102774 <write_head>
}
801027eb:	c9                   	leave  
801027ec:	c3                   	ret    

801027ed <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
801027ed:	55                   	push   %ebp
801027ee:	89 e5                	mov    %esp,%ebp
801027f0:	57                   	push   %edi
801027f1:	56                   	push   %esi
801027f2:	53                   	push   %ebx
801027f3:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801027f6:	bb 00 00 00 00       	mov    $0x0,%ebx
801027fb:	eb 66                	jmp    80102863 <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
801027fd:	89 d8                	mov    %ebx,%eax
801027ff:	03 05 34 17 13 80    	add    0x80131734,%eax
80102805:	83 c0 01             	add    $0x1,%eax
80102808:	83 ec 08             	sub    $0x8,%esp
8010280b:	50                   	push   %eax
8010280c:	ff 35 44 17 13 80    	pushl  0x80131744
80102812:	e8 55 d9 ff ff       	call   8010016c <bread>
80102817:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80102819:	83 c4 08             	add    $0x8,%esp
8010281c:	ff 34 9d 4c 17 13 80 	pushl  -0x7fece8b4(,%ebx,4)
80102823:	ff 35 44 17 13 80    	pushl  0x80131744
80102829:	e8 3e d9 ff ff       	call   8010016c <bread>
8010282e:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
80102830:	8d 50 5c             	lea    0x5c(%eax),%edx
80102833:	8d 46 5c             	lea    0x5c(%esi),%eax
80102836:	83 c4 0c             	add    $0xc,%esp
80102839:	68 00 02 00 00       	push   $0x200
8010283e:	52                   	push   %edx
8010283f:	50                   	push   %eax
80102840:	e8 be 15 00 00       	call   80103e03 <memmove>
    bwrite(to);  // write the log
80102845:	89 34 24             	mov    %esi,(%esp)
80102848:	e8 4d d9 ff ff       	call   8010019a <bwrite>
    brelse(from);
8010284d:	89 3c 24             	mov    %edi,(%esp)
80102850:	e8 80 d9 ff ff       	call   801001d5 <brelse>
    brelse(to);
80102855:	89 34 24             	mov    %esi,(%esp)
80102858:	e8 78 d9 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
8010285d:	83 c3 01             	add    $0x1,%ebx
80102860:	83 c4 10             	add    $0x10,%esp
80102863:	39 1d 48 17 13 80    	cmp    %ebx,0x80131748
80102869:	7f 92                	jg     801027fd <write_log+0x10>
  }
}
8010286b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010286e:	5b                   	pop    %ebx
8010286f:	5e                   	pop    %esi
80102870:	5f                   	pop    %edi
80102871:	5d                   	pop    %ebp
80102872:	c3                   	ret    

80102873 <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
80102873:	83 3d 48 17 13 80 00 	cmpl   $0x0,0x80131748
8010287a:	7e 26                	jle    801028a2 <commit+0x2f>
{
8010287c:	55                   	push   %ebp
8010287d:	89 e5                	mov    %esp,%ebp
8010287f:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
80102882:	e8 66 ff ff ff       	call   801027ed <write_log>
    write_head();    // Write header to disk -- the real commit
80102887:	e8 e8 fe ff ff       	call   80102774 <write_head>
    install_trans(); // Now install writes to home locations
8010288c:	e8 5d fe ff ff       	call   801026ee <install_trans>
    log.lh.n = 0;
80102891:	c7 05 48 17 13 80 00 	movl   $0x0,0x80131748
80102898:	00 00 00 
    write_head();    // Erase the transaction from the log
8010289b:	e8 d4 fe ff ff       	call   80102774 <write_head>
  }
}
801028a0:	c9                   	leave  
801028a1:	c3                   	ret    
801028a2:	f3 c3                	repz ret 

801028a4 <initlog>:
{
801028a4:	55                   	push   %ebp
801028a5:	89 e5                	mov    %esp,%ebp
801028a7:	53                   	push   %ebx
801028a8:	83 ec 2c             	sub    $0x2c,%esp
801028ab:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
801028ae:	68 a0 6a 10 80       	push   $0x80106aa0
801028b3:	68 00 17 13 80       	push   $0x80131700
801028b8:	e8 e3 12 00 00       	call   80103ba0 <initlock>
  readsb(dev, &sb);
801028bd:	83 c4 08             	add    $0x8,%esp
801028c0:	8d 45 dc             	lea    -0x24(%ebp),%eax
801028c3:	50                   	push   %eax
801028c4:	53                   	push   %ebx
801028c5:	e8 6c e9 ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
801028ca:	8b 45 ec             	mov    -0x14(%ebp),%eax
801028cd:	a3 34 17 13 80       	mov    %eax,0x80131734
  log.size = sb.nlog;
801028d2:	8b 45 e8             	mov    -0x18(%ebp),%eax
801028d5:	a3 38 17 13 80       	mov    %eax,0x80131738
  log.dev = dev;
801028da:	89 1d 44 17 13 80    	mov    %ebx,0x80131744
  recover_from_log();
801028e0:	e8 e7 fe ff ff       	call   801027cc <recover_from_log>
}
801028e5:	83 c4 10             	add    $0x10,%esp
801028e8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801028eb:	c9                   	leave  
801028ec:	c3                   	ret    

801028ed <begin_op>:
{
801028ed:	55                   	push   %ebp
801028ee:	89 e5                	mov    %esp,%ebp
801028f0:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
801028f3:	68 00 17 13 80       	push   $0x80131700
801028f8:	e8 df 13 00 00       	call   80103cdc <acquire>
801028fd:	83 c4 10             	add    $0x10,%esp
80102900:	eb 15                	jmp    80102917 <begin_op+0x2a>
      sleep(&log, &log.lock);
80102902:	83 ec 08             	sub    $0x8,%esp
80102905:	68 00 17 13 80       	push   $0x80131700
8010290a:	68 00 17 13 80       	push   $0x80131700
8010290f:	e8 cd 0e 00 00       	call   801037e1 <sleep>
80102914:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
80102917:	83 3d 40 17 13 80 00 	cmpl   $0x0,0x80131740
8010291e:	75 e2                	jne    80102902 <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80102920:	a1 3c 17 13 80       	mov    0x8013173c,%eax
80102925:	83 c0 01             	add    $0x1,%eax
80102928:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010292b:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
8010292e:	03 15 48 17 13 80    	add    0x80131748,%edx
80102934:	83 fa 1e             	cmp    $0x1e,%edx
80102937:	7e 17                	jle    80102950 <begin_op+0x63>
      sleep(&log, &log.lock);
80102939:	83 ec 08             	sub    $0x8,%esp
8010293c:	68 00 17 13 80       	push   $0x80131700
80102941:	68 00 17 13 80       	push   $0x80131700
80102946:	e8 96 0e 00 00       	call   801037e1 <sleep>
8010294b:	83 c4 10             	add    $0x10,%esp
8010294e:	eb c7                	jmp    80102917 <begin_op+0x2a>
      log.outstanding += 1;
80102950:	a3 3c 17 13 80       	mov    %eax,0x8013173c
      release(&log.lock);
80102955:	83 ec 0c             	sub    $0xc,%esp
80102958:	68 00 17 13 80       	push   $0x80131700
8010295d:	e8 df 13 00 00       	call   80103d41 <release>
}
80102962:	83 c4 10             	add    $0x10,%esp
80102965:	c9                   	leave  
80102966:	c3                   	ret    

80102967 <end_op>:
{
80102967:	55                   	push   %ebp
80102968:	89 e5                	mov    %esp,%ebp
8010296a:	53                   	push   %ebx
8010296b:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
8010296e:	68 00 17 13 80       	push   $0x80131700
80102973:	e8 64 13 00 00       	call   80103cdc <acquire>
  log.outstanding -= 1;
80102978:	a1 3c 17 13 80       	mov    0x8013173c,%eax
8010297d:	83 e8 01             	sub    $0x1,%eax
80102980:	a3 3c 17 13 80       	mov    %eax,0x8013173c
  if(log.committing)
80102985:	8b 1d 40 17 13 80    	mov    0x80131740,%ebx
8010298b:	83 c4 10             	add    $0x10,%esp
8010298e:	85 db                	test   %ebx,%ebx
80102990:	75 2c                	jne    801029be <end_op+0x57>
  if(log.outstanding == 0){
80102992:	85 c0                	test   %eax,%eax
80102994:	75 35                	jne    801029cb <end_op+0x64>
    log.committing = 1;
80102996:	c7 05 40 17 13 80 01 	movl   $0x1,0x80131740
8010299d:	00 00 00 
    do_commit = 1;
801029a0:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
801029a5:	83 ec 0c             	sub    $0xc,%esp
801029a8:	68 00 17 13 80       	push   $0x80131700
801029ad:	e8 8f 13 00 00       	call   80103d41 <release>
  if(do_commit){
801029b2:	83 c4 10             	add    $0x10,%esp
801029b5:	85 db                	test   %ebx,%ebx
801029b7:	75 24                	jne    801029dd <end_op+0x76>
}
801029b9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801029bc:	c9                   	leave  
801029bd:	c3                   	ret    
    panic("log.committing");
801029be:	83 ec 0c             	sub    $0xc,%esp
801029c1:	68 a4 6a 10 80       	push   $0x80106aa4
801029c6:	e8 7d d9 ff ff       	call   80100348 <panic>
    wakeup(&log);
801029cb:	83 ec 0c             	sub    $0xc,%esp
801029ce:	68 00 17 13 80       	push   $0x80131700
801029d3:	e8 6e 0f 00 00       	call   80103946 <wakeup>
801029d8:	83 c4 10             	add    $0x10,%esp
801029db:	eb c8                	jmp    801029a5 <end_op+0x3e>
    commit();
801029dd:	e8 91 fe ff ff       	call   80102873 <commit>
    acquire(&log.lock);
801029e2:	83 ec 0c             	sub    $0xc,%esp
801029e5:	68 00 17 13 80       	push   $0x80131700
801029ea:	e8 ed 12 00 00       	call   80103cdc <acquire>
    log.committing = 0;
801029ef:	c7 05 40 17 13 80 00 	movl   $0x0,0x80131740
801029f6:	00 00 00 
    wakeup(&log);
801029f9:	c7 04 24 00 17 13 80 	movl   $0x80131700,(%esp)
80102a00:	e8 41 0f 00 00       	call   80103946 <wakeup>
    release(&log.lock);
80102a05:	c7 04 24 00 17 13 80 	movl   $0x80131700,(%esp)
80102a0c:	e8 30 13 00 00       	call   80103d41 <release>
80102a11:	83 c4 10             	add    $0x10,%esp
}
80102a14:	eb a3                	jmp    801029b9 <end_op+0x52>

80102a16 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80102a16:	55                   	push   %ebp
80102a17:	89 e5                	mov    %esp,%ebp
80102a19:	53                   	push   %ebx
80102a1a:	83 ec 04             	sub    $0x4,%esp
80102a1d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80102a20:	8b 15 48 17 13 80    	mov    0x80131748,%edx
80102a26:	83 fa 1d             	cmp    $0x1d,%edx
80102a29:	7f 45                	jg     80102a70 <log_write+0x5a>
80102a2b:	a1 38 17 13 80       	mov    0x80131738,%eax
80102a30:	83 e8 01             	sub    $0x1,%eax
80102a33:	39 c2                	cmp    %eax,%edx
80102a35:	7d 39                	jge    80102a70 <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102a37:	83 3d 3c 17 13 80 00 	cmpl   $0x0,0x8013173c
80102a3e:	7e 3d                	jle    80102a7d <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102a40:	83 ec 0c             	sub    $0xc,%esp
80102a43:	68 00 17 13 80       	push   $0x80131700
80102a48:	e8 8f 12 00 00       	call   80103cdc <acquire>
  for (i = 0; i < log.lh.n; i++) {
80102a4d:	83 c4 10             	add    $0x10,%esp
80102a50:	b8 00 00 00 00       	mov    $0x0,%eax
80102a55:	8b 15 48 17 13 80    	mov    0x80131748,%edx
80102a5b:	39 c2                	cmp    %eax,%edx
80102a5d:	7e 2b                	jle    80102a8a <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102a5f:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102a62:	39 0c 85 4c 17 13 80 	cmp    %ecx,-0x7fece8b4(,%eax,4)
80102a69:	74 1f                	je     80102a8a <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
80102a6b:	83 c0 01             	add    $0x1,%eax
80102a6e:	eb e5                	jmp    80102a55 <log_write+0x3f>
    panic("too big a transaction");
80102a70:	83 ec 0c             	sub    $0xc,%esp
80102a73:	68 b3 6a 10 80       	push   $0x80106ab3
80102a78:	e8 cb d8 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102a7d:	83 ec 0c             	sub    $0xc,%esp
80102a80:	68 c9 6a 10 80       	push   $0x80106ac9
80102a85:	e8 be d8 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102a8a:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102a8d:	89 0c 85 4c 17 13 80 	mov    %ecx,-0x7fece8b4(,%eax,4)
  if (i == log.lh.n)
80102a94:	39 c2                	cmp    %eax,%edx
80102a96:	74 18                	je     80102ab0 <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102a98:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102a9b:	83 ec 0c             	sub    $0xc,%esp
80102a9e:	68 00 17 13 80       	push   $0x80131700
80102aa3:	e8 99 12 00 00       	call   80103d41 <release>
}
80102aa8:	83 c4 10             	add    $0x10,%esp
80102aab:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102aae:	c9                   	leave  
80102aaf:	c3                   	ret    
    log.lh.n++;
80102ab0:	83 c2 01             	add    $0x1,%edx
80102ab3:	89 15 48 17 13 80    	mov    %edx,0x80131748
80102ab9:	eb dd                	jmp    80102a98 <log_write+0x82>

80102abb <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102abb:	55                   	push   %ebp
80102abc:	89 e5                	mov    %esp,%ebp
80102abe:	53                   	push   %ebx
80102abf:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102ac2:	68 8a 00 00 00       	push   $0x8a
80102ac7:	68 8c 94 10 80       	push   $0x8010948c
80102acc:	68 00 70 00 80       	push   $0x80007000
80102ad1:	e8 2d 13 00 00       	call   80103e03 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102ad6:	83 c4 10             	add    $0x10,%esp
80102ad9:	bb 00 18 13 80       	mov    $0x80131800,%ebx
80102ade:	eb 06                	jmp    80102ae6 <startothers+0x2b>
80102ae0:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102ae6:	69 05 80 1d 13 80 b0 	imul   $0xb0,0x80131d80,%eax
80102aed:	00 00 00 
80102af0:	05 00 18 13 80       	add    $0x80131800,%eax
80102af5:	39 d8                	cmp    %ebx,%eax
80102af7:	76 4c                	jbe    80102b45 <startothers+0x8a>
    if(c == mycpu())  // We've started already.
80102af9:	e8 c8 07 00 00       	call   801032c6 <mycpu>
80102afe:	39 d8                	cmp    %ebx,%eax
80102b00:	74 de                	je     80102ae0 <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80102b02:	e8 c1 f5 ff ff       	call   801020c8 <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102b07:	05 00 10 00 00       	add    $0x1000,%eax
80102b0c:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102b11:	c7 05 f8 6f 00 80 89 	movl   $0x80102b89,0x80006ff8
80102b18:	2b 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102b1b:	c7 05 f4 6f 00 80 00 	movl   $0x108000,0x80006ff4
80102b22:	80 10 00 

    lapicstartap(c->apicid, V2P(code));
80102b25:	83 ec 08             	sub    $0x8,%esp
80102b28:	68 00 70 00 00       	push   $0x7000
80102b2d:	0f b6 03             	movzbl (%ebx),%eax
80102b30:	50                   	push   %eax
80102b31:	e8 c6 f9 ff ff       	call   801024fc <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102b36:	83 c4 10             	add    $0x10,%esp
80102b39:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102b3f:	85 c0                	test   %eax,%eax
80102b41:	74 f6                	je     80102b39 <startothers+0x7e>
80102b43:	eb 9b                	jmp    80102ae0 <startothers+0x25>
      ;
  }
}
80102b45:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102b48:	c9                   	leave  
80102b49:	c3                   	ret    

80102b4a <mpmain>:
{
80102b4a:	55                   	push   %ebp
80102b4b:	89 e5                	mov    %esp,%ebp
80102b4d:	53                   	push   %ebx
80102b4e:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102b51:	e8 cc 07 00 00       	call   80103322 <cpuid>
80102b56:	89 c3                	mov    %eax,%ebx
80102b58:	e8 c5 07 00 00       	call   80103322 <cpuid>
80102b5d:	83 ec 04             	sub    $0x4,%esp
80102b60:	53                   	push   %ebx
80102b61:	50                   	push   %eax
80102b62:	68 e4 6a 10 80       	push   $0x80106ae4
80102b67:	e8 9f da ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102b6c:	e8 e9 23 00 00       	call   80104f5a <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102b71:	e8 50 07 00 00       	call   801032c6 <mycpu>
80102b76:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102b78:	b8 01 00 00 00       	mov    $0x1,%eax
80102b7d:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102b84:	e8 33 0a 00 00       	call   801035bc <scheduler>

80102b89 <mpenter>:
{
80102b89:	55                   	push   %ebp
80102b8a:	89 e5                	mov    %esp,%ebp
80102b8c:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102b8f:	e8 d7 33 00 00       	call   80105f6b <switchkvm>
  seginit();
80102b94:	e8 86 32 00 00       	call   80105e1f <seginit>
  lapicinit();
80102b99:	e8 15 f8 ff ff       	call   801023b3 <lapicinit>
  mpmain();
80102b9e:	e8 a7 ff ff ff       	call   80102b4a <mpmain>

80102ba3 <main>:
{
80102ba3:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102ba7:	83 e4 f0             	and    $0xfffffff0,%esp
80102baa:	ff 71 fc             	pushl  -0x4(%ecx)
80102bad:	55                   	push   %ebp
80102bae:	89 e5                	mov    %esp,%ebp
80102bb0:	51                   	push   %ecx
80102bb1:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102bb4:	68 00 00 40 80       	push   $0x80400000
80102bb9:	68 28 45 13 80       	push   $0x80134528
80102bbe:	e8 a6 f4 ff ff       	call   80102069 <kinit1>
  kvmalloc();      // kernel page table
80102bc3:	e8 4b 38 00 00       	call   80106413 <kvmalloc>
  mpinit();        // detect other processors
80102bc8:	e8 c9 01 00 00       	call   80102d96 <mpinit>
  lapicinit();     // interrupt controller
80102bcd:	e8 e1 f7 ff ff       	call   801023b3 <lapicinit>
  seginit();       // segment descriptors
80102bd2:	e8 48 32 00 00       	call   80105e1f <seginit>
  picinit();       // disable pic
80102bd7:	e8 82 02 00 00       	call   80102e5e <picinit>
  ioapicinit();    // another interrupt controller
80102bdc:	e8 19 f3 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102be1:	e8 a8 dc ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102be6:	e8 1d 26 00 00       	call   80105208 <uartinit>
  pinit();         // process table
80102beb:	e8 bc 06 00 00       	call   801032ac <pinit>
  tvinit();        // trap vectors
80102bf0:	e8 b4 22 00 00       	call   80104ea9 <tvinit>
  binit();         // buffer cache
80102bf5:	e8 fa d4 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102bfa:	e8 14 e0 ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102bff:	e8 fc f0 ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102c04:	e8 b2 fe ff ff       	call   80102abb <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102c09:	83 c4 08             	add    $0x8,%esp
80102c0c:	68 00 00 00 8e       	push   $0x8e000000
80102c11:	68 00 00 40 80       	push   $0x80400000
80102c16:	e8 80 f4 ff ff       	call   8010209b <kinit2>
  userinit();      // first user process
80102c1b:	e8 41 07 00 00       	call   80103361 <userinit>
  mpmain();        // finish this processor's setup
80102c20:	e8 25 ff ff ff       	call   80102b4a <mpmain>

80102c25 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102c25:	55                   	push   %ebp
80102c26:	89 e5                	mov    %esp,%ebp
80102c28:	56                   	push   %esi
80102c29:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102c2a:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102c2f:	b9 00 00 00 00       	mov    $0x0,%ecx
80102c34:	eb 09                	jmp    80102c3f <sum+0x1a>
    sum += addr[i];
80102c36:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102c3a:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102c3c:	83 c1 01             	add    $0x1,%ecx
80102c3f:	39 d1                	cmp    %edx,%ecx
80102c41:	7c f3                	jl     80102c36 <sum+0x11>
  return sum;
}
80102c43:	89 d8                	mov    %ebx,%eax
80102c45:	5b                   	pop    %ebx
80102c46:	5e                   	pop    %esi
80102c47:	5d                   	pop    %ebp
80102c48:	c3                   	ret    

80102c49 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102c49:	55                   	push   %ebp
80102c4a:	89 e5                	mov    %esp,%ebp
80102c4c:	56                   	push   %esi
80102c4d:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102c4e:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102c54:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102c56:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102c58:	eb 03                	jmp    80102c5d <mpsearch1+0x14>
80102c5a:	83 c3 10             	add    $0x10,%ebx
80102c5d:	39 f3                	cmp    %esi,%ebx
80102c5f:	73 29                	jae    80102c8a <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102c61:	83 ec 04             	sub    $0x4,%esp
80102c64:	6a 04                	push   $0x4
80102c66:	68 f8 6a 10 80       	push   $0x80106af8
80102c6b:	53                   	push   %ebx
80102c6c:	e8 5d 11 00 00       	call   80103dce <memcmp>
80102c71:	83 c4 10             	add    $0x10,%esp
80102c74:	85 c0                	test   %eax,%eax
80102c76:	75 e2                	jne    80102c5a <mpsearch1+0x11>
80102c78:	ba 10 00 00 00       	mov    $0x10,%edx
80102c7d:	89 d8                	mov    %ebx,%eax
80102c7f:	e8 a1 ff ff ff       	call   80102c25 <sum>
80102c84:	84 c0                	test   %al,%al
80102c86:	75 d2                	jne    80102c5a <mpsearch1+0x11>
80102c88:	eb 05                	jmp    80102c8f <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102c8a:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102c8f:	89 d8                	mov    %ebx,%eax
80102c91:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102c94:	5b                   	pop    %ebx
80102c95:	5e                   	pop    %esi
80102c96:	5d                   	pop    %ebp
80102c97:	c3                   	ret    

80102c98 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102c98:	55                   	push   %ebp
80102c99:	89 e5                	mov    %esp,%ebp
80102c9b:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102c9e:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102ca5:	c1 e0 08             	shl    $0x8,%eax
80102ca8:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102caf:	09 d0                	or     %edx,%eax
80102cb1:	c1 e0 04             	shl    $0x4,%eax
80102cb4:	85 c0                	test   %eax,%eax
80102cb6:	74 1f                	je     80102cd7 <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102cb8:	ba 00 04 00 00       	mov    $0x400,%edx
80102cbd:	e8 87 ff ff ff       	call   80102c49 <mpsearch1>
80102cc2:	85 c0                	test   %eax,%eax
80102cc4:	75 0f                	jne    80102cd5 <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102cc6:	ba 00 00 01 00       	mov    $0x10000,%edx
80102ccb:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102cd0:	e8 74 ff ff ff       	call   80102c49 <mpsearch1>
}
80102cd5:	c9                   	leave  
80102cd6:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102cd7:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102cde:	c1 e0 08             	shl    $0x8,%eax
80102ce1:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102ce8:	09 d0                	or     %edx,%eax
80102cea:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102ced:	2d 00 04 00 00       	sub    $0x400,%eax
80102cf2:	ba 00 04 00 00       	mov    $0x400,%edx
80102cf7:	e8 4d ff ff ff       	call   80102c49 <mpsearch1>
80102cfc:	85 c0                	test   %eax,%eax
80102cfe:	75 d5                	jne    80102cd5 <mpsearch+0x3d>
80102d00:	eb c4                	jmp    80102cc6 <mpsearch+0x2e>

80102d02 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102d02:	55                   	push   %ebp
80102d03:	89 e5                	mov    %esp,%ebp
80102d05:	57                   	push   %edi
80102d06:	56                   	push   %esi
80102d07:	53                   	push   %ebx
80102d08:	83 ec 1c             	sub    $0x1c,%esp
80102d0b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102d0e:	e8 85 ff ff ff       	call   80102c98 <mpsearch>
80102d13:	85 c0                	test   %eax,%eax
80102d15:	74 5c                	je     80102d73 <mpconfig+0x71>
80102d17:	89 c7                	mov    %eax,%edi
80102d19:	8b 58 04             	mov    0x4(%eax),%ebx
80102d1c:	85 db                	test   %ebx,%ebx
80102d1e:	74 5a                	je     80102d7a <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102d20:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102d26:	83 ec 04             	sub    $0x4,%esp
80102d29:	6a 04                	push   $0x4
80102d2b:	68 fd 6a 10 80       	push   $0x80106afd
80102d30:	56                   	push   %esi
80102d31:	e8 98 10 00 00       	call   80103dce <memcmp>
80102d36:	83 c4 10             	add    $0x10,%esp
80102d39:	85 c0                	test   %eax,%eax
80102d3b:	75 44                	jne    80102d81 <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102d3d:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102d44:	3c 01                	cmp    $0x1,%al
80102d46:	0f 95 c2             	setne  %dl
80102d49:	3c 04                	cmp    $0x4,%al
80102d4b:	0f 95 c0             	setne  %al
80102d4e:	84 c2                	test   %al,%dl
80102d50:	75 36                	jne    80102d88 <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102d52:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102d59:	89 f0                	mov    %esi,%eax
80102d5b:	e8 c5 fe ff ff       	call   80102c25 <sum>
80102d60:	84 c0                	test   %al,%al
80102d62:	75 2b                	jne    80102d8f <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102d64:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102d67:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102d69:	89 f0                	mov    %esi,%eax
80102d6b:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102d6e:	5b                   	pop    %ebx
80102d6f:	5e                   	pop    %esi
80102d70:	5f                   	pop    %edi
80102d71:	5d                   	pop    %ebp
80102d72:	c3                   	ret    
    return 0;
80102d73:	be 00 00 00 00       	mov    $0x0,%esi
80102d78:	eb ef                	jmp    80102d69 <mpconfig+0x67>
80102d7a:	be 00 00 00 00       	mov    $0x0,%esi
80102d7f:	eb e8                	jmp    80102d69 <mpconfig+0x67>
    return 0;
80102d81:	be 00 00 00 00       	mov    $0x0,%esi
80102d86:	eb e1                	jmp    80102d69 <mpconfig+0x67>
    return 0;
80102d88:	be 00 00 00 00       	mov    $0x0,%esi
80102d8d:	eb da                	jmp    80102d69 <mpconfig+0x67>
    return 0;
80102d8f:	be 00 00 00 00       	mov    $0x0,%esi
80102d94:	eb d3                	jmp    80102d69 <mpconfig+0x67>

80102d96 <mpinit>:

void
mpinit(void)
{
80102d96:	55                   	push   %ebp
80102d97:	89 e5                	mov    %esp,%ebp
80102d99:	57                   	push   %edi
80102d9a:	56                   	push   %esi
80102d9b:	53                   	push   %ebx
80102d9c:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102d9f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102da2:	e8 5b ff ff ff       	call   80102d02 <mpconfig>
80102da7:	85 c0                	test   %eax,%eax
80102da9:	74 19                	je     80102dc4 <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102dab:	8b 50 24             	mov    0x24(%eax),%edx
80102dae:	89 15 e4 16 13 80    	mov    %edx,0x801316e4
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102db4:	8d 50 2c             	lea    0x2c(%eax),%edx
80102db7:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102dbb:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102dbd:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102dc2:	eb 34                	jmp    80102df8 <mpinit+0x62>
    panic("Expect to run on an SMP");
80102dc4:	83 ec 0c             	sub    $0xc,%esp
80102dc7:	68 02 6b 10 80       	push   $0x80106b02
80102dcc:	e8 77 d5 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102dd1:	8b 35 80 1d 13 80    	mov    0x80131d80,%esi
80102dd7:	83 fe 07             	cmp    $0x7,%esi
80102dda:	7f 19                	jg     80102df5 <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102ddc:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102de0:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102de6:	88 87 00 18 13 80    	mov    %al,-0x7fece800(%edi)
        ncpu++;
80102dec:	83 c6 01             	add    $0x1,%esi
80102def:	89 35 80 1d 13 80    	mov    %esi,0x80131d80
      }
      p += sizeof(struct mpproc);
80102df5:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102df8:	39 ca                	cmp    %ecx,%edx
80102dfa:	73 2b                	jae    80102e27 <mpinit+0x91>
    switch(*p){
80102dfc:	0f b6 02             	movzbl (%edx),%eax
80102dff:	3c 04                	cmp    $0x4,%al
80102e01:	77 1d                	ja     80102e20 <mpinit+0x8a>
80102e03:	0f b6 c0             	movzbl %al,%eax
80102e06:	ff 24 85 3c 6b 10 80 	jmp    *-0x7fef94c4(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102e0d:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102e11:	a2 e0 17 13 80       	mov    %al,0x801317e0
      p += sizeof(struct mpioapic);
80102e16:	83 c2 08             	add    $0x8,%edx
      continue;
80102e19:	eb dd                	jmp    80102df8 <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102e1b:	83 c2 08             	add    $0x8,%edx
      continue;
80102e1e:	eb d8                	jmp    80102df8 <mpinit+0x62>
    default:
      ismp = 0;
80102e20:	bb 00 00 00 00       	mov    $0x0,%ebx
80102e25:	eb d1                	jmp    80102df8 <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102e27:	85 db                	test   %ebx,%ebx
80102e29:	74 26                	je     80102e51 <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102e2b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102e2e:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102e32:	74 15                	je     80102e49 <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e34:	b8 70 00 00 00       	mov    $0x70,%eax
80102e39:	ba 22 00 00 00       	mov    $0x22,%edx
80102e3e:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102e3f:	ba 23 00 00 00       	mov    $0x23,%edx
80102e44:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102e45:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e48:	ee                   	out    %al,(%dx)
  }
}
80102e49:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102e4c:	5b                   	pop    %ebx
80102e4d:	5e                   	pop    %esi
80102e4e:	5f                   	pop    %edi
80102e4f:	5d                   	pop    %ebp
80102e50:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102e51:	83 ec 0c             	sub    $0xc,%esp
80102e54:	68 1c 6b 10 80       	push   $0x80106b1c
80102e59:	e8 ea d4 ff ff       	call   80100348 <panic>

80102e5e <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102e5e:	55                   	push   %ebp
80102e5f:	89 e5                	mov    %esp,%ebp
80102e61:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102e66:	ba 21 00 00 00       	mov    $0x21,%edx
80102e6b:	ee                   	out    %al,(%dx)
80102e6c:	ba a1 00 00 00       	mov    $0xa1,%edx
80102e71:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102e72:	5d                   	pop    %ebp
80102e73:	c3                   	ret    

80102e74 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102e74:	55                   	push   %ebp
80102e75:	89 e5                	mov    %esp,%ebp
80102e77:	57                   	push   %edi
80102e78:	56                   	push   %esi
80102e79:	53                   	push   %ebx
80102e7a:	83 ec 0c             	sub    $0xc,%esp
80102e7d:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102e80:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102e83:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102e89:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102e8f:	e8 99 dd ff ff       	call   80100c2d <filealloc>
80102e94:	89 03                	mov    %eax,(%ebx)
80102e96:	85 c0                	test   %eax,%eax
80102e98:	74 1e                	je     80102eb8 <pipealloc+0x44>
80102e9a:	e8 8e dd ff ff       	call   80100c2d <filealloc>
80102e9f:	89 06                	mov    %eax,(%esi)
80102ea1:	85 c0                	test   %eax,%eax
80102ea3:	74 13                	je     80102eb8 <pipealloc+0x44>
    goto bad;
  if((p = (struct pipe*)kalloc2(-2)) == 0)
80102ea5:	83 ec 0c             	sub    $0xc,%esp
80102ea8:	6a fe                	push   $0xfffffffe
80102eaa:	e8 b1 f2 ff ff       	call   80102160 <kalloc2>
80102eaf:	89 c7                	mov    %eax,%edi
80102eb1:	83 c4 10             	add    $0x10,%esp
80102eb4:	85 c0                	test   %eax,%eax
80102eb6:	75 35                	jne    80102eed <pipealloc+0x79>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102eb8:	8b 03                	mov    (%ebx),%eax
80102eba:	85 c0                	test   %eax,%eax
80102ebc:	74 0c                	je     80102eca <pipealloc+0x56>
    fileclose(*f0);
80102ebe:	83 ec 0c             	sub    $0xc,%esp
80102ec1:	50                   	push   %eax
80102ec2:	e8 0c de ff ff       	call   80100cd3 <fileclose>
80102ec7:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102eca:	8b 06                	mov    (%esi),%eax
80102ecc:	85 c0                	test   %eax,%eax
80102ece:	0f 84 8b 00 00 00    	je     80102f5f <pipealloc+0xeb>
    fileclose(*f1);
80102ed4:	83 ec 0c             	sub    $0xc,%esp
80102ed7:	50                   	push   %eax
80102ed8:	e8 f6 dd ff ff       	call   80100cd3 <fileclose>
80102edd:	83 c4 10             	add    $0x10,%esp
  return -1;
80102ee0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102ee5:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102ee8:	5b                   	pop    %ebx
80102ee9:	5e                   	pop    %esi
80102eea:	5f                   	pop    %edi
80102eeb:	5d                   	pop    %ebp
80102eec:	c3                   	ret    
  p->readopen = 1;
80102eed:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102ef4:	00 00 00 
  p->writeopen = 1;
80102ef7:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102efe:	00 00 00 
  p->nwrite = 0;
80102f01:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102f08:	00 00 00 
  p->nread = 0;
80102f0b:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102f12:	00 00 00 
  initlock(&p->lock, "pipe");
80102f15:	83 ec 08             	sub    $0x8,%esp
80102f18:	68 50 6b 10 80       	push   $0x80106b50
80102f1d:	50                   	push   %eax
80102f1e:	e8 7d 0c 00 00       	call   80103ba0 <initlock>
  (*f0)->type = FD_PIPE;
80102f23:	8b 03                	mov    (%ebx),%eax
80102f25:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102f2b:	8b 03                	mov    (%ebx),%eax
80102f2d:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102f31:	8b 03                	mov    (%ebx),%eax
80102f33:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102f37:	8b 03                	mov    (%ebx),%eax
80102f39:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80102f3c:	8b 06                	mov    (%esi),%eax
80102f3e:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80102f44:	8b 06                	mov    (%esi),%eax
80102f46:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80102f4a:	8b 06                	mov    (%esi),%eax
80102f4c:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80102f50:	8b 06                	mov    (%esi),%eax
80102f52:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80102f55:	83 c4 10             	add    $0x10,%esp
80102f58:	b8 00 00 00 00       	mov    $0x0,%eax
80102f5d:	eb 86                	jmp    80102ee5 <pipealloc+0x71>
  return -1;
80102f5f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102f64:	e9 7c ff ff ff       	jmp    80102ee5 <pipealloc+0x71>

80102f69 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80102f69:	55                   	push   %ebp
80102f6a:	89 e5                	mov    %esp,%ebp
80102f6c:	53                   	push   %ebx
80102f6d:	83 ec 10             	sub    $0x10,%esp
80102f70:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80102f73:	53                   	push   %ebx
80102f74:	e8 63 0d 00 00       	call   80103cdc <acquire>
  if(writable){
80102f79:	83 c4 10             	add    $0x10,%esp
80102f7c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102f80:	74 3f                	je     80102fc1 <pipeclose+0x58>
    p->writeopen = 0;
80102f82:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80102f89:	00 00 00 
    wakeup(&p->nread);
80102f8c:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102f92:	83 ec 0c             	sub    $0xc,%esp
80102f95:	50                   	push   %eax
80102f96:	e8 ab 09 00 00       	call   80103946 <wakeup>
80102f9b:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80102f9e:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102fa5:	75 09                	jne    80102fb0 <pipeclose+0x47>
80102fa7:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80102fae:	74 2f                	je     80102fdf <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80102fb0:	83 ec 0c             	sub    $0xc,%esp
80102fb3:	53                   	push   %ebx
80102fb4:	e8 88 0d 00 00       	call   80103d41 <release>
80102fb9:	83 c4 10             	add    $0x10,%esp
}
80102fbc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102fbf:	c9                   	leave  
80102fc0:	c3                   	ret    
    p->readopen = 0;
80102fc1:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
80102fc8:	00 00 00 
    wakeup(&p->nwrite);
80102fcb:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102fd1:	83 ec 0c             	sub    $0xc,%esp
80102fd4:	50                   	push   %eax
80102fd5:	e8 6c 09 00 00       	call   80103946 <wakeup>
80102fda:	83 c4 10             	add    $0x10,%esp
80102fdd:	eb bf                	jmp    80102f9e <pipeclose+0x35>
    release(&p->lock);
80102fdf:	83 ec 0c             	sub    $0xc,%esp
80102fe2:	53                   	push   %ebx
80102fe3:	e8 59 0d 00 00       	call   80103d41 <release>
    kfree((char*)p);
80102fe8:	89 1c 24             	mov    %ebx,(%esp)
80102feb:	e8 b4 ef ff ff       	call   80101fa4 <kfree>
80102ff0:	83 c4 10             	add    $0x10,%esp
80102ff3:	eb c7                	jmp    80102fbc <pipeclose+0x53>

80102ff5 <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
80102ff5:	55                   	push   %ebp
80102ff6:	89 e5                	mov    %esp,%ebp
80102ff8:	57                   	push   %edi
80102ff9:	56                   	push   %esi
80102ffa:	53                   	push   %ebx
80102ffb:	83 ec 18             	sub    $0x18,%esp
80102ffe:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80103001:	89 de                	mov    %ebx,%esi
80103003:	53                   	push   %ebx
80103004:	e8 d3 0c 00 00       	call   80103cdc <acquire>
  for(i = 0; i < n; i++){
80103009:	83 c4 10             	add    $0x10,%esp
8010300c:	bf 00 00 00 00       	mov    $0x0,%edi
80103011:	3b 7d 10             	cmp    0x10(%ebp),%edi
80103014:	0f 8d 88 00 00 00    	jge    801030a2 <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010301a:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
80103020:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103026:	05 00 02 00 00       	add    $0x200,%eax
8010302b:	39 c2                	cmp    %eax,%edx
8010302d:	75 51                	jne    80103080 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
8010302f:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80103036:	74 2f                	je     80103067 <pipewrite+0x72>
80103038:	e8 00 03 00 00       	call   8010333d <myproc>
8010303d:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80103041:	75 24                	jne    80103067 <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
80103043:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103049:	83 ec 0c             	sub    $0xc,%esp
8010304c:	50                   	push   %eax
8010304d:	e8 f4 08 00 00       	call   80103946 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103052:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103058:	83 c4 08             	add    $0x8,%esp
8010305b:	56                   	push   %esi
8010305c:	50                   	push   %eax
8010305d:	e8 7f 07 00 00       	call   801037e1 <sleep>
80103062:	83 c4 10             	add    $0x10,%esp
80103065:	eb b3                	jmp    8010301a <pipewrite+0x25>
        release(&p->lock);
80103067:	83 ec 0c             	sub    $0xc,%esp
8010306a:	53                   	push   %ebx
8010306b:	e8 d1 0c 00 00       	call   80103d41 <release>
        return -1;
80103070:	83 c4 10             	add    $0x10,%esp
80103073:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
80103078:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010307b:	5b                   	pop    %ebx
8010307c:	5e                   	pop    %esi
8010307d:	5f                   	pop    %edi
8010307e:	5d                   	pop    %ebp
8010307f:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103080:	8d 42 01             	lea    0x1(%edx),%eax
80103083:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80103089:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
8010308f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103092:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
80103096:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
8010309a:	83 c7 01             	add    $0x1,%edi
8010309d:	e9 6f ff ff ff       	jmp    80103011 <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
801030a2:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801030a8:	83 ec 0c             	sub    $0xc,%esp
801030ab:	50                   	push   %eax
801030ac:	e8 95 08 00 00       	call   80103946 <wakeup>
  release(&p->lock);
801030b1:	89 1c 24             	mov    %ebx,(%esp)
801030b4:	e8 88 0c 00 00       	call   80103d41 <release>
  return n;
801030b9:	83 c4 10             	add    $0x10,%esp
801030bc:	8b 45 10             	mov    0x10(%ebp),%eax
801030bf:	eb b7                	jmp    80103078 <pipewrite+0x83>

801030c1 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801030c1:	55                   	push   %ebp
801030c2:	89 e5                	mov    %esp,%ebp
801030c4:	57                   	push   %edi
801030c5:	56                   	push   %esi
801030c6:	53                   	push   %ebx
801030c7:	83 ec 18             	sub    $0x18,%esp
801030ca:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
801030cd:	89 df                	mov    %ebx,%edi
801030cf:	53                   	push   %ebx
801030d0:	e8 07 0c 00 00       	call   80103cdc <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801030d5:	83 c4 10             	add    $0x10,%esp
801030d8:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
801030de:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
801030e4:	75 3d                	jne    80103123 <piperead+0x62>
801030e6:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
801030ec:	85 f6                	test   %esi,%esi
801030ee:	74 38                	je     80103128 <piperead+0x67>
    if(myproc()->killed){
801030f0:	e8 48 02 00 00       	call   8010333d <myproc>
801030f5:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801030f9:	75 15                	jne    80103110 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801030fb:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103101:	83 ec 08             	sub    $0x8,%esp
80103104:	57                   	push   %edi
80103105:	50                   	push   %eax
80103106:	e8 d6 06 00 00       	call   801037e1 <sleep>
8010310b:	83 c4 10             	add    $0x10,%esp
8010310e:	eb c8                	jmp    801030d8 <piperead+0x17>
      release(&p->lock);
80103110:	83 ec 0c             	sub    $0xc,%esp
80103113:	53                   	push   %ebx
80103114:	e8 28 0c 00 00       	call   80103d41 <release>
      return -1;
80103119:	83 c4 10             	add    $0x10,%esp
8010311c:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103121:	eb 50                	jmp    80103173 <piperead+0xb2>
80103123:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103128:	3b 75 10             	cmp    0x10(%ebp),%esi
8010312b:	7d 2c                	jge    80103159 <piperead+0x98>
    if(p->nread == p->nwrite)
8010312d:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103133:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
80103139:	74 1e                	je     80103159 <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
8010313b:	8d 50 01             	lea    0x1(%eax),%edx
8010313e:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
80103144:	25 ff 01 00 00       	and    $0x1ff,%eax
80103149:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
8010314e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103151:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103154:	83 c6 01             	add    $0x1,%esi
80103157:	eb cf                	jmp    80103128 <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80103159:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
8010315f:	83 ec 0c             	sub    $0xc,%esp
80103162:	50                   	push   %eax
80103163:	e8 de 07 00 00       	call   80103946 <wakeup>
  release(&p->lock);
80103168:	89 1c 24             	mov    %ebx,(%esp)
8010316b:	e8 d1 0b 00 00       	call   80103d41 <release>
  return i;
80103170:	83 c4 10             	add    $0x10,%esp
}
80103173:	89 f0                	mov    %esi,%eax
80103175:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103178:	5b                   	pop    %ebx
80103179:	5e                   	pop    %esi
8010317a:	5f                   	pop    %edi
8010317b:	5d                   	pop    %ebp
8010317c:	c3                   	ret    

8010317d <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
8010317d:	55                   	push   %ebp
8010317e:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103180:	ba d4 1d 13 80       	mov    $0x80131dd4,%edx
80103185:	eb 03                	jmp    8010318a <wakeup1+0xd>
80103187:	83 c2 7c             	add    $0x7c,%edx
8010318a:	81 fa d4 3c 13 80    	cmp    $0x80133cd4,%edx
80103190:	73 14                	jae    801031a6 <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
80103192:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
80103196:	75 ef                	jne    80103187 <wakeup1+0xa>
80103198:	39 42 20             	cmp    %eax,0x20(%edx)
8010319b:	75 ea                	jne    80103187 <wakeup1+0xa>
      p->state = RUNNABLE;
8010319d:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
801031a4:	eb e1                	jmp    80103187 <wakeup1+0xa>
}
801031a6:	5d                   	pop    %ebp
801031a7:	c3                   	ret    

801031a8 <allocproc>:
{
801031a8:	55                   	push   %ebp
801031a9:	89 e5                	mov    %esp,%ebp
801031ab:	53                   	push   %ebx
801031ac:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
801031af:	68 a0 1d 13 80       	push   $0x80131da0
801031b4:	e8 23 0b 00 00       	call   80103cdc <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801031b9:	83 c4 10             	add    $0x10,%esp
801031bc:	bb d4 1d 13 80       	mov    $0x80131dd4,%ebx
801031c1:	81 fb d4 3c 13 80    	cmp    $0x80133cd4,%ebx
801031c7:	73 0b                	jae    801031d4 <allocproc+0x2c>
    if(p->state == UNUSED)
801031c9:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
801031cd:	74 1c                	je     801031eb <allocproc+0x43>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801031cf:	83 c3 7c             	add    $0x7c,%ebx
801031d2:	eb ed                	jmp    801031c1 <allocproc+0x19>
  release(&ptable.lock);
801031d4:	83 ec 0c             	sub    $0xc,%esp
801031d7:	68 a0 1d 13 80       	push   $0x80131da0
801031dc:	e8 60 0b 00 00       	call   80103d41 <release>
  return 0;
801031e1:	83 c4 10             	add    $0x10,%esp
801031e4:	bb 00 00 00 00       	mov    $0x0,%ebx
801031e9:	eb 69                	jmp    80103254 <allocproc+0xac>
  p->state = EMBRYO;
801031eb:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
801031f2:	a1 04 90 10 80       	mov    0x80109004,%eax
801031f7:	8d 50 01             	lea    0x1(%eax),%edx
801031fa:	89 15 04 90 10 80    	mov    %edx,0x80109004
80103200:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
80103203:	83 ec 0c             	sub    $0xc,%esp
80103206:	68 a0 1d 13 80       	push   $0x80131da0
8010320b:	e8 31 0b 00 00       	call   80103d41 <release>
  if((p->kstack = kalloc()) == 0){
80103210:	e8 b3 ee ff ff       	call   801020c8 <kalloc>
80103215:	89 43 08             	mov    %eax,0x8(%ebx)
80103218:	83 c4 10             	add    $0x10,%esp
8010321b:	85 c0                	test   %eax,%eax
8010321d:	74 3c                	je     8010325b <allocproc+0xb3>
  sp -= sizeof *p->tf;
8010321f:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
80103225:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
80103228:	c7 80 b0 0f 00 00 9e 	movl   $0x80104e9e,0xfb0(%eax)
8010322f:	4e 10 80 
  sp -= sizeof *p->context;
80103232:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
80103237:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
8010323a:	83 ec 04             	sub    $0x4,%esp
8010323d:	6a 14                	push   $0x14
8010323f:	6a 00                	push   $0x0
80103241:	50                   	push   %eax
80103242:	e8 41 0b 00 00       	call   80103d88 <memset>
  p->context->eip = (uint)forkret;
80103247:	8b 43 1c             	mov    0x1c(%ebx),%eax
8010324a:	c7 40 10 69 32 10 80 	movl   $0x80103269,0x10(%eax)
  return p;
80103251:	83 c4 10             	add    $0x10,%esp
}
80103254:	89 d8                	mov    %ebx,%eax
80103256:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103259:	c9                   	leave  
8010325a:	c3                   	ret    
    p->state = UNUSED;
8010325b:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
80103262:	bb 00 00 00 00       	mov    $0x0,%ebx
80103267:	eb eb                	jmp    80103254 <allocproc+0xac>

80103269 <forkret>:
{
80103269:	55                   	push   %ebp
8010326a:	89 e5                	mov    %esp,%ebp
8010326c:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
8010326f:	68 a0 1d 13 80       	push   $0x80131da0
80103274:	e8 c8 0a 00 00       	call   80103d41 <release>
  if (first) {
80103279:	83 c4 10             	add    $0x10,%esp
8010327c:	83 3d 00 90 10 80 00 	cmpl   $0x0,0x80109000
80103283:	75 02                	jne    80103287 <forkret+0x1e>
}
80103285:	c9                   	leave  
80103286:	c3                   	ret    
    first = 0;
80103287:	c7 05 00 90 10 80 00 	movl   $0x0,0x80109000
8010328e:	00 00 00 
    iinit(ROOTDEV);
80103291:	83 ec 0c             	sub    $0xc,%esp
80103294:	6a 01                	push   $0x1
80103296:	e8 51 e0 ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
8010329b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801032a2:	e8 fd f5 ff ff       	call   801028a4 <initlog>
801032a7:	83 c4 10             	add    $0x10,%esp
}
801032aa:	eb d9                	jmp    80103285 <forkret+0x1c>

801032ac <pinit>:
{
801032ac:	55                   	push   %ebp
801032ad:	89 e5                	mov    %esp,%ebp
801032af:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
801032b2:	68 55 6b 10 80       	push   $0x80106b55
801032b7:	68 a0 1d 13 80       	push   $0x80131da0
801032bc:	e8 df 08 00 00       	call   80103ba0 <initlock>
}
801032c1:	83 c4 10             	add    $0x10,%esp
801032c4:	c9                   	leave  
801032c5:	c3                   	ret    

801032c6 <mycpu>:
{
801032c6:	55                   	push   %ebp
801032c7:	89 e5                	mov    %esp,%ebp
801032c9:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801032cc:	9c                   	pushf  
801032cd:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801032ce:	f6 c4 02             	test   $0x2,%ah
801032d1:	75 28                	jne    801032fb <mycpu+0x35>
  apicid = lapicid();
801032d3:	e8 e5 f1 ff ff       	call   801024bd <lapicid>
  for (i = 0; i < ncpu; ++i) {
801032d8:	ba 00 00 00 00       	mov    $0x0,%edx
801032dd:	39 15 80 1d 13 80    	cmp    %edx,0x80131d80
801032e3:	7e 23                	jle    80103308 <mycpu+0x42>
    if (cpus[i].apicid == apicid)
801032e5:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
801032eb:	0f b6 89 00 18 13 80 	movzbl -0x7fece800(%ecx),%ecx
801032f2:	39 c1                	cmp    %eax,%ecx
801032f4:	74 1f                	je     80103315 <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
801032f6:	83 c2 01             	add    $0x1,%edx
801032f9:	eb e2                	jmp    801032dd <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
801032fb:	83 ec 0c             	sub    $0xc,%esp
801032fe:	68 38 6c 10 80       	push   $0x80106c38
80103303:	e8 40 d0 ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
80103308:	83 ec 0c             	sub    $0xc,%esp
8010330b:	68 5c 6b 10 80       	push   $0x80106b5c
80103310:	e8 33 d0 ff ff       	call   80100348 <panic>
      return &cpus[i];
80103315:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
8010331b:	05 00 18 13 80       	add    $0x80131800,%eax
}
80103320:	c9                   	leave  
80103321:	c3                   	ret    

80103322 <cpuid>:
cpuid() {
80103322:	55                   	push   %ebp
80103323:	89 e5                	mov    %esp,%ebp
80103325:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
80103328:	e8 99 ff ff ff       	call   801032c6 <mycpu>
8010332d:	2d 00 18 13 80       	sub    $0x80131800,%eax
80103332:	c1 f8 04             	sar    $0x4,%eax
80103335:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
8010333b:	c9                   	leave  
8010333c:	c3                   	ret    

8010333d <myproc>:
myproc(void) {
8010333d:	55                   	push   %ebp
8010333e:	89 e5                	mov    %esp,%ebp
80103340:	53                   	push   %ebx
80103341:	83 ec 04             	sub    $0x4,%esp
  pushcli();
80103344:	e8 b6 08 00 00       	call   80103bff <pushcli>
  c = mycpu();
80103349:	e8 78 ff ff ff       	call   801032c6 <mycpu>
  p = c->proc;
8010334e:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103354:	e8 e3 08 00 00       	call   80103c3c <popcli>
}
80103359:	89 d8                	mov    %ebx,%eax
8010335b:	83 c4 04             	add    $0x4,%esp
8010335e:	5b                   	pop    %ebx
8010335f:	5d                   	pop    %ebp
80103360:	c3                   	ret    

80103361 <userinit>:
{
80103361:	55                   	push   %ebp
80103362:	89 e5                	mov    %esp,%ebp
80103364:	53                   	push   %ebx
80103365:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
80103368:	e8 3b fe ff ff       	call   801031a8 <allocproc>
8010336d:	89 c3                	mov    %eax,%ebx
  initproc = p;
8010336f:	a3 bc 95 10 80       	mov    %eax,0x801095bc
  if((p->pgdir = setupkvm()) == 0)
80103374:	e8 24 30 00 00       	call   8010639d <setupkvm>
80103379:	89 43 04             	mov    %eax,0x4(%ebx)
8010337c:	85 c0                	test   %eax,%eax
8010337e:	0f 84 b7 00 00 00    	je     8010343b <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80103384:	83 ec 04             	sub    $0x4,%esp
80103387:	68 2c 00 00 00       	push   $0x2c
8010338c:	68 60 94 10 80       	push   $0x80109460
80103391:	50                   	push   %eax
80103392:	e8 fe 2c 00 00       	call   80106095 <inituvm>
  p->sz = PGSIZE;
80103397:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
8010339d:	83 c4 0c             	add    $0xc,%esp
801033a0:	6a 4c                	push   $0x4c
801033a2:	6a 00                	push   $0x0
801033a4:	ff 73 18             	pushl  0x18(%ebx)
801033a7:	e8 dc 09 00 00       	call   80103d88 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801033ac:	8b 43 18             	mov    0x18(%ebx),%eax
801033af:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801033b5:	8b 43 18             	mov    0x18(%ebx),%eax
801033b8:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
801033be:	8b 43 18             	mov    0x18(%ebx),%eax
801033c1:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801033c5:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801033c9:	8b 43 18             	mov    0x18(%ebx),%eax
801033cc:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801033d0:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801033d4:	8b 43 18             	mov    0x18(%ebx),%eax
801033d7:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801033de:	8b 43 18             	mov    0x18(%ebx),%eax
801033e1:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801033e8:	8b 43 18             	mov    0x18(%ebx),%eax
801033eb:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
801033f2:	8d 43 6c             	lea    0x6c(%ebx),%eax
801033f5:	83 c4 0c             	add    $0xc,%esp
801033f8:	6a 10                	push   $0x10
801033fa:	68 85 6b 10 80       	push   $0x80106b85
801033ff:	50                   	push   %eax
80103400:	e8 ea 0a 00 00       	call   80103eef <safestrcpy>
  p->cwd = namei("/");
80103405:	c7 04 24 8e 6b 10 80 	movl   $0x80106b8e,(%esp)
8010340c:	e8 d0 e7 ff ff       	call   80101be1 <namei>
80103411:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
80103414:	c7 04 24 a0 1d 13 80 	movl   $0x80131da0,(%esp)
8010341b:	e8 bc 08 00 00       	call   80103cdc <acquire>
  p->state = RUNNABLE;
80103420:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
80103427:	c7 04 24 a0 1d 13 80 	movl   $0x80131da0,(%esp)
8010342e:	e8 0e 09 00 00       	call   80103d41 <release>
}
80103433:	83 c4 10             	add    $0x10,%esp
80103436:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103439:	c9                   	leave  
8010343a:	c3                   	ret    
    panic("userinit: out of memory?");
8010343b:	83 ec 0c             	sub    $0xc,%esp
8010343e:	68 6c 6b 10 80       	push   $0x80106b6c
80103443:	e8 00 cf ff ff       	call   80100348 <panic>

80103448 <growproc>:
{
80103448:	55                   	push   %ebp
80103449:	89 e5                	mov    %esp,%ebp
8010344b:	56                   	push   %esi
8010344c:	53                   	push   %ebx
8010344d:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
80103450:	e8 e8 fe ff ff       	call   8010333d <myproc>
80103455:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
80103457:	8b 00                	mov    (%eax),%eax
  if(n > 0){
80103459:	85 f6                	test   %esi,%esi
8010345b:	7f 21                	jg     8010347e <growproc+0x36>
  } else if(n < 0){
8010345d:	85 f6                	test   %esi,%esi
8010345f:	79 33                	jns    80103494 <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103461:	83 ec 04             	sub    $0x4,%esp
80103464:	01 c6                	add    %eax,%esi
80103466:	56                   	push   %esi
80103467:	50                   	push   %eax
80103468:	ff 73 04             	pushl  0x4(%ebx)
8010346b:	e8 33 2d 00 00       	call   801061a3 <deallocuvm>
80103470:	83 c4 10             	add    $0x10,%esp
80103473:	85 c0                	test   %eax,%eax
80103475:	75 1d                	jne    80103494 <growproc+0x4c>
      return -1;
80103477:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010347c:	eb 29                	jmp    801034a7 <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
8010347e:	83 ec 04             	sub    $0x4,%esp
80103481:	01 c6                	add    %eax,%esi
80103483:	56                   	push   %esi
80103484:	50                   	push   %eax
80103485:	ff 73 04             	pushl  0x4(%ebx)
80103488:	e8 a8 2d 00 00       	call   80106235 <allocuvm>
8010348d:	83 c4 10             	add    $0x10,%esp
80103490:	85 c0                	test   %eax,%eax
80103492:	74 1a                	je     801034ae <growproc+0x66>
  curproc->sz = sz;
80103494:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
80103496:	83 ec 0c             	sub    $0xc,%esp
80103499:	53                   	push   %ebx
8010349a:	e8 de 2a 00 00       	call   80105f7d <switchuvm>
  return 0;
8010349f:	83 c4 10             	add    $0x10,%esp
801034a2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801034a7:	8d 65 f8             	lea    -0x8(%ebp),%esp
801034aa:	5b                   	pop    %ebx
801034ab:	5e                   	pop    %esi
801034ac:	5d                   	pop    %ebp
801034ad:	c3                   	ret    
      return -1;
801034ae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801034b3:	eb f2                	jmp    801034a7 <growproc+0x5f>

801034b5 <fork>:
{
801034b5:	55                   	push   %ebp
801034b6:	89 e5                	mov    %esp,%ebp
801034b8:	57                   	push   %edi
801034b9:	56                   	push   %esi
801034ba:	53                   	push   %ebx
801034bb:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
801034be:	e8 7a fe ff ff       	call   8010333d <myproc>
801034c3:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
801034c5:	e8 de fc ff ff       	call   801031a8 <allocproc>
801034ca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801034cd:	85 c0                	test   %eax,%eax
801034cf:	0f 84 e0 00 00 00    	je     801035b5 <fork+0x100>
801034d5:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){
801034d7:	83 ec 08             	sub    $0x8,%esp
801034da:	ff 33                	pushl  (%ebx)
801034dc:	ff 73 04             	pushl  0x4(%ebx)
801034df:	e8 72 2f 00 00       	call   80106456 <copyuvm>
801034e4:	89 47 04             	mov    %eax,0x4(%edi)
801034e7:	83 c4 10             	add    $0x10,%esp
801034ea:	85 c0                	test   %eax,%eax
801034ec:	74 2a                	je     80103518 <fork+0x63>
  np->sz = curproc->sz;
801034ee:	8b 03                	mov    (%ebx),%eax
801034f0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801034f3:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
801034f5:	89 c8                	mov    %ecx,%eax
801034f7:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
801034fa:	8b 73 18             	mov    0x18(%ebx),%esi
801034fd:	8b 79 18             	mov    0x18(%ecx),%edi
80103500:	b9 13 00 00 00       	mov    $0x13,%ecx
80103505:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
80103507:	8b 40 18             	mov    0x18(%eax),%eax
8010350a:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
80103511:	be 00 00 00 00       	mov    $0x0,%esi
80103516:	eb 29                	jmp    80103541 <fork+0x8c>
    kfree(np->kstack);
80103518:	83 ec 0c             	sub    $0xc,%esp
8010351b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
8010351e:	ff 73 08             	pushl  0x8(%ebx)
80103521:	e8 7e ea ff ff       	call   80101fa4 <kfree>
    np->kstack = 0;
80103526:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
8010352d:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
80103534:	83 c4 10             	add    $0x10,%esp
80103537:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010353c:	eb 6d                	jmp    801035ab <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
8010353e:	83 c6 01             	add    $0x1,%esi
80103541:	83 fe 0f             	cmp    $0xf,%esi
80103544:	7f 1d                	jg     80103563 <fork+0xae>
    if(curproc->ofile[i])
80103546:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
8010354a:	85 c0                	test   %eax,%eax
8010354c:	74 f0                	je     8010353e <fork+0x89>
      np->ofile[i] = filedup(curproc->ofile[i]);
8010354e:	83 ec 0c             	sub    $0xc,%esp
80103551:	50                   	push   %eax
80103552:	e8 37 d7 ff ff       	call   80100c8e <filedup>
80103557:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010355a:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
8010355e:	83 c4 10             	add    $0x10,%esp
80103561:	eb db                	jmp    8010353e <fork+0x89>
  np->cwd = idup(curproc->cwd);
80103563:	83 ec 0c             	sub    $0xc,%esp
80103566:	ff 73 68             	pushl  0x68(%ebx)
80103569:	e8 e3 df ff ff       	call   80101551 <idup>
8010356e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103571:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103574:	83 c3 6c             	add    $0x6c,%ebx
80103577:	8d 47 6c             	lea    0x6c(%edi),%eax
8010357a:	83 c4 0c             	add    $0xc,%esp
8010357d:	6a 10                	push   $0x10
8010357f:	53                   	push   %ebx
80103580:	50                   	push   %eax
80103581:	e8 69 09 00 00       	call   80103eef <safestrcpy>
  pid = np->pid;
80103586:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
80103589:	c7 04 24 a0 1d 13 80 	movl   $0x80131da0,(%esp)
80103590:	e8 47 07 00 00       	call   80103cdc <acquire>
  np->state = RUNNABLE;
80103595:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
8010359c:	c7 04 24 a0 1d 13 80 	movl   $0x80131da0,(%esp)
801035a3:	e8 99 07 00 00       	call   80103d41 <release>
  return pid;
801035a8:	83 c4 10             	add    $0x10,%esp
}
801035ab:	89 d8                	mov    %ebx,%eax
801035ad:	8d 65 f4             	lea    -0xc(%ebp),%esp
801035b0:	5b                   	pop    %ebx
801035b1:	5e                   	pop    %esi
801035b2:	5f                   	pop    %edi
801035b3:	5d                   	pop    %ebp
801035b4:	c3                   	ret    
    return -1;
801035b5:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801035ba:	eb ef                	jmp    801035ab <fork+0xf6>

801035bc <scheduler>:
{
801035bc:	55                   	push   %ebp
801035bd:	89 e5                	mov    %esp,%ebp
801035bf:	56                   	push   %esi
801035c0:	53                   	push   %ebx
  struct cpu *c = mycpu();
801035c1:	e8 00 fd ff ff       	call   801032c6 <mycpu>
801035c6:	89 c6                	mov    %eax,%esi
  c->proc = 0;
801035c8:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
801035cf:	00 00 00 
801035d2:	eb 5a                	jmp    8010362e <scheduler+0x72>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801035d4:	83 c3 7c             	add    $0x7c,%ebx
801035d7:	81 fb d4 3c 13 80    	cmp    $0x80133cd4,%ebx
801035dd:	73 3f                	jae    8010361e <scheduler+0x62>
      if(p->state != RUNNABLE)
801035df:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
801035e3:	75 ef                	jne    801035d4 <scheduler+0x18>
      c->proc = p;
801035e5:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
801035eb:	83 ec 0c             	sub    $0xc,%esp
801035ee:	53                   	push   %ebx
801035ef:	e8 89 29 00 00       	call   80105f7d <switchuvm>
      p->state = RUNNING;
801035f4:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
801035fb:	83 c4 08             	add    $0x8,%esp
801035fe:	ff 73 1c             	pushl  0x1c(%ebx)
80103601:	8d 46 04             	lea    0x4(%esi),%eax
80103604:	50                   	push   %eax
80103605:	e8 38 09 00 00       	call   80103f42 <swtch>
      switchkvm();
8010360a:	e8 5c 29 00 00       	call   80105f6b <switchkvm>
      c->proc = 0;
8010360f:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
80103616:	00 00 00 
80103619:	83 c4 10             	add    $0x10,%esp
8010361c:	eb b6                	jmp    801035d4 <scheduler+0x18>
    release(&ptable.lock);
8010361e:	83 ec 0c             	sub    $0xc,%esp
80103621:	68 a0 1d 13 80       	push   $0x80131da0
80103626:	e8 16 07 00 00       	call   80103d41 <release>
    sti();
8010362b:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
8010362e:	fb                   	sti    
    acquire(&ptable.lock);
8010362f:	83 ec 0c             	sub    $0xc,%esp
80103632:	68 a0 1d 13 80       	push   $0x80131da0
80103637:	e8 a0 06 00 00       	call   80103cdc <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010363c:	83 c4 10             	add    $0x10,%esp
8010363f:	bb d4 1d 13 80       	mov    $0x80131dd4,%ebx
80103644:	eb 91                	jmp    801035d7 <scheduler+0x1b>

80103646 <sched>:
{
80103646:	55                   	push   %ebp
80103647:	89 e5                	mov    %esp,%ebp
80103649:	56                   	push   %esi
8010364a:	53                   	push   %ebx
  struct proc *p = myproc();
8010364b:	e8 ed fc ff ff       	call   8010333d <myproc>
80103650:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
80103652:	83 ec 0c             	sub    $0xc,%esp
80103655:	68 a0 1d 13 80       	push   $0x80131da0
8010365a:	e8 3d 06 00 00       	call   80103c9c <holding>
8010365f:	83 c4 10             	add    $0x10,%esp
80103662:	85 c0                	test   %eax,%eax
80103664:	74 4f                	je     801036b5 <sched+0x6f>
  if(mycpu()->ncli != 1)
80103666:	e8 5b fc ff ff       	call   801032c6 <mycpu>
8010366b:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
80103672:	75 4e                	jne    801036c2 <sched+0x7c>
  if(p->state == RUNNING)
80103674:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
80103678:	74 55                	je     801036cf <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010367a:	9c                   	pushf  
8010367b:	58                   	pop    %eax
  if(readeflags()&FL_IF)
8010367c:	f6 c4 02             	test   $0x2,%ah
8010367f:	75 5b                	jne    801036dc <sched+0x96>
  intena = mycpu()->intena;
80103681:	e8 40 fc ff ff       	call   801032c6 <mycpu>
80103686:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
8010368c:	e8 35 fc ff ff       	call   801032c6 <mycpu>
80103691:	83 ec 08             	sub    $0x8,%esp
80103694:	ff 70 04             	pushl  0x4(%eax)
80103697:	83 c3 1c             	add    $0x1c,%ebx
8010369a:	53                   	push   %ebx
8010369b:	e8 a2 08 00 00       	call   80103f42 <swtch>
  mycpu()->intena = intena;
801036a0:	e8 21 fc ff ff       	call   801032c6 <mycpu>
801036a5:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
801036ab:	83 c4 10             	add    $0x10,%esp
801036ae:	8d 65 f8             	lea    -0x8(%ebp),%esp
801036b1:	5b                   	pop    %ebx
801036b2:	5e                   	pop    %esi
801036b3:	5d                   	pop    %ebp
801036b4:	c3                   	ret    
    panic("sched ptable.lock");
801036b5:	83 ec 0c             	sub    $0xc,%esp
801036b8:	68 90 6b 10 80       	push   $0x80106b90
801036bd:	e8 86 cc ff ff       	call   80100348 <panic>
    panic("sched locks");
801036c2:	83 ec 0c             	sub    $0xc,%esp
801036c5:	68 a2 6b 10 80       	push   $0x80106ba2
801036ca:	e8 79 cc ff ff       	call   80100348 <panic>
    panic("sched running");
801036cf:	83 ec 0c             	sub    $0xc,%esp
801036d2:	68 ae 6b 10 80       	push   $0x80106bae
801036d7:	e8 6c cc ff ff       	call   80100348 <panic>
    panic("sched interruptible");
801036dc:	83 ec 0c             	sub    $0xc,%esp
801036df:	68 bc 6b 10 80       	push   $0x80106bbc
801036e4:	e8 5f cc ff ff       	call   80100348 <panic>

801036e9 <exit>:
{
801036e9:	55                   	push   %ebp
801036ea:	89 e5                	mov    %esp,%ebp
801036ec:	56                   	push   %esi
801036ed:	53                   	push   %ebx
  struct proc *curproc = myproc();
801036ee:	e8 4a fc ff ff       	call   8010333d <myproc>
  if(curproc == initproc)
801036f3:	39 05 bc 95 10 80    	cmp    %eax,0x801095bc
801036f9:	74 09                	je     80103704 <exit+0x1b>
801036fb:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
801036fd:	bb 00 00 00 00       	mov    $0x0,%ebx
80103702:	eb 10                	jmp    80103714 <exit+0x2b>
    panic("init exiting");
80103704:	83 ec 0c             	sub    $0xc,%esp
80103707:	68 d0 6b 10 80       	push   $0x80106bd0
8010370c:	e8 37 cc ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
80103711:	83 c3 01             	add    $0x1,%ebx
80103714:	83 fb 0f             	cmp    $0xf,%ebx
80103717:	7f 1e                	jg     80103737 <exit+0x4e>
    if(curproc->ofile[fd]){
80103719:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
8010371d:	85 c0                	test   %eax,%eax
8010371f:	74 f0                	je     80103711 <exit+0x28>
      fileclose(curproc->ofile[fd]);
80103721:	83 ec 0c             	sub    $0xc,%esp
80103724:	50                   	push   %eax
80103725:	e8 a9 d5 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
8010372a:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
80103731:	00 
80103732:	83 c4 10             	add    $0x10,%esp
80103735:	eb da                	jmp    80103711 <exit+0x28>
  begin_op();
80103737:	e8 b1 f1 ff ff       	call   801028ed <begin_op>
  iput(curproc->cwd);
8010373c:	83 ec 0c             	sub    $0xc,%esp
8010373f:	ff 76 68             	pushl  0x68(%esi)
80103742:	e8 41 df ff ff       	call   80101688 <iput>
  end_op();
80103747:	e8 1b f2 ff ff       	call   80102967 <end_op>
  curproc->cwd = 0;
8010374c:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
80103753:	c7 04 24 a0 1d 13 80 	movl   $0x80131da0,(%esp)
8010375a:	e8 7d 05 00 00       	call   80103cdc <acquire>
  wakeup1(curproc->parent);
8010375f:	8b 46 14             	mov    0x14(%esi),%eax
80103762:	e8 16 fa ff ff       	call   8010317d <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103767:	83 c4 10             	add    $0x10,%esp
8010376a:	bb d4 1d 13 80       	mov    $0x80131dd4,%ebx
8010376f:	eb 03                	jmp    80103774 <exit+0x8b>
80103771:	83 c3 7c             	add    $0x7c,%ebx
80103774:	81 fb d4 3c 13 80    	cmp    $0x80133cd4,%ebx
8010377a:	73 1a                	jae    80103796 <exit+0xad>
    if(p->parent == curproc){
8010377c:	39 73 14             	cmp    %esi,0x14(%ebx)
8010377f:	75 f0                	jne    80103771 <exit+0x88>
      p->parent = initproc;
80103781:	a1 bc 95 10 80       	mov    0x801095bc,%eax
80103786:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
80103789:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
8010378d:	75 e2                	jne    80103771 <exit+0x88>
        wakeup1(initproc);
8010378f:	e8 e9 f9 ff ff       	call   8010317d <wakeup1>
80103794:	eb db                	jmp    80103771 <exit+0x88>
  curproc->state = ZOMBIE;
80103796:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
8010379d:	e8 a4 fe ff ff       	call   80103646 <sched>
  panic("zombie exit");
801037a2:	83 ec 0c             	sub    $0xc,%esp
801037a5:	68 dd 6b 10 80       	push   $0x80106bdd
801037aa:	e8 99 cb ff ff       	call   80100348 <panic>

801037af <yield>:
{
801037af:	55                   	push   %ebp
801037b0:	89 e5                	mov    %esp,%ebp
801037b2:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801037b5:	68 a0 1d 13 80       	push   $0x80131da0
801037ba:	e8 1d 05 00 00       	call   80103cdc <acquire>
  myproc()->state = RUNNABLE;
801037bf:	e8 79 fb ff ff       	call   8010333d <myproc>
801037c4:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801037cb:	e8 76 fe ff ff       	call   80103646 <sched>
  release(&ptable.lock);
801037d0:	c7 04 24 a0 1d 13 80 	movl   $0x80131da0,(%esp)
801037d7:	e8 65 05 00 00       	call   80103d41 <release>
}
801037dc:	83 c4 10             	add    $0x10,%esp
801037df:	c9                   	leave  
801037e0:	c3                   	ret    

801037e1 <sleep>:
{
801037e1:	55                   	push   %ebp
801037e2:	89 e5                	mov    %esp,%ebp
801037e4:	56                   	push   %esi
801037e5:	53                   	push   %ebx
801037e6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
801037e9:	e8 4f fb ff ff       	call   8010333d <myproc>
  if(p == 0)
801037ee:	85 c0                	test   %eax,%eax
801037f0:	74 66                	je     80103858 <sleep+0x77>
801037f2:	89 c6                	mov    %eax,%esi
  if(lk == 0)
801037f4:	85 db                	test   %ebx,%ebx
801037f6:	74 6d                	je     80103865 <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
801037f8:	81 fb a0 1d 13 80    	cmp    $0x80131da0,%ebx
801037fe:	74 18                	je     80103818 <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
80103800:	83 ec 0c             	sub    $0xc,%esp
80103803:	68 a0 1d 13 80       	push   $0x80131da0
80103808:	e8 cf 04 00 00       	call   80103cdc <acquire>
    release(lk);
8010380d:	89 1c 24             	mov    %ebx,(%esp)
80103810:	e8 2c 05 00 00       	call   80103d41 <release>
80103815:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
80103818:	8b 45 08             	mov    0x8(%ebp),%eax
8010381b:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
8010381e:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
80103825:	e8 1c fe ff ff       	call   80103646 <sched>
  p->chan = 0;
8010382a:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
80103831:	81 fb a0 1d 13 80    	cmp    $0x80131da0,%ebx
80103837:	74 18                	je     80103851 <sleep+0x70>
    release(&ptable.lock);
80103839:	83 ec 0c             	sub    $0xc,%esp
8010383c:	68 a0 1d 13 80       	push   $0x80131da0
80103841:	e8 fb 04 00 00       	call   80103d41 <release>
    acquire(lk);
80103846:	89 1c 24             	mov    %ebx,(%esp)
80103849:	e8 8e 04 00 00       	call   80103cdc <acquire>
8010384e:	83 c4 10             	add    $0x10,%esp
}
80103851:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103854:	5b                   	pop    %ebx
80103855:	5e                   	pop    %esi
80103856:	5d                   	pop    %ebp
80103857:	c3                   	ret    
    panic("sleep");
80103858:	83 ec 0c             	sub    $0xc,%esp
8010385b:	68 e9 6b 10 80       	push   $0x80106be9
80103860:	e8 e3 ca ff ff       	call   80100348 <panic>
    panic("sleep without lk");
80103865:	83 ec 0c             	sub    $0xc,%esp
80103868:	68 ef 6b 10 80       	push   $0x80106bef
8010386d:	e8 d6 ca ff ff       	call   80100348 <panic>

80103872 <wait>:
{
80103872:	55                   	push   %ebp
80103873:	89 e5                	mov    %esp,%ebp
80103875:	56                   	push   %esi
80103876:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103877:	e8 c1 fa ff ff       	call   8010333d <myproc>
8010387c:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
8010387e:	83 ec 0c             	sub    $0xc,%esp
80103881:	68 a0 1d 13 80       	push   $0x80131da0
80103886:	e8 51 04 00 00       	call   80103cdc <acquire>
8010388b:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
8010388e:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103893:	bb d4 1d 13 80       	mov    $0x80131dd4,%ebx
80103898:	eb 5b                	jmp    801038f5 <wait+0x83>
        pid = p->pid;
8010389a:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
8010389d:	83 ec 0c             	sub    $0xc,%esp
801038a0:	ff 73 08             	pushl  0x8(%ebx)
801038a3:	e8 fc e6 ff ff       	call   80101fa4 <kfree>
        p->kstack = 0;
801038a8:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
801038af:	83 c4 04             	add    $0x4,%esp
801038b2:	ff 73 04             	pushl  0x4(%ebx)
801038b5:	e8 73 2a 00 00       	call   8010632d <freevm>
        p->pid = 0;
801038ba:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
801038c1:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
801038c8:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
801038cc:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
801038d3:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
801038da:	c7 04 24 a0 1d 13 80 	movl   $0x80131da0,(%esp)
801038e1:	e8 5b 04 00 00       	call   80103d41 <release>
        return pid;
801038e6:	83 c4 10             	add    $0x10,%esp
}
801038e9:	89 f0                	mov    %esi,%eax
801038eb:	8d 65 f8             	lea    -0x8(%ebp),%esp
801038ee:	5b                   	pop    %ebx
801038ef:	5e                   	pop    %esi
801038f0:	5d                   	pop    %ebp
801038f1:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801038f2:	83 c3 7c             	add    $0x7c,%ebx
801038f5:	81 fb d4 3c 13 80    	cmp    $0x80133cd4,%ebx
801038fb:	73 12                	jae    8010390f <wait+0x9d>
      if(p->parent != curproc)
801038fd:	39 73 14             	cmp    %esi,0x14(%ebx)
80103900:	75 f0                	jne    801038f2 <wait+0x80>
      if(p->state == ZOMBIE){
80103902:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103906:	74 92                	je     8010389a <wait+0x28>
      havekids = 1;
80103908:	b8 01 00 00 00       	mov    $0x1,%eax
8010390d:	eb e3                	jmp    801038f2 <wait+0x80>
    if(!havekids || curproc->killed){
8010390f:	85 c0                	test   %eax,%eax
80103911:	74 06                	je     80103919 <wait+0xa7>
80103913:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
80103917:	74 17                	je     80103930 <wait+0xbe>
      release(&ptable.lock);
80103919:	83 ec 0c             	sub    $0xc,%esp
8010391c:	68 a0 1d 13 80       	push   $0x80131da0
80103921:	e8 1b 04 00 00       	call   80103d41 <release>
      return -1;
80103926:	83 c4 10             	add    $0x10,%esp
80103929:	be ff ff ff ff       	mov    $0xffffffff,%esi
8010392e:	eb b9                	jmp    801038e9 <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80103930:	83 ec 08             	sub    $0x8,%esp
80103933:	68 a0 1d 13 80       	push   $0x80131da0
80103938:	56                   	push   %esi
80103939:	e8 a3 fe ff ff       	call   801037e1 <sleep>
    havekids = 0;
8010393e:	83 c4 10             	add    $0x10,%esp
80103941:	e9 48 ff ff ff       	jmp    8010388e <wait+0x1c>

80103946 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80103946:	55                   	push   %ebp
80103947:	89 e5                	mov    %esp,%ebp
80103949:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
8010394c:	68 a0 1d 13 80       	push   $0x80131da0
80103951:	e8 86 03 00 00       	call   80103cdc <acquire>
  wakeup1(chan);
80103956:	8b 45 08             	mov    0x8(%ebp),%eax
80103959:	e8 1f f8 ff ff       	call   8010317d <wakeup1>
  release(&ptable.lock);
8010395e:	c7 04 24 a0 1d 13 80 	movl   $0x80131da0,(%esp)
80103965:	e8 d7 03 00 00       	call   80103d41 <release>
}
8010396a:	83 c4 10             	add    $0x10,%esp
8010396d:	c9                   	leave  
8010396e:	c3                   	ret    

8010396f <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
8010396f:	55                   	push   %ebp
80103970:	89 e5                	mov    %esp,%ebp
80103972:	53                   	push   %ebx
80103973:	83 ec 10             	sub    $0x10,%esp
80103976:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
80103979:	68 a0 1d 13 80       	push   $0x80131da0
8010397e:	e8 59 03 00 00       	call   80103cdc <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103983:	83 c4 10             	add    $0x10,%esp
80103986:	b8 d4 1d 13 80       	mov    $0x80131dd4,%eax
8010398b:	3d d4 3c 13 80       	cmp    $0x80133cd4,%eax
80103990:	73 3a                	jae    801039cc <kill+0x5d>
    if(p->pid == pid){
80103992:	39 58 10             	cmp    %ebx,0x10(%eax)
80103995:	74 05                	je     8010399c <kill+0x2d>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103997:	83 c0 7c             	add    $0x7c,%eax
8010399a:	eb ef                	jmp    8010398b <kill+0x1c>
      p->killed = 1;
8010399c:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
801039a3:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
801039a7:	74 1a                	je     801039c3 <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
801039a9:	83 ec 0c             	sub    $0xc,%esp
801039ac:	68 a0 1d 13 80       	push   $0x80131da0
801039b1:	e8 8b 03 00 00       	call   80103d41 <release>
      return 0;
801039b6:	83 c4 10             	add    $0x10,%esp
801039b9:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
801039be:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801039c1:	c9                   	leave  
801039c2:	c3                   	ret    
        p->state = RUNNABLE;
801039c3:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
801039ca:	eb dd                	jmp    801039a9 <kill+0x3a>
  release(&ptable.lock);
801039cc:	83 ec 0c             	sub    $0xc,%esp
801039cf:	68 a0 1d 13 80       	push   $0x80131da0
801039d4:	e8 68 03 00 00       	call   80103d41 <release>
  return -1;
801039d9:	83 c4 10             	add    $0x10,%esp
801039dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801039e1:	eb db                	jmp    801039be <kill+0x4f>

801039e3 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
801039e3:	55                   	push   %ebp
801039e4:	89 e5                	mov    %esp,%ebp
801039e6:	56                   	push   %esi
801039e7:	53                   	push   %ebx
801039e8:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039eb:	bb d4 1d 13 80       	mov    $0x80131dd4,%ebx
801039f0:	eb 33                	jmp    80103a25 <procdump+0x42>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
801039f2:	b8 00 6c 10 80       	mov    $0x80106c00,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
801039f7:	8d 53 6c             	lea    0x6c(%ebx),%edx
801039fa:	52                   	push   %edx
801039fb:	50                   	push   %eax
801039fc:	ff 73 10             	pushl  0x10(%ebx)
801039ff:	68 04 6c 10 80       	push   $0x80106c04
80103a04:	e8 02 cc ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
80103a09:	83 c4 10             	add    $0x10,%esp
80103a0c:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103a10:	74 39                	je     80103a4b <procdump+0x68>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103a12:	83 ec 0c             	sub    $0xc,%esp
80103a15:	68 7b 6f 10 80       	push   $0x80106f7b
80103a1a:	e8 ec cb ff ff       	call   8010060b <cprintf>
80103a1f:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103a22:	83 c3 7c             	add    $0x7c,%ebx
80103a25:	81 fb d4 3c 13 80    	cmp    $0x80133cd4,%ebx
80103a2b:	73 61                	jae    80103a8e <procdump+0xab>
    if(p->state == UNUSED)
80103a2d:	8b 43 0c             	mov    0xc(%ebx),%eax
80103a30:	85 c0                	test   %eax,%eax
80103a32:	74 ee                	je     80103a22 <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103a34:	83 f8 05             	cmp    $0x5,%eax
80103a37:	77 b9                	ja     801039f2 <procdump+0xf>
80103a39:	8b 04 85 60 6c 10 80 	mov    -0x7fef93a0(,%eax,4),%eax
80103a40:	85 c0                	test   %eax,%eax
80103a42:	75 b3                	jne    801039f7 <procdump+0x14>
      state = "???";
80103a44:	b8 00 6c 10 80       	mov    $0x80106c00,%eax
80103a49:	eb ac                	jmp    801039f7 <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80103a4b:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103a4e:	8b 40 0c             	mov    0xc(%eax),%eax
80103a51:	83 c0 08             	add    $0x8,%eax
80103a54:	83 ec 08             	sub    $0x8,%esp
80103a57:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103a5a:	52                   	push   %edx
80103a5b:	50                   	push   %eax
80103a5c:	e8 5a 01 00 00       	call   80103bbb <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103a61:	83 c4 10             	add    $0x10,%esp
80103a64:	be 00 00 00 00       	mov    $0x0,%esi
80103a69:	eb 14                	jmp    80103a7f <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103a6b:	83 ec 08             	sub    $0x8,%esp
80103a6e:	50                   	push   %eax
80103a6f:	68 41 66 10 80       	push   $0x80106641
80103a74:	e8 92 cb ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103a79:	83 c6 01             	add    $0x1,%esi
80103a7c:	83 c4 10             	add    $0x10,%esp
80103a7f:	83 fe 09             	cmp    $0x9,%esi
80103a82:	7f 8e                	jg     80103a12 <procdump+0x2f>
80103a84:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103a88:	85 c0                	test   %eax,%eax
80103a8a:	75 df                	jne    80103a6b <procdump+0x88>
80103a8c:	eb 84                	jmp    80103a12 <procdump+0x2f>
  }
}
80103a8e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a91:	5b                   	pop    %ebx
80103a92:	5e                   	pop    %esi
80103a93:	5d                   	pop    %ebp
80103a94:	c3                   	ret    

80103a95 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103a95:	55                   	push   %ebp
80103a96:	89 e5                	mov    %esp,%ebp
80103a98:	53                   	push   %ebx
80103a99:	83 ec 0c             	sub    $0xc,%esp
80103a9c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103a9f:	68 78 6c 10 80       	push   $0x80106c78
80103aa4:	8d 43 04             	lea    0x4(%ebx),%eax
80103aa7:	50                   	push   %eax
80103aa8:	e8 f3 00 00 00       	call   80103ba0 <initlock>
  lk->name = name;
80103aad:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ab0:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103ab3:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103ab9:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103ac0:	83 c4 10             	add    $0x10,%esp
80103ac3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103ac6:	c9                   	leave  
80103ac7:	c3                   	ret    

80103ac8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103ac8:	55                   	push   %ebp
80103ac9:	89 e5                	mov    %esp,%ebp
80103acb:	56                   	push   %esi
80103acc:	53                   	push   %ebx
80103acd:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103ad0:	8d 73 04             	lea    0x4(%ebx),%esi
80103ad3:	83 ec 0c             	sub    $0xc,%esp
80103ad6:	56                   	push   %esi
80103ad7:	e8 00 02 00 00       	call   80103cdc <acquire>
  while (lk->locked) {
80103adc:	83 c4 10             	add    $0x10,%esp
80103adf:	eb 0d                	jmp    80103aee <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103ae1:	83 ec 08             	sub    $0x8,%esp
80103ae4:	56                   	push   %esi
80103ae5:	53                   	push   %ebx
80103ae6:	e8 f6 fc ff ff       	call   801037e1 <sleep>
80103aeb:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103aee:	83 3b 00             	cmpl   $0x0,(%ebx)
80103af1:	75 ee                	jne    80103ae1 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103af3:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103af9:	e8 3f f8 ff ff       	call   8010333d <myproc>
80103afe:	8b 40 10             	mov    0x10(%eax),%eax
80103b01:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103b04:	83 ec 0c             	sub    $0xc,%esp
80103b07:	56                   	push   %esi
80103b08:	e8 34 02 00 00       	call   80103d41 <release>
}
80103b0d:	83 c4 10             	add    $0x10,%esp
80103b10:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b13:	5b                   	pop    %ebx
80103b14:	5e                   	pop    %esi
80103b15:	5d                   	pop    %ebp
80103b16:	c3                   	ret    

80103b17 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103b17:	55                   	push   %ebp
80103b18:	89 e5                	mov    %esp,%ebp
80103b1a:	56                   	push   %esi
80103b1b:	53                   	push   %ebx
80103b1c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103b1f:	8d 73 04             	lea    0x4(%ebx),%esi
80103b22:	83 ec 0c             	sub    $0xc,%esp
80103b25:	56                   	push   %esi
80103b26:	e8 b1 01 00 00       	call   80103cdc <acquire>
  lk->locked = 0;
80103b2b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103b31:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103b38:	89 1c 24             	mov    %ebx,(%esp)
80103b3b:	e8 06 fe ff ff       	call   80103946 <wakeup>
  release(&lk->lk);
80103b40:	89 34 24             	mov    %esi,(%esp)
80103b43:	e8 f9 01 00 00       	call   80103d41 <release>
}
80103b48:	83 c4 10             	add    $0x10,%esp
80103b4b:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b4e:	5b                   	pop    %ebx
80103b4f:	5e                   	pop    %esi
80103b50:	5d                   	pop    %ebp
80103b51:	c3                   	ret    

80103b52 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103b52:	55                   	push   %ebp
80103b53:	89 e5                	mov    %esp,%ebp
80103b55:	56                   	push   %esi
80103b56:	53                   	push   %ebx
80103b57:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103b5a:	8d 73 04             	lea    0x4(%ebx),%esi
80103b5d:	83 ec 0c             	sub    $0xc,%esp
80103b60:	56                   	push   %esi
80103b61:	e8 76 01 00 00       	call   80103cdc <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103b66:	83 c4 10             	add    $0x10,%esp
80103b69:	83 3b 00             	cmpl   $0x0,(%ebx)
80103b6c:	75 17                	jne    80103b85 <holdingsleep+0x33>
80103b6e:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103b73:	83 ec 0c             	sub    $0xc,%esp
80103b76:	56                   	push   %esi
80103b77:	e8 c5 01 00 00       	call   80103d41 <release>
  return r;
}
80103b7c:	89 d8                	mov    %ebx,%eax
80103b7e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b81:	5b                   	pop    %ebx
80103b82:	5e                   	pop    %esi
80103b83:	5d                   	pop    %ebp
80103b84:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103b85:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103b88:	e8 b0 f7 ff ff       	call   8010333d <myproc>
80103b8d:	3b 58 10             	cmp    0x10(%eax),%ebx
80103b90:	74 07                	je     80103b99 <holdingsleep+0x47>
80103b92:	bb 00 00 00 00       	mov    $0x0,%ebx
80103b97:	eb da                	jmp    80103b73 <holdingsleep+0x21>
80103b99:	bb 01 00 00 00       	mov    $0x1,%ebx
80103b9e:	eb d3                	jmp    80103b73 <holdingsleep+0x21>

80103ba0 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103ba0:	55                   	push   %ebp
80103ba1:	89 e5                	mov    %esp,%ebp
80103ba3:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103ba6:	8b 55 0c             	mov    0xc(%ebp),%edx
80103ba9:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103bac:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103bb2:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103bb9:	5d                   	pop    %ebp
80103bba:	c3                   	ret    

80103bbb <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103bbb:	55                   	push   %ebp
80103bbc:	89 e5                	mov    %esp,%ebp
80103bbe:	53                   	push   %ebx
80103bbf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103bc2:	8b 45 08             	mov    0x8(%ebp),%eax
80103bc5:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103bc8:	b8 00 00 00 00       	mov    $0x0,%eax
80103bcd:	83 f8 09             	cmp    $0x9,%eax
80103bd0:	7f 25                	jg     80103bf7 <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103bd2:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103bd8:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103bde:	77 17                	ja     80103bf7 <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103be0:	8b 5a 04             	mov    0x4(%edx),%ebx
80103be3:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103be6:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103be8:	83 c0 01             	add    $0x1,%eax
80103beb:	eb e0                	jmp    80103bcd <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103bed:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103bf4:	83 c0 01             	add    $0x1,%eax
80103bf7:	83 f8 09             	cmp    $0x9,%eax
80103bfa:	7e f1                	jle    80103bed <getcallerpcs+0x32>
}
80103bfc:	5b                   	pop    %ebx
80103bfd:	5d                   	pop    %ebp
80103bfe:	c3                   	ret    

80103bff <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103bff:	55                   	push   %ebp
80103c00:	89 e5                	mov    %esp,%ebp
80103c02:	53                   	push   %ebx
80103c03:	83 ec 04             	sub    $0x4,%esp
80103c06:	9c                   	pushf  
80103c07:	5b                   	pop    %ebx
  asm volatile("cli");
80103c08:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103c09:	e8 b8 f6 ff ff       	call   801032c6 <mycpu>
80103c0e:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103c15:	74 12                	je     80103c29 <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103c17:	e8 aa f6 ff ff       	call   801032c6 <mycpu>
80103c1c:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103c23:	83 c4 04             	add    $0x4,%esp
80103c26:	5b                   	pop    %ebx
80103c27:	5d                   	pop    %ebp
80103c28:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103c29:	e8 98 f6 ff ff       	call   801032c6 <mycpu>
80103c2e:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103c34:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103c3a:	eb db                	jmp    80103c17 <pushcli+0x18>

80103c3c <popcli>:

void
popcli(void)
{
80103c3c:	55                   	push   %ebp
80103c3d:	89 e5                	mov    %esp,%ebp
80103c3f:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103c42:	9c                   	pushf  
80103c43:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103c44:	f6 c4 02             	test   $0x2,%ah
80103c47:	75 28                	jne    80103c71 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103c49:	e8 78 f6 ff ff       	call   801032c6 <mycpu>
80103c4e:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103c54:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103c57:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103c5d:	85 d2                	test   %edx,%edx
80103c5f:	78 1d                	js     80103c7e <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103c61:	e8 60 f6 ff ff       	call   801032c6 <mycpu>
80103c66:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103c6d:	74 1c                	je     80103c8b <popcli+0x4f>
    sti();
}
80103c6f:	c9                   	leave  
80103c70:	c3                   	ret    
    panic("popcli - interruptible");
80103c71:	83 ec 0c             	sub    $0xc,%esp
80103c74:	68 83 6c 10 80       	push   $0x80106c83
80103c79:	e8 ca c6 ff ff       	call   80100348 <panic>
    panic("popcli");
80103c7e:	83 ec 0c             	sub    $0xc,%esp
80103c81:	68 9a 6c 10 80       	push   $0x80106c9a
80103c86:	e8 bd c6 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103c8b:	e8 36 f6 ff ff       	call   801032c6 <mycpu>
80103c90:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103c97:	74 d6                	je     80103c6f <popcli+0x33>
  asm volatile("sti");
80103c99:	fb                   	sti    
}
80103c9a:	eb d3                	jmp    80103c6f <popcli+0x33>

80103c9c <holding>:
{
80103c9c:	55                   	push   %ebp
80103c9d:	89 e5                	mov    %esp,%ebp
80103c9f:	53                   	push   %ebx
80103ca0:	83 ec 04             	sub    $0x4,%esp
80103ca3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103ca6:	e8 54 ff ff ff       	call   80103bff <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103cab:	83 3b 00             	cmpl   $0x0,(%ebx)
80103cae:	75 12                	jne    80103cc2 <holding+0x26>
80103cb0:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103cb5:	e8 82 ff ff ff       	call   80103c3c <popcli>
}
80103cba:	89 d8                	mov    %ebx,%eax
80103cbc:	83 c4 04             	add    $0x4,%esp
80103cbf:	5b                   	pop    %ebx
80103cc0:	5d                   	pop    %ebp
80103cc1:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103cc2:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103cc5:	e8 fc f5 ff ff       	call   801032c6 <mycpu>
80103cca:	39 c3                	cmp    %eax,%ebx
80103ccc:	74 07                	je     80103cd5 <holding+0x39>
80103cce:	bb 00 00 00 00       	mov    $0x0,%ebx
80103cd3:	eb e0                	jmp    80103cb5 <holding+0x19>
80103cd5:	bb 01 00 00 00       	mov    $0x1,%ebx
80103cda:	eb d9                	jmp    80103cb5 <holding+0x19>

80103cdc <acquire>:
{
80103cdc:	55                   	push   %ebp
80103cdd:	89 e5                	mov    %esp,%ebp
80103cdf:	53                   	push   %ebx
80103ce0:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103ce3:	e8 17 ff ff ff       	call   80103bff <pushcli>
  if(holding(lk))
80103ce8:	83 ec 0c             	sub    $0xc,%esp
80103ceb:	ff 75 08             	pushl  0x8(%ebp)
80103cee:	e8 a9 ff ff ff       	call   80103c9c <holding>
80103cf3:	83 c4 10             	add    $0x10,%esp
80103cf6:	85 c0                	test   %eax,%eax
80103cf8:	75 3a                	jne    80103d34 <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103cfa:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103cfd:	b8 01 00 00 00       	mov    $0x1,%eax
80103d02:	f0 87 02             	lock xchg %eax,(%edx)
80103d05:	85 c0                	test   %eax,%eax
80103d07:	75 f1                	jne    80103cfa <acquire+0x1e>
  __sync_synchronize();
80103d09:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103d0e:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103d11:	e8 b0 f5 ff ff       	call   801032c6 <mycpu>
80103d16:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103d19:	8b 45 08             	mov    0x8(%ebp),%eax
80103d1c:	83 c0 0c             	add    $0xc,%eax
80103d1f:	83 ec 08             	sub    $0x8,%esp
80103d22:	50                   	push   %eax
80103d23:	8d 45 08             	lea    0x8(%ebp),%eax
80103d26:	50                   	push   %eax
80103d27:	e8 8f fe ff ff       	call   80103bbb <getcallerpcs>
}
80103d2c:	83 c4 10             	add    $0x10,%esp
80103d2f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103d32:	c9                   	leave  
80103d33:	c3                   	ret    
    panic("acquire");
80103d34:	83 ec 0c             	sub    $0xc,%esp
80103d37:	68 a1 6c 10 80       	push   $0x80106ca1
80103d3c:	e8 07 c6 ff ff       	call   80100348 <panic>

80103d41 <release>:
{
80103d41:	55                   	push   %ebp
80103d42:	89 e5                	mov    %esp,%ebp
80103d44:	53                   	push   %ebx
80103d45:	83 ec 10             	sub    $0x10,%esp
80103d48:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103d4b:	53                   	push   %ebx
80103d4c:	e8 4b ff ff ff       	call   80103c9c <holding>
80103d51:	83 c4 10             	add    $0x10,%esp
80103d54:	85 c0                	test   %eax,%eax
80103d56:	74 23                	je     80103d7b <release+0x3a>
  lk->pcs[0] = 0;
80103d58:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103d5f:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103d66:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103d6b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103d71:	e8 c6 fe ff ff       	call   80103c3c <popcli>
}
80103d76:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103d79:	c9                   	leave  
80103d7a:	c3                   	ret    
    panic("release");
80103d7b:	83 ec 0c             	sub    $0xc,%esp
80103d7e:	68 a9 6c 10 80       	push   $0x80106ca9
80103d83:	e8 c0 c5 ff ff       	call   80100348 <panic>

80103d88 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103d88:	55                   	push   %ebp
80103d89:	89 e5                	mov    %esp,%ebp
80103d8b:	57                   	push   %edi
80103d8c:	53                   	push   %ebx
80103d8d:	8b 55 08             	mov    0x8(%ebp),%edx
80103d90:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103d93:	f6 c2 03             	test   $0x3,%dl
80103d96:	75 05                	jne    80103d9d <memset+0x15>
80103d98:	f6 c1 03             	test   $0x3,%cl
80103d9b:	74 0e                	je     80103dab <memset+0x23>
  asm volatile("cld; rep stosb" :
80103d9d:	89 d7                	mov    %edx,%edi
80103d9f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103da2:	fc                   	cld    
80103da3:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103da5:	89 d0                	mov    %edx,%eax
80103da7:	5b                   	pop    %ebx
80103da8:	5f                   	pop    %edi
80103da9:	5d                   	pop    %ebp
80103daa:	c3                   	ret    
    c &= 0xFF;
80103dab:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103daf:	c1 e9 02             	shr    $0x2,%ecx
80103db2:	89 f8                	mov    %edi,%eax
80103db4:	c1 e0 18             	shl    $0x18,%eax
80103db7:	89 fb                	mov    %edi,%ebx
80103db9:	c1 e3 10             	shl    $0x10,%ebx
80103dbc:	09 d8                	or     %ebx,%eax
80103dbe:	89 fb                	mov    %edi,%ebx
80103dc0:	c1 e3 08             	shl    $0x8,%ebx
80103dc3:	09 d8                	or     %ebx,%eax
80103dc5:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103dc7:	89 d7                	mov    %edx,%edi
80103dc9:	fc                   	cld    
80103dca:	f3 ab                	rep stos %eax,%es:(%edi)
80103dcc:	eb d7                	jmp    80103da5 <memset+0x1d>

80103dce <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103dce:	55                   	push   %ebp
80103dcf:	89 e5                	mov    %esp,%ebp
80103dd1:	56                   	push   %esi
80103dd2:	53                   	push   %ebx
80103dd3:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103dd6:	8b 55 0c             	mov    0xc(%ebp),%edx
80103dd9:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103ddc:	8d 70 ff             	lea    -0x1(%eax),%esi
80103ddf:	85 c0                	test   %eax,%eax
80103de1:	74 1c                	je     80103dff <memcmp+0x31>
    if(*s1 != *s2)
80103de3:	0f b6 01             	movzbl (%ecx),%eax
80103de6:	0f b6 1a             	movzbl (%edx),%ebx
80103de9:	38 d8                	cmp    %bl,%al
80103deb:	75 0a                	jne    80103df7 <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103ded:	83 c1 01             	add    $0x1,%ecx
80103df0:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103df3:	89 f0                	mov    %esi,%eax
80103df5:	eb e5                	jmp    80103ddc <memcmp+0xe>
      return *s1 - *s2;
80103df7:	0f b6 c0             	movzbl %al,%eax
80103dfa:	0f b6 db             	movzbl %bl,%ebx
80103dfd:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103dff:	5b                   	pop    %ebx
80103e00:	5e                   	pop    %esi
80103e01:	5d                   	pop    %ebp
80103e02:	c3                   	ret    

80103e03 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103e03:	55                   	push   %ebp
80103e04:	89 e5                	mov    %esp,%ebp
80103e06:	56                   	push   %esi
80103e07:	53                   	push   %ebx
80103e08:	8b 45 08             	mov    0x8(%ebp),%eax
80103e0b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103e0e:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103e11:	39 c1                	cmp    %eax,%ecx
80103e13:	73 3a                	jae    80103e4f <memmove+0x4c>
80103e15:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103e18:	39 c3                	cmp    %eax,%ebx
80103e1a:	76 37                	jbe    80103e53 <memmove+0x50>
    s += n;
    d += n;
80103e1c:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103e1f:	eb 0d                	jmp    80103e2e <memmove+0x2b>
      *--d = *--s;
80103e21:	83 eb 01             	sub    $0x1,%ebx
80103e24:	83 e9 01             	sub    $0x1,%ecx
80103e27:	0f b6 13             	movzbl (%ebx),%edx
80103e2a:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103e2c:	89 f2                	mov    %esi,%edx
80103e2e:	8d 72 ff             	lea    -0x1(%edx),%esi
80103e31:	85 d2                	test   %edx,%edx
80103e33:	75 ec                	jne    80103e21 <memmove+0x1e>
80103e35:	eb 14                	jmp    80103e4b <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103e37:	0f b6 11             	movzbl (%ecx),%edx
80103e3a:	88 13                	mov    %dl,(%ebx)
80103e3c:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103e3f:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103e42:	89 f2                	mov    %esi,%edx
80103e44:	8d 72 ff             	lea    -0x1(%edx),%esi
80103e47:	85 d2                	test   %edx,%edx
80103e49:	75 ec                	jne    80103e37 <memmove+0x34>

  return dst;
}
80103e4b:	5b                   	pop    %ebx
80103e4c:	5e                   	pop    %esi
80103e4d:	5d                   	pop    %ebp
80103e4e:	c3                   	ret    
80103e4f:	89 c3                	mov    %eax,%ebx
80103e51:	eb f1                	jmp    80103e44 <memmove+0x41>
80103e53:	89 c3                	mov    %eax,%ebx
80103e55:	eb ed                	jmp    80103e44 <memmove+0x41>

80103e57 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103e57:	55                   	push   %ebp
80103e58:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80103e5a:	ff 75 10             	pushl  0x10(%ebp)
80103e5d:	ff 75 0c             	pushl  0xc(%ebp)
80103e60:	ff 75 08             	pushl  0x8(%ebp)
80103e63:	e8 9b ff ff ff       	call   80103e03 <memmove>
}
80103e68:	c9                   	leave  
80103e69:	c3                   	ret    

80103e6a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103e6a:	55                   	push   %ebp
80103e6b:	89 e5                	mov    %esp,%ebp
80103e6d:	53                   	push   %ebx
80103e6e:	8b 55 08             	mov    0x8(%ebp),%edx
80103e71:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103e74:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103e77:	eb 09                	jmp    80103e82 <strncmp+0x18>
    n--, p++, q++;
80103e79:	83 e8 01             	sub    $0x1,%eax
80103e7c:	83 c2 01             	add    $0x1,%edx
80103e7f:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103e82:	85 c0                	test   %eax,%eax
80103e84:	74 0b                	je     80103e91 <strncmp+0x27>
80103e86:	0f b6 1a             	movzbl (%edx),%ebx
80103e89:	84 db                	test   %bl,%bl
80103e8b:	74 04                	je     80103e91 <strncmp+0x27>
80103e8d:	3a 19                	cmp    (%ecx),%bl
80103e8f:	74 e8                	je     80103e79 <strncmp+0xf>
  if(n == 0)
80103e91:	85 c0                	test   %eax,%eax
80103e93:	74 0b                	je     80103ea0 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80103e95:	0f b6 02             	movzbl (%edx),%eax
80103e98:	0f b6 11             	movzbl (%ecx),%edx
80103e9b:	29 d0                	sub    %edx,%eax
}
80103e9d:	5b                   	pop    %ebx
80103e9e:	5d                   	pop    %ebp
80103e9f:	c3                   	ret    
    return 0;
80103ea0:	b8 00 00 00 00       	mov    $0x0,%eax
80103ea5:	eb f6                	jmp    80103e9d <strncmp+0x33>

80103ea7 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103ea7:	55                   	push   %ebp
80103ea8:	89 e5                	mov    %esp,%ebp
80103eaa:	57                   	push   %edi
80103eab:	56                   	push   %esi
80103eac:	53                   	push   %ebx
80103ead:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103eb0:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103eb3:	8b 45 08             	mov    0x8(%ebp),%eax
80103eb6:	eb 04                	jmp    80103ebc <strncpy+0x15>
80103eb8:	89 fb                	mov    %edi,%ebx
80103eba:	89 f0                	mov    %esi,%eax
80103ebc:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103ebf:	85 c9                	test   %ecx,%ecx
80103ec1:	7e 1d                	jle    80103ee0 <strncpy+0x39>
80103ec3:	8d 7b 01             	lea    0x1(%ebx),%edi
80103ec6:	8d 70 01             	lea    0x1(%eax),%esi
80103ec9:	0f b6 1b             	movzbl (%ebx),%ebx
80103ecc:	88 18                	mov    %bl,(%eax)
80103ece:	89 d1                	mov    %edx,%ecx
80103ed0:	84 db                	test   %bl,%bl
80103ed2:	75 e4                	jne    80103eb8 <strncpy+0x11>
80103ed4:	89 f0                	mov    %esi,%eax
80103ed6:	eb 08                	jmp    80103ee0 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80103ed8:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80103edb:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80103edd:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80103ee0:	8d 4a ff             	lea    -0x1(%edx),%ecx
80103ee3:	85 d2                	test   %edx,%edx
80103ee5:	7f f1                	jg     80103ed8 <strncpy+0x31>
  return os;
}
80103ee7:	8b 45 08             	mov    0x8(%ebp),%eax
80103eea:	5b                   	pop    %ebx
80103eeb:	5e                   	pop    %esi
80103eec:	5f                   	pop    %edi
80103eed:	5d                   	pop    %ebp
80103eee:	c3                   	ret    

80103eef <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80103eef:	55                   	push   %ebp
80103ef0:	89 e5                	mov    %esp,%ebp
80103ef2:	57                   	push   %edi
80103ef3:	56                   	push   %esi
80103ef4:	53                   	push   %ebx
80103ef5:	8b 45 08             	mov    0x8(%ebp),%eax
80103ef8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103efb:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
80103efe:	85 d2                	test   %edx,%edx
80103f00:	7e 23                	jle    80103f25 <safestrcpy+0x36>
80103f02:	89 c1                	mov    %eax,%ecx
80103f04:	eb 04                	jmp    80103f0a <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80103f06:	89 fb                	mov    %edi,%ebx
80103f08:	89 f1                	mov    %esi,%ecx
80103f0a:	83 ea 01             	sub    $0x1,%edx
80103f0d:	85 d2                	test   %edx,%edx
80103f0f:	7e 11                	jle    80103f22 <safestrcpy+0x33>
80103f11:	8d 7b 01             	lea    0x1(%ebx),%edi
80103f14:	8d 71 01             	lea    0x1(%ecx),%esi
80103f17:	0f b6 1b             	movzbl (%ebx),%ebx
80103f1a:	88 19                	mov    %bl,(%ecx)
80103f1c:	84 db                	test   %bl,%bl
80103f1e:	75 e6                	jne    80103f06 <safestrcpy+0x17>
80103f20:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80103f22:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80103f25:	5b                   	pop    %ebx
80103f26:	5e                   	pop    %esi
80103f27:	5f                   	pop    %edi
80103f28:	5d                   	pop    %ebp
80103f29:	c3                   	ret    

80103f2a <strlen>:

int
strlen(const char *s)
{
80103f2a:	55                   	push   %ebp
80103f2b:	89 e5                	mov    %esp,%ebp
80103f2d:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80103f30:	b8 00 00 00 00       	mov    $0x0,%eax
80103f35:	eb 03                	jmp    80103f3a <strlen+0x10>
80103f37:	83 c0 01             	add    $0x1,%eax
80103f3a:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80103f3e:	75 f7                	jne    80103f37 <strlen+0xd>
    ;
  return n;
}
80103f40:	5d                   	pop    %ebp
80103f41:	c3                   	ret    

80103f42 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80103f42:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80103f46:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80103f4a:	55                   	push   %ebp
  pushl %ebx
80103f4b:	53                   	push   %ebx
  pushl %esi
80103f4c:	56                   	push   %esi
  pushl %edi
80103f4d:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80103f4e:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80103f50:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80103f52:	5f                   	pop    %edi
  popl %esi
80103f53:	5e                   	pop    %esi
  popl %ebx
80103f54:	5b                   	pop    %ebx
  popl %ebp
80103f55:	5d                   	pop    %ebp
  ret
80103f56:	c3                   	ret    

80103f57 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80103f57:	55                   	push   %ebp
80103f58:	89 e5                	mov    %esp,%ebp
80103f5a:	53                   	push   %ebx
80103f5b:	83 ec 04             	sub    $0x4,%esp
80103f5e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80103f61:	e8 d7 f3 ff ff       	call   8010333d <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80103f66:	8b 00                	mov    (%eax),%eax
80103f68:	39 d8                	cmp    %ebx,%eax
80103f6a:	76 19                	jbe    80103f85 <fetchint+0x2e>
80103f6c:	8d 53 04             	lea    0x4(%ebx),%edx
80103f6f:	39 d0                	cmp    %edx,%eax
80103f71:	72 19                	jb     80103f8c <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80103f73:	8b 13                	mov    (%ebx),%edx
80103f75:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f78:	89 10                	mov    %edx,(%eax)
  return 0;
80103f7a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103f7f:	83 c4 04             	add    $0x4,%esp
80103f82:	5b                   	pop    %ebx
80103f83:	5d                   	pop    %ebp
80103f84:	c3                   	ret    
    return -1;
80103f85:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f8a:	eb f3                	jmp    80103f7f <fetchint+0x28>
80103f8c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f91:	eb ec                	jmp    80103f7f <fetchint+0x28>

80103f93 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80103f93:	55                   	push   %ebp
80103f94:	89 e5                	mov    %esp,%ebp
80103f96:	53                   	push   %ebx
80103f97:	83 ec 04             	sub    $0x4,%esp
80103f9a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
80103f9d:	e8 9b f3 ff ff       	call   8010333d <myproc>

  if(addr >= curproc->sz)
80103fa2:	39 18                	cmp    %ebx,(%eax)
80103fa4:	76 26                	jbe    80103fcc <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
80103fa6:	8b 55 0c             	mov    0xc(%ebp),%edx
80103fa9:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
80103fab:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
80103fad:	89 d8                	mov    %ebx,%eax
80103faf:	39 d0                	cmp    %edx,%eax
80103fb1:	73 0e                	jae    80103fc1 <fetchstr+0x2e>
    if(*s == 0)
80103fb3:	80 38 00             	cmpb   $0x0,(%eax)
80103fb6:	74 05                	je     80103fbd <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
80103fb8:	83 c0 01             	add    $0x1,%eax
80103fbb:	eb f2                	jmp    80103faf <fetchstr+0x1c>
      return s - *pp;
80103fbd:	29 d8                	sub    %ebx,%eax
80103fbf:	eb 05                	jmp    80103fc6 <fetchstr+0x33>
  }
  return -1;
80103fc1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103fc6:	83 c4 04             	add    $0x4,%esp
80103fc9:	5b                   	pop    %ebx
80103fca:	5d                   	pop    %ebp
80103fcb:	c3                   	ret    
    return -1;
80103fcc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fd1:	eb f3                	jmp    80103fc6 <fetchstr+0x33>

80103fd3 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80103fd3:	55                   	push   %ebp
80103fd4:	89 e5                	mov    %esp,%ebp
80103fd6:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80103fd9:	e8 5f f3 ff ff       	call   8010333d <myproc>
80103fde:	8b 50 18             	mov    0x18(%eax),%edx
80103fe1:	8b 45 08             	mov    0x8(%ebp),%eax
80103fe4:	c1 e0 02             	shl    $0x2,%eax
80103fe7:	03 42 44             	add    0x44(%edx),%eax
80103fea:	83 ec 08             	sub    $0x8,%esp
80103fed:	ff 75 0c             	pushl  0xc(%ebp)
80103ff0:	83 c0 04             	add    $0x4,%eax
80103ff3:	50                   	push   %eax
80103ff4:	e8 5e ff ff ff       	call   80103f57 <fetchint>
}
80103ff9:	c9                   	leave  
80103ffa:	c3                   	ret    

80103ffb <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80103ffb:	55                   	push   %ebp
80103ffc:	89 e5                	mov    %esp,%ebp
80103ffe:	56                   	push   %esi
80103fff:	53                   	push   %ebx
80104000:	83 ec 10             	sub    $0x10,%esp
80104003:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
80104006:	e8 32 f3 ff ff       	call   8010333d <myproc>
8010400b:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
8010400d:	83 ec 08             	sub    $0x8,%esp
80104010:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104013:	50                   	push   %eax
80104014:	ff 75 08             	pushl  0x8(%ebp)
80104017:	e8 b7 ff ff ff       	call   80103fd3 <argint>
8010401c:	83 c4 10             	add    $0x10,%esp
8010401f:	85 c0                	test   %eax,%eax
80104021:	78 24                	js     80104047 <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80104023:	85 db                	test   %ebx,%ebx
80104025:	78 27                	js     8010404e <argptr+0x53>
80104027:	8b 16                	mov    (%esi),%edx
80104029:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010402c:	39 c2                	cmp    %eax,%edx
8010402e:	76 25                	jbe    80104055 <argptr+0x5a>
80104030:	01 c3                	add    %eax,%ebx
80104032:	39 da                	cmp    %ebx,%edx
80104034:	72 26                	jb     8010405c <argptr+0x61>
    return -1;
  *pp = (char*)i;
80104036:	8b 55 0c             	mov    0xc(%ebp),%edx
80104039:	89 02                	mov    %eax,(%edx)
  return 0;
8010403b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104040:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104043:	5b                   	pop    %ebx
80104044:	5e                   	pop    %esi
80104045:	5d                   	pop    %ebp
80104046:	c3                   	ret    
    return -1;
80104047:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010404c:	eb f2                	jmp    80104040 <argptr+0x45>
    return -1;
8010404e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104053:	eb eb                	jmp    80104040 <argptr+0x45>
80104055:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010405a:	eb e4                	jmp    80104040 <argptr+0x45>
8010405c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104061:	eb dd                	jmp    80104040 <argptr+0x45>

80104063 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80104063:	55                   	push   %ebp
80104064:	89 e5                	mov    %esp,%ebp
80104066:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
80104069:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010406c:	50                   	push   %eax
8010406d:	ff 75 08             	pushl  0x8(%ebp)
80104070:	e8 5e ff ff ff       	call   80103fd3 <argint>
80104075:	83 c4 10             	add    $0x10,%esp
80104078:	85 c0                	test   %eax,%eax
8010407a:	78 13                	js     8010408f <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
8010407c:	83 ec 08             	sub    $0x8,%esp
8010407f:	ff 75 0c             	pushl  0xc(%ebp)
80104082:	ff 75 f4             	pushl  -0xc(%ebp)
80104085:	e8 09 ff ff ff       	call   80103f93 <fetchstr>
8010408a:	83 c4 10             	add    $0x10,%esp
}
8010408d:	c9                   	leave  
8010408e:	c3                   	ret    
    return -1;
8010408f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104094:	eb f7                	jmp    8010408d <argstr+0x2a>

80104096 <syscall>:
[SYS_dump_physmem]   sys_dump_physmem,
};

void
syscall(void)
{
80104096:	55                   	push   %ebp
80104097:	89 e5                	mov    %esp,%ebp
80104099:	53                   	push   %ebx
8010409a:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
8010409d:	e8 9b f2 ff ff       	call   8010333d <myproc>
801040a2:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
801040a4:	8b 40 18             	mov    0x18(%eax),%eax
801040a7:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
801040aa:	8d 50 ff             	lea    -0x1(%eax),%edx
801040ad:	83 fa 15             	cmp    $0x15,%edx
801040b0:	77 18                	ja     801040ca <syscall+0x34>
801040b2:	8b 14 85 e0 6c 10 80 	mov    -0x7fef9320(,%eax,4),%edx
801040b9:	85 d2                	test   %edx,%edx
801040bb:	74 0d                	je     801040ca <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
801040bd:	ff d2                	call   *%edx
801040bf:	8b 53 18             	mov    0x18(%ebx),%edx
801040c2:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
801040c5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801040c8:	c9                   	leave  
801040c9:	c3                   	ret    
            curproc->pid, curproc->name, num);
801040ca:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
801040cd:	50                   	push   %eax
801040ce:	52                   	push   %edx
801040cf:	ff 73 10             	pushl  0x10(%ebx)
801040d2:	68 b1 6c 10 80       	push   $0x80106cb1
801040d7:	e8 2f c5 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
801040dc:	8b 43 18             	mov    0x18(%ebx),%eax
801040df:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
801040e6:	83 c4 10             	add    $0x10,%esp
}
801040e9:	eb da                	jmp    801040c5 <syscall+0x2f>

801040eb <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801040eb:	55                   	push   %ebp
801040ec:	89 e5                	mov    %esp,%ebp
801040ee:	56                   	push   %esi
801040ef:	53                   	push   %ebx
801040f0:	83 ec 18             	sub    $0x18,%esp
801040f3:	89 d6                	mov    %edx,%esi
801040f5:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801040f7:	8d 55 f4             	lea    -0xc(%ebp),%edx
801040fa:	52                   	push   %edx
801040fb:	50                   	push   %eax
801040fc:	e8 d2 fe ff ff       	call   80103fd3 <argint>
80104101:	83 c4 10             	add    $0x10,%esp
80104104:	85 c0                	test   %eax,%eax
80104106:	78 2e                	js     80104136 <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
80104108:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
8010410c:	77 2f                	ja     8010413d <argfd+0x52>
8010410e:	e8 2a f2 ff ff       	call   8010333d <myproc>
80104113:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104116:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
8010411a:	85 c0                	test   %eax,%eax
8010411c:	74 26                	je     80104144 <argfd+0x59>
    return -1;
  if(pfd)
8010411e:	85 f6                	test   %esi,%esi
80104120:	74 02                	je     80104124 <argfd+0x39>
    *pfd = fd;
80104122:	89 16                	mov    %edx,(%esi)
  if(pf)
80104124:	85 db                	test   %ebx,%ebx
80104126:	74 23                	je     8010414b <argfd+0x60>
    *pf = f;
80104128:	89 03                	mov    %eax,(%ebx)
  return 0;
8010412a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010412f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104132:	5b                   	pop    %ebx
80104133:	5e                   	pop    %esi
80104134:	5d                   	pop    %ebp
80104135:	c3                   	ret    
    return -1;
80104136:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010413b:	eb f2                	jmp    8010412f <argfd+0x44>
    return -1;
8010413d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104142:	eb eb                	jmp    8010412f <argfd+0x44>
80104144:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104149:	eb e4                	jmp    8010412f <argfd+0x44>
  return 0;
8010414b:	b8 00 00 00 00       	mov    $0x0,%eax
80104150:	eb dd                	jmp    8010412f <argfd+0x44>

80104152 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80104152:	55                   	push   %ebp
80104153:	89 e5                	mov    %esp,%ebp
80104155:	53                   	push   %ebx
80104156:	83 ec 04             	sub    $0x4,%esp
80104159:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
8010415b:	e8 dd f1 ff ff       	call   8010333d <myproc>

  for(fd = 0; fd < NOFILE; fd++){
80104160:	ba 00 00 00 00       	mov    $0x0,%edx
80104165:	83 fa 0f             	cmp    $0xf,%edx
80104168:	7f 18                	jg     80104182 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
8010416a:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
8010416f:	74 05                	je     80104176 <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
80104171:	83 c2 01             	add    $0x1,%edx
80104174:	eb ef                	jmp    80104165 <fdalloc+0x13>
      curproc->ofile[fd] = f;
80104176:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
8010417a:	89 d0                	mov    %edx,%eax
8010417c:	83 c4 04             	add    $0x4,%esp
8010417f:	5b                   	pop    %ebx
80104180:	5d                   	pop    %ebp
80104181:	c3                   	ret    
  return -1;
80104182:	ba ff ff ff ff       	mov    $0xffffffff,%edx
80104187:	eb f1                	jmp    8010417a <fdalloc+0x28>

80104189 <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80104189:	55                   	push   %ebp
8010418a:	89 e5                	mov    %esp,%ebp
8010418c:	56                   	push   %esi
8010418d:	53                   	push   %ebx
8010418e:	83 ec 10             	sub    $0x10,%esp
80104191:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104193:	b8 20 00 00 00       	mov    $0x20,%eax
80104198:	89 c6                	mov    %eax,%esi
8010419a:	39 43 58             	cmp    %eax,0x58(%ebx)
8010419d:	76 2e                	jbe    801041cd <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010419f:	6a 10                	push   $0x10
801041a1:	50                   	push   %eax
801041a2:	8d 45 e8             	lea    -0x18(%ebp),%eax
801041a5:	50                   	push   %eax
801041a6:	53                   	push   %ebx
801041a7:	e8 c7 d5 ff ff       	call   80101773 <readi>
801041ac:	83 c4 10             	add    $0x10,%esp
801041af:	83 f8 10             	cmp    $0x10,%eax
801041b2:	75 0c                	jne    801041c0 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
801041b4:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
801041b9:	75 1e                	jne    801041d9 <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801041bb:	8d 46 10             	lea    0x10(%esi),%eax
801041be:	eb d8                	jmp    80104198 <isdirempty+0xf>
      panic("isdirempty: readi");
801041c0:	83 ec 0c             	sub    $0xc,%esp
801041c3:	68 3c 6d 10 80       	push   $0x80106d3c
801041c8:	e8 7b c1 ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
801041cd:	b8 01 00 00 00       	mov    $0x1,%eax
}
801041d2:	8d 65 f8             	lea    -0x8(%ebp),%esp
801041d5:	5b                   	pop    %ebx
801041d6:	5e                   	pop    %esi
801041d7:	5d                   	pop    %ebp
801041d8:	c3                   	ret    
      return 0;
801041d9:	b8 00 00 00 00       	mov    $0x0,%eax
801041de:	eb f2                	jmp    801041d2 <isdirempty+0x49>

801041e0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
801041e0:	55                   	push   %ebp
801041e1:	89 e5                	mov    %esp,%ebp
801041e3:	57                   	push   %edi
801041e4:	56                   	push   %esi
801041e5:	53                   	push   %ebx
801041e6:	83 ec 44             	sub    $0x44,%esp
801041e9:	89 55 c4             	mov    %edx,-0x3c(%ebp)
801041ec:	89 4d c0             	mov    %ecx,-0x40(%ebp)
801041ef:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801041f2:	8d 55 d6             	lea    -0x2a(%ebp),%edx
801041f5:	52                   	push   %edx
801041f6:	50                   	push   %eax
801041f7:	e8 fd d9 ff ff       	call   80101bf9 <nameiparent>
801041fc:	89 c6                	mov    %eax,%esi
801041fe:	83 c4 10             	add    $0x10,%esp
80104201:	85 c0                	test   %eax,%eax
80104203:	0f 84 3a 01 00 00    	je     80104343 <create+0x163>
    return 0;
  ilock(dp);
80104209:	83 ec 0c             	sub    $0xc,%esp
8010420c:	50                   	push   %eax
8010420d:	e8 6f d3 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80104212:	83 c4 0c             	add    $0xc,%esp
80104215:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104218:	50                   	push   %eax
80104219:	8d 45 d6             	lea    -0x2a(%ebp),%eax
8010421c:	50                   	push   %eax
8010421d:	56                   	push   %esi
8010421e:	e8 8d d7 ff ff       	call   801019b0 <dirlookup>
80104223:	89 c3                	mov    %eax,%ebx
80104225:	83 c4 10             	add    $0x10,%esp
80104228:	85 c0                	test   %eax,%eax
8010422a:	74 3f                	je     8010426b <create+0x8b>
    iunlockput(dp);
8010422c:	83 ec 0c             	sub    $0xc,%esp
8010422f:	56                   	push   %esi
80104230:	e8 f3 d4 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
80104235:	89 1c 24             	mov    %ebx,(%esp)
80104238:	e8 44 d3 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
8010423d:	83 c4 10             	add    $0x10,%esp
80104240:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
80104245:	75 11                	jne    80104258 <create+0x78>
80104247:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
8010424c:	75 0a                	jne    80104258 <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
8010424e:	89 d8                	mov    %ebx,%eax
80104250:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104253:	5b                   	pop    %ebx
80104254:	5e                   	pop    %esi
80104255:	5f                   	pop    %edi
80104256:	5d                   	pop    %ebp
80104257:	c3                   	ret    
    iunlockput(ip);
80104258:	83 ec 0c             	sub    $0xc,%esp
8010425b:	53                   	push   %ebx
8010425c:	e8 c7 d4 ff ff       	call   80101728 <iunlockput>
    return 0;
80104261:	83 c4 10             	add    $0x10,%esp
80104264:	bb 00 00 00 00       	mov    $0x0,%ebx
80104269:	eb e3                	jmp    8010424e <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
8010426b:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
8010426f:	83 ec 08             	sub    $0x8,%esp
80104272:	50                   	push   %eax
80104273:	ff 36                	pushl  (%esi)
80104275:	e8 04 d1 ff ff       	call   8010137e <ialloc>
8010427a:	89 c3                	mov    %eax,%ebx
8010427c:	83 c4 10             	add    $0x10,%esp
8010427f:	85 c0                	test   %eax,%eax
80104281:	74 55                	je     801042d8 <create+0xf8>
  ilock(ip);
80104283:	83 ec 0c             	sub    $0xc,%esp
80104286:	50                   	push   %eax
80104287:	e8 f5 d2 ff ff       	call   80101581 <ilock>
  ip->major = major;
8010428c:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
80104290:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
80104294:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
80104298:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
8010429e:	89 1c 24             	mov    %ebx,(%esp)
801042a1:	e8 7a d1 ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
801042a6:	83 c4 10             	add    $0x10,%esp
801042a9:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
801042ae:	74 35                	je     801042e5 <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
801042b0:	83 ec 04             	sub    $0x4,%esp
801042b3:	ff 73 04             	pushl  0x4(%ebx)
801042b6:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801042b9:	50                   	push   %eax
801042ba:	56                   	push   %esi
801042bb:	e8 70 d8 ff ff       	call   80101b30 <dirlink>
801042c0:	83 c4 10             	add    $0x10,%esp
801042c3:	85 c0                	test   %eax,%eax
801042c5:	78 6f                	js     80104336 <create+0x156>
  iunlockput(dp);
801042c7:	83 ec 0c             	sub    $0xc,%esp
801042ca:	56                   	push   %esi
801042cb:	e8 58 d4 ff ff       	call   80101728 <iunlockput>
  return ip;
801042d0:	83 c4 10             	add    $0x10,%esp
801042d3:	e9 76 ff ff ff       	jmp    8010424e <create+0x6e>
    panic("create: ialloc");
801042d8:	83 ec 0c             	sub    $0xc,%esp
801042db:	68 4e 6d 10 80       	push   $0x80106d4e
801042e0:	e8 63 c0 ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
801042e5:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801042e9:	83 c0 01             	add    $0x1,%eax
801042ec:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801042f0:	83 ec 0c             	sub    $0xc,%esp
801042f3:	56                   	push   %esi
801042f4:	e8 27 d1 ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
801042f9:	83 c4 0c             	add    $0xc,%esp
801042fc:	ff 73 04             	pushl  0x4(%ebx)
801042ff:	68 5e 6d 10 80       	push   $0x80106d5e
80104304:	53                   	push   %ebx
80104305:	e8 26 d8 ff ff       	call   80101b30 <dirlink>
8010430a:	83 c4 10             	add    $0x10,%esp
8010430d:	85 c0                	test   %eax,%eax
8010430f:	78 18                	js     80104329 <create+0x149>
80104311:	83 ec 04             	sub    $0x4,%esp
80104314:	ff 76 04             	pushl  0x4(%esi)
80104317:	68 5d 6d 10 80       	push   $0x80106d5d
8010431c:	53                   	push   %ebx
8010431d:	e8 0e d8 ff ff       	call   80101b30 <dirlink>
80104322:	83 c4 10             	add    $0x10,%esp
80104325:	85 c0                	test   %eax,%eax
80104327:	79 87                	jns    801042b0 <create+0xd0>
      panic("create dots");
80104329:	83 ec 0c             	sub    $0xc,%esp
8010432c:	68 60 6d 10 80       	push   $0x80106d60
80104331:	e8 12 c0 ff ff       	call   80100348 <panic>
    panic("create: dirlink");
80104336:	83 ec 0c             	sub    $0xc,%esp
80104339:	68 6c 6d 10 80       	push   $0x80106d6c
8010433e:	e8 05 c0 ff ff       	call   80100348 <panic>
    return 0;
80104343:	89 c3                	mov    %eax,%ebx
80104345:	e9 04 ff ff ff       	jmp    8010424e <create+0x6e>

8010434a <sys_dup>:
{
8010434a:	55                   	push   %ebp
8010434b:	89 e5                	mov    %esp,%ebp
8010434d:	53                   	push   %ebx
8010434e:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
80104351:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104354:	ba 00 00 00 00       	mov    $0x0,%edx
80104359:	b8 00 00 00 00       	mov    $0x0,%eax
8010435e:	e8 88 fd ff ff       	call   801040eb <argfd>
80104363:	85 c0                	test   %eax,%eax
80104365:	78 23                	js     8010438a <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
80104367:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010436a:	e8 e3 fd ff ff       	call   80104152 <fdalloc>
8010436f:	89 c3                	mov    %eax,%ebx
80104371:	85 c0                	test   %eax,%eax
80104373:	78 1c                	js     80104391 <sys_dup+0x47>
  filedup(f);
80104375:	83 ec 0c             	sub    $0xc,%esp
80104378:	ff 75 f4             	pushl  -0xc(%ebp)
8010437b:	e8 0e c9 ff ff       	call   80100c8e <filedup>
  return fd;
80104380:	83 c4 10             	add    $0x10,%esp
}
80104383:	89 d8                	mov    %ebx,%eax
80104385:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104388:	c9                   	leave  
80104389:	c3                   	ret    
    return -1;
8010438a:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010438f:	eb f2                	jmp    80104383 <sys_dup+0x39>
    return -1;
80104391:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104396:	eb eb                	jmp    80104383 <sys_dup+0x39>

80104398 <sys_read>:
{
80104398:	55                   	push   %ebp
80104399:	89 e5                	mov    %esp,%ebp
8010439b:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010439e:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801043a1:	ba 00 00 00 00       	mov    $0x0,%edx
801043a6:	b8 00 00 00 00       	mov    $0x0,%eax
801043ab:	e8 3b fd ff ff       	call   801040eb <argfd>
801043b0:	85 c0                	test   %eax,%eax
801043b2:	78 43                	js     801043f7 <sys_read+0x5f>
801043b4:	83 ec 08             	sub    $0x8,%esp
801043b7:	8d 45 f0             	lea    -0x10(%ebp),%eax
801043ba:	50                   	push   %eax
801043bb:	6a 02                	push   $0x2
801043bd:	e8 11 fc ff ff       	call   80103fd3 <argint>
801043c2:	83 c4 10             	add    $0x10,%esp
801043c5:	85 c0                	test   %eax,%eax
801043c7:	78 35                	js     801043fe <sys_read+0x66>
801043c9:	83 ec 04             	sub    $0x4,%esp
801043cc:	ff 75 f0             	pushl  -0x10(%ebp)
801043cf:	8d 45 ec             	lea    -0x14(%ebp),%eax
801043d2:	50                   	push   %eax
801043d3:	6a 01                	push   $0x1
801043d5:	e8 21 fc ff ff       	call   80103ffb <argptr>
801043da:	83 c4 10             	add    $0x10,%esp
801043dd:	85 c0                	test   %eax,%eax
801043df:	78 24                	js     80104405 <sys_read+0x6d>
  return fileread(f, p, n);
801043e1:	83 ec 04             	sub    $0x4,%esp
801043e4:	ff 75 f0             	pushl  -0x10(%ebp)
801043e7:	ff 75 ec             	pushl  -0x14(%ebp)
801043ea:	ff 75 f4             	pushl  -0xc(%ebp)
801043ed:	e8 e5 c9 ff ff       	call   80100dd7 <fileread>
801043f2:	83 c4 10             	add    $0x10,%esp
}
801043f5:	c9                   	leave  
801043f6:	c3                   	ret    
    return -1;
801043f7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043fc:	eb f7                	jmp    801043f5 <sys_read+0x5d>
801043fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104403:	eb f0                	jmp    801043f5 <sys_read+0x5d>
80104405:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010440a:	eb e9                	jmp    801043f5 <sys_read+0x5d>

8010440c <sys_write>:
{
8010440c:	55                   	push   %ebp
8010440d:	89 e5                	mov    %esp,%ebp
8010440f:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104412:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104415:	ba 00 00 00 00       	mov    $0x0,%edx
8010441a:	b8 00 00 00 00       	mov    $0x0,%eax
8010441f:	e8 c7 fc ff ff       	call   801040eb <argfd>
80104424:	85 c0                	test   %eax,%eax
80104426:	78 43                	js     8010446b <sys_write+0x5f>
80104428:	83 ec 08             	sub    $0x8,%esp
8010442b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010442e:	50                   	push   %eax
8010442f:	6a 02                	push   $0x2
80104431:	e8 9d fb ff ff       	call   80103fd3 <argint>
80104436:	83 c4 10             	add    $0x10,%esp
80104439:	85 c0                	test   %eax,%eax
8010443b:	78 35                	js     80104472 <sys_write+0x66>
8010443d:	83 ec 04             	sub    $0x4,%esp
80104440:	ff 75 f0             	pushl  -0x10(%ebp)
80104443:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104446:	50                   	push   %eax
80104447:	6a 01                	push   $0x1
80104449:	e8 ad fb ff ff       	call   80103ffb <argptr>
8010444e:	83 c4 10             	add    $0x10,%esp
80104451:	85 c0                	test   %eax,%eax
80104453:	78 24                	js     80104479 <sys_write+0x6d>
  return filewrite(f, p, n);
80104455:	83 ec 04             	sub    $0x4,%esp
80104458:	ff 75 f0             	pushl  -0x10(%ebp)
8010445b:	ff 75 ec             	pushl  -0x14(%ebp)
8010445e:	ff 75 f4             	pushl  -0xc(%ebp)
80104461:	e8 f6 c9 ff ff       	call   80100e5c <filewrite>
80104466:	83 c4 10             	add    $0x10,%esp
}
80104469:	c9                   	leave  
8010446a:	c3                   	ret    
    return -1;
8010446b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104470:	eb f7                	jmp    80104469 <sys_write+0x5d>
80104472:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104477:	eb f0                	jmp    80104469 <sys_write+0x5d>
80104479:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010447e:	eb e9                	jmp    80104469 <sys_write+0x5d>

80104480 <sys_close>:
{
80104480:	55                   	push   %ebp
80104481:	89 e5                	mov    %esp,%ebp
80104483:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
80104486:	8d 4d f0             	lea    -0x10(%ebp),%ecx
80104489:	8d 55 f4             	lea    -0xc(%ebp),%edx
8010448c:	b8 00 00 00 00       	mov    $0x0,%eax
80104491:	e8 55 fc ff ff       	call   801040eb <argfd>
80104496:	85 c0                	test   %eax,%eax
80104498:	78 25                	js     801044bf <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
8010449a:	e8 9e ee ff ff       	call   8010333d <myproc>
8010449f:	8b 55 f4             	mov    -0xc(%ebp),%edx
801044a2:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
801044a9:	00 
  fileclose(f);
801044aa:	83 ec 0c             	sub    $0xc,%esp
801044ad:	ff 75 f0             	pushl  -0x10(%ebp)
801044b0:	e8 1e c8 ff ff       	call   80100cd3 <fileclose>
  return 0;
801044b5:	83 c4 10             	add    $0x10,%esp
801044b8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801044bd:	c9                   	leave  
801044be:	c3                   	ret    
    return -1;
801044bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044c4:	eb f7                	jmp    801044bd <sys_close+0x3d>

801044c6 <sys_fstat>:
{
801044c6:	55                   	push   %ebp
801044c7:	89 e5                	mov    %esp,%ebp
801044c9:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801044cc:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801044cf:	ba 00 00 00 00       	mov    $0x0,%edx
801044d4:	b8 00 00 00 00       	mov    $0x0,%eax
801044d9:	e8 0d fc ff ff       	call   801040eb <argfd>
801044de:	85 c0                	test   %eax,%eax
801044e0:	78 2a                	js     8010450c <sys_fstat+0x46>
801044e2:	83 ec 04             	sub    $0x4,%esp
801044e5:	6a 14                	push   $0x14
801044e7:	8d 45 f0             	lea    -0x10(%ebp),%eax
801044ea:	50                   	push   %eax
801044eb:	6a 01                	push   $0x1
801044ed:	e8 09 fb ff ff       	call   80103ffb <argptr>
801044f2:	83 c4 10             	add    $0x10,%esp
801044f5:	85 c0                	test   %eax,%eax
801044f7:	78 1a                	js     80104513 <sys_fstat+0x4d>
  return filestat(f, st);
801044f9:	83 ec 08             	sub    $0x8,%esp
801044fc:	ff 75 f0             	pushl  -0x10(%ebp)
801044ff:	ff 75 f4             	pushl  -0xc(%ebp)
80104502:	e8 89 c8 ff ff       	call   80100d90 <filestat>
80104507:	83 c4 10             	add    $0x10,%esp
}
8010450a:	c9                   	leave  
8010450b:	c3                   	ret    
    return -1;
8010450c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104511:	eb f7                	jmp    8010450a <sys_fstat+0x44>
80104513:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104518:	eb f0                	jmp    8010450a <sys_fstat+0x44>

8010451a <sys_link>:
{
8010451a:	55                   	push   %ebp
8010451b:	89 e5                	mov    %esp,%ebp
8010451d:	56                   	push   %esi
8010451e:	53                   	push   %ebx
8010451f:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80104522:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104525:	50                   	push   %eax
80104526:	6a 00                	push   $0x0
80104528:	e8 36 fb ff ff       	call   80104063 <argstr>
8010452d:	83 c4 10             	add    $0x10,%esp
80104530:	85 c0                	test   %eax,%eax
80104532:	0f 88 32 01 00 00    	js     8010466a <sys_link+0x150>
80104538:	83 ec 08             	sub    $0x8,%esp
8010453b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010453e:	50                   	push   %eax
8010453f:	6a 01                	push   $0x1
80104541:	e8 1d fb ff ff       	call   80104063 <argstr>
80104546:	83 c4 10             	add    $0x10,%esp
80104549:	85 c0                	test   %eax,%eax
8010454b:	0f 88 20 01 00 00    	js     80104671 <sys_link+0x157>
  begin_op();
80104551:	e8 97 e3 ff ff       	call   801028ed <begin_op>
  if((ip = namei(old)) == 0){
80104556:	83 ec 0c             	sub    $0xc,%esp
80104559:	ff 75 e0             	pushl  -0x20(%ebp)
8010455c:	e8 80 d6 ff ff       	call   80101be1 <namei>
80104561:	89 c3                	mov    %eax,%ebx
80104563:	83 c4 10             	add    $0x10,%esp
80104566:	85 c0                	test   %eax,%eax
80104568:	0f 84 99 00 00 00    	je     80104607 <sys_link+0xed>
  ilock(ip);
8010456e:	83 ec 0c             	sub    $0xc,%esp
80104571:	50                   	push   %eax
80104572:	e8 0a d0 ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
80104577:	83 c4 10             	add    $0x10,%esp
8010457a:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010457f:	0f 84 8e 00 00 00    	je     80104613 <sys_link+0xf9>
  ip->nlink++;
80104585:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104589:	83 c0 01             	add    $0x1,%eax
8010458c:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104590:	83 ec 0c             	sub    $0xc,%esp
80104593:	53                   	push   %ebx
80104594:	e8 87 ce ff ff       	call   80101420 <iupdate>
  iunlock(ip);
80104599:	89 1c 24             	mov    %ebx,(%esp)
8010459c:	e8 a2 d0 ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
801045a1:	83 c4 08             	add    $0x8,%esp
801045a4:	8d 45 ea             	lea    -0x16(%ebp),%eax
801045a7:	50                   	push   %eax
801045a8:	ff 75 e4             	pushl  -0x1c(%ebp)
801045ab:	e8 49 d6 ff ff       	call   80101bf9 <nameiparent>
801045b0:	89 c6                	mov    %eax,%esi
801045b2:	83 c4 10             	add    $0x10,%esp
801045b5:	85 c0                	test   %eax,%eax
801045b7:	74 7e                	je     80104637 <sys_link+0x11d>
  ilock(dp);
801045b9:	83 ec 0c             	sub    $0xc,%esp
801045bc:	50                   	push   %eax
801045bd:	e8 bf cf ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801045c2:	83 c4 10             	add    $0x10,%esp
801045c5:	8b 03                	mov    (%ebx),%eax
801045c7:	39 06                	cmp    %eax,(%esi)
801045c9:	75 60                	jne    8010462b <sys_link+0x111>
801045cb:	83 ec 04             	sub    $0x4,%esp
801045ce:	ff 73 04             	pushl  0x4(%ebx)
801045d1:	8d 45 ea             	lea    -0x16(%ebp),%eax
801045d4:	50                   	push   %eax
801045d5:	56                   	push   %esi
801045d6:	e8 55 d5 ff ff       	call   80101b30 <dirlink>
801045db:	83 c4 10             	add    $0x10,%esp
801045de:	85 c0                	test   %eax,%eax
801045e0:	78 49                	js     8010462b <sys_link+0x111>
  iunlockput(dp);
801045e2:	83 ec 0c             	sub    $0xc,%esp
801045e5:	56                   	push   %esi
801045e6:	e8 3d d1 ff ff       	call   80101728 <iunlockput>
  iput(ip);
801045eb:	89 1c 24             	mov    %ebx,(%esp)
801045ee:	e8 95 d0 ff ff       	call   80101688 <iput>
  end_op();
801045f3:	e8 6f e3 ff ff       	call   80102967 <end_op>
  return 0;
801045f8:	83 c4 10             	add    $0x10,%esp
801045fb:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104600:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104603:	5b                   	pop    %ebx
80104604:	5e                   	pop    %esi
80104605:	5d                   	pop    %ebp
80104606:	c3                   	ret    
    end_op();
80104607:	e8 5b e3 ff ff       	call   80102967 <end_op>
    return -1;
8010460c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104611:	eb ed                	jmp    80104600 <sys_link+0xe6>
    iunlockput(ip);
80104613:	83 ec 0c             	sub    $0xc,%esp
80104616:	53                   	push   %ebx
80104617:	e8 0c d1 ff ff       	call   80101728 <iunlockput>
    end_op();
8010461c:	e8 46 e3 ff ff       	call   80102967 <end_op>
    return -1;
80104621:	83 c4 10             	add    $0x10,%esp
80104624:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104629:	eb d5                	jmp    80104600 <sys_link+0xe6>
    iunlockput(dp);
8010462b:	83 ec 0c             	sub    $0xc,%esp
8010462e:	56                   	push   %esi
8010462f:	e8 f4 d0 ff ff       	call   80101728 <iunlockput>
    goto bad;
80104634:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
80104637:	83 ec 0c             	sub    $0xc,%esp
8010463a:	53                   	push   %ebx
8010463b:	e8 41 cf ff ff       	call   80101581 <ilock>
  ip->nlink--;
80104640:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104644:	83 e8 01             	sub    $0x1,%eax
80104647:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
8010464b:	89 1c 24             	mov    %ebx,(%esp)
8010464e:	e8 cd cd ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104653:	89 1c 24             	mov    %ebx,(%esp)
80104656:	e8 cd d0 ff ff       	call   80101728 <iunlockput>
  end_op();
8010465b:	e8 07 e3 ff ff       	call   80102967 <end_op>
  return -1;
80104660:	83 c4 10             	add    $0x10,%esp
80104663:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104668:	eb 96                	jmp    80104600 <sys_link+0xe6>
    return -1;
8010466a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010466f:	eb 8f                	jmp    80104600 <sys_link+0xe6>
80104671:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104676:	eb 88                	jmp    80104600 <sys_link+0xe6>

80104678 <sys_unlink>:
{
80104678:	55                   	push   %ebp
80104679:	89 e5                	mov    %esp,%ebp
8010467b:	57                   	push   %edi
8010467c:	56                   	push   %esi
8010467d:	53                   	push   %ebx
8010467e:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
80104681:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104684:	50                   	push   %eax
80104685:	6a 00                	push   $0x0
80104687:	e8 d7 f9 ff ff       	call   80104063 <argstr>
8010468c:	83 c4 10             	add    $0x10,%esp
8010468f:	85 c0                	test   %eax,%eax
80104691:	0f 88 83 01 00 00    	js     8010481a <sys_unlink+0x1a2>
  begin_op();
80104697:	e8 51 e2 ff ff       	call   801028ed <begin_op>
  if((dp = nameiparent(path, name)) == 0){
8010469c:	83 ec 08             	sub    $0x8,%esp
8010469f:	8d 45 ca             	lea    -0x36(%ebp),%eax
801046a2:	50                   	push   %eax
801046a3:	ff 75 c4             	pushl  -0x3c(%ebp)
801046a6:	e8 4e d5 ff ff       	call   80101bf9 <nameiparent>
801046ab:	89 c6                	mov    %eax,%esi
801046ad:	83 c4 10             	add    $0x10,%esp
801046b0:	85 c0                	test   %eax,%eax
801046b2:	0f 84 ed 00 00 00    	je     801047a5 <sys_unlink+0x12d>
  ilock(dp);
801046b8:	83 ec 0c             	sub    $0xc,%esp
801046bb:	50                   	push   %eax
801046bc:	e8 c0 ce ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801046c1:	83 c4 08             	add    $0x8,%esp
801046c4:	68 5e 6d 10 80       	push   $0x80106d5e
801046c9:	8d 45 ca             	lea    -0x36(%ebp),%eax
801046cc:	50                   	push   %eax
801046cd:	e8 c9 d2 ff ff       	call   8010199b <namecmp>
801046d2:	83 c4 10             	add    $0x10,%esp
801046d5:	85 c0                	test   %eax,%eax
801046d7:	0f 84 fc 00 00 00    	je     801047d9 <sys_unlink+0x161>
801046dd:	83 ec 08             	sub    $0x8,%esp
801046e0:	68 5d 6d 10 80       	push   $0x80106d5d
801046e5:	8d 45 ca             	lea    -0x36(%ebp),%eax
801046e8:	50                   	push   %eax
801046e9:	e8 ad d2 ff ff       	call   8010199b <namecmp>
801046ee:	83 c4 10             	add    $0x10,%esp
801046f1:	85 c0                	test   %eax,%eax
801046f3:	0f 84 e0 00 00 00    	je     801047d9 <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
801046f9:	83 ec 04             	sub    $0x4,%esp
801046fc:	8d 45 c0             	lea    -0x40(%ebp),%eax
801046ff:	50                   	push   %eax
80104700:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104703:	50                   	push   %eax
80104704:	56                   	push   %esi
80104705:	e8 a6 d2 ff ff       	call   801019b0 <dirlookup>
8010470a:	89 c3                	mov    %eax,%ebx
8010470c:	83 c4 10             	add    $0x10,%esp
8010470f:	85 c0                	test   %eax,%eax
80104711:	0f 84 c2 00 00 00    	je     801047d9 <sys_unlink+0x161>
  ilock(ip);
80104717:	83 ec 0c             	sub    $0xc,%esp
8010471a:	50                   	push   %eax
8010471b:	e8 61 ce ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
80104720:	83 c4 10             	add    $0x10,%esp
80104723:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
80104728:	0f 8e 83 00 00 00    	jle    801047b1 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010472e:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104733:	0f 84 85 00 00 00    	je     801047be <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
80104739:	83 ec 04             	sub    $0x4,%esp
8010473c:	6a 10                	push   $0x10
8010473e:	6a 00                	push   $0x0
80104740:	8d 7d d8             	lea    -0x28(%ebp),%edi
80104743:	57                   	push   %edi
80104744:	e8 3f f6 ff ff       	call   80103d88 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104749:	6a 10                	push   $0x10
8010474b:	ff 75 c0             	pushl  -0x40(%ebp)
8010474e:	57                   	push   %edi
8010474f:	56                   	push   %esi
80104750:	e8 1b d1 ff ff       	call   80101870 <writei>
80104755:	83 c4 20             	add    $0x20,%esp
80104758:	83 f8 10             	cmp    $0x10,%eax
8010475b:	0f 85 90 00 00 00    	jne    801047f1 <sys_unlink+0x179>
  if(ip->type == T_DIR){
80104761:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104766:	0f 84 92 00 00 00    	je     801047fe <sys_unlink+0x186>
  iunlockput(dp);
8010476c:	83 ec 0c             	sub    $0xc,%esp
8010476f:	56                   	push   %esi
80104770:	e8 b3 cf ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
80104775:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104779:	83 e8 01             	sub    $0x1,%eax
8010477c:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104780:	89 1c 24             	mov    %ebx,(%esp)
80104783:	e8 98 cc ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104788:	89 1c 24             	mov    %ebx,(%esp)
8010478b:	e8 98 cf ff ff       	call   80101728 <iunlockput>
  end_op();
80104790:	e8 d2 e1 ff ff       	call   80102967 <end_op>
  return 0;
80104795:	83 c4 10             	add    $0x10,%esp
80104798:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010479d:	8d 65 f4             	lea    -0xc(%ebp),%esp
801047a0:	5b                   	pop    %ebx
801047a1:	5e                   	pop    %esi
801047a2:	5f                   	pop    %edi
801047a3:	5d                   	pop    %ebp
801047a4:	c3                   	ret    
    end_op();
801047a5:	e8 bd e1 ff ff       	call   80102967 <end_op>
    return -1;
801047aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047af:	eb ec                	jmp    8010479d <sys_unlink+0x125>
    panic("unlink: nlink < 1");
801047b1:	83 ec 0c             	sub    $0xc,%esp
801047b4:	68 7c 6d 10 80       	push   $0x80106d7c
801047b9:	e8 8a bb ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801047be:	89 d8                	mov    %ebx,%eax
801047c0:	e8 c4 f9 ff ff       	call   80104189 <isdirempty>
801047c5:	85 c0                	test   %eax,%eax
801047c7:	0f 85 6c ff ff ff    	jne    80104739 <sys_unlink+0xc1>
    iunlockput(ip);
801047cd:	83 ec 0c             	sub    $0xc,%esp
801047d0:	53                   	push   %ebx
801047d1:	e8 52 cf ff ff       	call   80101728 <iunlockput>
    goto bad;
801047d6:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
801047d9:	83 ec 0c             	sub    $0xc,%esp
801047dc:	56                   	push   %esi
801047dd:	e8 46 cf ff ff       	call   80101728 <iunlockput>
  end_op();
801047e2:	e8 80 e1 ff ff       	call   80102967 <end_op>
  return -1;
801047e7:	83 c4 10             	add    $0x10,%esp
801047ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047ef:	eb ac                	jmp    8010479d <sys_unlink+0x125>
    panic("unlink: writei");
801047f1:	83 ec 0c             	sub    $0xc,%esp
801047f4:	68 8e 6d 10 80       	push   $0x80106d8e
801047f9:	e8 4a bb ff ff       	call   80100348 <panic>
    dp->nlink--;
801047fe:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104802:	83 e8 01             	sub    $0x1,%eax
80104805:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104809:	83 ec 0c             	sub    $0xc,%esp
8010480c:	56                   	push   %esi
8010480d:	e8 0e cc ff ff       	call   80101420 <iupdate>
80104812:	83 c4 10             	add    $0x10,%esp
80104815:	e9 52 ff ff ff       	jmp    8010476c <sys_unlink+0xf4>
    return -1;
8010481a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010481f:	e9 79 ff ff ff       	jmp    8010479d <sys_unlink+0x125>

80104824 <sys_open>:

int
sys_open(void)
{
80104824:	55                   	push   %ebp
80104825:	89 e5                	mov    %esp,%ebp
80104827:	57                   	push   %edi
80104828:	56                   	push   %esi
80104829:	53                   	push   %ebx
8010482a:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
8010482d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104830:	50                   	push   %eax
80104831:	6a 00                	push   $0x0
80104833:	e8 2b f8 ff ff       	call   80104063 <argstr>
80104838:	83 c4 10             	add    $0x10,%esp
8010483b:	85 c0                	test   %eax,%eax
8010483d:	0f 88 30 01 00 00    	js     80104973 <sys_open+0x14f>
80104843:	83 ec 08             	sub    $0x8,%esp
80104846:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104849:	50                   	push   %eax
8010484a:	6a 01                	push   $0x1
8010484c:	e8 82 f7 ff ff       	call   80103fd3 <argint>
80104851:	83 c4 10             	add    $0x10,%esp
80104854:	85 c0                	test   %eax,%eax
80104856:	0f 88 21 01 00 00    	js     8010497d <sys_open+0x159>
    return -1;

  begin_op();
8010485c:	e8 8c e0 ff ff       	call   801028ed <begin_op>

  if(omode & O_CREATE){
80104861:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
80104865:	0f 84 84 00 00 00    	je     801048ef <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
8010486b:	83 ec 0c             	sub    $0xc,%esp
8010486e:	6a 00                	push   $0x0
80104870:	b9 00 00 00 00       	mov    $0x0,%ecx
80104875:	ba 02 00 00 00       	mov    $0x2,%edx
8010487a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010487d:	e8 5e f9 ff ff       	call   801041e0 <create>
80104882:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104884:	83 c4 10             	add    $0x10,%esp
80104887:	85 c0                	test   %eax,%eax
80104889:	74 58                	je     801048e3 <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
8010488b:	e8 9d c3 ff ff       	call   80100c2d <filealloc>
80104890:	89 c3                	mov    %eax,%ebx
80104892:	85 c0                	test   %eax,%eax
80104894:	0f 84 ae 00 00 00    	je     80104948 <sys_open+0x124>
8010489a:	e8 b3 f8 ff ff       	call   80104152 <fdalloc>
8010489f:	89 c7                	mov    %eax,%edi
801048a1:	85 c0                	test   %eax,%eax
801048a3:	0f 88 9f 00 00 00    	js     80104948 <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
801048a9:	83 ec 0c             	sub    $0xc,%esp
801048ac:	56                   	push   %esi
801048ad:	e8 91 cd ff ff       	call   80101643 <iunlock>
  end_op();
801048b2:	e8 b0 e0 ff ff       	call   80102967 <end_op>

  f->type = FD_INODE;
801048b7:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
801048bd:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
801048c0:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
801048c7:	8b 45 e0             	mov    -0x20(%ebp),%eax
801048ca:	83 c4 10             	add    $0x10,%esp
801048cd:	a8 01                	test   $0x1,%al
801048cf:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
801048d3:	a8 03                	test   $0x3,%al
801048d5:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
801048d9:	89 f8                	mov    %edi,%eax
801048db:	8d 65 f4             	lea    -0xc(%ebp),%esp
801048de:	5b                   	pop    %ebx
801048df:	5e                   	pop    %esi
801048e0:	5f                   	pop    %edi
801048e1:	5d                   	pop    %ebp
801048e2:	c3                   	ret    
      end_op();
801048e3:	e8 7f e0 ff ff       	call   80102967 <end_op>
      return -1;
801048e8:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801048ed:	eb ea                	jmp    801048d9 <sys_open+0xb5>
    if((ip = namei(path)) == 0){
801048ef:	83 ec 0c             	sub    $0xc,%esp
801048f2:	ff 75 e4             	pushl  -0x1c(%ebp)
801048f5:	e8 e7 d2 ff ff       	call   80101be1 <namei>
801048fa:	89 c6                	mov    %eax,%esi
801048fc:	83 c4 10             	add    $0x10,%esp
801048ff:	85 c0                	test   %eax,%eax
80104901:	74 39                	je     8010493c <sys_open+0x118>
    ilock(ip);
80104903:	83 ec 0c             	sub    $0xc,%esp
80104906:	50                   	push   %eax
80104907:	e8 75 cc ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
8010490c:	83 c4 10             	add    $0x10,%esp
8010490f:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104914:	0f 85 71 ff ff ff    	jne    8010488b <sys_open+0x67>
8010491a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010491e:	0f 84 67 ff ff ff    	je     8010488b <sys_open+0x67>
      iunlockput(ip);
80104924:	83 ec 0c             	sub    $0xc,%esp
80104927:	56                   	push   %esi
80104928:	e8 fb cd ff ff       	call   80101728 <iunlockput>
      end_op();
8010492d:	e8 35 e0 ff ff       	call   80102967 <end_op>
      return -1;
80104932:	83 c4 10             	add    $0x10,%esp
80104935:	bf ff ff ff ff       	mov    $0xffffffff,%edi
8010493a:	eb 9d                	jmp    801048d9 <sys_open+0xb5>
      end_op();
8010493c:	e8 26 e0 ff ff       	call   80102967 <end_op>
      return -1;
80104941:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104946:	eb 91                	jmp    801048d9 <sys_open+0xb5>
    if(f)
80104948:	85 db                	test   %ebx,%ebx
8010494a:	74 0c                	je     80104958 <sys_open+0x134>
      fileclose(f);
8010494c:	83 ec 0c             	sub    $0xc,%esp
8010494f:	53                   	push   %ebx
80104950:	e8 7e c3 ff ff       	call   80100cd3 <fileclose>
80104955:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104958:	83 ec 0c             	sub    $0xc,%esp
8010495b:	56                   	push   %esi
8010495c:	e8 c7 cd ff ff       	call   80101728 <iunlockput>
    end_op();
80104961:	e8 01 e0 ff ff       	call   80102967 <end_op>
    return -1;
80104966:	83 c4 10             	add    $0x10,%esp
80104969:	bf ff ff ff ff       	mov    $0xffffffff,%edi
8010496e:	e9 66 ff ff ff       	jmp    801048d9 <sys_open+0xb5>
    return -1;
80104973:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104978:	e9 5c ff ff ff       	jmp    801048d9 <sys_open+0xb5>
8010497d:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104982:	e9 52 ff ff ff       	jmp    801048d9 <sys_open+0xb5>

80104987 <sys_mkdir>:

int
sys_mkdir(void)
{
80104987:	55                   	push   %ebp
80104988:	89 e5                	mov    %esp,%ebp
8010498a:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
8010498d:	e8 5b df ff ff       	call   801028ed <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104992:	83 ec 08             	sub    $0x8,%esp
80104995:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104998:	50                   	push   %eax
80104999:	6a 00                	push   $0x0
8010499b:	e8 c3 f6 ff ff       	call   80104063 <argstr>
801049a0:	83 c4 10             	add    $0x10,%esp
801049a3:	85 c0                	test   %eax,%eax
801049a5:	78 36                	js     801049dd <sys_mkdir+0x56>
801049a7:	83 ec 0c             	sub    $0xc,%esp
801049aa:	6a 00                	push   $0x0
801049ac:	b9 00 00 00 00       	mov    $0x0,%ecx
801049b1:	ba 01 00 00 00       	mov    $0x1,%edx
801049b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049b9:	e8 22 f8 ff ff       	call   801041e0 <create>
801049be:	83 c4 10             	add    $0x10,%esp
801049c1:	85 c0                	test   %eax,%eax
801049c3:	74 18                	je     801049dd <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
801049c5:	83 ec 0c             	sub    $0xc,%esp
801049c8:	50                   	push   %eax
801049c9:	e8 5a cd ff ff       	call   80101728 <iunlockput>
  end_op();
801049ce:	e8 94 df ff ff       	call   80102967 <end_op>
  return 0;
801049d3:	83 c4 10             	add    $0x10,%esp
801049d6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801049db:	c9                   	leave  
801049dc:	c3                   	ret    
    end_op();
801049dd:	e8 85 df ff ff       	call   80102967 <end_op>
    return -1;
801049e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049e7:	eb f2                	jmp    801049db <sys_mkdir+0x54>

801049e9 <sys_mknod>:

int
sys_mknod(void)
{
801049e9:	55                   	push   %ebp
801049ea:	89 e5                	mov    %esp,%ebp
801049ec:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
801049ef:	e8 f9 de ff ff       	call   801028ed <begin_op>
  if((argstr(0, &path)) < 0 ||
801049f4:	83 ec 08             	sub    $0x8,%esp
801049f7:	8d 45 f4             	lea    -0xc(%ebp),%eax
801049fa:	50                   	push   %eax
801049fb:	6a 00                	push   $0x0
801049fd:	e8 61 f6 ff ff       	call   80104063 <argstr>
80104a02:	83 c4 10             	add    $0x10,%esp
80104a05:	85 c0                	test   %eax,%eax
80104a07:	78 62                	js     80104a6b <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104a09:	83 ec 08             	sub    $0x8,%esp
80104a0c:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104a0f:	50                   	push   %eax
80104a10:	6a 01                	push   $0x1
80104a12:	e8 bc f5 ff ff       	call   80103fd3 <argint>
  if((argstr(0, &path)) < 0 ||
80104a17:	83 c4 10             	add    $0x10,%esp
80104a1a:	85 c0                	test   %eax,%eax
80104a1c:	78 4d                	js     80104a6b <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104a1e:	83 ec 08             	sub    $0x8,%esp
80104a21:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104a24:	50                   	push   %eax
80104a25:	6a 02                	push   $0x2
80104a27:	e8 a7 f5 ff ff       	call   80103fd3 <argint>
     argint(1, &major) < 0 ||
80104a2c:	83 c4 10             	add    $0x10,%esp
80104a2f:	85 c0                	test   %eax,%eax
80104a31:	78 38                	js     80104a6b <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104a33:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104a37:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104a3b:	83 ec 0c             	sub    $0xc,%esp
80104a3e:	50                   	push   %eax
80104a3f:	ba 03 00 00 00       	mov    $0x3,%edx
80104a44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a47:	e8 94 f7 ff ff       	call   801041e0 <create>
80104a4c:	83 c4 10             	add    $0x10,%esp
80104a4f:	85 c0                	test   %eax,%eax
80104a51:	74 18                	je     80104a6b <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104a53:	83 ec 0c             	sub    $0xc,%esp
80104a56:	50                   	push   %eax
80104a57:	e8 cc cc ff ff       	call   80101728 <iunlockput>
  end_op();
80104a5c:	e8 06 df ff ff       	call   80102967 <end_op>
  return 0;
80104a61:	83 c4 10             	add    $0x10,%esp
80104a64:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a69:	c9                   	leave  
80104a6a:	c3                   	ret    
    end_op();
80104a6b:	e8 f7 de ff ff       	call   80102967 <end_op>
    return -1;
80104a70:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a75:	eb f2                	jmp    80104a69 <sys_mknod+0x80>

80104a77 <sys_chdir>:

int
sys_chdir(void)
{
80104a77:	55                   	push   %ebp
80104a78:	89 e5                	mov    %esp,%ebp
80104a7a:	56                   	push   %esi
80104a7b:	53                   	push   %ebx
80104a7c:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104a7f:	e8 b9 e8 ff ff       	call   8010333d <myproc>
80104a84:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104a86:	e8 62 de ff ff       	call   801028ed <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104a8b:	83 ec 08             	sub    $0x8,%esp
80104a8e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104a91:	50                   	push   %eax
80104a92:	6a 00                	push   $0x0
80104a94:	e8 ca f5 ff ff       	call   80104063 <argstr>
80104a99:	83 c4 10             	add    $0x10,%esp
80104a9c:	85 c0                	test   %eax,%eax
80104a9e:	78 52                	js     80104af2 <sys_chdir+0x7b>
80104aa0:	83 ec 0c             	sub    $0xc,%esp
80104aa3:	ff 75 f4             	pushl  -0xc(%ebp)
80104aa6:	e8 36 d1 ff ff       	call   80101be1 <namei>
80104aab:	89 c3                	mov    %eax,%ebx
80104aad:	83 c4 10             	add    $0x10,%esp
80104ab0:	85 c0                	test   %eax,%eax
80104ab2:	74 3e                	je     80104af2 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104ab4:	83 ec 0c             	sub    $0xc,%esp
80104ab7:	50                   	push   %eax
80104ab8:	e8 c4 ca ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104abd:	83 c4 10             	add    $0x10,%esp
80104ac0:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104ac5:	75 37                	jne    80104afe <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104ac7:	83 ec 0c             	sub    $0xc,%esp
80104aca:	53                   	push   %ebx
80104acb:	e8 73 cb ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104ad0:	83 c4 04             	add    $0x4,%esp
80104ad3:	ff 76 68             	pushl  0x68(%esi)
80104ad6:	e8 ad cb ff ff       	call   80101688 <iput>
  end_op();
80104adb:	e8 87 de ff ff       	call   80102967 <end_op>
  curproc->cwd = ip;
80104ae0:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104ae3:	83 c4 10             	add    $0x10,%esp
80104ae6:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104aeb:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104aee:	5b                   	pop    %ebx
80104aef:	5e                   	pop    %esi
80104af0:	5d                   	pop    %ebp
80104af1:	c3                   	ret    
    end_op();
80104af2:	e8 70 de ff ff       	call   80102967 <end_op>
    return -1;
80104af7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104afc:	eb ed                	jmp    80104aeb <sys_chdir+0x74>
    iunlockput(ip);
80104afe:	83 ec 0c             	sub    $0xc,%esp
80104b01:	53                   	push   %ebx
80104b02:	e8 21 cc ff ff       	call   80101728 <iunlockput>
    end_op();
80104b07:	e8 5b de ff ff       	call   80102967 <end_op>
    return -1;
80104b0c:	83 c4 10             	add    $0x10,%esp
80104b0f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b14:	eb d5                	jmp    80104aeb <sys_chdir+0x74>

80104b16 <sys_exec>:

int
sys_exec(void)
{
80104b16:	55                   	push   %ebp
80104b17:	89 e5                	mov    %esp,%ebp
80104b19:	53                   	push   %ebx
80104b1a:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104b20:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b23:	50                   	push   %eax
80104b24:	6a 00                	push   $0x0
80104b26:	e8 38 f5 ff ff       	call   80104063 <argstr>
80104b2b:	83 c4 10             	add    $0x10,%esp
80104b2e:	85 c0                	test   %eax,%eax
80104b30:	0f 88 a8 00 00 00    	js     80104bde <sys_exec+0xc8>
80104b36:	83 ec 08             	sub    $0x8,%esp
80104b39:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104b3f:	50                   	push   %eax
80104b40:	6a 01                	push   $0x1
80104b42:	e8 8c f4 ff ff       	call   80103fd3 <argint>
80104b47:	83 c4 10             	add    $0x10,%esp
80104b4a:	85 c0                	test   %eax,%eax
80104b4c:	0f 88 93 00 00 00    	js     80104be5 <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104b52:	83 ec 04             	sub    $0x4,%esp
80104b55:	68 80 00 00 00       	push   $0x80
80104b5a:	6a 00                	push   $0x0
80104b5c:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104b62:	50                   	push   %eax
80104b63:	e8 20 f2 ff ff       	call   80103d88 <memset>
80104b68:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104b6b:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104b70:	83 fb 1f             	cmp    $0x1f,%ebx
80104b73:	77 77                	ja     80104bec <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104b75:	83 ec 08             	sub    $0x8,%esp
80104b78:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104b7e:	50                   	push   %eax
80104b7f:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104b85:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104b88:	50                   	push   %eax
80104b89:	e8 c9 f3 ff ff       	call   80103f57 <fetchint>
80104b8e:	83 c4 10             	add    $0x10,%esp
80104b91:	85 c0                	test   %eax,%eax
80104b93:	78 5e                	js     80104bf3 <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104b95:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104b9b:	85 c0                	test   %eax,%eax
80104b9d:	74 1d                	je     80104bbc <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104b9f:	83 ec 08             	sub    $0x8,%esp
80104ba2:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104ba9:	52                   	push   %edx
80104baa:	50                   	push   %eax
80104bab:	e8 e3 f3 ff ff       	call   80103f93 <fetchstr>
80104bb0:	83 c4 10             	add    $0x10,%esp
80104bb3:	85 c0                	test   %eax,%eax
80104bb5:	78 46                	js     80104bfd <sys_exec+0xe7>
  for(i=0;; i++){
80104bb7:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104bba:	eb b4                	jmp    80104b70 <sys_exec+0x5a>
      argv[i] = 0;
80104bbc:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104bc3:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104bc7:	83 ec 08             	sub    $0x8,%esp
80104bca:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104bd0:	50                   	push   %eax
80104bd1:	ff 75 f4             	pushl  -0xc(%ebp)
80104bd4:	e8 f9 bc ff ff       	call   801008d2 <exec>
80104bd9:	83 c4 10             	add    $0x10,%esp
80104bdc:	eb 1a                	jmp    80104bf8 <sys_exec+0xe2>
    return -1;
80104bde:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104be3:	eb 13                	jmp    80104bf8 <sys_exec+0xe2>
80104be5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bea:	eb 0c                	jmp    80104bf8 <sys_exec+0xe2>
      return -1;
80104bec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bf1:	eb 05                	jmp    80104bf8 <sys_exec+0xe2>
      return -1;
80104bf3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104bf8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104bfb:	c9                   	leave  
80104bfc:	c3                   	ret    
      return -1;
80104bfd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c02:	eb f4                	jmp    80104bf8 <sys_exec+0xe2>

80104c04 <sys_pipe>:

int
sys_pipe(void)
{
80104c04:	55                   	push   %ebp
80104c05:	89 e5                	mov    %esp,%ebp
80104c07:	53                   	push   %ebx
80104c08:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104c0b:	6a 08                	push   $0x8
80104c0d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c10:	50                   	push   %eax
80104c11:	6a 00                	push   $0x0
80104c13:	e8 e3 f3 ff ff       	call   80103ffb <argptr>
80104c18:	83 c4 10             	add    $0x10,%esp
80104c1b:	85 c0                	test   %eax,%eax
80104c1d:	78 77                	js     80104c96 <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104c1f:	83 ec 08             	sub    $0x8,%esp
80104c22:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104c25:	50                   	push   %eax
80104c26:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104c29:	50                   	push   %eax
80104c2a:	e8 45 e2 ff ff       	call   80102e74 <pipealloc>
80104c2f:	83 c4 10             	add    $0x10,%esp
80104c32:	85 c0                	test   %eax,%eax
80104c34:	78 67                	js     80104c9d <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104c36:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c39:	e8 14 f5 ff ff       	call   80104152 <fdalloc>
80104c3e:	89 c3                	mov    %eax,%ebx
80104c40:	85 c0                	test   %eax,%eax
80104c42:	78 21                	js     80104c65 <sys_pipe+0x61>
80104c44:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104c47:	e8 06 f5 ff ff       	call   80104152 <fdalloc>
80104c4c:	85 c0                	test   %eax,%eax
80104c4e:	78 15                	js     80104c65 <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104c50:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c53:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104c55:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c58:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104c5b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104c60:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104c63:	c9                   	leave  
80104c64:	c3                   	ret    
    if(fd0 >= 0)
80104c65:	85 db                	test   %ebx,%ebx
80104c67:	78 0d                	js     80104c76 <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104c69:	e8 cf e6 ff ff       	call   8010333d <myproc>
80104c6e:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104c75:	00 
    fileclose(rf);
80104c76:	83 ec 0c             	sub    $0xc,%esp
80104c79:	ff 75 f0             	pushl  -0x10(%ebp)
80104c7c:	e8 52 c0 ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104c81:	83 c4 04             	add    $0x4,%esp
80104c84:	ff 75 ec             	pushl  -0x14(%ebp)
80104c87:	e8 47 c0 ff ff       	call   80100cd3 <fileclose>
    return -1;
80104c8c:	83 c4 10             	add    $0x10,%esp
80104c8f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c94:	eb ca                	jmp    80104c60 <sys_pipe+0x5c>
    return -1;
80104c96:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c9b:	eb c3                	jmp    80104c60 <sys_pipe+0x5c>
    return -1;
80104c9d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ca2:	eb bc                	jmp    80104c60 <sys_pipe+0x5c>

80104ca4 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104ca4:	55                   	push   %ebp
80104ca5:	89 e5                	mov    %esp,%ebp
80104ca7:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104caa:	e8 06 e8 ff ff       	call   801034b5 <fork>
}
80104caf:	c9                   	leave  
80104cb0:	c3                   	ret    

80104cb1 <sys_exit>:

int
sys_exit(void)
{
80104cb1:	55                   	push   %ebp
80104cb2:	89 e5                	mov    %esp,%ebp
80104cb4:	83 ec 08             	sub    $0x8,%esp
  exit();
80104cb7:	e8 2d ea ff ff       	call   801036e9 <exit>
  return 0;  // not reached
}
80104cbc:	b8 00 00 00 00       	mov    $0x0,%eax
80104cc1:	c9                   	leave  
80104cc2:	c3                   	ret    

80104cc3 <sys_wait>:

int
sys_wait(void)
{
80104cc3:	55                   	push   %ebp
80104cc4:	89 e5                	mov    %esp,%ebp
80104cc6:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104cc9:	e8 a4 eb ff ff       	call   80103872 <wait>
}
80104cce:	c9                   	leave  
80104ccf:	c3                   	ret    

80104cd0 <sys_kill>:

int
sys_kill(void)
{
80104cd0:	55                   	push   %ebp
80104cd1:	89 e5                	mov    %esp,%ebp
80104cd3:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104cd6:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104cd9:	50                   	push   %eax
80104cda:	6a 00                	push   $0x0
80104cdc:	e8 f2 f2 ff ff       	call   80103fd3 <argint>
80104ce1:	83 c4 10             	add    $0x10,%esp
80104ce4:	85 c0                	test   %eax,%eax
80104ce6:	78 10                	js     80104cf8 <sys_kill+0x28>
    return -1;
  return kill(pid);
80104ce8:	83 ec 0c             	sub    $0xc,%esp
80104ceb:	ff 75 f4             	pushl  -0xc(%ebp)
80104cee:	e8 7c ec ff ff       	call   8010396f <kill>
80104cf3:	83 c4 10             	add    $0x10,%esp
}
80104cf6:	c9                   	leave  
80104cf7:	c3                   	ret    
    return -1;
80104cf8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cfd:	eb f7                	jmp    80104cf6 <sys_kill+0x26>

80104cff <sys_getpid>:

int
sys_getpid(void)
{
80104cff:	55                   	push   %ebp
80104d00:	89 e5                	mov    %esp,%ebp
80104d02:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104d05:	e8 33 e6 ff ff       	call   8010333d <myproc>
80104d0a:	8b 40 10             	mov    0x10(%eax),%eax
}
80104d0d:	c9                   	leave  
80104d0e:	c3                   	ret    

80104d0f <sys_sbrk>:

int
sys_sbrk(void)
{
80104d0f:	55                   	push   %ebp
80104d10:	89 e5                	mov    %esp,%ebp
80104d12:	53                   	push   %ebx
80104d13:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104d16:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d19:	50                   	push   %eax
80104d1a:	6a 00                	push   $0x0
80104d1c:	e8 b2 f2 ff ff       	call   80103fd3 <argint>
80104d21:	83 c4 10             	add    $0x10,%esp
80104d24:	85 c0                	test   %eax,%eax
80104d26:	78 27                	js     80104d4f <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104d28:	e8 10 e6 ff ff       	call   8010333d <myproc>
80104d2d:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104d2f:	83 ec 0c             	sub    $0xc,%esp
80104d32:	ff 75 f4             	pushl  -0xc(%ebp)
80104d35:	e8 0e e7 ff ff       	call   80103448 <growproc>
80104d3a:	83 c4 10             	add    $0x10,%esp
80104d3d:	85 c0                	test   %eax,%eax
80104d3f:	78 07                	js     80104d48 <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104d41:	89 d8                	mov    %ebx,%eax
80104d43:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104d46:	c9                   	leave  
80104d47:	c3                   	ret    
    return -1;
80104d48:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104d4d:	eb f2                	jmp    80104d41 <sys_sbrk+0x32>
    return -1;
80104d4f:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104d54:	eb eb                	jmp    80104d41 <sys_sbrk+0x32>

80104d56 <sys_sleep>:

int
sys_sleep(void)
{
80104d56:	55                   	push   %ebp
80104d57:	89 e5                	mov    %esp,%ebp
80104d59:	53                   	push   %ebx
80104d5a:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104d5d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d60:	50                   	push   %eax
80104d61:	6a 00                	push   $0x0
80104d63:	e8 6b f2 ff ff       	call   80103fd3 <argint>
80104d68:	83 c4 10             	add    $0x10,%esp
80104d6b:	85 c0                	test   %eax,%eax
80104d6d:	78 75                	js     80104de4 <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104d6f:	83 ec 0c             	sub    $0xc,%esp
80104d72:	68 e0 3c 13 80       	push   $0x80133ce0
80104d77:	e8 60 ef ff ff       	call   80103cdc <acquire>
  ticks0 = ticks;
80104d7c:	8b 1d 20 45 13 80    	mov    0x80134520,%ebx
  while(ticks - ticks0 < n){
80104d82:	83 c4 10             	add    $0x10,%esp
80104d85:	a1 20 45 13 80       	mov    0x80134520,%eax
80104d8a:	29 d8                	sub    %ebx,%eax
80104d8c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104d8f:	73 39                	jae    80104dca <sys_sleep+0x74>
    if(myproc()->killed){
80104d91:	e8 a7 e5 ff ff       	call   8010333d <myproc>
80104d96:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104d9a:	75 17                	jne    80104db3 <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104d9c:	83 ec 08             	sub    $0x8,%esp
80104d9f:	68 e0 3c 13 80       	push   $0x80133ce0
80104da4:	68 20 45 13 80       	push   $0x80134520
80104da9:	e8 33 ea ff ff       	call   801037e1 <sleep>
80104dae:	83 c4 10             	add    $0x10,%esp
80104db1:	eb d2                	jmp    80104d85 <sys_sleep+0x2f>
      release(&tickslock);
80104db3:	83 ec 0c             	sub    $0xc,%esp
80104db6:	68 e0 3c 13 80       	push   $0x80133ce0
80104dbb:	e8 81 ef ff ff       	call   80103d41 <release>
      return -1;
80104dc0:	83 c4 10             	add    $0x10,%esp
80104dc3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dc8:	eb 15                	jmp    80104ddf <sys_sleep+0x89>
  }
  release(&tickslock);
80104dca:	83 ec 0c             	sub    $0xc,%esp
80104dcd:	68 e0 3c 13 80       	push   $0x80133ce0
80104dd2:	e8 6a ef ff ff       	call   80103d41 <release>
  return 0;
80104dd7:	83 c4 10             	add    $0x10,%esp
80104dda:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104ddf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104de2:	c9                   	leave  
80104de3:	c3                   	ret    
    return -1;
80104de4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104de9:	eb f4                	jmp    80104ddf <sys_sleep+0x89>

80104deb <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104deb:	55                   	push   %ebp
80104dec:	89 e5                	mov    %esp,%ebp
80104dee:	53                   	push   %ebx
80104def:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104df2:	68 e0 3c 13 80       	push   $0x80133ce0
80104df7:	e8 e0 ee ff ff       	call   80103cdc <acquire>
  xticks = ticks;
80104dfc:	8b 1d 20 45 13 80    	mov    0x80134520,%ebx
  release(&tickslock);
80104e02:	c7 04 24 e0 3c 13 80 	movl   $0x80133ce0,(%esp)
80104e09:	e8 33 ef ff ff       	call   80103d41 <release>
  return xticks;
}
80104e0e:	89 d8                	mov    %ebx,%eax
80104e10:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e13:	c9                   	leave  
80104e14:	c3                   	ret    

80104e15 <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80104e15:	55                   	push   %ebp
80104e16:	89 e5                	mov    %esp,%ebp
80104e18:	83 ec 1c             	sub    $0x1c,%esp
  int *frames;
  int *pids;
  int numframes;
  if(argptr(0, (char**)(&frames), sizeof(*frames)) < 0)
80104e1b:	6a 04                	push   $0x4
80104e1d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e20:	50                   	push   %eax
80104e21:	6a 00                	push   $0x0
80104e23:	e8 d3 f1 ff ff       	call   80103ffb <argptr>
80104e28:	83 c4 10             	add    $0x10,%esp
80104e2b:	85 c0                	test   %eax,%eax
80104e2d:	78 42                	js     80104e71 <sys_dump_physmem+0x5c>
    return -1;
  if(argptr(1, (char**)(&pids), sizeof(*pids)) < 0)
80104e2f:	83 ec 04             	sub    $0x4,%esp
80104e32:	6a 04                	push   $0x4
80104e34:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104e37:	50                   	push   %eax
80104e38:	6a 01                	push   $0x1
80104e3a:	e8 bc f1 ff ff       	call   80103ffb <argptr>
80104e3f:	83 c4 10             	add    $0x10,%esp
80104e42:	85 c0                	test   %eax,%eax
80104e44:	78 32                	js     80104e78 <sys_dump_physmem+0x63>
    return -1;
  if(argint(2, &numframes) < 0)
80104e46:	83 ec 08             	sub    $0x8,%esp
80104e49:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104e4c:	50                   	push   %eax
80104e4d:	6a 02                	push   $0x2
80104e4f:	e8 7f f1 ff ff       	call   80103fd3 <argint>
80104e54:	83 c4 10             	add    $0x10,%esp
80104e57:	85 c0                	test   %eax,%eax
80104e59:	78 24                	js     80104e7f <sys_dump_physmem+0x6a>
    return -1;

  return dump_physmem(frames, pids, numframes);
80104e5b:	83 ec 04             	sub    $0x4,%esp
80104e5e:	ff 75 ec             	pushl  -0x14(%ebp)
80104e61:	ff 75 f0             	pushl  -0x10(%ebp)
80104e64:	ff 75 f4             	pushl  -0xc(%ebp)
80104e67:	e8 8c d3 ff ff       	call   801021f8 <dump_physmem>
80104e6c:	83 c4 10             	add    $0x10,%esp
80104e6f:	c9                   	leave  
80104e70:	c3                   	ret    
    return -1;
80104e71:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e76:	eb f7                	jmp    80104e6f <sys_dump_physmem+0x5a>
    return -1;
80104e78:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e7d:	eb f0                	jmp    80104e6f <sys_dump_physmem+0x5a>
    return -1;
80104e7f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e84:	eb e9                	jmp    80104e6f <sys_dump_physmem+0x5a>

80104e86 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104e86:	1e                   	push   %ds
  pushl %es
80104e87:	06                   	push   %es
  pushl %fs
80104e88:	0f a0                	push   %fs
  pushl %gs
80104e8a:	0f a8                	push   %gs
  pushal
80104e8c:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104e8d:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104e91:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104e93:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104e95:	54                   	push   %esp
  call trap
80104e96:	e8 e3 00 00 00       	call   80104f7e <trap>
  addl $4, %esp
80104e9b:	83 c4 04             	add    $0x4,%esp

80104e9e <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104e9e:	61                   	popa   
  popl %gs
80104e9f:	0f a9                	pop    %gs
  popl %fs
80104ea1:	0f a1                	pop    %fs
  popl %es
80104ea3:	07                   	pop    %es
  popl %ds
80104ea4:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104ea5:	83 c4 08             	add    $0x8,%esp
  iret
80104ea8:	cf                   	iret   

80104ea9 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80104ea9:	55                   	push   %ebp
80104eaa:	89 e5                	mov    %esp,%ebp
80104eac:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
80104eaf:	b8 00 00 00 00       	mov    $0x0,%eax
80104eb4:	eb 4a                	jmp    80104f00 <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104eb6:	8b 0c 85 08 90 10 80 	mov    -0x7fef6ff8(,%eax,4),%ecx
80104ebd:	66 89 0c c5 20 3d 13 	mov    %cx,-0x7fecc2e0(,%eax,8)
80104ec4:	80 
80104ec5:	66 c7 04 c5 22 3d 13 	movw   $0x8,-0x7fecc2de(,%eax,8)
80104ecc:	80 08 00 
80104ecf:	c6 04 c5 24 3d 13 80 	movb   $0x0,-0x7fecc2dc(,%eax,8)
80104ed6:	00 
80104ed7:	0f b6 14 c5 25 3d 13 	movzbl -0x7fecc2db(,%eax,8),%edx
80104ede:	80 
80104edf:	83 e2 f0             	and    $0xfffffff0,%edx
80104ee2:	83 ca 0e             	or     $0xe,%edx
80104ee5:	83 e2 8f             	and    $0xffffff8f,%edx
80104ee8:	83 ca 80             	or     $0xffffff80,%edx
80104eeb:	88 14 c5 25 3d 13 80 	mov    %dl,-0x7fecc2db(,%eax,8)
80104ef2:	c1 e9 10             	shr    $0x10,%ecx
80104ef5:	66 89 0c c5 26 3d 13 	mov    %cx,-0x7fecc2da(,%eax,8)
80104efc:	80 
  for(i = 0; i < 256; i++)
80104efd:	83 c0 01             	add    $0x1,%eax
80104f00:	3d ff 00 00 00       	cmp    $0xff,%eax
80104f05:	7e af                	jle    80104eb6 <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80104f07:	8b 15 08 91 10 80    	mov    0x80109108,%edx
80104f0d:	66 89 15 20 3f 13 80 	mov    %dx,0x80133f20
80104f14:	66 c7 05 22 3f 13 80 	movw   $0x8,0x80133f22
80104f1b:	08 00 
80104f1d:	c6 05 24 3f 13 80 00 	movb   $0x0,0x80133f24
80104f24:	0f b6 05 25 3f 13 80 	movzbl 0x80133f25,%eax
80104f2b:	83 c8 0f             	or     $0xf,%eax
80104f2e:	83 e0 ef             	and    $0xffffffef,%eax
80104f31:	83 c8 e0             	or     $0xffffffe0,%eax
80104f34:	a2 25 3f 13 80       	mov    %al,0x80133f25
80104f39:	c1 ea 10             	shr    $0x10,%edx
80104f3c:	66 89 15 26 3f 13 80 	mov    %dx,0x80133f26

  initlock(&tickslock, "time");
80104f43:	83 ec 08             	sub    $0x8,%esp
80104f46:	68 9d 6d 10 80       	push   $0x80106d9d
80104f4b:	68 e0 3c 13 80       	push   $0x80133ce0
80104f50:	e8 4b ec ff ff       	call   80103ba0 <initlock>
}
80104f55:	83 c4 10             	add    $0x10,%esp
80104f58:	c9                   	leave  
80104f59:	c3                   	ret    

80104f5a <idtinit>:

void
idtinit(void)
{
80104f5a:	55                   	push   %ebp
80104f5b:	89 e5                	mov    %esp,%ebp
80104f5d:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80104f60:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80104f66:	b8 20 3d 13 80       	mov    $0x80133d20,%eax
80104f6b:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80104f6f:	c1 e8 10             	shr    $0x10,%eax
80104f72:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
80104f76:	8d 45 fa             	lea    -0x6(%ebp),%eax
80104f79:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80104f7c:	c9                   	leave  
80104f7d:	c3                   	ret    

80104f7e <trap>:

void
trap(struct trapframe *tf)
{
80104f7e:	55                   	push   %ebp
80104f7f:	89 e5                	mov    %esp,%ebp
80104f81:	57                   	push   %edi
80104f82:	56                   	push   %esi
80104f83:	53                   	push   %ebx
80104f84:	83 ec 1c             	sub    $0x1c,%esp
80104f87:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80104f8a:	8b 43 30             	mov    0x30(%ebx),%eax
80104f8d:	83 f8 40             	cmp    $0x40,%eax
80104f90:	74 13                	je     80104fa5 <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
80104f92:	83 e8 20             	sub    $0x20,%eax
80104f95:	83 f8 1f             	cmp    $0x1f,%eax
80104f98:	0f 87 3a 01 00 00    	ja     801050d8 <trap+0x15a>
80104f9e:	ff 24 85 44 6e 10 80 	jmp    *-0x7fef91bc(,%eax,4)
    if(myproc()->killed)
80104fa5:	e8 93 e3 ff ff       	call   8010333d <myproc>
80104faa:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104fae:	75 1f                	jne    80104fcf <trap+0x51>
    myproc()->tf = tf;
80104fb0:	e8 88 e3 ff ff       	call   8010333d <myproc>
80104fb5:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80104fb8:	e8 d9 f0 ff ff       	call   80104096 <syscall>
    if(myproc()->killed)
80104fbd:	e8 7b e3 ff ff       	call   8010333d <myproc>
80104fc2:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104fc6:	74 7e                	je     80105046 <trap+0xc8>
      exit();
80104fc8:	e8 1c e7 ff ff       	call   801036e9 <exit>
80104fcd:	eb 77                	jmp    80105046 <trap+0xc8>
      exit();
80104fcf:	e8 15 e7 ff ff       	call   801036e9 <exit>
80104fd4:	eb da                	jmp    80104fb0 <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80104fd6:	e8 47 e3 ff ff       	call   80103322 <cpuid>
80104fdb:	85 c0                	test   %eax,%eax
80104fdd:	74 6f                	je     8010504e <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
80104fdf:	e8 f4 d4 ff ff       	call   801024d8 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80104fe4:	e8 54 e3 ff ff       	call   8010333d <myproc>
80104fe9:	85 c0                	test   %eax,%eax
80104feb:	74 1c                	je     80105009 <trap+0x8b>
80104fed:	e8 4b e3 ff ff       	call   8010333d <myproc>
80104ff2:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104ff6:	74 11                	je     80105009 <trap+0x8b>
80104ff8:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80104ffc:	83 e0 03             	and    $0x3,%eax
80104fff:	66 83 f8 03          	cmp    $0x3,%ax
80105003:	0f 84 62 01 00 00    	je     8010516b <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80105009:	e8 2f e3 ff ff       	call   8010333d <myproc>
8010500e:	85 c0                	test   %eax,%eax
80105010:	74 0f                	je     80105021 <trap+0xa3>
80105012:	e8 26 e3 ff ff       	call   8010333d <myproc>
80105017:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
8010501b:	0f 84 54 01 00 00    	je     80105175 <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105021:	e8 17 e3 ff ff       	call   8010333d <myproc>
80105026:	85 c0                	test   %eax,%eax
80105028:	74 1c                	je     80105046 <trap+0xc8>
8010502a:	e8 0e e3 ff ff       	call   8010333d <myproc>
8010502f:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105033:	74 11                	je     80105046 <trap+0xc8>
80105035:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105039:	83 e0 03             	and    $0x3,%eax
8010503c:	66 83 f8 03          	cmp    $0x3,%ax
80105040:	0f 84 43 01 00 00    	je     80105189 <trap+0x20b>
    exit();
}
80105046:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105049:	5b                   	pop    %ebx
8010504a:	5e                   	pop    %esi
8010504b:	5f                   	pop    %edi
8010504c:	5d                   	pop    %ebp
8010504d:	c3                   	ret    
      acquire(&tickslock);
8010504e:	83 ec 0c             	sub    $0xc,%esp
80105051:	68 e0 3c 13 80       	push   $0x80133ce0
80105056:	e8 81 ec ff ff       	call   80103cdc <acquire>
      ticks++;
8010505b:	83 05 20 45 13 80 01 	addl   $0x1,0x80134520
      wakeup(&ticks);
80105062:	c7 04 24 20 45 13 80 	movl   $0x80134520,(%esp)
80105069:	e8 d8 e8 ff ff       	call   80103946 <wakeup>
      release(&tickslock);
8010506e:	c7 04 24 e0 3c 13 80 	movl   $0x80133ce0,(%esp)
80105075:	e8 c7 ec ff ff       	call   80103d41 <release>
8010507a:	83 c4 10             	add    $0x10,%esp
8010507d:	e9 5d ff ff ff       	jmp    80104fdf <trap+0x61>
    ideintr();
80105082:	e8 ec cc ff ff       	call   80101d73 <ideintr>
    lapiceoi();
80105087:	e8 4c d4 ff ff       	call   801024d8 <lapiceoi>
    break;
8010508c:	e9 53 ff ff ff       	jmp    80104fe4 <trap+0x66>
    kbdintr();
80105091:	e8 86 d2 ff ff       	call   8010231c <kbdintr>
    lapiceoi();
80105096:	e8 3d d4 ff ff       	call   801024d8 <lapiceoi>
    break;
8010509b:	e9 44 ff ff ff       	jmp    80104fe4 <trap+0x66>
    uartintr();
801050a0:	e8 05 02 00 00       	call   801052aa <uartintr>
    lapiceoi();
801050a5:	e8 2e d4 ff ff       	call   801024d8 <lapiceoi>
    break;
801050aa:	e9 35 ff ff ff       	jmp    80104fe4 <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801050af:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
801050b2:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801050b6:	e8 67 e2 ff ff       	call   80103322 <cpuid>
801050bb:	57                   	push   %edi
801050bc:	0f b7 f6             	movzwl %si,%esi
801050bf:	56                   	push   %esi
801050c0:	50                   	push   %eax
801050c1:	68 a8 6d 10 80       	push   $0x80106da8
801050c6:	e8 40 b5 ff ff       	call   8010060b <cprintf>
    lapiceoi();
801050cb:	e8 08 d4 ff ff       	call   801024d8 <lapiceoi>
    break;
801050d0:	83 c4 10             	add    $0x10,%esp
801050d3:	e9 0c ff ff ff       	jmp    80104fe4 <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
801050d8:	e8 60 e2 ff ff       	call   8010333d <myproc>
801050dd:	85 c0                	test   %eax,%eax
801050df:	74 5f                	je     80105140 <trap+0x1c2>
801050e1:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
801050e5:	74 59                	je     80105140 <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801050e7:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801050ea:	8b 43 38             	mov    0x38(%ebx),%eax
801050ed:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801050f0:	e8 2d e2 ff ff       	call   80103322 <cpuid>
801050f5:	89 45 e0             	mov    %eax,-0x20(%ebp)
801050f8:	8b 53 34             	mov    0x34(%ebx),%edx
801050fb:	89 55 dc             	mov    %edx,-0x24(%ebp)
801050fe:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
80105101:	e8 37 e2 ff ff       	call   8010333d <myproc>
80105106:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105109:	89 4d d8             	mov    %ecx,-0x28(%ebp)
8010510c:	e8 2c e2 ff ff       	call   8010333d <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105111:	57                   	push   %edi
80105112:	ff 75 e4             	pushl  -0x1c(%ebp)
80105115:	ff 75 e0             	pushl  -0x20(%ebp)
80105118:	ff 75 dc             	pushl  -0x24(%ebp)
8010511b:	56                   	push   %esi
8010511c:	ff 75 d8             	pushl  -0x28(%ebp)
8010511f:	ff 70 10             	pushl  0x10(%eax)
80105122:	68 00 6e 10 80       	push   $0x80106e00
80105127:	e8 df b4 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
8010512c:	83 c4 20             	add    $0x20,%esp
8010512f:	e8 09 e2 ff ff       	call   8010333d <myproc>
80105134:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010513b:	e9 a4 fe ff ff       	jmp    80104fe4 <trap+0x66>
80105140:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80105143:	8b 73 38             	mov    0x38(%ebx),%esi
80105146:	e8 d7 e1 ff ff       	call   80103322 <cpuid>
8010514b:	83 ec 0c             	sub    $0xc,%esp
8010514e:	57                   	push   %edi
8010514f:	56                   	push   %esi
80105150:	50                   	push   %eax
80105151:	ff 73 30             	pushl  0x30(%ebx)
80105154:	68 cc 6d 10 80       	push   $0x80106dcc
80105159:	e8 ad b4 ff ff       	call   8010060b <cprintf>
      panic("trap");
8010515e:	83 c4 14             	add    $0x14,%esp
80105161:	68 a2 6d 10 80       	push   $0x80106da2
80105166:	e8 dd b1 ff ff       	call   80100348 <panic>
    exit();
8010516b:	e8 79 e5 ff ff       	call   801036e9 <exit>
80105170:	e9 94 fe ff ff       	jmp    80105009 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
80105175:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
80105179:	0f 85 a2 fe ff ff    	jne    80105021 <trap+0xa3>
    yield();
8010517f:	e8 2b e6 ff ff       	call   801037af <yield>
80105184:	e9 98 fe ff ff       	jmp    80105021 <trap+0xa3>
    exit();
80105189:	e8 5b e5 ff ff       	call   801036e9 <exit>
8010518e:	e9 b3 fe ff ff       	jmp    80105046 <trap+0xc8>

80105193 <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
80105193:	55                   	push   %ebp
80105194:	89 e5                	mov    %esp,%ebp
  if(!uart)
80105196:	83 3d c0 95 10 80 00 	cmpl   $0x0,0x801095c0
8010519d:	74 15                	je     801051b4 <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010519f:	ba fd 03 00 00       	mov    $0x3fd,%edx
801051a4:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
801051a5:	a8 01                	test   $0x1,%al
801051a7:	74 12                	je     801051bb <uartgetc+0x28>
801051a9:	ba f8 03 00 00       	mov    $0x3f8,%edx
801051ae:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
801051af:	0f b6 c0             	movzbl %al,%eax
}
801051b2:	5d                   	pop    %ebp
801051b3:	c3                   	ret    
    return -1;
801051b4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051b9:	eb f7                	jmp    801051b2 <uartgetc+0x1f>
    return -1;
801051bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051c0:	eb f0                	jmp    801051b2 <uartgetc+0x1f>

801051c2 <uartputc>:
  if(!uart)
801051c2:	83 3d c0 95 10 80 00 	cmpl   $0x0,0x801095c0
801051c9:	74 3b                	je     80105206 <uartputc+0x44>
{
801051cb:	55                   	push   %ebp
801051cc:	89 e5                	mov    %esp,%ebp
801051ce:	53                   	push   %ebx
801051cf:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801051d2:	bb 00 00 00 00       	mov    $0x0,%ebx
801051d7:	eb 10                	jmp    801051e9 <uartputc+0x27>
    microdelay(10);
801051d9:	83 ec 0c             	sub    $0xc,%esp
801051dc:	6a 0a                	push   $0xa
801051de:	e8 14 d3 ff ff       	call   801024f7 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801051e3:	83 c3 01             	add    $0x1,%ebx
801051e6:	83 c4 10             	add    $0x10,%esp
801051e9:	83 fb 7f             	cmp    $0x7f,%ebx
801051ec:	7f 0a                	jg     801051f8 <uartputc+0x36>
801051ee:	ba fd 03 00 00       	mov    $0x3fd,%edx
801051f3:	ec                   	in     (%dx),%al
801051f4:	a8 20                	test   $0x20,%al
801051f6:	74 e1                	je     801051d9 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801051f8:	8b 45 08             	mov    0x8(%ebp),%eax
801051fb:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105200:	ee                   	out    %al,(%dx)
}
80105201:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105204:	c9                   	leave  
80105205:	c3                   	ret    
80105206:	f3 c3                	repz ret 

80105208 <uartinit>:
{
80105208:	55                   	push   %ebp
80105209:	89 e5                	mov    %esp,%ebp
8010520b:	56                   	push   %esi
8010520c:	53                   	push   %ebx
8010520d:	b9 00 00 00 00       	mov    $0x0,%ecx
80105212:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105217:	89 c8                	mov    %ecx,%eax
80105219:	ee                   	out    %al,(%dx)
8010521a:	be fb 03 00 00       	mov    $0x3fb,%esi
8010521f:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
80105224:	89 f2                	mov    %esi,%edx
80105226:	ee                   	out    %al,(%dx)
80105227:	b8 0c 00 00 00       	mov    $0xc,%eax
8010522c:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105231:	ee                   	out    %al,(%dx)
80105232:	bb f9 03 00 00       	mov    $0x3f9,%ebx
80105237:	89 c8                	mov    %ecx,%eax
80105239:	89 da                	mov    %ebx,%edx
8010523b:	ee                   	out    %al,(%dx)
8010523c:	b8 03 00 00 00       	mov    $0x3,%eax
80105241:	89 f2                	mov    %esi,%edx
80105243:	ee                   	out    %al,(%dx)
80105244:	ba fc 03 00 00       	mov    $0x3fc,%edx
80105249:	89 c8                	mov    %ecx,%eax
8010524b:	ee                   	out    %al,(%dx)
8010524c:	b8 01 00 00 00       	mov    $0x1,%eax
80105251:	89 da                	mov    %ebx,%edx
80105253:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105254:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105259:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
8010525a:	3c ff                	cmp    $0xff,%al
8010525c:	74 45                	je     801052a3 <uartinit+0x9b>
  uart = 1;
8010525e:	c7 05 c0 95 10 80 01 	movl   $0x1,0x801095c0
80105265:	00 00 00 
80105268:	ba fa 03 00 00       	mov    $0x3fa,%edx
8010526d:	ec                   	in     (%dx),%al
8010526e:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105273:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
80105274:	83 ec 08             	sub    $0x8,%esp
80105277:	6a 00                	push   $0x0
80105279:	6a 04                	push   $0x4
8010527b:	e8 fe cc ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
80105280:	83 c4 10             	add    $0x10,%esp
80105283:	bb c4 6e 10 80       	mov    $0x80106ec4,%ebx
80105288:	eb 12                	jmp    8010529c <uartinit+0x94>
    uartputc(*p);
8010528a:	83 ec 0c             	sub    $0xc,%esp
8010528d:	0f be c0             	movsbl %al,%eax
80105290:	50                   	push   %eax
80105291:	e8 2c ff ff ff       	call   801051c2 <uartputc>
  for(p="xv6...\n"; *p; p++)
80105296:	83 c3 01             	add    $0x1,%ebx
80105299:	83 c4 10             	add    $0x10,%esp
8010529c:	0f b6 03             	movzbl (%ebx),%eax
8010529f:	84 c0                	test   %al,%al
801052a1:	75 e7                	jne    8010528a <uartinit+0x82>
}
801052a3:	8d 65 f8             	lea    -0x8(%ebp),%esp
801052a6:	5b                   	pop    %ebx
801052a7:	5e                   	pop    %esi
801052a8:	5d                   	pop    %ebp
801052a9:	c3                   	ret    

801052aa <uartintr>:

void
uartintr(void)
{
801052aa:	55                   	push   %ebp
801052ab:	89 e5                	mov    %esp,%ebp
801052ad:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
801052b0:	68 93 51 10 80       	push   $0x80105193
801052b5:	e8 84 b4 ff ff       	call   8010073e <consoleintr>
}
801052ba:	83 c4 10             	add    $0x10,%esp
801052bd:	c9                   	leave  
801052be:	c3                   	ret    

801052bf <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801052bf:	6a 00                	push   $0x0
  pushl $0
801052c1:	6a 00                	push   $0x0
  jmp alltraps
801052c3:	e9 be fb ff ff       	jmp    80104e86 <alltraps>

801052c8 <vector1>:
.globl vector1
vector1:
  pushl $0
801052c8:	6a 00                	push   $0x0
  pushl $1
801052ca:	6a 01                	push   $0x1
  jmp alltraps
801052cc:	e9 b5 fb ff ff       	jmp    80104e86 <alltraps>

801052d1 <vector2>:
.globl vector2
vector2:
  pushl $0
801052d1:	6a 00                	push   $0x0
  pushl $2
801052d3:	6a 02                	push   $0x2
  jmp alltraps
801052d5:	e9 ac fb ff ff       	jmp    80104e86 <alltraps>

801052da <vector3>:
.globl vector3
vector3:
  pushl $0
801052da:	6a 00                	push   $0x0
  pushl $3
801052dc:	6a 03                	push   $0x3
  jmp alltraps
801052de:	e9 a3 fb ff ff       	jmp    80104e86 <alltraps>

801052e3 <vector4>:
.globl vector4
vector4:
  pushl $0
801052e3:	6a 00                	push   $0x0
  pushl $4
801052e5:	6a 04                	push   $0x4
  jmp alltraps
801052e7:	e9 9a fb ff ff       	jmp    80104e86 <alltraps>

801052ec <vector5>:
.globl vector5
vector5:
  pushl $0
801052ec:	6a 00                	push   $0x0
  pushl $5
801052ee:	6a 05                	push   $0x5
  jmp alltraps
801052f0:	e9 91 fb ff ff       	jmp    80104e86 <alltraps>

801052f5 <vector6>:
.globl vector6
vector6:
  pushl $0
801052f5:	6a 00                	push   $0x0
  pushl $6
801052f7:	6a 06                	push   $0x6
  jmp alltraps
801052f9:	e9 88 fb ff ff       	jmp    80104e86 <alltraps>

801052fe <vector7>:
.globl vector7
vector7:
  pushl $0
801052fe:	6a 00                	push   $0x0
  pushl $7
80105300:	6a 07                	push   $0x7
  jmp alltraps
80105302:	e9 7f fb ff ff       	jmp    80104e86 <alltraps>

80105307 <vector8>:
.globl vector8
vector8:
  pushl $8
80105307:	6a 08                	push   $0x8
  jmp alltraps
80105309:	e9 78 fb ff ff       	jmp    80104e86 <alltraps>

8010530e <vector9>:
.globl vector9
vector9:
  pushl $0
8010530e:	6a 00                	push   $0x0
  pushl $9
80105310:	6a 09                	push   $0x9
  jmp alltraps
80105312:	e9 6f fb ff ff       	jmp    80104e86 <alltraps>

80105317 <vector10>:
.globl vector10
vector10:
  pushl $10
80105317:	6a 0a                	push   $0xa
  jmp alltraps
80105319:	e9 68 fb ff ff       	jmp    80104e86 <alltraps>

8010531e <vector11>:
.globl vector11
vector11:
  pushl $11
8010531e:	6a 0b                	push   $0xb
  jmp alltraps
80105320:	e9 61 fb ff ff       	jmp    80104e86 <alltraps>

80105325 <vector12>:
.globl vector12
vector12:
  pushl $12
80105325:	6a 0c                	push   $0xc
  jmp alltraps
80105327:	e9 5a fb ff ff       	jmp    80104e86 <alltraps>

8010532c <vector13>:
.globl vector13
vector13:
  pushl $13
8010532c:	6a 0d                	push   $0xd
  jmp alltraps
8010532e:	e9 53 fb ff ff       	jmp    80104e86 <alltraps>

80105333 <vector14>:
.globl vector14
vector14:
  pushl $14
80105333:	6a 0e                	push   $0xe
  jmp alltraps
80105335:	e9 4c fb ff ff       	jmp    80104e86 <alltraps>

8010533a <vector15>:
.globl vector15
vector15:
  pushl $0
8010533a:	6a 00                	push   $0x0
  pushl $15
8010533c:	6a 0f                	push   $0xf
  jmp alltraps
8010533e:	e9 43 fb ff ff       	jmp    80104e86 <alltraps>

80105343 <vector16>:
.globl vector16
vector16:
  pushl $0
80105343:	6a 00                	push   $0x0
  pushl $16
80105345:	6a 10                	push   $0x10
  jmp alltraps
80105347:	e9 3a fb ff ff       	jmp    80104e86 <alltraps>

8010534c <vector17>:
.globl vector17
vector17:
  pushl $17
8010534c:	6a 11                	push   $0x11
  jmp alltraps
8010534e:	e9 33 fb ff ff       	jmp    80104e86 <alltraps>

80105353 <vector18>:
.globl vector18
vector18:
  pushl $0
80105353:	6a 00                	push   $0x0
  pushl $18
80105355:	6a 12                	push   $0x12
  jmp alltraps
80105357:	e9 2a fb ff ff       	jmp    80104e86 <alltraps>

8010535c <vector19>:
.globl vector19
vector19:
  pushl $0
8010535c:	6a 00                	push   $0x0
  pushl $19
8010535e:	6a 13                	push   $0x13
  jmp alltraps
80105360:	e9 21 fb ff ff       	jmp    80104e86 <alltraps>

80105365 <vector20>:
.globl vector20
vector20:
  pushl $0
80105365:	6a 00                	push   $0x0
  pushl $20
80105367:	6a 14                	push   $0x14
  jmp alltraps
80105369:	e9 18 fb ff ff       	jmp    80104e86 <alltraps>

8010536e <vector21>:
.globl vector21
vector21:
  pushl $0
8010536e:	6a 00                	push   $0x0
  pushl $21
80105370:	6a 15                	push   $0x15
  jmp alltraps
80105372:	e9 0f fb ff ff       	jmp    80104e86 <alltraps>

80105377 <vector22>:
.globl vector22
vector22:
  pushl $0
80105377:	6a 00                	push   $0x0
  pushl $22
80105379:	6a 16                	push   $0x16
  jmp alltraps
8010537b:	e9 06 fb ff ff       	jmp    80104e86 <alltraps>

80105380 <vector23>:
.globl vector23
vector23:
  pushl $0
80105380:	6a 00                	push   $0x0
  pushl $23
80105382:	6a 17                	push   $0x17
  jmp alltraps
80105384:	e9 fd fa ff ff       	jmp    80104e86 <alltraps>

80105389 <vector24>:
.globl vector24
vector24:
  pushl $0
80105389:	6a 00                	push   $0x0
  pushl $24
8010538b:	6a 18                	push   $0x18
  jmp alltraps
8010538d:	e9 f4 fa ff ff       	jmp    80104e86 <alltraps>

80105392 <vector25>:
.globl vector25
vector25:
  pushl $0
80105392:	6a 00                	push   $0x0
  pushl $25
80105394:	6a 19                	push   $0x19
  jmp alltraps
80105396:	e9 eb fa ff ff       	jmp    80104e86 <alltraps>

8010539b <vector26>:
.globl vector26
vector26:
  pushl $0
8010539b:	6a 00                	push   $0x0
  pushl $26
8010539d:	6a 1a                	push   $0x1a
  jmp alltraps
8010539f:	e9 e2 fa ff ff       	jmp    80104e86 <alltraps>

801053a4 <vector27>:
.globl vector27
vector27:
  pushl $0
801053a4:	6a 00                	push   $0x0
  pushl $27
801053a6:	6a 1b                	push   $0x1b
  jmp alltraps
801053a8:	e9 d9 fa ff ff       	jmp    80104e86 <alltraps>

801053ad <vector28>:
.globl vector28
vector28:
  pushl $0
801053ad:	6a 00                	push   $0x0
  pushl $28
801053af:	6a 1c                	push   $0x1c
  jmp alltraps
801053b1:	e9 d0 fa ff ff       	jmp    80104e86 <alltraps>

801053b6 <vector29>:
.globl vector29
vector29:
  pushl $0
801053b6:	6a 00                	push   $0x0
  pushl $29
801053b8:	6a 1d                	push   $0x1d
  jmp alltraps
801053ba:	e9 c7 fa ff ff       	jmp    80104e86 <alltraps>

801053bf <vector30>:
.globl vector30
vector30:
  pushl $0
801053bf:	6a 00                	push   $0x0
  pushl $30
801053c1:	6a 1e                	push   $0x1e
  jmp alltraps
801053c3:	e9 be fa ff ff       	jmp    80104e86 <alltraps>

801053c8 <vector31>:
.globl vector31
vector31:
  pushl $0
801053c8:	6a 00                	push   $0x0
  pushl $31
801053ca:	6a 1f                	push   $0x1f
  jmp alltraps
801053cc:	e9 b5 fa ff ff       	jmp    80104e86 <alltraps>

801053d1 <vector32>:
.globl vector32
vector32:
  pushl $0
801053d1:	6a 00                	push   $0x0
  pushl $32
801053d3:	6a 20                	push   $0x20
  jmp alltraps
801053d5:	e9 ac fa ff ff       	jmp    80104e86 <alltraps>

801053da <vector33>:
.globl vector33
vector33:
  pushl $0
801053da:	6a 00                	push   $0x0
  pushl $33
801053dc:	6a 21                	push   $0x21
  jmp alltraps
801053de:	e9 a3 fa ff ff       	jmp    80104e86 <alltraps>

801053e3 <vector34>:
.globl vector34
vector34:
  pushl $0
801053e3:	6a 00                	push   $0x0
  pushl $34
801053e5:	6a 22                	push   $0x22
  jmp alltraps
801053e7:	e9 9a fa ff ff       	jmp    80104e86 <alltraps>

801053ec <vector35>:
.globl vector35
vector35:
  pushl $0
801053ec:	6a 00                	push   $0x0
  pushl $35
801053ee:	6a 23                	push   $0x23
  jmp alltraps
801053f0:	e9 91 fa ff ff       	jmp    80104e86 <alltraps>

801053f5 <vector36>:
.globl vector36
vector36:
  pushl $0
801053f5:	6a 00                	push   $0x0
  pushl $36
801053f7:	6a 24                	push   $0x24
  jmp alltraps
801053f9:	e9 88 fa ff ff       	jmp    80104e86 <alltraps>

801053fe <vector37>:
.globl vector37
vector37:
  pushl $0
801053fe:	6a 00                	push   $0x0
  pushl $37
80105400:	6a 25                	push   $0x25
  jmp alltraps
80105402:	e9 7f fa ff ff       	jmp    80104e86 <alltraps>

80105407 <vector38>:
.globl vector38
vector38:
  pushl $0
80105407:	6a 00                	push   $0x0
  pushl $38
80105409:	6a 26                	push   $0x26
  jmp alltraps
8010540b:	e9 76 fa ff ff       	jmp    80104e86 <alltraps>

80105410 <vector39>:
.globl vector39
vector39:
  pushl $0
80105410:	6a 00                	push   $0x0
  pushl $39
80105412:	6a 27                	push   $0x27
  jmp alltraps
80105414:	e9 6d fa ff ff       	jmp    80104e86 <alltraps>

80105419 <vector40>:
.globl vector40
vector40:
  pushl $0
80105419:	6a 00                	push   $0x0
  pushl $40
8010541b:	6a 28                	push   $0x28
  jmp alltraps
8010541d:	e9 64 fa ff ff       	jmp    80104e86 <alltraps>

80105422 <vector41>:
.globl vector41
vector41:
  pushl $0
80105422:	6a 00                	push   $0x0
  pushl $41
80105424:	6a 29                	push   $0x29
  jmp alltraps
80105426:	e9 5b fa ff ff       	jmp    80104e86 <alltraps>

8010542b <vector42>:
.globl vector42
vector42:
  pushl $0
8010542b:	6a 00                	push   $0x0
  pushl $42
8010542d:	6a 2a                	push   $0x2a
  jmp alltraps
8010542f:	e9 52 fa ff ff       	jmp    80104e86 <alltraps>

80105434 <vector43>:
.globl vector43
vector43:
  pushl $0
80105434:	6a 00                	push   $0x0
  pushl $43
80105436:	6a 2b                	push   $0x2b
  jmp alltraps
80105438:	e9 49 fa ff ff       	jmp    80104e86 <alltraps>

8010543d <vector44>:
.globl vector44
vector44:
  pushl $0
8010543d:	6a 00                	push   $0x0
  pushl $44
8010543f:	6a 2c                	push   $0x2c
  jmp alltraps
80105441:	e9 40 fa ff ff       	jmp    80104e86 <alltraps>

80105446 <vector45>:
.globl vector45
vector45:
  pushl $0
80105446:	6a 00                	push   $0x0
  pushl $45
80105448:	6a 2d                	push   $0x2d
  jmp alltraps
8010544a:	e9 37 fa ff ff       	jmp    80104e86 <alltraps>

8010544f <vector46>:
.globl vector46
vector46:
  pushl $0
8010544f:	6a 00                	push   $0x0
  pushl $46
80105451:	6a 2e                	push   $0x2e
  jmp alltraps
80105453:	e9 2e fa ff ff       	jmp    80104e86 <alltraps>

80105458 <vector47>:
.globl vector47
vector47:
  pushl $0
80105458:	6a 00                	push   $0x0
  pushl $47
8010545a:	6a 2f                	push   $0x2f
  jmp alltraps
8010545c:	e9 25 fa ff ff       	jmp    80104e86 <alltraps>

80105461 <vector48>:
.globl vector48
vector48:
  pushl $0
80105461:	6a 00                	push   $0x0
  pushl $48
80105463:	6a 30                	push   $0x30
  jmp alltraps
80105465:	e9 1c fa ff ff       	jmp    80104e86 <alltraps>

8010546a <vector49>:
.globl vector49
vector49:
  pushl $0
8010546a:	6a 00                	push   $0x0
  pushl $49
8010546c:	6a 31                	push   $0x31
  jmp alltraps
8010546e:	e9 13 fa ff ff       	jmp    80104e86 <alltraps>

80105473 <vector50>:
.globl vector50
vector50:
  pushl $0
80105473:	6a 00                	push   $0x0
  pushl $50
80105475:	6a 32                	push   $0x32
  jmp alltraps
80105477:	e9 0a fa ff ff       	jmp    80104e86 <alltraps>

8010547c <vector51>:
.globl vector51
vector51:
  pushl $0
8010547c:	6a 00                	push   $0x0
  pushl $51
8010547e:	6a 33                	push   $0x33
  jmp alltraps
80105480:	e9 01 fa ff ff       	jmp    80104e86 <alltraps>

80105485 <vector52>:
.globl vector52
vector52:
  pushl $0
80105485:	6a 00                	push   $0x0
  pushl $52
80105487:	6a 34                	push   $0x34
  jmp alltraps
80105489:	e9 f8 f9 ff ff       	jmp    80104e86 <alltraps>

8010548e <vector53>:
.globl vector53
vector53:
  pushl $0
8010548e:	6a 00                	push   $0x0
  pushl $53
80105490:	6a 35                	push   $0x35
  jmp alltraps
80105492:	e9 ef f9 ff ff       	jmp    80104e86 <alltraps>

80105497 <vector54>:
.globl vector54
vector54:
  pushl $0
80105497:	6a 00                	push   $0x0
  pushl $54
80105499:	6a 36                	push   $0x36
  jmp alltraps
8010549b:	e9 e6 f9 ff ff       	jmp    80104e86 <alltraps>

801054a0 <vector55>:
.globl vector55
vector55:
  pushl $0
801054a0:	6a 00                	push   $0x0
  pushl $55
801054a2:	6a 37                	push   $0x37
  jmp alltraps
801054a4:	e9 dd f9 ff ff       	jmp    80104e86 <alltraps>

801054a9 <vector56>:
.globl vector56
vector56:
  pushl $0
801054a9:	6a 00                	push   $0x0
  pushl $56
801054ab:	6a 38                	push   $0x38
  jmp alltraps
801054ad:	e9 d4 f9 ff ff       	jmp    80104e86 <alltraps>

801054b2 <vector57>:
.globl vector57
vector57:
  pushl $0
801054b2:	6a 00                	push   $0x0
  pushl $57
801054b4:	6a 39                	push   $0x39
  jmp alltraps
801054b6:	e9 cb f9 ff ff       	jmp    80104e86 <alltraps>

801054bb <vector58>:
.globl vector58
vector58:
  pushl $0
801054bb:	6a 00                	push   $0x0
  pushl $58
801054bd:	6a 3a                	push   $0x3a
  jmp alltraps
801054bf:	e9 c2 f9 ff ff       	jmp    80104e86 <alltraps>

801054c4 <vector59>:
.globl vector59
vector59:
  pushl $0
801054c4:	6a 00                	push   $0x0
  pushl $59
801054c6:	6a 3b                	push   $0x3b
  jmp alltraps
801054c8:	e9 b9 f9 ff ff       	jmp    80104e86 <alltraps>

801054cd <vector60>:
.globl vector60
vector60:
  pushl $0
801054cd:	6a 00                	push   $0x0
  pushl $60
801054cf:	6a 3c                	push   $0x3c
  jmp alltraps
801054d1:	e9 b0 f9 ff ff       	jmp    80104e86 <alltraps>

801054d6 <vector61>:
.globl vector61
vector61:
  pushl $0
801054d6:	6a 00                	push   $0x0
  pushl $61
801054d8:	6a 3d                	push   $0x3d
  jmp alltraps
801054da:	e9 a7 f9 ff ff       	jmp    80104e86 <alltraps>

801054df <vector62>:
.globl vector62
vector62:
  pushl $0
801054df:	6a 00                	push   $0x0
  pushl $62
801054e1:	6a 3e                	push   $0x3e
  jmp alltraps
801054e3:	e9 9e f9 ff ff       	jmp    80104e86 <alltraps>

801054e8 <vector63>:
.globl vector63
vector63:
  pushl $0
801054e8:	6a 00                	push   $0x0
  pushl $63
801054ea:	6a 3f                	push   $0x3f
  jmp alltraps
801054ec:	e9 95 f9 ff ff       	jmp    80104e86 <alltraps>

801054f1 <vector64>:
.globl vector64
vector64:
  pushl $0
801054f1:	6a 00                	push   $0x0
  pushl $64
801054f3:	6a 40                	push   $0x40
  jmp alltraps
801054f5:	e9 8c f9 ff ff       	jmp    80104e86 <alltraps>

801054fa <vector65>:
.globl vector65
vector65:
  pushl $0
801054fa:	6a 00                	push   $0x0
  pushl $65
801054fc:	6a 41                	push   $0x41
  jmp alltraps
801054fe:	e9 83 f9 ff ff       	jmp    80104e86 <alltraps>

80105503 <vector66>:
.globl vector66
vector66:
  pushl $0
80105503:	6a 00                	push   $0x0
  pushl $66
80105505:	6a 42                	push   $0x42
  jmp alltraps
80105507:	e9 7a f9 ff ff       	jmp    80104e86 <alltraps>

8010550c <vector67>:
.globl vector67
vector67:
  pushl $0
8010550c:	6a 00                	push   $0x0
  pushl $67
8010550e:	6a 43                	push   $0x43
  jmp alltraps
80105510:	e9 71 f9 ff ff       	jmp    80104e86 <alltraps>

80105515 <vector68>:
.globl vector68
vector68:
  pushl $0
80105515:	6a 00                	push   $0x0
  pushl $68
80105517:	6a 44                	push   $0x44
  jmp alltraps
80105519:	e9 68 f9 ff ff       	jmp    80104e86 <alltraps>

8010551e <vector69>:
.globl vector69
vector69:
  pushl $0
8010551e:	6a 00                	push   $0x0
  pushl $69
80105520:	6a 45                	push   $0x45
  jmp alltraps
80105522:	e9 5f f9 ff ff       	jmp    80104e86 <alltraps>

80105527 <vector70>:
.globl vector70
vector70:
  pushl $0
80105527:	6a 00                	push   $0x0
  pushl $70
80105529:	6a 46                	push   $0x46
  jmp alltraps
8010552b:	e9 56 f9 ff ff       	jmp    80104e86 <alltraps>

80105530 <vector71>:
.globl vector71
vector71:
  pushl $0
80105530:	6a 00                	push   $0x0
  pushl $71
80105532:	6a 47                	push   $0x47
  jmp alltraps
80105534:	e9 4d f9 ff ff       	jmp    80104e86 <alltraps>

80105539 <vector72>:
.globl vector72
vector72:
  pushl $0
80105539:	6a 00                	push   $0x0
  pushl $72
8010553b:	6a 48                	push   $0x48
  jmp alltraps
8010553d:	e9 44 f9 ff ff       	jmp    80104e86 <alltraps>

80105542 <vector73>:
.globl vector73
vector73:
  pushl $0
80105542:	6a 00                	push   $0x0
  pushl $73
80105544:	6a 49                	push   $0x49
  jmp alltraps
80105546:	e9 3b f9 ff ff       	jmp    80104e86 <alltraps>

8010554b <vector74>:
.globl vector74
vector74:
  pushl $0
8010554b:	6a 00                	push   $0x0
  pushl $74
8010554d:	6a 4a                	push   $0x4a
  jmp alltraps
8010554f:	e9 32 f9 ff ff       	jmp    80104e86 <alltraps>

80105554 <vector75>:
.globl vector75
vector75:
  pushl $0
80105554:	6a 00                	push   $0x0
  pushl $75
80105556:	6a 4b                	push   $0x4b
  jmp alltraps
80105558:	e9 29 f9 ff ff       	jmp    80104e86 <alltraps>

8010555d <vector76>:
.globl vector76
vector76:
  pushl $0
8010555d:	6a 00                	push   $0x0
  pushl $76
8010555f:	6a 4c                	push   $0x4c
  jmp alltraps
80105561:	e9 20 f9 ff ff       	jmp    80104e86 <alltraps>

80105566 <vector77>:
.globl vector77
vector77:
  pushl $0
80105566:	6a 00                	push   $0x0
  pushl $77
80105568:	6a 4d                	push   $0x4d
  jmp alltraps
8010556a:	e9 17 f9 ff ff       	jmp    80104e86 <alltraps>

8010556f <vector78>:
.globl vector78
vector78:
  pushl $0
8010556f:	6a 00                	push   $0x0
  pushl $78
80105571:	6a 4e                	push   $0x4e
  jmp alltraps
80105573:	e9 0e f9 ff ff       	jmp    80104e86 <alltraps>

80105578 <vector79>:
.globl vector79
vector79:
  pushl $0
80105578:	6a 00                	push   $0x0
  pushl $79
8010557a:	6a 4f                	push   $0x4f
  jmp alltraps
8010557c:	e9 05 f9 ff ff       	jmp    80104e86 <alltraps>

80105581 <vector80>:
.globl vector80
vector80:
  pushl $0
80105581:	6a 00                	push   $0x0
  pushl $80
80105583:	6a 50                	push   $0x50
  jmp alltraps
80105585:	e9 fc f8 ff ff       	jmp    80104e86 <alltraps>

8010558a <vector81>:
.globl vector81
vector81:
  pushl $0
8010558a:	6a 00                	push   $0x0
  pushl $81
8010558c:	6a 51                	push   $0x51
  jmp alltraps
8010558e:	e9 f3 f8 ff ff       	jmp    80104e86 <alltraps>

80105593 <vector82>:
.globl vector82
vector82:
  pushl $0
80105593:	6a 00                	push   $0x0
  pushl $82
80105595:	6a 52                	push   $0x52
  jmp alltraps
80105597:	e9 ea f8 ff ff       	jmp    80104e86 <alltraps>

8010559c <vector83>:
.globl vector83
vector83:
  pushl $0
8010559c:	6a 00                	push   $0x0
  pushl $83
8010559e:	6a 53                	push   $0x53
  jmp alltraps
801055a0:	e9 e1 f8 ff ff       	jmp    80104e86 <alltraps>

801055a5 <vector84>:
.globl vector84
vector84:
  pushl $0
801055a5:	6a 00                	push   $0x0
  pushl $84
801055a7:	6a 54                	push   $0x54
  jmp alltraps
801055a9:	e9 d8 f8 ff ff       	jmp    80104e86 <alltraps>

801055ae <vector85>:
.globl vector85
vector85:
  pushl $0
801055ae:	6a 00                	push   $0x0
  pushl $85
801055b0:	6a 55                	push   $0x55
  jmp alltraps
801055b2:	e9 cf f8 ff ff       	jmp    80104e86 <alltraps>

801055b7 <vector86>:
.globl vector86
vector86:
  pushl $0
801055b7:	6a 00                	push   $0x0
  pushl $86
801055b9:	6a 56                	push   $0x56
  jmp alltraps
801055bb:	e9 c6 f8 ff ff       	jmp    80104e86 <alltraps>

801055c0 <vector87>:
.globl vector87
vector87:
  pushl $0
801055c0:	6a 00                	push   $0x0
  pushl $87
801055c2:	6a 57                	push   $0x57
  jmp alltraps
801055c4:	e9 bd f8 ff ff       	jmp    80104e86 <alltraps>

801055c9 <vector88>:
.globl vector88
vector88:
  pushl $0
801055c9:	6a 00                	push   $0x0
  pushl $88
801055cb:	6a 58                	push   $0x58
  jmp alltraps
801055cd:	e9 b4 f8 ff ff       	jmp    80104e86 <alltraps>

801055d2 <vector89>:
.globl vector89
vector89:
  pushl $0
801055d2:	6a 00                	push   $0x0
  pushl $89
801055d4:	6a 59                	push   $0x59
  jmp alltraps
801055d6:	e9 ab f8 ff ff       	jmp    80104e86 <alltraps>

801055db <vector90>:
.globl vector90
vector90:
  pushl $0
801055db:	6a 00                	push   $0x0
  pushl $90
801055dd:	6a 5a                	push   $0x5a
  jmp alltraps
801055df:	e9 a2 f8 ff ff       	jmp    80104e86 <alltraps>

801055e4 <vector91>:
.globl vector91
vector91:
  pushl $0
801055e4:	6a 00                	push   $0x0
  pushl $91
801055e6:	6a 5b                	push   $0x5b
  jmp alltraps
801055e8:	e9 99 f8 ff ff       	jmp    80104e86 <alltraps>

801055ed <vector92>:
.globl vector92
vector92:
  pushl $0
801055ed:	6a 00                	push   $0x0
  pushl $92
801055ef:	6a 5c                	push   $0x5c
  jmp alltraps
801055f1:	e9 90 f8 ff ff       	jmp    80104e86 <alltraps>

801055f6 <vector93>:
.globl vector93
vector93:
  pushl $0
801055f6:	6a 00                	push   $0x0
  pushl $93
801055f8:	6a 5d                	push   $0x5d
  jmp alltraps
801055fa:	e9 87 f8 ff ff       	jmp    80104e86 <alltraps>

801055ff <vector94>:
.globl vector94
vector94:
  pushl $0
801055ff:	6a 00                	push   $0x0
  pushl $94
80105601:	6a 5e                	push   $0x5e
  jmp alltraps
80105603:	e9 7e f8 ff ff       	jmp    80104e86 <alltraps>

80105608 <vector95>:
.globl vector95
vector95:
  pushl $0
80105608:	6a 00                	push   $0x0
  pushl $95
8010560a:	6a 5f                	push   $0x5f
  jmp alltraps
8010560c:	e9 75 f8 ff ff       	jmp    80104e86 <alltraps>

80105611 <vector96>:
.globl vector96
vector96:
  pushl $0
80105611:	6a 00                	push   $0x0
  pushl $96
80105613:	6a 60                	push   $0x60
  jmp alltraps
80105615:	e9 6c f8 ff ff       	jmp    80104e86 <alltraps>

8010561a <vector97>:
.globl vector97
vector97:
  pushl $0
8010561a:	6a 00                	push   $0x0
  pushl $97
8010561c:	6a 61                	push   $0x61
  jmp alltraps
8010561e:	e9 63 f8 ff ff       	jmp    80104e86 <alltraps>

80105623 <vector98>:
.globl vector98
vector98:
  pushl $0
80105623:	6a 00                	push   $0x0
  pushl $98
80105625:	6a 62                	push   $0x62
  jmp alltraps
80105627:	e9 5a f8 ff ff       	jmp    80104e86 <alltraps>

8010562c <vector99>:
.globl vector99
vector99:
  pushl $0
8010562c:	6a 00                	push   $0x0
  pushl $99
8010562e:	6a 63                	push   $0x63
  jmp alltraps
80105630:	e9 51 f8 ff ff       	jmp    80104e86 <alltraps>

80105635 <vector100>:
.globl vector100
vector100:
  pushl $0
80105635:	6a 00                	push   $0x0
  pushl $100
80105637:	6a 64                	push   $0x64
  jmp alltraps
80105639:	e9 48 f8 ff ff       	jmp    80104e86 <alltraps>

8010563e <vector101>:
.globl vector101
vector101:
  pushl $0
8010563e:	6a 00                	push   $0x0
  pushl $101
80105640:	6a 65                	push   $0x65
  jmp alltraps
80105642:	e9 3f f8 ff ff       	jmp    80104e86 <alltraps>

80105647 <vector102>:
.globl vector102
vector102:
  pushl $0
80105647:	6a 00                	push   $0x0
  pushl $102
80105649:	6a 66                	push   $0x66
  jmp alltraps
8010564b:	e9 36 f8 ff ff       	jmp    80104e86 <alltraps>

80105650 <vector103>:
.globl vector103
vector103:
  pushl $0
80105650:	6a 00                	push   $0x0
  pushl $103
80105652:	6a 67                	push   $0x67
  jmp alltraps
80105654:	e9 2d f8 ff ff       	jmp    80104e86 <alltraps>

80105659 <vector104>:
.globl vector104
vector104:
  pushl $0
80105659:	6a 00                	push   $0x0
  pushl $104
8010565b:	6a 68                	push   $0x68
  jmp alltraps
8010565d:	e9 24 f8 ff ff       	jmp    80104e86 <alltraps>

80105662 <vector105>:
.globl vector105
vector105:
  pushl $0
80105662:	6a 00                	push   $0x0
  pushl $105
80105664:	6a 69                	push   $0x69
  jmp alltraps
80105666:	e9 1b f8 ff ff       	jmp    80104e86 <alltraps>

8010566b <vector106>:
.globl vector106
vector106:
  pushl $0
8010566b:	6a 00                	push   $0x0
  pushl $106
8010566d:	6a 6a                	push   $0x6a
  jmp alltraps
8010566f:	e9 12 f8 ff ff       	jmp    80104e86 <alltraps>

80105674 <vector107>:
.globl vector107
vector107:
  pushl $0
80105674:	6a 00                	push   $0x0
  pushl $107
80105676:	6a 6b                	push   $0x6b
  jmp alltraps
80105678:	e9 09 f8 ff ff       	jmp    80104e86 <alltraps>

8010567d <vector108>:
.globl vector108
vector108:
  pushl $0
8010567d:	6a 00                	push   $0x0
  pushl $108
8010567f:	6a 6c                	push   $0x6c
  jmp alltraps
80105681:	e9 00 f8 ff ff       	jmp    80104e86 <alltraps>

80105686 <vector109>:
.globl vector109
vector109:
  pushl $0
80105686:	6a 00                	push   $0x0
  pushl $109
80105688:	6a 6d                	push   $0x6d
  jmp alltraps
8010568a:	e9 f7 f7 ff ff       	jmp    80104e86 <alltraps>

8010568f <vector110>:
.globl vector110
vector110:
  pushl $0
8010568f:	6a 00                	push   $0x0
  pushl $110
80105691:	6a 6e                	push   $0x6e
  jmp alltraps
80105693:	e9 ee f7 ff ff       	jmp    80104e86 <alltraps>

80105698 <vector111>:
.globl vector111
vector111:
  pushl $0
80105698:	6a 00                	push   $0x0
  pushl $111
8010569a:	6a 6f                	push   $0x6f
  jmp alltraps
8010569c:	e9 e5 f7 ff ff       	jmp    80104e86 <alltraps>

801056a1 <vector112>:
.globl vector112
vector112:
  pushl $0
801056a1:	6a 00                	push   $0x0
  pushl $112
801056a3:	6a 70                	push   $0x70
  jmp alltraps
801056a5:	e9 dc f7 ff ff       	jmp    80104e86 <alltraps>

801056aa <vector113>:
.globl vector113
vector113:
  pushl $0
801056aa:	6a 00                	push   $0x0
  pushl $113
801056ac:	6a 71                	push   $0x71
  jmp alltraps
801056ae:	e9 d3 f7 ff ff       	jmp    80104e86 <alltraps>

801056b3 <vector114>:
.globl vector114
vector114:
  pushl $0
801056b3:	6a 00                	push   $0x0
  pushl $114
801056b5:	6a 72                	push   $0x72
  jmp alltraps
801056b7:	e9 ca f7 ff ff       	jmp    80104e86 <alltraps>

801056bc <vector115>:
.globl vector115
vector115:
  pushl $0
801056bc:	6a 00                	push   $0x0
  pushl $115
801056be:	6a 73                	push   $0x73
  jmp alltraps
801056c0:	e9 c1 f7 ff ff       	jmp    80104e86 <alltraps>

801056c5 <vector116>:
.globl vector116
vector116:
  pushl $0
801056c5:	6a 00                	push   $0x0
  pushl $116
801056c7:	6a 74                	push   $0x74
  jmp alltraps
801056c9:	e9 b8 f7 ff ff       	jmp    80104e86 <alltraps>

801056ce <vector117>:
.globl vector117
vector117:
  pushl $0
801056ce:	6a 00                	push   $0x0
  pushl $117
801056d0:	6a 75                	push   $0x75
  jmp alltraps
801056d2:	e9 af f7 ff ff       	jmp    80104e86 <alltraps>

801056d7 <vector118>:
.globl vector118
vector118:
  pushl $0
801056d7:	6a 00                	push   $0x0
  pushl $118
801056d9:	6a 76                	push   $0x76
  jmp alltraps
801056db:	e9 a6 f7 ff ff       	jmp    80104e86 <alltraps>

801056e0 <vector119>:
.globl vector119
vector119:
  pushl $0
801056e0:	6a 00                	push   $0x0
  pushl $119
801056e2:	6a 77                	push   $0x77
  jmp alltraps
801056e4:	e9 9d f7 ff ff       	jmp    80104e86 <alltraps>

801056e9 <vector120>:
.globl vector120
vector120:
  pushl $0
801056e9:	6a 00                	push   $0x0
  pushl $120
801056eb:	6a 78                	push   $0x78
  jmp alltraps
801056ed:	e9 94 f7 ff ff       	jmp    80104e86 <alltraps>

801056f2 <vector121>:
.globl vector121
vector121:
  pushl $0
801056f2:	6a 00                	push   $0x0
  pushl $121
801056f4:	6a 79                	push   $0x79
  jmp alltraps
801056f6:	e9 8b f7 ff ff       	jmp    80104e86 <alltraps>

801056fb <vector122>:
.globl vector122
vector122:
  pushl $0
801056fb:	6a 00                	push   $0x0
  pushl $122
801056fd:	6a 7a                	push   $0x7a
  jmp alltraps
801056ff:	e9 82 f7 ff ff       	jmp    80104e86 <alltraps>

80105704 <vector123>:
.globl vector123
vector123:
  pushl $0
80105704:	6a 00                	push   $0x0
  pushl $123
80105706:	6a 7b                	push   $0x7b
  jmp alltraps
80105708:	e9 79 f7 ff ff       	jmp    80104e86 <alltraps>

8010570d <vector124>:
.globl vector124
vector124:
  pushl $0
8010570d:	6a 00                	push   $0x0
  pushl $124
8010570f:	6a 7c                	push   $0x7c
  jmp alltraps
80105711:	e9 70 f7 ff ff       	jmp    80104e86 <alltraps>

80105716 <vector125>:
.globl vector125
vector125:
  pushl $0
80105716:	6a 00                	push   $0x0
  pushl $125
80105718:	6a 7d                	push   $0x7d
  jmp alltraps
8010571a:	e9 67 f7 ff ff       	jmp    80104e86 <alltraps>

8010571f <vector126>:
.globl vector126
vector126:
  pushl $0
8010571f:	6a 00                	push   $0x0
  pushl $126
80105721:	6a 7e                	push   $0x7e
  jmp alltraps
80105723:	e9 5e f7 ff ff       	jmp    80104e86 <alltraps>

80105728 <vector127>:
.globl vector127
vector127:
  pushl $0
80105728:	6a 00                	push   $0x0
  pushl $127
8010572a:	6a 7f                	push   $0x7f
  jmp alltraps
8010572c:	e9 55 f7 ff ff       	jmp    80104e86 <alltraps>

80105731 <vector128>:
.globl vector128
vector128:
  pushl $0
80105731:	6a 00                	push   $0x0
  pushl $128
80105733:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80105738:	e9 49 f7 ff ff       	jmp    80104e86 <alltraps>

8010573d <vector129>:
.globl vector129
vector129:
  pushl $0
8010573d:	6a 00                	push   $0x0
  pushl $129
8010573f:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80105744:	e9 3d f7 ff ff       	jmp    80104e86 <alltraps>

80105749 <vector130>:
.globl vector130
vector130:
  pushl $0
80105749:	6a 00                	push   $0x0
  pushl $130
8010574b:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80105750:	e9 31 f7 ff ff       	jmp    80104e86 <alltraps>

80105755 <vector131>:
.globl vector131
vector131:
  pushl $0
80105755:	6a 00                	push   $0x0
  pushl $131
80105757:	68 83 00 00 00       	push   $0x83
  jmp alltraps
8010575c:	e9 25 f7 ff ff       	jmp    80104e86 <alltraps>

80105761 <vector132>:
.globl vector132
vector132:
  pushl $0
80105761:	6a 00                	push   $0x0
  pushl $132
80105763:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80105768:	e9 19 f7 ff ff       	jmp    80104e86 <alltraps>

8010576d <vector133>:
.globl vector133
vector133:
  pushl $0
8010576d:	6a 00                	push   $0x0
  pushl $133
8010576f:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80105774:	e9 0d f7 ff ff       	jmp    80104e86 <alltraps>

80105779 <vector134>:
.globl vector134
vector134:
  pushl $0
80105779:	6a 00                	push   $0x0
  pushl $134
8010577b:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80105780:	e9 01 f7 ff ff       	jmp    80104e86 <alltraps>

80105785 <vector135>:
.globl vector135
vector135:
  pushl $0
80105785:	6a 00                	push   $0x0
  pushl $135
80105787:	68 87 00 00 00       	push   $0x87
  jmp alltraps
8010578c:	e9 f5 f6 ff ff       	jmp    80104e86 <alltraps>

80105791 <vector136>:
.globl vector136
vector136:
  pushl $0
80105791:	6a 00                	push   $0x0
  pushl $136
80105793:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80105798:	e9 e9 f6 ff ff       	jmp    80104e86 <alltraps>

8010579d <vector137>:
.globl vector137
vector137:
  pushl $0
8010579d:	6a 00                	push   $0x0
  pushl $137
8010579f:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801057a4:	e9 dd f6 ff ff       	jmp    80104e86 <alltraps>

801057a9 <vector138>:
.globl vector138
vector138:
  pushl $0
801057a9:	6a 00                	push   $0x0
  pushl $138
801057ab:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801057b0:	e9 d1 f6 ff ff       	jmp    80104e86 <alltraps>

801057b5 <vector139>:
.globl vector139
vector139:
  pushl $0
801057b5:	6a 00                	push   $0x0
  pushl $139
801057b7:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801057bc:	e9 c5 f6 ff ff       	jmp    80104e86 <alltraps>

801057c1 <vector140>:
.globl vector140
vector140:
  pushl $0
801057c1:	6a 00                	push   $0x0
  pushl $140
801057c3:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801057c8:	e9 b9 f6 ff ff       	jmp    80104e86 <alltraps>

801057cd <vector141>:
.globl vector141
vector141:
  pushl $0
801057cd:	6a 00                	push   $0x0
  pushl $141
801057cf:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801057d4:	e9 ad f6 ff ff       	jmp    80104e86 <alltraps>

801057d9 <vector142>:
.globl vector142
vector142:
  pushl $0
801057d9:	6a 00                	push   $0x0
  pushl $142
801057db:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
801057e0:	e9 a1 f6 ff ff       	jmp    80104e86 <alltraps>

801057e5 <vector143>:
.globl vector143
vector143:
  pushl $0
801057e5:	6a 00                	push   $0x0
  pushl $143
801057e7:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
801057ec:	e9 95 f6 ff ff       	jmp    80104e86 <alltraps>

801057f1 <vector144>:
.globl vector144
vector144:
  pushl $0
801057f1:	6a 00                	push   $0x0
  pushl $144
801057f3:	68 90 00 00 00       	push   $0x90
  jmp alltraps
801057f8:	e9 89 f6 ff ff       	jmp    80104e86 <alltraps>

801057fd <vector145>:
.globl vector145
vector145:
  pushl $0
801057fd:	6a 00                	push   $0x0
  pushl $145
801057ff:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80105804:	e9 7d f6 ff ff       	jmp    80104e86 <alltraps>

80105809 <vector146>:
.globl vector146
vector146:
  pushl $0
80105809:	6a 00                	push   $0x0
  pushl $146
8010580b:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80105810:	e9 71 f6 ff ff       	jmp    80104e86 <alltraps>

80105815 <vector147>:
.globl vector147
vector147:
  pushl $0
80105815:	6a 00                	push   $0x0
  pushl $147
80105817:	68 93 00 00 00       	push   $0x93
  jmp alltraps
8010581c:	e9 65 f6 ff ff       	jmp    80104e86 <alltraps>

80105821 <vector148>:
.globl vector148
vector148:
  pushl $0
80105821:	6a 00                	push   $0x0
  pushl $148
80105823:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80105828:	e9 59 f6 ff ff       	jmp    80104e86 <alltraps>

8010582d <vector149>:
.globl vector149
vector149:
  pushl $0
8010582d:	6a 00                	push   $0x0
  pushl $149
8010582f:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80105834:	e9 4d f6 ff ff       	jmp    80104e86 <alltraps>

80105839 <vector150>:
.globl vector150
vector150:
  pushl $0
80105839:	6a 00                	push   $0x0
  pushl $150
8010583b:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80105840:	e9 41 f6 ff ff       	jmp    80104e86 <alltraps>

80105845 <vector151>:
.globl vector151
vector151:
  pushl $0
80105845:	6a 00                	push   $0x0
  pushl $151
80105847:	68 97 00 00 00       	push   $0x97
  jmp alltraps
8010584c:	e9 35 f6 ff ff       	jmp    80104e86 <alltraps>

80105851 <vector152>:
.globl vector152
vector152:
  pushl $0
80105851:	6a 00                	push   $0x0
  pushl $152
80105853:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80105858:	e9 29 f6 ff ff       	jmp    80104e86 <alltraps>

8010585d <vector153>:
.globl vector153
vector153:
  pushl $0
8010585d:	6a 00                	push   $0x0
  pushl $153
8010585f:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80105864:	e9 1d f6 ff ff       	jmp    80104e86 <alltraps>

80105869 <vector154>:
.globl vector154
vector154:
  pushl $0
80105869:	6a 00                	push   $0x0
  pushl $154
8010586b:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80105870:	e9 11 f6 ff ff       	jmp    80104e86 <alltraps>

80105875 <vector155>:
.globl vector155
vector155:
  pushl $0
80105875:	6a 00                	push   $0x0
  pushl $155
80105877:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
8010587c:	e9 05 f6 ff ff       	jmp    80104e86 <alltraps>

80105881 <vector156>:
.globl vector156
vector156:
  pushl $0
80105881:	6a 00                	push   $0x0
  pushl $156
80105883:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80105888:	e9 f9 f5 ff ff       	jmp    80104e86 <alltraps>

8010588d <vector157>:
.globl vector157
vector157:
  pushl $0
8010588d:	6a 00                	push   $0x0
  pushl $157
8010588f:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80105894:	e9 ed f5 ff ff       	jmp    80104e86 <alltraps>

80105899 <vector158>:
.globl vector158
vector158:
  pushl $0
80105899:	6a 00                	push   $0x0
  pushl $158
8010589b:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801058a0:	e9 e1 f5 ff ff       	jmp    80104e86 <alltraps>

801058a5 <vector159>:
.globl vector159
vector159:
  pushl $0
801058a5:	6a 00                	push   $0x0
  pushl $159
801058a7:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801058ac:	e9 d5 f5 ff ff       	jmp    80104e86 <alltraps>

801058b1 <vector160>:
.globl vector160
vector160:
  pushl $0
801058b1:	6a 00                	push   $0x0
  pushl $160
801058b3:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801058b8:	e9 c9 f5 ff ff       	jmp    80104e86 <alltraps>

801058bd <vector161>:
.globl vector161
vector161:
  pushl $0
801058bd:	6a 00                	push   $0x0
  pushl $161
801058bf:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801058c4:	e9 bd f5 ff ff       	jmp    80104e86 <alltraps>

801058c9 <vector162>:
.globl vector162
vector162:
  pushl $0
801058c9:	6a 00                	push   $0x0
  pushl $162
801058cb:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801058d0:	e9 b1 f5 ff ff       	jmp    80104e86 <alltraps>

801058d5 <vector163>:
.globl vector163
vector163:
  pushl $0
801058d5:	6a 00                	push   $0x0
  pushl $163
801058d7:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
801058dc:	e9 a5 f5 ff ff       	jmp    80104e86 <alltraps>

801058e1 <vector164>:
.globl vector164
vector164:
  pushl $0
801058e1:	6a 00                	push   $0x0
  pushl $164
801058e3:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
801058e8:	e9 99 f5 ff ff       	jmp    80104e86 <alltraps>

801058ed <vector165>:
.globl vector165
vector165:
  pushl $0
801058ed:	6a 00                	push   $0x0
  pushl $165
801058ef:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
801058f4:	e9 8d f5 ff ff       	jmp    80104e86 <alltraps>

801058f9 <vector166>:
.globl vector166
vector166:
  pushl $0
801058f9:	6a 00                	push   $0x0
  pushl $166
801058fb:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105900:	e9 81 f5 ff ff       	jmp    80104e86 <alltraps>

80105905 <vector167>:
.globl vector167
vector167:
  pushl $0
80105905:	6a 00                	push   $0x0
  pushl $167
80105907:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
8010590c:	e9 75 f5 ff ff       	jmp    80104e86 <alltraps>

80105911 <vector168>:
.globl vector168
vector168:
  pushl $0
80105911:	6a 00                	push   $0x0
  pushl $168
80105913:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105918:	e9 69 f5 ff ff       	jmp    80104e86 <alltraps>

8010591d <vector169>:
.globl vector169
vector169:
  pushl $0
8010591d:	6a 00                	push   $0x0
  pushl $169
8010591f:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80105924:	e9 5d f5 ff ff       	jmp    80104e86 <alltraps>

80105929 <vector170>:
.globl vector170
vector170:
  pushl $0
80105929:	6a 00                	push   $0x0
  pushl $170
8010592b:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105930:	e9 51 f5 ff ff       	jmp    80104e86 <alltraps>

80105935 <vector171>:
.globl vector171
vector171:
  pushl $0
80105935:	6a 00                	push   $0x0
  pushl $171
80105937:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
8010593c:	e9 45 f5 ff ff       	jmp    80104e86 <alltraps>

80105941 <vector172>:
.globl vector172
vector172:
  pushl $0
80105941:	6a 00                	push   $0x0
  pushl $172
80105943:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105948:	e9 39 f5 ff ff       	jmp    80104e86 <alltraps>

8010594d <vector173>:
.globl vector173
vector173:
  pushl $0
8010594d:	6a 00                	push   $0x0
  pushl $173
8010594f:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80105954:	e9 2d f5 ff ff       	jmp    80104e86 <alltraps>

80105959 <vector174>:
.globl vector174
vector174:
  pushl $0
80105959:	6a 00                	push   $0x0
  pushl $174
8010595b:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105960:	e9 21 f5 ff ff       	jmp    80104e86 <alltraps>

80105965 <vector175>:
.globl vector175
vector175:
  pushl $0
80105965:	6a 00                	push   $0x0
  pushl $175
80105967:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
8010596c:	e9 15 f5 ff ff       	jmp    80104e86 <alltraps>

80105971 <vector176>:
.globl vector176
vector176:
  pushl $0
80105971:	6a 00                	push   $0x0
  pushl $176
80105973:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105978:	e9 09 f5 ff ff       	jmp    80104e86 <alltraps>

8010597d <vector177>:
.globl vector177
vector177:
  pushl $0
8010597d:	6a 00                	push   $0x0
  pushl $177
8010597f:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105984:	e9 fd f4 ff ff       	jmp    80104e86 <alltraps>

80105989 <vector178>:
.globl vector178
vector178:
  pushl $0
80105989:	6a 00                	push   $0x0
  pushl $178
8010598b:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105990:	e9 f1 f4 ff ff       	jmp    80104e86 <alltraps>

80105995 <vector179>:
.globl vector179
vector179:
  pushl $0
80105995:	6a 00                	push   $0x0
  pushl $179
80105997:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
8010599c:	e9 e5 f4 ff ff       	jmp    80104e86 <alltraps>

801059a1 <vector180>:
.globl vector180
vector180:
  pushl $0
801059a1:	6a 00                	push   $0x0
  pushl $180
801059a3:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801059a8:	e9 d9 f4 ff ff       	jmp    80104e86 <alltraps>

801059ad <vector181>:
.globl vector181
vector181:
  pushl $0
801059ad:	6a 00                	push   $0x0
  pushl $181
801059af:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801059b4:	e9 cd f4 ff ff       	jmp    80104e86 <alltraps>

801059b9 <vector182>:
.globl vector182
vector182:
  pushl $0
801059b9:	6a 00                	push   $0x0
  pushl $182
801059bb:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801059c0:	e9 c1 f4 ff ff       	jmp    80104e86 <alltraps>

801059c5 <vector183>:
.globl vector183
vector183:
  pushl $0
801059c5:	6a 00                	push   $0x0
  pushl $183
801059c7:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801059cc:	e9 b5 f4 ff ff       	jmp    80104e86 <alltraps>

801059d1 <vector184>:
.globl vector184
vector184:
  pushl $0
801059d1:	6a 00                	push   $0x0
  pushl $184
801059d3:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801059d8:	e9 a9 f4 ff ff       	jmp    80104e86 <alltraps>

801059dd <vector185>:
.globl vector185
vector185:
  pushl $0
801059dd:	6a 00                	push   $0x0
  pushl $185
801059df:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
801059e4:	e9 9d f4 ff ff       	jmp    80104e86 <alltraps>

801059e9 <vector186>:
.globl vector186
vector186:
  pushl $0
801059e9:	6a 00                	push   $0x0
  pushl $186
801059eb:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
801059f0:	e9 91 f4 ff ff       	jmp    80104e86 <alltraps>

801059f5 <vector187>:
.globl vector187
vector187:
  pushl $0
801059f5:	6a 00                	push   $0x0
  pushl $187
801059f7:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
801059fc:	e9 85 f4 ff ff       	jmp    80104e86 <alltraps>

80105a01 <vector188>:
.globl vector188
vector188:
  pushl $0
80105a01:	6a 00                	push   $0x0
  pushl $188
80105a03:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105a08:	e9 79 f4 ff ff       	jmp    80104e86 <alltraps>

80105a0d <vector189>:
.globl vector189
vector189:
  pushl $0
80105a0d:	6a 00                	push   $0x0
  pushl $189
80105a0f:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105a14:	e9 6d f4 ff ff       	jmp    80104e86 <alltraps>

80105a19 <vector190>:
.globl vector190
vector190:
  pushl $0
80105a19:	6a 00                	push   $0x0
  pushl $190
80105a1b:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105a20:	e9 61 f4 ff ff       	jmp    80104e86 <alltraps>

80105a25 <vector191>:
.globl vector191
vector191:
  pushl $0
80105a25:	6a 00                	push   $0x0
  pushl $191
80105a27:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105a2c:	e9 55 f4 ff ff       	jmp    80104e86 <alltraps>

80105a31 <vector192>:
.globl vector192
vector192:
  pushl $0
80105a31:	6a 00                	push   $0x0
  pushl $192
80105a33:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105a38:	e9 49 f4 ff ff       	jmp    80104e86 <alltraps>

80105a3d <vector193>:
.globl vector193
vector193:
  pushl $0
80105a3d:	6a 00                	push   $0x0
  pushl $193
80105a3f:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105a44:	e9 3d f4 ff ff       	jmp    80104e86 <alltraps>

80105a49 <vector194>:
.globl vector194
vector194:
  pushl $0
80105a49:	6a 00                	push   $0x0
  pushl $194
80105a4b:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105a50:	e9 31 f4 ff ff       	jmp    80104e86 <alltraps>

80105a55 <vector195>:
.globl vector195
vector195:
  pushl $0
80105a55:	6a 00                	push   $0x0
  pushl $195
80105a57:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105a5c:	e9 25 f4 ff ff       	jmp    80104e86 <alltraps>

80105a61 <vector196>:
.globl vector196
vector196:
  pushl $0
80105a61:	6a 00                	push   $0x0
  pushl $196
80105a63:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105a68:	e9 19 f4 ff ff       	jmp    80104e86 <alltraps>

80105a6d <vector197>:
.globl vector197
vector197:
  pushl $0
80105a6d:	6a 00                	push   $0x0
  pushl $197
80105a6f:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105a74:	e9 0d f4 ff ff       	jmp    80104e86 <alltraps>

80105a79 <vector198>:
.globl vector198
vector198:
  pushl $0
80105a79:	6a 00                	push   $0x0
  pushl $198
80105a7b:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105a80:	e9 01 f4 ff ff       	jmp    80104e86 <alltraps>

80105a85 <vector199>:
.globl vector199
vector199:
  pushl $0
80105a85:	6a 00                	push   $0x0
  pushl $199
80105a87:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105a8c:	e9 f5 f3 ff ff       	jmp    80104e86 <alltraps>

80105a91 <vector200>:
.globl vector200
vector200:
  pushl $0
80105a91:	6a 00                	push   $0x0
  pushl $200
80105a93:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105a98:	e9 e9 f3 ff ff       	jmp    80104e86 <alltraps>

80105a9d <vector201>:
.globl vector201
vector201:
  pushl $0
80105a9d:	6a 00                	push   $0x0
  pushl $201
80105a9f:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105aa4:	e9 dd f3 ff ff       	jmp    80104e86 <alltraps>

80105aa9 <vector202>:
.globl vector202
vector202:
  pushl $0
80105aa9:	6a 00                	push   $0x0
  pushl $202
80105aab:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105ab0:	e9 d1 f3 ff ff       	jmp    80104e86 <alltraps>

80105ab5 <vector203>:
.globl vector203
vector203:
  pushl $0
80105ab5:	6a 00                	push   $0x0
  pushl $203
80105ab7:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105abc:	e9 c5 f3 ff ff       	jmp    80104e86 <alltraps>

80105ac1 <vector204>:
.globl vector204
vector204:
  pushl $0
80105ac1:	6a 00                	push   $0x0
  pushl $204
80105ac3:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105ac8:	e9 b9 f3 ff ff       	jmp    80104e86 <alltraps>

80105acd <vector205>:
.globl vector205
vector205:
  pushl $0
80105acd:	6a 00                	push   $0x0
  pushl $205
80105acf:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105ad4:	e9 ad f3 ff ff       	jmp    80104e86 <alltraps>

80105ad9 <vector206>:
.globl vector206
vector206:
  pushl $0
80105ad9:	6a 00                	push   $0x0
  pushl $206
80105adb:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105ae0:	e9 a1 f3 ff ff       	jmp    80104e86 <alltraps>

80105ae5 <vector207>:
.globl vector207
vector207:
  pushl $0
80105ae5:	6a 00                	push   $0x0
  pushl $207
80105ae7:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105aec:	e9 95 f3 ff ff       	jmp    80104e86 <alltraps>

80105af1 <vector208>:
.globl vector208
vector208:
  pushl $0
80105af1:	6a 00                	push   $0x0
  pushl $208
80105af3:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105af8:	e9 89 f3 ff ff       	jmp    80104e86 <alltraps>

80105afd <vector209>:
.globl vector209
vector209:
  pushl $0
80105afd:	6a 00                	push   $0x0
  pushl $209
80105aff:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105b04:	e9 7d f3 ff ff       	jmp    80104e86 <alltraps>

80105b09 <vector210>:
.globl vector210
vector210:
  pushl $0
80105b09:	6a 00                	push   $0x0
  pushl $210
80105b0b:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105b10:	e9 71 f3 ff ff       	jmp    80104e86 <alltraps>

80105b15 <vector211>:
.globl vector211
vector211:
  pushl $0
80105b15:	6a 00                	push   $0x0
  pushl $211
80105b17:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105b1c:	e9 65 f3 ff ff       	jmp    80104e86 <alltraps>

80105b21 <vector212>:
.globl vector212
vector212:
  pushl $0
80105b21:	6a 00                	push   $0x0
  pushl $212
80105b23:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105b28:	e9 59 f3 ff ff       	jmp    80104e86 <alltraps>

80105b2d <vector213>:
.globl vector213
vector213:
  pushl $0
80105b2d:	6a 00                	push   $0x0
  pushl $213
80105b2f:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105b34:	e9 4d f3 ff ff       	jmp    80104e86 <alltraps>

80105b39 <vector214>:
.globl vector214
vector214:
  pushl $0
80105b39:	6a 00                	push   $0x0
  pushl $214
80105b3b:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105b40:	e9 41 f3 ff ff       	jmp    80104e86 <alltraps>

80105b45 <vector215>:
.globl vector215
vector215:
  pushl $0
80105b45:	6a 00                	push   $0x0
  pushl $215
80105b47:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105b4c:	e9 35 f3 ff ff       	jmp    80104e86 <alltraps>

80105b51 <vector216>:
.globl vector216
vector216:
  pushl $0
80105b51:	6a 00                	push   $0x0
  pushl $216
80105b53:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105b58:	e9 29 f3 ff ff       	jmp    80104e86 <alltraps>

80105b5d <vector217>:
.globl vector217
vector217:
  pushl $0
80105b5d:	6a 00                	push   $0x0
  pushl $217
80105b5f:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105b64:	e9 1d f3 ff ff       	jmp    80104e86 <alltraps>

80105b69 <vector218>:
.globl vector218
vector218:
  pushl $0
80105b69:	6a 00                	push   $0x0
  pushl $218
80105b6b:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105b70:	e9 11 f3 ff ff       	jmp    80104e86 <alltraps>

80105b75 <vector219>:
.globl vector219
vector219:
  pushl $0
80105b75:	6a 00                	push   $0x0
  pushl $219
80105b77:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105b7c:	e9 05 f3 ff ff       	jmp    80104e86 <alltraps>

80105b81 <vector220>:
.globl vector220
vector220:
  pushl $0
80105b81:	6a 00                	push   $0x0
  pushl $220
80105b83:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105b88:	e9 f9 f2 ff ff       	jmp    80104e86 <alltraps>

80105b8d <vector221>:
.globl vector221
vector221:
  pushl $0
80105b8d:	6a 00                	push   $0x0
  pushl $221
80105b8f:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105b94:	e9 ed f2 ff ff       	jmp    80104e86 <alltraps>

80105b99 <vector222>:
.globl vector222
vector222:
  pushl $0
80105b99:	6a 00                	push   $0x0
  pushl $222
80105b9b:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105ba0:	e9 e1 f2 ff ff       	jmp    80104e86 <alltraps>

80105ba5 <vector223>:
.globl vector223
vector223:
  pushl $0
80105ba5:	6a 00                	push   $0x0
  pushl $223
80105ba7:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105bac:	e9 d5 f2 ff ff       	jmp    80104e86 <alltraps>

80105bb1 <vector224>:
.globl vector224
vector224:
  pushl $0
80105bb1:	6a 00                	push   $0x0
  pushl $224
80105bb3:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105bb8:	e9 c9 f2 ff ff       	jmp    80104e86 <alltraps>

80105bbd <vector225>:
.globl vector225
vector225:
  pushl $0
80105bbd:	6a 00                	push   $0x0
  pushl $225
80105bbf:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105bc4:	e9 bd f2 ff ff       	jmp    80104e86 <alltraps>

80105bc9 <vector226>:
.globl vector226
vector226:
  pushl $0
80105bc9:	6a 00                	push   $0x0
  pushl $226
80105bcb:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105bd0:	e9 b1 f2 ff ff       	jmp    80104e86 <alltraps>

80105bd5 <vector227>:
.globl vector227
vector227:
  pushl $0
80105bd5:	6a 00                	push   $0x0
  pushl $227
80105bd7:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105bdc:	e9 a5 f2 ff ff       	jmp    80104e86 <alltraps>

80105be1 <vector228>:
.globl vector228
vector228:
  pushl $0
80105be1:	6a 00                	push   $0x0
  pushl $228
80105be3:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105be8:	e9 99 f2 ff ff       	jmp    80104e86 <alltraps>

80105bed <vector229>:
.globl vector229
vector229:
  pushl $0
80105bed:	6a 00                	push   $0x0
  pushl $229
80105bef:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105bf4:	e9 8d f2 ff ff       	jmp    80104e86 <alltraps>

80105bf9 <vector230>:
.globl vector230
vector230:
  pushl $0
80105bf9:	6a 00                	push   $0x0
  pushl $230
80105bfb:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105c00:	e9 81 f2 ff ff       	jmp    80104e86 <alltraps>

80105c05 <vector231>:
.globl vector231
vector231:
  pushl $0
80105c05:	6a 00                	push   $0x0
  pushl $231
80105c07:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105c0c:	e9 75 f2 ff ff       	jmp    80104e86 <alltraps>

80105c11 <vector232>:
.globl vector232
vector232:
  pushl $0
80105c11:	6a 00                	push   $0x0
  pushl $232
80105c13:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105c18:	e9 69 f2 ff ff       	jmp    80104e86 <alltraps>

80105c1d <vector233>:
.globl vector233
vector233:
  pushl $0
80105c1d:	6a 00                	push   $0x0
  pushl $233
80105c1f:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105c24:	e9 5d f2 ff ff       	jmp    80104e86 <alltraps>

80105c29 <vector234>:
.globl vector234
vector234:
  pushl $0
80105c29:	6a 00                	push   $0x0
  pushl $234
80105c2b:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105c30:	e9 51 f2 ff ff       	jmp    80104e86 <alltraps>

80105c35 <vector235>:
.globl vector235
vector235:
  pushl $0
80105c35:	6a 00                	push   $0x0
  pushl $235
80105c37:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105c3c:	e9 45 f2 ff ff       	jmp    80104e86 <alltraps>

80105c41 <vector236>:
.globl vector236
vector236:
  pushl $0
80105c41:	6a 00                	push   $0x0
  pushl $236
80105c43:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105c48:	e9 39 f2 ff ff       	jmp    80104e86 <alltraps>

80105c4d <vector237>:
.globl vector237
vector237:
  pushl $0
80105c4d:	6a 00                	push   $0x0
  pushl $237
80105c4f:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105c54:	e9 2d f2 ff ff       	jmp    80104e86 <alltraps>

80105c59 <vector238>:
.globl vector238
vector238:
  pushl $0
80105c59:	6a 00                	push   $0x0
  pushl $238
80105c5b:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105c60:	e9 21 f2 ff ff       	jmp    80104e86 <alltraps>

80105c65 <vector239>:
.globl vector239
vector239:
  pushl $0
80105c65:	6a 00                	push   $0x0
  pushl $239
80105c67:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105c6c:	e9 15 f2 ff ff       	jmp    80104e86 <alltraps>

80105c71 <vector240>:
.globl vector240
vector240:
  pushl $0
80105c71:	6a 00                	push   $0x0
  pushl $240
80105c73:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105c78:	e9 09 f2 ff ff       	jmp    80104e86 <alltraps>

80105c7d <vector241>:
.globl vector241
vector241:
  pushl $0
80105c7d:	6a 00                	push   $0x0
  pushl $241
80105c7f:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105c84:	e9 fd f1 ff ff       	jmp    80104e86 <alltraps>

80105c89 <vector242>:
.globl vector242
vector242:
  pushl $0
80105c89:	6a 00                	push   $0x0
  pushl $242
80105c8b:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105c90:	e9 f1 f1 ff ff       	jmp    80104e86 <alltraps>

80105c95 <vector243>:
.globl vector243
vector243:
  pushl $0
80105c95:	6a 00                	push   $0x0
  pushl $243
80105c97:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105c9c:	e9 e5 f1 ff ff       	jmp    80104e86 <alltraps>

80105ca1 <vector244>:
.globl vector244
vector244:
  pushl $0
80105ca1:	6a 00                	push   $0x0
  pushl $244
80105ca3:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105ca8:	e9 d9 f1 ff ff       	jmp    80104e86 <alltraps>

80105cad <vector245>:
.globl vector245
vector245:
  pushl $0
80105cad:	6a 00                	push   $0x0
  pushl $245
80105caf:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105cb4:	e9 cd f1 ff ff       	jmp    80104e86 <alltraps>

80105cb9 <vector246>:
.globl vector246
vector246:
  pushl $0
80105cb9:	6a 00                	push   $0x0
  pushl $246
80105cbb:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105cc0:	e9 c1 f1 ff ff       	jmp    80104e86 <alltraps>

80105cc5 <vector247>:
.globl vector247
vector247:
  pushl $0
80105cc5:	6a 00                	push   $0x0
  pushl $247
80105cc7:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105ccc:	e9 b5 f1 ff ff       	jmp    80104e86 <alltraps>

80105cd1 <vector248>:
.globl vector248
vector248:
  pushl $0
80105cd1:	6a 00                	push   $0x0
  pushl $248
80105cd3:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105cd8:	e9 a9 f1 ff ff       	jmp    80104e86 <alltraps>

80105cdd <vector249>:
.globl vector249
vector249:
  pushl $0
80105cdd:	6a 00                	push   $0x0
  pushl $249
80105cdf:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105ce4:	e9 9d f1 ff ff       	jmp    80104e86 <alltraps>

80105ce9 <vector250>:
.globl vector250
vector250:
  pushl $0
80105ce9:	6a 00                	push   $0x0
  pushl $250
80105ceb:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105cf0:	e9 91 f1 ff ff       	jmp    80104e86 <alltraps>

80105cf5 <vector251>:
.globl vector251
vector251:
  pushl $0
80105cf5:	6a 00                	push   $0x0
  pushl $251
80105cf7:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105cfc:	e9 85 f1 ff ff       	jmp    80104e86 <alltraps>

80105d01 <vector252>:
.globl vector252
vector252:
  pushl $0
80105d01:	6a 00                	push   $0x0
  pushl $252
80105d03:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105d08:	e9 79 f1 ff ff       	jmp    80104e86 <alltraps>

80105d0d <vector253>:
.globl vector253
vector253:
  pushl $0
80105d0d:	6a 00                	push   $0x0
  pushl $253
80105d0f:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105d14:	e9 6d f1 ff ff       	jmp    80104e86 <alltraps>

80105d19 <vector254>:
.globl vector254
vector254:
  pushl $0
80105d19:	6a 00                	push   $0x0
  pushl $254
80105d1b:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105d20:	e9 61 f1 ff ff       	jmp    80104e86 <alltraps>

80105d25 <vector255>:
.globl vector255
vector255:
  pushl $0
80105d25:	6a 00                	push   $0x0
  pushl $255
80105d27:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105d2c:	e9 55 f1 ff ff       	jmp    80104e86 <alltraps>

80105d31 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105d31:	55                   	push   %ebp
80105d32:	89 e5                	mov    %esp,%ebp
80105d34:	57                   	push   %edi
80105d35:	56                   	push   %esi
80105d36:	53                   	push   %ebx
80105d37:	83 ec 0c             	sub    $0xc,%esp
80105d3a:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105d3c:	c1 ea 16             	shr    $0x16,%edx
80105d3f:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105d42:	8b 1f                	mov    (%edi),%ebx
80105d44:	f6 c3 01             	test   $0x1,%bl
80105d47:	74 22                	je     80105d6b <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105d49:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105d4f:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105d55:	c1 ee 0c             	shr    $0xc,%esi
80105d58:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105d5e:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105d61:	89 d8                	mov    %ebx,%eax
80105d63:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105d66:	5b                   	pop    %ebx
80105d67:	5e                   	pop    %esi
80105d68:	5f                   	pop    %edi
80105d69:	5d                   	pop    %ebp
80105d6a:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc2(-2)) == 0)
80105d6b:	85 c9                	test   %ecx,%ecx
80105d6d:	74 33                	je     80105da2 <walkpgdir+0x71>
80105d6f:	83 ec 0c             	sub    $0xc,%esp
80105d72:	6a fe                	push   $0xfffffffe
80105d74:	e8 e7 c3 ff ff       	call   80102160 <kalloc2>
80105d79:	89 c3                	mov    %eax,%ebx
80105d7b:	83 c4 10             	add    $0x10,%esp
80105d7e:	85 c0                	test   %eax,%eax
80105d80:	74 df                	je     80105d61 <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105d82:	83 ec 04             	sub    $0x4,%esp
80105d85:	68 00 10 00 00       	push   $0x1000
80105d8a:	6a 00                	push   $0x0
80105d8c:	50                   	push   %eax
80105d8d:	e8 f6 df ff ff       	call   80103d88 <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105d92:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105d98:	83 c8 07             	or     $0x7,%eax
80105d9b:	89 07                	mov    %eax,(%edi)
80105d9d:	83 c4 10             	add    $0x10,%esp
80105da0:	eb b3                	jmp    80105d55 <walkpgdir+0x24>
      return 0;
80105da2:	bb 00 00 00 00       	mov    $0x0,%ebx
80105da7:	eb b8                	jmp    80105d61 <walkpgdir+0x30>

80105da9 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105da9:	55                   	push   %ebp
80105daa:	89 e5                	mov    %esp,%ebp
80105dac:	57                   	push   %edi
80105dad:	56                   	push   %esi
80105dae:	53                   	push   %ebx
80105daf:	83 ec 1c             	sub    $0x1c,%esp
80105db2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105db5:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105db8:	89 d3                	mov    %edx,%ebx
80105dba:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105dc0:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105dc4:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105dca:	b9 01 00 00 00       	mov    $0x1,%ecx
80105dcf:	89 da                	mov    %ebx,%edx
80105dd1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105dd4:	e8 58 ff ff ff       	call   80105d31 <walkpgdir>
80105dd9:	85 c0                	test   %eax,%eax
80105ddb:	74 2e                	je     80105e0b <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105ddd:	f6 00 01             	testb  $0x1,(%eax)
80105de0:	75 1c                	jne    80105dfe <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105de2:	89 f2                	mov    %esi,%edx
80105de4:	0b 55 0c             	or     0xc(%ebp),%edx
80105de7:	83 ca 01             	or     $0x1,%edx
80105dea:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105dec:	39 fb                	cmp    %edi,%ebx
80105dee:	74 28                	je     80105e18 <mappages+0x6f>
      break;
    a += PGSIZE;
80105df0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105df6:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105dfc:	eb cc                	jmp    80105dca <mappages+0x21>
      panic("remap");
80105dfe:	83 ec 0c             	sub    $0xc,%esp
80105e01:	68 cc 6e 10 80       	push   $0x80106ecc
80105e06:	e8 3d a5 ff ff       	call   80100348 <panic>
      return -1;
80105e0b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105e10:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105e13:	5b                   	pop    %ebx
80105e14:	5e                   	pop    %esi
80105e15:	5f                   	pop    %edi
80105e16:	5d                   	pop    %ebp
80105e17:	c3                   	ret    
  return 0;
80105e18:	b8 00 00 00 00       	mov    $0x0,%eax
80105e1d:	eb f1                	jmp    80105e10 <mappages+0x67>

80105e1f <seginit>:
{
80105e1f:	55                   	push   %ebp
80105e20:	89 e5                	mov    %esp,%ebp
80105e22:	53                   	push   %ebx
80105e23:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105e26:	e8 f7 d4 ff ff       	call   80103322 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105e2b:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105e31:	66 c7 80 78 18 13 80 	movw   $0xffff,-0x7fece788(%eax)
80105e38:	ff ff 
80105e3a:	66 c7 80 7a 18 13 80 	movw   $0x0,-0x7fece786(%eax)
80105e41:	00 00 
80105e43:	c6 80 7c 18 13 80 00 	movb   $0x0,-0x7fece784(%eax)
80105e4a:	0f b6 88 7d 18 13 80 	movzbl -0x7fece783(%eax),%ecx
80105e51:	83 e1 f0             	and    $0xfffffff0,%ecx
80105e54:	83 c9 1a             	or     $0x1a,%ecx
80105e57:	83 e1 9f             	and    $0xffffff9f,%ecx
80105e5a:	83 c9 80             	or     $0xffffff80,%ecx
80105e5d:	88 88 7d 18 13 80    	mov    %cl,-0x7fece783(%eax)
80105e63:	0f b6 88 7e 18 13 80 	movzbl -0x7fece782(%eax),%ecx
80105e6a:	83 c9 0f             	or     $0xf,%ecx
80105e6d:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e70:	83 c9 c0             	or     $0xffffffc0,%ecx
80105e73:	88 88 7e 18 13 80    	mov    %cl,-0x7fece782(%eax)
80105e79:	c6 80 7f 18 13 80 00 	movb   $0x0,-0x7fece781(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105e80:	66 c7 80 80 18 13 80 	movw   $0xffff,-0x7fece780(%eax)
80105e87:	ff ff 
80105e89:	66 c7 80 82 18 13 80 	movw   $0x0,-0x7fece77e(%eax)
80105e90:	00 00 
80105e92:	c6 80 84 18 13 80 00 	movb   $0x0,-0x7fece77c(%eax)
80105e99:	0f b6 88 85 18 13 80 	movzbl -0x7fece77b(%eax),%ecx
80105ea0:	83 e1 f0             	and    $0xfffffff0,%ecx
80105ea3:	83 c9 12             	or     $0x12,%ecx
80105ea6:	83 e1 9f             	and    $0xffffff9f,%ecx
80105ea9:	83 c9 80             	or     $0xffffff80,%ecx
80105eac:	88 88 85 18 13 80    	mov    %cl,-0x7fece77b(%eax)
80105eb2:	0f b6 88 86 18 13 80 	movzbl -0x7fece77a(%eax),%ecx
80105eb9:	83 c9 0f             	or     $0xf,%ecx
80105ebc:	83 e1 cf             	and    $0xffffffcf,%ecx
80105ebf:	83 c9 c0             	or     $0xffffffc0,%ecx
80105ec2:	88 88 86 18 13 80    	mov    %cl,-0x7fece77a(%eax)
80105ec8:	c6 80 87 18 13 80 00 	movb   $0x0,-0x7fece779(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80105ecf:	66 c7 80 88 18 13 80 	movw   $0xffff,-0x7fece778(%eax)
80105ed6:	ff ff 
80105ed8:	66 c7 80 8a 18 13 80 	movw   $0x0,-0x7fece776(%eax)
80105edf:	00 00 
80105ee1:	c6 80 8c 18 13 80 00 	movb   $0x0,-0x7fece774(%eax)
80105ee8:	c6 80 8d 18 13 80 fa 	movb   $0xfa,-0x7fece773(%eax)
80105eef:	0f b6 88 8e 18 13 80 	movzbl -0x7fece772(%eax),%ecx
80105ef6:	83 c9 0f             	or     $0xf,%ecx
80105ef9:	83 e1 cf             	and    $0xffffffcf,%ecx
80105efc:	83 c9 c0             	or     $0xffffffc0,%ecx
80105eff:	88 88 8e 18 13 80    	mov    %cl,-0x7fece772(%eax)
80105f05:	c6 80 8f 18 13 80 00 	movb   $0x0,-0x7fece771(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80105f0c:	66 c7 80 90 18 13 80 	movw   $0xffff,-0x7fece770(%eax)
80105f13:	ff ff 
80105f15:	66 c7 80 92 18 13 80 	movw   $0x0,-0x7fece76e(%eax)
80105f1c:	00 00 
80105f1e:	c6 80 94 18 13 80 00 	movb   $0x0,-0x7fece76c(%eax)
80105f25:	c6 80 95 18 13 80 f2 	movb   $0xf2,-0x7fece76b(%eax)
80105f2c:	0f b6 88 96 18 13 80 	movzbl -0x7fece76a(%eax),%ecx
80105f33:	83 c9 0f             	or     $0xf,%ecx
80105f36:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f39:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f3c:	88 88 96 18 13 80    	mov    %cl,-0x7fece76a(%eax)
80105f42:	c6 80 97 18 13 80 00 	movb   $0x0,-0x7fece769(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80105f49:	05 70 18 13 80       	add    $0x80131870,%eax
  pd[0] = size-1;
80105f4e:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80105f54:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80105f58:	c1 e8 10             	shr    $0x10,%eax
80105f5b:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80105f5f:	8d 45 f2             	lea    -0xe(%ebp),%eax
80105f62:	0f 01 10             	lgdtl  (%eax)
}
80105f65:	83 c4 14             	add    $0x14,%esp
80105f68:	5b                   	pop    %ebx
80105f69:	5d                   	pop    %ebp
80105f6a:	c3                   	ret    

80105f6b <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80105f6b:	55                   	push   %ebp
80105f6c:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80105f6e:	a1 24 45 13 80       	mov    0x80134524,%eax
80105f73:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80105f78:	0f 22 d8             	mov    %eax,%cr3
}
80105f7b:	5d                   	pop    %ebp
80105f7c:	c3                   	ret    

80105f7d <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80105f7d:	55                   	push   %ebp
80105f7e:	89 e5                	mov    %esp,%ebp
80105f80:	57                   	push   %edi
80105f81:	56                   	push   %esi
80105f82:	53                   	push   %ebx
80105f83:	83 ec 1c             	sub    $0x1c,%esp
80105f86:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
80105f89:	85 f6                	test   %esi,%esi
80105f8b:	0f 84 dd 00 00 00    	je     8010606e <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
80105f91:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
80105f95:	0f 84 e0 00 00 00    	je     8010607b <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
80105f9b:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
80105f9f:	0f 84 e3 00 00 00    	je     80106088 <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
80105fa5:	e8 55 dc ff ff       	call   80103bff <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80105faa:	e8 17 d3 ff ff       	call   801032c6 <mycpu>
80105faf:	89 c3                	mov    %eax,%ebx
80105fb1:	e8 10 d3 ff ff       	call   801032c6 <mycpu>
80105fb6:	8d 78 08             	lea    0x8(%eax),%edi
80105fb9:	e8 08 d3 ff ff       	call   801032c6 <mycpu>
80105fbe:	83 c0 08             	add    $0x8,%eax
80105fc1:	c1 e8 10             	shr    $0x10,%eax
80105fc4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105fc7:	e8 fa d2 ff ff       	call   801032c6 <mycpu>
80105fcc:	83 c0 08             	add    $0x8,%eax
80105fcf:	c1 e8 18             	shr    $0x18,%eax
80105fd2:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80105fd9:	67 00 
80105fdb:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80105fe2:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
80105fe6:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80105fec:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80105ff3:	83 e2 f0             	and    $0xfffffff0,%edx
80105ff6:	83 ca 19             	or     $0x19,%edx
80105ff9:	83 e2 9f             	and    $0xffffff9f,%edx
80105ffc:	83 ca 80             	or     $0xffffff80,%edx
80105fff:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80106005:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
8010600c:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80106012:	e8 af d2 ff ff       	call   801032c6 <mycpu>
80106017:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010601e:	83 e2 ef             	and    $0xffffffef,%edx
80106021:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80106027:	e8 9a d2 ff ff       	call   801032c6 <mycpu>
8010602c:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80106032:	8b 5e 08             	mov    0x8(%esi),%ebx
80106035:	e8 8c d2 ff ff       	call   801032c6 <mycpu>
8010603a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106040:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
80106043:	e8 7e d2 ff ff       	call   801032c6 <mycpu>
80106048:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
8010604e:	b8 28 00 00 00       	mov    $0x28,%eax
80106053:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
80106056:	8b 46 04             	mov    0x4(%esi),%eax
80106059:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010605e:	0f 22 d8             	mov    %eax,%cr3
  popcli();
80106061:	e8 d6 db ff ff       	call   80103c3c <popcli>
}
80106066:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106069:	5b                   	pop    %ebx
8010606a:	5e                   	pop    %esi
8010606b:	5f                   	pop    %edi
8010606c:	5d                   	pop    %ebp
8010606d:	c3                   	ret    
    panic("switchuvm: no process");
8010606e:	83 ec 0c             	sub    $0xc,%esp
80106071:	68 d2 6e 10 80       	push   $0x80106ed2
80106076:	e8 cd a2 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
8010607b:	83 ec 0c             	sub    $0xc,%esp
8010607e:	68 e8 6e 10 80       	push   $0x80106ee8
80106083:	e8 c0 a2 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
80106088:	83 ec 0c             	sub    $0xc,%esp
8010608b:	68 fd 6e 10 80       	push   $0x80106efd
80106090:	e8 b3 a2 ff ff       	call   80100348 <panic>

80106095 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80106095:	55                   	push   %ebp
80106096:	89 e5                	mov    %esp,%ebp
80106098:	56                   	push   %esi
80106099:	53                   	push   %ebx
8010609a:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
8010609d:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801060a3:	77 51                	ja     801060f6 <inituvm+0x61>
    panic("inituvm: more than a page");
  mem = kalloc2(-2);
801060a5:	83 ec 0c             	sub    $0xc,%esp
801060a8:	6a fe                	push   $0xfffffffe
801060aa:	e8 b1 c0 ff ff       	call   80102160 <kalloc2>
801060af:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
801060b1:	83 c4 0c             	add    $0xc,%esp
801060b4:	68 00 10 00 00       	push   $0x1000
801060b9:	6a 00                	push   $0x0
801060bb:	50                   	push   %eax
801060bc:	e8 c7 dc ff ff       	call   80103d88 <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
801060c1:	83 c4 08             	add    $0x8,%esp
801060c4:	6a 06                	push   $0x6
801060c6:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801060cc:	50                   	push   %eax
801060cd:	b9 00 10 00 00       	mov    $0x1000,%ecx
801060d2:	ba 00 00 00 00       	mov    $0x0,%edx
801060d7:	8b 45 08             	mov    0x8(%ebp),%eax
801060da:	e8 ca fc ff ff       	call   80105da9 <mappages>
  memmove(mem, init, sz);
801060df:	83 c4 0c             	add    $0xc,%esp
801060e2:	56                   	push   %esi
801060e3:	ff 75 0c             	pushl  0xc(%ebp)
801060e6:	53                   	push   %ebx
801060e7:	e8 17 dd ff ff       	call   80103e03 <memmove>
}
801060ec:	83 c4 10             	add    $0x10,%esp
801060ef:	8d 65 f8             	lea    -0x8(%ebp),%esp
801060f2:	5b                   	pop    %ebx
801060f3:	5e                   	pop    %esi
801060f4:	5d                   	pop    %ebp
801060f5:	c3                   	ret    
    panic("inituvm: more than a page");
801060f6:	83 ec 0c             	sub    $0xc,%esp
801060f9:	68 11 6f 10 80       	push   $0x80106f11
801060fe:	e8 45 a2 ff ff       	call   80100348 <panic>

80106103 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80106103:	55                   	push   %ebp
80106104:	89 e5                	mov    %esp,%ebp
80106106:	57                   	push   %edi
80106107:	56                   	push   %esi
80106108:	53                   	push   %ebx
80106109:	83 ec 0c             	sub    $0xc,%esp
8010610c:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
8010610f:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
80106116:	75 07                	jne    8010611f <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80106118:	bb 00 00 00 00       	mov    $0x0,%ebx
8010611d:	eb 3c                	jmp    8010615b <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
8010611f:	83 ec 0c             	sub    $0xc,%esp
80106122:	68 cc 6f 10 80       	push   $0x80106fcc
80106127:	e8 1c a2 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
8010612c:	83 ec 0c             	sub    $0xc,%esp
8010612f:	68 2b 6f 10 80       	push   $0x80106f2b
80106134:	e8 0f a2 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
80106139:	05 00 00 00 80       	add    $0x80000000,%eax
8010613e:	56                   	push   %esi
8010613f:	89 da                	mov    %ebx,%edx
80106141:	03 55 14             	add    0x14(%ebp),%edx
80106144:	52                   	push   %edx
80106145:	50                   	push   %eax
80106146:	ff 75 10             	pushl  0x10(%ebp)
80106149:	e8 25 b6 ff ff       	call   80101773 <readi>
8010614e:	83 c4 10             	add    $0x10,%esp
80106151:	39 f0                	cmp    %esi,%eax
80106153:	75 47                	jne    8010619c <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
80106155:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010615b:	39 fb                	cmp    %edi,%ebx
8010615d:	73 30                	jae    8010618f <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
8010615f:	89 da                	mov    %ebx,%edx
80106161:	03 55 0c             	add    0xc(%ebp),%edx
80106164:	b9 00 00 00 00       	mov    $0x0,%ecx
80106169:	8b 45 08             	mov    0x8(%ebp),%eax
8010616c:	e8 c0 fb ff ff       	call   80105d31 <walkpgdir>
80106171:	85 c0                	test   %eax,%eax
80106173:	74 b7                	je     8010612c <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
80106175:	8b 00                	mov    (%eax),%eax
80106177:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
8010617c:	89 fe                	mov    %edi,%esi
8010617e:	29 de                	sub    %ebx,%esi
80106180:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106186:	76 b1                	jbe    80106139 <loaduvm+0x36>
      n = PGSIZE;
80106188:	be 00 10 00 00       	mov    $0x1000,%esi
8010618d:	eb aa                	jmp    80106139 <loaduvm+0x36>
      return -1;
  }
  return 0;
8010618f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106194:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106197:	5b                   	pop    %ebx
80106198:	5e                   	pop    %esi
80106199:	5f                   	pop    %edi
8010619a:	5d                   	pop    %ebp
8010619b:	c3                   	ret    
      return -1;
8010619c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061a1:	eb f1                	jmp    80106194 <loaduvm+0x91>

801061a3 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801061a3:	55                   	push   %ebp
801061a4:	89 e5                	mov    %esp,%ebp
801061a6:	57                   	push   %edi
801061a7:	56                   	push   %esi
801061a8:	53                   	push   %ebx
801061a9:	83 ec 0c             	sub    $0xc,%esp
801061ac:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801061af:	39 7d 10             	cmp    %edi,0x10(%ebp)
801061b2:	73 11                	jae    801061c5 <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
801061b4:	8b 45 10             	mov    0x10(%ebp),%eax
801061b7:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801061bd:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801061c3:	eb 19                	jmp    801061de <deallocuvm+0x3b>
    return oldsz;
801061c5:	89 f8                	mov    %edi,%eax
801061c7:	eb 64                	jmp    8010622d <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
801061c9:	c1 eb 16             	shr    $0x16,%ebx
801061cc:	83 c3 01             	add    $0x1,%ebx
801061cf:	c1 e3 16             	shl    $0x16,%ebx
801061d2:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801061d8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801061de:	39 fb                	cmp    %edi,%ebx
801061e0:	73 48                	jae    8010622a <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
801061e2:	b9 00 00 00 00       	mov    $0x0,%ecx
801061e7:	89 da                	mov    %ebx,%edx
801061e9:	8b 45 08             	mov    0x8(%ebp),%eax
801061ec:	e8 40 fb ff ff       	call   80105d31 <walkpgdir>
801061f1:	89 c6                	mov    %eax,%esi
    if(!pte)
801061f3:	85 c0                	test   %eax,%eax
801061f5:	74 d2                	je     801061c9 <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
801061f7:	8b 00                	mov    (%eax),%eax
801061f9:	a8 01                	test   $0x1,%al
801061fb:	74 db                	je     801061d8 <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
801061fd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106202:	74 19                	je     8010621d <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
80106204:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106209:	83 ec 0c             	sub    $0xc,%esp
8010620c:	50                   	push   %eax
8010620d:	e8 92 bd ff ff       	call   80101fa4 <kfree>
      *pte = 0;
80106212:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80106218:	83 c4 10             	add    $0x10,%esp
8010621b:	eb bb                	jmp    801061d8 <deallocuvm+0x35>
        panic("kfree");
8010621d:	83 ec 0c             	sub    $0xc,%esp
80106220:	68 66 68 10 80       	push   $0x80106866
80106225:	e8 1e a1 ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
8010622a:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010622d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106230:	5b                   	pop    %ebx
80106231:	5e                   	pop    %esi
80106232:	5f                   	pop    %edi
80106233:	5d                   	pop    %ebp
80106234:	c3                   	ret    

80106235 <allocuvm>:
{
80106235:	55                   	push   %ebp
80106236:	89 e5                	mov    %esp,%ebp
80106238:	57                   	push   %edi
80106239:	56                   	push   %esi
8010623a:	53                   	push   %ebx
8010623b:	83 ec 1c             	sub    $0x1c,%esp
8010623e:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
80106241:	89 7d e4             	mov    %edi,-0x1c(%ebp)
80106244:	85 ff                	test   %edi,%edi
80106246:	0f 88 cf 00 00 00    	js     8010631b <allocuvm+0xe6>
  if(newsz < oldsz)
8010624c:	3b 7d 0c             	cmp    0xc(%ebp),%edi
8010624f:	72 6a                	jb     801062bb <allocuvm+0x86>
  a = PGROUNDUP(oldsz);
80106251:	8b 45 0c             	mov    0xc(%ebp),%eax
80106254:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
8010625a:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
80106260:	39 fb                	cmp    %edi,%ebx
80106262:	0f 83 ba 00 00 00    	jae    80106322 <allocuvm+0xed>
    mem = kalloc2(myproc()->pid);
80106268:	e8 d0 d0 ff ff       	call   8010333d <myproc>
8010626d:	83 ec 0c             	sub    $0xc,%esp
80106270:	ff 70 10             	pushl  0x10(%eax)
80106273:	e8 e8 be ff ff       	call   80102160 <kalloc2>
80106278:	89 c6                	mov    %eax,%esi
    if(mem == 0){
8010627a:	83 c4 10             	add    $0x10,%esp
8010627d:	85 c0                	test   %eax,%eax
8010627f:	74 42                	je     801062c3 <allocuvm+0x8e>
    memset(mem, 0, PGSIZE);
80106281:	83 ec 04             	sub    $0x4,%esp
80106284:	68 00 10 00 00       	push   $0x1000
80106289:	6a 00                	push   $0x0
8010628b:	50                   	push   %eax
8010628c:	e8 f7 da ff ff       	call   80103d88 <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
80106291:	83 c4 08             	add    $0x8,%esp
80106294:	6a 06                	push   $0x6
80106296:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
8010629c:	50                   	push   %eax
8010629d:	b9 00 10 00 00       	mov    $0x1000,%ecx
801062a2:	89 da                	mov    %ebx,%edx
801062a4:	8b 45 08             	mov    0x8(%ebp),%eax
801062a7:	e8 fd fa ff ff       	call   80105da9 <mappages>
801062ac:	83 c4 10             	add    $0x10,%esp
801062af:	85 c0                	test   %eax,%eax
801062b1:	78 38                	js     801062eb <allocuvm+0xb6>
  for(; a < newsz; a += PGSIZE){
801062b3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801062b9:	eb a5                	jmp    80106260 <allocuvm+0x2b>
    return oldsz;
801062bb:	8b 45 0c             	mov    0xc(%ebp),%eax
801062be:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801062c1:	eb 5f                	jmp    80106322 <allocuvm+0xed>
      cprintf("allocuvm out of memory\n");
801062c3:	83 ec 0c             	sub    $0xc,%esp
801062c6:	68 49 6f 10 80       	push   $0x80106f49
801062cb:	e8 3b a3 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801062d0:	83 c4 0c             	add    $0xc,%esp
801062d3:	ff 75 0c             	pushl  0xc(%ebp)
801062d6:	57                   	push   %edi
801062d7:	ff 75 08             	pushl  0x8(%ebp)
801062da:	e8 c4 fe ff ff       	call   801061a3 <deallocuvm>
      return 0;
801062df:	83 c4 10             	add    $0x10,%esp
801062e2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801062e9:	eb 37                	jmp    80106322 <allocuvm+0xed>
      cprintf("allocuvm out of memory (2)\n");
801062eb:	83 ec 0c             	sub    $0xc,%esp
801062ee:	68 61 6f 10 80       	push   $0x80106f61
801062f3:	e8 13 a3 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801062f8:	83 c4 0c             	add    $0xc,%esp
801062fb:	ff 75 0c             	pushl  0xc(%ebp)
801062fe:	57                   	push   %edi
801062ff:	ff 75 08             	pushl  0x8(%ebp)
80106302:	e8 9c fe ff ff       	call   801061a3 <deallocuvm>
      kfree(mem);
80106307:	89 34 24             	mov    %esi,(%esp)
8010630a:	e8 95 bc ff ff       	call   80101fa4 <kfree>
      return 0;
8010630f:	83 c4 10             	add    $0x10,%esp
80106312:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106319:	eb 07                	jmp    80106322 <allocuvm+0xed>
    return 0;
8010631b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
80106322:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106325:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106328:	5b                   	pop    %ebx
80106329:	5e                   	pop    %esi
8010632a:	5f                   	pop    %edi
8010632b:	5d                   	pop    %ebp
8010632c:	c3                   	ret    

8010632d <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
8010632d:	55                   	push   %ebp
8010632e:	89 e5                	mov    %esp,%ebp
80106330:	56                   	push   %esi
80106331:	53                   	push   %ebx
80106332:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
80106335:	85 f6                	test   %esi,%esi
80106337:	74 1a                	je     80106353 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
80106339:	83 ec 04             	sub    $0x4,%esp
8010633c:	6a 00                	push   $0x0
8010633e:	68 00 00 00 80       	push   $0x80000000
80106343:	56                   	push   %esi
80106344:	e8 5a fe ff ff       	call   801061a3 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80106349:	83 c4 10             	add    $0x10,%esp
8010634c:	bb 00 00 00 00       	mov    $0x0,%ebx
80106351:	eb 10                	jmp    80106363 <freevm+0x36>
    panic("freevm: no pgdir");
80106353:	83 ec 0c             	sub    $0xc,%esp
80106356:	68 7d 6f 10 80       	push   $0x80106f7d
8010635b:	e8 e8 9f ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
80106360:	83 c3 01             	add    $0x1,%ebx
80106363:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
80106369:	77 1f                	ja     8010638a <freevm+0x5d>
    if(pgdir[i] & PTE_P){
8010636b:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
8010636e:	a8 01                	test   $0x1,%al
80106370:	74 ee                	je     80106360 <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
80106372:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106377:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
8010637c:	83 ec 0c             	sub    $0xc,%esp
8010637f:	50                   	push   %eax
80106380:	e8 1f bc ff ff       	call   80101fa4 <kfree>
80106385:	83 c4 10             	add    $0x10,%esp
80106388:	eb d6                	jmp    80106360 <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
8010638a:	83 ec 0c             	sub    $0xc,%esp
8010638d:	56                   	push   %esi
8010638e:	e8 11 bc ff ff       	call   80101fa4 <kfree>
}
80106393:	83 c4 10             	add    $0x10,%esp
80106396:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106399:	5b                   	pop    %ebx
8010639a:	5e                   	pop    %esi
8010639b:	5d                   	pop    %ebp
8010639c:	c3                   	ret    

8010639d <setupkvm>:
{
8010639d:	55                   	push   %ebp
8010639e:	89 e5                	mov    %esp,%ebp
801063a0:	56                   	push   %esi
801063a1:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc2(-2)) == 0)
801063a2:	83 ec 0c             	sub    $0xc,%esp
801063a5:	6a fe                	push   $0xfffffffe
801063a7:	e8 b4 bd ff ff       	call   80102160 <kalloc2>
801063ac:	89 c6                	mov    %eax,%esi
801063ae:	83 c4 10             	add    $0x10,%esp
801063b1:	85 c0                	test   %eax,%eax
801063b3:	74 55                	je     8010640a <setupkvm+0x6d>
  memset(pgdir, 0, PGSIZE);
801063b5:	83 ec 04             	sub    $0x4,%esp
801063b8:	68 00 10 00 00       	push   $0x1000
801063bd:	6a 00                	push   $0x0
801063bf:	50                   	push   %eax
801063c0:	e8 c3 d9 ff ff       	call   80103d88 <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801063c5:	83 c4 10             	add    $0x10,%esp
801063c8:	bb 20 94 10 80       	mov    $0x80109420,%ebx
801063cd:	81 fb 60 94 10 80    	cmp    $0x80109460,%ebx
801063d3:	73 35                	jae    8010640a <setupkvm+0x6d>
                (uint)k->phys_start, k->perm) < 0) {
801063d5:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
801063d8:	8b 4b 08             	mov    0x8(%ebx),%ecx
801063db:	29 c1                	sub    %eax,%ecx
801063dd:	83 ec 08             	sub    $0x8,%esp
801063e0:	ff 73 0c             	pushl  0xc(%ebx)
801063e3:	50                   	push   %eax
801063e4:	8b 13                	mov    (%ebx),%edx
801063e6:	89 f0                	mov    %esi,%eax
801063e8:	e8 bc f9 ff ff       	call   80105da9 <mappages>
801063ed:	83 c4 10             	add    $0x10,%esp
801063f0:	85 c0                	test   %eax,%eax
801063f2:	78 05                	js     801063f9 <setupkvm+0x5c>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801063f4:	83 c3 10             	add    $0x10,%ebx
801063f7:	eb d4                	jmp    801063cd <setupkvm+0x30>
      freevm(pgdir);
801063f9:	83 ec 0c             	sub    $0xc,%esp
801063fc:	56                   	push   %esi
801063fd:	e8 2b ff ff ff       	call   8010632d <freevm>
      return 0;
80106402:	83 c4 10             	add    $0x10,%esp
80106405:	be 00 00 00 00       	mov    $0x0,%esi
}
8010640a:	89 f0                	mov    %esi,%eax
8010640c:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010640f:	5b                   	pop    %ebx
80106410:	5e                   	pop    %esi
80106411:	5d                   	pop    %ebp
80106412:	c3                   	ret    

80106413 <kvmalloc>:
{
80106413:	55                   	push   %ebp
80106414:	89 e5                	mov    %esp,%ebp
80106416:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80106419:	e8 7f ff ff ff       	call   8010639d <setupkvm>
8010641e:	a3 24 45 13 80       	mov    %eax,0x80134524
  switchkvm();
80106423:	e8 43 fb ff ff       	call   80105f6b <switchkvm>
}
80106428:	c9                   	leave  
80106429:	c3                   	ret    

8010642a <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
8010642a:	55                   	push   %ebp
8010642b:	89 e5                	mov    %esp,%ebp
8010642d:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106430:	b9 00 00 00 00       	mov    $0x0,%ecx
80106435:	8b 55 0c             	mov    0xc(%ebp),%edx
80106438:	8b 45 08             	mov    0x8(%ebp),%eax
8010643b:	e8 f1 f8 ff ff       	call   80105d31 <walkpgdir>
  if(pte == 0)
80106440:	85 c0                	test   %eax,%eax
80106442:	74 05                	je     80106449 <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
80106444:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
80106447:	c9                   	leave  
80106448:	c3                   	ret    
    panic("clearpteu");
80106449:	83 ec 0c             	sub    $0xc,%esp
8010644c:	68 8e 6f 10 80       	push   $0x80106f8e
80106451:	e8 f2 9e ff ff       	call   80100348 <panic>

80106456 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80106456:	55                   	push   %ebp
80106457:	89 e5                	mov    %esp,%ebp
80106459:	57                   	push   %edi
8010645a:	56                   	push   %esi
8010645b:	53                   	push   %ebx
8010645c:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
8010645f:	e8 39 ff ff ff       	call   8010639d <setupkvm>
80106464:	89 45 dc             	mov    %eax,-0x24(%ebp)
80106467:	85 c0                	test   %eax,%eax
80106469:	0f 84 c4 00 00 00    	je     80106533 <copyuvm+0xdd>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
8010646f:	bf 00 00 00 00       	mov    $0x0,%edi
80106474:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106477:	0f 83 b6 00 00 00    	jae    80106533 <copyuvm+0xdd>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
8010647d:	89 7d e4             	mov    %edi,-0x1c(%ebp)
80106480:	b9 00 00 00 00       	mov    $0x0,%ecx
80106485:	89 fa                	mov    %edi,%edx
80106487:	8b 45 08             	mov    0x8(%ebp),%eax
8010648a:	e8 a2 f8 ff ff       	call   80105d31 <walkpgdir>
8010648f:	85 c0                	test   %eax,%eax
80106491:	74 65                	je     801064f8 <copyuvm+0xa2>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
80106493:	8b 00                	mov    (%eax),%eax
80106495:	a8 01                	test   $0x1,%al
80106497:	74 6c                	je     80106505 <copyuvm+0xaf>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
80106499:	89 c6                	mov    %eax,%esi
8010649b:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
801064a1:	25 ff 0f 00 00       	and    $0xfff,%eax
801064a6:	89 45 e0             	mov    %eax,-0x20(%ebp)
    if((mem = kalloc()) == 0)
801064a9:	e8 1a bc ff ff       	call   801020c8 <kalloc>
801064ae:	89 c3                	mov    %eax,%ebx
801064b0:	85 c0                	test   %eax,%eax
801064b2:	74 6a                	je     8010651e <copyuvm+0xc8>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
801064b4:	81 c6 00 00 00 80    	add    $0x80000000,%esi
801064ba:	83 ec 04             	sub    $0x4,%esp
801064bd:	68 00 10 00 00       	push   $0x1000
801064c2:	56                   	push   %esi
801064c3:	50                   	push   %eax
801064c4:	e8 3a d9 ff ff       	call   80103e03 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
801064c9:	83 c4 08             	add    $0x8,%esp
801064cc:	ff 75 e0             	pushl  -0x20(%ebp)
801064cf:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801064d5:	50                   	push   %eax
801064d6:	b9 00 10 00 00       	mov    $0x1000,%ecx
801064db:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801064de:	8b 45 dc             	mov    -0x24(%ebp),%eax
801064e1:	e8 c3 f8 ff ff       	call   80105da9 <mappages>
801064e6:	83 c4 10             	add    $0x10,%esp
801064e9:	85 c0                	test   %eax,%eax
801064eb:	78 25                	js     80106512 <copyuvm+0xbc>
  for(i = 0; i < sz; i += PGSIZE){
801064ed:	81 c7 00 10 00 00    	add    $0x1000,%edi
801064f3:	e9 7c ff ff ff       	jmp    80106474 <copyuvm+0x1e>
      panic("copyuvm: pte should exist");
801064f8:	83 ec 0c             	sub    $0xc,%esp
801064fb:	68 98 6f 10 80       	push   $0x80106f98
80106500:	e8 43 9e ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
80106505:	83 ec 0c             	sub    $0xc,%esp
80106508:	68 b2 6f 10 80       	push   $0x80106fb2
8010650d:	e8 36 9e ff ff       	call   80100348 <panic>
      kfree(mem);
80106512:	83 ec 0c             	sub    $0xc,%esp
80106515:	53                   	push   %ebx
80106516:	e8 89 ba ff ff       	call   80101fa4 <kfree>
      goto bad;
8010651b:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
8010651e:	83 ec 0c             	sub    $0xc,%esp
80106521:	ff 75 dc             	pushl  -0x24(%ebp)
80106524:	e8 04 fe ff ff       	call   8010632d <freevm>
  return 0;
80106529:	83 c4 10             	add    $0x10,%esp
8010652c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
80106533:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106536:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106539:	5b                   	pop    %ebx
8010653a:	5e                   	pop    %esi
8010653b:	5f                   	pop    %edi
8010653c:	5d                   	pop    %ebp
8010653d:	c3                   	ret    

8010653e <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
8010653e:	55                   	push   %ebp
8010653f:	89 e5                	mov    %esp,%ebp
80106541:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106544:	b9 00 00 00 00       	mov    $0x0,%ecx
80106549:	8b 55 0c             	mov    0xc(%ebp),%edx
8010654c:	8b 45 08             	mov    0x8(%ebp),%eax
8010654f:	e8 dd f7 ff ff       	call   80105d31 <walkpgdir>
  if((*pte & PTE_P) == 0)
80106554:	8b 00                	mov    (%eax),%eax
80106556:	a8 01                	test   $0x1,%al
80106558:	74 10                	je     8010656a <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
8010655a:	a8 04                	test   $0x4,%al
8010655c:	74 13                	je     80106571 <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
8010655e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106563:	05 00 00 00 80       	add    $0x80000000,%eax
}
80106568:	c9                   	leave  
80106569:	c3                   	ret    
    return 0;
8010656a:	b8 00 00 00 00       	mov    $0x0,%eax
8010656f:	eb f7                	jmp    80106568 <uva2ka+0x2a>
    return 0;
80106571:	b8 00 00 00 00       	mov    $0x0,%eax
80106576:	eb f0                	jmp    80106568 <uva2ka+0x2a>

80106578 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80106578:	55                   	push   %ebp
80106579:	89 e5                	mov    %esp,%ebp
8010657b:	57                   	push   %edi
8010657c:	56                   	push   %esi
8010657d:	53                   	push   %ebx
8010657e:	83 ec 0c             	sub    $0xc,%esp
80106581:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80106584:	eb 25                	jmp    801065ab <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
80106586:	8b 55 0c             	mov    0xc(%ebp),%edx
80106589:	29 f2                	sub    %esi,%edx
8010658b:	01 d0                	add    %edx,%eax
8010658d:	83 ec 04             	sub    $0x4,%esp
80106590:	53                   	push   %ebx
80106591:	ff 75 10             	pushl  0x10(%ebp)
80106594:	50                   	push   %eax
80106595:	e8 69 d8 ff ff       	call   80103e03 <memmove>
    len -= n;
8010659a:	29 df                	sub    %ebx,%edi
    buf += n;
8010659c:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
8010659f:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
801065a5:	89 45 0c             	mov    %eax,0xc(%ebp)
801065a8:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
801065ab:	85 ff                	test   %edi,%edi
801065ad:	74 2f                	je     801065de <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
801065af:	8b 75 0c             	mov    0xc(%ebp),%esi
801065b2:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
801065b8:	83 ec 08             	sub    $0x8,%esp
801065bb:	56                   	push   %esi
801065bc:	ff 75 08             	pushl  0x8(%ebp)
801065bf:	e8 7a ff ff ff       	call   8010653e <uva2ka>
    if(pa0 == 0)
801065c4:	83 c4 10             	add    $0x10,%esp
801065c7:	85 c0                	test   %eax,%eax
801065c9:	74 20                	je     801065eb <copyout+0x73>
    n = PGSIZE - (va - va0);
801065cb:	89 f3                	mov    %esi,%ebx
801065cd:	2b 5d 0c             	sub    0xc(%ebp),%ebx
801065d0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
801065d6:	39 df                	cmp    %ebx,%edi
801065d8:	73 ac                	jae    80106586 <copyout+0xe>
      n = len;
801065da:	89 fb                	mov    %edi,%ebx
801065dc:	eb a8                	jmp    80106586 <copyout+0xe>
  }
  return 0;
801065de:	b8 00 00 00 00       	mov    $0x0,%eax
}
801065e3:	8d 65 f4             	lea    -0xc(%ebp),%esp
801065e6:	5b                   	pop    %ebx
801065e7:	5e                   	pop    %esi
801065e8:	5f                   	pop    %edi
801065e9:	5d                   	pop    %ebp
801065ea:	c3                   	ret    
      return -1;
801065eb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065f0:	eb f1                	jmp    801065e3 <copyout+0x6b>
