
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
80100015:	b8 00 90 12 00       	mov    $0x129000,%eax
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
80100028:	bc d0 b5 12 80       	mov    $0x8012b5d0,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 af 2c 10 80       	mov    $0x80102caf,%eax
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
80100041:	68 e0 b5 12 80       	push   $0x8012b5e0
80100046:	e8 a0 3d 00 00       	call   80103deb <acquire>

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010004b:	8b 1d 30 fd 12 80    	mov    0x8012fd30,%ebx
80100051:	83 c4 10             	add    $0x10,%esp
80100054:	eb 03                	jmp    80100059 <bget+0x25>
80100056:	8b 5b 54             	mov    0x54(%ebx),%ebx
80100059:	81 fb dc fc 12 80    	cmp    $0x8012fcdc,%ebx
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
80100077:	68 e0 b5 12 80       	push   $0x8012b5e0
8010007c:	e8 cf 3d 00 00       	call   80103e50 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 4b 3b 00 00       	call   80103bd7 <acquiresleep>
      return b;
8010008c:	83 c4 10             	add    $0x10,%esp
8010008f:	eb 4c                	jmp    801000dd <bget+0xa9>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100091:	8b 1d 2c fd 12 80    	mov    0x8012fd2c,%ebx
80100097:	eb 03                	jmp    8010009c <bget+0x68>
80100099:	8b 5b 50             	mov    0x50(%ebx),%ebx
8010009c:	81 fb dc fc 12 80    	cmp    $0x8012fcdc,%ebx
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
801000c5:	68 e0 b5 12 80       	push   $0x8012b5e0
801000ca:	e8 81 3d 00 00       	call   80103e50 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 fd 3a 00 00       	call   80103bd7 <acquiresleep>
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
801000ea:	68 20 67 10 80       	push   $0x80106720
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 31 67 10 80       	push   $0x80106731
80100100:	68 e0 b5 12 80       	push   $0x8012b5e0
80100105:	e8 a5 3b 00 00       	call   80103caf <initlock>
  bcache.head.prev = &bcache.head;
8010010a:	c7 05 2c fd 12 80 dc 	movl   $0x8012fcdc,0x8012fd2c
80100111:	fc 12 80 
  bcache.head.next = &bcache.head;
80100114:	c7 05 30 fd 12 80 dc 	movl   $0x8012fcdc,0x8012fd30
8010011b:	fc 12 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010011e:	83 c4 10             	add    $0x10,%esp
80100121:	bb 14 b6 12 80       	mov    $0x8012b614,%ebx
80100126:	eb 37                	jmp    8010015f <binit+0x6b>
    b->next = bcache.head.next;
80100128:	a1 30 fd 12 80       	mov    0x8012fd30,%eax
8010012d:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
80100130:	c7 43 50 dc fc 12 80 	movl   $0x8012fcdc,0x50(%ebx)
    initsleeplock(&b->lock, "buffer");
80100137:	83 ec 08             	sub    $0x8,%esp
8010013a:	68 38 67 10 80       	push   $0x80106738
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 5c 3a 00 00       	call   80103ba4 <initsleeplock>
    bcache.head.next->prev = b;
80100148:	a1 30 fd 12 80       	mov    0x8012fd30,%eax
8010014d:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
80100150:	89 1d 30 fd 12 80    	mov    %ebx,0x8012fd30
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100156:	81 c3 5c 02 00 00    	add    $0x25c,%ebx
8010015c:	83 c4 10             	add    $0x10,%esp
8010015f:	81 fb dc fc 12 80    	cmp    $0x8012fcdc,%ebx
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
801001a8:	e8 b4 3a 00 00       	call   80103c61 <holdingsleep>
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
801001cb:	68 3f 67 10 80       	push   $0x8010673f
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
801001e4:	e8 78 3a 00 00       	call   80103c61 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 2d 3a 00 00       	call   80103c26 <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 e0 b5 12 80 	movl   $0x8012b5e0,(%esp)
80100200:	e8 e6 3b 00 00       	call   80103deb <acquire>
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
80100227:	a1 30 fd 12 80       	mov    0x8012fd30,%eax
8010022c:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
8010022f:	c7 43 50 dc fc 12 80 	movl   $0x8012fcdc,0x50(%ebx)
    bcache.head.next->prev = b;
80100236:	a1 30 fd 12 80       	mov    0x8012fd30,%eax
8010023b:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
8010023e:	89 1d 30 fd 12 80    	mov    %ebx,0x8012fd30
  }
  
  release(&bcache.lock);
80100244:	83 ec 0c             	sub    $0xc,%esp
80100247:	68 e0 b5 12 80       	push   $0x8012b5e0
8010024c:	e8 ff 3b 00 00       	call   80103e50 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 46 67 10 80       	push   $0x80106746
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
80100283:	c7 04 24 20 a5 12 80 	movl   $0x8012a520,(%esp)
8010028a:	e8 5c 3b 00 00       	call   80103deb <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 c0 ff 12 80       	mov    0x8012ffc0,%eax
8010029f:	3b 05 c4 ff 12 80    	cmp    0x8012ffc4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 9d 31 00 00       	call   80103449 <myproc>
801002ac:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801002b0:	75 17                	jne    801002c9 <consoleread+0x61>
        release(&cons.lock);
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
801002b2:	83 ec 08             	sub    $0x8,%esp
801002b5:	68 20 a5 12 80       	push   $0x8012a520
801002ba:	68 c0 ff 12 80       	push   $0x8012ffc0
801002bf:	e8 2c 36 00 00       	call   801038f0 <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 a5 12 80       	push   $0x8012a520
801002d1:	e8 7a 3b 00 00       	call   80103e50 <release>
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
801002f1:	89 15 c0 ff 12 80    	mov    %edx,0x8012ffc0
801002f7:	89 c2                	mov    %eax,%edx
801002f9:	83 e2 7f             	and    $0x7f,%edx
801002fc:	0f b6 8a 40 ff 12 80 	movzbl -0x7fed00c0(%edx),%ecx
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
80100324:	a3 c0 ff 12 80       	mov    %eax,0x8012ffc0
  release(&cons.lock);
80100329:	83 ec 0c             	sub    $0xc,%esp
8010032c:	68 20 a5 12 80       	push   $0x8012a520
80100331:	e8 1a 3b 00 00       	call   80103e50 <release>
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
80100350:	c7 05 54 a5 12 80 00 	movl   $0x0,0x8012a554
80100357:	00 00 00 
  cprintf("lapicid %d: panic: ", lapicid());
8010035a:	e8 6a 22 00 00       	call   801025c9 <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 4d 67 10 80       	push   $0x8010674d
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 9b 70 10 80 	movl   $0x8010709b,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 36 39 00 00       	call   80103cca <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 61 67 10 80       	push   $0x80106761
801003aa:	e8 5c 02 00 00       	call   8010060b <cprintf>
  for(i=0; i<10; i++)
801003af:	83 c3 01             	add    $0x1,%ebx
801003b2:	83 c4 10             	add    $0x10,%esp
801003b5:	83 fb 09             	cmp    $0x9,%ebx
801003b8:	7e e4                	jle    8010039e <panic+0x56>
  panicked = 1; // freeze other CPU
801003ba:	c7 05 58 a5 12 80 01 	movl   $0x1,0x8012a558
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
8010049e:	68 65 67 10 80       	push   $0x80106765
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 53 3a 00 00       	call   80103f12 <memmove>
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
801004d9:	e8 b9 39 00 00       	call   80103e97 <memset>
801004de:	83 c4 10             	add    $0x10,%esp
801004e1:	e9 4c ff ff ff       	jmp    80100432 <cgaputc+0x6c>

801004e6 <consputc>:
  if(panicked){
801004e6:	83 3d 58 a5 12 80 00 	cmpl   $0x0,0x8012a558
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
80100506:	e8 c6 4d 00 00       	call   801052d1 <uartputc>
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
8010051f:	e8 ad 4d 00 00       	call   801052d1 <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 a1 4d 00 00       	call   801052d1 <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 95 4d 00 00       	call   801052d1 <uartputc>
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
80100576:	0f b6 92 90 67 10 80 	movzbl -0x7fef9870(%edx),%edx
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
801005c3:	c7 04 24 20 a5 12 80 	movl   $0x8012a520,(%esp)
801005ca:	e8 1c 38 00 00       	call   80103deb <acquire>
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
801005ec:	68 20 a5 12 80       	push   $0x8012a520
801005f1:	e8 5a 38 00 00       	call   80103e50 <release>
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
80100614:	a1 54 a5 12 80       	mov    0x8012a554,%eax
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
80100633:	68 20 a5 12 80       	push   $0x8012a520
80100638:	e8 ae 37 00 00       	call   80103deb <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 7f 67 10 80       	push   $0x8010677f
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
801006ee:	be 78 67 10 80       	mov    $0x80106778,%esi
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
8010072f:	68 20 a5 12 80       	push   $0x8012a520
80100734:	e8 17 37 00 00       	call   80103e50 <release>
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
8010074a:	68 20 a5 12 80       	push   $0x8012a520
8010074f:	e8 97 36 00 00       	call   80103deb <acquire>
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
80100772:	a1 c8 ff 12 80       	mov    0x8012ffc8,%eax
80100777:	89 c2                	mov    %eax,%edx
80100779:	2b 15 c0 ff 12 80    	sub    0x8012ffc0,%edx
8010077f:	83 fa 7f             	cmp    $0x7f,%edx
80100782:	0f 87 9e 00 00 00    	ja     80100826 <consoleintr+0xe8>
        c = (c == '\r') ? '\n' : c;
80100788:	83 ff 0d             	cmp    $0xd,%edi
8010078b:	0f 84 86 00 00 00    	je     80100817 <consoleintr+0xd9>
        input.buf[input.e++ % INPUT_BUF] = c;
80100791:	8d 50 01             	lea    0x1(%eax),%edx
80100794:	89 15 c8 ff 12 80    	mov    %edx,0x8012ffc8
8010079a:	83 e0 7f             	and    $0x7f,%eax
8010079d:	89 f9                	mov    %edi,%ecx
8010079f:	88 88 40 ff 12 80    	mov    %cl,-0x7fed00c0(%eax)
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
801007bc:	a1 c0 ff 12 80       	mov    0x8012ffc0,%eax
801007c1:	83 e8 80             	sub    $0xffffff80,%eax
801007c4:	39 05 c8 ff 12 80    	cmp    %eax,0x8012ffc8
801007ca:	75 5a                	jne    80100826 <consoleintr+0xe8>
          input.w = input.e;
801007cc:	a1 c8 ff 12 80       	mov    0x8012ffc8,%eax
801007d1:	a3 c4 ff 12 80       	mov    %eax,0x8012ffc4
          wakeup(&input.r);
801007d6:	83 ec 0c             	sub    $0xc,%esp
801007d9:	68 c0 ff 12 80       	push   $0x8012ffc0
801007de:	e8 72 32 00 00       	call   80103a55 <wakeup>
801007e3:	83 c4 10             	add    $0x10,%esp
801007e6:	eb 3e                	jmp    80100826 <consoleintr+0xe8>
        input.e--;
801007e8:	a3 c8 ff 12 80       	mov    %eax,0x8012ffc8
        consputc(BACKSPACE);
801007ed:	b8 00 01 00 00       	mov    $0x100,%eax
801007f2:	e8 ef fc ff ff       	call   801004e6 <consputc>
      while(input.e != input.w &&
801007f7:	a1 c8 ff 12 80       	mov    0x8012ffc8,%eax
801007fc:	3b 05 c4 ff 12 80    	cmp    0x8012ffc4,%eax
80100802:	74 22                	je     80100826 <consoleintr+0xe8>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100804:	83 e8 01             	sub    $0x1,%eax
80100807:	89 c2                	mov    %eax,%edx
80100809:	83 e2 7f             	and    $0x7f,%edx
      while(input.e != input.w &&
8010080c:	80 ba 40 ff 12 80 0a 	cmpb   $0xa,-0x7fed00c0(%edx)
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
8010084a:	a1 c8 ff 12 80       	mov    0x8012ffc8,%eax
8010084f:	3b 05 c4 ff 12 80    	cmp    0x8012ffc4,%eax
80100855:	74 cf                	je     80100826 <consoleintr+0xe8>
        input.e--;
80100857:	83 e8 01             	sub    $0x1,%eax
8010085a:	a3 c8 ff 12 80       	mov    %eax,0x8012ffc8
        consputc(BACKSPACE);
8010085f:	b8 00 01 00 00       	mov    $0x100,%eax
80100864:	e8 7d fc ff ff       	call   801004e6 <consputc>
80100869:	eb bb                	jmp    80100826 <consoleintr+0xe8>
  release(&cons.lock);
8010086b:	83 ec 0c             	sub    $0xc,%esp
8010086e:	68 20 a5 12 80       	push   $0x8012a520
80100873:	e8 d8 35 00 00       	call   80103e50 <release>
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
80100887:	e8 66 32 00 00       	call   80103af2 <procdump>
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
80100894:	68 88 67 10 80       	push   $0x80106788
80100899:	68 20 a5 12 80       	push   $0x8012a520
8010089e:	e8 0c 34 00 00       	call   80103caf <initlock>

  devsw[CONSOLE].write = consolewrite;
801008a3:	c7 05 8c 09 13 80 ac 	movl   $0x801005ac,0x8013098c
801008aa:	05 10 80 
  devsw[CONSOLE].read = consoleread;
801008ad:	c7 05 88 09 13 80 68 	movl   $0x80100268,0x80130988
801008b4:	02 10 80 
  cons.locking = 1;
801008b7:	c7 05 54 a5 12 80 01 	movl   $0x1,0x8012a554
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
801008de:	e8 66 2b 00 00       	call   80103449 <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 0b 21 00 00       	call   801029f9 <begin_op>

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
80100935:	e8 39 21 00 00       	call   80102a73 <end_op>
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
8010094a:	e8 24 21 00 00       	call   80102a73 <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 a1 67 10 80       	push   $0x801067a1
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
80100972:	e8 35 5b 00 00       	call   801064ac <setupkvm>
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
80100a06:	e8 39 59 00 00       	call   80106344 <allocuvm>
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
80100a38:	e8 d5 57 00 00       	call   80106212 <loaduvm>
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
80100a53:	e8 1b 20 00 00       	call   80102a73 <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 cb 58 00 00       	call   80106344 <allocuvm>
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
80100a9d:	e8 9a 59 00 00       	call   8010643c <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 78 5a 00 00       	call   80106539 <clearpteu>
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
80100ae2:	e8 52 35 00 00       	call   80104039 <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 40 35 00 00       	call   80104039 <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 89 5b 00 00       	call   80106694 <copyout>
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
80100b66:	e8 29 5b 00 00       	call   80106694 <copyout>
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
80100ba3:	e8 56 34 00 00       	call   80103ffe <safestrcpy>
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
80100bd1:	e8 b6 54 00 00       	call   8010608c <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 5e 58 00 00       	call   8010643c <freevm>
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
80100c19:	68 ad 67 10 80       	push   $0x801067ad
80100c1e:	68 e0 ff 12 80       	push   $0x8012ffe0
80100c23:	e8 87 30 00 00       	call   80103caf <initlock>
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
80100c34:	68 e0 ff 12 80       	push   $0x8012ffe0
80100c39:	e8 ad 31 00 00       	call   80103deb <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c3e:	83 c4 10             	add    $0x10,%esp
80100c41:	bb 14 00 13 80       	mov    $0x80130014,%ebx
80100c46:	81 fb 74 09 13 80    	cmp    $0x80130974,%ebx
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
80100c63:	68 e0 ff 12 80       	push   $0x8012ffe0
80100c68:	e8 e3 31 00 00       	call   80103e50 <release>
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
80100c7a:	68 e0 ff 12 80       	push   $0x8012ffe0
80100c7f:	e8 cc 31 00 00       	call   80103e50 <release>
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
80100c98:	68 e0 ff 12 80       	push   $0x8012ffe0
80100c9d:	e8 49 31 00 00       	call   80103deb <acquire>
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
80100cb5:	68 e0 ff 12 80       	push   $0x8012ffe0
80100cba:	e8 91 31 00 00       	call   80103e50 <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 b4 67 10 80       	push   $0x801067b4
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
80100cdd:	68 e0 ff 12 80       	push   $0x8012ffe0
80100ce2:	e8 04 31 00 00       	call   80103deb <acquire>
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
80100cfe:	68 e0 ff 12 80       	push   $0x8012ffe0
80100d03:	e8 48 31 00 00       	call   80103e50 <release>
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
80100d13:	68 bc 67 10 80       	push   $0x801067bc
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
80100d44:	68 e0 ff 12 80       	push   $0x8012ffe0
80100d49:	e8 02 31 00 00       	call   80103e50 <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 96 1c 00 00       	call   801029f9 <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 00 1d 00 00       	call   80102a73 <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 ed 22 00 00       	call   80103075 <pipeclose>
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
80100e3c:	e8 8c 23 00 00       	call   801031cd <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 c6 67 10 80       	push   $0x801067c6
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
80100e95:	e8 67 22 00 00       	call   80103101 <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 52 1b 00 00       	call   801029f9 <begin_op>
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
80100edd:	e8 91 1b 00 00       	call   80102a73 <end_op>

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
80100f10:	68 cf 67 10 80       	push   $0x801067cf
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
80100f2d:	68 d5 67 10 80       	push   $0x801067d5
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
80100f8a:	e8 83 2f 00 00       	call   80103f12 <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 73 2f 00 00       	call   80103f12 <memmove>
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
80100fdf:	e8 b3 2e 00 00       	call   80103e97 <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 36 1b 00 00       	call   80102b22 <log_write>
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
80101023:	39 35 e0 09 13 80    	cmp    %esi,0x801309e0
80101029:	76 75                	jbe    801010a0 <balloc+0xa4>
    bp = bread(dev, BBLOCK(b, sb));
8010102b:	8d 86 ff 0f 00 00    	lea    0xfff(%esi),%eax
80101031:	85 f6                	test   %esi,%esi
80101033:	0f 49 c6             	cmovns %esi,%eax
80101036:	c1 f8 0c             	sar    $0xc,%eax
80101039:	03 05 f8 09 13 80    	add    0x801309f8,%eax
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
80101063:	3b 1d e0 09 13 80    	cmp    0x801309e0,%ebx
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
801010a3:	68 df 67 10 80       	push   $0x801067df
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
801010bf:	e8 5e 1a 00 00       	call   80102b22 <log_write>
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
80101170:	e8 ad 19 00 00       	call   80102b22 <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 f5 67 10 80       	push   $0x801067f5
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
80101195:	68 00 0a 13 80       	push   $0x80130a00
8010119a:	e8 4c 2c 00 00       	call   80103deb <acquire>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010119f:	83 c4 10             	add    $0x10,%esp
  empty = 0;
801011a2:	be 00 00 00 00       	mov    $0x0,%esi
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011a7:	bb 34 0a 13 80       	mov    $0x80130a34,%ebx
801011ac:	eb 0a                	jmp    801011b8 <iget+0x31>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801011ae:	85 f6                	test   %esi,%esi
801011b0:	74 3b                	je     801011ed <iget+0x66>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801011b2:	81 c3 90 00 00 00    	add    $0x90,%ebx
801011b8:	81 fb 54 26 13 80    	cmp    $0x80132654,%ebx
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
801011dc:	68 00 0a 13 80       	push   $0x80130a00
801011e1:	e8 6a 2c 00 00       	call   80103e50 <release>
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
80101212:	68 00 0a 13 80       	push   $0x80130a00
80101217:	e8 34 2c 00 00       	call   80103e50 <release>
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
8010122c:	68 08 68 10 80       	push   $0x80106808
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
80101255:	e8 b8 2c 00 00       	call   80103f12 <memmove>
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
80101276:	68 e0 09 13 80       	push   $0x801309e0
8010127b:	50                   	push   %eax
8010127c:	e8 b5 ff ff ff       	call   80101236 <readsb>
  bp = bread(dev, BBLOCK(b, sb));
80101281:	89 d8                	mov    %ebx,%eax
80101283:	c1 e8 0c             	shr    $0xc,%eax
80101286:	03 05 f8 09 13 80    	add    0x801309f8,%eax
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
801012c8:	e8 55 18 00 00       	call   80102b22 <log_write>
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
801012e2:	68 18 68 10 80       	push   $0x80106818
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 2b 68 10 80       	push   $0x8010682b
801012f8:	68 00 0a 13 80       	push   $0x80130a00
801012fd:	e8 ad 29 00 00       	call   80103caf <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 32 68 10 80       	push   $0x80106832
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 40 0a 13 80       	add    $0x80130a40,%eax
80101321:	50                   	push   %eax
80101322:	e8 7d 28 00 00       	call   80103ba4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
80101327:	83 c3 01             	add    $0x1,%ebx
8010132a:	83 c4 10             	add    $0x10,%esp
8010132d:	83 fb 31             	cmp    $0x31,%ebx
80101330:	7e da                	jle    8010130c <iinit+0x20>
  readsb(dev, &sb);
80101332:	83 ec 08             	sub    $0x8,%esp
80101335:	68 e0 09 13 80       	push   $0x801309e0
8010133a:	ff 75 08             	pushl  0x8(%ebp)
8010133d:	e8 f4 fe ff ff       	call   80101236 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
80101342:	ff 35 f8 09 13 80    	pushl  0x801309f8
80101348:	ff 35 f4 09 13 80    	pushl  0x801309f4
8010134e:	ff 35 f0 09 13 80    	pushl  0x801309f0
80101354:	ff 35 ec 09 13 80    	pushl  0x801309ec
8010135a:	ff 35 e8 09 13 80    	pushl  0x801309e8
80101360:	ff 35 e4 09 13 80    	pushl  0x801309e4
80101366:	ff 35 e0 09 13 80    	pushl  0x801309e0
8010136c:	68 98 68 10 80       	push   $0x80106898
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
80101395:	39 1d e8 09 13 80    	cmp    %ebx,0x801309e8
8010139b:	76 3f                	jbe    801013dc <ialloc+0x5e>
    bp = bread(dev, IBLOCK(inum, sb));
8010139d:	89 d8                	mov    %ebx,%eax
8010139f:	c1 e8 03             	shr    $0x3,%eax
801013a2:	03 05 f4 09 13 80    	add    0x801309f4,%eax
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
801013df:	68 38 68 10 80       	push   $0x80106838
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 a1 2a 00 00       	call   80103e97 <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 1d 17 00 00       	call   80102b22 <log_write>
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
8010142e:	03 05 f4 09 13 80    	add    0x801309f4,%eax
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
80101480:	e8 8d 2a 00 00       	call   80103f12 <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 95 16 00 00       	call   80102b22 <log_write>
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
8010155b:	68 00 0a 13 80       	push   $0x80130a00
80101560:	e8 86 28 00 00       	call   80103deb <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 00 0a 13 80 	movl   $0x80130a00,(%esp)
80101575:	e8 d6 28 00 00       	call   80103e50 <release>
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
8010159a:	e8 38 26 00 00       	call   80103bd7 <acquiresleep>
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
801015b2:	68 4a 68 10 80       	push   $0x8010684a
801015b7:	e8 8c ed ff ff       	call   80100348 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
801015bc:	8b 43 04             	mov    0x4(%ebx),%eax
801015bf:	c1 e8 03             	shr    $0x3,%eax
801015c2:	03 05 f4 09 13 80    	add    0x801309f4,%eax
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
80101614:	e8 f9 28 00 00       	call   80103f12 <memmove>
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
80101639:	68 50 68 10 80       	push   $0x80106850
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
80101656:	e8 06 26 00 00       	call   80103c61 <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 b5 25 00 00       	call   80103c26 <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 5f 68 10 80       	push   $0x8010685f
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
80101698:	e8 3a 25 00 00       	call   80103bd7 <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 70 25 00 00       	call   80103c26 <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 00 0a 13 80 	movl   $0x80130a00,(%esp)
801016bd:	e8 29 27 00 00       	call   80103deb <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 00 0a 13 80 	movl   $0x80130a00,(%esp)
801016d2:	e8 79 27 00 00       	call   80103e50 <release>
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
801016e5:	68 00 0a 13 80       	push   $0x80130a00
801016ea:	e8 fc 26 00 00       	call   80103deb <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 00 0a 13 80 	movl   $0x80130a00,(%esp)
801016f9:	e8 52 27 00 00       	call   80103e50 <release>
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
801017c4:	8b 04 c5 80 09 13 80 	mov    -0x7fecf680(,%eax,8),%eax
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
8010182a:	e8 e3 26 00 00       	call   80103f12 <memmove>
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
801018c1:	8b 04 c5 84 09 13 80 	mov    -0x7fecf67c(,%eax,8),%eax
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
80101926:	e8 e7 25 00 00       	call   80103f12 <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 ef 11 00 00       	call   80102b22 <log_write>
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
801019a9:	e8 cb 25 00 00       	call   80103f79 <strncmp>
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
801019d0:	68 67 68 10 80       	push   $0x80106867
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 79 68 10 80       	push   $0x80106879
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
80101a5a:	e8 ea 19 00 00       	call   80103449 <myproc>
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
80101b92:	68 88 68 10 80       	push   $0x80106888
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 08 24 00 00       	call   80103fb6 <strncpy>
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
80101bd7:	68 94 6e 10 80       	push   $0x80106e94
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
80101ccc:	68 eb 68 10 80       	push   $0x801068eb
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 f4 68 10 80       	push   $0x801068f4
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
80101d06:	68 06 69 10 80       	push   $0x80106906
80101d0b:	68 80 a5 12 80       	push   $0x8012a580
80101d10:	e8 9a 1f 00 00       	call   80103caf <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101d15:	83 c4 08             	add    $0x8,%esp
80101d18:	a1 40 2d 13 80       	mov    0x80132d40,%eax
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
80101d5c:	c7 05 60 a5 12 80 01 	movl   $0x1,0x8012a560
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
80101d7b:	68 80 a5 12 80       	push   $0x8012a580
80101d80:	e8 66 20 00 00       	call   80103deb <acquire>

  if((b = idequeue) == 0){
80101d85:	8b 1d 64 a5 12 80    	mov    0x8012a564,%ebx
80101d8b:	83 c4 10             	add    $0x10,%esp
80101d8e:	85 db                	test   %ebx,%ebx
80101d90:	74 48                	je     80101dda <ideintr+0x67>
    release(&idelock);
    return;
  }
  idequeue = b->qnext;
80101d92:	8b 43 58             	mov    0x58(%ebx),%eax
80101d95:	a3 64 a5 12 80       	mov    %eax,0x8012a564

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
80101dad:	e8 a3 1c 00 00       	call   80103a55 <wakeup>

  // Start disk on next buf in queue.
  if(idequeue != 0)
80101db2:	a1 64 a5 12 80       	mov    0x8012a564,%eax
80101db7:	83 c4 10             	add    $0x10,%esp
80101dba:	85 c0                	test   %eax,%eax
80101dbc:	74 05                	je     80101dc3 <ideintr+0x50>
    idestart(idequeue);
80101dbe:	e8 80 fe ff ff       	call   80101c43 <idestart>

  release(&idelock);
80101dc3:	83 ec 0c             	sub    $0xc,%esp
80101dc6:	68 80 a5 12 80       	push   $0x8012a580
80101dcb:	e8 80 20 00 00       	call   80103e50 <release>
80101dd0:	83 c4 10             	add    $0x10,%esp
}
80101dd3:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101dd6:	5b                   	pop    %ebx
80101dd7:	5f                   	pop    %edi
80101dd8:	5d                   	pop    %ebp
80101dd9:	c3                   	ret    
    release(&idelock);
80101dda:	83 ec 0c             	sub    $0xc,%esp
80101ddd:	68 80 a5 12 80       	push   $0x8012a580
80101de2:	e8 69 20 00 00       	call   80103e50 <release>
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
80101e1a:	e8 42 1e 00 00       	call   80103c61 <holdingsleep>
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
80101e36:	83 3d 60 a5 12 80 00 	cmpl   $0x0,0x8012a560
80101e3d:	74 38                	je     80101e77 <iderw+0x6b>
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);  //DOC:acquire-lock
80101e3f:	83 ec 0c             	sub    $0xc,%esp
80101e42:	68 80 a5 12 80       	push   $0x8012a580
80101e47:	e8 9f 1f 00 00       	call   80103deb <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 a5 12 80       	mov    $0x8012a564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 0a 69 10 80       	push   $0x8010690a
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 20 69 10 80       	push   $0x80106920
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 35 69 10 80       	push   $0x80106935
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
80101e8f:	39 1d 64 a5 12 80    	cmp    %ebx,0x8012a564
80101e95:	75 1a                	jne    80101eb1 <iderw+0xa5>
    idestart(b);
80101e97:	89 d8                	mov    %ebx,%eax
80101e99:	e8 a5 fd ff ff       	call   80101c43 <idestart>
80101e9e:	eb 11                	jmp    80101eb1 <iderw+0xa5>

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
80101ea0:	83 ec 08             	sub    $0x8,%esp
80101ea3:	68 80 a5 12 80       	push   $0x8012a580
80101ea8:	53                   	push   %ebx
80101ea9:	e8 42 1a 00 00       	call   801038f0 <sleep>
80101eae:	83 c4 10             	add    $0x10,%esp
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80101eb1:	8b 03                	mov    (%ebx),%eax
80101eb3:	83 e0 06             	and    $0x6,%eax
80101eb6:	83 f8 02             	cmp    $0x2,%eax
80101eb9:	75 e5                	jne    80101ea0 <iderw+0x94>
  }


  release(&idelock);
80101ebb:	83 ec 0c             	sub    $0xc,%esp
80101ebe:	68 80 a5 12 80       	push   $0x8012a580
80101ec3:	e8 88 1f 00 00       	call   80103e50 <release>
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
80101ed3:	8b 15 54 26 13 80    	mov    0x80132654,%edx
80101ed9:	89 02                	mov    %eax,(%edx)
  return ioapic->data;
80101edb:	a1 54 26 13 80       	mov    0x80132654,%eax
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
80101ee8:	8b 0d 54 26 13 80    	mov    0x80132654,%ecx
80101eee:	89 01                	mov    %eax,(%ecx)
  ioapic->data = data;
80101ef0:	a1 54 26 13 80       	mov    0x80132654,%eax
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
80101f03:	c7 05 54 26 13 80 00 	movl   $0xfec00000,0x80132654
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
80101f2a:	0f b6 15 a0 27 13 80 	movzbl 0x801327a0,%edx
80101f31:	39 c2                	cmp    %eax,%edx
80101f33:	75 07                	jne    80101f3c <ioapicinit+0x42>
{
80101f35:	bb 00 00 00 00       	mov    $0x0,%ebx
80101f3a:	eb 36                	jmp    80101f72 <ioapicinit+0x78>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80101f3c:	83 ec 0c             	sub    $0xc,%esp
80101f3f:	68 54 69 10 80       	push   $0x80106954
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
80101fb6:	81 fb e8 54 13 80    	cmp    $0x801354e8,%ebx
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
80101fd6:	e8 bc 1e 00 00       	call   80103e97 <memset>

  if(kmem.use_lock)
80101fdb:	83 c4 10             	add    $0x10,%esp
80101fde:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
80101fe5:	75 28                	jne    8010200f <kfree+0x6b>
  //   frames[i] = frames[i+1];
  //   pids[i] = pids[i+1];
  // }

  //add to free list
  r->next = kmem.freelist;
80101fe7:	a1 98 26 13 80       	mov    0x80132698,%eax
80101fec:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
80101fee:	89 1d 98 26 13 80    	mov    %ebx,0x80132698


  if(kmem.use_lock)
80101ff4:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
80101ffb:	75 24                	jne    80102021 <kfree+0x7d>
    release(&kmem.lock);
}
80101ffd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102000:	c9                   	leave  
80102001:	c3                   	ret    
    panic("kfree");
80102002:	83 ec 0c             	sub    $0xc,%esp
80102005:	68 86 69 10 80       	push   $0x80106986
8010200a:	e8 39 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010200f:	83 ec 0c             	sub    $0xc,%esp
80102012:	68 60 26 13 80       	push   $0x80132660
80102017:	e8 cf 1d 00 00       	call   80103deb <acquire>
8010201c:	83 c4 10             	add    $0x10,%esp
8010201f:	eb c6                	jmp    80101fe7 <kfree+0x43>
    release(&kmem.lock);
80102021:	83 ec 0c             	sub    $0xc,%esp
80102024:	68 60 26 13 80       	push   $0x80132660
80102029:	e8 22 1e 00 00       	call   80103e50 <release>
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
8010206f:	68 8c 69 10 80       	push   $0x8010698c
80102074:	68 60 26 13 80       	push   $0x80132660
80102079:	e8 31 1c 00 00       	call   80103caf <initlock>
  kmem.use_lock = 0;
8010207e:	c7 05 94 26 13 80 00 	movl   $0x0,0x80132694
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
  flag = 1;
801020a1:	c7 05 b4 a5 12 80 01 	movl   $0x1,0x8012a5b4
801020a8:	00 00 00 
  freerange(vstart, vend);
801020ab:	ff 75 0c             	pushl  0xc(%ebp)
801020ae:	ff 75 08             	pushl  0x8(%ebp)
801020b1:	e8 7d ff ff ff       	call   80102033 <freerange>
  kmem.use_lock = 1;
801020b6:	c7 05 94 26 13 80 01 	movl   $0x1,0x80132694
801020bd:	00 00 00 
}
801020c0:	83 c4 10             	add    $0x10,%esp
801020c3:	c9                   	leave  
801020c4:	c3                   	ret    

801020c5 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
801020c5:	55                   	push   %ebp
801020c6:	89 e5                	mov    %esp,%ebp
801020c8:	53                   	push   %ebx
801020c9:	83 ec 04             	sub    $0x4,%esp
  struct run *r;

  if(kmem.use_lock)
801020cc:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
801020d3:	75 33                	jne    80102108 <kalloc+0x43>
    acquire(&kmem.lock);
  r = kmem.freelist;
801020d5:	8b 1d 98 26 13 80    	mov    0x80132698,%ebx
  
  // V2P and shift, and mask off
  framenumber = (uint)(V2P(r) >> 12 & 0xffff);
801020db:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801020e1:	c1 e8 0c             	shr    $0xc,%eax
801020e4:	0f b7 c0             	movzwl %ax,%eax
801020e7:	a3 a0 26 13 80       	mov    %eax,0x801326a0

  if(r){
801020ec:	85 db                	test   %ebx,%ebx
801020ee:	74 08                	je     801020f8 <kalloc+0x33>
    kmem.freelist = r->next;
801020f0:	8b 13                	mov    (%ebx),%edx
801020f2:	89 15 98 26 13 80    	mov    %edx,0x80132698
  }

  if(kmem.use_lock) {    
801020f8:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
801020ff:	75 19                	jne    8010211a <kalloc+0x55>
    pids[index] = 1;
    index++;
    release(&kmem.lock);
  }
  return (char*)r;
}
80102101:	89 d8                	mov    %ebx,%eax
80102103:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102106:	c9                   	leave  
80102107:	c3                   	ret    
    acquire(&kmem.lock);
80102108:	83 ec 0c             	sub    $0xc,%esp
8010210b:	68 60 26 13 80       	push   $0x80132660
80102110:	e8 d6 1c 00 00       	call   80103deb <acquire>
80102115:	83 c4 10             	add    $0x10,%esp
80102118:	eb bb                	jmp    801020d5 <kalloc+0x10>
    frames[index] = framenumber;
8010211a:	8b 15 b8 a5 12 80    	mov    0x8012a5b8,%edx
80102120:	89 04 95 20 80 11 80 	mov    %eax,-0x7fee7fe0(,%edx,4)
    pids[index] = 1;
80102127:	c7 04 95 00 80 10 80 	movl   $0x1,-0x7fef8000(,%edx,4)
8010212e:	01 00 00 00 
    index++;
80102132:	83 c2 01             	add    $0x1,%edx
80102135:	89 15 b8 a5 12 80    	mov    %edx,0x8012a5b8
    release(&kmem.lock);
8010213b:	83 ec 0c             	sub    $0xc,%esp
8010213e:	68 60 26 13 80       	push   $0x80132660
80102143:	e8 08 1d 00 00       	call   80103e50 <release>
80102148:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
8010214b:	eb b4                	jmp    80102101 <kalloc+0x3c>

8010214d <kalloc2>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc2(uint pid)
{
8010214d:	55                   	push   %ebp
8010214e:	89 e5                	mov    %esp,%ebp
80102150:	57                   	push   %edi
80102151:	56                   	push   %esi
80102152:	53                   	push   %ebx
80102153:	83 ec 1c             	sub    $0x1c,%esp
  struct run *prev; // previous head of the freelist
  struct run *store_head; // stores current head of the freelist
  uint nextPid = -1;
  uint prevPid = -1;

  if(kmem.use_lock)
80102156:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
8010215d:	75 1d                	jne    8010217c <kalloc2+0x2f>
    acquire(&kmem.lock);
  r = kmem.freelist; // head which acts as a current pointer
8010215f:	8b 1d 98 26 13 80    	mov    0x80132698,%ebx
80102165:	89 5d dc             	mov    %ebx,-0x24(%ebp)


  store_head = r;
  prev = r;
80102168:	89 5d e0             	mov    %ebx,-0x20(%ebp)
  uint prevPid = -1;
8010216b:	be ff ff ff ff       	mov    $0xffffffff,%esi
  uint nextPid = -1;
80102170:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
  while(r){
80102177:	e9 b2 00 00 00       	jmp    8010222e <kalloc2+0xe1>
    acquire(&kmem.lock);
8010217c:	83 ec 0c             	sub    $0xc,%esp
8010217f:	68 60 26 13 80       	push   $0x80132660
80102184:	e8 62 1c 00 00       	call   80103deb <acquire>
80102189:	83 c4 10             	add    $0x10,%esp
8010218c:	eb d1                	jmp    8010215f <kalloc2+0x12>
      if (frames[i] == -1) {
        prevPid = -1;
        break;
      }
      if (frames[i] == framenumber - 1) {
        prevPid = pids[i];
8010218e:	8b 34 85 00 80 10 80 	mov    -0x7fef8000(,%eax,4),%esi
         // cprintf("PrevPIDINLOOP: %d %d\n", prevPid, i);
        break;
80102195:	eb 05                	jmp    8010219c <kalloc2+0x4f>
        prevPid = -1;
80102197:	be ff ff ff ff       	mov    $0xffffffff,%esi
      }
    }
    // looking at 1 frame after current to check for same process
    for(int j = 0; j < 16385; j++){
8010219c:	b8 00 00 00 00       	mov    $0x0,%eax
801021a1:	3d 00 40 00 00       	cmp    $0x4000,%eax
801021a6:	7f 2b                	jg     801021d3 <kalloc2+0x86>
      if (frames[j] == -1) {
801021a8:	8b 14 85 20 80 11 80 	mov    -0x7fee7fe0(,%eax,4),%edx
801021af:	83 fa ff             	cmp    $0xffffffff,%edx
801021b2:	74 18                	je     801021cc <kalloc2+0x7f>
        nextPid = -1;
        break;
      }
      if(frames[j] == framenumber + 1){
801021b4:	8d 79 01             	lea    0x1(%ecx),%edi
801021b7:	39 fa                	cmp    %edi,%edx
801021b9:	74 05                	je     801021c0 <kalloc2+0x73>
    for(int j = 0; j < 16385; j++){
801021bb:	83 c0 01             	add    $0x1,%eax
801021be:	eb e1                	jmp    801021a1 <kalloc2+0x54>
        nextPid = pids[j];
801021c0:	8b 04 85 00 80 10 80 	mov    -0x7fef8000(,%eax,4),%eax
801021c7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        break;
801021ca:	eb 07                	jmp    801021d3 <kalloc2+0x86>
        nextPid = -1;
801021cc:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)

    // cprintf("R:       %p\n", r);
    // cprintf("PrevPID: %d\n", prevPid);
    // cprintf("CurrPID: %d\n", pid);
    // cprintf("NextPID: %d\n", nextPid);
    if(((prevPid == pid || prevPid == -2) && (nextPid == pid || nextPid == -2)) // if both are not free
801021d3:	3b 75 08             	cmp    0x8(%ebp),%esi
801021d6:	0f 94 c2             	sete   %dl
801021d9:	83 fe fe             	cmp    $0xfffffffe,%esi
801021dc:	0f 94 c0             	sete   %al
801021df:	08 d0                	or     %dl,%al
801021e1:	74 17                	je     801021fa <kalloc2+0xad>
801021e3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
801021e6:	3b 7d 08             	cmp    0x8(%ebp),%edi
801021e9:	0f 94 c1             	sete   %cl
801021ec:	83 ff fe             	cmp    $0xfffffffe,%edi
801021ef:	0f 94 c2             	sete   %dl
801021f2:	08 d1                	or     %dl,%cl
801021f4:	0f 85 95 00 00 00    	jne    8010228f <kalloc2+0x142>
      || (prevPid == -1 && nextPid == -1) // if both are free
801021fa:	83 fe ff             	cmp    $0xffffffff,%esi
801021fd:	0f 94 c1             	sete   %cl
80102200:	83 7d e4 ff          	cmpl   $0xffffffff,-0x1c(%ebp)
80102204:	0f 94 c2             	sete   %dl
80102207:	84 d1                	test   %dl,%cl
80102209:	0f 85 80 00 00 00    	jne    8010228f <kalloc2+0x142>
      || ((pid == prevPid || prevPid == -2 || prevPid != -1) && (pid == -2 || pid == -1) && nextPid == -1) // if left is not free
8010220f:	84 c0                	test   %al,%al
80102211:	75 05                	jne    80102218 <kalloc2+0xcb>
80102213:	83 fe ff             	cmp    $0xffffffff,%esi
80102216:	74 06                	je     8010221e <kalloc2+0xd1>
80102218:	83 7d 08 fe          	cmpl   $0xfffffffe,0x8(%ebp)
8010221c:	73 56                	jae    80102274 <kalloc2+0x127>
      || ((prevPid == -1 && (pid == nextPid || nextPid == -2)))
8010221e:	83 fe ff             	cmp    $0xffffffff,%esi
80102221:	74 59                	je     8010227c <kalloc2+0x12f>
      || (pid == -2)) { // if right is not free
80102223:	83 7d 08 fe          	cmpl   $0xfffffffe,0x8(%ebp)
80102227:	74 66                	je     8010228f <kalloc2+0x142>
          prev->next = r->next;
          break;
        }
      }

      prev = r;
80102229:	89 5d e0             	mov    %ebx,-0x20(%ebp)
      r = r->next;  
8010222c:	8b 1b                	mov    (%ebx),%ebx
  while(r){
8010222e:	85 db                	test   %ebx,%ebx
80102230:	74 6a                	je     8010229c <kalloc2+0x14f>
    framenumber = (uint)(V2P(r) >> 12 & 0xffff);
80102232:	8d 8b 00 00 00 80    	lea    -0x80000000(%ebx),%ecx
80102238:	c1 e9 0c             	shr    $0xc,%ecx
8010223b:	0f b7 c9             	movzwl %cx,%ecx
8010223e:	89 0d a0 26 13 80    	mov    %ecx,0x801326a0
    for(int i = 0; i < 16385; i++){
80102244:	b8 00 00 00 00       	mov    $0x0,%eax
80102249:	3d 00 40 00 00       	cmp    $0x4000,%eax
8010224e:	0f 8f 48 ff ff ff    	jg     8010219c <kalloc2+0x4f>
      if (frames[i] == -1) {
80102254:	8b 14 85 20 80 11 80 	mov    -0x7fee7fe0(,%eax,4),%edx
8010225b:	83 fa ff             	cmp    $0xffffffff,%edx
8010225e:	0f 84 33 ff ff ff    	je     80102197 <kalloc2+0x4a>
      if (frames[i] == framenumber - 1) {
80102264:	8d 79 ff             	lea    -0x1(%ecx),%edi
80102267:	39 fa                	cmp    %edi,%edx
80102269:	0f 84 1f ff ff ff    	je     8010218e <kalloc2+0x41>
    for(int i = 0; i < 16385; i++){
8010226f:	83 c0 01             	add    $0x1,%eax
80102272:	eb d5                	jmp    80102249 <kalloc2+0xfc>
      || ((pid == prevPid || prevPid == -2 || prevPid != -1) && (pid == -2 || pid == -1) && nextPid == -1) // if left is not free
80102274:	83 7d e4 ff          	cmpl   $0xffffffff,-0x1c(%ebp)
80102278:	75 a4                	jne    8010221e <kalloc2+0xd1>
8010227a:	eb 13                	jmp    8010228f <kalloc2+0x142>
      || ((prevPid == -1 && (pid == nextPid || nextPid == -2)))
8010227c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010227f:	3b 45 08             	cmp    0x8(%ebp),%eax
80102282:	0f 94 c2             	sete   %dl
80102285:	83 f8 fe             	cmp    $0xfffffffe,%eax
80102288:	0f 94 c0             	sete   %al
8010228b:	08 c2                	or     %al,%dl
8010228d:	74 94                	je     80102223 <kalloc2+0xd6>
        if(store_head){
8010228f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
80102293:	74 23                	je     801022b8 <kalloc2+0x16b>
          kmem.freelist = r->next;
80102295:	8b 03                	mov    (%ebx),%eax
80102297:	a3 98 26 13 80       	mov    %eax,0x80132698
    }

  if (flag == 1){
8010229c:	83 3d b4 a5 12 80 01 	cmpl   $0x1,0x8012a5b4
801022a3:	74 1c                	je     801022c1 <kalloc2+0x174>
    frames[index] = framenumber;
    pids[index] = pid;
    index++;
  }

  if(kmem.use_lock) {
801022a5:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
801022ac:	75 39                	jne    801022e7 <kalloc2+0x19a>
    release(&kmem.lock);
  }
  // cprintf("RRRRRRR: %p\n", r);
  return (char*)r;
}
801022ae:	89 d8                	mov    %ebx,%eax
801022b0:	8d 65 f4             	lea    -0xc(%ebp),%esp
801022b3:	5b                   	pop    %ebx
801022b4:	5e                   	pop    %esi
801022b5:	5f                   	pop    %edi
801022b6:	5d                   	pop    %ebp
801022b7:	c3                   	ret    
          prev->next = r->next;
801022b8:	8b 03                	mov    (%ebx),%eax
801022ba:	8b 75 e0             	mov    -0x20(%ebp),%esi
801022bd:	89 06                	mov    %eax,(%esi)
          break;
801022bf:	eb db                	jmp    8010229c <kalloc2+0x14f>
    frames[index] = framenumber;
801022c1:	a1 b8 a5 12 80       	mov    0x8012a5b8,%eax
801022c6:	8b 15 a0 26 13 80    	mov    0x801326a0,%edx
801022cc:	89 14 85 20 80 11 80 	mov    %edx,-0x7fee7fe0(,%eax,4)
    pids[index] = pid;
801022d3:	8b 75 08             	mov    0x8(%ebp),%esi
801022d6:	89 34 85 00 80 10 80 	mov    %esi,-0x7fef8000(,%eax,4)
    index++;
801022dd:	83 c0 01             	add    $0x1,%eax
801022e0:	a3 b8 a5 12 80       	mov    %eax,0x8012a5b8
801022e5:	eb be                	jmp    801022a5 <kalloc2+0x158>
    release(&kmem.lock);
801022e7:	83 ec 0c             	sub    $0xc,%esp
801022ea:	68 60 26 13 80       	push   $0x80132660
801022ef:	e8 5c 1b 00 00       	call   80103e50 <release>
801022f4:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
801022f7:	eb b5                	jmp    801022ae <kalloc2+0x161>

801022f9 <dump_physmem>:

int
dump_physmem(int *frs, int *pds, int numframes)
{
801022f9:	55                   	push   %ebp
801022fa:	89 e5                	mov    %esp,%ebp
801022fc:	57                   	push   %edi
801022fd:	56                   	push   %esi
801022fe:	53                   	push   %ebx
801022ff:	8b 75 08             	mov    0x8(%ebp),%esi
80102302:	8b 7d 0c             	mov    0xc(%ebp),%edi
80102305:	8b 5d 10             	mov    0x10(%ebp),%ebx
  if(numframes <= 0 || frs == 0 || pds == 0)
80102308:	85 db                	test   %ebx,%ebx
8010230a:	0f 9e c2             	setle  %dl
8010230d:	85 f6                	test   %esi,%esi
8010230f:	0f 94 c0             	sete   %al
80102312:	08 c2                	or     %al,%dl
80102314:	75 37                	jne    8010234d <dump_physmem+0x54>
80102316:	85 ff                	test   %edi,%edi
80102318:	74 3a                	je     80102354 <dump_physmem+0x5b>
    return -1;
  for (int i = 0; i < numframes; i++) {
8010231a:	b8 00 00 00 00       	mov    $0x0,%eax
8010231f:	eb 1e                	jmp    8010233f <dump_physmem+0x46>
    frs[i] = frames[i];
80102321:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80102328:	8b 0c 85 20 80 11 80 	mov    -0x7fee7fe0(,%eax,4),%ecx
8010232f:	89 0c 16             	mov    %ecx,(%esi,%edx,1)
    pds[i] = pids[i];
80102332:	8b 0c 85 00 80 10 80 	mov    -0x7fef8000(,%eax,4),%ecx
80102339:	89 0c 17             	mov    %ecx,(%edi,%edx,1)
  for (int i = 0; i < numframes; i++) {
8010233c:	83 c0 01             	add    $0x1,%eax
8010233f:	39 d8                	cmp    %ebx,%eax
80102341:	7c de                	jl     80102321 <dump_physmem+0x28>
  }
  return 0;
80102343:	b8 00 00 00 00       	mov    $0x0,%eax
80102348:	5b                   	pop    %ebx
80102349:	5e                   	pop    %esi
8010234a:	5f                   	pop    %edi
8010234b:	5d                   	pop    %ebp
8010234c:	c3                   	ret    
    return -1;
8010234d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102352:	eb f4                	jmp    80102348 <dump_physmem+0x4f>
80102354:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102359:	eb ed                	jmp    80102348 <dump_physmem+0x4f>

8010235b <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
8010235b:	55                   	push   %ebp
8010235c:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010235e:	ba 64 00 00 00       	mov    $0x64,%edx
80102363:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
80102364:	a8 01                	test   $0x1,%al
80102366:	0f 84 b5 00 00 00    	je     80102421 <kbdgetc+0xc6>
8010236c:	ba 60 00 00 00       	mov    $0x60,%edx
80102371:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
80102372:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
80102375:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
8010237b:	74 5c                	je     801023d9 <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
8010237d:	84 c0                	test   %al,%al
8010237f:	78 66                	js     801023e7 <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
80102381:	8b 0d bc a5 12 80    	mov    0x8012a5bc,%ecx
80102387:	f6 c1 40             	test   $0x40,%cl
8010238a:	74 0f                	je     8010239b <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
8010238c:	83 c8 80             	or     $0xffffff80,%eax
8010238f:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
80102392:	83 e1 bf             	and    $0xffffffbf,%ecx
80102395:	89 0d bc a5 12 80    	mov    %ecx,0x8012a5bc
  }

  shift |= shiftcode[data];
8010239b:	0f b6 8a c0 6a 10 80 	movzbl -0x7fef9540(%edx),%ecx
801023a2:	0b 0d bc a5 12 80    	or     0x8012a5bc,%ecx
  shift ^= togglecode[data];
801023a8:	0f b6 82 c0 69 10 80 	movzbl -0x7fef9640(%edx),%eax
801023af:	31 c1                	xor    %eax,%ecx
801023b1:	89 0d bc a5 12 80    	mov    %ecx,0x8012a5bc
  c = charcode[shift & (CTL | SHIFT)][data];
801023b7:	89 c8                	mov    %ecx,%eax
801023b9:	83 e0 03             	and    $0x3,%eax
801023bc:	8b 04 85 a0 69 10 80 	mov    -0x7fef9660(,%eax,4),%eax
801023c3:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
801023c7:	f6 c1 08             	test   $0x8,%cl
801023ca:	74 19                	je     801023e5 <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
801023cc:	8d 50 9f             	lea    -0x61(%eax),%edx
801023cf:	83 fa 19             	cmp    $0x19,%edx
801023d2:	77 40                	ja     80102414 <kbdgetc+0xb9>
      c += 'A' - 'a';
801023d4:	83 e8 20             	sub    $0x20,%eax
801023d7:	eb 0c                	jmp    801023e5 <kbdgetc+0x8a>
    shift |= E0ESC;
801023d9:	83 0d bc a5 12 80 40 	orl    $0x40,0x8012a5bc
    return 0;
801023e0:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
801023e5:	5d                   	pop    %ebp
801023e6:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
801023e7:	8b 0d bc a5 12 80    	mov    0x8012a5bc,%ecx
801023ed:	f6 c1 40             	test   $0x40,%cl
801023f0:	75 05                	jne    801023f7 <kbdgetc+0x9c>
801023f2:	89 c2                	mov    %eax,%edx
801023f4:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
801023f7:	0f b6 82 c0 6a 10 80 	movzbl -0x7fef9540(%edx),%eax
801023fe:	83 c8 40             	or     $0x40,%eax
80102401:	0f b6 c0             	movzbl %al,%eax
80102404:	f7 d0                	not    %eax
80102406:	21 c8                	and    %ecx,%eax
80102408:	a3 bc a5 12 80       	mov    %eax,0x8012a5bc
    return 0;
8010240d:	b8 00 00 00 00       	mov    $0x0,%eax
80102412:	eb d1                	jmp    801023e5 <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
80102414:	8d 50 bf             	lea    -0x41(%eax),%edx
80102417:	83 fa 19             	cmp    $0x19,%edx
8010241a:	77 c9                	ja     801023e5 <kbdgetc+0x8a>
      c += 'a' - 'A';
8010241c:	83 c0 20             	add    $0x20,%eax
  return c;
8010241f:	eb c4                	jmp    801023e5 <kbdgetc+0x8a>
    return -1;
80102421:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102426:	eb bd                	jmp    801023e5 <kbdgetc+0x8a>

80102428 <kbdintr>:

void
kbdintr(void)
{
80102428:	55                   	push   %ebp
80102429:	89 e5                	mov    %esp,%ebp
8010242b:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
8010242e:	68 5b 23 10 80       	push   $0x8010235b
80102433:	e8 06 e3 ff ff       	call   8010073e <consoleintr>
}
80102438:	83 c4 10             	add    $0x10,%esp
8010243b:	c9                   	leave  
8010243c:	c3                   	ret    

8010243d <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
8010243d:	55                   	push   %ebp
8010243e:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102440:	8b 0d a4 26 13 80    	mov    0x801326a4,%ecx
80102446:	8d 04 81             	lea    (%ecx,%eax,4),%eax
80102449:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
8010244b:	a1 a4 26 13 80       	mov    0x801326a4,%eax
80102450:	8b 40 20             	mov    0x20(%eax),%eax
}
80102453:	5d                   	pop    %ebp
80102454:	c3                   	ret    

80102455 <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
80102455:	55                   	push   %ebp
80102456:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102458:	ba 70 00 00 00       	mov    $0x70,%edx
8010245d:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010245e:	ba 71 00 00 00       	mov    $0x71,%edx
80102463:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
80102464:	0f b6 c0             	movzbl %al,%eax
}
80102467:	5d                   	pop    %ebp
80102468:	c3                   	ret    

80102469 <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
80102469:	55                   	push   %ebp
8010246a:	89 e5                	mov    %esp,%ebp
8010246c:	53                   	push   %ebx
8010246d:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
8010246f:	b8 00 00 00 00       	mov    $0x0,%eax
80102474:	e8 dc ff ff ff       	call   80102455 <cmos_read>
80102479:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
8010247b:	b8 02 00 00 00       	mov    $0x2,%eax
80102480:	e8 d0 ff ff ff       	call   80102455 <cmos_read>
80102485:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
80102488:	b8 04 00 00 00       	mov    $0x4,%eax
8010248d:	e8 c3 ff ff ff       	call   80102455 <cmos_read>
80102492:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
80102495:	b8 07 00 00 00       	mov    $0x7,%eax
8010249a:	e8 b6 ff ff ff       	call   80102455 <cmos_read>
8010249f:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
801024a2:	b8 08 00 00 00       	mov    $0x8,%eax
801024a7:	e8 a9 ff ff ff       	call   80102455 <cmos_read>
801024ac:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
801024af:	b8 09 00 00 00       	mov    $0x9,%eax
801024b4:	e8 9c ff ff ff       	call   80102455 <cmos_read>
801024b9:	89 43 14             	mov    %eax,0x14(%ebx)
}
801024bc:	5b                   	pop    %ebx
801024bd:	5d                   	pop    %ebp
801024be:	c3                   	ret    

801024bf <lapicinit>:
  if(!lapic)
801024bf:	83 3d a4 26 13 80 00 	cmpl   $0x0,0x801326a4
801024c6:	0f 84 fb 00 00 00    	je     801025c7 <lapicinit+0x108>
{
801024cc:	55                   	push   %ebp
801024cd:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801024cf:	ba 3f 01 00 00       	mov    $0x13f,%edx
801024d4:	b8 3c 00 00 00       	mov    $0x3c,%eax
801024d9:	e8 5f ff ff ff       	call   8010243d <lapicw>
  lapicw(TDCR, X1);
801024de:	ba 0b 00 00 00       	mov    $0xb,%edx
801024e3:	b8 f8 00 00 00       	mov    $0xf8,%eax
801024e8:	e8 50 ff ff ff       	call   8010243d <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801024ed:	ba 20 00 02 00       	mov    $0x20020,%edx
801024f2:	b8 c8 00 00 00       	mov    $0xc8,%eax
801024f7:	e8 41 ff ff ff       	call   8010243d <lapicw>
  lapicw(TICR, 10000000);
801024fc:	ba 80 96 98 00       	mov    $0x989680,%edx
80102501:	b8 e0 00 00 00       	mov    $0xe0,%eax
80102506:	e8 32 ff ff ff       	call   8010243d <lapicw>
  lapicw(LINT0, MASKED);
8010250b:	ba 00 00 01 00       	mov    $0x10000,%edx
80102510:	b8 d4 00 00 00       	mov    $0xd4,%eax
80102515:	e8 23 ff ff ff       	call   8010243d <lapicw>
  lapicw(LINT1, MASKED);
8010251a:	ba 00 00 01 00       	mov    $0x10000,%edx
8010251f:	b8 d8 00 00 00       	mov    $0xd8,%eax
80102524:	e8 14 ff ff ff       	call   8010243d <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102529:	a1 a4 26 13 80       	mov    0x801326a4,%eax
8010252e:	8b 40 30             	mov    0x30(%eax),%eax
80102531:	c1 e8 10             	shr    $0x10,%eax
80102534:	3c 03                	cmp    $0x3,%al
80102536:	77 7b                	ja     801025b3 <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102538:	ba 33 00 00 00       	mov    $0x33,%edx
8010253d:	b8 dc 00 00 00       	mov    $0xdc,%eax
80102542:	e8 f6 fe ff ff       	call   8010243d <lapicw>
  lapicw(ESR, 0);
80102547:	ba 00 00 00 00       	mov    $0x0,%edx
8010254c:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102551:	e8 e7 fe ff ff       	call   8010243d <lapicw>
  lapicw(ESR, 0);
80102556:	ba 00 00 00 00       	mov    $0x0,%edx
8010255b:	b8 a0 00 00 00       	mov    $0xa0,%eax
80102560:	e8 d8 fe ff ff       	call   8010243d <lapicw>
  lapicw(EOI, 0);
80102565:	ba 00 00 00 00       	mov    $0x0,%edx
8010256a:	b8 2c 00 00 00       	mov    $0x2c,%eax
8010256f:	e8 c9 fe ff ff       	call   8010243d <lapicw>
  lapicw(ICRHI, 0);
80102574:	ba 00 00 00 00       	mov    $0x0,%edx
80102579:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010257e:	e8 ba fe ff ff       	call   8010243d <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102583:	ba 00 85 08 00       	mov    $0x88500,%edx
80102588:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010258d:	e8 ab fe ff ff       	call   8010243d <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102592:	a1 a4 26 13 80       	mov    0x801326a4,%eax
80102597:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
8010259d:	f6 c4 10             	test   $0x10,%ah
801025a0:	75 f0                	jne    80102592 <lapicinit+0xd3>
  lapicw(TPR, 0);
801025a2:	ba 00 00 00 00       	mov    $0x0,%edx
801025a7:	b8 20 00 00 00       	mov    $0x20,%eax
801025ac:	e8 8c fe ff ff       	call   8010243d <lapicw>
}
801025b1:	5d                   	pop    %ebp
801025b2:	c3                   	ret    
    lapicw(PCINT, MASKED);
801025b3:	ba 00 00 01 00       	mov    $0x10000,%edx
801025b8:	b8 d0 00 00 00       	mov    $0xd0,%eax
801025bd:	e8 7b fe ff ff       	call   8010243d <lapicw>
801025c2:	e9 71 ff ff ff       	jmp    80102538 <lapicinit+0x79>
801025c7:	f3 c3                	repz ret 

801025c9 <lapicid>:
{
801025c9:	55                   	push   %ebp
801025ca:	89 e5                	mov    %esp,%ebp
  if (!lapic)
801025cc:	a1 a4 26 13 80       	mov    0x801326a4,%eax
801025d1:	85 c0                	test   %eax,%eax
801025d3:	74 08                	je     801025dd <lapicid+0x14>
  return lapic[ID] >> 24;
801025d5:	8b 40 20             	mov    0x20(%eax),%eax
801025d8:	c1 e8 18             	shr    $0x18,%eax
}
801025db:	5d                   	pop    %ebp
801025dc:	c3                   	ret    
    return 0;
801025dd:	b8 00 00 00 00       	mov    $0x0,%eax
801025e2:	eb f7                	jmp    801025db <lapicid+0x12>

801025e4 <lapiceoi>:
  if(lapic)
801025e4:	83 3d a4 26 13 80 00 	cmpl   $0x0,0x801326a4
801025eb:	74 14                	je     80102601 <lapiceoi+0x1d>
{
801025ed:	55                   	push   %ebp
801025ee:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
801025f0:	ba 00 00 00 00       	mov    $0x0,%edx
801025f5:	b8 2c 00 00 00       	mov    $0x2c,%eax
801025fa:	e8 3e fe ff ff       	call   8010243d <lapicw>
}
801025ff:	5d                   	pop    %ebp
80102600:	c3                   	ret    
80102601:	f3 c3                	repz ret 

80102603 <microdelay>:
{
80102603:	55                   	push   %ebp
80102604:	89 e5                	mov    %esp,%ebp
}
80102606:	5d                   	pop    %ebp
80102607:	c3                   	ret    

80102608 <lapicstartap>:
{
80102608:	55                   	push   %ebp
80102609:	89 e5                	mov    %esp,%ebp
8010260b:	57                   	push   %edi
8010260c:	56                   	push   %esi
8010260d:	53                   	push   %ebx
8010260e:	8b 75 08             	mov    0x8(%ebp),%esi
80102611:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102614:	b8 0f 00 00 00       	mov    $0xf,%eax
80102619:	ba 70 00 00 00       	mov    $0x70,%edx
8010261e:	ee                   	out    %al,(%dx)
8010261f:	b8 0a 00 00 00       	mov    $0xa,%eax
80102624:	ba 71 00 00 00       	mov    $0x71,%edx
80102629:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
8010262a:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
80102631:	00 00 
  wrv[1] = addr >> 4;
80102633:	89 f8                	mov    %edi,%eax
80102635:	c1 e8 04             	shr    $0x4,%eax
80102638:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
8010263e:	c1 e6 18             	shl    $0x18,%esi
80102641:	89 f2                	mov    %esi,%edx
80102643:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102648:	e8 f0 fd ff ff       	call   8010243d <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
8010264d:	ba 00 c5 00 00       	mov    $0xc500,%edx
80102652:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102657:	e8 e1 fd ff ff       	call   8010243d <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
8010265c:	ba 00 85 00 00       	mov    $0x8500,%edx
80102661:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102666:	e8 d2 fd ff ff       	call   8010243d <lapicw>
  for(i = 0; i < 2; i++){
8010266b:	bb 00 00 00 00       	mov    $0x0,%ebx
80102670:	eb 21                	jmp    80102693 <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
80102672:	89 f2                	mov    %esi,%edx
80102674:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102679:	e8 bf fd ff ff       	call   8010243d <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
8010267e:	89 fa                	mov    %edi,%edx
80102680:	c1 ea 0c             	shr    $0xc,%edx
80102683:	80 ce 06             	or     $0x6,%dh
80102686:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010268b:	e8 ad fd ff ff       	call   8010243d <lapicw>
  for(i = 0; i < 2; i++){
80102690:	83 c3 01             	add    $0x1,%ebx
80102693:	83 fb 01             	cmp    $0x1,%ebx
80102696:	7e da                	jle    80102672 <lapicstartap+0x6a>
}
80102698:	5b                   	pop    %ebx
80102699:	5e                   	pop    %esi
8010269a:	5f                   	pop    %edi
8010269b:	5d                   	pop    %ebp
8010269c:	c3                   	ret    

8010269d <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
8010269d:	55                   	push   %ebp
8010269e:	89 e5                	mov    %esp,%ebp
801026a0:	57                   	push   %edi
801026a1:	56                   	push   %esi
801026a2:	53                   	push   %ebx
801026a3:	83 ec 3c             	sub    $0x3c,%esp
801026a6:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801026a9:	b8 0b 00 00 00       	mov    $0xb,%eax
801026ae:	e8 a2 fd ff ff       	call   80102455 <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
801026b3:	83 e0 04             	and    $0x4,%eax
801026b6:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
801026b8:	8d 45 d0             	lea    -0x30(%ebp),%eax
801026bb:	e8 a9 fd ff ff       	call   80102469 <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
801026c0:	b8 0a 00 00 00       	mov    $0xa,%eax
801026c5:	e8 8b fd ff ff       	call   80102455 <cmos_read>
801026ca:	a8 80                	test   $0x80,%al
801026cc:	75 ea                	jne    801026b8 <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
801026ce:	8d 5d b8             	lea    -0x48(%ebp),%ebx
801026d1:	89 d8                	mov    %ebx,%eax
801026d3:	e8 91 fd ff ff       	call   80102469 <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
801026d8:	83 ec 04             	sub    $0x4,%esp
801026db:	6a 18                	push   $0x18
801026dd:	53                   	push   %ebx
801026de:	8d 45 d0             	lea    -0x30(%ebp),%eax
801026e1:	50                   	push   %eax
801026e2:	e8 f6 17 00 00       	call   80103edd <memcmp>
801026e7:	83 c4 10             	add    $0x10,%esp
801026ea:	85 c0                	test   %eax,%eax
801026ec:	75 ca                	jne    801026b8 <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
801026ee:	85 ff                	test   %edi,%edi
801026f0:	0f 85 84 00 00 00    	jne    8010277a <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801026f6:	8b 55 d0             	mov    -0x30(%ebp),%edx
801026f9:	89 d0                	mov    %edx,%eax
801026fb:	c1 e8 04             	shr    $0x4,%eax
801026fe:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102701:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102704:	83 e2 0f             	and    $0xf,%edx
80102707:	01 d0                	add    %edx,%eax
80102709:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
8010270c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
8010270f:	89 d0                	mov    %edx,%eax
80102711:	c1 e8 04             	shr    $0x4,%eax
80102714:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102717:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010271a:	83 e2 0f             	and    $0xf,%edx
8010271d:	01 d0                	add    %edx,%eax
8010271f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
80102722:	8b 55 d8             	mov    -0x28(%ebp),%edx
80102725:	89 d0                	mov    %edx,%eax
80102727:	c1 e8 04             	shr    $0x4,%eax
8010272a:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010272d:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102730:	83 e2 0f             	and    $0xf,%edx
80102733:	01 d0                	add    %edx,%eax
80102735:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
80102738:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010273b:	89 d0                	mov    %edx,%eax
8010273d:	c1 e8 04             	shr    $0x4,%eax
80102740:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102743:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102746:	83 e2 0f             	and    $0xf,%edx
80102749:	01 d0                	add    %edx,%eax
8010274b:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
8010274e:	8b 55 e0             	mov    -0x20(%ebp),%edx
80102751:	89 d0                	mov    %edx,%eax
80102753:	c1 e8 04             	shr    $0x4,%eax
80102756:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102759:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010275c:	83 e2 0f             	and    $0xf,%edx
8010275f:	01 d0                	add    %edx,%eax
80102761:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
80102764:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80102767:	89 d0                	mov    %edx,%eax
80102769:	c1 e8 04             	shr    $0x4,%eax
8010276c:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010276f:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102772:	83 e2 0f             	and    $0xf,%edx
80102775:	01 d0                	add    %edx,%eax
80102777:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
8010277a:	8b 45 d0             	mov    -0x30(%ebp),%eax
8010277d:	89 06                	mov    %eax,(%esi)
8010277f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102782:	89 46 04             	mov    %eax,0x4(%esi)
80102785:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102788:	89 46 08             	mov    %eax,0x8(%esi)
8010278b:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010278e:	89 46 0c             	mov    %eax,0xc(%esi)
80102791:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102794:	89 46 10             	mov    %eax,0x10(%esi)
80102797:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010279a:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
8010279d:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
801027a4:	8d 65 f4             	lea    -0xc(%ebp),%esp
801027a7:	5b                   	pop    %ebx
801027a8:	5e                   	pop    %esi
801027a9:	5f                   	pop    %edi
801027aa:	5d                   	pop    %ebp
801027ab:	c3                   	ret    

801027ac <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
801027ac:	55                   	push   %ebp
801027ad:	89 e5                	mov    %esp,%ebp
801027af:	53                   	push   %ebx
801027b0:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
801027b3:	ff 35 f4 26 13 80    	pushl  0x801326f4
801027b9:	ff 35 04 27 13 80    	pushl  0x80132704
801027bf:	e8 a8 d9 ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
801027c4:	8b 58 5c             	mov    0x5c(%eax),%ebx
801027c7:	89 1d 08 27 13 80    	mov    %ebx,0x80132708
  for (i = 0; i < log.lh.n; i++) {
801027cd:	83 c4 10             	add    $0x10,%esp
801027d0:	ba 00 00 00 00       	mov    $0x0,%edx
801027d5:	eb 0e                	jmp    801027e5 <read_head+0x39>
    log.lh.block[i] = lh->block[i];
801027d7:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
801027db:	89 0c 95 0c 27 13 80 	mov    %ecx,-0x7fecd8f4(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
801027e2:	83 c2 01             	add    $0x1,%edx
801027e5:	39 d3                	cmp    %edx,%ebx
801027e7:	7f ee                	jg     801027d7 <read_head+0x2b>
  }
  brelse(buf);
801027e9:	83 ec 0c             	sub    $0xc,%esp
801027ec:	50                   	push   %eax
801027ed:	e8 e3 d9 ff ff       	call   801001d5 <brelse>
}
801027f2:	83 c4 10             	add    $0x10,%esp
801027f5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801027f8:	c9                   	leave  
801027f9:	c3                   	ret    

801027fa <install_trans>:
{
801027fa:	55                   	push   %ebp
801027fb:	89 e5                	mov    %esp,%ebp
801027fd:	57                   	push   %edi
801027fe:	56                   	push   %esi
801027ff:	53                   	push   %ebx
80102800:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
80102803:	bb 00 00 00 00       	mov    $0x0,%ebx
80102808:	eb 66                	jmp    80102870 <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
8010280a:	89 d8                	mov    %ebx,%eax
8010280c:	03 05 f4 26 13 80    	add    0x801326f4,%eax
80102812:	83 c0 01             	add    $0x1,%eax
80102815:	83 ec 08             	sub    $0x8,%esp
80102818:	50                   	push   %eax
80102819:	ff 35 04 27 13 80    	pushl  0x80132704
8010281f:	e8 48 d9 ff ff       	call   8010016c <bread>
80102824:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
80102826:	83 c4 08             	add    $0x8,%esp
80102829:	ff 34 9d 0c 27 13 80 	pushl  -0x7fecd8f4(,%ebx,4)
80102830:	ff 35 04 27 13 80    	pushl  0x80132704
80102836:	e8 31 d9 ff ff       	call   8010016c <bread>
8010283b:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
8010283d:	8d 57 5c             	lea    0x5c(%edi),%edx
80102840:	8d 40 5c             	lea    0x5c(%eax),%eax
80102843:	83 c4 0c             	add    $0xc,%esp
80102846:	68 00 02 00 00       	push   $0x200
8010284b:	52                   	push   %edx
8010284c:	50                   	push   %eax
8010284d:	e8 c0 16 00 00       	call   80103f12 <memmove>
    bwrite(dbuf);  // write dst to disk
80102852:	89 34 24             	mov    %esi,(%esp)
80102855:	e8 40 d9 ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
8010285a:	89 3c 24             	mov    %edi,(%esp)
8010285d:	e8 73 d9 ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
80102862:	89 34 24             	mov    %esi,(%esp)
80102865:	e8 6b d9 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
8010286a:	83 c3 01             	add    $0x1,%ebx
8010286d:	83 c4 10             	add    $0x10,%esp
80102870:	39 1d 08 27 13 80    	cmp    %ebx,0x80132708
80102876:	7f 92                	jg     8010280a <install_trans+0x10>
}
80102878:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010287b:	5b                   	pop    %ebx
8010287c:	5e                   	pop    %esi
8010287d:	5f                   	pop    %edi
8010287e:	5d                   	pop    %ebp
8010287f:	c3                   	ret    

80102880 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80102880:	55                   	push   %ebp
80102881:	89 e5                	mov    %esp,%ebp
80102883:	53                   	push   %ebx
80102884:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102887:	ff 35 f4 26 13 80    	pushl  0x801326f4
8010288d:	ff 35 04 27 13 80    	pushl  0x80132704
80102893:	e8 d4 d8 ff ff       	call   8010016c <bread>
80102898:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
8010289a:	8b 0d 08 27 13 80    	mov    0x80132708,%ecx
801028a0:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
801028a3:	83 c4 10             	add    $0x10,%esp
801028a6:	b8 00 00 00 00       	mov    $0x0,%eax
801028ab:	eb 0e                	jmp    801028bb <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
801028ad:	8b 14 85 0c 27 13 80 	mov    -0x7fecd8f4(,%eax,4),%edx
801028b4:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
801028b8:	83 c0 01             	add    $0x1,%eax
801028bb:	39 c1                	cmp    %eax,%ecx
801028bd:	7f ee                	jg     801028ad <write_head+0x2d>
  }
  bwrite(buf);
801028bf:	83 ec 0c             	sub    $0xc,%esp
801028c2:	53                   	push   %ebx
801028c3:	e8 d2 d8 ff ff       	call   8010019a <bwrite>
  brelse(buf);
801028c8:	89 1c 24             	mov    %ebx,(%esp)
801028cb:	e8 05 d9 ff ff       	call   801001d5 <brelse>
}
801028d0:	83 c4 10             	add    $0x10,%esp
801028d3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801028d6:	c9                   	leave  
801028d7:	c3                   	ret    

801028d8 <recover_from_log>:

static void
recover_from_log(void)
{
801028d8:	55                   	push   %ebp
801028d9:	89 e5                	mov    %esp,%ebp
801028db:	83 ec 08             	sub    $0x8,%esp
  read_head();
801028de:	e8 c9 fe ff ff       	call   801027ac <read_head>
  install_trans(); // if committed, copy from log to disk
801028e3:	e8 12 ff ff ff       	call   801027fa <install_trans>
  log.lh.n = 0;
801028e8:	c7 05 08 27 13 80 00 	movl   $0x0,0x80132708
801028ef:	00 00 00 
  write_head(); // clear the log
801028f2:	e8 89 ff ff ff       	call   80102880 <write_head>
}
801028f7:	c9                   	leave  
801028f8:	c3                   	ret    

801028f9 <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
801028f9:	55                   	push   %ebp
801028fa:	89 e5                	mov    %esp,%ebp
801028fc:	57                   	push   %edi
801028fd:	56                   	push   %esi
801028fe:	53                   	push   %ebx
801028ff:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80102902:	bb 00 00 00 00       	mov    $0x0,%ebx
80102907:	eb 66                	jmp    8010296f <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80102909:	89 d8                	mov    %ebx,%eax
8010290b:	03 05 f4 26 13 80    	add    0x801326f4,%eax
80102911:	83 c0 01             	add    $0x1,%eax
80102914:	83 ec 08             	sub    $0x8,%esp
80102917:	50                   	push   %eax
80102918:	ff 35 04 27 13 80    	pushl  0x80132704
8010291e:	e8 49 d8 ff ff       	call   8010016c <bread>
80102923:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
80102925:	83 c4 08             	add    $0x8,%esp
80102928:	ff 34 9d 0c 27 13 80 	pushl  -0x7fecd8f4(,%ebx,4)
8010292f:	ff 35 04 27 13 80    	pushl  0x80132704
80102935:	e8 32 d8 ff ff       	call   8010016c <bread>
8010293a:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
8010293c:	8d 50 5c             	lea    0x5c(%eax),%edx
8010293f:	8d 46 5c             	lea    0x5c(%esi),%eax
80102942:	83 c4 0c             	add    $0xc,%esp
80102945:	68 00 02 00 00       	push   $0x200
8010294a:	52                   	push   %edx
8010294b:	50                   	push   %eax
8010294c:	e8 c1 15 00 00       	call   80103f12 <memmove>
    bwrite(to);  // write the log
80102951:	89 34 24             	mov    %esi,(%esp)
80102954:	e8 41 d8 ff ff       	call   8010019a <bwrite>
    brelse(from);
80102959:	89 3c 24             	mov    %edi,(%esp)
8010295c:	e8 74 d8 ff ff       	call   801001d5 <brelse>
    brelse(to);
80102961:	89 34 24             	mov    %esi,(%esp)
80102964:	e8 6c d8 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102969:	83 c3 01             	add    $0x1,%ebx
8010296c:	83 c4 10             	add    $0x10,%esp
8010296f:	39 1d 08 27 13 80    	cmp    %ebx,0x80132708
80102975:	7f 92                	jg     80102909 <write_log+0x10>
  }
}
80102977:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010297a:	5b                   	pop    %ebx
8010297b:	5e                   	pop    %esi
8010297c:	5f                   	pop    %edi
8010297d:	5d                   	pop    %ebp
8010297e:	c3                   	ret    

8010297f <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
8010297f:	83 3d 08 27 13 80 00 	cmpl   $0x0,0x80132708
80102986:	7e 26                	jle    801029ae <commit+0x2f>
{
80102988:	55                   	push   %ebp
80102989:	89 e5                	mov    %esp,%ebp
8010298b:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
8010298e:	e8 66 ff ff ff       	call   801028f9 <write_log>
    write_head();    // Write header to disk -- the real commit
80102993:	e8 e8 fe ff ff       	call   80102880 <write_head>
    install_trans(); // Now install writes to home locations
80102998:	e8 5d fe ff ff       	call   801027fa <install_trans>
    log.lh.n = 0;
8010299d:	c7 05 08 27 13 80 00 	movl   $0x0,0x80132708
801029a4:	00 00 00 
    write_head();    // Erase the transaction from the log
801029a7:	e8 d4 fe ff ff       	call   80102880 <write_head>
  }
}
801029ac:	c9                   	leave  
801029ad:	c3                   	ret    
801029ae:	f3 c3                	repz ret 

801029b0 <initlog>:
{
801029b0:	55                   	push   %ebp
801029b1:	89 e5                	mov    %esp,%ebp
801029b3:	53                   	push   %ebx
801029b4:	83 ec 2c             	sub    $0x2c,%esp
801029b7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
801029ba:	68 c0 6b 10 80       	push   $0x80106bc0
801029bf:	68 c0 26 13 80       	push   $0x801326c0
801029c4:	e8 e6 12 00 00       	call   80103caf <initlock>
  readsb(dev, &sb);
801029c9:	83 c4 08             	add    $0x8,%esp
801029cc:	8d 45 dc             	lea    -0x24(%ebp),%eax
801029cf:	50                   	push   %eax
801029d0:	53                   	push   %ebx
801029d1:	e8 60 e8 ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
801029d6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801029d9:	a3 f4 26 13 80       	mov    %eax,0x801326f4
  log.size = sb.nlog;
801029de:	8b 45 e8             	mov    -0x18(%ebp),%eax
801029e1:	a3 f8 26 13 80       	mov    %eax,0x801326f8
  log.dev = dev;
801029e6:	89 1d 04 27 13 80    	mov    %ebx,0x80132704
  recover_from_log();
801029ec:	e8 e7 fe ff ff       	call   801028d8 <recover_from_log>
}
801029f1:	83 c4 10             	add    $0x10,%esp
801029f4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801029f7:	c9                   	leave  
801029f8:	c3                   	ret    

801029f9 <begin_op>:
{
801029f9:	55                   	push   %ebp
801029fa:	89 e5                	mov    %esp,%ebp
801029fc:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
801029ff:	68 c0 26 13 80       	push   $0x801326c0
80102a04:	e8 e2 13 00 00       	call   80103deb <acquire>
80102a09:	83 c4 10             	add    $0x10,%esp
80102a0c:	eb 15                	jmp    80102a23 <begin_op+0x2a>
      sleep(&log, &log.lock);
80102a0e:	83 ec 08             	sub    $0x8,%esp
80102a11:	68 c0 26 13 80       	push   $0x801326c0
80102a16:	68 c0 26 13 80       	push   $0x801326c0
80102a1b:	e8 d0 0e 00 00       	call   801038f0 <sleep>
80102a20:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
80102a23:	83 3d 00 27 13 80 00 	cmpl   $0x0,0x80132700
80102a2a:	75 e2                	jne    80102a0e <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80102a2c:	a1 fc 26 13 80       	mov    0x801326fc,%eax
80102a31:	83 c0 01             	add    $0x1,%eax
80102a34:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102a37:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
80102a3a:	03 15 08 27 13 80    	add    0x80132708,%edx
80102a40:	83 fa 1e             	cmp    $0x1e,%edx
80102a43:	7e 17                	jle    80102a5c <begin_op+0x63>
      sleep(&log, &log.lock);
80102a45:	83 ec 08             	sub    $0x8,%esp
80102a48:	68 c0 26 13 80       	push   $0x801326c0
80102a4d:	68 c0 26 13 80       	push   $0x801326c0
80102a52:	e8 99 0e 00 00       	call   801038f0 <sleep>
80102a57:	83 c4 10             	add    $0x10,%esp
80102a5a:	eb c7                	jmp    80102a23 <begin_op+0x2a>
      log.outstanding += 1;
80102a5c:	a3 fc 26 13 80       	mov    %eax,0x801326fc
      release(&log.lock);
80102a61:	83 ec 0c             	sub    $0xc,%esp
80102a64:	68 c0 26 13 80       	push   $0x801326c0
80102a69:	e8 e2 13 00 00       	call   80103e50 <release>
}
80102a6e:	83 c4 10             	add    $0x10,%esp
80102a71:	c9                   	leave  
80102a72:	c3                   	ret    

80102a73 <end_op>:
{
80102a73:	55                   	push   %ebp
80102a74:	89 e5                	mov    %esp,%ebp
80102a76:	53                   	push   %ebx
80102a77:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
80102a7a:	68 c0 26 13 80       	push   $0x801326c0
80102a7f:	e8 67 13 00 00       	call   80103deb <acquire>
  log.outstanding -= 1;
80102a84:	a1 fc 26 13 80       	mov    0x801326fc,%eax
80102a89:	83 e8 01             	sub    $0x1,%eax
80102a8c:	a3 fc 26 13 80       	mov    %eax,0x801326fc
  if(log.committing)
80102a91:	8b 1d 00 27 13 80    	mov    0x80132700,%ebx
80102a97:	83 c4 10             	add    $0x10,%esp
80102a9a:	85 db                	test   %ebx,%ebx
80102a9c:	75 2c                	jne    80102aca <end_op+0x57>
  if(log.outstanding == 0){
80102a9e:	85 c0                	test   %eax,%eax
80102aa0:	75 35                	jne    80102ad7 <end_op+0x64>
    log.committing = 1;
80102aa2:	c7 05 00 27 13 80 01 	movl   $0x1,0x80132700
80102aa9:	00 00 00 
    do_commit = 1;
80102aac:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
80102ab1:	83 ec 0c             	sub    $0xc,%esp
80102ab4:	68 c0 26 13 80       	push   $0x801326c0
80102ab9:	e8 92 13 00 00       	call   80103e50 <release>
  if(do_commit){
80102abe:	83 c4 10             	add    $0x10,%esp
80102ac1:	85 db                	test   %ebx,%ebx
80102ac3:	75 24                	jne    80102ae9 <end_op+0x76>
}
80102ac5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102ac8:	c9                   	leave  
80102ac9:	c3                   	ret    
    panic("log.committing");
80102aca:	83 ec 0c             	sub    $0xc,%esp
80102acd:	68 c4 6b 10 80       	push   $0x80106bc4
80102ad2:	e8 71 d8 ff ff       	call   80100348 <panic>
    wakeup(&log);
80102ad7:	83 ec 0c             	sub    $0xc,%esp
80102ada:	68 c0 26 13 80       	push   $0x801326c0
80102adf:	e8 71 0f 00 00       	call   80103a55 <wakeup>
80102ae4:	83 c4 10             	add    $0x10,%esp
80102ae7:	eb c8                	jmp    80102ab1 <end_op+0x3e>
    commit();
80102ae9:	e8 91 fe ff ff       	call   8010297f <commit>
    acquire(&log.lock);
80102aee:	83 ec 0c             	sub    $0xc,%esp
80102af1:	68 c0 26 13 80       	push   $0x801326c0
80102af6:	e8 f0 12 00 00       	call   80103deb <acquire>
    log.committing = 0;
80102afb:	c7 05 00 27 13 80 00 	movl   $0x0,0x80132700
80102b02:	00 00 00 
    wakeup(&log);
80102b05:	c7 04 24 c0 26 13 80 	movl   $0x801326c0,(%esp)
80102b0c:	e8 44 0f 00 00       	call   80103a55 <wakeup>
    release(&log.lock);
80102b11:	c7 04 24 c0 26 13 80 	movl   $0x801326c0,(%esp)
80102b18:	e8 33 13 00 00       	call   80103e50 <release>
80102b1d:	83 c4 10             	add    $0x10,%esp
}
80102b20:	eb a3                	jmp    80102ac5 <end_op+0x52>

80102b22 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80102b22:	55                   	push   %ebp
80102b23:	89 e5                	mov    %esp,%ebp
80102b25:	53                   	push   %ebx
80102b26:	83 ec 04             	sub    $0x4,%esp
80102b29:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80102b2c:	8b 15 08 27 13 80    	mov    0x80132708,%edx
80102b32:	83 fa 1d             	cmp    $0x1d,%edx
80102b35:	7f 45                	jg     80102b7c <log_write+0x5a>
80102b37:	a1 f8 26 13 80       	mov    0x801326f8,%eax
80102b3c:	83 e8 01             	sub    $0x1,%eax
80102b3f:	39 c2                	cmp    %eax,%edx
80102b41:	7d 39                	jge    80102b7c <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102b43:	83 3d fc 26 13 80 00 	cmpl   $0x0,0x801326fc
80102b4a:	7e 3d                	jle    80102b89 <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102b4c:	83 ec 0c             	sub    $0xc,%esp
80102b4f:	68 c0 26 13 80       	push   $0x801326c0
80102b54:	e8 92 12 00 00       	call   80103deb <acquire>
  for (i = 0; i < log.lh.n; i++) {
80102b59:	83 c4 10             	add    $0x10,%esp
80102b5c:	b8 00 00 00 00       	mov    $0x0,%eax
80102b61:	8b 15 08 27 13 80    	mov    0x80132708,%edx
80102b67:	39 c2                	cmp    %eax,%edx
80102b69:	7e 2b                	jle    80102b96 <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102b6b:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102b6e:	39 0c 85 0c 27 13 80 	cmp    %ecx,-0x7fecd8f4(,%eax,4)
80102b75:	74 1f                	je     80102b96 <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
80102b77:	83 c0 01             	add    $0x1,%eax
80102b7a:	eb e5                	jmp    80102b61 <log_write+0x3f>
    panic("too big a transaction");
80102b7c:	83 ec 0c             	sub    $0xc,%esp
80102b7f:	68 d3 6b 10 80       	push   $0x80106bd3
80102b84:	e8 bf d7 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102b89:	83 ec 0c             	sub    $0xc,%esp
80102b8c:	68 e9 6b 10 80       	push   $0x80106be9
80102b91:	e8 b2 d7 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102b96:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102b99:	89 0c 85 0c 27 13 80 	mov    %ecx,-0x7fecd8f4(,%eax,4)
  if (i == log.lh.n)
80102ba0:	39 c2                	cmp    %eax,%edx
80102ba2:	74 18                	je     80102bbc <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102ba4:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102ba7:	83 ec 0c             	sub    $0xc,%esp
80102baa:	68 c0 26 13 80       	push   $0x801326c0
80102baf:	e8 9c 12 00 00       	call   80103e50 <release>
}
80102bb4:	83 c4 10             	add    $0x10,%esp
80102bb7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102bba:	c9                   	leave  
80102bbb:	c3                   	ret    
    log.lh.n++;
80102bbc:	83 c2 01             	add    $0x1,%edx
80102bbf:	89 15 08 27 13 80    	mov    %edx,0x80132708
80102bc5:	eb dd                	jmp    80102ba4 <log_write+0x82>

80102bc7 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102bc7:	55                   	push   %ebp
80102bc8:	89 e5                	mov    %esp,%ebp
80102bca:	53                   	push   %ebx
80102bcb:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102bce:	68 8a 00 00 00       	push   $0x8a
80102bd3:	68 8c a4 12 80       	push   $0x8012a48c
80102bd8:	68 00 70 00 80       	push   $0x80007000
80102bdd:	e8 30 13 00 00       	call   80103f12 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102be2:	83 c4 10             	add    $0x10,%esp
80102be5:	bb c0 27 13 80       	mov    $0x801327c0,%ebx
80102bea:	eb 06                	jmp    80102bf2 <startothers+0x2b>
80102bec:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102bf2:	69 05 40 2d 13 80 b0 	imul   $0xb0,0x80132d40,%eax
80102bf9:	00 00 00 
80102bfc:	05 c0 27 13 80       	add    $0x801327c0,%eax
80102c01:	39 d8                	cmp    %ebx,%eax
80102c03:	76 4c                	jbe    80102c51 <startothers+0x8a>
    if(c == mycpu())  // We've started already.
80102c05:	e8 c8 07 00 00       	call   801033d2 <mycpu>
80102c0a:	39 d8                	cmp    %ebx,%eax
80102c0c:	74 de                	je     80102bec <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80102c0e:	e8 b2 f4 ff ff       	call   801020c5 <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102c13:	05 00 10 00 00       	add    $0x1000,%eax
80102c18:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102c1d:	c7 05 f8 6f 00 80 95 	movl   $0x80102c95,0x80006ff8
80102c24:	2c 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102c27:	c7 05 f4 6f 00 80 00 	movl   $0x129000,0x80006ff4
80102c2e:	90 12 00 

    lapicstartap(c->apicid, V2P(code));
80102c31:	83 ec 08             	sub    $0x8,%esp
80102c34:	68 00 70 00 00       	push   $0x7000
80102c39:	0f b6 03             	movzbl (%ebx),%eax
80102c3c:	50                   	push   %eax
80102c3d:	e8 c6 f9 ff ff       	call   80102608 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102c42:	83 c4 10             	add    $0x10,%esp
80102c45:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102c4b:	85 c0                	test   %eax,%eax
80102c4d:	74 f6                	je     80102c45 <startothers+0x7e>
80102c4f:	eb 9b                	jmp    80102bec <startothers+0x25>
      ;
  }
}
80102c51:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102c54:	c9                   	leave  
80102c55:	c3                   	ret    

80102c56 <mpmain>:
{
80102c56:	55                   	push   %ebp
80102c57:	89 e5                	mov    %esp,%ebp
80102c59:	53                   	push   %ebx
80102c5a:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102c5d:	e8 cc 07 00 00       	call   8010342e <cpuid>
80102c62:	89 c3                	mov    %eax,%ebx
80102c64:	e8 c5 07 00 00       	call   8010342e <cpuid>
80102c69:	83 ec 04             	sub    $0x4,%esp
80102c6c:	53                   	push   %ebx
80102c6d:	50                   	push   %eax
80102c6e:	68 04 6c 10 80       	push   $0x80106c04
80102c73:	e8 93 d9 ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102c78:	e8 ec 23 00 00       	call   80105069 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102c7d:	e8 50 07 00 00       	call   801033d2 <mycpu>
80102c82:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102c84:	b8 01 00 00 00       	mov    $0x1,%eax
80102c89:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102c90:	e8 36 0a 00 00       	call   801036cb <scheduler>

80102c95 <mpenter>:
{
80102c95:	55                   	push   %ebp
80102c96:	89 e5                	mov    %esp,%ebp
80102c98:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102c9b:	e8 da 33 00 00       	call   8010607a <switchkvm>
  seginit();
80102ca0:	e8 89 32 00 00       	call   80105f2e <seginit>
  lapicinit();
80102ca5:	e8 15 f8 ff ff       	call   801024bf <lapicinit>
  mpmain();
80102caa:	e8 a7 ff ff ff       	call   80102c56 <mpmain>

80102caf <main>:
{
80102caf:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102cb3:	83 e4 f0             	and    $0xfffffff0,%esp
80102cb6:	ff 71 fc             	pushl  -0x4(%ecx)
80102cb9:	55                   	push   %ebp
80102cba:	89 e5                	mov    %esp,%ebp
80102cbc:	51                   	push   %ecx
80102cbd:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102cc0:	68 00 00 40 80       	push   $0x80400000
80102cc5:	68 e8 54 13 80       	push   $0x801354e8
80102cca:	e8 9a f3 ff ff       	call   80102069 <kinit1>
  kvmalloc();      // kernel page table
80102ccf:	e8 4e 38 00 00       	call   80106522 <kvmalloc>
  mpinit();        // detect other processors
80102cd4:	e8 c9 01 00 00       	call   80102ea2 <mpinit>
  lapicinit();     // interrupt controller
80102cd9:	e8 e1 f7 ff ff       	call   801024bf <lapicinit>
  seginit();       // segment descriptors
80102cde:	e8 4b 32 00 00       	call   80105f2e <seginit>
  picinit();       // disable pic
80102ce3:	e8 82 02 00 00       	call   80102f6a <picinit>
  ioapicinit();    // another interrupt controller
80102ce8:	e8 0d f2 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102ced:	e8 9c db ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102cf2:	e8 20 26 00 00       	call   80105317 <uartinit>
  pinit();         // process table
80102cf7:	e8 bc 06 00 00       	call   801033b8 <pinit>
  tvinit();        // trap vectors
80102cfc:	e8 b7 22 00 00       	call   80104fb8 <tvinit>
  binit();         // buffer cache
80102d01:	e8 ee d3 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102d06:	e8 08 df ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102d0b:	e8 f0 ef ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102d10:	e8 b2 fe ff ff       	call   80102bc7 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102d15:	83 c4 08             	add    $0x8,%esp
80102d18:	68 00 00 00 8e       	push   $0x8e000000
80102d1d:	68 00 00 40 80       	push   $0x80400000
80102d22:	e8 74 f3 ff ff       	call   8010209b <kinit2>
  userinit();      // first user process
80102d27:	e8 41 07 00 00       	call   8010346d <userinit>
  mpmain();        // finish this processor's setup
80102d2c:	e8 25 ff ff ff       	call   80102c56 <mpmain>

80102d31 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102d31:	55                   	push   %ebp
80102d32:	89 e5                	mov    %esp,%ebp
80102d34:	56                   	push   %esi
80102d35:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102d36:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102d3b:	b9 00 00 00 00       	mov    $0x0,%ecx
80102d40:	eb 09                	jmp    80102d4b <sum+0x1a>
    sum += addr[i];
80102d42:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102d46:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102d48:	83 c1 01             	add    $0x1,%ecx
80102d4b:	39 d1                	cmp    %edx,%ecx
80102d4d:	7c f3                	jl     80102d42 <sum+0x11>
  return sum;
}
80102d4f:	89 d8                	mov    %ebx,%eax
80102d51:	5b                   	pop    %ebx
80102d52:	5e                   	pop    %esi
80102d53:	5d                   	pop    %ebp
80102d54:	c3                   	ret    

80102d55 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102d55:	55                   	push   %ebp
80102d56:	89 e5                	mov    %esp,%ebp
80102d58:	56                   	push   %esi
80102d59:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102d5a:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102d60:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102d62:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102d64:	eb 03                	jmp    80102d69 <mpsearch1+0x14>
80102d66:	83 c3 10             	add    $0x10,%ebx
80102d69:	39 f3                	cmp    %esi,%ebx
80102d6b:	73 29                	jae    80102d96 <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102d6d:	83 ec 04             	sub    $0x4,%esp
80102d70:	6a 04                	push   $0x4
80102d72:	68 18 6c 10 80       	push   $0x80106c18
80102d77:	53                   	push   %ebx
80102d78:	e8 60 11 00 00       	call   80103edd <memcmp>
80102d7d:	83 c4 10             	add    $0x10,%esp
80102d80:	85 c0                	test   %eax,%eax
80102d82:	75 e2                	jne    80102d66 <mpsearch1+0x11>
80102d84:	ba 10 00 00 00       	mov    $0x10,%edx
80102d89:	89 d8                	mov    %ebx,%eax
80102d8b:	e8 a1 ff ff ff       	call   80102d31 <sum>
80102d90:	84 c0                	test   %al,%al
80102d92:	75 d2                	jne    80102d66 <mpsearch1+0x11>
80102d94:	eb 05                	jmp    80102d9b <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102d96:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102d9b:	89 d8                	mov    %ebx,%eax
80102d9d:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102da0:	5b                   	pop    %ebx
80102da1:	5e                   	pop    %esi
80102da2:	5d                   	pop    %ebp
80102da3:	c3                   	ret    

80102da4 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102da4:	55                   	push   %ebp
80102da5:	89 e5                	mov    %esp,%ebp
80102da7:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102daa:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102db1:	c1 e0 08             	shl    $0x8,%eax
80102db4:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102dbb:	09 d0                	or     %edx,%eax
80102dbd:	c1 e0 04             	shl    $0x4,%eax
80102dc0:	85 c0                	test   %eax,%eax
80102dc2:	74 1f                	je     80102de3 <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102dc4:	ba 00 04 00 00       	mov    $0x400,%edx
80102dc9:	e8 87 ff ff ff       	call   80102d55 <mpsearch1>
80102dce:	85 c0                	test   %eax,%eax
80102dd0:	75 0f                	jne    80102de1 <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102dd2:	ba 00 00 01 00       	mov    $0x10000,%edx
80102dd7:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102ddc:	e8 74 ff ff ff       	call   80102d55 <mpsearch1>
}
80102de1:	c9                   	leave  
80102de2:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102de3:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102dea:	c1 e0 08             	shl    $0x8,%eax
80102ded:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102df4:	09 d0                	or     %edx,%eax
80102df6:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102df9:	2d 00 04 00 00       	sub    $0x400,%eax
80102dfe:	ba 00 04 00 00       	mov    $0x400,%edx
80102e03:	e8 4d ff ff ff       	call   80102d55 <mpsearch1>
80102e08:	85 c0                	test   %eax,%eax
80102e0a:	75 d5                	jne    80102de1 <mpsearch+0x3d>
80102e0c:	eb c4                	jmp    80102dd2 <mpsearch+0x2e>

80102e0e <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102e0e:	55                   	push   %ebp
80102e0f:	89 e5                	mov    %esp,%ebp
80102e11:	57                   	push   %edi
80102e12:	56                   	push   %esi
80102e13:	53                   	push   %ebx
80102e14:	83 ec 1c             	sub    $0x1c,%esp
80102e17:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102e1a:	e8 85 ff ff ff       	call   80102da4 <mpsearch>
80102e1f:	85 c0                	test   %eax,%eax
80102e21:	74 5c                	je     80102e7f <mpconfig+0x71>
80102e23:	89 c7                	mov    %eax,%edi
80102e25:	8b 58 04             	mov    0x4(%eax),%ebx
80102e28:	85 db                	test   %ebx,%ebx
80102e2a:	74 5a                	je     80102e86 <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102e2c:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102e32:	83 ec 04             	sub    $0x4,%esp
80102e35:	6a 04                	push   $0x4
80102e37:	68 1d 6c 10 80       	push   $0x80106c1d
80102e3c:	56                   	push   %esi
80102e3d:	e8 9b 10 00 00       	call   80103edd <memcmp>
80102e42:	83 c4 10             	add    $0x10,%esp
80102e45:	85 c0                	test   %eax,%eax
80102e47:	75 44                	jne    80102e8d <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102e49:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102e50:	3c 01                	cmp    $0x1,%al
80102e52:	0f 95 c2             	setne  %dl
80102e55:	3c 04                	cmp    $0x4,%al
80102e57:	0f 95 c0             	setne  %al
80102e5a:	84 c2                	test   %al,%dl
80102e5c:	75 36                	jne    80102e94 <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102e5e:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102e65:	89 f0                	mov    %esi,%eax
80102e67:	e8 c5 fe ff ff       	call   80102d31 <sum>
80102e6c:	84 c0                	test   %al,%al
80102e6e:	75 2b                	jne    80102e9b <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102e70:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102e73:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102e75:	89 f0                	mov    %esi,%eax
80102e77:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102e7a:	5b                   	pop    %ebx
80102e7b:	5e                   	pop    %esi
80102e7c:	5f                   	pop    %edi
80102e7d:	5d                   	pop    %ebp
80102e7e:	c3                   	ret    
    return 0;
80102e7f:	be 00 00 00 00       	mov    $0x0,%esi
80102e84:	eb ef                	jmp    80102e75 <mpconfig+0x67>
80102e86:	be 00 00 00 00       	mov    $0x0,%esi
80102e8b:	eb e8                	jmp    80102e75 <mpconfig+0x67>
    return 0;
80102e8d:	be 00 00 00 00       	mov    $0x0,%esi
80102e92:	eb e1                	jmp    80102e75 <mpconfig+0x67>
    return 0;
80102e94:	be 00 00 00 00       	mov    $0x0,%esi
80102e99:	eb da                	jmp    80102e75 <mpconfig+0x67>
    return 0;
80102e9b:	be 00 00 00 00       	mov    $0x0,%esi
80102ea0:	eb d3                	jmp    80102e75 <mpconfig+0x67>

80102ea2 <mpinit>:

void
mpinit(void)
{
80102ea2:	55                   	push   %ebp
80102ea3:	89 e5                	mov    %esp,%ebp
80102ea5:	57                   	push   %edi
80102ea6:	56                   	push   %esi
80102ea7:	53                   	push   %ebx
80102ea8:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102eab:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102eae:	e8 5b ff ff ff       	call   80102e0e <mpconfig>
80102eb3:	85 c0                	test   %eax,%eax
80102eb5:	74 19                	je     80102ed0 <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102eb7:	8b 50 24             	mov    0x24(%eax),%edx
80102eba:	89 15 a4 26 13 80    	mov    %edx,0x801326a4
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102ec0:	8d 50 2c             	lea    0x2c(%eax),%edx
80102ec3:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102ec7:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102ec9:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102ece:	eb 34                	jmp    80102f04 <mpinit+0x62>
    panic("Expect to run on an SMP");
80102ed0:	83 ec 0c             	sub    $0xc,%esp
80102ed3:	68 22 6c 10 80       	push   $0x80106c22
80102ed8:	e8 6b d4 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102edd:	8b 35 40 2d 13 80    	mov    0x80132d40,%esi
80102ee3:	83 fe 07             	cmp    $0x7,%esi
80102ee6:	7f 19                	jg     80102f01 <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102ee8:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102eec:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102ef2:	88 87 c0 27 13 80    	mov    %al,-0x7fecd840(%edi)
        ncpu++;
80102ef8:	83 c6 01             	add    $0x1,%esi
80102efb:	89 35 40 2d 13 80    	mov    %esi,0x80132d40
      }
      p += sizeof(struct mpproc);
80102f01:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102f04:	39 ca                	cmp    %ecx,%edx
80102f06:	73 2b                	jae    80102f33 <mpinit+0x91>
    switch(*p){
80102f08:	0f b6 02             	movzbl (%edx),%eax
80102f0b:	3c 04                	cmp    $0x4,%al
80102f0d:	77 1d                	ja     80102f2c <mpinit+0x8a>
80102f0f:	0f b6 c0             	movzbl %al,%eax
80102f12:	ff 24 85 5c 6c 10 80 	jmp    *-0x7fef93a4(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102f19:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102f1d:	a2 a0 27 13 80       	mov    %al,0x801327a0
      p += sizeof(struct mpioapic);
80102f22:	83 c2 08             	add    $0x8,%edx
      continue;
80102f25:	eb dd                	jmp    80102f04 <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102f27:	83 c2 08             	add    $0x8,%edx
      continue;
80102f2a:	eb d8                	jmp    80102f04 <mpinit+0x62>
    default:
      ismp = 0;
80102f2c:	bb 00 00 00 00       	mov    $0x0,%ebx
80102f31:	eb d1                	jmp    80102f04 <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102f33:	85 db                	test   %ebx,%ebx
80102f35:	74 26                	je     80102f5d <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102f37:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102f3a:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102f3e:	74 15                	je     80102f55 <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102f40:	b8 70 00 00 00       	mov    $0x70,%eax
80102f45:	ba 22 00 00 00       	mov    $0x22,%edx
80102f4a:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102f4b:	ba 23 00 00 00       	mov    $0x23,%edx
80102f50:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102f51:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102f54:	ee                   	out    %al,(%dx)
  }
}
80102f55:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102f58:	5b                   	pop    %ebx
80102f59:	5e                   	pop    %esi
80102f5a:	5f                   	pop    %edi
80102f5b:	5d                   	pop    %ebp
80102f5c:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102f5d:	83 ec 0c             	sub    $0xc,%esp
80102f60:	68 3c 6c 10 80       	push   $0x80106c3c
80102f65:	e8 de d3 ff ff       	call   80100348 <panic>

80102f6a <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80102f6a:	55                   	push   %ebp
80102f6b:	89 e5                	mov    %esp,%ebp
80102f6d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102f72:	ba 21 00 00 00       	mov    $0x21,%edx
80102f77:	ee                   	out    %al,(%dx)
80102f78:	ba a1 00 00 00       	mov    $0xa1,%edx
80102f7d:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102f7e:	5d                   	pop    %ebp
80102f7f:	c3                   	ret    

80102f80 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102f80:	55                   	push   %ebp
80102f81:	89 e5                	mov    %esp,%ebp
80102f83:	57                   	push   %edi
80102f84:	56                   	push   %esi
80102f85:	53                   	push   %ebx
80102f86:	83 ec 0c             	sub    $0xc,%esp
80102f89:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102f8c:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102f8f:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102f95:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102f9b:	e8 8d dc ff ff       	call   80100c2d <filealloc>
80102fa0:	89 03                	mov    %eax,(%ebx)
80102fa2:	85 c0                	test   %eax,%eax
80102fa4:	74 1e                	je     80102fc4 <pipealloc+0x44>
80102fa6:	e8 82 dc ff ff       	call   80100c2d <filealloc>
80102fab:	89 06                	mov    %eax,(%esi)
80102fad:	85 c0                	test   %eax,%eax
80102faf:	74 13                	je     80102fc4 <pipealloc+0x44>
    goto bad;
  if((p = (struct pipe*)kalloc2(-2)) == 0)
80102fb1:	83 ec 0c             	sub    $0xc,%esp
80102fb4:	6a fe                	push   $0xfffffffe
80102fb6:	e8 92 f1 ff ff       	call   8010214d <kalloc2>
80102fbb:	89 c7                	mov    %eax,%edi
80102fbd:	83 c4 10             	add    $0x10,%esp
80102fc0:	85 c0                	test   %eax,%eax
80102fc2:	75 35                	jne    80102ff9 <pipealloc+0x79>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102fc4:	8b 03                	mov    (%ebx),%eax
80102fc6:	85 c0                	test   %eax,%eax
80102fc8:	74 0c                	je     80102fd6 <pipealloc+0x56>
    fileclose(*f0);
80102fca:	83 ec 0c             	sub    $0xc,%esp
80102fcd:	50                   	push   %eax
80102fce:	e8 00 dd ff ff       	call   80100cd3 <fileclose>
80102fd3:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102fd6:	8b 06                	mov    (%esi),%eax
80102fd8:	85 c0                	test   %eax,%eax
80102fda:	0f 84 8b 00 00 00    	je     8010306b <pipealloc+0xeb>
    fileclose(*f1);
80102fe0:	83 ec 0c             	sub    $0xc,%esp
80102fe3:	50                   	push   %eax
80102fe4:	e8 ea dc ff ff       	call   80100cd3 <fileclose>
80102fe9:	83 c4 10             	add    $0x10,%esp
  return -1;
80102fec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102ff1:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102ff4:	5b                   	pop    %ebx
80102ff5:	5e                   	pop    %esi
80102ff6:	5f                   	pop    %edi
80102ff7:	5d                   	pop    %ebp
80102ff8:	c3                   	ret    
  p->readopen = 1;
80102ff9:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103000:	00 00 00 
  p->writeopen = 1;
80103003:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
8010300a:	00 00 00 
  p->nwrite = 0;
8010300d:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103014:	00 00 00 
  p->nread = 0;
80103017:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
8010301e:	00 00 00 
  initlock(&p->lock, "pipe");
80103021:	83 ec 08             	sub    $0x8,%esp
80103024:	68 70 6c 10 80       	push   $0x80106c70
80103029:	50                   	push   %eax
8010302a:	e8 80 0c 00 00       	call   80103caf <initlock>
  (*f0)->type = FD_PIPE;
8010302f:	8b 03                	mov    (%ebx),%eax
80103031:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103037:	8b 03                	mov    (%ebx),%eax
80103039:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
8010303d:	8b 03                	mov    (%ebx),%eax
8010303f:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103043:	8b 03                	mov    (%ebx),%eax
80103045:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103048:	8b 06                	mov    (%esi),%eax
8010304a:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80103050:	8b 06                	mov    (%esi),%eax
80103052:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103056:	8b 06                	mov    (%esi),%eax
80103058:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
8010305c:	8b 06                	mov    (%esi),%eax
8010305e:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80103061:	83 c4 10             	add    $0x10,%esp
80103064:	b8 00 00 00 00       	mov    $0x0,%eax
80103069:	eb 86                	jmp    80102ff1 <pipealloc+0x71>
  return -1;
8010306b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103070:	e9 7c ff ff ff       	jmp    80102ff1 <pipealloc+0x71>

80103075 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103075:	55                   	push   %ebp
80103076:	89 e5                	mov    %esp,%ebp
80103078:	53                   	push   %ebx
80103079:	83 ec 10             	sub    $0x10,%esp
8010307c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
8010307f:	53                   	push   %ebx
80103080:	e8 66 0d 00 00       	call   80103deb <acquire>
  if(writable){
80103085:	83 c4 10             	add    $0x10,%esp
80103088:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010308c:	74 3f                	je     801030cd <pipeclose+0x58>
    p->writeopen = 0;
8010308e:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80103095:	00 00 00 
    wakeup(&p->nread);
80103098:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
8010309e:	83 ec 0c             	sub    $0xc,%esp
801030a1:	50                   	push   %eax
801030a2:	e8 ae 09 00 00       	call   80103a55 <wakeup>
801030a7:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
801030aa:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
801030b1:	75 09                	jne    801030bc <pipeclose+0x47>
801030b3:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
801030ba:	74 2f                	je     801030eb <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
801030bc:	83 ec 0c             	sub    $0xc,%esp
801030bf:	53                   	push   %ebx
801030c0:	e8 8b 0d 00 00       	call   80103e50 <release>
801030c5:	83 c4 10             	add    $0x10,%esp
}
801030c8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801030cb:	c9                   	leave  
801030cc:	c3                   	ret    
    p->readopen = 0;
801030cd:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
801030d4:	00 00 00 
    wakeup(&p->nwrite);
801030d7:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
801030dd:	83 ec 0c             	sub    $0xc,%esp
801030e0:	50                   	push   %eax
801030e1:	e8 6f 09 00 00       	call   80103a55 <wakeup>
801030e6:	83 c4 10             	add    $0x10,%esp
801030e9:	eb bf                	jmp    801030aa <pipeclose+0x35>
    release(&p->lock);
801030eb:	83 ec 0c             	sub    $0xc,%esp
801030ee:	53                   	push   %ebx
801030ef:	e8 5c 0d 00 00       	call   80103e50 <release>
    kfree((char*)p);
801030f4:	89 1c 24             	mov    %ebx,(%esp)
801030f7:	e8 a8 ee ff ff       	call   80101fa4 <kfree>
801030fc:	83 c4 10             	add    $0x10,%esp
801030ff:	eb c7                	jmp    801030c8 <pipeclose+0x53>

80103101 <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
80103101:	55                   	push   %ebp
80103102:	89 e5                	mov    %esp,%ebp
80103104:	57                   	push   %edi
80103105:	56                   	push   %esi
80103106:	53                   	push   %ebx
80103107:	83 ec 18             	sub    $0x18,%esp
8010310a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
8010310d:	89 de                	mov    %ebx,%esi
8010310f:	53                   	push   %ebx
80103110:	e8 d6 0c 00 00       	call   80103deb <acquire>
  for(i = 0; i < n; i++){
80103115:	83 c4 10             	add    $0x10,%esp
80103118:	bf 00 00 00 00       	mov    $0x0,%edi
8010311d:	3b 7d 10             	cmp    0x10(%ebp),%edi
80103120:	0f 8d 88 00 00 00    	jge    801031ae <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80103126:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
8010312c:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103132:	05 00 02 00 00       	add    $0x200,%eax
80103137:	39 c2                	cmp    %eax,%edx
80103139:	75 51                	jne    8010318c <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
8010313b:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80103142:	74 2f                	je     80103173 <pipewrite+0x72>
80103144:	e8 00 03 00 00       	call   80103449 <myproc>
80103149:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010314d:	75 24                	jne    80103173 <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
8010314f:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103155:	83 ec 0c             	sub    $0xc,%esp
80103158:	50                   	push   %eax
80103159:	e8 f7 08 00 00       	call   80103a55 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
8010315e:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103164:	83 c4 08             	add    $0x8,%esp
80103167:	56                   	push   %esi
80103168:	50                   	push   %eax
80103169:	e8 82 07 00 00       	call   801038f0 <sleep>
8010316e:	83 c4 10             	add    $0x10,%esp
80103171:	eb b3                	jmp    80103126 <pipewrite+0x25>
        release(&p->lock);
80103173:	83 ec 0c             	sub    $0xc,%esp
80103176:	53                   	push   %ebx
80103177:	e8 d4 0c 00 00       	call   80103e50 <release>
        return -1;
8010317c:	83 c4 10             	add    $0x10,%esp
8010317f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
80103184:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103187:	5b                   	pop    %ebx
80103188:	5e                   	pop    %esi
80103189:	5f                   	pop    %edi
8010318a:	5d                   	pop    %ebp
8010318b:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
8010318c:	8d 42 01             	lea    0x1(%edx),%eax
8010318f:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80103195:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
8010319b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010319e:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
801031a2:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
801031a6:	83 c7 01             	add    $0x1,%edi
801031a9:	e9 6f ff ff ff       	jmp    8010311d <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
801031ae:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801031b4:	83 ec 0c             	sub    $0xc,%esp
801031b7:	50                   	push   %eax
801031b8:	e8 98 08 00 00       	call   80103a55 <wakeup>
  release(&p->lock);
801031bd:	89 1c 24             	mov    %ebx,(%esp)
801031c0:	e8 8b 0c 00 00       	call   80103e50 <release>
  return n;
801031c5:	83 c4 10             	add    $0x10,%esp
801031c8:	8b 45 10             	mov    0x10(%ebp),%eax
801031cb:	eb b7                	jmp    80103184 <pipewrite+0x83>

801031cd <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801031cd:	55                   	push   %ebp
801031ce:	89 e5                	mov    %esp,%ebp
801031d0:	57                   	push   %edi
801031d1:	56                   	push   %esi
801031d2:	53                   	push   %ebx
801031d3:	83 ec 18             	sub    $0x18,%esp
801031d6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
801031d9:	89 df                	mov    %ebx,%edi
801031db:	53                   	push   %ebx
801031dc:	e8 0a 0c 00 00       	call   80103deb <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801031e1:	83 c4 10             	add    $0x10,%esp
801031e4:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
801031ea:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
801031f0:	75 3d                	jne    8010322f <piperead+0x62>
801031f2:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
801031f8:	85 f6                	test   %esi,%esi
801031fa:	74 38                	je     80103234 <piperead+0x67>
    if(myproc()->killed){
801031fc:	e8 48 02 00 00       	call   80103449 <myproc>
80103201:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80103205:	75 15                	jne    8010321c <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80103207:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
8010320d:	83 ec 08             	sub    $0x8,%esp
80103210:	57                   	push   %edi
80103211:	50                   	push   %eax
80103212:	e8 d9 06 00 00       	call   801038f0 <sleep>
80103217:	83 c4 10             	add    $0x10,%esp
8010321a:	eb c8                	jmp    801031e4 <piperead+0x17>
      release(&p->lock);
8010321c:	83 ec 0c             	sub    $0xc,%esp
8010321f:	53                   	push   %ebx
80103220:	e8 2b 0c 00 00       	call   80103e50 <release>
      return -1;
80103225:	83 c4 10             	add    $0x10,%esp
80103228:	be ff ff ff ff       	mov    $0xffffffff,%esi
8010322d:	eb 50                	jmp    8010327f <piperead+0xb2>
8010322f:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103234:	3b 75 10             	cmp    0x10(%ebp),%esi
80103237:	7d 2c                	jge    80103265 <piperead+0x98>
    if(p->nread == p->nwrite)
80103239:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
8010323f:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
80103245:	74 1e                	je     80103265 <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80103247:	8d 50 01             	lea    0x1(%eax),%edx
8010324a:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
80103250:	25 ff 01 00 00       	and    $0x1ff,%eax
80103255:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
8010325a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010325d:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103260:	83 c6 01             	add    $0x1,%esi
80103263:	eb cf                	jmp    80103234 <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80103265:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
8010326b:	83 ec 0c             	sub    $0xc,%esp
8010326e:	50                   	push   %eax
8010326f:	e8 e1 07 00 00       	call   80103a55 <wakeup>
  release(&p->lock);
80103274:	89 1c 24             	mov    %ebx,(%esp)
80103277:	e8 d4 0b 00 00       	call   80103e50 <release>
  return i;
8010327c:	83 c4 10             	add    $0x10,%esp
}
8010327f:	89 f0                	mov    %esi,%eax
80103281:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103284:	5b                   	pop    %ebx
80103285:	5e                   	pop    %esi
80103286:	5f                   	pop    %edi
80103287:	5d                   	pop    %ebp
80103288:	c3                   	ret    

80103289 <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80103289:	55                   	push   %ebp
8010328a:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010328c:	ba 94 2d 13 80       	mov    $0x80132d94,%edx
80103291:	eb 03                	jmp    80103296 <wakeup1+0xd>
80103293:	83 c2 7c             	add    $0x7c,%edx
80103296:	81 fa 94 4c 13 80    	cmp    $0x80134c94,%edx
8010329c:	73 14                	jae    801032b2 <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
8010329e:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
801032a2:	75 ef                	jne    80103293 <wakeup1+0xa>
801032a4:	39 42 20             	cmp    %eax,0x20(%edx)
801032a7:	75 ea                	jne    80103293 <wakeup1+0xa>
      p->state = RUNNABLE;
801032a9:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
801032b0:	eb e1                	jmp    80103293 <wakeup1+0xa>
}
801032b2:	5d                   	pop    %ebp
801032b3:	c3                   	ret    

801032b4 <allocproc>:
{
801032b4:	55                   	push   %ebp
801032b5:	89 e5                	mov    %esp,%ebp
801032b7:	53                   	push   %ebx
801032b8:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
801032bb:	68 60 2d 13 80       	push   $0x80132d60
801032c0:	e8 26 0b 00 00       	call   80103deb <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801032c5:	83 c4 10             	add    $0x10,%esp
801032c8:	bb 94 2d 13 80       	mov    $0x80132d94,%ebx
801032cd:	81 fb 94 4c 13 80    	cmp    $0x80134c94,%ebx
801032d3:	73 0b                	jae    801032e0 <allocproc+0x2c>
    if(p->state == UNUSED)
801032d5:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
801032d9:	74 1c                	je     801032f7 <allocproc+0x43>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801032db:	83 c3 7c             	add    $0x7c,%ebx
801032de:	eb ed                	jmp    801032cd <allocproc+0x19>
  release(&ptable.lock);
801032e0:	83 ec 0c             	sub    $0xc,%esp
801032e3:	68 60 2d 13 80       	push   $0x80132d60
801032e8:	e8 63 0b 00 00       	call   80103e50 <release>
  return 0;
801032ed:	83 c4 10             	add    $0x10,%esp
801032f0:	bb 00 00 00 00       	mov    $0x0,%ebx
801032f5:	eb 69                	jmp    80103360 <allocproc+0xac>
  p->state = EMBRYO;
801032f7:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
801032fe:	a1 04 a0 12 80       	mov    0x8012a004,%eax
80103303:	8d 50 01             	lea    0x1(%eax),%edx
80103306:	89 15 04 a0 12 80    	mov    %edx,0x8012a004
8010330c:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
8010330f:	83 ec 0c             	sub    $0xc,%esp
80103312:	68 60 2d 13 80       	push   $0x80132d60
80103317:	e8 34 0b 00 00       	call   80103e50 <release>
  if((p->kstack = kalloc()) == 0){
8010331c:	e8 a4 ed ff ff       	call   801020c5 <kalloc>
80103321:	89 43 08             	mov    %eax,0x8(%ebx)
80103324:	83 c4 10             	add    $0x10,%esp
80103327:	85 c0                	test   %eax,%eax
80103329:	74 3c                	je     80103367 <allocproc+0xb3>
  sp -= sizeof *p->tf;
8010332b:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
80103331:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
80103334:	c7 80 b0 0f 00 00 ad 	movl   $0x80104fad,0xfb0(%eax)
8010333b:	4f 10 80 
  sp -= sizeof *p->context;
8010333e:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
80103343:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
80103346:	83 ec 04             	sub    $0x4,%esp
80103349:	6a 14                	push   $0x14
8010334b:	6a 00                	push   $0x0
8010334d:	50                   	push   %eax
8010334e:	e8 44 0b 00 00       	call   80103e97 <memset>
  p->context->eip = (uint)forkret;
80103353:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103356:	c7 40 10 75 33 10 80 	movl   $0x80103375,0x10(%eax)
  return p;
8010335d:	83 c4 10             	add    $0x10,%esp
}
80103360:	89 d8                	mov    %ebx,%eax
80103362:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103365:	c9                   	leave  
80103366:	c3                   	ret    
    p->state = UNUSED;
80103367:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
8010336e:	bb 00 00 00 00       	mov    $0x0,%ebx
80103373:	eb eb                	jmp    80103360 <allocproc+0xac>

80103375 <forkret>:
{
80103375:	55                   	push   %ebp
80103376:	89 e5                	mov    %esp,%ebp
80103378:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
8010337b:	68 60 2d 13 80       	push   $0x80132d60
80103380:	e8 cb 0a 00 00       	call   80103e50 <release>
  if (first) {
80103385:	83 c4 10             	add    $0x10,%esp
80103388:	83 3d 00 a0 12 80 00 	cmpl   $0x0,0x8012a000
8010338f:	75 02                	jne    80103393 <forkret+0x1e>
}
80103391:	c9                   	leave  
80103392:	c3                   	ret    
    first = 0;
80103393:	c7 05 00 a0 12 80 00 	movl   $0x0,0x8012a000
8010339a:	00 00 00 
    iinit(ROOTDEV);
8010339d:	83 ec 0c             	sub    $0xc,%esp
801033a0:	6a 01                	push   $0x1
801033a2:	e8 45 df ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
801033a7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801033ae:	e8 fd f5 ff ff       	call   801029b0 <initlog>
801033b3:	83 c4 10             	add    $0x10,%esp
}
801033b6:	eb d9                	jmp    80103391 <forkret+0x1c>

801033b8 <pinit>:
{
801033b8:	55                   	push   %ebp
801033b9:	89 e5                	mov    %esp,%ebp
801033bb:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
801033be:	68 75 6c 10 80       	push   $0x80106c75
801033c3:	68 60 2d 13 80       	push   $0x80132d60
801033c8:	e8 e2 08 00 00       	call   80103caf <initlock>
}
801033cd:	83 c4 10             	add    $0x10,%esp
801033d0:	c9                   	leave  
801033d1:	c3                   	ret    

801033d2 <mycpu>:
{
801033d2:	55                   	push   %ebp
801033d3:	89 e5                	mov    %esp,%ebp
801033d5:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801033d8:	9c                   	pushf  
801033d9:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801033da:	f6 c4 02             	test   $0x2,%ah
801033dd:	75 28                	jne    80103407 <mycpu+0x35>
  apicid = lapicid();
801033df:	e8 e5 f1 ff ff       	call   801025c9 <lapicid>
  for (i = 0; i < ncpu; ++i) {
801033e4:	ba 00 00 00 00       	mov    $0x0,%edx
801033e9:	39 15 40 2d 13 80    	cmp    %edx,0x80132d40
801033ef:	7e 23                	jle    80103414 <mycpu+0x42>
    if (cpus[i].apicid == apicid)
801033f1:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
801033f7:	0f b6 89 c0 27 13 80 	movzbl -0x7fecd840(%ecx),%ecx
801033fe:	39 c1                	cmp    %eax,%ecx
80103400:	74 1f                	je     80103421 <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
80103402:	83 c2 01             	add    $0x1,%edx
80103405:	eb e2                	jmp    801033e9 <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
80103407:	83 ec 0c             	sub    $0xc,%esp
8010340a:	68 58 6d 10 80       	push   $0x80106d58
8010340f:	e8 34 cf ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
80103414:	83 ec 0c             	sub    $0xc,%esp
80103417:	68 7c 6c 10 80       	push   $0x80106c7c
8010341c:	e8 27 cf ff ff       	call   80100348 <panic>
      return &cpus[i];
80103421:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
80103427:	05 c0 27 13 80       	add    $0x801327c0,%eax
}
8010342c:	c9                   	leave  
8010342d:	c3                   	ret    

8010342e <cpuid>:
cpuid() {
8010342e:	55                   	push   %ebp
8010342f:	89 e5                	mov    %esp,%ebp
80103431:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
80103434:	e8 99 ff ff ff       	call   801033d2 <mycpu>
80103439:	2d c0 27 13 80       	sub    $0x801327c0,%eax
8010343e:	c1 f8 04             	sar    $0x4,%eax
80103441:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
80103447:	c9                   	leave  
80103448:	c3                   	ret    

80103449 <myproc>:
myproc(void) {
80103449:	55                   	push   %ebp
8010344a:	89 e5                	mov    %esp,%ebp
8010344c:	53                   	push   %ebx
8010344d:	83 ec 04             	sub    $0x4,%esp
  pushcli();
80103450:	e8 b9 08 00 00       	call   80103d0e <pushcli>
  c = mycpu();
80103455:	e8 78 ff ff ff       	call   801033d2 <mycpu>
  p = c->proc;
8010345a:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103460:	e8 e6 08 00 00       	call   80103d4b <popcli>
}
80103465:	89 d8                	mov    %ebx,%eax
80103467:	83 c4 04             	add    $0x4,%esp
8010346a:	5b                   	pop    %ebx
8010346b:	5d                   	pop    %ebp
8010346c:	c3                   	ret    

8010346d <userinit>:
{
8010346d:	55                   	push   %ebp
8010346e:	89 e5                	mov    %esp,%ebp
80103470:	53                   	push   %ebx
80103471:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
80103474:	e8 3b fe ff ff       	call   801032b4 <allocproc>
80103479:	89 c3                	mov    %eax,%ebx
  initproc = p;
8010347b:	a3 c0 a5 12 80       	mov    %eax,0x8012a5c0
  if((p->pgdir = setupkvm()) == 0)
80103480:	e8 27 30 00 00       	call   801064ac <setupkvm>
80103485:	89 43 04             	mov    %eax,0x4(%ebx)
80103488:	85 c0                	test   %eax,%eax
8010348a:	0f 84 b7 00 00 00    	je     80103547 <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80103490:	83 ec 04             	sub    $0x4,%esp
80103493:	68 2c 00 00 00       	push   $0x2c
80103498:	68 60 a4 12 80       	push   $0x8012a460
8010349d:	50                   	push   %eax
8010349e:	e8 01 2d 00 00       	call   801061a4 <inituvm>
  p->sz = PGSIZE;
801034a3:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
801034a9:	83 c4 0c             	add    $0xc,%esp
801034ac:	6a 4c                	push   $0x4c
801034ae:	6a 00                	push   $0x0
801034b0:	ff 73 18             	pushl  0x18(%ebx)
801034b3:	e8 df 09 00 00       	call   80103e97 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801034b8:	8b 43 18             	mov    0x18(%ebx),%eax
801034bb:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801034c1:	8b 43 18             	mov    0x18(%ebx),%eax
801034c4:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
801034ca:	8b 43 18             	mov    0x18(%ebx),%eax
801034cd:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801034d1:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801034d5:	8b 43 18             	mov    0x18(%ebx),%eax
801034d8:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801034dc:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801034e0:	8b 43 18             	mov    0x18(%ebx),%eax
801034e3:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801034ea:	8b 43 18             	mov    0x18(%ebx),%eax
801034ed:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801034f4:	8b 43 18             	mov    0x18(%ebx),%eax
801034f7:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
801034fe:	8d 43 6c             	lea    0x6c(%ebx),%eax
80103501:	83 c4 0c             	add    $0xc,%esp
80103504:	6a 10                	push   $0x10
80103506:	68 a5 6c 10 80       	push   $0x80106ca5
8010350b:	50                   	push   %eax
8010350c:	e8 ed 0a 00 00       	call   80103ffe <safestrcpy>
  p->cwd = namei("/");
80103511:	c7 04 24 ae 6c 10 80 	movl   $0x80106cae,(%esp)
80103518:	e8 c4 e6 ff ff       	call   80101be1 <namei>
8010351d:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
80103520:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
80103527:	e8 bf 08 00 00       	call   80103deb <acquire>
  p->state = RUNNABLE;
8010352c:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
80103533:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
8010353a:	e8 11 09 00 00       	call   80103e50 <release>
}
8010353f:	83 c4 10             	add    $0x10,%esp
80103542:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103545:	c9                   	leave  
80103546:	c3                   	ret    
    panic("userinit: out of memory?");
80103547:	83 ec 0c             	sub    $0xc,%esp
8010354a:	68 8c 6c 10 80       	push   $0x80106c8c
8010354f:	e8 f4 cd ff ff       	call   80100348 <panic>

80103554 <growproc>:
{
80103554:	55                   	push   %ebp
80103555:	89 e5                	mov    %esp,%ebp
80103557:	56                   	push   %esi
80103558:	53                   	push   %ebx
80103559:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
8010355c:	e8 e8 fe ff ff       	call   80103449 <myproc>
80103561:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
80103563:	8b 00                	mov    (%eax),%eax
  if(n > 0){
80103565:	85 f6                	test   %esi,%esi
80103567:	7f 21                	jg     8010358a <growproc+0x36>
  } else if(n < 0){
80103569:	85 f6                	test   %esi,%esi
8010356b:	79 33                	jns    801035a0 <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
8010356d:	83 ec 04             	sub    $0x4,%esp
80103570:	01 c6                	add    %eax,%esi
80103572:	56                   	push   %esi
80103573:	50                   	push   %eax
80103574:	ff 73 04             	pushl  0x4(%ebx)
80103577:	e8 36 2d 00 00       	call   801062b2 <deallocuvm>
8010357c:	83 c4 10             	add    $0x10,%esp
8010357f:	85 c0                	test   %eax,%eax
80103581:	75 1d                	jne    801035a0 <growproc+0x4c>
      return -1;
80103583:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103588:	eb 29                	jmp    801035b3 <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
8010358a:	83 ec 04             	sub    $0x4,%esp
8010358d:	01 c6                	add    %eax,%esi
8010358f:	56                   	push   %esi
80103590:	50                   	push   %eax
80103591:	ff 73 04             	pushl  0x4(%ebx)
80103594:	e8 ab 2d 00 00       	call   80106344 <allocuvm>
80103599:	83 c4 10             	add    $0x10,%esp
8010359c:	85 c0                	test   %eax,%eax
8010359e:	74 1a                	je     801035ba <growproc+0x66>
  curproc->sz = sz;
801035a0:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
801035a2:	83 ec 0c             	sub    $0xc,%esp
801035a5:	53                   	push   %ebx
801035a6:	e8 e1 2a 00 00       	call   8010608c <switchuvm>
  return 0;
801035ab:	83 c4 10             	add    $0x10,%esp
801035ae:	b8 00 00 00 00       	mov    $0x0,%eax
}
801035b3:	8d 65 f8             	lea    -0x8(%ebp),%esp
801035b6:	5b                   	pop    %ebx
801035b7:	5e                   	pop    %esi
801035b8:	5d                   	pop    %ebp
801035b9:	c3                   	ret    
      return -1;
801035ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801035bf:	eb f2                	jmp    801035b3 <growproc+0x5f>

801035c1 <fork>:
{
801035c1:	55                   	push   %ebp
801035c2:	89 e5                	mov    %esp,%ebp
801035c4:	57                   	push   %edi
801035c5:	56                   	push   %esi
801035c6:	53                   	push   %ebx
801035c7:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
801035ca:	e8 7a fe ff ff       	call   80103449 <myproc>
801035cf:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
801035d1:	e8 de fc ff ff       	call   801032b4 <allocproc>
801035d6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801035d9:	85 c0                	test   %eax,%eax
801035db:	0f 84 e3 00 00 00    	je     801036c4 <fork+0x103>
801035e1:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz, np->pid)) == 0){
801035e3:	83 ec 04             	sub    $0x4,%esp
801035e6:	ff 70 10             	pushl  0x10(%eax)
801035e9:	ff 33                	pushl  (%ebx)
801035eb:	ff 73 04             	pushl  0x4(%ebx)
801035ee:	e8 72 2f 00 00       	call   80106565 <copyuvm>
801035f3:	89 47 04             	mov    %eax,0x4(%edi)
801035f6:	83 c4 10             	add    $0x10,%esp
801035f9:	85 c0                	test   %eax,%eax
801035fb:	74 2a                	je     80103627 <fork+0x66>
  np->sz = curproc->sz;
801035fd:	8b 03                	mov    (%ebx),%eax
801035ff:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80103602:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
80103604:	89 c8                	mov    %ecx,%eax
80103606:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
80103609:	8b 73 18             	mov    0x18(%ebx),%esi
8010360c:	8b 79 18             	mov    0x18(%ecx),%edi
8010360f:	b9 13 00 00 00       	mov    $0x13,%ecx
80103614:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
80103616:	8b 40 18             	mov    0x18(%eax),%eax
80103619:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
80103620:	be 00 00 00 00       	mov    $0x0,%esi
80103625:	eb 29                	jmp    80103650 <fork+0x8f>
    kfree(np->kstack);
80103627:	83 ec 0c             	sub    $0xc,%esp
8010362a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
8010362d:	ff 73 08             	pushl  0x8(%ebx)
80103630:	e8 6f e9 ff ff       	call   80101fa4 <kfree>
    np->kstack = 0;
80103635:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
8010363c:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
80103643:	83 c4 10             	add    $0x10,%esp
80103646:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010364b:	eb 6d                	jmp    801036ba <fork+0xf9>
  for(i = 0; i < NOFILE; i++)
8010364d:	83 c6 01             	add    $0x1,%esi
80103650:	83 fe 0f             	cmp    $0xf,%esi
80103653:	7f 1d                	jg     80103672 <fork+0xb1>
    if(curproc->ofile[i])
80103655:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
80103659:	85 c0                	test   %eax,%eax
8010365b:	74 f0                	je     8010364d <fork+0x8c>
      np->ofile[i] = filedup(curproc->ofile[i]);
8010365d:	83 ec 0c             	sub    $0xc,%esp
80103660:	50                   	push   %eax
80103661:	e8 28 d6 ff ff       	call   80100c8e <filedup>
80103666:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103669:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
8010366d:	83 c4 10             	add    $0x10,%esp
80103670:	eb db                	jmp    8010364d <fork+0x8c>
  np->cwd = idup(curproc->cwd);
80103672:	83 ec 0c             	sub    $0xc,%esp
80103675:	ff 73 68             	pushl  0x68(%ebx)
80103678:	e8 d4 de ff ff       	call   80101551 <idup>
8010367d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103680:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103683:	83 c3 6c             	add    $0x6c,%ebx
80103686:	8d 47 6c             	lea    0x6c(%edi),%eax
80103689:	83 c4 0c             	add    $0xc,%esp
8010368c:	6a 10                	push   $0x10
8010368e:	53                   	push   %ebx
8010368f:	50                   	push   %eax
80103690:	e8 69 09 00 00       	call   80103ffe <safestrcpy>
  pid = np->pid;
80103695:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
80103698:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
8010369f:	e8 47 07 00 00       	call   80103deb <acquire>
  np->state = RUNNABLE;
801036a4:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
801036ab:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
801036b2:	e8 99 07 00 00       	call   80103e50 <release>
  return pid;
801036b7:	83 c4 10             	add    $0x10,%esp
}
801036ba:	89 d8                	mov    %ebx,%eax
801036bc:	8d 65 f4             	lea    -0xc(%ebp),%esp
801036bf:	5b                   	pop    %ebx
801036c0:	5e                   	pop    %esi
801036c1:	5f                   	pop    %edi
801036c2:	5d                   	pop    %ebp
801036c3:	c3                   	ret    
    return -1;
801036c4:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801036c9:	eb ef                	jmp    801036ba <fork+0xf9>

801036cb <scheduler>:
{
801036cb:	55                   	push   %ebp
801036cc:	89 e5                	mov    %esp,%ebp
801036ce:	56                   	push   %esi
801036cf:	53                   	push   %ebx
  struct cpu *c = mycpu();
801036d0:	e8 fd fc ff ff       	call   801033d2 <mycpu>
801036d5:	89 c6                	mov    %eax,%esi
  c->proc = 0;
801036d7:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
801036de:	00 00 00 
801036e1:	eb 5a                	jmp    8010373d <scheduler+0x72>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801036e3:	83 c3 7c             	add    $0x7c,%ebx
801036e6:	81 fb 94 4c 13 80    	cmp    $0x80134c94,%ebx
801036ec:	73 3f                	jae    8010372d <scheduler+0x62>
      if(p->state != RUNNABLE)
801036ee:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
801036f2:	75 ef                	jne    801036e3 <scheduler+0x18>
      c->proc = p;
801036f4:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
801036fa:	83 ec 0c             	sub    $0xc,%esp
801036fd:	53                   	push   %ebx
801036fe:	e8 89 29 00 00       	call   8010608c <switchuvm>
      p->state = RUNNING;
80103703:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
8010370a:	83 c4 08             	add    $0x8,%esp
8010370d:	ff 73 1c             	pushl  0x1c(%ebx)
80103710:	8d 46 04             	lea    0x4(%esi),%eax
80103713:	50                   	push   %eax
80103714:	e8 38 09 00 00       	call   80104051 <swtch>
      switchkvm();
80103719:	e8 5c 29 00 00       	call   8010607a <switchkvm>
      c->proc = 0;
8010371e:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
80103725:	00 00 00 
80103728:	83 c4 10             	add    $0x10,%esp
8010372b:	eb b6                	jmp    801036e3 <scheduler+0x18>
    release(&ptable.lock);
8010372d:	83 ec 0c             	sub    $0xc,%esp
80103730:	68 60 2d 13 80       	push   $0x80132d60
80103735:	e8 16 07 00 00       	call   80103e50 <release>
    sti();
8010373a:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
8010373d:	fb                   	sti    
    acquire(&ptable.lock);
8010373e:	83 ec 0c             	sub    $0xc,%esp
80103741:	68 60 2d 13 80       	push   $0x80132d60
80103746:	e8 a0 06 00 00       	call   80103deb <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010374b:	83 c4 10             	add    $0x10,%esp
8010374e:	bb 94 2d 13 80       	mov    $0x80132d94,%ebx
80103753:	eb 91                	jmp    801036e6 <scheduler+0x1b>

80103755 <sched>:
{
80103755:	55                   	push   %ebp
80103756:	89 e5                	mov    %esp,%ebp
80103758:	56                   	push   %esi
80103759:	53                   	push   %ebx
  struct proc *p = myproc();
8010375a:	e8 ea fc ff ff       	call   80103449 <myproc>
8010375f:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
80103761:	83 ec 0c             	sub    $0xc,%esp
80103764:	68 60 2d 13 80       	push   $0x80132d60
80103769:	e8 3d 06 00 00       	call   80103dab <holding>
8010376e:	83 c4 10             	add    $0x10,%esp
80103771:	85 c0                	test   %eax,%eax
80103773:	74 4f                	je     801037c4 <sched+0x6f>
  if(mycpu()->ncli != 1)
80103775:	e8 58 fc ff ff       	call   801033d2 <mycpu>
8010377a:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
80103781:	75 4e                	jne    801037d1 <sched+0x7c>
  if(p->state == RUNNING)
80103783:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
80103787:	74 55                	je     801037de <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103789:	9c                   	pushf  
8010378a:	58                   	pop    %eax
  if(readeflags()&FL_IF)
8010378b:	f6 c4 02             	test   $0x2,%ah
8010378e:	75 5b                	jne    801037eb <sched+0x96>
  intena = mycpu()->intena;
80103790:	e8 3d fc ff ff       	call   801033d2 <mycpu>
80103795:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
8010379b:	e8 32 fc ff ff       	call   801033d2 <mycpu>
801037a0:	83 ec 08             	sub    $0x8,%esp
801037a3:	ff 70 04             	pushl  0x4(%eax)
801037a6:	83 c3 1c             	add    $0x1c,%ebx
801037a9:	53                   	push   %ebx
801037aa:	e8 a2 08 00 00       	call   80104051 <swtch>
  mycpu()->intena = intena;
801037af:	e8 1e fc ff ff       	call   801033d2 <mycpu>
801037b4:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
801037ba:	83 c4 10             	add    $0x10,%esp
801037bd:	8d 65 f8             	lea    -0x8(%ebp),%esp
801037c0:	5b                   	pop    %ebx
801037c1:	5e                   	pop    %esi
801037c2:	5d                   	pop    %ebp
801037c3:	c3                   	ret    
    panic("sched ptable.lock");
801037c4:	83 ec 0c             	sub    $0xc,%esp
801037c7:	68 b0 6c 10 80       	push   $0x80106cb0
801037cc:	e8 77 cb ff ff       	call   80100348 <panic>
    panic("sched locks");
801037d1:	83 ec 0c             	sub    $0xc,%esp
801037d4:	68 c2 6c 10 80       	push   $0x80106cc2
801037d9:	e8 6a cb ff ff       	call   80100348 <panic>
    panic("sched running");
801037de:	83 ec 0c             	sub    $0xc,%esp
801037e1:	68 ce 6c 10 80       	push   $0x80106cce
801037e6:	e8 5d cb ff ff       	call   80100348 <panic>
    panic("sched interruptible");
801037eb:	83 ec 0c             	sub    $0xc,%esp
801037ee:	68 dc 6c 10 80       	push   $0x80106cdc
801037f3:	e8 50 cb ff ff       	call   80100348 <panic>

801037f8 <exit>:
{
801037f8:	55                   	push   %ebp
801037f9:	89 e5                	mov    %esp,%ebp
801037fb:	56                   	push   %esi
801037fc:	53                   	push   %ebx
  struct proc *curproc = myproc();
801037fd:	e8 47 fc ff ff       	call   80103449 <myproc>
  if(curproc == initproc)
80103802:	39 05 c0 a5 12 80    	cmp    %eax,0x8012a5c0
80103808:	74 09                	je     80103813 <exit+0x1b>
8010380a:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
8010380c:	bb 00 00 00 00       	mov    $0x0,%ebx
80103811:	eb 10                	jmp    80103823 <exit+0x2b>
    panic("init exiting");
80103813:	83 ec 0c             	sub    $0xc,%esp
80103816:	68 f0 6c 10 80       	push   $0x80106cf0
8010381b:	e8 28 cb ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
80103820:	83 c3 01             	add    $0x1,%ebx
80103823:	83 fb 0f             	cmp    $0xf,%ebx
80103826:	7f 1e                	jg     80103846 <exit+0x4e>
    if(curproc->ofile[fd]){
80103828:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
8010382c:	85 c0                	test   %eax,%eax
8010382e:	74 f0                	je     80103820 <exit+0x28>
      fileclose(curproc->ofile[fd]);
80103830:	83 ec 0c             	sub    $0xc,%esp
80103833:	50                   	push   %eax
80103834:	e8 9a d4 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
80103839:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
80103840:	00 
80103841:	83 c4 10             	add    $0x10,%esp
80103844:	eb da                	jmp    80103820 <exit+0x28>
  begin_op();
80103846:	e8 ae f1 ff ff       	call   801029f9 <begin_op>
  iput(curproc->cwd);
8010384b:	83 ec 0c             	sub    $0xc,%esp
8010384e:	ff 76 68             	pushl  0x68(%esi)
80103851:	e8 32 de ff ff       	call   80101688 <iput>
  end_op();
80103856:	e8 18 f2 ff ff       	call   80102a73 <end_op>
  curproc->cwd = 0;
8010385b:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
80103862:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
80103869:	e8 7d 05 00 00       	call   80103deb <acquire>
  wakeup1(curproc->parent);
8010386e:	8b 46 14             	mov    0x14(%esi),%eax
80103871:	e8 13 fa ff ff       	call   80103289 <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103876:	83 c4 10             	add    $0x10,%esp
80103879:	bb 94 2d 13 80       	mov    $0x80132d94,%ebx
8010387e:	eb 03                	jmp    80103883 <exit+0x8b>
80103880:	83 c3 7c             	add    $0x7c,%ebx
80103883:	81 fb 94 4c 13 80    	cmp    $0x80134c94,%ebx
80103889:	73 1a                	jae    801038a5 <exit+0xad>
    if(p->parent == curproc){
8010388b:	39 73 14             	cmp    %esi,0x14(%ebx)
8010388e:	75 f0                	jne    80103880 <exit+0x88>
      p->parent = initproc;
80103890:	a1 c0 a5 12 80       	mov    0x8012a5c0,%eax
80103895:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
80103898:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
8010389c:	75 e2                	jne    80103880 <exit+0x88>
        wakeup1(initproc);
8010389e:	e8 e6 f9 ff ff       	call   80103289 <wakeup1>
801038a3:	eb db                	jmp    80103880 <exit+0x88>
  curproc->state = ZOMBIE;
801038a5:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
801038ac:	e8 a4 fe ff ff       	call   80103755 <sched>
  panic("zombie exit");
801038b1:	83 ec 0c             	sub    $0xc,%esp
801038b4:	68 fd 6c 10 80       	push   $0x80106cfd
801038b9:	e8 8a ca ff ff       	call   80100348 <panic>

801038be <yield>:
{
801038be:	55                   	push   %ebp
801038bf:	89 e5                	mov    %esp,%ebp
801038c1:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801038c4:	68 60 2d 13 80       	push   $0x80132d60
801038c9:	e8 1d 05 00 00       	call   80103deb <acquire>
  myproc()->state = RUNNABLE;
801038ce:	e8 76 fb ff ff       	call   80103449 <myproc>
801038d3:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801038da:	e8 76 fe ff ff       	call   80103755 <sched>
  release(&ptable.lock);
801038df:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
801038e6:	e8 65 05 00 00       	call   80103e50 <release>
}
801038eb:	83 c4 10             	add    $0x10,%esp
801038ee:	c9                   	leave  
801038ef:	c3                   	ret    

801038f0 <sleep>:
{
801038f0:	55                   	push   %ebp
801038f1:	89 e5                	mov    %esp,%ebp
801038f3:	56                   	push   %esi
801038f4:	53                   	push   %ebx
801038f5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
801038f8:	e8 4c fb ff ff       	call   80103449 <myproc>
  if(p == 0)
801038fd:	85 c0                	test   %eax,%eax
801038ff:	74 66                	je     80103967 <sleep+0x77>
80103901:	89 c6                	mov    %eax,%esi
  if(lk == 0)
80103903:	85 db                	test   %ebx,%ebx
80103905:	74 6d                	je     80103974 <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
80103907:	81 fb 60 2d 13 80    	cmp    $0x80132d60,%ebx
8010390d:	74 18                	je     80103927 <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
8010390f:	83 ec 0c             	sub    $0xc,%esp
80103912:	68 60 2d 13 80       	push   $0x80132d60
80103917:	e8 cf 04 00 00       	call   80103deb <acquire>
    release(lk);
8010391c:	89 1c 24             	mov    %ebx,(%esp)
8010391f:	e8 2c 05 00 00       	call   80103e50 <release>
80103924:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
80103927:	8b 45 08             	mov    0x8(%ebp),%eax
8010392a:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
8010392d:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
80103934:	e8 1c fe ff ff       	call   80103755 <sched>
  p->chan = 0;
80103939:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
80103940:	81 fb 60 2d 13 80    	cmp    $0x80132d60,%ebx
80103946:	74 18                	je     80103960 <sleep+0x70>
    release(&ptable.lock);
80103948:	83 ec 0c             	sub    $0xc,%esp
8010394b:	68 60 2d 13 80       	push   $0x80132d60
80103950:	e8 fb 04 00 00       	call   80103e50 <release>
    acquire(lk);
80103955:	89 1c 24             	mov    %ebx,(%esp)
80103958:	e8 8e 04 00 00       	call   80103deb <acquire>
8010395d:	83 c4 10             	add    $0x10,%esp
}
80103960:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103963:	5b                   	pop    %ebx
80103964:	5e                   	pop    %esi
80103965:	5d                   	pop    %ebp
80103966:	c3                   	ret    
    panic("sleep");
80103967:	83 ec 0c             	sub    $0xc,%esp
8010396a:	68 09 6d 10 80       	push   $0x80106d09
8010396f:	e8 d4 c9 ff ff       	call   80100348 <panic>
    panic("sleep without lk");
80103974:	83 ec 0c             	sub    $0xc,%esp
80103977:	68 0f 6d 10 80       	push   $0x80106d0f
8010397c:	e8 c7 c9 ff ff       	call   80100348 <panic>

80103981 <wait>:
{
80103981:	55                   	push   %ebp
80103982:	89 e5                	mov    %esp,%ebp
80103984:	56                   	push   %esi
80103985:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103986:	e8 be fa ff ff       	call   80103449 <myproc>
8010398b:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
8010398d:	83 ec 0c             	sub    $0xc,%esp
80103990:	68 60 2d 13 80       	push   $0x80132d60
80103995:	e8 51 04 00 00       	call   80103deb <acquire>
8010399a:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
8010399d:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039a2:	bb 94 2d 13 80       	mov    $0x80132d94,%ebx
801039a7:	eb 5b                	jmp    80103a04 <wait+0x83>
        pid = p->pid;
801039a9:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
801039ac:	83 ec 0c             	sub    $0xc,%esp
801039af:	ff 73 08             	pushl  0x8(%ebx)
801039b2:	e8 ed e5 ff ff       	call   80101fa4 <kfree>
        p->kstack = 0;
801039b7:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
801039be:	83 c4 04             	add    $0x4,%esp
801039c1:	ff 73 04             	pushl  0x4(%ebx)
801039c4:	e8 73 2a 00 00       	call   8010643c <freevm>
        p->pid = 0;
801039c9:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
801039d0:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
801039d7:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
801039db:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
801039e2:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
801039e9:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
801039f0:	e8 5b 04 00 00       	call   80103e50 <release>
        return pid;
801039f5:	83 c4 10             	add    $0x10,%esp
}
801039f8:	89 f0                	mov    %esi,%eax
801039fa:	8d 65 f8             	lea    -0x8(%ebp),%esp
801039fd:	5b                   	pop    %ebx
801039fe:	5e                   	pop    %esi
801039ff:	5d                   	pop    %ebp
80103a00:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103a01:	83 c3 7c             	add    $0x7c,%ebx
80103a04:	81 fb 94 4c 13 80    	cmp    $0x80134c94,%ebx
80103a0a:	73 12                	jae    80103a1e <wait+0x9d>
      if(p->parent != curproc)
80103a0c:	39 73 14             	cmp    %esi,0x14(%ebx)
80103a0f:	75 f0                	jne    80103a01 <wait+0x80>
      if(p->state == ZOMBIE){
80103a11:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103a15:	74 92                	je     801039a9 <wait+0x28>
      havekids = 1;
80103a17:	b8 01 00 00 00       	mov    $0x1,%eax
80103a1c:	eb e3                	jmp    80103a01 <wait+0x80>
    if(!havekids || curproc->killed){
80103a1e:	85 c0                	test   %eax,%eax
80103a20:	74 06                	je     80103a28 <wait+0xa7>
80103a22:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
80103a26:	74 17                	je     80103a3f <wait+0xbe>
      release(&ptable.lock);
80103a28:	83 ec 0c             	sub    $0xc,%esp
80103a2b:	68 60 2d 13 80       	push   $0x80132d60
80103a30:	e8 1b 04 00 00       	call   80103e50 <release>
      return -1;
80103a35:	83 c4 10             	add    $0x10,%esp
80103a38:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103a3d:	eb b9                	jmp    801039f8 <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80103a3f:	83 ec 08             	sub    $0x8,%esp
80103a42:	68 60 2d 13 80       	push   $0x80132d60
80103a47:	56                   	push   %esi
80103a48:	e8 a3 fe ff ff       	call   801038f0 <sleep>
    havekids = 0;
80103a4d:	83 c4 10             	add    $0x10,%esp
80103a50:	e9 48 ff ff ff       	jmp    8010399d <wait+0x1c>

80103a55 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80103a55:	55                   	push   %ebp
80103a56:	89 e5                	mov    %esp,%ebp
80103a58:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
80103a5b:	68 60 2d 13 80       	push   $0x80132d60
80103a60:	e8 86 03 00 00       	call   80103deb <acquire>
  wakeup1(chan);
80103a65:	8b 45 08             	mov    0x8(%ebp),%eax
80103a68:	e8 1c f8 ff ff       	call   80103289 <wakeup1>
  release(&ptable.lock);
80103a6d:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
80103a74:	e8 d7 03 00 00       	call   80103e50 <release>
}
80103a79:	83 c4 10             	add    $0x10,%esp
80103a7c:	c9                   	leave  
80103a7d:	c3                   	ret    

80103a7e <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80103a7e:	55                   	push   %ebp
80103a7f:	89 e5                	mov    %esp,%ebp
80103a81:	53                   	push   %ebx
80103a82:	83 ec 10             	sub    $0x10,%esp
80103a85:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
80103a88:	68 60 2d 13 80       	push   $0x80132d60
80103a8d:	e8 59 03 00 00       	call   80103deb <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103a92:	83 c4 10             	add    $0x10,%esp
80103a95:	b8 94 2d 13 80       	mov    $0x80132d94,%eax
80103a9a:	3d 94 4c 13 80       	cmp    $0x80134c94,%eax
80103a9f:	73 3a                	jae    80103adb <kill+0x5d>
    if(p->pid == pid){
80103aa1:	39 58 10             	cmp    %ebx,0x10(%eax)
80103aa4:	74 05                	je     80103aab <kill+0x2d>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103aa6:	83 c0 7c             	add    $0x7c,%eax
80103aa9:	eb ef                	jmp    80103a9a <kill+0x1c>
      p->killed = 1;
80103aab:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80103ab2:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
80103ab6:	74 1a                	je     80103ad2 <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
80103ab8:	83 ec 0c             	sub    $0xc,%esp
80103abb:	68 60 2d 13 80       	push   $0x80132d60
80103ac0:	e8 8b 03 00 00       	call   80103e50 <release>
      return 0;
80103ac5:	83 c4 10             	add    $0x10,%esp
80103ac8:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
80103acd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103ad0:	c9                   	leave  
80103ad1:	c3                   	ret    
        p->state = RUNNABLE;
80103ad2:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80103ad9:	eb dd                	jmp    80103ab8 <kill+0x3a>
  release(&ptable.lock);
80103adb:	83 ec 0c             	sub    $0xc,%esp
80103ade:	68 60 2d 13 80       	push   $0x80132d60
80103ae3:	e8 68 03 00 00       	call   80103e50 <release>
  return -1;
80103ae8:	83 c4 10             	add    $0x10,%esp
80103aeb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103af0:	eb db                	jmp    80103acd <kill+0x4f>

80103af2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80103af2:	55                   	push   %ebp
80103af3:	89 e5                	mov    %esp,%ebp
80103af5:	56                   	push   %esi
80103af6:	53                   	push   %ebx
80103af7:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103afa:	bb 94 2d 13 80       	mov    $0x80132d94,%ebx
80103aff:	eb 33                	jmp    80103b34 <procdump+0x42>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103b01:	b8 20 6d 10 80       	mov    $0x80106d20,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
80103b06:	8d 53 6c             	lea    0x6c(%ebx),%edx
80103b09:	52                   	push   %edx
80103b0a:	50                   	push   %eax
80103b0b:	ff 73 10             	pushl  0x10(%ebx)
80103b0e:	68 24 6d 10 80       	push   $0x80106d24
80103b13:	e8 f3 ca ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
80103b18:	83 c4 10             	add    $0x10,%esp
80103b1b:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103b1f:	74 39                	je     80103b5a <procdump+0x68>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103b21:	83 ec 0c             	sub    $0xc,%esp
80103b24:	68 9b 70 10 80       	push   $0x8010709b
80103b29:	e8 dd ca ff ff       	call   8010060b <cprintf>
80103b2e:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103b31:	83 c3 7c             	add    $0x7c,%ebx
80103b34:	81 fb 94 4c 13 80    	cmp    $0x80134c94,%ebx
80103b3a:	73 61                	jae    80103b9d <procdump+0xab>
    if(p->state == UNUSED)
80103b3c:	8b 43 0c             	mov    0xc(%ebx),%eax
80103b3f:	85 c0                	test   %eax,%eax
80103b41:	74 ee                	je     80103b31 <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103b43:	83 f8 05             	cmp    $0x5,%eax
80103b46:	77 b9                	ja     80103b01 <procdump+0xf>
80103b48:	8b 04 85 80 6d 10 80 	mov    -0x7fef9280(,%eax,4),%eax
80103b4f:	85 c0                	test   %eax,%eax
80103b51:	75 b3                	jne    80103b06 <procdump+0x14>
      state = "???";
80103b53:	b8 20 6d 10 80       	mov    $0x80106d20,%eax
80103b58:	eb ac                	jmp    80103b06 <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80103b5a:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103b5d:	8b 40 0c             	mov    0xc(%eax),%eax
80103b60:	83 c0 08             	add    $0x8,%eax
80103b63:	83 ec 08             	sub    $0x8,%esp
80103b66:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103b69:	52                   	push   %edx
80103b6a:	50                   	push   %eax
80103b6b:	e8 5a 01 00 00       	call   80103cca <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103b70:	83 c4 10             	add    $0x10,%esp
80103b73:	be 00 00 00 00       	mov    $0x0,%esi
80103b78:	eb 14                	jmp    80103b8e <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103b7a:	83 ec 08             	sub    $0x8,%esp
80103b7d:	50                   	push   %eax
80103b7e:	68 61 67 10 80       	push   $0x80106761
80103b83:	e8 83 ca ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103b88:	83 c6 01             	add    $0x1,%esi
80103b8b:	83 c4 10             	add    $0x10,%esp
80103b8e:	83 fe 09             	cmp    $0x9,%esi
80103b91:	7f 8e                	jg     80103b21 <procdump+0x2f>
80103b93:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103b97:	85 c0                	test   %eax,%eax
80103b99:	75 df                	jne    80103b7a <procdump+0x88>
80103b9b:	eb 84                	jmp    80103b21 <procdump+0x2f>
  }
80103b9d:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103ba0:	5b                   	pop    %ebx
80103ba1:	5e                   	pop    %esi
80103ba2:	5d                   	pop    %ebp
80103ba3:	c3                   	ret    

80103ba4 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103ba4:	55                   	push   %ebp
80103ba5:	89 e5                	mov    %esp,%ebp
80103ba7:	53                   	push   %ebx
80103ba8:	83 ec 0c             	sub    $0xc,%esp
80103bab:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103bae:	68 98 6d 10 80       	push   $0x80106d98
80103bb3:	8d 43 04             	lea    0x4(%ebx),%eax
80103bb6:	50                   	push   %eax
80103bb7:	e8 f3 00 00 00       	call   80103caf <initlock>
  lk->name = name;
80103bbc:	8b 45 0c             	mov    0xc(%ebp),%eax
80103bbf:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103bc2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103bc8:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103bcf:	83 c4 10             	add    $0x10,%esp
80103bd2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103bd5:	c9                   	leave  
80103bd6:	c3                   	ret    

80103bd7 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103bd7:	55                   	push   %ebp
80103bd8:	89 e5                	mov    %esp,%ebp
80103bda:	56                   	push   %esi
80103bdb:	53                   	push   %ebx
80103bdc:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103bdf:	8d 73 04             	lea    0x4(%ebx),%esi
80103be2:	83 ec 0c             	sub    $0xc,%esp
80103be5:	56                   	push   %esi
80103be6:	e8 00 02 00 00       	call   80103deb <acquire>
  while (lk->locked) {
80103beb:	83 c4 10             	add    $0x10,%esp
80103bee:	eb 0d                	jmp    80103bfd <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103bf0:	83 ec 08             	sub    $0x8,%esp
80103bf3:	56                   	push   %esi
80103bf4:	53                   	push   %ebx
80103bf5:	e8 f6 fc ff ff       	call   801038f0 <sleep>
80103bfa:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103bfd:	83 3b 00             	cmpl   $0x0,(%ebx)
80103c00:	75 ee                	jne    80103bf0 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103c02:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103c08:	e8 3c f8 ff ff       	call   80103449 <myproc>
80103c0d:	8b 40 10             	mov    0x10(%eax),%eax
80103c10:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103c13:	83 ec 0c             	sub    $0xc,%esp
80103c16:	56                   	push   %esi
80103c17:	e8 34 02 00 00       	call   80103e50 <release>
}
80103c1c:	83 c4 10             	add    $0x10,%esp
80103c1f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103c22:	5b                   	pop    %ebx
80103c23:	5e                   	pop    %esi
80103c24:	5d                   	pop    %ebp
80103c25:	c3                   	ret    

80103c26 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103c26:	55                   	push   %ebp
80103c27:	89 e5                	mov    %esp,%ebp
80103c29:	56                   	push   %esi
80103c2a:	53                   	push   %ebx
80103c2b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103c2e:	8d 73 04             	lea    0x4(%ebx),%esi
80103c31:	83 ec 0c             	sub    $0xc,%esp
80103c34:	56                   	push   %esi
80103c35:	e8 b1 01 00 00       	call   80103deb <acquire>
  lk->locked = 0;
80103c3a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103c40:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103c47:	89 1c 24             	mov    %ebx,(%esp)
80103c4a:	e8 06 fe ff ff       	call   80103a55 <wakeup>
  release(&lk->lk);
80103c4f:	89 34 24             	mov    %esi,(%esp)
80103c52:	e8 f9 01 00 00       	call   80103e50 <release>
}
80103c57:	83 c4 10             	add    $0x10,%esp
80103c5a:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103c5d:	5b                   	pop    %ebx
80103c5e:	5e                   	pop    %esi
80103c5f:	5d                   	pop    %ebp
80103c60:	c3                   	ret    

80103c61 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103c61:	55                   	push   %ebp
80103c62:	89 e5                	mov    %esp,%ebp
80103c64:	56                   	push   %esi
80103c65:	53                   	push   %ebx
80103c66:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103c69:	8d 73 04             	lea    0x4(%ebx),%esi
80103c6c:	83 ec 0c             	sub    $0xc,%esp
80103c6f:	56                   	push   %esi
80103c70:	e8 76 01 00 00       	call   80103deb <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103c75:	83 c4 10             	add    $0x10,%esp
80103c78:	83 3b 00             	cmpl   $0x0,(%ebx)
80103c7b:	75 17                	jne    80103c94 <holdingsleep+0x33>
80103c7d:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103c82:	83 ec 0c             	sub    $0xc,%esp
80103c85:	56                   	push   %esi
80103c86:	e8 c5 01 00 00       	call   80103e50 <release>
  return r;
}
80103c8b:	89 d8                	mov    %ebx,%eax
80103c8d:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103c90:	5b                   	pop    %ebx
80103c91:	5e                   	pop    %esi
80103c92:	5d                   	pop    %ebp
80103c93:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103c94:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103c97:	e8 ad f7 ff ff       	call   80103449 <myproc>
80103c9c:	3b 58 10             	cmp    0x10(%eax),%ebx
80103c9f:	74 07                	je     80103ca8 <holdingsleep+0x47>
80103ca1:	bb 00 00 00 00       	mov    $0x0,%ebx
80103ca6:	eb da                	jmp    80103c82 <holdingsleep+0x21>
80103ca8:	bb 01 00 00 00       	mov    $0x1,%ebx
80103cad:	eb d3                	jmp    80103c82 <holdingsleep+0x21>

80103caf <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103caf:	55                   	push   %ebp
80103cb0:	89 e5                	mov    %esp,%ebp
80103cb2:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103cb5:	8b 55 0c             	mov    0xc(%ebp),%edx
80103cb8:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103cbb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103cc1:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103cc8:	5d                   	pop    %ebp
80103cc9:	c3                   	ret    

80103cca <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103cca:	55                   	push   %ebp
80103ccb:	89 e5                	mov    %esp,%ebp
80103ccd:	53                   	push   %ebx
80103cce:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103cd1:	8b 45 08             	mov    0x8(%ebp),%eax
80103cd4:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103cd7:	b8 00 00 00 00       	mov    $0x0,%eax
80103cdc:	83 f8 09             	cmp    $0x9,%eax
80103cdf:	7f 25                	jg     80103d06 <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103ce1:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103ce7:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103ced:	77 17                	ja     80103d06 <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103cef:	8b 5a 04             	mov    0x4(%edx),%ebx
80103cf2:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103cf5:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103cf7:	83 c0 01             	add    $0x1,%eax
80103cfa:	eb e0                	jmp    80103cdc <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103cfc:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103d03:	83 c0 01             	add    $0x1,%eax
80103d06:	83 f8 09             	cmp    $0x9,%eax
80103d09:	7e f1                	jle    80103cfc <getcallerpcs+0x32>
}
80103d0b:	5b                   	pop    %ebx
80103d0c:	5d                   	pop    %ebp
80103d0d:	c3                   	ret    

80103d0e <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103d0e:	55                   	push   %ebp
80103d0f:	89 e5                	mov    %esp,%ebp
80103d11:	53                   	push   %ebx
80103d12:	83 ec 04             	sub    $0x4,%esp
80103d15:	9c                   	pushf  
80103d16:	5b                   	pop    %ebx
  asm volatile("cli");
80103d17:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103d18:	e8 b5 f6 ff ff       	call   801033d2 <mycpu>
80103d1d:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103d24:	74 12                	je     80103d38 <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103d26:	e8 a7 f6 ff ff       	call   801033d2 <mycpu>
80103d2b:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103d32:	83 c4 04             	add    $0x4,%esp
80103d35:	5b                   	pop    %ebx
80103d36:	5d                   	pop    %ebp
80103d37:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103d38:	e8 95 f6 ff ff       	call   801033d2 <mycpu>
80103d3d:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103d43:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103d49:	eb db                	jmp    80103d26 <pushcli+0x18>

80103d4b <popcli>:

void
popcli(void)
{
80103d4b:	55                   	push   %ebp
80103d4c:	89 e5                	mov    %esp,%ebp
80103d4e:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103d51:	9c                   	pushf  
80103d52:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103d53:	f6 c4 02             	test   $0x2,%ah
80103d56:	75 28                	jne    80103d80 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103d58:	e8 75 f6 ff ff       	call   801033d2 <mycpu>
80103d5d:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103d63:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103d66:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103d6c:	85 d2                	test   %edx,%edx
80103d6e:	78 1d                	js     80103d8d <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103d70:	e8 5d f6 ff ff       	call   801033d2 <mycpu>
80103d75:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103d7c:	74 1c                	je     80103d9a <popcli+0x4f>
    sti();
}
80103d7e:	c9                   	leave  
80103d7f:	c3                   	ret    
    panic("popcli - interruptible");
80103d80:	83 ec 0c             	sub    $0xc,%esp
80103d83:	68 a3 6d 10 80       	push   $0x80106da3
80103d88:	e8 bb c5 ff ff       	call   80100348 <panic>
    panic("popcli");
80103d8d:	83 ec 0c             	sub    $0xc,%esp
80103d90:	68 ba 6d 10 80       	push   $0x80106dba
80103d95:	e8 ae c5 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103d9a:	e8 33 f6 ff ff       	call   801033d2 <mycpu>
80103d9f:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103da6:	74 d6                	je     80103d7e <popcli+0x33>
  asm volatile("sti");
80103da8:	fb                   	sti    
}
80103da9:	eb d3                	jmp    80103d7e <popcli+0x33>

80103dab <holding>:
{
80103dab:	55                   	push   %ebp
80103dac:	89 e5                	mov    %esp,%ebp
80103dae:	53                   	push   %ebx
80103daf:	83 ec 04             	sub    $0x4,%esp
80103db2:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103db5:	e8 54 ff ff ff       	call   80103d0e <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103dba:	83 3b 00             	cmpl   $0x0,(%ebx)
80103dbd:	75 12                	jne    80103dd1 <holding+0x26>
80103dbf:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103dc4:	e8 82 ff ff ff       	call   80103d4b <popcli>
}
80103dc9:	89 d8                	mov    %ebx,%eax
80103dcb:	83 c4 04             	add    $0x4,%esp
80103dce:	5b                   	pop    %ebx
80103dcf:	5d                   	pop    %ebp
80103dd0:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103dd1:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103dd4:	e8 f9 f5 ff ff       	call   801033d2 <mycpu>
80103dd9:	39 c3                	cmp    %eax,%ebx
80103ddb:	74 07                	je     80103de4 <holding+0x39>
80103ddd:	bb 00 00 00 00       	mov    $0x0,%ebx
80103de2:	eb e0                	jmp    80103dc4 <holding+0x19>
80103de4:	bb 01 00 00 00       	mov    $0x1,%ebx
80103de9:	eb d9                	jmp    80103dc4 <holding+0x19>

80103deb <acquire>:
{
80103deb:	55                   	push   %ebp
80103dec:	89 e5                	mov    %esp,%ebp
80103dee:	53                   	push   %ebx
80103def:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103df2:	e8 17 ff ff ff       	call   80103d0e <pushcli>
  if(holding(lk))
80103df7:	83 ec 0c             	sub    $0xc,%esp
80103dfa:	ff 75 08             	pushl  0x8(%ebp)
80103dfd:	e8 a9 ff ff ff       	call   80103dab <holding>
80103e02:	83 c4 10             	add    $0x10,%esp
80103e05:	85 c0                	test   %eax,%eax
80103e07:	75 3a                	jne    80103e43 <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103e09:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103e0c:	b8 01 00 00 00       	mov    $0x1,%eax
80103e11:	f0 87 02             	lock xchg %eax,(%edx)
80103e14:	85 c0                	test   %eax,%eax
80103e16:	75 f1                	jne    80103e09 <acquire+0x1e>
  __sync_synchronize();
80103e18:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103e1d:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103e20:	e8 ad f5 ff ff       	call   801033d2 <mycpu>
80103e25:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103e28:	8b 45 08             	mov    0x8(%ebp),%eax
80103e2b:	83 c0 0c             	add    $0xc,%eax
80103e2e:	83 ec 08             	sub    $0x8,%esp
80103e31:	50                   	push   %eax
80103e32:	8d 45 08             	lea    0x8(%ebp),%eax
80103e35:	50                   	push   %eax
80103e36:	e8 8f fe ff ff       	call   80103cca <getcallerpcs>
}
80103e3b:	83 c4 10             	add    $0x10,%esp
80103e3e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103e41:	c9                   	leave  
80103e42:	c3                   	ret    
    panic("acquire");
80103e43:	83 ec 0c             	sub    $0xc,%esp
80103e46:	68 c1 6d 10 80       	push   $0x80106dc1
80103e4b:	e8 f8 c4 ff ff       	call   80100348 <panic>

80103e50 <release>:
{
80103e50:	55                   	push   %ebp
80103e51:	89 e5                	mov    %esp,%ebp
80103e53:	53                   	push   %ebx
80103e54:	83 ec 10             	sub    $0x10,%esp
80103e57:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103e5a:	53                   	push   %ebx
80103e5b:	e8 4b ff ff ff       	call   80103dab <holding>
80103e60:	83 c4 10             	add    $0x10,%esp
80103e63:	85 c0                	test   %eax,%eax
80103e65:	74 23                	je     80103e8a <release+0x3a>
  lk->pcs[0] = 0;
80103e67:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103e6e:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103e75:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103e7a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103e80:	e8 c6 fe ff ff       	call   80103d4b <popcli>
}
80103e85:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103e88:	c9                   	leave  
80103e89:	c3                   	ret    
    panic("release");
80103e8a:	83 ec 0c             	sub    $0xc,%esp
80103e8d:	68 c9 6d 10 80       	push   $0x80106dc9
80103e92:	e8 b1 c4 ff ff       	call   80100348 <panic>

80103e97 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103e97:	55                   	push   %ebp
80103e98:	89 e5                	mov    %esp,%ebp
80103e9a:	57                   	push   %edi
80103e9b:	53                   	push   %ebx
80103e9c:	8b 55 08             	mov    0x8(%ebp),%edx
80103e9f:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103ea2:	f6 c2 03             	test   $0x3,%dl
80103ea5:	75 05                	jne    80103eac <memset+0x15>
80103ea7:	f6 c1 03             	test   $0x3,%cl
80103eaa:	74 0e                	je     80103eba <memset+0x23>
  asm volatile("cld; rep stosb" :
80103eac:	89 d7                	mov    %edx,%edi
80103eae:	8b 45 0c             	mov    0xc(%ebp),%eax
80103eb1:	fc                   	cld    
80103eb2:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103eb4:	89 d0                	mov    %edx,%eax
80103eb6:	5b                   	pop    %ebx
80103eb7:	5f                   	pop    %edi
80103eb8:	5d                   	pop    %ebp
80103eb9:	c3                   	ret    
    c &= 0xFF;
80103eba:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103ebe:	c1 e9 02             	shr    $0x2,%ecx
80103ec1:	89 f8                	mov    %edi,%eax
80103ec3:	c1 e0 18             	shl    $0x18,%eax
80103ec6:	89 fb                	mov    %edi,%ebx
80103ec8:	c1 e3 10             	shl    $0x10,%ebx
80103ecb:	09 d8                	or     %ebx,%eax
80103ecd:	89 fb                	mov    %edi,%ebx
80103ecf:	c1 e3 08             	shl    $0x8,%ebx
80103ed2:	09 d8                	or     %ebx,%eax
80103ed4:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103ed6:	89 d7                	mov    %edx,%edi
80103ed8:	fc                   	cld    
80103ed9:	f3 ab                	rep stos %eax,%es:(%edi)
80103edb:	eb d7                	jmp    80103eb4 <memset+0x1d>

80103edd <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103edd:	55                   	push   %ebp
80103ede:	89 e5                	mov    %esp,%ebp
80103ee0:	56                   	push   %esi
80103ee1:	53                   	push   %ebx
80103ee2:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103ee5:	8b 55 0c             	mov    0xc(%ebp),%edx
80103ee8:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103eeb:	8d 70 ff             	lea    -0x1(%eax),%esi
80103eee:	85 c0                	test   %eax,%eax
80103ef0:	74 1c                	je     80103f0e <memcmp+0x31>
    if(*s1 != *s2)
80103ef2:	0f b6 01             	movzbl (%ecx),%eax
80103ef5:	0f b6 1a             	movzbl (%edx),%ebx
80103ef8:	38 d8                	cmp    %bl,%al
80103efa:	75 0a                	jne    80103f06 <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103efc:	83 c1 01             	add    $0x1,%ecx
80103eff:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103f02:	89 f0                	mov    %esi,%eax
80103f04:	eb e5                	jmp    80103eeb <memcmp+0xe>
      return *s1 - *s2;
80103f06:	0f b6 c0             	movzbl %al,%eax
80103f09:	0f b6 db             	movzbl %bl,%ebx
80103f0c:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103f0e:	5b                   	pop    %ebx
80103f0f:	5e                   	pop    %esi
80103f10:	5d                   	pop    %ebp
80103f11:	c3                   	ret    

80103f12 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103f12:	55                   	push   %ebp
80103f13:	89 e5                	mov    %esp,%ebp
80103f15:	56                   	push   %esi
80103f16:	53                   	push   %ebx
80103f17:	8b 45 08             	mov    0x8(%ebp),%eax
80103f1a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103f1d:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103f20:	39 c1                	cmp    %eax,%ecx
80103f22:	73 3a                	jae    80103f5e <memmove+0x4c>
80103f24:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103f27:	39 c3                	cmp    %eax,%ebx
80103f29:	76 37                	jbe    80103f62 <memmove+0x50>
    s += n;
    d += n;
80103f2b:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103f2e:	eb 0d                	jmp    80103f3d <memmove+0x2b>
      *--d = *--s;
80103f30:	83 eb 01             	sub    $0x1,%ebx
80103f33:	83 e9 01             	sub    $0x1,%ecx
80103f36:	0f b6 13             	movzbl (%ebx),%edx
80103f39:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103f3b:	89 f2                	mov    %esi,%edx
80103f3d:	8d 72 ff             	lea    -0x1(%edx),%esi
80103f40:	85 d2                	test   %edx,%edx
80103f42:	75 ec                	jne    80103f30 <memmove+0x1e>
80103f44:	eb 14                	jmp    80103f5a <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103f46:	0f b6 11             	movzbl (%ecx),%edx
80103f49:	88 13                	mov    %dl,(%ebx)
80103f4b:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103f4e:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103f51:	89 f2                	mov    %esi,%edx
80103f53:	8d 72 ff             	lea    -0x1(%edx),%esi
80103f56:	85 d2                	test   %edx,%edx
80103f58:	75 ec                	jne    80103f46 <memmove+0x34>

  return dst;
}
80103f5a:	5b                   	pop    %ebx
80103f5b:	5e                   	pop    %esi
80103f5c:	5d                   	pop    %ebp
80103f5d:	c3                   	ret    
80103f5e:	89 c3                	mov    %eax,%ebx
80103f60:	eb f1                	jmp    80103f53 <memmove+0x41>
80103f62:	89 c3                	mov    %eax,%ebx
80103f64:	eb ed                	jmp    80103f53 <memmove+0x41>

80103f66 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103f66:	55                   	push   %ebp
80103f67:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80103f69:	ff 75 10             	pushl  0x10(%ebp)
80103f6c:	ff 75 0c             	pushl  0xc(%ebp)
80103f6f:	ff 75 08             	pushl  0x8(%ebp)
80103f72:	e8 9b ff ff ff       	call   80103f12 <memmove>
}
80103f77:	c9                   	leave  
80103f78:	c3                   	ret    

80103f79 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103f79:	55                   	push   %ebp
80103f7a:	89 e5                	mov    %esp,%ebp
80103f7c:	53                   	push   %ebx
80103f7d:	8b 55 08             	mov    0x8(%ebp),%edx
80103f80:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103f83:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103f86:	eb 09                	jmp    80103f91 <strncmp+0x18>
    n--, p++, q++;
80103f88:	83 e8 01             	sub    $0x1,%eax
80103f8b:	83 c2 01             	add    $0x1,%edx
80103f8e:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103f91:	85 c0                	test   %eax,%eax
80103f93:	74 0b                	je     80103fa0 <strncmp+0x27>
80103f95:	0f b6 1a             	movzbl (%edx),%ebx
80103f98:	84 db                	test   %bl,%bl
80103f9a:	74 04                	je     80103fa0 <strncmp+0x27>
80103f9c:	3a 19                	cmp    (%ecx),%bl
80103f9e:	74 e8                	je     80103f88 <strncmp+0xf>
  if(n == 0)
80103fa0:	85 c0                	test   %eax,%eax
80103fa2:	74 0b                	je     80103faf <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80103fa4:	0f b6 02             	movzbl (%edx),%eax
80103fa7:	0f b6 11             	movzbl (%ecx),%edx
80103faa:	29 d0                	sub    %edx,%eax
}
80103fac:	5b                   	pop    %ebx
80103fad:	5d                   	pop    %ebp
80103fae:	c3                   	ret    
    return 0;
80103faf:	b8 00 00 00 00       	mov    $0x0,%eax
80103fb4:	eb f6                	jmp    80103fac <strncmp+0x33>

80103fb6 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103fb6:	55                   	push   %ebp
80103fb7:	89 e5                	mov    %esp,%ebp
80103fb9:	57                   	push   %edi
80103fba:	56                   	push   %esi
80103fbb:	53                   	push   %ebx
80103fbc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80103fbf:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103fc2:	8b 45 08             	mov    0x8(%ebp),%eax
80103fc5:	eb 04                	jmp    80103fcb <strncpy+0x15>
80103fc7:	89 fb                	mov    %edi,%ebx
80103fc9:	89 f0                	mov    %esi,%eax
80103fcb:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103fce:	85 c9                	test   %ecx,%ecx
80103fd0:	7e 1d                	jle    80103fef <strncpy+0x39>
80103fd2:	8d 7b 01             	lea    0x1(%ebx),%edi
80103fd5:	8d 70 01             	lea    0x1(%eax),%esi
80103fd8:	0f b6 1b             	movzbl (%ebx),%ebx
80103fdb:	88 18                	mov    %bl,(%eax)
80103fdd:	89 d1                	mov    %edx,%ecx
80103fdf:	84 db                	test   %bl,%bl
80103fe1:	75 e4                	jne    80103fc7 <strncpy+0x11>
80103fe3:	89 f0                	mov    %esi,%eax
80103fe5:	eb 08                	jmp    80103fef <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80103fe7:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80103fea:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80103fec:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80103fef:	8d 4a ff             	lea    -0x1(%edx),%ecx
80103ff2:	85 d2                	test   %edx,%edx
80103ff4:	7f f1                	jg     80103fe7 <strncpy+0x31>
  return os;
}
80103ff6:	8b 45 08             	mov    0x8(%ebp),%eax
80103ff9:	5b                   	pop    %ebx
80103ffa:	5e                   	pop    %esi
80103ffb:	5f                   	pop    %edi
80103ffc:	5d                   	pop    %ebp
80103ffd:	c3                   	ret    

80103ffe <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80103ffe:	55                   	push   %ebp
80103fff:	89 e5                	mov    %esp,%ebp
80104001:	57                   	push   %edi
80104002:	56                   	push   %esi
80104003:	53                   	push   %ebx
80104004:	8b 45 08             	mov    0x8(%ebp),%eax
80104007:	8b 5d 0c             	mov    0xc(%ebp),%ebx
8010400a:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
8010400d:	85 d2                	test   %edx,%edx
8010400f:	7e 23                	jle    80104034 <safestrcpy+0x36>
80104011:	89 c1                	mov    %eax,%ecx
80104013:	eb 04                	jmp    80104019 <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80104015:	89 fb                	mov    %edi,%ebx
80104017:	89 f1                	mov    %esi,%ecx
80104019:	83 ea 01             	sub    $0x1,%edx
8010401c:	85 d2                	test   %edx,%edx
8010401e:	7e 11                	jle    80104031 <safestrcpy+0x33>
80104020:	8d 7b 01             	lea    0x1(%ebx),%edi
80104023:	8d 71 01             	lea    0x1(%ecx),%esi
80104026:	0f b6 1b             	movzbl (%ebx),%ebx
80104029:	88 19                	mov    %bl,(%ecx)
8010402b:	84 db                	test   %bl,%bl
8010402d:	75 e6                	jne    80104015 <safestrcpy+0x17>
8010402f:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80104031:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80104034:	5b                   	pop    %ebx
80104035:	5e                   	pop    %esi
80104036:	5f                   	pop    %edi
80104037:	5d                   	pop    %ebp
80104038:	c3                   	ret    

80104039 <strlen>:

int
strlen(const char *s)
{
80104039:	55                   	push   %ebp
8010403a:	89 e5                	mov    %esp,%ebp
8010403c:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
8010403f:	b8 00 00 00 00       	mov    $0x0,%eax
80104044:	eb 03                	jmp    80104049 <strlen+0x10>
80104046:	83 c0 01             	add    $0x1,%eax
80104049:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
8010404d:	75 f7                	jne    80104046 <strlen+0xd>
    ;
  return n;
}
8010404f:	5d                   	pop    %ebp
80104050:	c3                   	ret    

80104051 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80104051:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80104055:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80104059:	55                   	push   %ebp
  pushl %ebx
8010405a:	53                   	push   %ebx
  pushl %esi
8010405b:	56                   	push   %esi
  pushl %edi
8010405c:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
8010405d:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
8010405f:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80104061:	5f                   	pop    %edi
  popl %esi
80104062:	5e                   	pop    %esi
  popl %ebx
80104063:	5b                   	pop    %ebx
  popl %ebp
80104064:	5d                   	pop    %ebp
  ret
80104065:	c3                   	ret    

80104066 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80104066:	55                   	push   %ebp
80104067:	89 e5                	mov    %esp,%ebp
80104069:	53                   	push   %ebx
8010406a:	83 ec 04             	sub    $0x4,%esp
8010406d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80104070:	e8 d4 f3 ff ff       	call   80103449 <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80104075:	8b 00                	mov    (%eax),%eax
80104077:	39 d8                	cmp    %ebx,%eax
80104079:	76 19                	jbe    80104094 <fetchint+0x2e>
8010407b:	8d 53 04             	lea    0x4(%ebx),%edx
8010407e:	39 d0                	cmp    %edx,%eax
80104080:	72 19                	jb     8010409b <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80104082:	8b 13                	mov    (%ebx),%edx
80104084:	8b 45 0c             	mov    0xc(%ebp),%eax
80104087:	89 10                	mov    %edx,(%eax)
  return 0;
80104089:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010408e:	83 c4 04             	add    $0x4,%esp
80104091:	5b                   	pop    %ebx
80104092:	5d                   	pop    %ebp
80104093:	c3                   	ret    
    return -1;
80104094:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104099:	eb f3                	jmp    8010408e <fetchint+0x28>
8010409b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040a0:	eb ec                	jmp    8010408e <fetchint+0x28>

801040a2 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
801040a2:	55                   	push   %ebp
801040a3:	89 e5                	mov    %esp,%ebp
801040a5:	53                   	push   %ebx
801040a6:	83 ec 04             	sub    $0x4,%esp
801040a9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
801040ac:	e8 98 f3 ff ff       	call   80103449 <myproc>

  if(addr >= curproc->sz)
801040b1:	39 18                	cmp    %ebx,(%eax)
801040b3:	76 26                	jbe    801040db <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
801040b5:	8b 55 0c             	mov    0xc(%ebp),%edx
801040b8:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
801040ba:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
801040bc:	89 d8                	mov    %ebx,%eax
801040be:	39 d0                	cmp    %edx,%eax
801040c0:	73 0e                	jae    801040d0 <fetchstr+0x2e>
    if(*s == 0)
801040c2:	80 38 00             	cmpb   $0x0,(%eax)
801040c5:	74 05                	je     801040cc <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
801040c7:	83 c0 01             	add    $0x1,%eax
801040ca:	eb f2                	jmp    801040be <fetchstr+0x1c>
      return s - *pp;
801040cc:	29 d8                	sub    %ebx,%eax
801040ce:	eb 05                	jmp    801040d5 <fetchstr+0x33>
  }
  return -1;
801040d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801040d5:	83 c4 04             	add    $0x4,%esp
801040d8:	5b                   	pop    %ebx
801040d9:	5d                   	pop    %ebp
801040da:	c3                   	ret    
    return -1;
801040db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040e0:	eb f3                	jmp    801040d5 <fetchstr+0x33>

801040e2 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801040e2:	55                   	push   %ebp
801040e3:	89 e5                	mov    %esp,%ebp
801040e5:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
801040e8:	e8 5c f3 ff ff       	call   80103449 <myproc>
801040ed:	8b 50 18             	mov    0x18(%eax),%edx
801040f0:	8b 45 08             	mov    0x8(%ebp),%eax
801040f3:	c1 e0 02             	shl    $0x2,%eax
801040f6:	03 42 44             	add    0x44(%edx),%eax
801040f9:	83 ec 08             	sub    $0x8,%esp
801040fc:	ff 75 0c             	pushl  0xc(%ebp)
801040ff:	83 c0 04             	add    $0x4,%eax
80104102:	50                   	push   %eax
80104103:	e8 5e ff ff ff       	call   80104066 <fetchint>
}
80104108:	c9                   	leave  
80104109:	c3                   	ret    

8010410a <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
8010410a:	55                   	push   %ebp
8010410b:	89 e5                	mov    %esp,%ebp
8010410d:	56                   	push   %esi
8010410e:	53                   	push   %ebx
8010410f:	83 ec 10             	sub    $0x10,%esp
80104112:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
80104115:	e8 2f f3 ff ff       	call   80103449 <myproc>
8010411a:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
8010411c:	83 ec 08             	sub    $0x8,%esp
8010411f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104122:	50                   	push   %eax
80104123:	ff 75 08             	pushl  0x8(%ebp)
80104126:	e8 b7 ff ff ff       	call   801040e2 <argint>
8010412b:	83 c4 10             	add    $0x10,%esp
8010412e:	85 c0                	test   %eax,%eax
80104130:	78 24                	js     80104156 <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80104132:	85 db                	test   %ebx,%ebx
80104134:	78 27                	js     8010415d <argptr+0x53>
80104136:	8b 16                	mov    (%esi),%edx
80104138:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010413b:	39 c2                	cmp    %eax,%edx
8010413d:	76 25                	jbe    80104164 <argptr+0x5a>
8010413f:	01 c3                	add    %eax,%ebx
80104141:	39 da                	cmp    %ebx,%edx
80104143:	72 26                	jb     8010416b <argptr+0x61>
    return -1;
  *pp = (char*)i;
80104145:	8b 55 0c             	mov    0xc(%ebp),%edx
80104148:	89 02                	mov    %eax,(%edx)
  return 0;
8010414a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010414f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104152:	5b                   	pop    %ebx
80104153:	5e                   	pop    %esi
80104154:	5d                   	pop    %ebp
80104155:	c3                   	ret    
    return -1;
80104156:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010415b:	eb f2                	jmp    8010414f <argptr+0x45>
    return -1;
8010415d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104162:	eb eb                	jmp    8010414f <argptr+0x45>
80104164:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104169:	eb e4                	jmp    8010414f <argptr+0x45>
8010416b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104170:	eb dd                	jmp    8010414f <argptr+0x45>

80104172 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80104172:	55                   	push   %ebp
80104173:	89 e5                	mov    %esp,%ebp
80104175:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
80104178:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010417b:	50                   	push   %eax
8010417c:	ff 75 08             	pushl  0x8(%ebp)
8010417f:	e8 5e ff ff ff       	call   801040e2 <argint>
80104184:	83 c4 10             	add    $0x10,%esp
80104187:	85 c0                	test   %eax,%eax
80104189:	78 13                	js     8010419e <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
8010418b:	83 ec 08             	sub    $0x8,%esp
8010418e:	ff 75 0c             	pushl  0xc(%ebp)
80104191:	ff 75 f4             	pushl  -0xc(%ebp)
80104194:	e8 09 ff ff ff       	call   801040a2 <fetchstr>
80104199:	83 c4 10             	add    $0x10,%esp
}
8010419c:	c9                   	leave  
8010419d:	c3                   	ret    
    return -1;
8010419e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801041a3:	eb f7                	jmp    8010419c <argstr+0x2a>

801041a5 <syscall>:
[SYS_dump_physmem]   sys_dump_physmem,
};

void
syscall(void)
{
801041a5:	55                   	push   %ebp
801041a6:	89 e5                	mov    %esp,%ebp
801041a8:	53                   	push   %ebx
801041a9:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
801041ac:	e8 98 f2 ff ff       	call   80103449 <myproc>
801041b1:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
801041b3:	8b 40 18             	mov    0x18(%eax),%eax
801041b6:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
801041b9:	8d 50 ff             	lea    -0x1(%eax),%edx
801041bc:	83 fa 15             	cmp    $0x15,%edx
801041bf:	77 18                	ja     801041d9 <syscall+0x34>
801041c1:	8b 14 85 00 6e 10 80 	mov    -0x7fef9200(,%eax,4),%edx
801041c8:	85 d2                	test   %edx,%edx
801041ca:	74 0d                	je     801041d9 <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
801041cc:	ff d2                	call   *%edx
801041ce:	8b 53 18             	mov    0x18(%ebx),%edx
801041d1:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
801041d4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801041d7:	c9                   	leave  
801041d8:	c3                   	ret    
            curproc->pid, curproc->name, num);
801041d9:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
801041dc:	50                   	push   %eax
801041dd:	52                   	push   %edx
801041de:	ff 73 10             	pushl  0x10(%ebx)
801041e1:	68 d1 6d 10 80       	push   $0x80106dd1
801041e6:	e8 20 c4 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
801041eb:	8b 43 18             	mov    0x18(%ebx),%eax
801041ee:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
801041f5:	83 c4 10             	add    $0x10,%esp
}
801041f8:	eb da                	jmp    801041d4 <syscall+0x2f>

801041fa <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801041fa:	55                   	push   %ebp
801041fb:	89 e5                	mov    %esp,%ebp
801041fd:	56                   	push   %esi
801041fe:	53                   	push   %ebx
801041ff:	83 ec 18             	sub    $0x18,%esp
80104202:	89 d6                	mov    %edx,%esi
80104204:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80104206:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104209:	52                   	push   %edx
8010420a:	50                   	push   %eax
8010420b:	e8 d2 fe ff ff       	call   801040e2 <argint>
80104210:	83 c4 10             	add    $0x10,%esp
80104213:	85 c0                	test   %eax,%eax
80104215:	78 2e                	js     80104245 <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
80104217:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
8010421b:	77 2f                	ja     8010424c <argfd+0x52>
8010421d:	e8 27 f2 ff ff       	call   80103449 <myproc>
80104222:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104225:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
80104229:	85 c0                	test   %eax,%eax
8010422b:	74 26                	je     80104253 <argfd+0x59>
    return -1;
  if(pfd)
8010422d:	85 f6                	test   %esi,%esi
8010422f:	74 02                	je     80104233 <argfd+0x39>
    *pfd = fd;
80104231:	89 16                	mov    %edx,(%esi)
  if(pf)
80104233:	85 db                	test   %ebx,%ebx
80104235:	74 23                	je     8010425a <argfd+0x60>
    *pf = f;
80104237:	89 03                	mov    %eax,(%ebx)
  return 0;
80104239:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010423e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104241:	5b                   	pop    %ebx
80104242:	5e                   	pop    %esi
80104243:	5d                   	pop    %ebp
80104244:	c3                   	ret    
    return -1;
80104245:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010424a:	eb f2                	jmp    8010423e <argfd+0x44>
    return -1;
8010424c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104251:	eb eb                	jmp    8010423e <argfd+0x44>
80104253:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104258:	eb e4                	jmp    8010423e <argfd+0x44>
  return 0;
8010425a:	b8 00 00 00 00       	mov    $0x0,%eax
8010425f:	eb dd                	jmp    8010423e <argfd+0x44>

80104261 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80104261:	55                   	push   %ebp
80104262:	89 e5                	mov    %esp,%ebp
80104264:	53                   	push   %ebx
80104265:	83 ec 04             	sub    $0x4,%esp
80104268:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
8010426a:	e8 da f1 ff ff       	call   80103449 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
8010426f:	ba 00 00 00 00       	mov    $0x0,%edx
80104274:	83 fa 0f             	cmp    $0xf,%edx
80104277:	7f 18                	jg     80104291 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
80104279:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
8010427e:	74 05                	je     80104285 <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
80104280:	83 c2 01             	add    $0x1,%edx
80104283:	eb ef                	jmp    80104274 <fdalloc+0x13>
      curproc->ofile[fd] = f;
80104285:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
80104289:	89 d0                	mov    %edx,%eax
8010428b:	83 c4 04             	add    $0x4,%esp
8010428e:	5b                   	pop    %ebx
8010428f:	5d                   	pop    %ebp
80104290:	c3                   	ret    
  return -1;
80104291:	ba ff ff ff ff       	mov    $0xffffffff,%edx
80104296:	eb f1                	jmp    80104289 <fdalloc+0x28>

80104298 <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80104298:	55                   	push   %ebp
80104299:	89 e5                	mov    %esp,%ebp
8010429b:	56                   	push   %esi
8010429c:	53                   	push   %ebx
8010429d:	83 ec 10             	sub    $0x10,%esp
801042a0:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801042a2:	b8 20 00 00 00       	mov    $0x20,%eax
801042a7:	89 c6                	mov    %eax,%esi
801042a9:	39 43 58             	cmp    %eax,0x58(%ebx)
801042ac:	76 2e                	jbe    801042dc <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801042ae:	6a 10                	push   $0x10
801042b0:	50                   	push   %eax
801042b1:	8d 45 e8             	lea    -0x18(%ebp),%eax
801042b4:	50                   	push   %eax
801042b5:	53                   	push   %ebx
801042b6:	e8 b8 d4 ff ff       	call   80101773 <readi>
801042bb:	83 c4 10             	add    $0x10,%esp
801042be:	83 f8 10             	cmp    $0x10,%eax
801042c1:	75 0c                	jne    801042cf <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
801042c3:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
801042c8:	75 1e                	jne    801042e8 <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801042ca:	8d 46 10             	lea    0x10(%esi),%eax
801042cd:	eb d8                	jmp    801042a7 <isdirempty+0xf>
      panic("isdirempty: readi");
801042cf:	83 ec 0c             	sub    $0xc,%esp
801042d2:	68 5c 6e 10 80       	push   $0x80106e5c
801042d7:	e8 6c c0 ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
801042dc:	b8 01 00 00 00       	mov    $0x1,%eax
}
801042e1:	8d 65 f8             	lea    -0x8(%ebp),%esp
801042e4:	5b                   	pop    %ebx
801042e5:	5e                   	pop    %esi
801042e6:	5d                   	pop    %ebp
801042e7:	c3                   	ret    
      return 0;
801042e8:	b8 00 00 00 00       	mov    $0x0,%eax
801042ed:	eb f2                	jmp    801042e1 <isdirempty+0x49>

801042ef <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
801042ef:	55                   	push   %ebp
801042f0:	89 e5                	mov    %esp,%ebp
801042f2:	57                   	push   %edi
801042f3:	56                   	push   %esi
801042f4:	53                   	push   %ebx
801042f5:	83 ec 44             	sub    $0x44,%esp
801042f8:	89 55 c4             	mov    %edx,-0x3c(%ebp)
801042fb:	89 4d c0             	mov    %ecx,-0x40(%ebp)
801042fe:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80104301:	8d 55 d6             	lea    -0x2a(%ebp),%edx
80104304:	52                   	push   %edx
80104305:	50                   	push   %eax
80104306:	e8 ee d8 ff ff       	call   80101bf9 <nameiparent>
8010430b:	89 c6                	mov    %eax,%esi
8010430d:	83 c4 10             	add    $0x10,%esp
80104310:	85 c0                	test   %eax,%eax
80104312:	0f 84 3a 01 00 00    	je     80104452 <create+0x163>
    return 0;
  ilock(dp);
80104318:	83 ec 0c             	sub    $0xc,%esp
8010431b:	50                   	push   %eax
8010431c:	e8 60 d2 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80104321:	83 c4 0c             	add    $0xc,%esp
80104324:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104327:	50                   	push   %eax
80104328:	8d 45 d6             	lea    -0x2a(%ebp),%eax
8010432b:	50                   	push   %eax
8010432c:	56                   	push   %esi
8010432d:	e8 7e d6 ff ff       	call   801019b0 <dirlookup>
80104332:	89 c3                	mov    %eax,%ebx
80104334:	83 c4 10             	add    $0x10,%esp
80104337:	85 c0                	test   %eax,%eax
80104339:	74 3f                	je     8010437a <create+0x8b>
    iunlockput(dp);
8010433b:	83 ec 0c             	sub    $0xc,%esp
8010433e:	56                   	push   %esi
8010433f:	e8 e4 d3 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
80104344:	89 1c 24             	mov    %ebx,(%esp)
80104347:	e8 35 d2 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
8010434c:	83 c4 10             	add    $0x10,%esp
8010434f:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
80104354:	75 11                	jne    80104367 <create+0x78>
80104356:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
8010435b:	75 0a                	jne    80104367 <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
8010435d:	89 d8                	mov    %ebx,%eax
8010435f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104362:	5b                   	pop    %ebx
80104363:	5e                   	pop    %esi
80104364:	5f                   	pop    %edi
80104365:	5d                   	pop    %ebp
80104366:	c3                   	ret    
    iunlockput(ip);
80104367:	83 ec 0c             	sub    $0xc,%esp
8010436a:	53                   	push   %ebx
8010436b:	e8 b8 d3 ff ff       	call   80101728 <iunlockput>
    return 0;
80104370:	83 c4 10             	add    $0x10,%esp
80104373:	bb 00 00 00 00       	mov    $0x0,%ebx
80104378:	eb e3                	jmp    8010435d <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
8010437a:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
8010437e:	83 ec 08             	sub    $0x8,%esp
80104381:	50                   	push   %eax
80104382:	ff 36                	pushl  (%esi)
80104384:	e8 f5 cf ff ff       	call   8010137e <ialloc>
80104389:	89 c3                	mov    %eax,%ebx
8010438b:	83 c4 10             	add    $0x10,%esp
8010438e:	85 c0                	test   %eax,%eax
80104390:	74 55                	je     801043e7 <create+0xf8>
  ilock(ip);
80104392:	83 ec 0c             	sub    $0xc,%esp
80104395:	50                   	push   %eax
80104396:	e8 e6 d1 ff ff       	call   80101581 <ilock>
  ip->major = major;
8010439b:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
8010439f:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
801043a3:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
801043a7:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
801043ad:	89 1c 24             	mov    %ebx,(%esp)
801043b0:	e8 6b d0 ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
801043b5:	83 c4 10             	add    $0x10,%esp
801043b8:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
801043bd:	74 35                	je     801043f4 <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
801043bf:	83 ec 04             	sub    $0x4,%esp
801043c2:	ff 73 04             	pushl  0x4(%ebx)
801043c5:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801043c8:	50                   	push   %eax
801043c9:	56                   	push   %esi
801043ca:	e8 61 d7 ff ff       	call   80101b30 <dirlink>
801043cf:	83 c4 10             	add    $0x10,%esp
801043d2:	85 c0                	test   %eax,%eax
801043d4:	78 6f                	js     80104445 <create+0x156>
  iunlockput(dp);
801043d6:	83 ec 0c             	sub    $0xc,%esp
801043d9:	56                   	push   %esi
801043da:	e8 49 d3 ff ff       	call   80101728 <iunlockput>
  return ip;
801043df:	83 c4 10             	add    $0x10,%esp
801043e2:	e9 76 ff ff ff       	jmp    8010435d <create+0x6e>
    panic("create: ialloc");
801043e7:	83 ec 0c             	sub    $0xc,%esp
801043ea:	68 6e 6e 10 80       	push   $0x80106e6e
801043ef:	e8 54 bf ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
801043f4:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801043f8:	83 c0 01             	add    $0x1,%eax
801043fb:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801043ff:	83 ec 0c             	sub    $0xc,%esp
80104402:	56                   	push   %esi
80104403:	e8 18 d0 ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80104408:	83 c4 0c             	add    $0xc,%esp
8010440b:	ff 73 04             	pushl  0x4(%ebx)
8010440e:	68 7e 6e 10 80       	push   $0x80106e7e
80104413:	53                   	push   %ebx
80104414:	e8 17 d7 ff ff       	call   80101b30 <dirlink>
80104419:	83 c4 10             	add    $0x10,%esp
8010441c:	85 c0                	test   %eax,%eax
8010441e:	78 18                	js     80104438 <create+0x149>
80104420:	83 ec 04             	sub    $0x4,%esp
80104423:	ff 76 04             	pushl  0x4(%esi)
80104426:	68 7d 6e 10 80       	push   $0x80106e7d
8010442b:	53                   	push   %ebx
8010442c:	e8 ff d6 ff ff       	call   80101b30 <dirlink>
80104431:	83 c4 10             	add    $0x10,%esp
80104434:	85 c0                	test   %eax,%eax
80104436:	79 87                	jns    801043bf <create+0xd0>
      panic("create dots");
80104438:	83 ec 0c             	sub    $0xc,%esp
8010443b:	68 80 6e 10 80       	push   $0x80106e80
80104440:	e8 03 bf ff ff       	call   80100348 <panic>
    panic("create: dirlink");
80104445:	83 ec 0c             	sub    $0xc,%esp
80104448:	68 8c 6e 10 80       	push   $0x80106e8c
8010444d:	e8 f6 be ff ff       	call   80100348 <panic>
    return 0;
80104452:	89 c3                	mov    %eax,%ebx
80104454:	e9 04 ff ff ff       	jmp    8010435d <create+0x6e>

80104459 <sys_dup>:
{
80104459:	55                   	push   %ebp
8010445a:	89 e5                	mov    %esp,%ebp
8010445c:	53                   	push   %ebx
8010445d:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
80104460:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104463:	ba 00 00 00 00       	mov    $0x0,%edx
80104468:	b8 00 00 00 00       	mov    $0x0,%eax
8010446d:	e8 88 fd ff ff       	call   801041fa <argfd>
80104472:	85 c0                	test   %eax,%eax
80104474:	78 23                	js     80104499 <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
80104476:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104479:	e8 e3 fd ff ff       	call   80104261 <fdalloc>
8010447e:	89 c3                	mov    %eax,%ebx
80104480:	85 c0                	test   %eax,%eax
80104482:	78 1c                	js     801044a0 <sys_dup+0x47>
  filedup(f);
80104484:	83 ec 0c             	sub    $0xc,%esp
80104487:	ff 75 f4             	pushl  -0xc(%ebp)
8010448a:	e8 ff c7 ff ff       	call   80100c8e <filedup>
  return fd;
8010448f:	83 c4 10             	add    $0x10,%esp
}
80104492:	89 d8                	mov    %ebx,%eax
80104494:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104497:	c9                   	leave  
80104498:	c3                   	ret    
    return -1;
80104499:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010449e:	eb f2                	jmp    80104492 <sys_dup+0x39>
    return -1;
801044a0:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801044a5:	eb eb                	jmp    80104492 <sys_dup+0x39>

801044a7 <sys_read>:
{
801044a7:	55                   	push   %ebp
801044a8:	89 e5                	mov    %esp,%ebp
801044aa:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801044ad:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801044b0:	ba 00 00 00 00       	mov    $0x0,%edx
801044b5:	b8 00 00 00 00       	mov    $0x0,%eax
801044ba:	e8 3b fd ff ff       	call   801041fa <argfd>
801044bf:	85 c0                	test   %eax,%eax
801044c1:	78 43                	js     80104506 <sys_read+0x5f>
801044c3:	83 ec 08             	sub    $0x8,%esp
801044c6:	8d 45 f0             	lea    -0x10(%ebp),%eax
801044c9:	50                   	push   %eax
801044ca:	6a 02                	push   $0x2
801044cc:	e8 11 fc ff ff       	call   801040e2 <argint>
801044d1:	83 c4 10             	add    $0x10,%esp
801044d4:	85 c0                	test   %eax,%eax
801044d6:	78 35                	js     8010450d <sys_read+0x66>
801044d8:	83 ec 04             	sub    $0x4,%esp
801044db:	ff 75 f0             	pushl  -0x10(%ebp)
801044de:	8d 45 ec             	lea    -0x14(%ebp),%eax
801044e1:	50                   	push   %eax
801044e2:	6a 01                	push   $0x1
801044e4:	e8 21 fc ff ff       	call   8010410a <argptr>
801044e9:	83 c4 10             	add    $0x10,%esp
801044ec:	85 c0                	test   %eax,%eax
801044ee:	78 24                	js     80104514 <sys_read+0x6d>
  return fileread(f, p, n);
801044f0:	83 ec 04             	sub    $0x4,%esp
801044f3:	ff 75 f0             	pushl  -0x10(%ebp)
801044f6:	ff 75 ec             	pushl  -0x14(%ebp)
801044f9:	ff 75 f4             	pushl  -0xc(%ebp)
801044fc:	e8 d6 c8 ff ff       	call   80100dd7 <fileread>
80104501:	83 c4 10             	add    $0x10,%esp
}
80104504:	c9                   	leave  
80104505:	c3                   	ret    
    return -1;
80104506:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010450b:	eb f7                	jmp    80104504 <sys_read+0x5d>
8010450d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104512:	eb f0                	jmp    80104504 <sys_read+0x5d>
80104514:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104519:	eb e9                	jmp    80104504 <sys_read+0x5d>

8010451b <sys_write>:
{
8010451b:	55                   	push   %ebp
8010451c:	89 e5                	mov    %esp,%ebp
8010451e:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104521:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104524:	ba 00 00 00 00       	mov    $0x0,%edx
80104529:	b8 00 00 00 00       	mov    $0x0,%eax
8010452e:	e8 c7 fc ff ff       	call   801041fa <argfd>
80104533:	85 c0                	test   %eax,%eax
80104535:	78 43                	js     8010457a <sys_write+0x5f>
80104537:	83 ec 08             	sub    $0x8,%esp
8010453a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010453d:	50                   	push   %eax
8010453e:	6a 02                	push   $0x2
80104540:	e8 9d fb ff ff       	call   801040e2 <argint>
80104545:	83 c4 10             	add    $0x10,%esp
80104548:	85 c0                	test   %eax,%eax
8010454a:	78 35                	js     80104581 <sys_write+0x66>
8010454c:	83 ec 04             	sub    $0x4,%esp
8010454f:	ff 75 f0             	pushl  -0x10(%ebp)
80104552:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104555:	50                   	push   %eax
80104556:	6a 01                	push   $0x1
80104558:	e8 ad fb ff ff       	call   8010410a <argptr>
8010455d:	83 c4 10             	add    $0x10,%esp
80104560:	85 c0                	test   %eax,%eax
80104562:	78 24                	js     80104588 <sys_write+0x6d>
  return filewrite(f, p, n);
80104564:	83 ec 04             	sub    $0x4,%esp
80104567:	ff 75 f0             	pushl  -0x10(%ebp)
8010456a:	ff 75 ec             	pushl  -0x14(%ebp)
8010456d:	ff 75 f4             	pushl  -0xc(%ebp)
80104570:	e8 e7 c8 ff ff       	call   80100e5c <filewrite>
80104575:	83 c4 10             	add    $0x10,%esp
}
80104578:	c9                   	leave  
80104579:	c3                   	ret    
    return -1;
8010457a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010457f:	eb f7                	jmp    80104578 <sys_write+0x5d>
80104581:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104586:	eb f0                	jmp    80104578 <sys_write+0x5d>
80104588:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010458d:	eb e9                	jmp    80104578 <sys_write+0x5d>

8010458f <sys_close>:
{
8010458f:	55                   	push   %ebp
80104590:	89 e5                	mov    %esp,%ebp
80104592:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
80104595:	8d 4d f0             	lea    -0x10(%ebp),%ecx
80104598:	8d 55 f4             	lea    -0xc(%ebp),%edx
8010459b:	b8 00 00 00 00       	mov    $0x0,%eax
801045a0:	e8 55 fc ff ff       	call   801041fa <argfd>
801045a5:	85 c0                	test   %eax,%eax
801045a7:	78 25                	js     801045ce <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
801045a9:	e8 9b ee ff ff       	call   80103449 <myproc>
801045ae:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045b1:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
801045b8:	00 
  fileclose(f);
801045b9:	83 ec 0c             	sub    $0xc,%esp
801045bc:	ff 75 f0             	pushl  -0x10(%ebp)
801045bf:	e8 0f c7 ff ff       	call   80100cd3 <fileclose>
  return 0;
801045c4:	83 c4 10             	add    $0x10,%esp
801045c7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801045cc:	c9                   	leave  
801045cd:	c3                   	ret    
    return -1;
801045ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045d3:	eb f7                	jmp    801045cc <sys_close+0x3d>

801045d5 <sys_fstat>:
{
801045d5:	55                   	push   %ebp
801045d6:	89 e5                	mov    %esp,%ebp
801045d8:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801045db:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801045de:	ba 00 00 00 00       	mov    $0x0,%edx
801045e3:	b8 00 00 00 00       	mov    $0x0,%eax
801045e8:	e8 0d fc ff ff       	call   801041fa <argfd>
801045ed:	85 c0                	test   %eax,%eax
801045ef:	78 2a                	js     8010461b <sys_fstat+0x46>
801045f1:	83 ec 04             	sub    $0x4,%esp
801045f4:	6a 14                	push   $0x14
801045f6:	8d 45 f0             	lea    -0x10(%ebp),%eax
801045f9:	50                   	push   %eax
801045fa:	6a 01                	push   $0x1
801045fc:	e8 09 fb ff ff       	call   8010410a <argptr>
80104601:	83 c4 10             	add    $0x10,%esp
80104604:	85 c0                	test   %eax,%eax
80104606:	78 1a                	js     80104622 <sys_fstat+0x4d>
  return filestat(f, st);
80104608:	83 ec 08             	sub    $0x8,%esp
8010460b:	ff 75 f0             	pushl  -0x10(%ebp)
8010460e:	ff 75 f4             	pushl  -0xc(%ebp)
80104611:	e8 7a c7 ff ff       	call   80100d90 <filestat>
80104616:	83 c4 10             	add    $0x10,%esp
}
80104619:	c9                   	leave  
8010461a:	c3                   	ret    
    return -1;
8010461b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104620:	eb f7                	jmp    80104619 <sys_fstat+0x44>
80104622:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104627:	eb f0                	jmp    80104619 <sys_fstat+0x44>

80104629 <sys_link>:
{
80104629:	55                   	push   %ebp
8010462a:	89 e5                	mov    %esp,%ebp
8010462c:	56                   	push   %esi
8010462d:	53                   	push   %ebx
8010462e:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80104631:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104634:	50                   	push   %eax
80104635:	6a 00                	push   $0x0
80104637:	e8 36 fb ff ff       	call   80104172 <argstr>
8010463c:	83 c4 10             	add    $0x10,%esp
8010463f:	85 c0                	test   %eax,%eax
80104641:	0f 88 32 01 00 00    	js     80104779 <sys_link+0x150>
80104647:	83 ec 08             	sub    $0x8,%esp
8010464a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010464d:	50                   	push   %eax
8010464e:	6a 01                	push   $0x1
80104650:	e8 1d fb ff ff       	call   80104172 <argstr>
80104655:	83 c4 10             	add    $0x10,%esp
80104658:	85 c0                	test   %eax,%eax
8010465a:	0f 88 20 01 00 00    	js     80104780 <sys_link+0x157>
  begin_op();
80104660:	e8 94 e3 ff ff       	call   801029f9 <begin_op>
  if((ip = namei(old)) == 0){
80104665:	83 ec 0c             	sub    $0xc,%esp
80104668:	ff 75 e0             	pushl  -0x20(%ebp)
8010466b:	e8 71 d5 ff ff       	call   80101be1 <namei>
80104670:	89 c3                	mov    %eax,%ebx
80104672:	83 c4 10             	add    $0x10,%esp
80104675:	85 c0                	test   %eax,%eax
80104677:	0f 84 99 00 00 00    	je     80104716 <sys_link+0xed>
  ilock(ip);
8010467d:	83 ec 0c             	sub    $0xc,%esp
80104680:	50                   	push   %eax
80104681:	e8 fb ce ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
80104686:	83 c4 10             	add    $0x10,%esp
80104689:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010468e:	0f 84 8e 00 00 00    	je     80104722 <sys_link+0xf9>
  ip->nlink++;
80104694:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104698:	83 c0 01             	add    $0x1,%eax
8010469b:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
8010469f:	83 ec 0c             	sub    $0xc,%esp
801046a2:	53                   	push   %ebx
801046a3:	e8 78 cd ff ff       	call   80101420 <iupdate>
  iunlock(ip);
801046a8:	89 1c 24             	mov    %ebx,(%esp)
801046ab:	e8 93 cf ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
801046b0:	83 c4 08             	add    $0x8,%esp
801046b3:	8d 45 ea             	lea    -0x16(%ebp),%eax
801046b6:	50                   	push   %eax
801046b7:	ff 75 e4             	pushl  -0x1c(%ebp)
801046ba:	e8 3a d5 ff ff       	call   80101bf9 <nameiparent>
801046bf:	89 c6                	mov    %eax,%esi
801046c1:	83 c4 10             	add    $0x10,%esp
801046c4:	85 c0                	test   %eax,%eax
801046c6:	74 7e                	je     80104746 <sys_link+0x11d>
  ilock(dp);
801046c8:	83 ec 0c             	sub    $0xc,%esp
801046cb:	50                   	push   %eax
801046cc:	e8 b0 ce ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801046d1:	83 c4 10             	add    $0x10,%esp
801046d4:	8b 03                	mov    (%ebx),%eax
801046d6:	39 06                	cmp    %eax,(%esi)
801046d8:	75 60                	jne    8010473a <sys_link+0x111>
801046da:	83 ec 04             	sub    $0x4,%esp
801046dd:	ff 73 04             	pushl  0x4(%ebx)
801046e0:	8d 45 ea             	lea    -0x16(%ebp),%eax
801046e3:	50                   	push   %eax
801046e4:	56                   	push   %esi
801046e5:	e8 46 d4 ff ff       	call   80101b30 <dirlink>
801046ea:	83 c4 10             	add    $0x10,%esp
801046ed:	85 c0                	test   %eax,%eax
801046ef:	78 49                	js     8010473a <sys_link+0x111>
  iunlockput(dp);
801046f1:	83 ec 0c             	sub    $0xc,%esp
801046f4:	56                   	push   %esi
801046f5:	e8 2e d0 ff ff       	call   80101728 <iunlockput>
  iput(ip);
801046fa:	89 1c 24             	mov    %ebx,(%esp)
801046fd:	e8 86 cf ff ff       	call   80101688 <iput>
  end_op();
80104702:	e8 6c e3 ff ff       	call   80102a73 <end_op>
  return 0;
80104707:	83 c4 10             	add    $0x10,%esp
8010470a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010470f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104712:	5b                   	pop    %ebx
80104713:	5e                   	pop    %esi
80104714:	5d                   	pop    %ebp
80104715:	c3                   	ret    
    end_op();
80104716:	e8 58 e3 ff ff       	call   80102a73 <end_op>
    return -1;
8010471b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104720:	eb ed                	jmp    8010470f <sys_link+0xe6>
    iunlockput(ip);
80104722:	83 ec 0c             	sub    $0xc,%esp
80104725:	53                   	push   %ebx
80104726:	e8 fd cf ff ff       	call   80101728 <iunlockput>
    end_op();
8010472b:	e8 43 e3 ff ff       	call   80102a73 <end_op>
    return -1;
80104730:	83 c4 10             	add    $0x10,%esp
80104733:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104738:	eb d5                	jmp    8010470f <sys_link+0xe6>
    iunlockput(dp);
8010473a:	83 ec 0c             	sub    $0xc,%esp
8010473d:	56                   	push   %esi
8010473e:	e8 e5 cf ff ff       	call   80101728 <iunlockput>
    goto bad;
80104743:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
80104746:	83 ec 0c             	sub    $0xc,%esp
80104749:	53                   	push   %ebx
8010474a:	e8 32 ce ff ff       	call   80101581 <ilock>
  ip->nlink--;
8010474f:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104753:	83 e8 01             	sub    $0x1,%eax
80104756:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
8010475a:	89 1c 24             	mov    %ebx,(%esp)
8010475d:	e8 be cc ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104762:	89 1c 24             	mov    %ebx,(%esp)
80104765:	e8 be cf ff ff       	call   80101728 <iunlockput>
  end_op();
8010476a:	e8 04 e3 ff ff       	call   80102a73 <end_op>
  return -1;
8010476f:	83 c4 10             	add    $0x10,%esp
80104772:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104777:	eb 96                	jmp    8010470f <sys_link+0xe6>
    return -1;
80104779:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010477e:	eb 8f                	jmp    8010470f <sys_link+0xe6>
80104780:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104785:	eb 88                	jmp    8010470f <sys_link+0xe6>

80104787 <sys_unlink>:
{
80104787:	55                   	push   %ebp
80104788:	89 e5                	mov    %esp,%ebp
8010478a:	57                   	push   %edi
8010478b:	56                   	push   %esi
8010478c:	53                   	push   %ebx
8010478d:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
80104790:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104793:	50                   	push   %eax
80104794:	6a 00                	push   $0x0
80104796:	e8 d7 f9 ff ff       	call   80104172 <argstr>
8010479b:	83 c4 10             	add    $0x10,%esp
8010479e:	85 c0                	test   %eax,%eax
801047a0:	0f 88 83 01 00 00    	js     80104929 <sys_unlink+0x1a2>
  begin_op();
801047a6:	e8 4e e2 ff ff       	call   801029f9 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
801047ab:	83 ec 08             	sub    $0x8,%esp
801047ae:	8d 45 ca             	lea    -0x36(%ebp),%eax
801047b1:	50                   	push   %eax
801047b2:	ff 75 c4             	pushl  -0x3c(%ebp)
801047b5:	e8 3f d4 ff ff       	call   80101bf9 <nameiparent>
801047ba:	89 c6                	mov    %eax,%esi
801047bc:	83 c4 10             	add    $0x10,%esp
801047bf:	85 c0                	test   %eax,%eax
801047c1:	0f 84 ed 00 00 00    	je     801048b4 <sys_unlink+0x12d>
  ilock(dp);
801047c7:	83 ec 0c             	sub    $0xc,%esp
801047ca:	50                   	push   %eax
801047cb:	e8 b1 cd ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801047d0:	83 c4 08             	add    $0x8,%esp
801047d3:	68 7e 6e 10 80       	push   $0x80106e7e
801047d8:	8d 45 ca             	lea    -0x36(%ebp),%eax
801047db:	50                   	push   %eax
801047dc:	e8 ba d1 ff ff       	call   8010199b <namecmp>
801047e1:	83 c4 10             	add    $0x10,%esp
801047e4:	85 c0                	test   %eax,%eax
801047e6:	0f 84 fc 00 00 00    	je     801048e8 <sys_unlink+0x161>
801047ec:	83 ec 08             	sub    $0x8,%esp
801047ef:	68 7d 6e 10 80       	push   $0x80106e7d
801047f4:	8d 45 ca             	lea    -0x36(%ebp),%eax
801047f7:	50                   	push   %eax
801047f8:	e8 9e d1 ff ff       	call   8010199b <namecmp>
801047fd:	83 c4 10             	add    $0x10,%esp
80104800:	85 c0                	test   %eax,%eax
80104802:	0f 84 e0 00 00 00    	je     801048e8 <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
80104808:	83 ec 04             	sub    $0x4,%esp
8010480b:	8d 45 c0             	lea    -0x40(%ebp),%eax
8010480e:	50                   	push   %eax
8010480f:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104812:	50                   	push   %eax
80104813:	56                   	push   %esi
80104814:	e8 97 d1 ff ff       	call   801019b0 <dirlookup>
80104819:	89 c3                	mov    %eax,%ebx
8010481b:	83 c4 10             	add    $0x10,%esp
8010481e:	85 c0                	test   %eax,%eax
80104820:	0f 84 c2 00 00 00    	je     801048e8 <sys_unlink+0x161>
  ilock(ip);
80104826:	83 ec 0c             	sub    $0xc,%esp
80104829:	50                   	push   %eax
8010482a:	e8 52 cd ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
8010482f:	83 c4 10             	add    $0x10,%esp
80104832:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
80104837:	0f 8e 83 00 00 00    	jle    801048c0 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010483d:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104842:	0f 84 85 00 00 00    	je     801048cd <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
80104848:	83 ec 04             	sub    $0x4,%esp
8010484b:	6a 10                	push   $0x10
8010484d:	6a 00                	push   $0x0
8010484f:	8d 7d d8             	lea    -0x28(%ebp),%edi
80104852:	57                   	push   %edi
80104853:	e8 3f f6 ff ff       	call   80103e97 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104858:	6a 10                	push   $0x10
8010485a:	ff 75 c0             	pushl  -0x40(%ebp)
8010485d:	57                   	push   %edi
8010485e:	56                   	push   %esi
8010485f:	e8 0c d0 ff ff       	call   80101870 <writei>
80104864:	83 c4 20             	add    $0x20,%esp
80104867:	83 f8 10             	cmp    $0x10,%eax
8010486a:	0f 85 90 00 00 00    	jne    80104900 <sys_unlink+0x179>
  if(ip->type == T_DIR){
80104870:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104875:	0f 84 92 00 00 00    	je     8010490d <sys_unlink+0x186>
  iunlockput(dp);
8010487b:	83 ec 0c             	sub    $0xc,%esp
8010487e:	56                   	push   %esi
8010487f:	e8 a4 ce ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
80104884:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104888:	83 e8 01             	sub    $0x1,%eax
8010488b:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
8010488f:	89 1c 24             	mov    %ebx,(%esp)
80104892:	e8 89 cb ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104897:	89 1c 24             	mov    %ebx,(%esp)
8010489a:	e8 89 ce ff ff       	call   80101728 <iunlockput>
  end_op();
8010489f:	e8 cf e1 ff ff       	call   80102a73 <end_op>
  return 0;
801048a4:	83 c4 10             	add    $0x10,%esp
801048a7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801048ac:	8d 65 f4             	lea    -0xc(%ebp),%esp
801048af:	5b                   	pop    %ebx
801048b0:	5e                   	pop    %esi
801048b1:	5f                   	pop    %edi
801048b2:	5d                   	pop    %ebp
801048b3:	c3                   	ret    
    end_op();
801048b4:	e8 ba e1 ff ff       	call   80102a73 <end_op>
    return -1;
801048b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048be:	eb ec                	jmp    801048ac <sys_unlink+0x125>
    panic("unlink: nlink < 1");
801048c0:	83 ec 0c             	sub    $0xc,%esp
801048c3:	68 9c 6e 10 80       	push   $0x80106e9c
801048c8:	e8 7b ba ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801048cd:	89 d8                	mov    %ebx,%eax
801048cf:	e8 c4 f9 ff ff       	call   80104298 <isdirempty>
801048d4:	85 c0                	test   %eax,%eax
801048d6:	0f 85 6c ff ff ff    	jne    80104848 <sys_unlink+0xc1>
    iunlockput(ip);
801048dc:	83 ec 0c             	sub    $0xc,%esp
801048df:	53                   	push   %ebx
801048e0:	e8 43 ce ff ff       	call   80101728 <iunlockput>
    goto bad;
801048e5:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
801048e8:	83 ec 0c             	sub    $0xc,%esp
801048eb:	56                   	push   %esi
801048ec:	e8 37 ce ff ff       	call   80101728 <iunlockput>
  end_op();
801048f1:	e8 7d e1 ff ff       	call   80102a73 <end_op>
  return -1;
801048f6:	83 c4 10             	add    $0x10,%esp
801048f9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048fe:	eb ac                	jmp    801048ac <sys_unlink+0x125>
    panic("unlink: writei");
80104900:	83 ec 0c             	sub    $0xc,%esp
80104903:	68 ae 6e 10 80       	push   $0x80106eae
80104908:	e8 3b ba ff ff       	call   80100348 <panic>
    dp->nlink--;
8010490d:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104911:	83 e8 01             	sub    $0x1,%eax
80104914:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
80104918:	83 ec 0c             	sub    $0xc,%esp
8010491b:	56                   	push   %esi
8010491c:	e8 ff ca ff ff       	call   80101420 <iupdate>
80104921:	83 c4 10             	add    $0x10,%esp
80104924:	e9 52 ff ff ff       	jmp    8010487b <sys_unlink+0xf4>
    return -1;
80104929:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010492e:	e9 79 ff ff ff       	jmp    801048ac <sys_unlink+0x125>

80104933 <sys_open>:

int
sys_open(void)
{
80104933:	55                   	push   %ebp
80104934:	89 e5                	mov    %esp,%ebp
80104936:	57                   	push   %edi
80104937:	56                   	push   %esi
80104938:	53                   	push   %ebx
80104939:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
8010493c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010493f:	50                   	push   %eax
80104940:	6a 00                	push   $0x0
80104942:	e8 2b f8 ff ff       	call   80104172 <argstr>
80104947:	83 c4 10             	add    $0x10,%esp
8010494a:	85 c0                	test   %eax,%eax
8010494c:	0f 88 30 01 00 00    	js     80104a82 <sys_open+0x14f>
80104952:	83 ec 08             	sub    $0x8,%esp
80104955:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104958:	50                   	push   %eax
80104959:	6a 01                	push   $0x1
8010495b:	e8 82 f7 ff ff       	call   801040e2 <argint>
80104960:	83 c4 10             	add    $0x10,%esp
80104963:	85 c0                	test   %eax,%eax
80104965:	0f 88 21 01 00 00    	js     80104a8c <sys_open+0x159>
    return -1;

  begin_op();
8010496b:	e8 89 e0 ff ff       	call   801029f9 <begin_op>

  if(omode & O_CREATE){
80104970:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
80104974:	0f 84 84 00 00 00    	je     801049fe <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
8010497a:	83 ec 0c             	sub    $0xc,%esp
8010497d:	6a 00                	push   $0x0
8010497f:	b9 00 00 00 00       	mov    $0x0,%ecx
80104984:	ba 02 00 00 00       	mov    $0x2,%edx
80104989:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010498c:	e8 5e f9 ff ff       	call   801042ef <create>
80104991:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104993:	83 c4 10             	add    $0x10,%esp
80104996:	85 c0                	test   %eax,%eax
80104998:	74 58                	je     801049f2 <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
8010499a:	e8 8e c2 ff ff       	call   80100c2d <filealloc>
8010499f:	89 c3                	mov    %eax,%ebx
801049a1:	85 c0                	test   %eax,%eax
801049a3:	0f 84 ae 00 00 00    	je     80104a57 <sys_open+0x124>
801049a9:	e8 b3 f8 ff ff       	call   80104261 <fdalloc>
801049ae:	89 c7                	mov    %eax,%edi
801049b0:	85 c0                	test   %eax,%eax
801049b2:	0f 88 9f 00 00 00    	js     80104a57 <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
801049b8:	83 ec 0c             	sub    $0xc,%esp
801049bb:	56                   	push   %esi
801049bc:	e8 82 cc ff ff       	call   80101643 <iunlock>
  end_op();
801049c1:	e8 ad e0 ff ff       	call   80102a73 <end_op>

  f->type = FD_INODE;
801049c6:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
801049cc:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
801049cf:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
801049d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801049d9:	83 c4 10             	add    $0x10,%esp
801049dc:	a8 01                	test   $0x1,%al
801049de:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
801049e2:	a8 03                	test   $0x3,%al
801049e4:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
801049e8:	89 f8                	mov    %edi,%eax
801049ea:	8d 65 f4             	lea    -0xc(%ebp),%esp
801049ed:	5b                   	pop    %ebx
801049ee:	5e                   	pop    %esi
801049ef:	5f                   	pop    %edi
801049f0:	5d                   	pop    %ebp
801049f1:	c3                   	ret    
      end_op();
801049f2:	e8 7c e0 ff ff       	call   80102a73 <end_op>
      return -1;
801049f7:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801049fc:	eb ea                	jmp    801049e8 <sys_open+0xb5>
    if((ip = namei(path)) == 0){
801049fe:	83 ec 0c             	sub    $0xc,%esp
80104a01:	ff 75 e4             	pushl  -0x1c(%ebp)
80104a04:	e8 d8 d1 ff ff       	call   80101be1 <namei>
80104a09:	89 c6                	mov    %eax,%esi
80104a0b:	83 c4 10             	add    $0x10,%esp
80104a0e:	85 c0                	test   %eax,%eax
80104a10:	74 39                	je     80104a4b <sys_open+0x118>
    ilock(ip);
80104a12:	83 ec 0c             	sub    $0xc,%esp
80104a15:	50                   	push   %eax
80104a16:	e8 66 cb ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80104a1b:	83 c4 10             	add    $0x10,%esp
80104a1e:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104a23:	0f 85 71 ff ff ff    	jne    8010499a <sys_open+0x67>
80104a29:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104a2d:	0f 84 67 ff ff ff    	je     8010499a <sys_open+0x67>
      iunlockput(ip);
80104a33:	83 ec 0c             	sub    $0xc,%esp
80104a36:	56                   	push   %esi
80104a37:	e8 ec cc ff ff       	call   80101728 <iunlockput>
      end_op();
80104a3c:	e8 32 e0 ff ff       	call   80102a73 <end_op>
      return -1;
80104a41:	83 c4 10             	add    $0x10,%esp
80104a44:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a49:	eb 9d                	jmp    801049e8 <sys_open+0xb5>
      end_op();
80104a4b:	e8 23 e0 ff ff       	call   80102a73 <end_op>
      return -1;
80104a50:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a55:	eb 91                	jmp    801049e8 <sys_open+0xb5>
    if(f)
80104a57:	85 db                	test   %ebx,%ebx
80104a59:	74 0c                	je     80104a67 <sys_open+0x134>
      fileclose(f);
80104a5b:	83 ec 0c             	sub    $0xc,%esp
80104a5e:	53                   	push   %ebx
80104a5f:	e8 6f c2 ff ff       	call   80100cd3 <fileclose>
80104a64:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104a67:	83 ec 0c             	sub    $0xc,%esp
80104a6a:	56                   	push   %esi
80104a6b:	e8 b8 cc ff ff       	call   80101728 <iunlockput>
    end_op();
80104a70:	e8 fe df ff ff       	call   80102a73 <end_op>
    return -1;
80104a75:	83 c4 10             	add    $0x10,%esp
80104a78:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a7d:	e9 66 ff ff ff       	jmp    801049e8 <sys_open+0xb5>
    return -1;
80104a82:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a87:	e9 5c ff ff ff       	jmp    801049e8 <sys_open+0xb5>
80104a8c:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a91:	e9 52 ff ff ff       	jmp    801049e8 <sys_open+0xb5>

80104a96 <sys_mkdir>:

int
sys_mkdir(void)
{
80104a96:	55                   	push   %ebp
80104a97:	89 e5                	mov    %esp,%ebp
80104a99:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104a9c:	e8 58 df ff ff       	call   801029f9 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104aa1:	83 ec 08             	sub    $0x8,%esp
80104aa4:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104aa7:	50                   	push   %eax
80104aa8:	6a 00                	push   $0x0
80104aaa:	e8 c3 f6 ff ff       	call   80104172 <argstr>
80104aaf:	83 c4 10             	add    $0x10,%esp
80104ab2:	85 c0                	test   %eax,%eax
80104ab4:	78 36                	js     80104aec <sys_mkdir+0x56>
80104ab6:	83 ec 0c             	sub    $0xc,%esp
80104ab9:	6a 00                	push   $0x0
80104abb:	b9 00 00 00 00       	mov    $0x0,%ecx
80104ac0:	ba 01 00 00 00       	mov    $0x1,%edx
80104ac5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ac8:	e8 22 f8 ff ff       	call   801042ef <create>
80104acd:	83 c4 10             	add    $0x10,%esp
80104ad0:	85 c0                	test   %eax,%eax
80104ad2:	74 18                	je     80104aec <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104ad4:	83 ec 0c             	sub    $0xc,%esp
80104ad7:	50                   	push   %eax
80104ad8:	e8 4b cc ff ff       	call   80101728 <iunlockput>
  end_op();
80104add:	e8 91 df ff ff       	call   80102a73 <end_op>
  return 0;
80104ae2:	83 c4 10             	add    $0x10,%esp
80104ae5:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104aea:	c9                   	leave  
80104aeb:	c3                   	ret    
    end_op();
80104aec:	e8 82 df ff ff       	call   80102a73 <end_op>
    return -1;
80104af1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104af6:	eb f2                	jmp    80104aea <sys_mkdir+0x54>

80104af8 <sys_mknod>:

int
sys_mknod(void)
{
80104af8:	55                   	push   %ebp
80104af9:	89 e5                	mov    %esp,%ebp
80104afb:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104afe:	e8 f6 de ff ff       	call   801029f9 <begin_op>
  if((argstr(0, &path)) < 0 ||
80104b03:	83 ec 08             	sub    $0x8,%esp
80104b06:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b09:	50                   	push   %eax
80104b0a:	6a 00                	push   $0x0
80104b0c:	e8 61 f6 ff ff       	call   80104172 <argstr>
80104b11:	83 c4 10             	add    $0x10,%esp
80104b14:	85 c0                	test   %eax,%eax
80104b16:	78 62                	js     80104b7a <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104b18:	83 ec 08             	sub    $0x8,%esp
80104b1b:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104b1e:	50                   	push   %eax
80104b1f:	6a 01                	push   $0x1
80104b21:	e8 bc f5 ff ff       	call   801040e2 <argint>
  if((argstr(0, &path)) < 0 ||
80104b26:	83 c4 10             	add    $0x10,%esp
80104b29:	85 c0                	test   %eax,%eax
80104b2b:	78 4d                	js     80104b7a <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104b2d:	83 ec 08             	sub    $0x8,%esp
80104b30:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104b33:	50                   	push   %eax
80104b34:	6a 02                	push   $0x2
80104b36:	e8 a7 f5 ff ff       	call   801040e2 <argint>
     argint(1, &major) < 0 ||
80104b3b:	83 c4 10             	add    $0x10,%esp
80104b3e:	85 c0                	test   %eax,%eax
80104b40:	78 38                	js     80104b7a <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104b42:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104b46:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104b4a:	83 ec 0c             	sub    $0xc,%esp
80104b4d:	50                   	push   %eax
80104b4e:	ba 03 00 00 00       	mov    $0x3,%edx
80104b53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b56:	e8 94 f7 ff ff       	call   801042ef <create>
80104b5b:	83 c4 10             	add    $0x10,%esp
80104b5e:	85 c0                	test   %eax,%eax
80104b60:	74 18                	je     80104b7a <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104b62:	83 ec 0c             	sub    $0xc,%esp
80104b65:	50                   	push   %eax
80104b66:	e8 bd cb ff ff       	call   80101728 <iunlockput>
  end_op();
80104b6b:	e8 03 df ff ff       	call   80102a73 <end_op>
  return 0;
80104b70:	83 c4 10             	add    $0x10,%esp
80104b73:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104b78:	c9                   	leave  
80104b79:	c3                   	ret    
    end_op();
80104b7a:	e8 f4 de ff ff       	call   80102a73 <end_op>
    return -1;
80104b7f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b84:	eb f2                	jmp    80104b78 <sys_mknod+0x80>

80104b86 <sys_chdir>:

int
sys_chdir(void)
{
80104b86:	55                   	push   %ebp
80104b87:	89 e5                	mov    %esp,%ebp
80104b89:	56                   	push   %esi
80104b8a:	53                   	push   %ebx
80104b8b:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104b8e:	e8 b6 e8 ff ff       	call   80103449 <myproc>
80104b93:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104b95:	e8 5f de ff ff       	call   801029f9 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104b9a:	83 ec 08             	sub    $0x8,%esp
80104b9d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ba0:	50                   	push   %eax
80104ba1:	6a 00                	push   $0x0
80104ba3:	e8 ca f5 ff ff       	call   80104172 <argstr>
80104ba8:	83 c4 10             	add    $0x10,%esp
80104bab:	85 c0                	test   %eax,%eax
80104bad:	78 52                	js     80104c01 <sys_chdir+0x7b>
80104baf:	83 ec 0c             	sub    $0xc,%esp
80104bb2:	ff 75 f4             	pushl  -0xc(%ebp)
80104bb5:	e8 27 d0 ff ff       	call   80101be1 <namei>
80104bba:	89 c3                	mov    %eax,%ebx
80104bbc:	83 c4 10             	add    $0x10,%esp
80104bbf:	85 c0                	test   %eax,%eax
80104bc1:	74 3e                	je     80104c01 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104bc3:	83 ec 0c             	sub    $0xc,%esp
80104bc6:	50                   	push   %eax
80104bc7:	e8 b5 c9 ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104bcc:	83 c4 10             	add    $0x10,%esp
80104bcf:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104bd4:	75 37                	jne    80104c0d <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104bd6:	83 ec 0c             	sub    $0xc,%esp
80104bd9:	53                   	push   %ebx
80104bda:	e8 64 ca ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104bdf:	83 c4 04             	add    $0x4,%esp
80104be2:	ff 76 68             	pushl  0x68(%esi)
80104be5:	e8 9e ca ff ff       	call   80101688 <iput>
  end_op();
80104bea:	e8 84 de ff ff       	call   80102a73 <end_op>
  curproc->cwd = ip;
80104bef:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104bf2:	83 c4 10             	add    $0x10,%esp
80104bf5:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104bfa:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104bfd:	5b                   	pop    %ebx
80104bfe:	5e                   	pop    %esi
80104bff:	5d                   	pop    %ebp
80104c00:	c3                   	ret    
    end_op();
80104c01:	e8 6d de ff ff       	call   80102a73 <end_op>
    return -1;
80104c06:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c0b:	eb ed                	jmp    80104bfa <sys_chdir+0x74>
    iunlockput(ip);
80104c0d:	83 ec 0c             	sub    $0xc,%esp
80104c10:	53                   	push   %ebx
80104c11:	e8 12 cb ff ff       	call   80101728 <iunlockput>
    end_op();
80104c16:	e8 58 de ff ff       	call   80102a73 <end_op>
    return -1;
80104c1b:	83 c4 10             	add    $0x10,%esp
80104c1e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c23:	eb d5                	jmp    80104bfa <sys_chdir+0x74>

80104c25 <sys_exec>:

int
sys_exec(void)
{
80104c25:	55                   	push   %ebp
80104c26:	89 e5                	mov    %esp,%ebp
80104c28:	53                   	push   %ebx
80104c29:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104c2f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c32:	50                   	push   %eax
80104c33:	6a 00                	push   $0x0
80104c35:	e8 38 f5 ff ff       	call   80104172 <argstr>
80104c3a:	83 c4 10             	add    $0x10,%esp
80104c3d:	85 c0                	test   %eax,%eax
80104c3f:	0f 88 a8 00 00 00    	js     80104ced <sys_exec+0xc8>
80104c45:	83 ec 08             	sub    $0x8,%esp
80104c48:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104c4e:	50                   	push   %eax
80104c4f:	6a 01                	push   $0x1
80104c51:	e8 8c f4 ff ff       	call   801040e2 <argint>
80104c56:	83 c4 10             	add    $0x10,%esp
80104c59:	85 c0                	test   %eax,%eax
80104c5b:	0f 88 93 00 00 00    	js     80104cf4 <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104c61:	83 ec 04             	sub    $0x4,%esp
80104c64:	68 80 00 00 00       	push   $0x80
80104c69:	6a 00                	push   $0x0
80104c6b:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104c71:	50                   	push   %eax
80104c72:	e8 20 f2 ff ff       	call   80103e97 <memset>
80104c77:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104c7a:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104c7f:	83 fb 1f             	cmp    $0x1f,%ebx
80104c82:	77 77                	ja     80104cfb <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104c84:	83 ec 08             	sub    $0x8,%esp
80104c87:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104c8d:	50                   	push   %eax
80104c8e:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104c94:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104c97:	50                   	push   %eax
80104c98:	e8 c9 f3 ff ff       	call   80104066 <fetchint>
80104c9d:	83 c4 10             	add    $0x10,%esp
80104ca0:	85 c0                	test   %eax,%eax
80104ca2:	78 5e                	js     80104d02 <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104ca4:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104caa:	85 c0                	test   %eax,%eax
80104cac:	74 1d                	je     80104ccb <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104cae:	83 ec 08             	sub    $0x8,%esp
80104cb1:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104cb8:	52                   	push   %edx
80104cb9:	50                   	push   %eax
80104cba:	e8 e3 f3 ff ff       	call   801040a2 <fetchstr>
80104cbf:	83 c4 10             	add    $0x10,%esp
80104cc2:	85 c0                	test   %eax,%eax
80104cc4:	78 46                	js     80104d0c <sys_exec+0xe7>
  for(i=0;; i++){
80104cc6:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104cc9:	eb b4                	jmp    80104c7f <sys_exec+0x5a>
      argv[i] = 0;
80104ccb:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104cd2:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104cd6:	83 ec 08             	sub    $0x8,%esp
80104cd9:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104cdf:	50                   	push   %eax
80104ce0:	ff 75 f4             	pushl  -0xc(%ebp)
80104ce3:	e8 ea bb ff ff       	call   801008d2 <exec>
80104ce8:	83 c4 10             	add    $0x10,%esp
80104ceb:	eb 1a                	jmp    80104d07 <sys_exec+0xe2>
    return -1;
80104ced:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cf2:	eb 13                	jmp    80104d07 <sys_exec+0xe2>
80104cf4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cf9:	eb 0c                	jmp    80104d07 <sys_exec+0xe2>
      return -1;
80104cfb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d00:	eb 05                	jmp    80104d07 <sys_exec+0xe2>
      return -1;
80104d02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104d07:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104d0a:	c9                   	leave  
80104d0b:	c3                   	ret    
      return -1;
80104d0c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d11:	eb f4                	jmp    80104d07 <sys_exec+0xe2>

80104d13 <sys_pipe>:

int
sys_pipe(void)
{
80104d13:	55                   	push   %ebp
80104d14:	89 e5                	mov    %esp,%ebp
80104d16:	53                   	push   %ebx
80104d17:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104d1a:	6a 08                	push   $0x8
80104d1c:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d1f:	50                   	push   %eax
80104d20:	6a 00                	push   $0x0
80104d22:	e8 e3 f3 ff ff       	call   8010410a <argptr>
80104d27:	83 c4 10             	add    $0x10,%esp
80104d2a:	85 c0                	test   %eax,%eax
80104d2c:	78 77                	js     80104da5 <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104d2e:	83 ec 08             	sub    $0x8,%esp
80104d31:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104d34:	50                   	push   %eax
80104d35:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104d38:	50                   	push   %eax
80104d39:	e8 42 e2 ff ff       	call   80102f80 <pipealloc>
80104d3e:	83 c4 10             	add    $0x10,%esp
80104d41:	85 c0                	test   %eax,%eax
80104d43:	78 67                	js     80104dac <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104d45:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d48:	e8 14 f5 ff ff       	call   80104261 <fdalloc>
80104d4d:	89 c3                	mov    %eax,%ebx
80104d4f:	85 c0                	test   %eax,%eax
80104d51:	78 21                	js     80104d74 <sys_pipe+0x61>
80104d53:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104d56:	e8 06 f5 ff ff       	call   80104261 <fdalloc>
80104d5b:	85 c0                	test   %eax,%eax
80104d5d:	78 15                	js     80104d74 <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104d5f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d62:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104d64:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104d67:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104d6a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104d6f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104d72:	c9                   	leave  
80104d73:	c3                   	ret    
    if(fd0 >= 0)
80104d74:	85 db                	test   %ebx,%ebx
80104d76:	78 0d                	js     80104d85 <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104d78:	e8 cc e6 ff ff       	call   80103449 <myproc>
80104d7d:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104d84:	00 
    fileclose(rf);
80104d85:	83 ec 0c             	sub    $0xc,%esp
80104d88:	ff 75 f0             	pushl  -0x10(%ebp)
80104d8b:	e8 43 bf ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104d90:	83 c4 04             	add    $0x4,%esp
80104d93:	ff 75 ec             	pushl  -0x14(%ebp)
80104d96:	e8 38 bf ff ff       	call   80100cd3 <fileclose>
    return -1;
80104d9b:	83 c4 10             	add    $0x10,%esp
80104d9e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104da3:	eb ca                	jmp    80104d6f <sys_pipe+0x5c>
    return -1;
80104da5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104daa:	eb c3                	jmp    80104d6f <sys_pipe+0x5c>
    return -1;
80104dac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104db1:	eb bc                	jmp    80104d6f <sys_pipe+0x5c>

80104db3 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104db3:	55                   	push   %ebp
80104db4:	89 e5                	mov    %esp,%ebp
80104db6:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104db9:	e8 03 e8 ff ff       	call   801035c1 <fork>
}
80104dbe:	c9                   	leave  
80104dbf:	c3                   	ret    

80104dc0 <sys_exit>:

int
sys_exit(void)
{
80104dc0:	55                   	push   %ebp
80104dc1:	89 e5                	mov    %esp,%ebp
80104dc3:	83 ec 08             	sub    $0x8,%esp
  exit();
80104dc6:	e8 2d ea ff ff       	call   801037f8 <exit>
  return 0;  // not reached
}
80104dcb:	b8 00 00 00 00       	mov    $0x0,%eax
80104dd0:	c9                   	leave  
80104dd1:	c3                   	ret    

80104dd2 <sys_wait>:

int
sys_wait(void)
{
80104dd2:	55                   	push   %ebp
80104dd3:	89 e5                	mov    %esp,%ebp
80104dd5:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104dd8:	e8 a4 eb ff ff       	call   80103981 <wait>
}
80104ddd:	c9                   	leave  
80104dde:	c3                   	ret    

80104ddf <sys_kill>:

int
sys_kill(void)
{
80104ddf:	55                   	push   %ebp
80104de0:	89 e5                	mov    %esp,%ebp
80104de2:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104de5:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104de8:	50                   	push   %eax
80104de9:	6a 00                	push   $0x0
80104deb:	e8 f2 f2 ff ff       	call   801040e2 <argint>
80104df0:	83 c4 10             	add    $0x10,%esp
80104df3:	85 c0                	test   %eax,%eax
80104df5:	78 10                	js     80104e07 <sys_kill+0x28>
    return -1;
  return kill(pid);
80104df7:	83 ec 0c             	sub    $0xc,%esp
80104dfa:	ff 75 f4             	pushl  -0xc(%ebp)
80104dfd:	e8 7c ec ff ff       	call   80103a7e <kill>
80104e02:	83 c4 10             	add    $0x10,%esp
}
80104e05:	c9                   	leave  
80104e06:	c3                   	ret    
    return -1;
80104e07:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e0c:	eb f7                	jmp    80104e05 <sys_kill+0x26>

80104e0e <sys_getpid>:

int
sys_getpid(void)
{
80104e0e:	55                   	push   %ebp
80104e0f:	89 e5                	mov    %esp,%ebp
80104e11:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104e14:	e8 30 e6 ff ff       	call   80103449 <myproc>
80104e19:	8b 40 10             	mov    0x10(%eax),%eax
}
80104e1c:	c9                   	leave  
80104e1d:	c3                   	ret    

80104e1e <sys_sbrk>:

int
sys_sbrk(void)
{
80104e1e:	55                   	push   %ebp
80104e1f:	89 e5                	mov    %esp,%ebp
80104e21:	53                   	push   %ebx
80104e22:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104e25:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e28:	50                   	push   %eax
80104e29:	6a 00                	push   $0x0
80104e2b:	e8 b2 f2 ff ff       	call   801040e2 <argint>
80104e30:	83 c4 10             	add    $0x10,%esp
80104e33:	85 c0                	test   %eax,%eax
80104e35:	78 27                	js     80104e5e <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104e37:	e8 0d e6 ff ff       	call   80103449 <myproc>
80104e3c:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104e3e:	83 ec 0c             	sub    $0xc,%esp
80104e41:	ff 75 f4             	pushl  -0xc(%ebp)
80104e44:	e8 0b e7 ff ff       	call   80103554 <growproc>
80104e49:	83 c4 10             	add    $0x10,%esp
80104e4c:	85 c0                	test   %eax,%eax
80104e4e:	78 07                	js     80104e57 <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104e50:	89 d8                	mov    %ebx,%eax
80104e52:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e55:	c9                   	leave  
80104e56:	c3                   	ret    
    return -1;
80104e57:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104e5c:	eb f2                	jmp    80104e50 <sys_sbrk+0x32>
    return -1;
80104e5e:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104e63:	eb eb                	jmp    80104e50 <sys_sbrk+0x32>

80104e65 <sys_sleep>:

int
sys_sleep(void)
{
80104e65:	55                   	push   %ebp
80104e66:	89 e5                	mov    %esp,%ebp
80104e68:	53                   	push   %ebx
80104e69:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104e6c:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e6f:	50                   	push   %eax
80104e70:	6a 00                	push   $0x0
80104e72:	e8 6b f2 ff ff       	call   801040e2 <argint>
80104e77:	83 c4 10             	add    $0x10,%esp
80104e7a:	85 c0                	test   %eax,%eax
80104e7c:	78 75                	js     80104ef3 <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104e7e:	83 ec 0c             	sub    $0xc,%esp
80104e81:	68 a0 4c 13 80       	push   $0x80134ca0
80104e86:	e8 60 ef ff ff       	call   80103deb <acquire>
  ticks0 = ticks;
80104e8b:	8b 1d e0 54 13 80    	mov    0x801354e0,%ebx
  while(ticks - ticks0 < n){
80104e91:	83 c4 10             	add    $0x10,%esp
80104e94:	a1 e0 54 13 80       	mov    0x801354e0,%eax
80104e99:	29 d8                	sub    %ebx,%eax
80104e9b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104e9e:	73 39                	jae    80104ed9 <sys_sleep+0x74>
    if(myproc()->killed){
80104ea0:	e8 a4 e5 ff ff       	call   80103449 <myproc>
80104ea5:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104ea9:	75 17                	jne    80104ec2 <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104eab:	83 ec 08             	sub    $0x8,%esp
80104eae:	68 a0 4c 13 80       	push   $0x80134ca0
80104eb3:	68 e0 54 13 80       	push   $0x801354e0
80104eb8:	e8 33 ea ff ff       	call   801038f0 <sleep>
80104ebd:	83 c4 10             	add    $0x10,%esp
80104ec0:	eb d2                	jmp    80104e94 <sys_sleep+0x2f>
      release(&tickslock);
80104ec2:	83 ec 0c             	sub    $0xc,%esp
80104ec5:	68 a0 4c 13 80       	push   $0x80134ca0
80104eca:	e8 81 ef ff ff       	call   80103e50 <release>
      return -1;
80104ecf:	83 c4 10             	add    $0x10,%esp
80104ed2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ed7:	eb 15                	jmp    80104eee <sys_sleep+0x89>
  }
  release(&tickslock);
80104ed9:	83 ec 0c             	sub    $0xc,%esp
80104edc:	68 a0 4c 13 80       	push   $0x80134ca0
80104ee1:	e8 6a ef ff ff       	call   80103e50 <release>
  return 0;
80104ee6:	83 c4 10             	add    $0x10,%esp
80104ee9:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104eee:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104ef1:	c9                   	leave  
80104ef2:	c3                   	ret    
    return -1;
80104ef3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ef8:	eb f4                	jmp    80104eee <sys_sleep+0x89>

80104efa <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104efa:	55                   	push   %ebp
80104efb:	89 e5                	mov    %esp,%ebp
80104efd:	53                   	push   %ebx
80104efe:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104f01:	68 a0 4c 13 80       	push   $0x80134ca0
80104f06:	e8 e0 ee ff ff       	call   80103deb <acquire>
  xticks = ticks;
80104f0b:	8b 1d e0 54 13 80    	mov    0x801354e0,%ebx
  release(&tickslock);
80104f11:	c7 04 24 a0 4c 13 80 	movl   $0x80134ca0,(%esp)
80104f18:	e8 33 ef ff ff       	call   80103e50 <release>
  return xticks;
}
80104f1d:	89 d8                	mov    %ebx,%eax
80104f1f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104f22:	c9                   	leave  
80104f23:	c3                   	ret    

80104f24 <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80104f24:	55                   	push   %ebp
80104f25:	89 e5                	mov    %esp,%ebp
80104f27:	83 ec 1c             	sub    $0x1c,%esp
  int *frames;
  int *pids;
  int numframes;
  if(argptr(0, (char**)(&frames), sizeof(*frames)) < 0)
80104f2a:	6a 04                	push   $0x4
80104f2c:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104f2f:	50                   	push   %eax
80104f30:	6a 00                	push   $0x0
80104f32:	e8 d3 f1 ff ff       	call   8010410a <argptr>
80104f37:	83 c4 10             	add    $0x10,%esp
80104f3a:	85 c0                	test   %eax,%eax
80104f3c:	78 42                	js     80104f80 <sys_dump_physmem+0x5c>
    return -1;
  if(argptr(1, (char**)(&pids), sizeof(*pids)) < 0)
80104f3e:	83 ec 04             	sub    $0x4,%esp
80104f41:	6a 04                	push   $0x4
80104f43:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104f46:	50                   	push   %eax
80104f47:	6a 01                	push   $0x1
80104f49:	e8 bc f1 ff ff       	call   8010410a <argptr>
80104f4e:	83 c4 10             	add    $0x10,%esp
80104f51:	85 c0                	test   %eax,%eax
80104f53:	78 32                	js     80104f87 <sys_dump_physmem+0x63>
    return -1;
  if(argint(2, &numframes) < 0)
80104f55:	83 ec 08             	sub    $0x8,%esp
80104f58:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104f5b:	50                   	push   %eax
80104f5c:	6a 02                	push   $0x2
80104f5e:	e8 7f f1 ff ff       	call   801040e2 <argint>
80104f63:	83 c4 10             	add    $0x10,%esp
80104f66:	85 c0                	test   %eax,%eax
80104f68:	78 24                	js     80104f8e <sys_dump_physmem+0x6a>
    return -1;

  return dump_physmem(frames, pids, numframes);
80104f6a:	83 ec 04             	sub    $0x4,%esp
80104f6d:	ff 75 ec             	pushl  -0x14(%ebp)
80104f70:	ff 75 f0             	pushl  -0x10(%ebp)
80104f73:	ff 75 f4             	pushl  -0xc(%ebp)
80104f76:	e8 7e d3 ff ff       	call   801022f9 <dump_physmem>
80104f7b:	83 c4 10             	add    $0x10,%esp
80104f7e:	c9                   	leave  
80104f7f:	c3                   	ret    
    return -1;
80104f80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f85:	eb f7                	jmp    80104f7e <sys_dump_physmem+0x5a>
    return -1;
80104f87:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f8c:	eb f0                	jmp    80104f7e <sys_dump_physmem+0x5a>
    return -1;
80104f8e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f93:	eb e9                	jmp    80104f7e <sys_dump_physmem+0x5a>

80104f95 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104f95:	1e                   	push   %ds
  pushl %es
80104f96:	06                   	push   %es
  pushl %fs
80104f97:	0f a0                	push   %fs
  pushl %gs
80104f99:	0f a8                	push   %gs
  pushal
80104f9b:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104f9c:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104fa0:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104fa2:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104fa4:	54                   	push   %esp
  call trap
80104fa5:	e8 e3 00 00 00       	call   8010508d <trap>
  addl $4, %esp
80104faa:	83 c4 04             	add    $0x4,%esp

80104fad <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104fad:	61                   	popa   
  popl %gs
80104fae:	0f a9                	pop    %gs
  popl %fs
80104fb0:	0f a1                	pop    %fs
  popl %es
80104fb2:	07                   	pop    %es
  popl %ds
80104fb3:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104fb4:	83 c4 08             	add    $0x8,%esp
  iret
80104fb7:	cf                   	iret   

80104fb8 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80104fb8:	55                   	push   %ebp
80104fb9:	89 e5                	mov    %esp,%ebp
80104fbb:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
80104fbe:	b8 00 00 00 00       	mov    $0x0,%eax
80104fc3:	eb 4a                	jmp    8010500f <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104fc5:	8b 0c 85 08 a0 12 80 	mov    -0x7fed5ff8(,%eax,4),%ecx
80104fcc:	66 89 0c c5 e0 4c 13 	mov    %cx,-0x7fecb320(,%eax,8)
80104fd3:	80 
80104fd4:	66 c7 04 c5 e2 4c 13 	movw   $0x8,-0x7fecb31e(,%eax,8)
80104fdb:	80 08 00 
80104fde:	c6 04 c5 e4 4c 13 80 	movb   $0x0,-0x7fecb31c(,%eax,8)
80104fe5:	00 
80104fe6:	0f b6 14 c5 e5 4c 13 	movzbl -0x7fecb31b(,%eax,8),%edx
80104fed:	80 
80104fee:	83 e2 f0             	and    $0xfffffff0,%edx
80104ff1:	83 ca 0e             	or     $0xe,%edx
80104ff4:	83 e2 8f             	and    $0xffffff8f,%edx
80104ff7:	83 ca 80             	or     $0xffffff80,%edx
80104ffa:	88 14 c5 e5 4c 13 80 	mov    %dl,-0x7fecb31b(,%eax,8)
80105001:	c1 e9 10             	shr    $0x10,%ecx
80105004:	66 89 0c c5 e6 4c 13 	mov    %cx,-0x7fecb31a(,%eax,8)
8010500b:	80 
  for(i = 0; i < 256; i++)
8010500c:	83 c0 01             	add    $0x1,%eax
8010500f:	3d ff 00 00 00       	cmp    $0xff,%eax
80105014:	7e af                	jle    80104fc5 <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80105016:	8b 15 08 a1 12 80    	mov    0x8012a108,%edx
8010501c:	66 89 15 e0 4e 13 80 	mov    %dx,0x80134ee0
80105023:	66 c7 05 e2 4e 13 80 	movw   $0x8,0x80134ee2
8010502a:	08 00 
8010502c:	c6 05 e4 4e 13 80 00 	movb   $0x0,0x80134ee4
80105033:	0f b6 05 e5 4e 13 80 	movzbl 0x80134ee5,%eax
8010503a:	83 c8 0f             	or     $0xf,%eax
8010503d:	83 e0 ef             	and    $0xffffffef,%eax
80105040:	83 c8 e0             	or     $0xffffffe0,%eax
80105043:	a2 e5 4e 13 80       	mov    %al,0x80134ee5
80105048:	c1 ea 10             	shr    $0x10,%edx
8010504b:	66 89 15 e6 4e 13 80 	mov    %dx,0x80134ee6

  initlock(&tickslock, "time");
80105052:	83 ec 08             	sub    $0x8,%esp
80105055:	68 bd 6e 10 80       	push   $0x80106ebd
8010505a:	68 a0 4c 13 80       	push   $0x80134ca0
8010505f:	e8 4b ec ff ff       	call   80103caf <initlock>
}
80105064:	83 c4 10             	add    $0x10,%esp
80105067:	c9                   	leave  
80105068:	c3                   	ret    

80105069 <idtinit>:

void
idtinit(void)
{
80105069:	55                   	push   %ebp
8010506a:	89 e5                	mov    %esp,%ebp
8010506c:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
8010506f:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80105075:	b8 e0 4c 13 80       	mov    $0x80134ce0,%eax
8010507a:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010507e:	c1 e8 10             	shr    $0x10,%eax
80105081:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
80105085:	8d 45 fa             	lea    -0x6(%ebp),%eax
80105088:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
8010508b:	c9                   	leave  
8010508c:	c3                   	ret    

8010508d <trap>:

void
trap(struct trapframe *tf)
{
8010508d:	55                   	push   %ebp
8010508e:	89 e5                	mov    %esp,%ebp
80105090:	57                   	push   %edi
80105091:	56                   	push   %esi
80105092:	53                   	push   %ebx
80105093:	83 ec 1c             	sub    $0x1c,%esp
80105096:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80105099:	8b 43 30             	mov    0x30(%ebx),%eax
8010509c:	83 f8 40             	cmp    $0x40,%eax
8010509f:	74 13                	je     801050b4 <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
801050a1:	83 e8 20             	sub    $0x20,%eax
801050a4:	83 f8 1f             	cmp    $0x1f,%eax
801050a7:	0f 87 3a 01 00 00    	ja     801051e7 <trap+0x15a>
801050ad:	ff 24 85 64 6f 10 80 	jmp    *-0x7fef909c(,%eax,4)
    if(myproc()->killed)
801050b4:	e8 90 e3 ff ff       	call   80103449 <myproc>
801050b9:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801050bd:	75 1f                	jne    801050de <trap+0x51>
    myproc()->tf = tf;
801050bf:	e8 85 e3 ff ff       	call   80103449 <myproc>
801050c4:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
801050c7:	e8 d9 f0 ff ff       	call   801041a5 <syscall>
    if(myproc()->killed)
801050cc:	e8 78 e3 ff ff       	call   80103449 <myproc>
801050d1:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801050d5:	74 7e                	je     80105155 <trap+0xc8>
      exit();
801050d7:	e8 1c e7 ff ff       	call   801037f8 <exit>
801050dc:	eb 77                	jmp    80105155 <trap+0xc8>
      exit();
801050de:	e8 15 e7 ff ff       	call   801037f8 <exit>
801050e3:	eb da                	jmp    801050bf <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
801050e5:	e8 44 e3 ff ff       	call   8010342e <cpuid>
801050ea:	85 c0                	test   %eax,%eax
801050ec:	74 6f                	je     8010515d <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
801050ee:	e8 f1 d4 ff ff       	call   801025e4 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
801050f3:	e8 51 e3 ff ff       	call   80103449 <myproc>
801050f8:	85 c0                	test   %eax,%eax
801050fa:	74 1c                	je     80105118 <trap+0x8b>
801050fc:	e8 48 e3 ff ff       	call   80103449 <myproc>
80105101:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105105:	74 11                	je     80105118 <trap+0x8b>
80105107:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
8010510b:	83 e0 03             	and    $0x3,%eax
8010510e:	66 83 f8 03          	cmp    $0x3,%ax
80105112:	0f 84 62 01 00 00    	je     8010527a <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80105118:	e8 2c e3 ff ff       	call   80103449 <myproc>
8010511d:	85 c0                	test   %eax,%eax
8010511f:	74 0f                	je     80105130 <trap+0xa3>
80105121:	e8 23 e3 ff ff       	call   80103449 <myproc>
80105126:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
8010512a:	0f 84 54 01 00 00    	je     80105284 <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105130:	e8 14 e3 ff ff       	call   80103449 <myproc>
80105135:	85 c0                	test   %eax,%eax
80105137:	74 1c                	je     80105155 <trap+0xc8>
80105139:	e8 0b e3 ff ff       	call   80103449 <myproc>
8010513e:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105142:	74 11                	je     80105155 <trap+0xc8>
80105144:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105148:	83 e0 03             	and    $0x3,%eax
8010514b:	66 83 f8 03          	cmp    $0x3,%ax
8010514f:	0f 84 43 01 00 00    	je     80105298 <trap+0x20b>
    exit();
}
80105155:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105158:	5b                   	pop    %ebx
80105159:	5e                   	pop    %esi
8010515a:	5f                   	pop    %edi
8010515b:	5d                   	pop    %ebp
8010515c:	c3                   	ret    
      acquire(&tickslock);
8010515d:	83 ec 0c             	sub    $0xc,%esp
80105160:	68 a0 4c 13 80       	push   $0x80134ca0
80105165:	e8 81 ec ff ff       	call   80103deb <acquire>
      ticks++;
8010516a:	83 05 e0 54 13 80 01 	addl   $0x1,0x801354e0
      wakeup(&ticks);
80105171:	c7 04 24 e0 54 13 80 	movl   $0x801354e0,(%esp)
80105178:	e8 d8 e8 ff ff       	call   80103a55 <wakeup>
      release(&tickslock);
8010517d:	c7 04 24 a0 4c 13 80 	movl   $0x80134ca0,(%esp)
80105184:	e8 c7 ec ff ff       	call   80103e50 <release>
80105189:	83 c4 10             	add    $0x10,%esp
8010518c:	e9 5d ff ff ff       	jmp    801050ee <trap+0x61>
    ideintr();
80105191:	e8 dd cb ff ff       	call   80101d73 <ideintr>
    lapiceoi();
80105196:	e8 49 d4 ff ff       	call   801025e4 <lapiceoi>
    break;
8010519b:	e9 53 ff ff ff       	jmp    801050f3 <trap+0x66>
    kbdintr();
801051a0:	e8 83 d2 ff ff       	call   80102428 <kbdintr>
    lapiceoi();
801051a5:	e8 3a d4 ff ff       	call   801025e4 <lapiceoi>
    break;
801051aa:	e9 44 ff ff ff       	jmp    801050f3 <trap+0x66>
    uartintr();
801051af:	e8 05 02 00 00       	call   801053b9 <uartintr>
    lapiceoi();
801051b4:	e8 2b d4 ff ff       	call   801025e4 <lapiceoi>
    break;
801051b9:	e9 35 ff ff ff       	jmp    801050f3 <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801051be:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
801051c1:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801051c5:	e8 64 e2 ff ff       	call   8010342e <cpuid>
801051ca:	57                   	push   %edi
801051cb:	0f b7 f6             	movzwl %si,%esi
801051ce:	56                   	push   %esi
801051cf:	50                   	push   %eax
801051d0:	68 c8 6e 10 80       	push   $0x80106ec8
801051d5:	e8 31 b4 ff ff       	call   8010060b <cprintf>
    lapiceoi();
801051da:	e8 05 d4 ff ff       	call   801025e4 <lapiceoi>
    break;
801051df:	83 c4 10             	add    $0x10,%esp
801051e2:	e9 0c ff ff ff       	jmp    801050f3 <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
801051e7:	e8 5d e2 ff ff       	call   80103449 <myproc>
801051ec:	85 c0                	test   %eax,%eax
801051ee:	74 5f                	je     8010524f <trap+0x1c2>
801051f0:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
801051f4:	74 59                	je     8010524f <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801051f6:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801051f9:	8b 43 38             	mov    0x38(%ebx),%eax
801051fc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801051ff:	e8 2a e2 ff ff       	call   8010342e <cpuid>
80105204:	89 45 e0             	mov    %eax,-0x20(%ebp)
80105207:	8b 53 34             	mov    0x34(%ebx),%edx
8010520a:	89 55 dc             	mov    %edx,-0x24(%ebp)
8010520d:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
80105210:	e8 34 e2 ff ff       	call   80103449 <myproc>
80105215:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105218:	89 4d d8             	mov    %ecx,-0x28(%ebp)
8010521b:	e8 29 e2 ff ff       	call   80103449 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105220:	57                   	push   %edi
80105221:	ff 75 e4             	pushl  -0x1c(%ebp)
80105224:	ff 75 e0             	pushl  -0x20(%ebp)
80105227:	ff 75 dc             	pushl  -0x24(%ebp)
8010522a:	56                   	push   %esi
8010522b:	ff 75 d8             	pushl  -0x28(%ebp)
8010522e:	ff 70 10             	pushl  0x10(%eax)
80105231:	68 20 6f 10 80       	push   $0x80106f20
80105236:	e8 d0 b3 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
8010523b:	83 c4 20             	add    $0x20,%esp
8010523e:	e8 06 e2 ff ff       	call   80103449 <myproc>
80105243:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010524a:	e9 a4 fe ff ff       	jmp    801050f3 <trap+0x66>
8010524f:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80105252:	8b 73 38             	mov    0x38(%ebx),%esi
80105255:	e8 d4 e1 ff ff       	call   8010342e <cpuid>
8010525a:	83 ec 0c             	sub    $0xc,%esp
8010525d:	57                   	push   %edi
8010525e:	56                   	push   %esi
8010525f:	50                   	push   %eax
80105260:	ff 73 30             	pushl  0x30(%ebx)
80105263:	68 ec 6e 10 80       	push   $0x80106eec
80105268:	e8 9e b3 ff ff       	call   8010060b <cprintf>
      panic("trap");
8010526d:	83 c4 14             	add    $0x14,%esp
80105270:	68 c2 6e 10 80       	push   $0x80106ec2
80105275:	e8 ce b0 ff ff       	call   80100348 <panic>
    exit();
8010527a:	e8 79 e5 ff ff       	call   801037f8 <exit>
8010527f:	e9 94 fe ff ff       	jmp    80105118 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
80105284:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
80105288:	0f 85 a2 fe ff ff    	jne    80105130 <trap+0xa3>
    yield();
8010528e:	e8 2b e6 ff ff       	call   801038be <yield>
80105293:	e9 98 fe ff ff       	jmp    80105130 <trap+0xa3>
    exit();
80105298:	e8 5b e5 ff ff       	call   801037f8 <exit>
8010529d:	e9 b3 fe ff ff       	jmp    80105155 <trap+0xc8>

801052a2 <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
801052a2:	55                   	push   %ebp
801052a3:	89 e5                	mov    %esp,%ebp
  if(!uart)
801052a5:	83 3d c4 a5 12 80 00 	cmpl   $0x0,0x8012a5c4
801052ac:	74 15                	je     801052c3 <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801052ae:	ba fd 03 00 00       	mov    $0x3fd,%edx
801052b3:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
801052b4:	a8 01                	test   $0x1,%al
801052b6:	74 12                	je     801052ca <uartgetc+0x28>
801052b8:	ba f8 03 00 00       	mov    $0x3f8,%edx
801052bd:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
801052be:	0f b6 c0             	movzbl %al,%eax
}
801052c1:	5d                   	pop    %ebp
801052c2:	c3                   	ret    
    return -1;
801052c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052c8:	eb f7                	jmp    801052c1 <uartgetc+0x1f>
    return -1;
801052ca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052cf:	eb f0                	jmp    801052c1 <uartgetc+0x1f>

801052d1 <uartputc>:
  if(!uart)
801052d1:	83 3d c4 a5 12 80 00 	cmpl   $0x0,0x8012a5c4
801052d8:	74 3b                	je     80105315 <uartputc+0x44>
{
801052da:	55                   	push   %ebp
801052db:	89 e5                	mov    %esp,%ebp
801052dd:	53                   	push   %ebx
801052de:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801052e1:	bb 00 00 00 00       	mov    $0x0,%ebx
801052e6:	eb 10                	jmp    801052f8 <uartputc+0x27>
    microdelay(10);
801052e8:	83 ec 0c             	sub    $0xc,%esp
801052eb:	6a 0a                	push   $0xa
801052ed:	e8 11 d3 ff ff       	call   80102603 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801052f2:	83 c3 01             	add    $0x1,%ebx
801052f5:	83 c4 10             	add    $0x10,%esp
801052f8:	83 fb 7f             	cmp    $0x7f,%ebx
801052fb:	7f 0a                	jg     80105307 <uartputc+0x36>
801052fd:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105302:	ec                   	in     (%dx),%al
80105303:	a8 20                	test   $0x20,%al
80105305:	74 e1                	je     801052e8 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80105307:	8b 45 08             	mov    0x8(%ebp),%eax
8010530a:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010530f:	ee                   	out    %al,(%dx)
}
80105310:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105313:	c9                   	leave  
80105314:	c3                   	ret    
80105315:	f3 c3                	repz ret 

80105317 <uartinit>:
{
80105317:	55                   	push   %ebp
80105318:	89 e5                	mov    %esp,%ebp
8010531a:	56                   	push   %esi
8010531b:	53                   	push   %ebx
8010531c:	b9 00 00 00 00       	mov    $0x0,%ecx
80105321:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105326:	89 c8                	mov    %ecx,%eax
80105328:	ee                   	out    %al,(%dx)
80105329:	be fb 03 00 00       	mov    $0x3fb,%esi
8010532e:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
80105333:	89 f2                	mov    %esi,%edx
80105335:	ee                   	out    %al,(%dx)
80105336:	b8 0c 00 00 00       	mov    $0xc,%eax
8010533b:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105340:	ee                   	out    %al,(%dx)
80105341:	bb f9 03 00 00       	mov    $0x3f9,%ebx
80105346:	89 c8                	mov    %ecx,%eax
80105348:	89 da                	mov    %ebx,%edx
8010534a:	ee                   	out    %al,(%dx)
8010534b:	b8 03 00 00 00       	mov    $0x3,%eax
80105350:	89 f2                	mov    %esi,%edx
80105352:	ee                   	out    %al,(%dx)
80105353:	ba fc 03 00 00       	mov    $0x3fc,%edx
80105358:	89 c8                	mov    %ecx,%eax
8010535a:	ee                   	out    %al,(%dx)
8010535b:	b8 01 00 00 00       	mov    $0x1,%eax
80105360:	89 da                	mov    %ebx,%edx
80105362:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105363:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105368:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
80105369:	3c ff                	cmp    $0xff,%al
8010536b:	74 45                	je     801053b2 <uartinit+0x9b>
  uart = 1;
8010536d:	c7 05 c4 a5 12 80 01 	movl   $0x1,0x8012a5c4
80105374:	00 00 00 
80105377:	ba fa 03 00 00       	mov    $0x3fa,%edx
8010537c:	ec                   	in     (%dx),%al
8010537d:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105382:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
80105383:	83 ec 08             	sub    $0x8,%esp
80105386:	6a 00                	push   $0x0
80105388:	6a 04                	push   $0x4
8010538a:	e8 ef cb ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
8010538f:	83 c4 10             	add    $0x10,%esp
80105392:	bb e4 6f 10 80       	mov    $0x80106fe4,%ebx
80105397:	eb 12                	jmp    801053ab <uartinit+0x94>
    uartputc(*p);
80105399:	83 ec 0c             	sub    $0xc,%esp
8010539c:	0f be c0             	movsbl %al,%eax
8010539f:	50                   	push   %eax
801053a0:	e8 2c ff ff ff       	call   801052d1 <uartputc>
  for(p="xv6...\n"; *p; p++)
801053a5:	83 c3 01             	add    $0x1,%ebx
801053a8:	83 c4 10             	add    $0x10,%esp
801053ab:	0f b6 03             	movzbl (%ebx),%eax
801053ae:	84 c0                	test   %al,%al
801053b0:	75 e7                	jne    80105399 <uartinit+0x82>
}
801053b2:	8d 65 f8             	lea    -0x8(%ebp),%esp
801053b5:	5b                   	pop    %ebx
801053b6:	5e                   	pop    %esi
801053b7:	5d                   	pop    %ebp
801053b8:	c3                   	ret    

801053b9 <uartintr>:

void
uartintr(void)
{
801053b9:	55                   	push   %ebp
801053ba:	89 e5                	mov    %esp,%ebp
801053bc:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
801053bf:	68 a2 52 10 80       	push   $0x801052a2
801053c4:	e8 75 b3 ff ff       	call   8010073e <consoleintr>
}
801053c9:	83 c4 10             	add    $0x10,%esp
801053cc:	c9                   	leave  
801053cd:	c3                   	ret    

801053ce <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801053ce:	6a 00                	push   $0x0
  pushl $0
801053d0:	6a 00                	push   $0x0
  jmp alltraps
801053d2:	e9 be fb ff ff       	jmp    80104f95 <alltraps>

801053d7 <vector1>:
.globl vector1
vector1:
  pushl $0
801053d7:	6a 00                	push   $0x0
  pushl $1
801053d9:	6a 01                	push   $0x1
  jmp alltraps
801053db:	e9 b5 fb ff ff       	jmp    80104f95 <alltraps>

801053e0 <vector2>:
.globl vector2
vector2:
  pushl $0
801053e0:	6a 00                	push   $0x0
  pushl $2
801053e2:	6a 02                	push   $0x2
  jmp alltraps
801053e4:	e9 ac fb ff ff       	jmp    80104f95 <alltraps>

801053e9 <vector3>:
.globl vector3
vector3:
  pushl $0
801053e9:	6a 00                	push   $0x0
  pushl $3
801053eb:	6a 03                	push   $0x3
  jmp alltraps
801053ed:	e9 a3 fb ff ff       	jmp    80104f95 <alltraps>

801053f2 <vector4>:
.globl vector4
vector4:
  pushl $0
801053f2:	6a 00                	push   $0x0
  pushl $4
801053f4:	6a 04                	push   $0x4
  jmp alltraps
801053f6:	e9 9a fb ff ff       	jmp    80104f95 <alltraps>

801053fb <vector5>:
.globl vector5
vector5:
  pushl $0
801053fb:	6a 00                	push   $0x0
  pushl $5
801053fd:	6a 05                	push   $0x5
  jmp alltraps
801053ff:	e9 91 fb ff ff       	jmp    80104f95 <alltraps>

80105404 <vector6>:
.globl vector6
vector6:
  pushl $0
80105404:	6a 00                	push   $0x0
  pushl $6
80105406:	6a 06                	push   $0x6
  jmp alltraps
80105408:	e9 88 fb ff ff       	jmp    80104f95 <alltraps>

8010540d <vector7>:
.globl vector7
vector7:
  pushl $0
8010540d:	6a 00                	push   $0x0
  pushl $7
8010540f:	6a 07                	push   $0x7
  jmp alltraps
80105411:	e9 7f fb ff ff       	jmp    80104f95 <alltraps>

80105416 <vector8>:
.globl vector8
vector8:
  pushl $8
80105416:	6a 08                	push   $0x8
  jmp alltraps
80105418:	e9 78 fb ff ff       	jmp    80104f95 <alltraps>

8010541d <vector9>:
.globl vector9
vector9:
  pushl $0
8010541d:	6a 00                	push   $0x0
  pushl $9
8010541f:	6a 09                	push   $0x9
  jmp alltraps
80105421:	e9 6f fb ff ff       	jmp    80104f95 <alltraps>

80105426 <vector10>:
.globl vector10
vector10:
  pushl $10
80105426:	6a 0a                	push   $0xa
  jmp alltraps
80105428:	e9 68 fb ff ff       	jmp    80104f95 <alltraps>

8010542d <vector11>:
.globl vector11
vector11:
  pushl $11
8010542d:	6a 0b                	push   $0xb
  jmp alltraps
8010542f:	e9 61 fb ff ff       	jmp    80104f95 <alltraps>

80105434 <vector12>:
.globl vector12
vector12:
  pushl $12
80105434:	6a 0c                	push   $0xc
  jmp alltraps
80105436:	e9 5a fb ff ff       	jmp    80104f95 <alltraps>

8010543b <vector13>:
.globl vector13
vector13:
  pushl $13
8010543b:	6a 0d                	push   $0xd
  jmp alltraps
8010543d:	e9 53 fb ff ff       	jmp    80104f95 <alltraps>

80105442 <vector14>:
.globl vector14
vector14:
  pushl $14
80105442:	6a 0e                	push   $0xe
  jmp alltraps
80105444:	e9 4c fb ff ff       	jmp    80104f95 <alltraps>

80105449 <vector15>:
.globl vector15
vector15:
  pushl $0
80105449:	6a 00                	push   $0x0
  pushl $15
8010544b:	6a 0f                	push   $0xf
  jmp alltraps
8010544d:	e9 43 fb ff ff       	jmp    80104f95 <alltraps>

80105452 <vector16>:
.globl vector16
vector16:
  pushl $0
80105452:	6a 00                	push   $0x0
  pushl $16
80105454:	6a 10                	push   $0x10
  jmp alltraps
80105456:	e9 3a fb ff ff       	jmp    80104f95 <alltraps>

8010545b <vector17>:
.globl vector17
vector17:
  pushl $17
8010545b:	6a 11                	push   $0x11
  jmp alltraps
8010545d:	e9 33 fb ff ff       	jmp    80104f95 <alltraps>

80105462 <vector18>:
.globl vector18
vector18:
  pushl $0
80105462:	6a 00                	push   $0x0
  pushl $18
80105464:	6a 12                	push   $0x12
  jmp alltraps
80105466:	e9 2a fb ff ff       	jmp    80104f95 <alltraps>

8010546b <vector19>:
.globl vector19
vector19:
  pushl $0
8010546b:	6a 00                	push   $0x0
  pushl $19
8010546d:	6a 13                	push   $0x13
  jmp alltraps
8010546f:	e9 21 fb ff ff       	jmp    80104f95 <alltraps>

80105474 <vector20>:
.globl vector20
vector20:
  pushl $0
80105474:	6a 00                	push   $0x0
  pushl $20
80105476:	6a 14                	push   $0x14
  jmp alltraps
80105478:	e9 18 fb ff ff       	jmp    80104f95 <alltraps>

8010547d <vector21>:
.globl vector21
vector21:
  pushl $0
8010547d:	6a 00                	push   $0x0
  pushl $21
8010547f:	6a 15                	push   $0x15
  jmp alltraps
80105481:	e9 0f fb ff ff       	jmp    80104f95 <alltraps>

80105486 <vector22>:
.globl vector22
vector22:
  pushl $0
80105486:	6a 00                	push   $0x0
  pushl $22
80105488:	6a 16                	push   $0x16
  jmp alltraps
8010548a:	e9 06 fb ff ff       	jmp    80104f95 <alltraps>

8010548f <vector23>:
.globl vector23
vector23:
  pushl $0
8010548f:	6a 00                	push   $0x0
  pushl $23
80105491:	6a 17                	push   $0x17
  jmp alltraps
80105493:	e9 fd fa ff ff       	jmp    80104f95 <alltraps>

80105498 <vector24>:
.globl vector24
vector24:
  pushl $0
80105498:	6a 00                	push   $0x0
  pushl $24
8010549a:	6a 18                	push   $0x18
  jmp alltraps
8010549c:	e9 f4 fa ff ff       	jmp    80104f95 <alltraps>

801054a1 <vector25>:
.globl vector25
vector25:
  pushl $0
801054a1:	6a 00                	push   $0x0
  pushl $25
801054a3:	6a 19                	push   $0x19
  jmp alltraps
801054a5:	e9 eb fa ff ff       	jmp    80104f95 <alltraps>

801054aa <vector26>:
.globl vector26
vector26:
  pushl $0
801054aa:	6a 00                	push   $0x0
  pushl $26
801054ac:	6a 1a                	push   $0x1a
  jmp alltraps
801054ae:	e9 e2 fa ff ff       	jmp    80104f95 <alltraps>

801054b3 <vector27>:
.globl vector27
vector27:
  pushl $0
801054b3:	6a 00                	push   $0x0
  pushl $27
801054b5:	6a 1b                	push   $0x1b
  jmp alltraps
801054b7:	e9 d9 fa ff ff       	jmp    80104f95 <alltraps>

801054bc <vector28>:
.globl vector28
vector28:
  pushl $0
801054bc:	6a 00                	push   $0x0
  pushl $28
801054be:	6a 1c                	push   $0x1c
  jmp alltraps
801054c0:	e9 d0 fa ff ff       	jmp    80104f95 <alltraps>

801054c5 <vector29>:
.globl vector29
vector29:
  pushl $0
801054c5:	6a 00                	push   $0x0
  pushl $29
801054c7:	6a 1d                	push   $0x1d
  jmp alltraps
801054c9:	e9 c7 fa ff ff       	jmp    80104f95 <alltraps>

801054ce <vector30>:
.globl vector30
vector30:
  pushl $0
801054ce:	6a 00                	push   $0x0
  pushl $30
801054d0:	6a 1e                	push   $0x1e
  jmp alltraps
801054d2:	e9 be fa ff ff       	jmp    80104f95 <alltraps>

801054d7 <vector31>:
.globl vector31
vector31:
  pushl $0
801054d7:	6a 00                	push   $0x0
  pushl $31
801054d9:	6a 1f                	push   $0x1f
  jmp alltraps
801054db:	e9 b5 fa ff ff       	jmp    80104f95 <alltraps>

801054e0 <vector32>:
.globl vector32
vector32:
  pushl $0
801054e0:	6a 00                	push   $0x0
  pushl $32
801054e2:	6a 20                	push   $0x20
  jmp alltraps
801054e4:	e9 ac fa ff ff       	jmp    80104f95 <alltraps>

801054e9 <vector33>:
.globl vector33
vector33:
  pushl $0
801054e9:	6a 00                	push   $0x0
  pushl $33
801054eb:	6a 21                	push   $0x21
  jmp alltraps
801054ed:	e9 a3 fa ff ff       	jmp    80104f95 <alltraps>

801054f2 <vector34>:
.globl vector34
vector34:
  pushl $0
801054f2:	6a 00                	push   $0x0
  pushl $34
801054f4:	6a 22                	push   $0x22
  jmp alltraps
801054f6:	e9 9a fa ff ff       	jmp    80104f95 <alltraps>

801054fb <vector35>:
.globl vector35
vector35:
  pushl $0
801054fb:	6a 00                	push   $0x0
  pushl $35
801054fd:	6a 23                	push   $0x23
  jmp alltraps
801054ff:	e9 91 fa ff ff       	jmp    80104f95 <alltraps>

80105504 <vector36>:
.globl vector36
vector36:
  pushl $0
80105504:	6a 00                	push   $0x0
  pushl $36
80105506:	6a 24                	push   $0x24
  jmp alltraps
80105508:	e9 88 fa ff ff       	jmp    80104f95 <alltraps>

8010550d <vector37>:
.globl vector37
vector37:
  pushl $0
8010550d:	6a 00                	push   $0x0
  pushl $37
8010550f:	6a 25                	push   $0x25
  jmp alltraps
80105511:	e9 7f fa ff ff       	jmp    80104f95 <alltraps>

80105516 <vector38>:
.globl vector38
vector38:
  pushl $0
80105516:	6a 00                	push   $0x0
  pushl $38
80105518:	6a 26                	push   $0x26
  jmp alltraps
8010551a:	e9 76 fa ff ff       	jmp    80104f95 <alltraps>

8010551f <vector39>:
.globl vector39
vector39:
  pushl $0
8010551f:	6a 00                	push   $0x0
  pushl $39
80105521:	6a 27                	push   $0x27
  jmp alltraps
80105523:	e9 6d fa ff ff       	jmp    80104f95 <alltraps>

80105528 <vector40>:
.globl vector40
vector40:
  pushl $0
80105528:	6a 00                	push   $0x0
  pushl $40
8010552a:	6a 28                	push   $0x28
  jmp alltraps
8010552c:	e9 64 fa ff ff       	jmp    80104f95 <alltraps>

80105531 <vector41>:
.globl vector41
vector41:
  pushl $0
80105531:	6a 00                	push   $0x0
  pushl $41
80105533:	6a 29                	push   $0x29
  jmp alltraps
80105535:	e9 5b fa ff ff       	jmp    80104f95 <alltraps>

8010553a <vector42>:
.globl vector42
vector42:
  pushl $0
8010553a:	6a 00                	push   $0x0
  pushl $42
8010553c:	6a 2a                	push   $0x2a
  jmp alltraps
8010553e:	e9 52 fa ff ff       	jmp    80104f95 <alltraps>

80105543 <vector43>:
.globl vector43
vector43:
  pushl $0
80105543:	6a 00                	push   $0x0
  pushl $43
80105545:	6a 2b                	push   $0x2b
  jmp alltraps
80105547:	e9 49 fa ff ff       	jmp    80104f95 <alltraps>

8010554c <vector44>:
.globl vector44
vector44:
  pushl $0
8010554c:	6a 00                	push   $0x0
  pushl $44
8010554e:	6a 2c                	push   $0x2c
  jmp alltraps
80105550:	e9 40 fa ff ff       	jmp    80104f95 <alltraps>

80105555 <vector45>:
.globl vector45
vector45:
  pushl $0
80105555:	6a 00                	push   $0x0
  pushl $45
80105557:	6a 2d                	push   $0x2d
  jmp alltraps
80105559:	e9 37 fa ff ff       	jmp    80104f95 <alltraps>

8010555e <vector46>:
.globl vector46
vector46:
  pushl $0
8010555e:	6a 00                	push   $0x0
  pushl $46
80105560:	6a 2e                	push   $0x2e
  jmp alltraps
80105562:	e9 2e fa ff ff       	jmp    80104f95 <alltraps>

80105567 <vector47>:
.globl vector47
vector47:
  pushl $0
80105567:	6a 00                	push   $0x0
  pushl $47
80105569:	6a 2f                	push   $0x2f
  jmp alltraps
8010556b:	e9 25 fa ff ff       	jmp    80104f95 <alltraps>

80105570 <vector48>:
.globl vector48
vector48:
  pushl $0
80105570:	6a 00                	push   $0x0
  pushl $48
80105572:	6a 30                	push   $0x30
  jmp alltraps
80105574:	e9 1c fa ff ff       	jmp    80104f95 <alltraps>

80105579 <vector49>:
.globl vector49
vector49:
  pushl $0
80105579:	6a 00                	push   $0x0
  pushl $49
8010557b:	6a 31                	push   $0x31
  jmp alltraps
8010557d:	e9 13 fa ff ff       	jmp    80104f95 <alltraps>

80105582 <vector50>:
.globl vector50
vector50:
  pushl $0
80105582:	6a 00                	push   $0x0
  pushl $50
80105584:	6a 32                	push   $0x32
  jmp alltraps
80105586:	e9 0a fa ff ff       	jmp    80104f95 <alltraps>

8010558b <vector51>:
.globl vector51
vector51:
  pushl $0
8010558b:	6a 00                	push   $0x0
  pushl $51
8010558d:	6a 33                	push   $0x33
  jmp alltraps
8010558f:	e9 01 fa ff ff       	jmp    80104f95 <alltraps>

80105594 <vector52>:
.globl vector52
vector52:
  pushl $0
80105594:	6a 00                	push   $0x0
  pushl $52
80105596:	6a 34                	push   $0x34
  jmp alltraps
80105598:	e9 f8 f9 ff ff       	jmp    80104f95 <alltraps>

8010559d <vector53>:
.globl vector53
vector53:
  pushl $0
8010559d:	6a 00                	push   $0x0
  pushl $53
8010559f:	6a 35                	push   $0x35
  jmp alltraps
801055a1:	e9 ef f9 ff ff       	jmp    80104f95 <alltraps>

801055a6 <vector54>:
.globl vector54
vector54:
  pushl $0
801055a6:	6a 00                	push   $0x0
  pushl $54
801055a8:	6a 36                	push   $0x36
  jmp alltraps
801055aa:	e9 e6 f9 ff ff       	jmp    80104f95 <alltraps>

801055af <vector55>:
.globl vector55
vector55:
  pushl $0
801055af:	6a 00                	push   $0x0
  pushl $55
801055b1:	6a 37                	push   $0x37
  jmp alltraps
801055b3:	e9 dd f9 ff ff       	jmp    80104f95 <alltraps>

801055b8 <vector56>:
.globl vector56
vector56:
  pushl $0
801055b8:	6a 00                	push   $0x0
  pushl $56
801055ba:	6a 38                	push   $0x38
  jmp alltraps
801055bc:	e9 d4 f9 ff ff       	jmp    80104f95 <alltraps>

801055c1 <vector57>:
.globl vector57
vector57:
  pushl $0
801055c1:	6a 00                	push   $0x0
  pushl $57
801055c3:	6a 39                	push   $0x39
  jmp alltraps
801055c5:	e9 cb f9 ff ff       	jmp    80104f95 <alltraps>

801055ca <vector58>:
.globl vector58
vector58:
  pushl $0
801055ca:	6a 00                	push   $0x0
  pushl $58
801055cc:	6a 3a                	push   $0x3a
  jmp alltraps
801055ce:	e9 c2 f9 ff ff       	jmp    80104f95 <alltraps>

801055d3 <vector59>:
.globl vector59
vector59:
  pushl $0
801055d3:	6a 00                	push   $0x0
  pushl $59
801055d5:	6a 3b                	push   $0x3b
  jmp alltraps
801055d7:	e9 b9 f9 ff ff       	jmp    80104f95 <alltraps>

801055dc <vector60>:
.globl vector60
vector60:
  pushl $0
801055dc:	6a 00                	push   $0x0
  pushl $60
801055de:	6a 3c                	push   $0x3c
  jmp alltraps
801055e0:	e9 b0 f9 ff ff       	jmp    80104f95 <alltraps>

801055e5 <vector61>:
.globl vector61
vector61:
  pushl $0
801055e5:	6a 00                	push   $0x0
  pushl $61
801055e7:	6a 3d                	push   $0x3d
  jmp alltraps
801055e9:	e9 a7 f9 ff ff       	jmp    80104f95 <alltraps>

801055ee <vector62>:
.globl vector62
vector62:
  pushl $0
801055ee:	6a 00                	push   $0x0
  pushl $62
801055f0:	6a 3e                	push   $0x3e
  jmp alltraps
801055f2:	e9 9e f9 ff ff       	jmp    80104f95 <alltraps>

801055f7 <vector63>:
.globl vector63
vector63:
  pushl $0
801055f7:	6a 00                	push   $0x0
  pushl $63
801055f9:	6a 3f                	push   $0x3f
  jmp alltraps
801055fb:	e9 95 f9 ff ff       	jmp    80104f95 <alltraps>

80105600 <vector64>:
.globl vector64
vector64:
  pushl $0
80105600:	6a 00                	push   $0x0
  pushl $64
80105602:	6a 40                	push   $0x40
  jmp alltraps
80105604:	e9 8c f9 ff ff       	jmp    80104f95 <alltraps>

80105609 <vector65>:
.globl vector65
vector65:
  pushl $0
80105609:	6a 00                	push   $0x0
  pushl $65
8010560b:	6a 41                	push   $0x41
  jmp alltraps
8010560d:	e9 83 f9 ff ff       	jmp    80104f95 <alltraps>

80105612 <vector66>:
.globl vector66
vector66:
  pushl $0
80105612:	6a 00                	push   $0x0
  pushl $66
80105614:	6a 42                	push   $0x42
  jmp alltraps
80105616:	e9 7a f9 ff ff       	jmp    80104f95 <alltraps>

8010561b <vector67>:
.globl vector67
vector67:
  pushl $0
8010561b:	6a 00                	push   $0x0
  pushl $67
8010561d:	6a 43                	push   $0x43
  jmp alltraps
8010561f:	e9 71 f9 ff ff       	jmp    80104f95 <alltraps>

80105624 <vector68>:
.globl vector68
vector68:
  pushl $0
80105624:	6a 00                	push   $0x0
  pushl $68
80105626:	6a 44                	push   $0x44
  jmp alltraps
80105628:	e9 68 f9 ff ff       	jmp    80104f95 <alltraps>

8010562d <vector69>:
.globl vector69
vector69:
  pushl $0
8010562d:	6a 00                	push   $0x0
  pushl $69
8010562f:	6a 45                	push   $0x45
  jmp alltraps
80105631:	e9 5f f9 ff ff       	jmp    80104f95 <alltraps>

80105636 <vector70>:
.globl vector70
vector70:
  pushl $0
80105636:	6a 00                	push   $0x0
  pushl $70
80105638:	6a 46                	push   $0x46
  jmp alltraps
8010563a:	e9 56 f9 ff ff       	jmp    80104f95 <alltraps>

8010563f <vector71>:
.globl vector71
vector71:
  pushl $0
8010563f:	6a 00                	push   $0x0
  pushl $71
80105641:	6a 47                	push   $0x47
  jmp alltraps
80105643:	e9 4d f9 ff ff       	jmp    80104f95 <alltraps>

80105648 <vector72>:
.globl vector72
vector72:
  pushl $0
80105648:	6a 00                	push   $0x0
  pushl $72
8010564a:	6a 48                	push   $0x48
  jmp alltraps
8010564c:	e9 44 f9 ff ff       	jmp    80104f95 <alltraps>

80105651 <vector73>:
.globl vector73
vector73:
  pushl $0
80105651:	6a 00                	push   $0x0
  pushl $73
80105653:	6a 49                	push   $0x49
  jmp alltraps
80105655:	e9 3b f9 ff ff       	jmp    80104f95 <alltraps>

8010565a <vector74>:
.globl vector74
vector74:
  pushl $0
8010565a:	6a 00                	push   $0x0
  pushl $74
8010565c:	6a 4a                	push   $0x4a
  jmp alltraps
8010565e:	e9 32 f9 ff ff       	jmp    80104f95 <alltraps>

80105663 <vector75>:
.globl vector75
vector75:
  pushl $0
80105663:	6a 00                	push   $0x0
  pushl $75
80105665:	6a 4b                	push   $0x4b
  jmp alltraps
80105667:	e9 29 f9 ff ff       	jmp    80104f95 <alltraps>

8010566c <vector76>:
.globl vector76
vector76:
  pushl $0
8010566c:	6a 00                	push   $0x0
  pushl $76
8010566e:	6a 4c                	push   $0x4c
  jmp alltraps
80105670:	e9 20 f9 ff ff       	jmp    80104f95 <alltraps>

80105675 <vector77>:
.globl vector77
vector77:
  pushl $0
80105675:	6a 00                	push   $0x0
  pushl $77
80105677:	6a 4d                	push   $0x4d
  jmp alltraps
80105679:	e9 17 f9 ff ff       	jmp    80104f95 <alltraps>

8010567e <vector78>:
.globl vector78
vector78:
  pushl $0
8010567e:	6a 00                	push   $0x0
  pushl $78
80105680:	6a 4e                	push   $0x4e
  jmp alltraps
80105682:	e9 0e f9 ff ff       	jmp    80104f95 <alltraps>

80105687 <vector79>:
.globl vector79
vector79:
  pushl $0
80105687:	6a 00                	push   $0x0
  pushl $79
80105689:	6a 4f                	push   $0x4f
  jmp alltraps
8010568b:	e9 05 f9 ff ff       	jmp    80104f95 <alltraps>

80105690 <vector80>:
.globl vector80
vector80:
  pushl $0
80105690:	6a 00                	push   $0x0
  pushl $80
80105692:	6a 50                	push   $0x50
  jmp alltraps
80105694:	e9 fc f8 ff ff       	jmp    80104f95 <alltraps>

80105699 <vector81>:
.globl vector81
vector81:
  pushl $0
80105699:	6a 00                	push   $0x0
  pushl $81
8010569b:	6a 51                	push   $0x51
  jmp alltraps
8010569d:	e9 f3 f8 ff ff       	jmp    80104f95 <alltraps>

801056a2 <vector82>:
.globl vector82
vector82:
  pushl $0
801056a2:	6a 00                	push   $0x0
  pushl $82
801056a4:	6a 52                	push   $0x52
  jmp alltraps
801056a6:	e9 ea f8 ff ff       	jmp    80104f95 <alltraps>

801056ab <vector83>:
.globl vector83
vector83:
  pushl $0
801056ab:	6a 00                	push   $0x0
  pushl $83
801056ad:	6a 53                	push   $0x53
  jmp alltraps
801056af:	e9 e1 f8 ff ff       	jmp    80104f95 <alltraps>

801056b4 <vector84>:
.globl vector84
vector84:
  pushl $0
801056b4:	6a 00                	push   $0x0
  pushl $84
801056b6:	6a 54                	push   $0x54
  jmp alltraps
801056b8:	e9 d8 f8 ff ff       	jmp    80104f95 <alltraps>

801056bd <vector85>:
.globl vector85
vector85:
  pushl $0
801056bd:	6a 00                	push   $0x0
  pushl $85
801056bf:	6a 55                	push   $0x55
  jmp alltraps
801056c1:	e9 cf f8 ff ff       	jmp    80104f95 <alltraps>

801056c6 <vector86>:
.globl vector86
vector86:
  pushl $0
801056c6:	6a 00                	push   $0x0
  pushl $86
801056c8:	6a 56                	push   $0x56
  jmp alltraps
801056ca:	e9 c6 f8 ff ff       	jmp    80104f95 <alltraps>

801056cf <vector87>:
.globl vector87
vector87:
  pushl $0
801056cf:	6a 00                	push   $0x0
  pushl $87
801056d1:	6a 57                	push   $0x57
  jmp alltraps
801056d3:	e9 bd f8 ff ff       	jmp    80104f95 <alltraps>

801056d8 <vector88>:
.globl vector88
vector88:
  pushl $0
801056d8:	6a 00                	push   $0x0
  pushl $88
801056da:	6a 58                	push   $0x58
  jmp alltraps
801056dc:	e9 b4 f8 ff ff       	jmp    80104f95 <alltraps>

801056e1 <vector89>:
.globl vector89
vector89:
  pushl $0
801056e1:	6a 00                	push   $0x0
  pushl $89
801056e3:	6a 59                	push   $0x59
  jmp alltraps
801056e5:	e9 ab f8 ff ff       	jmp    80104f95 <alltraps>

801056ea <vector90>:
.globl vector90
vector90:
  pushl $0
801056ea:	6a 00                	push   $0x0
  pushl $90
801056ec:	6a 5a                	push   $0x5a
  jmp alltraps
801056ee:	e9 a2 f8 ff ff       	jmp    80104f95 <alltraps>

801056f3 <vector91>:
.globl vector91
vector91:
  pushl $0
801056f3:	6a 00                	push   $0x0
  pushl $91
801056f5:	6a 5b                	push   $0x5b
  jmp alltraps
801056f7:	e9 99 f8 ff ff       	jmp    80104f95 <alltraps>

801056fc <vector92>:
.globl vector92
vector92:
  pushl $0
801056fc:	6a 00                	push   $0x0
  pushl $92
801056fe:	6a 5c                	push   $0x5c
  jmp alltraps
80105700:	e9 90 f8 ff ff       	jmp    80104f95 <alltraps>

80105705 <vector93>:
.globl vector93
vector93:
  pushl $0
80105705:	6a 00                	push   $0x0
  pushl $93
80105707:	6a 5d                	push   $0x5d
  jmp alltraps
80105709:	e9 87 f8 ff ff       	jmp    80104f95 <alltraps>

8010570e <vector94>:
.globl vector94
vector94:
  pushl $0
8010570e:	6a 00                	push   $0x0
  pushl $94
80105710:	6a 5e                	push   $0x5e
  jmp alltraps
80105712:	e9 7e f8 ff ff       	jmp    80104f95 <alltraps>

80105717 <vector95>:
.globl vector95
vector95:
  pushl $0
80105717:	6a 00                	push   $0x0
  pushl $95
80105719:	6a 5f                	push   $0x5f
  jmp alltraps
8010571b:	e9 75 f8 ff ff       	jmp    80104f95 <alltraps>

80105720 <vector96>:
.globl vector96
vector96:
  pushl $0
80105720:	6a 00                	push   $0x0
  pushl $96
80105722:	6a 60                	push   $0x60
  jmp alltraps
80105724:	e9 6c f8 ff ff       	jmp    80104f95 <alltraps>

80105729 <vector97>:
.globl vector97
vector97:
  pushl $0
80105729:	6a 00                	push   $0x0
  pushl $97
8010572b:	6a 61                	push   $0x61
  jmp alltraps
8010572d:	e9 63 f8 ff ff       	jmp    80104f95 <alltraps>

80105732 <vector98>:
.globl vector98
vector98:
  pushl $0
80105732:	6a 00                	push   $0x0
  pushl $98
80105734:	6a 62                	push   $0x62
  jmp alltraps
80105736:	e9 5a f8 ff ff       	jmp    80104f95 <alltraps>

8010573b <vector99>:
.globl vector99
vector99:
  pushl $0
8010573b:	6a 00                	push   $0x0
  pushl $99
8010573d:	6a 63                	push   $0x63
  jmp alltraps
8010573f:	e9 51 f8 ff ff       	jmp    80104f95 <alltraps>

80105744 <vector100>:
.globl vector100
vector100:
  pushl $0
80105744:	6a 00                	push   $0x0
  pushl $100
80105746:	6a 64                	push   $0x64
  jmp alltraps
80105748:	e9 48 f8 ff ff       	jmp    80104f95 <alltraps>

8010574d <vector101>:
.globl vector101
vector101:
  pushl $0
8010574d:	6a 00                	push   $0x0
  pushl $101
8010574f:	6a 65                	push   $0x65
  jmp alltraps
80105751:	e9 3f f8 ff ff       	jmp    80104f95 <alltraps>

80105756 <vector102>:
.globl vector102
vector102:
  pushl $0
80105756:	6a 00                	push   $0x0
  pushl $102
80105758:	6a 66                	push   $0x66
  jmp alltraps
8010575a:	e9 36 f8 ff ff       	jmp    80104f95 <alltraps>

8010575f <vector103>:
.globl vector103
vector103:
  pushl $0
8010575f:	6a 00                	push   $0x0
  pushl $103
80105761:	6a 67                	push   $0x67
  jmp alltraps
80105763:	e9 2d f8 ff ff       	jmp    80104f95 <alltraps>

80105768 <vector104>:
.globl vector104
vector104:
  pushl $0
80105768:	6a 00                	push   $0x0
  pushl $104
8010576a:	6a 68                	push   $0x68
  jmp alltraps
8010576c:	e9 24 f8 ff ff       	jmp    80104f95 <alltraps>

80105771 <vector105>:
.globl vector105
vector105:
  pushl $0
80105771:	6a 00                	push   $0x0
  pushl $105
80105773:	6a 69                	push   $0x69
  jmp alltraps
80105775:	e9 1b f8 ff ff       	jmp    80104f95 <alltraps>

8010577a <vector106>:
.globl vector106
vector106:
  pushl $0
8010577a:	6a 00                	push   $0x0
  pushl $106
8010577c:	6a 6a                	push   $0x6a
  jmp alltraps
8010577e:	e9 12 f8 ff ff       	jmp    80104f95 <alltraps>

80105783 <vector107>:
.globl vector107
vector107:
  pushl $0
80105783:	6a 00                	push   $0x0
  pushl $107
80105785:	6a 6b                	push   $0x6b
  jmp alltraps
80105787:	e9 09 f8 ff ff       	jmp    80104f95 <alltraps>

8010578c <vector108>:
.globl vector108
vector108:
  pushl $0
8010578c:	6a 00                	push   $0x0
  pushl $108
8010578e:	6a 6c                	push   $0x6c
  jmp alltraps
80105790:	e9 00 f8 ff ff       	jmp    80104f95 <alltraps>

80105795 <vector109>:
.globl vector109
vector109:
  pushl $0
80105795:	6a 00                	push   $0x0
  pushl $109
80105797:	6a 6d                	push   $0x6d
  jmp alltraps
80105799:	e9 f7 f7 ff ff       	jmp    80104f95 <alltraps>

8010579e <vector110>:
.globl vector110
vector110:
  pushl $0
8010579e:	6a 00                	push   $0x0
  pushl $110
801057a0:	6a 6e                	push   $0x6e
  jmp alltraps
801057a2:	e9 ee f7 ff ff       	jmp    80104f95 <alltraps>

801057a7 <vector111>:
.globl vector111
vector111:
  pushl $0
801057a7:	6a 00                	push   $0x0
  pushl $111
801057a9:	6a 6f                	push   $0x6f
  jmp alltraps
801057ab:	e9 e5 f7 ff ff       	jmp    80104f95 <alltraps>

801057b0 <vector112>:
.globl vector112
vector112:
  pushl $0
801057b0:	6a 00                	push   $0x0
  pushl $112
801057b2:	6a 70                	push   $0x70
  jmp alltraps
801057b4:	e9 dc f7 ff ff       	jmp    80104f95 <alltraps>

801057b9 <vector113>:
.globl vector113
vector113:
  pushl $0
801057b9:	6a 00                	push   $0x0
  pushl $113
801057bb:	6a 71                	push   $0x71
  jmp alltraps
801057bd:	e9 d3 f7 ff ff       	jmp    80104f95 <alltraps>

801057c2 <vector114>:
.globl vector114
vector114:
  pushl $0
801057c2:	6a 00                	push   $0x0
  pushl $114
801057c4:	6a 72                	push   $0x72
  jmp alltraps
801057c6:	e9 ca f7 ff ff       	jmp    80104f95 <alltraps>

801057cb <vector115>:
.globl vector115
vector115:
  pushl $0
801057cb:	6a 00                	push   $0x0
  pushl $115
801057cd:	6a 73                	push   $0x73
  jmp alltraps
801057cf:	e9 c1 f7 ff ff       	jmp    80104f95 <alltraps>

801057d4 <vector116>:
.globl vector116
vector116:
  pushl $0
801057d4:	6a 00                	push   $0x0
  pushl $116
801057d6:	6a 74                	push   $0x74
  jmp alltraps
801057d8:	e9 b8 f7 ff ff       	jmp    80104f95 <alltraps>

801057dd <vector117>:
.globl vector117
vector117:
  pushl $0
801057dd:	6a 00                	push   $0x0
  pushl $117
801057df:	6a 75                	push   $0x75
  jmp alltraps
801057e1:	e9 af f7 ff ff       	jmp    80104f95 <alltraps>

801057e6 <vector118>:
.globl vector118
vector118:
  pushl $0
801057e6:	6a 00                	push   $0x0
  pushl $118
801057e8:	6a 76                	push   $0x76
  jmp alltraps
801057ea:	e9 a6 f7 ff ff       	jmp    80104f95 <alltraps>

801057ef <vector119>:
.globl vector119
vector119:
  pushl $0
801057ef:	6a 00                	push   $0x0
  pushl $119
801057f1:	6a 77                	push   $0x77
  jmp alltraps
801057f3:	e9 9d f7 ff ff       	jmp    80104f95 <alltraps>

801057f8 <vector120>:
.globl vector120
vector120:
  pushl $0
801057f8:	6a 00                	push   $0x0
  pushl $120
801057fa:	6a 78                	push   $0x78
  jmp alltraps
801057fc:	e9 94 f7 ff ff       	jmp    80104f95 <alltraps>

80105801 <vector121>:
.globl vector121
vector121:
  pushl $0
80105801:	6a 00                	push   $0x0
  pushl $121
80105803:	6a 79                	push   $0x79
  jmp alltraps
80105805:	e9 8b f7 ff ff       	jmp    80104f95 <alltraps>

8010580a <vector122>:
.globl vector122
vector122:
  pushl $0
8010580a:	6a 00                	push   $0x0
  pushl $122
8010580c:	6a 7a                	push   $0x7a
  jmp alltraps
8010580e:	e9 82 f7 ff ff       	jmp    80104f95 <alltraps>

80105813 <vector123>:
.globl vector123
vector123:
  pushl $0
80105813:	6a 00                	push   $0x0
  pushl $123
80105815:	6a 7b                	push   $0x7b
  jmp alltraps
80105817:	e9 79 f7 ff ff       	jmp    80104f95 <alltraps>

8010581c <vector124>:
.globl vector124
vector124:
  pushl $0
8010581c:	6a 00                	push   $0x0
  pushl $124
8010581e:	6a 7c                	push   $0x7c
  jmp alltraps
80105820:	e9 70 f7 ff ff       	jmp    80104f95 <alltraps>

80105825 <vector125>:
.globl vector125
vector125:
  pushl $0
80105825:	6a 00                	push   $0x0
  pushl $125
80105827:	6a 7d                	push   $0x7d
  jmp alltraps
80105829:	e9 67 f7 ff ff       	jmp    80104f95 <alltraps>

8010582e <vector126>:
.globl vector126
vector126:
  pushl $0
8010582e:	6a 00                	push   $0x0
  pushl $126
80105830:	6a 7e                	push   $0x7e
  jmp alltraps
80105832:	e9 5e f7 ff ff       	jmp    80104f95 <alltraps>

80105837 <vector127>:
.globl vector127
vector127:
  pushl $0
80105837:	6a 00                	push   $0x0
  pushl $127
80105839:	6a 7f                	push   $0x7f
  jmp alltraps
8010583b:	e9 55 f7 ff ff       	jmp    80104f95 <alltraps>

80105840 <vector128>:
.globl vector128
vector128:
  pushl $0
80105840:	6a 00                	push   $0x0
  pushl $128
80105842:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80105847:	e9 49 f7 ff ff       	jmp    80104f95 <alltraps>

8010584c <vector129>:
.globl vector129
vector129:
  pushl $0
8010584c:	6a 00                	push   $0x0
  pushl $129
8010584e:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80105853:	e9 3d f7 ff ff       	jmp    80104f95 <alltraps>

80105858 <vector130>:
.globl vector130
vector130:
  pushl $0
80105858:	6a 00                	push   $0x0
  pushl $130
8010585a:	68 82 00 00 00       	push   $0x82
  jmp alltraps
8010585f:	e9 31 f7 ff ff       	jmp    80104f95 <alltraps>

80105864 <vector131>:
.globl vector131
vector131:
  pushl $0
80105864:	6a 00                	push   $0x0
  pushl $131
80105866:	68 83 00 00 00       	push   $0x83
  jmp alltraps
8010586b:	e9 25 f7 ff ff       	jmp    80104f95 <alltraps>

80105870 <vector132>:
.globl vector132
vector132:
  pushl $0
80105870:	6a 00                	push   $0x0
  pushl $132
80105872:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80105877:	e9 19 f7 ff ff       	jmp    80104f95 <alltraps>

8010587c <vector133>:
.globl vector133
vector133:
  pushl $0
8010587c:	6a 00                	push   $0x0
  pushl $133
8010587e:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80105883:	e9 0d f7 ff ff       	jmp    80104f95 <alltraps>

80105888 <vector134>:
.globl vector134
vector134:
  pushl $0
80105888:	6a 00                	push   $0x0
  pushl $134
8010588a:	68 86 00 00 00       	push   $0x86
  jmp alltraps
8010588f:	e9 01 f7 ff ff       	jmp    80104f95 <alltraps>

80105894 <vector135>:
.globl vector135
vector135:
  pushl $0
80105894:	6a 00                	push   $0x0
  pushl $135
80105896:	68 87 00 00 00       	push   $0x87
  jmp alltraps
8010589b:	e9 f5 f6 ff ff       	jmp    80104f95 <alltraps>

801058a0 <vector136>:
.globl vector136
vector136:
  pushl $0
801058a0:	6a 00                	push   $0x0
  pushl $136
801058a2:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801058a7:	e9 e9 f6 ff ff       	jmp    80104f95 <alltraps>

801058ac <vector137>:
.globl vector137
vector137:
  pushl $0
801058ac:	6a 00                	push   $0x0
  pushl $137
801058ae:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801058b3:	e9 dd f6 ff ff       	jmp    80104f95 <alltraps>

801058b8 <vector138>:
.globl vector138
vector138:
  pushl $0
801058b8:	6a 00                	push   $0x0
  pushl $138
801058ba:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801058bf:	e9 d1 f6 ff ff       	jmp    80104f95 <alltraps>

801058c4 <vector139>:
.globl vector139
vector139:
  pushl $0
801058c4:	6a 00                	push   $0x0
  pushl $139
801058c6:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801058cb:	e9 c5 f6 ff ff       	jmp    80104f95 <alltraps>

801058d0 <vector140>:
.globl vector140
vector140:
  pushl $0
801058d0:	6a 00                	push   $0x0
  pushl $140
801058d2:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801058d7:	e9 b9 f6 ff ff       	jmp    80104f95 <alltraps>

801058dc <vector141>:
.globl vector141
vector141:
  pushl $0
801058dc:	6a 00                	push   $0x0
  pushl $141
801058de:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801058e3:	e9 ad f6 ff ff       	jmp    80104f95 <alltraps>

801058e8 <vector142>:
.globl vector142
vector142:
  pushl $0
801058e8:	6a 00                	push   $0x0
  pushl $142
801058ea:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
801058ef:	e9 a1 f6 ff ff       	jmp    80104f95 <alltraps>

801058f4 <vector143>:
.globl vector143
vector143:
  pushl $0
801058f4:	6a 00                	push   $0x0
  pushl $143
801058f6:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
801058fb:	e9 95 f6 ff ff       	jmp    80104f95 <alltraps>

80105900 <vector144>:
.globl vector144
vector144:
  pushl $0
80105900:	6a 00                	push   $0x0
  pushl $144
80105902:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80105907:	e9 89 f6 ff ff       	jmp    80104f95 <alltraps>

8010590c <vector145>:
.globl vector145
vector145:
  pushl $0
8010590c:	6a 00                	push   $0x0
  pushl $145
8010590e:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80105913:	e9 7d f6 ff ff       	jmp    80104f95 <alltraps>

80105918 <vector146>:
.globl vector146
vector146:
  pushl $0
80105918:	6a 00                	push   $0x0
  pushl $146
8010591a:	68 92 00 00 00       	push   $0x92
  jmp alltraps
8010591f:	e9 71 f6 ff ff       	jmp    80104f95 <alltraps>

80105924 <vector147>:
.globl vector147
vector147:
  pushl $0
80105924:	6a 00                	push   $0x0
  pushl $147
80105926:	68 93 00 00 00       	push   $0x93
  jmp alltraps
8010592b:	e9 65 f6 ff ff       	jmp    80104f95 <alltraps>

80105930 <vector148>:
.globl vector148
vector148:
  pushl $0
80105930:	6a 00                	push   $0x0
  pushl $148
80105932:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80105937:	e9 59 f6 ff ff       	jmp    80104f95 <alltraps>

8010593c <vector149>:
.globl vector149
vector149:
  pushl $0
8010593c:	6a 00                	push   $0x0
  pushl $149
8010593e:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80105943:	e9 4d f6 ff ff       	jmp    80104f95 <alltraps>

80105948 <vector150>:
.globl vector150
vector150:
  pushl $0
80105948:	6a 00                	push   $0x0
  pushl $150
8010594a:	68 96 00 00 00       	push   $0x96
  jmp alltraps
8010594f:	e9 41 f6 ff ff       	jmp    80104f95 <alltraps>

80105954 <vector151>:
.globl vector151
vector151:
  pushl $0
80105954:	6a 00                	push   $0x0
  pushl $151
80105956:	68 97 00 00 00       	push   $0x97
  jmp alltraps
8010595b:	e9 35 f6 ff ff       	jmp    80104f95 <alltraps>

80105960 <vector152>:
.globl vector152
vector152:
  pushl $0
80105960:	6a 00                	push   $0x0
  pushl $152
80105962:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80105967:	e9 29 f6 ff ff       	jmp    80104f95 <alltraps>

8010596c <vector153>:
.globl vector153
vector153:
  pushl $0
8010596c:	6a 00                	push   $0x0
  pushl $153
8010596e:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80105973:	e9 1d f6 ff ff       	jmp    80104f95 <alltraps>

80105978 <vector154>:
.globl vector154
vector154:
  pushl $0
80105978:	6a 00                	push   $0x0
  pushl $154
8010597a:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
8010597f:	e9 11 f6 ff ff       	jmp    80104f95 <alltraps>

80105984 <vector155>:
.globl vector155
vector155:
  pushl $0
80105984:	6a 00                	push   $0x0
  pushl $155
80105986:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
8010598b:	e9 05 f6 ff ff       	jmp    80104f95 <alltraps>

80105990 <vector156>:
.globl vector156
vector156:
  pushl $0
80105990:	6a 00                	push   $0x0
  pushl $156
80105992:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80105997:	e9 f9 f5 ff ff       	jmp    80104f95 <alltraps>

8010599c <vector157>:
.globl vector157
vector157:
  pushl $0
8010599c:	6a 00                	push   $0x0
  pushl $157
8010599e:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
801059a3:	e9 ed f5 ff ff       	jmp    80104f95 <alltraps>

801059a8 <vector158>:
.globl vector158
vector158:
  pushl $0
801059a8:	6a 00                	push   $0x0
  pushl $158
801059aa:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801059af:	e9 e1 f5 ff ff       	jmp    80104f95 <alltraps>

801059b4 <vector159>:
.globl vector159
vector159:
  pushl $0
801059b4:	6a 00                	push   $0x0
  pushl $159
801059b6:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801059bb:	e9 d5 f5 ff ff       	jmp    80104f95 <alltraps>

801059c0 <vector160>:
.globl vector160
vector160:
  pushl $0
801059c0:	6a 00                	push   $0x0
  pushl $160
801059c2:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801059c7:	e9 c9 f5 ff ff       	jmp    80104f95 <alltraps>

801059cc <vector161>:
.globl vector161
vector161:
  pushl $0
801059cc:	6a 00                	push   $0x0
  pushl $161
801059ce:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801059d3:	e9 bd f5 ff ff       	jmp    80104f95 <alltraps>

801059d8 <vector162>:
.globl vector162
vector162:
  pushl $0
801059d8:	6a 00                	push   $0x0
  pushl $162
801059da:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801059df:	e9 b1 f5 ff ff       	jmp    80104f95 <alltraps>

801059e4 <vector163>:
.globl vector163
vector163:
  pushl $0
801059e4:	6a 00                	push   $0x0
  pushl $163
801059e6:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
801059eb:	e9 a5 f5 ff ff       	jmp    80104f95 <alltraps>

801059f0 <vector164>:
.globl vector164
vector164:
  pushl $0
801059f0:	6a 00                	push   $0x0
  pushl $164
801059f2:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
801059f7:	e9 99 f5 ff ff       	jmp    80104f95 <alltraps>

801059fc <vector165>:
.globl vector165
vector165:
  pushl $0
801059fc:	6a 00                	push   $0x0
  pushl $165
801059fe:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80105a03:	e9 8d f5 ff ff       	jmp    80104f95 <alltraps>

80105a08 <vector166>:
.globl vector166
vector166:
  pushl $0
80105a08:	6a 00                	push   $0x0
  pushl $166
80105a0a:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105a0f:	e9 81 f5 ff ff       	jmp    80104f95 <alltraps>

80105a14 <vector167>:
.globl vector167
vector167:
  pushl $0
80105a14:	6a 00                	push   $0x0
  pushl $167
80105a16:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105a1b:	e9 75 f5 ff ff       	jmp    80104f95 <alltraps>

80105a20 <vector168>:
.globl vector168
vector168:
  pushl $0
80105a20:	6a 00                	push   $0x0
  pushl $168
80105a22:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105a27:	e9 69 f5 ff ff       	jmp    80104f95 <alltraps>

80105a2c <vector169>:
.globl vector169
vector169:
  pushl $0
80105a2c:	6a 00                	push   $0x0
  pushl $169
80105a2e:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80105a33:	e9 5d f5 ff ff       	jmp    80104f95 <alltraps>

80105a38 <vector170>:
.globl vector170
vector170:
  pushl $0
80105a38:	6a 00                	push   $0x0
  pushl $170
80105a3a:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105a3f:	e9 51 f5 ff ff       	jmp    80104f95 <alltraps>

80105a44 <vector171>:
.globl vector171
vector171:
  pushl $0
80105a44:	6a 00                	push   $0x0
  pushl $171
80105a46:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105a4b:	e9 45 f5 ff ff       	jmp    80104f95 <alltraps>

80105a50 <vector172>:
.globl vector172
vector172:
  pushl $0
80105a50:	6a 00                	push   $0x0
  pushl $172
80105a52:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105a57:	e9 39 f5 ff ff       	jmp    80104f95 <alltraps>

80105a5c <vector173>:
.globl vector173
vector173:
  pushl $0
80105a5c:	6a 00                	push   $0x0
  pushl $173
80105a5e:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80105a63:	e9 2d f5 ff ff       	jmp    80104f95 <alltraps>

80105a68 <vector174>:
.globl vector174
vector174:
  pushl $0
80105a68:	6a 00                	push   $0x0
  pushl $174
80105a6a:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105a6f:	e9 21 f5 ff ff       	jmp    80104f95 <alltraps>

80105a74 <vector175>:
.globl vector175
vector175:
  pushl $0
80105a74:	6a 00                	push   $0x0
  pushl $175
80105a76:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105a7b:	e9 15 f5 ff ff       	jmp    80104f95 <alltraps>

80105a80 <vector176>:
.globl vector176
vector176:
  pushl $0
80105a80:	6a 00                	push   $0x0
  pushl $176
80105a82:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105a87:	e9 09 f5 ff ff       	jmp    80104f95 <alltraps>

80105a8c <vector177>:
.globl vector177
vector177:
  pushl $0
80105a8c:	6a 00                	push   $0x0
  pushl $177
80105a8e:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105a93:	e9 fd f4 ff ff       	jmp    80104f95 <alltraps>

80105a98 <vector178>:
.globl vector178
vector178:
  pushl $0
80105a98:	6a 00                	push   $0x0
  pushl $178
80105a9a:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105a9f:	e9 f1 f4 ff ff       	jmp    80104f95 <alltraps>

80105aa4 <vector179>:
.globl vector179
vector179:
  pushl $0
80105aa4:	6a 00                	push   $0x0
  pushl $179
80105aa6:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105aab:	e9 e5 f4 ff ff       	jmp    80104f95 <alltraps>

80105ab0 <vector180>:
.globl vector180
vector180:
  pushl $0
80105ab0:	6a 00                	push   $0x0
  pushl $180
80105ab2:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105ab7:	e9 d9 f4 ff ff       	jmp    80104f95 <alltraps>

80105abc <vector181>:
.globl vector181
vector181:
  pushl $0
80105abc:	6a 00                	push   $0x0
  pushl $181
80105abe:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105ac3:	e9 cd f4 ff ff       	jmp    80104f95 <alltraps>

80105ac8 <vector182>:
.globl vector182
vector182:
  pushl $0
80105ac8:	6a 00                	push   $0x0
  pushl $182
80105aca:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105acf:	e9 c1 f4 ff ff       	jmp    80104f95 <alltraps>

80105ad4 <vector183>:
.globl vector183
vector183:
  pushl $0
80105ad4:	6a 00                	push   $0x0
  pushl $183
80105ad6:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105adb:	e9 b5 f4 ff ff       	jmp    80104f95 <alltraps>

80105ae0 <vector184>:
.globl vector184
vector184:
  pushl $0
80105ae0:	6a 00                	push   $0x0
  pushl $184
80105ae2:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105ae7:	e9 a9 f4 ff ff       	jmp    80104f95 <alltraps>

80105aec <vector185>:
.globl vector185
vector185:
  pushl $0
80105aec:	6a 00                	push   $0x0
  pushl $185
80105aee:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105af3:	e9 9d f4 ff ff       	jmp    80104f95 <alltraps>

80105af8 <vector186>:
.globl vector186
vector186:
  pushl $0
80105af8:	6a 00                	push   $0x0
  pushl $186
80105afa:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105aff:	e9 91 f4 ff ff       	jmp    80104f95 <alltraps>

80105b04 <vector187>:
.globl vector187
vector187:
  pushl $0
80105b04:	6a 00                	push   $0x0
  pushl $187
80105b06:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105b0b:	e9 85 f4 ff ff       	jmp    80104f95 <alltraps>

80105b10 <vector188>:
.globl vector188
vector188:
  pushl $0
80105b10:	6a 00                	push   $0x0
  pushl $188
80105b12:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105b17:	e9 79 f4 ff ff       	jmp    80104f95 <alltraps>

80105b1c <vector189>:
.globl vector189
vector189:
  pushl $0
80105b1c:	6a 00                	push   $0x0
  pushl $189
80105b1e:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105b23:	e9 6d f4 ff ff       	jmp    80104f95 <alltraps>

80105b28 <vector190>:
.globl vector190
vector190:
  pushl $0
80105b28:	6a 00                	push   $0x0
  pushl $190
80105b2a:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105b2f:	e9 61 f4 ff ff       	jmp    80104f95 <alltraps>

80105b34 <vector191>:
.globl vector191
vector191:
  pushl $0
80105b34:	6a 00                	push   $0x0
  pushl $191
80105b36:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105b3b:	e9 55 f4 ff ff       	jmp    80104f95 <alltraps>

80105b40 <vector192>:
.globl vector192
vector192:
  pushl $0
80105b40:	6a 00                	push   $0x0
  pushl $192
80105b42:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105b47:	e9 49 f4 ff ff       	jmp    80104f95 <alltraps>

80105b4c <vector193>:
.globl vector193
vector193:
  pushl $0
80105b4c:	6a 00                	push   $0x0
  pushl $193
80105b4e:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105b53:	e9 3d f4 ff ff       	jmp    80104f95 <alltraps>

80105b58 <vector194>:
.globl vector194
vector194:
  pushl $0
80105b58:	6a 00                	push   $0x0
  pushl $194
80105b5a:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105b5f:	e9 31 f4 ff ff       	jmp    80104f95 <alltraps>

80105b64 <vector195>:
.globl vector195
vector195:
  pushl $0
80105b64:	6a 00                	push   $0x0
  pushl $195
80105b66:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105b6b:	e9 25 f4 ff ff       	jmp    80104f95 <alltraps>

80105b70 <vector196>:
.globl vector196
vector196:
  pushl $0
80105b70:	6a 00                	push   $0x0
  pushl $196
80105b72:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105b77:	e9 19 f4 ff ff       	jmp    80104f95 <alltraps>

80105b7c <vector197>:
.globl vector197
vector197:
  pushl $0
80105b7c:	6a 00                	push   $0x0
  pushl $197
80105b7e:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105b83:	e9 0d f4 ff ff       	jmp    80104f95 <alltraps>

80105b88 <vector198>:
.globl vector198
vector198:
  pushl $0
80105b88:	6a 00                	push   $0x0
  pushl $198
80105b8a:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105b8f:	e9 01 f4 ff ff       	jmp    80104f95 <alltraps>

80105b94 <vector199>:
.globl vector199
vector199:
  pushl $0
80105b94:	6a 00                	push   $0x0
  pushl $199
80105b96:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105b9b:	e9 f5 f3 ff ff       	jmp    80104f95 <alltraps>

80105ba0 <vector200>:
.globl vector200
vector200:
  pushl $0
80105ba0:	6a 00                	push   $0x0
  pushl $200
80105ba2:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105ba7:	e9 e9 f3 ff ff       	jmp    80104f95 <alltraps>

80105bac <vector201>:
.globl vector201
vector201:
  pushl $0
80105bac:	6a 00                	push   $0x0
  pushl $201
80105bae:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105bb3:	e9 dd f3 ff ff       	jmp    80104f95 <alltraps>

80105bb8 <vector202>:
.globl vector202
vector202:
  pushl $0
80105bb8:	6a 00                	push   $0x0
  pushl $202
80105bba:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105bbf:	e9 d1 f3 ff ff       	jmp    80104f95 <alltraps>

80105bc4 <vector203>:
.globl vector203
vector203:
  pushl $0
80105bc4:	6a 00                	push   $0x0
  pushl $203
80105bc6:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105bcb:	e9 c5 f3 ff ff       	jmp    80104f95 <alltraps>

80105bd0 <vector204>:
.globl vector204
vector204:
  pushl $0
80105bd0:	6a 00                	push   $0x0
  pushl $204
80105bd2:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105bd7:	e9 b9 f3 ff ff       	jmp    80104f95 <alltraps>

80105bdc <vector205>:
.globl vector205
vector205:
  pushl $0
80105bdc:	6a 00                	push   $0x0
  pushl $205
80105bde:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105be3:	e9 ad f3 ff ff       	jmp    80104f95 <alltraps>

80105be8 <vector206>:
.globl vector206
vector206:
  pushl $0
80105be8:	6a 00                	push   $0x0
  pushl $206
80105bea:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105bef:	e9 a1 f3 ff ff       	jmp    80104f95 <alltraps>

80105bf4 <vector207>:
.globl vector207
vector207:
  pushl $0
80105bf4:	6a 00                	push   $0x0
  pushl $207
80105bf6:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105bfb:	e9 95 f3 ff ff       	jmp    80104f95 <alltraps>

80105c00 <vector208>:
.globl vector208
vector208:
  pushl $0
80105c00:	6a 00                	push   $0x0
  pushl $208
80105c02:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105c07:	e9 89 f3 ff ff       	jmp    80104f95 <alltraps>

80105c0c <vector209>:
.globl vector209
vector209:
  pushl $0
80105c0c:	6a 00                	push   $0x0
  pushl $209
80105c0e:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105c13:	e9 7d f3 ff ff       	jmp    80104f95 <alltraps>

80105c18 <vector210>:
.globl vector210
vector210:
  pushl $0
80105c18:	6a 00                	push   $0x0
  pushl $210
80105c1a:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105c1f:	e9 71 f3 ff ff       	jmp    80104f95 <alltraps>

80105c24 <vector211>:
.globl vector211
vector211:
  pushl $0
80105c24:	6a 00                	push   $0x0
  pushl $211
80105c26:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105c2b:	e9 65 f3 ff ff       	jmp    80104f95 <alltraps>

80105c30 <vector212>:
.globl vector212
vector212:
  pushl $0
80105c30:	6a 00                	push   $0x0
  pushl $212
80105c32:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105c37:	e9 59 f3 ff ff       	jmp    80104f95 <alltraps>

80105c3c <vector213>:
.globl vector213
vector213:
  pushl $0
80105c3c:	6a 00                	push   $0x0
  pushl $213
80105c3e:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105c43:	e9 4d f3 ff ff       	jmp    80104f95 <alltraps>

80105c48 <vector214>:
.globl vector214
vector214:
  pushl $0
80105c48:	6a 00                	push   $0x0
  pushl $214
80105c4a:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105c4f:	e9 41 f3 ff ff       	jmp    80104f95 <alltraps>

80105c54 <vector215>:
.globl vector215
vector215:
  pushl $0
80105c54:	6a 00                	push   $0x0
  pushl $215
80105c56:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105c5b:	e9 35 f3 ff ff       	jmp    80104f95 <alltraps>

80105c60 <vector216>:
.globl vector216
vector216:
  pushl $0
80105c60:	6a 00                	push   $0x0
  pushl $216
80105c62:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105c67:	e9 29 f3 ff ff       	jmp    80104f95 <alltraps>

80105c6c <vector217>:
.globl vector217
vector217:
  pushl $0
80105c6c:	6a 00                	push   $0x0
  pushl $217
80105c6e:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105c73:	e9 1d f3 ff ff       	jmp    80104f95 <alltraps>

80105c78 <vector218>:
.globl vector218
vector218:
  pushl $0
80105c78:	6a 00                	push   $0x0
  pushl $218
80105c7a:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105c7f:	e9 11 f3 ff ff       	jmp    80104f95 <alltraps>

80105c84 <vector219>:
.globl vector219
vector219:
  pushl $0
80105c84:	6a 00                	push   $0x0
  pushl $219
80105c86:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105c8b:	e9 05 f3 ff ff       	jmp    80104f95 <alltraps>

80105c90 <vector220>:
.globl vector220
vector220:
  pushl $0
80105c90:	6a 00                	push   $0x0
  pushl $220
80105c92:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105c97:	e9 f9 f2 ff ff       	jmp    80104f95 <alltraps>

80105c9c <vector221>:
.globl vector221
vector221:
  pushl $0
80105c9c:	6a 00                	push   $0x0
  pushl $221
80105c9e:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105ca3:	e9 ed f2 ff ff       	jmp    80104f95 <alltraps>

80105ca8 <vector222>:
.globl vector222
vector222:
  pushl $0
80105ca8:	6a 00                	push   $0x0
  pushl $222
80105caa:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105caf:	e9 e1 f2 ff ff       	jmp    80104f95 <alltraps>

80105cb4 <vector223>:
.globl vector223
vector223:
  pushl $0
80105cb4:	6a 00                	push   $0x0
  pushl $223
80105cb6:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105cbb:	e9 d5 f2 ff ff       	jmp    80104f95 <alltraps>

80105cc0 <vector224>:
.globl vector224
vector224:
  pushl $0
80105cc0:	6a 00                	push   $0x0
  pushl $224
80105cc2:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105cc7:	e9 c9 f2 ff ff       	jmp    80104f95 <alltraps>

80105ccc <vector225>:
.globl vector225
vector225:
  pushl $0
80105ccc:	6a 00                	push   $0x0
  pushl $225
80105cce:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105cd3:	e9 bd f2 ff ff       	jmp    80104f95 <alltraps>

80105cd8 <vector226>:
.globl vector226
vector226:
  pushl $0
80105cd8:	6a 00                	push   $0x0
  pushl $226
80105cda:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105cdf:	e9 b1 f2 ff ff       	jmp    80104f95 <alltraps>

80105ce4 <vector227>:
.globl vector227
vector227:
  pushl $0
80105ce4:	6a 00                	push   $0x0
  pushl $227
80105ce6:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105ceb:	e9 a5 f2 ff ff       	jmp    80104f95 <alltraps>

80105cf0 <vector228>:
.globl vector228
vector228:
  pushl $0
80105cf0:	6a 00                	push   $0x0
  pushl $228
80105cf2:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105cf7:	e9 99 f2 ff ff       	jmp    80104f95 <alltraps>

80105cfc <vector229>:
.globl vector229
vector229:
  pushl $0
80105cfc:	6a 00                	push   $0x0
  pushl $229
80105cfe:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105d03:	e9 8d f2 ff ff       	jmp    80104f95 <alltraps>

80105d08 <vector230>:
.globl vector230
vector230:
  pushl $0
80105d08:	6a 00                	push   $0x0
  pushl $230
80105d0a:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105d0f:	e9 81 f2 ff ff       	jmp    80104f95 <alltraps>

80105d14 <vector231>:
.globl vector231
vector231:
  pushl $0
80105d14:	6a 00                	push   $0x0
  pushl $231
80105d16:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105d1b:	e9 75 f2 ff ff       	jmp    80104f95 <alltraps>

80105d20 <vector232>:
.globl vector232
vector232:
  pushl $0
80105d20:	6a 00                	push   $0x0
  pushl $232
80105d22:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105d27:	e9 69 f2 ff ff       	jmp    80104f95 <alltraps>

80105d2c <vector233>:
.globl vector233
vector233:
  pushl $0
80105d2c:	6a 00                	push   $0x0
  pushl $233
80105d2e:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105d33:	e9 5d f2 ff ff       	jmp    80104f95 <alltraps>

80105d38 <vector234>:
.globl vector234
vector234:
  pushl $0
80105d38:	6a 00                	push   $0x0
  pushl $234
80105d3a:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105d3f:	e9 51 f2 ff ff       	jmp    80104f95 <alltraps>

80105d44 <vector235>:
.globl vector235
vector235:
  pushl $0
80105d44:	6a 00                	push   $0x0
  pushl $235
80105d46:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105d4b:	e9 45 f2 ff ff       	jmp    80104f95 <alltraps>

80105d50 <vector236>:
.globl vector236
vector236:
  pushl $0
80105d50:	6a 00                	push   $0x0
  pushl $236
80105d52:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105d57:	e9 39 f2 ff ff       	jmp    80104f95 <alltraps>

80105d5c <vector237>:
.globl vector237
vector237:
  pushl $0
80105d5c:	6a 00                	push   $0x0
  pushl $237
80105d5e:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105d63:	e9 2d f2 ff ff       	jmp    80104f95 <alltraps>

80105d68 <vector238>:
.globl vector238
vector238:
  pushl $0
80105d68:	6a 00                	push   $0x0
  pushl $238
80105d6a:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105d6f:	e9 21 f2 ff ff       	jmp    80104f95 <alltraps>

80105d74 <vector239>:
.globl vector239
vector239:
  pushl $0
80105d74:	6a 00                	push   $0x0
  pushl $239
80105d76:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105d7b:	e9 15 f2 ff ff       	jmp    80104f95 <alltraps>

80105d80 <vector240>:
.globl vector240
vector240:
  pushl $0
80105d80:	6a 00                	push   $0x0
  pushl $240
80105d82:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105d87:	e9 09 f2 ff ff       	jmp    80104f95 <alltraps>

80105d8c <vector241>:
.globl vector241
vector241:
  pushl $0
80105d8c:	6a 00                	push   $0x0
  pushl $241
80105d8e:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105d93:	e9 fd f1 ff ff       	jmp    80104f95 <alltraps>

80105d98 <vector242>:
.globl vector242
vector242:
  pushl $0
80105d98:	6a 00                	push   $0x0
  pushl $242
80105d9a:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105d9f:	e9 f1 f1 ff ff       	jmp    80104f95 <alltraps>

80105da4 <vector243>:
.globl vector243
vector243:
  pushl $0
80105da4:	6a 00                	push   $0x0
  pushl $243
80105da6:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105dab:	e9 e5 f1 ff ff       	jmp    80104f95 <alltraps>

80105db0 <vector244>:
.globl vector244
vector244:
  pushl $0
80105db0:	6a 00                	push   $0x0
  pushl $244
80105db2:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105db7:	e9 d9 f1 ff ff       	jmp    80104f95 <alltraps>

80105dbc <vector245>:
.globl vector245
vector245:
  pushl $0
80105dbc:	6a 00                	push   $0x0
  pushl $245
80105dbe:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105dc3:	e9 cd f1 ff ff       	jmp    80104f95 <alltraps>

80105dc8 <vector246>:
.globl vector246
vector246:
  pushl $0
80105dc8:	6a 00                	push   $0x0
  pushl $246
80105dca:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105dcf:	e9 c1 f1 ff ff       	jmp    80104f95 <alltraps>

80105dd4 <vector247>:
.globl vector247
vector247:
  pushl $0
80105dd4:	6a 00                	push   $0x0
  pushl $247
80105dd6:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105ddb:	e9 b5 f1 ff ff       	jmp    80104f95 <alltraps>

80105de0 <vector248>:
.globl vector248
vector248:
  pushl $0
80105de0:	6a 00                	push   $0x0
  pushl $248
80105de2:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105de7:	e9 a9 f1 ff ff       	jmp    80104f95 <alltraps>

80105dec <vector249>:
.globl vector249
vector249:
  pushl $0
80105dec:	6a 00                	push   $0x0
  pushl $249
80105dee:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105df3:	e9 9d f1 ff ff       	jmp    80104f95 <alltraps>

80105df8 <vector250>:
.globl vector250
vector250:
  pushl $0
80105df8:	6a 00                	push   $0x0
  pushl $250
80105dfa:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105dff:	e9 91 f1 ff ff       	jmp    80104f95 <alltraps>

80105e04 <vector251>:
.globl vector251
vector251:
  pushl $0
80105e04:	6a 00                	push   $0x0
  pushl $251
80105e06:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105e0b:	e9 85 f1 ff ff       	jmp    80104f95 <alltraps>

80105e10 <vector252>:
.globl vector252
vector252:
  pushl $0
80105e10:	6a 00                	push   $0x0
  pushl $252
80105e12:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105e17:	e9 79 f1 ff ff       	jmp    80104f95 <alltraps>

80105e1c <vector253>:
.globl vector253
vector253:
  pushl $0
80105e1c:	6a 00                	push   $0x0
  pushl $253
80105e1e:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105e23:	e9 6d f1 ff ff       	jmp    80104f95 <alltraps>

80105e28 <vector254>:
.globl vector254
vector254:
  pushl $0
80105e28:	6a 00                	push   $0x0
  pushl $254
80105e2a:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105e2f:	e9 61 f1 ff ff       	jmp    80104f95 <alltraps>

80105e34 <vector255>:
.globl vector255
vector255:
  pushl $0
80105e34:	6a 00                	push   $0x0
  pushl $255
80105e36:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105e3b:	e9 55 f1 ff ff       	jmp    80104f95 <alltraps>

80105e40 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105e40:	55                   	push   %ebp
80105e41:	89 e5                	mov    %esp,%ebp
80105e43:	57                   	push   %edi
80105e44:	56                   	push   %esi
80105e45:	53                   	push   %ebx
80105e46:	83 ec 0c             	sub    $0xc,%esp
80105e49:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105e4b:	c1 ea 16             	shr    $0x16,%edx
80105e4e:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105e51:	8b 1f                	mov    (%edi),%ebx
80105e53:	f6 c3 01             	test   $0x1,%bl
80105e56:	74 22                	je     80105e7a <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105e58:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105e5e:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105e64:	c1 ee 0c             	shr    $0xc,%esi
80105e67:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105e6d:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105e70:	89 d8                	mov    %ebx,%eax
80105e72:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105e75:	5b                   	pop    %ebx
80105e76:	5e                   	pop    %esi
80105e77:	5f                   	pop    %edi
80105e78:	5d                   	pop    %ebp
80105e79:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc2(-2)) == 0)
80105e7a:	85 c9                	test   %ecx,%ecx
80105e7c:	74 33                	je     80105eb1 <walkpgdir+0x71>
80105e7e:	83 ec 0c             	sub    $0xc,%esp
80105e81:	6a fe                	push   $0xfffffffe
80105e83:	e8 c5 c2 ff ff       	call   8010214d <kalloc2>
80105e88:	89 c3                	mov    %eax,%ebx
80105e8a:	83 c4 10             	add    $0x10,%esp
80105e8d:	85 c0                	test   %eax,%eax
80105e8f:	74 df                	je     80105e70 <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105e91:	83 ec 04             	sub    $0x4,%esp
80105e94:	68 00 10 00 00       	push   $0x1000
80105e99:	6a 00                	push   $0x0
80105e9b:	50                   	push   %eax
80105e9c:	e8 f6 df ff ff       	call   80103e97 <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105ea1:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105ea7:	83 c8 07             	or     $0x7,%eax
80105eaa:	89 07                	mov    %eax,(%edi)
80105eac:	83 c4 10             	add    $0x10,%esp
80105eaf:	eb b3                	jmp    80105e64 <walkpgdir+0x24>
      return 0;
80105eb1:	bb 00 00 00 00       	mov    $0x0,%ebx
80105eb6:	eb b8                	jmp    80105e70 <walkpgdir+0x30>

80105eb8 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105eb8:	55                   	push   %ebp
80105eb9:	89 e5                	mov    %esp,%ebp
80105ebb:	57                   	push   %edi
80105ebc:	56                   	push   %esi
80105ebd:	53                   	push   %ebx
80105ebe:	83 ec 1c             	sub    $0x1c,%esp
80105ec1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105ec4:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105ec7:	89 d3                	mov    %edx,%ebx
80105ec9:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105ecf:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105ed3:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105ed9:	b9 01 00 00 00       	mov    $0x1,%ecx
80105ede:	89 da                	mov    %ebx,%edx
80105ee0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105ee3:	e8 58 ff ff ff       	call   80105e40 <walkpgdir>
80105ee8:	85 c0                	test   %eax,%eax
80105eea:	74 2e                	je     80105f1a <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105eec:	f6 00 01             	testb  $0x1,(%eax)
80105eef:	75 1c                	jne    80105f0d <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105ef1:	89 f2                	mov    %esi,%edx
80105ef3:	0b 55 0c             	or     0xc(%ebp),%edx
80105ef6:	83 ca 01             	or     $0x1,%edx
80105ef9:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105efb:	39 fb                	cmp    %edi,%ebx
80105efd:	74 28                	je     80105f27 <mappages+0x6f>
      break;
    a += PGSIZE;
80105eff:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105f05:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105f0b:	eb cc                	jmp    80105ed9 <mappages+0x21>
      panic("remap");
80105f0d:	83 ec 0c             	sub    $0xc,%esp
80105f10:	68 ec 6f 10 80       	push   $0x80106fec
80105f15:	e8 2e a4 ff ff       	call   80100348 <panic>
      return -1;
80105f1a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105f1f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105f22:	5b                   	pop    %ebx
80105f23:	5e                   	pop    %esi
80105f24:	5f                   	pop    %edi
80105f25:	5d                   	pop    %ebp
80105f26:	c3                   	ret    
  return 0;
80105f27:	b8 00 00 00 00       	mov    $0x0,%eax
80105f2c:	eb f1                	jmp    80105f1f <mappages+0x67>

80105f2e <seginit>:
{
80105f2e:	55                   	push   %ebp
80105f2f:	89 e5                	mov    %esp,%ebp
80105f31:	53                   	push   %ebx
80105f32:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105f35:	e8 f4 d4 ff ff       	call   8010342e <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105f3a:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105f40:	66 c7 80 38 28 13 80 	movw   $0xffff,-0x7fecd7c8(%eax)
80105f47:	ff ff 
80105f49:	66 c7 80 3a 28 13 80 	movw   $0x0,-0x7fecd7c6(%eax)
80105f50:	00 00 
80105f52:	c6 80 3c 28 13 80 00 	movb   $0x0,-0x7fecd7c4(%eax)
80105f59:	0f b6 88 3d 28 13 80 	movzbl -0x7fecd7c3(%eax),%ecx
80105f60:	83 e1 f0             	and    $0xfffffff0,%ecx
80105f63:	83 c9 1a             	or     $0x1a,%ecx
80105f66:	83 e1 9f             	and    $0xffffff9f,%ecx
80105f69:	83 c9 80             	or     $0xffffff80,%ecx
80105f6c:	88 88 3d 28 13 80    	mov    %cl,-0x7fecd7c3(%eax)
80105f72:	0f b6 88 3e 28 13 80 	movzbl -0x7fecd7c2(%eax),%ecx
80105f79:	83 c9 0f             	or     $0xf,%ecx
80105f7c:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f7f:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f82:	88 88 3e 28 13 80    	mov    %cl,-0x7fecd7c2(%eax)
80105f88:	c6 80 3f 28 13 80 00 	movb   $0x0,-0x7fecd7c1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105f8f:	66 c7 80 40 28 13 80 	movw   $0xffff,-0x7fecd7c0(%eax)
80105f96:	ff ff 
80105f98:	66 c7 80 42 28 13 80 	movw   $0x0,-0x7fecd7be(%eax)
80105f9f:	00 00 
80105fa1:	c6 80 44 28 13 80 00 	movb   $0x0,-0x7fecd7bc(%eax)
80105fa8:	0f b6 88 45 28 13 80 	movzbl -0x7fecd7bb(%eax),%ecx
80105faf:	83 e1 f0             	and    $0xfffffff0,%ecx
80105fb2:	83 c9 12             	or     $0x12,%ecx
80105fb5:	83 e1 9f             	and    $0xffffff9f,%ecx
80105fb8:	83 c9 80             	or     $0xffffff80,%ecx
80105fbb:	88 88 45 28 13 80    	mov    %cl,-0x7fecd7bb(%eax)
80105fc1:	0f b6 88 46 28 13 80 	movzbl -0x7fecd7ba(%eax),%ecx
80105fc8:	83 c9 0f             	or     $0xf,%ecx
80105fcb:	83 e1 cf             	and    $0xffffffcf,%ecx
80105fce:	83 c9 c0             	or     $0xffffffc0,%ecx
80105fd1:	88 88 46 28 13 80    	mov    %cl,-0x7fecd7ba(%eax)
80105fd7:	c6 80 47 28 13 80 00 	movb   $0x0,-0x7fecd7b9(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80105fde:	66 c7 80 48 28 13 80 	movw   $0xffff,-0x7fecd7b8(%eax)
80105fe5:	ff ff 
80105fe7:	66 c7 80 4a 28 13 80 	movw   $0x0,-0x7fecd7b6(%eax)
80105fee:	00 00 
80105ff0:	c6 80 4c 28 13 80 00 	movb   $0x0,-0x7fecd7b4(%eax)
80105ff7:	c6 80 4d 28 13 80 fa 	movb   $0xfa,-0x7fecd7b3(%eax)
80105ffe:	0f b6 88 4e 28 13 80 	movzbl -0x7fecd7b2(%eax),%ecx
80106005:	83 c9 0f             	or     $0xf,%ecx
80106008:	83 e1 cf             	and    $0xffffffcf,%ecx
8010600b:	83 c9 c0             	or     $0xffffffc0,%ecx
8010600e:	88 88 4e 28 13 80    	mov    %cl,-0x7fecd7b2(%eax)
80106014:	c6 80 4f 28 13 80 00 	movb   $0x0,-0x7fecd7b1(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
8010601b:	66 c7 80 50 28 13 80 	movw   $0xffff,-0x7fecd7b0(%eax)
80106022:	ff ff 
80106024:	66 c7 80 52 28 13 80 	movw   $0x0,-0x7fecd7ae(%eax)
8010602b:	00 00 
8010602d:	c6 80 54 28 13 80 00 	movb   $0x0,-0x7fecd7ac(%eax)
80106034:	c6 80 55 28 13 80 f2 	movb   $0xf2,-0x7fecd7ab(%eax)
8010603b:	0f b6 88 56 28 13 80 	movzbl -0x7fecd7aa(%eax),%ecx
80106042:	83 c9 0f             	or     $0xf,%ecx
80106045:	83 e1 cf             	and    $0xffffffcf,%ecx
80106048:	83 c9 c0             	or     $0xffffffc0,%ecx
8010604b:	88 88 56 28 13 80    	mov    %cl,-0x7fecd7aa(%eax)
80106051:	c6 80 57 28 13 80 00 	movb   $0x0,-0x7fecd7a9(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80106058:	05 30 28 13 80       	add    $0x80132830,%eax
  pd[0] = size-1;
8010605d:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80106063:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80106067:	c1 e8 10             	shr    $0x10,%eax
8010606a:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
8010606e:	8d 45 f2             	lea    -0xe(%ebp),%eax
80106071:	0f 01 10             	lgdtl  (%eax)
}
80106074:	83 c4 14             	add    $0x14,%esp
80106077:	5b                   	pop    %ebx
80106078:	5d                   	pop    %ebp
80106079:	c3                   	ret    

8010607a <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
8010607a:	55                   	push   %ebp
8010607b:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
8010607d:	a1 e4 54 13 80       	mov    0x801354e4,%eax
80106082:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80106087:	0f 22 d8             	mov    %eax,%cr3
}
8010608a:	5d                   	pop    %ebp
8010608b:	c3                   	ret    

8010608c <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
8010608c:	55                   	push   %ebp
8010608d:	89 e5                	mov    %esp,%ebp
8010608f:	57                   	push   %edi
80106090:	56                   	push   %esi
80106091:	53                   	push   %ebx
80106092:	83 ec 1c             	sub    $0x1c,%esp
80106095:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
80106098:	85 f6                	test   %esi,%esi
8010609a:	0f 84 dd 00 00 00    	je     8010617d <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
801060a0:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
801060a4:	0f 84 e0 00 00 00    	je     8010618a <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
801060aa:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
801060ae:	0f 84 e3 00 00 00    	je     80106197 <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
801060b4:	e8 55 dc ff ff       	call   80103d0e <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
801060b9:	e8 14 d3 ff ff       	call   801033d2 <mycpu>
801060be:	89 c3                	mov    %eax,%ebx
801060c0:	e8 0d d3 ff ff       	call   801033d2 <mycpu>
801060c5:	8d 78 08             	lea    0x8(%eax),%edi
801060c8:	e8 05 d3 ff ff       	call   801033d2 <mycpu>
801060cd:	83 c0 08             	add    $0x8,%eax
801060d0:	c1 e8 10             	shr    $0x10,%eax
801060d3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801060d6:	e8 f7 d2 ff ff       	call   801033d2 <mycpu>
801060db:	83 c0 08             	add    $0x8,%eax
801060de:	c1 e8 18             	shr    $0x18,%eax
801060e1:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
801060e8:	67 00 
801060ea:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
801060f1:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
801060f5:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
801060fb:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80106102:	83 e2 f0             	and    $0xfffffff0,%edx
80106105:	83 ca 19             	or     $0x19,%edx
80106108:	83 e2 9f             	and    $0xffffff9f,%edx
8010610b:	83 ca 80             	or     $0xffffff80,%edx
8010610e:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80106114:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
8010611b:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80106121:	e8 ac d2 ff ff       	call   801033d2 <mycpu>
80106126:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010612d:	83 e2 ef             	and    $0xffffffef,%edx
80106130:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80106136:	e8 97 d2 ff ff       	call   801033d2 <mycpu>
8010613b:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80106141:	8b 5e 08             	mov    0x8(%esi),%ebx
80106144:	e8 89 d2 ff ff       	call   801033d2 <mycpu>
80106149:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010614f:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
80106152:	e8 7b d2 ff ff       	call   801033d2 <mycpu>
80106157:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
8010615d:	b8 28 00 00 00       	mov    $0x28,%eax
80106162:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
80106165:	8b 46 04             	mov    0x4(%esi),%eax
80106168:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010616d:	0f 22 d8             	mov    %eax,%cr3
  popcli();
80106170:	e8 d6 db ff ff       	call   80103d4b <popcli>
}
80106175:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106178:	5b                   	pop    %ebx
80106179:	5e                   	pop    %esi
8010617a:	5f                   	pop    %edi
8010617b:	5d                   	pop    %ebp
8010617c:	c3                   	ret    
    panic("switchuvm: no process");
8010617d:	83 ec 0c             	sub    $0xc,%esp
80106180:	68 f2 6f 10 80       	push   $0x80106ff2
80106185:	e8 be a1 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
8010618a:	83 ec 0c             	sub    $0xc,%esp
8010618d:	68 08 70 10 80       	push   $0x80107008
80106192:	e8 b1 a1 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
80106197:	83 ec 0c             	sub    $0xc,%esp
8010619a:	68 1d 70 10 80       	push   $0x8010701d
8010619f:	e8 a4 a1 ff ff       	call   80100348 <panic>

801061a4 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801061a4:	55                   	push   %ebp
801061a5:	89 e5                	mov    %esp,%ebp
801061a7:	56                   	push   %esi
801061a8:	53                   	push   %ebx
801061a9:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
801061ac:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
801061b2:	77 51                	ja     80106205 <inituvm+0x61>
    panic("inituvm: more than a page");
  mem = kalloc2(-2);
801061b4:	83 ec 0c             	sub    $0xc,%esp
801061b7:	6a fe                	push   $0xfffffffe
801061b9:	e8 8f bf ff ff       	call   8010214d <kalloc2>
801061be:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
801061c0:	83 c4 0c             	add    $0xc,%esp
801061c3:	68 00 10 00 00       	push   $0x1000
801061c8:	6a 00                	push   $0x0
801061ca:	50                   	push   %eax
801061cb:	e8 c7 dc ff ff       	call   80103e97 <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
801061d0:	83 c4 08             	add    $0x8,%esp
801061d3:	6a 06                	push   $0x6
801061d5:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801061db:	50                   	push   %eax
801061dc:	b9 00 10 00 00       	mov    $0x1000,%ecx
801061e1:	ba 00 00 00 00       	mov    $0x0,%edx
801061e6:	8b 45 08             	mov    0x8(%ebp),%eax
801061e9:	e8 ca fc ff ff       	call   80105eb8 <mappages>
  memmove(mem, init, sz);
801061ee:	83 c4 0c             	add    $0xc,%esp
801061f1:	56                   	push   %esi
801061f2:	ff 75 0c             	pushl  0xc(%ebp)
801061f5:	53                   	push   %ebx
801061f6:	e8 17 dd ff ff       	call   80103f12 <memmove>
}
801061fb:	83 c4 10             	add    $0x10,%esp
801061fe:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106201:	5b                   	pop    %ebx
80106202:	5e                   	pop    %esi
80106203:	5d                   	pop    %ebp
80106204:	c3                   	ret    
    panic("inituvm: more than a page");
80106205:	83 ec 0c             	sub    $0xc,%esp
80106208:	68 31 70 10 80       	push   $0x80107031
8010620d:	e8 36 a1 ff ff       	call   80100348 <panic>

80106212 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80106212:	55                   	push   %ebp
80106213:	89 e5                	mov    %esp,%ebp
80106215:	57                   	push   %edi
80106216:	56                   	push   %esi
80106217:	53                   	push   %ebx
80106218:	83 ec 0c             	sub    $0xc,%esp
8010621b:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
8010621e:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
80106225:	75 07                	jne    8010622e <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80106227:	bb 00 00 00 00       	mov    $0x0,%ebx
8010622c:	eb 3c                	jmp    8010626a <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
8010622e:	83 ec 0c             	sub    $0xc,%esp
80106231:	68 ec 70 10 80       	push   $0x801070ec
80106236:	e8 0d a1 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
8010623b:	83 ec 0c             	sub    $0xc,%esp
8010623e:	68 4b 70 10 80       	push   $0x8010704b
80106243:	e8 00 a1 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
80106248:	05 00 00 00 80       	add    $0x80000000,%eax
8010624d:	56                   	push   %esi
8010624e:	89 da                	mov    %ebx,%edx
80106250:	03 55 14             	add    0x14(%ebp),%edx
80106253:	52                   	push   %edx
80106254:	50                   	push   %eax
80106255:	ff 75 10             	pushl  0x10(%ebp)
80106258:	e8 16 b5 ff ff       	call   80101773 <readi>
8010625d:	83 c4 10             	add    $0x10,%esp
80106260:	39 f0                	cmp    %esi,%eax
80106262:	75 47                	jne    801062ab <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
80106264:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010626a:	39 fb                	cmp    %edi,%ebx
8010626c:	73 30                	jae    8010629e <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
8010626e:	89 da                	mov    %ebx,%edx
80106270:	03 55 0c             	add    0xc(%ebp),%edx
80106273:	b9 00 00 00 00       	mov    $0x0,%ecx
80106278:	8b 45 08             	mov    0x8(%ebp),%eax
8010627b:	e8 c0 fb ff ff       	call   80105e40 <walkpgdir>
80106280:	85 c0                	test   %eax,%eax
80106282:	74 b7                	je     8010623b <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
80106284:	8b 00                	mov    (%eax),%eax
80106286:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
8010628b:	89 fe                	mov    %edi,%esi
8010628d:	29 de                	sub    %ebx,%esi
8010628f:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106295:	76 b1                	jbe    80106248 <loaduvm+0x36>
      n = PGSIZE;
80106297:	be 00 10 00 00       	mov    $0x1000,%esi
8010629c:	eb aa                	jmp    80106248 <loaduvm+0x36>
      return -1;
  }
  return 0;
8010629e:	b8 00 00 00 00       	mov    $0x0,%eax
}
801062a3:	8d 65 f4             	lea    -0xc(%ebp),%esp
801062a6:	5b                   	pop    %ebx
801062a7:	5e                   	pop    %esi
801062a8:	5f                   	pop    %edi
801062a9:	5d                   	pop    %ebp
801062aa:	c3                   	ret    
      return -1;
801062ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062b0:	eb f1                	jmp    801062a3 <loaduvm+0x91>

801062b2 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801062b2:	55                   	push   %ebp
801062b3:	89 e5                	mov    %esp,%ebp
801062b5:	57                   	push   %edi
801062b6:	56                   	push   %esi
801062b7:	53                   	push   %ebx
801062b8:	83 ec 0c             	sub    $0xc,%esp
801062bb:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801062be:	39 7d 10             	cmp    %edi,0x10(%ebp)
801062c1:	73 11                	jae    801062d4 <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
801062c3:	8b 45 10             	mov    0x10(%ebp),%eax
801062c6:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801062cc:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801062d2:	eb 19                	jmp    801062ed <deallocuvm+0x3b>
    return oldsz;
801062d4:	89 f8                	mov    %edi,%eax
801062d6:	eb 64                	jmp    8010633c <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
801062d8:	c1 eb 16             	shr    $0x16,%ebx
801062db:	83 c3 01             	add    $0x1,%ebx
801062de:	c1 e3 16             	shl    $0x16,%ebx
801062e1:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801062e7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801062ed:	39 fb                	cmp    %edi,%ebx
801062ef:	73 48                	jae    80106339 <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
801062f1:	b9 00 00 00 00       	mov    $0x0,%ecx
801062f6:	89 da                	mov    %ebx,%edx
801062f8:	8b 45 08             	mov    0x8(%ebp),%eax
801062fb:	e8 40 fb ff ff       	call   80105e40 <walkpgdir>
80106300:	89 c6                	mov    %eax,%esi
    if(!pte)
80106302:	85 c0                	test   %eax,%eax
80106304:	74 d2                	je     801062d8 <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
80106306:	8b 00                	mov    (%eax),%eax
80106308:	a8 01                	test   $0x1,%al
8010630a:	74 db                	je     801062e7 <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
8010630c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106311:	74 19                	je     8010632c <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
80106313:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106318:	83 ec 0c             	sub    $0xc,%esp
8010631b:	50                   	push   %eax
8010631c:	e8 83 bc ff ff       	call   80101fa4 <kfree>
      *pte = 0;
80106321:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80106327:	83 c4 10             	add    $0x10,%esp
8010632a:	eb bb                	jmp    801062e7 <deallocuvm+0x35>
        panic("kfree");
8010632c:	83 ec 0c             	sub    $0xc,%esp
8010632f:	68 86 69 10 80       	push   $0x80106986
80106334:	e8 0f a0 ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
80106339:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010633c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010633f:	5b                   	pop    %ebx
80106340:	5e                   	pop    %esi
80106341:	5f                   	pop    %edi
80106342:	5d                   	pop    %ebp
80106343:	c3                   	ret    

80106344 <allocuvm>:
{
80106344:	55                   	push   %ebp
80106345:	89 e5                	mov    %esp,%ebp
80106347:	57                   	push   %edi
80106348:	56                   	push   %esi
80106349:	53                   	push   %ebx
8010634a:	83 ec 1c             	sub    $0x1c,%esp
8010634d:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
80106350:	89 7d e4             	mov    %edi,-0x1c(%ebp)
80106353:	85 ff                	test   %edi,%edi
80106355:	0f 88 cf 00 00 00    	js     8010642a <allocuvm+0xe6>
  if(newsz < oldsz)
8010635b:	3b 7d 0c             	cmp    0xc(%ebp),%edi
8010635e:	72 6a                	jb     801063ca <allocuvm+0x86>
  a = PGROUNDUP(oldsz);
80106360:	8b 45 0c             	mov    0xc(%ebp),%eax
80106363:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106369:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
8010636f:	39 fb                	cmp    %edi,%ebx
80106371:	0f 83 ba 00 00 00    	jae    80106431 <allocuvm+0xed>
    mem = kalloc2(myproc()->pid);
80106377:	e8 cd d0 ff ff       	call   80103449 <myproc>
8010637c:	83 ec 0c             	sub    $0xc,%esp
8010637f:	ff 70 10             	pushl  0x10(%eax)
80106382:	e8 c6 bd ff ff       	call   8010214d <kalloc2>
80106387:	89 c6                	mov    %eax,%esi
    if(mem == 0){
80106389:	83 c4 10             	add    $0x10,%esp
8010638c:	85 c0                	test   %eax,%eax
8010638e:	74 42                	je     801063d2 <allocuvm+0x8e>
    memset(mem, 0, PGSIZE);
80106390:	83 ec 04             	sub    $0x4,%esp
80106393:	68 00 10 00 00       	push   $0x1000
80106398:	6a 00                	push   $0x0
8010639a:	50                   	push   %eax
8010639b:	e8 f7 da ff ff       	call   80103e97 <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
801063a0:	83 c4 08             	add    $0x8,%esp
801063a3:	6a 06                	push   $0x6
801063a5:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
801063ab:	50                   	push   %eax
801063ac:	b9 00 10 00 00       	mov    $0x1000,%ecx
801063b1:	89 da                	mov    %ebx,%edx
801063b3:	8b 45 08             	mov    0x8(%ebp),%eax
801063b6:	e8 fd fa ff ff       	call   80105eb8 <mappages>
801063bb:	83 c4 10             	add    $0x10,%esp
801063be:	85 c0                	test   %eax,%eax
801063c0:	78 38                	js     801063fa <allocuvm+0xb6>
  for(; a < newsz; a += PGSIZE){
801063c2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801063c8:	eb a5                	jmp    8010636f <allocuvm+0x2b>
    return oldsz;
801063ca:	8b 45 0c             	mov    0xc(%ebp),%eax
801063cd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801063d0:	eb 5f                	jmp    80106431 <allocuvm+0xed>
      cprintf("allocuvm out of memory\n");
801063d2:	83 ec 0c             	sub    $0xc,%esp
801063d5:	68 69 70 10 80       	push   $0x80107069
801063da:	e8 2c a2 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801063df:	83 c4 0c             	add    $0xc,%esp
801063e2:	ff 75 0c             	pushl  0xc(%ebp)
801063e5:	57                   	push   %edi
801063e6:	ff 75 08             	pushl  0x8(%ebp)
801063e9:	e8 c4 fe ff ff       	call   801062b2 <deallocuvm>
      return 0;
801063ee:	83 c4 10             	add    $0x10,%esp
801063f1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801063f8:	eb 37                	jmp    80106431 <allocuvm+0xed>
      cprintf("allocuvm out of memory (2)\n");
801063fa:	83 ec 0c             	sub    $0xc,%esp
801063fd:	68 81 70 10 80       	push   $0x80107081
80106402:	e8 04 a2 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106407:	83 c4 0c             	add    $0xc,%esp
8010640a:	ff 75 0c             	pushl  0xc(%ebp)
8010640d:	57                   	push   %edi
8010640e:	ff 75 08             	pushl  0x8(%ebp)
80106411:	e8 9c fe ff ff       	call   801062b2 <deallocuvm>
      kfree(mem);
80106416:	89 34 24             	mov    %esi,(%esp)
80106419:	e8 86 bb ff ff       	call   80101fa4 <kfree>
      return 0;
8010641e:	83 c4 10             	add    $0x10,%esp
80106421:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106428:	eb 07                	jmp    80106431 <allocuvm+0xed>
    return 0;
8010642a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
80106431:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106434:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106437:	5b                   	pop    %ebx
80106438:	5e                   	pop    %esi
80106439:	5f                   	pop    %edi
8010643a:	5d                   	pop    %ebp
8010643b:	c3                   	ret    

8010643c <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
8010643c:	55                   	push   %ebp
8010643d:	89 e5                	mov    %esp,%ebp
8010643f:	56                   	push   %esi
80106440:	53                   	push   %ebx
80106441:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
80106444:	85 f6                	test   %esi,%esi
80106446:	74 1a                	je     80106462 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
80106448:	83 ec 04             	sub    $0x4,%esp
8010644b:	6a 00                	push   $0x0
8010644d:	68 00 00 00 80       	push   $0x80000000
80106452:	56                   	push   %esi
80106453:	e8 5a fe ff ff       	call   801062b2 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80106458:	83 c4 10             	add    $0x10,%esp
8010645b:	bb 00 00 00 00       	mov    $0x0,%ebx
80106460:	eb 10                	jmp    80106472 <freevm+0x36>
    panic("freevm: no pgdir");
80106462:	83 ec 0c             	sub    $0xc,%esp
80106465:	68 9d 70 10 80       	push   $0x8010709d
8010646a:	e8 d9 9e ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
8010646f:	83 c3 01             	add    $0x1,%ebx
80106472:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
80106478:	77 1f                	ja     80106499 <freevm+0x5d>
    if(pgdir[i] & PTE_P){
8010647a:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
8010647d:	a8 01                	test   $0x1,%al
8010647f:	74 ee                	je     8010646f <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
80106481:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106486:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
8010648b:	83 ec 0c             	sub    $0xc,%esp
8010648e:	50                   	push   %eax
8010648f:	e8 10 bb ff ff       	call   80101fa4 <kfree>
80106494:	83 c4 10             	add    $0x10,%esp
80106497:	eb d6                	jmp    8010646f <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
80106499:	83 ec 0c             	sub    $0xc,%esp
8010649c:	56                   	push   %esi
8010649d:	e8 02 bb ff ff       	call   80101fa4 <kfree>
}
801064a2:	83 c4 10             	add    $0x10,%esp
801064a5:	8d 65 f8             	lea    -0x8(%ebp),%esp
801064a8:	5b                   	pop    %ebx
801064a9:	5e                   	pop    %esi
801064aa:	5d                   	pop    %ebp
801064ab:	c3                   	ret    

801064ac <setupkvm>:
{
801064ac:	55                   	push   %ebp
801064ad:	89 e5                	mov    %esp,%ebp
801064af:	56                   	push   %esi
801064b0:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc2(-2)) == 0)
801064b1:	83 ec 0c             	sub    $0xc,%esp
801064b4:	6a fe                	push   $0xfffffffe
801064b6:	e8 92 bc ff ff       	call   8010214d <kalloc2>
801064bb:	89 c6                	mov    %eax,%esi
801064bd:	83 c4 10             	add    $0x10,%esp
801064c0:	85 c0                	test   %eax,%eax
801064c2:	74 55                	je     80106519 <setupkvm+0x6d>
  memset(pgdir, 0, PGSIZE);
801064c4:	83 ec 04             	sub    $0x4,%esp
801064c7:	68 00 10 00 00       	push   $0x1000
801064cc:	6a 00                	push   $0x0
801064ce:	50                   	push   %eax
801064cf:	e8 c3 d9 ff ff       	call   80103e97 <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801064d4:	83 c4 10             	add    $0x10,%esp
801064d7:	bb 20 a4 12 80       	mov    $0x8012a420,%ebx
801064dc:	81 fb 60 a4 12 80    	cmp    $0x8012a460,%ebx
801064e2:	73 35                	jae    80106519 <setupkvm+0x6d>
                (uint)k->phys_start, k->perm) < 0) {
801064e4:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
801064e7:	8b 4b 08             	mov    0x8(%ebx),%ecx
801064ea:	29 c1                	sub    %eax,%ecx
801064ec:	83 ec 08             	sub    $0x8,%esp
801064ef:	ff 73 0c             	pushl  0xc(%ebx)
801064f2:	50                   	push   %eax
801064f3:	8b 13                	mov    (%ebx),%edx
801064f5:	89 f0                	mov    %esi,%eax
801064f7:	e8 bc f9 ff ff       	call   80105eb8 <mappages>
801064fc:	83 c4 10             	add    $0x10,%esp
801064ff:	85 c0                	test   %eax,%eax
80106501:	78 05                	js     80106508 <setupkvm+0x5c>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106503:	83 c3 10             	add    $0x10,%ebx
80106506:	eb d4                	jmp    801064dc <setupkvm+0x30>
      freevm(pgdir);
80106508:	83 ec 0c             	sub    $0xc,%esp
8010650b:	56                   	push   %esi
8010650c:	e8 2b ff ff ff       	call   8010643c <freevm>
      return 0;
80106511:	83 c4 10             	add    $0x10,%esp
80106514:	be 00 00 00 00       	mov    $0x0,%esi
}
80106519:	89 f0                	mov    %esi,%eax
8010651b:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010651e:	5b                   	pop    %ebx
8010651f:	5e                   	pop    %esi
80106520:	5d                   	pop    %ebp
80106521:	c3                   	ret    

80106522 <kvmalloc>:
{
80106522:	55                   	push   %ebp
80106523:	89 e5                	mov    %esp,%ebp
80106525:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80106528:	e8 7f ff ff ff       	call   801064ac <setupkvm>
8010652d:	a3 e4 54 13 80       	mov    %eax,0x801354e4
  switchkvm();
80106532:	e8 43 fb ff ff       	call   8010607a <switchkvm>
}
80106537:	c9                   	leave  
80106538:	c3                   	ret    

80106539 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80106539:	55                   	push   %ebp
8010653a:	89 e5                	mov    %esp,%ebp
8010653c:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010653f:	b9 00 00 00 00       	mov    $0x0,%ecx
80106544:	8b 55 0c             	mov    0xc(%ebp),%edx
80106547:	8b 45 08             	mov    0x8(%ebp),%eax
8010654a:	e8 f1 f8 ff ff       	call   80105e40 <walkpgdir>
  if(pte == 0)
8010654f:	85 c0                	test   %eax,%eax
80106551:	74 05                	je     80106558 <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
80106553:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
80106556:	c9                   	leave  
80106557:	c3                   	ret    
    panic("clearpteu");
80106558:	83 ec 0c             	sub    $0xc,%esp
8010655b:	68 ae 70 10 80       	push   $0x801070ae
80106560:	e8 e3 9d ff ff       	call   80100348 <panic>

80106565 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz, uint childPid)
{
80106565:	55                   	push   %ebp
80106566:	89 e5                	mov    %esp,%ebp
80106568:	57                   	push   %edi
80106569:	56                   	push   %esi
8010656a:	53                   	push   %ebx
8010656b:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
8010656e:	e8 39 ff ff ff       	call   801064ac <setupkvm>
80106573:	89 45 dc             	mov    %eax,-0x24(%ebp)
80106576:	85 c0                	test   %eax,%eax
80106578:	0f 84 d1 00 00 00    	je     8010664f <copyuvm+0xea>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
8010657e:	bf 00 00 00 00       	mov    $0x0,%edi
80106583:	89 fe                	mov    %edi,%esi
80106585:	3b 75 0c             	cmp    0xc(%ebp),%esi
80106588:	0f 83 c1 00 00 00    	jae    8010664f <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
8010658e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
80106591:	b9 00 00 00 00       	mov    $0x0,%ecx
80106596:	89 f2                	mov    %esi,%edx
80106598:	8b 45 08             	mov    0x8(%ebp),%eax
8010659b:	e8 a0 f8 ff ff       	call   80105e40 <walkpgdir>
801065a0:	85 c0                	test   %eax,%eax
801065a2:	74 70                	je     80106614 <copyuvm+0xaf>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
801065a4:	8b 18                	mov    (%eax),%ebx
801065a6:	f6 c3 01             	test   $0x1,%bl
801065a9:	74 76                	je     80106621 <copyuvm+0xbc>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
801065ab:	89 df                	mov    %ebx,%edi
801065ad:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
    flags = PTE_FLAGS(*pte);
801065b3:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
801065b9:	89 5d e0             	mov    %ebx,-0x20(%ebp)
    if((mem = kalloc2(childPid)) == 0)
801065bc:	83 ec 0c             	sub    $0xc,%esp
801065bf:	ff 75 10             	pushl  0x10(%ebp)
801065c2:	e8 86 bb ff ff       	call   8010214d <kalloc2>
801065c7:	89 c3                	mov    %eax,%ebx
801065c9:	83 c4 10             	add    $0x10,%esp
801065cc:	85 c0                	test   %eax,%eax
801065ce:	74 6a                	je     8010663a <copyuvm+0xd5>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
801065d0:	81 c7 00 00 00 80    	add    $0x80000000,%edi
801065d6:	83 ec 04             	sub    $0x4,%esp
801065d9:	68 00 10 00 00       	push   $0x1000
801065de:	57                   	push   %edi
801065df:	50                   	push   %eax
801065e0:	e8 2d d9 ff ff       	call   80103f12 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
801065e5:	83 c4 08             	add    $0x8,%esp
801065e8:	ff 75 e0             	pushl  -0x20(%ebp)
801065eb:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801065f1:	50                   	push   %eax
801065f2:	b9 00 10 00 00       	mov    $0x1000,%ecx
801065f7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801065fa:	8b 45 dc             	mov    -0x24(%ebp),%eax
801065fd:	e8 b6 f8 ff ff       	call   80105eb8 <mappages>
80106602:	83 c4 10             	add    $0x10,%esp
80106605:	85 c0                	test   %eax,%eax
80106607:	78 25                	js     8010662e <copyuvm+0xc9>
  for(i = 0; i < sz; i += PGSIZE){
80106609:	81 c6 00 10 00 00    	add    $0x1000,%esi
8010660f:	e9 71 ff ff ff       	jmp    80106585 <copyuvm+0x20>
      panic("copyuvm: pte should exist");
80106614:	83 ec 0c             	sub    $0xc,%esp
80106617:	68 b8 70 10 80       	push   $0x801070b8
8010661c:	e8 27 9d ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
80106621:	83 ec 0c             	sub    $0xc,%esp
80106624:	68 d2 70 10 80       	push   $0x801070d2
80106629:	e8 1a 9d ff ff       	call   80100348 <panic>
      kfree(mem);
8010662e:	83 ec 0c             	sub    $0xc,%esp
80106631:	53                   	push   %ebx
80106632:	e8 6d b9 ff ff       	call   80101fa4 <kfree>
      goto bad;
80106637:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
8010663a:	83 ec 0c             	sub    $0xc,%esp
8010663d:	ff 75 dc             	pushl  -0x24(%ebp)
80106640:	e8 f7 fd ff ff       	call   8010643c <freevm>
  return 0;
80106645:	83 c4 10             	add    $0x10,%esp
80106648:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
8010664f:	8b 45 dc             	mov    -0x24(%ebp),%eax
80106652:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106655:	5b                   	pop    %ebx
80106656:	5e                   	pop    %esi
80106657:	5f                   	pop    %edi
80106658:	5d                   	pop    %ebp
80106659:	c3                   	ret    

8010665a <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
8010665a:	55                   	push   %ebp
8010665b:	89 e5                	mov    %esp,%ebp
8010665d:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80106660:	b9 00 00 00 00       	mov    $0x0,%ecx
80106665:	8b 55 0c             	mov    0xc(%ebp),%edx
80106668:	8b 45 08             	mov    0x8(%ebp),%eax
8010666b:	e8 d0 f7 ff ff       	call   80105e40 <walkpgdir>
  if((*pte & PTE_P) == 0)
80106670:	8b 00                	mov    (%eax),%eax
80106672:	a8 01                	test   $0x1,%al
80106674:	74 10                	je     80106686 <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
80106676:	a8 04                	test   $0x4,%al
80106678:	74 13                	je     8010668d <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
8010667a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010667f:	05 00 00 00 80       	add    $0x80000000,%eax
}
80106684:	c9                   	leave  
80106685:	c3                   	ret    
    return 0;
80106686:	b8 00 00 00 00       	mov    $0x0,%eax
8010668b:	eb f7                	jmp    80106684 <uva2ka+0x2a>
    return 0;
8010668d:	b8 00 00 00 00       	mov    $0x0,%eax
80106692:	eb f0                	jmp    80106684 <uva2ka+0x2a>

80106694 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80106694:	55                   	push   %ebp
80106695:	89 e5                	mov    %esp,%ebp
80106697:	57                   	push   %edi
80106698:	56                   	push   %esi
80106699:	53                   	push   %ebx
8010669a:	83 ec 0c             	sub    $0xc,%esp
8010669d:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801066a0:	eb 25                	jmp    801066c7 <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
801066a2:	8b 55 0c             	mov    0xc(%ebp),%edx
801066a5:	29 f2                	sub    %esi,%edx
801066a7:	01 d0                	add    %edx,%eax
801066a9:	83 ec 04             	sub    $0x4,%esp
801066ac:	53                   	push   %ebx
801066ad:	ff 75 10             	pushl  0x10(%ebp)
801066b0:	50                   	push   %eax
801066b1:	e8 5c d8 ff ff       	call   80103f12 <memmove>
    len -= n;
801066b6:	29 df                	sub    %ebx,%edi
    buf += n;
801066b8:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
801066bb:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
801066c1:	89 45 0c             	mov    %eax,0xc(%ebp)
801066c4:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
801066c7:	85 ff                	test   %edi,%edi
801066c9:	74 2f                	je     801066fa <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
801066cb:	8b 75 0c             	mov    0xc(%ebp),%esi
801066ce:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
801066d4:	83 ec 08             	sub    $0x8,%esp
801066d7:	56                   	push   %esi
801066d8:	ff 75 08             	pushl  0x8(%ebp)
801066db:	e8 7a ff ff ff       	call   8010665a <uva2ka>
    if(pa0 == 0)
801066e0:	83 c4 10             	add    $0x10,%esp
801066e3:	85 c0                	test   %eax,%eax
801066e5:	74 20                	je     80106707 <copyout+0x73>
    n = PGSIZE - (va - va0);
801066e7:	89 f3                	mov    %esi,%ebx
801066e9:	2b 5d 0c             	sub    0xc(%ebp),%ebx
801066ec:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
801066f2:	39 df                	cmp    %ebx,%edi
801066f4:	73 ac                	jae    801066a2 <copyout+0xe>
      n = len;
801066f6:	89 fb                	mov    %edi,%ebx
801066f8:	eb a8                	jmp    801066a2 <copyout+0xe>
  }
  return 0;
801066fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
801066ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106702:	5b                   	pop    %ebx
80106703:	5e                   	pop    %esi
80106704:	5f                   	pop    %edi
80106705:	5d                   	pop    %ebp
80106706:	c3                   	ret    
      return -1;
80106707:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010670c:	eb f1                	jmp    801066ff <copyout+0x6b>
