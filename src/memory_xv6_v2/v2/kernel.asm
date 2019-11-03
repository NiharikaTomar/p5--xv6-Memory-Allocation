
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
8010002d:	b8 c6 2b 10 80       	mov    $0x80102bc6,%eax
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
80100046:	e8 b7 3c 00 00       	call   80103d02 <acquire>

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
8010007c:	e8 e6 3c 00 00       	call   80103d67 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 62 3a 00 00       	call   80103aee <acquiresleep>
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
801000ca:	e8 98 3c 00 00       	call   80103d67 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 14 3a 00 00       	call   80103aee <acquiresleep>
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
801000ea:	68 40 66 10 80       	push   $0x80106640
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 51 66 10 80       	push   $0x80106651
80100100:	68 e0 b5 10 80       	push   $0x8010b5e0
80100105:	e8 bc 3a 00 00       	call   80103bc6 <initlock>
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
8010013a:	68 58 66 10 80       	push   $0x80106658
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 73 39 00 00       	call   80103abb <initsleeplock>
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
801001a8:	e8 cb 39 00 00       	call   80103b78 <holdingsleep>
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
801001cb:	68 5f 66 10 80       	push   $0x8010665f
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
801001e4:	e8 8f 39 00 00       	call   80103b78 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 44 39 00 00       	call   80103b3d <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 e0 b5 10 80 	movl   $0x8010b5e0,(%esp)
80100200:	e8 fd 3a 00 00       	call   80103d02 <acquire>
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
8010024c:	e8 16 3b 00 00       	call   80103d67 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 66 66 10 80       	push   $0x80106666
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
8010028a:	e8 73 3a 00 00       	call   80103d02 <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 c0 ff 10 80       	mov    0x8010ffc0,%eax
8010029f:	3b 05 c4 ff 10 80    	cmp    0x8010ffc4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 b4 30 00 00       	call   80103360 <myproc>
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
801002bf:	e8 43 35 00 00       	call   80103807 <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 a5 10 80       	push   $0x8010a520
801002d1:	e8 91 3a 00 00       	call   80103d67 <release>
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
80100331:	e8 31 3a 00 00       	call   80103d67 <release>
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
8010035a:	e8 81 21 00 00       	call   801024e0 <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 6d 66 10 80       	push   $0x8010666d
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 bb 6f 10 80 	movl   $0x80106fbb,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 4d 38 00 00       	call   80103be1 <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 81 66 10 80       	push   $0x80106681
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
8010049e:	68 85 66 10 80       	push   $0x80106685
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 6a 39 00 00       	call   80103e29 <memmove>
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
801004d9:	e8 d0 38 00 00       	call   80103dae <memset>
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
80100506:	e8 dd 4c 00 00       	call   801051e8 <uartputc>
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
8010051f:	e8 c4 4c 00 00       	call   801051e8 <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 b8 4c 00 00       	call   801051e8 <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 ac 4c 00 00       	call   801051e8 <uartputc>
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
80100576:	0f b6 92 b0 66 10 80 	movzbl -0x7fef9950(%edx),%edx
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
801005ca:	e8 33 37 00 00       	call   80103d02 <acquire>
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
801005f1:	e8 71 37 00 00       	call   80103d67 <release>
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
80100638:	e8 c5 36 00 00       	call   80103d02 <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 9f 66 10 80       	push   $0x8010669f
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
801006ee:	be 98 66 10 80       	mov    $0x80106698,%esi
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
80100734:	e8 2e 36 00 00       	call   80103d67 <release>
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
8010074f:	e8 ae 35 00 00       	call   80103d02 <acquire>
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
801007de:	e8 89 31 00 00       	call   8010396c <wakeup>
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
80100873:	e8 ef 34 00 00       	call   80103d67 <release>
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
80100887:	e8 7d 31 00 00       	call   80103a09 <procdump>
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
80100894:	68 a8 66 10 80       	push   $0x801066a8
80100899:	68 20 a5 10 80       	push   $0x8010a520
8010089e:	e8 23 33 00 00       	call   80103bc6 <initlock>

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
801008de:	e8 7d 2a 00 00       	call   80103360 <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 22 20 00 00       	call   80102910 <begin_op>

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
80100935:	e8 50 20 00 00       	call   8010298a <end_op>
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
8010094a:	e8 3b 20 00 00       	call   8010298a <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 c1 66 10 80       	push   $0x801066c1
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
80100972:	e8 4c 5a 00 00       	call   801063c3 <setupkvm>
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
80100a06:	e8 50 58 00 00       	call   8010625b <allocuvm>
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
80100a38:	e8 ec 56 00 00       	call   80106129 <loaduvm>
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
80100a53:	e8 32 1f 00 00       	call   8010298a <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 e2 57 00 00       	call   8010625b <allocuvm>
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
80100a9d:	e8 b1 58 00 00       	call   80106353 <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 8f 59 00 00       	call   80106450 <clearpteu>
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
80100ae2:	e8 69 34 00 00       	call   80103f50 <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 57 34 00 00       	call   80103f50 <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 a0 5a 00 00       	call   801065ab <copyout>
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
80100b66:	e8 40 5a 00 00       	call   801065ab <copyout>
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
80100ba3:	e8 6d 33 00 00       	call   80103f15 <safestrcpy>
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
80100bd1:	e8 cd 53 00 00       	call   80105fa3 <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 75 57 00 00       	call   80106353 <freevm>
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
80100c19:	68 cd 66 10 80       	push   $0x801066cd
80100c1e:	68 e0 ff 10 80       	push   $0x8010ffe0
80100c23:	e8 9e 2f 00 00       	call   80103bc6 <initlock>
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
80100c39:	e8 c4 30 00 00       	call   80103d02 <acquire>
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
80100c68:	e8 fa 30 00 00       	call   80103d67 <release>
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
80100c7f:	e8 e3 30 00 00       	call   80103d67 <release>
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
80100c9d:	e8 60 30 00 00       	call   80103d02 <acquire>
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
80100cba:	e8 a8 30 00 00       	call   80103d67 <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 d4 66 10 80       	push   $0x801066d4
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
80100ce2:	e8 1b 30 00 00       	call   80103d02 <acquire>
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
80100d03:	e8 5f 30 00 00       	call   80103d67 <release>
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
80100d13:	68 dc 66 10 80       	push   $0x801066dc
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
80100d49:	e8 19 30 00 00       	call   80103d67 <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 ad 1b 00 00       	call   80102910 <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 17 1c 00 00       	call   8010298a <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 04 22 00 00       	call   80102f8c <pipeclose>
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
80100e3c:	e8 a3 22 00 00       	call   801030e4 <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 e6 66 10 80       	push   $0x801066e6
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
80100e95:	e8 7e 21 00 00       	call   80103018 <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 69 1a 00 00       	call   80102910 <begin_op>
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
80100edd:	e8 a8 1a 00 00       	call   8010298a <end_op>

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
80100f10:	68 ef 66 10 80       	push   $0x801066ef
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
80100f2d:	68 f5 66 10 80       	push   $0x801066f5
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
80100f8a:	e8 9a 2e 00 00       	call   80103e29 <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 8a 2e 00 00       	call   80103e29 <memmove>
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
80100fdf:	e8 ca 2d 00 00       	call   80103dae <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 4d 1a 00 00       	call   80102a39 <log_write>
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
801010a3:	68 ff 66 10 80       	push   $0x801066ff
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
801010bf:	e8 75 19 00 00       	call   80102a39 <log_write>
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
80101170:	e8 c4 18 00 00       	call   80102a39 <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 15 67 10 80       	push   $0x80106715
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
8010119a:	e8 63 2b 00 00       	call   80103d02 <acquire>
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
801011e1:	e8 81 2b 00 00       	call   80103d67 <release>
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
80101217:	e8 4b 2b 00 00       	call   80103d67 <release>
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
8010122c:	68 28 67 10 80       	push   $0x80106728
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
80101255:	e8 cf 2b 00 00       	call   80103e29 <memmove>
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
801012c8:	e8 6c 17 00 00       	call   80102a39 <log_write>
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
801012e2:	68 38 67 10 80       	push   $0x80106738
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 4b 67 10 80       	push   $0x8010674b
801012f8:	68 00 0a 11 80       	push   $0x80110a00
801012fd:	e8 c4 28 00 00       	call   80103bc6 <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 52 67 10 80       	push   $0x80106752
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 40 0a 11 80       	add    $0x80110a40,%eax
80101321:	50                   	push   %eax
80101322:	e8 94 27 00 00       	call   80103abb <initsleeplock>
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
8010136c:	68 b8 67 10 80       	push   $0x801067b8
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
801013df:	68 58 67 10 80       	push   $0x80106758
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 b8 29 00 00       	call   80103dae <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 34 16 00 00       	call   80102a39 <log_write>
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
80101480:	e8 a4 29 00 00       	call   80103e29 <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 ac 15 00 00       	call   80102a39 <log_write>
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
80101560:	e8 9d 27 00 00       	call   80103d02 <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 00 0a 11 80 	movl   $0x80110a00,(%esp)
80101575:	e8 ed 27 00 00       	call   80103d67 <release>
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
8010159a:	e8 4f 25 00 00       	call   80103aee <acquiresleep>
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
801015b2:	68 6a 67 10 80       	push   $0x8010676a
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
80101614:	e8 10 28 00 00       	call   80103e29 <memmove>
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
80101639:	68 70 67 10 80       	push   $0x80106770
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
80101656:	e8 1d 25 00 00       	call   80103b78 <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 cc 24 00 00       	call   80103b3d <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 7f 67 10 80       	push   $0x8010677f
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
80101698:	e8 51 24 00 00       	call   80103aee <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 87 24 00 00       	call   80103b3d <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 00 0a 11 80 	movl   $0x80110a00,(%esp)
801016bd:	e8 40 26 00 00       	call   80103d02 <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 00 0a 11 80 	movl   $0x80110a00,(%esp)
801016d2:	e8 90 26 00 00       	call   80103d67 <release>
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
801016ea:	e8 13 26 00 00       	call   80103d02 <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 00 0a 11 80 	movl   $0x80110a00,(%esp)
801016f9:	e8 69 26 00 00       	call   80103d67 <release>
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
8010182a:	e8 fa 25 00 00       	call   80103e29 <memmove>
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
80101926:	e8 fe 24 00 00       	call   80103e29 <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 06 11 00 00       	call   80102a39 <log_write>
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
801019a9:	e8 e2 24 00 00       	call   80103e90 <strncmp>
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
801019d0:	68 87 67 10 80       	push   $0x80106787
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 99 67 10 80       	push   $0x80106799
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
80101a5a:	e8 01 19 00 00       	call   80103360 <myproc>
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
80101b92:	68 a8 67 10 80       	push   $0x801067a8
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 1f 23 00 00       	call   80103ecd <strncpy>
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
80101bd7:	68 b4 6d 10 80       	push   $0x80106db4
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
80101ccc:	68 0b 68 10 80       	push   $0x8010680b
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 14 68 10 80       	push   $0x80106814
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
80101d06:	68 26 68 10 80       	push   $0x80106826
80101d0b:	68 80 a5 10 80       	push   $0x8010a580
80101d10:	e8 b1 1e 00 00       	call   80103bc6 <initlock>
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
80101d80:	e8 7d 1f 00 00       	call   80103d02 <acquire>

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
80101dad:	e8 ba 1b 00 00       	call   8010396c <wakeup>

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
80101dcb:	e8 97 1f 00 00       	call   80103d67 <release>
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
80101de2:	e8 80 1f 00 00       	call   80103d67 <release>
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
80101e1a:	e8 59 1d 00 00       	call   80103b78 <holdingsleep>
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
80101e47:	e8 b6 1e 00 00       	call   80103d02 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 a5 10 80       	mov    $0x8010a564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 2a 68 10 80       	push   $0x8010682a
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 40 68 10 80       	push   $0x80106840
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 55 68 10 80       	push   $0x80106855
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
80101ea9:	e8 59 19 00 00       	call   80103807 <sleep>
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
80101ec3:	e8 9f 1e 00 00       	call   80103d67 <release>
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
80101f3f:	68 74 68 10 80       	push   $0x80106874
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
80101fd6:	e8 d3 1d 00 00       	call   80103dae <memset>

  if(kmem.use_lock)
80101fdb:	83 c4 10             	add    $0x10,%esp
80101fde:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
80101fe5:	75 28                	jne    8010200f <kfree+0x6b>
  //   frames[i] = frames[i+1];
  //   pids[i] = pids[i+1];
  // }

  //add to free list
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
80102005:	68 a6 68 10 80       	push   $0x801068a6
8010200a:	e8 39 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010200f:	83 ec 0c             	sub    $0xc,%esp
80102012:	68 60 26 11 80       	push   $0x80112660
80102017:	e8 e6 1c 00 00       	call   80103d02 <acquire>
8010201c:	83 c4 10             	add    $0x10,%esp
8010201f:	eb c6                	jmp    80101fe7 <kfree+0x43>
    release(&kmem.lock);
80102021:	83 ec 0c             	sub    $0xc,%esp
80102024:	68 60 26 11 80       	push   $0x80112660
80102029:	e8 39 1d 00 00       	call   80103d67 <release>
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
8010206f:	68 ac 68 10 80       	push   $0x801068ac
80102074:	68 60 26 11 80       	push   $0x80112660
80102079:	e8 48 1b 00 00       	call   80103bc6 <initlock>
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
	currPid = pid;
801020be:	8b 45 08             	mov    0x8(%ebp),%eax
801020c1:	a3 a4 26 11 80       	mov    %eax,0x801126a4
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
  
  if(r){
801020de:	85 db                	test   %ebx,%ebx
801020e0:	74 07                	je     801020e9 <kalloc+0x21>
    kmem.freelist = r->next;
801020e2:	8b 03                	mov    (%ebx),%eax
801020e4:	a3 98 26 11 80       	mov    %eax,0x80112698
  }

  if(kmem.use_lock) {    
801020e9:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
801020f0:	75 19                	jne    8010210b <kalloc+0x43>
    pids[index] = currPid;
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
80102101:	e8 fc 1b 00 00       	call   80103d02 <acquire>
80102106:	83 c4 10             	add    $0x10,%esp
80102109:	eb cd                	jmp    801020d8 <kalloc+0x10>
    framenumber = (uint)(V2P(r) >> 12 & 0xffff);
8010210b:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80102111:	c1 e8 0c             	shr    $0xc,%eax
80102114:	0f b7 c0             	movzwl %ax,%eax
80102117:	a3 a0 26 11 80       	mov    %eax,0x801126a0
    updatePid(1);
8010211c:	83 ec 0c             	sub    $0xc,%esp
8010211f:	6a 01                	push   $0x1
80102121:	e8 95 ff ff ff       	call   801020bb <updatePid>
    frames[index] = framenumber;
80102126:	a1 b4 a5 10 80       	mov    0x8010a5b4,%eax
8010212b:	8b 15 a0 26 11 80    	mov    0x801126a0,%edx
80102131:	89 14 85 c0 26 11 80 	mov    %edx,-0x7feed940(,%eax,4)
    pids[index] = currPid;
80102138:	8b 15 a4 26 11 80    	mov    0x801126a4,%edx
8010213e:	89 14 85 e0 26 12 80 	mov    %edx,-0x7fedd920(,%eax,4)
    index++;
80102145:	83 c0 01             	add    $0x1,%eax
80102148:	a3 b4 a5 10 80       	mov    %eax,0x8010a5b4
    release(&kmem.lock);
8010214d:	c7 04 24 60 26 11 80 	movl   $0x80112660,(%esp)
80102154:	e8 0e 1c 00 00       	call   80103d67 <release>
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
80102161:	56                   	push   %esi
80102162:	53                   	push   %ebx
  struct run *r;
  struct run *prev; // head of the freelist
  // uint nextPid = -1;
  // uint prevPid = -1;

  if(kmem.use_lock)
80102163:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
8010216a:	75 50                	jne    801021bc <kalloc2+0x5e>
    acquire(&kmem.lock);
  r = kmem.freelist; // head which acts as a current pointer
8010216c:	8b 35 98 26 11 80    	mov    0x80112698,%esi


  // V2P and shift, and mask off
  framenumber = (uint)(V2P(r) >> 12 & 0xffff);
80102172:	8d 9e 00 00 00 80    	lea    -0x80000000(%esi),%ebx
80102178:	c1 eb 0c             	shr    $0xc,%ebx
8010217b:	0f b7 db             	movzwl %bx,%ebx
8010217e:	89 1d a0 26 11 80    	mov    %ebx,0x801126a0
  r->pfn = framenumber;
80102184:	89 5e 04             	mov    %ebx,0x4(%esi)

  // Update global pid
  updatePid(pid);
80102187:	83 ec 0c             	sub    $0xc,%esp
8010218a:	ff 75 08             	pushl  0x8(%ebp)
8010218d:	e8 29 ff ff ff       	call   801020bb <updatePid>

    prev = r;
    while(r){
80102192:	83 c4 10             	add    $0x10,%esp
80102195:	85 f6                	test   %esi,%esi
80102197:	74 11                	je     801021aa <kalloc2+0x4c>
      // V2P and shift, and mask off
      framenumber = (uint)(V2P(r) >> 12 & 0xffff);
80102199:	89 1d a0 26 11 80    	mov    %ebx,0x801126a0
      r->pfn = framenumber;
8010219f:	89 5e 04             	mov    %ebx,0x4(%esi)
    //   // cprintf("outside if: (%d, %d), (%d, %d) %d\n", pids[i], i,  pids[j], j, currPid);
    //   if(((prevPid != -1 && prevPid ==  currPid) && (nextPid != -1 && nextPid == currPid)) ||
    //     (prevPid == -1 && nextPid == -1) || (prevPid != -1 && currPid == prevPid && nextPid == -1) ||
    //     (prevPid == -1 && nextPid != -1 && currPid == nextPid)){
    //   // cprintf("inside if: (%d, %d), (%d, %d) %d\n", pids[i], i,  pids[j], j, currPid);
        if(r == kmem.freelist){
801021a2:	39 35 98 26 11 80    	cmp    %esi,0x80112698
801021a8:	74 24                	je     801021ce <kalloc2+0x70>
       prev = r;
       r = r->next;  
    }
  

  if(kmem.use_lock) {
801021aa:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
801021b1:	75 24                	jne    801021d7 <kalloc2+0x79>

    release(&kmem.lock);
  }

  return (char*)r;
}
801021b3:	89 f0                	mov    %esi,%eax
801021b5:	8d 65 f8             	lea    -0x8(%ebp),%esp
801021b8:	5b                   	pop    %ebx
801021b9:	5e                   	pop    %esi
801021ba:	5d                   	pop    %ebp
801021bb:	c3                   	ret    
    acquire(&kmem.lock);
801021bc:	83 ec 0c             	sub    $0xc,%esp
801021bf:	68 60 26 11 80       	push   $0x80112660
801021c4:	e8 39 1b 00 00       	call   80103d02 <acquire>
801021c9:	83 c4 10             	add    $0x10,%esp
801021cc:	eb 9e                	jmp    8010216c <kalloc2+0xe>
         kmem.freelist = r->next;
801021ce:	8b 06                	mov    (%esi),%eax
801021d0:	a3 98 26 11 80       	mov    %eax,0x80112698
801021d5:	eb d3                	jmp    801021aa <kalloc2+0x4c>
    frames[index] = framenumber;
801021d7:	a1 b4 a5 10 80       	mov    0x8010a5b4,%eax
801021dc:	8b 15 a0 26 11 80    	mov    0x801126a0,%edx
801021e2:	89 14 85 c0 26 11 80 	mov    %edx,-0x7feed940(,%eax,4)
    pids[index] = currPid;
801021e9:	8b 15 a4 26 11 80    	mov    0x801126a4,%edx
801021ef:	89 14 85 e0 26 12 80 	mov    %edx,-0x7fedd920(,%eax,4)
    index++;
801021f6:	83 c0 01             	add    $0x1,%eax
801021f9:	a3 b4 a5 10 80       	mov    %eax,0x8010a5b4
    release(&kmem.lock);
801021fe:	83 ec 0c             	sub    $0xc,%esp
80102201:	68 60 26 11 80       	push   $0x80112660
80102206:	e8 5c 1b 00 00       	call   80103d67 <release>
8010220b:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
8010220e:	eb a3                	jmp    801021b3 <kalloc2+0x55>

80102210 <dump_physmem>:

int
dump_physmem(int *frs, int *pds, int numframes)
{
80102210:	55                   	push   %ebp
80102211:	89 e5                	mov    %esp,%ebp
80102213:	57                   	push   %edi
80102214:	56                   	push   %esi
80102215:	53                   	push   %ebx
80102216:	8b 75 08             	mov    0x8(%ebp),%esi
80102219:	8b 7d 0c             	mov    0xc(%ebp),%edi
8010221c:	8b 5d 10             	mov    0x10(%ebp),%ebx
  if(numframes <= 0 || frs == 0 || pds == 0)
8010221f:	85 db                	test   %ebx,%ebx
80102221:	0f 9e c2             	setle  %dl
80102224:	85 f6                	test   %esi,%esi
80102226:	0f 94 c0             	sete   %al
80102229:	08 c2                	or     %al,%dl
8010222b:	75 37                	jne    80102264 <dump_physmem+0x54>
8010222d:	85 ff                	test   %edi,%edi
8010222f:	74 3a                	je     8010226b <dump_physmem+0x5b>
    return -1;
  for (int i = 0; i < numframes; i++) {
80102231:	b8 00 00 00 00       	mov    $0x0,%eax
80102236:	eb 1e                	jmp    80102256 <dump_physmem+0x46>
    frs[i] = frames[i];
80102238:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010223f:	8b 0c 85 c0 26 11 80 	mov    -0x7feed940(,%eax,4),%ecx
80102246:	89 0c 16             	mov    %ecx,(%esi,%edx,1)
    pds[i] = pids[i];
80102249:	8b 0c 85 e0 26 12 80 	mov    -0x7fedd920(,%eax,4),%ecx
80102250:	89 0c 17             	mov    %ecx,(%edi,%edx,1)
  for (int i = 0; i < numframes; i++) {
80102253:	83 c0 01             	add    $0x1,%eax
80102256:	39 d8                	cmp    %ebx,%eax
80102258:	7c de                	jl     80102238 <dump_physmem+0x28>
  }
  return 0;
8010225a:	b8 00 00 00 00       	mov    $0x0,%eax
8010225f:	5b                   	pop    %ebx
80102260:	5e                   	pop    %esi
80102261:	5f                   	pop    %edi
80102262:	5d                   	pop    %ebp
80102263:	c3                   	ret    
    return -1;
80102264:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102269:	eb f4                	jmp    8010225f <dump_physmem+0x4f>
8010226b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102270:	eb ed                	jmp    8010225f <dump_physmem+0x4f>

80102272 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102272:	55                   	push   %ebp
80102273:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102275:	ba 64 00 00 00       	mov    $0x64,%edx
8010227a:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
8010227b:	a8 01                	test   $0x1,%al
8010227d:	0f 84 b5 00 00 00    	je     80102338 <kbdgetc+0xc6>
80102283:	ba 60 00 00 00       	mov    $0x60,%edx
80102288:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
80102289:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
8010228c:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
80102292:	74 5c                	je     801022f0 <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
80102294:	84 c0                	test   %al,%al
80102296:	78 66                	js     801022fe <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
80102298:	8b 0d b8 a5 10 80    	mov    0x8010a5b8,%ecx
8010229e:	f6 c1 40             	test   $0x40,%cl
801022a1:	74 0f                	je     801022b2 <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
801022a3:	83 c8 80             	or     $0xffffff80,%eax
801022a6:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
801022a9:	83 e1 bf             	and    $0xffffffbf,%ecx
801022ac:	89 0d b8 a5 10 80    	mov    %ecx,0x8010a5b8
  }

  shift |= shiftcode[data];
801022b2:	0f b6 8a e0 69 10 80 	movzbl -0x7fef9620(%edx),%ecx
801022b9:	0b 0d b8 a5 10 80    	or     0x8010a5b8,%ecx
  shift ^= togglecode[data];
801022bf:	0f b6 82 e0 68 10 80 	movzbl -0x7fef9720(%edx),%eax
801022c6:	31 c1                	xor    %eax,%ecx
801022c8:	89 0d b8 a5 10 80    	mov    %ecx,0x8010a5b8
  c = charcode[shift & (CTL | SHIFT)][data];
801022ce:	89 c8                	mov    %ecx,%eax
801022d0:	83 e0 03             	and    $0x3,%eax
801022d3:	8b 04 85 c0 68 10 80 	mov    -0x7fef9740(,%eax,4),%eax
801022da:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
801022de:	f6 c1 08             	test   $0x8,%cl
801022e1:	74 19                	je     801022fc <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
801022e3:	8d 50 9f             	lea    -0x61(%eax),%edx
801022e6:	83 fa 19             	cmp    $0x19,%edx
801022e9:	77 40                	ja     8010232b <kbdgetc+0xb9>
      c += 'A' - 'a';
801022eb:	83 e8 20             	sub    $0x20,%eax
801022ee:	eb 0c                	jmp    801022fc <kbdgetc+0x8a>
    shift |= E0ESC;
801022f0:	83 0d b8 a5 10 80 40 	orl    $0x40,0x8010a5b8
    return 0;
801022f7:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
801022fc:	5d                   	pop    %ebp
801022fd:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
801022fe:	8b 0d b8 a5 10 80    	mov    0x8010a5b8,%ecx
80102304:	f6 c1 40             	test   $0x40,%cl
80102307:	75 05                	jne    8010230e <kbdgetc+0x9c>
80102309:	89 c2                	mov    %eax,%edx
8010230b:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
8010230e:	0f b6 82 e0 69 10 80 	movzbl -0x7fef9620(%edx),%eax
80102315:	83 c8 40             	or     $0x40,%eax
80102318:	0f b6 c0             	movzbl %al,%eax
8010231b:	f7 d0                	not    %eax
8010231d:	21 c8                	and    %ecx,%eax
8010231f:	a3 b8 a5 10 80       	mov    %eax,0x8010a5b8
    return 0;
80102324:	b8 00 00 00 00       	mov    $0x0,%eax
80102329:	eb d1                	jmp    801022fc <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
8010232b:	8d 50 bf             	lea    -0x41(%eax),%edx
8010232e:	83 fa 19             	cmp    $0x19,%edx
80102331:	77 c9                	ja     801022fc <kbdgetc+0x8a>
      c += 'a' - 'A';
80102333:	83 c0 20             	add    $0x20,%eax
  return c;
80102336:	eb c4                	jmp    801022fc <kbdgetc+0x8a>
    return -1;
80102338:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010233d:	eb bd                	jmp    801022fc <kbdgetc+0x8a>

8010233f <kbdintr>:

void
kbdintr(void)
{
8010233f:	55                   	push   %ebp
80102340:	89 e5                	mov    %esp,%ebp
80102342:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
80102345:	68 72 22 10 80       	push   $0x80102272
8010234a:	e8 ef e3 ff ff       	call   8010073e <consoleintr>
}
8010234f:	83 c4 10             	add    $0x10,%esp
80102352:	c9                   	leave  
80102353:	c3                   	ret    

80102354 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102354:	55                   	push   %ebp
80102355:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102357:	8b 0d e4 26 13 80    	mov    0x801326e4,%ecx
8010235d:	8d 04 81             	lea    (%ecx,%eax,4),%eax
80102360:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
80102362:	a1 e4 26 13 80       	mov    0x801326e4,%eax
80102367:	8b 40 20             	mov    0x20(%eax),%eax
}
8010236a:	5d                   	pop    %ebp
8010236b:	c3                   	ret    

8010236c <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
8010236c:	55                   	push   %ebp
8010236d:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010236f:	ba 70 00 00 00       	mov    $0x70,%edx
80102374:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102375:	ba 71 00 00 00       	mov    $0x71,%edx
8010237a:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
8010237b:	0f b6 c0             	movzbl %al,%eax
}
8010237e:	5d                   	pop    %ebp
8010237f:	c3                   	ret    

80102380 <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
80102380:	55                   	push   %ebp
80102381:	89 e5                	mov    %esp,%ebp
80102383:	53                   	push   %ebx
80102384:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
80102386:	b8 00 00 00 00       	mov    $0x0,%eax
8010238b:	e8 dc ff ff ff       	call   8010236c <cmos_read>
80102390:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
80102392:	b8 02 00 00 00       	mov    $0x2,%eax
80102397:	e8 d0 ff ff ff       	call   8010236c <cmos_read>
8010239c:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
8010239f:	b8 04 00 00 00       	mov    $0x4,%eax
801023a4:	e8 c3 ff ff ff       	call   8010236c <cmos_read>
801023a9:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
801023ac:	b8 07 00 00 00       	mov    $0x7,%eax
801023b1:	e8 b6 ff ff ff       	call   8010236c <cmos_read>
801023b6:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
801023b9:	b8 08 00 00 00       	mov    $0x8,%eax
801023be:	e8 a9 ff ff ff       	call   8010236c <cmos_read>
801023c3:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
801023c6:	b8 09 00 00 00       	mov    $0x9,%eax
801023cb:	e8 9c ff ff ff       	call   8010236c <cmos_read>
801023d0:	89 43 14             	mov    %eax,0x14(%ebx)
}
801023d3:	5b                   	pop    %ebx
801023d4:	5d                   	pop    %ebp
801023d5:	c3                   	ret    

801023d6 <lapicinit>:
  if(!lapic)
801023d6:	83 3d e4 26 13 80 00 	cmpl   $0x0,0x801326e4
801023dd:	0f 84 fb 00 00 00    	je     801024de <lapicinit+0x108>
{
801023e3:	55                   	push   %ebp
801023e4:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801023e6:	ba 3f 01 00 00       	mov    $0x13f,%edx
801023eb:	b8 3c 00 00 00       	mov    $0x3c,%eax
801023f0:	e8 5f ff ff ff       	call   80102354 <lapicw>
  lapicw(TDCR, X1);
801023f5:	ba 0b 00 00 00       	mov    $0xb,%edx
801023fa:	b8 f8 00 00 00       	mov    $0xf8,%eax
801023ff:	e8 50 ff ff ff       	call   80102354 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102404:	ba 20 00 02 00       	mov    $0x20020,%edx
80102409:	b8 c8 00 00 00       	mov    $0xc8,%eax
8010240e:	e8 41 ff ff ff       	call   80102354 <lapicw>
  lapicw(TICR, 10000000);
80102413:	ba 80 96 98 00       	mov    $0x989680,%edx
80102418:	b8 e0 00 00 00       	mov    $0xe0,%eax
8010241d:	e8 32 ff ff ff       	call   80102354 <lapicw>
  lapicw(LINT0, MASKED);
80102422:	ba 00 00 01 00       	mov    $0x10000,%edx
80102427:	b8 d4 00 00 00       	mov    $0xd4,%eax
8010242c:	e8 23 ff ff ff       	call   80102354 <lapicw>
  lapicw(LINT1, MASKED);
80102431:	ba 00 00 01 00       	mov    $0x10000,%edx
80102436:	b8 d8 00 00 00       	mov    $0xd8,%eax
8010243b:	e8 14 ff ff ff       	call   80102354 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102440:	a1 e4 26 13 80       	mov    0x801326e4,%eax
80102445:	8b 40 30             	mov    0x30(%eax),%eax
80102448:	c1 e8 10             	shr    $0x10,%eax
8010244b:	3c 03                	cmp    $0x3,%al
8010244d:	77 7b                	ja     801024ca <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
8010244f:	ba 33 00 00 00       	mov    $0x33,%edx
80102454:	b8 dc 00 00 00       	mov    $0xdc,%eax
80102459:	e8 f6 fe ff ff       	call   80102354 <lapicw>
  lapicw(ESR, 0);
8010245e:	ba 00 00 00 00       	mov    $0x0,%edx
80102463:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102468:	e8 e7 fe ff ff       	call   80102354 <lapicw>
  lapicw(ESR, 0);
8010246d:	ba 00 00 00 00       	mov    $0x0,%edx
80102472:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102477:	e8 d8 fe ff ff       	call   80102354 <lapicw>
  lapicw(EOI, 0);
8010247c:	ba 00 00 00 00       	mov    $0x0,%edx
80102481:	b8 2c 00 00 00       	mov    $0x2c,%eax
80102486:	e8 c9 fe ff ff       	call   80102354 <lapicw>
  lapicw(ICRHI, 0);
8010248b:	ba 00 00 00 00       	mov    $0x0,%edx
80102490:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102495:	e8 ba fe ff ff       	call   80102354 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
8010249a:	ba 00 85 08 00       	mov    $0x88500,%edx
8010249f:	b8 c0 00 00 00       	mov    $0xc0,%eax
801024a4:	e8 ab fe ff ff       	call   80102354 <lapicw>
  while(lapic[ICRLO] & DELIVS)
801024a9:	a1 e4 26 13 80       	mov    0x801326e4,%eax
801024ae:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
801024b4:	f6 c4 10             	test   $0x10,%ah
801024b7:	75 f0                	jne    801024a9 <lapicinit+0xd3>
  lapicw(TPR, 0);
801024b9:	ba 00 00 00 00       	mov    $0x0,%edx
801024be:	b8 20 00 00 00       	mov    $0x20,%eax
801024c3:	e8 8c fe ff ff       	call   80102354 <lapicw>
}
801024c8:	5d                   	pop    %ebp
801024c9:	c3                   	ret    
    lapicw(PCINT, MASKED);
801024ca:	ba 00 00 01 00       	mov    $0x10000,%edx
801024cf:	b8 d0 00 00 00       	mov    $0xd0,%eax
801024d4:	e8 7b fe ff ff       	call   80102354 <lapicw>
801024d9:	e9 71 ff ff ff       	jmp    8010244f <lapicinit+0x79>
801024de:	f3 c3                	repz ret 

801024e0 <lapicid>:
{
801024e0:	55                   	push   %ebp
801024e1:	89 e5                	mov    %esp,%ebp
  if (!lapic)
801024e3:	a1 e4 26 13 80       	mov    0x801326e4,%eax
801024e8:	85 c0                	test   %eax,%eax
801024ea:	74 08                	je     801024f4 <lapicid+0x14>
  return lapic[ID] >> 24;
801024ec:	8b 40 20             	mov    0x20(%eax),%eax
801024ef:	c1 e8 18             	shr    $0x18,%eax
}
801024f2:	5d                   	pop    %ebp
801024f3:	c3                   	ret    
    return 0;
801024f4:	b8 00 00 00 00       	mov    $0x0,%eax
801024f9:	eb f7                	jmp    801024f2 <lapicid+0x12>

801024fb <lapiceoi>:
  if(lapic)
801024fb:	83 3d e4 26 13 80 00 	cmpl   $0x0,0x801326e4
80102502:	74 14                	je     80102518 <lapiceoi+0x1d>
{
80102504:	55                   	push   %ebp
80102505:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
80102507:	ba 00 00 00 00       	mov    $0x0,%edx
8010250c:	b8 2c 00 00 00       	mov    $0x2c,%eax
80102511:	e8 3e fe ff ff       	call   80102354 <lapicw>
}
80102516:	5d                   	pop    %ebp
80102517:	c3                   	ret    
80102518:	f3 c3                	repz ret 

8010251a <microdelay>:
{
8010251a:	55                   	push   %ebp
8010251b:	89 e5                	mov    %esp,%ebp
}
8010251d:	5d                   	pop    %ebp
8010251e:	c3                   	ret    

8010251f <lapicstartap>:
{
8010251f:	55                   	push   %ebp
80102520:	89 e5                	mov    %esp,%ebp
80102522:	57                   	push   %edi
80102523:	56                   	push   %esi
80102524:	53                   	push   %ebx
80102525:	8b 75 08             	mov    0x8(%ebp),%esi
80102528:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010252b:	b8 0f 00 00 00       	mov    $0xf,%eax
80102530:	ba 70 00 00 00       	mov    $0x70,%edx
80102535:	ee                   	out    %al,(%dx)
80102536:	b8 0a 00 00 00       	mov    $0xa,%eax
8010253b:	ba 71 00 00 00       	mov    $0x71,%edx
80102540:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
80102541:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
80102548:	00 00 
  wrv[1] = addr >> 4;
8010254a:	89 f8                	mov    %edi,%eax
8010254c:	c1 e8 04             	shr    $0x4,%eax
8010254f:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
80102555:	c1 e6 18             	shl    $0x18,%esi
80102558:	89 f2                	mov    %esi,%edx
8010255a:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010255f:	e8 f0 fd ff ff       	call   80102354 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102564:	ba 00 c5 00 00       	mov    $0xc500,%edx
80102569:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010256e:	e8 e1 fd ff ff       	call   80102354 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
80102573:	ba 00 85 00 00       	mov    $0x8500,%edx
80102578:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010257d:	e8 d2 fd ff ff       	call   80102354 <lapicw>
  for(i = 0; i < 2; i++){
80102582:	bb 00 00 00 00       	mov    $0x0,%ebx
80102587:	eb 21                	jmp    801025aa <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
80102589:	89 f2                	mov    %esi,%edx
8010258b:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102590:	e8 bf fd ff ff       	call   80102354 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80102595:	89 fa                	mov    %edi,%edx
80102597:	c1 ea 0c             	shr    $0xc,%edx
8010259a:	80 ce 06             	or     $0x6,%dh
8010259d:	b8 c0 00 00 00       	mov    $0xc0,%eax
801025a2:	e8 ad fd ff ff       	call   80102354 <lapicw>
  for(i = 0; i < 2; i++){
801025a7:	83 c3 01             	add    $0x1,%ebx
801025aa:	83 fb 01             	cmp    $0x1,%ebx
801025ad:	7e da                	jle    80102589 <lapicstartap+0x6a>
}
801025af:	5b                   	pop    %ebx
801025b0:	5e                   	pop    %esi
801025b1:	5f                   	pop    %edi
801025b2:	5d                   	pop    %ebp
801025b3:	c3                   	ret    

801025b4 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
801025b4:	55                   	push   %ebp
801025b5:	89 e5                	mov    %esp,%ebp
801025b7:	57                   	push   %edi
801025b8:	56                   	push   %esi
801025b9:	53                   	push   %ebx
801025ba:	83 ec 3c             	sub    $0x3c,%esp
801025bd:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801025c0:	b8 0b 00 00 00       	mov    $0xb,%eax
801025c5:	e8 a2 fd ff ff       	call   8010236c <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
801025ca:	83 e0 04             	and    $0x4,%eax
801025cd:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
801025cf:	8d 45 d0             	lea    -0x30(%ebp),%eax
801025d2:	e8 a9 fd ff ff       	call   80102380 <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
801025d7:	b8 0a 00 00 00       	mov    $0xa,%eax
801025dc:	e8 8b fd ff ff       	call   8010236c <cmos_read>
801025e1:	a8 80                	test   $0x80,%al
801025e3:	75 ea                	jne    801025cf <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
801025e5:	8d 5d b8             	lea    -0x48(%ebp),%ebx
801025e8:	89 d8                	mov    %ebx,%eax
801025ea:	e8 91 fd ff ff       	call   80102380 <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
801025ef:	83 ec 04             	sub    $0x4,%esp
801025f2:	6a 18                	push   $0x18
801025f4:	53                   	push   %ebx
801025f5:	8d 45 d0             	lea    -0x30(%ebp),%eax
801025f8:	50                   	push   %eax
801025f9:	e8 f6 17 00 00       	call   80103df4 <memcmp>
801025fe:	83 c4 10             	add    $0x10,%esp
80102601:	85 c0                	test   %eax,%eax
80102603:	75 ca                	jne    801025cf <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
80102605:	85 ff                	test   %edi,%edi
80102607:	0f 85 84 00 00 00    	jne    80102691 <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
8010260d:	8b 55 d0             	mov    -0x30(%ebp),%edx
80102610:	89 d0                	mov    %edx,%eax
80102612:	c1 e8 04             	shr    $0x4,%eax
80102615:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102618:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010261b:	83 e2 0f             	and    $0xf,%edx
8010261e:	01 d0                	add    %edx,%eax
80102620:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
80102623:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80102626:	89 d0                	mov    %edx,%eax
80102628:	c1 e8 04             	shr    $0x4,%eax
8010262b:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010262e:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102631:	83 e2 0f             	and    $0xf,%edx
80102634:	01 d0                	add    %edx,%eax
80102636:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
80102639:	8b 55 d8             	mov    -0x28(%ebp),%edx
8010263c:	89 d0                	mov    %edx,%eax
8010263e:	c1 e8 04             	shr    $0x4,%eax
80102641:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102644:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102647:	83 e2 0f             	and    $0xf,%edx
8010264a:	01 d0                	add    %edx,%eax
8010264c:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
8010264f:	8b 55 dc             	mov    -0x24(%ebp),%edx
80102652:	89 d0                	mov    %edx,%eax
80102654:	c1 e8 04             	shr    $0x4,%eax
80102657:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010265a:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010265d:	83 e2 0f             	and    $0xf,%edx
80102660:	01 d0                	add    %edx,%eax
80102662:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
80102665:	8b 55 e0             	mov    -0x20(%ebp),%edx
80102668:	89 d0                	mov    %edx,%eax
8010266a:	c1 e8 04             	shr    $0x4,%eax
8010266d:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102670:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102673:	83 e2 0f             	and    $0xf,%edx
80102676:	01 d0                	add    %edx,%eax
80102678:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
8010267b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010267e:	89 d0                	mov    %edx,%eax
80102680:	c1 e8 04             	shr    $0x4,%eax
80102683:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102686:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102689:	83 e2 0f             	and    $0xf,%edx
8010268c:	01 d0                	add    %edx,%eax
8010268e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
80102691:	8b 45 d0             	mov    -0x30(%ebp),%eax
80102694:	89 06                	mov    %eax,(%esi)
80102696:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102699:	89 46 04             	mov    %eax,0x4(%esi)
8010269c:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010269f:	89 46 08             	mov    %eax,0x8(%esi)
801026a2:	8b 45 dc             	mov    -0x24(%ebp),%eax
801026a5:	89 46 0c             	mov    %eax,0xc(%esi)
801026a8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801026ab:	89 46 10             	mov    %eax,0x10(%esi)
801026ae:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801026b1:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
801026b4:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
801026bb:	8d 65 f4             	lea    -0xc(%ebp),%esp
801026be:	5b                   	pop    %ebx
801026bf:	5e                   	pop    %esi
801026c0:	5f                   	pop    %edi
801026c1:	5d                   	pop    %ebp
801026c2:	c3                   	ret    

801026c3 <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
801026c3:	55                   	push   %ebp
801026c4:	89 e5                	mov    %esp,%ebp
801026c6:	53                   	push   %ebx
801026c7:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
801026ca:	ff 35 34 27 13 80    	pushl  0x80132734
801026d0:	ff 35 44 27 13 80    	pushl  0x80132744
801026d6:	e8 91 da ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
801026db:	8b 58 5c             	mov    0x5c(%eax),%ebx
801026de:	89 1d 48 27 13 80    	mov    %ebx,0x80132748
  for (i = 0; i < log.lh.n; i++) {
801026e4:	83 c4 10             	add    $0x10,%esp
801026e7:	ba 00 00 00 00       	mov    $0x0,%edx
801026ec:	eb 0e                	jmp    801026fc <read_head+0x39>
    log.lh.block[i] = lh->block[i];
801026ee:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
801026f2:	89 0c 95 4c 27 13 80 	mov    %ecx,-0x7fecd8b4(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
801026f9:	83 c2 01             	add    $0x1,%edx
801026fc:	39 d3                	cmp    %edx,%ebx
801026fe:	7f ee                	jg     801026ee <read_head+0x2b>
  }
  brelse(buf);
80102700:	83 ec 0c             	sub    $0xc,%esp
80102703:	50                   	push   %eax
80102704:	e8 cc da ff ff       	call   801001d5 <brelse>
}
80102709:	83 c4 10             	add    $0x10,%esp
8010270c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010270f:	c9                   	leave  
80102710:	c3                   	ret    

80102711 <install_trans>:
{
80102711:	55                   	push   %ebp
80102712:	89 e5                	mov    %esp,%ebp
80102714:	57                   	push   %edi
80102715:	56                   	push   %esi
80102716:	53                   	push   %ebx
80102717:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
8010271a:	bb 00 00 00 00       	mov    $0x0,%ebx
8010271f:	eb 66                	jmp    80102787 <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80102721:	89 d8                	mov    %ebx,%eax
80102723:	03 05 34 27 13 80    	add    0x80132734,%eax
80102729:	83 c0 01             	add    $0x1,%eax
8010272c:	83 ec 08             	sub    $0x8,%esp
8010272f:	50                   	push   %eax
80102730:	ff 35 44 27 13 80    	pushl  0x80132744
80102736:	e8 31 da ff ff       	call   8010016c <bread>
8010273b:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
8010273d:	83 c4 08             	add    $0x8,%esp
80102740:	ff 34 9d 4c 27 13 80 	pushl  -0x7fecd8b4(,%ebx,4)
80102747:	ff 35 44 27 13 80    	pushl  0x80132744
8010274d:	e8 1a da ff ff       	call   8010016c <bread>
80102752:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80102754:	8d 57 5c             	lea    0x5c(%edi),%edx
80102757:	8d 40 5c             	lea    0x5c(%eax),%eax
8010275a:	83 c4 0c             	add    $0xc,%esp
8010275d:	68 00 02 00 00       	push   $0x200
80102762:	52                   	push   %edx
80102763:	50                   	push   %eax
80102764:	e8 c0 16 00 00       	call   80103e29 <memmove>
    bwrite(dbuf);  // write dst to disk
80102769:	89 34 24             	mov    %esi,(%esp)
8010276c:	e8 29 da ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
80102771:	89 3c 24             	mov    %edi,(%esp)
80102774:	e8 5c da ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
80102779:	89 34 24             	mov    %esi,(%esp)
8010277c:	e8 54 da ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102781:	83 c3 01             	add    $0x1,%ebx
80102784:	83 c4 10             	add    $0x10,%esp
80102787:	39 1d 48 27 13 80    	cmp    %ebx,0x80132748
8010278d:	7f 92                	jg     80102721 <install_trans+0x10>
}
8010278f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102792:	5b                   	pop    %ebx
80102793:	5e                   	pop    %esi
80102794:	5f                   	pop    %edi
80102795:	5d                   	pop    %ebp
80102796:	c3                   	ret    

80102797 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80102797:	55                   	push   %ebp
80102798:	89 e5                	mov    %esp,%ebp
8010279a:	53                   	push   %ebx
8010279b:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
8010279e:	ff 35 34 27 13 80    	pushl  0x80132734
801027a4:	ff 35 44 27 13 80    	pushl  0x80132744
801027aa:	e8 bd d9 ff ff       	call   8010016c <bread>
801027af:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
801027b1:	8b 0d 48 27 13 80    	mov    0x80132748,%ecx
801027b7:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
801027ba:	83 c4 10             	add    $0x10,%esp
801027bd:	b8 00 00 00 00       	mov    $0x0,%eax
801027c2:	eb 0e                	jmp    801027d2 <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
801027c4:	8b 14 85 4c 27 13 80 	mov    -0x7fecd8b4(,%eax,4),%edx
801027cb:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
801027cf:	83 c0 01             	add    $0x1,%eax
801027d2:	39 c1                	cmp    %eax,%ecx
801027d4:	7f ee                	jg     801027c4 <write_head+0x2d>
  }
  bwrite(buf);
801027d6:	83 ec 0c             	sub    $0xc,%esp
801027d9:	53                   	push   %ebx
801027da:	e8 bb d9 ff ff       	call   8010019a <bwrite>
  brelse(buf);
801027df:	89 1c 24             	mov    %ebx,(%esp)
801027e2:	e8 ee d9 ff ff       	call   801001d5 <brelse>
}
801027e7:	83 c4 10             	add    $0x10,%esp
801027ea:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801027ed:	c9                   	leave  
801027ee:	c3                   	ret    

801027ef <recover_from_log>:

static void
recover_from_log(void)
{
801027ef:	55                   	push   %ebp
801027f0:	89 e5                	mov    %esp,%ebp
801027f2:	83 ec 08             	sub    $0x8,%esp
  read_head();
801027f5:	e8 c9 fe ff ff       	call   801026c3 <read_head>
  install_trans(); // if committed, copy from log to disk
801027fa:	e8 12 ff ff ff       	call   80102711 <install_trans>
  log.lh.n = 0;
801027ff:	c7 05 48 27 13 80 00 	movl   $0x0,0x80132748
80102806:	00 00 00 
  write_head(); // clear the log
80102809:	e8 89 ff ff ff       	call   80102797 <write_head>
}
8010280e:	c9                   	leave  
8010280f:	c3                   	ret    

80102810 <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
80102810:	55                   	push   %ebp
80102811:	89 e5                	mov    %esp,%ebp
80102813:	57                   	push   %edi
80102814:	56                   	push   %esi
80102815:	53                   	push   %ebx
80102816:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80102819:	bb 00 00 00 00       	mov    $0x0,%ebx
8010281e:	eb 66                	jmp    80102886 <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80102820:	89 d8                	mov    %ebx,%eax
80102822:	03 05 34 27 13 80    	add    0x80132734,%eax
80102828:	83 c0 01             	add    $0x1,%eax
8010282b:	83 ec 08             	sub    $0x8,%esp
8010282e:	50                   	push   %eax
8010282f:	ff 35 44 27 13 80    	pushl  0x80132744
80102835:	e8 32 d9 ff ff       	call   8010016c <bread>
8010283a:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
8010283c:	83 c4 08             	add    $0x8,%esp
8010283f:	ff 34 9d 4c 27 13 80 	pushl  -0x7fecd8b4(,%ebx,4)
80102846:	ff 35 44 27 13 80    	pushl  0x80132744
8010284c:	e8 1b d9 ff ff       	call   8010016c <bread>
80102851:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
80102853:	8d 50 5c             	lea    0x5c(%eax),%edx
80102856:	8d 46 5c             	lea    0x5c(%esi),%eax
80102859:	83 c4 0c             	add    $0xc,%esp
8010285c:	68 00 02 00 00       	push   $0x200
80102861:	52                   	push   %edx
80102862:	50                   	push   %eax
80102863:	e8 c1 15 00 00       	call   80103e29 <memmove>
    bwrite(to);  // write the log
80102868:	89 34 24             	mov    %esi,(%esp)
8010286b:	e8 2a d9 ff ff       	call   8010019a <bwrite>
    brelse(from);
80102870:	89 3c 24             	mov    %edi,(%esp)
80102873:	e8 5d d9 ff ff       	call   801001d5 <brelse>
    brelse(to);
80102878:	89 34 24             	mov    %esi,(%esp)
8010287b:	e8 55 d9 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102880:	83 c3 01             	add    $0x1,%ebx
80102883:	83 c4 10             	add    $0x10,%esp
80102886:	39 1d 48 27 13 80    	cmp    %ebx,0x80132748
8010288c:	7f 92                	jg     80102820 <write_log+0x10>
  }
}
8010288e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102891:	5b                   	pop    %ebx
80102892:	5e                   	pop    %esi
80102893:	5f                   	pop    %edi
80102894:	5d                   	pop    %ebp
80102895:	c3                   	ret    

80102896 <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
80102896:	83 3d 48 27 13 80 00 	cmpl   $0x0,0x80132748
8010289d:	7e 26                	jle    801028c5 <commit+0x2f>
{
8010289f:	55                   	push   %ebp
801028a0:	89 e5                	mov    %esp,%ebp
801028a2:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
801028a5:	e8 66 ff ff ff       	call   80102810 <write_log>
    write_head();    // Write header to disk -- the real commit
801028aa:	e8 e8 fe ff ff       	call   80102797 <write_head>
    install_trans(); // Now install writes to home locations
801028af:	e8 5d fe ff ff       	call   80102711 <install_trans>
    log.lh.n = 0;
801028b4:	c7 05 48 27 13 80 00 	movl   $0x0,0x80132748
801028bb:	00 00 00 
    write_head();    // Erase the transaction from the log
801028be:	e8 d4 fe ff ff       	call   80102797 <write_head>
  }
}
801028c3:	c9                   	leave  
801028c4:	c3                   	ret    
801028c5:	f3 c3                	repz ret 

801028c7 <initlog>:
{
801028c7:	55                   	push   %ebp
801028c8:	89 e5                	mov    %esp,%ebp
801028ca:	53                   	push   %ebx
801028cb:	83 ec 2c             	sub    $0x2c,%esp
801028ce:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
801028d1:	68 e0 6a 10 80       	push   $0x80106ae0
801028d6:	68 00 27 13 80       	push   $0x80132700
801028db:	e8 e6 12 00 00       	call   80103bc6 <initlock>
  readsb(dev, &sb);
801028e0:	83 c4 08             	add    $0x8,%esp
801028e3:	8d 45 dc             	lea    -0x24(%ebp),%eax
801028e6:	50                   	push   %eax
801028e7:	53                   	push   %ebx
801028e8:	e8 49 e9 ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
801028ed:	8b 45 ec             	mov    -0x14(%ebp),%eax
801028f0:	a3 34 27 13 80       	mov    %eax,0x80132734
  log.size = sb.nlog;
801028f5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801028f8:	a3 38 27 13 80       	mov    %eax,0x80132738
  log.dev = dev;
801028fd:	89 1d 44 27 13 80    	mov    %ebx,0x80132744
  recover_from_log();
80102903:	e8 e7 fe ff ff       	call   801027ef <recover_from_log>
}
80102908:	83 c4 10             	add    $0x10,%esp
8010290b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010290e:	c9                   	leave  
8010290f:	c3                   	ret    

80102910 <begin_op>:
{
80102910:	55                   	push   %ebp
80102911:	89 e5                	mov    %esp,%ebp
80102913:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
80102916:	68 00 27 13 80       	push   $0x80132700
8010291b:	e8 e2 13 00 00       	call   80103d02 <acquire>
80102920:	83 c4 10             	add    $0x10,%esp
80102923:	eb 15                	jmp    8010293a <begin_op+0x2a>
      sleep(&log, &log.lock);
80102925:	83 ec 08             	sub    $0x8,%esp
80102928:	68 00 27 13 80       	push   $0x80132700
8010292d:	68 00 27 13 80       	push   $0x80132700
80102932:	e8 d0 0e 00 00       	call   80103807 <sleep>
80102937:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
8010293a:	83 3d 40 27 13 80 00 	cmpl   $0x0,0x80132740
80102941:	75 e2                	jne    80102925 <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80102943:	a1 3c 27 13 80       	mov    0x8013273c,%eax
80102948:	83 c0 01             	add    $0x1,%eax
8010294b:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010294e:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
80102951:	03 15 48 27 13 80    	add    0x80132748,%edx
80102957:	83 fa 1e             	cmp    $0x1e,%edx
8010295a:	7e 17                	jle    80102973 <begin_op+0x63>
      sleep(&log, &log.lock);
8010295c:	83 ec 08             	sub    $0x8,%esp
8010295f:	68 00 27 13 80       	push   $0x80132700
80102964:	68 00 27 13 80       	push   $0x80132700
80102969:	e8 99 0e 00 00       	call   80103807 <sleep>
8010296e:	83 c4 10             	add    $0x10,%esp
80102971:	eb c7                	jmp    8010293a <begin_op+0x2a>
      log.outstanding += 1;
80102973:	a3 3c 27 13 80       	mov    %eax,0x8013273c
      release(&log.lock);
80102978:	83 ec 0c             	sub    $0xc,%esp
8010297b:	68 00 27 13 80       	push   $0x80132700
80102980:	e8 e2 13 00 00       	call   80103d67 <release>
}
80102985:	83 c4 10             	add    $0x10,%esp
80102988:	c9                   	leave  
80102989:	c3                   	ret    

8010298a <end_op>:
{
8010298a:	55                   	push   %ebp
8010298b:	89 e5                	mov    %esp,%ebp
8010298d:	53                   	push   %ebx
8010298e:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
80102991:	68 00 27 13 80       	push   $0x80132700
80102996:	e8 67 13 00 00       	call   80103d02 <acquire>
  log.outstanding -= 1;
8010299b:	a1 3c 27 13 80       	mov    0x8013273c,%eax
801029a0:	83 e8 01             	sub    $0x1,%eax
801029a3:	a3 3c 27 13 80       	mov    %eax,0x8013273c
  if(log.committing)
801029a8:	8b 1d 40 27 13 80    	mov    0x80132740,%ebx
801029ae:	83 c4 10             	add    $0x10,%esp
801029b1:	85 db                	test   %ebx,%ebx
801029b3:	75 2c                	jne    801029e1 <end_op+0x57>
  if(log.outstanding == 0){
801029b5:	85 c0                	test   %eax,%eax
801029b7:	75 35                	jne    801029ee <end_op+0x64>
    log.committing = 1;
801029b9:	c7 05 40 27 13 80 01 	movl   $0x1,0x80132740
801029c0:	00 00 00 
    do_commit = 1;
801029c3:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
801029c8:	83 ec 0c             	sub    $0xc,%esp
801029cb:	68 00 27 13 80       	push   $0x80132700
801029d0:	e8 92 13 00 00       	call   80103d67 <release>
  if(do_commit){
801029d5:	83 c4 10             	add    $0x10,%esp
801029d8:	85 db                	test   %ebx,%ebx
801029da:	75 24                	jne    80102a00 <end_op+0x76>
}
801029dc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801029df:	c9                   	leave  
801029e0:	c3                   	ret    
    panic("log.committing");
801029e1:	83 ec 0c             	sub    $0xc,%esp
801029e4:	68 e4 6a 10 80       	push   $0x80106ae4
801029e9:	e8 5a d9 ff ff       	call   80100348 <panic>
    wakeup(&log);
801029ee:	83 ec 0c             	sub    $0xc,%esp
801029f1:	68 00 27 13 80       	push   $0x80132700
801029f6:	e8 71 0f 00 00       	call   8010396c <wakeup>
801029fb:	83 c4 10             	add    $0x10,%esp
801029fe:	eb c8                	jmp    801029c8 <end_op+0x3e>
    commit();
80102a00:	e8 91 fe ff ff       	call   80102896 <commit>
    acquire(&log.lock);
80102a05:	83 ec 0c             	sub    $0xc,%esp
80102a08:	68 00 27 13 80       	push   $0x80132700
80102a0d:	e8 f0 12 00 00       	call   80103d02 <acquire>
    log.committing = 0;
80102a12:	c7 05 40 27 13 80 00 	movl   $0x0,0x80132740
80102a19:	00 00 00 
    wakeup(&log);
80102a1c:	c7 04 24 00 27 13 80 	movl   $0x80132700,(%esp)
80102a23:	e8 44 0f 00 00       	call   8010396c <wakeup>
    release(&log.lock);
80102a28:	c7 04 24 00 27 13 80 	movl   $0x80132700,(%esp)
80102a2f:	e8 33 13 00 00       	call   80103d67 <release>
80102a34:	83 c4 10             	add    $0x10,%esp
}
80102a37:	eb a3                	jmp    801029dc <end_op+0x52>

80102a39 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80102a39:	55                   	push   %ebp
80102a3a:	89 e5                	mov    %esp,%ebp
80102a3c:	53                   	push   %ebx
80102a3d:	83 ec 04             	sub    $0x4,%esp
80102a40:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80102a43:	8b 15 48 27 13 80    	mov    0x80132748,%edx
80102a49:	83 fa 1d             	cmp    $0x1d,%edx
80102a4c:	7f 45                	jg     80102a93 <log_write+0x5a>
80102a4e:	a1 38 27 13 80       	mov    0x80132738,%eax
80102a53:	83 e8 01             	sub    $0x1,%eax
80102a56:	39 c2                	cmp    %eax,%edx
80102a58:	7d 39                	jge    80102a93 <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102a5a:	83 3d 3c 27 13 80 00 	cmpl   $0x0,0x8013273c
80102a61:	7e 3d                	jle    80102aa0 <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102a63:	83 ec 0c             	sub    $0xc,%esp
80102a66:	68 00 27 13 80       	push   $0x80132700
80102a6b:	e8 92 12 00 00       	call   80103d02 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80102a70:	83 c4 10             	add    $0x10,%esp
80102a73:	b8 00 00 00 00       	mov    $0x0,%eax
80102a78:	8b 15 48 27 13 80    	mov    0x80132748,%edx
80102a7e:	39 c2                	cmp    %eax,%edx
80102a80:	7e 2b                	jle    80102aad <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102a82:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102a85:	39 0c 85 4c 27 13 80 	cmp    %ecx,-0x7fecd8b4(,%eax,4)
80102a8c:	74 1f                	je     80102aad <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
80102a8e:	83 c0 01             	add    $0x1,%eax
80102a91:	eb e5                	jmp    80102a78 <log_write+0x3f>
    panic("too big a transaction");
80102a93:	83 ec 0c             	sub    $0xc,%esp
80102a96:	68 f3 6a 10 80       	push   $0x80106af3
80102a9b:	e8 a8 d8 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102aa0:	83 ec 0c             	sub    $0xc,%esp
80102aa3:	68 09 6b 10 80       	push   $0x80106b09
80102aa8:	e8 9b d8 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102aad:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102ab0:	89 0c 85 4c 27 13 80 	mov    %ecx,-0x7fecd8b4(,%eax,4)
  if (i == log.lh.n)
80102ab7:	39 c2                	cmp    %eax,%edx
80102ab9:	74 18                	je     80102ad3 <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102abb:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102abe:	83 ec 0c             	sub    $0xc,%esp
80102ac1:	68 00 27 13 80       	push   $0x80132700
80102ac6:	e8 9c 12 00 00       	call   80103d67 <release>
}
80102acb:	83 c4 10             	add    $0x10,%esp
80102ace:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102ad1:	c9                   	leave  
80102ad2:	c3                   	ret    
    log.lh.n++;
80102ad3:	83 c2 01             	add    $0x1,%edx
80102ad6:	89 15 48 27 13 80    	mov    %edx,0x80132748
80102adc:	eb dd                	jmp    80102abb <log_write+0x82>

80102ade <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102ade:	55                   	push   %ebp
80102adf:	89 e5                	mov    %esp,%ebp
80102ae1:	53                   	push   %ebx
80102ae2:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102ae5:	68 8a 00 00 00       	push   $0x8a
80102aea:	68 8c a4 10 80       	push   $0x8010a48c
80102aef:	68 00 70 00 80       	push   $0x80007000
80102af4:	e8 30 13 00 00       	call   80103e29 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102af9:	83 c4 10             	add    $0x10,%esp
80102afc:	bb 00 28 13 80       	mov    $0x80132800,%ebx
80102b01:	eb 06                	jmp    80102b09 <startothers+0x2b>
80102b03:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102b09:	69 05 80 2d 13 80 b0 	imul   $0xb0,0x80132d80,%eax
80102b10:	00 00 00 
80102b13:	05 00 28 13 80       	add    $0x80132800,%eax
80102b18:	39 d8                	cmp    %ebx,%eax
80102b1a:	76 4c                	jbe    80102b68 <startothers+0x8a>
    if(c == mycpu())  // We've started already.
80102b1c:	e8 c8 07 00 00       	call   801032e9 <mycpu>
80102b21:	39 d8                	cmp    %ebx,%eax
80102b23:	74 de                	je     80102b03 <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80102b25:	e8 9e f5 ff ff       	call   801020c8 <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102b2a:	05 00 10 00 00       	add    $0x1000,%eax
80102b2f:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102b34:	c7 05 f8 6f 00 80 ac 	movl   $0x80102bac,0x80006ff8
80102b3b:	2b 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102b3e:	c7 05 f4 6f 00 80 00 	movl   $0x109000,0x80006ff4
80102b45:	90 10 00 

    lapicstartap(c->apicid, V2P(code));
80102b48:	83 ec 08             	sub    $0x8,%esp
80102b4b:	68 00 70 00 00       	push   $0x7000
80102b50:	0f b6 03             	movzbl (%ebx),%eax
80102b53:	50                   	push   %eax
80102b54:	e8 c6 f9 ff ff       	call   8010251f <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102b59:	83 c4 10             	add    $0x10,%esp
80102b5c:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102b62:	85 c0                	test   %eax,%eax
80102b64:	74 f6                	je     80102b5c <startothers+0x7e>
80102b66:	eb 9b                	jmp    80102b03 <startothers+0x25>
      ;
  }
}
80102b68:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102b6b:	c9                   	leave  
80102b6c:	c3                   	ret    

80102b6d <mpmain>:
{
80102b6d:	55                   	push   %ebp
80102b6e:	89 e5                	mov    %esp,%ebp
80102b70:	53                   	push   %ebx
80102b71:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102b74:	e8 cc 07 00 00       	call   80103345 <cpuid>
80102b79:	89 c3                	mov    %eax,%ebx
80102b7b:	e8 c5 07 00 00       	call   80103345 <cpuid>
80102b80:	83 ec 04             	sub    $0x4,%esp
80102b83:	53                   	push   %ebx
80102b84:	50                   	push   %eax
80102b85:	68 24 6b 10 80       	push   $0x80106b24
80102b8a:	e8 7c da ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102b8f:	e8 ec 23 00 00       	call   80104f80 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102b94:	e8 50 07 00 00       	call   801032e9 <mycpu>
80102b99:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102b9b:	b8 01 00 00 00       	mov    $0x1,%eax
80102ba0:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102ba7:	e8 36 0a 00 00       	call   801035e2 <scheduler>

80102bac <mpenter>:
{
80102bac:	55                   	push   %ebp
80102bad:	89 e5                	mov    %esp,%ebp
80102baf:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102bb2:	e8 da 33 00 00       	call   80105f91 <switchkvm>
  seginit();
80102bb7:	e8 89 32 00 00       	call   80105e45 <seginit>
  lapicinit();
80102bbc:	e8 15 f8 ff ff       	call   801023d6 <lapicinit>
  mpmain();
80102bc1:	e8 a7 ff ff ff       	call   80102b6d <mpmain>

80102bc6 <main>:
{
80102bc6:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102bca:	83 e4 f0             	and    $0xfffffff0,%esp
80102bcd:	ff 71 fc             	pushl  -0x4(%ecx)
80102bd0:	55                   	push   %ebp
80102bd1:	89 e5                	mov    %esp,%ebp
80102bd3:	51                   	push   %ecx
80102bd4:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102bd7:	68 00 00 40 80       	push   $0x80400000
80102bdc:	68 28 55 13 80       	push   $0x80135528
80102be1:	e8 83 f4 ff ff       	call   80102069 <kinit1>
  kvmalloc();      // kernel page table
80102be6:	e8 4e 38 00 00       	call   80106439 <kvmalloc>
  mpinit();        // detect other processors
80102beb:	e8 c9 01 00 00       	call   80102db9 <mpinit>
  lapicinit();     // interrupt controller
80102bf0:	e8 e1 f7 ff ff       	call   801023d6 <lapicinit>
  seginit();       // segment descriptors
80102bf5:	e8 4b 32 00 00       	call   80105e45 <seginit>
  picinit();       // disable pic
80102bfa:	e8 82 02 00 00       	call   80102e81 <picinit>
  ioapicinit();    // another interrupt controller
80102bff:	e8 f6 f2 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102c04:	e8 85 dc ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102c09:	e8 20 26 00 00       	call   8010522e <uartinit>
  pinit();         // process table
80102c0e:	e8 bc 06 00 00       	call   801032cf <pinit>
  tvinit();        // trap vectors
80102c13:	e8 b7 22 00 00       	call   80104ecf <tvinit>
  binit();         // buffer cache
80102c18:	e8 d7 d4 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102c1d:	e8 f1 df ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102c22:	e8 d9 f0 ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102c27:	e8 b2 fe ff ff       	call   80102ade <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102c2c:	83 c4 08             	add    $0x8,%esp
80102c2f:	68 00 00 00 8e       	push   $0x8e000000
80102c34:	68 00 00 40 80       	push   $0x80400000
80102c39:	e8 5d f4 ff ff       	call   8010209b <kinit2>
  userinit();      // first user process
80102c3e:	e8 41 07 00 00       	call   80103384 <userinit>
  mpmain();        // finish this processor's setup
80102c43:	e8 25 ff ff ff       	call   80102b6d <mpmain>

80102c48 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102c48:	55                   	push   %ebp
80102c49:	89 e5                	mov    %esp,%ebp
80102c4b:	56                   	push   %esi
80102c4c:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102c4d:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102c52:	b9 00 00 00 00       	mov    $0x0,%ecx
80102c57:	eb 09                	jmp    80102c62 <sum+0x1a>
    sum += addr[i];
80102c59:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102c5d:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102c5f:	83 c1 01             	add    $0x1,%ecx
80102c62:	39 d1                	cmp    %edx,%ecx
80102c64:	7c f3                	jl     80102c59 <sum+0x11>
  return sum;
}
80102c66:	89 d8                	mov    %ebx,%eax
80102c68:	5b                   	pop    %ebx
80102c69:	5e                   	pop    %esi
80102c6a:	5d                   	pop    %ebp
80102c6b:	c3                   	ret    

80102c6c <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102c6c:	55                   	push   %ebp
80102c6d:	89 e5                	mov    %esp,%ebp
80102c6f:	56                   	push   %esi
80102c70:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102c71:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102c77:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102c79:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102c7b:	eb 03                	jmp    80102c80 <mpsearch1+0x14>
80102c7d:	83 c3 10             	add    $0x10,%ebx
80102c80:	39 f3                	cmp    %esi,%ebx
80102c82:	73 29                	jae    80102cad <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102c84:	83 ec 04             	sub    $0x4,%esp
80102c87:	6a 04                	push   $0x4
80102c89:	68 38 6b 10 80       	push   $0x80106b38
80102c8e:	53                   	push   %ebx
80102c8f:	e8 60 11 00 00       	call   80103df4 <memcmp>
80102c94:	83 c4 10             	add    $0x10,%esp
80102c97:	85 c0                	test   %eax,%eax
80102c99:	75 e2                	jne    80102c7d <mpsearch1+0x11>
80102c9b:	ba 10 00 00 00       	mov    $0x10,%edx
80102ca0:	89 d8                	mov    %ebx,%eax
80102ca2:	e8 a1 ff ff ff       	call   80102c48 <sum>
80102ca7:	84 c0                	test   %al,%al
80102ca9:	75 d2                	jne    80102c7d <mpsearch1+0x11>
80102cab:	eb 05                	jmp    80102cb2 <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102cad:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102cb2:	89 d8                	mov    %ebx,%eax
80102cb4:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102cb7:	5b                   	pop    %ebx
80102cb8:	5e                   	pop    %esi
80102cb9:	5d                   	pop    %ebp
80102cba:	c3                   	ret    

80102cbb <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102cbb:	55                   	push   %ebp
80102cbc:	89 e5                	mov    %esp,%ebp
80102cbe:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102cc1:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102cc8:	c1 e0 08             	shl    $0x8,%eax
80102ccb:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102cd2:	09 d0                	or     %edx,%eax
80102cd4:	c1 e0 04             	shl    $0x4,%eax
80102cd7:	85 c0                	test   %eax,%eax
80102cd9:	74 1f                	je     80102cfa <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102cdb:	ba 00 04 00 00       	mov    $0x400,%edx
80102ce0:	e8 87 ff ff ff       	call   80102c6c <mpsearch1>
80102ce5:	85 c0                	test   %eax,%eax
80102ce7:	75 0f                	jne    80102cf8 <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102ce9:	ba 00 00 01 00       	mov    $0x10000,%edx
80102cee:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102cf3:	e8 74 ff ff ff       	call   80102c6c <mpsearch1>
}
80102cf8:	c9                   	leave  
80102cf9:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102cfa:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102d01:	c1 e0 08             	shl    $0x8,%eax
80102d04:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102d0b:	09 d0                	or     %edx,%eax
80102d0d:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102d10:	2d 00 04 00 00       	sub    $0x400,%eax
80102d15:	ba 00 04 00 00       	mov    $0x400,%edx
80102d1a:	e8 4d ff ff ff       	call   80102c6c <mpsearch1>
80102d1f:	85 c0                	test   %eax,%eax
80102d21:	75 d5                	jne    80102cf8 <mpsearch+0x3d>
80102d23:	eb c4                	jmp    80102ce9 <mpsearch+0x2e>

80102d25 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102d25:	55                   	push   %ebp
80102d26:	89 e5                	mov    %esp,%ebp
80102d28:	57                   	push   %edi
80102d29:	56                   	push   %esi
80102d2a:	53                   	push   %ebx
80102d2b:	83 ec 1c             	sub    $0x1c,%esp
80102d2e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102d31:	e8 85 ff ff ff       	call   80102cbb <mpsearch>
80102d36:	85 c0                	test   %eax,%eax
80102d38:	74 5c                	je     80102d96 <mpconfig+0x71>
80102d3a:	89 c7                	mov    %eax,%edi
80102d3c:	8b 58 04             	mov    0x4(%eax),%ebx
80102d3f:	85 db                	test   %ebx,%ebx
80102d41:	74 5a                	je     80102d9d <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102d43:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102d49:	83 ec 04             	sub    $0x4,%esp
80102d4c:	6a 04                	push   $0x4
80102d4e:	68 3d 6b 10 80       	push   $0x80106b3d
80102d53:	56                   	push   %esi
80102d54:	e8 9b 10 00 00       	call   80103df4 <memcmp>
80102d59:	83 c4 10             	add    $0x10,%esp
80102d5c:	85 c0                	test   %eax,%eax
80102d5e:	75 44                	jne    80102da4 <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102d60:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102d67:	3c 01                	cmp    $0x1,%al
80102d69:	0f 95 c2             	setne  %dl
80102d6c:	3c 04                	cmp    $0x4,%al
80102d6e:	0f 95 c0             	setne  %al
80102d71:	84 c2                	test   %al,%dl
80102d73:	75 36                	jne    80102dab <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102d75:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102d7c:	89 f0                	mov    %esi,%eax
80102d7e:	e8 c5 fe ff ff       	call   80102c48 <sum>
80102d83:	84 c0                	test   %al,%al
80102d85:	75 2b                	jne    80102db2 <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102d87:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102d8a:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102d8c:	89 f0                	mov    %esi,%eax
80102d8e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102d91:	5b                   	pop    %ebx
80102d92:	5e                   	pop    %esi
80102d93:	5f                   	pop    %edi
80102d94:	5d                   	pop    %ebp
80102d95:	c3                   	ret    
    return 0;
80102d96:	be 00 00 00 00       	mov    $0x0,%esi
80102d9b:	eb ef                	jmp    80102d8c <mpconfig+0x67>
80102d9d:	be 00 00 00 00       	mov    $0x0,%esi
80102da2:	eb e8                	jmp    80102d8c <mpconfig+0x67>
    return 0;
80102da4:	be 00 00 00 00       	mov    $0x0,%esi
80102da9:	eb e1                	jmp    80102d8c <mpconfig+0x67>
    return 0;
80102dab:	be 00 00 00 00       	mov    $0x0,%esi
80102db0:	eb da                	jmp    80102d8c <mpconfig+0x67>
    return 0;
80102db2:	be 00 00 00 00       	mov    $0x0,%esi
80102db7:	eb d3                	jmp    80102d8c <mpconfig+0x67>

80102db9 <mpinit>:

void
mpinit(void)
{
80102db9:	55                   	push   %ebp
80102dba:	89 e5                	mov    %esp,%ebp
80102dbc:	57                   	push   %edi
80102dbd:	56                   	push   %esi
80102dbe:	53                   	push   %ebx
80102dbf:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102dc2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102dc5:	e8 5b ff ff ff       	call   80102d25 <mpconfig>
80102dca:	85 c0                	test   %eax,%eax
80102dcc:	74 19                	je     80102de7 <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102dce:	8b 50 24             	mov    0x24(%eax),%edx
80102dd1:	89 15 e4 26 13 80    	mov    %edx,0x801326e4
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102dd7:	8d 50 2c             	lea    0x2c(%eax),%edx
80102dda:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102dde:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102de0:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102de5:	eb 34                	jmp    80102e1b <mpinit+0x62>
    panic("Expect to run on an SMP");
80102de7:	83 ec 0c             	sub    $0xc,%esp
80102dea:	68 42 6b 10 80       	push   $0x80106b42
80102def:	e8 54 d5 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102df4:	8b 35 80 2d 13 80    	mov    0x80132d80,%esi
80102dfa:	83 fe 07             	cmp    $0x7,%esi
80102dfd:	7f 19                	jg     80102e18 <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102dff:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102e03:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102e09:	88 87 00 28 13 80    	mov    %al,-0x7fecd800(%edi)
        ncpu++;
80102e0f:	83 c6 01             	add    $0x1,%esi
80102e12:	89 35 80 2d 13 80    	mov    %esi,0x80132d80
      }
      p += sizeof(struct mpproc);
80102e18:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102e1b:	39 ca                	cmp    %ecx,%edx
80102e1d:	73 2b                	jae    80102e4a <mpinit+0x91>
    switch(*p){
80102e1f:	0f b6 02             	movzbl (%edx),%eax
80102e22:	3c 04                	cmp    $0x4,%al
80102e24:	77 1d                	ja     80102e43 <mpinit+0x8a>
80102e26:	0f b6 c0             	movzbl %al,%eax
80102e29:	ff 24 85 7c 6b 10 80 	jmp    *-0x7fef9484(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102e30:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102e34:	a2 e0 27 13 80       	mov    %al,0x801327e0
      p += sizeof(struct mpioapic);
80102e39:	83 c2 08             	add    $0x8,%edx
      continue;
80102e3c:	eb dd                	jmp    80102e1b <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102e3e:	83 c2 08             	add    $0x8,%edx
      continue;
80102e41:	eb d8                	jmp    80102e1b <mpinit+0x62>
    default:
      ismp = 0;
80102e43:	bb 00 00 00 00       	mov    $0x0,%ebx
80102e48:	eb d1                	jmp    80102e1b <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102e4a:	85 db                	test   %ebx,%ebx
80102e4c:	74 26                	je     80102e74 <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102e4e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102e51:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102e55:	74 15                	je     80102e6c <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e57:	b8 70 00 00 00       	mov    $0x70,%eax
80102e5c:	ba 22 00 00 00       	mov    $0x22,%edx
80102e61:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102e62:	ba 23 00 00 00       	mov    $0x23,%edx
80102e67:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102e68:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e6b:	ee                   	out    %al,(%dx)
  }
}
80102e6c:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102e6f:	5b                   	pop    %ebx
80102e70:	5e                   	pop    %esi
80102e71:	5f                   	pop    %edi
80102e72:	5d                   	pop    %ebp
80102e73:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102e74:	83 ec 0c             	sub    $0xc,%esp
80102e77:	68 5c 6b 10 80       	push   $0x80106b5c
80102e7c:	e8 c7 d4 ff ff       	call   80100348 <panic>

80102e81 <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102e81:	55                   	push   %ebp
80102e82:	89 e5                	mov    %esp,%ebp
80102e84:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102e89:	ba 21 00 00 00       	mov    $0x21,%edx
80102e8e:	ee                   	out    %al,(%dx)
80102e8f:	ba a1 00 00 00       	mov    $0xa1,%edx
80102e94:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102e95:	5d                   	pop    %ebp
80102e96:	c3                   	ret    

80102e97 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102e97:	55                   	push   %ebp
80102e98:	89 e5                	mov    %esp,%ebp
80102e9a:	57                   	push   %edi
80102e9b:	56                   	push   %esi
80102e9c:	53                   	push   %ebx
80102e9d:	83 ec 0c             	sub    $0xc,%esp
80102ea0:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102ea3:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102ea6:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102eac:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102eb2:	e8 76 dd ff ff       	call   80100c2d <filealloc>
80102eb7:	89 03                	mov    %eax,(%ebx)
80102eb9:	85 c0                	test   %eax,%eax
80102ebb:	74 1e                	je     80102edb <pipealloc+0x44>
80102ebd:	e8 6b dd ff ff       	call   80100c2d <filealloc>
80102ec2:	89 06                	mov    %eax,(%esi)
80102ec4:	85 c0                	test   %eax,%eax
80102ec6:	74 13                	je     80102edb <pipealloc+0x44>
    goto bad;
  if((p = (struct pipe*)kalloc2(-2)) == 0)
80102ec8:	83 ec 0c             	sub    $0xc,%esp
80102ecb:	6a fe                	push   $0xfffffffe
80102ecd:	e8 8c f2 ff ff       	call   8010215e <kalloc2>
80102ed2:	89 c7                	mov    %eax,%edi
80102ed4:	83 c4 10             	add    $0x10,%esp
80102ed7:	85 c0                	test   %eax,%eax
80102ed9:	75 35                	jne    80102f10 <pipealloc+0x79>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102edb:	8b 03                	mov    (%ebx),%eax
80102edd:	85 c0                	test   %eax,%eax
80102edf:	74 0c                	je     80102eed <pipealloc+0x56>
    fileclose(*f0);
80102ee1:	83 ec 0c             	sub    $0xc,%esp
80102ee4:	50                   	push   %eax
80102ee5:	e8 e9 dd ff ff       	call   80100cd3 <fileclose>
80102eea:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102eed:	8b 06                	mov    (%esi),%eax
80102eef:	85 c0                	test   %eax,%eax
80102ef1:	0f 84 8b 00 00 00    	je     80102f82 <pipealloc+0xeb>
    fileclose(*f1);
80102ef7:	83 ec 0c             	sub    $0xc,%esp
80102efa:	50                   	push   %eax
80102efb:	e8 d3 dd ff ff       	call   80100cd3 <fileclose>
80102f00:	83 c4 10             	add    $0x10,%esp
  return -1;
80102f03:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102f08:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102f0b:	5b                   	pop    %ebx
80102f0c:	5e                   	pop    %esi
80102f0d:	5f                   	pop    %edi
80102f0e:	5d                   	pop    %ebp
80102f0f:	c3                   	ret    
  p->readopen = 1;
80102f10:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102f17:	00 00 00 
  p->writeopen = 1;
80102f1a:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102f21:	00 00 00 
  p->nwrite = 0;
80102f24:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102f2b:	00 00 00 
  p->nread = 0;
80102f2e:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102f35:	00 00 00 
  initlock(&p->lock, "pipe");
80102f38:	83 ec 08             	sub    $0x8,%esp
80102f3b:	68 90 6b 10 80       	push   $0x80106b90
80102f40:	50                   	push   %eax
80102f41:	e8 80 0c 00 00       	call   80103bc6 <initlock>
  (*f0)->type = FD_PIPE;
80102f46:	8b 03                	mov    (%ebx),%eax
80102f48:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102f4e:	8b 03                	mov    (%ebx),%eax
80102f50:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102f54:	8b 03                	mov    (%ebx),%eax
80102f56:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102f5a:	8b 03                	mov    (%ebx),%eax
80102f5c:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80102f5f:	8b 06                	mov    (%esi),%eax
80102f61:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80102f67:	8b 06                	mov    (%esi),%eax
80102f69:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80102f6d:	8b 06                	mov    (%esi),%eax
80102f6f:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80102f73:	8b 06                	mov    (%esi),%eax
80102f75:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80102f78:	83 c4 10             	add    $0x10,%esp
80102f7b:	b8 00 00 00 00       	mov    $0x0,%eax
80102f80:	eb 86                	jmp    80102f08 <pipealloc+0x71>
  return -1;
80102f82:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102f87:	e9 7c ff ff ff       	jmp    80102f08 <pipealloc+0x71>

80102f8c <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80102f8c:	55                   	push   %ebp
80102f8d:	89 e5                	mov    %esp,%ebp
80102f8f:	53                   	push   %ebx
80102f90:	83 ec 10             	sub    $0x10,%esp
80102f93:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80102f96:	53                   	push   %ebx
80102f97:	e8 66 0d 00 00       	call   80103d02 <acquire>
  if(writable){
80102f9c:	83 c4 10             	add    $0x10,%esp
80102f9f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102fa3:	74 3f                	je     80102fe4 <pipeclose+0x58>
    p->writeopen = 0;
80102fa5:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80102fac:	00 00 00 
    wakeup(&p->nread);
80102faf:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102fb5:	83 ec 0c             	sub    $0xc,%esp
80102fb8:	50                   	push   %eax
80102fb9:	e8 ae 09 00 00       	call   8010396c <wakeup>
80102fbe:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80102fc1:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102fc8:	75 09                	jne    80102fd3 <pipeclose+0x47>
80102fca:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80102fd1:	74 2f                	je     80103002 <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80102fd3:	83 ec 0c             	sub    $0xc,%esp
80102fd6:	53                   	push   %ebx
80102fd7:	e8 8b 0d 00 00       	call   80103d67 <release>
80102fdc:	83 c4 10             	add    $0x10,%esp
}
80102fdf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102fe2:	c9                   	leave  
80102fe3:	c3                   	ret    
    p->readopen = 0;
80102fe4:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
80102feb:	00 00 00 
    wakeup(&p->nwrite);
80102fee:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102ff4:	83 ec 0c             	sub    $0xc,%esp
80102ff7:	50                   	push   %eax
80102ff8:	e8 6f 09 00 00       	call   8010396c <wakeup>
80102ffd:	83 c4 10             	add    $0x10,%esp
80103000:	eb bf                	jmp    80102fc1 <pipeclose+0x35>
    release(&p->lock);
80103002:	83 ec 0c             	sub    $0xc,%esp
80103005:	53                   	push   %ebx
80103006:	e8 5c 0d 00 00       	call   80103d67 <release>
    kfree((char*)p);
8010300b:	89 1c 24             	mov    %ebx,(%esp)
8010300e:	e8 91 ef ff ff       	call   80101fa4 <kfree>
80103013:	83 c4 10             	add    $0x10,%esp
80103016:	eb c7                	jmp    80102fdf <pipeclose+0x53>

80103018 <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
80103018:	55                   	push   %ebp
80103019:	89 e5                	mov    %esp,%ebp
8010301b:	57                   	push   %edi
8010301c:	56                   	push   %esi
8010301d:	53                   	push   %ebx
8010301e:	83 ec 18             	sub    $0x18,%esp
80103021:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80103024:	89 de                	mov    %ebx,%esi
80103026:	53                   	push   %ebx
80103027:	e8 d6 0c 00 00       	call   80103d02 <acquire>
  for(i = 0; i < n; i++){
8010302c:	83 c4 10             	add    $0x10,%esp
8010302f:	bf 00 00 00 00       	mov    $0x0,%edi
80103034:	3b 7d 10             	cmp    0x10(%ebp),%edi
80103037:	0f 8d 88 00 00 00    	jge    801030c5 <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010303d:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
80103043:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103049:	05 00 02 00 00       	add    $0x200,%eax
8010304e:	39 c2                	cmp    %eax,%edx
80103050:	75 51                	jne    801030a3 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
80103052:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80103059:	74 2f                	je     8010308a <pipewrite+0x72>
8010305b:	e8 00 03 00 00       	call   80103360 <myproc>
80103060:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80103064:	75 24                	jne    8010308a <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
80103066:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
8010306c:	83 ec 0c             	sub    $0xc,%esp
8010306f:	50                   	push   %eax
80103070:	e8 f7 08 00 00       	call   8010396c <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103075:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
8010307b:	83 c4 08             	add    $0x8,%esp
8010307e:	56                   	push   %esi
8010307f:	50                   	push   %eax
80103080:	e8 82 07 00 00       	call   80103807 <sleep>
80103085:	83 c4 10             	add    $0x10,%esp
80103088:	eb b3                	jmp    8010303d <pipewrite+0x25>
        release(&p->lock);
8010308a:	83 ec 0c             	sub    $0xc,%esp
8010308d:	53                   	push   %ebx
8010308e:	e8 d4 0c 00 00       	call   80103d67 <release>
        return -1;
80103093:	83 c4 10             	add    $0x10,%esp
80103096:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
8010309b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010309e:	5b                   	pop    %ebx
8010309f:	5e                   	pop    %esi
801030a0:	5f                   	pop    %edi
801030a1:	5d                   	pop    %ebp
801030a2:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
801030a3:	8d 42 01             	lea    0x1(%edx),%eax
801030a6:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
801030ac:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
801030b2:	8b 45 0c             	mov    0xc(%ebp),%eax
801030b5:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
801030b9:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
801030bd:	83 c7 01             	add    $0x1,%edi
801030c0:	e9 6f ff ff ff       	jmp    80103034 <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
801030c5:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801030cb:	83 ec 0c             	sub    $0xc,%esp
801030ce:	50                   	push   %eax
801030cf:	e8 98 08 00 00       	call   8010396c <wakeup>
  release(&p->lock);
801030d4:	89 1c 24             	mov    %ebx,(%esp)
801030d7:	e8 8b 0c 00 00       	call   80103d67 <release>
  return n;
801030dc:	83 c4 10             	add    $0x10,%esp
801030df:	8b 45 10             	mov    0x10(%ebp),%eax
801030e2:	eb b7                	jmp    8010309b <pipewrite+0x83>

801030e4 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801030e4:	55                   	push   %ebp
801030e5:	89 e5                	mov    %esp,%ebp
801030e7:	57                   	push   %edi
801030e8:	56                   	push   %esi
801030e9:	53                   	push   %ebx
801030ea:	83 ec 18             	sub    $0x18,%esp
801030ed:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
801030f0:	89 df                	mov    %ebx,%edi
801030f2:	53                   	push   %ebx
801030f3:	e8 0a 0c 00 00       	call   80103d02 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801030f8:	83 c4 10             	add    $0x10,%esp
801030fb:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
80103101:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
80103107:	75 3d                	jne    80103146 <piperead+0x62>
80103109:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
8010310f:	85 f6                	test   %esi,%esi
80103111:	74 38                	je     8010314b <piperead+0x67>
    if(myproc()->killed){
80103113:	e8 48 02 00 00       	call   80103360 <myproc>
80103118:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010311c:	75 15                	jne    80103133 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010311e:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103124:	83 ec 08             	sub    $0x8,%esp
80103127:	57                   	push   %edi
80103128:	50                   	push   %eax
80103129:	e8 d9 06 00 00       	call   80103807 <sleep>
8010312e:	83 c4 10             	add    $0x10,%esp
80103131:	eb c8                	jmp    801030fb <piperead+0x17>
      release(&p->lock);
80103133:	83 ec 0c             	sub    $0xc,%esp
80103136:	53                   	push   %ebx
80103137:	e8 2b 0c 00 00       	call   80103d67 <release>
      return -1;
8010313c:	83 c4 10             	add    $0x10,%esp
8010313f:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103144:	eb 50                	jmp    80103196 <piperead+0xb2>
80103146:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010314b:	3b 75 10             	cmp    0x10(%ebp),%esi
8010314e:	7d 2c                	jge    8010317c <piperead+0x98>
    if(p->nread == p->nwrite)
80103150:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103156:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
8010315c:	74 1e                	je     8010317c <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
8010315e:	8d 50 01             	lea    0x1(%eax),%edx
80103161:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
80103167:	25 ff 01 00 00       	and    $0x1ff,%eax
8010316c:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
80103171:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103174:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103177:	83 c6 01             	add    $0x1,%esi
8010317a:	eb cf                	jmp    8010314b <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
8010317c:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103182:	83 ec 0c             	sub    $0xc,%esp
80103185:	50                   	push   %eax
80103186:	e8 e1 07 00 00       	call   8010396c <wakeup>
  release(&p->lock);
8010318b:	89 1c 24             	mov    %ebx,(%esp)
8010318e:	e8 d4 0b 00 00       	call   80103d67 <release>
  return i;
80103193:	83 c4 10             	add    $0x10,%esp
}
80103196:	89 f0                	mov    %esi,%eax
80103198:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010319b:	5b                   	pop    %ebx
8010319c:	5e                   	pop    %esi
8010319d:	5f                   	pop    %edi
8010319e:	5d                   	pop    %ebp
8010319f:	c3                   	ret    

801031a0 <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
801031a0:	55                   	push   %ebp
801031a1:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801031a3:	ba d4 2d 13 80       	mov    $0x80132dd4,%edx
801031a8:	eb 03                	jmp    801031ad <wakeup1+0xd>
801031aa:	83 c2 7c             	add    $0x7c,%edx
801031ad:	81 fa d4 4c 13 80    	cmp    $0x80134cd4,%edx
801031b3:	73 14                	jae    801031c9 <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
801031b5:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
801031b9:	75 ef                	jne    801031aa <wakeup1+0xa>
801031bb:	39 42 20             	cmp    %eax,0x20(%edx)
801031be:	75 ea                	jne    801031aa <wakeup1+0xa>
      p->state = RUNNABLE;
801031c0:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
801031c7:	eb e1                	jmp    801031aa <wakeup1+0xa>
}
801031c9:	5d                   	pop    %ebp
801031ca:	c3                   	ret    

801031cb <allocproc>:
{
801031cb:	55                   	push   %ebp
801031cc:	89 e5                	mov    %esp,%ebp
801031ce:	53                   	push   %ebx
801031cf:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
801031d2:	68 a0 2d 13 80       	push   $0x80132da0
801031d7:	e8 26 0b 00 00       	call   80103d02 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801031dc:	83 c4 10             	add    $0x10,%esp
801031df:	bb d4 2d 13 80       	mov    $0x80132dd4,%ebx
801031e4:	81 fb d4 4c 13 80    	cmp    $0x80134cd4,%ebx
801031ea:	73 0b                	jae    801031f7 <allocproc+0x2c>
    if(p->state == UNUSED)
801031ec:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
801031f0:	74 1c                	je     8010320e <allocproc+0x43>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801031f2:	83 c3 7c             	add    $0x7c,%ebx
801031f5:	eb ed                	jmp    801031e4 <allocproc+0x19>
  release(&ptable.lock);
801031f7:	83 ec 0c             	sub    $0xc,%esp
801031fa:	68 a0 2d 13 80       	push   $0x80132da0
801031ff:	e8 63 0b 00 00       	call   80103d67 <release>
  return 0;
80103204:	83 c4 10             	add    $0x10,%esp
80103207:	bb 00 00 00 00       	mov    $0x0,%ebx
8010320c:	eb 69                	jmp    80103277 <allocproc+0xac>
  p->state = EMBRYO;
8010320e:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
80103215:	a1 04 a0 10 80       	mov    0x8010a004,%eax
8010321a:	8d 50 01             	lea    0x1(%eax),%edx
8010321d:	89 15 04 a0 10 80    	mov    %edx,0x8010a004
80103223:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
80103226:	83 ec 0c             	sub    $0xc,%esp
80103229:	68 a0 2d 13 80       	push   $0x80132da0
8010322e:	e8 34 0b 00 00       	call   80103d67 <release>
  if((p->kstack = kalloc()) == 0){
80103233:	e8 90 ee ff ff       	call   801020c8 <kalloc>
80103238:	89 43 08             	mov    %eax,0x8(%ebx)
8010323b:	83 c4 10             	add    $0x10,%esp
8010323e:	85 c0                	test   %eax,%eax
80103240:	74 3c                	je     8010327e <allocproc+0xb3>
  sp -= sizeof *p->tf;
80103242:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
80103248:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
8010324b:	c7 80 b0 0f 00 00 c4 	movl   $0x80104ec4,0xfb0(%eax)
80103252:	4e 10 80 
  sp -= sizeof *p->context;
80103255:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
8010325a:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
8010325d:	83 ec 04             	sub    $0x4,%esp
80103260:	6a 14                	push   $0x14
80103262:	6a 00                	push   $0x0
80103264:	50                   	push   %eax
80103265:	e8 44 0b 00 00       	call   80103dae <memset>
  p->context->eip = (uint)forkret;
8010326a:	8b 43 1c             	mov    0x1c(%ebx),%eax
8010326d:	c7 40 10 8c 32 10 80 	movl   $0x8010328c,0x10(%eax)
  return p;
80103274:	83 c4 10             	add    $0x10,%esp
}
80103277:	89 d8                	mov    %ebx,%eax
80103279:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010327c:	c9                   	leave  
8010327d:	c3                   	ret    
    p->state = UNUSED;
8010327e:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
80103285:	bb 00 00 00 00       	mov    $0x0,%ebx
8010328a:	eb eb                	jmp    80103277 <allocproc+0xac>

8010328c <forkret>:
{
8010328c:	55                   	push   %ebp
8010328d:	89 e5                	mov    %esp,%ebp
8010328f:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
80103292:	68 a0 2d 13 80       	push   $0x80132da0
80103297:	e8 cb 0a 00 00       	call   80103d67 <release>
  if (first) {
8010329c:	83 c4 10             	add    $0x10,%esp
8010329f:	83 3d 00 a0 10 80 00 	cmpl   $0x0,0x8010a000
801032a6:	75 02                	jne    801032aa <forkret+0x1e>
}
801032a8:	c9                   	leave  
801032a9:	c3                   	ret    
    first = 0;
801032aa:	c7 05 00 a0 10 80 00 	movl   $0x0,0x8010a000
801032b1:	00 00 00 
    iinit(ROOTDEV);
801032b4:	83 ec 0c             	sub    $0xc,%esp
801032b7:	6a 01                	push   $0x1
801032b9:	e8 2e e0 ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
801032be:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801032c5:	e8 fd f5 ff ff       	call   801028c7 <initlog>
801032ca:	83 c4 10             	add    $0x10,%esp
}
801032cd:	eb d9                	jmp    801032a8 <forkret+0x1c>

801032cf <pinit>:
{
801032cf:	55                   	push   %ebp
801032d0:	89 e5                	mov    %esp,%ebp
801032d2:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
801032d5:	68 95 6b 10 80       	push   $0x80106b95
801032da:	68 a0 2d 13 80       	push   $0x80132da0
801032df:	e8 e2 08 00 00       	call   80103bc6 <initlock>
}
801032e4:	83 c4 10             	add    $0x10,%esp
801032e7:	c9                   	leave  
801032e8:	c3                   	ret    

801032e9 <mycpu>:
{
801032e9:	55                   	push   %ebp
801032ea:	89 e5                	mov    %esp,%ebp
801032ec:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801032ef:	9c                   	pushf  
801032f0:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801032f1:	f6 c4 02             	test   $0x2,%ah
801032f4:	75 28                	jne    8010331e <mycpu+0x35>
  apicid = lapicid();
801032f6:	e8 e5 f1 ff ff       	call   801024e0 <lapicid>
  for (i = 0; i < ncpu; ++i) {
801032fb:	ba 00 00 00 00       	mov    $0x0,%edx
80103300:	39 15 80 2d 13 80    	cmp    %edx,0x80132d80
80103306:	7e 23                	jle    8010332b <mycpu+0x42>
    if (cpus[i].apicid == apicid)
80103308:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
8010330e:	0f b6 89 00 28 13 80 	movzbl -0x7fecd800(%ecx),%ecx
80103315:	39 c1                	cmp    %eax,%ecx
80103317:	74 1f                	je     80103338 <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
80103319:	83 c2 01             	add    $0x1,%edx
8010331c:	eb e2                	jmp    80103300 <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
8010331e:	83 ec 0c             	sub    $0xc,%esp
80103321:	68 78 6c 10 80       	push   $0x80106c78
80103326:	e8 1d d0 ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
8010332b:	83 ec 0c             	sub    $0xc,%esp
8010332e:	68 9c 6b 10 80       	push   $0x80106b9c
80103333:	e8 10 d0 ff ff       	call   80100348 <panic>
      return &cpus[i];
80103338:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
8010333e:	05 00 28 13 80       	add    $0x80132800,%eax
}
80103343:	c9                   	leave  
80103344:	c3                   	ret    

80103345 <cpuid>:
cpuid() {
80103345:	55                   	push   %ebp
80103346:	89 e5                	mov    %esp,%ebp
80103348:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
8010334b:	e8 99 ff ff ff       	call   801032e9 <mycpu>
80103350:	2d 00 28 13 80       	sub    $0x80132800,%eax
80103355:	c1 f8 04             	sar    $0x4,%eax
80103358:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
8010335e:	c9                   	leave  
8010335f:	c3                   	ret    

80103360 <myproc>:
myproc(void) {
80103360:	55                   	push   %ebp
80103361:	89 e5                	mov    %esp,%ebp
80103363:	53                   	push   %ebx
80103364:	83 ec 04             	sub    $0x4,%esp
  pushcli();
80103367:	e8 b9 08 00 00       	call   80103c25 <pushcli>
  c = mycpu();
8010336c:	e8 78 ff ff ff       	call   801032e9 <mycpu>
  p = c->proc;
80103371:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103377:	e8 e6 08 00 00       	call   80103c62 <popcli>
}
8010337c:	89 d8                	mov    %ebx,%eax
8010337e:	83 c4 04             	add    $0x4,%esp
80103381:	5b                   	pop    %ebx
80103382:	5d                   	pop    %ebp
80103383:	c3                   	ret    

80103384 <userinit>:
{
80103384:	55                   	push   %ebp
80103385:	89 e5                	mov    %esp,%ebp
80103387:	53                   	push   %ebx
80103388:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
8010338b:	e8 3b fe ff ff       	call   801031cb <allocproc>
80103390:	89 c3                	mov    %eax,%ebx
  initproc = p;
80103392:	a3 bc a5 10 80       	mov    %eax,0x8010a5bc
  if((p->pgdir = setupkvm()) == 0)
80103397:	e8 27 30 00 00       	call   801063c3 <setupkvm>
8010339c:	89 43 04             	mov    %eax,0x4(%ebx)
8010339f:	85 c0                	test   %eax,%eax
801033a1:	0f 84 b7 00 00 00    	je     8010345e <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
801033a7:	83 ec 04             	sub    $0x4,%esp
801033aa:	68 2c 00 00 00       	push   $0x2c
801033af:	68 60 a4 10 80       	push   $0x8010a460
801033b4:	50                   	push   %eax
801033b5:	e8 01 2d 00 00       	call   801060bb <inituvm>
  p->sz = PGSIZE;
801033ba:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
801033c0:	83 c4 0c             	add    $0xc,%esp
801033c3:	6a 4c                	push   $0x4c
801033c5:	6a 00                	push   $0x0
801033c7:	ff 73 18             	pushl  0x18(%ebx)
801033ca:	e8 df 09 00 00       	call   80103dae <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801033cf:	8b 43 18             	mov    0x18(%ebx),%eax
801033d2:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801033d8:	8b 43 18             	mov    0x18(%ebx),%eax
801033db:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
801033e1:	8b 43 18             	mov    0x18(%ebx),%eax
801033e4:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801033e8:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801033ec:	8b 43 18             	mov    0x18(%ebx),%eax
801033ef:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801033f3:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801033f7:	8b 43 18             	mov    0x18(%ebx),%eax
801033fa:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80103401:	8b 43 18             	mov    0x18(%ebx),%eax
80103404:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
8010340b:	8b 43 18             	mov    0x18(%ebx),%eax
8010340e:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
80103415:	8d 43 6c             	lea    0x6c(%ebx),%eax
80103418:	83 c4 0c             	add    $0xc,%esp
8010341b:	6a 10                	push   $0x10
8010341d:	68 c5 6b 10 80       	push   $0x80106bc5
80103422:	50                   	push   %eax
80103423:	e8 ed 0a 00 00       	call   80103f15 <safestrcpy>
  p->cwd = namei("/");
80103428:	c7 04 24 ce 6b 10 80 	movl   $0x80106bce,(%esp)
8010342f:	e8 ad e7 ff ff       	call   80101be1 <namei>
80103434:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
80103437:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
8010343e:	e8 bf 08 00 00       	call   80103d02 <acquire>
  p->state = RUNNABLE;
80103443:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
8010344a:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
80103451:	e8 11 09 00 00       	call   80103d67 <release>
}
80103456:	83 c4 10             	add    $0x10,%esp
80103459:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010345c:	c9                   	leave  
8010345d:	c3                   	ret    
    panic("userinit: out of memory?");
8010345e:	83 ec 0c             	sub    $0xc,%esp
80103461:	68 ac 6b 10 80       	push   $0x80106bac
80103466:	e8 dd ce ff ff       	call   80100348 <panic>

8010346b <growproc>:
{
8010346b:	55                   	push   %ebp
8010346c:	89 e5                	mov    %esp,%ebp
8010346e:	56                   	push   %esi
8010346f:	53                   	push   %ebx
80103470:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
80103473:	e8 e8 fe ff ff       	call   80103360 <myproc>
80103478:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
8010347a:	8b 00                	mov    (%eax),%eax
  if(n > 0){
8010347c:	85 f6                	test   %esi,%esi
8010347e:	7f 21                	jg     801034a1 <growproc+0x36>
  } else if(n < 0){
80103480:	85 f6                	test   %esi,%esi
80103482:	79 33                	jns    801034b7 <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103484:	83 ec 04             	sub    $0x4,%esp
80103487:	01 c6                	add    %eax,%esi
80103489:	56                   	push   %esi
8010348a:	50                   	push   %eax
8010348b:	ff 73 04             	pushl  0x4(%ebx)
8010348e:	e8 36 2d 00 00       	call   801061c9 <deallocuvm>
80103493:	83 c4 10             	add    $0x10,%esp
80103496:	85 c0                	test   %eax,%eax
80103498:	75 1d                	jne    801034b7 <growproc+0x4c>
      return -1;
8010349a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010349f:	eb 29                	jmp    801034ca <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
801034a1:	83 ec 04             	sub    $0x4,%esp
801034a4:	01 c6                	add    %eax,%esi
801034a6:	56                   	push   %esi
801034a7:	50                   	push   %eax
801034a8:	ff 73 04             	pushl  0x4(%ebx)
801034ab:	e8 ab 2d 00 00       	call   8010625b <allocuvm>
801034b0:	83 c4 10             	add    $0x10,%esp
801034b3:	85 c0                	test   %eax,%eax
801034b5:	74 1a                	je     801034d1 <growproc+0x66>
  curproc->sz = sz;
801034b7:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
801034b9:	83 ec 0c             	sub    $0xc,%esp
801034bc:	53                   	push   %ebx
801034bd:	e8 e1 2a 00 00       	call   80105fa3 <switchuvm>
  return 0;
801034c2:	83 c4 10             	add    $0x10,%esp
801034c5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801034ca:	8d 65 f8             	lea    -0x8(%ebp),%esp
801034cd:	5b                   	pop    %ebx
801034ce:	5e                   	pop    %esi
801034cf:	5d                   	pop    %ebp
801034d0:	c3                   	ret    
      return -1;
801034d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801034d6:	eb f2                	jmp    801034ca <growproc+0x5f>

801034d8 <fork>:
{
801034d8:	55                   	push   %ebp
801034d9:	89 e5                	mov    %esp,%ebp
801034db:	57                   	push   %edi
801034dc:	56                   	push   %esi
801034dd:	53                   	push   %ebx
801034de:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
801034e1:	e8 7a fe ff ff       	call   80103360 <myproc>
801034e6:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
801034e8:	e8 de fc ff ff       	call   801031cb <allocproc>
801034ed:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801034f0:	85 c0                	test   %eax,%eax
801034f2:	0f 84 e3 00 00 00    	je     801035db <fork+0x103>
801034f8:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz, np->pid)) == 0){
801034fa:	83 ec 04             	sub    $0x4,%esp
801034fd:	ff 70 10             	pushl  0x10(%eax)
80103500:	ff 33                	pushl  (%ebx)
80103502:	ff 73 04             	pushl  0x4(%ebx)
80103505:	e8 72 2f 00 00       	call   8010647c <copyuvm>
8010350a:	89 47 04             	mov    %eax,0x4(%edi)
8010350d:	83 c4 10             	add    $0x10,%esp
80103510:	85 c0                	test   %eax,%eax
80103512:	74 2a                	je     8010353e <fork+0x66>
  np->sz = curproc->sz;
80103514:	8b 03                	mov    (%ebx),%eax
80103516:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80103519:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
8010351b:	89 c8                	mov    %ecx,%eax
8010351d:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
80103520:	8b 73 18             	mov    0x18(%ebx),%esi
80103523:	8b 79 18             	mov    0x18(%ecx),%edi
80103526:	b9 13 00 00 00       	mov    $0x13,%ecx
8010352b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
8010352d:	8b 40 18             	mov    0x18(%eax),%eax
80103530:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
80103537:	be 00 00 00 00       	mov    $0x0,%esi
8010353c:	eb 29                	jmp    80103567 <fork+0x8f>
    kfree(np->kstack);
8010353e:	83 ec 0c             	sub    $0xc,%esp
80103541:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80103544:	ff 73 08             	pushl  0x8(%ebx)
80103547:	e8 58 ea ff ff       	call   80101fa4 <kfree>
    np->kstack = 0;
8010354c:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
80103553:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
8010355a:	83 c4 10             	add    $0x10,%esp
8010355d:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103562:	eb 6d                	jmp    801035d1 <fork+0xf9>
  for(i = 0; i < NOFILE; i++)
80103564:	83 c6 01             	add    $0x1,%esi
80103567:	83 fe 0f             	cmp    $0xf,%esi
8010356a:	7f 1d                	jg     80103589 <fork+0xb1>
    if(curproc->ofile[i])
8010356c:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
80103570:	85 c0                	test   %eax,%eax
80103572:	74 f0                	je     80103564 <fork+0x8c>
      np->ofile[i] = filedup(curproc->ofile[i]);
80103574:	83 ec 0c             	sub    $0xc,%esp
80103577:	50                   	push   %eax
80103578:	e8 11 d7 ff ff       	call   80100c8e <filedup>
8010357d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103580:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
80103584:	83 c4 10             	add    $0x10,%esp
80103587:	eb db                	jmp    80103564 <fork+0x8c>
  np->cwd = idup(curproc->cwd);
80103589:	83 ec 0c             	sub    $0xc,%esp
8010358c:	ff 73 68             	pushl  0x68(%ebx)
8010358f:	e8 bd df ff ff       	call   80101551 <idup>
80103594:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103597:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
8010359a:	83 c3 6c             	add    $0x6c,%ebx
8010359d:	8d 47 6c             	lea    0x6c(%edi),%eax
801035a0:	83 c4 0c             	add    $0xc,%esp
801035a3:	6a 10                	push   $0x10
801035a5:	53                   	push   %ebx
801035a6:	50                   	push   %eax
801035a7:	e8 69 09 00 00       	call   80103f15 <safestrcpy>
  pid = np->pid;
801035ac:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
801035af:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
801035b6:	e8 47 07 00 00       	call   80103d02 <acquire>
  np->state = RUNNABLE;
801035bb:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
801035c2:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
801035c9:	e8 99 07 00 00       	call   80103d67 <release>
  return pid;
801035ce:	83 c4 10             	add    $0x10,%esp
}
801035d1:	89 d8                	mov    %ebx,%eax
801035d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
801035d6:	5b                   	pop    %ebx
801035d7:	5e                   	pop    %esi
801035d8:	5f                   	pop    %edi
801035d9:	5d                   	pop    %ebp
801035da:	c3                   	ret    
    return -1;
801035db:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801035e0:	eb ef                	jmp    801035d1 <fork+0xf9>

801035e2 <scheduler>:
{
801035e2:	55                   	push   %ebp
801035e3:	89 e5                	mov    %esp,%ebp
801035e5:	56                   	push   %esi
801035e6:	53                   	push   %ebx
  struct cpu *c = mycpu();
801035e7:	e8 fd fc ff ff       	call   801032e9 <mycpu>
801035ec:	89 c6                	mov    %eax,%esi
  c->proc = 0;
801035ee:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
801035f5:	00 00 00 
801035f8:	eb 5a                	jmp    80103654 <scheduler+0x72>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801035fa:	83 c3 7c             	add    $0x7c,%ebx
801035fd:	81 fb d4 4c 13 80    	cmp    $0x80134cd4,%ebx
80103603:	73 3f                	jae    80103644 <scheduler+0x62>
      if(p->state != RUNNABLE)
80103605:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
80103609:	75 ef                	jne    801035fa <scheduler+0x18>
      c->proc = p;
8010360b:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
80103611:	83 ec 0c             	sub    $0xc,%esp
80103614:	53                   	push   %ebx
80103615:	e8 89 29 00 00       	call   80105fa3 <switchuvm>
      p->state = RUNNING;
8010361a:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
80103621:	83 c4 08             	add    $0x8,%esp
80103624:	ff 73 1c             	pushl  0x1c(%ebx)
80103627:	8d 46 04             	lea    0x4(%esi),%eax
8010362a:	50                   	push   %eax
8010362b:	e8 38 09 00 00       	call   80103f68 <swtch>
      switchkvm();
80103630:	e8 5c 29 00 00       	call   80105f91 <switchkvm>
      c->proc = 0;
80103635:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
8010363c:	00 00 00 
8010363f:	83 c4 10             	add    $0x10,%esp
80103642:	eb b6                	jmp    801035fa <scheduler+0x18>
    release(&ptable.lock);
80103644:	83 ec 0c             	sub    $0xc,%esp
80103647:	68 a0 2d 13 80       	push   $0x80132da0
8010364c:	e8 16 07 00 00       	call   80103d67 <release>
    sti();
80103651:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
80103654:	fb                   	sti    
    acquire(&ptable.lock);
80103655:	83 ec 0c             	sub    $0xc,%esp
80103658:	68 a0 2d 13 80       	push   $0x80132da0
8010365d:	e8 a0 06 00 00       	call   80103d02 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103662:	83 c4 10             	add    $0x10,%esp
80103665:	bb d4 2d 13 80       	mov    $0x80132dd4,%ebx
8010366a:	eb 91                	jmp    801035fd <scheduler+0x1b>

8010366c <sched>:
{
8010366c:	55                   	push   %ebp
8010366d:	89 e5                	mov    %esp,%ebp
8010366f:	56                   	push   %esi
80103670:	53                   	push   %ebx
  struct proc *p = myproc();
80103671:	e8 ea fc ff ff       	call   80103360 <myproc>
80103676:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
80103678:	83 ec 0c             	sub    $0xc,%esp
8010367b:	68 a0 2d 13 80       	push   $0x80132da0
80103680:	e8 3d 06 00 00       	call   80103cc2 <holding>
80103685:	83 c4 10             	add    $0x10,%esp
80103688:	85 c0                	test   %eax,%eax
8010368a:	74 4f                	je     801036db <sched+0x6f>
  if(mycpu()->ncli != 1)
8010368c:	e8 58 fc ff ff       	call   801032e9 <mycpu>
80103691:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
80103698:	75 4e                	jne    801036e8 <sched+0x7c>
  if(p->state == RUNNING)
8010369a:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
8010369e:	74 55                	je     801036f5 <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801036a0:	9c                   	pushf  
801036a1:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801036a2:	f6 c4 02             	test   $0x2,%ah
801036a5:	75 5b                	jne    80103702 <sched+0x96>
  intena = mycpu()->intena;
801036a7:	e8 3d fc ff ff       	call   801032e9 <mycpu>
801036ac:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
801036b2:	e8 32 fc ff ff       	call   801032e9 <mycpu>
801036b7:	83 ec 08             	sub    $0x8,%esp
801036ba:	ff 70 04             	pushl  0x4(%eax)
801036bd:	83 c3 1c             	add    $0x1c,%ebx
801036c0:	53                   	push   %ebx
801036c1:	e8 a2 08 00 00       	call   80103f68 <swtch>
  mycpu()->intena = intena;
801036c6:	e8 1e fc ff ff       	call   801032e9 <mycpu>
801036cb:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
801036d1:	83 c4 10             	add    $0x10,%esp
801036d4:	8d 65 f8             	lea    -0x8(%ebp),%esp
801036d7:	5b                   	pop    %ebx
801036d8:	5e                   	pop    %esi
801036d9:	5d                   	pop    %ebp
801036da:	c3                   	ret    
    panic("sched ptable.lock");
801036db:	83 ec 0c             	sub    $0xc,%esp
801036de:	68 d0 6b 10 80       	push   $0x80106bd0
801036e3:	e8 60 cc ff ff       	call   80100348 <panic>
    panic("sched locks");
801036e8:	83 ec 0c             	sub    $0xc,%esp
801036eb:	68 e2 6b 10 80       	push   $0x80106be2
801036f0:	e8 53 cc ff ff       	call   80100348 <panic>
    panic("sched running");
801036f5:	83 ec 0c             	sub    $0xc,%esp
801036f8:	68 ee 6b 10 80       	push   $0x80106bee
801036fd:	e8 46 cc ff ff       	call   80100348 <panic>
    panic("sched interruptible");
80103702:	83 ec 0c             	sub    $0xc,%esp
80103705:	68 fc 6b 10 80       	push   $0x80106bfc
8010370a:	e8 39 cc ff ff       	call   80100348 <panic>

8010370f <exit>:
{
8010370f:	55                   	push   %ebp
80103710:	89 e5                	mov    %esp,%ebp
80103712:	56                   	push   %esi
80103713:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103714:	e8 47 fc ff ff       	call   80103360 <myproc>
  if(curproc == initproc)
80103719:	39 05 bc a5 10 80    	cmp    %eax,0x8010a5bc
8010371f:	74 09                	je     8010372a <exit+0x1b>
80103721:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
80103723:	bb 00 00 00 00       	mov    $0x0,%ebx
80103728:	eb 10                	jmp    8010373a <exit+0x2b>
    panic("init exiting");
8010372a:	83 ec 0c             	sub    $0xc,%esp
8010372d:	68 10 6c 10 80       	push   $0x80106c10
80103732:	e8 11 cc ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
80103737:	83 c3 01             	add    $0x1,%ebx
8010373a:	83 fb 0f             	cmp    $0xf,%ebx
8010373d:	7f 1e                	jg     8010375d <exit+0x4e>
    if(curproc->ofile[fd]){
8010373f:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
80103743:	85 c0                	test   %eax,%eax
80103745:	74 f0                	je     80103737 <exit+0x28>
      fileclose(curproc->ofile[fd]);
80103747:	83 ec 0c             	sub    $0xc,%esp
8010374a:	50                   	push   %eax
8010374b:	e8 83 d5 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
80103750:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
80103757:	00 
80103758:	83 c4 10             	add    $0x10,%esp
8010375b:	eb da                	jmp    80103737 <exit+0x28>
  begin_op();
8010375d:	e8 ae f1 ff ff       	call   80102910 <begin_op>
  iput(curproc->cwd);
80103762:	83 ec 0c             	sub    $0xc,%esp
80103765:	ff 76 68             	pushl  0x68(%esi)
80103768:	e8 1b df ff ff       	call   80101688 <iput>
  end_op();
8010376d:	e8 18 f2 ff ff       	call   8010298a <end_op>
  curproc->cwd = 0;
80103772:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
80103779:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
80103780:	e8 7d 05 00 00       	call   80103d02 <acquire>
  wakeup1(curproc->parent);
80103785:	8b 46 14             	mov    0x14(%esi),%eax
80103788:	e8 13 fa ff ff       	call   801031a0 <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010378d:	83 c4 10             	add    $0x10,%esp
80103790:	bb d4 2d 13 80       	mov    $0x80132dd4,%ebx
80103795:	eb 03                	jmp    8010379a <exit+0x8b>
80103797:	83 c3 7c             	add    $0x7c,%ebx
8010379a:	81 fb d4 4c 13 80    	cmp    $0x80134cd4,%ebx
801037a0:	73 1a                	jae    801037bc <exit+0xad>
    if(p->parent == curproc){
801037a2:	39 73 14             	cmp    %esi,0x14(%ebx)
801037a5:	75 f0                	jne    80103797 <exit+0x88>
      p->parent = initproc;
801037a7:	a1 bc a5 10 80       	mov    0x8010a5bc,%eax
801037ac:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
801037af:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
801037b3:	75 e2                	jne    80103797 <exit+0x88>
        wakeup1(initproc);
801037b5:	e8 e6 f9 ff ff       	call   801031a0 <wakeup1>
801037ba:	eb db                	jmp    80103797 <exit+0x88>
  curproc->state = ZOMBIE;
801037bc:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
801037c3:	e8 a4 fe ff ff       	call   8010366c <sched>
  panic("zombie exit");
801037c8:	83 ec 0c             	sub    $0xc,%esp
801037cb:	68 1d 6c 10 80       	push   $0x80106c1d
801037d0:	e8 73 cb ff ff       	call   80100348 <panic>

801037d5 <yield>:
{
801037d5:	55                   	push   %ebp
801037d6:	89 e5                	mov    %esp,%ebp
801037d8:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801037db:	68 a0 2d 13 80       	push   $0x80132da0
801037e0:	e8 1d 05 00 00       	call   80103d02 <acquire>
  myproc()->state = RUNNABLE;
801037e5:	e8 76 fb ff ff       	call   80103360 <myproc>
801037ea:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801037f1:	e8 76 fe ff ff       	call   8010366c <sched>
  release(&ptable.lock);
801037f6:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
801037fd:	e8 65 05 00 00       	call   80103d67 <release>
}
80103802:	83 c4 10             	add    $0x10,%esp
80103805:	c9                   	leave  
80103806:	c3                   	ret    

80103807 <sleep>:
{
80103807:	55                   	push   %ebp
80103808:	89 e5                	mov    %esp,%ebp
8010380a:	56                   	push   %esi
8010380b:	53                   	push   %ebx
8010380c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
8010380f:	e8 4c fb ff ff       	call   80103360 <myproc>
  if(p == 0)
80103814:	85 c0                	test   %eax,%eax
80103816:	74 66                	je     8010387e <sleep+0x77>
80103818:	89 c6                	mov    %eax,%esi
  if(lk == 0)
8010381a:	85 db                	test   %ebx,%ebx
8010381c:	74 6d                	je     8010388b <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
8010381e:	81 fb a0 2d 13 80    	cmp    $0x80132da0,%ebx
80103824:	74 18                	je     8010383e <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
80103826:	83 ec 0c             	sub    $0xc,%esp
80103829:	68 a0 2d 13 80       	push   $0x80132da0
8010382e:	e8 cf 04 00 00       	call   80103d02 <acquire>
    release(lk);
80103833:	89 1c 24             	mov    %ebx,(%esp)
80103836:	e8 2c 05 00 00       	call   80103d67 <release>
8010383b:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
8010383e:	8b 45 08             	mov    0x8(%ebp),%eax
80103841:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
80103844:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
8010384b:	e8 1c fe ff ff       	call   8010366c <sched>
  p->chan = 0;
80103850:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
80103857:	81 fb a0 2d 13 80    	cmp    $0x80132da0,%ebx
8010385d:	74 18                	je     80103877 <sleep+0x70>
    release(&ptable.lock);
8010385f:	83 ec 0c             	sub    $0xc,%esp
80103862:	68 a0 2d 13 80       	push   $0x80132da0
80103867:	e8 fb 04 00 00       	call   80103d67 <release>
    acquire(lk);
8010386c:	89 1c 24             	mov    %ebx,(%esp)
8010386f:	e8 8e 04 00 00       	call   80103d02 <acquire>
80103874:	83 c4 10             	add    $0x10,%esp
}
80103877:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010387a:	5b                   	pop    %ebx
8010387b:	5e                   	pop    %esi
8010387c:	5d                   	pop    %ebp
8010387d:	c3                   	ret    
    panic("sleep");
8010387e:	83 ec 0c             	sub    $0xc,%esp
80103881:	68 29 6c 10 80       	push   $0x80106c29
80103886:	e8 bd ca ff ff       	call   80100348 <panic>
    panic("sleep without lk");
8010388b:	83 ec 0c             	sub    $0xc,%esp
8010388e:	68 2f 6c 10 80       	push   $0x80106c2f
80103893:	e8 b0 ca ff ff       	call   80100348 <panic>

80103898 <wait>:
{
80103898:	55                   	push   %ebp
80103899:	89 e5                	mov    %esp,%ebp
8010389b:	56                   	push   %esi
8010389c:	53                   	push   %ebx
  struct proc *curproc = myproc();
8010389d:	e8 be fa ff ff       	call   80103360 <myproc>
801038a2:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
801038a4:	83 ec 0c             	sub    $0xc,%esp
801038a7:	68 a0 2d 13 80       	push   $0x80132da0
801038ac:	e8 51 04 00 00       	call   80103d02 <acquire>
801038b1:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
801038b4:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801038b9:	bb d4 2d 13 80       	mov    $0x80132dd4,%ebx
801038be:	eb 5b                	jmp    8010391b <wait+0x83>
        pid = p->pid;
801038c0:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
801038c3:	83 ec 0c             	sub    $0xc,%esp
801038c6:	ff 73 08             	pushl  0x8(%ebx)
801038c9:	e8 d6 e6 ff ff       	call   80101fa4 <kfree>
        p->kstack = 0;
801038ce:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
801038d5:	83 c4 04             	add    $0x4,%esp
801038d8:	ff 73 04             	pushl  0x4(%ebx)
801038db:	e8 73 2a 00 00       	call   80106353 <freevm>
        p->pid = 0;
801038e0:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
801038e7:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
801038ee:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
801038f2:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
801038f9:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
80103900:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
80103907:	e8 5b 04 00 00       	call   80103d67 <release>
        return pid;
8010390c:	83 c4 10             	add    $0x10,%esp
}
8010390f:	89 f0                	mov    %esi,%eax
80103911:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103914:	5b                   	pop    %ebx
80103915:	5e                   	pop    %esi
80103916:	5d                   	pop    %ebp
80103917:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103918:	83 c3 7c             	add    $0x7c,%ebx
8010391b:	81 fb d4 4c 13 80    	cmp    $0x80134cd4,%ebx
80103921:	73 12                	jae    80103935 <wait+0x9d>
      if(p->parent != curproc)
80103923:	39 73 14             	cmp    %esi,0x14(%ebx)
80103926:	75 f0                	jne    80103918 <wait+0x80>
      if(p->state == ZOMBIE){
80103928:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
8010392c:	74 92                	je     801038c0 <wait+0x28>
      havekids = 1;
8010392e:	b8 01 00 00 00       	mov    $0x1,%eax
80103933:	eb e3                	jmp    80103918 <wait+0x80>
    if(!havekids || curproc->killed){
80103935:	85 c0                	test   %eax,%eax
80103937:	74 06                	je     8010393f <wait+0xa7>
80103939:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
8010393d:	74 17                	je     80103956 <wait+0xbe>
      release(&ptable.lock);
8010393f:	83 ec 0c             	sub    $0xc,%esp
80103942:	68 a0 2d 13 80       	push   $0x80132da0
80103947:	e8 1b 04 00 00       	call   80103d67 <release>
      return -1;
8010394c:	83 c4 10             	add    $0x10,%esp
8010394f:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103954:	eb b9                	jmp    8010390f <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80103956:	83 ec 08             	sub    $0x8,%esp
80103959:	68 a0 2d 13 80       	push   $0x80132da0
8010395e:	56                   	push   %esi
8010395f:	e8 a3 fe ff ff       	call   80103807 <sleep>
    havekids = 0;
80103964:	83 c4 10             	add    $0x10,%esp
80103967:	e9 48 ff ff ff       	jmp    801038b4 <wait+0x1c>

8010396c <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
8010396c:	55                   	push   %ebp
8010396d:	89 e5                	mov    %esp,%ebp
8010396f:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
80103972:	68 a0 2d 13 80       	push   $0x80132da0
80103977:	e8 86 03 00 00       	call   80103d02 <acquire>
  wakeup1(chan);
8010397c:	8b 45 08             	mov    0x8(%ebp),%eax
8010397f:	e8 1c f8 ff ff       	call   801031a0 <wakeup1>
  release(&ptable.lock);
80103984:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
8010398b:	e8 d7 03 00 00       	call   80103d67 <release>
}
80103990:	83 c4 10             	add    $0x10,%esp
80103993:	c9                   	leave  
80103994:	c3                   	ret    

80103995 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80103995:	55                   	push   %ebp
80103996:	89 e5                	mov    %esp,%ebp
80103998:	53                   	push   %ebx
80103999:	83 ec 10             	sub    $0x10,%esp
8010399c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
8010399f:	68 a0 2d 13 80       	push   $0x80132da0
801039a4:	e8 59 03 00 00       	call   80103d02 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039a9:	83 c4 10             	add    $0x10,%esp
801039ac:	b8 d4 2d 13 80       	mov    $0x80132dd4,%eax
801039b1:	3d d4 4c 13 80       	cmp    $0x80134cd4,%eax
801039b6:	73 3a                	jae    801039f2 <kill+0x5d>
    if(p->pid == pid){
801039b8:	39 58 10             	cmp    %ebx,0x10(%eax)
801039bb:	74 05                	je     801039c2 <kill+0x2d>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039bd:	83 c0 7c             	add    $0x7c,%eax
801039c0:	eb ef                	jmp    801039b1 <kill+0x1c>
      p->killed = 1;
801039c2:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
801039c9:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
801039cd:	74 1a                	je     801039e9 <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
801039cf:	83 ec 0c             	sub    $0xc,%esp
801039d2:	68 a0 2d 13 80       	push   $0x80132da0
801039d7:	e8 8b 03 00 00       	call   80103d67 <release>
      return 0;
801039dc:	83 c4 10             	add    $0x10,%esp
801039df:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
801039e4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801039e7:	c9                   	leave  
801039e8:	c3                   	ret    
        p->state = RUNNABLE;
801039e9:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
801039f0:	eb dd                	jmp    801039cf <kill+0x3a>
  release(&ptable.lock);
801039f2:	83 ec 0c             	sub    $0xc,%esp
801039f5:	68 a0 2d 13 80       	push   $0x80132da0
801039fa:	e8 68 03 00 00       	call   80103d67 <release>
  return -1;
801039ff:	83 c4 10             	add    $0x10,%esp
80103a02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103a07:	eb db                	jmp    801039e4 <kill+0x4f>

80103a09 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80103a09:	55                   	push   %ebp
80103a0a:	89 e5                	mov    %esp,%ebp
80103a0c:	56                   	push   %esi
80103a0d:	53                   	push   %ebx
80103a0e:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103a11:	bb d4 2d 13 80       	mov    $0x80132dd4,%ebx
80103a16:	eb 33                	jmp    80103a4b <procdump+0x42>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103a18:	b8 40 6c 10 80       	mov    $0x80106c40,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
80103a1d:	8d 53 6c             	lea    0x6c(%ebx),%edx
80103a20:	52                   	push   %edx
80103a21:	50                   	push   %eax
80103a22:	ff 73 10             	pushl  0x10(%ebx)
80103a25:	68 44 6c 10 80       	push   $0x80106c44
80103a2a:	e8 dc cb ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
80103a2f:	83 c4 10             	add    $0x10,%esp
80103a32:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103a36:	74 39                	je     80103a71 <procdump+0x68>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103a38:	83 ec 0c             	sub    $0xc,%esp
80103a3b:	68 bb 6f 10 80       	push   $0x80106fbb
80103a40:	e8 c6 cb ff ff       	call   8010060b <cprintf>
80103a45:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103a48:	83 c3 7c             	add    $0x7c,%ebx
80103a4b:	81 fb d4 4c 13 80    	cmp    $0x80134cd4,%ebx
80103a51:	73 61                	jae    80103ab4 <procdump+0xab>
    if(p->state == UNUSED)
80103a53:	8b 43 0c             	mov    0xc(%ebx),%eax
80103a56:	85 c0                	test   %eax,%eax
80103a58:	74 ee                	je     80103a48 <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103a5a:	83 f8 05             	cmp    $0x5,%eax
80103a5d:	77 b9                	ja     80103a18 <procdump+0xf>
80103a5f:	8b 04 85 a0 6c 10 80 	mov    -0x7fef9360(,%eax,4),%eax
80103a66:	85 c0                	test   %eax,%eax
80103a68:	75 b3                	jne    80103a1d <procdump+0x14>
      state = "???";
80103a6a:	b8 40 6c 10 80       	mov    $0x80106c40,%eax
80103a6f:	eb ac                	jmp    80103a1d <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80103a71:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103a74:	8b 40 0c             	mov    0xc(%eax),%eax
80103a77:	83 c0 08             	add    $0x8,%eax
80103a7a:	83 ec 08             	sub    $0x8,%esp
80103a7d:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103a80:	52                   	push   %edx
80103a81:	50                   	push   %eax
80103a82:	e8 5a 01 00 00       	call   80103be1 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103a87:	83 c4 10             	add    $0x10,%esp
80103a8a:	be 00 00 00 00       	mov    $0x0,%esi
80103a8f:	eb 14                	jmp    80103aa5 <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103a91:	83 ec 08             	sub    $0x8,%esp
80103a94:	50                   	push   %eax
80103a95:	68 81 66 10 80       	push   $0x80106681
80103a9a:	e8 6c cb ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103a9f:	83 c6 01             	add    $0x1,%esi
80103aa2:	83 c4 10             	add    $0x10,%esp
80103aa5:	83 fe 09             	cmp    $0x9,%esi
80103aa8:	7f 8e                	jg     80103a38 <procdump+0x2f>
80103aaa:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103aae:	85 c0                	test   %eax,%eax
80103ab0:	75 df                	jne    80103a91 <procdump+0x88>
80103ab2:	eb 84                	jmp    80103a38 <procdump+0x2f>
  }
80103ab4:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103ab7:	5b                   	pop    %ebx
80103ab8:	5e                   	pop    %esi
80103ab9:	5d                   	pop    %ebp
80103aba:	c3                   	ret    

80103abb <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103abb:	55                   	push   %ebp
80103abc:	89 e5                	mov    %esp,%ebp
80103abe:	53                   	push   %ebx
80103abf:	83 ec 0c             	sub    $0xc,%esp
80103ac2:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103ac5:	68 b8 6c 10 80       	push   $0x80106cb8
80103aca:	8d 43 04             	lea    0x4(%ebx),%eax
80103acd:	50                   	push   %eax
80103ace:	e8 f3 00 00 00       	call   80103bc6 <initlock>
  lk->name = name;
80103ad3:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ad6:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103ad9:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103adf:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103ae6:	83 c4 10             	add    $0x10,%esp
80103ae9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103aec:	c9                   	leave  
80103aed:	c3                   	ret    

80103aee <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103aee:	55                   	push   %ebp
80103aef:	89 e5                	mov    %esp,%ebp
80103af1:	56                   	push   %esi
80103af2:	53                   	push   %ebx
80103af3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103af6:	8d 73 04             	lea    0x4(%ebx),%esi
80103af9:	83 ec 0c             	sub    $0xc,%esp
80103afc:	56                   	push   %esi
80103afd:	e8 00 02 00 00       	call   80103d02 <acquire>
  while (lk->locked) {
80103b02:	83 c4 10             	add    $0x10,%esp
80103b05:	eb 0d                	jmp    80103b14 <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103b07:	83 ec 08             	sub    $0x8,%esp
80103b0a:	56                   	push   %esi
80103b0b:	53                   	push   %ebx
80103b0c:	e8 f6 fc ff ff       	call   80103807 <sleep>
80103b11:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103b14:	83 3b 00             	cmpl   $0x0,(%ebx)
80103b17:	75 ee                	jne    80103b07 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103b19:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103b1f:	e8 3c f8 ff ff       	call   80103360 <myproc>
80103b24:	8b 40 10             	mov    0x10(%eax),%eax
80103b27:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103b2a:	83 ec 0c             	sub    $0xc,%esp
80103b2d:	56                   	push   %esi
80103b2e:	e8 34 02 00 00       	call   80103d67 <release>
}
80103b33:	83 c4 10             	add    $0x10,%esp
80103b36:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b39:	5b                   	pop    %ebx
80103b3a:	5e                   	pop    %esi
80103b3b:	5d                   	pop    %ebp
80103b3c:	c3                   	ret    

80103b3d <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103b3d:	55                   	push   %ebp
80103b3e:	89 e5                	mov    %esp,%ebp
80103b40:	56                   	push   %esi
80103b41:	53                   	push   %ebx
80103b42:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103b45:	8d 73 04             	lea    0x4(%ebx),%esi
80103b48:	83 ec 0c             	sub    $0xc,%esp
80103b4b:	56                   	push   %esi
80103b4c:	e8 b1 01 00 00       	call   80103d02 <acquire>
  lk->locked = 0;
80103b51:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103b57:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103b5e:	89 1c 24             	mov    %ebx,(%esp)
80103b61:	e8 06 fe ff ff       	call   8010396c <wakeup>
  release(&lk->lk);
80103b66:	89 34 24             	mov    %esi,(%esp)
80103b69:	e8 f9 01 00 00       	call   80103d67 <release>
}
80103b6e:	83 c4 10             	add    $0x10,%esp
80103b71:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b74:	5b                   	pop    %ebx
80103b75:	5e                   	pop    %esi
80103b76:	5d                   	pop    %ebp
80103b77:	c3                   	ret    

80103b78 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103b78:	55                   	push   %ebp
80103b79:	89 e5                	mov    %esp,%ebp
80103b7b:	56                   	push   %esi
80103b7c:	53                   	push   %ebx
80103b7d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103b80:	8d 73 04             	lea    0x4(%ebx),%esi
80103b83:	83 ec 0c             	sub    $0xc,%esp
80103b86:	56                   	push   %esi
80103b87:	e8 76 01 00 00       	call   80103d02 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103b8c:	83 c4 10             	add    $0x10,%esp
80103b8f:	83 3b 00             	cmpl   $0x0,(%ebx)
80103b92:	75 17                	jne    80103bab <holdingsleep+0x33>
80103b94:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103b99:	83 ec 0c             	sub    $0xc,%esp
80103b9c:	56                   	push   %esi
80103b9d:	e8 c5 01 00 00       	call   80103d67 <release>
  return r;
}
80103ba2:	89 d8                	mov    %ebx,%eax
80103ba4:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103ba7:	5b                   	pop    %ebx
80103ba8:	5e                   	pop    %esi
80103ba9:	5d                   	pop    %ebp
80103baa:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103bab:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103bae:	e8 ad f7 ff ff       	call   80103360 <myproc>
80103bb3:	3b 58 10             	cmp    0x10(%eax),%ebx
80103bb6:	74 07                	je     80103bbf <holdingsleep+0x47>
80103bb8:	bb 00 00 00 00       	mov    $0x0,%ebx
80103bbd:	eb da                	jmp    80103b99 <holdingsleep+0x21>
80103bbf:	bb 01 00 00 00       	mov    $0x1,%ebx
80103bc4:	eb d3                	jmp    80103b99 <holdingsleep+0x21>

80103bc6 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103bc6:	55                   	push   %ebp
80103bc7:	89 e5                	mov    %esp,%ebp
80103bc9:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103bcc:	8b 55 0c             	mov    0xc(%ebp),%edx
80103bcf:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103bd2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103bd8:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103bdf:	5d                   	pop    %ebp
80103be0:	c3                   	ret    

80103be1 <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103be1:	55                   	push   %ebp
80103be2:	89 e5                	mov    %esp,%ebp
80103be4:	53                   	push   %ebx
80103be5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103be8:	8b 45 08             	mov    0x8(%ebp),%eax
80103beb:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103bee:	b8 00 00 00 00       	mov    $0x0,%eax
80103bf3:	83 f8 09             	cmp    $0x9,%eax
80103bf6:	7f 25                	jg     80103c1d <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103bf8:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103bfe:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103c04:	77 17                	ja     80103c1d <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103c06:	8b 5a 04             	mov    0x4(%edx),%ebx
80103c09:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103c0c:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103c0e:	83 c0 01             	add    $0x1,%eax
80103c11:	eb e0                	jmp    80103bf3 <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103c13:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103c1a:	83 c0 01             	add    $0x1,%eax
80103c1d:	83 f8 09             	cmp    $0x9,%eax
80103c20:	7e f1                	jle    80103c13 <getcallerpcs+0x32>
}
80103c22:	5b                   	pop    %ebx
80103c23:	5d                   	pop    %ebp
80103c24:	c3                   	ret    

80103c25 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103c25:	55                   	push   %ebp
80103c26:	89 e5                	mov    %esp,%ebp
80103c28:	53                   	push   %ebx
80103c29:	83 ec 04             	sub    $0x4,%esp
80103c2c:	9c                   	pushf  
80103c2d:	5b                   	pop    %ebx
  asm volatile("cli");
80103c2e:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103c2f:	e8 b5 f6 ff ff       	call   801032e9 <mycpu>
80103c34:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103c3b:	74 12                	je     80103c4f <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103c3d:	e8 a7 f6 ff ff       	call   801032e9 <mycpu>
80103c42:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103c49:	83 c4 04             	add    $0x4,%esp
80103c4c:	5b                   	pop    %ebx
80103c4d:	5d                   	pop    %ebp
80103c4e:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103c4f:	e8 95 f6 ff ff       	call   801032e9 <mycpu>
80103c54:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103c5a:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103c60:	eb db                	jmp    80103c3d <pushcli+0x18>

80103c62 <popcli>:

void
popcli(void)
{
80103c62:	55                   	push   %ebp
80103c63:	89 e5                	mov    %esp,%ebp
80103c65:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103c68:	9c                   	pushf  
80103c69:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103c6a:	f6 c4 02             	test   $0x2,%ah
80103c6d:	75 28                	jne    80103c97 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103c6f:	e8 75 f6 ff ff       	call   801032e9 <mycpu>
80103c74:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103c7a:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103c7d:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103c83:	85 d2                	test   %edx,%edx
80103c85:	78 1d                	js     80103ca4 <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103c87:	e8 5d f6 ff ff       	call   801032e9 <mycpu>
80103c8c:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103c93:	74 1c                	je     80103cb1 <popcli+0x4f>
    sti();
}
80103c95:	c9                   	leave  
80103c96:	c3                   	ret    
    panic("popcli - interruptible");
80103c97:	83 ec 0c             	sub    $0xc,%esp
80103c9a:	68 c3 6c 10 80       	push   $0x80106cc3
80103c9f:	e8 a4 c6 ff ff       	call   80100348 <panic>
    panic("popcli");
80103ca4:	83 ec 0c             	sub    $0xc,%esp
80103ca7:	68 da 6c 10 80       	push   $0x80106cda
80103cac:	e8 97 c6 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103cb1:	e8 33 f6 ff ff       	call   801032e9 <mycpu>
80103cb6:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103cbd:	74 d6                	je     80103c95 <popcli+0x33>
  asm volatile("sti");
80103cbf:	fb                   	sti    
}
80103cc0:	eb d3                	jmp    80103c95 <popcli+0x33>

80103cc2 <holding>:
{
80103cc2:	55                   	push   %ebp
80103cc3:	89 e5                	mov    %esp,%ebp
80103cc5:	53                   	push   %ebx
80103cc6:	83 ec 04             	sub    $0x4,%esp
80103cc9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103ccc:	e8 54 ff ff ff       	call   80103c25 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103cd1:	83 3b 00             	cmpl   $0x0,(%ebx)
80103cd4:	75 12                	jne    80103ce8 <holding+0x26>
80103cd6:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103cdb:	e8 82 ff ff ff       	call   80103c62 <popcli>
}
80103ce0:	89 d8                	mov    %ebx,%eax
80103ce2:	83 c4 04             	add    $0x4,%esp
80103ce5:	5b                   	pop    %ebx
80103ce6:	5d                   	pop    %ebp
80103ce7:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103ce8:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103ceb:	e8 f9 f5 ff ff       	call   801032e9 <mycpu>
80103cf0:	39 c3                	cmp    %eax,%ebx
80103cf2:	74 07                	je     80103cfb <holding+0x39>
80103cf4:	bb 00 00 00 00       	mov    $0x0,%ebx
80103cf9:	eb e0                	jmp    80103cdb <holding+0x19>
80103cfb:	bb 01 00 00 00       	mov    $0x1,%ebx
80103d00:	eb d9                	jmp    80103cdb <holding+0x19>

80103d02 <acquire>:
{
80103d02:	55                   	push   %ebp
80103d03:	89 e5                	mov    %esp,%ebp
80103d05:	53                   	push   %ebx
80103d06:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103d09:	e8 17 ff ff ff       	call   80103c25 <pushcli>
  if(holding(lk))
80103d0e:	83 ec 0c             	sub    $0xc,%esp
80103d11:	ff 75 08             	pushl  0x8(%ebp)
80103d14:	e8 a9 ff ff ff       	call   80103cc2 <holding>
80103d19:	83 c4 10             	add    $0x10,%esp
80103d1c:	85 c0                	test   %eax,%eax
80103d1e:	75 3a                	jne    80103d5a <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103d20:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103d23:	b8 01 00 00 00       	mov    $0x1,%eax
80103d28:	f0 87 02             	lock xchg %eax,(%edx)
80103d2b:	85 c0                	test   %eax,%eax
80103d2d:	75 f1                	jne    80103d20 <acquire+0x1e>
  __sync_synchronize();
80103d2f:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103d34:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103d37:	e8 ad f5 ff ff       	call   801032e9 <mycpu>
80103d3c:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103d3f:	8b 45 08             	mov    0x8(%ebp),%eax
80103d42:	83 c0 0c             	add    $0xc,%eax
80103d45:	83 ec 08             	sub    $0x8,%esp
80103d48:	50                   	push   %eax
80103d49:	8d 45 08             	lea    0x8(%ebp),%eax
80103d4c:	50                   	push   %eax
80103d4d:	e8 8f fe ff ff       	call   80103be1 <getcallerpcs>
}
80103d52:	83 c4 10             	add    $0x10,%esp
80103d55:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103d58:	c9                   	leave  
80103d59:	c3                   	ret    
    panic("acquire");
80103d5a:	83 ec 0c             	sub    $0xc,%esp
80103d5d:	68 e1 6c 10 80       	push   $0x80106ce1
80103d62:	e8 e1 c5 ff ff       	call   80100348 <panic>

80103d67 <release>:
{
80103d67:	55                   	push   %ebp
80103d68:	89 e5                	mov    %esp,%ebp
80103d6a:	53                   	push   %ebx
80103d6b:	83 ec 10             	sub    $0x10,%esp
80103d6e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103d71:	53                   	push   %ebx
80103d72:	e8 4b ff ff ff       	call   80103cc2 <holding>
80103d77:	83 c4 10             	add    $0x10,%esp
80103d7a:	85 c0                	test   %eax,%eax
80103d7c:	74 23                	je     80103da1 <release+0x3a>
  lk->pcs[0] = 0;
80103d7e:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103d85:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103d8c:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103d91:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103d97:	e8 c6 fe ff ff       	call   80103c62 <popcli>
}
80103d9c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103d9f:	c9                   	leave  
80103da0:	c3                   	ret    
    panic("release");
80103da1:	83 ec 0c             	sub    $0xc,%esp
80103da4:	68 e9 6c 10 80       	push   $0x80106ce9
80103da9:	e8 9a c5 ff ff       	call   80100348 <panic>

80103dae <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103dae:	55                   	push   %ebp
80103daf:	89 e5                	mov    %esp,%ebp
80103db1:	57                   	push   %edi
80103db2:	53                   	push   %ebx
80103db3:	8b 55 08             	mov    0x8(%ebp),%edx
80103db6:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103db9:	f6 c2 03             	test   $0x3,%dl
80103dbc:	75 05                	jne    80103dc3 <memset+0x15>
80103dbe:	f6 c1 03             	test   $0x3,%cl
80103dc1:	74 0e                	je     80103dd1 <memset+0x23>
  asm volatile("cld; rep stosb" :
80103dc3:	89 d7                	mov    %edx,%edi
80103dc5:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dc8:	fc                   	cld    
80103dc9:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103dcb:	89 d0                	mov    %edx,%eax
80103dcd:	5b                   	pop    %ebx
80103dce:	5f                   	pop    %edi
80103dcf:	5d                   	pop    %ebp
80103dd0:	c3                   	ret    
    c &= 0xFF;
80103dd1:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103dd5:	c1 e9 02             	shr    $0x2,%ecx
80103dd8:	89 f8                	mov    %edi,%eax
80103dda:	c1 e0 18             	shl    $0x18,%eax
80103ddd:	89 fb                	mov    %edi,%ebx
80103ddf:	c1 e3 10             	shl    $0x10,%ebx
80103de2:	09 d8                	or     %ebx,%eax
80103de4:	89 fb                	mov    %edi,%ebx
80103de6:	c1 e3 08             	shl    $0x8,%ebx
80103de9:	09 d8                	or     %ebx,%eax
80103deb:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103ded:	89 d7                	mov    %edx,%edi
80103def:	fc                   	cld    
80103df0:	f3 ab                	rep stos %eax,%es:(%edi)
80103df2:	eb d7                	jmp    80103dcb <memset+0x1d>

80103df4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103df4:	55                   	push   %ebp
80103df5:	89 e5                	mov    %esp,%ebp
80103df7:	56                   	push   %esi
80103df8:	53                   	push   %ebx
80103df9:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103dfc:	8b 55 0c             	mov    0xc(%ebp),%edx
80103dff:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103e02:	8d 70 ff             	lea    -0x1(%eax),%esi
80103e05:	85 c0                	test   %eax,%eax
80103e07:	74 1c                	je     80103e25 <memcmp+0x31>
    if(*s1 != *s2)
80103e09:	0f b6 01             	movzbl (%ecx),%eax
80103e0c:	0f b6 1a             	movzbl (%edx),%ebx
80103e0f:	38 d8                	cmp    %bl,%al
80103e11:	75 0a                	jne    80103e1d <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103e13:	83 c1 01             	add    $0x1,%ecx
80103e16:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103e19:	89 f0                	mov    %esi,%eax
80103e1b:	eb e5                	jmp    80103e02 <memcmp+0xe>
      return *s1 - *s2;
80103e1d:	0f b6 c0             	movzbl %al,%eax
80103e20:	0f b6 db             	movzbl %bl,%ebx
80103e23:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103e25:	5b                   	pop    %ebx
80103e26:	5e                   	pop    %esi
80103e27:	5d                   	pop    %ebp
80103e28:	c3                   	ret    

80103e29 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103e29:	55                   	push   %ebp
80103e2a:	89 e5                	mov    %esp,%ebp
80103e2c:	56                   	push   %esi
80103e2d:	53                   	push   %ebx
80103e2e:	8b 45 08             	mov    0x8(%ebp),%eax
80103e31:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103e34:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103e37:	39 c1                	cmp    %eax,%ecx
80103e39:	73 3a                	jae    80103e75 <memmove+0x4c>
80103e3b:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103e3e:	39 c3                	cmp    %eax,%ebx
80103e40:	76 37                	jbe    80103e79 <memmove+0x50>
    s += n;
    d += n;
80103e42:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103e45:	eb 0d                	jmp    80103e54 <memmove+0x2b>
      *--d = *--s;
80103e47:	83 eb 01             	sub    $0x1,%ebx
80103e4a:	83 e9 01             	sub    $0x1,%ecx
80103e4d:	0f b6 13             	movzbl (%ebx),%edx
80103e50:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103e52:	89 f2                	mov    %esi,%edx
80103e54:	8d 72 ff             	lea    -0x1(%edx),%esi
80103e57:	85 d2                	test   %edx,%edx
80103e59:	75 ec                	jne    80103e47 <memmove+0x1e>
80103e5b:	eb 14                	jmp    80103e71 <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103e5d:	0f b6 11             	movzbl (%ecx),%edx
80103e60:	88 13                	mov    %dl,(%ebx)
80103e62:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103e65:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103e68:	89 f2                	mov    %esi,%edx
80103e6a:	8d 72 ff             	lea    -0x1(%edx),%esi
80103e6d:	85 d2                	test   %edx,%edx
80103e6f:	75 ec                	jne    80103e5d <memmove+0x34>

  return dst;
}
80103e71:	5b                   	pop    %ebx
80103e72:	5e                   	pop    %esi
80103e73:	5d                   	pop    %ebp
80103e74:	c3                   	ret    
80103e75:	89 c3                	mov    %eax,%ebx
80103e77:	eb f1                	jmp    80103e6a <memmove+0x41>
80103e79:	89 c3                	mov    %eax,%ebx
80103e7b:	eb ed                	jmp    80103e6a <memmove+0x41>

80103e7d <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103e7d:	55                   	push   %ebp
80103e7e:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80103e80:	ff 75 10             	pushl  0x10(%ebp)
80103e83:	ff 75 0c             	pushl  0xc(%ebp)
80103e86:	ff 75 08             	pushl  0x8(%ebp)
80103e89:	e8 9b ff ff ff       	call   80103e29 <memmove>
}
80103e8e:	c9                   	leave  
80103e8f:	c3                   	ret    

80103e90 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103e90:	55                   	push   %ebp
80103e91:	89 e5                	mov    %esp,%ebp
80103e93:	53                   	push   %ebx
80103e94:	8b 55 08             	mov    0x8(%ebp),%edx
80103e97:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103e9a:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103e9d:	eb 09                	jmp    80103ea8 <strncmp+0x18>
    n--, p++, q++;
80103e9f:	83 e8 01             	sub    $0x1,%eax
80103ea2:	83 c2 01             	add    $0x1,%edx
80103ea5:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103ea8:	85 c0                	test   %eax,%eax
80103eaa:	74 0b                	je     80103eb7 <strncmp+0x27>
80103eac:	0f b6 1a             	movzbl (%edx),%ebx
80103eaf:	84 db                	test   %bl,%bl
80103eb1:	74 04                	je     80103eb7 <strncmp+0x27>
80103eb3:	3a 19                	cmp    (%ecx),%bl
80103eb5:	74 e8                	je     80103e9f <strncmp+0xf>
  if(n == 0)
80103eb7:	85 c0                	test   %eax,%eax
80103eb9:	74 0b                	je     80103ec6 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80103ebb:	0f b6 02             	movzbl (%edx),%eax
80103ebe:	0f b6 11             	movzbl (%ecx),%edx
80103ec1:	29 d0                	sub    %edx,%eax
}
80103ec3:	5b                   	pop    %ebx
80103ec4:	5d                   	pop    %ebp
80103ec5:	c3                   	ret    
    return 0;
80103ec6:	b8 00 00 00 00       	mov    $0x0,%eax
80103ecb:	eb f6                	jmp    80103ec3 <strncmp+0x33>

80103ecd <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103ecd:	55                   	push   %ebp
80103ece:	89 e5                	mov    %esp,%ebp
80103ed0:	57                   	push   %edi
80103ed1:	56                   	push   %esi
80103ed2:	53                   	push   %ebx
80103ed3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103ed6:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103ed9:	8b 45 08             	mov    0x8(%ebp),%eax
80103edc:	eb 04                	jmp    80103ee2 <strncpy+0x15>
80103ede:	89 fb                	mov    %edi,%ebx
80103ee0:	89 f0                	mov    %esi,%eax
80103ee2:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103ee5:	85 c9                	test   %ecx,%ecx
80103ee7:	7e 1d                	jle    80103f06 <strncpy+0x39>
80103ee9:	8d 7b 01             	lea    0x1(%ebx),%edi
80103eec:	8d 70 01             	lea    0x1(%eax),%esi
80103eef:	0f b6 1b             	movzbl (%ebx),%ebx
80103ef2:	88 18                	mov    %bl,(%eax)
80103ef4:	89 d1                	mov    %edx,%ecx
80103ef6:	84 db                	test   %bl,%bl
80103ef8:	75 e4                	jne    80103ede <strncpy+0x11>
80103efa:	89 f0                	mov    %esi,%eax
80103efc:	eb 08                	jmp    80103f06 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80103efe:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80103f01:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80103f03:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80103f06:	8d 4a ff             	lea    -0x1(%edx),%ecx
80103f09:	85 d2                	test   %edx,%edx
80103f0b:	7f f1                	jg     80103efe <strncpy+0x31>
  return os;
}
80103f0d:	8b 45 08             	mov    0x8(%ebp),%eax
80103f10:	5b                   	pop    %ebx
80103f11:	5e                   	pop    %esi
80103f12:	5f                   	pop    %edi
80103f13:	5d                   	pop    %ebp
80103f14:	c3                   	ret    

80103f15 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80103f15:	55                   	push   %ebp
80103f16:	89 e5                	mov    %esp,%ebp
80103f18:	57                   	push   %edi
80103f19:	56                   	push   %esi
80103f1a:	53                   	push   %ebx
80103f1b:	8b 45 08             	mov    0x8(%ebp),%eax
80103f1e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103f21:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
80103f24:	85 d2                	test   %edx,%edx
80103f26:	7e 23                	jle    80103f4b <safestrcpy+0x36>
80103f28:	89 c1                	mov    %eax,%ecx
80103f2a:	eb 04                	jmp    80103f30 <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80103f2c:	89 fb                	mov    %edi,%ebx
80103f2e:	89 f1                	mov    %esi,%ecx
80103f30:	83 ea 01             	sub    $0x1,%edx
80103f33:	85 d2                	test   %edx,%edx
80103f35:	7e 11                	jle    80103f48 <safestrcpy+0x33>
80103f37:	8d 7b 01             	lea    0x1(%ebx),%edi
80103f3a:	8d 71 01             	lea    0x1(%ecx),%esi
80103f3d:	0f b6 1b             	movzbl (%ebx),%ebx
80103f40:	88 19                	mov    %bl,(%ecx)
80103f42:	84 db                	test   %bl,%bl
80103f44:	75 e6                	jne    80103f2c <safestrcpy+0x17>
80103f46:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80103f48:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80103f4b:	5b                   	pop    %ebx
80103f4c:	5e                   	pop    %esi
80103f4d:	5f                   	pop    %edi
80103f4e:	5d                   	pop    %ebp
80103f4f:	c3                   	ret    

80103f50 <strlen>:

int
strlen(const char *s)
{
80103f50:	55                   	push   %ebp
80103f51:	89 e5                	mov    %esp,%ebp
80103f53:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80103f56:	b8 00 00 00 00       	mov    $0x0,%eax
80103f5b:	eb 03                	jmp    80103f60 <strlen+0x10>
80103f5d:	83 c0 01             	add    $0x1,%eax
80103f60:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80103f64:	75 f7                	jne    80103f5d <strlen+0xd>
    ;
  return n;
}
80103f66:	5d                   	pop    %ebp
80103f67:	c3                   	ret    

80103f68 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80103f68:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80103f6c:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80103f70:	55                   	push   %ebp
  pushl %ebx
80103f71:	53                   	push   %ebx
  pushl %esi
80103f72:	56                   	push   %esi
  pushl %edi
80103f73:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80103f74:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80103f76:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80103f78:	5f                   	pop    %edi
  popl %esi
80103f79:	5e                   	pop    %esi
  popl %ebx
80103f7a:	5b                   	pop    %ebx
  popl %ebp
80103f7b:	5d                   	pop    %ebp
  ret
80103f7c:	c3                   	ret    

80103f7d <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80103f7d:	55                   	push   %ebp
80103f7e:	89 e5                	mov    %esp,%ebp
80103f80:	53                   	push   %ebx
80103f81:	83 ec 04             	sub    $0x4,%esp
80103f84:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80103f87:	e8 d4 f3 ff ff       	call   80103360 <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80103f8c:	8b 00                	mov    (%eax),%eax
80103f8e:	39 d8                	cmp    %ebx,%eax
80103f90:	76 19                	jbe    80103fab <fetchint+0x2e>
80103f92:	8d 53 04             	lea    0x4(%ebx),%edx
80103f95:	39 d0                	cmp    %edx,%eax
80103f97:	72 19                	jb     80103fb2 <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80103f99:	8b 13                	mov    (%ebx),%edx
80103f9b:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f9e:	89 10                	mov    %edx,(%eax)
  return 0;
80103fa0:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103fa5:	83 c4 04             	add    $0x4,%esp
80103fa8:	5b                   	pop    %ebx
80103fa9:	5d                   	pop    %ebp
80103faa:	c3                   	ret    
    return -1;
80103fab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fb0:	eb f3                	jmp    80103fa5 <fetchint+0x28>
80103fb2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fb7:	eb ec                	jmp    80103fa5 <fetchint+0x28>

80103fb9 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80103fb9:	55                   	push   %ebp
80103fba:	89 e5                	mov    %esp,%ebp
80103fbc:	53                   	push   %ebx
80103fbd:	83 ec 04             	sub    $0x4,%esp
80103fc0:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
80103fc3:	e8 98 f3 ff ff       	call   80103360 <myproc>

  if(addr >= curproc->sz)
80103fc8:	39 18                	cmp    %ebx,(%eax)
80103fca:	76 26                	jbe    80103ff2 <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
80103fcc:	8b 55 0c             	mov    0xc(%ebp),%edx
80103fcf:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
80103fd1:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
80103fd3:	89 d8                	mov    %ebx,%eax
80103fd5:	39 d0                	cmp    %edx,%eax
80103fd7:	73 0e                	jae    80103fe7 <fetchstr+0x2e>
    if(*s == 0)
80103fd9:	80 38 00             	cmpb   $0x0,(%eax)
80103fdc:	74 05                	je     80103fe3 <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
80103fde:	83 c0 01             	add    $0x1,%eax
80103fe1:	eb f2                	jmp    80103fd5 <fetchstr+0x1c>
      return s - *pp;
80103fe3:	29 d8                	sub    %ebx,%eax
80103fe5:	eb 05                	jmp    80103fec <fetchstr+0x33>
  }
  return -1;
80103fe7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103fec:	83 c4 04             	add    $0x4,%esp
80103fef:	5b                   	pop    %ebx
80103ff0:	5d                   	pop    %ebp
80103ff1:	c3                   	ret    
    return -1;
80103ff2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103ff7:	eb f3                	jmp    80103fec <fetchstr+0x33>

80103ff9 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80103ff9:	55                   	push   %ebp
80103ffa:	89 e5                	mov    %esp,%ebp
80103ffc:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80103fff:	e8 5c f3 ff ff       	call   80103360 <myproc>
80104004:	8b 50 18             	mov    0x18(%eax),%edx
80104007:	8b 45 08             	mov    0x8(%ebp),%eax
8010400a:	c1 e0 02             	shl    $0x2,%eax
8010400d:	03 42 44             	add    0x44(%edx),%eax
80104010:	83 ec 08             	sub    $0x8,%esp
80104013:	ff 75 0c             	pushl  0xc(%ebp)
80104016:	83 c0 04             	add    $0x4,%eax
80104019:	50                   	push   %eax
8010401a:	e8 5e ff ff ff       	call   80103f7d <fetchint>
}
8010401f:	c9                   	leave  
80104020:	c3                   	ret    

80104021 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80104021:	55                   	push   %ebp
80104022:	89 e5                	mov    %esp,%ebp
80104024:	56                   	push   %esi
80104025:	53                   	push   %ebx
80104026:	83 ec 10             	sub    $0x10,%esp
80104029:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
8010402c:	e8 2f f3 ff ff       	call   80103360 <myproc>
80104031:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
80104033:	83 ec 08             	sub    $0x8,%esp
80104036:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104039:	50                   	push   %eax
8010403a:	ff 75 08             	pushl  0x8(%ebp)
8010403d:	e8 b7 ff ff ff       	call   80103ff9 <argint>
80104042:	83 c4 10             	add    $0x10,%esp
80104045:	85 c0                	test   %eax,%eax
80104047:	78 24                	js     8010406d <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80104049:	85 db                	test   %ebx,%ebx
8010404b:	78 27                	js     80104074 <argptr+0x53>
8010404d:	8b 16                	mov    (%esi),%edx
8010404f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104052:	39 c2                	cmp    %eax,%edx
80104054:	76 25                	jbe    8010407b <argptr+0x5a>
80104056:	01 c3                	add    %eax,%ebx
80104058:	39 da                	cmp    %ebx,%edx
8010405a:	72 26                	jb     80104082 <argptr+0x61>
    return -1;
  *pp = (char*)i;
8010405c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010405f:	89 02                	mov    %eax,(%edx)
  return 0;
80104061:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104066:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104069:	5b                   	pop    %ebx
8010406a:	5e                   	pop    %esi
8010406b:	5d                   	pop    %ebp
8010406c:	c3                   	ret    
    return -1;
8010406d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104072:	eb f2                	jmp    80104066 <argptr+0x45>
    return -1;
80104074:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104079:	eb eb                	jmp    80104066 <argptr+0x45>
8010407b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104080:	eb e4                	jmp    80104066 <argptr+0x45>
80104082:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104087:	eb dd                	jmp    80104066 <argptr+0x45>

80104089 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80104089:	55                   	push   %ebp
8010408a:	89 e5                	mov    %esp,%ebp
8010408c:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010408f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104092:	50                   	push   %eax
80104093:	ff 75 08             	pushl  0x8(%ebp)
80104096:	e8 5e ff ff ff       	call   80103ff9 <argint>
8010409b:	83 c4 10             	add    $0x10,%esp
8010409e:	85 c0                	test   %eax,%eax
801040a0:	78 13                	js     801040b5 <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
801040a2:	83 ec 08             	sub    $0x8,%esp
801040a5:	ff 75 0c             	pushl  0xc(%ebp)
801040a8:	ff 75 f4             	pushl  -0xc(%ebp)
801040ab:	e8 09 ff ff ff       	call   80103fb9 <fetchstr>
801040b0:	83 c4 10             	add    $0x10,%esp
}
801040b3:	c9                   	leave  
801040b4:	c3                   	ret    
    return -1;
801040b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040ba:	eb f7                	jmp    801040b3 <argstr+0x2a>

801040bc <syscall>:
[SYS_dump_physmem]   sys_dump_physmem,
};

void
syscall(void)
{
801040bc:	55                   	push   %ebp
801040bd:	89 e5                	mov    %esp,%ebp
801040bf:	53                   	push   %ebx
801040c0:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
801040c3:	e8 98 f2 ff ff       	call   80103360 <myproc>
801040c8:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
801040ca:	8b 40 18             	mov    0x18(%eax),%eax
801040cd:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
801040d0:	8d 50 ff             	lea    -0x1(%eax),%edx
801040d3:	83 fa 15             	cmp    $0x15,%edx
801040d6:	77 18                	ja     801040f0 <syscall+0x34>
801040d8:	8b 14 85 20 6d 10 80 	mov    -0x7fef92e0(,%eax,4),%edx
801040df:	85 d2                	test   %edx,%edx
801040e1:	74 0d                	je     801040f0 <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
801040e3:	ff d2                	call   *%edx
801040e5:	8b 53 18             	mov    0x18(%ebx),%edx
801040e8:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
801040eb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801040ee:	c9                   	leave  
801040ef:	c3                   	ret    
            curproc->pid, curproc->name, num);
801040f0:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
801040f3:	50                   	push   %eax
801040f4:	52                   	push   %edx
801040f5:	ff 73 10             	pushl  0x10(%ebx)
801040f8:	68 f1 6c 10 80       	push   $0x80106cf1
801040fd:	e8 09 c5 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
80104102:	8b 43 18             	mov    0x18(%ebx),%eax
80104105:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
8010410c:	83 c4 10             	add    $0x10,%esp
}
8010410f:	eb da                	jmp    801040eb <syscall+0x2f>

80104111 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80104111:	55                   	push   %ebp
80104112:	89 e5                	mov    %esp,%ebp
80104114:	56                   	push   %esi
80104115:	53                   	push   %ebx
80104116:	83 ec 18             	sub    $0x18,%esp
80104119:	89 d6                	mov    %edx,%esi
8010411b:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010411d:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104120:	52                   	push   %edx
80104121:	50                   	push   %eax
80104122:	e8 d2 fe ff ff       	call   80103ff9 <argint>
80104127:	83 c4 10             	add    $0x10,%esp
8010412a:	85 c0                	test   %eax,%eax
8010412c:	78 2e                	js     8010415c <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
8010412e:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
80104132:	77 2f                	ja     80104163 <argfd+0x52>
80104134:	e8 27 f2 ff ff       	call   80103360 <myproc>
80104139:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010413c:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
80104140:	85 c0                	test   %eax,%eax
80104142:	74 26                	je     8010416a <argfd+0x59>
    return -1;
  if(pfd)
80104144:	85 f6                	test   %esi,%esi
80104146:	74 02                	je     8010414a <argfd+0x39>
    *pfd = fd;
80104148:	89 16                	mov    %edx,(%esi)
  if(pf)
8010414a:	85 db                	test   %ebx,%ebx
8010414c:	74 23                	je     80104171 <argfd+0x60>
    *pf = f;
8010414e:	89 03                	mov    %eax,(%ebx)
  return 0;
80104150:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104155:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104158:	5b                   	pop    %ebx
80104159:	5e                   	pop    %esi
8010415a:	5d                   	pop    %ebp
8010415b:	c3                   	ret    
    return -1;
8010415c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104161:	eb f2                	jmp    80104155 <argfd+0x44>
    return -1;
80104163:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104168:	eb eb                	jmp    80104155 <argfd+0x44>
8010416a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010416f:	eb e4                	jmp    80104155 <argfd+0x44>
  return 0;
80104171:	b8 00 00 00 00       	mov    $0x0,%eax
80104176:	eb dd                	jmp    80104155 <argfd+0x44>

80104178 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80104178:	55                   	push   %ebp
80104179:	89 e5                	mov    %esp,%ebp
8010417b:	53                   	push   %ebx
8010417c:	83 ec 04             	sub    $0x4,%esp
8010417f:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
80104181:	e8 da f1 ff ff       	call   80103360 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
80104186:	ba 00 00 00 00       	mov    $0x0,%edx
8010418b:	83 fa 0f             	cmp    $0xf,%edx
8010418e:	7f 18                	jg     801041a8 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
80104190:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
80104195:	74 05                	je     8010419c <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
80104197:	83 c2 01             	add    $0x1,%edx
8010419a:	eb ef                	jmp    8010418b <fdalloc+0x13>
      curproc->ofile[fd] = f;
8010419c:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
801041a0:	89 d0                	mov    %edx,%eax
801041a2:	83 c4 04             	add    $0x4,%esp
801041a5:	5b                   	pop    %ebx
801041a6:	5d                   	pop    %ebp
801041a7:	c3                   	ret    
  return -1;
801041a8:	ba ff ff ff ff       	mov    $0xffffffff,%edx
801041ad:	eb f1                	jmp    801041a0 <fdalloc+0x28>

801041af <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801041af:	55                   	push   %ebp
801041b0:	89 e5                	mov    %esp,%ebp
801041b2:	56                   	push   %esi
801041b3:	53                   	push   %ebx
801041b4:	83 ec 10             	sub    $0x10,%esp
801041b7:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801041b9:	b8 20 00 00 00       	mov    $0x20,%eax
801041be:	89 c6                	mov    %eax,%esi
801041c0:	39 43 58             	cmp    %eax,0x58(%ebx)
801041c3:	76 2e                	jbe    801041f3 <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801041c5:	6a 10                	push   $0x10
801041c7:	50                   	push   %eax
801041c8:	8d 45 e8             	lea    -0x18(%ebp),%eax
801041cb:	50                   	push   %eax
801041cc:	53                   	push   %ebx
801041cd:	e8 a1 d5 ff ff       	call   80101773 <readi>
801041d2:	83 c4 10             	add    $0x10,%esp
801041d5:	83 f8 10             	cmp    $0x10,%eax
801041d8:	75 0c                	jne    801041e6 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
801041da:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
801041df:	75 1e                	jne    801041ff <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801041e1:	8d 46 10             	lea    0x10(%esi),%eax
801041e4:	eb d8                	jmp    801041be <isdirempty+0xf>
      panic("isdirempty: readi");
801041e6:	83 ec 0c             	sub    $0xc,%esp
801041e9:	68 7c 6d 10 80       	push   $0x80106d7c
801041ee:	e8 55 c1 ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
801041f3:	b8 01 00 00 00       	mov    $0x1,%eax
}
801041f8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801041fb:	5b                   	pop    %ebx
801041fc:	5e                   	pop    %esi
801041fd:	5d                   	pop    %ebp
801041fe:	c3                   	ret    
      return 0;
801041ff:	b8 00 00 00 00       	mov    $0x0,%eax
80104204:	eb f2                	jmp    801041f8 <isdirempty+0x49>

80104206 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
80104206:	55                   	push   %ebp
80104207:	89 e5                	mov    %esp,%ebp
80104209:	57                   	push   %edi
8010420a:	56                   	push   %esi
8010420b:	53                   	push   %ebx
8010420c:	83 ec 44             	sub    $0x44,%esp
8010420f:	89 55 c4             	mov    %edx,-0x3c(%ebp)
80104212:	89 4d c0             	mov    %ecx,-0x40(%ebp)
80104215:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80104218:	8d 55 d6             	lea    -0x2a(%ebp),%edx
8010421b:	52                   	push   %edx
8010421c:	50                   	push   %eax
8010421d:	e8 d7 d9 ff ff       	call   80101bf9 <nameiparent>
80104222:	89 c6                	mov    %eax,%esi
80104224:	83 c4 10             	add    $0x10,%esp
80104227:	85 c0                	test   %eax,%eax
80104229:	0f 84 3a 01 00 00    	je     80104369 <create+0x163>
    return 0;
  ilock(dp);
8010422f:	83 ec 0c             	sub    $0xc,%esp
80104232:	50                   	push   %eax
80104233:	e8 49 d3 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80104238:	83 c4 0c             	add    $0xc,%esp
8010423b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010423e:	50                   	push   %eax
8010423f:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104242:	50                   	push   %eax
80104243:	56                   	push   %esi
80104244:	e8 67 d7 ff ff       	call   801019b0 <dirlookup>
80104249:	89 c3                	mov    %eax,%ebx
8010424b:	83 c4 10             	add    $0x10,%esp
8010424e:	85 c0                	test   %eax,%eax
80104250:	74 3f                	je     80104291 <create+0x8b>
    iunlockput(dp);
80104252:	83 ec 0c             	sub    $0xc,%esp
80104255:	56                   	push   %esi
80104256:	e8 cd d4 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
8010425b:	89 1c 24             	mov    %ebx,(%esp)
8010425e:	e8 1e d3 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80104263:	83 c4 10             	add    $0x10,%esp
80104266:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
8010426b:	75 11                	jne    8010427e <create+0x78>
8010426d:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
80104272:	75 0a                	jne    8010427e <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
80104274:	89 d8                	mov    %ebx,%eax
80104276:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104279:	5b                   	pop    %ebx
8010427a:	5e                   	pop    %esi
8010427b:	5f                   	pop    %edi
8010427c:	5d                   	pop    %ebp
8010427d:	c3                   	ret    
    iunlockput(ip);
8010427e:	83 ec 0c             	sub    $0xc,%esp
80104281:	53                   	push   %ebx
80104282:	e8 a1 d4 ff ff       	call   80101728 <iunlockput>
    return 0;
80104287:	83 c4 10             	add    $0x10,%esp
8010428a:	bb 00 00 00 00       	mov    $0x0,%ebx
8010428f:	eb e3                	jmp    80104274 <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
80104291:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
80104295:	83 ec 08             	sub    $0x8,%esp
80104298:	50                   	push   %eax
80104299:	ff 36                	pushl  (%esi)
8010429b:	e8 de d0 ff ff       	call   8010137e <ialloc>
801042a0:	89 c3                	mov    %eax,%ebx
801042a2:	83 c4 10             	add    $0x10,%esp
801042a5:	85 c0                	test   %eax,%eax
801042a7:	74 55                	je     801042fe <create+0xf8>
  ilock(ip);
801042a9:	83 ec 0c             	sub    $0xc,%esp
801042ac:	50                   	push   %eax
801042ad:	e8 cf d2 ff ff       	call   80101581 <ilock>
  ip->major = major;
801042b2:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
801042b6:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
801042ba:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
801042be:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
801042c4:	89 1c 24             	mov    %ebx,(%esp)
801042c7:	e8 54 d1 ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
801042cc:	83 c4 10             	add    $0x10,%esp
801042cf:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
801042d4:	74 35                	je     8010430b <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
801042d6:	83 ec 04             	sub    $0x4,%esp
801042d9:	ff 73 04             	pushl  0x4(%ebx)
801042dc:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801042df:	50                   	push   %eax
801042e0:	56                   	push   %esi
801042e1:	e8 4a d8 ff ff       	call   80101b30 <dirlink>
801042e6:	83 c4 10             	add    $0x10,%esp
801042e9:	85 c0                	test   %eax,%eax
801042eb:	78 6f                	js     8010435c <create+0x156>
  iunlockput(dp);
801042ed:	83 ec 0c             	sub    $0xc,%esp
801042f0:	56                   	push   %esi
801042f1:	e8 32 d4 ff ff       	call   80101728 <iunlockput>
  return ip;
801042f6:	83 c4 10             	add    $0x10,%esp
801042f9:	e9 76 ff ff ff       	jmp    80104274 <create+0x6e>
    panic("create: ialloc");
801042fe:	83 ec 0c             	sub    $0xc,%esp
80104301:	68 8e 6d 10 80       	push   $0x80106d8e
80104306:	e8 3d c0 ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
8010430b:	0f b7 46 56          	movzwl 0x56(%esi),%eax
8010430f:	83 c0 01             	add    $0x1,%eax
80104312:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104316:	83 ec 0c             	sub    $0xc,%esp
80104319:	56                   	push   %esi
8010431a:	e8 01 d1 ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
8010431f:	83 c4 0c             	add    $0xc,%esp
80104322:	ff 73 04             	pushl  0x4(%ebx)
80104325:	68 9e 6d 10 80       	push   $0x80106d9e
8010432a:	53                   	push   %ebx
8010432b:	e8 00 d8 ff ff       	call   80101b30 <dirlink>
80104330:	83 c4 10             	add    $0x10,%esp
80104333:	85 c0                	test   %eax,%eax
80104335:	78 18                	js     8010434f <create+0x149>
80104337:	83 ec 04             	sub    $0x4,%esp
8010433a:	ff 76 04             	pushl  0x4(%esi)
8010433d:	68 9d 6d 10 80       	push   $0x80106d9d
80104342:	53                   	push   %ebx
80104343:	e8 e8 d7 ff ff       	call   80101b30 <dirlink>
80104348:	83 c4 10             	add    $0x10,%esp
8010434b:	85 c0                	test   %eax,%eax
8010434d:	79 87                	jns    801042d6 <create+0xd0>
      panic("create dots");
8010434f:	83 ec 0c             	sub    $0xc,%esp
80104352:	68 a0 6d 10 80       	push   $0x80106da0
80104357:	e8 ec bf ff ff       	call   80100348 <panic>
    panic("create: dirlink");
8010435c:	83 ec 0c             	sub    $0xc,%esp
8010435f:	68 ac 6d 10 80       	push   $0x80106dac
80104364:	e8 df bf ff ff       	call   80100348 <panic>
    return 0;
80104369:	89 c3                	mov    %eax,%ebx
8010436b:	e9 04 ff ff ff       	jmp    80104274 <create+0x6e>

80104370 <sys_dup>:
{
80104370:	55                   	push   %ebp
80104371:	89 e5                	mov    %esp,%ebp
80104373:	53                   	push   %ebx
80104374:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
80104377:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010437a:	ba 00 00 00 00       	mov    $0x0,%edx
8010437f:	b8 00 00 00 00       	mov    $0x0,%eax
80104384:	e8 88 fd ff ff       	call   80104111 <argfd>
80104389:	85 c0                	test   %eax,%eax
8010438b:	78 23                	js     801043b0 <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
8010438d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104390:	e8 e3 fd ff ff       	call   80104178 <fdalloc>
80104395:	89 c3                	mov    %eax,%ebx
80104397:	85 c0                	test   %eax,%eax
80104399:	78 1c                	js     801043b7 <sys_dup+0x47>
  filedup(f);
8010439b:	83 ec 0c             	sub    $0xc,%esp
8010439e:	ff 75 f4             	pushl  -0xc(%ebp)
801043a1:	e8 e8 c8 ff ff       	call   80100c8e <filedup>
  return fd;
801043a6:	83 c4 10             	add    $0x10,%esp
}
801043a9:	89 d8                	mov    %ebx,%eax
801043ab:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801043ae:	c9                   	leave  
801043af:	c3                   	ret    
    return -1;
801043b0:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801043b5:	eb f2                	jmp    801043a9 <sys_dup+0x39>
    return -1;
801043b7:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801043bc:	eb eb                	jmp    801043a9 <sys_dup+0x39>

801043be <sys_read>:
{
801043be:	55                   	push   %ebp
801043bf:	89 e5                	mov    %esp,%ebp
801043c1:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801043c4:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801043c7:	ba 00 00 00 00       	mov    $0x0,%edx
801043cc:	b8 00 00 00 00       	mov    $0x0,%eax
801043d1:	e8 3b fd ff ff       	call   80104111 <argfd>
801043d6:	85 c0                	test   %eax,%eax
801043d8:	78 43                	js     8010441d <sys_read+0x5f>
801043da:	83 ec 08             	sub    $0x8,%esp
801043dd:	8d 45 f0             	lea    -0x10(%ebp),%eax
801043e0:	50                   	push   %eax
801043e1:	6a 02                	push   $0x2
801043e3:	e8 11 fc ff ff       	call   80103ff9 <argint>
801043e8:	83 c4 10             	add    $0x10,%esp
801043eb:	85 c0                	test   %eax,%eax
801043ed:	78 35                	js     80104424 <sys_read+0x66>
801043ef:	83 ec 04             	sub    $0x4,%esp
801043f2:	ff 75 f0             	pushl  -0x10(%ebp)
801043f5:	8d 45 ec             	lea    -0x14(%ebp),%eax
801043f8:	50                   	push   %eax
801043f9:	6a 01                	push   $0x1
801043fb:	e8 21 fc ff ff       	call   80104021 <argptr>
80104400:	83 c4 10             	add    $0x10,%esp
80104403:	85 c0                	test   %eax,%eax
80104405:	78 24                	js     8010442b <sys_read+0x6d>
  return fileread(f, p, n);
80104407:	83 ec 04             	sub    $0x4,%esp
8010440a:	ff 75 f0             	pushl  -0x10(%ebp)
8010440d:	ff 75 ec             	pushl  -0x14(%ebp)
80104410:	ff 75 f4             	pushl  -0xc(%ebp)
80104413:	e8 bf c9 ff ff       	call   80100dd7 <fileread>
80104418:	83 c4 10             	add    $0x10,%esp
}
8010441b:	c9                   	leave  
8010441c:	c3                   	ret    
    return -1;
8010441d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104422:	eb f7                	jmp    8010441b <sys_read+0x5d>
80104424:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104429:	eb f0                	jmp    8010441b <sys_read+0x5d>
8010442b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104430:	eb e9                	jmp    8010441b <sys_read+0x5d>

80104432 <sys_write>:
{
80104432:	55                   	push   %ebp
80104433:	89 e5                	mov    %esp,%ebp
80104435:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104438:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010443b:	ba 00 00 00 00       	mov    $0x0,%edx
80104440:	b8 00 00 00 00       	mov    $0x0,%eax
80104445:	e8 c7 fc ff ff       	call   80104111 <argfd>
8010444a:	85 c0                	test   %eax,%eax
8010444c:	78 43                	js     80104491 <sys_write+0x5f>
8010444e:	83 ec 08             	sub    $0x8,%esp
80104451:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104454:	50                   	push   %eax
80104455:	6a 02                	push   $0x2
80104457:	e8 9d fb ff ff       	call   80103ff9 <argint>
8010445c:	83 c4 10             	add    $0x10,%esp
8010445f:	85 c0                	test   %eax,%eax
80104461:	78 35                	js     80104498 <sys_write+0x66>
80104463:	83 ec 04             	sub    $0x4,%esp
80104466:	ff 75 f0             	pushl  -0x10(%ebp)
80104469:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010446c:	50                   	push   %eax
8010446d:	6a 01                	push   $0x1
8010446f:	e8 ad fb ff ff       	call   80104021 <argptr>
80104474:	83 c4 10             	add    $0x10,%esp
80104477:	85 c0                	test   %eax,%eax
80104479:	78 24                	js     8010449f <sys_write+0x6d>
  return filewrite(f, p, n);
8010447b:	83 ec 04             	sub    $0x4,%esp
8010447e:	ff 75 f0             	pushl  -0x10(%ebp)
80104481:	ff 75 ec             	pushl  -0x14(%ebp)
80104484:	ff 75 f4             	pushl  -0xc(%ebp)
80104487:	e8 d0 c9 ff ff       	call   80100e5c <filewrite>
8010448c:	83 c4 10             	add    $0x10,%esp
}
8010448f:	c9                   	leave  
80104490:	c3                   	ret    
    return -1;
80104491:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104496:	eb f7                	jmp    8010448f <sys_write+0x5d>
80104498:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010449d:	eb f0                	jmp    8010448f <sys_write+0x5d>
8010449f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044a4:	eb e9                	jmp    8010448f <sys_write+0x5d>

801044a6 <sys_close>:
{
801044a6:	55                   	push   %ebp
801044a7:	89 e5                	mov    %esp,%ebp
801044a9:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
801044ac:	8d 4d f0             	lea    -0x10(%ebp),%ecx
801044af:	8d 55 f4             	lea    -0xc(%ebp),%edx
801044b2:	b8 00 00 00 00       	mov    $0x0,%eax
801044b7:	e8 55 fc ff ff       	call   80104111 <argfd>
801044bc:	85 c0                	test   %eax,%eax
801044be:	78 25                	js     801044e5 <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
801044c0:	e8 9b ee ff ff       	call   80103360 <myproc>
801044c5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801044c8:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
801044cf:	00 
  fileclose(f);
801044d0:	83 ec 0c             	sub    $0xc,%esp
801044d3:	ff 75 f0             	pushl  -0x10(%ebp)
801044d6:	e8 f8 c7 ff ff       	call   80100cd3 <fileclose>
  return 0;
801044db:	83 c4 10             	add    $0x10,%esp
801044de:	b8 00 00 00 00       	mov    $0x0,%eax
}
801044e3:	c9                   	leave  
801044e4:	c3                   	ret    
    return -1;
801044e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044ea:	eb f7                	jmp    801044e3 <sys_close+0x3d>

801044ec <sys_fstat>:
{
801044ec:	55                   	push   %ebp
801044ed:	89 e5                	mov    %esp,%ebp
801044ef:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801044f2:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801044f5:	ba 00 00 00 00       	mov    $0x0,%edx
801044fa:	b8 00 00 00 00       	mov    $0x0,%eax
801044ff:	e8 0d fc ff ff       	call   80104111 <argfd>
80104504:	85 c0                	test   %eax,%eax
80104506:	78 2a                	js     80104532 <sys_fstat+0x46>
80104508:	83 ec 04             	sub    $0x4,%esp
8010450b:	6a 14                	push   $0x14
8010450d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104510:	50                   	push   %eax
80104511:	6a 01                	push   $0x1
80104513:	e8 09 fb ff ff       	call   80104021 <argptr>
80104518:	83 c4 10             	add    $0x10,%esp
8010451b:	85 c0                	test   %eax,%eax
8010451d:	78 1a                	js     80104539 <sys_fstat+0x4d>
  return filestat(f, st);
8010451f:	83 ec 08             	sub    $0x8,%esp
80104522:	ff 75 f0             	pushl  -0x10(%ebp)
80104525:	ff 75 f4             	pushl  -0xc(%ebp)
80104528:	e8 63 c8 ff ff       	call   80100d90 <filestat>
8010452d:	83 c4 10             	add    $0x10,%esp
}
80104530:	c9                   	leave  
80104531:	c3                   	ret    
    return -1;
80104532:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104537:	eb f7                	jmp    80104530 <sys_fstat+0x44>
80104539:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010453e:	eb f0                	jmp    80104530 <sys_fstat+0x44>

80104540 <sys_link>:
{
80104540:	55                   	push   %ebp
80104541:	89 e5                	mov    %esp,%ebp
80104543:	56                   	push   %esi
80104544:	53                   	push   %ebx
80104545:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80104548:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010454b:	50                   	push   %eax
8010454c:	6a 00                	push   $0x0
8010454e:	e8 36 fb ff ff       	call   80104089 <argstr>
80104553:	83 c4 10             	add    $0x10,%esp
80104556:	85 c0                	test   %eax,%eax
80104558:	0f 88 32 01 00 00    	js     80104690 <sys_link+0x150>
8010455e:	83 ec 08             	sub    $0x8,%esp
80104561:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104564:	50                   	push   %eax
80104565:	6a 01                	push   $0x1
80104567:	e8 1d fb ff ff       	call   80104089 <argstr>
8010456c:	83 c4 10             	add    $0x10,%esp
8010456f:	85 c0                	test   %eax,%eax
80104571:	0f 88 20 01 00 00    	js     80104697 <sys_link+0x157>
  begin_op();
80104577:	e8 94 e3 ff ff       	call   80102910 <begin_op>
  if((ip = namei(old)) == 0){
8010457c:	83 ec 0c             	sub    $0xc,%esp
8010457f:	ff 75 e0             	pushl  -0x20(%ebp)
80104582:	e8 5a d6 ff ff       	call   80101be1 <namei>
80104587:	89 c3                	mov    %eax,%ebx
80104589:	83 c4 10             	add    $0x10,%esp
8010458c:	85 c0                	test   %eax,%eax
8010458e:	0f 84 99 00 00 00    	je     8010462d <sys_link+0xed>
  ilock(ip);
80104594:	83 ec 0c             	sub    $0xc,%esp
80104597:	50                   	push   %eax
80104598:	e8 e4 cf ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
8010459d:	83 c4 10             	add    $0x10,%esp
801045a0:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801045a5:	0f 84 8e 00 00 00    	je     80104639 <sys_link+0xf9>
  ip->nlink++;
801045ab:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801045af:	83 c0 01             	add    $0x1,%eax
801045b2:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801045b6:	83 ec 0c             	sub    $0xc,%esp
801045b9:	53                   	push   %ebx
801045ba:	e8 61 ce ff ff       	call   80101420 <iupdate>
  iunlock(ip);
801045bf:	89 1c 24             	mov    %ebx,(%esp)
801045c2:	e8 7c d0 ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
801045c7:	83 c4 08             	add    $0x8,%esp
801045ca:	8d 45 ea             	lea    -0x16(%ebp),%eax
801045cd:	50                   	push   %eax
801045ce:	ff 75 e4             	pushl  -0x1c(%ebp)
801045d1:	e8 23 d6 ff ff       	call   80101bf9 <nameiparent>
801045d6:	89 c6                	mov    %eax,%esi
801045d8:	83 c4 10             	add    $0x10,%esp
801045db:	85 c0                	test   %eax,%eax
801045dd:	74 7e                	je     8010465d <sys_link+0x11d>
  ilock(dp);
801045df:	83 ec 0c             	sub    $0xc,%esp
801045e2:	50                   	push   %eax
801045e3:	e8 99 cf ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801045e8:	83 c4 10             	add    $0x10,%esp
801045eb:	8b 03                	mov    (%ebx),%eax
801045ed:	39 06                	cmp    %eax,(%esi)
801045ef:	75 60                	jne    80104651 <sys_link+0x111>
801045f1:	83 ec 04             	sub    $0x4,%esp
801045f4:	ff 73 04             	pushl  0x4(%ebx)
801045f7:	8d 45 ea             	lea    -0x16(%ebp),%eax
801045fa:	50                   	push   %eax
801045fb:	56                   	push   %esi
801045fc:	e8 2f d5 ff ff       	call   80101b30 <dirlink>
80104601:	83 c4 10             	add    $0x10,%esp
80104604:	85 c0                	test   %eax,%eax
80104606:	78 49                	js     80104651 <sys_link+0x111>
  iunlockput(dp);
80104608:	83 ec 0c             	sub    $0xc,%esp
8010460b:	56                   	push   %esi
8010460c:	e8 17 d1 ff ff       	call   80101728 <iunlockput>
  iput(ip);
80104611:	89 1c 24             	mov    %ebx,(%esp)
80104614:	e8 6f d0 ff ff       	call   80101688 <iput>
  end_op();
80104619:	e8 6c e3 ff ff       	call   8010298a <end_op>
  return 0;
8010461e:	83 c4 10             	add    $0x10,%esp
80104621:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104626:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104629:	5b                   	pop    %ebx
8010462a:	5e                   	pop    %esi
8010462b:	5d                   	pop    %ebp
8010462c:	c3                   	ret    
    end_op();
8010462d:	e8 58 e3 ff ff       	call   8010298a <end_op>
    return -1;
80104632:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104637:	eb ed                	jmp    80104626 <sys_link+0xe6>
    iunlockput(ip);
80104639:	83 ec 0c             	sub    $0xc,%esp
8010463c:	53                   	push   %ebx
8010463d:	e8 e6 d0 ff ff       	call   80101728 <iunlockput>
    end_op();
80104642:	e8 43 e3 ff ff       	call   8010298a <end_op>
    return -1;
80104647:	83 c4 10             	add    $0x10,%esp
8010464a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010464f:	eb d5                	jmp    80104626 <sys_link+0xe6>
    iunlockput(dp);
80104651:	83 ec 0c             	sub    $0xc,%esp
80104654:	56                   	push   %esi
80104655:	e8 ce d0 ff ff       	call   80101728 <iunlockput>
    goto bad;
8010465a:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
8010465d:	83 ec 0c             	sub    $0xc,%esp
80104660:	53                   	push   %ebx
80104661:	e8 1b cf ff ff       	call   80101581 <ilock>
  ip->nlink--;
80104666:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010466a:	83 e8 01             	sub    $0x1,%eax
8010466d:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104671:	89 1c 24             	mov    %ebx,(%esp)
80104674:	e8 a7 cd ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104679:	89 1c 24             	mov    %ebx,(%esp)
8010467c:	e8 a7 d0 ff ff       	call   80101728 <iunlockput>
  end_op();
80104681:	e8 04 e3 ff ff       	call   8010298a <end_op>
  return -1;
80104686:	83 c4 10             	add    $0x10,%esp
80104689:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010468e:	eb 96                	jmp    80104626 <sys_link+0xe6>
    return -1;
80104690:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104695:	eb 8f                	jmp    80104626 <sys_link+0xe6>
80104697:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010469c:	eb 88                	jmp    80104626 <sys_link+0xe6>

8010469e <sys_unlink>:
{
8010469e:	55                   	push   %ebp
8010469f:	89 e5                	mov    %esp,%ebp
801046a1:	57                   	push   %edi
801046a2:	56                   	push   %esi
801046a3:	53                   	push   %ebx
801046a4:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
801046a7:	8d 45 c4             	lea    -0x3c(%ebp),%eax
801046aa:	50                   	push   %eax
801046ab:	6a 00                	push   $0x0
801046ad:	e8 d7 f9 ff ff       	call   80104089 <argstr>
801046b2:	83 c4 10             	add    $0x10,%esp
801046b5:	85 c0                	test   %eax,%eax
801046b7:	0f 88 83 01 00 00    	js     80104840 <sys_unlink+0x1a2>
  begin_op();
801046bd:	e8 4e e2 ff ff       	call   80102910 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
801046c2:	83 ec 08             	sub    $0x8,%esp
801046c5:	8d 45 ca             	lea    -0x36(%ebp),%eax
801046c8:	50                   	push   %eax
801046c9:	ff 75 c4             	pushl  -0x3c(%ebp)
801046cc:	e8 28 d5 ff ff       	call   80101bf9 <nameiparent>
801046d1:	89 c6                	mov    %eax,%esi
801046d3:	83 c4 10             	add    $0x10,%esp
801046d6:	85 c0                	test   %eax,%eax
801046d8:	0f 84 ed 00 00 00    	je     801047cb <sys_unlink+0x12d>
  ilock(dp);
801046de:	83 ec 0c             	sub    $0xc,%esp
801046e1:	50                   	push   %eax
801046e2:	e8 9a ce ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801046e7:	83 c4 08             	add    $0x8,%esp
801046ea:	68 9e 6d 10 80       	push   $0x80106d9e
801046ef:	8d 45 ca             	lea    -0x36(%ebp),%eax
801046f2:	50                   	push   %eax
801046f3:	e8 a3 d2 ff ff       	call   8010199b <namecmp>
801046f8:	83 c4 10             	add    $0x10,%esp
801046fb:	85 c0                	test   %eax,%eax
801046fd:	0f 84 fc 00 00 00    	je     801047ff <sys_unlink+0x161>
80104703:	83 ec 08             	sub    $0x8,%esp
80104706:	68 9d 6d 10 80       	push   $0x80106d9d
8010470b:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010470e:	50                   	push   %eax
8010470f:	e8 87 d2 ff ff       	call   8010199b <namecmp>
80104714:	83 c4 10             	add    $0x10,%esp
80104717:	85 c0                	test   %eax,%eax
80104719:	0f 84 e0 00 00 00    	je     801047ff <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
8010471f:	83 ec 04             	sub    $0x4,%esp
80104722:	8d 45 c0             	lea    -0x40(%ebp),%eax
80104725:	50                   	push   %eax
80104726:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104729:	50                   	push   %eax
8010472a:	56                   	push   %esi
8010472b:	e8 80 d2 ff ff       	call   801019b0 <dirlookup>
80104730:	89 c3                	mov    %eax,%ebx
80104732:	83 c4 10             	add    $0x10,%esp
80104735:	85 c0                	test   %eax,%eax
80104737:	0f 84 c2 00 00 00    	je     801047ff <sys_unlink+0x161>
  ilock(ip);
8010473d:	83 ec 0c             	sub    $0xc,%esp
80104740:	50                   	push   %eax
80104741:	e8 3b ce ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
80104746:	83 c4 10             	add    $0x10,%esp
80104749:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
8010474e:	0f 8e 83 00 00 00    	jle    801047d7 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104754:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104759:	0f 84 85 00 00 00    	je     801047e4 <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
8010475f:	83 ec 04             	sub    $0x4,%esp
80104762:	6a 10                	push   $0x10
80104764:	6a 00                	push   $0x0
80104766:	8d 7d d8             	lea    -0x28(%ebp),%edi
80104769:	57                   	push   %edi
8010476a:	e8 3f f6 ff ff       	call   80103dae <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010476f:	6a 10                	push   $0x10
80104771:	ff 75 c0             	pushl  -0x40(%ebp)
80104774:	57                   	push   %edi
80104775:	56                   	push   %esi
80104776:	e8 f5 d0 ff ff       	call   80101870 <writei>
8010477b:	83 c4 20             	add    $0x20,%esp
8010477e:	83 f8 10             	cmp    $0x10,%eax
80104781:	0f 85 90 00 00 00    	jne    80104817 <sys_unlink+0x179>
  if(ip->type == T_DIR){
80104787:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010478c:	0f 84 92 00 00 00    	je     80104824 <sys_unlink+0x186>
  iunlockput(dp);
80104792:	83 ec 0c             	sub    $0xc,%esp
80104795:	56                   	push   %esi
80104796:	e8 8d cf ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
8010479b:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010479f:	83 e8 01             	sub    $0x1,%eax
801047a2:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801047a6:	89 1c 24             	mov    %ebx,(%esp)
801047a9:	e8 72 cc ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
801047ae:	89 1c 24             	mov    %ebx,(%esp)
801047b1:	e8 72 cf ff ff       	call   80101728 <iunlockput>
  end_op();
801047b6:	e8 cf e1 ff ff       	call   8010298a <end_op>
  return 0;
801047bb:	83 c4 10             	add    $0x10,%esp
801047be:	b8 00 00 00 00       	mov    $0x0,%eax
}
801047c3:	8d 65 f4             	lea    -0xc(%ebp),%esp
801047c6:	5b                   	pop    %ebx
801047c7:	5e                   	pop    %esi
801047c8:	5f                   	pop    %edi
801047c9:	5d                   	pop    %ebp
801047ca:	c3                   	ret    
    end_op();
801047cb:	e8 ba e1 ff ff       	call   8010298a <end_op>
    return -1;
801047d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047d5:	eb ec                	jmp    801047c3 <sys_unlink+0x125>
    panic("unlink: nlink < 1");
801047d7:	83 ec 0c             	sub    $0xc,%esp
801047da:	68 bc 6d 10 80       	push   $0x80106dbc
801047df:	e8 64 bb ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801047e4:	89 d8                	mov    %ebx,%eax
801047e6:	e8 c4 f9 ff ff       	call   801041af <isdirempty>
801047eb:	85 c0                	test   %eax,%eax
801047ed:	0f 85 6c ff ff ff    	jne    8010475f <sys_unlink+0xc1>
    iunlockput(ip);
801047f3:	83 ec 0c             	sub    $0xc,%esp
801047f6:	53                   	push   %ebx
801047f7:	e8 2c cf ff ff       	call   80101728 <iunlockput>
    goto bad;
801047fc:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
801047ff:	83 ec 0c             	sub    $0xc,%esp
80104802:	56                   	push   %esi
80104803:	e8 20 cf ff ff       	call   80101728 <iunlockput>
  end_op();
80104808:	e8 7d e1 ff ff       	call   8010298a <end_op>
  return -1;
8010480d:	83 c4 10             	add    $0x10,%esp
80104810:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104815:	eb ac                	jmp    801047c3 <sys_unlink+0x125>
    panic("unlink: writei");
80104817:	83 ec 0c             	sub    $0xc,%esp
8010481a:	68 ce 6d 10 80       	push   $0x80106dce
8010481f:	e8 24 bb ff ff       	call   80100348 <panic>
    dp->nlink--;
80104824:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104828:	83 e8 01             	sub    $0x1,%eax
8010482b:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
8010482f:	83 ec 0c             	sub    $0xc,%esp
80104832:	56                   	push   %esi
80104833:	e8 e8 cb ff ff       	call   80101420 <iupdate>
80104838:	83 c4 10             	add    $0x10,%esp
8010483b:	e9 52 ff ff ff       	jmp    80104792 <sys_unlink+0xf4>
    return -1;
80104840:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104845:	e9 79 ff ff ff       	jmp    801047c3 <sys_unlink+0x125>

8010484a <sys_open>:

int
sys_open(void)
{
8010484a:	55                   	push   %ebp
8010484b:	89 e5                	mov    %esp,%ebp
8010484d:	57                   	push   %edi
8010484e:	56                   	push   %esi
8010484f:	53                   	push   %ebx
80104850:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80104853:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104856:	50                   	push   %eax
80104857:	6a 00                	push   $0x0
80104859:	e8 2b f8 ff ff       	call   80104089 <argstr>
8010485e:	83 c4 10             	add    $0x10,%esp
80104861:	85 c0                	test   %eax,%eax
80104863:	0f 88 30 01 00 00    	js     80104999 <sys_open+0x14f>
80104869:	83 ec 08             	sub    $0x8,%esp
8010486c:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010486f:	50                   	push   %eax
80104870:	6a 01                	push   $0x1
80104872:	e8 82 f7 ff ff       	call   80103ff9 <argint>
80104877:	83 c4 10             	add    $0x10,%esp
8010487a:	85 c0                	test   %eax,%eax
8010487c:	0f 88 21 01 00 00    	js     801049a3 <sys_open+0x159>
    return -1;

  begin_op();
80104882:	e8 89 e0 ff ff       	call   80102910 <begin_op>

  if(omode & O_CREATE){
80104887:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
8010488b:	0f 84 84 00 00 00    	je     80104915 <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
80104891:	83 ec 0c             	sub    $0xc,%esp
80104894:	6a 00                	push   $0x0
80104896:	b9 00 00 00 00       	mov    $0x0,%ecx
8010489b:	ba 02 00 00 00       	mov    $0x2,%edx
801048a0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801048a3:	e8 5e f9 ff ff       	call   80104206 <create>
801048a8:	89 c6                	mov    %eax,%esi
    if(ip == 0){
801048aa:	83 c4 10             	add    $0x10,%esp
801048ad:	85 c0                	test   %eax,%eax
801048af:	74 58                	je     80104909 <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
801048b1:	e8 77 c3 ff ff       	call   80100c2d <filealloc>
801048b6:	89 c3                	mov    %eax,%ebx
801048b8:	85 c0                	test   %eax,%eax
801048ba:	0f 84 ae 00 00 00    	je     8010496e <sys_open+0x124>
801048c0:	e8 b3 f8 ff ff       	call   80104178 <fdalloc>
801048c5:	89 c7                	mov    %eax,%edi
801048c7:	85 c0                	test   %eax,%eax
801048c9:	0f 88 9f 00 00 00    	js     8010496e <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
801048cf:	83 ec 0c             	sub    $0xc,%esp
801048d2:	56                   	push   %esi
801048d3:	e8 6b cd ff ff       	call   80101643 <iunlock>
  end_op();
801048d8:	e8 ad e0 ff ff       	call   8010298a <end_op>

  f->type = FD_INODE;
801048dd:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
801048e3:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
801048e6:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
801048ed:	8b 45 e0             	mov    -0x20(%ebp),%eax
801048f0:	83 c4 10             	add    $0x10,%esp
801048f3:	a8 01                	test   $0x1,%al
801048f5:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
801048f9:	a8 03                	test   $0x3,%al
801048fb:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
801048ff:	89 f8                	mov    %edi,%eax
80104901:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104904:	5b                   	pop    %ebx
80104905:	5e                   	pop    %esi
80104906:	5f                   	pop    %edi
80104907:	5d                   	pop    %ebp
80104908:	c3                   	ret    
      end_op();
80104909:	e8 7c e0 ff ff       	call   8010298a <end_op>
      return -1;
8010490e:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104913:	eb ea                	jmp    801048ff <sys_open+0xb5>
    if((ip = namei(path)) == 0){
80104915:	83 ec 0c             	sub    $0xc,%esp
80104918:	ff 75 e4             	pushl  -0x1c(%ebp)
8010491b:	e8 c1 d2 ff ff       	call   80101be1 <namei>
80104920:	89 c6                	mov    %eax,%esi
80104922:	83 c4 10             	add    $0x10,%esp
80104925:	85 c0                	test   %eax,%eax
80104927:	74 39                	je     80104962 <sys_open+0x118>
    ilock(ip);
80104929:	83 ec 0c             	sub    $0xc,%esp
8010492c:	50                   	push   %eax
8010492d:	e8 4f cc ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80104932:	83 c4 10             	add    $0x10,%esp
80104935:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
8010493a:	0f 85 71 ff ff ff    	jne    801048b1 <sys_open+0x67>
80104940:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104944:	0f 84 67 ff ff ff    	je     801048b1 <sys_open+0x67>
      iunlockput(ip);
8010494a:	83 ec 0c             	sub    $0xc,%esp
8010494d:	56                   	push   %esi
8010494e:	e8 d5 cd ff ff       	call   80101728 <iunlockput>
      end_op();
80104953:	e8 32 e0 ff ff       	call   8010298a <end_op>
      return -1;
80104958:	83 c4 10             	add    $0x10,%esp
8010495b:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104960:	eb 9d                	jmp    801048ff <sys_open+0xb5>
      end_op();
80104962:	e8 23 e0 ff ff       	call   8010298a <end_op>
      return -1;
80104967:	bf ff ff ff ff       	mov    $0xffffffff,%edi
8010496c:	eb 91                	jmp    801048ff <sys_open+0xb5>
    if(f)
8010496e:	85 db                	test   %ebx,%ebx
80104970:	74 0c                	je     8010497e <sys_open+0x134>
      fileclose(f);
80104972:	83 ec 0c             	sub    $0xc,%esp
80104975:	53                   	push   %ebx
80104976:	e8 58 c3 ff ff       	call   80100cd3 <fileclose>
8010497b:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
8010497e:	83 ec 0c             	sub    $0xc,%esp
80104981:	56                   	push   %esi
80104982:	e8 a1 cd ff ff       	call   80101728 <iunlockput>
    end_op();
80104987:	e8 fe df ff ff       	call   8010298a <end_op>
    return -1;
8010498c:	83 c4 10             	add    $0x10,%esp
8010498f:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104994:	e9 66 ff ff ff       	jmp    801048ff <sys_open+0xb5>
    return -1;
80104999:	bf ff ff ff ff       	mov    $0xffffffff,%edi
8010499e:	e9 5c ff ff ff       	jmp    801048ff <sys_open+0xb5>
801049a3:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801049a8:	e9 52 ff ff ff       	jmp    801048ff <sys_open+0xb5>

801049ad <sys_mkdir>:

int
sys_mkdir(void)
{
801049ad:	55                   	push   %ebp
801049ae:	89 e5                	mov    %esp,%ebp
801049b0:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
801049b3:	e8 58 df ff ff       	call   80102910 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
801049b8:	83 ec 08             	sub    $0x8,%esp
801049bb:	8d 45 f4             	lea    -0xc(%ebp),%eax
801049be:	50                   	push   %eax
801049bf:	6a 00                	push   $0x0
801049c1:	e8 c3 f6 ff ff       	call   80104089 <argstr>
801049c6:	83 c4 10             	add    $0x10,%esp
801049c9:	85 c0                	test   %eax,%eax
801049cb:	78 36                	js     80104a03 <sys_mkdir+0x56>
801049cd:	83 ec 0c             	sub    $0xc,%esp
801049d0:	6a 00                	push   $0x0
801049d2:	b9 00 00 00 00       	mov    $0x0,%ecx
801049d7:	ba 01 00 00 00       	mov    $0x1,%edx
801049dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049df:	e8 22 f8 ff ff       	call   80104206 <create>
801049e4:	83 c4 10             	add    $0x10,%esp
801049e7:	85 c0                	test   %eax,%eax
801049e9:	74 18                	je     80104a03 <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
801049eb:	83 ec 0c             	sub    $0xc,%esp
801049ee:	50                   	push   %eax
801049ef:	e8 34 cd ff ff       	call   80101728 <iunlockput>
  end_op();
801049f4:	e8 91 df ff ff       	call   8010298a <end_op>
  return 0;
801049f9:	83 c4 10             	add    $0x10,%esp
801049fc:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a01:	c9                   	leave  
80104a02:	c3                   	ret    
    end_op();
80104a03:	e8 82 df ff ff       	call   8010298a <end_op>
    return -1;
80104a08:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a0d:	eb f2                	jmp    80104a01 <sys_mkdir+0x54>

80104a0f <sys_mknod>:

int
sys_mknod(void)
{
80104a0f:	55                   	push   %ebp
80104a10:	89 e5                	mov    %esp,%ebp
80104a12:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104a15:	e8 f6 de ff ff       	call   80102910 <begin_op>
  if((argstr(0, &path)) < 0 ||
80104a1a:	83 ec 08             	sub    $0x8,%esp
80104a1d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104a20:	50                   	push   %eax
80104a21:	6a 00                	push   $0x0
80104a23:	e8 61 f6 ff ff       	call   80104089 <argstr>
80104a28:	83 c4 10             	add    $0x10,%esp
80104a2b:	85 c0                	test   %eax,%eax
80104a2d:	78 62                	js     80104a91 <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104a2f:	83 ec 08             	sub    $0x8,%esp
80104a32:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104a35:	50                   	push   %eax
80104a36:	6a 01                	push   $0x1
80104a38:	e8 bc f5 ff ff       	call   80103ff9 <argint>
  if((argstr(0, &path)) < 0 ||
80104a3d:	83 c4 10             	add    $0x10,%esp
80104a40:	85 c0                	test   %eax,%eax
80104a42:	78 4d                	js     80104a91 <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104a44:	83 ec 08             	sub    $0x8,%esp
80104a47:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104a4a:	50                   	push   %eax
80104a4b:	6a 02                	push   $0x2
80104a4d:	e8 a7 f5 ff ff       	call   80103ff9 <argint>
     argint(1, &major) < 0 ||
80104a52:	83 c4 10             	add    $0x10,%esp
80104a55:	85 c0                	test   %eax,%eax
80104a57:	78 38                	js     80104a91 <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104a59:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104a5d:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104a61:	83 ec 0c             	sub    $0xc,%esp
80104a64:	50                   	push   %eax
80104a65:	ba 03 00 00 00       	mov    $0x3,%edx
80104a6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a6d:	e8 94 f7 ff ff       	call   80104206 <create>
80104a72:	83 c4 10             	add    $0x10,%esp
80104a75:	85 c0                	test   %eax,%eax
80104a77:	74 18                	je     80104a91 <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104a79:	83 ec 0c             	sub    $0xc,%esp
80104a7c:	50                   	push   %eax
80104a7d:	e8 a6 cc ff ff       	call   80101728 <iunlockput>
  end_op();
80104a82:	e8 03 df ff ff       	call   8010298a <end_op>
  return 0;
80104a87:	83 c4 10             	add    $0x10,%esp
80104a8a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a8f:	c9                   	leave  
80104a90:	c3                   	ret    
    end_op();
80104a91:	e8 f4 de ff ff       	call   8010298a <end_op>
    return -1;
80104a96:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a9b:	eb f2                	jmp    80104a8f <sys_mknod+0x80>

80104a9d <sys_chdir>:

int
sys_chdir(void)
{
80104a9d:	55                   	push   %ebp
80104a9e:	89 e5                	mov    %esp,%ebp
80104aa0:	56                   	push   %esi
80104aa1:	53                   	push   %ebx
80104aa2:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104aa5:	e8 b6 e8 ff ff       	call   80103360 <myproc>
80104aaa:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104aac:	e8 5f de ff ff       	call   80102910 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104ab1:	83 ec 08             	sub    $0x8,%esp
80104ab4:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ab7:	50                   	push   %eax
80104ab8:	6a 00                	push   $0x0
80104aba:	e8 ca f5 ff ff       	call   80104089 <argstr>
80104abf:	83 c4 10             	add    $0x10,%esp
80104ac2:	85 c0                	test   %eax,%eax
80104ac4:	78 52                	js     80104b18 <sys_chdir+0x7b>
80104ac6:	83 ec 0c             	sub    $0xc,%esp
80104ac9:	ff 75 f4             	pushl  -0xc(%ebp)
80104acc:	e8 10 d1 ff ff       	call   80101be1 <namei>
80104ad1:	89 c3                	mov    %eax,%ebx
80104ad3:	83 c4 10             	add    $0x10,%esp
80104ad6:	85 c0                	test   %eax,%eax
80104ad8:	74 3e                	je     80104b18 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104ada:	83 ec 0c             	sub    $0xc,%esp
80104add:	50                   	push   %eax
80104ade:	e8 9e ca ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104ae3:	83 c4 10             	add    $0x10,%esp
80104ae6:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104aeb:	75 37                	jne    80104b24 <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104aed:	83 ec 0c             	sub    $0xc,%esp
80104af0:	53                   	push   %ebx
80104af1:	e8 4d cb ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104af6:	83 c4 04             	add    $0x4,%esp
80104af9:	ff 76 68             	pushl  0x68(%esi)
80104afc:	e8 87 cb ff ff       	call   80101688 <iput>
  end_op();
80104b01:	e8 84 de ff ff       	call   8010298a <end_op>
  curproc->cwd = ip;
80104b06:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104b09:	83 c4 10             	add    $0x10,%esp
80104b0c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104b11:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104b14:	5b                   	pop    %ebx
80104b15:	5e                   	pop    %esi
80104b16:	5d                   	pop    %ebp
80104b17:	c3                   	ret    
    end_op();
80104b18:	e8 6d de ff ff       	call   8010298a <end_op>
    return -1;
80104b1d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b22:	eb ed                	jmp    80104b11 <sys_chdir+0x74>
    iunlockput(ip);
80104b24:	83 ec 0c             	sub    $0xc,%esp
80104b27:	53                   	push   %ebx
80104b28:	e8 fb cb ff ff       	call   80101728 <iunlockput>
    end_op();
80104b2d:	e8 58 de ff ff       	call   8010298a <end_op>
    return -1;
80104b32:	83 c4 10             	add    $0x10,%esp
80104b35:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b3a:	eb d5                	jmp    80104b11 <sys_chdir+0x74>

80104b3c <sys_exec>:

int
sys_exec(void)
{
80104b3c:	55                   	push   %ebp
80104b3d:	89 e5                	mov    %esp,%ebp
80104b3f:	53                   	push   %ebx
80104b40:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104b46:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b49:	50                   	push   %eax
80104b4a:	6a 00                	push   $0x0
80104b4c:	e8 38 f5 ff ff       	call   80104089 <argstr>
80104b51:	83 c4 10             	add    $0x10,%esp
80104b54:	85 c0                	test   %eax,%eax
80104b56:	0f 88 a8 00 00 00    	js     80104c04 <sys_exec+0xc8>
80104b5c:	83 ec 08             	sub    $0x8,%esp
80104b5f:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104b65:	50                   	push   %eax
80104b66:	6a 01                	push   $0x1
80104b68:	e8 8c f4 ff ff       	call   80103ff9 <argint>
80104b6d:	83 c4 10             	add    $0x10,%esp
80104b70:	85 c0                	test   %eax,%eax
80104b72:	0f 88 93 00 00 00    	js     80104c0b <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104b78:	83 ec 04             	sub    $0x4,%esp
80104b7b:	68 80 00 00 00       	push   $0x80
80104b80:	6a 00                	push   $0x0
80104b82:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104b88:	50                   	push   %eax
80104b89:	e8 20 f2 ff ff       	call   80103dae <memset>
80104b8e:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104b91:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104b96:	83 fb 1f             	cmp    $0x1f,%ebx
80104b99:	77 77                	ja     80104c12 <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104b9b:	83 ec 08             	sub    $0x8,%esp
80104b9e:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104ba4:	50                   	push   %eax
80104ba5:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104bab:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104bae:	50                   	push   %eax
80104baf:	e8 c9 f3 ff ff       	call   80103f7d <fetchint>
80104bb4:	83 c4 10             	add    $0x10,%esp
80104bb7:	85 c0                	test   %eax,%eax
80104bb9:	78 5e                	js     80104c19 <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104bbb:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104bc1:	85 c0                	test   %eax,%eax
80104bc3:	74 1d                	je     80104be2 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104bc5:	83 ec 08             	sub    $0x8,%esp
80104bc8:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104bcf:	52                   	push   %edx
80104bd0:	50                   	push   %eax
80104bd1:	e8 e3 f3 ff ff       	call   80103fb9 <fetchstr>
80104bd6:	83 c4 10             	add    $0x10,%esp
80104bd9:	85 c0                	test   %eax,%eax
80104bdb:	78 46                	js     80104c23 <sys_exec+0xe7>
  for(i=0;; i++){
80104bdd:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104be0:	eb b4                	jmp    80104b96 <sys_exec+0x5a>
      argv[i] = 0;
80104be2:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104be9:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104bed:	83 ec 08             	sub    $0x8,%esp
80104bf0:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104bf6:	50                   	push   %eax
80104bf7:	ff 75 f4             	pushl  -0xc(%ebp)
80104bfa:	e8 d3 bc ff ff       	call   801008d2 <exec>
80104bff:	83 c4 10             	add    $0x10,%esp
80104c02:	eb 1a                	jmp    80104c1e <sys_exec+0xe2>
    return -1;
80104c04:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c09:	eb 13                	jmp    80104c1e <sys_exec+0xe2>
80104c0b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c10:	eb 0c                	jmp    80104c1e <sys_exec+0xe2>
      return -1;
80104c12:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c17:	eb 05                	jmp    80104c1e <sys_exec+0xe2>
      return -1;
80104c19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104c1e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104c21:	c9                   	leave  
80104c22:	c3                   	ret    
      return -1;
80104c23:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c28:	eb f4                	jmp    80104c1e <sys_exec+0xe2>

80104c2a <sys_pipe>:

int
sys_pipe(void)
{
80104c2a:	55                   	push   %ebp
80104c2b:	89 e5                	mov    %esp,%ebp
80104c2d:	53                   	push   %ebx
80104c2e:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104c31:	6a 08                	push   $0x8
80104c33:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c36:	50                   	push   %eax
80104c37:	6a 00                	push   $0x0
80104c39:	e8 e3 f3 ff ff       	call   80104021 <argptr>
80104c3e:	83 c4 10             	add    $0x10,%esp
80104c41:	85 c0                	test   %eax,%eax
80104c43:	78 77                	js     80104cbc <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104c45:	83 ec 08             	sub    $0x8,%esp
80104c48:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104c4b:	50                   	push   %eax
80104c4c:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104c4f:	50                   	push   %eax
80104c50:	e8 42 e2 ff ff       	call   80102e97 <pipealloc>
80104c55:	83 c4 10             	add    $0x10,%esp
80104c58:	85 c0                	test   %eax,%eax
80104c5a:	78 67                	js     80104cc3 <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104c5c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104c5f:	e8 14 f5 ff ff       	call   80104178 <fdalloc>
80104c64:	89 c3                	mov    %eax,%ebx
80104c66:	85 c0                	test   %eax,%eax
80104c68:	78 21                	js     80104c8b <sys_pipe+0x61>
80104c6a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104c6d:	e8 06 f5 ff ff       	call   80104178 <fdalloc>
80104c72:	85 c0                	test   %eax,%eax
80104c74:	78 15                	js     80104c8b <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104c76:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c79:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104c7b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104c7e:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104c81:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104c86:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104c89:	c9                   	leave  
80104c8a:	c3                   	ret    
    if(fd0 >= 0)
80104c8b:	85 db                	test   %ebx,%ebx
80104c8d:	78 0d                	js     80104c9c <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104c8f:	e8 cc e6 ff ff       	call   80103360 <myproc>
80104c94:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104c9b:	00 
    fileclose(rf);
80104c9c:	83 ec 0c             	sub    $0xc,%esp
80104c9f:	ff 75 f0             	pushl  -0x10(%ebp)
80104ca2:	e8 2c c0 ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104ca7:	83 c4 04             	add    $0x4,%esp
80104caa:	ff 75 ec             	pushl  -0x14(%ebp)
80104cad:	e8 21 c0 ff ff       	call   80100cd3 <fileclose>
    return -1;
80104cb2:	83 c4 10             	add    $0x10,%esp
80104cb5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cba:	eb ca                	jmp    80104c86 <sys_pipe+0x5c>
    return -1;
80104cbc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cc1:	eb c3                	jmp    80104c86 <sys_pipe+0x5c>
    return -1;
80104cc3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cc8:	eb bc                	jmp    80104c86 <sys_pipe+0x5c>

80104cca <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104cca:	55                   	push   %ebp
80104ccb:	89 e5                	mov    %esp,%ebp
80104ccd:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104cd0:	e8 03 e8 ff ff       	call   801034d8 <fork>
}
80104cd5:	c9                   	leave  
80104cd6:	c3                   	ret    

80104cd7 <sys_exit>:

int
sys_exit(void)
{
80104cd7:	55                   	push   %ebp
80104cd8:	89 e5                	mov    %esp,%ebp
80104cda:	83 ec 08             	sub    $0x8,%esp
  exit();
80104cdd:	e8 2d ea ff ff       	call   8010370f <exit>
  return 0;  // not reached
}
80104ce2:	b8 00 00 00 00       	mov    $0x0,%eax
80104ce7:	c9                   	leave  
80104ce8:	c3                   	ret    

80104ce9 <sys_wait>:

int
sys_wait(void)
{
80104ce9:	55                   	push   %ebp
80104cea:	89 e5                	mov    %esp,%ebp
80104cec:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104cef:	e8 a4 eb ff ff       	call   80103898 <wait>
}
80104cf4:	c9                   	leave  
80104cf5:	c3                   	ret    

80104cf6 <sys_kill>:

int
sys_kill(void)
{
80104cf6:	55                   	push   %ebp
80104cf7:	89 e5                	mov    %esp,%ebp
80104cf9:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104cfc:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104cff:	50                   	push   %eax
80104d00:	6a 00                	push   $0x0
80104d02:	e8 f2 f2 ff ff       	call   80103ff9 <argint>
80104d07:	83 c4 10             	add    $0x10,%esp
80104d0a:	85 c0                	test   %eax,%eax
80104d0c:	78 10                	js     80104d1e <sys_kill+0x28>
    return -1;
  return kill(pid);
80104d0e:	83 ec 0c             	sub    $0xc,%esp
80104d11:	ff 75 f4             	pushl  -0xc(%ebp)
80104d14:	e8 7c ec ff ff       	call   80103995 <kill>
80104d19:	83 c4 10             	add    $0x10,%esp
}
80104d1c:	c9                   	leave  
80104d1d:	c3                   	ret    
    return -1;
80104d1e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d23:	eb f7                	jmp    80104d1c <sys_kill+0x26>

80104d25 <sys_getpid>:

int
sys_getpid(void)
{
80104d25:	55                   	push   %ebp
80104d26:	89 e5                	mov    %esp,%ebp
80104d28:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104d2b:	e8 30 e6 ff ff       	call   80103360 <myproc>
80104d30:	8b 40 10             	mov    0x10(%eax),%eax
}
80104d33:	c9                   	leave  
80104d34:	c3                   	ret    

80104d35 <sys_sbrk>:

int
sys_sbrk(void)
{
80104d35:	55                   	push   %ebp
80104d36:	89 e5                	mov    %esp,%ebp
80104d38:	53                   	push   %ebx
80104d39:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104d3c:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d3f:	50                   	push   %eax
80104d40:	6a 00                	push   $0x0
80104d42:	e8 b2 f2 ff ff       	call   80103ff9 <argint>
80104d47:	83 c4 10             	add    $0x10,%esp
80104d4a:	85 c0                	test   %eax,%eax
80104d4c:	78 27                	js     80104d75 <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104d4e:	e8 0d e6 ff ff       	call   80103360 <myproc>
80104d53:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104d55:	83 ec 0c             	sub    $0xc,%esp
80104d58:	ff 75 f4             	pushl  -0xc(%ebp)
80104d5b:	e8 0b e7 ff ff       	call   8010346b <growproc>
80104d60:	83 c4 10             	add    $0x10,%esp
80104d63:	85 c0                	test   %eax,%eax
80104d65:	78 07                	js     80104d6e <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104d67:	89 d8                	mov    %ebx,%eax
80104d69:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104d6c:	c9                   	leave  
80104d6d:	c3                   	ret    
    return -1;
80104d6e:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104d73:	eb f2                	jmp    80104d67 <sys_sbrk+0x32>
    return -1;
80104d75:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104d7a:	eb eb                	jmp    80104d67 <sys_sbrk+0x32>

80104d7c <sys_sleep>:

int
sys_sleep(void)
{
80104d7c:	55                   	push   %ebp
80104d7d:	89 e5                	mov    %esp,%ebp
80104d7f:	53                   	push   %ebx
80104d80:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104d83:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d86:	50                   	push   %eax
80104d87:	6a 00                	push   $0x0
80104d89:	e8 6b f2 ff ff       	call   80103ff9 <argint>
80104d8e:	83 c4 10             	add    $0x10,%esp
80104d91:	85 c0                	test   %eax,%eax
80104d93:	78 75                	js     80104e0a <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104d95:	83 ec 0c             	sub    $0xc,%esp
80104d98:	68 e0 4c 13 80       	push   $0x80134ce0
80104d9d:	e8 60 ef ff ff       	call   80103d02 <acquire>
  ticks0 = ticks;
80104da2:	8b 1d 20 55 13 80    	mov    0x80135520,%ebx
  while(ticks - ticks0 < n){
80104da8:	83 c4 10             	add    $0x10,%esp
80104dab:	a1 20 55 13 80       	mov    0x80135520,%eax
80104db0:	29 d8                	sub    %ebx,%eax
80104db2:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104db5:	73 39                	jae    80104df0 <sys_sleep+0x74>
    if(myproc()->killed){
80104db7:	e8 a4 e5 ff ff       	call   80103360 <myproc>
80104dbc:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104dc0:	75 17                	jne    80104dd9 <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104dc2:	83 ec 08             	sub    $0x8,%esp
80104dc5:	68 e0 4c 13 80       	push   $0x80134ce0
80104dca:	68 20 55 13 80       	push   $0x80135520
80104dcf:	e8 33 ea ff ff       	call   80103807 <sleep>
80104dd4:	83 c4 10             	add    $0x10,%esp
80104dd7:	eb d2                	jmp    80104dab <sys_sleep+0x2f>
      release(&tickslock);
80104dd9:	83 ec 0c             	sub    $0xc,%esp
80104ddc:	68 e0 4c 13 80       	push   $0x80134ce0
80104de1:	e8 81 ef ff ff       	call   80103d67 <release>
      return -1;
80104de6:	83 c4 10             	add    $0x10,%esp
80104de9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dee:	eb 15                	jmp    80104e05 <sys_sleep+0x89>
  }
  release(&tickslock);
80104df0:	83 ec 0c             	sub    $0xc,%esp
80104df3:	68 e0 4c 13 80       	push   $0x80134ce0
80104df8:	e8 6a ef ff ff       	call   80103d67 <release>
  return 0;
80104dfd:	83 c4 10             	add    $0x10,%esp
80104e00:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e05:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e08:	c9                   	leave  
80104e09:	c3                   	ret    
    return -1;
80104e0a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e0f:	eb f4                	jmp    80104e05 <sys_sleep+0x89>

80104e11 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104e11:	55                   	push   %ebp
80104e12:	89 e5                	mov    %esp,%ebp
80104e14:	53                   	push   %ebx
80104e15:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104e18:	68 e0 4c 13 80       	push   $0x80134ce0
80104e1d:	e8 e0 ee ff ff       	call   80103d02 <acquire>
  xticks = ticks;
80104e22:	8b 1d 20 55 13 80    	mov    0x80135520,%ebx
  release(&tickslock);
80104e28:	c7 04 24 e0 4c 13 80 	movl   $0x80134ce0,(%esp)
80104e2f:	e8 33 ef ff ff       	call   80103d67 <release>
  return xticks;
}
80104e34:	89 d8                	mov    %ebx,%eax
80104e36:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e39:	c9                   	leave  
80104e3a:	c3                   	ret    

80104e3b <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80104e3b:	55                   	push   %ebp
80104e3c:	89 e5                	mov    %esp,%ebp
80104e3e:	83 ec 1c             	sub    $0x1c,%esp
  int *frames;
  int *pids;
  int numframes;
  if(argptr(0, (char**)(&frames), sizeof(*frames)) < 0)
80104e41:	6a 04                	push   $0x4
80104e43:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e46:	50                   	push   %eax
80104e47:	6a 00                	push   $0x0
80104e49:	e8 d3 f1 ff ff       	call   80104021 <argptr>
80104e4e:	83 c4 10             	add    $0x10,%esp
80104e51:	85 c0                	test   %eax,%eax
80104e53:	78 42                	js     80104e97 <sys_dump_physmem+0x5c>
    return -1;
  if(argptr(1, (char**)(&pids), sizeof(*pids)) < 0)
80104e55:	83 ec 04             	sub    $0x4,%esp
80104e58:	6a 04                	push   $0x4
80104e5a:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104e5d:	50                   	push   %eax
80104e5e:	6a 01                	push   $0x1
80104e60:	e8 bc f1 ff ff       	call   80104021 <argptr>
80104e65:	83 c4 10             	add    $0x10,%esp
80104e68:	85 c0                	test   %eax,%eax
80104e6a:	78 32                	js     80104e9e <sys_dump_physmem+0x63>
    return -1;
  if(argint(2, &numframes) < 0)
80104e6c:	83 ec 08             	sub    $0x8,%esp
80104e6f:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104e72:	50                   	push   %eax
80104e73:	6a 02                	push   $0x2
80104e75:	e8 7f f1 ff ff       	call   80103ff9 <argint>
80104e7a:	83 c4 10             	add    $0x10,%esp
80104e7d:	85 c0                	test   %eax,%eax
80104e7f:	78 24                	js     80104ea5 <sys_dump_physmem+0x6a>
    return -1;

  return dump_physmem(frames, pids, numframes);
80104e81:	83 ec 04             	sub    $0x4,%esp
80104e84:	ff 75 ec             	pushl  -0x14(%ebp)
80104e87:	ff 75 f0             	pushl  -0x10(%ebp)
80104e8a:	ff 75 f4             	pushl  -0xc(%ebp)
80104e8d:	e8 7e d3 ff ff       	call   80102210 <dump_physmem>
80104e92:	83 c4 10             	add    $0x10,%esp
80104e95:	c9                   	leave  
80104e96:	c3                   	ret    
    return -1;
80104e97:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e9c:	eb f7                	jmp    80104e95 <sys_dump_physmem+0x5a>
    return -1;
80104e9e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ea3:	eb f0                	jmp    80104e95 <sys_dump_physmem+0x5a>
    return -1;
80104ea5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104eaa:	eb e9                	jmp    80104e95 <sys_dump_physmem+0x5a>

80104eac <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104eac:	1e                   	push   %ds
  pushl %es
80104ead:	06                   	push   %es
  pushl %fs
80104eae:	0f a0                	push   %fs
  pushl %gs
80104eb0:	0f a8                	push   %gs
  pushal
80104eb2:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104eb3:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104eb7:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104eb9:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104ebb:	54                   	push   %esp
  call trap
80104ebc:	e8 e3 00 00 00       	call   80104fa4 <trap>
  addl $4, %esp
80104ec1:	83 c4 04             	add    $0x4,%esp

80104ec4 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104ec4:	61                   	popa   
  popl %gs
80104ec5:	0f a9                	pop    %gs
  popl %fs
80104ec7:	0f a1                	pop    %fs
  popl %es
80104ec9:	07                   	pop    %es
  popl %ds
80104eca:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104ecb:	83 c4 08             	add    $0x8,%esp
  iret
80104ece:	cf                   	iret   

80104ecf <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80104ecf:	55                   	push   %ebp
80104ed0:	89 e5                	mov    %esp,%ebp
80104ed2:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
80104ed5:	b8 00 00 00 00       	mov    $0x0,%eax
80104eda:	eb 4a                	jmp    80104f26 <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104edc:	8b 0c 85 08 a0 10 80 	mov    -0x7fef5ff8(,%eax,4),%ecx
80104ee3:	66 89 0c c5 20 4d 13 	mov    %cx,-0x7fecb2e0(,%eax,8)
80104eea:	80 
80104eeb:	66 c7 04 c5 22 4d 13 	movw   $0x8,-0x7fecb2de(,%eax,8)
80104ef2:	80 08 00 
80104ef5:	c6 04 c5 24 4d 13 80 	movb   $0x0,-0x7fecb2dc(,%eax,8)
80104efc:	00 
80104efd:	0f b6 14 c5 25 4d 13 	movzbl -0x7fecb2db(,%eax,8),%edx
80104f04:	80 
80104f05:	83 e2 f0             	and    $0xfffffff0,%edx
80104f08:	83 ca 0e             	or     $0xe,%edx
80104f0b:	83 e2 8f             	and    $0xffffff8f,%edx
80104f0e:	83 ca 80             	or     $0xffffff80,%edx
80104f11:	88 14 c5 25 4d 13 80 	mov    %dl,-0x7fecb2db(,%eax,8)
80104f18:	c1 e9 10             	shr    $0x10,%ecx
80104f1b:	66 89 0c c5 26 4d 13 	mov    %cx,-0x7fecb2da(,%eax,8)
80104f22:	80 
  for(i = 0; i < 256; i++)
80104f23:	83 c0 01             	add    $0x1,%eax
80104f26:	3d ff 00 00 00       	cmp    $0xff,%eax
80104f2b:	7e af                	jle    80104edc <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80104f2d:	8b 15 08 a1 10 80    	mov    0x8010a108,%edx
80104f33:	66 89 15 20 4f 13 80 	mov    %dx,0x80134f20
80104f3a:	66 c7 05 22 4f 13 80 	movw   $0x8,0x80134f22
80104f41:	08 00 
80104f43:	c6 05 24 4f 13 80 00 	movb   $0x0,0x80134f24
80104f4a:	0f b6 05 25 4f 13 80 	movzbl 0x80134f25,%eax
80104f51:	83 c8 0f             	or     $0xf,%eax
80104f54:	83 e0 ef             	and    $0xffffffef,%eax
80104f57:	83 c8 e0             	or     $0xffffffe0,%eax
80104f5a:	a2 25 4f 13 80       	mov    %al,0x80134f25
80104f5f:	c1 ea 10             	shr    $0x10,%edx
80104f62:	66 89 15 26 4f 13 80 	mov    %dx,0x80134f26

  initlock(&tickslock, "time");
80104f69:	83 ec 08             	sub    $0x8,%esp
80104f6c:	68 dd 6d 10 80       	push   $0x80106ddd
80104f71:	68 e0 4c 13 80       	push   $0x80134ce0
80104f76:	e8 4b ec ff ff       	call   80103bc6 <initlock>
}
80104f7b:	83 c4 10             	add    $0x10,%esp
80104f7e:	c9                   	leave  
80104f7f:	c3                   	ret    

80104f80 <idtinit>:

void
idtinit(void)
{
80104f80:	55                   	push   %ebp
80104f81:	89 e5                	mov    %esp,%ebp
80104f83:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80104f86:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80104f8c:	b8 20 4d 13 80       	mov    $0x80134d20,%eax
80104f91:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80104f95:	c1 e8 10             	shr    $0x10,%eax
80104f98:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
80104f9c:	8d 45 fa             	lea    -0x6(%ebp),%eax
80104f9f:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80104fa2:	c9                   	leave  
80104fa3:	c3                   	ret    

80104fa4 <trap>:

void
trap(struct trapframe *tf)
{
80104fa4:	55                   	push   %ebp
80104fa5:	89 e5                	mov    %esp,%ebp
80104fa7:	57                   	push   %edi
80104fa8:	56                   	push   %esi
80104fa9:	53                   	push   %ebx
80104faa:	83 ec 1c             	sub    $0x1c,%esp
80104fad:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80104fb0:	8b 43 30             	mov    0x30(%ebx),%eax
80104fb3:	83 f8 40             	cmp    $0x40,%eax
80104fb6:	74 13                	je     80104fcb <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
80104fb8:	83 e8 20             	sub    $0x20,%eax
80104fbb:	83 f8 1f             	cmp    $0x1f,%eax
80104fbe:	0f 87 3a 01 00 00    	ja     801050fe <trap+0x15a>
80104fc4:	ff 24 85 84 6e 10 80 	jmp    *-0x7fef917c(,%eax,4)
    if(myproc()->killed)
80104fcb:	e8 90 e3 ff ff       	call   80103360 <myproc>
80104fd0:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104fd4:	75 1f                	jne    80104ff5 <trap+0x51>
    myproc()->tf = tf;
80104fd6:	e8 85 e3 ff ff       	call   80103360 <myproc>
80104fdb:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80104fde:	e8 d9 f0 ff ff       	call   801040bc <syscall>
    if(myproc()->killed)
80104fe3:	e8 78 e3 ff ff       	call   80103360 <myproc>
80104fe8:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104fec:	74 7e                	je     8010506c <trap+0xc8>
      exit();
80104fee:	e8 1c e7 ff ff       	call   8010370f <exit>
80104ff3:	eb 77                	jmp    8010506c <trap+0xc8>
      exit();
80104ff5:	e8 15 e7 ff ff       	call   8010370f <exit>
80104ffa:	eb da                	jmp    80104fd6 <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80104ffc:	e8 44 e3 ff ff       	call   80103345 <cpuid>
80105001:	85 c0                	test   %eax,%eax
80105003:	74 6f                	je     80105074 <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
80105005:	e8 f1 d4 ff ff       	call   801024fb <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
8010500a:	e8 51 e3 ff ff       	call   80103360 <myproc>
8010500f:	85 c0                	test   %eax,%eax
80105011:	74 1c                	je     8010502f <trap+0x8b>
80105013:	e8 48 e3 ff ff       	call   80103360 <myproc>
80105018:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010501c:	74 11                	je     8010502f <trap+0x8b>
8010501e:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105022:	83 e0 03             	and    $0x3,%eax
80105025:	66 83 f8 03          	cmp    $0x3,%ax
80105029:	0f 84 62 01 00 00    	je     80105191 <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
8010502f:	e8 2c e3 ff ff       	call   80103360 <myproc>
80105034:	85 c0                	test   %eax,%eax
80105036:	74 0f                	je     80105047 <trap+0xa3>
80105038:	e8 23 e3 ff ff       	call   80103360 <myproc>
8010503d:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80105041:	0f 84 54 01 00 00    	je     8010519b <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105047:	e8 14 e3 ff ff       	call   80103360 <myproc>
8010504c:	85 c0                	test   %eax,%eax
8010504e:	74 1c                	je     8010506c <trap+0xc8>
80105050:	e8 0b e3 ff ff       	call   80103360 <myproc>
80105055:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105059:	74 11                	je     8010506c <trap+0xc8>
8010505b:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
8010505f:	83 e0 03             	and    $0x3,%eax
80105062:	66 83 f8 03          	cmp    $0x3,%ax
80105066:	0f 84 43 01 00 00    	je     801051af <trap+0x20b>
    exit();
}
8010506c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010506f:	5b                   	pop    %ebx
80105070:	5e                   	pop    %esi
80105071:	5f                   	pop    %edi
80105072:	5d                   	pop    %ebp
80105073:	c3                   	ret    
      acquire(&tickslock);
80105074:	83 ec 0c             	sub    $0xc,%esp
80105077:	68 e0 4c 13 80       	push   $0x80134ce0
8010507c:	e8 81 ec ff ff       	call   80103d02 <acquire>
      ticks++;
80105081:	83 05 20 55 13 80 01 	addl   $0x1,0x80135520
      wakeup(&ticks);
80105088:	c7 04 24 20 55 13 80 	movl   $0x80135520,(%esp)
8010508f:	e8 d8 e8 ff ff       	call   8010396c <wakeup>
      release(&tickslock);
80105094:	c7 04 24 e0 4c 13 80 	movl   $0x80134ce0,(%esp)
8010509b:	e8 c7 ec ff ff       	call   80103d67 <release>
801050a0:	83 c4 10             	add    $0x10,%esp
801050a3:	e9 5d ff ff ff       	jmp    80105005 <trap+0x61>
    ideintr();
801050a8:	e8 c6 cc ff ff       	call   80101d73 <ideintr>
    lapiceoi();
801050ad:	e8 49 d4 ff ff       	call   801024fb <lapiceoi>
    break;
801050b2:	e9 53 ff ff ff       	jmp    8010500a <trap+0x66>
    kbdintr();
801050b7:	e8 83 d2 ff ff       	call   8010233f <kbdintr>
    lapiceoi();
801050bc:	e8 3a d4 ff ff       	call   801024fb <lapiceoi>
    break;
801050c1:	e9 44 ff ff ff       	jmp    8010500a <trap+0x66>
    uartintr();
801050c6:	e8 05 02 00 00       	call   801052d0 <uartintr>
    lapiceoi();
801050cb:	e8 2b d4 ff ff       	call   801024fb <lapiceoi>
    break;
801050d0:	e9 35 ff ff ff       	jmp    8010500a <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801050d5:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
801050d8:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801050dc:	e8 64 e2 ff ff       	call   80103345 <cpuid>
801050e1:	57                   	push   %edi
801050e2:	0f b7 f6             	movzwl %si,%esi
801050e5:	56                   	push   %esi
801050e6:	50                   	push   %eax
801050e7:	68 e8 6d 10 80       	push   $0x80106de8
801050ec:	e8 1a b5 ff ff       	call   8010060b <cprintf>
    lapiceoi();
801050f1:	e8 05 d4 ff ff       	call   801024fb <lapiceoi>
    break;
801050f6:	83 c4 10             	add    $0x10,%esp
801050f9:	e9 0c ff ff ff       	jmp    8010500a <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
801050fe:	e8 5d e2 ff ff       	call   80103360 <myproc>
80105103:	85 c0                	test   %eax,%eax
80105105:	74 5f                	je     80105166 <trap+0x1c2>
80105107:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
8010510b:	74 59                	je     80105166 <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
8010510d:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105110:	8b 43 38             	mov    0x38(%ebx),%eax
80105113:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105116:	e8 2a e2 ff ff       	call   80103345 <cpuid>
8010511b:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010511e:	8b 53 34             	mov    0x34(%ebx),%edx
80105121:	89 55 dc             	mov    %edx,-0x24(%ebp)
80105124:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
80105127:	e8 34 e2 ff ff       	call   80103360 <myproc>
8010512c:	8d 48 6c             	lea    0x6c(%eax),%ecx
8010512f:	89 4d d8             	mov    %ecx,-0x28(%ebp)
80105132:	e8 29 e2 ff ff       	call   80103360 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105137:	57                   	push   %edi
80105138:	ff 75 e4             	pushl  -0x1c(%ebp)
8010513b:	ff 75 e0             	pushl  -0x20(%ebp)
8010513e:	ff 75 dc             	pushl  -0x24(%ebp)
80105141:	56                   	push   %esi
80105142:	ff 75 d8             	pushl  -0x28(%ebp)
80105145:	ff 70 10             	pushl  0x10(%eax)
80105148:	68 40 6e 10 80       	push   $0x80106e40
8010514d:	e8 b9 b4 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
80105152:	83 c4 20             	add    $0x20,%esp
80105155:	e8 06 e2 ff ff       	call   80103360 <myproc>
8010515a:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80105161:	e9 a4 fe ff ff       	jmp    8010500a <trap+0x66>
80105166:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80105169:	8b 73 38             	mov    0x38(%ebx),%esi
8010516c:	e8 d4 e1 ff ff       	call   80103345 <cpuid>
80105171:	83 ec 0c             	sub    $0xc,%esp
80105174:	57                   	push   %edi
80105175:	56                   	push   %esi
80105176:	50                   	push   %eax
80105177:	ff 73 30             	pushl  0x30(%ebx)
8010517a:	68 0c 6e 10 80       	push   $0x80106e0c
8010517f:	e8 87 b4 ff ff       	call   8010060b <cprintf>
      panic("trap");
80105184:	83 c4 14             	add    $0x14,%esp
80105187:	68 e2 6d 10 80       	push   $0x80106de2
8010518c:	e8 b7 b1 ff ff       	call   80100348 <panic>
    exit();
80105191:	e8 79 e5 ff ff       	call   8010370f <exit>
80105196:	e9 94 fe ff ff       	jmp    8010502f <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
8010519b:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
8010519f:	0f 85 a2 fe ff ff    	jne    80105047 <trap+0xa3>
    yield();
801051a5:	e8 2b e6 ff ff       	call   801037d5 <yield>
801051aa:	e9 98 fe ff ff       	jmp    80105047 <trap+0xa3>
    exit();
801051af:	e8 5b e5 ff ff       	call   8010370f <exit>
801051b4:	e9 b3 fe ff ff       	jmp    8010506c <trap+0xc8>

801051b9 <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
801051b9:	55                   	push   %ebp
801051ba:	89 e5                	mov    %esp,%ebp
  if(!uart)
801051bc:	83 3d c0 a5 10 80 00 	cmpl   $0x0,0x8010a5c0
801051c3:	74 15                	je     801051da <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801051c5:	ba fd 03 00 00       	mov    $0x3fd,%edx
801051ca:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
801051cb:	a8 01                	test   $0x1,%al
801051cd:	74 12                	je     801051e1 <uartgetc+0x28>
801051cf:	ba f8 03 00 00       	mov    $0x3f8,%edx
801051d4:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
801051d5:	0f b6 c0             	movzbl %al,%eax
}
801051d8:	5d                   	pop    %ebp
801051d9:	c3                   	ret    
    return -1;
801051da:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051df:	eb f7                	jmp    801051d8 <uartgetc+0x1f>
    return -1;
801051e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051e6:	eb f0                	jmp    801051d8 <uartgetc+0x1f>

801051e8 <uartputc>:
  if(!uart)
801051e8:	83 3d c0 a5 10 80 00 	cmpl   $0x0,0x8010a5c0
801051ef:	74 3b                	je     8010522c <uartputc+0x44>
{
801051f1:	55                   	push   %ebp
801051f2:	89 e5                	mov    %esp,%ebp
801051f4:	53                   	push   %ebx
801051f5:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801051f8:	bb 00 00 00 00       	mov    $0x0,%ebx
801051fd:	eb 10                	jmp    8010520f <uartputc+0x27>
    microdelay(10);
801051ff:	83 ec 0c             	sub    $0xc,%esp
80105202:	6a 0a                	push   $0xa
80105204:	e8 11 d3 ff ff       	call   8010251a <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105209:	83 c3 01             	add    $0x1,%ebx
8010520c:	83 c4 10             	add    $0x10,%esp
8010520f:	83 fb 7f             	cmp    $0x7f,%ebx
80105212:	7f 0a                	jg     8010521e <uartputc+0x36>
80105214:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105219:	ec                   	in     (%dx),%al
8010521a:	a8 20                	test   $0x20,%al
8010521c:	74 e1                	je     801051ff <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010521e:	8b 45 08             	mov    0x8(%ebp),%eax
80105221:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105226:	ee                   	out    %al,(%dx)
}
80105227:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010522a:	c9                   	leave  
8010522b:	c3                   	ret    
8010522c:	f3 c3                	repz ret 

8010522e <uartinit>:
{
8010522e:	55                   	push   %ebp
8010522f:	89 e5                	mov    %esp,%ebp
80105231:	56                   	push   %esi
80105232:	53                   	push   %ebx
80105233:	b9 00 00 00 00       	mov    $0x0,%ecx
80105238:	ba fa 03 00 00       	mov    $0x3fa,%edx
8010523d:	89 c8                	mov    %ecx,%eax
8010523f:	ee                   	out    %al,(%dx)
80105240:	be fb 03 00 00       	mov    $0x3fb,%esi
80105245:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
8010524a:	89 f2                	mov    %esi,%edx
8010524c:	ee                   	out    %al,(%dx)
8010524d:	b8 0c 00 00 00       	mov    $0xc,%eax
80105252:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105257:	ee                   	out    %al,(%dx)
80105258:	bb f9 03 00 00       	mov    $0x3f9,%ebx
8010525d:	89 c8                	mov    %ecx,%eax
8010525f:	89 da                	mov    %ebx,%edx
80105261:	ee                   	out    %al,(%dx)
80105262:	b8 03 00 00 00       	mov    $0x3,%eax
80105267:	89 f2                	mov    %esi,%edx
80105269:	ee                   	out    %al,(%dx)
8010526a:	ba fc 03 00 00       	mov    $0x3fc,%edx
8010526f:	89 c8                	mov    %ecx,%eax
80105271:	ee                   	out    %al,(%dx)
80105272:	b8 01 00 00 00       	mov    $0x1,%eax
80105277:	89 da                	mov    %ebx,%edx
80105279:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010527a:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010527f:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
80105280:	3c ff                	cmp    $0xff,%al
80105282:	74 45                	je     801052c9 <uartinit+0x9b>
  uart = 1;
80105284:	c7 05 c0 a5 10 80 01 	movl   $0x1,0x8010a5c0
8010528b:	00 00 00 
8010528e:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105293:	ec                   	in     (%dx),%al
80105294:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105299:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
8010529a:	83 ec 08             	sub    $0x8,%esp
8010529d:	6a 00                	push   $0x0
8010529f:	6a 04                	push   $0x4
801052a1:	e8 d8 cc ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
801052a6:	83 c4 10             	add    $0x10,%esp
801052a9:	bb 04 6f 10 80       	mov    $0x80106f04,%ebx
801052ae:	eb 12                	jmp    801052c2 <uartinit+0x94>
    uartputc(*p);
801052b0:	83 ec 0c             	sub    $0xc,%esp
801052b3:	0f be c0             	movsbl %al,%eax
801052b6:	50                   	push   %eax
801052b7:	e8 2c ff ff ff       	call   801051e8 <uartputc>
  for(p="xv6...\n"; *p; p++)
801052bc:	83 c3 01             	add    $0x1,%ebx
801052bf:	83 c4 10             	add    $0x10,%esp
801052c2:	0f b6 03             	movzbl (%ebx),%eax
801052c5:	84 c0                	test   %al,%al
801052c7:	75 e7                	jne    801052b0 <uartinit+0x82>
}
801052c9:	8d 65 f8             	lea    -0x8(%ebp),%esp
801052cc:	5b                   	pop    %ebx
801052cd:	5e                   	pop    %esi
801052ce:	5d                   	pop    %ebp
801052cf:	c3                   	ret    

801052d0 <uartintr>:

void
uartintr(void)
{
801052d0:	55                   	push   %ebp
801052d1:	89 e5                	mov    %esp,%ebp
801052d3:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
801052d6:	68 b9 51 10 80       	push   $0x801051b9
801052db:	e8 5e b4 ff ff       	call   8010073e <consoleintr>
}
801052e0:	83 c4 10             	add    $0x10,%esp
801052e3:	c9                   	leave  
801052e4:	c3                   	ret    

801052e5 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801052e5:	6a 00                	push   $0x0
  pushl $0
801052e7:	6a 00                	push   $0x0
  jmp alltraps
801052e9:	e9 be fb ff ff       	jmp    80104eac <alltraps>

801052ee <vector1>:
.globl vector1
vector1:
  pushl $0
801052ee:	6a 00                	push   $0x0
  pushl $1
801052f0:	6a 01                	push   $0x1
  jmp alltraps
801052f2:	e9 b5 fb ff ff       	jmp    80104eac <alltraps>

801052f7 <vector2>:
.globl vector2
vector2:
  pushl $0
801052f7:	6a 00                	push   $0x0
  pushl $2
801052f9:	6a 02                	push   $0x2
  jmp alltraps
801052fb:	e9 ac fb ff ff       	jmp    80104eac <alltraps>

80105300 <vector3>:
.globl vector3
vector3:
  pushl $0
80105300:	6a 00                	push   $0x0
  pushl $3
80105302:	6a 03                	push   $0x3
  jmp alltraps
80105304:	e9 a3 fb ff ff       	jmp    80104eac <alltraps>

80105309 <vector4>:
.globl vector4
vector4:
  pushl $0
80105309:	6a 00                	push   $0x0
  pushl $4
8010530b:	6a 04                	push   $0x4
  jmp alltraps
8010530d:	e9 9a fb ff ff       	jmp    80104eac <alltraps>

80105312 <vector5>:
.globl vector5
vector5:
  pushl $0
80105312:	6a 00                	push   $0x0
  pushl $5
80105314:	6a 05                	push   $0x5
  jmp alltraps
80105316:	e9 91 fb ff ff       	jmp    80104eac <alltraps>

8010531b <vector6>:
.globl vector6
vector6:
  pushl $0
8010531b:	6a 00                	push   $0x0
  pushl $6
8010531d:	6a 06                	push   $0x6
  jmp alltraps
8010531f:	e9 88 fb ff ff       	jmp    80104eac <alltraps>

80105324 <vector7>:
.globl vector7
vector7:
  pushl $0
80105324:	6a 00                	push   $0x0
  pushl $7
80105326:	6a 07                	push   $0x7
  jmp alltraps
80105328:	e9 7f fb ff ff       	jmp    80104eac <alltraps>

8010532d <vector8>:
.globl vector8
vector8:
  pushl $8
8010532d:	6a 08                	push   $0x8
  jmp alltraps
8010532f:	e9 78 fb ff ff       	jmp    80104eac <alltraps>

80105334 <vector9>:
.globl vector9
vector9:
  pushl $0
80105334:	6a 00                	push   $0x0
  pushl $9
80105336:	6a 09                	push   $0x9
  jmp alltraps
80105338:	e9 6f fb ff ff       	jmp    80104eac <alltraps>

8010533d <vector10>:
.globl vector10
vector10:
  pushl $10
8010533d:	6a 0a                	push   $0xa
  jmp alltraps
8010533f:	e9 68 fb ff ff       	jmp    80104eac <alltraps>

80105344 <vector11>:
.globl vector11
vector11:
  pushl $11
80105344:	6a 0b                	push   $0xb
  jmp alltraps
80105346:	e9 61 fb ff ff       	jmp    80104eac <alltraps>

8010534b <vector12>:
.globl vector12
vector12:
  pushl $12
8010534b:	6a 0c                	push   $0xc
  jmp alltraps
8010534d:	e9 5a fb ff ff       	jmp    80104eac <alltraps>

80105352 <vector13>:
.globl vector13
vector13:
  pushl $13
80105352:	6a 0d                	push   $0xd
  jmp alltraps
80105354:	e9 53 fb ff ff       	jmp    80104eac <alltraps>

80105359 <vector14>:
.globl vector14
vector14:
  pushl $14
80105359:	6a 0e                	push   $0xe
  jmp alltraps
8010535b:	e9 4c fb ff ff       	jmp    80104eac <alltraps>

80105360 <vector15>:
.globl vector15
vector15:
  pushl $0
80105360:	6a 00                	push   $0x0
  pushl $15
80105362:	6a 0f                	push   $0xf
  jmp alltraps
80105364:	e9 43 fb ff ff       	jmp    80104eac <alltraps>

80105369 <vector16>:
.globl vector16
vector16:
  pushl $0
80105369:	6a 00                	push   $0x0
  pushl $16
8010536b:	6a 10                	push   $0x10
  jmp alltraps
8010536d:	e9 3a fb ff ff       	jmp    80104eac <alltraps>

80105372 <vector17>:
.globl vector17
vector17:
  pushl $17
80105372:	6a 11                	push   $0x11
  jmp alltraps
80105374:	e9 33 fb ff ff       	jmp    80104eac <alltraps>

80105379 <vector18>:
.globl vector18
vector18:
  pushl $0
80105379:	6a 00                	push   $0x0
  pushl $18
8010537b:	6a 12                	push   $0x12
  jmp alltraps
8010537d:	e9 2a fb ff ff       	jmp    80104eac <alltraps>

80105382 <vector19>:
.globl vector19
vector19:
  pushl $0
80105382:	6a 00                	push   $0x0
  pushl $19
80105384:	6a 13                	push   $0x13
  jmp alltraps
80105386:	e9 21 fb ff ff       	jmp    80104eac <alltraps>

8010538b <vector20>:
.globl vector20
vector20:
  pushl $0
8010538b:	6a 00                	push   $0x0
  pushl $20
8010538d:	6a 14                	push   $0x14
  jmp alltraps
8010538f:	e9 18 fb ff ff       	jmp    80104eac <alltraps>

80105394 <vector21>:
.globl vector21
vector21:
  pushl $0
80105394:	6a 00                	push   $0x0
  pushl $21
80105396:	6a 15                	push   $0x15
  jmp alltraps
80105398:	e9 0f fb ff ff       	jmp    80104eac <alltraps>

8010539d <vector22>:
.globl vector22
vector22:
  pushl $0
8010539d:	6a 00                	push   $0x0
  pushl $22
8010539f:	6a 16                	push   $0x16
  jmp alltraps
801053a1:	e9 06 fb ff ff       	jmp    80104eac <alltraps>

801053a6 <vector23>:
.globl vector23
vector23:
  pushl $0
801053a6:	6a 00                	push   $0x0
  pushl $23
801053a8:	6a 17                	push   $0x17
  jmp alltraps
801053aa:	e9 fd fa ff ff       	jmp    80104eac <alltraps>

801053af <vector24>:
.globl vector24
vector24:
  pushl $0
801053af:	6a 00                	push   $0x0
  pushl $24
801053b1:	6a 18                	push   $0x18
  jmp alltraps
801053b3:	e9 f4 fa ff ff       	jmp    80104eac <alltraps>

801053b8 <vector25>:
.globl vector25
vector25:
  pushl $0
801053b8:	6a 00                	push   $0x0
  pushl $25
801053ba:	6a 19                	push   $0x19
  jmp alltraps
801053bc:	e9 eb fa ff ff       	jmp    80104eac <alltraps>

801053c1 <vector26>:
.globl vector26
vector26:
  pushl $0
801053c1:	6a 00                	push   $0x0
  pushl $26
801053c3:	6a 1a                	push   $0x1a
  jmp alltraps
801053c5:	e9 e2 fa ff ff       	jmp    80104eac <alltraps>

801053ca <vector27>:
.globl vector27
vector27:
  pushl $0
801053ca:	6a 00                	push   $0x0
  pushl $27
801053cc:	6a 1b                	push   $0x1b
  jmp alltraps
801053ce:	e9 d9 fa ff ff       	jmp    80104eac <alltraps>

801053d3 <vector28>:
.globl vector28
vector28:
  pushl $0
801053d3:	6a 00                	push   $0x0
  pushl $28
801053d5:	6a 1c                	push   $0x1c
  jmp alltraps
801053d7:	e9 d0 fa ff ff       	jmp    80104eac <alltraps>

801053dc <vector29>:
.globl vector29
vector29:
  pushl $0
801053dc:	6a 00                	push   $0x0
  pushl $29
801053de:	6a 1d                	push   $0x1d
  jmp alltraps
801053e0:	e9 c7 fa ff ff       	jmp    80104eac <alltraps>

801053e5 <vector30>:
.globl vector30
vector30:
  pushl $0
801053e5:	6a 00                	push   $0x0
  pushl $30
801053e7:	6a 1e                	push   $0x1e
  jmp alltraps
801053e9:	e9 be fa ff ff       	jmp    80104eac <alltraps>

801053ee <vector31>:
.globl vector31
vector31:
  pushl $0
801053ee:	6a 00                	push   $0x0
  pushl $31
801053f0:	6a 1f                	push   $0x1f
  jmp alltraps
801053f2:	e9 b5 fa ff ff       	jmp    80104eac <alltraps>

801053f7 <vector32>:
.globl vector32
vector32:
  pushl $0
801053f7:	6a 00                	push   $0x0
  pushl $32
801053f9:	6a 20                	push   $0x20
  jmp alltraps
801053fb:	e9 ac fa ff ff       	jmp    80104eac <alltraps>

80105400 <vector33>:
.globl vector33
vector33:
  pushl $0
80105400:	6a 00                	push   $0x0
  pushl $33
80105402:	6a 21                	push   $0x21
  jmp alltraps
80105404:	e9 a3 fa ff ff       	jmp    80104eac <alltraps>

80105409 <vector34>:
.globl vector34
vector34:
  pushl $0
80105409:	6a 00                	push   $0x0
  pushl $34
8010540b:	6a 22                	push   $0x22
  jmp alltraps
8010540d:	e9 9a fa ff ff       	jmp    80104eac <alltraps>

80105412 <vector35>:
.globl vector35
vector35:
  pushl $0
80105412:	6a 00                	push   $0x0
  pushl $35
80105414:	6a 23                	push   $0x23
  jmp alltraps
80105416:	e9 91 fa ff ff       	jmp    80104eac <alltraps>

8010541b <vector36>:
.globl vector36
vector36:
  pushl $0
8010541b:	6a 00                	push   $0x0
  pushl $36
8010541d:	6a 24                	push   $0x24
  jmp alltraps
8010541f:	e9 88 fa ff ff       	jmp    80104eac <alltraps>

80105424 <vector37>:
.globl vector37
vector37:
  pushl $0
80105424:	6a 00                	push   $0x0
  pushl $37
80105426:	6a 25                	push   $0x25
  jmp alltraps
80105428:	e9 7f fa ff ff       	jmp    80104eac <alltraps>

8010542d <vector38>:
.globl vector38
vector38:
  pushl $0
8010542d:	6a 00                	push   $0x0
  pushl $38
8010542f:	6a 26                	push   $0x26
  jmp alltraps
80105431:	e9 76 fa ff ff       	jmp    80104eac <alltraps>

80105436 <vector39>:
.globl vector39
vector39:
  pushl $0
80105436:	6a 00                	push   $0x0
  pushl $39
80105438:	6a 27                	push   $0x27
  jmp alltraps
8010543a:	e9 6d fa ff ff       	jmp    80104eac <alltraps>

8010543f <vector40>:
.globl vector40
vector40:
  pushl $0
8010543f:	6a 00                	push   $0x0
  pushl $40
80105441:	6a 28                	push   $0x28
  jmp alltraps
80105443:	e9 64 fa ff ff       	jmp    80104eac <alltraps>

80105448 <vector41>:
.globl vector41
vector41:
  pushl $0
80105448:	6a 00                	push   $0x0
  pushl $41
8010544a:	6a 29                	push   $0x29
  jmp alltraps
8010544c:	e9 5b fa ff ff       	jmp    80104eac <alltraps>

80105451 <vector42>:
.globl vector42
vector42:
  pushl $0
80105451:	6a 00                	push   $0x0
  pushl $42
80105453:	6a 2a                	push   $0x2a
  jmp alltraps
80105455:	e9 52 fa ff ff       	jmp    80104eac <alltraps>

8010545a <vector43>:
.globl vector43
vector43:
  pushl $0
8010545a:	6a 00                	push   $0x0
  pushl $43
8010545c:	6a 2b                	push   $0x2b
  jmp alltraps
8010545e:	e9 49 fa ff ff       	jmp    80104eac <alltraps>

80105463 <vector44>:
.globl vector44
vector44:
  pushl $0
80105463:	6a 00                	push   $0x0
  pushl $44
80105465:	6a 2c                	push   $0x2c
  jmp alltraps
80105467:	e9 40 fa ff ff       	jmp    80104eac <alltraps>

8010546c <vector45>:
.globl vector45
vector45:
  pushl $0
8010546c:	6a 00                	push   $0x0
  pushl $45
8010546e:	6a 2d                	push   $0x2d
  jmp alltraps
80105470:	e9 37 fa ff ff       	jmp    80104eac <alltraps>

80105475 <vector46>:
.globl vector46
vector46:
  pushl $0
80105475:	6a 00                	push   $0x0
  pushl $46
80105477:	6a 2e                	push   $0x2e
  jmp alltraps
80105479:	e9 2e fa ff ff       	jmp    80104eac <alltraps>

8010547e <vector47>:
.globl vector47
vector47:
  pushl $0
8010547e:	6a 00                	push   $0x0
  pushl $47
80105480:	6a 2f                	push   $0x2f
  jmp alltraps
80105482:	e9 25 fa ff ff       	jmp    80104eac <alltraps>

80105487 <vector48>:
.globl vector48
vector48:
  pushl $0
80105487:	6a 00                	push   $0x0
  pushl $48
80105489:	6a 30                	push   $0x30
  jmp alltraps
8010548b:	e9 1c fa ff ff       	jmp    80104eac <alltraps>

80105490 <vector49>:
.globl vector49
vector49:
  pushl $0
80105490:	6a 00                	push   $0x0
  pushl $49
80105492:	6a 31                	push   $0x31
  jmp alltraps
80105494:	e9 13 fa ff ff       	jmp    80104eac <alltraps>

80105499 <vector50>:
.globl vector50
vector50:
  pushl $0
80105499:	6a 00                	push   $0x0
  pushl $50
8010549b:	6a 32                	push   $0x32
  jmp alltraps
8010549d:	e9 0a fa ff ff       	jmp    80104eac <alltraps>

801054a2 <vector51>:
.globl vector51
vector51:
  pushl $0
801054a2:	6a 00                	push   $0x0
  pushl $51
801054a4:	6a 33                	push   $0x33
  jmp alltraps
801054a6:	e9 01 fa ff ff       	jmp    80104eac <alltraps>

801054ab <vector52>:
.globl vector52
vector52:
  pushl $0
801054ab:	6a 00                	push   $0x0
  pushl $52
801054ad:	6a 34                	push   $0x34
  jmp alltraps
801054af:	e9 f8 f9 ff ff       	jmp    80104eac <alltraps>

801054b4 <vector53>:
.globl vector53
vector53:
  pushl $0
801054b4:	6a 00                	push   $0x0
  pushl $53
801054b6:	6a 35                	push   $0x35
  jmp alltraps
801054b8:	e9 ef f9 ff ff       	jmp    80104eac <alltraps>

801054bd <vector54>:
.globl vector54
vector54:
  pushl $0
801054bd:	6a 00                	push   $0x0
  pushl $54
801054bf:	6a 36                	push   $0x36
  jmp alltraps
801054c1:	e9 e6 f9 ff ff       	jmp    80104eac <alltraps>

801054c6 <vector55>:
.globl vector55
vector55:
  pushl $0
801054c6:	6a 00                	push   $0x0
  pushl $55
801054c8:	6a 37                	push   $0x37
  jmp alltraps
801054ca:	e9 dd f9 ff ff       	jmp    80104eac <alltraps>

801054cf <vector56>:
.globl vector56
vector56:
  pushl $0
801054cf:	6a 00                	push   $0x0
  pushl $56
801054d1:	6a 38                	push   $0x38
  jmp alltraps
801054d3:	e9 d4 f9 ff ff       	jmp    80104eac <alltraps>

801054d8 <vector57>:
.globl vector57
vector57:
  pushl $0
801054d8:	6a 00                	push   $0x0
  pushl $57
801054da:	6a 39                	push   $0x39
  jmp alltraps
801054dc:	e9 cb f9 ff ff       	jmp    80104eac <alltraps>

801054e1 <vector58>:
.globl vector58
vector58:
  pushl $0
801054e1:	6a 00                	push   $0x0
  pushl $58
801054e3:	6a 3a                	push   $0x3a
  jmp alltraps
801054e5:	e9 c2 f9 ff ff       	jmp    80104eac <alltraps>

801054ea <vector59>:
.globl vector59
vector59:
  pushl $0
801054ea:	6a 00                	push   $0x0
  pushl $59
801054ec:	6a 3b                	push   $0x3b
  jmp alltraps
801054ee:	e9 b9 f9 ff ff       	jmp    80104eac <alltraps>

801054f3 <vector60>:
.globl vector60
vector60:
  pushl $0
801054f3:	6a 00                	push   $0x0
  pushl $60
801054f5:	6a 3c                	push   $0x3c
  jmp alltraps
801054f7:	e9 b0 f9 ff ff       	jmp    80104eac <alltraps>

801054fc <vector61>:
.globl vector61
vector61:
  pushl $0
801054fc:	6a 00                	push   $0x0
  pushl $61
801054fe:	6a 3d                	push   $0x3d
  jmp alltraps
80105500:	e9 a7 f9 ff ff       	jmp    80104eac <alltraps>

80105505 <vector62>:
.globl vector62
vector62:
  pushl $0
80105505:	6a 00                	push   $0x0
  pushl $62
80105507:	6a 3e                	push   $0x3e
  jmp alltraps
80105509:	e9 9e f9 ff ff       	jmp    80104eac <alltraps>

8010550e <vector63>:
.globl vector63
vector63:
  pushl $0
8010550e:	6a 00                	push   $0x0
  pushl $63
80105510:	6a 3f                	push   $0x3f
  jmp alltraps
80105512:	e9 95 f9 ff ff       	jmp    80104eac <alltraps>

80105517 <vector64>:
.globl vector64
vector64:
  pushl $0
80105517:	6a 00                	push   $0x0
  pushl $64
80105519:	6a 40                	push   $0x40
  jmp alltraps
8010551b:	e9 8c f9 ff ff       	jmp    80104eac <alltraps>

80105520 <vector65>:
.globl vector65
vector65:
  pushl $0
80105520:	6a 00                	push   $0x0
  pushl $65
80105522:	6a 41                	push   $0x41
  jmp alltraps
80105524:	e9 83 f9 ff ff       	jmp    80104eac <alltraps>

80105529 <vector66>:
.globl vector66
vector66:
  pushl $0
80105529:	6a 00                	push   $0x0
  pushl $66
8010552b:	6a 42                	push   $0x42
  jmp alltraps
8010552d:	e9 7a f9 ff ff       	jmp    80104eac <alltraps>

80105532 <vector67>:
.globl vector67
vector67:
  pushl $0
80105532:	6a 00                	push   $0x0
  pushl $67
80105534:	6a 43                	push   $0x43
  jmp alltraps
80105536:	e9 71 f9 ff ff       	jmp    80104eac <alltraps>

8010553b <vector68>:
.globl vector68
vector68:
  pushl $0
8010553b:	6a 00                	push   $0x0
  pushl $68
8010553d:	6a 44                	push   $0x44
  jmp alltraps
8010553f:	e9 68 f9 ff ff       	jmp    80104eac <alltraps>

80105544 <vector69>:
.globl vector69
vector69:
  pushl $0
80105544:	6a 00                	push   $0x0
  pushl $69
80105546:	6a 45                	push   $0x45
  jmp alltraps
80105548:	e9 5f f9 ff ff       	jmp    80104eac <alltraps>

8010554d <vector70>:
.globl vector70
vector70:
  pushl $0
8010554d:	6a 00                	push   $0x0
  pushl $70
8010554f:	6a 46                	push   $0x46
  jmp alltraps
80105551:	e9 56 f9 ff ff       	jmp    80104eac <alltraps>

80105556 <vector71>:
.globl vector71
vector71:
  pushl $0
80105556:	6a 00                	push   $0x0
  pushl $71
80105558:	6a 47                	push   $0x47
  jmp alltraps
8010555a:	e9 4d f9 ff ff       	jmp    80104eac <alltraps>

8010555f <vector72>:
.globl vector72
vector72:
  pushl $0
8010555f:	6a 00                	push   $0x0
  pushl $72
80105561:	6a 48                	push   $0x48
  jmp alltraps
80105563:	e9 44 f9 ff ff       	jmp    80104eac <alltraps>

80105568 <vector73>:
.globl vector73
vector73:
  pushl $0
80105568:	6a 00                	push   $0x0
  pushl $73
8010556a:	6a 49                	push   $0x49
  jmp alltraps
8010556c:	e9 3b f9 ff ff       	jmp    80104eac <alltraps>

80105571 <vector74>:
.globl vector74
vector74:
  pushl $0
80105571:	6a 00                	push   $0x0
  pushl $74
80105573:	6a 4a                	push   $0x4a
  jmp alltraps
80105575:	e9 32 f9 ff ff       	jmp    80104eac <alltraps>

8010557a <vector75>:
.globl vector75
vector75:
  pushl $0
8010557a:	6a 00                	push   $0x0
  pushl $75
8010557c:	6a 4b                	push   $0x4b
  jmp alltraps
8010557e:	e9 29 f9 ff ff       	jmp    80104eac <alltraps>

80105583 <vector76>:
.globl vector76
vector76:
  pushl $0
80105583:	6a 00                	push   $0x0
  pushl $76
80105585:	6a 4c                	push   $0x4c
  jmp alltraps
80105587:	e9 20 f9 ff ff       	jmp    80104eac <alltraps>

8010558c <vector77>:
.globl vector77
vector77:
  pushl $0
8010558c:	6a 00                	push   $0x0
  pushl $77
8010558e:	6a 4d                	push   $0x4d
  jmp alltraps
80105590:	e9 17 f9 ff ff       	jmp    80104eac <alltraps>

80105595 <vector78>:
.globl vector78
vector78:
  pushl $0
80105595:	6a 00                	push   $0x0
  pushl $78
80105597:	6a 4e                	push   $0x4e
  jmp alltraps
80105599:	e9 0e f9 ff ff       	jmp    80104eac <alltraps>

8010559e <vector79>:
.globl vector79
vector79:
  pushl $0
8010559e:	6a 00                	push   $0x0
  pushl $79
801055a0:	6a 4f                	push   $0x4f
  jmp alltraps
801055a2:	e9 05 f9 ff ff       	jmp    80104eac <alltraps>

801055a7 <vector80>:
.globl vector80
vector80:
  pushl $0
801055a7:	6a 00                	push   $0x0
  pushl $80
801055a9:	6a 50                	push   $0x50
  jmp alltraps
801055ab:	e9 fc f8 ff ff       	jmp    80104eac <alltraps>

801055b0 <vector81>:
.globl vector81
vector81:
  pushl $0
801055b0:	6a 00                	push   $0x0
  pushl $81
801055b2:	6a 51                	push   $0x51
  jmp alltraps
801055b4:	e9 f3 f8 ff ff       	jmp    80104eac <alltraps>

801055b9 <vector82>:
.globl vector82
vector82:
  pushl $0
801055b9:	6a 00                	push   $0x0
  pushl $82
801055bb:	6a 52                	push   $0x52
  jmp alltraps
801055bd:	e9 ea f8 ff ff       	jmp    80104eac <alltraps>

801055c2 <vector83>:
.globl vector83
vector83:
  pushl $0
801055c2:	6a 00                	push   $0x0
  pushl $83
801055c4:	6a 53                	push   $0x53
  jmp alltraps
801055c6:	e9 e1 f8 ff ff       	jmp    80104eac <alltraps>

801055cb <vector84>:
.globl vector84
vector84:
  pushl $0
801055cb:	6a 00                	push   $0x0
  pushl $84
801055cd:	6a 54                	push   $0x54
  jmp alltraps
801055cf:	e9 d8 f8 ff ff       	jmp    80104eac <alltraps>

801055d4 <vector85>:
.globl vector85
vector85:
  pushl $0
801055d4:	6a 00                	push   $0x0
  pushl $85
801055d6:	6a 55                	push   $0x55
  jmp alltraps
801055d8:	e9 cf f8 ff ff       	jmp    80104eac <alltraps>

801055dd <vector86>:
.globl vector86
vector86:
  pushl $0
801055dd:	6a 00                	push   $0x0
  pushl $86
801055df:	6a 56                	push   $0x56
  jmp alltraps
801055e1:	e9 c6 f8 ff ff       	jmp    80104eac <alltraps>

801055e6 <vector87>:
.globl vector87
vector87:
  pushl $0
801055e6:	6a 00                	push   $0x0
  pushl $87
801055e8:	6a 57                	push   $0x57
  jmp alltraps
801055ea:	e9 bd f8 ff ff       	jmp    80104eac <alltraps>

801055ef <vector88>:
.globl vector88
vector88:
  pushl $0
801055ef:	6a 00                	push   $0x0
  pushl $88
801055f1:	6a 58                	push   $0x58
  jmp alltraps
801055f3:	e9 b4 f8 ff ff       	jmp    80104eac <alltraps>

801055f8 <vector89>:
.globl vector89
vector89:
  pushl $0
801055f8:	6a 00                	push   $0x0
  pushl $89
801055fa:	6a 59                	push   $0x59
  jmp alltraps
801055fc:	e9 ab f8 ff ff       	jmp    80104eac <alltraps>

80105601 <vector90>:
.globl vector90
vector90:
  pushl $0
80105601:	6a 00                	push   $0x0
  pushl $90
80105603:	6a 5a                	push   $0x5a
  jmp alltraps
80105605:	e9 a2 f8 ff ff       	jmp    80104eac <alltraps>

8010560a <vector91>:
.globl vector91
vector91:
  pushl $0
8010560a:	6a 00                	push   $0x0
  pushl $91
8010560c:	6a 5b                	push   $0x5b
  jmp alltraps
8010560e:	e9 99 f8 ff ff       	jmp    80104eac <alltraps>

80105613 <vector92>:
.globl vector92
vector92:
  pushl $0
80105613:	6a 00                	push   $0x0
  pushl $92
80105615:	6a 5c                	push   $0x5c
  jmp alltraps
80105617:	e9 90 f8 ff ff       	jmp    80104eac <alltraps>

8010561c <vector93>:
.globl vector93
vector93:
  pushl $0
8010561c:	6a 00                	push   $0x0
  pushl $93
8010561e:	6a 5d                	push   $0x5d
  jmp alltraps
80105620:	e9 87 f8 ff ff       	jmp    80104eac <alltraps>

80105625 <vector94>:
.globl vector94
vector94:
  pushl $0
80105625:	6a 00                	push   $0x0
  pushl $94
80105627:	6a 5e                	push   $0x5e
  jmp alltraps
80105629:	e9 7e f8 ff ff       	jmp    80104eac <alltraps>

8010562e <vector95>:
.globl vector95
vector95:
  pushl $0
8010562e:	6a 00                	push   $0x0
  pushl $95
80105630:	6a 5f                	push   $0x5f
  jmp alltraps
80105632:	e9 75 f8 ff ff       	jmp    80104eac <alltraps>

80105637 <vector96>:
.globl vector96
vector96:
  pushl $0
80105637:	6a 00                	push   $0x0
  pushl $96
80105639:	6a 60                	push   $0x60
  jmp alltraps
8010563b:	e9 6c f8 ff ff       	jmp    80104eac <alltraps>

80105640 <vector97>:
.globl vector97
vector97:
  pushl $0
80105640:	6a 00                	push   $0x0
  pushl $97
80105642:	6a 61                	push   $0x61
  jmp alltraps
80105644:	e9 63 f8 ff ff       	jmp    80104eac <alltraps>

80105649 <vector98>:
.globl vector98
vector98:
  pushl $0
80105649:	6a 00                	push   $0x0
  pushl $98
8010564b:	6a 62                	push   $0x62
  jmp alltraps
8010564d:	e9 5a f8 ff ff       	jmp    80104eac <alltraps>

80105652 <vector99>:
.globl vector99
vector99:
  pushl $0
80105652:	6a 00                	push   $0x0
  pushl $99
80105654:	6a 63                	push   $0x63
  jmp alltraps
80105656:	e9 51 f8 ff ff       	jmp    80104eac <alltraps>

8010565b <vector100>:
.globl vector100
vector100:
  pushl $0
8010565b:	6a 00                	push   $0x0
  pushl $100
8010565d:	6a 64                	push   $0x64
  jmp alltraps
8010565f:	e9 48 f8 ff ff       	jmp    80104eac <alltraps>

80105664 <vector101>:
.globl vector101
vector101:
  pushl $0
80105664:	6a 00                	push   $0x0
  pushl $101
80105666:	6a 65                	push   $0x65
  jmp alltraps
80105668:	e9 3f f8 ff ff       	jmp    80104eac <alltraps>

8010566d <vector102>:
.globl vector102
vector102:
  pushl $0
8010566d:	6a 00                	push   $0x0
  pushl $102
8010566f:	6a 66                	push   $0x66
  jmp alltraps
80105671:	e9 36 f8 ff ff       	jmp    80104eac <alltraps>

80105676 <vector103>:
.globl vector103
vector103:
  pushl $0
80105676:	6a 00                	push   $0x0
  pushl $103
80105678:	6a 67                	push   $0x67
  jmp alltraps
8010567a:	e9 2d f8 ff ff       	jmp    80104eac <alltraps>

8010567f <vector104>:
.globl vector104
vector104:
  pushl $0
8010567f:	6a 00                	push   $0x0
  pushl $104
80105681:	6a 68                	push   $0x68
  jmp alltraps
80105683:	e9 24 f8 ff ff       	jmp    80104eac <alltraps>

80105688 <vector105>:
.globl vector105
vector105:
  pushl $0
80105688:	6a 00                	push   $0x0
  pushl $105
8010568a:	6a 69                	push   $0x69
  jmp alltraps
8010568c:	e9 1b f8 ff ff       	jmp    80104eac <alltraps>

80105691 <vector106>:
.globl vector106
vector106:
  pushl $0
80105691:	6a 00                	push   $0x0
  pushl $106
80105693:	6a 6a                	push   $0x6a
  jmp alltraps
80105695:	e9 12 f8 ff ff       	jmp    80104eac <alltraps>

8010569a <vector107>:
.globl vector107
vector107:
  pushl $0
8010569a:	6a 00                	push   $0x0
  pushl $107
8010569c:	6a 6b                	push   $0x6b
  jmp alltraps
8010569e:	e9 09 f8 ff ff       	jmp    80104eac <alltraps>

801056a3 <vector108>:
.globl vector108
vector108:
  pushl $0
801056a3:	6a 00                	push   $0x0
  pushl $108
801056a5:	6a 6c                	push   $0x6c
  jmp alltraps
801056a7:	e9 00 f8 ff ff       	jmp    80104eac <alltraps>

801056ac <vector109>:
.globl vector109
vector109:
  pushl $0
801056ac:	6a 00                	push   $0x0
  pushl $109
801056ae:	6a 6d                	push   $0x6d
  jmp alltraps
801056b0:	e9 f7 f7 ff ff       	jmp    80104eac <alltraps>

801056b5 <vector110>:
.globl vector110
vector110:
  pushl $0
801056b5:	6a 00                	push   $0x0
  pushl $110
801056b7:	6a 6e                	push   $0x6e
  jmp alltraps
801056b9:	e9 ee f7 ff ff       	jmp    80104eac <alltraps>

801056be <vector111>:
.globl vector111
vector111:
  pushl $0
801056be:	6a 00                	push   $0x0
  pushl $111
801056c0:	6a 6f                	push   $0x6f
  jmp alltraps
801056c2:	e9 e5 f7 ff ff       	jmp    80104eac <alltraps>

801056c7 <vector112>:
.globl vector112
vector112:
  pushl $0
801056c7:	6a 00                	push   $0x0
  pushl $112
801056c9:	6a 70                	push   $0x70
  jmp alltraps
801056cb:	e9 dc f7 ff ff       	jmp    80104eac <alltraps>

801056d0 <vector113>:
.globl vector113
vector113:
  pushl $0
801056d0:	6a 00                	push   $0x0
  pushl $113
801056d2:	6a 71                	push   $0x71
  jmp alltraps
801056d4:	e9 d3 f7 ff ff       	jmp    80104eac <alltraps>

801056d9 <vector114>:
.globl vector114
vector114:
  pushl $0
801056d9:	6a 00                	push   $0x0
  pushl $114
801056db:	6a 72                	push   $0x72
  jmp alltraps
801056dd:	e9 ca f7 ff ff       	jmp    80104eac <alltraps>

801056e2 <vector115>:
.globl vector115
vector115:
  pushl $0
801056e2:	6a 00                	push   $0x0
  pushl $115
801056e4:	6a 73                	push   $0x73
  jmp alltraps
801056e6:	e9 c1 f7 ff ff       	jmp    80104eac <alltraps>

801056eb <vector116>:
.globl vector116
vector116:
  pushl $0
801056eb:	6a 00                	push   $0x0
  pushl $116
801056ed:	6a 74                	push   $0x74
  jmp alltraps
801056ef:	e9 b8 f7 ff ff       	jmp    80104eac <alltraps>

801056f4 <vector117>:
.globl vector117
vector117:
  pushl $0
801056f4:	6a 00                	push   $0x0
  pushl $117
801056f6:	6a 75                	push   $0x75
  jmp alltraps
801056f8:	e9 af f7 ff ff       	jmp    80104eac <alltraps>

801056fd <vector118>:
.globl vector118
vector118:
  pushl $0
801056fd:	6a 00                	push   $0x0
  pushl $118
801056ff:	6a 76                	push   $0x76
  jmp alltraps
80105701:	e9 a6 f7 ff ff       	jmp    80104eac <alltraps>

80105706 <vector119>:
.globl vector119
vector119:
  pushl $0
80105706:	6a 00                	push   $0x0
  pushl $119
80105708:	6a 77                	push   $0x77
  jmp alltraps
8010570a:	e9 9d f7 ff ff       	jmp    80104eac <alltraps>

8010570f <vector120>:
.globl vector120
vector120:
  pushl $0
8010570f:	6a 00                	push   $0x0
  pushl $120
80105711:	6a 78                	push   $0x78
  jmp alltraps
80105713:	e9 94 f7 ff ff       	jmp    80104eac <alltraps>

80105718 <vector121>:
.globl vector121
vector121:
  pushl $0
80105718:	6a 00                	push   $0x0
  pushl $121
8010571a:	6a 79                	push   $0x79
  jmp alltraps
8010571c:	e9 8b f7 ff ff       	jmp    80104eac <alltraps>

80105721 <vector122>:
.globl vector122
vector122:
  pushl $0
80105721:	6a 00                	push   $0x0
  pushl $122
80105723:	6a 7a                	push   $0x7a
  jmp alltraps
80105725:	e9 82 f7 ff ff       	jmp    80104eac <alltraps>

8010572a <vector123>:
.globl vector123
vector123:
  pushl $0
8010572a:	6a 00                	push   $0x0
  pushl $123
8010572c:	6a 7b                	push   $0x7b
  jmp alltraps
8010572e:	e9 79 f7 ff ff       	jmp    80104eac <alltraps>

80105733 <vector124>:
.globl vector124
vector124:
  pushl $0
80105733:	6a 00                	push   $0x0
  pushl $124
80105735:	6a 7c                	push   $0x7c
  jmp alltraps
80105737:	e9 70 f7 ff ff       	jmp    80104eac <alltraps>

8010573c <vector125>:
.globl vector125
vector125:
  pushl $0
8010573c:	6a 00                	push   $0x0
  pushl $125
8010573e:	6a 7d                	push   $0x7d
  jmp alltraps
80105740:	e9 67 f7 ff ff       	jmp    80104eac <alltraps>

80105745 <vector126>:
.globl vector126
vector126:
  pushl $0
80105745:	6a 00                	push   $0x0
  pushl $126
80105747:	6a 7e                	push   $0x7e
  jmp alltraps
80105749:	e9 5e f7 ff ff       	jmp    80104eac <alltraps>

8010574e <vector127>:
.globl vector127
vector127:
  pushl $0
8010574e:	6a 00                	push   $0x0
  pushl $127
80105750:	6a 7f                	push   $0x7f
  jmp alltraps
80105752:	e9 55 f7 ff ff       	jmp    80104eac <alltraps>

80105757 <vector128>:
.globl vector128
vector128:
  pushl $0
80105757:	6a 00                	push   $0x0
  pushl $128
80105759:	68 80 00 00 00       	push   $0x80
  jmp alltraps
8010575e:	e9 49 f7 ff ff       	jmp    80104eac <alltraps>

80105763 <vector129>:
.globl vector129
vector129:
  pushl $0
80105763:	6a 00                	push   $0x0
  pushl $129
80105765:	68 81 00 00 00       	push   $0x81
  jmp alltraps
8010576a:	e9 3d f7 ff ff       	jmp    80104eac <alltraps>

8010576f <vector130>:
.globl vector130
vector130:
  pushl $0
8010576f:	6a 00                	push   $0x0
  pushl $130
80105771:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80105776:	e9 31 f7 ff ff       	jmp    80104eac <alltraps>

8010577b <vector131>:
.globl vector131
vector131:
  pushl $0
8010577b:	6a 00                	push   $0x0
  pushl $131
8010577d:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80105782:	e9 25 f7 ff ff       	jmp    80104eac <alltraps>

80105787 <vector132>:
.globl vector132
vector132:
  pushl $0
80105787:	6a 00                	push   $0x0
  pushl $132
80105789:	68 84 00 00 00       	push   $0x84
  jmp alltraps
8010578e:	e9 19 f7 ff ff       	jmp    80104eac <alltraps>

80105793 <vector133>:
.globl vector133
vector133:
  pushl $0
80105793:	6a 00                	push   $0x0
  pushl $133
80105795:	68 85 00 00 00       	push   $0x85
  jmp alltraps
8010579a:	e9 0d f7 ff ff       	jmp    80104eac <alltraps>

8010579f <vector134>:
.globl vector134
vector134:
  pushl $0
8010579f:	6a 00                	push   $0x0
  pushl $134
801057a1:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801057a6:	e9 01 f7 ff ff       	jmp    80104eac <alltraps>

801057ab <vector135>:
.globl vector135
vector135:
  pushl $0
801057ab:	6a 00                	push   $0x0
  pushl $135
801057ad:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801057b2:	e9 f5 f6 ff ff       	jmp    80104eac <alltraps>

801057b7 <vector136>:
.globl vector136
vector136:
  pushl $0
801057b7:	6a 00                	push   $0x0
  pushl $136
801057b9:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801057be:	e9 e9 f6 ff ff       	jmp    80104eac <alltraps>

801057c3 <vector137>:
.globl vector137
vector137:
  pushl $0
801057c3:	6a 00                	push   $0x0
  pushl $137
801057c5:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801057ca:	e9 dd f6 ff ff       	jmp    80104eac <alltraps>

801057cf <vector138>:
.globl vector138
vector138:
  pushl $0
801057cf:	6a 00                	push   $0x0
  pushl $138
801057d1:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801057d6:	e9 d1 f6 ff ff       	jmp    80104eac <alltraps>

801057db <vector139>:
.globl vector139
vector139:
  pushl $0
801057db:	6a 00                	push   $0x0
  pushl $139
801057dd:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801057e2:	e9 c5 f6 ff ff       	jmp    80104eac <alltraps>

801057e7 <vector140>:
.globl vector140
vector140:
  pushl $0
801057e7:	6a 00                	push   $0x0
  pushl $140
801057e9:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801057ee:	e9 b9 f6 ff ff       	jmp    80104eac <alltraps>

801057f3 <vector141>:
.globl vector141
vector141:
  pushl $0
801057f3:	6a 00                	push   $0x0
  pushl $141
801057f5:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801057fa:	e9 ad f6 ff ff       	jmp    80104eac <alltraps>

801057ff <vector142>:
.globl vector142
vector142:
  pushl $0
801057ff:	6a 00                	push   $0x0
  pushl $142
80105801:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80105806:	e9 a1 f6 ff ff       	jmp    80104eac <alltraps>

8010580b <vector143>:
.globl vector143
vector143:
  pushl $0
8010580b:	6a 00                	push   $0x0
  pushl $143
8010580d:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80105812:	e9 95 f6 ff ff       	jmp    80104eac <alltraps>

80105817 <vector144>:
.globl vector144
vector144:
  pushl $0
80105817:	6a 00                	push   $0x0
  pushl $144
80105819:	68 90 00 00 00       	push   $0x90
  jmp alltraps
8010581e:	e9 89 f6 ff ff       	jmp    80104eac <alltraps>

80105823 <vector145>:
.globl vector145
vector145:
  pushl $0
80105823:	6a 00                	push   $0x0
  pushl $145
80105825:	68 91 00 00 00       	push   $0x91
  jmp alltraps
8010582a:	e9 7d f6 ff ff       	jmp    80104eac <alltraps>

8010582f <vector146>:
.globl vector146
vector146:
  pushl $0
8010582f:	6a 00                	push   $0x0
  pushl $146
80105831:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80105836:	e9 71 f6 ff ff       	jmp    80104eac <alltraps>

8010583b <vector147>:
.globl vector147
vector147:
  pushl $0
8010583b:	6a 00                	push   $0x0
  pushl $147
8010583d:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80105842:	e9 65 f6 ff ff       	jmp    80104eac <alltraps>

80105847 <vector148>:
.globl vector148
vector148:
  pushl $0
80105847:	6a 00                	push   $0x0
  pushl $148
80105849:	68 94 00 00 00       	push   $0x94
  jmp alltraps
8010584e:	e9 59 f6 ff ff       	jmp    80104eac <alltraps>

80105853 <vector149>:
.globl vector149
vector149:
  pushl $0
80105853:	6a 00                	push   $0x0
  pushl $149
80105855:	68 95 00 00 00       	push   $0x95
  jmp alltraps
8010585a:	e9 4d f6 ff ff       	jmp    80104eac <alltraps>

8010585f <vector150>:
.globl vector150
vector150:
  pushl $0
8010585f:	6a 00                	push   $0x0
  pushl $150
80105861:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80105866:	e9 41 f6 ff ff       	jmp    80104eac <alltraps>

8010586b <vector151>:
.globl vector151
vector151:
  pushl $0
8010586b:	6a 00                	push   $0x0
  pushl $151
8010586d:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80105872:	e9 35 f6 ff ff       	jmp    80104eac <alltraps>

80105877 <vector152>:
.globl vector152
vector152:
  pushl $0
80105877:	6a 00                	push   $0x0
  pushl $152
80105879:	68 98 00 00 00       	push   $0x98
  jmp alltraps
8010587e:	e9 29 f6 ff ff       	jmp    80104eac <alltraps>

80105883 <vector153>:
.globl vector153
vector153:
  pushl $0
80105883:	6a 00                	push   $0x0
  pushl $153
80105885:	68 99 00 00 00       	push   $0x99
  jmp alltraps
8010588a:	e9 1d f6 ff ff       	jmp    80104eac <alltraps>

8010588f <vector154>:
.globl vector154
vector154:
  pushl $0
8010588f:	6a 00                	push   $0x0
  pushl $154
80105891:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80105896:	e9 11 f6 ff ff       	jmp    80104eac <alltraps>

8010589b <vector155>:
.globl vector155
vector155:
  pushl $0
8010589b:	6a 00                	push   $0x0
  pushl $155
8010589d:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
801058a2:	e9 05 f6 ff ff       	jmp    80104eac <alltraps>

801058a7 <vector156>:
.globl vector156
vector156:
  pushl $0
801058a7:	6a 00                	push   $0x0
  pushl $156
801058a9:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
801058ae:	e9 f9 f5 ff ff       	jmp    80104eac <alltraps>

801058b3 <vector157>:
.globl vector157
vector157:
  pushl $0
801058b3:	6a 00                	push   $0x0
  pushl $157
801058b5:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
801058ba:	e9 ed f5 ff ff       	jmp    80104eac <alltraps>

801058bf <vector158>:
.globl vector158
vector158:
  pushl $0
801058bf:	6a 00                	push   $0x0
  pushl $158
801058c1:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801058c6:	e9 e1 f5 ff ff       	jmp    80104eac <alltraps>

801058cb <vector159>:
.globl vector159
vector159:
  pushl $0
801058cb:	6a 00                	push   $0x0
  pushl $159
801058cd:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801058d2:	e9 d5 f5 ff ff       	jmp    80104eac <alltraps>

801058d7 <vector160>:
.globl vector160
vector160:
  pushl $0
801058d7:	6a 00                	push   $0x0
  pushl $160
801058d9:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801058de:	e9 c9 f5 ff ff       	jmp    80104eac <alltraps>

801058e3 <vector161>:
.globl vector161
vector161:
  pushl $0
801058e3:	6a 00                	push   $0x0
  pushl $161
801058e5:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801058ea:	e9 bd f5 ff ff       	jmp    80104eac <alltraps>

801058ef <vector162>:
.globl vector162
vector162:
  pushl $0
801058ef:	6a 00                	push   $0x0
  pushl $162
801058f1:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801058f6:	e9 b1 f5 ff ff       	jmp    80104eac <alltraps>

801058fb <vector163>:
.globl vector163
vector163:
  pushl $0
801058fb:	6a 00                	push   $0x0
  pushl $163
801058fd:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105902:	e9 a5 f5 ff ff       	jmp    80104eac <alltraps>

80105907 <vector164>:
.globl vector164
vector164:
  pushl $0
80105907:	6a 00                	push   $0x0
  pushl $164
80105909:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
8010590e:	e9 99 f5 ff ff       	jmp    80104eac <alltraps>

80105913 <vector165>:
.globl vector165
vector165:
  pushl $0
80105913:	6a 00                	push   $0x0
  pushl $165
80105915:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
8010591a:	e9 8d f5 ff ff       	jmp    80104eac <alltraps>

8010591f <vector166>:
.globl vector166
vector166:
  pushl $0
8010591f:	6a 00                	push   $0x0
  pushl $166
80105921:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105926:	e9 81 f5 ff ff       	jmp    80104eac <alltraps>

8010592b <vector167>:
.globl vector167
vector167:
  pushl $0
8010592b:	6a 00                	push   $0x0
  pushl $167
8010592d:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105932:	e9 75 f5 ff ff       	jmp    80104eac <alltraps>

80105937 <vector168>:
.globl vector168
vector168:
  pushl $0
80105937:	6a 00                	push   $0x0
  pushl $168
80105939:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
8010593e:	e9 69 f5 ff ff       	jmp    80104eac <alltraps>

80105943 <vector169>:
.globl vector169
vector169:
  pushl $0
80105943:	6a 00                	push   $0x0
  pushl $169
80105945:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
8010594a:	e9 5d f5 ff ff       	jmp    80104eac <alltraps>

8010594f <vector170>:
.globl vector170
vector170:
  pushl $0
8010594f:	6a 00                	push   $0x0
  pushl $170
80105951:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105956:	e9 51 f5 ff ff       	jmp    80104eac <alltraps>

8010595b <vector171>:
.globl vector171
vector171:
  pushl $0
8010595b:	6a 00                	push   $0x0
  pushl $171
8010595d:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105962:	e9 45 f5 ff ff       	jmp    80104eac <alltraps>

80105967 <vector172>:
.globl vector172
vector172:
  pushl $0
80105967:	6a 00                	push   $0x0
  pushl $172
80105969:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
8010596e:	e9 39 f5 ff ff       	jmp    80104eac <alltraps>

80105973 <vector173>:
.globl vector173
vector173:
  pushl $0
80105973:	6a 00                	push   $0x0
  pushl $173
80105975:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
8010597a:	e9 2d f5 ff ff       	jmp    80104eac <alltraps>

8010597f <vector174>:
.globl vector174
vector174:
  pushl $0
8010597f:	6a 00                	push   $0x0
  pushl $174
80105981:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105986:	e9 21 f5 ff ff       	jmp    80104eac <alltraps>

8010598b <vector175>:
.globl vector175
vector175:
  pushl $0
8010598b:	6a 00                	push   $0x0
  pushl $175
8010598d:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105992:	e9 15 f5 ff ff       	jmp    80104eac <alltraps>

80105997 <vector176>:
.globl vector176
vector176:
  pushl $0
80105997:	6a 00                	push   $0x0
  pushl $176
80105999:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
8010599e:	e9 09 f5 ff ff       	jmp    80104eac <alltraps>

801059a3 <vector177>:
.globl vector177
vector177:
  pushl $0
801059a3:	6a 00                	push   $0x0
  pushl $177
801059a5:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
801059aa:	e9 fd f4 ff ff       	jmp    80104eac <alltraps>

801059af <vector178>:
.globl vector178
vector178:
  pushl $0
801059af:	6a 00                	push   $0x0
  pushl $178
801059b1:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
801059b6:	e9 f1 f4 ff ff       	jmp    80104eac <alltraps>

801059bb <vector179>:
.globl vector179
vector179:
  pushl $0
801059bb:	6a 00                	push   $0x0
  pushl $179
801059bd:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
801059c2:	e9 e5 f4 ff ff       	jmp    80104eac <alltraps>

801059c7 <vector180>:
.globl vector180
vector180:
  pushl $0
801059c7:	6a 00                	push   $0x0
  pushl $180
801059c9:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801059ce:	e9 d9 f4 ff ff       	jmp    80104eac <alltraps>

801059d3 <vector181>:
.globl vector181
vector181:
  pushl $0
801059d3:	6a 00                	push   $0x0
  pushl $181
801059d5:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801059da:	e9 cd f4 ff ff       	jmp    80104eac <alltraps>

801059df <vector182>:
.globl vector182
vector182:
  pushl $0
801059df:	6a 00                	push   $0x0
  pushl $182
801059e1:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801059e6:	e9 c1 f4 ff ff       	jmp    80104eac <alltraps>

801059eb <vector183>:
.globl vector183
vector183:
  pushl $0
801059eb:	6a 00                	push   $0x0
  pushl $183
801059ed:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801059f2:	e9 b5 f4 ff ff       	jmp    80104eac <alltraps>

801059f7 <vector184>:
.globl vector184
vector184:
  pushl $0
801059f7:	6a 00                	push   $0x0
  pushl $184
801059f9:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801059fe:	e9 a9 f4 ff ff       	jmp    80104eac <alltraps>

80105a03 <vector185>:
.globl vector185
vector185:
  pushl $0
80105a03:	6a 00                	push   $0x0
  pushl $185
80105a05:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105a0a:	e9 9d f4 ff ff       	jmp    80104eac <alltraps>

80105a0f <vector186>:
.globl vector186
vector186:
  pushl $0
80105a0f:	6a 00                	push   $0x0
  pushl $186
80105a11:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105a16:	e9 91 f4 ff ff       	jmp    80104eac <alltraps>

80105a1b <vector187>:
.globl vector187
vector187:
  pushl $0
80105a1b:	6a 00                	push   $0x0
  pushl $187
80105a1d:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105a22:	e9 85 f4 ff ff       	jmp    80104eac <alltraps>

80105a27 <vector188>:
.globl vector188
vector188:
  pushl $0
80105a27:	6a 00                	push   $0x0
  pushl $188
80105a29:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105a2e:	e9 79 f4 ff ff       	jmp    80104eac <alltraps>

80105a33 <vector189>:
.globl vector189
vector189:
  pushl $0
80105a33:	6a 00                	push   $0x0
  pushl $189
80105a35:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105a3a:	e9 6d f4 ff ff       	jmp    80104eac <alltraps>

80105a3f <vector190>:
.globl vector190
vector190:
  pushl $0
80105a3f:	6a 00                	push   $0x0
  pushl $190
80105a41:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105a46:	e9 61 f4 ff ff       	jmp    80104eac <alltraps>

80105a4b <vector191>:
.globl vector191
vector191:
  pushl $0
80105a4b:	6a 00                	push   $0x0
  pushl $191
80105a4d:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105a52:	e9 55 f4 ff ff       	jmp    80104eac <alltraps>

80105a57 <vector192>:
.globl vector192
vector192:
  pushl $0
80105a57:	6a 00                	push   $0x0
  pushl $192
80105a59:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105a5e:	e9 49 f4 ff ff       	jmp    80104eac <alltraps>

80105a63 <vector193>:
.globl vector193
vector193:
  pushl $0
80105a63:	6a 00                	push   $0x0
  pushl $193
80105a65:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105a6a:	e9 3d f4 ff ff       	jmp    80104eac <alltraps>

80105a6f <vector194>:
.globl vector194
vector194:
  pushl $0
80105a6f:	6a 00                	push   $0x0
  pushl $194
80105a71:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105a76:	e9 31 f4 ff ff       	jmp    80104eac <alltraps>

80105a7b <vector195>:
.globl vector195
vector195:
  pushl $0
80105a7b:	6a 00                	push   $0x0
  pushl $195
80105a7d:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105a82:	e9 25 f4 ff ff       	jmp    80104eac <alltraps>

80105a87 <vector196>:
.globl vector196
vector196:
  pushl $0
80105a87:	6a 00                	push   $0x0
  pushl $196
80105a89:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105a8e:	e9 19 f4 ff ff       	jmp    80104eac <alltraps>

80105a93 <vector197>:
.globl vector197
vector197:
  pushl $0
80105a93:	6a 00                	push   $0x0
  pushl $197
80105a95:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105a9a:	e9 0d f4 ff ff       	jmp    80104eac <alltraps>

80105a9f <vector198>:
.globl vector198
vector198:
  pushl $0
80105a9f:	6a 00                	push   $0x0
  pushl $198
80105aa1:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105aa6:	e9 01 f4 ff ff       	jmp    80104eac <alltraps>

80105aab <vector199>:
.globl vector199
vector199:
  pushl $0
80105aab:	6a 00                	push   $0x0
  pushl $199
80105aad:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105ab2:	e9 f5 f3 ff ff       	jmp    80104eac <alltraps>

80105ab7 <vector200>:
.globl vector200
vector200:
  pushl $0
80105ab7:	6a 00                	push   $0x0
  pushl $200
80105ab9:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105abe:	e9 e9 f3 ff ff       	jmp    80104eac <alltraps>

80105ac3 <vector201>:
.globl vector201
vector201:
  pushl $0
80105ac3:	6a 00                	push   $0x0
  pushl $201
80105ac5:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105aca:	e9 dd f3 ff ff       	jmp    80104eac <alltraps>

80105acf <vector202>:
.globl vector202
vector202:
  pushl $0
80105acf:	6a 00                	push   $0x0
  pushl $202
80105ad1:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105ad6:	e9 d1 f3 ff ff       	jmp    80104eac <alltraps>

80105adb <vector203>:
.globl vector203
vector203:
  pushl $0
80105adb:	6a 00                	push   $0x0
  pushl $203
80105add:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105ae2:	e9 c5 f3 ff ff       	jmp    80104eac <alltraps>

80105ae7 <vector204>:
.globl vector204
vector204:
  pushl $0
80105ae7:	6a 00                	push   $0x0
  pushl $204
80105ae9:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105aee:	e9 b9 f3 ff ff       	jmp    80104eac <alltraps>

80105af3 <vector205>:
.globl vector205
vector205:
  pushl $0
80105af3:	6a 00                	push   $0x0
  pushl $205
80105af5:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105afa:	e9 ad f3 ff ff       	jmp    80104eac <alltraps>

80105aff <vector206>:
.globl vector206
vector206:
  pushl $0
80105aff:	6a 00                	push   $0x0
  pushl $206
80105b01:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105b06:	e9 a1 f3 ff ff       	jmp    80104eac <alltraps>

80105b0b <vector207>:
.globl vector207
vector207:
  pushl $0
80105b0b:	6a 00                	push   $0x0
  pushl $207
80105b0d:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105b12:	e9 95 f3 ff ff       	jmp    80104eac <alltraps>

80105b17 <vector208>:
.globl vector208
vector208:
  pushl $0
80105b17:	6a 00                	push   $0x0
  pushl $208
80105b19:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105b1e:	e9 89 f3 ff ff       	jmp    80104eac <alltraps>

80105b23 <vector209>:
.globl vector209
vector209:
  pushl $0
80105b23:	6a 00                	push   $0x0
  pushl $209
80105b25:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105b2a:	e9 7d f3 ff ff       	jmp    80104eac <alltraps>

80105b2f <vector210>:
.globl vector210
vector210:
  pushl $0
80105b2f:	6a 00                	push   $0x0
  pushl $210
80105b31:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105b36:	e9 71 f3 ff ff       	jmp    80104eac <alltraps>

80105b3b <vector211>:
.globl vector211
vector211:
  pushl $0
80105b3b:	6a 00                	push   $0x0
  pushl $211
80105b3d:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105b42:	e9 65 f3 ff ff       	jmp    80104eac <alltraps>

80105b47 <vector212>:
.globl vector212
vector212:
  pushl $0
80105b47:	6a 00                	push   $0x0
  pushl $212
80105b49:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105b4e:	e9 59 f3 ff ff       	jmp    80104eac <alltraps>

80105b53 <vector213>:
.globl vector213
vector213:
  pushl $0
80105b53:	6a 00                	push   $0x0
  pushl $213
80105b55:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105b5a:	e9 4d f3 ff ff       	jmp    80104eac <alltraps>

80105b5f <vector214>:
.globl vector214
vector214:
  pushl $0
80105b5f:	6a 00                	push   $0x0
  pushl $214
80105b61:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105b66:	e9 41 f3 ff ff       	jmp    80104eac <alltraps>

80105b6b <vector215>:
.globl vector215
vector215:
  pushl $0
80105b6b:	6a 00                	push   $0x0
  pushl $215
80105b6d:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105b72:	e9 35 f3 ff ff       	jmp    80104eac <alltraps>

80105b77 <vector216>:
.globl vector216
vector216:
  pushl $0
80105b77:	6a 00                	push   $0x0
  pushl $216
80105b79:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105b7e:	e9 29 f3 ff ff       	jmp    80104eac <alltraps>

80105b83 <vector217>:
.globl vector217
vector217:
  pushl $0
80105b83:	6a 00                	push   $0x0
  pushl $217
80105b85:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105b8a:	e9 1d f3 ff ff       	jmp    80104eac <alltraps>

80105b8f <vector218>:
.globl vector218
vector218:
  pushl $0
80105b8f:	6a 00                	push   $0x0
  pushl $218
80105b91:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105b96:	e9 11 f3 ff ff       	jmp    80104eac <alltraps>

80105b9b <vector219>:
.globl vector219
vector219:
  pushl $0
80105b9b:	6a 00                	push   $0x0
  pushl $219
80105b9d:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105ba2:	e9 05 f3 ff ff       	jmp    80104eac <alltraps>

80105ba7 <vector220>:
.globl vector220
vector220:
  pushl $0
80105ba7:	6a 00                	push   $0x0
  pushl $220
80105ba9:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105bae:	e9 f9 f2 ff ff       	jmp    80104eac <alltraps>

80105bb3 <vector221>:
.globl vector221
vector221:
  pushl $0
80105bb3:	6a 00                	push   $0x0
  pushl $221
80105bb5:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105bba:	e9 ed f2 ff ff       	jmp    80104eac <alltraps>

80105bbf <vector222>:
.globl vector222
vector222:
  pushl $0
80105bbf:	6a 00                	push   $0x0
  pushl $222
80105bc1:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105bc6:	e9 e1 f2 ff ff       	jmp    80104eac <alltraps>

80105bcb <vector223>:
.globl vector223
vector223:
  pushl $0
80105bcb:	6a 00                	push   $0x0
  pushl $223
80105bcd:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105bd2:	e9 d5 f2 ff ff       	jmp    80104eac <alltraps>

80105bd7 <vector224>:
.globl vector224
vector224:
  pushl $0
80105bd7:	6a 00                	push   $0x0
  pushl $224
80105bd9:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105bde:	e9 c9 f2 ff ff       	jmp    80104eac <alltraps>

80105be3 <vector225>:
.globl vector225
vector225:
  pushl $0
80105be3:	6a 00                	push   $0x0
  pushl $225
80105be5:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105bea:	e9 bd f2 ff ff       	jmp    80104eac <alltraps>

80105bef <vector226>:
.globl vector226
vector226:
  pushl $0
80105bef:	6a 00                	push   $0x0
  pushl $226
80105bf1:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105bf6:	e9 b1 f2 ff ff       	jmp    80104eac <alltraps>

80105bfb <vector227>:
.globl vector227
vector227:
  pushl $0
80105bfb:	6a 00                	push   $0x0
  pushl $227
80105bfd:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105c02:	e9 a5 f2 ff ff       	jmp    80104eac <alltraps>

80105c07 <vector228>:
.globl vector228
vector228:
  pushl $0
80105c07:	6a 00                	push   $0x0
  pushl $228
80105c09:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105c0e:	e9 99 f2 ff ff       	jmp    80104eac <alltraps>

80105c13 <vector229>:
.globl vector229
vector229:
  pushl $0
80105c13:	6a 00                	push   $0x0
  pushl $229
80105c15:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105c1a:	e9 8d f2 ff ff       	jmp    80104eac <alltraps>

80105c1f <vector230>:
.globl vector230
vector230:
  pushl $0
80105c1f:	6a 00                	push   $0x0
  pushl $230
80105c21:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105c26:	e9 81 f2 ff ff       	jmp    80104eac <alltraps>

80105c2b <vector231>:
.globl vector231
vector231:
  pushl $0
80105c2b:	6a 00                	push   $0x0
  pushl $231
80105c2d:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105c32:	e9 75 f2 ff ff       	jmp    80104eac <alltraps>

80105c37 <vector232>:
.globl vector232
vector232:
  pushl $0
80105c37:	6a 00                	push   $0x0
  pushl $232
80105c39:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105c3e:	e9 69 f2 ff ff       	jmp    80104eac <alltraps>

80105c43 <vector233>:
.globl vector233
vector233:
  pushl $0
80105c43:	6a 00                	push   $0x0
  pushl $233
80105c45:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105c4a:	e9 5d f2 ff ff       	jmp    80104eac <alltraps>

80105c4f <vector234>:
.globl vector234
vector234:
  pushl $0
80105c4f:	6a 00                	push   $0x0
  pushl $234
80105c51:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105c56:	e9 51 f2 ff ff       	jmp    80104eac <alltraps>

80105c5b <vector235>:
.globl vector235
vector235:
  pushl $0
80105c5b:	6a 00                	push   $0x0
  pushl $235
80105c5d:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105c62:	e9 45 f2 ff ff       	jmp    80104eac <alltraps>

80105c67 <vector236>:
.globl vector236
vector236:
  pushl $0
80105c67:	6a 00                	push   $0x0
  pushl $236
80105c69:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105c6e:	e9 39 f2 ff ff       	jmp    80104eac <alltraps>

80105c73 <vector237>:
.globl vector237
vector237:
  pushl $0
80105c73:	6a 00                	push   $0x0
  pushl $237
80105c75:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105c7a:	e9 2d f2 ff ff       	jmp    80104eac <alltraps>

80105c7f <vector238>:
.globl vector238
vector238:
  pushl $0
80105c7f:	6a 00                	push   $0x0
  pushl $238
80105c81:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105c86:	e9 21 f2 ff ff       	jmp    80104eac <alltraps>

80105c8b <vector239>:
.globl vector239
vector239:
  pushl $0
80105c8b:	6a 00                	push   $0x0
  pushl $239
80105c8d:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105c92:	e9 15 f2 ff ff       	jmp    80104eac <alltraps>

80105c97 <vector240>:
.globl vector240
vector240:
  pushl $0
80105c97:	6a 00                	push   $0x0
  pushl $240
80105c99:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105c9e:	e9 09 f2 ff ff       	jmp    80104eac <alltraps>

80105ca3 <vector241>:
.globl vector241
vector241:
  pushl $0
80105ca3:	6a 00                	push   $0x0
  pushl $241
80105ca5:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105caa:	e9 fd f1 ff ff       	jmp    80104eac <alltraps>

80105caf <vector242>:
.globl vector242
vector242:
  pushl $0
80105caf:	6a 00                	push   $0x0
  pushl $242
80105cb1:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105cb6:	e9 f1 f1 ff ff       	jmp    80104eac <alltraps>

80105cbb <vector243>:
.globl vector243
vector243:
  pushl $0
80105cbb:	6a 00                	push   $0x0
  pushl $243
80105cbd:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105cc2:	e9 e5 f1 ff ff       	jmp    80104eac <alltraps>

80105cc7 <vector244>:
.globl vector244
vector244:
  pushl $0
80105cc7:	6a 00                	push   $0x0
  pushl $244
80105cc9:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105cce:	e9 d9 f1 ff ff       	jmp    80104eac <alltraps>

80105cd3 <vector245>:
.globl vector245
vector245:
  pushl $0
80105cd3:	6a 00                	push   $0x0
  pushl $245
80105cd5:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105cda:	e9 cd f1 ff ff       	jmp    80104eac <alltraps>

80105cdf <vector246>:
.globl vector246
vector246:
  pushl $0
80105cdf:	6a 00                	push   $0x0
  pushl $246
80105ce1:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105ce6:	e9 c1 f1 ff ff       	jmp    80104eac <alltraps>

80105ceb <vector247>:
.globl vector247
vector247:
  pushl $0
80105ceb:	6a 00                	push   $0x0
  pushl $247
80105ced:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105cf2:	e9 b5 f1 ff ff       	jmp    80104eac <alltraps>

80105cf7 <vector248>:
.globl vector248
vector248:
  pushl $0
80105cf7:	6a 00                	push   $0x0
  pushl $248
80105cf9:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105cfe:	e9 a9 f1 ff ff       	jmp    80104eac <alltraps>

80105d03 <vector249>:
.globl vector249
vector249:
  pushl $0
80105d03:	6a 00                	push   $0x0
  pushl $249
80105d05:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105d0a:	e9 9d f1 ff ff       	jmp    80104eac <alltraps>

80105d0f <vector250>:
.globl vector250
vector250:
  pushl $0
80105d0f:	6a 00                	push   $0x0
  pushl $250
80105d11:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105d16:	e9 91 f1 ff ff       	jmp    80104eac <alltraps>

80105d1b <vector251>:
.globl vector251
vector251:
  pushl $0
80105d1b:	6a 00                	push   $0x0
  pushl $251
80105d1d:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105d22:	e9 85 f1 ff ff       	jmp    80104eac <alltraps>

80105d27 <vector252>:
.globl vector252
vector252:
  pushl $0
80105d27:	6a 00                	push   $0x0
  pushl $252
80105d29:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105d2e:	e9 79 f1 ff ff       	jmp    80104eac <alltraps>

80105d33 <vector253>:
.globl vector253
vector253:
  pushl $0
80105d33:	6a 00                	push   $0x0
  pushl $253
80105d35:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105d3a:	e9 6d f1 ff ff       	jmp    80104eac <alltraps>

80105d3f <vector254>:
.globl vector254
vector254:
  pushl $0
80105d3f:	6a 00                	push   $0x0
  pushl $254
80105d41:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105d46:	e9 61 f1 ff ff       	jmp    80104eac <alltraps>

80105d4b <vector255>:
.globl vector255
vector255:
  pushl $0
80105d4b:	6a 00                	push   $0x0
  pushl $255
80105d4d:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105d52:	e9 55 f1 ff ff       	jmp    80104eac <alltraps>

80105d57 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105d57:	55                   	push   %ebp
80105d58:	89 e5                	mov    %esp,%ebp
80105d5a:	57                   	push   %edi
80105d5b:	56                   	push   %esi
80105d5c:	53                   	push   %ebx
80105d5d:	83 ec 0c             	sub    $0xc,%esp
80105d60:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105d62:	c1 ea 16             	shr    $0x16,%edx
80105d65:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105d68:	8b 1f                	mov    (%edi),%ebx
80105d6a:	f6 c3 01             	test   $0x1,%bl
80105d6d:	74 22                	je     80105d91 <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105d6f:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105d75:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105d7b:	c1 ee 0c             	shr    $0xc,%esi
80105d7e:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105d84:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105d87:	89 d8                	mov    %ebx,%eax
80105d89:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105d8c:	5b                   	pop    %ebx
80105d8d:	5e                   	pop    %esi
80105d8e:	5f                   	pop    %edi
80105d8f:	5d                   	pop    %ebp
80105d90:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc2(-2)) == 0)
80105d91:	85 c9                	test   %ecx,%ecx
80105d93:	74 33                	je     80105dc8 <walkpgdir+0x71>
80105d95:	83 ec 0c             	sub    $0xc,%esp
80105d98:	6a fe                	push   $0xfffffffe
80105d9a:	e8 bf c3 ff ff       	call   8010215e <kalloc2>
80105d9f:	89 c3                	mov    %eax,%ebx
80105da1:	83 c4 10             	add    $0x10,%esp
80105da4:	85 c0                	test   %eax,%eax
80105da6:	74 df                	je     80105d87 <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105da8:	83 ec 04             	sub    $0x4,%esp
80105dab:	68 00 10 00 00       	push   $0x1000
80105db0:	6a 00                	push   $0x0
80105db2:	50                   	push   %eax
80105db3:	e8 f6 df ff ff       	call   80103dae <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105db8:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105dbe:	83 c8 07             	or     $0x7,%eax
80105dc1:	89 07                	mov    %eax,(%edi)
80105dc3:	83 c4 10             	add    $0x10,%esp
80105dc6:	eb b3                	jmp    80105d7b <walkpgdir+0x24>
      return 0;
80105dc8:	bb 00 00 00 00       	mov    $0x0,%ebx
80105dcd:	eb b8                	jmp    80105d87 <walkpgdir+0x30>

80105dcf <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105dcf:	55                   	push   %ebp
80105dd0:	89 e5                	mov    %esp,%ebp
80105dd2:	57                   	push   %edi
80105dd3:	56                   	push   %esi
80105dd4:	53                   	push   %ebx
80105dd5:	83 ec 1c             	sub    $0x1c,%esp
80105dd8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105ddb:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105dde:	89 d3                	mov    %edx,%ebx
80105de0:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105de6:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105dea:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105df0:	b9 01 00 00 00       	mov    $0x1,%ecx
80105df5:	89 da                	mov    %ebx,%edx
80105df7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105dfa:	e8 58 ff ff ff       	call   80105d57 <walkpgdir>
80105dff:	85 c0                	test   %eax,%eax
80105e01:	74 2e                	je     80105e31 <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105e03:	f6 00 01             	testb  $0x1,(%eax)
80105e06:	75 1c                	jne    80105e24 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105e08:	89 f2                	mov    %esi,%edx
80105e0a:	0b 55 0c             	or     0xc(%ebp),%edx
80105e0d:	83 ca 01             	or     $0x1,%edx
80105e10:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105e12:	39 fb                	cmp    %edi,%ebx
80105e14:	74 28                	je     80105e3e <mappages+0x6f>
      break;
    a += PGSIZE;
80105e16:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105e1c:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105e22:	eb cc                	jmp    80105df0 <mappages+0x21>
      panic("remap");
80105e24:	83 ec 0c             	sub    $0xc,%esp
80105e27:	68 0c 6f 10 80       	push   $0x80106f0c
80105e2c:	e8 17 a5 ff ff       	call   80100348 <panic>
      return -1;
80105e31:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105e36:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105e39:	5b                   	pop    %ebx
80105e3a:	5e                   	pop    %esi
80105e3b:	5f                   	pop    %edi
80105e3c:	5d                   	pop    %ebp
80105e3d:	c3                   	ret    
  return 0;
80105e3e:	b8 00 00 00 00       	mov    $0x0,%eax
80105e43:	eb f1                	jmp    80105e36 <mappages+0x67>

80105e45 <seginit>:
{
80105e45:	55                   	push   %ebp
80105e46:	89 e5                	mov    %esp,%ebp
80105e48:	53                   	push   %ebx
80105e49:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105e4c:	e8 f4 d4 ff ff       	call   80103345 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105e51:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105e57:	66 c7 80 78 28 13 80 	movw   $0xffff,-0x7fecd788(%eax)
80105e5e:	ff ff 
80105e60:	66 c7 80 7a 28 13 80 	movw   $0x0,-0x7fecd786(%eax)
80105e67:	00 00 
80105e69:	c6 80 7c 28 13 80 00 	movb   $0x0,-0x7fecd784(%eax)
80105e70:	0f b6 88 7d 28 13 80 	movzbl -0x7fecd783(%eax),%ecx
80105e77:	83 e1 f0             	and    $0xfffffff0,%ecx
80105e7a:	83 c9 1a             	or     $0x1a,%ecx
80105e7d:	83 e1 9f             	and    $0xffffff9f,%ecx
80105e80:	83 c9 80             	or     $0xffffff80,%ecx
80105e83:	88 88 7d 28 13 80    	mov    %cl,-0x7fecd783(%eax)
80105e89:	0f b6 88 7e 28 13 80 	movzbl -0x7fecd782(%eax),%ecx
80105e90:	83 c9 0f             	or     $0xf,%ecx
80105e93:	83 e1 cf             	and    $0xffffffcf,%ecx
80105e96:	83 c9 c0             	or     $0xffffffc0,%ecx
80105e99:	88 88 7e 28 13 80    	mov    %cl,-0x7fecd782(%eax)
80105e9f:	c6 80 7f 28 13 80 00 	movb   $0x0,-0x7fecd781(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105ea6:	66 c7 80 80 28 13 80 	movw   $0xffff,-0x7fecd780(%eax)
80105ead:	ff ff 
80105eaf:	66 c7 80 82 28 13 80 	movw   $0x0,-0x7fecd77e(%eax)
80105eb6:	00 00 
80105eb8:	c6 80 84 28 13 80 00 	movb   $0x0,-0x7fecd77c(%eax)
80105ebf:	0f b6 88 85 28 13 80 	movzbl -0x7fecd77b(%eax),%ecx
80105ec6:	83 e1 f0             	and    $0xfffffff0,%ecx
80105ec9:	83 c9 12             	or     $0x12,%ecx
80105ecc:	83 e1 9f             	and    $0xffffff9f,%ecx
80105ecf:	83 c9 80             	or     $0xffffff80,%ecx
80105ed2:	88 88 85 28 13 80    	mov    %cl,-0x7fecd77b(%eax)
80105ed8:	0f b6 88 86 28 13 80 	movzbl -0x7fecd77a(%eax),%ecx
80105edf:	83 c9 0f             	or     $0xf,%ecx
80105ee2:	83 e1 cf             	and    $0xffffffcf,%ecx
80105ee5:	83 c9 c0             	or     $0xffffffc0,%ecx
80105ee8:	88 88 86 28 13 80    	mov    %cl,-0x7fecd77a(%eax)
80105eee:	c6 80 87 28 13 80 00 	movb   $0x0,-0x7fecd779(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80105ef5:	66 c7 80 88 28 13 80 	movw   $0xffff,-0x7fecd778(%eax)
80105efc:	ff ff 
80105efe:	66 c7 80 8a 28 13 80 	movw   $0x0,-0x7fecd776(%eax)
80105f05:	00 00 
80105f07:	c6 80 8c 28 13 80 00 	movb   $0x0,-0x7fecd774(%eax)
80105f0e:	c6 80 8d 28 13 80 fa 	movb   $0xfa,-0x7fecd773(%eax)
80105f15:	0f b6 88 8e 28 13 80 	movzbl -0x7fecd772(%eax),%ecx
80105f1c:	83 c9 0f             	or     $0xf,%ecx
80105f1f:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f22:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f25:	88 88 8e 28 13 80    	mov    %cl,-0x7fecd772(%eax)
80105f2b:	c6 80 8f 28 13 80 00 	movb   $0x0,-0x7fecd771(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80105f32:	66 c7 80 90 28 13 80 	movw   $0xffff,-0x7fecd770(%eax)
80105f39:	ff ff 
80105f3b:	66 c7 80 92 28 13 80 	movw   $0x0,-0x7fecd76e(%eax)
80105f42:	00 00 
80105f44:	c6 80 94 28 13 80 00 	movb   $0x0,-0x7fecd76c(%eax)
80105f4b:	c6 80 95 28 13 80 f2 	movb   $0xf2,-0x7fecd76b(%eax)
80105f52:	0f b6 88 96 28 13 80 	movzbl -0x7fecd76a(%eax),%ecx
80105f59:	83 c9 0f             	or     $0xf,%ecx
80105f5c:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f5f:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f62:	88 88 96 28 13 80    	mov    %cl,-0x7fecd76a(%eax)
80105f68:	c6 80 97 28 13 80 00 	movb   $0x0,-0x7fecd769(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80105f6f:	05 70 28 13 80       	add    $0x80132870,%eax
  pd[0] = size-1;
80105f74:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80105f7a:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80105f7e:	c1 e8 10             	shr    $0x10,%eax
80105f81:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80105f85:	8d 45 f2             	lea    -0xe(%ebp),%eax
80105f88:	0f 01 10             	lgdtl  (%eax)
}
80105f8b:	83 c4 14             	add    $0x14,%esp
80105f8e:	5b                   	pop    %ebx
80105f8f:	5d                   	pop    %ebp
80105f90:	c3                   	ret    

80105f91 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80105f91:	55                   	push   %ebp
80105f92:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80105f94:	a1 24 55 13 80       	mov    0x80135524,%eax
80105f99:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80105f9e:	0f 22 d8             	mov    %eax,%cr3
}
80105fa1:	5d                   	pop    %ebp
80105fa2:	c3                   	ret    

80105fa3 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80105fa3:	55                   	push   %ebp
80105fa4:	89 e5                	mov    %esp,%ebp
80105fa6:	57                   	push   %edi
80105fa7:	56                   	push   %esi
80105fa8:	53                   	push   %ebx
80105fa9:	83 ec 1c             	sub    $0x1c,%esp
80105fac:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
80105faf:	85 f6                	test   %esi,%esi
80105fb1:	0f 84 dd 00 00 00    	je     80106094 <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
80105fb7:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
80105fbb:	0f 84 e0 00 00 00    	je     801060a1 <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
80105fc1:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
80105fc5:	0f 84 e3 00 00 00    	je     801060ae <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
80105fcb:	e8 55 dc ff ff       	call   80103c25 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80105fd0:	e8 14 d3 ff ff       	call   801032e9 <mycpu>
80105fd5:	89 c3                	mov    %eax,%ebx
80105fd7:	e8 0d d3 ff ff       	call   801032e9 <mycpu>
80105fdc:	8d 78 08             	lea    0x8(%eax),%edi
80105fdf:	e8 05 d3 ff ff       	call   801032e9 <mycpu>
80105fe4:	83 c0 08             	add    $0x8,%eax
80105fe7:	c1 e8 10             	shr    $0x10,%eax
80105fea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105fed:	e8 f7 d2 ff ff       	call   801032e9 <mycpu>
80105ff2:	83 c0 08             	add    $0x8,%eax
80105ff5:	c1 e8 18             	shr    $0x18,%eax
80105ff8:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80105fff:	67 00 
80106001:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80106008:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
8010600c:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80106012:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80106019:	83 e2 f0             	and    $0xfffffff0,%edx
8010601c:	83 ca 19             	or     $0x19,%edx
8010601f:	83 e2 9f             	and    $0xffffff9f,%edx
80106022:	83 ca 80             	or     $0xffffff80,%edx
80106025:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
8010602b:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
80106032:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80106038:	e8 ac d2 ff ff       	call   801032e9 <mycpu>
8010603d:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80106044:	83 e2 ef             	and    $0xffffffef,%edx
80106047:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
8010604d:	e8 97 d2 ff ff       	call   801032e9 <mycpu>
80106052:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80106058:	8b 5e 08             	mov    0x8(%esi),%ebx
8010605b:	e8 89 d2 ff ff       	call   801032e9 <mycpu>
80106060:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106066:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
80106069:	e8 7b d2 ff ff       	call   801032e9 <mycpu>
8010606e:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
80106074:	b8 28 00 00 00       	mov    $0x28,%eax
80106079:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
8010607c:	8b 46 04             	mov    0x4(%esi),%eax
8010607f:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
80106084:	0f 22 d8             	mov    %eax,%cr3
  popcli();
80106087:	e8 d6 db ff ff       	call   80103c62 <popcli>
}
8010608c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010608f:	5b                   	pop    %ebx
80106090:	5e                   	pop    %esi
80106091:	5f                   	pop    %edi
80106092:	5d                   	pop    %ebp
80106093:	c3                   	ret    
    panic("switchuvm: no process");
80106094:	83 ec 0c             	sub    $0xc,%esp
80106097:	68 12 6f 10 80       	push   $0x80106f12
8010609c:	e8 a7 a2 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
801060a1:	83 ec 0c             	sub    $0xc,%esp
801060a4:	68 28 6f 10 80       	push   $0x80106f28
801060a9:	e8 9a a2 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
801060ae:	83 ec 0c             	sub    $0xc,%esp
801060b1:	68 3d 6f 10 80       	push   $0x80106f3d
801060b6:	e8 8d a2 ff ff       	call   80100348 <panic>

801060bb <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801060bb:	55                   	push   %ebp
801060bc:	89 e5                	mov    %esp,%ebp
801060be:	56                   	push   %esi
801060bf:	53                   	push   %ebx
801060c0:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
801060c3:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801060c9:	77 51                	ja     8010611c <inituvm+0x61>
    panic("inituvm: more than a page");
  mem = kalloc2(-2);
801060cb:	83 ec 0c             	sub    $0xc,%esp
801060ce:	6a fe                	push   $0xfffffffe
801060d0:	e8 89 c0 ff ff       	call   8010215e <kalloc2>
801060d5:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
801060d7:	83 c4 0c             	add    $0xc,%esp
801060da:	68 00 10 00 00       	push   $0x1000
801060df:	6a 00                	push   $0x0
801060e1:	50                   	push   %eax
801060e2:	e8 c7 dc ff ff       	call   80103dae <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
801060e7:	83 c4 08             	add    $0x8,%esp
801060ea:	6a 06                	push   $0x6
801060ec:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801060f2:	50                   	push   %eax
801060f3:	b9 00 10 00 00       	mov    $0x1000,%ecx
801060f8:	ba 00 00 00 00       	mov    $0x0,%edx
801060fd:	8b 45 08             	mov    0x8(%ebp),%eax
80106100:	e8 ca fc ff ff       	call   80105dcf <mappages>
  memmove(mem, init, sz);
80106105:	83 c4 0c             	add    $0xc,%esp
80106108:	56                   	push   %esi
80106109:	ff 75 0c             	pushl  0xc(%ebp)
8010610c:	53                   	push   %ebx
8010610d:	e8 17 dd ff ff       	call   80103e29 <memmove>
}
80106112:	83 c4 10             	add    $0x10,%esp
80106115:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106118:	5b                   	pop    %ebx
80106119:	5e                   	pop    %esi
8010611a:	5d                   	pop    %ebp
8010611b:	c3                   	ret    
    panic("inituvm: more than a page");
8010611c:	83 ec 0c             	sub    $0xc,%esp
8010611f:	68 51 6f 10 80       	push   $0x80106f51
80106124:	e8 1f a2 ff ff       	call   80100348 <panic>

80106129 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80106129:	55                   	push   %ebp
8010612a:	89 e5                	mov    %esp,%ebp
8010612c:	57                   	push   %edi
8010612d:	56                   	push   %esi
8010612e:	53                   	push   %ebx
8010612f:	83 ec 0c             	sub    $0xc,%esp
80106132:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80106135:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
8010613c:	75 07                	jne    80106145 <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
8010613e:	bb 00 00 00 00       	mov    $0x0,%ebx
80106143:	eb 3c                	jmp    80106181 <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
80106145:	83 ec 0c             	sub    $0xc,%esp
80106148:	68 0c 70 10 80       	push   $0x8010700c
8010614d:	e8 f6 a1 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
80106152:	83 ec 0c             	sub    $0xc,%esp
80106155:	68 6b 6f 10 80       	push   $0x80106f6b
8010615a:	e8 e9 a1 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
8010615f:	05 00 00 00 80       	add    $0x80000000,%eax
80106164:	56                   	push   %esi
80106165:	89 da                	mov    %ebx,%edx
80106167:	03 55 14             	add    0x14(%ebp),%edx
8010616a:	52                   	push   %edx
8010616b:	50                   	push   %eax
8010616c:	ff 75 10             	pushl  0x10(%ebp)
8010616f:	e8 ff b5 ff ff       	call   80101773 <readi>
80106174:	83 c4 10             	add    $0x10,%esp
80106177:	39 f0                	cmp    %esi,%eax
80106179:	75 47                	jne    801061c2 <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
8010617b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106181:	39 fb                	cmp    %edi,%ebx
80106183:	73 30                	jae    801061b5 <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80106185:	89 da                	mov    %ebx,%edx
80106187:	03 55 0c             	add    0xc(%ebp),%edx
8010618a:	b9 00 00 00 00       	mov    $0x0,%ecx
8010618f:	8b 45 08             	mov    0x8(%ebp),%eax
80106192:	e8 c0 fb ff ff       	call   80105d57 <walkpgdir>
80106197:	85 c0                	test   %eax,%eax
80106199:	74 b7                	je     80106152 <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
8010619b:	8b 00                	mov    (%eax),%eax
8010619d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
801061a2:	89 fe                	mov    %edi,%esi
801061a4:	29 de                	sub    %ebx,%esi
801061a6:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801061ac:	76 b1                	jbe    8010615f <loaduvm+0x36>
      n = PGSIZE;
801061ae:	be 00 10 00 00       	mov    $0x1000,%esi
801061b3:	eb aa                	jmp    8010615f <loaduvm+0x36>
      return -1;
  }
  return 0;
801061b5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061ba:	8d 65 f4             	lea    -0xc(%ebp),%esp
801061bd:	5b                   	pop    %ebx
801061be:	5e                   	pop    %esi
801061bf:	5f                   	pop    %edi
801061c0:	5d                   	pop    %ebp
801061c1:	c3                   	ret    
      return -1;
801061c2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061c7:	eb f1                	jmp    801061ba <loaduvm+0x91>

801061c9 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801061c9:	55                   	push   %ebp
801061ca:	89 e5                	mov    %esp,%ebp
801061cc:	57                   	push   %edi
801061cd:	56                   	push   %esi
801061ce:	53                   	push   %ebx
801061cf:	83 ec 0c             	sub    $0xc,%esp
801061d2:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801061d5:	39 7d 10             	cmp    %edi,0x10(%ebp)
801061d8:	73 11                	jae    801061eb <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
801061da:	8b 45 10             	mov    0x10(%ebp),%eax
801061dd:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801061e3:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801061e9:	eb 19                	jmp    80106204 <deallocuvm+0x3b>
    return oldsz;
801061eb:	89 f8                	mov    %edi,%eax
801061ed:	eb 64                	jmp    80106253 <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
801061ef:	c1 eb 16             	shr    $0x16,%ebx
801061f2:	83 c3 01             	add    $0x1,%ebx
801061f5:	c1 e3 16             	shl    $0x16,%ebx
801061f8:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801061fe:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106204:	39 fb                	cmp    %edi,%ebx
80106206:	73 48                	jae    80106250 <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
80106208:	b9 00 00 00 00       	mov    $0x0,%ecx
8010620d:	89 da                	mov    %ebx,%edx
8010620f:	8b 45 08             	mov    0x8(%ebp),%eax
80106212:	e8 40 fb ff ff       	call   80105d57 <walkpgdir>
80106217:	89 c6                	mov    %eax,%esi
    if(!pte)
80106219:	85 c0                	test   %eax,%eax
8010621b:	74 d2                	je     801061ef <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
8010621d:	8b 00                	mov    (%eax),%eax
8010621f:	a8 01                	test   $0x1,%al
80106221:	74 db                	je     801061fe <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
80106223:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106228:	74 19                	je     80106243 <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
8010622a:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
8010622f:	83 ec 0c             	sub    $0xc,%esp
80106232:	50                   	push   %eax
80106233:	e8 6c bd ff ff       	call   80101fa4 <kfree>
      *pte = 0;
80106238:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
8010623e:	83 c4 10             	add    $0x10,%esp
80106241:	eb bb                	jmp    801061fe <deallocuvm+0x35>
        panic("kfree");
80106243:	83 ec 0c             	sub    $0xc,%esp
80106246:	68 a6 68 10 80       	push   $0x801068a6
8010624b:	e8 f8 a0 ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
80106250:	8b 45 10             	mov    0x10(%ebp),%eax
}
80106253:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106256:	5b                   	pop    %ebx
80106257:	5e                   	pop    %esi
80106258:	5f                   	pop    %edi
80106259:	5d                   	pop    %ebp
8010625a:	c3                   	ret    

8010625b <allocuvm>:
{
8010625b:	55                   	push   %ebp
8010625c:	89 e5                	mov    %esp,%ebp
8010625e:	57                   	push   %edi
8010625f:	56                   	push   %esi
80106260:	53                   	push   %ebx
80106261:	83 ec 1c             	sub    $0x1c,%esp
80106264:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
80106267:	89 7d e4             	mov    %edi,-0x1c(%ebp)
8010626a:	85 ff                	test   %edi,%edi
8010626c:	0f 88 cf 00 00 00    	js     80106341 <allocuvm+0xe6>
  if(newsz < oldsz)
80106272:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106275:	72 6a                	jb     801062e1 <allocuvm+0x86>
  a = PGROUNDUP(oldsz);
80106277:	8b 45 0c             	mov    0xc(%ebp),%eax
8010627a:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106280:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
80106286:	39 fb                	cmp    %edi,%ebx
80106288:	0f 83 ba 00 00 00    	jae    80106348 <allocuvm+0xed>
    mem = kalloc2(myproc()->pid);
8010628e:	e8 cd d0 ff ff       	call   80103360 <myproc>
80106293:	83 ec 0c             	sub    $0xc,%esp
80106296:	ff 70 10             	pushl  0x10(%eax)
80106299:	e8 c0 be ff ff       	call   8010215e <kalloc2>
8010629e:	89 c6                	mov    %eax,%esi
    if(mem == 0){
801062a0:	83 c4 10             	add    $0x10,%esp
801062a3:	85 c0                	test   %eax,%eax
801062a5:	74 42                	je     801062e9 <allocuvm+0x8e>
    memset(mem, 0, PGSIZE);
801062a7:	83 ec 04             	sub    $0x4,%esp
801062aa:	68 00 10 00 00       	push   $0x1000
801062af:	6a 00                	push   $0x0
801062b1:	50                   	push   %eax
801062b2:	e8 f7 da ff ff       	call   80103dae <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
801062b7:	83 c4 08             	add    $0x8,%esp
801062ba:	6a 06                	push   $0x6
801062bc:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
801062c2:	50                   	push   %eax
801062c3:	b9 00 10 00 00       	mov    $0x1000,%ecx
801062c8:	89 da                	mov    %ebx,%edx
801062ca:	8b 45 08             	mov    0x8(%ebp),%eax
801062cd:	e8 fd fa ff ff       	call   80105dcf <mappages>
801062d2:	83 c4 10             	add    $0x10,%esp
801062d5:	85 c0                	test   %eax,%eax
801062d7:	78 38                	js     80106311 <allocuvm+0xb6>
  for(; a < newsz; a += PGSIZE){
801062d9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801062df:	eb a5                	jmp    80106286 <allocuvm+0x2b>
    return oldsz;
801062e1:	8b 45 0c             	mov    0xc(%ebp),%eax
801062e4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801062e7:	eb 5f                	jmp    80106348 <allocuvm+0xed>
      cprintf("allocuvm out of memory\n");
801062e9:	83 ec 0c             	sub    $0xc,%esp
801062ec:	68 89 6f 10 80       	push   $0x80106f89
801062f1:	e8 15 a3 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801062f6:	83 c4 0c             	add    $0xc,%esp
801062f9:	ff 75 0c             	pushl  0xc(%ebp)
801062fc:	57                   	push   %edi
801062fd:	ff 75 08             	pushl  0x8(%ebp)
80106300:	e8 c4 fe ff ff       	call   801061c9 <deallocuvm>
      return 0;
80106305:	83 c4 10             	add    $0x10,%esp
80106308:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010630f:	eb 37                	jmp    80106348 <allocuvm+0xed>
      cprintf("allocuvm out of memory (2)\n");
80106311:	83 ec 0c             	sub    $0xc,%esp
80106314:	68 a1 6f 10 80       	push   $0x80106fa1
80106319:	e8 ed a2 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010631e:	83 c4 0c             	add    $0xc,%esp
80106321:	ff 75 0c             	pushl  0xc(%ebp)
80106324:	57                   	push   %edi
80106325:	ff 75 08             	pushl  0x8(%ebp)
80106328:	e8 9c fe ff ff       	call   801061c9 <deallocuvm>
      kfree(mem);
8010632d:	89 34 24             	mov    %esi,(%esp)
80106330:	e8 6f bc ff ff       	call   80101fa4 <kfree>
      return 0;
80106335:	83 c4 10             	add    $0x10,%esp
80106338:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010633f:	eb 07                	jmp    80106348 <allocuvm+0xed>
    return 0;
80106341:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
80106348:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010634b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010634e:	5b                   	pop    %ebx
8010634f:	5e                   	pop    %esi
80106350:	5f                   	pop    %edi
80106351:	5d                   	pop    %ebp
80106352:	c3                   	ret    

80106353 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80106353:	55                   	push   %ebp
80106354:	89 e5                	mov    %esp,%ebp
80106356:	56                   	push   %esi
80106357:	53                   	push   %ebx
80106358:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
8010635b:	85 f6                	test   %esi,%esi
8010635d:	74 1a                	je     80106379 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
8010635f:	83 ec 04             	sub    $0x4,%esp
80106362:	6a 00                	push   $0x0
80106364:	68 00 00 00 80       	push   $0x80000000
80106369:	56                   	push   %esi
8010636a:	e8 5a fe ff ff       	call   801061c9 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
8010636f:	83 c4 10             	add    $0x10,%esp
80106372:	bb 00 00 00 00       	mov    $0x0,%ebx
80106377:	eb 10                	jmp    80106389 <freevm+0x36>
    panic("freevm: no pgdir");
80106379:	83 ec 0c             	sub    $0xc,%esp
8010637c:	68 bd 6f 10 80       	push   $0x80106fbd
80106381:	e8 c2 9f ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
80106386:	83 c3 01             	add    $0x1,%ebx
80106389:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
8010638f:	77 1f                	ja     801063b0 <freevm+0x5d>
    if(pgdir[i] & PTE_P){
80106391:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
80106394:	a8 01                	test   $0x1,%al
80106396:	74 ee                	je     80106386 <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
80106398:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010639d:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801063a2:	83 ec 0c             	sub    $0xc,%esp
801063a5:	50                   	push   %eax
801063a6:	e8 f9 bb ff ff       	call   80101fa4 <kfree>
801063ab:	83 c4 10             	add    $0x10,%esp
801063ae:	eb d6                	jmp    80106386 <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
801063b0:	83 ec 0c             	sub    $0xc,%esp
801063b3:	56                   	push   %esi
801063b4:	e8 eb bb ff ff       	call   80101fa4 <kfree>
}
801063b9:	83 c4 10             	add    $0x10,%esp
801063bc:	8d 65 f8             	lea    -0x8(%ebp),%esp
801063bf:	5b                   	pop    %ebx
801063c0:	5e                   	pop    %esi
801063c1:	5d                   	pop    %ebp
801063c2:	c3                   	ret    

801063c3 <setupkvm>:
{
801063c3:	55                   	push   %ebp
801063c4:	89 e5                	mov    %esp,%ebp
801063c6:	56                   	push   %esi
801063c7:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc2(-2)) == 0)
801063c8:	83 ec 0c             	sub    $0xc,%esp
801063cb:	6a fe                	push   $0xfffffffe
801063cd:	e8 8c bd ff ff       	call   8010215e <kalloc2>
801063d2:	89 c6                	mov    %eax,%esi
801063d4:	83 c4 10             	add    $0x10,%esp
801063d7:	85 c0                	test   %eax,%eax
801063d9:	74 55                	je     80106430 <setupkvm+0x6d>
  memset(pgdir, 0, PGSIZE);
801063db:	83 ec 04             	sub    $0x4,%esp
801063de:	68 00 10 00 00       	push   $0x1000
801063e3:	6a 00                	push   $0x0
801063e5:	50                   	push   %eax
801063e6:	e8 c3 d9 ff ff       	call   80103dae <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801063eb:	83 c4 10             	add    $0x10,%esp
801063ee:	bb 20 a4 10 80       	mov    $0x8010a420,%ebx
801063f3:	81 fb 60 a4 10 80    	cmp    $0x8010a460,%ebx
801063f9:	73 35                	jae    80106430 <setupkvm+0x6d>
                (uint)k->phys_start, k->perm) < 0) {
801063fb:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
801063fe:	8b 4b 08             	mov    0x8(%ebx),%ecx
80106401:	29 c1                	sub    %eax,%ecx
80106403:	83 ec 08             	sub    $0x8,%esp
80106406:	ff 73 0c             	pushl  0xc(%ebx)
80106409:	50                   	push   %eax
8010640a:	8b 13                	mov    (%ebx),%edx
8010640c:	89 f0                	mov    %esi,%eax
8010640e:	e8 bc f9 ff ff       	call   80105dcf <mappages>
80106413:	83 c4 10             	add    $0x10,%esp
80106416:	85 c0                	test   %eax,%eax
80106418:	78 05                	js     8010641f <setupkvm+0x5c>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010641a:	83 c3 10             	add    $0x10,%ebx
8010641d:	eb d4                	jmp    801063f3 <setupkvm+0x30>
      freevm(pgdir);
8010641f:	83 ec 0c             	sub    $0xc,%esp
80106422:	56                   	push   %esi
80106423:	e8 2b ff ff ff       	call   80106353 <freevm>
      return 0;
80106428:	83 c4 10             	add    $0x10,%esp
8010642b:	be 00 00 00 00       	mov    $0x0,%esi
}
80106430:	89 f0                	mov    %esi,%eax
80106432:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106435:	5b                   	pop    %ebx
80106436:	5e                   	pop    %esi
80106437:	5d                   	pop    %ebp
80106438:	c3                   	ret    

80106439 <kvmalloc>:
{
80106439:	55                   	push   %ebp
8010643a:	89 e5                	mov    %esp,%ebp
8010643c:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
8010643f:	e8 7f ff ff ff       	call   801063c3 <setupkvm>
80106444:	a3 24 55 13 80       	mov    %eax,0x80135524
  switchkvm();
80106449:	e8 43 fb ff ff       	call   80105f91 <switchkvm>
}
8010644e:	c9                   	leave  
8010644f:	c3                   	ret    

80106450 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80106450:	55                   	push   %ebp
80106451:	89 e5                	mov    %esp,%ebp
80106453:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106456:	b9 00 00 00 00       	mov    $0x0,%ecx
8010645b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010645e:	8b 45 08             	mov    0x8(%ebp),%eax
80106461:	e8 f1 f8 ff ff       	call   80105d57 <walkpgdir>
  if(pte == 0)
80106466:	85 c0                	test   %eax,%eax
80106468:	74 05                	je     8010646f <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
8010646a:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
8010646d:	c9                   	leave  
8010646e:	c3                   	ret    
    panic("clearpteu");
8010646f:	83 ec 0c             	sub    $0xc,%esp
80106472:	68 ce 6f 10 80       	push   $0x80106fce
80106477:	e8 cc 9e ff ff       	call   80100348 <panic>

8010647c <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz, uint childPid)
{
8010647c:	55                   	push   %ebp
8010647d:	89 e5                	mov    %esp,%ebp
8010647f:	57                   	push   %edi
80106480:	56                   	push   %esi
80106481:	53                   	push   %ebx
80106482:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80106485:	e8 39 ff ff ff       	call   801063c3 <setupkvm>
8010648a:	89 45 dc             	mov    %eax,-0x24(%ebp)
8010648d:	85 c0                	test   %eax,%eax
8010648f:	0f 84 d1 00 00 00    	je     80106566 <copyuvm+0xea>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80106495:	bf 00 00 00 00       	mov    $0x0,%edi
8010649a:	89 fe                	mov    %edi,%esi
8010649c:	3b 75 0c             	cmp    0xc(%ebp),%esi
8010649f:	0f 83 c1 00 00 00    	jae    80106566 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801064a5:	89 75 e4             	mov    %esi,-0x1c(%ebp)
801064a8:	b9 00 00 00 00       	mov    $0x0,%ecx
801064ad:	89 f2                	mov    %esi,%edx
801064af:	8b 45 08             	mov    0x8(%ebp),%eax
801064b2:	e8 a0 f8 ff ff       	call   80105d57 <walkpgdir>
801064b7:	85 c0                	test   %eax,%eax
801064b9:	74 70                	je     8010652b <copyuvm+0xaf>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
801064bb:	8b 18                	mov    (%eax),%ebx
801064bd:	f6 c3 01             	test   $0x1,%bl
801064c0:	74 76                	je     80106538 <copyuvm+0xbc>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
801064c2:	89 df                	mov    %ebx,%edi
801064c4:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
    flags = PTE_FLAGS(*pte);
801064ca:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
801064d0:	89 5d e0             	mov    %ebx,-0x20(%ebp)
    if((mem = kalloc2(childPid)) == 0)
801064d3:	83 ec 0c             	sub    $0xc,%esp
801064d6:	ff 75 10             	pushl  0x10(%ebp)
801064d9:	e8 80 bc ff ff       	call   8010215e <kalloc2>
801064de:	89 c3                	mov    %eax,%ebx
801064e0:	83 c4 10             	add    $0x10,%esp
801064e3:	85 c0                	test   %eax,%eax
801064e5:	74 6a                	je     80106551 <copyuvm+0xd5>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
801064e7:	81 c7 00 00 00 80    	add    $0x80000000,%edi
801064ed:	83 ec 04             	sub    $0x4,%esp
801064f0:	68 00 10 00 00       	push   $0x1000
801064f5:	57                   	push   %edi
801064f6:	50                   	push   %eax
801064f7:	e8 2d d9 ff ff       	call   80103e29 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
801064fc:	83 c4 08             	add    $0x8,%esp
801064ff:	ff 75 e0             	pushl  -0x20(%ebp)
80106502:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106508:	50                   	push   %eax
80106509:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010650e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106511:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106514:	e8 b6 f8 ff ff       	call   80105dcf <mappages>
80106519:	83 c4 10             	add    $0x10,%esp
8010651c:	85 c0                	test   %eax,%eax
8010651e:	78 25                	js     80106545 <copyuvm+0xc9>
  for(i = 0; i < sz; i += PGSIZE){
80106520:	81 c6 00 10 00 00    	add    $0x1000,%esi
80106526:	e9 71 ff ff ff       	jmp    8010649c <copyuvm+0x20>
      panic("copyuvm: pte should exist");
8010652b:	83 ec 0c             	sub    $0xc,%esp
8010652e:	68 d8 6f 10 80       	push   $0x80106fd8
80106533:	e8 10 9e ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
80106538:	83 ec 0c             	sub    $0xc,%esp
8010653b:	68 f2 6f 10 80       	push   $0x80106ff2
80106540:	e8 03 9e ff ff       	call   80100348 <panic>
      kfree(mem);
80106545:	83 ec 0c             	sub    $0xc,%esp
80106548:	53                   	push   %ebx
80106549:	e8 56 ba ff ff       	call   80101fa4 <kfree>
      goto bad;
8010654e:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
80106551:	83 ec 0c             	sub    $0xc,%esp
80106554:	ff 75 dc             	pushl  -0x24(%ebp)
80106557:	e8 f7 fd ff ff       	call   80106353 <freevm>
  return 0;
8010655c:	83 c4 10             	add    $0x10,%esp
8010655f:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
80106566:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106569:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010656c:	5b                   	pop    %ebx
8010656d:	5e                   	pop    %esi
8010656e:	5f                   	pop    %edi
8010656f:	5d                   	pop    %ebp
80106570:	c3                   	ret    

80106571 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80106571:	55                   	push   %ebp
80106572:	89 e5                	mov    %esp,%ebp
80106574:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106577:	b9 00 00 00 00       	mov    $0x0,%ecx
8010657c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010657f:	8b 45 08             	mov    0x8(%ebp),%eax
80106582:	e8 d0 f7 ff ff       	call   80105d57 <walkpgdir>
  if((*pte & PTE_P) == 0)
80106587:	8b 00                	mov    (%eax),%eax
80106589:	a8 01                	test   $0x1,%al
8010658b:	74 10                	je     8010659d <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
8010658d:	a8 04                	test   $0x4,%al
8010658f:	74 13                	je     801065a4 <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
80106591:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106596:	05 00 00 00 80       	add    $0x80000000,%eax
}
8010659b:	c9                   	leave  
8010659c:	c3                   	ret    
    return 0;
8010659d:	b8 00 00 00 00       	mov    $0x0,%eax
801065a2:	eb f7                	jmp    8010659b <uva2ka+0x2a>
    return 0;
801065a4:	b8 00 00 00 00       	mov    $0x0,%eax
801065a9:	eb f0                	jmp    8010659b <uva2ka+0x2a>

801065ab <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801065ab:	55                   	push   %ebp
801065ac:	89 e5                	mov    %esp,%ebp
801065ae:	57                   	push   %edi
801065af:	56                   	push   %esi
801065b0:	53                   	push   %ebx
801065b1:	83 ec 0c             	sub    $0xc,%esp
801065b4:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801065b7:	eb 25                	jmp    801065de <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
801065b9:	8b 55 0c             	mov    0xc(%ebp),%edx
801065bc:	29 f2                	sub    %esi,%edx
801065be:	01 d0                	add    %edx,%eax
801065c0:	83 ec 04             	sub    $0x4,%esp
801065c3:	53                   	push   %ebx
801065c4:	ff 75 10             	pushl  0x10(%ebp)
801065c7:	50                   	push   %eax
801065c8:	e8 5c d8 ff ff       	call   80103e29 <memmove>
    len -= n;
801065cd:	29 df                	sub    %ebx,%edi
    buf += n;
801065cf:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
801065d2:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
801065d8:	89 45 0c             	mov    %eax,0xc(%ebp)
801065db:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
801065de:	85 ff                	test   %edi,%edi
801065e0:	74 2f                	je     80106611 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
801065e2:	8b 75 0c             	mov    0xc(%ebp),%esi
801065e5:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
801065eb:	83 ec 08             	sub    $0x8,%esp
801065ee:	56                   	push   %esi
801065ef:	ff 75 08             	pushl  0x8(%ebp)
801065f2:	e8 7a ff ff ff       	call   80106571 <uva2ka>
    if(pa0 == 0)
801065f7:	83 c4 10             	add    $0x10,%esp
801065fa:	85 c0                	test   %eax,%eax
801065fc:	74 20                	je     8010661e <copyout+0x73>
    n = PGSIZE - (va - va0);
801065fe:	89 f3                	mov    %esi,%ebx
80106600:	2b 5d 0c             	sub    0xc(%ebp),%ebx
80106603:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
80106609:	39 df                	cmp    %ebx,%edi
8010660b:	73 ac                	jae    801065b9 <copyout+0xe>
      n = len;
8010660d:	89 fb                	mov    %edi,%ebx
8010660f:	eb a8                	jmp    801065b9 <copyout+0xe>
  }
  return 0;
80106611:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106616:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106619:	5b                   	pop    %ebx
8010661a:	5e                   	pop    %esi
8010661b:	5f                   	pop    %edi
8010661c:	5d                   	pop    %ebp
8010661d:	c3                   	ret    
      return -1;
8010661e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106623:	eb f1                	jmp    80106616 <copyout+0x6b>
