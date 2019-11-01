
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
8010002d:	b8 f7 2a 10 80       	mov    $0x80102af7,%eax
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
80100046:	e8 dd 3b 00 00       	call   80103c28 <acquire>

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
8010007c:	e8 0c 3c 00 00       	call   80103c8d <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 88 39 00 00       	call   80103a14 <acquiresleep>
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
801000ca:	e8 be 3b 00 00       	call   80103c8d <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 3a 39 00 00       	call   80103a14 <acquiresleep>
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
801000ea:	68 20 65 10 80       	push   $0x80106520
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 31 65 10 80       	push   $0x80106531
80100100:	68 e0 a5 10 80       	push   $0x8010a5e0
80100105:	e8 e2 39 00 00       	call   80103aec <initlock>
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
8010013a:	68 38 65 10 80       	push   $0x80106538
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 99 38 00 00       	call   801039e1 <initsleeplock>
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
801001a8:	e8 f1 38 00 00       	call   80103a9e <holdingsleep>
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
801001cb:	68 3f 65 10 80       	push   $0x8010653f
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
801001e4:	e8 b5 38 00 00       	call   80103a9e <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 6a 38 00 00       	call   80103a63 <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
80100200:	e8 23 3a 00 00       	call   80103c28 <acquire>
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
8010024c:	e8 3c 3a 00 00       	call   80103c8d <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 46 65 10 80       	push   $0x80106546
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
8010028a:	e8 99 39 00 00       	call   80103c28 <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 c0 ef 10 80       	mov    0x8010efc0,%eax
8010029f:	3b 05 c4 ef 10 80    	cmp    0x8010efc4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 dd 2f 00 00       	call   80103289 <myproc>
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
801002bf:	e8 69 34 00 00       	call   8010372d <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 95 10 80       	push   $0x80109520
801002d1:	e8 b7 39 00 00       	call   80103c8d <release>
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
80100331:	e8 57 39 00 00       	call   80103c8d <release>
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
8010035a:	e8 b2 20 00 00       	call   80102411 <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 4d 65 10 80       	push   $0x8010654d
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 9b 6e 10 80 	movl   $0x80106e9b,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 73 37 00 00       	call   80103b07 <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 61 65 10 80       	push   $0x80106561
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
8010049e:	68 65 65 10 80       	push   $0x80106565
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 90 38 00 00       	call   80103d4f <memmove>
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
801004d9:	e8 f6 37 00 00       	call   80103cd4 <memset>
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
80100506:	e8 03 4c 00 00       	call   8010510e <uartputc>
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
8010051f:	e8 ea 4b 00 00       	call   8010510e <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 de 4b 00 00       	call   8010510e <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 d2 4b 00 00       	call   8010510e <uartputc>
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
80100576:	0f b6 92 90 65 10 80 	movzbl -0x7fef9a70(%edx),%edx
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
801005ca:	e8 59 36 00 00       	call   80103c28 <acquire>
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
801005f1:	e8 97 36 00 00       	call   80103c8d <release>
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
80100638:	e8 eb 35 00 00       	call   80103c28 <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 7f 65 10 80       	push   $0x8010657f
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
801006ee:	be 78 65 10 80       	mov    $0x80106578,%esi
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
80100734:	e8 54 35 00 00       	call   80103c8d <release>
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
8010074f:	e8 d4 34 00 00       	call   80103c28 <acquire>
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
801007de:	e8 af 30 00 00       	call   80103892 <wakeup>
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
80100873:	e8 15 34 00 00       	call   80103c8d <release>
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
80100887:	e8 a3 30 00 00       	call   8010392f <procdump>
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
80100894:	68 88 65 10 80       	push   $0x80106588
80100899:	68 20 95 10 80       	push   $0x80109520
8010089e:	e8 49 32 00 00       	call   80103aec <initlock>

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
801008de:	e8 a6 29 00 00       	call   80103289 <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 53 1f 00 00       	call   80102841 <begin_op>

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
80100935:	e8 81 1f 00 00       	call   801028bb <end_op>
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
8010094a:	e8 6c 1f 00 00       	call   801028bb <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 a1 65 10 80       	push   $0x801065a1
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
80100972:	e8 57 59 00 00       	call   801062ce <setupkvm>
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
80100a06:	e8 69 57 00 00       	call   80106174 <allocuvm>
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
80100a38:	e8 05 56 00 00       	call   80106042 <loaduvm>
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
80100a53:	e8 63 1e 00 00       	call   801028bb <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 fb 56 00 00       	call   80106174 <allocuvm>
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
80100a9d:	e8 bc 57 00 00       	call   8010625e <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 92 58 00 00       	call   80106353 <clearpteu>
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
80100ae2:	e8 8f 33 00 00       	call   80103e76 <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 7d 33 00 00       	call   80103e76 <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 96 59 00 00       	call   801064a1 <copyout>
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
80100b66:	e8 36 59 00 00       	call   801064a1 <copyout>
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
80100ba3:	e8 93 32 00 00       	call   80103e3b <safestrcpy>
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
80100bd1:	e8 eb 52 00 00       	call   80105ec1 <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 80 56 00 00       	call   8010625e <freevm>
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
80100c19:	68 ad 65 10 80       	push   $0x801065ad
80100c1e:	68 e0 ef 10 80       	push   $0x8010efe0
80100c23:	e8 c4 2e 00 00       	call   80103aec <initlock>
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
80100c39:	e8 ea 2f 00 00       	call   80103c28 <acquire>
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
80100c68:	e8 20 30 00 00       	call   80103c8d <release>
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
80100c7f:	e8 09 30 00 00       	call   80103c8d <release>
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
80100c9d:	e8 86 2f 00 00       	call   80103c28 <acquire>
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
80100cba:	e8 ce 2f 00 00       	call   80103c8d <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 b4 65 10 80       	push   $0x801065b4
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
80100ce2:	e8 41 2f 00 00       	call   80103c28 <acquire>
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
80100d03:	e8 85 2f 00 00       	call   80103c8d <release>
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
80100d13:	68 bc 65 10 80       	push   $0x801065bc
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
80100d49:	e8 3f 2f 00 00       	call   80103c8d <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 de 1a 00 00       	call   80102841 <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 48 1b 00 00       	call   801028bb <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 2d 21 00 00       	call   80102eb5 <pipeclose>
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
80100e3c:	e8 cc 21 00 00       	call   8010300d <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 c6 65 10 80       	push   $0x801065c6
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
80100e95:	e8 a7 20 00 00       	call   80102f41 <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 9a 19 00 00       	call   80102841 <begin_op>
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
80100edd:	e8 d9 19 00 00       	call   801028bb <end_op>

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
80100f10:	68 cf 65 10 80       	push   $0x801065cf
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
80100f2d:	68 d5 65 10 80       	push   $0x801065d5
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
80100f8a:	e8 c0 2d 00 00       	call   80103d4f <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 b0 2d 00 00       	call   80103d4f <memmove>
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
80100fdf:	e8 f0 2c 00 00       	call   80103cd4 <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 7e 19 00 00       	call   8010296a <log_write>
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
801010a3:	68 df 65 10 80       	push   $0x801065df
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
801010bf:	e8 a6 18 00 00       	call   8010296a <log_write>
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
80101170:	e8 f5 17 00 00       	call   8010296a <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 f5 65 10 80       	push   $0x801065f5
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
8010119a:	e8 89 2a 00 00       	call   80103c28 <acquire>
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
801011e1:	e8 a7 2a 00 00       	call   80103c8d <release>
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
80101217:	e8 71 2a 00 00       	call   80103c8d <release>
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
8010122c:	68 08 66 10 80       	push   $0x80106608
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
80101255:	e8 f5 2a 00 00       	call   80103d4f <memmove>
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
801012c8:	e8 9d 16 00 00       	call   8010296a <log_write>
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
801012e2:	68 18 66 10 80       	push   $0x80106618
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 2b 66 10 80       	push   $0x8010662b
801012f8:	68 00 fa 10 80       	push   $0x8010fa00
801012fd:	e8 ea 27 00 00       	call   80103aec <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 32 66 10 80       	push   $0x80106632
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 40 fa 10 80       	add    $0x8010fa40,%eax
80101321:	50                   	push   %eax
80101322:	e8 ba 26 00 00       	call   801039e1 <initsleeplock>
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
8010136c:	68 98 66 10 80       	push   $0x80106698
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
801013df:	68 38 66 10 80       	push   $0x80106638
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 de 28 00 00       	call   80103cd4 <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 65 15 00 00       	call   8010296a <log_write>
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
80101480:	e8 ca 28 00 00       	call   80103d4f <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 dd 14 00 00       	call   8010296a <log_write>
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
80101560:	e8 c3 26 00 00       	call   80103c28 <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
80101575:	e8 13 27 00 00       	call   80103c8d <release>
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
8010159a:	e8 75 24 00 00       	call   80103a14 <acquiresleep>
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
801015b2:	68 4a 66 10 80       	push   $0x8010664a
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
80101614:	e8 36 27 00 00       	call   80103d4f <memmove>
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
80101639:	68 50 66 10 80       	push   $0x80106650
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
80101656:	e8 43 24 00 00       	call   80103a9e <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 f2 23 00 00       	call   80103a63 <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 5f 66 10 80       	push   $0x8010665f
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
80101698:	e8 77 23 00 00       	call   80103a14 <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 ad 23 00 00       	call   80103a63 <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
801016bd:	e8 66 25 00 00       	call   80103c28 <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
801016d2:	e8 b6 25 00 00       	call   80103c8d <release>
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
801016ea:	e8 39 25 00 00       	call   80103c28 <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
801016f9:	e8 8f 25 00 00       	call   80103c8d <release>
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
8010182a:	e8 20 25 00 00       	call   80103d4f <memmove>
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
80101926:	e8 24 24 00 00       	call   80103d4f <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 37 10 00 00       	call   8010296a <log_write>
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
801019a9:	e8 08 24 00 00       	call   80103db6 <strncmp>
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
801019d0:	68 67 66 10 80       	push   $0x80106667
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 79 66 10 80       	push   $0x80106679
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
80101a5a:	e8 2a 18 00 00       	call   80103289 <myproc>
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
80101b92:	68 88 66 10 80       	push   $0x80106688
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 45 22 00 00       	call   80103df3 <strncpy>
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
80101bd7:	68 94 6c 10 80       	push   $0x80106c94
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
80101ccc:	68 eb 66 10 80       	push   $0x801066eb
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 f4 66 10 80       	push   $0x801066f4
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
80101d06:	68 06 67 10 80       	push   $0x80106706
80101d0b:	68 80 95 10 80       	push   $0x80109580
80101d10:	e8 d7 1d 00 00       	call   80103aec <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101d15:	83 c4 08             	add    $0x8,%esp
80101d18:	a1 60 1d 13 80       	mov    0x80131d60,%eax
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
80101d80:	e8 a3 1e 00 00       	call   80103c28 <acquire>

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
80101dad:	e8 e0 1a 00 00       	call   80103892 <wakeup>

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
80101dcb:	e8 bd 1e 00 00       	call   80103c8d <release>
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
80101de2:	e8 a6 1e 00 00       	call   80103c8d <release>
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
80101e1a:	e8 7f 1c 00 00       	call   80103a9e <holdingsleep>
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
80101e47:	e8 dc 1d 00 00       	call   80103c28 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 95 10 80       	mov    $0x80109564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 0a 67 10 80       	push   $0x8010670a
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 20 67 10 80       	push   $0x80106720
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 35 67 10 80       	push   $0x80106735
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
80101ea9:	e8 7f 18 00 00       	call   8010372d <sleep>
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
80101ec3:	e8 c5 1d 00 00       	call   80103c8d <release>
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
80101f2a:	0f b6 15 c0 17 13 80 	movzbl 0x801317c0,%edx
80101f31:	39 c2                	cmp    %eax,%edx
80101f33:	75 07                	jne    80101f3c <ioapicinit+0x42>
{
80101f35:	bb 00 00 00 00       	mov    $0x0,%ebx
80101f3a:	eb 36                	jmp    80101f72 <ioapicinit+0x78>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80101f3c:	83 ec 0c             	sub    $0xc,%esp
80101f3f:	68 54 67 10 80       	push   $0x80106754
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
80101fb6:	81 fb 08 45 13 80    	cmp    $0x80134508,%ebx
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
80101fd6:	e8 f9 1c 00 00       	call   80103cd4 <memset>

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
80102005:	68 86 67 10 80       	push   $0x80106786
8010200a:	e8 39 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010200f:	83 ec 0c             	sub    $0xc,%esp
80102012:	68 60 16 11 80       	push   $0x80111660
80102017:	e8 0c 1c 00 00       	call   80103c28 <acquire>
8010201c:	83 c4 10             	add    $0x10,%esp
8010201f:	eb c6                	jmp    80101fe7 <kfree+0x43>
    release(&kmem.lock);
80102021:	83 ec 0c             	sub    $0xc,%esp
80102024:	68 60 16 11 80       	push   $0x80111660
80102029:	e8 5f 1c 00 00       	call   80103c8d <release>
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
8010206f:	68 8c 67 10 80       	push   $0x8010678c
80102074:	68 60 16 11 80       	push   $0x80111660
80102079:	e8 6e 1a 00 00       	call   80103aec <initlock>
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

801020bb <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
801020bb:	55                   	push   %ebp
801020bc:	89 e5                	mov    %esp,%ebp
801020be:	53                   	push   %ebx
801020bf:	83 ec 04             	sub    $0x4,%esp
  struct run *r;

  if(kmem.use_lock)
801020c2:	83 3d 94 16 11 80 00 	cmpl   $0x0,0x80111694
801020c9:	75 23                	jne    801020ee <kalloc+0x33>
    acquire(&kmem.lock);
  r = kmem.freelist;
801020cb:	8b 1d 98 16 11 80    	mov    0x80111698,%ebx
  if(r)
801020d1:	85 db                	test   %ebx,%ebx
801020d3:	74 09                	je     801020de <kalloc+0x23>
    kmem.freelist = r->next->next;
801020d5:	8b 03                	mov    (%ebx),%eax
801020d7:	8b 00                	mov    (%eax),%eax
801020d9:	a3 98 16 11 80       	mov    %eax,0x80111698

  if(kmem.use_lock) {
801020de:	83 3d 94 16 11 80 00 	cmpl   $0x0,0x80111694
801020e5:	75 19                	jne    80102100 <kalloc+0x45>
    pids[index] = -2;
    index++;
    release(&kmem.lock);
  }
  return (char*)r;
}
801020e7:	89 d8                	mov    %ebx,%eax
801020e9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801020ec:	c9                   	leave  
801020ed:	c3                   	ret    
    acquire(&kmem.lock);
801020ee:	83 ec 0c             	sub    $0xc,%esp
801020f1:	68 60 16 11 80       	push   $0x80111660
801020f6:	e8 2d 1b 00 00       	call   80103c28 <acquire>
801020fb:	83 c4 10             	add    $0x10,%esp
801020fe:	eb cb                	jmp    801020cb <kalloc+0x10>
    framenumber = (uint)(V2P(r) >> 12 & 0xffff);
80102100:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80102106:	c1 e8 0c             	shr    $0xc,%eax
80102109:	0f b7 c0             	movzwl %ax,%eax
8010210c:	a3 9c 16 11 80       	mov    %eax,0x8011169c
    frames[index] = framenumber;
80102111:	8b 15 b4 95 10 80    	mov    0x801095b4,%edx
80102117:	89 04 95 a0 16 11 80 	mov    %eax,-0x7feee960(,%edx,4)
    pids[index] = -2;
8010211e:	c7 04 95 c0 16 12 80 	movl   $0xfffffffe,-0x7fede940(,%edx,4)
80102125:	fe ff ff ff 
    index++;
80102129:	83 c2 01             	add    $0x1,%edx
8010212c:	89 15 b4 95 10 80    	mov    %edx,0x801095b4
    release(&kmem.lock);
80102132:	83 ec 0c             	sub    $0xc,%esp
80102135:	68 60 16 11 80       	push   $0x80111660
8010213a:	e8 4e 1b 00 00       	call   80103c8d <release>
8010213f:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
80102142:	eb a3                	jmp    801020e7 <kalloc+0x2c>

80102144 <dump_physmem>:
//   return (char*)r;
// }

int
dump_physmem(int *frs, int *pids, int numframes)
{
80102144:	55                   	push   %ebp
80102145:	89 e5                	mov    %esp,%ebp
80102147:	57                   	push   %edi
80102148:	56                   	push   %esi
80102149:	53                   	push   %ebx
8010214a:	8b 75 08             	mov    0x8(%ebp),%esi
8010214d:	8b 7d 0c             	mov    0xc(%ebp),%edi
80102150:	8b 5d 10             	mov    0x10(%ebp),%ebx
  if(numframes <= 0 || frs == 0 || pids == 0)
80102153:	85 db                	test   %ebx,%ebx
80102155:	0f 9e c2             	setle  %dl
80102158:	85 f6                	test   %esi,%esi
8010215a:	0f 94 c0             	sete   %al
8010215d:	08 c2                	or     %al,%dl
8010215f:	75 34                	jne    80102195 <dump_physmem+0x51>
80102161:	85 ff                	test   %edi,%edi
80102163:	74 37                	je     8010219c <dump_physmem+0x58>
    return -1;
  for (int i = 0; i < numframes; i++) {
80102165:	b8 00 00 00 00       	mov    $0x0,%eax
8010216a:	eb 1b                	jmp    80102187 <dump_physmem+0x43>
    frs[i] = frames[i];
8010216c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80102173:	8b 0c 85 a0 16 11 80 	mov    -0x7feee960(,%eax,4),%ecx
8010217a:	89 0c 16             	mov    %ecx,(%esi,%edx,1)
    pids[i] = -2;
8010217d:	c7 04 17 fe ff ff ff 	movl   $0xfffffffe,(%edi,%edx,1)
  for (int i = 0; i < numframes; i++) {
80102184:	83 c0 01             	add    $0x1,%eax
80102187:	39 d8                	cmp    %ebx,%eax
80102189:	7c e1                	jl     8010216c <dump_physmem+0x28>
  }
  return 0;
8010218b:	b8 00 00 00 00       	mov    $0x0,%eax
80102190:	5b                   	pop    %ebx
80102191:	5e                   	pop    %esi
80102192:	5f                   	pop    %edi
80102193:	5d                   	pop    %ebp
80102194:	c3                   	ret    
    return -1;
80102195:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010219a:	eb f4                	jmp    80102190 <dump_physmem+0x4c>
8010219c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801021a1:	eb ed                	jmp    80102190 <dump_physmem+0x4c>

801021a3 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
801021a3:	55                   	push   %ebp
801021a4:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801021a6:	ba 64 00 00 00       	mov    $0x64,%edx
801021ab:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
801021ac:	a8 01                	test   $0x1,%al
801021ae:	0f 84 b5 00 00 00    	je     80102269 <kbdgetc+0xc6>
801021b4:	ba 60 00 00 00       	mov    $0x60,%edx
801021b9:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
801021ba:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
801021bd:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
801021c3:	74 5c                	je     80102221 <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
801021c5:	84 c0                	test   %al,%al
801021c7:	78 66                	js     8010222f <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
801021c9:	8b 0d b8 95 10 80    	mov    0x801095b8,%ecx
801021cf:	f6 c1 40             	test   $0x40,%cl
801021d2:	74 0f                	je     801021e3 <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
801021d4:	83 c8 80             	or     $0xffffff80,%eax
801021d7:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
801021da:	83 e1 bf             	and    $0xffffffbf,%ecx
801021dd:	89 0d b8 95 10 80    	mov    %ecx,0x801095b8
  }

  shift |= shiftcode[data];
801021e3:	0f b6 8a c0 68 10 80 	movzbl -0x7fef9740(%edx),%ecx
801021ea:	0b 0d b8 95 10 80    	or     0x801095b8,%ecx
  shift ^= togglecode[data];
801021f0:	0f b6 82 c0 67 10 80 	movzbl -0x7fef9840(%edx),%eax
801021f7:	31 c1                	xor    %eax,%ecx
801021f9:	89 0d b8 95 10 80    	mov    %ecx,0x801095b8
  c = charcode[shift & (CTL | SHIFT)][data];
801021ff:	89 c8                	mov    %ecx,%eax
80102201:	83 e0 03             	and    $0x3,%eax
80102204:	8b 04 85 a0 67 10 80 	mov    -0x7fef9860(,%eax,4),%eax
8010220b:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
8010220f:	f6 c1 08             	test   $0x8,%cl
80102212:	74 19                	je     8010222d <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
80102214:	8d 50 9f             	lea    -0x61(%eax),%edx
80102217:	83 fa 19             	cmp    $0x19,%edx
8010221a:	77 40                	ja     8010225c <kbdgetc+0xb9>
      c += 'A' - 'a';
8010221c:	83 e8 20             	sub    $0x20,%eax
8010221f:	eb 0c                	jmp    8010222d <kbdgetc+0x8a>
    shift |= E0ESC;
80102221:	83 0d b8 95 10 80 40 	orl    $0x40,0x801095b8
    return 0;
80102228:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
8010222d:	5d                   	pop    %ebp
8010222e:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
8010222f:	8b 0d b8 95 10 80    	mov    0x801095b8,%ecx
80102235:	f6 c1 40             	test   $0x40,%cl
80102238:	75 05                	jne    8010223f <kbdgetc+0x9c>
8010223a:	89 c2                	mov    %eax,%edx
8010223c:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
8010223f:	0f b6 82 c0 68 10 80 	movzbl -0x7fef9740(%edx),%eax
80102246:	83 c8 40             	or     $0x40,%eax
80102249:	0f b6 c0             	movzbl %al,%eax
8010224c:	f7 d0                	not    %eax
8010224e:	21 c8                	and    %ecx,%eax
80102250:	a3 b8 95 10 80       	mov    %eax,0x801095b8
    return 0;
80102255:	b8 00 00 00 00       	mov    $0x0,%eax
8010225a:	eb d1                	jmp    8010222d <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
8010225c:	8d 50 bf             	lea    -0x41(%eax),%edx
8010225f:	83 fa 19             	cmp    $0x19,%edx
80102262:	77 c9                	ja     8010222d <kbdgetc+0x8a>
      c += 'a' - 'A';
80102264:	83 c0 20             	add    $0x20,%eax
  return c;
80102267:	eb c4                	jmp    8010222d <kbdgetc+0x8a>
    return -1;
80102269:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010226e:	eb bd                	jmp    8010222d <kbdgetc+0x8a>

80102270 <kbdintr>:

void
kbdintr(void)
{
80102270:	55                   	push   %ebp
80102271:	89 e5                	mov    %esp,%ebp
80102273:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
80102276:	68 a3 21 10 80       	push   $0x801021a3
8010227b:	e8 be e4 ff ff       	call   8010073e <consoleintr>
}
80102280:	83 c4 10             	add    $0x10,%esp
80102283:	c9                   	leave  
80102284:	c3                   	ret    

80102285 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102285:	55                   	push   %ebp
80102286:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102288:	8b 0d c4 16 13 80    	mov    0x801316c4,%ecx
8010228e:	8d 04 81             	lea    (%ecx,%eax,4),%eax
80102291:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
80102293:	a1 c4 16 13 80       	mov    0x801316c4,%eax
80102298:	8b 40 20             	mov    0x20(%eax),%eax
}
8010229b:	5d                   	pop    %ebp
8010229c:	c3                   	ret    

8010229d <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
8010229d:	55                   	push   %ebp
8010229e:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801022a0:	ba 70 00 00 00       	mov    $0x70,%edx
801022a5:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801022a6:	ba 71 00 00 00       	mov    $0x71,%edx
801022ab:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
801022ac:	0f b6 c0             	movzbl %al,%eax
}
801022af:	5d                   	pop    %ebp
801022b0:	c3                   	ret    

801022b1 <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
801022b1:	55                   	push   %ebp
801022b2:	89 e5                	mov    %esp,%ebp
801022b4:	53                   	push   %ebx
801022b5:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
801022b7:	b8 00 00 00 00       	mov    $0x0,%eax
801022bc:	e8 dc ff ff ff       	call   8010229d <cmos_read>
801022c1:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
801022c3:	b8 02 00 00 00       	mov    $0x2,%eax
801022c8:	e8 d0 ff ff ff       	call   8010229d <cmos_read>
801022cd:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
801022d0:	b8 04 00 00 00       	mov    $0x4,%eax
801022d5:	e8 c3 ff ff ff       	call   8010229d <cmos_read>
801022da:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
801022dd:	b8 07 00 00 00       	mov    $0x7,%eax
801022e2:	e8 b6 ff ff ff       	call   8010229d <cmos_read>
801022e7:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
801022ea:	b8 08 00 00 00       	mov    $0x8,%eax
801022ef:	e8 a9 ff ff ff       	call   8010229d <cmos_read>
801022f4:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
801022f7:	b8 09 00 00 00       	mov    $0x9,%eax
801022fc:	e8 9c ff ff ff       	call   8010229d <cmos_read>
80102301:	89 43 14             	mov    %eax,0x14(%ebx)
}
80102304:	5b                   	pop    %ebx
80102305:	5d                   	pop    %ebp
80102306:	c3                   	ret    

80102307 <lapicinit>:
  if(!lapic)
80102307:	83 3d c4 16 13 80 00 	cmpl   $0x0,0x801316c4
8010230e:	0f 84 fb 00 00 00    	je     8010240f <lapicinit+0x108>
{
80102314:	55                   	push   %ebp
80102315:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102317:	ba 3f 01 00 00       	mov    $0x13f,%edx
8010231c:	b8 3c 00 00 00       	mov    $0x3c,%eax
80102321:	e8 5f ff ff ff       	call   80102285 <lapicw>
  lapicw(TDCR, X1);
80102326:	ba 0b 00 00 00       	mov    $0xb,%edx
8010232b:	b8 f8 00 00 00       	mov    $0xf8,%eax
80102330:	e8 50 ff ff ff       	call   80102285 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102335:	ba 20 00 02 00       	mov    $0x20020,%edx
8010233a:	b8 c8 00 00 00       	mov    $0xc8,%eax
8010233f:	e8 41 ff ff ff       	call   80102285 <lapicw>
  lapicw(TICR, 10000000);
80102344:	ba 80 96 98 00       	mov    $0x989680,%edx
80102349:	b8 e0 00 00 00       	mov    $0xe0,%eax
8010234e:	e8 32 ff ff ff       	call   80102285 <lapicw>
  lapicw(LINT0, MASKED);
80102353:	ba 00 00 01 00       	mov    $0x10000,%edx
80102358:	b8 d4 00 00 00       	mov    $0xd4,%eax
8010235d:	e8 23 ff ff ff       	call   80102285 <lapicw>
  lapicw(LINT1, MASKED);
80102362:	ba 00 00 01 00       	mov    $0x10000,%edx
80102367:	b8 d8 00 00 00       	mov    $0xd8,%eax
8010236c:	e8 14 ff ff ff       	call   80102285 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102371:	a1 c4 16 13 80       	mov    0x801316c4,%eax
80102376:	8b 40 30             	mov    0x30(%eax),%eax
80102379:	c1 e8 10             	shr    $0x10,%eax
8010237c:	3c 03                	cmp    $0x3,%al
8010237e:	77 7b                	ja     801023fb <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102380:	ba 33 00 00 00       	mov    $0x33,%edx
80102385:	b8 dc 00 00 00       	mov    $0xdc,%eax
8010238a:	e8 f6 fe ff ff       	call   80102285 <lapicw>
  lapicw(ESR, 0);
8010238f:	ba 00 00 00 00       	mov    $0x0,%edx
80102394:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102399:	e8 e7 fe ff ff       	call   80102285 <lapicw>
  lapicw(ESR, 0);
8010239e:	ba 00 00 00 00       	mov    $0x0,%edx
801023a3:	b8 a0 00 00 00       	mov    $0xa0,%eax
801023a8:	e8 d8 fe ff ff       	call   80102285 <lapicw>
  lapicw(EOI, 0);
801023ad:	ba 00 00 00 00       	mov    $0x0,%edx
801023b2:	b8 2c 00 00 00       	mov    $0x2c,%eax
801023b7:	e8 c9 fe ff ff       	call   80102285 <lapicw>
  lapicw(ICRHI, 0);
801023bc:	ba 00 00 00 00       	mov    $0x0,%edx
801023c1:	b8 c4 00 00 00       	mov    $0xc4,%eax
801023c6:	e8 ba fe ff ff       	call   80102285 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801023cb:	ba 00 85 08 00       	mov    $0x88500,%edx
801023d0:	b8 c0 00 00 00       	mov    $0xc0,%eax
801023d5:	e8 ab fe ff ff       	call   80102285 <lapicw>
  while(lapic[ICRLO] & DELIVS)
801023da:	a1 c4 16 13 80       	mov    0x801316c4,%eax
801023df:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
801023e5:	f6 c4 10             	test   $0x10,%ah
801023e8:	75 f0                	jne    801023da <lapicinit+0xd3>
  lapicw(TPR, 0);
801023ea:	ba 00 00 00 00       	mov    $0x0,%edx
801023ef:	b8 20 00 00 00       	mov    $0x20,%eax
801023f4:	e8 8c fe ff ff       	call   80102285 <lapicw>
}
801023f9:	5d                   	pop    %ebp
801023fa:	c3                   	ret    
    lapicw(PCINT, MASKED);
801023fb:	ba 00 00 01 00       	mov    $0x10000,%edx
80102400:	b8 d0 00 00 00       	mov    $0xd0,%eax
80102405:	e8 7b fe ff ff       	call   80102285 <lapicw>
8010240a:	e9 71 ff ff ff       	jmp    80102380 <lapicinit+0x79>
8010240f:	f3 c3                	repz ret 

80102411 <lapicid>:
{
80102411:	55                   	push   %ebp
80102412:	89 e5                	mov    %esp,%ebp
  if (!lapic)
80102414:	a1 c4 16 13 80       	mov    0x801316c4,%eax
80102419:	85 c0                	test   %eax,%eax
8010241b:	74 08                	je     80102425 <lapicid+0x14>
  return lapic[ID] >> 24;
8010241d:	8b 40 20             	mov    0x20(%eax),%eax
80102420:	c1 e8 18             	shr    $0x18,%eax
}
80102423:	5d                   	pop    %ebp
80102424:	c3                   	ret    
    return 0;
80102425:	b8 00 00 00 00       	mov    $0x0,%eax
8010242a:	eb f7                	jmp    80102423 <lapicid+0x12>

8010242c <lapiceoi>:
  if(lapic)
8010242c:	83 3d c4 16 13 80 00 	cmpl   $0x0,0x801316c4
80102433:	74 14                	je     80102449 <lapiceoi+0x1d>
{
80102435:	55                   	push   %ebp
80102436:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
80102438:	ba 00 00 00 00       	mov    $0x0,%edx
8010243d:	b8 2c 00 00 00       	mov    $0x2c,%eax
80102442:	e8 3e fe ff ff       	call   80102285 <lapicw>
}
80102447:	5d                   	pop    %ebp
80102448:	c3                   	ret    
80102449:	f3 c3                	repz ret 

8010244b <microdelay>:
{
8010244b:	55                   	push   %ebp
8010244c:	89 e5                	mov    %esp,%ebp
}
8010244e:	5d                   	pop    %ebp
8010244f:	c3                   	ret    

80102450 <lapicstartap>:
{
80102450:	55                   	push   %ebp
80102451:	89 e5                	mov    %esp,%ebp
80102453:	57                   	push   %edi
80102454:	56                   	push   %esi
80102455:	53                   	push   %ebx
80102456:	8b 75 08             	mov    0x8(%ebp),%esi
80102459:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010245c:	b8 0f 00 00 00       	mov    $0xf,%eax
80102461:	ba 70 00 00 00       	mov    $0x70,%edx
80102466:	ee                   	out    %al,(%dx)
80102467:	b8 0a 00 00 00       	mov    $0xa,%eax
8010246c:	ba 71 00 00 00       	mov    $0x71,%edx
80102471:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
80102472:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
80102479:	00 00 
  wrv[1] = addr >> 4;
8010247b:	89 f8                	mov    %edi,%eax
8010247d:	c1 e8 04             	shr    $0x4,%eax
80102480:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
80102486:	c1 e6 18             	shl    $0x18,%esi
80102489:	89 f2                	mov    %esi,%edx
8010248b:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102490:	e8 f0 fd ff ff       	call   80102285 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102495:	ba 00 c5 00 00       	mov    $0xc500,%edx
8010249a:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010249f:	e8 e1 fd ff ff       	call   80102285 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
801024a4:	ba 00 85 00 00       	mov    $0x8500,%edx
801024a9:	b8 c0 00 00 00       	mov    $0xc0,%eax
801024ae:	e8 d2 fd ff ff       	call   80102285 <lapicw>
  for(i = 0; i < 2; i++){
801024b3:	bb 00 00 00 00       	mov    $0x0,%ebx
801024b8:	eb 21                	jmp    801024db <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
801024ba:	89 f2                	mov    %esi,%edx
801024bc:	b8 c4 00 00 00       	mov    $0xc4,%eax
801024c1:	e8 bf fd ff ff       	call   80102285 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
801024c6:	89 fa                	mov    %edi,%edx
801024c8:	c1 ea 0c             	shr    $0xc,%edx
801024cb:	80 ce 06             	or     $0x6,%dh
801024ce:	b8 c0 00 00 00       	mov    $0xc0,%eax
801024d3:	e8 ad fd ff ff       	call   80102285 <lapicw>
  for(i = 0; i < 2; i++){
801024d8:	83 c3 01             	add    $0x1,%ebx
801024db:	83 fb 01             	cmp    $0x1,%ebx
801024de:	7e da                	jle    801024ba <lapicstartap+0x6a>
}
801024e0:	5b                   	pop    %ebx
801024e1:	5e                   	pop    %esi
801024e2:	5f                   	pop    %edi
801024e3:	5d                   	pop    %ebp
801024e4:	c3                   	ret    

801024e5 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
801024e5:	55                   	push   %ebp
801024e6:	89 e5                	mov    %esp,%ebp
801024e8:	57                   	push   %edi
801024e9:	56                   	push   %esi
801024ea:	53                   	push   %ebx
801024eb:	83 ec 3c             	sub    $0x3c,%esp
801024ee:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801024f1:	b8 0b 00 00 00       	mov    $0xb,%eax
801024f6:	e8 a2 fd ff ff       	call   8010229d <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
801024fb:	83 e0 04             	and    $0x4,%eax
801024fe:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
80102500:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102503:	e8 a9 fd ff ff       	call   801022b1 <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
80102508:	b8 0a 00 00 00       	mov    $0xa,%eax
8010250d:	e8 8b fd ff ff       	call   8010229d <cmos_read>
80102512:	a8 80                	test   $0x80,%al
80102514:	75 ea                	jne    80102500 <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
80102516:	8d 5d b8             	lea    -0x48(%ebp),%ebx
80102519:	89 d8                	mov    %ebx,%eax
8010251b:	e8 91 fd ff ff       	call   801022b1 <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
80102520:	83 ec 04             	sub    $0x4,%esp
80102523:	6a 18                	push   $0x18
80102525:	53                   	push   %ebx
80102526:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102529:	50                   	push   %eax
8010252a:	e8 eb 17 00 00       	call   80103d1a <memcmp>
8010252f:	83 c4 10             	add    $0x10,%esp
80102532:	85 c0                	test   %eax,%eax
80102534:	75 ca                	jne    80102500 <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
80102536:	85 ff                	test   %edi,%edi
80102538:	0f 85 84 00 00 00    	jne    801025c2 <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
8010253e:	8b 55 d0             	mov    -0x30(%ebp),%edx
80102541:	89 d0                	mov    %edx,%eax
80102543:	c1 e8 04             	shr    $0x4,%eax
80102546:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102549:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010254c:	83 e2 0f             	and    $0xf,%edx
8010254f:	01 d0                	add    %edx,%eax
80102551:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
80102554:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80102557:	89 d0                	mov    %edx,%eax
80102559:	c1 e8 04             	shr    $0x4,%eax
8010255c:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010255f:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102562:	83 e2 0f             	and    $0xf,%edx
80102565:	01 d0                	add    %edx,%eax
80102567:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
8010256a:	8b 55 d8             	mov    -0x28(%ebp),%edx
8010256d:	89 d0                	mov    %edx,%eax
8010256f:	c1 e8 04             	shr    $0x4,%eax
80102572:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102575:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102578:	83 e2 0f             	and    $0xf,%edx
8010257b:	01 d0                	add    %edx,%eax
8010257d:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
80102580:	8b 55 dc             	mov    -0x24(%ebp),%edx
80102583:	89 d0                	mov    %edx,%eax
80102585:	c1 e8 04             	shr    $0x4,%eax
80102588:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010258b:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010258e:	83 e2 0f             	and    $0xf,%edx
80102591:	01 d0                	add    %edx,%eax
80102593:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
80102596:	8b 55 e0             	mov    -0x20(%ebp),%edx
80102599:	89 d0                	mov    %edx,%eax
8010259b:	c1 e8 04             	shr    $0x4,%eax
8010259e:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025a1:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025a4:	83 e2 0f             	and    $0xf,%edx
801025a7:	01 d0                	add    %edx,%eax
801025a9:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
801025ac:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801025af:	89 d0                	mov    %edx,%eax
801025b1:	c1 e8 04             	shr    $0x4,%eax
801025b4:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025b7:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025ba:	83 e2 0f             	and    $0xf,%edx
801025bd:	01 d0                	add    %edx,%eax
801025bf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
801025c2:	8b 45 d0             	mov    -0x30(%ebp),%eax
801025c5:	89 06                	mov    %eax,(%esi)
801025c7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801025ca:	89 46 04             	mov    %eax,0x4(%esi)
801025cd:	8b 45 d8             	mov    -0x28(%ebp),%eax
801025d0:	89 46 08             	mov    %eax,0x8(%esi)
801025d3:	8b 45 dc             	mov    -0x24(%ebp),%eax
801025d6:	89 46 0c             	mov    %eax,0xc(%esi)
801025d9:	8b 45 e0             	mov    -0x20(%ebp),%eax
801025dc:	89 46 10             	mov    %eax,0x10(%esi)
801025df:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801025e2:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
801025e5:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
801025ec:	8d 65 f4             	lea    -0xc(%ebp),%esp
801025ef:	5b                   	pop    %ebx
801025f0:	5e                   	pop    %esi
801025f1:	5f                   	pop    %edi
801025f2:	5d                   	pop    %ebp
801025f3:	c3                   	ret    

801025f4 <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
801025f4:	55                   	push   %ebp
801025f5:	89 e5                	mov    %esp,%ebp
801025f7:	53                   	push   %ebx
801025f8:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
801025fb:	ff 35 14 17 13 80    	pushl  0x80131714
80102601:	ff 35 24 17 13 80    	pushl  0x80131724
80102607:	e8 60 db ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
8010260c:	8b 58 5c             	mov    0x5c(%eax),%ebx
8010260f:	89 1d 28 17 13 80    	mov    %ebx,0x80131728
  for (i = 0; i < log.lh.n; i++) {
80102615:	83 c4 10             	add    $0x10,%esp
80102618:	ba 00 00 00 00       	mov    $0x0,%edx
8010261d:	eb 0e                	jmp    8010262d <read_head+0x39>
    log.lh.block[i] = lh->block[i];
8010261f:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
80102623:	89 0c 95 2c 17 13 80 	mov    %ecx,-0x7fece8d4(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
8010262a:	83 c2 01             	add    $0x1,%edx
8010262d:	39 d3                	cmp    %edx,%ebx
8010262f:	7f ee                	jg     8010261f <read_head+0x2b>
  }
  brelse(buf);
80102631:	83 ec 0c             	sub    $0xc,%esp
80102634:	50                   	push   %eax
80102635:	e8 9b db ff ff       	call   801001d5 <brelse>
}
8010263a:	83 c4 10             	add    $0x10,%esp
8010263d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102640:	c9                   	leave  
80102641:	c3                   	ret    

80102642 <install_trans>:
{
80102642:	55                   	push   %ebp
80102643:	89 e5                	mov    %esp,%ebp
80102645:	57                   	push   %edi
80102646:	56                   	push   %esi
80102647:	53                   	push   %ebx
80102648:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
8010264b:	bb 00 00 00 00       	mov    $0x0,%ebx
80102650:	eb 66                	jmp    801026b8 <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80102652:	89 d8                	mov    %ebx,%eax
80102654:	03 05 14 17 13 80    	add    0x80131714,%eax
8010265a:	83 c0 01             	add    $0x1,%eax
8010265d:	83 ec 08             	sub    $0x8,%esp
80102660:	50                   	push   %eax
80102661:	ff 35 24 17 13 80    	pushl  0x80131724
80102667:	e8 00 db ff ff       	call   8010016c <bread>
8010266c:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
8010266e:	83 c4 08             	add    $0x8,%esp
80102671:	ff 34 9d 2c 17 13 80 	pushl  -0x7fece8d4(,%ebx,4)
80102678:	ff 35 24 17 13 80    	pushl  0x80131724
8010267e:	e8 e9 da ff ff       	call   8010016c <bread>
80102683:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80102685:	8d 57 5c             	lea    0x5c(%edi),%edx
80102688:	8d 40 5c             	lea    0x5c(%eax),%eax
8010268b:	83 c4 0c             	add    $0xc,%esp
8010268e:	68 00 02 00 00       	push   $0x200
80102693:	52                   	push   %edx
80102694:	50                   	push   %eax
80102695:	e8 b5 16 00 00       	call   80103d4f <memmove>
    bwrite(dbuf);  // write dst to disk
8010269a:	89 34 24             	mov    %esi,(%esp)
8010269d:	e8 f8 da ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
801026a2:	89 3c 24             	mov    %edi,(%esp)
801026a5:	e8 2b db ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
801026aa:	89 34 24             	mov    %esi,(%esp)
801026ad:	e8 23 db ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
801026b2:	83 c3 01             	add    $0x1,%ebx
801026b5:	83 c4 10             	add    $0x10,%esp
801026b8:	39 1d 28 17 13 80    	cmp    %ebx,0x80131728
801026be:	7f 92                	jg     80102652 <install_trans+0x10>
}
801026c0:	8d 65 f4             	lea    -0xc(%ebp),%esp
801026c3:	5b                   	pop    %ebx
801026c4:	5e                   	pop    %esi
801026c5:	5f                   	pop    %edi
801026c6:	5d                   	pop    %ebp
801026c7:	c3                   	ret    

801026c8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801026c8:	55                   	push   %ebp
801026c9:	89 e5                	mov    %esp,%ebp
801026cb:	53                   	push   %ebx
801026cc:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
801026cf:	ff 35 14 17 13 80    	pushl  0x80131714
801026d5:	ff 35 24 17 13 80    	pushl  0x80131724
801026db:	e8 8c da ff ff       	call   8010016c <bread>
801026e0:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
801026e2:	8b 0d 28 17 13 80    	mov    0x80131728,%ecx
801026e8:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
801026eb:	83 c4 10             	add    $0x10,%esp
801026ee:	b8 00 00 00 00       	mov    $0x0,%eax
801026f3:	eb 0e                	jmp    80102703 <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
801026f5:	8b 14 85 2c 17 13 80 	mov    -0x7fece8d4(,%eax,4),%edx
801026fc:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
80102700:	83 c0 01             	add    $0x1,%eax
80102703:	39 c1                	cmp    %eax,%ecx
80102705:	7f ee                	jg     801026f5 <write_head+0x2d>
  }
  bwrite(buf);
80102707:	83 ec 0c             	sub    $0xc,%esp
8010270a:	53                   	push   %ebx
8010270b:	e8 8a da ff ff       	call   8010019a <bwrite>
  brelse(buf);
80102710:	89 1c 24             	mov    %ebx,(%esp)
80102713:	e8 bd da ff ff       	call   801001d5 <brelse>
}
80102718:	83 c4 10             	add    $0x10,%esp
8010271b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010271e:	c9                   	leave  
8010271f:	c3                   	ret    

80102720 <recover_from_log>:

static void
recover_from_log(void)
{
80102720:	55                   	push   %ebp
80102721:	89 e5                	mov    %esp,%ebp
80102723:	83 ec 08             	sub    $0x8,%esp
  read_head();
80102726:	e8 c9 fe ff ff       	call   801025f4 <read_head>
  install_trans(); // if committed, copy from log to disk
8010272b:	e8 12 ff ff ff       	call   80102642 <install_trans>
  log.lh.n = 0;
80102730:	c7 05 28 17 13 80 00 	movl   $0x0,0x80131728
80102737:	00 00 00 
  write_head(); // clear the log
8010273a:	e8 89 ff ff ff       	call   801026c8 <write_head>
}
8010273f:	c9                   	leave  
80102740:	c3                   	ret    

80102741 <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
80102741:	55                   	push   %ebp
80102742:	89 e5                	mov    %esp,%ebp
80102744:	57                   	push   %edi
80102745:	56                   	push   %esi
80102746:	53                   	push   %ebx
80102747:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010274a:	bb 00 00 00 00       	mov    $0x0,%ebx
8010274f:	eb 66                	jmp    801027b7 <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80102751:	89 d8                	mov    %ebx,%eax
80102753:	03 05 14 17 13 80    	add    0x80131714,%eax
80102759:	83 c0 01             	add    $0x1,%eax
8010275c:	83 ec 08             	sub    $0x8,%esp
8010275f:	50                   	push   %eax
80102760:	ff 35 24 17 13 80    	pushl  0x80131724
80102766:	e8 01 da ff ff       	call   8010016c <bread>
8010276b:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
8010276d:	83 c4 08             	add    $0x8,%esp
80102770:	ff 34 9d 2c 17 13 80 	pushl  -0x7fece8d4(,%ebx,4)
80102777:	ff 35 24 17 13 80    	pushl  0x80131724
8010277d:	e8 ea d9 ff ff       	call   8010016c <bread>
80102782:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
80102784:	8d 50 5c             	lea    0x5c(%eax),%edx
80102787:	8d 46 5c             	lea    0x5c(%esi),%eax
8010278a:	83 c4 0c             	add    $0xc,%esp
8010278d:	68 00 02 00 00       	push   $0x200
80102792:	52                   	push   %edx
80102793:	50                   	push   %eax
80102794:	e8 b6 15 00 00       	call   80103d4f <memmove>
    bwrite(to);  // write the log
80102799:	89 34 24             	mov    %esi,(%esp)
8010279c:	e8 f9 d9 ff ff       	call   8010019a <bwrite>
    brelse(from);
801027a1:	89 3c 24             	mov    %edi,(%esp)
801027a4:	e8 2c da ff ff       	call   801001d5 <brelse>
    brelse(to);
801027a9:	89 34 24             	mov    %esi,(%esp)
801027ac:	e8 24 da ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
801027b1:	83 c3 01             	add    $0x1,%ebx
801027b4:	83 c4 10             	add    $0x10,%esp
801027b7:	39 1d 28 17 13 80    	cmp    %ebx,0x80131728
801027bd:	7f 92                	jg     80102751 <write_log+0x10>
  }
}
801027bf:	8d 65 f4             	lea    -0xc(%ebp),%esp
801027c2:	5b                   	pop    %ebx
801027c3:	5e                   	pop    %esi
801027c4:	5f                   	pop    %edi
801027c5:	5d                   	pop    %ebp
801027c6:	c3                   	ret    

801027c7 <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
801027c7:	83 3d 28 17 13 80 00 	cmpl   $0x0,0x80131728
801027ce:	7e 26                	jle    801027f6 <commit+0x2f>
{
801027d0:	55                   	push   %ebp
801027d1:	89 e5                	mov    %esp,%ebp
801027d3:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
801027d6:	e8 66 ff ff ff       	call   80102741 <write_log>
    write_head();    // Write header to disk -- the real commit
801027db:	e8 e8 fe ff ff       	call   801026c8 <write_head>
    install_trans(); // Now install writes to home locations
801027e0:	e8 5d fe ff ff       	call   80102642 <install_trans>
    log.lh.n = 0;
801027e5:	c7 05 28 17 13 80 00 	movl   $0x0,0x80131728
801027ec:	00 00 00 
    write_head();    // Erase the transaction from the log
801027ef:	e8 d4 fe ff ff       	call   801026c8 <write_head>
  }
}
801027f4:	c9                   	leave  
801027f5:	c3                   	ret    
801027f6:	f3 c3                	repz ret 

801027f8 <initlog>:
{
801027f8:	55                   	push   %ebp
801027f9:	89 e5                	mov    %esp,%ebp
801027fb:	53                   	push   %ebx
801027fc:	83 ec 2c             	sub    $0x2c,%esp
801027ff:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
80102802:	68 c0 69 10 80       	push   $0x801069c0
80102807:	68 e0 16 13 80       	push   $0x801316e0
8010280c:	e8 db 12 00 00       	call   80103aec <initlock>
  readsb(dev, &sb);
80102811:	83 c4 08             	add    $0x8,%esp
80102814:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102817:	50                   	push   %eax
80102818:	53                   	push   %ebx
80102819:	e8 18 ea ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
8010281e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102821:	a3 14 17 13 80       	mov    %eax,0x80131714
  log.size = sb.nlog;
80102826:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102829:	a3 18 17 13 80       	mov    %eax,0x80131718
  log.dev = dev;
8010282e:	89 1d 24 17 13 80    	mov    %ebx,0x80131724
  recover_from_log();
80102834:	e8 e7 fe ff ff       	call   80102720 <recover_from_log>
}
80102839:	83 c4 10             	add    $0x10,%esp
8010283c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010283f:	c9                   	leave  
80102840:	c3                   	ret    

80102841 <begin_op>:
{
80102841:	55                   	push   %ebp
80102842:	89 e5                	mov    %esp,%ebp
80102844:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
80102847:	68 e0 16 13 80       	push   $0x801316e0
8010284c:	e8 d7 13 00 00       	call   80103c28 <acquire>
80102851:	83 c4 10             	add    $0x10,%esp
80102854:	eb 15                	jmp    8010286b <begin_op+0x2a>
      sleep(&log, &log.lock);
80102856:	83 ec 08             	sub    $0x8,%esp
80102859:	68 e0 16 13 80       	push   $0x801316e0
8010285e:	68 e0 16 13 80       	push   $0x801316e0
80102863:	e8 c5 0e 00 00       	call   8010372d <sleep>
80102868:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
8010286b:	83 3d 20 17 13 80 00 	cmpl   $0x0,0x80131720
80102872:	75 e2                	jne    80102856 <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80102874:	a1 1c 17 13 80       	mov    0x8013171c,%eax
80102879:	83 c0 01             	add    $0x1,%eax
8010287c:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010287f:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
80102882:	03 15 28 17 13 80    	add    0x80131728,%edx
80102888:	83 fa 1e             	cmp    $0x1e,%edx
8010288b:	7e 17                	jle    801028a4 <begin_op+0x63>
      sleep(&log, &log.lock);
8010288d:	83 ec 08             	sub    $0x8,%esp
80102890:	68 e0 16 13 80       	push   $0x801316e0
80102895:	68 e0 16 13 80       	push   $0x801316e0
8010289a:	e8 8e 0e 00 00       	call   8010372d <sleep>
8010289f:	83 c4 10             	add    $0x10,%esp
801028a2:	eb c7                	jmp    8010286b <begin_op+0x2a>
      log.outstanding += 1;
801028a4:	a3 1c 17 13 80       	mov    %eax,0x8013171c
      release(&log.lock);
801028a9:	83 ec 0c             	sub    $0xc,%esp
801028ac:	68 e0 16 13 80       	push   $0x801316e0
801028b1:	e8 d7 13 00 00       	call   80103c8d <release>
}
801028b6:	83 c4 10             	add    $0x10,%esp
801028b9:	c9                   	leave  
801028ba:	c3                   	ret    

801028bb <end_op>:
{
801028bb:	55                   	push   %ebp
801028bc:	89 e5                	mov    %esp,%ebp
801028be:	53                   	push   %ebx
801028bf:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
801028c2:	68 e0 16 13 80       	push   $0x801316e0
801028c7:	e8 5c 13 00 00       	call   80103c28 <acquire>
  log.outstanding -= 1;
801028cc:	a1 1c 17 13 80       	mov    0x8013171c,%eax
801028d1:	83 e8 01             	sub    $0x1,%eax
801028d4:	a3 1c 17 13 80       	mov    %eax,0x8013171c
  if(log.committing)
801028d9:	8b 1d 20 17 13 80    	mov    0x80131720,%ebx
801028df:	83 c4 10             	add    $0x10,%esp
801028e2:	85 db                	test   %ebx,%ebx
801028e4:	75 2c                	jne    80102912 <end_op+0x57>
  if(log.outstanding == 0){
801028e6:	85 c0                	test   %eax,%eax
801028e8:	75 35                	jne    8010291f <end_op+0x64>
    log.committing = 1;
801028ea:	c7 05 20 17 13 80 01 	movl   $0x1,0x80131720
801028f1:	00 00 00 
    do_commit = 1;
801028f4:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
801028f9:	83 ec 0c             	sub    $0xc,%esp
801028fc:	68 e0 16 13 80       	push   $0x801316e0
80102901:	e8 87 13 00 00       	call   80103c8d <release>
  if(do_commit){
80102906:	83 c4 10             	add    $0x10,%esp
80102909:	85 db                	test   %ebx,%ebx
8010290b:	75 24                	jne    80102931 <end_op+0x76>
}
8010290d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102910:	c9                   	leave  
80102911:	c3                   	ret    
    panic("log.committing");
80102912:	83 ec 0c             	sub    $0xc,%esp
80102915:	68 c4 69 10 80       	push   $0x801069c4
8010291a:	e8 29 da ff ff       	call   80100348 <panic>
    wakeup(&log);
8010291f:	83 ec 0c             	sub    $0xc,%esp
80102922:	68 e0 16 13 80       	push   $0x801316e0
80102927:	e8 66 0f 00 00       	call   80103892 <wakeup>
8010292c:	83 c4 10             	add    $0x10,%esp
8010292f:	eb c8                	jmp    801028f9 <end_op+0x3e>
    commit();
80102931:	e8 91 fe ff ff       	call   801027c7 <commit>
    acquire(&log.lock);
80102936:	83 ec 0c             	sub    $0xc,%esp
80102939:	68 e0 16 13 80       	push   $0x801316e0
8010293e:	e8 e5 12 00 00       	call   80103c28 <acquire>
    log.committing = 0;
80102943:	c7 05 20 17 13 80 00 	movl   $0x0,0x80131720
8010294a:	00 00 00 
    wakeup(&log);
8010294d:	c7 04 24 e0 16 13 80 	movl   $0x801316e0,(%esp)
80102954:	e8 39 0f 00 00       	call   80103892 <wakeup>
    release(&log.lock);
80102959:	c7 04 24 e0 16 13 80 	movl   $0x801316e0,(%esp)
80102960:	e8 28 13 00 00       	call   80103c8d <release>
80102965:	83 c4 10             	add    $0x10,%esp
}
80102968:	eb a3                	jmp    8010290d <end_op+0x52>

8010296a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
8010296a:	55                   	push   %ebp
8010296b:	89 e5                	mov    %esp,%ebp
8010296d:	53                   	push   %ebx
8010296e:	83 ec 04             	sub    $0x4,%esp
80102971:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80102974:	8b 15 28 17 13 80    	mov    0x80131728,%edx
8010297a:	83 fa 1d             	cmp    $0x1d,%edx
8010297d:	7f 45                	jg     801029c4 <log_write+0x5a>
8010297f:	a1 18 17 13 80       	mov    0x80131718,%eax
80102984:	83 e8 01             	sub    $0x1,%eax
80102987:	39 c2                	cmp    %eax,%edx
80102989:	7d 39                	jge    801029c4 <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
8010298b:	83 3d 1c 17 13 80 00 	cmpl   $0x0,0x8013171c
80102992:	7e 3d                	jle    801029d1 <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102994:	83 ec 0c             	sub    $0xc,%esp
80102997:	68 e0 16 13 80       	push   $0x801316e0
8010299c:	e8 87 12 00 00       	call   80103c28 <acquire>
  for (i = 0; i < log.lh.n; i++) {
801029a1:	83 c4 10             	add    $0x10,%esp
801029a4:	b8 00 00 00 00       	mov    $0x0,%eax
801029a9:	8b 15 28 17 13 80    	mov    0x80131728,%edx
801029af:	39 c2                	cmp    %eax,%edx
801029b1:	7e 2b                	jle    801029de <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
801029b3:	8b 4b 08             	mov    0x8(%ebx),%ecx
801029b6:	39 0c 85 2c 17 13 80 	cmp    %ecx,-0x7fece8d4(,%eax,4)
801029bd:	74 1f                	je     801029de <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
801029bf:	83 c0 01             	add    $0x1,%eax
801029c2:	eb e5                	jmp    801029a9 <log_write+0x3f>
    panic("too big a transaction");
801029c4:	83 ec 0c             	sub    $0xc,%esp
801029c7:	68 d3 69 10 80       	push   $0x801069d3
801029cc:	e8 77 d9 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
801029d1:	83 ec 0c             	sub    $0xc,%esp
801029d4:	68 e9 69 10 80       	push   $0x801069e9
801029d9:	e8 6a d9 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
801029de:	8b 4b 08             	mov    0x8(%ebx),%ecx
801029e1:	89 0c 85 2c 17 13 80 	mov    %ecx,-0x7fece8d4(,%eax,4)
  if (i == log.lh.n)
801029e8:	39 c2                	cmp    %eax,%edx
801029ea:	74 18                	je     80102a04 <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
801029ec:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
801029ef:	83 ec 0c             	sub    $0xc,%esp
801029f2:	68 e0 16 13 80       	push   $0x801316e0
801029f7:	e8 91 12 00 00       	call   80103c8d <release>
}
801029fc:	83 c4 10             	add    $0x10,%esp
801029ff:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a02:	c9                   	leave  
80102a03:	c3                   	ret    
    log.lh.n++;
80102a04:	83 c2 01             	add    $0x1,%edx
80102a07:	89 15 28 17 13 80    	mov    %edx,0x80131728
80102a0d:	eb dd                	jmp    801029ec <log_write+0x82>

80102a0f <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102a0f:	55                   	push   %ebp
80102a10:	89 e5                	mov    %esp,%ebp
80102a12:	53                   	push   %ebx
80102a13:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102a16:	68 8a 00 00 00       	push   $0x8a
80102a1b:	68 8c 94 10 80       	push   $0x8010948c
80102a20:	68 00 70 00 80       	push   $0x80007000
80102a25:	e8 25 13 00 00       	call   80103d4f <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102a2a:	83 c4 10             	add    $0x10,%esp
80102a2d:	bb e0 17 13 80       	mov    $0x801317e0,%ebx
80102a32:	eb 06                	jmp    80102a3a <startothers+0x2b>
80102a34:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102a3a:	69 05 60 1d 13 80 b0 	imul   $0xb0,0x80131d60,%eax
80102a41:	00 00 00 
80102a44:	05 e0 17 13 80       	add    $0x801317e0,%eax
80102a49:	39 d8                	cmp    %ebx,%eax
80102a4b:	76 4c                	jbe    80102a99 <startothers+0x8a>
    if(c == mycpu())  // We've started already.
80102a4d:	e8 c0 07 00 00       	call   80103212 <mycpu>
80102a52:	39 d8                	cmp    %ebx,%eax
80102a54:	74 de                	je     80102a34 <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80102a56:	e8 60 f6 ff ff       	call   801020bb <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102a5b:	05 00 10 00 00       	add    $0x1000,%eax
80102a60:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102a65:	c7 05 f8 6f 00 80 dd 	movl   $0x80102add,0x80006ff8
80102a6c:	2a 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102a6f:	c7 05 f4 6f 00 80 00 	movl   $0x108000,0x80006ff4
80102a76:	80 10 00 

    lapicstartap(c->apicid, V2P(code));
80102a79:	83 ec 08             	sub    $0x8,%esp
80102a7c:	68 00 70 00 00       	push   $0x7000
80102a81:	0f b6 03             	movzbl (%ebx),%eax
80102a84:	50                   	push   %eax
80102a85:	e8 c6 f9 ff ff       	call   80102450 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102a8a:	83 c4 10             	add    $0x10,%esp
80102a8d:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102a93:	85 c0                	test   %eax,%eax
80102a95:	74 f6                	je     80102a8d <startothers+0x7e>
80102a97:	eb 9b                	jmp    80102a34 <startothers+0x25>
      ;
  }
}
80102a99:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a9c:	c9                   	leave  
80102a9d:	c3                   	ret    

80102a9e <mpmain>:
{
80102a9e:	55                   	push   %ebp
80102a9f:	89 e5                	mov    %esp,%ebp
80102aa1:	53                   	push   %ebx
80102aa2:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102aa5:	e8 c4 07 00 00       	call   8010326e <cpuid>
80102aaa:	89 c3                	mov    %eax,%ebx
80102aac:	e8 bd 07 00 00       	call   8010326e <cpuid>
80102ab1:	83 ec 04             	sub    $0x4,%esp
80102ab4:	53                   	push   %ebx
80102ab5:	50                   	push   %eax
80102ab6:	68 04 6a 10 80       	push   $0x80106a04
80102abb:	e8 4b db ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102ac0:	e8 e1 23 00 00       	call   80104ea6 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102ac5:	e8 48 07 00 00       	call   80103212 <mycpu>
80102aca:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102acc:	b8 01 00 00 00       	mov    $0x1,%eax
80102ad1:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102ad8:	e8 2b 0a 00 00       	call   80103508 <scheduler>

80102add <mpenter>:
{
80102add:	55                   	push   %ebp
80102ade:	89 e5                	mov    %esp,%ebp
80102ae0:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102ae3:	e8 c7 33 00 00       	call   80105eaf <switchkvm>
  seginit();
80102ae8:	e8 76 32 00 00       	call   80105d63 <seginit>
  lapicinit();
80102aed:	e8 15 f8 ff ff       	call   80102307 <lapicinit>
  mpmain();
80102af2:	e8 a7 ff ff ff       	call   80102a9e <mpmain>

80102af7 <main>:
{
80102af7:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102afb:	83 e4 f0             	and    $0xfffffff0,%esp
80102afe:	ff 71 fc             	pushl  -0x4(%ecx)
80102b01:	55                   	push   %ebp
80102b02:	89 e5                	mov    %esp,%ebp
80102b04:	51                   	push   %ecx
80102b05:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102b08:	68 00 00 40 80       	push   $0x80400000
80102b0d:	68 08 45 13 80       	push   $0x80134508
80102b12:	e8 52 f5 ff ff       	call   80102069 <kinit1>
  kvmalloc();      // kernel page table
80102b17:	e8 20 38 00 00       	call   8010633c <kvmalloc>
  mpinit();        // detect other processors
80102b1c:	e8 c9 01 00 00       	call   80102cea <mpinit>
  lapicinit();     // interrupt controller
80102b21:	e8 e1 f7 ff ff       	call   80102307 <lapicinit>
  seginit();       // segment descriptors
80102b26:	e8 38 32 00 00       	call   80105d63 <seginit>
  picinit();       // disable pic
80102b2b:	e8 82 02 00 00       	call   80102db2 <picinit>
  ioapicinit();    // another interrupt controller
80102b30:	e8 c5 f3 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102b35:	e8 54 dd ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102b3a:	e8 15 26 00 00       	call   80105154 <uartinit>
  pinit();         // process table
80102b3f:	e8 b4 06 00 00       	call   801031f8 <pinit>
  tvinit();        // trap vectors
80102b44:	e8 ac 22 00 00       	call   80104df5 <tvinit>
  binit();         // buffer cache
80102b49:	e8 a6 d5 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102b4e:	e8 c0 e0 ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102b53:	e8 a8 f1 ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102b58:	e8 b2 fe ff ff       	call   80102a0f <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102b5d:	83 c4 08             	add    $0x8,%esp
80102b60:	68 00 00 00 8e       	push   $0x8e000000
80102b65:	68 00 00 40 80       	push   $0x80400000
80102b6a:	e8 2c f5 ff ff       	call   8010209b <kinit2>
  userinit();      // first user process
80102b6f:	e8 39 07 00 00       	call   801032ad <userinit>
  mpmain();        // finish this processor's setup
80102b74:	e8 25 ff ff ff       	call   80102a9e <mpmain>

80102b79 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102b79:	55                   	push   %ebp
80102b7a:	89 e5                	mov    %esp,%ebp
80102b7c:	56                   	push   %esi
80102b7d:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102b7e:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102b83:	b9 00 00 00 00       	mov    $0x0,%ecx
80102b88:	eb 09                	jmp    80102b93 <sum+0x1a>
    sum += addr[i];
80102b8a:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102b8e:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102b90:	83 c1 01             	add    $0x1,%ecx
80102b93:	39 d1                	cmp    %edx,%ecx
80102b95:	7c f3                	jl     80102b8a <sum+0x11>
  return sum;
}
80102b97:	89 d8                	mov    %ebx,%eax
80102b99:	5b                   	pop    %ebx
80102b9a:	5e                   	pop    %esi
80102b9b:	5d                   	pop    %ebp
80102b9c:	c3                   	ret    

80102b9d <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102b9d:	55                   	push   %ebp
80102b9e:	89 e5                	mov    %esp,%ebp
80102ba0:	56                   	push   %esi
80102ba1:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102ba2:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102ba8:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102baa:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102bac:	eb 03                	jmp    80102bb1 <mpsearch1+0x14>
80102bae:	83 c3 10             	add    $0x10,%ebx
80102bb1:	39 f3                	cmp    %esi,%ebx
80102bb3:	73 29                	jae    80102bde <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102bb5:	83 ec 04             	sub    $0x4,%esp
80102bb8:	6a 04                	push   $0x4
80102bba:	68 18 6a 10 80       	push   $0x80106a18
80102bbf:	53                   	push   %ebx
80102bc0:	e8 55 11 00 00       	call   80103d1a <memcmp>
80102bc5:	83 c4 10             	add    $0x10,%esp
80102bc8:	85 c0                	test   %eax,%eax
80102bca:	75 e2                	jne    80102bae <mpsearch1+0x11>
80102bcc:	ba 10 00 00 00       	mov    $0x10,%edx
80102bd1:	89 d8                	mov    %ebx,%eax
80102bd3:	e8 a1 ff ff ff       	call   80102b79 <sum>
80102bd8:	84 c0                	test   %al,%al
80102bda:	75 d2                	jne    80102bae <mpsearch1+0x11>
80102bdc:	eb 05                	jmp    80102be3 <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102bde:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102be3:	89 d8                	mov    %ebx,%eax
80102be5:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102be8:	5b                   	pop    %ebx
80102be9:	5e                   	pop    %esi
80102bea:	5d                   	pop    %ebp
80102beb:	c3                   	ret    

80102bec <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102bec:	55                   	push   %ebp
80102bed:	89 e5                	mov    %esp,%ebp
80102bef:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102bf2:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102bf9:	c1 e0 08             	shl    $0x8,%eax
80102bfc:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102c03:	09 d0                	or     %edx,%eax
80102c05:	c1 e0 04             	shl    $0x4,%eax
80102c08:	85 c0                	test   %eax,%eax
80102c0a:	74 1f                	je     80102c2b <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102c0c:	ba 00 04 00 00       	mov    $0x400,%edx
80102c11:	e8 87 ff ff ff       	call   80102b9d <mpsearch1>
80102c16:	85 c0                	test   %eax,%eax
80102c18:	75 0f                	jne    80102c29 <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102c1a:	ba 00 00 01 00       	mov    $0x10000,%edx
80102c1f:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102c24:	e8 74 ff ff ff       	call   80102b9d <mpsearch1>
}
80102c29:	c9                   	leave  
80102c2a:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102c2b:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102c32:	c1 e0 08             	shl    $0x8,%eax
80102c35:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102c3c:	09 d0                	or     %edx,%eax
80102c3e:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102c41:	2d 00 04 00 00       	sub    $0x400,%eax
80102c46:	ba 00 04 00 00       	mov    $0x400,%edx
80102c4b:	e8 4d ff ff ff       	call   80102b9d <mpsearch1>
80102c50:	85 c0                	test   %eax,%eax
80102c52:	75 d5                	jne    80102c29 <mpsearch+0x3d>
80102c54:	eb c4                	jmp    80102c1a <mpsearch+0x2e>

80102c56 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102c56:	55                   	push   %ebp
80102c57:	89 e5                	mov    %esp,%ebp
80102c59:	57                   	push   %edi
80102c5a:	56                   	push   %esi
80102c5b:	53                   	push   %ebx
80102c5c:	83 ec 1c             	sub    $0x1c,%esp
80102c5f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102c62:	e8 85 ff ff ff       	call   80102bec <mpsearch>
80102c67:	85 c0                	test   %eax,%eax
80102c69:	74 5c                	je     80102cc7 <mpconfig+0x71>
80102c6b:	89 c7                	mov    %eax,%edi
80102c6d:	8b 58 04             	mov    0x4(%eax),%ebx
80102c70:	85 db                	test   %ebx,%ebx
80102c72:	74 5a                	je     80102cce <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102c74:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102c7a:	83 ec 04             	sub    $0x4,%esp
80102c7d:	6a 04                	push   $0x4
80102c7f:	68 1d 6a 10 80       	push   $0x80106a1d
80102c84:	56                   	push   %esi
80102c85:	e8 90 10 00 00       	call   80103d1a <memcmp>
80102c8a:	83 c4 10             	add    $0x10,%esp
80102c8d:	85 c0                	test   %eax,%eax
80102c8f:	75 44                	jne    80102cd5 <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102c91:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102c98:	3c 01                	cmp    $0x1,%al
80102c9a:	0f 95 c2             	setne  %dl
80102c9d:	3c 04                	cmp    $0x4,%al
80102c9f:	0f 95 c0             	setne  %al
80102ca2:	84 c2                	test   %al,%dl
80102ca4:	75 36                	jne    80102cdc <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102ca6:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102cad:	89 f0                	mov    %esi,%eax
80102caf:	e8 c5 fe ff ff       	call   80102b79 <sum>
80102cb4:	84 c0                	test   %al,%al
80102cb6:	75 2b                	jne    80102ce3 <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102cb8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102cbb:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102cbd:	89 f0                	mov    %esi,%eax
80102cbf:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102cc2:	5b                   	pop    %ebx
80102cc3:	5e                   	pop    %esi
80102cc4:	5f                   	pop    %edi
80102cc5:	5d                   	pop    %ebp
80102cc6:	c3                   	ret    
    return 0;
80102cc7:	be 00 00 00 00       	mov    $0x0,%esi
80102ccc:	eb ef                	jmp    80102cbd <mpconfig+0x67>
80102cce:	be 00 00 00 00       	mov    $0x0,%esi
80102cd3:	eb e8                	jmp    80102cbd <mpconfig+0x67>
    return 0;
80102cd5:	be 00 00 00 00       	mov    $0x0,%esi
80102cda:	eb e1                	jmp    80102cbd <mpconfig+0x67>
    return 0;
80102cdc:	be 00 00 00 00       	mov    $0x0,%esi
80102ce1:	eb da                	jmp    80102cbd <mpconfig+0x67>
    return 0;
80102ce3:	be 00 00 00 00       	mov    $0x0,%esi
80102ce8:	eb d3                	jmp    80102cbd <mpconfig+0x67>

80102cea <mpinit>:

void
mpinit(void)
{
80102cea:	55                   	push   %ebp
80102ceb:	89 e5                	mov    %esp,%ebp
80102ced:	57                   	push   %edi
80102cee:	56                   	push   %esi
80102cef:	53                   	push   %ebx
80102cf0:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102cf3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102cf6:	e8 5b ff ff ff       	call   80102c56 <mpconfig>
80102cfb:	85 c0                	test   %eax,%eax
80102cfd:	74 19                	je     80102d18 <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102cff:	8b 50 24             	mov    0x24(%eax),%edx
80102d02:	89 15 c4 16 13 80    	mov    %edx,0x801316c4
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d08:	8d 50 2c             	lea    0x2c(%eax),%edx
80102d0b:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102d0f:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102d11:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d16:	eb 34                	jmp    80102d4c <mpinit+0x62>
    panic("Expect to run on an SMP");
80102d18:	83 ec 0c             	sub    $0xc,%esp
80102d1b:	68 22 6a 10 80       	push   $0x80106a22
80102d20:	e8 23 d6 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102d25:	8b 35 60 1d 13 80    	mov    0x80131d60,%esi
80102d2b:	83 fe 07             	cmp    $0x7,%esi
80102d2e:	7f 19                	jg     80102d49 <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102d30:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102d34:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102d3a:	88 87 e0 17 13 80    	mov    %al,-0x7fece820(%edi)
        ncpu++;
80102d40:	83 c6 01             	add    $0x1,%esi
80102d43:	89 35 60 1d 13 80    	mov    %esi,0x80131d60
      }
      p += sizeof(struct mpproc);
80102d49:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d4c:	39 ca                	cmp    %ecx,%edx
80102d4e:	73 2b                	jae    80102d7b <mpinit+0x91>
    switch(*p){
80102d50:	0f b6 02             	movzbl (%edx),%eax
80102d53:	3c 04                	cmp    $0x4,%al
80102d55:	77 1d                	ja     80102d74 <mpinit+0x8a>
80102d57:	0f b6 c0             	movzbl %al,%eax
80102d5a:	ff 24 85 5c 6a 10 80 	jmp    *-0x7fef95a4(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102d61:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102d65:	a2 c0 17 13 80       	mov    %al,0x801317c0
      p += sizeof(struct mpioapic);
80102d6a:	83 c2 08             	add    $0x8,%edx
      continue;
80102d6d:	eb dd                	jmp    80102d4c <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102d6f:	83 c2 08             	add    $0x8,%edx
      continue;
80102d72:	eb d8                	jmp    80102d4c <mpinit+0x62>
    default:
      ismp = 0;
80102d74:	bb 00 00 00 00       	mov    $0x0,%ebx
80102d79:	eb d1                	jmp    80102d4c <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102d7b:	85 db                	test   %ebx,%ebx
80102d7d:	74 26                	je     80102da5 <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102d7f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102d82:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102d86:	74 15                	je     80102d9d <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102d88:	b8 70 00 00 00       	mov    $0x70,%eax
80102d8d:	ba 22 00 00 00       	mov    $0x22,%edx
80102d92:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102d93:	ba 23 00 00 00       	mov    $0x23,%edx
80102d98:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102d99:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102d9c:	ee                   	out    %al,(%dx)
  }
}
80102d9d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102da0:	5b                   	pop    %ebx
80102da1:	5e                   	pop    %esi
80102da2:	5f                   	pop    %edi
80102da3:	5d                   	pop    %ebp
80102da4:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102da5:	83 ec 0c             	sub    $0xc,%esp
80102da8:	68 3c 6a 10 80       	push   $0x80106a3c
80102dad:	e8 96 d5 ff ff       	call   80100348 <panic>

80102db2 <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102db2:	55                   	push   %ebp
80102db3:	89 e5                	mov    %esp,%ebp
80102db5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102dba:	ba 21 00 00 00       	mov    $0x21,%edx
80102dbf:	ee                   	out    %al,(%dx)
80102dc0:	ba a1 00 00 00       	mov    $0xa1,%edx
80102dc5:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102dc6:	5d                   	pop    %ebp
80102dc7:	c3                   	ret    

80102dc8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102dc8:	55                   	push   %ebp
80102dc9:	89 e5                	mov    %esp,%ebp
80102dcb:	57                   	push   %edi
80102dcc:	56                   	push   %esi
80102dcd:	53                   	push   %ebx
80102dce:	83 ec 0c             	sub    $0xc,%esp
80102dd1:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102dd4:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102dd7:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102ddd:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102de3:	e8 45 de ff ff       	call   80100c2d <filealloc>
80102de8:	89 03                	mov    %eax,(%ebx)
80102dea:	85 c0                	test   %eax,%eax
80102dec:	74 16                	je     80102e04 <pipealloc+0x3c>
80102dee:	e8 3a de ff ff       	call   80100c2d <filealloc>
80102df3:	89 06                	mov    %eax,(%esi)
80102df5:	85 c0                	test   %eax,%eax
80102df7:	74 0b                	je     80102e04 <pipealloc+0x3c>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80102df9:	e8 bd f2 ff ff       	call   801020bb <kalloc>
80102dfe:	89 c7                	mov    %eax,%edi
80102e00:	85 c0                	test   %eax,%eax
80102e02:	75 35                	jne    80102e39 <pipealloc+0x71>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102e04:	8b 03                	mov    (%ebx),%eax
80102e06:	85 c0                	test   %eax,%eax
80102e08:	74 0c                	je     80102e16 <pipealloc+0x4e>
    fileclose(*f0);
80102e0a:	83 ec 0c             	sub    $0xc,%esp
80102e0d:	50                   	push   %eax
80102e0e:	e8 c0 de ff ff       	call   80100cd3 <fileclose>
80102e13:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102e16:	8b 06                	mov    (%esi),%eax
80102e18:	85 c0                	test   %eax,%eax
80102e1a:	0f 84 8b 00 00 00    	je     80102eab <pipealloc+0xe3>
    fileclose(*f1);
80102e20:	83 ec 0c             	sub    $0xc,%esp
80102e23:	50                   	push   %eax
80102e24:	e8 aa de ff ff       	call   80100cd3 <fileclose>
80102e29:	83 c4 10             	add    $0x10,%esp
  return -1;
80102e2c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102e31:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102e34:	5b                   	pop    %ebx
80102e35:	5e                   	pop    %esi
80102e36:	5f                   	pop    %edi
80102e37:	5d                   	pop    %ebp
80102e38:	c3                   	ret    
  p->readopen = 1;
80102e39:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102e40:	00 00 00 
  p->writeopen = 1;
80102e43:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102e4a:	00 00 00 
  p->nwrite = 0;
80102e4d:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102e54:	00 00 00 
  p->nread = 0;
80102e57:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102e5e:	00 00 00 
  initlock(&p->lock, "pipe");
80102e61:	83 ec 08             	sub    $0x8,%esp
80102e64:	68 70 6a 10 80       	push   $0x80106a70
80102e69:	50                   	push   %eax
80102e6a:	e8 7d 0c 00 00       	call   80103aec <initlock>
  (*f0)->type = FD_PIPE;
80102e6f:	8b 03                	mov    (%ebx),%eax
80102e71:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102e77:	8b 03                	mov    (%ebx),%eax
80102e79:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102e7d:	8b 03                	mov    (%ebx),%eax
80102e7f:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102e83:	8b 03                	mov    (%ebx),%eax
80102e85:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80102e88:	8b 06                	mov    (%esi),%eax
80102e8a:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80102e90:	8b 06                	mov    (%esi),%eax
80102e92:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80102e96:	8b 06                	mov    (%esi),%eax
80102e98:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80102e9c:	8b 06                	mov    (%esi),%eax
80102e9e:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80102ea1:	83 c4 10             	add    $0x10,%esp
80102ea4:	b8 00 00 00 00       	mov    $0x0,%eax
80102ea9:	eb 86                	jmp    80102e31 <pipealloc+0x69>
  return -1;
80102eab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102eb0:	e9 7c ff ff ff       	jmp    80102e31 <pipealloc+0x69>

80102eb5 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80102eb5:	55                   	push   %ebp
80102eb6:	89 e5                	mov    %esp,%ebp
80102eb8:	53                   	push   %ebx
80102eb9:	83 ec 10             	sub    $0x10,%esp
80102ebc:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80102ebf:	53                   	push   %ebx
80102ec0:	e8 63 0d 00 00       	call   80103c28 <acquire>
  if(writable){
80102ec5:	83 c4 10             	add    $0x10,%esp
80102ec8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102ecc:	74 3f                	je     80102f0d <pipeclose+0x58>
    p->writeopen = 0;
80102ece:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80102ed5:	00 00 00 
    wakeup(&p->nread);
80102ed8:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102ede:	83 ec 0c             	sub    $0xc,%esp
80102ee1:	50                   	push   %eax
80102ee2:	e8 ab 09 00 00       	call   80103892 <wakeup>
80102ee7:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80102eea:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102ef1:	75 09                	jne    80102efc <pipeclose+0x47>
80102ef3:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80102efa:	74 2f                	je     80102f2b <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80102efc:	83 ec 0c             	sub    $0xc,%esp
80102eff:	53                   	push   %ebx
80102f00:	e8 88 0d 00 00       	call   80103c8d <release>
80102f05:	83 c4 10             	add    $0x10,%esp
}
80102f08:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102f0b:	c9                   	leave  
80102f0c:	c3                   	ret    
    p->readopen = 0;
80102f0d:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
80102f14:	00 00 00 
    wakeup(&p->nwrite);
80102f17:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102f1d:	83 ec 0c             	sub    $0xc,%esp
80102f20:	50                   	push   %eax
80102f21:	e8 6c 09 00 00       	call   80103892 <wakeup>
80102f26:	83 c4 10             	add    $0x10,%esp
80102f29:	eb bf                	jmp    80102eea <pipeclose+0x35>
    release(&p->lock);
80102f2b:	83 ec 0c             	sub    $0xc,%esp
80102f2e:	53                   	push   %ebx
80102f2f:	e8 59 0d 00 00       	call   80103c8d <release>
    kfree((char*)p);
80102f34:	89 1c 24             	mov    %ebx,(%esp)
80102f37:	e8 68 f0 ff ff       	call   80101fa4 <kfree>
80102f3c:	83 c4 10             	add    $0x10,%esp
80102f3f:	eb c7                	jmp    80102f08 <pipeclose+0x53>

80102f41 <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
80102f41:	55                   	push   %ebp
80102f42:	89 e5                	mov    %esp,%ebp
80102f44:	57                   	push   %edi
80102f45:	56                   	push   %esi
80102f46:	53                   	push   %ebx
80102f47:	83 ec 18             	sub    $0x18,%esp
80102f4a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80102f4d:	89 de                	mov    %ebx,%esi
80102f4f:	53                   	push   %ebx
80102f50:	e8 d3 0c 00 00       	call   80103c28 <acquire>
  for(i = 0; i < n; i++){
80102f55:	83 c4 10             	add    $0x10,%esp
80102f58:	bf 00 00 00 00       	mov    $0x0,%edi
80102f5d:	3b 7d 10             	cmp    0x10(%ebp),%edi
80102f60:	0f 8d 88 00 00 00    	jge    80102fee <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80102f66:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
80102f6c:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80102f72:	05 00 02 00 00       	add    $0x200,%eax
80102f77:	39 c2                	cmp    %eax,%edx
80102f79:	75 51                	jne    80102fcc <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
80102f7b:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102f82:	74 2f                	je     80102fb3 <pipewrite+0x72>
80102f84:	e8 00 03 00 00       	call   80103289 <myproc>
80102f89:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80102f8d:	75 24                	jne    80102fb3 <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
80102f8f:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102f95:	83 ec 0c             	sub    $0xc,%esp
80102f98:	50                   	push   %eax
80102f99:	e8 f4 08 00 00       	call   80103892 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80102f9e:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102fa4:	83 c4 08             	add    $0x8,%esp
80102fa7:	56                   	push   %esi
80102fa8:	50                   	push   %eax
80102fa9:	e8 7f 07 00 00       	call   8010372d <sleep>
80102fae:	83 c4 10             	add    $0x10,%esp
80102fb1:	eb b3                	jmp    80102f66 <pipewrite+0x25>
        release(&p->lock);
80102fb3:	83 ec 0c             	sub    $0xc,%esp
80102fb6:	53                   	push   %ebx
80102fb7:	e8 d1 0c 00 00       	call   80103c8d <release>
        return -1;
80102fbc:	83 c4 10             	add    $0x10,%esp
80102fbf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
80102fc4:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102fc7:	5b                   	pop    %ebx
80102fc8:	5e                   	pop    %esi
80102fc9:	5f                   	pop    %edi
80102fca:	5d                   	pop    %ebp
80102fcb:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80102fcc:	8d 42 01             	lea    0x1(%edx),%eax
80102fcf:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80102fd5:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102fdb:	8b 45 0c             	mov    0xc(%ebp),%eax
80102fde:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
80102fe2:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
80102fe6:	83 c7 01             	add    $0x1,%edi
80102fe9:	e9 6f ff ff ff       	jmp    80102f5d <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80102fee:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102ff4:	83 ec 0c             	sub    $0xc,%esp
80102ff7:	50                   	push   %eax
80102ff8:	e8 95 08 00 00       	call   80103892 <wakeup>
  release(&p->lock);
80102ffd:	89 1c 24             	mov    %ebx,(%esp)
80103000:	e8 88 0c 00 00       	call   80103c8d <release>
  return n;
80103005:	83 c4 10             	add    $0x10,%esp
80103008:	8b 45 10             	mov    0x10(%ebp),%eax
8010300b:	eb b7                	jmp    80102fc4 <pipewrite+0x83>

8010300d <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
8010300d:	55                   	push   %ebp
8010300e:	89 e5                	mov    %esp,%ebp
80103010:	57                   	push   %edi
80103011:	56                   	push   %esi
80103012:	53                   	push   %ebx
80103013:	83 ec 18             	sub    $0x18,%esp
80103016:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80103019:	89 df                	mov    %ebx,%edi
8010301b:	53                   	push   %ebx
8010301c:	e8 07 0c 00 00       	call   80103c28 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103021:	83 c4 10             	add    $0x10,%esp
80103024:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
8010302a:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
80103030:	75 3d                	jne    8010306f <piperead+0x62>
80103032:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
80103038:	85 f6                	test   %esi,%esi
8010303a:	74 38                	je     80103074 <piperead+0x67>
    if(myproc()->killed){
8010303c:	e8 48 02 00 00       	call   80103289 <myproc>
80103041:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80103045:	75 15                	jne    8010305c <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80103047:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
8010304d:	83 ec 08             	sub    $0x8,%esp
80103050:	57                   	push   %edi
80103051:	50                   	push   %eax
80103052:	e8 d6 06 00 00       	call   8010372d <sleep>
80103057:	83 c4 10             	add    $0x10,%esp
8010305a:	eb c8                	jmp    80103024 <piperead+0x17>
      release(&p->lock);
8010305c:	83 ec 0c             	sub    $0xc,%esp
8010305f:	53                   	push   %ebx
80103060:	e8 28 0c 00 00       	call   80103c8d <release>
      return -1;
80103065:	83 c4 10             	add    $0x10,%esp
80103068:	be ff ff ff ff       	mov    $0xffffffff,%esi
8010306d:	eb 50                	jmp    801030bf <piperead+0xb2>
8010306f:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103074:	3b 75 10             	cmp    0x10(%ebp),%esi
80103077:	7d 2c                	jge    801030a5 <piperead+0x98>
    if(p->nread == p->nwrite)
80103079:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
8010307f:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
80103085:	74 1e                	je     801030a5 <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80103087:	8d 50 01             	lea    0x1(%eax),%edx
8010308a:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
80103090:	25 ff 01 00 00       	and    $0x1ff,%eax
80103095:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
8010309a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010309d:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801030a0:	83 c6 01             	add    $0x1,%esi
801030a3:	eb cf                	jmp    80103074 <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
801030a5:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
801030ab:	83 ec 0c             	sub    $0xc,%esp
801030ae:	50                   	push   %eax
801030af:	e8 de 07 00 00       	call   80103892 <wakeup>
  release(&p->lock);
801030b4:	89 1c 24             	mov    %ebx,(%esp)
801030b7:	e8 d1 0b 00 00       	call   80103c8d <release>
  return i;
801030bc:	83 c4 10             	add    $0x10,%esp
}
801030bf:	89 f0                	mov    %esi,%eax
801030c1:	8d 65 f4             	lea    -0xc(%ebp),%esp
801030c4:	5b                   	pop    %ebx
801030c5:	5e                   	pop    %esi
801030c6:	5f                   	pop    %edi
801030c7:	5d                   	pop    %ebp
801030c8:	c3                   	ret    

801030c9 <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
801030c9:	55                   	push   %ebp
801030ca:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801030cc:	ba b4 1d 13 80       	mov    $0x80131db4,%edx
801030d1:	eb 03                	jmp    801030d6 <wakeup1+0xd>
801030d3:	83 c2 7c             	add    $0x7c,%edx
801030d6:	81 fa b4 3c 13 80    	cmp    $0x80133cb4,%edx
801030dc:	73 14                	jae    801030f2 <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
801030de:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
801030e2:	75 ef                	jne    801030d3 <wakeup1+0xa>
801030e4:	39 42 20             	cmp    %eax,0x20(%edx)
801030e7:	75 ea                	jne    801030d3 <wakeup1+0xa>
      p->state = RUNNABLE;
801030e9:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
801030f0:	eb e1                	jmp    801030d3 <wakeup1+0xa>
}
801030f2:	5d                   	pop    %ebp
801030f3:	c3                   	ret    

801030f4 <allocproc>:
{
801030f4:	55                   	push   %ebp
801030f5:	89 e5                	mov    %esp,%ebp
801030f7:	53                   	push   %ebx
801030f8:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
801030fb:	68 80 1d 13 80       	push   $0x80131d80
80103100:	e8 23 0b 00 00       	call   80103c28 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103105:	83 c4 10             	add    $0x10,%esp
80103108:	bb b4 1d 13 80       	mov    $0x80131db4,%ebx
8010310d:	81 fb b4 3c 13 80    	cmp    $0x80133cb4,%ebx
80103113:	73 0b                	jae    80103120 <allocproc+0x2c>
    if(p->state == UNUSED)
80103115:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
80103119:	74 1c                	je     80103137 <allocproc+0x43>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010311b:	83 c3 7c             	add    $0x7c,%ebx
8010311e:	eb ed                	jmp    8010310d <allocproc+0x19>
  release(&ptable.lock);
80103120:	83 ec 0c             	sub    $0xc,%esp
80103123:	68 80 1d 13 80       	push   $0x80131d80
80103128:	e8 60 0b 00 00       	call   80103c8d <release>
  return 0;
8010312d:	83 c4 10             	add    $0x10,%esp
80103130:	bb 00 00 00 00       	mov    $0x0,%ebx
80103135:	eb 69                	jmp    801031a0 <allocproc+0xac>
  p->state = EMBRYO;
80103137:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
8010313e:	a1 04 90 10 80       	mov    0x80109004,%eax
80103143:	8d 50 01             	lea    0x1(%eax),%edx
80103146:	89 15 04 90 10 80    	mov    %edx,0x80109004
8010314c:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
8010314f:	83 ec 0c             	sub    $0xc,%esp
80103152:	68 80 1d 13 80       	push   $0x80131d80
80103157:	e8 31 0b 00 00       	call   80103c8d <release>
  if((p->kstack = kalloc()) == 0){
8010315c:	e8 5a ef ff ff       	call   801020bb <kalloc>
80103161:	89 43 08             	mov    %eax,0x8(%ebx)
80103164:	83 c4 10             	add    $0x10,%esp
80103167:	85 c0                	test   %eax,%eax
80103169:	74 3c                	je     801031a7 <allocproc+0xb3>
  sp -= sizeof *p->tf;
8010316b:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
80103171:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
80103174:	c7 80 b0 0f 00 00 ea 	movl   $0x80104dea,0xfb0(%eax)
8010317b:	4d 10 80 
  sp -= sizeof *p->context;
8010317e:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
80103183:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
80103186:	83 ec 04             	sub    $0x4,%esp
80103189:	6a 14                	push   $0x14
8010318b:	6a 00                	push   $0x0
8010318d:	50                   	push   %eax
8010318e:	e8 41 0b 00 00       	call   80103cd4 <memset>
  p->context->eip = (uint)forkret;
80103193:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103196:	c7 40 10 b5 31 10 80 	movl   $0x801031b5,0x10(%eax)
  return p;
8010319d:	83 c4 10             	add    $0x10,%esp
}
801031a0:	89 d8                	mov    %ebx,%eax
801031a2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801031a5:	c9                   	leave  
801031a6:	c3                   	ret    
    p->state = UNUSED;
801031a7:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
801031ae:	bb 00 00 00 00       	mov    $0x0,%ebx
801031b3:	eb eb                	jmp    801031a0 <allocproc+0xac>

801031b5 <forkret>:
{
801031b5:	55                   	push   %ebp
801031b6:	89 e5                	mov    %esp,%ebp
801031b8:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
801031bb:	68 80 1d 13 80       	push   $0x80131d80
801031c0:	e8 c8 0a 00 00       	call   80103c8d <release>
  if (first) {
801031c5:	83 c4 10             	add    $0x10,%esp
801031c8:	83 3d 00 90 10 80 00 	cmpl   $0x0,0x80109000
801031cf:	75 02                	jne    801031d3 <forkret+0x1e>
}
801031d1:	c9                   	leave  
801031d2:	c3                   	ret    
    first = 0;
801031d3:	c7 05 00 90 10 80 00 	movl   $0x0,0x80109000
801031da:	00 00 00 
    iinit(ROOTDEV);
801031dd:	83 ec 0c             	sub    $0xc,%esp
801031e0:	6a 01                	push   $0x1
801031e2:	e8 05 e1 ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
801031e7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801031ee:	e8 05 f6 ff ff       	call   801027f8 <initlog>
801031f3:	83 c4 10             	add    $0x10,%esp
}
801031f6:	eb d9                	jmp    801031d1 <forkret+0x1c>

801031f8 <pinit>:
{
801031f8:	55                   	push   %ebp
801031f9:	89 e5                	mov    %esp,%ebp
801031fb:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
801031fe:	68 75 6a 10 80       	push   $0x80106a75
80103203:	68 80 1d 13 80       	push   $0x80131d80
80103208:	e8 df 08 00 00       	call   80103aec <initlock>
}
8010320d:	83 c4 10             	add    $0x10,%esp
80103210:	c9                   	leave  
80103211:	c3                   	ret    

80103212 <mycpu>:
{
80103212:	55                   	push   %ebp
80103213:	89 e5                	mov    %esp,%ebp
80103215:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103218:	9c                   	pushf  
80103219:	58                   	pop    %eax
  if(readeflags()&FL_IF)
8010321a:	f6 c4 02             	test   $0x2,%ah
8010321d:	75 28                	jne    80103247 <mycpu+0x35>
  apicid = lapicid();
8010321f:	e8 ed f1 ff ff       	call   80102411 <lapicid>
  for (i = 0; i < ncpu; ++i) {
80103224:	ba 00 00 00 00       	mov    $0x0,%edx
80103229:	39 15 60 1d 13 80    	cmp    %edx,0x80131d60
8010322f:	7e 23                	jle    80103254 <mycpu+0x42>
    if (cpus[i].apicid == apicid)
80103231:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
80103237:	0f b6 89 e0 17 13 80 	movzbl -0x7fece820(%ecx),%ecx
8010323e:	39 c1                	cmp    %eax,%ecx
80103240:	74 1f                	je     80103261 <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
80103242:	83 c2 01             	add    $0x1,%edx
80103245:	eb e2                	jmp    80103229 <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
80103247:	83 ec 0c             	sub    $0xc,%esp
8010324a:	68 58 6b 10 80       	push   $0x80106b58
8010324f:	e8 f4 d0 ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
80103254:	83 ec 0c             	sub    $0xc,%esp
80103257:	68 7c 6a 10 80       	push   $0x80106a7c
8010325c:	e8 e7 d0 ff ff       	call   80100348 <panic>
      return &cpus[i];
80103261:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
80103267:	05 e0 17 13 80       	add    $0x801317e0,%eax
}
8010326c:	c9                   	leave  
8010326d:	c3                   	ret    

8010326e <cpuid>:
cpuid() {
8010326e:	55                   	push   %ebp
8010326f:	89 e5                	mov    %esp,%ebp
80103271:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
80103274:	e8 99 ff ff ff       	call   80103212 <mycpu>
80103279:	2d e0 17 13 80       	sub    $0x801317e0,%eax
8010327e:	c1 f8 04             	sar    $0x4,%eax
80103281:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
80103287:	c9                   	leave  
80103288:	c3                   	ret    

80103289 <myproc>:
myproc(void) {
80103289:	55                   	push   %ebp
8010328a:	89 e5                	mov    %esp,%ebp
8010328c:	53                   	push   %ebx
8010328d:	83 ec 04             	sub    $0x4,%esp
  pushcli();
80103290:	e8 b6 08 00 00       	call   80103b4b <pushcli>
  c = mycpu();
80103295:	e8 78 ff ff ff       	call   80103212 <mycpu>
  p = c->proc;
8010329a:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
801032a0:	e8 e3 08 00 00       	call   80103b88 <popcli>
}
801032a5:	89 d8                	mov    %ebx,%eax
801032a7:	83 c4 04             	add    $0x4,%esp
801032aa:	5b                   	pop    %ebx
801032ab:	5d                   	pop    %ebp
801032ac:	c3                   	ret    

801032ad <userinit>:
{
801032ad:	55                   	push   %ebp
801032ae:	89 e5                	mov    %esp,%ebp
801032b0:	53                   	push   %ebx
801032b1:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
801032b4:	e8 3b fe ff ff       	call   801030f4 <allocproc>
801032b9:	89 c3                	mov    %eax,%ebx
  initproc = p;
801032bb:	a3 bc 95 10 80       	mov    %eax,0x801095bc
  if((p->pgdir = setupkvm()) == 0)
801032c0:	e8 09 30 00 00       	call   801062ce <setupkvm>
801032c5:	89 43 04             	mov    %eax,0x4(%ebx)
801032c8:	85 c0                	test   %eax,%eax
801032ca:	0f 84 b7 00 00 00    	je     80103387 <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
801032d0:	83 ec 04             	sub    $0x4,%esp
801032d3:	68 2c 00 00 00       	push   $0x2c
801032d8:	68 60 94 10 80       	push   $0x80109460
801032dd:	50                   	push   %eax
801032de:	e8 f6 2c 00 00       	call   80105fd9 <inituvm>
  p->sz = PGSIZE;
801032e3:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
801032e9:	83 c4 0c             	add    $0xc,%esp
801032ec:	6a 4c                	push   $0x4c
801032ee:	6a 00                	push   $0x0
801032f0:	ff 73 18             	pushl  0x18(%ebx)
801032f3:	e8 dc 09 00 00       	call   80103cd4 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801032f8:	8b 43 18             	mov    0x18(%ebx),%eax
801032fb:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80103301:	8b 43 18             	mov    0x18(%ebx),%eax
80103304:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
8010330a:	8b 43 18             	mov    0x18(%ebx),%eax
8010330d:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
80103311:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80103315:	8b 43 18             	mov    0x18(%ebx),%eax
80103318:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
8010331c:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80103320:	8b 43 18             	mov    0x18(%ebx),%eax
80103323:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
8010332a:	8b 43 18             	mov    0x18(%ebx),%eax
8010332d:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80103334:	8b 43 18             	mov    0x18(%ebx),%eax
80103337:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
8010333e:	8d 43 6c             	lea    0x6c(%ebx),%eax
80103341:	83 c4 0c             	add    $0xc,%esp
80103344:	6a 10                	push   $0x10
80103346:	68 a5 6a 10 80       	push   $0x80106aa5
8010334b:	50                   	push   %eax
8010334c:	e8 ea 0a 00 00       	call   80103e3b <safestrcpy>
  p->cwd = namei("/");
80103351:	c7 04 24 ae 6a 10 80 	movl   $0x80106aae,(%esp)
80103358:	e8 84 e8 ff ff       	call   80101be1 <namei>
8010335d:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
80103360:	c7 04 24 80 1d 13 80 	movl   $0x80131d80,(%esp)
80103367:	e8 bc 08 00 00       	call   80103c28 <acquire>
  p->state = RUNNABLE;
8010336c:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
80103373:	c7 04 24 80 1d 13 80 	movl   $0x80131d80,(%esp)
8010337a:	e8 0e 09 00 00       	call   80103c8d <release>
}
8010337f:	83 c4 10             	add    $0x10,%esp
80103382:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103385:	c9                   	leave  
80103386:	c3                   	ret    
    panic("userinit: out of memory?");
80103387:	83 ec 0c             	sub    $0xc,%esp
8010338a:	68 8c 6a 10 80       	push   $0x80106a8c
8010338f:	e8 b4 cf ff ff       	call   80100348 <panic>

80103394 <growproc>:
{
80103394:	55                   	push   %ebp
80103395:	89 e5                	mov    %esp,%ebp
80103397:	56                   	push   %esi
80103398:	53                   	push   %ebx
80103399:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
8010339c:	e8 e8 fe ff ff       	call   80103289 <myproc>
801033a1:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
801033a3:	8b 00                	mov    (%eax),%eax
  if(n > 0){
801033a5:	85 f6                	test   %esi,%esi
801033a7:	7f 21                	jg     801033ca <growproc+0x36>
  } else if(n < 0){
801033a9:	85 f6                	test   %esi,%esi
801033ab:	79 33                	jns    801033e0 <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
801033ad:	83 ec 04             	sub    $0x4,%esp
801033b0:	01 c6                	add    %eax,%esi
801033b2:	56                   	push   %esi
801033b3:	50                   	push   %eax
801033b4:	ff 73 04             	pushl  0x4(%ebx)
801033b7:	e8 26 2d 00 00       	call   801060e2 <deallocuvm>
801033bc:	83 c4 10             	add    $0x10,%esp
801033bf:	85 c0                	test   %eax,%eax
801033c1:	75 1d                	jne    801033e0 <growproc+0x4c>
      return -1;
801033c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801033c8:	eb 29                	jmp    801033f3 <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
801033ca:	83 ec 04             	sub    $0x4,%esp
801033cd:	01 c6                	add    %eax,%esi
801033cf:	56                   	push   %esi
801033d0:	50                   	push   %eax
801033d1:	ff 73 04             	pushl  0x4(%ebx)
801033d4:	e8 9b 2d 00 00       	call   80106174 <allocuvm>
801033d9:	83 c4 10             	add    $0x10,%esp
801033dc:	85 c0                	test   %eax,%eax
801033de:	74 1a                	je     801033fa <growproc+0x66>
  curproc->sz = sz;
801033e0:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
801033e2:	83 ec 0c             	sub    $0xc,%esp
801033e5:	53                   	push   %ebx
801033e6:	e8 d6 2a 00 00       	call   80105ec1 <switchuvm>
  return 0;
801033eb:	83 c4 10             	add    $0x10,%esp
801033ee:	b8 00 00 00 00       	mov    $0x0,%eax
}
801033f3:	8d 65 f8             	lea    -0x8(%ebp),%esp
801033f6:	5b                   	pop    %ebx
801033f7:	5e                   	pop    %esi
801033f8:	5d                   	pop    %ebp
801033f9:	c3                   	ret    
      return -1;
801033fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801033ff:	eb f2                	jmp    801033f3 <growproc+0x5f>

80103401 <fork>:
{
80103401:	55                   	push   %ebp
80103402:	89 e5                	mov    %esp,%ebp
80103404:	57                   	push   %edi
80103405:	56                   	push   %esi
80103406:	53                   	push   %ebx
80103407:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
8010340a:	e8 7a fe ff ff       	call   80103289 <myproc>
8010340f:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
80103411:	e8 de fc ff ff       	call   801030f4 <allocproc>
80103416:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80103419:	85 c0                	test   %eax,%eax
8010341b:	0f 84 e0 00 00 00    	je     80103501 <fork+0x100>
80103421:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){
80103423:	83 ec 08             	sub    $0x8,%esp
80103426:	ff 33                	pushl  (%ebx)
80103428:	ff 73 04             	pushl  0x4(%ebx)
8010342b:	e8 4f 2f 00 00       	call   8010637f <copyuvm>
80103430:	89 47 04             	mov    %eax,0x4(%edi)
80103433:	83 c4 10             	add    $0x10,%esp
80103436:	85 c0                	test   %eax,%eax
80103438:	74 2a                	je     80103464 <fork+0x63>
  np->sz = curproc->sz;
8010343a:	8b 03                	mov    (%ebx),%eax
8010343c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
8010343f:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
80103441:	89 c8                	mov    %ecx,%eax
80103443:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
80103446:	8b 73 18             	mov    0x18(%ebx),%esi
80103449:	8b 79 18             	mov    0x18(%ecx),%edi
8010344c:	b9 13 00 00 00       	mov    $0x13,%ecx
80103451:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
80103453:	8b 40 18             	mov    0x18(%eax),%eax
80103456:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
8010345d:	be 00 00 00 00       	mov    $0x0,%esi
80103462:	eb 29                	jmp    8010348d <fork+0x8c>
    kfree(np->kstack);
80103464:	83 ec 0c             	sub    $0xc,%esp
80103467:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
8010346a:	ff 73 08             	pushl  0x8(%ebx)
8010346d:	e8 32 eb ff ff       	call   80101fa4 <kfree>
    np->kstack = 0;
80103472:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
80103479:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
80103480:	83 c4 10             	add    $0x10,%esp
80103483:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103488:	eb 6d                	jmp    801034f7 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
8010348a:	83 c6 01             	add    $0x1,%esi
8010348d:	83 fe 0f             	cmp    $0xf,%esi
80103490:	7f 1d                	jg     801034af <fork+0xae>
    if(curproc->ofile[i])
80103492:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
80103496:	85 c0                	test   %eax,%eax
80103498:	74 f0                	je     8010348a <fork+0x89>
      np->ofile[i] = filedup(curproc->ofile[i]);
8010349a:	83 ec 0c             	sub    $0xc,%esp
8010349d:	50                   	push   %eax
8010349e:	e8 eb d7 ff ff       	call   80100c8e <filedup>
801034a3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801034a6:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
801034aa:	83 c4 10             	add    $0x10,%esp
801034ad:	eb db                	jmp    8010348a <fork+0x89>
  np->cwd = idup(curproc->cwd);
801034af:	83 ec 0c             	sub    $0xc,%esp
801034b2:	ff 73 68             	pushl  0x68(%ebx)
801034b5:	e8 97 e0 ff ff       	call   80101551 <idup>
801034ba:	8b 7d e4             	mov    -0x1c(%ebp),%edi
801034bd:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
801034c0:	83 c3 6c             	add    $0x6c,%ebx
801034c3:	8d 47 6c             	lea    0x6c(%edi),%eax
801034c6:	83 c4 0c             	add    $0xc,%esp
801034c9:	6a 10                	push   $0x10
801034cb:	53                   	push   %ebx
801034cc:	50                   	push   %eax
801034cd:	e8 69 09 00 00       	call   80103e3b <safestrcpy>
  pid = np->pid;
801034d2:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
801034d5:	c7 04 24 80 1d 13 80 	movl   $0x80131d80,(%esp)
801034dc:	e8 47 07 00 00       	call   80103c28 <acquire>
  np->state = RUNNABLE;
801034e1:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
801034e8:	c7 04 24 80 1d 13 80 	movl   $0x80131d80,(%esp)
801034ef:	e8 99 07 00 00       	call   80103c8d <release>
  return pid;
801034f4:	83 c4 10             	add    $0x10,%esp
}
801034f7:	89 d8                	mov    %ebx,%eax
801034f9:	8d 65 f4             	lea    -0xc(%ebp),%esp
801034fc:	5b                   	pop    %ebx
801034fd:	5e                   	pop    %esi
801034fe:	5f                   	pop    %edi
801034ff:	5d                   	pop    %ebp
80103500:	c3                   	ret    
    return -1;
80103501:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103506:	eb ef                	jmp    801034f7 <fork+0xf6>

80103508 <scheduler>:
{
80103508:	55                   	push   %ebp
80103509:	89 e5                	mov    %esp,%ebp
8010350b:	56                   	push   %esi
8010350c:	53                   	push   %ebx
  struct cpu *c = mycpu();
8010350d:	e8 00 fd ff ff       	call   80103212 <mycpu>
80103512:	89 c6                	mov    %eax,%esi
  c->proc = 0;
80103514:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
8010351b:	00 00 00 
8010351e:	eb 5a                	jmp    8010357a <scheduler+0x72>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103520:	83 c3 7c             	add    $0x7c,%ebx
80103523:	81 fb b4 3c 13 80    	cmp    $0x80133cb4,%ebx
80103529:	73 3f                	jae    8010356a <scheduler+0x62>
      if(p->state != RUNNABLE)
8010352b:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
8010352f:	75 ef                	jne    80103520 <scheduler+0x18>
      c->proc = p;
80103531:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
80103537:	83 ec 0c             	sub    $0xc,%esp
8010353a:	53                   	push   %ebx
8010353b:	e8 81 29 00 00       	call   80105ec1 <switchuvm>
      p->state = RUNNING;
80103540:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
80103547:	83 c4 08             	add    $0x8,%esp
8010354a:	ff 73 1c             	pushl  0x1c(%ebx)
8010354d:	8d 46 04             	lea    0x4(%esi),%eax
80103550:	50                   	push   %eax
80103551:	e8 38 09 00 00       	call   80103e8e <swtch>
      switchkvm();
80103556:	e8 54 29 00 00       	call   80105eaf <switchkvm>
      c->proc = 0;
8010355b:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
80103562:	00 00 00 
80103565:	83 c4 10             	add    $0x10,%esp
80103568:	eb b6                	jmp    80103520 <scheduler+0x18>
    release(&ptable.lock);
8010356a:	83 ec 0c             	sub    $0xc,%esp
8010356d:	68 80 1d 13 80       	push   $0x80131d80
80103572:	e8 16 07 00 00       	call   80103c8d <release>
    sti();
80103577:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
8010357a:	fb                   	sti    
    acquire(&ptable.lock);
8010357b:	83 ec 0c             	sub    $0xc,%esp
8010357e:	68 80 1d 13 80       	push   $0x80131d80
80103583:	e8 a0 06 00 00       	call   80103c28 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103588:	83 c4 10             	add    $0x10,%esp
8010358b:	bb b4 1d 13 80       	mov    $0x80131db4,%ebx
80103590:	eb 91                	jmp    80103523 <scheduler+0x1b>

80103592 <sched>:
{
80103592:	55                   	push   %ebp
80103593:	89 e5                	mov    %esp,%ebp
80103595:	56                   	push   %esi
80103596:	53                   	push   %ebx
  struct proc *p = myproc();
80103597:	e8 ed fc ff ff       	call   80103289 <myproc>
8010359c:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
8010359e:	83 ec 0c             	sub    $0xc,%esp
801035a1:	68 80 1d 13 80       	push   $0x80131d80
801035a6:	e8 3d 06 00 00       	call   80103be8 <holding>
801035ab:	83 c4 10             	add    $0x10,%esp
801035ae:	85 c0                	test   %eax,%eax
801035b0:	74 4f                	je     80103601 <sched+0x6f>
  if(mycpu()->ncli != 1)
801035b2:	e8 5b fc ff ff       	call   80103212 <mycpu>
801035b7:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
801035be:	75 4e                	jne    8010360e <sched+0x7c>
  if(p->state == RUNNING)
801035c0:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
801035c4:	74 55                	je     8010361b <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801035c6:	9c                   	pushf  
801035c7:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801035c8:	f6 c4 02             	test   $0x2,%ah
801035cb:	75 5b                	jne    80103628 <sched+0x96>
  intena = mycpu()->intena;
801035cd:	e8 40 fc ff ff       	call   80103212 <mycpu>
801035d2:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
801035d8:	e8 35 fc ff ff       	call   80103212 <mycpu>
801035dd:	83 ec 08             	sub    $0x8,%esp
801035e0:	ff 70 04             	pushl  0x4(%eax)
801035e3:	83 c3 1c             	add    $0x1c,%ebx
801035e6:	53                   	push   %ebx
801035e7:	e8 a2 08 00 00       	call   80103e8e <swtch>
  mycpu()->intena = intena;
801035ec:	e8 21 fc ff ff       	call   80103212 <mycpu>
801035f1:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
801035f7:	83 c4 10             	add    $0x10,%esp
801035fa:	8d 65 f8             	lea    -0x8(%ebp),%esp
801035fd:	5b                   	pop    %ebx
801035fe:	5e                   	pop    %esi
801035ff:	5d                   	pop    %ebp
80103600:	c3                   	ret    
    panic("sched ptable.lock");
80103601:	83 ec 0c             	sub    $0xc,%esp
80103604:	68 b0 6a 10 80       	push   $0x80106ab0
80103609:	e8 3a cd ff ff       	call   80100348 <panic>
    panic("sched locks");
8010360e:	83 ec 0c             	sub    $0xc,%esp
80103611:	68 c2 6a 10 80       	push   $0x80106ac2
80103616:	e8 2d cd ff ff       	call   80100348 <panic>
    panic("sched running");
8010361b:	83 ec 0c             	sub    $0xc,%esp
8010361e:	68 ce 6a 10 80       	push   $0x80106ace
80103623:	e8 20 cd ff ff       	call   80100348 <panic>
    panic("sched interruptible");
80103628:	83 ec 0c             	sub    $0xc,%esp
8010362b:	68 dc 6a 10 80       	push   $0x80106adc
80103630:	e8 13 cd ff ff       	call   80100348 <panic>

80103635 <exit>:
{
80103635:	55                   	push   %ebp
80103636:	89 e5                	mov    %esp,%ebp
80103638:	56                   	push   %esi
80103639:	53                   	push   %ebx
  struct proc *curproc = myproc();
8010363a:	e8 4a fc ff ff       	call   80103289 <myproc>
  if(curproc == initproc)
8010363f:	39 05 bc 95 10 80    	cmp    %eax,0x801095bc
80103645:	74 09                	je     80103650 <exit+0x1b>
80103647:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
80103649:	bb 00 00 00 00       	mov    $0x0,%ebx
8010364e:	eb 10                	jmp    80103660 <exit+0x2b>
    panic("init exiting");
80103650:	83 ec 0c             	sub    $0xc,%esp
80103653:	68 f0 6a 10 80       	push   $0x80106af0
80103658:	e8 eb cc ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
8010365d:	83 c3 01             	add    $0x1,%ebx
80103660:	83 fb 0f             	cmp    $0xf,%ebx
80103663:	7f 1e                	jg     80103683 <exit+0x4e>
    if(curproc->ofile[fd]){
80103665:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
80103669:	85 c0                	test   %eax,%eax
8010366b:	74 f0                	je     8010365d <exit+0x28>
      fileclose(curproc->ofile[fd]);
8010366d:	83 ec 0c             	sub    $0xc,%esp
80103670:	50                   	push   %eax
80103671:	e8 5d d6 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
80103676:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
8010367d:	00 
8010367e:	83 c4 10             	add    $0x10,%esp
80103681:	eb da                	jmp    8010365d <exit+0x28>
  begin_op();
80103683:	e8 b9 f1 ff ff       	call   80102841 <begin_op>
  iput(curproc->cwd);
80103688:	83 ec 0c             	sub    $0xc,%esp
8010368b:	ff 76 68             	pushl  0x68(%esi)
8010368e:	e8 f5 df ff ff       	call   80101688 <iput>
  end_op();
80103693:	e8 23 f2 ff ff       	call   801028bb <end_op>
  curproc->cwd = 0;
80103698:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
8010369f:	c7 04 24 80 1d 13 80 	movl   $0x80131d80,(%esp)
801036a6:	e8 7d 05 00 00       	call   80103c28 <acquire>
  wakeup1(curproc->parent);
801036ab:	8b 46 14             	mov    0x14(%esi),%eax
801036ae:	e8 16 fa ff ff       	call   801030c9 <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801036b3:	83 c4 10             	add    $0x10,%esp
801036b6:	bb b4 1d 13 80       	mov    $0x80131db4,%ebx
801036bb:	eb 03                	jmp    801036c0 <exit+0x8b>
801036bd:	83 c3 7c             	add    $0x7c,%ebx
801036c0:	81 fb b4 3c 13 80    	cmp    $0x80133cb4,%ebx
801036c6:	73 1a                	jae    801036e2 <exit+0xad>
    if(p->parent == curproc){
801036c8:	39 73 14             	cmp    %esi,0x14(%ebx)
801036cb:	75 f0                	jne    801036bd <exit+0x88>
      p->parent = initproc;
801036cd:	a1 bc 95 10 80       	mov    0x801095bc,%eax
801036d2:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
801036d5:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
801036d9:	75 e2                	jne    801036bd <exit+0x88>
        wakeup1(initproc);
801036db:	e8 e9 f9 ff ff       	call   801030c9 <wakeup1>
801036e0:	eb db                	jmp    801036bd <exit+0x88>
  curproc->state = ZOMBIE;
801036e2:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
801036e9:	e8 a4 fe ff ff       	call   80103592 <sched>
  panic("zombie exit");
801036ee:	83 ec 0c             	sub    $0xc,%esp
801036f1:	68 fd 6a 10 80       	push   $0x80106afd
801036f6:	e8 4d cc ff ff       	call   80100348 <panic>

801036fb <yield>:
{
801036fb:	55                   	push   %ebp
801036fc:	89 e5                	mov    %esp,%ebp
801036fe:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80103701:	68 80 1d 13 80       	push   $0x80131d80
80103706:	e8 1d 05 00 00       	call   80103c28 <acquire>
  myproc()->state = RUNNABLE;
8010370b:	e8 79 fb ff ff       	call   80103289 <myproc>
80103710:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80103717:	e8 76 fe ff ff       	call   80103592 <sched>
  release(&ptable.lock);
8010371c:	c7 04 24 80 1d 13 80 	movl   $0x80131d80,(%esp)
80103723:	e8 65 05 00 00       	call   80103c8d <release>
}
80103728:	83 c4 10             	add    $0x10,%esp
8010372b:	c9                   	leave  
8010372c:	c3                   	ret    

8010372d <sleep>:
{
8010372d:	55                   	push   %ebp
8010372e:	89 e5                	mov    %esp,%ebp
80103730:	56                   	push   %esi
80103731:	53                   	push   %ebx
80103732:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
80103735:	e8 4f fb ff ff       	call   80103289 <myproc>
  if(p == 0)
8010373a:	85 c0                	test   %eax,%eax
8010373c:	74 66                	je     801037a4 <sleep+0x77>
8010373e:	89 c6                	mov    %eax,%esi
  if(lk == 0)
80103740:	85 db                	test   %ebx,%ebx
80103742:	74 6d                	je     801037b1 <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
80103744:	81 fb 80 1d 13 80    	cmp    $0x80131d80,%ebx
8010374a:	74 18                	je     80103764 <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
8010374c:	83 ec 0c             	sub    $0xc,%esp
8010374f:	68 80 1d 13 80       	push   $0x80131d80
80103754:	e8 cf 04 00 00       	call   80103c28 <acquire>
    release(lk);
80103759:	89 1c 24             	mov    %ebx,(%esp)
8010375c:	e8 2c 05 00 00       	call   80103c8d <release>
80103761:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
80103764:	8b 45 08             	mov    0x8(%ebp),%eax
80103767:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
8010376a:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
80103771:	e8 1c fe ff ff       	call   80103592 <sched>
  p->chan = 0;
80103776:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
8010377d:	81 fb 80 1d 13 80    	cmp    $0x80131d80,%ebx
80103783:	74 18                	je     8010379d <sleep+0x70>
    release(&ptable.lock);
80103785:	83 ec 0c             	sub    $0xc,%esp
80103788:	68 80 1d 13 80       	push   $0x80131d80
8010378d:	e8 fb 04 00 00       	call   80103c8d <release>
    acquire(lk);
80103792:	89 1c 24             	mov    %ebx,(%esp)
80103795:	e8 8e 04 00 00       	call   80103c28 <acquire>
8010379a:	83 c4 10             	add    $0x10,%esp
}
8010379d:	8d 65 f8             	lea    -0x8(%ebp),%esp
801037a0:	5b                   	pop    %ebx
801037a1:	5e                   	pop    %esi
801037a2:	5d                   	pop    %ebp
801037a3:	c3                   	ret    
    panic("sleep");
801037a4:	83 ec 0c             	sub    $0xc,%esp
801037a7:	68 09 6b 10 80       	push   $0x80106b09
801037ac:	e8 97 cb ff ff       	call   80100348 <panic>
    panic("sleep without lk");
801037b1:	83 ec 0c             	sub    $0xc,%esp
801037b4:	68 0f 6b 10 80       	push   $0x80106b0f
801037b9:	e8 8a cb ff ff       	call   80100348 <panic>

801037be <wait>:
{
801037be:	55                   	push   %ebp
801037bf:	89 e5                	mov    %esp,%ebp
801037c1:	56                   	push   %esi
801037c2:	53                   	push   %ebx
  struct proc *curproc = myproc();
801037c3:	e8 c1 fa ff ff       	call   80103289 <myproc>
801037c8:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
801037ca:	83 ec 0c             	sub    $0xc,%esp
801037cd:	68 80 1d 13 80       	push   $0x80131d80
801037d2:	e8 51 04 00 00       	call   80103c28 <acquire>
801037d7:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
801037da:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801037df:	bb b4 1d 13 80       	mov    $0x80131db4,%ebx
801037e4:	eb 5b                	jmp    80103841 <wait+0x83>
        pid = p->pid;
801037e6:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
801037e9:	83 ec 0c             	sub    $0xc,%esp
801037ec:	ff 73 08             	pushl  0x8(%ebx)
801037ef:	e8 b0 e7 ff ff       	call   80101fa4 <kfree>
        p->kstack = 0;
801037f4:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
801037fb:	83 c4 04             	add    $0x4,%esp
801037fe:	ff 73 04             	pushl  0x4(%ebx)
80103801:	e8 58 2a 00 00       	call   8010625e <freevm>
        p->pid = 0;
80103806:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
8010380d:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
80103814:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
80103818:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
8010381f:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
80103826:	c7 04 24 80 1d 13 80 	movl   $0x80131d80,(%esp)
8010382d:	e8 5b 04 00 00       	call   80103c8d <release>
        return pid;
80103832:	83 c4 10             	add    $0x10,%esp
}
80103835:	89 f0                	mov    %esi,%eax
80103837:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010383a:	5b                   	pop    %ebx
8010383b:	5e                   	pop    %esi
8010383c:	5d                   	pop    %ebp
8010383d:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010383e:	83 c3 7c             	add    $0x7c,%ebx
80103841:	81 fb b4 3c 13 80    	cmp    $0x80133cb4,%ebx
80103847:	73 12                	jae    8010385b <wait+0x9d>
      if(p->parent != curproc)
80103849:	39 73 14             	cmp    %esi,0x14(%ebx)
8010384c:	75 f0                	jne    8010383e <wait+0x80>
      if(p->state == ZOMBIE){
8010384e:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103852:	74 92                	je     801037e6 <wait+0x28>
      havekids = 1;
80103854:	b8 01 00 00 00       	mov    $0x1,%eax
80103859:	eb e3                	jmp    8010383e <wait+0x80>
    if(!havekids || curproc->killed){
8010385b:	85 c0                	test   %eax,%eax
8010385d:	74 06                	je     80103865 <wait+0xa7>
8010385f:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
80103863:	74 17                	je     8010387c <wait+0xbe>
      release(&ptable.lock);
80103865:	83 ec 0c             	sub    $0xc,%esp
80103868:	68 80 1d 13 80       	push   $0x80131d80
8010386d:	e8 1b 04 00 00       	call   80103c8d <release>
      return -1;
80103872:	83 c4 10             	add    $0x10,%esp
80103875:	be ff ff ff ff       	mov    $0xffffffff,%esi
8010387a:	eb b9                	jmp    80103835 <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
8010387c:	83 ec 08             	sub    $0x8,%esp
8010387f:	68 80 1d 13 80       	push   $0x80131d80
80103884:	56                   	push   %esi
80103885:	e8 a3 fe ff ff       	call   8010372d <sleep>
    havekids = 0;
8010388a:	83 c4 10             	add    $0x10,%esp
8010388d:	e9 48 ff ff ff       	jmp    801037da <wait+0x1c>

80103892 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80103892:	55                   	push   %ebp
80103893:	89 e5                	mov    %esp,%ebp
80103895:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
80103898:	68 80 1d 13 80       	push   $0x80131d80
8010389d:	e8 86 03 00 00       	call   80103c28 <acquire>
  wakeup1(chan);
801038a2:	8b 45 08             	mov    0x8(%ebp),%eax
801038a5:	e8 1f f8 ff ff       	call   801030c9 <wakeup1>
  release(&ptable.lock);
801038aa:	c7 04 24 80 1d 13 80 	movl   $0x80131d80,(%esp)
801038b1:	e8 d7 03 00 00       	call   80103c8d <release>
}
801038b6:	83 c4 10             	add    $0x10,%esp
801038b9:	c9                   	leave  
801038ba:	c3                   	ret    

801038bb <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
801038bb:	55                   	push   %ebp
801038bc:	89 e5                	mov    %esp,%ebp
801038be:	53                   	push   %ebx
801038bf:	83 ec 10             	sub    $0x10,%esp
801038c2:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
801038c5:	68 80 1d 13 80       	push   $0x80131d80
801038ca:	e8 59 03 00 00       	call   80103c28 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801038cf:	83 c4 10             	add    $0x10,%esp
801038d2:	b8 b4 1d 13 80       	mov    $0x80131db4,%eax
801038d7:	3d b4 3c 13 80       	cmp    $0x80133cb4,%eax
801038dc:	73 3a                	jae    80103918 <kill+0x5d>
    if(p->pid == pid){
801038de:	39 58 10             	cmp    %ebx,0x10(%eax)
801038e1:	74 05                	je     801038e8 <kill+0x2d>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801038e3:	83 c0 7c             	add    $0x7c,%eax
801038e6:	eb ef                	jmp    801038d7 <kill+0x1c>
      p->killed = 1;
801038e8:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
801038ef:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
801038f3:	74 1a                	je     8010390f <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
801038f5:	83 ec 0c             	sub    $0xc,%esp
801038f8:	68 80 1d 13 80       	push   $0x80131d80
801038fd:	e8 8b 03 00 00       	call   80103c8d <release>
      return 0;
80103902:	83 c4 10             	add    $0x10,%esp
80103905:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
8010390a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010390d:	c9                   	leave  
8010390e:	c3                   	ret    
        p->state = RUNNABLE;
8010390f:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80103916:	eb dd                	jmp    801038f5 <kill+0x3a>
  release(&ptable.lock);
80103918:	83 ec 0c             	sub    $0xc,%esp
8010391b:	68 80 1d 13 80       	push   $0x80131d80
80103920:	e8 68 03 00 00       	call   80103c8d <release>
  return -1;
80103925:	83 c4 10             	add    $0x10,%esp
80103928:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010392d:	eb db                	jmp    8010390a <kill+0x4f>

8010392f <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
8010392f:	55                   	push   %ebp
80103930:	89 e5                	mov    %esp,%ebp
80103932:	56                   	push   %esi
80103933:	53                   	push   %ebx
80103934:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103937:	bb b4 1d 13 80       	mov    $0x80131db4,%ebx
8010393c:	eb 33                	jmp    80103971 <procdump+0x42>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
8010393e:	b8 20 6b 10 80       	mov    $0x80106b20,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
80103943:	8d 53 6c             	lea    0x6c(%ebx),%edx
80103946:	52                   	push   %edx
80103947:	50                   	push   %eax
80103948:	ff 73 10             	pushl  0x10(%ebx)
8010394b:	68 24 6b 10 80       	push   $0x80106b24
80103950:	e8 b6 cc ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
80103955:	83 c4 10             	add    $0x10,%esp
80103958:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
8010395c:	74 39                	je     80103997 <procdump+0x68>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
8010395e:	83 ec 0c             	sub    $0xc,%esp
80103961:	68 9b 6e 10 80       	push   $0x80106e9b
80103966:	e8 a0 cc ff ff       	call   8010060b <cprintf>
8010396b:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010396e:	83 c3 7c             	add    $0x7c,%ebx
80103971:	81 fb b4 3c 13 80    	cmp    $0x80133cb4,%ebx
80103977:	73 61                	jae    801039da <procdump+0xab>
    if(p->state == UNUSED)
80103979:	8b 43 0c             	mov    0xc(%ebx),%eax
8010397c:	85 c0                	test   %eax,%eax
8010397e:	74 ee                	je     8010396e <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103980:	83 f8 05             	cmp    $0x5,%eax
80103983:	77 b9                	ja     8010393e <procdump+0xf>
80103985:	8b 04 85 80 6b 10 80 	mov    -0x7fef9480(,%eax,4),%eax
8010398c:	85 c0                	test   %eax,%eax
8010398e:	75 b3                	jne    80103943 <procdump+0x14>
      state = "???";
80103990:	b8 20 6b 10 80       	mov    $0x80106b20,%eax
80103995:	eb ac                	jmp    80103943 <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80103997:	8b 43 1c             	mov    0x1c(%ebx),%eax
8010399a:	8b 40 0c             	mov    0xc(%eax),%eax
8010399d:	83 c0 08             	add    $0x8,%eax
801039a0:	83 ec 08             	sub    $0x8,%esp
801039a3:	8d 55 d0             	lea    -0x30(%ebp),%edx
801039a6:	52                   	push   %edx
801039a7:	50                   	push   %eax
801039a8:	e8 5a 01 00 00       	call   80103b07 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
801039ad:	83 c4 10             	add    $0x10,%esp
801039b0:	be 00 00 00 00       	mov    $0x0,%esi
801039b5:	eb 14                	jmp    801039cb <procdump+0x9c>
        cprintf(" %p", pc[i]);
801039b7:	83 ec 08             	sub    $0x8,%esp
801039ba:	50                   	push   %eax
801039bb:	68 61 65 10 80       	push   $0x80106561
801039c0:	e8 46 cc ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
801039c5:	83 c6 01             	add    $0x1,%esi
801039c8:	83 c4 10             	add    $0x10,%esp
801039cb:	83 fe 09             	cmp    $0x9,%esi
801039ce:	7f 8e                	jg     8010395e <procdump+0x2f>
801039d0:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
801039d4:	85 c0                	test   %eax,%eax
801039d6:	75 df                	jne    801039b7 <procdump+0x88>
801039d8:	eb 84                	jmp    8010395e <procdump+0x2f>
  }
}
801039da:	8d 65 f8             	lea    -0x8(%ebp),%esp
801039dd:	5b                   	pop    %ebx
801039de:	5e                   	pop    %esi
801039df:	5d                   	pop    %ebp
801039e0:	c3                   	ret    

801039e1 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
801039e1:	55                   	push   %ebp
801039e2:	89 e5                	mov    %esp,%ebp
801039e4:	53                   	push   %ebx
801039e5:	83 ec 0c             	sub    $0xc,%esp
801039e8:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
801039eb:	68 98 6b 10 80       	push   $0x80106b98
801039f0:	8d 43 04             	lea    0x4(%ebx),%eax
801039f3:	50                   	push   %eax
801039f4:	e8 f3 00 00 00       	call   80103aec <initlock>
  lk->name = name;
801039f9:	8b 45 0c             	mov    0xc(%ebp),%eax
801039fc:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
801039ff:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103a05:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103a0c:	83 c4 10             	add    $0x10,%esp
80103a0f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103a12:	c9                   	leave  
80103a13:	c3                   	ret    

80103a14 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103a14:	55                   	push   %ebp
80103a15:	89 e5                	mov    %esp,%ebp
80103a17:	56                   	push   %esi
80103a18:	53                   	push   %ebx
80103a19:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103a1c:	8d 73 04             	lea    0x4(%ebx),%esi
80103a1f:	83 ec 0c             	sub    $0xc,%esp
80103a22:	56                   	push   %esi
80103a23:	e8 00 02 00 00       	call   80103c28 <acquire>
  while (lk->locked) {
80103a28:	83 c4 10             	add    $0x10,%esp
80103a2b:	eb 0d                	jmp    80103a3a <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103a2d:	83 ec 08             	sub    $0x8,%esp
80103a30:	56                   	push   %esi
80103a31:	53                   	push   %ebx
80103a32:	e8 f6 fc ff ff       	call   8010372d <sleep>
80103a37:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103a3a:	83 3b 00             	cmpl   $0x0,(%ebx)
80103a3d:	75 ee                	jne    80103a2d <acquiresleep+0x19>
  }
  lk->locked = 1;
80103a3f:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103a45:	e8 3f f8 ff ff       	call   80103289 <myproc>
80103a4a:	8b 40 10             	mov    0x10(%eax),%eax
80103a4d:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103a50:	83 ec 0c             	sub    $0xc,%esp
80103a53:	56                   	push   %esi
80103a54:	e8 34 02 00 00       	call   80103c8d <release>
}
80103a59:	83 c4 10             	add    $0x10,%esp
80103a5c:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a5f:	5b                   	pop    %ebx
80103a60:	5e                   	pop    %esi
80103a61:	5d                   	pop    %ebp
80103a62:	c3                   	ret    

80103a63 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103a63:	55                   	push   %ebp
80103a64:	89 e5                	mov    %esp,%ebp
80103a66:	56                   	push   %esi
80103a67:	53                   	push   %ebx
80103a68:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103a6b:	8d 73 04             	lea    0x4(%ebx),%esi
80103a6e:	83 ec 0c             	sub    $0xc,%esp
80103a71:	56                   	push   %esi
80103a72:	e8 b1 01 00 00       	call   80103c28 <acquire>
  lk->locked = 0;
80103a77:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103a7d:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103a84:	89 1c 24             	mov    %ebx,(%esp)
80103a87:	e8 06 fe ff ff       	call   80103892 <wakeup>
  release(&lk->lk);
80103a8c:	89 34 24             	mov    %esi,(%esp)
80103a8f:	e8 f9 01 00 00       	call   80103c8d <release>
}
80103a94:	83 c4 10             	add    $0x10,%esp
80103a97:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a9a:	5b                   	pop    %ebx
80103a9b:	5e                   	pop    %esi
80103a9c:	5d                   	pop    %ebp
80103a9d:	c3                   	ret    

80103a9e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103a9e:	55                   	push   %ebp
80103a9f:	89 e5                	mov    %esp,%ebp
80103aa1:	56                   	push   %esi
80103aa2:	53                   	push   %ebx
80103aa3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103aa6:	8d 73 04             	lea    0x4(%ebx),%esi
80103aa9:	83 ec 0c             	sub    $0xc,%esp
80103aac:	56                   	push   %esi
80103aad:	e8 76 01 00 00       	call   80103c28 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103ab2:	83 c4 10             	add    $0x10,%esp
80103ab5:	83 3b 00             	cmpl   $0x0,(%ebx)
80103ab8:	75 17                	jne    80103ad1 <holdingsleep+0x33>
80103aba:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103abf:	83 ec 0c             	sub    $0xc,%esp
80103ac2:	56                   	push   %esi
80103ac3:	e8 c5 01 00 00       	call   80103c8d <release>
  return r;
}
80103ac8:	89 d8                	mov    %ebx,%eax
80103aca:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103acd:	5b                   	pop    %ebx
80103ace:	5e                   	pop    %esi
80103acf:	5d                   	pop    %ebp
80103ad0:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103ad1:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103ad4:	e8 b0 f7 ff ff       	call   80103289 <myproc>
80103ad9:	3b 58 10             	cmp    0x10(%eax),%ebx
80103adc:	74 07                	je     80103ae5 <holdingsleep+0x47>
80103ade:	bb 00 00 00 00       	mov    $0x0,%ebx
80103ae3:	eb da                	jmp    80103abf <holdingsleep+0x21>
80103ae5:	bb 01 00 00 00       	mov    $0x1,%ebx
80103aea:	eb d3                	jmp    80103abf <holdingsleep+0x21>

80103aec <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103aec:	55                   	push   %ebp
80103aed:	89 e5                	mov    %esp,%ebp
80103aef:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103af2:	8b 55 0c             	mov    0xc(%ebp),%edx
80103af5:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103af8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103afe:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103b05:	5d                   	pop    %ebp
80103b06:	c3                   	ret    

80103b07 <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103b07:	55                   	push   %ebp
80103b08:	89 e5                	mov    %esp,%ebp
80103b0a:	53                   	push   %ebx
80103b0b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103b0e:	8b 45 08             	mov    0x8(%ebp),%eax
80103b11:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103b14:	b8 00 00 00 00       	mov    $0x0,%eax
80103b19:	83 f8 09             	cmp    $0x9,%eax
80103b1c:	7f 25                	jg     80103b43 <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103b1e:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103b24:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103b2a:	77 17                	ja     80103b43 <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103b2c:	8b 5a 04             	mov    0x4(%edx),%ebx
80103b2f:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103b32:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103b34:	83 c0 01             	add    $0x1,%eax
80103b37:	eb e0                	jmp    80103b19 <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103b39:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103b40:	83 c0 01             	add    $0x1,%eax
80103b43:	83 f8 09             	cmp    $0x9,%eax
80103b46:	7e f1                	jle    80103b39 <getcallerpcs+0x32>
}
80103b48:	5b                   	pop    %ebx
80103b49:	5d                   	pop    %ebp
80103b4a:	c3                   	ret    

80103b4b <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103b4b:	55                   	push   %ebp
80103b4c:	89 e5                	mov    %esp,%ebp
80103b4e:	53                   	push   %ebx
80103b4f:	83 ec 04             	sub    $0x4,%esp
80103b52:	9c                   	pushf  
80103b53:	5b                   	pop    %ebx
  asm volatile("cli");
80103b54:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103b55:	e8 b8 f6 ff ff       	call   80103212 <mycpu>
80103b5a:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103b61:	74 12                	je     80103b75 <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103b63:	e8 aa f6 ff ff       	call   80103212 <mycpu>
80103b68:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103b6f:	83 c4 04             	add    $0x4,%esp
80103b72:	5b                   	pop    %ebx
80103b73:	5d                   	pop    %ebp
80103b74:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103b75:	e8 98 f6 ff ff       	call   80103212 <mycpu>
80103b7a:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103b80:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103b86:	eb db                	jmp    80103b63 <pushcli+0x18>

80103b88 <popcli>:

void
popcli(void)
{
80103b88:	55                   	push   %ebp
80103b89:	89 e5                	mov    %esp,%ebp
80103b8b:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103b8e:	9c                   	pushf  
80103b8f:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103b90:	f6 c4 02             	test   $0x2,%ah
80103b93:	75 28                	jne    80103bbd <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103b95:	e8 78 f6 ff ff       	call   80103212 <mycpu>
80103b9a:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103ba0:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103ba3:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103ba9:	85 d2                	test   %edx,%edx
80103bab:	78 1d                	js     80103bca <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103bad:	e8 60 f6 ff ff       	call   80103212 <mycpu>
80103bb2:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103bb9:	74 1c                	je     80103bd7 <popcli+0x4f>
    sti();
}
80103bbb:	c9                   	leave  
80103bbc:	c3                   	ret    
    panic("popcli - interruptible");
80103bbd:	83 ec 0c             	sub    $0xc,%esp
80103bc0:	68 a3 6b 10 80       	push   $0x80106ba3
80103bc5:	e8 7e c7 ff ff       	call   80100348 <panic>
    panic("popcli");
80103bca:	83 ec 0c             	sub    $0xc,%esp
80103bcd:	68 ba 6b 10 80       	push   $0x80106bba
80103bd2:	e8 71 c7 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103bd7:	e8 36 f6 ff ff       	call   80103212 <mycpu>
80103bdc:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103be3:	74 d6                	je     80103bbb <popcli+0x33>
  asm volatile("sti");
80103be5:	fb                   	sti    
}
80103be6:	eb d3                	jmp    80103bbb <popcli+0x33>

80103be8 <holding>:
{
80103be8:	55                   	push   %ebp
80103be9:	89 e5                	mov    %esp,%ebp
80103beb:	53                   	push   %ebx
80103bec:	83 ec 04             	sub    $0x4,%esp
80103bef:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103bf2:	e8 54 ff ff ff       	call   80103b4b <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103bf7:	83 3b 00             	cmpl   $0x0,(%ebx)
80103bfa:	75 12                	jne    80103c0e <holding+0x26>
80103bfc:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103c01:	e8 82 ff ff ff       	call   80103b88 <popcli>
}
80103c06:	89 d8                	mov    %ebx,%eax
80103c08:	83 c4 04             	add    $0x4,%esp
80103c0b:	5b                   	pop    %ebx
80103c0c:	5d                   	pop    %ebp
80103c0d:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103c0e:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103c11:	e8 fc f5 ff ff       	call   80103212 <mycpu>
80103c16:	39 c3                	cmp    %eax,%ebx
80103c18:	74 07                	je     80103c21 <holding+0x39>
80103c1a:	bb 00 00 00 00       	mov    $0x0,%ebx
80103c1f:	eb e0                	jmp    80103c01 <holding+0x19>
80103c21:	bb 01 00 00 00       	mov    $0x1,%ebx
80103c26:	eb d9                	jmp    80103c01 <holding+0x19>

80103c28 <acquire>:
{
80103c28:	55                   	push   %ebp
80103c29:	89 e5                	mov    %esp,%ebp
80103c2b:	53                   	push   %ebx
80103c2c:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103c2f:	e8 17 ff ff ff       	call   80103b4b <pushcli>
  if(holding(lk))
80103c34:	83 ec 0c             	sub    $0xc,%esp
80103c37:	ff 75 08             	pushl  0x8(%ebp)
80103c3a:	e8 a9 ff ff ff       	call   80103be8 <holding>
80103c3f:	83 c4 10             	add    $0x10,%esp
80103c42:	85 c0                	test   %eax,%eax
80103c44:	75 3a                	jne    80103c80 <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103c46:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103c49:	b8 01 00 00 00       	mov    $0x1,%eax
80103c4e:	f0 87 02             	lock xchg %eax,(%edx)
80103c51:	85 c0                	test   %eax,%eax
80103c53:	75 f1                	jne    80103c46 <acquire+0x1e>
  __sync_synchronize();
80103c55:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103c5a:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103c5d:	e8 b0 f5 ff ff       	call   80103212 <mycpu>
80103c62:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103c65:	8b 45 08             	mov    0x8(%ebp),%eax
80103c68:	83 c0 0c             	add    $0xc,%eax
80103c6b:	83 ec 08             	sub    $0x8,%esp
80103c6e:	50                   	push   %eax
80103c6f:	8d 45 08             	lea    0x8(%ebp),%eax
80103c72:	50                   	push   %eax
80103c73:	e8 8f fe ff ff       	call   80103b07 <getcallerpcs>
}
80103c78:	83 c4 10             	add    $0x10,%esp
80103c7b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103c7e:	c9                   	leave  
80103c7f:	c3                   	ret    
    panic("acquire");
80103c80:	83 ec 0c             	sub    $0xc,%esp
80103c83:	68 c1 6b 10 80       	push   $0x80106bc1
80103c88:	e8 bb c6 ff ff       	call   80100348 <panic>

80103c8d <release>:
{
80103c8d:	55                   	push   %ebp
80103c8e:	89 e5                	mov    %esp,%ebp
80103c90:	53                   	push   %ebx
80103c91:	83 ec 10             	sub    $0x10,%esp
80103c94:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103c97:	53                   	push   %ebx
80103c98:	e8 4b ff ff ff       	call   80103be8 <holding>
80103c9d:	83 c4 10             	add    $0x10,%esp
80103ca0:	85 c0                	test   %eax,%eax
80103ca2:	74 23                	je     80103cc7 <release+0x3a>
  lk->pcs[0] = 0;
80103ca4:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103cab:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103cb2:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103cb7:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103cbd:	e8 c6 fe ff ff       	call   80103b88 <popcli>
}
80103cc2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103cc5:	c9                   	leave  
80103cc6:	c3                   	ret    
    panic("release");
80103cc7:	83 ec 0c             	sub    $0xc,%esp
80103cca:	68 c9 6b 10 80       	push   $0x80106bc9
80103ccf:	e8 74 c6 ff ff       	call   80100348 <panic>

80103cd4 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103cd4:	55                   	push   %ebp
80103cd5:	89 e5                	mov    %esp,%ebp
80103cd7:	57                   	push   %edi
80103cd8:	53                   	push   %ebx
80103cd9:	8b 55 08             	mov    0x8(%ebp),%edx
80103cdc:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103cdf:	f6 c2 03             	test   $0x3,%dl
80103ce2:	75 05                	jne    80103ce9 <memset+0x15>
80103ce4:	f6 c1 03             	test   $0x3,%cl
80103ce7:	74 0e                	je     80103cf7 <memset+0x23>
  asm volatile("cld; rep stosb" :
80103ce9:	89 d7                	mov    %edx,%edi
80103ceb:	8b 45 0c             	mov    0xc(%ebp),%eax
80103cee:	fc                   	cld    
80103cef:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103cf1:	89 d0                	mov    %edx,%eax
80103cf3:	5b                   	pop    %ebx
80103cf4:	5f                   	pop    %edi
80103cf5:	5d                   	pop    %ebp
80103cf6:	c3                   	ret    
    c &= 0xFF;
80103cf7:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103cfb:	c1 e9 02             	shr    $0x2,%ecx
80103cfe:	89 f8                	mov    %edi,%eax
80103d00:	c1 e0 18             	shl    $0x18,%eax
80103d03:	89 fb                	mov    %edi,%ebx
80103d05:	c1 e3 10             	shl    $0x10,%ebx
80103d08:	09 d8                	or     %ebx,%eax
80103d0a:	89 fb                	mov    %edi,%ebx
80103d0c:	c1 e3 08             	shl    $0x8,%ebx
80103d0f:	09 d8                	or     %ebx,%eax
80103d11:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103d13:	89 d7                	mov    %edx,%edi
80103d15:	fc                   	cld    
80103d16:	f3 ab                	rep stos %eax,%es:(%edi)
80103d18:	eb d7                	jmp    80103cf1 <memset+0x1d>

80103d1a <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103d1a:	55                   	push   %ebp
80103d1b:	89 e5                	mov    %esp,%ebp
80103d1d:	56                   	push   %esi
80103d1e:	53                   	push   %ebx
80103d1f:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103d22:	8b 55 0c             	mov    0xc(%ebp),%edx
80103d25:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103d28:	8d 70 ff             	lea    -0x1(%eax),%esi
80103d2b:	85 c0                	test   %eax,%eax
80103d2d:	74 1c                	je     80103d4b <memcmp+0x31>
    if(*s1 != *s2)
80103d2f:	0f b6 01             	movzbl (%ecx),%eax
80103d32:	0f b6 1a             	movzbl (%edx),%ebx
80103d35:	38 d8                	cmp    %bl,%al
80103d37:	75 0a                	jne    80103d43 <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103d39:	83 c1 01             	add    $0x1,%ecx
80103d3c:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103d3f:	89 f0                	mov    %esi,%eax
80103d41:	eb e5                	jmp    80103d28 <memcmp+0xe>
      return *s1 - *s2;
80103d43:	0f b6 c0             	movzbl %al,%eax
80103d46:	0f b6 db             	movzbl %bl,%ebx
80103d49:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103d4b:	5b                   	pop    %ebx
80103d4c:	5e                   	pop    %esi
80103d4d:	5d                   	pop    %ebp
80103d4e:	c3                   	ret    

80103d4f <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103d4f:	55                   	push   %ebp
80103d50:	89 e5                	mov    %esp,%ebp
80103d52:	56                   	push   %esi
80103d53:	53                   	push   %ebx
80103d54:	8b 45 08             	mov    0x8(%ebp),%eax
80103d57:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103d5a:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103d5d:	39 c1                	cmp    %eax,%ecx
80103d5f:	73 3a                	jae    80103d9b <memmove+0x4c>
80103d61:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103d64:	39 c3                	cmp    %eax,%ebx
80103d66:	76 37                	jbe    80103d9f <memmove+0x50>
    s += n;
    d += n;
80103d68:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103d6b:	eb 0d                	jmp    80103d7a <memmove+0x2b>
      *--d = *--s;
80103d6d:	83 eb 01             	sub    $0x1,%ebx
80103d70:	83 e9 01             	sub    $0x1,%ecx
80103d73:	0f b6 13             	movzbl (%ebx),%edx
80103d76:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103d78:	89 f2                	mov    %esi,%edx
80103d7a:	8d 72 ff             	lea    -0x1(%edx),%esi
80103d7d:	85 d2                	test   %edx,%edx
80103d7f:	75 ec                	jne    80103d6d <memmove+0x1e>
80103d81:	eb 14                	jmp    80103d97 <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103d83:	0f b6 11             	movzbl (%ecx),%edx
80103d86:	88 13                	mov    %dl,(%ebx)
80103d88:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103d8b:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103d8e:	89 f2                	mov    %esi,%edx
80103d90:	8d 72 ff             	lea    -0x1(%edx),%esi
80103d93:	85 d2                	test   %edx,%edx
80103d95:	75 ec                	jne    80103d83 <memmove+0x34>

  return dst;
}
80103d97:	5b                   	pop    %ebx
80103d98:	5e                   	pop    %esi
80103d99:	5d                   	pop    %ebp
80103d9a:	c3                   	ret    
80103d9b:	89 c3                	mov    %eax,%ebx
80103d9d:	eb f1                	jmp    80103d90 <memmove+0x41>
80103d9f:	89 c3                	mov    %eax,%ebx
80103da1:	eb ed                	jmp    80103d90 <memmove+0x41>

80103da3 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103da3:	55                   	push   %ebp
80103da4:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80103da6:	ff 75 10             	pushl  0x10(%ebp)
80103da9:	ff 75 0c             	pushl  0xc(%ebp)
80103dac:	ff 75 08             	pushl  0x8(%ebp)
80103daf:	e8 9b ff ff ff       	call   80103d4f <memmove>
}
80103db4:	c9                   	leave  
80103db5:	c3                   	ret    

80103db6 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103db6:	55                   	push   %ebp
80103db7:	89 e5                	mov    %esp,%ebp
80103db9:	53                   	push   %ebx
80103dba:	8b 55 08             	mov    0x8(%ebp),%edx
80103dbd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103dc0:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103dc3:	eb 09                	jmp    80103dce <strncmp+0x18>
    n--, p++, q++;
80103dc5:	83 e8 01             	sub    $0x1,%eax
80103dc8:	83 c2 01             	add    $0x1,%edx
80103dcb:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103dce:	85 c0                	test   %eax,%eax
80103dd0:	74 0b                	je     80103ddd <strncmp+0x27>
80103dd2:	0f b6 1a             	movzbl (%edx),%ebx
80103dd5:	84 db                	test   %bl,%bl
80103dd7:	74 04                	je     80103ddd <strncmp+0x27>
80103dd9:	3a 19                	cmp    (%ecx),%bl
80103ddb:	74 e8                	je     80103dc5 <strncmp+0xf>
  if(n == 0)
80103ddd:	85 c0                	test   %eax,%eax
80103ddf:	74 0b                	je     80103dec <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80103de1:	0f b6 02             	movzbl (%edx),%eax
80103de4:	0f b6 11             	movzbl (%ecx),%edx
80103de7:	29 d0                	sub    %edx,%eax
}
80103de9:	5b                   	pop    %ebx
80103dea:	5d                   	pop    %ebp
80103deb:	c3                   	ret    
    return 0;
80103dec:	b8 00 00 00 00       	mov    $0x0,%eax
80103df1:	eb f6                	jmp    80103de9 <strncmp+0x33>

80103df3 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103df3:	55                   	push   %ebp
80103df4:	89 e5                	mov    %esp,%ebp
80103df6:	57                   	push   %edi
80103df7:	56                   	push   %esi
80103df8:	53                   	push   %ebx
80103df9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103dfc:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103dff:	8b 45 08             	mov    0x8(%ebp),%eax
80103e02:	eb 04                	jmp    80103e08 <strncpy+0x15>
80103e04:	89 fb                	mov    %edi,%ebx
80103e06:	89 f0                	mov    %esi,%eax
80103e08:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103e0b:	85 c9                	test   %ecx,%ecx
80103e0d:	7e 1d                	jle    80103e2c <strncpy+0x39>
80103e0f:	8d 7b 01             	lea    0x1(%ebx),%edi
80103e12:	8d 70 01             	lea    0x1(%eax),%esi
80103e15:	0f b6 1b             	movzbl (%ebx),%ebx
80103e18:	88 18                	mov    %bl,(%eax)
80103e1a:	89 d1                	mov    %edx,%ecx
80103e1c:	84 db                	test   %bl,%bl
80103e1e:	75 e4                	jne    80103e04 <strncpy+0x11>
80103e20:	89 f0                	mov    %esi,%eax
80103e22:	eb 08                	jmp    80103e2c <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80103e24:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80103e27:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80103e29:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80103e2c:	8d 4a ff             	lea    -0x1(%edx),%ecx
80103e2f:	85 d2                	test   %edx,%edx
80103e31:	7f f1                	jg     80103e24 <strncpy+0x31>
  return os;
}
80103e33:	8b 45 08             	mov    0x8(%ebp),%eax
80103e36:	5b                   	pop    %ebx
80103e37:	5e                   	pop    %esi
80103e38:	5f                   	pop    %edi
80103e39:	5d                   	pop    %ebp
80103e3a:	c3                   	ret    

80103e3b <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80103e3b:	55                   	push   %ebp
80103e3c:	89 e5                	mov    %esp,%ebp
80103e3e:	57                   	push   %edi
80103e3f:	56                   	push   %esi
80103e40:	53                   	push   %ebx
80103e41:	8b 45 08             	mov    0x8(%ebp),%eax
80103e44:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103e47:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
80103e4a:	85 d2                	test   %edx,%edx
80103e4c:	7e 23                	jle    80103e71 <safestrcpy+0x36>
80103e4e:	89 c1                	mov    %eax,%ecx
80103e50:	eb 04                	jmp    80103e56 <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80103e52:	89 fb                	mov    %edi,%ebx
80103e54:	89 f1                	mov    %esi,%ecx
80103e56:	83 ea 01             	sub    $0x1,%edx
80103e59:	85 d2                	test   %edx,%edx
80103e5b:	7e 11                	jle    80103e6e <safestrcpy+0x33>
80103e5d:	8d 7b 01             	lea    0x1(%ebx),%edi
80103e60:	8d 71 01             	lea    0x1(%ecx),%esi
80103e63:	0f b6 1b             	movzbl (%ebx),%ebx
80103e66:	88 19                	mov    %bl,(%ecx)
80103e68:	84 db                	test   %bl,%bl
80103e6a:	75 e6                	jne    80103e52 <safestrcpy+0x17>
80103e6c:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80103e6e:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80103e71:	5b                   	pop    %ebx
80103e72:	5e                   	pop    %esi
80103e73:	5f                   	pop    %edi
80103e74:	5d                   	pop    %ebp
80103e75:	c3                   	ret    

80103e76 <strlen>:

int
strlen(const char *s)
{
80103e76:	55                   	push   %ebp
80103e77:	89 e5                	mov    %esp,%ebp
80103e79:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80103e7c:	b8 00 00 00 00       	mov    $0x0,%eax
80103e81:	eb 03                	jmp    80103e86 <strlen+0x10>
80103e83:	83 c0 01             	add    $0x1,%eax
80103e86:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80103e8a:	75 f7                	jne    80103e83 <strlen+0xd>
    ;
  return n;
}
80103e8c:	5d                   	pop    %ebp
80103e8d:	c3                   	ret    

80103e8e <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80103e8e:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80103e92:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80103e96:	55                   	push   %ebp
  pushl %ebx
80103e97:	53                   	push   %ebx
  pushl %esi
80103e98:	56                   	push   %esi
  pushl %edi
80103e99:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80103e9a:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80103e9c:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80103e9e:	5f                   	pop    %edi
  popl %esi
80103e9f:	5e                   	pop    %esi
  popl %ebx
80103ea0:	5b                   	pop    %ebx
  popl %ebp
80103ea1:	5d                   	pop    %ebp
  ret
80103ea2:	c3                   	ret    

80103ea3 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80103ea3:	55                   	push   %ebp
80103ea4:	89 e5                	mov    %esp,%ebp
80103ea6:	53                   	push   %ebx
80103ea7:	83 ec 04             	sub    $0x4,%esp
80103eaa:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80103ead:	e8 d7 f3 ff ff       	call   80103289 <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80103eb2:	8b 00                	mov    (%eax),%eax
80103eb4:	39 d8                	cmp    %ebx,%eax
80103eb6:	76 19                	jbe    80103ed1 <fetchint+0x2e>
80103eb8:	8d 53 04             	lea    0x4(%ebx),%edx
80103ebb:	39 d0                	cmp    %edx,%eax
80103ebd:	72 19                	jb     80103ed8 <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80103ebf:	8b 13                	mov    (%ebx),%edx
80103ec1:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ec4:	89 10                	mov    %edx,(%eax)
  return 0;
80103ec6:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103ecb:	83 c4 04             	add    $0x4,%esp
80103ece:	5b                   	pop    %ebx
80103ecf:	5d                   	pop    %ebp
80103ed0:	c3                   	ret    
    return -1;
80103ed1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103ed6:	eb f3                	jmp    80103ecb <fetchint+0x28>
80103ed8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103edd:	eb ec                	jmp    80103ecb <fetchint+0x28>

80103edf <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80103edf:	55                   	push   %ebp
80103ee0:	89 e5                	mov    %esp,%ebp
80103ee2:	53                   	push   %ebx
80103ee3:	83 ec 04             	sub    $0x4,%esp
80103ee6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
80103ee9:	e8 9b f3 ff ff       	call   80103289 <myproc>

  if(addr >= curproc->sz)
80103eee:	39 18                	cmp    %ebx,(%eax)
80103ef0:	76 26                	jbe    80103f18 <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
80103ef2:	8b 55 0c             	mov    0xc(%ebp),%edx
80103ef5:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
80103ef7:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
80103ef9:	89 d8                	mov    %ebx,%eax
80103efb:	39 d0                	cmp    %edx,%eax
80103efd:	73 0e                	jae    80103f0d <fetchstr+0x2e>
    if(*s == 0)
80103eff:	80 38 00             	cmpb   $0x0,(%eax)
80103f02:	74 05                	je     80103f09 <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
80103f04:	83 c0 01             	add    $0x1,%eax
80103f07:	eb f2                	jmp    80103efb <fetchstr+0x1c>
      return s - *pp;
80103f09:	29 d8                	sub    %ebx,%eax
80103f0b:	eb 05                	jmp    80103f12 <fetchstr+0x33>
  }
  return -1;
80103f0d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103f12:	83 c4 04             	add    $0x4,%esp
80103f15:	5b                   	pop    %ebx
80103f16:	5d                   	pop    %ebp
80103f17:	c3                   	ret    
    return -1;
80103f18:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f1d:	eb f3                	jmp    80103f12 <fetchstr+0x33>

80103f1f <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80103f1f:	55                   	push   %ebp
80103f20:	89 e5                	mov    %esp,%ebp
80103f22:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80103f25:	e8 5f f3 ff ff       	call   80103289 <myproc>
80103f2a:	8b 50 18             	mov    0x18(%eax),%edx
80103f2d:	8b 45 08             	mov    0x8(%ebp),%eax
80103f30:	c1 e0 02             	shl    $0x2,%eax
80103f33:	03 42 44             	add    0x44(%edx),%eax
80103f36:	83 ec 08             	sub    $0x8,%esp
80103f39:	ff 75 0c             	pushl  0xc(%ebp)
80103f3c:	83 c0 04             	add    $0x4,%eax
80103f3f:	50                   	push   %eax
80103f40:	e8 5e ff ff ff       	call   80103ea3 <fetchint>
}
80103f45:	c9                   	leave  
80103f46:	c3                   	ret    

80103f47 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80103f47:	55                   	push   %ebp
80103f48:	89 e5                	mov    %esp,%ebp
80103f4a:	56                   	push   %esi
80103f4b:	53                   	push   %ebx
80103f4c:	83 ec 10             	sub    $0x10,%esp
80103f4f:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
80103f52:	e8 32 f3 ff ff       	call   80103289 <myproc>
80103f57:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
80103f59:	83 ec 08             	sub    $0x8,%esp
80103f5c:	8d 45 f4             	lea    -0xc(%ebp),%eax
80103f5f:	50                   	push   %eax
80103f60:	ff 75 08             	pushl  0x8(%ebp)
80103f63:	e8 b7 ff ff ff       	call   80103f1f <argint>
80103f68:	83 c4 10             	add    $0x10,%esp
80103f6b:	85 c0                	test   %eax,%eax
80103f6d:	78 24                	js     80103f93 <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80103f6f:	85 db                	test   %ebx,%ebx
80103f71:	78 27                	js     80103f9a <argptr+0x53>
80103f73:	8b 16                	mov    (%esi),%edx
80103f75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f78:	39 c2                	cmp    %eax,%edx
80103f7a:	76 25                	jbe    80103fa1 <argptr+0x5a>
80103f7c:	01 c3                	add    %eax,%ebx
80103f7e:	39 da                	cmp    %ebx,%edx
80103f80:	72 26                	jb     80103fa8 <argptr+0x61>
    return -1;
  *pp = (char*)i;
80103f82:	8b 55 0c             	mov    0xc(%ebp),%edx
80103f85:	89 02                	mov    %eax,(%edx)
  return 0;
80103f87:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103f8c:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103f8f:	5b                   	pop    %ebx
80103f90:	5e                   	pop    %esi
80103f91:	5d                   	pop    %ebp
80103f92:	c3                   	ret    
    return -1;
80103f93:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f98:	eb f2                	jmp    80103f8c <argptr+0x45>
    return -1;
80103f9a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f9f:	eb eb                	jmp    80103f8c <argptr+0x45>
80103fa1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fa6:	eb e4                	jmp    80103f8c <argptr+0x45>
80103fa8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fad:	eb dd                	jmp    80103f8c <argptr+0x45>

80103faf <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80103faf:	55                   	push   %ebp
80103fb0:	89 e5                	mov    %esp,%ebp
80103fb2:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
80103fb5:	8d 45 f4             	lea    -0xc(%ebp),%eax
80103fb8:	50                   	push   %eax
80103fb9:	ff 75 08             	pushl  0x8(%ebp)
80103fbc:	e8 5e ff ff ff       	call   80103f1f <argint>
80103fc1:	83 c4 10             	add    $0x10,%esp
80103fc4:	85 c0                	test   %eax,%eax
80103fc6:	78 13                	js     80103fdb <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
80103fc8:	83 ec 08             	sub    $0x8,%esp
80103fcb:	ff 75 0c             	pushl  0xc(%ebp)
80103fce:	ff 75 f4             	pushl  -0xc(%ebp)
80103fd1:	e8 09 ff ff ff       	call   80103edf <fetchstr>
80103fd6:	83 c4 10             	add    $0x10,%esp
}
80103fd9:	c9                   	leave  
80103fda:	c3                   	ret    
    return -1;
80103fdb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fe0:	eb f7                	jmp    80103fd9 <argstr+0x2a>

80103fe2 <syscall>:
[SYS_dump_physmem]   sys_dump_physmem,
};

void
syscall(void)
{
80103fe2:	55                   	push   %ebp
80103fe3:	89 e5                	mov    %esp,%ebp
80103fe5:	53                   	push   %ebx
80103fe6:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
80103fe9:	e8 9b f2 ff ff       	call   80103289 <myproc>
80103fee:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
80103ff0:	8b 40 18             	mov    0x18(%eax),%eax
80103ff3:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80103ff6:	8d 50 ff             	lea    -0x1(%eax),%edx
80103ff9:	83 fa 15             	cmp    $0x15,%edx
80103ffc:	77 18                	ja     80104016 <syscall+0x34>
80103ffe:	8b 14 85 00 6c 10 80 	mov    -0x7fef9400(,%eax,4),%edx
80104005:	85 d2                	test   %edx,%edx
80104007:	74 0d                	je     80104016 <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
80104009:	ff d2                	call   *%edx
8010400b:	8b 53 18             	mov    0x18(%ebx),%edx
8010400e:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
80104011:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104014:	c9                   	leave  
80104015:	c3                   	ret    
            curproc->pid, curproc->name, num);
80104016:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
80104019:	50                   	push   %eax
8010401a:	52                   	push   %edx
8010401b:	ff 73 10             	pushl  0x10(%ebx)
8010401e:	68 d1 6b 10 80       	push   $0x80106bd1
80104023:	e8 e3 c5 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
80104028:	8b 43 18             	mov    0x18(%ebx),%eax
8010402b:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
80104032:	83 c4 10             	add    $0x10,%esp
}
80104035:	eb da                	jmp    80104011 <syscall+0x2f>

80104037 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80104037:	55                   	push   %ebp
80104038:	89 e5                	mov    %esp,%ebp
8010403a:	56                   	push   %esi
8010403b:	53                   	push   %ebx
8010403c:	83 ec 18             	sub    $0x18,%esp
8010403f:	89 d6                	mov    %edx,%esi
80104041:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80104043:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104046:	52                   	push   %edx
80104047:	50                   	push   %eax
80104048:	e8 d2 fe ff ff       	call   80103f1f <argint>
8010404d:	83 c4 10             	add    $0x10,%esp
80104050:	85 c0                	test   %eax,%eax
80104052:	78 2e                	js     80104082 <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
80104054:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
80104058:	77 2f                	ja     80104089 <argfd+0x52>
8010405a:	e8 2a f2 ff ff       	call   80103289 <myproc>
8010405f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104062:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
80104066:	85 c0                	test   %eax,%eax
80104068:	74 26                	je     80104090 <argfd+0x59>
    return -1;
  if(pfd)
8010406a:	85 f6                	test   %esi,%esi
8010406c:	74 02                	je     80104070 <argfd+0x39>
    *pfd = fd;
8010406e:	89 16                	mov    %edx,(%esi)
  if(pf)
80104070:	85 db                	test   %ebx,%ebx
80104072:	74 23                	je     80104097 <argfd+0x60>
    *pf = f;
80104074:	89 03                	mov    %eax,(%ebx)
  return 0;
80104076:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010407b:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010407e:	5b                   	pop    %ebx
8010407f:	5e                   	pop    %esi
80104080:	5d                   	pop    %ebp
80104081:	c3                   	ret    
    return -1;
80104082:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104087:	eb f2                	jmp    8010407b <argfd+0x44>
    return -1;
80104089:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010408e:	eb eb                	jmp    8010407b <argfd+0x44>
80104090:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104095:	eb e4                	jmp    8010407b <argfd+0x44>
  return 0;
80104097:	b8 00 00 00 00       	mov    $0x0,%eax
8010409c:	eb dd                	jmp    8010407b <argfd+0x44>

8010409e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
8010409e:	55                   	push   %ebp
8010409f:	89 e5                	mov    %esp,%ebp
801040a1:	53                   	push   %ebx
801040a2:	83 ec 04             	sub    $0x4,%esp
801040a5:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
801040a7:	e8 dd f1 ff ff       	call   80103289 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
801040ac:	ba 00 00 00 00       	mov    $0x0,%edx
801040b1:	83 fa 0f             	cmp    $0xf,%edx
801040b4:	7f 18                	jg     801040ce <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
801040b6:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
801040bb:	74 05                	je     801040c2 <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
801040bd:	83 c2 01             	add    $0x1,%edx
801040c0:	eb ef                	jmp    801040b1 <fdalloc+0x13>
      curproc->ofile[fd] = f;
801040c2:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
801040c6:	89 d0                	mov    %edx,%eax
801040c8:	83 c4 04             	add    $0x4,%esp
801040cb:	5b                   	pop    %ebx
801040cc:	5d                   	pop    %ebp
801040cd:	c3                   	ret    
  return -1;
801040ce:	ba ff ff ff ff       	mov    $0xffffffff,%edx
801040d3:	eb f1                	jmp    801040c6 <fdalloc+0x28>

801040d5 <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801040d5:	55                   	push   %ebp
801040d6:	89 e5                	mov    %esp,%ebp
801040d8:	56                   	push   %esi
801040d9:	53                   	push   %ebx
801040da:	83 ec 10             	sub    $0x10,%esp
801040dd:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801040df:	b8 20 00 00 00       	mov    $0x20,%eax
801040e4:	89 c6                	mov    %eax,%esi
801040e6:	39 43 58             	cmp    %eax,0x58(%ebx)
801040e9:	76 2e                	jbe    80104119 <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801040eb:	6a 10                	push   $0x10
801040ed:	50                   	push   %eax
801040ee:	8d 45 e8             	lea    -0x18(%ebp),%eax
801040f1:	50                   	push   %eax
801040f2:	53                   	push   %ebx
801040f3:	e8 7b d6 ff ff       	call   80101773 <readi>
801040f8:	83 c4 10             	add    $0x10,%esp
801040fb:	83 f8 10             	cmp    $0x10,%eax
801040fe:	75 0c                	jne    8010410c <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
80104100:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
80104105:	75 1e                	jne    80104125 <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104107:	8d 46 10             	lea    0x10(%esi),%eax
8010410a:	eb d8                	jmp    801040e4 <isdirempty+0xf>
      panic("isdirempty: readi");
8010410c:	83 ec 0c             	sub    $0xc,%esp
8010410f:	68 5c 6c 10 80       	push   $0x80106c5c
80104114:	e8 2f c2 ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
80104119:	b8 01 00 00 00       	mov    $0x1,%eax
}
8010411e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104121:	5b                   	pop    %ebx
80104122:	5e                   	pop    %esi
80104123:	5d                   	pop    %ebp
80104124:	c3                   	ret    
      return 0;
80104125:	b8 00 00 00 00       	mov    $0x0,%eax
8010412a:	eb f2                	jmp    8010411e <isdirempty+0x49>

8010412c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
8010412c:	55                   	push   %ebp
8010412d:	89 e5                	mov    %esp,%ebp
8010412f:	57                   	push   %edi
80104130:	56                   	push   %esi
80104131:	53                   	push   %ebx
80104132:	83 ec 44             	sub    $0x44,%esp
80104135:	89 55 c4             	mov    %edx,-0x3c(%ebp)
80104138:	89 4d c0             	mov    %ecx,-0x40(%ebp)
8010413b:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
8010413e:	8d 55 d6             	lea    -0x2a(%ebp),%edx
80104141:	52                   	push   %edx
80104142:	50                   	push   %eax
80104143:	e8 b1 da ff ff       	call   80101bf9 <nameiparent>
80104148:	89 c6                	mov    %eax,%esi
8010414a:	83 c4 10             	add    $0x10,%esp
8010414d:	85 c0                	test   %eax,%eax
8010414f:	0f 84 3a 01 00 00    	je     8010428f <create+0x163>
    return 0;
  ilock(dp);
80104155:	83 ec 0c             	sub    $0xc,%esp
80104158:	50                   	push   %eax
80104159:	e8 23 d4 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
8010415e:	83 c4 0c             	add    $0xc,%esp
80104161:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104164:	50                   	push   %eax
80104165:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104168:	50                   	push   %eax
80104169:	56                   	push   %esi
8010416a:	e8 41 d8 ff ff       	call   801019b0 <dirlookup>
8010416f:	89 c3                	mov    %eax,%ebx
80104171:	83 c4 10             	add    $0x10,%esp
80104174:	85 c0                	test   %eax,%eax
80104176:	74 3f                	je     801041b7 <create+0x8b>
    iunlockput(dp);
80104178:	83 ec 0c             	sub    $0xc,%esp
8010417b:	56                   	push   %esi
8010417c:	e8 a7 d5 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
80104181:	89 1c 24             	mov    %ebx,(%esp)
80104184:	e8 f8 d3 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80104189:	83 c4 10             	add    $0x10,%esp
8010418c:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
80104191:	75 11                	jne    801041a4 <create+0x78>
80104193:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
80104198:	75 0a                	jne    801041a4 <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
8010419a:	89 d8                	mov    %ebx,%eax
8010419c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010419f:	5b                   	pop    %ebx
801041a0:	5e                   	pop    %esi
801041a1:	5f                   	pop    %edi
801041a2:	5d                   	pop    %ebp
801041a3:	c3                   	ret    
    iunlockput(ip);
801041a4:	83 ec 0c             	sub    $0xc,%esp
801041a7:	53                   	push   %ebx
801041a8:	e8 7b d5 ff ff       	call   80101728 <iunlockput>
    return 0;
801041ad:	83 c4 10             	add    $0x10,%esp
801041b0:	bb 00 00 00 00       	mov    $0x0,%ebx
801041b5:	eb e3                	jmp    8010419a <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
801041b7:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
801041bb:	83 ec 08             	sub    $0x8,%esp
801041be:	50                   	push   %eax
801041bf:	ff 36                	pushl  (%esi)
801041c1:	e8 b8 d1 ff ff       	call   8010137e <ialloc>
801041c6:	89 c3                	mov    %eax,%ebx
801041c8:	83 c4 10             	add    $0x10,%esp
801041cb:	85 c0                	test   %eax,%eax
801041cd:	74 55                	je     80104224 <create+0xf8>
  ilock(ip);
801041cf:	83 ec 0c             	sub    $0xc,%esp
801041d2:	50                   	push   %eax
801041d3:	e8 a9 d3 ff ff       	call   80101581 <ilock>
  ip->major = major;
801041d8:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
801041dc:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
801041e0:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
801041e4:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
801041ea:	89 1c 24             	mov    %ebx,(%esp)
801041ed:	e8 2e d2 ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
801041f2:	83 c4 10             	add    $0x10,%esp
801041f5:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
801041fa:	74 35                	je     80104231 <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
801041fc:	83 ec 04             	sub    $0x4,%esp
801041ff:	ff 73 04             	pushl  0x4(%ebx)
80104202:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104205:	50                   	push   %eax
80104206:	56                   	push   %esi
80104207:	e8 24 d9 ff ff       	call   80101b30 <dirlink>
8010420c:	83 c4 10             	add    $0x10,%esp
8010420f:	85 c0                	test   %eax,%eax
80104211:	78 6f                	js     80104282 <create+0x156>
  iunlockput(dp);
80104213:	83 ec 0c             	sub    $0xc,%esp
80104216:	56                   	push   %esi
80104217:	e8 0c d5 ff ff       	call   80101728 <iunlockput>
  return ip;
8010421c:	83 c4 10             	add    $0x10,%esp
8010421f:	e9 76 ff ff ff       	jmp    8010419a <create+0x6e>
    panic("create: ialloc");
80104224:	83 ec 0c             	sub    $0xc,%esp
80104227:	68 6e 6c 10 80       	push   $0x80106c6e
8010422c:	e8 17 c1 ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
80104231:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104235:	83 c0 01             	add    $0x1,%eax
80104238:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
8010423c:	83 ec 0c             	sub    $0xc,%esp
8010423f:	56                   	push   %esi
80104240:	e8 db d1 ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80104245:	83 c4 0c             	add    $0xc,%esp
80104248:	ff 73 04             	pushl  0x4(%ebx)
8010424b:	68 7e 6c 10 80       	push   $0x80106c7e
80104250:	53                   	push   %ebx
80104251:	e8 da d8 ff ff       	call   80101b30 <dirlink>
80104256:	83 c4 10             	add    $0x10,%esp
80104259:	85 c0                	test   %eax,%eax
8010425b:	78 18                	js     80104275 <create+0x149>
8010425d:	83 ec 04             	sub    $0x4,%esp
80104260:	ff 76 04             	pushl  0x4(%esi)
80104263:	68 7d 6c 10 80       	push   $0x80106c7d
80104268:	53                   	push   %ebx
80104269:	e8 c2 d8 ff ff       	call   80101b30 <dirlink>
8010426e:	83 c4 10             	add    $0x10,%esp
80104271:	85 c0                	test   %eax,%eax
80104273:	79 87                	jns    801041fc <create+0xd0>
      panic("create dots");
80104275:	83 ec 0c             	sub    $0xc,%esp
80104278:	68 80 6c 10 80       	push   $0x80106c80
8010427d:	e8 c6 c0 ff ff       	call   80100348 <panic>
    panic("create: dirlink");
80104282:	83 ec 0c             	sub    $0xc,%esp
80104285:	68 8c 6c 10 80       	push   $0x80106c8c
8010428a:	e8 b9 c0 ff ff       	call   80100348 <panic>
    return 0;
8010428f:	89 c3                	mov    %eax,%ebx
80104291:	e9 04 ff ff ff       	jmp    8010419a <create+0x6e>

80104296 <sys_dup>:
{
80104296:	55                   	push   %ebp
80104297:	89 e5                	mov    %esp,%ebp
80104299:	53                   	push   %ebx
8010429a:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
8010429d:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801042a0:	ba 00 00 00 00       	mov    $0x0,%edx
801042a5:	b8 00 00 00 00       	mov    $0x0,%eax
801042aa:	e8 88 fd ff ff       	call   80104037 <argfd>
801042af:	85 c0                	test   %eax,%eax
801042b1:	78 23                	js     801042d6 <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
801042b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042b6:	e8 e3 fd ff ff       	call   8010409e <fdalloc>
801042bb:	89 c3                	mov    %eax,%ebx
801042bd:	85 c0                	test   %eax,%eax
801042bf:	78 1c                	js     801042dd <sys_dup+0x47>
  filedup(f);
801042c1:	83 ec 0c             	sub    $0xc,%esp
801042c4:	ff 75 f4             	pushl  -0xc(%ebp)
801042c7:	e8 c2 c9 ff ff       	call   80100c8e <filedup>
  return fd;
801042cc:	83 c4 10             	add    $0x10,%esp
}
801042cf:	89 d8                	mov    %ebx,%eax
801042d1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801042d4:	c9                   	leave  
801042d5:	c3                   	ret    
    return -1;
801042d6:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801042db:	eb f2                	jmp    801042cf <sys_dup+0x39>
    return -1;
801042dd:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801042e2:	eb eb                	jmp    801042cf <sys_dup+0x39>

801042e4 <sys_read>:
{
801042e4:	55                   	push   %ebp
801042e5:	89 e5                	mov    %esp,%ebp
801042e7:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801042ea:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801042ed:	ba 00 00 00 00       	mov    $0x0,%edx
801042f2:	b8 00 00 00 00       	mov    $0x0,%eax
801042f7:	e8 3b fd ff ff       	call   80104037 <argfd>
801042fc:	85 c0                	test   %eax,%eax
801042fe:	78 43                	js     80104343 <sys_read+0x5f>
80104300:	83 ec 08             	sub    $0x8,%esp
80104303:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104306:	50                   	push   %eax
80104307:	6a 02                	push   $0x2
80104309:	e8 11 fc ff ff       	call   80103f1f <argint>
8010430e:	83 c4 10             	add    $0x10,%esp
80104311:	85 c0                	test   %eax,%eax
80104313:	78 35                	js     8010434a <sys_read+0x66>
80104315:	83 ec 04             	sub    $0x4,%esp
80104318:	ff 75 f0             	pushl  -0x10(%ebp)
8010431b:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010431e:	50                   	push   %eax
8010431f:	6a 01                	push   $0x1
80104321:	e8 21 fc ff ff       	call   80103f47 <argptr>
80104326:	83 c4 10             	add    $0x10,%esp
80104329:	85 c0                	test   %eax,%eax
8010432b:	78 24                	js     80104351 <sys_read+0x6d>
  return fileread(f, p, n);
8010432d:	83 ec 04             	sub    $0x4,%esp
80104330:	ff 75 f0             	pushl  -0x10(%ebp)
80104333:	ff 75 ec             	pushl  -0x14(%ebp)
80104336:	ff 75 f4             	pushl  -0xc(%ebp)
80104339:	e8 99 ca ff ff       	call   80100dd7 <fileread>
8010433e:	83 c4 10             	add    $0x10,%esp
}
80104341:	c9                   	leave  
80104342:	c3                   	ret    
    return -1;
80104343:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104348:	eb f7                	jmp    80104341 <sys_read+0x5d>
8010434a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010434f:	eb f0                	jmp    80104341 <sys_read+0x5d>
80104351:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104356:	eb e9                	jmp    80104341 <sys_read+0x5d>

80104358 <sys_write>:
{
80104358:	55                   	push   %ebp
80104359:	89 e5                	mov    %esp,%ebp
8010435b:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010435e:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104361:	ba 00 00 00 00       	mov    $0x0,%edx
80104366:	b8 00 00 00 00       	mov    $0x0,%eax
8010436b:	e8 c7 fc ff ff       	call   80104037 <argfd>
80104370:	85 c0                	test   %eax,%eax
80104372:	78 43                	js     801043b7 <sys_write+0x5f>
80104374:	83 ec 08             	sub    $0x8,%esp
80104377:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010437a:	50                   	push   %eax
8010437b:	6a 02                	push   $0x2
8010437d:	e8 9d fb ff ff       	call   80103f1f <argint>
80104382:	83 c4 10             	add    $0x10,%esp
80104385:	85 c0                	test   %eax,%eax
80104387:	78 35                	js     801043be <sys_write+0x66>
80104389:	83 ec 04             	sub    $0x4,%esp
8010438c:	ff 75 f0             	pushl  -0x10(%ebp)
8010438f:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104392:	50                   	push   %eax
80104393:	6a 01                	push   $0x1
80104395:	e8 ad fb ff ff       	call   80103f47 <argptr>
8010439a:	83 c4 10             	add    $0x10,%esp
8010439d:	85 c0                	test   %eax,%eax
8010439f:	78 24                	js     801043c5 <sys_write+0x6d>
  return filewrite(f, p, n);
801043a1:	83 ec 04             	sub    $0x4,%esp
801043a4:	ff 75 f0             	pushl  -0x10(%ebp)
801043a7:	ff 75 ec             	pushl  -0x14(%ebp)
801043aa:	ff 75 f4             	pushl  -0xc(%ebp)
801043ad:	e8 aa ca ff ff       	call   80100e5c <filewrite>
801043b2:	83 c4 10             	add    $0x10,%esp
}
801043b5:	c9                   	leave  
801043b6:	c3                   	ret    
    return -1;
801043b7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043bc:	eb f7                	jmp    801043b5 <sys_write+0x5d>
801043be:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043c3:	eb f0                	jmp    801043b5 <sys_write+0x5d>
801043c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043ca:	eb e9                	jmp    801043b5 <sys_write+0x5d>

801043cc <sys_close>:
{
801043cc:	55                   	push   %ebp
801043cd:	89 e5                	mov    %esp,%ebp
801043cf:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
801043d2:	8d 4d f0             	lea    -0x10(%ebp),%ecx
801043d5:	8d 55 f4             	lea    -0xc(%ebp),%edx
801043d8:	b8 00 00 00 00       	mov    $0x0,%eax
801043dd:	e8 55 fc ff ff       	call   80104037 <argfd>
801043e2:	85 c0                	test   %eax,%eax
801043e4:	78 25                	js     8010440b <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
801043e6:	e8 9e ee ff ff       	call   80103289 <myproc>
801043eb:	8b 55 f4             	mov    -0xc(%ebp),%edx
801043ee:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
801043f5:	00 
  fileclose(f);
801043f6:	83 ec 0c             	sub    $0xc,%esp
801043f9:	ff 75 f0             	pushl  -0x10(%ebp)
801043fc:	e8 d2 c8 ff ff       	call   80100cd3 <fileclose>
  return 0;
80104401:	83 c4 10             	add    $0x10,%esp
80104404:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104409:	c9                   	leave  
8010440a:	c3                   	ret    
    return -1;
8010440b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104410:	eb f7                	jmp    80104409 <sys_close+0x3d>

80104412 <sys_fstat>:
{
80104412:	55                   	push   %ebp
80104413:	89 e5                	mov    %esp,%ebp
80104415:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80104418:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010441b:	ba 00 00 00 00       	mov    $0x0,%edx
80104420:	b8 00 00 00 00       	mov    $0x0,%eax
80104425:	e8 0d fc ff ff       	call   80104037 <argfd>
8010442a:	85 c0                	test   %eax,%eax
8010442c:	78 2a                	js     80104458 <sys_fstat+0x46>
8010442e:	83 ec 04             	sub    $0x4,%esp
80104431:	6a 14                	push   $0x14
80104433:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104436:	50                   	push   %eax
80104437:	6a 01                	push   $0x1
80104439:	e8 09 fb ff ff       	call   80103f47 <argptr>
8010443e:	83 c4 10             	add    $0x10,%esp
80104441:	85 c0                	test   %eax,%eax
80104443:	78 1a                	js     8010445f <sys_fstat+0x4d>
  return filestat(f, st);
80104445:	83 ec 08             	sub    $0x8,%esp
80104448:	ff 75 f0             	pushl  -0x10(%ebp)
8010444b:	ff 75 f4             	pushl  -0xc(%ebp)
8010444e:	e8 3d c9 ff ff       	call   80100d90 <filestat>
80104453:	83 c4 10             	add    $0x10,%esp
}
80104456:	c9                   	leave  
80104457:	c3                   	ret    
    return -1;
80104458:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010445d:	eb f7                	jmp    80104456 <sys_fstat+0x44>
8010445f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104464:	eb f0                	jmp    80104456 <sys_fstat+0x44>

80104466 <sys_link>:
{
80104466:	55                   	push   %ebp
80104467:	89 e5                	mov    %esp,%ebp
80104469:	56                   	push   %esi
8010446a:	53                   	push   %ebx
8010446b:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
8010446e:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104471:	50                   	push   %eax
80104472:	6a 00                	push   $0x0
80104474:	e8 36 fb ff ff       	call   80103faf <argstr>
80104479:	83 c4 10             	add    $0x10,%esp
8010447c:	85 c0                	test   %eax,%eax
8010447e:	0f 88 32 01 00 00    	js     801045b6 <sys_link+0x150>
80104484:	83 ec 08             	sub    $0x8,%esp
80104487:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010448a:	50                   	push   %eax
8010448b:	6a 01                	push   $0x1
8010448d:	e8 1d fb ff ff       	call   80103faf <argstr>
80104492:	83 c4 10             	add    $0x10,%esp
80104495:	85 c0                	test   %eax,%eax
80104497:	0f 88 20 01 00 00    	js     801045bd <sys_link+0x157>
  begin_op();
8010449d:	e8 9f e3 ff ff       	call   80102841 <begin_op>
  if((ip = namei(old)) == 0){
801044a2:	83 ec 0c             	sub    $0xc,%esp
801044a5:	ff 75 e0             	pushl  -0x20(%ebp)
801044a8:	e8 34 d7 ff ff       	call   80101be1 <namei>
801044ad:	89 c3                	mov    %eax,%ebx
801044af:	83 c4 10             	add    $0x10,%esp
801044b2:	85 c0                	test   %eax,%eax
801044b4:	0f 84 99 00 00 00    	je     80104553 <sys_link+0xed>
  ilock(ip);
801044ba:	83 ec 0c             	sub    $0xc,%esp
801044bd:	50                   	push   %eax
801044be:	e8 be d0 ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
801044c3:	83 c4 10             	add    $0x10,%esp
801044c6:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801044cb:	0f 84 8e 00 00 00    	je     8010455f <sys_link+0xf9>
  ip->nlink++;
801044d1:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801044d5:	83 c0 01             	add    $0x1,%eax
801044d8:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801044dc:	83 ec 0c             	sub    $0xc,%esp
801044df:	53                   	push   %ebx
801044e0:	e8 3b cf ff ff       	call   80101420 <iupdate>
  iunlock(ip);
801044e5:	89 1c 24             	mov    %ebx,(%esp)
801044e8:	e8 56 d1 ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
801044ed:	83 c4 08             	add    $0x8,%esp
801044f0:	8d 45 ea             	lea    -0x16(%ebp),%eax
801044f3:	50                   	push   %eax
801044f4:	ff 75 e4             	pushl  -0x1c(%ebp)
801044f7:	e8 fd d6 ff ff       	call   80101bf9 <nameiparent>
801044fc:	89 c6                	mov    %eax,%esi
801044fe:	83 c4 10             	add    $0x10,%esp
80104501:	85 c0                	test   %eax,%eax
80104503:	74 7e                	je     80104583 <sys_link+0x11d>
  ilock(dp);
80104505:	83 ec 0c             	sub    $0xc,%esp
80104508:	50                   	push   %eax
80104509:	e8 73 d0 ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
8010450e:	83 c4 10             	add    $0x10,%esp
80104511:	8b 03                	mov    (%ebx),%eax
80104513:	39 06                	cmp    %eax,(%esi)
80104515:	75 60                	jne    80104577 <sys_link+0x111>
80104517:	83 ec 04             	sub    $0x4,%esp
8010451a:	ff 73 04             	pushl  0x4(%ebx)
8010451d:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104520:	50                   	push   %eax
80104521:	56                   	push   %esi
80104522:	e8 09 d6 ff ff       	call   80101b30 <dirlink>
80104527:	83 c4 10             	add    $0x10,%esp
8010452a:	85 c0                	test   %eax,%eax
8010452c:	78 49                	js     80104577 <sys_link+0x111>
  iunlockput(dp);
8010452e:	83 ec 0c             	sub    $0xc,%esp
80104531:	56                   	push   %esi
80104532:	e8 f1 d1 ff ff       	call   80101728 <iunlockput>
  iput(ip);
80104537:	89 1c 24             	mov    %ebx,(%esp)
8010453a:	e8 49 d1 ff ff       	call   80101688 <iput>
  end_op();
8010453f:	e8 77 e3 ff ff       	call   801028bb <end_op>
  return 0;
80104544:	83 c4 10             	add    $0x10,%esp
80104547:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010454c:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010454f:	5b                   	pop    %ebx
80104550:	5e                   	pop    %esi
80104551:	5d                   	pop    %ebp
80104552:	c3                   	ret    
    end_op();
80104553:	e8 63 e3 ff ff       	call   801028bb <end_op>
    return -1;
80104558:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010455d:	eb ed                	jmp    8010454c <sys_link+0xe6>
    iunlockput(ip);
8010455f:	83 ec 0c             	sub    $0xc,%esp
80104562:	53                   	push   %ebx
80104563:	e8 c0 d1 ff ff       	call   80101728 <iunlockput>
    end_op();
80104568:	e8 4e e3 ff ff       	call   801028bb <end_op>
    return -1;
8010456d:	83 c4 10             	add    $0x10,%esp
80104570:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104575:	eb d5                	jmp    8010454c <sys_link+0xe6>
    iunlockput(dp);
80104577:	83 ec 0c             	sub    $0xc,%esp
8010457a:	56                   	push   %esi
8010457b:	e8 a8 d1 ff ff       	call   80101728 <iunlockput>
    goto bad;
80104580:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
80104583:	83 ec 0c             	sub    $0xc,%esp
80104586:	53                   	push   %ebx
80104587:	e8 f5 cf ff ff       	call   80101581 <ilock>
  ip->nlink--;
8010458c:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104590:	83 e8 01             	sub    $0x1,%eax
80104593:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104597:	89 1c 24             	mov    %ebx,(%esp)
8010459a:	e8 81 ce ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
8010459f:	89 1c 24             	mov    %ebx,(%esp)
801045a2:	e8 81 d1 ff ff       	call   80101728 <iunlockput>
  end_op();
801045a7:	e8 0f e3 ff ff       	call   801028bb <end_op>
  return -1;
801045ac:	83 c4 10             	add    $0x10,%esp
801045af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045b4:	eb 96                	jmp    8010454c <sys_link+0xe6>
    return -1;
801045b6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045bb:	eb 8f                	jmp    8010454c <sys_link+0xe6>
801045bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045c2:	eb 88                	jmp    8010454c <sys_link+0xe6>

801045c4 <sys_unlink>:
{
801045c4:	55                   	push   %ebp
801045c5:	89 e5                	mov    %esp,%ebp
801045c7:	57                   	push   %edi
801045c8:	56                   	push   %esi
801045c9:	53                   	push   %ebx
801045ca:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
801045cd:	8d 45 c4             	lea    -0x3c(%ebp),%eax
801045d0:	50                   	push   %eax
801045d1:	6a 00                	push   $0x0
801045d3:	e8 d7 f9 ff ff       	call   80103faf <argstr>
801045d8:	83 c4 10             	add    $0x10,%esp
801045db:	85 c0                	test   %eax,%eax
801045dd:	0f 88 83 01 00 00    	js     80104766 <sys_unlink+0x1a2>
  begin_op();
801045e3:	e8 59 e2 ff ff       	call   80102841 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
801045e8:	83 ec 08             	sub    $0x8,%esp
801045eb:	8d 45 ca             	lea    -0x36(%ebp),%eax
801045ee:	50                   	push   %eax
801045ef:	ff 75 c4             	pushl  -0x3c(%ebp)
801045f2:	e8 02 d6 ff ff       	call   80101bf9 <nameiparent>
801045f7:	89 c6                	mov    %eax,%esi
801045f9:	83 c4 10             	add    $0x10,%esp
801045fc:	85 c0                	test   %eax,%eax
801045fe:	0f 84 ed 00 00 00    	je     801046f1 <sys_unlink+0x12d>
  ilock(dp);
80104604:	83 ec 0c             	sub    $0xc,%esp
80104607:	50                   	push   %eax
80104608:	e8 74 cf ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
8010460d:	83 c4 08             	add    $0x8,%esp
80104610:	68 7e 6c 10 80       	push   $0x80106c7e
80104615:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104618:	50                   	push   %eax
80104619:	e8 7d d3 ff ff       	call   8010199b <namecmp>
8010461e:	83 c4 10             	add    $0x10,%esp
80104621:	85 c0                	test   %eax,%eax
80104623:	0f 84 fc 00 00 00    	je     80104725 <sys_unlink+0x161>
80104629:	83 ec 08             	sub    $0x8,%esp
8010462c:	68 7d 6c 10 80       	push   $0x80106c7d
80104631:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104634:	50                   	push   %eax
80104635:	e8 61 d3 ff ff       	call   8010199b <namecmp>
8010463a:	83 c4 10             	add    $0x10,%esp
8010463d:	85 c0                	test   %eax,%eax
8010463f:	0f 84 e0 00 00 00    	je     80104725 <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
80104645:	83 ec 04             	sub    $0x4,%esp
80104648:	8d 45 c0             	lea    -0x40(%ebp),%eax
8010464b:	50                   	push   %eax
8010464c:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010464f:	50                   	push   %eax
80104650:	56                   	push   %esi
80104651:	e8 5a d3 ff ff       	call   801019b0 <dirlookup>
80104656:	89 c3                	mov    %eax,%ebx
80104658:	83 c4 10             	add    $0x10,%esp
8010465b:	85 c0                	test   %eax,%eax
8010465d:	0f 84 c2 00 00 00    	je     80104725 <sys_unlink+0x161>
  ilock(ip);
80104663:	83 ec 0c             	sub    $0xc,%esp
80104666:	50                   	push   %eax
80104667:	e8 15 cf ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
8010466c:	83 c4 10             	add    $0x10,%esp
8010466f:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
80104674:	0f 8e 83 00 00 00    	jle    801046fd <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010467a:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010467f:	0f 84 85 00 00 00    	je     8010470a <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
80104685:	83 ec 04             	sub    $0x4,%esp
80104688:	6a 10                	push   $0x10
8010468a:	6a 00                	push   $0x0
8010468c:	8d 7d d8             	lea    -0x28(%ebp),%edi
8010468f:	57                   	push   %edi
80104690:	e8 3f f6 ff ff       	call   80103cd4 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104695:	6a 10                	push   $0x10
80104697:	ff 75 c0             	pushl  -0x40(%ebp)
8010469a:	57                   	push   %edi
8010469b:	56                   	push   %esi
8010469c:	e8 cf d1 ff ff       	call   80101870 <writei>
801046a1:	83 c4 20             	add    $0x20,%esp
801046a4:	83 f8 10             	cmp    $0x10,%eax
801046a7:	0f 85 90 00 00 00    	jne    8010473d <sys_unlink+0x179>
  if(ip->type == T_DIR){
801046ad:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801046b2:	0f 84 92 00 00 00    	je     8010474a <sys_unlink+0x186>
  iunlockput(dp);
801046b8:	83 ec 0c             	sub    $0xc,%esp
801046bb:	56                   	push   %esi
801046bc:	e8 67 d0 ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
801046c1:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801046c5:	83 e8 01             	sub    $0x1,%eax
801046c8:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801046cc:	89 1c 24             	mov    %ebx,(%esp)
801046cf:	e8 4c cd ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
801046d4:	89 1c 24             	mov    %ebx,(%esp)
801046d7:	e8 4c d0 ff ff       	call   80101728 <iunlockput>
  end_op();
801046dc:	e8 da e1 ff ff       	call   801028bb <end_op>
  return 0;
801046e1:	83 c4 10             	add    $0x10,%esp
801046e4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801046e9:	8d 65 f4             	lea    -0xc(%ebp),%esp
801046ec:	5b                   	pop    %ebx
801046ed:	5e                   	pop    %esi
801046ee:	5f                   	pop    %edi
801046ef:	5d                   	pop    %ebp
801046f0:	c3                   	ret    
    end_op();
801046f1:	e8 c5 e1 ff ff       	call   801028bb <end_op>
    return -1;
801046f6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046fb:	eb ec                	jmp    801046e9 <sys_unlink+0x125>
    panic("unlink: nlink < 1");
801046fd:	83 ec 0c             	sub    $0xc,%esp
80104700:	68 9c 6c 10 80       	push   $0x80106c9c
80104705:	e8 3e bc ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010470a:	89 d8                	mov    %ebx,%eax
8010470c:	e8 c4 f9 ff ff       	call   801040d5 <isdirempty>
80104711:	85 c0                	test   %eax,%eax
80104713:	0f 85 6c ff ff ff    	jne    80104685 <sys_unlink+0xc1>
    iunlockput(ip);
80104719:	83 ec 0c             	sub    $0xc,%esp
8010471c:	53                   	push   %ebx
8010471d:	e8 06 d0 ff ff       	call   80101728 <iunlockput>
    goto bad;
80104722:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
80104725:	83 ec 0c             	sub    $0xc,%esp
80104728:	56                   	push   %esi
80104729:	e8 fa cf ff ff       	call   80101728 <iunlockput>
  end_op();
8010472e:	e8 88 e1 ff ff       	call   801028bb <end_op>
  return -1;
80104733:	83 c4 10             	add    $0x10,%esp
80104736:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010473b:	eb ac                	jmp    801046e9 <sys_unlink+0x125>
    panic("unlink: writei");
8010473d:	83 ec 0c             	sub    $0xc,%esp
80104740:	68 ae 6c 10 80       	push   $0x80106cae
80104745:	e8 fe bb ff ff       	call   80100348 <panic>
    dp->nlink--;
8010474a:	0f b7 46 56          	movzwl 0x56(%esi),%eax
8010474e:	83 e8 01             	sub    $0x1,%eax
80104751:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104755:	83 ec 0c             	sub    $0xc,%esp
80104758:	56                   	push   %esi
80104759:	e8 c2 cc ff ff       	call   80101420 <iupdate>
8010475e:	83 c4 10             	add    $0x10,%esp
80104761:	e9 52 ff ff ff       	jmp    801046b8 <sys_unlink+0xf4>
    return -1;
80104766:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010476b:	e9 79 ff ff ff       	jmp    801046e9 <sys_unlink+0x125>

80104770 <sys_open>:

int
sys_open(void)
{
80104770:	55                   	push   %ebp
80104771:	89 e5                	mov    %esp,%ebp
80104773:	57                   	push   %edi
80104774:	56                   	push   %esi
80104775:	53                   	push   %ebx
80104776:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80104779:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010477c:	50                   	push   %eax
8010477d:	6a 00                	push   $0x0
8010477f:	e8 2b f8 ff ff       	call   80103faf <argstr>
80104784:	83 c4 10             	add    $0x10,%esp
80104787:	85 c0                	test   %eax,%eax
80104789:	0f 88 30 01 00 00    	js     801048bf <sys_open+0x14f>
8010478f:	83 ec 08             	sub    $0x8,%esp
80104792:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104795:	50                   	push   %eax
80104796:	6a 01                	push   $0x1
80104798:	e8 82 f7 ff ff       	call   80103f1f <argint>
8010479d:	83 c4 10             	add    $0x10,%esp
801047a0:	85 c0                	test   %eax,%eax
801047a2:	0f 88 21 01 00 00    	js     801048c9 <sys_open+0x159>
    return -1;

  begin_op();
801047a8:	e8 94 e0 ff ff       	call   80102841 <begin_op>

  if(omode & O_CREATE){
801047ad:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
801047b1:	0f 84 84 00 00 00    	je     8010483b <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
801047b7:	83 ec 0c             	sub    $0xc,%esp
801047ba:	6a 00                	push   $0x0
801047bc:	b9 00 00 00 00       	mov    $0x0,%ecx
801047c1:	ba 02 00 00 00       	mov    $0x2,%edx
801047c6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801047c9:	e8 5e f9 ff ff       	call   8010412c <create>
801047ce:	89 c6                	mov    %eax,%esi
    if(ip == 0){
801047d0:	83 c4 10             	add    $0x10,%esp
801047d3:	85 c0                	test   %eax,%eax
801047d5:	74 58                	je     8010482f <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
801047d7:	e8 51 c4 ff ff       	call   80100c2d <filealloc>
801047dc:	89 c3                	mov    %eax,%ebx
801047de:	85 c0                	test   %eax,%eax
801047e0:	0f 84 ae 00 00 00    	je     80104894 <sys_open+0x124>
801047e6:	e8 b3 f8 ff ff       	call   8010409e <fdalloc>
801047eb:	89 c7                	mov    %eax,%edi
801047ed:	85 c0                	test   %eax,%eax
801047ef:	0f 88 9f 00 00 00    	js     80104894 <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
801047f5:	83 ec 0c             	sub    $0xc,%esp
801047f8:	56                   	push   %esi
801047f9:	e8 45 ce ff ff       	call   80101643 <iunlock>
  end_op();
801047fe:	e8 b8 e0 ff ff       	call   801028bb <end_op>

  f->type = FD_INODE;
80104803:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
80104809:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
8010480c:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
80104813:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104816:	83 c4 10             	add    $0x10,%esp
80104819:	a8 01                	test   $0x1,%al
8010481b:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
8010481f:	a8 03                	test   $0x3,%al
80104821:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
80104825:	89 f8                	mov    %edi,%eax
80104827:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010482a:	5b                   	pop    %ebx
8010482b:	5e                   	pop    %esi
8010482c:	5f                   	pop    %edi
8010482d:	5d                   	pop    %ebp
8010482e:	c3                   	ret    
      end_op();
8010482f:	e8 87 e0 ff ff       	call   801028bb <end_op>
      return -1;
80104834:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104839:	eb ea                	jmp    80104825 <sys_open+0xb5>
    if((ip = namei(path)) == 0){
8010483b:	83 ec 0c             	sub    $0xc,%esp
8010483e:	ff 75 e4             	pushl  -0x1c(%ebp)
80104841:	e8 9b d3 ff ff       	call   80101be1 <namei>
80104846:	89 c6                	mov    %eax,%esi
80104848:	83 c4 10             	add    $0x10,%esp
8010484b:	85 c0                	test   %eax,%eax
8010484d:	74 39                	je     80104888 <sys_open+0x118>
    ilock(ip);
8010484f:	83 ec 0c             	sub    $0xc,%esp
80104852:	50                   	push   %eax
80104853:	e8 29 cd ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80104858:	83 c4 10             	add    $0x10,%esp
8010485b:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104860:	0f 85 71 ff ff ff    	jne    801047d7 <sys_open+0x67>
80104866:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010486a:	0f 84 67 ff ff ff    	je     801047d7 <sys_open+0x67>
      iunlockput(ip);
80104870:	83 ec 0c             	sub    $0xc,%esp
80104873:	56                   	push   %esi
80104874:	e8 af ce ff ff       	call   80101728 <iunlockput>
      end_op();
80104879:	e8 3d e0 ff ff       	call   801028bb <end_op>
      return -1;
8010487e:	83 c4 10             	add    $0x10,%esp
80104881:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104886:	eb 9d                	jmp    80104825 <sys_open+0xb5>
      end_op();
80104888:	e8 2e e0 ff ff       	call   801028bb <end_op>
      return -1;
8010488d:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104892:	eb 91                	jmp    80104825 <sys_open+0xb5>
    if(f)
80104894:	85 db                	test   %ebx,%ebx
80104896:	74 0c                	je     801048a4 <sys_open+0x134>
      fileclose(f);
80104898:	83 ec 0c             	sub    $0xc,%esp
8010489b:	53                   	push   %ebx
8010489c:	e8 32 c4 ff ff       	call   80100cd3 <fileclose>
801048a1:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
801048a4:	83 ec 0c             	sub    $0xc,%esp
801048a7:	56                   	push   %esi
801048a8:	e8 7b ce ff ff       	call   80101728 <iunlockput>
    end_op();
801048ad:	e8 09 e0 ff ff       	call   801028bb <end_op>
    return -1;
801048b2:	83 c4 10             	add    $0x10,%esp
801048b5:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801048ba:	e9 66 ff ff ff       	jmp    80104825 <sys_open+0xb5>
    return -1;
801048bf:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801048c4:	e9 5c ff ff ff       	jmp    80104825 <sys_open+0xb5>
801048c9:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801048ce:	e9 52 ff ff ff       	jmp    80104825 <sys_open+0xb5>

801048d3 <sys_mkdir>:

int
sys_mkdir(void)
{
801048d3:	55                   	push   %ebp
801048d4:	89 e5                	mov    %esp,%ebp
801048d6:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
801048d9:	e8 63 df ff ff       	call   80102841 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
801048de:	83 ec 08             	sub    $0x8,%esp
801048e1:	8d 45 f4             	lea    -0xc(%ebp),%eax
801048e4:	50                   	push   %eax
801048e5:	6a 00                	push   $0x0
801048e7:	e8 c3 f6 ff ff       	call   80103faf <argstr>
801048ec:	83 c4 10             	add    $0x10,%esp
801048ef:	85 c0                	test   %eax,%eax
801048f1:	78 36                	js     80104929 <sys_mkdir+0x56>
801048f3:	83 ec 0c             	sub    $0xc,%esp
801048f6:	6a 00                	push   $0x0
801048f8:	b9 00 00 00 00       	mov    $0x0,%ecx
801048fd:	ba 01 00 00 00       	mov    $0x1,%edx
80104902:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104905:	e8 22 f8 ff ff       	call   8010412c <create>
8010490a:	83 c4 10             	add    $0x10,%esp
8010490d:	85 c0                	test   %eax,%eax
8010490f:	74 18                	je     80104929 <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104911:	83 ec 0c             	sub    $0xc,%esp
80104914:	50                   	push   %eax
80104915:	e8 0e ce ff ff       	call   80101728 <iunlockput>
  end_op();
8010491a:	e8 9c df ff ff       	call   801028bb <end_op>
  return 0;
8010491f:	83 c4 10             	add    $0x10,%esp
80104922:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104927:	c9                   	leave  
80104928:	c3                   	ret    
    end_op();
80104929:	e8 8d df ff ff       	call   801028bb <end_op>
    return -1;
8010492e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104933:	eb f2                	jmp    80104927 <sys_mkdir+0x54>

80104935 <sys_mknod>:

int
sys_mknod(void)
{
80104935:	55                   	push   %ebp
80104936:	89 e5                	mov    %esp,%ebp
80104938:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
8010493b:	e8 01 df ff ff       	call   80102841 <begin_op>
  if((argstr(0, &path)) < 0 ||
80104940:	83 ec 08             	sub    $0x8,%esp
80104943:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104946:	50                   	push   %eax
80104947:	6a 00                	push   $0x0
80104949:	e8 61 f6 ff ff       	call   80103faf <argstr>
8010494e:	83 c4 10             	add    $0x10,%esp
80104951:	85 c0                	test   %eax,%eax
80104953:	78 62                	js     801049b7 <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104955:	83 ec 08             	sub    $0x8,%esp
80104958:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010495b:	50                   	push   %eax
8010495c:	6a 01                	push   $0x1
8010495e:	e8 bc f5 ff ff       	call   80103f1f <argint>
  if((argstr(0, &path)) < 0 ||
80104963:	83 c4 10             	add    $0x10,%esp
80104966:	85 c0                	test   %eax,%eax
80104968:	78 4d                	js     801049b7 <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
8010496a:	83 ec 08             	sub    $0x8,%esp
8010496d:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104970:	50                   	push   %eax
80104971:	6a 02                	push   $0x2
80104973:	e8 a7 f5 ff ff       	call   80103f1f <argint>
     argint(1, &major) < 0 ||
80104978:	83 c4 10             	add    $0x10,%esp
8010497b:	85 c0                	test   %eax,%eax
8010497d:	78 38                	js     801049b7 <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
8010497f:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104983:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104987:	83 ec 0c             	sub    $0xc,%esp
8010498a:	50                   	push   %eax
8010498b:	ba 03 00 00 00       	mov    $0x3,%edx
80104990:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104993:	e8 94 f7 ff ff       	call   8010412c <create>
80104998:	83 c4 10             	add    $0x10,%esp
8010499b:	85 c0                	test   %eax,%eax
8010499d:	74 18                	je     801049b7 <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
8010499f:	83 ec 0c             	sub    $0xc,%esp
801049a2:	50                   	push   %eax
801049a3:	e8 80 cd ff ff       	call   80101728 <iunlockput>
  end_op();
801049a8:	e8 0e df ff ff       	call   801028bb <end_op>
  return 0;
801049ad:	83 c4 10             	add    $0x10,%esp
801049b0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801049b5:	c9                   	leave  
801049b6:	c3                   	ret    
    end_op();
801049b7:	e8 ff de ff ff       	call   801028bb <end_op>
    return -1;
801049bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049c1:	eb f2                	jmp    801049b5 <sys_mknod+0x80>

801049c3 <sys_chdir>:

int
sys_chdir(void)
{
801049c3:	55                   	push   %ebp
801049c4:	89 e5                	mov    %esp,%ebp
801049c6:	56                   	push   %esi
801049c7:	53                   	push   %ebx
801049c8:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
801049cb:	e8 b9 e8 ff ff       	call   80103289 <myproc>
801049d0:	89 c6                	mov    %eax,%esi
  
  begin_op();
801049d2:	e8 6a de ff ff       	call   80102841 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
801049d7:	83 ec 08             	sub    $0x8,%esp
801049da:	8d 45 f4             	lea    -0xc(%ebp),%eax
801049dd:	50                   	push   %eax
801049de:	6a 00                	push   $0x0
801049e0:	e8 ca f5 ff ff       	call   80103faf <argstr>
801049e5:	83 c4 10             	add    $0x10,%esp
801049e8:	85 c0                	test   %eax,%eax
801049ea:	78 52                	js     80104a3e <sys_chdir+0x7b>
801049ec:	83 ec 0c             	sub    $0xc,%esp
801049ef:	ff 75 f4             	pushl  -0xc(%ebp)
801049f2:	e8 ea d1 ff ff       	call   80101be1 <namei>
801049f7:	89 c3                	mov    %eax,%ebx
801049f9:	83 c4 10             	add    $0x10,%esp
801049fc:	85 c0                	test   %eax,%eax
801049fe:	74 3e                	je     80104a3e <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104a00:	83 ec 0c             	sub    $0xc,%esp
80104a03:	50                   	push   %eax
80104a04:	e8 78 cb ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104a09:	83 c4 10             	add    $0x10,%esp
80104a0c:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104a11:	75 37                	jne    80104a4a <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104a13:	83 ec 0c             	sub    $0xc,%esp
80104a16:	53                   	push   %ebx
80104a17:	e8 27 cc ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104a1c:	83 c4 04             	add    $0x4,%esp
80104a1f:	ff 76 68             	pushl  0x68(%esi)
80104a22:	e8 61 cc ff ff       	call   80101688 <iput>
  end_op();
80104a27:	e8 8f de ff ff       	call   801028bb <end_op>
  curproc->cwd = ip;
80104a2c:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104a2f:	83 c4 10             	add    $0x10,%esp
80104a32:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a37:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104a3a:	5b                   	pop    %ebx
80104a3b:	5e                   	pop    %esi
80104a3c:	5d                   	pop    %ebp
80104a3d:	c3                   	ret    
    end_op();
80104a3e:	e8 78 de ff ff       	call   801028bb <end_op>
    return -1;
80104a43:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a48:	eb ed                	jmp    80104a37 <sys_chdir+0x74>
    iunlockput(ip);
80104a4a:	83 ec 0c             	sub    $0xc,%esp
80104a4d:	53                   	push   %ebx
80104a4e:	e8 d5 cc ff ff       	call   80101728 <iunlockput>
    end_op();
80104a53:	e8 63 de ff ff       	call   801028bb <end_op>
    return -1;
80104a58:	83 c4 10             	add    $0x10,%esp
80104a5b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a60:	eb d5                	jmp    80104a37 <sys_chdir+0x74>

80104a62 <sys_exec>:

int
sys_exec(void)
{
80104a62:	55                   	push   %ebp
80104a63:	89 e5                	mov    %esp,%ebp
80104a65:	53                   	push   %ebx
80104a66:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104a6c:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104a6f:	50                   	push   %eax
80104a70:	6a 00                	push   $0x0
80104a72:	e8 38 f5 ff ff       	call   80103faf <argstr>
80104a77:	83 c4 10             	add    $0x10,%esp
80104a7a:	85 c0                	test   %eax,%eax
80104a7c:	0f 88 a8 00 00 00    	js     80104b2a <sys_exec+0xc8>
80104a82:	83 ec 08             	sub    $0x8,%esp
80104a85:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104a8b:	50                   	push   %eax
80104a8c:	6a 01                	push   $0x1
80104a8e:	e8 8c f4 ff ff       	call   80103f1f <argint>
80104a93:	83 c4 10             	add    $0x10,%esp
80104a96:	85 c0                	test   %eax,%eax
80104a98:	0f 88 93 00 00 00    	js     80104b31 <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104a9e:	83 ec 04             	sub    $0x4,%esp
80104aa1:	68 80 00 00 00       	push   $0x80
80104aa6:	6a 00                	push   $0x0
80104aa8:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104aae:	50                   	push   %eax
80104aaf:	e8 20 f2 ff ff       	call   80103cd4 <memset>
80104ab4:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104ab7:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104abc:	83 fb 1f             	cmp    $0x1f,%ebx
80104abf:	77 77                	ja     80104b38 <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104ac1:	83 ec 08             	sub    $0x8,%esp
80104ac4:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104aca:	50                   	push   %eax
80104acb:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104ad1:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104ad4:	50                   	push   %eax
80104ad5:	e8 c9 f3 ff ff       	call   80103ea3 <fetchint>
80104ada:	83 c4 10             	add    $0x10,%esp
80104add:	85 c0                	test   %eax,%eax
80104adf:	78 5e                	js     80104b3f <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104ae1:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104ae7:	85 c0                	test   %eax,%eax
80104ae9:	74 1d                	je     80104b08 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104aeb:	83 ec 08             	sub    $0x8,%esp
80104aee:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104af5:	52                   	push   %edx
80104af6:	50                   	push   %eax
80104af7:	e8 e3 f3 ff ff       	call   80103edf <fetchstr>
80104afc:	83 c4 10             	add    $0x10,%esp
80104aff:	85 c0                	test   %eax,%eax
80104b01:	78 46                	js     80104b49 <sys_exec+0xe7>
  for(i=0;; i++){
80104b03:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104b06:	eb b4                	jmp    80104abc <sys_exec+0x5a>
      argv[i] = 0;
80104b08:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104b0f:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104b13:	83 ec 08             	sub    $0x8,%esp
80104b16:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104b1c:	50                   	push   %eax
80104b1d:	ff 75 f4             	pushl  -0xc(%ebp)
80104b20:	e8 ad bd ff ff       	call   801008d2 <exec>
80104b25:	83 c4 10             	add    $0x10,%esp
80104b28:	eb 1a                	jmp    80104b44 <sys_exec+0xe2>
    return -1;
80104b2a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b2f:	eb 13                	jmp    80104b44 <sys_exec+0xe2>
80104b31:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b36:	eb 0c                	jmp    80104b44 <sys_exec+0xe2>
      return -1;
80104b38:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b3d:	eb 05                	jmp    80104b44 <sys_exec+0xe2>
      return -1;
80104b3f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104b44:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104b47:	c9                   	leave  
80104b48:	c3                   	ret    
      return -1;
80104b49:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b4e:	eb f4                	jmp    80104b44 <sys_exec+0xe2>

80104b50 <sys_pipe>:

int
sys_pipe(void)
{
80104b50:	55                   	push   %ebp
80104b51:	89 e5                	mov    %esp,%ebp
80104b53:	53                   	push   %ebx
80104b54:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104b57:	6a 08                	push   $0x8
80104b59:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b5c:	50                   	push   %eax
80104b5d:	6a 00                	push   $0x0
80104b5f:	e8 e3 f3 ff ff       	call   80103f47 <argptr>
80104b64:	83 c4 10             	add    $0x10,%esp
80104b67:	85 c0                	test   %eax,%eax
80104b69:	78 77                	js     80104be2 <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104b6b:	83 ec 08             	sub    $0x8,%esp
80104b6e:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104b71:	50                   	push   %eax
80104b72:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104b75:	50                   	push   %eax
80104b76:	e8 4d e2 ff ff       	call   80102dc8 <pipealloc>
80104b7b:	83 c4 10             	add    $0x10,%esp
80104b7e:	85 c0                	test   %eax,%eax
80104b80:	78 67                	js     80104be9 <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104b82:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b85:	e8 14 f5 ff ff       	call   8010409e <fdalloc>
80104b8a:	89 c3                	mov    %eax,%ebx
80104b8c:	85 c0                	test   %eax,%eax
80104b8e:	78 21                	js     80104bb1 <sys_pipe+0x61>
80104b90:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104b93:	e8 06 f5 ff ff       	call   8010409e <fdalloc>
80104b98:	85 c0                	test   %eax,%eax
80104b9a:	78 15                	js     80104bb1 <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104b9c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b9f:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104ba1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ba4:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104ba7:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104bac:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104baf:	c9                   	leave  
80104bb0:	c3                   	ret    
    if(fd0 >= 0)
80104bb1:	85 db                	test   %ebx,%ebx
80104bb3:	78 0d                	js     80104bc2 <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104bb5:	e8 cf e6 ff ff       	call   80103289 <myproc>
80104bba:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104bc1:	00 
    fileclose(rf);
80104bc2:	83 ec 0c             	sub    $0xc,%esp
80104bc5:	ff 75 f0             	pushl  -0x10(%ebp)
80104bc8:	e8 06 c1 ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104bcd:	83 c4 04             	add    $0x4,%esp
80104bd0:	ff 75 ec             	pushl  -0x14(%ebp)
80104bd3:	e8 fb c0 ff ff       	call   80100cd3 <fileclose>
    return -1;
80104bd8:	83 c4 10             	add    $0x10,%esp
80104bdb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104be0:	eb ca                	jmp    80104bac <sys_pipe+0x5c>
    return -1;
80104be2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104be7:	eb c3                	jmp    80104bac <sys_pipe+0x5c>
    return -1;
80104be9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bee:	eb bc                	jmp    80104bac <sys_pipe+0x5c>

80104bf0 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104bf0:	55                   	push   %ebp
80104bf1:	89 e5                	mov    %esp,%ebp
80104bf3:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104bf6:	e8 06 e8 ff ff       	call   80103401 <fork>
}
80104bfb:	c9                   	leave  
80104bfc:	c3                   	ret    

80104bfd <sys_exit>:

int
sys_exit(void)
{
80104bfd:	55                   	push   %ebp
80104bfe:	89 e5                	mov    %esp,%ebp
80104c00:	83 ec 08             	sub    $0x8,%esp
  exit();
80104c03:	e8 2d ea ff ff       	call   80103635 <exit>
  return 0;  // not reached
}
80104c08:	b8 00 00 00 00       	mov    $0x0,%eax
80104c0d:	c9                   	leave  
80104c0e:	c3                   	ret    

80104c0f <sys_wait>:

int
sys_wait(void)
{
80104c0f:	55                   	push   %ebp
80104c10:	89 e5                	mov    %esp,%ebp
80104c12:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104c15:	e8 a4 eb ff ff       	call   801037be <wait>
}
80104c1a:	c9                   	leave  
80104c1b:	c3                   	ret    

80104c1c <sys_kill>:

int
sys_kill(void)
{
80104c1c:	55                   	push   %ebp
80104c1d:	89 e5                	mov    %esp,%ebp
80104c1f:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104c22:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c25:	50                   	push   %eax
80104c26:	6a 00                	push   $0x0
80104c28:	e8 f2 f2 ff ff       	call   80103f1f <argint>
80104c2d:	83 c4 10             	add    $0x10,%esp
80104c30:	85 c0                	test   %eax,%eax
80104c32:	78 10                	js     80104c44 <sys_kill+0x28>
    return -1;
  return kill(pid);
80104c34:	83 ec 0c             	sub    $0xc,%esp
80104c37:	ff 75 f4             	pushl  -0xc(%ebp)
80104c3a:	e8 7c ec ff ff       	call   801038bb <kill>
80104c3f:	83 c4 10             	add    $0x10,%esp
}
80104c42:	c9                   	leave  
80104c43:	c3                   	ret    
    return -1;
80104c44:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c49:	eb f7                	jmp    80104c42 <sys_kill+0x26>

80104c4b <sys_getpid>:

int
sys_getpid(void)
{
80104c4b:	55                   	push   %ebp
80104c4c:	89 e5                	mov    %esp,%ebp
80104c4e:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104c51:	e8 33 e6 ff ff       	call   80103289 <myproc>
80104c56:	8b 40 10             	mov    0x10(%eax),%eax
}
80104c59:	c9                   	leave  
80104c5a:	c3                   	ret    

80104c5b <sys_sbrk>:

int
sys_sbrk(void)
{
80104c5b:	55                   	push   %ebp
80104c5c:	89 e5                	mov    %esp,%ebp
80104c5e:	53                   	push   %ebx
80104c5f:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104c62:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c65:	50                   	push   %eax
80104c66:	6a 00                	push   $0x0
80104c68:	e8 b2 f2 ff ff       	call   80103f1f <argint>
80104c6d:	83 c4 10             	add    $0x10,%esp
80104c70:	85 c0                	test   %eax,%eax
80104c72:	78 27                	js     80104c9b <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104c74:	e8 10 e6 ff ff       	call   80103289 <myproc>
80104c79:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104c7b:	83 ec 0c             	sub    $0xc,%esp
80104c7e:	ff 75 f4             	pushl  -0xc(%ebp)
80104c81:	e8 0e e7 ff ff       	call   80103394 <growproc>
80104c86:	83 c4 10             	add    $0x10,%esp
80104c89:	85 c0                	test   %eax,%eax
80104c8b:	78 07                	js     80104c94 <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104c8d:	89 d8                	mov    %ebx,%eax
80104c8f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104c92:	c9                   	leave  
80104c93:	c3                   	ret    
    return -1;
80104c94:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104c99:	eb f2                	jmp    80104c8d <sys_sbrk+0x32>
    return -1;
80104c9b:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104ca0:	eb eb                	jmp    80104c8d <sys_sbrk+0x32>

80104ca2 <sys_sleep>:

int
sys_sleep(void)
{
80104ca2:	55                   	push   %ebp
80104ca3:	89 e5                	mov    %esp,%ebp
80104ca5:	53                   	push   %ebx
80104ca6:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104ca9:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104cac:	50                   	push   %eax
80104cad:	6a 00                	push   $0x0
80104caf:	e8 6b f2 ff ff       	call   80103f1f <argint>
80104cb4:	83 c4 10             	add    $0x10,%esp
80104cb7:	85 c0                	test   %eax,%eax
80104cb9:	78 75                	js     80104d30 <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104cbb:	83 ec 0c             	sub    $0xc,%esp
80104cbe:	68 c0 3c 13 80       	push   $0x80133cc0
80104cc3:	e8 60 ef ff ff       	call   80103c28 <acquire>
  ticks0 = ticks;
80104cc8:	8b 1d 00 45 13 80    	mov    0x80134500,%ebx
  while(ticks - ticks0 < n){
80104cce:	83 c4 10             	add    $0x10,%esp
80104cd1:	a1 00 45 13 80       	mov    0x80134500,%eax
80104cd6:	29 d8                	sub    %ebx,%eax
80104cd8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104cdb:	73 39                	jae    80104d16 <sys_sleep+0x74>
    if(myproc()->killed){
80104cdd:	e8 a7 e5 ff ff       	call   80103289 <myproc>
80104ce2:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104ce6:	75 17                	jne    80104cff <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104ce8:	83 ec 08             	sub    $0x8,%esp
80104ceb:	68 c0 3c 13 80       	push   $0x80133cc0
80104cf0:	68 00 45 13 80       	push   $0x80134500
80104cf5:	e8 33 ea ff ff       	call   8010372d <sleep>
80104cfa:	83 c4 10             	add    $0x10,%esp
80104cfd:	eb d2                	jmp    80104cd1 <sys_sleep+0x2f>
      release(&tickslock);
80104cff:	83 ec 0c             	sub    $0xc,%esp
80104d02:	68 c0 3c 13 80       	push   $0x80133cc0
80104d07:	e8 81 ef ff ff       	call   80103c8d <release>
      return -1;
80104d0c:	83 c4 10             	add    $0x10,%esp
80104d0f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d14:	eb 15                	jmp    80104d2b <sys_sleep+0x89>
  }
  release(&tickslock);
80104d16:	83 ec 0c             	sub    $0xc,%esp
80104d19:	68 c0 3c 13 80       	push   $0x80133cc0
80104d1e:	e8 6a ef ff ff       	call   80103c8d <release>
  return 0;
80104d23:	83 c4 10             	add    $0x10,%esp
80104d26:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104d2b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104d2e:	c9                   	leave  
80104d2f:	c3                   	ret    
    return -1;
80104d30:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d35:	eb f4                	jmp    80104d2b <sys_sleep+0x89>

80104d37 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104d37:	55                   	push   %ebp
80104d38:	89 e5                	mov    %esp,%ebp
80104d3a:	53                   	push   %ebx
80104d3b:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104d3e:	68 c0 3c 13 80       	push   $0x80133cc0
80104d43:	e8 e0 ee ff ff       	call   80103c28 <acquire>
  xticks = ticks;
80104d48:	8b 1d 00 45 13 80    	mov    0x80134500,%ebx
  release(&tickslock);
80104d4e:	c7 04 24 c0 3c 13 80 	movl   $0x80133cc0,(%esp)
80104d55:	e8 33 ef ff ff       	call   80103c8d <release>
  return xticks;
}
80104d5a:	89 d8                	mov    %ebx,%eax
80104d5c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104d5f:	c9                   	leave  
80104d60:	c3                   	ret    

80104d61 <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80104d61:	55                   	push   %ebp
80104d62:	89 e5                	mov    %esp,%ebp
80104d64:	83 ec 1c             	sub    $0x1c,%esp
  int *frames;
  int *pids;
  int numframes;
  if(argptr(0, (char**)(&frames), sizeof(*frames)) < 0)
80104d67:	6a 04                	push   $0x4
80104d69:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d6c:	50                   	push   %eax
80104d6d:	6a 00                	push   $0x0
80104d6f:	e8 d3 f1 ff ff       	call   80103f47 <argptr>
80104d74:	83 c4 10             	add    $0x10,%esp
80104d77:	85 c0                	test   %eax,%eax
80104d79:	78 42                	js     80104dbd <sys_dump_physmem+0x5c>
    return -1;
  if(argptr(1, (char**)(&pids), sizeof(*pids)) < 0)
80104d7b:	83 ec 04             	sub    $0x4,%esp
80104d7e:	6a 04                	push   $0x4
80104d80:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104d83:	50                   	push   %eax
80104d84:	6a 01                	push   $0x1
80104d86:	e8 bc f1 ff ff       	call   80103f47 <argptr>
80104d8b:	83 c4 10             	add    $0x10,%esp
80104d8e:	85 c0                	test   %eax,%eax
80104d90:	78 32                	js     80104dc4 <sys_dump_physmem+0x63>
    return -1;
  if(argint(2, &numframes) < 0)
80104d92:	83 ec 08             	sub    $0x8,%esp
80104d95:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104d98:	50                   	push   %eax
80104d99:	6a 02                	push   $0x2
80104d9b:	e8 7f f1 ff ff       	call   80103f1f <argint>
80104da0:	83 c4 10             	add    $0x10,%esp
80104da3:	85 c0                	test   %eax,%eax
80104da5:	78 24                	js     80104dcb <sys_dump_physmem+0x6a>
    return -1;

  return dump_physmem(frames, pids, numframes);
80104da7:	83 ec 04             	sub    $0x4,%esp
80104daa:	ff 75 ec             	pushl  -0x14(%ebp)
80104dad:	ff 75 f0             	pushl  -0x10(%ebp)
80104db0:	ff 75 f4             	pushl  -0xc(%ebp)
80104db3:	e8 8c d3 ff ff       	call   80102144 <dump_physmem>
80104db8:	83 c4 10             	add    $0x10,%esp
80104dbb:	c9                   	leave  
80104dbc:	c3                   	ret    
    return -1;
80104dbd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dc2:	eb f7                	jmp    80104dbb <sys_dump_physmem+0x5a>
    return -1;
80104dc4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dc9:	eb f0                	jmp    80104dbb <sys_dump_physmem+0x5a>
    return -1;
80104dcb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dd0:	eb e9                	jmp    80104dbb <sys_dump_physmem+0x5a>

80104dd2 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104dd2:	1e                   	push   %ds
  pushl %es
80104dd3:	06                   	push   %es
  pushl %fs
80104dd4:	0f a0                	push   %fs
  pushl %gs
80104dd6:	0f a8                	push   %gs
  pushal
80104dd8:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104dd9:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104ddd:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104ddf:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104de1:	54                   	push   %esp
  call trap
80104de2:	e8 e3 00 00 00       	call   80104eca <trap>
  addl $4, %esp
80104de7:	83 c4 04             	add    $0x4,%esp

80104dea <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104dea:	61                   	popa   
  popl %gs
80104deb:	0f a9                	pop    %gs
  popl %fs
80104ded:	0f a1                	pop    %fs
  popl %es
80104def:	07                   	pop    %es
  popl %ds
80104df0:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104df1:	83 c4 08             	add    $0x8,%esp
  iret
80104df4:	cf                   	iret   

80104df5 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80104df5:	55                   	push   %ebp
80104df6:	89 e5                	mov    %esp,%ebp
80104df8:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
80104dfb:	b8 00 00 00 00       	mov    $0x0,%eax
80104e00:	eb 4a                	jmp    80104e4c <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104e02:	8b 0c 85 08 90 10 80 	mov    -0x7fef6ff8(,%eax,4),%ecx
80104e09:	66 89 0c c5 00 3d 13 	mov    %cx,-0x7fecc300(,%eax,8)
80104e10:	80 
80104e11:	66 c7 04 c5 02 3d 13 	movw   $0x8,-0x7fecc2fe(,%eax,8)
80104e18:	80 08 00 
80104e1b:	c6 04 c5 04 3d 13 80 	movb   $0x0,-0x7fecc2fc(,%eax,8)
80104e22:	00 
80104e23:	0f b6 14 c5 05 3d 13 	movzbl -0x7fecc2fb(,%eax,8),%edx
80104e2a:	80 
80104e2b:	83 e2 f0             	and    $0xfffffff0,%edx
80104e2e:	83 ca 0e             	or     $0xe,%edx
80104e31:	83 e2 8f             	and    $0xffffff8f,%edx
80104e34:	83 ca 80             	or     $0xffffff80,%edx
80104e37:	88 14 c5 05 3d 13 80 	mov    %dl,-0x7fecc2fb(,%eax,8)
80104e3e:	c1 e9 10             	shr    $0x10,%ecx
80104e41:	66 89 0c c5 06 3d 13 	mov    %cx,-0x7fecc2fa(,%eax,8)
80104e48:	80 
  for(i = 0; i < 256; i++)
80104e49:	83 c0 01             	add    $0x1,%eax
80104e4c:	3d ff 00 00 00       	cmp    $0xff,%eax
80104e51:	7e af                	jle    80104e02 <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80104e53:	8b 15 08 91 10 80    	mov    0x80109108,%edx
80104e59:	66 89 15 00 3f 13 80 	mov    %dx,0x80133f00
80104e60:	66 c7 05 02 3f 13 80 	movw   $0x8,0x80133f02
80104e67:	08 00 
80104e69:	c6 05 04 3f 13 80 00 	movb   $0x0,0x80133f04
80104e70:	0f b6 05 05 3f 13 80 	movzbl 0x80133f05,%eax
80104e77:	83 c8 0f             	or     $0xf,%eax
80104e7a:	83 e0 ef             	and    $0xffffffef,%eax
80104e7d:	83 c8 e0             	or     $0xffffffe0,%eax
80104e80:	a2 05 3f 13 80       	mov    %al,0x80133f05
80104e85:	c1 ea 10             	shr    $0x10,%edx
80104e88:	66 89 15 06 3f 13 80 	mov    %dx,0x80133f06

  initlock(&tickslock, "time");
80104e8f:	83 ec 08             	sub    $0x8,%esp
80104e92:	68 bd 6c 10 80       	push   $0x80106cbd
80104e97:	68 c0 3c 13 80       	push   $0x80133cc0
80104e9c:	e8 4b ec ff ff       	call   80103aec <initlock>
}
80104ea1:	83 c4 10             	add    $0x10,%esp
80104ea4:	c9                   	leave  
80104ea5:	c3                   	ret    

80104ea6 <idtinit>:

void
idtinit(void)
{
80104ea6:	55                   	push   %ebp
80104ea7:	89 e5                	mov    %esp,%ebp
80104ea9:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80104eac:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80104eb2:	b8 00 3d 13 80       	mov    $0x80133d00,%eax
80104eb7:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80104ebb:	c1 e8 10             	shr    $0x10,%eax
80104ebe:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
80104ec2:	8d 45 fa             	lea    -0x6(%ebp),%eax
80104ec5:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80104ec8:	c9                   	leave  
80104ec9:	c3                   	ret    

80104eca <trap>:

void
trap(struct trapframe *tf)
{
80104eca:	55                   	push   %ebp
80104ecb:	89 e5                	mov    %esp,%ebp
80104ecd:	57                   	push   %edi
80104ece:	56                   	push   %esi
80104ecf:	53                   	push   %ebx
80104ed0:	83 ec 1c             	sub    $0x1c,%esp
80104ed3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80104ed6:	8b 43 30             	mov    0x30(%ebx),%eax
80104ed9:	83 f8 40             	cmp    $0x40,%eax
80104edc:	74 13                	je     80104ef1 <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
80104ede:	83 e8 20             	sub    $0x20,%eax
80104ee1:	83 f8 1f             	cmp    $0x1f,%eax
80104ee4:	0f 87 3a 01 00 00    	ja     80105024 <trap+0x15a>
80104eea:	ff 24 85 64 6d 10 80 	jmp    *-0x7fef929c(,%eax,4)
    if(myproc()->killed)
80104ef1:	e8 93 e3 ff ff       	call   80103289 <myproc>
80104ef6:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104efa:	75 1f                	jne    80104f1b <trap+0x51>
    myproc()->tf = tf;
80104efc:	e8 88 e3 ff ff       	call   80103289 <myproc>
80104f01:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80104f04:	e8 d9 f0 ff ff       	call   80103fe2 <syscall>
    if(myproc()->killed)
80104f09:	e8 7b e3 ff ff       	call   80103289 <myproc>
80104f0e:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f12:	74 7e                	je     80104f92 <trap+0xc8>
      exit();
80104f14:	e8 1c e7 ff ff       	call   80103635 <exit>
80104f19:	eb 77                	jmp    80104f92 <trap+0xc8>
      exit();
80104f1b:	e8 15 e7 ff ff       	call   80103635 <exit>
80104f20:	eb da                	jmp    80104efc <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80104f22:	e8 47 e3 ff ff       	call   8010326e <cpuid>
80104f27:	85 c0                	test   %eax,%eax
80104f29:	74 6f                	je     80104f9a <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
80104f2b:	e8 fc d4 ff ff       	call   8010242c <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80104f30:	e8 54 e3 ff ff       	call   80103289 <myproc>
80104f35:	85 c0                	test   %eax,%eax
80104f37:	74 1c                	je     80104f55 <trap+0x8b>
80104f39:	e8 4b e3 ff ff       	call   80103289 <myproc>
80104f3e:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f42:	74 11                	je     80104f55 <trap+0x8b>
80104f44:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80104f48:	83 e0 03             	and    $0x3,%eax
80104f4b:	66 83 f8 03          	cmp    $0x3,%ax
80104f4f:	0f 84 62 01 00 00    	je     801050b7 <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80104f55:	e8 2f e3 ff ff       	call   80103289 <myproc>
80104f5a:	85 c0                	test   %eax,%eax
80104f5c:	74 0f                	je     80104f6d <trap+0xa3>
80104f5e:	e8 26 e3 ff ff       	call   80103289 <myproc>
80104f63:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80104f67:	0f 84 54 01 00 00    	je     801050c1 <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80104f6d:	e8 17 e3 ff ff       	call   80103289 <myproc>
80104f72:	85 c0                	test   %eax,%eax
80104f74:	74 1c                	je     80104f92 <trap+0xc8>
80104f76:	e8 0e e3 ff ff       	call   80103289 <myproc>
80104f7b:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f7f:	74 11                	je     80104f92 <trap+0xc8>
80104f81:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80104f85:	83 e0 03             	and    $0x3,%eax
80104f88:	66 83 f8 03          	cmp    $0x3,%ax
80104f8c:	0f 84 43 01 00 00    	je     801050d5 <trap+0x20b>
    exit();
}
80104f92:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104f95:	5b                   	pop    %ebx
80104f96:	5e                   	pop    %esi
80104f97:	5f                   	pop    %edi
80104f98:	5d                   	pop    %ebp
80104f99:	c3                   	ret    
      acquire(&tickslock);
80104f9a:	83 ec 0c             	sub    $0xc,%esp
80104f9d:	68 c0 3c 13 80       	push   $0x80133cc0
80104fa2:	e8 81 ec ff ff       	call   80103c28 <acquire>
      ticks++;
80104fa7:	83 05 00 45 13 80 01 	addl   $0x1,0x80134500
      wakeup(&ticks);
80104fae:	c7 04 24 00 45 13 80 	movl   $0x80134500,(%esp)
80104fb5:	e8 d8 e8 ff ff       	call   80103892 <wakeup>
      release(&tickslock);
80104fba:	c7 04 24 c0 3c 13 80 	movl   $0x80133cc0,(%esp)
80104fc1:	e8 c7 ec ff ff       	call   80103c8d <release>
80104fc6:	83 c4 10             	add    $0x10,%esp
80104fc9:	e9 5d ff ff ff       	jmp    80104f2b <trap+0x61>
    ideintr();
80104fce:	e8 a0 cd ff ff       	call   80101d73 <ideintr>
    lapiceoi();
80104fd3:	e8 54 d4 ff ff       	call   8010242c <lapiceoi>
    break;
80104fd8:	e9 53 ff ff ff       	jmp    80104f30 <trap+0x66>
    kbdintr();
80104fdd:	e8 8e d2 ff ff       	call   80102270 <kbdintr>
    lapiceoi();
80104fe2:	e8 45 d4 ff ff       	call   8010242c <lapiceoi>
    break;
80104fe7:	e9 44 ff ff ff       	jmp    80104f30 <trap+0x66>
    uartintr();
80104fec:	e8 05 02 00 00       	call   801051f6 <uartintr>
    lapiceoi();
80104ff1:	e8 36 d4 ff ff       	call   8010242c <lapiceoi>
    break;
80104ff6:	e9 35 ff ff ff       	jmp    80104f30 <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80104ffb:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
80104ffe:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105002:	e8 67 e2 ff ff       	call   8010326e <cpuid>
80105007:	57                   	push   %edi
80105008:	0f b7 f6             	movzwl %si,%esi
8010500b:	56                   	push   %esi
8010500c:	50                   	push   %eax
8010500d:	68 c8 6c 10 80       	push   $0x80106cc8
80105012:	e8 f4 b5 ff ff       	call   8010060b <cprintf>
    lapiceoi();
80105017:	e8 10 d4 ff ff       	call   8010242c <lapiceoi>
    break;
8010501c:	83 c4 10             	add    $0x10,%esp
8010501f:	e9 0c ff ff ff       	jmp    80104f30 <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
80105024:	e8 60 e2 ff ff       	call   80103289 <myproc>
80105029:	85 c0                	test   %eax,%eax
8010502b:	74 5f                	je     8010508c <trap+0x1c2>
8010502d:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
80105031:	74 59                	je     8010508c <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80105033:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105036:	8b 43 38             	mov    0x38(%ebx),%eax
80105039:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010503c:	e8 2d e2 ff ff       	call   8010326e <cpuid>
80105041:	89 45 e0             	mov    %eax,-0x20(%ebp)
80105044:	8b 53 34             	mov    0x34(%ebx),%edx
80105047:	89 55 dc             	mov    %edx,-0x24(%ebp)
8010504a:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
8010504d:	e8 37 e2 ff ff       	call   80103289 <myproc>
80105052:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105055:	89 4d d8             	mov    %ecx,-0x28(%ebp)
80105058:	e8 2c e2 ff ff       	call   80103289 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010505d:	57                   	push   %edi
8010505e:	ff 75 e4             	pushl  -0x1c(%ebp)
80105061:	ff 75 e0             	pushl  -0x20(%ebp)
80105064:	ff 75 dc             	pushl  -0x24(%ebp)
80105067:	56                   	push   %esi
80105068:	ff 75 d8             	pushl  -0x28(%ebp)
8010506b:	ff 70 10             	pushl  0x10(%eax)
8010506e:	68 20 6d 10 80       	push   $0x80106d20
80105073:	e8 93 b5 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
80105078:	83 c4 20             	add    $0x20,%esp
8010507b:	e8 09 e2 ff ff       	call   80103289 <myproc>
80105080:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80105087:	e9 a4 fe ff ff       	jmp    80104f30 <trap+0x66>
8010508c:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010508f:	8b 73 38             	mov    0x38(%ebx),%esi
80105092:	e8 d7 e1 ff ff       	call   8010326e <cpuid>
80105097:	83 ec 0c             	sub    $0xc,%esp
8010509a:	57                   	push   %edi
8010509b:	56                   	push   %esi
8010509c:	50                   	push   %eax
8010509d:	ff 73 30             	pushl  0x30(%ebx)
801050a0:	68 ec 6c 10 80       	push   $0x80106cec
801050a5:	e8 61 b5 ff ff       	call   8010060b <cprintf>
      panic("trap");
801050aa:	83 c4 14             	add    $0x14,%esp
801050ad:	68 c2 6c 10 80       	push   $0x80106cc2
801050b2:	e8 91 b2 ff ff       	call   80100348 <panic>
    exit();
801050b7:	e8 79 e5 ff ff       	call   80103635 <exit>
801050bc:	e9 94 fe ff ff       	jmp    80104f55 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
801050c1:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
801050c5:	0f 85 a2 fe ff ff    	jne    80104f6d <trap+0xa3>
    yield();
801050cb:	e8 2b e6 ff ff       	call   801036fb <yield>
801050d0:	e9 98 fe ff ff       	jmp    80104f6d <trap+0xa3>
    exit();
801050d5:	e8 5b e5 ff ff       	call   80103635 <exit>
801050da:	e9 b3 fe ff ff       	jmp    80104f92 <trap+0xc8>

801050df <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
801050df:	55                   	push   %ebp
801050e0:	89 e5                	mov    %esp,%ebp
  if(!uart)
801050e2:	83 3d c0 95 10 80 00 	cmpl   $0x0,0x801095c0
801050e9:	74 15                	je     80105100 <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801050eb:	ba fd 03 00 00       	mov    $0x3fd,%edx
801050f0:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
801050f1:	a8 01                	test   $0x1,%al
801050f3:	74 12                	je     80105107 <uartgetc+0x28>
801050f5:	ba f8 03 00 00       	mov    $0x3f8,%edx
801050fa:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
801050fb:	0f b6 c0             	movzbl %al,%eax
}
801050fe:	5d                   	pop    %ebp
801050ff:	c3                   	ret    
    return -1;
80105100:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105105:	eb f7                	jmp    801050fe <uartgetc+0x1f>
    return -1;
80105107:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010510c:	eb f0                	jmp    801050fe <uartgetc+0x1f>

8010510e <uartputc>:
  if(!uart)
8010510e:	83 3d c0 95 10 80 00 	cmpl   $0x0,0x801095c0
80105115:	74 3b                	je     80105152 <uartputc+0x44>
{
80105117:	55                   	push   %ebp
80105118:	89 e5                	mov    %esp,%ebp
8010511a:	53                   	push   %ebx
8010511b:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010511e:	bb 00 00 00 00       	mov    $0x0,%ebx
80105123:	eb 10                	jmp    80105135 <uartputc+0x27>
    microdelay(10);
80105125:	83 ec 0c             	sub    $0xc,%esp
80105128:	6a 0a                	push   $0xa
8010512a:	e8 1c d3 ff ff       	call   8010244b <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010512f:	83 c3 01             	add    $0x1,%ebx
80105132:	83 c4 10             	add    $0x10,%esp
80105135:	83 fb 7f             	cmp    $0x7f,%ebx
80105138:	7f 0a                	jg     80105144 <uartputc+0x36>
8010513a:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010513f:	ec                   	in     (%dx),%al
80105140:	a8 20                	test   $0x20,%al
80105142:	74 e1                	je     80105125 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80105144:	8b 45 08             	mov    0x8(%ebp),%eax
80105147:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010514c:	ee                   	out    %al,(%dx)
}
8010514d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105150:	c9                   	leave  
80105151:	c3                   	ret    
80105152:	f3 c3                	repz ret 

80105154 <uartinit>:
{
80105154:	55                   	push   %ebp
80105155:	89 e5                	mov    %esp,%ebp
80105157:	56                   	push   %esi
80105158:	53                   	push   %ebx
80105159:	b9 00 00 00 00       	mov    $0x0,%ecx
8010515e:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105163:	89 c8                	mov    %ecx,%eax
80105165:	ee                   	out    %al,(%dx)
80105166:	be fb 03 00 00       	mov    $0x3fb,%esi
8010516b:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
80105170:	89 f2                	mov    %esi,%edx
80105172:	ee                   	out    %al,(%dx)
80105173:	b8 0c 00 00 00       	mov    $0xc,%eax
80105178:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010517d:	ee                   	out    %al,(%dx)
8010517e:	bb f9 03 00 00       	mov    $0x3f9,%ebx
80105183:	89 c8                	mov    %ecx,%eax
80105185:	89 da                	mov    %ebx,%edx
80105187:	ee                   	out    %al,(%dx)
80105188:	b8 03 00 00 00       	mov    $0x3,%eax
8010518d:	89 f2                	mov    %esi,%edx
8010518f:	ee                   	out    %al,(%dx)
80105190:	ba fc 03 00 00       	mov    $0x3fc,%edx
80105195:	89 c8                	mov    %ecx,%eax
80105197:	ee                   	out    %al,(%dx)
80105198:	b8 01 00 00 00       	mov    $0x1,%eax
8010519d:	89 da                	mov    %ebx,%edx
8010519f:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801051a0:	ba fd 03 00 00       	mov    $0x3fd,%edx
801051a5:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
801051a6:	3c ff                	cmp    $0xff,%al
801051a8:	74 45                	je     801051ef <uartinit+0x9b>
  uart = 1;
801051aa:	c7 05 c0 95 10 80 01 	movl   $0x1,0x801095c0
801051b1:	00 00 00 
801051b4:	ba fa 03 00 00       	mov    $0x3fa,%edx
801051b9:	ec                   	in     (%dx),%al
801051ba:	ba f8 03 00 00       	mov    $0x3f8,%edx
801051bf:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
801051c0:	83 ec 08             	sub    $0x8,%esp
801051c3:	6a 00                	push   $0x0
801051c5:	6a 04                	push   $0x4
801051c7:	e8 b2 cd ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
801051cc:	83 c4 10             	add    $0x10,%esp
801051cf:	bb e4 6d 10 80       	mov    $0x80106de4,%ebx
801051d4:	eb 12                	jmp    801051e8 <uartinit+0x94>
    uartputc(*p);
801051d6:	83 ec 0c             	sub    $0xc,%esp
801051d9:	0f be c0             	movsbl %al,%eax
801051dc:	50                   	push   %eax
801051dd:	e8 2c ff ff ff       	call   8010510e <uartputc>
  for(p="xv6...\n"; *p; p++)
801051e2:	83 c3 01             	add    $0x1,%ebx
801051e5:	83 c4 10             	add    $0x10,%esp
801051e8:	0f b6 03             	movzbl (%ebx),%eax
801051eb:	84 c0                	test   %al,%al
801051ed:	75 e7                	jne    801051d6 <uartinit+0x82>
}
801051ef:	8d 65 f8             	lea    -0x8(%ebp),%esp
801051f2:	5b                   	pop    %ebx
801051f3:	5e                   	pop    %esi
801051f4:	5d                   	pop    %ebp
801051f5:	c3                   	ret    

801051f6 <uartintr>:

void
uartintr(void)
{
801051f6:	55                   	push   %ebp
801051f7:	89 e5                	mov    %esp,%ebp
801051f9:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
801051fc:	68 df 50 10 80       	push   $0x801050df
80105201:	e8 38 b5 ff ff       	call   8010073e <consoleintr>
}
80105206:	83 c4 10             	add    $0x10,%esp
80105209:	c9                   	leave  
8010520a:	c3                   	ret    

8010520b <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
8010520b:	6a 00                	push   $0x0
  pushl $0
8010520d:	6a 00                	push   $0x0
  jmp alltraps
8010520f:	e9 be fb ff ff       	jmp    80104dd2 <alltraps>

80105214 <vector1>:
.globl vector1
vector1:
  pushl $0
80105214:	6a 00                	push   $0x0
  pushl $1
80105216:	6a 01                	push   $0x1
  jmp alltraps
80105218:	e9 b5 fb ff ff       	jmp    80104dd2 <alltraps>

8010521d <vector2>:
.globl vector2
vector2:
  pushl $0
8010521d:	6a 00                	push   $0x0
  pushl $2
8010521f:	6a 02                	push   $0x2
  jmp alltraps
80105221:	e9 ac fb ff ff       	jmp    80104dd2 <alltraps>

80105226 <vector3>:
.globl vector3
vector3:
  pushl $0
80105226:	6a 00                	push   $0x0
  pushl $3
80105228:	6a 03                	push   $0x3
  jmp alltraps
8010522a:	e9 a3 fb ff ff       	jmp    80104dd2 <alltraps>

8010522f <vector4>:
.globl vector4
vector4:
  pushl $0
8010522f:	6a 00                	push   $0x0
  pushl $4
80105231:	6a 04                	push   $0x4
  jmp alltraps
80105233:	e9 9a fb ff ff       	jmp    80104dd2 <alltraps>

80105238 <vector5>:
.globl vector5
vector5:
  pushl $0
80105238:	6a 00                	push   $0x0
  pushl $5
8010523a:	6a 05                	push   $0x5
  jmp alltraps
8010523c:	e9 91 fb ff ff       	jmp    80104dd2 <alltraps>

80105241 <vector6>:
.globl vector6
vector6:
  pushl $0
80105241:	6a 00                	push   $0x0
  pushl $6
80105243:	6a 06                	push   $0x6
  jmp alltraps
80105245:	e9 88 fb ff ff       	jmp    80104dd2 <alltraps>

8010524a <vector7>:
.globl vector7
vector7:
  pushl $0
8010524a:	6a 00                	push   $0x0
  pushl $7
8010524c:	6a 07                	push   $0x7
  jmp alltraps
8010524e:	e9 7f fb ff ff       	jmp    80104dd2 <alltraps>

80105253 <vector8>:
.globl vector8
vector8:
  pushl $8
80105253:	6a 08                	push   $0x8
  jmp alltraps
80105255:	e9 78 fb ff ff       	jmp    80104dd2 <alltraps>

8010525a <vector9>:
.globl vector9
vector9:
  pushl $0
8010525a:	6a 00                	push   $0x0
  pushl $9
8010525c:	6a 09                	push   $0x9
  jmp alltraps
8010525e:	e9 6f fb ff ff       	jmp    80104dd2 <alltraps>

80105263 <vector10>:
.globl vector10
vector10:
  pushl $10
80105263:	6a 0a                	push   $0xa
  jmp alltraps
80105265:	e9 68 fb ff ff       	jmp    80104dd2 <alltraps>

8010526a <vector11>:
.globl vector11
vector11:
  pushl $11
8010526a:	6a 0b                	push   $0xb
  jmp alltraps
8010526c:	e9 61 fb ff ff       	jmp    80104dd2 <alltraps>

80105271 <vector12>:
.globl vector12
vector12:
  pushl $12
80105271:	6a 0c                	push   $0xc
  jmp alltraps
80105273:	e9 5a fb ff ff       	jmp    80104dd2 <alltraps>

80105278 <vector13>:
.globl vector13
vector13:
  pushl $13
80105278:	6a 0d                	push   $0xd
  jmp alltraps
8010527a:	e9 53 fb ff ff       	jmp    80104dd2 <alltraps>

8010527f <vector14>:
.globl vector14
vector14:
  pushl $14
8010527f:	6a 0e                	push   $0xe
  jmp alltraps
80105281:	e9 4c fb ff ff       	jmp    80104dd2 <alltraps>

80105286 <vector15>:
.globl vector15
vector15:
  pushl $0
80105286:	6a 00                	push   $0x0
  pushl $15
80105288:	6a 0f                	push   $0xf
  jmp alltraps
8010528a:	e9 43 fb ff ff       	jmp    80104dd2 <alltraps>

8010528f <vector16>:
.globl vector16
vector16:
  pushl $0
8010528f:	6a 00                	push   $0x0
  pushl $16
80105291:	6a 10                	push   $0x10
  jmp alltraps
80105293:	e9 3a fb ff ff       	jmp    80104dd2 <alltraps>

80105298 <vector17>:
.globl vector17
vector17:
  pushl $17
80105298:	6a 11                	push   $0x11
  jmp alltraps
8010529a:	e9 33 fb ff ff       	jmp    80104dd2 <alltraps>

8010529f <vector18>:
.globl vector18
vector18:
  pushl $0
8010529f:	6a 00                	push   $0x0
  pushl $18
801052a1:	6a 12                	push   $0x12
  jmp alltraps
801052a3:	e9 2a fb ff ff       	jmp    80104dd2 <alltraps>

801052a8 <vector19>:
.globl vector19
vector19:
  pushl $0
801052a8:	6a 00                	push   $0x0
  pushl $19
801052aa:	6a 13                	push   $0x13
  jmp alltraps
801052ac:	e9 21 fb ff ff       	jmp    80104dd2 <alltraps>

801052b1 <vector20>:
.globl vector20
vector20:
  pushl $0
801052b1:	6a 00                	push   $0x0
  pushl $20
801052b3:	6a 14                	push   $0x14
  jmp alltraps
801052b5:	e9 18 fb ff ff       	jmp    80104dd2 <alltraps>

801052ba <vector21>:
.globl vector21
vector21:
  pushl $0
801052ba:	6a 00                	push   $0x0
  pushl $21
801052bc:	6a 15                	push   $0x15
  jmp alltraps
801052be:	e9 0f fb ff ff       	jmp    80104dd2 <alltraps>

801052c3 <vector22>:
.globl vector22
vector22:
  pushl $0
801052c3:	6a 00                	push   $0x0
  pushl $22
801052c5:	6a 16                	push   $0x16
  jmp alltraps
801052c7:	e9 06 fb ff ff       	jmp    80104dd2 <alltraps>

801052cc <vector23>:
.globl vector23
vector23:
  pushl $0
801052cc:	6a 00                	push   $0x0
  pushl $23
801052ce:	6a 17                	push   $0x17
  jmp alltraps
801052d0:	e9 fd fa ff ff       	jmp    80104dd2 <alltraps>

801052d5 <vector24>:
.globl vector24
vector24:
  pushl $0
801052d5:	6a 00                	push   $0x0
  pushl $24
801052d7:	6a 18                	push   $0x18
  jmp alltraps
801052d9:	e9 f4 fa ff ff       	jmp    80104dd2 <alltraps>

801052de <vector25>:
.globl vector25
vector25:
  pushl $0
801052de:	6a 00                	push   $0x0
  pushl $25
801052e0:	6a 19                	push   $0x19
  jmp alltraps
801052e2:	e9 eb fa ff ff       	jmp    80104dd2 <alltraps>

801052e7 <vector26>:
.globl vector26
vector26:
  pushl $0
801052e7:	6a 00                	push   $0x0
  pushl $26
801052e9:	6a 1a                	push   $0x1a
  jmp alltraps
801052eb:	e9 e2 fa ff ff       	jmp    80104dd2 <alltraps>

801052f0 <vector27>:
.globl vector27
vector27:
  pushl $0
801052f0:	6a 00                	push   $0x0
  pushl $27
801052f2:	6a 1b                	push   $0x1b
  jmp alltraps
801052f4:	e9 d9 fa ff ff       	jmp    80104dd2 <alltraps>

801052f9 <vector28>:
.globl vector28
vector28:
  pushl $0
801052f9:	6a 00                	push   $0x0
  pushl $28
801052fb:	6a 1c                	push   $0x1c
  jmp alltraps
801052fd:	e9 d0 fa ff ff       	jmp    80104dd2 <alltraps>

80105302 <vector29>:
.globl vector29
vector29:
  pushl $0
80105302:	6a 00                	push   $0x0
  pushl $29
80105304:	6a 1d                	push   $0x1d
  jmp alltraps
80105306:	e9 c7 fa ff ff       	jmp    80104dd2 <alltraps>

8010530b <vector30>:
.globl vector30
vector30:
  pushl $0
8010530b:	6a 00                	push   $0x0
  pushl $30
8010530d:	6a 1e                	push   $0x1e
  jmp alltraps
8010530f:	e9 be fa ff ff       	jmp    80104dd2 <alltraps>

80105314 <vector31>:
.globl vector31
vector31:
  pushl $0
80105314:	6a 00                	push   $0x0
  pushl $31
80105316:	6a 1f                	push   $0x1f
  jmp alltraps
80105318:	e9 b5 fa ff ff       	jmp    80104dd2 <alltraps>

8010531d <vector32>:
.globl vector32
vector32:
  pushl $0
8010531d:	6a 00                	push   $0x0
  pushl $32
8010531f:	6a 20                	push   $0x20
  jmp alltraps
80105321:	e9 ac fa ff ff       	jmp    80104dd2 <alltraps>

80105326 <vector33>:
.globl vector33
vector33:
  pushl $0
80105326:	6a 00                	push   $0x0
  pushl $33
80105328:	6a 21                	push   $0x21
  jmp alltraps
8010532a:	e9 a3 fa ff ff       	jmp    80104dd2 <alltraps>

8010532f <vector34>:
.globl vector34
vector34:
  pushl $0
8010532f:	6a 00                	push   $0x0
  pushl $34
80105331:	6a 22                	push   $0x22
  jmp alltraps
80105333:	e9 9a fa ff ff       	jmp    80104dd2 <alltraps>

80105338 <vector35>:
.globl vector35
vector35:
  pushl $0
80105338:	6a 00                	push   $0x0
  pushl $35
8010533a:	6a 23                	push   $0x23
  jmp alltraps
8010533c:	e9 91 fa ff ff       	jmp    80104dd2 <alltraps>

80105341 <vector36>:
.globl vector36
vector36:
  pushl $0
80105341:	6a 00                	push   $0x0
  pushl $36
80105343:	6a 24                	push   $0x24
  jmp alltraps
80105345:	e9 88 fa ff ff       	jmp    80104dd2 <alltraps>

8010534a <vector37>:
.globl vector37
vector37:
  pushl $0
8010534a:	6a 00                	push   $0x0
  pushl $37
8010534c:	6a 25                	push   $0x25
  jmp alltraps
8010534e:	e9 7f fa ff ff       	jmp    80104dd2 <alltraps>

80105353 <vector38>:
.globl vector38
vector38:
  pushl $0
80105353:	6a 00                	push   $0x0
  pushl $38
80105355:	6a 26                	push   $0x26
  jmp alltraps
80105357:	e9 76 fa ff ff       	jmp    80104dd2 <alltraps>

8010535c <vector39>:
.globl vector39
vector39:
  pushl $0
8010535c:	6a 00                	push   $0x0
  pushl $39
8010535e:	6a 27                	push   $0x27
  jmp alltraps
80105360:	e9 6d fa ff ff       	jmp    80104dd2 <alltraps>

80105365 <vector40>:
.globl vector40
vector40:
  pushl $0
80105365:	6a 00                	push   $0x0
  pushl $40
80105367:	6a 28                	push   $0x28
  jmp alltraps
80105369:	e9 64 fa ff ff       	jmp    80104dd2 <alltraps>

8010536e <vector41>:
.globl vector41
vector41:
  pushl $0
8010536e:	6a 00                	push   $0x0
  pushl $41
80105370:	6a 29                	push   $0x29
  jmp alltraps
80105372:	e9 5b fa ff ff       	jmp    80104dd2 <alltraps>

80105377 <vector42>:
.globl vector42
vector42:
  pushl $0
80105377:	6a 00                	push   $0x0
  pushl $42
80105379:	6a 2a                	push   $0x2a
  jmp alltraps
8010537b:	e9 52 fa ff ff       	jmp    80104dd2 <alltraps>

80105380 <vector43>:
.globl vector43
vector43:
  pushl $0
80105380:	6a 00                	push   $0x0
  pushl $43
80105382:	6a 2b                	push   $0x2b
  jmp alltraps
80105384:	e9 49 fa ff ff       	jmp    80104dd2 <alltraps>

80105389 <vector44>:
.globl vector44
vector44:
  pushl $0
80105389:	6a 00                	push   $0x0
  pushl $44
8010538b:	6a 2c                	push   $0x2c
  jmp alltraps
8010538d:	e9 40 fa ff ff       	jmp    80104dd2 <alltraps>

80105392 <vector45>:
.globl vector45
vector45:
  pushl $0
80105392:	6a 00                	push   $0x0
  pushl $45
80105394:	6a 2d                	push   $0x2d
  jmp alltraps
80105396:	e9 37 fa ff ff       	jmp    80104dd2 <alltraps>

8010539b <vector46>:
.globl vector46
vector46:
  pushl $0
8010539b:	6a 00                	push   $0x0
  pushl $46
8010539d:	6a 2e                	push   $0x2e
  jmp alltraps
8010539f:	e9 2e fa ff ff       	jmp    80104dd2 <alltraps>

801053a4 <vector47>:
.globl vector47
vector47:
  pushl $0
801053a4:	6a 00                	push   $0x0
  pushl $47
801053a6:	6a 2f                	push   $0x2f
  jmp alltraps
801053a8:	e9 25 fa ff ff       	jmp    80104dd2 <alltraps>

801053ad <vector48>:
.globl vector48
vector48:
  pushl $0
801053ad:	6a 00                	push   $0x0
  pushl $48
801053af:	6a 30                	push   $0x30
  jmp alltraps
801053b1:	e9 1c fa ff ff       	jmp    80104dd2 <alltraps>

801053b6 <vector49>:
.globl vector49
vector49:
  pushl $0
801053b6:	6a 00                	push   $0x0
  pushl $49
801053b8:	6a 31                	push   $0x31
  jmp alltraps
801053ba:	e9 13 fa ff ff       	jmp    80104dd2 <alltraps>

801053bf <vector50>:
.globl vector50
vector50:
  pushl $0
801053bf:	6a 00                	push   $0x0
  pushl $50
801053c1:	6a 32                	push   $0x32
  jmp alltraps
801053c3:	e9 0a fa ff ff       	jmp    80104dd2 <alltraps>

801053c8 <vector51>:
.globl vector51
vector51:
  pushl $0
801053c8:	6a 00                	push   $0x0
  pushl $51
801053ca:	6a 33                	push   $0x33
  jmp alltraps
801053cc:	e9 01 fa ff ff       	jmp    80104dd2 <alltraps>

801053d1 <vector52>:
.globl vector52
vector52:
  pushl $0
801053d1:	6a 00                	push   $0x0
  pushl $52
801053d3:	6a 34                	push   $0x34
  jmp alltraps
801053d5:	e9 f8 f9 ff ff       	jmp    80104dd2 <alltraps>

801053da <vector53>:
.globl vector53
vector53:
  pushl $0
801053da:	6a 00                	push   $0x0
  pushl $53
801053dc:	6a 35                	push   $0x35
  jmp alltraps
801053de:	e9 ef f9 ff ff       	jmp    80104dd2 <alltraps>

801053e3 <vector54>:
.globl vector54
vector54:
  pushl $0
801053e3:	6a 00                	push   $0x0
  pushl $54
801053e5:	6a 36                	push   $0x36
  jmp alltraps
801053e7:	e9 e6 f9 ff ff       	jmp    80104dd2 <alltraps>

801053ec <vector55>:
.globl vector55
vector55:
  pushl $0
801053ec:	6a 00                	push   $0x0
  pushl $55
801053ee:	6a 37                	push   $0x37
  jmp alltraps
801053f0:	e9 dd f9 ff ff       	jmp    80104dd2 <alltraps>

801053f5 <vector56>:
.globl vector56
vector56:
  pushl $0
801053f5:	6a 00                	push   $0x0
  pushl $56
801053f7:	6a 38                	push   $0x38
  jmp alltraps
801053f9:	e9 d4 f9 ff ff       	jmp    80104dd2 <alltraps>

801053fe <vector57>:
.globl vector57
vector57:
  pushl $0
801053fe:	6a 00                	push   $0x0
  pushl $57
80105400:	6a 39                	push   $0x39
  jmp alltraps
80105402:	e9 cb f9 ff ff       	jmp    80104dd2 <alltraps>

80105407 <vector58>:
.globl vector58
vector58:
  pushl $0
80105407:	6a 00                	push   $0x0
  pushl $58
80105409:	6a 3a                	push   $0x3a
  jmp alltraps
8010540b:	e9 c2 f9 ff ff       	jmp    80104dd2 <alltraps>

80105410 <vector59>:
.globl vector59
vector59:
  pushl $0
80105410:	6a 00                	push   $0x0
  pushl $59
80105412:	6a 3b                	push   $0x3b
  jmp alltraps
80105414:	e9 b9 f9 ff ff       	jmp    80104dd2 <alltraps>

80105419 <vector60>:
.globl vector60
vector60:
  pushl $0
80105419:	6a 00                	push   $0x0
  pushl $60
8010541b:	6a 3c                	push   $0x3c
  jmp alltraps
8010541d:	e9 b0 f9 ff ff       	jmp    80104dd2 <alltraps>

80105422 <vector61>:
.globl vector61
vector61:
  pushl $0
80105422:	6a 00                	push   $0x0
  pushl $61
80105424:	6a 3d                	push   $0x3d
  jmp alltraps
80105426:	e9 a7 f9 ff ff       	jmp    80104dd2 <alltraps>

8010542b <vector62>:
.globl vector62
vector62:
  pushl $0
8010542b:	6a 00                	push   $0x0
  pushl $62
8010542d:	6a 3e                	push   $0x3e
  jmp alltraps
8010542f:	e9 9e f9 ff ff       	jmp    80104dd2 <alltraps>

80105434 <vector63>:
.globl vector63
vector63:
  pushl $0
80105434:	6a 00                	push   $0x0
  pushl $63
80105436:	6a 3f                	push   $0x3f
  jmp alltraps
80105438:	e9 95 f9 ff ff       	jmp    80104dd2 <alltraps>

8010543d <vector64>:
.globl vector64
vector64:
  pushl $0
8010543d:	6a 00                	push   $0x0
  pushl $64
8010543f:	6a 40                	push   $0x40
  jmp alltraps
80105441:	e9 8c f9 ff ff       	jmp    80104dd2 <alltraps>

80105446 <vector65>:
.globl vector65
vector65:
  pushl $0
80105446:	6a 00                	push   $0x0
  pushl $65
80105448:	6a 41                	push   $0x41
  jmp alltraps
8010544a:	e9 83 f9 ff ff       	jmp    80104dd2 <alltraps>

8010544f <vector66>:
.globl vector66
vector66:
  pushl $0
8010544f:	6a 00                	push   $0x0
  pushl $66
80105451:	6a 42                	push   $0x42
  jmp alltraps
80105453:	e9 7a f9 ff ff       	jmp    80104dd2 <alltraps>

80105458 <vector67>:
.globl vector67
vector67:
  pushl $0
80105458:	6a 00                	push   $0x0
  pushl $67
8010545a:	6a 43                	push   $0x43
  jmp alltraps
8010545c:	e9 71 f9 ff ff       	jmp    80104dd2 <alltraps>

80105461 <vector68>:
.globl vector68
vector68:
  pushl $0
80105461:	6a 00                	push   $0x0
  pushl $68
80105463:	6a 44                	push   $0x44
  jmp alltraps
80105465:	e9 68 f9 ff ff       	jmp    80104dd2 <alltraps>

8010546a <vector69>:
.globl vector69
vector69:
  pushl $0
8010546a:	6a 00                	push   $0x0
  pushl $69
8010546c:	6a 45                	push   $0x45
  jmp alltraps
8010546e:	e9 5f f9 ff ff       	jmp    80104dd2 <alltraps>

80105473 <vector70>:
.globl vector70
vector70:
  pushl $0
80105473:	6a 00                	push   $0x0
  pushl $70
80105475:	6a 46                	push   $0x46
  jmp alltraps
80105477:	e9 56 f9 ff ff       	jmp    80104dd2 <alltraps>

8010547c <vector71>:
.globl vector71
vector71:
  pushl $0
8010547c:	6a 00                	push   $0x0
  pushl $71
8010547e:	6a 47                	push   $0x47
  jmp alltraps
80105480:	e9 4d f9 ff ff       	jmp    80104dd2 <alltraps>

80105485 <vector72>:
.globl vector72
vector72:
  pushl $0
80105485:	6a 00                	push   $0x0
  pushl $72
80105487:	6a 48                	push   $0x48
  jmp alltraps
80105489:	e9 44 f9 ff ff       	jmp    80104dd2 <alltraps>

8010548e <vector73>:
.globl vector73
vector73:
  pushl $0
8010548e:	6a 00                	push   $0x0
  pushl $73
80105490:	6a 49                	push   $0x49
  jmp alltraps
80105492:	e9 3b f9 ff ff       	jmp    80104dd2 <alltraps>

80105497 <vector74>:
.globl vector74
vector74:
  pushl $0
80105497:	6a 00                	push   $0x0
  pushl $74
80105499:	6a 4a                	push   $0x4a
  jmp alltraps
8010549b:	e9 32 f9 ff ff       	jmp    80104dd2 <alltraps>

801054a0 <vector75>:
.globl vector75
vector75:
  pushl $0
801054a0:	6a 00                	push   $0x0
  pushl $75
801054a2:	6a 4b                	push   $0x4b
  jmp alltraps
801054a4:	e9 29 f9 ff ff       	jmp    80104dd2 <alltraps>

801054a9 <vector76>:
.globl vector76
vector76:
  pushl $0
801054a9:	6a 00                	push   $0x0
  pushl $76
801054ab:	6a 4c                	push   $0x4c
  jmp alltraps
801054ad:	e9 20 f9 ff ff       	jmp    80104dd2 <alltraps>

801054b2 <vector77>:
.globl vector77
vector77:
  pushl $0
801054b2:	6a 00                	push   $0x0
  pushl $77
801054b4:	6a 4d                	push   $0x4d
  jmp alltraps
801054b6:	e9 17 f9 ff ff       	jmp    80104dd2 <alltraps>

801054bb <vector78>:
.globl vector78
vector78:
  pushl $0
801054bb:	6a 00                	push   $0x0
  pushl $78
801054bd:	6a 4e                	push   $0x4e
  jmp alltraps
801054bf:	e9 0e f9 ff ff       	jmp    80104dd2 <alltraps>

801054c4 <vector79>:
.globl vector79
vector79:
  pushl $0
801054c4:	6a 00                	push   $0x0
  pushl $79
801054c6:	6a 4f                	push   $0x4f
  jmp alltraps
801054c8:	e9 05 f9 ff ff       	jmp    80104dd2 <alltraps>

801054cd <vector80>:
.globl vector80
vector80:
  pushl $0
801054cd:	6a 00                	push   $0x0
  pushl $80
801054cf:	6a 50                	push   $0x50
  jmp alltraps
801054d1:	e9 fc f8 ff ff       	jmp    80104dd2 <alltraps>

801054d6 <vector81>:
.globl vector81
vector81:
  pushl $0
801054d6:	6a 00                	push   $0x0
  pushl $81
801054d8:	6a 51                	push   $0x51
  jmp alltraps
801054da:	e9 f3 f8 ff ff       	jmp    80104dd2 <alltraps>

801054df <vector82>:
.globl vector82
vector82:
  pushl $0
801054df:	6a 00                	push   $0x0
  pushl $82
801054e1:	6a 52                	push   $0x52
  jmp alltraps
801054e3:	e9 ea f8 ff ff       	jmp    80104dd2 <alltraps>

801054e8 <vector83>:
.globl vector83
vector83:
  pushl $0
801054e8:	6a 00                	push   $0x0
  pushl $83
801054ea:	6a 53                	push   $0x53
  jmp alltraps
801054ec:	e9 e1 f8 ff ff       	jmp    80104dd2 <alltraps>

801054f1 <vector84>:
.globl vector84
vector84:
  pushl $0
801054f1:	6a 00                	push   $0x0
  pushl $84
801054f3:	6a 54                	push   $0x54
  jmp alltraps
801054f5:	e9 d8 f8 ff ff       	jmp    80104dd2 <alltraps>

801054fa <vector85>:
.globl vector85
vector85:
  pushl $0
801054fa:	6a 00                	push   $0x0
  pushl $85
801054fc:	6a 55                	push   $0x55
  jmp alltraps
801054fe:	e9 cf f8 ff ff       	jmp    80104dd2 <alltraps>

80105503 <vector86>:
.globl vector86
vector86:
  pushl $0
80105503:	6a 00                	push   $0x0
  pushl $86
80105505:	6a 56                	push   $0x56
  jmp alltraps
80105507:	e9 c6 f8 ff ff       	jmp    80104dd2 <alltraps>

8010550c <vector87>:
.globl vector87
vector87:
  pushl $0
8010550c:	6a 00                	push   $0x0
  pushl $87
8010550e:	6a 57                	push   $0x57
  jmp alltraps
80105510:	e9 bd f8 ff ff       	jmp    80104dd2 <alltraps>

80105515 <vector88>:
.globl vector88
vector88:
  pushl $0
80105515:	6a 00                	push   $0x0
  pushl $88
80105517:	6a 58                	push   $0x58
  jmp alltraps
80105519:	e9 b4 f8 ff ff       	jmp    80104dd2 <alltraps>

8010551e <vector89>:
.globl vector89
vector89:
  pushl $0
8010551e:	6a 00                	push   $0x0
  pushl $89
80105520:	6a 59                	push   $0x59
  jmp alltraps
80105522:	e9 ab f8 ff ff       	jmp    80104dd2 <alltraps>

80105527 <vector90>:
.globl vector90
vector90:
  pushl $0
80105527:	6a 00                	push   $0x0
  pushl $90
80105529:	6a 5a                	push   $0x5a
  jmp alltraps
8010552b:	e9 a2 f8 ff ff       	jmp    80104dd2 <alltraps>

80105530 <vector91>:
.globl vector91
vector91:
  pushl $0
80105530:	6a 00                	push   $0x0
  pushl $91
80105532:	6a 5b                	push   $0x5b
  jmp alltraps
80105534:	e9 99 f8 ff ff       	jmp    80104dd2 <alltraps>

80105539 <vector92>:
.globl vector92
vector92:
  pushl $0
80105539:	6a 00                	push   $0x0
  pushl $92
8010553b:	6a 5c                	push   $0x5c
  jmp alltraps
8010553d:	e9 90 f8 ff ff       	jmp    80104dd2 <alltraps>

80105542 <vector93>:
.globl vector93
vector93:
  pushl $0
80105542:	6a 00                	push   $0x0
  pushl $93
80105544:	6a 5d                	push   $0x5d
  jmp alltraps
80105546:	e9 87 f8 ff ff       	jmp    80104dd2 <alltraps>

8010554b <vector94>:
.globl vector94
vector94:
  pushl $0
8010554b:	6a 00                	push   $0x0
  pushl $94
8010554d:	6a 5e                	push   $0x5e
  jmp alltraps
8010554f:	e9 7e f8 ff ff       	jmp    80104dd2 <alltraps>

80105554 <vector95>:
.globl vector95
vector95:
  pushl $0
80105554:	6a 00                	push   $0x0
  pushl $95
80105556:	6a 5f                	push   $0x5f
  jmp alltraps
80105558:	e9 75 f8 ff ff       	jmp    80104dd2 <alltraps>

8010555d <vector96>:
.globl vector96
vector96:
  pushl $0
8010555d:	6a 00                	push   $0x0
  pushl $96
8010555f:	6a 60                	push   $0x60
  jmp alltraps
80105561:	e9 6c f8 ff ff       	jmp    80104dd2 <alltraps>

80105566 <vector97>:
.globl vector97
vector97:
  pushl $0
80105566:	6a 00                	push   $0x0
  pushl $97
80105568:	6a 61                	push   $0x61
  jmp alltraps
8010556a:	e9 63 f8 ff ff       	jmp    80104dd2 <alltraps>

8010556f <vector98>:
.globl vector98
vector98:
  pushl $0
8010556f:	6a 00                	push   $0x0
  pushl $98
80105571:	6a 62                	push   $0x62
  jmp alltraps
80105573:	e9 5a f8 ff ff       	jmp    80104dd2 <alltraps>

80105578 <vector99>:
.globl vector99
vector99:
  pushl $0
80105578:	6a 00                	push   $0x0
  pushl $99
8010557a:	6a 63                	push   $0x63
  jmp alltraps
8010557c:	e9 51 f8 ff ff       	jmp    80104dd2 <alltraps>

80105581 <vector100>:
.globl vector100
vector100:
  pushl $0
80105581:	6a 00                	push   $0x0
  pushl $100
80105583:	6a 64                	push   $0x64
  jmp alltraps
80105585:	e9 48 f8 ff ff       	jmp    80104dd2 <alltraps>

8010558a <vector101>:
.globl vector101
vector101:
  pushl $0
8010558a:	6a 00                	push   $0x0
  pushl $101
8010558c:	6a 65                	push   $0x65
  jmp alltraps
8010558e:	e9 3f f8 ff ff       	jmp    80104dd2 <alltraps>

80105593 <vector102>:
.globl vector102
vector102:
  pushl $0
80105593:	6a 00                	push   $0x0
  pushl $102
80105595:	6a 66                	push   $0x66
  jmp alltraps
80105597:	e9 36 f8 ff ff       	jmp    80104dd2 <alltraps>

8010559c <vector103>:
.globl vector103
vector103:
  pushl $0
8010559c:	6a 00                	push   $0x0
  pushl $103
8010559e:	6a 67                	push   $0x67
  jmp alltraps
801055a0:	e9 2d f8 ff ff       	jmp    80104dd2 <alltraps>

801055a5 <vector104>:
.globl vector104
vector104:
  pushl $0
801055a5:	6a 00                	push   $0x0
  pushl $104
801055a7:	6a 68                	push   $0x68
  jmp alltraps
801055a9:	e9 24 f8 ff ff       	jmp    80104dd2 <alltraps>

801055ae <vector105>:
.globl vector105
vector105:
  pushl $0
801055ae:	6a 00                	push   $0x0
  pushl $105
801055b0:	6a 69                	push   $0x69
  jmp alltraps
801055b2:	e9 1b f8 ff ff       	jmp    80104dd2 <alltraps>

801055b7 <vector106>:
.globl vector106
vector106:
  pushl $0
801055b7:	6a 00                	push   $0x0
  pushl $106
801055b9:	6a 6a                	push   $0x6a
  jmp alltraps
801055bb:	e9 12 f8 ff ff       	jmp    80104dd2 <alltraps>

801055c0 <vector107>:
.globl vector107
vector107:
  pushl $0
801055c0:	6a 00                	push   $0x0
  pushl $107
801055c2:	6a 6b                	push   $0x6b
  jmp alltraps
801055c4:	e9 09 f8 ff ff       	jmp    80104dd2 <alltraps>

801055c9 <vector108>:
.globl vector108
vector108:
  pushl $0
801055c9:	6a 00                	push   $0x0
  pushl $108
801055cb:	6a 6c                	push   $0x6c
  jmp alltraps
801055cd:	e9 00 f8 ff ff       	jmp    80104dd2 <alltraps>

801055d2 <vector109>:
.globl vector109
vector109:
  pushl $0
801055d2:	6a 00                	push   $0x0
  pushl $109
801055d4:	6a 6d                	push   $0x6d
  jmp alltraps
801055d6:	e9 f7 f7 ff ff       	jmp    80104dd2 <alltraps>

801055db <vector110>:
.globl vector110
vector110:
  pushl $0
801055db:	6a 00                	push   $0x0
  pushl $110
801055dd:	6a 6e                	push   $0x6e
  jmp alltraps
801055df:	e9 ee f7 ff ff       	jmp    80104dd2 <alltraps>

801055e4 <vector111>:
.globl vector111
vector111:
  pushl $0
801055e4:	6a 00                	push   $0x0
  pushl $111
801055e6:	6a 6f                	push   $0x6f
  jmp alltraps
801055e8:	e9 e5 f7 ff ff       	jmp    80104dd2 <alltraps>

801055ed <vector112>:
.globl vector112
vector112:
  pushl $0
801055ed:	6a 00                	push   $0x0
  pushl $112
801055ef:	6a 70                	push   $0x70
  jmp alltraps
801055f1:	e9 dc f7 ff ff       	jmp    80104dd2 <alltraps>

801055f6 <vector113>:
.globl vector113
vector113:
  pushl $0
801055f6:	6a 00                	push   $0x0
  pushl $113
801055f8:	6a 71                	push   $0x71
  jmp alltraps
801055fa:	e9 d3 f7 ff ff       	jmp    80104dd2 <alltraps>

801055ff <vector114>:
.globl vector114
vector114:
  pushl $0
801055ff:	6a 00                	push   $0x0
  pushl $114
80105601:	6a 72                	push   $0x72
  jmp alltraps
80105603:	e9 ca f7 ff ff       	jmp    80104dd2 <alltraps>

80105608 <vector115>:
.globl vector115
vector115:
  pushl $0
80105608:	6a 00                	push   $0x0
  pushl $115
8010560a:	6a 73                	push   $0x73
  jmp alltraps
8010560c:	e9 c1 f7 ff ff       	jmp    80104dd2 <alltraps>

80105611 <vector116>:
.globl vector116
vector116:
  pushl $0
80105611:	6a 00                	push   $0x0
  pushl $116
80105613:	6a 74                	push   $0x74
  jmp alltraps
80105615:	e9 b8 f7 ff ff       	jmp    80104dd2 <alltraps>

8010561a <vector117>:
.globl vector117
vector117:
  pushl $0
8010561a:	6a 00                	push   $0x0
  pushl $117
8010561c:	6a 75                	push   $0x75
  jmp alltraps
8010561e:	e9 af f7 ff ff       	jmp    80104dd2 <alltraps>

80105623 <vector118>:
.globl vector118
vector118:
  pushl $0
80105623:	6a 00                	push   $0x0
  pushl $118
80105625:	6a 76                	push   $0x76
  jmp alltraps
80105627:	e9 a6 f7 ff ff       	jmp    80104dd2 <alltraps>

8010562c <vector119>:
.globl vector119
vector119:
  pushl $0
8010562c:	6a 00                	push   $0x0
  pushl $119
8010562e:	6a 77                	push   $0x77
  jmp alltraps
80105630:	e9 9d f7 ff ff       	jmp    80104dd2 <alltraps>

80105635 <vector120>:
.globl vector120
vector120:
  pushl $0
80105635:	6a 00                	push   $0x0
  pushl $120
80105637:	6a 78                	push   $0x78
  jmp alltraps
80105639:	e9 94 f7 ff ff       	jmp    80104dd2 <alltraps>

8010563e <vector121>:
.globl vector121
vector121:
  pushl $0
8010563e:	6a 00                	push   $0x0
  pushl $121
80105640:	6a 79                	push   $0x79
  jmp alltraps
80105642:	e9 8b f7 ff ff       	jmp    80104dd2 <alltraps>

80105647 <vector122>:
.globl vector122
vector122:
  pushl $0
80105647:	6a 00                	push   $0x0
  pushl $122
80105649:	6a 7a                	push   $0x7a
  jmp alltraps
8010564b:	e9 82 f7 ff ff       	jmp    80104dd2 <alltraps>

80105650 <vector123>:
.globl vector123
vector123:
  pushl $0
80105650:	6a 00                	push   $0x0
  pushl $123
80105652:	6a 7b                	push   $0x7b
  jmp alltraps
80105654:	e9 79 f7 ff ff       	jmp    80104dd2 <alltraps>

80105659 <vector124>:
.globl vector124
vector124:
  pushl $0
80105659:	6a 00                	push   $0x0
  pushl $124
8010565b:	6a 7c                	push   $0x7c
  jmp alltraps
8010565d:	e9 70 f7 ff ff       	jmp    80104dd2 <alltraps>

80105662 <vector125>:
.globl vector125
vector125:
  pushl $0
80105662:	6a 00                	push   $0x0
  pushl $125
80105664:	6a 7d                	push   $0x7d
  jmp alltraps
80105666:	e9 67 f7 ff ff       	jmp    80104dd2 <alltraps>

8010566b <vector126>:
.globl vector126
vector126:
  pushl $0
8010566b:	6a 00                	push   $0x0
  pushl $126
8010566d:	6a 7e                	push   $0x7e
  jmp alltraps
8010566f:	e9 5e f7 ff ff       	jmp    80104dd2 <alltraps>

80105674 <vector127>:
.globl vector127
vector127:
  pushl $0
80105674:	6a 00                	push   $0x0
  pushl $127
80105676:	6a 7f                	push   $0x7f
  jmp alltraps
80105678:	e9 55 f7 ff ff       	jmp    80104dd2 <alltraps>

8010567d <vector128>:
.globl vector128
vector128:
  pushl $0
8010567d:	6a 00                	push   $0x0
  pushl $128
8010567f:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80105684:	e9 49 f7 ff ff       	jmp    80104dd2 <alltraps>

80105689 <vector129>:
.globl vector129
vector129:
  pushl $0
80105689:	6a 00                	push   $0x0
  pushl $129
8010568b:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80105690:	e9 3d f7 ff ff       	jmp    80104dd2 <alltraps>

80105695 <vector130>:
.globl vector130
vector130:
  pushl $0
80105695:	6a 00                	push   $0x0
  pushl $130
80105697:	68 82 00 00 00       	push   $0x82
  jmp alltraps
8010569c:	e9 31 f7 ff ff       	jmp    80104dd2 <alltraps>

801056a1 <vector131>:
.globl vector131
vector131:
  pushl $0
801056a1:	6a 00                	push   $0x0
  pushl $131
801056a3:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801056a8:	e9 25 f7 ff ff       	jmp    80104dd2 <alltraps>

801056ad <vector132>:
.globl vector132
vector132:
  pushl $0
801056ad:	6a 00                	push   $0x0
  pushl $132
801056af:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801056b4:	e9 19 f7 ff ff       	jmp    80104dd2 <alltraps>

801056b9 <vector133>:
.globl vector133
vector133:
  pushl $0
801056b9:	6a 00                	push   $0x0
  pushl $133
801056bb:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801056c0:	e9 0d f7 ff ff       	jmp    80104dd2 <alltraps>

801056c5 <vector134>:
.globl vector134
vector134:
  pushl $0
801056c5:	6a 00                	push   $0x0
  pushl $134
801056c7:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801056cc:	e9 01 f7 ff ff       	jmp    80104dd2 <alltraps>

801056d1 <vector135>:
.globl vector135
vector135:
  pushl $0
801056d1:	6a 00                	push   $0x0
  pushl $135
801056d3:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801056d8:	e9 f5 f6 ff ff       	jmp    80104dd2 <alltraps>

801056dd <vector136>:
.globl vector136
vector136:
  pushl $0
801056dd:	6a 00                	push   $0x0
  pushl $136
801056df:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801056e4:	e9 e9 f6 ff ff       	jmp    80104dd2 <alltraps>

801056e9 <vector137>:
.globl vector137
vector137:
  pushl $0
801056e9:	6a 00                	push   $0x0
  pushl $137
801056eb:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801056f0:	e9 dd f6 ff ff       	jmp    80104dd2 <alltraps>

801056f5 <vector138>:
.globl vector138
vector138:
  pushl $0
801056f5:	6a 00                	push   $0x0
  pushl $138
801056f7:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801056fc:	e9 d1 f6 ff ff       	jmp    80104dd2 <alltraps>

80105701 <vector139>:
.globl vector139
vector139:
  pushl $0
80105701:	6a 00                	push   $0x0
  pushl $139
80105703:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80105708:	e9 c5 f6 ff ff       	jmp    80104dd2 <alltraps>

8010570d <vector140>:
.globl vector140
vector140:
  pushl $0
8010570d:	6a 00                	push   $0x0
  pushl $140
8010570f:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80105714:	e9 b9 f6 ff ff       	jmp    80104dd2 <alltraps>

80105719 <vector141>:
.globl vector141
vector141:
  pushl $0
80105719:	6a 00                	push   $0x0
  pushl $141
8010571b:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80105720:	e9 ad f6 ff ff       	jmp    80104dd2 <alltraps>

80105725 <vector142>:
.globl vector142
vector142:
  pushl $0
80105725:	6a 00                	push   $0x0
  pushl $142
80105727:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
8010572c:	e9 a1 f6 ff ff       	jmp    80104dd2 <alltraps>

80105731 <vector143>:
.globl vector143
vector143:
  pushl $0
80105731:	6a 00                	push   $0x0
  pushl $143
80105733:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80105738:	e9 95 f6 ff ff       	jmp    80104dd2 <alltraps>

8010573d <vector144>:
.globl vector144
vector144:
  pushl $0
8010573d:	6a 00                	push   $0x0
  pushl $144
8010573f:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80105744:	e9 89 f6 ff ff       	jmp    80104dd2 <alltraps>

80105749 <vector145>:
.globl vector145
vector145:
  pushl $0
80105749:	6a 00                	push   $0x0
  pushl $145
8010574b:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80105750:	e9 7d f6 ff ff       	jmp    80104dd2 <alltraps>

80105755 <vector146>:
.globl vector146
vector146:
  pushl $0
80105755:	6a 00                	push   $0x0
  pushl $146
80105757:	68 92 00 00 00       	push   $0x92
  jmp alltraps
8010575c:	e9 71 f6 ff ff       	jmp    80104dd2 <alltraps>

80105761 <vector147>:
.globl vector147
vector147:
  pushl $0
80105761:	6a 00                	push   $0x0
  pushl $147
80105763:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80105768:	e9 65 f6 ff ff       	jmp    80104dd2 <alltraps>

8010576d <vector148>:
.globl vector148
vector148:
  pushl $0
8010576d:	6a 00                	push   $0x0
  pushl $148
8010576f:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80105774:	e9 59 f6 ff ff       	jmp    80104dd2 <alltraps>

80105779 <vector149>:
.globl vector149
vector149:
  pushl $0
80105779:	6a 00                	push   $0x0
  pushl $149
8010577b:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80105780:	e9 4d f6 ff ff       	jmp    80104dd2 <alltraps>

80105785 <vector150>:
.globl vector150
vector150:
  pushl $0
80105785:	6a 00                	push   $0x0
  pushl $150
80105787:	68 96 00 00 00       	push   $0x96
  jmp alltraps
8010578c:	e9 41 f6 ff ff       	jmp    80104dd2 <alltraps>

80105791 <vector151>:
.globl vector151
vector151:
  pushl $0
80105791:	6a 00                	push   $0x0
  pushl $151
80105793:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80105798:	e9 35 f6 ff ff       	jmp    80104dd2 <alltraps>

8010579d <vector152>:
.globl vector152
vector152:
  pushl $0
8010579d:	6a 00                	push   $0x0
  pushl $152
8010579f:	68 98 00 00 00       	push   $0x98
  jmp alltraps
801057a4:	e9 29 f6 ff ff       	jmp    80104dd2 <alltraps>

801057a9 <vector153>:
.globl vector153
vector153:
  pushl $0
801057a9:	6a 00                	push   $0x0
  pushl $153
801057ab:	68 99 00 00 00       	push   $0x99
  jmp alltraps
801057b0:	e9 1d f6 ff ff       	jmp    80104dd2 <alltraps>

801057b5 <vector154>:
.globl vector154
vector154:
  pushl $0
801057b5:	6a 00                	push   $0x0
  pushl $154
801057b7:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
801057bc:	e9 11 f6 ff ff       	jmp    80104dd2 <alltraps>

801057c1 <vector155>:
.globl vector155
vector155:
  pushl $0
801057c1:	6a 00                	push   $0x0
  pushl $155
801057c3:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
801057c8:	e9 05 f6 ff ff       	jmp    80104dd2 <alltraps>

801057cd <vector156>:
.globl vector156
vector156:
  pushl $0
801057cd:	6a 00                	push   $0x0
  pushl $156
801057cf:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
801057d4:	e9 f9 f5 ff ff       	jmp    80104dd2 <alltraps>

801057d9 <vector157>:
.globl vector157
vector157:
  pushl $0
801057d9:	6a 00                	push   $0x0
  pushl $157
801057db:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
801057e0:	e9 ed f5 ff ff       	jmp    80104dd2 <alltraps>

801057e5 <vector158>:
.globl vector158
vector158:
  pushl $0
801057e5:	6a 00                	push   $0x0
  pushl $158
801057e7:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801057ec:	e9 e1 f5 ff ff       	jmp    80104dd2 <alltraps>

801057f1 <vector159>:
.globl vector159
vector159:
  pushl $0
801057f1:	6a 00                	push   $0x0
  pushl $159
801057f3:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801057f8:	e9 d5 f5 ff ff       	jmp    80104dd2 <alltraps>

801057fd <vector160>:
.globl vector160
vector160:
  pushl $0
801057fd:	6a 00                	push   $0x0
  pushl $160
801057ff:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80105804:	e9 c9 f5 ff ff       	jmp    80104dd2 <alltraps>

80105809 <vector161>:
.globl vector161
vector161:
  pushl $0
80105809:	6a 00                	push   $0x0
  pushl $161
8010580b:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80105810:	e9 bd f5 ff ff       	jmp    80104dd2 <alltraps>

80105815 <vector162>:
.globl vector162
vector162:
  pushl $0
80105815:	6a 00                	push   $0x0
  pushl $162
80105817:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
8010581c:	e9 b1 f5 ff ff       	jmp    80104dd2 <alltraps>

80105821 <vector163>:
.globl vector163
vector163:
  pushl $0
80105821:	6a 00                	push   $0x0
  pushl $163
80105823:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105828:	e9 a5 f5 ff ff       	jmp    80104dd2 <alltraps>

8010582d <vector164>:
.globl vector164
vector164:
  pushl $0
8010582d:	6a 00                	push   $0x0
  pushl $164
8010582f:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80105834:	e9 99 f5 ff ff       	jmp    80104dd2 <alltraps>

80105839 <vector165>:
.globl vector165
vector165:
  pushl $0
80105839:	6a 00                	push   $0x0
  pushl $165
8010583b:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80105840:	e9 8d f5 ff ff       	jmp    80104dd2 <alltraps>

80105845 <vector166>:
.globl vector166
vector166:
  pushl $0
80105845:	6a 00                	push   $0x0
  pushl $166
80105847:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
8010584c:	e9 81 f5 ff ff       	jmp    80104dd2 <alltraps>

80105851 <vector167>:
.globl vector167
vector167:
  pushl $0
80105851:	6a 00                	push   $0x0
  pushl $167
80105853:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105858:	e9 75 f5 ff ff       	jmp    80104dd2 <alltraps>

8010585d <vector168>:
.globl vector168
vector168:
  pushl $0
8010585d:	6a 00                	push   $0x0
  pushl $168
8010585f:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105864:	e9 69 f5 ff ff       	jmp    80104dd2 <alltraps>

80105869 <vector169>:
.globl vector169
vector169:
  pushl $0
80105869:	6a 00                	push   $0x0
  pushl $169
8010586b:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80105870:	e9 5d f5 ff ff       	jmp    80104dd2 <alltraps>

80105875 <vector170>:
.globl vector170
vector170:
  pushl $0
80105875:	6a 00                	push   $0x0
  pushl $170
80105877:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
8010587c:	e9 51 f5 ff ff       	jmp    80104dd2 <alltraps>

80105881 <vector171>:
.globl vector171
vector171:
  pushl $0
80105881:	6a 00                	push   $0x0
  pushl $171
80105883:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105888:	e9 45 f5 ff ff       	jmp    80104dd2 <alltraps>

8010588d <vector172>:
.globl vector172
vector172:
  pushl $0
8010588d:	6a 00                	push   $0x0
  pushl $172
8010588f:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105894:	e9 39 f5 ff ff       	jmp    80104dd2 <alltraps>

80105899 <vector173>:
.globl vector173
vector173:
  pushl $0
80105899:	6a 00                	push   $0x0
  pushl $173
8010589b:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801058a0:	e9 2d f5 ff ff       	jmp    80104dd2 <alltraps>

801058a5 <vector174>:
.globl vector174
vector174:
  pushl $0
801058a5:	6a 00                	push   $0x0
  pushl $174
801058a7:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
801058ac:	e9 21 f5 ff ff       	jmp    80104dd2 <alltraps>

801058b1 <vector175>:
.globl vector175
vector175:
  pushl $0
801058b1:	6a 00                	push   $0x0
  pushl $175
801058b3:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
801058b8:	e9 15 f5 ff ff       	jmp    80104dd2 <alltraps>

801058bd <vector176>:
.globl vector176
vector176:
  pushl $0
801058bd:	6a 00                	push   $0x0
  pushl $176
801058bf:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
801058c4:	e9 09 f5 ff ff       	jmp    80104dd2 <alltraps>

801058c9 <vector177>:
.globl vector177
vector177:
  pushl $0
801058c9:	6a 00                	push   $0x0
  pushl $177
801058cb:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
801058d0:	e9 fd f4 ff ff       	jmp    80104dd2 <alltraps>

801058d5 <vector178>:
.globl vector178
vector178:
  pushl $0
801058d5:	6a 00                	push   $0x0
  pushl $178
801058d7:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
801058dc:	e9 f1 f4 ff ff       	jmp    80104dd2 <alltraps>

801058e1 <vector179>:
.globl vector179
vector179:
  pushl $0
801058e1:	6a 00                	push   $0x0
  pushl $179
801058e3:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
801058e8:	e9 e5 f4 ff ff       	jmp    80104dd2 <alltraps>

801058ed <vector180>:
.globl vector180
vector180:
  pushl $0
801058ed:	6a 00                	push   $0x0
  pushl $180
801058ef:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801058f4:	e9 d9 f4 ff ff       	jmp    80104dd2 <alltraps>

801058f9 <vector181>:
.globl vector181
vector181:
  pushl $0
801058f9:	6a 00                	push   $0x0
  pushl $181
801058fb:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105900:	e9 cd f4 ff ff       	jmp    80104dd2 <alltraps>

80105905 <vector182>:
.globl vector182
vector182:
  pushl $0
80105905:	6a 00                	push   $0x0
  pushl $182
80105907:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
8010590c:	e9 c1 f4 ff ff       	jmp    80104dd2 <alltraps>

80105911 <vector183>:
.globl vector183
vector183:
  pushl $0
80105911:	6a 00                	push   $0x0
  pushl $183
80105913:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105918:	e9 b5 f4 ff ff       	jmp    80104dd2 <alltraps>

8010591d <vector184>:
.globl vector184
vector184:
  pushl $0
8010591d:	6a 00                	push   $0x0
  pushl $184
8010591f:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105924:	e9 a9 f4 ff ff       	jmp    80104dd2 <alltraps>

80105929 <vector185>:
.globl vector185
vector185:
  pushl $0
80105929:	6a 00                	push   $0x0
  pushl $185
8010592b:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105930:	e9 9d f4 ff ff       	jmp    80104dd2 <alltraps>

80105935 <vector186>:
.globl vector186
vector186:
  pushl $0
80105935:	6a 00                	push   $0x0
  pushl $186
80105937:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
8010593c:	e9 91 f4 ff ff       	jmp    80104dd2 <alltraps>

80105941 <vector187>:
.globl vector187
vector187:
  pushl $0
80105941:	6a 00                	push   $0x0
  pushl $187
80105943:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105948:	e9 85 f4 ff ff       	jmp    80104dd2 <alltraps>

8010594d <vector188>:
.globl vector188
vector188:
  pushl $0
8010594d:	6a 00                	push   $0x0
  pushl $188
8010594f:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105954:	e9 79 f4 ff ff       	jmp    80104dd2 <alltraps>

80105959 <vector189>:
.globl vector189
vector189:
  pushl $0
80105959:	6a 00                	push   $0x0
  pushl $189
8010595b:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105960:	e9 6d f4 ff ff       	jmp    80104dd2 <alltraps>

80105965 <vector190>:
.globl vector190
vector190:
  pushl $0
80105965:	6a 00                	push   $0x0
  pushl $190
80105967:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
8010596c:	e9 61 f4 ff ff       	jmp    80104dd2 <alltraps>

80105971 <vector191>:
.globl vector191
vector191:
  pushl $0
80105971:	6a 00                	push   $0x0
  pushl $191
80105973:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105978:	e9 55 f4 ff ff       	jmp    80104dd2 <alltraps>

8010597d <vector192>:
.globl vector192
vector192:
  pushl $0
8010597d:	6a 00                	push   $0x0
  pushl $192
8010597f:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105984:	e9 49 f4 ff ff       	jmp    80104dd2 <alltraps>

80105989 <vector193>:
.globl vector193
vector193:
  pushl $0
80105989:	6a 00                	push   $0x0
  pushl $193
8010598b:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105990:	e9 3d f4 ff ff       	jmp    80104dd2 <alltraps>

80105995 <vector194>:
.globl vector194
vector194:
  pushl $0
80105995:	6a 00                	push   $0x0
  pushl $194
80105997:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
8010599c:	e9 31 f4 ff ff       	jmp    80104dd2 <alltraps>

801059a1 <vector195>:
.globl vector195
vector195:
  pushl $0
801059a1:	6a 00                	push   $0x0
  pushl $195
801059a3:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
801059a8:	e9 25 f4 ff ff       	jmp    80104dd2 <alltraps>

801059ad <vector196>:
.globl vector196
vector196:
  pushl $0
801059ad:	6a 00                	push   $0x0
  pushl $196
801059af:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
801059b4:	e9 19 f4 ff ff       	jmp    80104dd2 <alltraps>

801059b9 <vector197>:
.globl vector197
vector197:
  pushl $0
801059b9:	6a 00                	push   $0x0
  pushl $197
801059bb:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
801059c0:	e9 0d f4 ff ff       	jmp    80104dd2 <alltraps>

801059c5 <vector198>:
.globl vector198
vector198:
  pushl $0
801059c5:	6a 00                	push   $0x0
  pushl $198
801059c7:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
801059cc:	e9 01 f4 ff ff       	jmp    80104dd2 <alltraps>

801059d1 <vector199>:
.globl vector199
vector199:
  pushl $0
801059d1:	6a 00                	push   $0x0
  pushl $199
801059d3:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
801059d8:	e9 f5 f3 ff ff       	jmp    80104dd2 <alltraps>

801059dd <vector200>:
.globl vector200
vector200:
  pushl $0
801059dd:	6a 00                	push   $0x0
  pushl $200
801059df:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
801059e4:	e9 e9 f3 ff ff       	jmp    80104dd2 <alltraps>

801059e9 <vector201>:
.globl vector201
vector201:
  pushl $0
801059e9:	6a 00                	push   $0x0
  pushl $201
801059eb:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801059f0:	e9 dd f3 ff ff       	jmp    80104dd2 <alltraps>

801059f5 <vector202>:
.globl vector202
vector202:
  pushl $0
801059f5:	6a 00                	push   $0x0
  pushl $202
801059f7:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
801059fc:	e9 d1 f3 ff ff       	jmp    80104dd2 <alltraps>

80105a01 <vector203>:
.globl vector203
vector203:
  pushl $0
80105a01:	6a 00                	push   $0x0
  pushl $203
80105a03:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105a08:	e9 c5 f3 ff ff       	jmp    80104dd2 <alltraps>

80105a0d <vector204>:
.globl vector204
vector204:
  pushl $0
80105a0d:	6a 00                	push   $0x0
  pushl $204
80105a0f:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105a14:	e9 b9 f3 ff ff       	jmp    80104dd2 <alltraps>

80105a19 <vector205>:
.globl vector205
vector205:
  pushl $0
80105a19:	6a 00                	push   $0x0
  pushl $205
80105a1b:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105a20:	e9 ad f3 ff ff       	jmp    80104dd2 <alltraps>

80105a25 <vector206>:
.globl vector206
vector206:
  pushl $0
80105a25:	6a 00                	push   $0x0
  pushl $206
80105a27:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105a2c:	e9 a1 f3 ff ff       	jmp    80104dd2 <alltraps>

80105a31 <vector207>:
.globl vector207
vector207:
  pushl $0
80105a31:	6a 00                	push   $0x0
  pushl $207
80105a33:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105a38:	e9 95 f3 ff ff       	jmp    80104dd2 <alltraps>

80105a3d <vector208>:
.globl vector208
vector208:
  pushl $0
80105a3d:	6a 00                	push   $0x0
  pushl $208
80105a3f:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105a44:	e9 89 f3 ff ff       	jmp    80104dd2 <alltraps>

80105a49 <vector209>:
.globl vector209
vector209:
  pushl $0
80105a49:	6a 00                	push   $0x0
  pushl $209
80105a4b:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105a50:	e9 7d f3 ff ff       	jmp    80104dd2 <alltraps>

80105a55 <vector210>:
.globl vector210
vector210:
  pushl $0
80105a55:	6a 00                	push   $0x0
  pushl $210
80105a57:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105a5c:	e9 71 f3 ff ff       	jmp    80104dd2 <alltraps>

80105a61 <vector211>:
.globl vector211
vector211:
  pushl $0
80105a61:	6a 00                	push   $0x0
  pushl $211
80105a63:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105a68:	e9 65 f3 ff ff       	jmp    80104dd2 <alltraps>

80105a6d <vector212>:
.globl vector212
vector212:
  pushl $0
80105a6d:	6a 00                	push   $0x0
  pushl $212
80105a6f:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105a74:	e9 59 f3 ff ff       	jmp    80104dd2 <alltraps>

80105a79 <vector213>:
.globl vector213
vector213:
  pushl $0
80105a79:	6a 00                	push   $0x0
  pushl $213
80105a7b:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105a80:	e9 4d f3 ff ff       	jmp    80104dd2 <alltraps>

80105a85 <vector214>:
.globl vector214
vector214:
  pushl $0
80105a85:	6a 00                	push   $0x0
  pushl $214
80105a87:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105a8c:	e9 41 f3 ff ff       	jmp    80104dd2 <alltraps>

80105a91 <vector215>:
.globl vector215
vector215:
  pushl $0
80105a91:	6a 00                	push   $0x0
  pushl $215
80105a93:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105a98:	e9 35 f3 ff ff       	jmp    80104dd2 <alltraps>

80105a9d <vector216>:
.globl vector216
vector216:
  pushl $0
80105a9d:	6a 00                	push   $0x0
  pushl $216
80105a9f:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105aa4:	e9 29 f3 ff ff       	jmp    80104dd2 <alltraps>

80105aa9 <vector217>:
.globl vector217
vector217:
  pushl $0
80105aa9:	6a 00                	push   $0x0
  pushl $217
80105aab:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105ab0:	e9 1d f3 ff ff       	jmp    80104dd2 <alltraps>

80105ab5 <vector218>:
.globl vector218
vector218:
  pushl $0
80105ab5:	6a 00                	push   $0x0
  pushl $218
80105ab7:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105abc:	e9 11 f3 ff ff       	jmp    80104dd2 <alltraps>

80105ac1 <vector219>:
.globl vector219
vector219:
  pushl $0
80105ac1:	6a 00                	push   $0x0
  pushl $219
80105ac3:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105ac8:	e9 05 f3 ff ff       	jmp    80104dd2 <alltraps>

80105acd <vector220>:
.globl vector220
vector220:
  pushl $0
80105acd:	6a 00                	push   $0x0
  pushl $220
80105acf:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105ad4:	e9 f9 f2 ff ff       	jmp    80104dd2 <alltraps>

80105ad9 <vector221>:
.globl vector221
vector221:
  pushl $0
80105ad9:	6a 00                	push   $0x0
  pushl $221
80105adb:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105ae0:	e9 ed f2 ff ff       	jmp    80104dd2 <alltraps>

80105ae5 <vector222>:
.globl vector222
vector222:
  pushl $0
80105ae5:	6a 00                	push   $0x0
  pushl $222
80105ae7:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105aec:	e9 e1 f2 ff ff       	jmp    80104dd2 <alltraps>

80105af1 <vector223>:
.globl vector223
vector223:
  pushl $0
80105af1:	6a 00                	push   $0x0
  pushl $223
80105af3:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105af8:	e9 d5 f2 ff ff       	jmp    80104dd2 <alltraps>

80105afd <vector224>:
.globl vector224
vector224:
  pushl $0
80105afd:	6a 00                	push   $0x0
  pushl $224
80105aff:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105b04:	e9 c9 f2 ff ff       	jmp    80104dd2 <alltraps>

80105b09 <vector225>:
.globl vector225
vector225:
  pushl $0
80105b09:	6a 00                	push   $0x0
  pushl $225
80105b0b:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105b10:	e9 bd f2 ff ff       	jmp    80104dd2 <alltraps>

80105b15 <vector226>:
.globl vector226
vector226:
  pushl $0
80105b15:	6a 00                	push   $0x0
  pushl $226
80105b17:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105b1c:	e9 b1 f2 ff ff       	jmp    80104dd2 <alltraps>

80105b21 <vector227>:
.globl vector227
vector227:
  pushl $0
80105b21:	6a 00                	push   $0x0
  pushl $227
80105b23:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105b28:	e9 a5 f2 ff ff       	jmp    80104dd2 <alltraps>

80105b2d <vector228>:
.globl vector228
vector228:
  pushl $0
80105b2d:	6a 00                	push   $0x0
  pushl $228
80105b2f:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105b34:	e9 99 f2 ff ff       	jmp    80104dd2 <alltraps>

80105b39 <vector229>:
.globl vector229
vector229:
  pushl $0
80105b39:	6a 00                	push   $0x0
  pushl $229
80105b3b:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105b40:	e9 8d f2 ff ff       	jmp    80104dd2 <alltraps>

80105b45 <vector230>:
.globl vector230
vector230:
  pushl $0
80105b45:	6a 00                	push   $0x0
  pushl $230
80105b47:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105b4c:	e9 81 f2 ff ff       	jmp    80104dd2 <alltraps>

80105b51 <vector231>:
.globl vector231
vector231:
  pushl $0
80105b51:	6a 00                	push   $0x0
  pushl $231
80105b53:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105b58:	e9 75 f2 ff ff       	jmp    80104dd2 <alltraps>

80105b5d <vector232>:
.globl vector232
vector232:
  pushl $0
80105b5d:	6a 00                	push   $0x0
  pushl $232
80105b5f:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105b64:	e9 69 f2 ff ff       	jmp    80104dd2 <alltraps>

80105b69 <vector233>:
.globl vector233
vector233:
  pushl $0
80105b69:	6a 00                	push   $0x0
  pushl $233
80105b6b:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105b70:	e9 5d f2 ff ff       	jmp    80104dd2 <alltraps>

80105b75 <vector234>:
.globl vector234
vector234:
  pushl $0
80105b75:	6a 00                	push   $0x0
  pushl $234
80105b77:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105b7c:	e9 51 f2 ff ff       	jmp    80104dd2 <alltraps>

80105b81 <vector235>:
.globl vector235
vector235:
  pushl $0
80105b81:	6a 00                	push   $0x0
  pushl $235
80105b83:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105b88:	e9 45 f2 ff ff       	jmp    80104dd2 <alltraps>

80105b8d <vector236>:
.globl vector236
vector236:
  pushl $0
80105b8d:	6a 00                	push   $0x0
  pushl $236
80105b8f:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105b94:	e9 39 f2 ff ff       	jmp    80104dd2 <alltraps>

80105b99 <vector237>:
.globl vector237
vector237:
  pushl $0
80105b99:	6a 00                	push   $0x0
  pushl $237
80105b9b:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105ba0:	e9 2d f2 ff ff       	jmp    80104dd2 <alltraps>

80105ba5 <vector238>:
.globl vector238
vector238:
  pushl $0
80105ba5:	6a 00                	push   $0x0
  pushl $238
80105ba7:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105bac:	e9 21 f2 ff ff       	jmp    80104dd2 <alltraps>

80105bb1 <vector239>:
.globl vector239
vector239:
  pushl $0
80105bb1:	6a 00                	push   $0x0
  pushl $239
80105bb3:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105bb8:	e9 15 f2 ff ff       	jmp    80104dd2 <alltraps>

80105bbd <vector240>:
.globl vector240
vector240:
  pushl $0
80105bbd:	6a 00                	push   $0x0
  pushl $240
80105bbf:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105bc4:	e9 09 f2 ff ff       	jmp    80104dd2 <alltraps>

80105bc9 <vector241>:
.globl vector241
vector241:
  pushl $0
80105bc9:	6a 00                	push   $0x0
  pushl $241
80105bcb:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105bd0:	e9 fd f1 ff ff       	jmp    80104dd2 <alltraps>

80105bd5 <vector242>:
.globl vector242
vector242:
  pushl $0
80105bd5:	6a 00                	push   $0x0
  pushl $242
80105bd7:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105bdc:	e9 f1 f1 ff ff       	jmp    80104dd2 <alltraps>

80105be1 <vector243>:
.globl vector243
vector243:
  pushl $0
80105be1:	6a 00                	push   $0x0
  pushl $243
80105be3:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105be8:	e9 e5 f1 ff ff       	jmp    80104dd2 <alltraps>

80105bed <vector244>:
.globl vector244
vector244:
  pushl $0
80105bed:	6a 00                	push   $0x0
  pushl $244
80105bef:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105bf4:	e9 d9 f1 ff ff       	jmp    80104dd2 <alltraps>

80105bf9 <vector245>:
.globl vector245
vector245:
  pushl $0
80105bf9:	6a 00                	push   $0x0
  pushl $245
80105bfb:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105c00:	e9 cd f1 ff ff       	jmp    80104dd2 <alltraps>

80105c05 <vector246>:
.globl vector246
vector246:
  pushl $0
80105c05:	6a 00                	push   $0x0
  pushl $246
80105c07:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105c0c:	e9 c1 f1 ff ff       	jmp    80104dd2 <alltraps>

80105c11 <vector247>:
.globl vector247
vector247:
  pushl $0
80105c11:	6a 00                	push   $0x0
  pushl $247
80105c13:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105c18:	e9 b5 f1 ff ff       	jmp    80104dd2 <alltraps>

80105c1d <vector248>:
.globl vector248
vector248:
  pushl $0
80105c1d:	6a 00                	push   $0x0
  pushl $248
80105c1f:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105c24:	e9 a9 f1 ff ff       	jmp    80104dd2 <alltraps>

80105c29 <vector249>:
.globl vector249
vector249:
  pushl $0
80105c29:	6a 00                	push   $0x0
  pushl $249
80105c2b:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105c30:	e9 9d f1 ff ff       	jmp    80104dd2 <alltraps>

80105c35 <vector250>:
.globl vector250
vector250:
  pushl $0
80105c35:	6a 00                	push   $0x0
  pushl $250
80105c37:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105c3c:	e9 91 f1 ff ff       	jmp    80104dd2 <alltraps>

80105c41 <vector251>:
.globl vector251
vector251:
  pushl $0
80105c41:	6a 00                	push   $0x0
  pushl $251
80105c43:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105c48:	e9 85 f1 ff ff       	jmp    80104dd2 <alltraps>

80105c4d <vector252>:
.globl vector252
vector252:
  pushl $0
80105c4d:	6a 00                	push   $0x0
  pushl $252
80105c4f:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105c54:	e9 79 f1 ff ff       	jmp    80104dd2 <alltraps>

80105c59 <vector253>:
.globl vector253
vector253:
  pushl $0
80105c59:	6a 00                	push   $0x0
  pushl $253
80105c5b:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105c60:	e9 6d f1 ff ff       	jmp    80104dd2 <alltraps>

80105c65 <vector254>:
.globl vector254
vector254:
  pushl $0
80105c65:	6a 00                	push   $0x0
  pushl $254
80105c67:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105c6c:	e9 61 f1 ff ff       	jmp    80104dd2 <alltraps>

80105c71 <vector255>:
.globl vector255
vector255:
  pushl $0
80105c71:	6a 00                	push   $0x0
  pushl $255
80105c73:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105c78:	e9 55 f1 ff ff       	jmp    80104dd2 <alltraps>

80105c7d <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105c7d:	55                   	push   %ebp
80105c7e:	89 e5                	mov    %esp,%ebp
80105c80:	57                   	push   %edi
80105c81:	56                   	push   %esi
80105c82:	53                   	push   %ebx
80105c83:	83 ec 0c             	sub    $0xc,%esp
80105c86:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105c88:	c1 ea 16             	shr    $0x16,%edx
80105c8b:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105c8e:	8b 1f                	mov    (%edi),%ebx
80105c90:	f6 c3 01             	test   $0x1,%bl
80105c93:	74 22                	je     80105cb7 <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105c95:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105c9b:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105ca1:	c1 ee 0c             	shr    $0xc,%esi
80105ca4:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105caa:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105cad:	89 d8                	mov    %ebx,%eax
80105caf:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105cb2:	5b                   	pop    %ebx
80105cb3:	5e                   	pop    %esi
80105cb4:	5f                   	pop    %edi
80105cb5:	5d                   	pop    %ebp
80105cb6:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80105cb7:	85 c9                	test   %ecx,%ecx
80105cb9:	74 2b                	je     80105ce6 <walkpgdir+0x69>
80105cbb:	e8 fb c3 ff ff       	call   801020bb <kalloc>
80105cc0:	89 c3                	mov    %eax,%ebx
80105cc2:	85 c0                	test   %eax,%eax
80105cc4:	74 e7                	je     80105cad <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105cc6:	83 ec 04             	sub    $0x4,%esp
80105cc9:	68 00 10 00 00       	push   $0x1000
80105cce:	6a 00                	push   $0x0
80105cd0:	50                   	push   %eax
80105cd1:	e8 fe df ff ff       	call   80103cd4 <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105cd6:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105cdc:	83 c8 07             	or     $0x7,%eax
80105cdf:	89 07                	mov    %eax,(%edi)
80105ce1:	83 c4 10             	add    $0x10,%esp
80105ce4:	eb bb                	jmp    80105ca1 <walkpgdir+0x24>
      return 0;
80105ce6:	bb 00 00 00 00       	mov    $0x0,%ebx
80105ceb:	eb c0                	jmp    80105cad <walkpgdir+0x30>

80105ced <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105ced:	55                   	push   %ebp
80105cee:	89 e5                	mov    %esp,%ebp
80105cf0:	57                   	push   %edi
80105cf1:	56                   	push   %esi
80105cf2:	53                   	push   %ebx
80105cf3:	83 ec 1c             	sub    $0x1c,%esp
80105cf6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105cf9:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105cfc:	89 d3                	mov    %edx,%ebx
80105cfe:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105d04:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105d08:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105d0e:	b9 01 00 00 00       	mov    $0x1,%ecx
80105d13:	89 da                	mov    %ebx,%edx
80105d15:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105d18:	e8 60 ff ff ff       	call   80105c7d <walkpgdir>
80105d1d:	85 c0                	test   %eax,%eax
80105d1f:	74 2e                	je     80105d4f <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105d21:	f6 00 01             	testb  $0x1,(%eax)
80105d24:	75 1c                	jne    80105d42 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105d26:	89 f2                	mov    %esi,%edx
80105d28:	0b 55 0c             	or     0xc(%ebp),%edx
80105d2b:	83 ca 01             	or     $0x1,%edx
80105d2e:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105d30:	39 fb                	cmp    %edi,%ebx
80105d32:	74 28                	je     80105d5c <mappages+0x6f>
      break;
    a += PGSIZE;
80105d34:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105d3a:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105d40:	eb cc                	jmp    80105d0e <mappages+0x21>
      panic("remap");
80105d42:	83 ec 0c             	sub    $0xc,%esp
80105d45:	68 ec 6d 10 80       	push   $0x80106dec
80105d4a:	e8 f9 a5 ff ff       	call   80100348 <panic>
      return -1;
80105d4f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105d54:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105d57:	5b                   	pop    %ebx
80105d58:	5e                   	pop    %esi
80105d59:	5f                   	pop    %edi
80105d5a:	5d                   	pop    %ebp
80105d5b:	c3                   	ret    
  return 0;
80105d5c:	b8 00 00 00 00       	mov    $0x0,%eax
80105d61:	eb f1                	jmp    80105d54 <mappages+0x67>

80105d63 <seginit>:
{
80105d63:	55                   	push   %ebp
80105d64:	89 e5                	mov    %esp,%ebp
80105d66:	53                   	push   %ebx
80105d67:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105d6a:	e8 ff d4 ff ff       	call   8010326e <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105d6f:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105d75:	66 c7 80 58 18 13 80 	movw   $0xffff,-0x7fece7a8(%eax)
80105d7c:	ff ff 
80105d7e:	66 c7 80 5a 18 13 80 	movw   $0x0,-0x7fece7a6(%eax)
80105d85:	00 00 
80105d87:	c6 80 5c 18 13 80 00 	movb   $0x0,-0x7fece7a4(%eax)
80105d8e:	0f b6 88 5d 18 13 80 	movzbl -0x7fece7a3(%eax),%ecx
80105d95:	83 e1 f0             	and    $0xfffffff0,%ecx
80105d98:	83 c9 1a             	or     $0x1a,%ecx
80105d9b:	83 e1 9f             	and    $0xffffff9f,%ecx
80105d9e:	83 c9 80             	or     $0xffffff80,%ecx
80105da1:	88 88 5d 18 13 80    	mov    %cl,-0x7fece7a3(%eax)
80105da7:	0f b6 88 5e 18 13 80 	movzbl -0x7fece7a2(%eax),%ecx
80105dae:	83 c9 0f             	or     $0xf,%ecx
80105db1:	83 e1 cf             	and    $0xffffffcf,%ecx
80105db4:	83 c9 c0             	or     $0xffffffc0,%ecx
80105db7:	88 88 5e 18 13 80    	mov    %cl,-0x7fece7a2(%eax)
80105dbd:	c6 80 5f 18 13 80 00 	movb   $0x0,-0x7fece7a1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105dc4:	66 c7 80 60 18 13 80 	movw   $0xffff,-0x7fece7a0(%eax)
80105dcb:	ff ff 
80105dcd:	66 c7 80 62 18 13 80 	movw   $0x0,-0x7fece79e(%eax)
80105dd4:	00 00 
80105dd6:	c6 80 64 18 13 80 00 	movb   $0x0,-0x7fece79c(%eax)
80105ddd:	0f b6 88 65 18 13 80 	movzbl -0x7fece79b(%eax),%ecx
80105de4:	83 e1 f0             	and    $0xfffffff0,%ecx
80105de7:	83 c9 12             	or     $0x12,%ecx
80105dea:	83 e1 9f             	and    $0xffffff9f,%ecx
80105ded:	83 c9 80             	or     $0xffffff80,%ecx
80105df0:	88 88 65 18 13 80    	mov    %cl,-0x7fece79b(%eax)
80105df6:	0f b6 88 66 18 13 80 	movzbl -0x7fece79a(%eax),%ecx
80105dfd:	83 c9 0f             	or     $0xf,%ecx
80105e00:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e03:	83 c9 c0             	or     $0xffffffc0,%ecx
80105e06:	88 88 66 18 13 80    	mov    %cl,-0x7fece79a(%eax)
80105e0c:	c6 80 67 18 13 80 00 	movb   $0x0,-0x7fece799(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80105e13:	66 c7 80 68 18 13 80 	movw   $0xffff,-0x7fece798(%eax)
80105e1a:	ff ff 
80105e1c:	66 c7 80 6a 18 13 80 	movw   $0x0,-0x7fece796(%eax)
80105e23:	00 00 
80105e25:	c6 80 6c 18 13 80 00 	movb   $0x0,-0x7fece794(%eax)
80105e2c:	c6 80 6d 18 13 80 fa 	movb   $0xfa,-0x7fece793(%eax)
80105e33:	0f b6 88 6e 18 13 80 	movzbl -0x7fece792(%eax),%ecx
80105e3a:	83 c9 0f             	or     $0xf,%ecx
80105e3d:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e40:	83 c9 c0             	or     $0xffffffc0,%ecx
80105e43:	88 88 6e 18 13 80    	mov    %cl,-0x7fece792(%eax)
80105e49:	c6 80 6f 18 13 80 00 	movb   $0x0,-0x7fece791(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80105e50:	66 c7 80 70 18 13 80 	movw   $0xffff,-0x7fece790(%eax)
80105e57:	ff ff 
80105e59:	66 c7 80 72 18 13 80 	movw   $0x0,-0x7fece78e(%eax)
80105e60:	00 00 
80105e62:	c6 80 74 18 13 80 00 	movb   $0x0,-0x7fece78c(%eax)
80105e69:	c6 80 75 18 13 80 f2 	movb   $0xf2,-0x7fece78b(%eax)
80105e70:	0f b6 88 76 18 13 80 	movzbl -0x7fece78a(%eax),%ecx
80105e77:	83 c9 0f             	or     $0xf,%ecx
80105e7a:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e7d:	83 c9 c0             	or     $0xffffffc0,%ecx
80105e80:	88 88 76 18 13 80    	mov    %cl,-0x7fece78a(%eax)
80105e86:	c6 80 77 18 13 80 00 	movb   $0x0,-0x7fece789(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80105e8d:	05 50 18 13 80       	add    $0x80131850,%eax
  pd[0] = size-1;
80105e92:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80105e98:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80105e9c:	c1 e8 10             	shr    $0x10,%eax
80105e9f:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80105ea3:	8d 45 f2             	lea    -0xe(%ebp),%eax
80105ea6:	0f 01 10             	lgdtl  (%eax)
}
80105ea9:	83 c4 14             	add    $0x14,%esp
80105eac:	5b                   	pop    %ebx
80105ead:	5d                   	pop    %ebp
80105eae:	c3                   	ret    

80105eaf <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80105eaf:	55                   	push   %ebp
80105eb0:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80105eb2:	a1 04 45 13 80       	mov    0x80134504,%eax
80105eb7:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80105ebc:	0f 22 d8             	mov    %eax,%cr3
}
80105ebf:	5d                   	pop    %ebp
80105ec0:	c3                   	ret    

80105ec1 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80105ec1:	55                   	push   %ebp
80105ec2:	89 e5                	mov    %esp,%ebp
80105ec4:	57                   	push   %edi
80105ec5:	56                   	push   %esi
80105ec6:	53                   	push   %ebx
80105ec7:	83 ec 1c             	sub    $0x1c,%esp
80105eca:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
80105ecd:	85 f6                	test   %esi,%esi
80105ecf:	0f 84 dd 00 00 00    	je     80105fb2 <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
80105ed5:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
80105ed9:	0f 84 e0 00 00 00    	je     80105fbf <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
80105edf:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
80105ee3:	0f 84 e3 00 00 00    	je     80105fcc <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
80105ee9:	e8 5d dc ff ff       	call   80103b4b <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80105eee:	e8 1f d3 ff ff       	call   80103212 <mycpu>
80105ef3:	89 c3                	mov    %eax,%ebx
80105ef5:	e8 18 d3 ff ff       	call   80103212 <mycpu>
80105efa:	8d 78 08             	lea    0x8(%eax),%edi
80105efd:	e8 10 d3 ff ff       	call   80103212 <mycpu>
80105f02:	83 c0 08             	add    $0x8,%eax
80105f05:	c1 e8 10             	shr    $0x10,%eax
80105f08:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105f0b:	e8 02 d3 ff ff       	call   80103212 <mycpu>
80105f10:	83 c0 08             	add    $0x8,%eax
80105f13:	c1 e8 18             	shr    $0x18,%eax
80105f16:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80105f1d:	67 00 
80105f1f:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80105f26:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
80105f2a:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80105f30:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80105f37:	83 e2 f0             	and    $0xfffffff0,%edx
80105f3a:	83 ca 19             	or     $0x19,%edx
80105f3d:	83 e2 9f             	and    $0xffffff9f,%edx
80105f40:	83 ca 80             	or     $0xffffff80,%edx
80105f43:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80105f49:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
80105f50:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80105f56:	e8 b7 d2 ff ff       	call   80103212 <mycpu>
80105f5b:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80105f62:	83 e2 ef             	and    $0xffffffef,%edx
80105f65:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80105f6b:	e8 a2 d2 ff ff       	call   80103212 <mycpu>
80105f70:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80105f76:	8b 5e 08             	mov    0x8(%esi),%ebx
80105f79:	e8 94 d2 ff ff       	call   80103212 <mycpu>
80105f7e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80105f84:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
80105f87:	e8 86 d2 ff ff       	call   80103212 <mycpu>
80105f8c:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
80105f92:	b8 28 00 00 00       	mov    $0x28,%eax
80105f97:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
80105f9a:	8b 46 04             	mov    0x4(%esi),%eax
80105f9d:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
80105fa2:	0f 22 d8             	mov    %eax,%cr3
  popcli();
80105fa5:	e8 de db ff ff       	call   80103b88 <popcli>
}
80105faa:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105fad:	5b                   	pop    %ebx
80105fae:	5e                   	pop    %esi
80105faf:	5f                   	pop    %edi
80105fb0:	5d                   	pop    %ebp
80105fb1:	c3                   	ret    
    panic("switchuvm: no process");
80105fb2:	83 ec 0c             	sub    $0xc,%esp
80105fb5:	68 f2 6d 10 80       	push   $0x80106df2
80105fba:	e8 89 a3 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
80105fbf:	83 ec 0c             	sub    $0xc,%esp
80105fc2:	68 08 6e 10 80       	push   $0x80106e08
80105fc7:	e8 7c a3 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
80105fcc:	83 ec 0c             	sub    $0xc,%esp
80105fcf:	68 1d 6e 10 80       	push   $0x80106e1d
80105fd4:	e8 6f a3 ff ff       	call   80100348 <panic>

80105fd9 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80105fd9:	55                   	push   %ebp
80105fda:	89 e5                	mov    %esp,%ebp
80105fdc:	56                   	push   %esi
80105fdd:	53                   	push   %ebx
80105fde:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
80105fe1:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80105fe7:	77 4c                	ja     80106035 <inituvm+0x5c>
    panic("inituvm: more than a page");
  mem = kalloc();
80105fe9:	e8 cd c0 ff ff       	call   801020bb <kalloc>
80105fee:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
80105ff0:	83 ec 04             	sub    $0x4,%esp
80105ff3:	68 00 10 00 00       	push   $0x1000
80105ff8:	6a 00                	push   $0x0
80105ffa:	50                   	push   %eax
80105ffb:	e8 d4 dc ff ff       	call   80103cd4 <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
80106000:	83 c4 08             	add    $0x8,%esp
80106003:	6a 06                	push   $0x6
80106005:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
8010600b:	50                   	push   %eax
8010600c:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106011:	ba 00 00 00 00       	mov    $0x0,%edx
80106016:	8b 45 08             	mov    0x8(%ebp),%eax
80106019:	e8 cf fc ff ff       	call   80105ced <mappages>
  memmove(mem, init, sz);
8010601e:	83 c4 0c             	add    $0xc,%esp
80106021:	56                   	push   %esi
80106022:	ff 75 0c             	pushl  0xc(%ebp)
80106025:	53                   	push   %ebx
80106026:	e8 24 dd ff ff       	call   80103d4f <memmove>
}
8010602b:	83 c4 10             	add    $0x10,%esp
8010602e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106031:	5b                   	pop    %ebx
80106032:	5e                   	pop    %esi
80106033:	5d                   	pop    %ebp
80106034:	c3                   	ret    
    panic("inituvm: more than a page");
80106035:	83 ec 0c             	sub    $0xc,%esp
80106038:	68 31 6e 10 80       	push   $0x80106e31
8010603d:	e8 06 a3 ff ff       	call   80100348 <panic>

80106042 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80106042:	55                   	push   %ebp
80106043:	89 e5                	mov    %esp,%ebp
80106045:	57                   	push   %edi
80106046:	56                   	push   %esi
80106047:	53                   	push   %ebx
80106048:	83 ec 0c             	sub    $0xc,%esp
8010604b:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
8010604e:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
80106055:	75 07                	jne    8010605e <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80106057:	bb 00 00 00 00       	mov    $0x0,%ebx
8010605c:	eb 3c                	jmp    8010609a <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
8010605e:	83 ec 0c             	sub    $0xc,%esp
80106061:	68 ec 6e 10 80       	push   $0x80106eec
80106066:	e8 dd a2 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
8010606b:	83 ec 0c             	sub    $0xc,%esp
8010606e:	68 4b 6e 10 80       	push   $0x80106e4b
80106073:	e8 d0 a2 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
80106078:	05 00 00 00 80       	add    $0x80000000,%eax
8010607d:	56                   	push   %esi
8010607e:	89 da                	mov    %ebx,%edx
80106080:	03 55 14             	add    0x14(%ebp),%edx
80106083:	52                   	push   %edx
80106084:	50                   	push   %eax
80106085:	ff 75 10             	pushl  0x10(%ebp)
80106088:	e8 e6 b6 ff ff       	call   80101773 <readi>
8010608d:	83 c4 10             	add    $0x10,%esp
80106090:	39 f0                	cmp    %esi,%eax
80106092:	75 47                	jne    801060db <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
80106094:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010609a:	39 fb                	cmp    %edi,%ebx
8010609c:	73 30                	jae    801060ce <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
8010609e:	89 da                	mov    %ebx,%edx
801060a0:	03 55 0c             	add    0xc(%ebp),%edx
801060a3:	b9 00 00 00 00       	mov    $0x0,%ecx
801060a8:	8b 45 08             	mov    0x8(%ebp),%eax
801060ab:	e8 cd fb ff ff       	call   80105c7d <walkpgdir>
801060b0:	85 c0                	test   %eax,%eax
801060b2:	74 b7                	je     8010606b <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
801060b4:	8b 00                	mov    (%eax),%eax
801060b6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
801060bb:	89 fe                	mov    %edi,%esi
801060bd:	29 de                	sub    %ebx,%esi
801060bf:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801060c5:	76 b1                	jbe    80106078 <loaduvm+0x36>
      n = PGSIZE;
801060c7:	be 00 10 00 00       	mov    $0x1000,%esi
801060cc:	eb aa                	jmp    80106078 <loaduvm+0x36>
      return -1;
  }
  return 0;
801060ce:	b8 00 00 00 00       	mov    $0x0,%eax
}
801060d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
801060d6:	5b                   	pop    %ebx
801060d7:	5e                   	pop    %esi
801060d8:	5f                   	pop    %edi
801060d9:	5d                   	pop    %ebp
801060da:	c3                   	ret    
      return -1;
801060db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060e0:	eb f1                	jmp    801060d3 <loaduvm+0x91>

801060e2 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801060e2:	55                   	push   %ebp
801060e3:	89 e5                	mov    %esp,%ebp
801060e5:	57                   	push   %edi
801060e6:	56                   	push   %esi
801060e7:	53                   	push   %ebx
801060e8:	83 ec 0c             	sub    $0xc,%esp
801060eb:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801060ee:	39 7d 10             	cmp    %edi,0x10(%ebp)
801060f1:	73 11                	jae    80106104 <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
801060f3:	8b 45 10             	mov    0x10(%ebp),%eax
801060f6:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801060fc:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106102:	eb 19                	jmp    8010611d <deallocuvm+0x3b>
    return oldsz;
80106104:	89 f8                	mov    %edi,%eax
80106106:	eb 64                	jmp    8010616c <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
80106108:	c1 eb 16             	shr    $0x16,%ebx
8010610b:	83 c3 01             	add    $0x1,%ebx
8010610e:	c1 e3 16             	shl    $0x16,%ebx
80106111:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106117:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010611d:	39 fb                	cmp    %edi,%ebx
8010611f:	73 48                	jae    80106169 <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
80106121:	b9 00 00 00 00       	mov    $0x0,%ecx
80106126:	89 da                	mov    %ebx,%edx
80106128:	8b 45 08             	mov    0x8(%ebp),%eax
8010612b:	e8 4d fb ff ff       	call   80105c7d <walkpgdir>
80106130:	89 c6                	mov    %eax,%esi
    if(!pte)
80106132:	85 c0                	test   %eax,%eax
80106134:	74 d2                	je     80106108 <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
80106136:	8b 00                	mov    (%eax),%eax
80106138:	a8 01                	test   $0x1,%al
8010613a:	74 db                	je     80106117 <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
8010613c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106141:	74 19                	je     8010615c <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
80106143:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106148:	83 ec 0c             	sub    $0xc,%esp
8010614b:	50                   	push   %eax
8010614c:	e8 53 be ff ff       	call   80101fa4 <kfree>
      *pte = 0;
80106151:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80106157:	83 c4 10             	add    $0x10,%esp
8010615a:	eb bb                	jmp    80106117 <deallocuvm+0x35>
        panic("kfree");
8010615c:	83 ec 0c             	sub    $0xc,%esp
8010615f:	68 86 67 10 80       	push   $0x80106786
80106164:	e8 df a1 ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
80106169:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010616c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010616f:	5b                   	pop    %ebx
80106170:	5e                   	pop    %esi
80106171:	5f                   	pop    %edi
80106172:	5d                   	pop    %ebp
80106173:	c3                   	ret    

80106174 <allocuvm>:
{
80106174:	55                   	push   %ebp
80106175:	89 e5                	mov    %esp,%ebp
80106177:	57                   	push   %edi
80106178:	56                   	push   %esi
80106179:	53                   	push   %ebx
8010617a:	83 ec 1c             	sub    $0x1c,%esp
8010617d:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
80106180:	89 7d e4             	mov    %edi,-0x1c(%ebp)
80106183:	85 ff                	test   %edi,%edi
80106185:	0f 88 c1 00 00 00    	js     8010624c <allocuvm+0xd8>
  if(newsz < oldsz)
8010618b:	3b 7d 0c             	cmp    0xc(%ebp),%edi
8010618e:	72 5c                	jb     801061ec <allocuvm+0x78>
  a = PGROUNDUP(oldsz);
80106190:	8b 45 0c             	mov    0xc(%ebp),%eax
80106193:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106199:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
8010619f:	39 fb                	cmp    %edi,%ebx
801061a1:	0f 83 ac 00 00 00    	jae    80106253 <allocuvm+0xdf>
    mem = kalloc();
801061a7:	e8 0f bf ff ff       	call   801020bb <kalloc>
801061ac:	89 c6                	mov    %eax,%esi
    if(mem == 0){
801061ae:	85 c0                	test   %eax,%eax
801061b0:	74 42                	je     801061f4 <allocuvm+0x80>
    memset(mem, 0, PGSIZE);
801061b2:	83 ec 04             	sub    $0x4,%esp
801061b5:	68 00 10 00 00       	push   $0x1000
801061ba:	6a 00                	push   $0x0
801061bc:	50                   	push   %eax
801061bd:	e8 12 db ff ff       	call   80103cd4 <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
801061c2:	83 c4 08             	add    $0x8,%esp
801061c5:	6a 06                	push   $0x6
801061c7:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
801061cd:	50                   	push   %eax
801061ce:	b9 00 10 00 00       	mov    $0x1000,%ecx
801061d3:	89 da                	mov    %ebx,%edx
801061d5:	8b 45 08             	mov    0x8(%ebp),%eax
801061d8:	e8 10 fb ff ff       	call   80105ced <mappages>
801061dd:	83 c4 10             	add    $0x10,%esp
801061e0:	85 c0                	test   %eax,%eax
801061e2:	78 38                	js     8010621c <allocuvm+0xa8>
  for(; a < newsz; a += PGSIZE){
801061e4:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801061ea:	eb b3                	jmp    8010619f <allocuvm+0x2b>
    return oldsz;
801061ec:	8b 45 0c             	mov    0xc(%ebp),%eax
801061ef:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801061f2:	eb 5f                	jmp    80106253 <allocuvm+0xdf>
      cprintf("allocuvm out of memory\n");
801061f4:	83 ec 0c             	sub    $0xc,%esp
801061f7:	68 69 6e 10 80       	push   $0x80106e69
801061fc:	e8 0a a4 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106201:	83 c4 0c             	add    $0xc,%esp
80106204:	ff 75 0c             	pushl  0xc(%ebp)
80106207:	57                   	push   %edi
80106208:	ff 75 08             	pushl  0x8(%ebp)
8010620b:	e8 d2 fe ff ff       	call   801060e2 <deallocuvm>
      return 0;
80106210:	83 c4 10             	add    $0x10,%esp
80106213:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010621a:	eb 37                	jmp    80106253 <allocuvm+0xdf>
      cprintf("allocuvm out of memory (2)\n");
8010621c:	83 ec 0c             	sub    $0xc,%esp
8010621f:	68 81 6e 10 80       	push   $0x80106e81
80106224:	e8 e2 a3 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106229:	83 c4 0c             	add    $0xc,%esp
8010622c:	ff 75 0c             	pushl  0xc(%ebp)
8010622f:	57                   	push   %edi
80106230:	ff 75 08             	pushl  0x8(%ebp)
80106233:	e8 aa fe ff ff       	call   801060e2 <deallocuvm>
      kfree(mem);
80106238:	89 34 24             	mov    %esi,(%esp)
8010623b:	e8 64 bd ff ff       	call   80101fa4 <kfree>
      return 0;
80106240:	83 c4 10             	add    $0x10,%esp
80106243:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010624a:	eb 07                	jmp    80106253 <allocuvm+0xdf>
    return 0;
8010624c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
80106253:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106256:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106259:	5b                   	pop    %ebx
8010625a:	5e                   	pop    %esi
8010625b:	5f                   	pop    %edi
8010625c:	5d                   	pop    %ebp
8010625d:	c3                   	ret    

8010625e <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
8010625e:	55                   	push   %ebp
8010625f:	89 e5                	mov    %esp,%ebp
80106261:	56                   	push   %esi
80106262:	53                   	push   %ebx
80106263:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
80106266:	85 f6                	test   %esi,%esi
80106268:	74 1a                	je     80106284 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
8010626a:	83 ec 04             	sub    $0x4,%esp
8010626d:	6a 00                	push   $0x0
8010626f:	68 00 00 00 80       	push   $0x80000000
80106274:	56                   	push   %esi
80106275:	e8 68 fe ff ff       	call   801060e2 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
8010627a:	83 c4 10             	add    $0x10,%esp
8010627d:	bb 00 00 00 00       	mov    $0x0,%ebx
80106282:	eb 10                	jmp    80106294 <freevm+0x36>
    panic("freevm: no pgdir");
80106284:	83 ec 0c             	sub    $0xc,%esp
80106287:	68 9d 6e 10 80       	push   $0x80106e9d
8010628c:	e8 b7 a0 ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
80106291:	83 c3 01             	add    $0x1,%ebx
80106294:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
8010629a:	77 1f                	ja     801062bb <freevm+0x5d>
    if(pgdir[i] & PTE_P){
8010629c:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
8010629f:	a8 01                	test   $0x1,%al
801062a1:	74 ee                	je     80106291 <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
801062a3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801062a8:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801062ad:	83 ec 0c             	sub    $0xc,%esp
801062b0:	50                   	push   %eax
801062b1:	e8 ee bc ff ff       	call   80101fa4 <kfree>
801062b6:	83 c4 10             	add    $0x10,%esp
801062b9:	eb d6                	jmp    80106291 <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
801062bb:	83 ec 0c             	sub    $0xc,%esp
801062be:	56                   	push   %esi
801062bf:	e8 e0 bc ff ff       	call   80101fa4 <kfree>
}
801062c4:	83 c4 10             	add    $0x10,%esp
801062c7:	8d 65 f8             	lea    -0x8(%ebp),%esp
801062ca:	5b                   	pop    %ebx
801062cb:	5e                   	pop    %esi
801062cc:	5d                   	pop    %ebp
801062cd:	c3                   	ret    

801062ce <setupkvm>:
{
801062ce:	55                   	push   %ebp
801062cf:	89 e5                	mov    %esp,%ebp
801062d1:	56                   	push   %esi
801062d2:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc()) == 0)
801062d3:	e8 e3 bd ff ff       	call   801020bb <kalloc>
801062d8:	89 c6                	mov    %eax,%esi
801062da:	85 c0                	test   %eax,%eax
801062dc:	74 55                	je     80106333 <setupkvm+0x65>
  memset(pgdir, 0, PGSIZE);
801062de:	83 ec 04             	sub    $0x4,%esp
801062e1:	68 00 10 00 00       	push   $0x1000
801062e6:	6a 00                	push   $0x0
801062e8:	50                   	push   %eax
801062e9:	e8 e6 d9 ff ff       	call   80103cd4 <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801062ee:	83 c4 10             	add    $0x10,%esp
801062f1:	bb 20 94 10 80       	mov    $0x80109420,%ebx
801062f6:	81 fb 60 94 10 80    	cmp    $0x80109460,%ebx
801062fc:	73 35                	jae    80106333 <setupkvm+0x65>
                (uint)k->phys_start, k->perm) < 0) {
801062fe:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
80106301:	8b 4b 08             	mov    0x8(%ebx),%ecx
80106304:	29 c1                	sub    %eax,%ecx
80106306:	83 ec 08             	sub    $0x8,%esp
80106309:	ff 73 0c             	pushl  0xc(%ebx)
8010630c:	50                   	push   %eax
8010630d:	8b 13                	mov    (%ebx),%edx
8010630f:	89 f0                	mov    %esi,%eax
80106311:	e8 d7 f9 ff ff       	call   80105ced <mappages>
80106316:	83 c4 10             	add    $0x10,%esp
80106319:	85 c0                	test   %eax,%eax
8010631b:	78 05                	js     80106322 <setupkvm+0x54>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010631d:	83 c3 10             	add    $0x10,%ebx
80106320:	eb d4                	jmp    801062f6 <setupkvm+0x28>
      freevm(pgdir);
80106322:	83 ec 0c             	sub    $0xc,%esp
80106325:	56                   	push   %esi
80106326:	e8 33 ff ff ff       	call   8010625e <freevm>
      return 0;
8010632b:	83 c4 10             	add    $0x10,%esp
8010632e:	be 00 00 00 00       	mov    $0x0,%esi
}
80106333:	89 f0                	mov    %esi,%eax
80106335:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106338:	5b                   	pop    %ebx
80106339:	5e                   	pop    %esi
8010633a:	5d                   	pop    %ebp
8010633b:	c3                   	ret    

8010633c <kvmalloc>:
{
8010633c:	55                   	push   %ebp
8010633d:	89 e5                	mov    %esp,%ebp
8010633f:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80106342:	e8 87 ff ff ff       	call   801062ce <setupkvm>
80106347:	a3 04 45 13 80       	mov    %eax,0x80134504
  switchkvm();
8010634c:	e8 5e fb ff ff       	call   80105eaf <switchkvm>
}
80106351:	c9                   	leave  
80106352:	c3                   	ret    

80106353 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80106353:	55                   	push   %ebp
80106354:	89 e5                	mov    %esp,%ebp
80106356:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106359:	b9 00 00 00 00       	mov    $0x0,%ecx
8010635e:	8b 55 0c             	mov    0xc(%ebp),%edx
80106361:	8b 45 08             	mov    0x8(%ebp),%eax
80106364:	e8 14 f9 ff ff       	call   80105c7d <walkpgdir>
  if(pte == 0)
80106369:	85 c0                	test   %eax,%eax
8010636b:	74 05                	je     80106372 <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
8010636d:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
80106370:	c9                   	leave  
80106371:	c3                   	ret    
    panic("clearpteu");
80106372:	83 ec 0c             	sub    $0xc,%esp
80106375:	68 ae 6e 10 80       	push   $0x80106eae
8010637a:	e8 c9 9f ff ff       	call   80100348 <panic>

8010637f <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
8010637f:	55                   	push   %ebp
80106380:	89 e5                	mov    %esp,%ebp
80106382:	57                   	push   %edi
80106383:	56                   	push   %esi
80106384:	53                   	push   %ebx
80106385:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80106388:	e8 41 ff ff ff       	call   801062ce <setupkvm>
8010638d:	89 45 dc             	mov    %eax,-0x24(%ebp)
80106390:	85 c0                	test   %eax,%eax
80106392:	0f 84 c4 00 00 00    	je     8010645c <copyuvm+0xdd>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80106398:	bf 00 00 00 00       	mov    $0x0,%edi
8010639d:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801063a0:	0f 83 b6 00 00 00    	jae    8010645c <copyuvm+0xdd>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801063a6:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801063a9:	b9 00 00 00 00       	mov    $0x0,%ecx
801063ae:	89 fa                	mov    %edi,%edx
801063b0:	8b 45 08             	mov    0x8(%ebp),%eax
801063b3:	e8 c5 f8 ff ff       	call   80105c7d <walkpgdir>
801063b8:	85 c0                	test   %eax,%eax
801063ba:	74 65                	je     80106421 <copyuvm+0xa2>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
801063bc:	8b 00                	mov    (%eax),%eax
801063be:	a8 01                	test   $0x1,%al
801063c0:	74 6c                	je     8010642e <copyuvm+0xaf>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
801063c2:	89 c6                	mov    %eax,%esi
801063c4:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
801063ca:	25 ff 0f 00 00       	and    $0xfff,%eax
801063cf:	89 45 e0             	mov    %eax,-0x20(%ebp)
    if((mem = kalloc()) == 0)
801063d2:	e8 e4 bc ff ff       	call   801020bb <kalloc>
801063d7:	89 c3                	mov    %eax,%ebx
801063d9:	85 c0                	test   %eax,%eax
801063db:	74 6a                	je     80106447 <copyuvm+0xc8>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
801063dd:	81 c6 00 00 00 80    	add    $0x80000000,%esi
801063e3:	83 ec 04             	sub    $0x4,%esp
801063e6:	68 00 10 00 00       	push   $0x1000
801063eb:	56                   	push   %esi
801063ec:	50                   	push   %eax
801063ed:	e8 5d d9 ff ff       	call   80103d4f <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
801063f2:	83 c4 08             	add    $0x8,%esp
801063f5:	ff 75 e0             	pushl  -0x20(%ebp)
801063f8:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801063fe:	50                   	push   %eax
801063ff:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106404:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106407:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010640a:	e8 de f8 ff ff       	call   80105ced <mappages>
8010640f:	83 c4 10             	add    $0x10,%esp
80106412:	85 c0                	test   %eax,%eax
80106414:	78 25                	js     8010643b <copyuvm+0xbc>
  for(i = 0; i < sz; i += PGSIZE){
80106416:	81 c7 00 10 00 00    	add    $0x1000,%edi
8010641c:	e9 7c ff ff ff       	jmp    8010639d <copyuvm+0x1e>
      panic("copyuvm: pte should exist");
80106421:	83 ec 0c             	sub    $0xc,%esp
80106424:	68 b8 6e 10 80       	push   $0x80106eb8
80106429:	e8 1a 9f ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
8010642e:	83 ec 0c             	sub    $0xc,%esp
80106431:	68 d2 6e 10 80       	push   $0x80106ed2
80106436:	e8 0d 9f ff ff       	call   80100348 <panic>
      kfree(mem);
8010643b:	83 ec 0c             	sub    $0xc,%esp
8010643e:	53                   	push   %ebx
8010643f:	e8 60 bb ff ff       	call   80101fa4 <kfree>
      goto bad;
80106444:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
80106447:	83 ec 0c             	sub    $0xc,%esp
8010644a:	ff 75 dc             	pushl  -0x24(%ebp)
8010644d:	e8 0c fe ff ff       	call   8010625e <freevm>
  return 0;
80106452:	83 c4 10             	add    $0x10,%esp
80106455:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
8010645c:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010645f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106462:	5b                   	pop    %ebx
80106463:	5e                   	pop    %esi
80106464:	5f                   	pop    %edi
80106465:	5d                   	pop    %ebp
80106466:	c3                   	ret    

80106467 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80106467:	55                   	push   %ebp
80106468:	89 e5                	mov    %esp,%ebp
8010646a:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010646d:	b9 00 00 00 00       	mov    $0x0,%ecx
80106472:	8b 55 0c             	mov    0xc(%ebp),%edx
80106475:	8b 45 08             	mov    0x8(%ebp),%eax
80106478:	e8 00 f8 ff ff       	call   80105c7d <walkpgdir>
  if((*pte & PTE_P) == 0)
8010647d:	8b 00                	mov    (%eax),%eax
8010647f:	a8 01                	test   $0x1,%al
80106481:	74 10                	je     80106493 <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
80106483:	a8 04                	test   $0x4,%al
80106485:	74 13                	je     8010649a <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
80106487:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010648c:	05 00 00 00 80       	add    $0x80000000,%eax
}
80106491:	c9                   	leave  
80106492:	c3                   	ret    
    return 0;
80106493:	b8 00 00 00 00       	mov    $0x0,%eax
80106498:	eb f7                	jmp    80106491 <uva2ka+0x2a>
    return 0;
8010649a:	b8 00 00 00 00       	mov    $0x0,%eax
8010649f:	eb f0                	jmp    80106491 <uva2ka+0x2a>

801064a1 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801064a1:	55                   	push   %ebp
801064a2:	89 e5                	mov    %esp,%ebp
801064a4:	57                   	push   %edi
801064a5:	56                   	push   %esi
801064a6:	53                   	push   %ebx
801064a7:	83 ec 0c             	sub    $0xc,%esp
801064aa:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801064ad:	eb 25                	jmp    801064d4 <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
801064af:	8b 55 0c             	mov    0xc(%ebp),%edx
801064b2:	29 f2                	sub    %esi,%edx
801064b4:	01 d0                	add    %edx,%eax
801064b6:	83 ec 04             	sub    $0x4,%esp
801064b9:	53                   	push   %ebx
801064ba:	ff 75 10             	pushl  0x10(%ebp)
801064bd:	50                   	push   %eax
801064be:	e8 8c d8 ff ff       	call   80103d4f <memmove>
    len -= n;
801064c3:	29 df                	sub    %ebx,%edi
    buf += n;
801064c5:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
801064c8:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
801064ce:	89 45 0c             	mov    %eax,0xc(%ebp)
801064d1:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
801064d4:	85 ff                	test   %edi,%edi
801064d6:	74 2f                	je     80106507 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
801064d8:	8b 75 0c             	mov    0xc(%ebp),%esi
801064db:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
801064e1:	83 ec 08             	sub    $0x8,%esp
801064e4:	56                   	push   %esi
801064e5:	ff 75 08             	pushl  0x8(%ebp)
801064e8:	e8 7a ff ff ff       	call   80106467 <uva2ka>
    if(pa0 == 0)
801064ed:	83 c4 10             	add    $0x10,%esp
801064f0:	85 c0                	test   %eax,%eax
801064f2:	74 20                	je     80106514 <copyout+0x73>
    n = PGSIZE - (va - va0);
801064f4:	89 f3                	mov    %esi,%ebx
801064f6:	2b 5d 0c             	sub    0xc(%ebp),%ebx
801064f9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
801064ff:	39 df                	cmp    %ebx,%edi
80106501:	73 ac                	jae    801064af <copyout+0xe>
      n = len;
80106503:	89 fb                	mov    %edi,%ebx
80106505:	eb a8                	jmp    801064af <copyout+0xe>
  }
  return 0;
80106507:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010650c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010650f:	5b                   	pop    %ebx
80106510:	5e                   	pop    %esi
80106511:	5f                   	pop    %edi
80106512:	5d                   	pop    %ebp
80106513:	c3                   	ret    
      return -1;
80106514:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106519:	eb f1                	jmp    8010650c <copyout+0x6b>
