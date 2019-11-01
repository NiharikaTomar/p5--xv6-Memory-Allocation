
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
8010002d:	b8 e3 2a 10 80       	mov    $0x80102ae3,%eax
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
80100046:	e8 33 3c 00 00       	call   80103c7e <acquire>

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
8010007c:	e8 62 3c 00 00       	call   80103ce3 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 de 39 00 00       	call   80103a6a <acquiresleep>
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
801000ca:	e8 14 3c 00 00       	call   80103ce3 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 90 39 00 00       	call   80103a6a <acquiresleep>
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
801000ea:	68 a0 65 10 80       	push   $0x801065a0
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 b1 65 10 80       	push   $0x801065b1
80100100:	68 e0 a5 10 80       	push   $0x8010a5e0
80100105:	e8 38 3a 00 00       	call   80103b42 <initlock>
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
8010013a:	68 b8 65 10 80       	push   $0x801065b8
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 ef 38 00 00       	call   80103a37 <initsleeplock>
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
801001a8:	e8 47 39 00 00       	call   80103af4 <holdingsleep>
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
801001cb:	68 bf 65 10 80       	push   $0x801065bf
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
801001e4:	e8 0b 39 00 00       	call   80103af4 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 c0 38 00 00       	call   80103ab9 <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 e0 a5 10 80 	movl   $0x8010a5e0,(%esp)
80100200:	e8 79 3a 00 00       	call   80103c7e <acquire>
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
8010024c:	e8 92 3a 00 00       	call   80103ce3 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 c6 65 10 80       	push   $0x801065c6
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
8010028a:	e8 ef 39 00 00       	call   80103c7e <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 c0 ef 10 80       	mov    0x8010efc0,%eax
8010029f:	3b 05 c4 ef 10 80    	cmp    0x8010efc4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 d1 2f 00 00       	call   8010327d <myproc>
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
801002bf:	e8 5d 34 00 00       	call   80103721 <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 95 10 80       	push   $0x80109520
801002d1:	e8 0d 3a 00 00       	call   80103ce3 <release>
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
80100331:	e8 ad 39 00 00       	call   80103ce3 <release>
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
8010035a:	e8 9e 20 00 00       	call   801023fd <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 cd 65 10 80       	push   $0x801065cd
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 3b 6f 10 80 	movl   $0x80106f3b,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 c9 37 00 00       	call   80103b5d <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 e1 65 10 80       	push   $0x801065e1
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
8010049e:	68 e5 65 10 80       	push   $0x801065e5
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 e6 38 00 00       	call   80103da5 <memmove>
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
801004d9:	e8 4c 38 00 00       	call   80103d2a <memset>
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
80100506:	e8 59 4c 00 00       	call   80105164 <uartputc>
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
8010051f:	e8 40 4c 00 00       	call   80105164 <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 34 4c 00 00       	call   80105164 <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 28 4c 00 00       	call   80105164 <uartputc>
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
80100576:	0f b6 92 10 66 10 80 	movzbl -0x7fef99f0(%edx),%edx
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
801005ca:	e8 af 36 00 00       	call   80103c7e <acquire>
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
801005f1:	e8 ed 36 00 00       	call   80103ce3 <release>
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
80100638:	e8 41 36 00 00       	call   80103c7e <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 ff 65 10 80       	push   $0x801065ff
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
801006ee:	be f8 65 10 80       	mov    $0x801065f8,%esi
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
80100734:	e8 aa 35 00 00       	call   80103ce3 <release>
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
8010074f:	e8 2a 35 00 00       	call   80103c7e <acquire>
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
801007de:	e8 a3 30 00 00       	call   80103886 <wakeup>
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
80100873:	e8 6b 34 00 00       	call   80103ce3 <release>
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
80100887:	e8 97 30 00 00       	call   80103923 <procdump>
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
80100894:	68 08 66 10 80       	push   $0x80106608
80100899:	68 20 95 10 80       	push   $0x80109520
8010089e:	e8 9f 32 00 00       	call   80103b42 <initlock>

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
801008de:	e8 9a 29 00 00       	call   8010327d <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 3f 1f 00 00       	call   8010282d <begin_op>

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
80100935:	e8 6d 1f 00 00       	call   801028a7 <end_op>
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
8010094a:	e8 58 1f 00 00       	call   801028a7 <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 21 66 10 80       	push   $0x80106621
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
80100972:	e8 c8 59 00 00       	call   8010633f <setupkvm>
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
80100a06:	e8 cc 57 00 00       	call   801061d7 <allocuvm>
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
80100a38:	e8 68 56 00 00       	call   801060a5 <loaduvm>
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
80100a53:	e8 4f 1e 00 00       	call   801028a7 <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 5e 57 00 00       	call   801061d7 <allocuvm>
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
80100a9d:	e8 2d 58 00 00       	call   801062cf <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 0b 59 00 00       	call   801063cc <clearpteu>
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
80100ae2:	e8 e5 33 00 00       	call   80103ecc <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 d3 33 00 00       	call   80103ecc <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 0f 5a 00 00       	call   8010651a <copyout>
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
80100b66:	e8 af 59 00 00       	call   8010651a <copyout>
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
80100ba3:	e8 e9 32 00 00       	call   80103e91 <safestrcpy>
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
80100bd1:	e8 49 53 00 00       	call   80105f1f <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 f1 56 00 00       	call   801062cf <freevm>
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
80100c19:	68 2d 66 10 80       	push   $0x8010662d
80100c1e:	68 e0 ef 10 80       	push   $0x8010efe0
80100c23:	e8 1a 2f 00 00       	call   80103b42 <initlock>
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
80100c39:	e8 40 30 00 00       	call   80103c7e <acquire>
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
80100c68:	e8 76 30 00 00       	call   80103ce3 <release>
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
80100c7f:	e8 5f 30 00 00       	call   80103ce3 <release>
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
80100c9d:	e8 dc 2f 00 00       	call   80103c7e <acquire>
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
80100cba:	e8 24 30 00 00       	call   80103ce3 <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 34 66 10 80       	push   $0x80106634
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
80100ce2:	e8 97 2f 00 00       	call   80103c7e <acquire>
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
80100d03:	e8 db 2f 00 00       	call   80103ce3 <release>
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
80100d13:	68 3c 66 10 80       	push   $0x8010663c
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
80100d49:	e8 95 2f 00 00       	call   80103ce3 <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 ca 1a 00 00       	call   8010282d <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 34 1b 00 00       	call   801028a7 <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 21 21 00 00       	call   80102ea9 <pipeclose>
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
80100e3c:	e8 c0 21 00 00       	call   80103001 <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 46 66 10 80       	push   $0x80106646
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
80100e95:	e8 9b 20 00 00       	call   80102f35 <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 86 19 00 00       	call   8010282d <begin_op>
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
80100edd:	e8 c5 19 00 00       	call   801028a7 <end_op>

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
80100f10:	68 4f 66 10 80       	push   $0x8010664f
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
80100f2d:	68 55 66 10 80       	push   $0x80106655
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
80100f8a:	e8 16 2e 00 00       	call   80103da5 <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 06 2e 00 00       	call   80103da5 <memmove>
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
80100fdf:	e8 46 2d 00 00       	call   80103d2a <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 6a 19 00 00       	call   80102956 <log_write>
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
801010a3:	68 5f 66 10 80       	push   $0x8010665f
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
801010bf:	e8 92 18 00 00       	call   80102956 <log_write>
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
80101170:	e8 e1 17 00 00       	call   80102956 <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 75 66 10 80       	push   $0x80106675
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
8010119a:	e8 df 2a 00 00       	call   80103c7e <acquire>
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
801011e1:	e8 fd 2a 00 00       	call   80103ce3 <release>
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
80101217:	e8 c7 2a 00 00       	call   80103ce3 <release>
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
8010122c:	68 88 66 10 80       	push   $0x80106688
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
80101255:	e8 4b 2b 00 00       	call   80103da5 <memmove>
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
801012c8:	e8 89 16 00 00       	call   80102956 <log_write>
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
801012e2:	68 98 66 10 80       	push   $0x80106698
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 ab 66 10 80       	push   $0x801066ab
801012f8:	68 00 fa 10 80       	push   $0x8010fa00
801012fd:	e8 40 28 00 00       	call   80103b42 <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 b2 66 10 80       	push   $0x801066b2
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 40 fa 10 80       	add    $0x8010fa40,%eax
80101321:	50                   	push   %eax
80101322:	e8 10 27 00 00       	call   80103a37 <initsleeplock>
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
8010136c:	68 18 67 10 80       	push   $0x80106718
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
801013df:	68 b8 66 10 80       	push   $0x801066b8
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 34 29 00 00       	call   80103d2a <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 51 15 00 00       	call   80102956 <log_write>
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
80101480:	e8 20 29 00 00       	call   80103da5 <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 c9 14 00 00       	call   80102956 <log_write>
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
80101560:	e8 19 27 00 00       	call   80103c7e <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
80101575:	e8 69 27 00 00       	call   80103ce3 <release>
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
8010159a:	e8 cb 24 00 00       	call   80103a6a <acquiresleep>
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
801015b2:	68 ca 66 10 80       	push   $0x801066ca
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
80101614:	e8 8c 27 00 00       	call   80103da5 <memmove>
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
80101639:	68 d0 66 10 80       	push   $0x801066d0
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
80101656:	e8 99 24 00 00       	call   80103af4 <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 48 24 00 00       	call   80103ab9 <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 df 66 10 80       	push   $0x801066df
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
80101698:	e8 cd 23 00 00       	call   80103a6a <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 03 24 00 00       	call   80103ab9 <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
801016bd:	e8 bc 25 00 00       	call   80103c7e <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
801016d2:	e8 0c 26 00 00       	call   80103ce3 <release>
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
801016ea:	e8 8f 25 00 00       	call   80103c7e <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 00 fa 10 80 	movl   $0x8010fa00,(%esp)
801016f9:	e8 e5 25 00 00       	call   80103ce3 <release>
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
8010182a:	e8 76 25 00 00       	call   80103da5 <memmove>
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
80101926:	e8 7a 24 00 00       	call   80103da5 <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 23 10 00 00       	call   80102956 <log_write>
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
801019a9:	e8 5e 24 00 00       	call   80103e0c <strncmp>
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
801019d0:	68 e7 66 10 80       	push   $0x801066e7
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 f9 66 10 80       	push   $0x801066f9
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
80101a5a:	e8 1e 18 00 00       	call   8010327d <myproc>
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
80101b92:	68 08 67 10 80       	push   $0x80106708
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 9b 22 00 00       	call   80103e49 <strncpy>
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
80101bd7:	68 34 6d 10 80       	push   $0x80106d34
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
80101ccc:	68 6b 67 10 80       	push   $0x8010676b
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 74 67 10 80       	push   $0x80106774
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
80101d06:	68 86 67 10 80       	push   $0x80106786
80101d0b:	68 80 95 10 80       	push   $0x80109580
80101d10:	e8 2d 1e 00 00       	call   80103b42 <initlock>
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
80101d80:	e8 f9 1e 00 00       	call   80103c7e <acquire>

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
80101dad:	e8 d4 1a 00 00       	call   80103886 <wakeup>

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
80101dcb:	e8 13 1f 00 00       	call   80103ce3 <release>
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
80101de2:	e8 fc 1e 00 00       	call   80103ce3 <release>
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
80101e1a:	e8 d5 1c 00 00       	call   80103af4 <holdingsleep>
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
80101e47:	e8 32 1e 00 00       	call   80103c7e <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 95 10 80       	mov    $0x80109564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 8a 67 10 80       	push   $0x8010678a
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 a0 67 10 80       	push   $0x801067a0
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 b5 67 10 80       	push   $0x801067b5
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
80101ea9:	e8 73 18 00 00       	call   80103721 <sleep>
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
80101ec3:	e8 1b 1e 00 00       	call   80103ce3 <release>
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
80101f3f:	68 d4 67 10 80       	push   $0x801067d4
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
80101fd6:	e8 4f 1d 00 00       	call   80103d2a <memset>

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
80102005:	68 06 68 10 80       	push   $0x80106806
8010200a:	e8 39 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010200f:	83 ec 0c             	sub    $0xc,%esp
80102012:	68 60 16 11 80       	push   $0x80111660
80102017:	e8 62 1c 00 00       	call   80103c7e <acquire>
8010201c:	83 c4 10             	add    $0x10,%esp
8010201f:	eb c6                	jmp    80101fe7 <kfree+0x43>
    release(&kmem.lock);
80102021:	83 ec 0c             	sub    $0xc,%esp
80102024:	68 60 16 11 80       	push   $0x80111660
80102029:	e8 b5 1c 00 00       	call   80103ce3 <release>
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
8010206f:	68 0c 68 10 80       	push   $0x8010680c
80102074:	68 60 16 11 80       	push   $0x80111660
80102079:	e8 c4 1a 00 00       	call   80103b42 <initlock>
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
801020c9:	75 21                	jne    801020ec <kalloc+0x31>
    acquire(&kmem.lock);
  r = kmem.freelist;
801020cb:	8b 1d 98 16 11 80    	mov    0x80111698,%ebx
  if(r)
801020d1:	85 db                	test   %ebx,%ebx
801020d3:	74 07                	je     801020dc <kalloc+0x21>
    kmem.freelist = r->next;
801020d5:	8b 03                	mov    (%ebx),%eax
801020d7:	a3 98 16 11 80       	mov    %eax,0x80111698
  if(kmem.use_lock)
801020dc:	83 3d 94 16 11 80 00 	cmpl   $0x0,0x80111694
801020e3:	75 19                	jne    801020fe <kalloc+0x43>
    release(&kmem.lock);
  return (char*)r;
}
801020e5:	89 d8                	mov    %ebx,%eax
801020e7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801020ea:	c9                   	leave  
801020eb:	c3                   	ret    
    acquire(&kmem.lock);
801020ec:	83 ec 0c             	sub    $0xc,%esp
801020ef:	68 60 16 11 80       	push   $0x80111660
801020f4:	e8 85 1b 00 00       	call   80103c7e <acquire>
801020f9:	83 c4 10             	add    $0x10,%esp
801020fc:	eb cd                	jmp    801020cb <kalloc+0x10>
    release(&kmem.lock);
801020fe:	83 ec 0c             	sub    $0xc,%esp
80102101:	68 60 16 11 80       	push   $0x80111660
80102106:	e8 d8 1b 00 00       	call   80103ce3 <release>
8010210b:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
8010210e:	eb d5                	jmp    801020e5 <kalloc+0x2a>

80102110 <kalloc2>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc2(uint pid)
{
80102110:	55                   	push   %ebp
80102111:	89 e5                	mov    %esp,%ebp
80102113:	53                   	push   %ebx
80102114:	83 ec 04             	sub    $0x4,%esp
  struct run *r;

  if(kmem.use_lock)
80102117:	83 3d 94 16 11 80 00 	cmpl   $0x0,0x80111694
8010211e:	75 4b                	jne    8010216b <kalloc2+0x5b>
    acquire(&kmem.lock);
  r = kmem.freelist;
80102120:	8b 1d 98 16 11 80    	mov    0x80111698,%ebx
  if(r)
80102126:	85 db                	test   %ebx,%ebx
80102128:	74 07                	je     80102131 <kalloc2+0x21>
    kmem.freelist = r->next;
8010212a:	8b 03                	mov    (%ebx),%eax
8010212c:	a3 98 16 11 80       	mov    %eax,0x80111698


  //char* virt = (char*)r;
  // V2P and shift, and mask off
  uint framenumber = (uint)(V2P(r) >> 12 & 0xffff);
80102131:	8d 93 00 00 00 80    	lea    -0x80000000(%ebx),%edx
80102137:	c1 ea 0c             	shr    $0xc,%edx
8010213a:	0f b7 d2             	movzwl %dx,%edx

  frames[index] = framenumber;
8010213d:	a1 b4 95 10 80       	mov    0x801095b4,%eax
80102142:	89 14 85 a0 16 11 80 	mov    %edx,-0x7feee960(,%eax,4)
  pids[index] = pid;
80102149:	8b 55 08             	mov    0x8(%ebp),%edx
8010214c:	89 14 85 c0 16 12 80 	mov    %edx,-0x7fede940(,%eax,4)
  index++;
80102153:	83 c0 01             	add    $0x1,%eax
80102156:	a3 b4 95 10 80       	mov    %eax,0x801095b4

  if(kmem.use_lock)
8010215b:	83 3d 94 16 11 80 00 	cmpl   $0x0,0x80111694
80102162:	75 19                	jne    8010217d <kalloc2+0x6d>
    release(&kmem.lock);
  return (char*)r;
80102164:	89 d8                	mov    %ebx,%eax
80102166:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102169:	c9                   	leave  
8010216a:	c3                   	ret    
    acquire(&kmem.lock);
8010216b:	83 ec 0c             	sub    $0xc,%esp
8010216e:	68 60 16 11 80       	push   $0x80111660
80102173:	e8 06 1b 00 00       	call   80103c7e <acquire>
80102178:	83 c4 10             	add    $0x10,%esp
8010217b:	eb a3                	jmp    80102120 <kalloc2+0x10>
    release(&kmem.lock);
8010217d:	83 ec 0c             	sub    $0xc,%esp
80102180:	68 60 16 11 80       	push   $0x80111660
80102185:	e8 59 1b 00 00       	call   80103ce3 <release>
8010218a:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
8010218d:	eb d5                	jmp    80102164 <kalloc2+0x54>

8010218f <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
8010218f:	55                   	push   %ebp
80102190:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102192:	ba 64 00 00 00       	mov    $0x64,%edx
80102197:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
80102198:	a8 01                	test   $0x1,%al
8010219a:	0f 84 b5 00 00 00    	je     80102255 <kbdgetc+0xc6>
801021a0:	ba 60 00 00 00       	mov    $0x60,%edx
801021a5:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
801021a6:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
801021a9:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
801021af:	74 5c                	je     8010220d <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
801021b1:	84 c0                	test   %al,%al
801021b3:	78 66                	js     8010221b <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
801021b5:	8b 0d b8 95 10 80    	mov    0x801095b8,%ecx
801021bb:	f6 c1 40             	test   $0x40,%cl
801021be:	74 0f                	je     801021cf <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
801021c0:	83 c8 80             	or     $0xffffff80,%eax
801021c3:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
801021c6:	83 e1 bf             	and    $0xffffffbf,%ecx
801021c9:	89 0d b8 95 10 80    	mov    %ecx,0x801095b8
  }

  shift |= shiftcode[data];
801021cf:	0f b6 8a 40 69 10 80 	movzbl -0x7fef96c0(%edx),%ecx
801021d6:	0b 0d b8 95 10 80    	or     0x801095b8,%ecx
  shift ^= togglecode[data];
801021dc:	0f b6 82 40 68 10 80 	movzbl -0x7fef97c0(%edx),%eax
801021e3:	31 c1                	xor    %eax,%ecx
801021e5:	89 0d b8 95 10 80    	mov    %ecx,0x801095b8
  c = charcode[shift & (CTL | SHIFT)][data];
801021eb:	89 c8                	mov    %ecx,%eax
801021ed:	83 e0 03             	and    $0x3,%eax
801021f0:	8b 04 85 20 68 10 80 	mov    -0x7fef97e0(,%eax,4),%eax
801021f7:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
801021fb:	f6 c1 08             	test   $0x8,%cl
801021fe:	74 19                	je     80102219 <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
80102200:	8d 50 9f             	lea    -0x61(%eax),%edx
80102203:	83 fa 19             	cmp    $0x19,%edx
80102206:	77 40                	ja     80102248 <kbdgetc+0xb9>
      c += 'A' - 'a';
80102208:	83 e8 20             	sub    $0x20,%eax
8010220b:	eb 0c                	jmp    80102219 <kbdgetc+0x8a>
    shift |= E0ESC;
8010220d:	83 0d b8 95 10 80 40 	orl    $0x40,0x801095b8
    return 0;
80102214:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
80102219:	5d                   	pop    %ebp
8010221a:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
8010221b:	8b 0d b8 95 10 80    	mov    0x801095b8,%ecx
80102221:	f6 c1 40             	test   $0x40,%cl
80102224:	75 05                	jne    8010222b <kbdgetc+0x9c>
80102226:	89 c2                	mov    %eax,%edx
80102228:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
8010222b:	0f b6 82 40 69 10 80 	movzbl -0x7fef96c0(%edx),%eax
80102232:	83 c8 40             	or     $0x40,%eax
80102235:	0f b6 c0             	movzbl %al,%eax
80102238:	f7 d0                	not    %eax
8010223a:	21 c8                	and    %ecx,%eax
8010223c:	a3 b8 95 10 80       	mov    %eax,0x801095b8
    return 0;
80102241:	b8 00 00 00 00       	mov    $0x0,%eax
80102246:	eb d1                	jmp    80102219 <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
80102248:	8d 50 bf             	lea    -0x41(%eax),%edx
8010224b:	83 fa 19             	cmp    $0x19,%edx
8010224e:	77 c9                	ja     80102219 <kbdgetc+0x8a>
      c += 'a' - 'A';
80102250:	83 c0 20             	add    $0x20,%eax
  return c;
80102253:	eb c4                	jmp    80102219 <kbdgetc+0x8a>
    return -1;
80102255:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010225a:	eb bd                	jmp    80102219 <kbdgetc+0x8a>

8010225c <kbdintr>:

void
kbdintr(void)
{
8010225c:	55                   	push   %ebp
8010225d:	89 e5                	mov    %esp,%ebp
8010225f:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
80102262:	68 8f 21 10 80       	push   $0x8010218f
80102267:	e8 d2 e4 ff ff       	call   8010073e <consoleintr>
}
8010226c:	83 c4 10             	add    $0x10,%esp
8010226f:	c9                   	leave  
80102270:	c3                   	ret    

80102271 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102271:	55                   	push   %ebp
80102272:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102274:	8b 0d c4 16 13 80    	mov    0x801316c4,%ecx
8010227a:	8d 04 81             	lea    (%ecx,%eax,4),%eax
8010227d:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
8010227f:	a1 c4 16 13 80       	mov    0x801316c4,%eax
80102284:	8b 40 20             	mov    0x20(%eax),%eax
}
80102287:	5d                   	pop    %ebp
80102288:	c3                   	ret    

80102289 <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
80102289:	55                   	push   %ebp
8010228a:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010228c:	ba 70 00 00 00       	mov    $0x70,%edx
80102291:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102292:	ba 71 00 00 00       	mov    $0x71,%edx
80102297:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
80102298:	0f b6 c0             	movzbl %al,%eax
}
8010229b:	5d                   	pop    %ebp
8010229c:	c3                   	ret    

8010229d <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
8010229d:	55                   	push   %ebp
8010229e:	89 e5                	mov    %esp,%ebp
801022a0:	53                   	push   %ebx
801022a1:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
801022a3:	b8 00 00 00 00       	mov    $0x0,%eax
801022a8:	e8 dc ff ff ff       	call   80102289 <cmos_read>
801022ad:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
801022af:	b8 02 00 00 00       	mov    $0x2,%eax
801022b4:	e8 d0 ff ff ff       	call   80102289 <cmos_read>
801022b9:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
801022bc:	b8 04 00 00 00       	mov    $0x4,%eax
801022c1:	e8 c3 ff ff ff       	call   80102289 <cmos_read>
801022c6:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
801022c9:	b8 07 00 00 00       	mov    $0x7,%eax
801022ce:	e8 b6 ff ff ff       	call   80102289 <cmos_read>
801022d3:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
801022d6:	b8 08 00 00 00       	mov    $0x8,%eax
801022db:	e8 a9 ff ff ff       	call   80102289 <cmos_read>
801022e0:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
801022e3:	b8 09 00 00 00       	mov    $0x9,%eax
801022e8:	e8 9c ff ff ff       	call   80102289 <cmos_read>
801022ed:	89 43 14             	mov    %eax,0x14(%ebx)
}
801022f0:	5b                   	pop    %ebx
801022f1:	5d                   	pop    %ebp
801022f2:	c3                   	ret    

801022f3 <lapicinit>:
  if(!lapic)
801022f3:	83 3d c4 16 13 80 00 	cmpl   $0x0,0x801316c4
801022fa:	0f 84 fb 00 00 00    	je     801023fb <lapicinit+0x108>
{
80102300:	55                   	push   %ebp
80102301:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102303:	ba 3f 01 00 00       	mov    $0x13f,%edx
80102308:	b8 3c 00 00 00       	mov    $0x3c,%eax
8010230d:	e8 5f ff ff ff       	call   80102271 <lapicw>
  lapicw(TDCR, X1);
80102312:	ba 0b 00 00 00       	mov    $0xb,%edx
80102317:	b8 f8 00 00 00       	mov    $0xf8,%eax
8010231c:	e8 50 ff ff ff       	call   80102271 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102321:	ba 20 00 02 00       	mov    $0x20020,%edx
80102326:	b8 c8 00 00 00       	mov    $0xc8,%eax
8010232b:	e8 41 ff ff ff       	call   80102271 <lapicw>
  lapicw(TICR, 10000000);
80102330:	ba 80 96 98 00       	mov    $0x989680,%edx
80102335:	b8 e0 00 00 00       	mov    $0xe0,%eax
8010233a:	e8 32 ff ff ff       	call   80102271 <lapicw>
  lapicw(LINT0, MASKED);
8010233f:	ba 00 00 01 00       	mov    $0x10000,%edx
80102344:	b8 d4 00 00 00       	mov    $0xd4,%eax
80102349:	e8 23 ff ff ff       	call   80102271 <lapicw>
  lapicw(LINT1, MASKED);
8010234e:	ba 00 00 01 00       	mov    $0x10000,%edx
80102353:	b8 d8 00 00 00       	mov    $0xd8,%eax
80102358:	e8 14 ff ff ff       	call   80102271 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
8010235d:	a1 c4 16 13 80       	mov    0x801316c4,%eax
80102362:	8b 40 30             	mov    0x30(%eax),%eax
80102365:	c1 e8 10             	shr    $0x10,%eax
80102368:	3c 03                	cmp    $0x3,%al
8010236a:	77 7b                	ja     801023e7 <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
8010236c:	ba 33 00 00 00       	mov    $0x33,%edx
80102371:	b8 dc 00 00 00       	mov    $0xdc,%eax
80102376:	e8 f6 fe ff ff       	call   80102271 <lapicw>
  lapicw(ESR, 0);
8010237b:	ba 00 00 00 00       	mov    $0x0,%edx
80102380:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102385:	e8 e7 fe ff ff       	call   80102271 <lapicw>
  lapicw(ESR, 0);
8010238a:	ba 00 00 00 00       	mov    $0x0,%edx
8010238f:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102394:	e8 d8 fe ff ff       	call   80102271 <lapicw>
  lapicw(EOI, 0);
80102399:	ba 00 00 00 00       	mov    $0x0,%edx
8010239e:	b8 2c 00 00 00       	mov    $0x2c,%eax
801023a3:	e8 c9 fe ff ff       	call   80102271 <lapicw>
  lapicw(ICRHI, 0);
801023a8:	ba 00 00 00 00       	mov    $0x0,%edx
801023ad:	b8 c4 00 00 00       	mov    $0xc4,%eax
801023b2:	e8 ba fe ff ff       	call   80102271 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801023b7:	ba 00 85 08 00       	mov    $0x88500,%edx
801023bc:	b8 c0 00 00 00       	mov    $0xc0,%eax
801023c1:	e8 ab fe ff ff       	call   80102271 <lapicw>
  while(lapic[ICRLO] & DELIVS)
801023c6:	a1 c4 16 13 80       	mov    0x801316c4,%eax
801023cb:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
801023d1:	f6 c4 10             	test   $0x10,%ah
801023d4:	75 f0                	jne    801023c6 <lapicinit+0xd3>
  lapicw(TPR, 0);
801023d6:	ba 00 00 00 00       	mov    $0x0,%edx
801023db:	b8 20 00 00 00       	mov    $0x20,%eax
801023e0:	e8 8c fe ff ff       	call   80102271 <lapicw>
}
801023e5:	5d                   	pop    %ebp
801023e6:	c3                   	ret    
    lapicw(PCINT, MASKED);
801023e7:	ba 00 00 01 00       	mov    $0x10000,%edx
801023ec:	b8 d0 00 00 00       	mov    $0xd0,%eax
801023f1:	e8 7b fe ff ff       	call   80102271 <lapicw>
801023f6:	e9 71 ff ff ff       	jmp    8010236c <lapicinit+0x79>
801023fb:	f3 c3                	repz ret 

801023fd <lapicid>:
{
801023fd:	55                   	push   %ebp
801023fe:	89 e5                	mov    %esp,%ebp
  if (!lapic)
80102400:	a1 c4 16 13 80       	mov    0x801316c4,%eax
80102405:	85 c0                	test   %eax,%eax
80102407:	74 08                	je     80102411 <lapicid+0x14>
  return lapic[ID] >> 24;
80102409:	8b 40 20             	mov    0x20(%eax),%eax
8010240c:	c1 e8 18             	shr    $0x18,%eax
}
8010240f:	5d                   	pop    %ebp
80102410:	c3                   	ret    
    return 0;
80102411:	b8 00 00 00 00       	mov    $0x0,%eax
80102416:	eb f7                	jmp    8010240f <lapicid+0x12>

80102418 <lapiceoi>:
  if(lapic)
80102418:	83 3d c4 16 13 80 00 	cmpl   $0x0,0x801316c4
8010241f:	74 14                	je     80102435 <lapiceoi+0x1d>
{
80102421:	55                   	push   %ebp
80102422:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
80102424:	ba 00 00 00 00       	mov    $0x0,%edx
80102429:	b8 2c 00 00 00       	mov    $0x2c,%eax
8010242e:	e8 3e fe ff ff       	call   80102271 <lapicw>
}
80102433:	5d                   	pop    %ebp
80102434:	c3                   	ret    
80102435:	f3 c3                	repz ret 

80102437 <microdelay>:
{
80102437:	55                   	push   %ebp
80102438:	89 e5                	mov    %esp,%ebp
}
8010243a:	5d                   	pop    %ebp
8010243b:	c3                   	ret    

8010243c <lapicstartap>:
{
8010243c:	55                   	push   %ebp
8010243d:	89 e5                	mov    %esp,%ebp
8010243f:	57                   	push   %edi
80102440:	56                   	push   %esi
80102441:	53                   	push   %ebx
80102442:	8b 75 08             	mov    0x8(%ebp),%esi
80102445:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102448:	b8 0f 00 00 00       	mov    $0xf,%eax
8010244d:	ba 70 00 00 00       	mov    $0x70,%edx
80102452:	ee                   	out    %al,(%dx)
80102453:	b8 0a 00 00 00       	mov    $0xa,%eax
80102458:	ba 71 00 00 00       	mov    $0x71,%edx
8010245d:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
8010245e:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
80102465:	00 00 
  wrv[1] = addr >> 4;
80102467:	89 f8                	mov    %edi,%eax
80102469:	c1 e8 04             	shr    $0x4,%eax
8010246c:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
80102472:	c1 e6 18             	shl    $0x18,%esi
80102475:	89 f2                	mov    %esi,%edx
80102477:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010247c:	e8 f0 fd ff ff       	call   80102271 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102481:	ba 00 c5 00 00       	mov    $0xc500,%edx
80102486:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010248b:	e8 e1 fd ff ff       	call   80102271 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
80102490:	ba 00 85 00 00       	mov    $0x8500,%edx
80102495:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010249a:	e8 d2 fd ff ff       	call   80102271 <lapicw>
  for(i = 0; i < 2; i++){
8010249f:	bb 00 00 00 00       	mov    $0x0,%ebx
801024a4:	eb 21                	jmp    801024c7 <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
801024a6:	89 f2                	mov    %esi,%edx
801024a8:	b8 c4 00 00 00       	mov    $0xc4,%eax
801024ad:	e8 bf fd ff ff       	call   80102271 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
801024b2:	89 fa                	mov    %edi,%edx
801024b4:	c1 ea 0c             	shr    $0xc,%edx
801024b7:	80 ce 06             	or     $0x6,%dh
801024ba:	b8 c0 00 00 00       	mov    $0xc0,%eax
801024bf:	e8 ad fd ff ff       	call   80102271 <lapicw>
  for(i = 0; i < 2; i++){
801024c4:	83 c3 01             	add    $0x1,%ebx
801024c7:	83 fb 01             	cmp    $0x1,%ebx
801024ca:	7e da                	jle    801024a6 <lapicstartap+0x6a>
}
801024cc:	5b                   	pop    %ebx
801024cd:	5e                   	pop    %esi
801024ce:	5f                   	pop    %edi
801024cf:	5d                   	pop    %ebp
801024d0:	c3                   	ret    

801024d1 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
801024d1:	55                   	push   %ebp
801024d2:	89 e5                	mov    %esp,%ebp
801024d4:	57                   	push   %edi
801024d5:	56                   	push   %esi
801024d6:	53                   	push   %ebx
801024d7:	83 ec 3c             	sub    $0x3c,%esp
801024da:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801024dd:	b8 0b 00 00 00       	mov    $0xb,%eax
801024e2:	e8 a2 fd ff ff       	call   80102289 <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
801024e7:	83 e0 04             	and    $0x4,%eax
801024ea:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
801024ec:	8d 45 d0             	lea    -0x30(%ebp),%eax
801024ef:	e8 a9 fd ff ff       	call   8010229d <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
801024f4:	b8 0a 00 00 00       	mov    $0xa,%eax
801024f9:	e8 8b fd ff ff       	call   80102289 <cmos_read>
801024fe:	a8 80                	test   $0x80,%al
80102500:	75 ea                	jne    801024ec <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
80102502:	8d 5d b8             	lea    -0x48(%ebp),%ebx
80102505:	89 d8                	mov    %ebx,%eax
80102507:	e8 91 fd ff ff       	call   8010229d <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
8010250c:	83 ec 04             	sub    $0x4,%esp
8010250f:	6a 18                	push   $0x18
80102511:	53                   	push   %ebx
80102512:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102515:	50                   	push   %eax
80102516:	e8 55 18 00 00       	call   80103d70 <memcmp>
8010251b:	83 c4 10             	add    $0x10,%esp
8010251e:	85 c0                	test   %eax,%eax
80102520:	75 ca                	jne    801024ec <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
80102522:	85 ff                	test   %edi,%edi
80102524:	0f 85 84 00 00 00    	jne    801025ae <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
8010252a:	8b 55 d0             	mov    -0x30(%ebp),%edx
8010252d:	89 d0                	mov    %edx,%eax
8010252f:	c1 e8 04             	shr    $0x4,%eax
80102532:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102535:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102538:	83 e2 0f             	and    $0xf,%edx
8010253b:	01 d0                	add    %edx,%eax
8010253d:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
80102540:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80102543:	89 d0                	mov    %edx,%eax
80102545:	c1 e8 04             	shr    $0x4,%eax
80102548:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010254b:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010254e:	83 e2 0f             	and    $0xf,%edx
80102551:	01 d0                	add    %edx,%eax
80102553:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
80102556:	8b 55 d8             	mov    -0x28(%ebp),%edx
80102559:	89 d0                	mov    %edx,%eax
8010255b:	c1 e8 04             	shr    $0x4,%eax
8010255e:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102561:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102564:	83 e2 0f             	and    $0xf,%edx
80102567:	01 d0                	add    %edx,%eax
80102569:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
8010256c:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010256f:	89 d0                	mov    %edx,%eax
80102571:	c1 e8 04             	shr    $0x4,%eax
80102574:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102577:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010257a:	83 e2 0f             	and    $0xf,%edx
8010257d:	01 d0                	add    %edx,%eax
8010257f:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
80102582:	8b 55 e0             	mov    -0x20(%ebp),%edx
80102585:	89 d0                	mov    %edx,%eax
80102587:	c1 e8 04             	shr    $0x4,%eax
8010258a:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010258d:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102590:	83 e2 0f             	and    $0xf,%edx
80102593:	01 d0                	add    %edx,%eax
80102595:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
80102598:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010259b:	89 d0                	mov    %edx,%eax
8010259d:	c1 e8 04             	shr    $0x4,%eax
801025a0:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025a3:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025a6:	83 e2 0f             	and    $0xf,%edx
801025a9:	01 d0                	add    %edx,%eax
801025ab:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
801025ae:	8b 45 d0             	mov    -0x30(%ebp),%eax
801025b1:	89 06                	mov    %eax,(%esi)
801025b3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801025b6:	89 46 04             	mov    %eax,0x4(%esi)
801025b9:	8b 45 d8             	mov    -0x28(%ebp),%eax
801025bc:	89 46 08             	mov    %eax,0x8(%esi)
801025bf:	8b 45 dc             	mov    -0x24(%ebp),%eax
801025c2:	89 46 0c             	mov    %eax,0xc(%esi)
801025c5:	8b 45 e0             	mov    -0x20(%ebp),%eax
801025c8:	89 46 10             	mov    %eax,0x10(%esi)
801025cb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801025ce:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
801025d1:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
801025d8:	8d 65 f4             	lea    -0xc(%ebp),%esp
801025db:	5b                   	pop    %ebx
801025dc:	5e                   	pop    %esi
801025dd:	5f                   	pop    %edi
801025de:	5d                   	pop    %ebp
801025df:	c3                   	ret    

801025e0 <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
801025e0:	55                   	push   %ebp
801025e1:	89 e5                	mov    %esp,%ebp
801025e3:	53                   	push   %ebx
801025e4:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
801025e7:	ff 35 14 17 13 80    	pushl  0x80131714
801025ed:	ff 35 24 17 13 80    	pushl  0x80131724
801025f3:	e8 74 db ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
801025f8:	8b 58 5c             	mov    0x5c(%eax),%ebx
801025fb:	89 1d 28 17 13 80    	mov    %ebx,0x80131728
  for (i = 0; i < log.lh.n; i++) {
80102601:	83 c4 10             	add    $0x10,%esp
80102604:	ba 00 00 00 00       	mov    $0x0,%edx
80102609:	eb 0e                	jmp    80102619 <read_head+0x39>
    log.lh.block[i] = lh->block[i];
8010260b:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
8010260f:	89 0c 95 2c 17 13 80 	mov    %ecx,-0x7fece8d4(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
80102616:	83 c2 01             	add    $0x1,%edx
80102619:	39 d3                	cmp    %edx,%ebx
8010261b:	7f ee                	jg     8010260b <read_head+0x2b>
  }
  brelse(buf);
8010261d:	83 ec 0c             	sub    $0xc,%esp
80102620:	50                   	push   %eax
80102621:	e8 af db ff ff       	call   801001d5 <brelse>
}
80102626:	83 c4 10             	add    $0x10,%esp
80102629:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010262c:	c9                   	leave  
8010262d:	c3                   	ret    

8010262e <install_trans>:
{
8010262e:	55                   	push   %ebp
8010262f:	89 e5                	mov    %esp,%ebp
80102631:	57                   	push   %edi
80102632:	56                   	push   %esi
80102633:	53                   	push   %ebx
80102634:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
80102637:	bb 00 00 00 00       	mov    $0x0,%ebx
8010263c:	eb 66                	jmp    801026a4 <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
8010263e:	89 d8                	mov    %ebx,%eax
80102640:	03 05 14 17 13 80    	add    0x80131714,%eax
80102646:	83 c0 01             	add    $0x1,%eax
80102649:	83 ec 08             	sub    $0x8,%esp
8010264c:	50                   	push   %eax
8010264d:	ff 35 24 17 13 80    	pushl  0x80131724
80102653:	e8 14 db ff ff       	call   8010016c <bread>
80102658:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
8010265a:	83 c4 08             	add    $0x8,%esp
8010265d:	ff 34 9d 2c 17 13 80 	pushl  -0x7fece8d4(,%ebx,4)
80102664:	ff 35 24 17 13 80    	pushl  0x80131724
8010266a:	e8 fd da ff ff       	call   8010016c <bread>
8010266f:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80102671:	8d 57 5c             	lea    0x5c(%edi),%edx
80102674:	8d 40 5c             	lea    0x5c(%eax),%eax
80102677:	83 c4 0c             	add    $0xc,%esp
8010267a:	68 00 02 00 00       	push   $0x200
8010267f:	52                   	push   %edx
80102680:	50                   	push   %eax
80102681:	e8 1f 17 00 00       	call   80103da5 <memmove>
    bwrite(dbuf);  // write dst to disk
80102686:	89 34 24             	mov    %esi,(%esp)
80102689:	e8 0c db ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
8010268e:	89 3c 24             	mov    %edi,(%esp)
80102691:	e8 3f db ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
80102696:	89 34 24             	mov    %esi,(%esp)
80102699:	e8 37 db ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
8010269e:	83 c3 01             	add    $0x1,%ebx
801026a1:	83 c4 10             	add    $0x10,%esp
801026a4:	39 1d 28 17 13 80    	cmp    %ebx,0x80131728
801026aa:	7f 92                	jg     8010263e <install_trans+0x10>
}
801026ac:	8d 65 f4             	lea    -0xc(%ebp),%esp
801026af:	5b                   	pop    %ebx
801026b0:	5e                   	pop    %esi
801026b1:	5f                   	pop    %edi
801026b2:	5d                   	pop    %ebp
801026b3:	c3                   	ret    

801026b4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801026b4:	55                   	push   %ebp
801026b5:	89 e5                	mov    %esp,%ebp
801026b7:	53                   	push   %ebx
801026b8:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
801026bb:	ff 35 14 17 13 80    	pushl  0x80131714
801026c1:	ff 35 24 17 13 80    	pushl  0x80131724
801026c7:	e8 a0 da ff ff       	call   8010016c <bread>
801026cc:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
801026ce:	8b 0d 28 17 13 80    	mov    0x80131728,%ecx
801026d4:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
801026d7:	83 c4 10             	add    $0x10,%esp
801026da:	b8 00 00 00 00       	mov    $0x0,%eax
801026df:	eb 0e                	jmp    801026ef <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
801026e1:	8b 14 85 2c 17 13 80 	mov    -0x7fece8d4(,%eax,4),%edx
801026e8:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
801026ec:	83 c0 01             	add    $0x1,%eax
801026ef:	39 c1                	cmp    %eax,%ecx
801026f1:	7f ee                	jg     801026e1 <write_head+0x2d>
  }
  bwrite(buf);
801026f3:	83 ec 0c             	sub    $0xc,%esp
801026f6:	53                   	push   %ebx
801026f7:	e8 9e da ff ff       	call   8010019a <bwrite>
  brelse(buf);
801026fc:	89 1c 24             	mov    %ebx,(%esp)
801026ff:	e8 d1 da ff ff       	call   801001d5 <brelse>
}
80102704:	83 c4 10             	add    $0x10,%esp
80102707:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010270a:	c9                   	leave  
8010270b:	c3                   	ret    

8010270c <recover_from_log>:

static void
recover_from_log(void)
{
8010270c:	55                   	push   %ebp
8010270d:	89 e5                	mov    %esp,%ebp
8010270f:	83 ec 08             	sub    $0x8,%esp
  read_head();
80102712:	e8 c9 fe ff ff       	call   801025e0 <read_head>
  install_trans(); // if committed, copy from log to disk
80102717:	e8 12 ff ff ff       	call   8010262e <install_trans>
  log.lh.n = 0;
8010271c:	c7 05 28 17 13 80 00 	movl   $0x0,0x80131728
80102723:	00 00 00 
  write_head(); // clear the log
80102726:	e8 89 ff ff ff       	call   801026b4 <write_head>
}
8010272b:	c9                   	leave  
8010272c:	c3                   	ret    

8010272d <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
8010272d:	55                   	push   %ebp
8010272e:	89 e5                	mov    %esp,%ebp
80102730:	57                   	push   %edi
80102731:	56                   	push   %esi
80102732:	53                   	push   %ebx
80102733:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80102736:	bb 00 00 00 00       	mov    $0x0,%ebx
8010273b:	eb 66                	jmp    801027a3 <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
8010273d:	89 d8                	mov    %ebx,%eax
8010273f:	03 05 14 17 13 80    	add    0x80131714,%eax
80102745:	83 c0 01             	add    $0x1,%eax
80102748:	83 ec 08             	sub    $0x8,%esp
8010274b:	50                   	push   %eax
8010274c:	ff 35 24 17 13 80    	pushl  0x80131724
80102752:	e8 15 da ff ff       	call   8010016c <bread>
80102757:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80102759:	83 c4 08             	add    $0x8,%esp
8010275c:	ff 34 9d 2c 17 13 80 	pushl  -0x7fece8d4(,%ebx,4)
80102763:	ff 35 24 17 13 80    	pushl  0x80131724
80102769:	e8 fe d9 ff ff       	call   8010016c <bread>
8010276e:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
80102770:	8d 50 5c             	lea    0x5c(%eax),%edx
80102773:	8d 46 5c             	lea    0x5c(%esi),%eax
80102776:	83 c4 0c             	add    $0xc,%esp
80102779:	68 00 02 00 00       	push   $0x200
8010277e:	52                   	push   %edx
8010277f:	50                   	push   %eax
80102780:	e8 20 16 00 00       	call   80103da5 <memmove>
    bwrite(to);  // write the log
80102785:	89 34 24             	mov    %esi,(%esp)
80102788:	e8 0d da ff ff       	call   8010019a <bwrite>
    brelse(from);
8010278d:	89 3c 24             	mov    %edi,(%esp)
80102790:	e8 40 da ff ff       	call   801001d5 <brelse>
    brelse(to);
80102795:	89 34 24             	mov    %esi,(%esp)
80102798:	e8 38 da ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
8010279d:	83 c3 01             	add    $0x1,%ebx
801027a0:	83 c4 10             	add    $0x10,%esp
801027a3:	39 1d 28 17 13 80    	cmp    %ebx,0x80131728
801027a9:	7f 92                	jg     8010273d <write_log+0x10>
  }
}
801027ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
801027ae:	5b                   	pop    %ebx
801027af:	5e                   	pop    %esi
801027b0:	5f                   	pop    %edi
801027b1:	5d                   	pop    %ebp
801027b2:	c3                   	ret    

801027b3 <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
801027b3:	83 3d 28 17 13 80 00 	cmpl   $0x0,0x80131728
801027ba:	7e 26                	jle    801027e2 <commit+0x2f>
{
801027bc:	55                   	push   %ebp
801027bd:	89 e5                	mov    %esp,%ebp
801027bf:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
801027c2:	e8 66 ff ff ff       	call   8010272d <write_log>
    write_head();    // Write header to disk -- the real commit
801027c7:	e8 e8 fe ff ff       	call   801026b4 <write_head>
    install_trans(); // Now install writes to home locations
801027cc:	e8 5d fe ff ff       	call   8010262e <install_trans>
    log.lh.n = 0;
801027d1:	c7 05 28 17 13 80 00 	movl   $0x0,0x80131728
801027d8:	00 00 00 
    write_head();    // Erase the transaction from the log
801027db:	e8 d4 fe ff ff       	call   801026b4 <write_head>
  }
}
801027e0:	c9                   	leave  
801027e1:	c3                   	ret    
801027e2:	f3 c3                	repz ret 

801027e4 <initlog>:
{
801027e4:	55                   	push   %ebp
801027e5:	89 e5                	mov    %esp,%ebp
801027e7:	53                   	push   %ebx
801027e8:	83 ec 2c             	sub    $0x2c,%esp
801027eb:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
801027ee:	68 40 6a 10 80       	push   $0x80106a40
801027f3:	68 e0 16 13 80       	push   $0x801316e0
801027f8:	e8 45 13 00 00       	call   80103b42 <initlock>
  readsb(dev, &sb);
801027fd:	83 c4 08             	add    $0x8,%esp
80102800:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102803:	50                   	push   %eax
80102804:	53                   	push   %ebx
80102805:	e8 2c ea ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
8010280a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010280d:	a3 14 17 13 80       	mov    %eax,0x80131714
  log.size = sb.nlog;
80102812:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102815:	a3 18 17 13 80       	mov    %eax,0x80131718
  log.dev = dev;
8010281a:	89 1d 24 17 13 80    	mov    %ebx,0x80131724
  recover_from_log();
80102820:	e8 e7 fe ff ff       	call   8010270c <recover_from_log>
}
80102825:	83 c4 10             	add    $0x10,%esp
80102828:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010282b:	c9                   	leave  
8010282c:	c3                   	ret    

8010282d <begin_op>:
{
8010282d:	55                   	push   %ebp
8010282e:	89 e5                	mov    %esp,%ebp
80102830:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
80102833:	68 e0 16 13 80       	push   $0x801316e0
80102838:	e8 41 14 00 00       	call   80103c7e <acquire>
8010283d:	83 c4 10             	add    $0x10,%esp
80102840:	eb 15                	jmp    80102857 <begin_op+0x2a>
      sleep(&log, &log.lock);
80102842:	83 ec 08             	sub    $0x8,%esp
80102845:	68 e0 16 13 80       	push   $0x801316e0
8010284a:	68 e0 16 13 80       	push   $0x801316e0
8010284f:	e8 cd 0e 00 00       	call   80103721 <sleep>
80102854:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
80102857:	83 3d 20 17 13 80 00 	cmpl   $0x0,0x80131720
8010285e:	75 e2                	jne    80102842 <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80102860:	a1 1c 17 13 80       	mov    0x8013171c,%eax
80102865:	83 c0 01             	add    $0x1,%eax
80102868:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010286b:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
8010286e:	03 15 28 17 13 80    	add    0x80131728,%edx
80102874:	83 fa 1e             	cmp    $0x1e,%edx
80102877:	7e 17                	jle    80102890 <begin_op+0x63>
      sleep(&log, &log.lock);
80102879:	83 ec 08             	sub    $0x8,%esp
8010287c:	68 e0 16 13 80       	push   $0x801316e0
80102881:	68 e0 16 13 80       	push   $0x801316e0
80102886:	e8 96 0e 00 00       	call   80103721 <sleep>
8010288b:	83 c4 10             	add    $0x10,%esp
8010288e:	eb c7                	jmp    80102857 <begin_op+0x2a>
      log.outstanding += 1;
80102890:	a3 1c 17 13 80       	mov    %eax,0x8013171c
      release(&log.lock);
80102895:	83 ec 0c             	sub    $0xc,%esp
80102898:	68 e0 16 13 80       	push   $0x801316e0
8010289d:	e8 41 14 00 00       	call   80103ce3 <release>
}
801028a2:	83 c4 10             	add    $0x10,%esp
801028a5:	c9                   	leave  
801028a6:	c3                   	ret    

801028a7 <end_op>:
{
801028a7:	55                   	push   %ebp
801028a8:	89 e5                	mov    %esp,%ebp
801028aa:	53                   	push   %ebx
801028ab:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
801028ae:	68 e0 16 13 80       	push   $0x801316e0
801028b3:	e8 c6 13 00 00       	call   80103c7e <acquire>
  log.outstanding -= 1;
801028b8:	a1 1c 17 13 80       	mov    0x8013171c,%eax
801028bd:	83 e8 01             	sub    $0x1,%eax
801028c0:	a3 1c 17 13 80       	mov    %eax,0x8013171c
  if(log.committing)
801028c5:	8b 1d 20 17 13 80    	mov    0x80131720,%ebx
801028cb:	83 c4 10             	add    $0x10,%esp
801028ce:	85 db                	test   %ebx,%ebx
801028d0:	75 2c                	jne    801028fe <end_op+0x57>
  if(log.outstanding == 0){
801028d2:	85 c0                	test   %eax,%eax
801028d4:	75 35                	jne    8010290b <end_op+0x64>
    log.committing = 1;
801028d6:	c7 05 20 17 13 80 01 	movl   $0x1,0x80131720
801028dd:	00 00 00 
    do_commit = 1;
801028e0:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
801028e5:	83 ec 0c             	sub    $0xc,%esp
801028e8:	68 e0 16 13 80       	push   $0x801316e0
801028ed:	e8 f1 13 00 00       	call   80103ce3 <release>
  if(do_commit){
801028f2:	83 c4 10             	add    $0x10,%esp
801028f5:	85 db                	test   %ebx,%ebx
801028f7:	75 24                	jne    8010291d <end_op+0x76>
}
801028f9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801028fc:	c9                   	leave  
801028fd:	c3                   	ret    
    panic("log.committing");
801028fe:	83 ec 0c             	sub    $0xc,%esp
80102901:	68 44 6a 10 80       	push   $0x80106a44
80102906:	e8 3d da ff ff       	call   80100348 <panic>
    wakeup(&log);
8010290b:	83 ec 0c             	sub    $0xc,%esp
8010290e:	68 e0 16 13 80       	push   $0x801316e0
80102913:	e8 6e 0f 00 00       	call   80103886 <wakeup>
80102918:	83 c4 10             	add    $0x10,%esp
8010291b:	eb c8                	jmp    801028e5 <end_op+0x3e>
    commit();
8010291d:	e8 91 fe ff ff       	call   801027b3 <commit>
    acquire(&log.lock);
80102922:	83 ec 0c             	sub    $0xc,%esp
80102925:	68 e0 16 13 80       	push   $0x801316e0
8010292a:	e8 4f 13 00 00       	call   80103c7e <acquire>
    log.committing = 0;
8010292f:	c7 05 20 17 13 80 00 	movl   $0x0,0x80131720
80102936:	00 00 00 
    wakeup(&log);
80102939:	c7 04 24 e0 16 13 80 	movl   $0x801316e0,(%esp)
80102940:	e8 41 0f 00 00       	call   80103886 <wakeup>
    release(&log.lock);
80102945:	c7 04 24 e0 16 13 80 	movl   $0x801316e0,(%esp)
8010294c:	e8 92 13 00 00       	call   80103ce3 <release>
80102951:	83 c4 10             	add    $0x10,%esp
}
80102954:	eb a3                	jmp    801028f9 <end_op+0x52>

80102956 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80102956:	55                   	push   %ebp
80102957:	89 e5                	mov    %esp,%ebp
80102959:	53                   	push   %ebx
8010295a:	83 ec 04             	sub    $0x4,%esp
8010295d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80102960:	8b 15 28 17 13 80    	mov    0x80131728,%edx
80102966:	83 fa 1d             	cmp    $0x1d,%edx
80102969:	7f 45                	jg     801029b0 <log_write+0x5a>
8010296b:	a1 18 17 13 80       	mov    0x80131718,%eax
80102970:	83 e8 01             	sub    $0x1,%eax
80102973:	39 c2                	cmp    %eax,%edx
80102975:	7d 39                	jge    801029b0 <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102977:	83 3d 1c 17 13 80 00 	cmpl   $0x0,0x8013171c
8010297e:	7e 3d                	jle    801029bd <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102980:	83 ec 0c             	sub    $0xc,%esp
80102983:	68 e0 16 13 80       	push   $0x801316e0
80102988:	e8 f1 12 00 00       	call   80103c7e <acquire>
  for (i = 0; i < log.lh.n; i++) {
8010298d:	83 c4 10             	add    $0x10,%esp
80102990:	b8 00 00 00 00       	mov    $0x0,%eax
80102995:	8b 15 28 17 13 80    	mov    0x80131728,%edx
8010299b:	39 c2                	cmp    %eax,%edx
8010299d:	7e 2b                	jle    801029ca <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
8010299f:	8b 4b 08             	mov    0x8(%ebx),%ecx
801029a2:	39 0c 85 2c 17 13 80 	cmp    %ecx,-0x7fece8d4(,%eax,4)
801029a9:	74 1f                	je     801029ca <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
801029ab:	83 c0 01             	add    $0x1,%eax
801029ae:	eb e5                	jmp    80102995 <log_write+0x3f>
    panic("too big a transaction");
801029b0:	83 ec 0c             	sub    $0xc,%esp
801029b3:	68 53 6a 10 80       	push   $0x80106a53
801029b8:	e8 8b d9 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
801029bd:	83 ec 0c             	sub    $0xc,%esp
801029c0:	68 69 6a 10 80       	push   $0x80106a69
801029c5:	e8 7e d9 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
801029ca:	8b 4b 08             	mov    0x8(%ebx),%ecx
801029cd:	89 0c 85 2c 17 13 80 	mov    %ecx,-0x7fece8d4(,%eax,4)
  if (i == log.lh.n)
801029d4:	39 c2                	cmp    %eax,%edx
801029d6:	74 18                	je     801029f0 <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
801029d8:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
801029db:	83 ec 0c             	sub    $0xc,%esp
801029de:	68 e0 16 13 80       	push   $0x801316e0
801029e3:	e8 fb 12 00 00       	call   80103ce3 <release>
}
801029e8:	83 c4 10             	add    $0x10,%esp
801029eb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801029ee:	c9                   	leave  
801029ef:	c3                   	ret    
    log.lh.n++;
801029f0:	83 c2 01             	add    $0x1,%edx
801029f3:	89 15 28 17 13 80    	mov    %edx,0x80131728
801029f9:	eb dd                	jmp    801029d8 <log_write+0x82>

801029fb <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
801029fb:	55                   	push   %ebp
801029fc:	89 e5                	mov    %esp,%ebp
801029fe:	53                   	push   %ebx
801029ff:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102a02:	68 8a 00 00 00       	push   $0x8a
80102a07:	68 8c 94 10 80       	push   $0x8010948c
80102a0c:	68 00 70 00 80       	push   $0x80007000
80102a11:	e8 8f 13 00 00       	call   80103da5 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102a16:	83 c4 10             	add    $0x10,%esp
80102a19:	bb e0 17 13 80       	mov    $0x801317e0,%ebx
80102a1e:	eb 06                	jmp    80102a26 <startothers+0x2b>
80102a20:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102a26:	69 05 60 1d 13 80 b0 	imul   $0xb0,0x80131d60,%eax
80102a2d:	00 00 00 
80102a30:	05 e0 17 13 80       	add    $0x801317e0,%eax
80102a35:	39 d8                	cmp    %ebx,%eax
80102a37:	76 4c                	jbe    80102a85 <startothers+0x8a>
    if(c == mycpu())  // We've started already.
80102a39:	e8 c8 07 00 00       	call   80103206 <mycpu>
80102a3e:	39 d8                	cmp    %ebx,%eax
80102a40:	74 de                	je     80102a20 <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80102a42:	e8 74 f6 ff ff       	call   801020bb <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102a47:	05 00 10 00 00       	add    $0x1000,%eax
80102a4c:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102a51:	c7 05 f8 6f 00 80 c9 	movl   $0x80102ac9,0x80006ff8
80102a58:	2a 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102a5b:	c7 05 f4 6f 00 80 00 	movl   $0x108000,0x80006ff4
80102a62:	80 10 00 

    lapicstartap(c->apicid, V2P(code));
80102a65:	83 ec 08             	sub    $0x8,%esp
80102a68:	68 00 70 00 00       	push   $0x7000
80102a6d:	0f b6 03             	movzbl (%ebx),%eax
80102a70:	50                   	push   %eax
80102a71:	e8 c6 f9 ff ff       	call   8010243c <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102a76:	83 c4 10             	add    $0x10,%esp
80102a79:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102a7f:	85 c0                	test   %eax,%eax
80102a81:	74 f6                	je     80102a79 <startothers+0x7e>
80102a83:	eb 9b                	jmp    80102a20 <startothers+0x25>
      ;
  }
}
80102a85:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a88:	c9                   	leave  
80102a89:	c3                   	ret    

80102a8a <mpmain>:
{
80102a8a:	55                   	push   %ebp
80102a8b:	89 e5                	mov    %esp,%ebp
80102a8d:	53                   	push   %ebx
80102a8e:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102a91:	e8 cc 07 00 00       	call   80103262 <cpuid>
80102a96:	89 c3                	mov    %eax,%ebx
80102a98:	e8 c5 07 00 00       	call   80103262 <cpuid>
80102a9d:	83 ec 04             	sub    $0x4,%esp
80102aa0:	53                   	push   %ebx
80102aa1:	50                   	push   %eax
80102aa2:	68 84 6a 10 80       	push   $0x80106a84
80102aa7:	e8 5f db ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102aac:	e8 4b 24 00 00       	call   80104efc <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102ab1:	e8 50 07 00 00       	call   80103206 <mycpu>
80102ab6:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102ab8:	b8 01 00 00 00       	mov    $0x1,%eax
80102abd:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102ac4:	e8 33 0a 00 00       	call   801034fc <scheduler>

80102ac9 <mpenter>:
{
80102ac9:	55                   	push   %ebp
80102aca:	89 e5                	mov    %esp,%ebp
80102acc:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102acf:	e8 39 34 00 00       	call   80105f0d <switchkvm>
  seginit();
80102ad4:	e8 e8 32 00 00       	call   80105dc1 <seginit>
  lapicinit();
80102ad9:	e8 15 f8 ff ff       	call   801022f3 <lapicinit>
  mpmain();
80102ade:	e8 a7 ff ff ff       	call   80102a8a <mpmain>

80102ae3 <main>:
{
80102ae3:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102ae7:	83 e4 f0             	and    $0xfffffff0,%esp
80102aea:	ff 71 fc             	pushl  -0x4(%ecx)
80102aed:	55                   	push   %ebp
80102aee:	89 e5                	mov    %esp,%ebp
80102af0:	51                   	push   %ecx
80102af1:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102af4:	68 00 00 40 80       	push   $0x80400000
80102af9:	68 08 45 13 80       	push   $0x80134508
80102afe:	e8 66 f5 ff ff       	call   80102069 <kinit1>
  kvmalloc();      // kernel page table
80102b03:	e8 ad 38 00 00       	call   801063b5 <kvmalloc>
  mpinit();        // detect other processors
80102b08:	e8 c9 01 00 00       	call   80102cd6 <mpinit>
  lapicinit();     // interrupt controller
80102b0d:	e8 e1 f7 ff ff       	call   801022f3 <lapicinit>
  seginit();       // segment descriptors
80102b12:	e8 aa 32 00 00       	call   80105dc1 <seginit>
  picinit();       // disable pic
80102b17:	e8 82 02 00 00       	call   80102d9e <picinit>
  ioapicinit();    // another interrupt controller
80102b1c:	e8 d9 f3 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102b21:	e8 68 dd ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102b26:	e8 7f 26 00 00       	call   801051aa <uartinit>
  pinit();         // process table
80102b2b:	e8 bc 06 00 00       	call   801031ec <pinit>
  tvinit();        // trap vectors
80102b30:	e8 16 23 00 00       	call   80104e4b <tvinit>
  binit();         // buffer cache
80102b35:	e8 ba d5 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102b3a:	e8 d4 e0 ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102b3f:	e8 bc f1 ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102b44:	e8 b2 fe ff ff       	call   801029fb <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102b49:	83 c4 08             	add    $0x8,%esp
80102b4c:	68 00 00 00 8e       	push   $0x8e000000
80102b51:	68 00 00 40 80       	push   $0x80400000
80102b56:	e8 40 f5 ff ff       	call   8010209b <kinit2>
  userinit();      // first user process
80102b5b:	e8 41 07 00 00       	call   801032a1 <userinit>
  mpmain();        // finish this processor's setup
80102b60:	e8 25 ff ff ff       	call   80102a8a <mpmain>

80102b65 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102b65:	55                   	push   %ebp
80102b66:	89 e5                	mov    %esp,%ebp
80102b68:	56                   	push   %esi
80102b69:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102b6a:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102b6f:	b9 00 00 00 00       	mov    $0x0,%ecx
80102b74:	eb 09                	jmp    80102b7f <sum+0x1a>
    sum += addr[i];
80102b76:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102b7a:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102b7c:	83 c1 01             	add    $0x1,%ecx
80102b7f:	39 d1                	cmp    %edx,%ecx
80102b81:	7c f3                	jl     80102b76 <sum+0x11>
  return sum;
}
80102b83:	89 d8                	mov    %ebx,%eax
80102b85:	5b                   	pop    %ebx
80102b86:	5e                   	pop    %esi
80102b87:	5d                   	pop    %ebp
80102b88:	c3                   	ret    

80102b89 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102b89:	55                   	push   %ebp
80102b8a:	89 e5                	mov    %esp,%ebp
80102b8c:	56                   	push   %esi
80102b8d:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102b8e:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102b94:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102b96:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102b98:	eb 03                	jmp    80102b9d <mpsearch1+0x14>
80102b9a:	83 c3 10             	add    $0x10,%ebx
80102b9d:	39 f3                	cmp    %esi,%ebx
80102b9f:	73 29                	jae    80102bca <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102ba1:	83 ec 04             	sub    $0x4,%esp
80102ba4:	6a 04                	push   $0x4
80102ba6:	68 98 6a 10 80       	push   $0x80106a98
80102bab:	53                   	push   %ebx
80102bac:	e8 bf 11 00 00       	call   80103d70 <memcmp>
80102bb1:	83 c4 10             	add    $0x10,%esp
80102bb4:	85 c0                	test   %eax,%eax
80102bb6:	75 e2                	jne    80102b9a <mpsearch1+0x11>
80102bb8:	ba 10 00 00 00       	mov    $0x10,%edx
80102bbd:	89 d8                	mov    %ebx,%eax
80102bbf:	e8 a1 ff ff ff       	call   80102b65 <sum>
80102bc4:	84 c0                	test   %al,%al
80102bc6:	75 d2                	jne    80102b9a <mpsearch1+0x11>
80102bc8:	eb 05                	jmp    80102bcf <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102bca:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102bcf:	89 d8                	mov    %ebx,%eax
80102bd1:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102bd4:	5b                   	pop    %ebx
80102bd5:	5e                   	pop    %esi
80102bd6:	5d                   	pop    %ebp
80102bd7:	c3                   	ret    

80102bd8 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102bd8:	55                   	push   %ebp
80102bd9:	89 e5                	mov    %esp,%ebp
80102bdb:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102bde:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102be5:	c1 e0 08             	shl    $0x8,%eax
80102be8:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102bef:	09 d0                	or     %edx,%eax
80102bf1:	c1 e0 04             	shl    $0x4,%eax
80102bf4:	85 c0                	test   %eax,%eax
80102bf6:	74 1f                	je     80102c17 <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102bf8:	ba 00 04 00 00       	mov    $0x400,%edx
80102bfd:	e8 87 ff ff ff       	call   80102b89 <mpsearch1>
80102c02:	85 c0                	test   %eax,%eax
80102c04:	75 0f                	jne    80102c15 <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102c06:	ba 00 00 01 00       	mov    $0x10000,%edx
80102c0b:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102c10:	e8 74 ff ff ff       	call   80102b89 <mpsearch1>
}
80102c15:	c9                   	leave  
80102c16:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102c17:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102c1e:	c1 e0 08             	shl    $0x8,%eax
80102c21:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102c28:	09 d0                	or     %edx,%eax
80102c2a:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102c2d:	2d 00 04 00 00       	sub    $0x400,%eax
80102c32:	ba 00 04 00 00       	mov    $0x400,%edx
80102c37:	e8 4d ff ff ff       	call   80102b89 <mpsearch1>
80102c3c:	85 c0                	test   %eax,%eax
80102c3e:	75 d5                	jne    80102c15 <mpsearch+0x3d>
80102c40:	eb c4                	jmp    80102c06 <mpsearch+0x2e>

80102c42 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102c42:	55                   	push   %ebp
80102c43:	89 e5                	mov    %esp,%ebp
80102c45:	57                   	push   %edi
80102c46:	56                   	push   %esi
80102c47:	53                   	push   %ebx
80102c48:	83 ec 1c             	sub    $0x1c,%esp
80102c4b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102c4e:	e8 85 ff ff ff       	call   80102bd8 <mpsearch>
80102c53:	85 c0                	test   %eax,%eax
80102c55:	74 5c                	je     80102cb3 <mpconfig+0x71>
80102c57:	89 c7                	mov    %eax,%edi
80102c59:	8b 58 04             	mov    0x4(%eax),%ebx
80102c5c:	85 db                	test   %ebx,%ebx
80102c5e:	74 5a                	je     80102cba <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102c60:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102c66:	83 ec 04             	sub    $0x4,%esp
80102c69:	6a 04                	push   $0x4
80102c6b:	68 9d 6a 10 80       	push   $0x80106a9d
80102c70:	56                   	push   %esi
80102c71:	e8 fa 10 00 00       	call   80103d70 <memcmp>
80102c76:	83 c4 10             	add    $0x10,%esp
80102c79:	85 c0                	test   %eax,%eax
80102c7b:	75 44                	jne    80102cc1 <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102c7d:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102c84:	3c 01                	cmp    $0x1,%al
80102c86:	0f 95 c2             	setne  %dl
80102c89:	3c 04                	cmp    $0x4,%al
80102c8b:	0f 95 c0             	setne  %al
80102c8e:	84 c2                	test   %al,%dl
80102c90:	75 36                	jne    80102cc8 <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102c92:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102c99:	89 f0                	mov    %esi,%eax
80102c9b:	e8 c5 fe ff ff       	call   80102b65 <sum>
80102ca0:	84 c0                	test   %al,%al
80102ca2:	75 2b                	jne    80102ccf <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102ca4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102ca7:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102ca9:	89 f0                	mov    %esi,%eax
80102cab:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102cae:	5b                   	pop    %ebx
80102caf:	5e                   	pop    %esi
80102cb0:	5f                   	pop    %edi
80102cb1:	5d                   	pop    %ebp
80102cb2:	c3                   	ret    
    return 0;
80102cb3:	be 00 00 00 00       	mov    $0x0,%esi
80102cb8:	eb ef                	jmp    80102ca9 <mpconfig+0x67>
80102cba:	be 00 00 00 00       	mov    $0x0,%esi
80102cbf:	eb e8                	jmp    80102ca9 <mpconfig+0x67>
    return 0;
80102cc1:	be 00 00 00 00       	mov    $0x0,%esi
80102cc6:	eb e1                	jmp    80102ca9 <mpconfig+0x67>
    return 0;
80102cc8:	be 00 00 00 00       	mov    $0x0,%esi
80102ccd:	eb da                	jmp    80102ca9 <mpconfig+0x67>
    return 0;
80102ccf:	be 00 00 00 00       	mov    $0x0,%esi
80102cd4:	eb d3                	jmp    80102ca9 <mpconfig+0x67>

80102cd6 <mpinit>:

void
mpinit(void)
{
80102cd6:	55                   	push   %ebp
80102cd7:	89 e5                	mov    %esp,%ebp
80102cd9:	57                   	push   %edi
80102cda:	56                   	push   %esi
80102cdb:	53                   	push   %ebx
80102cdc:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102cdf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102ce2:	e8 5b ff ff ff       	call   80102c42 <mpconfig>
80102ce7:	85 c0                	test   %eax,%eax
80102ce9:	74 19                	je     80102d04 <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102ceb:	8b 50 24             	mov    0x24(%eax),%edx
80102cee:	89 15 c4 16 13 80    	mov    %edx,0x801316c4
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102cf4:	8d 50 2c             	lea    0x2c(%eax),%edx
80102cf7:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102cfb:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102cfd:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d02:	eb 34                	jmp    80102d38 <mpinit+0x62>
    panic("Expect to run on an SMP");
80102d04:	83 ec 0c             	sub    $0xc,%esp
80102d07:	68 a2 6a 10 80       	push   $0x80106aa2
80102d0c:	e8 37 d6 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102d11:	8b 35 60 1d 13 80    	mov    0x80131d60,%esi
80102d17:	83 fe 07             	cmp    $0x7,%esi
80102d1a:	7f 19                	jg     80102d35 <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102d1c:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102d20:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102d26:	88 87 e0 17 13 80    	mov    %al,-0x7fece820(%edi)
        ncpu++;
80102d2c:	83 c6 01             	add    $0x1,%esi
80102d2f:	89 35 60 1d 13 80    	mov    %esi,0x80131d60
      }
      p += sizeof(struct mpproc);
80102d35:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102d38:	39 ca                	cmp    %ecx,%edx
80102d3a:	73 2b                	jae    80102d67 <mpinit+0x91>
    switch(*p){
80102d3c:	0f b6 02             	movzbl (%edx),%eax
80102d3f:	3c 04                	cmp    $0x4,%al
80102d41:	77 1d                	ja     80102d60 <mpinit+0x8a>
80102d43:	0f b6 c0             	movzbl %al,%eax
80102d46:	ff 24 85 dc 6a 10 80 	jmp    *-0x7fef9524(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102d4d:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102d51:	a2 c0 17 13 80       	mov    %al,0x801317c0
      p += sizeof(struct mpioapic);
80102d56:	83 c2 08             	add    $0x8,%edx
      continue;
80102d59:	eb dd                	jmp    80102d38 <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102d5b:	83 c2 08             	add    $0x8,%edx
      continue;
80102d5e:	eb d8                	jmp    80102d38 <mpinit+0x62>
    default:
      ismp = 0;
80102d60:	bb 00 00 00 00       	mov    $0x0,%ebx
80102d65:	eb d1                	jmp    80102d38 <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102d67:	85 db                	test   %ebx,%ebx
80102d69:	74 26                	je     80102d91 <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102d6b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102d6e:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102d72:	74 15                	je     80102d89 <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102d74:	b8 70 00 00 00       	mov    $0x70,%eax
80102d79:	ba 22 00 00 00       	mov    $0x22,%edx
80102d7e:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102d7f:	ba 23 00 00 00       	mov    $0x23,%edx
80102d84:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102d85:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102d88:	ee                   	out    %al,(%dx)
  }
}
80102d89:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102d8c:	5b                   	pop    %ebx
80102d8d:	5e                   	pop    %esi
80102d8e:	5f                   	pop    %edi
80102d8f:	5d                   	pop    %ebp
80102d90:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102d91:	83 ec 0c             	sub    $0xc,%esp
80102d94:	68 bc 6a 10 80       	push   $0x80106abc
80102d99:	e8 aa d5 ff ff       	call   80100348 <panic>

80102d9e <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102d9e:	55                   	push   %ebp
80102d9f:	89 e5                	mov    %esp,%ebp
80102da1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102da6:	ba 21 00 00 00       	mov    $0x21,%edx
80102dab:	ee                   	out    %al,(%dx)
80102dac:	ba a1 00 00 00       	mov    $0xa1,%edx
80102db1:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102db2:	5d                   	pop    %ebp
80102db3:	c3                   	ret    

80102db4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102db4:	55                   	push   %ebp
80102db5:	89 e5                	mov    %esp,%ebp
80102db7:	57                   	push   %edi
80102db8:	56                   	push   %esi
80102db9:	53                   	push   %ebx
80102dba:	83 ec 0c             	sub    $0xc,%esp
80102dbd:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102dc0:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102dc3:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102dc9:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102dcf:	e8 59 de ff ff       	call   80100c2d <filealloc>
80102dd4:	89 03                	mov    %eax,(%ebx)
80102dd6:	85 c0                	test   %eax,%eax
80102dd8:	74 1e                	je     80102df8 <pipealloc+0x44>
80102dda:	e8 4e de ff ff       	call   80100c2d <filealloc>
80102ddf:	89 06                	mov    %eax,(%esi)
80102de1:	85 c0                	test   %eax,%eax
80102de3:	74 13                	je     80102df8 <pipealloc+0x44>
    goto bad;
  if((p = (struct pipe*)kalloc2(-2)) == 0)
80102de5:	83 ec 0c             	sub    $0xc,%esp
80102de8:	6a fe                	push   $0xfffffffe
80102dea:	e8 21 f3 ff ff       	call   80102110 <kalloc2>
80102def:	89 c7                	mov    %eax,%edi
80102df1:	83 c4 10             	add    $0x10,%esp
80102df4:	85 c0                	test   %eax,%eax
80102df6:	75 35                	jne    80102e2d <pipealloc+0x79>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102df8:	8b 03                	mov    (%ebx),%eax
80102dfa:	85 c0                	test   %eax,%eax
80102dfc:	74 0c                	je     80102e0a <pipealloc+0x56>
    fileclose(*f0);
80102dfe:	83 ec 0c             	sub    $0xc,%esp
80102e01:	50                   	push   %eax
80102e02:	e8 cc de ff ff       	call   80100cd3 <fileclose>
80102e07:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102e0a:	8b 06                	mov    (%esi),%eax
80102e0c:	85 c0                	test   %eax,%eax
80102e0e:	0f 84 8b 00 00 00    	je     80102e9f <pipealloc+0xeb>
    fileclose(*f1);
80102e14:	83 ec 0c             	sub    $0xc,%esp
80102e17:	50                   	push   %eax
80102e18:	e8 b6 de ff ff       	call   80100cd3 <fileclose>
80102e1d:	83 c4 10             	add    $0x10,%esp
  return -1;
80102e20:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102e25:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102e28:	5b                   	pop    %ebx
80102e29:	5e                   	pop    %esi
80102e2a:	5f                   	pop    %edi
80102e2b:	5d                   	pop    %ebp
80102e2c:	c3                   	ret    
  p->readopen = 1;
80102e2d:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102e34:	00 00 00 
  p->writeopen = 1;
80102e37:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102e3e:	00 00 00 
  p->nwrite = 0;
80102e41:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102e48:	00 00 00 
  p->nread = 0;
80102e4b:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102e52:	00 00 00 
  initlock(&p->lock, "pipe");
80102e55:	83 ec 08             	sub    $0x8,%esp
80102e58:	68 f0 6a 10 80       	push   $0x80106af0
80102e5d:	50                   	push   %eax
80102e5e:	e8 df 0c 00 00       	call   80103b42 <initlock>
  (*f0)->type = FD_PIPE;
80102e63:	8b 03                	mov    (%ebx),%eax
80102e65:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102e6b:	8b 03                	mov    (%ebx),%eax
80102e6d:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102e71:	8b 03                	mov    (%ebx),%eax
80102e73:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102e77:	8b 03                	mov    (%ebx),%eax
80102e79:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80102e7c:	8b 06                	mov    (%esi),%eax
80102e7e:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80102e84:	8b 06                	mov    (%esi),%eax
80102e86:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80102e8a:	8b 06                	mov    (%esi),%eax
80102e8c:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80102e90:	8b 06                	mov    (%esi),%eax
80102e92:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80102e95:	83 c4 10             	add    $0x10,%esp
80102e98:	b8 00 00 00 00       	mov    $0x0,%eax
80102e9d:	eb 86                	jmp    80102e25 <pipealloc+0x71>
  return -1;
80102e9f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102ea4:	e9 7c ff ff ff       	jmp    80102e25 <pipealloc+0x71>

80102ea9 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80102ea9:	55                   	push   %ebp
80102eaa:	89 e5                	mov    %esp,%ebp
80102eac:	53                   	push   %ebx
80102ead:	83 ec 10             	sub    $0x10,%esp
80102eb0:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80102eb3:	53                   	push   %ebx
80102eb4:	e8 c5 0d 00 00       	call   80103c7e <acquire>
  if(writable){
80102eb9:	83 c4 10             	add    $0x10,%esp
80102ebc:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102ec0:	74 3f                	je     80102f01 <pipeclose+0x58>
    p->writeopen = 0;
80102ec2:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80102ec9:	00 00 00 
    wakeup(&p->nread);
80102ecc:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102ed2:	83 ec 0c             	sub    $0xc,%esp
80102ed5:	50                   	push   %eax
80102ed6:	e8 ab 09 00 00       	call   80103886 <wakeup>
80102edb:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80102ede:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102ee5:	75 09                	jne    80102ef0 <pipeclose+0x47>
80102ee7:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80102eee:	74 2f                	je     80102f1f <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80102ef0:	83 ec 0c             	sub    $0xc,%esp
80102ef3:	53                   	push   %ebx
80102ef4:	e8 ea 0d 00 00       	call   80103ce3 <release>
80102ef9:	83 c4 10             	add    $0x10,%esp
}
80102efc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102eff:	c9                   	leave  
80102f00:	c3                   	ret    
    p->readopen = 0;
80102f01:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
80102f08:	00 00 00 
    wakeup(&p->nwrite);
80102f0b:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102f11:	83 ec 0c             	sub    $0xc,%esp
80102f14:	50                   	push   %eax
80102f15:	e8 6c 09 00 00       	call   80103886 <wakeup>
80102f1a:	83 c4 10             	add    $0x10,%esp
80102f1d:	eb bf                	jmp    80102ede <pipeclose+0x35>
    release(&p->lock);
80102f1f:	83 ec 0c             	sub    $0xc,%esp
80102f22:	53                   	push   %ebx
80102f23:	e8 bb 0d 00 00       	call   80103ce3 <release>
    kfree((char*)p);
80102f28:	89 1c 24             	mov    %ebx,(%esp)
80102f2b:	e8 74 f0 ff ff       	call   80101fa4 <kfree>
80102f30:	83 c4 10             	add    $0x10,%esp
80102f33:	eb c7                	jmp    80102efc <pipeclose+0x53>

80102f35 <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
80102f35:	55                   	push   %ebp
80102f36:	89 e5                	mov    %esp,%ebp
80102f38:	57                   	push   %edi
80102f39:	56                   	push   %esi
80102f3a:	53                   	push   %ebx
80102f3b:	83 ec 18             	sub    $0x18,%esp
80102f3e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80102f41:	89 de                	mov    %ebx,%esi
80102f43:	53                   	push   %ebx
80102f44:	e8 35 0d 00 00       	call   80103c7e <acquire>
  for(i = 0; i < n; i++){
80102f49:	83 c4 10             	add    $0x10,%esp
80102f4c:	bf 00 00 00 00       	mov    $0x0,%edi
80102f51:	3b 7d 10             	cmp    0x10(%ebp),%edi
80102f54:	0f 8d 88 00 00 00    	jge    80102fe2 <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80102f5a:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
80102f60:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80102f66:	05 00 02 00 00       	add    $0x200,%eax
80102f6b:	39 c2                	cmp    %eax,%edx
80102f6d:	75 51                	jne    80102fc0 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
80102f6f:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102f76:	74 2f                	je     80102fa7 <pipewrite+0x72>
80102f78:	e8 00 03 00 00       	call   8010327d <myproc>
80102f7d:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80102f81:	75 24                	jne    80102fa7 <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
80102f83:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102f89:	83 ec 0c             	sub    $0xc,%esp
80102f8c:	50                   	push   %eax
80102f8d:	e8 f4 08 00 00       	call   80103886 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80102f92:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102f98:	83 c4 08             	add    $0x8,%esp
80102f9b:	56                   	push   %esi
80102f9c:	50                   	push   %eax
80102f9d:	e8 7f 07 00 00       	call   80103721 <sleep>
80102fa2:	83 c4 10             	add    $0x10,%esp
80102fa5:	eb b3                	jmp    80102f5a <pipewrite+0x25>
        release(&p->lock);
80102fa7:	83 ec 0c             	sub    $0xc,%esp
80102faa:	53                   	push   %ebx
80102fab:	e8 33 0d 00 00       	call   80103ce3 <release>
        return -1;
80102fb0:	83 c4 10             	add    $0x10,%esp
80102fb3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
80102fb8:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102fbb:	5b                   	pop    %ebx
80102fbc:	5e                   	pop    %esi
80102fbd:	5f                   	pop    %edi
80102fbe:	5d                   	pop    %ebp
80102fbf:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80102fc0:	8d 42 01             	lea    0x1(%edx),%eax
80102fc3:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80102fc9:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102fcf:	8b 45 0c             	mov    0xc(%ebp),%eax
80102fd2:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
80102fd6:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
80102fda:	83 c7 01             	add    $0x1,%edi
80102fdd:	e9 6f ff ff ff       	jmp    80102f51 <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80102fe2:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102fe8:	83 ec 0c             	sub    $0xc,%esp
80102feb:	50                   	push   %eax
80102fec:	e8 95 08 00 00       	call   80103886 <wakeup>
  release(&p->lock);
80102ff1:	89 1c 24             	mov    %ebx,(%esp)
80102ff4:	e8 ea 0c 00 00       	call   80103ce3 <release>
  return n;
80102ff9:	83 c4 10             	add    $0x10,%esp
80102ffc:	8b 45 10             	mov    0x10(%ebp),%eax
80102fff:	eb b7                	jmp    80102fb8 <pipewrite+0x83>

80103001 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80103001:	55                   	push   %ebp
80103002:	89 e5                	mov    %esp,%ebp
80103004:	57                   	push   %edi
80103005:	56                   	push   %esi
80103006:	53                   	push   %ebx
80103007:	83 ec 18             	sub    $0x18,%esp
8010300a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
8010300d:	89 df                	mov    %ebx,%edi
8010300f:	53                   	push   %ebx
80103010:	e8 69 0c 00 00       	call   80103c7e <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103015:	83 c4 10             	add    $0x10,%esp
80103018:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
8010301e:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
80103024:	75 3d                	jne    80103063 <piperead+0x62>
80103026:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
8010302c:	85 f6                	test   %esi,%esi
8010302e:	74 38                	je     80103068 <piperead+0x67>
    if(myproc()->killed){
80103030:	e8 48 02 00 00       	call   8010327d <myproc>
80103035:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80103039:	75 15                	jne    80103050 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010303b:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103041:	83 ec 08             	sub    $0x8,%esp
80103044:	57                   	push   %edi
80103045:	50                   	push   %eax
80103046:	e8 d6 06 00 00       	call   80103721 <sleep>
8010304b:	83 c4 10             	add    $0x10,%esp
8010304e:	eb c8                	jmp    80103018 <piperead+0x17>
      release(&p->lock);
80103050:	83 ec 0c             	sub    $0xc,%esp
80103053:	53                   	push   %ebx
80103054:	e8 8a 0c 00 00       	call   80103ce3 <release>
      return -1;
80103059:	83 c4 10             	add    $0x10,%esp
8010305c:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103061:	eb 50                	jmp    801030b3 <piperead+0xb2>
80103063:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103068:	3b 75 10             	cmp    0x10(%ebp),%esi
8010306b:	7d 2c                	jge    80103099 <piperead+0x98>
    if(p->nread == p->nwrite)
8010306d:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103073:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
80103079:	74 1e                	je     80103099 <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
8010307b:	8d 50 01             	lea    0x1(%eax),%edx
8010307e:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
80103084:	25 ff 01 00 00       	and    $0x1ff,%eax
80103089:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
8010308e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103091:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103094:	83 c6 01             	add    $0x1,%esi
80103097:	eb cf                	jmp    80103068 <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80103099:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
8010309f:	83 ec 0c             	sub    $0xc,%esp
801030a2:	50                   	push   %eax
801030a3:	e8 de 07 00 00       	call   80103886 <wakeup>
  release(&p->lock);
801030a8:	89 1c 24             	mov    %ebx,(%esp)
801030ab:	e8 33 0c 00 00       	call   80103ce3 <release>
  return i;
801030b0:	83 c4 10             	add    $0x10,%esp
}
801030b3:	89 f0                	mov    %esi,%eax
801030b5:	8d 65 f4             	lea    -0xc(%ebp),%esp
801030b8:	5b                   	pop    %ebx
801030b9:	5e                   	pop    %esi
801030ba:	5f                   	pop    %edi
801030bb:	5d                   	pop    %ebp
801030bc:	c3                   	ret    

801030bd <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
801030bd:	55                   	push   %ebp
801030be:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801030c0:	ba b4 1d 13 80       	mov    $0x80131db4,%edx
801030c5:	eb 03                	jmp    801030ca <wakeup1+0xd>
801030c7:	83 c2 7c             	add    $0x7c,%edx
801030ca:	81 fa b4 3c 13 80    	cmp    $0x80133cb4,%edx
801030d0:	73 14                	jae    801030e6 <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
801030d2:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
801030d6:	75 ef                	jne    801030c7 <wakeup1+0xa>
801030d8:	39 42 20             	cmp    %eax,0x20(%edx)
801030db:	75 ea                	jne    801030c7 <wakeup1+0xa>
      p->state = RUNNABLE;
801030dd:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
801030e4:	eb e1                	jmp    801030c7 <wakeup1+0xa>
}
801030e6:	5d                   	pop    %ebp
801030e7:	c3                   	ret    

801030e8 <allocproc>:
{
801030e8:	55                   	push   %ebp
801030e9:	89 e5                	mov    %esp,%ebp
801030eb:	53                   	push   %ebx
801030ec:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
801030ef:	68 80 1d 13 80       	push   $0x80131d80
801030f4:	e8 85 0b 00 00       	call   80103c7e <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801030f9:	83 c4 10             	add    $0x10,%esp
801030fc:	bb b4 1d 13 80       	mov    $0x80131db4,%ebx
80103101:	81 fb b4 3c 13 80    	cmp    $0x80133cb4,%ebx
80103107:	73 0b                	jae    80103114 <allocproc+0x2c>
    if(p->state == UNUSED)
80103109:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
8010310d:	74 1c                	je     8010312b <allocproc+0x43>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010310f:	83 c3 7c             	add    $0x7c,%ebx
80103112:	eb ed                	jmp    80103101 <allocproc+0x19>
  release(&ptable.lock);
80103114:	83 ec 0c             	sub    $0xc,%esp
80103117:	68 80 1d 13 80       	push   $0x80131d80
8010311c:	e8 c2 0b 00 00       	call   80103ce3 <release>
  return 0;
80103121:	83 c4 10             	add    $0x10,%esp
80103124:	bb 00 00 00 00       	mov    $0x0,%ebx
80103129:	eb 69                	jmp    80103194 <allocproc+0xac>
  p->state = EMBRYO;
8010312b:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
80103132:	a1 04 90 10 80       	mov    0x80109004,%eax
80103137:	8d 50 01             	lea    0x1(%eax),%edx
8010313a:	89 15 04 90 10 80    	mov    %edx,0x80109004
80103140:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
80103143:	83 ec 0c             	sub    $0xc,%esp
80103146:	68 80 1d 13 80       	push   $0x80131d80
8010314b:	e8 93 0b 00 00       	call   80103ce3 <release>
  if((p->kstack = kalloc()) == 0){
80103150:	e8 66 ef ff ff       	call   801020bb <kalloc>
80103155:	89 43 08             	mov    %eax,0x8(%ebx)
80103158:	83 c4 10             	add    $0x10,%esp
8010315b:	85 c0                	test   %eax,%eax
8010315d:	74 3c                	je     8010319b <allocproc+0xb3>
  sp -= sizeof *p->tf;
8010315f:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
80103165:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
80103168:	c7 80 b0 0f 00 00 40 	movl   $0x80104e40,0xfb0(%eax)
8010316f:	4e 10 80 
  sp -= sizeof *p->context;
80103172:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
80103177:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
8010317a:	83 ec 04             	sub    $0x4,%esp
8010317d:	6a 14                	push   $0x14
8010317f:	6a 00                	push   $0x0
80103181:	50                   	push   %eax
80103182:	e8 a3 0b 00 00       	call   80103d2a <memset>
  p->context->eip = (uint)forkret;
80103187:	8b 43 1c             	mov    0x1c(%ebx),%eax
8010318a:	c7 40 10 a9 31 10 80 	movl   $0x801031a9,0x10(%eax)
  return p;
80103191:	83 c4 10             	add    $0x10,%esp
}
80103194:	89 d8                	mov    %ebx,%eax
80103196:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103199:	c9                   	leave  
8010319a:	c3                   	ret    
    p->state = UNUSED;
8010319b:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
801031a2:	bb 00 00 00 00       	mov    $0x0,%ebx
801031a7:	eb eb                	jmp    80103194 <allocproc+0xac>

801031a9 <forkret>:
{
801031a9:	55                   	push   %ebp
801031aa:	89 e5                	mov    %esp,%ebp
801031ac:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
801031af:	68 80 1d 13 80       	push   $0x80131d80
801031b4:	e8 2a 0b 00 00       	call   80103ce3 <release>
  if (first) {
801031b9:	83 c4 10             	add    $0x10,%esp
801031bc:	83 3d 00 90 10 80 00 	cmpl   $0x0,0x80109000
801031c3:	75 02                	jne    801031c7 <forkret+0x1e>
}
801031c5:	c9                   	leave  
801031c6:	c3                   	ret    
    first = 0;
801031c7:	c7 05 00 90 10 80 00 	movl   $0x0,0x80109000
801031ce:	00 00 00 
    iinit(ROOTDEV);
801031d1:	83 ec 0c             	sub    $0xc,%esp
801031d4:	6a 01                	push   $0x1
801031d6:	e8 11 e1 ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
801031db:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801031e2:	e8 fd f5 ff ff       	call   801027e4 <initlog>
801031e7:	83 c4 10             	add    $0x10,%esp
}
801031ea:	eb d9                	jmp    801031c5 <forkret+0x1c>

801031ec <pinit>:
{
801031ec:	55                   	push   %ebp
801031ed:	89 e5                	mov    %esp,%ebp
801031ef:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
801031f2:	68 f5 6a 10 80       	push   $0x80106af5
801031f7:	68 80 1d 13 80       	push   $0x80131d80
801031fc:	e8 41 09 00 00       	call   80103b42 <initlock>
}
80103201:	83 c4 10             	add    $0x10,%esp
80103204:	c9                   	leave  
80103205:	c3                   	ret    

80103206 <mycpu>:
{
80103206:	55                   	push   %ebp
80103207:	89 e5                	mov    %esp,%ebp
80103209:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010320c:	9c                   	pushf  
8010320d:	58                   	pop    %eax
  if(readeflags()&FL_IF)
8010320e:	f6 c4 02             	test   $0x2,%ah
80103211:	75 28                	jne    8010323b <mycpu+0x35>
  apicid = lapicid();
80103213:	e8 e5 f1 ff ff       	call   801023fd <lapicid>
  for (i = 0; i < ncpu; ++i) {
80103218:	ba 00 00 00 00       	mov    $0x0,%edx
8010321d:	39 15 60 1d 13 80    	cmp    %edx,0x80131d60
80103223:	7e 23                	jle    80103248 <mycpu+0x42>
    if (cpus[i].apicid == apicid)
80103225:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
8010322b:	0f b6 89 e0 17 13 80 	movzbl -0x7fece820(%ecx),%ecx
80103232:	39 c1                	cmp    %eax,%ecx
80103234:	74 1f                	je     80103255 <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
80103236:	83 c2 01             	add    $0x1,%edx
80103239:	eb e2                	jmp    8010321d <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
8010323b:	83 ec 0c             	sub    $0xc,%esp
8010323e:	68 ec 6b 10 80       	push   $0x80106bec
80103243:	e8 00 d1 ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
80103248:	83 ec 0c             	sub    $0xc,%esp
8010324b:	68 fc 6a 10 80       	push   $0x80106afc
80103250:	e8 f3 d0 ff ff       	call   80100348 <panic>
      return &cpus[i];
80103255:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
8010325b:	05 e0 17 13 80       	add    $0x801317e0,%eax
}
80103260:	c9                   	leave  
80103261:	c3                   	ret    

80103262 <cpuid>:
cpuid() {
80103262:	55                   	push   %ebp
80103263:	89 e5                	mov    %esp,%ebp
80103265:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
80103268:	e8 99 ff ff ff       	call   80103206 <mycpu>
8010326d:	2d e0 17 13 80       	sub    $0x801317e0,%eax
80103272:	c1 f8 04             	sar    $0x4,%eax
80103275:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
8010327b:	c9                   	leave  
8010327c:	c3                   	ret    

8010327d <myproc>:
myproc(void) {
8010327d:	55                   	push   %ebp
8010327e:	89 e5                	mov    %esp,%ebp
80103280:	53                   	push   %ebx
80103281:	83 ec 04             	sub    $0x4,%esp
  pushcli();
80103284:	e8 18 09 00 00       	call   80103ba1 <pushcli>
  c = mycpu();
80103289:	e8 78 ff ff ff       	call   80103206 <mycpu>
  p = c->proc;
8010328e:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103294:	e8 45 09 00 00       	call   80103bde <popcli>
}
80103299:	89 d8                	mov    %ebx,%eax
8010329b:	83 c4 04             	add    $0x4,%esp
8010329e:	5b                   	pop    %ebx
8010329f:	5d                   	pop    %ebp
801032a0:	c3                   	ret    

801032a1 <userinit>:
{
801032a1:	55                   	push   %ebp
801032a2:	89 e5                	mov    %esp,%ebp
801032a4:	53                   	push   %ebx
801032a5:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
801032a8:	e8 3b fe ff ff       	call   801030e8 <allocproc>
801032ad:	89 c3                	mov    %eax,%ebx
  initproc = p;
801032af:	a3 bc 95 10 80       	mov    %eax,0x801095bc
  if((p->pgdir = setupkvm()) == 0)
801032b4:	e8 86 30 00 00       	call   8010633f <setupkvm>
801032b9:	89 43 04             	mov    %eax,0x4(%ebx)
801032bc:	85 c0                	test   %eax,%eax
801032be:	0f 84 b7 00 00 00    	je     8010337b <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
801032c4:	83 ec 04             	sub    $0x4,%esp
801032c7:	68 2c 00 00 00       	push   $0x2c
801032cc:	68 60 94 10 80       	push   $0x80109460
801032d1:	50                   	push   %eax
801032d2:	e8 60 2d 00 00       	call   80106037 <inituvm>
  p->sz = PGSIZE;
801032d7:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
801032dd:	83 c4 0c             	add    $0xc,%esp
801032e0:	6a 4c                	push   $0x4c
801032e2:	6a 00                	push   $0x0
801032e4:	ff 73 18             	pushl  0x18(%ebx)
801032e7:	e8 3e 0a 00 00       	call   80103d2a <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801032ec:	8b 43 18             	mov    0x18(%ebx),%eax
801032ef:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801032f5:	8b 43 18             	mov    0x18(%ebx),%eax
801032f8:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
801032fe:	8b 43 18             	mov    0x18(%ebx),%eax
80103301:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
80103305:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80103309:	8b 43 18             	mov    0x18(%ebx),%eax
8010330c:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
80103310:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80103314:	8b 43 18             	mov    0x18(%ebx),%eax
80103317:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
8010331e:	8b 43 18             	mov    0x18(%ebx),%eax
80103321:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80103328:	8b 43 18             	mov    0x18(%ebx),%eax
8010332b:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
80103332:	8d 43 6c             	lea    0x6c(%ebx),%eax
80103335:	83 c4 0c             	add    $0xc,%esp
80103338:	6a 10                	push   $0x10
8010333a:	68 25 6b 10 80       	push   $0x80106b25
8010333f:	50                   	push   %eax
80103340:	e8 4c 0b 00 00       	call   80103e91 <safestrcpy>
  p->cwd = namei("/");
80103345:	c7 04 24 2e 6b 10 80 	movl   $0x80106b2e,(%esp)
8010334c:	e8 90 e8 ff ff       	call   80101be1 <namei>
80103351:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
80103354:	c7 04 24 80 1d 13 80 	movl   $0x80131d80,(%esp)
8010335b:	e8 1e 09 00 00       	call   80103c7e <acquire>
  p->state = RUNNABLE;
80103360:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
80103367:	c7 04 24 80 1d 13 80 	movl   $0x80131d80,(%esp)
8010336e:	e8 70 09 00 00       	call   80103ce3 <release>
}
80103373:	83 c4 10             	add    $0x10,%esp
80103376:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103379:	c9                   	leave  
8010337a:	c3                   	ret    
    panic("userinit: out of memory?");
8010337b:	83 ec 0c             	sub    $0xc,%esp
8010337e:	68 0c 6b 10 80       	push   $0x80106b0c
80103383:	e8 c0 cf ff ff       	call   80100348 <panic>

80103388 <growproc>:
{
80103388:	55                   	push   %ebp
80103389:	89 e5                	mov    %esp,%ebp
8010338b:	56                   	push   %esi
8010338c:	53                   	push   %ebx
8010338d:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
80103390:	e8 e8 fe ff ff       	call   8010327d <myproc>
80103395:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
80103397:	8b 00                	mov    (%eax),%eax
  if(n > 0){
80103399:	85 f6                	test   %esi,%esi
8010339b:	7f 21                	jg     801033be <growproc+0x36>
  } else if(n < 0){
8010339d:	85 f6                	test   %esi,%esi
8010339f:	79 33                	jns    801033d4 <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
801033a1:	83 ec 04             	sub    $0x4,%esp
801033a4:	01 c6                	add    %eax,%esi
801033a6:	56                   	push   %esi
801033a7:	50                   	push   %eax
801033a8:	ff 73 04             	pushl  0x4(%ebx)
801033ab:	e8 95 2d 00 00       	call   80106145 <deallocuvm>
801033b0:	83 c4 10             	add    $0x10,%esp
801033b3:	85 c0                	test   %eax,%eax
801033b5:	75 1d                	jne    801033d4 <growproc+0x4c>
      return -1;
801033b7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801033bc:	eb 29                	jmp    801033e7 <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
801033be:	83 ec 04             	sub    $0x4,%esp
801033c1:	01 c6                	add    %eax,%esi
801033c3:	56                   	push   %esi
801033c4:	50                   	push   %eax
801033c5:	ff 73 04             	pushl  0x4(%ebx)
801033c8:	e8 0a 2e 00 00       	call   801061d7 <allocuvm>
801033cd:	83 c4 10             	add    $0x10,%esp
801033d0:	85 c0                	test   %eax,%eax
801033d2:	74 1a                	je     801033ee <growproc+0x66>
  curproc->sz = sz;
801033d4:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
801033d6:	83 ec 0c             	sub    $0xc,%esp
801033d9:	53                   	push   %ebx
801033da:	e8 40 2b 00 00       	call   80105f1f <switchuvm>
  return 0;
801033df:	83 c4 10             	add    $0x10,%esp
801033e2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801033e7:	8d 65 f8             	lea    -0x8(%ebp),%esp
801033ea:	5b                   	pop    %ebx
801033eb:	5e                   	pop    %esi
801033ec:	5d                   	pop    %ebp
801033ed:	c3                   	ret    
      return -1;
801033ee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801033f3:	eb f2                	jmp    801033e7 <growproc+0x5f>

801033f5 <fork>:
{
801033f5:	55                   	push   %ebp
801033f6:	89 e5                	mov    %esp,%ebp
801033f8:	57                   	push   %edi
801033f9:	56                   	push   %esi
801033fa:	53                   	push   %ebx
801033fb:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
801033fe:	e8 7a fe ff ff       	call   8010327d <myproc>
80103403:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
80103405:	e8 de fc ff ff       	call   801030e8 <allocproc>
8010340a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010340d:	85 c0                	test   %eax,%eax
8010340f:	0f 84 e0 00 00 00    	je     801034f5 <fork+0x100>
80103415:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){
80103417:	83 ec 08             	sub    $0x8,%esp
8010341a:	ff 33                	pushl  (%ebx)
8010341c:	ff 73 04             	pushl  0x4(%ebx)
8010341f:	e8 d4 2f 00 00       	call   801063f8 <copyuvm>
80103424:	89 47 04             	mov    %eax,0x4(%edi)
80103427:	83 c4 10             	add    $0x10,%esp
8010342a:	85 c0                	test   %eax,%eax
8010342c:	74 2a                	je     80103458 <fork+0x63>
  np->sz = curproc->sz;
8010342e:	8b 03                	mov    (%ebx),%eax
80103430:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80103433:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
80103435:	89 c8                	mov    %ecx,%eax
80103437:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
8010343a:	8b 73 18             	mov    0x18(%ebx),%esi
8010343d:	8b 79 18             	mov    0x18(%ecx),%edi
80103440:	b9 13 00 00 00       	mov    $0x13,%ecx
80103445:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
80103447:	8b 40 18             	mov    0x18(%eax),%eax
8010344a:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
80103451:	be 00 00 00 00       	mov    $0x0,%esi
80103456:	eb 29                	jmp    80103481 <fork+0x8c>
    kfree(np->kstack);
80103458:	83 ec 0c             	sub    $0xc,%esp
8010345b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
8010345e:	ff 73 08             	pushl  0x8(%ebx)
80103461:	e8 3e eb ff ff       	call   80101fa4 <kfree>
    np->kstack = 0;
80103466:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
8010346d:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
80103474:	83 c4 10             	add    $0x10,%esp
80103477:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010347c:	eb 6d                	jmp    801034eb <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
8010347e:	83 c6 01             	add    $0x1,%esi
80103481:	83 fe 0f             	cmp    $0xf,%esi
80103484:	7f 1d                	jg     801034a3 <fork+0xae>
    if(curproc->ofile[i])
80103486:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
8010348a:	85 c0                	test   %eax,%eax
8010348c:	74 f0                	je     8010347e <fork+0x89>
      np->ofile[i] = filedup(curproc->ofile[i]);
8010348e:	83 ec 0c             	sub    $0xc,%esp
80103491:	50                   	push   %eax
80103492:	e8 f7 d7 ff ff       	call   80100c8e <filedup>
80103497:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010349a:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
8010349e:	83 c4 10             	add    $0x10,%esp
801034a1:	eb db                	jmp    8010347e <fork+0x89>
  np->cwd = idup(curproc->cwd);
801034a3:	83 ec 0c             	sub    $0xc,%esp
801034a6:	ff 73 68             	pushl  0x68(%ebx)
801034a9:	e8 a3 e0 ff ff       	call   80101551 <idup>
801034ae:	8b 7d e4             	mov    -0x1c(%ebp),%edi
801034b1:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
801034b4:	83 c3 6c             	add    $0x6c,%ebx
801034b7:	8d 47 6c             	lea    0x6c(%edi),%eax
801034ba:	83 c4 0c             	add    $0xc,%esp
801034bd:	6a 10                	push   $0x10
801034bf:	53                   	push   %ebx
801034c0:	50                   	push   %eax
801034c1:	e8 cb 09 00 00       	call   80103e91 <safestrcpy>
  pid = np->pid;
801034c6:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
801034c9:	c7 04 24 80 1d 13 80 	movl   $0x80131d80,(%esp)
801034d0:	e8 a9 07 00 00       	call   80103c7e <acquire>
  np->state = RUNNABLE;
801034d5:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
801034dc:	c7 04 24 80 1d 13 80 	movl   $0x80131d80,(%esp)
801034e3:	e8 fb 07 00 00       	call   80103ce3 <release>
  return pid;
801034e8:	83 c4 10             	add    $0x10,%esp
}
801034eb:	89 d8                	mov    %ebx,%eax
801034ed:	8d 65 f4             	lea    -0xc(%ebp),%esp
801034f0:	5b                   	pop    %ebx
801034f1:	5e                   	pop    %esi
801034f2:	5f                   	pop    %edi
801034f3:	5d                   	pop    %ebp
801034f4:	c3                   	ret    
    return -1;
801034f5:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801034fa:	eb ef                	jmp    801034eb <fork+0xf6>

801034fc <scheduler>:
{
801034fc:	55                   	push   %ebp
801034fd:	89 e5                	mov    %esp,%ebp
801034ff:	56                   	push   %esi
80103500:	53                   	push   %ebx
  struct cpu *c = mycpu();
80103501:	e8 00 fd ff ff       	call   80103206 <mycpu>
80103506:	89 c6                	mov    %eax,%esi
  c->proc = 0;
80103508:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
8010350f:	00 00 00 
80103512:	eb 5a                	jmp    8010356e <scheduler+0x72>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103514:	83 c3 7c             	add    $0x7c,%ebx
80103517:	81 fb b4 3c 13 80    	cmp    $0x80133cb4,%ebx
8010351d:	73 3f                	jae    8010355e <scheduler+0x62>
      if(p->state != RUNNABLE)
8010351f:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
80103523:	75 ef                	jne    80103514 <scheduler+0x18>
      c->proc = p;
80103525:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
8010352b:	83 ec 0c             	sub    $0xc,%esp
8010352e:	53                   	push   %ebx
8010352f:	e8 eb 29 00 00       	call   80105f1f <switchuvm>
      p->state = RUNNING;
80103534:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
8010353b:	83 c4 08             	add    $0x8,%esp
8010353e:	ff 73 1c             	pushl  0x1c(%ebx)
80103541:	8d 46 04             	lea    0x4(%esi),%eax
80103544:	50                   	push   %eax
80103545:	e8 9a 09 00 00       	call   80103ee4 <swtch>
      switchkvm();
8010354a:	e8 be 29 00 00       	call   80105f0d <switchkvm>
      c->proc = 0;
8010354f:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
80103556:	00 00 00 
80103559:	83 c4 10             	add    $0x10,%esp
8010355c:	eb b6                	jmp    80103514 <scheduler+0x18>
    release(&ptable.lock);
8010355e:	83 ec 0c             	sub    $0xc,%esp
80103561:	68 80 1d 13 80       	push   $0x80131d80
80103566:	e8 78 07 00 00       	call   80103ce3 <release>
    sti();
8010356b:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
8010356e:	fb                   	sti    
    acquire(&ptable.lock);
8010356f:	83 ec 0c             	sub    $0xc,%esp
80103572:	68 80 1d 13 80       	push   $0x80131d80
80103577:	e8 02 07 00 00       	call   80103c7e <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010357c:	83 c4 10             	add    $0x10,%esp
8010357f:	bb b4 1d 13 80       	mov    $0x80131db4,%ebx
80103584:	eb 91                	jmp    80103517 <scheduler+0x1b>

80103586 <sched>:
{
80103586:	55                   	push   %ebp
80103587:	89 e5                	mov    %esp,%ebp
80103589:	56                   	push   %esi
8010358a:	53                   	push   %ebx
  struct proc *p = myproc();
8010358b:	e8 ed fc ff ff       	call   8010327d <myproc>
80103590:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
80103592:	83 ec 0c             	sub    $0xc,%esp
80103595:	68 80 1d 13 80       	push   $0x80131d80
8010359a:	e8 9f 06 00 00       	call   80103c3e <holding>
8010359f:	83 c4 10             	add    $0x10,%esp
801035a2:	85 c0                	test   %eax,%eax
801035a4:	74 4f                	je     801035f5 <sched+0x6f>
  if(mycpu()->ncli != 1)
801035a6:	e8 5b fc ff ff       	call   80103206 <mycpu>
801035ab:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
801035b2:	75 4e                	jne    80103602 <sched+0x7c>
  if(p->state == RUNNING)
801035b4:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
801035b8:	74 55                	je     8010360f <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801035ba:	9c                   	pushf  
801035bb:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801035bc:	f6 c4 02             	test   $0x2,%ah
801035bf:	75 5b                	jne    8010361c <sched+0x96>
  intena = mycpu()->intena;
801035c1:	e8 40 fc ff ff       	call   80103206 <mycpu>
801035c6:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
801035cc:	e8 35 fc ff ff       	call   80103206 <mycpu>
801035d1:	83 ec 08             	sub    $0x8,%esp
801035d4:	ff 70 04             	pushl  0x4(%eax)
801035d7:	83 c3 1c             	add    $0x1c,%ebx
801035da:	53                   	push   %ebx
801035db:	e8 04 09 00 00       	call   80103ee4 <swtch>
  mycpu()->intena = intena;
801035e0:	e8 21 fc ff ff       	call   80103206 <mycpu>
801035e5:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
801035eb:	83 c4 10             	add    $0x10,%esp
801035ee:	8d 65 f8             	lea    -0x8(%ebp),%esp
801035f1:	5b                   	pop    %ebx
801035f2:	5e                   	pop    %esi
801035f3:	5d                   	pop    %ebp
801035f4:	c3                   	ret    
    panic("sched ptable.lock");
801035f5:	83 ec 0c             	sub    $0xc,%esp
801035f8:	68 30 6b 10 80       	push   $0x80106b30
801035fd:	e8 46 cd ff ff       	call   80100348 <panic>
    panic("sched locks");
80103602:	83 ec 0c             	sub    $0xc,%esp
80103605:	68 42 6b 10 80       	push   $0x80106b42
8010360a:	e8 39 cd ff ff       	call   80100348 <panic>
    panic("sched running");
8010360f:	83 ec 0c             	sub    $0xc,%esp
80103612:	68 4e 6b 10 80       	push   $0x80106b4e
80103617:	e8 2c cd ff ff       	call   80100348 <panic>
    panic("sched interruptible");
8010361c:	83 ec 0c             	sub    $0xc,%esp
8010361f:	68 5c 6b 10 80       	push   $0x80106b5c
80103624:	e8 1f cd ff ff       	call   80100348 <panic>

80103629 <exit>:
{
80103629:	55                   	push   %ebp
8010362a:	89 e5                	mov    %esp,%ebp
8010362c:	56                   	push   %esi
8010362d:	53                   	push   %ebx
  struct proc *curproc = myproc();
8010362e:	e8 4a fc ff ff       	call   8010327d <myproc>
  if(curproc == initproc)
80103633:	39 05 bc 95 10 80    	cmp    %eax,0x801095bc
80103639:	74 09                	je     80103644 <exit+0x1b>
8010363b:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
8010363d:	bb 00 00 00 00       	mov    $0x0,%ebx
80103642:	eb 10                	jmp    80103654 <exit+0x2b>
    panic("init exiting");
80103644:	83 ec 0c             	sub    $0xc,%esp
80103647:	68 70 6b 10 80       	push   $0x80106b70
8010364c:	e8 f7 cc ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
80103651:	83 c3 01             	add    $0x1,%ebx
80103654:	83 fb 0f             	cmp    $0xf,%ebx
80103657:	7f 1e                	jg     80103677 <exit+0x4e>
    if(curproc->ofile[fd]){
80103659:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
8010365d:	85 c0                	test   %eax,%eax
8010365f:	74 f0                	je     80103651 <exit+0x28>
      fileclose(curproc->ofile[fd]);
80103661:	83 ec 0c             	sub    $0xc,%esp
80103664:	50                   	push   %eax
80103665:	e8 69 d6 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
8010366a:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
80103671:	00 
80103672:	83 c4 10             	add    $0x10,%esp
80103675:	eb da                	jmp    80103651 <exit+0x28>
  begin_op();
80103677:	e8 b1 f1 ff ff       	call   8010282d <begin_op>
  iput(curproc->cwd);
8010367c:	83 ec 0c             	sub    $0xc,%esp
8010367f:	ff 76 68             	pushl  0x68(%esi)
80103682:	e8 01 e0 ff ff       	call   80101688 <iput>
  end_op();
80103687:	e8 1b f2 ff ff       	call   801028a7 <end_op>
  curproc->cwd = 0;
8010368c:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
80103693:	c7 04 24 80 1d 13 80 	movl   $0x80131d80,(%esp)
8010369a:	e8 df 05 00 00       	call   80103c7e <acquire>
  wakeup1(curproc->parent);
8010369f:	8b 46 14             	mov    0x14(%esi),%eax
801036a2:	e8 16 fa ff ff       	call   801030bd <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801036a7:	83 c4 10             	add    $0x10,%esp
801036aa:	bb b4 1d 13 80       	mov    $0x80131db4,%ebx
801036af:	eb 03                	jmp    801036b4 <exit+0x8b>
801036b1:	83 c3 7c             	add    $0x7c,%ebx
801036b4:	81 fb b4 3c 13 80    	cmp    $0x80133cb4,%ebx
801036ba:	73 1a                	jae    801036d6 <exit+0xad>
    if(p->parent == curproc){
801036bc:	39 73 14             	cmp    %esi,0x14(%ebx)
801036bf:	75 f0                	jne    801036b1 <exit+0x88>
      p->parent = initproc;
801036c1:	a1 bc 95 10 80       	mov    0x801095bc,%eax
801036c6:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
801036c9:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
801036cd:	75 e2                	jne    801036b1 <exit+0x88>
        wakeup1(initproc);
801036cf:	e8 e9 f9 ff ff       	call   801030bd <wakeup1>
801036d4:	eb db                	jmp    801036b1 <exit+0x88>
  curproc->state = ZOMBIE;
801036d6:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
801036dd:	e8 a4 fe ff ff       	call   80103586 <sched>
  panic("zombie exit");
801036e2:	83 ec 0c             	sub    $0xc,%esp
801036e5:	68 7d 6b 10 80       	push   $0x80106b7d
801036ea:	e8 59 cc ff ff       	call   80100348 <panic>

801036ef <yield>:
{
801036ef:	55                   	push   %ebp
801036f0:	89 e5                	mov    %esp,%ebp
801036f2:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801036f5:	68 80 1d 13 80       	push   $0x80131d80
801036fa:	e8 7f 05 00 00       	call   80103c7e <acquire>
  myproc()->state = RUNNABLE;
801036ff:	e8 79 fb ff ff       	call   8010327d <myproc>
80103704:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
8010370b:	e8 76 fe ff ff       	call   80103586 <sched>
  release(&ptable.lock);
80103710:	c7 04 24 80 1d 13 80 	movl   $0x80131d80,(%esp)
80103717:	e8 c7 05 00 00       	call   80103ce3 <release>
}
8010371c:	83 c4 10             	add    $0x10,%esp
8010371f:	c9                   	leave  
80103720:	c3                   	ret    

80103721 <sleep>:
{
80103721:	55                   	push   %ebp
80103722:	89 e5                	mov    %esp,%ebp
80103724:	56                   	push   %esi
80103725:	53                   	push   %ebx
80103726:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
80103729:	e8 4f fb ff ff       	call   8010327d <myproc>
  if(p == 0)
8010372e:	85 c0                	test   %eax,%eax
80103730:	74 66                	je     80103798 <sleep+0x77>
80103732:	89 c6                	mov    %eax,%esi
  if(lk == 0)
80103734:	85 db                	test   %ebx,%ebx
80103736:	74 6d                	je     801037a5 <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
80103738:	81 fb 80 1d 13 80    	cmp    $0x80131d80,%ebx
8010373e:	74 18                	je     80103758 <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
80103740:	83 ec 0c             	sub    $0xc,%esp
80103743:	68 80 1d 13 80       	push   $0x80131d80
80103748:	e8 31 05 00 00       	call   80103c7e <acquire>
    release(lk);
8010374d:	89 1c 24             	mov    %ebx,(%esp)
80103750:	e8 8e 05 00 00       	call   80103ce3 <release>
80103755:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
80103758:	8b 45 08             	mov    0x8(%ebp),%eax
8010375b:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
8010375e:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
80103765:	e8 1c fe ff ff       	call   80103586 <sched>
  p->chan = 0;
8010376a:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
80103771:	81 fb 80 1d 13 80    	cmp    $0x80131d80,%ebx
80103777:	74 18                	je     80103791 <sleep+0x70>
    release(&ptable.lock);
80103779:	83 ec 0c             	sub    $0xc,%esp
8010377c:	68 80 1d 13 80       	push   $0x80131d80
80103781:	e8 5d 05 00 00       	call   80103ce3 <release>
    acquire(lk);
80103786:	89 1c 24             	mov    %ebx,(%esp)
80103789:	e8 f0 04 00 00       	call   80103c7e <acquire>
8010378e:	83 c4 10             	add    $0x10,%esp
}
80103791:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103794:	5b                   	pop    %ebx
80103795:	5e                   	pop    %esi
80103796:	5d                   	pop    %ebp
80103797:	c3                   	ret    
    panic("sleep");
80103798:	83 ec 0c             	sub    $0xc,%esp
8010379b:	68 89 6b 10 80       	push   $0x80106b89
801037a0:	e8 a3 cb ff ff       	call   80100348 <panic>
    panic("sleep without lk");
801037a5:	83 ec 0c             	sub    $0xc,%esp
801037a8:	68 8f 6b 10 80       	push   $0x80106b8f
801037ad:	e8 96 cb ff ff       	call   80100348 <panic>

801037b2 <wait>:
{
801037b2:	55                   	push   %ebp
801037b3:	89 e5                	mov    %esp,%ebp
801037b5:	56                   	push   %esi
801037b6:	53                   	push   %ebx
  struct proc *curproc = myproc();
801037b7:	e8 c1 fa ff ff       	call   8010327d <myproc>
801037bc:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
801037be:	83 ec 0c             	sub    $0xc,%esp
801037c1:	68 80 1d 13 80       	push   $0x80131d80
801037c6:	e8 b3 04 00 00       	call   80103c7e <acquire>
801037cb:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
801037ce:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801037d3:	bb b4 1d 13 80       	mov    $0x80131db4,%ebx
801037d8:	eb 5b                	jmp    80103835 <wait+0x83>
        pid = p->pid;
801037da:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
801037dd:	83 ec 0c             	sub    $0xc,%esp
801037e0:	ff 73 08             	pushl  0x8(%ebx)
801037e3:	e8 bc e7 ff ff       	call   80101fa4 <kfree>
        p->kstack = 0;
801037e8:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
801037ef:	83 c4 04             	add    $0x4,%esp
801037f2:	ff 73 04             	pushl  0x4(%ebx)
801037f5:	e8 d5 2a 00 00       	call   801062cf <freevm>
        p->pid = 0;
801037fa:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
80103801:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
80103808:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
8010380c:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
80103813:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
8010381a:	c7 04 24 80 1d 13 80 	movl   $0x80131d80,(%esp)
80103821:	e8 bd 04 00 00       	call   80103ce3 <release>
        return pid;
80103826:	83 c4 10             	add    $0x10,%esp
}
80103829:	89 f0                	mov    %esi,%eax
8010382b:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010382e:	5b                   	pop    %ebx
8010382f:	5e                   	pop    %esi
80103830:	5d                   	pop    %ebp
80103831:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103832:	83 c3 7c             	add    $0x7c,%ebx
80103835:	81 fb b4 3c 13 80    	cmp    $0x80133cb4,%ebx
8010383b:	73 12                	jae    8010384f <wait+0x9d>
      if(p->parent != curproc)
8010383d:	39 73 14             	cmp    %esi,0x14(%ebx)
80103840:	75 f0                	jne    80103832 <wait+0x80>
      if(p->state == ZOMBIE){
80103842:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103846:	74 92                	je     801037da <wait+0x28>
      havekids = 1;
80103848:	b8 01 00 00 00       	mov    $0x1,%eax
8010384d:	eb e3                	jmp    80103832 <wait+0x80>
    if(!havekids || curproc->killed){
8010384f:	85 c0                	test   %eax,%eax
80103851:	74 06                	je     80103859 <wait+0xa7>
80103853:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
80103857:	74 17                	je     80103870 <wait+0xbe>
      release(&ptable.lock);
80103859:	83 ec 0c             	sub    $0xc,%esp
8010385c:	68 80 1d 13 80       	push   $0x80131d80
80103861:	e8 7d 04 00 00       	call   80103ce3 <release>
      return -1;
80103866:	83 c4 10             	add    $0x10,%esp
80103869:	be ff ff ff ff       	mov    $0xffffffff,%esi
8010386e:	eb b9                	jmp    80103829 <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80103870:	83 ec 08             	sub    $0x8,%esp
80103873:	68 80 1d 13 80       	push   $0x80131d80
80103878:	56                   	push   %esi
80103879:	e8 a3 fe ff ff       	call   80103721 <sleep>
    havekids = 0;
8010387e:	83 c4 10             	add    $0x10,%esp
80103881:	e9 48 ff ff ff       	jmp    801037ce <wait+0x1c>

80103886 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80103886:	55                   	push   %ebp
80103887:	89 e5                	mov    %esp,%ebp
80103889:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
8010388c:	68 80 1d 13 80       	push   $0x80131d80
80103891:	e8 e8 03 00 00       	call   80103c7e <acquire>
  wakeup1(chan);
80103896:	8b 45 08             	mov    0x8(%ebp),%eax
80103899:	e8 1f f8 ff ff       	call   801030bd <wakeup1>
  release(&ptable.lock);
8010389e:	c7 04 24 80 1d 13 80 	movl   $0x80131d80,(%esp)
801038a5:	e8 39 04 00 00       	call   80103ce3 <release>
}
801038aa:	83 c4 10             	add    $0x10,%esp
801038ad:	c9                   	leave  
801038ae:	c3                   	ret    

801038af <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
801038af:	55                   	push   %ebp
801038b0:	89 e5                	mov    %esp,%ebp
801038b2:	53                   	push   %ebx
801038b3:	83 ec 10             	sub    $0x10,%esp
801038b6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
801038b9:	68 80 1d 13 80       	push   $0x80131d80
801038be:	e8 bb 03 00 00       	call   80103c7e <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801038c3:	83 c4 10             	add    $0x10,%esp
801038c6:	b8 b4 1d 13 80       	mov    $0x80131db4,%eax
801038cb:	3d b4 3c 13 80       	cmp    $0x80133cb4,%eax
801038d0:	73 3a                	jae    8010390c <kill+0x5d>
    if(p->pid == pid){
801038d2:	39 58 10             	cmp    %ebx,0x10(%eax)
801038d5:	74 05                	je     801038dc <kill+0x2d>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801038d7:	83 c0 7c             	add    $0x7c,%eax
801038da:	eb ef                	jmp    801038cb <kill+0x1c>
      p->killed = 1;
801038dc:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
801038e3:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
801038e7:	74 1a                	je     80103903 <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
801038e9:	83 ec 0c             	sub    $0xc,%esp
801038ec:	68 80 1d 13 80       	push   $0x80131d80
801038f1:	e8 ed 03 00 00       	call   80103ce3 <release>
      return 0;
801038f6:	83 c4 10             	add    $0x10,%esp
801038f9:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
801038fe:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103901:	c9                   	leave  
80103902:	c3                   	ret    
        p->state = RUNNABLE;
80103903:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
8010390a:	eb dd                	jmp    801038e9 <kill+0x3a>
  release(&ptable.lock);
8010390c:	83 ec 0c             	sub    $0xc,%esp
8010390f:	68 80 1d 13 80       	push   $0x80131d80
80103914:	e8 ca 03 00 00       	call   80103ce3 <release>
  return -1;
80103919:	83 c4 10             	add    $0x10,%esp
8010391c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103921:	eb db                	jmp    801038fe <kill+0x4f>

80103923 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80103923:	55                   	push   %ebp
80103924:	89 e5                	mov    %esp,%ebp
80103926:	56                   	push   %esi
80103927:	53                   	push   %ebx
80103928:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010392b:	bb b4 1d 13 80       	mov    $0x80131db4,%ebx
80103930:	eb 33                	jmp    80103965 <procdump+0x42>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103932:	b8 a0 6b 10 80       	mov    $0x80106ba0,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
80103937:	8d 53 6c             	lea    0x6c(%ebx),%edx
8010393a:	52                   	push   %edx
8010393b:	50                   	push   %eax
8010393c:	ff 73 10             	pushl  0x10(%ebx)
8010393f:	68 a4 6b 10 80       	push   $0x80106ba4
80103944:	e8 c2 cc ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
80103949:	83 c4 10             	add    $0x10,%esp
8010394c:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103950:	74 39                	je     8010398b <procdump+0x68>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103952:	83 ec 0c             	sub    $0xc,%esp
80103955:	68 3b 6f 10 80       	push   $0x80106f3b
8010395a:	e8 ac cc ff ff       	call   8010060b <cprintf>
8010395f:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103962:	83 c3 7c             	add    $0x7c,%ebx
80103965:	81 fb b4 3c 13 80    	cmp    $0x80133cb4,%ebx
8010396b:	73 61                	jae    801039ce <procdump+0xab>
    if(p->state == UNUSED)
8010396d:	8b 43 0c             	mov    0xc(%ebx),%eax
80103970:	85 c0                	test   %eax,%eax
80103972:	74 ee                	je     80103962 <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103974:	83 f8 05             	cmp    $0x5,%eax
80103977:	77 b9                	ja     80103932 <procdump+0xf>
80103979:	8b 04 85 14 6c 10 80 	mov    -0x7fef93ec(,%eax,4),%eax
80103980:	85 c0                	test   %eax,%eax
80103982:	75 b3                	jne    80103937 <procdump+0x14>
      state = "???";
80103984:	b8 a0 6b 10 80       	mov    $0x80106ba0,%eax
80103989:	eb ac                	jmp    80103937 <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
8010398b:	8b 43 1c             	mov    0x1c(%ebx),%eax
8010398e:	8b 40 0c             	mov    0xc(%eax),%eax
80103991:	83 c0 08             	add    $0x8,%eax
80103994:	83 ec 08             	sub    $0x8,%esp
80103997:	8d 55 d0             	lea    -0x30(%ebp),%edx
8010399a:	52                   	push   %edx
8010399b:	50                   	push   %eax
8010399c:	e8 bc 01 00 00       	call   80103b5d <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
801039a1:	83 c4 10             	add    $0x10,%esp
801039a4:	be 00 00 00 00       	mov    $0x0,%esi
801039a9:	eb 14                	jmp    801039bf <procdump+0x9c>
        cprintf(" %p", pc[i]);
801039ab:	83 ec 08             	sub    $0x8,%esp
801039ae:	50                   	push   %eax
801039af:	68 e1 65 10 80       	push   $0x801065e1
801039b4:	e8 52 cc ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
801039b9:	83 c6 01             	add    $0x1,%esi
801039bc:	83 c4 10             	add    $0x10,%esp
801039bf:	83 fe 09             	cmp    $0x9,%esi
801039c2:	7f 8e                	jg     80103952 <procdump+0x2f>
801039c4:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
801039c8:	85 c0                	test   %eax,%eax
801039ca:	75 df                	jne    801039ab <procdump+0x88>
801039cc:	eb 84                	jmp    80103952 <procdump+0x2f>
  }
}
801039ce:	8d 65 f8             	lea    -0x8(%ebp),%esp
801039d1:	5b                   	pop    %ebx
801039d2:	5e                   	pop    %esi
801039d3:	5d                   	pop    %ebp
801039d4:	c3                   	ret    

801039d5 <dump_physmem>:

int
dump_physmem(int *frames, int *pids, int numframes)
{
801039d5:	55                   	push   %ebp
801039d6:	89 e5                	mov    %esp,%ebp
801039d8:	57                   	push   %edi
801039d9:	56                   	push   %esi
801039da:	53                   	push   %ebx
801039db:	83 ec 0c             	sub    $0xc,%esp
801039de:	8b 75 08             	mov    0x8(%ebp),%esi
801039e1:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if(frames == 0 || pids == 0){
801039e4:	85 f6                	test   %esi,%esi
801039e6:	0f 94 c2             	sete   %dl
801039e9:	85 ff                	test   %edi,%edi
801039eb:	0f 94 c0             	sete   %al
801039ee:	08 c2                	or     %al,%dl
801039f0:	75 3e                	jne    80103a30 <dump_physmem+0x5b>
    return -1;
  }
  for (int i = 0; i < numframes - 1; i++) {
801039f2:	bb 00 00 00 00       	mov    $0x0,%ebx
801039f7:	eb 20                	jmp    80103a19 <dump_physmem+0x44>
    cprintf("frame: %x; pid: %d\n", frames[i], pids[i]);
801039f9:	8d 04 9d 00 00 00 00 	lea    0x0(,%ebx,4),%eax
80103a00:	83 ec 04             	sub    $0x4,%esp
80103a03:	ff 34 07             	pushl  (%edi,%eax,1)
80103a06:	ff 34 06             	pushl  (%esi,%eax,1)
80103a09:	68 ad 6b 10 80       	push   $0x80106bad
80103a0e:	e8 f8 cb ff ff       	call   8010060b <cprintf>
  for (int i = 0; i < numframes - 1; i++) {
80103a13:	83 c3 01             	add    $0x1,%ebx
80103a16:	83 c4 10             	add    $0x10,%esp
80103a19:	8b 45 10             	mov    0x10(%ebp),%eax
80103a1c:	83 e8 01             	sub    $0x1,%eax
80103a1f:	39 d8                	cmp    %ebx,%eax
80103a21:	7f d6                	jg     801039f9 <dump_physmem+0x24>
  }
  return 0;
80103a23:	b8 00 00 00 00       	mov    $0x0,%eax
80103a28:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103a2b:	5b                   	pop    %ebx
80103a2c:	5e                   	pop    %esi
80103a2d:	5f                   	pop    %edi
80103a2e:	5d                   	pop    %ebp
80103a2f:	c3                   	ret    
    return -1;
80103a30:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103a35:	eb f1                	jmp    80103a28 <dump_physmem+0x53>

80103a37 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103a37:	55                   	push   %ebp
80103a38:	89 e5                	mov    %esp,%ebp
80103a3a:	53                   	push   %ebx
80103a3b:	83 ec 0c             	sub    $0xc,%esp
80103a3e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103a41:	68 2c 6c 10 80       	push   $0x80106c2c
80103a46:	8d 43 04             	lea    0x4(%ebx),%eax
80103a49:	50                   	push   %eax
80103a4a:	e8 f3 00 00 00       	call   80103b42 <initlock>
  lk->name = name;
80103a4f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103a52:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103a55:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103a5b:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103a62:	83 c4 10             	add    $0x10,%esp
80103a65:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103a68:	c9                   	leave  
80103a69:	c3                   	ret    

80103a6a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103a6a:	55                   	push   %ebp
80103a6b:	89 e5                	mov    %esp,%ebp
80103a6d:	56                   	push   %esi
80103a6e:	53                   	push   %ebx
80103a6f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103a72:	8d 73 04             	lea    0x4(%ebx),%esi
80103a75:	83 ec 0c             	sub    $0xc,%esp
80103a78:	56                   	push   %esi
80103a79:	e8 00 02 00 00       	call   80103c7e <acquire>
  while (lk->locked) {
80103a7e:	83 c4 10             	add    $0x10,%esp
80103a81:	eb 0d                	jmp    80103a90 <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103a83:	83 ec 08             	sub    $0x8,%esp
80103a86:	56                   	push   %esi
80103a87:	53                   	push   %ebx
80103a88:	e8 94 fc ff ff       	call   80103721 <sleep>
80103a8d:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103a90:	83 3b 00             	cmpl   $0x0,(%ebx)
80103a93:	75 ee                	jne    80103a83 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103a95:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103a9b:	e8 dd f7 ff ff       	call   8010327d <myproc>
80103aa0:	8b 40 10             	mov    0x10(%eax),%eax
80103aa3:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103aa6:	83 ec 0c             	sub    $0xc,%esp
80103aa9:	56                   	push   %esi
80103aaa:	e8 34 02 00 00       	call   80103ce3 <release>
}
80103aaf:	83 c4 10             	add    $0x10,%esp
80103ab2:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103ab5:	5b                   	pop    %ebx
80103ab6:	5e                   	pop    %esi
80103ab7:	5d                   	pop    %ebp
80103ab8:	c3                   	ret    

80103ab9 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103ab9:	55                   	push   %ebp
80103aba:	89 e5                	mov    %esp,%ebp
80103abc:	56                   	push   %esi
80103abd:	53                   	push   %ebx
80103abe:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103ac1:	8d 73 04             	lea    0x4(%ebx),%esi
80103ac4:	83 ec 0c             	sub    $0xc,%esp
80103ac7:	56                   	push   %esi
80103ac8:	e8 b1 01 00 00       	call   80103c7e <acquire>
  lk->locked = 0;
80103acd:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103ad3:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103ada:	89 1c 24             	mov    %ebx,(%esp)
80103add:	e8 a4 fd ff ff       	call   80103886 <wakeup>
  release(&lk->lk);
80103ae2:	89 34 24             	mov    %esi,(%esp)
80103ae5:	e8 f9 01 00 00       	call   80103ce3 <release>
}
80103aea:	83 c4 10             	add    $0x10,%esp
80103aed:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103af0:	5b                   	pop    %ebx
80103af1:	5e                   	pop    %esi
80103af2:	5d                   	pop    %ebp
80103af3:	c3                   	ret    

80103af4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103af4:	55                   	push   %ebp
80103af5:	89 e5                	mov    %esp,%ebp
80103af7:	56                   	push   %esi
80103af8:	53                   	push   %ebx
80103af9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103afc:	8d 73 04             	lea    0x4(%ebx),%esi
80103aff:	83 ec 0c             	sub    $0xc,%esp
80103b02:	56                   	push   %esi
80103b03:	e8 76 01 00 00       	call   80103c7e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103b08:	83 c4 10             	add    $0x10,%esp
80103b0b:	83 3b 00             	cmpl   $0x0,(%ebx)
80103b0e:	75 17                	jne    80103b27 <holdingsleep+0x33>
80103b10:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103b15:	83 ec 0c             	sub    $0xc,%esp
80103b18:	56                   	push   %esi
80103b19:	e8 c5 01 00 00       	call   80103ce3 <release>
  return r;
}
80103b1e:	89 d8                	mov    %ebx,%eax
80103b20:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b23:	5b                   	pop    %ebx
80103b24:	5e                   	pop    %esi
80103b25:	5d                   	pop    %ebp
80103b26:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103b27:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103b2a:	e8 4e f7 ff ff       	call   8010327d <myproc>
80103b2f:	3b 58 10             	cmp    0x10(%eax),%ebx
80103b32:	74 07                	je     80103b3b <holdingsleep+0x47>
80103b34:	bb 00 00 00 00       	mov    $0x0,%ebx
80103b39:	eb da                	jmp    80103b15 <holdingsleep+0x21>
80103b3b:	bb 01 00 00 00       	mov    $0x1,%ebx
80103b40:	eb d3                	jmp    80103b15 <holdingsleep+0x21>

80103b42 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103b42:	55                   	push   %ebp
80103b43:	89 e5                	mov    %esp,%ebp
80103b45:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103b48:	8b 55 0c             	mov    0xc(%ebp),%edx
80103b4b:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103b4e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103b54:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103b5b:	5d                   	pop    %ebp
80103b5c:	c3                   	ret    

80103b5d <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103b5d:	55                   	push   %ebp
80103b5e:	89 e5                	mov    %esp,%ebp
80103b60:	53                   	push   %ebx
80103b61:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103b64:	8b 45 08             	mov    0x8(%ebp),%eax
80103b67:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103b6a:	b8 00 00 00 00       	mov    $0x0,%eax
80103b6f:	83 f8 09             	cmp    $0x9,%eax
80103b72:	7f 25                	jg     80103b99 <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103b74:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103b7a:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103b80:	77 17                	ja     80103b99 <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103b82:	8b 5a 04             	mov    0x4(%edx),%ebx
80103b85:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103b88:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103b8a:	83 c0 01             	add    $0x1,%eax
80103b8d:	eb e0                	jmp    80103b6f <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103b8f:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103b96:	83 c0 01             	add    $0x1,%eax
80103b99:	83 f8 09             	cmp    $0x9,%eax
80103b9c:	7e f1                	jle    80103b8f <getcallerpcs+0x32>
}
80103b9e:	5b                   	pop    %ebx
80103b9f:	5d                   	pop    %ebp
80103ba0:	c3                   	ret    

80103ba1 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103ba1:	55                   	push   %ebp
80103ba2:	89 e5                	mov    %esp,%ebp
80103ba4:	53                   	push   %ebx
80103ba5:	83 ec 04             	sub    $0x4,%esp
80103ba8:	9c                   	pushf  
80103ba9:	5b                   	pop    %ebx
  asm volatile("cli");
80103baa:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103bab:	e8 56 f6 ff ff       	call   80103206 <mycpu>
80103bb0:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103bb7:	74 12                	je     80103bcb <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103bb9:	e8 48 f6 ff ff       	call   80103206 <mycpu>
80103bbe:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103bc5:	83 c4 04             	add    $0x4,%esp
80103bc8:	5b                   	pop    %ebx
80103bc9:	5d                   	pop    %ebp
80103bca:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103bcb:	e8 36 f6 ff ff       	call   80103206 <mycpu>
80103bd0:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103bd6:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103bdc:	eb db                	jmp    80103bb9 <pushcli+0x18>

80103bde <popcli>:

void
popcli(void)
{
80103bde:	55                   	push   %ebp
80103bdf:	89 e5                	mov    %esp,%ebp
80103be1:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103be4:	9c                   	pushf  
80103be5:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103be6:	f6 c4 02             	test   $0x2,%ah
80103be9:	75 28                	jne    80103c13 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103beb:	e8 16 f6 ff ff       	call   80103206 <mycpu>
80103bf0:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103bf6:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103bf9:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103bff:	85 d2                	test   %edx,%edx
80103c01:	78 1d                	js     80103c20 <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103c03:	e8 fe f5 ff ff       	call   80103206 <mycpu>
80103c08:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103c0f:	74 1c                	je     80103c2d <popcli+0x4f>
    sti();
}
80103c11:	c9                   	leave  
80103c12:	c3                   	ret    
    panic("popcli - interruptible");
80103c13:	83 ec 0c             	sub    $0xc,%esp
80103c16:	68 37 6c 10 80       	push   $0x80106c37
80103c1b:	e8 28 c7 ff ff       	call   80100348 <panic>
    panic("popcli");
80103c20:	83 ec 0c             	sub    $0xc,%esp
80103c23:	68 4e 6c 10 80       	push   $0x80106c4e
80103c28:	e8 1b c7 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103c2d:	e8 d4 f5 ff ff       	call   80103206 <mycpu>
80103c32:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103c39:	74 d6                	je     80103c11 <popcli+0x33>
  asm volatile("sti");
80103c3b:	fb                   	sti    
}
80103c3c:	eb d3                	jmp    80103c11 <popcli+0x33>

80103c3e <holding>:
{
80103c3e:	55                   	push   %ebp
80103c3f:	89 e5                	mov    %esp,%ebp
80103c41:	53                   	push   %ebx
80103c42:	83 ec 04             	sub    $0x4,%esp
80103c45:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103c48:	e8 54 ff ff ff       	call   80103ba1 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103c4d:	83 3b 00             	cmpl   $0x0,(%ebx)
80103c50:	75 12                	jne    80103c64 <holding+0x26>
80103c52:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103c57:	e8 82 ff ff ff       	call   80103bde <popcli>
}
80103c5c:	89 d8                	mov    %ebx,%eax
80103c5e:	83 c4 04             	add    $0x4,%esp
80103c61:	5b                   	pop    %ebx
80103c62:	5d                   	pop    %ebp
80103c63:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103c64:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103c67:	e8 9a f5 ff ff       	call   80103206 <mycpu>
80103c6c:	39 c3                	cmp    %eax,%ebx
80103c6e:	74 07                	je     80103c77 <holding+0x39>
80103c70:	bb 00 00 00 00       	mov    $0x0,%ebx
80103c75:	eb e0                	jmp    80103c57 <holding+0x19>
80103c77:	bb 01 00 00 00       	mov    $0x1,%ebx
80103c7c:	eb d9                	jmp    80103c57 <holding+0x19>

80103c7e <acquire>:
{
80103c7e:	55                   	push   %ebp
80103c7f:	89 e5                	mov    %esp,%ebp
80103c81:	53                   	push   %ebx
80103c82:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103c85:	e8 17 ff ff ff       	call   80103ba1 <pushcli>
  if(holding(lk))
80103c8a:	83 ec 0c             	sub    $0xc,%esp
80103c8d:	ff 75 08             	pushl  0x8(%ebp)
80103c90:	e8 a9 ff ff ff       	call   80103c3e <holding>
80103c95:	83 c4 10             	add    $0x10,%esp
80103c98:	85 c0                	test   %eax,%eax
80103c9a:	75 3a                	jne    80103cd6 <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103c9c:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103c9f:	b8 01 00 00 00       	mov    $0x1,%eax
80103ca4:	f0 87 02             	lock xchg %eax,(%edx)
80103ca7:	85 c0                	test   %eax,%eax
80103ca9:	75 f1                	jne    80103c9c <acquire+0x1e>
  __sync_synchronize();
80103cab:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103cb0:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103cb3:	e8 4e f5 ff ff       	call   80103206 <mycpu>
80103cb8:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103cbb:	8b 45 08             	mov    0x8(%ebp),%eax
80103cbe:	83 c0 0c             	add    $0xc,%eax
80103cc1:	83 ec 08             	sub    $0x8,%esp
80103cc4:	50                   	push   %eax
80103cc5:	8d 45 08             	lea    0x8(%ebp),%eax
80103cc8:	50                   	push   %eax
80103cc9:	e8 8f fe ff ff       	call   80103b5d <getcallerpcs>
}
80103cce:	83 c4 10             	add    $0x10,%esp
80103cd1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103cd4:	c9                   	leave  
80103cd5:	c3                   	ret    
    panic("acquire");
80103cd6:	83 ec 0c             	sub    $0xc,%esp
80103cd9:	68 55 6c 10 80       	push   $0x80106c55
80103cde:	e8 65 c6 ff ff       	call   80100348 <panic>

80103ce3 <release>:
{
80103ce3:	55                   	push   %ebp
80103ce4:	89 e5                	mov    %esp,%ebp
80103ce6:	53                   	push   %ebx
80103ce7:	83 ec 10             	sub    $0x10,%esp
80103cea:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103ced:	53                   	push   %ebx
80103cee:	e8 4b ff ff ff       	call   80103c3e <holding>
80103cf3:	83 c4 10             	add    $0x10,%esp
80103cf6:	85 c0                	test   %eax,%eax
80103cf8:	74 23                	je     80103d1d <release+0x3a>
  lk->pcs[0] = 0;
80103cfa:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103d01:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103d08:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103d0d:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103d13:	e8 c6 fe ff ff       	call   80103bde <popcli>
}
80103d18:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103d1b:	c9                   	leave  
80103d1c:	c3                   	ret    
    panic("release");
80103d1d:	83 ec 0c             	sub    $0xc,%esp
80103d20:	68 5d 6c 10 80       	push   $0x80106c5d
80103d25:	e8 1e c6 ff ff       	call   80100348 <panic>

80103d2a <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103d2a:	55                   	push   %ebp
80103d2b:	89 e5                	mov    %esp,%ebp
80103d2d:	57                   	push   %edi
80103d2e:	53                   	push   %ebx
80103d2f:	8b 55 08             	mov    0x8(%ebp),%edx
80103d32:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103d35:	f6 c2 03             	test   $0x3,%dl
80103d38:	75 05                	jne    80103d3f <memset+0x15>
80103d3a:	f6 c1 03             	test   $0x3,%cl
80103d3d:	74 0e                	je     80103d4d <memset+0x23>
  asm volatile("cld; rep stosb" :
80103d3f:	89 d7                	mov    %edx,%edi
80103d41:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d44:	fc                   	cld    
80103d45:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103d47:	89 d0                	mov    %edx,%eax
80103d49:	5b                   	pop    %ebx
80103d4a:	5f                   	pop    %edi
80103d4b:	5d                   	pop    %ebp
80103d4c:	c3                   	ret    
    c &= 0xFF;
80103d4d:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103d51:	c1 e9 02             	shr    $0x2,%ecx
80103d54:	89 f8                	mov    %edi,%eax
80103d56:	c1 e0 18             	shl    $0x18,%eax
80103d59:	89 fb                	mov    %edi,%ebx
80103d5b:	c1 e3 10             	shl    $0x10,%ebx
80103d5e:	09 d8                	or     %ebx,%eax
80103d60:	89 fb                	mov    %edi,%ebx
80103d62:	c1 e3 08             	shl    $0x8,%ebx
80103d65:	09 d8                	or     %ebx,%eax
80103d67:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103d69:	89 d7                	mov    %edx,%edi
80103d6b:	fc                   	cld    
80103d6c:	f3 ab                	rep stos %eax,%es:(%edi)
80103d6e:	eb d7                	jmp    80103d47 <memset+0x1d>

80103d70 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103d70:	55                   	push   %ebp
80103d71:	89 e5                	mov    %esp,%ebp
80103d73:	56                   	push   %esi
80103d74:	53                   	push   %ebx
80103d75:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103d78:	8b 55 0c             	mov    0xc(%ebp),%edx
80103d7b:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103d7e:	8d 70 ff             	lea    -0x1(%eax),%esi
80103d81:	85 c0                	test   %eax,%eax
80103d83:	74 1c                	je     80103da1 <memcmp+0x31>
    if(*s1 != *s2)
80103d85:	0f b6 01             	movzbl (%ecx),%eax
80103d88:	0f b6 1a             	movzbl (%edx),%ebx
80103d8b:	38 d8                	cmp    %bl,%al
80103d8d:	75 0a                	jne    80103d99 <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103d8f:	83 c1 01             	add    $0x1,%ecx
80103d92:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103d95:	89 f0                	mov    %esi,%eax
80103d97:	eb e5                	jmp    80103d7e <memcmp+0xe>
      return *s1 - *s2;
80103d99:	0f b6 c0             	movzbl %al,%eax
80103d9c:	0f b6 db             	movzbl %bl,%ebx
80103d9f:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103da1:	5b                   	pop    %ebx
80103da2:	5e                   	pop    %esi
80103da3:	5d                   	pop    %ebp
80103da4:	c3                   	ret    

80103da5 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103da5:	55                   	push   %ebp
80103da6:	89 e5                	mov    %esp,%ebp
80103da8:	56                   	push   %esi
80103da9:	53                   	push   %ebx
80103daa:	8b 45 08             	mov    0x8(%ebp),%eax
80103dad:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103db0:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103db3:	39 c1                	cmp    %eax,%ecx
80103db5:	73 3a                	jae    80103df1 <memmove+0x4c>
80103db7:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103dba:	39 c3                	cmp    %eax,%ebx
80103dbc:	76 37                	jbe    80103df5 <memmove+0x50>
    s += n;
    d += n;
80103dbe:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103dc1:	eb 0d                	jmp    80103dd0 <memmove+0x2b>
      *--d = *--s;
80103dc3:	83 eb 01             	sub    $0x1,%ebx
80103dc6:	83 e9 01             	sub    $0x1,%ecx
80103dc9:	0f b6 13             	movzbl (%ebx),%edx
80103dcc:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103dce:	89 f2                	mov    %esi,%edx
80103dd0:	8d 72 ff             	lea    -0x1(%edx),%esi
80103dd3:	85 d2                	test   %edx,%edx
80103dd5:	75 ec                	jne    80103dc3 <memmove+0x1e>
80103dd7:	eb 14                	jmp    80103ded <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103dd9:	0f b6 11             	movzbl (%ecx),%edx
80103ddc:	88 13                	mov    %dl,(%ebx)
80103dde:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103de1:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103de4:	89 f2                	mov    %esi,%edx
80103de6:	8d 72 ff             	lea    -0x1(%edx),%esi
80103de9:	85 d2                	test   %edx,%edx
80103deb:	75 ec                	jne    80103dd9 <memmove+0x34>

  return dst;
}
80103ded:	5b                   	pop    %ebx
80103dee:	5e                   	pop    %esi
80103def:	5d                   	pop    %ebp
80103df0:	c3                   	ret    
80103df1:	89 c3                	mov    %eax,%ebx
80103df3:	eb f1                	jmp    80103de6 <memmove+0x41>
80103df5:	89 c3                	mov    %eax,%ebx
80103df7:	eb ed                	jmp    80103de6 <memmove+0x41>

80103df9 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103df9:	55                   	push   %ebp
80103dfa:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80103dfc:	ff 75 10             	pushl  0x10(%ebp)
80103dff:	ff 75 0c             	pushl  0xc(%ebp)
80103e02:	ff 75 08             	pushl  0x8(%ebp)
80103e05:	e8 9b ff ff ff       	call   80103da5 <memmove>
}
80103e0a:	c9                   	leave  
80103e0b:	c3                   	ret    

80103e0c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103e0c:	55                   	push   %ebp
80103e0d:	89 e5                	mov    %esp,%ebp
80103e0f:	53                   	push   %ebx
80103e10:	8b 55 08             	mov    0x8(%ebp),%edx
80103e13:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103e16:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103e19:	eb 09                	jmp    80103e24 <strncmp+0x18>
    n--, p++, q++;
80103e1b:	83 e8 01             	sub    $0x1,%eax
80103e1e:	83 c2 01             	add    $0x1,%edx
80103e21:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103e24:	85 c0                	test   %eax,%eax
80103e26:	74 0b                	je     80103e33 <strncmp+0x27>
80103e28:	0f b6 1a             	movzbl (%edx),%ebx
80103e2b:	84 db                	test   %bl,%bl
80103e2d:	74 04                	je     80103e33 <strncmp+0x27>
80103e2f:	3a 19                	cmp    (%ecx),%bl
80103e31:	74 e8                	je     80103e1b <strncmp+0xf>
  if(n == 0)
80103e33:	85 c0                	test   %eax,%eax
80103e35:	74 0b                	je     80103e42 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80103e37:	0f b6 02             	movzbl (%edx),%eax
80103e3a:	0f b6 11             	movzbl (%ecx),%edx
80103e3d:	29 d0                	sub    %edx,%eax
}
80103e3f:	5b                   	pop    %ebx
80103e40:	5d                   	pop    %ebp
80103e41:	c3                   	ret    
    return 0;
80103e42:	b8 00 00 00 00       	mov    $0x0,%eax
80103e47:	eb f6                	jmp    80103e3f <strncmp+0x33>

80103e49 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103e49:	55                   	push   %ebp
80103e4a:	89 e5                	mov    %esp,%ebp
80103e4c:	57                   	push   %edi
80103e4d:	56                   	push   %esi
80103e4e:	53                   	push   %ebx
80103e4f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103e52:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103e55:	8b 45 08             	mov    0x8(%ebp),%eax
80103e58:	eb 04                	jmp    80103e5e <strncpy+0x15>
80103e5a:	89 fb                	mov    %edi,%ebx
80103e5c:	89 f0                	mov    %esi,%eax
80103e5e:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103e61:	85 c9                	test   %ecx,%ecx
80103e63:	7e 1d                	jle    80103e82 <strncpy+0x39>
80103e65:	8d 7b 01             	lea    0x1(%ebx),%edi
80103e68:	8d 70 01             	lea    0x1(%eax),%esi
80103e6b:	0f b6 1b             	movzbl (%ebx),%ebx
80103e6e:	88 18                	mov    %bl,(%eax)
80103e70:	89 d1                	mov    %edx,%ecx
80103e72:	84 db                	test   %bl,%bl
80103e74:	75 e4                	jne    80103e5a <strncpy+0x11>
80103e76:	89 f0                	mov    %esi,%eax
80103e78:	eb 08                	jmp    80103e82 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80103e7a:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80103e7d:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80103e7f:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80103e82:	8d 4a ff             	lea    -0x1(%edx),%ecx
80103e85:	85 d2                	test   %edx,%edx
80103e87:	7f f1                	jg     80103e7a <strncpy+0x31>
  return os;
}
80103e89:	8b 45 08             	mov    0x8(%ebp),%eax
80103e8c:	5b                   	pop    %ebx
80103e8d:	5e                   	pop    %esi
80103e8e:	5f                   	pop    %edi
80103e8f:	5d                   	pop    %ebp
80103e90:	c3                   	ret    

80103e91 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80103e91:	55                   	push   %ebp
80103e92:	89 e5                	mov    %esp,%ebp
80103e94:	57                   	push   %edi
80103e95:	56                   	push   %esi
80103e96:	53                   	push   %ebx
80103e97:	8b 45 08             	mov    0x8(%ebp),%eax
80103e9a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103e9d:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
80103ea0:	85 d2                	test   %edx,%edx
80103ea2:	7e 23                	jle    80103ec7 <safestrcpy+0x36>
80103ea4:	89 c1                	mov    %eax,%ecx
80103ea6:	eb 04                	jmp    80103eac <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80103ea8:	89 fb                	mov    %edi,%ebx
80103eaa:	89 f1                	mov    %esi,%ecx
80103eac:	83 ea 01             	sub    $0x1,%edx
80103eaf:	85 d2                	test   %edx,%edx
80103eb1:	7e 11                	jle    80103ec4 <safestrcpy+0x33>
80103eb3:	8d 7b 01             	lea    0x1(%ebx),%edi
80103eb6:	8d 71 01             	lea    0x1(%ecx),%esi
80103eb9:	0f b6 1b             	movzbl (%ebx),%ebx
80103ebc:	88 19                	mov    %bl,(%ecx)
80103ebe:	84 db                	test   %bl,%bl
80103ec0:	75 e6                	jne    80103ea8 <safestrcpy+0x17>
80103ec2:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80103ec4:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80103ec7:	5b                   	pop    %ebx
80103ec8:	5e                   	pop    %esi
80103ec9:	5f                   	pop    %edi
80103eca:	5d                   	pop    %ebp
80103ecb:	c3                   	ret    

80103ecc <strlen>:

int
strlen(const char *s)
{
80103ecc:	55                   	push   %ebp
80103ecd:	89 e5                	mov    %esp,%ebp
80103ecf:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80103ed2:	b8 00 00 00 00       	mov    $0x0,%eax
80103ed7:	eb 03                	jmp    80103edc <strlen+0x10>
80103ed9:	83 c0 01             	add    $0x1,%eax
80103edc:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80103ee0:	75 f7                	jne    80103ed9 <strlen+0xd>
    ;
  return n;
}
80103ee2:	5d                   	pop    %ebp
80103ee3:	c3                   	ret    

80103ee4 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80103ee4:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80103ee8:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80103eec:	55                   	push   %ebp
  pushl %ebx
80103eed:	53                   	push   %ebx
  pushl %esi
80103eee:	56                   	push   %esi
  pushl %edi
80103eef:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80103ef0:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80103ef2:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80103ef4:	5f                   	pop    %edi
  popl %esi
80103ef5:	5e                   	pop    %esi
  popl %ebx
80103ef6:	5b                   	pop    %ebx
  popl %ebp
80103ef7:	5d                   	pop    %ebp
  ret
80103ef8:	c3                   	ret    

80103ef9 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80103ef9:	55                   	push   %ebp
80103efa:	89 e5                	mov    %esp,%ebp
80103efc:	53                   	push   %ebx
80103efd:	83 ec 04             	sub    $0x4,%esp
80103f00:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80103f03:	e8 75 f3 ff ff       	call   8010327d <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80103f08:	8b 00                	mov    (%eax),%eax
80103f0a:	39 d8                	cmp    %ebx,%eax
80103f0c:	76 19                	jbe    80103f27 <fetchint+0x2e>
80103f0e:	8d 53 04             	lea    0x4(%ebx),%edx
80103f11:	39 d0                	cmp    %edx,%eax
80103f13:	72 19                	jb     80103f2e <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80103f15:	8b 13                	mov    (%ebx),%edx
80103f17:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f1a:	89 10                	mov    %edx,(%eax)
  return 0;
80103f1c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103f21:	83 c4 04             	add    $0x4,%esp
80103f24:	5b                   	pop    %ebx
80103f25:	5d                   	pop    %ebp
80103f26:	c3                   	ret    
    return -1;
80103f27:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f2c:	eb f3                	jmp    80103f21 <fetchint+0x28>
80103f2e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f33:	eb ec                	jmp    80103f21 <fetchint+0x28>

80103f35 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80103f35:	55                   	push   %ebp
80103f36:	89 e5                	mov    %esp,%ebp
80103f38:	53                   	push   %ebx
80103f39:	83 ec 04             	sub    $0x4,%esp
80103f3c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
80103f3f:	e8 39 f3 ff ff       	call   8010327d <myproc>

  if(addr >= curproc->sz)
80103f44:	39 18                	cmp    %ebx,(%eax)
80103f46:	76 26                	jbe    80103f6e <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
80103f48:	8b 55 0c             	mov    0xc(%ebp),%edx
80103f4b:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
80103f4d:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
80103f4f:	89 d8                	mov    %ebx,%eax
80103f51:	39 d0                	cmp    %edx,%eax
80103f53:	73 0e                	jae    80103f63 <fetchstr+0x2e>
    if(*s == 0)
80103f55:	80 38 00             	cmpb   $0x0,(%eax)
80103f58:	74 05                	je     80103f5f <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
80103f5a:	83 c0 01             	add    $0x1,%eax
80103f5d:	eb f2                	jmp    80103f51 <fetchstr+0x1c>
      return s - *pp;
80103f5f:	29 d8                	sub    %ebx,%eax
80103f61:	eb 05                	jmp    80103f68 <fetchstr+0x33>
  }
  return -1;
80103f63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103f68:	83 c4 04             	add    $0x4,%esp
80103f6b:	5b                   	pop    %ebx
80103f6c:	5d                   	pop    %ebp
80103f6d:	c3                   	ret    
    return -1;
80103f6e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f73:	eb f3                	jmp    80103f68 <fetchstr+0x33>

80103f75 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80103f75:	55                   	push   %ebp
80103f76:	89 e5                	mov    %esp,%ebp
80103f78:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80103f7b:	e8 fd f2 ff ff       	call   8010327d <myproc>
80103f80:	8b 50 18             	mov    0x18(%eax),%edx
80103f83:	8b 45 08             	mov    0x8(%ebp),%eax
80103f86:	c1 e0 02             	shl    $0x2,%eax
80103f89:	03 42 44             	add    0x44(%edx),%eax
80103f8c:	83 ec 08             	sub    $0x8,%esp
80103f8f:	ff 75 0c             	pushl  0xc(%ebp)
80103f92:	83 c0 04             	add    $0x4,%eax
80103f95:	50                   	push   %eax
80103f96:	e8 5e ff ff ff       	call   80103ef9 <fetchint>
}
80103f9b:	c9                   	leave  
80103f9c:	c3                   	ret    

80103f9d <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80103f9d:	55                   	push   %ebp
80103f9e:	89 e5                	mov    %esp,%ebp
80103fa0:	56                   	push   %esi
80103fa1:	53                   	push   %ebx
80103fa2:	83 ec 10             	sub    $0x10,%esp
80103fa5:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
80103fa8:	e8 d0 f2 ff ff       	call   8010327d <myproc>
80103fad:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
80103faf:	83 ec 08             	sub    $0x8,%esp
80103fb2:	8d 45 f4             	lea    -0xc(%ebp),%eax
80103fb5:	50                   	push   %eax
80103fb6:	ff 75 08             	pushl  0x8(%ebp)
80103fb9:	e8 b7 ff ff ff       	call   80103f75 <argint>
80103fbe:	83 c4 10             	add    $0x10,%esp
80103fc1:	85 c0                	test   %eax,%eax
80103fc3:	78 24                	js     80103fe9 <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80103fc5:	85 db                	test   %ebx,%ebx
80103fc7:	78 27                	js     80103ff0 <argptr+0x53>
80103fc9:	8b 16                	mov    (%esi),%edx
80103fcb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fce:	39 c2                	cmp    %eax,%edx
80103fd0:	76 25                	jbe    80103ff7 <argptr+0x5a>
80103fd2:	01 c3                	add    %eax,%ebx
80103fd4:	39 da                	cmp    %ebx,%edx
80103fd6:	72 26                	jb     80103ffe <argptr+0x61>
    return -1;
  *pp = (char*)i;
80103fd8:	8b 55 0c             	mov    0xc(%ebp),%edx
80103fdb:	89 02                	mov    %eax,(%edx)
  return 0;
80103fdd:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103fe2:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103fe5:	5b                   	pop    %ebx
80103fe6:	5e                   	pop    %esi
80103fe7:	5d                   	pop    %ebp
80103fe8:	c3                   	ret    
    return -1;
80103fe9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fee:	eb f2                	jmp    80103fe2 <argptr+0x45>
    return -1;
80103ff0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103ff5:	eb eb                	jmp    80103fe2 <argptr+0x45>
80103ff7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103ffc:	eb e4                	jmp    80103fe2 <argptr+0x45>
80103ffe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104003:	eb dd                	jmp    80103fe2 <argptr+0x45>

80104005 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80104005:	55                   	push   %ebp
80104006:	89 e5                	mov    %esp,%ebp
80104008:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010400b:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010400e:	50                   	push   %eax
8010400f:	ff 75 08             	pushl  0x8(%ebp)
80104012:	e8 5e ff ff ff       	call   80103f75 <argint>
80104017:	83 c4 10             	add    $0x10,%esp
8010401a:	85 c0                	test   %eax,%eax
8010401c:	78 13                	js     80104031 <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
8010401e:	83 ec 08             	sub    $0x8,%esp
80104021:	ff 75 0c             	pushl  0xc(%ebp)
80104024:	ff 75 f4             	pushl  -0xc(%ebp)
80104027:	e8 09 ff ff ff       	call   80103f35 <fetchstr>
8010402c:	83 c4 10             	add    $0x10,%esp
}
8010402f:	c9                   	leave  
80104030:	c3                   	ret    
    return -1;
80104031:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104036:	eb f7                	jmp    8010402f <argstr+0x2a>

80104038 <syscall>:
[SYS_dump_physmem]   sys_dump_physmem,
};

void
syscall(void)
{
80104038:	55                   	push   %ebp
80104039:	89 e5                	mov    %esp,%ebp
8010403b:	53                   	push   %ebx
8010403c:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
8010403f:	e8 39 f2 ff ff       	call   8010327d <myproc>
80104044:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
80104046:	8b 40 18             	mov    0x18(%eax),%eax
80104049:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
8010404c:	8d 50 ff             	lea    -0x1(%eax),%edx
8010404f:	83 fa 15             	cmp    $0x15,%edx
80104052:	77 18                	ja     8010406c <syscall+0x34>
80104054:	8b 14 85 a0 6c 10 80 	mov    -0x7fef9360(,%eax,4),%edx
8010405b:	85 d2                	test   %edx,%edx
8010405d:	74 0d                	je     8010406c <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
8010405f:	ff d2                	call   *%edx
80104061:	8b 53 18             	mov    0x18(%ebx),%edx
80104064:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
80104067:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010406a:	c9                   	leave  
8010406b:	c3                   	ret    
            curproc->pid, curproc->name, num);
8010406c:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
8010406f:	50                   	push   %eax
80104070:	52                   	push   %edx
80104071:	ff 73 10             	pushl  0x10(%ebx)
80104074:	68 65 6c 10 80       	push   $0x80106c65
80104079:	e8 8d c5 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
8010407e:	8b 43 18             	mov    0x18(%ebx),%eax
80104081:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
80104088:	83 c4 10             	add    $0x10,%esp
}
8010408b:	eb da                	jmp    80104067 <syscall+0x2f>

8010408d <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
8010408d:	55                   	push   %ebp
8010408e:	89 e5                	mov    %esp,%ebp
80104090:	56                   	push   %esi
80104091:	53                   	push   %ebx
80104092:	83 ec 18             	sub    $0x18,%esp
80104095:	89 d6                	mov    %edx,%esi
80104097:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80104099:	8d 55 f4             	lea    -0xc(%ebp),%edx
8010409c:	52                   	push   %edx
8010409d:	50                   	push   %eax
8010409e:	e8 d2 fe ff ff       	call   80103f75 <argint>
801040a3:	83 c4 10             	add    $0x10,%esp
801040a6:	85 c0                	test   %eax,%eax
801040a8:	78 2e                	js     801040d8 <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
801040aa:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
801040ae:	77 2f                	ja     801040df <argfd+0x52>
801040b0:	e8 c8 f1 ff ff       	call   8010327d <myproc>
801040b5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801040b8:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
801040bc:	85 c0                	test   %eax,%eax
801040be:	74 26                	je     801040e6 <argfd+0x59>
    return -1;
  if(pfd)
801040c0:	85 f6                	test   %esi,%esi
801040c2:	74 02                	je     801040c6 <argfd+0x39>
    *pfd = fd;
801040c4:	89 16                	mov    %edx,(%esi)
  if(pf)
801040c6:	85 db                	test   %ebx,%ebx
801040c8:	74 23                	je     801040ed <argfd+0x60>
    *pf = f;
801040ca:	89 03                	mov    %eax,(%ebx)
  return 0;
801040cc:	b8 00 00 00 00       	mov    $0x0,%eax
}
801040d1:	8d 65 f8             	lea    -0x8(%ebp),%esp
801040d4:	5b                   	pop    %ebx
801040d5:	5e                   	pop    %esi
801040d6:	5d                   	pop    %ebp
801040d7:	c3                   	ret    
    return -1;
801040d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040dd:	eb f2                	jmp    801040d1 <argfd+0x44>
    return -1;
801040df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040e4:	eb eb                	jmp    801040d1 <argfd+0x44>
801040e6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040eb:	eb e4                	jmp    801040d1 <argfd+0x44>
  return 0;
801040ed:	b8 00 00 00 00       	mov    $0x0,%eax
801040f2:	eb dd                	jmp    801040d1 <argfd+0x44>

801040f4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801040f4:	55                   	push   %ebp
801040f5:	89 e5                	mov    %esp,%ebp
801040f7:	53                   	push   %ebx
801040f8:	83 ec 04             	sub    $0x4,%esp
801040fb:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
801040fd:	e8 7b f1 ff ff       	call   8010327d <myproc>

  for(fd = 0; fd < NOFILE; fd++){
80104102:	ba 00 00 00 00       	mov    $0x0,%edx
80104107:	83 fa 0f             	cmp    $0xf,%edx
8010410a:	7f 18                	jg     80104124 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
8010410c:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
80104111:	74 05                	je     80104118 <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
80104113:	83 c2 01             	add    $0x1,%edx
80104116:	eb ef                	jmp    80104107 <fdalloc+0x13>
      curproc->ofile[fd] = f;
80104118:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
8010411c:	89 d0                	mov    %edx,%eax
8010411e:	83 c4 04             	add    $0x4,%esp
80104121:	5b                   	pop    %ebx
80104122:	5d                   	pop    %ebp
80104123:	c3                   	ret    
  return -1;
80104124:	ba ff ff ff ff       	mov    $0xffffffff,%edx
80104129:	eb f1                	jmp    8010411c <fdalloc+0x28>

8010412b <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
8010412b:	55                   	push   %ebp
8010412c:	89 e5                	mov    %esp,%ebp
8010412e:	56                   	push   %esi
8010412f:	53                   	push   %ebx
80104130:	83 ec 10             	sub    $0x10,%esp
80104133:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104135:	b8 20 00 00 00       	mov    $0x20,%eax
8010413a:	89 c6                	mov    %eax,%esi
8010413c:	39 43 58             	cmp    %eax,0x58(%ebx)
8010413f:	76 2e                	jbe    8010416f <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104141:	6a 10                	push   $0x10
80104143:	50                   	push   %eax
80104144:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104147:	50                   	push   %eax
80104148:	53                   	push   %ebx
80104149:	e8 25 d6 ff ff       	call   80101773 <readi>
8010414e:	83 c4 10             	add    $0x10,%esp
80104151:	83 f8 10             	cmp    $0x10,%eax
80104154:	75 0c                	jne    80104162 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
80104156:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
8010415b:	75 1e                	jne    8010417b <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010415d:	8d 46 10             	lea    0x10(%esi),%eax
80104160:	eb d8                	jmp    8010413a <isdirempty+0xf>
      panic("isdirempty: readi");
80104162:	83 ec 0c             	sub    $0xc,%esp
80104165:	68 fc 6c 10 80       	push   $0x80106cfc
8010416a:	e8 d9 c1 ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
8010416f:	b8 01 00 00 00       	mov    $0x1,%eax
}
80104174:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104177:	5b                   	pop    %ebx
80104178:	5e                   	pop    %esi
80104179:	5d                   	pop    %ebp
8010417a:	c3                   	ret    
      return 0;
8010417b:	b8 00 00 00 00       	mov    $0x0,%eax
80104180:	eb f2                	jmp    80104174 <isdirempty+0x49>

80104182 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
80104182:	55                   	push   %ebp
80104183:	89 e5                	mov    %esp,%ebp
80104185:	57                   	push   %edi
80104186:	56                   	push   %esi
80104187:	53                   	push   %ebx
80104188:	83 ec 44             	sub    $0x44,%esp
8010418b:	89 55 c4             	mov    %edx,-0x3c(%ebp)
8010418e:	89 4d c0             	mov    %ecx,-0x40(%ebp)
80104191:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80104194:	8d 55 d6             	lea    -0x2a(%ebp),%edx
80104197:	52                   	push   %edx
80104198:	50                   	push   %eax
80104199:	e8 5b da ff ff       	call   80101bf9 <nameiparent>
8010419e:	89 c6                	mov    %eax,%esi
801041a0:	83 c4 10             	add    $0x10,%esp
801041a3:	85 c0                	test   %eax,%eax
801041a5:	0f 84 3a 01 00 00    	je     801042e5 <create+0x163>
    return 0;
  ilock(dp);
801041ab:	83 ec 0c             	sub    $0xc,%esp
801041ae:	50                   	push   %eax
801041af:	e8 cd d3 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
801041b4:	83 c4 0c             	add    $0xc,%esp
801041b7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801041ba:	50                   	push   %eax
801041bb:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801041be:	50                   	push   %eax
801041bf:	56                   	push   %esi
801041c0:	e8 eb d7 ff ff       	call   801019b0 <dirlookup>
801041c5:	89 c3                	mov    %eax,%ebx
801041c7:	83 c4 10             	add    $0x10,%esp
801041ca:	85 c0                	test   %eax,%eax
801041cc:	74 3f                	je     8010420d <create+0x8b>
    iunlockput(dp);
801041ce:	83 ec 0c             	sub    $0xc,%esp
801041d1:	56                   	push   %esi
801041d2:	e8 51 d5 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
801041d7:	89 1c 24             	mov    %ebx,(%esp)
801041da:	e8 a2 d3 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
801041df:	83 c4 10             	add    $0x10,%esp
801041e2:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
801041e7:	75 11                	jne    801041fa <create+0x78>
801041e9:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
801041ee:	75 0a                	jne    801041fa <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
801041f0:	89 d8                	mov    %ebx,%eax
801041f2:	8d 65 f4             	lea    -0xc(%ebp),%esp
801041f5:	5b                   	pop    %ebx
801041f6:	5e                   	pop    %esi
801041f7:	5f                   	pop    %edi
801041f8:	5d                   	pop    %ebp
801041f9:	c3                   	ret    
    iunlockput(ip);
801041fa:	83 ec 0c             	sub    $0xc,%esp
801041fd:	53                   	push   %ebx
801041fe:	e8 25 d5 ff ff       	call   80101728 <iunlockput>
    return 0;
80104203:	83 c4 10             	add    $0x10,%esp
80104206:	bb 00 00 00 00       	mov    $0x0,%ebx
8010420b:	eb e3                	jmp    801041f0 <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
8010420d:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
80104211:	83 ec 08             	sub    $0x8,%esp
80104214:	50                   	push   %eax
80104215:	ff 36                	pushl  (%esi)
80104217:	e8 62 d1 ff ff       	call   8010137e <ialloc>
8010421c:	89 c3                	mov    %eax,%ebx
8010421e:	83 c4 10             	add    $0x10,%esp
80104221:	85 c0                	test   %eax,%eax
80104223:	74 55                	je     8010427a <create+0xf8>
  ilock(ip);
80104225:	83 ec 0c             	sub    $0xc,%esp
80104228:	50                   	push   %eax
80104229:	e8 53 d3 ff ff       	call   80101581 <ilock>
  ip->major = major;
8010422e:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
80104232:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
80104236:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
8010423a:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
80104240:	89 1c 24             	mov    %ebx,(%esp)
80104243:	e8 d8 d1 ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
80104248:	83 c4 10             	add    $0x10,%esp
8010424b:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
80104250:	74 35                	je     80104287 <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
80104252:	83 ec 04             	sub    $0x4,%esp
80104255:	ff 73 04             	pushl  0x4(%ebx)
80104258:	8d 45 d6             	lea    -0x2a(%ebp),%eax
8010425b:	50                   	push   %eax
8010425c:	56                   	push   %esi
8010425d:	e8 ce d8 ff ff       	call   80101b30 <dirlink>
80104262:	83 c4 10             	add    $0x10,%esp
80104265:	85 c0                	test   %eax,%eax
80104267:	78 6f                	js     801042d8 <create+0x156>
  iunlockput(dp);
80104269:	83 ec 0c             	sub    $0xc,%esp
8010426c:	56                   	push   %esi
8010426d:	e8 b6 d4 ff ff       	call   80101728 <iunlockput>
  return ip;
80104272:	83 c4 10             	add    $0x10,%esp
80104275:	e9 76 ff ff ff       	jmp    801041f0 <create+0x6e>
    panic("create: ialloc");
8010427a:	83 ec 0c             	sub    $0xc,%esp
8010427d:	68 0e 6d 10 80       	push   $0x80106d0e
80104282:	e8 c1 c0 ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
80104287:	0f b7 46 56          	movzwl 0x56(%esi),%eax
8010428b:	83 c0 01             	add    $0x1,%eax
8010428e:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104292:	83 ec 0c             	sub    $0xc,%esp
80104295:	56                   	push   %esi
80104296:	e8 85 d1 ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
8010429b:	83 c4 0c             	add    $0xc,%esp
8010429e:	ff 73 04             	pushl  0x4(%ebx)
801042a1:	68 1e 6d 10 80       	push   $0x80106d1e
801042a6:	53                   	push   %ebx
801042a7:	e8 84 d8 ff ff       	call   80101b30 <dirlink>
801042ac:	83 c4 10             	add    $0x10,%esp
801042af:	85 c0                	test   %eax,%eax
801042b1:	78 18                	js     801042cb <create+0x149>
801042b3:	83 ec 04             	sub    $0x4,%esp
801042b6:	ff 76 04             	pushl  0x4(%esi)
801042b9:	68 1d 6d 10 80       	push   $0x80106d1d
801042be:	53                   	push   %ebx
801042bf:	e8 6c d8 ff ff       	call   80101b30 <dirlink>
801042c4:	83 c4 10             	add    $0x10,%esp
801042c7:	85 c0                	test   %eax,%eax
801042c9:	79 87                	jns    80104252 <create+0xd0>
      panic("create dots");
801042cb:	83 ec 0c             	sub    $0xc,%esp
801042ce:	68 20 6d 10 80       	push   $0x80106d20
801042d3:	e8 70 c0 ff ff       	call   80100348 <panic>
    panic("create: dirlink");
801042d8:	83 ec 0c             	sub    $0xc,%esp
801042db:	68 2c 6d 10 80       	push   $0x80106d2c
801042e0:	e8 63 c0 ff ff       	call   80100348 <panic>
    return 0;
801042e5:	89 c3                	mov    %eax,%ebx
801042e7:	e9 04 ff ff ff       	jmp    801041f0 <create+0x6e>

801042ec <sys_dup>:
{
801042ec:	55                   	push   %ebp
801042ed:	89 e5                	mov    %esp,%ebp
801042ef:	53                   	push   %ebx
801042f0:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
801042f3:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801042f6:	ba 00 00 00 00       	mov    $0x0,%edx
801042fb:	b8 00 00 00 00       	mov    $0x0,%eax
80104300:	e8 88 fd ff ff       	call   8010408d <argfd>
80104305:	85 c0                	test   %eax,%eax
80104307:	78 23                	js     8010432c <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
80104309:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010430c:	e8 e3 fd ff ff       	call   801040f4 <fdalloc>
80104311:	89 c3                	mov    %eax,%ebx
80104313:	85 c0                	test   %eax,%eax
80104315:	78 1c                	js     80104333 <sys_dup+0x47>
  filedup(f);
80104317:	83 ec 0c             	sub    $0xc,%esp
8010431a:	ff 75 f4             	pushl  -0xc(%ebp)
8010431d:	e8 6c c9 ff ff       	call   80100c8e <filedup>
  return fd;
80104322:	83 c4 10             	add    $0x10,%esp
}
80104325:	89 d8                	mov    %ebx,%eax
80104327:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010432a:	c9                   	leave  
8010432b:	c3                   	ret    
    return -1;
8010432c:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104331:	eb f2                	jmp    80104325 <sys_dup+0x39>
    return -1;
80104333:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104338:	eb eb                	jmp    80104325 <sys_dup+0x39>

8010433a <sys_read>:
{
8010433a:	55                   	push   %ebp
8010433b:	89 e5                	mov    %esp,%ebp
8010433d:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104340:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104343:	ba 00 00 00 00       	mov    $0x0,%edx
80104348:	b8 00 00 00 00       	mov    $0x0,%eax
8010434d:	e8 3b fd ff ff       	call   8010408d <argfd>
80104352:	85 c0                	test   %eax,%eax
80104354:	78 43                	js     80104399 <sys_read+0x5f>
80104356:	83 ec 08             	sub    $0x8,%esp
80104359:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010435c:	50                   	push   %eax
8010435d:	6a 02                	push   $0x2
8010435f:	e8 11 fc ff ff       	call   80103f75 <argint>
80104364:	83 c4 10             	add    $0x10,%esp
80104367:	85 c0                	test   %eax,%eax
80104369:	78 35                	js     801043a0 <sys_read+0x66>
8010436b:	83 ec 04             	sub    $0x4,%esp
8010436e:	ff 75 f0             	pushl  -0x10(%ebp)
80104371:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104374:	50                   	push   %eax
80104375:	6a 01                	push   $0x1
80104377:	e8 21 fc ff ff       	call   80103f9d <argptr>
8010437c:	83 c4 10             	add    $0x10,%esp
8010437f:	85 c0                	test   %eax,%eax
80104381:	78 24                	js     801043a7 <sys_read+0x6d>
  return fileread(f, p, n);
80104383:	83 ec 04             	sub    $0x4,%esp
80104386:	ff 75 f0             	pushl  -0x10(%ebp)
80104389:	ff 75 ec             	pushl  -0x14(%ebp)
8010438c:	ff 75 f4             	pushl  -0xc(%ebp)
8010438f:	e8 43 ca ff ff       	call   80100dd7 <fileread>
80104394:	83 c4 10             	add    $0x10,%esp
}
80104397:	c9                   	leave  
80104398:	c3                   	ret    
    return -1;
80104399:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010439e:	eb f7                	jmp    80104397 <sys_read+0x5d>
801043a0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043a5:	eb f0                	jmp    80104397 <sys_read+0x5d>
801043a7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043ac:	eb e9                	jmp    80104397 <sys_read+0x5d>

801043ae <sys_write>:
{
801043ae:	55                   	push   %ebp
801043af:	89 e5                	mov    %esp,%ebp
801043b1:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801043b4:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801043b7:	ba 00 00 00 00       	mov    $0x0,%edx
801043bc:	b8 00 00 00 00       	mov    $0x0,%eax
801043c1:	e8 c7 fc ff ff       	call   8010408d <argfd>
801043c6:	85 c0                	test   %eax,%eax
801043c8:	78 43                	js     8010440d <sys_write+0x5f>
801043ca:	83 ec 08             	sub    $0x8,%esp
801043cd:	8d 45 f0             	lea    -0x10(%ebp),%eax
801043d0:	50                   	push   %eax
801043d1:	6a 02                	push   $0x2
801043d3:	e8 9d fb ff ff       	call   80103f75 <argint>
801043d8:	83 c4 10             	add    $0x10,%esp
801043db:	85 c0                	test   %eax,%eax
801043dd:	78 35                	js     80104414 <sys_write+0x66>
801043df:	83 ec 04             	sub    $0x4,%esp
801043e2:	ff 75 f0             	pushl  -0x10(%ebp)
801043e5:	8d 45 ec             	lea    -0x14(%ebp),%eax
801043e8:	50                   	push   %eax
801043e9:	6a 01                	push   $0x1
801043eb:	e8 ad fb ff ff       	call   80103f9d <argptr>
801043f0:	83 c4 10             	add    $0x10,%esp
801043f3:	85 c0                	test   %eax,%eax
801043f5:	78 24                	js     8010441b <sys_write+0x6d>
  return filewrite(f, p, n);
801043f7:	83 ec 04             	sub    $0x4,%esp
801043fa:	ff 75 f0             	pushl  -0x10(%ebp)
801043fd:	ff 75 ec             	pushl  -0x14(%ebp)
80104400:	ff 75 f4             	pushl  -0xc(%ebp)
80104403:	e8 54 ca ff ff       	call   80100e5c <filewrite>
80104408:	83 c4 10             	add    $0x10,%esp
}
8010440b:	c9                   	leave  
8010440c:	c3                   	ret    
    return -1;
8010440d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104412:	eb f7                	jmp    8010440b <sys_write+0x5d>
80104414:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104419:	eb f0                	jmp    8010440b <sys_write+0x5d>
8010441b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104420:	eb e9                	jmp    8010440b <sys_write+0x5d>

80104422 <sys_close>:
{
80104422:	55                   	push   %ebp
80104423:	89 e5                	mov    %esp,%ebp
80104425:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
80104428:	8d 4d f0             	lea    -0x10(%ebp),%ecx
8010442b:	8d 55 f4             	lea    -0xc(%ebp),%edx
8010442e:	b8 00 00 00 00       	mov    $0x0,%eax
80104433:	e8 55 fc ff ff       	call   8010408d <argfd>
80104438:	85 c0                	test   %eax,%eax
8010443a:	78 25                	js     80104461 <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
8010443c:	e8 3c ee ff ff       	call   8010327d <myproc>
80104441:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104444:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
8010444b:	00 
  fileclose(f);
8010444c:	83 ec 0c             	sub    $0xc,%esp
8010444f:	ff 75 f0             	pushl  -0x10(%ebp)
80104452:	e8 7c c8 ff ff       	call   80100cd3 <fileclose>
  return 0;
80104457:	83 c4 10             	add    $0x10,%esp
8010445a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010445f:	c9                   	leave  
80104460:	c3                   	ret    
    return -1;
80104461:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104466:	eb f7                	jmp    8010445f <sys_close+0x3d>

80104468 <sys_fstat>:
{
80104468:	55                   	push   %ebp
80104469:	89 e5                	mov    %esp,%ebp
8010446b:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
8010446e:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104471:	ba 00 00 00 00       	mov    $0x0,%edx
80104476:	b8 00 00 00 00       	mov    $0x0,%eax
8010447b:	e8 0d fc ff ff       	call   8010408d <argfd>
80104480:	85 c0                	test   %eax,%eax
80104482:	78 2a                	js     801044ae <sys_fstat+0x46>
80104484:	83 ec 04             	sub    $0x4,%esp
80104487:	6a 14                	push   $0x14
80104489:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010448c:	50                   	push   %eax
8010448d:	6a 01                	push   $0x1
8010448f:	e8 09 fb ff ff       	call   80103f9d <argptr>
80104494:	83 c4 10             	add    $0x10,%esp
80104497:	85 c0                	test   %eax,%eax
80104499:	78 1a                	js     801044b5 <sys_fstat+0x4d>
  return filestat(f, st);
8010449b:	83 ec 08             	sub    $0x8,%esp
8010449e:	ff 75 f0             	pushl  -0x10(%ebp)
801044a1:	ff 75 f4             	pushl  -0xc(%ebp)
801044a4:	e8 e7 c8 ff ff       	call   80100d90 <filestat>
801044a9:	83 c4 10             	add    $0x10,%esp
}
801044ac:	c9                   	leave  
801044ad:	c3                   	ret    
    return -1;
801044ae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044b3:	eb f7                	jmp    801044ac <sys_fstat+0x44>
801044b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044ba:	eb f0                	jmp    801044ac <sys_fstat+0x44>

801044bc <sys_link>:
{
801044bc:	55                   	push   %ebp
801044bd:	89 e5                	mov    %esp,%ebp
801044bf:	56                   	push   %esi
801044c0:	53                   	push   %ebx
801044c1:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801044c4:	8d 45 e0             	lea    -0x20(%ebp),%eax
801044c7:	50                   	push   %eax
801044c8:	6a 00                	push   $0x0
801044ca:	e8 36 fb ff ff       	call   80104005 <argstr>
801044cf:	83 c4 10             	add    $0x10,%esp
801044d2:	85 c0                	test   %eax,%eax
801044d4:	0f 88 32 01 00 00    	js     8010460c <sys_link+0x150>
801044da:	83 ec 08             	sub    $0x8,%esp
801044dd:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801044e0:	50                   	push   %eax
801044e1:	6a 01                	push   $0x1
801044e3:	e8 1d fb ff ff       	call   80104005 <argstr>
801044e8:	83 c4 10             	add    $0x10,%esp
801044eb:	85 c0                	test   %eax,%eax
801044ed:	0f 88 20 01 00 00    	js     80104613 <sys_link+0x157>
  begin_op();
801044f3:	e8 35 e3 ff ff       	call   8010282d <begin_op>
  if((ip = namei(old)) == 0){
801044f8:	83 ec 0c             	sub    $0xc,%esp
801044fb:	ff 75 e0             	pushl  -0x20(%ebp)
801044fe:	e8 de d6 ff ff       	call   80101be1 <namei>
80104503:	89 c3                	mov    %eax,%ebx
80104505:	83 c4 10             	add    $0x10,%esp
80104508:	85 c0                	test   %eax,%eax
8010450a:	0f 84 99 00 00 00    	je     801045a9 <sys_link+0xed>
  ilock(ip);
80104510:	83 ec 0c             	sub    $0xc,%esp
80104513:	50                   	push   %eax
80104514:	e8 68 d0 ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
80104519:	83 c4 10             	add    $0x10,%esp
8010451c:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104521:	0f 84 8e 00 00 00    	je     801045b5 <sys_link+0xf9>
  ip->nlink++;
80104527:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010452b:	83 c0 01             	add    $0x1,%eax
8010452e:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104532:	83 ec 0c             	sub    $0xc,%esp
80104535:	53                   	push   %ebx
80104536:	e8 e5 ce ff ff       	call   80101420 <iupdate>
  iunlock(ip);
8010453b:	89 1c 24             	mov    %ebx,(%esp)
8010453e:	e8 00 d1 ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
80104543:	83 c4 08             	add    $0x8,%esp
80104546:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104549:	50                   	push   %eax
8010454a:	ff 75 e4             	pushl  -0x1c(%ebp)
8010454d:	e8 a7 d6 ff ff       	call   80101bf9 <nameiparent>
80104552:	89 c6                	mov    %eax,%esi
80104554:	83 c4 10             	add    $0x10,%esp
80104557:	85 c0                	test   %eax,%eax
80104559:	74 7e                	je     801045d9 <sys_link+0x11d>
  ilock(dp);
8010455b:	83 ec 0c             	sub    $0xc,%esp
8010455e:	50                   	push   %eax
8010455f:	e8 1d d0 ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80104564:	83 c4 10             	add    $0x10,%esp
80104567:	8b 03                	mov    (%ebx),%eax
80104569:	39 06                	cmp    %eax,(%esi)
8010456b:	75 60                	jne    801045cd <sys_link+0x111>
8010456d:	83 ec 04             	sub    $0x4,%esp
80104570:	ff 73 04             	pushl  0x4(%ebx)
80104573:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104576:	50                   	push   %eax
80104577:	56                   	push   %esi
80104578:	e8 b3 d5 ff ff       	call   80101b30 <dirlink>
8010457d:	83 c4 10             	add    $0x10,%esp
80104580:	85 c0                	test   %eax,%eax
80104582:	78 49                	js     801045cd <sys_link+0x111>
  iunlockput(dp);
80104584:	83 ec 0c             	sub    $0xc,%esp
80104587:	56                   	push   %esi
80104588:	e8 9b d1 ff ff       	call   80101728 <iunlockput>
  iput(ip);
8010458d:	89 1c 24             	mov    %ebx,(%esp)
80104590:	e8 f3 d0 ff ff       	call   80101688 <iput>
  end_op();
80104595:	e8 0d e3 ff ff       	call   801028a7 <end_op>
  return 0;
8010459a:	83 c4 10             	add    $0x10,%esp
8010459d:	b8 00 00 00 00       	mov    $0x0,%eax
}
801045a2:	8d 65 f8             	lea    -0x8(%ebp),%esp
801045a5:	5b                   	pop    %ebx
801045a6:	5e                   	pop    %esi
801045a7:	5d                   	pop    %ebp
801045a8:	c3                   	ret    
    end_op();
801045a9:	e8 f9 e2 ff ff       	call   801028a7 <end_op>
    return -1;
801045ae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045b3:	eb ed                	jmp    801045a2 <sys_link+0xe6>
    iunlockput(ip);
801045b5:	83 ec 0c             	sub    $0xc,%esp
801045b8:	53                   	push   %ebx
801045b9:	e8 6a d1 ff ff       	call   80101728 <iunlockput>
    end_op();
801045be:	e8 e4 e2 ff ff       	call   801028a7 <end_op>
    return -1;
801045c3:	83 c4 10             	add    $0x10,%esp
801045c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045cb:	eb d5                	jmp    801045a2 <sys_link+0xe6>
    iunlockput(dp);
801045cd:	83 ec 0c             	sub    $0xc,%esp
801045d0:	56                   	push   %esi
801045d1:	e8 52 d1 ff ff       	call   80101728 <iunlockput>
    goto bad;
801045d6:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
801045d9:	83 ec 0c             	sub    $0xc,%esp
801045dc:	53                   	push   %ebx
801045dd:	e8 9f cf ff ff       	call   80101581 <ilock>
  ip->nlink--;
801045e2:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801045e6:	83 e8 01             	sub    $0x1,%eax
801045e9:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801045ed:	89 1c 24             	mov    %ebx,(%esp)
801045f0:	e8 2b ce ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
801045f5:	89 1c 24             	mov    %ebx,(%esp)
801045f8:	e8 2b d1 ff ff       	call   80101728 <iunlockput>
  end_op();
801045fd:	e8 a5 e2 ff ff       	call   801028a7 <end_op>
  return -1;
80104602:	83 c4 10             	add    $0x10,%esp
80104605:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010460a:	eb 96                	jmp    801045a2 <sys_link+0xe6>
    return -1;
8010460c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104611:	eb 8f                	jmp    801045a2 <sys_link+0xe6>
80104613:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104618:	eb 88                	jmp    801045a2 <sys_link+0xe6>

8010461a <sys_unlink>:
{
8010461a:	55                   	push   %ebp
8010461b:	89 e5                	mov    %esp,%ebp
8010461d:	57                   	push   %edi
8010461e:	56                   	push   %esi
8010461f:	53                   	push   %ebx
80104620:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
80104623:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104626:	50                   	push   %eax
80104627:	6a 00                	push   $0x0
80104629:	e8 d7 f9 ff ff       	call   80104005 <argstr>
8010462e:	83 c4 10             	add    $0x10,%esp
80104631:	85 c0                	test   %eax,%eax
80104633:	0f 88 83 01 00 00    	js     801047bc <sys_unlink+0x1a2>
  begin_op();
80104639:	e8 ef e1 ff ff       	call   8010282d <begin_op>
  if((dp = nameiparent(path, name)) == 0){
8010463e:	83 ec 08             	sub    $0x8,%esp
80104641:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104644:	50                   	push   %eax
80104645:	ff 75 c4             	pushl  -0x3c(%ebp)
80104648:	e8 ac d5 ff ff       	call   80101bf9 <nameiparent>
8010464d:	89 c6                	mov    %eax,%esi
8010464f:	83 c4 10             	add    $0x10,%esp
80104652:	85 c0                	test   %eax,%eax
80104654:	0f 84 ed 00 00 00    	je     80104747 <sys_unlink+0x12d>
  ilock(dp);
8010465a:	83 ec 0c             	sub    $0xc,%esp
8010465d:	50                   	push   %eax
8010465e:	e8 1e cf ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80104663:	83 c4 08             	add    $0x8,%esp
80104666:	68 1e 6d 10 80       	push   $0x80106d1e
8010466b:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010466e:	50                   	push   %eax
8010466f:	e8 27 d3 ff ff       	call   8010199b <namecmp>
80104674:	83 c4 10             	add    $0x10,%esp
80104677:	85 c0                	test   %eax,%eax
80104679:	0f 84 fc 00 00 00    	je     8010477b <sys_unlink+0x161>
8010467f:	83 ec 08             	sub    $0x8,%esp
80104682:	68 1d 6d 10 80       	push   $0x80106d1d
80104687:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010468a:	50                   	push   %eax
8010468b:	e8 0b d3 ff ff       	call   8010199b <namecmp>
80104690:	83 c4 10             	add    $0x10,%esp
80104693:	85 c0                	test   %eax,%eax
80104695:	0f 84 e0 00 00 00    	je     8010477b <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
8010469b:	83 ec 04             	sub    $0x4,%esp
8010469e:	8d 45 c0             	lea    -0x40(%ebp),%eax
801046a1:	50                   	push   %eax
801046a2:	8d 45 ca             	lea    -0x36(%ebp),%eax
801046a5:	50                   	push   %eax
801046a6:	56                   	push   %esi
801046a7:	e8 04 d3 ff ff       	call   801019b0 <dirlookup>
801046ac:	89 c3                	mov    %eax,%ebx
801046ae:	83 c4 10             	add    $0x10,%esp
801046b1:	85 c0                	test   %eax,%eax
801046b3:	0f 84 c2 00 00 00    	je     8010477b <sys_unlink+0x161>
  ilock(ip);
801046b9:	83 ec 0c             	sub    $0xc,%esp
801046bc:	50                   	push   %eax
801046bd:	e8 bf ce ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
801046c2:	83 c4 10             	add    $0x10,%esp
801046c5:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801046ca:	0f 8e 83 00 00 00    	jle    80104753 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
801046d0:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801046d5:	0f 84 85 00 00 00    	je     80104760 <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
801046db:	83 ec 04             	sub    $0x4,%esp
801046de:	6a 10                	push   $0x10
801046e0:	6a 00                	push   $0x0
801046e2:	8d 7d d8             	lea    -0x28(%ebp),%edi
801046e5:	57                   	push   %edi
801046e6:	e8 3f f6 ff ff       	call   80103d2a <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801046eb:	6a 10                	push   $0x10
801046ed:	ff 75 c0             	pushl  -0x40(%ebp)
801046f0:	57                   	push   %edi
801046f1:	56                   	push   %esi
801046f2:	e8 79 d1 ff ff       	call   80101870 <writei>
801046f7:	83 c4 20             	add    $0x20,%esp
801046fa:	83 f8 10             	cmp    $0x10,%eax
801046fd:	0f 85 90 00 00 00    	jne    80104793 <sys_unlink+0x179>
  if(ip->type == T_DIR){
80104703:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104708:	0f 84 92 00 00 00    	je     801047a0 <sys_unlink+0x186>
  iunlockput(dp);
8010470e:	83 ec 0c             	sub    $0xc,%esp
80104711:	56                   	push   %esi
80104712:	e8 11 d0 ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
80104717:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010471b:	83 e8 01             	sub    $0x1,%eax
8010471e:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104722:	89 1c 24             	mov    %ebx,(%esp)
80104725:	e8 f6 cc ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
8010472a:	89 1c 24             	mov    %ebx,(%esp)
8010472d:	e8 f6 cf ff ff       	call   80101728 <iunlockput>
  end_op();
80104732:	e8 70 e1 ff ff       	call   801028a7 <end_op>
  return 0;
80104737:	83 c4 10             	add    $0x10,%esp
8010473a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010473f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104742:	5b                   	pop    %ebx
80104743:	5e                   	pop    %esi
80104744:	5f                   	pop    %edi
80104745:	5d                   	pop    %ebp
80104746:	c3                   	ret    
    end_op();
80104747:	e8 5b e1 ff ff       	call   801028a7 <end_op>
    return -1;
8010474c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104751:	eb ec                	jmp    8010473f <sys_unlink+0x125>
    panic("unlink: nlink < 1");
80104753:	83 ec 0c             	sub    $0xc,%esp
80104756:	68 3c 6d 10 80       	push   $0x80106d3c
8010475b:	e8 e8 bb ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104760:	89 d8                	mov    %ebx,%eax
80104762:	e8 c4 f9 ff ff       	call   8010412b <isdirempty>
80104767:	85 c0                	test   %eax,%eax
80104769:	0f 85 6c ff ff ff    	jne    801046db <sys_unlink+0xc1>
    iunlockput(ip);
8010476f:	83 ec 0c             	sub    $0xc,%esp
80104772:	53                   	push   %ebx
80104773:	e8 b0 cf ff ff       	call   80101728 <iunlockput>
    goto bad;
80104778:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
8010477b:	83 ec 0c             	sub    $0xc,%esp
8010477e:	56                   	push   %esi
8010477f:	e8 a4 cf ff ff       	call   80101728 <iunlockput>
  end_op();
80104784:	e8 1e e1 ff ff       	call   801028a7 <end_op>
  return -1;
80104789:	83 c4 10             	add    $0x10,%esp
8010478c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104791:	eb ac                	jmp    8010473f <sys_unlink+0x125>
    panic("unlink: writei");
80104793:	83 ec 0c             	sub    $0xc,%esp
80104796:	68 4e 6d 10 80       	push   $0x80106d4e
8010479b:	e8 a8 bb ff ff       	call   80100348 <panic>
    dp->nlink--;
801047a0:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801047a4:	83 e8 01             	sub    $0x1,%eax
801047a7:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801047ab:	83 ec 0c             	sub    $0xc,%esp
801047ae:	56                   	push   %esi
801047af:	e8 6c cc ff ff       	call   80101420 <iupdate>
801047b4:	83 c4 10             	add    $0x10,%esp
801047b7:	e9 52 ff ff ff       	jmp    8010470e <sys_unlink+0xf4>
    return -1;
801047bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047c1:	e9 79 ff ff ff       	jmp    8010473f <sys_unlink+0x125>

801047c6 <sys_open>:

int
sys_open(void)
{
801047c6:	55                   	push   %ebp
801047c7:	89 e5                	mov    %esp,%ebp
801047c9:	57                   	push   %edi
801047ca:	56                   	push   %esi
801047cb:	53                   	push   %ebx
801047cc:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801047cf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801047d2:	50                   	push   %eax
801047d3:	6a 00                	push   $0x0
801047d5:	e8 2b f8 ff ff       	call   80104005 <argstr>
801047da:	83 c4 10             	add    $0x10,%esp
801047dd:	85 c0                	test   %eax,%eax
801047df:	0f 88 30 01 00 00    	js     80104915 <sys_open+0x14f>
801047e5:	83 ec 08             	sub    $0x8,%esp
801047e8:	8d 45 e0             	lea    -0x20(%ebp),%eax
801047eb:	50                   	push   %eax
801047ec:	6a 01                	push   $0x1
801047ee:	e8 82 f7 ff ff       	call   80103f75 <argint>
801047f3:	83 c4 10             	add    $0x10,%esp
801047f6:	85 c0                	test   %eax,%eax
801047f8:	0f 88 21 01 00 00    	js     8010491f <sys_open+0x159>
    return -1;

  begin_op();
801047fe:	e8 2a e0 ff ff       	call   8010282d <begin_op>

  if(omode & O_CREATE){
80104803:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
80104807:	0f 84 84 00 00 00    	je     80104891 <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
8010480d:	83 ec 0c             	sub    $0xc,%esp
80104810:	6a 00                	push   $0x0
80104812:	b9 00 00 00 00       	mov    $0x0,%ecx
80104817:	ba 02 00 00 00       	mov    $0x2,%edx
8010481c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010481f:	e8 5e f9 ff ff       	call   80104182 <create>
80104824:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104826:	83 c4 10             	add    $0x10,%esp
80104829:	85 c0                	test   %eax,%eax
8010482b:	74 58                	je     80104885 <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
8010482d:	e8 fb c3 ff ff       	call   80100c2d <filealloc>
80104832:	89 c3                	mov    %eax,%ebx
80104834:	85 c0                	test   %eax,%eax
80104836:	0f 84 ae 00 00 00    	je     801048ea <sys_open+0x124>
8010483c:	e8 b3 f8 ff ff       	call   801040f4 <fdalloc>
80104841:	89 c7                	mov    %eax,%edi
80104843:	85 c0                	test   %eax,%eax
80104845:	0f 88 9f 00 00 00    	js     801048ea <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
8010484b:	83 ec 0c             	sub    $0xc,%esp
8010484e:	56                   	push   %esi
8010484f:	e8 ef cd ff ff       	call   80101643 <iunlock>
  end_op();
80104854:	e8 4e e0 ff ff       	call   801028a7 <end_op>

  f->type = FD_INODE;
80104859:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
8010485f:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104862:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
80104869:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010486c:	83 c4 10             	add    $0x10,%esp
8010486f:	a8 01                	test   $0x1,%al
80104871:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80104875:	a8 03                	test   $0x3,%al
80104877:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
8010487b:	89 f8                	mov    %edi,%eax
8010487d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104880:	5b                   	pop    %ebx
80104881:	5e                   	pop    %esi
80104882:	5f                   	pop    %edi
80104883:	5d                   	pop    %ebp
80104884:	c3                   	ret    
      end_op();
80104885:	e8 1d e0 ff ff       	call   801028a7 <end_op>
      return -1;
8010488a:	bf ff ff ff ff       	mov    $0xffffffff,%edi
8010488f:	eb ea                	jmp    8010487b <sys_open+0xb5>
    if((ip = namei(path)) == 0){
80104891:	83 ec 0c             	sub    $0xc,%esp
80104894:	ff 75 e4             	pushl  -0x1c(%ebp)
80104897:	e8 45 d3 ff ff       	call   80101be1 <namei>
8010489c:	89 c6                	mov    %eax,%esi
8010489e:	83 c4 10             	add    $0x10,%esp
801048a1:	85 c0                	test   %eax,%eax
801048a3:	74 39                	je     801048de <sys_open+0x118>
    ilock(ip);
801048a5:	83 ec 0c             	sub    $0xc,%esp
801048a8:	50                   	push   %eax
801048a9:	e8 d3 cc ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
801048ae:	83 c4 10             	add    $0x10,%esp
801048b1:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
801048b6:	0f 85 71 ff ff ff    	jne    8010482d <sys_open+0x67>
801048bc:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801048c0:	0f 84 67 ff ff ff    	je     8010482d <sys_open+0x67>
      iunlockput(ip);
801048c6:	83 ec 0c             	sub    $0xc,%esp
801048c9:	56                   	push   %esi
801048ca:	e8 59 ce ff ff       	call   80101728 <iunlockput>
      end_op();
801048cf:	e8 d3 df ff ff       	call   801028a7 <end_op>
      return -1;
801048d4:	83 c4 10             	add    $0x10,%esp
801048d7:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801048dc:	eb 9d                	jmp    8010487b <sys_open+0xb5>
      end_op();
801048de:	e8 c4 df ff ff       	call   801028a7 <end_op>
      return -1;
801048e3:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801048e8:	eb 91                	jmp    8010487b <sys_open+0xb5>
    if(f)
801048ea:	85 db                	test   %ebx,%ebx
801048ec:	74 0c                	je     801048fa <sys_open+0x134>
      fileclose(f);
801048ee:	83 ec 0c             	sub    $0xc,%esp
801048f1:	53                   	push   %ebx
801048f2:	e8 dc c3 ff ff       	call   80100cd3 <fileclose>
801048f7:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
801048fa:	83 ec 0c             	sub    $0xc,%esp
801048fd:	56                   	push   %esi
801048fe:	e8 25 ce ff ff       	call   80101728 <iunlockput>
    end_op();
80104903:	e8 9f df ff ff       	call   801028a7 <end_op>
    return -1;
80104908:	83 c4 10             	add    $0x10,%esp
8010490b:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104910:	e9 66 ff ff ff       	jmp    8010487b <sys_open+0xb5>
    return -1;
80104915:	bf ff ff ff ff       	mov    $0xffffffff,%edi
8010491a:	e9 5c ff ff ff       	jmp    8010487b <sys_open+0xb5>
8010491f:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104924:	e9 52 ff ff ff       	jmp    8010487b <sys_open+0xb5>

80104929 <sys_mkdir>:

int
sys_mkdir(void)
{
80104929:	55                   	push   %ebp
8010492a:	89 e5                	mov    %esp,%ebp
8010492c:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
8010492f:	e8 f9 de ff ff       	call   8010282d <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104934:	83 ec 08             	sub    $0x8,%esp
80104937:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010493a:	50                   	push   %eax
8010493b:	6a 00                	push   $0x0
8010493d:	e8 c3 f6 ff ff       	call   80104005 <argstr>
80104942:	83 c4 10             	add    $0x10,%esp
80104945:	85 c0                	test   %eax,%eax
80104947:	78 36                	js     8010497f <sys_mkdir+0x56>
80104949:	83 ec 0c             	sub    $0xc,%esp
8010494c:	6a 00                	push   $0x0
8010494e:	b9 00 00 00 00       	mov    $0x0,%ecx
80104953:	ba 01 00 00 00       	mov    $0x1,%edx
80104958:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010495b:	e8 22 f8 ff ff       	call   80104182 <create>
80104960:	83 c4 10             	add    $0x10,%esp
80104963:	85 c0                	test   %eax,%eax
80104965:	74 18                	je     8010497f <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104967:	83 ec 0c             	sub    $0xc,%esp
8010496a:	50                   	push   %eax
8010496b:	e8 b8 cd ff ff       	call   80101728 <iunlockput>
  end_op();
80104970:	e8 32 df ff ff       	call   801028a7 <end_op>
  return 0;
80104975:	83 c4 10             	add    $0x10,%esp
80104978:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010497d:	c9                   	leave  
8010497e:	c3                   	ret    
    end_op();
8010497f:	e8 23 df ff ff       	call   801028a7 <end_op>
    return -1;
80104984:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104989:	eb f2                	jmp    8010497d <sys_mkdir+0x54>

8010498b <sys_mknod>:

int
sys_mknod(void)
{
8010498b:	55                   	push   %ebp
8010498c:	89 e5                	mov    %esp,%ebp
8010498e:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104991:	e8 97 de ff ff       	call   8010282d <begin_op>
  if((argstr(0, &path)) < 0 ||
80104996:	83 ec 08             	sub    $0x8,%esp
80104999:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010499c:	50                   	push   %eax
8010499d:	6a 00                	push   $0x0
8010499f:	e8 61 f6 ff ff       	call   80104005 <argstr>
801049a4:	83 c4 10             	add    $0x10,%esp
801049a7:	85 c0                	test   %eax,%eax
801049a9:	78 62                	js     80104a0d <sys_mknod+0x82>
     argint(1, &major) < 0 ||
801049ab:	83 ec 08             	sub    $0x8,%esp
801049ae:	8d 45 f0             	lea    -0x10(%ebp),%eax
801049b1:	50                   	push   %eax
801049b2:	6a 01                	push   $0x1
801049b4:	e8 bc f5 ff ff       	call   80103f75 <argint>
  if((argstr(0, &path)) < 0 ||
801049b9:	83 c4 10             	add    $0x10,%esp
801049bc:	85 c0                	test   %eax,%eax
801049be:	78 4d                	js     80104a0d <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
801049c0:	83 ec 08             	sub    $0x8,%esp
801049c3:	8d 45 ec             	lea    -0x14(%ebp),%eax
801049c6:	50                   	push   %eax
801049c7:	6a 02                	push   $0x2
801049c9:	e8 a7 f5 ff ff       	call   80103f75 <argint>
     argint(1, &major) < 0 ||
801049ce:	83 c4 10             	add    $0x10,%esp
801049d1:	85 c0                	test   %eax,%eax
801049d3:	78 38                	js     80104a0d <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
801049d5:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
801049d9:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
801049dd:	83 ec 0c             	sub    $0xc,%esp
801049e0:	50                   	push   %eax
801049e1:	ba 03 00 00 00       	mov    $0x3,%edx
801049e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049e9:	e8 94 f7 ff ff       	call   80104182 <create>
801049ee:	83 c4 10             	add    $0x10,%esp
801049f1:	85 c0                	test   %eax,%eax
801049f3:	74 18                	je     80104a0d <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
801049f5:	83 ec 0c             	sub    $0xc,%esp
801049f8:	50                   	push   %eax
801049f9:	e8 2a cd ff ff       	call   80101728 <iunlockput>
  end_op();
801049fe:	e8 a4 de ff ff       	call   801028a7 <end_op>
  return 0;
80104a03:	83 c4 10             	add    $0x10,%esp
80104a06:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a0b:	c9                   	leave  
80104a0c:	c3                   	ret    
    end_op();
80104a0d:	e8 95 de ff ff       	call   801028a7 <end_op>
    return -1;
80104a12:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a17:	eb f2                	jmp    80104a0b <sys_mknod+0x80>

80104a19 <sys_chdir>:

int
sys_chdir(void)
{
80104a19:	55                   	push   %ebp
80104a1a:	89 e5                	mov    %esp,%ebp
80104a1c:	56                   	push   %esi
80104a1d:	53                   	push   %ebx
80104a1e:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104a21:	e8 57 e8 ff ff       	call   8010327d <myproc>
80104a26:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104a28:	e8 00 de ff ff       	call   8010282d <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104a2d:	83 ec 08             	sub    $0x8,%esp
80104a30:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104a33:	50                   	push   %eax
80104a34:	6a 00                	push   $0x0
80104a36:	e8 ca f5 ff ff       	call   80104005 <argstr>
80104a3b:	83 c4 10             	add    $0x10,%esp
80104a3e:	85 c0                	test   %eax,%eax
80104a40:	78 52                	js     80104a94 <sys_chdir+0x7b>
80104a42:	83 ec 0c             	sub    $0xc,%esp
80104a45:	ff 75 f4             	pushl  -0xc(%ebp)
80104a48:	e8 94 d1 ff ff       	call   80101be1 <namei>
80104a4d:	89 c3                	mov    %eax,%ebx
80104a4f:	83 c4 10             	add    $0x10,%esp
80104a52:	85 c0                	test   %eax,%eax
80104a54:	74 3e                	je     80104a94 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104a56:	83 ec 0c             	sub    $0xc,%esp
80104a59:	50                   	push   %eax
80104a5a:	e8 22 cb ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104a5f:	83 c4 10             	add    $0x10,%esp
80104a62:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104a67:	75 37                	jne    80104aa0 <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104a69:	83 ec 0c             	sub    $0xc,%esp
80104a6c:	53                   	push   %ebx
80104a6d:	e8 d1 cb ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104a72:	83 c4 04             	add    $0x4,%esp
80104a75:	ff 76 68             	pushl  0x68(%esi)
80104a78:	e8 0b cc ff ff       	call   80101688 <iput>
  end_op();
80104a7d:	e8 25 de ff ff       	call   801028a7 <end_op>
  curproc->cwd = ip;
80104a82:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104a85:	83 c4 10             	add    $0x10,%esp
80104a88:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a8d:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104a90:	5b                   	pop    %ebx
80104a91:	5e                   	pop    %esi
80104a92:	5d                   	pop    %ebp
80104a93:	c3                   	ret    
    end_op();
80104a94:	e8 0e de ff ff       	call   801028a7 <end_op>
    return -1;
80104a99:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a9e:	eb ed                	jmp    80104a8d <sys_chdir+0x74>
    iunlockput(ip);
80104aa0:	83 ec 0c             	sub    $0xc,%esp
80104aa3:	53                   	push   %ebx
80104aa4:	e8 7f cc ff ff       	call   80101728 <iunlockput>
    end_op();
80104aa9:	e8 f9 dd ff ff       	call   801028a7 <end_op>
    return -1;
80104aae:	83 c4 10             	add    $0x10,%esp
80104ab1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ab6:	eb d5                	jmp    80104a8d <sys_chdir+0x74>

80104ab8 <sys_exec>:

int
sys_exec(void)
{
80104ab8:	55                   	push   %ebp
80104ab9:	89 e5                	mov    %esp,%ebp
80104abb:	53                   	push   %ebx
80104abc:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104ac2:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ac5:	50                   	push   %eax
80104ac6:	6a 00                	push   $0x0
80104ac8:	e8 38 f5 ff ff       	call   80104005 <argstr>
80104acd:	83 c4 10             	add    $0x10,%esp
80104ad0:	85 c0                	test   %eax,%eax
80104ad2:	0f 88 a8 00 00 00    	js     80104b80 <sys_exec+0xc8>
80104ad8:	83 ec 08             	sub    $0x8,%esp
80104adb:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104ae1:	50                   	push   %eax
80104ae2:	6a 01                	push   $0x1
80104ae4:	e8 8c f4 ff ff       	call   80103f75 <argint>
80104ae9:	83 c4 10             	add    $0x10,%esp
80104aec:	85 c0                	test   %eax,%eax
80104aee:	0f 88 93 00 00 00    	js     80104b87 <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104af4:	83 ec 04             	sub    $0x4,%esp
80104af7:	68 80 00 00 00       	push   $0x80
80104afc:	6a 00                	push   $0x0
80104afe:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104b04:	50                   	push   %eax
80104b05:	e8 20 f2 ff ff       	call   80103d2a <memset>
80104b0a:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104b0d:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104b12:	83 fb 1f             	cmp    $0x1f,%ebx
80104b15:	77 77                	ja     80104b8e <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104b17:	83 ec 08             	sub    $0x8,%esp
80104b1a:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104b20:	50                   	push   %eax
80104b21:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104b27:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104b2a:	50                   	push   %eax
80104b2b:	e8 c9 f3 ff ff       	call   80103ef9 <fetchint>
80104b30:	83 c4 10             	add    $0x10,%esp
80104b33:	85 c0                	test   %eax,%eax
80104b35:	78 5e                	js     80104b95 <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104b37:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104b3d:	85 c0                	test   %eax,%eax
80104b3f:	74 1d                	je     80104b5e <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104b41:	83 ec 08             	sub    $0x8,%esp
80104b44:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104b4b:	52                   	push   %edx
80104b4c:	50                   	push   %eax
80104b4d:	e8 e3 f3 ff ff       	call   80103f35 <fetchstr>
80104b52:	83 c4 10             	add    $0x10,%esp
80104b55:	85 c0                	test   %eax,%eax
80104b57:	78 46                	js     80104b9f <sys_exec+0xe7>
  for(i=0;; i++){
80104b59:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104b5c:	eb b4                	jmp    80104b12 <sys_exec+0x5a>
      argv[i] = 0;
80104b5e:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104b65:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104b69:	83 ec 08             	sub    $0x8,%esp
80104b6c:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104b72:	50                   	push   %eax
80104b73:	ff 75 f4             	pushl  -0xc(%ebp)
80104b76:	e8 57 bd ff ff       	call   801008d2 <exec>
80104b7b:	83 c4 10             	add    $0x10,%esp
80104b7e:	eb 1a                	jmp    80104b9a <sys_exec+0xe2>
    return -1;
80104b80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b85:	eb 13                	jmp    80104b9a <sys_exec+0xe2>
80104b87:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b8c:	eb 0c                	jmp    80104b9a <sys_exec+0xe2>
      return -1;
80104b8e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b93:	eb 05                	jmp    80104b9a <sys_exec+0xe2>
      return -1;
80104b95:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104b9a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104b9d:	c9                   	leave  
80104b9e:	c3                   	ret    
      return -1;
80104b9f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ba4:	eb f4                	jmp    80104b9a <sys_exec+0xe2>

80104ba6 <sys_pipe>:

int
sys_pipe(void)
{
80104ba6:	55                   	push   %ebp
80104ba7:	89 e5                	mov    %esp,%ebp
80104ba9:	53                   	push   %ebx
80104baa:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104bad:	6a 08                	push   $0x8
80104baf:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104bb2:	50                   	push   %eax
80104bb3:	6a 00                	push   $0x0
80104bb5:	e8 e3 f3 ff ff       	call   80103f9d <argptr>
80104bba:	83 c4 10             	add    $0x10,%esp
80104bbd:	85 c0                	test   %eax,%eax
80104bbf:	78 77                	js     80104c38 <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104bc1:	83 ec 08             	sub    $0x8,%esp
80104bc4:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104bc7:	50                   	push   %eax
80104bc8:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104bcb:	50                   	push   %eax
80104bcc:	e8 e3 e1 ff ff       	call   80102db4 <pipealloc>
80104bd1:	83 c4 10             	add    $0x10,%esp
80104bd4:	85 c0                	test   %eax,%eax
80104bd6:	78 67                	js     80104c3f <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104bd8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104bdb:	e8 14 f5 ff ff       	call   801040f4 <fdalloc>
80104be0:	89 c3                	mov    %eax,%ebx
80104be2:	85 c0                	test   %eax,%eax
80104be4:	78 21                	js     80104c07 <sys_pipe+0x61>
80104be6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104be9:	e8 06 f5 ff ff       	call   801040f4 <fdalloc>
80104bee:	85 c0                	test   %eax,%eax
80104bf0:	78 15                	js     80104c07 <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104bf2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104bf5:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104bf7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104bfa:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104bfd:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104c02:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104c05:	c9                   	leave  
80104c06:	c3                   	ret    
    if(fd0 >= 0)
80104c07:	85 db                	test   %ebx,%ebx
80104c09:	78 0d                	js     80104c18 <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104c0b:	e8 6d e6 ff ff       	call   8010327d <myproc>
80104c10:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104c17:	00 
    fileclose(rf);
80104c18:	83 ec 0c             	sub    $0xc,%esp
80104c1b:	ff 75 f0             	pushl  -0x10(%ebp)
80104c1e:	e8 b0 c0 ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104c23:	83 c4 04             	add    $0x4,%esp
80104c26:	ff 75 ec             	pushl  -0x14(%ebp)
80104c29:	e8 a5 c0 ff ff       	call   80100cd3 <fileclose>
    return -1;
80104c2e:	83 c4 10             	add    $0x10,%esp
80104c31:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c36:	eb ca                	jmp    80104c02 <sys_pipe+0x5c>
    return -1;
80104c38:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c3d:	eb c3                	jmp    80104c02 <sys_pipe+0x5c>
    return -1;
80104c3f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c44:	eb bc                	jmp    80104c02 <sys_pipe+0x5c>

80104c46 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104c46:	55                   	push   %ebp
80104c47:	89 e5                	mov    %esp,%ebp
80104c49:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104c4c:	e8 a4 e7 ff ff       	call   801033f5 <fork>
}
80104c51:	c9                   	leave  
80104c52:	c3                   	ret    

80104c53 <sys_exit>:

int
sys_exit(void)
{
80104c53:	55                   	push   %ebp
80104c54:	89 e5                	mov    %esp,%ebp
80104c56:	83 ec 08             	sub    $0x8,%esp
  exit();
80104c59:	e8 cb e9 ff ff       	call   80103629 <exit>
  return 0;  // not reached
}
80104c5e:	b8 00 00 00 00       	mov    $0x0,%eax
80104c63:	c9                   	leave  
80104c64:	c3                   	ret    

80104c65 <sys_wait>:

int
sys_wait(void)
{
80104c65:	55                   	push   %ebp
80104c66:	89 e5                	mov    %esp,%ebp
80104c68:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104c6b:	e8 42 eb ff ff       	call   801037b2 <wait>
}
80104c70:	c9                   	leave  
80104c71:	c3                   	ret    

80104c72 <sys_kill>:

int
sys_kill(void)
{
80104c72:	55                   	push   %ebp
80104c73:	89 e5                	mov    %esp,%ebp
80104c75:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104c78:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c7b:	50                   	push   %eax
80104c7c:	6a 00                	push   $0x0
80104c7e:	e8 f2 f2 ff ff       	call   80103f75 <argint>
80104c83:	83 c4 10             	add    $0x10,%esp
80104c86:	85 c0                	test   %eax,%eax
80104c88:	78 10                	js     80104c9a <sys_kill+0x28>
    return -1;
  return kill(pid);
80104c8a:	83 ec 0c             	sub    $0xc,%esp
80104c8d:	ff 75 f4             	pushl  -0xc(%ebp)
80104c90:	e8 1a ec ff ff       	call   801038af <kill>
80104c95:	83 c4 10             	add    $0x10,%esp
}
80104c98:	c9                   	leave  
80104c99:	c3                   	ret    
    return -1;
80104c9a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c9f:	eb f7                	jmp    80104c98 <sys_kill+0x26>

80104ca1 <sys_getpid>:

int
sys_getpid(void)
{
80104ca1:	55                   	push   %ebp
80104ca2:	89 e5                	mov    %esp,%ebp
80104ca4:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104ca7:	e8 d1 e5 ff ff       	call   8010327d <myproc>
80104cac:	8b 40 10             	mov    0x10(%eax),%eax
}
80104caf:	c9                   	leave  
80104cb0:	c3                   	ret    

80104cb1 <sys_sbrk>:

int
sys_sbrk(void)
{
80104cb1:	55                   	push   %ebp
80104cb2:	89 e5                	mov    %esp,%ebp
80104cb4:	53                   	push   %ebx
80104cb5:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104cb8:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104cbb:	50                   	push   %eax
80104cbc:	6a 00                	push   $0x0
80104cbe:	e8 b2 f2 ff ff       	call   80103f75 <argint>
80104cc3:	83 c4 10             	add    $0x10,%esp
80104cc6:	85 c0                	test   %eax,%eax
80104cc8:	78 27                	js     80104cf1 <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104cca:	e8 ae e5 ff ff       	call   8010327d <myproc>
80104ccf:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104cd1:	83 ec 0c             	sub    $0xc,%esp
80104cd4:	ff 75 f4             	pushl  -0xc(%ebp)
80104cd7:	e8 ac e6 ff ff       	call   80103388 <growproc>
80104cdc:	83 c4 10             	add    $0x10,%esp
80104cdf:	85 c0                	test   %eax,%eax
80104ce1:	78 07                	js     80104cea <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104ce3:	89 d8                	mov    %ebx,%eax
80104ce5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104ce8:	c9                   	leave  
80104ce9:	c3                   	ret    
    return -1;
80104cea:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104cef:	eb f2                	jmp    80104ce3 <sys_sbrk+0x32>
    return -1;
80104cf1:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104cf6:	eb eb                	jmp    80104ce3 <sys_sbrk+0x32>

80104cf8 <sys_sleep>:

int
sys_sleep(void)
{
80104cf8:	55                   	push   %ebp
80104cf9:	89 e5                	mov    %esp,%ebp
80104cfb:	53                   	push   %ebx
80104cfc:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104cff:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d02:	50                   	push   %eax
80104d03:	6a 00                	push   $0x0
80104d05:	e8 6b f2 ff ff       	call   80103f75 <argint>
80104d0a:	83 c4 10             	add    $0x10,%esp
80104d0d:	85 c0                	test   %eax,%eax
80104d0f:	78 75                	js     80104d86 <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104d11:	83 ec 0c             	sub    $0xc,%esp
80104d14:	68 c0 3c 13 80       	push   $0x80133cc0
80104d19:	e8 60 ef ff ff       	call   80103c7e <acquire>
  ticks0 = ticks;
80104d1e:	8b 1d 00 45 13 80    	mov    0x80134500,%ebx
  while(ticks - ticks0 < n){
80104d24:	83 c4 10             	add    $0x10,%esp
80104d27:	a1 00 45 13 80       	mov    0x80134500,%eax
80104d2c:	29 d8                	sub    %ebx,%eax
80104d2e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104d31:	73 39                	jae    80104d6c <sys_sleep+0x74>
    if(myproc()->killed){
80104d33:	e8 45 e5 ff ff       	call   8010327d <myproc>
80104d38:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104d3c:	75 17                	jne    80104d55 <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104d3e:	83 ec 08             	sub    $0x8,%esp
80104d41:	68 c0 3c 13 80       	push   $0x80133cc0
80104d46:	68 00 45 13 80       	push   $0x80134500
80104d4b:	e8 d1 e9 ff ff       	call   80103721 <sleep>
80104d50:	83 c4 10             	add    $0x10,%esp
80104d53:	eb d2                	jmp    80104d27 <sys_sleep+0x2f>
      release(&tickslock);
80104d55:	83 ec 0c             	sub    $0xc,%esp
80104d58:	68 c0 3c 13 80       	push   $0x80133cc0
80104d5d:	e8 81 ef ff ff       	call   80103ce3 <release>
      return -1;
80104d62:	83 c4 10             	add    $0x10,%esp
80104d65:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d6a:	eb 15                	jmp    80104d81 <sys_sleep+0x89>
  }
  release(&tickslock);
80104d6c:	83 ec 0c             	sub    $0xc,%esp
80104d6f:	68 c0 3c 13 80       	push   $0x80133cc0
80104d74:	e8 6a ef ff ff       	call   80103ce3 <release>
  return 0;
80104d79:	83 c4 10             	add    $0x10,%esp
80104d7c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104d81:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104d84:	c9                   	leave  
80104d85:	c3                   	ret    
    return -1;
80104d86:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d8b:	eb f4                	jmp    80104d81 <sys_sleep+0x89>

80104d8d <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104d8d:	55                   	push   %ebp
80104d8e:	89 e5                	mov    %esp,%ebp
80104d90:	53                   	push   %ebx
80104d91:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104d94:	68 c0 3c 13 80       	push   $0x80133cc0
80104d99:	e8 e0 ee ff ff       	call   80103c7e <acquire>
  xticks = ticks;
80104d9e:	8b 1d 00 45 13 80    	mov    0x80134500,%ebx
  release(&tickslock);
80104da4:	c7 04 24 c0 3c 13 80 	movl   $0x80133cc0,(%esp)
80104dab:	e8 33 ef ff ff       	call   80103ce3 <release>
  return xticks;
}
80104db0:	89 d8                	mov    %ebx,%eax
80104db2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104db5:	c9                   	leave  
80104db6:	c3                   	ret    

80104db7 <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80104db7:	55                   	push   %ebp
80104db8:	89 e5                	mov    %esp,%ebp
80104dba:	83 ec 1c             	sub    $0x1c,%esp
  int *frames;
  int *pids;
  int numframes;
  if(argptr(0, (char**)(&frames), sizeof(*frames)) < 0)
80104dbd:	6a 04                	push   $0x4
80104dbf:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104dc2:	50                   	push   %eax
80104dc3:	6a 00                	push   $0x0
80104dc5:	e8 d3 f1 ff ff       	call   80103f9d <argptr>
80104dca:	83 c4 10             	add    $0x10,%esp
80104dcd:	85 c0                	test   %eax,%eax
80104dcf:	78 42                	js     80104e13 <sys_dump_physmem+0x5c>
    return -1;
  if(argptr(1, (char**)(&pids), sizeof(*pids)) < 0)
80104dd1:	83 ec 04             	sub    $0x4,%esp
80104dd4:	6a 04                	push   $0x4
80104dd6:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104dd9:	50                   	push   %eax
80104dda:	6a 01                	push   $0x1
80104ddc:	e8 bc f1 ff ff       	call   80103f9d <argptr>
80104de1:	83 c4 10             	add    $0x10,%esp
80104de4:	85 c0                	test   %eax,%eax
80104de6:	78 32                	js     80104e1a <sys_dump_physmem+0x63>
    return -1;
  if(argint(2, &numframes) < 0)
80104de8:	83 ec 08             	sub    $0x8,%esp
80104deb:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104dee:	50                   	push   %eax
80104def:	6a 02                	push   $0x2
80104df1:	e8 7f f1 ff ff       	call   80103f75 <argint>
80104df6:	83 c4 10             	add    $0x10,%esp
80104df9:	85 c0                	test   %eax,%eax
80104dfb:	78 24                	js     80104e21 <sys_dump_physmem+0x6a>
    return -1;

  return dump_physmem(frames, pids, numframes);
80104dfd:	83 ec 04             	sub    $0x4,%esp
80104e00:	ff 75 ec             	pushl  -0x14(%ebp)
80104e03:	ff 75 f0             	pushl  -0x10(%ebp)
80104e06:	ff 75 f4             	pushl  -0xc(%ebp)
80104e09:	e8 c7 eb ff ff       	call   801039d5 <dump_physmem>
80104e0e:	83 c4 10             	add    $0x10,%esp
80104e11:	c9                   	leave  
80104e12:	c3                   	ret    
    return -1;
80104e13:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e18:	eb f7                	jmp    80104e11 <sys_dump_physmem+0x5a>
    return -1;
80104e1a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e1f:	eb f0                	jmp    80104e11 <sys_dump_physmem+0x5a>
    return -1;
80104e21:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e26:	eb e9                	jmp    80104e11 <sys_dump_physmem+0x5a>

80104e28 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104e28:	1e                   	push   %ds
  pushl %es
80104e29:	06                   	push   %es
  pushl %fs
80104e2a:	0f a0                	push   %fs
  pushl %gs
80104e2c:	0f a8                	push   %gs
  pushal
80104e2e:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104e2f:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104e33:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104e35:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104e37:	54                   	push   %esp
  call trap
80104e38:	e8 e3 00 00 00       	call   80104f20 <trap>
  addl $4, %esp
80104e3d:	83 c4 04             	add    $0x4,%esp

80104e40 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104e40:	61                   	popa   
  popl %gs
80104e41:	0f a9                	pop    %gs
  popl %fs
80104e43:	0f a1                	pop    %fs
  popl %es
80104e45:	07                   	pop    %es
  popl %ds
80104e46:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104e47:	83 c4 08             	add    $0x8,%esp
  iret
80104e4a:	cf                   	iret   

80104e4b <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80104e4b:	55                   	push   %ebp
80104e4c:	89 e5                	mov    %esp,%ebp
80104e4e:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
80104e51:	b8 00 00 00 00       	mov    $0x0,%eax
80104e56:	eb 4a                	jmp    80104ea2 <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104e58:	8b 0c 85 08 90 10 80 	mov    -0x7fef6ff8(,%eax,4),%ecx
80104e5f:	66 89 0c c5 00 3d 13 	mov    %cx,-0x7fecc300(,%eax,8)
80104e66:	80 
80104e67:	66 c7 04 c5 02 3d 13 	movw   $0x8,-0x7fecc2fe(,%eax,8)
80104e6e:	80 08 00 
80104e71:	c6 04 c5 04 3d 13 80 	movb   $0x0,-0x7fecc2fc(,%eax,8)
80104e78:	00 
80104e79:	0f b6 14 c5 05 3d 13 	movzbl -0x7fecc2fb(,%eax,8),%edx
80104e80:	80 
80104e81:	83 e2 f0             	and    $0xfffffff0,%edx
80104e84:	83 ca 0e             	or     $0xe,%edx
80104e87:	83 e2 8f             	and    $0xffffff8f,%edx
80104e8a:	83 ca 80             	or     $0xffffff80,%edx
80104e8d:	88 14 c5 05 3d 13 80 	mov    %dl,-0x7fecc2fb(,%eax,8)
80104e94:	c1 e9 10             	shr    $0x10,%ecx
80104e97:	66 89 0c c5 06 3d 13 	mov    %cx,-0x7fecc2fa(,%eax,8)
80104e9e:	80 
  for(i = 0; i < 256; i++)
80104e9f:	83 c0 01             	add    $0x1,%eax
80104ea2:	3d ff 00 00 00       	cmp    $0xff,%eax
80104ea7:	7e af                	jle    80104e58 <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80104ea9:	8b 15 08 91 10 80    	mov    0x80109108,%edx
80104eaf:	66 89 15 00 3f 13 80 	mov    %dx,0x80133f00
80104eb6:	66 c7 05 02 3f 13 80 	movw   $0x8,0x80133f02
80104ebd:	08 00 
80104ebf:	c6 05 04 3f 13 80 00 	movb   $0x0,0x80133f04
80104ec6:	0f b6 05 05 3f 13 80 	movzbl 0x80133f05,%eax
80104ecd:	83 c8 0f             	or     $0xf,%eax
80104ed0:	83 e0 ef             	and    $0xffffffef,%eax
80104ed3:	83 c8 e0             	or     $0xffffffe0,%eax
80104ed6:	a2 05 3f 13 80       	mov    %al,0x80133f05
80104edb:	c1 ea 10             	shr    $0x10,%edx
80104ede:	66 89 15 06 3f 13 80 	mov    %dx,0x80133f06

  initlock(&tickslock, "time");
80104ee5:	83 ec 08             	sub    $0x8,%esp
80104ee8:	68 5d 6d 10 80       	push   $0x80106d5d
80104eed:	68 c0 3c 13 80       	push   $0x80133cc0
80104ef2:	e8 4b ec ff ff       	call   80103b42 <initlock>
}
80104ef7:	83 c4 10             	add    $0x10,%esp
80104efa:	c9                   	leave  
80104efb:	c3                   	ret    

80104efc <idtinit>:

void
idtinit(void)
{
80104efc:	55                   	push   %ebp
80104efd:	89 e5                	mov    %esp,%ebp
80104eff:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80104f02:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80104f08:	b8 00 3d 13 80       	mov    $0x80133d00,%eax
80104f0d:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80104f11:	c1 e8 10             	shr    $0x10,%eax
80104f14:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
80104f18:	8d 45 fa             	lea    -0x6(%ebp),%eax
80104f1b:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80104f1e:	c9                   	leave  
80104f1f:	c3                   	ret    

80104f20 <trap>:

void
trap(struct trapframe *tf)
{
80104f20:	55                   	push   %ebp
80104f21:	89 e5                	mov    %esp,%ebp
80104f23:	57                   	push   %edi
80104f24:	56                   	push   %esi
80104f25:	53                   	push   %ebx
80104f26:	83 ec 1c             	sub    $0x1c,%esp
80104f29:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80104f2c:	8b 43 30             	mov    0x30(%ebx),%eax
80104f2f:	83 f8 40             	cmp    $0x40,%eax
80104f32:	74 13                	je     80104f47 <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
80104f34:	83 e8 20             	sub    $0x20,%eax
80104f37:	83 f8 1f             	cmp    $0x1f,%eax
80104f3a:	0f 87 3a 01 00 00    	ja     8010507a <trap+0x15a>
80104f40:	ff 24 85 04 6e 10 80 	jmp    *-0x7fef91fc(,%eax,4)
    if(myproc()->killed)
80104f47:	e8 31 e3 ff ff       	call   8010327d <myproc>
80104f4c:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f50:	75 1f                	jne    80104f71 <trap+0x51>
    myproc()->tf = tf;
80104f52:	e8 26 e3 ff ff       	call   8010327d <myproc>
80104f57:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80104f5a:	e8 d9 f0 ff ff       	call   80104038 <syscall>
    if(myproc()->killed)
80104f5f:	e8 19 e3 ff ff       	call   8010327d <myproc>
80104f64:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f68:	74 7e                	je     80104fe8 <trap+0xc8>
      exit();
80104f6a:	e8 ba e6 ff ff       	call   80103629 <exit>
80104f6f:	eb 77                	jmp    80104fe8 <trap+0xc8>
      exit();
80104f71:	e8 b3 e6 ff ff       	call   80103629 <exit>
80104f76:	eb da                	jmp    80104f52 <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80104f78:	e8 e5 e2 ff ff       	call   80103262 <cpuid>
80104f7d:	85 c0                	test   %eax,%eax
80104f7f:	74 6f                	je     80104ff0 <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
80104f81:	e8 92 d4 ff ff       	call   80102418 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80104f86:	e8 f2 e2 ff ff       	call   8010327d <myproc>
80104f8b:	85 c0                	test   %eax,%eax
80104f8d:	74 1c                	je     80104fab <trap+0x8b>
80104f8f:	e8 e9 e2 ff ff       	call   8010327d <myproc>
80104f94:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f98:	74 11                	je     80104fab <trap+0x8b>
80104f9a:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80104f9e:	83 e0 03             	and    $0x3,%eax
80104fa1:	66 83 f8 03          	cmp    $0x3,%ax
80104fa5:	0f 84 62 01 00 00    	je     8010510d <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80104fab:	e8 cd e2 ff ff       	call   8010327d <myproc>
80104fb0:	85 c0                	test   %eax,%eax
80104fb2:	74 0f                	je     80104fc3 <trap+0xa3>
80104fb4:	e8 c4 e2 ff ff       	call   8010327d <myproc>
80104fb9:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80104fbd:	0f 84 54 01 00 00    	je     80105117 <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80104fc3:	e8 b5 e2 ff ff       	call   8010327d <myproc>
80104fc8:	85 c0                	test   %eax,%eax
80104fca:	74 1c                	je     80104fe8 <trap+0xc8>
80104fcc:	e8 ac e2 ff ff       	call   8010327d <myproc>
80104fd1:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104fd5:	74 11                	je     80104fe8 <trap+0xc8>
80104fd7:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80104fdb:	83 e0 03             	and    $0x3,%eax
80104fde:	66 83 f8 03          	cmp    $0x3,%ax
80104fe2:	0f 84 43 01 00 00    	je     8010512b <trap+0x20b>
    exit();
}
80104fe8:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104feb:	5b                   	pop    %ebx
80104fec:	5e                   	pop    %esi
80104fed:	5f                   	pop    %edi
80104fee:	5d                   	pop    %ebp
80104fef:	c3                   	ret    
      acquire(&tickslock);
80104ff0:	83 ec 0c             	sub    $0xc,%esp
80104ff3:	68 c0 3c 13 80       	push   $0x80133cc0
80104ff8:	e8 81 ec ff ff       	call   80103c7e <acquire>
      ticks++;
80104ffd:	83 05 00 45 13 80 01 	addl   $0x1,0x80134500
      wakeup(&ticks);
80105004:	c7 04 24 00 45 13 80 	movl   $0x80134500,(%esp)
8010500b:	e8 76 e8 ff ff       	call   80103886 <wakeup>
      release(&tickslock);
80105010:	c7 04 24 c0 3c 13 80 	movl   $0x80133cc0,(%esp)
80105017:	e8 c7 ec ff ff       	call   80103ce3 <release>
8010501c:	83 c4 10             	add    $0x10,%esp
8010501f:	e9 5d ff ff ff       	jmp    80104f81 <trap+0x61>
    ideintr();
80105024:	e8 4a cd ff ff       	call   80101d73 <ideintr>
    lapiceoi();
80105029:	e8 ea d3 ff ff       	call   80102418 <lapiceoi>
    break;
8010502e:	e9 53 ff ff ff       	jmp    80104f86 <trap+0x66>
    kbdintr();
80105033:	e8 24 d2 ff ff       	call   8010225c <kbdintr>
    lapiceoi();
80105038:	e8 db d3 ff ff       	call   80102418 <lapiceoi>
    break;
8010503d:	e9 44 ff ff ff       	jmp    80104f86 <trap+0x66>
    uartintr();
80105042:	e8 05 02 00 00       	call   8010524c <uartintr>
    lapiceoi();
80105047:	e8 cc d3 ff ff       	call   80102418 <lapiceoi>
    break;
8010504c:	e9 35 ff ff ff       	jmp    80104f86 <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105051:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
80105054:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105058:	e8 05 e2 ff ff       	call   80103262 <cpuid>
8010505d:	57                   	push   %edi
8010505e:	0f b7 f6             	movzwl %si,%esi
80105061:	56                   	push   %esi
80105062:	50                   	push   %eax
80105063:	68 68 6d 10 80       	push   $0x80106d68
80105068:	e8 9e b5 ff ff       	call   8010060b <cprintf>
    lapiceoi();
8010506d:	e8 a6 d3 ff ff       	call   80102418 <lapiceoi>
    break;
80105072:	83 c4 10             	add    $0x10,%esp
80105075:	e9 0c ff ff ff       	jmp    80104f86 <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
8010507a:	e8 fe e1 ff ff       	call   8010327d <myproc>
8010507f:	85 c0                	test   %eax,%eax
80105081:	74 5f                	je     801050e2 <trap+0x1c2>
80105083:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
80105087:	74 59                	je     801050e2 <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80105089:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010508c:	8b 43 38             	mov    0x38(%ebx),%eax
8010508f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105092:	e8 cb e1 ff ff       	call   80103262 <cpuid>
80105097:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010509a:	8b 53 34             	mov    0x34(%ebx),%edx
8010509d:	89 55 dc             	mov    %edx,-0x24(%ebp)
801050a0:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
801050a3:	e8 d5 e1 ff ff       	call   8010327d <myproc>
801050a8:	8d 48 6c             	lea    0x6c(%eax),%ecx
801050ab:	89 4d d8             	mov    %ecx,-0x28(%ebp)
801050ae:	e8 ca e1 ff ff       	call   8010327d <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801050b3:	57                   	push   %edi
801050b4:	ff 75 e4             	pushl  -0x1c(%ebp)
801050b7:	ff 75 e0             	pushl  -0x20(%ebp)
801050ba:	ff 75 dc             	pushl  -0x24(%ebp)
801050bd:	56                   	push   %esi
801050be:	ff 75 d8             	pushl  -0x28(%ebp)
801050c1:	ff 70 10             	pushl  0x10(%eax)
801050c4:	68 c0 6d 10 80       	push   $0x80106dc0
801050c9:	e8 3d b5 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
801050ce:	83 c4 20             	add    $0x20,%esp
801050d1:	e8 a7 e1 ff ff       	call   8010327d <myproc>
801050d6:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801050dd:	e9 a4 fe ff ff       	jmp    80104f86 <trap+0x66>
801050e2:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801050e5:	8b 73 38             	mov    0x38(%ebx),%esi
801050e8:	e8 75 e1 ff ff       	call   80103262 <cpuid>
801050ed:	83 ec 0c             	sub    $0xc,%esp
801050f0:	57                   	push   %edi
801050f1:	56                   	push   %esi
801050f2:	50                   	push   %eax
801050f3:	ff 73 30             	pushl  0x30(%ebx)
801050f6:	68 8c 6d 10 80       	push   $0x80106d8c
801050fb:	e8 0b b5 ff ff       	call   8010060b <cprintf>
      panic("trap");
80105100:	83 c4 14             	add    $0x14,%esp
80105103:	68 62 6d 10 80       	push   $0x80106d62
80105108:	e8 3b b2 ff ff       	call   80100348 <panic>
    exit();
8010510d:	e8 17 e5 ff ff       	call   80103629 <exit>
80105112:	e9 94 fe ff ff       	jmp    80104fab <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
80105117:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
8010511b:	0f 85 a2 fe ff ff    	jne    80104fc3 <trap+0xa3>
    yield();
80105121:	e8 c9 e5 ff ff       	call   801036ef <yield>
80105126:	e9 98 fe ff ff       	jmp    80104fc3 <trap+0xa3>
    exit();
8010512b:	e8 f9 e4 ff ff       	call   80103629 <exit>
80105130:	e9 b3 fe ff ff       	jmp    80104fe8 <trap+0xc8>

80105135 <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
80105135:	55                   	push   %ebp
80105136:	89 e5                	mov    %esp,%ebp
  if(!uart)
80105138:	83 3d c0 95 10 80 00 	cmpl   $0x0,0x801095c0
8010513f:	74 15                	je     80105156 <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105141:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105146:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
80105147:	a8 01                	test   $0x1,%al
80105149:	74 12                	je     8010515d <uartgetc+0x28>
8010514b:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105150:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
80105151:	0f b6 c0             	movzbl %al,%eax
}
80105154:	5d                   	pop    %ebp
80105155:	c3                   	ret    
    return -1;
80105156:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010515b:	eb f7                	jmp    80105154 <uartgetc+0x1f>
    return -1;
8010515d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105162:	eb f0                	jmp    80105154 <uartgetc+0x1f>

80105164 <uartputc>:
  if(!uart)
80105164:	83 3d c0 95 10 80 00 	cmpl   $0x0,0x801095c0
8010516b:	74 3b                	je     801051a8 <uartputc+0x44>
{
8010516d:	55                   	push   %ebp
8010516e:	89 e5                	mov    %esp,%ebp
80105170:	53                   	push   %ebx
80105171:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105174:	bb 00 00 00 00       	mov    $0x0,%ebx
80105179:	eb 10                	jmp    8010518b <uartputc+0x27>
    microdelay(10);
8010517b:	83 ec 0c             	sub    $0xc,%esp
8010517e:	6a 0a                	push   $0xa
80105180:	e8 b2 d2 ff ff       	call   80102437 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105185:	83 c3 01             	add    $0x1,%ebx
80105188:	83 c4 10             	add    $0x10,%esp
8010518b:	83 fb 7f             	cmp    $0x7f,%ebx
8010518e:	7f 0a                	jg     8010519a <uartputc+0x36>
80105190:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105195:	ec                   	in     (%dx),%al
80105196:	a8 20                	test   $0x20,%al
80105198:	74 e1                	je     8010517b <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010519a:	8b 45 08             	mov    0x8(%ebp),%eax
8010519d:	ba f8 03 00 00       	mov    $0x3f8,%edx
801051a2:	ee                   	out    %al,(%dx)
}
801051a3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801051a6:	c9                   	leave  
801051a7:	c3                   	ret    
801051a8:	f3 c3                	repz ret 

801051aa <uartinit>:
{
801051aa:	55                   	push   %ebp
801051ab:	89 e5                	mov    %esp,%ebp
801051ad:	56                   	push   %esi
801051ae:	53                   	push   %ebx
801051af:	b9 00 00 00 00       	mov    $0x0,%ecx
801051b4:	ba fa 03 00 00       	mov    $0x3fa,%edx
801051b9:	89 c8                	mov    %ecx,%eax
801051bb:	ee                   	out    %al,(%dx)
801051bc:	be fb 03 00 00       	mov    $0x3fb,%esi
801051c1:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
801051c6:	89 f2                	mov    %esi,%edx
801051c8:	ee                   	out    %al,(%dx)
801051c9:	b8 0c 00 00 00       	mov    $0xc,%eax
801051ce:	ba f8 03 00 00       	mov    $0x3f8,%edx
801051d3:	ee                   	out    %al,(%dx)
801051d4:	bb f9 03 00 00       	mov    $0x3f9,%ebx
801051d9:	89 c8                	mov    %ecx,%eax
801051db:	89 da                	mov    %ebx,%edx
801051dd:	ee                   	out    %al,(%dx)
801051de:	b8 03 00 00 00       	mov    $0x3,%eax
801051e3:	89 f2                	mov    %esi,%edx
801051e5:	ee                   	out    %al,(%dx)
801051e6:	ba fc 03 00 00       	mov    $0x3fc,%edx
801051eb:	89 c8                	mov    %ecx,%eax
801051ed:	ee                   	out    %al,(%dx)
801051ee:	b8 01 00 00 00       	mov    $0x1,%eax
801051f3:	89 da                	mov    %ebx,%edx
801051f5:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801051f6:	ba fd 03 00 00       	mov    $0x3fd,%edx
801051fb:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
801051fc:	3c ff                	cmp    $0xff,%al
801051fe:	74 45                	je     80105245 <uartinit+0x9b>
  uart = 1;
80105200:	c7 05 c0 95 10 80 01 	movl   $0x1,0x801095c0
80105207:	00 00 00 
8010520a:	ba fa 03 00 00       	mov    $0x3fa,%edx
8010520f:	ec                   	in     (%dx),%al
80105210:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105215:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
80105216:	83 ec 08             	sub    $0x8,%esp
80105219:	6a 00                	push   $0x0
8010521b:	6a 04                	push   $0x4
8010521d:	e8 5c cd ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
80105222:	83 c4 10             	add    $0x10,%esp
80105225:	bb 84 6e 10 80       	mov    $0x80106e84,%ebx
8010522a:	eb 12                	jmp    8010523e <uartinit+0x94>
    uartputc(*p);
8010522c:	83 ec 0c             	sub    $0xc,%esp
8010522f:	0f be c0             	movsbl %al,%eax
80105232:	50                   	push   %eax
80105233:	e8 2c ff ff ff       	call   80105164 <uartputc>
  for(p="xv6...\n"; *p; p++)
80105238:	83 c3 01             	add    $0x1,%ebx
8010523b:	83 c4 10             	add    $0x10,%esp
8010523e:	0f b6 03             	movzbl (%ebx),%eax
80105241:	84 c0                	test   %al,%al
80105243:	75 e7                	jne    8010522c <uartinit+0x82>
}
80105245:	8d 65 f8             	lea    -0x8(%ebp),%esp
80105248:	5b                   	pop    %ebx
80105249:	5e                   	pop    %esi
8010524a:	5d                   	pop    %ebp
8010524b:	c3                   	ret    

8010524c <uartintr>:

void
uartintr(void)
{
8010524c:	55                   	push   %ebp
8010524d:	89 e5                	mov    %esp,%ebp
8010524f:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
80105252:	68 35 51 10 80       	push   $0x80105135
80105257:	e8 e2 b4 ff ff       	call   8010073e <consoleintr>
}
8010525c:	83 c4 10             	add    $0x10,%esp
8010525f:	c9                   	leave  
80105260:	c3                   	ret    

80105261 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80105261:	6a 00                	push   $0x0
  pushl $0
80105263:	6a 00                	push   $0x0
  jmp alltraps
80105265:	e9 be fb ff ff       	jmp    80104e28 <alltraps>

8010526a <vector1>:
.globl vector1
vector1:
  pushl $0
8010526a:	6a 00                	push   $0x0
  pushl $1
8010526c:	6a 01                	push   $0x1
  jmp alltraps
8010526e:	e9 b5 fb ff ff       	jmp    80104e28 <alltraps>

80105273 <vector2>:
.globl vector2
vector2:
  pushl $0
80105273:	6a 00                	push   $0x0
  pushl $2
80105275:	6a 02                	push   $0x2
  jmp alltraps
80105277:	e9 ac fb ff ff       	jmp    80104e28 <alltraps>

8010527c <vector3>:
.globl vector3
vector3:
  pushl $0
8010527c:	6a 00                	push   $0x0
  pushl $3
8010527e:	6a 03                	push   $0x3
  jmp alltraps
80105280:	e9 a3 fb ff ff       	jmp    80104e28 <alltraps>

80105285 <vector4>:
.globl vector4
vector4:
  pushl $0
80105285:	6a 00                	push   $0x0
  pushl $4
80105287:	6a 04                	push   $0x4
  jmp alltraps
80105289:	e9 9a fb ff ff       	jmp    80104e28 <alltraps>

8010528e <vector5>:
.globl vector5
vector5:
  pushl $0
8010528e:	6a 00                	push   $0x0
  pushl $5
80105290:	6a 05                	push   $0x5
  jmp alltraps
80105292:	e9 91 fb ff ff       	jmp    80104e28 <alltraps>

80105297 <vector6>:
.globl vector6
vector6:
  pushl $0
80105297:	6a 00                	push   $0x0
  pushl $6
80105299:	6a 06                	push   $0x6
  jmp alltraps
8010529b:	e9 88 fb ff ff       	jmp    80104e28 <alltraps>

801052a0 <vector7>:
.globl vector7
vector7:
  pushl $0
801052a0:	6a 00                	push   $0x0
  pushl $7
801052a2:	6a 07                	push   $0x7
  jmp alltraps
801052a4:	e9 7f fb ff ff       	jmp    80104e28 <alltraps>

801052a9 <vector8>:
.globl vector8
vector8:
  pushl $8
801052a9:	6a 08                	push   $0x8
  jmp alltraps
801052ab:	e9 78 fb ff ff       	jmp    80104e28 <alltraps>

801052b0 <vector9>:
.globl vector9
vector9:
  pushl $0
801052b0:	6a 00                	push   $0x0
  pushl $9
801052b2:	6a 09                	push   $0x9
  jmp alltraps
801052b4:	e9 6f fb ff ff       	jmp    80104e28 <alltraps>

801052b9 <vector10>:
.globl vector10
vector10:
  pushl $10
801052b9:	6a 0a                	push   $0xa
  jmp alltraps
801052bb:	e9 68 fb ff ff       	jmp    80104e28 <alltraps>

801052c0 <vector11>:
.globl vector11
vector11:
  pushl $11
801052c0:	6a 0b                	push   $0xb
  jmp alltraps
801052c2:	e9 61 fb ff ff       	jmp    80104e28 <alltraps>

801052c7 <vector12>:
.globl vector12
vector12:
  pushl $12
801052c7:	6a 0c                	push   $0xc
  jmp alltraps
801052c9:	e9 5a fb ff ff       	jmp    80104e28 <alltraps>

801052ce <vector13>:
.globl vector13
vector13:
  pushl $13
801052ce:	6a 0d                	push   $0xd
  jmp alltraps
801052d0:	e9 53 fb ff ff       	jmp    80104e28 <alltraps>

801052d5 <vector14>:
.globl vector14
vector14:
  pushl $14
801052d5:	6a 0e                	push   $0xe
  jmp alltraps
801052d7:	e9 4c fb ff ff       	jmp    80104e28 <alltraps>

801052dc <vector15>:
.globl vector15
vector15:
  pushl $0
801052dc:	6a 00                	push   $0x0
  pushl $15
801052de:	6a 0f                	push   $0xf
  jmp alltraps
801052e0:	e9 43 fb ff ff       	jmp    80104e28 <alltraps>

801052e5 <vector16>:
.globl vector16
vector16:
  pushl $0
801052e5:	6a 00                	push   $0x0
  pushl $16
801052e7:	6a 10                	push   $0x10
  jmp alltraps
801052e9:	e9 3a fb ff ff       	jmp    80104e28 <alltraps>

801052ee <vector17>:
.globl vector17
vector17:
  pushl $17
801052ee:	6a 11                	push   $0x11
  jmp alltraps
801052f0:	e9 33 fb ff ff       	jmp    80104e28 <alltraps>

801052f5 <vector18>:
.globl vector18
vector18:
  pushl $0
801052f5:	6a 00                	push   $0x0
  pushl $18
801052f7:	6a 12                	push   $0x12
  jmp alltraps
801052f9:	e9 2a fb ff ff       	jmp    80104e28 <alltraps>

801052fe <vector19>:
.globl vector19
vector19:
  pushl $0
801052fe:	6a 00                	push   $0x0
  pushl $19
80105300:	6a 13                	push   $0x13
  jmp alltraps
80105302:	e9 21 fb ff ff       	jmp    80104e28 <alltraps>

80105307 <vector20>:
.globl vector20
vector20:
  pushl $0
80105307:	6a 00                	push   $0x0
  pushl $20
80105309:	6a 14                	push   $0x14
  jmp alltraps
8010530b:	e9 18 fb ff ff       	jmp    80104e28 <alltraps>

80105310 <vector21>:
.globl vector21
vector21:
  pushl $0
80105310:	6a 00                	push   $0x0
  pushl $21
80105312:	6a 15                	push   $0x15
  jmp alltraps
80105314:	e9 0f fb ff ff       	jmp    80104e28 <alltraps>

80105319 <vector22>:
.globl vector22
vector22:
  pushl $0
80105319:	6a 00                	push   $0x0
  pushl $22
8010531b:	6a 16                	push   $0x16
  jmp alltraps
8010531d:	e9 06 fb ff ff       	jmp    80104e28 <alltraps>

80105322 <vector23>:
.globl vector23
vector23:
  pushl $0
80105322:	6a 00                	push   $0x0
  pushl $23
80105324:	6a 17                	push   $0x17
  jmp alltraps
80105326:	e9 fd fa ff ff       	jmp    80104e28 <alltraps>

8010532b <vector24>:
.globl vector24
vector24:
  pushl $0
8010532b:	6a 00                	push   $0x0
  pushl $24
8010532d:	6a 18                	push   $0x18
  jmp alltraps
8010532f:	e9 f4 fa ff ff       	jmp    80104e28 <alltraps>

80105334 <vector25>:
.globl vector25
vector25:
  pushl $0
80105334:	6a 00                	push   $0x0
  pushl $25
80105336:	6a 19                	push   $0x19
  jmp alltraps
80105338:	e9 eb fa ff ff       	jmp    80104e28 <alltraps>

8010533d <vector26>:
.globl vector26
vector26:
  pushl $0
8010533d:	6a 00                	push   $0x0
  pushl $26
8010533f:	6a 1a                	push   $0x1a
  jmp alltraps
80105341:	e9 e2 fa ff ff       	jmp    80104e28 <alltraps>

80105346 <vector27>:
.globl vector27
vector27:
  pushl $0
80105346:	6a 00                	push   $0x0
  pushl $27
80105348:	6a 1b                	push   $0x1b
  jmp alltraps
8010534a:	e9 d9 fa ff ff       	jmp    80104e28 <alltraps>

8010534f <vector28>:
.globl vector28
vector28:
  pushl $0
8010534f:	6a 00                	push   $0x0
  pushl $28
80105351:	6a 1c                	push   $0x1c
  jmp alltraps
80105353:	e9 d0 fa ff ff       	jmp    80104e28 <alltraps>

80105358 <vector29>:
.globl vector29
vector29:
  pushl $0
80105358:	6a 00                	push   $0x0
  pushl $29
8010535a:	6a 1d                	push   $0x1d
  jmp alltraps
8010535c:	e9 c7 fa ff ff       	jmp    80104e28 <alltraps>

80105361 <vector30>:
.globl vector30
vector30:
  pushl $0
80105361:	6a 00                	push   $0x0
  pushl $30
80105363:	6a 1e                	push   $0x1e
  jmp alltraps
80105365:	e9 be fa ff ff       	jmp    80104e28 <alltraps>

8010536a <vector31>:
.globl vector31
vector31:
  pushl $0
8010536a:	6a 00                	push   $0x0
  pushl $31
8010536c:	6a 1f                	push   $0x1f
  jmp alltraps
8010536e:	e9 b5 fa ff ff       	jmp    80104e28 <alltraps>

80105373 <vector32>:
.globl vector32
vector32:
  pushl $0
80105373:	6a 00                	push   $0x0
  pushl $32
80105375:	6a 20                	push   $0x20
  jmp alltraps
80105377:	e9 ac fa ff ff       	jmp    80104e28 <alltraps>

8010537c <vector33>:
.globl vector33
vector33:
  pushl $0
8010537c:	6a 00                	push   $0x0
  pushl $33
8010537e:	6a 21                	push   $0x21
  jmp alltraps
80105380:	e9 a3 fa ff ff       	jmp    80104e28 <alltraps>

80105385 <vector34>:
.globl vector34
vector34:
  pushl $0
80105385:	6a 00                	push   $0x0
  pushl $34
80105387:	6a 22                	push   $0x22
  jmp alltraps
80105389:	e9 9a fa ff ff       	jmp    80104e28 <alltraps>

8010538e <vector35>:
.globl vector35
vector35:
  pushl $0
8010538e:	6a 00                	push   $0x0
  pushl $35
80105390:	6a 23                	push   $0x23
  jmp alltraps
80105392:	e9 91 fa ff ff       	jmp    80104e28 <alltraps>

80105397 <vector36>:
.globl vector36
vector36:
  pushl $0
80105397:	6a 00                	push   $0x0
  pushl $36
80105399:	6a 24                	push   $0x24
  jmp alltraps
8010539b:	e9 88 fa ff ff       	jmp    80104e28 <alltraps>

801053a0 <vector37>:
.globl vector37
vector37:
  pushl $0
801053a0:	6a 00                	push   $0x0
  pushl $37
801053a2:	6a 25                	push   $0x25
  jmp alltraps
801053a4:	e9 7f fa ff ff       	jmp    80104e28 <alltraps>

801053a9 <vector38>:
.globl vector38
vector38:
  pushl $0
801053a9:	6a 00                	push   $0x0
  pushl $38
801053ab:	6a 26                	push   $0x26
  jmp alltraps
801053ad:	e9 76 fa ff ff       	jmp    80104e28 <alltraps>

801053b2 <vector39>:
.globl vector39
vector39:
  pushl $0
801053b2:	6a 00                	push   $0x0
  pushl $39
801053b4:	6a 27                	push   $0x27
  jmp alltraps
801053b6:	e9 6d fa ff ff       	jmp    80104e28 <alltraps>

801053bb <vector40>:
.globl vector40
vector40:
  pushl $0
801053bb:	6a 00                	push   $0x0
  pushl $40
801053bd:	6a 28                	push   $0x28
  jmp alltraps
801053bf:	e9 64 fa ff ff       	jmp    80104e28 <alltraps>

801053c4 <vector41>:
.globl vector41
vector41:
  pushl $0
801053c4:	6a 00                	push   $0x0
  pushl $41
801053c6:	6a 29                	push   $0x29
  jmp alltraps
801053c8:	e9 5b fa ff ff       	jmp    80104e28 <alltraps>

801053cd <vector42>:
.globl vector42
vector42:
  pushl $0
801053cd:	6a 00                	push   $0x0
  pushl $42
801053cf:	6a 2a                	push   $0x2a
  jmp alltraps
801053d1:	e9 52 fa ff ff       	jmp    80104e28 <alltraps>

801053d6 <vector43>:
.globl vector43
vector43:
  pushl $0
801053d6:	6a 00                	push   $0x0
  pushl $43
801053d8:	6a 2b                	push   $0x2b
  jmp alltraps
801053da:	e9 49 fa ff ff       	jmp    80104e28 <alltraps>

801053df <vector44>:
.globl vector44
vector44:
  pushl $0
801053df:	6a 00                	push   $0x0
  pushl $44
801053e1:	6a 2c                	push   $0x2c
  jmp alltraps
801053e3:	e9 40 fa ff ff       	jmp    80104e28 <alltraps>

801053e8 <vector45>:
.globl vector45
vector45:
  pushl $0
801053e8:	6a 00                	push   $0x0
  pushl $45
801053ea:	6a 2d                	push   $0x2d
  jmp alltraps
801053ec:	e9 37 fa ff ff       	jmp    80104e28 <alltraps>

801053f1 <vector46>:
.globl vector46
vector46:
  pushl $0
801053f1:	6a 00                	push   $0x0
  pushl $46
801053f3:	6a 2e                	push   $0x2e
  jmp alltraps
801053f5:	e9 2e fa ff ff       	jmp    80104e28 <alltraps>

801053fa <vector47>:
.globl vector47
vector47:
  pushl $0
801053fa:	6a 00                	push   $0x0
  pushl $47
801053fc:	6a 2f                	push   $0x2f
  jmp alltraps
801053fe:	e9 25 fa ff ff       	jmp    80104e28 <alltraps>

80105403 <vector48>:
.globl vector48
vector48:
  pushl $0
80105403:	6a 00                	push   $0x0
  pushl $48
80105405:	6a 30                	push   $0x30
  jmp alltraps
80105407:	e9 1c fa ff ff       	jmp    80104e28 <alltraps>

8010540c <vector49>:
.globl vector49
vector49:
  pushl $0
8010540c:	6a 00                	push   $0x0
  pushl $49
8010540e:	6a 31                	push   $0x31
  jmp alltraps
80105410:	e9 13 fa ff ff       	jmp    80104e28 <alltraps>

80105415 <vector50>:
.globl vector50
vector50:
  pushl $0
80105415:	6a 00                	push   $0x0
  pushl $50
80105417:	6a 32                	push   $0x32
  jmp alltraps
80105419:	e9 0a fa ff ff       	jmp    80104e28 <alltraps>

8010541e <vector51>:
.globl vector51
vector51:
  pushl $0
8010541e:	6a 00                	push   $0x0
  pushl $51
80105420:	6a 33                	push   $0x33
  jmp alltraps
80105422:	e9 01 fa ff ff       	jmp    80104e28 <alltraps>

80105427 <vector52>:
.globl vector52
vector52:
  pushl $0
80105427:	6a 00                	push   $0x0
  pushl $52
80105429:	6a 34                	push   $0x34
  jmp alltraps
8010542b:	e9 f8 f9 ff ff       	jmp    80104e28 <alltraps>

80105430 <vector53>:
.globl vector53
vector53:
  pushl $0
80105430:	6a 00                	push   $0x0
  pushl $53
80105432:	6a 35                	push   $0x35
  jmp alltraps
80105434:	e9 ef f9 ff ff       	jmp    80104e28 <alltraps>

80105439 <vector54>:
.globl vector54
vector54:
  pushl $0
80105439:	6a 00                	push   $0x0
  pushl $54
8010543b:	6a 36                	push   $0x36
  jmp alltraps
8010543d:	e9 e6 f9 ff ff       	jmp    80104e28 <alltraps>

80105442 <vector55>:
.globl vector55
vector55:
  pushl $0
80105442:	6a 00                	push   $0x0
  pushl $55
80105444:	6a 37                	push   $0x37
  jmp alltraps
80105446:	e9 dd f9 ff ff       	jmp    80104e28 <alltraps>

8010544b <vector56>:
.globl vector56
vector56:
  pushl $0
8010544b:	6a 00                	push   $0x0
  pushl $56
8010544d:	6a 38                	push   $0x38
  jmp alltraps
8010544f:	e9 d4 f9 ff ff       	jmp    80104e28 <alltraps>

80105454 <vector57>:
.globl vector57
vector57:
  pushl $0
80105454:	6a 00                	push   $0x0
  pushl $57
80105456:	6a 39                	push   $0x39
  jmp alltraps
80105458:	e9 cb f9 ff ff       	jmp    80104e28 <alltraps>

8010545d <vector58>:
.globl vector58
vector58:
  pushl $0
8010545d:	6a 00                	push   $0x0
  pushl $58
8010545f:	6a 3a                	push   $0x3a
  jmp alltraps
80105461:	e9 c2 f9 ff ff       	jmp    80104e28 <alltraps>

80105466 <vector59>:
.globl vector59
vector59:
  pushl $0
80105466:	6a 00                	push   $0x0
  pushl $59
80105468:	6a 3b                	push   $0x3b
  jmp alltraps
8010546a:	e9 b9 f9 ff ff       	jmp    80104e28 <alltraps>

8010546f <vector60>:
.globl vector60
vector60:
  pushl $0
8010546f:	6a 00                	push   $0x0
  pushl $60
80105471:	6a 3c                	push   $0x3c
  jmp alltraps
80105473:	e9 b0 f9 ff ff       	jmp    80104e28 <alltraps>

80105478 <vector61>:
.globl vector61
vector61:
  pushl $0
80105478:	6a 00                	push   $0x0
  pushl $61
8010547a:	6a 3d                	push   $0x3d
  jmp alltraps
8010547c:	e9 a7 f9 ff ff       	jmp    80104e28 <alltraps>

80105481 <vector62>:
.globl vector62
vector62:
  pushl $0
80105481:	6a 00                	push   $0x0
  pushl $62
80105483:	6a 3e                	push   $0x3e
  jmp alltraps
80105485:	e9 9e f9 ff ff       	jmp    80104e28 <alltraps>

8010548a <vector63>:
.globl vector63
vector63:
  pushl $0
8010548a:	6a 00                	push   $0x0
  pushl $63
8010548c:	6a 3f                	push   $0x3f
  jmp alltraps
8010548e:	e9 95 f9 ff ff       	jmp    80104e28 <alltraps>

80105493 <vector64>:
.globl vector64
vector64:
  pushl $0
80105493:	6a 00                	push   $0x0
  pushl $64
80105495:	6a 40                	push   $0x40
  jmp alltraps
80105497:	e9 8c f9 ff ff       	jmp    80104e28 <alltraps>

8010549c <vector65>:
.globl vector65
vector65:
  pushl $0
8010549c:	6a 00                	push   $0x0
  pushl $65
8010549e:	6a 41                	push   $0x41
  jmp alltraps
801054a0:	e9 83 f9 ff ff       	jmp    80104e28 <alltraps>

801054a5 <vector66>:
.globl vector66
vector66:
  pushl $0
801054a5:	6a 00                	push   $0x0
  pushl $66
801054a7:	6a 42                	push   $0x42
  jmp alltraps
801054a9:	e9 7a f9 ff ff       	jmp    80104e28 <alltraps>

801054ae <vector67>:
.globl vector67
vector67:
  pushl $0
801054ae:	6a 00                	push   $0x0
  pushl $67
801054b0:	6a 43                	push   $0x43
  jmp alltraps
801054b2:	e9 71 f9 ff ff       	jmp    80104e28 <alltraps>

801054b7 <vector68>:
.globl vector68
vector68:
  pushl $0
801054b7:	6a 00                	push   $0x0
  pushl $68
801054b9:	6a 44                	push   $0x44
  jmp alltraps
801054bb:	e9 68 f9 ff ff       	jmp    80104e28 <alltraps>

801054c0 <vector69>:
.globl vector69
vector69:
  pushl $0
801054c0:	6a 00                	push   $0x0
  pushl $69
801054c2:	6a 45                	push   $0x45
  jmp alltraps
801054c4:	e9 5f f9 ff ff       	jmp    80104e28 <alltraps>

801054c9 <vector70>:
.globl vector70
vector70:
  pushl $0
801054c9:	6a 00                	push   $0x0
  pushl $70
801054cb:	6a 46                	push   $0x46
  jmp alltraps
801054cd:	e9 56 f9 ff ff       	jmp    80104e28 <alltraps>

801054d2 <vector71>:
.globl vector71
vector71:
  pushl $0
801054d2:	6a 00                	push   $0x0
  pushl $71
801054d4:	6a 47                	push   $0x47
  jmp alltraps
801054d6:	e9 4d f9 ff ff       	jmp    80104e28 <alltraps>

801054db <vector72>:
.globl vector72
vector72:
  pushl $0
801054db:	6a 00                	push   $0x0
  pushl $72
801054dd:	6a 48                	push   $0x48
  jmp alltraps
801054df:	e9 44 f9 ff ff       	jmp    80104e28 <alltraps>

801054e4 <vector73>:
.globl vector73
vector73:
  pushl $0
801054e4:	6a 00                	push   $0x0
  pushl $73
801054e6:	6a 49                	push   $0x49
  jmp alltraps
801054e8:	e9 3b f9 ff ff       	jmp    80104e28 <alltraps>

801054ed <vector74>:
.globl vector74
vector74:
  pushl $0
801054ed:	6a 00                	push   $0x0
  pushl $74
801054ef:	6a 4a                	push   $0x4a
  jmp alltraps
801054f1:	e9 32 f9 ff ff       	jmp    80104e28 <alltraps>

801054f6 <vector75>:
.globl vector75
vector75:
  pushl $0
801054f6:	6a 00                	push   $0x0
  pushl $75
801054f8:	6a 4b                	push   $0x4b
  jmp alltraps
801054fa:	e9 29 f9 ff ff       	jmp    80104e28 <alltraps>

801054ff <vector76>:
.globl vector76
vector76:
  pushl $0
801054ff:	6a 00                	push   $0x0
  pushl $76
80105501:	6a 4c                	push   $0x4c
  jmp alltraps
80105503:	e9 20 f9 ff ff       	jmp    80104e28 <alltraps>

80105508 <vector77>:
.globl vector77
vector77:
  pushl $0
80105508:	6a 00                	push   $0x0
  pushl $77
8010550a:	6a 4d                	push   $0x4d
  jmp alltraps
8010550c:	e9 17 f9 ff ff       	jmp    80104e28 <alltraps>

80105511 <vector78>:
.globl vector78
vector78:
  pushl $0
80105511:	6a 00                	push   $0x0
  pushl $78
80105513:	6a 4e                	push   $0x4e
  jmp alltraps
80105515:	e9 0e f9 ff ff       	jmp    80104e28 <alltraps>

8010551a <vector79>:
.globl vector79
vector79:
  pushl $0
8010551a:	6a 00                	push   $0x0
  pushl $79
8010551c:	6a 4f                	push   $0x4f
  jmp alltraps
8010551e:	e9 05 f9 ff ff       	jmp    80104e28 <alltraps>

80105523 <vector80>:
.globl vector80
vector80:
  pushl $0
80105523:	6a 00                	push   $0x0
  pushl $80
80105525:	6a 50                	push   $0x50
  jmp alltraps
80105527:	e9 fc f8 ff ff       	jmp    80104e28 <alltraps>

8010552c <vector81>:
.globl vector81
vector81:
  pushl $0
8010552c:	6a 00                	push   $0x0
  pushl $81
8010552e:	6a 51                	push   $0x51
  jmp alltraps
80105530:	e9 f3 f8 ff ff       	jmp    80104e28 <alltraps>

80105535 <vector82>:
.globl vector82
vector82:
  pushl $0
80105535:	6a 00                	push   $0x0
  pushl $82
80105537:	6a 52                	push   $0x52
  jmp alltraps
80105539:	e9 ea f8 ff ff       	jmp    80104e28 <alltraps>

8010553e <vector83>:
.globl vector83
vector83:
  pushl $0
8010553e:	6a 00                	push   $0x0
  pushl $83
80105540:	6a 53                	push   $0x53
  jmp alltraps
80105542:	e9 e1 f8 ff ff       	jmp    80104e28 <alltraps>

80105547 <vector84>:
.globl vector84
vector84:
  pushl $0
80105547:	6a 00                	push   $0x0
  pushl $84
80105549:	6a 54                	push   $0x54
  jmp alltraps
8010554b:	e9 d8 f8 ff ff       	jmp    80104e28 <alltraps>

80105550 <vector85>:
.globl vector85
vector85:
  pushl $0
80105550:	6a 00                	push   $0x0
  pushl $85
80105552:	6a 55                	push   $0x55
  jmp alltraps
80105554:	e9 cf f8 ff ff       	jmp    80104e28 <alltraps>

80105559 <vector86>:
.globl vector86
vector86:
  pushl $0
80105559:	6a 00                	push   $0x0
  pushl $86
8010555b:	6a 56                	push   $0x56
  jmp alltraps
8010555d:	e9 c6 f8 ff ff       	jmp    80104e28 <alltraps>

80105562 <vector87>:
.globl vector87
vector87:
  pushl $0
80105562:	6a 00                	push   $0x0
  pushl $87
80105564:	6a 57                	push   $0x57
  jmp alltraps
80105566:	e9 bd f8 ff ff       	jmp    80104e28 <alltraps>

8010556b <vector88>:
.globl vector88
vector88:
  pushl $0
8010556b:	6a 00                	push   $0x0
  pushl $88
8010556d:	6a 58                	push   $0x58
  jmp alltraps
8010556f:	e9 b4 f8 ff ff       	jmp    80104e28 <alltraps>

80105574 <vector89>:
.globl vector89
vector89:
  pushl $0
80105574:	6a 00                	push   $0x0
  pushl $89
80105576:	6a 59                	push   $0x59
  jmp alltraps
80105578:	e9 ab f8 ff ff       	jmp    80104e28 <alltraps>

8010557d <vector90>:
.globl vector90
vector90:
  pushl $0
8010557d:	6a 00                	push   $0x0
  pushl $90
8010557f:	6a 5a                	push   $0x5a
  jmp alltraps
80105581:	e9 a2 f8 ff ff       	jmp    80104e28 <alltraps>

80105586 <vector91>:
.globl vector91
vector91:
  pushl $0
80105586:	6a 00                	push   $0x0
  pushl $91
80105588:	6a 5b                	push   $0x5b
  jmp alltraps
8010558a:	e9 99 f8 ff ff       	jmp    80104e28 <alltraps>

8010558f <vector92>:
.globl vector92
vector92:
  pushl $0
8010558f:	6a 00                	push   $0x0
  pushl $92
80105591:	6a 5c                	push   $0x5c
  jmp alltraps
80105593:	e9 90 f8 ff ff       	jmp    80104e28 <alltraps>

80105598 <vector93>:
.globl vector93
vector93:
  pushl $0
80105598:	6a 00                	push   $0x0
  pushl $93
8010559a:	6a 5d                	push   $0x5d
  jmp alltraps
8010559c:	e9 87 f8 ff ff       	jmp    80104e28 <alltraps>

801055a1 <vector94>:
.globl vector94
vector94:
  pushl $0
801055a1:	6a 00                	push   $0x0
  pushl $94
801055a3:	6a 5e                	push   $0x5e
  jmp alltraps
801055a5:	e9 7e f8 ff ff       	jmp    80104e28 <alltraps>

801055aa <vector95>:
.globl vector95
vector95:
  pushl $0
801055aa:	6a 00                	push   $0x0
  pushl $95
801055ac:	6a 5f                	push   $0x5f
  jmp alltraps
801055ae:	e9 75 f8 ff ff       	jmp    80104e28 <alltraps>

801055b3 <vector96>:
.globl vector96
vector96:
  pushl $0
801055b3:	6a 00                	push   $0x0
  pushl $96
801055b5:	6a 60                	push   $0x60
  jmp alltraps
801055b7:	e9 6c f8 ff ff       	jmp    80104e28 <alltraps>

801055bc <vector97>:
.globl vector97
vector97:
  pushl $0
801055bc:	6a 00                	push   $0x0
  pushl $97
801055be:	6a 61                	push   $0x61
  jmp alltraps
801055c0:	e9 63 f8 ff ff       	jmp    80104e28 <alltraps>

801055c5 <vector98>:
.globl vector98
vector98:
  pushl $0
801055c5:	6a 00                	push   $0x0
  pushl $98
801055c7:	6a 62                	push   $0x62
  jmp alltraps
801055c9:	e9 5a f8 ff ff       	jmp    80104e28 <alltraps>

801055ce <vector99>:
.globl vector99
vector99:
  pushl $0
801055ce:	6a 00                	push   $0x0
  pushl $99
801055d0:	6a 63                	push   $0x63
  jmp alltraps
801055d2:	e9 51 f8 ff ff       	jmp    80104e28 <alltraps>

801055d7 <vector100>:
.globl vector100
vector100:
  pushl $0
801055d7:	6a 00                	push   $0x0
  pushl $100
801055d9:	6a 64                	push   $0x64
  jmp alltraps
801055db:	e9 48 f8 ff ff       	jmp    80104e28 <alltraps>

801055e0 <vector101>:
.globl vector101
vector101:
  pushl $0
801055e0:	6a 00                	push   $0x0
  pushl $101
801055e2:	6a 65                	push   $0x65
  jmp alltraps
801055e4:	e9 3f f8 ff ff       	jmp    80104e28 <alltraps>

801055e9 <vector102>:
.globl vector102
vector102:
  pushl $0
801055e9:	6a 00                	push   $0x0
  pushl $102
801055eb:	6a 66                	push   $0x66
  jmp alltraps
801055ed:	e9 36 f8 ff ff       	jmp    80104e28 <alltraps>

801055f2 <vector103>:
.globl vector103
vector103:
  pushl $0
801055f2:	6a 00                	push   $0x0
  pushl $103
801055f4:	6a 67                	push   $0x67
  jmp alltraps
801055f6:	e9 2d f8 ff ff       	jmp    80104e28 <alltraps>

801055fb <vector104>:
.globl vector104
vector104:
  pushl $0
801055fb:	6a 00                	push   $0x0
  pushl $104
801055fd:	6a 68                	push   $0x68
  jmp alltraps
801055ff:	e9 24 f8 ff ff       	jmp    80104e28 <alltraps>

80105604 <vector105>:
.globl vector105
vector105:
  pushl $0
80105604:	6a 00                	push   $0x0
  pushl $105
80105606:	6a 69                	push   $0x69
  jmp alltraps
80105608:	e9 1b f8 ff ff       	jmp    80104e28 <alltraps>

8010560d <vector106>:
.globl vector106
vector106:
  pushl $0
8010560d:	6a 00                	push   $0x0
  pushl $106
8010560f:	6a 6a                	push   $0x6a
  jmp alltraps
80105611:	e9 12 f8 ff ff       	jmp    80104e28 <alltraps>

80105616 <vector107>:
.globl vector107
vector107:
  pushl $0
80105616:	6a 00                	push   $0x0
  pushl $107
80105618:	6a 6b                	push   $0x6b
  jmp alltraps
8010561a:	e9 09 f8 ff ff       	jmp    80104e28 <alltraps>

8010561f <vector108>:
.globl vector108
vector108:
  pushl $0
8010561f:	6a 00                	push   $0x0
  pushl $108
80105621:	6a 6c                	push   $0x6c
  jmp alltraps
80105623:	e9 00 f8 ff ff       	jmp    80104e28 <alltraps>

80105628 <vector109>:
.globl vector109
vector109:
  pushl $0
80105628:	6a 00                	push   $0x0
  pushl $109
8010562a:	6a 6d                	push   $0x6d
  jmp alltraps
8010562c:	e9 f7 f7 ff ff       	jmp    80104e28 <alltraps>

80105631 <vector110>:
.globl vector110
vector110:
  pushl $0
80105631:	6a 00                	push   $0x0
  pushl $110
80105633:	6a 6e                	push   $0x6e
  jmp alltraps
80105635:	e9 ee f7 ff ff       	jmp    80104e28 <alltraps>

8010563a <vector111>:
.globl vector111
vector111:
  pushl $0
8010563a:	6a 00                	push   $0x0
  pushl $111
8010563c:	6a 6f                	push   $0x6f
  jmp alltraps
8010563e:	e9 e5 f7 ff ff       	jmp    80104e28 <alltraps>

80105643 <vector112>:
.globl vector112
vector112:
  pushl $0
80105643:	6a 00                	push   $0x0
  pushl $112
80105645:	6a 70                	push   $0x70
  jmp alltraps
80105647:	e9 dc f7 ff ff       	jmp    80104e28 <alltraps>

8010564c <vector113>:
.globl vector113
vector113:
  pushl $0
8010564c:	6a 00                	push   $0x0
  pushl $113
8010564e:	6a 71                	push   $0x71
  jmp alltraps
80105650:	e9 d3 f7 ff ff       	jmp    80104e28 <alltraps>

80105655 <vector114>:
.globl vector114
vector114:
  pushl $0
80105655:	6a 00                	push   $0x0
  pushl $114
80105657:	6a 72                	push   $0x72
  jmp alltraps
80105659:	e9 ca f7 ff ff       	jmp    80104e28 <alltraps>

8010565e <vector115>:
.globl vector115
vector115:
  pushl $0
8010565e:	6a 00                	push   $0x0
  pushl $115
80105660:	6a 73                	push   $0x73
  jmp alltraps
80105662:	e9 c1 f7 ff ff       	jmp    80104e28 <alltraps>

80105667 <vector116>:
.globl vector116
vector116:
  pushl $0
80105667:	6a 00                	push   $0x0
  pushl $116
80105669:	6a 74                	push   $0x74
  jmp alltraps
8010566b:	e9 b8 f7 ff ff       	jmp    80104e28 <alltraps>

80105670 <vector117>:
.globl vector117
vector117:
  pushl $0
80105670:	6a 00                	push   $0x0
  pushl $117
80105672:	6a 75                	push   $0x75
  jmp alltraps
80105674:	e9 af f7 ff ff       	jmp    80104e28 <alltraps>

80105679 <vector118>:
.globl vector118
vector118:
  pushl $0
80105679:	6a 00                	push   $0x0
  pushl $118
8010567b:	6a 76                	push   $0x76
  jmp alltraps
8010567d:	e9 a6 f7 ff ff       	jmp    80104e28 <alltraps>

80105682 <vector119>:
.globl vector119
vector119:
  pushl $0
80105682:	6a 00                	push   $0x0
  pushl $119
80105684:	6a 77                	push   $0x77
  jmp alltraps
80105686:	e9 9d f7 ff ff       	jmp    80104e28 <alltraps>

8010568b <vector120>:
.globl vector120
vector120:
  pushl $0
8010568b:	6a 00                	push   $0x0
  pushl $120
8010568d:	6a 78                	push   $0x78
  jmp alltraps
8010568f:	e9 94 f7 ff ff       	jmp    80104e28 <alltraps>

80105694 <vector121>:
.globl vector121
vector121:
  pushl $0
80105694:	6a 00                	push   $0x0
  pushl $121
80105696:	6a 79                	push   $0x79
  jmp alltraps
80105698:	e9 8b f7 ff ff       	jmp    80104e28 <alltraps>

8010569d <vector122>:
.globl vector122
vector122:
  pushl $0
8010569d:	6a 00                	push   $0x0
  pushl $122
8010569f:	6a 7a                	push   $0x7a
  jmp alltraps
801056a1:	e9 82 f7 ff ff       	jmp    80104e28 <alltraps>

801056a6 <vector123>:
.globl vector123
vector123:
  pushl $0
801056a6:	6a 00                	push   $0x0
  pushl $123
801056a8:	6a 7b                	push   $0x7b
  jmp alltraps
801056aa:	e9 79 f7 ff ff       	jmp    80104e28 <alltraps>

801056af <vector124>:
.globl vector124
vector124:
  pushl $0
801056af:	6a 00                	push   $0x0
  pushl $124
801056b1:	6a 7c                	push   $0x7c
  jmp alltraps
801056b3:	e9 70 f7 ff ff       	jmp    80104e28 <alltraps>

801056b8 <vector125>:
.globl vector125
vector125:
  pushl $0
801056b8:	6a 00                	push   $0x0
  pushl $125
801056ba:	6a 7d                	push   $0x7d
  jmp alltraps
801056bc:	e9 67 f7 ff ff       	jmp    80104e28 <alltraps>

801056c1 <vector126>:
.globl vector126
vector126:
  pushl $0
801056c1:	6a 00                	push   $0x0
  pushl $126
801056c3:	6a 7e                	push   $0x7e
  jmp alltraps
801056c5:	e9 5e f7 ff ff       	jmp    80104e28 <alltraps>

801056ca <vector127>:
.globl vector127
vector127:
  pushl $0
801056ca:	6a 00                	push   $0x0
  pushl $127
801056cc:	6a 7f                	push   $0x7f
  jmp alltraps
801056ce:	e9 55 f7 ff ff       	jmp    80104e28 <alltraps>

801056d3 <vector128>:
.globl vector128
vector128:
  pushl $0
801056d3:	6a 00                	push   $0x0
  pushl $128
801056d5:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801056da:	e9 49 f7 ff ff       	jmp    80104e28 <alltraps>

801056df <vector129>:
.globl vector129
vector129:
  pushl $0
801056df:	6a 00                	push   $0x0
  pushl $129
801056e1:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801056e6:	e9 3d f7 ff ff       	jmp    80104e28 <alltraps>

801056eb <vector130>:
.globl vector130
vector130:
  pushl $0
801056eb:	6a 00                	push   $0x0
  pushl $130
801056ed:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801056f2:	e9 31 f7 ff ff       	jmp    80104e28 <alltraps>

801056f7 <vector131>:
.globl vector131
vector131:
  pushl $0
801056f7:	6a 00                	push   $0x0
  pushl $131
801056f9:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801056fe:	e9 25 f7 ff ff       	jmp    80104e28 <alltraps>

80105703 <vector132>:
.globl vector132
vector132:
  pushl $0
80105703:	6a 00                	push   $0x0
  pushl $132
80105705:	68 84 00 00 00       	push   $0x84
  jmp alltraps
8010570a:	e9 19 f7 ff ff       	jmp    80104e28 <alltraps>

8010570f <vector133>:
.globl vector133
vector133:
  pushl $0
8010570f:	6a 00                	push   $0x0
  pushl $133
80105711:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80105716:	e9 0d f7 ff ff       	jmp    80104e28 <alltraps>

8010571b <vector134>:
.globl vector134
vector134:
  pushl $0
8010571b:	6a 00                	push   $0x0
  pushl $134
8010571d:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80105722:	e9 01 f7 ff ff       	jmp    80104e28 <alltraps>

80105727 <vector135>:
.globl vector135
vector135:
  pushl $0
80105727:	6a 00                	push   $0x0
  pushl $135
80105729:	68 87 00 00 00       	push   $0x87
  jmp alltraps
8010572e:	e9 f5 f6 ff ff       	jmp    80104e28 <alltraps>

80105733 <vector136>:
.globl vector136
vector136:
  pushl $0
80105733:	6a 00                	push   $0x0
  pushl $136
80105735:	68 88 00 00 00       	push   $0x88
  jmp alltraps
8010573a:	e9 e9 f6 ff ff       	jmp    80104e28 <alltraps>

8010573f <vector137>:
.globl vector137
vector137:
  pushl $0
8010573f:	6a 00                	push   $0x0
  pushl $137
80105741:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80105746:	e9 dd f6 ff ff       	jmp    80104e28 <alltraps>

8010574b <vector138>:
.globl vector138
vector138:
  pushl $0
8010574b:	6a 00                	push   $0x0
  pushl $138
8010574d:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80105752:	e9 d1 f6 ff ff       	jmp    80104e28 <alltraps>

80105757 <vector139>:
.globl vector139
vector139:
  pushl $0
80105757:	6a 00                	push   $0x0
  pushl $139
80105759:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
8010575e:	e9 c5 f6 ff ff       	jmp    80104e28 <alltraps>

80105763 <vector140>:
.globl vector140
vector140:
  pushl $0
80105763:	6a 00                	push   $0x0
  pushl $140
80105765:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
8010576a:	e9 b9 f6 ff ff       	jmp    80104e28 <alltraps>

8010576f <vector141>:
.globl vector141
vector141:
  pushl $0
8010576f:	6a 00                	push   $0x0
  pushl $141
80105771:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80105776:	e9 ad f6 ff ff       	jmp    80104e28 <alltraps>

8010577b <vector142>:
.globl vector142
vector142:
  pushl $0
8010577b:	6a 00                	push   $0x0
  pushl $142
8010577d:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80105782:	e9 a1 f6 ff ff       	jmp    80104e28 <alltraps>

80105787 <vector143>:
.globl vector143
vector143:
  pushl $0
80105787:	6a 00                	push   $0x0
  pushl $143
80105789:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
8010578e:	e9 95 f6 ff ff       	jmp    80104e28 <alltraps>

80105793 <vector144>:
.globl vector144
vector144:
  pushl $0
80105793:	6a 00                	push   $0x0
  pushl $144
80105795:	68 90 00 00 00       	push   $0x90
  jmp alltraps
8010579a:	e9 89 f6 ff ff       	jmp    80104e28 <alltraps>

8010579f <vector145>:
.globl vector145
vector145:
  pushl $0
8010579f:	6a 00                	push   $0x0
  pushl $145
801057a1:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801057a6:	e9 7d f6 ff ff       	jmp    80104e28 <alltraps>

801057ab <vector146>:
.globl vector146
vector146:
  pushl $0
801057ab:	6a 00                	push   $0x0
  pushl $146
801057ad:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801057b2:	e9 71 f6 ff ff       	jmp    80104e28 <alltraps>

801057b7 <vector147>:
.globl vector147
vector147:
  pushl $0
801057b7:	6a 00                	push   $0x0
  pushl $147
801057b9:	68 93 00 00 00       	push   $0x93
  jmp alltraps
801057be:	e9 65 f6 ff ff       	jmp    80104e28 <alltraps>

801057c3 <vector148>:
.globl vector148
vector148:
  pushl $0
801057c3:	6a 00                	push   $0x0
  pushl $148
801057c5:	68 94 00 00 00       	push   $0x94
  jmp alltraps
801057ca:	e9 59 f6 ff ff       	jmp    80104e28 <alltraps>

801057cf <vector149>:
.globl vector149
vector149:
  pushl $0
801057cf:	6a 00                	push   $0x0
  pushl $149
801057d1:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801057d6:	e9 4d f6 ff ff       	jmp    80104e28 <alltraps>

801057db <vector150>:
.globl vector150
vector150:
  pushl $0
801057db:	6a 00                	push   $0x0
  pushl $150
801057dd:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801057e2:	e9 41 f6 ff ff       	jmp    80104e28 <alltraps>

801057e7 <vector151>:
.globl vector151
vector151:
  pushl $0
801057e7:	6a 00                	push   $0x0
  pushl $151
801057e9:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801057ee:	e9 35 f6 ff ff       	jmp    80104e28 <alltraps>

801057f3 <vector152>:
.globl vector152
vector152:
  pushl $0
801057f3:	6a 00                	push   $0x0
  pushl $152
801057f5:	68 98 00 00 00       	push   $0x98
  jmp alltraps
801057fa:	e9 29 f6 ff ff       	jmp    80104e28 <alltraps>

801057ff <vector153>:
.globl vector153
vector153:
  pushl $0
801057ff:	6a 00                	push   $0x0
  pushl $153
80105801:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80105806:	e9 1d f6 ff ff       	jmp    80104e28 <alltraps>

8010580b <vector154>:
.globl vector154
vector154:
  pushl $0
8010580b:	6a 00                	push   $0x0
  pushl $154
8010580d:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80105812:	e9 11 f6 ff ff       	jmp    80104e28 <alltraps>

80105817 <vector155>:
.globl vector155
vector155:
  pushl $0
80105817:	6a 00                	push   $0x0
  pushl $155
80105819:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
8010581e:	e9 05 f6 ff ff       	jmp    80104e28 <alltraps>

80105823 <vector156>:
.globl vector156
vector156:
  pushl $0
80105823:	6a 00                	push   $0x0
  pushl $156
80105825:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
8010582a:	e9 f9 f5 ff ff       	jmp    80104e28 <alltraps>

8010582f <vector157>:
.globl vector157
vector157:
  pushl $0
8010582f:	6a 00                	push   $0x0
  pushl $157
80105831:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80105836:	e9 ed f5 ff ff       	jmp    80104e28 <alltraps>

8010583b <vector158>:
.globl vector158
vector158:
  pushl $0
8010583b:	6a 00                	push   $0x0
  pushl $158
8010583d:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80105842:	e9 e1 f5 ff ff       	jmp    80104e28 <alltraps>

80105847 <vector159>:
.globl vector159
vector159:
  pushl $0
80105847:	6a 00                	push   $0x0
  pushl $159
80105849:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
8010584e:	e9 d5 f5 ff ff       	jmp    80104e28 <alltraps>

80105853 <vector160>:
.globl vector160
vector160:
  pushl $0
80105853:	6a 00                	push   $0x0
  pushl $160
80105855:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
8010585a:	e9 c9 f5 ff ff       	jmp    80104e28 <alltraps>

8010585f <vector161>:
.globl vector161
vector161:
  pushl $0
8010585f:	6a 00                	push   $0x0
  pushl $161
80105861:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80105866:	e9 bd f5 ff ff       	jmp    80104e28 <alltraps>

8010586b <vector162>:
.globl vector162
vector162:
  pushl $0
8010586b:	6a 00                	push   $0x0
  pushl $162
8010586d:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105872:	e9 b1 f5 ff ff       	jmp    80104e28 <alltraps>

80105877 <vector163>:
.globl vector163
vector163:
  pushl $0
80105877:	6a 00                	push   $0x0
  pushl $163
80105879:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
8010587e:	e9 a5 f5 ff ff       	jmp    80104e28 <alltraps>

80105883 <vector164>:
.globl vector164
vector164:
  pushl $0
80105883:	6a 00                	push   $0x0
  pushl $164
80105885:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
8010588a:	e9 99 f5 ff ff       	jmp    80104e28 <alltraps>

8010588f <vector165>:
.globl vector165
vector165:
  pushl $0
8010588f:	6a 00                	push   $0x0
  pushl $165
80105891:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80105896:	e9 8d f5 ff ff       	jmp    80104e28 <alltraps>

8010589b <vector166>:
.globl vector166
vector166:
  pushl $0
8010589b:	6a 00                	push   $0x0
  pushl $166
8010589d:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
801058a2:	e9 81 f5 ff ff       	jmp    80104e28 <alltraps>

801058a7 <vector167>:
.globl vector167
vector167:
  pushl $0
801058a7:	6a 00                	push   $0x0
  pushl $167
801058a9:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
801058ae:	e9 75 f5 ff ff       	jmp    80104e28 <alltraps>

801058b3 <vector168>:
.globl vector168
vector168:
  pushl $0
801058b3:	6a 00                	push   $0x0
  pushl $168
801058b5:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
801058ba:	e9 69 f5 ff ff       	jmp    80104e28 <alltraps>

801058bf <vector169>:
.globl vector169
vector169:
  pushl $0
801058bf:	6a 00                	push   $0x0
  pushl $169
801058c1:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
801058c6:	e9 5d f5 ff ff       	jmp    80104e28 <alltraps>

801058cb <vector170>:
.globl vector170
vector170:
  pushl $0
801058cb:	6a 00                	push   $0x0
  pushl $170
801058cd:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
801058d2:	e9 51 f5 ff ff       	jmp    80104e28 <alltraps>

801058d7 <vector171>:
.globl vector171
vector171:
  pushl $0
801058d7:	6a 00                	push   $0x0
  pushl $171
801058d9:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
801058de:	e9 45 f5 ff ff       	jmp    80104e28 <alltraps>

801058e3 <vector172>:
.globl vector172
vector172:
  pushl $0
801058e3:	6a 00                	push   $0x0
  pushl $172
801058e5:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
801058ea:	e9 39 f5 ff ff       	jmp    80104e28 <alltraps>

801058ef <vector173>:
.globl vector173
vector173:
  pushl $0
801058ef:	6a 00                	push   $0x0
  pushl $173
801058f1:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801058f6:	e9 2d f5 ff ff       	jmp    80104e28 <alltraps>

801058fb <vector174>:
.globl vector174
vector174:
  pushl $0
801058fb:	6a 00                	push   $0x0
  pushl $174
801058fd:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105902:	e9 21 f5 ff ff       	jmp    80104e28 <alltraps>

80105907 <vector175>:
.globl vector175
vector175:
  pushl $0
80105907:	6a 00                	push   $0x0
  pushl $175
80105909:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
8010590e:	e9 15 f5 ff ff       	jmp    80104e28 <alltraps>

80105913 <vector176>:
.globl vector176
vector176:
  pushl $0
80105913:	6a 00                	push   $0x0
  pushl $176
80105915:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
8010591a:	e9 09 f5 ff ff       	jmp    80104e28 <alltraps>

8010591f <vector177>:
.globl vector177
vector177:
  pushl $0
8010591f:	6a 00                	push   $0x0
  pushl $177
80105921:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105926:	e9 fd f4 ff ff       	jmp    80104e28 <alltraps>

8010592b <vector178>:
.globl vector178
vector178:
  pushl $0
8010592b:	6a 00                	push   $0x0
  pushl $178
8010592d:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105932:	e9 f1 f4 ff ff       	jmp    80104e28 <alltraps>

80105937 <vector179>:
.globl vector179
vector179:
  pushl $0
80105937:	6a 00                	push   $0x0
  pushl $179
80105939:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
8010593e:	e9 e5 f4 ff ff       	jmp    80104e28 <alltraps>

80105943 <vector180>:
.globl vector180
vector180:
  pushl $0
80105943:	6a 00                	push   $0x0
  pushl $180
80105945:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
8010594a:	e9 d9 f4 ff ff       	jmp    80104e28 <alltraps>

8010594f <vector181>:
.globl vector181
vector181:
  pushl $0
8010594f:	6a 00                	push   $0x0
  pushl $181
80105951:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105956:	e9 cd f4 ff ff       	jmp    80104e28 <alltraps>

8010595b <vector182>:
.globl vector182
vector182:
  pushl $0
8010595b:	6a 00                	push   $0x0
  pushl $182
8010595d:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105962:	e9 c1 f4 ff ff       	jmp    80104e28 <alltraps>

80105967 <vector183>:
.globl vector183
vector183:
  pushl $0
80105967:	6a 00                	push   $0x0
  pushl $183
80105969:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
8010596e:	e9 b5 f4 ff ff       	jmp    80104e28 <alltraps>

80105973 <vector184>:
.globl vector184
vector184:
  pushl $0
80105973:	6a 00                	push   $0x0
  pushl $184
80105975:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
8010597a:	e9 a9 f4 ff ff       	jmp    80104e28 <alltraps>

8010597f <vector185>:
.globl vector185
vector185:
  pushl $0
8010597f:	6a 00                	push   $0x0
  pushl $185
80105981:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105986:	e9 9d f4 ff ff       	jmp    80104e28 <alltraps>

8010598b <vector186>:
.globl vector186
vector186:
  pushl $0
8010598b:	6a 00                	push   $0x0
  pushl $186
8010598d:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105992:	e9 91 f4 ff ff       	jmp    80104e28 <alltraps>

80105997 <vector187>:
.globl vector187
vector187:
  pushl $0
80105997:	6a 00                	push   $0x0
  pushl $187
80105999:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
8010599e:	e9 85 f4 ff ff       	jmp    80104e28 <alltraps>

801059a3 <vector188>:
.globl vector188
vector188:
  pushl $0
801059a3:	6a 00                	push   $0x0
  pushl $188
801059a5:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
801059aa:	e9 79 f4 ff ff       	jmp    80104e28 <alltraps>

801059af <vector189>:
.globl vector189
vector189:
  pushl $0
801059af:	6a 00                	push   $0x0
  pushl $189
801059b1:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
801059b6:	e9 6d f4 ff ff       	jmp    80104e28 <alltraps>

801059bb <vector190>:
.globl vector190
vector190:
  pushl $0
801059bb:	6a 00                	push   $0x0
  pushl $190
801059bd:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
801059c2:	e9 61 f4 ff ff       	jmp    80104e28 <alltraps>

801059c7 <vector191>:
.globl vector191
vector191:
  pushl $0
801059c7:	6a 00                	push   $0x0
  pushl $191
801059c9:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
801059ce:	e9 55 f4 ff ff       	jmp    80104e28 <alltraps>

801059d3 <vector192>:
.globl vector192
vector192:
  pushl $0
801059d3:	6a 00                	push   $0x0
  pushl $192
801059d5:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
801059da:	e9 49 f4 ff ff       	jmp    80104e28 <alltraps>

801059df <vector193>:
.globl vector193
vector193:
  pushl $0
801059df:	6a 00                	push   $0x0
  pushl $193
801059e1:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
801059e6:	e9 3d f4 ff ff       	jmp    80104e28 <alltraps>

801059eb <vector194>:
.globl vector194
vector194:
  pushl $0
801059eb:	6a 00                	push   $0x0
  pushl $194
801059ed:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
801059f2:	e9 31 f4 ff ff       	jmp    80104e28 <alltraps>

801059f7 <vector195>:
.globl vector195
vector195:
  pushl $0
801059f7:	6a 00                	push   $0x0
  pushl $195
801059f9:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
801059fe:	e9 25 f4 ff ff       	jmp    80104e28 <alltraps>

80105a03 <vector196>:
.globl vector196
vector196:
  pushl $0
80105a03:	6a 00                	push   $0x0
  pushl $196
80105a05:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105a0a:	e9 19 f4 ff ff       	jmp    80104e28 <alltraps>

80105a0f <vector197>:
.globl vector197
vector197:
  pushl $0
80105a0f:	6a 00                	push   $0x0
  pushl $197
80105a11:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105a16:	e9 0d f4 ff ff       	jmp    80104e28 <alltraps>

80105a1b <vector198>:
.globl vector198
vector198:
  pushl $0
80105a1b:	6a 00                	push   $0x0
  pushl $198
80105a1d:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105a22:	e9 01 f4 ff ff       	jmp    80104e28 <alltraps>

80105a27 <vector199>:
.globl vector199
vector199:
  pushl $0
80105a27:	6a 00                	push   $0x0
  pushl $199
80105a29:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105a2e:	e9 f5 f3 ff ff       	jmp    80104e28 <alltraps>

80105a33 <vector200>:
.globl vector200
vector200:
  pushl $0
80105a33:	6a 00                	push   $0x0
  pushl $200
80105a35:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105a3a:	e9 e9 f3 ff ff       	jmp    80104e28 <alltraps>

80105a3f <vector201>:
.globl vector201
vector201:
  pushl $0
80105a3f:	6a 00                	push   $0x0
  pushl $201
80105a41:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105a46:	e9 dd f3 ff ff       	jmp    80104e28 <alltraps>

80105a4b <vector202>:
.globl vector202
vector202:
  pushl $0
80105a4b:	6a 00                	push   $0x0
  pushl $202
80105a4d:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105a52:	e9 d1 f3 ff ff       	jmp    80104e28 <alltraps>

80105a57 <vector203>:
.globl vector203
vector203:
  pushl $0
80105a57:	6a 00                	push   $0x0
  pushl $203
80105a59:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105a5e:	e9 c5 f3 ff ff       	jmp    80104e28 <alltraps>

80105a63 <vector204>:
.globl vector204
vector204:
  pushl $0
80105a63:	6a 00                	push   $0x0
  pushl $204
80105a65:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105a6a:	e9 b9 f3 ff ff       	jmp    80104e28 <alltraps>

80105a6f <vector205>:
.globl vector205
vector205:
  pushl $0
80105a6f:	6a 00                	push   $0x0
  pushl $205
80105a71:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105a76:	e9 ad f3 ff ff       	jmp    80104e28 <alltraps>

80105a7b <vector206>:
.globl vector206
vector206:
  pushl $0
80105a7b:	6a 00                	push   $0x0
  pushl $206
80105a7d:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105a82:	e9 a1 f3 ff ff       	jmp    80104e28 <alltraps>

80105a87 <vector207>:
.globl vector207
vector207:
  pushl $0
80105a87:	6a 00                	push   $0x0
  pushl $207
80105a89:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105a8e:	e9 95 f3 ff ff       	jmp    80104e28 <alltraps>

80105a93 <vector208>:
.globl vector208
vector208:
  pushl $0
80105a93:	6a 00                	push   $0x0
  pushl $208
80105a95:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105a9a:	e9 89 f3 ff ff       	jmp    80104e28 <alltraps>

80105a9f <vector209>:
.globl vector209
vector209:
  pushl $0
80105a9f:	6a 00                	push   $0x0
  pushl $209
80105aa1:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105aa6:	e9 7d f3 ff ff       	jmp    80104e28 <alltraps>

80105aab <vector210>:
.globl vector210
vector210:
  pushl $0
80105aab:	6a 00                	push   $0x0
  pushl $210
80105aad:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105ab2:	e9 71 f3 ff ff       	jmp    80104e28 <alltraps>

80105ab7 <vector211>:
.globl vector211
vector211:
  pushl $0
80105ab7:	6a 00                	push   $0x0
  pushl $211
80105ab9:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105abe:	e9 65 f3 ff ff       	jmp    80104e28 <alltraps>

80105ac3 <vector212>:
.globl vector212
vector212:
  pushl $0
80105ac3:	6a 00                	push   $0x0
  pushl $212
80105ac5:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105aca:	e9 59 f3 ff ff       	jmp    80104e28 <alltraps>

80105acf <vector213>:
.globl vector213
vector213:
  pushl $0
80105acf:	6a 00                	push   $0x0
  pushl $213
80105ad1:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105ad6:	e9 4d f3 ff ff       	jmp    80104e28 <alltraps>

80105adb <vector214>:
.globl vector214
vector214:
  pushl $0
80105adb:	6a 00                	push   $0x0
  pushl $214
80105add:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105ae2:	e9 41 f3 ff ff       	jmp    80104e28 <alltraps>

80105ae7 <vector215>:
.globl vector215
vector215:
  pushl $0
80105ae7:	6a 00                	push   $0x0
  pushl $215
80105ae9:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105aee:	e9 35 f3 ff ff       	jmp    80104e28 <alltraps>

80105af3 <vector216>:
.globl vector216
vector216:
  pushl $0
80105af3:	6a 00                	push   $0x0
  pushl $216
80105af5:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105afa:	e9 29 f3 ff ff       	jmp    80104e28 <alltraps>

80105aff <vector217>:
.globl vector217
vector217:
  pushl $0
80105aff:	6a 00                	push   $0x0
  pushl $217
80105b01:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105b06:	e9 1d f3 ff ff       	jmp    80104e28 <alltraps>

80105b0b <vector218>:
.globl vector218
vector218:
  pushl $0
80105b0b:	6a 00                	push   $0x0
  pushl $218
80105b0d:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105b12:	e9 11 f3 ff ff       	jmp    80104e28 <alltraps>

80105b17 <vector219>:
.globl vector219
vector219:
  pushl $0
80105b17:	6a 00                	push   $0x0
  pushl $219
80105b19:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105b1e:	e9 05 f3 ff ff       	jmp    80104e28 <alltraps>

80105b23 <vector220>:
.globl vector220
vector220:
  pushl $0
80105b23:	6a 00                	push   $0x0
  pushl $220
80105b25:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105b2a:	e9 f9 f2 ff ff       	jmp    80104e28 <alltraps>

80105b2f <vector221>:
.globl vector221
vector221:
  pushl $0
80105b2f:	6a 00                	push   $0x0
  pushl $221
80105b31:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105b36:	e9 ed f2 ff ff       	jmp    80104e28 <alltraps>

80105b3b <vector222>:
.globl vector222
vector222:
  pushl $0
80105b3b:	6a 00                	push   $0x0
  pushl $222
80105b3d:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105b42:	e9 e1 f2 ff ff       	jmp    80104e28 <alltraps>

80105b47 <vector223>:
.globl vector223
vector223:
  pushl $0
80105b47:	6a 00                	push   $0x0
  pushl $223
80105b49:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105b4e:	e9 d5 f2 ff ff       	jmp    80104e28 <alltraps>

80105b53 <vector224>:
.globl vector224
vector224:
  pushl $0
80105b53:	6a 00                	push   $0x0
  pushl $224
80105b55:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105b5a:	e9 c9 f2 ff ff       	jmp    80104e28 <alltraps>

80105b5f <vector225>:
.globl vector225
vector225:
  pushl $0
80105b5f:	6a 00                	push   $0x0
  pushl $225
80105b61:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105b66:	e9 bd f2 ff ff       	jmp    80104e28 <alltraps>

80105b6b <vector226>:
.globl vector226
vector226:
  pushl $0
80105b6b:	6a 00                	push   $0x0
  pushl $226
80105b6d:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105b72:	e9 b1 f2 ff ff       	jmp    80104e28 <alltraps>

80105b77 <vector227>:
.globl vector227
vector227:
  pushl $0
80105b77:	6a 00                	push   $0x0
  pushl $227
80105b79:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105b7e:	e9 a5 f2 ff ff       	jmp    80104e28 <alltraps>

80105b83 <vector228>:
.globl vector228
vector228:
  pushl $0
80105b83:	6a 00                	push   $0x0
  pushl $228
80105b85:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105b8a:	e9 99 f2 ff ff       	jmp    80104e28 <alltraps>

80105b8f <vector229>:
.globl vector229
vector229:
  pushl $0
80105b8f:	6a 00                	push   $0x0
  pushl $229
80105b91:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105b96:	e9 8d f2 ff ff       	jmp    80104e28 <alltraps>

80105b9b <vector230>:
.globl vector230
vector230:
  pushl $0
80105b9b:	6a 00                	push   $0x0
  pushl $230
80105b9d:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105ba2:	e9 81 f2 ff ff       	jmp    80104e28 <alltraps>

80105ba7 <vector231>:
.globl vector231
vector231:
  pushl $0
80105ba7:	6a 00                	push   $0x0
  pushl $231
80105ba9:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105bae:	e9 75 f2 ff ff       	jmp    80104e28 <alltraps>

80105bb3 <vector232>:
.globl vector232
vector232:
  pushl $0
80105bb3:	6a 00                	push   $0x0
  pushl $232
80105bb5:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105bba:	e9 69 f2 ff ff       	jmp    80104e28 <alltraps>

80105bbf <vector233>:
.globl vector233
vector233:
  pushl $0
80105bbf:	6a 00                	push   $0x0
  pushl $233
80105bc1:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105bc6:	e9 5d f2 ff ff       	jmp    80104e28 <alltraps>

80105bcb <vector234>:
.globl vector234
vector234:
  pushl $0
80105bcb:	6a 00                	push   $0x0
  pushl $234
80105bcd:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105bd2:	e9 51 f2 ff ff       	jmp    80104e28 <alltraps>

80105bd7 <vector235>:
.globl vector235
vector235:
  pushl $0
80105bd7:	6a 00                	push   $0x0
  pushl $235
80105bd9:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105bde:	e9 45 f2 ff ff       	jmp    80104e28 <alltraps>

80105be3 <vector236>:
.globl vector236
vector236:
  pushl $0
80105be3:	6a 00                	push   $0x0
  pushl $236
80105be5:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105bea:	e9 39 f2 ff ff       	jmp    80104e28 <alltraps>

80105bef <vector237>:
.globl vector237
vector237:
  pushl $0
80105bef:	6a 00                	push   $0x0
  pushl $237
80105bf1:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105bf6:	e9 2d f2 ff ff       	jmp    80104e28 <alltraps>

80105bfb <vector238>:
.globl vector238
vector238:
  pushl $0
80105bfb:	6a 00                	push   $0x0
  pushl $238
80105bfd:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105c02:	e9 21 f2 ff ff       	jmp    80104e28 <alltraps>

80105c07 <vector239>:
.globl vector239
vector239:
  pushl $0
80105c07:	6a 00                	push   $0x0
  pushl $239
80105c09:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105c0e:	e9 15 f2 ff ff       	jmp    80104e28 <alltraps>

80105c13 <vector240>:
.globl vector240
vector240:
  pushl $0
80105c13:	6a 00                	push   $0x0
  pushl $240
80105c15:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105c1a:	e9 09 f2 ff ff       	jmp    80104e28 <alltraps>

80105c1f <vector241>:
.globl vector241
vector241:
  pushl $0
80105c1f:	6a 00                	push   $0x0
  pushl $241
80105c21:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105c26:	e9 fd f1 ff ff       	jmp    80104e28 <alltraps>

80105c2b <vector242>:
.globl vector242
vector242:
  pushl $0
80105c2b:	6a 00                	push   $0x0
  pushl $242
80105c2d:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105c32:	e9 f1 f1 ff ff       	jmp    80104e28 <alltraps>

80105c37 <vector243>:
.globl vector243
vector243:
  pushl $0
80105c37:	6a 00                	push   $0x0
  pushl $243
80105c39:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105c3e:	e9 e5 f1 ff ff       	jmp    80104e28 <alltraps>

80105c43 <vector244>:
.globl vector244
vector244:
  pushl $0
80105c43:	6a 00                	push   $0x0
  pushl $244
80105c45:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105c4a:	e9 d9 f1 ff ff       	jmp    80104e28 <alltraps>

80105c4f <vector245>:
.globl vector245
vector245:
  pushl $0
80105c4f:	6a 00                	push   $0x0
  pushl $245
80105c51:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105c56:	e9 cd f1 ff ff       	jmp    80104e28 <alltraps>

80105c5b <vector246>:
.globl vector246
vector246:
  pushl $0
80105c5b:	6a 00                	push   $0x0
  pushl $246
80105c5d:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105c62:	e9 c1 f1 ff ff       	jmp    80104e28 <alltraps>

80105c67 <vector247>:
.globl vector247
vector247:
  pushl $0
80105c67:	6a 00                	push   $0x0
  pushl $247
80105c69:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105c6e:	e9 b5 f1 ff ff       	jmp    80104e28 <alltraps>

80105c73 <vector248>:
.globl vector248
vector248:
  pushl $0
80105c73:	6a 00                	push   $0x0
  pushl $248
80105c75:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105c7a:	e9 a9 f1 ff ff       	jmp    80104e28 <alltraps>

80105c7f <vector249>:
.globl vector249
vector249:
  pushl $0
80105c7f:	6a 00                	push   $0x0
  pushl $249
80105c81:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105c86:	e9 9d f1 ff ff       	jmp    80104e28 <alltraps>

80105c8b <vector250>:
.globl vector250
vector250:
  pushl $0
80105c8b:	6a 00                	push   $0x0
  pushl $250
80105c8d:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105c92:	e9 91 f1 ff ff       	jmp    80104e28 <alltraps>

80105c97 <vector251>:
.globl vector251
vector251:
  pushl $0
80105c97:	6a 00                	push   $0x0
  pushl $251
80105c99:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105c9e:	e9 85 f1 ff ff       	jmp    80104e28 <alltraps>

80105ca3 <vector252>:
.globl vector252
vector252:
  pushl $0
80105ca3:	6a 00                	push   $0x0
  pushl $252
80105ca5:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105caa:	e9 79 f1 ff ff       	jmp    80104e28 <alltraps>

80105caf <vector253>:
.globl vector253
vector253:
  pushl $0
80105caf:	6a 00                	push   $0x0
  pushl $253
80105cb1:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105cb6:	e9 6d f1 ff ff       	jmp    80104e28 <alltraps>

80105cbb <vector254>:
.globl vector254
vector254:
  pushl $0
80105cbb:	6a 00                	push   $0x0
  pushl $254
80105cbd:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105cc2:	e9 61 f1 ff ff       	jmp    80104e28 <alltraps>

80105cc7 <vector255>:
.globl vector255
vector255:
  pushl $0
80105cc7:	6a 00                	push   $0x0
  pushl $255
80105cc9:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105cce:	e9 55 f1 ff ff       	jmp    80104e28 <alltraps>

80105cd3 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105cd3:	55                   	push   %ebp
80105cd4:	89 e5                	mov    %esp,%ebp
80105cd6:	57                   	push   %edi
80105cd7:	56                   	push   %esi
80105cd8:	53                   	push   %ebx
80105cd9:	83 ec 0c             	sub    $0xc,%esp
80105cdc:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105cde:	c1 ea 16             	shr    $0x16,%edx
80105ce1:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105ce4:	8b 1f                	mov    (%edi),%ebx
80105ce6:	f6 c3 01             	test   $0x1,%bl
80105ce9:	74 22                	je     80105d0d <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105ceb:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105cf1:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105cf7:	c1 ee 0c             	shr    $0xc,%esi
80105cfa:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105d00:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105d03:	89 d8                	mov    %ebx,%eax
80105d05:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105d08:	5b                   	pop    %ebx
80105d09:	5e                   	pop    %esi
80105d0a:	5f                   	pop    %edi
80105d0b:	5d                   	pop    %ebp
80105d0c:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc2(-2)) == 0)
80105d0d:	85 c9                	test   %ecx,%ecx
80105d0f:	74 33                	je     80105d44 <walkpgdir+0x71>
80105d11:	83 ec 0c             	sub    $0xc,%esp
80105d14:	6a fe                	push   $0xfffffffe
80105d16:	e8 f5 c3 ff ff       	call   80102110 <kalloc2>
80105d1b:	89 c3                	mov    %eax,%ebx
80105d1d:	83 c4 10             	add    $0x10,%esp
80105d20:	85 c0                	test   %eax,%eax
80105d22:	74 df                	je     80105d03 <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105d24:	83 ec 04             	sub    $0x4,%esp
80105d27:	68 00 10 00 00       	push   $0x1000
80105d2c:	6a 00                	push   $0x0
80105d2e:	50                   	push   %eax
80105d2f:	e8 f6 df ff ff       	call   80103d2a <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105d34:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105d3a:	83 c8 07             	or     $0x7,%eax
80105d3d:	89 07                	mov    %eax,(%edi)
80105d3f:	83 c4 10             	add    $0x10,%esp
80105d42:	eb b3                	jmp    80105cf7 <walkpgdir+0x24>
      return 0;
80105d44:	bb 00 00 00 00       	mov    $0x0,%ebx
80105d49:	eb b8                	jmp    80105d03 <walkpgdir+0x30>

80105d4b <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105d4b:	55                   	push   %ebp
80105d4c:	89 e5                	mov    %esp,%ebp
80105d4e:	57                   	push   %edi
80105d4f:	56                   	push   %esi
80105d50:	53                   	push   %ebx
80105d51:	83 ec 1c             	sub    $0x1c,%esp
80105d54:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105d57:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105d5a:	89 d3                	mov    %edx,%ebx
80105d5c:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105d62:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105d66:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105d6c:	b9 01 00 00 00       	mov    $0x1,%ecx
80105d71:	89 da                	mov    %ebx,%edx
80105d73:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105d76:	e8 58 ff ff ff       	call   80105cd3 <walkpgdir>
80105d7b:	85 c0                	test   %eax,%eax
80105d7d:	74 2e                	je     80105dad <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105d7f:	f6 00 01             	testb  $0x1,(%eax)
80105d82:	75 1c                	jne    80105da0 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105d84:	89 f2                	mov    %esi,%edx
80105d86:	0b 55 0c             	or     0xc(%ebp),%edx
80105d89:	83 ca 01             	or     $0x1,%edx
80105d8c:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105d8e:	39 fb                	cmp    %edi,%ebx
80105d90:	74 28                	je     80105dba <mappages+0x6f>
      break;
    a += PGSIZE;
80105d92:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105d98:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105d9e:	eb cc                	jmp    80105d6c <mappages+0x21>
      panic("remap");
80105da0:	83 ec 0c             	sub    $0xc,%esp
80105da3:	68 8c 6e 10 80       	push   $0x80106e8c
80105da8:	e8 9b a5 ff ff       	call   80100348 <panic>
      return -1;
80105dad:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105db2:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105db5:	5b                   	pop    %ebx
80105db6:	5e                   	pop    %esi
80105db7:	5f                   	pop    %edi
80105db8:	5d                   	pop    %ebp
80105db9:	c3                   	ret    
  return 0;
80105dba:	b8 00 00 00 00       	mov    $0x0,%eax
80105dbf:	eb f1                	jmp    80105db2 <mappages+0x67>

80105dc1 <seginit>:
{
80105dc1:	55                   	push   %ebp
80105dc2:	89 e5                	mov    %esp,%ebp
80105dc4:	53                   	push   %ebx
80105dc5:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105dc8:	e8 95 d4 ff ff       	call   80103262 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105dcd:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105dd3:	66 c7 80 58 18 13 80 	movw   $0xffff,-0x7fece7a8(%eax)
80105dda:	ff ff 
80105ddc:	66 c7 80 5a 18 13 80 	movw   $0x0,-0x7fece7a6(%eax)
80105de3:	00 00 
80105de5:	c6 80 5c 18 13 80 00 	movb   $0x0,-0x7fece7a4(%eax)
80105dec:	0f b6 88 5d 18 13 80 	movzbl -0x7fece7a3(%eax),%ecx
80105df3:	83 e1 f0             	and    $0xfffffff0,%ecx
80105df6:	83 c9 1a             	or     $0x1a,%ecx
80105df9:	83 e1 9f             	and    $0xffffff9f,%ecx
80105dfc:	83 c9 80             	or     $0xffffff80,%ecx
80105dff:	88 88 5d 18 13 80    	mov    %cl,-0x7fece7a3(%eax)
80105e05:	0f b6 88 5e 18 13 80 	movzbl -0x7fece7a2(%eax),%ecx
80105e0c:	83 c9 0f             	or     $0xf,%ecx
80105e0f:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e12:	83 c9 c0             	or     $0xffffffc0,%ecx
80105e15:	88 88 5e 18 13 80    	mov    %cl,-0x7fece7a2(%eax)
80105e1b:	c6 80 5f 18 13 80 00 	movb   $0x0,-0x7fece7a1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105e22:	66 c7 80 60 18 13 80 	movw   $0xffff,-0x7fece7a0(%eax)
80105e29:	ff ff 
80105e2b:	66 c7 80 62 18 13 80 	movw   $0x0,-0x7fece79e(%eax)
80105e32:	00 00 
80105e34:	c6 80 64 18 13 80 00 	movb   $0x0,-0x7fece79c(%eax)
80105e3b:	0f b6 88 65 18 13 80 	movzbl -0x7fece79b(%eax),%ecx
80105e42:	83 e1 f0             	and    $0xfffffff0,%ecx
80105e45:	83 c9 12             	or     $0x12,%ecx
80105e48:	83 e1 9f             	and    $0xffffff9f,%ecx
80105e4b:	83 c9 80             	or     $0xffffff80,%ecx
80105e4e:	88 88 65 18 13 80    	mov    %cl,-0x7fece79b(%eax)
80105e54:	0f b6 88 66 18 13 80 	movzbl -0x7fece79a(%eax),%ecx
80105e5b:	83 c9 0f             	or     $0xf,%ecx
80105e5e:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e61:	83 c9 c0             	or     $0xffffffc0,%ecx
80105e64:	88 88 66 18 13 80    	mov    %cl,-0x7fece79a(%eax)
80105e6a:	c6 80 67 18 13 80 00 	movb   $0x0,-0x7fece799(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80105e71:	66 c7 80 68 18 13 80 	movw   $0xffff,-0x7fece798(%eax)
80105e78:	ff ff 
80105e7a:	66 c7 80 6a 18 13 80 	movw   $0x0,-0x7fece796(%eax)
80105e81:	00 00 
80105e83:	c6 80 6c 18 13 80 00 	movb   $0x0,-0x7fece794(%eax)
80105e8a:	c6 80 6d 18 13 80 fa 	movb   $0xfa,-0x7fece793(%eax)
80105e91:	0f b6 88 6e 18 13 80 	movzbl -0x7fece792(%eax),%ecx
80105e98:	83 c9 0f             	or     $0xf,%ecx
80105e9b:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e9e:	83 c9 c0             	or     $0xffffffc0,%ecx
80105ea1:	88 88 6e 18 13 80    	mov    %cl,-0x7fece792(%eax)
80105ea7:	c6 80 6f 18 13 80 00 	movb   $0x0,-0x7fece791(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80105eae:	66 c7 80 70 18 13 80 	movw   $0xffff,-0x7fece790(%eax)
80105eb5:	ff ff 
80105eb7:	66 c7 80 72 18 13 80 	movw   $0x0,-0x7fece78e(%eax)
80105ebe:	00 00 
80105ec0:	c6 80 74 18 13 80 00 	movb   $0x0,-0x7fece78c(%eax)
80105ec7:	c6 80 75 18 13 80 f2 	movb   $0xf2,-0x7fece78b(%eax)
80105ece:	0f b6 88 76 18 13 80 	movzbl -0x7fece78a(%eax),%ecx
80105ed5:	83 c9 0f             	or     $0xf,%ecx
80105ed8:	83 e1 cf             	and    $0xffffffcf,%ecx
80105edb:	83 c9 c0             	or     $0xffffffc0,%ecx
80105ede:	88 88 76 18 13 80    	mov    %cl,-0x7fece78a(%eax)
80105ee4:	c6 80 77 18 13 80 00 	movb   $0x0,-0x7fece789(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80105eeb:	05 50 18 13 80       	add    $0x80131850,%eax
  pd[0] = size-1;
80105ef0:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80105ef6:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80105efa:	c1 e8 10             	shr    $0x10,%eax
80105efd:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80105f01:	8d 45 f2             	lea    -0xe(%ebp),%eax
80105f04:	0f 01 10             	lgdtl  (%eax)
}
80105f07:	83 c4 14             	add    $0x14,%esp
80105f0a:	5b                   	pop    %ebx
80105f0b:	5d                   	pop    %ebp
80105f0c:	c3                   	ret    

80105f0d <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80105f0d:	55                   	push   %ebp
80105f0e:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80105f10:	a1 04 45 13 80       	mov    0x80134504,%eax
80105f15:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80105f1a:	0f 22 d8             	mov    %eax,%cr3
}
80105f1d:	5d                   	pop    %ebp
80105f1e:	c3                   	ret    

80105f1f <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80105f1f:	55                   	push   %ebp
80105f20:	89 e5                	mov    %esp,%ebp
80105f22:	57                   	push   %edi
80105f23:	56                   	push   %esi
80105f24:	53                   	push   %ebx
80105f25:	83 ec 1c             	sub    $0x1c,%esp
80105f28:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
80105f2b:	85 f6                	test   %esi,%esi
80105f2d:	0f 84 dd 00 00 00    	je     80106010 <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
80105f33:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
80105f37:	0f 84 e0 00 00 00    	je     8010601d <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
80105f3d:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
80105f41:	0f 84 e3 00 00 00    	je     8010602a <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
80105f47:	e8 55 dc ff ff       	call   80103ba1 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80105f4c:	e8 b5 d2 ff ff       	call   80103206 <mycpu>
80105f51:	89 c3                	mov    %eax,%ebx
80105f53:	e8 ae d2 ff ff       	call   80103206 <mycpu>
80105f58:	8d 78 08             	lea    0x8(%eax),%edi
80105f5b:	e8 a6 d2 ff ff       	call   80103206 <mycpu>
80105f60:	83 c0 08             	add    $0x8,%eax
80105f63:	c1 e8 10             	shr    $0x10,%eax
80105f66:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105f69:	e8 98 d2 ff ff       	call   80103206 <mycpu>
80105f6e:	83 c0 08             	add    $0x8,%eax
80105f71:	c1 e8 18             	shr    $0x18,%eax
80105f74:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80105f7b:	67 00 
80105f7d:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80105f84:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
80105f88:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80105f8e:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80105f95:	83 e2 f0             	and    $0xfffffff0,%edx
80105f98:	83 ca 19             	or     $0x19,%edx
80105f9b:	83 e2 9f             	and    $0xffffff9f,%edx
80105f9e:	83 ca 80             	or     $0xffffff80,%edx
80105fa1:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80105fa7:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
80105fae:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80105fb4:	e8 4d d2 ff ff       	call   80103206 <mycpu>
80105fb9:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80105fc0:	83 e2 ef             	and    $0xffffffef,%edx
80105fc3:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80105fc9:	e8 38 d2 ff ff       	call   80103206 <mycpu>
80105fce:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80105fd4:	8b 5e 08             	mov    0x8(%esi),%ebx
80105fd7:	e8 2a d2 ff ff       	call   80103206 <mycpu>
80105fdc:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80105fe2:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
80105fe5:	e8 1c d2 ff ff       	call   80103206 <mycpu>
80105fea:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
80105ff0:	b8 28 00 00 00       	mov    $0x28,%eax
80105ff5:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
80105ff8:	8b 46 04             	mov    0x4(%esi),%eax
80105ffb:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
80106000:	0f 22 d8             	mov    %eax,%cr3
  popcli();
80106003:	e8 d6 db ff ff       	call   80103bde <popcli>
}
80106008:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010600b:	5b                   	pop    %ebx
8010600c:	5e                   	pop    %esi
8010600d:	5f                   	pop    %edi
8010600e:	5d                   	pop    %ebp
8010600f:	c3                   	ret    
    panic("switchuvm: no process");
80106010:	83 ec 0c             	sub    $0xc,%esp
80106013:	68 92 6e 10 80       	push   $0x80106e92
80106018:	e8 2b a3 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
8010601d:	83 ec 0c             	sub    $0xc,%esp
80106020:	68 a8 6e 10 80       	push   $0x80106ea8
80106025:	e8 1e a3 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
8010602a:	83 ec 0c             	sub    $0xc,%esp
8010602d:	68 bd 6e 10 80       	push   $0x80106ebd
80106032:	e8 11 a3 ff ff       	call   80100348 <panic>

80106037 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80106037:	55                   	push   %ebp
80106038:	89 e5                	mov    %esp,%ebp
8010603a:	56                   	push   %esi
8010603b:	53                   	push   %ebx
8010603c:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
8010603f:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106045:	77 51                	ja     80106098 <inituvm+0x61>
    panic("inituvm: more than a page");
  mem = kalloc2(-2);
80106047:	83 ec 0c             	sub    $0xc,%esp
8010604a:	6a fe                	push   $0xfffffffe
8010604c:	e8 bf c0 ff ff       	call   80102110 <kalloc2>
80106051:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
80106053:	83 c4 0c             	add    $0xc,%esp
80106056:	68 00 10 00 00       	push   $0x1000
8010605b:	6a 00                	push   $0x0
8010605d:	50                   	push   %eax
8010605e:	e8 c7 dc ff ff       	call   80103d2a <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
80106063:	83 c4 08             	add    $0x8,%esp
80106066:	6a 06                	push   $0x6
80106068:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
8010606e:	50                   	push   %eax
8010606f:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106074:	ba 00 00 00 00       	mov    $0x0,%edx
80106079:	8b 45 08             	mov    0x8(%ebp),%eax
8010607c:	e8 ca fc ff ff       	call   80105d4b <mappages>
  memmove(mem, init, sz);
80106081:	83 c4 0c             	add    $0xc,%esp
80106084:	56                   	push   %esi
80106085:	ff 75 0c             	pushl  0xc(%ebp)
80106088:	53                   	push   %ebx
80106089:	e8 17 dd ff ff       	call   80103da5 <memmove>
}
8010608e:	83 c4 10             	add    $0x10,%esp
80106091:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106094:	5b                   	pop    %ebx
80106095:	5e                   	pop    %esi
80106096:	5d                   	pop    %ebp
80106097:	c3                   	ret    
    panic("inituvm: more than a page");
80106098:	83 ec 0c             	sub    $0xc,%esp
8010609b:	68 d1 6e 10 80       	push   $0x80106ed1
801060a0:	e8 a3 a2 ff ff       	call   80100348 <panic>

801060a5 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
801060a5:	55                   	push   %ebp
801060a6:	89 e5                	mov    %esp,%ebp
801060a8:	57                   	push   %edi
801060a9:	56                   	push   %esi
801060aa:	53                   	push   %ebx
801060ab:	83 ec 0c             	sub    $0xc,%esp
801060ae:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
801060b1:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
801060b8:	75 07                	jne    801060c1 <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
801060ba:	bb 00 00 00 00       	mov    $0x0,%ebx
801060bf:	eb 3c                	jmp    801060fd <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
801060c1:	83 ec 0c             	sub    $0xc,%esp
801060c4:	68 8c 6f 10 80       	push   $0x80106f8c
801060c9:	e8 7a a2 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
801060ce:	83 ec 0c             	sub    $0xc,%esp
801060d1:	68 eb 6e 10 80       	push   $0x80106eeb
801060d6:	e8 6d a2 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
801060db:	05 00 00 00 80       	add    $0x80000000,%eax
801060e0:	56                   	push   %esi
801060e1:	89 da                	mov    %ebx,%edx
801060e3:	03 55 14             	add    0x14(%ebp),%edx
801060e6:	52                   	push   %edx
801060e7:	50                   	push   %eax
801060e8:	ff 75 10             	pushl  0x10(%ebp)
801060eb:	e8 83 b6 ff ff       	call   80101773 <readi>
801060f0:	83 c4 10             	add    $0x10,%esp
801060f3:	39 f0                	cmp    %esi,%eax
801060f5:	75 47                	jne    8010613e <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
801060f7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801060fd:	39 fb                	cmp    %edi,%ebx
801060ff:	73 30                	jae    80106131 <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80106101:	89 da                	mov    %ebx,%edx
80106103:	03 55 0c             	add    0xc(%ebp),%edx
80106106:	b9 00 00 00 00       	mov    $0x0,%ecx
8010610b:	8b 45 08             	mov    0x8(%ebp),%eax
8010610e:	e8 c0 fb ff ff       	call   80105cd3 <walkpgdir>
80106113:	85 c0                	test   %eax,%eax
80106115:	74 b7                	je     801060ce <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
80106117:	8b 00                	mov    (%eax),%eax
80106119:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
8010611e:	89 fe                	mov    %edi,%esi
80106120:	29 de                	sub    %ebx,%esi
80106122:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106128:	76 b1                	jbe    801060db <loaduvm+0x36>
      n = PGSIZE;
8010612a:	be 00 10 00 00       	mov    $0x1000,%esi
8010612f:	eb aa                	jmp    801060db <loaduvm+0x36>
      return -1;
  }
  return 0;
80106131:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106136:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106139:	5b                   	pop    %ebx
8010613a:	5e                   	pop    %esi
8010613b:	5f                   	pop    %edi
8010613c:	5d                   	pop    %ebp
8010613d:	c3                   	ret    
      return -1;
8010613e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106143:	eb f1                	jmp    80106136 <loaduvm+0x91>

80106145 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80106145:	55                   	push   %ebp
80106146:	89 e5                	mov    %esp,%ebp
80106148:	57                   	push   %edi
80106149:	56                   	push   %esi
8010614a:	53                   	push   %ebx
8010614b:	83 ec 0c             	sub    $0xc,%esp
8010614e:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80106151:	39 7d 10             	cmp    %edi,0x10(%ebp)
80106154:	73 11                	jae    80106167 <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
80106156:	8b 45 10             	mov    0x10(%ebp),%eax
80106159:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
8010615f:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106165:	eb 19                	jmp    80106180 <deallocuvm+0x3b>
    return oldsz;
80106167:	89 f8                	mov    %edi,%eax
80106169:	eb 64                	jmp    801061cf <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
8010616b:	c1 eb 16             	shr    $0x16,%ebx
8010616e:	83 c3 01             	add    $0x1,%ebx
80106171:	c1 e3 16             	shl    $0x16,%ebx
80106174:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
8010617a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106180:	39 fb                	cmp    %edi,%ebx
80106182:	73 48                	jae    801061cc <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
80106184:	b9 00 00 00 00       	mov    $0x0,%ecx
80106189:	89 da                	mov    %ebx,%edx
8010618b:	8b 45 08             	mov    0x8(%ebp),%eax
8010618e:	e8 40 fb ff ff       	call   80105cd3 <walkpgdir>
80106193:	89 c6                	mov    %eax,%esi
    if(!pte)
80106195:	85 c0                	test   %eax,%eax
80106197:	74 d2                	je     8010616b <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
80106199:	8b 00                	mov    (%eax),%eax
8010619b:	a8 01                	test   $0x1,%al
8010619d:	74 db                	je     8010617a <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
8010619f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801061a4:	74 19                	je     801061bf <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
801061a6:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801061ab:	83 ec 0c             	sub    $0xc,%esp
801061ae:	50                   	push   %eax
801061af:	e8 f0 bd ff ff       	call   80101fa4 <kfree>
      *pte = 0;
801061b4:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
801061ba:	83 c4 10             	add    $0x10,%esp
801061bd:	eb bb                	jmp    8010617a <deallocuvm+0x35>
        panic("kfree");
801061bf:	83 ec 0c             	sub    $0xc,%esp
801061c2:	68 06 68 10 80       	push   $0x80106806
801061c7:	e8 7c a1 ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
801061cc:	8b 45 10             	mov    0x10(%ebp),%eax
}
801061cf:	8d 65 f4             	lea    -0xc(%ebp),%esp
801061d2:	5b                   	pop    %ebx
801061d3:	5e                   	pop    %esi
801061d4:	5f                   	pop    %edi
801061d5:	5d                   	pop    %ebp
801061d6:	c3                   	ret    

801061d7 <allocuvm>:
{
801061d7:	55                   	push   %ebp
801061d8:	89 e5                	mov    %esp,%ebp
801061da:	57                   	push   %edi
801061db:	56                   	push   %esi
801061dc:	53                   	push   %ebx
801061dd:	83 ec 1c             	sub    $0x1c,%esp
801061e0:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
801061e3:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801061e6:	85 ff                	test   %edi,%edi
801061e8:	0f 88 cf 00 00 00    	js     801062bd <allocuvm+0xe6>
  if(newsz < oldsz)
801061ee:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801061f1:	72 6a                	jb     8010625d <allocuvm+0x86>
  a = PGROUNDUP(oldsz);
801061f3:	8b 45 0c             	mov    0xc(%ebp),%eax
801061f6:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801061fc:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
80106202:	39 fb                	cmp    %edi,%ebx
80106204:	0f 83 ba 00 00 00    	jae    801062c4 <allocuvm+0xed>
    mem = kalloc2(myproc()->pid);
8010620a:	e8 6e d0 ff ff       	call   8010327d <myproc>
8010620f:	83 ec 0c             	sub    $0xc,%esp
80106212:	ff 70 10             	pushl  0x10(%eax)
80106215:	e8 f6 be ff ff       	call   80102110 <kalloc2>
8010621a:	89 c6                	mov    %eax,%esi
    if(mem == 0){
8010621c:	83 c4 10             	add    $0x10,%esp
8010621f:	85 c0                	test   %eax,%eax
80106221:	74 42                	je     80106265 <allocuvm+0x8e>
    memset(mem, 0, PGSIZE);
80106223:	83 ec 04             	sub    $0x4,%esp
80106226:	68 00 10 00 00       	push   $0x1000
8010622b:	6a 00                	push   $0x0
8010622d:	50                   	push   %eax
8010622e:	e8 f7 da ff ff       	call   80103d2a <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
80106233:	83 c4 08             	add    $0x8,%esp
80106236:	6a 06                	push   $0x6
80106238:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
8010623e:	50                   	push   %eax
8010623f:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106244:	89 da                	mov    %ebx,%edx
80106246:	8b 45 08             	mov    0x8(%ebp),%eax
80106249:	e8 fd fa ff ff       	call   80105d4b <mappages>
8010624e:	83 c4 10             	add    $0x10,%esp
80106251:	85 c0                	test   %eax,%eax
80106253:	78 38                	js     8010628d <allocuvm+0xb6>
  for(; a < newsz; a += PGSIZE){
80106255:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010625b:	eb a5                	jmp    80106202 <allocuvm+0x2b>
    return oldsz;
8010625d:	8b 45 0c             	mov    0xc(%ebp),%eax
80106260:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106263:	eb 5f                	jmp    801062c4 <allocuvm+0xed>
      cprintf("allocuvm out of memory\n");
80106265:	83 ec 0c             	sub    $0xc,%esp
80106268:	68 09 6f 10 80       	push   $0x80106f09
8010626d:	e8 99 a3 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106272:	83 c4 0c             	add    $0xc,%esp
80106275:	ff 75 0c             	pushl  0xc(%ebp)
80106278:	57                   	push   %edi
80106279:	ff 75 08             	pushl  0x8(%ebp)
8010627c:	e8 c4 fe ff ff       	call   80106145 <deallocuvm>
      return 0;
80106281:	83 c4 10             	add    $0x10,%esp
80106284:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010628b:	eb 37                	jmp    801062c4 <allocuvm+0xed>
      cprintf("allocuvm out of memory (2)\n");
8010628d:	83 ec 0c             	sub    $0xc,%esp
80106290:	68 21 6f 10 80       	push   $0x80106f21
80106295:	e8 71 a3 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010629a:	83 c4 0c             	add    $0xc,%esp
8010629d:	ff 75 0c             	pushl  0xc(%ebp)
801062a0:	57                   	push   %edi
801062a1:	ff 75 08             	pushl  0x8(%ebp)
801062a4:	e8 9c fe ff ff       	call   80106145 <deallocuvm>
      kfree(mem);
801062a9:	89 34 24             	mov    %esi,(%esp)
801062ac:	e8 f3 bc ff ff       	call   80101fa4 <kfree>
      return 0;
801062b1:	83 c4 10             	add    $0x10,%esp
801062b4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801062bb:	eb 07                	jmp    801062c4 <allocuvm+0xed>
    return 0;
801062bd:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
801062c4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801062c7:	8d 65 f4             	lea    -0xc(%ebp),%esp
801062ca:	5b                   	pop    %ebx
801062cb:	5e                   	pop    %esi
801062cc:	5f                   	pop    %edi
801062cd:	5d                   	pop    %ebp
801062ce:	c3                   	ret    

801062cf <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801062cf:	55                   	push   %ebp
801062d0:	89 e5                	mov    %esp,%ebp
801062d2:	56                   	push   %esi
801062d3:	53                   	push   %ebx
801062d4:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
801062d7:	85 f6                	test   %esi,%esi
801062d9:	74 1a                	je     801062f5 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
801062db:	83 ec 04             	sub    $0x4,%esp
801062de:	6a 00                	push   $0x0
801062e0:	68 00 00 00 80       	push   $0x80000000
801062e5:	56                   	push   %esi
801062e6:	e8 5a fe ff ff       	call   80106145 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
801062eb:	83 c4 10             	add    $0x10,%esp
801062ee:	bb 00 00 00 00       	mov    $0x0,%ebx
801062f3:	eb 10                	jmp    80106305 <freevm+0x36>
    panic("freevm: no pgdir");
801062f5:	83 ec 0c             	sub    $0xc,%esp
801062f8:	68 3d 6f 10 80       	push   $0x80106f3d
801062fd:	e8 46 a0 ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
80106302:	83 c3 01             	add    $0x1,%ebx
80106305:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
8010630b:	77 1f                	ja     8010632c <freevm+0x5d>
    if(pgdir[i] & PTE_P){
8010630d:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
80106310:	a8 01                	test   $0x1,%al
80106312:	74 ee                	je     80106302 <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
80106314:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106319:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
8010631e:	83 ec 0c             	sub    $0xc,%esp
80106321:	50                   	push   %eax
80106322:	e8 7d bc ff ff       	call   80101fa4 <kfree>
80106327:	83 c4 10             	add    $0x10,%esp
8010632a:	eb d6                	jmp    80106302 <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
8010632c:	83 ec 0c             	sub    $0xc,%esp
8010632f:	56                   	push   %esi
80106330:	e8 6f bc ff ff       	call   80101fa4 <kfree>
}
80106335:	83 c4 10             	add    $0x10,%esp
80106338:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010633b:	5b                   	pop    %ebx
8010633c:	5e                   	pop    %esi
8010633d:	5d                   	pop    %ebp
8010633e:	c3                   	ret    

8010633f <setupkvm>:
{
8010633f:	55                   	push   %ebp
80106340:	89 e5                	mov    %esp,%ebp
80106342:	56                   	push   %esi
80106343:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc2(-2)) == 0)
80106344:	83 ec 0c             	sub    $0xc,%esp
80106347:	6a fe                	push   $0xfffffffe
80106349:	e8 c2 bd ff ff       	call   80102110 <kalloc2>
8010634e:	89 c6                	mov    %eax,%esi
80106350:	83 c4 10             	add    $0x10,%esp
80106353:	85 c0                	test   %eax,%eax
80106355:	74 55                	je     801063ac <setupkvm+0x6d>
  memset(pgdir, 0, PGSIZE);
80106357:	83 ec 04             	sub    $0x4,%esp
8010635a:	68 00 10 00 00       	push   $0x1000
8010635f:	6a 00                	push   $0x0
80106361:	50                   	push   %eax
80106362:	e8 c3 d9 ff ff       	call   80103d2a <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106367:	83 c4 10             	add    $0x10,%esp
8010636a:	bb 20 94 10 80       	mov    $0x80109420,%ebx
8010636f:	81 fb 60 94 10 80    	cmp    $0x80109460,%ebx
80106375:	73 35                	jae    801063ac <setupkvm+0x6d>
                (uint)k->phys_start, k->perm) < 0) {
80106377:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
8010637a:	8b 4b 08             	mov    0x8(%ebx),%ecx
8010637d:	29 c1                	sub    %eax,%ecx
8010637f:	83 ec 08             	sub    $0x8,%esp
80106382:	ff 73 0c             	pushl  0xc(%ebx)
80106385:	50                   	push   %eax
80106386:	8b 13                	mov    (%ebx),%edx
80106388:	89 f0                	mov    %esi,%eax
8010638a:	e8 bc f9 ff ff       	call   80105d4b <mappages>
8010638f:	83 c4 10             	add    $0x10,%esp
80106392:	85 c0                	test   %eax,%eax
80106394:	78 05                	js     8010639b <setupkvm+0x5c>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106396:	83 c3 10             	add    $0x10,%ebx
80106399:	eb d4                	jmp    8010636f <setupkvm+0x30>
      freevm(pgdir);
8010639b:	83 ec 0c             	sub    $0xc,%esp
8010639e:	56                   	push   %esi
8010639f:	e8 2b ff ff ff       	call   801062cf <freevm>
      return 0;
801063a4:	83 c4 10             	add    $0x10,%esp
801063a7:	be 00 00 00 00       	mov    $0x0,%esi
}
801063ac:	89 f0                	mov    %esi,%eax
801063ae:	8d 65 f8             	lea    -0x8(%ebp),%esp
801063b1:	5b                   	pop    %ebx
801063b2:	5e                   	pop    %esi
801063b3:	5d                   	pop    %ebp
801063b4:	c3                   	ret    

801063b5 <kvmalloc>:
{
801063b5:	55                   	push   %ebp
801063b6:	89 e5                	mov    %esp,%ebp
801063b8:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
801063bb:	e8 7f ff ff ff       	call   8010633f <setupkvm>
801063c0:	a3 04 45 13 80       	mov    %eax,0x80134504
  switchkvm();
801063c5:	e8 43 fb ff ff       	call   80105f0d <switchkvm>
}
801063ca:	c9                   	leave  
801063cb:	c3                   	ret    

801063cc <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801063cc:	55                   	push   %ebp
801063cd:	89 e5                	mov    %esp,%ebp
801063cf:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801063d2:	b9 00 00 00 00       	mov    $0x0,%ecx
801063d7:	8b 55 0c             	mov    0xc(%ebp),%edx
801063da:	8b 45 08             	mov    0x8(%ebp),%eax
801063dd:	e8 f1 f8 ff ff       	call   80105cd3 <walkpgdir>
  if(pte == 0)
801063e2:	85 c0                	test   %eax,%eax
801063e4:	74 05                	je     801063eb <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
801063e6:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
801063e9:	c9                   	leave  
801063ea:	c3                   	ret    
    panic("clearpteu");
801063eb:	83 ec 0c             	sub    $0xc,%esp
801063ee:	68 4e 6f 10 80       	push   $0x80106f4e
801063f3:	e8 50 9f ff ff       	call   80100348 <panic>

801063f8 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
801063f8:	55                   	push   %ebp
801063f9:	89 e5                	mov    %esp,%ebp
801063fb:	57                   	push   %edi
801063fc:	56                   	push   %esi
801063fd:	53                   	push   %ebx
801063fe:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80106401:	e8 39 ff ff ff       	call   8010633f <setupkvm>
80106406:	89 45 dc             	mov    %eax,-0x24(%ebp)
80106409:	85 c0                	test   %eax,%eax
8010640b:	0f 84 c4 00 00 00    	je     801064d5 <copyuvm+0xdd>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80106411:	bf 00 00 00 00       	mov    $0x0,%edi
80106416:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106419:	0f 83 b6 00 00 00    	jae    801064d5 <copyuvm+0xdd>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
8010641f:	89 7d e4             	mov    %edi,-0x1c(%ebp)
80106422:	b9 00 00 00 00       	mov    $0x0,%ecx
80106427:	89 fa                	mov    %edi,%edx
80106429:	8b 45 08             	mov    0x8(%ebp),%eax
8010642c:	e8 a2 f8 ff ff       	call   80105cd3 <walkpgdir>
80106431:	85 c0                	test   %eax,%eax
80106433:	74 65                	je     8010649a <copyuvm+0xa2>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
80106435:	8b 00                	mov    (%eax),%eax
80106437:	a8 01                	test   $0x1,%al
80106439:	74 6c                	je     801064a7 <copyuvm+0xaf>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
8010643b:	89 c6                	mov    %eax,%esi
8010643d:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
80106443:	25 ff 0f 00 00       	and    $0xfff,%eax
80106448:	89 45 e0             	mov    %eax,-0x20(%ebp)
    if((mem = kalloc()) == 0)
8010644b:	e8 6b bc ff ff       	call   801020bb <kalloc>
80106450:	89 c3                	mov    %eax,%ebx
80106452:	85 c0                	test   %eax,%eax
80106454:	74 6a                	je     801064c0 <copyuvm+0xc8>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
80106456:	81 c6 00 00 00 80    	add    $0x80000000,%esi
8010645c:	83 ec 04             	sub    $0x4,%esp
8010645f:	68 00 10 00 00       	push   $0x1000
80106464:	56                   	push   %esi
80106465:	50                   	push   %eax
80106466:	e8 3a d9 ff ff       	call   80103da5 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
8010646b:	83 c4 08             	add    $0x8,%esp
8010646e:	ff 75 e0             	pushl  -0x20(%ebp)
80106471:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106477:	50                   	push   %eax
80106478:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010647d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106480:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106483:	e8 c3 f8 ff ff       	call   80105d4b <mappages>
80106488:	83 c4 10             	add    $0x10,%esp
8010648b:	85 c0                	test   %eax,%eax
8010648d:	78 25                	js     801064b4 <copyuvm+0xbc>
  for(i = 0; i < sz; i += PGSIZE){
8010648f:	81 c7 00 10 00 00    	add    $0x1000,%edi
80106495:	e9 7c ff ff ff       	jmp    80106416 <copyuvm+0x1e>
      panic("copyuvm: pte should exist");
8010649a:	83 ec 0c             	sub    $0xc,%esp
8010649d:	68 58 6f 10 80       	push   $0x80106f58
801064a2:	e8 a1 9e ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
801064a7:	83 ec 0c             	sub    $0xc,%esp
801064aa:	68 72 6f 10 80       	push   $0x80106f72
801064af:	e8 94 9e ff ff       	call   80100348 <panic>
      kfree(mem);
801064b4:	83 ec 0c             	sub    $0xc,%esp
801064b7:	53                   	push   %ebx
801064b8:	e8 e7 ba ff ff       	call   80101fa4 <kfree>
      goto bad;
801064bd:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
801064c0:	83 ec 0c             	sub    $0xc,%esp
801064c3:	ff 75 dc             	pushl  -0x24(%ebp)
801064c6:	e8 04 fe ff ff       	call   801062cf <freevm>
  return 0;
801064cb:	83 c4 10             	add    $0x10,%esp
801064ce:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
801064d5:	8b 45 dc             	mov    -0x24(%ebp),%eax
801064d8:	8d 65 f4             	lea    -0xc(%ebp),%esp
801064db:	5b                   	pop    %ebx
801064dc:	5e                   	pop    %esi
801064dd:	5f                   	pop    %edi
801064de:	5d                   	pop    %ebp
801064df:	c3                   	ret    

801064e0 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801064e0:	55                   	push   %ebp
801064e1:	89 e5                	mov    %esp,%ebp
801064e3:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801064e6:	b9 00 00 00 00       	mov    $0x0,%ecx
801064eb:	8b 55 0c             	mov    0xc(%ebp),%edx
801064ee:	8b 45 08             	mov    0x8(%ebp),%eax
801064f1:	e8 dd f7 ff ff       	call   80105cd3 <walkpgdir>
  if((*pte & PTE_P) == 0)
801064f6:	8b 00                	mov    (%eax),%eax
801064f8:	a8 01                	test   $0x1,%al
801064fa:	74 10                	je     8010650c <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
801064fc:	a8 04                	test   $0x4,%al
801064fe:	74 13                	je     80106513 <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
80106500:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106505:	05 00 00 00 80       	add    $0x80000000,%eax
}
8010650a:	c9                   	leave  
8010650b:	c3                   	ret    
    return 0;
8010650c:	b8 00 00 00 00       	mov    $0x0,%eax
80106511:	eb f7                	jmp    8010650a <uva2ka+0x2a>
    return 0;
80106513:	b8 00 00 00 00       	mov    $0x0,%eax
80106518:	eb f0                	jmp    8010650a <uva2ka+0x2a>

8010651a <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
8010651a:	55                   	push   %ebp
8010651b:	89 e5                	mov    %esp,%ebp
8010651d:	57                   	push   %edi
8010651e:	56                   	push   %esi
8010651f:	53                   	push   %ebx
80106520:	83 ec 0c             	sub    $0xc,%esp
80106523:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80106526:	eb 25                	jmp    8010654d <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
80106528:	8b 55 0c             	mov    0xc(%ebp),%edx
8010652b:	29 f2                	sub    %esi,%edx
8010652d:	01 d0                	add    %edx,%eax
8010652f:	83 ec 04             	sub    $0x4,%esp
80106532:	53                   	push   %ebx
80106533:	ff 75 10             	pushl  0x10(%ebp)
80106536:	50                   	push   %eax
80106537:	e8 69 d8 ff ff       	call   80103da5 <memmove>
    len -= n;
8010653c:	29 df                	sub    %ebx,%edi
    buf += n;
8010653e:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
80106541:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
80106547:	89 45 0c             	mov    %eax,0xc(%ebp)
8010654a:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
8010654d:	85 ff                	test   %edi,%edi
8010654f:	74 2f                	je     80106580 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
80106551:	8b 75 0c             	mov    0xc(%ebp),%esi
80106554:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
8010655a:	83 ec 08             	sub    $0x8,%esp
8010655d:	56                   	push   %esi
8010655e:	ff 75 08             	pushl  0x8(%ebp)
80106561:	e8 7a ff ff ff       	call   801064e0 <uva2ka>
    if(pa0 == 0)
80106566:	83 c4 10             	add    $0x10,%esp
80106569:	85 c0                	test   %eax,%eax
8010656b:	74 20                	je     8010658d <copyout+0x73>
    n = PGSIZE - (va - va0);
8010656d:	89 f3                	mov    %esi,%ebx
8010656f:	2b 5d 0c             	sub    0xc(%ebp),%ebx
80106572:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
80106578:	39 df                	cmp    %ebx,%edi
8010657a:	73 ac                	jae    80106528 <copyout+0xe>
      n = len;
8010657c:	89 fb                	mov    %edi,%ebx
8010657e:	eb a8                	jmp    80106528 <copyout+0xe>
  }
  return 0;
80106580:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106585:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106588:	5b                   	pop    %ebx
80106589:	5e                   	pop    %esi
8010658a:	5f                   	pop    %edi
8010658b:	5d                   	pop    %ebp
8010658c:	c3                   	ret    
      return -1;
8010658d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106592:	eb f1                	jmp    80106585 <copyout+0x6b>
