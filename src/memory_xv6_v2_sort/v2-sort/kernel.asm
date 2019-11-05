
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
80100028:	bc c0 b5 10 80       	mov    $0x8010b5c0,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 06 2d 10 80       	mov    $0x80102d06,%eax
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
80100041:	68 c0 b5 10 80       	push   $0x8010b5c0
80100046:	e8 fd 3d 00 00       	call   80103e48 <acquire>

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010004b:	8b 1d 10 fd 10 80    	mov    0x8010fd10,%ebx
80100051:	83 c4 10             	add    $0x10,%esp
80100054:	eb 03                	jmp    80100059 <bget+0x25>
80100056:	8b 5b 54             	mov    0x54(%ebx),%ebx
80100059:	81 fb bc fc 10 80    	cmp    $0x8010fcbc,%ebx
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
80100077:	68 c0 b5 10 80       	push   $0x8010b5c0
8010007c:	e8 2c 3e 00 00       	call   80103ead <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 a8 3b 00 00       	call   80103c34 <acquiresleep>
      return b;
8010008c:	83 c4 10             	add    $0x10,%esp
8010008f:	eb 4c                	jmp    801000dd <bget+0xa9>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100091:	8b 1d 0c fd 10 80    	mov    0x8010fd0c,%ebx
80100097:	eb 03                	jmp    8010009c <bget+0x68>
80100099:	8b 5b 50             	mov    0x50(%ebx),%ebx
8010009c:	81 fb bc fc 10 80    	cmp    $0x8010fcbc,%ebx
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
801000c5:	68 c0 b5 10 80       	push   $0x8010b5c0
801000ca:	e8 de 3d 00 00       	call   80103ead <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 5a 3b 00 00       	call   80103c34 <acquiresleep>
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
801000ea:	68 60 67 10 80       	push   $0x80106760
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 71 67 10 80       	push   $0x80106771
80100100:	68 c0 b5 10 80       	push   $0x8010b5c0
80100105:	e8 02 3c 00 00       	call   80103d0c <initlock>
  bcache.head.prev = &bcache.head;
8010010a:	c7 05 0c fd 10 80 bc 	movl   $0x8010fcbc,0x8010fd0c
80100111:	fc 10 80 
  bcache.head.next = &bcache.head;
80100114:	c7 05 10 fd 10 80 bc 	movl   $0x8010fcbc,0x8010fd10
8010011b:	fc 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010011e:	83 c4 10             	add    $0x10,%esp
80100121:	bb f4 b5 10 80       	mov    $0x8010b5f4,%ebx
80100126:	eb 37                	jmp    8010015f <binit+0x6b>
    b->next = bcache.head.next;
80100128:	a1 10 fd 10 80       	mov    0x8010fd10,%eax
8010012d:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
80100130:	c7 43 50 bc fc 10 80 	movl   $0x8010fcbc,0x50(%ebx)
    initsleeplock(&b->lock, "buffer");
80100137:	83 ec 08             	sub    $0x8,%esp
8010013a:	68 78 67 10 80       	push   $0x80106778
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 b9 3a 00 00       	call   80103c01 <initsleeplock>
    bcache.head.next->prev = b;
80100148:	a1 10 fd 10 80       	mov    0x8010fd10,%eax
8010014d:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
80100150:	89 1d 10 fd 10 80    	mov    %ebx,0x8010fd10
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100156:	81 c3 5c 02 00 00    	add    $0x25c,%ebx
8010015c:	83 c4 10             	add    $0x10,%esp
8010015f:	81 fb bc fc 10 80    	cmp    $0x8010fcbc,%ebx
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
80100190:	e8 83 1c 00 00       	call   80101e18 <iderw>
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
801001a8:	e8 11 3b 00 00       	call   80103cbe <holdingsleep>
801001ad:	83 c4 10             	add    $0x10,%esp
801001b0:	85 c0                	test   %eax,%eax
801001b2:	74 14                	je     801001c8 <bwrite+0x2e>
    panic("bwrite");
  b->flags |= B_DIRTY;
801001b4:	83 0b 04             	orl    $0x4,(%ebx)
  iderw(b);
801001b7:	83 ec 0c             	sub    $0xc,%esp
801001ba:	53                   	push   %ebx
801001bb:	e8 58 1c 00 00       	call   80101e18 <iderw>
}
801001c0:	83 c4 10             	add    $0x10,%esp
801001c3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801001c6:	c9                   	leave  
801001c7:	c3                   	ret    
    panic("bwrite");
801001c8:	83 ec 0c             	sub    $0xc,%esp
801001cb:	68 7f 67 10 80       	push   $0x8010677f
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
801001e4:	e8 d5 3a 00 00       	call   80103cbe <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 8a 3a 00 00       	call   80103c83 <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100200:	e8 43 3c 00 00       	call   80103e48 <acquire>
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
80100227:	a1 10 fd 10 80       	mov    0x8010fd10,%eax
8010022c:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
8010022f:	c7 43 50 bc fc 10 80 	movl   $0x8010fcbc,0x50(%ebx)
    bcache.head.next->prev = b;
80100236:	a1 10 fd 10 80       	mov    0x8010fd10,%eax
8010023b:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
8010023e:	89 1d 10 fd 10 80    	mov    %ebx,0x8010fd10
  }
  
  release(&bcache.lock);
80100244:	83 ec 0c             	sub    $0xc,%esp
80100247:	68 c0 b5 10 80       	push   $0x8010b5c0
8010024c:	e8 5c 3c 00 00       	call   80103ead <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 86 67 10 80       	push   $0x80106786
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
8010027b:	e8 cf 13 00 00       	call   8010164f <iunlock>
  target = n;
80100280:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  acquire(&cons.lock);
80100283:	c7 04 24 20 a5 10 80 	movl   $0x8010a520,(%esp)
8010028a:	e8 b9 3b 00 00       	call   80103e48 <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 a0 ff 10 80       	mov    0x8010ffa0,%eax
8010029f:	3b 05 a4 ff 10 80    	cmp    0x8010ffa4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 fa 31 00 00       	call   801034a6 <myproc>
801002ac:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801002b0:	75 17                	jne    801002c9 <consoleread+0x61>
        release(&cons.lock);
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
801002b2:	83 ec 08             	sub    $0x8,%esp
801002b5:	68 20 a5 10 80       	push   $0x8010a520
801002ba:	68 a0 ff 10 80       	push   $0x8010ffa0
801002bf:	e8 89 36 00 00       	call   8010394d <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 a5 10 80       	push   $0x8010a520
801002d1:	e8 d7 3b 00 00       	call   80103ead <release>
        ilock(ip);
801002d6:	89 3c 24             	mov    %edi,(%esp)
801002d9:	e8 af 12 00 00       	call   8010158d <ilock>
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
801002f1:	89 15 a0 ff 10 80    	mov    %edx,0x8010ffa0
801002f7:	89 c2                	mov    %eax,%edx
801002f9:	83 e2 7f             	and    $0x7f,%edx
801002fc:	0f b6 8a 20 ff 10 80 	movzbl -0x7fef00e0(%edx),%ecx
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
80100324:	a3 a0 ff 10 80       	mov    %eax,0x8010ffa0
  release(&cons.lock);
80100329:	83 ec 0c             	sub    $0xc,%esp
8010032c:	68 20 a5 10 80       	push   $0x8010a520
80100331:	e8 77 3b 00 00       	call   80103ead <release>
  ilock(ip);
80100336:	89 3c 24             	mov    %edi,(%esp)
80100339:	e8 4f 12 00 00       	call   8010158d <ilock>
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
8010035a:	e8 bc 22 00 00       	call   8010261b <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 8d 67 10 80       	push   $0x8010678d
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 db 70 10 80 	movl   $0x801070db,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 93 39 00 00       	call   80103d27 <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 a1 67 10 80       	push   $0x801067a1
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
8010049e:	68 a5 67 10 80       	push   $0x801067a5
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 b0 3a 00 00       	call   80103f6f <memmove>
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
801004d9:	e8 16 3a 00 00       	call   80103ef4 <memset>
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
80100506:	e8 23 4e 00 00       	call   8010532e <uartputc>
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
8010051f:	e8 0a 4e 00 00       	call   8010532e <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 fe 4d 00 00       	call   8010532e <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 f2 4d 00 00       	call   8010532e <uartputc>
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
80100576:	0f b6 92 d0 67 10 80 	movzbl -0x7fef9830(%edx),%edx
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
801005be:	e8 8c 10 00 00       	call   8010164f <iunlock>
  acquire(&cons.lock);
801005c3:	c7 04 24 20 a5 10 80 	movl   $0x8010a520,(%esp)
801005ca:	e8 79 38 00 00       	call   80103e48 <acquire>
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
801005f1:	e8 b7 38 00 00       	call   80103ead <release>
  ilock(ip);
801005f6:	83 c4 04             	add    $0x4,%esp
801005f9:	ff 75 08             	pushl  0x8(%ebp)
801005fc:	e8 8c 0f 00 00       	call   8010158d <ilock>

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
80100638:	e8 0b 38 00 00       	call   80103e48 <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 bf 67 10 80       	push   $0x801067bf
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
801006ee:	be b8 67 10 80       	mov    $0x801067b8,%esi
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
80100734:	e8 74 37 00 00       	call   80103ead <release>
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
8010074f:	e8 f4 36 00 00       	call   80103e48 <acquire>
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
80100772:	a1 a8 ff 10 80       	mov    0x8010ffa8,%eax
80100777:	89 c2                	mov    %eax,%edx
80100779:	2b 15 a0 ff 10 80    	sub    0x8010ffa0,%edx
8010077f:	83 fa 7f             	cmp    $0x7f,%edx
80100782:	0f 87 9e 00 00 00    	ja     80100826 <consoleintr+0xe8>
        c = (c == '\r') ? '\n' : c;
80100788:	83 ff 0d             	cmp    $0xd,%edi
8010078b:	0f 84 86 00 00 00    	je     80100817 <consoleintr+0xd9>
        input.buf[input.e++ % INPUT_BUF] = c;
80100791:	8d 50 01             	lea    0x1(%eax),%edx
80100794:	89 15 a8 ff 10 80    	mov    %edx,0x8010ffa8
8010079a:	83 e0 7f             	and    $0x7f,%eax
8010079d:	89 f9                	mov    %edi,%ecx
8010079f:	88 88 20 ff 10 80    	mov    %cl,-0x7fef00e0(%eax)
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
801007bc:	a1 a0 ff 10 80       	mov    0x8010ffa0,%eax
801007c1:	83 e8 80             	sub    $0xffffff80,%eax
801007c4:	39 05 a8 ff 10 80    	cmp    %eax,0x8010ffa8
801007ca:	75 5a                	jne    80100826 <consoleintr+0xe8>
          input.w = input.e;
801007cc:	a1 a8 ff 10 80       	mov    0x8010ffa8,%eax
801007d1:	a3 a4 ff 10 80       	mov    %eax,0x8010ffa4
          wakeup(&input.r);
801007d6:	83 ec 0c             	sub    $0xc,%esp
801007d9:	68 a0 ff 10 80       	push   $0x8010ffa0
801007de:	e8 cf 32 00 00       	call   80103ab2 <wakeup>
801007e3:	83 c4 10             	add    $0x10,%esp
801007e6:	eb 3e                	jmp    80100826 <consoleintr+0xe8>
        input.e--;
801007e8:	a3 a8 ff 10 80       	mov    %eax,0x8010ffa8
        consputc(BACKSPACE);
801007ed:	b8 00 01 00 00       	mov    $0x100,%eax
801007f2:	e8 ef fc ff ff       	call   801004e6 <consputc>
      while(input.e != input.w &&
801007f7:	a1 a8 ff 10 80       	mov    0x8010ffa8,%eax
801007fc:	3b 05 a4 ff 10 80    	cmp    0x8010ffa4,%eax
80100802:	74 22                	je     80100826 <consoleintr+0xe8>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100804:	83 e8 01             	sub    $0x1,%eax
80100807:	89 c2                	mov    %eax,%edx
80100809:	83 e2 7f             	and    $0x7f,%edx
      while(input.e != input.w &&
8010080c:	80 ba 20 ff 10 80 0a 	cmpb   $0xa,-0x7fef00e0(%edx)
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
8010084a:	a1 a8 ff 10 80       	mov    0x8010ffa8,%eax
8010084f:	3b 05 a4 ff 10 80    	cmp    0x8010ffa4,%eax
80100855:	74 cf                	je     80100826 <consoleintr+0xe8>
        input.e--;
80100857:	83 e8 01             	sub    $0x1,%eax
8010085a:	a3 a8 ff 10 80       	mov    %eax,0x8010ffa8
        consputc(BACKSPACE);
8010085f:	b8 00 01 00 00       	mov    $0x100,%eax
80100864:	e8 7d fc ff ff       	call   801004e6 <consputc>
80100869:	eb bb                	jmp    80100826 <consoleintr+0xe8>
  release(&cons.lock);
8010086b:	83 ec 0c             	sub    $0xc,%esp
8010086e:	68 20 a5 10 80       	push   $0x8010a520
80100873:	e8 35 36 00 00       	call   80103ead <release>
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
80100887:	e8 c3 32 00 00       	call   80103b4f <procdump>
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
80100894:	68 c8 67 10 80       	push   $0x801067c8
80100899:	68 20 a5 10 80       	push   $0x8010a520
8010089e:	e8 69 34 00 00       	call   80103d0c <initlock>

  devsw[CONSOLE].write = consolewrite;
801008a3:	c7 05 6c 09 11 80 ac 	movl   $0x801005ac,0x8011096c
801008aa:	05 10 80 
  devsw[CONSOLE].read = consoleread;
801008ad:	c7 05 68 09 11 80 68 	movl   $0x80100268,0x80110968
801008b4:	02 10 80 
  cons.locking = 1;
801008b7:	c7 05 54 a5 10 80 01 	movl   $0x1,0x8010a554
801008be:	00 00 00 

  ioapicenable(IRQ_KBD, 0);
801008c1:	83 c4 08             	add    $0x8,%esp
801008c4:	6a 00                	push   $0x0
801008c6:	6a 01                	push   $0x1
801008c8:	e8 bd 16 00 00       	call   80101f8a <ioapicenable>
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
801008de:	e8 c3 2b 00 00       	call   801034a6 <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 5d 21 00 00       	call   80102a4b <begin_op>

  if((ip = namei(path)) == 0){
801008ee:	83 ec 0c             	sub    $0xc,%esp
801008f1:	ff 75 08             	pushl  0x8(%ebp)
801008f4:	e8 f4 12 00 00       	call   80101bed <namei>
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
80100906:	e8 82 0c 00 00       	call   8010158d <ilock>
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
8010090b:	6a 34                	push   $0x34
8010090d:	6a 00                	push   $0x0
8010090f:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
80100915:	50                   	push   %eax
80100916:	53                   	push   %ebx
80100917:	e8 63 0e 00 00       	call   8010177f <readi>
8010091c:	83 c4 20             	add    $0x20,%esp
8010091f:	83 f8 34             	cmp    $0x34,%eax
80100922:	74 42                	je     80100966 <exec+0x94>
  return 0;

 bad:
  if(pgdir)
    freevm(pgdir);
  if(ip){
80100924:	85 db                	test   %ebx,%ebx
80100926:	0f 84 e9 02 00 00    	je     80100c15 <exec+0x343>
    iunlockput(ip);
8010092c:	83 ec 0c             	sub    $0xc,%esp
8010092f:	53                   	push   %ebx
80100930:	e8 ff 0d 00 00       	call   80101734 <iunlockput>
    end_op();
80100935:	e8 8b 21 00 00       	call   80102ac5 <end_op>
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
8010094a:	e8 76 21 00 00       	call   80102ac5 <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 e1 67 10 80       	push   $0x801067e1
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
80100972:	e8 80 5b 00 00       	call   801064f7 <setupkvm>
80100977:	89 85 ec fe ff ff    	mov    %eax,-0x114(%ebp)
8010097d:	85 c0                	test   %eax,%eax
8010097f:	0f 84 12 01 00 00    	je     80100a97 <exec+0x1c5>
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
801009ac:	0f 8e 9e 00 00 00    	jle    80100a50 <exec+0x17e>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
801009b2:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
801009b8:	6a 20                	push   $0x20
801009ba:	50                   	push   %eax
801009bb:	8d 85 04 ff ff ff    	lea    -0xfc(%ebp),%eax
801009c1:	50                   	push   %eax
801009c2:	53                   	push   %ebx
801009c3:	e8 b7 0d 00 00       	call   8010177f <readi>
801009c8:	83 c4 10             	add    $0x10,%esp
801009cb:	83 f8 20             	cmp    $0x20,%eax
801009ce:	0f 85 c3 00 00 00    	jne    80100a97 <exec+0x1c5>
    if(ph.type != ELF_PROG_LOAD)
801009d4:	83 bd 04 ff ff ff 01 	cmpl   $0x1,-0xfc(%ebp)
801009db:	75 ba                	jne    80100997 <exec+0xc5>
    if(ph.memsz < ph.filesz)
801009dd:	8b 85 18 ff ff ff    	mov    -0xe8(%ebp),%eax
801009e3:	3b 85 14 ff ff ff    	cmp    -0xec(%ebp),%eax
801009e9:	0f 82 a8 00 00 00    	jb     80100a97 <exec+0x1c5>
    if(ph.vaddr + ph.memsz < ph.vaddr)
801009ef:	03 85 0c ff ff ff    	add    -0xf4(%ebp),%eax
801009f5:	0f 82 9c 00 00 00    	jb     80100a97 <exec+0x1c5>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz, curproc->pid)) == 0)
801009fb:	8b 8d f4 fe ff ff    	mov    -0x10c(%ebp),%ecx
80100a01:	ff 71 10             	pushl  0x10(%ecx)
80100a04:	50                   	push   %eax
80100a05:	57                   	push   %edi
80100a06:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a0c:	e8 83 59 00 00       	call   80106394 <allocuvm>
80100a11:	89 c7                	mov    %eax,%edi
80100a13:	83 c4 10             	add    $0x10,%esp
80100a16:	85 c0                	test   %eax,%eax
80100a18:	74 7d                	je     80100a97 <exec+0x1c5>
    if(ph.vaddr % PGSIZE != 0)
80100a1a:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100a20:	a9 ff 0f 00 00       	test   $0xfff,%eax
80100a25:	75 70                	jne    80100a97 <exec+0x1c5>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100a27:	83 ec 0c             	sub    $0xc,%esp
80100a2a:	ff b5 14 ff ff ff    	pushl  -0xec(%ebp)
80100a30:	ff b5 08 ff ff ff    	pushl  -0xf8(%ebp)
80100a36:	53                   	push   %ebx
80100a37:	50                   	push   %eax
80100a38:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a3e:	e8 1f 58 00 00       	call   80106262 <loaduvm>
80100a43:	83 c4 20             	add    $0x20,%esp
80100a46:	85 c0                	test   %eax,%eax
80100a48:	0f 89 49 ff ff ff    	jns    80100997 <exec+0xc5>
 bad:
80100a4e:	eb 47                	jmp    80100a97 <exec+0x1c5>
  iunlockput(ip);
80100a50:	83 ec 0c             	sub    $0xc,%esp
80100a53:	53                   	push   %ebx
80100a54:	e8 db 0c 00 00       	call   80101734 <iunlockput>
  end_op();
80100a59:	e8 67 20 00 00       	call   80102ac5 <end_op>
  sz = PGROUNDUP(sz);
80100a5e:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a64:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE, curproc->pid)) == 0)
80100a69:	8b 8d f4 fe ff ff    	mov    -0x10c(%ebp),%ecx
80100a6f:	ff 71 10             	pushl  0x10(%ecx)
80100a72:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a78:	52                   	push   %edx
80100a79:	50                   	push   %eax
80100a7a:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a80:	e8 0f 59 00 00       	call   80106394 <allocuvm>
80100a85:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
80100a8b:	83 c4 20             	add    $0x20,%esp
80100a8e:	85 c0                	test   %eax,%eax
80100a90:	75 24                	jne    80100ab6 <exec+0x1e4>
  ip = 0;
80100a92:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(pgdir)
80100a97:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100a9d:	85 c0                	test   %eax,%eax
80100a9f:	0f 84 7f fe ff ff    	je     80100924 <exec+0x52>
    freevm(pgdir);
80100aa5:	83 ec 0c             	sub    $0xc,%esp
80100aa8:	50                   	push   %eax
80100aa9:	e8 d9 59 00 00       	call   80106487 <freevm>
80100aae:	83 c4 10             	add    $0x10,%esp
80100ab1:	e9 6e fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100ab6:	89 c7                	mov    %eax,%edi
80100ab8:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100abe:	83 ec 08             	sub    $0x8,%esp
80100ac1:	50                   	push   %eax
80100ac2:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100ac8:	e8 af 5a 00 00       	call   8010657c <clearpteu>
  for(argc = 0; argv[argc]; argc++) {
80100acd:	83 c4 10             	add    $0x10,%esp
80100ad0:	be 00 00 00 00       	mov    $0x0,%esi
80100ad5:	8b 45 0c             	mov    0xc(%ebp),%eax
80100ad8:	8d 1c b0             	lea    (%eax,%esi,4),%ebx
80100adb:	8b 03                	mov    (%ebx),%eax
80100add:	85 c0                	test   %eax,%eax
80100adf:	74 4d                	je     80100b2e <exec+0x25c>
    if(argc >= MAXARG)
80100ae1:	83 fe 1f             	cmp    $0x1f,%esi
80100ae4:	0f 87 0d 01 00 00    	ja     80100bf7 <exec+0x325>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100aea:	83 ec 0c             	sub    $0xc,%esp
80100aed:	50                   	push   %eax
80100aee:	e8 a3 35 00 00       	call   80104096 <strlen>
80100af3:	29 c7                	sub    %eax,%edi
80100af5:	83 ef 01             	sub    $0x1,%edi
80100af8:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100afb:	83 c4 04             	add    $0x4,%esp
80100afe:	ff 33                	pushl  (%ebx)
80100b00:	e8 91 35 00 00       	call   80104096 <strlen>
80100b05:	83 c0 01             	add    $0x1,%eax
80100b08:	50                   	push   %eax
80100b09:	ff 33                	pushl  (%ebx)
80100b0b:	57                   	push   %edi
80100b0c:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b12:	e8 c0 5b 00 00       	call   801066d7 <copyout>
80100b17:	83 c4 20             	add    $0x20,%esp
80100b1a:	85 c0                	test   %eax,%eax
80100b1c:	0f 88 df 00 00 00    	js     80100c01 <exec+0x32f>
    ustack[3+argc] = sp;
80100b22:	89 bc b5 64 ff ff ff 	mov    %edi,-0x9c(%ebp,%esi,4)
  for(argc = 0; argv[argc]; argc++) {
80100b29:	83 c6 01             	add    $0x1,%esi
80100b2c:	eb a7                	jmp    80100ad5 <exec+0x203>
  ustack[3+argc] = 0;
80100b2e:	c7 84 b5 64 ff ff ff 	movl   $0x0,-0x9c(%ebp,%esi,4)
80100b35:	00 00 00 00 
  ustack[0] = 0xffffffff;  // fake return PC
80100b39:	c7 85 58 ff ff ff ff 	movl   $0xffffffff,-0xa8(%ebp)
80100b40:	ff ff ff 
  ustack[1] = argc;
80100b43:	89 b5 5c ff ff ff    	mov    %esi,-0xa4(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100b49:	8d 04 b5 04 00 00 00 	lea    0x4(,%esi,4),%eax
80100b50:	89 f9                	mov    %edi,%ecx
80100b52:	29 c1                	sub    %eax,%ecx
80100b54:	89 8d 60 ff ff ff    	mov    %ecx,-0xa0(%ebp)
  sp -= (3+argc+1) * 4;
80100b5a:	8d 04 b5 10 00 00 00 	lea    0x10(,%esi,4),%eax
80100b61:	29 c7                	sub    %eax,%edi
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100b63:	50                   	push   %eax
80100b64:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
80100b6a:	50                   	push   %eax
80100b6b:	57                   	push   %edi
80100b6c:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b72:	e8 60 5b 00 00       	call   801066d7 <copyout>
80100b77:	83 c4 10             	add    $0x10,%esp
80100b7a:	85 c0                	test   %eax,%eax
80100b7c:	0f 88 89 00 00 00    	js     80100c0b <exec+0x339>
  for(last=s=path; *s; s++)
80100b82:	8b 55 08             	mov    0x8(%ebp),%edx
80100b85:	89 d0                	mov    %edx,%eax
80100b87:	eb 03                	jmp    80100b8c <exec+0x2ba>
80100b89:	83 c0 01             	add    $0x1,%eax
80100b8c:	0f b6 08             	movzbl (%eax),%ecx
80100b8f:	84 c9                	test   %cl,%cl
80100b91:	74 0a                	je     80100b9d <exec+0x2cb>
    if(*s == '/')
80100b93:	80 f9 2f             	cmp    $0x2f,%cl
80100b96:	75 f1                	jne    80100b89 <exec+0x2b7>
      last = s+1;
80100b98:	8d 50 01             	lea    0x1(%eax),%edx
80100b9b:	eb ec                	jmp    80100b89 <exec+0x2b7>
  safestrcpy(curproc->name, last, sizeof(curproc->name));
80100b9d:	8b b5 f4 fe ff ff    	mov    -0x10c(%ebp),%esi
80100ba3:	89 f0                	mov    %esi,%eax
80100ba5:	83 c0 6c             	add    $0x6c,%eax
80100ba8:	83 ec 04             	sub    $0x4,%esp
80100bab:	6a 10                	push   $0x10
80100bad:	52                   	push   %edx
80100bae:	50                   	push   %eax
80100baf:	e8 a7 34 00 00       	call   8010405b <safestrcpy>
  oldpgdir = curproc->pgdir;
80100bb4:	8b 5e 04             	mov    0x4(%esi),%ebx
  curproc->pgdir = pgdir;
80100bb7:	8b 8d ec fe ff ff    	mov    -0x114(%ebp),%ecx
80100bbd:	89 4e 04             	mov    %ecx,0x4(%esi)
  curproc->sz = sz;
80100bc0:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100bc6:	89 0e                	mov    %ecx,(%esi)
  curproc->tf->eip = elf.entry;  // main
80100bc8:	8b 46 18             	mov    0x18(%esi),%eax
80100bcb:	8b 95 3c ff ff ff    	mov    -0xc4(%ebp),%edx
80100bd1:	89 50 38             	mov    %edx,0x38(%eax)
  curproc->tf->esp = sp;
80100bd4:	8b 46 18             	mov    0x18(%esi),%eax
80100bd7:	89 78 44             	mov    %edi,0x44(%eax)
  switchuvm(curproc);
80100bda:	89 34 24             	mov    %esi,(%esp)
80100bdd:	e8 ff 54 00 00       	call   801060e1 <switchuvm>
  freevm(oldpgdir);
80100be2:	89 1c 24             	mov    %ebx,(%esp)
80100be5:	e8 9d 58 00 00       	call   80106487 <freevm>
  return 0;
80100bea:	83 c4 10             	add    $0x10,%esp
80100bed:	b8 00 00 00 00       	mov    $0x0,%eax
80100bf2:	e9 4b fd ff ff       	jmp    80100942 <exec+0x70>
  ip = 0;
80100bf7:	bb 00 00 00 00       	mov    $0x0,%ebx
80100bfc:	e9 96 fe ff ff       	jmp    80100a97 <exec+0x1c5>
80100c01:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c06:	e9 8c fe ff ff       	jmp    80100a97 <exec+0x1c5>
80100c0b:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c10:	e9 82 fe ff ff       	jmp    80100a97 <exec+0x1c5>
  return -1;
80100c15:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100c1a:	e9 23 fd ff ff       	jmp    80100942 <exec+0x70>

80100c1f <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100c1f:	55                   	push   %ebp
80100c20:	89 e5                	mov    %esp,%ebp
80100c22:	83 ec 10             	sub    $0x10,%esp
  initlock(&ftable.lock, "ftable");
80100c25:	68 ed 67 10 80       	push   $0x801067ed
80100c2a:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c2f:	e8 d8 30 00 00       	call   80103d0c <initlock>
}
80100c34:	83 c4 10             	add    $0x10,%esp
80100c37:	c9                   	leave  
80100c38:	c3                   	ret    

80100c39 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100c39:	55                   	push   %ebp
80100c3a:	89 e5                	mov    %esp,%ebp
80100c3c:	53                   	push   %ebx
80100c3d:	83 ec 10             	sub    $0x10,%esp
  struct file *f;

  acquire(&ftable.lock);
80100c40:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c45:	e8 fe 31 00 00       	call   80103e48 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c4a:	83 c4 10             	add    $0x10,%esp
80100c4d:	bb f4 ff 10 80       	mov    $0x8010fff4,%ebx
80100c52:	81 fb 54 09 11 80    	cmp    $0x80110954,%ebx
80100c58:	73 29                	jae    80100c83 <filealloc+0x4a>
    if(f->ref == 0){
80100c5a:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80100c5e:	74 05                	je     80100c65 <filealloc+0x2c>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c60:	83 c3 18             	add    $0x18,%ebx
80100c63:	eb ed                	jmp    80100c52 <filealloc+0x19>
      f->ref = 1;
80100c65:	c7 43 04 01 00 00 00 	movl   $0x1,0x4(%ebx)
      release(&ftable.lock);
80100c6c:	83 ec 0c             	sub    $0xc,%esp
80100c6f:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c74:	e8 34 32 00 00       	call   80103ead <release>
      return f;
80100c79:	83 c4 10             	add    $0x10,%esp
    }
  }
  release(&ftable.lock);
  return 0;
}
80100c7c:	89 d8                	mov    %ebx,%eax
80100c7e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100c81:	c9                   	leave  
80100c82:	c3                   	ret    
  release(&ftable.lock);
80100c83:	83 ec 0c             	sub    $0xc,%esp
80100c86:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c8b:	e8 1d 32 00 00       	call   80103ead <release>
  return 0;
80100c90:	83 c4 10             	add    $0x10,%esp
80100c93:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c98:	eb e2                	jmp    80100c7c <filealloc+0x43>

80100c9a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100c9a:	55                   	push   %ebp
80100c9b:	89 e5                	mov    %esp,%ebp
80100c9d:	53                   	push   %ebx
80100c9e:	83 ec 10             	sub    $0x10,%esp
80100ca1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&ftable.lock);
80100ca4:	68 c0 ff 10 80       	push   $0x8010ffc0
80100ca9:	e8 9a 31 00 00       	call   80103e48 <acquire>
  if(f->ref < 1)
80100cae:	8b 43 04             	mov    0x4(%ebx),%eax
80100cb1:	83 c4 10             	add    $0x10,%esp
80100cb4:	85 c0                	test   %eax,%eax
80100cb6:	7e 1a                	jle    80100cd2 <filedup+0x38>
    panic("filedup");
  f->ref++;
80100cb8:	83 c0 01             	add    $0x1,%eax
80100cbb:	89 43 04             	mov    %eax,0x4(%ebx)
  release(&ftable.lock);
80100cbe:	83 ec 0c             	sub    $0xc,%esp
80100cc1:	68 c0 ff 10 80       	push   $0x8010ffc0
80100cc6:	e8 e2 31 00 00       	call   80103ead <release>
  return f;
}
80100ccb:	89 d8                	mov    %ebx,%eax
80100ccd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cd0:	c9                   	leave  
80100cd1:	c3                   	ret    
    panic("filedup");
80100cd2:	83 ec 0c             	sub    $0xc,%esp
80100cd5:	68 f4 67 10 80       	push   $0x801067f4
80100cda:	e8 69 f6 ff ff       	call   80100348 <panic>

80100cdf <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100cdf:	55                   	push   %ebp
80100ce0:	89 e5                	mov    %esp,%ebp
80100ce2:	53                   	push   %ebx
80100ce3:	83 ec 30             	sub    $0x30,%esp
80100ce6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct file ff;

  acquire(&ftable.lock);
80100ce9:	68 c0 ff 10 80       	push   $0x8010ffc0
80100cee:	e8 55 31 00 00       	call   80103e48 <acquire>
  if(f->ref < 1)
80100cf3:	8b 43 04             	mov    0x4(%ebx),%eax
80100cf6:	83 c4 10             	add    $0x10,%esp
80100cf9:	85 c0                	test   %eax,%eax
80100cfb:	7e 1f                	jle    80100d1c <fileclose+0x3d>
    panic("fileclose");
  if(--f->ref > 0){
80100cfd:	83 e8 01             	sub    $0x1,%eax
80100d00:	89 43 04             	mov    %eax,0x4(%ebx)
80100d03:	85 c0                	test   %eax,%eax
80100d05:	7e 22                	jle    80100d29 <fileclose+0x4a>
    release(&ftable.lock);
80100d07:	83 ec 0c             	sub    $0xc,%esp
80100d0a:	68 c0 ff 10 80       	push   $0x8010ffc0
80100d0f:	e8 99 31 00 00       	call   80103ead <release>
    return;
80100d14:	83 c4 10             	add    $0x10,%esp
  else if(ff.type == FD_INODE){
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
80100d17:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100d1a:	c9                   	leave  
80100d1b:	c3                   	ret    
    panic("fileclose");
80100d1c:	83 ec 0c             	sub    $0xc,%esp
80100d1f:	68 fc 67 10 80       	push   $0x801067fc
80100d24:	e8 1f f6 ff ff       	call   80100348 <panic>
  ff = *f;
80100d29:	8b 03                	mov    (%ebx),%eax
80100d2b:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d2e:	8b 43 08             	mov    0x8(%ebx),%eax
80100d31:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d34:	8b 43 0c             	mov    0xc(%ebx),%eax
80100d37:	89 45 ec             	mov    %eax,-0x14(%ebp)
80100d3a:	8b 43 10             	mov    0x10(%ebx),%eax
80100d3d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  f->ref = 0;
80100d40:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
  f->type = FD_NONE;
80100d47:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  release(&ftable.lock);
80100d4d:	83 ec 0c             	sub    $0xc,%esp
80100d50:	68 c0 ff 10 80       	push   $0x8010ffc0
80100d55:	e8 53 31 00 00       	call   80103ead <release>
  if(ff.type == FD_PIPE)
80100d5a:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d5d:	83 c4 10             	add    $0x10,%esp
80100d60:	83 f8 01             	cmp    $0x1,%eax
80100d63:	74 1f                	je     80100d84 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d65:	83 f8 02             	cmp    $0x2,%eax
80100d68:	75 ad                	jne    80100d17 <fileclose+0x38>
    begin_op();
80100d6a:	e8 dc 1c 00 00       	call   80102a4b <begin_op>
    iput(ff.ip);
80100d6f:	83 ec 0c             	sub    $0xc,%esp
80100d72:	ff 75 f0             	pushl  -0x10(%ebp)
80100d75:	e8 1a 09 00 00       	call   80101694 <iput>
    end_op();
80100d7a:	e8 46 1d 00 00       	call   80102ac5 <end_op>
80100d7f:	83 c4 10             	add    $0x10,%esp
80100d82:	eb 93                	jmp    80100d17 <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d84:	83 ec 08             	sub    $0x8,%esp
80100d87:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d8b:	50                   	push   %eax
80100d8c:	ff 75 ec             	pushl  -0x14(%ebp)
80100d8f:	e8 38 23 00 00       	call   801030cc <pipeclose>
80100d94:	83 c4 10             	add    $0x10,%esp
80100d97:	e9 7b ff ff ff       	jmp    80100d17 <fileclose+0x38>

80100d9c <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80100d9c:	55                   	push   %ebp
80100d9d:	89 e5                	mov    %esp,%ebp
80100d9f:	53                   	push   %ebx
80100da0:	83 ec 04             	sub    $0x4,%esp
80100da3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(f->type == FD_INODE){
80100da6:	83 3b 02             	cmpl   $0x2,(%ebx)
80100da9:	75 31                	jne    80100ddc <filestat+0x40>
    ilock(f->ip);
80100dab:	83 ec 0c             	sub    $0xc,%esp
80100dae:	ff 73 10             	pushl  0x10(%ebx)
80100db1:	e8 d7 07 00 00       	call   8010158d <ilock>
    stati(f->ip, st);
80100db6:	83 c4 08             	add    $0x8,%esp
80100db9:	ff 75 0c             	pushl  0xc(%ebp)
80100dbc:	ff 73 10             	pushl  0x10(%ebx)
80100dbf:	e8 90 09 00 00       	call   80101754 <stati>
    iunlock(f->ip);
80100dc4:	83 c4 04             	add    $0x4,%esp
80100dc7:	ff 73 10             	pushl  0x10(%ebx)
80100dca:	e8 80 08 00 00       	call   8010164f <iunlock>
    return 0;
80100dcf:	83 c4 10             	add    $0x10,%esp
80100dd2:	b8 00 00 00 00       	mov    $0x0,%eax
  }
  return -1;
}
80100dd7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100dda:	c9                   	leave  
80100ddb:	c3                   	ret    
  return -1;
80100ddc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100de1:	eb f4                	jmp    80100dd7 <filestat+0x3b>

80100de3 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80100de3:	55                   	push   %ebp
80100de4:	89 e5                	mov    %esp,%ebp
80100de6:	56                   	push   %esi
80100de7:	53                   	push   %ebx
80100de8:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->readable == 0)
80100deb:	80 7b 08 00          	cmpb   $0x0,0x8(%ebx)
80100def:	74 70                	je     80100e61 <fileread+0x7e>
    return -1;
  if(f->type == FD_PIPE)
80100df1:	8b 03                	mov    (%ebx),%eax
80100df3:	83 f8 01             	cmp    $0x1,%eax
80100df6:	74 44                	je     80100e3c <fileread+0x59>
    return piperead(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100df8:	83 f8 02             	cmp    $0x2,%eax
80100dfb:	75 57                	jne    80100e54 <fileread+0x71>
    ilock(f->ip);
80100dfd:	83 ec 0c             	sub    $0xc,%esp
80100e00:	ff 73 10             	pushl  0x10(%ebx)
80100e03:	e8 85 07 00 00       	call   8010158d <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80100e08:	ff 75 10             	pushl  0x10(%ebp)
80100e0b:	ff 73 14             	pushl  0x14(%ebx)
80100e0e:	ff 75 0c             	pushl  0xc(%ebp)
80100e11:	ff 73 10             	pushl  0x10(%ebx)
80100e14:	e8 66 09 00 00       	call   8010177f <readi>
80100e19:	89 c6                	mov    %eax,%esi
80100e1b:	83 c4 20             	add    $0x20,%esp
80100e1e:	85 c0                	test   %eax,%eax
80100e20:	7e 03                	jle    80100e25 <fileread+0x42>
      f->off += r;
80100e22:	01 43 14             	add    %eax,0x14(%ebx)
    iunlock(f->ip);
80100e25:	83 ec 0c             	sub    $0xc,%esp
80100e28:	ff 73 10             	pushl  0x10(%ebx)
80100e2b:	e8 1f 08 00 00       	call   8010164f <iunlock>
    return r;
80100e30:	83 c4 10             	add    $0x10,%esp
  }
  panic("fileread");
}
80100e33:	89 f0                	mov    %esi,%eax
80100e35:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100e38:	5b                   	pop    %ebx
80100e39:	5e                   	pop    %esi
80100e3a:	5d                   	pop    %ebp
80100e3b:	c3                   	ret    
    return piperead(f->pipe, addr, n);
80100e3c:	83 ec 04             	sub    $0x4,%esp
80100e3f:	ff 75 10             	pushl  0x10(%ebp)
80100e42:	ff 75 0c             	pushl  0xc(%ebp)
80100e45:	ff 73 0c             	pushl  0xc(%ebx)
80100e48:	e8 d7 23 00 00       	call   80103224 <piperead>
80100e4d:	89 c6                	mov    %eax,%esi
80100e4f:	83 c4 10             	add    $0x10,%esp
80100e52:	eb df                	jmp    80100e33 <fileread+0x50>
  panic("fileread");
80100e54:	83 ec 0c             	sub    $0xc,%esp
80100e57:	68 06 68 10 80       	push   $0x80106806
80100e5c:	e8 e7 f4 ff ff       	call   80100348 <panic>
    return -1;
80100e61:	be ff ff ff ff       	mov    $0xffffffff,%esi
80100e66:	eb cb                	jmp    80100e33 <fileread+0x50>

80100e68 <filewrite>:

// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
80100e68:	55                   	push   %ebp
80100e69:	89 e5                	mov    %esp,%ebp
80100e6b:	57                   	push   %edi
80100e6c:	56                   	push   %esi
80100e6d:	53                   	push   %ebx
80100e6e:	83 ec 1c             	sub    $0x1c,%esp
80100e71:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->writable == 0)
80100e74:	80 7b 09 00          	cmpb   $0x0,0x9(%ebx)
80100e78:	0f 84 c5 00 00 00    	je     80100f43 <filewrite+0xdb>
    return -1;
  if(f->type == FD_PIPE)
80100e7e:	8b 03                	mov    (%ebx),%eax
80100e80:	83 f8 01             	cmp    $0x1,%eax
80100e83:	74 10                	je     80100e95 <filewrite+0x2d>
    return pipewrite(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100e85:	83 f8 02             	cmp    $0x2,%eax
80100e88:	0f 85 a8 00 00 00    	jne    80100f36 <filewrite+0xce>
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * 512;
    int i = 0;
80100e8e:	bf 00 00 00 00       	mov    $0x0,%edi
80100e93:	eb 67                	jmp    80100efc <filewrite+0x94>
    return pipewrite(f->pipe, addr, n);
80100e95:	83 ec 04             	sub    $0x4,%esp
80100e98:	ff 75 10             	pushl  0x10(%ebp)
80100e9b:	ff 75 0c             	pushl  0xc(%ebp)
80100e9e:	ff 73 0c             	pushl  0xc(%ebx)
80100ea1:	e8 b2 22 00 00       	call   80103158 <pipewrite>
80100ea6:	83 c4 10             	add    $0x10,%esp
80100ea9:	e9 80 00 00 00       	jmp    80100f2e <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100eae:	e8 98 1b 00 00       	call   80102a4b <begin_op>
      ilock(f->ip);
80100eb3:	83 ec 0c             	sub    $0xc,%esp
80100eb6:	ff 73 10             	pushl  0x10(%ebx)
80100eb9:	e8 cf 06 00 00       	call   8010158d <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80100ebe:	89 f8                	mov    %edi,%eax
80100ec0:	03 45 0c             	add    0xc(%ebp),%eax
80100ec3:	ff 75 e4             	pushl  -0x1c(%ebp)
80100ec6:	ff 73 14             	pushl  0x14(%ebx)
80100ec9:	50                   	push   %eax
80100eca:	ff 73 10             	pushl  0x10(%ebx)
80100ecd:	e8 aa 09 00 00       	call   8010187c <writei>
80100ed2:	89 c6                	mov    %eax,%esi
80100ed4:	83 c4 20             	add    $0x20,%esp
80100ed7:	85 c0                	test   %eax,%eax
80100ed9:	7e 03                	jle    80100ede <filewrite+0x76>
        f->off += r;
80100edb:	01 43 14             	add    %eax,0x14(%ebx)
      iunlock(f->ip);
80100ede:	83 ec 0c             	sub    $0xc,%esp
80100ee1:	ff 73 10             	pushl  0x10(%ebx)
80100ee4:	e8 66 07 00 00       	call   8010164f <iunlock>
      end_op();
80100ee9:	e8 d7 1b 00 00       	call   80102ac5 <end_op>

      if(r < 0)
80100eee:	83 c4 10             	add    $0x10,%esp
80100ef1:	85 f6                	test   %esi,%esi
80100ef3:	78 31                	js     80100f26 <filewrite+0xbe>
        break;
      if(r != n1)
80100ef5:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
80100ef8:	75 1f                	jne    80100f19 <filewrite+0xb1>
        panic("short filewrite");
      i += r;
80100efa:	01 f7                	add    %esi,%edi
    while(i < n){
80100efc:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100eff:	7d 25                	jge    80100f26 <filewrite+0xbe>
      int n1 = n - i;
80100f01:	8b 45 10             	mov    0x10(%ebp),%eax
80100f04:	29 f8                	sub    %edi,%eax
80100f06:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      if(n1 > max)
80100f09:	3d 00 06 00 00       	cmp    $0x600,%eax
80100f0e:	7e 9e                	jle    80100eae <filewrite+0x46>
        n1 = max;
80100f10:	c7 45 e4 00 06 00 00 	movl   $0x600,-0x1c(%ebp)
80100f17:	eb 95                	jmp    80100eae <filewrite+0x46>
        panic("short filewrite");
80100f19:	83 ec 0c             	sub    $0xc,%esp
80100f1c:	68 0f 68 10 80       	push   $0x8010680f
80100f21:	e8 22 f4 ff ff       	call   80100348 <panic>
    }
    return i == n ? n : -1;
80100f26:	3b 7d 10             	cmp    0x10(%ebp),%edi
80100f29:	75 1f                	jne    80100f4a <filewrite+0xe2>
80100f2b:	8b 45 10             	mov    0x10(%ebp),%eax
  }
  panic("filewrite");
}
80100f2e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100f31:	5b                   	pop    %ebx
80100f32:	5e                   	pop    %esi
80100f33:	5f                   	pop    %edi
80100f34:	5d                   	pop    %ebp
80100f35:	c3                   	ret    
  panic("filewrite");
80100f36:	83 ec 0c             	sub    $0xc,%esp
80100f39:	68 15 68 10 80       	push   $0x80106815
80100f3e:	e8 05 f4 ff ff       	call   80100348 <panic>
    return -1;
80100f43:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f48:	eb e4                	jmp    80100f2e <filewrite+0xc6>
    return i == n ? n : -1;
80100f4a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f4f:	eb dd                	jmp    80100f2e <filewrite+0xc6>

80100f51 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80100f51:	55                   	push   %ebp
80100f52:	89 e5                	mov    %esp,%ebp
80100f54:	57                   	push   %edi
80100f55:	56                   	push   %esi
80100f56:	53                   	push   %ebx
80100f57:	83 ec 0c             	sub    $0xc,%esp
80100f5a:	89 d7                	mov    %edx,%edi
  char *s;
  int len;

  while(*path == '/')
80100f5c:	eb 03                	jmp    80100f61 <skipelem+0x10>
    path++;
80100f5e:	83 c0 01             	add    $0x1,%eax
  while(*path == '/')
80100f61:	0f b6 10             	movzbl (%eax),%edx
80100f64:	80 fa 2f             	cmp    $0x2f,%dl
80100f67:	74 f5                	je     80100f5e <skipelem+0xd>
  if(*path == 0)
80100f69:	84 d2                	test   %dl,%dl
80100f6b:	74 59                	je     80100fc6 <skipelem+0x75>
80100f6d:	89 c3                	mov    %eax,%ebx
80100f6f:	eb 03                	jmp    80100f74 <skipelem+0x23>
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
    path++;
80100f71:	83 c3 01             	add    $0x1,%ebx
  while(*path != '/' && *path != 0)
80100f74:	0f b6 13             	movzbl (%ebx),%edx
80100f77:	80 fa 2f             	cmp    $0x2f,%dl
80100f7a:	0f 95 c1             	setne  %cl
80100f7d:	84 d2                	test   %dl,%dl
80100f7f:	0f 95 c2             	setne  %dl
80100f82:	84 d1                	test   %dl,%cl
80100f84:	75 eb                	jne    80100f71 <skipelem+0x20>
  len = path - s;
80100f86:	89 de                	mov    %ebx,%esi
80100f88:	29 c6                	sub    %eax,%esi
  if(len >= DIRSIZ)
80100f8a:	83 fe 0d             	cmp    $0xd,%esi
80100f8d:	7e 11                	jle    80100fa0 <skipelem+0x4f>
    memmove(name, s, DIRSIZ);
80100f8f:	83 ec 04             	sub    $0x4,%esp
80100f92:	6a 0e                	push   $0xe
80100f94:	50                   	push   %eax
80100f95:	57                   	push   %edi
80100f96:	e8 d4 2f 00 00       	call   80103f6f <memmove>
80100f9b:	83 c4 10             	add    $0x10,%esp
80100f9e:	eb 17                	jmp    80100fb7 <skipelem+0x66>
  else {
    memmove(name, s, len);
80100fa0:	83 ec 04             	sub    $0x4,%esp
80100fa3:	56                   	push   %esi
80100fa4:	50                   	push   %eax
80100fa5:	57                   	push   %edi
80100fa6:	e8 c4 2f 00 00       	call   80103f6f <memmove>
    name[len] = 0;
80100fab:	c6 04 37 00          	movb   $0x0,(%edi,%esi,1)
80100faf:	83 c4 10             	add    $0x10,%esp
80100fb2:	eb 03                	jmp    80100fb7 <skipelem+0x66>
  }
  while(*path == '/')
    path++;
80100fb4:	83 c3 01             	add    $0x1,%ebx
  while(*path == '/')
80100fb7:	80 3b 2f             	cmpb   $0x2f,(%ebx)
80100fba:	74 f8                	je     80100fb4 <skipelem+0x63>
  return path;
}
80100fbc:	89 d8                	mov    %ebx,%eax
80100fbe:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100fc1:	5b                   	pop    %ebx
80100fc2:	5e                   	pop    %esi
80100fc3:	5f                   	pop    %edi
80100fc4:	5d                   	pop    %ebp
80100fc5:	c3                   	ret    
    return 0;
80100fc6:	bb 00 00 00 00       	mov    $0x0,%ebx
80100fcb:	eb ef                	jmp    80100fbc <skipelem+0x6b>

80100fcd <bzero>:
{
80100fcd:	55                   	push   %ebp
80100fce:	89 e5                	mov    %esp,%ebp
80100fd0:	53                   	push   %ebx
80100fd1:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, bno);
80100fd4:	52                   	push   %edx
80100fd5:	50                   	push   %eax
80100fd6:	e8 91 f1 ff ff       	call   8010016c <bread>
80100fdb:	89 c3                	mov    %eax,%ebx
  memset(bp->data, 0, BSIZE);
80100fdd:	8d 40 5c             	lea    0x5c(%eax),%eax
80100fe0:	83 c4 0c             	add    $0xc,%esp
80100fe3:	68 00 02 00 00       	push   $0x200
80100fe8:	6a 00                	push   $0x0
80100fea:	50                   	push   %eax
80100feb:	e8 04 2f 00 00       	call   80103ef4 <memset>
  log_write(bp);
80100ff0:	89 1c 24             	mov    %ebx,(%esp)
80100ff3:	e8 7c 1b 00 00       	call   80102b74 <log_write>
  brelse(bp);
80100ff8:	89 1c 24             	mov    %ebx,(%esp)
80100ffb:	e8 d5 f1 ff ff       	call   801001d5 <brelse>
}
80101000:	83 c4 10             	add    $0x10,%esp
80101003:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101006:	c9                   	leave  
80101007:	c3                   	ret    

80101008 <balloc>:
{
80101008:	55                   	push   %ebp
80101009:	89 e5                	mov    %esp,%ebp
8010100b:	57                   	push   %edi
8010100c:	56                   	push   %esi
8010100d:	53                   	push   %ebx
8010100e:	83 ec 1c             	sub    $0x1c,%esp
80101011:	89 45 d8             	mov    %eax,-0x28(%ebp)
  for(b = 0; b < sb.size; b += BPB){
80101014:	be 00 00 00 00       	mov    $0x0,%esi
80101019:	eb 14                	jmp    8010102f <balloc+0x27>
    brelse(bp);
8010101b:	83 ec 0c             	sub    $0xc,%esp
8010101e:	ff 75 e4             	pushl  -0x1c(%ebp)
80101021:	e8 af f1 ff ff       	call   801001d5 <brelse>
  for(b = 0; b < sb.size; b += BPB){
80101026:	81 c6 00 10 00 00    	add    $0x1000,%esi
8010102c:	83 c4 10             	add    $0x10,%esp
8010102f:	39 35 c0 09 11 80    	cmp    %esi,0x801109c0
80101035:	76 75                	jbe    801010ac <balloc+0xa4>
    bp = bread(dev, BBLOCK(b, sb));
80101037:	8d 86 ff 0f 00 00    	lea    0xfff(%esi),%eax
8010103d:	85 f6                	test   %esi,%esi
8010103f:	0f 49 c6             	cmovns %esi,%eax
80101042:	c1 f8 0c             	sar    $0xc,%eax
80101045:	03 05 d8 09 11 80    	add    0x801109d8,%eax
8010104b:	83 ec 08             	sub    $0x8,%esp
8010104e:	50                   	push   %eax
8010104f:	ff 75 d8             	pushl  -0x28(%ebp)
80101052:	e8 15 f1 ff ff       	call   8010016c <bread>
80101057:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010105a:	83 c4 10             	add    $0x10,%esp
8010105d:	b8 00 00 00 00       	mov    $0x0,%eax
80101062:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80101067:	7f b2                	jg     8010101b <balloc+0x13>
80101069:	8d 1c 06             	lea    (%esi,%eax,1),%ebx
8010106c:	89 5d e0             	mov    %ebx,-0x20(%ebp)
8010106f:	3b 1d c0 09 11 80    	cmp    0x801109c0,%ebx
80101075:	73 a4                	jae    8010101b <balloc+0x13>
      m = 1 << (bi % 8);
80101077:	99                   	cltd   
80101078:	c1 ea 1d             	shr    $0x1d,%edx
8010107b:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
8010107e:	83 e1 07             	and    $0x7,%ecx
80101081:	29 d1                	sub    %edx,%ecx
80101083:	ba 01 00 00 00       	mov    $0x1,%edx
80101088:	d3 e2                	shl    %cl,%edx
      if((bp->data[bi/8] & m) == 0){  // Is block free?
8010108a:	8d 48 07             	lea    0x7(%eax),%ecx
8010108d:	85 c0                	test   %eax,%eax
8010108f:	0f 49 c8             	cmovns %eax,%ecx
80101092:	c1 f9 03             	sar    $0x3,%ecx
80101095:	89 4d dc             	mov    %ecx,-0x24(%ebp)
80101098:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010109b:	0f b6 4c 0f 5c       	movzbl 0x5c(%edi,%ecx,1),%ecx
801010a0:	0f b6 f9             	movzbl %cl,%edi
801010a3:	85 d7                	test   %edx,%edi
801010a5:	74 12                	je     801010b9 <balloc+0xb1>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801010a7:	83 c0 01             	add    $0x1,%eax
801010aa:	eb b6                	jmp    80101062 <balloc+0x5a>
  panic("balloc: out of blocks");
801010ac:	83 ec 0c             	sub    $0xc,%esp
801010af:	68 1f 68 10 80       	push   $0x8010681f
801010b4:	e8 8f f2 ff ff       	call   80100348 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
801010b9:	09 ca                	or     %ecx,%edx
801010bb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801010be:	8b 75 dc             	mov    -0x24(%ebp),%esi
801010c1:	88 54 30 5c          	mov    %dl,0x5c(%eax,%esi,1)
        log_write(bp);
801010c5:	83 ec 0c             	sub    $0xc,%esp
801010c8:	89 c6                	mov    %eax,%esi
801010ca:	50                   	push   %eax
801010cb:	e8 a4 1a 00 00       	call   80102b74 <log_write>
        brelse(bp);
801010d0:	89 34 24             	mov    %esi,(%esp)
801010d3:	e8 fd f0 ff ff       	call   801001d5 <brelse>
        bzero(dev, b + bi);
801010d8:	89 da                	mov    %ebx,%edx
801010da:	8b 45 d8             	mov    -0x28(%ebp),%eax
801010dd:	e8 eb fe ff ff       	call   80100fcd <bzero>
}
801010e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010e5:	8d 65 f4             	lea    -0xc(%ebp),%esp
801010e8:	5b                   	pop    %ebx
801010e9:	5e                   	pop    %esi
801010ea:	5f                   	pop    %edi
801010eb:	5d                   	pop    %ebp
801010ec:	c3                   	ret    

801010ed <bmap>:
{
801010ed:	55                   	push   %ebp
801010ee:	89 e5                	mov    %esp,%ebp
801010f0:	57                   	push   %edi
801010f1:	56                   	push   %esi
801010f2:	53                   	push   %ebx
801010f3:	83 ec 1c             	sub    $0x1c,%esp
801010f6:	89 c6                	mov    %eax,%esi
801010f8:	89 d7                	mov    %edx,%edi
  if(bn < NDIRECT){
801010fa:	83 fa 0b             	cmp    $0xb,%edx
801010fd:	77 17                	ja     80101116 <bmap+0x29>
    if((addr = ip->addrs[bn]) == 0)
801010ff:	8b 5c 90 5c          	mov    0x5c(%eax,%edx,4),%ebx
80101103:	85 db                	test   %ebx,%ebx
80101105:	75 4a                	jne    80101151 <bmap+0x64>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101107:	8b 00                	mov    (%eax),%eax
80101109:	e8 fa fe ff ff       	call   80101008 <balloc>
8010110e:	89 c3                	mov    %eax,%ebx
80101110:	89 44 be 5c          	mov    %eax,0x5c(%esi,%edi,4)
80101114:	eb 3b                	jmp    80101151 <bmap+0x64>
  bn -= NDIRECT;
80101116:	8d 5a f4             	lea    -0xc(%edx),%ebx
  if(bn < NINDIRECT){
80101119:	83 fb 7f             	cmp    $0x7f,%ebx
8010111c:	77 68                	ja     80101186 <bmap+0x99>
    if((addr = ip->addrs[NDIRECT]) == 0)
8010111e:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101124:	85 c0                	test   %eax,%eax
80101126:	74 33                	je     8010115b <bmap+0x6e>
    bp = bread(ip->dev, addr);
80101128:	83 ec 08             	sub    $0x8,%esp
8010112b:	50                   	push   %eax
8010112c:	ff 36                	pushl  (%esi)
8010112e:	e8 39 f0 ff ff       	call   8010016c <bread>
80101133:	89 c7                	mov    %eax,%edi
    if((addr = a[bn]) == 0){
80101135:	8d 44 98 5c          	lea    0x5c(%eax,%ebx,4),%eax
80101139:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010113c:	8b 18                	mov    (%eax),%ebx
8010113e:	83 c4 10             	add    $0x10,%esp
80101141:	85 db                	test   %ebx,%ebx
80101143:	74 25                	je     8010116a <bmap+0x7d>
    brelse(bp);
80101145:	83 ec 0c             	sub    $0xc,%esp
80101148:	57                   	push   %edi
80101149:	e8 87 f0 ff ff       	call   801001d5 <brelse>
    return addr;
8010114e:	83 c4 10             	add    $0x10,%esp
}
80101151:	89 d8                	mov    %ebx,%eax
80101153:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101156:	5b                   	pop    %ebx
80101157:	5e                   	pop    %esi
80101158:	5f                   	pop    %edi
80101159:	5d                   	pop    %ebp
8010115a:	c3                   	ret    
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
8010115b:	8b 06                	mov    (%esi),%eax
8010115d:	e8 a6 fe ff ff       	call   80101008 <balloc>
80101162:	89 86 8c 00 00 00    	mov    %eax,0x8c(%esi)
80101168:	eb be                	jmp    80101128 <bmap+0x3b>
      a[bn] = addr = balloc(ip->dev);
8010116a:	8b 06                	mov    (%esi),%eax
8010116c:	e8 97 fe ff ff       	call   80101008 <balloc>
80101171:	89 c3                	mov    %eax,%ebx
80101173:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101176:	89 18                	mov    %ebx,(%eax)
      log_write(bp);
80101178:	83 ec 0c             	sub    $0xc,%esp
8010117b:	57                   	push   %edi
8010117c:	e8 f3 19 00 00       	call   80102b74 <log_write>
80101181:	83 c4 10             	add    $0x10,%esp
80101184:	eb bf                	jmp    80101145 <bmap+0x58>
  panic("bmap: out of range");
80101186:	83 ec 0c             	sub    $0xc,%esp
80101189:	68 35 68 10 80       	push   $0x80106835
8010118e:	e8 b5 f1 ff ff       	call   80100348 <panic>

80101193 <iget>:
{
80101193:	55                   	push   %ebp
80101194:	89 e5                	mov    %esp,%ebp
80101196:	57                   	push   %edi
80101197:	56                   	push   %esi
80101198:	53                   	push   %ebx
80101199:	83 ec 28             	sub    $0x28,%esp
8010119c:	89 c7                	mov    %eax,%edi
8010119e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  acquire(&icache.lock);
801011a1:	68 e0 09 11 80       	push   $0x801109e0
801011a6:	e8 9d 2c 00 00       	call   80103e48 <acquire>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011ab:	83 c4 10             	add    $0x10,%esp
  empty = 0;
801011ae:	be 00 00 00 00       	mov    $0x0,%esi
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011b3:	bb 14 0a 11 80       	mov    $0x80110a14,%ebx
801011b8:	eb 0a                	jmp    801011c4 <iget+0x31>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ba:	85 f6                	test   %esi,%esi
801011bc:	74 3b                	je     801011f9 <iget+0x66>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011be:	81 c3 90 00 00 00    	add    $0x90,%ebx
801011c4:	81 fb 34 26 11 80    	cmp    $0x80112634,%ebx
801011ca:	73 35                	jae    80101201 <iget+0x6e>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801011cc:	8b 43 08             	mov    0x8(%ebx),%eax
801011cf:	85 c0                	test   %eax,%eax
801011d1:	7e e7                	jle    801011ba <iget+0x27>
801011d3:	39 3b                	cmp    %edi,(%ebx)
801011d5:	75 e3                	jne    801011ba <iget+0x27>
801011d7:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801011da:	39 4b 04             	cmp    %ecx,0x4(%ebx)
801011dd:	75 db                	jne    801011ba <iget+0x27>
      ip->ref++;
801011df:	83 c0 01             	add    $0x1,%eax
801011e2:	89 43 08             	mov    %eax,0x8(%ebx)
      release(&icache.lock);
801011e5:	83 ec 0c             	sub    $0xc,%esp
801011e8:	68 e0 09 11 80       	push   $0x801109e0
801011ed:	e8 bb 2c 00 00       	call   80103ead <release>
      return ip;
801011f2:	83 c4 10             	add    $0x10,%esp
801011f5:	89 de                	mov    %ebx,%esi
801011f7:	eb 32                	jmp    8010122b <iget+0x98>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011f9:	85 c0                	test   %eax,%eax
801011fb:	75 c1                	jne    801011be <iget+0x2b>
      empty = ip;
801011fd:	89 de                	mov    %ebx,%esi
801011ff:	eb bd                	jmp    801011be <iget+0x2b>
  if(empty == 0)
80101201:	85 f6                	test   %esi,%esi
80101203:	74 30                	je     80101235 <iget+0xa2>
  ip->dev = dev;
80101205:	89 3e                	mov    %edi,(%esi)
  ip->inum = inum;
80101207:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010120a:	89 46 04             	mov    %eax,0x4(%esi)
  ip->ref = 1;
8010120d:	c7 46 08 01 00 00 00 	movl   $0x1,0x8(%esi)
  ip->valid = 0;
80101214:	c7 46 4c 00 00 00 00 	movl   $0x0,0x4c(%esi)
  release(&icache.lock);
8010121b:	83 ec 0c             	sub    $0xc,%esp
8010121e:	68 e0 09 11 80       	push   $0x801109e0
80101223:	e8 85 2c 00 00       	call   80103ead <release>
  return ip;
80101228:	83 c4 10             	add    $0x10,%esp
}
8010122b:	89 f0                	mov    %esi,%eax
8010122d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101230:	5b                   	pop    %ebx
80101231:	5e                   	pop    %esi
80101232:	5f                   	pop    %edi
80101233:	5d                   	pop    %ebp
80101234:	c3                   	ret    
    panic("iget: no inodes");
80101235:	83 ec 0c             	sub    $0xc,%esp
80101238:	68 48 68 10 80       	push   $0x80106848
8010123d:	e8 06 f1 ff ff       	call   80100348 <panic>

80101242 <readsb>:
{
80101242:	55                   	push   %ebp
80101243:	89 e5                	mov    %esp,%ebp
80101245:	53                   	push   %ebx
80101246:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, 1);
80101249:	6a 01                	push   $0x1
8010124b:	ff 75 08             	pushl  0x8(%ebp)
8010124e:	e8 19 ef ff ff       	call   8010016c <bread>
80101253:	89 c3                	mov    %eax,%ebx
  memmove(sb, bp->data, sizeof(*sb));
80101255:	8d 40 5c             	lea    0x5c(%eax),%eax
80101258:	83 c4 0c             	add    $0xc,%esp
8010125b:	6a 1c                	push   $0x1c
8010125d:	50                   	push   %eax
8010125e:	ff 75 0c             	pushl  0xc(%ebp)
80101261:	e8 09 2d 00 00       	call   80103f6f <memmove>
  brelse(bp);
80101266:	89 1c 24             	mov    %ebx,(%esp)
80101269:	e8 67 ef ff ff       	call   801001d5 <brelse>
}
8010126e:	83 c4 10             	add    $0x10,%esp
80101271:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101274:	c9                   	leave  
80101275:	c3                   	ret    

80101276 <bfree>:
{
80101276:	55                   	push   %ebp
80101277:	89 e5                	mov    %esp,%ebp
80101279:	56                   	push   %esi
8010127a:	53                   	push   %ebx
8010127b:	89 c6                	mov    %eax,%esi
8010127d:	89 d3                	mov    %edx,%ebx
  readsb(dev, &sb);
8010127f:	83 ec 08             	sub    $0x8,%esp
80101282:	68 c0 09 11 80       	push   $0x801109c0
80101287:	50                   	push   %eax
80101288:	e8 b5 ff ff ff       	call   80101242 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
8010128d:	89 d8                	mov    %ebx,%eax
8010128f:	c1 e8 0c             	shr    $0xc,%eax
80101292:	03 05 d8 09 11 80    	add    0x801109d8,%eax
80101298:	83 c4 08             	add    $0x8,%esp
8010129b:	50                   	push   %eax
8010129c:	56                   	push   %esi
8010129d:	e8 ca ee ff ff       	call   8010016c <bread>
801012a2:	89 c6                	mov    %eax,%esi
  m = 1 << (bi % 8);
801012a4:	89 d9                	mov    %ebx,%ecx
801012a6:	83 e1 07             	and    $0x7,%ecx
801012a9:	b8 01 00 00 00       	mov    $0x1,%eax
801012ae:	d3 e0                	shl    %cl,%eax
  if((bp->data[bi/8] & m) == 0)
801012b0:	83 c4 10             	add    $0x10,%esp
801012b3:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
801012b9:	c1 fb 03             	sar    $0x3,%ebx
801012bc:	0f b6 54 1e 5c       	movzbl 0x5c(%esi,%ebx,1),%edx
801012c1:	0f b6 ca             	movzbl %dl,%ecx
801012c4:	85 c1                	test   %eax,%ecx
801012c6:	74 23                	je     801012eb <bfree+0x75>
  bp->data[bi/8] &= ~m;
801012c8:	f7 d0                	not    %eax
801012ca:	21 d0                	and    %edx,%eax
801012cc:	88 44 1e 5c          	mov    %al,0x5c(%esi,%ebx,1)
  log_write(bp);
801012d0:	83 ec 0c             	sub    $0xc,%esp
801012d3:	56                   	push   %esi
801012d4:	e8 9b 18 00 00       	call   80102b74 <log_write>
  brelse(bp);
801012d9:	89 34 24             	mov    %esi,(%esp)
801012dc:	e8 f4 ee ff ff       	call   801001d5 <brelse>
}
801012e1:	83 c4 10             	add    $0x10,%esp
801012e4:	8d 65 f8             	lea    -0x8(%ebp),%esp
801012e7:	5b                   	pop    %ebx
801012e8:	5e                   	pop    %esi
801012e9:	5d                   	pop    %ebp
801012ea:	c3                   	ret    
    panic("freeing free block");
801012eb:	83 ec 0c             	sub    $0xc,%esp
801012ee:	68 58 68 10 80       	push   $0x80106858
801012f3:	e8 50 f0 ff ff       	call   80100348 <panic>

801012f8 <iinit>:
{
801012f8:	55                   	push   %ebp
801012f9:	89 e5                	mov    %esp,%ebp
801012fb:	53                   	push   %ebx
801012fc:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012ff:	68 6b 68 10 80       	push   $0x8010686b
80101304:	68 e0 09 11 80       	push   $0x801109e0
80101309:	e8 fe 29 00 00       	call   80103d0c <initlock>
  for(i = 0; i < NINODE; i++) {
8010130e:	83 c4 10             	add    $0x10,%esp
80101311:	bb 00 00 00 00       	mov    $0x0,%ebx
80101316:	eb 21                	jmp    80101339 <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
80101318:	83 ec 08             	sub    $0x8,%esp
8010131b:	68 72 68 10 80       	push   $0x80106872
80101320:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101323:	89 d0                	mov    %edx,%eax
80101325:	c1 e0 04             	shl    $0x4,%eax
80101328:	05 20 0a 11 80       	add    $0x80110a20,%eax
8010132d:	50                   	push   %eax
8010132e:	e8 ce 28 00 00       	call   80103c01 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
80101333:	83 c3 01             	add    $0x1,%ebx
80101336:	83 c4 10             	add    $0x10,%esp
80101339:	83 fb 31             	cmp    $0x31,%ebx
8010133c:	7e da                	jle    80101318 <iinit+0x20>
  readsb(dev, &sb);
8010133e:	83 ec 08             	sub    $0x8,%esp
80101341:	68 c0 09 11 80       	push   $0x801109c0
80101346:	ff 75 08             	pushl  0x8(%ebp)
80101349:	e8 f4 fe ff ff       	call   80101242 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
8010134e:	ff 35 d8 09 11 80    	pushl  0x801109d8
80101354:	ff 35 d4 09 11 80    	pushl  0x801109d4
8010135a:	ff 35 d0 09 11 80    	pushl  0x801109d0
80101360:	ff 35 cc 09 11 80    	pushl  0x801109cc
80101366:	ff 35 c8 09 11 80    	pushl  0x801109c8
8010136c:	ff 35 c4 09 11 80    	pushl  0x801109c4
80101372:	ff 35 c0 09 11 80    	pushl  0x801109c0
80101378:	68 d8 68 10 80       	push   $0x801068d8
8010137d:	e8 89 f2 ff ff       	call   8010060b <cprintf>
}
80101382:	83 c4 30             	add    $0x30,%esp
80101385:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101388:	c9                   	leave  
80101389:	c3                   	ret    

8010138a <ialloc>:
{
8010138a:	55                   	push   %ebp
8010138b:	89 e5                	mov    %esp,%ebp
8010138d:	57                   	push   %edi
8010138e:	56                   	push   %esi
8010138f:	53                   	push   %ebx
80101390:	83 ec 1c             	sub    $0x1c,%esp
80101393:	8b 45 0c             	mov    0xc(%ebp),%eax
80101396:	89 45 e0             	mov    %eax,-0x20(%ebp)
  for(inum = 1; inum < sb.ninodes; inum++){
80101399:	bb 01 00 00 00       	mov    $0x1,%ebx
8010139e:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
801013a1:	39 1d c8 09 11 80    	cmp    %ebx,0x801109c8
801013a7:	76 3f                	jbe    801013e8 <ialloc+0x5e>
    bp = bread(dev, IBLOCK(inum, sb));
801013a9:	89 d8                	mov    %ebx,%eax
801013ab:	c1 e8 03             	shr    $0x3,%eax
801013ae:	03 05 d4 09 11 80    	add    0x801109d4,%eax
801013b4:	83 ec 08             	sub    $0x8,%esp
801013b7:	50                   	push   %eax
801013b8:	ff 75 08             	pushl  0x8(%ebp)
801013bb:	e8 ac ed ff ff       	call   8010016c <bread>
801013c0:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + inum%IPB;
801013c2:	89 d8                	mov    %ebx,%eax
801013c4:	83 e0 07             	and    $0x7,%eax
801013c7:	c1 e0 06             	shl    $0x6,%eax
801013ca:	8d 7c 06 5c          	lea    0x5c(%esi,%eax,1),%edi
    if(dip->type == 0){  // a free inode
801013ce:	83 c4 10             	add    $0x10,%esp
801013d1:	66 83 3f 00          	cmpw   $0x0,(%edi)
801013d5:	74 1e                	je     801013f5 <ialloc+0x6b>
    brelse(bp);
801013d7:	83 ec 0c             	sub    $0xc,%esp
801013da:	56                   	push   %esi
801013db:	e8 f5 ed ff ff       	call   801001d5 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
801013e0:	83 c3 01             	add    $0x1,%ebx
801013e3:	83 c4 10             	add    $0x10,%esp
801013e6:	eb b6                	jmp    8010139e <ialloc+0x14>
  panic("ialloc: no inodes");
801013e8:	83 ec 0c             	sub    $0xc,%esp
801013eb:	68 78 68 10 80       	push   $0x80106878
801013f0:	e8 53 ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013f5:	83 ec 04             	sub    $0x4,%esp
801013f8:	6a 40                	push   $0x40
801013fa:	6a 00                	push   $0x0
801013fc:	57                   	push   %edi
801013fd:	e8 f2 2a 00 00       	call   80103ef4 <memset>
      dip->type = type;
80101402:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80101406:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
80101409:	89 34 24             	mov    %esi,(%esp)
8010140c:	e8 63 17 00 00       	call   80102b74 <log_write>
      brelse(bp);
80101411:	89 34 24             	mov    %esi,(%esp)
80101414:	e8 bc ed ff ff       	call   801001d5 <brelse>
      return iget(dev, inum);
80101419:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010141c:	8b 45 08             	mov    0x8(%ebp),%eax
8010141f:	e8 6f fd ff ff       	call   80101193 <iget>
}
80101424:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101427:	5b                   	pop    %ebx
80101428:	5e                   	pop    %esi
80101429:	5f                   	pop    %edi
8010142a:	5d                   	pop    %ebp
8010142b:	c3                   	ret    

8010142c <iupdate>:
{
8010142c:	55                   	push   %ebp
8010142d:	89 e5                	mov    %esp,%ebp
8010142f:	56                   	push   %esi
80101430:	53                   	push   %ebx
80101431:	8b 5d 08             	mov    0x8(%ebp),%ebx
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101434:	8b 43 04             	mov    0x4(%ebx),%eax
80101437:	c1 e8 03             	shr    $0x3,%eax
8010143a:	03 05 d4 09 11 80    	add    0x801109d4,%eax
80101440:	83 ec 08             	sub    $0x8,%esp
80101443:	50                   	push   %eax
80101444:	ff 33                	pushl  (%ebx)
80101446:	e8 21 ed ff ff       	call   8010016c <bread>
8010144b:	89 c6                	mov    %eax,%esi
  dip = (struct dinode*)bp->data + ip->inum%IPB;
8010144d:	8b 43 04             	mov    0x4(%ebx),%eax
80101450:	83 e0 07             	and    $0x7,%eax
80101453:	c1 e0 06             	shl    $0x6,%eax
80101456:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
  dip->type = ip->type;
8010145a:	0f b7 53 50          	movzwl 0x50(%ebx),%edx
8010145e:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101461:	0f b7 53 52          	movzwl 0x52(%ebx),%edx
80101465:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80101469:	0f b7 53 54          	movzwl 0x54(%ebx),%edx
8010146d:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101471:	0f b7 53 56          	movzwl 0x56(%ebx),%edx
80101475:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101479:	8b 53 58             	mov    0x58(%ebx),%edx
8010147c:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
8010147f:	83 c3 5c             	add    $0x5c,%ebx
80101482:	83 c0 0c             	add    $0xc,%eax
80101485:	83 c4 0c             	add    $0xc,%esp
80101488:	6a 34                	push   $0x34
8010148a:	53                   	push   %ebx
8010148b:	50                   	push   %eax
8010148c:	e8 de 2a 00 00       	call   80103f6f <memmove>
  log_write(bp);
80101491:	89 34 24             	mov    %esi,(%esp)
80101494:	e8 db 16 00 00       	call   80102b74 <log_write>
  brelse(bp);
80101499:	89 34 24             	mov    %esi,(%esp)
8010149c:	e8 34 ed ff ff       	call   801001d5 <brelse>
}
801014a1:	83 c4 10             	add    $0x10,%esp
801014a4:	8d 65 f8             	lea    -0x8(%ebp),%esp
801014a7:	5b                   	pop    %ebx
801014a8:	5e                   	pop    %esi
801014a9:	5d                   	pop    %ebp
801014aa:	c3                   	ret    

801014ab <itrunc>:
{
801014ab:	55                   	push   %ebp
801014ac:	89 e5                	mov    %esp,%ebp
801014ae:	57                   	push   %edi
801014af:	56                   	push   %esi
801014b0:	53                   	push   %ebx
801014b1:	83 ec 1c             	sub    $0x1c,%esp
801014b4:	89 c6                	mov    %eax,%esi
  for(i = 0; i < NDIRECT; i++){
801014b6:	bb 00 00 00 00       	mov    $0x0,%ebx
801014bb:	eb 03                	jmp    801014c0 <itrunc+0x15>
801014bd:	83 c3 01             	add    $0x1,%ebx
801014c0:	83 fb 0b             	cmp    $0xb,%ebx
801014c3:	7f 19                	jg     801014de <itrunc+0x33>
    if(ip->addrs[i]){
801014c5:	8b 54 9e 5c          	mov    0x5c(%esi,%ebx,4),%edx
801014c9:	85 d2                	test   %edx,%edx
801014cb:	74 f0                	je     801014bd <itrunc+0x12>
      bfree(ip->dev, ip->addrs[i]);
801014cd:	8b 06                	mov    (%esi),%eax
801014cf:	e8 a2 fd ff ff       	call   80101276 <bfree>
      ip->addrs[i] = 0;
801014d4:	c7 44 9e 5c 00 00 00 	movl   $0x0,0x5c(%esi,%ebx,4)
801014db:	00 
801014dc:	eb df                	jmp    801014bd <itrunc+0x12>
  if(ip->addrs[NDIRECT]){
801014de:	8b 86 8c 00 00 00    	mov    0x8c(%esi),%eax
801014e4:	85 c0                	test   %eax,%eax
801014e6:	75 1b                	jne    80101503 <itrunc+0x58>
  ip->size = 0;
801014e8:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
  iupdate(ip);
801014ef:	83 ec 0c             	sub    $0xc,%esp
801014f2:	56                   	push   %esi
801014f3:	e8 34 ff ff ff       	call   8010142c <iupdate>
}
801014f8:	83 c4 10             	add    $0x10,%esp
801014fb:	8d 65 f4             	lea    -0xc(%ebp),%esp
801014fe:	5b                   	pop    %ebx
801014ff:	5e                   	pop    %esi
80101500:	5f                   	pop    %edi
80101501:	5d                   	pop    %ebp
80101502:	c3                   	ret    
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101503:	83 ec 08             	sub    $0x8,%esp
80101506:	50                   	push   %eax
80101507:	ff 36                	pushl  (%esi)
80101509:	e8 5e ec ff ff       	call   8010016c <bread>
8010150e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    a = (uint*)bp->data;
80101511:	8d 78 5c             	lea    0x5c(%eax),%edi
    for(j = 0; j < NINDIRECT; j++){
80101514:	83 c4 10             	add    $0x10,%esp
80101517:	bb 00 00 00 00       	mov    $0x0,%ebx
8010151c:	eb 03                	jmp    80101521 <itrunc+0x76>
8010151e:	83 c3 01             	add    $0x1,%ebx
80101521:	83 fb 7f             	cmp    $0x7f,%ebx
80101524:	77 10                	ja     80101536 <itrunc+0x8b>
      if(a[j])
80101526:	8b 14 9f             	mov    (%edi,%ebx,4),%edx
80101529:	85 d2                	test   %edx,%edx
8010152b:	74 f1                	je     8010151e <itrunc+0x73>
        bfree(ip->dev, a[j]);
8010152d:	8b 06                	mov    (%esi),%eax
8010152f:	e8 42 fd ff ff       	call   80101276 <bfree>
80101534:	eb e8                	jmp    8010151e <itrunc+0x73>
    brelse(bp);
80101536:	83 ec 0c             	sub    $0xc,%esp
80101539:	ff 75 e4             	pushl  -0x1c(%ebp)
8010153c:	e8 94 ec ff ff       	call   801001d5 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101541:	8b 06                	mov    (%esi),%eax
80101543:	8b 96 8c 00 00 00    	mov    0x8c(%esi),%edx
80101549:	e8 28 fd ff ff       	call   80101276 <bfree>
    ip->addrs[NDIRECT] = 0;
8010154e:	c7 86 8c 00 00 00 00 	movl   $0x0,0x8c(%esi)
80101555:	00 00 00 
80101558:	83 c4 10             	add    $0x10,%esp
8010155b:	eb 8b                	jmp    801014e8 <itrunc+0x3d>

8010155d <idup>:
{
8010155d:	55                   	push   %ebp
8010155e:	89 e5                	mov    %esp,%ebp
80101560:	53                   	push   %ebx
80101561:	83 ec 10             	sub    $0x10,%esp
80101564:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&icache.lock);
80101567:	68 e0 09 11 80       	push   $0x801109e0
8010156c:	e8 d7 28 00 00       	call   80103e48 <acquire>
  ip->ref++;
80101571:	8b 43 08             	mov    0x8(%ebx),%eax
80101574:	83 c0 01             	add    $0x1,%eax
80101577:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010157a:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
80101581:	e8 27 29 00 00       	call   80103ead <release>
}
80101586:	89 d8                	mov    %ebx,%eax
80101588:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010158b:	c9                   	leave  
8010158c:	c3                   	ret    

8010158d <ilock>:
{
8010158d:	55                   	push   %ebp
8010158e:	89 e5                	mov    %esp,%ebp
80101590:	56                   	push   %esi
80101591:	53                   	push   %ebx
80101592:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || ip->ref < 1)
80101595:	85 db                	test   %ebx,%ebx
80101597:	74 22                	je     801015bb <ilock+0x2e>
80101599:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
8010159d:	7e 1c                	jle    801015bb <ilock+0x2e>
  acquiresleep(&ip->lock);
8010159f:	83 ec 0c             	sub    $0xc,%esp
801015a2:	8d 43 0c             	lea    0xc(%ebx),%eax
801015a5:	50                   	push   %eax
801015a6:	e8 89 26 00 00       	call   80103c34 <acquiresleep>
  if(ip->valid == 0){
801015ab:	83 c4 10             	add    $0x10,%esp
801015ae:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801015b2:	74 14                	je     801015c8 <ilock+0x3b>
}
801015b4:	8d 65 f8             	lea    -0x8(%ebp),%esp
801015b7:	5b                   	pop    %ebx
801015b8:	5e                   	pop    %esi
801015b9:	5d                   	pop    %ebp
801015ba:	c3                   	ret    
    panic("ilock");
801015bb:	83 ec 0c             	sub    $0xc,%esp
801015be:	68 8a 68 10 80       	push   $0x8010688a
801015c3:	e8 80 ed ff ff       	call   80100348 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
801015c8:	8b 43 04             	mov    0x4(%ebx),%eax
801015cb:	c1 e8 03             	shr    $0x3,%eax
801015ce:	03 05 d4 09 11 80    	add    0x801109d4,%eax
801015d4:	83 ec 08             	sub    $0x8,%esp
801015d7:	50                   	push   %eax
801015d8:	ff 33                	pushl  (%ebx)
801015da:	e8 8d eb ff ff       	call   8010016c <bread>
801015df:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801015e1:	8b 43 04             	mov    0x4(%ebx),%eax
801015e4:	83 e0 07             	and    $0x7,%eax
801015e7:	c1 e0 06             	shl    $0x6,%eax
801015ea:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
    ip->type = dip->type;
801015ee:	0f b7 10             	movzwl (%eax),%edx
801015f1:	66 89 53 50          	mov    %dx,0x50(%ebx)
    ip->major = dip->major;
801015f5:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801015f9:	66 89 53 52          	mov    %dx,0x52(%ebx)
    ip->minor = dip->minor;
801015fd:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101601:	66 89 53 54          	mov    %dx,0x54(%ebx)
    ip->nlink = dip->nlink;
80101605:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101609:	66 89 53 56          	mov    %dx,0x56(%ebx)
    ip->size = dip->size;
8010160d:	8b 50 08             	mov    0x8(%eax),%edx
80101610:	89 53 58             	mov    %edx,0x58(%ebx)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101613:	83 c0 0c             	add    $0xc,%eax
80101616:	8d 53 5c             	lea    0x5c(%ebx),%edx
80101619:	83 c4 0c             	add    $0xc,%esp
8010161c:	6a 34                	push   $0x34
8010161e:	50                   	push   %eax
8010161f:	52                   	push   %edx
80101620:	e8 4a 29 00 00       	call   80103f6f <memmove>
    brelse(bp);
80101625:	89 34 24             	mov    %esi,(%esp)
80101628:	e8 a8 eb ff ff       	call   801001d5 <brelse>
    ip->valid = 1;
8010162d:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
    if(ip->type == 0)
80101634:	83 c4 10             	add    $0x10,%esp
80101637:	66 83 7b 50 00       	cmpw   $0x0,0x50(%ebx)
8010163c:	0f 85 72 ff ff ff    	jne    801015b4 <ilock+0x27>
      panic("ilock: no type");
80101642:	83 ec 0c             	sub    $0xc,%esp
80101645:	68 90 68 10 80       	push   $0x80106890
8010164a:	e8 f9 ec ff ff       	call   80100348 <panic>

8010164f <iunlock>:
{
8010164f:	55                   	push   %ebp
80101650:	89 e5                	mov    %esp,%ebp
80101652:	56                   	push   %esi
80101653:	53                   	push   %ebx
80101654:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
80101657:	85 db                	test   %ebx,%ebx
80101659:	74 2c                	je     80101687 <iunlock+0x38>
8010165b:	8d 73 0c             	lea    0xc(%ebx),%esi
8010165e:	83 ec 0c             	sub    $0xc,%esp
80101661:	56                   	push   %esi
80101662:	e8 57 26 00 00       	call   80103cbe <holdingsleep>
80101667:	83 c4 10             	add    $0x10,%esp
8010166a:	85 c0                	test   %eax,%eax
8010166c:	74 19                	je     80101687 <iunlock+0x38>
8010166e:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101672:	7e 13                	jle    80101687 <iunlock+0x38>
  releasesleep(&ip->lock);
80101674:	83 ec 0c             	sub    $0xc,%esp
80101677:	56                   	push   %esi
80101678:	e8 06 26 00 00       	call   80103c83 <releasesleep>
}
8010167d:	83 c4 10             	add    $0x10,%esp
80101680:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101683:	5b                   	pop    %ebx
80101684:	5e                   	pop    %esi
80101685:	5d                   	pop    %ebp
80101686:	c3                   	ret    
    panic("iunlock");
80101687:	83 ec 0c             	sub    $0xc,%esp
8010168a:	68 9f 68 10 80       	push   $0x8010689f
8010168f:	e8 b4 ec ff ff       	call   80100348 <panic>

80101694 <iput>:
{
80101694:	55                   	push   %ebp
80101695:	89 e5                	mov    %esp,%ebp
80101697:	57                   	push   %edi
80101698:	56                   	push   %esi
80101699:	53                   	push   %ebx
8010169a:	83 ec 18             	sub    $0x18,%esp
8010169d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquiresleep(&ip->lock);
801016a0:	8d 73 0c             	lea    0xc(%ebx),%esi
801016a3:	56                   	push   %esi
801016a4:	e8 8b 25 00 00       	call   80103c34 <acquiresleep>
  if(ip->valid && ip->nlink == 0){
801016a9:	83 c4 10             	add    $0x10,%esp
801016ac:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016b0:	74 07                	je     801016b9 <iput+0x25>
801016b2:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016b7:	74 35                	je     801016ee <iput+0x5a>
  releasesleep(&ip->lock);
801016b9:	83 ec 0c             	sub    $0xc,%esp
801016bc:	56                   	push   %esi
801016bd:	e8 c1 25 00 00       	call   80103c83 <releasesleep>
  acquire(&icache.lock);
801016c2:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016c9:	e8 7a 27 00 00       	call   80103e48 <acquire>
  ip->ref--;
801016ce:	8b 43 08             	mov    0x8(%ebx),%eax
801016d1:	83 e8 01             	sub    $0x1,%eax
801016d4:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016d7:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016de:	e8 ca 27 00 00       	call   80103ead <release>
}
801016e3:	83 c4 10             	add    $0x10,%esp
801016e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
801016e9:	5b                   	pop    %ebx
801016ea:	5e                   	pop    %esi
801016eb:	5f                   	pop    %edi
801016ec:	5d                   	pop    %ebp
801016ed:	c3                   	ret    
    acquire(&icache.lock);
801016ee:	83 ec 0c             	sub    $0xc,%esp
801016f1:	68 e0 09 11 80       	push   $0x801109e0
801016f6:	e8 4d 27 00 00       	call   80103e48 <acquire>
    int r = ip->ref;
801016fb:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016fe:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
80101705:	e8 a3 27 00 00       	call   80103ead <release>
    if(r == 1){
8010170a:	83 c4 10             	add    $0x10,%esp
8010170d:	83 ff 01             	cmp    $0x1,%edi
80101710:	75 a7                	jne    801016b9 <iput+0x25>
      itrunc(ip);
80101712:	89 d8                	mov    %ebx,%eax
80101714:	e8 92 fd ff ff       	call   801014ab <itrunc>
      ip->type = 0;
80101719:	66 c7 43 50 00 00    	movw   $0x0,0x50(%ebx)
      iupdate(ip);
8010171f:	83 ec 0c             	sub    $0xc,%esp
80101722:	53                   	push   %ebx
80101723:	e8 04 fd ff ff       	call   8010142c <iupdate>
      ip->valid = 0;
80101728:	c7 43 4c 00 00 00 00 	movl   $0x0,0x4c(%ebx)
8010172f:	83 c4 10             	add    $0x10,%esp
80101732:	eb 85                	jmp    801016b9 <iput+0x25>

80101734 <iunlockput>:
{
80101734:	55                   	push   %ebp
80101735:	89 e5                	mov    %esp,%ebp
80101737:	53                   	push   %ebx
80101738:	83 ec 10             	sub    $0x10,%esp
8010173b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  iunlock(ip);
8010173e:	53                   	push   %ebx
8010173f:	e8 0b ff ff ff       	call   8010164f <iunlock>
  iput(ip);
80101744:	89 1c 24             	mov    %ebx,(%esp)
80101747:	e8 48 ff ff ff       	call   80101694 <iput>
}
8010174c:	83 c4 10             	add    $0x10,%esp
8010174f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101752:	c9                   	leave  
80101753:	c3                   	ret    

80101754 <stati>:
{
80101754:	55                   	push   %ebp
80101755:	89 e5                	mov    %esp,%ebp
80101757:	8b 55 08             	mov    0x8(%ebp),%edx
8010175a:	8b 45 0c             	mov    0xc(%ebp),%eax
  st->dev = ip->dev;
8010175d:	8b 0a                	mov    (%edx),%ecx
8010175f:	89 48 04             	mov    %ecx,0x4(%eax)
  st->ino = ip->inum;
80101762:	8b 4a 04             	mov    0x4(%edx),%ecx
80101765:	89 48 08             	mov    %ecx,0x8(%eax)
  st->type = ip->type;
80101768:	0f b7 4a 50          	movzwl 0x50(%edx),%ecx
8010176c:	66 89 08             	mov    %cx,(%eax)
  st->nlink = ip->nlink;
8010176f:	0f b7 4a 56          	movzwl 0x56(%edx),%ecx
80101773:	66 89 48 0c          	mov    %cx,0xc(%eax)
  st->size = ip->size;
80101777:	8b 52 58             	mov    0x58(%edx),%edx
8010177a:	89 50 10             	mov    %edx,0x10(%eax)
}
8010177d:	5d                   	pop    %ebp
8010177e:	c3                   	ret    

8010177f <readi>:
{
8010177f:	55                   	push   %ebp
80101780:	89 e5                	mov    %esp,%ebp
80101782:	57                   	push   %edi
80101783:	56                   	push   %esi
80101784:	53                   	push   %ebx
80101785:	83 ec 1c             	sub    $0x1c,%esp
80101788:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(ip->type == T_DEV){
8010178b:	8b 45 08             	mov    0x8(%ebp),%eax
8010178e:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101793:	74 2c                	je     801017c1 <readi+0x42>
  if(off > ip->size || off + n < off)
80101795:	8b 45 08             	mov    0x8(%ebp),%eax
80101798:	8b 40 58             	mov    0x58(%eax),%eax
8010179b:	39 f8                	cmp    %edi,%eax
8010179d:	0f 82 cb 00 00 00    	jb     8010186e <readi+0xef>
801017a3:	89 fa                	mov    %edi,%edx
801017a5:	03 55 14             	add    0x14(%ebp),%edx
801017a8:	0f 82 c7 00 00 00    	jb     80101875 <readi+0xf6>
  if(off + n > ip->size)
801017ae:	39 d0                	cmp    %edx,%eax
801017b0:	73 05                	jae    801017b7 <readi+0x38>
    n = ip->size - off;
801017b2:	29 f8                	sub    %edi,%eax
801017b4:	89 45 14             	mov    %eax,0x14(%ebp)
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
801017b7:	be 00 00 00 00       	mov    $0x0,%esi
801017bc:	e9 8f 00 00 00       	jmp    80101850 <readi+0xd1>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
801017c1:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801017c5:	66 83 f8 09          	cmp    $0x9,%ax
801017c9:	0f 87 91 00 00 00    	ja     80101860 <readi+0xe1>
801017cf:	98                   	cwtl   
801017d0:	8b 04 c5 60 09 11 80 	mov    -0x7feef6a0(,%eax,8),%eax
801017d7:	85 c0                	test   %eax,%eax
801017d9:	0f 84 88 00 00 00    	je     80101867 <readi+0xe8>
    return devsw[ip->major].read(ip, dst, n);
801017df:	83 ec 04             	sub    $0x4,%esp
801017e2:	ff 75 14             	pushl  0x14(%ebp)
801017e5:	ff 75 0c             	pushl  0xc(%ebp)
801017e8:	ff 75 08             	pushl  0x8(%ebp)
801017eb:	ff d0                	call   *%eax
801017ed:	83 c4 10             	add    $0x10,%esp
801017f0:	eb 66                	jmp    80101858 <readi+0xd9>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801017f2:	89 fa                	mov    %edi,%edx
801017f4:	c1 ea 09             	shr    $0x9,%edx
801017f7:	8b 45 08             	mov    0x8(%ebp),%eax
801017fa:	e8 ee f8 ff ff       	call   801010ed <bmap>
801017ff:	83 ec 08             	sub    $0x8,%esp
80101802:	50                   	push   %eax
80101803:	8b 45 08             	mov    0x8(%ebp),%eax
80101806:	ff 30                	pushl  (%eax)
80101808:	e8 5f e9 ff ff       	call   8010016c <bread>
8010180d:	89 c1                	mov    %eax,%ecx
    m = min(n - tot, BSIZE - off%BSIZE);
8010180f:	89 f8                	mov    %edi,%eax
80101811:	25 ff 01 00 00       	and    $0x1ff,%eax
80101816:	bb 00 02 00 00       	mov    $0x200,%ebx
8010181b:	29 c3                	sub    %eax,%ebx
8010181d:	8b 55 14             	mov    0x14(%ebp),%edx
80101820:	29 f2                	sub    %esi,%edx
80101822:	83 c4 0c             	add    $0xc,%esp
80101825:	39 d3                	cmp    %edx,%ebx
80101827:	0f 47 da             	cmova  %edx,%ebx
    memmove(dst, bp->data + off%BSIZE, m);
8010182a:	53                   	push   %ebx
8010182b:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
8010182e:	8d 44 01 5c          	lea    0x5c(%ecx,%eax,1),%eax
80101832:	50                   	push   %eax
80101833:	ff 75 0c             	pushl  0xc(%ebp)
80101836:	e8 34 27 00 00       	call   80103f6f <memmove>
    brelse(bp);
8010183b:	83 c4 04             	add    $0x4,%esp
8010183e:	ff 75 e4             	pushl  -0x1c(%ebp)
80101841:	e8 8f e9 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101846:	01 de                	add    %ebx,%esi
80101848:	01 df                	add    %ebx,%edi
8010184a:	01 5d 0c             	add    %ebx,0xc(%ebp)
8010184d:	83 c4 10             	add    $0x10,%esp
80101850:	39 75 14             	cmp    %esi,0x14(%ebp)
80101853:	77 9d                	ja     801017f2 <readi+0x73>
  return n;
80101855:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101858:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010185b:	5b                   	pop    %ebx
8010185c:	5e                   	pop    %esi
8010185d:	5f                   	pop    %edi
8010185e:	5d                   	pop    %ebp
8010185f:	c3                   	ret    
      return -1;
80101860:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101865:	eb f1                	jmp    80101858 <readi+0xd9>
80101867:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010186c:	eb ea                	jmp    80101858 <readi+0xd9>
    return -1;
8010186e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101873:	eb e3                	jmp    80101858 <readi+0xd9>
80101875:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010187a:	eb dc                	jmp    80101858 <readi+0xd9>

8010187c <writei>:
{
8010187c:	55                   	push   %ebp
8010187d:	89 e5                	mov    %esp,%ebp
8010187f:	57                   	push   %edi
80101880:	56                   	push   %esi
80101881:	53                   	push   %ebx
80101882:	83 ec 0c             	sub    $0xc,%esp
  if(ip->type == T_DEV){
80101885:	8b 45 08             	mov    0x8(%ebp),%eax
80101888:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
8010188d:	74 2f                	je     801018be <writei+0x42>
  if(off > ip->size || off + n < off)
8010188f:	8b 45 08             	mov    0x8(%ebp),%eax
80101892:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101895:	39 48 58             	cmp    %ecx,0x58(%eax)
80101898:	0f 82 f4 00 00 00    	jb     80101992 <writei+0x116>
8010189e:	89 c8                	mov    %ecx,%eax
801018a0:	03 45 14             	add    0x14(%ebp),%eax
801018a3:	0f 82 f0 00 00 00    	jb     80101999 <writei+0x11d>
  if(off + n > MAXFILE*BSIZE)
801018a9:	3d 00 18 01 00       	cmp    $0x11800,%eax
801018ae:	0f 87 ec 00 00 00    	ja     801019a0 <writei+0x124>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801018b4:	be 00 00 00 00       	mov    $0x0,%esi
801018b9:	e9 94 00 00 00       	jmp    80101952 <writei+0xd6>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
801018be:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801018c2:	66 83 f8 09          	cmp    $0x9,%ax
801018c6:	0f 87 b8 00 00 00    	ja     80101984 <writei+0x108>
801018cc:	98                   	cwtl   
801018cd:	8b 04 c5 64 09 11 80 	mov    -0x7feef69c(,%eax,8),%eax
801018d4:	85 c0                	test   %eax,%eax
801018d6:	0f 84 af 00 00 00    	je     8010198b <writei+0x10f>
    return devsw[ip->major].write(ip, src, n);
801018dc:	83 ec 04             	sub    $0x4,%esp
801018df:	ff 75 14             	pushl  0x14(%ebp)
801018e2:	ff 75 0c             	pushl  0xc(%ebp)
801018e5:	ff 75 08             	pushl  0x8(%ebp)
801018e8:	ff d0                	call   *%eax
801018ea:	83 c4 10             	add    $0x10,%esp
801018ed:	eb 7c                	jmp    8010196b <writei+0xef>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801018ef:	8b 55 10             	mov    0x10(%ebp),%edx
801018f2:	c1 ea 09             	shr    $0x9,%edx
801018f5:	8b 45 08             	mov    0x8(%ebp),%eax
801018f8:	e8 f0 f7 ff ff       	call   801010ed <bmap>
801018fd:	83 ec 08             	sub    $0x8,%esp
80101900:	50                   	push   %eax
80101901:	8b 45 08             	mov    0x8(%ebp),%eax
80101904:	ff 30                	pushl  (%eax)
80101906:	e8 61 e8 ff ff       	call   8010016c <bread>
8010190b:	89 c7                	mov    %eax,%edi
    m = min(n - tot, BSIZE - off%BSIZE);
8010190d:	8b 45 10             	mov    0x10(%ebp),%eax
80101910:	25 ff 01 00 00       	and    $0x1ff,%eax
80101915:	bb 00 02 00 00       	mov    $0x200,%ebx
8010191a:	29 c3                	sub    %eax,%ebx
8010191c:	8b 55 14             	mov    0x14(%ebp),%edx
8010191f:	29 f2                	sub    %esi,%edx
80101921:	83 c4 0c             	add    $0xc,%esp
80101924:	39 d3                	cmp    %edx,%ebx
80101926:	0f 47 da             	cmova  %edx,%ebx
    memmove(bp->data + off%BSIZE, src, m);
80101929:	53                   	push   %ebx
8010192a:	ff 75 0c             	pushl  0xc(%ebp)
8010192d:	8d 44 07 5c          	lea    0x5c(%edi,%eax,1),%eax
80101931:	50                   	push   %eax
80101932:	e8 38 26 00 00       	call   80103f6f <memmove>
    log_write(bp);
80101937:	89 3c 24             	mov    %edi,(%esp)
8010193a:	e8 35 12 00 00       	call   80102b74 <log_write>
    brelse(bp);
8010193f:	89 3c 24             	mov    %edi,(%esp)
80101942:	e8 8e e8 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80101947:	01 de                	add    %ebx,%esi
80101949:	01 5d 10             	add    %ebx,0x10(%ebp)
8010194c:	01 5d 0c             	add    %ebx,0xc(%ebp)
8010194f:	83 c4 10             	add    $0x10,%esp
80101952:	3b 75 14             	cmp    0x14(%ebp),%esi
80101955:	72 98                	jb     801018ef <writei+0x73>
  if(n > 0 && off > ip->size){
80101957:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010195b:	74 0b                	je     80101968 <writei+0xec>
8010195d:	8b 45 08             	mov    0x8(%ebp),%eax
80101960:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101963:	39 48 58             	cmp    %ecx,0x58(%eax)
80101966:	72 0b                	jb     80101973 <writei+0xf7>
  return n;
80101968:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010196b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010196e:	5b                   	pop    %ebx
8010196f:	5e                   	pop    %esi
80101970:	5f                   	pop    %edi
80101971:	5d                   	pop    %ebp
80101972:	c3                   	ret    
    ip->size = off;
80101973:	89 48 58             	mov    %ecx,0x58(%eax)
    iupdate(ip);
80101976:	83 ec 0c             	sub    $0xc,%esp
80101979:	50                   	push   %eax
8010197a:	e8 ad fa ff ff       	call   8010142c <iupdate>
8010197f:	83 c4 10             	add    $0x10,%esp
80101982:	eb e4                	jmp    80101968 <writei+0xec>
      return -1;
80101984:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101989:	eb e0                	jmp    8010196b <writei+0xef>
8010198b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101990:	eb d9                	jmp    8010196b <writei+0xef>
    return -1;
80101992:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101997:	eb d2                	jmp    8010196b <writei+0xef>
80101999:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010199e:	eb cb                	jmp    8010196b <writei+0xef>
    return -1;
801019a0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801019a5:	eb c4                	jmp    8010196b <writei+0xef>

801019a7 <namecmp>:
{
801019a7:	55                   	push   %ebp
801019a8:	89 e5                	mov    %esp,%ebp
801019aa:	83 ec 0c             	sub    $0xc,%esp
  return strncmp(s, t, DIRSIZ);
801019ad:	6a 0e                	push   $0xe
801019af:	ff 75 0c             	pushl  0xc(%ebp)
801019b2:	ff 75 08             	pushl  0x8(%ebp)
801019b5:	e8 1c 26 00 00       	call   80103fd6 <strncmp>
}
801019ba:	c9                   	leave  
801019bb:	c3                   	ret    

801019bc <dirlookup>:
{
801019bc:	55                   	push   %ebp
801019bd:	89 e5                	mov    %esp,%ebp
801019bf:	57                   	push   %edi
801019c0:	56                   	push   %esi
801019c1:	53                   	push   %ebx
801019c2:	83 ec 1c             	sub    $0x1c,%esp
801019c5:	8b 75 08             	mov    0x8(%ebp),%esi
801019c8:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if(dp->type != T_DIR)
801019cb:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
801019d0:	75 07                	jne    801019d9 <dirlookup+0x1d>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019d2:	bb 00 00 00 00       	mov    $0x0,%ebx
801019d7:	eb 1d                	jmp    801019f6 <dirlookup+0x3a>
    panic("dirlookup not DIR");
801019d9:	83 ec 0c             	sub    $0xc,%esp
801019dc:	68 a7 68 10 80       	push   $0x801068a7
801019e1:	e8 62 e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019e6:	83 ec 0c             	sub    $0xc,%esp
801019e9:	68 b9 68 10 80       	push   $0x801068b9
801019ee:	e8 55 e9 ff ff       	call   80100348 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019f3:	83 c3 10             	add    $0x10,%ebx
801019f6:	39 5e 58             	cmp    %ebx,0x58(%esi)
801019f9:	76 48                	jbe    80101a43 <dirlookup+0x87>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801019fb:	6a 10                	push   $0x10
801019fd:	53                   	push   %ebx
801019fe:	8d 45 d8             	lea    -0x28(%ebp),%eax
80101a01:	50                   	push   %eax
80101a02:	56                   	push   %esi
80101a03:	e8 77 fd ff ff       	call   8010177f <readi>
80101a08:	83 c4 10             	add    $0x10,%esp
80101a0b:	83 f8 10             	cmp    $0x10,%eax
80101a0e:	75 d6                	jne    801019e6 <dirlookup+0x2a>
    if(de.inum == 0)
80101a10:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101a15:	74 dc                	je     801019f3 <dirlookup+0x37>
    if(namecmp(name, de.name) == 0){
80101a17:	83 ec 08             	sub    $0x8,%esp
80101a1a:	8d 45 da             	lea    -0x26(%ebp),%eax
80101a1d:	50                   	push   %eax
80101a1e:	57                   	push   %edi
80101a1f:	e8 83 ff ff ff       	call   801019a7 <namecmp>
80101a24:	83 c4 10             	add    $0x10,%esp
80101a27:	85 c0                	test   %eax,%eax
80101a29:	75 c8                	jne    801019f3 <dirlookup+0x37>
      if(poff)
80101a2b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80101a2f:	74 05                	je     80101a36 <dirlookup+0x7a>
        *poff = off;
80101a31:	8b 45 10             	mov    0x10(%ebp),%eax
80101a34:	89 18                	mov    %ebx,(%eax)
      inum = de.inum;
80101a36:	0f b7 55 d8          	movzwl -0x28(%ebp),%edx
      return iget(dp->dev, inum);
80101a3a:	8b 06                	mov    (%esi),%eax
80101a3c:	e8 52 f7 ff ff       	call   80101193 <iget>
80101a41:	eb 05                	jmp    80101a48 <dirlookup+0x8c>
  return 0;
80101a43:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101a48:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a4b:	5b                   	pop    %ebx
80101a4c:	5e                   	pop    %esi
80101a4d:	5f                   	pop    %edi
80101a4e:	5d                   	pop    %ebp
80101a4f:	c3                   	ret    

80101a50 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80101a50:	55                   	push   %ebp
80101a51:	89 e5                	mov    %esp,%ebp
80101a53:	57                   	push   %edi
80101a54:	56                   	push   %esi
80101a55:	53                   	push   %ebx
80101a56:	83 ec 1c             	sub    $0x1c,%esp
80101a59:	89 c6                	mov    %eax,%esi
80101a5b:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101a5e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  struct inode *ip, *next;

  if(*path == '/')
80101a61:	80 38 2f             	cmpb   $0x2f,(%eax)
80101a64:	74 17                	je     80101a7d <namex+0x2d>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
80101a66:	e8 3b 1a 00 00       	call   801034a6 <myproc>
80101a6b:	83 ec 0c             	sub    $0xc,%esp
80101a6e:	ff 70 68             	pushl  0x68(%eax)
80101a71:	e8 e7 fa ff ff       	call   8010155d <idup>
80101a76:	89 c3                	mov    %eax,%ebx
80101a78:	83 c4 10             	add    $0x10,%esp
80101a7b:	eb 53                	jmp    80101ad0 <namex+0x80>
    ip = iget(ROOTDEV, ROOTINO);
80101a7d:	ba 01 00 00 00       	mov    $0x1,%edx
80101a82:	b8 01 00 00 00       	mov    $0x1,%eax
80101a87:	e8 07 f7 ff ff       	call   80101193 <iget>
80101a8c:	89 c3                	mov    %eax,%ebx
80101a8e:	eb 40                	jmp    80101ad0 <namex+0x80>

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
      iunlockput(ip);
80101a90:	83 ec 0c             	sub    $0xc,%esp
80101a93:	53                   	push   %ebx
80101a94:	e8 9b fc ff ff       	call   80101734 <iunlockput>
      return 0;
80101a99:	83 c4 10             	add    $0x10,%esp
80101a9c:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
80101aa1:	89 d8                	mov    %ebx,%eax
80101aa3:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101aa6:	5b                   	pop    %ebx
80101aa7:	5e                   	pop    %esi
80101aa8:	5f                   	pop    %edi
80101aa9:	5d                   	pop    %ebp
80101aaa:	c3                   	ret    
    if((next = dirlookup(ip, name, 0)) == 0){
80101aab:	83 ec 04             	sub    $0x4,%esp
80101aae:	6a 00                	push   $0x0
80101ab0:	ff 75 e4             	pushl  -0x1c(%ebp)
80101ab3:	53                   	push   %ebx
80101ab4:	e8 03 ff ff ff       	call   801019bc <dirlookup>
80101ab9:	89 c7                	mov    %eax,%edi
80101abb:	83 c4 10             	add    $0x10,%esp
80101abe:	85 c0                	test   %eax,%eax
80101ac0:	74 4a                	je     80101b0c <namex+0xbc>
    iunlockput(ip);
80101ac2:	83 ec 0c             	sub    $0xc,%esp
80101ac5:	53                   	push   %ebx
80101ac6:	e8 69 fc ff ff       	call   80101734 <iunlockput>
    ip = next;
80101acb:	83 c4 10             	add    $0x10,%esp
80101ace:	89 fb                	mov    %edi,%ebx
  while((path = skipelem(path, name)) != 0){
80101ad0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101ad3:	89 f0                	mov    %esi,%eax
80101ad5:	e8 77 f4 ff ff       	call   80100f51 <skipelem>
80101ada:	89 c6                	mov    %eax,%esi
80101adc:	85 c0                	test   %eax,%eax
80101ade:	74 3c                	je     80101b1c <namex+0xcc>
    ilock(ip);
80101ae0:	83 ec 0c             	sub    $0xc,%esp
80101ae3:	53                   	push   %ebx
80101ae4:	e8 a4 fa ff ff       	call   8010158d <ilock>
    if(ip->type != T_DIR){
80101ae9:	83 c4 10             	add    $0x10,%esp
80101aec:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80101af1:	75 9d                	jne    80101a90 <namex+0x40>
    if(nameiparent && *path == '\0'){
80101af3:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101af7:	74 b2                	je     80101aab <namex+0x5b>
80101af9:	80 3e 00             	cmpb   $0x0,(%esi)
80101afc:	75 ad                	jne    80101aab <namex+0x5b>
      iunlock(ip);
80101afe:	83 ec 0c             	sub    $0xc,%esp
80101b01:	53                   	push   %ebx
80101b02:	e8 48 fb ff ff       	call   8010164f <iunlock>
      return ip;
80101b07:	83 c4 10             	add    $0x10,%esp
80101b0a:	eb 95                	jmp    80101aa1 <namex+0x51>
      iunlockput(ip);
80101b0c:	83 ec 0c             	sub    $0xc,%esp
80101b0f:	53                   	push   %ebx
80101b10:	e8 1f fc ff ff       	call   80101734 <iunlockput>
      return 0;
80101b15:	83 c4 10             	add    $0x10,%esp
80101b18:	89 fb                	mov    %edi,%ebx
80101b1a:	eb 85                	jmp    80101aa1 <namex+0x51>
  if(nameiparent){
80101b1c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101b20:	0f 84 7b ff ff ff    	je     80101aa1 <namex+0x51>
    iput(ip);
80101b26:	83 ec 0c             	sub    $0xc,%esp
80101b29:	53                   	push   %ebx
80101b2a:	e8 65 fb ff ff       	call   80101694 <iput>
    return 0;
80101b2f:	83 c4 10             	add    $0x10,%esp
80101b32:	bb 00 00 00 00       	mov    $0x0,%ebx
80101b37:	e9 65 ff ff ff       	jmp    80101aa1 <namex+0x51>

80101b3c <dirlink>:
{
80101b3c:	55                   	push   %ebp
80101b3d:	89 e5                	mov    %esp,%ebp
80101b3f:	57                   	push   %edi
80101b40:	56                   	push   %esi
80101b41:	53                   	push   %ebx
80101b42:	83 ec 20             	sub    $0x20,%esp
80101b45:	8b 5d 08             	mov    0x8(%ebp),%ebx
80101b48:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if((ip = dirlookup(dp, name, 0)) != 0){
80101b4b:	6a 00                	push   $0x0
80101b4d:	57                   	push   %edi
80101b4e:	53                   	push   %ebx
80101b4f:	e8 68 fe ff ff       	call   801019bc <dirlookup>
80101b54:	83 c4 10             	add    $0x10,%esp
80101b57:	85 c0                	test   %eax,%eax
80101b59:	75 2d                	jne    80101b88 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b5b:	b8 00 00 00 00       	mov    $0x0,%eax
80101b60:	89 c6                	mov    %eax,%esi
80101b62:	39 43 58             	cmp    %eax,0x58(%ebx)
80101b65:	76 41                	jbe    80101ba8 <dirlink+0x6c>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101b67:	6a 10                	push   $0x10
80101b69:	50                   	push   %eax
80101b6a:	8d 45 d8             	lea    -0x28(%ebp),%eax
80101b6d:	50                   	push   %eax
80101b6e:	53                   	push   %ebx
80101b6f:	e8 0b fc ff ff       	call   8010177f <readi>
80101b74:	83 c4 10             	add    $0x10,%esp
80101b77:	83 f8 10             	cmp    $0x10,%eax
80101b7a:	75 1f                	jne    80101b9b <dirlink+0x5f>
    if(de.inum == 0)
80101b7c:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101b81:	74 25                	je     80101ba8 <dirlink+0x6c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b83:	8d 46 10             	lea    0x10(%esi),%eax
80101b86:	eb d8                	jmp    80101b60 <dirlink+0x24>
    iput(ip);
80101b88:	83 ec 0c             	sub    $0xc,%esp
80101b8b:	50                   	push   %eax
80101b8c:	e8 03 fb ff ff       	call   80101694 <iput>
    return -1;
80101b91:	83 c4 10             	add    $0x10,%esp
80101b94:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101b99:	eb 3d                	jmp    80101bd8 <dirlink+0x9c>
      panic("dirlink read");
80101b9b:	83 ec 0c             	sub    $0xc,%esp
80101b9e:	68 c8 68 10 80       	push   $0x801068c8
80101ba3:	e8 a0 e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101ba8:	83 ec 04             	sub    $0x4,%esp
80101bab:	6a 0e                	push   $0xe
80101bad:	57                   	push   %edi
80101bae:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101bb1:	8d 45 da             	lea    -0x26(%ebp),%eax
80101bb4:	50                   	push   %eax
80101bb5:	e8 59 24 00 00       	call   80104013 <strncpy>
  de.inum = inum;
80101bba:	8b 45 10             	mov    0x10(%ebp),%eax
80101bbd:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101bc1:	6a 10                	push   $0x10
80101bc3:	56                   	push   %esi
80101bc4:	57                   	push   %edi
80101bc5:	53                   	push   %ebx
80101bc6:	e8 b1 fc ff ff       	call   8010187c <writei>
80101bcb:	83 c4 20             	add    $0x20,%esp
80101bce:	83 f8 10             	cmp    $0x10,%eax
80101bd1:	75 0d                	jne    80101be0 <dirlink+0xa4>
  return 0;
80101bd3:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101bd8:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101bdb:	5b                   	pop    %ebx
80101bdc:	5e                   	pop    %esi
80101bdd:	5f                   	pop    %edi
80101bde:	5d                   	pop    %ebp
80101bdf:	c3                   	ret    
    panic("dirlink");
80101be0:	83 ec 0c             	sub    $0xc,%esp
80101be3:	68 d4 6e 10 80       	push   $0x80106ed4
80101be8:	e8 5b e7 ff ff       	call   80100348 <panic>

80101bed <namei>:

struct inode*
namei(char *path)
{
80101bed:	55                   	push   %ebp
80101bee:	89 e5                	mov    %esp,%ebp
80101bf0:	83 ec 18             	sub    $0x18,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80101bf3:	8d 4d ea             	lea    -0x16(%ebp),%ecx
80101bf6:	ba 00 00 00 00       	mov    $0x0,%edx
80101bfb:	8b 45 08             	mov    0x8(%ebp),%eax
80101bfe:	e8 4d fe ff ff       	call   80101a50 <namex>
}
80101c03:	c9                   	leave  
80101c04:	c3                   	ret    

80101c05 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80101c05:	55                   	push   %ebp
80101c06:	89 e5                	mov    %esp,%ebp
80101c08:	83 ec 08             	sub    $0x8,%esp
  return namex(path, 1, name);
80101c0b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80101c0e:	ba 01 00 00 00       	mov    $0x1,%edx
80101c13:	8b 45 08             	mov    0x8(%ebp),%eax
80101c16:	e8 35 fe ff ff       	call   80101a50 <namex>
}
80101c1b:	c9                   	leave  
80101c1c:	c3                   	ret    

80101c1d <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80101c1d:	55                   	push   %ebp
80101c1e:	89 e5                	mov    %esp,%ebp
80101c20:	89 c1                	mov    %eax,%ecx
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101c22:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101c27:	ec                   	in     (%dx),%al
80101c28:	89 c2                	mov    %eax,%edx
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY)
80101c2a:	83 e0 c0             	and    $0xffffffc0,%eax
80101c2d:	3c 40                	cmp    $0x40,%al
80101c2f:	75 f1                	jne    80101c22 <idewait+0x5>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80101c31:	85 c9                	test   %ecx,%ecx
80101c33:	74 0c                	je     80101c41 <idewait+0x24>
80101c35:	f6 c2 21             	test   $0x21,%dl
80101c38:	75 0e                	jne    80101c48 <idewait+0x2b>
    return -1;
  return 0;
80101c3a:	b8 00 00 00 00       	mov    $0x0,%eax
80101c3f:	eb 05                	jmp    80101c46 <idewait+0x29>
80101c41:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101c46:	5d                   	pop    %ebp
80101c47:	c3                   	ret    
    return -1;
80101c48:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101c4d:	eb f7                	jmp    80101c46 <idewait+0x29>

80101c4f <idestart>:
}

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80101c4f:	55                   	push   %ebp
80101c50:	89 e5                	mov    %esp,%ebp
80101c52:	56                   	push   %esi
80101c53:	53                   	push   %ebx
  if(b == 0)
80101c54:	85 c0                	test   %eax,%eax
80101c56:	74 7d                	je     80101cd5 <idestart+0x86>
80101c58:	89 c6                	mov    %eax,%esi
    panic("idestart");
  if(b->blockno >= FSSIZE)
80101c5a:	8b 58 08             	mov    0x8(%eax),%ebx
80101c5d:	81 fb e7 03 00 00    	cmp    $0x3e7,%ebx
80101c63:	77 7d                	ja     80101ce2 <idestart+0x93>
  int read_cmd = (sector_per_block == 1) ? IDE_CMD_READ :  IDE_CMD_RDMUL;
  int write_cmd = (sector_per_block == 1) ? IDE_CMD_WRITE : IDE_CMD_WRMUL;

  if (sector_per_block > 7) panic("idestart");

  idewait(0);
80101c65:	b8 00 00 00 00       	mov    $0x0,%eax
80101c6a:	e8 ae ff ff ff       	call   80101c1d <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101c6f:	b8 00 00 00 00       	mov    $0x0,%eax
80101c74:	ba f6 03 00 00       	mov    $0x3f6,%edx
80101c79:	ee                   	out    %al,(%dx)
80101c7a:	b8 01 00 00 00       	mov    $0x1,%eax
80101c7f:	ba f2 01 00 00       	mov    $0x1f2,%edx
80101c84:	ee                   	out    %al,(%dx)
80101c85:	ba f3 01 00 00       	mov    $0x1f3,%edx
80101c8a:	89 d8                	mov    %ebx,%eax
80101c8c:	ee                   	out    %al,(%dx)
  outb(0x3f6, 0);  // generate interrupt
  outb(0x1f2, sector_per_block);  // number of sectors
  outb(0x1f3, sector & 0xff);
  outb(0x1f4, (sector >> 8) & 0xff);
80101c8d:	89 d8                	mov    %ebx,%eax
80101c8f:	c1 f8 08             	sar    $0x8,%eax
80101c92:	ba f4 01 00 00       	mov    $0x1f4,%edx
80101c97:	ee                   	out    %al,(%dx)
  outb(0x1f5, (sector >> 16) & 0xff);
80101c98:	89 d8                	mov    %ebx,%eax
80101c9a:	c1 f8 10             	sar    $0x10,%eax
80101c9d:	ba f5 01 00 00       	mov    $0x1f5,%edx
80101ca2:	ee                   	out    %al,(%dx)
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80101ca3:	0f b6 46 04          	movzbl 0x4(%esi),%eax
80101ca7:	c1 e0 04             	shl    $0x4,%eax
80101caa:	83 e0 10             	and    $0x10,%eax
80101cad:	c1 fb 18             	sar    $0x18,%ebx
80101cb0:	83 e3 0f             	and    $0xf,%ebx
80101cb3:	09 d8                	or     %ebx,%eax
80101cb5:	83 c8 e0             	or     $0xffffffe0,%eax
80101cb8:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101cbd:	ee                   	out    %al,(%dx)
  if(b->flags & B_DIRTY){
80101cbe:	f6 06 04             	testb  $0x4,(%esi)
80101cc1:	75 2c                	jne    80101cef <idestart+0xa0>
80101cc3:	b8 20 00 00 00       	mov    $0x20,%eax
80101cc8:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101ccd:	ee                   	out    %al,(%dx)
    outb(0x1f7, write_cmd);
    outsl(0x1f0, b->data, BSIZE/4);
  } else {
    outb(0x1f7, read_cmd);
  }
}
80101cce:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101cd1:	5b                   	pop    %ebx
80101cd2:	5e                   	pop    %esi
80101cd3:	5d                   	pop    %ebp
80101cd4:	c3                   	ret    
    panic("idestart");
80101cd5:	83 ec 0c             	sub    $0xc,%esp
80101cd8:	68 2b 69 10 80       	push   $0x8010692b
80101cdd:	e8 66 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101ce2:	83 ec 0c             	sub    $0xc,%esp
80101ce5:	68 34 69 10 80       	push   $0x80106934
80101cea:	e8 59 e6 ff ff       	call   80100348 <panic>
80101cef:	b8 30 00 00 00       	mov    $0x30,%eax
80101cf4:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101cf9:	ee                   	out    %al,(%dx)
    outsl(0x1f0, b->data, BSIZE/4);
80101cfa:	83 c6 5c             	add    $0x5c,%esi
  asm volatile("cld; rep outsl" :
80101cfd:	b9 80 00 00 00       	mov    $0x80,%ecx
80101d02:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101d07:	fc                   	cld    
80101d08:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80101d0a:	eb c2                	jmp    80101cce <idestart+0x7f>

80101d0c <ideinit>:
{
80101d0c:	55                   	push   %ebp
80101d0d:	89 e5                	mov    %esp,%ebp
80101d0f:	83 ec 10             	sub    $0x10,%esp
  initlock(&idelock, "ide");
80101d12:	68 46 69 10 80       	push   $0x80106946
80101d17:	68 80 a5 10 80       	push   $0x8010a580
80101d1c:	e8 eb 1f 00 00       	call   80103d0c <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101d21:	83 c4 08             	add    $0x8,%esp
80101d24:	a1 60 40 13 80       	mov    0x80134060,%eax
80101d29:	83 e8 01             	sub    $0x1,%eax
80101d2c:	50                   	push   %eax
80101d2d:	6a 0e                	push   $0xe
80101d2f:	e8 56 02 00 00       	call   80101f8a <ioapicenable>
  idewait(0);
80101d34:	b8 00 00 00 00       	mov    $0x0,%eax
80101d39:	e8 df fe ff ff       	call   80101c1d <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d3e:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
80101d43:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d48:	ee                   	out    %al,(%dx)
  for(i=0; i<1000; i++){
80101d49:	83 c4 10             	add    $0x10,%esp
80101d4c:	b9 00 00 00 00       	mov    $0x0,%ecx
80101d51:	81 f9 e7 03 00 00    	cmp    $0x3e7,%ecx
80101d57:	7f 19                	jg     80101d72 <ideinit+0x66>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101d59:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101d5e:	ec                   	in     (%dx),%al
    if(inb(0x1f7) != 0){
80101d5f:	84 c0                	test   %al,%al
80101d61:	75 05                	jne    80101d68 <ideinit+0x5c>
  for(i=0; i<1000; i++){
80101d63:	83 c1 01             	add    $0x1,%ecx
80101d66:	eb e9                	jmp    80101d51 <ideinit+0x45>
      havedisk1 = 1;
80101d68:	c7 05 60 a5 10 80 01 	movl   $0x1,0x8010a560
80101d6f:	00 00 00 
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d72:	b8 e0 ff ff ff       	mov    $0xffffffe0,%eax
80101d77:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d7c:	ee                   	out    %al,(%dx)
}
80101d7d:	c9                   	leave  
80101d7e:	c3                   	ret    

80101d7f <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80101d7f:	55                   	push   %ebp
80101d80:	89 e5                	mov    %esp,%ebp
80101d82:	57                   	push   %edi
80101d83:	53                   	push   %ebx
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80101d84:	83 ec 0c             	sub    $0xc,%esp
80101d87:	68 80 a5 10 80       	push   $0x8010a580
80101d8c:	e8 b7 20 00 00       	call   80103e48 <acquire>

  if((b = idequeue) == 0){
80101d91:	8b 1d 64 a5 10 80    	mov    0x8010a564,%ebx
80101d97:	83 c4 10             	add    $0x10,%esp
80101d9a:	85 db                	test   %ebx,%ebx
80101d9c:	74 48                	je     80101de6 <ideintr+0x67>
    release(&idelock);
    return;
  }
  idequeue = b->qnext;
80101d9e:	8b 43 58             	mov    0x58(%ebx),%eax
80101da1:	a3 64 a5 10 80       	mov    %eax,0x8010a564

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101da6:	f6 03 04             	testb  $0x4,(%ebx)
80101da9:	74 4d                	je     80101df8 <ideintr+0x79>
    insl(0x1f0, b->data, BSIZE/4);

  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80101dab:	8b 03                	mov    (%ebx),%eax
80101dad:	83 c8 02             	or     $0x2,%eax
  b->flags &= ~B_DIRTY;
80101db0:	83 e0 fb             	and    $0xfffffffb,%eax
80101db3:	89 03                	mov    %eax,(%ebx)
  wakeup(b);
80101db5:	83 ec 0c             	sub    $0xc,%esp
80101db8:	53                   	push   %ebx
80101db9:	e8 f4 1c 00 00       	call   80103ab2 <wakeup>

  // Start disk on next buf in queue.
  if(idequeue != 0)
80101dbe:	a1 64 a5 10 80       	mov    0x8010a564,%eax
80101dc3:	83 c4 10             	add    $0x10,%esp
80101dc6:	85 c0                	test   %eax,%eax
80101dc8:	74 05                	je     80101dcf <ideintr+0x50>
    idestart(idequeue);
80101dca:	e8 80 fe ff ff       	call   80101c4f <idestart>

  release(&idelock);
80101dcf:	83 ec 0c             	sub    $0xc,%esp
80101dd2:	68 80 a5 10 80       	push   $0x8010a580
80101dd7:	e8 d1 20 00 00       	call   80103ead <release>
80101ddc:	83 c4 10             	add    $0x10,%esp
}
80101ddf:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101de2:	5b                   	pop    %ebx
80101de3:	5f                   	pop    %edi
80101de4:	5d                   	pop    %ebp
80101de5:	c3                   	ret    
    release(&idelock);
80101de6:	83 ec 0c             	sub    $0xc,%esp
80101de9:	68 80 a5 10 80       	push   $0x8010a580
80101dee:	e8 ba 20 00 00       	call   80103ead <release>
    return;
80101df3:	83 c4 10             	add    $0x10,%esp
80101df6:	eb e7                	jmp    80101ddf <ideintr+0x60>
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101df8:	b8 01 00 00 00       	mov    $0x1,%eax
80101dfd:	e8 1b fe ff ff       	call   80101c1d <idewait>
80101e02:	85 c0                	test   %eax,%eax
80101e04:	78 a5                	js     80101dab <ideintr+0x2c>
    insl(0x1f0, b->data, BSIZE/4);
80101e06:	8d 7b 5c             	lea    0x5c(%ebx),%edi
  asm volatile("cld; rep insl" :
80101e09:	b9 80 00 00 00       	mov    $0x80,%ecx
80101e0e:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101e13:	fc                   	cld    
80101e14:	f3 6d                	rep insl (%dx),%es:(%edi)
80101e16:	eb 93                	jmp    80101dab <ideintr+0x2c>

80101e18 <iderw>:
// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80101e18:	55                   	push   %ebp
80101e19:	89 e5                	mov    %esp,%ebp
80101e1b:	53                   	push   %ebx
80101e1c:	83 ec 10             	sub    $0x10,%esp
80101e1f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct buf **pp;

  if(!holdingsleep(&b->lock))
80101e22:	8d 43 0c             	lea    0xc(%ebx),%eax
80101e25:	50                   	push   %eax
80101e26:	e8 93 1e 00 00       	call   80103cbe <holdingsleep>
80101e2b:	83 c4 10             	add    $0x10,%esp
80101e2e:	85 c0                	test   %eax,%eax
80101e30:	74 37                	je     80101e69 <iderw+0x51>
    panic("iderw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80101e32:	8b 03                	mov    (%ebx),%eax
80101e34:	83 e0 06             	and    $0x6,%eax
80101e37:	83 f8 02             	cmp    $0x2,%eax
80101e3a:	74 3a                	je     80101e76 <iderw+0x5e>
    panic("iderw: nothing to do");
  if(b->dev != 0 && !havedisk1)
80101e3c:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80101e40:	74 09                	je     80101e4b <iderw+0x33>
80101e42:	83 3d 60 a5 10 80 00 	cmpl   $0x0,0x8010a560
80101e49:	74 38                	je     80101e83 <iderw+0x6b>
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);  //DOC:acquire-lock
80101e4b:	83 ec 0c             	sub    $0xc,%esp
80101e4e:	68 80 a5 10 80       	push   $0x8010a580
80101e53:	e8 f0 1f 00 00       	call   80103e48 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e58:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e5f:	83 c4 10             	add    $0x10,%esp
80101e62:	ba 64 a5 10 80       	mov    $0x8010a564,%edx
80101e67:	eb 2a                	jmp    80101e93 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e69:	83 ec 0c             	sub    $0xc,%esp
80101e6c:	68 4a 69 10 80       	push   $0x8010694a
80101e71:	e8 d2 e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e76:	83 ec 0c             	sub    $0xc,%esp
80101e79:	68 60 69 10 80       	push   $0x80106960
80101e7e:	e8 c5 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e83:	83 ec 0c             	sub    $0xc,%esp
80101e86:	68 75 69 10 80       	push   $0x80106975
80101e8b:	e8 b8 e4 ff ff       	call   80100348 <panic>
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e90:	8d 50 58             	lea    0x58(%eax),%edx
80101e93:	8b 02                	mov    (%edx),%eax
80101e95:	85 c0                	test   %eax,%eax
80101e97:	75 f7                	jne    80101e90 <iderw+0x78>
    ;
  *pp = b;
80101e99:	89 1a                	mov    %ebx,(%edx)

  // Start disk if necessary.
  if(idequeue == b)
80101e9b:	39 1d 64 a5 10 80    	cmp    %ebx,0x8010a564
80101ea1:	75 1a                	jne    80101ebd <iderw+0xa5>
    idestart(b);
80101ea3:	89 d8                	mov    %ebx,%eax
80101ea5:	e8 a5 fd ff ff       	call   80101c4f <idestart>
80101eaa:	eb 11                	jmp    80101ebd <iderw+0xa5>

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
80101eac:	83 ec 08             	sub    $0x8,%esp
80101eaf:	68 80 a5 10 80       	push   $0x8010a580
80101eb4:	53                   	push   %ebx
80101eb5:	e8 93 1a 00 00       	call   8010394d <sleep>
80101eba:	83 c4 10             	add    $0x10,%esp
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80101ebd:	8b 03                	mov    (%ebx),%eax
80101ebf:	83 e0 06             	and    $0x6,%eax
80101ec2:	83 f8 02             	cmp    $0x2,%eax
80101ec5:	75 e5                	jne    80101eac <iderw+0x94>
  }


  release(&idelock);
80101ec7:	83 ec 0c             	sub    $0xc,%esp
80101eca:	68 80 a5 10 80       	push   $0x8010a580
80101ecf:	e8 d9 1f 00 00       	call   80103ead <release>
}
80101ed4:	83 c4 10             	add    $0x10,%esp
80101ed7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101eda:	c9                   	leave  
80101edb:	c3                   	ret    

80101edc <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80101edc:	55                   	push   %ebp
80101edd:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80101edf:	8b 15 34 26 11 80    	mov    0x80112634,%edx
80101ee5:	89 02                	mov    %eax,(%edx)
  return ioapic->data;
80101ee7:	a1 34 26 11 80       	mov    0x80112634,%eax
80101eec:	8b 40 10             	mov    0x10(%eax),%eax
}
80101eef:	5d                   	pop    %ebp
80101ef0:	c3                   	ret    

80101ef1 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80101ef1:	55                   	push   %ebp
80101ef2:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80101ef4:	8b 0d 34 26 11 80    	mov    0x80112634,%ecx
80101efa:	89 01                	mov    %eax,(%ecx)
  ioapic->data = data;
80101efc:	a1 34 26 11 80       	mov    0x80112634,%eax
80101f01:	89 50 10             	mov    %edx,0x10(%eax)
}
80101f04:	5d                   	pop    %ebp
80101f05:	c3                   	ret    

80101f06 <ioapicinit>:

void
ioapicinit(void)
{
80101f06:	55                   	push   %ebp
80101f07:	89 e5                	mov    %esp,%ebp
80101f09:	57                   	push   %edi
80101f0a:	56                   	push   %esi
80101f0b:	53                   	push   %ebx
80101f0c:	83 ec 0c             	sub    $0xc,%esp
  int i, id, maxintr;

  ioapic = (volatile struct ioapic*)IOAPIC;
80101f0f:	c7 05 34 26 11 80 00 	movl   $0xfec00000,0x80112634
80101f16:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80101f19:	b8 01 00 00 00       	mov    $0x1,%eax
80101f1e:	e8 b9 ff ff ff       	call   80101edc <ioapicread>
80101f23:	c1 e8 10             	shr    $0x10,%eax
80101f26:	0f b6 f8             	movzbl %al,%edi
  id = ioapicread(REG_ID) >> 24;
80101f29:	b8 00 00 00 00       	mov    $0x0,%eax
80101f2e:	e8 a9 ff ff ff       	call   80101edc <ioapicread>
80101f33:	c1 e8 18             	shr    $0x18,%eax
  if(id != ioapicid)
80101f36:	0f b6 15 c0 3a 13 80 	movzbl 0x80133ac0,%edx
80101f3d:	39 c2                	cmp    %eax,%edx
80101f3f:	75 07                	jne    80101f48 <ioapicinit+0x42>
{
80101f41:	bb 00 00 00 00       	mov    $0x0,%ebx
80101f46:	eb 36                	jmp    80101f7e <ioapicinit+0x78>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80101f48:	83 ec 0c             	sub    $0xc,%esp
80101f4b:	68 94 69 10 80       	push   $0x80106994
80101f50:	e8 b6 e6 ff ff       	call   8010060b <cprintf>
80101f55:	83 c4 10             	add    $0x10,%esp
80101f58:	eb e7                	jmp    80101f41 <ioapicinit+0x3b>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80101f5a:	8d 53 20             	lea    0x20(%ebx),%edx
80101f5d:	81 ca 00 00 01 00    	or     $0x10000,%edx
80101f63:	8d 74 1b 10          	lea    0x10(%ebx,%ebx,1),%esi
80101f67:	89 f0                	mov    %esi,%eax
80101f69:	e8 83 ff ff ff       	call   80101ef1 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80101f6e:	8d 46 01             	lea    0x1(%esi),%eax
80101f71:	ba 00 00 00 00       	mov    $0x0,%edx
80101f76:	e8 76 ff ff ff       	call   80101ef1 <ioapicwrite>
  for(i = 0; i <= maxintr; i++){
80101f7b:	83 c3 01             	add    $0x1,%ebx
80101f7e:	39 fb                	cmp    %edi,%ebx
80101f80:	7e d8                	jle    80101f5a <ioapicinit+0x54>
  }
}
80101f82:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101f85:	5b                   	pop    %ebx
80101f86:	5e                   	pop    %esi
80101f87:	5f                   	pop    %edi
80101f88:	5d                   	pop    %ebp
80101f89:	c3                   	ret    

80101f8a <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80101f8a:	55                   	push   %ebp
80101f8b:	89 e5                	mov    %esp,%ebp
80101f8d:	53                   	push   %ebx
80101f8e:	8b 45 08             	mov    0x8(%ebp),%eax
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80101f91:	8d 50 20             	lea    0x20(%eax),%edx
80101f94:	8d 5c 00 10          	lea    0x10(%eax,%eax,1),%ebx
80101f98:	89 d8                	mov    %ebx,%eax
80101f9a:	e8 52 ff ff ff       	call   80101ef1 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80101f9f:	8b 55 0c             	mov    0xc(%ebp),%edx
80101fa2:	c1 e2 18             	shl    $0x18,%edx
80101fa5:	8d 43 01             	lea    0x1(%ebx),%eax
80101fa8:	e8 44 ff ff ff       	call   80101ef1 <ioapicwrite>
}
80101fad:	5b                   	pop    %ebx
80101fae:	5d                   	pop    %ebp
80101faf:	c3                   	ret    

80101fb0 <set>:
} kmem;

struct frameInfo framelist[17000];

static void
set(struct run *framenum, int pid) {
80101fb0:	55                   	push   %ebp
80101fb1:	89 e5                	mov    %esp,%ebp
    for (int i = 0; i < 17000; i++) {
80101fb3:	b9 00 00 00 00       	mov    $0x0,%ecx
80101fb8:	81 f9 67 42 00 00    	cmp    $0x4267,%ecx
80101fbe:	7f 15                	jg     80101fd5 <set+0x25>
        if (framelist[i].frameNum == framenum) {
80101fc0:	39 04 cd 84 26 11 80 	cmp    %eax,-0x7feed97c(,%ecx,8)
80101fc7:	74 05                	je     80101fce <set+0x1e>
    for (int i = 0; i < 17000; i++) {
80101fc9:	83 c1 01             	add    $0x1,%ecx
80101fcc:	eb ea                	jmp    80101fb8 <set+0x8>
            framelist[i].pid = pid;
80101fce:	89 14 cd 80 26 11 80 	mov    %edx,-0x7feed980(,%ecx,8)
            break;
        }
    }
}
80101fd5:	5d                   	pop    %ebp
80101fd6:	c3                   	ret    

80101fd7 <nextfree>:

static struct run *
nextfree(int pid) {
80101fd7:	55                   	push   %ebp
80101fd8:	89 e5                	mov    %esp,%ebp
    if (framelist[0].pid == 0 && (framelist[1].pid == 0 || framelist[1].pid == pid)) {
80101fda:	83 3d 80 26 11 80 00 	cmpl   $0x0,0x80112680
80101fe1:	0f 85 8f 00 00 00    	jne    80102076 <nextfree+0x9f>
80101fe7:	8b 15 88 26 11 80    	mov    0x80112688,%edx
80101fed:	85 d2                	test   %edx,%edx
80101fef:	74 0b                	je     80101ffc <nextfree+0x25>
80101ff1:	39 c2                	cmp    %eax,%edx
80101ff3:	74 07                	je     80101ffc <nextfree+0x25>
80101ff5:	ba 01 00 00 00       	mov    $0x1,%edx
80101ffa:	eb 33                	jmp    8010202f <nextfree+0x58>
        framelist[0].pid = pid;
80101ffc:	a3 80 26 11 80       	mov    %eax,0x80112680
        return framelist[0].frameNum;
80102001:	a1 84 26 11 80       	mov    0x80112684,%eax
80102006:	eb 6c                	jmp    80102074 <nextfree+0x9d>
    }
    for (int i = 1; i < 17000; i++) {
        if (pid == -2 && !framelist[i].pid) {
80102008:	83 3c d5 80 26 11 80 	cmpl   $0x0,-0x7feed980(,%edx,8)
8010200f:	00 
80102010:	75 2a                	jne    8010203c <nextfree+0x65>
            framelist[i].pid = pid;
80102012:	89 04 d5 80 26 11 80 	mov    %eax,-0x7feed980(,%edx,8)
            return framelist[i].frameNum;
80102019:	8b 04 d5 84 26 11 80 	mov    -0x7feed97c(,%edx,8),%eax
80102020:	eb 52                	jmp    80102074 <nextfree+0x9d>
        }
        else if ((framelist[i - 1].pid == pid || framelist[i - 1].pid == 0 || framelist[i - 1].pid == -2)
            && (framelist[i + 1].pid == pid || framelist[i + 1].pid == 0 || framelist[i + 1].pid == -2)
            && !framelist[i].pid) {
80102022:	83 3c d5 80 26 11 80 	cmpl   $0x0,-0x7feed980(,%edx,8)
80102029:	00 
8010202a:	74 3a                	je     80102066 <nextfree+0x8f>
    for (int i = 1; i < 17000; i++) {
8010202c:	83 c2 01             	add    $0x1,%edx
8010202f:	81 fa 67 42 00 00    	cmp    $0x4267,%edx
80102035:	7f 46                	jg     8010207d <nextfree+0xa6>
        if (pid == -2 && !framelist[i].pid) {
80102037:	83 f8 fe             	cmp    $0xfffffffe,%eax
8010203a:	74 cc                	je     80102008 <nextfree+0x31>
        else if ((framelist[i - 1].pid == pid || framelist[i - 1].pid == 0 || framelist[i - 1].pid == -2)
8010203c:	8b 0c d5 78 26 11 80 	mov    -0x7feed988(,%edx,8),%ecx
80102043:	39 c1                	cmp    %eax,%ecx
80102045:	74 09                	je     80102050 <nextfree+0x79>
80102047:	85 c9                	test   %ecx,%ecx
80102049:	74 05                	je     80102050 <nextfree+0x79>
8010204b:	83 f9 fe             	cmp    $0xfffffffe,%ecx
8010204e:	75 dc                	jne    8010202c <nextfree+0x55>
            && (framelist[i + 1].pid == pid || framelist[i + 1].pid == 0 || framelist[i + 1].pid == -2)
80102050:	8b 0c d5 88 26 11 80 	mov    -0x7feed978(,%edx,8),%ecx
80102057:	39 c1                	cmp    %eax,%ecx
80102059:	74 c7                	je     80102022 <nextfree+0x4b>
8010205b:	85 c9                	test   %ecx,%ecx
8010205d:	74 c3                	je     80102022 <nextfree+0x4b>
8010205f:	83 f9 fe             	cmp    $0xfffffffe,%ecx
80102062:	75 c8                	jne    8010202c <nextfree+0x55>
80102064:	eb bc                	jmp    80102022 <nextfree+0x4b>
            framelist[i].pid = pid;
80102066:	89 04 d5 80 26 11 80 	mov    %eax,-0x7feed980(,%edx,8)
            return framelist[i].frameNum;
8010206d:	8b 04 d5 84 26 11 80 	mov    -0x7feed97c(,%edx,8),%eax
        }
    }
    return 0;
}
80102074:	5d                   	pop    %ebp
80102075:	c3                   	ret    
80102076:	ba 01 00 00 00       	mov    $0x1,%edx
8010207b:	eb b2                	jmp    8010202f <nextfree+0x58>
    return 0;
8010207d:	b8 00 00 00 00       	mov    $0x0,%eax
80102082:	eb f0                	jmp    80102074 <nextfree+0x9d>

80102084 <kfree>:

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(char *v) {
80102084:	55                   	push   %ebp
80102085:	89 e5                	mov    %esp,%ebp
80102087:	53                   	push   %ebx
80102088:	83 ec 04             	sub    $0x4,%esp
8010208b:	8b 5d 08             	mov    0x8(%ebp),%ebx

    if ((uint) v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
8010208e:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80102094:	75 4b                	jne    801020e1 <kfree+0x5d>
80102096:	81 fb 08 68 13 80    	cmp    $0x80136808,%ebx
8010209c:	72 43                	jb     801020e1 <kfree+0x5d>
8010209e:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801020a4:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
801020a9:	77 36                	ja     801020e1 <kfree+0x5d>
        panic("kfree");

    // Fill with junk to catch dangling refs.
    memset(v, 1, PGSIZE);
801020ab:	83 ec 04             	sub    $0x4,%esp
801020ae:	68 00 10 00 00       	push   $0x1000
801020b3:	6a 01                	push   $0x1
801020b5:	53                   	push   %ebx
801020b6:	e8 39 1e 00 00       	call   80103ef4 <memset>

    if (kmem.use_lock)
801020bb:	83 c4 10             	add    $0x10,%esp
801020be:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801020c5:	75 27                	jne    801020ee <kfree+0x6a>
        acquire(&kmem.lock);

    set((struct run *) v, 0);
801020c7:	ba 00 00 00 00       	mov    $0x0,%edx
801020cc:	89 d8                	mov    %ebx,%eax
801020ce:	e8 dd fe ff ff       	call   80101fb0 <set>
    if (kmem.use_lock)
801020d3:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801020da:	75 24                	jne    80102100 <kfree+0x7c>
        release(&kmem.lock);
}
801020dc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801020df:	c9                   	leave  
801020e0:	c3                   	ret    
        panic("kfree");
801020e1:	83 ec 0c             	sub    $0xc,%esp
801020e4:	68 c6 69 10 80       	push   $0x801069c6
801020e9:	e8 5a e2 ff ff       	call   80100348 <panic>
        acquire(&kmem.lock);
801020ee:	83 ec 0c             	sub    $0xc,%esp
801020f1:	68 40 26 11 80       	push   $0x80112640
801020f6:	e8 4d 1d 00 00       	call   80103e48 <acquire>
801020fb:	83 c4 10             	add    $0x10,%esp
801020fe:	eb c7                	jmp    801020c7 <kfree+0x43>
        release(&kmem.lock);
80102100:	83 ec 0c             	sub    $0xc,%esp
80102103:	68 40 26 11 80       	push   $0x80112640
80102108:	e8 a0 1d 00 00       	call   80103ead <release>
8010210d:	83 c4 10             	add    $0x10,%esp
}
80102110:	eb ca                	jmp    801020dc <kfree+0x58>

80102112 <initialize>:

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void initialize(char *v) {
80102112:	55                   	push   %ebp
80102113:	89 e5                	mov    %esp,%ebp
80102115:	53                   	push   %ebx
80102116:	83 ec 04             	sub    $0x4,%esp
80102119:	8b 5d 08             	mov    0x8(%ebp),%ebx
    struct run *r;

    if ((uint) v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
8010211c:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80102122:	75 4c                	jne    80102170 <initialize+0x5e>
80102124:	81 fb 08 68 13 80    	cmp    $0x80136808,%ebx
8010212a:	72 44                	jb     80102170 <initialize+0x5e>
8010212c:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80102132:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102137:	77 37                	ja     80102170 <initialize+0x5e>
        panic("kfree");

    // Fill with junk to catch dangling refs.
    memset(v, 1, PGSIZE);
80102139:	83 ec 04             	sub    $0x4,%esp
8010213c:	68 00 10 00 00       	push   $0x1000
80102141:	6a 01                	push   $0x1
80102143:	53                   	push   %ebx
80102144:	e8 ab 1d 00 00       	call   80103ef4 <memset>

    if (kmem.use_lock)
80102149:	83 c4 10             	add    $0x10,%esp
8010214c:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80102153:	75 28                	jne    8010217d <initialize+0x6b>
        acquire(&kmem.lock);
    r = (struct run *) v;
    r->next = kmem.freelist;
80102155:	a1 78 26 11 80       	mov    0x80112678,%eax
8010215a:	89 03                	mov    %eax,(%ebx)
    kmem.freelist = r;
8010215c:	89 1d 78 26 11 80    	mov    %ebx,0x80112678
    if (kmem.use_lock)
80102162:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80102169:	75 24                	jne    8010218f <initialize+0x7d>
        release(&kmem.lock);
}
8010216b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010216e:	c9                   	leave  
8010216f:	c3                   	ret    
        panic("kfree");
80102170:	83 ec 0c             	sub    $0xc,%esp
80102173:	68 c6 69 10 80       	push   $0x801069c6
80102178:	e8 cb e1 ff ff       	call   80100348 <panic>
        acquire(&kmem.lock);
8010217d:	83 ec 0c             	sub    $0xc,%esp
80102180:	68 40 26 11 80       	push   $0x80112640
80102185:	e8 be 1c 00 00       	call   80103e48 <acquire>
8010218a:	83 c4 10             	add    $0x10,%esp
8010218d:	eb c6                	jmp    80102155 <initialize+0x43>
        release(&kmem.lock);
8010218f:	83 ec 0c             	sub    $0xc,%esp
80102192:	68 40 26 11 80       	push   $0x80112640
80102197:	e8 11 1d 00 00       	call   80103ead <release>
8010219c:	83 c4 10             	add    $0x10,%esp
}
8010219f:	eb ca                	jmp    8010216b <initialize+0x59>

801021a1 <freerange>:
void freerange(void *vstart, void *vend) {
801021a1:	55                   	push   %ebp
801021a2:	89 e5                	mov    %esp,%ebp
801021a4:	56                   	push   %esi
801021a5:	53                   	push   %ebx
801021a6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
    p = (char *) PGROUNDUP((uint) vstart);
801021a9:	8b 45 08             	mov    0x8(%ebp),%eax
801021ac:	05 ff 0f 00 00       	add    $0xfff,%eax
801021b1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    for (; p + PGSIZE <= (char *) vend; p += PGSIZE) {
801021b6:	eb 0e                	jmp    801021c6 <freerange+0x25>
        initialize(p);
801021b8:	83 ec 0c             	sub    $0xc,%esp
801021bb:	50                   	push   %eax
801021bc:	e8 51 ff ff ff       	call   80102112 <initialize>
    for (; p + PGSIZE <= (char *) vend; p += PGSIZE) {
801021c1:	83 c4 10             	add    $0x10,%esp
801021c4:	89 f0                	mov    %esi,%eax
801021c6:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
801021cc:	39 de                	cmp    %ebx,%esi
801021ce:	76 e8                	jbe    801021b8 <freerange+0x17>
}
801021d0:	8d 65 f8             	lea    -0x8(%ebp),%esp
801021d3:	5b                   	pop    %ebx
801021d4:	5e                   	pop    %esi
801021d5:	5d                   	pop    %ebp
801021d6:	c3                   	ret    

801021d7 <kinit1>:
void kinit1(void *vstart, void *vend) {
801021d7:	55                   	push   %ebp
801021d8:	89 e5                	mov    %esp,%ebp
801021da:	83 ec 10             	sub    $0x10,%esp
    initlock(&kmem.lock, "kmem");
801021dd:	68 cc 69 10 80       	push   $0x801069cc
801021e2:	68 40 26 11 80       	push   $0x80112640
801021e7:	e8 20 1b 00 00       	call   80103d0c <initlock>
    kmem.use_lock = 0;
801021ec:	c7 05 74 26 11 80 00 	movl   $0x0,0x80112674
801021f3:	00 00 00 
    freerange(vstart, vend);
801021f6:	83 c4 08             	add    $0x8,%esp
801021f9:	ff 75 0c             	pushl  0xc(%ebp)
801021fc:	ff 75 08             	pushl  0x8(%ebp)
801021ff:	e8 9d ff ff ff       	call   801021a1 <freerange>
}
80102204:	83 c4 10             	add    $0x10,%esp
80102207:	c9                   	leave  
80102208:	c3                   	ret    

80102209 <kinit2>:
void kinit2(void *vstart, void *vend) {
80102209:	55                   	push   %ebp
8010220a:	89 e5                	mov    %esp,%ebp
8010220c:	83 ec 10             	sub    $0x10,%esp
    freerange(vstart, vend);
8010220f:	ff 75 0c             	pushl  0xc(%ebp)
80102212:	ff 75 08             	pushl  0x8(%ebp)
80102215:	e8 87 ff ff ff       	call   801021a1 <freerange>
    struct run *temp = kmem.freelist;
8010221a:	8b 15 78 26 11 80    	mov    0x80112678,%edx
    for (int i = 0; i < 17000; i++) {
80102220:	83 c4 10             	add    $0x10,%esp
80102223:	b8 00 00 00 00       	mov    $0x0,%eax
80102228:	eb 17                	jmp    80102241 <kinit2+0x38>
        framelist[i].frameNum = temp;
8010222a:	89 14 c5 84 26 11 80 	mov    %edx,-0x7feed97c(,%eax,8)
        framelist[i].pid = 0;
80102231:	c7 04 c5 80 26 11 80 	movl   $0x0,-0x7feed980(,%eax,8)
80102238:	00 00 00 00 
        temp = temp->next;
8010223c:	8b 12                	mov    (%edx),%edx
    for (int i = 0; i < 17000; i++) {
8010223e:	83 c0 01             	add    $0x1,%eax
80102241:	3d 67 42 00 00       	cmp    $0x4267,%eax
80102246:	7e e2                	jle    8010222a <kinit2+0x21>
    kmem.use_lock = 1;
80102248:	c7 05 74 26 11 80 01 	movl   $0x1,0x80112674
8010224f:	00 00 00 
}
80102252:	c9                   	leave  
80102253:	c3                   	ret    

80102254 <kalloc>:

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char *
kalloc(void) {
80102254:	55                   	push   %ebp
80102255:	89 e5                	mov    %esp,%ebp
80102257:	53                   	push   %ebx
80102258:	83 ec 04             	sub    $0x4,%esp
    struct run *r;

    if (kmem.use_lock)
8010225b:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80102262:	75 2a                	jne    8010228e <kalloc+0x3a>
        acquire(&kmem.lock);
    if (!kmem.use_lock){
80102264:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
8010226b:	75 33                	jne    801022a0 <kalloc+0x4c>
        r = kmem.freelist;
8010226d:	8b 1d 78 26 11 80    	mov    0x80112678,%ebx
        if (r) {
80102273:	85 db                	test   %ebx,%ebx
80102275:	74 07                	je     8010227e <kalloc+0x2a>
            kmem.freelist = r->next;
80102277:	8b 03                	mov    (%ebx),%eax
80102279:	a3 78 26 11 80       	mov    %eax,0x80112678
        }
    }
    else r = nextfree(-2);
    if (kmem.use_lock)
8010227e:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80102285:	75 27                	jne    801022ae <kalloc+0x5a>
        release(&kmem.lock);
    return (char *) r;
}
80102287:	89 d8                	mov    %ebx,%eax
80102289:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010228c:	c9                   	leave  
8010228d:	c3                   	ret    
        acquire(&kmem.lock);
8010228e:	83 ec 0c             	sub    $0xc,%esp
80102291:	68 40 26 11 80       	push   $0x80112640
80102296:	e8 ad 1b 00 00       	call   80103e48 <acquire>
8010229b:	83 c4 10             	add    $0x10,%esp
8010229e:	eb c4                	jmp    80102264 <kalloc+0x10>
    else r = nextfree(-2);
801022a0:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
801022a5:	e8 2d fd ff ff       	call   80101fd7 <nextfree>
801022aa:	89 c3                	mov    %eax,%ebx
801022ac:	eb d0                	jmp    8010227e <kalloc+0x2a>
        release(&kmem.lock);
801022ae:	83 ec 0c             	sub    $0xc,%esp
801022b1:	68 40 26 11 80       	push   $0x80112640
801022b6:	e8 f2 1b 00 00       	call   80103ead <release>
801022bb:	83 c4 10             	add    $0x10,%esp
    return (char *) r;
801022be:	eb c7                	jmp    80102287 <kalloc+0x33>

801022c0 <kalloc2>:

char *
kalloc2(int pid) {
801022c0:	55                   	push   %ebp
801022c1:	89 e5                	mov    %esp,%ebp
801022c3:	53                   	push   %ebx
801022c4:	83 ec 04             	sub    $0x4,%esp
    struct run *r;

    if (kmem.use_lock)
801022c7:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801022ce:	75 2a                	jne    801022fa <kalloc2+0x3a>
        acquire(&kmem.lock);
    if (!kmem.use_lock){
801022d0:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801022d7:	75 33                	jne    8010230c <kalloc2+0x4c>
        r = kmem.freelist;
801022d9:	8b 1d 78 26 11 80    	mov    0x80112678,%ebx
        if (r) {
801022df:	85 db                	test   %ebx,%ebx
801022e1:	74 07                	je     801022ea <kalloc2+0x2a>
            kmem.freelist = r->next;
801022e3:	8b 03                	mov    (%ebx),%eax
801022e5:	a3 78 26 11 80       	mov    %eax,0x80112678
        }
    }
    else r = nextfree(pid);
    if (kmem.use_lock)
801022ea:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801022f1:	75 25                	jne    80102318 <kalloc2+0x58>
        release(&kmem.lock);
    return (char *) r;
}
801022f3:	89 d8                	mov    %ebx,%eax
801022f5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801022f8:	c9                   	leave  
801022f9:	c3                   	ret    
        acquire(&kmem.lock);
801022fa:	83 ec 0c             	sub    $0xc,%esp
801022fd:	68 40 26 11 80       	push   $0x80112640
80102302:	e8 41 1b 00 00       	call   80103e48 <acquire>
80102307:	83 c4 10             	add    $0x10,%esp
8010230a:	eb c4                	jmp    801022d0 <kalloc2+0x10>
    else r = nextfree(pid);
8010230c:	8b 45 08             	mov    0x8(%ebp),%eax
8010230f:	e8 c3 fc ff ff       	call   80101fd7 <nextfree>
80102314:	89 c3                	mov    %eax,%ebx
80102316:	eb d2                	jmp    801022ea <kalloc2+0x2a>
        release(&kmem.lock);
80102318:	83 ec 0c             	sub    $0xc,%esp
8010231b:	68 40 26 11 80       	push   $0x80112640
80102320:	e8 88 1b 00 00       	call   80103ead <release>
80102325:	83 c4 10             	add    $0x10,%esp
    return (char *) r;
80102328:	eb c9                	jmp    801022f3 <kalloc2+0x33>

8010232a <dump_physmem>:
int
dump_physmem(int *frs, int *pds, int numframes)
{
8010232a:	55                   	push   %ebp
8010232b:	89 e5                	mov    %esp,%ebp
8010232d:	57                   	push   %edi
8010232e:	56                   	push   %esi
8010232f:	53                   	push   %ebx
80102330:	8b 7d 08             	mov    0x8(%ebp),%edi
80102333:	8b 5d 10             	mov    0x10(%ebp),%ebx
    if(numframes <= 0 || frs == 0 || pds == 0) {
80102336:	85 db                	test   %ebx,%ebx
80102338:	0f 9e c2             	setle  %dl
8010233b:	85 ff                	test   %edi,%edi
8010233d:	0f 94 c0             	sete   %al
80102340:	08 c2                	or     %al,%dl
80102342:	75 5b                	jne    8010239f <dump_physmem+0x75>
80102344:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102348:	74 5c                	je     801023a6 <dump_physmem+0x7c>
    // if (kmem.use_lock){
    //     acquire(&kmem.lock);
    // }

    int c = 0; // keep track of frame number and pid
    int i = 0; // keep track of current index
8010234a:	ba 00 00 00 00       	mov    $0x0,%edx
    int c = 0; // keep track of frame number and pid
8010234f:	b9 00 00 00 00       	mov    $0x0,%ecx
80102354:	eb 03                	jmp    80102359 <dump_physmem+0x2f>
        framenumber = (uint) (V2P(framelist[i].frameNum) >> 12);
        if (framelist[i].pid != 0) {
            frs[c] = framenumber;
            pds[c++] = framelist[i].pid;
        }
        i++;
80102356:	83 c2 01             	add    $0x1,%edx
    while(c < numframes){
80102359:	39 d9                	cmp    %ebx,%ecx
8010235b:	7d 38                	jge    80102395 <dump_physmem+0x6b>
        framenumber = (uint) (V2P(framelist[i].frameNum) >> 12);
8010235d:	8b 04 d5 84 26 11 80 	mov    -0x7feed97c(,%edx,8),%eax
80102364:	05 00 00 00 80       	add    $0x80000000,%eax
80102369:	c1 e8 0c             	shr    $0xc,%eax
        if (framelist[i].pid != 0) {
8010236c:	83 3c d5 80 26 11 80 	cmpl   $0x0,-0x7feed980(,%edx,8)
80102373:	00 
80102374:	74 e0                	je     80102356 <dump_physmem+0x2c>
            frs[c] = framenumber;
80102376:	8d 34 8d 00 00 00 00 	lea    0x0(,%ecx,4),%esi
8010237d:	8b 7d 08             	mov    0x8(%ebp),%edi
80102380:	89 04 37             	mov    %eax,(%edi,%esi,1)
            pds[c++] = framelist[i].pid;
80102383:	83 c1 01             	add    $0x1,%ecx
80102386:	8b 04 d5 80 26 11 80 	mov    -0x7feed980(,%edx,8),%eax
8010238d:	8b 7d 0c             	mov    0xc(%ebp),%edi
80102390:	89 04 37             	mov    %eax,(%edi,%esi,1)
80102393:	eb c1                	jmp    80102356 <dump_physmem+0x2c>

    // if (kmem.use_lock) {
    //     release(&kmem.lock);

    // }
  return 0;
80102395:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010239a:	5b                   	pop    %ebx
8010239b:	5e                   	pop    %esi
8010239c:	5f                   	pop    %edi
8010239d:	5d                   	pop    %ebp
8010239e:	c3                   	ret    
        return -1;
8010239f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801023a4:	eb f4                	jmp    8010239a <dump_physmem+0x70>
801023a6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801023ab:	eb ed                	jmp    8010239a <dump_physmem+0x70>

801023ad <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
801023ad:	55                   	push   %ebp
801023ae:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801023b0:	ba 64 00 00 00       	mov    $0x64,%edx
801023b5:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
801023b6:	a8 01                	test   $0x1,%al
801023b8:	0f 84 b5 00 00 00    	je     80102473 <kbdgetc+0xc6>
801023be:	ba 60 00 00 00       	mov    $0x60,%edx
801023c3:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
801023c4:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
801023c7:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
801023cd:	74 5c                	je     8010242b <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
801023cf:	84 c0                	test   %al,%al
801023d1:	78 66                	js     80102439 <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
801023d3:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
801023d9:	f6 c1 40             	test   $0x40,%cl
801023dc:	74 0f                	je     801023ed <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
801023de:	83 c8 80             	or     $0xffffff80,%eax
801023e1:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
801023e4:	83 e1 bf             	and    $0xffffffbf,%ecx
801023e7:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  }

  shift |= shiftcode[data];
801023ed:	0f b6 8a 00 6b 10 80 	movzbl -0x7fef9500(%edx),%ecx
801023f4:	0b 0d b4 a5 10 80    	or     0x8010a5b4,%ecx
  shift ^= togglecode[data];
801023fa:	0f b6 82 00 6a 10 80 	movzbl -0x7fef9600(%edx),%eax
80102401:	31 c1                	xor    %eax,%ecx
80102403:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  c = charcode[shift & (CTL | SHIFT)][data];
80102409:	89 c8                	mov    %ecx,%eax
8010240b:	83 e0 03             	and    $0x3,%eax
8010240e:	8b 04 85 e0 69 10 80 	mov    -0x7fef9620(,%eax,4),%eax
80102415:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
80102419:	f6 c1 08             	test   $0x8,%cl
8010241c:	74 19                	je     80102437 <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
8010241e:	8d 50 9f             	lea    -0x61(%eax),%edx
80102421:	83 fa 19             	cmp    $0x19,%edx
80102424:	77 40                	ja     80102466 <kbdgetc+0xb9>
      c += 'A' - 'a';
80102426:	83 e8 20             	sub    $0x20,%eax
80102429:	eb 0c                	jmp    80102437 <kbdgetc+0x8a>
    shift |= E0ESC;
8010242b:	83 0d b4 a5 10 80 40 	orl    $0x40,0x8010a5b4
    return 0;
80102432:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
80102437:	5d                   	pop    %ebp
80102438:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
80102439:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
8010243f:	f6 c1 40             	test   $0x40,%cl
80102442:	75 05                	jne    80102449 <kbdgetc+0x9c>
80102444:	89 c2                	mov    %eax,%edx
80102446:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
80102449:	0f b6 82 00 6b 10 80 	movzbl -0x7fef9500(%edx),%eax
80102450:	83 c8 40             	or     $0x40,%eax
80102453:	0f b6 c0             	movzbl %al,%eax
80102456:	f7 d0                	not    %eax
80102458:	21 c8                	and    %ecx,%eax
8010245a:	a3 b4 a5 10 80       	mov    %eax,0x8010a5b4
    return 0;
8010245f:	b8 00 00 00 00       	mov    $0x0,%eax
80102464:	eb d1                	jmp    80102437 <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
80102466:	8d 50 bf             	lea    -0x41(%eax),%edx
80102469:	83 fa 19             	cmp    $0x19,%edx
8010246c:	77 c9                	ja     80102437 <kbdgetc+0x8a>
      c += 'a' - 'A';
8010246e:	83 c0 20             	add    $0x20,%eax
  return c;
80102471:	eb c4                	jmp    80102437 <kbdgetc+0x8a>
    return -1;
80102473:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102478:	eb bd                	jmp    80102437 <kbdgetc+0x8a>

8010247a <kbdintr>:

void
kbdintr(void)
{
8010247a:	55                   	push   %ebp
8010247b:	89 e5                	mov    %esp,%ebp
8010247d:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
80102480:	68 ad 23 10 80       	push   $0x801023ad
80102485:	e8 b4 e2 ff ff       	call   8010073e <consoleintr>
}
8010248a:	83 c4 10             	add    $0x10,%esp
8010248d:	c9                   	leave  
8010248e:	c3                   	ret    

8010248f <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
8010248f:	55                   	push   %ebp
80102490:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102492:	8b 0d c0 39 13 80    	mov    0x801339c0,%ecx
80102498:	8d 04 81             	lea    (%ecx,%eax,4),%eax
8010249b:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
8010249d:	a1 c0 39 13 80       	mov    0x801339c0,%eax
801024a2:	8b 40 20             	mov    0x20(%eax),%eax
}
801024a5:	5d                   	pop    %ebp
801024a6:	c3                   	ret    

801024a7 <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
801024a7:	55                   	push   %ebp
801024a8:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801024aa:	ba 70 00 00 00       	mov    $0x70,%edx
801024af:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801024b0:	ba 71 00 00 00       	mov    $0x71,%edx
801024b5:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
801024b6:	0f b6 c0             	movzbl %al,%eax
}
801024b9:	5d                   	pop    %ebp
801024ba:	c3                   	ret    

801024bb <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
801024bb:	55                   	push   %ebp
801024bc:	89 e5                	mov    %esp,%ebp
801024be:	53                   	push   %ebx
801024bf:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
801024c1:	b8 00 00 00 00       	mov    $0x0,%eax
801024c6:	e8 dc ff ff ff       	call   801024a7 <cmos_read>
801024cb:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
801024cd:	b8 02 00 00 00       	mov    $0x2,%eax
801024d2:	e8 d0 ff ff ff       	call   801024a7 <cmos_read>
801024d7:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
801024da:	b8 04 00 00 00       	mov    $0x4,%eax
801024df:	e8 c3 ff ff ff       	call   801024a7 <cmos_read>
801024e4:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
801024e7:	b8 07 00 00 00       	mov    $0x7,%eax
801024ec:	e8 b6 ff ff ff       	call   801024a7 <cmos_read>
801024f1:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
801024f4:	b8 08 00 00 00       	mov    $0x8,%eax
801024f9:	e8 a9 ff ff ff       	call   801024a7 <cmos_read>
801024fe:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
80102501:	b8 09 00 00 00       	mov    $0x9,%eax
80102506:	e8 9c ff ff ff       	call   801024a7 <cmos_read>
8010250b:	89 43 14             	mov    %eax,0x14(%ebx)
}
8010250e:	5b                   	pop    %ebx
8010250f:	5d                   	pop    %ebp
80102510:	c3                   	ret    

80102511 <lapicinit>:
  if(!lapic)
80102511:	83 3d c0 39 13 80 00 	cmpl   $0x0,0x801339c0
80102518:	0f 84 fb 00 00 00    	je     80102619 <lapicinit+0x108>
{
8010251e:	55                   	push   %ebp
8010251f:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102521:	ba 3f 01 00 00       	mov    $0x13f,%edx
80102526:	b8 3c 00 00 00       	mov    $0x3c,%eax
8010252b:	e8 5f ff ff ff       	call   8010248f <lapicw>
  lapicw(TDCR, X1);
80102530:	ba 0b 00 00 00       	mov    $0xb,%edx
80102535:	b8 f8 00 00 00       	mov    $0xf8,%eax
8010253a:	e8 50 ff ff ff       	call   8010248f <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
8010253f:	ba 20 00 02 00       	mov    $0x20020,%edx
80102544:	b8 c8 00 00 00       	mov    $0xc8,%eax
80102549:	e8 41 ff ff ff       	call   8010248f <lapicw>
  lapicw(TICR, 10000000);
8010254e:	ba 80 96 98 00       	mov    $0x989680,%edx
80102553:	b8 e0 00 00 00       	mov    $0xe0,%eax
80102558:	e8 32 ff ff ff       	call   8010248f <lapicw>
  lapicw(LINT0, MASKED);
8010255d:	ba 00 00 01 00       	mov    $0x10000,%edx
80102562:	b8 d4 00 00 00       	mov    $0xd4,%eax
80102567:	e8 23 ff ff ff       	call   8010248f <lapicw>
  lapicw(LINT1, MASKED);
8010256c:	ba 00 00 01 00       	mov    $0x10000,%edx
80102571:	b8 d8 00 00 00       	mov    $0xd8,%eax
80102576:	e8 14 ff ff ff       	call   8010248f <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
8010257b:	a1 c0 39 13 80       	mov    0x801339c0,%eax
80102580:	8b 40 30             	mov    0x30(%eax),%eax
80102583:	c1 e8 10             	shr    $0x10,%eax
80102586:	3c 03                	cmp    $0x3,%al
80102588:	77 7b                	ja     80102605 <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
8010258a:	ba 33 00 00 00       	mov    $0x33,%edx
8010258f:	b8 dc 00 00 00       	mov    $0xdc,%eax
80102594:	e8 f6 fe ff ff       	call   8010248f <lapicw>
  lapicw(ESR, 0);
80102599:	ba 00 00 00 00       	mov    $0x0,%edx
8010259e:	b8 a0 00 00 00       	mov    $0xa0,%eax
801025a3:	e8 e7 fe ff ff       	call   8010248f <lapicw>
  lapicw(ESR, 0);
801025a8:	ba 00 00 00 00       	mov    $0x0,%edx
801025ad:	b8 a0 00 00 00       	mov    $0xa0,%eax
801025b2:	e8 d8 fe ff ff       	call   8010248f <lapicw>
  lapicw(EOI, 0);
801025b7:	ba 00 00 00 00       	mov    $0x0,%edx
801025bc:	b8 2c 00 00 00       	mov    $0x2c,%eax
801025c1:	e8 c9 fe ff ff       	call   8010248f <lapicw>
  lapicw(ICRHI, 0);
801025c6:	ba 00 00 00 00       	mov    $0x0,%edx
801025cb:	b8 c4 00 00 00       	mov    $0xc4,%eax
801025d0:	e8 ba fe ff ff       	call   8010248f <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801025d5:	ba 00 85 08 00       	mov    $0x88500,%edx
801025da:	b8 c0 00 00 00       	mov    $0xc0,%eax
801025df:	e8 ab fe ff ff       	call   8010248f <lapicw>
  while(lapic[ICRLO] & DELIVS)
801025e4:	a1 c0 39 13 80       	mov    0x801339c0,%eax
801025e9:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
801025ef:	f6 c4 10             	test   $0x10,%ah
801025f2:	75 f0                	jne    801025e4 <lapicinit+0xd3>
  lapicw(TPR, 0);
801025f4:	ba 00 00 00 00       	mov    $0x0,%edx
801025f9:	b8 20 00 00 00       	mov    $0x20,%eax
801025fe:	e8 8c fe ff ff       	call   8010248f <lapicw>
}
80102603:	5d                   	pop    %ebp
80102604:	c3                   	ret    
    lapicw(PCINT, MASKED);
80102605:	ba 00 00 01 00       	mov    $0x10000,%edx
8010260a:	b8 d0 00 00 00       	mov    $0xd0,%eax
8010260f:	e8 7b fe ff ff       	call   8010248f <lapicw>
80102614:	e9 71 ff ff ff       	jmp    8010258a <lapicinit+0x79>
80102619:	f3 c3                	repz ret 

8010261b <lapicid>:
{
8010261b:	55                   	push   %ebp
8010261c:	89 e5                	mov    %esp,%ebp
  if (!lapic)
8010261e:	a1 c0 39 13 80       	mov    0x801339c0,%eax
80102623:	85 c0                	test   %eax,%eax
80102625:	74 08                	je     8010262f <lapicid+0x14>
  return lapic[ID] >> 24;
80102627:	8b 40 20             	mov    0x20(%eax),%eax
8010262a:	c1 e8 18             	shr    $0x18,%eax
}
8010262d:	5d                   	pop    %ebp
8010262e:	c3                   	ret    
    return 0;
8010262f:	b8 00 00 00 00       	mov    $0x0,%eax
80102634:	eb f7                	jmp    8010262d <lapicid+0x12>

80102636 <lapiceoi>:
  if(lapic)
80102636:	83 3d c0 39 13 80 00 	cmpl   $0x0,0x801339c0
8010263d:	74 14                	je     80102653 <lapiceoi+0x1d>
{
8010263f:	55                   	push   %ebp
80102640:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
80102642:	ba 00 00 00 00       	mov    $0x0,%edx
80102647:	b8 2c 00 00 00       	mov    $0x2c,%eax
8010264c:	e8 3e fe ff ff       	call   8010248f <lapicw>
}
80102651:	5d                   	pop    %ebp
80102652:	c3                   	ret    
80102653:	f3 c3                	repz ret 

80102655 <microdelay>:
{
80102655:	55                   	push   %ebp
80102656:	89 e5                	mov    %esp,%ebp
}
80102658:	5d                   	pop    %ebp
80102659:	c3                   	ret    

8010265a <lapicstartap>:
{
8010265a:	55                   	push   %ebp
8010265b:	89 e5                	mov    %esp,%ebp
8010265d:	57                   	push   %edi
8010265e:	56                   	push   %esi
8010265f:	53                   	push   %ebx
80102660:	8b 75 08             	mov    0x8(%ebp),%esi
80102663:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102666:	b8 0f 00 00 00       	mov    $0xf,%eax
8010266b:	ba 70 00 00 00       	mov    $0x70,%edx
80102670:	ee                   	out    %al,(%dx)
80102671:	b8 0a 00 00 00       	mov    $0xa,%eax
80102676:	ba 71 00 00 00       	mov    $0x71,%edx
8010267b:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
8010267c:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
80102683:	00 00 
  wrv[1] = addr >> 4;
80102685:	89 f8                	mov    %edi,%eax
80102687:	c1 e8 04             	shr    $0x4,%eax
8010268a:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
80102690:	c1 e6 18             	shl    $0x18,%esi
80102693:	89 f2                	mov    %esi,%edx
80102695:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010269a:	e8 f0 fd ff ff       	call   8010248f <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
8010269f:	ba 00 c5 00 00       	mov    $0xc500,%edx
801026a4:	b8 c0 00 00 00       	mov    $0xc0,%eax
801026a9:	e8 e1 fd ff ff       	call   8010248f <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
801026ae:	ba 00 85 00 00       	mov    $0x8500,%edx
801026b3:	b8 c0 00 00 00       	mov    $0xc0,%eax
801026b8:	e8 d2 fd ff ff       	call   8010248f <lapicw>
  for(i = 0; i < 2; i++){
801026bd:	bb 00 00 00 00       	mov    $0x0,%ebx
801026c2:	eb 21                	jmp    801026e5 <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
801026c4:	89 f2                	mov    %esi,%edx
801026c6:	b8 c4 00 00 00       	mov    $0xc4,%eax
801026cb:	e8 bf fd ff ff       	call   8010248f <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
801026d0:	89 fa                	mov    %edi,%edx
801026d2:	c1 ea 0c             	shr    $0xc,%edx
801026d5:	80 ce 06             	or     $0x6,%dh
801026d8:	b8 c0 00 00 00       	mov    $0xc0,%eax
801026dd:	e8 ad fd ff ff       	call   8010248f <lapicw>
  for(i = 0; i < 2; i++){
801026e2:	83 c3 01             	add    $0x1,%ebx
801026e5:	83 fb 01             	cmp    $0x1,%ebx
801026e8:	7e da                	jle    801026c4 <lapicstartap+0x6a>
}
801026ea:	5b                   	pop    %ebx
801026eb:	5e                   	pop    %esi
801026ec:	5f                   	pop    %edi
801026ed:	5d                   	pop    %ebp
801026ee:	c3                   	ret    

801026ef <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
801026ef:	55                   	push   %ebp
801026f0:	89 e5                	mov    %esp,%ebp
801026f2:	57                   	push   %edi
801026f3:	56                   	push   %esi
801026f4:	53                   	push   %ebx
801026f5:	83 ec 3c             	sub    $0x3c,%esp
801026f8:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801026fb:	b8 0b 00 00 00       	mov    $0xb,%eax
80102700:	e8 a2 fd ff ff       	call   801024a7 <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
80102705:	83 e0 04             	and    $0x4,%eax
80102708:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
8010270a:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010270d:	e8 a9 fd ff ff       	call   801024bb <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
80102712:	b8 0a 00 00 00       	mov    $0xa,%eax
80102717:	e8 8b fd ff ff       	call   801024a7 <cmos_read>
8010271c:	a8 80                	test   $0x80,%al
8010271e:	75 ea                	jne    8010270a <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
80102720:	8d 5d b8             	lea    -0x48(%ebp),%ebx
80102723:	89 d8                	mov    %ebx,%eax
80102725:	e8 91 fd ff ff       	call   801024bb <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
8010272a:	83 ec 04             	sub    $0x4,%esp
8010272d:	6a 18                	push   $0x18
8010272f:	53                   	push   %ebx
80102730:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102733:	50                   	push   %eax
80102734:	e8 01 18 00 00       	call   80103f3a <memcmp>
80102739:	83 c4 10             	add    $0x10,%esp
8010273c:	85 c0                	test   %eax,%eax
8010273e:	75 ca                	jne    8010270a <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
80102740:	85 ff                	test   %edi,%edi
80102742:	0f 85 84 00 00 00    	jne    801027cc <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80102748:	8b 55 d0             	mov    -0x30(%ebp),%edx
8010274b:	89 d0                	mov    %edx,%eax
8010274d:	c1 e8 04             	shr    $0x4,%eax
80102750:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102753:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102756:	83 e2 0f             	and    $0xf,%edx
80102759:	01 d0                	add    %edx,%eax
8010275b:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
8010275e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80102761:	89 d0                	mov    %edx,%eax
80102763:	c1 e8 04             	shr    $0x4,%eax
80102766:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102769:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010276c:	83 e2 0f             	and    $0xf,%edx
8010276f:	01 d0                	add    %edx,%eax
80102771:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
80102774:	8b 55 d8             	mov    -0x28(%ebp),%edx
80102777:	89 d0                	mov    %edx,%eax
80102779:	c1 e8 04             	shr    $0x4,%eax
8010277c:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010277f:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102782:	83 e2 0f             	and    $0xf,%edx
80102785:	01 d0                	add    %edx,%eax
80102787:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
8010278a:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010278d:	89 d0                	mov    %edx,%eax
8010278f:	c1 e8 04             	shr    $0x4,%eax
80102792:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102795:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102798:	83 e2 0f             	and    $0xf,%edx
8010279b:	01 d0                	add    %edx,%eax
8010279d:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
801027a0:	8b 55 e0             	mov    -0x20(%ebp),%edx
801027a3:	89 d0                	mov    %edx,%eax
801027a5:	c1 e8 04             	shr    $0x4,%eax
801027a8:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801027ab:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801027ae:	83 e2 0f             	and    $0xf,%edx
801027b1:	01 d0                	add    %edx,%eax
801027b3:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
801027b6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801027b9:	89 d0                	mov    %edx,%eax
801027bb:	c1 e8 04             	shr    $0x4,%eax
801027be:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801027c1:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801027c4:	83 e2 0f             	and    $0xf,%edx
801027c7:	01 d0                	add    %edx,%eax
801027c9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
801027cc:	8b 45 d0             	mov    -0x30(%ebp),%eax
801027cf:	89 06                	mov    %eax,(%esi)
801027d1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801027d4:	89 46 04             	mov    %eax,0x4(%esi)
801027d7:	8b 45 d8             	mov    -0x28(%ebp),%eax
801027da:	89 46 08             	mov    %eax,0x8(%esi)
801027dd:	8b 45 dc             	mov    -0x24(%ebp),%eax
801027e0:	89 46 0c             	mov    %eax,0xc(%esi)
801027e3:	8b 45 e0             	mov    -0x20(%ebp),%eax
801027e6:	89 46 10             	mov    %eax,0x10(%esi)
801027e9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801027ec:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
801027ef:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
801027f6:	8d 65 f4             	lea    -0xc(%ebp),%esp
801027f9:	5b                   	pop    %ebx
801027fa:	5e                   	pop    %esi
801027fb:	5f                   	pop    %edi
801027fc:	5d                   	pop    %ebp
801027fd:	c3                   	ret    

801027fe <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
801027fe:	55                   	push   %ebp
801027ff:	89 e5                	mov    %esp,%ebp
80102801:	53                   	push   %ebx
80102802:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102805:	ff 35 14 3a 13 80    	pushl  0x80133a14
8010280b:	ff 35 24 3a 13 80    	pushl  0x80133a24
80102811:	e8 56 d9 ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
80102816:	8b 58 5c             	mov    0x5c(%eax),%ebx
80102819:	89 1d 28 3a 13 80    	mov    %ebx,0x80133a28
  for (i = 0; i < log.lh.n; i++) {
8010281f:	83 c4 10             	add    $0x10,%esp
80102822:	ba 00 00 00 00       	mov    $0x0,%edx
80102827:	eb 0e                	jmp    80102837 <read_head+0x39>
    log.lh.block[i] = lh->block[i];
80102829:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
8010282d:	89 0c 95 2c 3a 13 80 	mov    %ecx,-0x7fecc5d4(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
80102834:	83 c2 01             	add    $0x1,%edx
80102837:	39 d3                	cmp    %edx,%ebx
80102839:	7f ee                	jg     80102829 <read_head+0x2b>
  }
  brelse(buf);
8010283b:	83 ec 0c             	sub    $0xc,%esp
8010283e:	50                   	push   %eax
8010283f:	e8 91 d9 ff ff       	call   801001d5 <brelse>
}
80102844:	83 c4 10             	add    $0x10,%esp
80102847:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010284a:	c9                   	leave  
8010284b:	c3                   	ret    

8010284c <install_trans>:
{
8010284c:	55                   	push   %ebp
8010284d:	89 e5                	mov    %esp,%ebp
8010284f:	57                   	push   %edi
80102850:	56                   	push   %esi
80102851:	53                   	push   %ebx
80102852:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
80102855:	bb 00 00 00 00       	mov    $0x0,%ebx
8010285a:	eb 66                	jmp    801028c2 <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
8010285c:	89 d8                	mov    %ebx,%eax
8010285e:	03 05 14 3a 13 80    	add    0x80133a14,%eax
80102864:	83 c0 01             	add    $0x1,%eax
80102867:	83 ec 08             	sub    $0x8,%esp
8010286a:	50                   	push   %eax
8010286b:	ff 35 24 3a 13 80    	pushl  0x80133a24
80102871:	e8 f6 d8 ff ff       	call   8010016c <bread>
80102876:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
80102878:	83 c4 08             	add    $0x8,%esp
8010287b:	ff 34 9d 2c 3a 13 80 	pushl  -0x7fecc5d4(,%ebx,4)
80102882:	ff 35 24 3a 13 80    	pushl  0x80133a24
80102888:	e8 df d8 ff ff       	call   8010016c <bread>
8010288d:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
8010288f:	8d 57 5c             	lea    0x5c(%edi),%edx
80102892:	8d 40 5c             	lea    0x5c(%eax),%eax
80102895:	83 c4 0c             	add    $0xc,%esp
80102898:	68 00 02 00 00       	push   $0x200
8010289d:	52                   	push   %edx
8010289e:	50                   	push   %eax
8010289f:	e8 cb 16 00 00       	call   80103f6f <memmove>
    bwrite(dbuf);  // write dst to disk
801028a4:	89 34 24             	mov    %esi,(%esp)
801028a7:	e8 ee d8 ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
801028ac:	89 3c 24             	mov    %edi,(%esp)
801028af:	e8 21 d9 ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
801028b4:	89 34 24             	mov    %esi,(%esp)
801028b7:	e8 19 d9 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
801028bc:	83 c3 01             	add    $0x1,%ebx
801028bf:	83 c4 10             	add    $0x10,%esp
801028c2:	39 1d 28 3a 13 80    	cmp    %ebx,0x80133a28
801028c8:	7f 92                	jg     8010285c <install_trans+0x10>
}
801028ca:	8d 65 f4             	lea    -0xc(%ebp),%esp
801028cd:	5b                   	pop    %ebx
801028ce:	5e                   	pop    %esi
801028cf:	5f                   	pop    %edi
801028d0:	5d                   	pop    %ebp
801028d1:	c3                   	ret    

801028d2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801028d2:	55                   	push   %ebp
801028d3:	89 e5                	mov    %esp,%ebp
801028d5:	53                   	push   %ebx
801028d6:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
801028d9:	ff 35 14 3a 13 80    	pushl  0x80133a14
801028df:	ff 35 24 3a 13 80    	pushl  0x80133a24
801028e5:	e8 82 d8 ff ff       	call   8010016c <bread>
801028ea:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
801028ec:	8b 0d 28 3a 13 80    	mov    0x80133a28,%ecx
801028f2:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
801028f5:	83 c4 10             	add    $0x10,%esp
801028f8:	b8 00 00 00 00       	mov    $0x0,%eax
801028fd:	eb 0e                	jmp    8010290d <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
801028ff:	8b 14 85 2c 3a 13 80 	mov    -0x7fecc5d4(,%eax,4),%edx
80102906:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
8010290a:	83 c0 01             	add    $0x1,%eax
8010290d:	39 c1                	cmp    %eax,%ecx
8010290f:	7f ee                	jg     801028ff <write_head+0x2d>
  }
  bwrite(buf);
80102911:	83 ec 0c             	sub    $0xc,%esp
80102914:	53                   	push   %ebx
80102915:	e8 80 d8 ff ff       	call   8010019a <bwrite>
  brelse(buf);
8010291a:	89 1c 24             	mov    %ebx,(%esp)
8010291d:	e8 b3 d8 ff ff       	call   801001d5 <brelse>
}
80102922:	83 c4 10             	add    $0x10,%esp
80102925:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102928:	c9                   	leave  
80102929:	c3                   	ret    

8010292a <recover_from_log>:

static void
recover_from_log(void)
{
8010292a:	55                   	push   %ebp
8010292b:	89 e5                	mov    %esp,%ebp
8010292d:	83 ec 08             	sub    $0x8,%esp
  read_head();
80102930:	e8 c9 fe ff ff       	call   801027fe <read_head>
  install_trans(); // if committed, copy from log to disk
80102935:	e8 12 ff ff ff       	call   8010284c <install_trans>
  log.lh.n = 0;
8010293a:	c7 05 28 3a 13 80 00 	movl   $0x0,0x80133a28
80102941:	00 00 00 
  write_head(); // clear the log
80102944:	e8 89 ff ff ff       	call   801028d2 <write_head>
}
80102949:	c9                   	leave  
8010294a:	c3                   	ret    

8010294b <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
8010294b:	55                   	push   %ebp
8010294c:	89 e5                	mov    %esp,%ebp
8010294e:	57                   	push   %edi
8010294f:	56                   	push   %esi
80102950:	53                   	push   %ebx
80102951:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80102954:	bb 00 00 00 00       	mov    $0x0,%ebx
80102959:	eb 66                	jmp    801029c1 <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
8010295b:	89 d8                	mov    %ebx,%eax
8010295d:	03 05 14 3a 13 80    	add    0x80133a14,%eax
80102963:	83 c0 01             	add    $0x1,%eax
80102966:	83 ec 08             	sub    $0x8,%esp
80102969:	50                   	push   %eax
8010296a:	ff 35 24 3a 13 80    	pushl  0x80133a24
80102970:	e8 f7 d7 ff ff       	call   8010016c <bread>
80102975:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80102977:	83 c4 08             	add    $0x8,%esp
8010297a:	ff 34 9d 2c 3a 13 80 	pushl  -0x7fecc5d4(,%ebx,4)
80102981:	ff 35 24 3a 13 80    	pushl  0x80133a24
80102987:	e8 e0 d7 ff ff       	call   8010016c <bread>
8010298c:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
8010298e:	8d 50 5c             	lea    0x5c(%eax),%edx
80102991:	8d 46 5c             	lea    0x5c(%esi),%eax
80102994:	83 c4 0c             	add    $0xc,%esp
80102997:	68 00 02 00 00       	push   $0x200
8010299c:	52                   	push   %edx
8010299d:	50                   	push   %eax
8010299e:	e8 cc 15 00 00       	call   80103f6f <memmove>
    bwrite(to);  // write the log
801029a3:	89 34 24             	mov    %esi,(%esp)
801029a6:	e8 ef d7 ff ff       	call   8010019a <bwrite>
    brelse(from);
801029ab:	89 3c 24             	mov    %edi,(%esp)
801029ae:	e8 22 d8 ff ff       	call   801001d5 <brelse>
    brelse(to);
801029b3:	89 34 24             	mov    %esi,(%esp)
801029b6:	e8 1a d8 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
801029bb:	83 c3 01             	add    $0x1,%ebx
801029be:	83 c4 10             	add    $0x10,%esp
801029c1:	39 1d 28 3a 13 80    	cmp    %ebx,0x80133a28
801029c7:	7f 92                	jg     8010295b <write_log+0x10>
  }
}
801029c9:	8d 65 f4             	lea    -0xc(%ebp),%esp
801029cc:	5b                   	pop    %ebx
801029cd:	5e                   	pop    %esi
801029ce:	5f                   	pop    %edi
801029cf:	5d                   	pop    %ebp
801029d0:	c3                   	ret    

801029d1 <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
801029d1:	83 3d 28 3a 13 80 00 	cmpl   $0x0,0x80133a28
801029d8:	7e 26                	jle    80102a00 <commit+0x2f>
{
801029da:	55                   	push   %ebp
801029db:	89 e5                	mov    %esp,%ebp
801029dd:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
801029e0:	e8 66 ff ff ff       	call   8010294b <write_log>
    write_head();    // Write header to disk -- the real commit
801029e5:	e8 e8 fe ff ff       	call   801028d2 <write_head>
    install_trans(); // Now install writes to home locations
801029ea:	e8 5d fe ff ff       	call   8010284c <install_trans>
    log.lh.n = 0;
801029ef:	c7 05 28 3a 13 80 00 	movl   $0x0,0x80133a28
801029f6:	00 00 00 
    write_head();    // Erase the transaction from the log
801029f9:	e8 d4 fe ff ff       	call   801028d2 <write_head>
  }
}
801029fe:	c9                   	leave  
801029ff:	c3                   	ret    
80102a00:	f3 c3                	repz ret 

80102a02 <initlog>:
{
80102a02:	55                   	push   %ebp
80102a03:	89 e5                	mov    %esp,%ebp
80102a05:	53                   	push   %ebx
80102a06:	83 ec 2c             	sub    $0x2c,%esp
80102a09:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
80102a0c:	68 00 6c 10 80       	push   $0x80106c00
80102a11:	68 e0 39 13 80       	push   $0x801339e0
80102a16:	e8 f1 12 00 00       	call   80103d0c <initlock>
  readsb(dev, &sb);
80102a1b:	83 c4 08             	add    $0x8,%esp
80102a1e:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102a21:	50                   	push   %eax
80102a22:	53                   	push   %ebx
80102a23:	e8 1a e8 ff ff       	call   80101242 <readsb>
  log.start = sb.logstart;
80102a28:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102a2b:	a3 14 3a 13 80       	mov    %eax,0x80133a14
  log.size = sb.nlog;
80102a30:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102a33:	a3 18 3a 13 80       	mov    %eax,0x80133a18
  log.dev = dev;
80102a38:	89 1d 24 3a 13 80    	mov    %ebx,0x80133a24
  recover_from_log();
80102a3e:	e8 e7 fe ff ff       	call   8010292a <recover_from_log>
}
80102a43:	83 c4 10             	add    $0x10,%esp
80102a46:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a49:	c9                   	leave  
80102a4a:	c3                   	ret    

80102a4b <begin_op>:
{
80102a4b:	55                   	push   %ebp
80102a4c:	89 e5                	mov    %esp,%ebp
80102a4e:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
80102a51:	68 e0 39 13 80       	push   $0x801339e0
80102a56:	e8 ed 13 00 00       	call   80103e48 <acquire>
80102a5b:	83 c4 10             	add    $0x10,%esp
80102a5e:	eb 15                	jmp    80102a75 <begin_op+0x2a>
      sleep(&log, &log.lock);
80102a60:	83 ec 08             	sub    $0x8,%esp
80102a63:	68 e0 39 13 80       	push   $0x801339e0
80102a68:	68 e0 39 13 80       	push   $0x801339e0
80102a6d:	e8 db 0e 00 00       	call   8010394d <sleep>
80102a72:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
80102a75:	83 3d 20 3a 13 80 00 	cmpl   $0x0,0x80133a20
80102a7c:	75 e2                	jne    80102a60 <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80102a7e:	a1 1c 3a 13 80       	mov    0x80133a1c,%eax
80102a83:	83 c0 01             	add    $0x1,%eax
80102a86:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102a89:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
80102a8c:	03 15 28 3a 13 80    	add    0x80133a28,%edx
80102a92:	83 fa 1e             	cmp    $0x1e,%edx
80102a95:	7e 17                	jle    80102aae <begin_op+0x63>
      sleep(&log, &log.lock);
80102a97:	83 ec 08             	sub    $0x8,%esp
80102a9a:	68 e0 39 13 80       	push   $0x801339e0
80102a9f:	68 e0 39 13 80       	push   $0x801339e0
80102aa4:	e8 a4 0e 00 00       	call   8010394d <sleep>
80102aa9:	83 c4 10             	add    $0x10,%esp
80102aac:	eb c7                	jmp    80102a75 <begin_op+0x2a>
      log.outstanding += 1;
80102aae:	a3 1c 3a 13 80       	mov    %eax,0x80133a1c
      release(&log.lock);
80102ab3:	83 ec 0c             	sub    $0xc,%esp
80102ab6:	68 e0 39 13 80       	push   $0x801339e0
80102abb:	e8 ed 13 00 00       	call   80103ead <release>
}
80102ac0:	83 c4 10             	add    $0x10,%esp
80102ac3:	c9                   	leave  
80102ac4:	c3                   	ret    

80102ac5 <end_op>:
{
80102ac5:	55                   	push   %ebp
80102ac6:	89 e5                	mov    %esp,%ebp
80102ac8:	53                   	push   %ebx
80102ac9:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
80102acc:	68 e0 39 13 80       	push   $0x801339e0
80102ad1:	e8 72 13 00 00       	call   80103e48 <acquire>
  log.outstanding -= 1;
80102ad6:	a1 1c 3a 13 80       	mov    0x80133a1c,%eax
80102adb:	83 e8 01             	sub    $0x1,%eax
80102ade:	a3 1c 3a 13 80       	mov    %eax,0x80133a1c
  if(log.committing)
80102ae3:	8b 1d 20 3a 13 80    	mov    0x80133a20,%ebx
80102ae9:	83 c4 10             	add    $0x10,%esp
80102aec:	85 db                	test   %ebx,%ebx
80102aee:	75 2c                	jne    80102b1c <end_op+0x57>
  if(log.outstanding == 0){
80102af0:	85 c0                	test   %eax,%eax
80102af2:	75 35                	jne    80102b29 <end_op+0x64>
    log.committing = 1;
80102af4:	c7 05 20 3a 13 80 01 	movl   $0x1,0x80133a20
80102afb:	00 00 00 
    do_commit = 1;
80102afe:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
80102b03:	83 ec 0c             	sub    $0xc,%esp
80102b06:	68 e0 39 13 80       	push   $0x801339e0
80102b0b:	e8 9d 13 00 00       	call   80103ead <release>
  if(do_commit){
80102b10:	83 c4 10             	add    $0x10,%esp
80102b13:	85 db                	test   %ebx,%ebx
80102b15:	75 24                	jne    80102b3b <end_op+0x76>
}
80102b17:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102b1a:	c9                   	leave  
80102b1b:	c3                   	ret    
    panic("log.committing");
80102b1c:	83 ec 0c             	sub    $0xc,%esp
80102b1f:	68 04 6c 10 80       	push   $0x80106c04
80102b24:	e8 1f d8 ff ff       	call   80100348 <panic>
    wakeup(&log);
80102b29:	83 ec 0c             	sub    $0xc,%esp
80102b2c:	68 e0 39 13 80       	push   $0x801339e0
80102b31:	e8 7c 0f 00 00       	call   80103ab2 <wakeup>
80102b36:	83 c4 10             	add    $0x10,%esp
80102b39:	eb c8                	jmp    80102b03 <end_op+0x3e>
    commit();
80102b3b:	e8 91 fe ff ff       	call   801029d1 <commit>
    acquire(&log.lock);
80102b40:	83 ec 0c             	sub    $0xc,%esp
80102b43:	68 e0 39 13 80       	push   $0x801339e0
80102b48:	e8 fb 12 00 00       	call   80103e48 <acquire>
    log.committing = 0;
80102b4d:	c7 05 20 3a 13 80 00 	movl   $0x0,0x80133a20
80102b54:	00 00 00 
    wakeup(&log);
80102b57:	c7 04 24 e0 39 13 80 	movl   $0x801339e0,(%esp)
80102b5e:	e8 4f 0f 00 00       	call   80103ab2 <wakeup>
    release(&log.lock);
80102b63:	c7 04 24 e0 39 13 80 	movl   $0x801339e0,(%esp)
80102b6a:	e8 3e 13 00 00       	call   80103ead <release>
80102b6f:	83 c4 10             	add    $0x10,%esp
}
80102b72:	eb a3                	jmp    80102b17 <end_op+0x52>

80102b74 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80102b74:	55                   	push   %ebp
80102b75:	89 e5                	mov    %esp,%ebp
80102b77:	53                   	push   %ebx
80102b78:	83 ec 04             	sub    $0x4,%esp
80102b7b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80102b7e:	8b 15 28 3a 13 80    	mov    0x80133a28,%edx
80102b84:	83 fa 1d             	cmp    $0x1d,%edx
80102b87:	7f 45                	jg     80102bce <log_write+0x5a>
80102b89:	a1 18 3a 13 80       	mov    0x80133a18,%eax
80102b8e:	83 e8 01             	sub    $0x1,%eax
80102b91:	39 c2                	cmp    %eax,%edx
80102b93:	7d 39                	jge    80102bce <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102b95:	83 3d 1c 3a 13 80 00 	cmpl   $0x0,0x80133a1c
80102b9c:	7e 3d                	jle    80102bdb <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102b9e:	83 ec 0c             	sub    $0xc,%esp
80102ba1:	68 e0 39 13 80       	push   $0x801339e0
80102ba6:	e8 9d 12 00 00       	call   80103e48 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80102bab:	83 c4 10             	add    $0x10,%esp
80102bae:	b8 00 00 00 00       	mov    $0x0,%eax
80102bb3:	8b 15 28 3a 13 80    	mov    0x80133a28,%edx
80102bb9:	39 c2                	cmp    %eax,%edx
80102bbb:	7e 2b                	jle    80102be8 <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102bbd:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102bc0:	39 0c 85 2c 3a 13 80 	cmp    %ecx,-0x7fecc5d4(,%eax,4)
80102bc7:	74 1f                	je     80102be8 <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
80102bc9:	83 c0 01             	add    $0x1,%eax
80102bcc:	eb e5                	jmp    80102bb3 <log_write+0x3f>
    panic("too big a transaction");
80102bce:	83 ec 0c             	sub    $0xc,%esp
80102bd1:	68 13 6c 10 80       	push   $0x80106c13
80102bd6:	e8 6d d7 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102bdb:	83 ec 0c             	sub    $0xc,%esp
80102bde:	68 29 6c 10 80       	push   $0x80106c29
80102be3:	e8 60 d7 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102be8:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102beb:	89 0c 85 2c 3a 13 80 	mov    %ecx,-0x7fecc5d4(,%eax,4)
  if (i == log.lh.n)
80102bf2:	39 c2                	cmp    %eax,%edx
80102bf4:	74 18                	je     80102c0e <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102bf6:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102bf9:	83 ec 0c             	sub    $0xc,%esp
80102bfc:	68 e0 39 13 80       	push   $0x801339e0
80102c01:	e8 a7 12 00 00       	call   80103ead <release>
}
80102c06:	83 c4 10             	add    $0x10,%esp
80102c09:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102c0c:	c9                   	leave  
80102c0d:	c3                   	ret    
    log.lh.n++;
80102c0e:	83 c2 01             	add    $0x1,%edx
80102c11:	89 15 28 3a 13 80    	mov    %edx,0x80133a28
80102c17:	eb dd                	jmp    80102bf6 <log_write+0x82>

80102c19 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102c19:	55                   	push   %ebp
80102c1a:	89 e5                	mov    %esp,%ebp
80102c1c:	53                   	push   %ebx
80102c1d:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102c20:	68 8a 00 00 00       	push   $0x8a
80102c25:	68 8c a4 10 80       	push   $0x8010a48c
80102c2a:	68 00 70 00 80       	push   $0x80007000
80102c2f:	e8 3b 13 00 00       	call   80103f6f <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102c34:	83 c4 10             	add    $0x10,%esp
80102c37:	bb e0 3a 13 80       	mov    $0x80133ae0,%ebx
80102c3c:	eb 06                	jmp    80102c44 <startothers+0x2b>
80102c3e:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102c44:	69 05 60 40 13 80 b0 	imul   $0xb0,0x80134060,%eax
80102c4b:	00 00 00 
80102c4e:	05 e0 3a 13 80       	add    $0x80133ae0,%eax
80102c53:	39 d8                	cmp    %ebx,%eax
80102c55:	76 51                	jbe    80102ca8 <startothers+0x8f>
    if(c == mycpu())  // We've started already.
80102c57:	e8 d3 07 00 00       	call   8010342f <mycpu>
80102c5c:	39 d8                	cmp    %ebx,%eax
80102c5e:	74 de                	je     80102c3e <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc2(-2);
80102c60:	83 ec 0c             	sub    $0xc,%esp
80102c63:	6a fe                	push   $0xfffffffe
80102c65:	e8 56 f6 ff ff       	call   801022c0 <kalloc2>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102c6a:	05 00 10 00 00       	add    $0x1000,%eax
80102c6f:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102c74:	c7 05 f8 6f 00 80 ec 	movl   $0x80102cec,0x80006ff8
80102c7b:	2c 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102c7e:	c7 05 f4 6f 00 80 00 	movl   $0x109000,0x80006ff4
80102c85:	90 10 00 

    lapicstartap(c->apicid, V2P(code));
80102c88:	83 c4 08             	add    $0x8,%esp
80102c8b:	68 00 70 00 00       	push   $0x7000
80102c90:	0f b6 03             	movzbl (%ebx),%eax
80102c93:	50                   	push   %eax
80102c94:	e8 c1 f9 ff ff       	call   8010265a <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102c99:	83 c4 10             	add    $0x10,%esp
80102c9c:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102ca2:	85 c0                	test   %eax,%eax
80102ca4:	74 f6                	je     80102c9c <startothers+0x83>
80102ca6:	eb 96                	jmp    80102c3e <startothers+0x25>
      ;
  }
}
80102ca8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102cab:	c9                   	leave  
80102cac:	c3                   	ret    

80102cad <mpmain>:
{
80102cad:	55                   	push   %ebp
80102cae:	89 e5                	mov    %esp,%ebp
80102cb0:	53                   	push   %ebx
80102cb1:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102cb4:	e8 d2 07 00 00       	call   8010348b <cpuid>
80102cb9:	89 c3                	mov    %eax,%ebx
80102cbb:	e8 cb 07 00 00       	call   8010348b <cpuid>
80102cc0:	83 ec 04             	sub    $0x4,%esp
80102cc3:	53                   	push   %ebx
80102cc4:	50                   	push   %eax
80102cc5:	68 44 6c 10 80       	push   $0x80106c44
80102cca:	e8 3c d9 ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102ccf:	e8 f2 23 00 00       	call   801050c6 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102cd4:	e8 56 07 00 00       	call   8010342f <mycpu>
80102cd9:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102cdb:	b8 01 00 00 00       	mov    $0x1,%eax
80102ce0:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102ce7:	e8 3c 0a 00 00       	call   80103728 <scheduler>

80102cec <mpenter>:
{
80102cec:	55                   	push   %ebp
80102ced:	89 e5                	mov    %esp,%ebp
80102cef:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102cf2:	e8 d8 33 00 00       	call   801060cf <switchkvm>
  seginit();
80102cf7:	e8 87 32 00 00       	call   80105f83 <seginit>
  lapicinit();
80102cfc:	e8 10 f8 ff ff       	call   80102511 <lapicinit>
  mpmain();
80102d01:	e8 a7 ff ff ff       	call   80102cad <mpmain>

80102d06 <main>:
{
80102d06:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102d0a:	83 e4 f0             	and    $0xfffffff0,%esp
80102d0d:	ff 71 fc             	pushl  -0x4(%ecx)
80102d10:	55                   	push   %ebp
80102d11:	89 e5                	mov    %esp,%ebp
80102d13:	51                   	push   %ecx
80102d14:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102d17:	68 00 00 40 80       	push   $0x80400000
80102d1c:	68 08 68 13 80       	push   $0x80136808
80102d21:	e8 b1 f4 ff ff       	call   801021d7 <kinit1>
  kvmalloc();      // kernel page table
80102d26:	e8 3a 38 00 00       	call   80106565 <kvmalloc>
  mpinit();        // detect other processors
80102d2b:	e8 c9 01 00 00       	call   80102ef9 <mpinit>
  lapicinit();     // interrupt controller
80102d30:	e8 dc f7 ff ff       	call   80102511 <lapicinit>
  seginit();       // segment descriptors
80102d35:	e8 49 32 00 00       	call   80105f83 <seginit>
  picinit();       // disable pic
80102d3a:	e8 82 02 00 00       	call   80102fc1 <picinit>
  ioapicinit();    // another interrupt controller
80102d3f:	e8 c2 f1 ff ff       	call   80101f06 <ioapicinit>
  consoleinit();   // console hardware
80102d44:	e8 45 db ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102d49:	e8 26 26 00 00       	call   80105374 <uartinit>
  pinit();         // process table
80102d4e:	e8 c2 06 00 00       	call   80103415 <pinit>
  tvinit();        // trap vectors
80102d53:	e8 bd 22 00 00       	call   80105015 <tvinit>
  binit();         // buffer cache
80102d58:	e8 97 d3 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102d5d:	e8 bd de ff ff       	call   80100c1f <fileinit>
  ideinit();       // disk 
80102d62:	e8 a5 ef ff ff       	call   80101d0c <ideinit>
  startothers();   // start other processors
80102d67:	e8 ad fe ff ff       	call   80102c19 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102d6c:	83 c4 08             	add    $0x8,%esp
80102d6f:	68 00 00 00 8e       	push   $0x8e000000
80102d74:	68 00 00 40 80       	push   $0x80400000
80102d79:	e8 8b f4 ff ff       	call   80102209 <kinit2>
  userinit();      // first user process
80102d7e:	e8 47 07 00 00       	call   801034ca <userinit>
  mpmain();        // finish this processor's setup
80102d83:	e8 25 ff ff ff       	call   80102cad <mpmain>

80102d88 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102d88:	55                   	push   %ebp
80102d89:	89 e5                	mov    %esp,%ebp
80102d8b:	56                   	push   %esi
80102d8c:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102d8d:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102d92:	b9 00 00 00 00       	mov    $0x0,%ecx
80102d97:	eb 09                	jmp    80102da2 <sum+0x1a>
    sum += addr[i];
80102d99:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102d9d:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102d9f:	83 c1 01             	add    $0x1,%ecx
80102da2:	39 d1                	cmp    %edx,%ecx
80102da4:	7c f3                	jl     80102d99 <sum+0x11>
  return sum;
}
80102da6:	89 d8                	mov    %ebx,%eax
80102da8:	5b                   	pop    %ebx
80102da9:	5e                   	pop    %esi
80102daa:	5d                   	pop    %ebp
80102dab:	c3                   	ret    

80102dac <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102dac:	55                   	push   %ebp
80102dad:	89 e5                	mov    %esp,%ebp
80102daf:	56                   	push   %esi
80102db0:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102db1:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102db7:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102db9:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102dbb:	eb 03                	jmp    80102dc0 <mpsearch1+0x14>
80102dbd:	83 c3 10             	add    $0x10,%ebx
80102dc0:	39 f3                	cmp    %esi,%ebx
80102dc2:	73 29                	jae    80102ded <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102dc4:	83 ec 04             	sub    $0x4,%esp
80102dc7:	6a 04                	push   $0x4
80102dc9:	68 58 6c 10 80       	push   $0x80106c58
80102dce:	53                   	push   %ebx
80102dcf:	e8 66 11 00 00       	call   80103f3a <memcmp>
80102dd4:	83 c4 10             	add    $0x10,%esp
80102dd7:	85 c0                	test   %eax,%eax
80102dd9:	75 e2                	jne    80102dbd <mpsearch1+0x11>
80102ddb:	ba 10 00 00 00       	mov    $0x10,%edx
80102de0:	89 d8                	mov    %ebx,%eax
80102de2:	e8 a1 ff ff ff       	call   80102d88 <sum>
80102de7:	84 c0                	test   %al,%al
80102de9:	75 d2                	jne    80102dbd <mpsearch1+0x11>
80102deb:	eb 05                	jmp    80102df2 <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102ded:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102df2:	89 d8                	mov    %ebx,%eax
80102df4:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102df7:	5b                   	pop    %ebx
80102df8:	5e                   	pop    %esi
80102df9:	5d                   	pop    %ebp
80102dfa:	c3                   	ret    

80102dfb <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102dfb:	55                   	push   %ebp
80102dfc:	89 e5                	mov    %esp,%ebp
80102dfe:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102e01:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102e08:	c1 e0 08             	shl    $0x8,%eax
80102e0b:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102e12:	09 d0                	or     %edx,%eax
80102e14:	c1 e0 04             	shl    $0x4,%eax
80102e17:	85 c0                	test   %eax,%eax
80102e19:	74 1f                	je     80102e3a <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102e1b:	ba 00 04 00 00       	mov    $0x400,%edx
80102e20:	e8 87 ff ff ff       	call   80102dac <mpsearch1>
80102e25:	85 c0                	test   %eax,%eax
80102e27:	75 0f                	jne    80102e38 <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102e29:	ba 00 00 01 00       	mov    $0x10000,%edx
80102e2e:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102e33:	e8 74 ff ff ff       	call   80102dac <mpsearch1>
}
80102e38:	c9                   	leave  
80102e39:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102e3a:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102e41:	c1 e0 08             	shl    $0x8,%eax
80102e44:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102e4b:	09 d0                	or     %edx,%eax
80102e4d:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102e50:	2d 00 04 00 00       	sub    $0x400,%eax
80102e55:	ba 00 04 00 00       	mov    $0x400,%edx
80102e5a:	e8 4d ff ff ff       	call   80102dac <mpsearch1>
80102e5f:	85 c0                	test   %eax,%eax
80102e61:	75 d5                	jne    80102e38 <mpsearch+0x3d>
80102e63:	eb c4                	jmp    80102e29 <mpsearch+0x2e>

80102e65 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102e65:	55                   	push   %ebp
80102e66:	89 e5                	mov    %esp,%ebp
80102e68:	57                   	push   %edi
80102e69:	56                   	push   %esi
80102e6a:	53                   	push   %ebx
80102e6b:	83 ec 1c             	sub    $0x1c,%esp
80102e6e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102e71:	e8 85 ff ff ff       	call   80102dfb <mpsearch>
80102e76:	85 c0                	test   %eax,%eax
80102e78:	74 5c                	je     80102ed6 <mpconfig+0x71>
80102e7a:	89 c7                	mov    %eax,%edi
80102e7c:	8b 58 04             	mov    0x4(%eax),%ebx
80102e7f:	85 db                	test   %ebx,%ebx
80102e81:	74 5a                	je     80102edd <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102e83:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102e89:	83 ec 04             	sub    $0x4,%esp
80102e8c:	6a 04                	push   $0x4
80102e8e:	68 5d 6c 10 80       	push   $0x80106c5d
80102e93:	56                   	push   %esi
80102e94:	e8 a1 10 00 00       	call   80103f3a <memcmp>
80102e99:	83 c4 10             	add    $0x10,%esp
80102e9c:	85 c0                	test   %eax,%eax
80102e9e:	75 44                	jne    80102ee4 <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102ea0:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102ea7:	3c 01                	cmp    $0x1,%al
80102ea9:	0f 95 c2             	setne  %dl
80102eac:	3c 04                	cmp    $0x4,%al
80102eae:	0f 95 c0             	setne  %al
80102eb1:	84 c2                	test   %al,%dl
80102eb3:	75 36                	jne    80102eeb <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102eb5:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102ebc:	89 f0                	mov    %esi,%eax
80102ebe:	e8 c5 fe ff ff       	call   80102d88 <sum>
80102ec3:	84 c0                	test   %al,%al
80102ec5:	75 2b                	jne    80102ef2 <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102ec7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102eca:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102ecc:	89 f0                	mov    %esi,%eax
80102ece:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102ed1:	5b                   	pop    %ebx
80102ed2:	5e                   	pop    %esi
80102ed3:	5f                   	pop    %edi
80102ed4:	5d                   	pop    %ebp
80102ed5:	c3                   	ret    
    return 0;
80102ed6:	be 00 00 00 00       	mov    $0x0,%esi
80102edb:	eb ef                	jmp    80102ecc <mpconfig+0x67>
80102edd:	be 00 00 00 00       	mov    $0x0,%esi
80102ee2:	eb e8                	jmp    80102ecc <mpconfig+0x67>
    return 0;
80102ee4:	be 00 00 00 00       	mov    $0x0,%esi
80102ee9:	eb e1                	jmp    80102ecc <mpconfig+0x67>
    return 0;
80102eeb:	be 00 00 00 00       	mov    $0x0,%esi
80102ef0:	eb da                	jmp    80102ecc <mpconfig+0x67>
    return 0;
80102ef2:	be 00 00 00 00       	mov    $0x0,%esi
80102ef7:	eb d3                	jmp    80102ecc <mpconfig+0x67>

80102ef9 <mpinit>:

void
mpinit(void)
{
80102ef9:	55                   	push   %ebp
80102efa:	89 e5                	mov    %esp,%ebp
80102efc:	57                   	push   %edi
80102efd:	56                   	push   %esi
80102efe:	53                   	push   %ebx
80102eff:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102f02:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102f05:	e8 5b ff ff ff       	call   80102e65 <mpconfig>
80102f0a:	85 c0                	test   %eax,%eax
80102f0c:	74 19                	je     80102f27 <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102f0e:	8b 50 24             	mov    0x24(%eax),%edx
80102f11:	89 15 c0 39 13 80    	mov    %edx,0x801339c0
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102f17:	8d 50 2c             	lea    0x2c(%eax),%edx
80102f1a:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102f1e:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102f20:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102f25:	eb 34                	jmp    80102f5b <mpinit+0x62>
    panic("Expect to run on an SMP");
80102f27:	83 ec 0c             	sub    $0xc,%esp
80102f2a:	68 62 6c 10 80       	push   $0x80106c62
80102f2f:	e8 14 d4 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102f34:	8b 35 60 40 13 80    	mov    0x80134060,%esi
80102f3a:	83 fe 07             	cmp    $0x7,%esi
80102f3d:	7f 19                	jg     80102f58 <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102f3f:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102f43:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102f49:	88 87 e0 3a 13 80    	mov    %al,-0x7fecc520(%edi)
        ncpu++;
80102f4f:	83 c6 01             	add    $0x1,%esi
80102f52:	89 35 60 40 13 80    	mov    %esi,0x80134060
      }
      p += sizeof(struct mpproc);
80102f58:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102f5b:	39 ca                	cmp    %ecx,%edx
80102f5d:	73 2b                	jae    80102f8a <mpinit+0x91>
    switch(*p){
80102f5f:	0f b6 02             	movzbl (%edx),%eax
80102f62:	3c 04                	cmp    $0x4,%al
80102f64:	77 1d                	ja     80102f83 <mpinit+0x8a>
80102f66:	0f b6 c0             	movzbl %al,%eax
80102f69:	ff 24 85 9c 6c 10 80 	jmp    *-0x7fef9364(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102f70:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102f74:	a2 c0 3a 13 80       	mov    %al,0x80133ac0
      p += sizeof(struct mpioapic);
80102f79:	83 c2 08             	add    $0x8,%edx
      continue;
80102f7c:	eb dd                	jmp    80102f5b <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102f7e:	83 c2 08             	add    $0x8,%edx
      continue;
80102f81:	eb d8                	jmp    80102f5b <mpinit+0x62>
    default:
      ismp = 0;
80102f83:	bb 00 00 00 00       	mov    $0x0,%ebx
80102f88:	eb d1                	jmp    80102f5b <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102f8a:	85 db                	test   %ebx,%ebx
80102f8c:	74 26                	je     80102fb4 <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102f8e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102f91:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102f95:	74 15                	je     80102fac <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102f97:	b8 70 00 00 00       	mov    $0x70,%eax
80102f9c:	ba 22 00 00 00       	mov    $0x22,%edx
80102fa1:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102fa2:	ba 23 00 00 00       	mov    $0x23,%edx
80102fa7:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102fa8:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102fab:	ee                   	out    %al,(%dx)
  }
}
80102fac:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102faf:	5b                   	pop    %ebx
80102fb0:	5e                   	pop    %esi
80102fb1:	5f                   	pop    %edi
80102fb2:	5d                   	pop    %ebp
80102fb3:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102fb4:	83 ec 0c             	sub    $0xc,%esp
80102fb7:	68 7c 6c 10 80       	push   $0x80106c7c
80102fbc:	e8 87 d3 ff ff       	call   80100348 <panic>

80102fc1 <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102fc1:	55                   	push   %ebp
80102fc2:	89 e5                	mov    %esp,%ebp
80102fc4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102fc9:	ba 21 00 00 00       	mov    $0x21,%edx
80102fce:	ee                   	out    %al,(%dx)
80102fcf:	ba a1 00 00 00       	mov    $0xa1,%edx
80102fd4:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102fd5:	5d                   	pop    %ebp
80102fd6:	c3                   	ret    

80102fd7 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102fd7:	55                   	push   %ebp
80102fd8:	89 e5                	mov    %esp,%ebp
80102fda:	57                   	push   %edi
80102fdb:	56                   	push   %esi
80102fdc:	53                   	push   %ebx
80102fdd:	83 ec 0c             	sub    $0xc,%esp
80102fe0:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102fe3:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102fe6:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102fec:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102ff2:	e8 42 dc ff ff       	call   80100c39 <filealloc>
80102ff7:	89 03                	mov    %eax,(%ebx)
80102ff9:	85 c0                	test   %eax,%eax
80102ffb:	74 1e                	je     8010301b <pipealloc+0x44>
80102ffd:	e8 37 dc ff ff       	call   80100c39 <filealloc>
80103002:	89 06                	mov    %eax,(%esi)
80103004:	85 c0                	test   %eax,%eax
80103006:	74 13                	je     8010301b <pipealloc+0x44>
    goto bad;
  if((p = (struct pipe*)kalloc2(-2)) == 0)
80103008:	83 ec 0c             	sub    $0xc,%esp
8010300b:	6a fe                	push   $0xfffffffe
8010300d:	e8 ae f2 ff ff       	call   801022c0 <kalloc2>
80103012:	89 c7                	mov    %eax,%edi
80103014:	83 c4 10             	add    $0x10,%esp
80103017:	85 c0                	test   %eax,%eax
80103019:	75 35                	jne    80103050 <pipealloc+0x79>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
8010301b:	8b 03                	mov    (%ebx),%eax
8010301d:	85 c0                	test   %eax,%eax
8010301f:	74 0c                	je     8010302d <pipealloc+0x56>
    fileclose(*f0);
80103021:	83 ec 0c             	sub    $0xc,%esp
80103024:	50                   	push   %eax
80103025:	e8 b5 dc ff ff       	call   80100cdf <fileclose>
8010302a:	83 c4 10             	add    $0x10,%esp
  if(*f1)
8010302d:	8b 06                	mov    (%esi),%eax
8010302f:	85 c0                	test   %eax,%eax
80103031:	0f 84 8b 00 00 00    	je     801030c2 <pipealloc+0xeb>
    fileclose(*f1);
80103037:	83 ec 0c             	sub    $0xc,%esp
8010303a:	50                   	push   %eax
8010303b:	e8 9f dc ff ff       	call   80100cdf <fileclose>
80103040:	83 c4 10             	add    $0x10,%esp
  return -1;
80103043:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103048:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010304b:	5b                   	pop    %ebx
8010304c:	5e                   	pop    %esi
8010304d:	5f                   	pop    %edi
8010304e:	5d                   	pop    %ebp
8010304f:	c3                   	ret    
  p->readopen = 1;
80103050:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103057:	00 00 00 
  p->writeopen = 1;
8010305a:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80103061:	00 00 00 
  p->nwrite = 0;
80103064:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
8010306b:	00 00 00 
  p->nread = 0;
8010306e:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80103075:	00 00 00 
  initlock(&p->lock, "pipe");
80103078:	83 ec 08             	sub    $0x8,%esp
8010307b:	68 b0 6c 10 80       	push   $0x80106cb0
80103080:	50                   	push   %eax
80103081:	e8 86 0c 00 00       	call   80103d0c <initlock>
  (*f0)->type = FD_PIPE;
80103086:	8b 03                	mov    (%ebx),%eax
80103088:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
8010308e:	8b 03                	mov    (%ebx),%eax
80103090:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80103094:	8b 03                	mov    (%ebx),%eax
80103096:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
8010309a:	8b 03                	mov    (%ebx),%eax
8010309c:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
8010309f:	8b 06                	mov    (%esi),%eax
801030a1:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
801030a7:	8b 06                	mov    (%esi),%eax
801030a9:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
801030ad:	8b 06                	mov    (%esi),%eax
801030af:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
801030b3:	8b 06                	mov    (%esi),%eax
801030b5:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
801030b8:	83 c4 10             	add    $0x10,%esp
801030bb:	b8 00 00 00 00       	mov    $0x0,%eax
801030c0:	eb 86                	jmp    80103048 <pipealloc+0x71>
  return -1;
801030c2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801030c7:	e9 7c ff ff ff       	jmp    80103048 <pipealloc+0x71>

801030cc <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
801030cc:	55                   	push   %ebp
801030cd:	89 e5                	mov    %esp,%ebp
801030cf:	53                   	push   %ebx
801030d0:	83 ec 10             	sub    $0x10,%esp
801030d3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
801030d6:	53                   	push   %ebx
801030d7:	e8 6c 0d 00 00       	call   80103e48 <acquire>
  if(writable){
801030dc:	83 c4 10             	add    $0x10,%esp
801030df:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801030e3:	74 3f                	je     80103124 <pipeclose+0x58>
    p->writeopen = 0;
801030e5:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
801030ec:	00 00 00 
    wakeup(&p->nread);
801030ef:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801030f5:	83 ec 0c             	sub    $0xc,%esp
801030f8:	50                   	push   %eax
801030f9:	e8 b4 09 00 00       	call   80103ab2 <wakeup>
801030fe:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80103101:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80103108:	75 09                	jne    80103113 <pipeclose+0x47>
8010310a:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80103111:	74 2f                	je     80103142 <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80103113:	83 ec 0c             	sub    $0xc,%esp
80103116:	53                   	push   %ebx
80103117:	e8 91 0d 00 00       	call   80103ead <release>
8010311c:	83 c4 10             	add    $0x10,%esp
}
8010311f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103122:	c9                   	leave  
80103123:	c3                   	ret    
    p->readopen = 0;
80103124:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
8010312b:	00 00 00 
    wakeup(&p->nwrite);
8010312e:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103134:	83 ec 0c             	sub    $0xc,%esp
80103137:	50                   	push   %eax
80103138:	e8 75 09 00 00       	call   80103ab2 <wakeup>
8010313d:	83 c4 10             	add    $0x10,%esp
80103140:	eb bf                	jmp    80103101 <pipeclose+0x35>
    release(&p->lock);
80103142:	83 ec 0c             	sub    $0xc,%esp
80103145:	53                   	push   %ebx
80103146:	e8 62 0d 00 00       	call   80103ead <release>
    kfree((char*)p);
8010314b:	89 1c 24             	mov    %ebx,(%esp)
8010314e:	e8 31 ef ff ff       	call   80102084 <kfree>
80103153:	83 c4 10             	add    $0x10,%esp
80103156:	eb c7                	jmp    8010311f <pipeclose+0x53>

80103158 <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
80103158:	55                   	push   %ebp
80103159:	89 e5                	mov    %esp,%ebp
8010315b:	57                   	push   %edi
8010315c:	56                   	push   %esi
8010315d:	53                   	push   %ebx
8010315e:	83 ec 18             	sub    $0x18,%esp
80103161:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80103164:	89 de                	mov    %ebx,%esi
80103166:	53                   	push   %ebx
80103167:	e8 dc 0c 00 00       	call   80103e48 <acquire>
  for(i = 0; i < n; i++){
8010316c:	83 c4 10             	add    $0x10,%esp
8010316f:	bf 00 00 00 00       	mov    $0x0,%edi
80103174:	3b 7d 10             	cmp    0x10(%ebp),%edi
80103177:	0f 8d 88 00 00 00    	jge    80103205 <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010317d:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
80103183:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103189:	05 00 02 00 00       	add    $0x200,%eax
8010318e:	39 c2                	cmp    %eax,%edx
80103190:	75 51                	jne    801031e3 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
80103192:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80103199:	74 2f                	je     801031ca <pipewrite+0x72>
8010319b:	e8 06 03 00 00       	call   801034a6 <myproc>
801031a0:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801031a4:	75 24                	jne    801031ca <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
801031a6:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801031ac:	83 ec 0c             	sub    $0xc,%esp
801031af:	50                   	push   %eax
801031b0:	e8 fd 08 00 00       	call   80103ab2 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801031b5:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
801031bb:	83 c4 08             	add    $0x8,%esp
801031be:	56                   	push   %esi
801031bf:	50                   	push   %eax
801031c0:	e8 88 07 00 00       	call   8010394d <sleep>
801031c5:	83 c4 10             	add    $0x10,%esp
801031c8:	eb b3                	jmp    8010317d <pipewrite+0x25>
        release(&p->lock);
801031ca:	83 ec 0c             	sub    $0xc,%esp
801031cd:	53                   	push   %ebx
801031ce:	e8 da 0c 00 00       	call   80103ead <release>
        return -1;
801031d3:	83 c4 10             	add    $0x10,%esp
801031d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
801031db:	8d 65 f4             	lea    -0xc(%ebp),%esp
801031de:	5b                   	pop    %ebx
801031df:	5e                   	pop    %esi
801031e0:	5f                   	pop    %edi
801031e1:	5d                   	pop    %ebp
801031e2:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
801031e3:	8d 42 01             	lea    0x1(%edx),%eax
801031e6:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
801031ec:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
801031f2:	8b 45 0c             	mov    0xc(%ebp),%eax
801031f5:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
801031f9:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
801031fd:	83 c7 01             	add    $0x1,%edi
80103200:	e9 6f ff ff ff       	jmp    80103174 <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80103205:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
8010320b:	83 ec 0c             	sub    $0xc,%esp
8010320e:	50                   	push   %eax
8010320f:	e8 9e 08 00 00       	call   80103ab2 <wakeup>
  release(&p->lock);
80103214:	89 1c 24             	mov    %ebx,(%esp)
80103217:	e8 91 0c 00 00       	call   80103ead <release>
  return n;
8010321c:	83 c4 10             	add    $0x10,%esp
8010321f:	8b 45 10             	mov    0x10(%ebp),%eax
80103222:	eb b7                	jmp    801031db <pipewrite+0x83>

80103224 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80103224:	55                   	push   %ebp
80103225:	89 e5                	mov    %esp,%ebp
80103227:	57                   	push   %edi
80103228:	56                   	push   %esi
80103229:	53                   	push   %ebx
8010322a:	83 ec 18             	sub    $0x18,%esp
8010322d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80103230:	89 df                	mov    %ebx,%edi
80103232:	53                   	push   %ebx
80103233:	e8 10 0c 00 00       	call   80103e48 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103238:	83 c4 10             	add    $0x10,%esp
8010323b:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
80103241:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
80103247:	75 3d                	jne    80103286 <piperead+0x62>
80103249:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
8010324f:	85 f6                	test   %esi,%esi
80103251:	74 38                	je     8010328b <piperead+0x67>
    if(myproc()->killed){
80103253:	e8 4e 02 00 00       	call   801034a6 <myproc>
80103258:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010325c:	75 15                	jne    80103273 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010325e:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103264:	83 ec 08             	sub    $0x8,%esp
80103267:	57                   	push   %edi
80103268:	50                   	push   %eax
80103269:	e8 df 06 00 00       	call   8010394d <sleep>
8010326e:	83 c4 10             	add    $0x10,%esp
80103271:	eb c8                	jmp    8010323b <piperead+0x17>
      release(&p->lock);
80103273:	83 ec 0c             	sub    $0xc,%esp
80103276:	53                   	push   %ebx
80103277:	e8 31 0c 00 00       	call   80103ead <release>
      return -1;
8010327c:	83 c4 10             	add    $0x10,%esp
8010327f:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103284:	eb 50                	jmp    801032d6 <piperead+0xb2>
80103286:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010328b:	3b 75 10             	cmp    0x10(%ebp),%esi
8010328e:	7d 2c                	jge    801032bc <piperead+0x98>
    if(p->nread == p->nwrite)
80103290:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103296:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
8010329c:	74 1e                	je     801032bc <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
8010329e:	8d 50 01             	lea    0x1(%eax),%edx
801032a1:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
801032a7:	25 ff 01 00 00       	and    $0x1ff,%eax
801032ac:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
801032b1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801032b4:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801032b7:	83 c6 01             	add    $0x1,%esi
801032ba:	eb cf                	jmp    8010328b <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
801032bc:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
801032c2:	83 ec 0c             	sub    $0xc,%esp
801032c5:	50                   	push   %eax
801032c6:	e8 e7 07 00 00       	call   80103ab2 <wakeup>
  release(&p->lock);
801032cb:	89 1c 24             	mov    %ebx,(%esp)
801032ce:	e8 da 0b 00 00       	call   80103ead <release>
  return i;
801032d3:	83 c4 10             	add    $0x10,%esp
}
801032d6:	89 f0                	mov    %esi,%eax
801032d8:	8d 65 f4             	lea    -0xc(%ebp),%esp
801032db:	5b                   	pop    %ebx
801032dc:	5e                   	pop    %esi
801032dd:	5f                   	pop    %edi
801032de:	5d                   	pop    %ebp
801032df:	c3                   	ret    

801032e0 <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
801032e0:	55                   	push   %ebp
801032e1:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801032e3:	ba b4 40 13 80       	mov    $0x801340b4,%edx
801032e8:	eb 03                	jmp    801032ed <wakeup1+0xd>
801032ea:	83 c2 7c             	add    $0x7c,%edx
801032ed:	81 fa b4 5f 13 80    	cmp    $0x80135fb4,%edx
801032f3:	73 14                	jae    80103309 <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
801032f5:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
801032f9:	75 ef                	jne    801032ea <wakeup1+0xa>
801032fb:	39 42 20             	cmp    %eax,0x20(%edx)
801032fe:	75 ea                	jne    801032ea <wakeup1+0xa>
      p->state = RUNNABLE;
80103300:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
80103307:	eb e1                	jmp    801032ea <wakeup1+0xa>
}
80103309:	5d                   	pop    %ebp
8010330a:	c3                   	ret    

8010330b <allocproc>:
{
8010330b:	55                   	push   %ebp
8010330c:	89 e5                	mov    %esp,%ebp
8010330e:	53                   	push   %ebx
8010330f:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
80103312:	68 80 40 13 80       	push   $0x80134080
80103317:	e8 2c 0b 00 00       	call   80103e48 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010331c:	83 c4 10             	add    $0x10,%esp
8010331f:	bb b4 40 13 80       	mov    $0x801340b4,%ebx
80103324:	81 fb b4 5f 13 80    	cmp    $0x80135fb4,%ebx
8010332a:	73 0b                	jae    80103337 <allocproc+0x2c>
    if(p->state == UNUSED)
8010332c:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
80103330:	74 1c                	je     8010334e <allocproc+0x43>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103332:	83 c3 7c             	add    $0x7c,%ebx
80103335:	eb ed                	jmp    80103324 <allocproc+0x19>
  release(&ptable.lock);
80103337:	83 ec 0c             	sub    $0xc,%esp
8010333a:	68 80 40 13 80       	push   $0x80134080
8010333f:	e8 69 0b 00 00       	call   80103ead <release>
  return 0;
80103344:	83 c4 10             	add    $0x10,%esp
80103347:	bb 00 00 00 00       	mov    $0x0,%ebx
8010334c:	eb 6f                	jmp    801033bd <allocproc+0xb2>
  p->state = EMBRYO;
8010334e:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
80103355:	a1 04 a0 10 80       	mov    0x8010a004,%eax
8010335a:	8d 50 01             	lea    0x1(%eax),%edx
8010335d:	89 15 04 a0 10 80    	mov    %edx,0x8010a004
80103363:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
80103366:	83 ec 0c             	sub    $0xc,%esp
80103369:	68 80 40 13 80       	push   $0x80134080
8010336e:	e8 3a 0b 00 00       	call   80103ead <release>
  if((p->kstack = kalloc2(p->pid)) == 0){
80103373:	83 c4 04             	add    $0x4,%esp
80103376:	ff 73 10             	pushl  0x10(%ebx)
80103379:	e8 42 ef ff ff       	call   801022c0 <kalloc2>
8010337e:	89 43 08             	mov    %eax,0x8(%ebx)
80103381:	83 c4 10             	add    $0x10,%esp
80103384:	85 c0                	test   %eax,%eax
80103386:	74 3c                	je     801033c4 <allocproc+0xb9>
  sp -= sizeof *p->tf;
80103388:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
8010338e:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
80103391:	c7 80 b0 0f 00 00 0a 	movl   $0x8010500a,0xfb0(%eax)
80103398:	50 10 80 
  sp -= sizeof *p->context;
8010339b:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
801033a0:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
801033a3:	83 ec 04             	sub    $0x4,%esp
801033a6:	6a 14                	push   $0x14
801033a8:	6a 00                	push   $0x0
801033aa:	50                   	push   %eax
801033ab:	e8 44 0b 00 00       	call   80103ef4 <memset>
  p->context->eip = (uint)forkret;
801033b0:	8b 43 1c             	mov    0x1c(%ebx),%eax
801033b3:	c7 40 10 d2 33 10 80 	movl   $0x801033d2,0x10(%eax)
  return p;
801033ba:	83 c4 10             	add    $0x10,%esp
}
801033bd:	89 d8                	mov    %ebx,%eax
801033bf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801033c2:	c9                   	leave  
801033c3:	c3                   	ret    
    p->state = UNUSED;
801033c4:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
801033cb:	bb 00 00 00 00       	mov    $0x0,%ebx
801033d0:	eb eb                	jmp    801033bd <allocproc+0xb2>

801033d2 <forkret>:
{
801033d2:	55                   	push   %ebp
801033d3:	89 e5                	mov    %esp,%ebp
801033d5:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
801033d8:	68 80 40 13 80       	push   $0x80134080
801033dd:	e8 cb 0a 00 00       	call   80103ead <release>
  if (first) {
801033e2:	83 c4 10             	add    $0x10,%esp
801033e5:	83 3d 00 a0 10 80 00 	cmpl   $0x0,0x8010a000
801033ec:	75 02                	jne    801033f0 <forkret+0x1e>
}
801033ee:	c9                   	leave  
801033ef:	c3                   	ret    
    first = 0;
801033f0:	c7 05 00 a0 10 80 00 	movl   $0x0,0x8010a000
801033f7:	00 00 00 
    iinit(ROOTDEV);
801033fa:	83 ec 0c             	sub    $0xc,%esp
801033fd:	6a 01                	push   $0x1
801033ff:	e8 f4 de ff ff       	call   801012f8 <iinit>
    initlog(ROOTDEV);
80103404:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010340b:	e8 f2 f5 ff ff       	call   80102a02 <initlog>
80103410:	83 c4 10             	add    $0x10,%esp
}
80103413:	eb d9                	jmp    801033ee <forkret+0x1c>

80103415 <pinit>:
{
80103415:	55                   	push   %ebp
80103416:	89 e5                	mov    %esp,%ebp
80103418:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
8010341b:	68 b5 6c 10 80       	push   $0x80106cb5
80103420:	68 80 40 13 80       	push   $0x80134080
80103425:	e8 e2 08 00 00       	call   80103d0c <initlock>
}
8010342a:	83 c4 10             	add    $0x10,%esp
8010342d:	c9                   	leave  
8010342e:	c3                   	ret    

8010342f <mycpu>:
{
8010342f:	55                   	push   %ebp
80103430:	89 e5                	mov    %esp,%ebp
80103432:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103435:	9c                   	pushf  
80103436:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103437:	f6 c4 02             	test   $0x2,%ah
8010343a:	75 28                	jne    80103464 <mycpu+0x35>
  apicid = lapicid();
8010343c:	e8 da f1 ff ff       	call   8010261b <lapicid>
  for (i = 0; i < ncpu; ++i) {
80103441:	ba 00 00 00 00       	mov    $0x0,%edx
80103446:	39 15 60 40 13 80    	cmp    %edx,0x80134060
8010344c:	7e 23                	jle    80103471 <mycpu+0x42>
    if (cpus[i].apicid == apicid)
8010344e:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
80103454:	0f b6 89 e0 3a 13 80 	movzbl -0x7fecc520(%ecx),%ecx
8010345b:	39 c1                	cmp    %eax,%ecx
8010345d:	74 1f                	je     8010347e <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
8010345f:	83 c2 01             	add    $0x1,%edx
80103462:	eb e2                	jmp    80103446 <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
80103464:	83 ec 0c             	sub    $0xc,%esp
80103467:	68 98 6d 10 80       	push   $0x80106d98
8010346c:	e8 d7 ce ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
80103471:	83 ec 0c             	sub    $0xc,%esp
80103474:	68 bc 6c 10 80       	push   $0x80106cbc
80103479:	e8 ca ce ff ff       	call   80100348 <panic>
      return &cpus[i];
8010347e:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
80103484:	05 e0 3a 13 80       	add    $0x80133ae0,%eax
}
80103489:	c9                   	leave  
8010348a:	c3                   	ret    

8010348b <cpuid>:
cpuid() {
8010348b:	55                   	push   %ebp
8010348c:	89 e5                	mov    %esp,%ebp
8010348e:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
80103491:	e8 99 ff ff ff       	call   8010342f <mycpu>
80103496:	2d e0 3a 13 80       	sub    $0x80133ae0,%eax
8010349b:	c1 f8 04             	sar    $0x4,%eax
8010349e:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
801034a4:	c9                   	leave  
801034a5:	c3                   	ret    

801034a6 <myproc>:
myproc(void) {
801034a6:	55                   	push   %ebp
801034a7:	89 e5                	mov    %esp,%ebp
801034a9:	53                   	push   %ebx
801034aa:	83 ec 04             	sub    $0x4,%esp
  pushcli();
801034ad:	e8 b9 08 00 00       	call   80103d6b <pushcli>
  c = mycpu();
801034b2:	e8 78 ff ff ff       	call   8010342f <mycpu>
  p = c->proc;
801034b7:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
801034bd:	e8 e6 08 00 00       	call   80103da8 <popcli>
}
801034c2:	89 d8                	mov    %ebx,%eax
801034c4:	83 c4 04             	add    $0x4,%esp
801034c7:	5b                   	pop    %ebx
801034c8:	5d                   	pop    %ebp
801034c9:	c3                   	ret    

801034ca <userinit>:
{
801034ca:	55                   	push   %ebp
801034cb:	89 e5                	mov    %esp,%ebp
801034cd:	53                   	push   %ebx
801034ce:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
801034d1:	e8 35 fe ff ff       	call   8010330b <allocproc>
801034d6:	89 c3                	mov    %eax,%ebx
  initproc = p;
801034d8:	a3 b8 a5 10 80       	mov    %eax,0x8010a5b8
  if((p->pgdir = setupkvm()) == 0)
801034dd:	e8 15 30 00 00       	call   801064f7 <setupkvm>
801034e2:	89 43 04             	mov    %eax,0x4(%ebx)
801034e5:	85 c0                	test   %eax,%eax
801034e7:	0f 84 b7 00 00 00    	je     801035a4 <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
801034ed:	83 ec 04             	sub    $0x4,%esp
801034f0:	68 2c 00 00 00       	push   $0x2c
801034f5:	68 60 a4 10 80       	push   $0x8010a460
801034fa:	50                   	push   %eax
801034fb:	e8 f9 2c 00 00       	call   801061f9 <inituvm>
  p->sz = PGSIZE;
80103500:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
80103506:	83 c4 0c             	add    $0xc,%esp
80103509:	6a 4c                	push   $0x4c
8010350b:	6a 00                	push   $0x0
8010350d:	ff 73 18             	pushl  0x18(%ebx)
80103510:	e8 df 09 00 00       	call   80103ef4 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80103515:	8b 43 18             	mov    0x18(%ebx),%eax
80103518:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
8010351e:	8b 43 18             	mov    0x18(%ebx),%eax
80103521:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
80103527:	8b 43 18             	mov    0x18(%ebx),%eax
8010352a:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
8010352e:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80103532:	8b 43 18             	mov    0x18(%ebx),%eax
80103535:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
80103539:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
8010353d:	8b 43 18             	mov    0x18(%ebx),%eax
80103540:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80103547:	8b 43 18             	mov    0x18(%ebx),%eax
8010354a:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80103551:	8b 43 18             	mov    0x18(%ebx),%eax
80103554:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
8010355b:	8d 43 6c             	lea    0x6c(%ebx),%eax
8010355e:	83 c4 0c             	add    $0xc,%esp
80103561:	6a 10                	push   $0x10
80103563:	68 e5 6c 10 80       	push   $0x80106ce5
80103568:	50                   	push   %eax
80103569:	e8 ed 0a 00 00       	call   8010405b <safestrcpy>
  p->cwd = namei("/");
8010356e:	c7 04 24 ee 6c 10 80 	movl   $0x80106cee,(%esp)
80103575:	e8 73 e6 ff ff       	call   80101bed <namei>
8010357a:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
8010357d:	c7 04 24 80 40 13 80 	movl   $0x80134080,(%esp)
80103584:	e8 bf 08 00 00       	call   80103e48 <acquire>
  p->state = RUNNABLE;
80103589:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
80103590:	c7 04 24 80 40 13 80 	movl   $0x80134080,(%esp)
80103597:	e8 11 09 00 00       	call   80103ead <release>
}
8010359c:	83 c4 10             	add    $0x10,%esp
8010359f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801035a2:	c9                   	leave  
801035a3:	c3                   	ret    
    panic("userinit: out of memory?");
801035a4:	83 ec 0c             	sub    $0xc,%esp
801035a7:	68 cc 6c 10 80       	push   $0x80106ccc
801035ac:	e8 97 cd ff ff       	call   80100348 <panic>

801035b1 <growproc>:
{
801035b1:	55                   	push   %ebp
801035b2:	89 e5                	mov    %esp,%ebp
801035b4:	56                   	push   %esi
801035b5:	53                   	push   %ebx
801035b6:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
801035b9:	e8 e8 fe ff ff       	call   801034a6 <myproc>
801035be:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
801035c0:	8b 00                	mov    (%eax),%eax
  if(n > 0){
801035c2:	85 f6                	test   %esi,%esi
801035c4:	7f 21                	jg     801035e7 <growproc+0x36>
  } else if(n < 0){
801035c6:	85 f6                	test   %esi,%esi
801035c8:	79 33                	jns    801035fd <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
801035ca:	83 ec 04             	sub    $0x4,%esp
801035cd:	01 c6                	add    %eax,%esi
801035cf:	56                   	push   %esi
801035d0:	50                   	push   %eax
801035d1:	ff 73 04             	pushl  0x4(%ebx)
801035d4:	e8 29 2d 00 00       	call   80106302 <deallocuvm>
801035d9:	83 c4 10             	add    $0x10,%esp
801035dc:	85 c0                	test   %eax,%eax
801035de:	75 1d                	jne    801035fd <growproc+0x4c>
      return -1;
801035e0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801035e5:	eb 29                	jmp    80103610 <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n, curproc->pid)) == 0)
801035e7:	ff 73 10             	pushl  0x10(%ebx)
801035ea:	01 c6                	add    %eax,%esi
801035ec:	56                   	push   %esi
801035ed:	50                   	push   %eax
801035ee:	ff 73 04             	pushl  0x4(%ebx)
801035f1:	e8 9e 2d 00 00       	call   80106394 <allocuvm>
801035f6:	83 c4 10             	add    $0x10,%esp
801035f9:	85 c0                	test   %eax,%eax
801035fb:	74 1a                	je     80103617 <growproc+0x66>
  curproc->sz = sz;
801035fd:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
801035ff:	83 ec 0c             	sub    $0xc,%esp
80103602:	53                   	push   %ebx
80103603:	e8 d9 2a 00 00       	call   801060e1 <switchuvm>
  return 0;
80103608:	83 c4 10             	add    $0x10,%esp
8010360b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103610:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103613:	5b                   	pop    %ebx
80103614:	5e                   	pop    %esi
80103615:	5d                   	pop    %ebp
80103616:	c3                   	ret    
      return -1;
80103617:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010361c:	eb f2                	jmp    80103610 <growproc+0x5f>

8010361e <fork>:
{
8010361e:	55                   	push   %ebp
8010361f:	89 e5                	mov    %esp,%ebp
80103621:	57                   	push   %edi
80103622:	56                   	push   %esi
80103623:	53                   	push   %ebx
80103624:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
80103627:	e8 7a fe ff ff       	call   801034a6 <myproc>
8010362c:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
8010362e:	e8 d8 fc ff ff       	call   8010330b <allocproc>
80103633:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80103636:	85 c0                	test   %eax,%eax
80103638:	0f 84 e3 00 00 00    	je     80103721 <fork+0x103>
8010363e:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz, np->pid)) == 0){
80103640:	83 ec 04             	sub    $0x4,%esp
80103643:	ff 70 10             	pushl  0x10(%eax)
80103646:	ff 33                	pushl  (%ebx)
80103648:	ff 73 04             	pushl  0x4(%ebx)
8010364b:	e8 58 2f 00 00       	call   801065a8 <copyuvm>
80103650:	89 47 04             	mov    %eax,0x4(%edi)
80103653:	83 c4 10             	add    $0x10,%esp
80103656:	85 c0                	test   %eax,%eax
80103658:	74 2a                	je     80103684 <fork+0x66>
  np->sz = curproc->sz;
8010365a:	8b 03                	mov    (%ebx),%eax
8010365c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
8010365f:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
80103661:	89 c8                	mov    %ecx,%eax
80103663:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
80103666:	8b 73 18             	mov    0x18(%ebx),%esi
80103669:	8b 79 18             	mov    0x18(%ecx),%edi
8010366c:	b9 13 00 00 00       	mov    $0x13,%ecx
80103671:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
80103673:	8b 40 18             	mov    0x18(%eax),%eax
80103676:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
8010367d:	be 00 00 00 00       	mov    $0x0,%esi
80103682:	eb 29                	jmp    801036ad <fork+0x8f>
    kfree(np->kstack);
80103684:	83 ec 0c             	sub    $0xc,%esp
80103687:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
8010368a:	ff 73 08             	pushl  0x8(%ebx)
8010368d:	e8 f2 e9 ff ff       	call   80102084 <kfree>
    np->kstack = 0;
80103692:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
80103699:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
801036a0:	83 c4 10             	add    $0x10,%esp
801036a3:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801036a8:	eb 6d                	jmp    80103717 <fork+0xf9>
  for(i = 0; i < NOFILE; i++)
801036aa:	83 c6 01             	add    $0x1,%esi
801036ad:	83 fe 0f             	cmp    $0xf,%esi
801036b0:	7f 1d                	jg     801036cf <fork+0xb1>
    if(curproc->ofile[i])
801036b2:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
801036b6:	85 c0                	test   %eax,%eax
801036b8:	74 f0                	je     801036aa <fork+0x8c>
      np->ofile[i] = filedup(curproc->ofile[i]);
801036ba:	83 ec 0c             	sub    $0xc,%esp
801036bd:	50                   	push   %eax
801036be:	e8 d7 d5 ff ff       	call   80100c9a <filedup>
801036c3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801036c6:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
801036ca:	83 c4 10             	add    $0x10,%esp
801036cd:	eb db                	jmp    801036aa <fork+0x8c>
  np->cwd = idup(curproc->cwd);
801036cf:	83 ec 0c             	sub    $0xc,%esp
801036d2:	ff 73 68             	pushl  0x68(%ebx)
801036d5:	e8 83 de ff ff       	call   8010155d <idup>
801036da:	8b 7d e4             	mov    -0x1c(%ebp),%edi
801036dd:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
801036e0:	83 c3 6c             	add    $0x6c,%ebx
801036e3:	8d 47 6c             	lea    0x6c(%edi),%eax
801036e6:	83 c4 0c             	add    $0xc,%esp
801036e9:	6a 10                	push   $0x10
801036eb:	53                   	push   %ebx
801036ec:	50                   	push   %eax
801036ed:	e8 69 09 00 00       	call   8010405b <safestrcpy>
  pid = np->pid;
801036f2:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
801036f5:	c7 04 24 80 40 13 80 	movl   $0x80134080,(%esp)
801036fc:	e8 47 07 00 00       	call   80103e48 <acquire>
  np->state = RUNNABLE;
80103701:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
80103708:	c7 04 24 80 40 13 80 	movl   $0x80134080,(%esp)
8010370f:	e8 99 07 00 00       	call   80103ead <release>
  return pid;
80103714:	83 c4 10             	add    $0x10,%esp
}
80103717:	89 d8                	mov    %ebx,%eax
80103719:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010371c:	5b                   	pop    %ebx
8010371d:	5e                   	pop    %esi
8010371e:	5f                   	pop    %edi
8010371f:	5d                   	pop    %ebp
80103720:	c3                   	ret    
    return -1;
80103721:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103726:	eb ef                	jmp    80103717 <fork+0xf9>

80103728 <scheduler>:
{
80103728:	55                   	push   %ebp
80103729:	89 e5                	mov    %esp,%ebp
8010372b:	56                   	push   %esi
8010372c:	53                   	push   %ebx
  struct cpu *c = mycpu();
8010372d:	e8 fd fc ff ff       	call   8010342f <mycpu>
80103732:	89 c6                	mov    %eax,%esi
  c->proc = 0;
80103734:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
8010373b:	00 00 00 
8010373e:	eb 5a                	jmp    8010379a <scheduler+0x72>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103740:	83 c3 7c             	add    $0x7c,%ebx
80103743:	81 fb b4 5f 13 80    	cmp    $0x80135fb4,%ebx
80103749:	73 3f                	jae    8010378a <scheduler+0x62>
      if(p->state != RUNNABLE)
8010374b:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
8010374f:	75 ef                	jne    80103740 <scheduler+0x18>
      c->proc = p;
80103751:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
80103757:	83 ec 0c             	sub    $0xc,%esp
8010375a:	53                   	push   %ebx
8010375b:	e8 81 29 00 00       	call   801060e1 <switchuvm>
      p->state = RUNNING;
80103760:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
80103767:	83 c4 08             	add    $0x8,%esp
8010376a:	ff 73 1c             	pushl  0x1c(%ebx)
8010376d:	8d 46 04             	lea    0x4(%esi),%eax
80103770:	50                   	push   %eax
80103771:	e8 38 09 00 00       	call   801040ae <swtch>
      switchkvm();
80103776:	e8 54 29 00 00       	call   801060cf <switchkvm>
      c->proc = 0;
8010377b:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
80103782:	00 00 00 
80103785:	83 c4 10             	add    $0x10,%esp
80103788:	eb b6                	jmp    80103740 <scheduler+0x18>
    release(&ptable.lock);
8010378a:	83 ec 0c             	sub    $0xc,%esp
8010378d:	68 80 40 13 80       	push   $0x80134080
80103792:	e8 16 07 00 00       	call   80103ead <release>
    sti();
80103797:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
8010379a:	fb                   	sti    
    acquire(&ptable.lock);
8010379b:	83 ec 0c             	sub    $0xc,%esp
8010379e:	68 80 40 13 80       	push   $0x80134080
801037a3:	e8 a0 06 00 00       	call   80103e48 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801037a8:	83 c4 10             	add    $0x10,%esp
801037ab:	bb b4 40 13 80       	mov    $0x801340b4,%ebx
801037b0:	eb 91                	jmp    80103743 <scheduler+0x1b>

801037b2 <sched>:
{
801037b2:	55                   	push   %ebp
801037b3:	89 e5                	mov    %esp,%ebp
801037b5:	56                   	push   %esi
801037b6:	53                   	push   %ebx
  struct proc *p = myproc();
801037b7:	e8 ea fc ff ff       	call   801034a6 <myproc>
801037bc:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
801037be:	83 ec 0c             	sub    $0xc,%esp
801037c1:	68 80 40 13 80       	push   $0x80134080
801037c6:	e8 3d 06 00 00       	call   80103e08 <holding>
801037cb:	83 c4 10             	add    $0x10,%esp
801037ce:	85 c0                	test   %eax,%eax
801037d0:	74 4f                	je     80103821 <sched+0x6f>
  if(mycpu()->ncli != 1)
801037d2:	e8 58 fc ff ff       	call   8010342f <mycpu>
801037d7:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
801037de:	75 4e                	jne    8010382e <sched+0x7c>
  if(p->state == RUNNING)
801037e0:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
801037e4:	74 55                	je     8010383b <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801037e6:	9c                   	pushf  
801037e7:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801037e8:	f6 c4 02             	test   $0x2,%ah
801037eb:	75 5b                	jne    80103848 <sched+0x96>
  intena = mycpu()->intena;
801037ed:	e8 3d fc ff ff       	call   8010342f <mycpu>
801037f2:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
801037f8:	e8 32 fc ff ff       	call   8010342f <mycpu>
801037fd:	83 ec 08             	sub    $0x8,%esp
80103800:	ff 70 04             	pushl  0x4(%eax)
80103803:	83 c3 1c             	add    $0x1c,%ebx
80103806:	53                   	push   %ebx
80103807:	e8 a2 08 00 00       	call   801040ae <swtch>
  mycpu()->intena = intena;
8010380c:	e8 1e fc ff ff       	call   8010342f <mycpu>
80103811:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
80103817:	83 c4 10             	add    $0x10,%esp
8010381a:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010381d:	5b                   	pop    %ebx
8010381e:	5e                   	pop    %esi
8010381f:	5d                   	pop    %ebp
80103820:	c3                   	ret    
    panic("sched ptable.lock");
80103821:	83 ec 0c             	sub    $0xc,%esp
80103824:	68 f0 6c 10 80       	push   $0x80106cf0
80103829:	e8 1a cb ff ff       	call   80100348 <panic>
    panic("sched locks");
8010382e:	83 ec 0c             	sub    $0xc,%esp
80103831:	68 02 6d 10 80       	push   $0x80106d02
80103836:	e8 0d cb ff ff       	call   80100348 <panic>
    panic("sched running");
8010383b:	83 ec 0c             	sub    $0xc,%esp
8010383e:	68 0e 6d 10 80       	push   $0x80106d0e
80103843:	e8 00 cb ff ff       	call   80100348 <panic>
    panic("sched interruptible");
80103848:	83 ec 0c             	sub    $0xc,%esp
8010384b:	68 1c 6d 10 80       	push   $0x80106d1c
80103850:	e8 f3 ca ff ff       	call   80100348 <panic>

80103855 <exit>:
{
80103855:	55                   	push   %ebp
80103856:	89 e5                	mov    %esp,%ebp
80103858:	56                   	push   %esi
80103859:	53                   	push   %ebx
  struct proc *curproc = myproc();
8010385a:	e8 47 fc ff ff       	call   801034a6 <myproc>
  if(curproc == initproc)
8010385f:	39 05 b8 a5 10 80    	cmp    %eax,0x8010a5b8
80103865:	74 09                	je     80103870 <exit+0x1b>
80103867:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
80103869:	bb 00 00 00 00       	mov    $0x0,%ebx
8010386e:	eb 10                	jmp    80103880 <exit+0x2b>
    panic("init exiting");
80103870:	83 ec 0c             	sub    $0xc,%esp
80103873:	68 30 6d 10 80       	push   $0x80106d30
80103878:	e8 cb ca ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
8010387d:	83 c3 01             	add    $0x1,%ebx
80103880:	83 fb 0f             	cmp    $0xf,%ebx
80103883:	7f 1e                	jg     801038a3 <exit+0x4e>
    if(curproc->ofile[fd]){
80103885:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
80103889:	85 c0                	test   %eax,%eax
8010388b:	74 f0                	je     8010387d <exit+0x28>
      fileclose(curproc->ofile[fd]);
8010388d:	83 ec 0c             	sub    $0xc,%esp
80103890:	50                   	push   %eax
80103891:	e8 49 d4 ff ff       	call   80100cdf <fileclose>
      curproc->ofile[fd] = 0;
80103896:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
8010389d:	00 
8010389e:	83 c4 10             	add    $0x10,%esp
801038a1:	eb da                	jmp    8010387d <exit+0x28>
  begin_op();
801038a3:	e8 a3 f1 ff ff       	call   80102a4b <begin_op>
  iput(curproc->cwd);
801038a8:	83 ec 0c             	sub    $0xc,%esp
801038ab:	ff 76 68             	pushl  0x68(%esi)
801038ae:	e8 e1 dd ff ff       	call   80101694 <iput>
  end_op();
801038b3:	e8 0d f2 ff ff       	call   80102ac5 <end_op>
  curproc->cwd = 0;
801038b8:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
801038bf:	c7 04 24 80 40 13 80 	movl   $0x80134080,(%esp)
801038c6:	e8 7d 05 00 00       	call   80103e48 <acquire>
  wakeup1(curproc->parent);
801038cb:	8b 46 14             	mov    0x14(%esi),%eax
801038ce:	e8 0d fa ff ff       	call   801032e0 <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801038d3:	83 c4 10             	add    $0x10,%esp
801038d6:	bb b4 40 13 80       	mov    $0x801340b4,%ebx
801038db:	eb 03                	jmp    801038e0 <exit+0x8b>
801038dd:	83 c3 7c             	add    $0x7c,%ebx
801038e0:	81 fb b4 5f 13 80    	cmp    $0x80135fb4,%ebx
801038e6:	73 1a                	jae    80103902 <exit+0xad>
    if(p->parent == curproc){
801038e8:	39 73 14             	cmp    %esi,0x14(%ebx)
801038eb:	75 f0                	jne    801038dd <exit+0x88>
      p->parent = initproc;
801038ed:	a1 b8 a5 10 80       	mov    0x8010a5b8,%eax
801038f2:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
801038f5:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
801038f9:	75 e2                	jne    801038dd <exit+0x88>
        wakeup1(initproc);
801038fb:	e8 e0 f9 ff ff       	call   801032e0 <wakeup1>
80103900:	eb db                	jmp    801038dd <exit+0x88>
  curproc->state = ZOMBIE;
80103902:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
80103909:	e8 a4 fe ff ff       	call   801037b2 <sched>
  panic("zombie exit");
8010390e:	83 ec 0c             	sub    $0xc,%esp
80103911:	68 3d 6d 10 80       	push   $0x80106d3d
80103916:	e8 2d ca ff ff       	call   80100348 <panic>

8010391b <yield>:
{
8010391b:	55                   	push   %ebp
8010391c:	89 e5                	mov    %esp,%ebp
8010391e:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80103921:	68 80 40 13 80       	push   $0x80134080
80103926:	e8 1d 05 00 00       	call   80103e48 <acquire>
  myproc()->state = RUNNABLE;
8010392b:	e8 76 fb ff ff       	call   801034a6 <myproc>
80103930:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80103937:	e8 76 fe ff ff       	call   801037b2 <sched>
  release(&ptable.lock);
8010393c:	c7 04 24 80 40 13 80 	movl   $0x80134080,(%esp)
80103943:	e8 65 05 00 00       	call   80103ead <release>
}
80103948:	83 c4 10             	add    $0x10,%esp
8010394b:	c9                   	leave  
8010394c:	c3                   	ret    

8010394d <sleep>:
{
8010394d:	55                   	push   %ebp
8010394e:	89 e5                	mov    %esp,%ebp
80103950:	56                   	push   %esi
80103951:	53                   	push   %ebx
80103952:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
80103955:	e8 4c fb ff ff       	call   801034a6 <myproc>
  if(p == 0)
8010395a:	85 c0                	test   %eax,%eax
8010395c:	74 66                	je     801039c4 <sleep+0x77>
8010395e:	89 c6                	mov    %eax,%esi
  if(lk == 0)
80103960:	85 db                	test   %ebx,%ebx
80103962:	74 6d                	je     801039d1 <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
80103964:	81 fb 80 40 13 80    	cmp    $0x80134080,%ebx
8010396a:	74 18                	je     80103984 <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
8010396c:	83 ec 0c             	sub    $0xc,%esp
8010396f:	68 80 40 13 80       	push   $0x80134080
80103974:	e8 cf 04 00 00       	call   80103e48 <acquire>
    release(lk);
80103979:	89 1c 24             	mov    %ebx,(%esp)
8010397c:	e8 2c 05 00 00       	call   80103ead <release>
80103981:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
80103984:	8b 45 08             	mov    0x8(%ebp),%eax
80103987:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
8010398a:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
80103991:	e8 1c fe ff ff       	call   801037b2 <sched>
  p->chan = 0;
80103996:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
8010399d:	81 fb 80 40 13 80    	cmp    $0x80134080,%ebx
801039a3:	74 18                	je     801039bd <sleep+0x70>
    release(&ptable.lock);
801039a5:	83 ec 0c             	sub    $0xc,%esp
801039a8:	68 80 40 13 80       	push   $0x80134080
801039ad:	e8 fb 04 00 00       	call   80103ead <release>
    acquire(lk);
801039b2:	89 1c 24             	mov    %ebx,(%esp)
801039b5:	e8 8e 04 00 00       	call   80103e48 <acquire>
801039ba:	83 c4 10             	add    $0x10,%esp
}
801039bd:	8d 65 f8             	lea    -0x8(%ebp),%esp
801039c0:	5b                   	pop    %ebx
801039c1:	5e                   	pop    %esi
801039c2:	5d                   	pop    %ebp
801039c3:	c3                   	ret    
    panic("sleep");
801039c4:	83 ec 0c             	sub    $0xc,%esp
801039c7:	68 49 6d 10 80       	push   $0x80106d49
801039cc:	e8 77 c9 ff ff       	call   80100348 <panic>
    panic("sleep without lk");
801039d1:	83 ec 0c             	sub    $0xc,%esp
801039d4:	68 4f 6d 10 80       	push   $0x80106d4f
801039d9:	e8 6a c9 ff ff       	call   80100348 <panic>

801039de <wait>:
{
801039de:	55                   	push   %ebp
801039df:	89 e5                	mov    %esp,%ebp
801039e1:	56                   	push   %esi
801039e2:	53                   	push   %ebx
  struct proc *curproc = myproc();
801039e3:	e8 be fa ff ff       	call   801034a6 <myproc>
801039e8:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
801039ea:	83 ec 0c             	sub    $0xc,%esp
801039ed:	68 80 40 13 80       	push   $0x80134080
801039f2:	e8 51 04 00 00       	call   80103e48 <acquire>
801039f7:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
801039fa:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039ff:	bb b4 40 13 80       	mov    $0x801340b4,%ebx
80103a04:	eb 5b                	jmp    80103a61 <wait+0x83>
        pid = p->pid;
80103a06:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
80103a09:	83 ec 0c             	sub    $0xc,%esp
80103a0c:	ff 73 08             	pushl  0x8(%ebx)
80103a0f:	e8 70 e6 ff ff       	call   80102084 <kfree>
        p->kstack = 0;
80103a14:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
80103a1b:	83 c4 04             	add    $0x4,%esp
80103a1e:	ff 73 04             	pushl  0x4(%ebx)
80103a21:	e8 61 2a 00 00       	call   80106487 <freevm>
        p->pid = 0;
80103a26:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
80103a2d:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
80103a34:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
80103a38:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
80103a3f:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
80103a46:	c7 04 24 80 40 13 80 	movl   $0x80134080,(%esp)
80103a4d:	e8 5b 04 00 00       	call   80103ead <release>
        return pid;
80103a52:	83 c4 10             	add    $0x10,%esp
}
80103a55:	89 f0                	mov    %esi,%eax
80103a57:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a5a:	5b                   	pop    %ebx
80103a5b:	5e                   	pop    %esi
80103a5c:	5d                   	pop    %ebp
80103a5d:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103a5e:	83 c3 7c             	add    $0x7c,%ebx
80103a61:	81 fb b4 5f 13 80    	cmp    $0x80135fb4,%ebx
80103a67:	73 12                	jae    80103a7b <wait+0x9d>
      if(p->parent != curproc)
80103a69:	39 73 14             	cmp    %esi,0x14(%ebx)
80103a6c:	75 f0                	jne    80103a5e <wait+0x80>
      if(p->state == ZOMBIE){
80103a6e:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103a72:	74 92                	je     80103a06 <wait+0x28>
      havekids = 1;
80103a74:	b8 01 00 00 00       	mov    $0x1,%eax
80103a79:	eb e3                	jmp    80103a5e <wait+0x80>
    if(!havekids || curproc->killed){
80103a7b:	85 c0                	test   %eax,%eax
80103a7d:	74 06                	je     80103a85 <wait+0xa7>
80103a7f:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
80103a83:	74 17                	je     80103a9c <wait+0xbe>
      release(&ptable.lock);
80103a85:	83 ec 0c             	sub    $0xc,%esp
80103a88:	68 80 40 13 80       	push   $0x80134080
80103a8d:	e8 1b 04 00 00       	call   80103ead <release>
      return -1;
80103a92:	83 c4 10             	add    $0x10,%esp
80103a95:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103a9a:	eb b9                	jmp    80103a55 <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80103a9c:	83 ec 08             	sub    $0x8,%esp
80103a9f:	68 80 40 13 80       	push   $0x80134080
80103aa4:	56                   	push   %esi
80103aa5:	e8 a3 fe ff ff       	call   8010394d <sleep>
    havekids = 0;
80103aaa:	83 c4 10             	add    $0x10,%esp
80103aad:	e9 48 ff ff ff       	jmp    801039fa <wait+0x1c>

80103ab2 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80103ab2:	55                   	push   %ebp
80103ab3:	89 e5                	mov    %esp,%ebp
80103ab5:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
80103ab8:	68 80 40 13 80       	push   $0x80134080
80103abd:	e8 86 03 00 00       	call   80103e48 <acquire>
  wakeup1(chan);
80103ac2:	8b 45 08             	mov    0x8(%ebp),%eax
80103ac5:	e8 16 f8 ff ff       	call   801032e0 <wakeup1>
  release(&ptable.lock);
80103aca:	c7 04 24 80 40 13 80 	movl   $0x80134080,(%esp)
80103ad1:	e8 d7 03 00 00       	call   80103ead <release>
}
80103ad6:	83 c4 10             	add    $0x10,%esp
80103ad9:	c9                   	leave  
80103ada:	c3                   	ret    

80103adb <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80103adb:	55                   	push   %ebp
80103adc:	89 e5                	mov    %esp,%ebp
80103ade:	53                   	push   %ebx
80103adf:	83 ec 10             	sub    $0x10,%esp
80103ae2:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
80103ae5:	68 80 40 13 80       	push   $0x80134080
80103aea:	e8 59 03 00 00       	call   80103e48 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103aef:	83 c4 10             	add    $0x10,%esp
80103af2:	b8 b4 40 13 80       	mov    $0x801340b4,%eax
80103af7:	3d b4 5f 13 80       	cmp    $0x80135fb4,%eax
80103afc:	73 3a                	jae    80103b38 <kill+0x5d>
    if(p->pid == pid){
80103afe:	39 58 10             	cmp    %ebx,0x10(%eax)
80103b01:	74 05                	je     80103b08 <kill+0x2d>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103b03:	83 c0 7c             	add    $0x7c,%eax
80103b06:	eb ef                	jmp    80103af7 <kill+0x1c>
      p->killed = 1;
80103b08:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80103b0f:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
80103b13:	74 1a                	je     80103b2f <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
80103b15:	83 ec 0c             	sub    $0xc,%esp
80103b18:	68 80 40 13 80       	push   $0x80134080
80103b1d:	e8 8b 03 00 00       	call   80103ead <release>
      return 0;
80103b22:	83 c4 10             	add    $0x10,%esp
80103b25:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
80103b2a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103b2d:	c9                   	leave  
80103b2e:	c3                   	ret    
        p->state = RUNNABLE;
80103b2f:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80103b36:	eb dd                	jmp    80103b15 <kill+0x3a>
  release(&ptable.lock);
80103b38:	83 ec 0c             	sub    $0xc,%esp
80103b3b:	68 80 40 13 80       	push   $0x80134080
80103b40:	e8 68 03 00 00       	call   80103ead <release>
  return -1;
80103b45:	83 c4 10             	add    $0x10,%esp
80103b48:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103b4d:	eb db                	jmp    80103b2a <kill+0x4f>

80103b4f <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80103b4f:	55                   	push   %ebp
80103b50:	89 e5                	mov    %esp,%ebp
80103b52:	56                   	push   %esi
80103b53:	53                   	push   %ebx
80103b54:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103b57:	bb b4 40 13 80       	mov    $0x801340b4,%ebx
80103b5c:	eb 33                	jmp    80103b91 <procdump+0x42>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103b5e:	b8 60 6d 10 80       	mov    $0x80106d60,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
80103b63:	8d 53 6c             	lea    0x6c(%ebx),%edx
80103b66:	52                   	push   %edx
80103b67:	50                   	push   %eax
80103b68:	ff 73 10             	pushl  0x10(%ebx)
80103b6b:	68 64 6d 10 80       	push   $0x80106d64
80103b70:	e8 96 ca ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
80103b75:	83 c4 10             	add    $0x10,%esp
80103b78:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103b7c:	74 39                	je     80103bb7 <procdump+0x68>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103b7e:	83 ec 0c             	sub    $0xc,%esp
80103b81:	68 db 70 10 80       	push   $0x801070db
80103b86:	e8 80 ca ff ff       	call   8010060b <cprintf>
80103b8b:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103b8e:	83 c3 7c             	add    $0x7c,%ebx
80103b91:	81 fb b4 5f 13 80    	cmp    $0x80135fb4,%ebx
80103b97:	73 61                	jae    80103bfa <procdump+0xab>
    if(p->state == UNUSED)
80103b99:	8b 43 0c             	mov    0xc(%ebx),%eax
80103b9c:	85 c0                	test   %eax,%eax
80103b9e:	74 ee                	je     80103b8e <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103ba0:	83 f8 05             	cmp    $0x5,%eax
80103ba3:	77 b9                	ja     80103b5e <procdump+0xf>
80103ba5:	8b 04 85 c0 6d 10 80 	mov    -0x7fef9240(,%eax,4),%eax
80103bac:	85 c0                	test   %eax,%eax
80103bae:	75 b3                	jne    80103b63 <procdump+0x14>
      state = "???";
80103bb0:	b8 60 6d 10 80       	mov    $0x80106d60,%eax
80103bb5:	eb ac                	jmp    80103b63 <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80103bb7:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103bba:	8b 40 0c             	mov    0xc(%eax),%eax
80103bbd:	83 c0 08             	add    $0x8,%eax
80103bc0:	83 ec 08             	sub    $0x8,%esp
80103bc3:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103bc6:	52                   	push   %edx
80103bc7:	50                   	push   %eax
80103bc8:	e8 5a 01 00 00       	call   80103d27 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103bcd:	83 c4 10             	add    $0x10,%esp
80103bd0:	be 00 00 00 00       	mov    $0x0,%esi
80103bd5:	eb 14                	jmp    80103beb <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103bd7:	83 ec 08             	sub    $0x8,%esp
80103bda:	50                   	push   %eax
80103bdb:	68 a1 67 10 80       	push   $0x801067a1
80103be0:	e8 26 ca ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103be5:	83 c6 01             	add    $0x1,%esi
80103be8:	83 c4 10             	add    $0x10,%esp
80103beb:	83 fe 09             	cmp    $0x9,%esi
80103bee:	7f 8e                	jg     80103b7e <procdump+0x2f>
80103bf0:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103bf4:	85 c0                	test   %eax,%eax
80103bf6:	75 df                	jne    80103bd7 <procdump+0x88>
80103bf8:	eb 84                	jmp    80103b7e <procdump+0x2f>
  }
80103bfa:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103bfd:	5b                   	pop    %ebx
80103bfe:	5e                   	pop    %esi
80103bff:	5d                   	pop    %ebp
80103c00:	c3                   	ret    

80103c01 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103c01:	55                   	push   %ebp
80103c02:	89 e5                	mov    %esp,%ebp
80103c04:	53                   	push   %ebx
80103c05:	83 ec 0c             	sub    $0xc,%esp
80103c08:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103c0b:	68 d8 6d 10 80       	push   $0x80106dd8
80103c10:	8d 43 04             	lea    0x4(%ebx),%eax
80103c13:	50                   	push   %eax
80103c14:	e8 f3 00 00 00       	call   80103d0c <initlock>
  lk->name = name;
80103c19:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c1c:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103c1f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103c25:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103c2c:	83 c4 10             	add    $0x10,%esp
80103c2f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103c32:	c9                   	leave  
80103c33:	c3                   	ret    

80103c34 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103c34:	55                   	push   %ebp
80103c35:	89 e5                	mov    %esp,%ebp
80103c37:	56                   	push   %esi
80103c38:	53                   	push   %ebx
80103c39:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103c3c:	8d 73 04             	lea    0x4(%ebx),%esi
80103c3f:	83 ec 0c             	sub    $0xc,%esp
80103c42:	56                   	push   %esi
80103c43:	e8 00 02 00 00       	call   80103e48 <acquire>
  while (lk->locked) {
80103c48:	83 c4 10             	add    $0x10,%esp
80103c4b:	eb 0d                	jmp    80103c5a <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103c4d:	83 ec 08             	sub    $0x8,%esp
80103c50:	56                   	push   %esi
80103c51:	53                   	push   %ebx
80103c52:	e8 f6 fc ff ff       	call   8010394d <sleep>
80103c57:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103c5a:	83 3b 00             	cmpl   $0x0,(%ebx)
80103c5d:	75 ee                	jne    80103c4d <acquiresleep+0x19>
  }
  lk->locked = 1;
80103c5f:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103c65:	e8 3c f8 ff ff       	call   801034a6 <myproc>
80103c6a:	8b 40 10             	mov    0x10(%eax),%eax
80103c6d:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103c70:	83 ec 0c             	sub    $0xc,%esp
80103c73:	56                   	push   %esi
80103c74:	e8 34 02 00 00       	call   80103ead <release>
}
80103c79:	83 c4 10             	add    $0x10,%esp
80103c7c:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103c7f:	5b                   	pop    %ebx
80103c80:	5e                   	pop    %esi
80103c81:	5d                   	pop    %ebp
80103c82:	c3                   	ret    

80103c83 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103c83:	55                   	push   %ebp
80103c84:	89 e5                	mov    %esp,%ebp
80103c86:	56                   	push   %esi
80103c87:	53                   	push   %ebx
80103c88:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103c8b:	8d 73 04             	lea    0x4(%ebx),%esi
80103c8e:	83 ec 0c             	sub    $0xc,%esp
80103c91:	56                   	push   %esi
80103c92:	e8 b1 01 00 00       	call   80103e48 <acquire>
  lk->locked = 0;
80103c97:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103c9d:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103ca4:	89 1c 24             	mov    %ebx,(%esp)
80103ca7:	e8 06 fe ff ff       	call   80103ab2 <wakeup>
  release(&lk->lk);
80103cac:	89 34 24             	mov    %esi,(%esp)
80103caf:	e8 f9 01 00 00       	call   80103ead <release>
}
80103cb4:	83 c4 10             	add    $0x10,%esp
80103cb7:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103cba:	5b                   	pop    %ebx
80103cbb:	5e                   	pop    %esi
80103cbc:	5d                   	pop    %ebp
80103cbd:	c3                   	ret    

80103cbe <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103cbe:	55                   	push   %ebp
80103cbf:	89 e5                	mov    %esp,%ebp
80103cc1:	56                   	push   %esi
80103cc2:	53                   	push   %ebx
80103cc3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103cc6:	8d 73 04             	lea    0x4(%ebx),%esi
80103cc9:	83 ec 0c             	sub    $0xc,%esp
80103ccc:	56                   	push   %esi
80103ccd:	e8 76 01 00 00       	call   80103e48 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103cd2:	83 c4 10             	add    $0x10,%esp
80103cd5:	83 3b 00             	cmpl   $0x0,(%ebx)
80103cd8:	75 17                	jne    80103cf1 <holdingsleep+0x33>
80103cda:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103cdf:	83 ec 0c             	sub    $0xc,%esp
80103ce2:	56                   	push   %esi
80103ce3:	e8 c5 01 00 00       	call   80103ead <release>
  return r;
}
80103ce8:	89 d8                	mov    %ebx,%eax
80103cea:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103ced:	5b                   	pop    %ebx
80103cee:	5e                   	pop    %esi
80103cef:	5d                   	pop    %ebp
80103cf0:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103cf1:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103cf4:	e8 ad f7 ff ff       	call   801034a6 <myproc>
80103cf9:	3b 58 10             	cmp    0x10(%eax),%ebx
80103cfc:	74 07                	je     80103d05 <holdingsleep+0x47>
80103cfe:	bb 00 00 00 00       	mov    $0x0,%ebx
80103d03:	eb da                	jmp    80103cdf <holdingsleep+0x21>
80103d05:	bb 01 00 00 00       	mov    $0x1,%ebx
80103d0a:	eb d3                	jmp    80103cdf <holdingsleep+0x21>

80103d0c <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103d0c:	55                   	push   %ebp
80103d0d:	89 e5                	mov    %esp,%ebp
80103d0f:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103d12:	8b 55 0c             	mov    0xc(%ebp),%edx
80103d15:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103d18:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103d1e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103d25:	5d                   	pop    %ebp
80103d26:	c3                   	ret    

80103d27 <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103d27:	55                   	push   %ebp
80103d28:	89 e5                	mov    %esp,%ebp
80103d2a:	53                   	push   %ebx
80103d2b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103d2e:	8b 45 08             	mov    0x8(%ebp),%eax
80103d31:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103d34:	b8 00 00 00 00       	mov    $0x0,%eax
80103d39:	83 f8 09             	cmp    $0x9,%eax
80103d3c:	7f 25                	jg     80103d63 <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103d3e:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103d44:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103d4a:	77 17                	ja     80103d63 <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103d4c:	8b 5a 04             	mov    0x4(%edx),%ebx
80103d4f:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103d52:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103d54:	83 c0 01             	add    $0x1,%eax
80103d57:	eb e0                	jmp    80103d39 <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103d59:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103d60:	83 c0 01             	add    $0x1,%eax
80103d63:	83 f8 09             	cmp    $0x9,%eax
80103d66:	7e f1                	jle    80103d59 <getcallerpcs+0x32>
}
80103d68:	5b                   	pop    %ebx
80103d69:	5d                   	pop    %ebp
80103d6a:	c3                   	ret    

80103d6b <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103d6b:	55                   	push   %ebp
80103d6c:	89 e5                	mov    %esp,%ebp
80103d6e:	53                   	push   %ebx
80103d6f:	83 ec 04             	sub    $0x4,%esp
80103d72:	9c                   	pushf  
80103d73:	5b                   	pop    %ebx
  asm volatile("cli");
80103d74:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103d75:	e8 b5 f6 ff ff       	call   8010342f <mycpu>
80103d7a:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103d81:	74 12                	je     80103d95 <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103d83:	e8 a7 f6 ff ff       	call   8010342f <mycpu>
80103d88:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103d8f:	83 c4 04             	add    $0x4,%esp
80103d92:	5b                   	pop    %ebx
80103d93:	5d                   	pop    %ebp
80103d94:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103d95:	e8 95 f6 ff ff       	call   8010342f <mycpu>
80103d9a:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103da0:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103da6:	eb db                	jmp    80103d83 <pushcli+0x18>

80103da8 <popcli>:

void
popcli(void)
{
80103da8:	55                   	push   %ebp
80103da9:	89 e5                	mov    %esp,%ebp
80103dab:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103dae:	9c                   	pushf  
80103daf:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103db0:	f6 c4 02             	test   $0x2,%ah
80103db3:	75 28                	jne    80103ddd <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103db5:	e8 75 f6 ff ff       	call   8010342f <mycpu>
80103dba:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103dc0:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103dc3:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103dc9:	85 d2                	test   %edx,%edx
80103dcb:	78 1d                	js     80103dea <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103dcd:	e8 5d f6 ff ff       	call   8010342f <mycpu>
80103dd2:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103dd9:	74 1c                	je     80103df7 <popcli+0x4f>
    sti();
}
80103ddb:	c9                   	leave  
80103ddc:	c3                   	ret    
    panic("popcli - interruptible");
80103ddd:	83 ec 0c             	sub    $0xc,%esp
80103de0:	68 e3 6d 10 80       	push   $0x80106de3
80103de5:	e8 5e c5 ff ff       	call   80100348 <panic>
    panic("popcli");
80103dea:	83 ec 0c             	sub    $0xc,%esp
80103ded:	68 fa 6d 10 80       	push   $0x80106dfa
80103df2:	e8 51 c5 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103df7:	e8 33 f6 ff ff       	call   8010342f <mycpu>
80103dfc:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103e03:	74 d6                	je     80103ddb <popcli+0x33>
  asm volatile("sti");
80103e05:	fb                   	sti    
}
80103e06:	eb d3                	jmp    80103ddb <popcli+0x33>

80103e08 <holding>:
{
80103e08:	55                   	push   %ebp
80103e09:	89 e5                	mov    %esp,%ebp
80103e0b:	53                   	push   %ebx
80103e0c:	83 ec 04             	sub    $0x4,%esp
80103e0f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103e12:	e8 54 ff ff ff       	call   80103d6b <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103e17:	83 3b 00             	cmpl   $0x0,(%ebx)
80103e1a:	75 12                	jne    80103e2e <holding+0x26>
80103e1c:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103e21:	e8 82 ff ff ff       	call   80103da8 <popcli>
}
80103e26:	89 d8                	mov    %ebx,%eax
80103e28:	83 c4 04             	add    $0x4,%esp
80103e2b:	5b                   	pop    %ebx
80103e2c:	5d                   	pop    %ebp
80103e2d:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103e2e:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103e31:	e8 f9 f5 ff ff       	call   8010342f <mycpu>
80103e36:	39 c3                	cmp    %eax,%ebx
80103e38:	74 07                	je     80103e41 <holding+0x39>
80103e3a:	bb 00 00 00 00       	mov    $0x0,%ebx
80103e3f:	eb e0                	jmp    80103e21 <holding+0x19>
80103e41:	bb 01 00 00 00       	mov    $0x1,%ebx
80103e46:	eb d9                	jmp    80103e21 <holding+0x19>

80103e48 <acquire>:
{
80103e48:	55                   	push   %ebp
80103e49:	89 e5                	mov    %esp,%ebp
80103e4b:	53                   	push   %ebx
80103e4c:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103e4f:	e8 17 ff ff ff       	call   80103d6b <pushcli>
  if(holding(lk))
80103e54:	83 ec 0c             	sub    $0xc,%esp
80103e57:	ff 75 08             	pushl  0x8(%ebp)
80103e5a:	e8 a9 ff ff ff       	call   80103e08 <holding>
80103e5f:	83 c4 10             	add    $0x10,%esp
80103e62:	85 c0                	test   %eax,%eax
80103e64:	75 3a                	jne    80103ea0 <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103e66:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103e69:	b8 01 00 00 00       	mov    $0x1,%eax
80103e6e:	f0 87 02             	lock xchg %eax,(%edx)
80103e71:	85 c0                	test   %eax,%eax
80103e73:	75 f1                	jne    80103e66 <acquire+0x1e>
  __sync_synchronize();
80103e75:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103e7a:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103e7d:	e8 ad f5 ff ff       	call   8010342f <mycpu>
80103e82:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103e85:	8b 45 08             	mov    0x8(%ebp),%eax
80103e88:	83 c0 0c             	add    $0xc,%eax
80103e8b:	83 ec 08             	sub    $0x8,%esp
80103e8e:	50                   	push   %eax
80103e8f:	8d 45 08             	lea    0x8(%ebp),%eax
80103e92:	50                   	push   %eax
80103e93:	e8 8f fe ff ff       	call   80103d27 <getcallerpcs>
}
80103e98:	83 c4 10             	add    $0x10,%esp
80103e9b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103e9e:	c9                   	leave  
80103e9f:	c3                   	ret    
    panic("acquire");
80103ea0:	83 ec 0c             	sub    $0xc,%esp
80103ea3:	68 01 6e 10 80       	push   $0x80106e01
80103ea8:	e8 9b c4 ff ff       	call   80100348 <panic>

80103ead <release>:
{
80103ead:	55                   	push   %ebp
80103eae:	89 e5                	mov    %esp,%ebp
80103eb0:	53                   	push   %ebx
80103eb1:	83 ec 10             	sub    $0x10,%esp
80103eb4:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103eb7:	53                   	push   %ebx
80103eb8:	e8 4b ff ff ff       	call   80103e08 <holding>
80103ebd:	83 c4 10             	add    $0x10,%esp
80103ec0:	85 c0                	test   %eax,%eax
80103ec2:	74 23                	je     80103ee7 <release+0x3a>
  lk->pcs[0] = 0;
80103ec4:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103ecb:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103ed2:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103ed7:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103edd:	e8 c6 fe ff ff       	call   80103da8 <popcli>
}
80103ee2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103ee5:	c9                   	leave  
80103ee6:	c3                   	ret    
    panic("release");
80103ee7:	83 ec 0c             	sub    $0xc,%esp
80103eea:	68 09 6e 10 80       	push   $0x80106e09
80103eef:	e8 54 c4 ff ff       	call   80100348 <panic>

80103ef4 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103ef4:	55                   	push   %ebp
80103ef5:	89 e5                	mov    %esp,%ebp
80103ef7:	57                   	push   %edi
80103ef8:	53                   	push   %ebx
80103ef9:	8b 55 08             	mov    0x8(%ebp),%edx
80103efc:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103eff:	f6 c2 03             	test   $0x3,%dl
80103f02:	75 05                	jne    80103f09 <memset+0x15>
80103f04:	f6 c1 03             	test   $0x3,%cl
80103f07:	74 0e                	je     80103f17 <memset+0x23>
  asm volatile("cld; rep stosb" :
80103f09:	89 d7                	mov    %edx,%edi
80103f0b:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f0e:	fc                   	cld    
80103f0f:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103f11:	89 d0                	mov    %edx,%eax
80103f13:	5b                   	pop    %ebx
80103f14:	5f                   	pop    %edi
80103f15:	5d                   	pop    %ebp
80103f16:	c3                   	ret    
    c &= 0xFF;
80103f17:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103f1b:	c1 e9 02             	shr    $0x2,%ecx
80103f1e:	89 f8                	mov    %edi,%eax
80103f20:	c1 e0 18             	shl    $0x18,%eax
80103f23:	89 fb                	mov    %edi,%ebx
80103f25:	c1 e3 10             	shl    $0x10,%ebx
80103f28:	09 d8                	or     %ebx,%eax
80103f2a:	89 fb                	mov    %edi,%ebx
80103f2c:	c1 e3 08             	shl    $0x8,%ebx
80103f2f:	09 d8                	or     %ebx,%eax
80103f31:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103f33:	89 d7                	mov    %edx,%edi
80103f35:	fc                   	cld    
80103f36:	f3 ab                	rep stos %eax,%es:(%edi)
80103f38:	eb d7                	jmp    80103f11 <memset+0x1d>

80103f3a <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103f3a:	55                   	push   %ebp
80103f3b:	89 e5                	mov    %esp,%ebp
80103f3d:	56                   	push   %esi
80103f3e:	53                   	push   %ebx
80103f3f:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103f42:	8b 55 0c             	mov    0xc(%ebp),%edx
80103f45:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103f48:	8d 70 ff             	lea    -0x1(%eax),%esi
80103f4b:	85 c0                	test   %eax,%eax
80103f4d:	74 1c                	je     80103f6b <memcmp+0x31>
    if(*s1 != *s2)
80103f4f:	0f b6 01             	movzbl (%ecx),%eax
80103f52:	0f b6 1a             	movzbl (%edx),%ebx
80103f55:	38 d8                	cmp    %bl,%al
80103f57:	75 0a                	jne    80103f63 <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103f59:	83 c1 01             	add    $0x1,%ecx
80103f5c:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103f5f:	89 f0                	mov    %esi,%eax
80103f61:	eb e5                	jmp    80103f48 <memcmp+0xe>
      return *s1 - *s2;
80103f63:	0f b6 c0             	movzbl %al,%eax
80103f66:	0f b6 db             	movzbl %bl,%ebx
80103f69:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103f6b:	5b                   	pop    %ebx
80103f6c:	5e                   	pop    %esi
80103f6d:	5d                   	pop    %ebp
80103f6e:	c3                   	ret    

80103f6f <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103f6f:	55                   	push   %ebp
80103f70:	89 e5                	mov    %esp,%ebp
80103f72:	56                   	push   %esi
80103f73:	53                   	push   %ebx
80103f74:	8b 45 08             	mov    0x8(%ebp),%eax
80103f77:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103f7a:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103f7d:	39 c1                	cmp    %eax,%ecx
80103f7f:	73 3a                	jae    80103fbb <memmove+0x4c>
80103f81:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103f84:	39 c3                	cmp    %eax,%ebx
80103f86:	76 37                	jbe    80103fbf <memmove+0x50>
    s += n;
    d += n;
80103f88:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103f8b:	eb 0d                	jmp    80103f9a <memmove+0x2b>
      *--d = *--s;
80103f8d:	83 eb 01             	sub    $0x1,%ebx
80103f90:	83 e9 01             	sub    $0x1,%ecx
80103f93:	0f b6 13             	movzbl (%ebx),%edx
80103f96:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103f98:	89 f2                	mov    %esi,%edx
80103f9a:	8d 72 ff             	lea    -0x1(%edx),%esi
80103f9d:	85 d2                	test   %edx,%edx
80103f9f:	75 ec                	jne    80103f8d <memmove+0x1e>
80103fa1:	eb 14                	jmp    80103fb7 <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103fa3:	0f b6 11             	movzbl (%ecx),%edx
80103fa6:	88 13                	mov    %dl,(%ebx)
80103fa8:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103fab:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103fae:	89 f2                	mov    %esi,%edx
80103fb0:	8d 72 ff             	lea    -0x1(%edx),%esi
80103fb3:	85 d2                	test   %edx,%edx
80103fb5:	75 ec                	jne    80103fa3 <memmove+0x34>

  return dst;
}
80103fb7:	5b                   	pop    %ebx
80103fb8:	5e                   	pop    %esi
80103fb9:	5d                   	pop    %ebp
80103fba:	c3                   	ret    
80103fbb:	89 c3                	mov    %eax,%ebx
80103fbd:	eb f1                	jmp    80103fb0 <memmove+0x41>
80103fbf:	89 c3                	mov    %eax,%ebx
80103fc1:	eb ed                	jmp    80103fb0 <memmove+0x41>

80103fc3 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103fc3:	55                   	push   %ebp
80103fc4:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80103fc6:	ff 75 10             	pushl  0x10(%ebp)
80103fc9:	ff 75 0c             	pushl  0xc(%ebp)
80103fcc:	ff 75 08             	pushl  0x8(%ebp)
80103fcf:	e8 9b ff ff ff       	call   80103f6f <memmove>
}
80103fd4:	c9                   	leave  
80103fd5:	c3                   	ret    

80103fd6 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103fd6:	55                   	push   %ebp
80103fd7:	89 e5                	mov    %esp,%ebp
80103fd9:	53                   	push   %ebx
80103fda:	8b 55 08             	mov    0x8(%ebp),%edx
80103fdd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103fe0:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103fe3:	eb 09                	jmp    80103fee <strncmp+0x18>
    n--, p++, q++;
80103fe5:	83 e8 01             	sub    $0x1,%eax
80103fe8:	83 c2 01             	add    $0x1,%edx
80103feb:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103fee:	85 c0                	test   %eax,%eax
80103ff0:	74 0b                	je     80103ffd <strncmp+0x27>
80103ff2:	0f b6 1a             	movzbl (%edx),%ebx
80103ff5:	84 db                	test   %bl,%bl
80103ff7:	74 04                	je     80103ffd <strncmp+0x27>
80103ff9:	3a 19                	cmp    (%ecx),%bl
80103ffb:	74 e8                	je     80103fe5 <strncmp+0xf>
  if(n == 0)
80103ffd:	85 c0                	test   %eax,%eax
80103fff:	74 0b                	je     8010400c <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80104001:	0f b6 02             	movzbl (%edx),%eax
80104004:	0f b6 11             	movzbl (%ecx),%edx
80104007:	29 d0                	sub    %edx,%eax
}
80104009:	5b                   	pop    %ebx
8010400a:	5d                   	pop    %ebp
8010400b:	c3                   	ret    
    return 0;
8010400c:	b8 00 00 00 00       	mov    $0x0,%eax
80104011:	eb f6                	jmp    80104009 <strncmp+0x33>

80104013 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80104013:	55                   	push   %ebp
80104014:	89 e5                	mov    %esp,%ebp
80104016:	57                   	push   %edi
80104017:	56                   	push   %esi
80104018:	53                   	push   %ebx
80104019:	8b 5d 0c             	mov    0xc(%ebp),%ebx
8010401c:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
8010401f:	8b 45 08             	mov    0x8(%ebp),%eax
80104022:	eb 04                	jmp    80104028 <strncpy+0x15>
80104024:	89 fb                	mov    %edi,%ebx
80104026:	89 f0                	mov    %esi,%eax
80104028:	8d 51 ff             	lea    -0x1(%ecx),%edx
8010402b:	85 c9                	test   %ecx,%ecx
8010402d:	7e 1d                	jle    8010404c <strncpy+0x39>
8010402f:	8d 7b 01             	lea    0x1(%ebx),%edi
80104032:	8d 70 01             	lea    0x1(%eax),%esi
80104035:	0f b6 1b             	movzbl (%ebx),%ebx
80104038:	88 18                	mov    %bl,(%eax)
8010403a:	89 d1                	mov    %edx,%ecx
8010403c:	84 db                	test   %bl,%bl
8010403e:	75 e4                	jne    80104024 <strncpy+0x11>
80104040:	89 f0                	mov    %esi,%eax
80104042:	eb 08                	jmp    8010404c <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80104044:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80104047:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80104049:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
8010404c:	8d 4a ff             	lea    -0x1(%edx),%ecx
8010404f:	85 d2                	test   %edx,%edx
80104051:	7f f1                	jg     80104044 <strncpy+0x31>
  return os;
}
80104053:	8b 45 08             	mov    0x8(%ebp),%eax
80104056:	5b                   	pop    %ebx
80104057:	5e                   	pop    %esi
80104058:	5f                   	pop    %edi
80104059:	5d                   	pop    %ebp
8010405a:	c3                   	ret    

8010405b <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
8010405b:	55                   	push   %ebp
8010405c:	89 e5                	mov    %esp,%ebp
8010405e:	57                   	push   %edi
8010405f:	56                   	push   %esi
80104060:	53                   	push   %ebx
80104061:	8b 45 08             	mov    0x8(%ebp),%eax
80104064:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80104067:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
8010406a:	85 d2                	test   %edx,%edx
8010406c:	7e 23                	jle    80104091 <safestrcpy+0x36>
8010406e:	89 c1                	mov    %eax,%ecx
80104070:	eb 04                	jmp    80104076 <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80104072:	89 fb                	mov    %edi,%ebx
80104074:	89 f1                	mov    %esi,%ecx
80104076:	83 ea 01             	sub    $0x1,%edx
80104079:	85 d2                	test   %edx,%edx
8010407b:	7e 11                	jle    8010408e <safestrcpy+0x33>
8010407d:	8d 7b 01             	lea    0x1(%ebx),%edi
80104080:	8d 71 01             	lea    0x1(%ecx),%esi
80104083:	0f b6 1b             	movzbl (%ebx),%ebx
80104086:	88 19                	mov    %bl,(%ecx)
80104088:	84 db                	test   %bl,%bl
8010408a:	75 e6                	jne    80104072 <safestrcpy+0x17>
8010408c:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
8010408e:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80104091:	5b                   	pop    %ebx
80104092:	5e                   	pop    %esi
80104093:	5f                   	pop    %edi
80104094:	5d                   	pop    %ebp
80104095:	c3                   	ret    

80104096 <strlen>:

int
strlen(const char *s)
{
80104096:	55                   	push   %ebp
80104097:	89 e5                	mov    %esp,%ebp
80104099:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
8010409c:	b8 00 00 00 00       	mov    $0x0,%eax
801040a1:	eb 03                	jmp    801040a6 <strlen+0x10>
801040a3:	83 c0 01             	add    $0x1,%eax
801040a6:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
801040aa:	75 f7                	jne    801040a3 <strlen+0xd>
    ;
  return n;
}
801040ac:	5d                   	pop    %ebp
801040ad:	c3                   	ret    

801040ae <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
801040ae:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
801040b2:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
801040b6:	55                   	push   %ebp
  pushl %ebx
801040b7:	53                   	push   %ebx
  pushl %esi
801040b8:	56                   	push   %esi
  pushl %edi
801040b9:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
801040ba:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
801040bc:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
801040be:	5f                   	pop    %edi
  popl %esi
801040bf:	5e                   	pop    %esi
  popl %ebx
801040c0:	5b                   	pop    %ebx
  popl %ebp
801040c1:	5d                   	pop    %ebp
  ret
801040c2:	c3                   	ret    

801040c3 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
801040c3:	55                   	push   %ebp
801040c4:	89 e5                	mov    %esp,%ebp
801040c6:	53                   	push   %ebx
801040c7:	83 ec 04             	sub    $0x4,%esp
801040ca:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
801040cd:	e8 d4 f3 ff ff       	call   801034a6 <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
801040d2:	8b 00                	mov    (%eax),%eax
801040d4:	39 d8                	cmp    %ebx,%eax
801040d6:	76 19                	jbe    801040f1 <fetchint+0x2e>
801040d8:	8d 53 04             	lea    0x4(%ebx),%edx
801040db:	39 d0                	cmp    %edx,%eax
801040dd:	72 19                	jb     801040f8 <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
801040df:	8b 13                	mov    (%ebx),%edx
801040e1:	8b 45 0c             	mov    0xc(%ebp),%eax
801040e4:	89 10                	mov    %edx,(%eax)
  return 0;
801040e6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801040eb:	83 c4 04             	add    $0x4,%esp
801040ee:	5b                   	pop    %ebx
801040ef:	5d                   	pop    %ebp
801040f0:	c3                   	ret    
    return -1;
801040f1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040f6:	eb f3                	jmp    801040eb <fetchint+0x28>
801040f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040fd:	eb ec                	jmp    801040eb <fetchint+0x28>

801040ff <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
801040ff:	55                   	push   %ebp
80104100:	89 e5                	mov    %esp,%ebp
80104102:	53                   	push   %ebx
80104103:	83 ec 04             	sub    $0x4,%esp
80104106:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
80104109:	e8 98 f3 ff ff       	call   801034a6 <myproc>

  if(addr >= curproc->sz)
8010410e:	39 18                	cmp    %ebx,(%eax)
80104110:	76 26                	jbe    80104138 <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
80104112:	8b 55 0c             	mov    0xc(%ebp),%edx
80104115:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
80104117:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
80104119:	89 d8                	mov    %ebx,%eax
8010411b:	39 d0                	cmp    %edx,%eax
8010411d:	73 0e                	jae    8010412d <fetchstr+0x2e>
    if(*s == 0)
8010411f:	80 38 00             	cmpb   $0x0,(%eax)
80104122:	74 05                	je     80104129 <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
80104124:	83 c0 01             	add    $0x1,%eax
80104127:	eb f2                	jmp    8010411b <fetchstr+0x1c>
      return s - *pp;
80104129:	29 d8                	sub    %ebx,%eax
8010412b:	eb 05                	jmp    80104132 <fetchstr+0x33>
  }
  return -1;
8010412d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104132:	83 c4 04             	add    $0x4,%esp
80104135:	5b                   	pop    %ebx
80104136:	5d                   	pop    %ebp
80104137:	c3                   	ret    
    return -1;
80104138:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010413d:	eb f3                	jmp    80104132 <fetchstr+0x33>

8010413f <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
8010413f:	55                   	push   %ebp
80104140:	89 e5                	mov    %esp,%ebp
80104142:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80104145:	e8 5c f3 ff ff       	call   801034a6 <myproc>
8010414a:	8b 50 18             	mov    0x18(%eax),%edx
8010414d:	8b 45 08             	mov    0x8(%ebp),%eax
80104150:	c1 e0 02             	shl    $0x2,%eax
80104153:	03 42 44             	add    0x44(%edx),%eax
80104156:	83 ec 08             	sub    $0x8,%esp
80104159:	ff 75 0c             	pushl  0xc(%ebp)
8010415c:	83 c0 04             	add    $0x4,%eax
8010415f:	50                   	push   %eax
80104160:	e8 5e ff ff ff       	call   801040c3 <fetchint>
}
80104165:	c9                   	leave  
80104166:	c3                   	ret    

80104167 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80104167:	55                   	push   %ebp
80104168:	89 e5                	mov    %esp,%ebp
8010416a:	56                   	push   %esi
8010416b:	53                   	push   %ebx
8010416c:	83 ec 10             	sub    $0x10,%esp
8010416f:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
80104172:	e8 2f f3 ff ff       	call   801034a6 <myproc>
80104177:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
80104179:	83 ec 08             	sub    $0x8,%esp
8010417c:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010417f:	50                   	push   %eax
80104180:	ff 75 08             	pushl  0x8(%ebp)
80104183:	e8 b7 ff ff ff       	call   8010413f <argint>
80104188:	83 c4 10             	add    $0x10,%esp
8010418b:	85 c0                	test   %eax,%eax
8010418d:	78 24                	js     801041b3 <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
8010418f:	85 db                	test   %ebx,%ebx
80104191:	78 27                	js     801041ba <argptr+0x53>
80104193:	8b 16                	mov    (%esi),%edx
80104195:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104198:	39 c2                	cmp    %eax,%edx
8010419a:	76 25                	jbe    801041c1 <argptr+0x5a>
8010419c:	01 c3                	add    %eax,%ebx
8010419e:	39 da                	cmp    %ebx,%edx
801041a0:	72 26                	jb     801041c8 <argptr+0x61>
    return -1;
  *pp = (char*)i;
801041a2:	8b 55 0c             	mov    0xc(%ebp),%edx
801041a5:	89 02                	mov    %eax,(%edx)
  return 0;
801041a7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801041ac:	8d 65 f8             	lea    -0x8(%ebp),%esp
801041af:	5b                   	pop    %ebx
801041b0:	5e                   	pop    %esi
801041b1:	5d                   	pop    %ebp
801041b2:	c3                   	ret    
    return -1;
801041b3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801041b8:	eb f2                	jmp    801041ac <argptr+0x45>
    return -1;
801041ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801041bf:	eb eb                	jmp    801041ac <argptr+0x45>
801041c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801041c6:	eb e4                	jmp    801041ac <argptr+0x45>
801041c8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801041cd:	eb dd                	jmp    801041ac <argptr+0x45>

801041cf <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
801041cf:	55                   	push   %ebp
801041d0:	89 e5                	mov    %esp,%ebp
801041d2:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
801041d5:	8d 45 f4             	lea    -0xc(%ebp),%eax
801041d8:	50                   	push   %eax
801041d9:	ff 75 08             	pushl  0x8(%ebp)
801041dc:	e8 5e ff ff ff       	call   8010413f <argint>
801041e1:	83 c4 10             	add    $0x10,%esp
801041e4:	85 c0                	test   %eax,%eax
801041e6:	78 13                	js     801041fb <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
801041e8:	83 ec 08             	sub    $0x8,%esp
801041eb:	ff 75 0c             	pushl  0xc(%ebp)
801041ee:	ff 75 f4             	pushl  -0xc(%ebp)
801041f1:	e8 09 ff ff ff       	call   801040ff <fetchstr>
801041f6:	83 c4 10             	add    $0x10,%esp
}
801041f9:	c9                   	leave  
801041fa:	c3                   	ret    
    return -1;
801041fb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104200:	eb f7                	jmp    801041f9 <argstr+0x2a>

80104202 <syscall>:
[SYS_dump_physmem]   sys_dump_physmem,
};

void
syscall(void)
{
80104202:	55                   	push   %ebp
80104203:	89 e5                	mov    %esp,%ebp
80104205:	53                   	push   %ebx
80104206:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
80104209:	e8 98 f2 ff ff       	call   801034a6 <myproc>
8010420e:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
80104210:	8b 40 18             	mov    0x18(%eax),%eax
80104213:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80104216:	8d 50 ff             	lea    -0x1(%eax),%edx
80104219:	83 fa 15             	cmp    $0x15,%edx
8010421c:	77 18                	ja     80104236 <syscall+0x34>
8010421e:	8b 14 85 40 6e 10 80 	mov    -0x7fef91c0(,%eax,4),%edx
80104225:	85 d2                	test   %edx,%edx
80104227:	74 0d                	je     80104236 <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
80104229:	ff d2                	call   *%edx
8010422b:	8b 53 18             	mov    0x18(%ebx),%edx
8010422e:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
80104231:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104234:	c9                   	leave  
80104235:	c3                   	ret    
            curproc->pid, curproc->name, num);
80104236:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
80104239:	50                   	push   %eax
8010423a:	52                   	push   %edx
8010423b:	ff 73 10             	pushl  0x10(%ebx)
8010423e:	68 11 6e 10 80       	push   $0x80106e11
80104243:	e8 c3 c3 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
80104248:	8b 43 18             	mov    0x18(%ebx),%eax
8010424b:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
80104252:	83 c4 10             	add    $0x10,%esp
}
80104255:	eb da                	jmp    80104231 <syscall+0x2f>

80104257 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80104257:	55                   	push   %ebp
80104258:	89 e5                	mov    %esp,%ebp
8010425a:	56                   	push   %esi
8010425b:	53                   	push   %ebx
8010425c:	83 ec 18             	sub    $0x18,%esp
8010425f:	89 d6                	mov    %edx,%esi
80104261:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80104263:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104266:	52                   	push   %edx
80104267:	50                   	push   %eax
80104268:	e8 d2 fe ff ff       	call   8010413f <argint>
8010426d:	83 c4 10             	add    $0x10,%esp
80104270:	85 c0                	test   %eax,%eax
80104272:	78 2e                	js     801042a2 <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
80104274:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
80104278:	77 2f                	ja     801042a9 <argfd+0x52>
8010427a:	e8 27 f2 ff ff       	call   801034a6 <myproc>
8010427f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104282:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
80104286:	85 c0                	test   %eax,%eax
80104288:	74 26                	je     801042b0 <argfd+0x59>
    return -1;
  if(pfd)
8010428a:	85 f6                	test   %esi,%esi
8010428c:	74 02                	je     80104290 <argfd+0x39>
    *pfd = fd;
8010428e:	89 16                	mov    %edx,(%esi)
  if(pf)
80104290:	85 db                	test   %ebx,%ebx
80104292:	74 23                	je     801042b7 <argfd+0x60>
    *pf = f;
80104294:	89 03                	mov    %eax,(%ebx)
  return 0;
80104296:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010429b:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010429e:	5b                   	pop    %ebx
8010429f:	5e                   	pop    %esi
801042a0:	5d                   	pop    %ebp
801042a1:	c3                   	ret    
    return -1;
801042a2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042a7:	eb f2                	jmp    8010429b <argfd+0x44>
    return -1;
801042a9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042ae:	eb eb                	jmp    8010429b <argfd+0x44>
801042b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042b5:	eb e4                	jmp    8010429b <argfd+0x44>
  return 0;
801042b7:	b8 00 00 00 00       	mov    $0x0,%eax
801042bc:	eb dd                	jmp    8010429b <argfd+0x44>

801042be <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801042be:	55                   	push   %ebp
801042bf:	89 e5                	mov    %esp,%ebp
801042c1:	53                   	push   %ebx
801042c2:	83 ec 04             	sub    $0x4,%esp
801042c5:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
801042c7:	e8 da f1 ff ff       	call   801034a6 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
801042cc:	ba 00 00 00 00       	mov    $0x0,%edx
801042d1:	83 fa 0f             	cmp    $0xf,%edx
801042d4:	7f 18                	jg     801042ee <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
801042d6:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
801042db:	74 05                	je     801042e2 <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
801042dd:	83 c2 01             	add    $0x1,%edx
801042e0:	eb ef                	jmp    801042d1 <fdalloc+0x13>
      curproc->ofile[fd] = f;
801042e2:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
801042e6:	89 d0                	mov    %edx,%eax
801042e8:	83 c4 04             	add    $0x4,%esp
801042eb:	5b                   	pop    %ebx
801042ec:	5d                   	pop    %ebp
801042ed:	c3                   	ret    
  return -1;
801042ee:	ba ff ff ff ff       	mov    $0xffffffff,%edx
801042f3:	eb f1                	jmp    801042e6 <fdalloc+0x28>

801042f5 <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801042f5:	55                   	push   %ebp
801042f6:	89 e5                	mov    %esp,%ebp
801042f8:	56                   	push   %esi
801042f9:	53                   	push   %ebx
801042fa:	83 ec 10             	sub    $0x10,%esp
801042fd:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801042ff:	b8 20 00 00 00       	mov    $0x20,%eax
80104304:	89 c6                	mov    %eax,%esi
80104306:	39 43 58             	cmp    %eax,0x58(%ebx)
80104309:	76 2e                	jbe    80104339 <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010430b:	6a 10                	push   $0x10
8010430d:	50                   	push   %eax
8010430e:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104311:	50                   	push   %eax
80104312:	53                   	push   %ebx
80104313:	e8 67 d4 ff ff       	call   8010177f <readi>
80104318:	83 c4 10             	add    $0x10,%esp
8010431b:	83 f8 10             	cmp    $0x10,%eax
8010431e:	75 0c                	jne    8010432c <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
80104320:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
80104325:	75 1e                	jne    80104345 <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104327:	8d 46 10             	lea    0x10(%esi),%eax
8010432a:	eb d8                	jmp    80104304 <isdirempty+0xf>
      panic("isdirempty: readi");
8010432c:	83 ec 0c             	sub    $0xc,%esp
8010432f:	68 9c 6e 10 80       	push   $0x80106e9c
80104334:	e8 0f c0 ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
80104339:	b8 01 00 00 00       	mov    $0x1,%eax
}
8010433e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104341:	5b                   	pop    %ebx
80104342:	5e                   	pop    %esi
80104343:	5d                   	pop    %ebp
80104344:	c3                   	ret    
      return 0;
80104345:	b8 00 00 00 00       	mov    $0x0,%eax
8010434a:	eb f2                	jmp    8010433e <isdirempty+0x49>

8010434c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
8010434c:	55                   	push   %ebp
8010434d:	89 e5                	mov    %esp,%ebp
8010434f:	57                   	push   %edi
80104350:	56                   	push   %esi
80104351:	53                   	push   %ebx
80104352:	83 ec 44             	sub    $0x44,%esp
80104355:	89 55 c4             	mov    %edx,-0x3c(%ebp)
80104358:	89 4d c0             	mov    %ecx,-0x40(%ebp)
8010435b:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
8010435e:	8d 55 d6             	lea    -0x2a(%ebp),%edx
80104361:	52                   	push   %edx
80104362:	50                   	push   %eax
80104363:	e8 9d d8 ff ff       	call   80101c05 <nameiparent>
80104368:	89 c6                	mov    %eax,%esi
8010436a:	83 c4 10             	add    $0x10,%esp
8010436d:	85 c0                	test   %eax,%eax
8010436f:	0f 84 3a 01 00 00    	je     801044af <create+0x163>
    return 0;
  ilock(dp);
80104375:	83 ec 0c             	sub    $0xc,%esp
80104378:	50                   	push   %eax
80104379:	e8 0f d2 ff ff       	call   8010158d <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
8010437e:	83 c4 0c             	add    $0xc,%esp
80104381:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104384:	50                   	push   %eax
80104385:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104388:	50                   	push   %eax
80104389:	56                   	push   %esi
8010438a:	e8 2d d6 ff ff       	call   801019bc <dirlookup>
8010438f:	89 c3                	mov    %eax,%ebx
80104391:	83 c4 10             	add    $0x10,%esp
80104394:	85 c0                	test   %eax,%eax
80104396:	74 3f                	je     801043d7 <create+0x8b>
    iunlockput(dp);
80104398:	83 ec 0c             	sub    $0xc,%esp
8010439b:	56                   	push   %esi
8010439c:	e8 93 d3 ff ff       	call   80101734 <iunlockput>
    ilock(ip);
801043a1:	89 1c 24             	mov    %ebx,(%esp)
801043a4:	e8 e4 d1 ff ff       	call   8010158d <ilock>
    if(type == T_FILE && ip->type == T_FILE)
801043a9:	83 c4 10             	add    $0x10,%esp
801043ac:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
801043b1:	75 11                	jne    801043c4 <create+0x78>
801043b3:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
801043b8:	75 0a                	jne    801043c4 <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
801043ba:	89 d8                	mov    %ebx,%eax
801043bc:	8d 65 f4             	lea    -0xc(%ebp),%esp
801043bf:	5b                   	pop    %ebx
801043c0:	5e                   	pop    %esi
801043c1:	5f                   	pop    %edi
801043c2:	5d                   	pop    %ebp
801043c3:	c3                   	ret    
    iunlockput(ip);
801043c4:	83 ec 0c             	sub    $0xc,%esp
801043c7:	53                   	push   %ebx
801043c8:	e8 67 d3 ff ff       	call   80101734 <iunlockput>
    return 0;
801043cd:	83 c4 10             	add    $0x10,%esp
801043d0:	bb 00 00 00 00       	mov    $0x0,%ebx
801043d5:	eb e3                	jmp    801043ba <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
801043d7:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
801043db:	83 ec 08             	sub    $0x8,%esp
801043de:	50                   	push   %eax
801043df:	ff 36                	pushl  (%esi)
801043e1:	e8 a4 cf ff ff       	call   8010138a <ialloc>
801043e6:	89 c3                	mov    %eax,%ebx
801043e8:	83 c4 10             	add    $0x10,%esp
801043eb:	85 c0                	test   %eax,%eax
801043ed:	74 55                	je     80104444 <create+0xf8>
  ilock(ip);
801043ef:	83 ec 0c             	sub    $0xc,%esp
801043f2:	50                   	push   %eax
801043f3:	e8 95 d1 ff ff       	call   8010158d <ilock>
  ip->major = major;
801043f8:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
801043fc:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
80104400:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
80104404:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
8010440a:	89 1c 24             	mov    %ebx,(%esp)
8010440d:	e8 1a d0 ff ff       	call   8010142c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
80104412:	83 c4 10             	add    $0x10,%esp
80104415:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
8010441a:	74 35                	je     80104451 <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
8010441c:	83 ec 04             	sub    $0x4,%esp
8010441f:	ff 73 04             	pushl  0x4(%ebx)
80104422:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104425:	50                   	push   %eax
80104426:	56                   	push   %esi
80104427:	e8 10 d7 ff ff       	call   80101b3c <dirlink>
8010442c:	83 c4 10             	add    $0x10,%esp
8010442f:	85 c0                	test   %eax,%eax
80104431:	78 6f                	js     801044a2 <create+0x156>
  iunlockput(dp);
80104433:	83 ec 0c             	sub    $0xc,%esp
80104436:	56                   	push   %esi
80104437:	e8 f8 d2 ff ff       	call   80101734 <iunlockput>
  return ip;
8010443c:	83 c4 10             	add    $0x10,%esp
8010443f:	e9 76 ff ff ff       	jmp    801043ba <create+0x6e>
    panic("create: ialloc");
80104444:	83 ec 0c             	sub    $0xc,%esp
80104447:	68 ae 6e 10 80       	push   $0x80106eae
8010444c:	e8 f7 be ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
80104451:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104455:	83 c0 01             	add    $0x1,%eax
80104458:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
8010445c:	83 ec 0c             	sub    $0xc,%esp
8010445f:	56                   	push   %esi
80104460:	e8 c7 cf ff ff       	call   8010142c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80104465:	83 c4 0c             	add    $0xc,%esp
80104468:	ff 73 04             	pushl  0x4(%ebx)
8010446b:	68 be 6e 10 80       	push   $0x80106ebe
80104470:	53                   	push   %ebx
80104471:	e8 c6 d6 ff ff       	call   80101b3c <dirlink>
80104476:	83 c4 10             	add    $0x10,%esp
80104479:	85 c0                	test   %eax,%eax
8010447b:	78 18                	js     80104495 <create+0x149>
8010447d:	83 ec 04             	sub    $0x4,%esp
80104480:	ff 76 04             	pushl  0x4(%esi)
80104483:	68 bd 6e 10 80       	push   $0x80106ebd
80104488:	53                   	push   %ebx
80104489:	e8 ae d6 ff ff       	call   80101b3c <dirlink>
8010448e:	83 c4 10             	add    $0x10,%esp
80104491:	85 c0                	test   %eax,%eax
80104493:	79 87                	jns    8010441c <create+0xd0>
      panic("create dots");
80104495:	83 ec 0c             	sub    $0xc,%esp
80104498:	68 c0 6e 10 80       	push   $0x80106ec0
8010449d:	e8 a6 be ff ff       	call   80100348 <panic>
    panic("create: dirlink");
801044a2:	83 ec 0c             	sub    $0xc,%esp
801044a5:	68 cc 6e 10 80       	push   $0x80106ecc
801044aa:	e8 99 be ff ff       	call   80100348 <panic>
    return 0;
801044af:	89 c3                	mov    %eax,%ebx
801044b1:	e9 04 ff ff ff       	jmp    801043ba <create+0x6e>

801044b6 <sys_dup>:
{
801044b6:	55                   	push   %ebp
801044b7:	89 e5                	mov    %esp,%ebp
801044b9:	53                   	push   %ebx
801044ba:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
801044bd:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801044c0:	ba 00 00 00 00       	mov    $0x0,%edx
801044c5:	b8 00 00 00 00       	mov    $0x0,%eax
801044ca:	e8 88 fd ff ff       	call   80104257 <argfd>
801044cf:	85 c0                	test   %eax,%eax
801044d1:	78 23                	js     801044f6 <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
801044d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044d6:	e8 e3 fd ff ff       	call   801042be <fdalloc>
801044db:	89 c3                	mov    %eax,%ebx
801044dd:	85 c0                	test   %eax,%eax
801044df:	78 1c                	js     801044fd <sys_dup+0x47>
  filedup(f);
801044e1:	83 ec 0c             	sub    $0xc,%esp
801044e4:	ff 75 f4             	pushl  -0xc(%ebp)
801044e7:	e8 ae c7 ff ff       	call   80100c9a <filedup>
  return fd;
801044ec:	83 c4 10             	add    $0x10,%esp
}
801044ef:	89 d8                	mov    %ebx,%eax
801044f1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801044f4:	c9                   	leave  
801044f5:	c3                   	ret    
    return -1;
801044f6:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801044fb:	eb f2                	jmp    801044ef <sys_dup+0x39>
    return -1;
801044fd:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104502:	eb eb                	jmp    801044ef <sys_dup+0x39>

80104504 <sys_read>:
{
80104504:	55                   	push   %ebp
80104505:	89 e5                	mov    %esp,%ebp
80104507:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010450a:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010450d:	ba 00 00 00 00       	mov    $0x0,%edx
80104512:	b8 00 00 00 00       	mov    $0x0,%eax
80104517:	e8 3b fd ff ff       	call   80104257 <argfd>
8010451c:	85 c0                	test   %eax,%eax
8010451e:	78 43                	js     80104563 <sys_read+0x5f>
80104520:	83 ec 08             	sub    $0x8,%esp
80104523:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104526:	50                   	push   %eax
80104527:	6a 02                	push   $0x2
80104529:	e8 11 fc ff ff       	call   8010413f <argint>
8010452e:	83 c4 10             	add    $0x10,%esp
80104531:	85 c0                	test   %eax,%eax
80104533:	78 35                	js     8010456a <sys_read+0x66>
80104535:	83 ec 04             	sub    $0x4,%esp
80104538:	ff 75 f0             	pushl  -0x10(%ebp)
8010453b:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010453e:	50                   	push   %eax
8010453f:	6a 01                	push   $0x1
80104541:	e8 21 fc ff ff       	call   80104167 <argptr>
80104546:	83 c4 10             	add    $0x10,%esp
80104549:	85 c0                	test   %eax,%eax
8010454b:	78 24                	js     80104571 <sys_read+0x6d>
  return fileread(f, p, n);
8010454d:	83 ec 04             	sub    $0x4,%esp
80104550:	ff 75 f0             	pushl  -0x10(%ebp)
80104553:	ff 75 ec             	pushl  -0x14(%ebp)
80104556:	ff 75 f4             	pushl  -0xc(%ebp)
80104559:	e8 85 c8 ff ff       	call   80100de3 <fileread>
8010455e:	83 c4 10             	add    $0x10,%esp
}
80104561:	c9                   	leave  
80104562:	c3                   	ret    
    return -1;
80104563:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104568:	eb f7                	jmp    80104561 <sys_read+0x5d>
8010456a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010456f:	eb f0                	jmp    80104561 <sys_read+0x5d>
80104571:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104576:	eb e9                	jmp    80104561 <sys_read+0x5d>

80104578 <sys_write>:
{
80104578:	55                   	push   %ebp
80104579:	89 e5                	mov    %esp,%ebp
8010457b:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010457e:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104581:	ba 00 00 00 00       	mov    $0x0,%edx
80104586:	b8 00 00 00 00       	mov    $0x0,%eax
8010458b:	e8 c7 fc ff ff       	call   80104257 <argfd>
80104590:	85 c0                	test   %eax,%eax
80104592:	78 43                	js     801045d7 <sys_write+0x5f>
80104594:	83 ec 08             	sub    $0x8,%esp
80104597:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010459a:	50                   	push   %eax
8010459b:	6a 02                	push   $0x2
8010459d:	e8 9d fb ff ff       	call   8010413f <argint>
801045a2:	83 c4 10             	add    $0x10,%esp
801045a5:	85 c0                	test   %eax,%eax
801045a7:	78 35                	js     801045de <sys_write+0x66>
801045a9:	83 ec 04             	sub    $0x4,%esp
801045ac:	ff 75 f0             	pushl  -0x10(%ebp)
801045af:	8d 45 ec             	lea    -0x14(%ebp),%eax
801045b2:	50                   	push   %eax
801045b3:	6a 01                	push   $0x1
801045b5:	e8 ad fb ff ff       	call   80104167 <argptr>
801045ba:	83 c4 10             	add    $0x10,%esp
801045bd:	85 c0                	test   %eax,%eax
801045bf:	78 24                	js     801045e5 <sys_write+0x6d>
  return filewrite(f, p, n);
801045c1:	83 ec 04             	sub    $0x4,%esp
801045c4:	ff 75 f0             	pushl  -0x10(%ebp)
801045c7:	ff 75 ec             	pushl  -0x14(%ebp)
801045ca:	ff 75 f4             	pushl  -0xc(%ebp)
801045cd:	e8 96 c8 ff ff       	call   80100e68 <filewrite>
801045d2:	83 c4 10             	add    $0x10,%esp
}
801045d5:	c9                   	leave  
801045d6:	c3                   	ret    
    return -1;
801045d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045dc:	eb f7                	jmp    801045d5 <sys_write+0x5d>
801045de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045e3:	eb f0                	jmp    801045d5 <sys_write+0x5d>
801045e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045ea:	eb e9                	jmp    801045d5 <sys_write+0x5d>

801045ec <sys_close>:
{
801045ec:	55                   	push   %ebp
801045ed:	89 e5                	mov    %esp,%ebp
801045ef:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
801045f2:	8d 4d f0             	lea    -0x10(%ebp),%ecx
801045f5:	8d 55 f4             	lea    -0xc(%ebp),%edx
801045f8:	b8 00 00 00 00       	mov    $0x0,%eax
801045fd:	e8 55 fc ff ff       	call   80104257 <argfd>
80104602:	85 c0                	test   %eax,%eax
80104604:	78 25                	js     8010462b <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
80104606:	e8 9b ee ff ff       	call   801034a6 <myproc>
8010460b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010460e:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
80104615:	00 
  fileclose(f);
80104616:	83 ec 0c             	sub    $0xc,%esp
80104619:	ff 75 f0             	pushl  -0x10(%ebp)
8010461c:	e8 be c6 ff ff       	call   80100cdf <fileclose>
  return 0;
80104621:	83 c4 10             	add    $0x10,%esp
80104624:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104629:	c9                   	leave  
8010462a:	c3                   	ret    
    return -1;
8010462b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104630:	eb f7                	jmp    80104629 <sys_close+0x3d>

80104632 <sys_fstat>:
{
80104632:	55                   	push   %ebp
80104633:	89 e5                	mov    %esp,%ebp
80104635:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80104638:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010463b:	ba 00 00 00 00       	mov    $0x0,%edx
80104640:	b8 00 00 00 00       	mov    $0x0,%eax
80104645:	e8 0d fc ff ff       	call   80104257 <argfd>
8010464a:	85 c0                	test   %eax,%eax
8010464c:	78 2a                	js     80104678 <sys_fstat+0x46>
8010464e:	83 ec 04             	sub    $0x4,%esp
80104651:	6a 14                	push   $0x14
80104653:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104656:	50                   	push   %eax
80104657:	6a 01                	push   $0x1
80104659:	e8 09 fb ff ff       	call   80104167 <argptr>
8010465e:	83 c4 10             	add    $0x10,%esp
80104661:	85 c0                	test   %eax,%eax
80104663:	78 1a                	js     8010467f <sys_fstat+0x4d>
  return filestat(f, st);
80104665:	83 ec 08             	sub    $0x8,%esp
80104668:	ff 75 f0             	pushl  -0x10(%ebp)
8010466b:	ff 75 f4             	pushl  -0xc(%ebp)
8010466e:	e8 29 c7 ff ff       	call   80100d9c <filestat>
80104673:	83 c4 10             	add    $0x10,%esp
}
80104676:	c9                   	leave  
80104677:	c3                   	ret    
    return -1;
80104678:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010467d:	eb f7                	jmp    80104676 <sys_fstat+0x44>
8010467f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104684:	eb f0                	jmp    80104676 <sys_fstat+0x44>

80104686 <sys_link>:
{
80104686:	55                   	push   %ebp
80104687:	89 e5                	mov    %esp,%ebp
80104689:	56                   	push   %esi
8010468a:	53                   	push   %ebx
8010468b:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
8010468e:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104691:	50                   	push   %eax
80104692:	6a 00                	push   $0x0
80104694:	e8 36 fb ff ff       	call   801041cf <argstr>
80104699:	83 c4 10             	add    $0x10,%esp
8010469c:	85 c0                	test   %eax,%eax
8010469e:	0f 88 32 01 00 00    	js     801047d6 <sys_link+0x150>
801046a4:	83 ec 08             	sub    $0x8,%esp
801046a7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801046aa:	50                   	push   %eax
801046ab:	6a 01                	push   $0x1
801046ad:	e8 1d fb ff ff       	call   801041cf <argstr>
801046b2:	83 c4 10             	add    $0x10,%esp
801046b5:	85 c0                	test   %eax,%eax
801046b7:	0f 88 20 01 00 00    	js     801047dd <sys_link+0x157>
  begin_op();
801046bd:	e8 89 e3 ff ff       	call   80102a4b <begin_op>
  if((ip = namei(old)) == 0){
801046c2:	83 ec 0c             	sub    $0xc,%esp
801046c5:	ff 75 e0             	pushl  -0x20(%ebp)
801046c8:	e8 20 d5 ff ff       	call   80101bed <namei>
801046cd:	89 c3                	mov    %eax,%ebx
801046cf:	83 c4 10             	add    $0x10,%esp
801046d2:	85 c0                	test   %eax,%eax
801046d4:	0f 84 99 00 00 00    	je     80104773 <sys_link+0xed>
  ilock(ip);
801046da:	83 ec 0c             	sub    $0xc,%esp
801046dd:	50                   	push   %eax
801046de:	e8 aa ce ff ff       	call   8010158d <ilock>
  if(ip->type == T_DIR){
801046e3:	83 c4 10             	add    $0x10,%esp
801046e6:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801046eb:	0f 84 8e 00 00 00    	je     8010477f <sys_link+0xf9>
  ip->nlink++;
801046f1:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801046f5:	83 c0 01             	add    $0x1,%eax
801046f8:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801046fc:	83 ec 0c             	sub    $0xc,%esp
801046ff:	53                   	push   %ebx
80104700:	e8 27 cd ff ff       	call   8010142c <iupdate>
  iunlock(ip);
80104705:	89 1c 24             	mov    %ebx,(%esp)
80104708:	e8 42 cf ff ff       	call   8010164f <iunlock>
  if((dp = nameiparent(new, name)) == 0)
8010470d:	83 c4 08             	add    $0x8,%esp
80104710:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104713:	50                   	push   %eax
80104714:	ff 75 e4             	pushl  -0x1c(%ebp)
80104717:	e8 e9 d4 ff ff       	call   80101c05 <nameiparent>
8010471c:	89 c6                	mov    %eax,%esi
8010471e:	83 c4 10             	add    $0x10,%esp
80104721:	85 c0                	test   %eax,%eax
80104723:	74 7e                	je     801047a3 <sys_link+0x11d>
  ilock(dp);
80104725:	83 ec 0c             	sub    $0xc,%esp
80104728:	50                   	push   %eax
80104729:	e8 5f ce ff ff       	call   8010158d <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
8010472e:	83 c4 10             	add    $0x10,%esp
80104731:	8b 03                	mov    (%ebx),%eax
80104733:	39 06                	cmp    %eax,(%esi)
80104735:	75 60                	jne    80104797 <sys_link+0x111>
80104737:	83 ec 04             	sub    $0x4,%esp
8010473a:	ff 73 04             	pushl  0x4(%ebx)
8010473d:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104740:	50                   	push   %eax
80104741:	56                   	push   %esi
80104742:	e8 f5 d3 ff ff       	call   80101b3c <dirlink>
80104747:	83 c4 10             	add    $0x10,%esp
8010474a:	85 c0                	test   %eax,%eax
8010474c:	78 49                	js     80104797 <sys_link+0x111>
  iunlockput(dp);
8010474e:	83 ec 0c             	sub    $0xc,%esp
80104751:	56                   	push   %esi
80104752:	e8 dd cf ff ff       	call   80101734 <iunlockput>
  iput(ip);
80104757:	89 1c 24             	mov    %ebx,(%esp)
8010475a:	e8 35 cf ff ff       	call   80101694 <iput>
  end_op();
8010475f:	e8 61 e3 ff ff       	call   80102ac5 <end_op>
  return 0;
80104764:	83 c4 10             	add    $0x10,%esp
80104767:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010476c:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010476f:	5b                   	pop    %ebx
80104770:	5e                   	pop    %esi
80104771:	5d                   	pop    %ebp
80104772:	c3                   	ret    
    end_op();
80104773:	e8 4d e3 ff ff       	call   80102ac5 <end_op>
    return -1;
80104778:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010477d:	eb ed                	jmp    8010476c <sys_link+0xe6>
    iunlockput(ip);
8010477f:	83 ec 0c             	sub    $0xc,%esp
80104782:	53                   	push   %ebx
80104783:	e8 ac cf ff ff       	call   80101734 <iunlockput>
    end_op();
80104788:	e8 38 e3 ff ff       	call   80102ac5 <end_op>
    return -1;
8010478d:	83 c4 10             	add    $0x10,%esp
80104790:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104795:	eb d5                	jmp    8010476c <sys_link+0xe6>
    iunlockput(dp);
80104797:	83 ec 0c             	sub    $0xc,%esp
8010479a:	56                   	push   %esi
8010479b:	e8 94 cf ff ff       	call   80101734 <iunlockput>
    goto bad;
801047a0:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
801047a3:	83 ec 0c             	sub    $0xc,%esp
801047a6:	53                   	push   %ebx
801047a7:	e8 e1 cd ff ff       	call   8010158d <ilock>
  ip->nlink--;
801047ac:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801047b0:	83 e8 01             	sub    $0x1,%eax
801047b3:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801047b7:	89 1c 24             	mov    %ebx,(%esp)
801047ba:	e8 6d cc ff ff       	call   8010142c <iupdate>
  iunlockput(ip);
801047bf:	89 1c 24             	mov    %ebx,(%esp)
801047c2:	e8 6d cf ff ff       	call   80101734 <iunlockput>
  end_op();
801047c7:	e8 f9 e2 ff ff       	call   80102ac5 <end_op>
  return -1;
801047cc:	83 c4 10             	add    $0x10,%esp
801047cf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047d4:	eb 96                	jmp    8010476c <sys_link+0xe6>
    return -1;
801047d6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047db:	eb 8f                	jmp    8010476c <sys_link+0xe6>
801047dd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047e2:	eb 88                	jmp    8010476c <sys_link+0xe6>

801047e4 <sys_unlink>:
{
801047e4:	55                   	push   %ebp
801047e5:	89 e5                	mov    %esp,%ebp
801047e7:	57                   	push   %edi
801047e8:	56                   	push   %esi
801047e9:	53                   	push   %ebx
801047ea:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
801047ed:	8d 45 c4             	lea    -0x3c(%ebp),%eax
801047f0:	50                   	push   %eax
801047f1:	6a 00                	push   $0x0
801047f3:	e8 d7 f9 ff ff       	call   801041cf <argstr>
801047f8:	83 c4 10             	add    $0x10,%esp
801047fb:	85 c0                	test   %eax,%eax
801047fd:	0f 88 83 01 00 00    	js     80104986 <sys_unlink+0x1a2>
  begin_op();
80104803:	e8 43 e2 ff ff       	call   80102a4b <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80104808:	83 ec 08             	sub    $0x8,%esp
8010480b:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010480e:	50                   	push   %eax
8010480f:	ff 75 c4             	pushl  -0x3c(%ebp)
80104812:	e8 ee d3 ff ff       	call   80101c05 <nameiparent>
80104817:	89 c6                	mov    %eax,%esi
80104819:	83 c4 10             	add    $0x10,%esp
8010481c:	85 c0                	test   %eax,%eax
8010481e:	0f 84 ed 00 00 00    	je     80104911 <sys_unlink+0x12d>
  ilock(dp);
80104824:	83 ec 0c             	sub    $0xc,%esp
80104827:	50                   	push   %eax
80104828:	e8 60 cd ff ff       	call   8010158d <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
8010482d:	83 c4 08             	add    $0x8,%esp
80104830:	68 be 6e 10 80       	push   $0x80106ebe
80104835:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104838:	50                   	push   %eax
80104839:	e8 69 d1 ff ff       	call   801019a7 <namecmp>
8010483e:	83 c4 10             	add    $0x10,%esp
80104841:	85 c0                	test   %eax,%eax
80104843:	0f 84 fc 00 00 00    	je     80104945 <sys_unlink+0x161>
80104849:	83 ec 08             	sub    $0x8,%esp
8010484c:	68 bd 6e 10 80       	push   $0x80106ebd
80104851:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104854:	50                   	push   %eax
80104855:	e8 4d d1 ff ff       	call   801019a7 <namecmp>
8010485a:	83 c4 10             	add    $0x10,%esp
8010485d:	85 c0                	test   %eax,%eax
8010485f:	0f 84 e0 00 00 00    	je     80104945 <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
80104865:	83 ec 04             	sub    $0x4,%esp
80104868:	8d 45 c0             	lea    -0x40(%ebp),%eax
8010486b:	50                   	push   %eax
8010486c:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010486f:	50                   	push   %eax
80104870:	56                   	push   %esi
80104871:	e8 46 d1 ff ff       	call   801019bc <dirlookup>
80104876:	89 c3                	mov    %eax,%ebx
80104878:	83 c4 10             	add    $0x10,%esp
8010487b:	85 c0                	test   %eax,%eax
8010487d:	0f 84 c2 00 00 00    	je     80104945 <sys_unlink+0x161>
  ilock(ip);
80104883:	83 ec 0c             	sub    $0xc,%esp
80104886:	50                   	push   %eax
80104887:	e8 01 cd ff ff       	call   8010158d <ilock>
  if(ip->nlink < 1)
8010488c:	83 c4 10             	add    $0x10,%esp
8010488f:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
80104894:	0f 8e 83 00 00 00    	jle    8010491d <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010489a:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010489f:	0f 84 85 00 00 00    	je     8010492a <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
801048a5:	83 ec 04             	sub    $0x4,%esp
801048a8:	6a 10                	push   $0x10
801048aa:	6a 00                	push   $0x0
801048ac:	8d 7d d8             	lea    -0x28(%ebp),%edi
801048af:	57                   	push   %edi
801048b0:	e8 3f f6 ff ff       	call   80103ef4 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801048b5:	6a 10                	push   $0x10
801048b7:	ff 75 c0             	pushl  -0x40(%ebp)
801048ba:	57                   	push   %edi
801048bb:	56                   	push   %esi
801048bc:	e8 bb cf ff ff       	call   8010187c <writei>
801048c1:	83 c4 20             	add    $0x20,%esp
801048c4:	83 f8 10             	cmp    $0x10,%eax
801048c7:	0f 85 90 00 00 00    	jne    8010495d <sys_unlink+0x179>
  if(ip->type == T_DIR){
801048cd:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801048d2:	0f 84 92 00 00 00    	je     8010496a <sys_unlink+0x186>
  iunlockput(dp);
801048d8:	83 ec 0c             	sub    $0xc,%esp
801048db:	56                   	push   %esi
801048dc:	e8 53 ce ff ff       	call   80101734 <iunlockput>
  ip->nlink--;
801048e1:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801048e5:	83 e8 01             	sub    $0x1,%eax
801048e8:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801048ec:	89 1c 24             	mov    %ebx,(%esp)
801048ef:	e8 38 cb ff ff       	call   8010142c <iupdate>
  iunlockput(ip);
801048f4:	89 1c 24             	mov    %ebx,(%esp)
801048f7:	e8 38 ce ff ff       	call   80101734 <iunlockput>
  end_op();
801048fc:	e8 c4 e1 ff ff       	call   80102ac5 <end_op>
  return 0;
80104901:	83 c4 10             	add    $0x10,%esp
80104904:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104909:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010490c:	5b                   	pop    %ebx
8010490d:	5e                   	pop    %esi
8010490e:	5f                   	pop    %edi
8010490f:	5d                   	pop    %ebp
80104910:	c3                   	ret    
    end_op();
80104911:	e8 af e1 ff ff       	call   80102ac5 <end_op>
    return -1;
80104916:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010491b:	eb ec                	jmp    80104909 <sys_unlink+0x125>
    panic("unlink: nlink < 1");
8010491d:	83 ec 0c             	sub    $0xc,%esp
80104920:	68 dc 6e 10 80       	push   $0x80106edc
80104925:	e8 1e ba ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010492a:	89 d8                	mov    %ebx,%eax
8010492c:	e8 c4 f9 ff ff       	call   801042f5 <isdirempty>
80104931:	85 c0                	test   %eax,%eax
80104933:	0f 85 6c ff ff ff    	jne    801048a5 <sys_unlink+0xc1>
    iunlockput(ip);
80104939:	83 ec 0c             	sub    $0xc,%esp
8010493c:	53                   	push   %ebx
8010493d:	e8 f2 cd ff ff       	call   80101734 <iunlockput>
    goto bad;
80104942:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
80104945:	83 ec 0c             	sub    $0xc,%esp
80104948:	56                   	push   %esi
80104949:	e8 e6 cd ff ff       	call   80101734 <iunlockput>
  end_op();
8010494e:	e8 72 e1 ff ff       	call   80102ac5 <end_op>
  return -1;
80104953:	83 c4 10             	add    $0x10,%esp
80104956:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010495b:	eb ac                	jmp    80104909 <sys_unlink+0x125>
    panic("unlink: writei");
8010495d:	83 ec 0c             	sub    $0xc,%esp
80104960:	68 ee 6e 10 80       	push   $0x80106eee
80104965:	e8 de b9 ff ff       	call   80100348 <panic>
    dp->nlink--;
8010496a:	0f b7 46 56          	movzwl 0x56(%esi),%eax
8010496e:	83 e8 01             	sub    $0x1,%eax
80104971:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104975:	83 ec 0c             	sub    $0xc,%esp
80104978:	56                   	push   %esi
80104979:	e8 ae ca ff ff       	call   8010142c <iupdate>
8010497e:	83 c4 10             	add    $0x10,%esp
80104981:	e9 52 ff ff ff       	jmp    801048d8 <sys_unlink+0xf4>
    return -1;
80104986:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010498b:	e9 79 ff ff ff       	jmp    80104909 <sys_unlink+0x125>

80104990 <sys_open>:

int
sys_open(void)
{
80104990:	55                   	push   %ebp
80104991:	89 e5                	mov    %esp,%ebp
80104993:	57                   	push   %edi
80104994:	56                   	push   %esi
80104995:	53                   	push   %ebx
80104996:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80104999:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010499c:	50                   	push   %eax
8010499d:	6a 00                	push   $0x0
8010499f:	e8 2b f8 ff ff       	call   801041cf <argstr>
801049a4:	83 c4 10             	add    $0x10,%esp
801049a7:	85 c0                	test   %eax,%eax
801049a9:	0f 88 30 01 00 00    	js     80104adf <sys_open+0x14f>
801049af:	83 ec 08             	sub    $0x8,%esp
801049b2:	8d 45 e0             	lea    -0x20(%ebp),%eax
801049b5:	50                   	push   %eax
801049b6:	6a 01                	push   $0x1
801049b8:	e8 82 f7 ff ff       	call   8010413f <argint>
801049bd:	83 c4 10             	add    $0x10,%esp
801049c0:	85 c0                	test   %eax,%eax
801049c2:	0f 88 21 01 00 00    	js     80104ae9 <sys_open+0x159>
    return -1;

  begin_op();
801049c8:	e8 7e e0 ff ff       	call   80102a4b <begin_op>

  if(omode & O_CREATE){
801049cd:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
801049d1:	0f 84 84 00 00 00    	je     80104a5b <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
801049d7:	83 ec 0c             	sub    $0xc,%esp
801049da:	6a 00                	push   $0x0
801049dc:	b9 00 00 00 00       	mov    $0x0,%ecx
801049e1:	ba 02 00 00 00       	mov    $0x2,%edx
801049e6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801049e9:	e8 5e f9 ff ff       	call   8010434c <create>
801049ee:	89 c6                	mov    %eax,%esi
    if(ip == 0){
801049f0:	83 c4 10             	add    $0x10,%esp
801049f3:	85 c0                	test   %eax,%eax
801049f5:	74 58                	je     80104a4f <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
801049f7:	e8 3d c2 ff ff       	call   80100c39 <filealloc>
801049fc:	89 c3                	mov    %eax,%ebx
801049fe:	85 c0                	test   %eax,%eax
80104a00:	0f 84 ae 00 00 00    	je     80104ab4 <sys_open+0x124>
80104a06:	e8 b3 f8 ff ff       	call   801042be <fdalloc>
80104a0b:	89 c7                	mov    %eax,%edi
80104a0d:	85 c0                	test   %eax,%eax
80104a0f:	0f 88 9f 00 00 00    	js     80104ab4 <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104a15:	83 ec 0c             	sub    $0xc,%esp
80104a18:	56                   	push   %esi
80104a19:	e8 31 cc ff ff       	call   8010164f <iunlock>
  end_op();
80104a1e:	e8 a2 e0 ff ff       	call   80102ac5 <end_op>

  f->type = FD_INODE;
80104a23:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
80104a29:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104a2c:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
80104a33:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104a36:	83 c4 10             	add    $0x10,%esp
80104a39:	a8 01                	test   $0x1,%al
80104a3b:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80104a3f:	a8 03                	test   $0x3,%al
80104a41:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
80104a45:	89 f8                	mov    %edi,%eax
80104a47:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104a4a:	5b                   	pop    %ebx
80104a4b:	5e                   	pop    %esi
80104a4c:	5f                   	pop    %edi
80104a4d:	5d                   	pop    %ebp
80104a4e:	c3                   	ret    
      end_op();
80104a4f:	e8 71 e0 ff ff       	call   80102ac5 <end_op>
      return -1;
80104a54:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a59:	eb ea                	jmp    80104a45 <sys_open+0xb5>
    if((ip = namei(path)) == 0){
80104a5b:	83 ec 0c             	sub    $0xc,%esp
80104a5e:	ff 75 e4             	pushl  -0x1c(%ebp)
80104a61:	e8 87 d1 ff ff       	call   80101bed <namei>
80104a66:	89 c6                	mov    %eax,%esi
80104a68:	83 c4 10             	add    $0x10,%esp
80104a6b:	85 c0                	test   %eax,%eax
80104a6d:	74 39                	je     80104aa8 <sys_open+0x118>
    ilock(ip);
80104a6f:	83 ec 0c             	sub    $0xc,%esp
80104a72:	50                   	push   %eax
80104a73:	e8 15 cb ff ff       	call   8010158d <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80104a78:	83 c4 10             	add    $0x10,%esp
80104a7b:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104a80:	0f 85 71 ff ff ff    	jne    801049f7 <sys_open+0x67>
80104a86:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104a8a:	0f 84 67 ff ff ff    	je     801049f7 <sys_open+0x67>
      iunlockput(ip);
80104a90:	83 ec 0c             	sub    $0xc,%esp
80104a93:	56                   	push   %esi
80104a94:	e8 9b cc ff ff       	call   80101734 <iunlockput>
      end_op();
80104a99:	e8 27 e0 ff ff       	call   80102ac5 <end_op>
      return -1;
80104a9e:	83 c4 10             	add    $0x10,%esp
80104aa1:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104aa6:	eb 9d                	jmp    80104a45 <sys_open+0xb5>
      end_op();
80104aa8:	e8 18 e0 ff ff       	call   80102ac5 <end_op>
      return -1;
80104aad:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104ab2:	eb 91                	jmp    80104a45 <sys_open+0xb5>
    if(f)
80104ab4:	85 db                	test   %ebx,%ebx
80104ab6:	74 0c                	je     80104ac4 <sys_open+0x134>
      fileclose(f);
80104ab8:	83 ec 0c             	sub    $0xc,%esp
80104abb:	53                   	push   %ebx
80104abc:	e8 1e c2 ff ff       	call   80100cdf <fileclose>
80104ac1:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104ac4:	83 ec 0c             	sub    $0xc,%esp
80104ac7:	56                   	push   %esi
80104ac8:	e8 67 cc ff ff       	call   80101734 <iunlockput>
    end_op();
80104acd:	e8 f3 df ff ff       	call   80102ac5 <end_op>
    return -1;
80104ad2:	83 c4 10             	add    $0x10,%esp
80104ad5:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104ada:	e9 66 ff ff ff       	jmp    80104a45 <sys_open+0xb5>
    return -1;
80104adf:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104ae4:	e9 5c ff ff ff       	jmp    80104a45 <sys_open+0xb5>
80104ae9:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104aee:	e9 52 ff ff ff       	jmp    80104a45 <sys_open+0xb5>

80104af3 <sys_mkdir>:

int
sys_mkdir(void)
{
80104af3:	55                   	push   %ebp
80104af4:	89 e5                	mov    %esp,%ebp
80104af6:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104af9:	e8 4d df ff ff       	call   80102a4b <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104afe:	83 ec 08             	sub    $0x8,%esp
80104b01:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b04:	50                   	push   %eax
80104b05:	6a 00                	push   $0x0
80104b07:	e8 c3 f6 ff ff       	call   801041cf <argstr>
80104b0c:	83 c4 10             	add    $0x10,%esp
80104b0f:	85 c0                	test   %eax,%eax
80104b11:	78 36                	js     80104b49 <sys_mkdir+0x56>
80104b13:	83 ec 0c             	sub    $0xc,%esp
80104b16:	6a 00                	push   $0x0
80104b18:	b9 00 00 00 00       	mov    $0x0,%ecx
80104b1d:	ba 01 00 00 00       	mov    $0x1,%edx
80104b22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b25:	e8 22 f8 ff ff       	call   8010434c <create>
80104b2a:	83 c4 10             	add    $0x10,%esp
80104b2d:	85 c0                	test   %eax,%eax
80104b2f:	74 18                	je     80104b49 <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104b31:	83 ec 0c             	sub    $0xc,%esp
80104b34:	50                   	push   %eax
80104b35:	e8 fa cb ff ff       	call   80101734 <iunlockput>
  end_op();
80104b3a:	e8 86 df ff ff       	call   80102ac5 <end_op>
  return 0;
80104b3f:	83 c4 10             	add    $0x10,%esp
80104b42:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104b47:	c9                   	leave  
80104b48:	c3                   	ret    
    end_op();
80104b49:	e8 77 df ff ff       	call   80102ac5 <end_op>
    return -1;
80104b4e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b53:	eb f2                	jmp    80104b47 <sys_mkdir+0x54>

80104b55 <sys_mknod>:

int
sys_mknod(void)
{
80104b55:	55                   	push   %ebp
80104b56:	89 e5                	mov    %esp,%ebp
80104b58:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104b5b:	e8 eb de ff ff       	call   80102a4b <begin_op>
  if((argstr(0, &path)) < 0 ||
80104b60:	83 ec 08             	sub    $0x8,%esp
80104b63:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b66:	50                   	push   %eax
80104b67:	6a 00                	push   $0x0
80104b69:	e8 61 f6 ff ff       	call   801041cf <argstr>
80104b6e:	83 c4 10             	add    $0x10,%esp
80104b71:	85 c0                	test   %eax,%eax
80104b73:	78 62                	js     80104bd7 <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104b75:	83 ec 08             	sub    $0x8,%esp
80104b78:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104b7b:	50                   	push   %eax
80104b7c:	6a 01                	push   $0x1
80104b7e:	e8 bc f5 ff ff       	call   8010413f <argint>
  if((argstr(0, &path)) < 0 ||
80104b83:	83 c4 10             	add    $0x10,%esp
80104b86:	85 c0                	test   %eax,%eax
80104b88:	78 4d                	js     80104bd7 <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104b8a:	83 ec 08             	sub    $0x8,%esp
80104b8d:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104b90:	50                   	push   %eax
80104b91:	6a 02                	push   $0x2
80104b93:	e8 a7 f5 ff ff       	call   8010413f <argint>
     argint(1, &major) < 0 ||
80104b98:	83 c4 10             	add    $0x10,%esp
80104b9b:	85 c0                	test   %eax,%eax
80104b9d:	78 38                	js     80104bd7 <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104b9f:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104ba3:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104ba7:	83 ec 0c             	sub    $0xc,%esp
80104baa:	50                   	push   %eax
80104bab:	ba 03 00 00 00       	mov    $0x3,%edx
80104bb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bb3:	e8 94 f7 ff ff       	call   8010434c <create>
80104bb8:	83 c4 10             	add    $0x10,%esp
80104bbb:	85 c0                	test   %eax,%eax
80104bbd:	74 18                	je     80104bd7 <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104bbf:	83 ec 0c             	sub    $0xc,%esp
80104bc2:	50                   	push   %eax
80104bc3:	e8 6c cb ff ff       	call   80101734 <iunlockput>
  end_op();
80104bc8:	e8 f8 de ff ff       	call   80102ac5 <end_op>
  return 0;
80104bcd:	83 c4 10             	add    $0x10,%esp
80104bd0:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104bd5:	c9                   	leave  
80104bd6:	c3                   	ret    
    end_op();
80104bd7:	e8 e9 de ff ff       	call   80102ac5 <end_op>
    return -1;
80104bdc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104be1:	eb f2                	jmp    80104bd5 <sys_mknod+0x80>

80104be3 <sys_chdir>:

int
sys_chdir(void)
{
80104be3:	55                   	push   %ebp
80104be4:	89 e5                	mov    %esp,%ebp
80104be6:	56                   	push   %esi
80104be7:	53                   	push   %ebx
80104be8:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104beb:	e8 b6 e8 ff ff       	call   801034a6 <myproc>
80104bf0:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104bf2:	e8 54 de ff ff       	call   80102a4b <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104bf7:	83 ec 08             	sub    $0x8,%esp
80104bfa:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104bfd:	50                   	push   %eax
80104bfe:	6a 00                	push   $0x0
80104c00:	e8 ca f5 ff ff       	call   801041cf <argstr>
80104c05:	83 c4 10             	add    $0x10,%esp
80104c08:	85 c0                	test   %eax,%eax
80104c0a:	78 52                	js     80104c5e <sys_chdir+0x7b>
80104c0c:	83 ec 0c             	sub    $0xc,%esp
80104c0f:	ff 75 f4             	pushl  -0xc(%ebp)
80104c12:	e8 d6 cf ff ff       	call   80101bed <namei>
80104c17:	89 c3                	mov    %eax,%ebx
80104c19:	83 c4 10             	add    $0x10,%esp
80104c1c:	85 c0                	test   %eax,%eax
80104c1e:	74 3e                	je     80104c5e <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104c20:	83 ec 0c             	sub    $0xc,%esp
80104c23:	50                   	push   %eax
80104c24:	e8 64 c9 ff ff       	call   8010158d <ilock>
  if(ip->type != T_DIR){
80104c29:	83 c4 10             	add    $0x10,%esp
80104c2c:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104c31:	75 37                	jne    80104c6a <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104c33:	83 ec 0c             	sub    $0xc,%esp
80104c36:	53                   	push   %ebx
80104c37:	e8 13 ca ff ff       	call   8010164f <iunlock>
  iput(curproc->cwd);
80104c3c:	83 c4 04             	add    $0x4,%esp
80104c3f:	ff 76 68             	pushl  0x68(%esi)
80104c42:	e8 4d ca ff ff       	call   80101694 <iput>
  end_op();
80104c47:	e8 79 de ff ff       	call   80102ac5 <end_op>
  curproc->cwd = ip;
80104c4c:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104c4f:	83 c4 10             	add    $0x10,%esp
80104c52:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104c57:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104c5a:	5b                   	pop    %ebx
80104c5b:	5e                   	pop    %esi
80104c5c:	5d                   	pop    %ebp
80104c5d:	c3                   	ret    
    end_op();
80104c5e:	e8 62 de ff ff       	call   80102ac5 <end_op>
    return -1;
80104c63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c68:	eb ed                	jmp    80104c57 <sys_chdir+0x74>
    iunlockput(ip);
80104c6a:	83 ec 0c             	sub    $0xc,%esp
80104c6d:	53                   	push   %ebx
80104c6e:	e8 c1 ca ff ff       	call   80101734 <iunlockput>
    end_op();
80104c73:	e8 4d de ff ff       	call   80102ac5 <end_op>
    return -1;
80104c78:	83 c4 10             	add    $0x10,%esp
80104c7b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c80:	eb d5                	jmp    80104c57 <sys_chdir+0x74>

80104c82 <sys_exec>:

int
sys_exec(void)
{
80104c82:	55                   	push   %ebp
80104c83:	89 e5                	mov    %esp,%ebp
80104c85:	53                   	push   %ebx
80104c86:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104c8c:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c8f:	50                   	push   %eax
80104c90:	6a 00                	push   $0x0
80104c92:	e8 38 f5 ff ff       	call   801041cf <argstr>
80104c97:	83 c4 10             	add    $0x10,%esp
80104c9a:	85 c0                	test   %eax,%eax
80104c9c:	0f 88 a8 00 00 00    	js     80104d4a <sys_exec+0xc8>
80104ca2:	83 ec 08             	sub    $0x8,%esp
80104ca5:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104cab:	50                   	push   %eax
80104cac:	6a 01                	push   $0x1
80104cae:	e8 8c f4 ff ff       	call   8010413f <argint>
80104cb3:	83 c4 10             	add    $0x10,%esp
80104cb6:	85 c0                	test   %eax,%eax
80104cb8:	0f 88 93 00 00 00    	js     80104d51 <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104cbe:	83 ec 04             	sub    $0x4,%esp
80104cc1:	68 80 00 00 00       	push   $0x80
80104cc6:	6a 00                	push   $0x0
80104cc8:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104cce:	50                   	push   %eax
80104ccf:	e8 20 f2 ff ff       	call   80103ef4 <memset>
80104cd4:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104cd7:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104cdc:	83 fb 1f             	cmp    $0x1f,%ebx
80104cdf:	77 77                	ja     80104d58 <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104ce1:	83 ec 08             	sub    $0x8,%esp
80104ce4:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104cea:	50                   	push   %eax
80104ceb:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104cf1:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104cf4:	50                   	push   %eax
80104cf5:	e8 c9 f3 ff ff       	call   801040c3 <fetchint>
80104cfa:	83 c4 10             	add    $0x10,%esp
80104cfd:	85 c0                	test   %eax,%eax
80104cff:	78 5e                	js     80104d5f <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104d01:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104d07:	85 c0                	test   %eax,%eax
80104d09:	74 1d                	je     80104d28 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104d0b:	83 ec 08             	sub    $0x8,%esp
80104d0e:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104d15:	52                   	push   %edx
80104d16:	50                   	push   %eax
80104d17:	e8 e3 f3 ff ff       	call   801040ff <fetchstr>
80104d1c:	83 c4 10             	add    $0x10,%esp
80104d1f:	85 c0                	test   %eax,%eax
80104d21:	78 46                	js     80104d69 <sys_exec+0xe7>
  for(i=0;; i++){
80104d23:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104d26:	eb b4                	jmp    80104cdc <sys_exec+0x5a>
      argv[i] = 0;
80104d28:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104d2f:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104d33:	83 ec 08             	sub    $0x8,%esp
80104d36:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104d3c:	50                   	push   %eax
80104d3d:	ff 75 f4             	pushl  -0xc(%ebp)
80104d40:	e8 8d bb ff ff       	call   801008d2 <exec>
80104d45:	83 c4 10             	add    $0x10,%esp
80104d48:	eb 1a                	jmp    80104d64 <sys_exec+0xe2>
    return -1;
80104d4a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d4f:	eb 13                	jmp    80104d64 <sys_exec+0xe2>
80104d51:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d56:	eb 0c                	jmp    80104d64 <sys_exec+0xe2>
      return -1;
80104d58:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d5d:	eb 05                	jmp    80104d64 <sys_exec+0xe2>
      return -1;
80104d5f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104d64:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104d67:	c9                   	leave  
80104d68:	c3                   	ret    
      return -1;
80104d69:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d6e:	eb f4                	jmp    80104d64 <sys_exec+0xe2>

80104d70 <sys_pipe>:

int
sys_pipe(void)
{
80104d70:	55                   	push   %ebp
80104d71:	89 e5                	mov    %esp,%ebp
80104d73:	53                   	push   %ebx
80104d74:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104d77:	6a 08                	push   $0x8
80104d79:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d7c:	50                   	push   %eax
80104d7d:	6a 00                	push   $0x0
80104d7f:	e8 e3 f3 ff ff       	call   80104167 <argptr>
80104d84:	83 c4 10             	add    $0x10,%esp
80104d87:	85 c0                	test   %eax,%eax
80104d89:	78 77                	js     80104e02 <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104d8b:	83 ec 08             	sub    $0x8,%esp
80104d8e:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104d91:	50                   	push   %eax
80104d92:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104d95:	50                   	push   %eax
80104d96:	e8 3c e2 ff ff       	call   80102fd7 <pipealloc>
80104d9b:	83 c4 10             	add    $0x10,%esp
80104d9e:	85 c0                	test   %eax,%eax
80104da0:	78 67                	js     80104e09 <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104da2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104da5:	e8 14 f5 ff ff       	call   801042be <fdalloc>
80104daa:	89 c3                	mov    %eax,%ebx
80104dac:	85 c0                	test   %eax,%eax
80104dae:	78 21                	js     80104dd1 <sys_pipe+0x61>
80104db0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104db3:	e8 06 f5 ff ff       	call   801042be <fdalloc>
80104db8:	85 c0                	test   %eax,%eax
80104dba:	78 15                	js     80104dd1 <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104dbc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104dbf:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104dc1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104dc4:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104dc7:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104dcc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104dcf:	c9                   	leave  
80104dd0:	c3                   	ret    
    if(fd0 >= 0)
80104dd1:	85 db                	test   %ebx,%ebx
80104dd3:	78 0d                	js     80104de2 <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104dd5:	e8 cc e6 ff ff       	call   801034a6 <myproc>
80104dda:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104de1:	00 
    fileclose(rf);
80104de2:	83 ec 0c             	sub    $0xc,%esp
80104de5:	ff 75 f0             	pushl  -0x10(%ebp)
80104de8:	e8 f2 be ff ff       	call   80100cdf <fileclose>
    fileclose(wf);
80104ded:	83 c4 04             	add    $0x4,%esp
80104df0:	ff 75 ec             	pushl  -0x14(%ebp)
80104df3:	e8 e7 be ff ff       	call   80100cdf <fileclose>
    return -1;
80104df8:	83 c4 10             	add    $0x10,%esp
80104dfb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e00:	eb ca                	jmp    80104dcc <sys_pipe+0x5c>
    return -1;
80104e02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e07:	eb c3                	jmp    80104dcc <sys_pipe+0x5c>
    return -1;
80104e09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e0e:	eb bc                	jmp    80104dcc <sys_pipe+0x5c>

80104e10 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104e10:	55                   	push   %ebp
80104e11:	89 e5                	mov    %esp,%ebp
80104e13:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104e16:	e8 03 e8 ff ff       	call   8010361e <fork>
}
80104e1b:	c9                   	leave  
80104e1c:	c3                   	ret    

80104e1d <sys_exit>:

int
sys_exit(void)
{
80104e1d:	55                   	push   %ebp
80104e1e:	89 e5                	mov    %esp,%ebp
80104e20:	83 ec 08             	sub    $0x8,%esp
  exit();
80104e23:	e8 2d ea ff ff       	call   80103855 <exit>
  return 0;  // not reached
}
80104e28:	b8 00 00 00 00       	mov    $0x0,%eax
80104e2d:	c9                   	leave  
80104e2e:	c3                   	ret    

80104e2f <sys_wait>:

int
sys_wait(void)
{
80104e2f:	55                   	push   %ebp
80104e30:	89 e5                	mov    %esp,%ebp
80104e32:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104e35:	e8 a4 eb ff ff       	call   801039de <wait>
}
80104e3a:	c9                   	leave  
80104e3b:	c3                   	ret    

80104e3c <sys_kill>:

int
sys_kill(void)
{
80104e3c:	55                   	push   %ebp
80104e3d:	89 e5                	mov    %esp,%ebp
80104e3f:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104e42:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e45:	50                   	push   %eax
80104e46:	6a 00                	push   $0x0
80104e48:	e8 f2 f2 ff ff       	call   8010413f <argint>
80104e4d:	83 c4 10             	add    $0x10,%esp
80104e50:	85 c0                	test   %eax,%eax
80104e52:	78 10                	js     80104e64 <sys_kill+0x28>
    return -1;
  return kill(pid);
80104e54:	83 ec 0c             	sub    $0xc,%esp
80104e57:	ff 75 f4             	pushl  -0xc(%ebp)
80104e5a:	e8 7c ec ff ff       	call   80103adb <kill>
80104e5f:	83 c4 10             	add    $0x10,%esp
}
80104e62:	c9                   	leave  
80104e63:	c3                   	ret    
    return -1;
80104e64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e69:	eb f7                	jmp    80104e62 <sys_kill+0x26>

80104e6b <sys_getpid>:

int
sys_getpid(void)
{
80104e6b:	55                   	push   %ebp
80104e6c:	89 e5                	mov    %esp,%ebp
80104e6e:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104e71:	e8 30 e6 ff ff       	call   801034a6 <myproc>
80104e76:	8b 40 10             	mov    0x10(%eax),%eax
}
80104e79:	c9                   	leave  
80104e7a:	c3                   	ret    

80104e7b <sys_sbrk>:

int
sys_sbrk(void)
{
80104e7b:	55                   	push   %ebp
80104e7c:	89 e5                	mov    %esp,%ebp
80104e7e:	53                   	push   %ebx
80104e7f:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104e82:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e85:	50                   	push   %eax
80104e86:	6a 00                	push   $0x0
80104e88:	e8 b2 f2 ff ff       	call   8010413f <argint>
80104e8d:	83 c4 10             	add    $0x10,%esp
80104e90:	85 c0                	test   %eax,%eax
80104e92:	78 27                	js     80104ebb <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104e94:	e8 0d e6 ff ff       	call   801034a6 <myproc>
80104e99:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104e9b:	83 ec 0c             	sub    $0xc,%esp
80104e9e:	ff 75 f4             	pushl  -0xc(%ebp)
80104ea1:	e8 0b e7 ff ff       	call   801035b1 <growproc>
80104ea6:	83 c4 10             	add    $0x10,%esp
80104ea9:	85 c0                	test   %eax,%eax
80104eab:	78 07                	js     80104eb4 <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104ead:	89 d8                	mov    %ebx,%eax
80104eaf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104eb2:	c9                   	leave  
80104eb3:	c3                   	ret    
    return -1;
80104eb4:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104eb9:	eb f2                	jmp    80104ead <sys_sbrk+0x32>
    return -1;
80104ebb:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104ec0:	eb eb                	jmp    80104ead <sys_sbrk+0x32>

80104ec2 <sys_sleep>:

int
sys_sleep(void)
{
80104ec2:	55                   	push   %ebp
80104ec3:	89 e5                	mov    %esp,%ebp
80104ec5:	53                   	push   %ebx
80104ec6:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104ec9:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ecc:	50                   	push   %eax
80104ecd:	6a 00                	push   $0x0
80104ecf:	e8 6b f2 ff ff       	call   8010413f <argint>
80104ed4:	83 c4 10             	add    $0x10,%esp
80104ed7:	85 c0                	test   %eax,%eax
80104ed9:	78 75                	js     80104f50 <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104edb:	83 ec 0c             	sub    $0xc,%esp
80104ede:	68 c0 5f 13 80       	push   $0x80135fc0
80104ee3:	e8 60 ef ff ff       	call   80103e48 <acquire>
  ticks0 = ticks;
80104ee8:	8b 1d 00 68 13 80    	mov    0x80136800,%ebx
  while(ticks - ticks0 < n){
80104eee:	83 c4 10             	add    $0x10,%esp
80104ef1:	a1 00 68 13 80       	mov    0x80136800,%eax
80104ef6:	29 d8                	sub    %ebx,%eax
80104ef8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104efb:	73 39                	jae    80104f36 <sys_sleep+0x74>
    if(myproc()->killed){
80104efd:	e8 a4 e5 ff ff       	call   801034a6 <myproc>
80104f02:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f06:	75 17                	jne    80104f1f <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104f08:	83 ec 08             	sub    $0x8,%esp
80104f0b:	68 c0 5f 13 80       	push   $0x80135fc0
80104f10:	68 00 68 13 80       	push   $0x80136800
80104f15:	e8 33 ea ff ff       	call   8010394d <sleep>
80104f1a:	83 c4 10             	add    $0x10,%esp
80104f1d:	eb d2                	jmp    80104ef1 <sys_sleep+0x2f>
      release(&tickslock);
80104f1f:	83 ec 0c             	sub    $0xc,%esp
80104f22:	68 c0 5f 13 80       	push   $0x80135fc0
80104f27:	e8 81 ef ff ff       	call   80103ead <release>
      return -1;
80104f2c:	83 c4 10             	add    $0x10,%esp
80104f2f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f34:	eb 15                	jmp    80104f4b <sys_sleep+0x89>
  }
  release(&tickslock);
80104f36:	83 ec 0c             	sub    $0xc,%esp
80104f39:	68 c0 5f 13 80       	push   $0x80135fc0
80104f3e:	e8 6a ef ff ff       	call   80103ead <release>
  return 0;
80104f43:	83 c4 10             	add    $0x10,%esp
80104f46:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104f4b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104f4e:	c9                   	leave  
80104f4f:	c3                   	ret    
    return -1;
80104f50:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f55:	eb f4                	jmp    80104f4b <sys_sleep+0x89>

80104f57 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104f57:	55                   	push   %ebp
80104f58:	89 e5                	mov    %esp,%ebp
80104f5a:	53                   	push   %ebx
80104f5b:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104f5e:	68 c0 5f 13 80       	push   $0x80135fc0
80104f63:	e8 e0 ee ff ff       	call   80103e48 <acquire>
  xticks = ticks;
80104f68:	8b 1d 00 68 13 80    	mov    0x80136800,%ebx
  release(&tickslock);
80104f6e:	c7 04 24 c0 5f 13 80 	movl   $0x80135fc0,(%esp)
80104f75:	e8 33 ef ff ff       	call   80103ead <release>
  return xticks;
}
80104f7a:	89 d8                	mov    %ebx,%eax
80104f7c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104f7f:	c9                   	leave  
80104f80:	c3                   	ret    

80104f81 <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80104f81:	55                   	push   %ebp
80104f82:	89 e5                	mov    %esp,%ebp
80104f84:	83 ec 1c             	sub    $0x1c,%esp
  int *frames;
  int *pids;
  int numframes;
  if(argptr(0, (char**)(&frames), sizeof(*frames)) < 0)
80104f87:	6a 04                	push   $0x4
80104f89:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104f8c:	50                   	push   %eax
80104f8d:	6a 00                	push   $0x0
80104f8f:	e8 d3 f1 ff ff       	call   80104167 <argptr>
80104f94:	83 c4 10             	add    $0x10,%esp
80104f97:	85 c0                	test   %eax,%eax
80104f99:	78 42                	js     80104fdd <sys_dump_physmem+0x5c>
    return -1;
  if(argptr(1, (char**)(&pids), sizeof(*pids)) < 0)
80104f9b:	83 ec 04             	sub    $0x4,%esp
80104f9e:	6a 04                	push   $0x4
80104fa0:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104fa3:	50                   	push   %eax
80104fa4:	6a 01                	push   $0x1
80104fa6:	e8 bc f1 ff ff       	call   80104167 <argptr>
80104fab:	83 c4 10             	add    $0x10,%esp
80104fae:	85 c0                	test   %eax,%eax
80104fb0:	78 32                	js     80104fe4 <sys_dump_physmem+0x63>
    return -1;
  if(argint(2, &numframes) < 0)
80104fb2:	83 ec 08             	sub    $0x8,%esp
80104fb5:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104fb8:	50                   	push   %eax
80104fb9:	6a 02                	push   $0x2
80104fbb:	e8 7f f1 ff ff       	call   8010413f <argint>
80104fc0:	83 c4 10             	add    $0x10,%esp
80104fc3:	85 c0                	test   %eax,%eax
80104fc5:	78 24                	js     80104feb <sys_dump_physmem+0x6a>
    return -1;

  return dump_physmem(frames, pids, numframes);
80104fc7:	83 ec 04             	sub    $0x4,%esp
80104fca:	ff 75 ec             	pushl  -0x14(%ebp)
80104fcd:	ff 75 f0             	pushl  -0x10(%ebp)
80104fd0:	ff 75 f4             	pushl  -0xc(%ebp)
80104fd3:	e8 52 d3 ff ff       	call   8010232a <dump_physmem>
80104fd8:	83 c4 10             	add    $0x10,%esp
80104fdb:	c9                   	leave  
80104fdc:	c3                   	ret    
    return -1;
80104fdd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fe2:	eb f7                	jmp    80104fdb <sys_dump_physmem+0x5a>
    return -1;
80104fe4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fe9:	eb f0                	jmp    80104fdb <sys_dump_physmem+0x5a>
    return -1;
80104feb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ff0:	eb e9                	jmp    80104fdb <sys_dump_physmem+0x5a>

80104ff2 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104ff2:	1e                   	push   %ds
  pushl %es
80104ff3:	06                   	push   %es
  pushl %fs
80104ff4:	0f a0                	push   %fs
  pushl %gs
80104ff6:	0f a8                	push   %gs
  pushal
80104ff8:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104ff9:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104ffd:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104fff:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80105001:	54                   	push   %esp
  call trap
80105002:	e8 e3 00 00 00       	call   801050ea <trap>
  addl $4, %esp
80105007:	83 c4 04             	add    $0x4,%esp

8010500a <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
8010500a:	61                   	popa   
  popl %gs
8010500b:	0f a9                	pop    %gs
  popl %fs
8010500d:	0f a1                	pop    %fs
  popl %es
8010500f:	07                   	pop    %es
  popl %ds
80105010:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80105011:	83 c4 08             	add    $0x8,%esp
  iret
80105014:	cf                   	iret   

80105015 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80105015:	55                   	push   %ebp
80105016:	89 e5                	mov    %esp,%ebp
80105018:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
8010501b:	b8 00 00 00 00       	mov    $0x0,%eax
80105020:	eb 4a                	jmp    8010506c <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80105022:	8b 0c 85 08 a0 10 80 	mov    -0x7fef5ff8(,%eax,4),%ecx
80105029:	66 89 0c c5 00 60 13 	mov    %cx,-0x7feca000(,%eax,8)
80105030:	80 
80105031:	66 c7 04 c5 02 60 13 	movw   $0x8,-0x7fec9ffe(,%eax,8)
80105038:	80 08 00 
8010503b:	c6 04 c5 04 60 13 80 	movb   $0x0,-0x7fec9ffc(,%eax,8)
80105042:	00 
80105043:	0f b6 14 c5 05 60 13 	movzbl -0x7fec9ffb(,%eax,8),%edx
8010504a:	80 
8010504b:	83 e2 f0             	and    $0xfffffff0,%edx
8010504e:	83 ca 0e             	or     $0xe,%edx
80105051:	83 e2 8f             	and    $0xffffff8f,%edx
80105054:	83 ca 80             	or     $0xffffff80,%edx
80105057:	88 14 c5 05 60 13 80 	mov    %dl,-0x7fec9ffb(,%eax,8)
8010505e:	c1 e9 10             	shr    $0x10,%ecx
80105061:	66 89 0c c5 06 60 13 	mov    %cx,-0x7fec9ffa(,%eax,8)
80105068:	80 
  for(i = 0; i < 256; i++)
80105069:	83 c0 01             	add    $0x1,%eax
8010506c:	3d ff 00 00 00       	cmp    $0xff,%eax
80105071:	7e af                	jle    80105022 <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80105073:	8b 15 08 a1 10 80    	mov    0x8010a108,%edx
80105079:	66 89 15 00 62 13 80 	mov    %dx,0x80136200
80105080:	66 c7 05 02 62 13 80 	movw   $0x8,0x80136202
80105087:	08 00 
80105089:	c6 05 04 62 13 80 00 	movb   $0x0,0x80136204
80105090:	0f b6 05 05 62 13 80 	movzbl 0x80136205,%eax
80105097:	83 c8 0f             	or     $0xf,%eax
8010509a:	83 e0 ef             	and    $0xffffffef,%eax
8010509d:	83 c8 e0             	or     $0xffffffe0,%eax
801050a0:	a2 05 62 13 80       	mov    %al,0x80136205
801050a5:	c1 ea 10             	shr    $0x10,%edx
801050a8:	66 89 15 06 62 13 80 	mov    %dx,0x80136206

  initlock(&tickslock, "time");
801050af:	83 ec 08             	sub    $0x8,%esp
801050b2:	68 fd 6e 10 80       	push   $0x80106efd
801050b7:	68 c0 5f 13 80       	push   $0x80135fc0
801050bc:	e8 4b ec ff ff       	call   80103d0c <initlock>
}
801050c1:	83 c4 10             	add    $0x10,%esp
801050c4:	c9                   	leave  
801050c5:	c3                   	ret    

801050c6 <idtinit>:

void
idtinit(void)
{
801050c6:	55                   	push   %ebp
801050c7:	89 e5                	mov    %esp,%ebp
801050c9:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
801050cc:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
801050d2:	b8 00 60 13 80       	mov    $0x80136000,%eax
801050d7:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801050db:	c1 e8 10             	shr    $0x10,%eax
801050de:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
801050e2:	8d 45 fa             	lea    -0x6(%ebp),%eax
801050e5:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
801050e8:	c9                   	leave  
801050e9:	c3                   	ret    

801050ea <trap>:

void
trap(struct trapframe *tf)
{
801050ea:	55                   	push   %ebp
801050eb:	89 e5                	mov    %esp,%ebp
801050ed:	57                   	push   %edi
801050ee:	56                   	push   %esi
801050ef:	53                   	push   %ebx
801050f0:	83 ec 1c             	sub    $0x1c,%esp
801050f3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
801050f6:	8b 43 30             	mov    0x30(%ebx),%eax
801050f9:	83 f8 40             	cmp    $0x40,%eax
801050fc:	74 13                	je     80105111 <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
801050fe:	83 e8 20             	sub    $0x20,%eax
80105101:	83 f8 1f             	cmp    $0x1f,%eax
80105104:	0f 87 3a 01 00 00    	ja     80105244 <trap+0x15a>
8010510a:	ff 24 85 a4 6f 10 80 	jmp    *-0x7fef905c(,%eax,4)
    if(myproc()->killed)
80105111:	e8 90 e3 ff ff       	call   801034a6 <myproc>
80105116:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010511a:	75 1f                	jne    8010513b <trap+0x51>
    myproc()->tf = tf;
8010511c:	e8 85 e3 ff ff       	call   801034a6 <myproc>
80105121:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80105124:	e8 d9 f0 ff ff       	call   80104202 <syscall>
    if(myproc()->killed)
80105129:	e8 78 e3 ff ff       	call   801034a6 <myproc>
8010512e:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105132:	74 7e                	je     801051b2 <trap+0xc8>
      exit();
80105134:	e8 1c e7 ff ff       	call   80103855 <exit>
80105139:	eb 77                	jmp    801051b2 <trap+0xc8>
      exit();
8010513b:	e8 15 e7 ff ff       	call   80103855 <exit>
80105140:	eb da                	jmp    8010511c <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80105142:	e8 44 e3 ff ff       	call   8010348b <cpuid>
80105147:	85 c0                	test   %eax,%eax
80105149:	74 6f                	je     801051ba <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
8010514b:	e8 e6 d4 ff ff       	call   80102636 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105150:	e8 51 e3 ff ff       	call   801034a6 <myproc>
80105155:	85 c0                	test   %eax,%eax
80105157:	74 1c                	je     80105175 <trap+0x8b>
80105159:	e8 48 e3 ff ff       	call   801034a6 <myproc>
8010515e:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105162:	74 11                	je     80105175 <trap+0x8b>
80105164:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105168:	83 e0 03             	and    $0x3,%eax
8010516b:	66 83 f8 03          	cmp    $0x3,%ax
8010516f:	0f 84 62 01 00 00    	je     801052d7 <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80105175:	e8 2c e3 ff ff       	call   801034a6 <myproc>
8010517a:	85 c0                	test   %eax,%eax
8010517c:	74 0f                	je     8010518d <trap+0xa3>
8010517e:	e8 23 e3 ff ff       	call   801034a6 <myproc>
80105183:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80105187:	0f 84 54 01 00 00    	je     801052e1 <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
8010518d:	e8 14 e3 ff ff       	call   801034a6 <myproc>
80105192:	85 c0                	test   %eax,%eax
80105194:	74 1c                	je     801051b2 <trap+0xc8>
80105196:	e8 0b e3 ff ff       	call   801034a6 <myproc>
8010519b:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010519f:	74 11                	je     801051b2 <trap+0xc8>
801051a1:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
801051a5:	83 e0 03             	and    $0x3,%eax
801051a8:	66 83 f8 03          	cmp    $0x3,%ax
801051ac:	0f 84 43 01 00 00    	je     801052f5 <trap+0x20b>
    exit();
}
801051b2:	8d 65 f4             	lea    -0xc(%ebp),%esp
801051b5:	5b                   	pop    %ebx
801051b6:	5e                   	pop    %esi
801051b7:	5f                   	pop    %edi
801051b8:	5d                   	pop    %ebp
801051b9:	c3                   	ret    
      acquire(&tickslock);
801051ba:	83 ec 0c             	sub    $0xc,%esp
801051bd:	68 c0 5f 13 80       	push   $0x80135fc0
801051c2:	e8 81 ec ff ff       	call   80103e48 <acquire>
      ticks++;
801051c7:	83 05 00 68 13 80 01 	addl   $0x1,0x80136800
      wakeup(&ticks);
801051ce:	c7 04 24 00 68 13 80 	movl   $0x80136800,(%esp)
801051d5:	e8 d8 e8 ff ff       	call   80103ab2 <wakeup>
      release(&tickslock);
801051da:	c7 04 24 c0 5f 13 80 	movl   $0x80135fc0,(%esp)
801051e1:	e8 c7 ec ff ff       	call   80103ead <release>
801051e6:	83 c4 10             	add    $0x10,%esp
801051e9:	e9 5d ff ff ff       	jmp    8010514b <trap+0x61>
    ideintr();
801051ee:	e8 8c cb ff ff       	call   80101d7f <ideintr>
    lapiceoi();
801051f3:	e8 3e d4 ff ff       	call   80102636 <lapiceoi>
    break;
801051f8:	e9 53 ff ff ff       	jmp    80105150 <trap+0x66>
    kbdintr();
801051fd:	e8 78 d2 ff ff       	call   8010247a <kbdintr>
    lapiceoi();
80105202:	e8 2f d4 ff ff       	call   80102636 <lapiceoi>
    break;
80105207:	e9 44 ff ff ff       	jmp    80105150 <trap+0x66>
    uartintr();
8010520c:	e8 05 02 00 00       	call   80105416 <uartintr>
    lapiceoi();
80105211:	e8 20 d4 ff ff       	call   80102636 <lapiceoi>
    break;
80105216:	e9 35 ff ff ff       	jmp    80105150 <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010521b:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
8010521e:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105222:	e8 64 e2 ff ff       	call   8010348b <cpuid>
80105227:	57                   	push   %edi
80105228:	0f b7 f6             	movzwl %si,%esi
8010522b:	56                   	push   %esi
8010522c:	50                   	push   %eax
8010522d:	68 08 6f 10 80       	push   $0x80106f08
80105232:	e8 d4 b3 ff ff       	call   8010060b <cprintf>
    lapiceoi();
80105237:	e8 fa d3 ff ff       	call   80102636 <lapiceoi>
    break;
8010523c:	83 c4 10             	add    $0x10,%esp
8010523f:	e9 0c ff ff ff       	jmp    80105150 <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
80105244:	e8 5d e2 ff ff       	call   801034a6 <myproc>
80105249:	85 c0                	test   %eax,%eax
8010524b:	74 5f                	je     801052ac <trap+0x1c2>
8010524d:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
80105251:	74 59                	je     801052ac <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80105253:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105256:	8b 43 38             	mov    0x38(%ebx),%eax
80105259:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010525c:	e8 2a e2 ff ff       	call   8010348b <cpuid>
80105261:	89 45 e0             	mov    %eax,-0x20(%ebp)
80105264:	8b 53 34             	mov    0x34(%ebx),%edx
80105267:	89 55 dc             	mov    %edx,-0x24(%ebp)
8010526a:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
8010526d:	e8 34 e2 ff ff       	call   801034a6 <myproc>
80105272:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105275:	89 4d d8             	mov    %ecx,-0x28(%ebp)
80105278:	e8 29 e2 ff ff       	call   801034a6 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010527d:	57                   	push   %edi
8010527e:	ff 75 e4             	pushl  -0x1c(%ebp)
80105281:	ff 75 e0             	pushl  -0x20(%ebp)
80105284:	ff 75 dc             	pushl  -0x24(%ebp)
80105287:	56                   	push   %esi
80105288:	ff 75 d8             	pushl  -0x28(%ebp)
8010528b:	ff 70 10             	pushl  0x10(%eax)
8010528e:	68 60 6f 10 80       	push   $0x80106f60
80105293:	e8 73 b3 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
80105298:	83 c4 20             	add    $0x20,%esp
8010529b:	e8 06 e2 ff ff       	call   801034a6 <myproc>
801052a0:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801052a7:	e9 a4 fe ff ff       	jmp    80105150 <trap+0x66>
801052ac:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801052af:	8b 73 38             	mov    0x38(%ebx),%esi
801052b2:	e8 d4 e1 ff ff       	call   8010348b <cpuid>
801052b7:	83 ec 0c             	sub    $0xc,%esp
801052ba:	57                   	push   %edi
801052bb:	56                   	push   %esi
801052bc:	50                   	push   %eax
801052bd:	ff 73 30             	pushl  0x30(%ebx)
801052c0:	68 2c 6f 10 80       	push   $0x80106f2c
801052c5:	e8 41 b3 ff ff       	call   8010060b <cprintf>
      panic("trap");
801052ca:	83 c4 14             	add    $0x14,%esp
801052cd:	68 02 6f 10 80       	push   $0x80106f02
801052d2:	e8 71 b0 ff ff       	call   80100348 <panic>
    exit();
801052d7:	e8 79 e5 ff ff       	call   80103855 <exit>
801052dc:	e9 94 fe ff ff       	jmp    80105175 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
801052e1:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
801052e5:	0f 85 a2 fe ff ff    	jne    8010518d <trap+0xa3>
    yield();
801052eb:	e8 2b e6 ff ff       	call   8010391b <yield>
801052f0:	e9 98 fe ff ff       	jmp    8010518d <trap+0xa3>
    exit();
801052f5:	e8 5b e5 ff ff       	call   80103855 <exit>
801052fa:	e9 b3 fe ff ff       	jmp    801051b2 <trap+0xc8>

801052ff <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
801052ff:	55                   	push   %ebp
80105300:	89 e5                	mov    %esp,%ebp
  if(!uart)
80105302:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
80105309:	74 15                	je     80105320 <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010530b:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105310:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
80105311:	a8 01                	test   $0x1,%al
80105313:	74 12                	je     80105327 <uartgetc+0x28>
80105315:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010531a:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
8010531b:	0f b6 c0             	movzbl %al,%eax
}
8010531e:	5d                   	pop    %ebp
8010531f:	c3                   	ret    
    return -1;
80105320:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105325:	eb f7                	jmp    8010531e <uartgetc+0x1f>
    return -1;
80105327:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010532c:	eb f0                	jmp    8010531e <uartgetc+0x1f>

8010532e <uartputc>:
  if(!uart)
8010532e:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
80105335:	74 3b                	je     80105372 <uartputc+0x44>
{
80105337:	55                   	push   %ebp
80105338:	89 e5                	mov    %esp,%ebp
8010533a:	53                   	push   %ebx
8010533b:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010533e:	bb 00 00 00 00       	mov    $0x0,%ebx
80105343:	eb 10                	jmp    80105355 <uartputc+0x27>
    microdelay(10);
80105345:	83 ec 0c             	sub    $0xc,%esp
80105348:	6a 0a                	push   $0xa
8010534a:	e8 06 d3 ff ff       	call   80102655 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010534f:	83 c3 01             	add    $0x1,%ebx
80105352:	83 c4 10             	add    $0x10,%esp
80105355:	83 fb 7f             	cmp    $0x7f,%ebx
80105358:	7f 0a                	jg     80105364 <uartputc+0x36>
8010535a:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010535f:	ec                   	in     (%dx),%al
80105360:	a8 20                	test   $0x20,%al
80105362:	74 e1                	je     80105345 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80105364:	8b 45 08             	mov    0x8(%ebp),%eax
80105367:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010536c:	ee                   	out    %al,(%dx)
}
8010536d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105370:	c9                   	leave  
80105371:	c3                   	ret    
80105372:	f3 c3                	repz ret 

80105374 <uartinit>:
{
80105374:	55                   	push   %ebp
80105375:	89 e5                	mov    %esp,%ebp
80105377:	56                   	push   %esi
80105378:	53                   	push   %ebx
80105379:	b9 00 00 00 00       	mov    $0x0,%ecx
8010537e:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105383:	89 c8                	mov    %ecx,%eax
80105385:	ee                   	out    %al,(%dx)
80105386:	be fb 03 00 00       	mov    $0x3fb,%esi
8010538b:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
80105390:	89 f2                	mov    %esi,%edx
80105392:	ee                   	out    %al,(%dx)
80105393:	b8 0c 00 00 00       	mov    $0xc,%eax
80105398:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010539d:	ee                   	out    %al,(%dx)
8010539e:	bb f9 03 00 00       	mov    $0x3f9,%ebx
801053a3:	89 c8                	mov    %ecx,%eax
801053a5:	89 da                	mov    %ebx,%edx
801053a7:	ee                   	out    %al,(%dx)
801053a8:	b8 03 00 00 00       	mov    $0x3,%eax
801053ad:	89 f2                	mov    %esi,%edx
801053af:	ee                   	out    %al,(%dx)
801053b0:	ba fc 03 00 00       	mov    $0x3fc,%edx
801053b5:	89 c8                	mov    %ecx,%eax
801053b7:	ee                   	out    %al,(%dx)
801053b8:	b8 01 00 00 00       	mov    $0x1,%eax
801053bd:	89 da                	mov    %ebx,%edx
801053bf:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801053c0:	ba fd 03 00 00       	mov    $0x3fd,%edx
801053c5:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
801053c6:	3c ff                	cmp    $0xff,%al
801053c8:	74 45                	je     8010540f <uartinit+0x9b>
  uart = 1;
801053ca:	c7 05 bc a5 10 80 01 	movl   $0x1,0x8010a5bc
801053d1:	00 00 00 
801053d4:	ba fa 03 00 00       	mov    $0x3fa,%edx
801053d9:	ec                   	in     (%dx),%al
801053da:	ba f8 03 00 00       	mov    $0x3f8,%edx
801053df:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
801053e0:	83 ec 08             	sub    $0x8,%esp
801053e3:	6a 00                	push   $0x0
801053e5:	6a 04                	push   $0x4
801053e7:	e8 9e cb ff ff       	call   80101f8a <ioapicenable>
  for(p="xv6...\n"; *p; p++)
801053ec:	83 c4 10             	add    $0x10,%esp
801053ef:	bb 24 70 10 80       	mov    $0x80107024,%ebx
801053f4:	eb 12                	jmp    80105408 <uartinit+0x94>
    uartputc(*p);
801053f6:	83 ec 0c             	sub    $0xc,%esp
801053f9:	0f be c0             	movsbl %al,%eax
801053fc:	50                   	push   %eax
801053fd:	e8 2c ff ff ff       	call   8010532e <uartputc>
  for(p="xv6...\n"; *p; p++)
80105402:	83 c3 01             	add    $0x1,%ebx
80105405:	83 c4 10             	add    $0x10,%esp
80105408:	0f b6 03             	movzbl (%ebx),%eax
8010540b:	84 c0                	test   %al,%al
8010540d:	75 e7                	jne    801053f6 <uartinit+0x82>
}
8010540f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80105412:	5b                   	pop    %ebx
80105413:	5e                   	pop    %esi
80105414:	5d                   	pop    %ebp
80105415:	c3                   	ret    

80105416 <uartintr>:

void
uartintr(void)
{
80105416:	55                   	push   %ebp
80105417:	89 e5                	mov    %esp,%ebp
80105419:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
8010541c:	68 ff 52 10 80       	push   $0x801052ff
80105421:	e8 18 b3 ff ff       	call   8010073e <consoleintr>
}
80105426:	83 c4 10             	add    $0x10,%esp
80105429:	c9                   	leave  
8010542a:	c3                   	ret    

8010542b <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
8010542b:	6a 00                	push   $0x0
  pushl $0
8010542d:	6a 00                	push   $0x0
  jmp alltraps
8010542f:	e9 be fb ff ff       	jmp    80104ff2 <alltraps>

80105434 <vector1>:
.globl vector1
vector1:
  pushl $0
80105434:	6a 00                	push   $0x0
  pushl $1
80105436:	6a 01                	push   $0x1
  jmp alltraps
80105438:	e9 b5 fb ff ff       	jmp    80104ff2 <alltraps>

8010543d <vector2>:
.globl vector2
vector2:
  pushl $0
8010543d:	6a 00                	push   $0x0
  pushl $2
8010543f:	6a 02                	push   $0x2
  jmp alltraps
80105441:	e9 ac fb ff ff       	jmp    80104ff2 <alltraps>

80105446 <vector3>:
.globl vector3
vector3:
  pushl $0
80105446:	6a 00                	push   $0x0
  pushl $3
80105448:	6a 03                	push   $0x3
  jmp alltraps
8010544a:	e9 a3 fb ff ff       	jmp    80104ff2 <alltraps>

8010544f <vector4>:
.globl vector4
vector4:
  pushl $0
8010544f:	6a 00                	push   $0x0
  pushl $4
80105451:	6a 04                	push   $0x4
  jmp alltraps
80105453:	e9 9a fb ff ff       	jmp    80104ff2 <alltraps>

80105458 <vector5>:
.globl vector5
vector5:
  pushl $0
80105458:	6a 00                	push   $0x0
  pushl $5
8010545a:	6a 05                	push   $0x5
  jmp alltraps
8010545c:	e9 91 fb ff ff       	jmp    80104ff2 <alltraps>

80105461 <vector6>:
.globl vector6
vector6:
  pushl $0
80105461:	6a 00                	push   $0x0
  pushl $6
80105463:	6a 06                	push   $0x6
  jmp alltraps
80105465:	e9 88 fb ff ff       	jmp    80104ff2 <alltraps>

8010546a <vector7>:
.globl vector7
vector7:
  pushl $0
8010546a:	6a 00                	push   $0x0
  pushl $7
8010546c:	6a 07                	push   $0x7
  jmp alltraps
8010546e:	e9 7f fb ff ff       	jmp    80104ff2 <alltraps>

80105473 <vector8>:
.globl vector8
vector8:
  pushl $8
80105473:	6a 08                	push   $0x8
  jmp alltraps
80105475:	e9 78 fb ff ff       	jmp    80104ff2 <alltraps>

8010547a <vector9>:
.globl vector9
vector9:
  pushl $0
8010547a:	6a 00                	push   $0x0
  pushl $9
8010547c:	6a 09                	push   $0x9
  jmp alltraps
8010547e:	e9 6f fb ff ff       	jmp    80104ff2 <alltraps>

80105483 <vector10>:
.globl vector10
vector10:
  pushl $10
80105483:	6a 0a                	push   $0xa
  jmp alltraps
80105485:	e9 68 fb ff ff       	jmp    80104ff2 <alltraps>

8010548a <vector11>:
.globl vector11
vector11:
  pushl $11
8010548a:	6a 0b                	push   $0xb
  jmp alltraps
8010548c:	e9 61 fb ff ff       	jmp    80104ff2 <alltraps>

80105491 <vector12>:
.globl vector12
vector12:
  pushl $12
80105491:	6a 0c                	push   $0xc
  jmp alltraps
80105493:	e9 5a fb ff ff       	jmp    80104ff2 <alltraps>

80105498 <vector13>:
.globl vector13
vector13:
  pushl $13
80105498:	6a 0d                	push   $0xd
  jmp alltraps
8010549a:	e9 53 fb ff ff       	jmp    80104ff2 <alltraps>

8010549f <vector14>:
.globl vector14
vector14:
  pushl $14
8010549f:	6a 0e                	push   $0xe
  jmp alltraps
801054a1:	e9 4c fb ff ff       	jmp    80104ff2 <alltraps>

801054a6 <vector15>:
.globl vector15
vector15:
  pushl $0
801054a6:	6a 00                	push   $0x0
  pushl $15
801054a8:	6a 0f                	push   $0xf
  jmp alltraps
801054aa:	e9 43 fb ff ff       	jmp    80104ff2 <alltraps>

801054af <vector16>:
.globl vector16
vector16:
  pushl $0
801054af:	6a 00                	push   $0x0
  pushl $16
801054b1:	6a 10                	push   $0x10
  jmp alltraps
801054b3:	e9 3a fb ff ff       	jmp    80104ff2 <alltraps>

801054b8 <vector17>:
.globl vector17
vector17:
  pushl $17
801054b8:	6a 11                	push   $0x11
  jmp alltraps
801054ba:	e9 33 fb ff ff       	jmp    80104ff2 <alltraps>

801054bf <vector18>:
.globl vector18
vector18:
  pushl $0
801054bf:	6a 00                	push   $0x0
  pushl $18
801054c1:	6a 12                	push   $0x12
  jmp alltraps
801054c3:	e9 2a fb ff ff       	jmp    80104ff2 <alltraps>

801054c8 <vector19>:
.globl vector19
vector19:
  pushl $0
801054c8:	6a 00                	push   $0x0
  pushl $19
801054ca:	6a 13                	push   $0x13
  jmp alltraps
801054cc:	e9 21 fb ff ff       	jmp    80104ff2 <alltraps>

801054d1 <vector20>:
.globl vector20
vector20:
  pushl $0
801054d1:	6a 00                	push   $0x0
  pushl $20
801054d3:	6a 14                	push   $0x14
  jmp alltraps
801054d5:	e9 18 fb ff ff       	jmp    80104ff2 <alltraps>

801054da <vector21>:
.globl vector21
vector21:
  pushl $0
801054da:	6a 00                	push   $0x0
  pushl $21
801054dc:	6a 15                	push   $0x15
  jmp alltraps
801054de:	e9 0f fb ff ff       	jmp    80104ff2 <alltraps>

801054e3 <vector22>:
.globl vector22
vector22:
  pushl $0
801054e3:	6a 00                	push   $0x0
  pushl $22
801054e5:	6a 16                	push   $0x16
  jmp alltraps
801054e7:	e9 06 fb ff ff       	jmp    80104ff2 <alltraps>

801054ec <vector23>:
.globl vector23
vector23:
  pushl $0
801054ec:	6a 00                	push   $0x0
  pushl $23
801054ee:	6a 17                	push   $0x17
  jmp alltraps
801054f0:	e9 fd fa ff ff       	jmp    80104ff2 <alltraps>

801054f5 <vector24>:
.globl vector24
vector24:
  pushl $0
801054f5:	6a 00                	push   $0x0
  pushl $24
801054f7:	6a 18                	push   $0x18
  jmp alltraps
801054f9:	e9 f4 fa ff ff       	jmp    80104ff2 <alltraps>

801054fe <vector25>:
.globl vector25
vector25:
  pushl $0
801054fe:	6a 00                	push   $0x0
  pushl $25
80105500:	6a 19                	push   $0x19
  jmp alltraps
80105502:	e9 eb fa ff ff       	jmp    80104ff2 <alltraps>

80105507 <vector26>:
.globl vector26
vector26:
  pushl $0
80105507:	6a 00                	push   $0x0
  pushl $26
80105509:	6a 1a                	push   $0x1a
  jmp alltraps
8010550b:	e9 e2 fa ff ff       	jmp    80104ff2 <alltraps>

80105510 <vector27>:
.globl vector27
vector27:
  pushl $0
80105510:	6a 00                	push   $0x0
  pushl $27
80105512:	6a 1b                	push   $0x1b
  jmp alltraps
80105514:	e9 d9 fa ff ff       	jmp    80104ff2 <alltraps>

80105519 <vector28>:
.globl vector28
vector28:
  pushl $0
80105519:	6a 00                	push   $0x0
  pushl $28
8010551b:	6a 1c                	push   $0x1c
  jmp alltraps
8010551d:	e9 d0 fa ff ff       	jmp    80104ff2 <alltraps>

80105522 <vector29>:
.globl vector29
vector29:
  pushl $0
80105522:	6a 00                	push   $0x0
  pushl $29
80105524:	6a 1d                	push   $0x1d
  jmp alltraps
80105526:	e9 c7 fa ff ff       	jmp    80104ff2 <alltraps>

8010552b <vector30>:
.globl vector30
vector30:
  pushl $0
8010552b:	6a 00                	push   $0x0
  pushl $30
8010552d:	6a 1e                	push   $0x1e
  jmp alltraps
8010552f:	e9 be fa ff ff       	jmp    80104ff2 <alltraps>

80105534 <vector31>:
.globl vector31
vector31:
  pushl $0
80105534:	6a 00                	push   $0x0
  pushl $31
80105536:	6a 1f                	push   $0x1f
  jmp alltraps
80105538:	e9 b5 fa ff ff       	jmp    80104ff2 <alltraps>

8010553d <vector32>:
.globl vector32
vector32:
  pushl $0
8010553d:	6a 00                	push   $0x0
  pushl $32
8010553f:	6a 20                	push   $0x20
  jmp alltraps
80105541:	e9 ac fa ff ff       	jmp    80104ff2 <alltraps>

80105546 <vector33>:
.globl vector33
vector33:
  pushl $0
80105546:	6a 00                	push   $0x0
  pushl $33
80105548:	6a 21                	push   $0x21
  jmp alltraps
8010554a:	e9 a3 fa ff ff       	jmp    80104ff2 <alltraps>

8010554f <vector34>:
.globl vector34
vector34:
  pushl $0
8010554f:	6a 00                	push   $0x0
  pushl $34
80105551:	6a 22                	push   $0x22
  jmp alltraps
80105553:	e9 9a fa ff ff       	jmp    80104ff2 <alltraps>

80105558 <vector35>:
.globl vector35
vector35:
  pushl $0
80105558:	6a 00                	push   $0x0
  pushl $35
8010555a:	6a 23                	push   $0x23
  jmp alltraps
8010555c:	e9 91 fa ff ff       	jmp    80104ff2 <alltraps>

80105561 <vector36>:
.globl vector36
vector36:
  pushl $0
80105561:	6a 00                	push   $0x0
  pushl $36
80105563:	6a 24                	push   $0x24
  jmp alltraps
80105565:	e9 88 fa ff ff       	jmp    80104ff2 <alltraps>

8010556a <vector37>:
.globl vector37
vector37:
  pushl $0
8010556a:	6a 00                	push   $0x0
  pushl $37
8010556c:	6a 25                	push   $0x25
  jmp alltraps
8010556e:	e9 7f fa ff ff       	jmp    80104ff2 <alltraps>

80105573 <vector38>:
.globl vector38
vector38:
  pushl $0
80105573:	6a 00                	push   $0x0
  pushl $38
80105575:	6a 26                	push   $0x26
  jmp alltraps
80105577:	e9 76 fa ff ff       	jmp    80104ff2 <alltraps>

8010557c <vector39>:
.globl vector39
vector39:
  pushl $0
8010557c:	6a 00                	push   $0x0
  pushl $39
8010557e:	6a 27                	push   $0x27
  jmp alltraps
80105580:	e9 6d fa ff ff       	jmp    80104ff2 <alltraps>

80105585 <vector40>:
.globl vector40
vector40:
  pushl $0
80105585:	6a 00                	push   $0x0
  pushl $40
80105587:	6a 28                	push   $0x28
  jmp alltraps
80105589:	e9 64 fa ff ff       	jmp    80104ff2 <alltraps>

8010558e <vector41>:
.globl vector41
vector41:
  pushl $0
8010558e:	6a 00                	push   $0x0
  pushl $41
80105590:	6a 29                	push   $0x29
  jmp alltraps
80105592:	e9 5b fa ff ff       	jmp    80104ff2 <alltraps>

80105597 <vector42>:
.globl vector42
vector42:
  pushl $0
80105597:	6a 00                	push   $0x0
  pushl $42
80105599:	6a 2a                	push   $0x2a
  jmp alltraps
8010559b:	e9 52 fa ff ff       	jmp    80104ff2 <alltraps>

801055a0 <vector43>:
.globl vector43
vector43:
  pushl $0
801055a0:	6a 00                	push   $0x0
  pushl $43
801055a2:	6a 2b                	push   $0x2b
  jmp alltraps
801055a4:	e9 49 fa ff ff       	jmp    80104ff2 <alltraps>

801055a9 <vector44>:
.globl vector44
vector44:
  pushl $0
801055a9:	6a 00                	push   $0x0
  pushl $44
801055ab:	6a 2c                	push   $0x2c
  jmp alltraps
801055ad:	e9 40 fa ff ff       	jmp    80104ff2 <alltraps>

801055b2 <vector45>:
.globl vector45
vector45:
  pushl $0
801055b2:	6a 00                	push   $0x0
  pushl $45
801055b4:	6a 2d                	push   $0x2d
  jmp alltraps
801055b6:	e9 37 fa ff ff       	jmp    80104ff2 <alltraps>

801055bb <vector46>:
.globl vector46
vector46:
  pushl $0
801055bb:	6a 00                	push   $0x0
  pushl $46
801055bd:	6a 2e                	push   $0x2e
  jmp alltraps
801055bf:	e9 2e fa ff ff       	jmp    80104ff2 <alltraps>

801055c4 <vector47>:
.globl vector47
vector47:
  pushl $0
801055c4:	6a 00                	push   $0x0
  pushl $47
801055c6:	6a 2f                	push   $0x2f
  jmp alltraps
801055c8:	e9 25 fa ff ff       	jmp    80104ff2 <alltraps>

801055cd <vector48>:
.globl vector48
vector48:
  pushl $0
801055cd:	6a 00                	push   $0x0
  pushl $48
801055cf:	6a 30                	push   $0x30
  jmp alltraps
801055d1:	e9 1c fa ff ff       	jmp    80104ff2 <alltraps>

801055d6 <vector49>:
.globl vector49
vector49:
  pushl $0
801055d6:	6a 00                	push   $0x0
  pushl $49
801055d8:	6a 31                	push   $0x31
  jmp alltraps
801055da:	e9 13 fa ff ff       	jmp    80104ff2 <alltraps>

801055df <vector50>:
.globl vector50
vector50:
  pushl $0
801055df:	6a 00                	push   $0x0
  pushl $50
801055e1:	6a 32                	push   $0x32
  jmp alltraps
801055e3:	e9 0a fa ff ff       	jmp    80104ff2 <alltraps>

801055e8 <vector51>:
.globl vector51
vector51:
  pushl $0
801055e8:	6a 00                	push   $0x0
  pushl $51
801055ea:	6a 33                	push   $0x33
  jmp alltraps
801055ec:	e9 01 fa ff ff       	jmp    80104ff2 <alltraps>

801055f1 <vector52>:
.globl vector52
vector52:
  pushl $0
801055f1:	6a 00                	push   $0x0
  pushl $52
801055f3:	6a 34                	push   $0x34
  jmp alltraps
801055f5:	e9 f8 f9 ff ff       	jmp    80104ff2 <alltraps>

801055fa <vector53>:
.globl vector53
vector53:
  pushl $0
801055fa:	6a 00                	push   $0x0
  pushl $53
801055fc:	6a 35                	push   $0x35
  jmp alltraps
801055fe:	e9 ef f9 ff ff       	jmp    80104ff2 <alltraps>

80105603 <vector54>:
.globl vector54
vector54:
  pushl $0
80105603:	6a 00                	push   $0x0
  pushl $54
80105605:	6a 36                	push   $0x36
  jmp alltraps
80105607:	e9 e6 f9 ff ff       	jmp    80104ff2 <alltraps>

8010560c <vector55>:
.globl vector55
vector55:
  pushl $0
8010560c:	6a 00                	push   $0x0
  pushl $55
8010560e:	6a 37                	push   $0x37
  jmp alltraps
80105610:	e9 dd f9 ff ff       	jmp    80104ff2 <alltraps>

80105615 <vector56>:
.globl vector56
vector56:
  pushl $0
80105615:	6a 00                	push   $0x0
  pushl $56
80105617:	6a 38                	push   $0x38
  jmp alltraps
80105619:	e9 d4 f9 ff ff       	jmp    80104ff2 <alltraps>

8010561e <vector57>:
.globl vector57
vector57:
  pushl $0
8010561e:	6a 00                	push   $0x0
  pushl $57
80105620:	6a 39                	push   $0x39
  jmp alltraps
80105622:	e9 cb f9 ff ff       	jmp    80104ff2 <alltraps>

80105627 <vector58>:
.globl vector58
vector58:
  pushl $0
80105627:	6a 00                	push   $0x0
  pushl $58
80105629:	6a 3a                	push   $0x3a
  jmp alltraps
8010562b:	e9 c2 f9 ff ff       	jmp    80104ff2 <alltraps>

80105630 <vector59>:
.globl vector59
vector59:
  pushl $0
80105630:	6a 00                	push   $0x0
  pushl $59
80105632:	6a 3b                	push   $0x3b
  jmp alltraps
80105634:	e9 b9 f9 ff ff       	jmp    80104ff2 <alltraps>

80105639 <vector60>:
.globl vector60
vector60:
  pushl $0
80105639:	6a 00                	push   $0x0
  pushl $60
8010563b:	6a 3c                	push   $0x3c
  jmp alltraps
8010563d:	e9 b0 f9 ff ff       	jmp    80104ff2 <alltraps>

80105642 <vector61>:
.globl vector61
vector61:
  pushl $0
80105642:	6a 00                	push   $0x0
  pushl $61
80105644:	6a 3d                	push   $0x3d
  jmp alltraps
80105646:	e9 a7 f9 ff ff       	jmp    80104ff2 <alltraps>

8010564b <vector62>:
.globl vector62
vector62:
  pushl $0
8010564b:	6a 00                	push   $0x0
  pushl $62
8010564d:	6a 3e                	push   $0x3e
  jmp alltraps
8010564f:	e9 9e f9 ff ff       	jmp    80104ff2 <alltraps>

80105654 <vector63>:
.globl vector63
vector63:
  pushl $0
80105654:	6a 00                	push   $0x0
  pushl $63
80105656:	6a 3f                	push   $0x3f
  jmp alltraps
80105658:	e9 95 f9 ff ff       	jmp    80104ff2 <alltraps>

8010565d <vector64>:
.globl vector64
vector64:
  pushl $0
8010565d:	6a 00                	push   $0x0
  pushl $64
8010565f:	6a 40                	push   $0x40
  jmp alltraps
80105661:	e9 8c f9 ff ff       	jmp    80104ff2 <alltraps>

80105666 <vector65>:
.globl vector65
vector65:
  pushl $0
80105666:	6a 00                	push   $0x0
  pushl $65
80105668:	6a 41                	push   $0x41
  jmp alltraps
8010566a:	e9 83 f9 ff ff       	jmp    80104ff2 <alltraps>

8010566f <vector66>:
.globl vector66
vector66:
  pushl $0
8010566f:	6a 00                	push   $0x0
  pushl $66
80105671:	6a 42                	push   $0x42
  jmp alltraps
80105673:	e9 7a f9 ff ff       	jmp    80104ff2 <alltraps>

80105678 <vector67>:
.globl vector67
vector67:
  pushl $0
80105678:	6a 00                	push   $0x0
  pushl $67
8010567a:	6a 43                	push   $0x43
  jmp alltraps
8010567c:	e9 71 f9 ff ff       	jmp    80104ff2 <alltraps>

80105681 <vector68>:
.globl vector68
vector68:
  pushl $0
80105681:	6a 00                	push   $0x0
  pushl $68
80105683:	6a 44                	push   $0x44
  jmp alltraps
80105685:	e9 68 f9 ff ff       	jmp    80104ff2 <alltraps>

8010568a <vector69>:
.globl vector69
vector69:
  pushl $0
8010568a:	6a 00                	push   $0x0
  pushl $69
8010568c:	6a 45                	push   $0x45
  jmp alltraps
8010568e:	e9 5f f9 ff ff       	jmp    80104ff2 <alltraps>

80105693 <vector70>:
.globl vector70
vector70:
  pushl $0
80105693:	6a 00                	push   $0x0
  pushl $70
80105695:	6a 46                	push   $0x46
  jmp alltraps
80105697:	e9 56 f9 ff ff       	jmp    80104ff2 <alltraps>

8010569c <vector71>:
.globl vector71
vector71:
  pushl $0
8010569c:	6a 00                	push   $0x0
  pushl $71
8010569e:	6a 47                	push   $0x47
  jmp alltraps
801056a0:	e9 4d f9 ff ff       	jmp    80104ff2 <alltraps>

801056a5 <vector72>:
.globl vector72
vector72:
  pushl $0
801056a5:	6a 00                	push   $0x0
  pushl $72
801056a7:	6a 48                	push   $0x48
  jmp alltraps
801056a9:	e9 44 f9 ff ff       	jmp    80104ff2 <alltraps>

801056ae <vector73>:
.globl vector73
vector73:
  pushl $0
801056ae:	6a 00                	push   $0x0
  pushl $73
801056b0:	6a 49                	push   $0x49
  jmp alltraps
801056b2:	e9 3b f9 ff ff       	jmp    80104ff2 <alltraps>

801056b7 <vector74>:
.globl vector74
vector74:
  pushl $0
801056b7:	6a 00                	push   $0x0
  pushl $74
801056b9:	6a 4a                	push   $0x4a
  jmp alltraps
801056bb:	e9 32 f9 ff ff       	jmp    80104ff2 <alltraps>

801056c0 <vector75>:
.globl vector75
vector75:
  pushl $0
801056c0:	6a 00                	push   $0x0
  pushl $75
801056c2:	6a 4b                	push   $0x4b
  jmp alltraps
801056c4:	e9 29 f9 ff ff       	jmp    80104ff2 <alltraps>

801056c9 <vector76>:
.globl vector76
vector76:
  pushl $0
801056c9:	6a 00                	push   $0x0
  pushl $76
801056cb:	6a 4c                	push   $0x4c
  jmp alltraps
801056cd:	e9 20 f9 ff ff       	jmp    80104ff2 <alltraps>

801056d2 <vector77>:
.globl vector77
vector77:
  pushl $0
801056d2:	6a 00                	push   $0x0
  pushl $77
801056d4:	6a 4d                	push   $0x4d
  jmp alltraps
801056d6:	e9 17 f9 ff ff       	jmp    80104ff2 <alltraps>

801056db <vector78>:
.globl vector78
vector78:
  pushl $0
801056db:	6a 00                	push   $0x0
  pushl $78
801056dd:	6a 4e                	push   $0x4e
  jmp alltraps
801056df:	e9 0e f9 ff ff       	jmp    80104ff2 <alltraps>

801056e4 <vector79>:
.globl vector79
vector79:
  pushl $0
801056e4:	6a 00                	push   $0x0
  pushl $79
801056e6:	6a 4f                	push   $0x4f
  jmp alltraps
801056e8:	e9 05 f9 ff ff       	jmp    80104ff2 <alltraps>

801056ed <vector80>:
.globl vector80
vector80:
  pushl $0
801056ed:	6a 00                	push   $0x0
  pushl $80
801056ef:	6a 50                	push   $0x50
  jmp alltraps
801056f1:	e9 fc f8 ff ff       	jmp    80104ff2 <alltraps>

801056f6 <vector81>:
.globl vector81
vector81:
  pushl $0
801056f6:	6a 00                	push   $0x0
  pushl $81
801056f8:	6a 51                	push   $0x51
  jmp alltraps
801056fa:	e9 f3 f8 ff ff       	jmp    80104ff2 <alltraps>

801056ff <vector82>:
.globl vector82
vector82:
  pushl $0
801056ff:	6a 00                	push   $0x0
  pushl $82
80105701:	6a 52                	push   $0x52
  jmp alltraps
80105703:	e9 ea f8 ff ff       	jmp    80104ff2 <alltraps>

80105708 <vector83>:
.globl vector83
vector83:
  pushl $0
80105708:	6a 00                	push   $0x0
  pushl $83
8010570a:	6a 53                	push   $0x53
  jmp alltraps
8010570c:	e9 e1 f8 ff ff       	jmp    80104ff2 <alltraps>

80105711 <vector84>:
.globl vector84
vector84:
  pushl $0
80105711:	6a 00                	push   $0x0
  pushl $84
80105713:	6a 54                	push   $0x54
  jmp alltraps
80105715:	e9 d8 f8 ff ff       	jmp    80104ff2 <alltraps>

8010571a <vector85>:
.globl vector85
vector85:
  pushl $0
8010571a:	6a 00                	push   $0x0
  pushl $85
8010571c:	6a 55                	push   $0x55
  jmp alltraps
8010571e:	e9 cf f8 ff ff       	jmp    80104ff2 <alltraps>

80105723 <vector86>:
.globl vector86
vector86:
  pushl $0
80105723:	6a 00                	push   $0x0
  pushl $86
80105725:	6a 56                	push   $0x56
  jmp alltraps
80105727:	e9 c6 f8 ff ff       	jmp    80104ff2 <alltraps>

8010572c <vector87>:
.globl vector87
vector87:
  pushl $0
8010572c:	6a 00                	push   $0x0
  pushl $87
8010572e:	6a 57                	push   $0x57
  jmp alltraps
80105730:	e9 bd f8 ff ff       	jmp    80104ff2 <alltraps>

80105735 <vector88>:
.globl vector88
vector88:
  pushl $0
80105735:	6a 00                	push   $0x0
  pushl $88
80105737:	6a 58                	push   $0x58
  jmp alltraps
80105739:	e9 b4 f8 ff ff       	jmp    80104ff2 <alltraps>

8010573e <vector89>:
.globl vector89
vector89:
  pushl $0
8010573e:	6a 00                	push   $0x0
  pushl $89
80105740:	6a 59                	push   $0x59
  jmp alltraps
80105742:	e9 ab f8 ff ff       	jmp    80104ff2 <alltraps>

80105747 <vector90>:
.globl vector90
vector90:
  pushl $0
80105747:	6a 00                	push   $0x0
  pushl $90
80105749:	6a 5a                	push   $0x5a
  jmp alltraps
8010574b:	e9 a2 f8 ff ff       	jmp    80104ff2 <alltraps>

80105750 <vector91>:
.globl vector91
vector91:
  pushl $0
80105750:	6a 00                	push   $0x0
  pushl $91
80105752:	6a 5b                	push   $0x5b
  jmp alltraps
80105754:	e9 99 f8 ff ff       	jmp    80104ff2 <alltraps>

80105759 <vector92>:
.globl vector92
vector92:
  pushl $0
80105759:	6a 00                	push   $0x0
  pushl $92
8010575b:	6a 5c                	push   $0x5c
  jmp alltraps
8010575d:	e9 90 f8 ff ff       	jmp    80104ff2 <alltraps>

80105762 <vector93>:
.globl vector93
vector93:
  pushl $0
80105762:	6a 00                	push   $0x0
  pushl $93
80105764:	6a 5d                	push   $0x5d
  jmp alltraps
80105766:	e9 87 f8 ff ff       	jmp    80104ff2 <alltraps>

8010576b <vector94>:
.globl vector94
vector94:
  pushl $0
8010576b:	6a 00                	push   $0x0
  pushl $94
8010576d:	6a 5e                	push   $0x5e
  jmp alltraps
8010576f:	e9 7e f8 ff ff       	jmp    80104ff2 <alltraps>

80105774 <vector95>:
.globl vector95
vector95:
  pushl $0
80105774:	6a 00                	push   $0x0
  pushl $95
80105776:	6a 5f                	push   $0x5f
  jmp alltraps
80105778:	e9 75 f8 ff ff       	jmp    80104ff2 <alltraps>

8010577d <vector96>:
.globl vector96
vector96:
  pushl $0
8010577d:	6a 00                	push   $0x0
  pushl $96
8010577f:	6a 60                	push   $0x60
  jmp alltraps
80105781:	e9 6c f8 ff ff       	jmp    80104ff2 <alltraps>

80105786 <vector97>:
.globl vector97
vector97:
  pushl $0
80105786:	6a 00                	push   $0x0
  pushl $97
80105788:	6a 61                	push   $0x61
  jmp alltraps
8010578a:	e9 63 f8 ff ff       	jmp    80104ff2 <alltraps>

8010578f <vector98>:
.globl vector98
vector98:
  pushl $0
8010578f:	6a 00                	push   $0x0
  pushl $98
80105791:	6a 62                	push   $0x62
  jmp alltraps
80105793:	e9 5a f8 ff ff       	jmp    80104ff2 <alltraps>

80105798 <vector99>:
.globl vector99
vector99:
  pushl $0
80105798:	6a 00                	push   $0x0
  pushl $99
8010579a:	6a 63                	push   $0x63
  jmp alltraps
8010579c:	e9 51 f8 ff ff       	jmp    80104ff2 <alltraps>

801057a1 <vector100>:
.globl vector100
vector100:
  pushl $0
801057a1:	6a 00                	push   $0x0
  pushl $100
801057a3:	6a 64                	push   $0x64
  jmp alltraps
801057a5:	e9 48 f8 ff ff       	jmp    80104ff2 <alltraps>

801057aa <vector101>:
.globl vector101
vector101:
  pushl $0
801057aa:	6a 00                	push   $0x0
  pushl $101
801057ac:	6a 65                	push   $0x65
  jmp alltraps
801057ae:	e9 3f f8 ff ff       	jmp    80104ff2 <alltraps>

801057b3 <vector102>:
.globl vector102
vector102:
  pushl $0
801057b3:	6a 00                	push   $0x0
  pushl $102
801057b5:	6a 66                	push   $0x66
  jmp alltraps
801057b7:	e9 36 f8 ff ff       	jmp    80104ff2 <alltraps>

801057bc <vector103>:
.globl vector103
vector103:
  pushl $0
801057bc:	6a 00                	push   $0x0
  pushl $103
801057be:	6a 67                	push   $0x67
  jmp alltraps
801057c0:	e9 2d f8 ff ff       	jmp    80104ff2 <alltraps>

801057c5 <vector104>:
.globl vector104
vector104:
  pushl $0
801057c5:	6a 00                	push   $0x0
  pushl $104
801057c7:	6a 68                	push   $0x68
  jmp alltraps
801057c9:	e9 24 f8 ff ff       	jmp    80104ff2 <alltraps>

801057ce <vector105>:
.globl vector105
vector105:
  pushl $0
801057ce:	6a 00                	push   $0x0
  pushl $105
801057d0:	6a 69                	push   $0x69
  jmp alltraps
801057d2:	e9 1b f8 ff ff       	jmp    80104ff2 <alltraps>

801057d7 <vector106>:
.globl vector106
vector106:
  pushl $0
801057d7:	6a 00                	push   $0x0
  pushl $106
801057d9:	6a 6a                	push   $0x6a
  jmp alltraps
801057db:	e9 12 f8 ff ff       	jmp    80104ff2 <alltraps>

801057e0 <vector107>:
.globl vector107
vector107:
  pushl $0
801057e0:	6a 00                	push   $0x0
  pushl $107
801057e2:	6a 6b                	push   $0x6b
  jmp alltraps
801057e4:	e9 09 f8 ff ff       	jmp    80104ff2 <alltraps>

801057e9 <vector108>:
.globl vector108
vector108:
  pushl $0
801057e9:	6a 00                	push   $0x0
  pushl $108
801057eb:	6a 6c                	push   $0x6c
  jmp alltraps
801057ed:	e9 00 f8 ff ff       	jmp    80104ff2 <alltraps>

801057f2 <vector109>:
.globl vector109
vector109:
  pushl $0
801057f2:	6a 00                	push   $0x0
  pushl $109
801057f4:	6a 6d                	push   $0x6d
  jmp alltraps
801057f6:	e9 f7 f7 ff ff       	jmp    80104ff2 <alltraps>

801057fb <vector110>:
.globl vector110
vector110:
  pushl $0
801057fb:	6a 00                	push   $0x0
  pushl $110
801057fd:	6a 6e                	push   $0x6e
  jmp alltraps
801057ff:	e9 ee f7 ff ff       	jmp    80104ff2 <alltraps>

80105804 <vector111>:
.globl vector111
vector111:
  pushl $0
80105804:	6a 00                	push   $0x0
  pushl $111
80105806:	6a 6f                	push   $0x6f
  jmp alltraps
80105808:	e9 e5 f7 ff ff       	jmp    80104ff2 <alltraps>

8010580d <vector112>:
.globl vector112
vector112:
  pushl $0
8010580d:	6a 00                	push   $0x0
  pushl $112
8010580f:	6a 70                	push   $0x70
  jmp alltraps
80105811:	e9 dc f7 ff ff       	jmp    80104ff2 <alltraps>

80105816 <vector113>:
.globl vector113
vector113:
  pushl $0
80105816:	6a 00                	push   $0x0
  pushl $113
80105818:	6a 71                	push   $0x71
  jmp alltraps
8010581a:	e9 d3 f7 ff ff       	jmp    80104ff2 <alltraps>

8010581f <vector114>:
.globl vector114
vector114:
  pushl $0
8010581f:	6a 00                	push   $0x0
  pushl $114
80105821:	6a 72                	push   $0x72
  jmp alltraps
80105823:	e9 ca f7 ff ff       	jmp    80104ff2 <alltraps>

80105828 <vector115>:
.globl vector115
vector115:
  pushl $0
80105828:	6a 00                	push   $0x0
  pushl $115
8010582a:	6a 73                	push   $0x73
  jmp alltraps
8010582c:	e9 c1 f7 ff ff       	jmp    80104ff2 <alltraps>

80105831 <vector116>:
.globl vector116
vector116:
  pushl $0
80105831:	6a 00                	push   $0x0
  pushl $116
80105833:	6a 74                	push   $0x74
  jmp alltraps
80105835:	e9 b8 f7 ff ff       	jmp    80104ff2 <alltraps>

8010583a <vector117>:
.globl vector117
vector117:
  pushl $0
8010583a:	6a 00                	push   $0x0
  pushl $117
8010583c:	6a 75                	push   $0x75
  jmp alltraps
8010583e:	e9 af f7 ff ff       	jmp    80104ff2 <alltraps>

80105843 <vector118>:
.globl vector118
vector118:
  pushl $0
80105843:	6a 00                	push   $0x0
  pushl $118
80105845:	6a 76                	push   $0x76
  jmp alltraps
80105847:	e9 a6 f7 ff ff       	jmp    80104ff2 <alltraps>

8010584c <vector119>:
.globl vector119
vector119:
  pushl $0
8010584c:	6a 00                	push   $0x0
  pushl $119
8010584e:	6a 77                	push   $0x77
  jmp alltraps
80105850:	e9 9d f7 ff ff       	jmp    80104ff2 <alltraps>

80105855 <vector120>:
.globl vector120
vector120:
  pushl $0
80105855:	6a 00                	push   $0x0
  pushl $120
80105857:	6a 78                	push   $0x78
  jmp alltraps
80105859:	e9 94 f7 ff ff       	jmp    80104ff2 <alltraps>

8010585e <vector121>:
.globl vector121
vector121:
  pushl $0
8010585e:	6a 00                	push   $0x0
  pushl $121
80105860:	6a 79                	push   $0x79
  jmp alltraps
80105862:	e9 8b f7 ff ff       	jmp    80104ff2 <alltraps>

80105867 <vector122>:
.globl vector122
vector122:
  pushl $0
80105867:	6a 00                	push   $0x0
  pushl $122
80105869:	6a 7a                	push   $0x7a
  jmp alltraps
8010586b:	e9 82 f7 ff ff       	jmp    80104ff2 <alltraps>

80105870 <vector123>:
.globl vector123
vector123:
  pushl $0
80105870:	6a 00                	push   $0x0
  pushl $123
80105872:	6a 7b                	push   $0x7b
  jmp alltraps
80105874:	e9 79 f7 ff ff       	jmp    80104ff2 <alltraps>

80105879 <vector124>:
.globl vector124
vector124:
  pushl $0
80105879:	6a 00                	push   $0x0
  pushl $124
8010587b:	6a 7c                	push   $0x7c
  jmp alltraps
8010587d:	e9 70 f7 ff ff       	jmp    80104ff2 <alltraps>

80105882 <vector125>:
.globl vector125
vector125:
  pushl $0
80105882:	6a 00                	push   $0x0
  pushl $125
80105884:	6a 7d                	push   $0x7d
  jmp alltraps
80105886:	e9 67 f7 ff ff       	jmp    80104ff2 <alltraps>

8010588b <vector126>:
.globl vector126
vector126:
  pushl $0
8010588b:	6a 00                	push   $0x0
  pushl $126
8010588d:	6a 7e                	push   $0x7e
  jmp alltraps
8010588f:	e9 5e f7 ff ff       	jmp    80104ff2 <alltraps>

80105894 <vector127>:
.globl vector127
vector127:
  pushl $0
80105894:	6a 00                	push   $0x0
  pushl $127
80105896:	6a 7f                	push   $0x7f
  jmp alltraps
80105898:	e9 55 f7 ff ff       	jmp    80104ff2 <alltraps>

8010589d <vector128>:
.globl vector128
vector128:
  pushl $0
8010589d:	6a 00                	push   $0x0
  pushl $128
8010589f:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801058a4:	e9 49 f7 ff ff       	jmp    80104ff2 <alltraps>

801058a9 <vector129>:
.globl vector129
vector129:
  pushl $0
801058a9:	6a 00                	push   $0x0
  pushl $129
801058ab:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801058b0:	e9 3d f7 ff ff       	jmp    80104ff2 <alltraps>

801058b5 <vector130>:
.globl vector130
vector130:
  pushl $0
801058b5:	6a 00                	push   $0x0
  pushl $130
801058b7:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801058bc:	e9 31 f7 ff ff       	jmp    80104ff2 <alltraps>

801058c1 <vector131>:
.globl vector131
vector131:
  pushl $0
801058c1:	6a 00                	push   $0x0
  pushl $131
801058c3:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801058c8:	e9 25 f7 ff ff       	jmp    80104ff2 <alltraps>

801058cd <vector132>:
.globl vector132
vector132:
  pushl $0
801058cd:	6a 00                	push   $0x0
  pushl $132
801058cf:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801058d4:	e9 19 f7 ff ff       	jmp    80104ff2 <alltraps>

801058d9 <vector133>:
.globl vector133
vector133:
  pushl $0
801058d9:	6a 00                	push   $0x0
  pushl $133
801058db:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801058e0:	e9 0d f7 ff ff       	jmp    80104ff2 <alltraps>

801058e5 <vector134>:
.globl vector134
vector134:
  pushl $0
801058e5:	6a 00                	push   $0x0
  pushl $134
801058e7:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801058ec:	e9 01 f7 ff ff       	jmp    80104ff2 <alltraps>

801058f1 <vector135>:
.globl vector135
vector135:
  pushl $0
801058f1:	6a 00                	push   $0x0
  pushl $135
801058f3:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801058f8:	e9 f5 f6 ff ff       	jmp    80104ff2 <alltraps>

801058fd <vector136>:
.globl vector136
vector136:
  pushl $0
801058fd:	6a 00                	push   $0x0
  pushl $136
801058ff:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80105904:	e9 e9 f6 ff ff       	jmp    80104ff2 <alltraps>

80105909 <vector137>:
.globl vector137
vector137:
  pushl $0
80105909:	6a 00                	push   $0x0
  pushl $137
8010590b:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80105910:	e9 dd f6 ff ff       	jmp    80104ff2 <alltraps>

80105915 <vector138>:
.globl vector138
vector138:
  pushl $0
80105915:	6a 00                	push   $0x0
  pushl $138
80105917:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
8010591c:	e9 d1 f6 ff ff       	jmp    80104ff2 <alltraps>

80105921 <vector139>:
.globl vector139
vector139:
  pushl $0
80105921:	6a 00                	push   $0x0
  pushl $139
80105923:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80105928:	e9 c5 f6 ff ff       	jmp    80104ff2 <alltraps>

8010592d <vector140>:
.globl vector140
vector140:
  pushl $0
8010592d:	6a 00                	push   $0x0
  pushl $140
8010592f:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80105934:	e9 b9 f6 ff ff       	jmp    80104ff2 <alltraps>

80105939 <vector141>:
.globl vector141
vector141:
  pushl $0
80105939:	6a 00                	push   $0x0
  pushl $141
8010593b:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80105940:	e9 ad f6 ff ff       	jmp    80104ff2 <alltraps>

80105945 <vector142>:
.globl vector142
vector142:
  pushl $0
80105945:	6a 00                	push   $0x0
  pushl $142
80105947:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
8010594c:	e9 a1 f6 ff ff       	jmp    80104ff2 <alltraps>

80105951 <vector143>:
.globl vector143
vector143:
  pushl $0
80105951:	6a 00                	push   $0x0
  pushl $143
80105953:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80105958:	e9 95 f6 ff ff       	jmp    80104ff2 <alltraps>

8010595d <vector144>:
.globl vector144
vector144:
  pushl $0
8010595d:	6a 00                	push   $0x0
  pushl $144
8010595f:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80105964:	e9 89 f6 ff ff       	jmp    80104ff2 <alltraps>

80105969 <vector145>:
.globl vector145
vector145:
  pushl $0
80105969:	6a 00                	push   $0x0
  pushl $145
8010596b:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80105970:	e9 7d f6 ff ff       	jmp    80104ff2 <alltraps>

80105975 <vector146>:
.globl vector146
vector146:
  pushl $0
80105975:	6a 00                	push   $0x0
  pushl $146
80105977:	68 92 00 00 00       	push   $0x92
  jmp alltraps
8010597c:	e9 71 f6 ff ff       	jmp    80104ff2 <alltraps>

80105981 <vector147>:
.globl vector147
vector147:
  pushl $0
80105981:	6a 00                	push   $0x0
  pushl $147
80105983:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80105988:	e9 65 f6 ff ff       	jmp    80104ff2 <alltraps>

8010598d <vector148>:
.globl vector148
vector148:
  pushl $0
8010598d:	6a 00                	push   $0x0
  pushl $148
8010598f:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80105994:	e9 59 f6 ff ff       	jmp    80104ff2 <alltraps>

80105999 <vector149>:
.globl vector149
vector149:
  pushl $0
80105999:	6a 00                	push   $0x0
  pushl $149
8010599b:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801059a0:	e9 4d f6 ff ff       	jmp    80104ff2 <alltraps>

801059a5 <vector150>:
.globl vector150
vector150:
  pushl $0
801059a5:	6a 00                	push   $0x0
  pushl $150
801059a7:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801059ac:	e9 41 f6 ff ff       	jmp    80104ff2 <alltraps>

801059b1 <vector151>:
.globl vector151
vector151:
  pushl $0
801059b1:	6a 00                	push   $0x0
  pushl $151
801059b3:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801059b8:	e9 35 f6 ff ff       	jmp    80104ff2 <alltraps>

801059bd <vector152>:
.globl vector152
vector152:
  pushl $0
801059bd:	6a 00                	push   $0x0
  pushl $152
801059bf:	68 98 00 00 00       	push   $0x98
  jmp alltraps
801059c4:	e9 29 f6 ff ff       	jmp    80104ff2 <alltraps>

801059c9 <vector153>:
.globl vector153
vector153:
  pushl $0
801059c9:	6a 00                	push   $0x0
  pushl $153
801059cb:	68 99 00 00 00       	push   $0x99
  jmp alltraps
801059d0:	e9 1d f6 ff ff       	jmp    80104ff2 <alltraps>

801059d5 <vector154>:
.globl vector154
vector154:
  pushl $0
801059d5:	6a 00                	push   $0x0
  pushl $154
801059d7:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
801059dc:	e9 11 f6 ff ff       	jmp    80104ff2 <alltraps>

801059e1 <vector155>:
.globl vector155
vector155:
  pushl $0
801059e1:	6a 00                	push   $0x0
  pushl $155
801059e3:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
801059e8:	e9 05 f6 ff ff       	jmp    80104ff2 <alltraps>

801059ed <vector156>:
.globl vector156
vector156:
  pushl $0
801059ed:	6a 00                	push   $0x0
  pushl $156
801059ef:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
801059f4:	e9 f9 f5 ff ff       	jmp    80104ff2 <alltraps>

801059f9 <vector157>:
.globl vector157
vector157:
  pushl $0
801059f9:	6a 00                	push   $0x0
  pushl $157
801059fb:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80105a00:	e9 ed f5 ff ff       	jmp    80104ff2 <alltraps>

80105a05 <vector158>:
.globl vector158
vector158:
  pushl $0
80105a05:	6a 00                	push   $0x0
  pushl $158
80105a07:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80105a0c:	e9 e1 f5 ff ff       	jmp    80104ff2 <alltraps>

80105a11 <vector159>:
.globl vector159
vector159:
  pushl $0
80105a11:	6a 00                	push   $0x0
  pushl $159
80105a13:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80105a18:	e9 d5 f5 ff ff       	jmp    80104ff2 <alltraps>

80105a1d <vector160>:
.globl vector160
vector160:
  pushl $0
80105a1d:	6a 00                	push   $0x0
  pushl $160
80105a1f:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80105a24:	e9 c9 f5 ff ff       	jmp    80104ff2 <alltraps>

80105a29 <vector161>:
.globl vector161
vector161:
  pushl $0
80105a29:	6a 00                	push   $0x0
  pushl $161
80105a2b:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80105a30:	e9 bd f5 ff ff       	jmp    80104ff2 <alltraps>

80105a35 <vector162>:
.globl vector162
vector162:
  pushl $0
80105a35:	6a 00                	push   $0x0
  pushl $162
80105a37:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105a3c:	e9 b1 f5 ff ff       	jmp    80104ff2 <alltraps>

80105a41 <vector163>:
.globl vector163
vector163:
  pushl $0
80105a41:	6a 00                	push   $0x0
  pushl $163
80105a43:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105a48:	e9 a5 f5 ff ff       	jmp    80104ff2 <alltraps>

80105a4d <vector164>:
.globl vector164
vector164:
  pushl $0
80105a4d:	6a 00                	push   $0x0
  pushl $164
80105a4f:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80105a54:	e9 99 f5 ff ff       	jmp    80104ff2 <alltraps>

80105a59 <vector165>:
.globl vector165
vector165:
  pushl $0
80105a59:	6a 00                	push   $0x0
  pushl $165
80105a5b:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80105a60:	e9 8d f5 ff ff       	jmp    80104ff2 <alltraps>

80105a65 <vector166>:
.globl vector166
vector166:
  pushl $0
80105a65:	6a 00                	push   $0x0
  pushl $166
80105a67:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105a6c:	e9 81 f5 ff ff       	jmp    80104ff2 <alltraps>

80105a71 <vector167>:
.globl vector167
vector167:
  pushl $0
80105a71:	6a 00                	push   $0x0
  pushl $167
80105a73:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105a78:	e9 75 f5 ff ff       	jmp    80104ff2 <alltraps>

80105a7d <vector168>:
.globl vector168
vector168:
  pushl $0
80105a7d:	6a 00                	push   $0x0
  pushl $168
80105a7f:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105a84:	e9 69 f5 ff ff       	jmp    80104ff2 <alltraps>

80105a89 <vector169>:
.globl vector169
vector169:
  pushl $0
80105a89:	6a 00                	push   $0x0
  pushl $169
80105a8b:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80105a90:	e9 5d f5 ff ff       	jmp    80104ff2 <alltraps>

80105a95 <vector170>:
.globl vector170
vector170:
  pushl $0
80105a95:	6a 00                	push   $0x0
  pushl $170
80105a97:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105a9c:	e9 51 f5 ff ff       	jmp    80104ff2 <alltraps>

80105aa1 <vector171>:
.globl vector171
vector171:
  pushl $0
80105aa1:	6a 00                	push   $0x0
  pushl $171
80105aa3:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105aa8:	e9 45 f5 ff ff       	jmp    80104ff2 <alltraps>

80105aad <vector172>:
.globl vector172
vector172:
  pushl $0
80105aad:	6a 00                	push   $0x0
  pushl $172
80105aaf:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105ab4:	e9 39 f5 ff ff       	jmp    80104ff2 <alltraps>

80105ab9 <vector173>:
.globl vector173
vector173:
  pushl $0
80105ab9:	6a 00                	push   $0x0
  pushl $173
80105abb:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80105ac0:	e9 2d f5 ff ff       	jmp    80104ff2 <alltraps>

80105ac5 <vector174>:
.globl vector174
vector174:
  pushl $0
80105ac5:	6a 00                	push   $0x0
  pushl $174
80105ac7:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105acc:	e9 21 f5 ff ff       	jmp    80104ff2 <alltraps>

80105ad1 <vector175>:
.globl vector175
vector175:
  pushl $0
80105ad1:	6a 00                	push   $0x0
  pushl $175
80105ad3:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105ad8:	e9 15 f5 ff ff       	jmp    80104ff2 <alltraps>

80105add <vector176>:
.globl vector176
vector176:
  pushl $0
80105add:	6a 00                	push   $0x0
  pushl $176
80105adf:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105ae4:	e9 09 f5 ff ff       	jmp    80104ff2 <alltraps>

80105ae9 <vector177>:
.globl vector177
vector177:
  pushl $0
80105ae9:	6a 00                	push   $0x0
  pushl $177
80105aeb:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105af0:	e9 fd f4 ff ff       	jmp    80104ff2 <alltraps>

80105af5 <vector178>:
.globl vector178
vector178:
  pushl $0
80105af5:	6a 00                	push   $0x0
  pushl $178
80105af7:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105afc:	e9 f1 f4 ff ff       	jmp    80104ff2 <alltraps>

80105b01 <vector179>:
.globl vector179
vector179:
  pushl $0
80105b01:	6a 00                	push   $0x0
  pushl $179
80105b03:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105b08:	e9 e5 f4 ff ff       	jmp    80104ff2 <alltraps>

80105b0d <vector180>:
.globl vector180
vector180:
  pushl $0
80105b0d:	6a 00                	push   $0x0
  pushl $180
80105b0f:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105b14:	e9 d9 f4 ff ff       	jmp    80104ff2 <alltraps>

80105b19 <vector181>:
.globl vector181
vector181:
  pushl $0
80105b19:	6a 00                	push   $0x0
  pushl $181
80105b1b:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105b20:	e9 cd f4 ff ff       	jmp    80104ff2 <alltraps>

80105b25 <vector182>:
.globl vector182
vector182:
  pushl $0
80105b25:	6a 00                	push   $0x0
  pushl $182
80105b27:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105b2c:	e9 c1 f4 ff ff       	jmp    80104ff2 <alltraps>

80105b31 <vector183>:
.globl vector183
vector183:
  pushl $0
80105b31:	6a 00                	push   $0x0
  pushl $183
80105b33:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105b38:	e9 b5 f4 ff ff       	jmp    80104ff2 <alltraps>

80105b3d <vector184>:
.globl vector184
vector184:
  pushl $0
80105b3d:	6a 00                	push   $0x0
  pushl $184
80105b3f:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105b44:	e9 a9 f4 ff ff       	jmp    80104ff2 <alltraps>

80105b49 <vector185>:
.globl vector185
vector185:
  pushl $0
80105b49:	6a 00                	push   $0x0
  pushl $185
80105b4b:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105b50:	e9 9d f4 ff ff       	jmp    80104ff2 <alltraps>

80105b55 <vector186>:
.globl vector186
vector186:
  pushl $0
80105b55:	6a 00                	push   $0x0
  pushl $186
80105b57:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105b5c:	e9 91 f4 ff ff       	jmp    80104ff2 <alltraps>

80105b61 <vector187>:
.globl vector187
vector187:
  pushl $0
80105b61:	6a 00                	push   $0x0
  pushl $187
80105b63:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105b68:	e9 85 f4 ff ff       	jmp    80104ff2 <alltraps>

80105b6d <vector188>:
.globl vector188
vector188:
  pushl $0
80105b6d:	6a 00                	push   $0x0
  pushl $188
80105b6f:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105b74:	e9 79 f4 ff ff       	jmp    80104ff2 <alltraps>

80105b79 <vector189>:
.globl vector189
vector189:
  pushl $0
80105b79:	6a 00                	push   $0x0
  pushl $189
80105b7b:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105b80:	e9 6d f4 ff ff       	jmp    80104ff2 <alltraps>

80105b85 <vector190>:
.globl vector190
vector190:
  pushl $0
80105b85:	6a 00                	push   $0x0
  pushl $190
80105b87:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105b8c:	e9 61 f4 ff ff       	jmp    80104ff2 <alltraps>

80105b91 <vector191>:
.globl vector191
vector191:
  pushl $0
80105b91:	6a 00                	push   $0x0
  pushl $191
80105b93:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105b98:	e9 55 f4 ff ff       	jmp    80104ff2 <alltraps>

80105b9d <vector192>:
.globl vector192
vector192:
  pushl $0
80105b9d:	6a 00                	push   $0x0
  pushl $192
80105b9f:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105ba4:	e9 49 f4 ff ff       	jmp    80104ff2 <alltraps>

80105ba9 <vector193>:
.globl vector193
vector193:
  pushl $0
80105ba9:	6a 00                	push   $0x0
  pushl $193
80105bab:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105bb0:	e9 3d f4 ff ff       	jmp    80104ff2 <alltraps>

80105bb5 <vector194>:
.globl vector194
vector194:
  pushl $0
80105bb5:	6a 00                	push   $0x0
  pushl $194
80105bb7:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105bbc:	e9 31 f4 ff ff       	jmp    80104ff2 <alltraps>

80105bc1 <vector195>:
.globl vector195
vector195:
  pushl $0
80105bc1:	6a 00                	push   $0x0
  pushl $195
80105bc3:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105bc8:	e9 25 f4 ff ff       	jmp    80104ff2 <alltraps>

80105bcd <vector196>:
.globl vector196
vector196:
  pushl $0
80105bcd:	6a 00                	push   $0x0
  pushl $196
80105bcf:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105bd4:	e9 19 f4 ff ff       	jmp    80104ff2 <alltraps>

80105bd9 <vector197>:
.globl vector197
vector197:
  pushl $0
80105bd9:	6a 00                	push   $0x0
  pushl $197
80105bdb:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105be0:	e9 0d f4 ff ff       	jmp    80104ff2 <alltraps>

80105be5 <vector198>:
.globl vector198
vector198:
  pushl $0
80105be5:	6a 00                	push   $0x0
  pushl $198
80105be7:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105bec:	e9 01 f4 ff ff       	jmp    80104ff2 <alltraps>

80105bf1 <vector199>:
.globl vector199
vector199:
  pushl $0
80105bf1:	6a 00                	push   $0x0
  pushl $199
80105bf3:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105bf8:	e9 f5 f3 ff ff       	jmp    80104ff2 <alltraps>

80105bfd <vector200>:
.globl vector200
vector200:
  pushl $0
80105bfd:	6a 00                	push   $0x0
  pushl $200
80105bff:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105c04:	e9 e9 f3 ff ff       	jmp    80104ff2 <alltraps>

80105c09 <vector201>:
.globl vector201
vector201:
  pushl $0
80105c09:	6a 00                	push   $0x0
  pushl $201
80105c0b:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105c10:	e9 dd f3 ff ff       	jmp    80104ff2 <alltraps>

80105c15 <vector202>:
.globl vector202
vector202:
  pushl $0
80105c15:	6a 00                	push   $0x0
  pushl $202
80105c17:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105c1c:	e9 d1 f3 ff ff       	jmp    80104ff2 <alltraps>

80105c21 <vector203>:
.globl vector203
vector203:
  pushl $0
80105c21:	6a 00                	push   $0x0
  pushl $203
80105c23:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105c28:	e9 c5 f3 ff ff       	jmp    80104ff2 <alltraps>

80105c2d <vector204>:
.globl vector204
vector204:
  pushl $0
80105c2d:	6a 00                	push   $0x0
  pushl $204
80105c2f:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105c34:	e9 b9 f3 ff ff       	jmp    80104ff2 <alltraps>

80105c39 <vector205>:
.globl vector205
vector205:
  pushl $0
80105c39:	6a 00                	push   $0x0
  pushl $205
80105c3b:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105c40:	e9 ad f3 ff ff       	jmp    80104ff2 <alltraps>

80105c45 <vector206>:
.globl vector206
vector206:
  pushl $0
80105c45:	6a 00                	push   $0x0
  pushl $206
80105c47:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105c4c:	e9 a1 f3 ff ff       	jmp    80104ff2 <alltraps>

80105c51 <vector207>:
.globl vector207
vector207:
  pushl $0
80105c51:	6a 00                	push   $0x0
  pushl $207
80105c53:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105c58:	e9 95 f3 ff ff       	jmp    80104ff2 <alltraps>

80105c5d <vector208>:
.globl vector208
vector208:
  pushl $0
80105c5d:	6a 00                	push   $0x0
  pushl $208
80105c5f:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105c64:	e9 89 f3 ff ff       	jmp    80104ff2 <alltraps>

80105c69 <vector209>:
.globl vector209
vector209:
  pushl $0
80105c69:	6a 00                	push   $0x0
  pushl $209
80105c6b:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105c70:	e9 7d f3 ff ff       	jmp    80104ff2 <alltraps>

80105c75 <vector210>:
.globl vector210
vector210:
  pushl $0
80105c75:	6a 00                	push   $0x0
  pushl $210
80105c77:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105c7c:	e9 71 f3 ff ff       	jmp    80104ff2 <alltraps>

80105c81 <vector211>:
.globl vector211
vector211:
  pushl $0
80105c81:	6a 00                	push   $0x0
  pushl $211
80105c83:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105c88:	e9 65 f3 ff ff       	jmp    80104ff2 <alltraps>

80105c8d <vector212>:
.globl vector212
vector212:
  pushl $0
80105c8d:	6a 00                	push   $0x0
  pushl $212
80105c8f:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105c94:	e9 59 f3 ff ff       	jmp    80104ff2 <alltraps>

80105c99 <vector213>:
.globl vector213
vector213:
  pushl $0
80105c99:	6a 00                	push   $0x0
  pushl $213
80105c9b:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105ca0:	e9 4d f3 ff ff       	jmp    80104ff2 <alltraps>

80105ca5 <vector214>:
.globl vector214
vector214:
  pushl $0
80105ca5:	6a 00                	push   $0x0
  pushl $214
80105ca7:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105cac:	e9 41 f3 ff ff       	jmp    80104ff2 <alltraps>

80105cb1 <vector215>:
.globl vector215
vector215:
  pushl $0
80105cb1:	6a 00                	push   $0x0
  pushl $215
80105cb3:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105cb8:	e9 35 f3 ff ff       	jmp    80104ff2 <alltraps>

80105cbd <vector216>:
.globl vector216
vector216:
  pushl $0
80105cbd:	6a 00                	push   $0x0
  pushl $216
80105cbf:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105cc4:	e9 29 f3 ff ff       	jmp    80104ff2 <alltraps>

80105cc9 <vector217>:
.globl vector217
vector217:
  pushl $0
80105cc9:	6a 00                	push   $0x0
  pushl $217
80105ccb:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105cd0:	e9 1d f3 ff ff       	jmp    80104ff2 <alltraps>

80105cd5 <vector218>:
.globl vector218
vector218:
  pushl $0
80105cd5:	6a 00                	push   $0x0
  pushl $218
80105cd7:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105cdc:	e9 11 f3 ff ff       	jmp    80104ff2 <alltraps>

80105ce1 <vector219>:
.globl vector219
vector219:
  pushl $0
80105ce1:	6a 00                	push   $0x0
  pushl $219
80105ce3:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105ce8:	e9 05 f3 ff ff       	jmp    80104ff2 <alltraps>

80105ced <vector220>:
.globl vector220
vector220:
  pushl $0
80105ced:	6a 00                	push   $0x0
  pushl $220
80105cef:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105cf4:	e9 f9 f2 ff ff       	jmp    80104ff2 <alltraps>

80105cf9 <vector221>:
.globl vector221
vector221:
  pushl $0
80105cf9:	6a 00                	push   $0x0
  pushl $221
80105cfb:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105d00:	e9 ed f2 ff ff       	jmp    80104ff2 <alltraps>

80105d05 <vector222>:
.globl vector222
vector222:
  pushl $0
80105d05:	6a 00                	push   $0x0
  pushl $222
80105d07:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105d0c:	e9 e1 f2 ff ff       	jmp    80104ff2 <alltraps>

80105d11 <vector223>:
.globl vector223
vector223:
  pushl $0
80105d11:	6a 00                	push   $0x0
  pushl $223
80105d13:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105d18:	e9 d5 f2 ff ff       	jmp    80104ff2 <alltraps>

80105d1d <vector224>:
.globl vector224
vector224:
  pushl $0
80105d1d:	6a 00                	push   $0x0
  pushl $224
80105d1f:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105d24:	e9 c9 f2 ff ff       	jmp    80104ff2 <alltraps>

80105d29 <vector225>:
.globl vector225
vector225:
  pushl $0
80105d29:	6a 00                	push   $0x0
  pushl $225
80105d2b:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105d30:	e9 bd f2 ff ff       	jmp    80104ff2 <alltraps>

80105d35 <vector226>:
.globl vector226
vector226:
  pushl $0
80105d35:	6a 00                	push   $0x0
  pushl $226
80105d37:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105d3c:	e9 b1 f2 ff ff       	jmp    80104ff2 <alltraps>

80105d41 <vector227>:
.globl vector227
vector227:
  pushl $0
80105d41:	6a 00                	push   $0x0
  pushl $227
80105d43:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105d48:	e9 a5 f2 ff ff       	jmp    80104ff2 <alltraps>

80105d4d <vector228>:
.globl vector228
vector228:
  pushl $0
80105d4d:	6a 00                	push   $0x0
  pushl $228
80105d4f:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105d54:	e9 99 f2 ff ff       	jmp    80104ff2 <alltraps>

80105d59 <vector229>:
.globl vector229
vector229:
  pushl $0
80105d59:	6a 00                	push   $0x0
  pushl $229
80105d5b:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105d60:	e9 8d f2 ff ff       	jmp    80104ff2 <alltraps>

80105d65 <vector230>:
.globl vector230
vector230:
  pushl $0
80105d65:	6a 00                	push   $0x0
  pushl $230
80105d67:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105d6c:	e9 81 f2 ff ff       	jmp    80104ff2 <alltraps>

80105d71 <vector231>:
.globl vector231
vector231:
  pushl $0
80105d71:	6a 00                	push   $0x0
  pushl $231
80105d73:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105d78:	e9 75 f2 ff ff       	jmp    80104ff2 <alltraps>

80105d7d <vector232>:
.globl vector232
vector232:
  pushl $0
80105d7d:	6a 00                	push   $0x0
  pushl $232
80105d7f:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105d84:	e9 69 f2 ff ff       	jmp    80104ff2 <alltraps>

80105d89 <vector233>:
.globl vector233
vector233:
  pushl $0
80105d89:	6a 00                	push   $0x0
  pushl $233
80105d8b:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105d90:	e9 5d f2 ff ff       	jmp    80104ff2 <alltraps>

80105d95 <vector234>:
.globl vector234
vector234:
  pushl $0
80105d95:	6a 00                	push   $0x0
  pushl $234
80105d97:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105d9c:	e9 51 f2 ff ff       	jmp    80104ff2 <alltraps>

80105da1 <vector235>:
.globl vector235
vector235:
  pushl $0
80105da1:	6a 00                	push   $0x0
  pushl $235
80105da3:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105da8:	e9 45 f2 ff ff       	jmp    80104ff2 <alltraps>

80105dad <vector236>:
.globl vector236
vector236:
  pushl $0
80105dad:	6a 00                	push   $0x0
  pushl $236
80105daf:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105db4:	e9 39 f2 ff ff       	jmp    80104ff2 <alltraps>

80105db9 <vector237>:
.globl vector237
vector237:
  pushl $0
80105db9:	6a 00                	push   $0x0
  pushl $237
80105dbb:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105dc0:	e9 2d f2 ff ff       	jmp    80104ff2 <alltraps>

80105dc5 <vector238>:
.globl vector238
vector238:
  pushl $0
80105dc5:	6a 00                	push   $0x0
  pushl $238
80105dc7:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105dcc:	e9 21 f2 ff ff       	jmp    80104ff2 <alltraps>

80105dd1 <vector239>:
.globl vector239
vector239:
  pushl $0
80105dd1:	6a 00                	push   $0x0
  pushl $239
80105dd3:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105dd8:	e9 15 f2 ff ff       	jmp    80104ff2 <alltraps>

80105ddd <vector240>:
.globl vector240
vector240:
  pushl $0
80105ddd:	6a 00                	push   $0x0
  pushl $240
80105ddf:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105de4:	e9 09 f2 ff ff       	jmp    80104ff2 <alltraps>

80105de9 <vector241>:
.globl vector241
vector241:
  pushl $0
80105de9:	6a 00                	push   $0x0
  pushl $241
80105deb:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105df0:	e9 fd f1 ff ff       	jmp    80104ff2 <alltraps>

80105df5 <vector242>:
.globl vector242
vector242:
  pushl $0
80105df5:	6a 00                	push   $0x0
  pushl $242
80105df7:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105dfc:	e9 f1 f1 ff ff       	jmp    80104ff2 <alltraps>

80105e01 <vector243>:
.globl vector243
vector243:
  pushl $0
80105e01:	6a 00                	push   $0x0
  pushl $243
80105e03:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105e08:	e9 e5 f1 ff ff       	jmp    80104ff2 <alltraps>

80105e0d <vector244>:
.globl vector244
vector244:
  pushl $0
80105e0d:	6a 00                	push   $0x0
  pushl $244
80105e0f:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105e14:	e9 d9 f1 ff ff       	jmp    80104ff2 <alltraps>

80105e19 <vector245>:
.globl vector245
vector245:
  pushl $0
80105e19:	6a 00                	push   $0x0
  pushl $245
80105e1b:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105e20:	e9 cd f1 ff ff       	jmp    80104ff2 <alltraps>

80105e25 <vector246>:
.globl vector246
vector246:
  pushl $0
80105e25:	6a 00                	push   $0x0
  pushl $246
80105e27:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105e2c:	e9 c1 f1 ff ff       	jmp    80104ff2 <alltraps>

80105e31 <vector247>:
.globl vector247
vector247:
  pushl $0
80105e31:	6a 00                	push   $0x0
  pushl $247
80105e33:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105e38:	e9 b5 f1 ff ff       	jmp    80104ff2 <alltraps>

80105e3d <vector248>:
.globl vector248
vector248:
  pushl $0
80105e3d:	6a 00                	push   $0x0
  pushl $248
80105e3f:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105e44:	e9 a9 f1 ff ff       	jmp    80104ff2 <alltraps>

80105e49 <vector249>:
.globl vector249
vector249:
  pushl $0
80105e49:	6a 00                	push   $0x0
  pushl $249
80105e4b:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105e50:	e9 9d f1 ff ff       	jmp    80104ff2 <alltraps>

80105e55 <vector250>:
.globl vector250
vector250:
  pushl $0
80105e55:	6a 00                	push   $0x0
  pushl $250
80105e57:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105e5c:	e9 91 f1 ff ff       	jmp    80104ff2 <alltraps>

80105e61 <vector251>:
.globl vector251
vector251:
  pushl $0
80105e61:	6a 00                	push   $0x0
  pushl $251
80105e63:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105e68:	e9 85 f1 ff ff       	jmp    80104ff2 <alltraps>

80105e6d <vector252>:
.globl vector252
vector252:
  pushl $0
80105e6d:	6a 00                	push   $0x0
  pushl $252
80105e6f:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105e74:	e9 79 f1 ff ff       	jmp    80104ff2 <alltraps>

80105e79 <vector253>:
.globl vector253
vector253:
  pushl $0
80105e79:	6a 00                	push   $0x0
  pushl $253
80105e7b:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105e80:	e9 6d f1 ff ff       	jmp    80104ff2 <alltraps>

80105e85 <vector254>:
.globl vector254
vector254:
  pushl $0
80105e85:	6a 00                	push   $0x0
  pushl $254
80105e87:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105e8c:	e9 61 f1 ff ff       	jmp    80104ff2 <alltraps>

80105e91 <vector255>:
.globl vector255
vector255:
  pushl $0
80105e91:	6a 00                	push   $0x0
  pushl $255
80105e93:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105e98:	e9 55 f1 ff ff       	jmp    80104ff2 <alltraps>

80105e9d <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105e9d:	55                   	push   %ebp
80105e9e:	89 e5                	mov    %esp,%ebp
80105ea0:	57                   	push   %edi
80105ea1:	56                   	push   %esi
80105ea2:	53                   	push   %ebx
80105ea3:	83 ec 0c             	sub    $0xc,%esp
80105ea6:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105ea8:	c1 ea 16             	shr    $0x16,%edx
80105eab:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105eae:	8b 1f                	mov    (%edi),%ebx
80105eb0:	f6 c3 01             	test   $0x1,%bl
80105eb3:	74 22                	je     80105ed7 <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105eb5:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105ebb:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105ec1:	c1 ee 0c             	shr    $0xc,%esi
80105ec4:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105eca:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105ecd:	89 d8                	mov    %ebx,%eax
80105ecf:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105ed2:	5b                   	pop    %ebx
80105ed3:	5e                   	pop    %esi
80105ed4:	5f                   	pop    %edi
80105ed5:	5d                   	pop    %ebp
80105ed6:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80105ed7:	85 c9                	test   %ecx,%ecx
80105ed9:	74 2b                	je     80105f06 <walkpgdir+0x69>
80105edb:	e8 74 c3 ff ff       	call   80102254 <kalloc>
80105ee0:	89 c3                	mov    %eax,%ebx
80105ee2:	85 c0                	test   %eax,%eax
80105ee4:	74 e7                	je     80105ecd <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105ee6:	83 ec 04             	sub    $0x4,%esp
80105ee9:	68 00 10 00 00       	push   $0x1000
80105eee:	6a 00                	push   $0x0
80105ef0:	50                   	push   %eax
80105ef1:	e8 fe df ff ff       	call   80103ef4 <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105ef6:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105efc:	83 c8 07             	or     $0x7,%eax
80105eff:	89 07                	mov    %eax,(%edi)
80105f01:	83 c4 10             	add    $0x10,%esp
80105f04:	eb bb                	jmp    80105ec1 <walkpgdir+0x24>
      return 0;
80105f06:	bb 00 00 00 00       	mov    $0x0,%ebx
80105f0b:	eb c0                	jmp    80105ecd <walkpgdir+0x30>

80105f0d <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105f0d:	55                   	push   %ebp
80105f0e:	89 e5                	mov    %esp,%ebp
80105f10:	57                   	push   %edi
80105f11:	56                   	push   %esi
80105f12:	53                   	push   %ebx
80105f13:	83 ec 1c             	sub    $0x1c,%esp
80105f16:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105f19:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105f1c:	89 d3                	mov    %edx,%ebx
80105f1e:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105f24:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105f28:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105f2e:	b9 01 00 00 00       	mov    $0x1,%ecx
80105f33:	89 da                	mov    %ebx,%edx
80105f35:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105f38:	e8 60 ff ff ff       	call   80105e9d <walkpgdir>
80105f3d:	85 c0                	test   %eax,%eax
80105f3f:	74 2e                	je     80105f6f <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105f41:	f6 00 01             	testb  $0x1,(%eax)
80105f44:	75 1c                	jne    80105f62 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105f46:	89 f2                	mov    %esi,%edx
80105f48:	0b 55 0c             	or     0xc(%ebp),%edx
80105f4b:	83 ca 01             	or     $0x1,%edx
80105f4e:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105f50:	39 fb                	cmp    %edi,%ebx
80105f52:	74 28                	je     80105f7c <mappages+0x6f>
      break;
    a += PGSIZE;
80105f54:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105f5a:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105f60:	eb cc                	jmp    80105f2e <mappages+0x21>
      panic("remap");
80105f62:	83 ec 0c             	sub    $0xc,%esp
80105f65:	68 2c 70 10 80       	push   $0x8010702c
80105f6a:	e8 d9 a3 ff ff       	call   80100348 <panic>
      return -1;
80105f6f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105f74:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105f77:	5b                   	pop    %ebx
80105f78:	5e                   	pop    %esi
80105f79:	5f                   	pop    %edi
80105f7a:	5d                   	pop    %ebp
80105f7b:	c3                   	ret    
  return 0;
80105f7c:	b8 00 00 00 00       	mov    $0x0,%eax
80105f81:	eb f1                	jmp    80105f74 <mappages+0x67>

80105f83 <seginit>:
{
80105f83:	55                   	push   %ebp
80105f84:	89 e5                	mov    %esp,%ebp
80105f86:	53                   	push   %ebx
80105f87:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105f8a:	e8 fc d4 ff ff       	call   8010348b <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105f8f:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105f95:	66 c7 80 58 3b 13 80 	movw   $0xffff,-0x7fecc4a8(%eax)
80105f9c:	ff ff 
80105f9e:	66 c7 80 5a 3b 13 80 	movw   $0x0,-0x7fecc4a6(%eax)
80105fa5:	00 00 
80105fa7:	c6 80 5c 3b 13 80 00 	movb   $0x0,-0x7fecc4a4(%eax)
80105fae:	0f b6 88 5d 3b 13 80 	movzbl -0x7fecc4a3(%eax),%ecx
80105fb5:	83 e1 f0             	and    $0xfffffff0,%ecx
80105fb8:	83 c9 1a             	or     $0x1a,%ecx
80105fbb:	83 e1 9f             	and    $0xffffff9f,%ecx
80105fbe:	83 c9 80             	or     $0xffffff80,%ecx
80105fc1:	88 88 5d 3b 13 80    	mov    %cl,-0x7fecc4a3(%eax)
80105fc7:	0f b6 88 5e 3b 13 80 	movzbl -0x7fecc4a2(%eax),%ecx
80105fce:	83 c9 0f             	or     $0xf,%ecx
80105fd1:	83 e1 cf             	and    $0xffffffcf,%ecx
80105fd4:	83 c9 c0             	or     $0xffffffc0,%ecx
80105fd7:	88 88 5e 3b 13 80    	mov    %cl,-0x7fecc4a2(%eax)
80105fdd:	c6 80 5f 3b 13 80 00 	movb   $0x0,-0x7fecc4a1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105fe4:	66 c7 80 60 3b 13 80 	movw   $0xffff,-0x7fecc4a0(%eax)
80105feb:	ff ff 
80105fed:	66 c7 80 62 3b 13 80 	movw   $0x0,-0x7fecc49e(%eax)
80105ff4:	00 00 
80105ff6:	c6 80 64 3b 13 80 00 	movb   $0x0,-0x7fecc49c(%eax)
80105ffd:	0f b6 88 65 3b 13 80 	movzbl -0x7fecc49b(%eax),%ecx
80106004:	83 e1 f0             	and    $0xfffffff0,%ecx
80106007:	83 c9 12             	or     $0x12,%ecx
8010600a:	83 e1 9f             	and    $0xffffff9f,%ecx
8010600d:	83 c9 80             	or     $0xffffff80,%ecx
80106010:	88 88 65 3b 13 80    	mov    %cl,-0x7fecc49b(%eax)
80106016:	0f b6 88 66 3b 13 80 	movzbl -0x7fecc49a(%eax),%ecx
8010601d:	83 c9 0f             	or     $0xf,%ecx
80106020:	83 e1 cf             	and    $0xffffffcf,%ecx
80106023:	83 c9 c0             	or     $0xffffffc0,%ecx
80106026:	88 88 66 3b 13 80    	mov    %cl,-0x7fecc49a(%eax)
8010602c:	c6 80 67 3b 13 80 00 	movb   $0x0,-0x7fecc499(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80106033:	66 c7 80 68 3b 13 80 	movw   $0xffff,-0x7fecc498(%eax)
8010603a:	ff ff 
8010603c:	66 c7 80 6a 3b 13 80 	movw   $0x0,-0x7fecc496(%eax)
80106043:	00 00 
80106045:	c6 80 6c 3b 13 80 00 	movb   $0x0,-0x7fecc494(%eax)
8010604c:	c6 80 6d 3b 13 80 fa 	movb   $0xfa,-0x7fecc493(%eax)
80106053:	0f b6 88 6e 3b 13 80 	movzbl -0x7fecc492(%eax),%ecx
8010605a:	83 c9 0f             	or     $0xf,%ecx
8010605d:	83 e1 cf             	and    $0xffffffcf,%ecx
80106060:	83 c9 c0             	or     $0xffffffc0,%ecx
80106063:	88 88 6e 3b 13 80    	mov    %cl,-0x7fecc492(%eax)
80106069:	c6 80 6f 3b 13 80 00 	movb   $0x0,-0x7fecc491(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80106070:	66 c7 80 70 3b 13 80 	movw   $0xffff,-0x7fecc490(%eax)
80106077:	ff ff 
80106079:	66 c7 80 72 3b 13 80 	movw   $0x0,-0x7fecc48e(%eax)
80106080:	00 00 
80106082:	c6 80 74 3b 13 80 00 	movb   $0x0,-0x7fecc48c(%eax)
80106089:	c6 80 75 3b 13 80 f2 	movb   $0xf2,-0x7fecc48b(%eax)
80106090:	0f b6 88 76 3b 13 80 	movzbl -0x7fecc48a(%eax),%ecx
80106097:	83 c9 0f             	or     $0xf,%ecx
8010609a:	83 e1 cf             	and    $0xffffffcf,%ecx
8010609d:	83 c9 c0             	or     $0xffffffc0,%ecx
801060a0:	88 88 76 3b 13 80    	mov    %cl,-0x7fecc48a(%eax)
801060a6:	c6 80 77 3b 13 80 00 	movb   $0x0,-0x7fecc489(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
801060ad:	05 50 3b 13 80       	add    $0x80133b50,%eax
  pd[0] = size-1;
801060b2:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
801060b8:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
801060bc:	c1 e8 10             	shr    $0x10,%eax
801060bf:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
801060c3:	8d 45 f2             	lea    -0xe(%ebp),%eax
801060c6:	0f 01 10             	lgdtl  (%eax)
}
801060c9:	83 c4 14             	add    $0x14,%esp
801060cc:	5b                   	pop    %ebx
801060cd:	5d                   	pop    %ebp
801060ce:	c3                   	ret    

801060cf <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
801060cf:	55                   	push   %ebp
801060d0:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
801060d2:	a1 04 68 13 80       	mov    0x80136804,%eax
801060d7:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
801060dc:	0f 22 d8             	mov    %eax,%cr3
}
801060df:	5d                   	pop    %ebp
801060e0:	c3                   	ret    

801060e1 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
801060e1:	55                   	push   %ebp
801060e2:	89 e5                	mov    %esp,%ebp
801060e4:	57                   	push   %edi
801060e5:	56                   	push   %esi
801060e6:	53                   	push   %ebx
801060e7:	83 ec 1c             	sub    $0x1c,%esp
801060ea:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
801060ed:	85 f6                	test   %esi,%esi
801060ef:	0f 84 dd 00 00 00    	je     801061d2 <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
801060f5:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
801060f9:	0f 84 e0 00 00 00    	je     801061df <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
801060ff:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
80106103:	0f 84 e3 00 00 00    	je     801061ec <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
80106109:	e8 5d dc ff ff       	call   80103d6b <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
8010610e:	e8 1c d3 ff ff       	call   8010342f <mycpu>
80106113:	89 c3                	mov    %eax,%ebx
80106115:	e8 15 d3 ff ff       	call   8010342f <mycpu>
8010611a:	8d 78 08             	lea    0x8(%eax),%edi
8010611d:	e8 0d d3 ff ff       	call   8010342f <mycpu>
80106122:	83 c0 08             	add    $0x8,%eax
80106125:	c1 e8 10             	shr    $0x10,%eax
80106128:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010612b:	e8 ff d2 ff ff       	call   8010342f <mycpu>
80106130:	83 c0 08             	add    $0x8,%eax
80106133:	c1 e8 18             	shr    $0x18,%eax
80106136:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
8010613d:	67 00 
8010613f:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80106146:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
8010614a:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80106150:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80106157:	83 e2 f0             	and    $0xfffffff0,%edx
8010615a:	83 ca 19             	or     $0x19,%edx
8010615d:	83 e2 9f             	and    $0xffffff9f,%edx
80106160:	83 ca 80             	or     $0xffffff80,%edx
80106163:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80106169:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
80106170:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80106176:	e8 b4 d2 ff ff       	call   8010342f <mycpu>
8010617b:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80106182:	83 e2 ef             	and    $0xffffffef,%edx
80106185:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
8010618b:	e8 9f d2 ff ff       	call   8010342f <mycpu>
80106190:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80106196:	8b 5e 08             	mov    0x8(%esi),%ebx
80106199:	e8 91 d2 ff ff       	call   8010342f <mycpu>
8010619e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801061a4:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
801061a7:	e8 83 d2 ff ff       	call   8010342f <mycpu>
801061ac:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
801061b2:	b8 28 00 00 00       	mov    $0x28,%eax
801061b7:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
801061ba:	8b 46 04             	mov    0x4(%esi),%eax
801061bd:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
801061c2:	0f 22 d8             	mov    %eax,%cr3
  popcli();
801061c5:	e8 de db ff ff       	call   80103da8 <popcli>
}
801061ca:	8d 65 f4             	lea    -0xc(%ebp),%esp
801061cd:	5b                   	pop    %ebx
801061ce:	5e                   	pop    %esi
801061cf:	5f                   	pop    %edi
801061d0:	5d                   	pop    %ebp
801061d1:	c3                   	ret    
    panic("switchuvm: no process");
801061d2:	83 ec 0c             	sub    $0xc,%esp
801061d5:	68 32 70 10 80       	push   $0x80107032
801061da:	e8 69 a1 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
801061df:	83 ec 0c             	sub    $0xc,%esp
801061e2:	68 48 70 10 80       	push   $0x80107048
801061e7:	e8 5c a1 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
801061ec:	83 ec 0c             	sub    $0xc,%esp
801061ef:	68 5d 70 10 80       	push   $0x8010705d
801061f4:	e8 4f a1 ff ff       	call   80100348 <panic>

801061f9 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801061f9:	55                   	push   %ebp
801061fa:	89 e5                	mov    %esp,%ebp
801061fc:	56                   	push   %esi
801061fd:	53                   	push   %ebx
801061fe:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
80106201:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106207:	77 4c                	ja     80106255 <inituvm+0x5c>
    panic("inituvm: more than a page");
  mem = kalloc();
80106209:	e8 46 c0 ff ff       	call   80102254 <kalloc>
8010620e:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
80106210:	83 ec 04             	sub    $0x4,%esp
80106213:	68 00 10 00 00       	push   $0x1000
80106218:	6a 00                	push   $0x0
8010621a:	50                   	push   %eax
8010621b:	e8 d4 dc ff ff       	call   80103ef4 <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
80106220:	83 c4 08             	add    $0x8,%esp
80106223:	6a 06                	push   $0x6
80106225:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
8010622b:	50                   	push   %eax
8010622c:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106231:	ba 00 00 00 00       	mov    $0x0,%edx
80106236:	8b 45 08             	mov    0x8(%ebp),%eax
80106239:	e8 cf fc ff ff       	call   80105f0d <mappages>
  memmove(mem, init, sz);
8010623e:	83 c4 0c             	add    $0xc,%esp
80106241:	56                   	push   %esi
80106242:	ff 75 0c             	pushl  0xc(%ebp)
80106245:	53                   	push   %ebx
80106246:	e8 24 dd ff ff       	call   80103f6f <memmove>
}
8010624b:	83 c4 10             	add    $0x10,%esp
8010624e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106251:	5b                   	pop    %ebx
80106252:	5e                   	pop    %esi
80106253:	5d                   	pop    %ebp
80106254:	c3                   	ret    
    panic("inituvm: more than a page");
80106255:	83 ec 0c             	sub    $0xc,%esp
80106258:	68 71 70 10 80       	push   $0x80107071
8010625d:	e8 e6 a0 ff ff       	call   80100348 <panic>

80106262 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80106262:	55                   	push   %ebp
80106263:	89 e5                	mov    %esp,%ebp
80106265:	57                   	push   %edi
80106266:	56                   	push   %esi
80106267:	53                   	push   %ebx
80106268:	83 ec 0c             	sub    $0xc,%esp
8010626b:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
8010626e:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
80106275:	75 07                	jne    8010627e <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80106277:	bb 00 00 00 00       	mov    $0x0,%ebx
8010627c:	eb 3c                	jmp    801062ba <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
8010627e:	83 ec 0c             	sub    $0xc,%esp
80106281:	68 2c 71 10 80       	push   $0x8010712c
80106286:	e8 bd a0 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
8010628b:	83 ec 0c             	sub    $0xc,%esp
8010628e:	68 8b 70 10 80       	push   $0x8010708b
80106293:	e8 b0 a0 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
80106298:	05 00 00 00 80       	add    $0x80000000,%eax
8010629d:	56                   	push   %esi
8010629e:	89 da                	mov    %ebx,%edx
801062a0:	03 55 14             	add    0x14(%ebp),%edx
801062a3:	52                   	push   %edx
801062a4:	50                   	push   %eax
801062a5:	ff 75 10             	pushl  0x10(%ebp)
801062a8:	e8 d2 b4 ff ff       	call   8010177f <readi>
801062ad:	83 c4 10             	add    $0x10,%esp
801062b0:	39 f0                	cmp    %esi,%eax
801062b2:	75 47                	jne    801062fb <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
801062b4:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801062ba:	39 fb                	cmp    %edi,%ebx
801062bc:	73 30                	jae    801062ee <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801062be:	89 da                	mov    %ebx,%edx
801062c0:	03 55 0c             	add    0xc(%ebp),%edx
801062c3:	b9 00 00 00 00       	mov    $0x0,%ecx
801062c8:	8b 45 08             	mov    0x8(%ebp),%eax
801062cb:	e8 cd fb ff ff       	call   80105e9d <walkpgdir>
801062d0:	85 c0                	test   %eax,%eax
801062d2:	74 b7                	je     8010628b <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
801062d4:	8b 00                	mov    (%eax),%eax
801062d6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
801062db:	89 fe                	mov    %edi,%esi
801062dd:	29 de                	sub    %ebx,%esi
801062df:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801062e5:	76 b1                	jbe    80106298 <loaduvm+0x36>
      n = PGSIZE;
801062e7:	be 00 10 00 00       	mov    $0x1000,%esi
801062ec:	eb aa                	jmp    80106298 <loaduvm+0x36>
      return -1;
  }
  return 0;
801062ee:	b8 00 00 00 00       	mov    $0x0,%eax
}
801062f3:	8d 65 f4             	lea    -0xc(%ebp),%esp
801062f6:	5b                   	pop    %ebx
801062f7:	5e                   	pop    %esi
801062f8:	5f                   	pop    %edi
801062f9:	5d                   	pop    %ebp
801062fa:	c3                   	ret    
      return -1;
801062fb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106300:	eb f1                	jmp    801062f3 <loaduvm+0x91>

80106302 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80106302:	55                   	push   %ebp
80106303:	89 e5                	mov    %esp,%ebp
80106305:	57                   	push   %edi
80106306:	56                   	push   %esi
80106307:	53                   	push   %ebx
80106308:	83 ec 0c             	sub    $0xc,%esp
8010630b:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
8010630e:	39 7d 10             	cmp    %edi,0x10(%ebp)
80106311:	73 11                	jae    80106324 <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
80106313:	8b 45 10             	mov    0x10(%ebp),%eax
80106316:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
8010631c:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106322:	eb 19                	jmp    8010633d <deallocuvm+0x3b>
    return oldsz;
80106324:	89 f8                	mov    %edi,%eax
80106326:	eb 64                	jmp    8010638c <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
80106328:	c1 eb 16             	shr    $0x16,%ebx
8010632b:	83 c3 01             	add    $0x1,%ebx
8010632e:	c1 e3 16             	shl    $0x16,%ebx
80106331:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106337:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010633d:	39 fb                	cmp    %edi,%ebx
8010633f:	73 48                	jae    80106389 <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
80106341:	b9 00 00 00 00       	mov    $0x0,%ecx
80106346:	89 da                	mov    %ebx,%edx
80106348:	8b 45 08             	mov    0x8(%ebp),%eax
8010634b:	e8 4d fb ff ff       	call   80105e9d <walkpgdir>
80106350:	89 c6                	mov    %eax,%esi
    if(!pte)
80106352:	85 c0                	test   %eax,%eax
80106354:	74 d2                	je     80106328 <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
80106356:	8b 00                	mov    (%eax),%eax
80106358:	a8 01                	test   $0x1,%al
8010635a:	74 db                	je     80106337 <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
8010635c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106361:	74 19                	je     8010637c <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
80106363:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106368:	83 ec 0c             	sub    $0xc,%esp
8010636b:	50                   	push   %eax
8010636c:	e8 13 bd ff ff       	call   80102084 <kfree>
      *pte = 0;
80106371:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80106377:	83 c4 10             	add    $0x10,%esp
8010637a:	eb bb                	jmp    80106337 <deallocuvm+0x35>
        panic("kfree");
8010637c:	83 ec 0c             	sub    $0xc,%esp
8010637f:	68 c6 69 10 80       	push   $0x801069c6
80106384:	e8 bf 9f ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
80106389:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010638c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010638f:	5b                   	pop    %ebx
80106390:	5e                   	pop    %esi
80106391:	5f                   	pop    %edi
80106392:	5d                   	pop    %ebp
80106393:	c3                   	ret    

80106394 <allocuvm>:
{
80106394:	55                   	push   %ebp
80106395:	89 e5                	mov    %esp,%ebp
80106397:	57                   	push   %edi
80106398:	56                   	push   %esi
80106399:	53                   	push   %ebx
8010639a:	83 ec 1c             	sub    $0x1c,%esp
8010639d:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
801063a0:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801063a3:	85 ff                	test   %edi,%edi
801063a5:	0f 88 ca 00 00 00    	js     80106475 <allocuvm+0xe1>
  if(newsz < oldsz)
801063ab:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801063ae:	72 65                	jb     80106415 <allocuvm+0x81>
  a = PGROUNDUP(oldsz);
801063b0:	8b 45 0c             	mov    0xc(%ebp),%eax
801063b3:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801063b9:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
801063bf:	39 fb                	cmp    %edi,%ebx
801063c1:	0f 83 b5 00 00 00    	jae    8010647c <allocuvm+0xe8>
    mem = kalloc2(pid);
801063c7:	83 ec 0c             	sub    $0xc,%esp
801063ca:	ff 75 14             	pushl  0x14(%ebp)
801063cd:	e8 ee be ff ff       	call   801022c0 <kalloc2>
801063d2:	89 c6                	mov    %eax,%esi
    if(mem == 0){
801063d4:	83 c4 10             	add    $0x10,%esp
801063d7:	85 c0                	test   %eax,%eax
801063d9:	74 42                	je     8010641d <allocuvm+0x89>
    memset(mem, 0, PGSIZE);
801063db:	83 ec 04             	sub    $0x4,%esp
801063de:	68 00 10 00 00       	push   $0x1000
801063e3:	6a 00                	push   $0x0
801063e5:	50                   	push   %eax
801063e6:	e8 09 db ff ff       	call   80103ef4 <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
801063eb:	83 c4 08             	add    $0x8,%esp
801063ee:	6a 06                	push   $0x6
801063f0:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
801063f6:	50                   	push   %eax
801063f7:	b9 00 10 00 00       	mov    $0x1000,%ecx
801063fc:	89 da                	mov    %ebx,%edx
801063fe:	8b 45 08             	mov    0x8(%ebp),%eax
80106401:	e8 07 fb ff ff       	call   80105f0d <mappages>
80106406:	83 c4 10             	add    $0x10,%esp
80106409:	85 c0                	test   %eax,%eax
8010640b:	78 38                	js     80106445 <allocuvm+0xb1>
  for(; a < newsz; a += PGSIZE){
8010640d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106413:	eb aa                	jmp    801063bf <allocuvm+0x2b>
    return oldsz;
80106415:	8b 45 0c             	mov    0xc(%ebp),%eax
80106418:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010641b:	eb 5f                	jmp    8010647c <allocuvm+0xe8>
      cprintf("allocuvm out of memory\n");
8010641d:	83 ec 0c             	sub    $0xc,%esp
80106420:	68 a9 70 10 80       	push   $0x801070a9
80106425:	e8 e1 a1 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010642a:	83 c4 0c             	add    $0xc,%esp
8010642d:	ff 75 0c             	pushl  0xc(%ebp)
80106430:	57                   	push   %edi
80106431:	ff 75 08             	pushl  0x8(%ebp)
80106434:	e8 c9 fe ff ff       	call   80106302 <deallocuvm>
      return 0;
80106439:	83 c4 10             	add    $0x10,%esp
8010643c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106443:	eb 37                	jmp    8010647c <allocuvm+0xe8>
      cprintf("allocuvm out of memory (2)\n");
80106445:	83 ec 0c             	sub    $0xc,%esp
80106448:	68 c1 70 10 80       	push   $0x801070c1
8010644d:	e8 b9 a1 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106452:	83 c4 0c             	add    $0xc,%esp
80106455:	ff 75 0c             	pushl  0xc(%ebp)
80106458:	57                   	push   %edi
80106459:	ff 75 08             	pushl  0x8(%ebp)
8010645c:	e8 a1 fe ff ff       	call   80106302 <deallocuvm>
      kfree(mem);
80106461:	89 34 24             	mov    %esi,(%esp)
80106464:	e8 1b bc ff ff       	call   80102084 <kfree>
      return 0;
80106469:	83 c4 10             	add    $0x10,%esp
8010646c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106473:	eb 07                	jmp    8010647c <allocuvm+0xe8>
    return 0;
80106475:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
8010647c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010647f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106482:	5b                   	pop    %ebx
80106483:	5e                   	pop    %esi
80106484:	5f                   	pop    %edi
80106485:	5d                   	pop    %ebp
80106486:	c3                   	ret    

80106487 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80106487:	55                   	push   %ebp
80106488:	89 e5                	mov    %esp,%ebp
8010648a:	56                   	push   %esi
8010648b:	53                   	push   %ebx
8010648c:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
8010648f:	85 f6                	test   %esi,%esi
80106491:	74 1a                	je     801064ad <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
80106493:	83 ec 04             	sub    $0x4,%esp
80106496:	6a 00                	push   $0x0
80106498:	68 00 00 00 80       	push   $0x80000000
8010649d:	56                   	push   %esi
8010649e:	e8 5f fe ff ff       	call   80106302 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
801064a3:	83 c4 10             	add    $0x10,%esp
801064a6:	bb 00 00 00 00       	mov    $0x0,%ebx
801064ab:	eb 10                	jmp    801064bd <freevm+0x36>
    panic("freevm: no pgdir");
801064ad:	83 ec 0c             	sub    $0xc,%esp
801064b0:	68 dd 70 10 80       	push   $0x801070dd
801064b5:	e8 8e 9e ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
801064ba:	83 c3 01             	add    $0x1,%ebx
801064bd:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
801064c3:	77 1f                	ja     801064e4 <freevm+0x5d>
    if(pgdir[i] & PTE_P){
801064c5:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
801064c8:	a8 01                	test   $0x1,%al
801064ca:	74 ee                	je     801064ba <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
801064cc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801064d1:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801064d6:	83 ec 0c             	sub    $0xc,%esp
801064d9:	50                   	push   %eax
801064da:	e8 a5 bb ff ff       	call   80102084 <kfree>
801064df:	83 c4 10             	add    $0x10,%esp
801064e2:	eb d6                	jmp    801064ba <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
801064e4:	83 ec 0c             	sub    $0xc,%esp
801064e7:	56                   	push   %esi
801064e8:	e8 97 bb ff ff       	call   80102084 <kfree>
}
801064ed:	83 c4 10             	add    $0x10,%esp
801064f0:	8d 65 f8             	lea    -0x8(%ebp),%esp
801064f3:	5b                   	pop    %ebx
801064f4:	5e                   	pop    %esi
801064f5:	5d                   	pop    %ebp
801064f6:	c3                   	ret    

801064f7 <setupkvm>:
{
801064f7:	55                   	push   %ebp
801064f8:	89 e5                	mov    %esp,%ebp
801064fa:	56                   	push   %esi
801064fb:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc()) == 0)
801064fc:	e8 53 bd ff ff       	call   80102254 <kalloc>
80106501:	89 c6                	mov    %eax,%esi
80106503:	85 c0                	test   %eax,%eax
80106505:	74 55                	je     8010655c <setupkvm+0x65>
  memset(pgdir, 0, PGSIZE);
80106507:	83 ec 04             	sub    $0x4,%esp
8010650a:	68 00 10 00 00       	push   $0x1000
8010650f:	6a 00                	push   $0x0
80106511:	50                   	push   %eax
80106512:	e8 dd d9 ff ff       	call   80103ef4 <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106517:	83 c4 10             	add    $0x10,%esp
8010651a:	bb 20 a4 10 80       	mov    $0x8010a420,%ebx
8010651f:	81 fb 60 a4 10 80    	cmp    $0x8010a460,%ebx
80106525:	73 35                	jae    8010655c <setupkvm+0x65>
                (uint)k->phys_start, k->perm) < 0) {
80106527:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
8010652a:	8b 4b 08             	mov    0x8(%ebx),%ecx
8010652d:	29 c1                	sub    %eax,%ecx
8010652f:	83 ec 08             	sub    $0x8,%esp
80106532:	ff 73 0c             	pushl  0xc(%ebx)
80106535:	50                   	push   %eax
80106536:	8b 13                	mov    (%ebx),%edx
80106538:	89 f0                	mov    %esi,%eax
8010653a:	e8 ce f9 ff ff       	call   80105f0d <mappages>
8010653f:	83 c4 10             	add    $0x10,%esp
80106542:	85 c0                	test   %eax,%eax
80106544:	78 05                	js     8010654b <setupkvm+0x54>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106546:	83 c3 10             	add    $0x10,%ebx
80106549:	eb d4                	jmp    8010651f <setupkvm+0x28>
      freevm(pgdir);
8010654b:	83 ec 0c             	sub    $0xc,%esp
8010654e:	56                   	push   %esi
8010654f:	e8 33 ff ff ff       	call   80106487 <freevm>
      return 0;
80106554:	83 c4 10             	add    $0x10,%esp
80106557:	be 00 00 00 00       	mov    $0x0,%esi
}
8010655c:	89 f0                	mov    %esi,%eax
8010655e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106561:	5b                   	pop    %ebx
80106562:	5e                   	pop    %esi
80106563:	5d                   	pop    %ebp
80106564:	c3                   	ret    

80106565 <kvmalloc>:
{
80106565:	55                   	push   %ebp
80106566:	89 e5                	mov    %esp,%ebp
80106568:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
8010656b:	e8 87 ff ff ff       	call   801064f7 <setupkvm>
80106570:	a3 04 68 13 80       	mov    %eax,0x80136804
  switchkvm();
80106575:	e8 55 fb ff ff       	call   801060cf <switchkvm>
}
8010657a:	c9                   	leave  
8010657b:	c3                   	ret    

8010657c <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
8010657c:	55                   	push   %ebp
8010657d:	89 e5                	mov    %esp,%ebp
8010657f:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106582:	b9 00 00 00 00       	mov    $0x0,%ecx
80106587:	8b 55 0c             	mov    0xc(%ebp),%edx
8010658a:	8b 45 08             	mov    0x8(%ebp),%eax
8010658d:	e8 0b f9 ff ff       	call   80105e9d <walkpgdir>
  if(pte == 0)
80106592:	85 c0                	test   %eax,%eax
80106594:	74 05                	je     8010659b <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
80106596:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
80106599:	c9                   	leave  
8010659a:	c3                   	ret    
    panic("clearpteu");
8010659b:	83 ec 0c             	sub    $0xc,%esp
8010659e:	68 ee 70 10 80       	push   $0x801070ee
801065a3:	e8 a0 9d ff ff       	call   80100348 <panic>

801065a8 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz, int pid)
{
801065a8:	55                   	push   %ebp
801065a9:	89 e5                	mov    %esp,%ebp
801065ab:	57                   	push   %edi
801065ac:	56                   	push   %esi
801065ad:	53                   	push   %ebx
801065ae:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
801065b1:	e8 41 ff ff ff       	call   801064f7 <setupkvm>
801065b6:	89 45 dc             	mov    %eax,-0x24(%ebp)
801065b9:	85 c0                	test   %eax,%eax
801065bb:	0f 84 d1 00 00 00    	je     80106692 <copyuvm+0xea>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801065c1:	bf 00 00 00 00       	mov    $0x0,%edi
801065c6:	89 fe                	mov    %edi,%esi
801065c8:	3b 75 0c             	cmp    0xc(%ebp),%esi
801065cb:	0f 83 c1 00 00 00    	jae    80106692 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801065d1:	89 75 e4             	mov    %esi,-0x1c(%ebp)
801065d4:	b9 00 00 00 00       	mov    $0x0,%ecx
801065d9:	89 f2                	mov    %esi,%edx
801065db:	8b 45 08             	mov    0x8(%ebp),%eax
801065de:	e8 ba f8 ff ff       	call   80105e9d <walkpgdir>
801065e3:	85 c0                	test   %eax,%eax
801065e5:	74 70                	je     80106657 <copyuvm+0xaf>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
801065e7:	8b 18                	mov    (%eax),%ebx
801065e9:	f6 c3 01             	test   $0x1,%bl
801065ec:	74 76                	je     80106664 <copyuvm+0xbc>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
801065ee:	89 df                	mov    %ebx,%edi
801065f0:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
    flags = PTE_FLAGS(*pte);
801065f6:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
801065fc:	89 5d e0             	mov    %ebx,-0x20(%ebp)
    if((mem = kalloc2(pid)) == 0)
801065ff:	83 ec 0c             	sub    $0xc,%esp
80106602:	ff 75 10             	pushl  0x10(%ebp)
80106605:	e8 b6 bc ff ff       	call   801022c0 <kalloc2>
8010660a:	89 c3                	mov    %eax,%ebx
8010660c:	83 c4 10             	add    $0x10,%esp
8010660f:	85 c0                	test   %eax,%eax
80106611:	74 6a                	je     8010667d <copyuvm+0xd5>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
80106613:	81 c7 00 00 00 80    	add    $0x80000000,%edi
80106619:	83 ec 04             	sub    $0x4,%esp
8010661c:	68 00 10 00 00       	push   $0x1000
80106621:	57                   	push   %edi
80106622:	50                   	push   %eax
80106623:	e8 47 d9 ff ff       	call   80103f6f <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
80106628:	83 c4 08             	add    $0x8,%esp
8010662b:	ff 75 e0             	pushl  -0x20(%ebp)
8010662e:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106634:	50                   	push   %eax
80106635:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010663a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010663d:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106640:	e8 c8 f8 ff ff       	call   80105f0d <mappages>
80106645:	83 c4 10             	add    $0x10,%esp
80106648:	85 c0                	test   %eax,%eax
8010664a:	78 25                	js     80106671 <copyuvm+0xc9>
  for(i = 0; i < sz; i += PGSIZE){
8010664c:	81 c6 00 10 00 00    	add    $0x1000,%esi
80106652:	e9 71 ff ff ff       	jmp    801065c8 <copyuvm+0x20>
      panic("copyuvm: pte should exist");
80106657:	83 ec 0c             	sub    $0xc,%esp
8010665a:	68 f8 70 10 80       	push   $0x801070f8
8010665f:	e8 e4 9c ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
80106664:	83 ec 0c             	sub    $0xc,%esp
80106667:	68 12 71 10 80       	push   $0x80107112
8010666c:	e8 d7 9c ff ff       	call   80100348 <panic>
      kfree(mem);
80106671:	83 ec 0c             	sub    $0xc,%esp
80106674:	53                   	push   %ebx
80106675:	e8 0a ba ff ff       	call   80102084 <kfree>
      goto bad;
8010667a:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
8010667d:	83 ec 0c             	sub    $0xc,%esp
80106680:	ff 75 dc             	pushl  -0x24(%ebp)
80106683:	e8 ff fd ff ff       	call   80106487 <freevm>
  return 0;
80106688:	83 c4 10             	add    $0x10,%esp
8010668b:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
80106692:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106695:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106698:	5b                   	pop    %ebx
80106699:	5e                   	pop    %esi
8010669a:	5f                   	pop    %edi
8010669b:	5d                   	pop    %ebp
8010669c:	c3                   	ret    

8010669d <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
8010669d:	55                   	push   %ebp
8010669e:	89 e5                	mov    %esp,%ebp
801066a0:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801066a3:	b9 00 00 00 00       	mov    $0x0,%ecx
801066a8:	8b 55 0c             	mov    0xc(%ebp),%edx
801066ab:	8b 45 08             	mov    0x8(%ebp),%eax
801066ae:	e8 ea f7 ff ff       	call   80105e9d <walkpgdir>
  if((*pte & PTE_P) == 0)
801066b3:	8b 00                	mov    (%eax),%eax
801066b5:	a8 01                	test   $0x1,%al
801066b7:	74 10                	je     801066c9 <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
801066b9:	a8 04                	test   $0x4,%al
801066bb:	74 13                	je     801066d0 <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
801066bd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801066c2:	05 00 00 00 80       	add    $0x80000000,%eax
}
801066c7:	c9                   	leave  
801066c8:	c3                   	ret    
    return 0;
801066c9:	b8 00 00 00 00       	mov    $0x0,%eax
801066ce:	eb f7                	jmp    801066c7 <uva2ka+0x2a>
    return 0;
801066d0:	b8 00 00 00 00       	mov    $0x0,%eax
801066d5:	eb f0                	jmp    801066c7 <uva2ka+0x2a>

801066d7 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801066d7:	55                   	push   %ebp
801066d8:	89 e5                	mov    %esp,%ebp
801066da:	57                   	push   %edi
801066db:	56                   	push   %esi
801066dc:	53                   	push   %ebx
801066dd:	83 ec 0c             	sub    $0xc,%esp
801066e0:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801066e3:	eb 25                	jmp    8010670a <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
801066e5:	8b 55 0c             	mov    0xc(%ebp),%edx
801066e8:	29 f2                	sub    %esi,%edx
801066ea:	01 d0                	add    %edx,%eax
801066ec:	83 ec 04             	sub    $0x4,%esp
801066ef:	53                   	push   %ebx
801066f0:	ff 75 10             	pushl  0x10(%ebp)
801066f3:	50                   	push   %eax
801066f4:	e8 76 d8 ff ff       	call   80103f6f <memmove>
    len -= n;
801066f9:	29 df                	sub    %ebx,%edi
    buf += n;
801066fb:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
801066fe:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
80106704:	89 45 0c             	mov    %eax,0xc(%ebp)
80106707:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
8010670a:	85 ff                	test   %edi,%edi
8010670c:	74 2f                	je     8010673d <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
8010670e:	8b 75 0c             	mov    0xc(%ebp),%esi
80106711:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
80106717:	83 ec 08             	sub    $0x8,%esp
8010671a:	56                   	push   %esi
8010671b:	ff 75 08             	pushl  0x8(%ebp)
8010671e:	e8 7a ff ff ff       	call   8010669d <uva2ka>
    if(pa0 == 0)
80106723:	83 c4 10             	add    $0x10,%esp
80106726:	85 c0                	test   %eax,%eax
80106728:	74 20                	je     8010674a <copyout+0x73>
    n = PGSIZE - (va - va0);
8010672a:	89 f3                	mov    %esi,%ebx
8010672c:	2b 5d 0c             	sub    0xc(%ebp),%ebx
8010672f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
80106735:	39 df                	cmp    %ebx,%edi
80106737:	73 ac                	jae    801066e5 <copyout+0xe>
      n = len;
80106739:	89 fb                	mov    %edi,%ebx
8010673b:	eb a8                	jmp    801066e5 <copyout+0xe>
  }
  return 0;
8010673d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106742:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106745:	5b                   	pop    %ebx
80106746:	5e                   	pop    %esi
80106747:	5f                   	pop    %edi
80106748:	5d                   	pop    %ebp
80106749:	c3                   	ret    
      return -1;
8010674a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010674f:	eb f1                	jmp    80106742 <copyout+0x6b>
