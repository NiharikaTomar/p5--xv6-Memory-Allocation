
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
80100015:	b8 00 90 10 00       	mov    $0x109000,%eax
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
80100028:	bc d0 b5 10 80       	mov    $0x8010b5d0,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 aa 2b 10 80       	mov    $0x80102baa,%eax
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
80100041:	68 e0 b5 10 80       	push   $0x8010b5e0
80100046:	e8 9b 3c 00 00       	call   80103ce6 <acquire>

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010004b:	8b 1d 30 fd 10 80    	mov    0x8010fd30,%ebx
80100051:	83 c4 10             	add    $0x10,%esp
80100054:	eb 03                	jmp    80100059 <bget+0x25>
80100056:	8b 5b 54             	mov    0x54(%ebx),%ebx
80100059:	81 fb dc fc 10 80    	cmp    $0x8010fcdc,%ebx
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
80100077:	68 e0 b5 10 80       	push   $0x8010b5e0
8010007c:	e8 ca 3c 00 00       	call   80103d4b <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 46 3a 00 00       	call   80103ad2 <acquiresleep>
      return b;
8010008c:	83 c4 10             	add    $0x10,%esp
8010008f:	eb 4c                	jmp    801000dd <bget+0xa9>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100091:	8b 1d 2c fd 10 80    	mov    0x8010fd2c,%ebx
80100097:	eb 03                	jmp    8010009c <bget+0x68>
80100099:	8b 5b 50             	mov    0x50(%ebx),%ebx
8010009c:	81 fb dc fc 10 80    	cmp    $0x8010fcdc,%ebx
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
801000c5:	68 e0 b5 10 80       	push   $0x8010b5e0
801000ca:	e8 7c 3c 00 00       	call   80103d4b <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 f8 39 00 00       	call   80103ad2 <acquiresleep>
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
801000ea:	68 20 66 10 80       	push   $0x80106620
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 31 66 10 80       	push   $0x80106631
80100100:	68 e0 b5 10 80       	push   $0x8010b5e0
80100105:	e8 a0 3a 00 00       	call   80103baa <initlock>
  bcache.head.prev = &bcache.head;
8010010a:	c7 05 2c fd 10 80 dc 	movl   $0x8010fcdc,0x8010fd2c
80100111:	fc 10 80 
  bcache.head.next = &bcache.head;
80100114:	c7 05 30 fd 10 80 dc 	movl   $0x8010fcdc,0x8010fd30
8010011b:	fc 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010011e:	83 c4 10             	add    $0x10,%esp
80100121:	bb 14 b6 10 80       	mov    $0x8010b614,%ebx
80100126:	eb 37                	jmp    8010015f <binit+0x6b>
    b->next = bcache.head.next;
80100128:	a1 30 fd 10 80       	mov    0x8010fd30,%eax
8010012d:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
80100130:	c7 43 50 dc fc 10 80 	movl   $0x8010fcdc,0x50(%ebx)
    initsleeplock(&b->lock, "buffer");
80100137:	83 ec 08             	sub    $0x8,%esp
8010013a:	68 38 66 10 80       	push   $0x80106638
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 57 39 00 00       	call   80103a9f <initsleeplock>
    bcache.head.next->prev = b;
80100148:	a1 30 fd 10 80       	mov    0x8010fd30,%eax
8010014d:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
80100150:	89 1d 30 fd 10 80    	mov    %ebx,0x8010fd30
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100156:	81 c3 5c 02 00 00    	add    $0x25c,%ebx
8010015c:	83 c4 10             	add    $0x10,%esp
8010015f:	81 fb dc fc 10 80    	cmp    $0x8010fcdc,%ebx
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
801001a8:	e8 af 39 00 00       	call   80103b5c <holdingsleep>
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
801001cb:	68 3f 66 10 80       	push   $0x8010663f
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
801001e4:	e8 73 39 00 00       	call   80103b5c <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 28 39 00 00       	call   80103b21 <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 e0 b5 10 80 	movl   $0x8010b5e0,(%esp)
80100200:	e8 e1 3a 00 00       	call   80103ce6 <acquire>
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
80100227:	a1 30 fd 10 80       	mov    0x8010fd30,%eax
8010022c:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
8010022f:	c7 43 50 dc fc 10 80 	movl   $0x8010fcdc,0x50(%ebx)
    bcache.head.next->prev = b;
80100236:	a1 30 fd 10 80       	mov    0x8010fd30,%eax
8010023b:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
8010023e:	89 1d 30 fd 10 80    	mov    %ebx,0x8010fd30
  }
  
  release(&bcache.lock);
80100244:	83 ec 0c             	sub    $0xc,%esp
80100247:	68 e0 b5 10 80       	push   $0x8010b5e0
8010024c:	e8 fa 3a 00 00       	call   80103d4b <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 46 66 10 80       	push   $0x80106646
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
80100283:	c7 04 24 20 a5 10 80 	movl   $0x8010a520,(%esp)
8010028a:	e8 57 3a 00 00       	call   80103ce6 <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 c0 ff 10 80       	mov    0x8010ffc0,%eax
8010029f:	3b 05 c4 ff 10 80    	cmp    0x8010ffc4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 98 30 00 00       	call   80103344 <myproc>
801002ac:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801002b0:	75 17                	jne    801002c9 <consoleread+0x61>
        release(&cons.lock);
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
801002b2:	83 ec 08             	sub    $0x8,%esp
801002b5:	68 20 a5 10 80       	push   $0x8010a520
801002ba:	68 c0 ff 10 80       	push   $0x8010ffc0
801002bf:	e8 27 35 00 00       	call   801037eb <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 a5 10 80       	push   $0x8010a520
801002d1:	e8 75 3a 00 00       	call   80103d4b <release>
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
801002f1:	89 15 c0 ff 10 80    	mov    %edx,0x8010ffc0
801002f7:	89 c2                	mov    %eax,%edx
801002f9:	83 e2 7f             	and    $0x7f,%edx
801002fc:	0f b6 8a 40 ff 10 80 	movzbl -0x7fef00c0(%edx),%ecx
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
80100324:	a3 c0 ff 10 80       	mov    %eax,0x8010ffc0
  release(&cons.lock);
80100329:	83 ec 0c             	sub    $0xc,%esp
8010032c:	68 20 a5 10 80       	push   $0x8010a520
80100331:	e8 15 3a 00 00       	call   80103d4b <release>
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
80100350:	c7 05 54 a5 10 80 00 	movl   $0x0,0x8010a554
80100357:	00 00 00 
  cprintf("lapicid %d: panic: ", lapicid());
8010035a:	e8 65 21 00 00       	call   801024c4 <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 4d 66 10 80       	push   $0x8010664d
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 9b 6f 10 80 	movl   $0x80106f9b,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 31 38 00 00       	call   80103bc5 <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 61 66 10 80       	push   $0x80106661
801003aa:	e8 5c 02 00 00       	call   8010060b <cprintf>
  for(i=0; i<10; i++)
801003af:	83 c3 01             	add    $0x1,%ebx
801003b2:	83 c4 10             	add    $0x10,%esp
801003b5:	83 fb 09             	cmp    $0x9,%ebx
801003b8:	7e e4                	jle    8010039e <panic+0x56>
  panicked = 1; // freeze other CPU
801003ba:	c7 05 58 a5 10 80 01 	movl   $0x1,0x8010a558
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
8010049e:	68 65 66 10 80       	push   $0x80106665
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 4e 39 00 00       	call   80103e0d <memmove>
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
801004d9:	e8 b4 38 00 00       	call   80103d92 <memset>
801004de:	83 c4 10             	add    $0x10,%esp
801004e1:	e9 4c ff ff ff       	jmp    80100432 <cgaputc+0x6c>

801004e6 <consputc>:
  if(panicked){
801004e6:	83 3d 58 a5 10 80 00 	cmpl   $0x0,0x8010a558
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
80100506:	e8 c1 4c 00 00       	call   801051cc <uartputc>
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
8010051f:	e8 a8 4c 00 00       	call   801051cc <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 9c 4c 00 00       	call   801051cc <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 90 4c 00 00       	call   801051cc <uartputc>
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
80100576:	0f b6 92 90 66 10 80 	movzbl -0x7fef9970(%edx),%edx
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
801005c3:	c7 04 24 20 a5 10 80 	movl   $0x8010a520,(%esp)
801005ca:	e8 17 37 00 00       	call   80103ce6 <acquire>
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
801005ec:	68 20 a5 10 80       	push   $0x8010a520
801005f1:	e8 55 37 00 00       	call   80103d4b <release>
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
80100614:	a1 54 a5 10 80       	mov    0x8010a554,%eax
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
80100633:	68 20 a5 10 80       	push   $0x8010a520
80100638:	e8 a9 36 00 00       	call   80103ce6 <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 7f 66 10 80       	push   $0x8010667f
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
801006ee:	be 78 66 10 80       	mov    $0x80106678,%esi
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
8010072f:	68 20 a5 10 80       	push   $0x8010a520
80100734:	e8 12 36 00 00       	call   80103d4b <release>
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
8010074a:	68 20 a5 10 80       	push   $0x8010a520
8010074f:	e8 92 35 00 00       	call   80103ce6 <acquire>
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
80100772:	a1 c8 ff 10 80       	mov    0x8010ffc8,%eax
80100777:	89 c2                	mov    %eax,%edx
80100779:	2b 15 c0 ff 10 80    	sub    0x8010ffc0,%edx
8010077f:	83 fa 7f             	cmp    $0x7f,%edx
80100782:	0f 87 9e 00 00 00    	ja     80100826 <consoleintr+0xe8>
        c = (c == '\r') ? '\n' : c;
80100788:	83 ff 0d             	cmp    $0xd,%edi
8010078b:	0f 84 86 00 00 00    	je     80100817 <consoleintr+0xd9>
        input.buf[input.e++ % INPUT_BUF] = c;
80100791:	8d 50 01             	lea    0x1(%eax),%edx
80100794:	89 15 c8 ff 10 80    	mov    %edx,0x8010ffc8
8010079a:	83 e0 7f             	and    $0x7f,%eax
8010079d:	89 f9                	mov    %edi,%ecx
8010079f:	88 88 40 ff 10 80    	mov    %cl,-0x7fef00c0(%eax)
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
801007bc:	a1 c0 ff 10 80       	mov    0x8010ffc0,%eax
801007c1:	83 e8 80             	sub    $0xffffff80,%eax
801007c4:	39 05 c8 ff 10 80    	cmp    %eax,0x8010ffc8
801007ca:	75 5a                	jne    80100826 <consoleintr+0xe8>
          input.w = input.e;
801007cc:	a1 c8 ff 10 80       	mov    0x8010ffc8,%eax
801007d1:	a3 c4 ff 10 80       	mov    %eax,0x8010ffc4
          wakeup(&input.r);
801007d6:	83 ec 0c             	sub    $0xc,%esp
801007d9:	68 c0 ff 10 80       	push   $0x8010ffc0
801007de:	e8 6d 31 00 00       	call   80103950 <wakeup>
801007e3:	83 c4 10             	add    $0x10,%esp
801007e6:	eb 3e                	jmp    80100826 <consoleintr+0xe8>
        input.e--;
801007e8:	a3 c8 ff 10 80       	mov    %eax,0x8010ffc8
        consputc(BACKSPACE);
801007ed:	b8 00 01 00 00       	mov    $0x100,%eax
801007f2:	e8 ef fc ff ff       	call   801004e6 <consputc>
      while(input.e != input.w &&
801007f7:	a1 c8 ff 10 80       	mov    0x8010ffc8,%eax
801007fc:	3b 05 c4 ff 10 80    	cmp    0x8010ffc4,%eax
80100802:	74 22                	je     80100826 <consoleintr+0xe8>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100804:	83 e8 01             	sub    $0x1,%eax
80100807:	89 c2                	mov    %eax,%edx
80100809:	83 e2 7f             	and    $0x7f,%edx
      while(input.e != input.w &&
8010080c:	80 ba 40 ff 10 80 0a 	cmpb   $0xa,-0x7fef00c0(%edx)
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
8010084a:	a1 c8 ff 10 80       	mov    0x8010ffc8,%eax
8010084f:	3b 05 c4 ff 10 80    	cmp    0x8010ffc4,%eax
80100855:	74 cf                	je     80100826 <consoleintr+0xe8>
        input.e--;
80100857:	83 e8 01             	sub    $0x1,%eax
8010085a:	a3 c8 ff 10 80       	mov    %eax,0x8010ffc8
        consputc(BACKSPACE);
8010085f:	b8 00 01 00 00       	mov    $0x100,%eax
80100864:	e8 7d fc ff ff       	call   801004e6 <consputc>
80100869:	eb bb                	jmp    80100826 <consoleintr+0xe8>
  release(&cons.lock);
8010086b:	83 ec 0c             	sub    $0xc,%esp
8010086e:	68 20 a5 10 80       	push   $0x8010a520
80100873:	e8 d3 34 00 00       	call   80103d4b <release>
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
80100887:	e8 61 31 00 00       	call   801039ed <procdump>
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
80100894:	68 88 66 10 80       	push   $0x80106688
80100899:	68 20 a5 10 80       	push   $0x8010a520
8010089e:	e8 07 33 00 00       	call   80103baa <initlock>

  devsw[CONSOLE].write = consolewrite;
801008a3:	c7 05 8c 09 11 80 ac 	movl   $0x801005ac,0x8011098c
801008aa:	05 10 80 
  devsw[CONSOLE].read = consoleread;
801008ad:	c7 05 88 09 11 80 68 	movl   $0x80100268,0x80110988
801008b4:	02 10 80 
  cons.locking = 1;
801008b7:	c7 05 54 a5 10 80 01 	movl   $0x1,0x8010a554
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
801008de:	e8 61 2a 00 00       	call   80103344 <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 06 20 00 00       	call   801028f4 <begin_op>

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
80100935:	e8 34 20 00 00       	call   8010296e <end_op>
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
8010094a:	e8 1f 20 00 00       	call   8010296e <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 a1 66 10 80       	push   $0x801066a1
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
80100972:	e8 30 5a 00 00       	call   801063a7 <setupkvm>
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
80100a06:	e8 34 58 00 00       	call   8010623f <allocuvm>
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
80100a38:	e8 d0 56 00 00       	call   8010610d <loaduvm>
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
80100a53:	e8 16 1f 00 00       	call   8010296e <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 c6 57 00 00       	call   8010623f <allocuvm>
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
80100a9d:	e8 95 58 00 00       	call   80106337 <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 73 59 00 00       	call   80106434 <clearpteu>
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
80100ae2:	e8 4d 34 00 00       	call   80103f34 <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 3b 34 00 00       	call   80103f34 <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 84 5a 00 00       	call   8010658f <copyout>
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
80100b66:	e8 24 5a 00 00       	call   8010658f <copyout>
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
80100ba3:	e8 51 33 00 00       	call   80103ef9 <safestrcpy>
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
80100bd1:	e8 b1 53 00 00       	call   80105f87 <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 59 57 00 00       	call   80106337 <freevm>
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
80100c19:	68 ad 66 10 80       	push   $0x801066ad
80100c1e:	68 e0 ff 10 80       	push   $0x8010ffe0
80100c23:	e8 82 2f 00 00       	call   80103baa <initlock>
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
80100c34:	68 e0 ff 10 80       	push   $0x8010ffe0
80100c39:	e8 a8 30 00 00       	call   80103ce6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c3e:	83 c4 10             	add    $0x10,%esp
80100c41:	bb 14 00 11 80       	mov    $0x80110014,%ebx
80100c46:	81 fb 74 09 11 80    	cmp    $0x80110974,%ebx
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
80100c63:	68 e0 ff 10 80       	push   $0x8010ffe0
80100c68:	e8 de 30 00 00       	call   80103d4b <release>
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
80100c7a:	68 e0 ff 10 80       	push   $0x8010ffe0
80100c7f:	e8 c7 30 00 00       	call   80103d4b <release>
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
80100c98:	68 e0 ff 10 80       	push   $0x8010ffe0
80100c9d:	e8 44 30 00 00       	call   80103ce6 <acquire>
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
80100cb5:	68 e0 ff 10 80       	push   $0x8010ffe0
80100cba:	e8 8c 30 00 00       	call   80103d4b <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 b4 66 10 80       	push   $0x801066b4
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
80100cdd:	68 e0 ff 10 80       	push   $0x8010ffe0
80100ce2:	e8 ff 2f 00 00       	call   80103ce6 <acquire>
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
80100cfe:	68 e0 ff 10 80       	push   $0x8010ffe0
80100d03:	e8 43 30 00 00       	call   80103d4b <release>
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
80100d13:	68 bc 66 10 80       	push   $0x801066bc
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
80100d44:	68 e0 ff 10 80       	push   $0x8010ffe0
80100d49:	e8 fd 2f 00 00       	call   80103d4b <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 91 1b 00 00       	call   801028f4 <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 fb 1b 00 00       	call   8010296e <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 e8 21 00 00       	call   80102f70 <pipeclose>
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
80100e3c:	e8 87 22 00 00       	call   801030c8 <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 c6 66 10 80       	push   $0x801066c6
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
80100e95:	e8 62 21 00 00       	call   80102ffc <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 4d 1a 00 00       	call   801028f4 <begin_op>
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
80100edd:	e8 8c 1a 00 00       	call   8010296e <end_op>

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
80100f10:	68 cf 66 10 80       	push   $0x801066cf
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
80100f2d:	68 d5 66 10 80       	push   $0x801066d5
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
80100f8a:	e8 7e 2e 00 00       	call   80103e0d <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 6e 2e 00 00       	call   80103e0d <memmove>
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
80100fdf:	e8 ae 2d 00 00       	call   80103d92 <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 31 1a 00 00       	call   80102a1d <log_write>
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
80101023:	39 35 e0 09 11 80    	cmp    %esi,0x801109e0
80101029:	76 75                	jbe    801010a0 <balloc+0xa4>
    bp = bread(dev, BBLOCK(b, sb));
8010102b:	8d 86 ff 0f 00 00    	lea    0xfff(%esi),%eax
80101031:	85 f6                	test   %esi,%esi
80101033:	0f 49 c6             	cmovns %esi,%eax
80101036:	c1 f8 0c             	sar    $0xc,%eax
80101039:	03 05 f8 09 11 80    	add    0x801109f8,%eax
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
80101063:	3b 1d e0 09 11 80    	cmp    0x801109e0,%ebx
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
801010a3:	68 df 66 10 80       	push   $0x801066df
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
801010bf:	e8 59 19 00 00       	call   80102a1d <log_write>
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
80101170:	e8 a8 18 00 00       	call   80102a1d <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 f5 66 10 80       	push   $0x801066f5
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
80101195:	68 00 0a 11 80       	push   $0x80110a00
8010119a:	e8 47 2b 00 00       	call   80103ce6 <acquire>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010119f:	83 c4 10             	add    $0x10,%esp
  empty = 0;
801011a2:	be 00 00 00 00       	mov    $0x0,%esi
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011a7:	bb 34 0a 11 80       	mov    $0x80110a34,%ebx
801011ac:	eb 0a                	jmp    801011b8 <iget+0x31>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ae:	85 f6                	test   %esi,%esi
801011b0:	74 3b                	je     801011ed <iget+0x66>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011b2:	81 c3 90 00 00 00    	add    $0x90,%ebx
801011b8:	81 fb 54 26 11 80    	cmp    $0x80112654,%ebx
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
801011dc:	68 00 0a 11 80       	push   $0x80110a00
801011e1:	e8 65 2b 00 00       	call   80103d4b <release>
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
80101212:	68 00 0a 11 80       	push   $0x80110a00
80101217:	e8 2f 2b 00 00       	call   80103d4b <release>
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
8010122c:	68 08 67 10 80       	push   $0x80106708
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
80101255:	e8 b3 2b 00 00       	call   80103e0d <memmove>
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
80101276:	68 e0 09 11 80       	push   $0x801109e0
8010127b:	50                   	push   %eax
8010127c:	e8 b5 ff ff ff       	call   80101236 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
80101281:	89 d8                	mov    %ebx,%eax
80101283:	c1 e8 0c             	shr    $0xc,%eax
80101286:	03 05 f8 09 11 80    	add    0x801109f8,%eax
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
801012c8:	e8 50 17 00 00       	call   80102a1d <log_write>
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
801012e2:	68 18 67 10 80       	push   $0x80106718
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 2b 67 10 80       	push   $0x8010672b
801012f8:	68 00 0a 11 80       	push   $0x80110a00
801012fd:	e8 a8 28 00 00       	call   80103baa <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 32 67 10 80       	push   $0x80106732
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 40 0a 11 80       	add    $0x80110a40,%eax
80101321:	50                   	push   %eax
80101322:	e8 78 27 00 00       	call   80103a9f <initsleeplock>
  for(i = 0; i < NINODE; i++) {
80101327:	83 c3 01             	add    $0x1,%ebx
8010132a:	83 c4 10             	add    $0x10,%esp
8010132d:	83 fb 31             	cmp    $0x31,%ebx
80101330:	7e da                	jle    8010130c <iinit+0x20>
  readsb(dev, &sb);
80101332:	83 ec 08             	sub    $0x8,%esp
80101335:	68 e0 09 11 80       	push   $0x801109e0
8010133a:	ff 75 08             	pushl  0x8(%ebp)
8010133d:	e8 f4 fe ff ff       	call   80101236 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
80101342:	ff 35 f8 09 11 80    	pushl  0x801109f8
80101348:	ff 35 f4 09 11 80    	pushl  0x801109f4
8010134e:	ff 35 f0 09 11 80    	pushl  0x801109f0
80101354:	ff 35 ec 09 11 80    	pushl  0x801109ec
8010135a:	ff 35 e8 09 11 80    	pushl  0x801109e8
80101360:	ff 35 e4 09 11 80    	pushl  0x801109e4
80101366:	ff 35 e0 09 11 80    	pushl  0x801109e0
8010136c:	68 98 67 10 80       	push   $0x80106798
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
80101395:	39 1d e8 09 11 80    	cmp    %ebx,0x801109e8
8010139b:	76 3f                	jbe    801013dc <ialloc+0x5e>
    bp = bread(dev, IBLOCK(inum, sb));
8010139d:	89 d8                	mov    %ebx,%eax
8010139f:	c1 e8 03             	shr    $0x3,%eax
801013a2:	03 05 f4 09 11 80    	add    0x801109f4,%eax
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
801013df:	68 38 67 10 80       	push   $0x80106738
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 9c 29 00 00       	call   80103d92 <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 18 16 00 00       	call   80102a1d <log_write>
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
8010142e:	03 05 f4 09 11 80    	add    0x801109f4,%eax
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
80101480:	e8 88 29 00 00       	call   80103e0d <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 90 15 00 00       	call   80102a1d <log_write>
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
8010155b:	68 00 0a 11 80       	push   $0x80110a00
80101560:	e8 81 27 00 00       	call   80103ce6 <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 00 0a 11 80 	movl   $0x80110a00,(%esp)
80101575:	e8 d1 27 00 00       	call   80103d4b <release>
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
8010159a:	e8 33 25 00 00       	call   80103ad2 <acquiresleep>
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
801015b2:	68 4a 67 10 80       	push   $0x8010674a
801015b7:	e8 8c ed ff ff       	call   80100348 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
801015bc:	8b 43 04             	mov    0x4(%ebx),%eax
801015bf:	c1 e8 03             	shr    $0x3,%eax
801015c2:	03 05 f4 09 11 80    	add    0x801109f4,%eax
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
80101614:	e8 f4 27 00 00       	call   80103e0d <memmove>
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
80101639:	68 50 67 10 80       	push   $0x80106750
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
80101656:	e8 01 25 00 00       	call   80103b5c <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 b0 24 00 00       	call   80103b21 <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 5f 67 10 80       	push   $0x8010675f
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
80101698:	e8 35 24 00 00       	call   80103ad2 <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 6b 24 00 00       	call   80103b21 <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 00 0a 11 80 	movl   $0x80110a00,(%esp)
801016bd:	e8 24 26 00 00       	call   80103ce6 <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 00 0a 11 80 	movl   $0x80110a00,(%esp)
801016d2:	e8 74 26 00 00       	call   80103d4b <release>
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
801016e5:	68 00 0a 11 80       	push   $0x80110a00
801016ea:	e8 f7 25 00 00       	call   80103ce6 <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 00 0a 11 80 	movl   $0x80110a00,(%esp)
801016f9:	e8 4d 26 00 00       	call   80103d4b <release>
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
801017c4:	8b 04 c5 80 09 11 80 	mov    -0x7feef680(,%eax,8),%eax
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
8010182a:	e8 de 25 00 00       	call   80103e0d <memmove>
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
801018c1:	8b 04 c5 84 09 11 80 	mov    -0x7feef67c(,%eax,8),%eax
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
80101926:	e8 e2 24 00 00       	call   80103e0d <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 ea 10 00 00       	call   80102a1d <log_write>
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
801019a9:	e8 c6 24 00 00       	call   80103e74 <strncmp>
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
801019d0:	68 67 67 10 80       	push   $0x80106767
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 79 67 10 80       	push   $0x80106779
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
80101a5a:	e8 e5 18 00 00       	call   80103344 <myproc>
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
80101b92:	68 88 67 10 80       	push   $0x80106788
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 03 23 00 00       	call   80103eb1 <strncpy>
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
80101bd7:	68 94 6d 10 80       	push   $0x80106d94
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
80101ccc:	68 eb 67 10 80       	push   $0x801067eb
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 f4 67 10 80       	push   $0x801067f4
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
80101d06:	68 06 68 10 80       	push   $0x80106806
80101d0b:	68 80 a5 10 80       	push   $0x8010a580
80101d10:	e8 95 1e 00 00       	call   80103baa <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101d15:	83 c4 08             	add    $0x8,%esp
80101d18:	a1 80 2d 13 80       	mov    0x80132d80,%eax
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
80101d5c:	c7 05 60 a5 10 80 01 	movl   $0x1,0x8010a560
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
80101d7b:	68 80 a5 10 80       	push   $0x8010a580
80101d80:	e8 61 1f 00 00       	call   80103ce6 <acquire>

  if((b = idequeue) == 0){
80101d85:	8b 1d 64 a5 10 80    	mov    0x8010a564,%ebx
80101d8b:	83 c4 10             	add    $0x10,%esp
80101d8e:	85 db                	test   %ebx,%ebx
80101d90:	74 48                	je     80101dda <ideintr+0x67>
    release(&idelock);
    return;
  }
  idequeue = b->qnext;
80101d92:	8b 43 58             	mov    0x58(%ebx),%eax
80101d95:	a3 64 a5 10 80       	mov    %eax,0x8010a564

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
80101dad:	e8 9e 1b 00 00       	call   80103950 <wakeup>

  // Start disk on next buf in queue.
  if(idequeue != 0)
80101db2:	a1 64 a5 10 80       	mov    0x8010a564,%eax
80101db7:	83 c4 10             	add    $0x10,%esp
80101dba:	85 c0                	test   %eax,%eax
80101dbc:	74 05                	je     80101dc3 <ideintr+0x50>
    idestart(idequeue);
80101dbe:	e8 80 fe ff ff       	call   80101c43 <idestart>

  release(&idelock);
80101dc3:	83 ec 0c             	sub    $0xc,%esp
80101dc6:	68 80 a5 10 80       	push   $0x8010a580
80101dcb:	e8 7b 1f 00 00       	call   80103d4b <release>
80101dd0:	83 c4 10             	add    $0x10,%esp
}
80101dd3:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101dd6:	5b                   	pop    %ebx
80101dd7:	5f                   	pop    %edi
80101dd8:	5d                   	pop    %ebp
80101dd9:	c3                   	ret    
    release(&idelock);
80101dda:	83 ec 0c             	sub    $0xc,%esp
80101ddd:	68 80 a5 10 80       	push   $0x8010a580
80101de2:	e8 64 1f 00 00       	call   80103d4b <release>
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
80101e1a:	e8 3d 1d 00 00       	call   80103b5c <holdingsleep>
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
80101e36:	83 3d 60 a5 10 80 00 	cmpl   $0x0,0x8010a560
80101e3d:	74 38                	je     80101e77 <iderw+0x6b>
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);  //DOC:acquire-lock
80101e3f:	83 ec 0c             	sub    $0xc,%esp
80101e42:	68 80 a5 10 80       	push   $0x8010a580
80101e47:	e8 9a 1e 00 00       	call   80103ce6 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 a5 10 80       	mov    $0x8010a564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 0a 68 10 80       	push   $0x8010680a
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 20 68 10 80       	push   $0x80106820
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 35 68 10 80       	push   $0x80106835
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
80101e8f:	39 1d 64 a5 10 80    	cmp    %ebx,0x8010a564
80101e95:	75 1a                	jne    80101eb1 <iderw+0xa5>
    idestart(b);
80101e97:	89 d8                	mov    %ebx,%eax
80101e99:	e8 a5 fd ff ff       	call   80101c43 <idestart>
80101e9e:	eb 11                	jmp    80101eb1 <iderw+0xa5>

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
80101ea0:	83 ec 08             	sub    $0x8,%esp
80101ea3:	68 80 a5 10 80       	push   $0x8010a580
80101ea8:	53                   	push   %ebx
80101ea9:	e8 3d 19 00 00       	call   801037eb <sleep>
80101eae:	83 c4 10             	add    $0x10,%esp
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80101eb1:	8b 03                	mov    (%ebx),%eax
80101eb3:	83 e0 06             	and    $0x6,%eax
80101eb6:	83 f8 02             	cmp    $0x2,%eax
80101eb9:	75 e5                	jne    80101ea0 <iderw+0x94>
  }


  release(&idelock);
80101ebb:	83 ec 0c             	sub    $0xc,%esp
80101ebe:	68 80 a5 10 80       	push   $0x8010a580
80101ec3:	e8 83 1e 00 00       	call   80103d4b <release>
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
80101ed3:	8b 15 54 26 11 80    	mov    0x80112654,%edx
80101ed9:	89 02                	mov    %eax,(%edx)
  return ioapic->data;
80101edb:	a1 54 26 11 80       	mov    0x80112654,%eax
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
80101ee8:	8b 0d 54 26 11 80    	mov    0x80112654,%ecx
80101eee:	89 01                	mov    %eax,(%ecx)
  ioapic->data = data;
80101ef0:	a1 54 26 11 80       	mov    0x80112654,%eax
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
80101f03:	c7 05 54 26 11 80 00 	movl   $0xfec00000,0x80112654
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
80101f2a:	0f b6 15 e0 27 13 80 	movzbl 0x801327e0,%edx
80101f31:	39 c2                	cmp    %eax,%edx
80101f33:	75 07                	jne    80101f3c <ioapicinit+0x42>
{
80101f35:	bb 00 00 00 00       	mov    $0x0,%ebx
80101f3a:	eb 36                	jmp    80101f72 <ioapicinit+0x78>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80101f3c:	83 ec 0c             	sub    $0xc,%esp
80101f3f:	68 54 68 10 80       	push   $0x80106854
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
80101fb6:	81 fb 28 55 13 80    	cmp    $0x80135528,%ebx
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
80101fd6:	e8 b7 1d 00 00       	call   80103d92 <memset>

  if(kmem.use_lock)
80101fdb:	83 c4 10             	add    $0x10,%esp
80101fde:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
80101fe5:	75 28                	jne    8010200f <kfree+0x6b>
    acquire(&kmem.lock);
  r = (struct run*)v;
  r->next = kmem.freelist;
80101fe7:	a1 98 26 11 80       	mov    0x80112698,%eax
80101fec:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
80101fee:	89 1d 98 26 11 80    	mov    %ebx,0x80112698
  if(kmem.use_lock)
80101ff4:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
80101ffb:	75 24                	jne    80102021 <kfree+0x7d>
    release(&kmem.lock);
}
80101ffd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102000:	c9                   	leave  
80102001:	c3                   	ret    
    panic("kfree");
80102002:	83 ec 0c             	sub    $0xc,%esp
80102005:	68 86 68 10 80       	push   $0x80106886
8010200a:	e8 39 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010200f:	83 ec 0c             	sub    $0xc,%esp
80102012:	68 60 26 11 80       	push   $0x80112660
80102017:	e8 ca 1c 00 00       	call   80103ce6 <acquire>
8010201c:	83 c4 10             	add    $0x10,%esp
8010201f:	eb c6                	jmp    80101fe7 <kfree+0x43>
    release(&kmem.lock);
80102021:	83 ec 0c             	sub    $0xc,%esp
80102024:	68 60 26 11 80       	push   $0x80112660
80102029:	e8 1d 1d 00 00       	call   80103d4b <release>
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
8010206f:	68 8c 68 10 80       	push   $0x8010688c
80102074:	68 60 26 11 80       	push   $0x80112660
80102079:	e8 2c 1b 00 00       	call   80103baa <initlock>
  kmem.use_lock = 0;
8010207e:	c7 05 94 26 11 80 00 	movl   $0x0,0x80112694
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
801020ac:	c7 05 94 26 11 80 01 	movl   $0x1,0x80112694
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
801020c1:	a3 a0 26 11 80       	mov    %eax,0x801126a0
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
801020cf:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
801020d6:	75 21                	jne    801020f9 <kalloc+0x31>
    acquire(&kmem.lock);
  r = kmem.freelist;
801020d8:	8b 1d 98 26 11 80    	mov    0x80112698,%ebx
  if(r)
801020de:	85 db                	test   %ebx,%ebx
801020e0:	74 07                	je     801020e9 <kalloc+0x21>
    kmem.freelist = r->next;
801020e2:	8b 03                	mov    (%ebx),%eax
801020e4:	a3 98 26 11 80       	mov    %eax,0x80112698

  if(kmem.use_lock) {
801020e9:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
801020f0:	75 19                	jne    8010210b <kalloc+0x43>
    pids[index] = pidNum;
    index++;
    release(&kmem.lock);
  }
  return (char*)r;
}
801020f2:	89 d8                	mov    %ebx,%eax
801020f4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801020f7:	c9                   	leave  
801020f8:	c3                   	ret    
    acquire(&kmem.lock);
801020f9:	83 ec 0c             	sub    $0xc,%esp
801020fc:	68 60 26 11 80       	push   $0x80112660
80102101:	e8 e0 1b 00 00       	call   80103ce6 <acquire>
80102106:	83 c4 10             	add    $0x10,%esp
80102109:	eb cd                	jmp    801020d8 <kalloc+0x10>
    framenumber = (uint)(V2P(r) >> 12 & 0xffff);
8010210b:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80102111:	c1 e8 0c             	shr    $0xc,%eax
80102114:	0f b7 c0             	movzwl %ax,%eax
80102117:	a3 9c 26 11 80       	mov    %eax,0x8011269c
    updatePid(1);
8010211c:	83 ec 0c             	sub    $0xc,%esp
8010211f:	6a 01                	push   $0x1
80102121:	e8 95 ff ff ff       	call   801020bb <updatePid>
    frames[index] = framenumber;
80102126:	a1 b4 a5 10 80       	mov    0x8010a5b4,%eax
8010212b:	8b 15 9c 26 11 80    	mov    0x8011269c,%edx
80102131:	89 14 85 c0 26 11 80 	mov    %edx,-0x7feed940(,%eax,4)
    pids[index] = pidNum;
80102138:	8b 15 a0 26 11 80    	mov    0x801126a0,%edx
8010213e:	89 14 85 e0 26 12 80 	mov    %edx,-0x7fedd920(,%eax,4)
    index++;
80102145:	83 c0 01             	add    $0x1,%eax
80102148:	a3 b4 a5 10 80       	mov    %eax,0x8010a5b4
    release(&kmem.lock);
8010214d:	c7 04 24 60 26 11 80 	movl   $0x80112660,(%esp)
80102154:	e8 f2 1b 00 00       	call   80103d4b <release>
80102159:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
8010215c:	eb 94                	jmp    801020f2 <kalloc+0x2a>

8010215e <kalloc2>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc2(uint pid)
{
8010215e:	55                   	push   %ebp
8010215f:	89 e5                	mov    %esp,%ebp
80102161:	53                   	push   %ebx
80102162:	83 ec 04             	sub    $0x4,%esp
  struct run *r;

  if(kmem.use_lock)
80102165:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
8010216c:	75 2f                	jne    8010219d <kalloc2+0x3f>
    acquire(&kmem.lock);
  r = kmem.freelist;
8010216e:	8b 1d 98 26 11 80    	mov    0x80112698,%ebx
  if(r)
80102174:	85 db                	test   %ebx,%ebx
80102176:	74 07                	je     8010217f <kalloc2+0x21>
    kmem.freelist = r->next;
80102178:	8b 03                	mov    (%ebx),%eax
8010217a:	a3 98 26 11 80       	mov    %eax,0x80112698
  
  // Update global pid
  updatePid(pid);
8010217f:	83 ec 0c             	sub    $0xc,%esp
80102182:	ff 75 08             	pushl  0x8(%ebp)
80102185:	e8 31 ff ff ff       	call   801020bb <updatePid>

  if(kmem.use_lock) {
8010218a:	83 c4 10             	add    $0x10,%esp
8010218d:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
80102194:	75 19                	jne    801021af <kalloc2+0x51>
    index++;
    release(&kmem.lock);
  }
    
  return (char*)r;
}
80102196:	89 d8                	mov    %ebx,%eax
80102198:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010219b:	c9                   	leave  
8010219c:	c3                   	ret    
    acquire(&kmem.lock);
8010219d:	83 ec 0c             	sub    $0xc,%esp
801021a0:	68 60 26 11 80       	push   $0x80112660
801021a5:	e8 3c 1b 00 00       	call   80103ce6 <acquire>
801021aa:	83 c4 10             	add    $0x10,%esp
801021ad:	eb bf                	jmp    8010216e <kalloc2+0x10>
    framenumber = (uint)(V2P(r) >> 12 & 0xffff);
801021af:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801021b5:	c1 e8 0c             	shr    $0xc,%eax
801021b8:	0f b7 c0             	movzwl %ax,%eax
801021bb:	a3 9c 26 11 80       	mov    %eax,0x8011269c
    frames[index] = framenumber;
801021c0:	8b 15 b4 a5 10 80    	mov    0x8010a5b4,%edx
801021c6:	89 04 95 c0 26 11 80 	mov    %eax,-0x7feed940(,%edx,4)
    pids[index] = pidNum;
801021cd:	a1 a0 26 11 80       	mov    0x801126a0,%eax
801021d2:	89 04 95 e0 26 12 80 	mov    %eax,-0x7fedd920(,%edx,4)
    index++;
801021d9:	83 c2 01             	add    $0x1,%edx
801021dc:	89 15 b4 a5 10 80    	mov    %edx,0x8010a5b4
    release(&kmem.lock);
801021e2:	83 ec 0c             	sub    $0xc,%esp
801021e5:	68 60 26 11 80       	push   $0x80112660
801021ea:	e8 5c 1b 00 00       	call   80103d4b <release>
801021ef:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
801021f2:	eb a2                	jmp    80102196 <kalloc2+0x38>

801021f4 <dump_physmem>:

int
dump_physmem(int *frs, int *pds, int numframes)
{
801021f4:	55                   	push   %ebp
801021f5:	89 e5                	mov    %esp,%ebp
801021f7:	57                   	push   %edi
801021f8:	56                   	push   %esi
801021f9:	53                   	push   %ebx
801021fa:	8b 75 08             	mov    0x8(%ebp),%esi
801021fd:	8b 7d 0c             	mov    0xc(%ebp),%edi
80102200:	8b 5d 10             	mov    0x10(%ebp),%ebx
  if(numframes <= 0 || frs == 0 || pds == 0)
80102203:	85 db                	test   %ebx,%ebx
80102205:	0f 9e c2             	setle  %dl
80102208:	85 f6                	test   %esi,%esi
8010220a:	0f 94 c0             	sete   %al
8010220d:	08 c2                	or     %al,%dl
8010220f:	75 37                	jne    80102248 <dump_physmem+0x54>
80102211:	85 ff                	test   %edi,%edi
80102213:	74 3a                	je     8010224f <dump_physmem+0x5b>
    return -1;
  for (int i = 0; i < numframes; i++) {
80102215:	b8 00 00 00 00       	mov    $0x0,%eax
8010221a:	eb 1e                	jmp    8010223a <dump_physmem+0x46>
    frs[i] = frames[i];
8010221c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80102223:	8b 0c 85 c0 26 11 80 	mov    -0x7feed940(,%eax,4),%ecx
8010222a:	89 0c 16             	mov    %ecx,(%esi,%edx,1)
    pds[i] = pids[i];
8010222d:	8b 0c 85 e0 26 12 80 	mov    -0x7fedd920(,%eax,4),%ecx
80102234:	89 0c 17             	mov    %ecx,(%edi,%edx,1)
  for (int i = 0; i < numframes; i++) {
80102237:	83 c0 01             	add    $0x1,%eax
8010223a:	39 d8                	cmp    %ebx,%eax
8010223c:	7c de                	jl     8010221c <dump_physmem+0x28>
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
8010224d:	eb f4                	jmp    80102243 <dump_physmem+0x4f>
8010224f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102254:	eb ed                	jmp    80102243 <dump_physmem+0x4f>

80102256 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102256:	55                   	push   %ebp
80102257:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102259:	ba 64 00 00 00       	mov    $0x64,%edx
8010225e:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
8010225f:	a8 01                	test   $0x1,%al
80102261:	0f 84 b5 00 00 00    	je     8010231c <kbdgetc+0xc6>
80102267:	ba 60 00 00 00       	mov    $0x60,%edx
8010226c:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
8010226d:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
80102270:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
80102276:	74 5c                	je     801022d4 <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
80102278:	84 c0                	test   %al,%al
8010227a:	78 66                	js     801022e2 <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
8010227c:	8b 0d b8 a5 10 80    	mov    0x8010a5b8,%ecx
80102282:	f6 c1 40             	test   $0x40,%cl
80102285:	74 0f                	je     80102296 <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102287:	83 c8 80             	or     $0xffffff80,%eax
8010228a:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
8010228d:	83 e1 bf             	and    $0xffffffbf,%ecx
80102290:	89 0d b8 a5 10 80    	mov    %ecx,0x8010a5b8
  }

  shift |= shiftcode[data];
80102296:	0f b6 8a c0 69 10 80 	movzbl -0x7fef9640(%edx),%ecx
8010229d:	0b 0d b8 a5 10 80    	or     0x8010a5b8,%ecx
  shift ^= togglecode[data];
801022a3:	0f b6 82 c0 68 10 80 	movzbl -0x7fef9740(%edx),%eax
801022aa:	31 c1                	xor    %eax,%ecx
801022ac:	89 0d b8 a5 10 80    	mov    %ecx,0x8010a5b8
  c = charcode[shift & (CTL | SHIFT)][data];
801022b2:	89 c8                	mov    %ecx,%eax
801022b4:	83 e0 03             	and    $0x3,%eax
801022b7:	8b 04 85 a0 68 10 80 	mov    -0x7fef9760(,%eax,4),%eax
801022be:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
801022c2:	f6 c1 08             	test   $0x8,%cl
801022c5:	74 19                	je     801022e0 <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
801022c7:	8d 50 9f             	lea    -0x61(%eax),%edx
801022ca:	83 fa 19             	cmp    $0x19,%edx
801022cd:	77 40                	ja     8010230f <kbdgetc+0xb9>
      c += 'A' - 'a';
801022cf:	83 e8 20             	sub    $0x20,%eax
801022d2:	eb 0c                	jmp    801022e0 <kbdgetc+0x8a>
    shift |= E0ESC;
801022d4:	83 0d b8 a5 10 80 40 	orl    $0x40,0x8010a5b8
    return 0;
801022db:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
801022e0:	5d                   	pop    %ebp
801022e1:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
801022e2:	8b 0d b8 a5 10 80    	mov    0x8010a5b8,%ecx
801022e8:	f6 c1 40             	test   $0x40,%cl
801022eb:	75 05                	jne    801022f2 <kbdgetc+0x9c>
801022ed:	89 c2                	mov    %eax,%edx
801022ef:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
801022f2:	0f b6 82 c0 69 10 80 	movzbl -0x7fef9640(%edx),%eax
801022f9:	83 c8 40             	or     $0x40,%eax
801022fc:	0f b6 c0             	movzbl %al,%eax
801022ff:	f7 d0                	not    %eax
80102301:	21 c8                	and    %ecx,%eax
80102303:	a3 b8 a5 10 80       	mov    %eax,0x8010a5b8
    return 0;
80102308:	b8 00 00 00 00       	mov    $0x0,%eax
8010230d:	eb d1                	jmp    801022e0 <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
8010230f:	8d 50 bf             	lea    -0x41(%eax),%edx
80102312:	83 fa 19             	cmp    $0x19,%edx
80102315:	77 c9                	ja     801022e0 <kbdgetc+0x8a>
      c += 'a' - 'A';
80102317:	83 c0 20             	add    $0x20,%eax
  return c;
8010231a:	eb c4                	jmp    801022e0 <kbdgetc+0x8a>
    return -1;
8010231c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102321:	eb bd                	jmp    801022e0 <kbdgetc+0x8a>

80102323 <kbdintr>:

void
kbdintr(void)
{
80102323:	55                   	push   %ebp
80102324:	89 e5                	mov    %esp,%ebp
80102326:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
80102329:	68 56 22 10 80       	push   $0x80102256
8010232e:	e8 0b e4 ff ff       	call   8010073e <consoleintr>
}
80102333:	83 c4 10             	add    $0x10,%esp
80102336:	c9                   	leave  
80102337:	c3                   	ret    

80102338 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102338:	55                   	push   %ebp
80102339:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
8010233b:	8b 0d e4 26 13 80    	mov    0x801326e4,%ecx
80102341:	8d 04 81             	lea    (%ecx,%eax,4),%eax
80102344:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
80102346:	a1 e4 26 13 80       	mov    0x801326e4,%eax
8010234b:	8b 40 20             	mov    0x20(%eax),%eax
}
8010234e:	5d                   	pop    %ebp
8010234f:	c3                   	ret    

80102350 <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
80102350:	55                   	push   %ebp
80102351:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102353:	ba 70 00 00 00       	mov    $0x70,%edx
80102358:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102359:	ba 71 00 00 00       	mov    $0x71,%edx
8010235e:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
8010235f:	0f b6 c0             	movzbl %al,%eax
}
80102362:	5d                   	pop    %ebp
80102363:	c3                   	ret    

80102364 <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
80102364:	55                   	push   %ebp
80102365:	89 e5                	mov    %esp,%ebp
80102367:	53                   	push   %ebx
80102368:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
8010236a:	b8 00 00 00 00       	mov    $0x0,%eax
8010236f:	e8 dc ff ff ff       	call   80102350 <cmos_read>
80102374:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
80102376:	b8 02 00 00 00       	mov    $0x2,%eax
8010237b:	e8 d0 ff ff ff       	call   80102350 <cmos_read>
80102380:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
80102383:	b8 04 00 00 00       	mov    $0x4,%eax
80102388:	e8 c3 ff ff ff       	call   80102350 <cmos_read>
8010238d:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
80102390:	b8 07 00 00 00       	mov    $0x7,%eax
80102395:	e8 b6 ff ff ff       	call   80102350 <cmos_read>
8010239a:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
8010239d:	b8 08 00 00 00       	mov    $0x8,%eax
801023a2:	e8 a9 ff ff ff       	call   80102350 <cmos_read>
801023a7:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
801023aa:	b8 09 00 00 00       	mov    $0x9,%eax
801023af:	e8 9c ff ff ff       	call   80102350 <cmos_read>
801023b4:	89 43 14             	mov    %eax,0x14(%ebx)
}
801023b7:	5b                   	pop    %ebx
801023b8:	5d                   	pop    %ebp
801023b9:	c3                   	ret    

801023ba <lapicinit>:
  if(!lapic)
801023ba:	83 3d e4 26 13 80 00 	cmpl   $0x0,0x801326e4
801023c1:	0f 84 fb 00 00 00    	je     801024c2 <lapicinit+0x108>
{
801023c7:	55                   	push   %ebp
801023c8:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801023ca:	ba 3f 01 00 00       	mov    $0x13f,%edx
801023cf:	b8 3c 00 00 00       	mov    $0x3c,%eax
801023d4:	e8 5f ff ff ff       	call   80102338 <lapicw>
  lapicw(TDCR, X1);
801023d9:	ba 0b 00 00 00       	mov    $0xb,%edx
801023de:	b8 f8 00 00 00       	mov    $0xf8,%eax
801023e3:	e8 50 ff ff ff       	call   80102338 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801023e8:	ba 20 00 02 00       	mov    $0x20020,%edx
801023ed:	b8 c8 00 00 00       	mov    $0xc8,%eax
801023f2:	e8 41 ff ff ff       	call   80102338 <lapicw>
  lapicw(TICR, 10000000);
801023f7:	ba 80 96 98 00       	mov    $0x989680,%edx
801023fc:	b8 e0 00 00 00       	mov    $0xe0,%eax
80102401:	e8 32 ff ff ff       	call   80102338 <lapicw>
  lapicw(LINT0, MASKED);
80102406:	ba 00 00 01 00       	mov    $0x10000,%edx
8010240b:	b8 d4 00 00 00       	mov    $0xd4,%eax
80102410:	e8 23 ff ff ff       	call   80102338 <lapicw>
  lapicw(LINT1, MASKED);
80102415:	ba 00 00 01 00       	mov    $0x10000,%edx
8010241a:	b8 d8 00 00 00       	mov    $0xd8,%eax
8010241f:	e8 14 ff ff ff       	call   80102338 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102424:	a1 e4 26 13 80       	mov    0x801326e4,%eax
80102429:	8b 40 30             	mov    0x30(%eax),%eax
8010242c:	c1 e8 10             	shr    $0x10,%eax
8010242f:	3c 03                	cmp    $0x3,%al
80102431:	77 7b                	ja     801024ae <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102433:	ba 33 00 00 00       	mov    $0x33,%edx
80102438:	b8 dc 00 00 00       	mov    $0xdc,%eax
8010243d:	e8 f6 fe ff ff       	call   80102338 <lapicw>
  lapicw(ESR, 0);
80102442:	ba 00 00 00 00       	mov    $0x0,%edx
80102447:	b8 a0 00 00 00       	mov    $0xa0,%eax
8010244c:	e8 e7 fe ff ff       	call   80102338 <lapicw>
  lapicw(ESR, 0);
80102451:	ba 00 00 00 00       	mov    $0x0,%edx
80102456:	b8 a0 00 00 00       	mov    $0xa0,%eax
8010245b:	e8 d8 fe ff ff       	call   80102338 <lapicw>
  lapicw(EOI, 0);
80102460:	ba 00 00 00 00       	mov    $0x0,%edx
80102465:	b8 2c 00 00 00       	mov    $0x2c,%eax
8010246a:	e8 c9 fe ff ff       	call   80102338 <lapicw>
  lapicw(ICRHI, 0);
8010246f:	ba 00 00 00 00       	mov    $0x0,%edx
80102474:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102479:	e8 ba fe ff ff       	call   80102338 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
8010247e:	ba 00 85 08 00       	mov    $0x88500,%edx
80102483:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102488:	e8 ab fe ff ff       	call   80102338 <lapicw>
  while(lapic[ICRLO] & DELIVS)
8010248d:	a1 e4 26 13 80       	mov    0x801326e4,%eax
80102492:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
80102498:	f6 c4 10             	test   $0x10,%ah
8010249b:	75 f0                	jne    8010248d <lapicinit+0xd3>
  lapicw(TPR, 0);
8010249d:	ba 00 00 00 00       	mov    $0x0,%edx
801024a2:	b8 20 00 00 00       	mov    $0x20,%eax
801024a7:	e8 8c fe ff ff       	call   80102338 <lapicw>
}
801024ac:	5d                   	pop    %ebp
801024ad:	c3                   	ret    
    lapicw(PCINT, MASKED);
801024ae:	ba 00 00 01 00       	mov    $0x10000,%edx
801024b3:	b8 d0 00 00 00       	mov    $0xd0,%eax
801024b8:	e8 7b fe ff ff       	call   80102338 <lapicw>
801024bd:	e9 71 ff ff ff       	jmp    80102433 <lapicinit+0x79>
801024c2:	f3 c3                	repz ret 

801024c4 <lapicid>:
{
801024c4:	55                   	push   %ebp
801024c5:	89 e5                	mov    %esp,%ebp
  if (!lapic)
801024c7:	a1 e4 26 13 80       	mov    0x801326e4,%eax
801024cc:	85 c0                	test   %eax,%eax
801024ce:	74 08                	je     801024d8 <lapicid+0x14>
  return lapic[ID] >> 24;
801024d0:	8b 40 20             	mov    0x20(%eax),%eax
801024d3:	c1 e8 18             	shr    $0x18,%eax
}
801024d6:	5d                   	pop    %ebp
801024d7:	c3                   	ret    
    return 0;
801024d8:	b8 00 00 00 00       	mov    $0x0,%eax
801024dd:	eb f7                	jmp    801024d6 <lapicid+0x12>

801024df <lapiceoi>:
  if(lapic)
801024df:	83 3d e4 26 13 80 00 	cmpl   $0x0,0x801326e4
801024e6:	74 14                	je     801024fc <lapiceoi+0x1d>
{
801024e8:	55                   	push   %ebp
801024e9:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
801024eb:	ba 00 00 00 00       	mov    $0x0,%edx
801024f0:	b8 2c 00 00 00       	mov    $0x2c,%eax
801024f5:	e8 3e fe ff ff       	call   80102338 <lapicw>
}
801024fa:	5d                   	pop    %ebp
801024fb:	c3                   	ret    
801024fc:	f3 c3                	repz ret 

801024fe <microdelay>:
{
801024fe:	55                   	push   %ebp
801024ff:	89 e5                	mov    %esp,%ebp
}
80102501:	5d                   	pop    %ebp
80102502:	c3                   	ret    

80102503 <lapicstartap>:
{
80102503:	55                   	push   %ebp
80102504:	89 e5                	mov    %esp,%ebp
80102506:	57                   	push   %edi
80102507:	56                   	push   %esi
80102508:	53                   	push   %ebx
80102509:	8b 75 08             	mov    0x8(%ebp),%esi
8010250c:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010250f:	b8 0f 00 00 00       	mov    $0xf,%eax
80102514:	ba 70 00 00 00       	mov    $0x70,%edx
80102519:	ee                   	out    %al,(%dx)
8010251a:	b8 0a 00 00 00       	mov    $0xa,%eax
8010251f:	ba 71 00 00 00       	mov    $0x71,%edx
80102524:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
80102525:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
8010252c:	00 00 
  wrv[1] = addr >> 4;
8010252e:	89 f8                	mov    %edi,%eax
80102530:	c1 e8 04             	shr    $0x4,%eax
80102533:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
80102539:	c1 e6 18             	shl    $0x18,%esi
8010253c:	89 f2                	mov    %esi,%edx
8010253e:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102543:	e8 f0 fd ff ff       	call   80102338 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102548:	ba 00 c5 00 00       	mov    $0xc500,%edx
8010254d:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102552:	e8 e1 fd ff ff       	call   80102338 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
80102557:	ba 00 85 00 00       	mov    $0x8500,%edx
8010255c:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102561:	e8 d2 fd ff ff       	call   80102338 <lapicw>
  for(i = 0; i < 2; i++){
80102566:	bb 00 00 00 00       	mov    $0x0,%ebx
8010256b:	eb 21                	jmp    8010258e <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
8010256d:	89 f2                	mov    %esi,%edx
8010256f:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102574:	e8 bf fd ff ff       	call   80102338 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80102579:	89 fa                	mov    %edi,%edx
8010257b:	c1 ea 0c             	shr    $0xc,%edx
8010257e:	80 ce 06             	or     $0x6,%dh
80102581:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102586:	e8 ad fd ff ff       	call   80102338 <lapicw>
  for(i = 0; i < 2; i++){
8010258b:	83 c3 01             	add    $0x1,%ebx
8010258e:	83 fb 01             	cmp    $0x1,%ebx
80102591:	7e da                	jle    8010256d <lapicstartap+0x6a>
}
80102593:	5b                   	pop    %ebx
80102594:	5e                   	pop    %esi
80102595:	5f                   	pop    %edi
80102596:	5d                   	pop    %ebp
80102597:	c3                   	ret    

80102598 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
80102598:	55                   	push   %ebp
80102599:	89 e5                	mov    %esp,%ebp
8010259b:	57                   	push   %edi
8010259c:	56                   	push   %esi
8010259d:	53                   	push   %ebx
8010259e:	83 ec 3c             	sub    $0x3c,%esp
801025a1:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801025a4:	b8 0b 00 00 00       	mov    $0xb,%eax
801025a9:	e8 a2 fd ff ff       	call   80102350 <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
801025ae:	83 e0 04             	and    $0x4,%eax
801025b1:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
801025b3:	8d 45 d0             	lea    -0x30(%ebp),%eax
801025b6:	e8 a9 fd ff ff       	call   80102364 <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
801025bb:	b8 0a 00 00 00       	mov    $0xa,%eax
801025c0:	e8 8b fd ff ff       	call   80102350 <cmos_read>
801025c5:	a8 80                	test   $0x80,%al
801025c7:	75 ea                	jne    801025b3 <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
801025c9:	8d 5d b8             	lea    -0x48(%ebp),%ebx
801025cc:	89 d8                	mov    %ebx,%eax
801025ce:	e8 91 fd ff ff       	call   80102364 <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
801025d3:	83 ec 04             	sub    $0x4,%esp
801025d6:	6a 18                	push   $0x18
801025d8:	53                   	push   %ebx
801025d9:	8d 45 d0             	lea    -0x30(%ebp),%eax
801025dc:	50                   	push   %eax
801025dd:	e8 f6 17 00 00       	call   80103dd8 <memcmp>
801025e2:	83 c4 10             	add    $0x10,%esp
801025e5:	85 c0                	test   %eax,%eax
801025e7:	75 ca                	jne    801025b3 <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
801025e9:	85 ff                	test   %edi,%edi
801025eb:	0f 85 84 00 00 00    	jne    80102675 <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801025f1:	8b 55 d0             	mov    -0x30(%ebp),%edx
801025f4:	89 d0                	mov    %edx,%eax
801025f6:	c1 e8 04             	shr    $0x4,%eax
801025f9:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801025fc:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801025ff:	83 e2 0f             	and    $0xf,%edx
80102602:	01 d0                	add    %edx,%eax
80102604:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
80102607:	8b 55 d4             	mov    -0x2c(%ebp),%edx
8010260a:	89 d0                	mov    %edx,%eax
8010260c:	c1 e8 04             	shr    $0x4,%eax
8010260f:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102612:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102615:	83 e2 0f             	and    $0xf,%edx
80102618:	01 d0                	add    %edx,%eax
8010261a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
8010261d:	8b 55 d8             	mov    -0x28(%ebp),%edx
80102620:	89 d0                	mov    %edx,%eax
80102622:	c1 e8 04             	shr    $0x4,%eax
80102625:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102628:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010262b:	83 e2 0f             	and    $0xf,%edx
8010262e:	01 d0                	add    %edx,%eax
80102630:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
80102633:	8b 55 dc             	mov    -0x24(%ebp),%edx
80102636:	89 d0                	mov    %edx,%eax
80102638:	c1 e8 04             	shr    $0x4,%eax
8010263b:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010263e:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102641:	83 e2 0f             	and    $0xf,%edx
80102644:	01 d0                	add    %edx,%eax
80102646:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
80102649:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010264c:	89 d0                	mov    %edx,%eax
8010264e:	c1 e8 04             	shr    $0x4,%eax
80102651:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102654:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102657:	83 e2 0f             	and    $0xf,%edx
8010265a:	01 d0                	add    %edx,%eax
8010265c:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
8010265f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80102662:	89 d0                	mov    %edx,%eax
80102664:	c1 e8 04             	shr    $0x4,%eax
80102667:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010266a:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010266d:	83 e2 0f             	and    $0xf,%edx
80102670:	01 d0                	add    %edx,%eax
80102672:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
80102675:	8b 45 d0             	mov    -0x30(%ebp),%eax
80102678:	89 06                	mov    %eax,(%esi)
8010267a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
8010267d:	89 46 04             	mov    %eax,0x4(%esi)
80102680:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102683:	89 46 08             	mov    %eax,0x8(%esi)
80102686:	8b 45 dc             	mov    -0x24(%ebp),%eax
80102689:	89 46 0c             	mov    %eax,0xc(%esi)
8010268c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010268f:	89 46 10             	mov    %eax,0x10(%esi)
80102692:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102695:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
80102698:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
8010269f:	8d 65 f4             	lea    -0xc(%ebp),%esp
801026a2:	5b                   	pop    %ebx
801026a3:	5e                   	pop    %esi
801026a4:	5f                   	pop    %edi
801026a5:	5d                   	pop    %ebp
801026a6:	c3                   	ret    

801026a7 <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
801026a7:	55                   	push   %ebp
801026a8:	89 e5                	mov    %esp,%ebp
801026aa:	53                   	push   %ebx
801026ab:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
801026ae:	ff 35 34 27 13 80    	pushl  0x80132734
801026b4:	ff 35 44 27 13 80    	pushl  0x80132744
801026ba:	e8 ad da ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
801026bf:	8b 58 5c             	mov    0x5c(%eax),%ebx
801026c2:	89 1d 48 27 13 80    	mov    %ebx,0x80132748
  for (i = 0; i < log.lh.n; i++) {
801026c8:	83 c4 10             	add    $0x10,%esp
801026cb:	ba 00 00 00 00       	mov    $0x0,%edx
801026d0:	eb 0e                	jmp    801026e0 <read_head+0x39>
    log.lh.block[i] = lh->block[i];
801026d2:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
801026d6:	89 0c 95 4c 27 13 80 	mov    %ecx,-0x7fecd8b4(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
801026dd:	83 c2 01             	add    $0x1,%edx
801026e0:	39 d3                	cmp    %edx,%ebx
801026e2:	7f ee                	jg     801026d2 <read_head+0x2b>
  }
  brelse(buf);
801026e4:	83 ec 0c             	sub    $0xc,%esp
801026e7:	50                   	push   %eax
801026e8:	e8 e8 da ff ff       	call   801001d5 <brelse>
}
801026ed:	83 c4 10             	add    $0x10,%esp
801026f0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801026f3:	c9                   	leave  
801026f4:	c3                   	ret    

801026f5 <install_trans>:
{
801026f5:	55                   	push   %ebp
801026f6:	89 e5                	mov    %esp,%ebp
801026f8:	57                   	push   %edi
801026f9:	56                   	push   %esi
801026fa:	53                   	push   %ebx
801026fb:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
801026fe:	bb 00 00 00 00       	mov    $0x0,%ebx
80102703:	eb 66                	jmp    8010276b <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80102705:	89 d8                	mov    %ebx,%eax
80102707:	03 05 34 27 13 80    	add    0x80132734,%eax
8010270d:	83 c0 01             	add    $0x1,%eax
80102710:	83 ec 08             	sub    $0x8,%esp
80102713:	50                   	push   %eax
80102714:	ff 35 44 27 13 80    	pushl  0x80132744
8010271a:	e8 4d da ff ff       	call   8010016c <bread>
8010271f:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
80102721:	83 c4 08             	add    $0x8,%esp
80102724:	ff 34 9d 4c 27 13 80 	pushl  -0x7fecd8b4(,%ebx,4)
8010272b:	ff 35 44 27 13 80    	pushl  0x80132744
80102731:	e8 36 da ff ff       	call   8010016c <bread>
80102736:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80102738:	8d 57 5c             	lea    0x5c(%edi),%edx
8010273b:	8d 40 5c             	lea    0x5c(%eax),%eax
8010273e:	83 c4 0c             	add    $0xc,%esp
80102741:	68 00 02 00 00       	push   $0x200
80102746:	52                   	push   %edx
80102747:	50                   	push   %eax
80102748:	e8 c0 16 00 00       	call   80103e0d <memmove>
    bwrite(dbuf);  // write dst to disk
8010274d:	89 34 24             	mov    %esi,(%esp)
80102750:	e8 45 da ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
80102755:	89 3c 24             	mov    %edi,(%esp)
80102758:	e8 78 da ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
8010275d:	89 34 24             	mov    %esi,(%esp)
80102760:	e8 70 da ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102765:	83 c3 01             	add    $0x1,%ebx
80102768:	83 c4 10             	add    $0x10,%esp
8010276b:	39 1d 48 27 13 80    	cmp    %ebx,0x80132748
80102771:	7f 92                	jg     80102705 <install_trans+0x10>
}
80102773:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102776:	5b                   	pop    %ebx
80102777:	5e                   	pop    %esi
80102778:	5f                   	pop    %edi
80102779:	5d                   	pop    %ebp
8010277a:	c3                   	ret    

8010277b <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
8010277b:	55                   	push   %ebp
8010277c:	89 e5                	mov    %esp,%ebp
8010277e:	53                   	push   %ebx
8010277f:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102782:	ff 35 34 27 13 80    	pushl  0x80132734
80102788:	ff 35 44 27 13 80    	pushl  0x80132744
8010278e:	e8 d9 d9 ff ff       	call   8010016c <bread>
80102793:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
80102795:	8b 0d 48 27 13 80    	mov    0x80132748,%ecx
8010279b:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
8010279e:	83 c4 10             	add    $0x10,%esp
801027a1:	b8 00 00 00 00       	mov    $0x0,%eax
801027a6:	eb 0e                	jmp    801027b6 <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
801027a8:	8b 14 85 4c 27 13 80 	mov    -0x7fecd8b4(,%eax,4),%edx
801027af:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
801027b3:	83 c0 01             	add    $0x1,%eax
801027b6:	39 c1                	cmp    %eax,%ecx
801027b8:	7f ee                	jg     801027a8 <write_head+0x2d>
  }
  bwrite(buf);
801027ba:	83 ec 0c             	sub    $0xc,%esp
801027bd:	53                   	push   %ebx
801027be:	e8 d7 d9 ff ff       	call   8010019a <bwrite>
  brelse(buf);
801027c3:	89 1c 24             	mov    %ebx,(%esp)
801027c6:	e8 0a da ff ff       	call   801001d5 <brelse>
}
801027cb:	83 c4 10             	add    $0x10,%esp
801027ce:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801027d1:	c9                   	leave  
801027d2:	c3                   	ret    

801027d3 <recover_from_log>:

static void
recover_from_log(void)
{
801027d3:	55                   	push   %ebp
801027d4:	89 e5                	mov    %esp,%ebp
801027d6:	83 ec 08             	sub    $0x8,%esp
  read_head();
801027d9:	e8 c9 fe ff ff       	call   801026a7 <read_head>
  install_trans(); // if committed, copy from log to disk
801027de:	e8 12 ff ff ff       	call   801026f5 <install_trans>
  log.lh.n = 0;
801027e3:	c7 05 48 27 13 80 00 	movl   $0x0,0x80132748
801027ea:	00 00 00 
  write_head(); // clear the log
801027ed:	e8 89 ff ff ff       	call   8010277b <write_head>
}
801027f2:	c9                   	leave  
801027f3:	c3                   	ret    

801027f4 <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
801027f4:	55                   	push   %ebp
801027f5:	89 e5                	mov    %esp,%ebp
801027f7:	57                   	push   %edi
801027f8:	56                   	push   %esi
801027f9:	53                   	push   %ebx
801027fa:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801027fd:	bb 00 00 00 00       	mov    $0x0,%ebx
80102802:	eb 66                	jmp    8010286a <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80102804:	89 d8                	mov    %ebx,%eax
80102806:	03 05 34 27 13 80    	add    0x80132734,%eax
8010280c:	83 c0 01             	add    $0x1,%eax
8010280f:	83 ec 08             	sub    $0x8,%esp
80102812:	50                   	push   %eax
80102813:	ff 35 44 27 13 80    	pushl  0x80132744
80102819:	e8 4e d9 ff ff       	call   8010016c <bread>
8010281e:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80102820:	83 c4 08             	add    $0x8,%esp
80102823:	ff 34 9d 4c 27 13 80 	pushl  -0x7fecd8b4(,%ebx,4)
8010282a:	ff 35 44 27 13 80    	pushl  0x80132744
80102830:	e8 37 d9 ff ff       	call   8010016c <bread>
80102835:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
80102837:	8d 50 5c             	lea    0x5c(%eax),%edx
8010283a:	8d 46 5c             	lea    0x5c(%esi),%eax
8010283d:	83 c4 0c             	add    $0xc,%esp
80102840:	68 00 02 00 00       	push   $0x200
80102845:	52                   	push   %edx
80102846:	50                   	push   %eax
80102847:	e8 c1 15 00 00       	call   80103e0d <memmove>
    bwrite(to);  // write the log
8010284c:	89 34 24             	mov    %esi,(%esp)
8010284f:	e8 46 d9 ff ff       	call   8010019a <bwrite>
    brelse(from);
80102854:	89 3c 24             	mov    %edi,(%esp)
80102857:	e8 79 d9 ff ff       	call   801001d5 <brelse>
    brelse(to);
8010285c:	89 34 24             	mov    %esi,(%esp)
8010285f:	e8 71 d9 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102864:	83 c3 01             	add    $0x1,%ebx
80102867:	83 c4 10             	add    $0x10,%esp
8010286a:	39 1d 48 27 13 80    	cmp    %ebx,0x80132748
80102870:	7f 92                	jg     80102804 <write_log+0x10>
  }
}
80102872:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102875:	5b                   	pop    %ebx
80102876:	5e                   	pop    %esi
80102877:	5f                   	pop    %edi
80102878:	5d                   	pop    %ebp
80102879:	c3                   	ret    

8010287a <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
8010287a:	83 3d 48 27 13 80 00 	cmpl   $0x0,0x80132748
80102881:	7e 26                	jle    801028a9 <commit+0x2f>
{
80102883:	55                   	push   %ebp
80102884:	89 e5                	mov    %esp,%ebp
80102886:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
80102889:	e8 66 ff ff ff       	call   801027f4 <write_log>
    write_head();    // Write header to disk -- the real commit
8010288e:	e8 e8 fe ff ff       	call   8010277b <write_head>
    install_trans(); // Now install writes to home locations
80102893:	e8 5d fe ff ff       	call   801026f5 <install_trans>
    log.lh.n = 0;
80102898:	c7 05 48 27 13 80 00 	movl   $0x0,0x80132748
8010289f:	00 00 00 
    write_head();    // Erase the transaction from the log
801028a2:	e8 d4 fe ff ff       	call   8010277b <write_head>
  }
}
801028a7:	c9                   	leave  
801028a8:	c3                   	ret    
801028a9:	f3 c3                	repz ret 

801028ab <initlog>:
{
801028ab:	55                   	push   %ebp
801028ac:	89 e5                	mov    %esp,%ebp
801028ae:	53                   	push   %ebx
801028af:	83 ec 2c             	sub    $0x2c,%esp
801028b2:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
801028b5:	68 c0 6a 10 80       	push   $0x80106ac0
801028ba:	68 00 27 13 80       	push   $0x80132700
801028bf:	e8 e6 12 00 00       	call   80103baa <initlock>
  readsb(dev, &sb);
801028c4:	83 c4 08             	add    $0x8,%esp
801028c7:	8d 45 dc             	lea    -0x24(%ebp),%eax
801028ca:	50                   	push   %eax
801028cb:	53                   	push   %ebx
801028cc:	e8 65 e9 ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
801028d1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801028d4:	a3 34 27 13 80       	mov    %eax,0x80132734
  log.size = sb.nlog;
801028d9:	8b 45 e8             	mov    -0x18(%ebp),%eax
801028dc:	a3 38 27 13 80       	mov    %eax,0x80132738
  log.dev = dev;
801028e1:	89 1d 44 27 13 80    	mov    %ebx,0x80132744
  recover_from_log();
801028e7:	e8 e7 fe ff ff       	call   801027d3 <recover_from_log>
}
801028ec:	83 c4 10             	add    $0x10,%esp
801028ef:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801028f2:	c9                   	leave  
801028f3:	c3                   	ret    

801028f4 <begin_op>:
{
801028f4:	55                   	push   %ebp
801028f5:	89 e5                	mov    %esp,%ebp
801028f7:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
801028fa:	68 00 27 13 80       	push   $0x80132700
801028ff:	e8 e2 13 00 00       	call   80103ce6 <acquire>
80102904:	83 c4 10             	add    $0x10,%esp
80102907:	eb 15                	jmp    8010291e <begin_op+0x2a>
      sleep(&log, &log.lock);
80102909:	83 ec 08             	sub    $0x8,%esp
8010290c:	68 00 27 13 80       	push   $0x80132700
80102911:	68 00 27 13 80       	push   $0x80132700
80102916:	e8 d0 0e 00 00       	call   801037eb <sleep>
8010291b:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
8010291e:	83 3d 40 27 13 80 00 	cmpl   $0x0,0x80132740
80102925:	75 e2                	jne    80102909 <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80102927:	a1 3c 27 13 80       	mov    0x8013273c,%eax
8010292c:	83 c0 01             	add    $0x1,%eax
8010292f:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102932:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
80102935:	03 15 48 27 13 80    	add    0x80132748,%edx
8010293b:	83 fa 1e             	cmp    $0x1e,%edx
8010293e:	7e 17                	jle    80102957 <begin_op+0x63>
      sleep(&log, &log.lock);
80102940:	83 ec 08             	sub    $0x8,%esp
80102943:	68 00 27 13 80       	push   $0x80132700
80102948:	68 00 27 13 80       	push   $0x80132700
8010294d:	e8 99 0e 00 00       	call   801037eb <sleep>
80102952:	83 c4 10             	add    $0x10,%esp
80102955:	eb c7                	jmp    8010291e <begin_op+0x2a>
      log.outstanding += 1;
80102957:	a3 3c 27 13 80       	mov    %eax,0x8013273c
      release(&log.lock);
8010295c:	83 ec 0c             	sub    $0xc,%esp
8010295f:	68 00 27 13 80       	push   $0x80132700
80102964:	e8 e2 13 00 00       	call   80103d4b <release>
}
80102969:	83 c4 10             	add    $0x10,%esp
8010296c:	c9                   	leave  
8010296d:	c3                   	ret    

8010296e <end_op>:
{
8010296e:	55                   	push   %ebp
8010296f:	89 e5                	mov    %esp,%ebp
80102971:	53                   	push   %ebx
80102972:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
80102975:	68 00 27 13 80       	push   $0x80132700
8010297a:	e8 67 13 00 00       	call   80103ce6 <acquire>
  log.outstanding -= 1;
8010297f:	a1 3c 27 13 80       	mov    0x8013273c,%eax
80102984:	83 e8 01             	sub    $0x1,%eax
80102987:	a3 3c 27 13 80       	mov    %eax,0x8013273c
  if(log.committing)
8010298c:	8b 1d 40 27 13 80    	mov    0x80132740,%ebx
80102992:	83 c4 10             	add    $0x10,%esp
80102995:	85 db                	test   %ebx,%ebx
80102997:	75 2c                	jne    801029c5 <end_op+0x57>
  if(log.outstanding == 0){
80102999:	85 c0                	test   %eax,%eax
8010299b:	75 35                	jne    801029d2 <end_op+0x64>
    log.committing = 1;
8010299d:	c7 05 40 27 13 80 01 	movl   $0x1,0x80132740
801029a4:	00 00 00 
    do_commit = 1;
801029a7:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
801029ac:	83 ec 0c             	sub    $0xc,%esp
801029af:	68 00 27 13 80       	push   $0x80132700
801029b4:	e8 92 13 00 00       	call   80103d4b <release>
  if(do_commit){
801029b9:	83 c4 10             	add    $0x10,%esp
801029bc:	85 db                	test   %ebx,%ebx
801029be:	75 24                	jne    801029e4 <end_op+0x76>
}
801029c0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801029c3:	c9                   	leave  
801029c4:	c3                   	ret    
    panic("log.committing");
801029c5:	83 ec 0c             	sub    $0xc,%esp
801029c8:	68 c4 6a 10 80       	push   $0x80106ac4
801029cd:	e8 76 d9 ff ff       	call   80100348 <panic>
    wakeup(&log);
801029d2:	83 ec 0c             	sub    $0xc,%esp
801029d5:	68 00 27 13 80       	push   $0x80132700
801029da:	e8 71 0f 00 00       	call   80103950 <wakeup>
801029df:	83 c4 10             	add    $0x10,%esp
801029e2:	eb c8                	jmp    801029ac <end_op+0x3e>
    commit();
801029e4:	e8 91 fe ff ff       	call   8010287a <commit>
    acquire(&log.lock);
801029e9:	83 ec 0c             	sub    $0xc,%esp
801029ec:	68 00 27 13 80       	push   $0x80132700
801029f1:	e8 f0 12 00 00       	call   80103ce6 <acquire>
    log.committing = 0;
801029f6:	c7 05 40 27 13 80 00 	movl   $0x0,0x80132740
801029fd:	00 00 00 
    wakeup(&log);
80102a00:	c7 04 24 00 27 13 80 	movl   $0x80132700,(%esp)
80102a07:	e8 44 0f 00 00       	call   80103950 <wakeup>
    release(&log.lock);
80102a0c:	c7 04 24 00 27 13 80 	movl   $0x80132700,(%esp)
80102a13:	e8 33 13 00 00       	call   80103d4b <release>
80102a18:	83 c4 10             	add    $0x10,%esp
}
80102a1b:	eb a3                	jmp    801029c0 <end_op+0x52>

80102a1d <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80102a1d:	55                   	push   %ebp
80102a1e:	89 e5                	mov    %esp,%ebp
80102a20:	53                   	push   %ebx
80102a21:	83 ec 04             	sub    $0x4,%esp
80102a24:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80102a27:	8b 15 48 27 13 80    	mov    0x80132748,%edx
80102a2d:	83 fa 1d             	cmp    $0x1d,%edx
80102a30:	7f 45                	jg     80102a77 <log_write+0x5a>
80102a32:	a1 38 27 13 80       	mov    0x80132738,%eax
80102a37:	83 e8 01             	sub    $0x1,%eax
80102a3a:	39 c2                	cmp    %eax,%edx
80102a3c:	7d 39                	jge    80102a77 <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102a3e:	83 3d 3c 27 13 80 00 	cmpl   $0x0,0x8013273c
80102a45:	7e 3d                	jle    80102a84 <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102a47:	83 ec 0c             	sub    $0xc,%esp
80102a4a:	68 00 27 13 80       	push   $0x80132700
80102a4f:	e8 92 12 00 00       	call   80103ce6 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80102a54:	83 c4 10             	add    $0x10,%esp
80102a57:	b8 00 00 00 00       	mov    $0x0,%eax
80102a5c:	8b 15 48 27 13 80    	mov    0x80132748,%edx
80102a62:	39 c2                	cmp    %eax,%edx
80102a64:	7e 2b                	jle    80102a91 <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102a66:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102a69:	39 0c 85 4c 27 13 80 	cmp    %ecx,-0x7fecd8b4(,%eax,4)
80102a70:	74 1f                	je     80102a91 <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
80102a72:	83 c0 01             	add    $0x1,%eax
80102a75:	eb e5                	jmp    80102a5c <log_write+0x3f>
    panic("too big a transaction");
80102a77:	83 ec 0c             	sub    $0xc,%esp
80102a7a:	68 d3 6a 10 80       	push   $0x80106ad3
80102a7f:	e8 c4 d8 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102a84:	83 ec 0c             	sub    $0xc,%esp
80102a87:	68 e9 6a 10 80       	push   $0x80106ae9
80102a8c:	e8 b7 d8 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102a91:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102a94:	89 0c 85 4c 27 13 80 	mov    %ecx,-0x7fecd8b4(,%eax,4)
  if (i == log.lh.n)
80102a9b:	39 c2                	cmp    %eax,%edx
80102a9d:	74 18                	je     80102ab7 <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102a9f:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102aa2:	83 ec 0c             	sub    $0xc,%esp
80102aa5:	68 00 27 13 80       	push   $0x80132700
80102aaa:	e8 9c 12 00 00       	call   80103d4b <release>
}
80102aaf:	83 c4 10             	add    $0x10,%esp
80102ab2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102ab5:	c9                   	leave  
80102ab6:	c3                   	ret    
    log.lh.n++;
80102ab7:	83 c2 01             	add    $0x1,%edx
80102aba:	89 15 48 27 13 80    	mov    %edx,0x80132748
80102ac0:	eb dd                	jmp    80102a9f <log_write+0x82>

80102ac2 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102ac2:	55                   	push   %ebp
80102ac3:	89 e5                	mov    %esp,%ebp
80102ac5:	53                   	push   %ebx
80102ac6:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102ac9:	68 8a 00 00 00       	push   $0x8a
80102ace:	68 8c a4 10 80       	push   $0x8010a48c
80102ad3:	68 00 70 00 80       	push   $0x80007000
80102ad8:	e8 30 13 00 00       	call   80103e0d <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102add:	83 c4 10             	add    $0x10,%esp
80102ae0:	bb 00 28 13 80       	mov    $0x80132800,%ebx
80102ae5:	eb 06                	jmp    80102aed <startothers+0x2b>
80102ae7:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102aed:	69 05 80 2d 13 80 b0 	imul   $0xb0,0x80132d80,%eax
80102af4:	00 00 00 
80102af7:	05 00 28 13 80       	add    $0x80132800,%eax
80102afc:	39 d8                	cmp    %ebx,%eax
80102afe:	76 4c                	jbe    80102b4c <startothers+0x8a>
    if(c == mycpu())  // We've started already.
80102b00:	e8 c8 07 00 00       	call   801032cd <mycpu>
80102b05:	39 d8                	cmp    %ebx,%eax
80102b07:	74 de                	je     80102ae7 <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80102b09:	e8 ba f5 ff ff       	call   801020c8 <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102b0e:	05 00 10 00 00       	add    $0x1000,%eax
80102b13:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102b18:	c7 05 f8 6f 00 80 90 	movl   $0x80102b90,0x80006ff8
80102b1f:	2b 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102b22:	c7 05 f4 6f 00 80 00 	movl   $0x109000,0x80006ff4
80102b29:	90 10 00 

    lapicstartap(c->apicid, V2P(code));
80102b2c:	83 ec 08             	sub    $0x8,%esp
80102b2f:	68 00 70 00 00       	push   $0x7000
80102b34:	0f b6 03             	movzbl (%ebx),%eax
80102b37:	50                   	push   %eax
80102b38:	e8 c6 f9 ff ff       	call   80102503 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102b3d:	83 c4 10             	add    $0x10,%esp
80102b40:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102b46:	85 c0                	test   %eax,%eax
80102b48:	74 f6                	je     80102b40 <startothers+0x7e>
80102b4a:	eb 9b                	jmp    80102ae7 <startothers+0x25>
      ;
  }
}
80102b4c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102b4f:	c9                   	leave  
80102b50:	c3                   	ret    

80102b51 <mpmain>:
{
80102b51:	55                   	push   %ebp
80102b52:	89 e5                	mov    %esp,%ebp
80102b54:	53                   	push   %ebx
80102b55:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102b58:	e8 cc 07 00 00       	call   80103329 <cpuid>
80102b5d:	89 c3                	mov    %eax,%ebx
80102b5f:	e8 c5 07 00 00       	call   80103329 <cpuid>
80102b64:	83 ec 04             	sub    $0x4,%esp
80102b67:	53                   	push   %ebx
80102b68:	50                   	push   %eax
80102b69:	68 04 6b 10 80       	push   $0x80106b04
80102b6e:	e8 98 da ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102b73:	e8 ec 23 00 00       	call   80104f64 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102b78:	e8 50 07 00 00       	call   801032cd <mycpu>
80102b7d:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102b7f:	b8 01 00 00 00       	mov    $0x1,%eax
80102b84:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102b8b:	e8 36 0a 00 00       	call   801035c6 <scheduler>

80102b90 <mpenter>:
{
80102b90:	55                   	push   %ebp
80102b91:	89 e5                	mov    %esp,%ebp
80102b93:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102b96:	e8 da 33 00 00       	call   80105f75 <switchkvm>
  seginit();
80102b9b:	e8 89 32 00 00       	call   80105e29 <seginit>
  lapicinit();
80102ba0:	e8 15 f8 ff ff       	call   801023ba <lapicinit>
  mpmain();
80102ba5:	e8 a7 ff ff ff       	call   80102b51 <mpmain>

80102baa <main>:
{
80102baa:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102bae:	83 e4 f0             	and    $0xfffffff0,%esp
80102bb1:	ff 71 fc             	pushl  -0x4(%ecx)
80102bb4:	55                   	push   %ebp
80102bb5:	89 e5                	mov    %esp,%ebp
80102bb7:	51                   	push   %ecx
80102bb8:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102bbb:	68 00 00 40 80       	push   $0x80400000
80102bc0:	68 28 55 13 80       	push   $0x80135528
80102bc5:	e8 9f f4 ff ff       	call   80102069 <kinit1>
  kvmalloc();      // kernel page table
80102bca:	e8 4e 38 00 00       	call   8010641d <kvmalloc>
  mpinit();        // detect other processors
80102bcf:	e8 c9 01 00 00       	call   80102d9d <mpinit>
  lapicinit();     // interrupt controller
80102bd4:	e8 e1 f7 ff ff       	call   801023ba <lapicinit>
  seginit();       // segment descriptors
80102bd9:	e8 4b 32 00 00       	call   80105e29 <seginit>
  picinit();       // disable pic
80102bde:	e8 82 02 00 00       	call   80102e65 <picinit>
  ioapicinit();    // another interrupt controller
80102be3:	e8 12 f3 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102be8:	e8 a1 dc ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102bed:	e8 20 26 00 00       	call   80105212 <uartinit>
  pinit();         // process table
80102bf2:	e8 bc 06 00 00       	call   801032b3 <pinit>
  tvinit();        // trap vectors
80102bf7:	e8 b7 22 00 00       	call   80104eb3 <tvinit>
  binit();         // buffer cache
80102bfc:	e8 f3 d4 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102c01:	e8 0d e0 ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102c06:	e8 f5 f0 ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102c0b:	e8 b2 fe ff ff       	call   80102ac2 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102c10:	83 c4 08             	add    $0x8,%esp
80102c13:	68 00 00 00 8e       	push   $0x8e000000
80102c18:	68 00 00 40 80       	push   $0x80400000
80102c1d:	e8 79 f4 ff ff       	call   8010209b <kinit2>
  userinit();      // first user process
80102c22:	e8 41 07 00 00       	call   80103368 <userinit>
  mpmain();        // finish this processor's setup
80102c27:	e8 25 ff ff ff       	call   80102b51 <mpmain>

80102c2c <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102c2c:	55                   	push   %ebp
80102c2d:	89 e5                	mov    %esp,%ebp
80102c2f:	56                   	push   %esi
80102c30:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102c31:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102c36:	b9 00 00 00 00       	mov    $0x0,%ecx
80102c3b:	eb 09                	jmp    80102c46 <sum+0x1a>
    sum += addr[i];
80102c3d:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102c41:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102c43:	83 c1 01             	add    $0x1,%ecx
80102c46:	39 d1                	cmp    %edx,%ecx
80102c48:	7c f3                	jl     80102c3d <sum+0x11>
  return sum;
}
80102c4a:	89 d8                	mov    %ebx,%eax
80102c4c:	5b                   	pop    %ebx
80102c4d:	5e                   	pop    %esi
80102c4e:	5d                   	pop    %ebp
80102c4f:	c3                   	ret    

80102c50 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102c50:	55                   	push   %ebp
80102c51:	89 e5                	mov    %esp,%ebp
80102c53:	56                   	push   %esi
80102c54:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102c55:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102c5b:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102c5d:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102c5f:	eb 03                	jmp    80102c64 <mpsearch1+0x14>
80102c61:	83 c3 10             	add    $0x10,%ebx
80102c64:	39 f3                	cmp    %esi,%ebx
80102c66:	73 29                	jae    80102c91 <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102c68:	83 ec 04             	sub    $0x4,%esp
80102c6b:	6a 04                	push   $0x4
80102c6d:	68 18 6b 10 80       	push   $0x80106b18
80102c72:	53                   	push   %ebx
80102c73:	e8 60 11 00 00       	call   80103dd8 <memcmp>
80102c78:	83 c4 10             	add    $0x10,%esp
80102c7b:	85 c0                	test   %eax,%eax
80102c7d:	75 e2                	jne    80102c61 <mpsearch1+0x11>
80102c7f:	ba 10 00 00 00       	mov    $0x10,%edx
80102c84:	89 d8                	mov    %ebx,%eax
80102c86:	e8 a1 ff ff ff       	call   80102c2c <sum>
80102c8b:	84 c0                	test   %al,%al
80102c8d:	75 d2                	jne    80102c61 <mpsearch1+0x11>
80102c8f:	eb 05                	jmp    80102c96 <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102c91:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102c96:	89 d8                	mov    %ebx,%eax
80102c98:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102c9b:	5b                   	pop    %ebx
80102c9c:	5e                   	pop    %esi
80102c9d:	5d                   	pop    %ebp
80102c9e:	c3                   	ret    

80102c9f <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102c9f:	55                   	push   %ebp
80102ca0:	89 e5                	mov    %esp,%ebp
80102ca2:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102ca5:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102cac:	c1 e0 08             	shl    $0x8,%eax
80102caf:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102cb6:	09 d0                	or     %edx,%eax
80102cb8:	c1 e0 04             	shl    $0x4,%eax
80102cbb:	85 c0                	test   %eax,%eax
80102cbd:	74 1f                	je     80102cde <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102cbf:	ba 00 04 00 00       	mov    $0x400,%edx
80102cc4:	e8 87 ff ff ff       	call   80102c50 <mpsearch1>
80102cc9:	85 c0                	test   %eax,%eax
80102ccb:	75 0f                	jne    80102cdc <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102ccd:	ba 00 00 01 00       	mov    $0x10000,%edx
80102cd2:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102cd7:	e8 74 ff ff ff       	call   80102c50 <mpsearch1>
}
80102cdc:	c9                   	leave  
80102cdd:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102cde:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102ce5:	c1 e0 08             	shl    $0x8,%eax
80102ce8:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102cef:	09 d0                	or     %edx,%eax
80102cf1:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102cf4:	2d 00 04 00 00       	sub    $0x400,%eax
80102cf9:	ba 00 04 00 00       	mov    $0x400,%edx
80102cfe:	e8 4d ff ff ff       	call   80102c50 <mpsearch1>
80102d03:	85 c0                	test   %eax,%eax
80102d05:	75 d5                	jne    80102cdc <mpsearch+0x3d>
80102d07:	eb c4                	jmp    80102ccd <mpsearch+0x2e>

80102d09 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102d09:	55                   	push   %ebp
80102d0a:	89 e5                	mov    %esp,%ebp
80102d0c:	57                   	push   %edi
80102d0d:	56                   	push   %esi
80102d0e:	53                   	push   %ebx
80102d0f:	83 ec 1c             	sub    $0x1c,%esp
80102d12:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102d15:	e8 85 ff ff ff       	call   80102c9f <mpsearch>
80102d1a:	85 c0                	test   %eax,%eax
80102d1c:	74 5c                	je     80102d7a <mpconfig+0x71>
80102d1e:	89 c7                	mov    %eax,%edi
80102d20:	8b 58 04             	mov    0x4(%eax),%ebx
80102d23:	85 db                	test   %ebx,%ebx
80102d25:	74 5a                	je     80102d81 <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102d27:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102d2d:	83 ec 04             	sub    $0x4,%esp
80102d30:	6a 04                	push   $0x4
80102d32:	68 1d 6b 10 80       	push   $0x80106b1d
80102d37:	56                   	push   %esi
80102d38:	e8 9b 10 00 00       	call   80103dd8 <memcmp>
80102d3d:	83 c4 10             	add    $0x10,%esp
80102d40:	85 c0                	test   %eax,%eax
80102d42:	75 44                	jne    80102d88 <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102d44:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102d4b:	3c 01                	cmp    $0x1,%al
80102d4d:	0f 95 c2             	setne  %dl
80102d50:	3c 04                	cmp    $0x4,%al
80102d52:	0f 95 c0             	setne  %al
80102d55:	84 c2                	test   %al,%dl
80102d57:	75 36                	jne    80102d8f <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102d59:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102d60:	89 f0                	mov    %esi,%eax
80102d62:	e8 c5 fe ff ff       	call   80102c2c <sum>
80102d67:	84 c0                	test   %al,%al
80102d69:	75 2b                	jne    80102d96 <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102d6b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102d6e:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102d70:	89 f0                	mov    %esi,%eax
80102d72:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102d75:	5b                   	pop    %ebx
80102d76:	5e                   	pop    %esi
80102d77:	5f                   	pop    %edi
80102d78:	5d                   	pop    %ebp
80102d79:	c3                   	ret    
    return 0;
80102d7a:	be 00 00 00 00       	mov    $0x0,%esi
80102d7f:	eb ef                	jmp    80102d70 <mpconfig+0x67>
80102d81:	be 00 00 00 00       	mov    $0x0,%esi
80102d86:	eb e8                	jmp    80102d70 <mpconfig+0x67>
    return 0;
80102d88:	be 00 00 00 00       	mov    $0x0,%esi
80102d8d:	eb e1                	jmp    80102d70 <mpconfig+0x67>
    return 0;
80102d8f:	be 00 00 00 00       	mov    $0x0,%esi
80102d94:	eb da                	jmp    80102d70 <mpconfig+0x67>
    return 0;
80102d96:	be 00 00 00 00       	mov    $0x0,%esi
80102d9b:	eb d3                	jmp    80102d70 <mpconfig+0x67>

80102d9d <mpinit>:

void
mpinit(void)
{
80102d9d:	55                   	push   %ebp
80102d9e:	89 e5                	mov    %esp,%ebp
80102da0:	57                   	push   %edi
80102da1:	56                   	push   %esi
80102da2:	53                   	push   %ebx
80102da3:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102da6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102da9:	e8 5b ff ff ff       	call   80102d09 <mpconfig>
80102dae:	85 c0                	test   %eax,%eax
80102db0:	74 19                	je     80102dcb <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102db2:	8b 50 24             	mov    0x24(%eax),%edx
80102db5:	89 15 e4 26 13 80    	mov    %edx,0x801326e4
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102dbb:	8d 50 2c             	lea    0x2c(%eax),%edx
80102dbe:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102dc2:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102dc4:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102dc9:	eb 34                	jmp    80102dff <mpinit+0x62>
    panic("Expect to run on an SMP");
80102dcb:	83 ec 0c             	sub    $0xc,%esp
80102dce:	68 22 6b 10 80       	push   $0x80106b22
80102dd3:	e8 70 d5 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102dd8:	8b 35 80 2d 13 80    	mov    0x80132d80,%esi
80102dde:	83 fe 07             	cmp    $0x7,%esi
80102de1:	7f 19                	jg     80102dfc <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102de3:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102de7:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102ded:	88 87 00 28 13 80    	mov    %al,-0x7fecd800(%edi)
        ncpu++;
80102df3:	83 c6 01             	add    $0x1,%esi
80102df6:	89 35 80 2d 13 80    	mov    %esi,0x80132d80
      }
      p += sizeof(struct mpproc);
80102dfc:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102dff:	39 ca                	cmp    %ecx,%edx
80102e01:	73 2b                	jae    80102e2e <mpinit+0x91>
    switch(*p){
80102e03:	0f b6 02             	movzbl (%edx),%eax
80102e06:	3c 04                	cmp    $0x4,%al
80102e08:	77 1d                	ja     80102e27 <mpinit+0x8a>
80102e0a:	0f b6 c0             	movzbl %al,%eax
80102e0d:	ff 24 85 5c 6b 10 80 	jmp    *-0x7fef94a4(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102e14:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102e18:	a2 e0 27 13 80       	mov    %al,0x801327e0
      p += sizeof(struct mpioapic);
80102e1d:	83 c2 08             	add    $0x8,%edx
      continue;
80102e20:	eb dd                	jmp    80102dff <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102e22:	83 c2 08             	add    $0x8,%edx
      continue;
80102e25:	eb d8                	jmp    80102dff <mpinit+0x62>
    default:
      ismp = 0;
80102e27:	bb 00 00 00 00       	mov    $0x0,%ebx
80102e2c:	eb d1                	jmp    80102dff <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102e2e:	85 db                	test   %ebx,%ebx
80102e30:	74 26                	je     80102e58 <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102e32:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102e35:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102e39:	74 15                	je     80102e50 <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e3b:	b8 70 00 00 00       	mov    $0x70,%eax
80102e40:	ba 22 00 00 00       	mov    $0x22,%edx
80102e45:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102e46:	ba 23 00 00 00       	mov    $0x23,%edx
80102e4b:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102e4c:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e4f:	ee                   	out    %al,(%dx)
  }
}
80102e50:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102e53:	5b                   	pop    %ebx
80102e54:	5e                   	pop    %esi
80102e55:	5f                   	pop    %edi
80102e56:	5d                   	pop    %ebp
80102e57:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102e58:	83 ec 0c             	sub    $0xc,%esp
80102e5b:	68 3c 6b 10 80       	push   $0x80106b3c
80102e60:	e8 e3 d4 ff ff       	call   80100348 <panic>

80102e65 <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102e65:	55                   	push   %ebp
80102e66:	89 e5                	mov    %esp,%ebp
80102e68:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102e6d:	ba 21 00 00 00       	mov    $0x21,%edx
80102e72:	ee                   	out    %al,(%dx)
80102e73:	ba a1 00 00 00       	mov    $0xa1,%edx
80102e78:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102e79:	5d                   	pop    %ebp
80102e7a:	c3                   	ret    

80102e7b <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102e7b:	55                   	push   %ebp
80102e7c:	89 e5                	mov    %esp,%ebp
80102e7e:	57                   	push   %edi
80102e7f:	56                   	push   %esi
80102e80:	53                   	push   %ebx
80102e81:	83 ec 0c             	sub    $0xc,%esp
80102e84:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102e87:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102e8a:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102e90:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102e96:	e8 92 dd ff ff       	call   80100c2d <filealloc>
80102e9b:	89 03                	mov    %eax,(%ebx)
80102e9d:	85 c0                	test   %eax,%eax
80102e9f:	74 1e                	je     80102ebf <pipealloc+0x44>
80102ea1:	e8 87 dd ff ff       	call   80100c2d <filealloc>
80102ea6:	89 06                	mov    %eax,(%esi)
80102ea8:	85 c0                	test   %eax,%eax
80102eaa:	74 13                	je     80102ebf <pipealloc+0x44>
    goto bad;
  if((p = (struct pipe*)kalloc2(-2)) == 0)
80102eac:	83 ec 0c             	sub    $0xc,%esp
80102eaf:	6a fe                	push   $0xfffffffe
80102eb1:	e8 a8 f2 ff ff       	call   8010215e <kalloc2>
80102eb6:	89 c7                	mov    %eax,%edi
80102eb8:	83 c4 10             	add    $0x10,%esp
80102ebb:	85 c0                	test   %eax,%eax
80102ebd:	75 35                	jne    80102ef4 <pipealloc+0x79>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102ebf:	8b 03                	mov    (%ebx),%eax
80102ec1:	85 c0                	test   %eax,%eax
80102ec3:	74 0c                	je     80102ed1 <pipealloc+0x56>
    fileclose(*f0);
80102ec5:	83 ec 0c             	sub    $0xc,%esp
80102ec8:	50                   	push   %eax
80102ec9:	e8 05 de ff ff       	call   80100cd3 <fileclose>
80102ece:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102ed1:	8b 06                	mov    (%esi),%eax
80102ed3:	85 c0                	test   %eax,%eax
80102ed5:	0f 84 8b 00 00 00    	je     80102f66 <pipealloc+0xeb>
    fileclose(*f1);
80102edb:	83 ec 0c             	sub    $0xc,%esp
80102ede:	50                   	push   %eax
80102edf:	e8 ef dd ff ff       	call   80100cd3 <fileclose>
80102ee4:	83 c4 10             	add    $0x10,%esp
  return -1;
80102ee7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102eec:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102eef:	5b                   	pop    %ebx
80102ef0:	5e                   	pop    %esi
80102ef1:	5f                   	pop    %edi
80102ef2:	5d                   	pop    %ebp
80102ef3:	c3                   	ret    
  p->readopen = 1;
80102ef4:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102efb:	00 00 00 
  p->writeopen = 1;
80102efe:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102f05:	00 00 00 
  p->nwrite = 0;
80102f08:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102f0f:	00 00 00 
  p->nread = 0;
80102f12:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102f19:	00 00 00 
  initlock(&p->lock, "pipe");
80102f1c:	83 ec 08             	sub    $0x8,%esp
80102f1f:	68 70 6b 10 80       	push   $0x80106b70
80102f24:	50                   	push   %eax
80102f25:	e8 80 0c 00 00       	call   80103baa <initlock>
  (*f0)->type = FD_PIPE;
80102f2a:	8b 03                	mov    (%ebx),%eax
80102f2c:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102f32:	8b 03                	mov    (%ebx),%eax
80102f34:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102f38:	8b 03                	mov    (%ebx),%eax
80102f3a:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102f3e:	8b 03                	mov    (%ebx),%eax
80102f40:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80102f43:	8b 06                	mov    (%esi),%eax
80102f45:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80102f4b:	8b 06                	mov    (%esi),%eax
80102f4d:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80102f51:	8b 06                	mov    (%esi),%eax
80102f53:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80102f57:	8b 06                	mov    (%esi),%eax
80102f59:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80102f5c:	83 c4 10             	add    $0x10,%esp
80102f5f:	b8 00 00 00 00       	mov    $0x0,%eax
80102f64:	eb 86                	jmp    80102eec <pipealloc+0x71>
  return -1;
80102f66:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102f6b:	e9 7c ff ff ff       	jmp    80102eec <pipealloc+0x71>

80102f70 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80102f70:	55                   	push   %ebp
80102f71:	89 e5                	mov    %esp,%ebp
80102f73:	53                   	push   %ebx
80102f74:	83 ec 10             	sub    $0x10,%esp
80102f77:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80102f7a:	53                   	push   %ebx
80102f7b:	e8 66 0d 00 00       	call   80103ce6 <acquire>
  if(writable){
80102f80:	83 c4 10             	add    $0x10,%esp
80102f83:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102f87:	74 3f                	je     80102fc8 <pipeclose+0x58>
    p->writeopen = 0;
80102f89:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80102f90:	00 00 00 
    wakeup(&p->nread);
80102f93:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102f99:	83 ec 0c             	sub    $0xc,%esp
80102f9c:	50                   	push   %eax
80102f9d:	e8 ae 09 00 00       	call   80103950 <wakeup>
80102fa2:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80102fa5:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102fac:	75 09                	jne    80102fb7 <pipeclose+0x47>
80102fae:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80102fb5:	74 2f                	je     80102fe6 <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80102fb7:	83 ec 0c             	sub    $0xc,%esp
80102fba:	53                   	push   %ebx
80102fbb:	e8 8b 0d 00 00       	call   80103d4b <release>
80102fc0:	83 c4 10             	add    $0x10,%esp
}
80102fc3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102fc6:	c9                   	leave  
80102fc7:	c3                   	ret    
    p->readopen = 0;
80102fc8:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
80102fcf:	00 00 00 
    wakeup(&p->nwrite);
80102fd2:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102fd8:	83 ec 0c             	sub    $0xc,%esp
80102fdb:	50                   	push   %eax
80102fdc:	e8 6f 09 00 00       	call   80103950 <wakeup>
80102fe1:	83 c4 10             	add    $0x10,%esp
80102fe4:	eb bf                	jmp    80102fa5 <pipeclose+0x35>
    release(&p->lock);
80102fe6:	83 ec 0c             	sub    $0xc,%esp
80102fe9:	53                   	push   %ebx
80102fea:	e8 5c 0d 00 00       	call   80103d4b <release>
    kfree((char*)p);
80102fef:	89 1c 24             	mov    %ebx,(%esp)
80102ff2:	e8 ad ef ff ff       	call   80101fa4 <kfree>
80102ff7:	83 c4 10             	add    $0x10,%esp
80102ffa:	eb c7                	jmp    80102fc3 <pipeclose+0x53>

80102ffc <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
80102ffc:	55                   	push   %ebp
80102ffd:	89 e5                	mov    %esp,%ebp
80102fff:	57                   	push   %edi
80103000:	56                   	push   %esi
80103001:	53                   	push   %ebx
80103002:	83 ec 18             	sub    $0x18,%esp
80103005:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80103008:	89 de                	mov    %ebx,%esi
8010300a:	53                   	push   %ebx
8010300b:	e8 d6 0c 00 00       	call   80103ce6 <acquire>
  for(i = 0; i < n; i++){
80103010:	83 c4 10             	add    $0x10,%esp
80103013:	bf 00 00 00 00       	mov    $0x0,%edi
80103018:	3b 7d 10             	cmp    0x10(%ebp),%edi
8010301b:	0f 8d 88 00 00 00    	jge    801030a9 <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80103021:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
80103027:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
8010302d:	05 00 02 00 00       	add    $0x200,%eax
80103032:	39 c2                	cmp    %eax,%edx
80103034:	75 51                	jne    80103087 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
80103036:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
8010303d:	74 2f                	je     8010306e <pipewrite+0x72>
8010303f:	e8 00 03 00 00       	call   80103344 <myproc>
80103044:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80103048:	75 24                	jne    8010306e <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
8010304a:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103050:	83 ec 0c             	sub    $0xc,%esp
80103053:	50                   	push   %eax
80103054:	e8 f7 08 00 00       	call   80103950 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103059:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
8010305f:	83 c4 08             	add    $0x8,%esp
80103062:	56                   	push   %esi
80103063:	50                   	push   %eax
80103064:	e8 82 07 00 00       	call   801037eb <sleep>
80103069:	83 c4 10             	add    $0x10,%esp
8010306c:	eb b3                	jmp    80103021 <pipewrite+0x25>
        release(&p->lock);
8010306e:	83 ec 0c             	sub    $0xc,%esp
80103071:	53                   	push   %ebx
80103072:	e8 d4 0c 00 00       	call   80103d4b <release>
        return -1;
80103077:	83 c4 10             	add    $0x10,%esp
8010307a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
8010307f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103082:	5b                   	pop    %ebx
80103083:	5e                   	pop    %esi
80103084:	5f                   	pop    %edi
80103085:	5d                   	pop    %ebp
80103086:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103087:	8d 42 01             	lea    0x1(%edx),%eax
8010308a:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80103090:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80103096:	8b 45 0c             	mov    0xc(%ebp),%eax
80103099:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
8010309d:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
801030a1:	83 c7 01             	add    $0x1,%edi
801030a4:	e9 6f ff ff ff       	jmp    80103018 <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
801030a9:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801030af:	83 ec 0c             	sub    $0xc,%esp
801030b2:	50                   	push   %eax
801030b3:	e8 98 08 00 00       	call   80103950 <wakeup>
  release(&p->lock);
801030b8:	89 1c 24             	mov    %ebx,(%esp)
801030bb:	e8 8b 0c 00 00       	call   80103d4b <release>
  return n;
801030c0:	83 c4 10             	add    $0x10,%esp
801030c3:	8b 45 10             	mov    0x10(%ebp),%eax
801030c6:	eb b7                	jmp    8010307f <pipewrite+0x83>

801030c8 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801030c8:	55                   	push   %ebp
801030c9:	89 e5                	mov    %esp,%ebp
801030cb:	57                   	push   %edi
801030cc:	56                   	push   %esi
801030cd:	53                   	push   %ebx
801030ce:	83 ec 18             	sub    $0x18,%esp
801030d1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
801030d4:	89 df                	mov    %ebx,%edi
801030d6:	53                   	push   %ebx
801030d7:	e8 0a 0c 00 00       	call   80103ce6 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801030dc:	83 c4 10             	add    $0x10,%esp
801030df:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
801030e5:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
801030eb:	75 3d                	jne    8010312a <piperead+0x62>
801030ed:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
801030f3:	85 f6                	test   %esi,%esi
801030f5:	74 38                	je     8010312f <piperead+0x67>
    if(myproc()->killed){
801030f7:	e8 48 02 00 00       	call   80103344 <myproc>
801030fc:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80103100:	75 15                	jne    80103117 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80103102:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103108:	83 ec 08             	sub    $0x8,%esp
8010310b:	57                   	push   %edi
8010310c:	50                   	push   %eax
8010310d:	e8 d9 06 00 00       	call   801037eb <sleep>
80103112:	83 c4 10             	add    $0x10,%esp
80103115:	eb c8                	jmp    801030df <piperead+0x17>
      release(&p->lock);
80103117:	83 ec 0c             	sub    $0xc,%esp
8010311a:	53                   	push   %ebx
8010311b:	e8 2b 0c 00 00       	call   80103d4b <release>
      return -1;
80103120:	83 c4 10             	add    $0x10,%esp
80103123:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103128:	eb 50                	jmp    8010317a <piperead+0xb2>
8010312a:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010312f:	3b 75 10             	cmp    0x10(%ebp),%esi
80103132:	7d 2c                	jge    80103160 <piperead+0x98>
    if(p->nread == p->nwrite)
80103134:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
8010313a:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
80103140:	74 1e                	je     80103160 <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80103142:	8d 50 01             	lea    0x1(%eax),%edx
80103145:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
8010314b:	25 ff 01 00 00       	and    $0x1ff,%eax
80103150:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
80103155:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103158:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010315b:	83 c6 01             	add    $0x1,%esi
8010315e:	eb cf                	jmp    8010312f <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80103160:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103166:	83 ec 0c             	sub    $0xc,%esp
80103169:	50                   	push   %eax
8010316a:	e8 e1 07 00 00       	call   80103950 <wakeup>
  release(&p->lock);
8010316f:	89 1c 24             	mov    %ebx,(%esp)
80103172:	e8 d4 0b 00 00       	call   80103d4b <release>
  return i;
80103177:	83 c4 10             	add    $0x10,%esp
}
8010317a:	89 f0                	mov    %esi,%eax
8010317c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010317f:	5b                   	pop    %ebx
80103180:	5e                   	pop    %esi
80103181:	5f                   	pop    %edi
80103182:	5d                   	pop    %ebp
80103183:	c3                   	ret    

80103184 <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80103184:	55                   	push   %ebp
80103185:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103187:	ba d4 2d 13 80       	mov    $0x80132dd4,%edx
8010318c:	eb 03                	jmp    80103191 <wakeup1+0xd>
8010318e:	83 c2 7c             	add    $0x7c,%edx
80103191:	81 fa d4 4c 13 80    	cmp    $0x80134cd4,%edx
80103197:	73 14                	jae    801031ad <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
80103199:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
8010319d:	75 ef                	jne    8010318e <wakeup1+0xa>
8010319f:	39 42 20             	cmp    %eax,0x20(%edx)
801031a2:	75 ea                	jne    8010318e <wakeup1+0xa>
      p->state = RUNNABLE;
801031a4:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
801031ab:	eb e1                	jmp    8010318e <wakeup1+0xa>
}
801031ad:	5d                   	pop    %ebp
801031ae:	c3                   	ret    

801031af <allocproc>:
{
801031af:	55                   	push   %ebp
801031b0:	89 e5                	mov    %esp,%ebp
801031b2:	53                   	push   %ebx
801031b3:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
801031b6:	68 a0 2d 13 80       	push   $0x80132da0
801031bb:	e8 26 0b 00 00       	call   80103ce6 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801031c0:	83 c4 10             	add    $0x10,%esp
801031c3:	bb d4 2d 13 80       	mov    $0x80132dd4,%ebx
801031c8:	81 fb d4 4c 13 80    	cmp    $0x80134cd4,%ebx
801031ce:	73 0b                	jae    801031db <allocproc+0x2c>
    if(p->state == UNUSED)
801031d0:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
801031d4:	74 1c                	je     801031f2 <allocproc+0x43>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801031d6:	83 c3 7c             	add    $0x7c,%ebx
801031d9:	eb ed                	jmp    801031c8 <allocproc+0x19>
  release(&ptable.lock);
801031db:	83 ec 0c             	sub    $0xc,%esp
801031de:	68 a0 2d 13 80       	push   $0x80132da0
801031e3:	e8 63 0b 00 00       	call   80103d4b <release>
  return 0;
801031e8:	83 c4 10             	add    $0x10,%esp
801031eb:	bb 00 00 00 00       	mov    $0x0,%ebx
801031f0:	eb 69                	jmp    8010325b <allocproc+0xac>
  p->state = EMBRYO;
801031f2:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
801031f9:	a1 04 a0 10 80       	mov    0x8010a004,%eax
801031fe:	8d 50 01             	lea    0x1(%eax),%edx
80103201:	89 15 04 a0 10 80    	mov    %edx,0x8010a004
80103207:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
8010320a:	83 ec 0c             	sub    $0xc,%esp
8010320d:	68 a0 2d 13 80       	push   $0x80132da0
80103212:	e8 34 0b 00 00       	call   80103d4b <release>
  if((p->kstack = kalloc()) == 0){
80103217:	e8 ac ee ff ff       	call   801020c8 <kalloc>
8010321c:	89 43 08             	mov    %eax,0x8(%ebx)
8010321f:	83 c4 10             	add    $0x10,%esp
80103222:	85 c0                	test   %eax,%eax
80103224:	74 3c                	je     80103262 <allocproc+0xb3>
  sp -= sizeof *p->tf;
80103226:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
8010322c:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
8010322f:	c7 80 b0 0f 00 00 a8 	movl   $0x80104ea8,0xfb0(%eax)
80103236:	4e 10 80 
  sp -= sizeof *p->context;
80103239:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
8010323e:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
80103241:	83 ec 04             	sub    $0x4,%esp
80103244:	6a 14                	push   $0x14
80103246:	6a 00                	push   $0x0
80103248:	50                   	push   %eax
80103249:	e8 44 0b 00 00       	call   80103d92 <memset>
  p->context->eip = (uint)forkret;
8010324e:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103251:	c7 40 10 70 32 10 80 	movl   $0x80103270,0x10(%eax)
  return p;
80103258:	83 c4 10             	add    $0x10,%esp
}
8010325b:	89 d8                	mov    %ebx,%eax
8010325d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103260:	c9                   	leave  
80103261:	c3                   	ret    
    p->state = UNUSED;
80103262:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
80103269:	bb 00 00 00 00       	mov    $0x0,%ebx
8010326e:	eb eb                	jmp    8010325b <allocproc+0xac>

80103270 <forkret>:
{
80103270:	55                   	push   %ebp
80103271:	89 e5                	mov    %esp,%ebp
80103273:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
80103276:	68 a0 2d 13 80       	push   $0x80132da0
8010327b:	e8 cb 0a 00 00       	call   80103d4b <release>
  if (first) {
80103280:	83 c4 10             	add    $0x10,%esp
80103283:	83 3d 00 a0 10 80 00 	cmpl   $0x0,0x8010a000
8010328a:	75 02                	jne    8010328e <forkret+0x1e>
}
8010328c:	c9                   	leave  
8010328d:	c3                   	ret    
    first = 0;
8010328e:	c7 05 00 a0 10 80 00 	movl   $0x0,0x8010a000
80103295:	00 00 00 
    iinit(ROOTDEV);
80103298:	83 ec 0c             	sub    $0xc,%esp
8010329b:	6a 01                	push   $0x1
8010329d:	e8 4a e0 ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
801032a2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801032a9:	e8 fd f5 ff ff       	call   801028ab <initlog>
801032ae:	83 c4 10             	add    $0x10,%esp
}
801032b1:	eb d9                	jmp    8010328c <forkret+0x1c>

801032b3 <pinit>:
{
801032b3:	55                   	push   %ebp
801032b4:	89 e5                	mov    %esp,%ebp
801032b6:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
801032b9:	68 75 6b 10 80       	push   $0x80106b75
801032be:	68 a0 2d 13 80       	push   $0x80132da0
801032c3:	e8 e2 08 00 00       	call   80103baa <initlock>
}
801032c8:	83 c4 10             	add    $0x10,%esp
801032cb:	c9                   	leave  
801032cc:	c3                   	ret    

801032cd <mycpu>:
{
801032cd:	55                   	push   %ebp
801032ce:	89 e5                	mov    %esp,%ebp
801032d0:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801032d3:	9c                   	pushf  
801032d4:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801032d5:	f6 c4 02             	test   $0x2,%ah
801032d8:	75 28                	jne    80103302 <mycpu+0x35>
  apicid = lapicid();
801032da:	e8 e5 f1 ff ff       	call   801024c4 <lapicid>
  for (i = 0; i < ncpu; ++i) {
801032df:	ba 00 00 00 00       	mov    $0x0,%edx
801032e4:	39 15 80 2d 13 80    	cmp    %edx,0x80132d80
801032ea:	7e 23                	jle    8010330f <mycpu+0x42>
    if (cpus[i].apicid == apicid)
801032ec:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
801032f2:	0f b6 89 00 28 13 80 	movzbl -0x7fecd800(%ecx),%ecx
801032f9:	39 c1                	cmp    %eax,%ecx
801032fb:	74 1f                	je     8010331c <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
801032fd:	83 c2 01             	add    $0x1,%edx
80103300:	eb e2                	jmp    801032e4 <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
80103302:	83 ec 0c             	sub    $0xc,%esp
80103305:	68 58 6c 10 80       	push   $0x80106c58
8010330a:	e8 39 d0 ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
8010330f:	83 ec 0c             	sub    $0xc,%esp
80103312:	68 7c 6b 10 80       	push   $0x80106b7c
80103317:	e8 2c d0 ff ff       	call   80100348 <panic>
      return &cpus[i];
8010331c:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
80103322:	05 00 28 13 80       	add    $0x80132800,%eax
}
80103327:	c9                   	leave  
80103328:	c3                   	ret    

80103329 <cpuid>:
cpuid() {
80103329:	55                   	push   %ebp
8010332a:	89 e5                	mov    %esp,%ebp
8010332c:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
8010332f:	e8 99 ff ff ff       	call   801032cd <mycpu>
80103334:	2d 00 28 13 80       	sub    $0x80132800,%eax
80103339:	c1 f8 04             	sar    $0x4,%eax
8010333c:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
80103342:	c9                   	leave  
80103343:	c3                   	ret    

80103344 <myproc>:
myproc(void) {
80103344:	55                   	push   %ebp
80103345:	89 e5                	mov    %esp,%ebp
80103347:	53                   	push   %ebx
80103348:	83 ec 04             	sub    $0x4,%esp
  pushcli();
8010334b:	e8 b9 08 00 00       	call   80103c09 <pushcli>
  c = mycpu();
80103350:	e8 78 ff ff ff       	call   801032cd <mycpu>
  p = c->proc;
80103355:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
8010335b:	e8 e6 08 00 00       	call   80103c46 <popcli>
}
80103360:	89 d8                	mov    %ebx,%eax
80103362:	83 c4 04             	add    $0x4,%esp
80103365:	5b                   	pop    %ebx
80103366:	5d                   	pop    %ebp
80103367:	c3                   	ret    

80103368 <userinit>:
{
80103368:	55                   	push   %ebp
80103369:	89 e5                	mov    %esp,%ebp
8010336b:	53                   	push   %ebx
8010336c:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
8010336f:	e8 3b fe ff ff       	call   801031af <allocproc>
80103374:	89 c3                	mov    %eax,%ebx
  initproc = p;
80103376:	a3 bc a5 10 80       	mov    %eax,0x8010a5bc
  if((p->pgdir = setupkvm()) == 0)
8010337b:	e8 27 30 00 00       	call   801063a7 <setupkvm>
80103380:	89 43 04             	mov    %eax,0x4(%ebx)
80103383:	85 c0                	test   %eax,%eax
80103385:	0f 84 b7 00 00 00    	je     80103442 <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
8010338b:	83 ec 04             	sub    $0x4,%esp
8010338e:	68 2c 00 00 00       	push   $0x2c
80103393:	68 60 a4 10 80       	push   $0x8010a460
80103398:	50                   	push   %eax
80103399:	e8 01 2d 00 00       	call   8010609f <inituvm>
  p->sz = PGSIZE;
8010339e:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
801033a4:	83 c4 0c             	add    $0xc,%esp
801033a7:	6a 4c                	push   $0x4c
801033a9:	6a 00                	push   $0x0
801033ab:	ff 73 18             	pushl  0x18(%ebx)
801033ae:	e8 df 09 00 00       	call   80103d92 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801033b3:	8b 43 18             	mov    0x18(%ebx),%eax
801033b6:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801033bc:	8b 43 18             	mov    0x18(%ebx),%eax
801033bf:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
801033c5:	8b 43 18             	mov    0x18(%ebx),%eax
801033c8:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801033cc:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801033d0:	8b 43 18             	mov    0x18(%ebx),%eax
801033d3:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801033d7:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801033db:	8b 43 18             	mov    0x18(%ebx),%eax
801033de:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801033e5:	8b 43 18             	mov    0x18(%ebx),%eax
801033e8:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801033ef:	8b 43 18             	mov    0x18(%ebx),%eax
801033f2:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
801033f9:	8d 43 6c             	lea    0x6c(%ebx),%eax
801033fc:	83 c4 0c             	add    $0xc,%esp
801033ff:	6a 10                	push   $0x10
80103401:	68 a5 6b 10 80       	push   $0x80106ba5
80103406:	50                   	push   %eax
80103407:	e8 ed 0a 00 00       	call   80103ef9 <safestrcpy>
  p->cwd = namei("/");
8010340c:	c7 04 24 ae 6b 10 80 	movl   $0x80106bae,(%esp)
80103413:	e8 c9 e7 ff ff       	call   80101be1 <namei>
80103418:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
8010341b:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
80103422:	e8 bf 08 00 00       	call   80103ce6 <acquire>
  p->state = RUNNABLE;
80103427:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
8010342e:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
80103435:	e8 11 09 00 00       	call   80103d4b <release>
}
8010343a:	83 c4 10             	add    $0x10,%esp
8010343d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103440:	c9                   	leave  
80103441:	c3                   	ret    
    panic("userinit: out of memory?");
80103442:	83 ec 0c             	sub    $0xc,%esp
80103445:	68 8c 6b 10 80       	push   $0x80106b8c
8010344a:	e8 f9 ce ff ff       	call   80100348 <panic>

8010344f <growproc>:
{
8010344f:	55                   	push   %ebp
80103450:	89 e5                	mov    %esp,%ebp
80103452:	56                   	push   %esi
80103453:	53                   	push   %ebx
80103454:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
80103457:	e8 e8 fe ff ff       	call   80103344 <myproc>
8010345c:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
8010345e:	8b 00                	mov    (%eax),%eax
  if(n > 0){
80103460:	85 f6                	test   %esi,%esi
80103462:	7f 21                	jg     80103485 <growproc+0x36>
  } else if(n < 0){
80103464:	85 f6                	test   %esi,%esi
80103466:	79 33                	jns    8010349b <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103468:	83 ec 04             	sub    $0x4,%esp
8010346b:	01 c6                	add    %eax,%esi
8010346d:	56                   	push   %esi
8010346e:	50                   	push   %eax
8010346f:	ff 73 04             	pushl  0x4(%ebx)
80103472:	e8 36 2d 00 00       	call   801061ad <deallocuvm>
80103477:	83 c4 10             	add    $0x10,%esp
8010347a:	85 c0                	test   %eax,%eax
8010347c:	75 1d                	jne    8010349b <growproc+0x4c>
      return -1;
8010347e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103483:	eb 29                	jmp    801034ae <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103485:	83 ec 04             	sub    $0x4,%esp
80103488:	01 c6                	add    %eax,%esi
8010348a:	56                   	push   %esi
8010348b:	50                   	push   %eax
8010348c:	ff 73 04             	pushl  0x4(%ebx)
8010348f:	e8 ab 2d 00 00       	call   8010623f <allocuvm>
80103494:	83 c4 10             	add    $0x10,%esp
80103497:	85 c0                	test   %eax,%eax
80103499:	74 1a                	je     801034b5 <growproc+0x66>
  curproc->sz = sz;
8010349b:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
8010349d:	83 ec 0c             	sub    $0xc,%esp
801034a0:	53                   	push   %ebx
801034a1:	e8 e1 2a 00 00       	call   80105f87 <switchuvm>
  return 0;
801034a6:	83 c4 10             	add    $0x10,%esp
801034a9:	b8 00 00 00 00       	mov    $0x0,%eax
}
801034ae:	8d 65 f8             	lea    -0x8(%ebp),%esp
801034b1:	5b                   	pop    %ebx
801034b2:	5e                   	pop    %esi
801034b3:	5d                   	pop    %ebp
801034b4:	c3                   	ret    
      return -1;
801034b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801034ba:	eb f2                	jmp    801034ae <growproc+0x5f>

801034bc <fork>:
{
801034bc:	55                   	push   %ebp
801034bd:	89 e5                	mov    %esp,%ebp
801034bf:	57                   	push   %edi
801034c0:	56                   	push   %esi
801034c1:	53                   	push   %ebx
801034c2:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
801034c5:	e8 7a fe ff ff       	call   80103344 <myproc>
801034ca:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
801034cc:	e8 de fc ff ff       	call   801031af <allocproc>
801034d1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801034d4:	85 c0                	test   %eax,%eax
801034d6:	0f 84 e3 00 00 00    	je     801035bf <fork+0x103>
801034dc:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz, np->pid)) == 0){
801034de:	83 ec 04             	sub    $0x4,%esp
801034e1:	ff 70 10             	pushl  0x10(%eax)
801034e4:	ff 33                	pushl  (%ebx)
801034e6:	ff 73 04             	pushl  0x4(%ebx)
801034e9:	e8 72 2f 00 00       	call   80106460 <copyuvm>
801034ee:	89 47 04             	mov    %eax,0x4(%edi)
801034f1:	83 c4 10             	add    $0x10,%esp
801034f4:	85 c0                	test   %eax,%eax
801034f6:	74 2a                	je     80103522 <fork+0x66>
  np->sz = curproc->sz;
801034f8:	8b 03                	mov    (%ebx),%eax
801034fa:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801034fd:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
801034ff:	89 c8                	mov    %ecx,%eax
80103501:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
80103504:	8b 73 18             	mov    0x18(%ebx),%esi
80103507:	8b 79 18             	mov    0x18(%ecx),%edi
8010350a:	b9 13 00 00 00       	mov    $0x13,%ecx
8010350f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
80103511:	8b 40 18             	mov    0x18(%eax),%eax
80103514:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
8010351b:	be 00 00 00 00       	mov    $0x0,%esi
80103520:	eb 29                	jmp    8010354b <fork+0x8f>
    kfree(np->kstack);
80103522:	83 ec 0c             	sub    $0xc,%esp
80103525:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80103528:	ff 73 08             	pushl  0x8(%ebx)
8010352b:	e8 74 ea ff ff       	call   80101fa4 <kfree>
    np->kstack = 0;
80103530:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
80103537:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
8010353e:	83 c4 10             	add    $0x10,%esp
80103541:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103546:	eb 6d                	jmp    801035b5 <fork+0xf9>
  for(i = 0; i < NOFILE; i++)
80103548:	83 c6 01             	add    $0x1,%esi
8010354b:	83 fe 0f             	cmp    $0xf,%esi
8010354e:	7f 1d                	jg     8010356d <fork+0xb1>
    if(curproc->ofile[i])
80103550:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
80103554:	85 c0                	test   %eax,%eax
80103556:	74 f0                	je     80103548 <fork+0x8c>
      np->ofile[i] = filedup(curproc->ofile[i]);
80103558:	83 ec 0c             	sub    $0xc,%esp
8010355b:	50                   	push   %eax
8010355c:	e8 2d d7 ff ff       	call   80100c8e <filedup>
80103561:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103564:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
80103568:	83 c4 10             	add    $0x10,%esp
8010356b:	eb db                	jmp    80103548 <fork+0x8c>
  np->cwd = idup(curproc->cwd);
8010356d:	83 ec 0c             	sub    $0xc,%esp
80103570:	ff 73 68             	pushl  0x68(%ebx)
80103573:	e8 d9 df ff ff       	call   80101551 <idup>
80103578:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010357b:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
8010357e:	83 c3 6c             	add    $0x6c,%ebx
80103581:	8d 47 6c             	lea    0x6c(%edi),%eax
80103584:	83 c4 0c             	add    $0xc,%esp
80103587:	6a 10                	push   $0x10
80103589:	53                   	push   %ebx
8010358a:	50                   	push   %eax
8010358b:	e8 69 09 00 00       	call   80103ef9 <safestrcpy>
  pid = np->pid;
80103590:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
80103593:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
8010359a:	e8 47 07 00 00       	call   80103ce6 <acquire>
  np->state = RUNNABLE;
8010359f:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
801035a6:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
801035ad:	e8 99 07 00 00       	call   80103d4b <release>
  return pid;
801035b2:	83 c4 10             	add    $0x10,%esp
}
801035b5:	89 d8                	mov    %ebx,%eax
801035b7:	8d 65 f4             	lea    -0xc(%ebp),%esp
801035ba:	5b                   	pop    %ebx
801035bb:	5e                   	pop    %esi
801035bc:	5f                   	pop    %edi
801035bd:	5d                   	pop    %ebp
801035be:	c3                   	ret    
    return -1;
801035bf:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801035c4:	eb ef                	jmp    801035b5 <fork+0xf9>

801035c6 <scheduler>:
{
801035c6:	55                   	push   %ebp
801035c7:	89 e5                	mov    %esp,%ebp
801035c9:	56                   	push   %esi
801035ca:	53                   	push   %ebx
  struct cpu *c = mycpu();
801035cb:	e8 fd fc ff ff       	call   801032cd <mycpu>
801035d0:	89 c6                	mov    %eax,%esi
  c->proc = 0;
801035d2:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
801035d9:	00 00 00 
801035dc:	eb 5a                	jmp    80103638 <scheduler+0x72>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801035de:	83 c3 7c             	add    $0x7c,%ebx
801035e1:	81 fb d4 4c 13 80    	cmp    $0x80134cd4,%ebx
801035e7:	73 3f                	jae    80103628 <scheduler+0x62>
      if(p->state != RUNNABLE)
801035e9:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
801035ed:	75 ef                	jne    801035de <scheduler+0x18>
      c->proc = p;
801035ef:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
801035f5:	83 ec 0c             	sub    $0xc,%esp
801035f8:	53                   	push   %ebx
801035f9:	e8 89 29 00 00       	call   80105f87 <switchuvm>
      p->state = RUNNING;
801035fe:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
80103605:	83 c4 08             	add    $0x8,%esp
80103608:	ff 73 1c             	pushl  0x1c(%ebx)
8010360b:	8d 46 04             	lea    0x4(%esi),%eax
8010360e:	50                   	push   %eax
8010360f:	e8 38 09 00 00       	call   80103f4c <swtch>
      switchkvm();
80103614:	e8 5c 29 00 00       	call   80105f75 <switchkvm>
      c->proc = 0;
80103619:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
80103620:	00 00 00 
80103623:	83 c4 10             	add    $0x10,%esp
80103626:	eb b6                	jmp    801035de <scheduler+0x18>
    release(&ptable.lock);
80103628:	83 ec 0c             	sub    $0xc,%esp
8010362b:	68 a0 2d 13 80       	push   $0x80132da0
80103630:	e8 16 07 00 00       	call   80103d4b <release>
    sti();
80103635:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
80103638:	fb                   	sti    
    acquire(&ptable.lock);
80103639:	83 ec 0c             	sub    $0xc,%esp
8010363c:	68 a0 2d 13 80       	push   $0x80132da0
80103641:	e8 a0 06 00 00       	call   80103ce6 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103646:	83 c4 10             	add    $0x10,%esp
80103649:	bb d4 2d 13 80       	mov    $0x80132dd4,%ebx
8010364e:	eb 91                	jmp    801035e1 <scheduler+0x1b>

80103650 <sched>:
{
80103650:	55                   	push   %ebp
80103651:	89 e5                	mov    %esp,%ebp
80103653:	56                   	push   %esi
80103654:	53                   	push   %ebx
  struct proc *p = myproc();
80103655:	e8 ea fc ff ff       	call   80103344 <myproc>
8010365a:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
8010365c:	83 ec 0c             	sub    $0xc,%esp
8010365f:	68 a0 2d 13 80       	push   $0x80132da0
80103664:	e8 3d 06 00 00       	call   80103ca6 <holding>
80103669:	83 c4 10             	add    $0x10,%esp
8010366c:	85 c0                	test   %eax,%eax
8010366e:	74 4f                	je     801036bf <sched+0x6f>
  if(mycpu()->ncli != 1)
80103670:	e8 58 fc ff ff       	call   801032cd <mycpu>
80103675:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
8010367c:	75 4e                	jne    801036cc <sched+0x7c>
  if(p->state == RUNNING)
8010367e:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
80103682:	74 55                	je     801036d9 <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103684:	9c                   	pushf  
80103685:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103686:	f6 c4 02             	test   $0x2,%ah
80103689:	75 5b                	jne    801036e6 <sched+0x96>
  intena = mycpu()->intena;
8010368b:	e8 3d fc ff ff       	call   801032cd <mycpu>
80103690:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
80103696:	e8 32 fc ff ff       	call   801032cd <mycpu>
8010369b:	83 ec 08             	sub    $0x8,%esp
8010369e:	ff 70 04             	pushl  0x4(%eax)
801036a1:	83 c3 1c             	add    $0x1c,%ebx
801036a4:	53                   	push   %ebx
801036a5:	e8 a2 08 00 00       	call   80103f4c <swtch>
  mycpu()->intena = intena;
801036aa:	e8 1e fc ff ff       	call   801032cd <mycpu>
801036af:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
801036b5:	83 c4 10             	add    $0x10,%esp
801036b8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801036bb:	5b                   	pop    %ebx
801036bc:	5e                   	pop    %esi
801036bd:	5d                   	pop    %ebp
801036be:	c3                   	ret    
    panic("sched ptable.lock");
801036bf:	83 ec 0c             	sub    $0xc,%esp
801036c2:	68 b0 6b 10 80       	push   $0x80106bb0
801036c7:	e8 7c cc ff ff       	call   80100348 <panic>
    panic("sched locks");
801036cc:	83 ec 0c             	sub    $0xc,%esp
801036cf:	68 c2 6b 10 80       	push   $0x80106bc2
801036d4:	e8 6f cc ff ff       	call   80100348 <panic>
    panic("sched running");
801036d9:	83 ec 0c             	sub    $0xc,%esp
801036dc:	68 ce 6b 10 80       	push   $0x80106bce
801036e1:	e8 62 cc ff ff       	call   80100348 <panic>
    panic("sched interruptible");
801036e6:	83 ec 0c             	sub    $0xc,%esp
801036e9:	68 dc 6b 10 80       	push   $0x80106bdc
801036ee:	e8 55 cc ff ff       	call   80100348 <panic>

801036f3 <exit>:
{
801036f3:	55                   	push   %ebp
801036f4:	89 e5                	mov    %esp,%ebp
801036f6:	56                   	push   %esi
801036f7:	53                   	push   %ebx
  struct proc *curproc = myproc();
801036f8:	e8 47 fc ff ff       	call   80103344 <myproc>
  if(curproc == initproc)
801036fd:	39 05 bc a5 10 80    	cmp    %eax,0x8010a5bc
80103703:	74 09                	je     8010370e <exit+0x1b>
80103705:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
80103707:	bb 00 00 00 00       	mov    $0x0,%ebx
8010370c:	eb 10                	jmp    8010371e <exit+0x2b>
    panic("init exiting");
8010370e:	83 ec 0c             	sub    $0xc,%esp
80103711:	68 f0 6b 10 80       	push   $0x80106bf0
80103716:	e8 2d cc ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
8010371b:	83 c3 01             	add    $0x1,%ebx
8010371e:	83 fb 0f             	cmp    $0xf,%ebx
80103721:	7f 1e                	jg     80103741 <exit+0x4e>
    if(curproc->ofile[fd]){
80103723:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
80103727:	85 c0                	test   %eax,%eax
80103729:	74 f0                	je     8010371b <exit+0x28>
      fileclose(curproc->ofile[fd]);
8010372b:	83 ec 0c             	sub    $0xc,%esp
8010372e:	50                   	push   %eax
8010372f:	e8 9f d5 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
80103734:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
8010373b:	00 
8010373c:	83 c4 10             	add    $0x10,%esp
8010373f:	eb da                	jmp    8010371b <exit+0x28>
  begin_op();
80103741:	e8 ae f1 ff ff       	call   801028f4 <begin_op>
  iput(curproc->cwd);
80103746:	83 ec 0c             	sub    $0xc,%esp
80103749:	ff 76 68             	pushl  0x68(%esi)
8010374c:	e8 37 df ff ff       	call   80101688 <iput>
  end_op();
80103751:	e8 18 f2 ff ff       	call   8010296e <end_op>
  curproc->cwd = 0;
80103756:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
8010375d:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
80103764:	e8 7d 05 00 00       	call   80103ce6 <acquire>
  wakeup1(curproc->parent);
80103769:	8b 46 14             	mov    0x14(%esi),%eax
8010376c:	e8 13 fa ff ff       	call   80103184 <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103771:	83 c4 10             	add    $0x10,%esp
80103774:	bb d4 2d 13 80       	mov    $0x80132dd4,%ebx
80103779:	eb 03                	jmp    8010377e <exit+0x8b>
8010377b:	83 c3 7c             	add    $0x7c,%ebx
8010377e:	81 fb d4 4c 13 80    	cmp    $0x80134cd4,%ebx
80103784:	73 1a                	jae    801037a0 <exit+0xad>
    if(p->parent == curproc){
80103786:	39 73 14             	cmp    %esi,0x14(%ebx)
80103789:	75 f0                	jne    8010377b <exit+0x88>
      p->parent = initproc;
8010378b:	a1 bc a5 10 80       	mov    0x8010a5bc,%eax
80103790:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
80103793:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103797:	75 e2                	jne    8010377b <exit+0x88>
        wakeup1(initproc);
80103799:	e8 e6 f9 ff ff       	call   80103184 <wakeup1>
8010379e:	eb db                	jmp    8010377b <exit+0x88>
  curproc->state = ZOMBIE;
801037a0:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
801037a7:	e8 a4 fe ff ff       	call   80103650 <sched>
  panic("zombie exit");
801037ac:	83 ec 0c             	sub    $0xc,%esp
801037af:	68 fd 6b 10 80       	push   $0x80106bfd
801037b4:	e8 8f cb ff ff       	call   80100348 <panic>

801037b9 <yield>:
{
801037b9:	55                   	push   %ebp
801037ba:	89 e5                	mov    %esp,%ebp
801037bc:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801037bf:	68 a0 2d 13 80       	push   $0x80132da0
801037c4:	e8 1d 05 00 00       	call   80103ce6 <acquire>
  myproc()->state = RUNNABLE;
801037c9:	e8 76 fb ff ff       	call   80103344 <myproc>
801037ce:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801037d5:	e8 76 fe ff ff       	call   80103650 <sched>
  release(&ptable.lock);
801037da:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
801037e1:	e8 65 05 00 00       	call   80103d4b <release>
}
801037e6:	83 c4 10             	add    $0x10,%esp
801037e9:	c9                   	leave  
801037ea:	c3                   	ret    

801037eb <sleep>:
{
801037eb:	55                   	push   %ebp
801037ec:	89 e5                	mov    %esp,%ebp
801037ee:	56                   	push   %esi
801037ef:	53                   	push   %ebx
801037f0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
801037f3:	e8 4c fb ff ff       	call   80103344 <myproc>
  if(p == 0)
801037f8:	85 c0                	test   %eax,%eax
801037fa:	74 66                	je     80103862 <sleep+0x77>
801037fc:	89 c6                	mov    %eax,%esi
  if(lk == 0)
801037fe:	85 db                	test   %ebx,%ebx
80103800:	74 6d                	je     8010386f <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
80103802:	81 fb a0 2d 13 80    	cmp    $0x80132da0,%ebx
80103808:	74 18                	je     80103822 <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
8010380a:	83 ec 0c             	sub    $0xc,%esp
8010380d:	68 a0 2d 13 80       	push   $0x80132da0
80103812:	e8 cf 04 00 00       	call   80103ce6 <acquire>
    release(lk);
80103817:	89 1c 24             	mov    %ebx,(%esp)
8010381a:	e8 2c 05 00 00       	call   80103d4b <release>
8010381f:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
80103822:	8b 45 08             	mov    0x8(%ebp),%eax
80103825:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
80103828:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
8010382f:	e8 1c fe ff ff       	call   80103650 <sched>
  p->chan = 0;
80103834:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
8010383b:	81 fb a0 2d 13 80    	cmp    $0x80132da0,%ebx
80103841:	74 18                	je     8010385b <sleep+0x70>
    release(&ptable.lock);
80103843:	83 ec 0c             	sub    $0xc,%esp
80103846:	68 a0 2d 13 80       	push   $0x80132da0
8010384b:	e8 fb 04 00 00       	call   80103d4b <release>
    acquire(lk);
80103850:	89 1c 24             	mov    %ebx,(%esp)
80103853:	e8 8e 04 00 00       	call   80103ce6 <acquire>
80103858:	83 c4 10             	add    $0x10,%esp
}
8010385b:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010385e:	5b                   	pop    %ebx
8010385f:	5e                   	pop    %esi
80103860:	5d                   	pop    %ebp
80103861:	c3                   	ret    
    panic("sleep");
80103862:	83 ec 0c             	sub    $0xc,%esp
80103865:	68 09 6c 10 80       	push   $0x80106c09
8010386a:	e8 d9 ca ff ff       	call   80100348 <panic>
    panic("sleep without lk");
8010386f:	83 ec 0c             	sub    $0xc,%esp
80103872:	68 0f 6c 10 80       	push   $0x80106c0f
80103877:	e8 cc ca ff ff       	call   80100348 <panic>

8010387c <wait>:
{
8010387c:	55                   	push   %ebp
8010387d:	89 e5                	mov    %esp,%ebp
8010387f:	56                   	push   %esi
80103880:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103881:	e8 be fa ff ff       	call   80103344 <myproc>
80103886:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
80103888:	83 ec 0c             	sub    $0xc,%esp
8010388b:	68 a0 2d 13 80       	push   $0x80132da0
80103890:	e8 51 04 00 00       	call   80103ce6 <acquire>
80103895:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
80103898:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010389d:	bb d4 2d 13 80       	mov    $0x80132dd4,%ebx
801038a2:	eb 5b                	jmp    801038ff <wait+0x83>
        pid = p->pid;
801038a4:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
801038a7:	83 ec 0c             	sub    $0xc,%esp
801038aa:	ff 73 08             	pushl  0x8(%ebx)
801038ad:	e8 f2 e6 ff ff       	call   80101fa4 <kfree>
        p->kstack = 0;
801038b2:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
801038b9:	83 c4 04             	add    $0x4,%esp
801038bc:	ff 73 04             	pushl  0x4(%ebx)
801038bf:	e8 73 2a 00 00       	call   80106337 <freevm>
        p->pid = 0;
801038c4:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
801038cb:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
801038d2:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
801038d6:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
801038dd:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
801038e4:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
801038eb:	e8 5b 04 00 00       	call   80103d4b <release>
        return pid;
801038f0:	83 c4 10             	add    $0x10,%esp
}
801038f3:	89 f0                	mov    %esi,%eax
801038f5:	8d 65 f8             	lea    -0x8(%ebp),%esp
801038f8:	5b                   	pop    %ebx
801038f9:	5e                   	pop    %esi
801038fa:	5d                   	pop    %ebp
801038fb:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801038fc:	83 c3 7c             	add    $0x7c,%ebx
801038ff:	81 fb d4 4c 13 80    	cmp    $0x80134cd4,%ebx
80103905:	73 12                	jae    80103919 <wait+0x9d>
      if(p->parent != curproc)
80103907:	39 73 14             	cmp    %esi,0x14(%ebx)
8010390a:	75 f0                	jne    801038fc <wait+0x80>
      if(p->state == ZOMBIE){
8010390c:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103910:	74 92                	je     801038a4 <wait+0x28>
      havekids = 1;
80103912:	b8 01 00 00 00       	mov    $0x1,%eax
80103917:	eb e3                	jmp    801038fc <wait+0x80>
    if(!havekids || curproc->killed){
80103919:	85 c0                	test   %eax,%eax
8010391b:	74 06                	je     80103923 <wait+0xa7>
8010391d:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
80103921:	74 17                	je     8010393a <wait+0xbe>
      release(&ptable.lock);
80103923:	83 ec 0c             	sub    $0xc,%esp
80103926:	68 a0 2d 13 80       	push   $0x80132da0
8010392b:	e8 1b 04 00 00       	call   80103d4b <release>
      return -1;
80103930:	83 c4 10             	add    $0x10,%esp
80103933:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103938:	eb b9                	jmp    801038f3 <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
8010393a:	83 ec 08             	sub    $0x8,%esp
8010393d:	68 a0 2d 13 80       	push   $0x80132da0
80103942:	56                   	push   %esi
80103943:	e8 a3 fe ff ff       	call   801037eb <sleep>
    havekids = 0;
80103948:	83 c4 10             	add    $0x10,%esp
8010394b:	e9 48 ff ff ff       	jmp    80103898 <wait+0x1c>

80103950 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80103950:	55                   	push   %ebp
80103951:	89 e5                	mov    %esp,%ebp
80103953:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
80103956:	68 a0 2d 13 80       	push   $0x80132da0
8010395b:	e8 86 03 00 00       	call   80103ce6 <acquire>
  wakeup1(chan);
80103960:	8b 45 08             	mov    0x8(%ebp),%eax
80103963:	e8 1c f8 ff ff       	call   80103184 <wakeup1>
  release(&ptable.lock);
80103968:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
8010396f:	e8 d7 03 00 00       	call   80103d4b <release>
}
80103974:	83 c4 10             	add    $0x10,%esp
80103977:	c9                   	leave  
80103978:	c3                   	ret    

80103979 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80103979:	55                   	push   %ebp
8010397a:	89 e5                	mov    %esp,%ebp
8010397c:	53                   	push   %ebx
8010397d:	83 ec 10             	sub    $0x10,%esp
80103980:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
80103983:	68 a0 2d 13 80       	push   $0x80132da0
80103988:	e8 59 03 00 00       	call   80103ce6 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010398d:	83 c4 10             	add    $0x10,%esp
80103990:	b8 d4 2d 13 80       	mov    $0x80132dd4,%eax
80103995:	3d d4 4c 13 80       	cmp    $0x80134cd4,%eax
8010399a:	73 3a                	jae    801039d6 <kill+0x5d>
    if(p->pid == pid){
8010399c:	39 58 10             	cmp    %ebx,0x10(%eax)
8010399f:	74 05                	je     801039a6 <kill+0x2d>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039a1:	83 c0 7c             	add    $0x7c,%eax
801039a4:	eb ef                	jmp    80103995 <kill+0x1c>
      p->killed = 1;
801039a6:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
801039ad:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
801039b1:	74 1a                	je     801039cd <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
801039b3:	83 ec 0c             	sub    $0xc,%esp
801039b6:	68 a0 2d 13 80       	push   $0x80132da0
801039bb:	e8 8b 03 00 00       	call   80103d4b <release>
      return 0;
801039c0:	83 c4 10             	add    $0x10,%esp
801039c3:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
801039c8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801039cb:	c9                   	leave  
801039cc:	c3                   	ret    
        p->state = RUNNABLE;
801039cd:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
801039d4:	eb dd                	jmp    801039b3 <kill+0x3a>
  release(&ptable.lock);
801039d6:	83 ec 0c             	sub    $0xc,%esp
801039d9:	68 a0 2d 13 80       	push   $0x80132da0
801039de:	e8 68 03 00 00       	call   80103d4b <release>
  return -1;
801039e3:	83 c4 10             	add    $0x10,%esp
801039e6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801039eb:	eb db                	jmp    801039c8 <kill+0x4f>

801039ed <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
801039ed:	55                   	push   %ebp
801039ee:	89 e5                	mov    %esp,%ebp
801039f0:	56                   	push   %esi
801039f1:	53                   	push   %ebx
801039f2:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039f5:	bb d4 2d 13 80       	mov    $0x80132dd4,%ebx
801039fa:	eb 33                	jmp    80103a2f <procdump+0x42>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
801039fc:	b8 20 6c 10 80       	mov    $0x80106c20,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
80103a01:	8d 53 6c             	lea    0x6c(%ebx),%edx
80103a04:	52                   	push   %edx
80103a05:	50                   	push   %eax
80103a06:	ff 73 10             	pushl  0x10(%ebx)
80103a09:	68 24 6c 10 80       	push   $0x80106c24
80103a0e:	e8 f8 cb ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
80103a13:	83 c4 10             	add    $0x10,%esp
80103a16:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103a1a:	74 39                	je     80103a55 <procdump+0x68>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103a1c:	83 ec 0c             	sub    $0xc,%esp
80103a1f:	68 9b 6f 10 80       	push   $0x80106f9b
80103a24:	e8 e2 cb ff ff       	call   8010060b <cprintf>
80103a29:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103a2c:	83 c3 7c             	add    $0x7c,%ebx
80103a2f:	81 fb d4 4c 13 80    	cmp    $0x80134cd4,%ebx
80103a35:	73 61                	jae    80103a98 <procdump+0xab>
    if(p->state == UNUSED)
80103a37:	8b 43 0c             	mov    0xc(%ebx),%eax
80103a3a:	85 c0                	test   %eax,%eax
80103a3c:	74 ee                	je     80103a2c <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103a3e:	83 f8 05             	cmp    $0x5,%eax
80103a41:	77 b9                	ja     801039fc <procdump+0xf>
80103a43:	8b 04 85 80 6c 10 80 	mov    -0x7fef9380(,%eax,4),%eax
80103a4a:	85 c0                	test   %eax,%eax
80103a4c:	75 b3                	jne    80103a01 <procdump+0x14>
      state = "???";
80103a4e:	b8 20 6c 10 80       	mov    $0x80106c20,%eax
80103a53:	eb ac                	jmp    80103a01 <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80103a55:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103a58:	8b 40 0c             	mov    0xc(%eax),%eax
80103a5b:	83 c0 08             	add    $0x8,%eax
80103a5e:	83 ec 08             	sub    $0x8,%esp
80103a61:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103a64:	52                   	push   %edx
80103a65:	50                   	push   %eax
80103a66:	e8 5a 01 00 00       	call   80103bc5 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103a6b:	83 c4 10             	add    $0x10,%esp
80103a6e:	be 00 00 00 00       	mov    $0x0,%esi
80103a73:	eb 14                	jmp    80103a89 <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103a75:	83 ec 08             	sub    $0x8,%esp
80103a78:	50                   	push   %eax
80103a79:	68 61 66 10 80       	push   $0x80106661
80103a7e:	e8 88 cb ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103a83:	83 c6 01             	add    $0x1,%esi
80103a86:	83 c4 10             	add    $0x10,%esp
80103a89:	83 fe 09             	cmp    $0x9,%esi
80103a8c:	7f 8e                	jg     80103a1c <procdump+0x2f>
80103a8e:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103a92:	85 c0                	test   %eax,%eax
80103a94:	75 df                	jne    80103a75 <procdump+0x88>
80103a96:	eb 84                	jmp    80103a1c <procdump+0x2f>
  }
80103a98:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a9b:	5b                   	pop    %ebx
80103a9c:	5e                   	pop    %esi
80103a9d:	5d                   	pop    %ebp
80103a9e:	c3                   	ret    

80103a9f <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103a9f:	55                   	push   %ebp
80103aa0:	89 e5                	mov    %esp,%ebp
80103aa2:	53                   	push   %ebx
80103aa3:	83 ec 0c             	sub    $0xc,%esp
80103aa6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103aa9:	68 98 6c 10 80       	push   $0x80106c98
80103aae:	8d 43 04             	lea    0x4(%ebx),%eax
80103ab1:	50                   	push   %eax
80103ab2:	e8 f3 00 00 00       	call   80103baa <initlock>
  lk->name = name;
80103ab7:	8b 45 0c             	mov    0xc(%ebp),%eax
80103aba:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103abd:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103ac3:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103aca:	83 c4 10             	add    $0x10,%esp
80103acd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103ad0:	c9                   	leave  
80103ad1:	c3                   	ret    

80103ad2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103ad2:	55                   	push   %ebp
80103ad3:	89 e5                	mov    %esp,%ebp
80103ad5:	56                   	push   %esi
80103ad6:	53                   	push   %ebx
80103ad7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103ada:	8d 73 04             	lea    0x4(%ebx),%esi
80103add:	83 ec 0c             	sub    $0xc,%esp
80103ae0:	56                   	push   %esi
80103ae1:	e8 00 02 00 00       	call   80103ce6 <acquire>
  while (lk->locked) {
80103ae6:	83 c4 10             	add    $0x10,%esp
80103ae9:	eb 0d                	jmp    80103af8 <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103aeb:	83 ec 08             	sub    $0x8,%esp
80103aee:	56                   	push   %esi
80103aef:	53                   	push   %ebx
80103af0:	e8 f6 fc ff ff       	call   801037eb <sleep>
80103af5:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103af8:	83 3b 00             	cmpl   $0x0,(%ebx)
80103afb:	75 ee                	jne    80103aeb <acquiresleep+0x19>
  }
  lk->locked = 1;
80103afd:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103b03:	e8 3c f8 ff ff       	call   80103344 <myproc>
80103b08:	8b 40 10             	mov    0x10(%eax),%eax
80103b0b:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103b0e:	83 ec 0c             	sub    $0xc,%esp
80103b11:	56                   	push   %esi
80103b12:	e8 34 02 00 00       	call   80103d4b <release>
}
80103b17:	83 c4 10             	add    $0x10,%esp
80103b1a:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b1d:	5b                   	pop    %ebx
80103b1e:	5e                   	pop    %esi
80103b1f:	5d                   	pop    %ebp
80103b20:	c3                   	ret    

80103b21 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103b21:	55                   	push   %ebp
80103b22:	89 e5                	mov    %esp,%ebp
80103b24:	56                   	push   %esi
80103b25:	53                   	push   %ebx
80103b26:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103b29:	8d 73 04             	lea    0x4(%ebx),%esi
80103b2c:	83 ec 0c             	sub    $0xc,%esp
80103b2f:	56                   	push   %esi
80103b30:	e8 b1 01 00 00       	call   80103ce6 <acquire>
  lk->locked = 0;
80103b35:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103b3b:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103b42:	89 1c 24             	mov    %ebx,(%esp)
80103b45:	e8 06 fe ff ff       	call   80103950 <wakeup>
  release(&lk->lk);
80103b4a:	89 34 24             	mov    %esi,(%esp)
80103b4d:	e8 f9 01 00 00       	call   80103d4b <release>
}
80103b52:	83 c4 10             	add    $0x10,%esp
80103b55:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b58:	5b                   	pop    %ebx
80103b59:	5e                   	pop    %esi
80103b5a:	5d                   	pop    %ebp
80103b5b:	c3                   	ret    

80103b5c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103b5c:	55                   	push   %ebp
80103b5d:	89 e5                	mov    %esp,%ebp
80103b5f:	56                   	push   %esi
80103b60:	53                   	push   %ebx
80103b61:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103b64:	8d 73 04             	lea    0x4(%ebx),%esi
80103b67:	83 ec 0c             	sub    $0xc,%esp
80103b6a:	56                   	push   %esi
80103b6b:	e8 76 01 00 00       	call   80103ce6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103b70:	83 c4 10             	add    $0x10,%esp
80103b73:	83 3b 00             	cmpl   $0x0,(%ebx)
80103b76:	75 17                	jne    80103b8f <holdingsleep+0x33>
80103b78:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103b7d:	83 ec 0c             	sub    $0xc,%esp
80103b80:	56                   	push   %esi
80103b81:	e8 c5 01 00 00       	call   80103d4b <release>
  return r;
}
80103b86:	89 d8                	mov    %ebx,%eax
80103b88:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b8b:	5b                   	pop    %ebx
80103b8c:	5e                   	pop    %esi
80103b8d:	5d                   	pop    %ebp
80103b8e:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103b8f:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103b92:	e8 ad f7 ff ff       	call   80103344 <myproc>
80103b97:	3b 58 10             	cmp    0x10(%eax),%ebx
80103b9a:	74 07                	je     80103ba3 <holdingsleep+0x47>
80103b9c:	bb 00 00 00 00       	mov    $0x0,%ebx
80103ba1:	eb da                	jmp    80103b7d <holdingsleep+0x21>
80103ba3:	bb 01 00 00 00       	mov    $0x1,%ebx
80103ba8:	eb d3                	jmp    80103b7d <holdingsleep+0x21>

80103baa <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103baa:	55                   	push   %ebp
80103bab:	89 e5                	mov    %esp,%ebp
80103bad:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103bb0:	8b 55 0c             	mov    0xc(%ebp),%edx
80103bb3:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103bb6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103bbc:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103bc3:	5d                   	pop    %ebp
80103bc4:	c3                   	ret    

80103bc5 <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103bc5:	55                   	push   %ebp
80103bc6:	89 e5                	mov    %esp,%ebp
80103bc8:	53                   	push   %ebx
80103bc9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103bcc:	8b 45 08             	mov    0x8(%ebp),%eax
80103bcf:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103bd2:	b8 00 00 00 00       	mov    $0x0,%eax
80103bd7:	83 f8 09             	cmp    $0x9,%eax
80103bda:	7f 25                	jg     80103c01 <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103bdc:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103be2:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103be8:	77 17                	ja     80103c01 <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103bea:	8b 5a 04             	mov    0x4(%edx),%ebx
80103bed:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103bf0:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103bf2:	83 c0 01             	add    $0x1,%eax
80103bf5:	eb e0                	jmp    80103bd7 <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103bf7:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103bfe:	83 c0 01             	add    $0x1,%eax
80103c01:	83 f8 09             	cmp    $0x9,%eax
80103c04:	7e f1                	jle    80103bf7 <getcallerpcs+0x32>
}
80103c06:	5b                   	pop    %ebx
80103c07:	5d                   	pop    %ebp
80103c08:	c3                   	ret    

80103c09 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103c09:	55                   	push   %ebp
80103c0a:	89 e5                	mov    %esp,%ebp
80103c0c:	53                   	push   %ebx
80103c0d:	83 ec 04             	sub    $0x4,%esp
80103c10:	9c                   	pushf  
80103c11:	5b                   	pop    %ebx
  asm volatile("cli");
80103c12:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103c13:	e8 b5 f6 ff ff       	call   801032cd <mycpu>
80103c18:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103c1f:	74 12                	je     80103c33 <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103c21:	e8 a7 f6 ff ff       	call   801032cd <mycpu>
80103c26:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103c2d:	83 c4 04             	add    $0x4,%esp
80103c30:	5b                   	pop    %ebx
80103c31:	5d                   	pop    %ebp
80103c32:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103c33:	e8 95 f6 ff ff       	call   801032cd <mycpu>
80103c38:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103c3e:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103c44:	eb db                	jmp    80103c21 <pushcli+0x18>

80103c46 <popcli>:

void
popcli(void)
{
80103c46:	55                   	push   %ebp
80103c47:	89 e5                	mov    %esp,%ebp
80103c49:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103c4c:	9c                   	pushf  
80103c4d:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103c4e:	f6 c4 02             	test   $0x2,%ah
80103c51:	75 28                	jne    80103c7b <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103c53:	e8 75 f6 ff ff       	call   801032cd <mycpu>
80103c58:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103c5e:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103c61:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103c67:	85 d2                	test   %edx,%edx
80103c69:	78 1d                	js     80103c88 <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103c6b:	e8 5d f6 ff ff       	call   801032cd <mycpu>
80103c70:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103c77:	74 1c                	je     80103c95 <popcli+0x4f>
    sti();
}
80103c79:	c9                   	leave  
80103c7a:	c3                   	ret    
    panic("popcli - interruptible");
80103c7b:	83 ec 0c             	sub    $0xc,%esp
80103c7e:	68 a3 6c 10 80       	push   $0x80106ca3
80103c83:	e8 c0 c6 ff ff       	call   80100348 <panic>
    panic("popcli");
80103c88:	83 ec 0c             	sub    $0xc,%esp
80103c8b:	68 ba 6c 10 80       	push   $0x80106cba
80103c90:	e8 b3 c6 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103c95:	e8 33 f6 ff ff       	call   801032cd <mycpu>
80103c9a:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103ca1:	74 d6                	je     80103c79 <popcli+0x33>
  asm volatile("sti");
80103ca3:	fb                   	sti    
}
80103ca4:	eb d3                	jmp    80103c79 <popcli+0x33>

80103ca6 <holding>:
{
80103ca6:	55                   	push   %ebp
80103ca7:	89 e5                	mov    %esp,%ebp
80103ca9:	53                   	push   %ebx
80103caa:	83 ec 04             	sub    $0x4,%esp
80103cad:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103cb0:	e8 54 ff ff ff       	call   80103c09 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103cb5:	83 3b 00             	cmpl   $0x0,(%ebx)
80103cb8:	75 12                	jne    80103ccc <holding+0x26>
80103cba:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103cbf:	e8 82 ff ff ff       	call   80103c46 <popcli>
}
80103cc4:	89 d8                	mov    %ebx,%eax
80103cc6:	83 c4 04             	add    $0x4,%esp
80103cc9:	5b                   	pop    %ebx
80103cca:	5d                   	pop    %ebp
80103ccb:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103ccc:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103ccf:	e8 f9 f5 ff ff       	call   801032cd <mycpu>
80103cd4:	39 c3                	cmp    %eax,%ebx
80103cd6:	74 07                	je     80103cdf <holding+0x39>
80103cd8:	bb 00 00 00 00       	mov    $0x0,%ebx
80103cdd:	eb e0                	jmp    80103cbf <holding+0x19>
80103cdf:	bb 01 00 00 00       	mov    $0x1,%ebx
80103ce4:	eb d9                	jmp    80103cbf <holding+0x19>

80103ce6 <acquire>:
{
80103ce6:	55                   	push   %ebp
80103ce7:	89 e5                	mov    %esp,%ebp
80103ce9:	53                   	push   %ebx
80103cea:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103ced:	e8 17 ff ff ff       	call   80103c09 <pushcli>
  if(holding(lk))
80103cf2:	83 ec 0c             	sub    $0xc,%esp
80103cf5:	ff 75 08             	pushl  0x8(%ebp)
80103cf8:	e8 a9 ff ff ff       	call   80103ca6 <holding>
80103cfd:	83 c4 10             	add    $0x10,%esp
80103d00:	85 c0                	test   %eax,%eax
80103d02:	75 3a                	jne    80103d3e <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103d04:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103d07:	b8 01 00 00 00       	mov    $0x1,%eax
80103d0c:	f0 87 02             	lock xchg %eax,(%edx)
80103d0f:	85 c0                	test   %eax,%eax
80103d11:	75 f1                	jne    80103d04 <acquire+0x1e>
  __sync_synchronize();
80103d13:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103d18:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103d1b:	e8 ad f5 ff ff       	call   801032cd <mycpu>
80103d20:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103d23:	8b 45 08             	mov    0x8(%ebp),%eax
80103d26:	83 c0 0c             	add    $0xc,%eax
80103d29:	83 ec 08             	sub    $0x8,%esp
80103d2c:	50                   	push   %eax
80103d2d:	8d 45 08             	lea    0x8(%ebp),%eax
80103d30:	50                   	push   %eax
80103d31:	e8 8f fe ff ff       	call   80103bc5 <getcallerpcs>
}
80103d36:	83 c4 10             	add    $0x10,%esp
80103d39:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103d3c:	c9                   	leave  
80103d3d:	c3                   	ret    
    panic("acquire");
80103d3e:	83 ec 0c             	sub    $0xc,%esp
80103d41:	68 c1 6c 10 80       	push   $0x80106cc1
80103d46:	e8 fd c5 ff ff       	call   80100348 <panic>

80103d4b <release>:
{
80103d4b:	55                   	push   %ebp
80103d4c:	89 e5                	mov    %esp,%ebp
80103d4e:	53                   	push   %ebx
80103d4f:	83 ec 10             	sub    $0x10,%esp
80103d52:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103d55:	53                   	push   %ebx
80103d56:	e8 4b ff ff ff       	call   80103ca6 <holding>
80103d5b:	83 c4 10             	add    $0x10,%esp
80103d5e:	85 c0                	test   %eax,%eax
80103d60:	74 23                	je     80103d85 <release+0x3a>
  lk->pcs[0] = 0;
80103d62:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103d69:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103d70:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103d75:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103d7b:	e8 c6 fe ff ff       	call   80103c46 <popcli>
}
80103d80:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103d83:	c9                   	leave  
80103d84:	c3                   	ret    
    panic("release");
80103d85:	83 ec 0c             	sub    $0xc,%esp
80103d88:	68 c9 6c 10 80       	push   $0x80106cc9
80103d8d:	e8 b6 c5 ff ff       	call   80100348 <panic>

80103d92 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103d92:	55                   	push   %ebp
80103d93:	89 e5                	mov    %esp,%ebp
80103d95:	57                   	push   %edi
80103d96:	53                   	push   %ebx
80103d97:	8b 55 08             	mov    0x8(%ebp),%edx
80103d9a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103d9d:	f6 c2 03             	test   $0x3,%dl
80103da0:	75 05                	jne    80103da7 <memset+0x15>
80103da2:	f6 c1 03             	test   $0x3,%cl
80103da5:	74 0e                	je     80103db5 <memset+0x23>
  asm volatile("cld; rep stosb" :
80103da7:	89 d7                	mov    %edx,%edi
80103da9:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dac:	fc                   	cld    
80103dad:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103daf:	89 d0                	mov    %edx,%eax
80103db1:	5b                   	pop    %ebx
80103db2:	5f                   	pop    %edi
80103db3:	5d                   	pop    %ebp
80103db4:	c3                   	ret    
    c &= 0xFF;
80103db5:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103db9:	c1 e9 02             	shr    $0x2,%ecx
80103dbc:	89 f8                	mov    %edi,%eax
80103dbe:	c1 e0 18             	shl    $0x18,%eax
80103dc1:	89 fb                	mov    %edi,%ebx
80103dc3:	c1 e3 10             	shl    $0x10,%ebx
80103dc6:	09 d8                	or     %ebx,%eax
80103dc8:	89 fb                	mov    %edi,%ebx
80103dca:	c1 e3 08             	shl    $0x8,%ebx
80103dcd:	09 d8                	or     %ebx,%eax
80103dcf:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103dd1:	89 d7                	mov    %edx,%edi
80103dd3:	fc                   	cld    
80103dd4:	f3 ab                	rep stos %eax,%es:(%edi)
80103dd6:	eb d7                	jmp    80103daf <memset+0x1d>

80103dd8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103dd8:	55                   	push   %ebp
80103dd9:	89 e5                	mov    %esp,%ebp
80103ddb:	56                   	push   %esi
80103ddc:	53                   	push   %ebx
80103ddd:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103de0:	8b 55 0c             	mov    0xc(%ebp),%edx
80103de3:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103de6:	8d 70 ff             	lea    -0x1(%eax),%esi
80103de9:	85 c0                	test   %eax,%eax
80103deb:	74 1c                	je     80103e09 <memcmp+0x31>
    if(*s1 != *s2)
80103ded:	0f b6 01             	movzbl (%ecx),%eax
80103df0:	0f b6 1a             	movzbl (%edx),%ebx
80103df3:	38 d8                	cmp    %bl,%al
80103df5:	75 0a                	jne    80103e01 <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103df7:	83 c1 01             	add    $0x1,%ecx
80103dfa:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103dfd:	89 f0                	mov    %esi,%eax
80103dff:	eb e5                	jmp    80103de6 <memcmp+0xe>
      return *s1 - *s2;
80103e01:	0f b6 c0             	movzbl %al,%eax
80103e04:	0f b6 db             	movzbl %bl,%ebx
80103e07:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103e09:	5b                   	pop    %ebx
80103e0a:	5e                   	pop    %esi
80103e0b:	5d                   	pop    %ebp
80103e0c:	c3                   	ret    

80103e0d <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103e0d:	55                   	push   %ebp
80103e0e:	89 e5                	mov    %esp,%ebp
80103e10:	56                   	push   %esi
80103e11:	53                   	push   %ebx
80103e12:	8b 45 08             	mov    0x8(%ebp),%eax
80103e15:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103e18:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103e1b:	39 c1                	cmp    %eax,%ecx
80103e1d:	73 3a                	jae    80103e59 <memmove+0x4c>
80103e1f:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103e22:	39 c3                	cmp    %eax,%ebx
80103e24:	76 37                	jbe    80103e5d <memmove+0x50>
    s += n;
    d += n;
80103e26:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103e29:	eb 0d                	jmp    80103e38 <memmove+0x2b>
      *--d = *--s;
80103e2b:	83 eb 01             	sub    $0x1,%ebx
80103e2e:	83 e9 01             	sub    $0x1,%ecx
80103e31:	0f b6 13             	movzbl (%ebx),%edx
80103e34:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103e36:	89 f2                	mov    %esi,%edx
80103e38:	8d 72 ff             	lea    -0x1(%edx),%esi
80103e3b:	85 d2                	test   %edx,%edx
80103e3d:	75 ec                	jne    80103e2b <memmove+0x1e>
80103e3f:	eb 14                	jmp    80103e55 <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103e41:	0f b6 11             	movzbl (%ecx),%edx
80103e44:	88 13                	mov    %dl,(%ebx)
80103e46:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103e49:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103e4c:	89 f2                	mov    %esi,%edx
80103e4e:	8d 72 ff             	lea    -0x1(%edx),%esi
80103e51:	85 d2                	test   %edx,%edx
80103e53:	75 ec                	jne    80103e41 <memmove+0x34>

  return dst;
}
80103e55:	5b                   	pop    %ebx
80103e56:	5e                   	pop    %esi
80103e57:	5d                   	pop    %ebp
80103e58:	c3                   	ret    
80103e59:	89 c3                	mov    %eax,%ebx
80103e5b:	eb f1                	jmp    80103e4e <memmove+0x41>
80103e5d:	89 c3                	mov    %eax,%ebx
80103e5f:	eb ed                	jmp    80103e4e <memmove+0x41>

80103e61 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103e61:	55                   	push   %ebp
80103e62:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80103e64:	ff 75 10             	pushl  0x10(%ebp)
80103e67:	ff 75 0c             	pushl  0xc(%ebp)
80103e6a:	ff 75 08             	pushl  0x8(%ebp)
80103e6d:	e8 9b ff ff ff       	call   80103e0d <memmove>
}
80103e72:	c9                   	leave  
80103e73:	c3                   	ret    

80103e74 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103e74:	55                   	push   %ebp
80103e75:	89 e5                	mov    %esp,%ebp
80103e77:	53                   	push   %ebx
80103e78:	8b 55 08             	mov    0x8(%ebp),%edx
80103e7b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103e7e:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103e81:	eb 09                	jmp    80103e8c <strncmp+0x18>
    n--, p++, q++;
80103e83:	83 e8 01             	sub    $0x1,%eax
80103e86:	83 c2 01             	add    $0x1,%edx
80103e89:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103e8c:	85 c0                	test   %eax,%eax
80103e8e:	74 0b                	je     80103e9b <strncmp+0x27>
80103e90:	0f b6 1a             	movzbl (%edx),%ebx
80103e93:	84 db                	test   %bl,%bl
80103e95:	74 04                	je     80103e9b <strncmp+0x27>
80103e97:	3a 19                	cmp    (%ecx),%bl
80103e99:	74 e8                	je     80103e83 <strncmp+0xf>
  if(n == 0)
80103e9b:	85 c0                	test   %eax,%eax
80103e9d:	74 0b                	je     80103eaa <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80103e9f:	0f b6 02             	movzbl (%edx),%eax
80103ea2:	0f b6 11             	movzbl (%ecx),%edx
80103ea5:	29 d0                	sub    %edx,%eax
}
80103ea7:	5b                   	pop    %ebx
80103ea8:	5d                   	pop    %ebp
80103ea9:	c3                   	ret    
    return 0;
80103eaa:	b8 00 00 00 00       	mov    $0x0,%eax
80103eaf:	eb f6                	jmp    80103ea7 <strncmp+0x33>

80103eb1 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103eb1:	55                   	push   %ebp
80103eb2:	89 e5                	mov    %esp,%ebp
80103eb4:	57                   	push   %edi
80103eb5:	56                   	push   %esi
80103eb6:	53                   	push   %ebx
80103eb7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103eba:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103ebd:	8b 45 08             	mov    0x8(%ebp),%eax
80103ec0:	eb 04                	jmp    80103ec6 <strncpy+0x15>
80103ec2:	89 fb                	mov    %edi,%ebx
80103ec4:	89 f0                	mov    %esi,%eax
80103ec6:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103ec9:	85 c9                	test   %ecx,%ecx
80103ecb:	7e 1d                	jle    80103eea <strncpy+0x39>
80103ecd:	8d 7b 01             	lea    0x1(%ebx),%edi
80103ed0:	8d 70 01             	lea    0x1(%eax),%esi
80103ed3:	0f b6 1b             	movzbl (%ebx),%ebx
80103ed6:	88 18                	mov    %bl,(%eax)
80103ed8:	89 d1                	mov    %edx,%ecx
80103eda:	84 db                	test   %bl,%bl
80103edc:	75 e4                	jne    80103ec2 <strncpy+0x11>
80103ede:	89 f0                	mov    %esi,%eax
80103ee0:	eb 08                	jmp    80103eea <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80103ee2:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80103ee5:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80103ee7:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80103eea:	8d 4a ff             	lea    -0x1(%edx),%ecx
80103eed:	85 d2                	test   %edx,%edx
80103eef:	7f f1                	jg     80103ee2 <strncpy+0x31>
  return os;
}
80103ef1:	8b 45 08             	mov    0x8(%ebp),%eax
80103ef4:	5b                   	pop    %ebx
80103ef5:	5e                   	pop    %esi
80103ef6:	5f                   	pop    %edi
80103ef7:	5d                   	pop    %ebp
80103ef8:	c3                   	ret    

80103ef9 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80103ef9:	55                   	push   %ebp
80103efa:	89 e5                	mov    %esp,%ebp
80103efc:	57                   	push   %edi
80103efd:	56                   	push   %esi
80103efe:	53                   	push   %ebx
80103eff:	8b 45 08             	mov    0x8(%ebp),%eax
80103f02:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103f05:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
80103f08:	85 d2                	test   %edx,%edx
80103f0a:	7e 23                	jle    80103f2f <safestrcpy+0x36>
80103f0c:	89 c1                	mov    %eax,%ecx
80103f0e:	eb 04                	jmp    80103f14 <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80103f10:	89 fb                	mov    %edi,%ebx
80103f12:	89 f1                	mov    %esi,%ecx
80103f14:	83 ea 01             	sub    $0x1,%edx
80103f17:	85 d2                	test   %edx,%edx
80103f19:	7e 11                	jle    80103f2c <safestrcpy+0x33>
80103f1b:	8d 7b 01             	lea    0x1(%ebx),%edi
80103f1e:	8d 71 01             	lea    0x1(%ecx),%esi
80103f21:	0f b6 1b             	movzbl (%ebx),%ebx
80103f24:	88 19                	mov    %bl,(%ecx)
80103f26:	84 db                	test   %bl,%bl
80103f28:	75 e6                	jne    80103f10 <safestrcpy+0x17>
80103f2a:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80103f2c:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80103f2f:	5b                   	pop    %ebx
80103f30:	5e                   	pop    %esi
80103f31:	5f                   	pop    %edi
80103f32:	5d                   	pop    %ebp
80103f33:	c3                   	ret    

80103f34 <strlen>:

int
strlen(const char *s)
{
80103f34:	55                   	push   %ebp
80103f35:	89 e5                	mov    %esp,%ebp
80103f37:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80103f3a:	b8 00 00 00 00       	mov    $0x0,%eax
80103f3f:	eb 03                	jmp    80103f44 <strlen+0x10>
80103f41:	83 c0 01             	add    $0x1,%eax
80103f44:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80103f48:	75 f7                	jne    80103f41 <strlen+0xd>
    ;
  return n;
}
80103f4a:	5d                   	pop    %ebp
80103f4b:	c3                   	ret    

80103f4c <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80103f4c:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80103f50:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80103f54:	55                   	push   %ebp
  pushl %ebx
80103f55:	53                   	push   %ebx
  pushl %esi
80103f56:	56                   	push   %esi
  pushl %edi
80103f57:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80103f58:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80103f5a:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80103f5c:	5f                   	pop    %edi
  popl %esi
80103f5d:	5e                   	pop    %esi
  popl %ebx
80103f5e:	5b                   	pop    %ebx
  popl %ebp
80103f5f:	5d                   	pop    %ebp
  ret
80103f60:	c3                   	ret    

80103f61 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80103f61:	55                   	push   %ebp
80103f62:	89 e5                	mov    %esp,%ebp
80103f64:	53                   	push   %ebx
80103f65:	83 ec 04             	sub    $0x4,%esp
80103f68:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80103f6b:	e8 d4 f3 ff ff       	call   80103344 <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80103f70:	8b 00                	mov    (%eax),%eax
80103f72:	39 d8                	cmp    %ebx,%eax
80103f74:	76 19                	jbe    80103f8f <fetchint+0x2e>
80103f76:	8d 53 04             	lea    0x4(%ebx),%edx
80103f79:	39 d0                	cmp    %edx,%eax
80103f7b:	72 19                	jb     80103f96 <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80103f7d:	8b 13                	mov    (%ebx),%edx
80103f7f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f82:	89 10                	mov    %edx,(%eax)
  return 0;
80103f84:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103f89:	83 c4 04             	add    $0x4,%esp
80103f8c:	5b                   	pop    %ebx
80103f8d:	5d                   	pop    %ebp
80103f8e:	c3                   	ret    
    return -1;
80103f8f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f94:	eb f3                	jmp    80103f89 <fetchint+0x28>
80103f96:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f9b:	eb ec                	jmp    80103f89 <fetchint+0x28>

80103f9d <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80103f9d:	55                   	push   %ebp
80103f9e:	89 e5                	mov    %esp,%ebp
80103fa0:	53                   	push   %ebx
80103fa1:	83 ec 04             	sub    $0x4,%esp
80103fa4:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
80103fa7:	e8 98 f3 ff ff       	call   80103344 <myproc>

  if(addr >= curproc->sz)
80103fac:	39 18                	cmp    %ebx,(%eax)
80103fae:	76 26                	jbe    80103fd6 <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
80103fb0:	8b 55 0c             	mov    0xc(%ebp),%edx
80103fb3:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
80103fb5:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
80103fb7:	89 d8                	mov    %ebx,%eax
80103fb9:	39 d0                	cmp    %edx,%eax
80103fbb:	73 0e                	jae    80103fcb <fetchstr+0x2e>
    if(*s == 0)
80103fbd:	80 38 00             	cmpb   $0x0,(%eax)
80103fc0:	74 05                	je     80103fc7 <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
80103fc2:	83 c0 01             	add    $0x1,%eax
80103fc5:	eb f2                	jmp    80103fb9 <fetchstr+0x1c>
      return s - *pp;
80103fc7:	29 d8                	sub    %ebx,%eax
80103fc9:	eb 05                	jmp    80103fd0 <fetchstr+0x33>
  }
  return -1;
80103fcb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103fd0:	83 c4 04             	add    $0x4,%esp
80103fd3:	5b                   	pop    %ebx
80103fd4:	5d                   	pop    %ebp
80103fd5:	c3                   	ret    
    return -1;
80103fd6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fdb:	eb f3                	jmp    80103fd0 <fetchstr+0x33>

80103fdd <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80103fdd:	55                   	push   %ebp
80103fde:	89 e5                	mov    %esp,%ebp
80103fe0:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80103fe3:	e8 5c f3 ff ff       	call   80103344 <myproc>
80103fe8:	8b 50 18             	mov    0x18(%eax),%edx
80103feb:	8b 45 08             	mov    0x8(%ebp),%eax
80103fee:	c1 e0 02             	shl    $0x2,%eax
80103ff1:	03 42 44             	add    0x44(%edx),%eax
80103ff4:	83 ec 08             	sub    $0x8,%esp
80103ff7:	ff 75 0c             	pushl  0xc(%ebp)
80103ffa:	83 c0 04             	add    $0x4,%eax
80103ffd:	50                   	push   %eax
80103ffe:	e8 5e ff ff ff       	call   80103f61 <fetchint>
}
80104003:	c9                   	leave  
80104004:	c3                   	ret    

80104005 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80104005:	55                   	push   %ebp
80104006:	89 e5                	mov    %esp,%ebp
80104008:	56                   	push   %esi
80104009:	53                   	push   %ebx
8010400a:	83 ec 10             	sub    $0x10,%esp
8010400d:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
80104010:	e8 2f f3 ff ff       	call   80103344 <myproc>
80104015:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
80104017:	83 ec 08             	sub    $0x8,%esp
8010401a:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010401d:	50                   	push   %eax
8010401e:	ff 75 08             	pushl  0x8(%ebp)
80104021:	e8 b7 ff ff ff       	call   80103fdd <argint>
80104026:	83 c4 10             	add    $0x10,%esp
80104029:	85 c0                	test   %eax,%eax
8010402b:	78 24                	js     80104051 <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
8010402d:	85 db                	test   %ebx,%ebx
8010402f:	78 27                	js     80104058 <argptr+0x53>
80104031:	8b 16                	mov    (%esi),%edx
80104033:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104036:	39 c2                	cmp    %eax,%edx
80104038:	76 25                	jbe    8010405f <argptr+0x5a>
8010403a:	01 c3                	add    %eax,%ebx
8010403c:	39 da                	cmp    %ebx,%edx
8010403e:	72 26                	jb     80104066 <argptr+0x61>
    return -1;
  *pp = (char*)i;
80104040:	8b 55 0c             	mov    0xc(%ebp),%edx
80104043:	89 02                	mov    %eax,(%edx)
  return 0;
80104045:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010404a:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010404d:	5b                   	pop    %ebx
8010404e:	5e                   	pop    %esi
8010404f:	5d                   	pop    %ebp
80104050:	c3                   	ret    
    return -1;
80104051:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104056:	eb f2                	jmp    8010404a <argptr+0x45>
    return -1;
80104058:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010405d:	eb eb                	jmp    8010404a <argptr+0x45>
8010405f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104064:	eb e4                	jmp    8010404a <argptr+0x45>
80104066:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010406b:	eb dd                	jmp    8010404a <argptr+0x45>

8010406d <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
8010406d:	55                   	push   %ebp
8010406e:	89 e5                	mov    %esp,%ebp
80104070:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
80104073:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104076:	50                   	push   %eax
80104077:	ff 75 08             	pushl  0x8(%ebp)
8010407a:	e8 5e ff ff ff       	call   80103fdd <argint>
8010407f:	83 c4 10             	add    $0x10,%esp
80104082:	85 c0                	test   %eax,%eax
80104084:	78 13                	js     80104099 <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
80104086:	83 ec 08             	sub    $0x8,%esp
80104089:	ff 75 0c             	pushl  0xc(%ebp)
8010408c:	ff 75 f4             	pushl  -0xc(%ebp)
8010408f:	e8 09 ff ff ff       	call   80103f9d <fetchstr>
80104094:	83 c4 10             	add    $0x10,%esp
}
80104097:	c9                   	leave  
80104098:	c3                   	ret    
    return -1;
80104099:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010409e:	eb f7                	jmp    80104097 <argstr+0x2a>

801040a0 <syscall>:
[SYS_dump_physmem]   sys_dump_physmem,
};

void
syscall(void)
{
801040a0:	55                   	push   %ebp
801040a1:	89 e5                	mov    %esp,%ebp
801040a3:	53                   	push   %ebx
801040a4:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
801040a7:	e8 98 f2 ff ff       	call   80103344 <myproc>
801040ac:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
801040ae:	8b 40 18             	mov    0x18(%eax),%eax
801040b1:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
801040b4:	8d 50 ff             	lea    -0x1(%eax),%edx
801040b7:	83 fa 15             	cmp    $0x15,%edx
801040ba:	77 18                	ja     801040d4 <syscall+0x34>
801040bc:	8b 14 85 00 6d 10 80 	mov    -0x7fef9300(,%eax,4),%edx
801040c3:	85 d2                	test   %edx,%edx
801040c5:	74 0d                	je     801040d4 <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
801040c7:	ff d2                	call   *%edx
801040c9:	8b 53 18             	mov    0x18(%ebx),%edx
801040cc:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
801040cf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801040d2:	c9                   	leave  
801040d3:	c3                   	ret    
            curproc->pid, curproc->name, num);
801040d4:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
801040d7:	50                   	push   %eax
801040d8:	52                   	push   %edx
801040d9:	ff 73 10             	pushl  0x10(%ebx)
801040dc:	68 d1 6c 10 80       	push   $0x80106cd1
801040e1:	e8 25 c5 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
801040e6:	8b 43 18             	mov    0x18(%ebx),%eax
801040e9:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
801040f0:	83 c4 10             	add    $0x10,%esp
}
801040f3:	eb da                	jmp    801040cf <syscall+0x2f>

801040f5 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801040f5:	55                   	push   %ebp
801040f6:	89 e5                	mov    %esp,%ebp
801040f8:	56                   	push   %esi
801040f9:	53                   	push   %ebx
801040fa:	83 ec 18             	sub    $0x18,%esp
801040fd:	89 d6                	mov    %edx,%esi
801040ff:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80104101:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104104:	52                   	push   %edx
80104105:	50                   	push   %eax
80104106:	e8 d2 fe ff ff       	call   80103fdd <argint>
8010410b:	83 c4 10             	add    $0x10,%esp
8010410e:	85 c0                	test   %eax,%eax
80104110:	78 2e                	js     80104140 <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
80104112:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
80104116:	77 2f                	ja     80104147 <argfd+0x52>
80104118:	e8 27 f2 ff ff       	call   80103344 <myproc>
8010411d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104120:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
80104124:	85 c0                	test   %eax,%eax
80104126:	74 26                	je     8010414e <argfd+0x59>
    return -1;
  if(pfd)
80104128:	85 f6                	test   %esi,%esi
8010412a:	74 02                	je     8010412e <argfd+0x39>
    *pfd = fd;
8010412c:	89 16                	mov    %edx,(%esi)
  if(pf)
8010412e:	85 db                	test   %ebx,%ebx
80104130:	74 23                	je     80104155 <argfd+0x60>
    *pf = f;
80104132:	89 03                	mov    %eax,(%ebx)
  return 0;
80104134:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104139:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010413c:	5b                   	pop    %ebx
8010413d:	5e                   	pop    %esi
8010413e:	5d                   	pop    %ebp
8010413f:	c3                   	ret    
    return -1;
80104140:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104145:	eb f2                	jmp    80104139 <argfd+0x44>
    return -1;
80104147:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010414c:	eb eb                	jmp    80104139 <argfd+0x44>
8010414e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104153:	eb e4                	jmp    80104139 <argfd+0x44>
  return 0;
80104155:	b8 00 00 00 00       	mov    $0x0,%eax
8010415a:	eb dd                	jmp    80104139 <argfd+0x44>

8010415c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
8010415c:	55                   	push   %ebp
8010415d:	89 e5                	mov    %esp,%ebp
8010415f:	53                   	push   %ebx
80104160:	83 ec 04             	sub    $0x4,%esp
80104163:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
80104165:	e8 da f1 ff ff       	call   80103344 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
8010416a:	ba 00 00 00 00       	mov    $0x0,%edx
8010416f:	83 fa 0f             	cmp    $0xf,%edx
80104172:	7f 18                	jg     8010418c <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
80104174:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
80104179:	74 05                	je     80104180 <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
8010417b:	83 c2 01             	add    $0x1,%edx
8010417e:	eb ef                	jmp    8010416f <fdalloc+0x13>
      curproc->ofile[fd] = f;
80104180:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
80104184:	89 d0                	mov    %edx,%eax
80104186:	83 c4 04             	add    $0x4,%esp
80104189:	5b                   	pop    %ebx
8010418a:	5d                   	pop    %ebp
8010418b:	c3                   	ret    
  return -1;
8010418c:	ba ff ff ff ff       	mov    $0xffffffff,%edx
80104191:	eb f1                	jmp    80104184 <fdalloc+0x28>

80104193 <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80104193:	55                   	push   %ebp
80104194:	89 e5                	mov    %esp,%ebp
80104196:	56                   	push   %esi
80104197:	53                   	push   %ebx
80104198:	83 ec 10             	sub    $0x10,%esp
8010419b:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010419d:	b8 20 00 00 00       	mov    $0x20,%eax
801041a2:	89 c6                	mov    %eax,%esi
801041a4:	39 43 58             	cmp    %eax,0x58(%ebx)
801041a7:	76 2e                	jbe    801041d7 <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801041a9:	6a 10                	push   $0x10
801041ab:	50                   	push   %eax
801041ac:	8d 45 e8             	lea    -0x18(%ebp),%eax
801041af:	50                   	push   %eax
801041b0:	53                   	push   %ebx
801041b1:	e8 bd d5 ff ff       	call   80101773 <readi>
801041b6:	83 c4 10             	add    $0x10,%esp
801041b9:	83 f8 10             	cmp    $0x10,%eax
801041bc:	75 0c                	jne    801041ca <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
801041be:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
801041c3:	75 1e                	jne    801041e3 <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801041c5:	8d 46 10             	lea    0x10(%esi),%eax
801041c8:	eb d8                	jmp    801041a2 <isdirempty+0xf>
      panic("isdirempty: readi");
801041ca:	83 ec 0c             	sub    $0xc,%esp
801041cd:	68 5c 6d 10 80       	push   $0x80106d5c
801041d2:	e8 71 c1 ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
801041d7:	b8 01 00 00 00       	mov    $0x1,%eax
}
801041dc:	8d 65 f8             	lea    -0x8(%ebp),%esp
801041df:	5b                   	pop    %ebx
801041e0:	5e                   	pop    %esi
801041e1:	5d                   	pop    %ebp
801041e2:	c3                   	ret    
      return 0;
801041e3:	b8 00 00 00 00       	mov    $0x0,%eax
801041e8:	eb f2                	jmp    801041dc <isdirempty+0x49>

801041ea <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
801041ea:	55                   	push   %ebp
801041eb:	89 e5                	mov    %esp,%ebp
801041ed:	57                   	push   %edi
801041ee:	56                   	push   %esi
801041ef:	53                   	push   %ebx
801041f0:	83 ec 44             	sub    $0x44,%esp
801041f3:	89 55 c4             	mov    %edx,-0x3c(%ebp)
801041f6:	89 4d c0             	mov    %ecx,-0x40(%ebp)
801041f9:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801041fc:	8d 55 d6             	lea    -0x2a(%ebp),%edx
801041ff:	52                   	push   %edx
80104200:	50                   	push   %eax
80104201:	e8 f3 d9 ff ff       	call   80101bf9 <nameiparent>
80104206:	89 c6                	mov    %eax,%esi
80104208:	83 c4 10             	add    $0x10,%esp
8010420b:	85 c0                	test   %eax,%eax
8010420d:	0f 84 3a 01 00 00    	je     8010434d <create+0x163>
    return 0;
  ilock(dp);
80104213:	83 ec 0c             	sub    $0xc,%esp
80104216:	50                   	push   %eax
80104217:	e8 65 d3 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
8010421c:	83 c4 0c             	add    $0xc,%esp
8010421f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104222:	50                   	push   %eax
80104223:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104226:	50                   	push   %eax
80104227:	56                   	push   %esi
80104228:	e8 83 d7 ff ff       	call   801019b0 <dirlookup>
8010422d:	89 c3                	mov    %eax,%ebx
8010422f:	83 c4 10             	add    $0x10,%esp
80104232:	85 c0                	test   %eax,%eax
80104234:	74 3f                	je     80104275 <create+0x8b>
    iunlockput(dp);
80104236:	83 ec 0c             	sub    $0xc,%esp
80104239:	56                   	push   %esi
8010423a:	e8 e9 d4 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
8010423f:	89 1c 24             	mov    %ebx,(%esp)
80104242:	e8 3a d3 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80104247:	83 c4 10             	add    $0x10,%esp
8010424a:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
8010424f:	75 11                	jne    80104262 <create+0x78>
80104251:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
80104256:	75 0a                	jne    80104262 <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
80104258:	89 d8                	mov    %ebx,%eax
8010425a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010425d:	5b                   	pop    %ebx
8010425e:	5e                   	pop    %esi
8010425f:	5f                   	pop    %edi
80104260:	5d                   	pop    %ebp
80104261:	c3                   	ret    
    iunlockput(ip);
80104262:	83 ec 0c             	sub    $0xc,%esp
80104265:	53                   	push   %ebx
80104266:	e8 bd d4 ff ff       	call   80101728 <iunlockput>
    return 0;
8010426b:	83 c4 10             	add    $0x10,%esp
8010426e:	bb 00 00 00 00       	mov    $0x0,%ebx
80104273:	eb e3                	jmp    80104258 <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
80104275:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
80104279:	83 ec 08             	sub    $0x8,%esp
8010427c:	50                   	push   %eax
8010427d:	ff 36                	pushl  (%esi)
8010427f:	e8 fa d0 ff ff       	call   8010137e <ialloc>
80104284:	89 c3                	mov    %eax,%ebx
80104286:	83 c4 10             	add    $0x10,%esp
80104289:	85 c0                	test   %eax,%eax
8010428b:	74 55                	je     801042e2 <create+0xf8>
  ilock(ip);
8010428d:	83 ec 0c             	sub    $0xc,%esp
80104290:	50                   	push   %eax
80104291:	e8 eb d2 ff ff       	call   80101581 <ilock>
  ip->major = major;
80104296:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
8010429a:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
8010429e:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
801042a2:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
801042a8:	89 1c 24             	mov    %ebx,(%esp)
801042ab:	e8 70 d1 ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
801042b0:	83 c4 10             	add    $0x10,%esp
801042b3:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
801042b8:	74 35                	je     801042ef <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
801042ba:	83 ec 04             	sub    $0x4,%esp
801042bd:	ff 73 04             	pushl  0x4(%ebx)
801042c0:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801042c3:	50                   	push   %eax
801042c4:	56                   	push   %esi
801042c5:	e8 66 d8 ff ff       	call   80101b30 <dirlink>
801042ca:	83 c4 10             	add    $0x10,%esp
801042cd:	85 c0                	test   %eax,%eax
801042cf:	78 6f                	js     80104340 <create+0x156>
  iunlockput(dp);
801042d1:	83 ec 0c             	sub    $0xc,%esp
801042d4:	56                   	push   %esi
801042d5:	e8 4e d4 ff ff       	call   80101728 <iunlockput>
  return ip;
801042da:	83 c4 10             	add    $0x10,%esp
801042dd:	e9 76 ff ff ff       	jmp    80104258 <create+0x6e>
    panic("create: ialloc");
801042e2:	83 ec 0c             	sub    $0xc,%esp
801042e5:	68 6e 6d 10 80       	push   $0x80106d6e
801042ea:	e8 59 c0 ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
801042ef:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801042f3:	83 c0 01             	add    $0x1,%eax
801042f6:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801042fa:	83 ec 0c             	sub    $0xc,%esp
801042fd:	56                   	push   %esi
801042fe:	e8 1d d1 ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80104303:	83 c4 0c             	add    $0xc,%esp
80104306:	ff 73 04             	pushl  0x4(%ebx)
80104309:	68 7e 6d 10 80       	push   $0x80106d7e
8010430e:	53                   	push   %ebx
8010430f:	e8 1c d8 ff ff       	call   80101b30 <dirlink>
80104314:	83 c4 10             	add    $0x10,%esp
80104317:	85 c0                	test   %eax,%eax
80104319:	78 18                	js     80104333 <create+0x149>
8010431b:	83 ec 04             	sub    $0x4,%esp
8010431e:	ff 76 04             	pushl  0x4(%esi)
80104321:	68 7d 6d 10 80       	push   $0x80106d7d
80104326:	53                   	push   %ebx
80104327:	e8 04 d8 ff ff       	call   80101b30 <dirlink>
8010432c:	83 c4 10             	add    $0x10,%esp
8010432f:	85 c0                	test   %eax,%eax
80104331:	79 87                	jns    801042ba <create+0xd0>
      panic("create dots");
80104333:	83 ec 0c             	sub    $0xc,%esp
80104336:	68 80 6d 10 80       	push   $0x80106d80
8010433b:	e8 08 c0 ff ff       	call   80100348 <panic>
    panic("create: dirlink");
80104340:	83 ec 0c             	sub    $0xc,%esp
80104343:	68 8c 6d 10 80       	push   $0x80106d8c
80104348:	e8 fb bf ff ff       	call   80100348 <panic>
    return 0;
8010434d:	89 c3                	mov    %eax,%ebx
8010434f:	e9 04 ff ff ff       	jmp    80104258 <create+0x6e>

80104354 <sys_dup>:
{
80104354:	55                   	push   %ebp
80104355:	89 e5                	mov    %esp,%ebp
80104357:	53                   	push   %ebx
80104358:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
8010435b:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010435e:	ba 00 00 00 00       	mov    $0x0,%edx
80104363:	b8 00 00 00 00       	mov    $0x0,%eax
80104368:	e8 88 fd ff ff       	call   801040f5 <argfd>
8010436d:	85 c0                	test   %eax,%eax
8010436f:	78 23                	js     80104394 <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
80104371:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104374:	e8 e3 fd ff ff       	call   8010415c <fdalloc>
80104379:	89 c3                	mov    %eax,%ebx
8010437b:	85 c0                	test   %eax,%eax
8010437d:	78 1c                	js     8010439b <sys_dup+0x47>
  filedup(f);
8010437f:	83 ec 0c             	sub    $0xc,%esp
80104382:	ff 75 f4             	pushl  -0xc(%ebp)
80104385:	e8 04 c9 ff ff       	call   80100c8e <filedup>
  return fd;
8010438a:	83 c4 10             	add    $0x10,%esp
}
8010438d:	89 d8                	mov    %ebx,%eax
8010438f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104392:	c9                   	leave  
80104393:	c3                   	ret    
    return -1;
80104394:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104399:	eb f2                	jmp    8010438d <sys_dup+0x39>
    return -1;
8010439b:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801043a0:	eb eb                	jmp    8010438d <sys_dup+0x39>

801043a2 <sys_read>:
{
801043a2:	55                   	push   %ebp
801043a3:	89 e5                	mov    %esp,%ebp
801043a5:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801043a8:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801043ab:	ba 00 00 00 00       	mov    $0x0,%edx
801043b0:	b8 00 00 00 00       	mov    $0x0,%eax
801043b5:	e8 3b fd ff ff       	call   801040f5 <argfd>
801043ba:	85 c0                	test   %eax,%eax
801043bc:	78 43                	js     80104401 <sys_read+0x5f>
801043be:	83 ec 08             	sub    $0x8,%esp
801043c1:	8d 45 f0             	lea    -0x10(%ebp),%eax
801043c4:	50                   	push   %eax
801043c5:	6a 02                	push   $0x2
801043c7:	e8 11 fc ff ff       	call   80103fdd <argint>
801043cc:	83 c4 10             	add    $0x10,%esp
801043cf:	85 c0                	test   %eax,%eax
801043d1:	78 35                	js     80104408 <sys_read+0x66>
801043d3:	83 ec 04             	sub    $0x4,%esp
801043d6:	ff 75 f0             	pushl  -0x10(%ebp)
801043d9:	8d 45 ec             	lea    -0x14(%ebp),%eax
801043dc:	50                   	push   %eax
801043dd:	6a 01                	push   $0x1
801043df:	e8 21 fc ff ff       	call   80104005 <argptr>
801043e4:	83 c4 10             	add    $0x10,%esp
801043e7:	85 c0                	test   %eax,%eax
801043e9:	78 24                	js     8010440f <sys_read+0x6d>
  return fileread(f, p, n);
801043eb:	83 ec 04             	sub    $0x4,%esp
801043ee:	ff 75 f0             	pushl  -0x10(%ebp)
801043f1:	ff 75 ec             	pushl  -0x14(%ebp)
801043f4:	ff 75 f4             	pushl  -0xc(%ebp)
801043f7:	e8 db c9 ff ff       	call   80100dd7 <fileread>
801043fc:	83 c4 10             	add    $0x10,%esp
}
801043ff:	c9                   	leave  
80104400:	c3                   	ret    
    return -1;
80104401:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104406:	eb f7                	jmp    801043ff <sys_read+0x5d>
80104408:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010440d:	eb f0                	jmp    801043ff <sys_read+0x5d>
8010440f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104414:	eb e9                	jmp    801043ff <sys_read+0x5d>

80104416 <sys_write>:
{
80104416:	55                   	push   %ebp
80104417:	89 e5                	mov    %esp,%ebp
80104419:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010441c:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010441f:	ba 00 00 00 00       	mov    $0x0,%edx
80104424:	b8 00 00 00 00       	mov    $0x0,%eax
80104429:	e8 c7 fc ff ff       	call   801040f5 <argfd>
8010442e:	85 c0                	test   %eax,%eax
80104430:	78 43                	js     80104475 <sys_write+0x5f>
80104432:	83 ec 08             	sub    $0x8,%esp
80104435:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104438:	50                   	push   %eax
80104439:	6a 02                	push   $0x2
8010443b:	e8 9d fb ff ff       	call   80103fdd <argint>
80104440:	83 c4 10             	add    $0x10,%esp
80104443:	85 c0                	test   %eax,%eax
80104445:	78 35                	js     8010447c <sys_write+0x66>
80104447:	83 ec 04             	sub    $0x4,%esp
8010444a:	ff 75 f0             	pushl  -0x10(%ebp)
8010444d:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104450:	50                   	push   %eax
80104451:	6a 01                	push   $0x1
80104453:	e8 ad fb ff ff       	call   80104005 <argptr>
80104458:	83 c4 10             	add    $0x10,%esp
8010445b:	85 c0                	test   %eax,%eax
8010445d:	78 24                	js     80104483 <sys_write+0x6d>
  return filewrite(f, p, n);
8010445f:	83 ec 04             	sub    $0x4,%esp
80104462:	ff 75 f0             	pushl  -0x10(%ebp)
80104465:	ff 75 ec             	pushl  -0x14(%ebp)
80104468:	ff 75 f4             	pushl  -0xc(%ebp)
8010446b:	e8 ec c9 ff ff       	call   80100e5c <filewrite>
80104470:	83 c4 10             	add    $0x10,%esp
}
80104473:	c9                   	leave  
80104474:	c3                   	ret    
    return -1;
80104475:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010447a:	eb f7                	jmp    80104473 <sys_write+0x5d>
8010447c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104481:	eb f0                	jmp    80104473 <sys_write+0x5d>
80104483:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104488:	eb e9                	jmp    80104473 <sys_write+0x5d>

8010448a <sys_close>:
{
8010448a:	55                   	push   %ebp
8010448b:	89 e5                	mov    %esp,%ebp
8010448d:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
80104490:	8d 4d f0             	lea    -0x10(%ebp),%ecx
80104493:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104496:	b8 00 00 00 00       	mov    $0x0,%eax
8010449b:	e8 55 fc ff ff       	call   801040f5 <argfd>
801044a0:	85 c0                	test   %eax,%eax
801044a2:	78 25                	js     801044c9 <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
801044a4:	e8 9b ee ff ff       	call   80103344 <myproc>
801044a9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801044ac:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
801044b3:	00 
  fileclose(f);
801044b4:	83 ec 0c             	sub    $0xc,%esp
801044b7:	ff 75 f0             	pushl  -0x10(%ebp)
801044ba:	e8 14 c8 ff ff       	call   80100cd3 <fileclose>
  return 0;
801044bf:	83 c4 10             	add    $0x10,%esp
801044c2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801044c7:	c9                   	leave  
801044c8:	c3                   	ret    
    return -1;
801044c9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044ce:	eb f7                	jmp    801044c7 <sys_close+0x3d>

801044d0 <sys_fstat>:
{
801044d0:	55                   	push   %ebp
801044d1:	89 e5                	mov    %esp,%ebp
801044d3:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801044d6:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801044d9:	ba 00 00 00 00       	mov    $0x0,%edx
801044de:	b8 00 00 00 00       	mov    $0x0,%eax
801044e3:	e8 0d fc ff ff       	call   801040f5 <argfd>
801044e8:	85 c0                	test   %eax,%eax
801044ea:	78 2a                	js     80104516 <sys_fstat+0x46>
801044ec:	83 ec 04             	sub    $0x4,%esp
801044ef:	6a 14                	push   $0x14
801044f1:	8d 45 f0             	lea    -0x10(%ebp),%eax
801044f4:	50                   	push   %eax
801044f5:	6a 01                	push   $0x1
801044f7:	e8 09 fb ff ff       	call   80104005 <argptr>
801044fc:	83 c4 10             	add    $0x10,%esp
801044ff:	85 c0                	test   %eax,%eax
80104501:	78 1a                	js     8010451d <sys_fstat+0x4d>
  return filestat(f, st);
80104503:	83 ec 08             	sub    $0x8,%esp
80104506:	ff 75 f0             	pushl  -0x10(%ebp)
80104509:	ff 75 f4             	pushl  -0xc(%ebp)
8010450c:	e8 7f c8 ff ff       	call   80100d90 <filestat>
80104511:	83 c4 10             	add    $0x10,%esp
}
80104514:	c9                   	leave  
80104515:	c3                   	ret    
    return -1;
80104516:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010451b:	eb f7                	jmp    80104514 <sys_fstat+0x44>
8010451d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104522:	eb f0                	jmp    80104514 <sys_fstat+0x44>

80104524 <sys_link>:
{
80104524:	55                   	push   %ebp
80104525:	89 e5                	mov    %esp,%ebp
80104527:	56                   	push   %esi
80104528:	53                   	push   %ebx
80104529:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
8010452c:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010452f:	50                   	push   %eax
80104530:	6a 00                	push   $0x0
80104532:	e8 36 fb ff ff       	call   8010406d <argstr>
80104537:	83 c4 10             	add    $0x10,%esp
8010453a:	85 c0                	test   %eax,%eax
8010453c:	0f 88 32 01 00 00    	js     80104674 <sys_link+0x150>
80104542:	83 ec 08             	sub    $0x8,%esp
80104545:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104548:	50                   	push   %eax
80104549:	6a 01                	push   $0x1
8010454b:	e8 1d fb ff ff       	call   8010406d <argstr>
80104550:	83 c4 10             	add    $0x10,%esp
80104553:	85 c0                	test   %eax,%eax
80104555:	0f 88 20 01 00 00    	js     8010467b <sys_link+0x157>
  begin_op();
8010455b:	e8 94 e3 ff ff       	call   801028f4 <begin_op>
  if((ip = namei(old)) == 0){
80104560:	83 ec 0c             	sub    $0xc,%esp
80104563:	ff 75 e0             	pushl  -0x20(%ebp)
80104566:	e8 76 d6 ff ff       	call   80101be1 <namei>
8010456b:	89 c3                	mov    %eax,%ebx
8010456d:	83 c4 10             	add    $0x10,%esp
80104570:	85 c0                	test   %eax,%eax
80104572:	0f 84 99 00 00 00    	je     80104611 <sys_link+0xed>
  ilock(ip);
80104578:	83 ec 0c             	sub    $0xc,%esp
8010457b:	50                   	push   %eax
8010457c:	e8 00 d0 ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
80104581:	83 c4 10             	add    $0x10,%esp
80104584:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104589:	0f 84 8e 00 00 00    	je     8010461d <sys_link+0xf9>
  ip->nlink++;
8010458f:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104593:	83 c0 01             	add    $0x1,%eax
80104596:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
8010459a:	83 ec 0c             	sub    $0xc,%esp
8010459d:	53                   	push   %ebx
8010459e:	e8 7d ce ff ff       	call   80101420 <iupdate>
  iunlock(ip);
801045a3:	89 1c 24             	mov    %ebx,(%esp)
801045a6:	e8 98 d0 ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
801045ab:	83 c4 08             	add    $0x8,%esp
801045ae:	8d 45 ea             	lea    -0x16(%ebp),%eax
801045b1:	50                   	push   %eax
801045b2:	ff 75 e4             	pushl  -0x1c(%ebp)
801045b5:	e8 3f d6 ff ff       	call   80101bf9 <nameiparent>
801045ba:	89 c6                	mov    %eax,%esi
801045bc:	83 c4 10             	add    $0x10,%esp
801045bf:	85 c0                	test   %eax,%eax
801045c1:	74 7e                	je     80104641 <sys_link+0x11d>
  ilock(dp);
801045c3:	83 ec 0c             	sub    $0xc,%esp
801045c6:	50                   	push   %eax
801045c7:	e8 b5 cf ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801045cc:	83 c4 10             	add    $0x10,%esp
801045cf:	8b 03                	mov    (%ebx),%eax
801045d1:	39 06                	cmp    %eax,(%esi)
801045d3:	75 60                	jne    80104635 <sys_link+0x111>
801045d5:	83 ec 04             	sub    $0x4,%esp
801045d8:	ff 73 04             	pushl  0x4(%ebx)
801045db:	8d 45 ea             	lea    -0x16(%ebp),%eax
801045de:	50                   	push   %eax
801045df:	56                   	push   %esi
801045e0:	e8 4b d5 ff ff       	call   80101b30 <dirlink>
801045e5:	83 c4 10             	add    $0x10,%esp
801045e8:	85 c0                	test   %eax,%eax
801045ea:	78 49                	js     80104635 <sys_link+0x111>
  iunlockput(dp);
801045ec:	83 ec 0c             	sub    $0xc,%esp
801045ef:	56                   	push   %esi
801045f0:	e8 33 d1 ff ff       	call   80101728 <iunlockput>
  iput(ip);
801045f5:	89 1c 24             	mov    %ebx,(%esp)
801045f8:	e8 8b d0 ff ff       	call   80101688 <iput>
  end_op();
801045fd:	e8 6c e3 ff ff       	call   8010296e <end_op>
  return 0;
80104602:	83 c4 10             	add    $0x10,%esp
80104605:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010460a:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010460d:	5b                   	pop    %ebx
8010460e:	5e                   	pop    %esi
8010460f:	5d                   	pop    %ebp
80104610:	c3                   	ret    
    end_op();
80104611:	e8 58 e3 ff ff       	call   8010296e <end_op>
    return -1;
80104616:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010461b:	eb ed                	jmp    8010460a <sys_link+0xe6>
    iunlockput(ip);
8010461d:	83 ec 0c             	sub    $0xc,%esp
80104620:	53                   	push   %ebx
80104621:	e8 02 d1 ff ff       	call   80101728 <iunlockput>
    end_op();
80104626:	e8 43 e3 ff ff       	call   8010296e <end_op>
    return -1;
8010462b:	83 c4 10             	add    $0x10,%esp
8010462e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104633:	eb d5                	jmp    8010460a <sys_link+0xe6>
    iunlockput(dp);
80104635:	83 ec 0c             	sub    $0xc,%esp
80104638:	56                   	push   %esi
80104639:	e8 ea d0 ff ff       	call   80101728 <iunlockput>
    goto bad;
8010463e:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
80104641:	83 ec 0c             	sub    $0xc,%esp
80104644:	53                   	push   %ebx
80104645:	e8 37 cf ff ff       	call   80101581 <ilock>
  ip->nlink--;
8010464a:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010464e:	83 e8 01             	sub    $0x1,%eax
80104651:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104655:	89 1c 24             	mov    %ebx,(%esp)
80104658:	e8 c3 cd ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
8010465d:	89 1c 24             	mov    %ebx,(%esp)
80104660:	e8 c3 d0 ff ff       	call   80101728 <iunlockput>
  end_op();
80104665:	e8 04 e3 ff ff       	call   8010296e <end_op>
  return -1;
8010466a:	83 c4 10             	add    $0x10,%esp
8010466d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104672:	eb 96                	jmp    8010460a <sys_link+0xe6>
    return -1;
80104674:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104679:	eb 8f                	jmp    8010460a <sys_link+0xe6>
8010467b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104680:	eb 88                	jmp    8010460a <sys_link+0xe6>

80104682 <sys_unlink>:
{
80104682:	55                   	push   %ebp
80104683:	89 e5                	mov    %esp,%ebp
80104685:	57                   	push   %edi
80104686:	56                   	push   %esi
80104687:	53                   	push   %ebx
80104688:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
8010468b:	8d 45 c4             	lea    -0x3c(%ebp),%eax
8010468e:	50                   	push   %eax
8010468f:	6a 00                	push   $0x0
80104691:	e8 d7 f9 ff ff       	call   8010406d <argstr>
80104696:	83 c4 10             	add    $0x10,%esp
80104699:	85 c0                	test   %eax,%eax
8010469b:	0f 88 83 01 00 00    	js     80104824 <sys_unlink+0x1a2>
  begin_op();
801046a1:	e8 4e e2 ff ff       	call   801028f4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
801046a6:	83 ec 08             	sub    $0x8,%esp
801046a9:	8d 45 ca             	lea    -0x36(%ebp),%eax
801046ac:	50                   	push   %eax
801046ad:	ff 75 c4             	pushl  -0x3c(%ebp)
801046b0:	e8 44 d5 ff ff       	call   80101bf9 <nameiparent>
801046b5:	89 c6                	mov    %eax,%esi
801046b7:	83 c4 10             	add    $0x10,%esp
801046ba:	85 c0                	test   %eax,%eax
801046bc:	0f 84 ed 00 00 00    	je     801047af <sys_unlink+0x12d>
  ilock(dp);
801046c2:	83 ec 0c             	sub    $0xc,%esp
801046c5:	50                   	push   %eax
801046c6:	e8 b6 ce ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801046cb:	83 c4 08             	add    $0x8,%esp
801046ce:	68 7e 6d 10 80       	push   $0x80106d7e
801046d3:	8d 45 ca             	lea    -0x36(%ebp),%eax
801046d6:	50                   	push   %eax
801046d7:	e8 bf d2 ff ff       	call   8010199b <namecmp>
801046dc:	83 c4 10             	add    $0x10,%esp
801046df:	85 c0                	test   %eax,%eax
801046e1:	0f 84 fc 00 00 00    	je     801047e3 <sys_unlink+0x161>
801046e7:	83 ec 08             	sub    $0x8,%esp
801046ea:	68 7d 6d 10 80       	push   $0x80106d7d
801046ef:	8d 45 ca             	lea    -0x36(%ebp),%eax
801046f2:	50                   	push   %eax
801046f3:	e8 a3 d2 ff ff       	call   8010199b <namecmp>
801046f8:	83 c4 10             	add    $0x10,%esp
801046fb:	85 c0                	test   %eax,%eax
801046fd:	0f 84 e0 00 00 00    	je     801047e3 <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
80104703:	83 ec 04             	sub    $0x4,%esp
80104706:	8d 45 c0             	lea    -0x40(%ebp),%eax
80104709:	50                   	push   %eax
8010470a:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010470d:	50                   	push   %eax
8010470e:	56                   	push   %esi
8010470f:	e8 9c d2 ff ff       	call   801019b0 <dirlookup>
80104714:	89 c3                	mov    %eax,%ebx
80104716:	83 c4 10             	add    $0x10,%esp
80104719:	85 c0                	test   %eax,%eax
8010471b:	0f 84 c2 00 00 00    	je     801047e3 <sys_unlink+0x161>
  ilock(ip);
80104721:	83 ec 0c             	sub    $0xc,%esp
80104724:	50                   	push   %eax
80104725:	e8 57 ce ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
8010472a:	83 c4 10             	add    $0x10,%esp
8010472d:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
80104732:	0f 8e 83 00 00 00    	jle    801047bb <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104738:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010473d:	0f 84 85 00 00 00    	je     801047c8 <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
80104743:	83 ec 04             	sub    $0x4,%esp
80104746:	6a 10                	push   $0x10
80104748:	6a 00                	push   $0x0
8010474a:	8d 7d d8             	lea    -0x28(%ebp),%edi
8010474d:	57                   	push   %edi
8010474e:	e8 3f f6 ff ff       	call   80103d92 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104753:	6a 10                	push   $0x10
80104755:	ff 75 c0             	pushl  -0x40(%ebp)
80104758:	57                   	push   %edi
80104759:	56                   	push   %esi
8010475a:	e8 11 d1 ff ff       	call   80101870 <writei>
8010475f:	83 c4 20             	add    $0x20,%esp
80104762:	83 f8 10             	cmp    $0x10,%eax
80104765:	0f 85 90 00 00 00    	jne    801047fb <sys_unlink+0x179>
  if(ip->type == T_DIR){
8010476b:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104770:	0f 84 92 00 00 00    	je     80104808 <sys_unlink+0x186>
  iunlockput(dp);
80104776:	83 ec 0c             	sub    $0xc,%esp
80104779:	56                   	push   %esi
8010477a:	e8 a9 cf ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
8010477f:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104783:	83 e8 01             	sub    $0x1,%eax
80104786:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
8010478a:	89 1c 24             	mov    %ebx,(%esp)
8010478d:	e8 8e cc ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104792:	89 1c 24             	mov    %ebx,(%esp)
80104795:	e8 8e cf ff ff       	call   80101728 <iunlockput>
  end_op();
8010479a:	e8 cf e1 ff ff       	call   8010296e <end_op>
  return 0;
8010479f:	83 c4 10             	add    $0x10,%esp
801047a2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801047a7:	8d 65 f4             	lea    -0xc(%ebp),%esp
801047aa:	5b                   	pop    %ebx
801047ab:	5e                   	pop    %esi
801047ac:	5f                   	pop    %edi
801047ad:	5d                   	pop    %ebp
801047ae:	c3                   	ret    
    end_op();
801047af:	e8 ba e1 ff ff       	call   8010296e <end_op>
    return -1;
801047b4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047b9:	eb ec                	jmp    801047a7 <sys_unlink+0x125>
    panic("unlink: nlink < 1");
801047bb:	83 ec 0c             	sub    $0xc,%esp
801047be:	68 9c 6d 10 80       	push   $0x80106d9c
801047c3:	e8 80 bb ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801047c8:	89 d8                	mov    %ebx,%eax
801047ca:	e8 c4 f9 ff ff       	call   80104193 <isdirempty>
801047cf:	85 c0                	test   %eax,%eax
801047d1:	0f 85 6c ff ff ff    	jne    80104743 <sys_unlink+0xc1>
    iunlockput(ip);
801047d7:	83 ec 0c             	sub    $0xc,%esp
801047da:	53                   	push   %ebx
801047db:	e8 48 cf ff ff       	call   80101728 <iunlockput>
    goto bad;
801047e0:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
801047e3:	83 ec 0c             	sub    $0xc,%esp
801047e6:	56                   	push   %esi
801047e7:	e8 3c cf ff ff       	call   80101728 <iunlockput>
  end_op();
801047ec:	e8 7d e1 ff ff       	call   8010296e <end_op>
  return -1;
801047f1:	83 c4 10             	add    $0x10,%esp
801047f4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047f9:	eb ac                	jmp    801047a7 <sys_unlink+0x125>
    panic("unlink: writei");
801047fb:	83 ec 0c             	sub    $0xc,%esp
801047fe:	68 ae 6d 10 80       	push   $0x80106dae
80104803:	e8 40 bb ff ff       	call   80100348 <panic>
    dp->nlink--;
80104808:	0f b7 46 56          	movzwl 0x56(%esi),%eax
8010480c:	83 e8 01             	sub    $0x1,%eax
8010480f:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104813:	83 ec 0c             	sub    $0xc,%esp
80104816:	56                   	push   %esi
80104817:	e8 04 cc ff ff       	call   80101420 <iupdate>
8010481c:	83 c4 10             	add    $0x10,%esp
8010481f:	e9 52 ff ff ff       	jmp    80104776 <sys_unlink+0xf4>
    return -1;
80104824:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104829:	e9 79 ff ff ff       	jmp    801047a7 <sys_unlink+0x125>

8010482e <sys_open>:

int
sys_open(void)
{
8010482e:	55                   	push   %ebp
8010482f:	89 e5                	mov    %esp,%ebp
80104831:	57                   	push   %edi
80104832:	56                   	push   %esi
80104833:	53                   	push   %ebx
80104834:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80104837:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010483a:	50                   	push   %eax
8010483b:	6a 00                	push   $0x0
8010483d:	e8 2b f8 ff ff       	call   8010406d <argstr>
80104842:	83 c4 10             	add    $0x10,%esp
80104845:	85 c0                	test   %eax,%eax
80104847:	0f 88 30 01 00 00    	js     8010497d <sys_open+0x14f>
8010484d:	83 ec 08             	sub    $0x8,%esp
80104850:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104853:	50                   	push   %eax
80104854:	6a 01                	push   $0x1
80104856:	e8 82 f7 ff ff       	call   80103fdd <argint>
8010485b:	83 c4 10             	add    $0x10,%esp
8010485e:	85 c0                	test   %eax,%eax
80104860:	0f 88 21 01 00 00    	js     80104987 <sys_open+0x159>
    return -1;

  begin_op();
80104866:	e8 89 e0 ff ff       	call   801028f4 <begin_op>

  if(omode & O_CREATE){
8010486b:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
8010486f:	0f 84 84 00 00 00    	je     801048f9 <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
80104875:	83 ec 0c             	sub    $0xc,%esp
80104878:	6a 00                	push   $0x0
8010487a:	b9 00 00 00 00       	mov    $0x0,%ecx
8010487f:	ba 02 00 00 00       	mov    $0x2,%edx
80104884:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104887:	e8 5e f9 ff ff       	call   801041ea <create>
8010488c:	89 c6                	mov    %eax,%esi
    if(ip == 0){
8010488e:	83 c4 10             	add    $0x10,%esp
80104891:	85 c0                	test   %eax,%eax
80104893:	74 58                	je     801048ed <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80104895:	e8 93 c3 ff ff       	call   80100c2d <filealloc>
8010489a:	89 c3                	mov    %eax,%ebx
8010489c:	85 c0                	test   %eax,%eax
8010489e:	0f 84 ae 00 00 00    	je     80104952 <sys_open+0x124>
801048a4:	e8 b3 f8 ff ff       	call   8010415c <fdalloc>
801048a9:	89 c7                	mov    %eax,%edi
801048ab:	85 c0                	test   %eax,%eax
801048ad:	0f 88 9f 00 00 00    	js     80104952 <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
801048b3:	83 ec 0c             	sub    $0xc,%esp
801048b6:	56                   	push   %esi
801048b7:	e8 87 cd ff ff       	call   80101643 <iunlock>
  end_op();
801048bc:	e8 ad e0 ff ff       	call   8010296e <end_op>

  f->type = FD_INODE;
801048c1:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
801048c7:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
801048ca:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
801048d1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801048d4:	83 c4 10             	add    $0x10,%esp
801048d7:	a8 01                	test   $0x1,%al
801048d9:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
801048dd:	a8 03                	test   $0x3,%al
801048df:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
801048e3:	89 f8                	mov    %edi,%eax
801048e5:	8d 65 f4             	lea    -0xc(%ebp),%esp
801048e8:	5b                   	pop    %ebx
801048e9:	5e                   	pop    %esi
801048ea:	5f                   	pop    %edi
801048eb:	5d                   	pop    %ebp
801048ec:	c3                   	ret    
      end_op();
801048ed:	e8 7c e0 ff ff       	call   8010296e <end_op>
      return -1;
801048f2:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801048f7:	eb ea                	jmp    801048e3 <sys_open+0xb5>
    if((ip = namei(path)) == 0){
801048f9:	83 ec 0c             	sub    $0xc,%esp
801048fc:	ff 75 e4             	pushl  -0x1c(%ebp)
801048ff:	e8 dd d2 ff ff       	call   80101be1 <namei>
80104904:	89 c6                	mov    %eax,%esi
80104906:	83 c4 10             	add    $0x10,%esp
80104909:	85 c0                	test   %eax,%eax
8010490b:	74 39                	je     80104946 <sys_open+0x118>
    ilock(ip);
8010490d:	83 ec 0c             	sub    $0xc,%esp
80104910:	50                   	push   %eax
80104911:	e8 6b cc ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80104916:	83 c4 10             	add    $0x10,%esp
80104919:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
8010491e:	0f 85 71 ff ff ff    	jne    80104895 <sys_open+0x67>
80104924:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104928:	0f 84 67 ff ff ff    	je     80104895 <sys_open+0x67>
      iunlockput(ip);
8010492e:	83 ec 0c             	sub    $0xc,%esp
80104931:	56                   	push   %esi
80104932:	e8 f1 cd ff ff       	call   80101728 <iunlockput>
      end_op();
80104937:	e8 32 e0 ff ff       	call   8010296e <end_op>
      return -1;
8010493c:	83 c4 10             	add    $0x10,%esp
8010493f:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104944:	eb 9d                	jmp    801048e3 <sys_open+0xb5>
      end_op();
80104946:	e8 23 e0 ff ff       	call   8010296e <end_op>
      return -1;
8010494b:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104950:	eb 91                	jmp    801048e3 <sys_open+0xb5>
    if(f)
80104952:	85 db                	test   %ebx,%ebx
80104954:	74 0c                	je     80104962 <sys_open+0x134>
      fileclose(f);
80104956:	83 ec 0c             	sub    $0xc,%esp
80104959:	53                   	push   %ebx
8010495a:	e8 74 c3 ff ff       	call   80100cd3 <fileclose>
8010495f:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104962:	83 ec 0c             	sub    $0xc,%esp
80104965:	56                   	push   %esi
80104966:	e8 bd cd ff ff       	call   80101728 <iunlockput>
    end_op();
8010496b:	e8 fe df ff ff       	call   8010296e <end_op>
    return -1;
80104970:	83 c4 10             	add    $0x10,%esp
80104973:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104978:	e9 66 ff ff ff       	jmp    801048e3 <sys_open+0xb5>
    return -1;
8010497d:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104982:	e9 5c ff ff ff       	jmp    801048e3 <sys_open+0xb5>
80104987:	bf ff ff ff ff       	mov    $0xffffffff,%edi
8010498c:	e9 52 ff ff ff       	jmp    801048e3 <sys_open+0xb5>

80104991 <sys_mkdir>:

int
sys_mkdir(void)
{
80104991:	55                   	push   %ebp
80104992:	89 e5                	mov    %esp,%ebp
80104994:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104997:	e8 58 df ff ff       	call   801028f4 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
8010499c:	83 ec 08             	sub    $0x8,%esp
8010499f:	8d 45 f4             	lea    -0xc(%ebp),%eax
801049a2:	50                   	push   %eax
801049a3:	6a 00                	push   $0x0
801049a5:	e8 c3 f6 ff ff       	call   8010406d <argstr>
801049aa:	83 c4 10             	add    $0x10,%esp
801049ad:	85 c0                	test   %eax,%eax
801049af:	78 36                	js     801049e7 <sys_mkdir+0x56>
801049b1:	83 ec 0c             	sub    $0xc,%esp
801049b4:	6a 00                	push   $0x0
801049b6:	b9 00 00 00 00       	mov    $0x0,%ecx
801049bb:	ba 01 00 00 00       	mov    $0x1,%edx
801049c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049c3:	e8 22 f8 ff ff       	call   801041ea <create>
801049c8:	83 c4 10             	add    $0x10,%esp
801049cb:	85 c0                	test   %eax,%eax
801049cd:	74 18                	je     801049e7 <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
801049cf:	83 ec 0c             	sub    $0xc,%esp
801049d2:	50                   	push   %eax
801049d3:	e8 50 cd ff ff       	call   80101728 <iunlockput>
  end_op();
801049d8:	e8 91 df ff ff       	call   8010296e <end_op>
  return 0;
801049dd:	83 c4 10             	add    $0x10,%esp
801049e0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801049e5:	c9                   	leave  
801049e6:	c3                   	ret    
    end_op();
801049e7:	e8 82 df ff ff       	call   8010296e <end_op>
    return -1;
801049ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049f1:	eb f2                	jmp    801049e5 <sys_mkdir+0x54>

801049f3 <sys_mknod>:

int
sys_mknod(void)
{
801049f3:	55                   	push   %ebp
801049f4:	89 e5                	mov    %esp,%ebp
801049f6:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
801049f9:	e8 f6 de ff ff       	call   801028f4 <begin_op>
  if((argstr(0, &path)) < 0 ||
801049fe:	83 ec 08             	sub    $0x8,%esp
80104a01:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104a04:	50                   	push   %eax
80104a05:	6a 00                	push   $0x0
80104a07:	e8 61 f6 ff ff       	call   8010406d <argstr>
80104a0c:	83 c4 10             	add    $0x10,%esp
80104a0f:	85 c0                	test   %eax,%eax
80104a11:	78 62                	js     80104a75 <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104a13:	83 ec 08             	sub    $0x8,%esp
80104a16:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104a19:	50                   	push   %eax
80104a1a:	6a 01                	push   $0x1
80104a1c:	e8 bc f5 ff ff       	call   80103fdd <argint>
  if((argstr(0, &path)) < 0 ||
80104a21:	83 c4 10             	add    $0x10,%esp
80104a24:	85 c0                	test   %eax,%eax
80104a26:	78 4d                	js     80104a75 <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104a28:	83 ec 08             	sub    $0x8,%esp
80104a2b:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104a2e:	50                   	push   %eax
80104a2f:	6a 02                	push   $0x2
80104a31:	e8 a7 f5 ff ff       	call   80103fdd <argint>
     argint(1, &major) < 0 ||
80104a36:	83 c4 10             	add    $0x10,%esp
80104a39:	85 c0                	test   %eax,%eax
80104a3b:	78 38                	js     80104a75 <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104a3d:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104a41:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104a45:	83 ec 0c             	sub    $0xc,%esp
80104a48:	50                   	push   %eax
80104a49:	ba 03 00 00 00       	mov    $0x3,%edx
80104a4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a51:	e8 94 f7 ff ff       	call   801041ea <create>
80104a56:	83 c4 10             	add    $0x10,%esp
80104a59:	85 c0                	test   %eax,%eax
80104a5b:	74 18                	je     80104a75 <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104a5d:	83 ec 0c             	sub    $0xc,%esp
80104a60:	50                   	push   %eax
80104a61:	e8 c2 cc ff ff       	call   80101728 <iunlockput>
  end_op();
80104a66:	e8 03 df ff ff       	call   8010296e <end_op>
  return 0;
80104a6b:	83 c4 10             	add    $0x10,%esp
80104a6e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a73:	c9                   	leave  
80104a74:	c3                   	ret    
    end_op();
80104a75:	e8 f4 de ff ff       	call   8010296e <end_op>
    return -1;
80104a7a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a7f:	eb f2                	jmp    80104a73 <sys_mknod+0x80>

80104a81 <sys_chdir>:

int
sys_chdir(void)
{
80104a81:	55                   	push   %ebp
80104a82:	89 e5                	mov    %esp,%ebp
80104a84:	56                   	push   %esi
80104a85:	53                   	push   %ebx
80104a86:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104a89:	e8 b6 e8 ff ff       	call   80103344 <myproc>
80104a8e:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104a90:	e8 5f de ff ff       	call   801028f4 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104a95:	83 ec 08             	sub    $0x8,%esp
80104a98:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104a9b:	50                   	push   %eax
80104a9c:	6a 00                	push   $0x0
80104a9e:	e8 ca f5 ff ff       	call   8010406d <argstr>
80104aa3:	83 c4 10             	add    $0x10,%esp
80104aa6:	85 c0                	test   %eax,%eax
80104aa8:	78 52                	js     80104afc <sys_chdir+0x7b>
80104aaa:	83 ec 0c             	sub    $0xc,%esp
80104aad:	ff 75 f4             	pushl  -0xc(%ebp)
80104ab0:	e8 2c d1 ff ff       	call   80101be1 <namei>
80104ab5:	89 c3                	mov    %eax,%ebx
80104ab7:	83 c4 10             	add    $0x10,%esp
80104aba:	85 c0                	test   %eax,%eax
80104abc:	74 3e                	je     80104afc <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104abe:	83 ec 0c             	sub    $0xc,%esp
80104ac1:	50                   	push   %eax
80104ac2:	e8 ba ca ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104ac7:	83 c4 10             	add    $0x10,%esp
80104aca:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104acf:	75 37                	jne    80104b08 <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104ad1:	83 ec 0c             	sub    $0xc,%esp
80104ad4:	53                   	push   %ebx
80104ad5:	e8 69 cb ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104ada:	83 c4 04             	add    $0x4,%esp
80104add:	ff 76 68             	pushl  0x68(%esi)
80104ae0:	e8 a3 cb ff ff       	call   80101688 <iput>
  end_op();
80104ae5:	e8 84 de ff ff       	call   8010296e <end_op>
  curproc->cwd = ip;
80104aea:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104aed:	83 c4 10             	add    $0x10,%esp
80104af0:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104af5:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104af8:	5b                   	pop    %ebx
80104af9:	5e                   	pop    %esi
80104afa:	5d                   	pop    %ebp
80104afb:	c3                   	ret    
    end_op();
80104afc:	e8 6d de ff ff       	call   8010296e <end_op>
    return -1;
80104b01:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b06:	eb ed                	jmp    80104af5 <sys_chdir+0x74>
    iunlockput(ip);
80104b08:	83 ec 0c             	sub    $0xc,%esp
80104b0b:	53                   	push   %ebx
80104b0c:	e8 17 cc ff ff       	call   80101728 <iunlockput>
    end_op();
80104b11:	e8 58 de ff ff       	call   8010296e <end_op>
    return -1;
80104b16:	83 c4 10             	add    $0x10,%esp
80104b19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b1e:	eb d5                	jmp    80104af5 <sys_chdir+0x74>

80104b20 <sys_exec>:

int
sys_exec(void)
{
80104b20:	55                   	push   %ebp
80104b21:	89 e5                	mov    %esp,%ebp
80104b23:	53                   	push   %ebx
80104b24:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104b2a:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b2d:	50                   	push   %eax
80104b2e:	6a 00                	push   $0x0
80104b30:	e8 38 f5 ff ff       	call   8010406d <argstr>
80104b35:	83 c4 10             	add    $0x10,%esp
80104b38:	85 c0                	test   %eax,%eax
80104b3a:	0f 88 a8 00 00 00    	js     80104be8 <sys_exec+0xc8>
80104b40:	83 ec 08             	sub    $0x8,%esp
80104b43:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104b49:	50                   	push   %eax
80104b4a:	6a 01                	push   $0x1
80104b4c:	e8 8c f4 ff ff       	call   80103fdd <argint>
80104b51:	83 c4 10             	add    $0x10,%esp
80104b54:	85 c0                	test   %eax,%eax
80104b56:	0f 88 93 00 00 00    	js     80104bef <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104b5c:	83 ec 04             	sub    $0x4,%esp
80104b5f:	68 80 00 00 00       	push   $0x80
80104b64:	6a 00                	push   $0x0
80104b66:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104b6c:	50                   	push   %eax
80104b6d:	e8 20 f2 ff ff       	call   80103d92 <memset>
80104b72:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104b75:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104b7a:	83 fb 1f             	cmp    $0x1f,%ebx
80104b7d:	77 77                	ja     80104bf6 <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104b7f:	83 ec 08             	sub    $0x8,%esp
80104b82:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104b88:	50                   	push   %eax
80104b89:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104b8f:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104b92:	50                   	push   %eax
80104b93:	e8 c9 f3 ff ff       	call   80103f61 <fetchint>
80104b98:	83 c4 10             	add    $0x10,%esp
80104b9b:	85 c0                	test   %eax,%eax
80104b9d:	78 5e                	js     80104bfd <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104b9f:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104ba5:	85 c0                	test   %eax,%eax
80104ba7:	74 1d                	je     80104bc6 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104ba9:	83 ec 08             	sub    $0x8,%esp
80104bac:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104bb3:	52                   	push   %edx
80104bb4:	50                   	push   %eax
80104bb5:	e8 e3 f3 ff ff       	call   80103f9d <fetchstr>
80104bba:	83 c4 10             	add    $0x10,%esp
80104bbd:	85 c0                	test   %eax,%eax
80104bbf:	78 46                	js     80104c07 <sys_exec+0xe7>
  for(i=0;; i++){
80104bc1:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104bc4:	eb b4                	jmp    80104b7a <sys_exec+0x5a>
      argv[i] = 0;
80104bc6:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104bcd:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104bd1:	83 ec 08             	sub    $0x8,%esp
80104bd4:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104bda:	50                   	push   %eax
80104bdb:	ff 75 f4             	pushl  -0xc(%ebp)
80104bde:	e8 ef bc ff ff       	call   801008d2 <exec>
80104be3:	83 c4 10             	add    $0x10,%esp
80104be6:	eb 1a                	jmp    80104c02 <sys_exec+0xe2>
    return -1;
80104be8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bed:	eb 13                	jmp    80104c02 <sys_exec+0xe2>
80104bef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bf4:	eb 0c                	jmp    80104c02 <sys_exec+0xe2>
      return -1;
80104bf6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bfb:	eb 05                	jmp    80104c02 <sys_exec+0xe2>
      return -1;
80104bfd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104c02:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104c05:	c9                   	leave  
80104c06:	c3                   	ret    
      return -1;
80104c07:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c0c:	eb f4                	jmp    80104c02 <sys_exec+0xe2>

80104c0e <sys_pipe>:

int
sys_pipe(void)
{
80104c0e:	55                   	push   %ebp
80104c0f:	89 e5                	mov    %esp,%ebp
80104c11:	53                   	push   %ebx
80104c12:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104c15:	6a 08                	push   $0x8
80104c17:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c1a:	50                   	push   %eax
80104c1b:	6a 00                	push   $0x0
80104c1d:	e8 e3 f3 ff ff       	call   80104005 <argptr>
80104c22:	83 c4 10             	add    $0x10,%esp
80104c25:	85 c0                	test   %eax,%eax
80104c27:	78 77                	js     80104ca0 <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104c29:	83 ec 08             	sub    $0x8,%esp
80104c2c:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104c2f:	50                   	push   %eax
80104c30:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104c33:	50                   	push   %eax
80104c34:	e8 42 e2 ff ff       	call   80102e7b <pipealloc>
80104c39:	83 c4 10             	add    $0x10,%esp
80104c3c:	85 c0                	test   %eax,%eax
80104c3e:	78 67                	js     80104ca7 <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104c40:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c43:	e8 14 f5 ff ff       	call   8010415c <fdalloc>
80104c48:	89 c3                	mov    %eax,%ebx
80104c4a:	85 c0                	test   %eax,%eax
80104c4c:	78 21                	js     80104c6f <sys_pipe+0x61>
80104c4e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104c51:	e8 06 f5 ff ff       	call   8010415c <fdalloc>
80104c56:	85 c0                	test   %eax,%eax
80104c58:	78 15                	js     80104c6f <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104c5a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c5d:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104c5f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c62:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104c65:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104c6a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104c6d:	c9                   	leave  
80104c6e:	c3                   	ret    
    if(fd0 >= 0)
80104c6f:	85 db                	test   %ebx,%ebx
80104c71:	78 0d                	js     80104c80 <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104c73:	e8 cc e6 ff ff       	call   80103344 <myproc>
80104c78:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104c7f:	00 
    fileclose(rf);
80104c80:	83 ec 0c             	sub    $0xc,%esp
80104c83:	ff 75 f0             	pushl  -0x10(%ebp)
80104c86:	e8 48 c0 ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104c8b:	83 c4 04             	add    $0x4,%esp
80104c8e:	ff 75 ec             	pushl  -0x14(%ebp)
80104c91:	e8 3d c0 ff ff       	call   80100cd3 <fileclose>
    return -1;
80104c96:	83 c4 10             	add    $0x10,%esp
80104c99:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c9e:	eb ca                	jmp    80104c6a <sys_pipe+0x5c>
    return -1;
80104ca0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ca5:	eb c3                	jmp    80104c6a <sys_pipe+0x5c>
    return -1;
80104ca7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cac:	eb bc                	jmp    80104c6a <sys_pipe+0x5c>

80104cae <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104cae:	55                   	push   %ebp
80104caf:	89 e5                	mov    %esp,%ebp
80104cb1:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104cb4:	e8 03 e8 ff ff       	call   801034bc <fork>
}
80104cb9:	c9                   	leave  
80104cba:	c3                   	ret    

80104cbb <sys_exit>:

int
sys_exit(void)
{
80104cbb:	55                   	push   %ebp
80104cbc:	89 e5                	mov    %esp,%ebp
80104cbe:	83 ec 08             	sub    $0x8,%esp
  exit();
80104cc1:	e8 2d ea ff ff       	call   801036f3 <exit>
  return 0;  // not reached
}
80104cc6:	b8 00 00 00 00       	mov    $0x0,%eax
80104ccb:	c9                   	leave  
80104ccc:	c3                   	ret    

80104ccd <sys_wait>:

int
sys_wait(void)
{
80104ccd:	55                   	push   %ebp
80104cce:	89 e5                	mov    %esp,%ebp
80104cd0:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104cd3:	e8 a4 eb ff ff       	call   8010387c <wait>
}
80104cd8:	c9                   	leave  
80104cd9:	c3                   	ret    

80104cda <sys_kill>:

int
sys_kill(void)
{
80104cda:	55                   	push   %ebp
80104cdb:	89 e5                	mov    %esp,%ebp
80104cdd:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104ce0:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ce3:	50                   	push   %eax
80104ce4:	6a 00                	push   $0x0
80104ce6:	e8 f2 f2 ff ff       	call   80103fdd <argint>
80104ceb:	83 c4 10             	add    $0x10,%esp
80104cee:	85 c0                	test   %eax,%eax
80104cf0:	78 10                	js     80104d02 <sys_kill+0x28>
    return -1;
  return kill(pid);
80104cf2:	83 ec 0c             	sub    $0xc,%esp
80104cf5:	ff 75 f4             	pushl  -0xc(%ebp)
80104cf8:	e8 7c ec ff ff       	call   80103979 <kill>
80104cfd:	83 c4 10             	add    $0x10,%esp
}
80104d00:	c9                   	leave  
80104d01:	c3                   	ret    
    return -1;
80104d02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d07:	eb f7                	jmp    80104d00 <sys_kill+0x26>

80104d09 <sys_getpid>:

int
sys_getpid(void)
{
80104d09:	55                   	push   %ebp
80104d0a:	89 e5                	mov    %esp,%ebp
80104d0c:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104d0f:	e8 30 e6 ff ff       	call   80103344 <myproc>
80104d14:	8b 40 10             	mov    0x10(%eax),%eax
}
80104d17:	c9                   	leave  
80104d18:	c3                   	ret    

80104d19 <sys_sbrk>:

int
sys_sbrk(void)
{
80104d19:	55                   	push   %ebp
80104d1a:	89 e5                	mov    %esp,%ebp
80104d1c:	53                   	push   %ebx
80104d1d:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104d20:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d23:	50                   	push   %eax
80104d24:	6a 00                	push   $0x0
80104d26:	e8 b2 f2 ff ff       	call   80103fdd <argint>
80104d2b:	83 c4 10             	add    $0x10,%esp
80104d2e:	85 c0                	test   %eax,%eax
80104d30:	78 27                	js     80104d59 <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104d32:	e8 0d e6 ff ff       	call   80103344 <myproc>
80104d37:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104d39:	83 ec 0c             	sub    $0xc,%esp
80104d3c:	ff 75 f4             	pushl  -0xc(%ebp)
80104d3f:	e8 0b e7 ff ff       	call   8010344f <growproc>
80104d44:	83 c4 10             	add    $0x10,%esp
80104d47:	85 c0                	test   %eax,%eax
80104d49:	78 07                	js     80104d52 <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104d4b:	89 d8                	mov    %ebx,%eax
80104d4d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104d50:	c9                   	leave  
80104d51:	c3                   	ret    
    return -1;
80104d52:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104d57:	eb f2                	jmp    80104d4b <sys_sbrk+0x32>
    return -1;
80104d59:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104d5e:	eb eb                	jmp    80104d4b <sys_sbrk+0x32>

80104d60 <sys_sleep>:

int
sys_sleep(void)
{
80104d60:	55                   	push   %ebp
80104d61:	89 e5                	mov    %esp,%ebp
80104d63:	53                   	push   %ebx
80104d64:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104d67:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d6a:	50                   	push   %eax
80104d6b:	6a 00                	push   $0x0
80104d6d:	e8 6b f2 ff ff       	call   80103fdd <argint>
80104d72:	83 c4 10             	add    $0x10,%esp
80104d75:	85 c0                	test   %eax,%eax
80104d77:	78 75                	js     80104dee <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104d79:	83 ec 0c             	sub    $0xc,%esp
80104d7c:	68 e0 4c 13 80       	push   $0x80134ce0
80104d81:	e8 60 ef ff ff       	call   80103ce6 <acquire>
  ticks0 = ticks;
80104d86:	8b 1d 20 55 13 80    	mov    0x80135520,%ebx
  while(ticks - ticks0 < n){
80104d8c:	83 c4 10             	add    $0x10,%esp
80104d8f:	a1 20 55 13 80       	mov    0x80135520,%eax
80104d94:	29 d8                	sub    %ebx,%eax
80104d96:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104d99:	73 39                	jae    80104dd4 <sys_sleep+0x74>
    if(myproc()->killed){
80104d9b:	e8 a4 e5 ff ff       	call   80103344 <myproc>
80104da0:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104da4:	75 17                	jne    80104dbd <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104da6:	83 ec 08             	sub    $0x8,%esp
80104da9:	68 e0 4c 13 80       	push   $0x80134ce0
80104dae:	68 20 55 13 80       	push   $0x80135520
80104db3:	e8 33 ea ff ff       	call   801037eb <sleep>
80104db8:	83 c4 10             	add    $0x10,%esp
80104dbb:	eb d2                	jmp    80104d8f <sys_sleep+0x2f>
      release(&tickslock);
80104dbd:	83 ec 0c             	sub    $0xc,%esp
80104dc0:	68 e0 4c 13 80       	push   $0x80134ce0
80104dc5:	e8 81 ef ff ff       	call   80103d4b <release>
      return -1;
80104dca:	83 c4 10             	add    $0x10,%esp
80104dcd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dd2:	eb 15                	jmp    80104de9 <sys_sleep+0x89>
  }
  release(&tickslock);
80104dd4:	83 ec 0c             	sub    $0xc,%esp
80104dd7:	68 e0 4c 13 80       	push   $0x80134ce0
80104ddc:	e8 6a ef ff ff       	call   80103d4b <release>
  return 0;
80104de1:	83 c4 10             	add    $0x10,%esp
80104de4:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104de9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104dec:	c9                   	leave  
80104ded:	c3                   	ret    
    return -1;
80104dee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104df3:	eb f4                	jmp    80104de9 <sys_sleep+0x89>

80104df5 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104df5:	55                   	push   %ebp
80104df6:	89 e5                	mov    %esp,%ebp
80104df8:	53                   	push   %ebx
80104df9:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104dfc:	68 e0 4c 13 80       	push   $0x80134ce0
80104e01:	e8 e0 ee ff ff       	call   80103ce6 <acquire>
  xticks = ticks;
80104e06:	8b 1d 20 55 13 80    	mov    0x80135520,%ebx
  release(&tickslock);
80104e0c:	c7 04 24 e0 4c 13 80 	movl   $0x80134ce0,(%esp)
80104e13:	e8 33 ef ff ff       	call   80103d4b <release>
  return xticks;
}
80104e18:	89 d8                	mov    %ebx,%eax
80104e1a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e1d:	c9                   	leave  
80104e1e:	c3                   	ret    

80104e1f <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80104e1f:	55                   	push   %ebp
80104e20:	89 e5                	mov    %esp,%ebp
80104e22:	83 ec 1c             	sub    $0x1c,%esp
  int *frames;
  int *pids;
  int numframes;
  if(argptr(0, (char**)(&frames), sizeof(*frames)) < 0)
80104e25:	6a 04                	push   $0x4
80104e27:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e2a:	50                   	push   %eax
80104e2b:	6a 00                	push   $0x0
80104e2d:	e8 d3 f1 ff ff       	call   80104005 <argptr>
80104e32:	83 c4 10             	add    $0x10,%esp
80104e35:	85 c0                	test   %eax,%eax
80104e37:	78 42                	js     80104e7b <sys_dump_physmem+0x5c>
    return -1;
  if(argptr(1, (char**)(&pids), sizeof(*pids)) < 0)
80104e39:	83 ec 04             	sub    $0x4,%esp
80104e3c:	6a 04                	push   $0x4
80104e3e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104e41:	50                   	push   %eax
80104e42:	6a 01                	push   $0x1
80104e44:	e8 bc f1 ff ff       	call   80104005 <argptr>
80104e49:	83 c4 10             	add    $0x10,%esp
80104e4c:	85 c0                	test   %eax,%eax
80104e4e:	78 32                	js     80104e82 <sys_dump_physmem+0x63>
    return -1;
  if(argint(2, &numframes) < 0)
80104e50:	83 ec 08             	sub    $0x8,%esp
80104e53:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104e56:	50                   	push   %eax
80104e57:	6a 02                	push   $0x2
80104e59:	e8 7f f1 ff ff       	call   80103fdd <argint>
80104e5e:	83 c4 10             	add    $0x10,%esp
80104e61:	85 c0                	test   %eax,%eax
80104e63:	78 24                	js     80104e89 <sys_dump_physmem+0x6a>
    return -1;

  return dump_physmem(frames, pids, numframes);
80104e65:	83 ec 04             	sub    $0x4,%esp
80104e68:	ff 75 ec             	pushl  -0x14(%ebp)
80104e6b:	ff 75 f0             	pushl  -0x10(%ebp)
80104e6e:	ff 75 f4             	pushl  -0xc(%ebp)
80104e71:	e8 7e d3 ff ff       	call   801021f4 <dump_physmem>
80104e76:	83 c4 10             	add    $0x10,%esp
80104e79:	c9                   	leave  
80104e7a:	c3                   	ret    
    return -1;
80104e7b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e80:	eb f7                	jmp    80104e79 <sys_dump_physmem+0x5a>
    return -1;
80104e82:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e87:	eb f0                	jmp    80104e79 <sys_dump_physmem+0x5a>
    return -1;
80104e89:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e8e:	eb e9                	jmp    80104e79 <sys_dump_physmem+0x5a>

80104e90 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104e90:	1e                   	push   %ds
  pushl %es
80104e91:	06                   	push   %es
  pushl %fs
80104e92:	0f a0                	push   %fs
  pushl %gs
80104e94:	0f a8                	push   %gs
  pushal
80104e96:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104e97:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104e9b:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104e9d:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104e9f:	54                   	push   %esp
  call trap
80104ea0:	e8 e3 00 00 00       	call   80104f88 <trap>
  addl $4, %esp
80104ea5:	83 c4 04             	add    $0x4,%esp

80104ea8 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104ea8:	61                   	popa   
  popl %gs
80104ea9:	0f a9                	pop    %gs
  popl %fs
80104eab:	0f a1                	pop    %fs
  popl %es
80104ead:	07                   	pop    %es
  popl %ds
80104eae:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104eaf:	83 c4 08             	add    $0x8,%esp
  iret
80104eb2:	cf                   	iret   

80104eb3 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80104eb3:	55                   	push   %ebp
80104eb4:	89 e5                	mov    %esp,%ebp
80104eb6:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
80104eb9:	b8 00 00 00 00       	mov    $0x0,%eax
80104ebe:	eb 4a                	jmp    80104f0a <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104ec0:	8b 0c 85 08 a0 10 80 	mov    -0x7fef5ff8(,%eax,4),%ecx
80104ec7:	66 89 0c c5 20 4d 13 	mov    %cx,-0x7fecb2e0(,%eax,8)
80104ece:	80 
80104ecf:	66 c7 04 c5 22 4d 13 	movw   $0x8,-0x7fecb2de(,%eax,8)
80104ed6:	80 08 00 
80104ed9:	c6 04 c5 24 4d 13 80 	movb   $0x0,-0x7fecb2dc(,%eax,8)
80104ee0:	00 
80104ee1:	0f b6 14 c5 25 4d 13 	movzbl -0x7fecb2db(,%eax,8),%edx
80104ee8:	80 
80104ee9:	83 e2 f0             	and    $0xfffffff0,%edx
80104eec:	83 ca 0e             	or     $0xe,%edx
80104eef:	83 e2 8f             	and    $0xffffff8f,%edx
80104ef2:	83 ca 80             	or     $0xffffff80,%edx
80104ef5:	88 14 c5 25 4d 13 80 	mov    %dl,-0x7fecb2db(,%eax,8)
80104efc:	c1 e9 10             	shr    $0x10,%ecx
80104eff:	66 89 0c c5 26 4d 13 	mov    %cx,-0x7fecb2da(,%eax,8)
80104f06:	80 
  for(i = 0; i < 256; i++)
80104f07:	83 c0 01             	add    $0x1,%eax
80104f0a:	3d ff 00 00 00       	cmp    $0xff,%eax
80104f0f:	7e af                	jle    80104ec0 <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80104f11:	8b 15 08 a1 10 80    	mov    0x8010a108,%edx
80104f17:	66 89 15 20 4f 13 80 	mov    %dx,0x80134f20
80104f1e:	66 c7 05 22 4f 13 80 	movw   $0x8,0x80134f22
80104f25:	08 00 
80104f27:	c6 05 24 4f 13 80 00 	movb   $0x0,0x80134f24
80104f2e:	0f b6 05 25 4f 13 80 	movzbl 0x80134f25,%eax
80104f35:	83 c8 0f             	or     $0xf,%eax
80104f38:	83 e0 ef             	and    $0xffffffef,%eax
80104f3b:	83 c8 e0             	or     $0xffffffe0,%eax
80104f3e:	a2 25 4f 13 80       	mov    %al,0x80134f25
80104f43:	c1 ea 10             	shr    $0x10,%edx
80104f46:	66 89 15 26 4f 13 80 	mov    %dx,0x80134f26

  initlock(&tickslock, "time");
80104f4d:	83 ec 08             	sub    $0x8,%esp
80104f50:	68 bd 6d 10 80       	push   $0x80106dbd
80104f55:	68 e0 4c 13 80       	push   $0x80134ce0
80104f5a:	e8 4b ec ff ff       	call   80103baa <initlock>
}
80104f5f:	83 c4 10             	add    $0x10,%esp
80104f62:	c9                   	leave  
80104f63:	c3                   	ret    

80104f64 <idtinit>:

void
idtinit(void)
{
80104f64:	55                   	push   %ebp
80104f65:	89 e5                	mov    %esp,%ebp
80104f67:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80104f6a:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80104f70:	b8 20 4d 13 80       	mov    $0x80134d20,%eax
80104f75:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80104f79:	c1 e8 10             	shr    $0x10,%eax
80104f7c:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
80104f80:	8d 45 fa             	lea    -0x6(%ebp),%eax
80104f83:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80104f86:	c9                   	leave  
80104f87:	c3                   	ret    

80104f88 <trap>:

void
trap(struct trapframe *tf)
{
80104f88:	55                   	push   %ebp
80104f89:	89 e5                	mov    %esp,%ebp
80104f8b:	57                   	push   %edi
80104f8c:	56                   	push   %esi
80104f8d:	53                   	push   %ebx
80104f8e:	83 ec 1c             	sub    $0x1c,%esp
80104f91:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80104f94:	8b 43 30             	mov    0x30(%ebx),%eax
80104f97:	83 f8 40             	cmp    $0x40,%eax
80104f9a:	74 13                	je     80104faf <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
80104f9c:	83 e8 20             	sub    $0x20,%eax
80104f9f:	83 f8 1f             	cmp    $0x1f,%eax
80104fa2:	0f 87 3a 01 00 00    	ja     801050e2 <trap+0x15a>
80104fa8:	ff 24 85 64 6e 10 80 	jmp    *-0x7fef919c(,%eax,4)
    if(myproc()->killed)
80104faf:	e8 90 e3 ff ff       	call   80103344 <myproc>
80104fb4:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104fb8:	75 1f                	jne    80104fd9 <trap+0x51>
    myproc()->tf = tf;
80104fba:	e8 85 e3 ff ff       	call   80103344 <myproc>
80104fbf:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80104fc2:	e8 d9 f0 ff ff       	call   801040a0 <syscall>
    if(myproc()->killed)
80104fc7:	e8 78 e3 ff ff       	call   80103344 <myproc>
80104fcc:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104fd0:	74 7e                	je     80105050 <trap+0xc8>
      exit();
80104fd2:	e8 1c e7 ff ff       	call   801036f3 <exit>
80104fd7:	eb 77                	jmp    80105050 <trap+0xc8>
      exit();
80104fd9:	e8 15 e7 ff ff       	call   801036f3 <exit>
80104fde:	eb da                	jmp    80104fba <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80104fe0:	e8 44 e3 ff ff       	call   80103329 <cpuid>
80104fe5:	85 c0                	test   %eax,%eax
80104fe7:	74 6f                	je     80105058 <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
80104fe9:	e8 f1 d4 ff ff       	call   801024df <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80104fee:	e8 51 e3 ff ff       	call   80103344 <myproc>
80104ff3:	85 c0                	test   %eax,%eax
80104ff5:	74 1c                	je     80105013 <trap+0x8b>
80104ff7:	e8 48 e3 ff ff       	call   80103344 <myproc>
80104ffc:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105000:	74 11                	je     80105013 <trap+0x8b>
80105002:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105006:	83 e0 03             	and    $0x3,%eax
80105009:	66 83 f8 03          	cmp    $0x3,%ax
8010500d:	0f 84 62 01 00 00    	je     80105175 <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80105013:	e8 2c e3 ff ff       	call   80103344 <myproc>
80105018:	85 c0                	test   %eax,%eax
8010501a:	74 0f                	je     8010502b <trap+0xa3>
8010501c:	e8 23 e3 ff ff       	call   80103344 <myproc>
80105021:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80105025:	0f 84 54 01 00 00    	je     8010517f <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
8010502b:	e8 14 e3 ff ff       	call   80103344 <myproc>
80105030:	85 c0                	test   %eax,%eax
80105032:	74 1c                	je     80105050 <trap+0xc8>
80105034:	e8 0b e3 ff ff       	call   80103344 <myproc>
80105039:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010503d:	74 11                	je     80105050 <trap+0xc8>
8010503f:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105043:	83 e0 03             	and    $0x3,%eax
80105046:	66 83 f8 03          	cmp    $0x3,%ax
8010504a:	0f 84 43 01 00 00    	je     80105193 <trap+0x20b>
    exit();
}
80105050:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105053:	5b                   	pop    %ebx
80105054:	5e                   	pop    %esi
80105055:	5f                   	pop    %edi
80105056:	5d                   	pop    %ebp
80105057:	c3                   	ret    
      acquire(&tickslock);
80105058:	83 ec 0c             	sub    $0xc,%esp
8010505b:	68 e0 4c 13 80       	push   $0x80134ce0
80105060:	e8 81 ec ff ff       	call   80103ce6 <acquire>
      ticks++;
80105065:	83 05 20 55 13 80 01 	addl   $0x1,0x80135520
      wakeup(&ticks);
8010506c:	c7 04 24 20 55 13 80 	movl   $0x80135520,(%esp)
80105073:	e8 d8 e8 ff ff       	call   80103950 <wakeup>
      release(&tickslock);
80105078:	c7 04 24 e0 4c 13 80 	movl   $0x80134ce0,(%esp)
8010507f:	e8 c7 ec ff ff       	call   80103d4b <release>
80105084:	83 c4 10             	add    $0x10,%esp
80105087:	e9 5d ff ff ff       	jmp    80104fe9 <trap+0x61>
    ideintr();
8010508c:	e8 e2 cc ff ff       	call   80101d73 <ideintr>
    lapiceoi();
80105091:	e8 49 d4 ff ff       	call   801024df <lapiceoi>
    break;
80105096:	e9 53 ff ff ff       	jmp    80104fee <trap+0x66>
    kbdintr();
8010509b:	e8 83 d2 ff ff       	call   80102323 <kbdintr>
    lapiceoi();
801050a0:	e8 3a d4 ff ff       	call   801024df <lapiceoi>
    break;
801050a5:	e9 44 ff ff ff       	jmp    80104fee <trap+0x66>
    uartintr();
801050aa:	e8 05 02 00 00       	call   801052b4 <uartintr>
    lapiceoi();
801050af:	e8 2b d4 ff ff       	call   801024df <lapiceoi>
    break;
801050b4:	e9 35 ff ff ff       	jmp    80104fee <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801050b9:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
801050bc:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801050c0:	e8 64 e2 ff ff       	call   80103329 <cpuid>
801050c5:	57                   	push   %edi
801050c6:	0f b7 f6             	movzwl %si,%esi
801050c9:	56                   	push   %esi
801050ca:	50                   	push   %eax
801050cb:	68 c8 6d 10 80       	push   $0x80106dc8
801050d0:	e8 36 b5 ff ff       	call   8010060b <cprintf>
    lapiceoi();
801050d5:	e8 05 d4 ff ff       	call   801024df <lapiceoi>
    break;
801050da:	83 c4 10             	add    $0x10,%esp
801050dd:	e9 0c ff ff ff       	jmp    80104fee <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
801050e2:	e8 5d e2 ff ff       	call   80103344 <myproc>
801050e7:	85 c0                	test   %eax,%eax
801050e9:	74 5f                	je     8010514a <trap+0x1c2>
801050eb:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
801050ef:	74 59                	je     8010514a <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801050f1:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801050f4:	8b 43 38             	mov    0x38(%ebx),%eax
801050f7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801050fa:	e8 2a e2 ff ff       	call   80103329 <cpuid>
801050ff:	89 45 e0             	mov    %eax,-0x20(%ebp)
80105102:	8b 53 34             	mov    0x34(%ebx),%edx
80105105:	89 55 dc             	mov    %edx,-0x24(%ebp)
80105108:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
8010510b:	e8 34 e2 ff ff       	call   80103344 <myproc>
80105110:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105113:	89 4d d8             	mov    %ecx,-0x28(%ebp)
80105116:	e8 29 e2 ff ff       	call   80103344 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010511b:	57                   	push   %edi
8010511c:	ff 75 e4             	pushl  -0x1c(%ebp)
8010511f:	ff 75 e0             	pushl  -0x20(%ebp)
80105122:	ff 75 dc             	pushl  -0x24(%ebp)
80105125:	56                   	push   %esi
80105126:	ff 75 d8             	pushl  -0x28(%ebp)
80105129:	ff 70 10             	pushl  0x10(%eax)
8010512c:	68 20 6e 10 80       	push   $0x80106e20
80105131:	e8 d5 b4 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
80105136:	83 c4 20             	add    $0x20,%esp
80105139:	e8 06 e2 ff ff       	call   80103344 <myproc>
8010513e:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80105145:	e9 a4 fe ff ff       	jmp    80104fee <trap+0x66>
8010514a:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010514d:	8b 73 38             	mov    0x38(%ebx),%esi
80105150:	e8 d4 e1 ff ff       	call   80103329 <cpuid>
80105155:	83 ec 0c             	sub    $0xc,%esp
80105158:	57                   	push   %edi
80105159:	56                   	push   %esi
8010515a:	50                   	push   %eax
8010515b:	ff 73 30             	pushl  0x30(%ebx)
8010515e:	68 ec 6d 10 80       	push   $0x80106dec
80105163:	e8 a3 b4 ff ff       	call   8010060b <cprintf>
      panic("trap");
80105168:	83 c4 14             	add    $0x14,%esp
8010516b:	68 c2 6d 10 80       	push   $0x80106dc2
80105170:	e8 d3 b1 ff ff       	call   80100348 <panic>
    exit();
80105175:	e8 79 e5 ff ff       	call   801036f3 <exit>
8010517a:	e9 94 fe ff ff       	jmp    80105013 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
8010517f:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
80105183:	0f 85 a2 fe ff ff    	jne    8010502b <trap+0xa3>
    yield();
80105189:	e8 2b e6 ff ff       	call   801037b9 <yield>
8010518e:	e9 98 fe ff ff       	jmp    8010502b <trap+0xa3>
    exit();
80105193:	e8 5b e5 ff ff       	call   801036f3 <exit>
80105198:	e9 b3 fe ff ff       	jmp    80105050 <trap+0xc8>

8010519d <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
8010519d:	55                   	push   %ebp
8010519e:	89 e5                	mov    %esp,%ebp
  if(!uart)
801051a0:	83 3d c0 a5 10 80 00 	cmpl   $0x0,0x8010a5c0
801051a7:	74 15                	je     801051be <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801051a9:	ba fd 03 00 00       	mov    $0x3fd,%edx
801051ae:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
801051af:	a8 01                	test   $0x1,%al
801051b1:	74 12                	je     801051c5 <uartgetc+0x28>
801051b3:	ba f8 03 00 00       	mov    $0x3f8,%edx
801051b8:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
801051b9:	0f b6 c0             	movzbl %al,%eax
}
801051bc:	5d                   	pop    %ebp
801051bd:	c3                   	ret    
    return -1;
801051be:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051c3:	eb f7                	jmp    801051bc <uartgetc+0x1f>
    return -1;
801051c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051ca:	eb f0                	jmp    801051bc <uartgetc+0x1f>

801051cc <uartputc>:
  if(!uart)
801051cc:	83 3d c0 a5 10 80 00 	cmpl   $0x0,0x8010a5c0
801051d3:	74 3b                	je     80105210 <uartputc+0x44>
{
801051d5:	55                   	push   %ebp
801051d6:	89 e5                	mov    %esp,%ebp
801051d8:	53                   	push   %ebx
801051d9:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801051dc:	bb 00 00 00 00       	mov    $0x0,%ebx
801051e1:	eb 10                	jmp    801051f3 <uartputc+0x27>
    microdelay(10);
801051e3:	83 ec 0c             	sub    $0xc,%esp
801051e6:	6a 0a                	push   $0xa
801051e8:	e8 11 d3 ff ff       	call   801024fe <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801051ed:	83 c3 01             	add    $0x1,%ebx
801051f0:	83 c4 10             	add    $0x10,%esp
801051f3:	83 fb 7f             	cmp    $0x7f,%ebx
801051f6:	7f 0a                	jg     80105202 <uartputc+0x36>
801051f8:	ba fd 03 00 00       	mov    $0x3fd,%edx
801051fd:	ec                   	in     (%dx),%al
801051fe:	a8 20                	test   $0x20,%al
80105200:	74 e1                	je     801051e3 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80105202:	8b 45 08             	mov    0x8(%ebp),%eax
80105205:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010520a:	ee                   	out    %al,(%dx)
}
8010520b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010520e:	c9                   	leave  
8010520f:	c3                   	ret    
80105210:	f3 c3                	repz ret 

80105212 <uartinit>:
{
80105212:	55                   	push   %ebp
80105213:	89 e5                	mov    %esp,%ebp
80105215:	56                   	push   %esi
80105216:	53                   	push   %ebx
80105217:	b9 00 00 00 00       	mov    $0x0,%ecx
8010521c:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105221:	89 c8                	mov    %ecx,%eax
80105223:	ee                   	out    %al,(%dx)
80105224:	be fb 03 00 00       	mov    $0x3fb,%esi
80105229:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
8010522e:	89 f2                	mov    %esi,%edx
80105230:	ee                   	out    %al,(%dx)
80105231:	b8 0c 00 00 00       	mov    $0xc,%eax
80105236:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010523b:	ee                   	out    %al,(%dx)
8010523c:	bb f9 03 00 00       	mov    $0x3f9,%ebx
80105241:	89 c8                	mov    %ecx,%eax
80105243:	89 da                	mov    %ebx,%edx
80105245:	ee                   	out    %al,(%dx)
80105246:	b8 03 00 00 00       	mov    $0x3,%eax
8010524b:	89 f2                	mov    %esi,%edx
8010524d:	ee                   	out    %al,(%dx)
8010524e:	ba fc 03 00 00       	mov    $0x3fc,%edx
80105253:	89 c8                	mov    %ecx,%eax
80105255:	ee                   	out    %al,(%dx)
80105256:	b8 01 00 00 00       	mov    $0x1,%eax
8010525b:	89 da                	mov    %ebx,%edx
8010525d:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010525e:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105263:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
80105264:	3c ff                	cmp    $0xff,%al
80105266:	74 45                	je     801052ad <uartinit+0x9b>
  uart = 1;
80105268:	c7 05 c0 a5 10 80 01 	movl   $0x1,0x8010a5c0
8010526f:	00 00 00 
80105272:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105277:	ec                   	in     (%dx),%al
80105278:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010527d:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
8010527e:	83 ec 08             	sub    $0x8,%esp
80105281:	6a 00                	push   $0x0
80105283:	6a 04                	push   $0x4
80105285:	e8 f4 cc ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
8010528a:	83 c4 10             	add    $0x10,%esp
8010528d:	bb e4 6e 10 80       	mov    $0x80106ee4,%ebx
80105292:	eb 12                	jmp    801052a6 <uartinit+0x94>
    uartputc(*p);
80105294:	83 ec 0c             	sub    $0xc,%esp
80105297:	0f be c0             	movsbl %al,%eax
8010529a:	50                   	push   %eax
8010529b:	e8 2c ff ff ff       	call   801051cc <uartputc>
  for(p="xv6...\n"; *p; p++)
801052a0:	83 c3 01             	add    $0x1,%ebx
801052a3:	83 c4 10             	add    $0x10,%esp
801052a6:	0f b6 03             	movzbl (%ebx),%eax
801052a9:	84 c0                	test   %al,%al
801052ab:	75 e7                	jne    80105294 <uartinit+0x82>
}
801052ad:	8d 65 f8             	lea    -0x8(%ebp),%esp
801052b0:	5b                   	pop    %ebx
801052b1:	5e                   	pop    %esi
801052b2:	5d                   	pop    %ebp
801052b3:	c3                   	ret    

801052b4 <uartintr>:

void
uartintr(void)
{
801052b4:	55                   	push   %ebp
801052b5:	89 e5                	mov    %esp,%ebp
801052b7:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
801052ba:	68 9d 51 10 80       	push   $0x8010519d
801052bf:	e8 7a b4 ff ff       	call   8010073e <consoleintr>
}
801052c4:	83 c4 10             	add    $0x10,%esp
801052c7:	c9                   	leave  
801052c8:	c3                   	ret    

801052c9 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801052c9:	6a 00                	push   $0x0
  pushl $0
801052cb:	6a 00                	push   $0x0
  jmp alltraps
801052cd:	e9 be fb ff ff       	jmp    80104e90 <alltraps>

801052d2 <vector1>:
.globl vector1
vector1:
  pushl $0
801052d2:	6a 00                	push   $0x0
  pushl $1
801052d4:	6a 01                	push   $0x1
  jmp alltraps
801052d6:	e9 b5 fb ff ff       	jmp    80104e90 <alltraps>

801052db <vector2>:
.globl vector2
vector2:
  pushl $0
801052db:	6a 00                	push   $0x0
  pushl $2
801052dd:	6a 02                	push   $0x2
  jmp alltraps
801052df:	e9 ac fb ff ff       	jmp    80104e90 <alltraps>

801052e4 <vector3>:
.globl vector3
vector3:
  pushl $0
801052e4:	6a 00                	push   $0x0
  pushl $3
801052e6:	6a 03                	push   $0x3
  jmp alltraps
801052e8:	e9 a3 fb ff ff       	jmp    80104e90 <alltraps>

801052ed <vector4>:
.globl vector4
vector4:
  pushl $0
801052ed:	6a 00                	push   $0x0
  pushl $4
801052ef:	6a 04                	push   $0x4
  jmp alltraps
801052f1:	e9 9a fb ff ff       	jmp    80104e90 <alltraps>

801052f6 <vector5>:
.globl vector5
vector5:
  pushl $0
801052f6:	6a 00                	push   $0x0
  pushl $5
801052f8:	6a 05                	push   $0x5
  jmp alltraps
801052fa:	e9 91 fb ff ff       	jmp    80104e90 <alltraps>

801052ff <vector6>:
.globl vector6
vector6:
  pushl $0
801052ff:	6a 00                	push   $0x0
  pushl $6
80105301:	6a 06                	push   $0x6
  jmp alltraps
80105303:	e9 88 fb ff ff       	jmp    80104e90 <alltraps>

80105308 <vector7>:
.globl vector7
vector7:
  pushl $0
80105308:	6a 00                	push   $0x0
  pushl $7
8010530a:	6a 07                	push   $0x7
  jmp alltraps
8010530c:	e9 7f fb ff ff       	jmp    80104e90 <alltraps>

80105311 <vector8>:
.globl vector8
vector8:
  pushl $8
80105311:	6a 08                	push   $0x8
  jmp alltraps
80105313:	e9 78 fb ff ff       	jmp    80104e90 <alltraps>

80105318 <vector9>:
.globl vector9
vector9:
  pushl $0
80105318:	6a 00                	push   $0x0
  pushl $9
8010531a:	6a 09                	push   $0x9
  jmp alltraps
8010531c:	e9 6f fb ff ff       	jmp    80104e90 <alltraps>

80105321 <vector10>:
.globl vector10
vector10:
  pushl $10
80105321:	6a 0a                	push   $0xa
  jmp alltraps
80105323:	e9 68 fb ff ff       	jmp    80104e90 <alltraps>

80105328 <vector11>:
.globl vector11
vector11:
  pushl $11
80105328:	6a 0b                	push   $0xb
  jmp alltraps
8010532a:	e9 61 fb ff ff       	jmp    80104e90 <alltraps>

8010532f <vector12>:
.globl vector12
vector12:
  pushl $12
8010532f:	6a 0c                	push   $0xc
  jmp alltraps
80105331:	e9 5a fb ff ff       	jmp    80104e90 <alltraps>

80105336 <vector13>:
.globl vector13
vector13:
  pushl $13
80105336:	6a 0d                	push   $0xd
  jmp alltraps
80105338:	e9 53 fb ff ff       	jmp    80104e90 <alltraps>

8010533d <vector14>:
.globl vector14
vector14:
  pushl $14
8010533d:	6a 0e                	push   $0xe
  jmp alltraps
8010533f:	e9 4c fb ff ff       	jmp    80104e90 <alltraps>

80105344 <vector15>:
.globl vector15
vector15:
  pushl $0
80105344:	6a 00                	push   $0x0
  pushl $15
80105346:	6a 0f                	push   $0xf
  jmp alltraps
80105348:	e9 43 fb ff ff       	jmp    80104e90 <alltraps>

8010534d <vector16>:
.globl vector16
vector16:
  pushl $0
8010534d:	6a 00                	push   $0x0
  pushl $16
8010534f:	6a 10                	push   $0x10
  jmp alltraps
80105351:	e9 3a fb ff ff       	jmp    80104e90 <alltraps>

80105356 <vector17>:
.globl vector17
vector17:
  pushl $17
80105356:	6a 11                	push   $0x11
  jmp alltraps
80105358:	e9 33 fb ff ff       	jmp    80104e90 <alltraps>

8010535d <vector18>:
.globl vector18
vector18:
  pushl $0
8010535d:	6a 00                	push   $0x0
  pushl $18
8010535f:	6a 12                	push   $0x12
  jmp alltraps
80105361:	e9 2a fb ff ff       	jmp    80104e90 <alltraps>

80105366 <vector19>:
.globl vector19
vector19:
  pushl $0
80105366:	6a 00                	push   $0x0
  pushl $19
80105368:	6a 13                	push   $0x13
  jmp alltraps
8010536a:	e9 21 fb ff ff       	jmp    80104e90 <alltraps>

8010536f <vector20>:
.globl vector20
vector20:
  pushl $0
8010536f:	6a 00                	push   $0x0
  pushl $20
80105371:	6a 14                	push   $0x14
  jmp alltraps
80105373:	e9 18 fb ff ff       	jmp    80104e90 <alltraps>

80105378 <vector21>:
.globl vector21
vector21:
  pushl $0
80105378:	6a 00                	push   $0x0
  pushl $21
8010537a:	6a 15                	push   $0x15
  jmp alltraps
8010537c:	e9 0f fb ff ff       	jmp    80104e90 <alltraps>

80105381 <vector22>:
.globl vector22
vector22:
  pushl $0
80105381:	6a 00                	push   $0x0
  pushl $22
80105383:	6a 16                	push   $0x16
  jmp alltraps
80105385:	e9 06 fb ff ff       	jmp    80104e90 <alltraps>

8010538a <vector23>:
.globl vector23
vector23:
  pushl $0
8010538a:	6a 00                	push   $0x0
  pushl $23
8010538c:	6a 17                	push   $0x17
  jmp alltraps
8010538e:	e9 fd fa ff ff       	jmp    80104e90 <alltraps>

80105393 <vector24>:
.globl vector24
vector24:
  pushl $0
80105393:	6a 00                	push   $0x0
  pushl $24
80105395:	6a 18                	push   $0x18
  jmp alltraps
80105397:	e9 f4 fa ff ff       	jmp    80104e90 <alltraps>

8010539c <vector25>:
.globl vector25
vector25:
  pushl $0
8010539c:	6a 00                	push   $0x0
  pushl $25
8010539e:	6a 19                	push   $0x19
  jmp alltraps
801053a0:	e9 eb fa ff ff       	jmp    80104e90 <alltraps>

801053a5 <vector26>:
.globl vector26
vector26:
  pushl $0
801053a5:	6a 00                	push   $0x0
  pushl $26
801053a7:	6a 1a                	push   $0x1a
  jmp alltraps
801053a9:	e9 e2 fa ff ff       	jmp    80104e90 <alltraps>

801053ae <vector27>:
.globl vector27
vector27:
  pushl $0
801053ae:	6a 00                	push   $0x0
  pushl $27
801053b0:	6a 1b                	push   $0x1b
  jmp alltraps
801053b2:	e9 d9 fa ff ff       	jmp    80104e90 <alltraps>

801053b7 <vector28>:
.globl vector28
vector28:
  pushl $0
801053b7:	6a 00                	push   $0x0
  pushl $28
801053b9:	6a 1c                	push   $0x1c
  jmp alltraps
801053bb:	e9 d0 fa ff ff       	jmp    80104e90 <alltraps>

801053c0 <vector29>:
.globl vector29
vector29:
  pushl $0
801053c0:	6a 00                	push   $0x0
  pushl $29
801053c2:	6a 1d                	push   $0x1d
  jmp alltraps
801053c4:	e9 c7 fa ff ff       	jmp    80104e90 <alltraps>

801053c9 <vector30>:
.globl vector30
vector30:
  pushl $0
801053c9:	6a 00                	push   $0x0
  pushl $30
801053cb:	6a 1e                	push   $0x1e
  jmp alltraps
801053cd:	e9 be fa ff ff       	jmp    80104e90 <alltraps>

801053d2 <vector31>:
.globl vector31
vector31:
  pushl $0
801053d2:	6a 00                	push   $0x0
  pushl $31
801053d4:	6a 1f                	push   $0x1f
  jmp alltraps
801053d6:	e9 b5 fa ff ff       	jmp    80104e90 <alltraps>

801053db <vector32>:
.globl vector32
vector32:
  pushl $0
801053db:	6a 00                	push   $0x0
  pushl $32
801053dd:	6a 20                	push   $0x20
  jmp alltraps
801053df:	e9 ac fa ff ff       	jmp    80104e90 <alltraps>

801053e4 <vector33>:
.globl vector33
vector33:
  pushl $0
801053e4:	6a 00                	push   $0x0
  pushl $33
801053e6:	6a 21                	push   $0x21
  jmp alltraps
801053e8:	e9 a3 fa ff ff       	jmp    80104e90 <alltraps>

801053ed <vector34>:
.globl vector34
vector34:
  pushl $0
801053ed:	6a 00                	push   $0x0
  pushl $34
801053ef:	6a 22                	push   $0x22
  jmp alltraps
801053f1:	e9 9a fa ff ff       	jmp    80104e90 <alltraps>

801053f6 <vector35>:
.globl vector35
vector35:
  pushl $0
801053f6:	6a 00                	push   $0x0
  pushl $35
801053f8:	6a 23                	push   $0x23
  jmp alltraps
801053fa:	e9 91 fa ff ff       	jmp    80104e90 <alltraps>

801053ff <vector36>:
.globl vector36
vector36:
  pushl $0
801053ff:	6a 00                	push   $0x0
  pushl $36
80105401:	6a 24                	push   $0x24
  jmp alltraps
80105403:	e9 88 fa ff ff       	jmp    80104e90 <alltraps>

80105408 <vector37>:
.globl vector37
vector37:
  pushl $0
80105408:	6a 00                	push   $0x0
  pushl $37
8010540a:	6a 25                	push   $0x25
  jmp alltraps
8010540c:	e9 7f fa ff ff       	jmp    80104e90 <alltraps>

80105411 <vector38>:
.globl vector38
vector38:
  pushl $0
80105411:	6a 00                	push   $0x0
  pushl $38
80105413:	6a 26                	push   $0x26
  jmp alltraps
80105415:	e9 76 fa ff ff       	jmp    80104e90 <alltraps>

8010541a <vector39>:
.globl vector39
vector39:
  pushl $0
8010541a:	6a 00                	push   $0x0
  pushl $39
8010541c:	6a 27                	push   $0x27
  jmp alltraps
8010541e:	e9 6d fa ff ff       	jmp    80104e90 <alltraps>

80105423 <vector40>:
.globl vector40
vector40:
  pushl $0
80105423:	6a 00                	push   $0x0
  pushl $40
80105425:	6a 28                	push   $0x28
  jmp alltraps
80105427:	e9 64 fa ff ff       	jmp    80104e90 <alltraps>

8010542c <vector41>:
.globl vector41
vector41:
  pushl $0
8010542c:	6a 00                	push   $0x0
  pushl $41
8010542e:	6a 29                	push   $0x29
  jmp alltraps
80105430:	e9 5b fa ff ff       	jmp    80104e90 <alltraps>

80105435 <vector42>:
.globl vector42
vector42:
  pushl $0
80105435:	6a 00                	push   $0x0
  pushl $42
80105437:	6a 2a                	push   $0x2a
  jmp alltraps
80105439:	e9 52 fa ff ff       	jmp    80104e90 <alltraps>

8010543e <vector43>:
.globl vector43
vector43:
  pushl $0
8010543e:	6a 00                	push   $0x0
  pushl $43
80105440:	6a 2b                	push   $0x2b
  jmp alltraps
80105442:	e9 49 fa ff ff       	jmp    80104e90 <alltraps>

80105447 <vector44>:
.globl vector44
vector44:
  pushl $0
80105447:	6a 00                	push   $0x0
  pushl $44
80105449:	6a 2c                	push   $0x2c
  jmp alltraps
8010544b:	e9 40 fa ff ff       	jmp    80104e90 <alltraps>

80105450 <vector45>:
.globl vector45
vector45:
  pushl $0
80105450:	6a 00                	push   $0x0
  pushl $45
80105452:	6a 2d                	push   $0x2d
  jmp alltraps
80105454:	e9 37 fa ff ff       	jmp    80104e90 <alltraps>

80105459 <vector46>:
.globl vector46
vector46:
  pushl $0
80105459:	6a 00                	push   $0x0
  pushl $46
8010545b:	6a 2e                	push   $0x2e
  jmp alltraps
8010545d:	e9 2e fa ff ff       	jmp    80104e90 <alltraps>

80105462 <vector47>:
.globl vector47
vector47:
  pushl $0
80105462:	6a 00                	push   $0x0
  pushl $47
80105464:	6a 2f                	push   $0x2f
  jmp alltraps
80105466:	e9 25 fa ff ff       	jmp    80104e90 <alltraps>

8010546b <vector48>:
.globl vector48
vector48:
  pushl $0
8010546b:	6a 00                	push   $0x0
  pushl $48
8010546d:	6a 30                	push   $0x30
  jmp alltraps
8010546f:	e9 1c fa ff ff       	jmp    80104e90 <alltraps>

80105474 <vector49>:
.globl vector49
vector49:
  pushl $0
80105474:	6a 00                	push   $0x0
  pushl $49
80105476:	6a 31                	push   $0x31
  jmp alltraps
80105478:	e9 13 fa ff ff       	jmp    80104e90 <alltraps>

8010547d <vector50>:
.globl vector50
vector50:
  pushl $0
8010547d:	6a 00                	push   $0x0
  pushl $50
8010547f:	6a 32                	push   $0x32
  jmp alltraps
80105481:	e9 0a fa ff ff       	jmp    80104e90 <alltraps>

80105486 <vector51>:
.globl vector51
vector51:
  pushl $0
80105486:	6a 00                	push   $0x0
  pushl $51
80105488:	6a 33                	push   $0x33
  jmp alltraps
8010548a:	e9 01 fa ff ff       	jmp    80104e90 <alltraps>

8010548f <vector52>:
.globl vector52
vector52:
  pushl $0
8010548f:	6a 00                	push   $0x0
  pushl $52
80105491:	6a 34                	push   $0x34
  jmp alltraps
80105493:	e9 f8 f9 ff ff       	jmp    80104e90 <alltraps>

80105498 <vector53>:
.globl vector53
vector53:
  pushl $0
80105498:	6a 00                	push   $0x0
  pushl $53
8010549a:	6a 35                	push   $0x35
  jmp alltraps
8010549c:	e9 ef f9 ff ff       	jmp    80104e90 <alltraps>

801054a1 <vector54>:
.globl vector54
vector54:
  pushl $0
801054a1:	6a 00                	push   $0x0
  pushl $54
801054a3:	6a 36                	push   $0x36
  jmp alltraps
801054a5:	e9 e6 f9 ff ff       	jmp    80104e90 <alltraps>

801054aa <vector55>:
.globl vector55
vector55:
  pushl $0
801054aa:	6a 00                	push   $0x0
  pushl $55
801054ac:	6a 37                	push   $0x37
  jmp alltraps
801054ae:	e9 dd f9 ff ff       	jmp    80104e90 <alltraps>

801054b3 <vector56>:
.globl vector56
vector56:
  pushl $0
801054b3:	6a 00                	push   $0x0
  pushl $56
801054b5:	6a 38                	push   $0x38
  jmp alltraps
801054b7:	e9 d4 f9 ff ff       	jmp    80104e90 <alltraps>

801054bc <vector57>:
.globl vector57
vector57:
  pushl $0
801054bc:	6a 00                	push   $0x0
  pushl $57
801054be:	6a 39                	push   $0x39
  jmp alltraps
801054c0:	e9 cb f9 ff ff       	jmp    80104e90 <alltraps>

801054c5 <vector58>:
.globl vector58
vector58:
  pushl $0
801054c5:	6a 00                	push   $0x0
  pushl $58
801054c7:	6a 3a                	push   $0x3a
  jmp alltraps
801054c9:	e9 c2 f9 ff ff       	jmp    80104e90 <alltraps>

801054ce <vector59>:
.globl vector59
vector59:
  pushl $0
801054ce:	6a 00                	push   $0x0
  pushl $59
801054d0:	6a 3b                	push   $0x3b
  jmp alltraps
801054d2:	e9 b9 f9 ff ff       	jmp    80104e90 <alltraps>

801054d7 <vector60>:
.globl vector60
vector60:
  pushl $0
801054d7:	6a 00                	push   $0x0
  pushl $60
801054d9:	6a 3c                	push   $0x3c
  jmp alltraps
801054db:	e9 b0 f9 ff ff       	jmp    80104e90 <alltraps>

801054e0 <vector61>:
.globl vector61
vector61:
  pushl $0
801054e0:	6a 00                	push   $0x0
  pushl $61
801054e2:	6a 3d                	push   $0x3d
  jmp alltraps
801054e4:	e9 a7 f9 ff ff       	jmp    80104e90 <alltraps>

801054e9 <vector62>:
.globl vector62
vector62:
  pushl $0
801054e9:	6a 00                	push   $0x0
  pushl $62
801054eb:	6a 3e                	push   $0x3e
  jmp alltraps
801054ed:	e9 9e f9 ff ff       	jmp    80104e90 <alltraps>

801054f2 <vector63>:
.globl vector63
vector63:
  pushl $0
801054f2:	6a 00                	push   $0x0
  pushl $63
801054f4:	6a 3f                	push   $0x3f
  jmp alltraps
801054f6:	e9 95 f9 ff ff       	jmp    80104e90 <alltraps>

801054fb <vector64>:
.globl vector64
vector64:
  pushl $0
801054fb:	6a 00                	push   $0x0
  pushl $64
801054fd:	6a 40                	push   $0x40
  jmp alltraps
801054ff:	e9 8c f9 ff ff       	jmp    80104e90 <alltraps>

80105504 <vector65>:
.globl vector65
vector65:
  pushl $0
80105504:	6a 00                	push   $0x0
  pushl $65
80105506:	6a 41                	push   $0x41
  jmp alltraps
80105508:	e9 83 f9 ff ff       	jmp    80104e90 <alltraps>

8010550d <vector66>:
.globl vector66
vector66:
  pushl $0
8010550d:	6a 00                	push   $0x0
  pushl $66
8010550f:	6a 42                	push   $0x42
  jmp alltraps
80105511:	e9 7a f9 ff ff       	jmp    80104e90 <alltraps>

80105516 <vector67>:
.globl vector67
vector67:
  pushl $0
80105516:	6a 00                	push   $0x0
  pushl $67
80105518:	6a 43                	push   $0x43
  jmp alltraps
8010551a:	e9 71 f9 ff ff       	jmp    80104e90 <alltraps>

8010551f <vector68>:
.globl vector68
vector68:
  pushl $0
8010551f:	6a 00                	push   $0x0
  pushl $68
80105521:	6a 44                	push   $0x44
  jmp alltraps
80105523:	e9 68 f9 ff ff       	jmp    80104e90 <alltraps>

80105528 <vector69>:
.globl vector69
vector69:
  pushl $0
80105528:	6a 00                	push   $0x0
  pushl $69
8010552a:	6a 45                	push   $0x45
  jmp alltraps
8010552c:	e9 5f f9 ff ff       	jmp    80104e90 <alltraps>

80105531 <vector70>:
.globl vector70
vector70:
  pushl $0
80105531:	6a 00                	push   $0x0
  pushl $70
80105533:	6a 46                	push   $0x46
  jmp alltraps
80105535:	e9 56 f9 ff ff       	jmp    80104e90 <alltraps>

8010553a <vector71>:
.globl vector71
vector71:
  pushl $0
8010553a:	6a 00                	push   $0x0
  pushl $71
8010553c:	6a 47                	push   $0x47
  jmp alltraps
8010553e:	e9 4d f9 ff ff       	jmp    80104e90 <alltraps>

80105543 <vector72>:
.globl vector72
vector72:
  pushl $0
80105543:	6a 00                	push   $0x0
  pushl $72
80105545:	6a 48                	push   $0x48
  jmp alltraps
80105547:	e9 44 f9 ff ff       	jmp    80104e90 <alltraps>

8010554c <vector73>:
.globl vector73
vector73:
  pushl $0
8010554c:	6a 00                	push   $0x0
  pushl $73
8010554e:	6a 49                	push   $0x49
  jmp alltraps
80105550:	e9 3b f9 ff ff       	jmp    80104e90 <alltraps>

80105555 <vector74>:
.globl vector74
vector74:
  pushl $0
80105555:	6a 00                	push   $0x0
  pushl $74
80105557:	6a 4a                	push   $0x4a
  jmp alltraps
80105559:	e9 32 f9 ff ff       	jmp    80104e90 <alltraps>

8010555e <vector75>:
.globl vector75
vector75:
  pushl $0
8010555e:	6a 00                	push   $0x0
  pushl $75
80105560:	6a 4b                	push   $0x4b
  jmp alltraps
80105562:	e9 29 f9 ff ff       	jmp    80104e90 <alltraps>

80105567 <vector76>:
.globl vector76
vector76:
  pushl $0
80105567:	6a 00                	push   $0x0
  pushl $76
80105569:	6a 4c                	push   $0x4c
  jmp alltraps
8010556b:	e9 20 f9 ff ff       	jmp    80104e90 <alltraps>

80105570 <vector77>:
.globl vector77
vector77:
  pushl $0
80105570:	6a 00                	push   $0x0
  pushl $77
80105572:	6a 4d                	push   $0x4d
  jmp alltraps
80105574:	e9 17 f9 ff ff       	jmp    80104e90 <alltraps>

80105579 <vector78>:
.globl vector78
vector78:
  pushl $0
80105579:	6a 00                	push   $0x0
  pushl $78
8010557b:	6a 4e                	push   $0x4e
  jmp alltraps
8010557d:	e9 0e f9 ff ff       	jmp    80104e90 <alltraps>

80105582 <vector79>:
.globl vector79
vector79:
  pushl $0
80105582:	6a 00                	push   $0x0
  pushl $79
80105584:	6a 4f                	push   $0x4f
  jmp alltraps
80105586:	e9 05 f9 ff ff       	jmp    80104e90 <alltraps>

8010558b <vector80>:
.globl vector80
vector80:
  pushl $0
8010558b:	6a 00                	push   $0x0
  pushl $80
8010558d:	6a 50                	push   $0x50
  jmp alltraps
8010558f:	e9 fc f8 ff ff       	jmp    80104e90 <alltraps>

80105594 <vector81>:
.globl vector81
vector81:
  pushl $0
80105594:	6a 00                	push   $0x0
  pushl $81
80105596:	6a 51                	push   $0x51
  jmp alltraps
80105598:	e9 f3 f8 ff ff       	jmp    80104e90 <alltraps>

8010559d <vector82>:
.globl vector82
vector82:
  pushl $0
8010559d:	6a 00                	push   $0x0
  pushl $82
8010559f:	6a 52                	push   $0x52
  jmp alltraps
801055a1:	e9 ea f8 ff ff       	jmp    80104e90 <alltraps>

801055a6 <vector83>:
.globl vector83
vector83:
  pushl $0
801055a6:	6a 00                	push   $0x0
  pushl $83
801055a8:	6a 53                	push   $0x53
  jmp alltraps
801055aa:	e9 e1 f8 ff ff       	jmp    80104e90 <alltraps>

801055af <vector84>:
.globl vector84
vector84:
  pushl $0
801055af:	6a 00                	push   $0x0
  pushl $84
801055b1:	6a 54                	push   $0x54
  jmp alltraps
801055b3:	e9 d8 f8 ff ff       	jmp    80104e90 <alltraps>

801055b8 <vector85>:
.globl vector85
vector85:
  pushl $0
801055b8:	6a 00                	push   $0x0
  pushl $85
801055ba:	6a 55                	push   $0x55
  jmp alltraps
801055bc:	e9 cf f8 ff ff       	jmp    80104e90 <alltraps>

801055c1 <vector86>:
.globl vector86
vector86:
  pushl $0
801055c1:	6a 00                	push   $0x0
  pushl $86
801055c3:	6a 56                	push   $0x56
  jmp alltraps
801055c5:	e9 c6 f8 ff ff       	jmp    80104e90 <alltraps>

801055ca <vector87>:
.globl vector87
vector87:
  pushl $0
801055ca:	6a 00                	push   $0x0
  pushl $87
801055cc:	6a 57                	push   $0x57
  jmp alltraps
801055ce:	e9 bd f8 ff ff       	jmp    80104e90 <alltraps>

801055d3 <vector88>:
.globl vector88
vector88:
  pushl $0
801055d3:	6a 00                	push   $0x0
  pushl $88
801055d5:	6a 58                	push   $0x58
  jmp alltraps
801055d7:	e9 b4 f8 ff ff       	jmp    80104e90 <alltraps>

801055dc <vector89>:
.globl vector89
vector89:
  pushl $0
801055dc:	6a 00                	push   $0x0
  pushl $89
801055de:	6a 59                	push   $0x59
  jmp alltraps
801055e0:	e9 ab f8 ff ff       	jmp    80104e90 <alltraps>

801055e5 <vector90>:
.globl vector90
vector90:
  pushl $0
801055e5:	6a 00                	push   $0x0
  pushl $90
801055e7:	6a 5a                	push   $0x5a
  jmp alltraps
801055e9:	e9 a2 f8 ff ff       	jmp    80104e90 <alltraps>

801055ee <vector91>:
.globl vector91
vector91:
  pushl $0
801055ee:	6a 00                	push   $0x0
  pushl $91
801055f0:	6a 5b                	push   $0x5b
  jmp alltraps
801055f2:	e9 99 f8 ff ff       	jmp    80104e90 <alltraps>

801055f7 <vector92>:
.globl vector92
vector92:
  pushl $0
801055f7:	6a 00                	push   $0x0
  pushl $92
801055f9:	6a 5c                	push   $0x5c
  jmp alltraps
801055fb:	e9 90 f8 ff ff       	jmp    80104e90 <alltraps>

80105600 <vector93>:
.globl vector93
vector93:
  pushl $0
80105600:	6a 00                	push   $0x0
  pushl $93
80105602:	6a 5d                	push   $0x5d
  jmp alltraps
80105604:	e9 87 f8 ff ff       	jmp    80104e90 <alltraps>

80105609 <vector94>:
.globl vector94
vector94:
  pushl $0
80105609:	6a 00                	push   $0x0
  pushl $94
8010560b:	6a 5e                	push   $0x5e
  jmp alltraps
8010560d:	e9 7e f8 ff ff       	jmp    80104e90 <alltraps>

80105612 <vector95>:
.globl vector95
vector95:
  pushl $0
80105612:	6a 00                	push   $0x0
  pushl $95
80105614:	6a 5f                	push   $0x5f
  jmp alltraps
80105616:	e9 75 f8 ff ff       	jmp    80104e90 <alltraps>

8010561b <vector96>:
.globl vector96
vector96:
  pushl $0
8010561b:	6a 00                	push   $0x0
  pushl $96
8010561d:	6a 60                	push   $0x60
  jmp alltraps
8010561f:	e9 6c f8 ff ff       	jmp    80104e90 <alltraps>

80105624 <vector97>:
.globl vector97
vector97:
  pushl $0
80105624:	6a 00                	push   $0x0
  pushl $97
80105626:	6a 61                	push   $0x61
  jmp alltraps
80105628:	e9 63 f8 ff ff       	jmp    80104e90 <alltraps>

8010562d <vector98>:
.globl vector98
vector98:
  pushl $0
8010562d:	6a 00                	push   $0x0
  pushl $98
8010562f:	6a 62                	push   $0x62
  jmp alltraps
80105631:	e9 5a f8 ff ff       	jmp    80104e90 <alltraps>

80105636 <vector99>:
.globl vector99
vector99:
  pushl $0
80105636:	6a 00                	push   $0x0
  pushl $99
80105638:	6a 63                	push   $0x63
  jmp alltraps
8010563a:	e9 51 f8 ff ff       	jmp    80104e90 <alltraps>

8010563f <vector100>:
.globl vector100
vector100:
  pushl $0
8010563f:	6a 00                	push   $0x0
  pushl $100
80105641:	6a 64                	push   $0x64
  jmp alltraps
80105643:	e9 48 f8 ff ff       	jmp    80104e90 <alltraps>

80105648 <vector101>:
.globl vector101
vector101:
  pushl $0
80105648:	6a 00                	push   $0x0
  pushl $101
8010564a:	6a 65                	push   $0x65
  jmp alltraps
8010564c:	e9 3f f8 ff ff       	jmp    80104e90 <alltraps>

80105651 <vector102>:
.globl vector102
vector102:
  pushl $0
80105651:	6a 00                	push   $0x0
  pushl $102
80105653:	6a 66                	push   $0x66
  jmp alltraps
80105655:	e9 36 f8 ff ff       	jmp    80104e90 <alltraps>

8010565a <vector103>:
.globl vector103
vector103:
  pushl $0
8010565a:	6a 00                	push   $0x0
  pushl $103
8010565c:	6a 67                	push   $0x67
  jmp alltraps
8010565e:	e9 2d f8 ff ff       	jmp    80104e90 <alltraps>

80105663 <vector104>:
.globl vector104
vector104:
  pushl $0
80105663:	6a 00                	push   $0x0
  pushl $104
80105665:	6a 68                	push   $0x68
  jmp alltraps
80105667:	e9 24 f8 ff ff       	jmp    80104e90 <alltraps>

8010566c <vector105>:
.globl vector105
vector105:
  pushl $0
8010566c:	6a 00                	push   $0x0
  pushl $105
8010566e:	6a 69                	push   $0x69
  jmp alltraps
80105670:	e9 1b f8 ff ff       	jmp    80104e90 <alltraps>

80105675 <vector106>:
.globl vector106
vector106:
  pushl $0
80105675:	6a 00                	push   $0x0
  pushl $106
80105677:	6a 6a                	push   $0x6a
  jmp alltraps
80105679:	e9 12 f8 ff ff       	jmp    80104e90 <alltraps>

8010567e <vector107>:
.globl vector107
vector107:
  pushl $0
8010567e:	6a 00                	push   $0x0
  pushl $107
80105680:	6a 6b                	push   $0x6b
  jmp alltraps
80105682:	e9 09 f8 ff ff       	jmp    80104e90 <alltraps>

80105687 <vector108>:
.globl vector108
vector108:
  pushl $0
80105687:	6a 00                	push   $0x0
  pushl $108
80105689:	6a 6c                	push   $0x6c
  jmp alltraps
8010568b:	e9 00 f8 ff ff       	jmp    80104e90 <alltraps>

80105690 <vector109>:
.globl vector109
vector109:
  pushl $0
80105690:	6a 00                	push   $0x0
  pushl $109
80105692:	6a 6d                	push   $0x6d
  jmp alltraps
80105694:	e9 f7 f7 ff ff       	jmp    80104e90 <alltraps>

80105699 <vector110>:
.globl vector110
vector110:
  pushl $0
80105699:	6a 00                	push   $0x0
  pushl $110
8010569b:	6a 6e                	push   $0x6e
  jmp alltraps
8010569d:	e9 ee f7 ff ff       	jmp    80104e90 <alltraps>

801056a2 <vector111>:
.globl vector111
vector111:
  pushl $0
801056a2:	6a 00                	push   $0x0
  pushl $111
801056a4:	6a 6f                	push   $0x6f
  jmp alltraps
801056a6:	e9 e5 f7 ff ff       	jmp    80104e90 <alltraps>

801056ab <vector112>:
.globl vector112
vector112:
  pushl $0
801056ab:	6a 00                	push   $0x0
  pushl $112
801056ad:	6a 70                	push   $0x70
  jmp alltraps
801056af:	e9 dc f7 ff ff       	jmp    80104e90 <alltraps>

801056b4 <vector113>:
.globl vector113
vector113:
  pushl $0
801056b4:	6a 00                	push   $0x0
  pushl $113
801056b6:	6a 71                	push   $0x71
  jmp alltraps
801056b8:	e9 d3 f7 ff ff       	jmp    80104e90 <alltraps>

801056bd <vector114>:
.globl vector114
vector114:
  pushl $0
801056bd:	6a 00                	push   $0x0
  pushl $114
801056bf:	6a 72                	push   $0x72
  jmp alltraps
801056c1:	e9 ca f7 ff ff       	jmp    80104e90 <alltraps>

801056c6 <vector115>:
.globl vector115
vector115:
  pushl $0
801056c6:	6a 00                	push   $0x0
  pushl $115
801056c8:	6a 73                	push   $0x73
  jmp alltraps
801056ca:	e9 c1 f7 ff ff       	jmp    80104e90 <alltraps>

801056cf <vector116>:
.globl vector116
vector116:
  pushl $0
801056cf:	6a 00                	push   $0x0
  pushl $116
801056d1:	6a 74                	push   $0x74
  jmp alltraps
801056d3:	e9 b8 f7 ff ff       	jmp    80104e90 <alltraps>

801056d8 <vector117>:
.globl vector117
vector117:
  pushl $0
801056d8:	6a 00                	push   $0x0
  pushl $117
801056da:	6a 75                	push   $0x75
  jmp alltraps
801056dc:	e9 af f7 ff ff       	jmp    80104e90 <alltraps>

801056e1 <vector118>:
.globl vector118
vector118:
  pushl $0
801056e1:	6a 00                	push   $0x0
  pushl $118
801056e3:	6a 76                	push   $0x76
  jmp alltraps
801056e5:	e9 a6 f7 ff ff       	jmp    80104e90 <alltraps>

801056ea <vector119>:
.globl vector119
vector119:
  pushl $0
801056ea:	6a 00                	push   $0x0
  pushl $119
801056ec:	6a 77                	push   $0x77
  jmp alltraps
801056ee:	e9 9d f7 ff ff       	jmp    80104e90 <alltraps>

801056f3 <vector120>:
.globl vector120
vector120:
  pushl $0
801056f3:	6a 00                	push   $0x0
  pushl $120
801056f5:	6a 78                	push   $0x78
  jmp alltraps
801056f7:	e9 94 f7 ff ff       	jmp    80104e90 <alltraps>

801056fc <vector121>:
.globl vector121
vector121:
  pushl $0
801056fc:	6a 00                	push   $0x0
  pushl $121
801056fe:	6a 79                	push   $0x79
  jmp alltraps
80105700:	e9 8b f7 ff ff       	jmp    80104e90 <alltraps>

80105705 <vector122>:
.globl vector122
vector122:
  pushl $0
80105705:	6a 00                	push   $0x0
  pushl $122
80105707:	6a 7a                	push   $0x7a
  jmp alltraps
80105709:	e9 82 f7 ff ff       	jmp    80104e90 <alltraps>

8010570e <vector123>:
.globl vector123
vector123:
  pushl $0
8010570e:	6a 00                	push   $0x0
  pushl $123
80105710:	6a 7b                	push   $0x7b
  jmp alltraps
80105712:	e9 79 f7 ff ff       	jmp    80104e90 <alltraps>

80105717 <vector124>:
.globl vector124
vector124:
  pushl $0
80105717:	6a 00                	push   $0x0
  pushl $124
80105719:	6a 7c                	push   $0x7c
  jmp alltraps
8010571b:	e9 70 f7 ff ff       	jmp    80104e90 <alltraps>

80105720 <vector125>:
.globl vector125
vector125:
  pushl $0
80105720:	6a 00                	push   $0x0
  pushl $125
80105722:	6a 7d                	push   $0x7d
  jmp alltraps
80105724:	e9 67 f7 ff ff       	jmp    80104e90 <alltraps>

80105729 <vector126>:
.globl vector126
vector126:
  pushl $0
80105729:	6a 00                	push   $0x0
  pushl $126
8010572b:	6a 7e                	push   $0x7e
  jmp alltraps
8010572d:	e9 5e f7 ff ff       	jmp    80104e90 <alltraps>

80105732 <vector127>:
.globl vector127
vector127:
  pushl $0
80105732:	6a 00                	push   $0x0
  pushl $127
80105734:	6a 7f                	push   $0x7f
  jmp alltraps
80105736:	e9 55 f7 ff ff       	jmp    80104e90 <alltraps>

8010573b <vector128>:
.globl vector128
vector128:
  pushl $0
8010573b:	6a 00                	push   $0x0
  pushl $128
8010573d:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80105742:	e9 49 f7 ff ff       	jmp    80104e90 <alltraps>

80105747 <vector129>:
.globl vector129
vector129:
  pushl $0
80105747:	6a 00                	push   $0x0
  pushl $129
80105749:	68 81 00 00 00       	push   $0x81
  jmp alltraps
8010574e:	e9 3d f7 ff ff       	jmp    80104e90 <alltraps>

80105753 <vector130>:
.globl vector130
vector130:
  pushl $0
80105753:	6a 00                	push   $0x0
  pushl $130
80105755:	68 82 00 00 00       	push   $0x82
  jmp alltraps
8010575a:	e9 31 f7 ff ff       	jmp    80104e90 <alltraps>

8010575f <vector131>:
.globl vector131
vector131:
  pushl $0
8010575f:	6a 00                	push   $0x0
  pushl $131
80105761:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80105766:	e9 25 f7 ff ff       	jmp    80104e90 <alltraps>

8010576b <vector132>:
.globl vector132
vector132:
  pushl $0
8010576b:	6a 00                	push   $0x0
  pushl $132
8010576d:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80105772:	e9 19 f7 ff ff       	jmp    80104e90 <alltraps>

80105777 <vector133>:
.globl vector133
vector133:
  pushl $0
80105777:	6a 00                	push   $0x0
  pushl $133
80105779:	68 85 00 00 00       	push   $0x85
  jmp alltraps
8010577e:	e9 0d f7 ff ff       	jmp    80104e90 <alltraps>

80105783 <vector134>:
.globl vector134
vector134:
  pushl $0
80105783:	6a 00                	push   $0x0
  pushl $134
80105785:	68 86 00 00 00       	push   $0x86
  jmp alltraps
8010578a:	e9 01 f7 ff ff       	jmp    80104e90 <alltraps>

8010578f <vector135>:
.globl vector135
vector135:
  pushl $0
8010578f:	6a 00                	push   $0x0
  pushl $135
80105791:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80105796:	e9 f5 f6 ff ff       	jmp    80104e90 <alltraps>

8010579b <vector136>:
.globl vector136
vector136:
  pushl $0
8010579b:	6a 00                	push   $0x0
  pushl $136
8010579d:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801057a2:	e9 e9 f6 ff ff       	jmp    80104e90 <alltraps>

801057a7 <vector137>:
.globl vector137
vector137:
  pushl $0
801057a7:	6a 00                	push   $0x0
  pushl $137
801057a9:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801057ae:	e9 dd f6 ff ff       	jmp    80104e90 <alltraps>

801057b3 <vector138>:
.globl vector138
vector138:
  pushl $0
801057b3:	6a 00                	push   $0x0
  pushl $138
801057b5:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801057ba:	e9 d1 f6 ff ff       	jmp    80104e90 <alltraps>

801057bf <vector139>:
.globl vector139
vector139:
  pushl $0
801057bf:	6a 00                	push   $0x0
  pushl $139
801057c1:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801057c6:	e9 c5 f6 ff ff       	jmp    80104e90 <alltraps>

801057cb <vector140>:
.globl vector140
vector140:
  pushl $0
801057cb:	6a 00                	push   $0x0
  pushl $140
801057cd:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801057d2:	e9 b9 f6 ff ff       	jmp    80104e90 <alltraps>

801057d7 <vector141>:
.globl vector141
vector141:
  pushl $0
801057d7:	6a 00                	push   $0x0
  pushl $141
801057d9:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801057de:	e9 ad f6 ff ff       	jmp    80104e90 <alltraps>

801057e3 <vector142>:
.globl vector142
vector142:
  pushl $0
801057e3:	6a 00                	push   $0x0
  pushl $142
801057e5:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
801057ea:	e9 a1 f6 ff ff       	jmp    80104e90 <alltraps>

801057ef <vector143>:
.globl vector143
vector143:
  pushl $0
801057ef:	6a 00                	push   $0x0
  pushl $143
801057f1:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
801057f6:	e9 95 f6 ff ff       	jmp    80104e90 <alltraps>

801057fb <vector144>:
.globl vector144
vector144:
  pushl $0
801057fb:	6a 00                	push   $0x0
  pushl $144
801057fd:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80105802:	e9 89 f6 ff ff       	jmp    80104e90 <alltraps>

80105807 <vector145>:
.globl vector145
vector145:
  pushl $0
80105807:	6a 00                	push   $0x0
  pushl $145
80105809:	68 91 00 00 00       	push   $0x91
  jmp alltraps
8010580e:	e9 7d f6 ff ff       	jmp    80104e90 <alltraps>

80105813 <vector146>:
.globl vector146
vector146:
  pushl $0
80105813:	6a 00                	push   $0x0
  pushl $146
80105815:	68 92 00 00 00       	push   $0x92
  jmp alltraps
8010581a:	e9 71 f6 ff ff       	jmp    80104e90 <alltraps>

8010581f <vector147>:
.globl vector147
vector147:
  pushl $0
8010581f:	6a 00                	push   $0x0
  pushl $147
80105821:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80105826:	e9 65 f6 ff ff       	jmp    80104e90 <alltraps>

8010582b <vector148>:
.globl vector148
vector148:
  pushl $0
8010582b:	6a 00                	push   $0x0
  pushl $148
8010582d:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80105832:	e9 59 f6 ff ff       	jmp    80104e90 <alltraps>

80105837 <vector149>:
.globl vector149
vector149:
  pushl $0
80105837:	6a 00                	push   $0x0
  pushl $149
80105839:	68 95 00 00 00       	push   $0x95
  jmp alltraps
8010583e:	e9 4d f6 ff ff       	jmp    80104e90 <alltraps>

80105843 <vector150>:
.globl vector150
vector150:
  pushl $0
80105843:	6a 00                	push   $0x0
  pushl $150
80105845:	68 96 00 00 00       	push   $0x96
  jmp alltraps
8010584a:	e9 41 f6 ff ff       	jmp    80104e90 <alltraps>

8010584f <vector151>:
.globl vector151
vector151:
  pushl $0
8010584f:	6a 00                	push   $0x0
  pushl $151
80105851:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80105856:	e9 35 f6 ff ff       	jmp    80104e90 <alltraps>

8010585b <vector152>:
.globl vector152
vector152:
  pushl $0
8010585b:	6a 00                	push   $0x0
  pushl $152
8010585d:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80105862:	e9 29 f6 ff ff       	jmp    80104e90 <alltraps>

80105867 <vector153>:
.globl vector153
vector153:
  pushl $0
80105867:	6a 00                	push   $0x0
  pushl $153
80105869:	68 99 00 00 00       	push   $0x99
  jmp alltraps
8010586e:	e9 1d f6 ff ff       	jmp    80104e90 <alltraps>

80105873 <vector154>:
.globl vector154
vector154:
  pushl $0
80105873:	6a 00                	push   $0x0
  pushl $154
80105875:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
8010587a:	e9 11 f6 ff ff       	jmp    80104e90 <alltraps>

8010587f <vector155>:
.globl vector155
vector155:
  pushl $0
8010587f:	6a 00                	push   $0x0
  pushl $155
80105881:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80105886:	e9 05 f6 ff ff       	jmp    80104e90 <alltraps>

8010588b <vector156>:
.globl vector156
vector156:
  pushl $0
8010588b:	6a 00                	push   $0x0
  pushl $156
8010588d:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80105892:	e9 f9 f5 ff ff       	jmp    80104e90 <alltraps>

80105897 <vector157>:
.globl vector157
vector157:
  pushl $0
80105897:	6a 00                	push   $0x0
  pushl $157
80105899:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
8010589e:	e9 ed f5 ff ff       	jmp    80104e90 <alltraps>

801058a3 <vector158>:
.globl vector158
vector158:
  pushl $0
801058a3:	6a 00                	push   $0x0
  pushl $158
801058a5:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801058aa:	e9 e1 f5 ff ff       	jmp    80104e90 <alltraps>

801058af <vector159>:
.globl vector159
vector159:
  pushl $0
801058af:	6a 00                	push   $0x0
  pushl $159
801058b1:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801058b6:	e9 d5 f5 ff ff       	jmp    80104e90 <alltraps>

801058bb <vector160>:
.globl vector160
vector160:
  pushl $0
801058bb:	6a 00                	push   $0x0
  pushl $160
801058bd:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801058c2:	e9 c9 f5 ff ff       	jmp    80104e90 <alltraps>

801058c7 <vector161>:
.globl vector161
vector161:
  pushl $0
801058c7:	6a 00                	push   $0x0
  pushl $161
801058c9:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801058ce:	e9 bd f5 ff ff       	jmp    80104e90 <alltraps>

801058d3 <vector162>:
.globl vector162
vector162:
  pushl $0
801058d3:	6a 00                	push   $0x0
  pushl $162
801058d5:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801058da:	e9 b1 f5 ff ff       	jmp    80104e90 <alltraps>

801058df <vector163>:
.globl vector163
vector163:
  pushl $0
801058df:	6a 00                	push   $0x0
  pushl $163
801058e1:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
801058e6:	e9 a5 f5 ff ff       	jmp    80104e90 <alltraps>

801058eb <vector164>:
.globl vector164
vector164:
  pushl $0
801058eb:	6a 00                	push   $0x0
  pushl $164
801058ed:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
801058f2:	e9 99 f5 ff ff       	jmp    80104e90 <alltraps>

801058f7 <vector165>:
.globl vector165
vector165:
  pushl $0
801058f7:	6a 00                	push   $0x0
  pushl $165
801058f9:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
801058fe:	e9 8d f5 ff ff       	jmp    80104e90 <alltraps>

80105903 <vector166>:
.globl vector166
vector166:
  pushl $0
80105903:	6a 00                	push   $0x0
  pushl $166
80105905:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
8010590a:	e9 81 f5 ff ff       	jmp    80104e90 <alltraps>

8010590f <vector167>:
.globl vector167
vector167:
  pushl $0
8010590f:	6a 00                	push   $0x0
  pushl $167
80105911:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105916:	e9 75 f5 ff ff       	jmp    80104e90 <alltraps>

8010591b <vector168>:
.globl vector168
vector168:
  pushl $0
8010591b:	6a 00                	push   $0x0
  pushl $168
8010591d:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105922:	e9 69 f5 ff ff       	jmp    80104e90 <alltraps>

80105927 <vector169>:
.globl vector169
vector169:
  pushl $0
80105927:	6a 00                	push   $0x0
  pushl $169
80105929:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
8010592e:	e9 5d f5 ff ff       	jmp    80104e90 <alltraps>

80105933 <vector170>:
.globl vector170
vector170:
  pushl $0
80105933:	6a 00                	push   $0x0
  pushl $170
80105935:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
8010593a:	e9 51 f5 ff ff       	jmp    80104e90 <alltraps>

8010593f <vector171>:
.globl vector171
vector171:
  pushl $0
8010593f:	6a 00                	push   $0x0
  pushl $171
80105941:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105946:	e9 45 f5 ff ff       	jmp    80104e90 <alltraps>

8010594b <vector172>:
.globl vector172
vector172:
  pushl $0
8010594b:	6a 00                	push   $0x0
  pushl $172
8010594d:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105952:	e9 39 f5 ff ff       	jmp    80104e90 <alltraps>

80105957 <vector173>:
.globl vector173
vector173:
  pushl $0
80105957:	6a 00                	push   $0x0
  pushl $173
80105959:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
8010595e:	e9 2d f5 ff ff       	jmp    80104e90 <alltraps>

80105963 <vector174>:
.globl vector174
vector174:
  pushl $0
80105963:	6a 00                	push   $0x0
  pushl $174
80105965:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
8010596a:	e9 21 f5 ff ff       	jmp    80104e90 <alltraps>

8010596f <vector175>:
.globl vector175
vector175:
  pushl $0
8010596f:	6a 00                	push   $0x0
  pushl $175
80105971:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105976:	e9 15 f5 ff ff       	jmp    80104e90 <alltraps>

8010597b <vector176>:
.globl vector176
vector176:
  pushl $0
8010597b:	6a 00                	push   $0x0
  pushl $176
8010597d:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105982:	e9 09 f5 ff ff       	jmp    80104e90 <alltraps>

80105987 <vector177>:
.globl vector177
vector177:
  pushl $0
80105987:	6a 00                	push   $0x0
  pushl $177
80105989:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
8010598e:	e9 fd f4 ff ff       	jmp    80104e90 <alltraps>

80105993 <vector178>:
.globl vector178
vector178:
  pushl $0
80105993:	6a 00                	push   $0x0
  pushl $178
80105995:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
8010599a:	e9 f1 f4 ff ff       	jmp    80104e90 <alltraps>

8010599f <vector179>:
.globl vector179
vector179:
  pushl $0
8010599f:	6a 00                	push   $0x0
  pushl $179
801059a1:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
801059a6:	e9 e5 f4 ff ff       	jmp    80104e90 <alltraps>

801059ab <vector180>:
.globl vector180
vector180:
  pushl $0
801059ab:	6a 00                	push   $0x0
  pushl $180
801059ad:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801059b2:	e9 d9 f4 ff ff       	jmp    80104e90 <alltraps>

801059b7 <vector181>:
.globl vector181
vector181:
  pushl $0
801059b7:	6a 00                	push   $0x0
  pushl $181
801059b9:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801059be:	e9 cd f4 ff ff       	jmp    80104e90 <alltraps>

801059c3 <vector182>:
.globl vector182
vector182:
  pushl $0
801059c3:	6a 00                	push   $0x0
  pushl $182
801059c5:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801059ca:	e9 c1 f4 ff ff       	jmp    80104e90 <alltraps>

801059cf <vector183>:
.globl vector183
vector183:
  pushl $0
801059cf:	6a 00                	push   $0x0
  pushl $183
801059d1:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801059d6:	e9 b5 f4 ff ff       	jmp    80104e90 <alltraps>

801059db <vector184>:
.globl vector184
vector184:
  pushl $0
801059db:	6a 00                	push   $0x0
  pushl $184
801059dd:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801059e2:	e9 a9 f4 ff ff       	jmp    80104e90 <alltraps>

801059e7 <vector185>:
.globl vector185
vector185:
  pushl $0
801059e7:	6a 00                	push   $0x0
  pushl $185
801059e9:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
801059ee:	e9 9d f4 ff ff       	jmp    80104e90 <alltraps>

801059f3 <vector186>:
.globl vector186
vector186:
  pushl $0
801059f3:	6a 00                	push   $0x0
  pushl $186
801059f5:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
801059fa:	e9 91 f4 ff ff       	jmp    80104e90 <alltraps>

801059ff <vector187>:
.globl vector187
vector187:
  pushl $0
801059ff:	6a 00                	push   $0x0
  pushl $187
80105a01:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105a06:	e9 85 f4 ff ff       	jmp    80104e90 <alltraps>

80105a0b <vector188>:
.globl vector188
vector188:
  pushl $0
80105a0b:	6a 00                	push   $0x0
  pushl $188
80105a0d:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105a12:	e9 79 f4 ff ff       	jmp    80104e90 <alltraps>

80105a17 <vector189>:
.globl vector189
vector189:
  pushl $0
80105a17:	6a 00                	push   $0x0
  pushl $189
80105a19:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105a1e:	e9 6d f4 ff ff       	jmp    80104e90 <alltraps>

80105a23 <vector190>:
.globl vector190
vector190:
  pushl $0
80105a23:	6a 00                	push   $0x0
  pushl $190
80105a25:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105a2a:	e9 61 f4 ff ff       	jmp    80104e90 <alltraps>

80105a2f <vector191>:
.globl vector191
vector191:
  pushl $0
80105a2f:	6a 00                	push   $0x0
  pushl $191
80105a31:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105a36:	e9 55 f4 ff ff       	jmp    80104e90 <alltraps>

80105a3b <vector192>:
.globl vector192
vector192:
  pushl $0
80105a3b:	6a 00                	push   $0x0
  pushl $192
80105a3d:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105a42:	e9 49 f4 ff ff       	jmp    80104e90 <alltraps>

80105a47 <vector193>:
.globl vector193
vector193:
  pushl $0
80105a47:	6a 00                	push   $0x0
  pushl $193
80105a49:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105a4e:	e9 3d f4 ff ff       	jmp    80104e90 <alltraps>

80105a53 <vector194>:
.globl vector194
vector194:
  pushl $0
80105a53:	6a 00                	push   $0x0
  pushl $194
80105a55:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105a5a:	e9 31 f4 ff ff       	jmp    80104e90 <alltraps>

80105a5f <vector195>:
.globl vector195
vector195:
  pushl $0
80105a5f:	6a 00                	push   $0x0
  pushl $195
80105a61:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105a66:	e9 25 f4 ff ff       	jmp    80104e90 <alltraps>

80105a6b <vector196>:
.globl vector196
vector196:
  pushl $0
80105a6b:	6a 00                	push   $0x0
  pushl $196
80105a6d:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105a72:	e9 19 f4 ff ff       	jmp    80104e90 <alltraps>

80105a77 <vector197>:
.globl vector197
vector197:
  pushl $0
80105a77:	6a 00                	push   $0x0
  pushl $197
80105a79:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105a7e:	e9 0d f4 ff ff       	jmp    80104e90 <alltraps>

80105a83 <vector198>:
.globl vector198
vector198:
  pushl $0
80105a83:	6a 00                	push   $0x0
  pushl $198
80105a85:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105a8a:	e9 01 f4 ff ff       	jmp    80104e90 <alltraps>

80105a8f <vector199>:
.globl vector199
vector199:
  pushl $0
80105a8f:	6a 00                	push   $0x0
  pushl $199
80105a91:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105a96:	e9 f5 f3 ff ff       	jmp    80104e90 <alltraps>

80105a9b <vector200>:
.globl vector200
vector200:
  pushl $0
80105a9b:	6a 00                	push   $0x0
  pushl $200
80105a9d:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105aa2:	e9 e9 f3 ff ff       	jmp    80104e90 <alltraps>

80105aa7 <vector201>:
.globl vector201
vector201:
  pushl $0
80105aa7:	6a 00                	push   $0x0
  pushl $201
80105aa9:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105aae:	e9 dd f3 ff ff       	jmp    80104e90 <alltraps>

80105ab3 <vector202>:
.globl vector202
vector202:
  pushl $0
80105ab3:	6a 00                	push   $0x0
  pushl $202
80105ab5:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105aba:	e9 d1 f3 ff ff       	jmp    80104e90 <alltraps>

80105abf <vector203>:
.globl vector203
vector203:
  pushl $0
80105abf:	6a 00                	push   $0x0
  pushl $203
80105ac1:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105ac6:	e9 c5 f3 ff ff       	jmp    80104e90 <alltraps>

80105acb <vector204>:
.globl vector204
vector204:
  pushl $0
80105acb:	6a 00                	push   $0x0
  pushl $204
80105acd:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105ad2:	e9 b9 f3 ff ff       	jmp    80104e90 <alltraps>

80105ad7 <vector205>:
.globl vector205
vector205:
  pushl $0
80105ad7:	6a 00                	push   $0x0
  pushl $205
80105ad9:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105ade:	e9 ad f3 ff ff       	jmp    80104e90 <alltraps>

80105ae3 <vector206>:
.globl vector206
vector206:
  pushl $0
80105ae3:	6a 00                	push   $0x0
  pushl $206
80105ae5:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105aea:	e9 a1 f3 ff ff       	jmp    80104e90 <alltraps>

80105aef <vector207>:
.globl vector207
vector207:
  pushl $0
80105aef:	6a 00                	push   $0x0
  pushl $207
80105af1:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105af6:	e9 95 f3 ff ff       	jmp    80104e90 <alltraps>

80105afb <vector208>:
.globl vector208
vector208:
  pushl $0
80105afb:	6a 00                	push   $0x0
  pushl $208
80105afd:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105b02:	e9 89 f3 ff ff       	jmp    80104e90 <alltraps>

80105b07 <vector209>:
.globl vector209
vector209:
  pushl $0
80105b07:	6a 00                	push   $0x0
  pushl $209
80105b09:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105b0e:	e9 7d f3 ff ff       	jmp    80104e90 <alltraps>

80105b13 <vector210>:
.globl vector210
vector210:
  pushl $0
80105b13:	6a 00                	push   $0x0
  pushl $210
80105b15:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105b1a:	e9 71 f3 ff ff       	jmp    80104e90 <alltraps>

80105b1f <vector211>:
.globl vector211
vector211:
  pushl $0
80105b1f:	6a 00                	push   $0x0
  pushl $211
80105b21:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105b26:	e9 65 f3 ff ff       	jmp    80104e90 <alltraps>

80105b2b <vector212>:
.globl vector212
vector212:
  pushl $0
80105b2b:	6a 00                	push   $0x0
  pushl $212
80105b2d:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105b32:	e9 59 f3 ff ff       	jmp    80104e90 <alltraps>

80105b37 <vector213>:
.globl vector213
vector213:
  pushl $0
80105b37:	6a 00                	push   $0x0
  pushl $213
80105b39:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105b3e:	e9 4d f3 ff ff       	jmp    80104e90 <alltraps>

80105b43 <vector214>:
.globl vector214
vector214:
  pushl $0
80105b43:	6a 00                	push   $0x0
  pushl $214
80105b45:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105b4a:	e9 41 f3 ff ff       	jmp    80104e90 <alltraps>

80105b4f <vector215>:
.globl vector215
vector215:
  pushl $0
80105b4f:	6a 00                	push   $0x0
  pushl $215
80105b51:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105b56:	e9 35 f3 ff ff       	jmp    80104e90 <alltraps>

80105b5b <vector216>:
.globl vector216
vector216:
  pushl $0
80105b5b:	6a 00                	push   $0x0
  pushl $216
80105b5d:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105b62:	e9 29 f3 ff ff       	jmp    80104e90 <alltraps>

80105b67 <vector217>:
.globl vector217
vector217:
  pushl $0
80105b67:	6a 00                	push   $0x0
  pushl $217
80105b69:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105b6e:	e9 1d f3 ff ff       	jmp    80104e90 <alltraps>

80105b73 <vector218>:
.globl vector218
vector218:
  pushl $0
80105b73:	6a 00                	push   $0x0
  pushl $218
80105b75:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105b7a:	e9 11 f3 ff ff       	jmp    80104e90 <alltraps>

80105b7f <vector219>:
.globl vector219
vector219:
  pushl $0
80105b7f:	6a 00                	push   $0x0
  pushl $219
80105b81:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105b86:	e9 05 f3 ff ff       	jmp    80104e90 <alltraps>

80105b8b <vector220>:
.globl vector220
vector220:
  pushl $0
80105b8b:	6a 00                	push   $0x0
  pushl $220
80105b8d:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105b92:	e9 f9 f2 ff ff       	jmp    80104e90 <alltraps>

80105b97 <vector221>:
.globl vector221
vector221:
  pushl $0
80105b97:	6a 00                	push   $0x0
  pushl $221
80105b99:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105b9e:	e9 ed f2 ff ff       	jmp    80104e90 <alltraps>

80105ba3 <vector222>:
.globl vector222
vector222:
  pushl $0
80105ba3:	6a 00                	push   $0x0
  pushl $222
80105ba5:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105baa:	e9 e1 f2 ff ff       	jmp    80104e90 <alltraps>

80105baf <vector223>:
.globl vector223
vector223:
  pushl $0
80105baf:	6a 00                	push   $0x0
  pushl $223
80105bb1:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105bb6:	e9 d5 f2 ff ff       	jmp    80104e90 <alltraps>

80105bbb <vector224>:
.globl vector224
vector224:
  pushl $0
80105bbb:	6a 00                	push   $0x0
  pushl $224
80105bbd:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105bc2:	e9 c9 f2 ff ff       	jmp    80104e90 <alltraps>

80105bc7 <vector225>:
.globl vector225
vector225:
  pushl $0
80105bc7:	6a 00                	push   $0x0
  pushl $225
80105bc9:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105bce:	e9 bd f2 ff ff       	jmp    80104e90 <alltraps>

80105bd3 <vector226>:
.globl vector226
vector226:
  pushl $0
80105bd3:	6a 00                	push   $0x0
  pushl $226
80105bd5:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105bda:	e9 b1 f2 ff ff       	jmp    80104e90 <alltraps>

80105bdf <vector227>:
.globl vector227
vector227:
  pushl $0
80105bdf:	6a 00                	push   $0x0
  pushl $227
80105be1:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105be6:	e9 a5 f2 ff ff       	jmp    80104e90 <alltraps>

80105beb <vector228>:
.globl vector228
vector228:
  pushl $0
80105beb:	6a 00                	push   $0x0
  pushl $228
80105bed:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105bf2:	e9 99 f2 ff ff       	jmp    80104e90 <alltraps>

80105bf7 <vector229>:
.globl vector229
vector229:
  pushl $0
80105bf7:	6a 00                	push   $0x0
  pushl $229
80105bf9:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105bfe:	e9 8d f2 ff ff       	jmp    80104e90 <alltraps>

80105c03 <vector230>:
.globl vector230
vector230:
  pushl $0
80105c03:	6a 00                	push   $0x0
  pushl $230
80105c05:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105c0a:	e9 81 f2 ff ff       	jmp    80104e90 <alltraps>

80105c0f <vector231>:
.globl vector231
vector231:
  pushl $0
80105c0f:	6a 00                	push   $0x0
  pushl $231
80105c11:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105c16:	e9 75 f2 ff ff       	jmp    80104e90 <alltraps>

80105c1b <vector232>:
.globl vector232
vector232:
  pushl $0
80105c1b:	6a 00                	push   $0x0
  pushl $232
80105c1d:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105c22:	e9 69 f2 ff ff       	jmp    80104e90 <alltraps>

80105c27 <vector233>:
.globl vector233
vector233:
  pushl $0
80105c27:	6a 00                	push   $0x0
  pushl $233
80105c29:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105c2e:	e9 5d f2 ff ff       	jmp    80104e90 <alltraps>

80105c33 <vector234>:
.globl vector234
vector234:
  pushl $0
80105c33:	6a 00                	push   $0x0
  pushl $234
80105c35:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105c3a:	e9 51 f2 ff ff       	jmp    80104e90 <alltraps>

80105c3f <vector235>:
.globl vector235
vector235:
  pushl $0
80105c3f:	6a 00                	push   $0x0
  pushl $235
80105c41:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105c46:	e9 45 f2 ff ff       	jmp    80104e90 <alltraps>

80105c4b <vector236>:
.globl vector236
vector236:
  pushl $0
80105c4b:	6a 00                	push   $0x0
  pushl $236
80105c4d:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105c52:	e9 39 f2 ff ff       	jmp    80104e90 <alltraps>

80105c57 <vector237>:
.globl vector237
vector237:
  pushl $0
80105c57:	6a 00                	push   $0x0
  pushl $237
80105c59:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105c5e:	e9 2d f2 ff ff       	jmp    80104e90 <alltraps>

80105c63 <vector238>:
.globl vector238
vector238:
  pushl $0
80105c63:	6a 00                	push   $0x0
  pushl $238
80105c65:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105c6a:	e9 21 f2 ff ff       	jmp    80104e90 <alltraps>

80105c6f <vector239>:
.globl vector239
vector239:
  pushl $0
80105c6f:	6a 00                	push   $0x0
  pushl $239
80105c71:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105c76:	e9 15 f2 ff ff       	jmp    80104e90 <alltraps>

80105c7b <vector240>:
.globl vector240
vector240:
  pushl $0
80105c7b:	6a 00                	push   $0x0
  pushl $240
80105c7d:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105c82:	e9 09 f2 ff ff       	jmp    80104e90 <alltraps>

80105c87 <vector241>:
.globl vector241
vector241:
  pushl $0
80105c87:	6a 00                	push   $0x0
  pushl $241
80105c89:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105c8e:	e9 fd f1 ff ff       	jmp    80104e90 <alltraps>

80105c93 <vector242>:
.globl vector242
vector242:
  pushl $0
80105c93:	6a 00                	push   $0x0
  pushl $242
80105c95:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105c9a:	e9 f1 f1 ff ff       	jmp    80104e90 <alltraps>

80105c9f <vector243>:
.globl vector243
vector243:
  pushl $0
80105c9f:	6a 00                	push   $0x0
  pushl $243
80105ca1:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105ca6:	e9 e5 f1 ff ff       	jmp    80104e90 <alltraps>

80105cab <vector244>:
.globl vector244
vector244:
  pushl $0
80105cab:	6a 00                	push   $0x0
  pushl $244
80105cad:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105cb2:	e9 d9 f1 ff ff       	jmp    80104e90 <alltraps>

80105cb7 <vector245>:
.globl vector245
vector245:
  pushl $0
80105cb7:	6a 00                	push   $0x0
  pushl $245
80105cb9:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105cbe:	e9 cd f1 ff ff       	jmp    80104e90 <alltraps>

80105cc3 <vector246>:
.globl vector246
vector246:
  pushl $0
80105cc3:	6a 00                	push   $0x0
  pushl $246
80105cc5:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105cca:	e9 c1 f1 ff ff       	jmp    80104e90 <alltraps>

80105ccf <vector247>:
.globl vector247
vector247:
  pushl $0
80105ccf:	6a 00                	push   $0x0
  pushl $247
80105cd1:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105cd6:	e9 b5 f1 ff ff       	jmp    80104e90 <alltraps>

80105cdb <vector248>:
.globl vector248
vector248:
  pushl $0
80105cdb:	6a 00                	push   $0x0
  pushl $248
80105cdd:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105ce2:	e9 a9 f1 ff ff       	jmp    80104e90 <alltraps>

80105ce7 <vector249>:
.globl vector249
vector249:
  pushl $0
80105ce7:	6a 00                	push   $0x0
  pushl $249
80105ce9:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105cee:	e9 9d f1 ff ff       	jmp    80104e90 <alltraps>

80105cf3 <vector250>:
.globl vector250
vector250:
  pushl $0
80105cf3:	6a 00                	push   $0x0
  pushl $250
80105cf5:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105cfa:	e9 91 f1 ff ff       	jmp    80104e90 <alltraps>

80105cff <vector251>:
.globl vector251
vector251:
  pushl $0
80105cff:	6a 00                	push   $0x0
  pushl $251
80105d01:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105d06:	e9 85 f1 ff ff       	jmp    80104e90 <alltraps>

80105d0b <vector252>:
.globl vector252
vector252:
  pushl $0
80105d0b:	6a 00                	push   $0x0
  pushl $252
80105d0d:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105d12:	e9 79 f1 ff ff       	jmp    80104e90 <alltraps>

80105d17 <vector253>:
.globl vector253
vector253:
  pushl $0
80105d17:	6a 00                	push   $0x0
  pushl $253
80105d19:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105d1e:	e9 6d f1 ff ff       	jmp    80104e90 <alltraps>

80105d23 <vector254>:
.globl vector254
vector254:
  pushl $0
80105d23:	6a 00                	push   $0x0
  pushl $254
80105d25:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105d2a:	e9 61 f1 ff ff       	jmp    80104e90 <alltraps>

80105d2f <vector255>:
.globl vector255
vector255:
  pushl $0
80105d2f:	6a 00                	push   $0x0
  pushl $255
80105d31:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105d36:	e9 55 f1 ff ff       	jmp    80104e90 <alltraps>

80105d3b <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105d3b:	55                   	push   %ebp
80105d3c:	89 e5                	mov    %esp,%ebp
80105d3e:	57                   	push   %edi
80105d3f:	56                   	push   %esi
80105d40:	53                   	push   %ebx
80105d41:	83 ec 0c             	sub    $0xc,%esp
80105d44:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105d46:	c1 ea 16             	shr    $0x16,%edx
80105d49:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105d4c:	8b 1f                	mov    (%edi),%ebx
80105d4e:	f6 c3 01             	test   $0x1,%bl
80105d51:	74 22                	je     80105d75 <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105d53:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105d59:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105d5f:	c1 ee 0c             	shr    $0xc,%esi
80105d62:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105d68:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105d6b:	89 d8                	mov    %ebx,%eax
80105d6d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105d70:	5b                   	pop    %ebx
80105d71:	5e                   	pop    %esi
80105d72:	5f                   	pop    %edi
80105d73:	5d                   	pop    %ebp
80105d74:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc2(-2)) == 0)
80105d75:	85 c9                	test   %ecx,%ecx
80105d77:	74 33                	je     80105dac <walkpgdir+0x71>
80105d79:	83 ec 0c             	sub    $0xc,%esp
80105d7c:	6a fe                	push   $0xfffffffe
80105d7e:	e8 db c3 ff ff       	call   8010215e <kalloc2>
80105d83:	89 c3                	mov    %eax,%ebx
80105d85:	83 c4 10             	add    $0x10,%esp
80105d88:	85 c0                	test   %eax,%eax
80105d8a:	74 df                	je     80105d6b <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105d8c:	83 ec 04             	sub    $0x4,%esp
80105d8f:	68 00 10 00 00       	push   $0x1000
80105d94:	6a 00                	push   $0x0
80105d96:	50                   	push   %eax
80105d97:	e8 f6 df ff ff       	call   80103d92 <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105d9c:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105da2:	83 c8 07             	or     $0x7,%eax
80105da5:	89 07                	mov    %eax,(%edi)
80105da7:	83 c4 10             	add    $0x10,%esp
80105daa:	eb b3                	jmp    80105d5f <walkpgdir+0x24>
      return 0;
80105dac:	bb 00 00 00 00       	mov    $0x0,%ebx
80105db1:	eb b8                	jmp    80105d6b <walkpgdir+0x30>

80105db3 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105db3:	55                   	push   %ebp
80105db4:	89 e5                	mov    %esp,%ebp
80105db6:	57                   	push   %edi
80105db7:	56                   	push   %esi
80105db8:	53                   	push   %ebx
80105db9:	83 ec 1c             	sub    $0x1c,%esp
80105dbc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105dbf:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105dc2:	89 d3                	mov    %edx,%ebx
80105dc4:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105dca:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105dce:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105dd4:	b9 01 00 00 00       	mov    $0x1,%ecx
80105dd9:	89 da                	mov    %ebx,%edx
80105ddb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105dde:	e8 58 ff ff ff       	call   80105d3b <walkpgdir>
80105de3:	85 c0                	test   %eax,%eax
80105de5:	74 2e                	je     80105e15 <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105de7:	f6 00 01             	testb  $0x1,(%eax)
80105dea:	75 1c                	jne    80105e08 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105dec:	89 f2                	mov    %esi,%edx
80105dee:	0b 55 0c             	or     0xc(%ebp),%edx
80105df1:	83 ca 01             	or     $0x1,%edx
80105df4:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105df6:	39 fb                	cmp    %edi,%ebx
80105df8:	74 28                	je     80105e22 <mappages+0x6f>
      break;
    a += PGSIZE;
80105dfa:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105e00:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105e06:	eb cc                	jmp    80105dd4 <mappages+0x21>
      panic("remap");
80105e08:	83 ec 0c             	sub    $0xc,%esp
80105e0b:	68 ec 6e 10 80       	push   $0x80106eec
80105e10:	e8 33 a5 ff ff       	call   80100348 <panic>
      return -1;
80105e15:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105e1a:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105e1d:	5b                   	pop    %ebx
80105e1e:	5e                   	pop    %esi
80105e1f:	5f                   	pop    %edi
80105e20:	5d                   	pop    %ebp
80105e21:	c3                   	ret    
  return 0;
80105e22:	b8 00 00 00 00       	mov    $0x0,%eax
80105e27:	eb f1                	jmp    80105e1a <mappages+0x67>

80105e29 <seginit>:
{
80105e29:	55                   	push   %ebp
80105e2a:	89 e5                	mov    %esp,%ebp
80105e2c:	53                   	push   %ebx
80105e2d:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105e30:	e8 f4 d4 ff ff       	call   80103329 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105e35:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105e3b:	66 c7 80 78 28 13 80 	movw   $0xffff,-0x7fecd788(%eax)
80105e42:	ff ff 
80105e44:	66 c7 80 7a 28 13 80 	movw   $0x0,-0x7fecd786(%eax)
80105e4b:	00 00 
80105e4d:	c6 80 7c 28 13 80 00 	movb   $0x0,-0x7fecd784(%eax)
80105e54:	0f b6 88 7d 28 13 80 	movzbl -0x7fecd783(%eax),%ecx
80105e5b:	83 e1 f0             	and    $0xfffffff0,%ecx
80105e5e:	83 c9 1a             	or     $0x1a,%ecx
80105e61:	83 e1 9f             	and    $0xffffff9f,%ecx
80105e64:	83 c9 80             	or     $0xffffff80,%ecx
80105e67:	88 88 7d 28 13 80    	mov    %cl,-0x7fecd783(%eax)
80105e6d:	0f b6 88 7e 28 13 80 	movzbl -0x7fecd782(%eax),%ecx
80105e74:	83 c9 0f             	or     $0xf,%ecx
80105e77:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e7a:	83 c9 c0             	or     $0xffffffc0,%ecx
80105e7d:	88 88 7e 28 13 80    	mov    %cl,-0x7fecd782(%eax)
80105e83:	c6 80 7f 28 13 80 00 	movb   $0x0,-0x7fecd781(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105e8a:	66 c7 80 80 28 13 80 	movw   $0xffff,-0x7fecd780(%eax)
80105e91:	ff ff 
80105e93:	66 c7 80 82 28 13 80 	movw   $0x0,-0x7fecd77e(%eax)
80105e9a:	00 00 
80105e9c:	c6 80 84 28 13 80 00 	movb   $0x0,-0x7fecd77c(%eax)
80105ea3:	0f b6 88 85 28 13 80 	movzbl -0x7fecd77b(%eax),%ecx
80105eaa:	83 e1 f0             	and    $0xfffffff0,%ecx
80105ead:	83 c9 12             	or     $0x12,%ecx
80105eb0:	83 e1 9f             	and    $0xffffff9f,%ecx
80105eb3:	83 c9 80             	or     $0xffffff80,%ecx
80105eb6:	88 88 85 28 13 80    	mov    %cl,-0x7fecd77b(%eax)
80105ebc:	0f b6 88 86 28 13 80 	movzbl -0x7fecd77a(%eax),%ecx
80105ec3:	83 c9 0f             	or     $0xf,%ecx
80105ec6:	83 e1 cf             	and    $0xffffffcf,%ecx
80105ec9:	83 c9 c0             	or     $0xffffffc0,%ecx
80105ecc:	88 88 86 28 13 80    	mov    %cl,-0x7fecd77a(%eax)
80105ed2:	c6 80 87 28 13 80 00 	movb   $0x0,-0x7fecd779(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80105ed9:	66 c7 80 88 28 13 80 	movw   $0xffff,-0x7fecd778(%eax)
80105ee0:	ff ff 
80105ee2:	66 c7 80 8a 28 13 80 	movw   $0x0,-0x7fecd776(%eax)
80105ee9:	00 00 
80105eeb:	c6 80 8c 28 13 80 00 	movb   $0x0,-0x7fecd774(%eax)
80105ef2:	c6 80 8d 28 13 80 fa 	movb   $0xfa,-0x7fecd773(%eax)
80105ef9:	0f b6 88 8e 28 13 80 	movzbl -0x7fecd772(%eax),%ecx
80105f00:	83 c9 0f             	or     $0xf,%ecx
80105f03:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f06:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f09:	88 88 8e 28 13 80    	mov    %cl,-0x7fecd772(%eax)
80105f0f:	c6 80 8f 28 13 80 00 	movb   $0x0,-0x7fecd771(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80105f16:	66 c7 80 90 28 13 80 	movw   $0xffff,-0x7fecd770(%eax)
80105f1d:	ff ff 
80105f1f:	66 c7 80 92 28 13 80 	movw   $0x0,-0x7fecd76e(%eax)
80105f26:	00 00 
80105f28:	c6 80 94 28 13 80 00 	movb   $0x0,-0x7fecd76c(%eax)
80105f2f:	c6 80 95 28 13 80 f2 	movb   $0xf2,-0x7fecd76b(%eax)
80105f36:	0f b6 88 96 28 13 80 	movzbl -0x7fecd76a(%eax),%ecx
80105f3d:	83 c9 0f             	or     $0xf,%ecx
80105f40:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f43:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f46:	88 88 96 28 13 80    	mov    %cl,-0x7fecd76a(%eax)
80105f4c:	c6 80 97 28 13 80 00 	movb   $0x0,-0x7fecd769(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80105f53:	05 70 28 13 80       	add    $0x80132870,%eax
  pd[0] = size-1;
80105f58:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80105f5e:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80105f62:	c1 e8 10             	shr    $0x10,%eax
80105f65:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80105f69:	8d 45 f2             	lea    -0xe(%ebp),%eax
80105f6c:	0f 01 10             	lgdtl  (%eax)
}
80105f6f:	83 c4 14             	add    $0x14,%esp
80105f72:	5b                   	pop    %ebx
80105f73:	5d                   	pop    %ebp
80105f74:	c3                   	ret    

80105f75 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80105f75:	55                   	push   %ebp
80105f76:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80105f78:	a1 24 55 13 80       	mov    0x80135524,%eax
80105f7d:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80105f82:	0f 22 d8             	mov    %eax,%cr3
}
80105f85:	5d                   	pop    %ebp
80105f86:	c3                   	ret    

80105f87 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80105f87:	55                   	push   %ebp
80105f88:	89 e5                	mov    %esp,%ebp
80105f8a:	57                   	push   %edi
80105f8b:	56                   	push   %esi
80105f8c:	53                   	push   %ebx
80105f8d:	83 ec 1c             	sub    $0x1c,%esp
80105f90:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
80105f93:	85 f6                	test   %esi,%esi
80105f95:	0f 84 dd 00 00 00    	je     80106078 <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
80105f9b:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
80105f9f:	0f 84 e0 00 00 00    	je     80106085 <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
80105fa5:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
80105fa9:	0f 84 e3 00 00 00    	je     80106092 <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
80105faf:	e8 55 dc ff ff       	call   80103c09 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80105fb4:	e8 14 d3 ff ff       	call   801032cd <mycpu>
80105fb9:	89 c3                	mov    %eax,%ebx
80105fbb:	e8 0d d3 ff ff       	call   801032cd <mycpu>
80105fc0:	8d 78 08             	lea    0x8(%eax),%edi
80105fc3:	e8 05 d3 ff ff       	call   801032cd <mycpu>
80105fc8:	83 c0 08             	add    $0x8,%eax
80105fcb:	c1 e8 10             	shr    $0x10,%eax
80105fce:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105fd1:	e8 f7 d2 ff ff       	call   801032cd <mycpu>
80105fd6:	83 c0 08             	add    $0x8,%eax
80105fd9:	c1 e8 18             	shr    $0x18,%eax
80105fdc:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80105fe3:	67 00 
80105fe5:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80105fec:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
80105ff0:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80105ff6:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80105ffd:	83 e2 f0             	and    $0xfffffff0,%edx
80106000:	83 ca 19             	or     $0x19,%edx
80106003:	83 e2 9f             	and    $0xffffff9f,%edx
80106006:	83 ca 80             	or     $0xffffff80,%edx
80106009:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
8010600f:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
80106016:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
8010601c:	e8 ac d2 ff ff       	call   801032cd <mycpu>
80106021:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80106028:	83 e2 ef             	and    $0xffffffef,%edx
8010602b:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80106031:	e8 97 d2 ff ff       	call   801032cd <mycpu>
80106036:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
8010603c:	8b 5e 08             	mov    0x8(%esi),%ebx
8010603f:	e8 89 d2 ff ff       	call   801032cd <mycpu>
80106044:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010604a:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
8010604d:	e8 7b d2 ff ff       	call   801032cd <mycpu>
80106052:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
80106058:	b8 28 00 00 00       	mov    $0x28,%eax
8010605d:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
80106060:	8b 46 04             	mov    0x4(%esi),%eax
80106063:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
80106068:	0f 22 d8             	mov    %eax,%cr3
  popcli();
8010606b:	e8 d6 db ff ff       	call   80103c46 <popcli>
}
80106070:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106073:	5b                   	pop    %ebx
80106074:	5e                   	pop    %esi
80106075:	5f                   	pop    %edi
80106076:	5d                   	pop    %ebp
80106077:	c3                   	ret    
    panic("switchuvm: no process");
80106078:	83 ec 0c             	sub    $0xc,%esp
8010607b:	68 f2 6e 10 80       	push   $0x80106ef2
80106080:	e8 c3 a2 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
80106085:	83 ec 0c             	sub    $0xc,%esp
80106088:	68 08 6f 10 80       	push   $0x80106f08
8010608d:	e8 b6 a2 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
80106092:	83 ec 0c             	sub    $0xc,%esp
80106095:	68 1d 6f 10 80       	push   $0x80106f1d
8010609a:	e8 a9 a2 ff ff       	call   80100348 <panic>

8010609f <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
8010609f:	55                   	push   %ebp
801060a0:	89 e5                	mov    %esp,%ebp
801060a2:	56                   	push   %esi
801060a3:	53                   	push   %ebx
801060a4:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
801060a7:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801060ad:	77 51                	ja     80106100 <inituvm+0x61>
    panic("inituvm: more than a page");
  mem = kalloc2(-2);
801060af:	83 ec 0c             	sub    $0xc,%esp
801060b2:	6a fe                	push   $0xfffffffe
801060b4:	e8 a5 c0 ff ff       	call   8010215e <kalloc2>
801060b9:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
801060bb:	83 c4 0c             	add    $0xc,%esp
801060be:	68 00 10 00 00       	push   $0x1000
801060c3:	6a 00                	push   $0x0
801060c5:	50                   	push   %eax
801060c6:	e8 c7 dc ff ff       	call   80103d92 <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
801060cb:	83 c4 08             	add    $0x8,%esp
801060ce:	6a 06                	push   $0x6
801060d0:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801060d6:	50                   	push   %eax
801060d7:	b9 00 10 00 00       	mov    $0x1000,%ecx
801060dc:	ba 00 00 00 00       	mov    $0x0,%edx
801060e1:	8b 45 08             	mov    0x8(%ebp),%eax
801060e4:	e8 ca fc ff ff       	call   80105db3 <mappages>
  memmove(mem, init, sz);
801060e9:	83 c4 0c             	add    $0xc,%esp
801060ec:	56                   	push   %esi
801060ed:	ff 75 0c             	pushl  0xc(%ebp)
801060f0:	53                   	push   %ebx
801060f1:	e8 17 dd ff ff       	call   80103e0d <memmove>
}
801060f6:	83 c4 10             	add    $0x10,%esp
801060f9:	8d 65 f8             	lea    -0x8(%ebp),%esp
801060fc:	5b                   	pop    %ebx
801060fd:	5e                   	pop    %esi
801060fe:	5d                   	pop    %ebp
801060ff:	c3                   	ret    
    panic("inituvm: more than a page");
80106100:	83 ec 0c             	sub    $0xc,%esp
80106103:	68 31 6f 10 80       	push   $0x80106f31
80106108:	e8 3b a2 ff ff       	call   80100348 <panic>

8010610d <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
8010610d:	55                   	push   %ebp
8010610e:	89 e5                	mov    %esp,%ebp
80106110:	57                   	push   %edi
80106111:	56                   	push   %esi
80106112:	53                   	push   %ebx
80106113:	83 ec 0c             	sub    $0xc,%esp
80106116:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80106119:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
80106120:	75 07                	jne    80106129 <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80106122:	bb 00 00 00 00       	mov    $0x0,%ebx
80106127:	eb 3c                	jmp    80106165 <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
80106129:	83 ec 0c             	sub    $0xc,%esp
8010612c:	68 ec 6f 10 80       	push   $0x80106fec
80106131:	e8 12 a2 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
80106136:	83 ec 0c             	sub    $0xc,%esp
80106139:	68 4b 6f 10 80       	push   $0x80106f4b
8010613e:	e8 05 a2 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
80106143:	05 00 00 00 80       	add    $0x80000000,%eax
80106148:	56                   	push   %esi
80106149:	89 da                	mov    %ebx,%edx
8010614b:	03 55 14             	add    0x14(%ebp),%edx
8010614e:	52                   	push   %edx
8010614f:	50                   	push   %eax
80106150:	ff 75 10             	pushl  0x10(%ebp)
80106153:	e8 1b b6 ff ff       	call   80101773 <readi>
80106158:	83 c4 10             	add    $0x10,%esp
8010615b:	39 f0                	cmp    %esi,%eax
8010615d:	75 47                	jne    801061a6 <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
8010615f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106165:	39 fb                	cmp    %edi,%ebx
80106167:	73 30                	jae    80106199 <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80106169:	89 da                	mov    %ebx,%edx
8010616b:	03 55 0c             	add    0xc(%ebp),%edx
8010616e:	b9 00 00 00 00       	mov    $0x0,%ecx
80106173:	8b 45 08             	mov    0x8(%ebp),%eax
80106176:	e8 c0 fb ff ff       	call   80105d3b <walkpgdir>
8010617b:	85 c0                	test   %eax,%eax
8010617d:	74 b7                	je     80106136 <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
8010617f:	8b 00                	mov    (%eax),%eax
80106181:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
80106186:	89 fe                	mov    %edi,%esi
80106188:	29 de                	sub    %ebx,%esi
8010618a:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106190:	76 b1                	jbe    80106143 <loaduvm+0x36>
      n = PGSIZE;
80106192:	be 00 10 00 00       	mov    $0x1000,%esi
80106197:	eb aa                	jmp    80106143 <loaduvm+0x36>
      return -1;
  }
  return 0;
80106199:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010619e:	8d 65 f4             	lea    -0xc(%ebp),%esp
801061a1:	5b                   	pop    %ebx
801061a2:	5e                   	pop    %esi
801061a3:	5f                   	pop    %edi
801061a4:	5d                   	pop    %ebp
801061a5:	c3                   	ret    
      return -1;
801061a6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061ab:	eb f1                	jmp    8010619e <loaduvm+0x91>

801061ad <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801061ad:	55                   	push   %ebp
801061ae:	89 e5                	mov    %esp,%ebp
801061b0:	57                   	push   %edi
801061b1:	56                   	push   %esi
801061b2:	53                   	push   %ebx
801061b3:	83 ec 0c             	sub    $0xc,%esp
801061b6:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801061b9:	39 7d 10             	cmp    %edi,0x10(%ebp)
801061bc:	73 11                	jae    801061cf <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
801061be:	8b 45 10             	mov    0x10(%ebp),%eax
801061c1:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801061c7:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801061cd:	eb 19                	jmp    801061e8 <deallocuvm+0x3b>
    return oldsz;
801061cf:	89 f8                	mov    %edi,%eax
801061d1:	eb 64                	jmp    80106237 <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
801061d3:	c1 eb 16             	shr    $0x16,%ebx
801061d6:	83 c3 01             	add    $0x1,%ebx
801061d9:	c1 e3 16             	shl    $0x16,%ebx
801061dc:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801061e2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801061e8:	39 fb                	cmp    %edi,%ebx
801061ea:	73 48                	jae    80106234 <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
801061ec:	b9 00 00 00 00       	mov    $0x0,%ecx
801061f1:	89 da                	mov    %ebx,%edx
801061f3:	8b 45 08             	mov    0x8(%ebp),%eax
801061f6:	e8 40 fb ff ff       	call   80105d3b <walkpgdir>
801061fb:	89 c6                	mov    %eax,%esi
    if(!pte)
801061fd:	85 c0                	test   %eax,%eax
801061ff:	74 d2                	je     801061d3 <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
80106201:	8b 00                	mov    (%eax),%eax
80106203:	a8 01                	test   $0x1,%al
80106205:	74 db                	je     801061e2 <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
80106207:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010620c:	74 19                	je     80106227 <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
8010620e:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106213:	83 ec 0c             	sub    $0xc,%esp
80106216:	50                   	push   %eax
80106217:	e8 88 bd ff ff       	call   80101fa4 <kfree>
      *pte = 0;
8010621c:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80106222:	83 c4 10             	add    $0x10,%esp
80106225:	eb bb                	jmp    801061e2 <deallocuvm+0x35>
        panic("kfree");
80106227:	83 ec 0c             	sub    $0xc,%esp
8010622a:	68 86 68 10 80       	push   $0x80106886
8010622f:	e8 14 a1 ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
80106234:	8b 45 10             	mov    0x10(%ebp),%eax
}
80106237:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010623a:	5b                   	pop    %ebx
8010623b:	5e                   	pop    %esi
8010623c:	5f                   	pop    %edi
8010623d:	5d                   	pop    %ebp
8010623e:	c3                   	ret    

8010623f <allocuvm>:
{
8010623f:	55                   	push   %ebp
80106240:	89 e5                	mov    %esp,%ebp
80106242:	57                   	push   %edi
80106243:	56                   	push   %esi
80106244:	53                   	push   %ebx
80106245:	83 ec 1c             	sub    $0x1c,%esp
80106248:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
8010624b:	89 7d e4             	mov    %edi,-0x1c(%ebp)
8010624e:	85 ff                	test   %edi,%edi
80106250:	0f 88 cf 00 00 00    	js     80106325 <allocuvm+0xe6>
  if(newsz < oldsz)
80106256:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106259:	72 6a                	jb     801062c5 <allocuvm+0x86>
  a = PGROUNDUP(oldsz);
8010625b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010625e:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106264:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
8010626a:	39 fb                	cmp    %edi,%ebx
8010626c:	0f 83 ba 00 00 00    	jae    8010632c <allocuvm+0xed>
    mem = kalloc2(myproc()->pid);
80106272:	e8 cd d0 ff ff       	call   80103344 <myproc>
80106277:	83 ec 0c             	sub    $0xc,%esp
8010627a:	ff 70 10             	pushl  0x10(%eax)
8010627d:	e8 dc be ff ff       	call   8010215e <kalloc2>
80106282:	89 c6                	mov    %eax,%esi
    if(mem == 0){
80106284:	83 c4 10             	add    $0x10,%esp
80106287:	85 c0                	test   %eax,%eax
80106289:	74 42                	je     801062cd <allocuvm+0x8e>
    memset(mem, 0, PGSIZE);
8010628b:	83 ec 04             	sub    $0x4,%esp
8010628e:	68 00 10 00 00       	push   $0x1000
80106293:	6a 00                	push   $0x0
80106295:	50                   	push   %eax
80106296:	e8 f7 da ff ff       	call   80103d92 <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
8010629b:	83 c4 08             	add    $0x8,%esp
8010629e:	6a 06                	push   $0x6
801062a0:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
801062a6:	50                   	push   %eax
801062a7:	b9 00 10 00 00       	mov    $0x1000,%ecx
801062ac:	89 da                	mov    %ebx,%edx
801062ae:	8b 45 08             	mov    0x8(%ebp),%eax
801062b1:	e8 fd fa ff ff       	call   80105db3 <mappages>
801062b6:	83 c4 10             	add    $0x10,%esp
801062b9:	85 c0                	test   %eax,%eax
801062bb:	78 38                	js     801062f5 <allocuvm+0xb6>
  for(; a < newsz; a += PGSIZE){
801062bd:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801062c3:	eb a5                	jmp    8010626a <allocuvm+0x2b>
    return oldsz;
801062c5:	8b 45 0c             	mov    0xc(%ebp),%eax
801062c8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801062cb:	eb 5f                	jmp    8010632c <allocuvm+0xed>
      cprintf("allocuvm out of memory\n");
801062cd:	83 ec 0c             	sub    $0xc,%esp
801062d0:	68 69 6f 10 80       	push   $0x80106f69
801062d5:	e8 31 a3 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801062da:	83 c4 0c             	add    $0xc,%esp
801062dd:	ff 75 0c             	pushl  0xc(%ebp)
801062e0:	57                   	push   %edi
801062e1:	ff 75 08             	pushl  0x8(%ebp)
801062e4:	e8 c4 fe ff ff       	call   801061ad <deallocuvm>
      return 0;
801062e9:	83 c4 10             	add    $0x10,%esp
801062ec:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801062f3:	eb 37                	jmp    8010632c <allocuvm+0xed>
      cprintf("allocuvm out of memory (2)\n");
801062f5:	83 ec 0c             	sub    $0xc,%esp
801062f8:	68 81 6f 10 80       	push   $0x80106f81
801062fd:	e8 09 a3 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106302:	83 c4 0c             	add    $0xc,%esp
80106305:	ff 75 0c             	pushl  0xc(%ebp)
80106308:	57                   	push   %edi
80106309:	ff 75 08             	pushl  0x8(%ebp)
8010630c:	e8 9c fe ff ff       	call   801061ad <deallocuvm>
      kfree(mem);
80106311:	89 34 24             	mov    %esi,(%esp)
80106314:	e8 8b bc ff ff       	call   80101fa4 <kfree>
      return 0;
80106319:	83 c4 10             	add    $0x10,%esp
8010631c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106323:	eb 07                	jmp    8010632c <allocuvm+0xed>
    return 0;
80106325:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
8010632c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010632f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106332:	5b                   	pop    %ebx
80106333:	5e                   	pop    %esi
80106334:	5f                   	pop    %edi
80106335:	5d                   	pop    %ebp
80106336:	c3                   	ret    

80106337 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80106337:	55                   	push   %ebp
80106338:	89 e5                	mov    %esp,%ebp
8010633a:	56                   	push   %esi
8010633b:	53                   	push   %ebx
8010633c:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
8010633f:	85 f6                	test   %esi,%esi
80106341:	74 1a                	je     8010635d <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
80106343:	83 ec 04             	sub    $0x4,%esp
80106346:	6a 00                	push   $0x0
80106348:	68 00 00 00 80       	push   $0x80000000
8010634d:	56                   	push   %esi
8010634e:	e8 5a fe ff ff       	call   801061ad <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80106353:	83 c4 10             	add    $0x10,%esp
80106356:	bb 00 00 00 00       	mov    $0x0,%ebx
8010635b:	eb 10                	jmp    8010636d <freevm+0x36>
    panic("freevm: no pgdir");
8010635d:	83 ec 0c             	sub    $0xc,%esp
80106360:	68 9d 6f 10 80       	push   $0x80106f9d
80106365:	e8 de 9f ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
8010636a:	83 c3 01             	add    $0x1,%ebx
8010636d:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
80106373:	77 1f                	ja     80106394 <freevm+0x5d>
    if(pgdir[i] & PTE_P){
80106375:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
80106378:	a8 01                	test   $0x1,%al
8010637a:	74 ee                	je     8010636a <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
8010637c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106381:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106386:	83 ec 0c             	sub    $0xc,%esp
80106389:	50                   	push   %eax
8010638a:	e8 15 bc ff ff       	call   80101fa4 <kfree>
8010638f:	83 c4 10             	add    $0x10,%esp
80106392:	eb d6                	jmp    8010636a <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
80106394:	83 ec 0c             	sub    $0xc,%esp
80106397:	56                   	push   %esi
80106398:	e8 07 bc ff ff       	call   80101fa4 <kfree>
}
8010639d:	83 c4 10             	add    $0x10,%esp
801063a0:	8d 65 f8             	lea    -0x8(%ebp),%esp
801063a3:	5b                   	pop    %ebx
801063a4:	5e                   	pop    %esi
801063a5:	5d                   	pop    %ebp
801063a6:	c3                   	ret    

801063a7 <setupkvm>:
{
801063a7:	55                   	push   %ebp
801063a8:	89 e5                	mov    %esp,%ebp
801063aa:	56                   	push   %esi
801063ab:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc2(-2)) == 0)
801063ac:	83 ec 0c             	sub    $0xc,%esp
801063af:	6a fe                	push   $0xfffffffe
801063b1:	e8 a8 bd ff ff       	call   8010215e <kalloc2>
801063b6:	89 c6                	mov    %eax,%esi
801063b8:	83 c4 10             	add    $0x10,%esp
801063bb:	85 c0                	test   %eax,%eax
801063bd:	74 55                	je     80106414 <setupkvm+0x6d>
  memset(pgdir, 0, PGSIZE);
801063bf:	83 ec 04             	sub    $0x4,%esp
801063c2:	68 00 10 00 00       	push   $0x1000
801063c7:	6a 00                	push   $0x0
801063c9:	50                   	push   %eax
801063ca:	e8 c3 d9 ff ff       	call   80103d92 <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801063cf:	83 c4 10             	add    $0x10,%esp
801063d2:	bb 20 a4 10 80       	mov    $0x8010a420,%ebx
801063d7:	81 fb 60 a4 10 80    	cmp    $0x8010a460,%ebx
801063dd:	73 35                	jae    80106414 <setupkvm+0x6d>
                (uint)k->phys_start, k->perm) < 0) {
801063df:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
801063e2:	8b 4b 08             	mov    0x8(%ebx),%ecx
801063e5:	29 c1                	sub    %eax,%ecx
801063e7:	83 ec 08             	sub    $0x8,%esp
801063ea:	ff 73 0c             	pushl  0xc(%ebx)
801063ed:	50                   	push   %eax
801063ee:	8b 13                	mov    (%ebx),%edx
801063f0:	89 f0                	mov    %esi,%eax
801063f2:	e8 bc f9 ff ff       	call   80105db3 <mappages>
801063f7:	83 c4 10             	add    $0x10,%esp
801063fa:	85 c0                	test   %eax,%eax
801063fc:	78 05                	js     80106403 <setupkvm+0x5c>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801063fe:	83 c3 10             	add    $0x10,%ebx
80106401:	eb d4                	jmp    801063d7 <setupkvm+0x30>
      freevm(pgdir);
80106403:	83 ec 0c             	sub    $0xc,%esp
80106406:	56                   	push   %esi
80106407:	e8 2b ff ff ff       	call   80106337 <freevm>
      return 0;
8010640c:	83 c4 10             	add    $0x10,%esp
8010640f:	be 00 00 00 00       	mov    $0x0,%esi
}
80106414:	89 f0                	mov    %esi,%eax
80106416:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106419:	5b                   	pop    %ebx
8010641a:	5e                   	pop    %esi
8010641b:	5d                   	pop    %ebp
8010641c:	c3                   	ret    

8010641d <kvmalloc>:
{
8010641d:	55                   	push   %ebp
8010641e:	89 e5                	mov    %esp,%ebp
80106420:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80106423:	e8 7f ff ff ff       	call   801063a7 <setupkvm>
80106428:	a3 24 55 13 80       	mov    %eax,0x80135524
  switchkvm();
8010642d:	e8 43 fb ff ff       	call   80105f75 <switchkvm>
}
80106432:	c9                   	leave  
80106433:	c3                   	ret    

80106434 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80106434:	55                   	push   %ebp
80106435:	89 e5                	mov    %esp,%ebp
80106437:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010643a:	b9 00 00 00 00       	mov    $0x0,%ecx
8010643f:	8b 55 0c             	mov    0xc(%ebp),%edx
80106442:	8b 45 08             	mov    0x8(%ebp),%eax
80106445:	e8 f1 f8 ff ff       	call   80105d3b <walkpgdir>
  if(pte == 0)
8010644a:	85 c0                	test   %eax,%eax
8010644c:	74 05                	je     80106453 <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
8010644e:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
80106451:	c9                   	leave  
80106452:	c3                   	ret    
    panic("clearpteu");
80106453:	83 ec 0c             	sub    $0xc,%esp
80106456:	68 ae 6f 10 80       	push   $0x80106fae
8010645b:	e8 e8 9e ff ff       	call   80100348 <panic>

80106460 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz, uint childPid)
{
80106460:	55                   	push   %ebp
80106461:	89 e5                	mov    %esp,%ebp
80106463:	57                   	push   %edi
80106464:	56                   	push   %esi
80106465:	53                   	push   %ebx
80106466:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80106469:	e8 39 ff ff ff       	call   801063a7 <setupkvm>
8010646e:	89 45 dc             	mov    %eax,-0x24(%ebp)
80106471:	85 c0                	test   %eax,%eax
80106473:	0f 84 d1 00 00 00    	je     8010654a <copyuvm+0xea>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80106479:	bf 00 00 00 00       	mov    $0x0,%edi
8010647e:	89 fe                	mov    %edi,%esi
80106480:	3b 75 0c             	cmp    0xc(%ebp),%esi
80106483:	0f 83 c1 00 00 00    	jae    8010654a <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80106489:	89 75 e4             	mov    %esi,-0x1c(%ebp)
8010648c:	b9 00 00 00 00       	mov    $0x0,%ecx
80106491:	89 f2                	mov    %esi,%edx
80106493:	8b 45 08             	mov    0x8(%ebp),%eax
80106496:	e8 a0 f8 ff ff       	call   80105d3b <walkpgdir>
8010649b:	85 c0                	test   %eax,%eax
8010649d:	74 70                	je     8010650f <copyuvm+0xaf>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
8010649f:	8b 18                	mov    (%eax),%ebx
801064a1:	f6 c3 01             	test   $0x1,%bl
801064a4:	74 76                	je     8010651c <copyuvm+0xbc>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
801064a6:	89 df                	mov    %ebx,%edi
801064a8:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
    flags = PTE_FLAGS(*pte);
801064ae:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
801064b4:	89 5d e0             	mov    %ebx,-0x20(%ebp)
    if((mem = kalloc2(childPid)) == 0)
801064b7:	83 ec 0c             	sub    $0xc,%esp
801064ba:	ff 75 10             	pushl  0x10(%ebp)
801064bd:	e8 9c bc ff ff       	call   8010215e <kalloc2>
801064c2:	89 c3                	mov    %eax,%ebx
801064c4:	83 c4 10             	add    $0x10,%esp
801064c7:	85 c0                	test   %eax,%eax
801064c9:	74 6a                	je     80106535 <copyuvm+0xd5>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
801064cb:	81 c7 00 00 00 80    	add    $0x80000000,%edi
801064d1:	83 ec 04             	sub    $0x4,%esp
801064d4:	68 00 10 00 00       	push   $0x1000
801064d9:	57                   	push   %edi
801064da:	50                   	push   %eax
801064db:	e8 2d d9 ff ff       	call   80103e0d <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
801064e0:	83 c4 08             	add    $0x8,%esp
801064e3:	ff 75 e0             	pushl  -0x20(%ebp)
801064e6:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801064ec:	50                   	push   %eax
801064ed:	b9 00 10 00 00       	mov    $0x1000,%ecx
801064f2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801064f5:	8b 45 dc             	mov    -0x24(%ebp),%eax
801064f8:	e8 b6 f8 ff ff       	call   80105db3 <mappages>
801064fd:	83 c4 10             	add    $0x10,%esp
80106500:	85 c0                	test   %eax,%eax
80106502:	78 25                	js     80106529 <copyuvm+0xc9>
  for(i = 0; i < sz; i += PGSIZE){
80106504:	81 c6 00 10 00 00    	add    $0x1000,%esi
8010650a:	e9 71 ff ff ff       	jmp    80106480 <copyuvm+0x20>
      panic("copyuvm: pte should exist");
8010650f:	83 ec 0c             	sub    $0xc,%esp
80106512:	68 b8 6f 10 80       	push   $0x80106fb8
80106517:	e8 2c 9e ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
8010651c:	83 ec 0c             	sub    $0xc,%esp
8010651f:	68 d2 6f 10 80       	push   $0x80106fd2
80106524:	e8 1f 9e ff ff       	call   80100348 <panic>
      kfree(mem);
80106529:	83 ec 0c             	sub    $0xc,%esp
8010652c:	53                   	push   %ebx
8010652d:	e8 72 ba ff ff       	call   80101fa4 <kfree>
      goto bad;
80106532:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
80106535:	83 ec 0c             	sub    $0xc,%esp
80106538:	ff 75 dc             	pushl  -0x24(%ebp)
8010653b:	e8 f7 fd ff ff       	call   80106337 <freevm>
  return 0;
80106540:	83 c4 10             	add    $0x10,%esp
80106543:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
8010654a:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010654d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106550:	5b                   	pop    %ebx
80106551:	5e                   	pop    %esi
80106552:	5f                   	pop    %edi
80106553:	5d                   	pop    %ebp
80106554:	c3                   	ret    

80106555 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80106555:	55                   	push   %ebp
80106556:	89 e5                	mov    %esp,%ebp
80106558:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010655b:	b9 00 00 00 00       	mov    $0x0,%ecx
80106560:	8b 55 0c             	mov    0xc(%ebp),%edx
80106563:	8b 45 08             	mov    0x8(%ebp),%eax
80106566:	e8 d0 f7 ff ff       	call   80105d3b <walkpgdir>
  if((*pte & PTE_P) == 0)
8010656b:	8b 00                	mov    (%eax),%eax
8010656d:	a8 01                	test   $0x1,%al
8010656f:	74 10                	je     80106581 <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
80106571:	a8 04                	test   $0x4,%al
80106573:	74 13                	je     80106588 <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
80106575:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010657a:	05 00 00 00 80       	add    $0x80000000,%eax
}
8010657f:	c9                   	leave  
80106580:	c3                   	ret    
    return 0;
80106581:	b8 00 00 00 00       	mov    $0x0,%eax
80106586:	eb f7                	jmp    8010657f <uva2ka+0x2a>
    return 0;
80106588:	b8 00 00 00 00       	mov    $0x0,%eax
8010658d:	eb f0                	jmp    8010657f <uva2ka+0x2a>

8010658f <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
8010658f:	55                   	push   %ebp
80106590:	89 e5                	mov    %esp,%ebp
80106592:	57                   	push   %edi
80106593:	56                   	push   %esi
80106594:	53                   	push   %ebx
80106595:	83 ec 0c             	sub    $0xc,%esp
80106598:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
8010659b:	eb 25                	jmp    801065c2 <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
8010659d:	8b 55 0c             	mov    0xc(%ebp),%edx
801065a0:	29 f2                	sub    %esi,%edx
801065a2:	01 d0                	add    %edx,%eax
801065a4:	83 ec 04             	sub    $0x4,%esp
801065a7:	53                   	push   %ebx
801065a8:	ff 75 10             	pushl  0x10(%ebp)
801065ab:	50                   	push   %eax
801065ac:	e8 5c d8 ff ff       	call   80103e0d <memmove>
    len -= n;
801065b1:	29 df                	sub    %ebx,%edi
    buf += n;
801065b3:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
801065b6:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
801065bc:	89 45 0c             	mov    %eax,0xc(%ebp)
801065bf:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
801065c2:	85 ff                	test   %edi,%edi
801065c4:	74 2f                	je     801065f5 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
801065c6:	8b 75 0c             	mov    0xc(%ebp),%esi
801065c9:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
801065cf:	83 ec 08             	sub    $0x8,%esp
801065d2:	56                   	push   %esi
801065d3:	ff 75 08             	pushl  0x8(%ebp)
801065d6:	e8 7a ff ff ff       	call   80106555 <uva2ka>
    if(pa0 == 0)
801065db:	83 c4 10             	add    $0x10,%esp
801065de:	85 c0                	test   %eax,%eax
801065e0:	74 20                	je     80106602 <copyout+0x73>
    n = PGSIZE - (va - va0);
801065e2:	89 f3                	mov    %esi,%ebx
801065e4:	2b 5d 0c             	sub    0xc(%ebp),%ebx
801065e7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
801065ed:	39 df                	cmp    %ebx,%edi
801065ef:	73 ac                	jae    8010659d <copyout+0xe>
      n = len;
801065f1:	89 fb                	mov    %edi,%ebx
801065f3:	eb a8                	jmp    8010659d <copyout+0xe>
  }
  return 0;
801065f5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801065fa:	8d 65 f4             	lea    -0xc(%ebp),%esp
801065fd:	5b                   	pop    %ebx
801065fe:	5e                   	pop    %esi
801065ff:	5f                   	pop    %edi
80106600:	5d                   	pop    %ebp
80106601:	c3                   	ret    
      return -1;
80106602:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106607:	eb f1                	jmp    801065fa <copyout+0x6b>
