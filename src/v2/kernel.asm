
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
8010002d:	b8 c4 2c 10 80       	mov    $0x80102cc4,%eax
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
80100046:	e8 b5 3d 00 00       	call   80103e00 <acquire>

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
8010007c:	e8 e4 3d 00 00       	call   80103e65 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 60 3b 00 00       	call   80103bec <acquiresleep>
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
801000ca:	e8 96 3d 00 00       	call   80103e65 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 12 3b 00 00       	call   80103bec <acquiresleep>
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
801000ea:	68 40 67 10 80       	push   $0x80106740
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 51 67 10 80       	push   $0x80106751
80100100:	68 e0 b5 10 80       	push   $0x8010b5e0
80100105:	e8 ba 3b 00 00       	call   80103cc4 <initlock>
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
8010013a:	68 58 67 10 80       	push   $0x80106758
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 71 3a 00 00       	call   80103bb9 <initsleeplock>
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
801001a8:	e8 c9 3a 00 00       	call   80103c76 <holdingsleep>
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
801001cb:	68 5f 67 10 80       	push   $0x8010675f
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
801001e4:	e8 8d 3a 00 00       	call   80103c76 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 42 3a 00 00       	call   80103c3b <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 e0 b5 10 80 	movl   $0x8010b5e0,(%esp)
80100200:	e8 fb 3b 00 00       	call   80103e00 <acquire>
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
8010024c:	e8 14 3c 00 00       	call   80103e65 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 66 67 10 80       	push   $0x80106766
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
8010028a:	e8 71 3b 00 00       	call   80103e00 <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 c0 ff 10 80       	mov    0x8010ffc0,%eax
8010029f:	3b 05 c4 ff 10 80    	cmp    0x8010ffc4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 b2 31 00 00       	call   8010345e <myproc>
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
801002bf:	e8 41 36 00 00       	call   80103905 <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 a5 10 80       	push   $0x8010a520
801002d1:	e8 8f 3b 00 00       	call   80103e65 <release>
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
80100331:	e8 2f 3b 00 00       	call   80103e65 <release>
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
8010035a:	e8 7f 22 00 00       	call   801025de <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 6d 67 10 80       	push   $0x8010676d
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 bb 70 10 80 	movl   $0x801070bb,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 4b 39 00 00       	call   80103cdf <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 81 67 10 80       	push   $0x80106781
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
8010049e:	68 85 67 10 80       	push   $0x80106785
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 68 3a 00 00       	call   80103f27 <memmove>
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
801004d9:	e8 ce 39 00 00       	call   80103eac <memset>
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
80100506:	e8 db 4d 00 00       	call   801052e6 <uartputc>
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
8010051f:	e8 c2 4d 00 00       	call   801052e6 <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 b6 4d 00 00       	call   801052e6 <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 aa 4d 00 00       	call   801052e6 <uartputc>
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
80100576:	0f b6 92 b0 67 10 80 	movzbl -0x7fef9850(%edx),%edx
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
801005ca:	e8 31 38 00 00       	call   80103e00 <acquire>
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
801005f1:	e8 6f 38 00 00       	call   80103e65 <release>
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
80100638:	e8 c3 37 00 00       	call   80103e00 <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 9f 67 10 80       	push   $0x8010679f
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
801006ee:	be 98 67 10 80       	mov    $0x80106798,%esi
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
80100734:	e8 2c 37 00 00       	call   80103e65 <release>
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
8010074f:	e8 ac 36 00 00       	call   80103e00 <acquire>
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
801007de:	e8 87 32 00 00       	call   80103a6a <wakeup>
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
80100873:	e8 ed 35 00 00       	call   80103e65 <release>
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
80100887:	e8 7b 32 00 00       	call   80103b07 <procdump>
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
80100894:	68 a8 67 10 80       	push   $0x801067a8
80100899:	68 20 a5 10 80       	push   $0x8010a520
8010089e:	e8 21 34 00 00       	call   80103cc4 <initlock>

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
801008de:	e8 7b 2b 00 00       	call   8010345e <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 20 21 00 00       	call   80102a0e <begin_op>

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
80100935:	e8 4e 21 00 00       	call   80102a88 <end_op>
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
8010094a:	e8 39 21 00 00       	call   80102a88 <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 c1 67 10 80       	push   $0x801067c1
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
80100972:	e8 4a 5b 00 00       	call   801064c1 <setupkvm>
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
80100a06:	e8 4e 59 00 00       	call   80106359 <allocuvm>
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
80100a38:	e8 ea 57 00 00       	call   80106227 <loaduvm>
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
80100a53:	e8 30 20 00 00       	call   80102a88 <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 e0 58 00 00       	call   80106359 <allocuvm>
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
80100a9d:	e8 af 59 00 00       	call   80106451 <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 8d 5a 00 00       	call   8010654e <clearpteu>
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
80100ae2:	e8 67 35 00 00       	call   8010404e <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 55 35 00 00       	call   8010404e <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 9e 5b 00 00       	call   801066a9 <copyout>
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
80100b66:	e8 3e 5b 00 00       	call   801066a9 <copyout>
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
80100ba3:	e8 6b 34 00 00       	call   80104013 <safestrcpy>
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
80100bd1:	e8 cb 54 00 00       	call   801060a1 <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 73 58 00 00       	call   80106451 <freevm>
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
80100c19:	68 cd 67 10 80       	push   $0x801067cd
80100c1e:	68 e0 ff 10 80       	push   $0x8010ffe0
80100c23:	e8 9c 30 00 00       	call   80103cc4 <initlock>
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
80100c39:	e8 c2 31 00 00       	call   80103e00 <acquire>
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
80100c68:	e8 f8 31 00 00       	call   80103e65 <release>
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
80100c7f:	e8 e1 31 00 00       	call   80103e65 <release>
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
80100c9d:	e8 5e 31 00 00       	call   80103e00 <acquire>
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
80100cba:	e8 a6 31 00 00       	call   80103e65 <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 d4 67 10 80       	push   $0x801067d4
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
80100ce2:	e8 19 31 00 00       	call   80103e00 <acquire>
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
80100d03:	e8 5d 31 00 00       	call   80103e65 <release>
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
80100d13:	68 dc 67 10 80       	push   $0x801067dc
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
80100d49:	e8 17 31 00 00       	call   80103e65 <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 ab 1c 00 00       	call   80102a0e <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 15 1d 00 00       	call   80102a88 <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 02 23 00 00       	call   8010308a <pipeclose>
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
80100e3c:	e8 a1 23 00 00       	call   801031e2 <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 e6 67 10 80       	push   $0x801067e6
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
80100e95:	e8 7c 22 00 00       	call   80103116 <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 67 1b 00 00       	call   80102a0e <begin_op>
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
80100edd:	e8 a6 1b 00 00       	call   80102a88 <end_op>

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
80100f10:	68 ef 67 10 80       	push   $0x801067ef
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
80100f2d:	68 f5 67 10 80       	push   $0x801067f5
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
80100f8a:	e8 98 2f 00 00       	call   80103f27 <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 88 2f 00 00       	call   80103f27 <memmove>
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
80100fdf:	e8 c8 2e 00 00       	call   80103eac <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 4b 1b 00 00       	call   80102b37 <log_write>
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
801010a3:	68 ff 67 10 80       	push   $0x801067ff
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
801010bf:	e8 73 1a 00 00       	call   80102b37 <log_write>
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
80101170:	e8 c2 19 00 00       	call   80102b37 <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 15 68 10 80       	push   $0x80106815
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
8010119a:	e8 61 2c 00 00       	call   80103e00 <acquire>
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
801011e1:	e8 7f 2c 00 00       	call   80103e65 <release>
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
80101217:	e8 49 2c 00 00       	call   80103e65 <release>
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
8010122c:	68 28 68 10 80       	push   $0x80106828
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
80101255:	e8 cd 2c 00 00       	call   80103f27 <memmove>
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
801012c8:	e8 6a 18 00 00       	call   80102b37 <log_write>
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
801012e2:	68 38 68 10 80       	push   $0x80106838
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 4b 68 10 80       	push   $0x8010684b
801012f8:	68 00 0a 11 80       	push   $0x80110a00
801012fd:	e8 c2 29 00 00       	call   80103cc4 <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 52 68 10 80       	push   $0x80106852
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 40 0a 11 80       	add    $0x80110a40,%eax
80101321:	50                   	push   %eax
80101322:	e8 92 28 00 00       	call   80103bb9 <initsleeplock>
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
8010136c:	68 b8 68 10 80       	push   $0x801068b8
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
801013df:	68 58 68 10 80       	push   $0x80106858
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 b6 2a 00 00       	call   80103eac <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 32 17 00 00       	call   80102b37 <log_write>
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
80101480:	e8 a2 2a 00 00       	call   80103f27 <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 aa 16 00 00       	call   80102b37 <log_write>
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
80101560:	e8 9b 28 00 00       	call   80103e00 <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 00 0a 11 80 	movl   $0x80110a00,(%esp)
80101575:	e8 eb 28 00 00       	call   80103e65 <release>
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
8010159a:	e8 4d 26 00 00       	call   80103bec <acquiresleep>
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
801015b2:	68 6a 68 10 80       	push   $0x8010686a
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
80101614:	e8 0e 29 00 00       	call   80103f27 <memmove>
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
80101639:	68 70 68 10 80       	push   $0x80106870
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
80101656:	e8 1b 26 00 00       	call   80103c76 <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 ca 25 00 00       	call   80103c3b <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 7f 68 10 80       	push   $0x8010687f
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
80101698:	e8 4f 25 00 00       	call   80103bec <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 85 25 00 00       	call   80103c3b <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 00 0a 11 80 	movl   $0x80110a00,(%esp)
801016bd:	e8 3e 27 00 00       	call   80103e00 <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 00 0a 11 80 	movl   $0x80110a00,(%esp)
801016d2:	e8 8e 27 00 00       	call   80103e65 <release>
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
801016ea:	e8 11 27 00 00       	call   80103e00 <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 00 0a 11 80 	movl   $0x80110a00,(%esp)
801016f9:	e8 67 27 00 00       	call   80103e65 <release>
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
8010182a:	e8 f8 26 00 00       	call   80103f27 <memmove>
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
80101926:	e8 fc 25 00 00       	call   80103f27 <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 04 12 00 00       	call   80102b37 <log_write>
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
801019a9:	e8 e0 25 00 00       	call   80103f8e <strncmp>
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
801019d0:	68 87 68 10 80       	push   $0x80106887
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 99 68 10 80       	push   $0x80106899
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
80101a5a:	e8 ff 19 00 00       	call   8010345e <myproc>
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
80101b92:	68 a8 68 10 80       	push   $0x801068a8
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 1d 24 00 00       	call   80103fcb <strncpy>
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
80101bd7:	68 b4 6e 10 80       	push   $0x80106eb4
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
80101ccc:	68 0b 69 10 80       	push   $0x8010690b
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 14 69 10 80       	push   $0x80106914
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
80101d06:	68 26 69 10 80       	push   $0x80106926
80101d0b:	68 80 a5 10 80       	push   $0x8010a580
80101d10:	e8 af 1f 00 00       	call   80103cc4 <initlock>
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
80101d80:	e8 7b 20 00 00       	call   80103e00 <acquire>

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
80101dad:	e8 b8 1c 00 00       	call   80103a6a <wakeup>

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
80101dcb:	e8 95 20 00 00       	call   80103e65 <release>
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
80101de2:	e8 7e 20 00 00       	call   80103e65 <release>
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
80101e1a:	e8 57 1e 00 00       	call   80103c76 <holdingsleep>
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
80101e47:	e8 b4 1f 00 00       	call   80103e00 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 a5 10 80       	mov    $0x8010a564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 2a 69 10 80       	push   $0x8010692a
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 40 69 10 80       	push   $0x80106940
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 55 69 10 80       	push   $0x80106955
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
80101ea9:	e8 57 1a 00 00       	call   80103905 <sleep>
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
80101ec3:	e8 9d 1f 00 00       	call   80103e65 <release>
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
80101f3f:	68 74 69 10 80       	push   $0x80106974
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
80101fd6:	e8 d1 1e 00 00       	call   80103eac <memset>

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
80102005:	68 a6 69 10 80       	push   $0x801069a6
8010200a:	e8 39 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010200f:	83 ec 0c             	sub    $0xc,%esp
80102012:	68 60 26 11 80       	push   $0x80112660
80102017:	e8 e4 1d 00 00       	call   80103e00 <acquire>
8010201c:	83 c4 10             	add    $0x10,%esp
8010201f:	eb c6                	jmp    80101fe7 <kfree+0x43>
    release(&kmem.lock);
80102021:	83 ec 0c             	sub    $0xc,%esp
80102024:	68 60 26 11 80       	push   $0x80112660
80102029:	e8 37 1e 00 00       	call   80103e65 <release>
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
8010206f:	68 ac 69 10 80       	push   $0x801069ac
80102074:	68 60 26 11 80       	push   $0x80112660
80102079:	e8 46 1c 00 00       	call   80103cc4 <initlock>
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

uint updatePid(uint pid){
801020bb:	55                   	push   %ebp
801020bc:	89 e5                	mov    %esp,%ebp
801020be:	8b 45 08             	mov    0x8(%ebp),%eax
	return pidNum = pid;
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
801020d6:	75 66                	jne    8010213e <kalloc+0x76>
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

  // V2P and shift, and mask off
  framenumber = (uint)(V2P(r) >> 12 & 0xffff);
801020e9:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801020ef:	c1 e8 0c             	shr    $0xc,%eax
801020f2:	0f b7 c0             	movzwl %ax,%eax
801020f5:	a3 a0 26 11 80       	mov    %eax,0x801126a0

  updatePid(1);
801020fa:	83 ec 0c             	sub    $0xc,%esp
801020fd:	6a 01                	push   $0x1
801020ff:	e8 b7 ff ff ff       	call   801020bb <updatePid>

  frames[index] = framenumber;
80102104:	a1 b4 a5 10 80       	mov    0x8010a5b4,%eax
80102109:	8b 15 a0 26 11 80    	mov    0x801126a0,%edx
8010210f:	89 14 85 c0 26 11 80 	mov    %edx,-0x7feed940(,%eax,4)
  pids[index] = pidNum;
80102116:	8b 15 a4 26 11 80    	mov    0x801126a4,%edx
8010211c:	89 14 85 e0 26 12 80 	mov    %edx,-0x7fedd920(,%eax,4)
  index++;
80102123:	83 c0 01             	add    $0x1,%eax
80102126:	a3 b4 a5 10 80       	mov    %eax,0x8010a5b4

  if(kmem.use_lock) {
8010212b:	83 c4 10             	add    $0x10,%esp
8010212e:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
80102135:	75 19                	jne    80102150 <kalloc+0x88>
    release(&kmem.lock);
  }
  return (char*)r;
}
80102137:	89 d8                	mov    %ebx,%eax
80102139:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010213c:	c9                   	leave  
8010213d:	c3                   	ret    
    acquire(&kmem.lock);
8010213e:	83 ec 0c             	sub    $0xc,%esp
80102141:	68 60 26 11 80       	push   $0x80112660
80102146:	e8 b5 1c 00 00       	call   80103e00 <acquire>
8010214b:	83 c4 10             	add    $0x10,%esp
8010214e:	eb 88                	jmp    801020d8 <kalloc+0x10>
    release(&kmem.lock);
80102150:	83 ec 0c             	sub    $0xc,%esp
80102153:	68 60 26 11 80       	push   $0x80112660
80102158:	e8 08 1d 00 00       	call   80103e65 <release>
8010215d:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
80102160:	eb d5                	jmp    80102137 <kalloc+0x6f>

80102162 <kalloc2>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc2(uint pid)
{
80102162:	55                   	push   %ebp
80102163:	89 e5                	mov    %esp,%ebp
80102165:	57                   	push   %edi
80102166:	56                   	push   %esi
80102167:	53                   	push   %ebx
80102168:	83 ec 1c             	sub    $0x1c,%esp
  struct run *r;
  struct run *prev; // head of the freelist
  uint nextPid = -2;
  uint prevPid = -2;

  if(kmem.use_lock)
8010216b:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
80102172:	75 2b                	jne    8010219f <kalloc2+0x3d>
    acquire(&kmem.lock);
  r = kmem.freelist; // head which acts as a current pointer
80102174:	8b 1d 98 26 11 80    	mov    0x80112698,%ebx

  // Update global pid
  uint currPid = updatePid(pid);
8010217a:	83 ec 0c             	sub    $0xc,%esp
8010217d:	ff 75 08             	pushl  0x8(%ebp)
80102180:	e8 36 ff ff ff       	call   801020bb <updatePid>
80102185:	89 c7                	mov    %eax,%edi

  prev = r;
   // cprintf("before while: %p", r);
  while(r){
80102187:	83 c4 10             	add    $0x10,%esp
  prev = r;
8010218a:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  uint prevPid = -2;
8010218d:	b9 fe ff ff ff       	mov    $0xfffffffe,%ecx
  uint nextPid = -2;
80102192:	ba fe ff ff ff       	mov    $0xfffffffe,%edx
80102197:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  while(r){
8010219a:	e9 c5 00 00 00       	jmp    80102264 <kalloc2+0x102>
    acquire(&kmem.lock);
8010219f:	83 ec 0c             	sub    $0xc,%esp
801021a2:	68 60 26 11 80       	push   $0x80112660
801021a7:	e8 54 1c 00 00       	call   80103e00 <acquire>
801021ac:	83 c4 10             	add    $0x10,%esp
801021af:	eb c3                	jmp    80102174 <kalloc2+0x12>
    index++;

    for(int i = 0; i < 16384; i++){

      if (frames[i] == r->pfn - 1) {
        prevPid = pids[i];
801021b1:	8b 04 85 e0 26 12 80 	mov    -0x7fedd920(,%eax,4),%eax
801021b8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        // cprintf("check prev: %d\n", prevPid);
        break;
      }
    }
    // looking at 1 frame after current to check for same process
    for(int j = 0; j < 16384; j++){
801021bb:	b8 00 00 00 00       	mov    $0x0,%eax
801021c0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801021c3:	3d ff 3f 00 00       	cmp    $0x3fff,%eax
801021c8:	0f 8f fb 00 00 00    	jg     801022c9 <kalloc2+0x167>

      if(frames[j] == r->pfn + 1){
801021ce:	8b 73 04             	mov    0x4(%ebx),%esi
801021d1:	83 c6 01             	add    $0x1,%esi
801021d4:	39 34 85 c0 26 11 80 	cmp    %esi,-0x7feed940(,%eax,4)
801021db:	74 0a                	je     801021e7 <kalloc2+0x85>
    for(int j = 0; j < 16384; j++){
801021dd:	83 c0 01             	add    $0x1,%eax
801021e0:	eb e1                	jmp    801021c3 <kalloc2+0x61>
801021e2:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
801021e5:	eb d4                	jmp    801021bb <kalloc2+0x59>
801021e7:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
        nextPid = pids[j];
801021ea:	8b 14 85 e0 26 12 80 	mov    -0x7fedd920(,%eax,4),%edx
    //     break;
    //   }
    // }
    // if((prevPid == -1 && prevPid ==  currPid) || (nextPid == -1 && nextPid == currPid)){
    // cprintf("outside if: (%d, %d), (%d, %d) %d\n", pids[i], i,  pids[j], j, currPid);
    if(((prevPid != -2 && prevPid ==  currPid) && (nextPid != -2 && nextPid == currPid)) ||
801021f1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801021f4:	83 f9 fe             	cmp    $0xfffffffe,%ecx
801021f7:	0f 95 c0             	setne  %al
801021fa:	89 c6                	mov    %eax,%esi
801021fc:	39 f9                	cmp    %edi,%ecx
801021fe:	0f 94 c0             	sete   %al
80102201:	89 f1                	mov    %esi,%ecx
80102203:	20 c8                	and    %cl,%al
80102205:	88 45 e2             	mov    %al,-0x1e(%ebp)
80102208:	74 18                	je     80102222 <kalloc2+0xc0>
8010220a:	83 fa fe             	cmp    $0xfffffffe,%edx
8010220d:	0f 95 45 e3          	setne  -0x1d(%ebp)
80102211:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
80102215:	39 fa                	cmp    %edi,%edx
80102217:	0f 94 c1             	sete   %cl
8010221a:	84 c8                	test   %cl,%al
8010221c:	0f 85 af 00 00 00    	jne    801022d1 <kalloc2+0x16f>
      (prevPid == -2 && nextPid == -2) || (prevPid != -2 && currPid == prevPid && nextPid == -2) ||
80102222:	83 7d e4 fe          	cmpl   $0xfffffffe,-0x1c(%ebp)
80102226:	0f 94 c1             	sete   %cl
80102229:	89 ce                	mov    %ecx,%esi
8010222b:	83 fa fe             	cmp    $0xfffffffe,%edx
8010222e:	0f 94 45 e3          	sete   -0x1d(%ebp)
80102232:	0f b6 4d e3          	movzbl -0x1d(%ebp),%ecx
    if(((prevPid != -2 && prevPid ==  currPid) && (nextPid != -2 && nextPid == currPid)) ||
80102236:	89 f0                	mov    %esi,%eax
80102238:	84 c1                	test   %al,%cl
8010223a:	0f 85 91 00 00 00    	jne    801022d1 <kalloc2+0x16f>
      (prevPid == -2 && nextPid == -2) || (prevPid != -2 && currPid == prevPid && nextPid == -2) ||
80102240:	80 7d e2 00          	cmpb   $0x0,-0x1e(%ebp)
80102244:	74 09                	je     8010224f <kalloc2+0xed>
80102246:	83 fa fe             	cmp    $0xfffffffe,%edx
80102249:	0f 84 82 00 00 00    	je     801022d1 <kalloc2+0x16f>
      (prevPid == -2 && nextPid != -2 && currPid == nextPid)){
8010224f:	83 fa fe             	cmp    $0xfffffffe,%edx
80102252:	0f 95 c0             	setne  %al
      (prevPid == -2 && nextPid == -2) || (prevPid != -2 && currPid == prevPid && nextPid == -2) ||
80102255:	89 f1                	mov    %esi,%ecx
80102257:	84 c1                	test   %al,%cl
80102259:	74 04                	je     8010225f <kalloc2+0xfd>
      (prevPid == -2 && nextPid != -2 && currPid == nextPid)){
8010225b:	39 fa                	cmp    %edi,%edx
8010225d:	74 72                	je     801022d1 <kalloc2+0x16f>
      } else {
        prev->next = r->next;
      }
      break;
    }
    prev = r;
8010225f:	89 5d dc             	mov    %ebx,-0x24(%ebp)
    r = r->next;  
80102262:	8b 1b                	mov    (%ebx),%ebx
  while(r){
80102264:	85 db                	test   %ebx,%ebx
80102266:	74 78                	je     801022e0 <kalloc2+0x17e>
    framenumber = (uint)(V2P(r) >> 12 & 0xffff);
80102268:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
8010226e:	c1 e8 0c             	shr    $0xc,%eax
80102271:	0f b7 c0             	movzwl %ax,%eax
80102274:	a3 a0 26 11 80       	mov    %eax,0x801126a0
    r->pfn = framenumber;
80102279:	89 43 04             	mov    %eax,0x4(%ebx)
    frames[index] = framenumber;
8010227c:	8b 35 b4 a5 10 80    	mov    0x8010a5b4,%esi
80102282:	89 04 b5 c0 26 11 80 	mov    %eax,-0x7feed940(,%esi,4)
    pids[index] = pidNum;
80102289:	a1 a4 26 11 80       	mov    0x801126a4,%eax
8010228e:	89 04 b5 e0 26 12 80 	mov    %eax,-0x7fedd920(,%esi,4)
    index++;
80102295:	83 c6 01             	add    $0x1,%esi
80102298:	89 35 b4 a5 10 80    	mov    %esi,0x8010a5b4
    for(int i = 0; i < 16384; i++){
8010229e:	b8 00 00 00 00       	mov    $0x0,%eax
801022a3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801022a6:	3d ff 3f 00 00       	cmp    $0x3fff,%eax
801022ab:	0f 8f 31 ff ff ff    	jg     801021e2 <kalloc2+0x80>
      if (frames[i] == r->pfn - 1) {
801022b1:	8b 73 04             	mov    0x4(%ebx),%esi
801022b4:	83 ee 01             	sub    $0x1,%esi
801022b7:	39 34 85 c0 26 11 80 	cmp    %esi,-0x7feed940(,%eax,4)
801022be:	0f 84 ed fe ff ff    	je     801021b1 <kalloc2+0x4f>
    for(int i = 0; i < 16384; i++){
801022c4:	83 c0 01             	add    $0x1,%eax
801022c7:	eb dd                	jmp    801022a6 <kalloc2+0x144>
801022c9:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
801022cc:	e9 20 ff ff ff       	jmp    801021f1 <kalloc2+0x8f>
      if(r == kmem.freelist){
801022d1:	39 1d 98 26 11 80    	cmp    %ebx,0x80112698
801022d7:	74 1a                	je     801022f3 <kalloc2+0x191>
        prev->next = r->next;
801022d9:	8b 03                	mov    (%ebx),%eax
801022db:	8b 7d dc             	mov    -0x24(%ebp),%edi
801022de:	89 07                	mov    %eax,(%edi)
      // cprintf("after while: %d", prevPid);
  }
  //cprintf("after while: %p", prev);


  if(kmem.use_lock) {
801022e0:	83 3d 94 26 11 80 00 	cmpl   $0x0,0x80112694
801022e7:	75 13                	jne    801022fc <kalloc2+0x19a>
    release(&kmem.lock);
  }

  return (char*)r;
}
801022e9:	89 d8                	mov    %ebx,%eax
801022eb:	8d 65 f4             	lea    -0xc(%ebp),%esp
801022ee:	5b                   	pop    %ebx
801022ef:	5e                   	pop    %esi
801022f0:	5f                   	pop    %edi
801022f1:	5d                   	pop    %ebp
801022f2:	c3                   	ret    
        kmem.freelist = r->next;
801022f3:	8b 03                	mov    (%ebx),%eax
801022f5:	a3 98 26 11 80       	mov    %eax,0x80112698
801022fa:	eb e4                	jmp    801022e0 <kalloc2+0x17e>
    release(&kmem.lock);
801022fc:	83 ec 0c             	sub    $0xc,%esp
801022ff:	68 60 26 11 80       	push   $0x80112660
80102304:	e8 5c 1b 00 00       	call   80103e65 <release>
80102309:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
8010230c:	eb db                	jmp    801022e9 <kalloc2+0x187>

8010230e <dump_physmem>:

int
dump_physmem(int *frs, int *pds, int numframes)
{
8010230e:	55                   	push   %ebp
8010230f:	89 e5                	mov    %esp,%ebp
80102311:	57                   	push   %edi
80102312:	56                   	push   %esi
80102313:	53                   	push   %ebx
80102314:	8b 75 08             	mov    0x8(%ebp),%esi
80102317:	8b 7d 0c             	mov    0xc(%ebp),%edi
8010231a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  if(numframes <= 0 || frs == 0 || pds == 0)
8010231d:	85 db                	test   %ebx,%ebx
8010231f:	0f 9e c2             	setle  %dl
80102322:	85 f6                	test   %esi,%esi
80102324:	0f 94 c0             	sete   %al
80102327:	08 c2                	or     %al,%dl
80102329:	75 37                	jne    80102362 <dump_physmem+0x54>
8010232b:	85 ff                	test   %edi,%edi
8010232d:	74 3a                	je     80102369 <dump_physmem+0x5b>
    return -1;
  for (int i = 0; i < numframes; i++) {
8010232f:	b8 00 00 00 00       	mov    $0x0,%eax
80102334:	eb 1e                	jmp    80102354 <dump_physmem+0x46>
    frs[i] = frames[i];
80102336:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010233d:	8b 0c 85 c0 26 11 80 	mov    -0x7feed940(,%eax,4),%ecx
80102344:	89 0c 16             	mov    %ecx,(%esi,%edx,1)
    pds[i] = pids[i];
80102347:	8b 0c 85 e0 26 12 80 	mov    -0x7fedd920(,%eax,4),%ecx
8010234e:	89 0c 17             	mov    %ecx,(%edi,%edx,1)
  for (int i = 0; i < numframes; i++) {
80102351:	83 c0 01             	add    $0x1,%eax
80102354:	39 d8                	cmp    %ebx,%eax
80102356:	7c de                	jl     80102336 <dump_physmem+0x28>
  }
  return 0;
80102358:	b8 00 00 00 00       	mov    $0x0,%eax
8010235d:	5b                   	pop    %ebx
8010235e:	5e                   	pop    %esi
8010235f:	5f                   	pop    %edi
80102360:	5d                   	pop    %ebp
80102361:	c3                   	ret    
    return -1;
80102362:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102367:	eb f4                	jmp    8010235d <dump_physmem+0x4f>
80102369:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010236e:	eb ed                	jmp    8010235d <dump_physmem+0x4f>

80102370 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102370:	55                   	push   %ebp
80102371:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102373:	ba 64 00 00 00       	mov    $0x64,%edx
80102378:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
80102379:	a8 01                	test   $0x1,%al
8010237b:	0f 84 b5 00 00 00    	je     80102436 <kbdgetc+0xc6>
80102381:	ba 60 00 00 00       	mov    $0x60,%edx
80102386:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
80102387:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
8010238a:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
80102390:	74 5c                	je     801023ee <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
80102392:	84 c0                	test   %al,%al
80102394:	78 66                	js     801023fc <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
80102396:	8b 0d b8 a5 10 80    	mov    0x8010a5b8,%ecx
8010239c:	f6 c1 40             	test   $0x40,%cl
8010239f:	74 0f                	je     801023b0 <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
801023a1:	83 c8 80             	or     $0xffffff80,%eax
801023a4:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
801023a7:	83 e1 bf             	and    $0xffffffbf,%ecx
801023aa:	89 0d b8 a5 10 80    	mov    %ecx,0x8010a5b8
  }

  shift |= shiftcode[data];
801023b0:	0f b6 8a e0 6a 10 80 	movzbl -0x7fef9520(%edx),%ecx
801023b7:	0b 0d b8 a5 10 80    	or     0x8010a5b8,%ecx
  shift ^= togglecode[data];
801023bd:	0f b6 82 e0 69 10 80 	movzbl -0x7fef9620(%edx),%eax
801023c4:	31 c1                	xor    %eax,%ecx
801023c6:	89 0d b8 a5 10 80    	mov    %ecx,0x8010a5b8
  c = charcode[shift & (CTL | SHIFT)][data];
801023cc:	89 c8                	mov    %ecx,%eax
801023ce:	83 e0 03             	and    $0x3,%eax
801023d1:	8b 04 85 c0 69 10 80 	mov    -0x7fef9640(,%eax,4),%eax
801023d8:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
801023dc:	f6 c1 08             	test   $0x8,%cl
801023df:	74 19                	je     801023fa <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
801023e1:	8d 50 9f             	lea    -0x61(%eax),%edx
801023e4:	83 fa 19             	cmp    $0x19,%edx
801023e7:	77 40                	ja     80102429 <kbdgetc+0xb9>
      c += 'A' - 'a';
801023e9:	83 e8 20             	sub    $0x20,%eax
801023ec:	eb 0c                	jmp    801023fa <kbdgetc+0x8a>
    shift |= E0ESC;
801023ee:	83 0d b8 a5 10 80 40 	orl    $0x40,0x8010a5b8
    return 0;
801023f5:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
801023fa:	5d                   	pop    %ebp
801023fb:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
801023fc:	8b 0d b8 a5 10 80    	mov    0x8010a5b8,%ecx
80102402:	f6 c1 40             	test   $0x40,%cl
80102405:	75 05                	jne    8010240c <kbdgetc+0x9c>
80102407:	89 c2                	mov    %eax,%edx
80102409:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
8010240c:	0f b6 82 e0 6a 10 80 	movzbl -0x7fef9520(%edx),%eax
80102413:	83 c8 40             	or     $0x40,%eax
80102416:	0f b6 c0             	movzbl %al,%eax
80102419:	f7 d0                	not    %eax
8010241b:	21 c8                	and    %ecx,%eax
8010241d:	a3 b8 a5 10 80       	mov    %eax,0x8010a5b8
    return 0;
80102422:	b8 00 00 00 00       	mov    $0x0,%eax
80102427:	eb d1                	jmp    801023fa <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
80102429:	8d 50 bf             	lea    -0x41(%eax),%edx
8010242c:	83 fa 19             	cmp    $0x19,%edx
8010242f:	77 c9                	ja     801023fa <kbdgetc+0x8a>
      c += 'a' - 'A';
80102431:	83 c0 20             	add    $0x20,%eax
  return c;
80102434:	eb c4                	jmp    801023fa <kbdgetc+0x8a>
    return -1;
80102436:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010243b:	eb bd                	jmp    801023fa <kbdgetc+0x8a>

8010243d <kbdintr>:

void
kbdintr(void)
{
8010243d:	55                   	push   %ebp
8010243e:	89 e5                	mov    %esp,%ebp
80102440:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
80102443:	68 70 23 10 80       	push   $0x80102370
80102448:	e8 f1 e2 ff ff       	call   8010073e <consoleintr>
}
8010244d:	83 c4 10             	add    $0x10,%esp
80102450:	c9                   	leave  
80102451:	c3                   	ret    

80102452 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102452:	55                   	push   %ebp
80102453:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102455:	8b 0d e4 26 13 80    	mov    0x801326e4,%ecx
8010245b:	8d 04 81             	lea    (%ecx,%eax,4),%eax
8010245e:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
80102460:	a1 e4 26 13 80       	mov    0x801326e4,%eax
80102465:	8b 40 20             	mov    0x20(%eax),%eax
}
80102468:	5d                   	pop    %ebp
80102469:	c3                   	ret    

8010246a <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
8010246a:	55                   	push   %ebp
8010246b:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010246d:	ba 70 00 00 00       	mov    $0x70,%edx
80102472:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102473:	ba 71 00 00 00       	mov    $0x71,%edx
80102478:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
80102479:	0f b6 c0             	movzbl %al,%eax
}
8010247c:	5d                   	pop    %ebp
8010247d:	c3                   	ret    

8010247e <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
8010247e:	55                   	push   %ebp
8010247f:	89 e5                	mov    %esp,%ebp
80102481:	53                   	push   %ebx
80102482:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
80102484:	b8 00 00 00 00       	mov    $0x0,%eax
80102489:	e8 dc ff ff ff       	call   8010246a <cmos_read>
8010248e:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
80102490:	b8 02 00 00 00       	mov    $0x2,%eax
80102495:	e8 d0 ff ff ff       	call   8010246a <cmos_read>
8010249a:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
8010249d:	b8 04 00 00 00       	mov    $0x4,%eax
801024a2:	e8 c3 ff ff ff       	call   8010246a <cmos_read>
801024a7:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
801024aa:	b8 07 00 00 00       	mov    $0x7,%eax
801024af:	e8 b6 ff ff ff       	call   8010246a <cmos_read>
801024b4:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
801024b7:	b8 08 00 00 00       	mov    $0x8,%eax
801024bc:	e8 a9 ff ff ff       	call   8010246a <cmos_read>
801024c1:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
801024c4:	b8 09 00 00 00       	mov    $0x9,%eax
801024c9:	e8 9c ff ff ff       	call   8010246a <cmos_read>
801024ce:	89 43 14             	mov    %eax,0x14(%ebx)
}
801024d1:	5b                   	pop    %ebx
801024d2:	5d                   	pop    %ebp
801024d3:	c3                   	ret    

801024d4 <lapicinit>:
  if(!lapic)
801024d4:	83 3d e4 26 13 80 00 	cmpl   $0x0,0x801326e4
801024db:	0f 84 fb 00 00 00    	je     801025dc <lapicinit+0x108>
{
801024e1:	55                   	push   %ebp
801024e2:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801024e4:	ba 3f 01 00 00       	mov    $0x13f,%edx
801024e9:	b8 3c 00 00 00       	mov    $0x3c,%eax
801024ee:	e8 5f ff ff ff       	call   80102452 <lapicw>
  lapicw(TDCR, X1);
801024f3:	ba 0b 00 00 00       	mov    $0xb,%edx
801024f8:	b8 f8 00 00 00       	mov    $0xf8,%eax
801024fd:	e8 50 ff ff ff       	call   80102452 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102502:	ba 20 00 02 00       	mov    $0x20020,%edx
80102507:	b8 c8 00 00 00       	mov    $0xc8,%eax
8010250c:	e8 41 ff ff ff       	call   80102452 <lapicw>
  lapicw(TICR, 10000000);
80102511:	ba 80 96 98 00       	mov    $0x989680,%edx
80102516:	b8 e0 00 00 00       	mov    $0xe0,%eax
8010251b:	e8 32 ff ff ff       	call   80102452 <lapicw>
  lapicw(LINT0, MASKED);
80102520:	ba 00 00 01 00       	mov    $0x10000,%edx
80102525:	b8 d4 00 00 00       	mov    $0xd4,%eax
8010252a:	e8 23 ff ff ff       	call   80102452 <lapicw>
  lapicw(LINT1, MASKED);
8010252f:	ba 00 00 01 00       	mov    $0x10000,%edx
80102534:	b8 d8 00 00 00       	mov    $0xd8,%eax
80102539:	e8 14 ff ff ff       	call   80102452 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
8010253e:	a1 e4 26 13 80       	mov    0x801326e4,%eax
80102543:	8b 40 30             	mov    0x30(%eax),%eax
80102546:	c1 e8 10             	shr    $0x10,%eax
80102549:	3c 03                	cmp    $0x3,%al
8010254b:	77 7b                	ja     801025c8 <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
8010254d:	ba 33 00 00 00       	mov    $0x33,%edx
80102552:	b8 dc 00 00 00       	mov    $0xdc,%eax
80102557:	e8 f6 fe ff ff       	call   80102452 <lapicw>
  lapicw(ESR, 0);
8010255c:	ba 00 00 00 00       	mov    $0x0,%edx
80102561:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102566:	e8 e7 fe ff ff       	call   80102452 <lapicw>
  lapicw(ESR, 0);
8010256b:	ba 00 00 00 00       	mov    $0x0,%edx
80102570:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102575:	e8 d8 fe ff ff       	call   80102452 <lapicw>
  lapicw(EOI, 0);
8010257a:	ba 00 00 00 00       	mov    $0x0,%edx
8010257f:	b8 2c 00 00 00       	mov    $0x2c,%eax
80102584:	e8 c9 fe ff ff       	call   80102452 <lapicw>
  lapicw(ICRHI, 0);
80102589:	ba 00 00 00 00       	mov    $0x0,%edx
8010258e:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102593:	e8 ba fe ff ff       	call   80102452 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102598:	ba 00 85 08 00       	mov    $0x88500,%edx
8010259d:	b8 c0 00 00 00       	mov    $0xc0,%eax
801025a2:	e8 ab fe ff ff       	call   80102452 <lapicw>
  while(lapic[ICRLO] & DELIVS)
801025a7:	a1 e4 26 13 80       	mov    0x801326e4,%eax
801025ac:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
801025b2:	f6 c4 10             	test   $0x10,%ah
801025b5:	75 f0                	jne    801025a7 <lapicinit+0xd3>
  lapicw(TPR, 0);
801025b7:	ba 00 00 00 00       	mov    $0x0,%edx
801025bc:	b8 20 00 00 00       	mov    $0x20,%eax
801025c1:	e8 8c fe ff ff       	call   80102452 <lapicw>
}
801025c6:	5d                   	pop    %ebp
801025c7:	c3                   	ret    
    lapicw(PCINT, MASKED);
801025c8:	ba 00 00 01 00       	mov    $0x10000,%edx
801025cd:	b8 d0 00 00 00       	mov    $0xd0,%eax
801025d2:	e8 7b fe ff ff       	call   80102452 <lapicw>
801025d7:	e9 71 ff ff ff       	jmp    8010254d <lapicinit+0x79>
801025dc:	f3 c3                	repz ret 

801025de <lapicid>:
{
801025de:	55                   	push   %ebp
801025df:	89 e5                	mov    %esp,%ebp
  if (!lapic)
801025e1:	a1 e4 26 13 80       	mov    0x801326e4,%eax
801025e6:	85 c0                	test   %eax,%eax
801025e8:	74 08                	je     801025f2 <lapicid+0x14>
  return lapic[ID] >> 24;
801025ea:	8b 40 20             	mov    0x20(%eax),%eax
801025ed:	c1 e8 18             	shr    $0x18,%eax
}
801025f0:	5d                   	pop    %ebp
801025f1:	c3                   	ret    
    return 0;
801025f2:	b8 00 00 00 00       	mov    $0x0,%eax
801025f7:	eb f7                	jmp    801025f0 <lapicid+0x12>

801025f9 <lapiceoi>:
  if(lapic)
801025f9:	83 3d e4 26 13 80 00 	cmpl   $0x0,0x801326e4
80102600:	74 14                	je     80102616 <lapiceoi+0x1d>
{
80102602:	55                   	push   %ebp
80102603:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
80102605:	ba 00 00 00 00       	mov    $0x0,%edx
8010260a:	b8 2c 00 00 00       	mov    $0x2c,%eax
8010260f:	e8 3e fe ff ff       	call   80102452 <lapicw>
}
80102614:	5d                   	pop    %ebp
80102615:	c3                   	ret    
80102616:	f3 c3                	repz ret 

80102618 <microdelay>:
{
80102618:	55                   	push   %ebp
80102619:	89 e5                	mov    %esp,%ebp
}
8010261b:	5d                   	pop    %ebp
8010261c:	c3                   	ret    

8010261d <lapicstartap>:
{
8010261d:	55                   	push   %ebp
8010261e:	89 e5                	mov    %esp,%ebp
80102620:	57                   	push   %edi
80102621:	56                   	push   %esi
80102622:	53                   	push   %ebx
80102623:	8b 75 08             	mov    0x8(%ebp),%esi
80102626:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102629:	b8 0f 00 00 00       	mov    $0xf,%eax
8010262e:	ba 70 00 00 00       	mov    $0x70,%edx
80102633:	ee                   	out    %al,(%dx)
80102634:	b8 0a 00 00 00       	mov    $0xa,%eax
80102639:	ba 71 00 00 00       	mov    $0x71,%edx
8010263e:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
8010263f:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
80102646:	00 00 
  wrv[1] = addr >> 4;
80102648:	89 f8                	mov    %edi,%eax
8010264a:	c1 e8 04             	shr    $0x4,%eax
8010264d:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
80102653:	c1 e6 18             	shl    $0x18,%esi
80102656:	89 f2                	mov    %esi,%edx
80102658:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010265d:	e8 f0 fd ff ff       	call   80102452 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102662:	ba 00 c5 00 00       	mov    $0xc500,%edx
80102667:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010266c:	e8 e1 fd ff ff       	call   80102452 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
80102671:	ba 00 85 00 00       	mov    $0x8500,%edx
80102676:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010267b:	e8 d2 fd ff ff       	call   80102452 <lapicw>
  for(i = 0; i < 2; i++){
80102680:	bb 00 00 00 00       	mov    $0x0,%ebx
80102685:	eb 21                	jmp    801026a8 <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
80102687:	89 f2                	mov    %esi,%edx
80102689:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010268e:	e8 bf fd ff ff       	call   80102452 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80102693:	89 fa                	mov    %edi,%edx
80102695:	c1 ea 0c             	shr    $0xc,%edx
80102698:	80 ce 06             	or     $0x6,%dh
8010269b:	b8 c0 00 00 00       	mov    $0xc0,%eax
801026a0:	e8 ad fd ff ff       	call   80102452 <lapicw>
  for(i = 0; i < 2; i++){
801026a5:	83 c3 01             	add    $0x1,%ebx
801026a8:	83 fb 01             	cmp    $0x1,%ebx
801026ab:	7e da                	jle    80102687 <lapicstartap+0x6a>
}
801026ad:	5b                   	pop    %ebx
801026ae:	5e                   	pop    %esi
801026af:	5f                   	pop    %edi
801026b0:	5d                   	pop    %ebp
801026b1:	c3                   	ret    

801026b2 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
801026b2:	55                   	push   %ebp
801026b3:	89 e5                	mov    %esp,%ebp
801026b5:	57                   	push   %edi
801026b6:	56                   	push   %esi
801026b7:	53                   	push   %ebx
801026b8:	83 ec 3c             	sub    $0x3c,%esp
801026bb:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801026be:	b8 0b 00 00 00       	mov    $0xb,%eax
801026c3:	e8 a2 fd ff ff       	call   8010246a <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
801026c8:	83 e0 04             	and    $0x4,%eax
801026cb:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
801026cd:	8d 45 d0             	lea    -0x30(%ebp),%eax
801026d0:	e8 a9 fd ff ff       	call   8010247e <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
801026d5:	b8 0a 00 00 00       	mov    $0xa,%eax
801026da:	e8 8b fd ff ff       	call   8010246a <cmos_read>
801026df:	a8 80                	test   $0x80,%al
801026e1:	75 ea                	jne    801026cd <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
801026e3:	8d 5d b8             	lea    -0x48(%ebp),%ebx
801026e6:	89 d8                	mov    %ebx,%eax
801026e8:	e8 91 fd ff ff       	call   8010247e <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
801026ed:	83 ec 04             	sub    $0x4,%esp
801026f0:	6a 18                	push   $0x18
801026f2:	53                   	push   %ebx
801026f3:	8d 45 d0             	lea    -0x30(%ebp),%eax
801026f6:	50                   	push   %eax
801026f7:	e8 f6 17 00 00       	call   80103ef2 <memcmp>
801026fc:	83 c4 10             	add    $0x10,%esp
801026ff:	85 c0                	test   %eax,%eax
80102701:	75 ca                	jne    801026cd <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
80102703:	85 ff                	test   %edi,%edi
80102705:	0f 85 84 00 00 00    	jne    8010278f <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
8010270b:	8b 55 d0             	mov    -0x30(%ebp),%edx
8010270e:	89 d0                	mov    %edx,%eax
80102710:	c1 e8 04             	shr    $0x4,%eax
80102713:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102716:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102719:	83 e2 0f             	and    $0xf,%edx
8010271c:	01 d0                	add    %edx,%eax
8010271e:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
80102721:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80102724:	89 d0                	mov    %edx,%eax
80102726:	c1 e8 04             	shr    $0x4,%eax
80102729:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010272c:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010272f:	83 e2 0f             	and    $0xf,%edx
80102732:	01 d0                	add    %edx,%eax
80102734:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
80102737:	8b 55 d8             	mov    -0x28(%ebp),%edx
8010273a:	89 d0                	mov    %edx,%eax
8010273c:	c1 e8 04             	shr    $0x4,%eax
8010273f:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102742:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102745:	83 e2 0f             	and    $0xf,%edx
80102748:	01 d0                	add    %edx,%eax
8010274a:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
8010274d:	8b 55 dc             	mov    -0x24(%ebp),%edx
80102750:	89 d0                	mov    %edx,%eax
80102752:	c1 e8 04             	shr    $0x4,%eax
80102755:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102758:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010275b:	83 e2 0f             	and    $0xf,%edx
8010275e:	01 d0                	add    %edx,%eax
80102760:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
80102763:	8b 55 e0             	mov    -0x20(%ebp),%edx
80102766:	89 d0                	mov    %edx,%eax
80102768:	c1 e8 04             	shr    $0x4,%eax
8010276b:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010276e:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102771:	83 e2 0f             	and    $0xf,%edx
80102774:	01 d0                	add    %edx,%eax
80102776:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
80102779:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010277c:	89 d0                	mov    %edx,%eax
8010277e:	c1 e8 04             	shr    $0x4,%eax
80102781:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102784:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102787:	83 e2 0f             	and    $0xf,%edx
8010278a:	01 d0                	add    %edx,%eax
8010278c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
8010278f:	8b 45 d0             	mov    -0x30(%ebp),%eax
80102792:	89 06                	mov    %eax,(%esi)
80102794:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102797:	89 46 04             	mov    %eax,0x4(%esi)
8010279a:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010279d:	89 46 08             	mov    %eax,0x8(%esi)
801027a0:	8b 45 dc             	mov    -0x24(%ebp),%eax
801027a3:	89 46 0c             	mov    %eax,0xc(%esi)
801027a6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801027a9:	89 46 10             	mov    %eax,0x10(%esi)
801027ac:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801027af:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
801027b2:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
801027b9:	8d 65 f4             	lea    -0xc(%ebp),%esp
801027bc:	5b                   	pop    %ebx
801027bd:	5e                   	pop    %esi
801027be:	5f                   	pop    %edi
801027bf:	5d                   	pop    %ebp
801027c0:	c3                   	ret    

801027c1 <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
801027c1:	55                   	push   %ebp
801027c2:	89 e5                	mov    %esp,%ebp
801027c4:	53                   	push   %ebx
801027c5:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
801027c8:	ff 35 34 27 13 80    	pushl  0x80132734
801027ce:	ff 35 44 27 13 80    	pushl  0x80132744
801027d4:	e8 93 d9 ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
801027d9:	8b 58 5c             	mov    0x5c(%eax),%ebx
801027dc:	89 1d 48 27 13 80    	mov    %ebx,0x80132748
  for (i = 0; i < log.lh.n; i++) {
801027e2:	83 c4 10             	add    $0x10,%esp
801027e5:	ba 00 00 00 00       	mov    $0x0,%edx
801027ea:	eb 0e                	jmp    801027fa <read_head+0x39>
    log.lh.block[i] = lh->block[i];
801027ec:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
801027f0:	89 0c 95 4c 27 13 80 	mov    %ecx,-0x7fecd8b4(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
801027f7:	83 c2 01             	add    $0x1,%edx
801027fa:	39 d3                	cmp    %edx,%ebx
801027fc:	7f ee                	jg     801027ec <read_head+0x2b>
  }
  brelse(buf);
801027fe:	83 ec 0c             	sub    $0xc,%esp
80102801:	50                   	push   %eax
80102802:	e8 ce d9 ff ff       	call   801001d5 <brelse>
}
80102807:	83 c4 10             	add    $0x10,%esp
8010280a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010280d:	c9                   	leave  
8010280e:	c3                   	ret    

8010280f <install_trans>:
{
8010280f:	55                   	push   %ebp
80102810:	89 e5                	mov    %esp,%ebp
80102812:	57                   	push   %edi
80102813:	56                   	push   %esi
80102814:	53                   	push   %ebx
80102815:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
80102818:	bb 00 00 00 00       	mov    $0x0,%ebx
8010281d:	eb 66                	jmp    80102885 <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
8010281f:	89 d8                	mov    %ebx,%eax
80102821:	03 05 34 27 13 80    	add    0x80132734,%eax
80102827:	83 c0 01             	add    $0x1,%eax
8010282a:	83 ec 08             	sub    $0x8,%esp
8010282d:	50                   	push   %eax
8010282e:	ff 35 44 27 13 80    	pushl  0x80132744
80102834:	e8 33 d9 ff ff       	call   8010016c <bread>
80102839:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
8010283b:	83 c4 08             	add    $0x8,%esp
8010283e:	ff 34 9d 4c 27 13 80 	pushl  -0x7fecd8b4(,%ebx,4)
80102845:	ff 35 44 27 13 80    	pushl  0x80132744
8010284b:	e8 1c d9 ff ff       	call   8010016c <bread>
80102850:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80102852:	8d 57 5c             	lea    0x5c(%edi),%edx
80102855:	8d 40 5c             	lea    0x5c(%eax),%eax
80102858:	83 c4 0c             	add    $0xc,%esp
8010285b:	68 00 02 00 00       	push   $0x200
80102860:	52                   	push   %edx
80102861:	50                   	push   %eax
80102862:	e8 c0 16 00 00       	call   80103f27 <memmove>
    bwrite(dbuf);  // write dst to disk
80102867:	89 34 24             	mov    %esi,(%esp)
8010286a:	e8 2b d9 ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
8010286f:	89 3c 24             	mov    %edi,(%esp)
80102872:	e8 5e d9 ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
80102877:	89 34 24             	mov    %esi,(%esp)
8010287a:	e8 56 d9 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
8010287f:	83 c3 01             	add    $0x1,%ebx
80102882:	83 c4 10             	add    $0x10,%esp
80102885:	39 1d 48 27 13 80    	cmp    %ebx,0x80132748
8010288b:	7f 92                	jg     8010281f <install_trans+0x10>
}
8010288d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102890:	5b                   	pop    %ebx
80102891:	5e                   	pop    %esi
80102892:	5f                   	pop    %edi
80102893:	5d                   	pop    %ebp
80102894:	c3                   	ret    

80102895 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80102895:	55                   	push   %ebp
80102896:	89 e5                	mov    %esp,%ebp
80102898:	53                   	push   %ebx
80102899:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
8010289c:	ff 35 34 27 13 80    	pushl  0x80132734
801028a2:	ff 35 44 27 13 80    	pushl  0x80132744
801028a8:	e8 bf d8 ff ff       	call   8010016c <bread>
801028ad:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
801028af:	8b 0d 48 27 13 80    	mov    0x80132748,%ecx
801028b5:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
801028b8:	83 c4 10             	add    $0x10,%esp
801028bb:	b8 00 00 00 00       	mov    $0x0,%eax
801028c0:	eb 0e                	jmp    801028d0 <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
801028c2:	8b 14 85 4c 27 13 80 	mov    -0x7fecd8b4(,%eax,4),%edx
801028c9:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
801028cd:	83 c0 01             	add    $0x1,%eax
801028d0:	39 c1                	cmp    %eax,%ecx
801028d2:	7f ee                	jg     801028c2 <write_head+0x2d>
  }
  bwrite(buf);
801028d4:	83 ec 0c             	sub    $0xc,%esp
801028d7:	53                   	push   %ebx
801028d8:	e8 bd d8 ff ff       	call   8010019a <bwrite>
  brelse(buf);
801028dd:	89 1c 24             	mov    %ebx,(%esp)
801028e0:	e8 f0 d8 ff ff       	call   801001d5 <brelse>
}
801028e5:	83 c4 10             	add    $0x10,%esp
801028e8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801028eb:	c9                   	leave  
801028ec:	c3                   	ret    

801028ed <recover_from_log>:

static void
recover_from_log(void)
{
801028ed:	55                   	push   %ebp
801028ee:	89 e5                	mov    %esp,%ebp
801028f0:	83 ec 08             	sub    $0x8,%esp
  read_head();
801028f3:	e8 c9 fe ff ff       	call   801027c1 <read_head>
  install_trans(); // if committed, copy from log to disk
801028f8:	e8 12 ff ff ff       	call   8010280f <install_trans>
  log.lh.n = 0;
801028fd:	c7 05 48 27 13 80 00 	movl   $0x0,0x80132748
80102904:	00 00 00 
  write_head(); // clear the log
80102907:	e8 89 ff ff ff       	call   80102895 <write_head>
}
8010290c:	c9                   	leave  
8010290d:	c3                   	ret    

8010290e <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
8010290e:	55                   	push   %ebp
8010290f:	89 e5                	mov    %esp,%ebp
80102911:	57                   	push   %edi
80102912:	56                   	push   %esi
80102913:	53                   	push   %ebx
80102914:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80102917:	bb 00 00 00 00       	mov    $0x0,%ebx
8010291c:	eb 66                	jmp    80102984 <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
8010291e:	89 d8                	mov    %ebx,%eax
80102920:	03 05 34 27 13 80    	add    0x80132734,%eax
80102926:	83 c0 01             	add    $0x1,%eax
80102929:	83 ec 08             	sub    $0x8,%esp
8010292c:	50                   	push   %eax
8010292d:	ff 35 44 27 13 80    	pushl  0x80132744
80102933:	e8 34 d8 ff ff       	call   8010016c <bread>
80102938:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
8010293a:	83 c4 08             	add    $0x8,%esp
8010293d:	ff 34 9d 4c 27 13 80 	pushl  -0x7fecd8b4(,%ebx,4)
80102944:	ff 35 44 27 13 80    	pushl  0x80132744
8010294a:	e8 1d d8 ff ff       	call   8010016c <bread>
8010294f:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
80102951:	8d 50 5c             	lea    0x5c(%eax),%edx
80102954:	8d 46 5c             	lea    0x5c(%esi),%eax
80102957:	83 c4 0c             	add    $0xc,%esp
8010295a:	68 00 02 00 00       	push   $0x200
8010295f:	52                   	push   %edx
80102960:	50                   	push   %eax
80102961:	e8 c1 15 00 00       	call   80103f27 <memmove>
    bwrite(to);  // write the log
80102966:	89 34 24             	mov    %esi,(%esp)
80102969:	e8 2c d8 ff ff       	call   8010019a <bwrite>
    brelse(from);
8010296e:	89 3c 24             	mov    %edi,(%esp)
80102971:	e8 5f d8 ff ff       	call   801001d5 <brelse>
    brelse(to);
80102976:	89 34 24             	mov    %esi,(%esp)
80102979:	e8 57 d8 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
8010297e:	83 c3 01             	add    $0x1,%ebx
80102981:	83 c4 10             	add    $0x10,%esp
80102984:	39 1d 48 27 13 80    	cmp    %ebx,0x80132748
8010298a:	7f 92                	jg     8010291e <write_log+0x10>
  }
}
8010298c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010298f:	5b                   	pop    %ebx
80102990:	5e                   	pop    %esi
80102991:	5f                   	pop    %edi
80102992:	5d                   	pop    %ebp
80102993:	c3                   	ret    

80102994 <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
80102994:	83 3d 48 27 13 80 00 	cmpl   $0x0,0x80132748
8010299b:	7e 26                	jle    801029c3 <commit+0x2f>
{
8010299d:	55                   	push   %ebp
8010299e:	89 e5                	mov    %esp,%ebp
801029a0:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
801029a3:	e8 66 ff ff ff       	call   8010290e <write_log>
    write_head();    // Write header to disk -- the real commit
801029a8:	e8 e8 fe ff ff       	call   80102895 <write_head>
    install_trans(); // Now install writes to home locations
801029ad:	e8 5d fe ff ff       	call   8010280f <install_trans>
    log.lh.n = 0;
801029b2:	c7 05 48 27 13 80 00 	movl   $0x0,0x80132748
801029b9:	00 00 00 
    write_head();    // Erase the transaction from the log
801029bc:	e8 d4 fe ff ff       	call   80102895 <write_head>
  }
}
801029c1:	c9                   	leave  
801029c2:	c3                   	ret    
801029c3:	f3 c3                	repz ret 

801029c5 <initlog>:
{
801029c5:	55                   	push   %ebp
801029c6:	89 e5                	mov    %esp,%ebp
801029c8:	53                   	push   %ebx
801029c9:	83 ec 2c             	sub    $0x2c,%esp
801029cc:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
801029cf:	68 e0 6b 10 80       	push   $0x80106be0
801029d4:	68 00 27 13 80       	push   $0x80132700
801029d9:	e8 e6 12 00 00       	call   80103cc4 <initlock>
  readsb(dev, &sb);
801029de:	83 c4 08             	add    $0x8,%esp
801029e1:	8d 45 dc             	lea    -0x24(%ebp),%eax
801029e4:	50                   	push   %eax
801029e5:	53                   	push   %ebx
801029e6:	e8 4b e8 ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
801029eb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801029ee:	a3 34 27 13 80       	mov    %eax,0x80132734
  log.size = sb.nlog;
801029f3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801029f6:	a3 38 27 13 80       	mov    %eax,0x80132738
  log.dev = dev;
801029fb:	89 1d 44 27 13 80    	mov    %ebx,0x80132744
  recover_from_log();
80102a01:	e8 e7 fe ff ff       	call   801028ed <recover_from_log>
}
80102a06:	83 c4 10             	add    $0x10,%esp
80102a09:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a0c:	c9                   	leave  
80102a0d:	c3                   	ret    

80102a0e <begin_op>:
{
80102a0e:	55                   	push   %ebp
80102a0f:	89 e5                	mov    %esp,%ebp
80102a11:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
80102a14:	68 00 27 13 80       	push   $0x80132700
80102a19:	e8 e2 13 00 00       	call   80103e00 <acquire>
80102a1e:	83 c4 10             	add    $0x10,%esp
80102a21:	eb 15                	jmp    80102a38 <begin_op+0x2a>
      sleep(&log, &log.lock);
80102a23:	83 ec 08             	sub    $0x8,%esp
80102a26:	68 00 27 13 80       	push   $0x80132700
80102a2b:	68 00 27 13 80       	push   $0x80132700
80102a30:	e8 d0 0e 00 00       	call   80103905 <sleep>
80102a35:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
80102a38:	83 3d 40 27 13 80 00 	cmpl   $0x0,0x80132740
80102a3f:	75 e2                	jne    80102a23 <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80102a41:	a1 3c 27 13 80       	mov    0x8013273c,%eax
80102a46:	83 c0 01             	add    $0x1,%eax
80102a49:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102a4c:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
80102a4f:	03 15 48 27 13 80    	add    0x80132748,%edx
80102a55:	83 fa 1e             	cmp    $0x1e,%edx
80102a58:	7e 17                	jle    80102a71 <begin_op+0x63>
      sleep(&log, &log.lock);
80102a5a:	83 ec 08             	sub    $0x8,%esp
80102a5d:	68 00 27 13 80       	push   $0x80132700
80102a62:	68 00 27 13 80       	push   $0x80132700
80102a67:	e8 99 0e 00 00       	call   80103905 <sleep>
80102a6c:	83 c4 10             	add    $0x10,%esp
80102a6f:	eb c7                	jmp    80102a38 <begin_op+0x2a>
      log.outstanding += 1;
80102a71:	a3 3c 27 13 80       	mov    %eax,0x8013273c
      release(&log.lock);
80102a76:	83 ec 0c             	sub    $0xc,%esp
80102a79:	68 00 27 13 80       	push   $0x80132700
80102a7e:	e8 e2 13 00 00       	call   80103e65 <release>
}
80102a83:	83 c4 10             	add    $0x10,%esp
80102a86:	c9                   	leave  
80102a87:	c3                   	ret    

80102a88 <end_op>:
{
80102a88:	55                   	push   %ebp
80102a89:	89 e5                	mov    %esp,%ebp
80102a8b:	53                   	push   %ebx
80102a8c:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
80102a8f:	68 00 27 13 80       	push   $0x80132700
80102a94:	e8 67 13 00 00       	call   80103e00 <acquire>
  log.outstanding -= 1;
80102a99:	a1 3c 27 13 80       	mov    0x8013273c,%eax
80102a9e:	83 e8 01             	sub    $0x1,%eax
80102aa1:	a3 3c 27 13 80       	mov    %eax,0x8013273c
  if(log.committing)
80102aa6:	8b 1d 40 27 13 80    	mov    0x80132740,%ebx
80102aac:	83 c4 10             	add    $0x10,%esp
80102aaf:	85 db                	test   %ebx,%ebx
80102ab1:	75 2c                	jne    80102adf <end_op+0x57>
  if(log.outstanding == 0){
80102ab3:	85 c0                	test   %eax,%eax
80102ab5:	75 35                	jne    80102aec <end_op+0x64>
    log.committing = 1;
80102ab7:	c7 05 40 27 13 80 01 	movl   $0x1,0x80132740
80102abe:	00 00 00 
    do_commit = 1;
80102ac1:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
80102ac6:	83 ec 0c             	sub    $0xc,%esp
80102ac9:	68 00 27 13 80       	push   $0x80132700
80102ace:	e8 92 13 00 00       	call   80103e65 <release>
  if(do_commit){
80102ad3:	83 c4 10             	add    $0x10,%esp
80102ad6:	85 db                	test   %ebx,%ebx
80102ad8:	75 24                	jne    80102afe <end_op+0x76>
}
80102ada:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102add:	c9                   	leave  
80102ade:	c3                   	ret    
    panic("log.committing");
80102adf:	83 ec 0c             	sub    $0xc,%esp
80102ae2:	68 e4 6b 10 80       	push   $0x80106be4
80102ae7:	e8 5c d8 ff ff       	call   80100348 <panic>
    wakeup(&log);
80102aec:	83 ec 0c             	sub    $0xc,%esp
80102aef:	68 00 27 13 80       	push   $0x80132700
80102af4:	e8 71 0f 00 00       	call   80103a6a <wakeup>
80102af9:	83 c4 10             	add    $0x10,%esp
80102afc:	eb c8                	jmp    80102ac6 <end_op+0x3e>
    commit();
80102afe:	e8 91 fe ff ff       	call   80102994 <commit>
    acquire(&log.lock);
80102b03:	83 ec 0c             	sub    $0xc,%esp
80102b06:	68 00 27 13 80       	push   $0x80132700
80102b0b:	e8 f0 12 00 00       	call   80103e00 <acquire>
    log.committing = 0;
80102b10:	c7 05 40 27 13 80 00 	movl   $0x0,0x80132740
80102b17:	00 00 00 
    wakeup(&log);
80102b1a:	c7 04 24 00 27 13 80 	movl   $0x80132700,(%esp)
80102b21:	e8 44 0f 00 00       	call   80103a6a <wakeup>
    release(&log.lock);
80102b26:	c7 04 24 00 27 13 80 	movl   $0x80132700,(%esp)
80102b2d:	e8 33 13 00 00       	call   80103e65 <release>
80102b32:	83 c4 10             	add    $0x10,%esp
}
80102b35:	eb a3                	jmp    80102ada <end_op+0x52>

80102b37 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80102b37:	55                   	push   %ebp
80102b38:	89 e5                	mov    %esp,%ebp
80102b3a:	53                   	push   %ebx
80102b3b:	83 ec 04             	sub    $0x4,%esp
80102b3e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80102b41:	8b 15 48 27 13 80    	mov    0x80132748,%edx
80102b47:	83 fa 1d             	cmp    $0x1d,%edx
80102b4a:	7f 45                	jg     80102b91 <log_write+0x5a>
80102b4c:	a1 38 27 13 80       	mov    0x80132738,%eax
80102b51:	83 e8 01             	sub    $0x1,%eax
80102b54:	39 c2                	cmp    %eax,%edx
80102b56:	7d 39                	jge    80102b91 <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102b58:	83 3d 3c 27 13 80 00 	cmpl   $0x0,0x8013273c
80102b5f:	7e 3d                	jle    80102b9e <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102b61:	83 ec 0c             	sub    $0xc,%esp
80102b64:	68 00 27 13 80       	push   $0x80132700
80102b69:	e8 92 12 00 00       	call   80103e00 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80102b6e:	83 c4 10             	add    $0x10,%esp
80102b71:	b8 00 00 00 00       	mov    $0x0,%eax
80102b76:	8b 15 48 27 13 80    	mov    0x80132748,%edx
80102b7c:	39 c2                	cmp    %eax,%edx
80102b7e:	7e 2b                	jle    80102bab <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102b80:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102b83:	39 0c 85 4c 27 13 80 	cmp    %ecx,-0x7fecd8b4(,%eax,4)
80102b8a:	74 1f                	je     80102bab <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
80102b8c:	83 c0 01             	add    $0x1,%eax
80102b8f:	eb e5                	jmp    80102b76 <log_write+0x3f>
    panic("too big a transaction");
80102b91:	83 ec 0c             	sub    $0xc,%esp
80102b94:	68 f3 6b 10 80       	push   $0x80106bf3
80102b99:	e8 aa d7 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102b9e:	83 ec 0c             	sub    $0xc,%esp
80102ba1:	68 09 6c 10 80       	push   $0x80106c09
80102ba6:	e8 9d d7 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102bab:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102bae:	89 0c 85 4c 27 13 80 	mov    %ecx,-0x7fecd8b4(,%eax,4)
  if (i == log.lh.n)
80102bb5:	39 c2                	cmp    %eax,%edx
80102bb7:	74 18                	je     80102bd1 <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102bb9:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102bbc:	83 ec 0c             	sub    $0xc,%esp
80102bbf:	68 00 27 13 80       	push   $0x80132700
80102bc4:	e8 9c 12 00 00       	call   80103e65 <release>
}
80102bc9:	83 c4 10             	add    $0x10,%esp
80102bcc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102bcf:	c9                   	leave  
80102bd0:	c3                   	ret    
    log.lh.n++;
80102bd1:	83 c2 01             	add    $0x1,%edx
80102bd4:	89 15 48 27 13 80    	mov    %edx,0x80132748
80102bda:	eb dd                	jmp    80102bb9 <log_write+0x82>

80102bdc <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102bdc:	55                   	push   %ebp
80102bdd:	89 e5                	mov    %esp,%ebp
80102bdf:	53                   	push   %ebx
80102be0:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102be3:	68 8a 00 00 00       	push   $0x8a
80102be8:	68 8c a4 10 80       	push   $0x8010a48c
80102bed:	68 00 70 00 80       	push   $0x80007000
80102bf2:	e8 30 13 00 00       	call   80103f27 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102bf7:	83 c4 10             	add    $0x10,%esp
80102bfa:	bb 00 28 13 80       	mov    $0x80132800,%ebx
80102bff:	eb 06                	jmp    80102c07 <startothers+0x2b>
80102c01:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102c07:	69 05 80 2d 13 80 b0 	imul   $0xb0,0x80132d80,%eax
80102c0e:	00 00 00 
80102c11:	05 00 28 13 80       	add    $0x80132800,%eax
80102c16:	39 d8                	cmp    %ebx,%eax
80102c18:	76 4c                	jbe    80102c66 <startothers+0x8a>
    if(c == mycpu())  // We've started already.
80102c1a:	e8 c8 07 00 00       	call   801033e7 <mycpu>
80102c1f:	39 d8                	cmp    %ebx,%eax
80102c21:	74 de                	je     80102c01 <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80102c23:	e8 a0 f4 ff ff       	call   801020c8 <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102c28:	05 00 10 00 00       	add    $0x1000,%eax
80102c2d:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102c32:	c7 05 f8 6f 00 80 aa 	movl   $0x80102caa,0x80006ff8
80102c39:	2c 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102c3c:	c7 05 f4 6f 00 80 00 	movl   $0x109000,0x80006ff4
80102c43:	90 10 00 

    lapicstartap(c->apicid, V2P(code));
80102c46:	83 ec 08             	sub    $0x8,%esp
80102c49:	68 00 70 00 00       	push   $0x7000
80102c4e:	0f b6 03             	movzbl (%ebx),%eax
80102c51:	50                   	push   %eax
80102c52:	e8 c6 f9 ff ff       	call   8010261d <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102c57:	83 c4 10             	add    $0x10,%esp
80102c5a:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102c60:	85 c0                	test   %eax,%eax
80102c62:	74 f6                	je     80102c5a <startothers+0x7e>
80102c64:	eb 9b                	jmp    80102c01 <startothers+0x25>
      ;
  }
}
80102c66:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102c69:	c9                   	leave  
80102c6a:	c3                   	ret    

80102c6b <mpmain>:
{
80102c6b:	55                   	push   %ebp
80102c6c:	89 e5                	mov    %esp,%ebp
80102c6e:	53                   	push   %ebx
80102c6f:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102c72:	e8 cc 07 00 00       	call   80103443 <cpuid>
80102c77:	89 c3                	mov    %eax,%ebx
80102c79:	e8 c5 07 00 00       	call   80103443 <cpuid>
80102c7e:	83 ec 04             	sub    $0x4,%esp
80102c81:	53                   	push   %ebx
80102c82:	50                   	push   %eax
80102c83:	68 24 6c 10 80       	push   $0x80106c24
80102c88:	e8 7e d9 ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102c8d:	e8 ec 23 00 00       	call   8010507e <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102c92:	e8 50 07 00 00       	call   801033e7 <mycpu>
80102c97:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102c99:	b8 01 00 00 00       	mov    $0x1,%eax
80102c9e:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102ca5:	e8 36 0a 00 00       	call   801036e0 <scheduler>

80102caa <mpenter>:
{
80102caa:	55                   	push   %ebp
80102cab:	89 e5                	mov    %esp,%ebp
80102cad:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102cb0:	e8 da 33 00 00       	call   8010608f <switchkvm>
  seginit();
80102cb5:	e8 89 32 00 00       	call   80105f43 <seginit>
  lapicinit();
80102cba:	e8 15 f8 ff ff       	call   801024d4 <lapicinit>
  mpmain();
80102cbf:	e8 a7 ff ff ff       	call   80102c6b <mpmain>

80102cc4 <main>:
{
80102cc4:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102cc8:	83 e4 f0             	and    $0xfffffff0,%esp
80102ccb:	ff 71 fc             	pushl  -0x4(%ecx)
80102cce:	55                   	push   %ebp
80102ccf:	89 e5                	mov    %esp,%ebp
80102cd1:	51                   	push   %ecx
80102cd2:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102cd5:	68 00 00 40 80       	push   $0x80400000
80102cda:	68 28 55 13 80       	push   $0x80135528
80102cdf:	e8 85 f3 ff ff       	call   80102069 <kinit1>
  kvmalloc();      // kernel page table
80102ce4:	e8 4e 38 00 00       	call   80106537 <kvmalloc>
  mpinit();        // detect other processors
80102ce9:	e8 c9 01 00 00       	call   80102eb7 <mpinit>
  lapicinit();     // interrupt controller
80102cee:	e8 e1 f7 ff ff       	call   801024d4 <lapicinit>
  seginit();       // segment descriptors
80102cf3:	e8 4b 32 00 00       	call   80105f43 <seginit>
  picinit();       // disable pic
80102cf8:	e8 82 02 00 00       	call   80102f7f <picinit>
  ioapicinit();    // another interrupt controller
80102cfd:	e8 f8 f1 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102d02:	e8 87 db ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102d07:	e8 20 26 00 00       	call   8010532c <uartinit>
  pinit();         // process table
80102d0c:	e8 bc 06 00 00       	call   801033cd <pinit>
  tvinit();        // trap vectors
80102d11:	e8 b7 22 00 00       	call   80104fcd <tvinit>
  binit();         // buffer cache
80102d16:	e8 d9 d3 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102d1b:	e8 f3 de ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102d20:	e8 db ef ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102d25:	e8 b2 fe ff ff       	call   80102bdc <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102d2a:	83 c4 08             	add    $0x8,%esp
80102d2d:	68 00 00 00 8e       	push   $0x8e000000
80102d32:	68 00 00 40 80       	push   $0x80400000
80102d37:	e8 5f f3 ff ff       	call   8010209b <kinit2>
  userinit();      // first user process
80102d3c:	e8 41 07 00 00       	call   80103482 <userinit>
  mpmain();        // finish this processor's setup
80102d41:	e8 25 ff ff ff       	call   80102c6b <mpmain>

80102d46 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102d46:	55                   	push   %ebp
80102d47:	89 e5                	mov    %esp,%ebp
80102d49:	56                   	push   %esi
80102d4a:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102d4b:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102d50:	b9 00 00 00 00       	mov    $0x0,%ecx
80102d55:	eb 09                	jmp    80102d60 <sum+0x1a>
    sum += addr[i];
80102d57:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102d5b:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102d5d:	83 c1 01             	add    $0x1,%ecx
80102d60:	39 d1                	cmp    %edx,%ecx
80102d62:	7c f3                	jl     80102d57 <sum+0x11>
  return sum;
}
80102d64:	89 d8                	mov    %ebx,%eax
80102d66:	5b                   	pop    %ebx
80102d67:	5e                   	pop    %esi
80102d68:	5d                   	pop    %ebp
80102d69:	c3                   	ret    

80102d6a <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102d6a:	55                   	push   %ebp
80102d6b:	89 e5                	mov    %esp,%ebp
80102d6d:	56                   	push   %esi
80102d6e:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102d6f:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102d75:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102d77:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102d79:	eb 03                	jmp    80102d7e <mpsearch1+0x14>
80102d7b:	83 c3 10             	add    $0x10,%ebx
80102d7e:	39 f3                	cmp    %esi,%ebx
80102d80:	73 29                	jae    80102dab <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102d82:	83 ec 04             	sub    $0x4,%esp
80102d85:	6a 04                	push   $0x4
80102d87:	68 38 6c 10 80       	push   $0x80106c38
80102d8c:	53                   	push   %ebx
80102d8d:	e8 60 11 00 00       	call   80103ef2 <memcmp>
80102d92:	83 c4 10             	add    $0x10,%esp
80102d95:	85 c0                	test   %eax,%eax
80102d97:	75 e2                	jne    80102d7b <mpsearch1+0x11>
80102d99:	ba 10 00 00 00       	mov    $0x10,%edx
80102d9e:	89 d8                	mov    %ebx,%eax
80102da0:	e8 a1 ff ff ff       	call   80102d46 <sum>
80102da5:	84 c0                	test   %al,%al
80102da7:	75 d2                	jne    80102d7b <mpsearch1+0x11>
80102da9:	eb 05                	jmp    80102db0 <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102dab:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102db0:	89 d8                	mov    %ebx,%eax
80102db2:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102db5:	5b                   	pop    %ebx
80102db6:	5e                   	pop    %esi
80102db7:	5d                   	pop    %ebp
80102db8:	c3                   	ret    

80102db9 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102db9:	55                   	push   %ebp
80102dba:	89 e5                	mov    %esp,%ebp
80102dbc:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102dbf:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102dc6:	c1 e0 08             	shl    $0x8,%eax
80102dc9:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102dd0:	09 d0                	or     %edx,%eax
80102dd2:	c1 e0 04             	shl    $0x4,%eax
80102dd5:	85 c0                	test   %eax,%eax
80102dd7:	74 1f                	je     80102df8 <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102dd9:	ba 00 04 00 00       	mov    $0x400,%edx
80102dde:	e8 87 ff ff ff       	call   80102d6a <mpsearch1>
80102de3:	85 c0                	test   %eax,%eax
80102de5:	75 0f                	jne    80102df6 <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102de7:	ba 00 00 01 00       	mov    $0x10000,%edx
80102dec:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102df1:	e8 74 ff ff ff       	call   80102d6a <mpsearch1>
}
80102df6:	c9                   	leave  
80102df7:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102df8:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102dff:	c1 e0 08             	shl    $0x8,%eax
80102e02:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102e09:	09 d0                	or     %edx,%eax
80102e0b:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102e0e:	2d 00 04 00 00       	sub    $0x400,%eax
80102e13:	ba 00 04 00 00       	mov    $0x400,%edx
80102e18:	e8 4d ff ff ff       	call   80102d6a <mpsearch1>
80102e1d:	85 c0                	test   %eax,%eax
80102e1f:	75 d5                	jne    80102df6 <mpsearch+0x3d>
80102e21:	eb c4                	jmp    80102de7 <mpsearch+0x2e>

80102e23 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102e23:	55                   	push   %ebp
80102e24:	89 e5                	mov    %esp,%ebp
80102e26:	57                   	push   %edi
80102e27:	56                   	push   %esi
80102e28:	53                   	push   %ebx
80102e29:	83 ec 1c             	sub    $0x1c,%esp
80102e2c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102e2f:	e8 85 ff ff ff       	call   80102db9 <mpsearch>
80102e34:	85 c0                	test   %eax,%eax
80102e36:	74 5c                	je     80102e94 <mpconfig+0x71>
80102e38:	89 c7                	mov    %eax,%edi
80102e3a:	8b 58 04             	mov    0x4(%eax),%ebx
80102e3d:	85 db                	test   %ebx,%ebx
80102e3f:	74 5a                	je     80102e9b <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102e41:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102e47:	83 ec 04             	sub    $0x4,%esp
80102e4a:	6a 04                	push   $0x4
80102e4c:	68 3d 6c 10 80       	push   $0x80106c3d
80102e51:	56                   	push   %esi
80102e52:	e8 9b 10 00 00       	call   80103ef2 <memcmp>
80102e57:	83 c4 10             	add    $0x10,%esp
80102e5a:	85 c0                	test   %eax,%eax
80102e5c:	75 44                	jne    80102ea2 <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102e5e:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102e65:	3c 01                	cmp    $0x1,%al
80102e67:	0f 95 c2             	setne  %dl
80102e6a:	3c 04                	cmp    $0x4,%al
80102e6c:	0f 95 c0             	setne  %al
80102e6f:	84 c2                	test   %al,%dl
80102e71:	75 36                	jne    80102ea9 <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102e73:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102e7a:	89 f0                	mov    %esi,%eax
80102e7c:	e8 c5 fe ff ff       	call   80102d46 <sum>
80102e81:	84 c0                	test   %al,%al
80102e83:	75 2b                	jne    80102eb0 <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102e85:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102e88:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102e8a:	89 f0                	mov    %esi,%eax
80102e8c:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102e8f:	5b                   	pop    %ebx
80102e90:	5e                   	pop    %esi
80102e91:	5f                   	pop    %edi
80102e92:	5d                   	pop    %ebp
80102e93:	c3                   	ret    
    return 0;
80102e94:	be 00 00 00 00       	mov    $0x0,%esi
80102e99:	eb ef                	jmp    80102e8a <mpconfig+0x67>
80102e9b:	be 00 00 00 00       	mov    $0x0,%esi
80102ea0:	eb e8                	jmp    80102e8a <mpconfig+0x67>
    return 0;
80102ea2:	be 00 00 00 00       	mov    $0x0,%esi
80102ea7:	eb e1                	jmp    80102e8a <mpconfig+0x67>
    return 0;
80102ea9:	be 00 00 00 00       	mov    $0x0,%esi
80102eae:	eb da                	jmp    80102e8a <mpconfig+0x67>
    return 0;
80102eb0:	be 00 00 00 00       	mov    $0x0,%esi
80102eb5:	eb d3                	jmp    80102e8a <mpconfig+0x67>

80102eb7 <mpinit>:

void
mpinit(void)
{
80102eb7:	55                   	push   %ebp
80102eb8:	89 e5                	mov    %esp,%ebp
80102eba:	57                   	push   %edi
80102ebb:	56                   	push   %esi
80102ebc:	53                   	push   %ebx
80102ebd:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102ec0:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102ec3:	e8 5b ff ff ff       	call   80102e23 <mpconfig>
80102ec8:	85 c0                	test   %eax,%eax
80102eca:	74 19                	je     80102ee5 <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102ecc:	8b 50 24             	mov    0x24(%eax),%edx
80102ecf:	89 15 e4 26 13 80    	mov    %edx,0x801326e4
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102ed5:	8d 50 2c             	lea    0x2c(%eax),%edx
80102ed8:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102edc:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102ede:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102ee3:	eb 34                	jmp    80102f19 <mpinit+0x62>
    panic("Expect to run on an SMP");
80102ee5:	83 ec 0c             	sub    $0xc,%esp
80102ee8:	68 42 6c 10 80       	push   $0x80106c42
80102eed:	e8 56 d4 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102ef2:	8b 35 80 2d 13 80    	mov    0x80132d80,%esi
80102ef8:	83 fe 07             	cmp    $0x7,%esi
80102efb:	7f 19                	jg     80102f16 <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102efd:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102f01:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102f07:	88 87 00 28 13 80    	mov    %al,-0x7fecd800(%edi)
        ncpu++;
80102f0d:	83 c6 01             	add    $0x1,%esi
80102f10:	89 35 80 2d 13 80    	mov    %esi,0x80132d80
      }
      p += sizeof(struct mpproc);
80102f16:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102f19:	39 ca                	cmp    %ecx,%edx
80102f1b:	73 2b                	jae    80102f48 <mpinit+0x91>
    switch(*p){
80102f1d:	0f b6 02             	movzbl (%edx),%eax
80102f20:	3c 04                	cmp    $0x4,%al
80102f22:	77 1d                	ja     80102f41 <mpinit+0x8a>
80102f24:	0f b6 c0             	movzbl %al,%eax
80102f27:	ff 24 85 7c 6c 10 80 	jmp    *-0x7fef9384(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102f2e:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102f32:	a2 e0 27 13 80       	mov    %al,0x801327e0
      p += sizeof(struct mpioapic);
80102f37:	83 c2 08             	add    $0x8,%edx
      continue;
80102f3a:	eb dd                	jmp    80102f19 <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102f3c:	83 c2 08             	add    $0x8,%edx
      continue;
80102f3f:	eb d8                	jmp    80102f19 <mpinit+0x62>
    default:
      ismp = 0;
80102f41:	bb 00 00 00 00       	mov    $0x0,%ebx
80102f46:	eb d1                	jmp    80102f19 <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102f48:	85 db                	test   %ebx,%ebx
80102f4a:	74 26                	je     80102f72 <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102f4c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102f4f:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102f53:	74 15                	je     80102f6a <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102f55:	b8 70 00 00 00       	mov    $0x70,%eax
80102f5a:	ba 22 00 00 00       	mov    $0x22,%edx
80102f5f:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102f60:	ba 23 00 00 00       	mov    $0x23,%edx
80102f65:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102f66:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102f69:	ee                   	out    %al,(%dx)
  }
}
80102f6a:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102f6d:	5b                   	pop    %ebx
80102f6e:	5e                   	pop    %esi
80102f6f:	5f                   	pop    %edi
80102f70:	5d                   	pop    %ebp
80102f71:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102f72:	83 ec 0c             	sub    $0xc,%esp
80102f75:	68 5c 6c 10 80       	push   $0x80106c5c
80102f7a:	e8 c9 d3 ff ff       	call   80100348 <panic>

80102f7f <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102f7f:	55                   	push   %ebp
80102f80:	89 e5                	mov    %esp,%ebp
80102f82:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102f87:	ba 21 00 00 00       	mov    $0x21,%edx
80102f8c:	ee                   	out    %al,(%dx)
80102f8d:	ba a1 00 00 00       	mov    $0xa1,%edx
80102f92:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102f93:	5d                   	pop    %ebp
80102f94:	c3                   	ret    

80102f95 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102f95:	55                   	push   %ebp
80102f96:	89 e5                	mov    %esp,%ebp
80102f98:	57                   	push   %edi
80102f99:	56                   	push   %esi
80102f9a:	53                   	push   %ebx
80102f9b:	83 ec 0c             	sub    $0xc,%esp
80102f9e:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102fa1:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102fa4:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102faa:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102fb0:	e8 78 dc ff ff       	call   80100c2d <filealloc>
80102fb5:	89 03                	mov    %eax,(%ebx)
80102fb7:	85 c0                	test   %eax,%eax
80102fb9:	74 1e                	je     80102fd9 <pipealloc+0x44>
80102fbb:	e8 6d dc ff ff       	call   80100c2d <filealloc>
80102fc0:	89 06                	mov    %eax,(%esi)
80102fc2:	85 c0                	test   %eax,%eax
80102fc4:	74 13                	je     80102fd9 <pipealloc+0x44>
    goto bad;
  if((p = (struct pipe*)kalloc2(-2)) == 0)
80102fc6:	83 ec 0c             	sub    $0xc,%esp
80102fc9:	6a fe                	push   $0xfffffffe
80102fcb:	e8 92 f1 ff ff       	call   80102162 <kalloc2>
80102fd0:	89 c7                	mov    %eax,%edi
80102fd2:	83 c4 10             	add    $0x10,%esp
80102fd5:	85 c0                	test   %eax,%eax
80102fd7:	75 35                	jne    8010300e <pipealloc+0x79>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102fd9:	8b 03                	mov    (%ebx),%eax
80102fdb:	85 c0                	test   %eax,%eax
80102fdd:	74 0c                	je     80102feb <pipealloc+0x56>
    fileclose(*f0);
80102fdf:	83 ec 0c             	sub    $0xc,%esp
80102fe2:	50                   	push   %eax
80102fe3:	e8 eb dc ff ff       	call   80100cd3 <fileclose>
80102fe8:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102feb:	8b 06                	mov    (%esi),%eax
80102fed:	85 c0                	test   %eax,%eax
80102fef:	0f 84 8b 00 00 00    	je     80103080 <pipealloc+0xeb>
    fileclose(*f1);
80102ff5:	83 ec 0c             	sub    $0xc,%esp
80102ff8:	50                   	push   %eax
80102ff9:	e8 d5 dc ff ff       	call   80100cd3 <fileclose>
80102ffe:	83 c4 10             	add    $0x10,%esp
  return -1;
80103001:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103006:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103009:	5b                   	pop    %ebx
8010300a:	5e                   	pop    %esi
8010300b:	5f                   	pop    %edi
8010300c:	5d                   	pop    %ebp
8010300d:	c3                   	ret    
  p->readopen = 1;
8010300e:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103015:	00 00 00 
  p->writeopen = 1;
80103018:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
8010301f:	00 00 00 
  p->nwrite = 0;
80103022:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103029:	00 00 00 
  p->nread = 0;
8010302c:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80103033:	00 00 00 
  initlock(&p->lock, "pipe");
80103036:	83 ec 08             	sub    $0x8,%esp
80103039:	68 90 6c 10 80       	push   $0x80106c90
8010303e:	50                   	push   %eax
8010303f:	e8 80 0c 00 00       	call   80103cc4 <initlock>
  (*f0)->type = FD_PIPE;
80103044:	8b 03                	mov    (%ebx),%eax
80103046:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
8010304c:	8b 03                	mov    (%ebx),%eax
8010304e:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80103052:	8b 03                	mov    (%ebx),%eax
80103054:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103058:	8b 03                	mov    (%ebx),%eax
8010305a:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
8010305d:	8b 06                	mov    (%esi),%eax
8010305f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80103065:	8b 06                	mov    (%esi),%eax
80103067:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
8010306b:	8b 06                	mov    (%esi),%eax
8010306d:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80103071:	8b 06                	mov    (%esi),%eax
80103073:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80103076:	83 c4 10             	add    $0x10,%esp
80103079:	b8 00 00 00 00       	mov    $0x0,%eax
8010307e:	eb 86                	jmp    80103006 <pipealloc+0x71>
  return -1;
80103080:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103085:	e9 7c ff ff ff       	jmp    80103006 <pipealloc+0x71>

8010308a <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
8010308a:	55                   	push   %ebp
8010308b:	89 e5                	mov    %esp,%ebp
8010308d:	53                   	push   %ebx
8010308e:	83 ec 10             	sub    $0x10,%esp
80103091:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80103094:	53                   	push   %ebx
80103095:	e8 66 0d 00 00       	call   80103e00 <acquire>
  if(writable){
8010309a:	83 c4 10             	add    $0x10,%esp
8010309d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801030a1:	74 3f                	je     801030e2 <pipeclose+0x58>
    p->writeopen = 0;
801030a3:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
801030aa:	00 00 00 
    wakeup(&p->nread);
801030ad:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801030b3:	83 ec 0c             	sub    $0xc,%esp
801030b6:	50                   	push   %eax
801030b7:	e8 ae 09 00 00       	call   80103a6a <wakeup>
801030bc:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
801030bf:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
801030c6:	75 09                	jne    801030d1 <pipeclose+0x47>
801030c8:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
801030cf:	74 2f                	je     80103100 <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
801030d1:	83 ec 0c             	sub    $0xc,%esp
801030d4:	53                   	push   %ebx
801030d5:	e8 8b 0d 00 00       	call   80103e65 <release>
801030da:	83 c4 10             	add    $0x10,%esp
}
801030dd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801030e0:	c9                   	leave  
801030e1:	c3                   	ret    
    p->readopen = 0;
801030e2:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
801030e9:	00 00 00 
    wakeup(&p->nwrite);
801030ec:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
801030f2:	83 ec 0c             	sub    $0xc,%esp
801030f5:	50                   	push   %eax
801030f6:	e8 6f 09 00 00       	call   80103a6a <wakeup>
801030fb:	83 c4 10             	add    $0x10,%esp
801030fe:	eb bf                	jmp    801030bf <pipeclose+0x35>
    release(&p->lock);
80103100:	83 ec 0c             	sub    $0xc,%esp
80103103:	53                   	push   %ebx
80103104:	e8 5c 0d 00 00       	call   80103e65 <release>
    kfree((char*)p);
80103109:	89 1c 24             	mov    %ebx,(%esp)
8010310c:	e8 93 ee ff ff       	call   80101fa4 <kfree>
80103111:	83 c4 10             	add    $0x10,%esp
80103114:	eb c7                	jmp    801030dd <pipeclose+0x53>

80103116 <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
80103116:	55                   	push   %ebp
80103117:	89 e5                	mov    %esp,%ebp
80103119:	57                   	push   %edi
8010311a:	56                   	push   %esi
8010311b:	53                   	push   %ebx
8010311c:	83 ec 18             	sub    $0x18,%esp
8010311f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80103122:	89 de                	mov    %ebx,%esi
80103124:	53                   	push   %ebx
80103125:	e8 d6 0c 00 00       	call   80103e00 <acquire>
  for(i = 0; i < n; i++){
8010312a:	83 c4 10             	add    $0x10,%esp
8010312d:	bf 00 00 00 00       	mov    $0x0,%edi
80103132:	3b 7d 10             	cmp    0x10(%ebp),%edi
80103135:	0f 8d 88 00 00 00    	jge    801031c3 <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010313b:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
80103141:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103147:	05 00 02 00 00       	add    $0x200,%eax
8010314c:	39 c2                	cmp    %eax,%edx
8010314e:	75 51                	jne    801031a1 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
80103150:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80103157:	74 2f                	je     80103188 <pipewrite+0x72>
80103159:	e8 00 03 00 00       	call   8010345e <myproc>
8010315e:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80103162:	75 24                	jne    80103188 <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
80103164:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
8010316a:	83 ec 0c             	sub    $0xc,%esp
8010316d:	50                   	push   %eax
8010316e:	e8 f7 08 00 00       	call   80103a6a <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103173:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103179:	83 c4 08             	add    $0x8,%esp
8010317c:	56                   	push   %esi
8010317d:	50                   	push   %eax
8010317e:	e8 82 07 00 00       	call   80103905 <sleep>
80103183:	83 c4 10             	add    $0x10,%esp
80103186:	eb b3                	jmp    8010313b <pipewrite+0x25>
        release(&p->lock);
80103188:	83 ec 0c             	sub    $0xc,%esp
8010318b:	53                   	push   %ebx
8010318c:	e8 d4 0c 00 00       	call   80103e65 <release>
        return -1;
80103191:	83 c4 10             	add    $0x10,%esp
80103194:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
80103199:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010319c:	5b                   	pop    %ebx
8010319d:	5e                   	pop    %esi
8010319e:	5f                   	pop    %edi
8010319f:	5d                   	pop    %ebp
801031a0:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
801031a1:	8d 42 01             	lea    0x1(%edx),%eax
801031a4:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
801031aa:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
801031b0:	8b 45 0c             	mov    0xc(%ebp),%eax
801031b3:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
801031b7:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
801031bb:	83 c7 01             	add    $0x1,%edi
801031be:	e9 6f ff ff ff       	jmp    80103132 <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
801031c3:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801031c9:	83 ec 0c             	sub    $0xc,%esp
801031cc:	50                   	push   %eax
801031cd:	e8 98 08 00 00       	call   80103a6a <wakeup>
  release(&p->lock);
801031d2:	89 1c 24             	mov    %ebx,(%esp)
801031d5:	e8 8b 0c 00 00       	call   80103e65 <release>
  return n;
801031da:	83 c4 10             	add    $0x10,%esp
801031dd:	8b 45 10             	mov    0x10(%ebp),%eax
801031e0:	eb b7                	jmp    80103199 <pipewrite+0x83>

801031e2 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801031e2:	55                   	push   %ebp
801031e3:	89 e5                	mov    %esp,%ebp
801031e5:	57                   	push   %edi
801031e6:	56                   	push   %esi
801031e7:	53                   	push   %ebx
801031e8:	83 ec 18             	sub    $0x18,%esp
801031eb:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
801031ee:	89 df                	mov    %ebx,%edi
801031f0:	53                   	push   %ebx
801031f1:	e8 0a 0c 00 00       	call   80103e00 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801031f6:	83 c4 10             	add    $0x10,%esp
801031f9:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
801031ff:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
80103205:	75 3d                	jne    80103244 <piperead+0x62>
80103207:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
8010320d:	85 f6                	test   %esi,%esi
8010320f:	74 38                	je     80103249 <piperead+0x67>
    if(myproc()->killed){
80103211:	e8 48 02 00 00       	call   8010345e <myproc>
80103216:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010321a:	75 15                	jne    80103231 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
8010321c:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103222:	83 ec 08             	sub    $0x8,%esp
80103225:	57                   	push   %edi
80103226:	50                   	push   %eax
80103227:	e8 d9 06 00 00       	call   80103905 <sleep>
8010322c:	83 c4 10             	add    $0x10,%esp
8010322f:	eb c8                	jmp    801031f9 <piperead+0x17>
      release(&p->lock);
80103231:	83 ec 0c             	sub    $0xc,%esp
80103234:	53                   	push   %ebx
80103235:	e8 2b 0c 00 00       	call   80103e65 <release>
      return -1;
8010323a:	83 c4 10             	add    $0x10,%esp
8010323d:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103242:	eb 50                	jmp    80103294 <piperead+0xb2>
80103244:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103249:	3b 75 10             	cmp    0x10(%ebp),%esi
8010324c:	7d 2c                	jge    8010327a <piperead+0x98>
    if(p->nread == p->nwrite)
8010324e:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103254:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
8010325a:	74 1e                	je     8010327a <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
8010325c:	8d 50 01             	lea    0x1(%eax),%edx
8010325f:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
80103265:	25 ff 01 00 00       	and    $0x1ff,%eax
8010326a:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
8010326f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103272:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103275:	83 c6 01             	add    $0x1,%esi
80103278:	eb cf                	jmp    80103249 <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
8010327a:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103280:	83 ec 0c             	sub    $0xc,%esp
80103283:	50                   	push   %eax
80103284:	e8 e1 07 00 00       	call   80103a6a <wakeup>
  release(&p->lock);
80103289:	89 1c 24             	mov    %ebx,(%esp)
8010328c:	e8 d4 0b 00 00       	call   80103e65 <release>
  return i;
80103291:	83 c4 10             	add    $0x10,%esp
}
80103294:	89 f0                	mov    %esi,%eax
80103296:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103299:	5b                   	pop    %ebx
8010329a:	5e                   	pop    %esi
8010329b:	5f                   	pop    %edi
8010329c:	5d                   	pop    %ebp
8010329d:	c3                   	ret    

8010329e <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
8010329e:	55                   	push   %ebp
8010329f:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801032a1:	ba d4 2d 13 80       	mov    $0x80132dd4,%edx
801032a6:	eb 03                	jmp    801032ab <wakeup1+0xd>
801032a8:	83 c2 7c             	add    $0x7c,%edx
801032ab:	81 fa d4 4c 13 80    	cmp    $0x80134cd4,%edx
801032b1:	73 14                	jae    801032c7 <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
801032b3:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
801032b7:	75 ef                	jne    801032a8 <wakeup1+0xa>
801032b9:	39 42 20             	cmp    %eax,0x20(%edx)
801032bc:	75 ea                	jne    801032a8 <wakeup1+0xa>
      p->state = RUNNABLE;
801032be:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
801032c5:	eb e1                	jmp    801032a8 <wakeup1+0xa>
}
801032c7:	5d                   	pop    %ebp
801032c8:	c3                   	ret    

801032c9 <allocproc>:
{
801032c9:	55                   	push   %ebp
801032ca:	89 e5                	mov    %esp,%ebp
801032cc:	53                   	push   %ebx
801032cd:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
801032d0:	68 a0 2d 13 80       	push   $0x80132da0
801032d5:	e8 26 0b 00 00       	call   80103e00 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801032da:	83 c4 10             	add    $0x10,%esp
801032dd:	bb d4 2d 13 80       	mov    $0x80132dd4,%ebx
801032e2:	81 fb d4 4c 13 80    	cmp    $0x80134cd4,%ebx
801032e8:	73 0b                	jae    801032f5 <allocproc+0x2c>
    if(p->state == UNUSED)
801032ea:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
801032ee:	74 1c                	je     8010330c <allocproc+0x43>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801032f0:	83 c3 7c             	add    $0x7c,%ebx
801032f3:	eb ed                	jmp    801032e2 <allocproc+0x19>
  release(&ptable.lock);
801032f5:	83 ec 0c             	sub    $0xc,%esp
801032f8:	68 a0 2d 13 80       	push   $0x80132da0
801032fd:	e8 63 0b 00 00       	call   80103e65 <release>
  return 0;
80103302:	83 c4 10             	add    $0x10,%esp
80103305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010330a:	eb 69                	jmp    80103375 <allocproc+0xac>
  p->state = EMBRYO;
8010330c:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
80103313:	a1 04 a0 10 80       	mov    0x8010a004,%eax
80103318:	8d 50 01             	lea    0x1(%eax),%edx
8010331b:	89 15 04 a0 10 80    	mov    %edx,0x8010a004
80103321:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
80103324:	83 ec 0c             	sub    $0xc,%esp
80103327:	68 a0 2d 13 80       	push   $0x80132da0
8010332c:	e8 34 0b 00 00       	call   80103e65 <release>
  if((p->kstack = kalloc()) == 0){
80103331:	e8 92 ed ff ff       	call   801020c8 <kalloc>
80103336:	89 43 08             	mov    %eax,0x8(%ebx)
80103339:	83 c4 10             	add    $0x10,%esp
8010333c:	85 c0                	test   %eax,%eax
8010333e:	74 3c                	je     8010337c <allocproc+0xb3>
  sp -= sizeof *p->tf;
80103340:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
80103346:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
80103349:	c7 80 b0 0f 00 00 c2 	movl   $0x80104fc2,0xfb0(%eax)
80103350:	4f 10 80 
  sp -= sizeof *p->context;
80103353:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
80103358:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
8010335b:	83 ec 04             	sub    $0x4,%esp
8010335e:	6a 14                	push   $0x14
80103360:	6a 00                	push   $0x0
80103362:	50                   	push   %eax
80103363:	e8 44 0b 00 00       	call   80103eac <memset>
  p->context->eip = (uint)forkret;
80103368:	8b 43 1c             	mov    0x1c(%ebx),%eax
8010336b:	c7 40 10 8a 33 10 80 	movl   $0x8010338a,0x10(%eax)
  return p;
80103372:	83 c4 10             	add    $0x10,%esp
}
80103375:	89 d8                	mov    %ebx,%eax
80103377:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010337a:	c9                   	leave  
8010337b:	c3                   	ret    
    p->state = UNUSED;
8010337c:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
80103383:	bb 00 00 00 00       	mov    $0x0,%ebx
80103388:	eb eb                	jmp    80103375 <allocproc+0xac>

8010338a <forkret>:
{
8010338a:	55                   	push   %ebp
8010338b:	89 e5                	mov    %esp,%ebp
8010338d:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
80103390:	68 a0 2d 13 80       	push   $0x80132da0
80103395:	e8 cb 0a 00 00       	call   80103e65 <release>
  if (first) {
8010339a:	83 c4 10             	add    $0x10,%esp
8010339d:	83 3d 00 a0 10 80 00 	cmpl   $0x0,0x8010a000
801033a4:	75 02                	jne    801033a8 <forkret+0x1e>
}
801033a6:	c9                   	leave  
801033a7:	c3                   	ret    
    first = 0;
801033a8:	c7 05 00 a0 10 80 00 	movl   $0x0,0x8010a000
801033af:	00 00 00 
    iinit(ROOTDEV);
801033b2:	83 ec 0c             	sub    $0xc,%esp
801033b5:	6a 01                	push   $0x1
801033b7:	e8 30 df ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
801033bc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801033c3:	e8 fd f5 ff ff       	call   801029c5 <initlog>
801033c8:	83 c4 10             	add    $0x10,%esp
}
801033cb:	eb d9                	jmp    801033a6 <forkret+0x1c>

801033cd <pinit>:
{
801033cd:	55                   	push   %ebp
801033ce:	89 e5                	mov    %esp,%ebp
801033d0:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
801033d3:	68 95 6c 10 80       	push   $0x80106c95
801033d8:	68 a0 2d 13 80       	push   $0x80132da0
801033dd:	e8 e2 08 00 00       	call   80103cc4 <initlock>
}
801033e2:	83 c4 10             	add    $0x10,%esp
801033e5:	c9                   	leave  
801033e6:	c3                   	ret    

801033e7 <mycpu>:
{
801033e7:	55                   	push   %ebp
801033e8:	89 e5                	mov    %esp,%ebp
801033ea:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801033ed:	9c                   	pushf  
801033ee:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801033ef:	f6 c4 02             	test   $0x2,%ah
801033f2:	75 28                	jne    8010341c <mycpu+0x35>
  apicid = lapicid();
801033f4:	e8 e5 f1 ff ff       	call   801025de <lapicid>
  for (i = 0; i < ncpu; ++i) {
801033f9:	ba 00 00 00 00       	mov    $0x0,%edx
801033fe:	39 15 80 2d 13 80    	cmp    %edx,0x80132d80
80103404:	7e 23                	jle    80103429 <mycpu+0x42>
    if (cpus[i].apicid == apicid)
80103406:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
8010340c:	0f b6 89 00 28 13 80 	movzbl -0x7fecd800(%ecx),%ecx
80103413:	39 c1                	cmp    %eax,%ecx
80103415:	74 1f                	je     80103436 <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
80103417:	83 c2 01             	add    $0x1,%edx
8010341a:	eb e2                	jmp    801033fe <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
8010341c:	83 ec 0c             	sub    $0xc,%esp
8010341f:	68 78 6d 10 80       	push   $0x80106d78
80103424:	e8 1f cf ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
80103429:	83 ec 0c             	sub    $0xc,%esp
8010342c:	68 9c 6c 10 80       	push   $0x80106c9c
80103431:	e8 12 cf ff ff       	call   80100348 <panic>
      return &cpus[i];
80103436:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
8010343c:	05 00 28 13 80       	add    $0x80132800,%eax
}
80103441:	c9                   	leave  
80103442:	c3                   	ret    

80103443 <cpuid>:
cpuid() {
80103443:	55                   	push   %ebp
80103444:	89 e5                	mov    %esp,%ebp
80103446:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
80103449:	e8 99 ff ff ff       	call   801033e7 <mycpu>
8010344e:	2d 00 28 13 80       	sub    $0x80132800,%eax
80103453:	c1 f8 04             	sar    $0x4,%eax
80103456:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
8010345c:	c9                   	leave  
8010345d:	c3                   	ret    

8010345e <myproc>:
myproc(void) {
8010345e:	55                   	push   %ebp
8010345f:	89 e5                	mov    %esp,%ebp
80103461:	53                   	push   %ebx
80103462:	83 ec 04             	sub    $0x4,%esp
  pushcli();
80103465:	e8 b9 08 00 00       	call   80103d23 <pushcli>
  c = mycpu();
8010346a:	e8 78 ff ff ff       	call   801033e7 <mycpu>
  p = c->proc;
8010346f:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103475:	e8 e6 08 00 00       	call   80103d60 <popcli>
}
8010347a:	89 d8                	mov    %ebx,%eax
8010347c:	83 c4 04             	add    $0x4,%esp
8010347f:	5b                   	pop    %ebx
80103480:	5d                   	pop    %ebp
80103481:	c3                   	ret    

80103482 <userinit>:
{
80103482:	55                   	push   %ebp
80103483:	89 e5                	mov    %esp,%ebp
80103485:	53                   	push   %ebx
80103486:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
80103489:	e8 3b fe ff ff       	call   801032c9 <allocproc>
8010348e:	89 c3                	mov    %eax,%ebx
  initproc = p;
80103490:	a3 bc a5 10 80       	mov    %eax,0x8010a5bc
  if((p->pgdir = setupkvm()) == 0)
80103495:	e8 27 30 00 00       	call   801064c1 <setupkvm>
8010349a:	89 43 04             	mov    %eax,0x4(%ebx)
8010349d:	85 c0                	test   %eax,%eax
8010349f:	0f 84 b7 00 00 00    	je     8010355c <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
801034a5:	83 ec 04             	sub    $0x4,%esp
801034a8:	68 2c 00 00 00       	push   $0x2c
801034ad:	68 60 a4 10 80       	push   $0x8010a460
801034b2:	50                   	push   %eax
801034b3:	e8 01 2d 00 00       	call   801061b9 <inituvm>
  p->sz = PGSIZE;
801034b8:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
801034be:	83 c4 0c             	add    $0xc,%esp
801034c1:	6a 4c                	push   $0x4c
801034c3:	6a 00                	push   $0x0
801034c5:	ff 73 18             	pushl  0x18(%ebx)
801034c8:	e8 df 09 00 00       	call   80103eac <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801034cd:	8b 43 18             	mov    0x18(%ebx),%eax
801034d0:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801034d6:	8b 43 18             	mov    0x18(%ebx),%eax
801034d9:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
801034df:	8b 43 18             	mov    0x18(%ebx),%eax
801034e2:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801034e6:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801034ea:	8b 43 18             	mov    0x18(%ebx),%eax
801034ed:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801034f1:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801034f5:	8b 43 18             	mov    0x18(%ebx),%eax
801034f8:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801034ff:	8b 43 18             	mov    0x18(%ebx),%eax
80103502:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80103509:	8b 43 18             	mov    0x18(%ebx),%eax
8010350c:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
80103513:	8d 43 6c             	lea    0x6c(%ebx),%eax
80103516:	83 c4 0c             	add    $0xc,%esp
80103519:	6a 10                	push   $0x10
8010351b:	68 c5 6c 10 80       	push   $0x80106cc5
80103520:	50                   	push   %eax
80103521:	e8 ed 0a 00 00       	call   80104013 <safestrcpy>
  p->cwd = namei("/");
80103526:	c7 04 24 ce 6c 10 80 	movl   $0x80106cce,(%esp)
8010352d:	e8 af e6 ff ff       	call   80101be1 <namei>
80103532:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
80103535:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
8010353c:	e8 bf 08 00 00       	call   80103e00 <acquire>
  p->state = RUNNABLE;
80103541:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
80103548:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
8010354f:	e8 11 09 00 00       	call   80103e65 <release>
}
80103554:	83 c4 10             	add    $0x10,%esp
80103557:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010355a:	c9                   	leave  
8010355b:	c3                   	ret    
    panic("userinit: out of memory?");
8010355c:	83 ec 0c             	sub    $0xc,%esp
8010355f:	68 ac 6c 10 80       	push   $0x80106cac
80103564:	e8 df cd ff ff       	call   80100348 <panic>

80103569 <growproc>:
{
80103569:	55                   	push   %ebp
8010356a:	89 e5                	mov    %esp,%ebp
8010356c:	56                   	push   %esi
8010356d:	53                   	push   %ebx
8010356e:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
80103571:	e8 e8 fe ff ff       	call   8010345e <myproc>
80103576:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
80103578:	8b 00                	mov    (%eax),%eax
  if(n > 0){
8010357a:	85 f6                	test   %esi,%esi
8010357c:	7f 21                	jg     8010359f <growproc+0x36>
  } else if(n < 0){
8010357e:	85 f6                	test   %esi,%esi
80103580:	79 33                	jns    801035b5 <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103582:	83 ec 04             	sub    $0x4,%esp
80103585:	01 c6                	add    %eax,%esi
80103587:	56                   	push   %esi
80103588:	50                   	push   %eax
80103589:	ff 73 04             	pushl  0x4(%ebx)
8010358c:	e8 36 2d 00 00       	call   801062c7 <deallocuvm>
80103591:	83 c4 10             	add    $0x10,%esp
80103594:	85 c0                	test   %eax,%eax
80103596:	75 1d                	jne    801035b5 <growproc+0x4c>
      return -1;
80103598:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010359d:	eb 29                	jmp    801035c8 <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
8010359f:	83 ec 04             	sub    $0x4,%esp
801035a2:	01 c6                	add    %eax,%esi
801035a4:	56                   	push   %esi
801035a5:	50                   	push   %eax
801035a6:	ff 73 04             	pushl  0x4(%ebx)
801035a9:	e8 ab 2d 00 00       	call   80106359 <allocuvm>
801035ae:	83 c4 10             	add    $0x10,%esp
801035b1:	85 c0                	test   %eax,%eax
801035b3:	74 1a                	je     801035cf <growproc+0x66>
  curproc->sz = sz;
801035b5:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
801035b7:	83 ec 0c             	sub    $0xc,%esp
801035ba:	53                   	push   %ebx
801035bb:	e8 e1 2a 00 00       	call   801060a1 <switchuvm>
  return 0;
801035c0:	83 c4 10             	add    $0x10,%esp
801035c3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801035c8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801035cb:	5b                   	pop    %ebx
801035cc:	5e                   	pop    %esi
801035cd:	5d                   	pop    %ebp
801035ce:	c3                   	ret    
      return -1;
801035cf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801035d4:	eb f2                	jmp    801035c8 <growproc+0x5f>

801035d6 <fork>:
{
801035d6:	55                   	push   %ebp
801035d7:	89 e5                	mov    %esp,%ebp
801035d9:	57                   	push   %edi
801035da:	56                   	push   %esi
801035db:	53                   	push   %ebx
801035dc:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
801035df:	e8 7a fe ff ff       	call   8010345e <myproc>
801035e4:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
801035e6:	e8 de fc ff ff       	call   801032c9 <allocproc>
801035eb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801035ee:	85 c0                	test   %eax,%eax
801035f0:	0f 84 e3 00 00 00    	je     801036d9 <fork+0x103>
801035f6:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz, np->pid)) == 0){
801035f8:	83 ec 04             	sub    $0x4,%esp
801035fb:	ff 70 10             	pushl  0x10(%eax)
801035fe:	ff 33                	pushl  (%ebx)
80103600:	ff 73 04             	pushl  0x4(%ebx)
80103603:	e8 72 2f 00 00       	call   8010657a <copyuvm>
80103608:	89 47 04             	mov    %eax,0x4(%edi)
8010360b:	83 c4 10             	add    $0x10,%esp
8010360e:	85 c0                	test   %eax,%eax
80103610:	74 2a                	je     8010363c <fork+0x66>
  np->sz = curproc->sz;
80103612:	8b 03                	mov    (%ebx),%eax
80103614:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80103617:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
80103619:	89 c8                	mov    %ecx,%eax
8010361b:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
8010361e:	8b 73 18             	mov    0x18(%ebx),%esi
80103621:	8b 79 18             	mov    0x18(%ecx),%edi
80103624:	b9 13 00 00 00       	mov    $0x13,%ecx
80103629:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
8010362b:	8b 40 18             	mov    0x18(%eax),%eax
8010362e:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
80103635:	be 00 00 00 00       	mov    $0x0,%esi
8010363a:	eb 29                	jmp    80103665 <fork+0x8f>
    kfree(np->kstack);
8010363c:	83 ec 0c             	sub    $0xc,%esp
8010363f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80103642:	ff 73 08             	pushl  0x8(%ebx)
80103645:	e8 5a e9 ff ff       	call   80101fa4 <kfree>
    np->kstack = 0;
8010364a:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
80103651:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
80103658:	83 c4 10             	add    $0x10,%esp
8010365b:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103660:	eb 6d                	jmp    801036cf <fork+0xf9>
  for(i = 0; i < NOFILE; i++)
80103662:	83 c6 01             	add    $0x1,%esi
80103665:	83 fe 0f             	cmp    $0xf,%esi
80103668:	7f 1d                	jg     80103687 <fork+0xb1>
    if(curproc->ofile[i])
8010366a:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
8010366e:	85 c0                	test   %eax,%eax
80103670:	74 f0                	je     80103662 <fork+0x8c>
      np->ofile[i] = filedup(curproc->ofile[i]);
80103672:	83 ec 0c             	sub    $0xc,%esp
80103675:	50                   	push   %eax
80103676:	e8 13 d6 ff ff       	call   80100c8e <filedup>
8010367b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010367e:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
80103682:	83 c4 10             	add    $0x10,%esp
80103685:	eb db                	jmp    80103662 <fork+0x8c>
  np->cwd = idup(curproc->cwd);
80103687:	83 ec 0c             	sub    $0xc,%esp
8010368a:	ff 73 68             	pushl  0x68(%ebx)
8010368d:	e8 bf de ff ff       	call   80101551 <idup>
80103692:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103695:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103698:	83 c3 6c             	add    $0x6c,%ebx
8010369b:	8d 47 6c             	lea    0x6c(%edi),%eax
8010369e:	83 c4 0c             	add    $0xc,%esp
801036a1:	6a 10                	push   $0x10
801036a3:	53                   	push   %ebx
801036a4:	50                   	push   %eax
801036a5:	e8 69 09 00 00       	call   80104013 <safestrcpy>
  pid = np->pid;
801036aa:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
801036ad:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
801036b4:	e8 47 07 00 00       	call   80103e00 <acquire>
  np->state = RUNNABLE;
801036b9:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
801036c0:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
801036c7:	e8 99 07 00 00       	call   80103e65 <release>
  return pid;
801036cc:	83 c4 10             	add    $0x10,%esp
}
801036cf:	89 d8                	mov    %ebx,%eax
801036d1:	8d 65 f4             	lea    -0xc(%ebp),%esp
801036d4:	5b                   	pop    %ebx
801036d5:	5e                   	pop    %esi
801036d6:	5f                   	pop    %edi
801036d7:	5d                   	pop    %ebp
801036d8:	c3                   	ret    
    return -1;
801036d9:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801036de:	eb ef                	jmp    801036cf <fork+0xf9>

801036e0 <scheduler>:
{
801036e0:	55                   	push   %ebp
801036e1:	89 e5                	mov    %esp,%ebp
801036e3:	56                   	push   %esi
801036e4:	53                   	push   %ebx
  struct cpu *c = mycpu();
801036e5:	e8 fd fc ff ff       	call   801033e7 <mycpu>
801036ea:	89 c6                	mov    %eax,%esi
  c->proc = 0;
801036ec:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
801036f3:	00 00 00 
801036f6:	eb 5a                	jmp    80103752 <scheduler+0x72>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801036f8:	83 c3 7c             	add    $0x7c,%ebx
801036fb:	81 fb d4 4c 13 80    	cmp    $0x80134cd4,%ebx
80103701:	73 3f                	jae    80103742 <scheduler+0x62>
      if(p->state != RUNNABLE)
80103703:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
80103707:	75 ef                	jne    801036f8 <scheduler+0x18>
      c->proc = p;
80103709:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
8010370f:	83 ec 0c             	sub    $0xc,%esp
80103712:	53                   	push   %ebx
80103713:	e8 89 29 00 00       	call   801060a1 <switchuvm>
      p->state = RUNNING;
80103718:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
8010371f:	83 c4 08             	add    $0x8,%esp
80103722:	ff 73 1c             	pushl  0x1c(%ebx)
80103725:	8d 46 04             	lea    0x4(%esi),%eax
80103728:	50                   	push   %eax
80103729:	e8 38 09 00 00       	call   80104066 <swtch>
      switchkvm();
8010372e:	e8 5c 29 00 00       	call   8010608f <switchkvm>
      c->proc = 0;
80103733:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
8010373a:	00 00 00 
8010373d:	83 c4 10             	add    $0x10,%esp
80103740:	eb b6                	jmp    801036f8 <scheduler+0x18>
    release(&ptable.lock);
80103742:	83 ec 0c             	sub    $0xc,%esp
80103745:	68 a0 2d 13 80       	push   $0x80132da0
8010374a:	e8 16 07 00 00       	call   80103e65 <release>
    sti();
8010374f:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
80103752:	fb                   	sti    
    acquire(&ptable.lock);
80103753:	83 ec 0c             	sub    $0xc,%esp
80103756:	68 a0 2d 13 80       	push   $0x80132da0
8010375b:	e8 a0 06 00 00       	call   80103e00 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103760:	83 c4 10             	add    $0x10,%esp
80103763:	bb d4 2d 13 80       	mov    $0x80132dd4,%ebx
80103768:	eb 91                	jmp    801036fb <scheduler+0x1b>

8010376a <sched>:
{
8010376a:	55                   	push   %ebp
8010376b:	89 e5                	mov    %esp,%ebp
8010376d:	56                   	push   %esi
8010376e:	53                   	push   %ebx
  struct proc *p = myproc();
8010376f:	e8 ea fc ff ff       	call   8010345e <myproc>
80103774:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
80103776:	83 ec 0c             	sub    $0xc,%esp
80103779:	68 a0 2d 13 80       	push   $0x80132da0
8010377e:	e8 3d 06 00 00       	call   80103dc0 <holding>
80103783:	83 c4 10             	add    $0x10,%esp
80103786:	85 c0                	test   %eax,%eax
80103788:	74 4f                	je     801037d9 <sched+0x6f>
  if(mycpu()->ncli != 1)
8010378a:	e8 58 fc ff ff       	call   801033e7 <mycpu>
8010378f:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
80103796:	75 4e                	jne    801037e6 <sched+0x7c>
  if(p->state == RUNNING)
80103798:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
8010379c:	74 55                	je     801037f3 <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010379e:	9c                   	pushf  
8010379f:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801037a0:	f6 c4 02             	test   $0x2,%ah
801037a3:	75 5b                	jne    80103800 <sched+0x96>
  intena = mycpu()->intena;
801037a5:	e8 3d fc ff ff       	call   801033e7 <mycpu>
801037aa:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
801037b0:	e8 32 fc ff ff       	call   801033e7 <mycpu>
801037b5:	83 ec 08             	sub    $0x8,%esp
801037b8:	ff 70 04             	pushl  0x4(%eax)
801037bb:	83 c3 1c             	add    $0x1c,%ebx
801037be:	53                   	push   %ebx
801037bf:	e8 a2 08 00 00       	call   80104066 <swtch>
  mycpu()->intena = intena;
801037c4:	e8 1e fc ff ff       	call   801033e7 <mycpu>
801037c9:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
801037cf:	83 c4 10             	add    $0x10,%esp
801037d2:	8d 65 f8             	lea    -0x8(%ebp),%esp
801037d5:	5b                   	pop    %ebx
801037d6:	5e                   	pop    %esi
801037d7:	5d                   	pop    %ebp
801037d8:	c3                   	ret    
    panic("sched ptable.lock");
801037d9:	83 ec 0c             	sub    $0xc,%esp
801037dc:	68 d0 6c 10 80       	push   $0x80106cd0
801037e1:	e8 62 cb ff ff       	call   80100348 <panic>
    panic("sched locks");
801037e6:	83 ec 0c             	sub    $0xc,%esp
801037e9:	68 e2 6c 10 80       	push   $0x80106ce2
801037ee:	e8 55 cb ff ff       	call   80100348 <panic>
    panic("sched running");
801037f3:	83 ec 0c             	sub    $0xc,%esp
801037f6:	68 ee 6c 10 80       	push   $0x80106cee
801037fb:	e8 48 cb ff ff       	call   80100348 <panic>
    panic("sched interruptible");
80103800:	83 ec 0c             	sub    $0xc,%esp
80103803:	68 fc 6c 10 80       	push   $0x80106cfc
80103808:	e8 3b cb ff ff       	call   80100348 <panic>

8010380d <exit>:
{
8010380d:	55                   	push   %ebp
8010380e:	89 e5                	mov    %esp,%ebp
80103810:	56                   	push   %esi
80103811:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103812:	e8 47 fc ff ff       	call   8010345e <myproc>
  if(curproc == initproc)
80103817:	39 05 bc a5 10 80    	cmp    %eax,0x8010a5bc
8010381d:	74 09                	je     80103828 <exit+0x1b>
8010381f:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
80103821:	bb 00 00 00 00       	mov    $0x0,%ebx
80103826:	eb 10                	jmp    80103838 <exit+0x2b>
    panic("init exiting");
80103828:	83 ec 0c             	sub    $0xc,%esp
8010382b:	68 10 6d 10 80       	push   $0x80106d10
80103830:	e8 13 cb ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
80103835:	83 c3 01             	add    $0x1,%ebx
80103838:	83 fb 0f             	cmp    $0xf,%ebx
8010383b:	7f 1e                	jg     8010385b <exit+0x4e>
    if(curproc->ofile[fd]){
8010383d:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
80103841:	85 c0                	test   %eax,%eax
80103843:	74 f0                	je     80103835 <exit+0x28>
      fileclose(curproc->ofile[fd]);
80103845:	83 ec 0c             	sub    $0xc,%esp
80103848:	50                   	push   %eax
80103849:	e8 85 d4 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
8010384e:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
80103855:	00 
80103856:	83 c4 10             	add    $0x10,%esp
80103859:	eb da                	jmp    80103835 <exit+0x28>
  begin_op();
8010385b:	e8 ae f1 ff ff       	call   80102a0e <begin_op>
  iput(curproc->cwd);
80103860:	83 ec 0c             	sub    $0xc,%esp
80103863:	ff 76 68             	pushl  0x68(%esi)
80103866:	e8 1d de ff ff       	call   80101688 <iput>
  end_op();
8010386b:	e8 18 f2 ff ff       	call   80102a88 <end_op>
  curproc->cwd = 0;
80103870:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
80103877:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
8010387e:	e8 7d 05 00 00       	call   80103e00 <acquire>
  wakeup1(curproc->parent);
80103883:	8b 46 14             	mov    0x14(%esi),%eax
80103886:	e8 13 fa ff ff       	call   8010329e <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010388b:	83 c4 10             	add    $0x10,%esp
8010388e:	bb d4 2d 13 80       	mov    $0x80132dd4,%ebx
80103893:	eb 03                	jmp    80103898 <exit+0x8b>
80103895:	83 c3 7c             	add    $0x7c,%ebx
80103898:	81 fb d4 4c 13 80    	cmp    $0x80134cd4,%ebx
8010389e:	73 1a                	jae    801038ba <exit+0xad>
    if(p->parent == curproc){
801038a0:	39 73 14             	cmp    %esi,0x14(%ebx)
801038a3:	75 f0                	jne    80103895 <exit+0x88>
      p->parent = initproc;
801038a5:	a1 bc a5 10 80       	mov    0x8010a5bc,%eax
801038aa:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
801038ad:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
801038b1:	75 e2                	jne    80103895 <exit+0x88>
        wakeup1(initproc);
801038b3:	e8 e6 f9 ff ff       	call   8010329e <wakeup1>
801038b8:	eb db                	jmp    80103895 <exit+0x88>
  curproc->state = ZOMBIE;
801038ba:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
801038c1:	e8 a4 fe ff ff       	call   8010376a <sched>
  panic("zombie exit");
801038c6:	83 ec 0c             	sub    $0xc,%esp
801038c9:	68 1d 6d 10 80       	push   $0x80106d1d
801038ce:	e8 75 ca ff ff       	call   80100348 <panic>

801038d3 <yield>:
{
801038d3:	55                   	push   %ebp
801038d4:	89 e5                	mov    %esp,%ebp
801038d6:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801038d9:	68 a0 2d 13 80       	push   $0x80132da0
801038de:	e8 1d 05 00 00       	call   80103e00 <acquire>
  myproc()->state = RUNNABLE;
801038e3:	e8 76 fb ff ff       	call   8010345e <myproc>
801038e8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801038ef:	e8 76 fe ff ff       	call   8010376a <sched>
  release(&ptable.lock);
801038f4:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
801038fb:	e8 65 05 00 00       	call   80103e65 <release>
}
80103900:	83 c4 10             	add    $0x10,%esp
80103903:	c9                   	leave  
80103904:	c3                   	ret    

80103905 <sleep>:
{
80103905:	55                   	push   %ebp
80103906:	89 e5                	mov    %esp,%ebp
80103908:	56                   	push   %esi
80103909:	53                   	push   %ebx
8010390a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
8010390d:	e8 4c fb ff ff       	call   8010345e <myproc>
  if(p == 0)
80103912:	85 c0                	test   %eax,%eax
80103914:	74 66                	je     8010397c <sleep+0x77>
80103916:	89 c6                	mov    %eax,%esi
  if(lk == 0)
80103918:	85 db                	test   %ebx,%ebx
8010391a:	74 6d                	je     80103989 <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
8010391c:	81 fb a0 2d 13 80    	cmp    $0x80132da0,%ebx
80103922:	74 18                	je     8010393c <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
80103924:	83 ec 0c             	sub    $0xc,%esp
80103927:	68 a0 2d 13 80       	push   $0x80132da0
8010392c:	e8 cf 04 00 00       	call   80103e00 <acquire>
    release(lk);
80103931:	89 1c 24             	mov    %ebx,(%esp)
80103934:	e8 2c 05 00 00       	call   80103e65 <release>
80103939:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
8010393c:	8b 45 08             	mov    0x8(%ebp),%eax
8010393f:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
80103942:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
80103949:	e8 1c fe ff ff       	call   8010376a <sched>
  p->chan = 0;
8010394e:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
80103955:	81 fb a0 2d 13 80    	cmp    $0x80132da0,%ebx
8010395b:	74 18                	je     80103975 <sleep+0x70>
    release(&ptable.lock);
8010395d:	83 ec 0c             	sub    $0xc,%esp
80103960:	68 a0 2d 13 80       	push   $0x80132da0
80103965:	e8 fb 04 00 00       	call   80103e65 <release>
    acquire(lk);
8010396a:	89 1c 24             	mov    %ebx,(%esp)
8010396d:	e8 8e 04 00 00       	call   80103e00 <acquire>
80103972:	83 c4 10             	add    $0x10,%esp
}
80103975:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103978:	5b                   	pop    %ebx
80103979:	5e                   	pop    %esi
8010397a:	5d                   	pop    %ebp
8010397b:	c3                   	ret    
    panic("sleep");
8010397c:	83 ec 0c             	sub    $0xc,%esp
8010397f:	68 29 6d 10 80       	push   $0x80106d29
80103984:	e8 bf c9 ff ff       	call   80100348 <panic>
    panic("sleep without lk");
80103989:	83 ec 0c             	sub    $0xc,%esp
8010398c:	68 2f 6d 10 80       	push   $0x80106d2f
80103991:	e8 b2 c9 ff ff       	call   80100348 <panic>

80103996 <wait>:
{
80103996:	55                   	push   %ebp
80103997:	89 e5                	mov    %esp,%ebp
80103999:	56                   	push   %esi
8010399a:	53                   	push   %ebx
  struct proc *curproc = myproc();
8010399b:	e8 be fa ff ff       	call   8010345e <myproc>
801039a0:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
801039a2:	83 ec 0c             	sub    $0xc,%esp
801039a5:	68 a0 2d 13 80       	push   $0x80132da0
801039aa:	e8 51 04 00 00       	call   80103e00 <acquire>
801039af:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
801039b2:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039b7:	bb d4 2d 13 80       	mov    $0x80132dd4,%ebx
801039bc:	eb 5b                	jmp    80103a19 <wait+0x83>
        pid = p->pid;
801039be:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
801039c1:	83 ec 0c             	sub    $0xc,%esp
801039c4:	ff 73 08             	pushl  0x8(%ebx)
801039c7:	e8 d8 e5 ff ff       	call   80101fa4 <kfree>
        p->kstack = 0;
801039cc:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
801039d3:	83 c4 04             	add    $0x4,%esp
801039d6:	ff 73 04             	pushl  0x4(%ebx)
801039d9:	e8 73 2a 00 00       	call   80106451 <freevm>
        p->pid = 0;
801039de:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
801039e5:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
801039ec:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
801039f0:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
801039f7:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
801039fe:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
80103a05:	e8 5b 04 00 00       	call   80103e65 <release>
        return pid;
80103a0a:	83 c4 10             	add    $0x10,%esp
}
80103a0d:	89 f0                	mov    %esi,%eax
80103a0f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a12:	5b                   	pop    %ebx
80103a13:	5e                   	pop    %esi
80103a14:	5d                   	pop    %ebp
80103a15:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103a16:	83 c3 7c             	add    $0x7c,%ebx
80103a19:	81 fb d4 4c 13 80    	cmp    $0x80134cd4,%ebx
80103a1f:	73 12                	jae    80103a33 <wait+0x9d>
      if(p->parent != curproc)
80103a21:	39 73 14             	cmp    %esi,0x14(%ebx)
80103a24:	75 f0                	jne    80103a16 <wait+0x80>
      if(p->state == ZOMBIE){
80103a26:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103a2a:	74 92                	je     801039be <wait+0x28>
      havekids = 1;
80103a2c:	b8 01 00 00 00       	mov    $0x1,%eax
80103a31:	eb e3                	jmp    80103a16 <wait+0x80>
    if(!havekids || curproc->killed){
80103a33:	85 c0                	test   %eax,%eax
80103a35:	74 06                	je     80103a3d <wait+0xa7>
80103a37:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
80103a3b:	74 17                	je     80103a54 <wait+0xbe>
      release(&ptable.lock);
80103a3d:	83 ec 0c             	sub    $0xc,%esp
80103a40:	68 a0 2d 13 80       	push   $0x80132da0
80103a45:	e8 1b 04 00 00       	call   80103e65 <release>
      return -1;
80103a4a:	83 c4 10             	add    $0x10,%esp
80103a4d:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103a52:	eb b9                	jmp    80103a0d <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80103a54:	83 ec 08             	sub    $0x8,%esp
80103a57:	68 a0 2d 13 80       	push   $0x80132da0
80103a5c:	56                   	push   %esi
80103a5d:	e8 a3 fe ff ff       	call   80103905 <sleep>
    havekids = 0;
80103a62:	83 c4 10             	add    $0x10,%esp
80103a65:	e9 48 ff ff ff       	jmp    801039b2 <wait+0x1c>

80103a6a <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80103a6a:	55                   	push   %ebp
80103a6b:	89 e5                	mov    %esp,%ebp
80103a6d:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
80103a70:	68 a0 2d 13 80       	push   $0x80132da0
80103a75:	e8 86 03 00 00       	call   80103e00 <acquire>
  wakeup1(chan);
80103a7a:	8b 45 08             	mov    0x8(%ebp),%eax
80103a7d:	e8 1c f8 ff ff       	call   8010329e <wakeup1>
  release(&ptable.lock);
80103a82:	c7 04 24 a0 2d 13 80 	movl   $0x80132da0,(%esp)
80103a89:	e8 d7 03 00 00       	call   80103e65 <release>
}
80103a8e:	83 c4 10             	add    $0x10,%esp
80103a91:	c9                   	leave  
80103a92:	c3                   	ret    

80103a93 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80103a93:	55                   	push   %ebp
80103a94:	89 e5                	mov    %esp,%ebp
80103a96:	53                   	push   %ebx
80103a97:	83 ec 10             	sub    $0x10,%esp
80103a9a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
80103a9d:	68 a0 2d 13 80       	push   $0x80132da0
80103aa2:	e8 59 03 00 00       	call   80103e00 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103aa7:	83 c4 10             	add    $0x10,%esp
80103aaa:	b8 d4 2d 13 80       	mov    $0x80132dd4,%eax
80103aaf:	3d d4 4c 13 80       	cmp    $0x80134cd4,%eax
80103ab4:	73 3a                	jae    80103af0 <kill+0x5d>
    if(p->pid == pid){
80103ab6:	39 58 10             	cmp    %ebx,0x10(%eax)
80103ab9:	74 05                	je     80103ac0 <kill+0x2d>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103abb:	83 c0 7c             	add    $0x7c,%eax
80103abe:	eb ef                	jmp    80103aaf <kill+0x1c>
      p->killed = 1;
80103ac0:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80103ac7:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
80103acb:	74 1a                	je     80103ae7 <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
80103acd:	83 ec 0c             	sub    $0xc,%esp
80103ad0:	68 a0 2d 13 80       	push   $0x80132da0
80103ad5:	e8 8b 03 00 00       	call   80103e65 <release>
      return 0;
80103ada:	83 c4 10             	add    $0x10,%esp
80103add:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
80103ae2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103ae5:	c9                   	leave  
80103ae6:	c3                   	ret    
        p->state = RUNNABLE;
80103ae7:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80103aee:	eb dd                	jmp    80103acd <kill+0x3a>
  release(&ptable.lock);
80103af0:	83 ec 0c             	sub    $0xc,%esp
80103af3:	68 a0 2d 13 80       	push   $0x80132da0
80103af8:	e8 68 03 00 00       	call   80103e65 <release>
  return -1;
80103afd:	83 c4 10             	add    $0x10,%esp
80103b00:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103b05:	eb db                	jmp    80103ae2 <kill+0x4f>

80103b07 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80103b07:	55                   	push   %ebp
80103b08:	89 e5                	mov    %esp,%ebp
80103b0a:	56                   	push   %esi
80103b0b:	53                   	push   %ebx
80103b0c:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103b0f:	bb d4 2d 13 80       	mov    $0x80132dd4,%ebx
80103b14:	eb 33                	jmp    80103b49 <procdump+0x42>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103b16:	b8 40 6d 10 80       	mov    $0x80106d40,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
80103b1b:	8d 53 6c             	lea    0x6c(%ebx),%edx
80103b1e:	52                   	push   %edx
80103b1f:	50                   	push   %eax
80103b20:	ff 73 10             	pushl  0x10(%ebx)
80103b23:	68 44 6d 10 80       	push   $0x80106d44
80103b28:	e8 de ca ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
80103b2d:	83 c4 10             	add    $0x10,%esp
80103b30:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103b34:	74 39                	je     80103b6f <procdump+0x68>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103b36:	83 ec 0c             	sub    $0xc,%esp
80103b39:	68 bb 70 10 80       	push   $0x801070bb
80103b3e:	e8 c8 ca ff ff       	call   8010060b <cprintf>
80103b43:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103b46:	83 c3 7c             	add    $0x7c,%ebx
80103b49:	81 fb d4 4c 13 80    	cmp    $0x80134cd4,%ebx
80103b4f:	73 61                	jae    80103bb2 <procdump+0xab>
    if(p->state == UNUSED)
80103b51:	8b 43 0c             	mov    0xc(%ebx),%eax
80103b54:	85 c0                	test   %eax,%eax
80103b56:	74 ee                	je     80103b46 <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103b58:	83 f8 05             	cmp    $0x5,%eax
80103b5b:	77 b9                	ja     80103b16 <procdump+0xf>
80103b5d:	8b 04 85 a0 6d 10 80 	mov    -0x7fef9260(,%eax,4),%eax
80103b64:	85 c0                	test   %eax,%eax
80103b66:	75 b3                	jne    80103b1b <procdump+0x14>
      state = "???";
80103b68:	b8 40 6d 10 80       	mov    $0x80106d40,%eax
80103b6d:	eb ac                	jmp    80103b1b <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80103b6f:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103b72:	8b 40 0c             	mov    0xc(%eax),%eax
80103b75:	83 c0 08             	add    $0x8,%eax
80103b78:	83 ec 08             	sub    $0x8,%esp
80103b7b:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103b7e:	52                   	push   %edx
80103b7f:	50                   	push   %eax
80103b80:	e8 5a 01 00 00       	call   80103cdf <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103b85:	83 c4 10             	add    $0x10,%esp
80103b88:	be 00 00 00 00       	mov    $0x0,%esi
80103b8d:	eb 14                	jmp    80103ba3 <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103b8f:	83 ec 08             	sub    $0x8,%esp
80103b92:	50                   	push   %eax
80103b93:	68 81 67 10 80       	push   $0x80106781
80103b98:	e8 6e ca ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103b9d:	83 c6 01             	add    $0x1,%esi
80103ba0:	83 c4 10             	add    $0x10,%esp
80103ba3:	83 fe 09             	cmp    $0x9,%esi
80103ba6:	7f 8e                	jg     80103b36 <procdump+0x2f>
80103ba8:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103bac:	85 c0                	test   %eax,%eax
80103bae:	75 df                	jne    80103b8f <procdump+0x88>
80103bb0:	eb 84                	jmp    80103b36 <procdump+0x2f>
  }
80103bb2:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103bb5:	5b                   	pop    %ebx
80103bb6:	5e                   	pop    %esi
80103bb7:	5d                   	pop    %ebp
80103bb8:	c3                   	ret    

80103bb9 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103bb9:	55                   	push   %ebp
80103bba:	89 e5                	mov    %esp,%ebp
80103bbc:	53                   	push   %ebx
80103bbd:	83 ec 0c             	sub    $0xc,%esp
80103bc0:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103bc3:	68 b8 6d 10 80       	push   $0x80106db8
80103bc8:	8d 43 04             	lea    0x4(%ebx),%eax
80103bcb:	50                   	push   %eax
80103bcc:	e8 f3 00 00 00       	call   80103cc4 <initlock>
  lk->name = name;
80103bd1:	8b 45 0c             	mov    0xc(%ebp),%eax
80103bd4:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103bd7:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103bdd:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103be4:	83 c4 10             	add    $0x10,%esp
80103be7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103bea:	c9                   	leave  
80103beb:	c3                   	ret    

80103bec <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103bec:	55                   	push   %ebp
80103bed:	89 e5                	mov    %esp,%ebp
80103bef:	56                   	push   %esi
80103bf0:	53                   	push   %ebx
80103bf1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103bf4:	8d 73 04             	lea    0x4(%ebx),%esi
80103bf7:	83 ec 0c             	sub    $0xc,%esp
80103bfa:	56                   	push   %esi
80103bfb:	e8 00 02 00 00       	call   80103e00 <acquire>
  while (lk->locked) {
80103c00:	83 c4 10             	add    $0x10,%esp
80103c03:	eb 0d                	jmp    80103c12 <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103c05:	83 ec 08             	sub    $0x8,%esp
80103c08:	56                   	push   %esi
80103c09:	53                   	push   %ebx
80103c0a:	e8 f6 fc ff ff       	call   80103905 <sleep>
80103c0f:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103c12:	83 3b 00             	cmpl   $0x0,(%ebx)
80103c15:	75 ee                	jne    80103c05 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103c17:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103c1d:	e8 3c f8 ff ff       	call   8010345e <myproc>
80103c22:	8b 40 10             	mov    0x10(%eax),%eax
80103c25:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103c28:	83 ec 0c             	sub    $0xc,%esp
80103c2b:	56                   	push   %esi
80103c2c:	e8 34 02 00 00       	call   80103e65 <release>
}
80103c31:	83 c4 10             	add    $0x10,%esp
80103c34:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103c37:	5b                   	pop    %ebx
80103c38:	5e                   	pop    %esi
80103c39:	5d                   	pop    %ebp
80103c3a:	c3                   	ret    

80103c3b <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103c3b:	55                   	push   %ebp
80103c3c:	89 e5                	mov    %esp,%ebp
80103c3e:	56                   	push   %esi
80103c3f:	53                   	push   %ebx
80103c40:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103c43:	8d 73 04             	lea    0x4(%ebx),%esi
80103c46:	83 ec 0c             	sub    $0xc,%esp
80103c49:	56                   	push   %esi
80103c4a:	e8 b1 01 00 00       	call   80103e00 <acquire>
  lk->locked = 0;
80103c4f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103c55:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103c5c:	89 1c 24             	mov    %ebx,(%esp)
80103c5f:	e8 06 fe ff ff       	call   80103a6a <wakeup>
  release(&lk->lk);
80103c64:	89 34 24             	mov    %esi,(%esp)
80103c67:	e8 f9 01 00 00       	call   80103e65 <release>
}
80103c6c:	83 c4 10             	add    $0x10,%esp
80103c6f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103c72:	5b                   	pop    %ebx
80103c73:	5e                   	pop    %esi
80103c74:	5d                   	pop    %ebp
80103c75:	c3                   	ret    

80103c76 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103c76:	55                   	push   %ebp
80103c77:	89 e5                	mov    %esp,%ebp
80103c79:	56                   	push   %esi
80103c7a:	53                   	push   %ebx
80103c7b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103c7e:	8d 73 04             	lea    0x4(%ebx),%esi
80103c81:	83 ec 0c             	sub    $0xc,%esp
80103c84:	56                   	push   %esi
80103c85:	e8 76 01 00 00       	call   80103e00 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103c8a:	83 c4 10             	add    $0x10,%esp
80103c8d:	83 3b 00             	cmpl   $0x0,(%ebx)
80103c90:	75 17                	jne    80103ca9 <holdingsleep+0x33>
80103c92:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103c97:	83 ec 0c             	sub    $0xc,%esp
80103c9a:	56                   	push   %esi
80103c9b:	e8 c5 01 00 00       	call   80103e65 <release>
  return r;
}
80103ca0:	89 d8                	mov    %ebx,%eax
80103ca2:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103ca5:	5b                   	pop    %ebx
80103ca6:	5e                   	pop    %esi
80103ca7:	5d                   	pop    %ebp
80103ca8:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103ca9:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103cac:	e8 ad f7 ff ff       	call   8010345e <myproc>
80103cb1:	3b 58 10             	cmp    0x10(%eax),%ebx
80103cb4:	74 07                	je     80103cbd <holdingsleep+0x47>
80103cb6:	bb 00 00 00 00       	mov    $0x0,%ebx
80103cbb:	eb da                	jmp    80103c97 <holdingsleep+0x21>
80103cbd:	bb 01 00 00 00       	mov    $0x1,%ebx
80103cc2:	eb d3                	jmp    80103c97 <holdingsleep+0x21>

80103cc4 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103cc4:	55                   	push   %ebp
80103cc5:	89 e5                	mov    %esp,%ebp
80103cc7:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103cca:	8b 55 0c             	mov    0xc(%ebp),%edx
80103ccd:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103cd0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103cd6:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103cdd:	5d                   	pop    %ebp
80103cde:	c3                   	ret    

80103cdf <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103cdf:	55                   	push   %ebp
80103ce0:	89 e5                	mov    %esp,%ebp
80103ce2:	53                   	push   %ebx
80103ce3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103ce6:	8b 45 08             	mov    0x8(%ebp),%eax
80103ce9:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103cec:	b8 00 00 00 00       	mov    $0x0,%eax
80103cf1:	83 f8 09             	cmp    $0x9,%eax
80103cf4:	7f 25                	jg     80103d1b <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103cf6:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103cfc:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103d02:	77 17                	ja     80103d1b <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103d04:	8b 5a 04             	mov    0x4(%edx),%ebx
80103d07:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103d0a:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103d0c:	83 c0 01             	add    $0x1,%eax
80103d0f:	eb e0                	jmp    80103cf1 <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103d11:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103d18:	83 c0 01             	add    $0x1,%eax
80103d1b:	83 f8 09             	cmp    $0x9,%eax
80103d1e:	7e f1                	jle    80103d11 <getcallerpcs+0x32>
}
80103d20:	5b                   	pop    %ebx
80103d21:	5d                   	pop    %ebp
80103d22:	c3                   	ret    

80103d23 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103d23:	55                   	push   %ebp
80103d24:	89 e5                	mov    %esp,%ebp
80103d26:	53                   	push   %ebx
80103d27:	83 ec 04             	sub    $0x4,%esp
80103d2a:	9c                   	pushf  
80103d2b:	5b                   	pop    %ebx
  asm volatile("cli");
80103d2c:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103d2d:	e8 b5 f6 ff ff       	call   801033e7 <mycpu>
80103d32:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103d39:	74 12                	je     80103d4d <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103d3b:	e8 a7 f6 ff ff       	call   801033e7 <mycpu>
80103d40:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103d47:	83 c4 04             	add    $0x4,%esp
80103d4a:	5b                   	pop    %ebx
80103d4b:	5d                   	pop    %ebp
80103d4c:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103d4d:	e8 95 f6 ff ff       	call   801033e7 <mycpu>
80103d52:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103d58:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103d5e:	eb db                	jmp    80103d3b <pushcli+0x18>

80103d60 <popcli>:

void
popcli(void)
{
80103d60:	55                   	push   %ebp
80103d61:	89 e5                	mov    %esp,%ebp
80103d63:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103d66:	9c                   	pushf  
80103d67:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103d68:	f6 c4 02             	test   $0x2,%ah
80103d6b:	75 28                	jne    80103d95 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103d6d:	e8 75 f6 ff ff       	call   801033e7 <mycpu>
80103d72:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103d78:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103d7b:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103d81:	85 d2                	test   %edx,%edx
80103d83:	78 1d                	js     80103da2 <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103d85:	e8 5d f6 ff ff       	call   801033e7 <mycpu>
80103d8a:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103d91:	74 1c                	je     80103daf <popcli+0x4f>
    sti();
}
80103d93:	c9                   	leave  
80103d94:	c3                   	ret    
    panic("popcli - interruptible");
80103d95:	83 ec 0c             	sub    $0xc,%esp
80103d98:	68 c3 6d 10 80       	push   $0x80106dc3
80103d9d:	e8 a6 c5 ff ff       	call   80100348 <panic>
    panic("popcli");
80103da2:	83 ec 0c             	sub    $0xc,%esp
80103da5:	68 da 6d 10 80       	push   $0x80106dda
80103daa:	e8 99 c5 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103daf:	e8 33 f6 ff ff       	call   801033e7 <mycpu>
80103db4:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103dbb:	74 d6                	je     80103d93 <popcli+0x33>
  asm volatile("sti");
80103dbd:	fb                   	sti    
}
80103dbe:	eb d3                	jmp    80103d93 <popcli+0x33>

80103dc0 <holding>:
{
80103dc0:	55                   	push   %ebp
80103dc1:	89 e5                	mov    %esp,%ebp
80103dc3:	53                   	push   %ebx
80103dc4:	83 ec 04             	sub    $0x4,%esp
80103dc7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103dca:	e8 54 ff ff ff       	call   80103d23 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103dcf:	83 3b 00             	cmpl   $0x0,(%ebx)
80103dd2:	75 12                	jne    80103de6 <holding+0x26>
80103dd4:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103dd9:	e8 82 ff ff ff       	call   80103d60 <popcli>
}
80103dde:	89 d8                	mov    %ebx,%eax
80103de0:	83 c4 04             	add    $0x4,%esp
80103de3:	5b                   	pop    %ebx
80103de4:	5d                   	pop    %ebp
80103de5:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103de6:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103de9:	e8 f9 f5 ff ff       	call   801033e7 <mycpu>
80103dee:	39 c3                	cmp    %eax,%ebx
80103df0:	74 07                	je     80103df9 <holding+0x39>
80103df2:	bb 00 00 00 00       	mov    $0x0,%ebx
80103df7:	eb e0                	jmp    80103dd9 <holding+0x19>
80103df9:	bb 01 00 00 00       	mov    $0x1,%ebx
80103dfe:	eb d9                	jmp    80103dd9 <holding+0x19>

80103e00 <acquire>:
{
80103e00:	55                   	push   %ebp
80103e01:	89 e5                	mov    %esp,%ebp
80103e03:	53                   	push   %ebx
80103e04:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103e07:	e8 17 ff ff ff       	call   80103d23 <pushcli>
  if(holding(lk))
80103e0c:	83 ec 0c             	sub    $0xc,%esp
80103e0f:	ff 75 08             	pushl  0x8(%ebp)
80103e12:	e8 a9 ff ff ff       	call   80103dc0 <holding>
80103e17:	83 c4 10             	add    $0x10,%esp
80103e1a:	85 c0                	test   %eax,%eax
80103e1c:	75 3a                	jne    80103e58 <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103e1e:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103e21:	b8 01 00 00 00       	mov    $0x1,%eax
80103e26:	f0 87 02             	lock xchg %eax,(%edx)
80103e29:	85 c0                	test   %eax,%eax
80103e2b:	75 f1                	jne    80103e1e <acquire+0x1e>
  __sync_synchronize();
80103e2d:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103e32:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103e35:	e8 ad f5 ff ff       	call   801033e7 <mycpu>
80103e3a:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103e3d:	8b 45 08             	mov    0x8(%ebp),%eax
80103e40:	83 c0 0c             	add    $0xc,%eax
80103e43:	83 ec 08             	sub    $0x8,%esp
80103e46:	50                   	push   %eax
80103e47:	8d 45 08             	lea    0x8(%ebp),%eax
80103e4a:	50                   	push   %eax
80103e4b:	e8 8f fe ff ff       	call   80103cdf <getcallerpcs>
}
80103e50:	83 c4 10             	add    $0x10,%esp
80103e53:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103e56:	c9                   	leave  
80103e57:	c3                   	ret    
    panic("acquire");
80103e58:	83 ec 0c             	sub    $0xc,%esp
80103e5b:	68 e1 6d 10 80       	push   $0x80106de1
80103e60:	e8 e3 c4 ff ff       	call   80100348 <panic>

80103e65 <release>:
{
80103e65:	55                   	push   %ebp
80103e66:	89 e5                	mov    %esp,%ebp
80103e68:	53                   	push   %ebx
80103e69:	83 ec 10             	sub    $0x10,%esp
80103e6c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103e6f:	53                   	push   %ebx
80103e70:	e8 4b ff ff ff       	call   80103dc0 <holding>
80103e75:	83 c4 10             	add    $0x10,%esp
80103e78:	85 c0                	test   %eax,%eax
80103e7a:	74 23                	je     80103e9f <release+0x3a>
  lk->pcs[0] = 0;
80103e7c:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103e83:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103e8a:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103e8f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103e95:	e8 c6 fe ff ff       	call   80103d60 <popcli>
}
80103e9a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103e9d:	c9                   	leave  
80103e9e:	c3                   	ret    
    panic("release");
80103e9f:	83 ec 0c             	sub    $0xc,%esp
80103ea2:	68 e9 6d 10 80       	push   $0x80106de9
80103ea7:	e8 9c c4 ff ff       	call   80100348 <panic>

80103eac <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103eac:	55                   	push   %ebp
80103ead:	89 e5                	mov    %esp,%ebp
80103eaf:	57                   	push   %edi
80103eb0:	53                   	push   %ebx
80103eb1:	8b 55 08             	mov    0x8(%ebp),%edx
80103eb4:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103eb7:	f6 c2 03             	test   $0x3,%dl
80103eba:	75 05                	jne    80103ec1 <memset+0x15>
80103ebc:	f6 c1 03             	test   $0x3,%cl
80103ebf:	74 0e                	je     80103ecf <memset+0x23>
  asm volatile("cld; rep stosb" :
80103ec1:	89 d7                	mov    %edx,%edi
80103ec3:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ec6:	fc                   	cld    
80103ec7:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103ec9:	89 d0                	mov    %edx,%eax
80103ecb:	5b                   	pop    %ebx
80103ecc:	5f                   	pop    %edi
80103ecd:	5d                   	pop    %ebp
80103ece:	c3                   	ret    
    c &= 0xFF;
80103ecf:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103ed3:	c1 e9 02             	shr    $0x2,%ecx
80103ed6:	89 f8                	mov    %edi,%eax
80103ed8:	c1 e0 18             	shl    $0x18,%eax
80103edb:	89 fb                	mov    %edi,%ebx
80103edd:	c1 e3 10             	shl    $0x10,%ebx
80103ee0:	09 d8                	or     %ebx,%eax
80103ee2:	89 fb                	mov    %edi,%ebx
80103ee4:	c1 e3 08             	shl    $0x8,%ebx
80103ee7:	09 d8                	or     %ebx,%eax
80103ee9:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103eeb:	89 d7                	mov    %edx,%edi
80103eed:	fc                   	cld    
80103eee:	f3 ab                	rep stos %eax,%es:(%edi)
80103ef0:	eb d7                	jmp    80103ec9 <memset+0x1d>

80103ef2 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103ef2:	55                   	push   %ebp
80103ef3:	89 e5                	mov    %esp,%ebp
80103ef5:	56                   	push   %esi
80103ef6:	53                   	push   %ebx
80103ef7:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103efa:	8b 55 0c             	mov    0xc(%ebp),%edx
80103efd:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103f00:	8d 70 ff             	lea    -0x1(%eax),%esi
80103f03:	85 c0                	test   %eax,%eax
80103f05:	74 1c                	je     80103f23 <memcmp+0x31>
    if(*s1 != *s2)
80103f07:	0f b6 01             	movzbl (%ecx),%eax
80103f0a:	0f b6 1a             	movzbl (%edx),%ebx
80103f0d:	38 d8                	cmp    %bl,%al
80103f0f:	75 0a                	jne    80103f1b <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103f11:	83 c1 01             	add    $0x1,%ecx
80103f14:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103f17:	89 f0                	mov    %esi,%eax
80103f19:	eb e5                	jmp    80103f00 <memcmp+0xe>
      return *s1 - *s2;
80103f1b:	0f b6 c0             	movzbl %al,%eax
80103f1e:	0f b6 db             	movzbl %bl,%ebx
80103f21:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103f23:	5b                   	pop    %ebx
80103f24:	5e                   	pop    %esi
80103f25:	5d                   	pop    %ebp
80103f26:	c3                   	ret    

80103f27 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103f27:	55                   	push   %ebp
80103f28:	89 e5                	mov    %esp,%ebp
80103f2a:	56                   	push   %esi
80103f2b:	53                   	push   %ebx
80103f2c:	8b 45 08             	mov    0x8(%ebp),%eax
80103f2f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103f32:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103f35:	39 c1                	cmp    %eax,%ecx
80103f37:	73 3a                	jae    80103f73 <memmove+0x4c>
80103f39:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103f3c:	39 c3                	cmp    %eax,%ebx
80103f3e:	76 37                	jbe    80103f77 <memmove+0x50>
    s += n;
    d += n;
80103f40:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103f43:	eb 0d                	jmp    80103f52 <memmove+0x2b>
      *--d = *--s;
80103f45:	83 eb 01             	sub    $0x1,%ebx
80103f48:	83 e9 01             	sub    $0x1,%ecx
80103f4b:	0f b6 13             	movzbl (%ebx),%edx
80103f4e:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103f50:	89 f2                	mov    %esi,%edx
80103f52:	8d 72 ff             	lea    -0x1(%edx),%esi
80103f55:	85 d2                	test   %edx,%edx
80103f57:	75 ec                	jne    80103f45 <memmove+0x1e>
80103f59:	eb 14                	jmp    80103f6f <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103f5b:	0f b6 11             	movzbl (%ecx),%edx
80103f5e:	88 13                	mov    %dl,(%ebx)
80103f60:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103f63:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103f66:	89 f2                	mov    %esi,%edx
80103f68:	8d 72 ff             	lea    -0x1(%edx),%esi
80103f6b:	85 d2                	test   %edx,%edx
80103f6d:	75 ec                	jne    80103f5b <memmove+0x34>

  return dst;
}
80103f6f:	5b                   	pop    %ebx
80103f70:	5e                   	pop    %esi
80103f71:	5d                   	pop    %ebp
80103f72:	c3                   	ret    
80103f73:	89 c3                	mov    %eax,%ebx
80103f75:	eb f1                	jmp    80103f68 <memmove+0x41>
80103f77:	89 c3                	mov    %eax,%ebx
80103f79:	eb ed                	jmp    80103f68 <memmove+0x41>

80103f7b <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103f7b:	55                   	push   %ebp
80103f7c:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80103f7e:	ff 75 10             	pushl  0x10(%ebp)
80103f81:	ff 75 0c             	pushl  0xc(%ebp)
80103f84:	ff 75 08             	pushl  0x8(%ebp)
80103f87:	e8 9b ff ff ff       	call   80103f27 <memmove>
}
80103f8c:	c9                   	leave  
80103f8d:	c3                   	ret    

80103f8e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103f8e:	55                   	push   %ebp
80103f8f:	89 e5                	mov    %esp,%ebp
80103f91:	53                   	push   %ebx
80103f92:	8b 55 08             	mov    0x8(%ebp),%edx
80103f95:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103f98:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103f9b:	eb 09                	jmp    80103fa6 <strncmp+0x18>
    n--, p++, q++;
80103f9d:	83 e8 01             	sub    $0x1,%eax
80103fa0:	83 c2 01             	add    $0x1,%edx
80103fa3:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103fa6:	85 c0                	test   %eax,%eax
80103fa8:	74 0b                	je     80103fb5 <strncmp+0x27>
80103faa:	0f b6 1a             	movzbl (%edx),%ebx
80103fad:	84 db                	test   %bl,%bl
80103faf:	74 04                	je     80103fb5 <strncmp+0x27>
80103fb1:	3a 19                	cmp    (%ecx),%bl
80103fb3:	74 e8                	je     80103f9d <strncmp+0xf>
  if(n == 0)
80103fb5:	85 c0                	test   %eax,%eax
80103fb7:	74 0b                	je     80103fc4 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80103fb9:	0f b6 02             	movzbl (%edx),%eax
80103fbc:	0f b6 11             	movzbl (%ecx),%edx
80103fbf:	29 d0                	sub    %edx,%eax
}
80103fc1:	5b                   	pop    %ebx
80103fc2:	5d                   	pop    %ebp
80103fc3:	c3                   	ret    
    return 0;
80103fc4:	b8 00 00 00 00       	mov    $0x0,%eax
80103fc9:	eb f6                	jmp    80103fc1 <strncmp+0x33>

80103fcb <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103fcb:	55                   	push   %ebp
80103fcc:	89 e5                	mov    %esp,%ebp
80103fce:	57                   	push   %edi
80103fcf:	56                   	push   %esi
80103fd0:	53                   	push   %ebx
80103fd1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103fd4:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103fd7:	8b 45 08             	mov    0x8(%ebp),%eax
80103fda:	eb 04                	jmp    80103fe0 <strncpy+0x15>
80103fdc:	89 fb                	mov    %edi,%ebx
80103fde:	89 f0                	mov    %esi,%eax
80103fe0:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103fe3:	85 c9                	test   %ecx,%ecx
80103fe5:	7e 1d                	jle    80104004 <strncpy+0x39>
80103fe7:	8d 7b 01             	lea    0x1(%ebx),%edi
80103fea:	8d 70 01             	lea    0x1(%eax),%esi
80103fed:	0f b6 1b             	movzbl (%ebx),%ebx
80103ff0:	88 18                	mov    %bl,(%eax)
80103ff2:	89 d1                	mov    %edx,%ecx
80103ff4:	84 db                	test   %bl,%bl
80103ff6:	75 e4                	jne    80103fdc <strncpy+0x11>
80103ff8:	89 f0                	mov    %esi,%eax
80103ffa:	eb 08                	jmp    80104004 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80103ffc:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80103fff:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80104001:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80104004:	8d 4a ff             	lea    -0x1(%edx),%ecx
80104007:	85 d2                	test   %edx,%edx
80104009:	7f f1                	jg     80103ffc <strncpy+0x31>
  return os;
}
8010400b:	8b 45 08             	mov    0x8(%ebp),%eax
8010400e:	5b                   	pop    %ebx
8010400f:	5e                   	pop    %esi
80104010:	5f                   	pop    %edi
80104011:	5d                   	pop    %ebp
80104012:	c3                   	ret    

80104013 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80104013:	55                   	push   %ebp
80104014:	89 e5                	mov    %esp,%ebp
80104016:	57                   	push   %edi
80104017:	56                   	push   %esi
80104018:	53                   	push   %ebx
80104019:	8b 45 08             	mov    0x8(%ebp),%eax
8010401c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
8010401f:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
80104022:	85 d2                	test   %edx,%edx
80104024:	7e 23                	jle    80104049 <safestrcpy+0x36>
80104026:	89 c1                	mov    %eax,%ecx
80104028:	eb 04                	jmp    8010402e <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
8010402a:	89 fb                	mov    %edi,%ebx
8010402c:	89 f1                	mov    %esi,%ecx
8010402e:	83 ea 01             	sub    $0x1,%edx
80104031:	85 d2                	test   %edx,%edx
80104033:	7e 11                	jle    80104046 <safestrcpy+0x33>
80104035:	8d 7b 01             	lea    0x1(%ebx),%edi
80104038:	8d 71 01             	lea    0x1(%ecx),%esi
8010403b:	0f b6 1b             	movzbl (%ebx),%ebx
8010403e:	88 19                	mov    %bl,(%ecx)
80104040:	84 db                	test   %bl,%bl
80104042:	75 e6                	jne    8010402a <safestrcpy+0x17>
80104044:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80104046:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80104049:	5b                   	pop    %ebx
8010404a:	5e                   	pop    %esi
8010404b:	5f                   	pop    %edi
8010404c:	5d                   	pop    %ebp
8010404d:	c3                   	ret    

8010404e <strlen>:

int
strlen(const char *s)
{
8010404e:	55                   	push   %ebp
8010404f:	89 e5                	mov    %esp,%ebp
80104051:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80104054:	b8 00 00 00 00       	mov    $0x0,%eax
80104059:	eb 03                	jmp    8010405e <strlen+0x10>
8010405b:	83 c0 01             	add    $0x1,%eax
8010405e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80104062:	75 f7                	jne    8010405b <strlen+0xd>
    ;
  return n;
}
80104064:	5d                   	pop    %ebp
80104065:	c3                   	ret    

80104066 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80104066:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
8010406a:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
8010406e:	55                   	push   %ebp
  pushl %ebx
8010406f:	53                   	push   %ebx
  pushl %esi
80104070:	56                   	push   %esi
  pushl %edi
80104071:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80104072:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80104074:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80104076:	5f                   	pop    %edi
  popl %esi
80104077:	5e                   	pop    %esi
  popl %ebx
80104078:	5b                   	pop    %ebx
  popl %ebp
80104079:	5d                   	pop    %ebp
  ret
8010407a:	c3                   	ret    

8010407b <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
8010407b:	55                   	push   %ebp
8010407c:	89 e5                	mov    %esp,%ebp
8010407e:	53                   	push   %ebx
8010407f:	83 ec 04             	sub    $0x4,%esp
80104082:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80104085:	e8 d4 f3 ff ff       	call   8010345e <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
8010408a:	8b 00                	mov    (%eax),%eax
8010408c:	39 d8                	cmp    %ebx,%eax
8010408e:	76 19                	jbe    801040a9 <fetchint+0x2e>
80104090:	8d 53 04             	lea    0x4(%ebx),%edx
80104093:	39 d0                	cmp    %edx,%eax
80104095:	72 19                	jb     801040b0 <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80104097:	8b 13                	mov    (%ebx),%edx
80104099:	8b 45 0c             	mov    0xc(%ebp),%eax
8010409c:	89 10                	mov    %edx,(%eax)
  return 0;
8010409e:	b8 00 00 00 00       	mov    $0x0,%eax
}
801040a3:	83 c4 04             	add    $0x4,%esp
801040a6:	5b                   	pop    %ebx
801040a7:	5d                   	pop    %ebp
801040a8:	c3                   	ret    
    return -1;
801040a9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040ae:	eb f3                	jmp    801040a3 <fetchint+0x28>
801040b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040b5:	eb ec                	jmp    801040a3 <fetchint+0x28>

801040b7 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
801040b7:	55                   	push   %ebp
801040b8:	89 e5                	mov    %esp,%ebp
801040ba:	53                   	push   %ebx
801040bb:	83 ec 04             	sub    $0x4,%esp
801040be:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
801040c1:	e8 98 f3 ff ff       	call   8010345e <myproc>

  if(addr >= curproc->sz)
801040c6:	39 18                	cmp    %ebx,(%eax)
801040c8:	76 26                	jbe    801040f0 <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
801040ca:	8b 55 0c             	mov    0xc(%ebp),%edx
801040cd:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
801040cf:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
801040d1:	89 d8                	mov    %ebx,%eax
801040d3:	39 d0                	cmp    %edx,%eax
801040d5:	73 0e                	jae    801040e5 <fetchstr+0x2e>
    if(*s == 0)
801040d7:	80 38 00             	cmpb   $0x0,(%eax)
801040da:	74 05                	je     801040e1 <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
801040dc:	83 c0 01             	add    $0x1,%eax
801040df:	eb f2                	jmp    801040d3 <fetchstr+0x1c>
      return s - *pp;
801040e1:	29 d8                	sub    %ebx,%eax
801040e3:	eb 05                	jmp    801040ea <fetchstr+0x33>
  }
  return -1;
801040e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801040ea:	83 c4 04             	add    $0x4,%esp
801040ed:	5b                   	pop    %ebx
801040ee:	5d                   	pop    %ebp
801040ef:	c3                   	ret    
    return -1;
801040f0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040f5:	eb f3                	jmp    801040ea <fetchstr+0x33>

801040f7 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801040f7:	55                   	push   %ebp
801040f8:	89 e5                	mov    %esp,%ebp
801040fa:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
801040fd:	e8 5c f3 ff ff       	call   8010345e <myproc>
80104102:	8b 50 18             	mov    0x18(%eax),%edx
80104105:	8b 45 08             	mov    0x8(%ebp),%eax
80104108:	c1 e0 02             	shl    $0x2,%eax
8010410b:	03 42 44             	add    0x44(%edx),%eax
8010410e:	83 ec 08             	sub    $0x8,%esp
80104111:	ff 75 0c             	pushl  0xc(%ebp)
80104114:	83 c0 04             	add    $0x4,%eax
80104117:	50                   	push   %eax
80104118:	e8 5e ff ff ff       	call   8010407b <fetchint>
}
8010411d:	c9                   	leave  
8010411e:	c3                   	ret    

8010411f <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
8010411f:	55                   	push   %ebp
80104120:	89 e5                	mov    %esp,%ebp
80104122:	56                   	push   %esi
80104123:	53                   	push   %ebx
80104124:	83 ec 10             	sub    $0x10,%esp
80104127:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
8010412a:	e8 2f f3 ff ff       	call   8010345e <myproc>
8010412f:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
80104131:	83 ec 08             	sub    $0x8,%esp
80104134:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104137:	50                   	push   %eax
80104138:	ff 75 08             	pushl  0x8(%ebp)
8010413b:	e8 b7 ff ff ff       	call   801040f7 <argint>
80104140:	83 c4 10             	add    $0x10,%esp
80104143:	85 c0                	test   %eax,%eax
80104145:	78 24                	js     8010416b <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80104147:	85 db                	test   %ebx,%ebx
80104149:	78 27                	js     80104172 <argptr+0x53>
8010414b:	8b 16                	mov    (%esi),%edx
8010414d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104150:	39 c2                	cmp    %eax,%edx
80104152:	76 25                	jbe    80104179 <argptr+0x5a>
80104154:	01 c3                	add    %eax,%ebx
80104156:	39 da                	cmp    %ebx,%edx
80104158:	72 26                	jb     80104180 <argptr+0x61>
    return -1;
  *pp = (char*)i;
8010415a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010415d:	89 02                	mov    %eax,(%edx)
  return 0;
8010415f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104164:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104167:	5b                   	pop    %ebx
80104168:	5e                   	pop    %esi
80104169:	5d                   	pop    %ebp
8010416a:	c3                   	ret    
    return -1;
8010416b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104170:	eb f2                	jmp    80104164 <argptr+0x45>
    return -1;
80104172:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104177:	eb eb                	jmp    80104164 <argptr+0x45>
80104179:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010417e:	eb e4                	jmp    80104164 <argptr+0x45>
80104180:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104185:	eb dd                	jmp    80104164 <argptr+0x45>

80104187 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80104187:	55                   	push   %ebp
80104188:	89 e5                	mov    %esp,%ebp
8010418a:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010418d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104190:	50                   	push   %eax
80104191:	ff 75 08             	pushl  0x8(%ebp)
80104194:	e8 5e ff ff ff       	call   801040f7 <argint>
80104199:	83 c4 10             	add    $0x10,%esp
8010419c:	85 c0                	test   %eax,%eax
8010419e:	78 13                	js     801041b3 <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
801041a0:	83 ec 08             	sub    $0x8,%esp
801041a3:	ff 75 0c             	pushl  0xc(%ebp)
801041a6:	ff 75 f4             	pushl  -0xc(%ebp)
801041a9:	e8 09 ff ff ff       	call   801040b7 <fetchstr>
801041ae:	83 c4 10             	add    $0x10,%esp
}
801041b1:	c9                   	leave  
801041b2:	c3                   	ret    
    return -1;
801041b3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801041b8:	eb f7                	jmp    801041b1 <argstr+0x2a>

801041ba <syscall>:
[SYS_dump_physmem]   sys_dump_physmem,
};

void
syscall(void)
{
801041ba:	55                   	push   %ebp
801041bb:	89 e5                	mov    %esp,%ebp
801041bd:	53                   	push   %ebx
801041be:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
801041c1:	e8 98 f2 ff ff       	call   8010345e <myproc>
801041c6:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
801041c8:	8b 40 18             	mov    0x18(%eax),%eax
801041cb:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
801041ce:	8d 50 ff             	lea    -0x1(%eax),%edx
801041d1:	83 fa 15             	cmp    $0x15,%edx
801041d4:	77 18                	ja     801041ee <syscall+0x34>
801041d6:	8b 14 85 20 6e 10 80 	mov    -0x7fef91e0(,%eax,4),%edx
801041dd:	85 d2                	test   %edx,%edx
801041df:	74 0d                	je     801041ee <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
801041e1:	ff d2                	call   *%edx
801041e3:	8b 53 18             	mov    0x18(%ebx),%edx
801041e6:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
801041e9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801041ec:	c9                   	leave  
801041ed:	c3                   	ret    
            curproc->pid, curproc->name, num);
801041ee:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
801041f1:	50                   	push   %eax
801041f2:	52                   	push   %edx
801041f3:	ff 73 10             	pushl  0x10(%ebx)
801041f6:	68 f1 6d 10 80       	push   $0x80106df1
801041fb:	e8 0b c4 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
80104200:	8b 43 18             	mov    0x18(%ebx),%eax
80104203:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
8010420a:	83 c4 10             	add    $0x10,%esp
}
8010420d:	eb da                	jmp    801041e9 <syscall+0x2f>

8010420f <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
8010420f:	55                   	push   %ebp
80104210:	89 e5                	mov    %esp,%ebp
80104212:	56                   	push   %esi
80104213:	53                   	push   %ebx
80104214:	83 ec 18             	sub    $0x18,%esp
80104217:	89 d6                	mov    %edx,%esi
80104219:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010421b:	8d 55 f4             	lea    -0xc(%ebp),%edx
8010421e:	52                   	push   %edx
8010421f:	50                   	push   %eax
80104220:	e8 d2 fe ff ff       	call   801040f7 <argint>
80104225:	83 c4 10             	add    $0x10,%esp
80104228:	85 c0                	test   %eax,%eax
8010422a:	78 2e                	js     8010425a <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
8010422c:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
80104230:	77 2f                	ja     80104261 <argfd+0x52>
80104232:	e8 27 f2 ff ff       	call   8010345e <myproc>
80104237:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010423a:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
8010423e:	85 c0                	test   %eax,%eax
80104240:	74 26                	je     80104268 <argfd+0x59>
    return -1;
  if(pfd)
80104242:	85 f6                	test   %esi,%esi
80104244:	74 02                	je     80104248 <argfd+0x39>
    *pfd = fd;
80104246:	89 16                	mov    %edx,(%esi)
  if(pf)
80104248:	85 db                	test   %ebx,%ebx
8010424a:	74 23                	je     8010426f <argfd+0x60>
    *pf = f;
8010424c:	89 03                	mov    %eax,(%ebx)
  return 0;
8010424e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104253:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104256:	5b                   	pop    %ebx
80104257:	5e                   	pop    %esi
80104258:	5d                   	pop    %ebp
80104259:	c3                   	ret    
    return -1;
8010425a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010425f:	eb f2                	jmp    80104253 <argfd+0x44>
    return -1;
80104261:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104266:	eb eb                	jmp    80104253 <argfd+0x44>
80104268:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010426d:	eb e4                	jmp    80104253 <argfd+0x44>
  return 0;
8010426f:	b8 00 00 00 00       	mov    $0x0,%eax
80104274:	eb dd                	jmp    80104253 <argfd+0x44>

80104276 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80104276:	55                   	push   %ebp
80104277:	89 e5                	mov    %esp,%ebp
80104279:	53                   	push   %ebx
8010427a:	83 ec 04             	sub    $0x4,%esp
8010427d:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
8010427f:	e8 da f1 ff ff       	call   8010345e <myproc>

  for(fd = 0; fd < NOFILE; fd++){
80104284:	ba 00 00 00 00       	mov    $0x0,%edx
80104289:	83 fa 0f             	cmp    $0xf,%edx
8010428c:	7f 18                	jg     801042a6 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
8010428e:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
80104293:	74 05                	je     8010429a <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
80104295:	83 c2 01             	add    $0x1,%edx
80104298:	eb ef                	jmp    80104289 <fdalloc+0x13>
      curproc->ofile[fd] = f;
8010429a:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
8010429e:	89 d0                	mov    %edx,%eax
801042a0:	83 c4 04             	add    $0x4,%esp
801042a3:	5b                   	pop    %ebx
801042a4:	5d                   	pop    %ebp
801042a5:	c3                   	ret    
  return -1;
801042a6:	ba ff ff ff ff       	mov    $0xffffffff,%edx
801042ab:	eb f1                	jmp    8010429e <fdalloc+0x28>

801042ad <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801042ad:	55                   	push   %ebp
801042ae:	89 e5                	mov    %esp,%ebp
801042b0:	56                   	push   %esi
801042b1:	53                   	push   %ebx
801042b2:	83 ec 10             	sub    $0x10,%esp
801042b5:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801042b7:	b8 20 00 00 00       	mov    $0x20,%eax
801042bc:	89 c6                	mov    %eax,%esi
801042be:	39 43 58             	cmp    %eax,0x58(%ebx)
801042c1:	76 2e                	jbe    801042f1 <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801042c3:	6a 10                	push   $0x10
801042c5:	50                   	push   %eax
801042c6:	8d 45 e8             	lea    -0x18(%ebp),%eax
801042c9:	50                   	push   %eax
801042ca:	53                   	push   %ebx
801042cb:	e8 a3 d4 ff ff       	call   80101773 <readi>
801042d0:	83 c4 10             	add    $0x10,%esp
801042d3:	83 f8 10             	cmp    $0x10,%eax
801042d6:	75 0c                	jne    801042e4 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
801042d8:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
801042dd:	75 1e                	jne    801042fd <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801042df:	8d 46 10             	lea    0x10(%esi),%eax
801042e2:	eb d8                	jmp    801042bc <isdirempty+0xf>
      panic("isdirempty: readi");
801042e4:	83 ec 0c             	sub    $0xc,%esp
801042e7:	68 7c 6e 10 80       	push   $0x80106e7c
801042ec:	e8 57 c0 ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
801042f1:	b8 01 00 00 00       	mov    $0x1,%eax
}
801042f6:	8d 65 f8             	lea    -0x8(%ebp),%esp
801042f9:	5b                   	pop    %ebx
801042fa:	5e                   	pop    %esi
801042fb:	5d                   	pop    %ebp
801042fc:	c3                   	ret    
      return 0;
801042fd:	b8 00 00 00 00       	mov    $0x0,%eax
80104302:	eb f2                	jmp    801042f6 <isdirempty+0x49>

80104304 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
80104304:	55                   	push   %ebp
80104305:	89 e5                	mov    %esp,%ebp
80104307:	57                   	push   %edi
80104308:	56                   	push   %esi
80104309:	53                   	push   %ebx
8010430a:	83 ec 44             	sub    $0x44,%esp
8010430d:	89 55 c4             	mov    %edx,-0x3c(%ebp)
80104310:	89 4d c0             	mov    %ecx,-0x40(%ebp)
80104313:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80104316:	8d 55 d6             	lea    -0x2a(%ebp),%edx
80104319:	52                   	push   %edx
8010431a:	50                   	push   %eax
8010431b:	e8 d9 d8 ff ff       	call   80101bf9 <nameiparent>
80104320:	89 c6                	mov    %eax,%esi
80104322:	83 c4 10             	add    $0x10,%esp
80104325:	85 c0                	test   %eax,%eax
80104327:	0f 84 3a 01 00 00    	je     80104467 <create+0x163>
    return 0;
  ilock(dp);
8010432d:	83 ec 0c             	sub    $0xc,%esp
80104330:	50                   	push   %eax
80104331:	e8 4b d2 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80104336:	83 c4 0c             	add    $0xc,%esp
80104339:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010433c:	50                   	push   %eax
8010433d:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104340:	50                   	push   %eax
80104341:	56                   	push   %esi
80104342:	e8 69 d6 ff ff       	call   801019b0 <dirlookup>
80104347:	89 c3                	mov    %eax,%ebx
80104349:	83 c4 10             	add    $0x10,%esp
8010434c:	85 c0                	test   %eax,%eax
8010434e:	74 3f                	je     8010438f <create+0x8b>
    iunlockput(dp);
80104350:	83 ec 0c             	sub    $0xc,%esp
80104353:	56                   	push   %esi
80104354:	e8 cf d3 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
80104359:	89 1c 24             	mov    %ebx,(%esp)
8010435c:	e8 20 d2 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80104361:	83 c4 10             	add    $0x10,%esp
80104364:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
80104369:	75 11                	jne    8010437c <create+0x78>
8010436b:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
80104370:	75 0a                	jne    8010437c <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
80104372:	89 d8                	mov    %ebx,%eax
80104374:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104377:	5b                   	pop    %ebx
80104378:	5e                   	pop    %esi
80104379:	5f                   	pop    %edi
8010437a:	5d                   	pop    %ebp
8010437b:	c3                   	ret    
    iunlockput(ip);
8010437c:	83 ec 0c             	sub    $0xc,%esp
8010437f:	53                   	push   %ebx
80104380:	e8 a3 d3 ff ff       	call   80101728 <iunlockput>
    return 0;
80104385:	83 c4 10             	add    $0x10,%esp
80104388:	bb 00 00 00 00       	mov    $0x0,%ebx
8010438d:	eb e3                	jmp    80104372 <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
8010438f:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
80104393:	83 ec 08             	sub    $0x8,%esp
80104396:	50                   	push   %eax
80104397:	ff 36                	pushl  (%esi)
80104399:	e8 e0 cf ff ff       	call   8010137e <ialloc>
8010439e:	89 c3                	mov    %eax,%ebx
801043a0:	83 c4 10             	add    $0x10,%esp
801043a3:	85 c0                	test   %eax,%eax
801043a5:	74 55                	je     801043fc <create+0xf8>
  ilock(ip);
801043a7:	83 ec 0c             	sub    $0xc,%esp
801043aa:	50                   	push   %eax
801043ab:	e8 d1 d1 ff ff       	call   80101581 <ilock>
  ip->major = major;
801043b0:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
801043b4:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
801043b8:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
801043bc:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
801043c2:	89 1c 24             	mov    %ebx,(%esp)
801043c5:	e8 56 d0 ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
801043ca:	83 c4 10             	add    $0x10,%esp
801043cd:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
801043d2:	74 35                	je     80104409 <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
801043d4:	83 ec 04             	sub    $0x4,%esp
801043d7:	ff 73 04             	pushl  0x4(%ebx)
801043da:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801043dd:	50                   	push   %eax
801043de:	56                   	push   %esi
801043df:	e8 4c d7 ff ff       	call   80101b30 <dirlink>
801043e4:	83 c4 10             	add    $0x10,%esp
801043e7:	85 c0                	test   %eax,%eax
801043e9:	78 6f                	js     8010445a <create+0x156>
  iunlockput(dp);
801043eb:	83 ec 0c             	sub    $0xc,%esp
801043ee:	56                   	push   %esi
801043ef:	e8 34 d3 ff ff       	call   80101728 <iunlockput>
  return ip;
801043f4:	83 c4 10             	add    $0x10,%esp
801043f7:	e9 76 ff ff ff       	jmp    80104372 <create+0x6e>
    panic("create: ialloc");
801043fc:	83 ec 0c             	sub    $0xc,%esp
801043ff:	68 8e 6e 10 80       	push   $0x80106e8e
80104404:	e8 3f bf ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
80104409:	0f b7 46 56          	movzwl 0x56(%esi),%eax
8010440d:	83 c0 01             	add    $0x1,%eax
80104410:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104414:	83 ec 0c             	sub    $0xc,%esp
80104417:	56                   	push   %esi
80104418:	e8 03 d0 ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
8010441d:	83 c4 0c             	add    $0xc,%esp
80104420:	ff 73 04             	pushl  0x4(%ebx)
80104423:	68 9e 6e 10 80       	push   $0x80106e9e
80104428:	53                   	push   %ebx
80104429:	e8 02 d7 ff ff       	call   80101b30 <dirlink>
8010442e:	83 c4 10             	add    $0x10,%esp
80104431:	85 c0                	test   %eax,%eax
80104433:	78 18                	js     8010444d <create+0x149>
80104435:	83 ec 04             	sub    $0x4,%esp
80104438:	ff 76 04             	pushl  0x4(%esi)
8010443b:	68 9d 6e 10 80       	push   $0x80106e9d
80104440:	53                   	push   %ebx
80104441:	e8 ea d6 ff ff       	call   80101b30 <dirlink>
80104446:	83 c4 10             	add    $0x10,%esp
80104449:	85 c0                	test   %eax,%eax
8010444b:	79 87                	jns    801043d4 <create+0xd0>
      panic("create dots");
8010444d:	83 ec 0c             	sub    $0xc,%esp
80104450:	68 a0 6e 10 80       	push   $0x80106ea0
80104455:	e8 ee be ff ff       	call   80100348 <panic>
    panic("create: dirlink");
8010445a:	83 ec 0c             	sub    $0xc,%esp
8010445d:	68 ac 6e 10 80       	push   $0x80106eac
80104462:	e8 e1 be ff ff       	call   80100348 <panic>
    return 0;
80104467:	89 c3                	mov    %eax,%ebx
80104469:	e9 04 ff ff ff       	jmp    80104372 <create+0x6e>

8010446e <sys_dup>:
{
8010446e:	55                   	push   %ebp
8010446f:	89 e5                	mov    %esp,%ebp
80104471:	53                   	push   %ebx
80104472:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
80104475:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104478:	ba 00 00 00 00       	mov    $0x0,%edx
8010447d:	b8 00 00 00 00       	mov    $0x0,%eax
80104482:	e8 88 fd ff ff       	call   8010420f <argfd>
80104487:	85 c0                	test   %eax,%eax
80104489:	78 23                	js     801044ae <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
8010448b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010448e:	e8 e3 fd ff ff       	call   80104276 <fdalloc>
80104493:	89 c3                	mov    %eax,%ebx
80104495:	85 c0                	test   %eax,%eax
80104497:	78 1c                	js     801044b5 <sys_dup+0x47>
  filedup(f);
80104499:	83 ec 0c             	sub    $0xc,%esp
8010449c:	ff 75 f4             	pushl  -0xc(%ebp)
8010449f:	e8 ea c7 ff ff       	call   80100c8e <filedup>
  return fd;
801044a4:	83 c4 10             	add    $0x10,%esp
}
801044a7:	89 d8                	mov    %ebx,%eax
801044a9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801044ac:	c9                   	leave  
801044ad:	c3                   	ret    
    return -1;
801044ae:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801044b3:	eb f2                	jmp    801044a7 <sys_dup+0x39>
    return -1;
801044b5:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801044ba:	eb eb                	jmp    801044a7 <sys_dup+0x39>

801044bc <sys_read>:
{
801044bc:	55                   	push   %ebp
801044bd:	89 e5                	mov    %esp,%ebp
801044bf:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801044c2:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801044c5:	ba 00 00 00 00       	mov    $0x0,%edx
801044ca:	b8 00 00 00 00       	mov    $0x0,%eax
801044cf:	e8 3b fd ff ff       	call   8010420f <argfd>
801044d4:	85 c0                	test   %eax,%eax
801044d6:	78 43                	js     8010451b <sys_read+0x5f>
801044d8:	83 ec 08             	sub    $0x8,%esp
801044db:	8d 45 f0             	lea    -0x10(%ebp),%eax
801044de:	50                   	push   %eax
801044df:	6a 02                	push   $0x2
801044e1:	e8 11 fc ff ff       	call   801040f7 <argint>
801044e6:	83 c4 10             	add    $0x10,%esp
801044e9:	85 c0                	test   %eax,%eax
801044eb:	78 35                	js     80104522 <sys_read+0x66>
801044ed:	83 ec 04             	sub    $0x4,%esp
801044f0:	ff 75 f0             	pushl  -0x10(%ebp)
801044f3:	8d 45 ec             	lea    -0x14(%ebp),%eax
801044f6:	50                   	push   %eax
801044f7:	6a 01                	push   $0x1
801044f9:	e8 21 fc ff ff       	call   8010411f <argptr>
801044fe:	83 c4 10             	add    $0x10,%esp
80104501:	85 c0                	test   %eax,%eax
80104503:	78 24                	js     80104529 <sys_read+0x6d>
  return fileread(f, p, n);
80104505:	83 ec 04             	sub    $0x4,%esp
80104508:	ff 75 f0             	pushl  -0x10(%ebp)
8010450b:	ff 75 ec             	pushl  -0x14(%ebp)
8010450e:	ff 75 f4             	pushl  -0xc(%ebp)
80104511:	e8 c1 c8 ff ff       	call   80100dd7 <fileread>
80104516:	83 c4 10             	add    $0x10,%esp
}
80104519:	c9                   	leave  
8010451a:	c3                   	ret    
    return -1;
8010451b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104520:	eb f7                	jmp    80104519 <sys_read+0x5d>
80104522:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104527:	eb f0                	jmp    80104519 <sys_read+0x5d>
80104529:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010452e:	eb e9                	jmp    80104519 <sys_read+0x5d>

80104530 <sys_write>:
{
80104530:	55                   	push   %ebp
80104531:	89 e5                	mov    %esp,%ebp
80104533:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104536:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104539:	ba 00 00 00 00       	mov    $0x0,%edx
8010453e:	b8 00 00 00 00       	mov    $0x0,%eax
80104543:	e8 c7 fc ff ff       	call   8010420f <argfd>
80104548:	85 c0                	test   %eax,%eax
8010454a:	78 43                	js     8010458f <sys_write+0x5f>
8010454c:	83 ec 08             	sub    $0x8,%esp
8010454f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104552:	50                   	push   %eax
80104553:	6a 02                	push   $0x2
80104555:	e8 9d fb ff ff       	call   801040f7 <argint>
8010455a:	83 c4 10             	add    $0x10,%esp
8010455d:	85 c0                	test   %eax,%eax
8010455f:	78 35                	js     80104596 <sys_write+0x66>
80104561:	83 ec 04             	sub    $0x4,%esp
80104564:	ff 75 f0             	pushl  -0x10(%ebp)
80104567:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010456a:	50                   	push   %eax
8010456b:	6a 01                	push   $0x1
8010456d:	e8 ad fb ff ff       	call   8010411f <argptr>
80104572:	83 c4 10             	add    $0x10,%esp
80104575:	85 c0                	test   %eax,%eax
80104577:	78 24                	js     8010459d <sys_write+0x6d>
  return filewrite(f, p, n);
80104579:	83 ec 04             	sub    $0x4,%esp
8010457c:	ff 75 f0             	pushl  -0x10(%ebp)
8010457f:	ff 75 ec             	pushl  -0x14(%ebp)
80104582:	ff 75 f4             	pushl  -0xc(%ebp)
80104585:	e8 d2 c8 ff ff       	call   80100e5c <filewrite>
8010458a:	83 c4 10             	add    $0x10,%esp
}
8010458d:	c9                   	leave  
8010458e:	c3                   	ret    
    return -1;
8010458f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104594:	eb f7                	jmp    8010458d <sys_write+0x5d>
80104596:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010459b:	eb f0                	jmp    8010458d <sys_write+0x5d>
8010459d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045a2:	eb e9                	jmp    8010458d <sys_write+0x5d>

801045a4 <sys_close>:
{
801045a4:	55                   	push   %ebp
801045a5:	89 e5                	mov    %esp,%ebp
801045a7:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
801045aa:	8d 4d f0             	lea    -0x10(%ebp),%ecx
801045ad:	8d 55 f4             	lea    -0xc(%ebp),%edx
801045b0:	b8 00 00 00 00       	mov    $0x0,%eax
801045b5:	e8 55 fc ff ff       	call   8010420f <argfd>
801045ba:	85 c0                	test   %eax,%eax
801045bc:	78 25                	js     801045e3 <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
801045be:	e8 9b ee ff ff       	call   8010345e <myproc>
801045c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045c6:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
801045cd:	00 
  fileclose(f);
801045ce:	83 ec 0c             	sub    $0xc,%esp
801045d1:	ff 75 f0             	pushl  -0x10(%ebp)
801045d4:	e8 fa c6 ff ff       	call   80100cd3 <fileclose>
  return 0;
801045d9:	83 c4 10             	add    $0x10,%esp
801045dc:	b8 00 00 00 00       	mov    $0x0,%eax
}
801045e1:	c9                   	leave  
801045e2:	c3                   	ret    
    return -1;
801045e3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045e8:	eb f7                	jmp    801045e1 <sys_close+0x3d>

801045ea <sys_fstat>:
{
801045ea:	55                   	push   %ebp
801045eb:	89 e5                	mov    %esp,%ebp
801045ed:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801045f0:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801045f3:	ba 00 00 00 00       	mov    $0x0,%edx
801045f8:	b8 00 00 00 00       	mov    $0x0,%eax
801045fd:	e8 0d fc ff ff       	call   8010420f <argfd>
80104602:	85 c0                	test   %eax,%eax
80104604:	78 2a                	js     80104630 <sys_fstat+0x46>
80104606:	83 ec 04             	sub    $0x4,%esp
80104609:	6a 14                	push   $0x14
8010460b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010460e:	50                   	push   %eax
8010460f:	6a 01                	push   $0x1
80104611:	e8 09 fb ff ff       	call   8010411f <argptr>
80104616:	83 c4 10             	add    $0x10,%esp
80104619:	85 c0                	test   %eax,%eax
8010461b:	78 1a                	js     80104637 <sys_fstat+0x4d>
  return filestat(f, st);
8010461d:	83 ec 08             	sub    $0x8,%esp
80104620:	ff 75 f0             	pushl  -0x10(%ebp)
80104623:	ff 75 f4             	pushl  -0xc(%ebp)
80104626:	e8 65 c7 ff ff       	call   80100d90 <filestat>
8010462b:	83 c4 10             	add    $0x10,%esp
}
8010462e:	c9                   	leave  
8010462f:	c3                   	ret    
    return -1;
80104630:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104635:	eb f7                	jmp    8010462e <sys_fstat+0x44>
80104637:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010463c:	eb f0                	jmp    8010462e <sys_fstat+0x44>

8010463e <sys_link>:
{
8010463e:	55                   	push   %ebp
8010463f:	89 e5                	mov    %esp,%ebp
80104641:	56                   	push   %esi
80104642:	53                   	push   %ebx
80104643:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80104646:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104649:	50                   	push   %eax
8010464a:	6a 00                	push   $0x0
8010464c:	e8 36 fb ff ff       	call   80104187 <argstr>
80104651:	83 c4 10             	add    $0x10,%esp
80104654:	85 c0                	test   %eax,%eax
80104656:	0f 88 32 01 00 00    	js     8010478e <sys_link+0x150>
8010465c:	83 ec 08             	sub    $0x8,%esp
8010465f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104662:	50                   	push   %eax
80104663:	6a 01                	push   $0x1
80104665:	e8 1d fb ff ff       	call   80104187 <argstr>
8010466a:	83 c4 10             	add    $0x10,%esp
8010466d:	85 c0                	test   %eax,%eax
8010466f:	0f 88 20 01 00 00    	js     80104795 <sys_link+0x157>
  begin_op();
80104675:	e8 94 e3 ff ff       	call   80102a0e <begin_op>
  if((ip = namei(old)) == 0){
8010467a:	83 ec 0c             	sub    $0xc,%esp
8010467d:	ff 75 e0             	pushl  -0x20(%ebp)
80104680:	e8 5c d5 ff ff       	call   80101be1 <namei>
80104685:	89 c3                	mov    %eax,%ebx
80104687:	83 c4 10             	add    $0x10,%esp
8010468a:	85 c0                	test   %eax,%eax
8010468c:	0f 84 99 00 00 00    	je     8010472b <sys_link+0xed>
  ilock(ip);
80104692:	83 ec 0c             	sub    $0xc,%esp
80104695:	50                   	push   %eax
80104696:	e8 e6 ce ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
8010469b:	83 c4 10             	add    $0x10,%esp
8010469e:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801046a3:	0f 84 8e 00 00 00    	je     80104737 <sys_link+0xf9>
  ip->nlink++;
801046a9:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801046ad:	83 c0 01             	add    $0x1,%eax
801046b0:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801046b4:	83 ec 0c             	sub    $0xc,%esp
801046b7:	53                   	push   %ebx
801046b8:	e8 63 cd ff ff       	call   80101420 <iupdate>
  iunlock(ip);
801046bd:	89 1c 24             	mov    %ebx,(%esp)
801046c0:	e8 7e cf ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
801046c5:	83 c4 08             	add    $0x8,%esp
801046c8:	8d 45 ea             	lea    -0x16(%ebp),%eax
801046cb:	50                   	push   %eax
801046cc:	ff 75 e4             	pushl  -0x1c(%ebp)
801046cf:	e8 25 d5 ff ff       	call   80101bf9 <nameiparent>
801046d4:	89 c6                	mov    %eax,%esi
801046d6:	83 c4 10             	add    $0x10,%esp
801046d9:	85 c0                	test   %eax,%eax
801046db:	74 7e                	je     8010475b <sys_link+0x11d>
  ilock(dp);
801046dd:	83 ec 0c             	sub    $0xc,%esp
801046e0:	50                   	push   %eax
801046e1:	e8 9b ce ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801046e6:	83 c4 10             	add    $0x10,%esp
801046e9:	8b 03                	mov    (%ebx),%eax
801046eb:	39 06                	cmp    %eax,(%esi)
801046ed:	75 60                	jne    8010474f <sys_link+0x111>
801046ef:	83 ec 04             	sub    $0x4,%esp
801046f2:	ff 73 04             	pushl  0x4(%ebx)
801046f5:	8d 45 ea             	lea    -0x16(%ebp),%eax
801046f8:	50                   	push   %eax
801046f9:	56                   	push   %esi
801046fa:	e8 31 d4 ff ff       	call   80101b30 <dirlink>
801046ff:	83 c4 10             	add    $0x10,%esp
80104702:	85 c0                	test   %eax,%eax
80104704:	78 49                	js     8010474f <sys_link+0x111>
  iunlockput(dp);
80104706:	83 ec 0c             	sub    $0xc,%esp
80104709:	56                   	push   %esi
8010470a:	e8 19 d0 ff ff       	call   80101728 <iunlockput>
  iput(ip);
8010470f:	89 1c 24             	mov    %ebx,(%esp)
80104712:	e8 71 cf ff ff       	call   80101688 <iput>
  end_op();
80104717:	e8 6c e3 ff ff       	call   80102a88 <end_op>
  return 0;
8010471c:	83 c4 10             	add    $0x10,%esp
8010471f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104724:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104727:	5b                   	pop    %ebx
80104728:	5e                   	pop    %esi
80104729:	5d                   	pop    %ebp
8010472a:	c3                   	ret    
    end_op();
8010472b:	e8 58 e3 ff ff       	call   80102a88 <end_op>
    return -1;
80104730:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104735:	eb ed                	jmp    80104724 <sys_link+0xe6>
    iunlockput(ip);
80104737:	83 ec 0c             	sub    $0xc,%esp
8010473a:	53                   	push   %ebx
8010473b:	e8 e8 cf ff ff       	call   80101728 <iunlockput>
    end_op();
80104740:	e8 43 e3 ff ff       	call   80102a88 <end_op>
    return -1;
80104745:	83 c4 10             	add    $0x10,%esp
80104748:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010474d:	eb d5                	jmp    80104724 <sys_link+0xe6>
    iunlockput(dp);
8010474f:	83 ec 0c             	sub    $0xc,%esp
80104752:	56                   	push   %esi
80104753:	e8 d0 cf ff ff       	call   80101728 <iunlockput>
    goto bad;
80104758:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
8010475b:	83 ec 0c             	sub    $0xc,%esp
8010475e:	53                   	push   %ebx
8010475f:	e8 1d ce ff ff       	call   80101581 <ilock>
  ip->nlink--;
80104764:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104768:	83 e8 01             	sub    $0x1,%eax
8010476b:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
8010476f:	89 1c 24             	mov    %ebx,(%esp)
80104772:	e8 a9 cc ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104777:	89 1c 24             	mov    %ebx,(%esp)
8010477a:	e8 a9 cf ff ff       	call   80101728 <iunlockput>
  end_op();
8010477f:	e8 04 e3 ff ff       	call   80102a88 <end_op>
  return -1;
80104784:	83 c4 10             	add    $0x10,%esp
80104787:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010478c:	eb 96                	jmp    80104724 <sys_link+0xe6>
    return -1;
8010478e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104793:	eb 8f                	jmp    80104724 <sys_link+0xe6>
80104795:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010479a:	eb 88                	jmp    80104724 <sys_link+0xe6>

8010479c <sys_unlink>:
{
8010479c:	55                   	push   %ebp
8010479d:	89 e5                	mov    %esp,%ebp
8010479f:	57                   	push   %edi
801047a0:	56                   	push   %esi
801047a1:	53                   	push   %ebx
801047a2:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
801047a5:	8d 45 c4             	lea    -0x3c(%ebp),%eax
801047a8:	50                   	push   %eax
801047a9:	6a 00                	push   $0x0
801047ab:	e8 d7 f9 ff ff       	call   80104187 <argstr>
801047b0:	83 c4 10             	add    $0x10,%esp
801047b3:	85 c0                	test   %eax,%eax
801047b5:	0f 88 83 01 00 00    	js     8010493e <sys_unlink+0x1a2>
  begin_op();
801047bb:	e8 4e e2 ff ff       	call   80102a0e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
801047c0:	83 ec 08             	sub    $0x8,%esp
801047c3:	8d 45 ca             	lea    -0x36(%ebp),%eax
801047c6:	50                   	push   %eax
801047c7:	ff 75 c4             	pushl  -0x3c(%ebp)
801047ca:	e8 2a d4 ff ff       	call   80101bf9 <nameiparent>
801047cf:	89 c6                	mov    %eax,%esi
801047d1:	83 c4 10             	add    $0x10,%esp
801047d4:	85 c0                	test   %eax,%eax
801047d6:	0f 84 ed 00 00 00    	je     801048c9 <sys_unlink+0x12d>
  ilock(dp);
801047dc:	83 ec 0c             	sub    $0xc,%esp
801047df:	50                   	push   %eax
801047e0:	e8 9c cd ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801047e5:	83 c4 08             	add    $0x8,%esp
801047e8:	68 9e 6e 10 80       	push   $0x80106e9e
801047ed:	8d 45 ca             	lea    -0x36(%ebp),%eax
801047f0:	50                   	push   %eax
801047f1:	e8 a5 d1 ff ff       	call   8010199b <namecmp>
801047f6:	83 c4 10             	add    $0x10,%esp
801047f9:	85 c0                	test   %eax,%eax
801047fb:	0f 84 fc 00 00 00    	je     801048fd <sys_unlink+0x161>
80104801:	83 ec 08             	sub    $0x8,%esp
80104804:	68 9d 6e 10 80       	push   $0x80106e9d
80104809:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010480c:	50                   	push   %eax
8010480d:	e8 89 d1 ff ff       	call   8010199b <namecmp>
80104812:	83 c4 10             	add    $0x10,%esp
80104815:	85 c0                	test   %eax,%eax
80104817:	0f 84 e0 00 00 00    	je     801048fd <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
8010481d:	83 ec 04             	sub    $0x4,%esp
80104820:	8d 45 c0             	lea    -0x40(%ebp),%eax
80104823:	50                   	push   %eax
80104824:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104827:	50                   	push   %eax
80104828:	56                   	push   %esi
80104829:	e8 82 d1 ff ff       	call   801019b0 <dirlookup>
8010482e:	89 c3                	mov    %eax,%ebx
80104830:	83 c4 10             	add    $0x10,%esp
80104833:	85 c0                	test   %eax,%eax
80104835:	0f 84 c2 00 00 00    	je     801048fd <sys_unlink+0x161>
  ilock(ip);
8010483b:	83 ec 0c             	sub    $0xc,%esp
8010483e:	50                   	push   %eax
8010483f:	e8 3d cd ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
80104844:	83 c4 10             	add    $0x10,%esp
80104847:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
8010484c:	0f 8e 83 00 00 00    	jle    801048d5 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104852:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104857:	0f 84 85 00 00 00    	je     801048e2 <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
8010485d:	83 ec 04             	sub    $0x4,%esp
80104860:	6a 10                	push   $0x10
80104862:	6a 00                	push   $0x0
80104864:	8d 7d d8             	lea    -0x28(%ebp),%edi
80104867:	57                   	push   %edi
80104868:	e8 3f f6 ff ff       	call   80103eac <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010486d:	6a 10                	push   $0x10
8010486f:	ff 75 c0             	pushl  -0x40(%ebp)
80104872:	57                   	push   %edi
80104873:	56                   	push   %esi
80104874:	e8 f7 cf ff ff       	call   80101870 <writei>
80104879:	83 c4 20             	add    $0x20,%esp
8010487c:	83 f8 10             	cmp    $0x10,%eax
8010487f:	0f 85 90 00 00 00    	jne    80104915 <sys_unlink+0x179>
  if(ip->type == T_DIR){
80104885:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010488a:	0f 84 92 00 00 00    	je     80104922 <sys_unlink+0x186>
  iunlockput(dp);
80104890:	83 ec 0c             	sub    $0xc,%esp
80104893:	56                   	push   %esi
80104894:	e8 8f ce ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
80104899:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010489d:	83 e8 01             	sub    $0x1,%eax
801048a0:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801048a4:	89 1c 24             	mov    %ebx,(%esp)
801048a7:	e8 74 cb ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
801048ac:	89 1c 24             	mov    %ebx,(%esp)
801048af:	e8 74 ce ff ff       	call   80101728 <iunlockput>
  end_op();
801048b4:	e8 cf e1 ff ff       	call   80102a88 <end_op>
  return 0;
801048b9:	83 c4 10             	add    $0x10,%esp
801048bc:	b8 00 00 00 00       	mov    $0x0,%eax
}
801048c1:	8d 65 f4             	lea    -0xc(%ebp),%esp
801048c4:	5b                   	pop    %ebx
801048c5:	5e                   	pop    %esi
801048c6:	5f                   	pop    %edi
801048c7:	5d                   	pop    %ebp
801048c8:	c3                   	ret    
    end_op();
801048c9:	e8 ba e1 ff ff       	call   80102a88 <end_op>
    return -1;
801048ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048d3:	eb ec                	jmp    801048c1 <sys_unlink+0x125>
    panic("unlink: nlink < 1");
801048d5:	83 ec 0c             	sub    $0xc,%esp
801048d8:	68 bc 6e 10 80       	push   $0x80106ebc
801048dd:	e8 66 ba ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801048e2:	89 d8                	mov    %ebx,%eax
801048e4:	e8 c4 f9 ff ff       	call   801042ad <isdirempty>
801048e9:	85 c0                	test   %eax,%eax
801048eb:	0f 85 6c ff ff ff    	jne    8010485d <sys_unlink+0xc1>
    iunlockput(ip);
801048f1:	83 ec 0c             	sub    $0xc,%esp
801048f4:	53                   	push   %ebx
801048f5:	e8 2e ce ff ff       	call   80101728 <iunlockput>
    goto bad;
801048fa:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
801048fd:	83 ec 0c             	sub    $0xc,%esp
80104900:	56                   	push   %esi
80104901:	e8 22 ce ff ff       	call   80101728 <iunlockput>
  end_op();
80104906:	e8 7d e1 ff ff       	call   80102a88 <end_op>
  return -1;
8010490b:	83 c4 10             	add    $0x10,%esp
8010490e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104913:	eb ac                	jmp    801048c1 <sys_unlink+0x125>
    panic("unlink: writei");
80104915:	83 ec 0c             	sub    $0xc,%esp
80104918:	68 ce 6e 10 80       	push   $0x80106ece
8010491d:	e8 26 ba ff ff       	call   80100348 <panic>
    dp->nlink--;
80104922:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104926:	83 e8 01             	sub    $0x1,%eax
80104929:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
8010492d:	83 ec 0c             	sub    $0xc,%esp
80104930:	56                   	push   %esi
80104931:	e8 ea ca ff ff       	call   80101420 <iupdate>
80104936:	83 c4 10             	add    $0x10,%esp
80104939:	e9 52 ff ff ff       	jmp    80104890 <sys_unlink+0xf4>
    return -1;
8010493e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104943:	e9 79 ff ff ff       	jmp    801048c1 <sys_unlink+0x125>

80104948 <sys_open>:

int
sys_open(void)
{
80104948:	55                   	push   %ebp
80104949:	89 e5                	mov    %esp,%ebp
8010494b:	57                   	push   %edi
8010494c:	56                   	push   %esi
8010494d:	53                   	push   %ebx
8010494e:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80104951:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104954:	50                   	push   %eax
80104955:	6a 00                	push   $0x0
80104957:	e8 2b f8 ff ff       	call   80104187 <argstr>
8010495c:	83 c4 10             	add    $0x10,%esp
8010495f:	85 c0                	test   %eax,%eax
80104961:	0f 88 30 01 00 00    	js     80104a97 <sys_open+0x14f>
80104967:	83 ec 08             	sub    $0x8,%esp
8010496a:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010496d:	50                   	push   %eax
8010496e:	6a 01                	push   $0x1
80104970:	e8 82 f7 ff ff       	call   801040f7 <argint>
80104975:	83 c4 10             	add    $0x10,%esp
80104978:	85 c0                	test   %eax,%eax
8010497a:	0f 88 21 01 00 00    	js     80104aa1 <sys_open+0x159>
    return -1;

  begin_op();
80104980:	e8 89 e0 ff ff       	call   80102a0e <begin_op>

  if(omode & O_CREATE){
80104985:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
80104989:	0f 84 84 00 00 00    	je     80104a13 <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
8010498f:	83 ec 0c             	sub    $0xc,%esp
80104992:	6a 00                	push   $0x0
80104994:	b9 00 00 00 00       	mov    $0x0,%ecx
80104999:	ba 02 00 00 00       	mov    $0x2,%edx
8010499e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801049a1:	e8 5e f9 ff ff       	call   80104304 <create>
801049a6:	89 c6                	mov    %eax,%esi
    if(ip == 0){
801049a8:	83 c4 10             	add    $0x10,%esp
801049ab:	85 c0                	test   %eax,%eax
801049ad:	74 58                	je     80104a07 <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
801049af:	e8 79 c2 ff ff       	call   80100c2d <filealloc>
801049b4:	89 c3                	mov    %eax,%ebx
801049b6:	85 c0                	test   %eax,%eax
801049b8:	0f 84 ae 00 00 00    	je     80104a6c <sys_open+0x124>
801049be:	e8 b3 f8 ff ff       	call   80104276 <fdalloc>
801049c3:	89 c7                	mov    %eax,%edi
801049c5:	85 c0                	test   %eax,%eax
801049c7:	0f 88 9f 00 00 00    	js     80104a6c <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
801049cd:	83 ec 0c             	sub    $0xc,%esp
801049d0:	56                   	push   %esi
801049d1:	e8 6d cc ff ff       	call   80101643 <iunlock>
  end_op();
801049d6:	e8 ad e0 ff ff       	call   80102a88 <end_op>

  f->type = FD_INODE;
801049db:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
801049e1:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
801049e4:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
801049eb:	8b 45 e0             	mov    -0x20(%ebp),%eax
801049ee:	83 c4 10             	add    $0x10,%esp
801049f1:	a8 01                	test   $0x1,%al
801049f3:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
801049f7:	a8 03                	test   $0x3,%al
801049f9:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
801049fd:	89 f8                	mov    %edi,%eax
801049ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104a02:	5b                   	pop    %ebx
80104a03:	5e                   	pop    %esi
80104a04:	5f                   	pop    %edi
80104a05:	5d                   	pop    %ebp
80104a06:	c3                   	ret    
      end_op();
80104a07:	e8 7c e0 ff ff       	call   80102a88 <end_op>
      return -1;
80104a0c:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a11:	eb ea                	jmp    801049fd <sys_open+0xb5>
    if((ip = namei(path)) == 0){
80104a13:	83 ec 0c             	sub    $0xc,%esp
80104a16:	ff 75 e4             	pushl  -0x1c(%ebp)
80104a19:	e8 c3 d1 ff ff       	call   80101be1 <namei>
80104a1e:	89 c6                	mov    %eax,%esi
80104a20:	83 c4 10             	add    $0x10,%esp
80104a23:	85 c0                	test   %eax,%eax
80104a25:	74 39                	je     80104a60 <sys_open+0x118>
    ilock(ip);
80104a27:	83 ec 0c             	sub    $0xc,%esp
80104a2a:	50                   	push   %eax
80104a2b:	e8 51 cb ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80104a30:	83 c4 10             	add    $0x10,%esp
80104a33:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104a38:	0f 85 71 ff ff ff    	jne    801049af <sys_open+0x67>
80104a3e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104a42:	0f 84 67 ff ff ff    	je     801049af <sys_open+0x67>
      iunlockput(ip);
80104a48:	83 ec 0c             	sub    $0xc,%esp
80104a4b:	56                   	push   %esi
80104a4c:	e8 d7 cc ff ff       	call   80101728 <iunlockput>
      end_op();
80104a51:	e8 32 e0 ff ff       	call   80102a88 <end_op>
      return -1;
80104a56:	83 c4 10             	add    $0x10,%esp
80104a59:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a5e:	eb 9d                	jmp    801049fd <sys_open+0xb5>
      end_op();
80104a60:	e8 23 e0 ff ff       	call   80102a88 <end_op>
      return -1;
80104a65:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a6a:	eb 91                	jmp    801049fd <sys_open+0xb5>
    if(f)
80104a6c:	85 db                	test   %ebx,%ebx
80104a6e:	74 0c                	je     80104a7c <sys_open+0x134>
      fileclose(f);
80104a70:	83 ec 0c             	sub    $0xc,%esp
80104a73:	53                   	push   %ebx
80104a74:	e8 5a c2 ff ff       	call   80100cd3 <fileclose>
80104a79:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104a7c:	83 ec 0c             	sub    $0xc,%esp
80104a7f:	56                   	push   %esi
80104a80:	e8 a3 cc ff ff       	call   80101728 <iunlockput>
    end_op();
80104a85:	e8 fe df ff ff       	call   80102a88 <end_op>
    return -1;
80104a8a:	83 c4 10             	add    $0x10,%esp
80104a8d:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a92:	e9 66 ff ff ff       	jmp    801049fd <sys_open+0xb5>
    return -1;
80104a97:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a9c:	e9 5c ff ff ff       	jmp    801049fd <sys_open+0xb5>
80104aa1:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104aa6:	e9 52 ff ff ff       	jmp    801049fd <sys_open+0xb5>

80104aab <sys_mkdir>:

int
sys_mkdir(void)
{
80104aab:	55                   	push   %ebp
80104aac:	89 e5                	mov    %esp,%ebp
80104aae:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104ab1:	e8 58 df ff ff       	call   80102a0e <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104ab6:	83 ec 08             	sub    $0x8,%esp
80104ab9:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104abc:	50                   	push   %eax
80104abd:	6a 00                	push   $0x0
80104abf:	e8 c3 f6 ff ff       	call   80104187 <argstr>
80104ac4:	83 c4 10             	add    $0x10,%esp
80104ac7:	85 c0                	test   %eax,%eax
80104ac9:	78 36                	js     80104b01 <sys_mkdir+0x56>
80104acb:	83 ec 0c             	sub    $0xc,%esp
80104ace:	6a 00                	push   $0x0
80104ad0:	b9 00 00 00 00       	mov    $0x0,%ecx
80104ad5:	ba 01 00 00 00       	mov    $0x1,%edx
80104ada:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104add:	e8 22 f8 ff ff       	call   80104304 <create>
80104ae2:	83 c4 10             	add    $0x10,%esp
80104ae5:	85 c0                	test   %eax,%eax
80104ae7:	74 18                	je     80104b01 <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104ae9:	83 ec 0c             	sub    $0xc,%esp
80104aec:	50                   	push   %eax
80104aed:	e8 36 cc ff ff       	call   80101728 <iunlockput>
  end_op();
80104af2:	e8 91 df ff ff       	call   80102a88 <end_op>
  return 0;
80104af7:	83 c4 10             	add    $0x10,%esp
80104afa:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104aff:	c9                   	leave  
80104b00:	c3                   	ret    
    end_op();
80104b01:	e8 82 df ff ff       	call   80102a88 <end_op>
    return -1;
80104b06:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b0b:	eb f2                	jmp    80104aff <sys_mkdir+0x54>

80104b0d <sys_mknod>:

int
sys_mknod(void)
{
80104b0d:	55                   	push   %ebp
80104b0e:	89 e5                	mov    %esp,%ebp
80104b10:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104b13:	e8 f6 de ff ff       	call   80102a0e <begin_op>
  if((argstr(0, &path)) < 0 ||
80104b18:	83 ec 08             	sub    $0x8,%esp
80104b1b:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b1e:	50                   	push   %eax
80104b1f:	6a 00                	push   $0x0
80104b21:	e8 61 f6 ff ff       	call   80104187 <argstr>
80104b26:	83 c4 10             	add    $0x10,%esp
80104b29:	85 c0                	test   %eax,%eax
80104b2b:	78 62                	js     80104b8f <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104b2d:	83 ec 08             	sub    $0x8,%esp
80104b30:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104b33:	50                   	push   %eax
80104b34:	6a 01                	push   $0x1
80104b36:	e8 bc f5 ff ff       	call   801040f7 <argint>
  if((argstr(0, &path)) < 0 ||
80104b3b:	83 c4 10             	add    $0x10,%esp
80104b3e:	85 c0                	test   %eax,%eax
80104b40:	78 4d                	js     80104b8f <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104b42:	83 ec 08             	sub    $0x8,%esp
80104b45:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104b48:	50                   	push   %eax
80104b49:	6a 02                	push   $0x2
80104b4b:	e8 a7 f5 ff ff       	call   801040f7 <argint>
     argint(1, &major) < 0 ||
80104b50:	83 c4 10             	add    $0x10,%esp
80104b53:	85 c0                	test   %eax,%eax
80104b55:	78 38                	js     80104b8f <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104b57:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104b5b:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104b5f:	83 ec 0c             	sub    $0xc,%esp
80104b62:	50                   	push   %eax
80104b63:	ba 03 00 00 00       	mov    $0x3,%edx
80104b68:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b6b:	e8 94 f7 ff ff       	call   80104304 <create>
80104b70:	83 c4 10             	add    $0x10,%esp
80104b73:	85 c0                	test   %eax,%eax
80104b75:	74 18                	je     80104b8f <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104b77:	83 ec 0c             	sub    $0xc,%esp
80104b7a:	50                   	push   %eax
80104b7b:	e8 a8 cb ff ff       	call   80101728 <iunlockput>
  end_op();
80104b80:	e8 03 df ff ff       	call   80102a88 <end_op>
  return 0;
80104b85:	83 c4 10             	add    $0x10,%esp
80104b88:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104b8d:	c9                   	leave  
80104b8e:	c3                   	ret    
    end_op();
80104b8f:	e8 f4 de ff ff       	call   80102a88 <end_op>
    return -1;
80104b94:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b99:	eb f2                	jmp    80104b8d <sys_mknod+0x80>

80104b9b <sys_chdir>:

int
sys_chdir(void)
{
80104b9b:	55                   	push   %ebp
80104b9c:	89 e5                	mov    %esp,%ebp
80104b9e:	56                   	push   %esi
80104b9f:	53                   	push   %ebx
80104ba0:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104ba3:	e8 b6 e8 ff ff       	call   8010345e <myproc>
80104ba8:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104baa:	e8 5f de ff ff       	call   80102a0e <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104baf:	83 ec 08             	sub    $0x8,%esp
80104bb2:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104bb5:	50                   	push   %eax
80104bb6:	6a 00                	push   $0x0
80104bb8:	e8 ca f5 ff ff       	call   80104187 <argstr>
80104bbd:	83 c4 10             	add    $0x10,%esp
80104bc0:	85 c0                	test   %eax,%eax
80104bc2:	78 52                	js     80104c16 <sys_chdir+0x7b>
80104bc4:	83 ec 0c             	sub    $0xc,%esp
80104bc7:	ff 75 f4             	pushl  -0xc(%ebp)
80104bca:	e8 12 d0 ff ff       	call   80101be1 <namei>
80104bcf:	89 c3                	mov    %eax,%ebx
80104bd1:	83 c4 10             	add    $0x10,%esp
80104bd4:	85 c0                	test   %eax,%eax
80104bd6:	74 3e                	je     80104c16 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104bd8:	83 ec 0c             	sub    $0xc,%esp
80104bdb:	50                   	push   %eax
80104bdc:	e8 a0 c9 ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104be1:	83 c4 10             	add    $0x10,%esp
80104be4:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104be9:	75 37                	jne    80104c22 <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104beb:	83 ec 0c             	sub    $0xc,%esp
80104bee:	53                   	push   %ebx
80104bef:	e8 4f ca ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104bf4:	83 c4 04             	add    $0x4,%esp
80104bf7:	ff 76 68             	pushl  0x68(%esi)
80104bfa:	e8 89 ca ff ff       	call   80101688 <iput>
  end_op();
80104bff:	e8 84 de ff ff       	call   80102a88 <end_op>
  curproc->cwd = ip;
80104c04:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104c07:	83 c4 10             	add    $0x10,%esp
80104c0a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104c0f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104c12:	5b                   	pop    %ebx
80104c13:	5e                   	pop    %esi
80104c14:	5d                   	pop    %ebp
80104c15:	c3                   	ret    
    end_op();
80104c16:	e8 6d de ff ff       	call   80102a88 <end_op>
    return -1;
80104c1b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c20:	eb ed                	jmp    80104c0f <sys_chdir+0x74>
    iunlockput(ip);
80104c22:	83 ec 0c             	sub    $0xc,%esp
80104c25:	53                   	push   %ebx
80104c26:	e8 fd ca ff ff       	call   80101728 <iunlockput>
    end_op();
80104c2b:	e8 58 de ff ff       	call   80102a88 <end_op>
    return -1;
80104c30:	83 c4 10             	add    $0x10,%esp
80104c33:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c38:	eb d5                	jmp    80104c0f <sys_chdir+0x74>

80104c3a <sys_exec>:

int
sys_exec(void)
{
80104c3a:	55                   	push   %ebp
80104c3b:	89 e5                	mov    %esp,%ebp
80104c3d:	53                   	push   %ebx
80104c3e:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104c44:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c47:	50                   	push   %eax
80104c48:	6a 00                	push   $0x0
80104c4a:	e8 38 f5 ff ff       	call   80104187 <argstr>
80104c4f:	83 c4 10             	add    $0x10,%esp
80104c52:	85 c0                	test   %eax,%eax
80104c54:	0f 88 a8 00 00 00    	js     80104d02 <sys_exec+0xc8>
80104c5a:	83 ec 08             	sub    $0x8,%esp
80104c5d:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104c63:	50                   	push   %eax
80104c64:	6a 01                	push   $0x1
80104c66:	e8 8c f4 ff ff       	call   801040f7 <argint>
80104c6b:	83 c4 10             	add    $0x10,%esp
80104c6e:	85 c0                	test   %eax,%eax
80104c70:	0f 88 93 00 00 00    	js     80104d09 <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104c76:	83 ec 04             	sub    $0x4,%esp
80104c79:	68 80 00 00 00       	push   $0x80
80104c7e:	6a 00                	push   $0x0
80104c80:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104c86:	50                   	push   %eax
80104c87:	e8 20 f2 ff ff       	call   80103eac <memset>
80104c8c:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104c8f:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104c94:	83 fb 1f             	cmp    $0x1f,%ebx
80104c97:	77 77                	ja     80104d10 <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104c99:	83 ec 08             	sub    $0x8,%esp
80104c9c:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104ca2:	50                   	push   %eax
80104ca3:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104ca9:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104cac:	50                   	push   %eax
80104cad:	e8 c9 f3 ff ff       	call   8010407b <fetchint>
80104cb2:	83 c4 10             	add    $0x10,%esp
80104cb5:	85 c0                	test   %eax,%eax
80104cb7:	78 5e                	js     80104d17 <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104cb9:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104cbf:	85 c0                	test   %eax,%eax
80104cc1:	74 1d                	je     80104ce0 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104cc3:	83 ec 08             	sub    $0x8,%esp
80104cc6:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104ccd:	52                   	push   %edx
80104cce:	50                   	push   %eax
80104ccf:	e8 e3 f3 ff ff       	call   801040b7 <fetchstr>
80104cd4:	83 c4 10             	add    $0x10,%esp
80104cd7:	85 c0                	test   %eax,%eax
80104cd9:	78 46                	js     80104d21 <sys_exec+0xe7>
  for(i=0;; i++){
80104cdb:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104cde:	eb b4                	jmp    80104c94 <sys_exec+0x5a>
      argv[i] = 0;
80104ce0:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104ce7:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104ceb:	83 ec 08             	sub    $0x8,%esp
80104cee:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104cf4:	50                   	push   %eax
80104cf5:	ff 75 f4             	pushl  -0xc(%ebp)
80104cf8:	e8 d5 bb ff ff       	call   801008d2 <exec>
80104cfd:	83 c4 10             	add    $0x10,%esp
80104d00:	eb 1a                	jmp    80104d1c <sys_exec+0xe2>
    return -1;
80104d02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d07:	eb 13                	jmp    80104d1c <sys_exec+0xe2>
80104d09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d0e:	eb 0c                	jmp    80104d1c <sys_exec+0xe2>
      return -1;
80104d10:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d15:	eb 05                	jmp    80104d1c <sys_exec+0xe2>
      return -1;
80104d17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104d1c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104d1f:	c9                   	leave  
80104d20:	c3                   	ret    
      return -1;
80104d21:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d26:	eb f4                	jmp    80104d1c <sys_exec+0xe2>

80104d28 <sys_pipe>:

int
sys_pipe(void)
{
80104d28:	55                   	push   %ebp
80104d29:	89 e5                	mov    %esp,%ebp
80104d2b:	53                   	push   %ebx
80104d2c:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104d2f:	6a 08                	push   $0x8
80104d31:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d34:	50                   	push   %eax
80104d35:	6a 00                	push   $0x0
80104d37:	e8 e3 f3 ff ff       	call   8010411f <argptr>
80104d3c:	83 c4 10             	add    $0x10,%esp
80104d3f:	85 c0                	test   %eax,%eax
80104d41:	78 77                	js     80104dba <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104d43:	83 ec 08             	sub    $0x8,%esp
80104d46:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104d49:	50                   	push   %eax
80104d4a:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104d4d:	50                   	push   %eax
80104d4e:	e8 42 e2 ff ff       	call   80102f95 <pipealloc>
80104d53:	83 c4 10             	add    $0x10,%esp
80104d56:	85 c0                	test   %eax,%eax
80104d58:	78 67                	js     80104dc1 <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104d5a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d5d:	e8 14 f5 ff ff       	call   80104276 <fdalloc>
80104d62:	89 c3                	mov    %eax,%ebx
80104d64:	85 c0                	test   %eax,%eax
80104d66:	78 21                	js     80104d89 <sys_pipe+0x61>
80104d68:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104d6b:	e8 06 f5 ff ff       	call   80104276 <fdalloc>
80104d70:	85 c0                	test   %eax,%eax
80104d72:	78 15                	js     80104d89 <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104d74:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d77:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104d79:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d7c:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104d7f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104d84:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104d87:	c9                   	leave  
80104d88:	c3                   	ret    
    if(fd0 >= 0)
80104d89:	85 db                	test   %ebx,%ebx
80104d8b:	78 0d                	js     80104d9a <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104d8d:	e8 cc e6 ff ff       	call   8010345e <myproc>
80104d92:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104d99:	00 
    fileclose(rf);
80104d9a:	83 ec 0c             	sub    $0xc,%esp
80104d9d:	ff 75 f0             	pushl  -0x10(%ebp)
80104da0:	e8 2e bf ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104da5:	83 c4 04             	add    $0x4,%esp
80104da8:	ff 75 ec             	pushl  -0x14(%ebp)
80104dab:	e8 23 bf ff ff       	call   80100cd3 <fileclose>
    return -1;
80104db0:	83 c4 10             	add    $0x10,%esp
80104db3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104db8:	eb ca                	jmp    80104d84 <sys_pipe+0x5c>
    return -1;
80104dba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dbf:	eb c3                	jmp    80104d84 <sys_pipe+0x5c>
    return -1;
80104dc1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dc6:	eb bc                	jmp    80104d84 <sys_pipe+0x5c>

80104dc8 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104dc8:	55                   	push   %ebp
80104dc9:	89 e5                	mov    %esp,%ebp
80104dcb:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104dce:	e8 03 e8 ff ff       	call   801035d6 <fork>
}
80104dd3:	c9                   	leave  
80104dd4:	c3                   	ret    

80104dd5 <sys_exit>:

int
sys_exit(void)
{
80104dd5:	55                   	push   %ebp
80104dd6:	89 e5                	mov    %esp,%ebp
80104dd8:	83 ec 08             	sub    $0x8,%esp
  exit();
80104ddb:	e8 2d ea ff ff       	call   8010380d <exit>
  return 0;  // not reached
}
80104de0:	b8 00 00 00 00       	mov    $0x0,%eax
80104de5:	c9                   	leave  
80104de6:	c3                   	ret    

80104de7 <sys_wait>:

int
sys_wait(void)
{
80104de7:	55                   	push   %ebp
80104de8:	89 e5                	mov    %esp,%ebp
80104dea:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104ded:	e8 a4 eb ff ff       	call   80103996 <wait>
}
80104df2:	c9                   	leave  
80104df3:	c3                   	ret    

80104df4 <sys_kill>:

int
sys_kill(void)
{
80104df4:	55                   	push   %ebp
80104df5:	89 e5                	mov    %esp,%ebp
80104df7:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104dfa:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104dfd:	50                   	push   %eax
80104dfe:	6a 00                	push   $0x0
80104e00:	e8 f2 f2 ff ff       	call   801040f7 <argint>
80104e05:	83 c4 10             	add    $0x10,%esp
80104e08:	85 c0                	test   %eax,%eax
80104e0a:	78 10                	js     80104e1c <sys_kill+0x28>
    return -1;
  return kill(pid);
80104e0c:	83 ec 0c             	sub    $0xc,%esp
80104e0f:	ff 75 f4             	pushl  -0xc(%ebp)
80104e12:	e8 7c ec ff ff       	call   80103a93 <kill>
80104e17:	83 c4 10             	add    $0x10,%esp
}
80104e1a:	c9                   	leave  
80104e1b:	c3                   	ret    
    return -1;
80104e1c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e21:	eb f7                	jmp    80104e1a <sys_kill+0x26>

80104e23 <sys_getpid>:

int
sys_getpid(void)
{
80104e23:	55                   	push   %ebp
80104e24:	89 e5                	mov    %esp,%ebp
80104e26:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104e29:	e8 30 e6 ff ff       	call   8010345e <myproc>
80104e2e:	8b 40 10             	mov    0x10(%eax),%eax
}
80104e31:	c9                   	leave  
80104e32:	c3                   	ret    

80104e33 <sys_sbrk>:

int
sys_sbrk(void)
{
80104e33:	55                   	push   %ebp
80104e34:	89 e5                	mov    %esp,%ebp
80104e36:	53                   	push   %ebx
80104e37:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104e3a:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e3d:	50                   	push   %eax
80104e3e:	6a 00                	push   $0x0
80104e40:	e8 b2 f2 ff ff       	call   801040f7 <argint>
80104e45:	83 c4 10             	add    $0x10,%esp
80104e48:	85 c0                	test   %eax,%eax
80104e4a:	78 27                	js     80104e73 <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104e4c:	e8 0d e6 ff ff       	call   8010345e <myproc>
80104e51:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104e53:	83 ec 0c             	sub    $0xc,%esp
80104e56:	ff 75 f4             	pushl  -0xc(%ebp)
80104e59:	e8 0b e7 ff ff       	call   80103569 <growproc>
80104e5e:	83 c4 10             	add    $0x10,%esp
80104e61:	85 c0                	test   %eax,%eax
80104e63:	78 07                	js     80104e6c <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104e65:	89 d8                	mov    %ebx,%eax
80104e67:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e6a:	c9                   	leave  
80104e6b:	c3                   	ret    
    return -1;
80104e6c:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104e71:	eb f2                	jmp    80104e65 <sys_sbrk+0x32>
    return -1;
80104e73:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104e78:	eb eb                	jmp    80104e65 <sys_sbrk+0x32>

80104e7a <sys_sleep>:

int
sys_sleep(void)
{
80104e7a:	55                   	push   %ebp
80104e7b:	89 e5                	mov    %esp,%ebp
80104e7d:	53                   	push   %ebx
80104e7e:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104e81:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e84:	50                   	push   %eax
80104e85:	6a 00                	push   $0x0
80104e87:	e8 6b f2 ff ff       	call   801040f7 <argint>
80104e8c:	83 c4 10             	add    $0x10,%esp
80104e8f:	85 c0                	test   %eax,%eax
80104e91:	78 75                	js     80104f08 <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104e93:	83 ec 0c             	sub    $0xc,%esp
80104e96:	68 e0 4c 13 80       	push   $0x80134ce0
80104e9b:	e8 60 ef ff ff       	call   80103e00 <acquire>
  ticks0 = ticks;
80104ea0:	8b 1d 20 55 13 80    	mov    0x80135520,%ebx
  while(ticks - ticks0 < n){
80104ea6:	83 c4 10             	add    $0x10,%esp
80104ea9:	a1 20 55 13 80       	mov    0x80135520,%eax
80104eae:	29 d8                	sub    %ebx,%eax
80104eb0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104eb3:	73 39                	jae    80104eee <sys_sleep+0x74>
    if(myproc()->killed){
80104eb5:	e8 a4 e5 ff ff       	call   8010345e <myproc>
80104eba:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104ebe:	75 17                	jne    80104ed7 <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104ec0:	83 ec 08             	sub    $0x8,%esp
80104ec3:	68 e0 4c 13 80       	push   $0x80134ce0
80104ec8:	68 20 55 13 80       	push   $0x80135520
80104ecd:	e8 33 ea ff ff       	call   80103905 <sleep>
80104ed2:	83 c4 10             	add    $0x10,%esp
80104ed5:	eb d2                	jmp    80104ea9 <sys_sleep+0x2f>
      release(&tickslock);
80104ed7:	83 ec 0c             	sub    $0xc,%esp
80104eda:	68 e0 4c 13 80       	push   $0x80134ce0
80104edf:	e8 81 ef ff ff       	call   80103e65 <release>
      return -1;
80104ee4:	83 c4 10             	add    $0x10,%esp
80104ee7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104eec:	eb 15                	jmp    80104f03 <sys_sleep+0x89>
  }
  release(&tickslock);
80104eee:	83 ec 0c             	sub    $0xc,%esp
80104ef1:	68 e0 4c 13 80       	push   $0x80134ce0
80104ef6:	e8 6a ef ff ff       	call   80103e65 <release>
  return 0;
80104efb:	83 c4 10             	add    $0x10,%esp
80104efe:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104f03:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104f06:	c9                   	leave  
80104f07:	c3                   	ret    
    return -1;
80104f08:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f0d:	eb f4                	jmp    80104f03 <sys_sleep+0x89>

80104f0f <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104f0f:	55                   	push   %ebp
80104f10:	89 e5                	mov    %esp,%ebp
80104f12:	53                   	push   %ebx
80104f13:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104f16:	68 e0 4c 13 80       	push   $0x80134ce0
80104f1b:	e8 e0 ee ff ff       	call   80103e00 <acquire>
  xticks = ticks;
80104f20:	8b 1d 20 55 13 80    	mov    0x80135520,%ebx
  release(&tickslock);
80104f26:	c7 04 24 e0 4c 13 80 	movl   $0x80134ce0,(%esp)
80104f2d:	e8 33 ef ff ff       	call   80103e65 <release>
  return xticks;
}
80104f32:	89 d8                	mov    %ebx,%eax
80104f34:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104f37:	c9                   	leave  
80104f38:	c3                   	ret    

80104f39 <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80104f39:	55                   	push   %ebp
80104f3a:	89 e5                	mov    %esp,%ebp
80104f3c:	83 ec 1c             	sub    $0x1c,%esp
  int *frames;
  int *pids;
  int numframes;
  if(argptr(0, (char**)(&frames), sizeof(*frames)) < 0)
80104f3f:	6a 04                	push   $0x4
80104f41:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104f44:	50                   	push   %eax
80104f45:	6a 00                	push   $0x0
80104f47:	e8 d3 f1 ff ff       	call   8010411f <argptr>
80104f4c:	83 c4 10             	add    $0x10,%esp
80104f4f:	85 c0                	test   %eax,%eax
80104f51:	78 42                	js     80104f95 <sys_dump_physmem+0x5c>
    return -1;
  if(argptr(1, (char**)(&pids), sizeof(*pids)) < 0)
80104f53:	83 ec 04             	sub    $0x4,%esp
80104f56:	6a 04                	push   $0x4
80104f58:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104f5b:	50                   	push   %eax
80104f5c:	6a 01                	push   $0x1
80104f5e:	e8 bc f1 ff ff       	call   8010411f <argptr>
80104f63:	83 c4 10             	add    $0x10,%esp
80104f66:	85 c0                	test   %eax,%eax
80104f68:	78 32                	js     80104f9c <sys_dump_physmem+0x63>
    return -1;
  if(argint(2, &numframes) < 0)
80104f6a:	83 ec 08             	sub    $0x8,%esp
80104f6d:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104f70:	50                   	push   %eax
80104f71:	6a 02                	push   $0x2
80104f73:	e8 7f f1 ff ff       	call   801040f7 <argint>
80104f78:	83 c4 10             	add    $0x10,%esp
80104f7b:	85 c0                	test   %eax,%eax
80104f7d:	78 24                	js     80104fa3 <sys_dump_physmem+0x6a>
    return -1;

  return dump_physmem(frames, pids, numframes);
80104f7f:	83 ec 04             	sub    $0x4,%esp
80104f82:	ff 75 ec             	pushl  -0x14(%ebp)
80104f85:	ff 75 f0             	pushl  -0x10(%ebp)
80104f88:	ff 75 f4             	pushl  -0xc(%ebp)
80104f8b:	e8 7e d3 ff ff       	call   8010230e <dump_physmem>
80104f90:	83 c4 10             	add    $0x10,%esp
80104f93:	c9                   	leave  
80104f94:	c3                   	ret    
    return -1;
80104f95:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f9a:	eb f7                	jmp    80104f93 <sys_dump_physmem+0x5a>
    return -1;
80104f9c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fa1:	eb f0                	jmp    80104f93 <sys_dump_physmem+0x5a>
    return -1;
80104fa3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fa8:	eb e9                	jmp    80104f93 <sys_dump_physmem+0x5a>

80104faa <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104faa:	1e                   	push   %ds
  pushl %es
80104fab:	06                   	push   %es
  pushl %fs
80104fac:	0f a0                	push   %fs
  pushl %gs
80104fae:	0f a8                	push   %gs
  pushal
80104fb0:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104fb1:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104fb5:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104fb7:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104fb9:	54                   	push   %esp
  call trap
80104fba:	e8 e3 00 00 00       	call   801050a2 <trap>
  addl $4, %esp
80104fbf:	83 c4 04             	add    $0x4,%esp

80104fc2 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104fc2:	61                   	popa   
  popl %gs
80104fc3:	0f a9                	pop    %gs
  popl %fs
80104fc5:	0f a1                	pop    %fs
  popl %es
80104fc7:	07                   	pop    %es
  popl %ds
80104fc8:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104fc9:	83 c4 08             	add    $0x8,%esp
  iret
80104fcc:	cf                   	iret   

80104fcd <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80104fcd:	55                   	push   %ebp
80104fce:	89 e5                	mov    %esp,%ebp
80104fd0:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
80104fd3:	b8 00 00 00 00       	mov    $0x0,%eax
80104fd8:	eb 4a                	jmp    80105024 <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104fda:	8b 0c 85 08 a0 10 80 	mov    -0x7fef5ff8(,%eax,4),%ecx
80104fe1:	66 89 0c c5 20 4d 13 	mov    %cx,-0x7fecb2e0(,%eax,8)
80104fe8:	80 
80104fe9:	66 c7 04 c5 22 4d 13 	movw   $0x8,-0x7fecb2de(,%eax,8)
80104ff0:	80 08 00 
80104ff3:	c6 04 c5 24 4d 13 80 	movb   $0x0,-0x7fecb2dc(,%eax,8)
80104ffa:	00 
80104ffb:	0f b6 14 c5 25 4d 13 	movzbl -0x7fecb2db(,%eax,8),%edx
80105002:	80 
80105003:	83 e2 f0             	and    $0xfffffff0,%edx
80105006:	83 ca 0e             	or     $0xe,%edx
80105009:	83 e2 8f             	and    $0xffffff8f,%edx
8010500c:	83 ca 80             	or     $0xffffff80,%edx
8010500f:	88 14 c5 25 4d 13 80 	mov    %dl,-0x7fecb2db(,%eax,8)
80105016:	c1 e9 10             	shr    $0x10,%ecx
80105019:	66 89 0c c5 26 4d 13 	mov    %cx,-0x7fecb2da(,%eax,8)
80105020:	80 
  for(i = 0; i < 256; i++)
80105021:	83 c0 01             	add    $0x1,%eax
80105024:	3d ff 00 00 00       	cmp    $0xff,%eax
80105029:	7e af                	jle    80104fda <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
8010502b:	8b 15 08 a1 10 80    	mov    0x8010a108,%edx
80105031:	66 89 15 20 4f 13 80 	mov    %dx,0x80134f20
80105038:	66 c7 05 22 4f 13 80 	movw   $0x8,0x80134f22
8010503f:	08 00 
80105041:	c6 05 24 4f 13 80 00 	movb   $0x0,0x80134f24
80105048:	0f b6 05 25 4f 13 80 	movzbl 0x80134f25,%eax
8010504f:	83 c8 0f             	or     $0xf,%eax
80105052:	83 e0 ef             	and    $0xffffffef,%eax
80105055:	83 c8 e0             	or     $0xffffffe0,%eax
80105058:	a2 25 4f 13 80       	mov    %al,0x80134f25
8010505d:	c1 ea 10             	shr    $0x10,%edx
80105060:	66 89 15 26 4f 13 80 	mov    %dx,0x80134f26

  initlock(&tickslock, "time");
80105067:	83 ec 08             	sub    $0x8,%esp
8010506a:	68 dd 6e 10 80       	push   $0x80106edd
8010506f:	68 e0 4c 13 80       	push   $0x80134ce0
80105074:	e8 4b ec ff ff       	call   80103cc4 <initlock>
}
80105079:	83 c4 10             	add    $0x10,%esp
8010507c:	c9                   	leave  
8010507d:	c3                   	ret    

8010507e <idtinit>:

void
idtinit(void)
{
8010507e:	55                   	push   %ebp
8010507f:	89 e5                	mov    %esp,%ebp
80105081:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80105084:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
8010508a:	b8 20 4d 13 80       	mov    $0x80134d20,%eax
8010508f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80105093:	c1 e8 10             	shr    $0x10,%eax
80105096:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
8010509a:	8d 45 fa             	lea    -0x6(%ebp),%eax
8010509d:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
801050a0:	c9                   	leave  
801050a1:	c3                   	ret    

801050a2 <trap>:

void
trap(struct trapframe *tf)
{
801050a2:	55                   	push   %ebp
801050a3:	89 e5                	mov    %esp,%ebp
801050a5:	57                   	push   %edi
801050a6:	56                   	push   %esi
801050a7:	53                   	push   %ebx
801050a8:	83 ec 1c             	sub    $0x1c,%esp
801050ab:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
801050ae:	8b 43 30             	mov    0x30(%ebx),%eax
801050b1:	83 f8 40             	cmp    $0x40,%eax
801050b4:	74 13                	je     801050c9 <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
801050b6:	83 e8 20             	sub    $0x20,%eax
801050b9:	83 f8 1f             	cmp    $0x1f,%eax
801050bc:	0f 87 3a 01 00 00    	ja     801051fc <trap+0x15a>
801050c2:	ff 24 85 84 6f 10 80 	jmp    *-0x7fef907c(,%eax,4)
    if(myproc()->killed)
801050c9:	e8 90 e3 ff ff       	call   8010345e <myproc>
801050ce:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801050d2:	75 1f                	jne    801050f3 <trap+0x51>
    myproc()->tf = tf;
801050d4:	e8 85 e3 ff ff       	call   8010345e <myproc>
801050d9:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
801050dc:	e8 d9 f0 ff ff       	call   801041ba <syscall>
    if(myproc()->killed)
801050e1:	e8 78 e3 ff ff       	call   8010345e <myproc>
801050e6:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801050ea:	74 7e                	je     8010516a <trap+0xc8>
      exit();
801050ec:	e8 1c e7 ff ff       	call   8010380d <exit>
801050f1:	eb 77                	jmp    8010516a <trap+0xc8>
      exit();
801050f3:	e8 15 e7 ff ff       	call   8010380d <exit>
801050f8:	eb da                	jmp    801050d4 <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
801050fa:	e8 44 e3 ff ff       	call   80103443 <cpuid>
801050ff:	85 c0                	test   %eax,%eax
80105101:	74 6f                	je     80105172 <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
80105103:	e8 f1 d4 ff ff       	call   801025f9 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105108:	e8 51 e3 ff ff       	call   8010345e <myproc>
8010510d:	85 c0                	test   %eax,%eax
8010510f:	74 1c                	je     8010512d <trap+0x8b>
80105111:	e8 48 e3 ff ff       	call   8010345e <myproc>
80105116:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010511a:	74 11                	je     8010512d <trap+0x8b>
8010511c:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105120:	83 e0 03             	and    $0x3,%eax
80105123:	66 83 f8 03          	cmp    $0x3,%ax
80105127:	0f 84 62 01 00 00    	je     8010528f <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
8010512d:	e8 2c e3 ff ff       	call   8010345e <myproc>
80105132:	85 c0                	test   %eax,%eax
80105134:	74 0f                	je     80105145 <trap+0xa3>
80105136:	e8 23 e3 ff ff       	call   8010345e <myproc>
8010513b:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
8010513f:	0f 84 54 01 00 00    	je     80105299 <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105145:	e8 14 e3 ff ff       	call   8010345e <myproc>
8010514a:	85 c0                	test   %eax,%eax
8010514c:	74 1c                	je     8010516a <trap+0xc8>
8010514e:	e8 0b e3 ff ff       	call   8010345e <myproc>
80105153:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105157:	74 11                	je     8010516a <trap+0xc8>
80105159:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
8010515d:	83 e0 03             	and    $0x3,%eax
80105160:	66 83 f8 03          	cmp    $0x3,%ax
80105164:	0f 84 43 01 00 00    	je     801052ad <trap+0x20b>
    exit();
}
8010516a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010516d:	5b                   	pop    %ebx
8010516e:	5e                   	pop    %esi
8010516f:	5f                   	pop    %edi
80105170:	5d                   	pop    %ebp
80105171:	c3                   	ret    
      acquire(&tickslock);
80105172:	83 ec 0c             	sub    $0xc,%esp
80105175:	68 e0 4c 13 80       	push   $0x80134ce0
8010517a:	e8 81 ec ff ff       	call   80103e00 <acquire>
      ticks++;
8010517f:	83 05 20 55 13 80 01 	addl   $0x1,0x80135520
      wakeup(&ticks);
80105186:	c7 04 24 20 55 13 80 	movl   $0x80135520,(%esp)
8010518d:	e8 d8 e8 ff ff       	call   80103a6a <wakeup>
      release(&tickslock);
80105192:	c7 04 24 e0 4c 13 80 	movl   $0x80134ce0,(%esp)
80105199:	e8 c7 ec ff ff       	call   80103e65 <release>
8010519e:	83 c4 10             	add    $0x10,%esp
801051a1:	e9 5d ff ff ff       	jmp    80105103 <trap+0x61>
    ideintr();
801051a6:	e8 c8 cb ff ff       	call   80101d73 <ideintr>
    lapiceoi();
801051ab:	e8 49 d4 ff ff       	call   801025f9 <lapiceoi>
    break;
801051b0:	e9 53 ff ff ff       	jmp    80105108 <trap+0x66>
    kbdintr();
801051b5:	e8 83 d2 ff ff       	call   8010243d <kbdintr>
    lapiceoi();
801051ba:	e8 3a d4 ff ff       	call   801025f9 <lapiceoi>
    break;
801051bf:	e9 44 ff ff ff       	jmp    80105108 <trap+0x66>
    uartintr();
801051c4:	e8 05 02 00 00       	call   801053ce <uartintr>
    lapiceoi();
801051c9:	e8 2b d4 ff ff       	call   801025f9 <lapiceoi>
    break;
801051ce:	e9 35 ff ff ff       	jmp    80105108 <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801051d3:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
801051d6:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801051da:	e8 64 e2 ff ff       	call   80103443 <cpuid>
801051df:	57                   	push   %edi
801051e0:	0f b7 f6             	movzwl %si,%esi
801051e3:	56                   	push   %esi
801051e4:	50                   	push   %eax
801051e5:	68 e8 6e 10 80       	push   $0x80106ee8
801051ea:	e8 1c b4 ff ff       	call   8010060b <cprintf>
    lapiceoi();
801051ef:	e8 05 d4 ff ff       	call   801025f9 <lapiceoi>
    break;
801051f4:	83 c4 10             	add    $0x10,%esp
801051f7:	e9 0c ff ff ff       	jmp    80105108 <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
801051fc:	e8 5d e2 ff ff       	call   8010345e <myproc>
80105201:	85 c0                	test   %eax,%eax
80105203:	74 5f                	je     80105264 <trap+0x1c2>
80105205:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
80105209:	74 59                	je     80105264 <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
8010520b:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010520e:	8b 43 38             	mov    0x38(%ebx),%eax
80105211:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105214:	e8 2a e2 ff ff       	call   80103443 <cpuid>
80105219:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010521c:	8b 53 34             	mov    0x34(%ebx),%edx
8010521f:	89 55 dc             	mov    %edx,-0x24(%ebp)
80105222:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
80105225:	e8 34 e2 ff ff       	call   8010345e <myproc>
8010522a:	8d 48 6c             	lea    0x6c(%eax),%ecx
8010522d:	89 4d d8             	mov    %ecx,-0x28(%ebp)
80105230:	e8 29 e2 ff ff       	call   8010345e <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105235:	57                   	push   %edi
80105236:	ff 75 e4             	pushl  -0x1c(%ebp)
80105239:	ff 75 e0             	pushl  -0x20(%ebp)
8010523c:	ff 75 dc             	pushl  -0x24(%ebp)
8010523f:	56                   	push   %esi
80105240:	ff 75 d8             	pushl  -0x28(%ebp)
80105243:	ff 70 10             	pushl  0x10(%eax)
80105246:	68 40 6f 10 80       	push   $0x80106f40
8010524b:	e8 bb b3 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
80105250:	83 c4 20             	add    $0x20,%esp
80105253:	e8 06 e2 ff ff       	call   8010345e <myproc>
80105258:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010525f:	e9 a4 fe ff ff       	jmp    80105108 <trap+0x66>
80105264:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80105267:	8b 73 38             	mov    0x38(%ebx),%esi
8010526a:	e8 d4 e1 ff ff       	call   80103443 <cpuid>
8010526f:	83 ec 0c             	sub    $0xc,%esp
80105272:	57                   	push   %edi
80105273:	56                   	push   %esi
80105274:	50                   	push   %eax
80105275:	ff 73 30             	pushl  0x30(%ebx)
80105278:	68 0c 6f 10 80       	push   $0x80106f0c
8010527d:	e8 89 b3 ff ff       	call   8010060b <cprintf>
      panic("trap");
80105282:	83 c4 14             	add    $0x14,%esp
80105285:	68 e2 6e 10 80       	push   $0x80106ee2
8010528a:	e8 b9 b0 ff ff       	call   80100348 <panic>
    exit();
8010528f:	e8 79 e5 ff ff       	call   8010380d <exit>
80105294:	e9 94 fe ff ff       	jmp    8010512d <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
80105299:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
8010529d:	0f 85 a2 fe ff ff    	jne    80105145 <trap+0xa3>
    yield();
801052a3:	e8 2b e6 ff ff       	call   801038d3 <yield>
801052a8:	e9 98 fe ff ff       	jmp    80105145 <trap+0xa3>
    exit();
801052ad:	e8 5b e5 ff ff       	call   8010380d <exit>
801052b2:	e9 b3 fe ff ff       	jmp    8010516a <trap+0xc8>

801052b7 <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
801052b7:	55                   	push   %ebp
801052b8:	89 e5                	mov    %esp,%ebp
  if(!uart)
801052ba:	83 3d c0 a5 10 80 00 	cmpl   $0x0,0x8010a5c0
801052c1:	74 15                	je     801052d8 <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801052c3:	ba fd 03 00 00       	mov    $0x3fd,%edx
801052c8:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
801052c9:	a8 01                	test   $0x1,%al
801052cb:	74 12                	je     801052df <uartgetc+0x28>
801052cd:	ba f8 03 00 00       	mov    $0x3f8,%edx
801052d2:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
801052d3:	0f b6 c0             	movzbl %al,%eax
}
801052d6:	5d                   	pop    %ebp
801052d7:	c3                   	ret    
    return -1;
801052d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052dd:	eb f7                	jmp    801052d6 <uartgetc+0x1f>
    return -1;
801052df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052e4:	eb f0                	jmp    801052d6 <uartgetc+0x1f>

801052e6 <uartputc>:
  if(!uart)
801052e6:	83 3d c0 a5 10 80 00 	cmpl   $0x0,0x8010a5c0
801052ed:	74 3b                	je     8010532a <uartputc+0x44>
{
801052ef:	55                   	push   %ebp
801052f0:	89 e5                	mov    %esp,%ebp
801052f2:	53                   	push   %ebx
801052f3:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801052f6:	bb 00 00 00 00       	mov    $0x0,%ebx
801052fb:	eb 10                	jmp    8010530d <uartputc+0x27>
    microdelay(10);
801052fd:	83 ec 0c             	sub    $0xc,%esp
80105300:	6a 0a                	push   $0xa
80105302:	e8 11 d3 ff ff       	call   80102618 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105307:	83 c3 01             	add    $0x1,%ebx
8010530a:	83 c4 10             	add    $0x10,%esp
8010530d:	83 fb 7f             	cmp    $0x7f,%ebx
80105310:	7f 0a                	jg     8010531c <uartputc+0x36>
80105312:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105317:	ec                   	in     (%dx),%al
80105318:	a8 20                	test   $0x20,%al
8010531a:	74 e1                	je     801052fd <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010531c:	8b 45 08             	mov    0x8(%ebp),%eax
8010531f:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105324:	ee                   	out    %al,(%dx)
}
80105325:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105328:	c9                   	leave  
80105329:	c3                   	ret    
8010532a:	f3 c3                	repz ret 

8010532c <uartinit>:
{
8010532c:	55                   	push   %ebp
8010532d:	89 e5                	mov    %esp,%ebp
8010532f:	56                   	push   %esi
80105330:	53                   	push   %ebx
80105331:	b9 00 00 00 00       	mov    $0x0,%ecx
80105336:	ba fa 03 00 00       	mov    $0x3fa,%edx
8010533b:	89 c8                	mov    %ecx,%eax
8010533d:	ee                   	out    %al,(%dx)
8010533e:	be fb 03 00 00       	mov    $0x3fb,%esi
80105343:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
80105348:	89 f2                	mov    %esi,%edx
8010534a:	ee                   	out    %al,(%dx)
8010534b:	b8 0c 00 00 00       	mov    $0xc,%eax
80105350:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105355:	ee                   	out    %al,(%dx)
80105356:	bb f9 03 00 00       	mov    $0x3f9,%ebx
8010535b:	89 c8                	mov    %ecx,%eax
8010535d:	89 da                	mov    %ebx,%edx
8010535f:	ee                   	out    %al,(%dx)
80105360:	b8 03 00 00 00       	mov    $0x3,%eax
80105365:	89 f2                	mov    %esi,%edx
80105367:	ee                   	out    %al,(%dx)
80105368:	ba fc 03 00 00       	mov    $0x3fc,%edx
8010536d:	89 c8                	mov    %ecx,%eax
8010536f:	ee                   	out    %al,(%dx)
80105370:	b8 01 00 00 00       	mov    $0x1,%eax
80105375:	89 da                	mov    %ebx,%edx
80105377:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105378:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010537d:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
8010537e:	3c ff                	cmp    $0xff,%al
80105380:	74 45                	je     801053c7 <uartinit+0x9b>
  uart = 1;
80105382:	c7 05 c0 a5 10 80 01 	movl   $0x1,0x8010a5c0
80105389:	00 00 00 
8010538c:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105391:	ec                   	in     (%dx),%al
80105392:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105397:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
80105398:	83 ec 08             	sub    $0x8,%esp
8010539b:	6a 00                	push   $0x0
8010539d:	6a 04                	push   $0x4
8010539f:	e8 da cb ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
801053a4:	83 c4 10             	add    $0x10,%esp
801053a7:	bb 04 70 10 80       	mov    $0x80107004,%ebx
801053ac:	eb 12                	jmp    801053c0 <uartinit+0x94>
    uartputc(*p);
801053ae:	83 ec 0c             	sub    $0xc,%esp
801053b1:	0f be c0             	movsbl %al,%eax
801053b4:	50                   	push   %eax
801053b5:	e8 2c ff ff ff       	call   801052e6 <uartputc>
  for(p="xv6...\n"; *p; p++)
801053ba:	83 c3 01             	add    $0x1,%ebx
801053bd:	83 c4 10             	add    $0x10,%esp
801053c0:	0f b6 03             	movzbl (%ebx),%eax
801053c3:	84 c0                	test   %al,%al
801053c5:	75 e7                	jne    801053ae <uartinit+0x82>
}
801053c7:	8d 65 f8             	lea    -0x8(%ebp),%esp
801053ca:	5b                   	pop    %ebx
801053cb:	5e                   	pop    %esi
801053cc:	5d                   	pop    %ebp
801053cd:	c3                   	ret    

801053ce <uartintr>:

void
uartintr(void)
{
801053ce:	55                   	push   %ebp
801053cf:	89 e5                	mov    %esp,%ebp
801053d1:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
801053d4:	68 b7 52 10 80       	push   $0x801052b7
801053d9:	e8 60 b3 ff ff       	call   8010073e <consoleintr>
}
801053de:	83 c4 10             	add    $0x10,%esp
801053e1:	c9                   	leave  
801053e2:	c3                   	ret    

801053e3 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801053e3:	6a 00                	push   $0x0
  pushl $0
801053e5:	6a 00                	push   $0x0
  jmp alltraps
801053e7:	e9 be fb ff ff       	jmp    80104faa <alltraps>

801053ec <vector1>:
.globl vector1
vector1:
  pushl $0
801053ec:	6a 00                	push   $0x0
  pushl $1
801053ee:	6a 01                	push   $0x1
  jmp alltraps
801053f0:	e9 b5 fb ff ff       	jmp    80104faa <alltraps>

801053f5 <vector2>:
.globl vector2
vector2:
  pushl $0
801053f5:	6a 00                	push   $0x0
  pushl $2
801053f7:	6a 02                	push   $0x2
  jmp alltraps
801053f9:	e9 ac fb ff ff       	jmp    80104faa <alltraps>

801053fe <vector3>:
.globl vector3
vector3:
  pushl $0
801053fe:	6a 00                	push   $0x0
  pushl $3
80105400:	6a 03                	push   $0x3
  jmp alltraps
80105402:	e9 a3 fb ff ff       	jmp    80104faa <alltraps>

80105407 <vector4>:
.globl vector4
vector4:
  pushl $0
80105407:	6a 00                	push   $0x0
  pushl $4
80105409:	6a 04                	push   $0x4
  jmp alltraps
8010540b:	e9 9a fb ff ff       	jmp    80104faa <alltraps>

80105410 <vector5>:
.globl vector5
vector5:
  pushl $0
80105410:	6a 00                	push   $0x0
  pushl $5
80105412:	6a 05                	push   $0x5
  jmp alltraps
80105414:	e9 91 fb ff ff       	jmp    80104faa <alltraps>

80105419 <vector6>:
.globl vector6
vector6:
  pushl $0
80105419:	6a 00                	push   $0x0
  pushl $6
8010541b:	6a 06                	push   $0x6
  jmp alltraps
8010541d:	e9 88 fb ff ff       	jmp    80104faa <alltraps>

80105422 <vector7>:
.globl vector7
vector7:
  pushl $0
80105422:	6a 00                	push   $0x0
  pushl $7
80105424:	6a 07                	push   $0x7
  jmp alltraps
80105426:	e9 7f fb ff ff       	jmp    80104faa <alltraps>

8010542b <vector8>:
.globl vector8
vector8:
  pushl $8
8010542b:	6a 08                	push   $0x8
  jmp alltraps
8010542d:	e9 78 fb ff ff       	jmp    80104faa <alltraps>

80105432 <vector9>:
.globl vector9
vector9:
  pushl $0
80105432:	6a 00                	push   $0x0
  pushl $9
80105434:	6a 09                	push   $0x9
  jmp alltraps
80105436:	e9 6f fb ff ff       	jmp    80104faa <alltraps>

8010543b <vector10>:
.globl vector10
vector10:
  pushl $10
8010543b:	6a 0a                	push   $0xa
  jmp alltraps
8010543d:	e9 68 fb ff ff       	jmp    80104faa <alltraps>

80105442 <vector11>:
.globl vector11
vector11:
  pushl $11
80105442:	6a 0b                	push   $0xb
  jmp alltraps
80105444:	e9 61 fb ff ff       	jmp    80104faa <alltraps>

80105449 <vector12>:
.globl vector12
vector12:
  pushl $12
80105449:	6a 0c                	push   $0xc
  jmp alltraps
8010544b:	e9 5a fb ff ff       	jmp    80104faa <alltraps>

80105450 <vector13>:
.globl vector13
vector13:
  pushl $13
80105450:	6a 0d                	push   $0xd
  jmp alltraps
80105452:	e9 53 fb ff ff       	jmp    80104faa <alltraps>

80105457 <vector14>:
.globl vector14
vector14:
  pushl $14
80105457:	6a 0e                	push   $0xe
  jmp alltraps
80105459:	e9 4c fb ff ff       	jmp    80104faa <alltraps>

8010545e <vector15>:
.globl vector15
vector15:
  pushl $0
8010545e:	6a 00                	push   $0x0
  pushl $15
80105460:	6a 0f                	push   $0xf
  jmp alltraps
80105462:	e9 43 fb ff ff       	jmp    80104faa <alltraps>

80105467 <vector16>:
.globl vector16
vector16:
  pushl $0
80105467:	6a 00                	push   $0x0
  pushl $16
80105469:	6a 10                	push   $0x10
  jmp alltraps
8010546b:	e9 3a fb ff ff       	jmp    80104faa <alltraps>

80105470 <vector17>:
.globl vector17
vector17:
  pushl $17
80105470:	6a 11                	push   $0x11
  jmp alltraps
80105472:	e9 33 fb ff ff       	jmp    80104faa <alltraps>

80105477 <vector18>:
.globl vector18
vector18:
  pushl $0
80105477:	6a 00                	push   $0x0
  pushl $18
80105479:	6a 12                	push   $0x12
  jmp alltraps
8010547b:	e9 2a fb ff ff       	jmp    80104faa <alltraps>

80105480 <vector19>:
.globl vector19
vector19:
  pushl $0
80105480:	6a 00                	push   $0x0
  pushl $19
80105482:	6a 13                	push   $0x13
  jmp alltraps
80105484:	e9 21 fb ff ff       	jmp    80104faa <alltraps>

80105489 <vector20>:
.globl vector20
vector20:
  pushl $0
80105489:	6a 00                	push   $0x0
  pushl $20
8010548b:	6a 14                	push   $0x14
  jmp alltraps
8010548d:	e9 18 fb ff ff       	jmp    80104faa <alltraps>

80105492 <vector21>:
.globl vector21
vector21:
  pushl $0
80105492:	6a 00                	push   $0x0
  pushl $21
80105494:	6a 15                	push   $0x15
  jmp alltraps
80105496:	e9 0f fb ff ff       	jmp    80104faa <alltraps>

8010549b <vector22>:
.globl vector22
vector22:
  pushl $0
8010549b:	6a 00                	push   $0x0
  pushl $22
8010549d:	6a 16                	push   $0x16
  jmp alltraps
8010549f:	e9 06 fb ff ff       	jmp    80104faa <alltraps>

801054a4 <vector23>:
.globl vector23
vector23:
  pushl $0
801054a4:	6a 00                	push   $0x0
  pushl $23
801054a6:	6a 17                	push   $0x17
  jmp alltraps
801054a8:	e9 fd fa ff ff       	jmp    80104faa <alltraps>

801054ad <vector24>:
.globl vector24
vector24:
  pushl $0
801054ad:	6a 00                	push   $0x0
  pushl $24
801054af:	6a 18                	push   $0x18
  jmp alltraps
801054b1:	e9 f4 fa ff ff       	jmp    80104faa <alltraps>

801054b6 <vector25>:
.globl vector25
vector25:
  pushl $0
801054b6:	6a 00                	push   $0x0
  pushl $25
801054b8:	6a 19                	push   $0x19
  jmp alltraps
801054ba:	e9 eb fa ff ff       	jmp    80104faa <alltraps>

801054bf <vector26>:
.globl vector26
vector26:
  pushl $0
801054bf:	6a 00                	push   $0x0
  pushl $26
801054c1:	6a 1a                	push   $0x1a
  jmp alltraps
801054c3:	e9 e2 fa ff ff       	jmp    80104faa <alltraps>

801054c8 <vector27>:
.globl vector27
vector27:
  pushl $0
801054c8:	6a 00                	push   $0x0
  pushl $27
801054ca:	6a 1b                	push   $0x1b
  jmp alltraps
801054cc:	e9 d9 fa ff ff       	jmp    80104faa <alltraps>

801054d1 <vector28>:
.globl vector28
vector28:
  pushl $0
801054d1:	6a 00                	push   $0x0
  pushl $28
801054d3:	6a 1c                	push   $0x1c
  jmp alltraps
801054d5:	e9 d0 fa ff ff       	jmp    80104faa <alltraps>

801054da <vector29>:
.globl vector29
vector29:
  pushl $0
801054da:	6a 00                	push   $0x0
  pushl $29
801054dc:	6a 1d                	push   $0x1d
  jmp alltraps
801054de:	e9 c7 fa ff ff       	jmp    80104faa <alltraps>

801054e3 <vector30>:
.globl vector30
vector30:
  pushl $0
801054e3:	6a 00                	push   $0x0
  pushl $30
801054e5:	6a 1e                	push   $0x1e
  jmp alltraps
801054e7:	e9 be fa ff ff       	jmp    80104faa <alltraps>

801054ec <vector31>:
.globl vector31
vector31:
  pushl $0
801054ec:	6a 00                	push   $0x0
  pushl $31
801054ee:	6a 1f                	push   $0x1f
  jmp alltraps
801054f0:	e9 b5 fa ff ff       	jmp    80104faa <alltraps>

801054f5 <vector32>:
.globl vector32
vector32:
  pushl $0
801054f5:	6a 00                	push   $0x0
  pushl $32
801054f7:	6a 20                	push   $0x20
  jmp alltraps
801054f9:	e9 ac fa ff ff       	jmp    80104faa <alltraps>

801054fe <vector33>:
.globl vector33
vector33:
  pushl $0
801054fe:	6a 00                	push   $0x0
  pushl $33
80105500:	6a 21                	push   $0x21
  jmp alltraps
80105502:	e9 a3 fa ff ff       	jmp    80104faa <alltraps>

80105507 <vector34>:
.globl vector34
vector34:
  pushl $0
80105507:	6a 00                	push   $0x0
  pushl $34
80105509:	6a 22                	push   $0x22
  jmp alltraps
8010550b:	e9 9a fa ff ff       	jmp    80104faa <alltraps>

80105510 <vector35>:
.globl vector35
vector35:
  pushl $0
80105510:	6a 00                	push   $0x0
  pushl $35
80105512:	6a 23                	push   $0x23
  jmp alltraps
80105514:	e9 91 fa ff ff       	jmp    80104faa <alltraps>

80105519 <vector36>:
.globl vector36
vector36:
  pushl $0
80105519:	6a 00                	push   $0x0
  pushl $36
8010551b:	6a 24                	push   $0x24
  jmp alltraps
8010551d:	e9 88 fa ff ff       	jmp    80104faa <alltraps>

80105522 <vector37>:
.globl vector37
vector37:
  pushl $0
80105522:	6a 00                	push   $0x0
  pushl $37
80105524:	6a 25                	push   $0x25
  jmp alltraps
80105526:	e9 7f fa ff ff       	jmp    80104faa <alltraps>

8010552b <vector38>:
.globl vector38
vector38:
  pushl $0
8010552b:	6a 00                	push   $0x0
  pushl $38
8010552d:	6a 26                	push   $0x26
  jmp alltraps
8010552f:	e9 76 fa ff ff       	jmp    80104faa <alltraps>

80105534 <vector39>:
.globl vector39
vector39:
  pushl $0
80105534:	6a 00                	push   $0x0
  pushl $39
80105536:	6a 27                	push   $0x27
  jmp alltraps
80105538:	e9 6d fa ff ff       	jmp    80104faa <alltraps>

8010553d <vector40>:
.globl vector40
vector40:
  pushl $0
8010553d:	6a 00                	push   $0x0
  pushl $40
8010553f:	6a 28                	push   $0x28
  jmp alltraps
80105541:	e9 64 fa ff ff       	jmp    80104faa <alltraps>

80105546 <vector41>:
.globl vector41
vector41:
  pushl $0
80105546:	6a 00                	push   $0x0
  pushl $41
80105548:	6a 29                	push   $0x29
  jmp alltraps
8010554a:	e9 5b fa ff ff       	jmp    80104faa <alltraps>

8010554f <vector42>:
.globl vector42
vector42:
  pushl $0
8010554f:	6a 00                	push   $0x0
  pushl $42
80105551:	6a 2a                	push   $0x2a
  jmp alltraps
80105553:	e9 52 fa ff ff       	jmp    80104faa <alltraps>

80105558 <vector43>:
.globl vector43
vector43:
  pushl $0
80105558:	6a 00                	push   $0x0
  pushl $43
8010555a:	6a 2b                	push   $0x2b
  jmp alltraps
8010555c:	e9 49 fa ff ff       	jmp    80104faa <alltraps>

80105561 <vector44>:
.globl vector44
vector44:
  pushl $0
80105561:	6a 00                	push   $0x0
  pushl $44
80105563:	6a 2c                	push   $0x2c
  jmp alltraps
80105565:	e9 40 fa ff ff       	jmp    80104faa <alltraps>

8010556a <vector45>:
.globl vector45
vector45:
  pushl $0
8010556a:	6a 00                	push   $0x0
  pushl $45
8010556c:	6a 2d                	push   $0x2d
  jmp alltraps
8010556e:	e9 37 fa ff ff       	jmp    80104faa <alltraps>

80105573 <vector46>:
.globl vector46
vector46:
  pushl $0
80105573:	6a 00                	push   $0x0
  pushl $46
80105575:	6a 2e                	push   $0x2e
  jmp alltraps
80105577:	e9 2e fa ff ff       	jmp    80104faa <alltraps>

8010557c <vector47>:
.globl vector47
vector47:
  pushl $0
8010557c:	6a 00                	push   $0x0
  pushl $47
8010557e:	6a 2f                	push   $0x2f
  jmp alltraps
80105580:	e9 25 fa ff ff       	jmp    80104faa <alltraps>

80105585 <vector48>:
.globl vector48
vector48:
  pushl $0
80105585:	6a 00                	push   $0x0
  pushl $48
80105587:	6a 30                	push   $0x30
  jmp alltraps
80105589:	e9 1c fa ff ff       	jmp    80104faa <alltraps>

8010558e <vector49>:
.globl vector49
vector49:
  pushl $0
8010558e:	6a 00                	push   $0x0
  pushl $49
80105590:	6a 31                	push   $0x31
  jmp alltraps
80105592:	e9 13 fa ff ff       	jmp    80104faa <alltraps>

80105597 <vector50>:
.globl vector50
vector50:
  pushl $0
80105597:	6a 00                	push   $0x0
  pushl $50
80105599:	6a 32                	push   $0x32
  jmp alltraps
8010559b:	e9 0a fa ff ff       	jmp    80104faa <alltraps>

801055a0 <vector51>:
.globl vector51
vector51:
  pushl $0
801055a0:	6a 00                	push   $0x0
  pushl $51
801055a2:	6a 33                	push   $0x33
  jmp alltraps
801055a4:	e9 01 fa ff ff       	jmp    80104faa <alltraps>

801055a9 <vector52>:
.globl vector52
vector52:
  pushl $0
801055a9:	6a 00                	push   $0x0
  pushl $52
801055ab:	6a 34                	push   $0x34
  jmp alltraps
801055ad:	e9 f8 f9 ff ff       	jmp    80104faa <alltraps>

801055b2 <vector53>:
.globl vector53
vector53:
  pushl $0
801055b2:	6a 00                	push   $0x0
  pushl $53
801055b4:	6a 35                	push   $0x35
  jmp alltraps
801055b6:	e9 ef f9 ff ff       	jmp    80104faa <alltraps>

801055bb <vector54>:
.globl vector54
vector54:
  pushl $0
801055bb:	6a 00                	push   $0x0
  pushl $54
801055bd:	6a 36                	push   $0x36
  jmp alltraps
801055bf:	e9 e6 f9 ff ff       	jmp    80104faa <alltraps>

801055c4 <vector55>:
.globl vector55
vector55:
  pushl $0
801055c4:	6a 00                	push   $0x0
  pushl $55
801055c6:	6a 37                	push   $0x37
  jmp alltraps
801055c8:	e9 dd f9 ff ff       	jmp    80104faa <alltraps>

801055cd <vector56>:
.globl vector56
vector56:
  pushl $0
801055cd:	6a 00                	push   $0x0
  pushl $56
801055cf:	6a 38                	push   $0x38
  jmp alltraps
801055d1:	e9 d4 f9 ff ff       	jmp    80104faa <alltraps>

801055d6 <vector57>:
.globl vector57
vector57:
  pushl $0
801055d6:	6a 00                	push   $0x0
  pushl $57
801055d8:	6a 39                	push   $0x39
  jmp alltraps
801055da:	e9 cb f9 ff ff       	jmp    80104faa <alltraps>

801055df <vector58>:
.globl vector58
vector58:
  pushl $0
801055df:	6a 00                	push   $0x0
  pushl $58
801055e1:	6a 3a                	push   $0x3a
  jmp alltraps
801055e3:	e9 c2 f9 ff ff       	jmp    80104faa <alltraps>

801055e8 <vector59>:
.globl vector59
vector59:
  pushl $0
801055e8:	6a 00                	push   $0x0
  pushl $59
801055ea:	6a 3b                	push   $0x3b
  jmp alltraps
801055ec:	e9 b9 f9 ff ff       	jmp    80104faa <alltraps>

801055f1 <vector60>:
.globl vector60
vector60:
  pushl $0
801055f1:	6a 00                	push   $0x0
  pushl $60
801055f3:	6a 3c                	push   $0x3c
  jmp alltraps
801055f5:	e9 b0 f9 ff ff       	jmp    80104faa <alltraps>

801055fa <vector61>:
.globl vector61
vector61:
  pushl $0
801055fa:	6a 00                	push   $0x0
  pushl $61
801055fc:	6a 3d                	push   $0x3d
  jmp alltraps
801055fe:	e9 a7 f9 ff ff       	jmp    80104faa <alltraps>

80105603 <vector62>:
.globl vector62
vector62:
  pushl $0
80105603:	6a 00                	push   $0x0
  pushl $62
80105605:	6a 3e                	push   $0x3e
  jmp alltraps
80105607:	e9 9e f9 ff ff       	jmp    80104faa <alltraps>

8010560c <vector63>:
.globl vector63
vector63:
  pushl $0
8010560c:	6a 00                	push   $0x0
  pushl $63
8010560e:	6a 3f                	push   $0x3f
  jmp alltraps
80105610:	e9 95 f9 ff ff       	jmp    80104faa <alltraps>

80105615 <vector64>:
.globl vector64
vector64:
  pushl $0
80105615:	6a 00                	push   $0x0
  pushl $64
80105617:	6a 40                	push   $0x40
  jmp alltraps
80105619:	e9 8c f9 ff ff       	jmp    80104faa <alltraps>

8010561e <vector65>:
.globl vector65
vector65:
  pushl $0
8010561e:	6a 00                	push   $0x0
  pushl $65
80105620:	6a 41                	push   $0x41
  jmp alltraps
80105622:	e9 83 f9 ff ff       	jmp    80104faa <alltraps>

80105627 <vector66>:
.globl vector66
vector66:
  pushl $0
80105627:	6a 00                	push   $0x0
  pushl $66
80105629:	6a 42                	push   $0x42
  jmp alltraps
8010562b:	e9 7a f9 ff ff       	jmp    80104faa <alltraps>

80105630 <vector67>:
.globl vector67
vector67:
  pushl $0
80105630:	6a 00                	push   $0x0
  pushl $67
80105632:	6a 43                	push   $0x43
  jmp alltraps
80105634:	e9 71 f9 ff ff       	jmp    80104faa <alltraps>

80105639 <vector68>:
.globl vector68
vector68:
  pushl $0
80105639:	6a 00                	push   $0x0
  pushl $68
8010563b:	6a 44                	push   $0x44
  jmp alltraps
8010563d:	e9 68 f9 ff ff       	jmp    80104faa <alltraps>

80105642 <vector69>:
.globl vector69
vector69:
  pushl $0
80105642:	6a 00                	push   $0x0
  pushl $69
80105644:	6a 45                	push   $0x45
  jmp alltraps
80105646:	e9 5f f9 ff ff       	jmp    80104faa <alltraps>

8010564b <vector70>:
.globl vector70
vector70:
  pushl $0
8010564b:	6a 00                	push   $0x0
  pushl $70
8010564d:	6a 46                	push   $0x46
  jmp alltraps
8010564f:	e9 56 f9 ff ff       	jmp    80104faa <alltraps>

80105654 <vector71>:
.globl vector71
vector71:
  pushl $0
80105654:	6a 00                	push   $0x0
  pushl $71
80105656:	6a 47                	push   $0x47
  jmp alltraps
80105658:	e9 4d f9 ff ff       	jmp    80104faa <alltraps>

8010565d <vector72>:
.globl vector72
vector72:
  pushl $0
8010565d:	6a 00                	push   $0x0
  pushl $72
8010565f:	6a 48                	push   $0x48
  jmp alltraps
80105661:	e9 44 f9 ff ff       	jmp    80104faa <alltraps>

80105666 <vector73>:
.globl vector73
vector73:
  pushl $0
80105666:	6a 00                	push   $0x0
  pushl $73
80105668:	6a 49                	push   $0x49
  jmp alltraps
8010566a:	e9 3b f9 ff ff       	jmp    80104faa <alltraps>

8010566f <vector74>:
.globl vector74
vector74:
  pushl $0
8010566f:	6a 00                	push   $0x0
  pushl $74
80105671:	6a 4a                	push   $0x4a
  jmp alltraps
80105673:	e9 32 f9 ff ff       	jmp    80104faa <alltraps>

80105678 <vector75>:
.globl vector75
vector75:
  pushl $0
80105678:	6a 00                	push   $0x0
  pushl $75
8010567a:	6a 4b                	push   $0x4b
  jmp alltraps
8010567c:	e9 29 f9 ff ff       	jmp    80104faa <alltraps>

80105681 <vector76>:
.globl vector76
vector76:
  pushl $0
80105681:	6a 00                	push   $0x0
  pushl $76
80105683:	6a 4c                	push   $0x4c
  jmp alltraps
80105685:	e9 20 f9 ff ff       	jmp    80104faa <alltraps>

8010568a <vector77>:
.globl vector77
vector77:
  pushl $0
8010568a:	6a 00                	push   $0x0
  pushl $77
8010568c:	6a 4d                	push   $0x4d
  jmp alltraps
8010568e:	e9 17 f9 ff ff       	jmp    80104faa <alltraps>

80105693 <vector78>:
.globl vector78
vector78:
  pushl $0
80105693:	6a 00                	push   $0x0
  pushl $78
80105695:	6a 4e                	push   $0x4e
  jmp alltraps
80105697:	e9 0e f9 ff ff       	jmp    80104faa <alltraps>

8010569c <vector79>:
.globl vector79
vector79:
  pushl $0
8010569c:	6a 00                	push   $0x0
  pushl $79
8010569e:	6a 4f                	push   $0x4f
  jmp alltraps
801056a0:	e9 05 f9 ff ff       	jmp    80104faa <alltraps>

801056a5 <vector80>:
.globl vector80
vector80:
  pushl $0
801056a5:	6a 00                	push   $0x0
  pushl $80
801056a7:	6a 50                	push   $0x50
  jmp alltraps
801056a9:	e9 fc f8 ff ff       	jmp    80104faa <alltraps>

801056ae <vector81>:
.globl vector81
vector81:
  pushl $0
801056ae:	6a 00                	push   $0x0
  pushl $81
801056b0:	6a 51                	push   $0x51
  jmp alltraps
801056b2:	e9 f3 f8 ff ff       	jmp    80104faa <alltraps>

801056b7 <vector82>:
.globl vector82
vector82:
  pushl $0
801056b7:	6a 00                	push   $0x0
  pushl $82
801056b9:	6a 52                	push   $0x52
  jmp alltraps
801056bb:	e9 ea f8 ff ff       	jmp    80104faa <alltraps>

801056c0 <vector83>:
.globl vector83
vector83:
  pushl $0
801056c0:	6a 00                	push   $0x0
  pushl $83
801056c2:	6a 53                	push   $0x53
  jmp alltraps
801056c4:	e9 e1 f8 ff ff       	jmp    80104faa <alltraps>

801056c9 <vector84>:
.globl vector84
vector84:
  pushl $0
801056c9:	6a 00                	push   $0x0
  pushl $84
801056cb:	6a 54                	push   $0x54
  jmp alltraps
801056cd:	e9 d8 f8 ff ff       	jmp    80104faa <alltraps>

801056d2 <vector85>:
.globl vector85
vector85:
  pushl $0
801056d2:	6a 00                	push   $0x0
  pushl $85
801056d4:	6a 55                	push   $0x55
  jmp alltraps
801056d6:	e9 cf f8 ff ff       	jmp    80104faa <alltraps>

801056db <vector86>:
.globl vector86
vector86:
  pushl $0
801056db:	6a 00                	push   $0x0
  pushl $86
801056dd:	6a 56                	push   $0x56
  jmp alltraps
801056df:	e9 c6 f8 ff ff       	jmp    80104faa <alltraps>

801056e4 <vector87>:
.globl vector87
vector87:
  pushl $0
801056e4:	6a 00                	push   $0x0
  pushl $87
801056e6:	6a 57                	push   $0x57
  jmp alltraps
801056e8:	e9 bd f8 ff ff       	jmp    80104faa <alltraps>

801056ed <vector88>:
.globl vector88
vector88:
  pushl $0
801056ed:	6a 00                	push   $0x0
  pushl $88
801056ef:	6a 58                	push   $0x58
  jmp alltraps
801056f1:	e9 b4 f8 ff ff       	jmp    80104faa <alltraps>

801056f6 <vector89>:
.globl vector89
vector89:
  pushl $0
801056f6:	6a 00                	push   $0x0
  pushl $89
801056f8:	6a 59                	push   $0x59
  jmp alltraps
801056fa:	e9 ab f8 ff ff       	jmp    80104faa <alltraps>

801056ff <vector90>:
.globl vector90
vector90:
  pushl $0
801056ff:	6a 00                	push   $0x0
  pushl $90
80105701:	6a 5a                	push   $0x5a
  jmp alltraps
80105703:	e9 a2 f8 ff ff       	jmp    80104faa <alltraps>

80105708 <vector91>:
.globl vector91
vector91:
  pushl $0
80105708:	6a 00                	push   $0x0
  pushl $91
8010570a:	6a 5b                	push   $0x5b
  jmp alltraps
8010570c:	e9 99 f8 ff ff       	jmp    80104faa <alltraps>

80105711 <vector92>:
.globl vector92
vector92:
  pushl $0
80105711:	6a 00                	push   $0x0
  pushl $92
80105713:	6a 5c                	push   $0x5c
  jmp alltraps
80105715:	e9 90 f8 ff ff       	jmp    80104faa <alltraps>

8010571a <vector93>:
.globl vector93
vector93:
  pushl $0
8010571a:	6a 00                	push   $0x0
  pushl $93
8010571c:	6a 5d                	push   $0x5d
  jmp alltraps
8010571e:	e9 87 f8 ff ff       	jmp    80104faa <alltraps>

80105723 <vector94>:
.globl vector94
vector94:
  pushl $0
80105723:	6a 00                	push   $0x0
  pushl $94
80105725:	6a 5e                	push   $0x5e
  jmp alltraps
80105727:	e9 7e f8 ff ff       	jmp    80104faa <alltraps>

8010572c <vector95>:
.globl vector95
vector95:
  pushl $0
8010572c:	6a 00                	push   $0x0
  pushl $95
8010572e:	6a 5f                	push   $0x5f
  jmp alltraps
80105730:	e9 75 f8 ff ff       	jmp    80104faa <alltraps>

80105735 <vector96>:
.globl vector96
vector96:
  pushl $0
80105735:	6a 00                	push   $0x0
  pushl $96
80105737:	6a 60                	push   $0x60
  jmp alltraps
80105739:	e9 6c f8 ff ff       	jmp    80104faa <alltraps>

8010573e <vector97>:
.globl vector97
vector97:
  pushl $0
8010573e:	6a 00                	push   $0x0
  pushl $97
80105740:	6a 61                	push   $0x61
  jmp alltraps
80105742:	e9 63 f8 ff ff       	jmp    80104faa <alltraps>

80105747 <vector98>:
.globl vector98
vector98:
  pushl $0
80105747:	6a 00                	push   $0x0
  pushl $98
80105749:	6a 62                	push   $0x62
  jmp alltraps
8010574b:	e9 5a f8 ff ff       	jmp    80104faa <alltraps>

80105750 <vector99>:
.globl vector99
vector99:
  pushl $0
80105750:	6a 00                	push   $0x0
  pushl $99
80105752:	6a 63                	push   $0x63
  jmp alltraps
80105754:	e9 51 f8 ff ff       	jmp    80104faa <alltraps>

80105759 <vector100>:
.globl vector100
vector100:
  pushl $0
80105759:	6a 00                	push   $0x0
  pushl $100
8010575b:	6a 64                	push   $0x64
  jmp alltraps
8010575d:	e9 48 f8 ff ff       	jmp    80104faa <alltraps>

80105762 <vector101>:
.globl vector101
vector101:
  pushl $0
80105762:	6a 00                	push   $0x0
  pushl $101
80105764:	6a 65                	push   $0x65
  jmp alltraps
80105766:	e9 3f f8 ff ff       	jmp    80104faa <alltraps>

8010576b <vector102>:
.globl vector102
vector102:
  pushl $0
8010576b:	6a 00                	push   $0x0
  pushl $102
8010576d:	6a 66                	push   $0x66
  jmp alltraps
8010576f:	e9 36 f8 ff ff       	jmp    80104faa <alltraps>

80105774 <vector103>:
.globl vector103
vector103:
  pushl $0
80105774:	6a 00                	push   $0x0
  pushl $103
80105776:	6a 67                	push   $0x67
  jmp alltraps
80105778:	e9 2d f8 ff ff       	jmp    80104faa <alltraps>

8010577d <vector104>:
.globl vector104
vector104:
  pushl $0
8010577d:	6a 00                	push   $0x0
  pushl $104
8010577f:	6a 68                	push   $0x68
  jmp alltraps
80105781:	e9 24 f8 ff ff       	jmp    80104faa <alltraps>

80105786 <vector105>:
.globl vector105
vector105:
  pushl $0
80105786:	6a 00                	push   $0x0
  pushl $105
80105788:	6a 69                	push   $0x69
  jmp alltraps
8010578a:	e9 1b f8 ff ff       	jmp    80104faa <alltraps>

8010578f <vector106>:
.globl vector106
vector106:
  pushl $0
8010578f:	6a 00                	push   $0x0
  pushl $106
80105791:	6a 6a                	push   $0x6a
  jmp alltraps
80105793:	e9 12 f8 ff ff       	jmp    80104faa <alltraps>

80105798 <vector107>:
.globl vector107
vector107:
  pushl $0
80105798:	6a 00                	push   $0x0
  pushl $107
8010579a:	6a 6b                	push   $0x6b
  jmp alltraps
8010579c:	e9 09 f8 ff ff       	jmp    80104faa <alltraps>

801057a1 <vector108>:
.globl vector108
vector108:
  pushl $0
801057a1:	6a 00                	push   $0x0
  pushl $108
801057a3:	6a 6c                	push   $0x6c
  jmp alltraps
801057a5:	e9 00 f8 ff ff       	jmp    80104faa <alltraps>

801057aa <vector109>:
.globl vector109
vector109:
  pushl $0
801057aa:	6a 00                	push   $0x0
  pushl $109
801057ac:	6a 6d                	push   $0x6d
  jmp alltraps
801057ae:	e9 f7 f7 ff ff       	jmp    80104faa <alltraps>

801057b3 <vector110>:
.globl vector110
vector110:
  pushl $0
801057b3:	6a 00                	push   $0x0
  pushl $110
801057b5:	6a 6e                	push   $0x6e
  jmp alltraps
801057b7:	e9 ee f7 ff ff       	jmp    80104faa <alltraps>

801057bc <vector111>:
.globl vector111
vector111:
  pushl $0
801057bc:	6a 00                	push   $0x0
  pushl $111
801057be:	6a 6f                	push   $0x6f
  jmp alltraps
801057c0:	e9 e5 f7 ff ff       	jmp    80104faa <alltraps>

801057c5 <vector112>:
.globl vector112
vector112:
  pushl $0
801057c5:	6a 00                	push   $0x0
  pushl $112
801057c7:	6a 70                	push   $0x70
  jmp alltraps
801057c9:	e9 dc f7 ff ff       	jmp    80104faa <alltraps>

801057ce <vector113>:
.globl vector113
vector113:
  pushl $0
801057ce:	6a 00                	push   $0x0
  pushl $113
801057d0:	6a 71                	push   $0x71
  jmp alltraps
801057d2:	e9 d3 f7 ff ff       	jmp    80104faa <alltraps>

801057d7 <vector114>:
.globl vector114
vector114:
  pushl $0
801057d7:	6a 00                	push   $0x0
  pushl $114
801057d9:	6a 72                	push   $0x72
  jmp alltraps
801057db:	e9 ca f7 ff ff       	jmp    80104faa <alltraps>

801057e0 <vector115>:
.globl vector115
vector115:
  pushl $0
801057e0:	6a 00                	push   $0x0
  pushl $115
801057e2:	6a 73                	push   $0x73
  jmp alltraps
801057e4:	e9 c1 f7 ff ff       	jmp    80104faa <alltraps>

801057e9 <vector116>:
.globl vector116
vector116:
  pushl $0
801057e9:	6a 00                	push   $0x0
  pushl $116
801057eb:	6a 74                	push   $0x74
  jmp alltraps
801057ed:	e9 b8 f7 ff ff       	jmp    80104faa <alltraps>

801057f2 <vector117>:
.globl vector117
vector117:
  pushl $0
801057f2:	6a 00                	push   $0x0
  pushl $117
801057f4:	6a 75                	push   $0x75
  jmp alltraps
801057f6:	e9 af f7 ff ff       	jmp    80104faa <alltraps>

801057fb <vector118>:
.globl vector118
vector118:
  pushl $0
801057fb:	6a 00                	push   $0x0
  pushl $118
801057fd:	6a 76                	push   $0x76
  jmp alltraps
801057ff:	e9 a6 f7 ff ff       	jmp    80104faa <alltraps>

80105804 <vector119>:
.globl vector119
vector119:
  pushl $0
80105804:	6a 00                	push   $0x0
  pushl $119
80105806:	6a 77                	push   $0x77
  jmp alltraps
80105808:	e9 9d f7 ff ff       	jmp    80104faa <alltraps>

8010580d <vector120>:
.globl vector120
vector120:
  pushl $0
8010580d:	6a 00                	push   $0x0
  pushl $120
8010580f:	6a 78                	push   $0x78
  jmp alltraps
80105811:	e9 94 f7 ff ff       	jmp    80104faa <alltraps>

80105816 <vector121>:
.globl vector121
vector121:
  pushl $0
80105816:	6a 00                	push   $0x0
  pushl $121
80105818:	6a 79                	push   $0x79
  jmp alltraps
8010581a:	e9 8b f7 ff ff       	jmp    80104faa <alltraps>

8010581f <vector122>:
.globl vector122
vector122:
  pushl $0
8010581f:	6a 00                	push   $0x0
  pushl $122
80105821:	6a 7a                	push   $0x7a
  jmp alltraps
80105823:	e9 82 f7 ff ff       	jmp    80104faa <alltraps>

80105828 <vector123>:
.globl vector123
vector123:
  pushl $0
80105828:	6a 00                	push   $0x0
  pushl $123
8010582a:	6a 7b                	push   $0x7b
  jmp alltraps
8010582c:	e9 79 f7 ff ff       	jmp    80104faa <alltraps>

80105831 <vector124>:
.globl vector124
vector124:
  pushl $0
80105831:	6a 00                	push   $0x0
  pushl $124
80105833:	6a 7c                	push   $0x7c
  jmp alltraps
80105835:	e9 70 f7 ff ff       	jmp    80104faa <alltraps>

8010583a <vector125>:
.globl vector125
vector125:
  pushl $0
8010583a:	6a 00                	push   $0x0
  pushl $125
8010583c:	6a 7d                	push   $0x7d
  jmp alltraps
8010583e:	e9 67 f7 ff ff       	jmp    80104faa <alltraps>

80105843 <vector126>:
.globl vector126
vector126:
  pushl $0
80105843:	6a 00                	push   $0x0
  pushl $126
80105845:	6a 7e                	push   $0x7e
  jmp alltraps
80105847:	e9 5e f7 ff ff       	jmp    80104faa <alltraps>

8010584c <vector127>:
.globl vector127
vector127:
  pushl $0
8010584c:	6a 00                	push   $0x0
  pushl $127
8010584e:	6a 7f                	push   $0x7f
  jmp alltraps
80105850:	e9 55 f7 ff ff       	jmp    80104faa <alltraps>

80105855 <vector128>:
.globl vector128
vector128:
  pushl $0
80105855:	6a 00                	push   $0x0
  pushl $128
80105857:	68 80 00 00 00       	push   $0x80
  jmp alltraps
8010585c:	e9 49 f7 ff ff       	jmp    80104faa <alltraps>

80105861 <vector129>:
.globl vector129
vector129:
  pushl $0
80105861:	6a 00                	push   $0x0
  pushl $129
80105863:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80105868:	e9 3d f7 ff ff       	jmp    80104faa <alltraps>

8010586d <vector130>:
.globl vector130
vector130:
  pushl $0
8010586d:	6a 00                	push   $0x0
  pushl $130
8010586f:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80105874:	e9 31 f7 ff ff       	jmp    80104faa <alltraps>

80105879 <vector131>:
.globl vector131
vector131:
  pushl $0
80105879:	6a 00                	push   $0x0
  pushl $131
8010587b:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80105880:	e9 25 f7 ff ff       	jmp    80104faa <alltraps>

80105885 <vector132>:
.globl vector132
vector132:
  pushl $0
80105885:	6a 00                	push   $0x0
  pushl $132
80105887:	68 84 00 00 00       	push   $0x84
  jmp alltraps
8010588c:	e9 19 f7 ff ff       	jmp    80104faa <alltraps>

80105891 <vector133>:
.globl vector133
vector133:
  pushl $0
80105891:	6a 00                	push   $0x0
  pushl $133
80105893:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80105898:	e9 0d f7 ff ff       	jmp    80104faa <alltraps>

8010589d <vector134>:
.globl vector134
vector134:
  pushl $0
8010589d:	6a 00                	push   $0x0
  pushl $134
8010589f:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801058a4:	e9 01 f7 ff ff       	jmp    80104faa <alltraps>

801058a9 <vector135>:
.globl vector135
vector135:
  pushl $0
801058a9:	6a 00                	push   $0x0
  pushl $135
801058ab:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801058b0:	e9 f5 f6 ff ff       	jmp    80104faa <alltraps>

801058b5 <vector136>:
.globl vector136
vector136:
  pushl $0
801058b5:	6a 00                	push   $0x0
  pushl $136
801058b7:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801058bc:	e9 e9 f6 ff ff       	jmp    80104faa <alltraps>

801058c1 <vector137>:
.globl vector137
vector137:
  pushl $0
801058c1:	6a 00                	push   $0x0
  pushl $137
801058c3:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801058c8:	e9 dd f6 ff ff       	jmp    80104faa <alltraps>

801058cd <vector138>:
.globl vector138
vector138:
  pushl $0
801058cd:	6a 00                	push   $0x0
  pushl $138
801058cf:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801058d4:	e9 d1 f6 ff ff       	jmp    80104faa <alltraps>

801058d9 <vector139>:
.globl vector139
vector139:
  pushl $0
801058d9:	6a 00                	push   $0x0
  pushl $139
801058db:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801058e0:	e9 c5 f6 ff ff       	jmp    80104faa <alltraps>

801058e5 <vector140>:
.globl vector140
vector140:
  pushl $0
801058e5:	6a 00                	push   $0x0
  pushl $140
801058e7:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801058ec:	e9 b9 f6 ff ff       	jmp    80104faa <alltraps>

801058f1 <vector141>:
.globl vector141
vector141:
  pushl $0
801058f1:	6a 00                	push   $0x0
  pushl $141
801058f3:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801058f8:	e9 ad f6 ff ff       	jmp    80104faa <alltraps>

801058fd <vector142>:
.globl vector142
vector142:
  pushl $0
801058fd:	6a 00                	push   $0x0
  pushl $142
801058ff:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80105904:	e9 a1 f6 ff ff       	jmp    80104faa <alltraps>

80105909 <vector143>:
.globl vector143
vector143:
  pushl $0
80105909:	6a 00                	push   $0x0
  pushl $143
8010590b:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80105910:	e9 95 f6 ff ff       	jmp    80104faa <alltraps>

80105915 <vector144>:
.globl vector144
vector144:
  pushl $0
80105915:	6a 00                	push   $0x0
  pushl $144
80105917:	68 90 00 00 00       	push   $0x90
  jmp alltraps
8010591c:	e9 89 f6 ff ff       	jmp    80104faa <alltraps>

80105921 <vector145>:
.globl vector145
vector145:
  pushl $0
80105921:	6a 00                	push   $0x0
  pushl $145
80105923:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80105928:	e9 7d f6 ff ff       	jmp    80104faa <alltraps>

8010592d <vector146>:
.globl vector146
vector146:
  pushl $0
8010592d:	6a 00                	push   $0x0
  pushl $146
8010592f:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80105934:	e9 71 f6 ff ff       	jmp    80104faa <alltraps>

80105939 <vector147>:
.globl vector147
vector147:
  pushl $0
80105939:	6a 00                	push   $0x0
  pushl $147
8010593b:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80105940:	e9 65 f6 ff ff       	jmp    80104faa <alltraps>

80105945 <vector148>:
.globl vector148
vector148:
  pushl $0
80105945:	6a 00                	push   $0x0
  pushl $148
80105947:	68 94 00 00 00       	push   $0x94
  jmp alltraps
8010594c:	e9 59 f6 ff ff       	jmp    80104faa <alltraps>

80105951 <vector149>:
.globl vector149
vector149:
  pushl $0
80105951:	6a 00                	push   $0x0
  pushl $149
80105953:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80105958:	e9 4d f6 ff ff       	jmp    80104faa <alltraps>

8010595d <vector150>:
.globl vector150
vector150:
  pushl $0
8010595d:	6a 00                	push   $0x0
  pushl $150
8010595f:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80105964:	e9 41 f6 ff ff       	jmp    80104faa <alltraps>

80105969 <vector151>:
.globl vector151
vector151:
  pushl $0
80105969:	6a 00                	push   $0x0
  pushl $151
8010596b:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80105970:	e9 35 f6 ff ff       	jmp    80104faa <alltraps>

80105975 <vector152>:
.globl vector152
vector152:
  pushl $0
80105975:	6a 00                	push   $0x0
  pushl $152
80105977:	68 98 00 00 00       	push   $0x98
  jmp alltraps
8010597c:	e9 29 f6 ff ff       	jmp    80104faa <alltraps>

80105981 <vector153>:
.globl vector153
vector153:
  pushl $0
80105981:	6a 00                	push   $0x0
  pushl $153
80105983:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80105988:	e9 1d f6 ff ff       	jmp    80104faa <alltraps>

8010598d <vector154>:
.globl vector154
vector154:
  pushl $0
8010598d:	6a 00                	push   $0x0
  pushl $154
8010598f:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80105994:	e9 11 f6 ff ff       	jmp    80104faa <alltraps>

80105999 <vector155>:
.globl vector155
vector155:
  pushl $0
80105999:	6a 00                	push   $0x0
  pushl $155
8010599b:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
801059a0:	e9 05 f6 ff ff       	jmp    80104faa <alltraps>

801059a5 <vector156>:
.globl vector156
vector156:
  pushl $0
801059a5:	6a 00                	push   $0x0
  pushl $156
801059a7:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
801059ac:	e9 f9 f5 ff ff       	jmp    80104faa <alltraps>

801059b1 <vector157>:
.globl vector157
vector157:
  pushl $0
801059b1:	6a 00                	push   $0x0
  pushl $157
801059b3:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
801059b8:	e9 ed f5 ff ff       	jmp    80104faa <alltraps>

801059bd <vector158>:
.globl vector158
vector158:
  pushl $0
801059bd:	6a 00                	push   $0x0
  pushl $158
801059bf:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801059c4:	e9 e1 f5 ff ff       	jmp    80104faa <alltraps>

801059c9 <vector159>:
.globl vector159
vector159:
  pushl $0
801059c9:	6a 00                	push   $0x0
  pushl $159
801059cb:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801059d0:	e9 d5 f5 ff ff       	jmp    80104faa <alltraps>

801059d5 <vector160>:
.globl vector160
vector160:
  pushl $0
801059d5:	6a 00                	push   $0x0
  pushl $160
801059d7:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801059dc:	e9 c9 f5 ff ff       	jmp    80104faa <alltraps>

801059e1 <vector161>:
.globl vector161
vector161:
  pushl $0
801059e1:	6a 00                	push   $0x0
  pushl $161
801059e3:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801059e8:	e9 bd f5 ff ff       	jmp    80104faa <alltraps>

801059ed <vector162>:
.globl vector162
vector162:
  pushl $0
801059ed:	6a 00                	push   $0x0
  pushl $162
801059ef:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801059f4:	e9 b1 f5 ff ff       	jmp    80104faa <alltraps>

801059f9 <vector163>:
.globl vector163
vector163:
  pushl $0
801059f9:	6a 00                	push   $0x0
  pushl $163
801059fb:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105a00:	e9 a5 f5 ff ff       	jmp    80104faa <alltraps>

80105a05 <vector164>:
.globl vector164
vector164:
  pushl $0
80105a05:	6a 00                	push   $0x0
  pushl $164
80105a07:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80105a0c:	e9 99 f5 ff ff       	jmp    80104faa <alltraps>

80105a11 <vector165>:
.globl vector165
vector165:
  pushl $0
80105a11:	6a 00                	push   $0x0
  pushl $165
80105a13:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80105a18:	e9 8d f5 ff ff       	jmp    80104faa <alltraps>

80105a1d <vector166>:
.globl vector166
vector166:
  pushl $0
80105a1d:	6a 00                	push   $0x0
  pushl $166
80105a1f:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105a24:	e9 81 f5 ff ff       	jmp    80104faa <alltraps>

80105a29 <vector167>:
.globl vector167
vector167:
  pushl $0
80105a29:	6a 00                	push   $0x0
  pushl $167
80105a2b:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105a30:	e9 75 f5 ff ff       	jmp    80104faa <alltraps>

80105a35 <vector168>:
.globl vector168
vector168:
  pushl $0
80105a35:	6a 00                	push   $0x0
  pushl $168
80105a37:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105a3c:	e9 69 f5 ff ff       	jmp    80104faa <alltraps>

80105a41 <vector169>:
.globl vector169
vector169:
  pushl $0
80105a41:	6a 00                	push   $0x0
  pushl $169
80105a43:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80105a48:	e9 5d f5 ff ff       	jmp    80104faa <alltraps>

80105a4d <vector170>:
.globl vector170
vector170:
  pushl $0
80105a4d:	6a 00                	push   $0x0
  pushl $170
80105a4f:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105a54:	e9 51 f5 ff ff       	jmp    80104faa <alltraps>

80105a59 <vector171>:
.globl vector171
vector171:
  pushl $0
80105a59:	6a 00                	push   $0x0
  pushl $171
80105a5b:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105a60:	e9 45 f5 ff ff       	jmp    80104faa <alltraps>

80105a65 <vector172>:
.globl vector172
vector172:
  pushl $0
80105a65:	6a 00                	push   $0x0
  pushl $172
80105a67:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105a6c:	e9 39 f5 ff ff       	jmp    80104faa <alltraps>

80105a71 <vector173>:
.globl vector173
vector173:
  pushl $0
80105a71:	6a 00                	push   $0x0
  pushl $173
80105a73:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80105a78:	e9 2d f5 ff ff       	jmp    80104faa <alltraps>

80105a7d <vector174>:
.globl vector174
vector174:
  pushl $0
80105a7d:	6a 00                	push   $0x0
  pushl $174
80105a7f:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105a84:	e9 21 f5 ff ff       	jmp    80104faa <alltraps>

80105a89 <vector175>:
.globl vector175
vector175:
  pushl $0
80105a89:	6a 00                	push   $0x0
  pushl $175
80105a8b:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105a90:	e9 15 f5 ff ff       	jmp    80104faa <alltraps>

80105a95 <vector176>:
.globl vector176
vector176:
  pushl $0
80105a95:	6a 00                	push   $0x0
  pushl $176
80105a97:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105a9c:	e9 09 f5 ff ff       	jmp    80104faa <alltraps>

80105aa1 <vector177>:
.globl vector177
vector177:
  pushl $0
80105aa1:	6a 00                	push   $0x0
  pushl $177
80105aa3:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105aa8:	e9 fd f4 ff ff       	jmp    80104faa <alltraps>

80105aad <vector178>:
.globl vector178
vector178:
  pushl $0
80105aad:	6a 00                	push   $0x0
  pushl $178
80105aaf:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105ab4:	e9 f1 f4 ff ff       	jmp    80104faa <alltraps>

80105ab9 <vector179>:
.globl vector179
vector179:
  pushl $0
80105ab9:	6a 00                	push   $0x0
  pushl $179
80105abb:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105ac0:	e9 e5 f4 ff ff       	jmp    80104faa <alltraps>

80105ac5 <vector180>:
.globl vector180
vector180:
  pushl $0
80105ac5:	6a 00                	push   $0x0
  pushl $180
80105ac7:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105acc:	e9 d9 f4 ff ff       	jmp    80104faa <alltraps>

80105ad1 <vector181>:
.globl vector181
vector181:
  pushl $0
80105ad1:	6a 00                	push   $0x0
  pushl $181
80105ad3:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105ad8:	e9 cd f4 ff ff       	jmp    80104faa <alltraps>

80105add <vector182>:
.globl vector182
vector182:
  pushl $0
80105add:	6a 00                	push   $0x0
  pushl $182
80105adf:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105ae4:	e9 c1 f4 ff ff       	jmp    80104faa <alltraps>

80105ae9 <vector183>:
.globl vector183
vector183:
  pushl $0
80105ae9:	6a 00                	push   $0x0
  pushl $183
80105aeb:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105af0:	e9 b5 f4 ff ff       	jmp    80104faa <alltraps>

80105af5 <vector184>:
.globl vector184
vector184:
  pushl $0
80105af5:	6a 00                	push   $0x0
  pushl $184
80105af7:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105afc:	e9 a9 f4 ff ff       	jmp    80104faa <alltraps>

80105b01 <vector185>:
.globl vector185
vector185:
  pushl $0
80105b01:	6a 00                	push   $0x0
  pushl $185
80105b03:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105b08:	e9 9d f4 ff ff       	jmp    80104faa <alltraps>

80105b0d <vector186>:
.globl vector186
vector186:
  pushl $0
80105b0d:	6a 00                	push   $0x0
  pushl $186
80105b0f:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105b14:	e9 91 f4 ff ff       	jmp    80104faa <alltraps>

80105b19 <vector187>:
.globl vector187
vector187:
  pushl $0
80105b19:	6a 00                	push   $0x0
  pushl $187
80105b1b:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105b20:	e9 85 f4 ff ff       	jmp    80104faa <alltraps>

80105b25 <vector188>:
.globl vector188
vector188:
  pushl $0
80105b25:	6a 00                	push   $0x0
  pushl $188
80105b27:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105b2c:	e9 79 f4 ff ff       	jmp    80104faa <alltraps>

80105b31 <vector189>:
.globl vector189
vector189:
  pushl $0
80105b31:	6a 00                	push   $0x0
  pushl $189
80105b33:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105b38:	e9 6d f4 ff ff       	jmp    80104faa <alltraps>

80105b3d <vector190>:
.globl vector190
vector190:
  pushl $0
80105b3d:	6a 00                	push   $0x0
  pushl $190
80105b3f:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105b44:	e9 61 f4 ff ff       	jmp    80104faa <alltraps>

80105b49 <vector191>:
.globl vector191
vector191:
  pushl $0
80105b49:	6a 00                	push   $0x0
  pushl $191
80105b4b:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105b50:	e9 55 f4 ff ff       	jmp    80104faa <alltraps>

80105b55 <vector192>:
.globl vector192
vector192:
  pushl $0
80105b55:	6a 00                	push   $0x0
  pushl $192
80105b57:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105b5c:	e9 49 f4 ff ff       	jmp    80104faa <alltraps>

80105b61 <vector193>:
.globl vector193
vector193:
  pushl $0
80105b61:	6a 00                	push   $0x0
  pushl $193
80105b63:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105b68:	e9 3d f4 ff ff       	jmp    80104faa <alltraps>

80105b6d <vector194>:
.globl vector194
vector194:
  pushl $0
80105b6d:	6a 00                	push   $0x0
  pushl $194
80105b6f:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105b74:	e9 31 f4 ff ff       	jmp    80104faa <alltraps>

80105b79 <vector195>:
.globl vector195
vector195:
  pushl $0
80105b79:	6a 00                	push   $0x0
  pushl $195
80105b7b:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105b80:	e9 25 f4 ff ff       	jmp    80104faa <alltraps>

80105b85 <vector196>:
.globl vector196
vector196:
  pushl $0
80105b85:	6a 00                	push   $0x0
  pushl $196
80105b87:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105b8c:	e9 19 f4 ff ff       	jmp    80104faa <alltraps>

80105b91 <vector197>:
.globl vector197
vector197:
  pushl $0
80105b91:	6a 00                	push   $0x0
  pushl $197
80105b93:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105b98:	e9 0d f4 ff ff       	jmp    80104faa <alltraps>

80105b9d <vector198>:
.globl vector198
vector198:
  pushl $0
80105b9d:	6a 00                	push   $0x0
  pushl $198
80105b9f:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105ba4:	e9 01 f4 ff ff       	jmp    80104faa <alltraps>

80105ba9 <vector199>:
.globl vector199
vector199:
  pushl $0
80105ba9:	6a 00                	push   $0x0
  pushl $199
80105bab:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105bb0:	e9 f5 f3 ff ff       	jmp    80104faa <alltraps>

80105bb5 <vector200>:
.globl vector200
vector200:
  pushl $0
80105bb5:	6a 00                	push   $0x0
  pushl $200
80105bb7:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105bbc:	e9 e9 f3 ff ff       	jmp    80104faa <alltraps>

80105bc1 <vector201>:
.globl vector201
vector201:
  pushl $0
80105bc1:	6a 00                	push   $0x0
  pushl $201
80105bc3:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105bc8:	e9 dd f3 ff ff       	jmp    80104faa <alltraps>

80105bcd <vector202>:
.globl vector202
vector202:
  pushl $0
80105bcd:	6a 00                	push   $0x0
  pushl $202
80105bcf:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105bd4:	e9 d1 f3 ff ff       	jmp    80104faa <alltraps>

80105bd9 <vector203>:
.globl vector203
vector203:
  pushl $0
80105bd9:	6a 00                	push   $0x0
  pushl $203
80105bdb:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105be0:	e9 c5 f3 ff ff       	jmp    80104faa <alltraps>

80105be5 <vector204>:
.globl vector204
vector204:
  pushl $0
80105be5:	6a 00                	push   $0x0
  pushl $204
80105be7:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105bec:	e9 b9 f3 ff ff       	jmp    80104faa <alltraps>

80105bf1 <vector205>:
.globl vector205
vector205:
  pushl $0
80105bf1:	6a 00                	push   $0x0
  pushl $205
80105bf3:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105bf8:	e9 ad f3 ff ff       	jmp    80104faa <alltraps>

80105bfd <vector206>:
.globl vector206
vector206:
  pushl $0
80105bfd:	6a 00                	push   $0x0
  pushl $206
80105bff:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105c04:	e9 a1 f3 ff ff       	jmp    80104faa <alltraps>

80105c09 <vector207>:
.globl vector207
vector207:
  pushl $0
80105c09:	6a 00                	push   $0x0
  pushl $207
80105c0b:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105c10:	e9 95 f3 ff ff       	jmp    80104faa <alltraps>

80105c15 <vector208>:
.globl vector208
vector208:
  pushl $0
80105c15:	6a 00                	push   $0x0
  pushl $208
80105c17:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105c1c:	e9 89 f3 ff ff       	jmp    80104faa <alltraps>

80105c21 <vector209>:
.globl vector209
vector209:
  pushl $0
80105c21:	6a 00                	push   $0x0
  pushl $209
80105c23:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105c28:	e9 7d f3 ff ff       	jmp    80104faa <alltraps>

80105c2d <vector210>:
.globl vector210
vector210:
  pushl $0
80105c2d:	6a 00                	push   $0x0
  pushl $210
80105c2f:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105c34:	e9 71 f3 ff ff       	jmp    80104faa <alltraps>

80105c39 <vector211>:
.globl vector211
vector211:
  pushl $0
80105c39:	6a 00                	push   $0x0
  pushl $211
80105c3b:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105c40:	e9 65 f3 ff ff       	jmp    80104faa <alltraps>

80105c45 <vector212>:
.globl vector212
vector212:
  pushl $0
80105c45:	6a 00                	push   $0x0
  pushl $212
80105c47:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105c4c:	e9 59 f3 ff ff       	jmp    80104faa <alltraps>

80105c51 <vector213>:
.globl vector213
vector213:
  pushl $0
80105c51:	6a 00                	push   $0x0
  pushl $213
80105c53:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105c58:	e9 4d f3 ff ff       	jmp    80104faa <alltraps>

80105c5d <vector214>:
.globl vector214
vector214:
  pushl $0
80105c5d:	6a 00                	push   $0x0
  pushl $214
80105c5f:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105c64:	e9 41 f3 ff ff       	jmp    80104faa <alltraps>

80105c69 <vector215>:
.globl vector215
vector215:
  pushl $0
80105c69:	6a 00                	push   $0x0
  pushl $215
80105c6b:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105c70:	e9 35 f3 ff ff       	jmp    80104faa <alltraps>

80105c75 <vector216>:
.globl vector216
vector216:
  pushl $0
80105c75:	6a 00                	push   $0x0
  pushl $216
80105c77:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105c7c:	e9 29 f3 ff ff       	jmp    80104faa <alltraps>

80105c81 <vector217>:
.globl vector217
vector217:
  pushl $0
80105c81:	6a 00                	push   $0x0
  pushl $217
80105c83:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105c88:	e9 1d f3 ff ff       	jmp    80104faa <alltraps>

80105c8d <vector218>:
.globl vector218
vector218:
  pushl $0
80105c8d:	6a 00                	push   $0x0
  pushl $218
80105c8f:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105c94:	e9 11 f3 ff ff       	jmp    80104faa <alltraps>

80105c99 <vector219>:
.globl vector219
vector219:
  pushl $0
80105c99:	6a 00                	push   $0x0
  pushl $219
80105c9b:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105ca0:	e9 05 f3 ff ff       	jmp    80104faa <alltraps>

80105ca5 <vector220>:
.globl vector220
vector220:
  pushl $0
80105ca5:	6a 00                	push   $0x0
  pushl $220
80105ca7:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105cac:	e9 f9 f2 ff ff       	jmp    80104faa <alltraps>

80105cb1 <vector221>:
.globl vector221
vector221:
  pushl $0
80105cb1:	6a 00                	push   $0x0
  pushl $221
80105cb3:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105cb8:	e9 ed f2 ff ff       	jmp    80104faa <alltraps>

80105cbd <vector222>:
.globl vector222
vector222:
  pushl $0
80105cbd:	6a 00                	push   $0x0
  pushl $222
80105cbf:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105cc4:	e9 e1 f2 ff ff       	jmp    80104faa <alltraps>

80105cc9 <vector223>:
.globl vector223
vector223:
  pushl $0
80105cc9:	6a 00                	push   $0x0
  pushl $223
80105ccb:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105cd0:	e9 d5 f2 ff ff       	jmp    80104faa <alltraps>

80105cd5 <vector224>:
.globl vector224
vector224:
  pushl $0
80105cd5:	6a 00                	push   $0x0
  pushl $224
80105cd7:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105cdc:	e9 c9 f2 ff ff       	jmp    80104faa <alltraps>

80105ce1 <vector225>:
.globl vector225
vector225:
  pushl $0
80105ce1:	6a 00                	push   $0x0
  pushl $225
80105ce3:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105ce8:	e9 bd f2 ff ff       	jmp    80104faa <alltraps>

80105ced <vector226>:
.globl vector226
vector226:
  pushl $0
80105ced:	6a 00                	push   $0x0
  pushl $226
80105cef:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105cf4:	e9 b1 f2 ff ff       	jmp    80104faa <alltraps>

80105cf9 <vector227>:
.globl vector227
vector227:
  pushl $0
80105cf9:	6a 00                	push   $0x0
  pushl $227
80105cfb:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105d00:	e9 a5 f2 ff ff       	jmp    80104faa <alltraps>

80105d05 <vector228>:
.globl vector228
vector228:
  pushl $0
80105d05:	6a 00                	push   $0x0
  pushl $228
80105d07:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105d0c:	e9 99 f2 ff ff       	jmp    80104faa <alltraps>

80105d11 <vector229>:
.globl vector229
vector229:
  pushl $0
80105d11:	6a 00                	push   $0x0
  pushl $229
80105d13:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105d18:	e9 8d f2 ff ff       	jmp    80104faa <alltraps>

80105d1d <vector230>:
.globl vector230
vector230:
  pushl $0
80105d1d:	6a 00                	push   $0x0
  pushl $230
80105d1f:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105d24:	e9 81 f2 ff ff       	jmp    80104faa <alltraps>

80105d29 <vector231>:
.globl vector231
vector231:
  pushl $0
80105d29:	6a 00                	push   $0x0
  pushl $231
80105d2b:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105d30:	e9 75 f2 ff ff       	jmp    80104faa <alltraps>

80105d35 <vector232>:
.globl vector232
vector232:
  pushl $0
80105d35:	6a 00                	push   $0x0
  pushl $232
80105d37:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105d3c:	e9 69 f2 ff ff       	jmp    80104faa <alltraps>

80105d41 <vector233>:
.globl vector233
vector233:
  pushl $0
80105d41:	6a 00                	push   $0x0
  pushl $233
80105d43:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105d48:	e9 5d f2 ff ff       	jmp    80104faa <alltraps>

80105d4d <vector234>:
.globl vector234
vector234:
  pushl $0
80105d4d:	6a 00                	push   $0x0
  pushl $234
80105d4f:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105d54:	e9 51 f2 ff ff       	jmp    80104faa <alltraps>

80105d59 <vector235>:
.globl vector235
vector235:
  pushl $0
80105d59:	6a 00                	push   $0x0
  pushl $235
80105d5b:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105d60:	e9 45 f2 ff ff       	jmp    80104faa <alltraps>

80105d65 <vector236>:
.globl vector236
vector236:
  pushl $0
80105d65:	6a 00                	push   $0x0
  pushl $236
80105d67:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105d6c:	e9 39 f2 ff ff       	jmp    80104faa <alltraps>

80105d71 <vector237>:
.globl vector237
vector237:
  pushl $0
80105d71:	6a 00                	push   $0x0
  pushl $237
80105d73:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105d78:	e9 2d f2 ff ff       	jmp    80104faa <alltraps>

80105d7d <vector238>:
.globl vector238
vector238:
  pushl $0
80105d7d:	6a 00                	push   $0x0
  pushl $238
80105d7f:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105d84:	e9 21 f2 ff ff       	jmp    80104faa <alltraps>

80105d89 <vector239>:
.globl vector239
vector239:
  pushl $0
80105d89:	6a 00                	push   $0x0
  pushl $239
80105d8b:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105d90:	e9 15 f2 ff ff       	jmp    80104faa <alltraps>

80105d95 <vector240>:
.globl vector240
vector240:
  pushl $0
80105d95:	6a 00                	push   $0x0
  pushl $240
80105d97:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105d9c:	e9 09 f2 ff ff       	jmp    80104faa <alltraps>

80105da1 <vector241>:
.globl vector241
vector241:
  pushl $0
80105da1:	6a 00                	push   $0x0
  pushl $241
80105da3:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105da8:	e9 fd f1 ff ff       	jmp    80104faa <alltraps>

80105dad <vector242>:
.globl vector242
vector242:
  pushl $0
80105dad:	6a 00                	push   $0x0
  pushl $242
80105daf:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105db4:	e9 f1 f1 ff ff       	jmp    80104faa <alltraps>

80105db9 <vector243>:
.globl vector243
vector243:
  pushl $0
80105db9:	6a 00                	push   $0x0
  pushl $243
80105dbb:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105dc0:	e9 e5 f1 ff ff       	jmp    80104faa <alltraps>

80105dc5 <vector244>:
.globl vector244
vector244:
  pushl $0
80105dc5:	6a 00                	push   $0x0
  pushl $244
80105dc7:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105dcc:	e9 d9 f1 ff ff       	jmp    80104faa <alltraps>

80105dd1 <vector245>:
.globl vector245
vector245:
  pushl $0
80105dd1:	6a 00                	push   $0x0
  pushl $245
80105dd3:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105dd8:	e9 cd f1 ff ff       	jmp    80104faa <alltraps>

80105ddd <vector246>:
.globl vector246
vector246:
  pushl $0
80105ddd:	6a 00                	push   $0x0
  pushl $246
80105ddf:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105de4:	e9 c1 f1 ff ff       	jmp    80104faa <alltraps>

80105de9 <vector247>:
.globl vector247
vector247:
  pushl $0
80105de9:	6a 00                	push   $0x0
  pushl $247
80105deb:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105df0:	e9 b5 f1 ff ff       	jmp    80104faa <alltraps>

80105df5 <vector248>:
.globl vector248
vector248:
  pushl $0
80105df5:	6a 00                	push   $0x0
  pushl $248
80105df7:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105dfc:	e9 a9 f1 ff ff       	jmp    80104faa <alltraps>

80105e01 <vector249>:
.globl vector249
vector249:
  pushl $0
80105e01:	6a 00                	push   $0x0
  pushl $249
80105e03:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105e08:	e9 9d f1 ff ff       	jmp    80104faa <alltraps>

80105e0d <vector250>:
.globl vector250
vector250:
  pushl $0
80105e0d:	6a 00                	push   $0x0
  pushl $250
80105e0f:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105e14:	e9 91 f1 ff ff       	jmp    80104faa <alltraps>

80105e19 <vector251>:
.globl vector251
vector251:
  pushl $0
80105e19:	6a 00                	push   $0x0
  pushl $251
80105e1b:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105e20:	e9 85 f1 ff ff       	jmp    80104faa <alltraps>

80105e25 <vector252>:
.globl vector252
vector252:
  pushl $0
80105e25:	6a 00                	push   $0x0
  pushl $252
80105e27:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105e2c:	e9 79 f1 ff ff       	jmp    80104faa <alltraps>

80105e31 <vector253>:
.globl vector253
vector253:
  pushl $0
80105e31:	6a 00                	push   $0x0
  pushl $253
80105e33:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105e38:	e9 6d f1 ff ff       	jmp    80104faa <alltraps>

80105e3d <vector254>:
.globl vector254
vector254:
  pushl $0
80105e3d:	6a 00                	push   $0x0
  pushl $254
80105e3f:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105e44:	e9 61 f1 ff ff       	jmp    80104faa <alltraps>

80105e49 <vector255>:
.globl vector255
vector255:
  pushl $0
80105e49:	6a 00                	push   $0x0
  pushl $255
80105e4b:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105e50:	e9 55 f1 ff ff       	jmp    80104faa <alltraps>

80105e55 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105e55:	55                   	push   %ebp
80105e56:	89 e5                	mov    %esp,%ebp
80105e58:	57                   	push   %edi
80105e59:	56                   	push   %esi
80105e5a:	53                   	push   %ebx
80105e5b:	83 ec 0c             	sub    $0xc,%esp
80105e5e:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105e60:	c1 ea 16             	shr    $0x16,%edx
80105e63:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105e66:	8b 1f                	mov    (%edi),%ebx
80105e68:	f6 c3 01             	test   $0x1,%bl
80105e6b:	74 22                	je     80105e8f <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105e6d:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105e73:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105e79:	c1 ee 0c             	shr    $0xc,%esi
80105e7c:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105e82:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105e85:	89 d8                	mov    %ebx,%eax
80105e87:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105e8a:	5b                   	pop    %ebx
80105e8b:	5e                   	pop    %esi
80105e8c:	5f                   	pop    %edi
80105e8d:	5d                   	pop    %ebp
80105e8e:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc2(-2)) == 0)
80105e8f:	85 c9                	test   %ecx,%ecx
80105e91:	74 33                	je     80105ec6 <walkpgdir+0x71>
80105e93:	83 ec 0c             	sub    $0xc,%esp
80105e96:	6a fe                	push   $0xfffffffe
80105e98:	e8 c5 c2 ff ff       	call   80102162 <kalloc2>
80105e9d:	89 c3                	mov    %eax,%ebx
80105e9f:	83 c4 10             	add    $0x10,%esp
80105ea2:	85 c0                	test   %eax,%eax
80105ea4:	74 df                	je     80105e85 <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105ea6:	83 ec 04             	sub    $0x4,%esp
80105ea9:	68 00 10 00 00       	push   $0x1000
80105eae:	6a 00                	push   $0x0
80105eb0:	50                   	push   %eax
80105eb1:	e8 f6 df ff ff       	call   80103eac <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105eb6:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105ebc:	83 c8 07             	or     $0x7,%eax
80105ebf:	89 07                	mov    %eax,(%edi)
80105ec1:	83 c4 10             	add    $0x10,%esp
80105ec4:	eb b3                	jmp    80105e79 <walkpgdir+0x24>
      return 0;
80105ec6:	bb 00 00 00 00       	mov    $0x0,%ebx
80105ecb:	eb b8                	jmp    80105e85 <walkpgdir+0x30>

80105ecd <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105ecd:	55                   	push   %ebp
80105ece:	89 e5                	mov    %esp,%ebp
80105ed0:	57                   	push   %edi
80105ed1:	56                   	push   %esi
80105ed2:	53                   	push   %ebx
80105ed3:	83 ec 1c             	sub    $0x1c,%esp
80105ed6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105ed9:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105edc:	89 d3                	mov    %edx,%ebx
80105ede:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105ee4:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105ee8:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105eee:	b9 01 00 00 00       	mov    $0x1,%ecx
80105ef3:	89 da                	mov    %ebx,%edx
80105ef5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105ef8:	e8 58 ff ff ff       	call   80105e55 <walkpgdir>
80105efd:	85 c0                	test   %eax,%eax
80105eff:	74 2e                	je     80105f2f <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105f01:	f6 00 01             	testb  $0x1,(%eax)
80105f04:	75 1c                	jne    80105f22 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105f06:	89 f2                	mov    %esi,%edx
80105f08:	0b 55 0c             	or     0xc(%ebp),%edx
80105f0b:	83 ca 01             	or     $0x1,%edx
80105f0e:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105f10:	39 fb                	cmp    %edi,%ebx
80105f12:	74 28                	je     80105f3c <mappages+0x6f>
      break;
    a += PGSIZE;
80105f14:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105f1a:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105f20:	eb cc                	jmp    80105eee <mappages+0x21>
      panic("remap");
80105f22:	83 ec 0c             	sub    $0xc,%esp
80105f25:	68 0c 70 10 80       	push   $0x8010700c
80105f2a:	e8 19 a4 ff ff       	call   80100348 <panic>
      return -1;
80105f2f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105f34:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105f37:	5b                   	pop    %ebx
80105f38:	5e                   	pop    %esi
80105f39:	5f                   	pop    %edi
80105f3a:	5d                   	pop    %ebp
80105f3b:	c3                   	ret    
  return 0;
80105f3c:	b8 00 00 00 00       	mov    $0x0,%eax
80105f41:	eb f1                	jmp    80105f34 <mappages+0x67>

80105f43 <seginit>:
{
80105f43:	55                   	push   %ebp
80105f44:	89 e5                	mov    %esp,%ebp
80105f46:	53                   	push   %ebx
80105f47:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105f4a:	e8 f4 d4 ff ff       	call   80103443 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105f4f:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105f55:	66 c7 80 78 28 13 80 	movw   $0xffff,-0x7fecd788(%eax)
80105f5c:	ff ff 
80105f5e:	66 c7 80 7a 28 13 80 	movw   $0x0,-0x7fecd786(%eax)
80105f65:	00 00 
80105f67:	c6 80 7c 28 13 80 00 	movb   $0x0,-0x7fecd784(%eax)
80105f6e:	0f b6 88 7d 28 13 80 	movzbl -0x7fecd783(%eax),%ecx
80105f75:	83 e1 f0             	and    $0xfffffff0,%ecx
80105f78:	83 c9 1a             	or     $0x1a,%ecx
80105f7b:	83 e1 9f             	and    $0xffffff9f,%ecx
80105f7e:	83 c9 80             	or     $0xffffff80,%ecx
80105f81:	88 88 7d 28 13 80    	mov    %cl,-0x7fecd783(%eax)
80105f87:	0f b6 88 7e 28 13 80 	movzbl -0x7fecd782(%eax),%ecx
80105f8e:	83 c9 0f             	or     $0xf,%ecx
80105f91:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f94:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f97:	88 88 7e 28 13 80    	mov    %cl,-0x7fecd782(%eax)
80105f9d:	c6 80 7f 28 13 80 00 	movb   $0x0,-0x7fecd781(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105fa4:	66 c7 80 80 28 13 80 	movw   $0xffff,-0x7fecd780(%eax)
80105fab:	ff ff 
80105fad:	66 c7 80 82 28 13 80 	movw   $0x0,-0x7fecd77e(%eax)
80105fb4:	00 00 
80105fb6:	c6 80 84 28 13 80 00 	movb   $0x0,-0x7fecd77c(%eax)
80105fbd:	0f b6 88 85 28 13 80 	movzbl -0x7fecd77b(%eax),%ecx
80105fc4:	83 e1 f0             	and    $0xfffffff0,%ecx
80105fc7:	83 c9 12             	or     $0x12,%ecx
80105fca:	83 e1 9f             	and    $0xffffff9f,%ecx
80105fcd:	83 c9 80             	or     $0xffffff80,%ecx
80105fd0:	88 88 85 28 13 80    	mov    %cl,-0x7fecd77b(%eax)
80105fd6:	0f b6 88 86 28 13 80 	movzbl -0x7fecd77a(%eax),%ecx
80105fdd:	83 c9 0f             	or     $0xf,%ecx
80105fe0:	83 e1 cf             	and    $0xffffffcf,%ecx
80105fe3:	83 c9 c0             	or     $0xffffffc0,%ecx
80105fe6:	88 88 86 28 13 80    	mov    %cl,-0x7fecd77a(%eax)
80105fec:	c6 80 87 28 13 80 00 	movb   $0x0,-0x7fecd779(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80105ff3:	66 c7 80 88 28 13 80 	movw   $0xffff,-0x7fecd778(%eax)
80105ffa:	ff ff 
80105ffc:	66 c7 80 8a 28 13 80 	movw   $0x0,-0x7fecd776(%eax)
80106003:	00 00 
80106005:	c6 80 8c 28 13 80 00 	movb   $0x0,-0x7fecd774(%eax)
8010600c:	c6 80 8d 28 13 80 fa 	movb   $0xfa,-0x7fecd773(%eax)
80106013:	0f b6 88 8e 28 13 80 	movzbl -0x7fecd772(%eax),%ecx
8010601a:	83 c9 0f             	or     $0xf,%ecx
8010601d:	83 e1 cf             	and    $0xffffffcf,%ecx
80106020:	83 c9 c0             	or     $0xffffffc0,%ecx
80106023:	88 88 8e 28 13 80    	mov    %cl,-0x7fecd772(%eax)
80106029:	c6 80 8f 28 13 80 00 	movb   $0x0,-0x7fecd771(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80106030:	66 c7 80 90 28 13 80 	movw   $0xffff,-0x7fecd770(%eax)
80106037:	ff ff 
80106039:	66 c7 80 92 28 13 80 	movw   $0x0,-0x7fecd76e(%eax)
80106040:	00 00 
80106042:	c6 80 94 28 13 80 00 	movb   $0x0,-0x7fecd76c(%eax)
80106049:	c6 80 95 28 13 80 f2 	movb   $0xf2,-0x7fecd76b(%eax)
80106050:	0f b6 88 96 28 13 80 	movzbl -0x7fecd76a(%eax),%ecx
80106057:	83 c9 0f             	or     $0xf,%ecx
8010605a:	83 e1 cf             	and    $0xffffffcf,%ecx
8010605d:	83 c9 c0             	or     $0xffffffc0,%ecx
80106060:	88 88 96 28 13 80    	mov    %cl,-0x7fecd76a(%eax)
80106066:	c6 80 97 28 13 80 00 	movb   $0x0,-0x7fecd769(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
8010606d:	05 70 28 13 80       	add    $0x80132870,%eax
  pd[0] = size-1;
80106072:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80106078:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
8010607c:	c1 e8 10             	shr    $0x10,%eax
8010607f:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80106083:	8d 45 f2             	lea    -0xe(%ebp),%eax
80106086:	0f 01 10             	lgdtl  (%eax)
}
80106089:	83 c4 14             	add    $0x14,%esp
8010608c:	5b                   	pop    %ebx
8010608d:	5d                   	pop    %ebp
8010608e:	c3                   	ret    

8010608f <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
8010608f:	55                   	push   %ebp
80106090:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80106092:	a1 24 55 13 80       	mov    0x80135524,%eax
80106097:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010609c:	0f 22 d8             	mov    %eax,%cr3
}
8010609f:	5d                   	pop    %ebp
801060a0:	c3                   	ret    

801060a1 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
801060a1:	55                   	push   %ebp
801060a2:	89 e5                	mov    %esp,%ebp
801060a4:	57                   	push   %edi
801060a5:	56                   	push   %esi
801060a6:	53                   	push   %ebx
801060a7:	83 ec 1c             	sub    $0x1c,%esp
801060aa:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
801060ad:	85 f6                	test   %esi,%esi
801060af:	0f 84 dd 00 00 00    	je     80106192 <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
801060b5:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
801060b9:	0f 84 e0 00 00 00    	je     8010619f <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
801060bf:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
801060c3:	0f 84 e3 00 00 00    	je     801061ac <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
801060c9:	e8 55 dc ff ff       	call   80103d23 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
801060ce:	e8 14 d3 ff ff       	call   801033e7 <mycpu>
801060d3:	89 c3                	mov    %eax,%ebx
801060d5:	e8 0d d3 ff ff       	call   801033e7 <mycpu>
801060da:	8d 78 08             	lea    0x8(%eax),%edi
801060dd:	e8 05 d3 ff ff       	call   801033e7 <mycpu>
801060e2:	83 c0 08             	add    $0x8,%eax
801060e5:	c1 e8 10             	shr    $0x10,%eax
801060e8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801060eb:	e8 f7 d2 ff ff       	call   801033e7 <mycpu>
801060f0:	83 c0 08             	add    $0x8,%eax
801060f3:	c1 e8 18             	shr    $0x18,%eax
801060f6:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
801060fd:	67 00 
801060ff:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80106106:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
8010610a:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80106110:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80106117:	83 e2 f0             	and    $0xfffffff0,%edx
8010611a:	83 ca 19             	or     $0x19,%edx
8010611d:	83 e2 9f             	and    $0xffffff9f,%edx
80106120:	83 ca 80             	or     $0xffffff80,%edx
80106123:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80106129:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
80106130:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80106136:	e8 ac d2 ff ff       	call   801033e7 <mycpu>
8010613b:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80106142:	83 e2 ef             	and    $0xffffffef,%edx
80106145:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
8010614b:	e8 97 d2 ff ff       	call   801033e7 <mycpu>
80106150:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80106156:	8b 5e 08             	mov    0x8(%esi),%ebx
80106159:	e8 89 d2 ff ff       	call   801033e7 <mycpu>
8010615e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106164:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
80106167:	e8 7b d2 ff ff       	call   801033e7 <mycpu>
8010616c:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
80106172:	b8 28 00 00 00       	mov    $0x28,%eax
80106177:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
8010617a:	8b 46 04             	mov    0x4(%esi),%eax
8010617d:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
80106182:	0f 22 d8             	mov    %eax,%cr3
  popcli();
80106185:	e8 d6 db ff ff       	call   80103d60 <popcli>
}
8010618a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010618d:	5b                   	pop    %ebx
8010618e:	5e                   	pop    %esi
8010618f:	5f                   	pop    %edi
80106190:	5d                   	pop    %ebp
80106191:	c3                   	ret    
    panic("switchuvm: no process");
80106192:	83 ec 0c             	sub    $0xc,%esp
80106195:	68 12 70 10 80       	push   $0x80107012
8010619a:	e8 a9 a1 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
8010619f:	83 ec 0c             	sub    $0xc,%esp
801061a2:	68 28 70 10 80       	push   $0x80107028
801061a7:	e8 9c a1 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
801061ac:	83 ec 0c             	sub    $0xc,%esp
801061af:	68 3d 70 10 80       	push   $0x8010703d
801061b4:	e8 8f a1 ff ff       	call   80100348 <panic>

801061b9 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801061b9:	55                   	push   %ebp
801061ba:	89 e5                	mov    %esp,%ebp
801061bc:	56                   	push   %esi
801061bd:	53                   	push   %ebx
801061be:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
801061c1:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801061c7:	77 51                	ja     8010621a <inituvm+0x61>
    panic("inituvm: more than a page");
  mem = kalloc2(-2);
801061c9:	83 ec 0c             	sub    $0xc,%esp
801061cc:	6a fe                	push   $0xfffffffe
801061ce:	e8 8f bf ff ff       	call   80102162 <kalloc2>
801061d3:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
801061d5:	83 c4 0c             	add    $0xc,%esp
801061d8:	68 00 10 00 00       	push   $0x1000
801061dd:	6a 00                	push   $0x0
801061df:	50                   	push   %eax
801061e0:	e8 c7 dc ff ff       	call   80103eac <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
801061e5:	83 c4 08             	add    $0x8,%esp
801061e8:	6a 06                	push   $0x6
801061ea:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801061f0:	50                   	push   %eax
801061f1:	b9 00 10 00 00       	mov    $0x1000,%ecx
801061f6:	ba 00 00 00 00       	mov    $0x0,%edx
801061fb:	8b 45 08             	mov    0x8(%ebp),%eax
801061fe:	e8 ca fc ff ff       	call   80105ecd <mappages>
  memmove(mem, init, sz);
80106203:	83 c4 0c             	add    $0xc,%esp
80106206:	56                   	push   %esi
80106207:	ff 75 0c             	pushl  0xc(%ebp)
8010620a:	53                   	push   %ebx
8010620b:	e8 17 dd ff ff       	call   80103f27 <memmove>
}
80106210:	83 c4 10             	add    $0x10,%esp
80106213:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106216:	5b                   	pop    %ebx
80106217:	5e                   	pop    %esi
80106218:	5d                   	pop    %ebp
80106219:	c3                   	ret    
    panic("inituvm: more than a page");
8010621a:	83 ec 0c             	sub    $0xc,%esp
8010621d:	68 51 70 10 80       	push   $0x80107051
80106222:	e8 21 a1 ff ff       	call   80100348 <panic>

80106227 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80106227:	55                   	push   %ebp
80106228:	89 e5                	mov    %esp,%ebp
8010622a:	57                   	push   %edi
8010622b:	56                   	push   %esi
8010622c:	53                   	push   %ebx
8010622d:	83 ec 0c             	sub    $0xc,%esp
80106230:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80106233:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
8010623a:	75 07                	jne    80106243 <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
8010623c:	bb 00 00 00 00       	mov    $0x0,%ebx
80106241:	eb 3c                	jmp    8010627f <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
80106243:	83 ec 0c             	sub    $0xc,%esp
80106246:	68 0c 71 10 80       	push   $0x8010710c
8010624b:	e8 f8 a0 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
80106250:	83 ec 0c             	sub    $0xc,%esp
80106253:	68 6b 70 10 80       	push   $0x8010706b
80106258:	e8 eb a0 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
8010625d:	05 00 00 00 80       	add    $0x80000000,%eax
80106262:	56                   	push   %esi
80106263:	89 da                	mov    %ebx,%edx
80106265:	03 55 14             	add    0x14(%ebp),%edx
80106268:	52                   	push   %edx
80106269:	50                   	push   %eax
8010626a:	ff 75 10             	pushl  0x10(%ebp)
8010626d:	e8 01 b5 ff ff       	call   80101773 <readi>
80106272:	83 c4 10             	add    $0x10,%esp
80106275:	39 f0                	cmp    %esi,%eax
80106277:	75 47                	jne    801062c0 <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
80106279:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010627f:	39 fb                	cmp    %edi,%ebx
80106281:	73 30                	jae    801062b3 <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80106283:	89 da                	mov    %ebx,%edx
80106285:	03 55 0c             	add    0xc(%ebp),%edx
80106288:	b9 00 00 00 00       	mov    $0x0,%ecx
8010628d:	8b 45 08             	mov    0x8(%ebp),%eax
80106290:	e8 c0 fb ff ff       	call   80105e55 <walkpgdir>
80106295:	85 c0                	test   %eax,%eax
80106297:	74 b7                	je     80106250 <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
80106299:	8b 00                	mov    (%eax),%eax
8010629b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
801062a0:	89 fe                	mov    %edi,%esi
801062a2:	29 de                	sub    %ebx,%esi
801062a4:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801062aa:	76 b1                	jbe    8010625d <loaduvm+0x36>
      n = PGSIZE;
801062ac:	be 00 10 00 00       	mov    $0x1000,%esi
801062b1:	eb aa                	jmp    8010625d <loaduvm+0x36>
      return -1;
  }
  return 0;
801062b3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801062b8:	8d 65 f4             	lea    -0xc(%ebp),%esp
801062bb:	5b                   	pop    %ebx
801062bc:	5e                   	pop    %esi
801062bd:	5f                   	pop    %edi
801062be:	5d                   	pop    %ebp
801062bf:	c3                   	ret    
      return -1;
801062c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062c5:	eb f1                	jmp    801062b8 <loaduvm+0x91>

801062c7 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801062c7:	55                   	push   %ebp
801062c8:	89 e5                	mov    %esp,%ebp
801062ca:	57                   	push   %edi
801062cb:	56                   	push   %esi
801062cc:	53                   	push   %ebx
801062cd:	83 ec 0c             	sub    $0xc,%esp
801062d0:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801062d3:	39 7d 10             	cmp    %edi,0x10(%ebp)
801062d6:	73 11                	jae    801062e9 <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
801062d8:	8b 45 10             	mov    0x10(%ebp),%eax
801062db:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801062e1:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801062e7:	eb 19                	jmp    80106302 <deallocuvm+0x3b>
    return oldsz;
801062e9:	89 f8                	mov    %edi,%eax
801062eb:	eb 64                	jmp    80106351 <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
801062ed:	c1 eb 16             	shr    $0x16,%ebx
801062f0:	83 c3 01             	add    $0x1,%ebx
801062f3:	c1 e3 16             	shl    $0x16,%ebx
801062f6:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801062fc:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106302:	39 fb                	cmp    %edi,%ebx
80106304:	73 48                	jae    8010634e <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
80106306:	b9 00 00 00 00       	mov    $0x0,%ecx
8010630b:	89 da                	mov    %ebx,%edx
8010630d:	8b 45 08             	mov    0x8(%ebp),%eax
80106310:	e8 40 fb ff ff       	call   80105e55 <walkpgdir>
80106315:	89 c6                	mov    %eax,%esi
    if(!pte)
80106317:	85 c0                	test   %eax,%eax
80106319:	74 d2                	je     801062ed <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
8010631b:	8b 00                	mov    (%eax),%eax
8010631d:	a8 01                	test   $0x1,%al
8010631f:	74 db                	je     801062fc <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
80106321:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106326:	74 19                	je     80106341 <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
80106328:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
8010632d:	83 ec 0c             	sub    $0xc,%esp
80106330:	50                   	push   %eax
80106331:	e8 6e bc ff ff       	call   80101fa4 <kfree>
      *pte = 0;
80106336:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
8010633c:	83 c4 10             	add    $0x10,%esp
8010633f:	eb bb                	jmp    801062fc <deallocuvm+0x35>
        panic("kfree");
80106341:	83 ec 0c             	sub    $0xc,%esp
80106344:	68 a6 69 10 80       	push   $0x801069a6
80106349:	e8 fa 9f ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
8010634e:	8b 45 10             	mov    0x10(%ebp),%eax
}
80106351:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106354:	5b                   	pop    %ebx
80106355:	5e                   	pop    %esi
80106356:	5f                   	pop    %edi
80106357:	5d                   	pop    %ebp
80106358:	c3                   	ret    

80106359 <allocuvm>:
{
80106359:	55                   	push   %ebp
8010635a:	89 e5                	mov    %esp,%ebp
8010635c:	57                   	push   %edi
8010635d:	56                   	push   %esi
8010635e:	53                   	push   %ebx
8010635f:	83 ec 1c             	sub    $0x1c,%esp
80106362:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
80106365:	89 7d e4             	mov    %edi,-0x1c(%ebp)
80106368:	85 ff                	test   %edi,%edi
8010636a:	0f 88 cf 00 00 00    	js     8010643f <allocuvm+0xe6>
  if(newsz < oldsz)
80106370:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106373:	72 6a                	jb     801063df <allocuvm+0x86>
  a = PGROUNDUP(oldsz);
80106375:	8b 45 0c             	mov    0xc(%ebp),%eax
80106378:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
8010637e:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
80106384:	39 fb                	cmp    %edi,%ebx
80106386:	0f 83 ba 00 00 00    	jae    80106446 <allocuvm+0xed>
    mem = kalloc2(myproc()->pid);
8010638c:	e8 cd d0 ff ff       	call   8010345e <myproc>
80106391:	83 ec 0c             	sub    $0xc,%esp
80106394:	ff 70 10             	pushl  0x10(%eax)
80106397:	e8 c6 bd ff ff       	call   80102162 <kalloc2>
8010639c:	89 c6                	mov    %eax,%esi
    if(mem == 0){
8010639e:	83 c4 10             	add    $0x10,%esp
801063a1:	85 c0                	test   %eax,%eax
801063a3:	74 42                	je     801063e7 <allocuvm+0x8e>
    memset(mem, 0, PGSIZE);
801063a5:	83 ec 04             	sub    $0x4,%esp
801063a8:	68 00 10 00 00       	push   $0x1000
801063ad:	6a 00                	push   $0x0
801063af:	50                   	push   %eax
801063b0:	e8 f7 da ff ff       	call   80103eac <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
801063b5:	83 c4 08             	add    $0x8,%esp
801063b8:	6a 06                	push   $0x6
801063ba:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
801063c0:	50                   	push   %eax
801063c1:	b9 00 10 00 00       	mov    $0x1000,%ecx
801063c6:	89 da                	mov    %ebx,%edx
801063c8:	8b 45 08             	mov    0x8(%ebp),%eax
801063cb:	e8 fd fa ff ff       	call   80105ecd <mappages>
801063d0:	83 c4 10             	add    $0x10,%esp
801063d3:	85 c0                	test   %eax,%eax
801063d5:	78 38                	js     8010640f <allocuvm+0xb6>
  for(; a < newsz; a += PGSIZE){
801063d7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801063dd:	eb a5                	jmp    80106384 <allocuvm+0x2b>
    return oldsz;
801063df:	8b 45 0c             	mov    0xc(%ebp),%eax
801063e2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801063e5:	eb 5f                	jmp    80106446 <allocuvm+0xed>
      cprintf("allocuvm out of memory\n");
801063e7:	83 ec 0c             	sub    $0xc,%esp
801063ea:	68 89 70 10 80       	push   $0x80107089
801063ef:	e8 17 a2 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801063f4:	83 c4 0c             	add    $0xc,%esp
801063f7:	ff 75 0c             	pushl  0xc(%ebp)
801063fa:	57                   	push   %edi
801063fb:	ff 75 08             	pushl  0x8(%ebp)
801063fe:	e8 c4 fe ff ff       	call   801062c7 <deallocuvm>
      return 0;
80106403:	83 c4 10             	add    $0x10,%esp
80106406:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010640d:	eb 37                	jmp    80106446 <allocuvm+0xed>
      cprintf("allocuvm out of memory (2)\n");
8010640f:	83 ec 0c             	sub    $0xc,%esp
80106412:	68 a1 70 10 80       	push   $0x801070a1
80106417:	e8 ef a1 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010641c:	83 c4 0c             	add    $0xc,%esp
8010641f:	ff 75 0c             	pushl  0xc(%ebp)
80106422:	57                   	push   %edi
80106423:	ff 75 08             	pushl  0x8(%ebp)
80106426:	e8 9c fe ff ff       	call   801062c7 <deallocuvm>
      kfree(mem);
8010642b:	89 34 24             	mov    %esi,(%esp)
8010642e:	e8 71 bb ff ff       	call   80101fa4 <kfree>
      return 0;
80106433:	83 c4 10             	add    $0x10,%esp
80106436:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010643d:	eb 07                	jmp    80106446 <allocuvm+0xed>
    return 0;
8010643f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
80106446:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106449:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010644c:	5b                   	pop    %ebx
8010644d:	5e                   	pop    %esi
8010644e:	5f                   	pop    %edi
8010644f:	5d                   	pop    %ebp
80106450:	c3                   	ret    

80106451 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80106451:	55                   	push   %ebp
80106452:	89 e5                	mov    %esp,%ebp
80106454:	56                   	push   %esi
80106455:	53                   	push   %ebx
80106456:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
80106459:	85 f6                	test   %esi,%esi
8010645b:	74 1a                	je     80106477 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
8010645d:	83 ec 04             	sub    $0x4,%esp
80106460:	6a 00                	push   $0x0
80106462:	68 00 00 00 80       	push   $0x80000000
80106467:	56                   	push   %esi
80106468:	e8 5a fe ff ff       	call   801062c7 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
8010646d:	83 c4 10             	add    $0x10,%esp
80106470:	bb 00 00 00 00       	mov    $0x0,%ebx
80106475:	eb 10                	jmp    80106487 <freevm+0x36>
    panic("freevm: no pgdir");
80106477:	83 ec 0c             	sub    $0xc,%esp
8010647a:	68 bd 70 10 80       	push   $0x801070bd
8010647f:	e8 c4 9e ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
80106484:	83 c3 01             	add    $0x1,%ebx
80106487:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
8010648d:	77 1f                	ja     801064ae <freevm+0x5d>
    if(pgdir[i] & PTE_P){
8010648f:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
80106492:	a8 01                	test   $0x1,%al
80106494:	74 ee                	je     80106484 <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
80106496:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010649b:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801064a0:	83 ec 0c             	sub    $0xc,%esp
801064a3:	50                   	push   %eax
801064a4:	e8 fb ba ff ff       	call   80101fa4 <kfree>
801064a9:	83 c4 10             	add    $0x10,%esp
801064ac:	eb d6                	jmp    80106484 <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
801064ae:	83 ec 0c             	sub    $0xc,%esp
801064b1:	56                   	push   %esi
801064b2:	e8 ed ba ff ff       	call   80101fa4 <kfree>
}
801064b7:	83 c4 10             	add    $0x10,%esp
801064ba:	8d 65 f8             	lea    -0x8(%ebp),%esp
801064bd:	5b                   	pop    %ebx
801064be:	5e                   	pop    %esi
801064bf:	5d                   	pop    %ebp
801064c0:	c3                   	ret    

801064c1 <setupkvm>:
{
801064c1:	55                   	push   %ebp
801064c2:	89 e5                	mov    %esp,%ebp
801064c4:	56                   	push   %esi
801064c5:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc2(-2)) == 0)
801064c6:	83 ec 0c             	sub    $0xc,%esp
801064c9:	6a fe                	push   $0xfffffffe
801064cb:	e8 92 bc ff ff       	call   80102162 <kalloc2>
801064d0:	89 c6                	mov    %eax,%esi
801064d2:	83 c4 10             	add    $0x10,%esp
801064d5:	85 c0                	test   %eax,%eax
801064d7:	74 55                	je     8010652e <setupkvm+0x6d>
  memset(pgdir, 0, PGSIZE);
801064d9:	83 ec 04             	sub    $0x4,%esp
801064dc:	68 00 10 00 00       	push   $0x1000
801064e1:	6a 00                	push   $0x0
801064e3:	50                   	push   %eax
801064e4:	e8 c3 d9 ff ff       	call   80103eac <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801064e9:	83 c4 10             	add    $0x10,%esp
801064ec:	bb 20 a4 10 80       	mov    $0x8010a420,%ebx
801064f1:	81 fb 60 a4 10 80    	cmp    $0x8010a460,%ebx
801064f7:	73 35                	jae    8010652e <setupkvm+0x6d>
                (uint)k->phys_start, k->perm) < 0) {
801064f9:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
801064fc:	8b 4b 08             	mov    0x8(%ebx),%ecx
801064ff:	29 c1                	sub    %eax,%ecx
80106501:	83 ec 08             	sub    $0x8,%esp
80106504:	ff 73 0c             	pushl  0xc(%ebx)
80106507:	50                   	push   %eax
80106508:	8b 13                	mov    (%ebx),%edx
8010650a:	89 f0                	mov    %esi,%eax
8010650c:	e8 bc f9 ff ff       	call   80105ecd <mappages>
80106511:	83 c4 10             	add    $0x10,%esp
80106514:	85 c0                	test   %eax,%eax
80106516:	78 05                	js     8010651d <setupkvm+0x5c>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106518:	83 c3 10             	add    $0x10,%ebx
8010651b:	eb d4                	jmp    801064f1 <setupkvm+0x30>
      freevm(pgdir);
8010651d:	83 ec 0c             	sub    $0xc,%esp
80106520:	56                   	push   %esi
80106521:	e8 2b ff ff ff       	call   80106451 <freevm>
      return 0;
80106526:	83 c4 10             	add    $0x10,%esp
80106529:	be 00 00 00 00       	mov    $0x0,%esi
}
8010652e:	89 f0                	mov    %esi,%eax
80106530:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106533:	5b                   	pop    %ebx
80106534:	5e                   	pop    %esi
80106535:	5d                   	pop    %ebp
80106536:	c3                   	ret    

80106537 <kvmalloc>:
{
80106537:	55                   	push   %ebp
80106538:	89 e5                	mov    %esp,%ebp
8010653a:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
8010653d:	e8 7f ff ff ff       	call   801064c1 <setupkvm>
80106542:	a3 24 55 13 80       	mov    %eax,0x80135524
  switchkvm();
80106547:	e8 43 fb ff ff       	call   8010608f <switchkvm>
}
8010654c:	c9                   	leave  
8010654d:	c3                   	ret    

8010654e <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
8010654e:	55                   	push   %ebp
8010654f:	89 e5                	mov    %esp,%ebp
80106551:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106554:	b9 00 00 00 00       	mov    $0x0,%ecx
80106559:	8b 55 0c             	mov    0xc(%ebp),%edx
8010655c:	8b 45 08             	mov    0x8(%ebp),%eax
8010655f:	e8 f1 f8 ff ff       	call   80105e55 <walkpgdir>
  if(pte == 0)
80106564:	85 c0                	test   %eax,%eax
80106566:	74 05                	je     8010656d <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
80106568:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
8010656b:	c9                   	leave  
8010656c:	c3                   	ret    
    panic("clearpteu");
8010656d:	83 ec 0c             	sub    $0xc,%esp
80106570:	68 ce 70 10 80       	push   $0x801070ce
80106575:	e8 ce 9d ff ff       	call   80100348 <panic>

8010657a <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz, uint childPid)
{
8010657a:	55                   	push   %ebp
8010657b:	89 e5                	mov    %esp,%ebp
8010657d:	57                   	push   %edi
8010657e:	56                   	push   %esi
8010657f:	53                   	push   %ebx
80106580:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80106583:	e8 39 ff ff ff       	call   801064c1 <setupkvm>
80106588:	89 45 dc             	mov    %eax,-0x24(%ebp)
8010658b:	85 c0                	test   %eax,%eax
8010658d:	0f 84 d1 00 00 00    	je     80106664 <copyuvm+0xea>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80106593:	bf 00 00 00 00       	mov    $0x0,%edi
80106598:	89 fe                	mov    %edi,%esi
8010659a:	3b 75 0c             	cmp    0xc(%ebp),%esi
8010659d:	0f 83 c1 00 00 00    	jae    80106664 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801065a3:	89 75 e4             	mov    %esi,-0x1c(%ebp)
801065a6:	b9 00 00 00 00       	mov    $0x0,%ecx
801065ab:	89 f2                	mov    %esi,%edx
801065ad:	8b 45 08             	mov    0x8(%ebp),%eax
801065b0:	e8 a0 f8 ff ff       	call   80105e55 <walkpgdir>
801065b5:	85 c0                	test   %eax,%eax
801065b7:	74 70                	je     80106629 <copyuvm+0xaf>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
801065b9:	8b 18                	mov    (%eax),%ebx
801065bb:	f6 c3 01             	test   $0x1,%bl
801065be:	74 76                	je     80106636 <copyuvm+0xbc>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
801065c0:	89 df                	mov    %ebx,%edi
801065c2:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
    flags = PTE_FLAGS(*pte);
801065c8:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
801065ce:	89 5d e0             	mov    %ebx,-0x20(%ebp)
    if((mem = kalloc2(childPid)) == 0)
801065d1:	83 ec 0c             	sub    $0xc,%esp
801065d4:	ff 75 10             	pushl  0x10(%ebp)
801065d7:	e8 86 bb ff ff       	call   80102162 <kalloc2>
801065dc:	89 c3                	mov    %eax,%ebx
801065de:	83 c4 10             	add    $0x10,%esp
801065e1:	85 c0                	test   %eax,%eax
801065e3:	74 6a                	je     8010664f <copyuvm+0xd5>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
801065e5:	81 c7 00 00 00 80    	add    $0x80000000,%edi
801065eb:	83 ec 04             	sub    $0x4,%esp
801065ee:	68 00 10 00 00       	push   $0x1000
801065f3:	57                   	push   %edi
801065f4:	50                   	push   %eax
801065f5:	e8 2d d9 ff ff       	call   80103f27 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
801065fa:	83 c4 08             	add    $0x8,%esp
801065fd:	ff 75 e0             	pushl  -0x20(%ebp)
80106600:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106606:	50                   	push   %eax
80106607:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010660c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010660f:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106612:	e8 b6 f8 ff ff       	call   80105ecd <mappages>
80106617:	83 c4 10             	add    $0x10,%esp
8010661a:	85 c0                	test   %eax,%eax
8010661c:	78 25                	js     80106643 <copyuvm+0xc9>
  for(i = 0; i < sz; i += PGSIZE){
8010661e:	81 c6 00 10 00 00    	add    $0x1000,%esi
80106624:	e9 71 ff ff ff       	jmp    8010659a <copyuvm+0x20>
      panic("copyuvm: pte should exist");
80106629:	83 ec 0c             	sub    $0xc,%esp
8010662c:	68 d8 70 10 80       	push   $0x801070d8
80106631:	e8 12 9d ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
80106636:	83 ec 0c             	sub    $0xc,%esp
80106639:	68 f2 70 10 80       	push   $0x801070f2
8010663e:	e8 05 9d ff ff       	call   80100348 <panic>
      kfree(mem);
80106643:	83 ec 0c             	sub    $0xc,%esp
80106646:	53                   	push   %ebx
80106647:	e8 58 b9 ff ff       	call   80101fa4 <kfree>
      goto bad;
8010664c:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
8010664f:	83 ec 0c             	sub    $0xc,%esp
80106652:	ff 75 dc             	pushl  -0x24(%ebp)
80106655:	e8 f7 fd ff ff       	call   80106451 <freevm>
  return 0;
8010665a:	83 c4 10             	add    $0x10,%esp
8010665d:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
80106664:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106667:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010666a:	5b                   	pop    %ebx
8010666b:	5e                   	pop    %esi
8010666c:	5f                   	pop    %edi
8010666d:	5d                   	pop    %ebp
8010666e:	c3                   	ret    

8010666f <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
8010666f:	55                   	push   %ebp
80106670:	89 e5                	mov    %esp,%ebp
80106672:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106675:	b9 00 00 00 00       	mov    $0x0,%ecx
8010667a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010667d:	8b 45 08             	mov    0x8(%ebp),%eax
80106680:	e8 d0 f7 ff ff       	call   80105e55 <walkpgdir>
  if((*pte & PTE_P) == 0)
80106685:	8b 00                	mov    (%eax),%eax
80106687:	a8 01                	test   $0x1,%al
80106689:	74 10                	je     8010669b <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
8010668b:	a8 04                	test   $0x4,%al
8010668d:	74 13                	je     801066a2 <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
8010668f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106694:	05 00 00 00 80       	add    $0x80000000,%eax
}
80106699:	c9                   	leave  
8010669a:	c3                   	ret    
    return 0;
8010669b:	b8 00 00 00 00       	mov    $0x0,%eax
801066a0:	eb f7                	jmp    80106699 <uva2ka+0x2a>
    return 0;
801066a2:	b8 00 00 00 00       	mov    $0x0,%eax
801066a7:	eb f0                	jmp    80106699 <uva2ka+0x2a>

801066a9 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801066a9:	55                   	push   %ebp
801066aa:	89 e5                	mov    %esp,%ebp
801066ac:	57                   	push   %edi
801066ad:	56                   	push   %esi
801066ae:	53                   	push   %ebx
801066af:	83 ec 0c             	sub    $0xc,%esp
801066b2:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801066b5:	eb 25                	jmp    801066dc <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
801066b7:	8b 55 0c             	mov    0xc(%ebp),%edx
801066ba:	29 f2                	sub    %esi,%edx
801066bc:	01 d0                	add    %edx,%eax
801066be:	83 ec 04             	sub    $0x4,%esp
801066c1:	53                   	push   %ebx
801066c2:	ff 75 10             	pushl  0x10(%ebp)
801066c5:	50                   	push   %eax
801066c6:	e8 5c d8 ff ff       	call   80103f27 <memmove>
    len -= n;
801066cb:	29 df                	sub    %ebx,%edi
    buf += n;
801066cd:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
801066d0:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
801066d6:	89 45 0c             	mov    %eax,0xc(%ebp)
801066d9:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
801066dc:	85 ff                	test   %edi,%edi
801066de:	74 2f                	je     8010670f <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
801066e0:	8b 75 0c             	mov    0xc(%ebp),%esi
801066e3:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
801066e9:	83 ec 08             	sub    $0x8,%esp
801066ec:	56                   	push   %esi
801066ed:	ff 75 08             	pushl  0x8(%ebp)
801066f0:	e8 7a ff ff ff       	call   8010666f <uva2ka>
    if(pa0 == 0)
801066f5:	83 c4 10             	add    $0x10,%esp
801066f8:	85 c0                	test   %eax,%eax
801066fa:	74 20                	je     8010671c <copyout+0x73>
    n = PGSIZE - (va - va0);
801066fc:	89 f3                	mov    %esi,%ebx
801066fe:	2b 5d 0c             	sub    0xc(%ebp),%ebx
80106701:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
80106707:	39 df                	cmp    %ebx,%edi
80106709:	73 ac                	jae    801066b7 <copyout+0xe>
      n = len;
8010670b:	89 fb                	mov    %edi,%ebx
8010670d:	eb a8                	jmp    801066b7 <copyout+0xe>
  }
  return 0;
8010670f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106714:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106717:	5b                   	pop    %ebx
80106718:	5e                   	pop    %esi
80106719:	5f                   	pop    %edi
8010671a:	5d                   	pop    %ebp
8010671b:	c3                   	ret    
      return -1;
8010671c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106721:	eb f1                	jmp    80106714 <copyout+0x6b>
