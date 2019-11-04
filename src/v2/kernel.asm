
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
8010002d:	b8 59 2d 10 80       	mov    $0x80102d59,%eax
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
80100046:	e8 4a 3e 00 00       	call   80103e95 <acquire>

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
8010007c:	e8 79 3e 00 00       	call   80103efa <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 f5 3b 00 00       	call   80103c81 <acquiresleep>
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
801000ca:	e8 2b 3e 00 00       	call   80103efa <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 a7 3b 00 00       	call   80103c81 <acquiresleep>
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
801000ea:	68 c0 67 10 80       	push   $0x801067c0
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 d1 67 10 80       	push   $0x801067d1
80100100:	68 e0 b5 12 80       	push   $0x8012b5e0
80100105:	e8 4f 3c 00 00       	call   80103d59 <initlock>
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
8010013a:	68 d8 67 10 80       	push   $0x801067d8
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 06 3b 00 00       	call   80103c4e <initsleeplock>
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
801001a8:	e8 5e 3b 00 00       	call   80103d0b <holdingsleep>
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
801001cb:	68 df 67 10 80       	push   $0x801067df
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
801001e4:	e8 22 3b 00 00       	call   80103d0b <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 d7 3a 00 00       	call   80103cd0 <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 e0 b5 12 80 	movl   $0x8012b5e0,(%esp)
80100200:	e8 90 3c 00 00       	call   80103e95 <acquire>
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
8010024c:	e8 a9 3c 00 00       	call   80103efa <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 e6 67 10 80       	push   $0x801067e6
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
8010028a:	e8 06 3c 00 00       	call   80103e95 <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 c0 ff 12 80       	mov    0x8012ffc0,%eax
8010029f:	3b 05 c4 ff 12 80    	cmp    0x8012ffc4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 47 32 00 00       	call   801034f3 <myproc>
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
801002bf:	e8 d6 36 00 00       	call   8010399a <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 a5 12 80       	push   $0x8012a520
801002d1:	e8 24 3c 00 00       	call   80103efa <release>
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
80100331:	e8 c4 3b 00 00       	call   80103efa <release>
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
8010035a:	e8 14 23 00 00       	call   80102673 <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 ed 67 10 80       	push   $0x801067ed
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 3b 71 10 80 	movl   $0x8010713b,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 e0 39 00 00       	call   80103d74 <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 01 68 10 80       	push   $0x80106801
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
8010049e:	68 05 68 10 80       	push   $0x80106805
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 fd 3a 00 00       	call   80103fbc <memmove>
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
801004d9:	e8 63 3a 00 00       	call   80103f41 <memset>
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
80100506:	e8 70 4e 00 00       	call   8010537b <uartputc>
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
8010051f:	e8 57 4e 00 00       	call   8010537b <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 4b 4e 00 00       	call   8010537b <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 3f 4e 00 00       	call   8010537b <uartputc>
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
80100576:	0f b6 92 30 68 10 80 	movzbl -0x7fef97d0(%edx),%edx
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
801005ca:	e8 c6 38 00 00       	call   80103e95 <acquire>
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
801005f1:	e8 04 39 00 00       	call   80103efa <release>
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
80100638:	e8 58 38 00 00       	call   80103e95 <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 1f 68 10 80       	push   $0x8010681f
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
801006ee:	be 18 68 10 80       	mov    $0x80106818,%esi
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
80100734:	e8 c1 37 00 00       	call   80103efa <release>
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
8010074f:	e8 41 37 00 00       	call   80103e95 <acquire>
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
801007de:	e8 1c 33 00 00       	call   80103aff <wakeup>
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
80100873:	e8 82 36 00 00       	call   80103efa <release>
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
80100887:	e8 10 33 00 00       	call   80103b9c <procdump>
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
80100894:	68 28 68 10 80       	push   $0x80106828
80100899:	68 20 a5 12 80       	push   $0x8012a520
8010089e:	e8 b6 34 00 00       	call   80103d59 <initlock>

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
801008de:	e8 10 2c 00 00       	call   801034f3 <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 b5 21 00 00       	call   80102aa3 <begin_op>

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
80100935:	e8 e3 21 00 00       	call   80102b1d <end_op>
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
8010094a:	e8 ce 21 00 00       	call   80102b1d <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 41 68 10 80       	push   $0x80106841
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
80100972:	e8 df 5b 00 00       	call   80106556 <setupkvm>
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
80100a06:	e8 e3 59 00 00       	call   801063ee <allocuvm>
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
80100a38:	e8 7f 58 00 00       	call   801062bc <loaduvm>
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
80100a53:	e8 c5 20 00 00       	call   80102b1d <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 75 59 00 00       	call   801063ee <allocuvm>
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
80100a9d:	e8 44 5a 00 00       	call   801064e6 <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 22 5b 00 00       	call   801065e3 <clearpteu>
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
80100ae2:	e8 fc 35 00 00       	call   801040e3 <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 ea 35 00 00       	call   801040e3 <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 33 5c 00 00       	call   8010673e <copyout>
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
80100b66:	e8 d3 5b 00 00       	call   8010673e <copyout>
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
80100ba3:	e8 00 35 00 00       	call   801040a8 <safestrcpy>
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
80100bd1:	e8 60 55 00 00       	call   80106136 <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 08 59 00 00       	call   801064e6 <freevm>
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
80100c19:	68 4d 68 10 80       	push   $0x8010684d
80100c1e:	68 e0 ff 12 80       	push   $0x8012ffe0
80100c23:	e8 31 31 00 00       	call   80103d59 <initlock>
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
80100c39:	e8 57 32 00 00       	call   80103e95 <acquire>
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
80100c68:	e8 8d 32 00 00       	call   80103efa <release>
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
80100c7f:	e8 76 32 00 00       	call   80103efa <release>
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
80100c9d:	e8 f3 31 00 00       	call   80103e95 <acquire>
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
80100cba:	e8 3b 32 00 00       	call   80103efa <release>
  return f;
}
80100cbf:	89 d8                	mov    %ebx,%eax
80100cc1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cc4:	c9                   	leave  
80100cc5:	c3                   	ret    
    panic("filedup");
80100cc6:	83 ec 0c             	sub    $0xc,%esp
80100cc9:	68 54 68 10 80       	push   $0x80106854
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
80100ce2:	e8 ae 31 00 00       	call   80103e95 <acquire>
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
80100d03:	e8 f2 31 00 00       	call   80103efa <release>
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
80100d13:	68 5c 68 10 80       	push   $0x8010685c
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
80100d49:	e8 ac 31 00 00       	call   80103efa <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 40 1d 00 00       	call   80102aa3 <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 aa 1d 00 00       	call   80102b1d <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 97 23 00 00       	call   8010311f <pipeclose>
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
80100e3c:	e8 36 24 00 00       	call   80103277 <piperead>
80100e41:	89 c6                	mov    %eax,%esi
80100e43:	83 c4 10             	add    $0x10,%esp
80100e46:	eb df                	jmp    80100e27 <fileread+0x50>
  panic("fileread");
80100e48:	83 ec 0c             	sub    $0xc,%esp
80100e4b:	68 66 68 10 80       	push   $0x80106866
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
80100e95:	e8 11 23 00 00       	call   801031ab <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 fc 1b 00 00       	call   80102aa3 <begin_op>
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
80100edd:	e8 3b 1c 00 00       	call   80102b1d <end_op>

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
80100f10:	68 6f 68 10 80       	push   $0x8010686f
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
80100f2d:	68 75 68 10 80       	push   $0x80106875
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
80100f8a:	e8 2d 30 00 00       	call   80103fbc <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 1d 30 00 00       	call   80103fbc <memmove>
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
80100fdf:	e8 5d 2f 00 00       	call   80103f41 <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 e0 1b 00 00       	call   80102bcc <log_write>
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
801010a3:	68 7f 68 10 80       	push   $0x8010687f
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
801010bf:	e8 08 1b 00 00       	call   80102bcc <log_write>
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
80101170:	e8 57 1a 00 00       	call   80102bcc <log_write>
80101175:	83 c4 10             	add    $0x10,%esp
80101178:	eb bf                	jmp    80101139 <bmap+0x58>
  panic("bmap: out of range");
8010117a:	83 ec 0c             	sub    $0xc,%esp
8010117d:	68 95 68 10 80       	push   $0x80106895
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
8010119a:	e8 f6 2c 00 00       	call   80103e95 <acquire>
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
801011e1:	e8 14 2d 00 00       	call   80103efa <release>
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
80101217:	e8 de 2c 00 00       	call   80103efa <release>
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
8010122c:	68 a8 68 10 80       	push   $0x801068a8
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
80101255:	e8 62 2d 00 00       	call   80103fbc <memmove>
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
801012c8:	e8 ff 18 00 00       	call   80102bcc <log_write>
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
801012e2:	68 b8 68 10 80       	push   $0x801068b8
801012e7:	e8 5c f0 ff ff       	call   80100348 <panic>

801012ec <iinit>:
{
801012ec:	55                   	push   %ebp
801012ed:	89 e5                	mov    %esp,%ebp
801012ef:	53                   	push   %ebx
801012f0:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012f3:	68 cb 68 10 80       	push   $0x801068cb
801012f8:	68 00 0a 13 80       	push   $0x80130a00
801012fd:	e8 57 2a 00 00       	call   80103d59 <initlock>
  for(i = 0; i < NINODE; i++) {
80101302:	83 c4 10             	add    $0x10,%esp
80101305:	bb 00 00 00 00       	mov    $0x0,%ebx
8010130a:	eb 21                	jmp    8010132d <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
8010130c:	83 ec 08             	sub    $0x8,%esp
8010130f:	68 d2 68 10 80       	push   $0x801068d2
80101314:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101317:	89 d0                	mov    %edx,%eax
80101319:	c1 e0 04             	shl    $0x4,%eax
8010131c:	05 40 0a 13 80       	add    $0x80130a40,%eax
80101321:	50                   	push   %eax
80101322:	e8 27 29 00 00       	call   80103c4e <initsleeplock>
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
8010136c:	68 38 69 10 80       	push   $0x80106938
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
801013df:	68 d8 68 10 80       	push   $0x801068d8
801013e4:	e8 5f ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013e9:	83 ec 04             	sub    $0x4,%esp
801013ec:	6a 40                	push   $0x40
801013ee:	6a 00                	push   $0x0
801013f0:	57                   	push   %edi
801013f1:	e8 4b 2b 00 00       	call   80103f41 <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 c7 17 00 00       	call   80102bcc <log_write>
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
80101480:	e8 37 2b 00 00       	call   80103fbc <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 3f 17 00 00       	call   80102bcc <log_write>
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
80101560:	e8 30 29 00 00       	call   80103e95 <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 00 0a 13 80 	movl   $0x80130a00,(%esp)
80101575:	e8 80 29 00 00       	call   80103efa <release>
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
8010159a:	e8 e2 26 00 00       	call   80103c81 <acquiresleep>
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
801015b2:	68 ea 68 10 80       	push   $0x801068ea
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
80101614:	e8 a3 29 00 00       	call   80103fbc <memmove>
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
80101639:	68 f0 68 10 80       	push   $0x801068f0
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
80101656:	e8 b0 26 00 00       	call   80103d0b <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 5f 26 00 00       	call   80103cd0 <releasesleep>
}
80101671:	83 c4 10             	add    $0x10,%esp
80101674:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101677:	5b                   	pop    %ebx
80101678:	5e                   	pop    %esi
80101679:	5d                   	pop    %ebp
8010167a:	c3                   	ret    
    panic("iunlock");
8010167b:	83 ec 0c             	sub    $0xc,%esp
8010167e:	68 ff 68 10 80       	push   $0x801068ff
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
80101698:	e8 e4 25 00 00       	call   80103c81 <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 1a 26 00 00       	call   80103cd0 <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 00 0a 13 80 	movl   $0x80130a00,(%esp)
801016bd:	e8 d3 27 00 00       	call   80103e95 <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 00 0a 13 80 	movl   $0x80130a00,(%esp)
801016d2:	e8 23 28 00 00       	call   80103efa <release>
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
801016ea:	e8 a6 27 00 00       	call   80103e95 <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 00 0a 13 80 	movl   $0x80130a00,(%esp)
801016f9:	e8 fc 27 00 00       	call   80103efa <release>
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
8010182a:	e8 8d 27 00 00       	call   80103fbc <memmove>
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
80101926:	e8 91 26 00 00       	call   80103fbc <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 99 12 00 00       	call   80102bcc <log_write>
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
801019a9:	e8 75 26 00 00       	call   80104023 <strncmp>
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
801019d0:	68 07 69 10 80       	push   $0x80106907
801019d5:	e8 6e e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019da:	83 ec 0c             	sub    $0xc,%esp
801019dd:	68 19 69 10 80       	push   $0x80106919
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
80101a5a:	e8 94 1a 00 00       	call   801034f3 <myproc>
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
80101b92:	68 28 69 10 80       	push   $0x80106928
80101b97:	e8 ac e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b9c:	83 ec 04             	sub    $0x4,%esp
80101b9f:	6a 0e                	push   $0xe
80101ba1:	57                   	push   %edi
80101ba2:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101ba5:	8d 45 da             	lea    -0x26(%ebp),%eax
80101ba8:	50                   	push   %eax
80101ba9:	e8 b2 24 00 00       	call   80104060 <strncpy>
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
80101bd7:	68 34 6f 10 80       	push   $0x80106f34
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
80101ccc:	68 8b 69 10 80       	push   $0x8010698b
80101cd1:	e8 72 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101cd6:	83 ec 0c             	sub    $0xc,%esp
80101cd9:	68 94 69 10 80       	push   $0x80106994
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
80101d06:	68 a6 69 10 80       	push   $0x801069a6
80101d0b:	68 80 a5 12 80       	push   $0x8012a580
80101d10:	e8 44 20 00 00       	call   80103d59 <initlock>
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
80101d80:	e8 10 21 00 00       	call   80103e95 <acquire>

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
80101dad:	e8 4d 1d 00 00       	call   80103aff <wakeup>

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
80101dcb:	e8 2a 21 00 00       	call   80103efa <release>
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
80101de2:	e8 13 21 00 00       	call   80103efa <release>
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
80101e1a:	e8 ec 1e 00 00       	call   80103d0b <holdingsleep>
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
80101e47:	e8 49 20 00 00       	call   80103e95 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e4c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e53:	83 c4 10             	add    $0x10,%esp
80101e56:	ba 64 a5 12 80       	mov    $0x8012a564,%edx
80101e5b:	eb 2a                	jmp    80101e87 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e5d:	83 ec 0c             	sub    $0xc,%esp
80101e60:	68 aa 69 10 80       	push   $0x801069aa
80101e65:	e8 de e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	68 c0 69 10 80       	push   $0x801069c0
80101e72:	e8 d1 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e77:	83 ec 0c             	sub    $0xc,%esp
80101e7a:	68 d5 69 10 80       	push   $0x801069d5
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
80101ea9:	e8 ec 1a 00 00       	call   8010399a <sleep>
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
80101ec3:	e8 32 20 00 00       	call   80103efa <release>
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
80101f3f:	68 f4 69 10 80       	push   $0x801069f4
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

80101fa4 <kfree2>:
  freerange(vstart, vend);
  kmem.use_lock = 1;
}
void
kfree2(char *v)
{
80101fa4:	55                   	push   %ebp
80101fa5:	89 e5                	mov    %esp,%ebp
80101fa7:	53                   	push   %ebx
80101fa8:	83 ec 04             	sub    $0x4,%esp
80101fab:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80101fae:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80101fb4:	75 4c                	jne    80102002 <kfree2+0x5e>
80101fb6:	81 fb e8 54 13 80    	cmp    $0x801354e8,%ebx
80101fbc:	72 44                	jb     80102002 <kfree2+0x5e>
80101fbe:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80101fc4:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80101fc9:	77 37                	ja     80102002 <kfree2+0x5e>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80101fcb:	83 ec 04             	sub    $0x4,%esp
80101fce:	68 00 10 00 00       	push   $0x1000
80101fd3:	6a 01                	push   $0x1
80101fd5:	53                   	push   %ebx
80101fd6:	e8 66 1f 00 00       	call   80103f41 <memset>

  if(kmem.use_lock)
80101fdb:	83 c4 10             	add    $0x10,%esp
80101fde:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
80101fe5:	75 28                	jne    8010200f <kfree2+0x6b>
    acquire(&kmem.lock);
  r = (struct run*)v;

  //add to free list
  r->next = kmem.freelist;
80101fe7:	a1 98 26 13 80       	mov    0x80132698,%eax
80101fec:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
80101fee:	89 1d 98 26 13 80    	mov    %ebx,0x80132698



  if(kmem.use_lock)
80101ff4:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
80101ffb:	75 24                	jne    80102021 <kfree2+0x7d>
    release(&kmem.lock);
}
80101ffd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102000:	c9                   	leave  
80102001:	c3                   	ret    
    panic("kfree");
80102002:	83 ec 0c             	sub    $0xc,%esp
80102005:	68 26 6a 10 80       	push   $0x80106a26
8010200a:	e8 39 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
8010200f:	83 ec 0c             	sub    $0xc,%esp
80102012:	68 60 26 13 80       	push   $0x80132660
80102017:	e8 79 1e 00 00       	call   80103e95 <acquire>
8010201c:	83 c4 10             	add    $0x10,%esp
8010201f:	eb c6                	jmp    80101fe7 <kfree2+0x43>
    release(&kmem.lock);
80102021:	83 ec 0c             	sub    $0xc,%esp
80102024:	68 60 26 13 80       	push   $0x80132660
80102029:	e8 cc 1e 00 00       	call   80103efa <release>
8010202e:	83 c4 10             	add    $0x10,%esp
}
80102031:	eb ca                	jmp    80101ffd <kfree2+0x59>

80102033 <freerange>:

void
freerange(void *vstart, void *vend)
{
80102033:	55                   	push   %ebp
80102034:	89 e5                	mov    %esp,%ebp
80102036:	56                   	push   %esi
80102037:	53                   	push   %ebx
80102038:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
8010203b:	8b 45 08             	mov    0x8(%ebp),%eax
8010203e:	05 ff 0f 00 00       	add    $0xfff,%eax
80102043:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102048:	eb 0e                	jmp    80102058 <freerange+0x25>
    kfree2(p);
8010204a:	83 ec 0c             	sub    $0xc,%esp
8010204d:	50                   	push   %eax
8010204e:	e8 51 ff ff ff       	call   80101fa4 <kfree2>
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
8010206f:	68 2c 6a 10 80       	push   $0x80106a2c
80102074:	68 60 26 13 80       	push   $0x80132660
80102079:	e8 db 1c 00 00       	call   80103d59 <initlock>
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

801020c5 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
801020c5:	55                   	push   %ebp
801020c6:	89 e5                	mov    %esp,%ebp
801020c8:	56                   	push   %esi
801020c9:	53                   	push   %ebx
801020ca:	8b 75 08             	mov    0x8(%ebp),%esi
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
801020cd:	f7 c6 ff 0f 00 00    	test   $0xfff,%esi
801020d3:	75 65                	jne    8010213a <kfree+0x75>
801020d5:	81 fe e8 54 13 80    	cmp    $0x801354e8,%esi
801020db:	72 5d                	jb     8010213a <kfree+0x75>
801020dd:	8d 9e 00 00 00 80    	lea    -0x80000000(%esi),%ebx
801020e3:	81 fb ff ff ff 0d    	cmp    $0xdffffff,%ebx
801020e9:	77 4f                	ja     8010213a <kfree+0x75>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
801020eb:	83 ec 04             	sub    $0x4,%esp
801020ee:	68 00 10 00 00       	push   $0x1000
801020f3:	6a 01                	push   $0x1
801020f5:	56                   	push   %esi
801020f6:	e8 46 1e 00 00       	call   80103f41 <memset>

  if(kmem.use_lock)
801020fb:	83 c4 10             	add    $0x10,%esp
801020fe:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
80102105:	75 40                	jne    80102147 <kfree+0x82>
    acquire(&kmem.lock);
  r = (struct run*)v;

  //add to free list
  r->next = kmem.freelist;
80102107:	a1 98 26 13 80       	mov    0x80132698,%eax
8010210c:	89 06                	mov    %eax,(%esi)
  kmem.freelist = r;
8010210e:	89 35 98 26 13 80    	mov    %esi,0x80132698


  // V2P and shift, and mask off
  pfn_kfree = (uint)(V2P(r) >> 12 & 0xffff);
80102114:	c1 eb 0c             	shr    $0xc,%ebx
80102117:	0f b7 d3             	movzwl %bx,%edx
8010211a:	89 15 9c 26 13 80    	mov    %edx,0x8013269c

  //int freeInd = 0;
  for(int i =0; i < 16835; i++){
80102120:	b8 00 00 00 00       	mov    $0x0,%eax
80102125:	3d c2 41 00 00       	cmp    $0x41c2,%eax
8010212a:	7f 43                	jg     8010216f <kfree+0xaa>
    if(frames[i] == pfn_kfree){
8010212c:	3b 14 85 20 80 11 80 	cmp    -0x7fee7fe0(,%eax,4),%edx
80102133:	74 24                	je     80102159 <kfree+0x94>
  for(int i =0; i < 16835; i++){
80102135:	83 c0 01             	add    $0x1,%eax
80102138:	eb eb                	jmp    80102125 <kfree+0x60>
    panic("kfree");
8010213a:	83 ec 0c             	sub    $0xc,%esp
8010213d:	68 26 6a 10 80       	push   $0x80106a26
80102142:	e8 01 e2 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
80102147:	83 ec 0c             	sub    $0xc,%esp
8010214a:	68 60 26 13 80       	push   $0x80132660
8010214f:	e8 41 1d 00 00       	call   80103e95 <acquire>
80102154:	83 c4 10             	add    $0x10,%esp
80102157:	eb ae                	jmp    80102107 <kfree+0x42>
      frames[i] = -1;
80102159:	c7 04 85 20 80 11 80 	movl   $0xffffffff,-0x7fee7fe0(,%eax,4)
80102160:	ff ff ff ff 
      pids[i] = -1;
80102164:	c7 04 85 00 80 10 80 	movl   $0xffffffff,-0x7fef8000(,%eax,4)
8010216b:	ff ff ff ff 
  // }

  // frames[16384] = -1;
  // pids[16384] = -1;

  if(kmem.use_lock)
8010216f:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
80102176:	75 07                	jne    8010217f <kfree+0xba>
    release(&kmem.lock);
}
80102178:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010217b:	5b                   	pop    %ebx
8010217c:	5e                   	pop    %esi
8010217d:	5d                   	pop    %ebp
8010217e:	c3                   	ret    
    release(&kmem.lock);
8010217f:	83 ec 0c             	sub    $0xc,%esp
80102182:	68 60 26 13 80       	push   $0x80132660
80102187:	e8 6e 1d 00 00       	call   80103efa <release>
8010218c:	83 c4 10             	add    $0x10,%esp
}
8010218f:	eb e7                	jmp    80102178 <kfree+0xb3>

80102191 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102191:	55                   	push   %ebp
80102192:	89 e5                	mov    %esp,%ebp
80102194:	53                   	push   %ebx
80102195:	83 ec 04             	sub    $0x4,%esp
  struct run *r;

  if(kmem.use_lock)
80102198:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
8010219f:	75 33                	jne    801021d4 <kalloc+0x43>
    acquire(&kmem.lock);
  r = kmem.freelist;
801021a1:	8b 1d 98 26 13 80    	mov    0x80132698,%ebx
  
  // V2P and shift, and mask off
  framenumber = (uint)(V2P(r) >> 12 & 0xffff);
801021a7:	8d 93 00 00 00 80    	lea    -0x80000000(%ebx),%edx
801021ad:	c1 ea 0c             	shr    $0xc,%edx
801021b0:	0f b7 d2             	movzwl %dx,%edx
801021b3:	89 15 a0 26 13 80    	mov    %edx,0x801326a0

  if(r){
801021b9:	85 db                	test   %ebx,%ebx
801021bb:	74 07                	je     801021c4 <kalloc+0x33>
    kmem.freelist = r->next;
801021bd:	8b 03                	mov    (%ebx),%eax
801021bf:	a3 98 26 13 80       	mov    %eax,0x80132698
  }

  if(kmem.use_lock) {
801021c4:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
801021cb:	74 51                	je     8010221e <kalloc+0x8d>
    for(int i =0 ; i < 16385; i++){
801021cd:	b8 00 00 00 00       	mov    $0x0,%eax
801021d2:	eb 15                	jmp    801021e9 <kalloc+0x58>
    acquire(&kmem.lock);
801021d4:	83 ec 0c             	sub    $0xc,%esp
801021d7:	68 60 26 13 80       	push   $0x80132660
801021dc:	e8 b4 1c 00 00       	call   80103e95 <acquire>
801021e1:	83 c4 10             	add    $0x10,%esp
801021e4:	eb bb                	jmp    801021a1 <kalloc+0x10>
    for(int i =0 ; i < 16385; i++){
801021e6:	83 c0 01             	add    $0x1,%eax
801021e9:	3d 00 40 00 00       	cmp    $0x4000,%eax
801021ee:	7f 1e                	jg     8010220e <kalloc+0x7d>
      if(frames[i] == -1){
801021f0:	83 3c 85 20 80 11 80 	cmpl   $0xffffffff,-0x7fee7fe0(,%eax,4)
801021f7:	ff 
801021f8:	75 ec                	jne    801021e6 <kalloc+0x55>
        frames[i] = framenumber;
801021fa:	89 14 85 20 80 11 80 	mov    %edx,-0x7fee7fe0(,%eax,4)
        pids[i] = 1;
80102201:	c7 04 85 00 80 10 80 	movl   $0x1,-0x7fef8000(,%eax,4)
80102208:	01 00 00 00 
8010220c:	eb d8                	jmp    801021e6 <kalloc+0x55>
    }
    //cprintf("index in kalloc is %d \n", index);    
    // frames[index] = framenumber;
    // pids[index] = 1;
    // index++;
    release(&kmem.lock);
8010220e:	83 ec 0c             	sub    $0xc,%esp
80102211:	68 60 26 13 80       	push   $0x80132660
80102216:	e8 df 1c 00 00       	call   80103efa <release>
8010221b:	83 c4 10             	add    $0x10,%esp
  }
  return (char*)r;
}
8010221e:	89 d8                	mov    %ebx,%eax
80102220:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102223:	c9                   	leave  
80102224:	c3                   	ret    

80102225 <kalloc2>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc2(uint pid)
{
80102225:	55                   	push   %ebp
80102226:	89 e5                	mov    %esp,%ebp
80102228:	57                   	push   %edi
80102229:	56                   	push   %esi
8010222a:	53                   	push   %ebx
8010222b:	83 ec 1c             	sub    $0x1c,%esp
  struct run *prev; // previous head of the freelist
  struct run *head; // stores current head of the freelist
  uint nextPid = -1;
  uint prevPid = -1;

  if(kmem.use_lock)
8010222e:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
80102235:	75 1b                	jne    80102252 <kalloc2+0x2d>
    acquire(&kmem.lock);
  r = kmem.freelist; // head which acts as a current pointer
80102237:	8b 1d 98 26 13 80    	mov    0x80132698,%ebx
8010223d:	89 5d dc             	mov    %ebx,-0x24(%ebp)
  head = kmem.freelist;
  //cprintf("kalloc2\n");
  prev = head;
80102240:	89 5d e0             	mov    %ebx,-0x20(%ebp)
  uint prevPid = -1;
80102243:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
  uint nextPid = -1;
80102248:	be ff ff ff ff       	mov    $0xffffffff,%esi
  while(r){
8010224d:	e9 8f 00 00 00       	jmp    801022e1 <kalloc2+0xbc>
    acquire(&kmem.lock);
80102252:	83 ec 0c             	sub    $0xc,%esp
80102255:	68 60 26 13 80       	push   $0x80132660
8010225a:	e8 36 1c 00 00       	call   80103e95 <acquire>
8010225f:	83 c4 10             	add    $0x10,%esp
80102262:	eb d3                	jmp    80102237 <kalloc2+0x12>
      // if (frames[i] == -1) {
      //   prevPid = -1;
      //   break;
      // }
      if (frames[i] == framenumber - 1) {
        prevPid = pids[i];
80102264:	8b 0c 85 00 80 10 80 	mov    -0x7fef8000(,%eax,4),%ecx
        break;
      }
    }
    //looking at 1 frame after current to check for same process
    for(int j = 0; j < 16385; j++){
8010226b:	b8 00 00 00 00       	mov    $0x0,%eax
80102270:	3d 00 40 00 00       	cmp    $0x4000,%eax
80102275:	7f 18                	jg     8010228f <kalloc2+0x6a>
      // if (frames[j] == -1) {
      //   nextPid = -1;
      //   break;
      // }
      if(frames[j] == framenumber + 1){
80102277:	8d 7a 01             	lea    0x1(%edx),%edi
8010227a:	39 3c 85 20 80 11 80 	cmp    %edi,-0x7fee7fe0(,%eax,4)
80102281:	74 05                	je     80102288 <kalloc2+0x63>
    for(int j = 0; j < 16385; j++){
80102283:	83 c0 01             	add    $0x1,%eax
80102286:	eb e8                	jmp    80102270 <kalloc2+0x4b>
        nextPid = pids[j];
80102288:	8b 34 85 00 80 10 80 	mov    -0x7fef8000(,%eax,4),%esi
        break;
      }
    }

    //cprintf("IN while loop\n");
    if(((prevPid == pid || prevPid == -2) && (nextPid == pid || nextPid == -2)) // if both are not free
8010228f:	3b 4d 08             	cmp    0x8(%ebp),%ecx
80102292:	0f 94 c2             	sete   %dl
80102295:	83 f9 fe             	cmp    $0xfffffffe,%ecx
80102298:	0f 94 c0             	sete   %al
8010229b:	08 d0                	or     %dl,%al
8010229d:	88 45 e7             	mov    %al,-0x19(%ebp)
801022a0:	74 10                	je     801022b2 <kalloc2+0x8d>
801022a2:	3b 75 08             	cmp    0x8(%ebp),%esi
801022a5:	0f 94 c0             	sete   %al
801022a8:	83 fe fe             	cmp    $0xfffffffe,%esi
801022ab:	0f 94 c2             	sete   %dl
801022ae:	08 d0                	or     %dl,%al
801022b0:	75 7a                	jne    8010232c <kalloc2+0x107>
          || (prevPid == -1 && nextPid == -1) // if both are free
801022b2:	83 f9 ff             	cmp    $0xffffffff,%ecx
801022b5:	0f 94 c2             	sete   %dl
801022b8:	89 d7                	mov    %edx,%edi
801022ba:	83 fe ff             	cmp    $0xffffffff,%esi
801022bd:	0f 94 c2             	sete   %dl
801022c0:	89 f8                	mov    %edi,%eax
801022c2:	84 d0                	test   %dl,%al
801022c4:	75 66                	jne    8010232c <kalloc2+0x107>
          || ((pid == prevPid || prevPid == -2) && nextPid == -1) // if left is not free
801022c6:	80 7d e7 00          	cmpb   $0x0,-0x19(%ebp)
801022ca:	74 05                	je     801022d1 <kalloc2+0xac>
801022cc:	83 fe ff             	cmp    $0xffffffff,%esi
801022cf:	74 5b                	je     8010232c <kalloc2+0x107>
          || ((prevPid == -1 && (pid == nextPid || nextPid == -2))) // if right is not free
801022d1:	83 f9 ff             	cmp    $0xffffffff,%ecx
801022d4:	74 46                	je     8010231c <kalloc2+0xf7>
          || (pid == -2)){
801022d6:	83 7d 08 fe          	cmpl   $0xfffffffe,0x8(%ebp)
801022da:	74 50                	je     8010232c <kalloc2+0x107>
          prev->next = r->next;
          break;
        }
      }

      prev = r;
801022dc:	89 5d e0             	mov    %ebx,-0x20(%ebp)
      r = r->next;  
801022df:	8b 1b                	mov    (%ebx),%ebx
  while(r){
801022e1:	85 db                	test   %ebx,%ebx
801022e3:	74 53                	je     80102338 <kalloc2+0x113>
    framenumber = (uint)(V2P(r) >> 12 & 0xffff);
801022e5:	8d 93 00 00 00 80    	lea    -0x80000000(%ebx),%edx
801022eb:	c1 ea 0c             	shr    $0xc,%edx
801022ee:	0f b7 d2             	movzwl %dx,%edx
801022f1:	89 15 a0 26 13 80    	mov    %edx,0x801326a0
    for(int i = 0; i < 16385; i++){
801022f7:	b8 00 00 00 00       	mov    $0x0,%eax
801022fc:	3d 00 40 00 00       	cmp    $0x4000,%eax
80102301:	0f 8f 64 ff ff ff    	jg     8010226b <kalloc2+0x46>
      if (frames[i] == framenumber - 1) {
80102307:	8d 7a ff             	lea    -0x1(%edx),%edi
8010230a:	39 3c 85 20 80 11 80 	cmp    %edi,-0x7fee7fe0(,%eax,4)
80102311:	0f 84 4d ff ff ff    	je     80102264 <kalloc2+0x3f>
    for(int i = 0; i < 16385; i++){
80102317:	83 c0 01             	add    $0x1,%eax
8010231a:	eb e0                	jmp    801022fc <kalloc2+0xd7>
          || ((prevPid == -1 && (pid == nextPid || nextPid == -2))) // if right is not free
8010231c:	3b 75 08             	cmp    0x8(%ebp),%esi
8010231f:	0f 94 c2             	sete   %dl
80102322:	83 fe fe             	cmp    $0xfffffffe,%esi
80102325:	0f 94 c0             	sete   %al
80102328:	08 c2                	or     %al,%dl
8010232a:	74 aa                	je     801022d6 <kalloc2+0xb1>
        if (r == head){
8010232c:	3b 5d dc             	cmp    -0x24(%ebp),%ebx
8010232f:	74 23                	je     80102354 <kalloc2+0x12f>
          prev->next = r->next;
80102331:	8b 03                	mov    (%ebx),%eax
80102333:	8b 75 e0             	mov    -0x20(%ebp),%esi
80102336:	89 06                	mov    %eax,(%esi)
    }
  // cprintf("frame_number = %x  and pid = %d \n", framenumber, pid);

  if (flag == 1){
80102338:	83 3d b4 a5 12 80 01 	cmpl   $0x1,0x8012a5b4
8010233f:	74 35                	je     80102376 <kalloc2+0x151>
    //cprintf("PIDS: %d \n", pids[index]);
    //cprintf("index = %d\n", index);
    //index++;
  }

  if(kmem.use_lock) {
80102341:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
80102348:	75 47                	jne    80102391 <kalloc2+0x16c>
    release(&kmem.lock);
  }
  return (char*)r;
}
8010234a:	89 d8                	mov    %ebx,%eax
8010234c:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010234f:	5b                   	pop    %ebx
80102350:	5e                   	pop    %esi
80102351:	5f                   	pop    %edi
80102352:	5d                   	pop    %ebp
80102353:	c3                   	ret    
          kmem.freelist = r->next;
80102354:	8b 03                	mov    (%ebx),%eax
80102356:	a3 98 26 13 80       	mov    %eax,0x80132698
          break;
8010235b:	eb db                	jmp    80102338 <kalloc2+0x113>
        frames[i] = framenumber;
8010235d:	8b 15 a0 26 13 80    	mov    0x801326a0,%edx
80102363:	89 14 85 20 80 11 80 	mov    %edx,-0x7fee7fe0(,%eax,4)
        pids[i] = pid;
8010236a:	8b 75 08             	mov    0x8(%ebp),%esi
8010236d:	89 34 85 00 80 10 80 	mov    %esi,-0x7fef8000(,%eax,4)
        break;
80102374:	eb cb                	jmp    80102341 <kalloc2+0x11c>
    for(int i = 0 ; i < 16385; i++){
80102376:	b8 00 00 00 00       	mov    $0x0,%eax
8010237b:	3d 00 40 00 00       	cmp    $0x4000,%eax
80102380:	7f bf                	jg     80102341 <kalloc2+0x11c>
      if(frames[i] == -1){
80102382:	83 3c 85 20 80 11 80 	cmpl   $0xffffffff,-0x7fee7fe0(,%eax,4)
80102389:	ff 
8010238a:	74 d1                	je     8010235d <kalloc2+0x138>
    for(int i = 0 ; i < 16385; i++){
8010238c:	83 c0 01             	add    $0x1,%eax
8010238f:	eb ea                	jmp    8010237b <kalloc2+0x156>
    release(&kmem.lock);
80102391:	83 ec 0c             	sub    $0xc,%esp
80102394:	68 60 26 13 80       	push   $0x80132660
80102399:	e8 5c 1b 00 00       	call   80103efa <release>
8010239e:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
801023a1:	eb a7                	jmp    8010234a <kalloc2+0x125>

801023a3 <dump_physmem>:

int
dump_physmem(int *frs, int *pds, int numframes)
{
801023a3:	55                   	push   %ebp
801023a4:	89 e5                	mov    %esp,%ebp
801023a6:	57                   	push   %edi
801023a7:	56                   	push   %esi
801023a8:	53                   	push   %ebx
801023a9:	8b 75 08             	mov    0x8(%ebp),%esi
801023ac:	8b 7d 0c             	mov    0xc(%ebp),%edi
801023af:	8b 5d 10             	mov    0x10(%ebp),%ebx
  if(numframes <= 0 || frs == 0 || pds == 0)
801023b2:	85 db                	test   %ebx,%ebx
801023b4:	0f 9e c2             	setle  %dl
801023b7:	85 f6                	test   %esi,%esi
801023b9:	0f 94 c0             	sete   %al
801023bc:	08 c2                	or     %al,%dl
801023be:	75 37                	jne    801023f7 <dump_physmem+0x54>
801023c0:	85 ff                	test   %edi,%edi
801023c2:	74 3a                	je     801023fe <dump_physmem+0x5b>
    return -1;
  for (int i = 0; i < numframes; i++) {
801023c4:	b8 00 00 00 00       	mov    $0x0,%eax
801023c9:	eb 1e                	jmp    801023e9 <dump_physmem+0x46>
    //if (frames[i] != -1) {
      frs[i] = frames[i];
801023cb:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801023d2:	8b 0c 85 20 80 11 80 	mov    -0x7fee7fe0(,%eax,4),%ecx
801023d9:	89 0c 16             	mov    %ecx,(%esi,%edx,1)
      pds[i] = pids[i];
801023dc:	8b 0c 85 00 80 10 80 	mov    -0x7fef8000(,%eax,4),%ecx
801023e3:	89 0c 17             	mov    %ecx,(%edi,%edx,1)
  for (int i = 0; i < numframes; i++) {
801023e6:	83 c0 01             	add    $0x1,%eax
801023e9:	39 d8                	cmp    %ebx,%eax
801023eb:	7c de                	jl     801023cb <dump_physmem+0x28>
    //}
  }
  return 0;
801023ed:	b8 00 00 00 00       	mov    $0x0,%eax
801023f2:	5b                   	pop    %ebx
801023f3:	5e                   	pop    %esi
801023f4:	5f                   	pop    %edi
801023f5:	5d                   	pop    %ebp
801023f6:	c3                   	ret    
    return -1;
801023f7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801023fc:	eb f4                	jmp    801023f2 <dump_physmem+0x4f>
801023fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102403:	eb ed                	jmp    801023f2 <dump_physmem+0x4f>

80102405 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102405:	55                   	push   %ebp
80102406:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102408:	ba 64 00 00 00       	mov    $0x64,%edx
8010240d:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
8010240e:	a8 01                	test   $0x1,%al
80102410:	0f 84 b5 00 00 00    	je     801024cb <kbdgetc+0xc6>
80102416:	ba 60 00 00 00       	mov    $0x60,%edx
8010241b:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
8010241c:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
8010241f:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
80102425:	74 5c                	je     80102483 <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
80102427:	84 c0                	test   %al,%al
80102429:	78 66                	js     80102491 <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
8010242b:	8b 0d b8 a5 12 80    	mov    0x8012a5b8,%ecx
80102431:	f6 c1 40             	test   $0x40,%cl
80102434:	74 0f                	je     80102445 <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102436:	83 c8 80             	or     $0xffffff80,%eax
80102439:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
8010243c:	83 e1 bf             	and    $0xffffffbf,%ecx
8010243f:	89 0d b8 a5 12 80    	mov    %ecx,0x8012a5b8
  }

  shift |= shiftcode[data];
80102445:	0f b6 8a 60 6b 10 80 	movzbl -0x7fef94a0(%edx),%ecx
8010244c:	0b 0d b8 a5 12 80    	or     0x8012a5b8,%ecx
  shift ^= togglecode[data];
80102452:	0f b6 82 60 6a 10 80 	movzbl -0x7fef95a0(%edx),%eax
80102459:	31 c1                	xor    %eax,%ecx
8010245b:	89 0d b8 a5 12 80    	mov    %ecx,0x8012a5b8
  c = charcode[shift & (CTL | SHIFT)][data];
80102461:	89 c8                	mov    %ecx,%eax
80102463:	83 e0 03             	and    $0x3,%eax
80102466:	8b 04 85 40 6a 10 80 	mov    -0x7fef95c0(,%eax,4),%eax
8010246d:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
80102471:	f6 c1 08             	test   $0x8,%cl
80102474:	74 19                	je     8010248f <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
80102476:	8d 50 9f             	lea    -0x61(%eax),%edx
80102479:	83 fa 19             	cmp    $0x19,%edx
8010247c:	77 40                	ja     801024be <kbdgetc+0xb9>
      c += 'A' - 'a';
8010247e:	83 e8 20             	sub    $0x20,%eax
80102481:	eb 0c                	jmp    8010248f <kbdgetc+0x8a>
    shift |= E0ESC;
80102483:	83 0d b8 a5 12 80 40 	orl    $0x40,0x8012a5b8
    return 0;
8010248a:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
8010248f:	5d                   	pop    %ebp
80102490:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
80102491:	8b 0d b8 a5 12 80    	mov    0x8012a5b8,%ecx
80102497:	f6 c1 40             	test   $0x40,%cl
8010249a:	75 05                	jne    801024a1 <kbdgetc+0x9c>
8010249c:	89 c2                	mov    %eax,%edx
8010249e:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
801024a1:	0f b6 82 60 6b 10 80 	movzbl -0x7fef94a0(%edx),%eax
801024a8:	83 c8 40             	or     $0x40,%eax
801024ab:	0f b6 c0             	movzbl %al,%eax
801024ae:	f7 d0                	not    %eax
801024b0:	21 c8                	and    %ecx,%eax
801024b2:	a3 b8 a5 12 80       	mov    %eax,0x8012a5b8
    return 0;
801024b7:	b8 00 00 00 00       	mov    $0x0,%eax
801024bc:	eb d1                	jmp    8010248f <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
801024be:	8d 50 bf             	lea    -0x41(%eax),%edx
801024c1:	83 fa 19             	cmp    $0x19,%edx
801024c4:	77 c9                	ja     8010248f <kbdgetc+0x8a>
      c += 'a' - 'A';
801024c6:	83 c0 20             	add    $0x20,%eax
  return c;
801024c9:	eb c4                	jmp    8010248f <kbdgetc+0x8a>
    return -1;
801024cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801024d0:	eb bd                	jmp    8010248f <kbdgetc+0x8a>

801024d2 <kbdintr>:

void
kbdintr(void)
{
801024d2:	55                   	push   %ebp
801024d3:	89 e5                	mov    %esp,%ebp
801024d5:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
801024d8:	68 05 24 10 80       	push   $0x80102405
801024dd:	e8 5c e2 ff ff       	call   8010073e <consoleintr>
}
801024e2:	83 c4 10             	add    $0x10,%esp
801024e5:	c9                   	leave  
801024e6:	c3                   	ret    

801024e7 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
801024e7:	55                   	push   %ebp
801024e8:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
801024ea:	8b 0d a4 26 13 80    	mov    0x801326a4,%ecx
801024f0:	8d 04 81             	lea    (%ecx,%eax,4),%eax
801024f3:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
801024f5:	a1 a4 26 13 80       	mov    0x801326a4,%eax
801024fa:	8b 40 20             	mov    0x20(%eax),%eax
}
801024fd:	5d                   	pop    %ebp
801024fe:	c3                   	ret    

801024ff <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
801024ff:	55                   	push   %ebp
80102500:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102502:	ba 70 00 00 00       	mov    $0x70,%edx
80102507:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102508:	ba 71 00 00 00       	mov    $0x71,%edx
8010250d:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
8010250e:	0f b6 c0             	movzbl %al,%eax
}
80102511:	5d                   	pop    %ebp
80102512:	c3                   	ret    

80102513 <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
80102513:	55                   	push   %ebp
80102514:	89 e5                	mov    %esp,%ebp
80102516:	53                   	push   %ebx
80102517:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
80102519:	b8 00 00 00 00       	mov    $0x0,%eax
8010251e:	e8 dc ff ff ff       	call   801024ff <cmos_read>
80102523:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
80102525:	b8 02 00 00 00       	mov    $0x2,%eax
8010252a:	e8 d0 ff ff ff       	call   801024ff <cmos_read>
8010252f:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
80102532:	b8 04 00 00 00       	mov    $0x4,%eax
80102537:	e8 c3 ff ff ff       	call   801024ff <cmos_read>
8010253c:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
8010253f:	b8 07 00 00 00       	mov    $0x7,%eax
80102544:	e8 b6 ff ff ff       	call   801024ff <cmos_read>
80102549:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
8010254c:	b8 08 00 00 00       	mov    $0x8,%eax
80102551:	e8 a9 ff ff ff       	call   801024ff <cmos_read>
80102556:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
80102559:	b8 09 00 00 00       	mov    $0x9,%eax
8010255e:	e8 9c ff ff ff       	call   801024ff <cmos_read>
80102563:	89 43 14             	mov    %eax,0x14(%ebx)
}
80102566:	5b                   	pop    %ebx
80102567:	5d                   	pop    %ebp
80102568:	c3                   	ret    

80102569 <lapicinit>:
  if(!lapic)
80102569:	83 3d a4 26 13 80 00 	cmpl   $0x0,0x801326a4
80102570:	0f 84 fb 00 00 00    	je     80102671 <lapicinit+0x108>
{
80102576:	55                   	push   %ebp
80102577:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102579:	ba 3f 01 00 00       	mov    $0x13f,%edx
8010257e:	b8 3c 00 00 00       	mov    $0x3c,%eax
80102583:	e8 5f ff ff ff       	call   801024e7 <lapicw>
  lapicw(TDCR, X1);
80102588:	ba 0b 00 00 00       	mov    $0xb,%edx
8010258d:	b8 f8 00 00 00       	mov    $0xf8,%eax
80102592:	e8 50 ff ff ff       	call   801024e7 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102597:	ba 20 00 02 00       	mov    $0x20020,%edx
8010259c:	b8 c8 00 00 00       	mov    $0xc8,%eax
801025a1:	e8 41 ff ff ff       	call   801024e7 <lapicw>
  lapicw(TICR, 10000000);
801025a6:	ba 80 96 98 00       	mov    $0x989680,%edx
801025ab:	b8 e0 00 00 00       	mov    $0xe0,%eax
801025b0:	e8 32 ff ff ff       	call   801024e7 <lapicw>
  lapicw(LINT0, MASKED);
801025b5:	ba 00 00 01 00       	mov    $0x10000,%edx
801025ba:	b8 d4 00 00 00       	mov    $0xd4,%eax
801025bf:	e8 23 ff ff ff       	call   801024e7 <lapicw>
  lapicw(LINT1, MASKED);
801025c4:	ba 00 00 01 00       	mov    $0x10000,%edx
801025c9:	b8 d8 00 00 00       	mov    $0xd8,%eax
801025ce:	e8 14 ff ff ff       	call   801024e7 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801025d3:	a1 a4 26 13 80       	mov    0x801326a4,%eax
801025d8:	8b 40 30             	mov    0x30(%eax),%eax
801025db:	c1 e8 10             	shr    $0x10,%eax
801025de:	3c 03                	cmp    $0x3,%al
801025e0:	77 7b                	ja     8010265d <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
801025e2:	ba 33 00 00 00       	mov    $0x33,%edx
801025e7:	b8 dc 00 00 00       	mov    $0xdc,%eax
801025ec:	e8 f6 fe ff ff       	call   801024e7 <lapicw>
  lapicw(ESR, 0);
801025f1:	ba 00 00 00 00       	mov    $0x0,%edx
801025f6:	b8 a0 00 00 00       	mov    $0xa0,%eax
801025fb:	e8 e7 fe ff ff       	call   801024e7 <lapicw>
  lapicw(ESR, 0);
80102600:	ba 00 00 00 00       	mov    $0x0,%edx
80102605:	b8 a0 00 00 00       	mov    $0xa0,%eax
8010260a:	e8 d8 fe ff ff       	call   801024e7 <lapicw>
  lapicw(EOI, 0);
8010260f:	ba 00 00 00 00       	mov    $0x0,%edx
80102614:	b8 2c 00 00 00       	mov    $0x2c,%eax
80102619:	e8 c9 fe ff ff       	call   801024e7 <lapicw>
  lapicw(ICRHI, 0);
8010261e:	ba 00 00 00 00       	mov    $0x0,%edx
80102623:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102628:	e8 ba fe ff ff       	call   801024e7 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
8010262d:	ba 00 85 08 00       	mov    $0x88500,%edx
80102632:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102637:	e8 ab fe ff ff       	call   801024e7 <lapicw>
  while(lapic[ICRLO] & DELIVS)
8010263c:	a1 a4 26 13 80       	mov    0x801326a4,%eax
80102641:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
80102647:	f6 c4 10             	test   $0x10,%ah
8010264a:	75 f0                	jne    8010263c <lapicinit+0xd3>
  lapicw(TPR, 0);
8010264c:	ba 00 00 00 00       	mov    $0x0,%edx
80102651:	b8 20 00 00 00       	mov    $0x20,%eax
80102656:	e8 8c fe ff ff       	call   801024e7 <lapicw>
}
8010265b:	5d                   	pop    %ebp
8010265c:	c3                   	ret    
    lapicw(PCINT, MASKED);
8010265d:	ba 00 00 01 00       	mov    $0x10000,%edx
80102662:	b8 d0 00 00 00       	mov    $0xd0,%eax
80102667:	e8 7b fe ff ff       	call   801024e7 <lapicw>
8010266c:	e9 71 ff ff ff       	jmp    801025e2 <lapicinit+0x79>
80102671:	f3 c3                	repz ret 

80102673 <lapicid>:
{
80102673:	55                   	push   %ebp
80102674:	89 e5                	mov    %esp,%ebp
  if (!lapic)
80102676:	a1 a4 26 13 80       	mov    0x801326a4,%eax
8010267b:	85 c0                	test   %eax,%eax
8010267d:	74 08                	je     80102687 <lapicid+0x14>
  return lapic[ID] >> 24;
8010267f:	8b 40 20             	mov    0x20(%eax),%eax
80102682:	c1 e8 18             	shr    $0x18,%eax
}
80102685:	5d                   	pop    %ebp
80102686:	c3                   	ret    
    return 0;
80102687:	b8 00 00 00 00       	mov    $0x0,%eax
8010268c:	eb f7                	jmp    80102685 <lapicid+0x12>

8010268e <lapiceoi>:
  if(lapic)
8010268e:	83 3d a4 26 13 80 00 	cmpl   $0x0,0x801326a4
80102695:	74 14                	je     801026ab <lapiceoi+0x1d>
{
80102697:	55                   	push   %ebp
80102698:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
8010269a:	ba 00 00 00 00       	mov    $0x0,%edx
8010269f:	b8 2c 00 00 00       	mov    $0x2c,%eax
801026a4:	e8 3e fe ff ff       	call   801024e7 <lapicw>
}
801026a9:	5d                   	pop    %ebp
801026aa:	c3                   	ret    
801026ab:	f3 c3                	repz ret 

801026ad <microdelay>:
{
801026ad:	55                   	push   %ebp
801026ae:	89 e5                	mov    %esp,%ebp
}
801026b0:	5d                   	pop    %ebp
801026b1:	c3                   	ret    

801026b2 <lapicstartap>:
{
801026b2:	55                   	push   %ebp
801026b3:	89 e5                	mov    %esp,%ebp
801026b5:	57                   	push   %edi
801026b6:	56                   	push   %esi
801026b7:	53                   	push   %ebx
801026b8:	8b 75 08             	mov    0x8(%ebp),%esi
801026bb:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801026be:	b8 0f 00 00 00       	mov    $0xf,%eax
801026c3:	ba 70 00 00 00       	mov    $0x70,%edx
801026c8:	ee                   	out    %al,(%dx)
801026c9:	b8 0a 00 00 00       	mov    $0xa,%eax
801026ce:	ba 71 00 00 00       	mov    $0x71,%edx
801026d3:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
801026d4:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
801026db:	00 00 
  wrv[1] = addr >> 4;
801026dd:	89 f8                	mov    %edi,%eax
801026df:	c1 e8 04             	shr    $0x4,%eax
801026e2:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
801026e8:	c1 e6 18             	shl    $0x18,%esi
801026eb:	89 f2                	mov    %esi,%edx
801026ed:	b8 c4 00 00 00       	mov    $0xc4,%eax
801026f2:	e8 f0 fd ff ff       	call   801024e7 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801026f7:	ba 00 c5 00 00       	mov    $0xc500,%edx
801026fc:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102701:	e8 e1 fd ff ff       	call   801024e7 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
80102706:	ba 00 85 00 00       	mov    $0x8500,%edx
8010270b:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102710:	e8 d2 fd ff ff       	call   801024e7 <lapicw>
  for(i = 0; i < 2; i++){
80102715:	bb 00 00 00 00       	mov    $0x0,%ebx
8010271a:	eb 21                	jmp    8010273d <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
8010271c:	89 f2                	mov    %esi,%edx
8010271e:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102723:	e8 bf fd ff ff       	call   801024e7 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80102728:	89 fa                	mov    %edi,%edx
8010272a:	c1 ea 0c             	shr    $0xc,%edx
8010272d:	80 ce 06             	or     $0x6,%dh
80102730:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102735:	e8 ad fd ff ff       	call   801024e7 <lapicw>
  for(i = 0; i < 2; i++){
8010273a:	83 c3 01             	add    $0x1,%ebx
8010273d:	83 fb 01             	cmp    $0x1,%ebx
80102740:	7e da                	jle    8010271c <lapicstartap+0x6a>
}
80102742:	5b                   	pop    %ebx
80102743:	5e                   	pop    %esi
80102744:	5f                   	pop    %edi
80102745:	5d                   	pop    %ebp
80102746:	c3                   	ret    

80102747 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
80102747:	55                   	push   %ebp
80102748:	89 e5                	mov    %esp,%ebp
8010274a:	57                   	push   %edi
8010274b:	56                   	push   %esi
8010274c:	53                   	push   %ebx
8010274d:	83 ec 3c             	sub    $0x3c,%esp
80102750:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
80102753:	b8 0b 00 00 00       	mov    $0xb,%eax
80102758:	e8 a2 fd ff ff       	call   801024ff <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
8010275d:	83 e0 04             	and    $0x4,%eax
80102760:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
80102762:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102765:	e8 a9 fd ff ff       	call   80102513 <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
8010276a:	b8 0a 00 00 00       	mov    $0xa,%eax
8010276f:	e8 8b fd ff ff       	call   801024ff <cmos_read>
80102774:	a8 80                	test   $0x80,%al
80102776:	75 ea                	jne    80102762 <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
80102778:	8d 5d b8             	lea    -0x48(%ebp),%ebx
8010277b:	89 d8                	mov    %ebx,%eax
8010277d:	e8 91 fd ff ff       	call   80102513 <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
80102782:	83 ec 04             	sub    $0x4,%esp
80102785:	6a 18                	push   $0x18
80102787:	53                   	push   %ebx
80102788:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010278b:	50                   	push   %eax
8010278c:	e8 f6 17 00 00       	call   80103f87 <memcmp>
80102791:	83 c4 10             	add    $0x10,%esp
80102794:	85 c0                	test   %eax,%eax
80102796:	75 ca                	jne    80102762 <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
80102798:	85 ff                	test   %edi,%edi
8010279a:	0f 85 84 00 00 00    	jne    80102824 <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801027a0:	8b 55 d0             	mov    -0x30(%ebp),%edx
801027a3:	89 d0                	mov    %edx,%eax
801027a5:	c1 e8 04             	shr    $0x4,%eax
801027a8:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801027ab:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801027ae:	83 e2 0f             	and    $0xf,%edx
801027b1:	01 d0                	add    %edx,%eax
801027b3:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
801027b6:	8b 55 d4             	mov    -0x2c(%ebp),%edx
801027b9:	89 d0                	mov    %edx,%eax
801027bb:	c1 e8 04             	shr    $0x4,%eax
801027be:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801027c1:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801027c4:	83 e2 0f             	and    $0xf,%edx
801027c7:	01 d0                	add    %edx,%eax
801027c9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
801027cc:	8b 55 d8             	mov    -0x28(%ebp),%edx
801027cf:	89 d0                	mov    %edx,%eax
801027d1:	c1 e8 04             	shr    $0x4,%eax
801027d4:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801027d7:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801027da:	83 e2 0f             	and    $0xf,%edx
801027dd:	01 d0                	add    %edx,%eax
801027df:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
801027e2:	8b 55 dc             	mov    -0x24(%ebp),%edx
801027e5:	89 d0                	mov    %edx,%eax
801027e7:	c1 e8 04             	shr    $0x4,%eax
801027ea:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801027ed:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801027f0:	83 e2 0f             	and    $0xf,%edx
801027f3:	01 d0                	add    %edx,%eax
801027f5:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
801027f8:	8b 55 e0             	mov    -0x20(%ebp),%edx
801027fb:	89 d0                	mov    %edx,%eax
801027fd:	c1 e8 04             	shr    $0x4,%eax
80102800:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102803:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102806:	83 e2 0f             	and    $0xf,%edx
80102809:	01 d0                	add    %edx,%eax
8010280b:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
8010280e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80102811:	89 d0                	mov    %edx,%eax
80102813:	c1 e8 04             	shr    $0x4,%eax
80102816:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102819:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010281c:	83 e2 0f             	and    $0xf,%edx
8010281f:	01 d0                	add    %edx,%eax
80102821:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
80102824:	8b 45 d0             	mov    -0x30(%ebp),%eax
80102827:	89 06                	mov    %eax,(%esi)
80102829:	8b 45 d4             	mov    -0x2c(%ebp),%eax
8010282c:	89 46 04             	mov    %eax,0x4(%esi)
8010282f:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102832:	89 46 08             	mov    %eax,0x8(%esi)
80102835:	8b 45 dc             	mov    -0x24(%ebp),%eax
80102838:	89 46 0c             	mov    %eax,0xc(%esi)
8010283b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010283e:	89 46 10             	mov    %eax,0x10(%esi)
80102841:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102844:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
80102847:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
8010284e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102851:	5b                   	pop    %ebx
80102852:	5e                   	pop    %esi
80102853:	5f                   	pop    %edi
80102854:	5d                   	pop    %ebp
80102855:	c3                   	ret    

80102856 <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80102856:	55                   	push   %ebp
80102857:	89 e5                	mov    %esp,%ebp
80102859:	53                   	push   %ebx
8010285a:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
8010285d:	ff 35 f4 26 13 80    	pushl  0x801326f4
80102863:	ff 35 04 27 13 80    	pushl  0x80132704
80102869:	e8 fe d8 ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
8010286e:	8b 58 5c             	mov    0x5c(%eax),%ebx
80102871:	89 1d 08 27 13 80    	mov    %ebx,0x80132708
  for (i = 0; i < log.lh.n; i++) {
80102877:	83 c4 10             	add    $0x10,%esp
8010287a:	ba 00 00 00 00       	mov    $0x0,%edx
8010287f:	eb 0e                	jmp    8010288f <read_head+0x39>
    log.lh.block[i] = lh->block[i];
80102881:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
80102885:	89 0c 95 0c 27 13 80 	mov    %ecx,-0x7fecd8f4(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
8010288c:	83 c2 01             	add    $0x1,%edx
8010288f:	39 d3                	cmp    %edx,%ebx
80102891:	7f ee                	jg     80102881 <read_head+0x2b>
  }
  brelse(buf);
80102893:	83 ec 0c             	sub    $0xc,%esp
80102896:	50                   	push   %eax
80102897:	e8 39 d9 ff ff       	call   801001d5 <brelse>
}
8010289c:	83 c4 10             	add    $0x10,%esp
8010289f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801028a2:	c9                   	leave  
801028a3:	c3                   	ret    

801028a4 <install_trans>:
{
801028a4:	55                   	push   %ebp
801028a5:	89 e5                	mov    %esp,%ebp
801028a7:	57                   	push   %edi
801028a8:	56                   	push   %esi
801028a9:	53                   	push   %ebx
801028aa:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
801028ad:	bb 00 00 00 00       	mov    $0x0,%ebx
801028b2:	eb 66                	jmp    8010291a <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801028b4:	89 d8                	mov    %ebx,%eax
801028b6:	03 05 f4 26 13 80    	add    0x801326f4,%eax
801028bc:	83 c0 01             	add    $0x1,%eax
801028bf:	83 ec 08             	sub    $0x8,%esp
801028c2:	50                   	push   %eax
801028c3:	ff 35 04 27 13 80    	pushl  0x80132704
801028c9:	e8 9e d8 ff ff       	call   8010016c <bread>
801028ce:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
801028d0:	83 c4 08             	add    $0x8,%esp
801028d3:	ff 34 9d 0c 27 13 80 	pushl  -0x7fecd8f4(,%ebx,4)
801028da:	ff 35 04 27 13 80    	pushl  0x80132704
801028e0:	e8 87 d8 ff ff       	call   8010016c <bread>
801028e5:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801028e7:	8d 57 5c             	lea    0x5c(%edi),%edx
801028ea:	8d 40 5c             	lea    0x5c(%eax),%eax
801028ed:	83 c4 0c             	add    $0xc,%esp
801028f0:	68 00 02 00 00       	push   $0x200
801028f5:	52                   	push   %edx
801028f6:	50                   	push   %eax
801028f7:	e8 c0 16 00 00       	call   80103fbc <memmove>
    bwrite(dbuf);  // write dst to disk
801028fc:	89 34 24             	mov    %esi,(%esp)
801028ff:	e8 96 d8 ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
80102904:	89 3c 24             	mov    %edi,(%esp)
80102907:	e8 c9 d8 ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
8010290c:	89 34 24             	mov    %esi,(%esp)
8010290f:	e8 c1 d8 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102914:	83 c3 01             	add    $0x1,%ebx
80102917:	83 c4 10             	add    $0x10,%esp
8010291a:	39 1d 08 27 13 80    	cmp    %ebx,0x80132708
80102920:	7f 92                	jg     801028b4 <install_trans+0x10>
}
80102922:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102925:	5b                   	pop    %ebx
80102926:	5e                   	pop    %esi
80102927:	5f                   	pop    %edi
80102928:	5d                   	pop    %ebp
80102929:	c3                   	ret    

8010292a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
8010292a:	55                   	push   %ebp
8010292b:	89 e5                	mov    %esp,%ebp
8010292d:	53                   	push   %ebx
8010292e:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102931:	ff 35 f4 26 13 80    	pushl  0x801326f4
80102937:	ff 35 04 27 13 80    	pushl  0x80132704
8010293d:	e8 2a d8 ff ff       	call   8010016c <bread>
80102942:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
80102944:	8b 0d 08 27 13 80    	mov    0x80132708,%ecx
8010294a:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
8010294d:	83 c4 10             	add    $0x10,%esp
80102950:	b8 00 00 00 00       	mov    $0x0,%eax
80102955:	eb 0e                	jmp    80102965 <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
80102957:	8b 14 85 0c 27 13 80 	mov    -0x7fecd8f4(,%eax,4),%edx
8010295e:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
80102962:	83 c0 01             	add    $0x1,%eax
80102965:	39 c1                	cmp    %eax,%ecx
80102967:	7f ee                	jg     80102957 <write_head+0x2d>
  }
  bwrite(buf);
80102969:	83 ec 0c             	sub    $0xc,%esp
8010296c:	53                   	push   %ebx
8010296d:	e8 28 d8 ff ff       	call   8010019a <bwrite>
  brelse(buf);
80102972:	89 1c 24             	mov    %ebx,(%esp)
80102975:	e8 5b d8 ff ff       	call   801001d5 <brelse>
}
8010297a:	83 c4 10             	add    $0x10,%esp
8010297d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102980:	c9                   	leave  
80102981:	c3                   	ret    

80102982 <recover_from_log>:

static void
recover_from_log(void)
{
80102982:	55                   	push   %ebp
80102983:	89 e5                	mov    %esp,%ebp
80102985:	83 ec 08             	sub    $0x8,%esp
  read_head();
80102988:	e8 c9 fe ff ff       	call   80102856 <read_head>
  install_trans(); // if committed, copy from log to disk
8010298d:	e8 12 ff ff ff       	call   801028a4 <install_trans>
  log.lh.n = 0;
80102992:	c7 05 08 27 13 80 00 	movl   $0x0,0x80132708
80102999:	00 00 00 
  write_head(); // clear the log
8010299c:	e8 89 ff ff ff       	call   8010292a <write_head>
}
801029a1:	c9                   	leave  
801029a2:	c3                   	ret    

801029a3 <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
801029a3:	55                   	push   %ebp
801029a4:	89 e5                	mov    %esp,%ebp
801029a6:	57                   	push   %edi
801029a7:	56                   	push   %esi
801029a8:	53                   	push   %ebx
801029a9:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801029ac:	bb 00 00 00 00       	mov    $0x0,%ebx
801029b1:	eb 66                	jmp    80102a19 <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
801029b3:	89 d8                	mov    %ebx,%eax
801029b5:	03 05 f4 26 13 80    	add    0x801326f4,%eax
801029bb:	83 c0 01             	add    $0x1,%eax
801029be:	83 ec 08             	sub    $0x8,%esp
801029c1:	50                   	push   %eax
801029c2:	ff 35 04 27 13 80    	pushl  0x80132704
801029c8:	e8 9f d7 ff ff       	call   8010016c <bread>
801029cd:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801029cf:	83 c4 08             	add    $0x8,%esp
801029d2:	ff 34 9d 0c 27 13 80 	pushl  -0x7fecd8f4(,%ebx,4)
801029d9:	ff 35 04 27 13 80    	pushl  0x80132704
801029df:	e8 88 d7 ff ff       	call   8010016c <bread>
801029e4:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
801029e6:	8d 50 5c             	lea    0x5c(%eax),%edx
801029e9:	8d 46 5c             	lea    0x5c(%esi),%eax
801029ec:	83 c4 0c             	add    $0xc,%esp
801029ef:	68 00 02 00 00       	push   $0x200
801029f4:	52                   	push   %edx
801029f5:	50                   	push   %eax
801029f6:	e8 c1 15 00 00       	call   80103fbc <memmove>
    bwrite(to);  // write the log
801029fb:	89 34 24             	mov    %esi,(%esp)
801029fe:	e8 97 d7 ff ff       	call   8010019a <bwrite>
    brelse(from);
80102a03:	89 3c 24             	mov    %edi,(%esp)
80102a06:	e8 ca d7 ff ff       	call   801001d5 <brelse>
    brelse(to);
80102a0b:	89 34 24             	mov    %esi,(%esp)
80102a0e:	e8 c2 d7 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102a13:	83 c3 01             	add    $0x1,%ebx
80102a16:	83 c4 10             	add    $0x10,%esp
80102a19:	39 1d 08 27 13 80    	cmp    %ebx,0x80132708
80102a1f:	7f 92                	jg     801029b3 <write_log+0x10>
  }
}
80102a21:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102a24:	5b                   	pop    %ebx
80102a25:	5e                   	pop    %esi
80102a26:	5f                   	pop    %edi
80102a27:	5d                   	pop    %ebp
80102a28:	c3                   	ret    

80102a29 <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
80102a29:	83 3d 08 27 13 80 00 	cmpl   $0x0,0x80132708
80102a30:	7e 26                	jle    80102a58 <commit+0x2f>
{
80102a32:	55                   	push   %ebp
80102a33:	89 e5                	mov    %esp,%ebp
80102a35:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
80102a38:	e8 66 ff ff ff       	call   801029a3 <write_log>
    write_head();    // Write header to disk -- the real commit
80102a3d:	e8 e8 fe ff ff       	call   8010292a <write_head>
    install_trans(); // Now install writes to home locations
80102a42:	e8 5d fe ff ff       	call   801028a4 <install_trans>
    log.lh.n = 0;
80102a47:	c7 05 08 27 13 80 00 	movl   $0x0,0x80132708
80102a4e:	00 00 00 
    write_head();    // Erase the transaction from the log
80102a51:	e8 d4 fe ff ff       	call   8010292a <write_head>
  }
}
80102a56:	c9                   	leave  
80102a57:	c3                   	ret    
80102a58:	f3 c3                	repz ret 

80102a5a <initlog>:
{
80102a5a:	55                   	push   %ebp
80102a5b:	89 e5                	mov    %esp,%ebp
80102a5d:	53                   	push   %ebx
80102a5e:	83 ec 2c             	sub    $0x2c,%esp
80102a61:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
80102a64:	68 60 6c 10 80       	push   $0x80106c60
80102a69:	68 c0 26 13 80       	push   $0x801326c0
80102a6e:	e8 e6 12 00 00       	call   80103d59 <initlock>
  readsb(dev, &sb);
80102a73:	83 c4 08             	add    $0x8,%esp
80102a76:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102a79:	50                   	push   %eax
80102a7a:	53                   	push   %ebx
80102a7b:	e8 b6 e7 ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
80102a80:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102a83:	a3 f4 26 13 80       	mov    %eax,0x801326f4
  log.size = sb.nlog;
80102a88:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102a8b:	a3 f8 26 13 80       	mov    %eax,0x801326f8
  log.dev = dev;
80102a90:	89 1d 04 27 13 80    	mov    %ebx,0x80132704
  recover_from_log();
80102a96:	e8 e7 fe ff ff       	call   80102982 <recover_from_log>
}
80102a9b:	83 c4 10             	add    $0x10,%esp
80102a9e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102aa1:	c9                   	leave  
80102aa2:	c3                   	ret    

80102aa3 <begin_op>:
{
80102aa3:	55                   	push   %ebp
80102aa4:	89 e5                	mov    %esp,%ebp
80102aa6:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
80102aa9:	68 c0 26 13 80       	push   $0x801326c0
80102aae:	e8 e2 13 00 00       	call   80103e95 <acquire>
80102ab3:	83 c4 10             	add    $0x10,%esp
80102ab6:	eb 15                	jmp    80102acd <begin_op+0x2a>
      sleep(&log, &log.lock);
80102ab8:	83 ec 08             	sub    $0x8,%esp
80102abb:	68 c0 26 13 80       	push   $0x801326c0
80102ac0:	68 c0 26 13 80       	push   $0x801326c0
80102ac5:	e8 d0 0e 00 00       	call   8010399a <sleep>
80102aca:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
80102acd:	83 3d 00 27 13 80 00 	cmpl   $0x0,0x80132700
80102ad4:	75 e2                	jne    80102ab8 <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80102ad6:	a1 fc 26 13 80       	mov    0x801326fc,%eax
80102adb:	83 c0 01             	add    $0x1,%eax
80102ade:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102ae1:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
80102ae4:	03 15 08 27 13 80    	add    0x80132708,%edx
80102aea:	83 fa 1e             	cmp    $0x1e,%edx
80102aed:	7e 17                	jle    80102b06 <begin_op+0x63>
      sleep(&log, &log.lock);
80102aef:	83 ec 08             	sub    $0x8,%esp
80102af2:	68 c0 26 13 80       	push   $0x801326c0
80102af7:	68 c0 26 13 80       	push   $0x801326c0
80102afc:	e8 99 0e 00 00       	call   8010399a <sleep>
80102b01:	83 c4 10             	add    $0x10,%esp
80102b04:	eb c7                	jmp    80102acd <begin_op+0x2a>
      log.outstanding += 1;
80102b06:	a3 fc 26 13 80       	mov    %eax,0x801326fc
      release(&log.lock);
80102b0b:	83 ec 0c             	sub    $0xc,%esp
80102b0e:	68 c0 26 13 80       	push   $0x801326c0
80102b13:	e8 e2 13 00 00       	call   80103efa <release>
}
80102b18:	83 c4 10             	add    $0x10,%esp
80102b1b:	c9                   	leave  
80102b1c:	c3                   	ret    

80102b1d <end_op>:
{
80102b1d:	55                   	push   %ebp
80102b1e:	89 e5                	mov    %esp,%ebp
80102b20:	53                   	push   %ebx
80102b21:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
80102b24:	68 c0 26 13 80       	push   $0x801326c0
80102b29:	e8 67 13 00 00       	call   80103e95 <acquire>
  log.outstanding -= 1;
80102b2e:	a1 fc 26 13 80       	mov    0x801326fc,%eax
80102b33:	83 e8 01             	sub    $0x1,%eax
80102b36:	a3 fc 26 13 80       	mov    %eax,0x801326fc
  if(log.committing)
80102b3b:	8b 1d 00 27 13 80    	mov    0x80132700,%ebx
80102b41:	83 c4 10             	add    $0x10,%esp
80102b44:	85 db                	test   %ebx,%ebx
80102b46:	75 2c                	jne    80102b74 <end_op+0x57>
  if(log.outstanding == 0){
80102b48:	85 c0                	test   %eax,%eax
80102b4a:	75 35                	jne    80102b81 <end_op+0x64>
    log.committing = 1;
80102b4c:	c7 05 00 27 13 80 01 	movl   $0x1,0x80132700
80102b53:	00 00 00 
    do_commit = 1;
80102b56:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
80102b5b:	83 ec 0c             	sub    $0xc,%esp
80102b5e:	68 c0 26 13 80       	push   $0x801326c0
80102b63:	e8 92 13 00 00       	call   80103efa <release>
  if(do_commit){
80102b68:	83 c4 10             	add    $0x10,%esp
80102b6b:	85 db                	test   %ebx,%ebx
80102b6d:	75 24                	jne    80102b93 <end_op+0x76>
}
80102b6f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102b72:	c9                   	leave  
80102b73:	c3                   	ret    
    panic("log.committing");
80102b74:	83 ec 0c             	sub    $0xc,%esp
80102b77:	68 64 6c 10 80       	push   $0x80106c64
80102b7c:	e8 c7 d7 ff ff       	call   80100348 <panic>
    wakeup(&log);
80102b81:	83 ec 0c             	sub    $0xc,%esp
80102b84:	68 c0 26 13 80       	push   $0x801326c0
80102b89:	e8 71 0f 00 00       	call   80103aff <wakeup>
80102b8e:	83 c4 10             	add    $0x10,%esp
80102b91:	eb c8                	jmp    80102b5b <end_op+0x3e>
    commit();
80102b93:	e8 91 fe ff ff       	call   80102a29 <commit>
    acquire(&log.lock);
80102b98:	83 ec 0c             	sub    $0xc,%esp
80102b9b:	68 c0 26 13 80       	push   $0x801326c0
80102ba0:	e8 f0 12 00 00       	call   80103e95 <acquire>
    log.committing = 0;
80102ba5:	c7 05 00 27 13 80 00 	movl   $0x0,0x80132700
80102bac:	00 00 00 
    wakeup(&log);
80102baf:	c7 04 24 c0 26 13 80 	movl   $0x801326c0,(%esp)
80102bb6:	e8 44 0f 00 00       	call   80103aff <wakeup>
    release(&log.lock);
80102bbb:	c7 04 24 c0 26 13 80 	movl   $0x801326c0,(%esp)
80102bc2:	e8 33 13 00 00       	call   80103efa <release>
80102bc7:	83 c4 10             	add    $0x10,%esp
}
80102bca:	eb a3                	jmp    80102b6f <end_op+0x52>

80102bcc <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80102bcc:	55                   	push   %ebp
80102bcd:	89 e5                	mov    %esp,%ebp
80102bcf:	53                   	push   %ebx
80102bd0:	83 ec 04             	sub    $0x4,%esp
80102bd3:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80102bd6:	8b 15 08 27 13 80    	mov    0x80132708,%edx
80102bdc:	83 fa 1d             	cmp    $0x1d,%edx
80102bdf:	7f 45                	jg     80102c26 <log_write+0x5a>
80102be1:	a1 f8 26 13 80       	mov    0x801326f8,%eax
80102be6:	83 e8 01             	sub    $0x1,%eax
80102be9:	39 c2                	cmp    %eax,%edx
80102beb:	7d 39                	jge    80102c26 <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102bed:	83 3d fc 26 13 80 00 	cmpl   $0x0,0x801326fc
80102bf4:	7e 3d                	jle    80102c33 <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102bf6:	83 ec 0c             	sub    $0xc,%esp
80102bf9:	68 c0 26 13 80       	push   $0x801326c0
80102bfe:	e8 92 12 00 00       	call   80103e95 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80102c03:	83 c4 10             	add    $0x10,%esp
80102c06:	b8 00 00 00 00       	mov    $0x0,%eax
80102c0b:	8b 15 08 27 13 80    	mov    0x80132708,%edx
80102c11:	39 c2                	cmp    %eax,%edx
80102c13:	7e 2b                	jle    80102c40 <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102c15:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102c18:	39 0c 85 0c 27 13 80 	cmp    %ecx,-0x7fecd8f4(,%eax,4)
80102c1f:	74 1f                	je     80102c40 <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
80102c21:	83 c0 01             	add    $0x1,%eax
80102c24:	eb e5                	jmp    80102c0b <log_write+0x3f>
    panic("too big a transaction");
80102c26:	83 ec 0c             	sub    $0xc,%esp
80102c29:	68 73 6c 10 80       	push   $0x80106c73
80102c2e:	e8 15 d7 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102c33:	83 ec 0c             	sub    $0xc,%esp
80102c36:	68 89 6c 10 80       	push   $0x80106c89
80102c3b:	e8 08 d7 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102c40:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102c43:	89 0c 85 0c 27 13 80 	mov    %ecx,-0x7fecd8f4(,%eax,4)
  if (i == log.lh.n)
80102c4a:	39 c2                	cmp    %eax,%edx
80102c4c:	74 18                	je     80102c66 <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102c4e:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102c51:	83 ec 0c             	sub    $0xc,%esp
80102c54:	68 c0 26 13 80       	push   $0x801326c0
80102c59:	e8 9c 12 00 00       	call   80103efa <release>
}
80102c5e:	83 c4 10             	add    $0x10,%esp
80102c61:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102c64:	c9                   	leave  
80102c65:	c3                   	ret    
    log.lh.n++;
80102c66:	83 c2 01             	add    $0x1,%edx
80102c69:	89 15 08 27 13 80    	mov    %edx,0x80132708
80102c6f:	eb dd                	jmp    80102c4e <log_write+0x82>

80102c71 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102c71:	55                   	push   %ebp
80102c72:	89 e5                	mov    %esp,%ebp
80102c74:	53                   	push   %ebx
80102c75:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102c78:	68 8a 00 00 00       	push   $0x8a
80102c7d:	68 8c a4 12 80       	push   $0x8012a48c
80102c82:	68 00 70 00 80       	push   $0x80007000
80102c87:	e8 30 13 00 00       	call   80103fbc <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102c8c:	83 c4 10             	add    $0x10,%esp
80102c8f:	bb c0 27 13 80       	mov    $0x801327c0,%ebx
80102c94:	eb 06                	jmp    80102c9c <startothers+0x2b>
80102c96:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102c9c:	69 05 40 2d 13 80 b0 	imul   $0xb0,0x80132d40,%eax
80102ca3:	00 00 00 
80102ca6:	05 c0 27 13 80       	add    $0x801327c0,%eax
80102cab:	39 d8                	cmp    %ebx,%eax
80102cad:	76 4c                	jbe    80102cfb <startothers+0x8a>
    if(c == mycpu())  // We've started already.
80102caf:	e8 c8 07 00 00       	call   8010347c <mycpu>
80102cb4:	39 d8                	cmp    %ebx,%eax
80102cb6:	74 de                	je     80102c96 <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80102cb8:	e8 d4 f4 ff ff       	call   80102191 <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102cbd:	05 00 10 00 00       	add    $0x1000,%eax
80102cc2:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102cc7:	c7 05 f8 6f 00 80 3f 	movl   $0x80102d3f,0x80006ff8
80102cce:	2d 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102cd1:	c7 05 f4 6f 00 80 00 	movl   $0x129000,0x80006ff4
80102cd8:	90 12 00 

    lapicstartap(c->apicid, V2P(code));
80102cdb:	83 ec 08             	sub    $0x8,%esp
80102cde:	68 00 70 00 00       	push   $0x7000
80102ce3:	0f b6 03             	movzbl (%ebx),%eax
80102ce6:	50                   	push   %eax
80102ce7:	e8 c6 f9 ff ff       	call   801026b2 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102cec:	83 c4 10             	add    $0x10,%esp
80102cef:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102cf5:	85 c0                	test   %eax,%eax
80102cf7:	74 f6                	je     80102cef <startothers+0x7e>
80102cf9:	eb 9b                	jmp    80102c96 <startothers+0x25>
      ;
  }
}
80102cfb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102cfe:	c9                   	leave  
80102cff:	c3                   	ret    

80102d00 <mpmain>:
{
80102d00:	55                   	push   %ebp
80102d01:	89 e5                	mov    %esp,%ebp
80102d03:	53                   	push   %ebx
80102d04:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102d07:	e8 cc 07 00 00       	call   801034d8 <cpuid>
80102d0c:	89 c3                	mov    %eax,%ebx
80102d0e:	e8 c5 07 00 00       	call   801034d8 <cpuid>
80102d13:	83 ec 04             	sub    $0x4,%esp
80102d16:	53                   	push   %ebx
80102d17:	50                   	push   %eax
80102d18:	68 a4 6c 10 80       	push   $0x80106ca4
80102d1d:	e8 e9 d8 ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102d22:	e8 ec 23 00 00       	call   80105113 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102d27:	e8 50 07 00 00       	call   8010347c <mycpu>
80102d2c:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102d2e:	b8 01 00 00 00       	mov    $0x1,%eax
80102d33:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102d3a:	e8 36 0a 00 00       	call   80103775 <scheduler>

80102d3f <mpenter>:
{
80102d3f:	55                   	push   %ebp
80102d40:	89 e5                	mov    %esp,%ebp
80102d42:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102d45:	e8 da 33 00 00       	call   80106124 <switchkvm>
  seginit();
80102d4a:	e8 89 32 00 00       	call   80105fd8 <seginit>
  lapicinit();
80102d4f:	e8 15 f8 ff ff       	call   80102569 <lapicinit>
  mpmain();
80102d54:	e8 a7 ff ff ff       	call   80102d00 <mpmain>

80102d59 <main>:
{
80102d59:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102d5d:	83 e4 f0             	and    $0xfffffff0,%esp
80102d60:	ff 71 fc             	pushl  -0x4(%ecx)
80102d63:	55                   	push   %ebp
80102d64:	89 e5                	mov    %esp,%ebp
80102d66:	51                   	push   %ecx
80102d67:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102d6a:	68 00 00 40 80       	push   $0x80400000
80102d6f:	68 e8 54 13 80       	push   $0x801354e8
80102d74:	e8 f0 f2 ff ff       	call   80102069 <kinit1>
  kvmalloc();      // kernel page table
80102d79:	e8 4e 38 00 00       	call   801065cc <kvmalloc>
  mpinit();        // detect other processors
80102d7e:	e8 c9 01 00 00       	call   80102f4c <mpinit>
  lapicinit();     // interrupt controller
80102d83:	e8 e1 f7 ff ff       	call   80102569 <lapicinit>
  seginit();       // segment descriptors
80102d88:	e8 4b 32 00 00       	call   80105fd8 <seginit>
  picinit();       // disable pic
80102d8d:	e8 82 02 00 00       	call   80103014 <picinit>
  ioapicinit();    // another interrupt controller
80102d92:	e8 63 f1 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102d97:	e8 f2 da ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102d9c:	e8 20 26 00 00       	call   801053c1 <uartinit>
  pinit();         // process table
80102da1:	e8 bc 06 00 00       	call   80103462 <pinit>
  tvinit();        // trap vectors
80102da6:	e8 b7 22 00 00       	call   80105062 <tvinit>
  binit();         // buffer cache
80102dab:	e8 44 d3 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102db0:	e8 5e de ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102db5:	e8 46 ef ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102dba:	e8 b2 fe ff ff       	call   80102c71 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102dbf:	83 c4 08             	add    $0x8,%esp
80102dc2:	68 00 00 00 8e       	push   $0x8e000000
80102dc7:	68 00 00 40 80       	push   $0x80400000
80102dcc:	e8 ca f2 ff ff       	call   8010209b <kinit2>
  userinit();      // first user process
80102dd1:	e8 41 07 00 00       	call   80103517 <userinit>
  mpmain();        // finish this processor's setup
80102dd6:	e8 25 ff ff ff       	call   80102d00 <mpmain>

80102ddb <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102ddb:	55                   	push   %ebp
80102ddc:	89 e5                	mov    %esp,%ebp
80102dde:	56                   	push   %esi
80102ddf:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102de0:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102de5:	b9 00 00 00 00       	mov    $0x0,%ecx
80102dea:	eb 09                	jmp    80102df5 <sum+0x1a>
    sum += addr[i];
80102dec:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102df0:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102df2:	83 c1 01             	add    $0x1,%ecx
80102df5:	39 d1                	cmp    %edx,%ecx
80102df7:	7c f3                	jl     80102dec <sum+0x11>
  return sum;
}
80102df9:	89 d8                	mov    %ebx,%eax
80102dfb:	5b                   	pop    %ebx
80102dfc:	5e                   	pop    %esi
80102dfd:	5d                   	pop    %ebp
80102dfe:	c3                   	ret    

80102dff <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102dff:	55                   	push   %ebp
80102e00:	89 e5                	mov    %esp,%ebp
80102e02:	56                   	push   %esi
80102e03:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102e04:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102e0a:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102e0c:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102e0e:	eb 03                	jmp    80102e13 <mpsearch1+0x14>
80102e10:	83 c3 10             	add    $0x10,%ebx
80102e13:	39 f3                	cmp    %esi,%ebx
80102e15:	73 29                	jae    80102e40 <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102e17:	83 ec 04             	sub    $0x4,%esp
80102e1a:	6a 04                	push   $0x4
80102e1c:	68 b8 6c 10 80       	push   $0x80106cb8
80102e21:	53                   	push   %ebx
80102e22:	e8 60 11 00 00       	call   80103f87 <memcmp>
80102e27:	83 c4 10             	add    $0x10,%esp
80102e2a:	85 c0                	test   %eax,%eax
80102e2c:	75 e2                	jne    80102e10 <mpsearch1+0x11>
80102e2e:	ba 10 00 00 00       	mov    $0x10,%edx
80102e33:	89 d8                	mov    %ebx,%eax
80102e35:	e8 a1 ff ff ff       	call   80102ddb <sum>
80102e3a:	84 c0                	test   %al,%al
80102e3c:	75 d2                	jne    80102e10 <mpsearch1+0x11>
80102e3e:	eb 05                	jmp    80102e45 <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102e40:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102e45:	89 d8                	mov    %ebx,%eax
80102e47:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102e4a:	5b                   	pop    %ebx
80102e4b:	5e                   	pop    %esi
80102e4c:	5d                   	pop    %ebp
80102e4d:	c3                   	ret    

80102e4e <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102e4e:	55                   	push   %ebp
80102e4f:	89 e5                	mov    %esp,%ebp
80102e51:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102e54:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102e5b:	c1 e0 08             	shl    $0x8,%eax
80102e5e:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102e65:	09 d0                	or     %edx,%eax
80102e67:	c1 e0 04             	shl    $0x4,%eax
80102e6a:	85 c0                	test   %eax,%eax
80102e6c:	74 1f                	je     80102e8d <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102e6e:	ba 00 04 00 00       	mov    $0x400,%edx
80102e73:	e8 87 ff ff ff       	call   80102dff <mpsearch1>
80102e78:	85 c0                	test   %eax,%eax
80102e7a:	75 0f                	jne    80102e8b <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102e7c:	ba 00 00 01 00       	mov    $0x10000,%edx
80102e81:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102e86:	e8 74 ff ff ff       	call   80102dff <mpsearch1>
}
80102e8b:	c9                   	leave  
80102e8c:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102e8d:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102e94:	c1 e0 08             	shl    $0x8,%eax
80102e97:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102e9e:	09 d0                	or     %edx,%eax
80102ea0:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102ea3:	2d 00 04 00 00       	sub    $0x400,%eax
80102ea8:	ba 00 04 00 00       	mov    $0x400,%edx
80102ead:	e8 4d ff ff ff       	call   80102dff <mpsearch1>
80102eb2:	85 c0                	test   %eax,%eax
80102eb4:	75 d5                	jne    80102e8b <mpsearch+0x3d>
80102eb6:	eb c4                	jmp    80102e7c <mpsearch+0x2e>

80102eb8 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102eb8:	55                   	push   %ebp
80102eb9:	89 e5                	mov    %esp,%ebp
80102ebb:	57                   	push   %edi
80102ebc:	56                   	push   %esi
80102ebd:	53                   	push   %ebx
80102ebe:	83 ec 1c             	sub    $0x1c,%esp
80102ec1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102ec4:	e8 85 ff ff ff       	call   80102e4e <mpsearch>
80102ec9:	85 c0                	test   %eax,%eax
80102ecb:	74 5c                	je     80102f29 <mpconfig+0x71>
80102ecd:	89 c7                	mov    %eax,%edi
80102ecf:	8b 58 04             	mov    0x4(%eax),%ebx
80102ed2:	85 db                	test   %ebx,%ebx
80102ed4:	74 5a                	je     80102f30 <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102ed6:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102edc:	83 ec 04             	sub    $0x4,%esp
80102edf:	6a 04                	push   $0x4
80102ee1:	68 bd 6c 10 80       	push   $0x80106cbd
80102ee6:	56                   	push   %esi
80102ee7:	e8 9b 10 00 00       	call   80103f87 <memcmp>
80102eec:	83 c4 10             	add    $0x10,%esp
80102eef:	85 c0                	test   %eax,%eax
80102ef1:	75 44                	jne    80102f37 <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102ef3:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102efa:	3c 01                	cmp    $0x1,%al
80102efc:	0f 95 c2             	setne  %dl
80102eff:	3c 04                	cmp    $0x4,%al
80102f01:	0f 95 c0             	setne  %al
80102f04:	84 c2                	test   %al,%dl
80102f06:	75 36                	jne    80102f3e <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102f08:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102f0f:	89 f0                	mov    %esi,%eax
80102f11:	e8 c5 fe ff ff       	call   80102ddb <sum>
80102f16:	84 c0                	test   %al,%al
80102f18:	75 2b                	jne    80102f45 <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102f1a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102f1d:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102f1f:	89 f0                	mov    %esi,%eax
80102f21:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102f24:	5b                   	pop    %ebx
80102f25:	5e                   	pop    %esi
80102f26:	5f                   	pop    %edi
80102f27:	5d                   	pop    %ebp
80102f28:	c3                   	ret    
    return 0;
80102f29:	be 00 00 00 00       	mov    $0x0,%esi
80102f2e:	eb ef                	jmp    80102f1f <mpconfig+0x67>
80102f30:	be 00 00 00 00       	mov    $0x0,%esi
80102f35:	eb e8                	jmp    80102f1f <mpconfig+0x67>
    return 0;
80102f37:	be 00 00 00 00       	mov    $0x0,%esi
80102f3c:	eb e1                	jmp    80102f1f <mpconfig+0x67>
    return 0;
80102f3e:	be 00 00 00 00       	mov    $0x0,%esi
80102f43:	eb da                	jmp    80102f1f <mpconfig+0x67>
    return 0;
80102f45:	be 00 00 00 00       	mov    $0x0,%esi
80102f4a:	eb d3                	jmp    80102f1f <mpconfig+0x67>

80102f4c <mpinit>:

void
mpinit(void)
{
80102f4c:	55                   	push   %ebp
80102f4d:	89 e5                	mov    %esp,%ebp
80102f4f:	57                   	push   %edi
80102f50:	56                   	push   %esi
80102f51:	53                   	push   %ebx
80102f52:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102f55:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102f58:	e8 5b ff ff ff       	call   80102eb8 <mpconfig>
80102f5d:	85 c0                	test   %eax,%eax
80102f5f:	74 19                	je     80102f7a <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102f61:	8b 50 24             	mov    0x24(%eax),%edx
80102f64:	89 15 a4 26 13 80    	mov    %edx,0x801326a4
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102f6a:	8d 50 2c             	lea    0x2c(%eax),%edx
80102f6d:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102f71:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102f73:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102f78:	eb 34                	jmp    80102fae <mpinit+0x62>
    panic("Expect to run on an SMP");
80102f7a:	83 ec 0c             	sub    $0xc,%esp
80102f7d:	68 c2 6c 10 80       	push   $0x80106cc2
80102f82:	e8 c1 d3 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102f87:	8b 35 40 2d 13 80    	mov    0x80132d40,%esi
80102f8d:	83 fe 07             	cmp    $0x7,%esi
80102f90:	7f 19                	jg     80102fab <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102f92:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102f96:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102f9c:	88 87 c0 27 13 80    	mov    %al,-0x7fecd840(%edi)
        ncpu++;
80102fa2:	83 c6 01             	add    $0x1,%esi
80102fa5:	89 35 40 2d 13 80    	mov    %esi,0x80132d40
      }
      p += sizeof(struct mpproc);
80102fab:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102fae:	39 ca                	cmp    %ecx,%edx
80102fb0:	73 2b                	jae    80102fdd <mpinit+0x91>
    switch(*p){
80102fb2:	0f b6 02             	movzbl (%edx),%eax
80102fb5:	3c 04                	cmp    $0x4,%al
80102fb7:	77 1d                	ja     80102fd6 <mpinit+0x8a>
80102fb9:	0f b6 c0             	movzbl %al,%eax
80102fbc:	ff 24 85 fc 6c 10 80 	jmp    *-0x7fef9304(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102fc3:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102fc7:	a2 a0 27 13 80       	mov    %al,0x801327a0
      p += sizeof(struct mpioapic);
80102fcc:	83 c2 08             	add    $0x8,%edx
      continue;
80102fcf:	eb dd                	jmp    80102fae <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102fd1:	83 c2 08             	add    $0x8,%edx
      continue;
80102fd4:	eb d8                	jmp    80102fae <mpinit+0x62>
    default:
      ismp = 0;
80102fd6:	bb 00 00 00 00       	mov    $0x0,%ebx
80102fdb:	eb d1                	jmp    80102fae <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102fdd:	85 db                	test   %ebx,%ebx
80102fdf:	74 26                	je     80103007 <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102fe1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102fe4:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102fe8:	74 15                	je     80102fff <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102fea:	b8 70 00 00 00       	mov    $0x70,%eax
80102fef:	ba 22 00 00 00       	mov    $0x22,%edx
80102ff4:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102ff5:	ba 23 00 00 00       	mov    $0x23,%edx
80102ffa:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102ffb:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102ffe:	ee                   	out    %al,(%dx)
  }
}
80102fff:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103002:	5b                   	pop    %ebx
80103003:	5e                   	pop    %esi
80103004:	5f                   	pop    %edi
80103005:	5d                   	pop    %ebp
80103006:	c3                   	ret    
    panic("Didn't find a suitable machine");
80103007:	83 ec 0c             	sub    $0xc,%esp
8010300a:	68 dc 6c 10 80       	push   $0x80106cdc
8010300f:	e8 34 d3 ff ff       	call   80100348 <panic>

80103014 <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80103014:	55                   	push   %ebp
80103015:	89 e5                	mov    %esp,%ebp
80103017:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010301c:	ba 21 00 00 00       	mov    $0x21,%edx
80103021:	ee                   	out    %al,(%dx)
80103022:	ba a1 00 00 00       	mov    $0xa1,%edx
80103027:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80103028:	5d                   	pop    %ebp
80103029:	c3                   	ret    

8010302a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
8010302a:	55                   	push   %ebp
8010302b:	89 e5                	mov    %esp,%ebp
8010302d:	57                   	push   %edi
8010302e:	56                   	push   %esi
8010302f:	53                   	push   %ebx
80103030:	83 ec 0c             	sub    $0xc,%esp
80103033:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103036:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80103039:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
8010303f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103045:	e8 e3 db ff ff       	call   80100c2d <filealloc>
8010304a:	89 03                	mov    %eax,(%ebx)
8010304c:	85 c0                	test   %eax,%eax
8010304e:	74 1e                	je     8010306e <pipealloc+0x44>
80103050:	e8 d8 db ff ff       	call   80100c2d <filealloc>
80103055:	89 06                	mov    %eax,(%esi)
80103057:	85 c0                	test   %eax,%eax
80103059:	74 13                	je     8010306e <pipealloc+0x44>
    goto bad;
  if((p = (struct pipe*)kalloc2(-2)) == 0)
8010305b:	83 ec 0c             	sub    $0xc,%esp
8010305e:	6a fe                	push   $0xfffffffe
80103060:	e8 c0 f1 ff ff       	call   80102225 <kalloc2>
80103065:	89 c7                	mov    %eax,%edi
80103067:	83 c4 10             	add    $0x10,%esp
8010306a:	85 c0                	test   %eax,%eax
8010306c:	75 35                	jne    801030a3 <pipealloc+0x79>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
8010306e:	8b 03                	mov    (%ebx),%eax
80103070:	85 c0                	test   %eax,%eax
80103072:	74 0c                	je     80103080 <pipealloc+0x56>
    fileclose(*f0);
80103074:	83 ec 0c             	sub    $0xc,%esp
80103077:	50                   	push   %eax
80103078:	e8 56 dc ff ff       	call   80100cd3 <fileclose>
8010307d:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80103080:	8b 06                	mov    (%esi),%eax
80103082:	85 c0                	test   %eax,%eax
80103084:	0f 84 8b 00 00 00    	je     80103115 <pipealloc+0xeb>
    fileclose(*f1);
8010308a:	83 ec 0c             	sub    $0xc,%esp
8010308d:	50                   	push   %eax
8010308e:	e8 40 dc ff ff       	call   80100cd3 <fileclose>
80103093:	83 c4 10             	add    $0x10,%esp
  return -1;
80103096:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010309b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010309e:	5b                   	pop    %ebx
8010309f:	5e                   	pop    %esi
801030a0:	5f                   	pop    %edi
801030a1:	5d                   	pop    %ebp
801030a2:	c3                   	ret    
  p->readopen = 1;
801030a3:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
801030aa:	00 00 00 
  p->writeopen = 1;
801030ad:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
801030b4:	00 00 00 
  p->nwrite = 0;
801030b7:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
801030be:	00 00 00 
  p->nread = 0;
801030c1:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
801030c8:	00 00 00 
  initlock(&p->lock, "pipe");
801030cb:	83 ec 08             	sub    $0x8,%esp
801030ce:	68 10 6d 10 80       	push   $0x80106d10
801030d3:	50                   	push   %eax
801030d4:	e8 80 0c 00 00       	call   80103d59 <initlock>
  (*f0)->type = FD_PIPE;
801030d9:	8b 03                	mov    (%ebx),%eax
801030db:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
801030e1:	8b 03                	mov    (%ebx),%eax
801030e3:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
801030e7:	8b 03                	mov    (%ebx),%eax
801030e9:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
801030ed:	8b 03                	mov    (%ebx),%eax
801030ef:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
801030f2:	8b 06                	mov    (%esi),%eax
801030f4:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
801030fa:	8b 06                	mov    (%esi),%eax
801030fc:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103100:	8b 06                	mov    (%esi),%eax
80103102:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80103106:	8b 06                	mov    (%esi),%eax
80103108:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
8010310b:	83 c4 10             	add    $0x10,%esp
8010310e:	b8 00 00 00 00       	mov    $0x0,%eax
80103113:	eb 86                	jmp    8010309b <pipealloc+0x71>
  return -1;
80103115:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010311a:	e9 7c ff ff ff       	jmp    8010309b <pipealloc+0x71>

8010311f <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
8010311f:	55                   	push   %ebp
80103120:	89 e5                	mov    %esp,%ebp
80103122:	53                   	push   %ebx
80103123:	83 ec 10             	sub    $0x10,%esp
80103126:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80103129:	53                   	push   %ebx
8010312a:	e8 66 0d 00 00       	call   80103e95 <acquire>
  if(writable){
8010312f:	83 c4 10             	add    $0x10,%esp
80103132:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103136:	74 3f                	je     80103177 <pipeclose+0x58>
    p->writeopen = 0;
80103138:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
8010313f:	00 00 00 
    wakeup(&p->nread);
80103142:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103148:	83 ec 0c             	sub    $0xc,%esp
8010314b:	50                   	push   %eax
8010314c:	e8 ae 09 00 00       	call   80103aff <wakeup>
80103151:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80103154:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
8010315b:	75 09                	jne    80103166 <pipeclose+0x47>
8010315d:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80103164:	74 2f                	je     80103195 <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80103166:	83 ec 0c             	sub    $0xc,%esp
80103169:	53                   	push   %ebx
8010316a:	e8 8b 0d 00 00       	call   80103efa <release>
8010316f:	83 c4 10             	add    $0x10,%esp
}
80103172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103175:	c9                   	leave  
80103176:	c3                   	ret    
    p->readopen = 0;
80103177:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
8010317e:	00 00 00 
    wakeup(&p->nwrite);
80103181:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103187:	83 ec 0c             	sub    $0xc,%esp
8010318a:	50                   	push   %eax
8010318b:	e8 6f 09 00 00       	call   80103aff <wakeup>
80103190:	83 c4 10             	add    $0x10,%esp
80103193:	eb bf                	jmp    80103154 <pipeclose+0x35>
    release(&p->lock);
80103195:	83 ec 0c             	sub    $0xc,%esp
80103198:	53                   	push   %ebx
80103199:	e8 5c 0d 00 00       	call   80103efa <release>
    kfree((char*)p);
8010319e:	89 1c 24             	mov    %ebx,(%esp)
801031a1:	e8 1f ef ff ff       	call   801020c5 <kfree>
801031a6:	83 c4 10             	add    $0x10,%esp
801031a9:	eb c7                	jmp    80103172 <pipeclose+0x53>

801031ab <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
801031ab:	55                   	push   %ebp
801031ac:	89 e5                	mov    %esp,%ebp
801031ae:	57                   	push   %edi
801031af:	56                   	push   %esi
801031b0:	53                   	push   %ebx
801031b1:	83 ec 18             	sub    $0x18,%esp
801031b4:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
801031b7:	89 de                	mov    %ebx,%esi
801031b9:	53                   	push   %ebx
801031ba:	e8 d6 0c 00 00       	call   80103e95 <acquire>
  for(i = 0; i < n; i++){
801031bf:	83 c4 10             	add    $0x10,%esp
801031c2:	bf 00 00 00 00       	mov    $0x0,%edi
801031c7:	3b 7d 10             	cmp    0x10(%ebp),%edi
801031ca:	0f 8d 88 00 00 00    	jge    80103258 <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801031d0:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
801031d6:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
801031dc:	05 00 02 00 00       	add    $0x200,%eax
801031e1:	39 c2                	cmp    %eax,%edx
801031e3:	75 51                	jne    80103236 <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
801031e5:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
801031ec:	74 2f                	je     8010321d <pipewrite+0x72>
801031ee:	e8 00 03 00 00       	call   801034f3 <myproc>
801031f3:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801031f7:	75 24                	jne    8010321d <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
801031f9:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801031ff:	83 ec 0c             	sub    $0xc,%esp
80103202:	50                   	push   %eax
80103203:	e8 f7 08 00 00       	call   80103aff <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103208:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
8010320e:	83 c4 08             	add    $0x8,%esp
80103211:	56                   	push   %esi
80103212:	50                   	push   %eax
80103213:	e8 82 07 00 00       	call   8010399a <sleep>
80103218:	83 c4 10             	add    $0x10,%esp
8010321b:	eb b3                	jmp    801031d0 <pipewrite+0x25>
        release(&p->lock);
8010321d:	83 ec 0c             	sub    $0xc,%esp
80103220:	53                   	push   %ebx
80103221:	e8 d4 0c 00 00       	call   80103efa <release>
        return -1;
80103226:	83 c4 10             	add    $0x10,%esp
80103229:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
8010322e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103231:	5b                   	pop    %ebx
80103232:	5e                   	pop    %esi
80103233:	5f                   	pop    %edi
80103234:	5d                   	pop    %ebp
80103235:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103236:	8d 42 01             	lea    0x1(%edx),%eax
80103239:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
8010323f:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80103245:	8b 45 0c             	mov    0xc(%ebp),%eax
80103248:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
8010324c:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
80103250:	83 c7 01             	add    $0x1,%edi
80103253:	e9 6f ff ff ff       	jmp    801031c7 <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80103258:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
8010325e:	83 ec 0c             	sub    $0xc,%esp
80103261:	50                   	push   %eax
80103262:	e8 98 08 00 00       	call   80103aff <wakeup>
  release(&p->lock);
80103267:	89 1c 24             	mov    %ebx,(%esp)
8010326a:	e8 8b 0c 00 00       	call   80103efa <release>
  return n;
8010326f:	83 c4 10             	add    $0x10,%esp
80103272:	8b 45 10             	mov    0x10(%ebp),%eax
80103275:	eb b7                	jmp    8010322e <pipewrite+0x83>

80103277 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80103277:	55                   	push   %ebp
80103278:	89 e5                	mov    %esp,%ebp
8010327a:	57                   	push   %edi
8010327b:	56                   	push   %esi
8010327c:	53                   	push   %ebx
8010327d:	83 ec 18             	sub    $0x18,%esp
80103280:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80103283:	89 df                	mov    %ebx,%edi
80103285:	53                   	push   %ebx
80103286:	e8 0a 0c 00 00       	call   80103e95 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010328b:	83 c4 10             	add    $0x10,%esp
8010328e:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
80103294:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
8010329a:	75 3d                	jne    801032d9 <piperead+0x62>
8010329c:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
801032a2:	85 f6                	test   %esi,%esi
801032a4:	74 38                	je     801032de <piperead+0x67>
    if(myproc()->killed){
801032a6:	e8 48 02 00 00       	call   801034f3 <myproc>
801032ab:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801032af:	75 15                	jne    801032c6 <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801032b1:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801032b7:	83 ec 08             	sub    $0x8,%esp
801032ba:	57                   	push   %edi
801032bb:	50                   	push   %eax
801032bc:	e8 d9 06 00 00       	call   8010399a <sleep>
801032c1:	83 c4 10             	add    $0x10,%esp
801032c4:	eb c8                	jmp    8010328e <piperead+0x17>
      release(&p->lock);
801032c6:	83 ec 0c             	sub    $0xc,%esp
801032c9:	53                   	push   %ebx
801032ca:	e8 2b 0c 00 00       	call   80103efa <release>
      return -1;
801032cf:	83 c4 10             	add    $0x10,%esp
801032d2:	be ff ff ff ff       	mov    $0xffffffff,%esi
801032d7:	eb 50                	jmp    80103329 <piperead+0xb2>
801032d9:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801032de:	3b 75 10             	cmp    0x10(%ebp),%esi
801032e1:	7d 2c                	jge    8010330f <piperead+0x98>
    if(p->nread == p->nwrite)
801032e3:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
801032e9:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
801032ef:	74 1e                	je     8010330f <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
801032f1:	8d 50 01             	lea    0x1(%eax),%edx
801032f4:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
801032fa:	25 ff 01 00 00       	and    $0x1ff,%eax
801032ff:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
80103304:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103307:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010330a:	83 c6 01             	add    $0x1,%esi
8010330d:	eb cf                	jmp    801032de <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
8010330f:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103315:	83 ec 0c             	sub    $0xc,%esp
80103318:	50                   	push   %eax
80103319:	e8 e1 07 00 00       	call   80103aff <wakeup>
  release(&p->lock);
8010331e:	89 1c 24             	mov    %ebx,(%esp)
80103321:	e8 d4 0b 00 00       	call   80103efa <release>
  return i;
80103326:	83 c4 10             	add    $0x10,%esp
}
80103329:	89 f0                	mov    %esi,%eax
8010332b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010332e:	5b                   	pop    %ebx
8010332f:	5e                   	pop    %esi
80103330:	5f                   	pop    %edi
80103331:	5d                   	pop    %ebp
80103332:	c3                   	ret    

80103333 <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80103333:	55                   	push   %ebp
80103334:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103336:	ba 94 2d 13 80       	mov    $0x80132d94,%edx
8010333b:	eb 03                	jmp    80103340 <wakeup1+0xd>
8010333d:	83 c2 7c             	add    $0x7c,%edx
80103340:	81 fa 94 4c 13 80    	cmp    $0x80134c94,%edx
80103346:	73 14                	jae    8010335c <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
80103348:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
8010334c:	75 ef                	jne    8010333d <wakeup1+0xa>
8010334e:	39 42 20             	cmp    %eax,0x20(%edx)
80103351:	75 ea                	jne    8010333d <wakeup1+0xa>
      p->state = RUNNABLE;
80103353:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
8010335a:	eb e1                	jmp    8010333d <wakeup1+0xa>
}
8010335c:	5d                   	pop    %ebp
8010335d:	c3                   	ret    

8010335e <allocproc>:
{
8010335e:	55                   	push   %ebp
8010335f:	89 e5                	mov    %esp,%ebp
80103361:	53                   	push   %ebx
80103362:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
80103365:	68 60 2d 13 80       	push   $0x80132d60
8010336a:	e8 26 0b 00 00       	call   80103e95 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010336f:	83 c4 10             	add    $0x10,%esp
80103372:	bb 94 2d 13 80       	mov    $0x80132d94,%ebx
80103377:	81 fb 94 4c 13 80    	cmp    $0x80134c94,%ebx
8010337d:	73 0b                	jae    8010338a <allocproc+0x2c>
    if(p->state == UNUSED)
8010337f:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
80103383:	74 1c                	je     801033a1 <allocproc+0x43>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103385:	83 c3 7c             	add    $0x7c,%ebx
80103388:	eb ed                	jmp    80103377 <allocproc+0x19>
  release(&ptable.lock);
8010338a:	83 ec 0c             	sub    $0xc,%esp
8010338d:	68 60 2d 13 80       	push   $0x80132d60
80103392:	e8 63 0b 00 00       	call   80103efa <release>
  return 0;
80103397:	83 c4 10             	add    $0x10,%esp
8010339a:	bb 00 00 00 00       	mov    $0x0,%ebx
8010339f:	eb 69                	jmp    8010340a <allocproc+0xac>
  p->state = EMBRYO;
801033a1:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
801033a8:	a1 04 a0 12 80       	mov    0x8012a004,%eax
801033ad:	8d 50 01             	lea    0x1(%eax),%edx
801033b0:	89 15 04 a0 12 80    	mov    %edx,0x8012a004
801033b6:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
801033b9:	83 ec 0c             	sub    $0xc,%esp
801033bc:	68 60 2d 13 80       	push   $0x80132d60
801033c1:	e8 34 0b 00 00       	call   80103efa <release>
  if((p->kstack = kalloc()) == 0){
801033c6:	e8 c6 ed ff ff       	call   80102191 <kalloc>
801033cb:	89 43 08             	mov    %eax,0x8(%ebx)
801033ce:	83 c4 10             	add    $0x10,%esp
801033d1:	85 c0                	test   %eax,%eax
801033d3:	74 3c                	je     80103411 <allocproc+0xb3>
  sp -= sizeof *p->tf;
801033d5:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
801033db:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
801033de:	c7 80 b0 0f 00 00 57 	movl   $0x80105057,0xfb0(%eax)
801033e5:	50 10 80 
  sp -= sizeof *p->context;
801033e8:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
801033ed:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
801033f0:	83 ec 04             	sub    $0x4,%esp
801033f3:	6a 14                	push   $0x14
801033f5:	6a 00                	push   $0x0
801033f7:	50                   	push   %eax
801033f8:	e8 44 0b 00 00       	call   80103f41 <memset>
  p->context->eip = (uint)forkret;
801033fd:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103400:	c7 40 10 1f 34 10 80 	movl   $0x8010341f,0x10(%eax)
  return p;
80103407:	83 c4 10             	add    $0x10,%esp
}
8010340a:	89 d8                	mov    %ebx,%eax
8010340c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010340f:	c9                   	leave  
80103410:	c3                   	ret    
    p->state = UNUSED;
80103411:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
80103418:	bb 00 00 00 00       	mov    $0x0,%ebx
8010341d:	eb eb                	jmp    8010340a <allocproc+0xac>

8010341f <forkret>:
{
8010341f:	55                   	push   %ebp
80103420:	89 e5                	mov    %esp,%ebp
80103422:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
80103425:	68 60 2d 13 80       	push   $0x80132d60
8010342a:	e8 cb 0a 00 00       	call   80103efa <release>
  if (first) {
8010342f:	83 c4 10             	add    $0x10,%esp
80103432:	83 3d 00 a0 12 80 00 	cmpl   $0x0,0x8012a000
80103439:	75 02                	jne    8010343d <forkret+0x1e>
}
8010343b:	c9                   	leave  
8010343c:	c3                   	ret    
    first = 0;
8010343d:	c7 05 00 a0 12 80 00 	movl   $0x0,0x8012a000
80103444:	00 00 00 
    iinit(ROOTDEV);
80103447:	83 ec 0c             	sub    $0xc,%esp
8010344a:	6a 01                	push   $0x1
8010344c:	e8 9b de ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
80103451:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103458:	e8 fd f5 ff ff       	call   80102a5a <initlog>
8010345d:	83 c4 10             	add    $0x10,%esp
}
80103460:	eb d9                	jmp    8010343b <forkret+0x1c>

80103462 <pinit>:
{
80103462:	55                   	push   %ebp
80103463:	89 e5                	mov    %esp,%ebp
80103465:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
80103468:	68 15 6d 10 80       	push   $0x80106d15
8010346d:	68 60 2d 13 80       	push   $0x80132d60
80103472:	e8 e2 08 00 00       	call   80103d59 <initlock>
}
80103477:	83 c4 10             	add    $0x10,%esp
8010347a:	c9                   	leave  
8010347b:	c3                   	ret    

8010347c <mycpu>:
{
8010347c:	55                   	push   %ebp
8010347d:	89 e5                	mov    %esp,%ebp
8010347f:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103482:	9c                   	pushf  
80103483:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103484:	f6 c4 02             	test   $0x2,%ah
80103487:	75 28                	jne    801034b1 <mycpu+0x35>
  apicid = lapicid();
80103489:	e8 e5 f1 ff ff       	call   80102673 <lapicid>
  for (i = 0; i < ncpu; ++i) {
8010348e:	ba 00 00 00 00       	mov    $0x0,%edx
80103493:	39 15 40 2d 13 80    	cmp    %edx,0x80132d40
80103499:	7e 23                	jle    801034be <mycpu+0x42>
    if (cpus[i].apicid == apicid)
8010349b:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
801034a1:	0f b6 89 c0 27 13 80 	movzbl -0x7fecd840(%ecx),%ecx
801034a8:	39 c1                	cmp    %eax,%ecx
801034aa:	74 1f                	je     801034cb <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
801034ac:	83 c2 01             	add    $0x1,%edx
801034af:	eb e2                	jmp    80103493 <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
801034b1:	83 ec 0c             	sub    $0xc,%esp
801034b4:	68 f8 6d 10 80       	push   $0x80106df8
801034b9:	e8 8a ce ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
801034be:	83 ec 0c             	sub    $0xc,%esp
801034c1:	68 1c 6d 10 80       	push   $0x80106d1c
801034c6:	e8 7d ce ff ff       	call   80100348 <panic>
      return &cpus[i];
801034cb:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
801034d1:	05 c0 27 13 80       	add    $0x801327c0,%eax
}
801034d6:	c9                   	leave  
801034d7:	c3                   	ret    

801034d8 <cpuid>:
cpuid() {
801034d8:	55                   	push   %ebp
801034d9:	89 e5                	mov    %esp,%ebp
801034db:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
801034de:	e8 99 ff ff ff       	call   8010347c <mycpu>
801034e3:	2d c0 27 13 80       	sub    $0x801327c0,%eax
801034e8:	c1 f8 04             	sar    $0x4,%eax
801034eb:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
801034f1:	c9                   	leave  
801034f2:	c3                   	ret    

801034f3 <myproc>:
myproc(void) {
801034f3:	55                   	push   %ebp
801034f4:	89 e5                	mov    %esp,%ebp
801034f6:	53                   	push   %ebx
801034f7:	83 ec 04             	sub    $0x4,%esp
  pushcli();
801034fa:	e8 b9 08 00 00       	call   80103db8 <pushcli>
  c = mycpu();
801034ff:	e8 78 ff ff ff       	call   8010347c <mycpu>
  p = c->proc;
80103504:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
8010350a:	e8 e6 08 00 00       	call   80103df5 <popcli>
}
8010350f:	89 d8                	mov    %ebx,%eax
80103511:	83 c4 04             	add    $0x4,%esp
80103514:	5b                   	pop    %ebx
80103515:	5d                   	pop    %ebp
80103516:	c3                   	ret    

80103517 <userinit>:
{
80103517:	55                   	push   %ebp
80103518:	89 e5                	mov    %esp,%ebp
8010351a:	53                   	push   %ebx
8010351b:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
8010351e:	e8 3b fe ff ff       	call   8010335e <allocproc>
80103523:	89 c3                	mov    %eax,%ebx
  initproc = p;
80103525:	a3 bc a5 12 80       	mov    %eax,0x8012a5bc
  if((p->pgdir = setupkvm()) == 0)
8010352a:	e8 27 30 00 00       	call   80106556 <setupkvm>
8010352f:	89 43 04             	mov    %eax,0x4(%ebx)
80103532:	85 c0                	test   %eax,%eax
80103534:	0f 84 b7 00 00 00    	je     801035f1 <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
8010353a:	83 ec 04             	sub    $0x4,%esp
8010353d:	68 2c 00 00 00       	push   $0x2c
80103542:	68 60 a4 12 80       	push   $0x8012a460
80103547:	50                   	push   %eax
80103548:	e8 01 2d 00 00       	call   8010624e <inituvm>
  p->sz = PGSIZE;
8010354d:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
80103553:	83 c4 0c             	add    $0xc,%esp
80103556:	6a 4c                	push   $0x4c
80103558:	6a 00                	push   $0x0
8010355a:	ff 73 18             	pushl  0x18(%ebx)
8010355d:	e8 df 09 00 00       	call   80103f41 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80103562:	8b 43 18             	mov    0x18(%ebx),%eax
80103565:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
8010356b:	8b 43 18             	mov    0x18(%ebx),%eax
8010356e:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
80103574:	8b 43 18             	mov    0x18(%ebx),%eax
80103577:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
8010357b:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
8010357f:	8b 43 18             	mov    0x18(%ebx),%eax
80103582:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
80103586:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
8010358a:	8b 43 18             	mov    0x18(%ebx),%eax
8010358d:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80103594:	8b 43 18             	mov    0x18(%ebx),%eax
80103597:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
8010359e:	8b 43 18             	mov    0x18(%ebx),%eax
801035a1:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
801035a8:	8d 43 6c             	lea    0x6c(%ebx),%eax
801035ab:	83 c4 0c             	add    $0xc,%esp
801035ae:	6a 10                	push   $0x10
801035b0:	68 45 6d 10 80       	push   $0x80106d45
801035b5:	50                   	push   %eax
801035b6:	e8 ed 0a 00 00       	call   801040a8 <safestrcpy>
  p->cwd = namei("/");
801035bb:	c7 04 24 4e 6d 10 80 	movl   $0x80106d4e,(%esp)
801035c2:	e8 1a e6 ff ff       	call   80101be1 <namei>
801035c7:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
801035ca:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
801035d1:	e8 bf 08 00 00       	call   80103e95 <acquire>
  p->state = RUNNABLE;
801035d6:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
801035dd:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
801035e4:	e8 11 09 00 00       	call   80103efa <release>
}
801035e9:	83 c4 10             	add    $0x10,%esp
801035ec:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801035ef:	c9                   	leave  
801035f0:	c3                   	ret    
    panic("userinit: out of memory?");
801035f1:	83 ec 0c             	sub    $0xc,%esp
801035f4:	68 2c 6d 10 80       	push   $0x80106d2c
801035f9:	e8 4a cd ff ff       	call   80100348 <panic>

801035fe <growproc>:
{
801035fe:	55                   	push   %ebp
801035ff:	89 e5                	mov    %esp,%ebp
80103601:	56                   	push   %esi
80103602:	53                   	push   %ebx
80103603:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
80103606:	e8 e8 fe ff ff       	call   801034f3 <myproc>
8010360b:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
8010360d:	8b 00                	mov    (%eax),%eax
  if(n > 0){
8010360f:	85 f6                	test   %esi,%esi
80103611:	7f 21                	jg     80103634 <growproc+0x36>
  } else if(n < 0){
80103613:	85 f6                	test   %esi,%esi
80103615:	79 33                	jns    8010364a <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103617:	83 ec 04             	sub    $0x4,%esp
8010361a:	01 c6                	add    %eax,%esi
8010361c:	56                   	push   %esi
8010361d:	50                   	push   %eax
8010361e:	ff 73 04             	pushl  0x4(%ebx)
80103621:	e8 36 2d 00 00       	call   8010635c <deallocuvm>
80103626:	83 c4 10             	add    $0x10,%esp
80103629:	85 c0                	test   %eax,%eax
8010362b:	75 1d                	jne    8010364a <growproc+0x4c>
      return -1;
8010362d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103632:	eb 29                	jmp    8010365d <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103634:	83 ec 04             	sub    $0x4,%esp
80103637:	01 c6                	add    %eax,%esi
80103639:	56                   	push   %esi
8010363a:	50                   	push   %eax
8010363b:	ff 73 04             	pushl  0x4(%ebx)
8010363e:	e8 ab 2d 00 00       	call   801063ee <allocuvm>
80103643:	83 c4 10             	add    $0x10,%esp
80103646:	85 c0                	test   %eax,%eax
80103648:	74 1a                	je     80103664 <growproc+0x66>
  curproc->sz = sz;
8010364a:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
8010364c:	83 ec 0c             	sub    $0xc,%esp
8010364f:	53                   	push   %ebx
80103650:	e8 e1 2a 00 00       	call   80106136 <switchuvm>
  return 0;
80103655:	83 c4 10             	add    $0x10,%esp
80103658:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010365d:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103660:	5b                   	pop    %ebx
80103661:	5e                   	pop    %esi
80103662:	5d                   	pop    %ebp
80103663:	c3                   	ret    
      return -1;
80103664:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103669:	eb f2                	jmp    8010365d <growproc+0x5f>

8010366b <fork>:
{
8010366b:	55                   	push   %ebp
8010366c:	89 e5                	mov    %esp,%ebp
8010366e:	57                   	push   %edi
8010366f:	56                   	push   %esi
80103670:	53                   	push   %ebx
80103671:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
80103674:	e8 7a fe ff ff       	call   801034f3 <myproc>
80103679:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
8010367b:	e8 de fc ff ff       	call   8010335e <allocproc>
80103680:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80103683:	85 c0                	test   %eax,%eax
80103685:	0f 84 e3 00 00 00    	je     8010376e <fork+0x103>
8010368b:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz, np->pid)) == 0){
8010368d:	83 ec 04             	sub    $0x4,%esp
80103690:	ff 70 10             	pushl  0x10(%eax)
80103693:	ff 33                	pushl  (%ebx)
80103695:	ff 73 04             	pushl  0x4(%ebx)
80103698:	e8 72 2f 00 00       	call   8010660f <copyuvm>
8010369d:	89 47 04             	mov    %eax,0x4(%edi)
801036a0:	83 c4 10             	add    $0x10,%esp
801036a3:	85 c0                	test   %eax,%eax
801036a5:	74 2a                	je     801036d1 <fork+0x66>
  np->sz = curproc->sz;
801036a7:	8b 03                	mov    (%ebx),%eax
801036a9:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801036ac:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
801036ae:	89 c8                	mov    %ecx,%eax
801036b0:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
801036b3:	8b 73 18             	mov    0x18(%ebx),%esi
801036b6:	8b 79 18             	mov    0x18(%ecx),%edi
801036b9:	b9 13 00 00 00       	mov    $0x13,%ecx
801036be:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
801036c0:	8b 40 18             	mov    0x18(%eax),%eax
801036c3:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
801036ca:	be 00 00 00 00       	mov    $0x0,%esi
801036cf:	eb 29                	jmp    801036fa <fork+0x8f>
    kfree(np->kstack);
801036d1:	83 ec 0c             	sub    $0xc,%esp
801036d4:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
801036d7:	ff 73 08             	pushl  0x8(%ebx)
801036da:	e8 e6 e9 ff ff       	call   801020c5 <kfree>
    np->kstack = 0;
801036df:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
801036e6:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
801036ed:	83 c4 10             	add    $0x10,%esp
801036f0:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801036f5:	eb 6d                	jmp    80103764 <fork+0xf9>
  for(i = 0; i < NOFILE; i++)
801036f7:	83 c6 01             	add    $0x1,%esi
801036fa:	83 fe 0f             	cmp    $0xf,%esi
801036fd:	7f 1d                	jg     8010371c <fork+0xb1>
    if(curproc->ofile[i])
801036ff:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
80103703:	85 c0                	test   %eax,%eax
80103705:	74 f0                	je     801036f7 <fork+0x8c>
      np->ofile[i] = filedup(curproc->ofile[i]);
80103707:	83 ec 0c             	sub    $0xc,%esp
8010370a:	50                   	push   %eax
8010370b:	e8 7e d5 ff ff       	call   80100c8e <filedup>
80103710:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103713:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
80103717:	83 c4 10             	add    $0x10,%esp
8010371a:	eb db                	jmp    801036f7 <fork+0x8c>
  np->cwd = idup(curproc->cwd);
8010371c:	83 ec 0c             	sub    $0xc,%esp
8010371f:	ff 73 68             	pushl  0x68(%ebx)
80103722:	e8 2a de ff ff       	call   80101551 <idup>
80103727:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010372a:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
8010372d:	83 c3 6c             	add    $0x6c,%ebx
80103730:	8d 47 6c             	lea    0x6c(%edi),%eax
80103733:	83 c4 0c             	add    $0xc,%esp
80103736:	6a 10                	push   $0x10
80103738:	53                   	push   %ebx
80103739:	50                   	push   %eax
8010373a:	e8 69 09 00 00       	call   801040a8 <safestrcpy>
  pid = np->pid;
8010373f:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
80103742:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
80103749:	e8 47 07 00 00       	call   80103e95 <acquire>
  np->state = RUNNABLE;
8010374e:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
80103755:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
8010375c:	e8 99 07 00 00       	call   80103efa <release>
  return pid;
80103761:	83 c4 10             	add    $0x10,%esp
}
80103764:	89 d8                	mov    %ebx,%eax
80103766:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103769:	5b                   	pop    %ebx
8010376a:	5e                   	pop    %esi
8010376b:	5f                   	pop    %edi
8010376c:	5d                   	pop    %ebp
8010376d:	c3                   	ret    
    return -1;
8010376e:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103773:	eb ef                	jmp    80103764 <fork+0xf9>

80103775 <scheduler>:
{
80103775:	55                   	push   %ebp
80103776:	89 e5                	mov    %esp,%ebp
80103778:	56                   	push   %esi
80103779:	53                   	push   %ebx
  struct cpu *c = mycpu();
8010377a:	e8 fd fc ff ff       	call   8010347c <mycpu>
8010377f:	89 c6                	mov    %eax,%esi
  c->proc = 0;
80103781:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
80103788:	00 00 00 
8010378b:	eb 5a                	jmp    801037e7 <scheduler+0x72>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010378d:	83 c3 7c             	add    $0x7c,%ebx
80103790:	81 fb 94 4c 13 80    	cmp    $0x80134c94,%ebx
80103796:	73 3f                	jae    801037d7 <scheduler+0x62>
      if(p->state != RUNNABLE)
80103798:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
8010379c:	75 ef                	jne    8010378d <scheduler+0x18>
      c->proc = p;
8010379e:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
801037a4:	83 ec 0c             	sub    $0xc,%esp
801037a7:	53                   	push   %ebx
801037a8:	e8 89 29 00 00       	call   80106136 <switchuvm>
      p->state = RUNNING;
801037ad:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
801037b4:	83 c4 08             	add    $0x8,%esp
801037b7:	ff 73 1c             	pushl  0x1c(%ebx)
801037ba:	8d 46 04             	lea    0x4(%esi),%eax
801037bd:	50                   	push   %eax
801037be:	e8 38 09 00 00       	call   801040fb <swtch>
      switchkvm();
801037c3:	e8 5c 29 00 00       	call   80106124 <switchkvm>
      c->proc = 0;
801037c8:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
801037cf:	00 00 00 
801037d2:	83 c4 10             	add    $0x10,%esp
801037d5:	eb b6                	jmp    8010378d <scheduler+0x18>
    release(&ptable.lock);
801037d7:	83 ec 0c             	sub    $0xc,%esp
801037da:	68 60 2d 13 80       	push   $0x80132d60
801037df:	e8 16 07 00 00       	call   80103efa <release>
    sti();
801037e4:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
801037e7:	fb                   	sti    
    acquire(&ptable.lock);
801037e8:	83 ec 0c             	sub    $0xc,%esp
801037eb:	68 60 2d 13 80       	push   $0x80132d60
801037f0:	e8 a0 06 00 00       	call   80103e95 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801037f5:	83 c4 10             	add    $0x10,%esp
801037f8:	bb 94 2d 13 80       	mov    $0x80132d94,%ebx
801037fd:	eb 91                	jmp    80103790 <scheduler+0x1b>

801037ff <sched>:
{
801037ff:	55                   	push   %ebp
80103800:	89 e5                	mov    %esp,%ebp
80103802:	56                   	push   %esi
80103803:	53                   	push   %ebx
  struct proc *p = myproc();
80103804:	e8 ea fc ff ff       	call   801034f3 <myproc>
80103809:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
8010380b:	83 ec 0c             	sub    $0xc,%esp
8010380e:	68 60 2d 13 80       	push   $0x80132d60
80103813:	e8 3d 06 00 00       	call   80103e55 <holding>
80103818:	83 c4 10             	add    $0x10,%esp
8010381b:	85 c0                	test   %eax,%eax
8010381d:	74 4f                	je     8010386e <sched+0x6f>
  if(mycpu()->ncli != 1)
8010381f:	e8 58 fc ff ff       	call   8010347c <mycpu>
80103824:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
8010382b:	75 4e                	jne    8010387b <sched+0x7c>
  if(p->state == RUNNING)
8010382d:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
80103831:	74 55                	je     80103888 <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103833:	9c                   	pushf  
80103834:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103835:	f6 c4 02             	test   $0x2,%ah
80103838:	75 5b                	jne    80103895 <sched+0x96>
  intena = mycpu()->intena;
8010383a:	e8 3d fc ff ff       	call   8010347c <mycpu>
8010383f:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
80103845:	e8 32 fc ff ff       	call   8010347c <mycpu>
8010384a:	83 ec 08             	sub    $0x8,%esp
8010384d:	ff 70 04             	pushl  0x4(%eax)
80103850:	83 c3 1c             	add    $0x1c,%ebx
80103853:	53                   	push   %ebx
80103854:	e8 a2 08 00 00       	call   801040fb <swtch>
  mycpu()->intena = intena;
80103859:	e8 1e fc ff ff       	call   8010347c <mycpu>
8010385e:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
80103864:	83 c4 10             	add    $0x10,%esp
80103867:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010386a:	5b                   	pop    %ebx
8010386b:	5e                   	pop    %esi
8010386c:	5d                   	pop    %ebp
8010386d:	c3                   	ret    
    panic("sched ptable.lock");
8010386e:	83 ec 0c             	sub    $0xc,%esp
80103871:	68 50 6d 10 80       	push   $0x80106d50
80103876:	e8 cd ca ff ff       	call   80100348 <panic>
    panic("sched locks");
8010387b:	83 ec 0c             	sub    $0xc,%esp
8010387e:	68 62 6d 10 80       	push   $0x80106d62
80103883:	e8 c0 ca ff ff       	call   80100348 <panic>
    panic("sched running");
80103888:	83 ec 0c             	sub    $0xc,%esp
8010388b:	68 6e 6d 10 80       	push   $0x80106d6e
80103890:	e8 b3 ca ff ff       	call   80100348 <panic>
    panic("sched interruptible");
80103895:	83 ec 0c             	sub    $0xc,%esp
80103898:	68 7c 6d 10 80       	push   $0x80106d7c
8010389d:	e8 a6 ca ff ff       	call   80100348 <panic>

801038a2 <exit>:
{
801038a2:	55                   	push   %ebp
801038a3:	89 e5                	mov    %esp,%ebp
801038a5:	56                   	push   %esi
801038a6:	53                   	push   %ebx
  struct proc *curproc = myproc();
801038a7:	e8 47 fc ff ff       	call   801034f3 <myproc>
  if(curproc == initproc)
801038ac:	39 05 bc a5 12 80    	cmp    %eax,0x8012a5bc
801038b2:	74 09                	je     801038bd <exit+0x1b>
801038b4:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
801038b6:	bb 00 00 00 00       	mov    $0x0,%ebx
801038bb:	eb 10                	jmp    801038cd <exit+0x2b>
    panic("init exiting");
801038bd:	83 ec 0c             	sub    $0xc,%esp
801038c0:	68 90 6d 10 80       	push   $0x80106d90
801038c5:	e8 7e ca ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
801038ca:	83 c3 01             	add    $0x1,%ebx
801038cd:	83 fb 0f             	cmp    $0xf,%ebx
801038d0:	7f 1e                	jg     801038f0 <exit+0x4e>
    if(curproc->ofile[fd]){
801038d2:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
801038d6:	85 c0                	test   %eax,%eax
801038d8:	74 f0                	je     801038ca <exit+0x28>
      fileclose(curproc->ofile[fd]);
801038da:	83 ec 0c             	sub    $0xc,%esp
801038dd:	50                   	push   %eax
801038de:	e8 f0 d3 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
801038e3:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
801038ea:	00 
801038eb:	83 c4 10             	add    $0x10,%esp
801038ee:	eb da                	jmp    801038ca <exit+0x28>
  begin_op();
801038f0:	e8 ae f1 ff ff       	call   80102aa3 <begin_op>
  iput(curproc->cwd);
801038f5:	83 ec 0c             	sub    $0xc,%esp
801038f8:	ff 76 68             	pushl  0x68(%esi)
801038fb:	e8 88 dd ff ff       	call   80101688 <iput>
  end_op();
80103900:	e8 18 f2 ff ff       	call   80102b1d <end_op>
  curproc->cwd = 0;
80103905:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
8010390c:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
80103913:	e8 7d 05 00 00       	call   80103e95 <acquire>
  wakeup1(curproc->parent);
80103918:	8b 46 14             	mov    0x14(%esi),%eax
8010391b:	e8 13 fa ff ff       	call   80103333 <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103920:	83 c4 10             	add    $0x10,%esp
80103923:	bb 94 2d 13 80       	mov    $0x80132d94,%ebx
80103928:	eb 03                	jmp    8010392d <exit+0x8b>
8010392a:	83 c3 7c             	add    $0x7c,%ebx
8010392d:	81 fb 94 4c 13 80    	cmp    $0x80134c94,%ebx
80103933:	73 1a                	jae    8010394f <exit+0xad>
    if(p->parent == curproc){
80103935:	39 73 14             	cmp    %esi,0x14(%ebx)
80103938:	75 f0                	jne    8010392a <exit+0x88>
      p->parent = initproc;
8010393a:	a1 bc a5 12 80       	mov    0x8012a5bc,%eax
8010393f:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
80103942:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103946:	75 e2                	jne    8010392a <exit+0x88>
        wakeup1(initproc);
80103948:	e8 e6 f9 ff ff       	call   80103333 <wakeup1>
8010394d:	eb db                	jmp    8010392a <exit+0x88>
  curproc->state = ZOMBIE;
8010394f:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
80103956:	e8 a4 fe ff ff       	call   801037ff <sched>
  panic("zombie exit");
8010395b:	83 ec 0c             	sub    $0xc,%esp
8010395e:	68 9d 6d 10 80       	push   $0x80106d9d
80103963:	e8 e0 c9 ff ff       	call   80100348 <panic>

80103968 <yield>:
{
80103968:	55                   	push   %ebp
80103969:	89 e5                	mov    %esp,%ebp
8010396b:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
8010396e:	68 60 2d 13 80       	push   $0x80132d60
80103973:	e8 1d 05 00 00       	call   80103e95 <acquire>
  myproc()->state = RUNNABLE;
80103978:	e8 76 fb ff ff       	call   801034f3 <myproc>
8010397d:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80103984:	e8 76 fe ff ff       	call   801037ff <sched>
  release(&ptable.lock);
80103989:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
80103990:	e8 65 05 00 00       	call   80103efa <release>
}
80103995:	83 c4 10             	add    $0x10,%esp
80103998:	c9                   	leave  
80103999:	c3                   	ret    

8010399a <sleep>:
{
8010399a:	55                   	push   %ebp
8010399b:	89 e5                	mov    %esp,%ebp
8010399d:	56                   	push   %esi
8010399e:	53                   	push   %ebx
8010399f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
801039a2:	e8 4c fb ff ff       	call   801034f3 <myproc>
  if(p == 0)
801039a7:	85 c0                	test   %eax,%eax
801039a9:	74 66                	je     80103a11 <sleep+0x77>
801039ab:	89 c6                	mov    %eax,%esi
  if(lk == 0)
801039ad:	85 db                	test   %ebx,%ebx
801039af:	74 6d                	je     80103a1e <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
801039b1:	81 fb 60 2d 13 80    	cmp    $0x80132d60,%ebx
801039b7:	74 18                	je     801039d1 <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
801039b9:	83 ec 0c             	sub    $0xc,%esp
801039bc:	68 60 2d 13 80       	push   $0x80132d60
801039c1:	e8 cf 04 00 00       	call   80103e95 <acquire>
    release(lk);
801039c6:	89 1c 24             	mov    %ebx,(%esp)
801039c9:	e8 2c 05 00 00       	call   80103efa <release>
801039ce:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
801039d1:	8b 45 08             	mov    0x8(%ebp),%eax
801039d4:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
801039d7:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
801039de:	e8 1c fe ff ff       	call   801037ff <sched>
  p->chan = 0;
801039e3:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
801039ea:	81 fb 60 2d 13 80    	cmp    $0x80132d60,%ebx
801039f0:	74 18                	je     80103a0a <sleep+0x70>
    release(&ptable.lock);
801039f2:	83 ec 0c             	sub    $0xc,%esp
801039f5:	68 60 2d 13 80       	push   $0x80132d60
801039fa:	e8 fb 04 00 00       	call   80103efa <release>
    acquire(lk);
801039ff:	89 1c 24             	mov    %ebx,(%esp)
80103a02:	e8 8e 04 00 00       	call   80103e95 <acquire>
80103a07:	83 c4 10             	add    $0x10,%esp
}
80103a0a:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a0d:	5b                   	pop    %ebx
80103a0e:	5e                   	pop    %esi
80103a0f:	5d                   	pop    %ebp
80103a10:	c3                   	ret    
    panic("sleep");
80103a11:	83 ec 0c             	sub    $0xc,%esp
80103a14:	68 a9 6d 10 80       	push   $0x80106da9
80103a19:	e8 2a c9 ff ff       	call   80100348 <panic>
    panic("sleep without lk");
80103a1e:	83 ec 0c             	sub    $0xc,%esp
80103a21:	68 af 6d 10 80       	push   $0x80106daf
80103a26:	e8 1d c9 ff ff       	call   80100348 <panic>

80103a2b <wait>:
{
80103a2b:	55                   	push   %ebp
80103a2c:	89 e5                	mov    %esp,%ebp
80103a2e:	56                   	push   %esi
80103a2f:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103a30:	e8 be fa ff ff       	call   801034f3 <myproc>
80103a35:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
80103a37:	83 ec 0c             	sub    $0xc,%esp
80103a3a:	68 60 2d 13 80       	push   $0x80132d60
80103a3f:	e8 51 04 00 00       	call   80103e95 <acquire>
80103a44:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
80103a47:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103a4c:	bb 94 2d 13 80       	mov    $0x80132d94,%ebx
80103a51:	eb 5b                	jmp    80103aae <wait+0x83>
        pid = p->pid;
80103a53:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
80103a56:	83 ec 0c             	sub    $0xc,%esp
80103a59:	ff 73 08             	pushl  0x8(%ebx)
80103a5c:	e8 64 e6 ff ff       	call   801020c5 <kfree>
        p->kstack = 0;
80103a61:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
80103a68:	83 c4 04             	add    $0x4,%esp
80103a6b:	ff 73 04             	pushl  0x4(%ebx)
80103a6e:	e8 73 2a 00 00       	call   801064e6 <freevm>
        p->pid = 0;
80103a73:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
80103a7a:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
80103a81:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
80103a85:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
80103a8c:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
80103a93:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
80103a9a:	e8 5b 04 00 00       	call   80103efa <release>
        return pid;
80103a9f:	83 c4 10             	add    $0x10,%esp
}
80103aa2:	89 f0                	mov    %esi,%eax
80103aa4:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103aa7:	5b                   	pop    %ebx
80103aa8:	5e                   	pop    %esi
80103aa9:	5d                   	pop    %ebp
80103aaa:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103aab:	83 c3 7c             	add    $0x7c,%ebx
80103aae:	81 fb 94 4c 13 80    	cmp    $0x80134c94,%ebx
80103ab4:	73 12                	jae    80103ac8 <wait+0x9d>
      if(p->parent != curproc)
80103ab6:	39 73 14             	cmp    %esi,0x14(%ebx)
80103ab9:	75 f0                	jne    80103aab <wait+0x80>
      if(p->state == ZOMBIE){
80103abb:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103abf:	74 92                	je     80103a53 <wait+0x28>
      havekids = 1;
80103ac1:	b8 01 00 00 00       	mov    $0x1,%eax
80103ac6:	eb e3                	jmp    80103aab <wait+0x80>
    if(!havekids || curproc->killed){
80103ac8:	85 c0                	test   %eax,%eax
80103aca:	74 06                	je     80103ad2 <wait+0xa7>
80103acc:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
80103ad0:	74 17                	je     80103ae9 <wait+0xbe>
      release(&ptable.lock);
80103ad2:	83 ec 0c             	sub    $0xc,%esp
80103ad5:	68 60 2d 13 80       	push   $0x80132d60
80103ada:	e8 1b 04 00 00       	call   80103efa <release>
      return -1;
80103adf:	83 c4 10             	add    $0x10,%esp
80103ae2:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103ae7:	eb b9                	jmp    80103aa2 <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80103ae9:	83 ec 08             	sub    $0x8,%esp
80103aec:	68 60 2d 13 80       	push   $0x80132d60
80103af1:	56                   	push   %esi
80103af2:	e8 a3 fe ff ff       	call   8010399a <sleep>
    havekids = 0;
80103af7:	83 c4 10             	add    $0x10,%esp
80103afa:	e9 48 ff ff ff       	jmp    80103a47 <wait+0x1c>

80103aff <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80103aff:	55                   	push   %ebp
80103b00:	89 e5                	mov    %esp,%ebp
80103b02:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
80103b05:	68 60 2d 13 80       	push   $0x80132d60
80103b0a:	e8 86 03 00 00       	call   80103e95 <acquire>
  wakeup1(chan);
80103b0f:	8b 45 08             	mov    0x8(%ebp),%eax
80103b12:	e8 1c f8 ff ff       	call   80103333 <wakeup1>
  release(&ptable.lock);
80103b17:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
80103b1e:	e8 d7 03 00 00       	call   80103efa <release>
}
80103b23:	83 c4 10             	add    $0x10,%esp
80103b26:	c9                   	leave  
80103b27:	c3                   	ret    

80103b28 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80103b28:	55                   	push   %ebp
80103b29:	89 e5                	mov    %esp,%ebp
80103b2b:	53                   	push   %ebx
80103b2c:	83 ec 10             	sub    $0x10,%esp
80103b2f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
80103b32:	68 60 2d 13 80       	push   $0x80132d60
80103b37:	e8 59 03 00 00       	call   80103e95 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103b3c:	83 c4 10             	add    $0x10,%esp
80103b3f:	b8 94 2d 13 80       	mov    $0x80132d94,%eax
80103b44:	3d 94 4c 13 80       	cmp    $0x80134c94,%eax
80103b49:	73 3a                	jae    80103b85 <kill+0x5d>
    if(p->pid == pid){
80103b4b:	39 58 10             	cmp    %ebx,0x10(%eax)
80103b4e:	74 05                	je     80103b55 <kill+0x2d>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103b50:	83 c0 7c             	add    $0x7c,%eax
80103b53:	eb ef                	jmp    80103b44 <kill+0x1c>
      p->killed = 1;
80103b55:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80103b5c:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
80103b60:	74 1a                	je     80103b7c <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
80103b62:	83 ec 0c             	sub    $0xc,%esp
80103b65:	68 60 2d 13 80       	push   $0x80132d60
80103b6a:	e8 8b 03 00 00       	call   80103efa <release>
      return 0;
80103b6f:	83 c4 10             	add    $0x10,%esp
80103b72:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
80103b77:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103b7a:	c9                   	leave  
80103b7b:	c3                   	ret    
        p->state = RUNNABLE;
80103b7c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80103b83:	eb dd                	jmp    80103b62 <kill+0x3a>
  release(&ptable.lock);
80103b85:	83 ec 0c             	sub    $0xc,%esp
80103b88:	68 60 2d 13 80       	push   $0x80132d60
80103b8d:	e8 68 03 00 00       	call   80103efa <release>
  return -1;
80103b92:	83 c4 10             	add    $0x10,%esp
80103b95:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103b9a:	eb db                	jmp    80103b77 <kill+0x4f>

80103b9c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80103b9c:	55                   	push   %ebp
80103b9d:	89 e5                	mov    %esp,%ebp
80103b9f:	56                   	push   %esi
80103ba0:	53                   	push   %ebx
80103ba1:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103ba4:	bb 94 2d 13 80       	mov    $0x80132d94,%ebx
80103ba9:	eb 33                	jmp    80103bde <procdump+0x42>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103bab:	b8 c0 6d 10 80       	mov    $0x80106dc0,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
80103bb0:	8d 53 6c             	lea    0x6c(%ebx),%edx
80103bb3:	52                   	push   %edx
80103bb4:	50                   	push   %eax
80103bb5:	ff 73 10             	pushl  0x10(%ebx)
80103bb8:	68 c4 6d 10 80       	push   $0x80106dc4
80103bbd:	e8 49 ca ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
80103bc2:	83 c4 10             	add    $0x10,%esp
80103bc5:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103bc9:	74 39                	je     80103c04 <procdump+0x68>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103bcb:	83 ec 0c             	sub    $0xc,%esp
80103bce:	68 3b 71 10 80       	push   $0x8010713b
80103bd3:	e8 33 ca ff ff       	call   8010060b <cprintf>
80103bd8:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103bdb:	83 c3 7c             	add    $0x7c,%ebx
80103bde:	81 fb 94 4c 13 80    	cmp    $0x80134c94,%ebx
80103be4:	73 61                	jae    80103c47 <procdump+0xab>
    if(p->state == UNUSED)
80103be6:	8b 43 0c             	mov    0xc(%ebx),%eax
80103be9:	85 c0                	test   %eax,%eax
80103beb:	74 ee                	je     80103bdb <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103bed:	83 f8 05             	cmp    $0x5,%eax
80103bf0:	77 b9                	ja     80103bab <procdump+0xf>
80103bf2:	8b 04 85 20 6e 10 80 	mov    -0x7fef91e0(,%eax,4),%eax
80103bf9:	85 c0                	test   %eax,%eax
80103bfb:	75 b3                	jne    80103bb0 <procdump+0x14>
      state = "???";
80103bfd:	b8 c0 6d 10 80       	mov    $0x80106dc0,%eax
80103c02:	eb ac                	jmp    80103bb0 <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80103c04:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103c07:	8b 40 0c             	mov    0xc(%eax),%eax
80103c0a:	83 c0 08             	add    $0x8,%eax
80103c0d:	83 ec 08             	sub    $0x8,%esp
80103c10:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103c13:	52                   	push   %edx
80103c14:	50                   	push   %eax
80103c15:	e8 5a 01 00 00       	call   80103d74 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103c1a:	83 c4 10             	add    $0x10,%esp
80103c1d:	be 00 00 00 00       	mov    $0x0,%esi
80103c22:	eb 14                	jmp    80103c38 <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103c24:	83 ec 08             	sub    $0x8,%esp
80103c27:	50                   	push   %eax
80103c28:	68 01 68 10 80       	push   $0x80106801
80103c2d:	e8 d9 c9 ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103c32:	83 c6 01             	add    $0x1,%esi
80103c35:	83 c4 10             	add    $0x10,%esp
80103c38:	83 fe 09             	cmp    $0x9,%esi
80103c3b:	7f 8e                	jg     80103bcb <procdump+0x2f>
80103c3d:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103c41:	85 c0                	test   %eax,%eax
80103c43:	75 df                	jne    80103c24 <procdump+0x88>
80103c45:	eb 84                	jmp    80103bcb <procdump+0x2f>
  }
80103c47:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103c4a:	5b                   	pop    %ebx
80103c4b:	5e                   	pop    %esi
80103c4c:	5d                   	pop    %ebp
80103c4d:	c3                   	ret    

80103c4e <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103c4e:	55                   	push   %ebp
80103c4f:	89 e5                	mov    %esp,%ebp
80103c51:	53                   	push   %ebx
80103c52:	83 ec 0c             	sub    $0xc,%esp
80103c55:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103c58:	68 38 6e 10 80       	push   $0x80106e38
80103c5d:	8d 43 04             	lea    0x4(%ebx),%eax
80103c60:	50                   	push   %eax
80103c61:	e8 f3 00 00 00       	call   80103d59 <initlock>
  lk->name = name;
80103c66:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c69:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103c6c:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103c72:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103c79:	83 c4 10             	add    $0x10,%esp
80103c7c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103c7f:	c9                   	leave  
80103c80:	c3                   	ret    

80103c81 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103c81:	55                   	push   %ebp
80103c82:	89 e5                	mov    %esp,%ebp
80103c84:	56                   	push   %esi
80103c85:	53                   	push   %ebx
80103c86:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103c89:	8d 73 04             	lea    0x4(%ebx),%esi
80103c8c:	83 ec 0c             	sub    $0xc,%esp
80103c8f:	56                   	push   %esi
80103c90:	e8 00 02 00 00       	call   80103e95 <acquire>
  while (lk->locked) {
80103c95:	83 c4 10             	add    $0x10,%esp
80103c98:	eb 0d                	jmp    80103ca7 <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103c9a:	83 ec 08             	sub    $0x8,%esp
80103c9d:	56                   	push   %esi
80103c9e:	53                   	push   %ebx
80103c9f:	e8 f6 fc ff ff       	call   8010399a <sleep>
80103ca4:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103ca7:	83 3b 00             	cmpl   $0x0,(%ebx)
80103caa:	75 ee                	jne    80103c9a <acquiresleep+0x19>
  }
  lk->locked = 1;
80103cac:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103cb2:	e8 3c f8 ff ff       	call   801034f3 <myproc>
80103cb7:	8b 40 10             	mov    0x10(%eax),%eax
80103cba:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103cbd:	83 ec 0c             	sub    $0xc,%esp
80103cc0:	56                   	push   %esi
80103cc1:	e8 34 02 00 00       	call   80103efa <release>
}
80103cc6:	83 c4 10             	add    $0x10,%esp
80103cc9:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103ccc:	5b                   	pop    %ebx
80103ccd:	5e                   	pop    %esi
80103cce:	5d                   	pop    %ebp
80103ccf:	c3                   	ret    

80103cd0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103cd0:	55                   	push   %ebp
80103cd1:	89 e5                	mov    %esp,%ebp
80103cd3:	56                   	push   %esi
80103cd4:	53                   	push   %ebx
80103cd5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103cd8:	8d 73 04             	lea    0x4(%ebx),%esi
80103cdb:	83 ec 0c             	sub    $0xc,%esp
80103cde:	56                   	push   %esi
80103cdf:	e8 b1 01 00 00       	call   80103e95 <acquire>
  lk->locked = 0;
80103ce4:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103cea:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103cf1:	89 1c 24             	mov    %ebx,(%esp)
80103cf4:	e8 06 fe ff ff       	call   80103aff <wakeup>
  release(&lk->lk);
80103cf9:	89 34 24             	mov    %esi,(%esp)
80103cfc:	e8 f9 01 00 00       	call   80103efa <release>
}
80103d01:	83 c4 10             	add    $0x10,%esp
80103d04:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103d07:	5b                   	pop    %ebx
80103d08:	5e                   	pop    %esi
80103d09:	5d                   	pop    %ebp
80103d0a:	c3                   	ret    

80103d0b <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103d0b:	55                   	push   %ebp
80103d0c:	89 e5                	mov    %esp,%ebp
80103d0e:	56                   	push   %esi
80103d0f:	53                   	push   %ebx
80103d10:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103d13:	8d 73 04             	lea    0x4(%ebx),%esi
80103d16:	83 ec 0c             	sub    $0xc,%esp
80103d19:	56                   	push   %esi
80103d1a:	e8 76 01 00 00       	call   80103e95 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103d1f:	83 c4 10             	add    $0x10,%esp
80103d22:	83 3b 00             	cmpl   $0x0,(%ebx)
80103d25:	75 17                	jne    80103d3e <holdingsleep+0x33>
80103d27:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103d2c:	83 ec 0c             	sub    $0xc,%esp
80103d2f:	56                   	push   %esi
80103d30:	e8 c5 01 00 00       	call   80103efa <release>
  return r;
}
80103d35:	89 d8                	mov    %ebx,%eax
80103d37:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103d3a:	5b                   	pop    %ebx
80103d3b:	5e                   	pop    %esi
80103d3c:	5d                   	pop    %ebp
80103d3d:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103d3e:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103d41:	e8 ad f7 ff ff       	call   801034f3 <myproc>
80103d46:	3b 58 10             	cmp    0x10(%eax),%ebx
80103d49:	74 07                	je     80103d52 <holdingsleep+0x47>
80103d4b:	bb 00 00 00 00       	mov    $0x0,%ebx
80103d50:	eb da                	jmp    80103d2c <holdingsleep+0x21>
80103d52:	bb 01 00 00 00       	mov    $0x1,%ebx
80103d57:	eb d3                	jmp    80103d2c <holdingsleep+0x21>

80103d59 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103d59:	55                   	push   %ebp
80103d5a:	89 e5                	mov    %esp,%ebp
80103d5c:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103d5f:	8b 55 0c             	mov    0xc(%ebp),%edx
80103d62:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103d65:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103d6b:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103d72:	5d                   	pop    %ebp
80103d73:	c3                   	ret    

80103d74 <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103d74:	55                   	push   %ebp
80103d75:	89 e5                	mov    %esp,%ebp
80103d77:	53                   	push   %ebx
80103d78:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103d7b:	8b 45 08             	mov    0x8(%ebp),%eax
80103d7e:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103d81:	b8 00 00 00 00       	mov    $0x0,%eax
80103d86:	83 f8 09             	cmp    $0x9,%eax
80103d89:	7f 25                	jg     80103db0 <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103d8b:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103d91:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103d97:	77 17                	ja     80103db0 <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103d99:	8b 5a 04             	mov    0x4(%edx),%ebx
80103d9c:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103d9f:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103da1:	83 c0 01             	add    $0x1,%eax
80103da4:	eb e0                	jmp    80103d86 <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103da6:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103dad:	83 c0 01             	add    $0x1,%eax
80103db0:	83 f8 09             	cmp    $0x9,%eax
80103db3:	7e f1                	jle    80103da6 <getcallerpcs+0x32>
}
80103db5:	5b                   	pop    %ebx
80103db6:	5d                   	pop    %ebp
80103db7:	c3                   	ret    

80103db8 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103db8:	55                   	push   %ebp
80103db9:	89 e5                	mov    %esp,%ebp
80103dbb:	53                   	push   %ebx
80103dbc:	83 ec 04             	sub    $0x4,%esp
80103dbf:	9c                   	pushf  
80103dc0:	5b                   	pop    %ebx
  asm volatile("cli");
80103dc1:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103dc2:	e8 b5 f6 ff ff       	call   8010347c <mycpu>
80103dc7:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103dce:	74 12                	je     80103de2 <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103dd0:	e8 a7 f6 ff ff       	call   8010347c <mycpu>
80103dd5:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103ddc:	83 c4 04             	add    $0x4,%esp
80103ddf:	5b                   	pop    %ebx
80103de0:	5d                   	pop    %ebp
80103de1:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103de2:	e8 95 f6 ff ff       	call   8010347c <mycpu>
80103de7:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103ded:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103df3:	eb db                	jmp    80103dd0 <pushcli+0x18>

80103df5 <popcli>:

void
popcli(void)
{
80103df5:	55                   	push   %ebp
80103df6:	89 e5                	mov    %esp,%ebp
80103df8:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103dfb:	9c                   	pushf  
80103dfc:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103dfd:	f6 c4 02             	test   $0x2,%ah
80103e00:	75 28                	jne    80103e2a <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103e02:	e8 75 f6 ff ff       	call   8010347c <mycpu>
80103e07:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103e0d:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103e10:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103e16:	85 d2                	test   %edx,%edx
80103e18:	78 1d                	js     80103e37 <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103e1a:	e8 5d f6 ff ff       	call   8010347c <mycpu>
80103e1f:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103e26:	74 1c                	je     80103e44 <popcli+0x4f>
    sti();
}
80103e28:	c9                   	leave  
80103e29:	c3                   	ret    
    panic("popcli - interruptible");
80103e2a:	83 ec 0c             	sub    $0xc,%esp
80103e2d:	68 43 6e 10 80       	push   $0x80106e43
80103e32:	e8 11 c5 ff ff       	call   80100348 <panic>
    panic("popcli");
80103e37:	83 ec 0c             	sub    $0xc,%esp
80103e3a:	68 5a 6e 10 80       	push   $0x80106e5a
80103e3f:	e8 04 c5 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103e44:	e8 33 f6 ff ff       	call   8010347c <mycpu>
80103e49:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103e50:	74 d6                	je     80103e28 <popcli+0x33>
  asm volatile("sti");
80103e52:	fb                   	sti    
}
80103e53:	eb d3                	jmp    80103e28 <popcli+0x33>

80103e55 <holding>:
{
80103e55:	55                   	push   %ebp
80103e56:	89 e5                	mov    %esp,%ebp
80103e58:	53                   	push   %ebx
80103e59:	83 ec 04             	sub    $0x4,%esp
80103e5c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103e5f:	e8 54 ff ff ff       	call   80103db8 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103e64:	83 3b 00             	cmpl   $0x0,(%ebx)
80103e67:	75 12                	jne    80103e7b <holding+0x26>
80103e69:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103e6e:	e8 82 ff ff ff       	call   80103df5 <popcli>
}
80103e73:	89 d8                	mov    %ebx,%eax
80103e75:	83 c4 04             	add    $0x4,%esp
80103e78:	5b                   	pop    %ebx
80103e79:	5d                   	pop    %ebp
80103e7a:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103e7b:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103e7e:	e8 f9 f5 ff ff       	call   8010347c <mycpu>
80103e83:	39 c3                	cmp    %eax,%ebx
80103e85:	74 07                	je     80103e8e <holding+0x39>
80103e87:	bb 00 00 00 00       	mov    $0x0,%ebx
80103e8c:	eb e0                	jmp    80103e6e <holding+0x19>
80103e8e:	bb 01 00 00 00       	mov    $0x1,%ebx
80103e93:	eb d9                	jmp    80103e6e <holding+0x19>

80103e95 <acquire>:
{
80103e95:	55                   	push   %ebp
80103e96:	89 e5                	mov    %esp,%ebp
80103e98:	53                   	push   %ebx
80103e99:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103e9c:	e8 17 ff ff ff       	call   80103db8 <pushcli>
  if(holding(lk))
80103ea1:	83 ec 0c             	sub    $0xc,%esp
80103ea4:	ff 75 08             	pushl  0x8(%ebp)
80103ea7:	e8 a9 ff ff ff       	call   80103e55 <holding>
80103eac:	83 c4 10             	add    $0x10,%esp
80103eaf:	85 c0                	test   %eax,%eax
80103eb1:	75 3a                	jne    80103eed <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103eb3:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103eb6:	b8 01 00 00 00       	mov    $0x1,%eax
80103ebb:	f0 87 02             	lock xchg %eax,(%edx)
80103ebe:	85 c0                	test   %eax,%eax
80103ec0:	75 f1                	jne    80103eb3 <acquire+0x1e>
  __sync_synchronize();
80103ec2:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103ec7:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103eca:	e8 ad f5 ff ff       	call   8010347c <mycpu>
80103ecf:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103ed2:	8b 45 08             	mov    0x8(%ebp),%eax
80103ed5:	83 c0 0c             	add    $0xc,%eax
80103ed8:	83 ec 08             	sub    $0x8,%esp
80103edb:	50                   	push   %eax
80103edc:	8d 45 08             	lea    0x8(%ebp),%eax
80103edf:	50                   	push   %eax
80103ee0:	e8 8f fe ff ff       	call   80103d74 <getcallerpcs>
}
80103ee5:	83 c4 10             	add    $0x10,%esp
80103ee8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103eeb:	c9                   	leave  
80103eec:	c3                   	ret    
    panic("acquire");
80103eed:	83 ec 0c             	sub    $0xc,%esp
80103ef0:	68 61 6e 10 80       	push   $0x80106e61
80103ef5:	e8 4e c4 ff ff       	call   80100348 <panic>

80103efa <release>:
{
80103efa:	55                   	push   %ebp
80103efb:	89 e5                	mov    %esp,%ebp
80103efd:	53                   	push   %ebx
80103efe:	83 ec 10             	sub    $0x10,%esp
80103f01:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103f04:	53                   	push   %ebx
80103f05:	e8 4b ff ff ff       	call   80103e55 <holding>
80103f0a:	83 c4 10             	add    $0x10,%esp
80103f0d:	85 c0                	test   %eax,%eax
80103f0f:	74 23                	je     80103f34 <release+0x3a>
  lk->pcs[0] = 0;
80103f11:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103f18:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103f1f:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103f24:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103f2a:	e8 c6 fe ff ff       	call   80103df5 <popcli>
}
80103f2f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103f32:	c9                   	leave  
80103f33:	c3                   	ret    
    panic("release");
80103f34:	83 ec 0c             	sub    $0xc,%esp
80103f37:	68 69 6e 10 80       	push   $0x80106e69
80103f3c:	e8 07 c4 ff ff       	call   80100348 <panic>

80103f41 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103f41:	55                   	push   %ebp
80103f42:	89 e5                	mov    %esp,%ebp
80103f44:	57                   	push   %edi
80103f45:	53                   	push   %ebx
80103f46:	8b 55 08             	mov    0x8(%ebp),%edx
80103f49:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103f4c:	f6 c2 03             	test   $0x3,%dl
80103f4f:	75 05                	jne    80103f56 <memset+0x15>
80103f51:	f6 c1 03             	test   $0x3,%cl
80103f54:	74 0e                	je     80103f64 <memset+0x23>
  asm volatile("cld; rep stosb" :
80103f56:	89 d7                	mov    %edx,%edi
80103f58:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f5b:	fc                   	cld    
80103f5c:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103f5e:	89 d0                	mov    %edx,%eax
80103f60:	5b                   	pop    %ebx
80103f61:	5f                   	pop    %edi
80103f62:	5d                   	pop    %ebp
80103f63:	c3                   	ret    
    c &= 0xFF;
80103f64:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103f68:	c1 e9 02             	shr    $0x2,%ecx
80103f6b:	89 f8                	mov    %edi,%eax
80103f6d:	c1 e0 18             	shl    $0x18,%eax
80103f70:	89 fb                	mov    %edi,%ebx
80103f72:	c1 e3 10             	shl    $0x10,%ebx
80103f75:	09 d8                	or     %ebx,%eax
80103f77:	89 fb                	mov    %edi,%ebx
80103f79:	c1 e3 08             	shl    $0x8,%ebx
80103f7c:	09 d8                	or     %ebx,%eax
80103f7e:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103f80:	89 d7                	mov    %edx,%edi
80103f82:	fc                   	cld    
80103f83:	f3 ab                	rep stos %eax,%es:(%edi)
80103f85:	eb d7                	jmp    80103f5e <memset+0x1d>

80103f87 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103f87:	55                   	push   %ebp
80103f88:	89 e5                	mov    %esp,%ebp
80103f8a:	56                   	push   %esi
80103f8b:	53                   	push   %ebx
80103f8c:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103f8f:	8b 55 0c             	mov    0xc(%ebp),%edx
80103f92:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103f95:	8d 70 ff             	lea    -0x1(%eax),%esi
80103f98:	85 c0                	test   %eax,%eax
80103f9a:	74 1c                	je     80103fb8 <memcmp+0x31>
    if(*s1 != *s2)
80103f9c:	0f b6 01             	movzbl (%ecx),%eax
80103f9f:	0f b6 1a             	movzbl (%edx),%ebx
80103fa2:	38 d8                	cmp    %bl,%al
80103fa4:	75 0a                	jne    80103fb0 <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103fa6:	83 c1 01             	add    $0x1,%ecx
80103fa9:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103fac:	89 f0                	mov    %esi,%eax
80103fae:	eb e5                	jmp    80103f95 <memcmp+0xe>
      return *s1 - *s2;
80103fb0:	0f b6 c0             	movzbl %al,%eax
80103fb3:	0f b6 db             	movzbl %bl,%ebx
80103fb6:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103fb8:	5b                   	pop    %ebx
80103fb9:	5e                   	pop    %esi
80103fba:	5d                   	pop    %ebp
80103fbb:	c3                   	ret    

80103fbc <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103fbc:	55                   	push   %ebp
80103fbd:	89 e5                	mov    %esp,%ebp
80103fbf:	56                   	push   %esi
80103fc0:	53                   	push   %ebx
80103fc1:	8b 45 08             	mov    0x8(%ebp),%eax
80103fc4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103fc7:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103fca:	39 c1                	cmp    %eax,%ecx
80103fcc:	73 3a                	jae    80104008 <memmove+0x4c>
80103fce:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103fd1:	39 c3                	cmp    %eax,%ebx
80103fd3:	76 37                	jbe    8010400c <memmove+0x50>
    s += n;
    d += n;
80103fd5:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103fd8:	eb 0d                	jmp    80103fe7 <memmove+0x2b>
      *--d = *--s;
80103fda:	83 eb 01             	sub    $0x1,%ebx
80103fdd:	83 e9 01             	sub    $0x1,%ecx
80103fe0:	0f b6 13             	movzbl (%ebx),%edx
80103fe3:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103fe5:	89 f2                	mov    %esi,%edx
80103fe7:	8d 72 ff             	lea    -0x1(%edx),%esi
80103fea:	85 d2                	test   %edx,%edx
80103fec:	75 ec                	jne    80103fda <memmove+0x1e>
80103fee:	eb 14                	jmp    80104004 <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103ff0:	0f b6 11             	movzbl (%ecx),%edx
80103ff3:	88 13                	mov    %dl,(%ebx)
80103ff5:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103ff8:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103ffb:	89 f2                	mov    %esi,%edx
80103ffd:	8d 72 ff             	lea    -0x1(%edx),%esi
80104000:	85 d2                	test   %edx,%edx
80104002:	75 ec                	jne    80103ff0 <memmove+0x34>

  return dst;
}
80104004:	5b                   	pop    %ebx
80104005:	5e                   	pop    %esi
80104006:	5d                   	pop    %ebp
80104007:	c3                   	ret    
80104008:	89 c3                	mov    %eax,%ebx
8010400a:	eb f1                	jmp    80103ffd <memmove+0x41>
8010400c:	89 c3                	mov    %eax,%ebx
8010400e:	eb ed                	jmp    80103ffd <memmove+0x41>

80104010 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80104010:	55                   	push   %ebp
80104011:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80104013:	ff 75 10             	pushl  0x10(%ebp)
80104016:	ff 75 0c             	pushl  0xc(%ebp)
80104019:	ff 75 08             	pushl  0x8(%ebp)
8010401c:	e8 9b ff ff ff       	call   80103fbc <memmove>
}
80104021:	c9                   	leave  
80104022:	c3                   	ret    

80104023 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80104023:	55                   	push   %ebp
80104024:	89 e5                	mov    %esp,%ebp
80104026:	53                   	push   %ebx
80104027:	8b 55 08             	mov    0x8(%ebp),%edx
8010402a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010402d:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80104030:	eb 09                	jmp    8010403b <strncmp+0x18>
    n--, p++, q++;
80104032:	83 e8 01             	sub    $0x1,%eax
80104035:	83 c2 01             	add    $0x1,%edx
80104038:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
8010403b:	85 c0                	test   %eax,%eax
8010403d:	74 0b                	je     8010404a <strncmp+0x27>
8010403f:	0f b6 1a             	movzbl (%edx),%ebx
80104042:	84 db                	test   %bl,%bl
80104044:	74 04                	je     8010404a <strncmp+0x27>
80104046:	3a 19                	cmp    (%ecx),%bl
80104048:	74 e8                	je     80104032 <strncmp+0xf>
  if(n == 0)
8010404a:	85 c0                	test   %eax,%eax
8010404c:	74 0b                	je     80104059 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
8010404e:	0f b6 02             	movzbl (%edx),%eax
80104051:	0f b6 11             	movzbl (%ecx),%edx
80104054:	29 d0                	sub    %edx,%eax
}
80104056:	5b                   	pop    %ebx
80104057:	5d                   	pop    %ebp
80104058:	c3                   	ret    
    return 0;
80104059:	b8 00 00 00 00       	mov    $0x0,%eax
8010405e:	eb f6                	jmp    80104056 <strncmp+0x33>

80104060 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80104060:	55                   	push   %ebp
80104061:	89 e5                	mov    %esp,%ebp
80104063:	57                   	push   %edi
80104064:	56                   	push   %esi
80104065:	53                   	push   %ebx
80104066:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80104069:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
8010406c:	8b 45 08             	mov    0x8(%ebp),%eax
8010406f:	eb 04                	jmp    80104075 <strncpy+0x15>
80104071:	89 fb                	mov    %edi,%ebx
80104073:	89 f0                	mov    %esi,%eax
80104075:	8d 51 ff             	lea    -0x1(%ecx),%edx
80104078:	85 c9                	test   %ecx,%ecx
8010407a:	7e 1d                	jle    80104099 <strncpy+0x39>
8010407c:	8d 7b 01             	lea    0x1(%ebx),%edi
8010407f:	8d 70 01             	lea    0x1(%eax),%esi
80104082:	0f b6 1b             	movzbl (%ebx),%ebx
80104085:	88 18                	mov    %bl,(%eax)
80104087:	89 d1                	mov    %edx,%ecx
80104089:	84 db                	test   %bl,%bl
8010408b:	75 e4                	jne    80104071 <strncpy+0x11>
8010408d:	89 f0                	mov    %esi,%eax
8010408f:	eb 08                	jmp    80104099 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80104091:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80104094:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
80104096:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
80104099:	8d 4a ff             	lea    -0x1(%edx),%ecx
8010409c:	85 d2                	test   %edx,%edx
8010409e:	7f f1                	jg     80104091 <strncpy+0x31>
  return os;
}
801040a0:	8b 45 08             	mov    0x8(%ebp),%eax
801040a3:	5b                   	pop    %ebx
801040a4:	5e                   	pop    %esi
801040a5:	5f                   	pop    %edi
801040a6:	5d                   	pop    %ebp
801040a7:	c3                   	ret    

801040a8 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801040a8:	55                   	push   %ebp
801040a9:	89 e5                	mov    %esp,%ebp
801040ab:	57                   	push   %edi
801040ac:	56                   	push   %esi
801040ad:	53                   	push   %ebx
801040ae:	8b 45 08             	mov    0x8(%ebp),%eax
801040b1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
801040b4:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
801040b7:	85 d2                	test   %edx,%edx
801040b9:	7e 23                	jle    801040de <safestrcpy+0x36>
801040bb:	89 c1                	mov    %eax,%ecx
801040bd:	eb 04                	jmp    801040c3 <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
801040bf:	89 fb                	mov    %edi,%ebx
801040c1:	89 f1                	mov    %esi,%ecx
801040c3:	83 ea 01             	sub    $0x1,%edx
801040c6:	85 d2                	test   %edx,%edx
801040c8:	7e 11                	jle    801040db <safestrcpy+0x33>
801040ca:	8d 7b 01             	lea    0x1(%ebx),%edi
801040cd:	8d 71 01             	lea    0x1(%ecx),%esi
801040d0:	0f b6 1b             	movzbl (%ebx),%ebx
801040d3:	88 19                	mov    %bl,(%ecx)
801040d5:	84 db                	test   %bl,%bl
801040d7:	75 e6                	jne    801040bf <safestrcpy+0x17>
801040d9:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
801040db:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
801040de:	5b                   	pop    %ebx
801040df:	5e                   	pop    %esi
801040e0:	5f                   	pop    %edi
801040e1:	5d                   	pop    %ebp
801040e2:	c3                   	ret    

801040e3 <strlen>:

int
strlen(const char *s)
{
801040e3:	55                   	push   %ebp
801040e4:	89 e5                	mov    %esp,%ebp
801040e6:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
801040e9:	b8 00 00 00 00       	mov    $0x0,%eax
801040ee:	eb 03                	jmp    801040f3 <strlen+0x10>
801040f0:	83 c0 01             	add    $0x1,%eax
801040f3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
801040f7:	75 f7                	jne    801040f0 <strlen+0xd>
    ;
  return n;
}
801040f9:	5d                   	pop    %ebp
801040fa:	c3                   	ret    

801040fb <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
801040fb:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
801040ff:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80104103:	55                   	push   %ebp
  pushl %ebx
80104104:	53                   	push   %ebx
  pushl %esi
80104105:	56                   	push   %esi
  pushl %edi
80104106:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80104107:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80104109:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
8010410b:	5f                   	pop    %edi
  popl %esi
8010410c:	5e                   	pop    %esi
  popl %ebx
8010410d:	5b                   	pop    %ebx
  popl %ebp
8010410e:	5d                   	pop    %ebp
  ret
8010410f:	c3                   	ret    

80104110 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80104110:	55                   	push   %ebp
80104111:	89 e5                	mov    %esp,%ebp
80104113:	53                   	push   %ebx
80104114:	83 ec 04             	sub    $0x4,%esp
80104117:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
8010411a:	e8 d4 f3 ff ff       	call   801034f3 <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
8010411f:	8b 00                	mov    (%eax),%eax
80104121:	39 d8                	cmp    %ebx,%eax
80104123:	76 19                	jbe    8010413e <fetchint+0x2e>
80104125:	8d 53 04             	lea    0x4(%ebx),%edx
80104128:	39 d0                	cmp    %edx,%eax
8010412a:	72 19                	jb     80104145 <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
8010412c:	8b 13                	mov    (%ebx),%edx
8010412e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104131:	89 10                	mov    %edx,(%eax)
  return 0;
80104133:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104138:	83 c4 04             	add    $0x4,%esp
8010413b:	5b                   	pop    %ebx
8010413c:	5d                   	pop    %ebp
8010413d:	c3                   	ret    
    return -1;
8010413e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104143:	eb f3                	jmp    80104138 <fetchint+0x28>
80104145:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010414a:	eb ec                	jmp    80104138 <fetchint+0x28>

8010414c <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
8010414c:	55                   	push   %ebp
8010414d:	89 e5                	mov    %esp,%ebp
8010414f:	53                   	push   %ebx
80104150:	83 ec 04             	sub    $0x4,%esp
80104153:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
80104156:	e8 98 f3 ff ff       	call   801034f3 <myproc>

  if(addr >= curproc->sz)
8010415b:	39 18                	cmp    %ebx,(%eax)
8010415d:	76 26                	jbe    80104185 <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
8010415f:	8b 55 0c             	mov    0xc(%ebp),%edx
80104162:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
80104164:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
80104166:	89 d8                	mov    %ebx,%eax
80104168:	39 d0                	cmp    %edx,%eax
8010416a:	73 0e                	jae    8010417a <fetchstr+0x2e>
    if(*s == 0)
8010416c:	80 38 00             	cmpb   $0x0,(%eax)
8010416f:	74 05                	je     80104176 <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
80104171:	83 c0 01             	add    $0x1,%eax
80104174:	eb f2                	jmp    80104168 <fetchstr+0x1c>
      return s - *pp;
80104176:	29 d8                	sub    %ebx,%eax
80104178:	eb 05                	jmp    8010417f <fetchstr+0x33>
  }
  return -1;
8010417a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010417f:	83 c4 04             	add    $0x4,%esp
80104182:	5b                   	pop    %ebx
80104183:	5d                   	pop    %ebp
80104184:	c3                   	ret    
    return -1;
80104185:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010418a:	eb f3                	jmp    8010417f <fetchstr+0x33>

8010418c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
8010418c:	55                   	push   %ebp
8010418d:	89 e5                	mov    %esp,%ebp
8010418f:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80104192:	e8 5c f3 ff ff       	call   801034f3 <myproc>
80104197:	8b 50 18             	mov    0x18(%eax),%edx
8010419a:	8b 45 08             	mov    0x8(%ebp),%eax
8010419d:	c1 e0 02             	shl    $0x2,%eax
801041a0:	03 42 44             	add    0x44(%edx),%eax
801041a3:	83 ec 08             	sub    $0x8,%esp
801041a6:	ff 75 0c             	pushl  0xc(%ebp)
801041a9:	83 c0 04             	add    $0x4,%eax
801041ac:	50                   	push   %eax
801041ad:	e8 5e ff ff ff       	call   80104110 <fetchint>
}
801041b2:	c9                   	leave  
801041b3:	c3                   	ret    

801041b4 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801041b4:	55                   	push   %ebp
801041b5:	89 e5                	mov    %esp,%ebp
801041b7:	56                   	push   %esi
801041b8:	53                   	push   %ebx
801041b9:	83 ec 10             	sub    $0x10,%esp
801041bc:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
801041bf:	e8 2f f3 ff ff       	call   801034f3 <myproc>
801041c4:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
801041c6:	83 ec 08             	sub    $0x8,%esp
801041c9:	8d 45 f4             	lea    -0xc(%ebp),%eax
801041cc:	50                   	push   %eax
801041cd:	ff 75 08             	pushl  0x8(%ebp)
801041d0:	e8 b7 ff ff ff       	call   8010418c <argint>
801041d5:	83 c4 10             	add    $0x10,%esp
801041d8:	85 c0                	test   %eax,%eax
801041da:	78 24                	js     80104200 <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
801041dc:	85 db                	test   %ebx,%ebx
801041de:	78 27                	js     80104207 <argptr+0x53>
801041e0:	8b 16                	mov    (%esi),%edx
801041e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041e5:	39 c2                	cmp    %eax,%edx
801041e7:	76 25                	jbe    8010420e <argptr+0x5a>
801041e9:	01 c3                	add    %eax,%ebx
801041eb:	39 da                	cmp    %ebx,%edx
801041ed:	72 26                	jb     80104215 <argptr+0x61>
    return -1;
  *pp = (char*)i;
801041ef:	8b 55 0c             	mov    0xc(%ebp),%edx
801041f2:	89 02                	mov    %eax,(%edx)
  return 0;
801041f4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801041f9:	8d 65 f8             	lea    -0x8(%ebp),%esp
801041fc:	5b                   	pop    %ebx
801041fd:	5e                   	pop    %esi
801041fe:	5d                   	pop    %ebp
801041ff:	c3                   	ret    
    return -1;
80104200:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104205:	eb f2                	jmp    801041f9 <argptr+0x45>
    return -1;
80104207:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010420c:	eb eb                	jmp    801041f9 <argptr+0x45>
8010420e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104213:	eb e4                	jmp    801041f9 <argptr+0x45>
80104215:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010421a:	eb dd                	jmp    801041f9 <argptr+0x45>

8010421c <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
8010421c:	55                   	push   %ebp
8010421d:	89 e5                	mov    %esp,%ebp
8010421f:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
80104222:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104225:	50                   	push   %eax
80104226:	ff 75 08             	pushl  0x8(%ebp)
80104229:	e8 5e ff ff ff       	call   8010418c <argint>
8010422e:	83 c4 10             	add    $0x10,%esp
80104231:	85 c0                	test   %eax,%eax
80104233:	78 13                	js     80104248 <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
80104235:	83 ec 08             	sub    $0x8,%esp
80104238:	ff 75 0c             	pushl  0xc(%ebp)
8010423b:	ff 75 f4             	pushl  -0xc(%ebp)
8010423e:	e8 09 ff ff ff       	call   8010414c <fetchstr>
80104243:	83 c4 10             	add    $0x10,%esp
}
80104246:	c9                   	leave  
80104247:	c3                   	ret    
    return -1;
80104248:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010424d:	eb f7                	jmp    80104246 <argstr+0x2a>

8010424f <syscall>:
[SYS_dump_physmem]   sys_dump_physmem,
};

void
syscall(void)
{
8010424f:	55                   	push   %ebp
80104250:	89 e5                	mov    %esp,%ebp
80104252:	53                   	push   %ebx
80104253:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
80104256:	e8 98 f2 ff ff       	call   801034f3 <myproc>
8010425b:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
8010425d:	8b 40 18             	mov    0x18(%eax),%eax
80104260:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80104263:	8d 50 ff             	lea    -0x1(%eax),%edx
80104266:	83 fa 15             	cmp    $0x15,%edx
80104269:	77 18                	ja     80104283 <syscall+0x34>
8010426b:	8b 14 85 a0 6e 10 80 	mov    -0x7fef9160(,%eax,4),%edx
80104272:	85 d2                	test   %edx,%edx
80104274:	74 0d                	je     80104283 <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
80104276:	ff d2                	call   *%edx
80104278:	8b 53 18             	mov    0x18(%ebx),%edx
8010427b:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
8010427e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104281:	c9                   	leave  
80104282:	c3                   	ret    
            curproc->pid, curproc->name, num);
80104283:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
80104286:	50                   	push   %eax
80104287:	52                   	push   %edx
80104288:	ff 73 10             	pushl  0x10(%ebx)
8010428b:	68 71 6e 10 80       	push   $0x80106e71
80104290:	e8 76 c3 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
80104295:	8b 43 18             	mov    0x18(%ebx),%eax
80104298:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
8010429f:	83 c4 10             	add    $0x10,%esp
}
801042a2:	eb da                	jmp    8010427e <syscall+0x2f>

801042a4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801042a4:	55                   	push   %ebp
801042a5:	89 e5                	mov    %esp,%ebp
801042a7:	56                   	push   %esi
801042a8:	53                   	push   %ebx
801042a9:	83 ec 18             	sub    $0x18,%esp
801042ac:	89 d6                	mov    %edx,%esi
801042ae:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801042b0:	8d 55 f4             	lea    -0xc(%ebp),%edx
801042b3:	52                   	push   %edx
801042b4:	50                   	push   %eax
801042b5:	e8 d2 fe ff ff       	call   8010418c <argint>
801042ba:	83 c4 10             	add    $0x10,%esp
801042bd:	85 c0                	test   %eax,%eax
801042bf:	78 2e                	js     801042ef <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
801042c1:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
801042c5:	77 2f                	ja     801042f6 <argfd+0x52>
801042c7:	e8 27 f2 ff ff       	call   801034f3 <myproc>
801042cc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042cf:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
801042d3:	85 c0                	test   %eax,%eax
801042d5:	74 26                	je     801042fd <argfd+0x59>
    return -1;
  if(pfd)
801042d7:	85 f6                	test   %esi,%esi
801042d9:	74 02                	je     801042dd <argfd+0x39>
    *pfd = fd;
801042db:	89 16                	mov    %edx,(%esi)
  if(pf)
801042dd:	85 db                	test   %ebx,%ebx
801042df:	74 23                	je     80104304 <argfd+0x60>
    *pf = f;
801042e1:	89 03                	mov    %eax,(%ebx)
  return 0;
801042e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801042e8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801042eb:	5b                   	pop    %ebx
801042ec:	5e                   	pop    %esi
801042ed:	5d                   	pop    %ebp
801042ee:	c3                   	ret    
    return -1;
801042ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042f4:	eb f2                	jmp    801042e8 <argfd+0x44>
    return -1;
801042f6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042fb:	eb eb                	jmp    801042e8 <argfd+0x44>
801042fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104302:	eb e4                	jmp    801042e8 <argfd+0x44>
  return 0;
80104304:	b8 00 00 00 00       	mov    $0x0,%eax
80104309:	eb dd                	jmp    801042e8 <argfd+0x44>

8010430b <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
8010430b:	55                   	push   %ebp
8010430c:	89 e5                	mov    %esp,%ebp
8010430e:	53                   	push   %ebx
8010430f:	83 ec 04             	sub    $0x4,%esp
80104312:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
80104314:	e8 da f1 ff ff       	call   801034f3 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
80104319:	ba 00 00 00 00       	mov    $0x0,%edx
8010431e:	83 fa 0f             	cmp    $0xf,%edx
80104321:	7f 18                	jg     8010433b <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
80104323:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
80104328:	74 05                	je     8010432f <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
8010432a:	83 c2 01             	add    $0x1,%edx
8010432d:	eb ef                	jmp    8010431e <fdalloc+0x13>
      curproc->ofile[fd] = f;
8010432f:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
80104333:	89 d0                	mov    %edx,%eax
80104335:	83 c4 04             	add    $0x4,%esp
80104338:	5b                   	pop    %ebx
80104339:	5d                   	pop    %ebp
8010433a:	c3                   	ret    
  return -1;
8010433b:	ba ff ff ff ff       	mov    $0xffffffff,%edx
80104340:	eb f1                	jmp    80104333 <fdalloc+0x28>

80104342 <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80104342:	55                   	push   %ebp
80104343:	89 e5                	mov    %esp,%ebp
80104345:	56                   	push   %esi
80104346:	53                   	push   %ebx
80104347:	83 ec 10             	sub    $0x10,%esp
8010434a:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010434c:	b8 20 00 00 00       	mov    $0x20,%eax
80104351:	89 c6                	mov    %eax,%esi
80104353:	39 43 58             	cmp    %eax,0x58(%ebx)
80104356:	76 2e                	jbe    80104386 <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104358:	6a 10                	push   $0x10
8010435a:	50                   	push   %eax
8010435b:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010435e:	50                   	push   %eax
8010435f:	53                   	push   %ebx
80104360:	e8 0e d4 ff ff       	call   80101773 <readi>
80104365:	83 c4 10             	add    $0x10,%esp
80104368:	83 f8 10             	cmp    $0x10,%eax
8010436b:	75 0c                	jne    80104379 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
8010436d:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
80104372:	75 1e                	jne    80104392 <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104374:	8d 46 10             	lea    0x10(%esi),%eax
80104377:	eb d8                	jmp    80104351 <isdirempty+0xf>
      panic("isdirempty: readi");
80104379:	83 ec 0c             	sub    $0xc,%esp
8010437c:	68 fc 6e 10 80       	push   $0x80106efc
80104381:	e8 c2 bf ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
80104386:	b8 01 00 00 00       	mov    $0x1,%eax
}
8010438b:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010438e:	5b                   	pop    %ebx
8010438f:	5e                   	pop    %esi
80104390:	5d                   	pop    %ebp
80104391:	c3                   	ret    
      return 0;
80104392:	b8 00 00 00 00       	mov    $0x0,%eax
80104397:	eb f2                	jmp    8010438b <isdirempty+0x49>

80104399 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
80104399:	55                   	push   %ebp
8010439a:	89 e5                	mov    %esp,%ebp
8010439c:	57                   	push   %edi
8010439d:	56                   	push   %esi
8010439e:	53                   	push   %ebx
8010439f:	83 ec 44             	sub    $0x44,%esp
801043a2:	89 55 c4             	mov    %edx,-0x3c(%ebp)
801043a5:	89 4d c0             	mov    %ecx,-0x40(%ebp)
801043a8:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801043ab:	8d 55 d6             	lea    -0x2a(%ebp),%edx
801043ae:	52                   	push   %edx
801043af:	50                   	push   %eax
801043b0:	e8 44 d8 ff ff       	call   80101bf9 <nameiparent>
801043b5:	89 c6                	mov    %eax,%esi
801043b7:	83 c4 10             	add    $0x10,%esp
801043ba:	85 c0                	test   %eax,%eax
801043bc:	0f 84 3a 01 00 00    	je     801044fc <create+0x163>
    return 0;
  ilock(dp);
801043c2:	83 ec 0c             	sub    $0xc,%esp
801043c5:	50                   	push   %eax
801043c6:	e8 b6 d1 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
801043cb:	83 c4 0c             	add    $0xc,%esp
801043ce:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801043d1:	50                   	push   %eax
801043d2:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801043d5:	50                   	push   %eax
801043d6:	56                   	push   %esi
801043d7:	e8 d4 d5 ff ff       	call   801019b0 <dirlookup>
801043dc:	89 c3                	mov    %eax,%ebx
801043de:	83 c4 10             	add    $0x10,%esp
801043e1:	85 c0                	test   %eax,%eax
801043e3:	74 3f                	je     80104424 <create+0x8b>
    iunlockput(dp);
801043e5:	83 ec 0c             	sub    $0xc,%esp
801043e8:	56                   	push   %esi
801043e9:	e8 3a d3 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
801043ee:	89 1c 24             	mov    %ebx,(%esp)
801043f1:	e8 8b d1 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
801043f6:	83 c4 10             	add    $0x10,%esp
801043f9:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
801043fe:	75 11                	jne    80104411 <create+0x78>
80104400:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
80104405:	75 0a                	jne    80104411 <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
80104407:	89 d8                	mov    %ebx,%eax
80104409:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010440c:	5b                   	pop    %ebx
8010440d:	5e                   	pop    %esi
8010440e:	5f                   	pop    %edi
8010440f:	5d                   	pop    %ebp
80104410:	c3                   	ret    
    iunlockput(ip);
80104411:	83 ec 0c             	sub    $0xc,%esp
80104414:	53                   	push   %ebx
80104415:	e8 0e d3 ff ff       	call   80101728 <iunlockput>
    return 0;
8010441a:	83 c4 10             	add    $0x10,%esp
8010441d:	bb 00 00 00 00       	mov    $0x0,%ebx
80104422:	eb e3                	jmp    80104407 <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
80104424:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
80104428:	83 ec 08             	sub    $0x8,%esp
8010442b:	50                   	push   %eax
8010442c:	ff 36                	pushl  (%esi)
8010442e:	e8 4b cf ff ff       	call   8010137e <ialloc>
80104433:	89 c3                	mov    %eax,%ebx
80104435:	83 c4 10             	add    $0x10,%esp
80104438:	85 c0                	test   %eax,%eax
8010443a:	74 55                	je     80104491 <create+0xf8>
  ilock(ip);
8010443c:	83 ec 0c             	sub    $0xc,%esp
8010443f:	50                   	push   %eax
80104440:	e8 3c d1 ff ff       	call   80101581 <ilock>
  ip->major = major;
80104445:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
80104449:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
8010444d:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
80104451:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
80104457:	89 1c 24             	mov    %ebx,(%esp)
8010445a:	e8 c1 cf ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
8010445f:	83 c4 10             	add    $0x10,%esp
80104462:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
80104467:	74 35                	je     8010449e <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
80104469:	83 ec 04             	sub    $0x4,%esp
8010446c:	ff 73 04             	pushl  0x4(%ebx)
8010446f:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104472:	50                   	push   %eax
80104473:	56                   	push   %esi
80104474:	e8 b7 d6 ff ff       	call   80101b30 <dirlink>
80104479:	83 c4 10             	add    $0x10,%esp
8010447c:	85 c0                	test   %eax,%eax
8010447e:	78 6f                	js     801044ef <create+0x156>
  iunlockput(dp);
80104480:	83 ec 0c             	sub    $0xc,%esp
80104483:	56                   	push   %esi
80104484:	e8 9f d2 ff ff       	call   80101728 <iunlockput>
  return ip;
80104489:	83 c4 10             	add    $0x10,%esp
8010448c:	e9 76 ff ff ff       	jmp    80104407 <create+0x6e>
    panic("create: ialloc");
80104491:	83 ec 0c             	sub    $0xc,%esp
80104494:	68 0e 6f 10 80       	push   $0x80106f0e
80104499:	e8 aa be ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
8010449e:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801044a2:	83 c0 01             	add    $0x1,%eax
801044a5:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801044a9:	83 ec 0c             	sub    $0xc,%esp
801044ac:	56                   	push   %esi
801044ad:	e8 6e cf ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
801044b2:	83 c4 0c             	add    $0xc,%esp
801044b5:	ff 73 04             	pushl  0x4(%ebx)
801044b8:	68 1e 6f 10 80       	push   $0x80106f1e
801044bd:	53                   	push   %ebx
801044be:	e8 6d d6 ff ff       	call   80101b30 <dirlink>
801044c3:	83 c4 10             	add    $0x10,%esp
801044c6:	85 c0                	test   %eax,%eax
801044c8:	78 18                	js     801044e2 <create+0x149>
801044ca:	83 ec 04             	sub    $0x4,%esp
801044cd:	ff 76 04             	pushl  0x4(%esi)
801044d0:	68 1d 6f 10 80       	push   $0x80106f1d
801044d5:	53                   	push   %ebx
801044d6:	e8 55 d6 ff ff       	call   80101b30 <dirlink>
801044db:	83 c4 10             	add    $0x10,%esp
801044de:	85 c0                	test   %eax,%eax
801044e0:	79 87                	jns    80104469 <create+0xd0>
      panic("create dots");
801044e2:	83 ec 0c             	sub    $0xc,%esp
801044e5:	68 20 6f 10 80       	push   $0x80106f20
801044ea:	e8 59 be ff ff       	call   80100348 <panic>
    panic("create: dirlink");
801044ef:	83 ec 0c             	sub    $0xc,%esp
801044f2:	68 2c 6f 10 80       	push   $0x80106f2c
801044f7:	e8 4c be ff ff       	call   80100348 <panic>
    return 0;
801044fc:	89 c3                	mov    %eax,%ebx
801044fe:	e9 04 ff ff ff       	jmp    80104407 <create+0x6e>

80104503 <sys_dup>:
{
80104503:	55                   	push   %ebp
80104504:	89 e5                	mov    %esp,%ebp
80104506:	53                   	push   %ebx
80104507:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
8010450a:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010450d:	ba 00 00 00 00       	mov    $0x0,%edx
80104512:	b8 00 00 00 00       	mov    $0x0,%eax
80104517:	e8 88 fd ff ff       	call   801042a4 <argfd>
8010451c:	85 c0                	test   %eax,%eax
8010451e:	78 23                	js     80104543 <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
80104520:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104523:	e8 e3 fd ff ff       	call   8010430b <fdalloc>
80104528:	89 c3                	mov    %eax,%ebx
8010452a:	85 c0                	test   %eax,%eax
8010452c:	78 1c                	js     8010454a <sys_dup+0x47>
  filedup(f);
8010452e:	83 ec 0c             	sub    $0xc,%esp
80104531:	ff 75 f4             	pushl  -0xc(%ebp)
80104534:	e8 55 c7 ff ff       	call   80100c8e <filedup>
  return fd;
80104539:	83 c4 10             	add    $0x10,%esp
}
8010453c:	89 d8                	mov    %ebx,%eax
8010453e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104541:	c9                   	leave  
80104542:	c3                   	ret    
    return -1;
80104543:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104548:	eb f2                	jmp    8010453c <sys_dup+0x39>
    return -1;
8010454a:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010454f:	eb eb                	jmp    8010453c <sys_dup+0x39>

80104551 <sys_read>:
{
80104551:	55                   	push   %ebp
80104552:	89 e5                	mov    %esp,%ebp
80104554:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104557:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010455a:	ba 00 00 00 00       	mov    $0x0,%edx
8010455f:	b8 00 00 00 00       	mov    $0x0,%eax
80104564:	e8 3b fd ff ff       	call   801042a4 <argfd>
80104569:	85 c0                	test   %eax,%eax
8010456b:	78 43                	js     801045b0 <sys_read+0x5f>
8010456d:	83 ec 08             	sub    $0x8,%esp
80104570:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104573:	50                   	push   %eax
80104574:	6a 02                	push   $0x2
80104576:	e8 11 fc ff ff       	call   8010418c <argint>
8010457b:	83 c4 10             	add    $0x10,%esp
8010457e:	85 c0                	test   %eax,%eax
80104580:	78 35                	js     801045b7 <sys_read+0x66>
80104582:	83 ec 04             	sub    $0x4,%esp
80104585:	ff 75 f0             	pushl  -0x10(%ebp)
80104588:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010458b:	50                   	push   %eax
8010458c:	6a 01                	push   $0x1
8010458e:	e8 21 fc ff ff       	call   801041b4 <argptr>
80104593:	83 c4 10             	add    $0x10,%esp
80104596:	85 c0                	test   %eax,%eax
80104598:	78 24                	js     801045be <sys_read+0x6d>
  return fileread(f, p, n);
8010459a:	83 ec 04             	sub    $0x4,%esp
8010459d:	ff 75 f0             	pushl  -0x10(%ebp)
801045a0:	ff 75 ec             	pushl  -0x14(%ebp)
801045a3:	ff 75 f4             	pushl  -0xc(%ebp)
801045a6:	e8 2c c8 ff ff       	call   80100dd7 <fileread>
801045ab:	83 c4 10             	add    $0x10,%esp
}
801045ae:	c9                   	leave  
801045af:	c3                   	ret    
    return -1;
801045b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045b5:	eb f7                	jmp    801045ae <sys_read+0x5d>
801045b7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045bc:	eb f0                	jmp    801045ae <sys_read+0x5d>
801045be:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045c3:	eb e9                	jmp    801045ae <sys_read+0x5d>

801045c5 <sys_write>:
{
801045c5:	55                   	push   %ebp
801045c6:	89 e5                	mov    %esp,%ebp
801045c8:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801045cb:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801045ce:	ba 00 00 00 00       	mov    $0x0,%edx
801045d3:	b8 00 00 00 00       	mov    $0x0,%eax
801045d8:	e8 c7 fc ff ff       	call   801042a4 <argfd>
801045dd:	85 c0                	test   %eax,%eax
801045df:	78 43                	js     80104624 <sys_write+0x5f>
801045e1:	83 ec 08             	sub    $0x8,%esp
801045e4:	8d 45 f0             	lea    -0x10(%ebp),%eax
801045e7:	50                   	push   %eax
801045e8:	6a 02                	push   $0x2
801045ea:	e8 9d fb ff ff       	call   8010418c <argint>
801045ef:	83 c4 10             	add    $0x10,%esp
801045f2:	85 c0                	test   %eax,%eax
801045f4:	78 35                	js     8010462b <sys_write+0x66>
801045f6:	83 ec 04             	sub    $0x4,%esp
801045f9:	ff 75 f0             	pushl  -0x10(%ebp)
801045fc:	8d 45 ec             	lea    -0x14(%ebp),%eax
801045ff:	50                   	push   %eax
80104600:	6a 01                	push   $0x1
80104602:	e8 ad fb ff ff       	call   801041b4 <argptr>
80104607:	83 c4 10             	add    $0x10,%esp
8010460a:	85 c0                	test   %eax,%eax
8010460c:	78 24                	js     80104632 <sys_write+0x6d>
  return filewrite(f, p, n);
8010460e:	83 ec 04             	sub    $0x4,%esp
80104611:	ff 75 f0             	pushl  -0x10(%ebp)
80104614:	ff 75 ec             	pushl  -0x14(%ebp)
80104617:	ff 75 f4             	pushl  -0xc(%ebp)
8010461a:	e8 3d c8 ff ff       	call   80100e5c <filewrite>
8010461f:	83 c4 10             	add    $0x10,%esp
}
80104622:	c9                   	leave  
80104623:	c3                   	ret    
    return -1;
80104624:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104629:	eb f7                	jmp    80104622 <sys_write+0x5d>
8010462b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104630:	eb f0                	jmp    80104622 <sys_write+0x5d>
80104632:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104637:	eb e9                	jmp    80104622 <sys_write+0x5d>

80104639 <sys_close>:
{
80104639:	55                   	push   %ebp
8010463a:	89 e5                	mov    %esp,%ebp
8010463c:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
8010463f:	8d 4d f0             	lea    -0x10(%ebp),%ecx
80104642:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104645:	b8 00 00 00 00       	mov    $0x0,%eax
8010464a:	e8 55 fc ff ff       	call   801042a4 <argfd>
8010464f:	85 c0                	test   %eax,%eax
80104651:	78 25                	js     80104678 <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
80104653:	e8 9b ee ff ff       	call   801034f3 <myproc>
80104658:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010465b:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
80104662:	00 
  fileclose(f);
80104663:	83 ec 0c             	sub    $0xc,%esp
80104666:	ff 75 f0             	pushl  -0x10(%ebp)
80104669:	e8 65 c6 ff ff       	call   80100cd3 <fileclose>
  return 0;
8010466e:	83 c4 10             	add    $0x10,%esp
80104671:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104676:	c9                   	leave  
80104677:	c3                   	ret    
    return -1;
80104678:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010467d:	eb f7                	jmp    80104676 <sys_close+0x3d>

8010467f <sys_fstat>:
{
8010467f:	55                   	push   %ebp
80104680:	89 e5                	mov    %esp,%ebp
80104682:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80104685:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104688:	ba 00 00 00 00       	mov    $0x0,%edx
8010468d:	b8 00 00 00 00       	mov    $0x0,%eax
80104692:	e8 0d fc ff ff       	call   801042a4 <argfd>
80104697:	85 c0                	test   %eax,%eax
80104699:	78 2a                	js     801046c5 <sys_fstat+0x46>
8010469b:	83 ec 04             	sub    $0x4,%esp
8010469e:	6a 14                	push   $0x14
801046a0:	8d 45 f0             	lea    -0x10(%ebp),%eax
801046a3:	50                   	push   %eax
801046a4:	6a 01                	push   $0x1
801046a6:	e8 09 fb ff ff       	call   801041b4 <argptr>
801046ab:	83 c4 10             	add    $0x10,%esp
801046ae:	85 c0                	test   %eax,%eax
801046b0:	78 1a                	js     801046cc <sys_fstat+0x4d>
  return filestat(f, st);
801046b2:	83 ec 08             	sub    $0x8,%esp
801046b5:	ff 75 f0             	pushl  -0x10(%ebp)
801046b8:	ff 75 f4             	pushl  -0xc(%ebp)
801046bb:	e8 d0 c6 ff ff       	call   80100d90 <filestat>
801046c0:	83 c4 10             	add    $0x10,%esp
}
801046c3:	c9                   	leave  
801046c4:	c3                   	ret    
    return -1;
801046c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046ca:	eb f7                	jmp    801046c3 <sys_fstat+0x44>
801046cc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046d1:	eb f0                	jmp    801046c3 <sys_fstat+0x44>

801046d3 <sys_link>:
{
801046d3:	55                   	push   %ebp
801046d4:	89 e5                	mov    %esp,%ebp
801046d6:	56                   	push   %esi
801046d7:	53                   	push   %ebx
801046d8:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801046db:	8d 45 e0             	lea    -0x20(%ebp),%eax
801046de:	50                   	push   %eax
801046df:	6a 00                	push   $0x0
801046e1:	e8 36 fb ff ff       	call   8010421c <argstr>
801046e6:	83 c4 10             	add    $0x10,%esp
801046e9:	85 c0                	test   %eax,%eax
801046eb:	0f 88 32 01 00 00    	js     80104823 <sys_link+0x150>
801046f1:	83 ec 08             	sub    $0x8,%esp
801046f4:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801046f7:	50                   	push   %eax
801046f8:	6a 01                	push   $0x1
801046fa:	e8 1d fb ff ff       	call   8010421c <argstr>
801046ff:	83 c4 10             	add    $0x10,%esp
80104702:	85 c0                	test   %eax,%eax
80104704:	0f 88 20 01 00 00    	js     8010482a <sys_link+0x157>
  begin_op();
8010470a:	e8 94 e3 ff ff       	call   80102aa3 <begin_op>
  if((ip = namei(old)) == 0){
8010470f:	83 ec 0c             	sub    $0xc,%esp
80104712:	ff 75 e0             	pushl  -0x20(%ebp)
80104715:	e8 c7 d4 ff ff       	call   80101be1 <namei>
8010471a:	89 c3                	mov    %eax,%ebx
8010471c:	83 c4 10             	add    $0x10,%esp
8010471f:	85 c0                	test   %eax,%eax
80104721:	0f 84 99 00 00 00    	je     801047c0 <sys_link+0xed>
  ilock(ip);
80104727:	83 ec 0c             	sub    $0xc,%esp
8010472a:	50                   	push   %eax
8010472b:	e8 51 ce ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
80104730:	83 c4 10             	add    $0x10,%esp
80104733:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104738:	0f 84 8e 00 00 00    	je     801047cc <sys_link+0xf9>
  ip->nlink++;
8010473e:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104742:	83 c0 01             	add    $0x1,%eax
80104745:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104749:	83 ec 0c             	sub    $0xc,%esp
8010474c:	53                   	push   %ebx
8010474d:	e8 ce cc ff ff       	call   80101420 <iupdate>
  iunlock(ip);
80104752:	89 1c 24             	mov    %ebx,(%esp)
80104755:	e8 e9 ce ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
8010475a:	83 c4 08             	add    $0x8,%esp
8010475d:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104760:	50                   	push   %eax
80104761:	ff 75 e4             	pushl  -0x1c(%ebp)
80104764:	e8 90 d4 ff ff       	call   80101bf9 <nameiparent>
80104769:	89 c6                	mov    %eax,%esi
8010476b:	83 c4 10             	add    $0x10,%esp
8010476e:	85 c0                	test   %eax,%eax
80104770:	74 7e                	je     801047f0 <sys_link+0x11d>
  ilock(dp);
80104772:	83 ec 0c             	sub    $0xc,%esp
80104775:	50                   	push   %eax
80104776:	e8 06 ce ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
8010477b:	83 c4 10             	add    $0x10,%esp
8010477e:	8b 03                	mov    (%ebx),%eax
80104780:	39 06                	cmp    %eax,(%esi)
80104782:	75 60                	jne    801047e4 <sys_link+0x111>
80104784:	83 ec 04             	sub    $0x4,%esp
80104787:	ff 73 04             	pushl  0x4(%ebx)
8010478a:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010478d:	50                   	push   %eax
8010478e:	56                   	push   %esi
8010478f:	e8 9c d3 ff ff       	call   80101b30 <dirlink>
80104794:	83 c4 10             	add    $0x10,%esp
80104797:	85 c0                	test   %eax,%eax
80104799:	78 49                	js     801047e4 <sys_link+0x111>
  iunlockput(dp);
8010479b:	83 ec 0c             	sub    $0xc,%esp
8010479e:	56                   	push   %esi
8010479f:	e8 84 cf ff ff       	call   80101728 <iunlockput>
  iput(ip);
801047a4:	89 1c 24             	mov    %ebx,(%esp)
801047a7:	e8 dc ce ff ff       	call   80101688 <iput>
  end_op();
801047ac:	e8 6c e3 ff ff       	call   80102b1d <end_op>
  return 0;
801047b1:	83 c4 10             	add    $0x10,%esp
801047b4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801047b9:	8d 65 f8             	lea    -0x8(%ebp),%esp
801047bc:	5b                   	pop    %ebx
801047bd:	5e                   	pop    %esi
801047be:	5d                   	pop    %ebp
801047bf:	c3                   	ret    
    end_op();
801047c0:	e8 58 e3 ff ff       	call   80102b1d <end_op>
    return -1;
801047c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047ca:	eb ed                	jmp    801047b9 <sys_link+0xe6>
    iunlockput(ip);
801047cc:	83 ec 0c             	sub    $0xc,%esp
801047cf:	53                   	push   %ebx
801047d0:	e8 53 cf ff ff       	call   80101728 <iunlockput>
    end_op();
801047d5:	e8 43 e3 ff ff       	call   80102b1d <end_op>
    return -1;
801047da:	83 c4 10             	add    $0x10,%esp
801047dd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047e2:	eb d5                	jmp    801047b9 <sys_link+0xe6>
    iunlockput(dp);
801047e4:	83 ec 0c             	sub    $0xc,%esp
801047e7:	56                   	push   %esi
801047e8:	e8 3b cf ff ff       	call   80101728 <iunlockput>
    goto bad;
801047ed:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
801047f0:	83 ec 0c             	sub    $0xc,%esp
801047f3:	53                   	push   %ebx
801047f4:	e8 88 cd ff ff       	call   80101581 <ilock>
  ip->nlink--;
801047f9:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801047fd:	83 e8 01             	sub    $0x1,%eax
80104800:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104804:	89 1c 24             	mov    %ebx,(%esp)
80104807:	e8 14 cc ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
8010480c:	89 1c 24             	mov    %ebx,(%esp)
8010480f:	e8 14 cf ff ff       	call   80101728 <iunlockput>
  end_op();
80104814:	e8 04 e3 ff ff       	call   80102b1d <end_op>
  return -1;
80104819:	83 c4 10             	add    $0x10,%esp
8010481c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104821:	eb 96                	jmp    801047b9 <sys_link+0xe6>
    return -1;
80104823:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104828:	eb 8f                	jmp    801047b9 <sys_link+0xe6>
8010482a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010482f:	eb 88                	jmp    801047b9 <sys_link+0xe6>

80104831 <sys_unlink>:
{
80104831:	55                   	push   %ebp
80104832:	89 e5                	mov    %esp,%ebp
80104834:	57                   	push   %edi
80104835:	56                   	push   %esi
80104836:	53                   	push   %ebx
80104837:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
8010483a:	8d 45 c4             	lea    -0x3c(%ebp),%eax
8010483d:	50                   	push   %eax
8010483e:	6a 00                	push   $0x0
80104840:	e8 d7 f9 ff ff       	call   8010421c <argstr>
80104845:	83 c4 10             	add    $0x10,%esp
80104848:	85 c0                	test   %eax,%eax
8010484a:	0f 88 83 01 00 00    	js     801049d3 <sys_unlink+0x1a2>
  begin_op();
80104850:	e8 4e e2 ff ff       	call   80102aa3 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80104855:	83 ec 08             	sub    $0x8,%esp
80104858:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010485b:	50                   	push   %eax
8010485c:	ff 75 c4             	pushl  -0x3c(%ebp)
8010485f:	e8 95 d3 ff ff       	call   80101bf9 <nameiparent>
80104864:	89 c6                	mov    %eax,%esi
80104866:	83 c4 10             	add    $0x10,%esp
80104869:	85 c0                	test   %eax,%eax
8010486b:	0f 84 ed 00 00 00    	je     8010495e <sys_unlink+0x12d>
  ilock(dp);
80104871:	83 ec 0c             	sub    $0xc,%esp
80104874:	50                   	push   %eax
80104875:	e8 07 cd ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
8010487a:	83 c4 08             	add    $0x8,%esp
8010487d:	68 1e 6f 10 80       	push   $0x80106f1e
80104882:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104885:	50                   	push   %eax
80104886:	e8 10 d1 ff ff       	call   8010199b <namecmp>
8010488b:	83 c4 10             	add    $0x10,%esp
8010488e:	85 c0                	test   %eax,%eax
80104890:	0f 84 fc 00 00 00    	je     80104992 <sys_unlink+0x161>
80104896:	83 ec 08             	sub    $0x8,%esp
80104899:	68 1d 6f 10 80       	push   $0x80106f1d
8010489e:	8d 45 ca             	lea    -0x36(%ebp),%eax
801048a1:	50                   	push   %eax
801048a2:	e8 f4 d0 ff ff       	call   8010199b <namecmp>
801048a7:	83 c4 10             	add    $0x10,%esp
801048aa:	85 c0                	test   %eax,%eax
801048ac:	0f 84 e0 00 00 00    	je     80104992 <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
801048b2:	83 ec 04             	sub    $0x4,%esp
801048b5:	8d 45 c0             	lea    -0x40(%ebp),%eax
801048b8:	50                   	push   %eax
801048b9:	8d 45 ca             	lea    -0x36(%ebp),%eax
801048bc:	50                   	push   %eax
801048bd:	56                   	push   %esi
801048be:	e8 ed d0 ff ff       	call   801019b0 <dirlookup>
801048c3:	89 c3                	mov    %eax,%ebx
801048c5:	83 c4 10             	add    $0x10,%esp
801048c8:	85 c0                	test   %eax,%eax
801048ca:	0f 84 c2 00 00 00    	je     80104992 <sys_unlink+0x161>
  ilock(ip);
801048d0:	83 ec 0c             	sub    $0xc,%esp
801048d3:	50                   	push   %eax
801048d4:	e8 a8 cc ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
801048d9:	83 c4 10             	add    $0x10,%esp
801048dc:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801048e1:	0f 8e 83 00 00 00    	jle    8010496a <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
801048e7:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801048ec:	0f 84 85 00 00 00    	je     80104977 <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
801048f2:	83 ec 04             	sub    $0x4,%esp
801048f5:	6a 10                	push   $0x10
801048f7:	6a 00                	push   $0x0
801048f9:	8d 7d d8             	lea    -0x28(%ebp),%edi
801048fc:	57                   	push   %edi
801048fd:	e8 3f f6 ff ff       	call   80103f41 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104902:	6a 10                	push   $0x10
80104904:	ff 75 c0             	pushl  -0x40(%ebp)
80104907:	57                   	push   %edi
80104908:	56                   	push   %esi
80104909:	e8 62 cf ff ff       	call   80101870 <writei>
8010490e:	83 c4 20             	add    $0x20,%esp
80104911:	83 f8 10             	cmp    $0x10,%eax
80104914:	0f 85 90 00 00 00    	jne    801049aa <sys_unlink+0x179>
  if(ip->type == T_DIR){
8010491a:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010491f:	0f 84 92 00 00 00    	je     801049b7 <sys_unlink+0x186>
  iunlockput(dp);
80104925:	83 ec 0c             	sub    $0xc,%esp
80104928:	56                   	push   %esi
80104929:	e8 fa cd ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
8010492e:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104932:	83 e8 01             	sub    $0x1,%eax
80104935:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104939:	89 1c 24             	mov    %ebx,(%esp)
8010493c:	e8 df ca ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104941:	89 1c 24             	mov    %ebx,(%esp)
80104944:	e8 df cd ff ff       	call   80101728 <iunlockput>
  end_op();
80104949:	e8 cf e1 ff ff       	call   80102b1d <end_op>
  return 0;
8010494e:	83 c4 10             	add    $0x10,%esp
80104951:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104956:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104959:	5b                   	pop    %ebx
8010495a:	5e                   	pop    %esi
8010495b:	5f                   	pop    %edi
8010495c:	5d                   	pop    %ebp
8010495d:	c3                   	ret    
    end_op();
8010495e:	e8 ba e1 ff ff       	call   80102b1d <end_op>
    return -1;
80104963:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104968:	eb ec                	jmp    80104956 <sys_unlink+0x125>
    panic("unlink: nlink < 1");
8010496a:	83 ec 0c             	sub    $0xc,%esp
8010496d:	68 3c 6f 10 80       	push   $0x80106f3c
80104972:	e8 d1 b9 ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104977:	89 d8                	mov    %ebx,%eax
80104979:	e8 c4 f9 ff ff       	call   80104342 <isdirempty>
8010497e:	85 c0                	test   %eax,%eax
80104980:	0f 85 6c ff ff ff    	jne    801048f2 <sys_unlink+0xc1>
    iunlockput(ip);
80104986:	83 ec 0c             	sub    $0xc,%esp
80104989:	53                   	push   %ebx
8010498a:	e8 99 cd ff ff       	call   80101728 <iunlockput>
    goto bad;
8010498f:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
80104992:	83 ec 0c             	sub    $0xc,%esp
80104995:	56                   	push   %esi
80104996:	e8 8d cd ff ff       	call   80101728 <iunlockput>
  end_op();
8010499b:	e8 7d e1 ff ff       	call   80102b1d <end_op>
  return -1;
801049a0:	83 c4 10             	add    $0x10,%esp
801049a3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049a8:	eb ac                	jmp    80104956 <sys_unlink+0x125>
    panic("unlink: writei");
801049aa:	83 ec 0c             	sub    $0xc,%esp
801049ad:	68 4e 6f 10 80       	push   $0x80106f4e
801049b2:	e8 91 b9 ff ff       	call   80100348 <panic>
    dp->nlink--;
801049b7:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801049bb:	83 e8 01             	sub    $0x1,%eax
801049be:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801049c2:	83 ec 0c             	sub    $0xc,%esp
801049c5:	56                   	push   %esi
801049c6:	e8 55 ca ff ff       	call   80101420 <iupdate>
801049cb:	83 c4 10             	add    $0x10,%esp
801049ce:	e9 52 ff ff ff       	jmp    80104925 <sys_unlink+0xf4>
    return -1;
801049d3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049d8:	e9 79 ff ff ff       	jmp    80104956 <sys_unlink+0x125>

801049dd <sys_open>:

int
sys_open(void)
{
801049dd:	55                   	push   %ebp
801049de:	89 e5                	mov    %esp,%ebp
801049e0:	57                   	push   %edi
801049e1:	56                   	push   %esi
801049e2:	53                   	push   %ebx
801049e3:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801049e6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801049e9:	50                   	push   %eax
801049ea:	6a 00                	push   $0x0
801049ec:	e8 2b f8 ff ff       	call   8010421c <argstr>
801049f1:	83 c4 10             	add    $0x10,%esp
801049f4:	85 c0                	test   %eax,%eax
801049f6:	0f 88 30 01 00 00    	js     80104b2c <sys_open+0x14f>
801049fc:	83 ec 08             	sub    $0x8,%esp
801049ff:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104a02:	50                   	push   %eax
80104a03:	6a 01                	push   $0x1
80104a05:	e8 82 f7 ff ff       	call   8010418c <argint>
80104a0a:	83 c4 10             	add    $0x10,%esp
80104a0d:	85 c0                	test   %eax,%eax
80104a0f:	0f 88 21 01 00 00    	js     80104b36 <sys_open+0x159>
    return -1;

  begin_op();
80104a15:	e8 89 e0 ff ff       	call   80102aa3 <begin_op>

  if(omode & O_CREATE){
80104a1a:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
80104a1e:	0f 84 84 00 00 00    	je     80104aa8 <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
80104a24:	83 ec 0c             	sub    $0xc,%esp
80104a27:	6a 00                	push   $0x0
80104a29:	b9 00 00 00 00       	mov    $0x0,%ecx
80104a2e:	ba 02 00 00 00       	mov    $0x2,%edx
80104a33:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104a36:	e8 5e f9 ff ff       	call   80104399 <create>
80104a3b:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104a3d:	83 c4 10             	add    $0x10,%esp
80104a40:	85 c0                	test   %eax,%eax
80104a42:	74 58                	je     80104a9c <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80104a44:	e8 e4 c1 ff ff       	call   80100c2d <filealloc>
80104a49:	89 c3                	mov    %eax,%ebx
80104a4b:	85 c0                	test   %eax,%eax
80104a4d:	0f 84 ae 00 00 00    	je     80104b01 <sys_open+0x124>
80104a53:	e8 b3 f8 ff ff       	call   8010430b <fdalloc>
80104a58:	89 c7                	mov    %eax,%edi
80104a5a:	85 c0                	test   %eax,%eax
80104a5c:	0f 88 9f 00 00 00    	js     80104b01 <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104a62:	83 ec 0c             	sub    $0xc,%esp
80104a65:	56                   	push   %esi
80104a66:	e8 d8 cb ff ff       	call   80101643 <iunlock>
  end_op();
80104a6b:	e8 ad e0 ff ff       	call   80102b1d <end_op>

  f->type = FD_INODE;
80104a70:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
80104a76:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104a79:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
80104a80:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104a83:	83 c4 10             	add    $0x10,%esp
80104a86:	a8 01                	test   $0x1,%al
80104a88:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80104a8c:	a8 03                	test   $0x3,%al
80104a8e:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
80104a92:	89 f8                	mov    %edi,%eax
80104a94:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104a97:	5b                   	pop    %ebx
80104a98:	5e                   	pop    %esi
80104a99:	5f                   	pop    %edi
80104a9a:	5d                   	pop    %ebp
80104a9b:	c3                   	ret    
      end_op();
80104a9c:	e8 7c e0 ff ff       	call   80102b1d <end_op>
      return -1;
80104aa1:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104aa6:	eb ea                	jmp    80104a92 <sys_open+0xb5>
    if((ip = namei(path)) == 0){
80104aa8:	83 ec 0c             	sub    $0xc,%esp
80104aab:	ff 75 e4             	pushl  -0x1c(%ebp)
80104aae:	e8 2e d1 ff ff       	call   80101be1 <namei>
80104ab3:	89 c6                	mov    %eax,%esi
80104ab5:	83 c4 10             	add    $0x10,%esp
80104ab8:	85 c0                	test   %eax,%eax
80104aba:	74 39                	je     80104af5 <sys_open+0x118>
    ilock(ip);
80104abc:	83 ec 0c             	sub    $0xc,%esp
80104abf:	50                   	push   %eax
80104ac0:	e8 bc ca ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80104ac5:	83 c4 10             	add    $0x10,%esp
80104ac8:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104acd:	0f 85 71 ff ff ff    	jne    80104a44 <sys_open+0x67>
80104ad3:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104ad7:	0f 84 67 ff ff ff    	je     80104a44 <sys_open+0x67>
      iunlockput(ip);
80104add:	83 ec 0c             	sub    $0xc,%esp
80104ae0:	56                   	push   %esi
80104ae1:	e8 42 cc ff ff       	call   80101728 <iunlockput>
      end_op();
80104ae6:	e8 32 e0 ff ff       	call   80102b1d <end_op>
      return -1;
80104aeb:	83 c4 10             	add    $0x10,%esp
80104aee:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104af3:	eb 9d                	jmp    80104a92 <sys_open+0xb5>
      end_op();
80104af5:	e8 23 e0 ff ff       	call   80102b1d <end_op>
      return -1;
80104afa:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104aff:	eb 91                	jmp    80104a92 <sys_open+0xb5>
    if(f)
80104b01:	85 db                	test   %ebx,%ebx
80104b03:	74 0c                	je     80104b11 <sys_open+0x134>
      fileclose(f);
80104b05:	83 ec 0c             	sub    $0xc,%esp
80104b08:	53                   	push   %ebx
80104b09:	e8 c5 c1 ff ff       	call   80100cd3 <fileclose>
80104b0e:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104b11:	83 ec 0c             	sub    $0xc,%esp
80104b14:	56                   	push   %esi
80104b15:	e8 0e cc ff ff       	call   80101728 <iunlockput>
    end_op();
80104b1a:	e8 fe df ff ff       	call   80102b1d <end_op>
    return -1;
80104b1f:	83 c4 10             	add    $0x10,%esp
80104b22:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104b27:	e9 66 ff ff ff       	jmp    80104a92 <sys_open+0xb5>
    return -1;
80104b2c:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104b31:	e9 5c ff ff ff       	jmp    80104a92 <sys_open+0xb5>
80104b36:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104b3b:	e9 52 ff ff ff       	jmp    80104a92 <sys_open+0xb5>

80104b40 <sys_mkdir>:

int
sys_mkdir(void)
{
80104b40:	55                   	push   %ebp
80104b41:	89 e5                	mov    %esp,%ebp
80104b43:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104b46:	e8 58 df ff ff       	call   80102aa3 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104b4b:	83 ec 08             	sub    $0x8,%esp
80104b4e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b51:	50                   	push   %eax
80104b52:	6a 00                	push   $0x0
80104b54:	e8 c3 f6 ff ff       	call   8010421c <argstr>
80104b59:	83 c4 10             	add    $0x10,%esp
80104b5c:	85 c0                	test   %eax,%eax
80104b5e:	78 36                	js     80104b96 <sys_mkdir+0x56>
80104b60:	83 ec 0c             	sub    $0xc,%esp
80104b63:	6a 00                	push   $0x0
80104b65:	b9 00 00 00 00       	mov    $0x0,%ecx
80104b6a:	ba 01 00 00 00       	mov    $0x1,%edx
80104b6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b72:	e8 22 f8 ff ff       	call   80104399 <create>
80104b77:	83 c4 10             	add    $0x10,%esp
80104b7a:	85 c0                	test   %eax,%eax
80104b7c:	74 18                	je     80104b96 <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104b7e:	83 ec 0c             	sub    $0xc,%esp
80104b81:	50                   	push   %eax
80104b82:	e8 a1 cb ff ff       	call   80101728 <iunlockput>
  end_op();
80104b87:	e8 91 df ff ff       	call   80102b1d <end_op>
  return 0;
80104b8c:	83 c4 10             	add    $0x10,%esp
80104b8f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104b94:	c9                   	leave  
80104b95:	c3                   	ret    
    end_op();
80104b96:	e8 82 df ff ff       	call   80102b1d <end_op>
    return -1;
80104b9b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ba0:	eb f2                	jmp    80104b94 <sys_mkdir+0x54>

80104ba2 <sys_mknod>:

int
sys_mknod(void)
{
80104ba2:	55                   	push   %ebp
80104ba3:	89 e5                	mov    %esp,%ebp
80104ba5:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104ba8:	e8 f6 de ff ff       	call   80102aa3 <begin_op>
  if((argstr(0, &path)) < 0 ||
80104bad:	83 ec 08             	sub    $0x8,%esp
80104bb0:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104bb3:	50                   	push   %eax
80104bb4:	6a 00                	push   $0x0
80104bb6:	e8 61 f6 ff ff       	call   8010421c <argstr>
80104bbb:	83 c4 10             	add    $0x10,%esp
80104bbe:	85 c0                	test   %eax,%eax
80104bc0:	78 62                	js     80104c24 <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104bc2:	83 ec 08             	sub    $0x8,%esp
80104bc5:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104bc8:	50                   	push   %eax
80104bc9:	6a 01                	push   $0x1
80104bcb:	e8 bc f5 ff ff       	call   8010418c <argint>
  if((argstr(0, &path)) < 0 ||
80104bd0:	83 c4 10             	add    $0x10,%esp
80104bd3:	85 c0                	test   %eax,%eax
80104bd5:	78 4d                	js     80104c24 <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104bd7:	83 ec 08             	sub    $0x8,%esp
80104bda:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104bdd:	50                   	push   %eax
80104bde:	6a 02                	push   $0x2
80104be0:	e8 a7 f5 ff ff       	call   8010418c <argint>
     argint(1, &major) < 0 ||
80104be5:	83 c4 10             	add    $0x10,%esp
80104be8:	85 c0                	test   %eax,%eax
80104bea:	78 38                	js     80104c24 <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104bec:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104bf0:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104bf4:	83 ec 0c             	sub    $0xc,%esp
80104bf7:	50                   	push   %eax
80104bf8:	ba 03 00 00 00       	mov    $0x3,%edx
80104bfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c00:	e8 94 f7 ff ff       	call   80104399 <create>
80104c05:	83 c4 10             	add    $0x10,%esp
80104c08:	85 c0                	test   %eax,%eax
80104c0a:	74 18                	je     80104c24 <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104c0c:	83 ec 0c             	sub    $0xc,%esp
80104c0f:	50                   	push   %eax
80104c10:	e8 13 cb ff ff       	call   80101728 <iunlockput>
  end_op();
80104c15:	e8 03 df ff ff       	call   80102b1d <end_op>
  return 0;
80104c1a:	83 c4 10             	add    $0x10,%esp
80104c1d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104c22:	c9                   	leave  
80104c23:	c3                   	ret    
    end_op();
80104c24:	e8 f4 de ff ff       	call   80102b1d <end_op>
    return -1;
80104c29:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c2e:	eb f2                	jmp    80104c22 <sys_mknod+0x80>

80104c30 <sys_chdir>:

int
sys_chdir(void)
{
80104c30:	55                   	push   %ebp
80104c31:	89 e5                	mov    %esp,%ebp
80104c33:	56                   	push   %esi
80104c34:	53                   	push   %ebx
80104c35:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104c38:	e8 b6 e8 ff ff       	call   801034f3 <myproc>
80104c3d:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104c3f:	e8 5f de ff ff       	call   80102aa3 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104c44:	83 ec 08             	sub    $0x8,%esp
80104c47:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c4a:	50                   	push   %eax
80104c4b:	6a 00                	push   $0x0
80104c4d:	e8 ca f5 ff ff       	call   8010421c <argstr>
80104c52:	83 c4 10             	add    $0x10,%esp
80104c55:	85 c0                	test   %eax,%eax
80104c57:	78 52                	js     80104cab <sys_chdir+0x7b>
80104c59:	83 ec 0c             	sub    $0xc,%esp
80104c5c:	ff 75 f4             	pushl  -0xc(%ebp)
80104c5f:	e8 7d cf ff ff       	call   80101be1 <namei>
80104c64:	89 c3                	mov    %eax,%ebx
80104c66:	83 c4 10             	add    $0x10,%esp
80104c69:	85 c0                	test   %eax,%eax
80104c6b:	74 3e                	je     80104cab <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104c6d:	83 ec 0c             	sub    $0xc,%esp
80104c70:	50                   	push   %eax
80104c71:	e8 0b c9 ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104c76:	83 c4 10             	add    $0x10,%esp
80104c79:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104c7e:	75 37                	jne    80104cb7 <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104c80:	83 ec 0c             	sub    $0xc,%esp
80104c83:	53                   	push   %ebx
80104c84:	e8 ba c9 ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104c89:	83 c4 04             	add    $0x4,%esp
80104c8c:	ff 76 68             	pushl  0x68(%esi)
80104c8f:	e8 f4 c9 ff ff       	call   80101688 <iput>
  end_op();
80104c94:	e8 84 de ff ff       	call   80102b1d <end_op>
  curproc->cwd = ip;
80104c99:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104c9c:	83 c4 10             	add    $0x10,%esp
80104c9f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104ca4:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104ca7:	5b                   	pop    %ebx
80104ca8:	5e                   	pop    %esi
80104ca9:	5d                   	pop    %ebp
80104caa:	c3                   	ret    
    end_op();
80104cab:	e8 6d de ff ff       	call   80102b1d <end_op>
    return -1;
80104cb0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cb5:	eb ed                	jmp    80104ca4 <sys_chdir+0x74>
    iunlockput(ip);
80104cb7:	83 ec 0c             	sub    $0xc,%esp
80104cba:	53                   	push   %ebx
80104cbb:	e8 68 ca ff ff       	call   80101728 <iunlockput>
    end_op();
80104cc0:	e8 58 de ff ff       	call   80102b1d <end_op>
    return -1;
80104cc5:	83 c4 10             	add    $0x10,%esp
80104cc8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ccd:	eb d5                	jmp    80104ca4 <sys_chdir+0x74>

80104ccf <sys_exec>:

int
sys_exec(void)
{
80104ccf:	55                   	push   %ebp
80104cd0:	89 e5                	mov    %esp,%ebp
80104cd2:	53                   	push   %ebx
80104cd3:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104cd9:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104cdc:	50                   	push   %eax
80104cdd:	6a 00                	push   $0x0
80104cdf:	e8 38 f5 ff ff       	call   8010421c <argstr>
80104ce4:	83 c4 10             	add    $0x10,%esp
80104ce7:	85 c0                	test   %eax,%eax
80104ce9:	0f 88 a8 00 00 00    	js     80104d97 <sys_exec+0xc8>
80104cef:	83 ec 08             	sub    $0x8,%esp
80104cf2:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104cf8:	50                   	push   %eax
80104cf9:	6a 01                	push   $0x1
80104cfb:	e8 8c f4 ff ff       	call   8010418c <argint>
80104d00:	83 c4 10             	add    $0x10,%esp
80104d03:	85 c0                	test   %eax,%eax
80104d05:	0f 88 93 00 00 00    	js     80104d9e <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104d0b:	83 ec 04             	sub    $0x4,%esp
80104d0e:	68 80 00 00 00       	push   $0x80
80104d13:	6a 00                	push   $0x0
80104d15:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104d1b:	50                   	push   %eax
80104d1c:	e8 20 f2 ff ff       	call   80103f41 <memset>
80104d21:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104d24:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104d29:	83 fb 1f             	cmp    $0x1f,%ebx
80104d2c:	77 77                	ja     80104da5 <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104d2e:	83 ec 08             	sub    $0x8,%esp
80104d31:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104d37:	50                   	push   %eax
80104d38:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104d3e:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104d41:	50                   	push   %eax
80104d42:	e8 c9 f3 ff ff       	call   80104110 <fetchint>
80104d47:	83 c4 10             	add    $0x10,%esp
80104d4a:	85 c0                	test   %eax,%eax
80104d4c:	78 5e                	js     80104dac <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104d4e:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104d54:	85 c0                	test   %eax,%eax
80104d56:	74 1d                	je     80104d75 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104d58:	83 ec 08             	sub    $0x8,%esp
80104d5b:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104d62:	52                   	push   %edx
80104d63:	50                   	push   %eax
80104d64:	e8 e3 f3 ff ff       	call   8010414c <fetchstr>
80104d69:	83 c4 10             	add    $0x10,%esp
80104d6c:	85 c0                	test   %eax,%eax
80104d6e:	78 46                	js     80104db6 <sys_exec+0xe7>
  for(i=0;; i++){
80104d70:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104d73:	eb b4                	jmp    80104d29 <sys_exec+0x5a>
      argv[i] = 0;
80104d75:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104d7c:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104d80:	83 ec 08             	sub    $0x8,%esp
80104d83:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104d89:	50                   	push   %eax
80104d8a:	ff 75 f4             	pushl  -0xc(%ebp)
80104d8d:	e8 40 bb ff ff       	call   801008d2 <exec>
80104d92:	83 c4 10             	add    $0x10,%esp
80104d95:	eb 1a                	jmp    80104db1 <sys_exec+0xe2>
    return -1;
80104d97:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d9c:	eb 13                	jmp    80104db1 <sys_exec+0xe2>
80104d9e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104da3:	eb 0c                	jmp    80104db1 <sys_exec+0xe2>
      return -1;
80104da5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104daa:	eb 05                	jmp    80104db1 <sys_exec+0xe2>
      return -1;
80104dac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104db1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104db4:	c9                   	leave  
80104db5:	c3                   	ret    
      return -1;
80104db6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dbb:	eb f4                	jmp    80104db1 <sys_exec+0xe2>

80104dbd <sys_pipe>:

int
sys_pipe(void)
{
80104dbd:	55                   	push   %ebp
80104dbe:	89 e5                	mov    %esp,%ebp
80104dc0:	53                   	push   %ebx
80104dc1:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104dc4:	6a 08                	push   $0x8
80104dc6:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104dc9:	50                   	push   %eax
80104dca:	6a 00                	push   $0x0
80104dcc:	e8 e3 f3 ff ff       	call   801041b4 <argptr>
80104dd1:	83 c4 10             	add    $0x10,%esp
80104dd4:	85 c0                	test   %eax,%eax
80104dd6:	78 77                	js     80104e4f <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104dd8:	83 ec 08             	sub    $0x8,%esp
80104ddb:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104dde:	50                   	push   %eax
80104ddf:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104de2:	50                   	push   %eax
80104de3:	e8 42 e2 ff ff       	call   8010302a <pipealloc>
80104de8:	83 c4 10             	add    $0x10,%esp
80104deb:	85 c0                	test   %eax,%eax
80104ded:	78 67                	js     80104e56 <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104def:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104df2:	e8 14 f5 ff ff       	call   8010430b <fdalloc>
80104df7:	89 c3                	mov    %eax,%ebx
80104df9:	85 c0                	test   %eax,%eax
80104dfb:	78 21                	js     80104e1e <sys_pipe+0x61>
80104dfd:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104e00:	e8 06 f5 ff ff       	call   8010430b <fdalloc>
80104e05:	85 c0                	test   %eax,%eax
80104e07:	78 15                	js     80104e1e <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104e09:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e0c:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104e0e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e11:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104e14:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e19:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e1c:	c9                   	leave  
80104e1d:	c3                   	ret    
    if(fd0 >= 0)
80104e1e:	85 db                	test   %ebx,%ebx
80104e20:	78 0d                	js     80104e2f <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104e22:	e8 cc e6 ff ff       	call   801034f3 <myproc>
80104e27:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104e2e:	00 
    fileclose(rf);
80104e2f:	83 ec 0c             	sub    $0xc,%esp
80104e32:	ff 75 f0             	pushl  -0x10(%ebp)
80104e35:	e8 99 be ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104e3a:	83 c4 04             	add    $0x4,%esp
80104e3d:	ff 75 ec             	pushl  -0x14(%ebp)
80104e40:	e8 8e be ff ff       	call   80100cd3 <fileclose>
    return -1;
80104e45:	83 c4 10             	add    $0x10,%esp
80104e48:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e4d:	eb ca                	jmp    80104e19 <sys_pipe+0x5c>
    return -1;
80104e4f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e54:	eb c3                	jmp    80104e19 <sys_pipe+0x5c>
    return -1;
80104e56:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e5b:	eb bc                	jmp    80104e19 <sys_pipe+0x5c>

80104e5d <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104e5d:	55                   	push   %ebp
80104e5e:	89 e5                	mov    %esp,%ebp
80104e60:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104e63:	e8 03 e8 ff ff       	call   8010366b <fork>
}
80104e68:	c9                   	leave  
80104e69:	c3                   	ret    

80104e6a <sys_exit>:

int
sys_exit(void)
{
80104e6a:	55                   	push   %ebp
80104e6b:	89 e5                	mov    %esp,%ebp
80104e6d:	83 ec 08             	sub    $0x8,%esp
  exit();
80104e70:	e8 2d ea ff ff       	call   801038a2 <exit>
  return 0;  // not reached
}
80104e75:	b8 00 00 00 00       	mov    $0x0,%eax
80104e7a:	c9                   	leave  
80104e7b:	c3                   	ret    

80104e7c <sys_wait>:

int
sys_wait(void)
{
80104e7c:	55                   	push   %ebp
80104e7d:	89 e5                	mov    %esp,%ebp
80104e7f:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104e82:	e8 a4 eb ff ff       	call   80103a2b <wait>
}
80104e87:	c9                   	leave  
80104e88:	c3                   	ret    

80104e89 <sys_kill>:

int
sys_kill(void)
{
80104e89:	55                   	push   %ebp
80104e8a:	89 e5                	mov    %esp,%ebp
80104e8c:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104e8f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e92:	50                   	push   %eax
80104e93:	6a 00                	push   $0x0
80104e95:	e8 f2 f2 ff ff       	call   8010418c <argint>
80104e9a:	83 c4 10             	add    $0x10,%esp
80104e9d:	85 c0                	test   %eax,%eax
80104e9f:	78 10                	js     80104eb1 <sys_kill+0x28>
    return -1;
  return kill(pid);
80104ea1:	83 ec 0c             	sub    $0xc,%esp
80104ea4:	ff 75 f4             	pushl  -0xc(%ebp)
80104ea7:	e8 7c ec ff ff       	call   80103b28 <kill>
80104eac:	83 c4 10             	add    $0x10,%esp
}
80104eaf:	c9                   	leave  
80104eb0:	c3                   	ret    
    return -1;
80104eb1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104eb6:	eb f7                	jmp    80104eaf <sys_kill+0x26>

80104eb8 <sys_getpid>:

int
sys_getpid(void)
{
80104eb8:	55                   	push   %ebp
80104eb9:	89 e5                	mov    %esp,%ebp
80104ebb:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104ebe:	e8 30 e6 ff ff       	call   801034f3 <myproc>
80104ec3:	8b 40 10             	mov    0x10(%eax),%eax
}
80104ec6:	c9                   	leave  
80104ec7:	c3                   	ret    

80104ec8 <sys_sbrk>:

int
sys_sbrk(void)
{
80104ec8:	55                   	push   %ebp
80104ec9:	89 e5                	mov    %esp,%ebp
80104ecb:	53                   	push   %ebx
80104ecc:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104ecf:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ed2:	50                   	push   %eax
80104ed3:	6a 00                	push   $0x0
80104ed5:	e8 b2 f2 ff ff       	call   8010418c <argint>
80104eda:	83 c4 10             	add    $0x10,%esp
80104edd:	85 c0                	test   %eax,%eax
80104edf:	78 27                	js     80104f08 <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104ee1:	e8 0d e6 ff ff       	call   801034f3 <myproc>
80104ee6:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104ee8:	83 ec 0c             	sub    $0xc,%esp
80104eeb:	ff 75 f4             	pushl  -0xc(%ebp)
80104eee:	e8 0b e7 ff ff       	call   801035fe <growproc>
80104ef3:	83 c4 10             	add    $0x10,%esp
80104ef6:	85 c0                	test   %eax,%eax
80104ef8:	78 07                	js     80104f01 <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104efa:	89 d8                	mov    %ebx,%eax
80104efc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104eff:	c9                   	leave  
80104f00:	c3                   	ret    
    return -1;
80104f01:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104f06:	eb f2                	jmp    80104efa <sys_sbrk+0x32>
    return -1;
80104f08:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104f0d:	eb eb                	jmp    80104efa <sys_sbrk+0x32>

80104f0f <sys_sleep>:

int
sys_sleep(void)
{
80104f0f:	55                   	push   %ebp
80104f10:	89 e5                	mov    %esp,%ebp
80104f12:	53                   	push   %ebx
80104f13:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104f16:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104f19:	50                   	push   %eax
80104f1a:	6a 00                	push   $0x0
80104f1c:	e8 6b f2 ff ff       	call   8010418c <argint>
80104f21:	83 c4 10             	add    $0x10,%esp
80104f24:	85 c0                	test   %eax,%eax
80104f26:	78 75                	js     80104f9d <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104f28:	83 ec 0c             	sub    $0xc,%esp
80104f2b:	68 a0 4c 13 80       	push   $0x80134ca0
80104f30:	e8 60 ef ff ff       	call   80103e95 <acquire>
  ticks0 = ticks;
80104f35:	8b 1d e0 54 13 80    	mov    0x801354e0,%ebx
  while(ticks - ticks0 < n){
80104f3b:	83 c4 10             	add    $0x10,%esp
80104f3e:	a1 e0 54 13 80       	mov    0x801354e0,%eax
80104f43:	29 d8                	sub    %ebx,%eax
80104f45:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104f48:	73 39                	jae    80104f83 <sys_sleep+0x74>
    if(myproc()->killed){
80104f4a:	e8 a4 e5 ff ff       	call   801034f3 <myproc>
80104f4f:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f53:	75 17                	jne    80104f6c <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104f55:	83 ec 08             	sub    $0x8,%esp
80104f58:	68 a0 4c 13 80       	push   $0x80134ca0
80104f5d:	68 e0 54 13 80       	push   $0x801354e0
80104f62:	e8 33 ea ff ff       	call   8010399a <sleep>
80104f67:	83 c4 10             	add    $0x10,%esp
80104f6a:	eb d2                	jmp    80104f3e <sys_sleep+0x2f>
      release(&tickslock);
80104f6c:	83 ec 0c             	sub    $0xc,%esp
80104f6f:	68 a0 4c 13 80       	push   $0x80134ca0
80104f74:	e8 81 ef ff ff       	call   80103efa <release>
      return -1;
80104f79:	83 c4 10             	add    $0x10,%esp
80104f7c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f81:	eb 15                	jmp    80104f98 <sys_sleep+0x89>
  }
  release(&tickslock);
80104f83:	83 ec 0c             	sub    $0xc,%esp
80104f86:	68 a0 4c 13 80       	push   $0x80134ca0
80104f8b:	e8 6a ef ff ff       	call   80103efa <release>
  return 0;
80104f90:	83 c4 10             	add    $0x10,%esp
80104f93:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104f98:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104f9b:	c9                   	leave  
80104f9c:	c3                   	ret    
    return -1;
80104f9d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fa2:	eb f4                	jmp    80104f98 <sys_sleep+0x89>

80104fa4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104fa4:	55                   	push   %ebp
80104fa5:	89 e5                	mov    %esp,%ebp
80104fa7:	53                   	push   %ebx
80104fa8:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104fab:	68 a0 4c 13 80       	push   $0x80134ca0
80104fb0:	e8 e0 ee ff ff       	call   80103e95 <acquire>
  xticks = ticks;
80104fb5:	8b 1d e0 54 13 80    	mov    0x801354e0,%ebx
  release(&tickslock);
80104fbb:	c7 04 24 a0 4c 13 80 	movl   $0x80134ca0,(%esp)
80104fc2:	e8 33 ef ff ff       	call   80103efa <release>
  return xticks;
}
80104fc7:	89 d8                	mov    %ebx,%eax
80104fc9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104fcc:	c9                   	leave  
80104fcd:	c3                   	ret    

80104fce <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80104fce:	55                   	push   %ebp
80104fcf:	89 e5                	mov    %esp,%ebp
80104fd1:	83 ec 1c             	sub    $0x1c,%esp
  int *frames;
  int *pids;
  int numframes;
  if(argptr(0, (char**)(&frames), sizeof(*frames)) < 0)
80104fd4:	6a 04                	push   $0x4
80104fd6:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104fd9:	50                   	push   %eax
80104fda:	6a 00                	push   $0x0
80104fdc:	e8 d3 f1 ff ff       	call   801041b4 <argptr>
80104fe1:	83 c4 10             	add    $0x10,%esp
80104fe4:	85 c0                	test   %eax,%eax
80104fe6:	78 42                	js     8010502a <sys_dump_physmem+0x5c>
    return -1;
  if(argptr(1, (char**)(&pids), sizeof(*pids)) < 0)
80104fe8:	83 ec 04             	sub    $0x4,%esp
80104feb:	6a 04                	push   $0x4
80104fed:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104ff0:	50                   	push   %eax
80104ff1:	6a 01                	push   $0x1
80104ff3:	e8 bc f1 ff ff       	call   801041b4 <argptr>
80104ff8:	83 c4 10             	add    $0x10,%esp
80104ffb:	85 c0                	test   %eax,%eax
80104ffd:	78 32                	js     80105031 <sys_dump_physmem+0x63>
    return -1;
  if(argint(2, &numframes) < 0)
80104fff:	83 ec 08             	sub    $0x8,%esp
80105002:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105005:	50                   	push   %eax
80105006:	6a 02                	push   $0x2
80105008:	e8 7f f1 ff ff       	call   8010418c <argint>
8010500d:	83 c4 10             	add    $0x10,%esp
80105010:	85 c0                	test   %eax,%eax
80105012:	78 24                	js     80105038 <sys_dump_physmem+0x6a>
    return -1;

  return dump_physmem(frames, pids, numframes);
80105014:	83 ec 04             	sub    $0x4,%esp
80105017:	ff 75 ec             	pushl  -0x14(%ebp)
8010501a:	ff 75 f0             	pushl  -0x10(%ebp)
8010501d:	ff 75 f4             	pushl  -0xc(%ebp)
80105020:	e8 7e d3 ff ff       	call   801023a3 <dump_physmem>
80105025:	83 c4 10             	add    $0x10,%esp
80105028:	c9                   	leave  
80105029:	c3                   	ret    
    return -1;
8010502a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010502f:	eb f7                	jmp    80105028 <sys_dump_physmem+0x5a>
    return -1;
80105031:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105036:	eb f0                	jmp    80105028 <sys_dump_physmem+0x5a>
    return -1;
80105038:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010503d:	eb e9                	jmp    80105028 <sys_dump_physmem+0x5a>

8010503f <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
8010503f:	1e                   	push   %ds
  pushl %es
80105040:	06                   	push   %es
  pushl %fs
80105041:	0f a0                	push   %fs
  pushl %gs
80105043:	0f a8                	push   %gs
  pushal
80105045:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80105046:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
8010504a:	8e d8                	mov    %eax,%ds
  movw %ax, %es
8010504c:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
8010504e:	54                   	push   %esp
  call trap
8010504f:	e8 e3 00 00 00       	call   80105137 <trap>
  addl $4, %esp
80105054:	83 c4 04             	add    $0x4,%esp

80105057 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80105057:	61                   	popa   
  popl %gs
80105058:	0f a9                	pop    %gs
  popl %fs
8010505a:	0f a1                	pop    %fs
  popl %es
8010505c:	07                   	pop    %es
  popl %ds
8010505d:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
8010505e:	83 c4 08             	add    $0x8,%esp
  iret
80105061:	cf                   	iret   

80105062 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80105062:	55                   	push   %ebp
80105063:	89 e5                	mov    %esp,%ebp
80105065:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
80105068:	b8 00 00 00 00       	mov    $0x0,%eax
8010506d:	eb 4a                	jmp    801050b9 <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
8010506f:	8b 0c 85 08 a0 12 80 	mov    -0x7fed5ff8(,%eax,4),%ecx
80105076:	66 89 0c c5 e0 4c 13 	mov    %cx,-0x7fecb320(,%eax,8)
8010507d:	80 
8010507e:	66 c7 04 c5 e2 4c 13 	movw   $0x8,-0x7fecb31e(,%eax,8)
80105085:	80 08 00 
80105088:	c6 04 c5 e4 4c 13 80 	movb   $0x0,-0x7fecb31c(,%eax,8)
8010508f:	00 
80105090:	0f b6 14 c5 e5 4c 13 	movzbl -0x7fecb31b(,%eax,8),%edx
80105097:	80 
80105098:	83 e2 f0             	and    $0xfffffff0,%edx
8010509b:	83 ca 0e             	or     $0xe,%edx
8010509e:	83 e2 8f             	and    $0xffffff8f,%edx
801050a1:	83 ca 80             	or     $0xffffff80,%edx
801050a4:	88 14 c5 e5 4c 13 80 	mov    %dl,-0x7fecb31b(,%eax,8)
801050ab:	c1 e9 10             	shr    $0x10,%ecx
801050ae:	66 89 0c c5 e6 4c 13 	mov    %cx,-0x7fecb31a(,%eax,8)
801050b5:	80 
  for(i = 0; i < 256; i++)
801050b6:	83 c0 01             	add    $0x1,%eax
801050b9:	3d ff 00 00 00       	cmp    $0xff,%eax
801050be:	7e af                	jle    8010506f <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
801050c0:	8b 15 08 a1 12 80    	mov    0x8012a108,%edx
801050c6:	66 89 15 e0 4e 13 80 	mov    %dx,0x80134ee0
801050cd:	66 c7 05 e2 4e 13 80 	movw   $0x8,0x80134ee2
801050d4:	08 00 
801050d6:	c6 05 e4 4e 13 80 00 	movb   $0x0,0x80134ee4
801050dd:	0f b6 05 e5 4e 13 80 	movzbl 0x80134ee5,%eax
801050e4:	83 c8 0f             	or     $0xf,%eax
801050e7:	83 e0 ef             	and    $0xffffffef,%eax
801050ea:	83 c8 e0             	or     $0xffffffe0,%eax
801050ed:	a2 e5 4e 13 80       	mov    %al,0x80134ee5
801050f2:	c1 ea 10             	shr    $0x10,%edx
801050f5:	66 89 15 e6 4e 13 80 	mov    %dx,0x80134ee6

  initlock(&tickslock, "time");
801050fc:	83 ec 08             	sub    $0x8,%esp
801050ff:	68 5d 6f 10 80       	push   $0x80106f5d
80105104:	68 a0 4c 13 80       	push   $0x80134ca0
80105109:	e8 4b ec ff ff       	call   80103d59 <initlock>
}
8010510e:	83 c4 10             	add    $0x10,%esp
80105111:	c9                   	leave  
80105112:	c3                   	ret    

80105113 <idtinit>:

void
idtinit(void)
{
80105113:	55                   	push   %ebp
80105114:	89 e5                	mov    %esp,%ebp
80105116:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80105119:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
8010511f:	b8 e0 4c 13 80       	mov    $0x80134ce0,%eax
80105124:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80105128:	c1 e8 10             	shr    $0x10,%eax
8010512b:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
8010512f:	8d 45 fa             	lea    -0x6(%ebp),%eax
80105132:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80105135:	c9                   	leave  
80105136:	c3                   	ret    

80105137 <trap>:

void
trap(struct trapframe *tf)
{
80105137:	55                   	push   %ebp
80105138:	89 e5                	mov    %esp,%ebp
8010513a:	57                   	push   %edi
8010513b:	56                   	push   %esi
8010513c:	53                   	push   %ebx
8010513d:	83 ec 1c             	sub    $0x1c,%esp
80105140:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80105143:	8b 43 30             	mov    0x30(%ebx),%eax
80105146:	83 f8 40             	cmp    $0x40,%eax
80105149:	74 13                	je     8010515e <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
8010514b:	83 e8 20             	sub    $0x20,%eax
8010514e:	83 f8 1f             	cmp    $0x1f,%eax
80105151:	0f 87 3a 01 00 00    	ja     80105291 <trap+0x15a>
80105157:	ff 24 85 04 70 10 80 	jmp    *-0x7fef8ffc(,%eax,4)
    if(myproc()->killed)
8010515e:	e8 90 e3 ff ff       	call   801034f3 <myproc>
80105163:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105167:	75 1f                	jne    80105188 <trap+0x51>
    myproc()->tf = tf;
80105169:	e8 85 e3 ff ff       	call   801034f3 <myproc>
8010516e:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80105171:	e8 d9 f0 ff ff       	call   8010424f <syscall>
    if(myproc()->killed)
80105176:	e8 78 e3 ff ff       	call   801034f3 <myproc>
8010517b:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010517f:	74 7e                	je     801051ff <trap+0xc8>
      exit();
80105181:	e8 1c e7 ff ff       	call   801038a2 <exit>
80105186:	eb 77                	jmp    801051ff <trap+0xc8>
      exit();
80105188:	e8 15 e7 ff ff       	call   801038a2 <exit>
8010518d:	eb da                	jmp    80105169 <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
8010518f:	e8 44 e3 ff ff       	call   801034d8 <cpuid>
80105194:	85 c0                	test   %eax,%eax
80105196:	74 6f                	je     80105207 <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
80105198:	e8 f1 d4 ff ff       	call   8010268e <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
8010519d:	e8 51 e3 ff ff       	call   801034f3 <myproc>
801051a2:	85 c0                	test   %eax,%eax
801051a4:	74 1c                	je     801051c2 <trap+0x8b>
801051a6:	e8 48 e3 ff ff       	call   801034f3 <myproc>
801051ab:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801051af:	74 11                	je     801051c2 <trap+0x8b>
801051b1:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
801051b5:	83 e0 03             	and    $0x3,%eax
801051b8:	66 83 f8 03          	cmp    $0x3,%ax
801051bc:	0f 84 62 01 00 00    	je     80105324 <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
801051c2:	e8 2c e3 ff ff       	call   801034f3 <myproc>
801051c7:	85 c0                	test   %eax,%eax
801051c9:	74 0f                	je     801051da <trap+0xa3>
801051cb:	e8 23 e3 ff ff       	call   801034f3 <myproc>
801051d0:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
801051d4:	0f 84 54 01 00 00    	je     8010532e <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
801051da:	e8 14 e3 ff ff       	call   801034f3 <myproc>
801051df:	85 c0                	test   %eax,%eax
801051e1:	74 1c                	je     801051ff <trap+0xc8>
801051e3:	e8 0b e3 ff ff       	call   801034f3 <myproc>
801051e8:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801051ec:	74 11                	je     801051ff <trap+0xc8>
801051ee:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
801051f2:	83 e0 03             	and    $0x3,%eax
801051f5:	66 83 f8 03          	cmp    $0x3,%ax
801051f9:	0f 84 43 01 00 00    	je     80105342 <trap+0x20b>
    exit();
}
801051ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105202:	5b                   	pop    %ebx
80105203:	5e                   	pop    %esi
80105204:	5f                   	pop    %edi
80105205:	5d                   	pop    %ebp
80105206:	c3                   	ret    
      acquire(&tickslock);
80105207:	83 ec 0c             	sub    $0xc,%esp
8010520a:	68 a0 4c 13 80       	push   $0x80134ca0
8010520f:	e8 81 ec ff ff       	call   80103e95 <acquire>
      ticks++;
80105214:	83 05 e0 54 13 80 01 	addl   $0x1,0x801354e0
      wakeup(&ticks);
8010521b:	c7 04 24 e0 54 13 80 	movl   $0x801354e0,(%esp)
80105222:	e8 d8 e8 ff ff       	call   80103aff <wakeup>
      release(&tickslock);
80105227:	c7 04 24 a0 4c 13 80 	movl   $0x80134ca0,(%esp)
8010522e:	e8 c7 ec ff ff       	call   80103efa <release>
80105233:	83 c4 10             	add    $0x10,%esp
80105236:	e9 5d ff ff ff       	jmp    80105198 <trap+0x61>
    ideintr();
8010523b:	e8 33 cb ff ff       	call   80101d73 <ideintr>
    lapiceoi();
80105240:	e8 49 d4 ff ff       	call   8010268e <lapiceoi>
    break;
80105245:	e9 53 ff ff ff       	jmp    8010519d <trap+0x66>
    kbdintr();
8010524a:	e8 83 d2 ff ff       	call   801024d2 <kbdintr>
    lapiceoi();
8010524f:	e8 3a d4 ff ff       	call   8010268e <lapiceoi>
    break;
80105254:	e9 44 ff ff ff       	jmp    8010519d <trap+0x66>
    uartintr();
80105259:	e8 05 02 00 00       	call   80105463 <uartintr>
    lapiceoi();
8010525e:	e8 2b d4 ff ff       	call   8010268e <lapiceoi>
    break;
80105263:	e9 35 ff ff ff       	jmp    8010519d <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105268:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
8010526b:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010526f:	e8 64 e2 ff ff       	call   801034d8 <cpuid>
80105274:	57                   	push   %edi
80105275:	0f b7 f6             	movzwl %si,%esi
80105278:	56                   	push   %esi
80105279:	50                   	push   %eax
8010527a:	68 68 6f 10 80       	push   $0x80106f68
8010527f:	e8 87 b3 ff ff       	call   8010060b <cprintf>
    lapiceoi();
80105284:	e8 05 d4 ff ff       	call   8010268e <lapiceoi>
    break;
80105289:	83 c4 10             	add    $0x10,%esp
8010528c:	e9 0c ff ff ff       	jmp    8010519d <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
80105291:	e8 5d e2 ff ff       	call   801034f3 <myproc>
80105296:	85 c0                	test   %eax,%eax
80105298:	74 5f                	je     801052f9 <trap+0x1c2>
8010529a:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
8010529e:	74 59                	je     801052f9 <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801052a0:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801052a3:	8b 43 38             	mov    0x38(%ebx),%eax
801052a6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801052a9:	e8 2a e2 ff ff       	call   801034d8 <cpuid>
801052ae:	89 45 e0             	mov    %eax,-0x20(%ebp)
801052b1:	8b 53 34             	mov    0x34(%ebx),%edx
801052b4:	89 55 dc             	mov    %edx,-0x24(%ebp)
801052b7:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
801052ba:	e8 34 e2 ff ff       	call   801034f3 <myproc>
801052bf:	8d 48 6c             	lea    0x6c(%eax),%ecx
801052c2:	89 4d d8             	mov    %ecx,-0x28(%ebp)
801052c5:	e8 29 e2 ff ff       	call   801034f3 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801052ca:	57                   	push   %edi
801052cb:	ff 75 e4             	pushl  -0x1c(%ebp)
801052ce:	ff 75 e0             	pushl  -0x20(%ebp)
801052d1:	ff 75 dc             	pushl  -0x24(%ebp)
801052d4:	56                   	push   %esi
801052d5:	ff 75 d8             	pushl  -0x28(%ebp)
801052d8:	ff 70 10             	pushl  0x10(%eax)
801052db:	68 c0 6f 10 80       	push   $0x80106fc0
801052e0:	e8 26 b3 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
801052e5:	83 c4 20             	add    $0x20,%esp
801052e8:	e8 06 e2 ff ff       	call   801034f3 <myproc>
801052ed:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801052f4:	e9 a4 fe ff ff       	jmp    8010519d <trap+0x66>
801052f9:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801052fc:	8b 73 38             	mov    0x38(%ebx),%esi
801052ff:	e8 d4 e1 ff ff       	call   801034d8 <cpuid>
80105304:	83 ec 0c             	sub    $0xc,%esp
80105307:	57                   	push   %edi
80105308:	56                   	push   %esi
80105309:	50                   	push   %eax
8010530a:	ff 73 30             	pushl  0x30(%ebx)
8010530d:	68 8c 6f 10 80       	push   $0x80106f8c
80105312:	e8 f4 b2 ff ff       	call   8010060b <cprintf>
      panic("trap");
80105317:	83 c4 14             	add    $0x14,%esp
8010531a:	68 62 6f 10 80       	push   $0x80106f62
8010531f:	e8 24 b0 ff ff       	call   80100348 <panic>
    exit();
80105324:	e8 79 e5 ff ff       	call   801038a2 <exit>
80105329:	e9 94 fe ff ff       	jmp    801051c2 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
8010532e:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
80105332:	0f 85 a2 fe ff ff    	jne    801051da <trap+0xa3>
    yield();
80105338:	e8 2b e6 ff ff       	call   80103968 <yield>
8010533d:	e9 98 fe ff ff       	jmp    801051da <trap+0xa3>
    exit();
80105342:	e8 5b e5 ff ff       	call   801038a2 <exit>
80105347:	e9 b3 fe ff ff       	jmp    801051ff <trap+0xc8>

8010534c <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
8010534c:	55                   	push   %ebp
8010534d:	89 e5                	mov    %esp,%ebp
  if(!uart)
8010534f:	83 3d c0 a5 12 80 00 	cmpl   $0x0,0x8012a5c0
80105356:	74 15                	je     8010536d <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105358:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010535d:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
8010535e:	a8 01                	test   $0x1,%al
80105360:	74 12                	je     80105374 <uartgetc+0x28>
80105362:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105367:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
80105368:	0f b6 c0             	movzbl %al,%eax
}
8010536b:	5d                   	pop    %ebp
8010536c:	c3                   	ret    
    return -1;
8010536d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105372:	eb f7                	jmp    8010536b <uartgetc+0x1f>
    return -1;
80105374:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105379:	eb f0                	jmp    8010536b <uartgetc+0x1f>

8010537b <uartputc>:
  if(!uart)
8010537b:	83 3d c0 a5 12 80 00 	cmpl   $0x0,0x8012a5c0
80105382:	74 3b                	je     801053bf <uartputc+0x44>
{
80105384:	55                   	push   %ebp
80105385:	89 e5                	mov    %esp,%ebp
80105387:	53                   	push   %ebx
80105388:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010538b:	bb 00 00 00 00       	mov    $0x0,%ebx
80105390:	eb 10                	jmp    801053a2 <uartputc+0x27>
    microdelay(10);
80105392:	83 ec 0c             	sub    $0xc,%esp
80105395:	6a 0a                	push   $0xa
80105397:	e8 11 d3 ff ff       	call   801026ad <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010539c:	83 c3 01             	add    $0x1,%ebx
8010539f:	83 c4 10             	add    $0x10,%esp
801053a2:	83 fb 7f             	cmp    $0x7f,%ebx
801053a5:	7f 0a                	jg     801053b1 <uartputc+0x36>
801053a7:	ba fd 03 00 00       	mov    $0x3fd,%edx
801053ac:	ec                   	in     (%dx),%al
801053ad:	a8 20                	test   $0x20,%al
801053af:	74 e1                	je     80105392 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801053b1:	8b 45 08             	mov    0x8(%ebp),%eax
801053b4:	ba f8 03 00 00       	mov    $0x3f8,%edx
801053b9:	ee                   	out    %al,(%dx)
}
801053ba:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801053bd:	c9                   	leave  
801053be:	c3                   	ret    
801053bf:	f3 c3                	repz ret 

801053c1 <uartinit>:
{
801053c1:	55                   	push   %ebp
801053c2:	89 e5                	mov    %esp,%ebp
801053c4:	56                   	push   %esi
801053c5:	53                   	push   %ebx
801053c6:	b9 00 00 00 00       	mov    $0x0,%ecx
801053cb:	ba fa 03 00 00       	mov    $0x3fa,%edx
801053d0:	89 c8                	mov    %ecx,%eax
801053d2:	ee                   	out    %al,(%dx)
801053d3:	be fb 03 00 00       	mov    $0x3fb,%esi
801053d8:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
801053dd:	89 f2                	mov    %esi,%edx
801053df:	ee                   	out    %al,(%dx)
801053e0:	b8 0c 00 00 00       	mov    $0xc,%eax
801053e5:	ba f8 03 00 00       	mov    $0x3f8,%edx
801053ea:	ee                   	out    %al,(%dx)
801053eb:	bb f9 03 00 00       	mov    $0x3f9,%ebx
801053f0:	89 c8                	mov    %ecx,%eax
801053f2:	89 da                	mov    %ebx,%edx
801053f4:	ee                   	out    %al,(%dx)
801053f5:	b8 03 00 00 00       	mov    $0x3,%eax
801053fa:	89 f2                	mov    %esi,%edx
801053fc:	ee                   	out    %al,(%dx)
801053fd:	ba fc 03 00 00       	mov    $0x3fc,%edx
80105402:	89 c8                	mov    %ecx,%eax
80105404:	ee                   	out    %al,(%dx)
80105405:	b8 01 00 00 00       	mov    $0x1,%eax
8010540a:	89 da                	mov    %ebx,%edx
8010540c:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010540d:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105412:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
80105413:	3c ff                	cmp    $0xff,%al
80105415:	74 45                	je     8010545c <uartinit+0x9b>
  uart = 1;
80105417:	c7 05 c0 a5 12 80 01 	movl   $0x1,0x8012a5c0
8010541e:	00 00 00 
80105421:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105426:	ec                   	in     (%dx),%al
80105427:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010542c:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
8010542d:	83 ec 08             	sub    $0x8,%esp
80105430:	6a 00                	push   $0x0
80105432:	6a 04                	push   $0x4
80105434:	e8 45 cb ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
80105439:	83 c4 10             	add    $0x10,%esp
8010543c:	bb 84 70 10 80       	mov    $0x80107084,%ebx
80105441:	eb 12                	jmp    80105455 <uartinit+0x94>
    uartputc(*p);
80105443:	83 ec 0c             	sub    $0xc,%esp
80105446:	0f be c0             	movsbl %al,%eax
80105449:	50                   	push   %eax
8010544a:	e8 2c ff ff ff       	call   8010537b <uartputc>
  for(p="xv6...\n"; *p; p++)
8010544f:	83 c3 01             	add    $0x1,%ebx
80105452:	83 c4 10             	add    $0x10,%esp
80105455:	0f b6 03             	movzbl (%ebx),%eax
80105458:	84 c0                	test   %al,%al
8010545a:	75 e7                	jne    80105443 <uartinit+0x82>
}
8010545c:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010545f:	5b                   	pop    %ebx
80105460:	5e                   	pop    %esi
80105461:	5d                   	pop    %ebp
80105462:	c3                   	ret    

80105463 <uartintr>:

void
uartintr(void)
{
80105463:	55                   	push   %ebp
80105464:	89 e5                	mov    %esp,%ebp
80105466:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
80105469:	68 4c 53 10 80       	push   $0x8010534c
8010546e:	e8 cb b2 ff ff       	call   8010073e <consoleintr>
}
80105473:	83 c4 10             	add    $0x10,%esp
80105476:	c9                   	leave  
80105477:	c3                   	ret    

80105478 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80105478:	6a 00                	push   $0x0
  pushl $0
8010547a:	6a 00                	push   $0x0
  jmp alltraps
8010547c:	e9 be fb ff ff       	jmp    8010503f <alltraps>

80105481 <vector1>:
.globl vector1
vector1:
  pushl $0
80105481:	6a 00                	push   $0x0
  pushl $1
80105483:	6a 01                	push   $0x1
  jmp alltraps
80105485:	e9 b5 fb ff ff       	jmp    8010503f <alltraps>

8010548a <vector2>:
.globl vector2
vector2:
  pushl $0
8010548a:	6a 00                	push   $0x0
  pushl $2
8010548c:	6a 02                	push   $0x2
  jmp alltraps
8010548e:	e9 ac fb ff ff       	jmp    8010503f <alltraps>

80105493 <vector3>:
.globl vector3
vector3:
  pushl $0
80105493:	6a 00                	push   $0x0
  pushl $3
80105495:	6a 03                	push   $0x3
  jmp alltraps
80105497:	e9 a3 fb ff ff       	jmp    8010503f <alltraps>

8010549c <vector4>:
.globl vector4
vector4:
  pushl $0
8010549c:	6a 00                	push   $0x0
  pushl $4
8010549e:	6a 04                	push   $0x4
  jmp alltraps
801054a0:	e9 9a fb ff ff       	jmp    8010503f <alltraps>

801054a5 <vector5>:
.globl vector5
vector5:
  pushl $0
801054a5:	6a 00                	push   $0x0
  pushl $5
801054a7:	6a 05                	push   $0x5
  jmp alltraps
801054a9:	e9 91 fb ff ff       	jmp    8010503f <alltraps>

801054ae <vector6>:
.globl vector6
vector6:
  pushl $0
801054ae:	6a 00                	push   $0x0
  pushl $6
801054b0:	6a 06                	push   $0x6
  jmp alltraps
801054b2:	e9 88 fb ff ff       	jmp    8010503f <alltraps>

801054b7 <vector7>:
.globl vector7
vector7:
  pushl $0
801054b7:	6a 00                	push   $0x0
  pushl $7
801054b9:	6a 07                	push   $0x7
  jmp alltraps
801054bb:	e9 7f fb ff ff       	jmp    8010503f <alltraps>

801054c0 <vector8>:
.globl vector8
vector8:
  pushl $8
801054c0:	6a 08                	push   $0x8
  jmp alltraps
801054c2:	e9 78 fb ff ff       	jmp    8010503f <alltraps>

801054c7 <vector9>:
.globl vector9
vector9:
  pushl $0
801054c7:	6a 00                	push   $0x0
  pushl $9
801054c9:	6a 09                	push   $0x9
  jmp alltraps
801054cb:	e9 6f fb ff ff       	jmp    8010503f <alltraps>

801054d0 <vector10>:
.globl vector10
vector10:
  pushl $10
801054d0:	6a 0a                	push   $0xa
  jmp alltraps
801054d2:	e9 68 fb ff ff       	jmp    8010503f <alltraps>

801054d7 <vector11>:
.globl vector11
vector11:
  pushl $11
801054d7:	6a 0b                	push   $0xb
  jmp alltraps
801054d9:	e9 61 fb ff ff       	jmp    8010503f <alltraps>

801054de <vector12>:
.globl vector12
vector12:
  pushl $12
801054de:	6a 0c                	push   $0xc
  jmp alltraps
801054e0:	e9 5a fb ff ff       	jmp    8010503f <alltraps>

801054e5 <vector13>:
.globl vector13
vector13:
  pushl $13
801054e5:	6a 0d                	push   $0xd
  jmp alltraps
801054e7:	e9 53 fb ff ff       	jmp    8010503f <alltraps>

801054ec <vector14>:
.globl vector14
vector14:
  pushl $14
801054ec:	6a 0e                	push   $0xe
  jmp alltraps
801054ee:	e9 4c fb ff ff       	jmp    8010503f <alltraps>

801054f3 <vector15>:
.globl vector15
vector15:
  pushl $0
801054f3:	6a 00                	push   $0x0
  pushl $15
801054f5:	6a 0f                	push   $0xf
  jmp alltraps
801054f7:	e9 43 fb ff ff       	jmp    8010503f <alltraps>

801054fc <vector16>:
.globl vector16
vector16:
  pushl $0
801054fc:	6a 00                	push   $0x0
  pushl $16
801054fe:	6a 10                	push   $0x10
  jmp alltraps
80105500:	e9 3a fb ff ff       	jmp    8010503f <alltraps>

80105505 <vector17>:
.globl vector17
vector17:
  pushl $17
80105505:	6a 11                	push   $0x11
  jmp alltraps
80105507:	e9 33 fb ff ff       	jmp    8010503f <alltraps>

8010550c <vector18>:
.globl vector18
vector18:
  pushl $0
8010550c:	6a 00                	push   $0x0
  pushl $18
8010550e:	6a 12                	push   $0x12
  jmp alltraps
80105510:	e9 2a fb ff ff       	jmp    8010503f <alltraps>

80105515 <vector19>:
.globl vector19
vector19:
  pushl $0
80105515:	6a 00                	push   $0x0
  pushl $19
80105517:	6a 13                	push   $0x13
  jmp alltraps
80105519:	e9 21 fb ff ff       	jmp    8010503f <alltraps>

8010551e <vector20>:
.globl vector20
vector20:
  pushl $0
8010551e:	6a 00                	push   $0x0
  pushl $20
80105520:	6a 14                	push   $0x14
  jmp alltraps
80105522:	e9 18 fb ff ff       	jmp    8010503f <alltraps>

80105527 <vector21>:
.globl vector21
vector21:
  pushl $0
80105527:	6a 00                	push   $0x0
  pushl $21
80105529:	6a 15                	push   $0x15
  jmp alltraps
8010552b:	e9 0f fb ff ff       	jmp    8010503f <alltraps>

80105530 <vector22>:
.globl vector22
vector22:
  pushl $0
80105530:	6a 00                	push   $0x0
  pushl $22
80105532:	6a 16                	push   $0x16
  jmp alltraps
80105534:	e9 06 fb ff ff       	jmp    8010503f <alltraps>

80105539 <vector23>:
.globl vector23
vector23:
  pushl $0
80105539:	6a 00                	push   $0x0
  pushl $23
8010553b:	6a 17                	push   $0x17
  jmp alltraps
8010553d:	e9 fd fa ff ff       	jmp    8010503f <alltraps>

80105542 <vector24>:
.globl vector24
vector24:
  pushl $0
80105542:	6a 00                	push   $0x0
  pushl $24
80105544:	6a 18                	push   $0x18
  jmp alltraps
80105546:	e9 f4 fa ff ff       	jmp    8010503f <alltraps>

8010554b <vector25>:
.globl vector25
vector25:
  pushl $0
8010554b:	6a 00                	push   $0x0
  pushl $25
8010554d:	6a 19                	push   $0x19
  jmp alltraps
8010554f:	e9 eb fa ff ff       	jmp    8010503f <alltraps>

80105554 <vector26>:
.globl vector26
vector26:
  pushl $0
80105554:	6a 00                	push   $0x0
  pushl $26
80105556:	6a 1a                	push   $0x1a
  jmp alltraps
80105558:	e9 e2 fa ff ff       	jmp    8010503f <alltraps>

8010555d <vector27>:
.globl vector27
vector27:
  pushl $0
8010555d:	6a 00                	push   $0x0
  pushl $27
8010555f:	6a 1b                	push   $0x1b
  jmp alltraps
80105561:	e9 d9 fa ff ff       	jmp    8010503f <alltraps>

80105566 <vector28>:
.globl vector28
vector28:
  pushl $0
80105566:	6a 00                	push   $0x0
  pushl $28
80105568:	6a 1c                	push   $0x1c
  jmp alltraps
8010556a:	e9 d0 fa ff ff       	jmp    8010503f <alltraps>

8010556f <vector29>:
.globl vector29
vector29:
  pushl $0
8010556f:	6a 00                	push   $0x0
  pushl $29
80105571:	6a 1d                	push   $0x1d
  jmp alltraps
80105573:	e9 c7 fa ff ff       	jmp    8010503f <alltraps>

80105578 <vector30>:
.globl vector30
vector30:
  pushl $0
80105578:	6a 00                	push   $0x0
  pushl $30
8010557a:	6a 1e                	push   $0x1e
  jmp alltraps
8010557c:	e9 be fa ff ff       	jmp    8010503f <alltraps>

80105581 <vector31>:
.globl vector31
vector31:
  pushl $0
80105581:	6a 00                	push   $0x0
  pushl $31
80105583:	6a 1f                	push   $0x1f
  jmp alltraps
80105585:	e9 b5 fa ff ff       	jmp    8010503f <alltraps>

8010558a <vector32>:
.globl vector32
vector32:
  pushl $0
8010558a:	6a 00                	push   $0x0
  pushl $32
8010558c:	6a 20                	push   $0x20
  jmp alltraps
8010558e:	e9 ac fa ff ff       	jmp    8010503f <alltraps>

80105593 <vector33>:
.globl vector33
vector33:
  pushl $0
80105593:	6a 00                	push   $0x0
  pushl $33
80105595:	6a 21                	push   $0x21
  jmp alltraps
80105597:	e9 a3 fa ff ff       	jmp    8010503f <alltraps>

8010559c <vector34>:
.globl vector34
vector34:
  pushl $0
8010559c:	6a 00                	push   $0x0
  pushl $34
8010559e:	6a 22                	push   $0x22
  jmp alltraps
801055a0:	e9 9a fa ff ff       	jmp    8010503f <alltraps>

801055a5 <vector35>:
.globl vector35
vector35:
  pushl $0
801055a5:	6a 00                	push   $0x0
  pushl $35
801055a7:	6a 23                	push   $0x23
  jmp alltraps
801055a9:	e9 91 fa ff ff       	jmp    8010503f <alltraps>

801055ae <vector36>:
.globl vector36
vector36:
  pushl $0
801055ae:	6a 00                	push   $0x0
  pushl $36
801055b0:	6a 24                	push   $0x24
  jmp alltraps
801055b2:	e9 88 fa ff ff       	jmp    8010503f <alltraps>

801055b7 <vector37>:
.globl vector37
vector37:
  pushl $0
801055b7:	6a 00                	push   $0x0
  pushl $37
801055b9:	6a 25                	push   $0x25
  jmp alltraps
801055bb:	e9 7f fa ff ff       	jmp    8010503f <alltraps>

801055c0 <vector38>:
.globl vector38
vector38:
  pushl $0
801055c0:	6a 00                	push   $0x0
  pushl $38
801055c2:	6a 26                	push   $0x26
  jmp alltraps
801055c4:	e9 76 fa ff ff       	jmp    8010503f <alltraps>

801055c9 <vector39>:
.globl vector39
vector39:
  pushl $0
801055c9:	6a 00                	push   $0x0
  pushl $39
801055cb:	6a 27                	push   $0x27
  jmp alltraps
801055cd:	e9 6d fa ff ff       	jmp    8010503f <alltraps>

801055d2 <vector40>:
.globl vector40
vector40:
  pushl $0
801055d2:	6a 00                	push   $0x0
  pushl $40
801055d4:	6a 28                	push   $0x28
  jmp alltraps
801055d6:	e9 64 fa ff ff       	jmp    8010503f <alltraps>

801055db <vector41>:
.globl vector41
vector41:
  pushl $0
801055db:	6a 00                	push   $0x0
  pushl $41
801055dd:	6a 29                	push   $0x29
  jmp alltraps
801055df:	e9 5b fa ff ff       	jmp    8010503f <alltraps>

801055e4 <vector42>:
.globl vector42
vector42:
  pushl $0
801055e4:	6a 00                	push   $0x0
  pushl $42
801055e6:	6a 2a                	push   $0x2a
  jmp alltraps
801055e8:	e9 52 fa ff ff       	jmp    8010503f <alltraps>

801055ed <vector43>:
.globl vector43
vector43:
  pushl $0
801055ed:	6a 00                	push   $0x0
  pushl $43
801055ef:	6a 2b                	push   $0x2b
  jmp alltraps
801055f1:	e9 49 fa ff ff       	jmp    8010503f <alltraps>

801055f6 <vector44>:
.globl vector44
vector44:
  pushl $0
801055f6:	6a 00                	push   $0x0
  pushl $44
801055f8:	6a 2c                	push   $0x2c
  jmp alltraps
801055fa:	e9 40 fa ff ff       	jmp    8010503f <alltraps>

801055ff <vector45>:
.globl vector45
vector45:
  pushl $0
801055ff:	6a 00                	push   $0x0
  pushl $45
80105601:	6a 2d                	push   $0x2d
  jmp alltraps
80105603:	e9 37 fa ff ff       	jmp    8010503f <alltraps>

80105608 <vector46>:
.globl vector46
vector46:
  pushl $0
80105608:	6a 00                	push   $0x0
  pushl $46
8010560a:	6a 2e                	push   $0x2e
  jmp alltraps
8010560c:	e9 2e fa ff ff       	jmp    8010503f <alltraps>

80105611 <vector47>:
.globl vector47
vector47:
  pushl $0
80105611:	6a 00                	push   $0x0
  pushl $47
80105613:	6a 2f                	push   $0x2f
  jmp alltraps
80105615:	e9 25 fa ff ff       	jmp    8010503f <alltraps>

8010561a <vector48>:
.globl vector48
vector48:
  pushl $0
8010561a:	6a 00                	push   $0x0
  pushl $48
8010561c:	6a 30                	push   $0x30
  jmp alltraps
8010561e:	e9 1c fa ff ff       	jmp    8010503f <alltraps>

80105623 <vector49>:
.globl vector49
vector49:
  pushl $0
80105623:	6a 00                	push   $0x0
  pushl $49
80105625:	6a 31                	push   $0x31
  jmp alltraps
80105627:	e9 13 fa ff ff       	jmp    8010503f <alltraps>

8010562c <vector50>:
.globl vector50
vector50:
  pushl $0
8010562c:	6a 00                	push   $0x0
  pushl $50
8010562e:	6a 32                	push   $0x32
  jmp alltraps
80105630:	e9 0a fa ff ff       	jmp    8010503f <alltraps>

80105635 <vector51>:
.globl vector51
vector51:
  pushl $0
80105635:	6a 00                	push   $0x0
  pushl $51
80105637:	6a 33                	push   $0x33
  jmp alltraps
80105639:	e9 01 fa ff ff       	jmp    8010503f <alltraps>

8010563e <vector52>:
.globl vector52
vector52:
  pushl $0
8010563e:	6a 00                	push   $0x0
  pushl $52
80105640:	6a 34                	push   $0x34
  jmp alltraps
80105642:	e9 f8 f9 ff ff       	jmp    8010503f <alltraps>

80105647 <vector53>:
.globl vector53
vector53:
  pushl $0
80105647:	6a 00                	push   $0x0
  pushl $53
80105649:	6a 35                	push   $0x35
  jmp alltraps
8010564b:	e9 ef f9 ff ff       	jmp    8010503f <alltraps>

80105650 <vector54>:
.globl vector54
vector54:
  pushl $0
80105650:	6a 00                	push   $0x0
  pushl $54
80105652:	6a 36                	push   $0x36
  jmp alltraps
80105654:	e9 e6 f9 ff ff       	jmp    8010503f <alltraps>

80105659 <vector55>:
.globl vector55
vector55:
  pushl $0
80105659:	6a 00                	push   $0x0
  pushl $55
8010565b:	6a 37                	push   $0x37
  jmp alltraps
8010565d:	e9 dd f9 ff ff       	jmp    8010503f <alltraps>

80105662 <vector56>:
.globl vector56
vector56:
  pushl $0
80105662:	6a 00                	push   $0x0
  pushl $56
80105664:	6a 38                	push   $0x38
  jmp alltraps
80105666:	e9 d4 f9 ff ff       	jmp    8010503f <alltraps>

8010566b <vector57>:
.globl vector57
vector57:
  pushl $0
8010566b:	6a 00                	push   $0x0
  pushl $57
8010566d:	6a 39                	push   $0x39
  jmp alltraps
8010566f:	e9 cb f9 ff ff       	jmp    8010503f <alltraps>

80105674 <vector58>:
.globl vector58
vector58:
  pushl $0
80105674:	6a 00                	push   $0x0
  pushl $58
80105676:	6a 3a                	push   $0x3a
  jmp alltraps
80105678:	e9 c2 f9 ff ff       	jmp    8010503f <alltraps>

8010567d <vector59>:
.globl vector59
vector59:
  pushl $0
8010567d:	6a 00                	push   $0x0
  pushl $59
8010567f:	6a 3b                	push   $0x3b
  jmp alltraps
80105681:	e9 b9 f9 ff ff       	jmp    8010503f <alltraps>

80105686 <vector60>:
.globl vector60
vector60:
  pushl $0
80105686:	6a 00                	push   $0x0
  pushl $60
80105688:	6a 3c                	push   $0x3c
  jmp alltraps
8010568a:	e9 b0 f9 ff ff       	jmp    8010503f <alltraps>

8010568f <vector61>:
.globl vector61
vector61:
  pushl $0
8010568f:	6a 00                	push   $0x0
  pushl $61
80105691:	6a 3d                	push   $0x3d
  jmp alltraps
80105693:	e9 a7 f9 ff ff       	jmp    8010503f <alltraps>

80105698 <vector62>:
.globl vector62
vector62:
  pushl $0
80105698:	6a 00                	push   $0x0
  pushl $62
8010569a:	6a 3e                	push   $0x3e
  jmp alltraps
8010569c:	e9 9e f9 ff ff       	jmp    8010503f <alltraps>

801056a1 <vector63>:
.globl vector63
vector63:
  pushl $0
801056a1:	6a 00                	push   $0x0
  pushl $63
801056a3:	6a 3f                	push   $0x3f
  jmp alltraps
801056a5:	e9 95 f9 ff ff       	jmp    8010503f <alltraps>

801056aa <vector64>:
.globl vector64
vector64:
  pushl $0
801056aa:	6a 00                	push   $0x0
  pushl $64
801056ac:	6a 40                	push   $0x40
  jmp alltraps
801056ae:	e9 8c f9 ff ff       	jmp    8010503f <alltraps>

801056b3 <vector65>:
.globl vector65
vector65:
  pushl $0
801056b3:	6a 00                	push   $0x0
  pushl $65
801056b5:	6a 41                	push   $0x41
  jmp alltraps
801056b7:	e9 83 f9 ff ff       	jmp    8010503f <alltraps>

801056bc <vector66>:
.globl vector66
vector66:
  pushl $0
801056bc:	6a 00                	push   $0x0
  pushl $66
801056be:	6a 42                	push   $0x42
  jmp alltraps
801056c0:	e9 7a f9 ff ff       	jmp    8010503f <alltraps>

801056c5 <vector67>:
.globl vector67
vector67:
  pushl $0
801056c5:	6a 00                	push   $0x0
  pushl $67
801056c7:	6a 43                	push   $0x43
  jmp alltraps
801056c9:	e9 71 f9 ff ff       	jmp    8010503f <alltraps>

801056ce <vector68>:
.globl vector68
vector68:
  pushl $0
801056ce:	6a 00                	push   $0x0
  pushl $68
801056d0:	6a 44                	push   $0x44
  jmp alltraps
801056d2:	e9 68 f9 ff ff       	jmp    8010503f <alltraps>

801056d7 <vector69>:
.globl vector69
vector69:
  pushl $0
801056d7:	6a 00                	push   $0x0
  pushl $69
801056d9:	6a 45                	push   $0x45
  jmp alltraps
801056db:	e9 5f f9 ff ff       	jmp    8010503f <alltraps>

801056e0 <vector70>:
.globl vector70
vector70:
  pushl $0
801056e0:	6a 00                	push   $0x0
  pushl $70
801056e2:	6a 46                	push   $0x46
  jmp alltraps
801056e4:	e9 56 f9 ff ff       	jmp    8010503f <alltraps>

801056e9 <vector71>:
.globl vector71
vector71:
  pushl $0
801056e9:	6a 00                	push   $0x0
  pushl $71
801056eb:	6a 47                	push   $0x47
  jmp alltraps
801056ed:	e9 4d f9 ff ff       	jmp    8010503f <alltraps>

801056f2 <vector72>:
.globl vector72
vector72:
  pushl $0
801056f2:	6a 00                	push   $0x0
  pushl $72
801056f4:	6a 48                	push   $0x48
  jmp alltraps
801056f6:	e9 44 f9 ff ff       	jmp    8010503f <alltraps>

801056fb <vector73>:
.globl vector73
vector73:
  pushl $0
801056fb:	6a 00                	push   $0x0
  pushl $73
801056fd:	6a 49                	push   $0x49
  jmp alltraps
801056ff:	e9 3b f9 ff ff       	jmp    8010503f <alltraps>

80105704 <vector74>:
.globl vector74
vector74:
  pushl $0
80105704:	6a 00                	push   $0x0
  pushl $74
80105706:	6a 4a                	push   $0x4a
  jmp alltraps
80105708:	e9 32 f9 ff ff       	jmp    8010503f <alltraps>

8010570d <vector75>:
.globl vector75
vector75:
  pushl $0
8010570d:	6a 00                	push   $0x0
  pushl $75
8010570f:	6a 4b                	push   $0x4b
  jmp alltraps
80105711:	e9 29 f9 ff ff       	jmp    8010503f <alltraps>

80105716 <vector76>:
.globl vector76
vector76:
  pushl $0
80105716:	6a 00                	push   $0x0
  pushl $76
80105718:	6a 4c                	push   $0x4c
  jmp alltraps
8010571a:	e9 20 f9 ff ff       	jmp    8010503f <alltraps>

8010571f <vector77>:
.globl vector77
vector77:
  pushl $0
8010571f:	6a 00                	push   $0x0
  pushl $77
80105721:	6a 4d                	push   $0x4d
  jmp alltraps
80105723:	e9 17 f9 ff ff       	jmp    8010503f <alltraps>

80105728 <vector78>:
.globl vector78
vector78:
  pushl $0
80105728:	6a 00                	push   $0x0
  pushl $78
8010572a:	6a 4e                	push   $0x4e
  jmp alltraps
8010572c:	e9 0e f9 ff ff       	jmp    8010503f <alltraps>

80105731 <vector79>:
.globl vector79
vector79:
  pushl $0
80105731:	6a 00                	push   $0x0
  pushl $79
80105733:	6a 4f                	push   $0x4f
  jmp alltraps
80105735:	e9 05 f9 ff ff       	jmp    8010503f <alltraps>

8010573a <vector80>:
.globl vector80
vector80:
  pushl $0
8010573a:	6a 00                	push   $0x0
  pushl $80
8010573c:	6a 50                	push   $0x50
  jmp alltraps
8010573e:	e9 fc f8 ff ff       	jmp    8010503f <alltraps>

80105743 <vector81>:
.globl vector81
vector81:
  pushl $0
80105743:	6a 00                	push   $0x0
  pushl $81
80105745:	6a 51                	push   $0x51
  jmp alltraps
80105747:	e9 f3 f8 ff ff       	jmp    8010503f <alltraps>

8010574c <vector82>:
.globl vector82
vector82:
  pushl $0
8010574c:	6a 00                	push   $0x0
  pushl $82
8010574e:	6a 52                	push   $0x52
  jmp alltraps
80105750:	e9 ea f8 ff ff       	jmp    8010503f <alltraps>

80105755 <vector83>:
.globl vector83
vector83:
  pushl $0
80105755:	6a 00                	push   $0x0
  pushl $83
80105757:	6a 53                	push   $0x53
  jmp alltraps
80105759:	e9 e1 f8 ff ff       	jmp    8010503f <alltraps>

8010575e <vector84>:
.globl vector84
vector84:
  pushl $0
8010575e:	6a 00                	push   $0x0
  pushl $84
80105760:	6a 54                	push   $0x54
  jmp alltraps
80105762:	e9 d8 f8 ff ff       	jmp    8010503f <alltraps>

80105767 <vector85>:
.globl vector85
vector85:
  pushl $0
80105767:	6a 00                	push   $0x0
  pushl $85
80105769:	6a 55                	push   $0x55
  jmp alltraps
8010576b:	e9 cf f8 ff ff       	jmp    8010503f <alltraps>

80105770 <vector86>:
.globl vector86
vector86:
  pushl $0
80105770:	6a 00                	push   $0x0
  pushl $86
80105772:	6a 56                	push   $0x56
  jmp alltraps
80105774:	e9 c6 f8 ff ff       	jmp    8010503f <alltraps>

80105779 <vector87>:
.globl vector87
vector87:
  pushl $0
80105779:	6a 00                	push   $0x0
  pushl $87
8010577b:	6a 57                	push   $0x57
  jmp alltraps
8010577d:	e9 bd f8 ff ff       	jmp    8010503f <alltraps>

80105782 <vector88>:
.globl vector88
vector88:
  pushl $0
80105782:	6a 00                	push   $0x0
  pushl $88
80105784:	6a 58                	push   $0x58
  jmp alltraps
80105786:	e9 b4 f8 ff ff       	jmp    8010503f <alltraps>

8010578b <vector89>:
.globl vector89
vector89:
  pushl $0
8010578b:	6a 00                	push   $0x0
  pushl $89
8010578d:	6a 59                	push   $0x59
  jmp alltraps
8010578f:	e9 ab f8 ff ff       	jmp    8010503f <alltraps>

80105794 <vector90>:
.globl vector90
vector90:
  pushl $0
80105794:	6a 00                	push   $0x0
  pushl $90
80105796:	6a 5a                	push   $0x5a
  jmp alltraps
80105798:	e9 a2 f8 ff ff       	jmp    8010503f <alltraps>

8010579d <vector91>:
.globl vector91
vector91:
  pushl $0
8010579d:	6a 00                	push   $0x0
  pushl $91
8010579f:	6a 5b                	push   $0x5b
  jmp alltraps
801057a1:	e9 99 f8 ff ff       	jmp    8010503f <alltraps>

801057a6 <vector92>:
.globl vector92
vector92:
  pushl $0
801057a6:	6a 00                	push   $0x0
  pushl $92
801057a8:	6a 5c                	push   $0x5c
  jmp alltraps
801057aa:	e9 90 f8 ff ff       	jmp    8010503f <alltraps>

801057af <vector93>:
.globl vector93
vector93:
  pushl $0
801057af:	6a 00                	push   $0x0
  pushl $93
801057b1:	6a 5d                	push   $0x5d
  jmp alltraps
801057b3:	e9 87 f8 ff ff       	jmp    8010503f <alltraps>

801057b8 <vector94>:
.globl vector94
vector94:
  pushl $0
801057b8:	6a 00                	push   $0x0
  pushl $94
801057ba:	6a 5e                	push   $0x5e
  jmp alltraps
801057bc:	e9 7e f8 ff ff       	jmp    8010503f <alltraps>

801057c1 <vector95>:
.globl vector95
vector95:
  pushl $0
801057c1:	6a 00                	push   $0x0
  pushl $95
801057c3:	6a 5f                	push   $0x5f
  jmp alltraps
801057c5:	e9 75 f8 ff ff       	jmp    8010503f <alltraps>

801057ca <vector96>:
.globl vector96
vector96:
  pushl $0
801057ca:	6a 00                	push   $0x0
  pushl $96
801057cc:	6a 60                	push   $0x60
  jmp alltraps
801057ce:	e9 6c f8 ff ff       	jmp    8010503f <alltraps>

801057d3 <vector97>:
.globl vector97
vector97:
  pushl $0
801057d3:	6a 00                	push   $0x0
  pushl $97
801057d5:	6a 61                	push   $0x61
  jmp alltraps
801057d7:	e9 63 f8 ff ff       	jmp    8010503f <alltraps>

801057dc <vector98>:
.globl vector98
vector98:
  pushl $0
801057dc:	6a 00                	push   $0x0
  pushl $98
801057de:	6a 62                	push   $0x62
  jmp alltraps
801057e0:	e9 5a f8 ff ff       	jmp    8010503f <alltraps>

801057e5 <vector99>:
.globl vector99
vector99:
  pushl $0
801057e5:	6a 00                	push   $0x0
  pushl $99
801057e7:	6a 63                	push   $0x63
  jmp alltraps
801057e9:	e9 51 f8 ff ff       	jmp    8010503f <alltraps>

801057ee <vector100>:
.globl vector100
vector100:
  pushl $0
801057ee:	6a 00                	push   $0x0
  pushl $100
801057f0:	6a 64                	push   $0x64
  jmp alltraps
801057f2:	e9 48 f8 ff ff       	jmp    8010503f <alltraps>

801057f7 <vector101>:
.globl vector101
vector101:
  pushl $0
801057f7:	6a 00                	push   $0x0
  pushl $101
801057f9:	6a 65                	push   $0x65
  jmp alltraps
801057fb:	e9 3f f8 ff ff       	jmp    8010503f <alltraps>

80105800 <vector102>:
.globl vector102
vector102:
  pushl $0
80105800:	6a 00                	push   $0x0
  pushl $102
80105802:	6a 66                	push   $0x66
  jmp alltraps
80105804:	e9 36 f8 ff ff       	jmp    8010503f <alltraps>

80105809 <vector103>:
.globl vector103
vector103:
  pushl $0
80105809:	6a 00                	push   $0x0
  pushl $103
8010580b:	6a 67                	push   $0x67
  jmp alltraps
8010580d:	e9 2d f8 ff ff       	jmp    8010503f <alltraps>

80105812 <vector104>:
.globl vector104
vector104:
  pushl $0
80105812:	6a 00                	push   $0x0
  pushl $104
80105814:	6a 68                	push   $0x68
  jmp alltraps
80105816:	e9 24 f8 ff ff       	jmp    8010503f <alltraps>

8010581b <vector105>:
.globl vector105
vector105:
  pushl $0
8010581b:	6a 00                	push   $0x0
  pushl $105
8010581d:	6a 69                	push   $0x69
  jmp alltraps
8010581f:	e9 1b f8 ff ff       	jmp    8010503f <alltraps>

80105824 <vector106>:
.globl vector106
vector106:
  pushl $0
80105824:	6a 00                	push   $0x0
  pushl $106
80105826:	6a 6a                	push   $0x6a
  jmp alltraps
80105828:	e9 12 f8 ff ff       	jmp    8010503f <alltraps>

8010582d <vector107>:
.globl vector107
vector107:
  pushl $0
8010582d:	6a 00                	push   $0x0
  pushl $107
8010582f:	6a 6b                	push   $0x6b
  jmp alltraps
80105831:	e9 09 f8 ff ff       	jmp    8010503f <alltraps>

80105836 <vector108>:
.globl vector108
vector108:
  pushl $0
80105836:	6a 00                	push   $0x0
  pushl $108
80105838:	6a 6c                	push   $0x6c
  jmp alltraps
8010583a:	e9 00 f8 ff ff       	jmp    8010503f <alltraps>

8010583f <vector109>:
.globl vector109
vector109:
  pushl $0
8010583f:	6a 00                	push   $0x0
  pushl $109
80105841:	6a 6d                	push   $0x6d
  jmp alltraps
80105843:	e9 f7 f7 ff ff       	jmp    8010503f <alltraps>

80105848 <vector110>:
.globl vector110
vector110:
  pushl $0
80105848:	6a 00                	push   $0x0
  pushl $110
8010584a:	6a 6e                	push   $0x6e
  jmp alltraps
8010584c:	e9 ee f7 ff ff       	jmp    8010503f <alltraps>

80105851 <vector111>:
.globl vector111
vector111:
  pushl $0
80105851:	6a 00                	push   $0x0
  pushl $111
80105853:	6a 6f                	push   $0x6f
  jmp alltraps
80105855:	e9 e5 f7 ff ff       	jmp    8010503f <alltraps>

8010585a <vector112>:
.globl vector112
vector112:
  pushl $0
8010585a:	6a 00                	push   $0x0
  pushl $112
8010585c:	6a 70                	push   $0x70
  jmp alltraps
8010585e:	e9 dc f7 ff ff       	jmp    8010503f <alltraps>

80105863 <vector113>:
.globl vector113
vector113:
  pushl $0
80105863:	6a 00                	push   $0x0
  pushl $113
80105865:	6a 71                	push   $0x71
  jmp alltraps
80105867:	e9 d3 f7 ff ff       	jmp    8010503f <alltraps>

8010586c <vector114>:
.globl vector114
vector114:
  pushl $0
8010586c:	6a 00                	push   $0x0
  pushl $114
8010586e:	6a 72                	push   $0x72
  jmp alltraps
80105870:	e9 ca f7 ff ff       	jmp    8010503f <alltraps>

80105875 <vector115>:
.globl vector115
vector115:
  pushl $0
80105875:	6a 00                	push   $0x0
  pushl $115
80105877:	6a 73                	push   $0x73
  jmp alltraps
80105879:	e9 c1 f7 ff ff       	jmp    8010503f <alltraps>

8010587e <vector116>:
.globl vector116
vector116:
  pushl $0
8010587e:	6a 00                	push   $0x0
  pushl $116
80105880:	6a 74                	push   $0x74
  jmp alltraps
80105882:	e9 b8 f7 ff ff       	jmp    8010503f <alltraps>

80105887 <vector117>:
.globl vector117
vector117:
  pushl $0
80105887:	6a 00                	push   $0x0
  pushl $117
80105889:	6a 75                	push   $0x75
  jmp alltraps
8010588b:	e9 af f7 ff ff       	jmp    8010503f <alltraps>

80105890 <vector118>:
.globl vector118
vector118:
  pushl $0
80105890:	6a 00                	push   $0x0
  pushl $118
80105892:	6a 76                	push   $0x76
  jmp alltraps
80105894:	e9 a6 f7 ff ff       	jmp    8010503f <alltraps>

80105899 <vector119>:
.globl vector119
vector119:
  pushl $0
80105899:	6a 00                	push   $0x0
  pushl $119
8010589b:	6a 77                	push   $0x77
  jmp alltraps
8010589d:	e9 9d f7 ff ff       	jmp    8010503f <alltraps>

801058a2 <vector120>:
.globl vector120
vector120:
  pushl $0
801058a2:	6a 00                	push   $0x0
  pushl $120
801058a4:	6a 78                	push   $0x78
  jmp alltraps
801058a6:	e9 94 f7 ff ff       	jmp    8010503f <alltraps>

801058ab <vector121>:
.globl vector121
vector121:
  pushl $0
801058ab:	6a 00                	push   $0x0
  pushl $121
801058ad:	6a 79                	push   $0x79
  jmp alltraps
801058af:	e9 8b f7 ff ff       	jmp    8010503f <alltraps>

801058b4 <vector122>:
.globl vector122
vector122:
  pushl $0
801058b4:	6a 00                	push   $0x0
  pushl $122
801058b6:	6a 7a                	push   $0x7a
  jmp alltraps
801058b8:	e9 82 f7 ff ff       	jmp    8010503f <alltraps>

801058bd <vector123>:
.globl vector123
vector123:
  pushl $0
801058bd:	6a 00                	push   $0x0
  pushl $123
801058bf:	6a 7b                	push   $0x7b
  jmp alltraps
801058c1:	e9 79 f7 ff ff       	jmp    8010503f <alltraps>

801058c6 <vector124>:
.globl vector124
vector124:
  pushl $0
801058c6:	6a 00                	push   $0x0
  pushl $124
801058c8:	6a 7c                	push   $0x7c
  jmp alltraps
801058ca:	e9 70 f7 ff ff       	jmp    8010503f <alltraps>

801058cf <vector125>:
.globl vector125
vector125:
  pushl $0
801058cf:	6a 00                	push   $0x0
  pushl $125
801058d1:	6a 7d                	push   $0x7d
  jmp alltraps
801058d3:	e9 67 f7 ff ff       	jmp    8010503f <alltraps>

801058d8 <vector126>:
.globl vector126
vector126:
  pushl $0
801058d8:	6a 00                	push   $0x0
  pushl $126
801058da:	6a 7e                	push   $0x7e
  jmp alltraps
801058dc:	e9 5e f7 ff ff       	jmp    8010503f <alltraps>

801058e1 <vector127>:
.globl vector127
vector127:
  pushl $0
801058e1:	6a 00                	push   $0x0
  pushl $127
801058e3:	6a 7f                	push   $0x7f
  jmp alltraps
801058e5:	e9 55 f7 ff ff       	jmp    8010503f <alltraps>

801058ea <vector128>:
.globl vector128
vector128:
  pushl $0
801058ea:	6a 00                	push   $0x0
  pushl $128
801058ec:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801058f1:	e9 49 f7 ff ff       	jmp    8010503f <alltraps>

801058f6 <vector129>:
.globl vector129
vector129:
  pushl $0
801058f6:	6a 00                	push   $0x0
  pushl $129
801058f8:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801058fd:	e9 3d f7 ff ff       	jmp    8010503f <alltraps>

80105902 <vector130>:
.globl vector130
vector130:
  pushl $0
80105902:	6a 00                	push   $0x0
  pushl $130
80105904:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80105909:	e9 31 f7 ff ff       	jmp    8010503f <alltraps>

8010590e <vector131>:
.globl vector131
vector131:
  pushl $0
8010590e:	6a 00                	push   $0x0
  pushl $131
80105910:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80105915:	e9 25 f7 ff ff       	jmp    8010503f <alltraps>

8010591a <vector132>:
.globl vector132
vector132:
  pushl $0
8010591a:	6a 00                	push   $0x0
  pushl $132
8010591c:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80105921:	e9 19 f7 ff ff       	jmp    8010503f <alltraps>

80105926 <vector133>:
.globl vector133
vector133:
  pushl $0
80105926:	6a 00                	push   $0x0
  pushl $133
80105928:	68 85 00 00 00       	push   $0x85
  jmp alltraps
8010592d:	e9 0d f7 ff ff       	jmp    8010503f <alltraps>

80105932 <vector134>:
.globl vector134
vector134:
  pushl $0
80105932:	6a 00                	push   $0x0
  pushl $134
80105934:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80105939:	e9 01 f7 ff ff       	jmp    8010503f <alltraps>

8010593e <vector135>:
.globl vector135
vector135:
  pushl $0
8010593e:	6a 00                	push   $0x0
  pushl $135
80105940:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80105945:	e9 f5 f6 ff ff       	jmp    8010503f <alltraps>

8010594a <vector136>:
.globl vector136
vector136:
  pushl $0
8010594a:	6a 00                	push   $0x0
  pushl $136
8010594c:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80105951:	e9 e9 f6 ff ff       	jmp    8010503f <alltraps>

80105956 <vector137>:
.globl vector137
vector137:
  pushl $0
80105956:	6a 00                	push   $0x0
  pushl $137
80105958:	68 89 00 00 00       	push   $0x89
  jmp alltraps
8010595d:	e9 dd f6 ff ff       	jmp    8010503f <alltraps>

80105962 <vector138>:
.globl vector138
vector138:
  pushl $0
80105962:	6a 00                	push   $0x0
  pushl $138
80105964:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80105969:	e9 d1 f6 ff ff       	jmp    8010503f <alltraps>

8010596e <vector139>:
.globl vector139
vector139:
  pushl $0
8010596e:	6a 00                	push   $0x0
  pushl $139
80105970:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80105975:	e9 c5 f6 ff ff       	jmp    8010503f <alltraps>

8010597a <vector140>:
.globl vector140
vector140:
  pushl $0
8010597a:	6a 00                	push   $0x0
  pushl $140
8010597c:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80105981:	e9 b9 f6 ff ff       	jmp    8010503f <alltraps>

80105986 <vector141>:
.globl vector141
vector141:
  pushl $0
80105986:	6a 00                	push   $0x0
  pushl $141
80105988:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
8010598d:	e9 ad f6 ff ff       	jmp    8010503f <alltraps>

80105992 <vector142>:
.globl vector142
vector142:
  pushl $0
80105992:	6a 00                	push   $0x0
  pushl $142
80105994:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80105999:	e9 a1 f6 ff ff       	jmp    8010503f <alltraps>

8010599e <vector143>:
.globl vector143
vector143:
  pushl $0
8010599e:	6a 00                	push   $0x0
  pushl $143
801059a0:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
801059a5:	e9 95 f6 ff ff       	jmp    8010503f <alltraps>

801059aa <vector144>:
.globl vector144
vector144:
  pushl $0
801059aa:	6a 00                	push   $0x0
  pushl $144
801059ac:	68 90 00 00 00       	push   $0x90
  jmp alltraps
801059b1:	e9 89 f6 ff ff       	jmp    8010503f <alltraps>

801059b6 <vector145>:
.globl vector145
vector145:
  pushl $0
801059b6:	6a 00                	push   $0x0
  pushl $145
801059b8:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801059bd:	e9 7d f6 ff ff       	jmp    8010503f <alltraps>

801059c2 <vector146>:
.globl vector146
vector146:
  pushl $0
801059c2:	6a 00                	push   $0x0
  pushl $146
801059c4:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801059c9:	e9 71 f6 ff ff       	jmp    8010503f <alltraps>

801059ce <vector147>:
.globl vector147
vector147:
  pushl $0
801059ce:	6a 00                	push   $0x0
  pushl $147
801059d0:	68 93 00 00 00       	push   $0x93
  jmp alltraps
801059d5:	e9 65 f6 ff ff       	jmp    8010503f <alltraps>

801059da <vector148>:
.globl vector148
vector148:
  pushl $0
801059da:	6a 00                	push   $0x0
  pushl $148
801059dc:	68 94 00 00 00       	push   $0x94
  jmp alltraps
801059e1:	e9 59 f6 ff ff       	jmp    8010503f <alltraps>

801059e6 <vector149>:
.globl vector149
vector149:
  pushl $0
801059e6:	6a 00                	push   $0x0
  pushl $149
801059e8:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801059ed:	e9 4d f6 ff ff       	jmp    8010503f <alltraps>

801059f2 <vector150>:
.globl vector150
vector150:
  pushl $0
801059f2:	6a 00                	push   $0x0
  pushl $150
801059f4:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801059f9:	e9 41 f6 ff ff       	jmp    8010503f <alltraps>

801059fe <vector151>:
.globl vector151
vector151:
  pushl $0
801059fe:	6a 00                	push   $0x0
  pushl $151
80105a00:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80105a05:	e9 35 f6 ff ff       	jmp    8010503f <alltraps>

80105a0a <vector152>:
.globl vector152
vector152:
  pushl $0
80105a0a:	6a 00                	push   $0x0
  pushl $152
80105a0c:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80105a11:	e9 29 f6 ff ff       	jmp    8010503f <alltraps>

80105a16 <vector153>:
.globl vector153
vector153:
  pushl $0
80105a16:	6a 00                	push   $0x0
  pushl $153
80105a18:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80105a1d:	e9 1d f6 ff ff       	jmp    8010503f <alltraps>

80105a22 <vector154>:
.globl vector154
vector154:
  pushl $0
80105a22:	6a 00                	push   $0x0
  pushl $154
80105a24:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80105a29:	e9 11 f6 ff ff       	jmp    8010503f <alltraps>

80105a2e <vector155>:
.globl vector155
vector155:
  pushl $0
80105a2e:	6a 00                	push   $0x0
  pushl $155
80105a30:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80105a35:	e9 05 f6 ff ff       	jmp    8010503f <alltraps>

80105a3a <vector156>:
.globl vector156
vector156:
  pushl $0
80105a3a:	6a 00                	push   $0x0
  pushl $156
80105a3c:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80105a41:	e9 f9 f5 ff ff       	jmp    8010503f <alltraps>

80105a46 <vector157>:
.globl vector157
vector157:
  pushl $0
80105a46:	6a 00                	push   $0x0
  pushl $157
80105a48:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80105a4d:	e9 ed f5 ff ff       	jmp    8010503f <alltraps>

80105a52 <vector158>:
.globl vector158
vector158:
  pushl $0
80105a52:	6a 00                	push   $0x0
  pushl $158
80105a54:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80105a59:	e9 e1 f5 ff ff       	jmp    8010503f <alltraps>

80105a5e <vector159>:
.globl vector159
vector159:
  pushl $0
80105a5e:	6a 00                	push   $0x0
  pushl $159
80105a60:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80105a65:	e9 d5 f5 ff ff       	jmp    8010503f <alltraps>

80105a6a <vector160>:
.globl vector160
vector160:
  pushl $0
80105a6a:	6a 00                	push   $0x0
  pushl $160
80105a6c:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80105a71:	e9 c9 f5 ff ff       	jmp    8010503f <alltraps>

80105a76 <vector161>:
.globl vector161
vector161:
  pushl $0
80105a76:	6a 00                	push   $0x0
  pushl $161
80105a78:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80105a7d:	e9 bd f5 ff ff       	jmp    8010503f <alltraps>

80105a82 <vector162>:
.globl vector162
vector162:
  pushl $0
80105a82:	6a 00                	push   $0x0
  pushl $162
80105a84:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105a89:	e9 b1 f5 ff ff       	jmp    8010503f <alltraps>

80105a8e <vector163>:
.globl vector163
vector163:
  pushl $0
80105a8e:	6a 00                	push   $0x0
  pushl $163
80105a90:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105a95:	e9 a5 f5 ff ff       	jmp    8010503f <alltraps>

80105a9a <vector164>:
.globl vector164
vector164:
  pushl $0
80105a9a:	6a 00                	push   $0x0
  pushl $164
80105a9c:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80105aa1:	e9 99 f5 ff ff       	jmp    8010503f <alltraps>

80105aa6 <vector165>:
.globl vector165
vector165:
  pushl $0
80105aa6:	6a 00                	push   $0x0
  pushl $165
80105aa8:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80105aad:	e9 8d f5 ff ff       	jmp    8010503f <alltraps>

80105ab2 <vector166>:
.globl vector166
vector166:
  pushl $0
80105ab2:	6a 00                	push   $0x0
  pushl $166
80105ab4:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105ab9:	e9 81 f5 ff ff       	jmp    8010503f <alltraps>

80105abe <vector167>:
.globl vector167
vector167:
  pushl $0
80105abe:	6a 00                	push   $0x0
  pushl $167
80105ac0:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105ac5:	e9 75 f5 ff ff       	jmp    8010503f <alltraps>

80105aca <vector168>:
.globl vector168
vector168:
  pushl $0
80105aca:	6a 00                	push   $0x0
  pushl $168
80105acc:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105ad1:	e9 69 f5 ff ff       	jmp    8010503f <alltraps>

80105ad6 <vector169>:
.globl vector169
vector169:
  pushl $0
80105ad6:	6a 00                	push   $0x0
  pushl $169
80105ad8:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80105add:	e9 5d f5 ff ff       	jmp    8010503f <alltraps>

80105ae2 <vector170>:
.globl vector170
vector170:
  pushl $0
80105ae2:	6a 00                	push   $0x0
  pushl $170
80105ae4:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105ae9:	e9 51 f5 ff ff       	jmp    8010503f <alltraps>

80105aee <vector171>:
.globl vector171
vector171:
  pushl $0
80105aee:	6a 00                	push   $0x0
  pushl $171
80105af0:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105af5:	e9 45 f5 ff ff       	jmp    8010503f <alltraps>

80105afa <vector172>:
.globl vector172
vector172:
  pushl $0
80105afa:	6a 00                	push   $0x0
  pushl $172
80105afc:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105b01:	e9 39 f5 ff ff       	jmp    8010503f <alltraps>

80105b06 <vector173>:
.globl vector173
vector173:
  pushl $0
80105b06:	6a 00                	push   $0x0
  pushl $173
80105b08:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80105b0d:	e9 2d f5 ff ff       	jmp    8010503f <alltraps>

80105b12 <vector174>:
.globl vector174
vector174:
  pushl $0
80105b12:	6a 00                	push   $0x0
  pushl $174
80105b14:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105b19:	e9 21 f5 ff ff       	jmp    8010503f <alltraps>

80105b1e <vector175>:
.globl vector175
vector175:
  pushl $0
80105b1e:	6a 00                	push   $0x0
  pushl $175
80105b20:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105b25:	e9 15 f5 ff ff       	jmp    8010503f <alltraps>

80105b2a <vector176>:
.globl vector176
vector176:
  pushl $0
80105b2a:	6a 00                	push   $0x0
  pushl $176
80105b2c:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105b31:	e9 09 f5 ff ff       	jmp    8010503f <alltraps>

80105b36 <vector177>:
.globl vector177
vector177:
  pushl $0
80105b36:	6a 00                	push   $0x0
  pushl $177
80105b38:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105b3d:	e9 fd f4 ff ff       	jmp    8010503f <alltraps>

80105b42 <vector178>:
.globl vector178
vector178:
  pushl $0
80105b42:	6a 00                	push   $0x0
  pushl $178
80105b44:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105b49:	e9 f1 f4 ff ff       	jmp    8010503f <alltraps>

80105b4e <vector179>:
.globl vector179
vector179:
  pushl $0
80105b4e:	6a 00                	push   $0x0
  pushl $179
80105b50:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105b55:	e9 e5 f4 ff ff       	jmp    8010503f <alltraps>

80105b5a <vector180>:
.globl vector180
vector180:
  pushl $0
80105b5a:	6a 00                	push   $0x0
  pushl $180
80105b5c:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105b61:	e9 d9 f4 ff ff       	jmp    8010503f <alltraps>

80105b66 <vector181>:
.globl vector181
vector181:
  pushl $0
80105b66:	6a 00                	push   $0x0
  pushl $181
80105b68:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105b6d:	e9 cd f4 ff ff       	jmp    8010503f <alltraps>

80105b72 <vector182>:
.globl vector182
vector182:
  pushl $0
80105b72:	6a 00                	push   $0x0
  pushl $182
80105b74:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105b79:	e9 c1 f4 ff ff       	jmp    8010503f <alltraps>

80105b7e <vector183>:
.globl vector183
vector183:
  pushl $0
80105b7e:	6a 00                	push   $0x0
  pushl $183
80105b80:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105b85:	e9 b5 f4 ff ff       	jmp    8010503f <alltraps>

80105b8a <vector184>:
.globl vector184
vector184:
  pushl $0
80105b8a:	6a 00                	push   $0x0
  pushl $184
80105b8c:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105b91:	e9 a9 f4 ff ff       	jmp    8010503f <alltraps>

80105b96 <vector185>:
.globl vector185
vector185:
  pushl $0
80105b96:	6a 00                	push   $0x0
  pushl $185
80105b98:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105b9d:	e9 9d f4 ff ff       	jmp    8010503f <alltraps>

80105ba2 <vector186>:
.globl vector186
vector186:
  pushl $0
80105ba2:	6a 00                	push   $0x0
  pushl $186
80105ba4:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105ba9:	e9 91 f4 ff ff       	jmp    8010503f <alltraps>

80105bae <vector187>:
.globl vector187
vector187:
  pushl $0
80105bae:	6a 00                	push   $0x0
  pushl $187
80105bb0:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105bb5:	e9 85 f4 ff ff       	jmp    8010503f <alltraps>

80105bba <vector188>:
.globl vector188
vector188:
  pushl $0
80105bba:	6a 00                	push   $0x0
  pushl $188
80105bbc:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105bc1:	e9 79 f4 ff ff       	jmp    8010503f <alltraps>

80105bc6 <vector189>:
.globl vector189
vector189:
  pushl $0
80105bc6:	6a 00                	push   $0x0
  pushl $189
80105bc8:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105bcd:	e9 6d f4 ff ff       	jmp    8010503f <alltraps>

80105bd2 <vector190>:
.globl vector190
vector190:
  pushl $0
80105bd2:	6a 00                	push   $0x0
  pushl $190
80105bd4:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105bd9:	e9 61 f4 ff ff       	jmp    8010503f <alltraps>

80105bde <vector191>:
.globl vector191
vector191:
  pushl $0
80105bde:	6a 00                	push   $0x0
  pushl $191
80105be0:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105be5:	e9 55 f4 ff ff       	jmp    8010503f <alltraps>

80105bea <vector192>:
.globl vector192
vector192:
  pushl $0
80105bea:	6a 00                	push   $0x0
  pushl $192
80105bec:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105bf1:	e9 49 f4 ff ff       	jmp    8010503f <alltraps>

80105bf6 <vector193>:
.globl vector193
vector193:
  pushl $0
80105bf6:	6a 00                	push   $0x0
  pushl $193
80105bf8:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105bfd:	e9 3d f4 ff ff       	jmp    8010503f <alltraps>

80105c02 <vector194>:
.globl vector194
vector194:
  pushl $0
80105c02:	6a 00                	push   $0x0
  pushl $194
80105c04:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105c09:	e9 31 f4 ff ff       	jmp    8010503f <alltraps>

80105c0e <vector195>:
.globl vector195
vector195:
  pushl $0
80105c0e:	6a 00                	push   $0x0
  pushl $195
80105c10:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105c15:	e9 25 f4 ff ff       	jmp    8010503f <alltraps>

80105c1a <vector196>:
.globl vector196
vector196:
  pushl $0
80105c1a:	6a 00                	push   $0x0
  pushl $196
80105c1c:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105c21:	e9 19 f4 ff ff       	jmp    8010503f <alltraps>

80105c26 <vector197>:
.globl vector197
vector197:
  pushl $0
80105c26:	6a 00                	push   $0x0
  pushl $197
80105c28:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105c2d:	e9 0d f4 ff ff       	jmp    8010503f <alltraps>

80105c32 <vector198>:
.globl vector198
vector198:
  pushl $0
80105c32:	6a 00                	push   $0x0
  pushl $198
80105c34:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105c39:	e9 01 f4 ff ff       	jmp    8010503f <alltraps>

80105c3e <vector199>:
.globl vector199
vector199:
  pushl $0
80105c3e:	6a 00                	push   $0x0
  pushl $199
80105c40:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105c45:	e9 f5 f3 ff ff       	jmp    8010503f <alltraps>

80105c4a <vector200>:
.globl vector200
vector200:
  pushl $0
80105c4a:	6a 00                	push   $0x0
  pushl $200
80105c4c:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105c51:	e9 e9 f3 ff ff       	jmp    8010503f <alltraps>

80105c56 <vector201>:
.globl vector201
vector201:
  pushl $0
80105c56:	6a 00                	push   $0x0
  pushl $201
80105c58:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105c5d:	e9 dd f3 ff ff       	jmp    8010503f <alltraps>

80105c62 <vector202>:
.globl vector202
vector202:
  pushl $0
80105c62:	6a 00                	push   $0x0
  pushl $202
80105c64:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105c69:	e9 d1 f3 ff ff       	jmp    8010503f <alltraps>

80105c6e <vector203>:
.globl vector203
vector203:
  pushl $0
80105c6e:	6a 00                	push   $0x0
  pushl $203
80105c70:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105c75:	e9 c5 f3 ff ff       	jmp    8010503f <alltraps>

80105c7a <vector204>:
.globl vector204
vector204:
  pushl $0
80105c7a:	6a 00                	push   $0x0
  pushl $204
80105c7c:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105c81:	e9 b9 f3 ff ff       	jmp    8010503f <alltraps>

80105c86 <vector205>:
.globl vector205
vector205:
  pushl $0
80105c86:	6a 00                	push   $0x0
  pushl $205
80105c88:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105c8d:	e9 ad f3 ff ff       	jmp    8010503f <alltraps>

80105c92 <vector206>:
.globl vector206
vector206:
  pushl $0
80105c92:	6a 00                	push   $0x0
  pushl $206
80105c94:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105c99:	e9 a1 f3 ff ff       	jmp    8010503f <alltraps>

80105c9e <vector207>:
.globl vector207
vector207:
  pushl $0
80105c9e:	6a 00                	push   $0x0
  pushl $207
80105ca0:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105ca5:	e9 95 f3 ff ff       	jmp    8010503f <alltraps>

80105caa <vector208>:
.globl vector208
vector208:
  pushl $0
80105caa:	6a 00                	push   $0x0
  pushl $208
80105cac:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105cb1:	e9 89 f3 ff ff       	jmp    8010503f <alltraps>

80105cb6 <vector209>:
.globl vector209
vector209:
  pushl $0
80105cb6:	6a 00                	push   $0x0
  pushl $209
80105cb8:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105cbd:	e9 7d f3 ff ff       	jmp    8010503f <alltraps>

80105cc2 <vector210>:
.globl vector210
vector210:
  pushl $0
80105cc2:	6a 00                	push   $0x0
  pushl $210
80105cc4:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105cc9:	e9 71 f3 ff ff       	jmp    8010503f <alltraps>

80105cce <vector211>:
.globl vector211
vector211:
  pushl $0
80105cce:	6a 00                	push   $0x0
  pushl $211
80105cd0:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105cd5:	e9 65 f3 ff ff       	jmp    8010503f <alltraps>

80105cda <vector212>:
.globl vector212
vector212:
  pushl $0
80105cda:	6a 00                	push   $0x0
  pushl $212
80105cdc:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105ce1:	e9 59 f3 ff ff       	jmp    8010503f <alltraps>

80105ce6 <vector213>:
.globl vector213
vector213:
  pushl $0
80105ce6:	6a 00                	push   $0x0
  pushl $213
80105ce8:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105ced:	e9 4d f3 ff ff       	jmp    8010503f <alltraps>

80105cf2 <vector214>:
.globl vector214
vector214:
  pushl $0
80105cf2:	6a 00                	push   $0x0
  pushl $214
80105cf4:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105cf9:	e9 41 f3 ff ff       	jmp    8010503f <alltraps>

80105cfe <vector215>:
.globl vector215
vector215:
  pushl $0
80105cfe:	6a 00                	push   $0x0
  pushl $215
80105d00:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105d05:	e9 35 f3 ff ff       	jmp    8010503f <alltraps>

80105d0a <vector216>:
.globl vector216
vector216:
  pushl $0
80105d0a:	6a 00                	push   $0x0
  pushl $216
80105d0c:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105d11:	e9 29 f3 ff ff       	jmp    8010503f <alltraps>

80105d16 <vector217>:
.globl vector217
vector217:
  pushl $0
80105d16:	6a 00                	push   $0x0
  pushl $217
80105d18:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105d1d:	e9 1d f3 ff ff       	jmp    8010503f <alltraps>

80105d22 <vector218>:
.globl vector218
vector218:
  pushl $0
80105d22:	6a 00                	push   $0x0
  pushl $218
80105d24:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105d29:	e9 11 f3 ff ff       	jmp    8010503f <alltraps>

80105d2e <vector219>:
.globl vector219
vector219:
  pushl $0
80105d2e:	6a 00                	push   $0x0
  pushl $219
80105d30:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105d35:	e9 05 f3 ff ff       	jmp    8010503f <alltraps>

80105d3a <vector220>:
.globl vector220
vector220:
  pushl $0
80105d3a:	6a 00                	push   $0x0
  pushl $220
80105d3c:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105d41:	e9 f9 f2 ff ff       	jmp    8010503f <alltraps>

80105d46 <vector221>:
.globl vector221
vector221:
  pushl $0
80105d46:	6a 00                	push   $0x0
  pushl $221
80105d48:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105d4d:	e9 ed f2 ff ff       	jmp    8010503f <alltraps>

80105d52 <vector222>:
.globl vector222
vector222:
  pushl $0
80105d52:	6a 00                	push   $0x0
  pushl $222
80105d54:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105d59:	e9 e1 f2 ff ff       	jmp    8010503f <alltraps>

80105d5e <vector223>:
.globl vector223
vector223:
  pushl $0
80105d5e:	6a 00                	push   $0x0
  pushl $223
80105d60:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105d65:	e9 d5 f2 ff ff       	jmp    8010503f <alltraps>

80105d6a <vector224>:
.globl vector224
vector224:
  pushl $0
80105d6a:	6a 00                	push   $0x0
  pushl $224
80105d6c:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105d71:	e9 c9 f2 ff ff       	jmp    8010503f <alltraps>

80105d76 <vector225>:
.globl vector225
vector225:
  pushl $0
80105d76:	6a 00                	push   $0x0
  pushl $225
80105d78:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105d7d:	e9 bd f2 ff ff       	jmp    8010503f <alltraps>

80105d82 <vector226>:
.globl vector226
vector226:
  pushl $0
80105d82:	6a 00                	push   $0x0
  pushl $226
80105d84:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105d89:	e9 b1 f2 ff ff       	jmp    8010503f <alltraps>

80105d8e <vector227>:
.globl vector227
vector227:
  pushl $0
80105d8e:	6a 00                	push   $0x0
  pushl $227
80105d90:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105d95:	e9 a5 f2 ff ff       	jmp    8010503f <alltraps>

80105d9a <vector228>:
.globl vector228
vector228:
  pushl $0
80105d9a:	6a 00                	push   $0x0
  pushl $228
80105d9c:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105da1:	e9 99 f2 ff ff       	jmp    8010503f <alltraps>

80105da6 <vector229>:
.globl vector229
vector229:
  pushl $0
80105da6:	6a 00                	push   $0x0
  pushl $229
80105da8:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105dad:	e9 8d f2 ff ff       	jmp    8010503f <alltraps>

80105db2 <vector230>:
.globl vector230
vector230:
  pushl $0
80105db2:	6a 00                	push   $0x0
  pushl $230
80105db4:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105db9:	e9 81 f2 ff ff       	jmp    8010503f <alltraps>

80105dbe <vector231>:
.globl vector231
vector231:
  pushl $0
80105dbe:	6a 00                	push   $0x0
  pushl $231
80105dc0:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105dc5:	e9 75 f2 ff ff       	jmp    8010503f <alltraps>

80105dca <vector232>:
.globl vector232
vector232:
  pushl $0
80105dca:	6a 00                	push   $0x0
  pushl $232
80105dcc:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105dd1:	e9 69 f2 ff ff       	jmp    8010503f <alltraps>

80105dd6 <vector233>:
.globl vector233
vector233:
  pushl $0
80105dd6:	6a 00                	push   $0x0
  pushl $233
80105dd8:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105ddd:	e9 5d f2 ff ff       	jmp    8010503f <alltraps>

80105de2 <vector234>:
.globl vector234
vector234:
  pushl $0
80105de2:	6a 00                	push   $0x0
  pushl $234
80105de4:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105de9:	e9 51 f2 ff ff       	jmp    8010503f <alltraps>

80105dee <vector235>:
.globl vector235
vector235:
  pushl $0
80105dee:	6a 00                	push   $0x0
  pushl $235
80105df0:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105df5:	e9 45 f2 ff ff       	jmp    8010503f <alltraps>

80105dfa <vector236>:
.globl vector236
vector236:
  pushl $0
80105dfa:	6a 00                	push   $0x0
  pushl $236
80105dfc:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105e01:	e9 39 f2 ff ff       	jmp    8010503f <alltraps>

80105e06 <vector237>:
.globl vector237
vector237:
  pushl $0
80105e06:	6a 00                	push   $0x0
  pushl $237
80105e08:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105e0d:	e9 2d f2 ff ff       	jmp    8010503f <alltraps>

80105e12 <vector238>:
.globl vector238
vector238:
  pushl $0
80105e12:	6a 00                	push   $0x0
  pushl $238
80105e14:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105e19:	e9 21 f2 ff ff       	jmp    8010503f <alltraps>

80105e1e <vector239>:
.globl vector239
vector239:
  pushl $0
80105e1e:	6a 00                	push   $0x0
  pushl $239
80105e20:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105e25:	e9 15 f2 ff ff       	jmp    8010503f <alltraps>

80105e2a <vector240>:
.globl vector240
vector240:
  pushl $0
80105e2a:	6a 00                	push   $0x0
  pushl $240
80105e2c:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105e31:	e9 09 f2 ff ff       	jmp    8010503f <alltraps>

80105e36 <vector241>:
.globl vector241
vector241:
  pushl $0
80105e36:	6a 00                	push   $0x0
  pushl $241
80105e38:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105e3d:	e9 fd f1 ff ff       	jmp    8010503f <alltraps>

80105e42 <vector242>:
.globl vector242
vector242:
  pushl $0
80105e42:	6a 00                	push   $0x0
  pushl $242
80105e44:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105e49:	e9 f1 f1 ff ff       	jmp    8010503f <alltraps>

80105e4e <vector243>:
.globl vector243
vector243:
  pushl $0
80105e4e:	6a 00                	push   $0x0
  pushl $243
80105e50:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105e55:	e9 e5 f1 ff ff       	jmp    8010503f <alltraps>

80105e5a <vector244>:
.globl vector244
vector244:
  pushl $0
80105e5a:	6a 00                	push   $0x0
  pushl $244
80105e5c:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105e61:	e9 d9 f1 ff ff       	jmp    8010503f <alltraps>

80105e66 <vector245>:
.globl vector245
vector245:
  pushl $0
80105e66:	6a 00                	push   $0x0
  pushl $245
80105e68:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105e6d:	e9 cd f1 ff ff       	jmp    8010503f <alltraps>

80105e72 <vector246>:
.globl vector246
vector246:
  pushl $0
80105e72:	6a 00                	push   $0x0
  pushl $246
80105e74:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105e79:	e9 c1 f1 ff ff       	jmp    8010503f <alltraps>

80105e7e <vector247>:
.globl vector247
vector247:
  pushl $0
80105e7e:	6a 00                	push   $0x0
  pushl $247
80105e80:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105e85:	e9 b5 f1 ff ff       	jmp    8010503f <alltraps>

80105e8a <vector248>:
.globl vector248
vector248:
  pushl $0
80105e8a:	6a 00                	push   $0x0
  pushl $248
80105e8c:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105e91:	e9 a9 f1 ff ff       	jmp    8010503f <alltraps>

80105e96 <vector249>:
.globl vector249
vector249:
  pushl $0
80105e96:	6a 00                	push   $0x0
  pushl $249
80105e98:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105e9d:	e9 9d f1 ff ff       	jmp    8010503f <alltraps>

80105ea2 <vector250>:
.globl vector250
vector250:
  pushl $0
80105ea2:	6a 00                	push   $0x0
  pushl $250
80105ea4:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105ea9:	e9 91 f1 ff ff       	jmp    8010503f <alltraps>

80105eae <vector251>:
.globl vector251
vector251:
  pushl $0
80105eae:	6a 00                	push   $0x0
  pushl $251
80105eb0:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105eb5:	e9 85 f1 ff ff       	jmp    8010503f <alltraps>

80105eba <vector252>:
.globl vector252
vector252:
  pushl $0
80105eba:	6a 00                	push   $0x0
  pushl $252
80105ebc:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105ec1:	e9 79 f1 ff ff       	jmp    8010503f <alltraps>

80105ec6 <vector253>:
.globl vector253
vector253:
  pushl $0
80105ec6:	6a 00                	push   $0x0
  pushl $253
80105ec8:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105ecd:	e9 6d f1 ff ff       	jmp    8010503f <alltraps>

80105ed2 <vector254>:
.globl vector254
vector254:
  pushl $0
80105ed2:	6a 00                	push   $0x0
  pushl $254
80105ed4:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105ed9:	e9 61 f1 ff ff       	jmp    8010503f <alltraps>

80105ede <vector255>:
.globl vector255
vector255:
  pushl $0
80105ede:	6a 00                	push   $0x0
  pushl $255
80105ee0:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105ee5:	e9 55 f1 ff ff       	jmp    8010503f <alltraps>

80105eea <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105eea:	55                   	push   %ebp
80105eeb:	89 e5                	mov    %esp,%ebp
80105eed:	57                   	push   %edi
80105eee:	56                   	push   %esi
80105eef:	53                   	push   %ebx
80105ef0:	83 ec 0c             	sub    $0xc,%esp
80105ef3:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105ef5:	c1 ea 16             	shr    $0x16,%edx
80105ef8:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105efb:	8b 1f                	mov    (%edi),%ebx
80105efd:	f6 c3 01             	test   $0x1,%bl
80105f00:	74 22                	je     80105f24 <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105f02:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105f08:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105f0e:	c1 ee 0c             	shr    $0xc,%esi
80105f11:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105f17:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105f1a:	89 d8                	mov    %ebx,%eax
80105f1c:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105f1f:	5b                   	pop    %ebx
80105f20:	5e                   	pop    %esi
80105f21:	5f                   	pop    %edi
80105f22:	5d                   	pop    %ebp
80105f23:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc2(-2)) == 0)
80105f24:	85 c9                	test   %ecx,%ecx
80105f26:	74 33                	je     80105f5b <walkpgdir+0x71>
80105f28:	83 ec 0c             	sub    $0xc,%esp
80105f2b:	6a fe                	push   $0xfffffffe
80105f2d:	e8 f3 c2 ff ff       	call   80102225 <kalloc2>
80105f32:	89 c3                	mov    %eax,%ebx
80105f34:	83 c4 10             	add    $0x10,%esp
80105f37:	85 c0                	test   %eax,%eax
80105f39:	74 df                	je     80105f1a <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105f3b:	83 ec 04             	sub    $0x4,%esp
80105f3e:	68 00 10 00 00       	push   $0x1000
80105f43:	6a 00                	push   $0x0
80105f45:	50                   	push   %eax
80105f46:	e8 f6 df ff ff       	call   80103f41 <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105f4b:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105f51:	83 c8 07             	or     $0x7,%eax
80105f54:	89 07                	mov    %eax,(%edi)
80105f56:	83 c4 10             	add    $0x10,%esp
80105f59:	eb b3                	jmp    80105f0e <walkpgdir+0x24>
      return 0;
80105f5b:	bb 00 00 00 00       	mov    $0x0,%ebx
80105f60:	eb b8                	jmp    80105f1a <walkpgdir+0x30>

80105f62 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105f62:	55                   	push   %ebp
80105f63:	89 e5                	mov    %esp,%ebp
80105f65:	57                   	push   %edi
80105f66:	56                   	push   %esi
80105f67:	53                   	push   %ebx
80105f68:	83 ec 1c             	sub    $0x1c,%esp
80105f6b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105f6e:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105f71:	89 d3                	mov    %edx,%ebx
80105f73:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105f79:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105f7d:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105f83:	b9 01 00 00 00       	mov    $0x1,%ecx
80105f88:	89 da                	mov    %ebx,%edx
80105f8a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105f8d:	e8 58 ff ff ff       	call   80105eea <walkpgdir>
80105f92:	85 c0                	test   %eax,%eax
80105f94:	74 2e                	je     80105fc4 <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105f96:	f6 00 01             	testb  $0x1,(%eax)
80105f99:	75 1c                	jne    80105fb7 <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105f9b:	89 f2                	mov    %esi,%edx
80105f9d:	0b 55 0c             	or     0xc(%ebp),%edx
80105fa0:	83 ca 01             	or     $0x1,%edx
80105fa3:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105fa5:	39 fb                	cmp    %edi,%ebx
80105fa7:	74 28                	je     80105fd1 <mappages+0x6f>
      break;
    a += PGSIZE;
80105fa9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105faf:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105fb5:	eb cc                	jmp    80105f83 <mappages+0x21>
      panic("remap");
80105fb7:	83 ec 0c             	sub    $0xc,%esp
80105fba:	68 8c 70 10 80       	push   $0x8010708c
80105fbf:	e8 84 a3 ff ff       	call   80100348 <panic>
      return -1;
80105fc4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105fc9:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105fcc:	5b                   	pop    %ebx
80105fcd:	5e                   	pop    %esi
80105fce:	5f                   	pop    %edi
80105fcf:	5d                   	pop    %ebp
80105fd0:	c3                   	ret    
  return 0;
80105fd1:	b8 00 00 00 00       	mov    $0x0,%eax
80105fd6:	eb f1                	jmp    80105fc9 <mappages+0x67>

80105fd8 <seginit>:
{
80105fd8:	55                   	push   %ebp
80105fd9:	89 e5                	mov    %esp,%ebp
80105fdb:	53                   	push   %ebx
80105fdc:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105fdf:	e8 f4 d4 ff ff       	call   801034d8 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105fe4:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105fea:	66 c7 80 38 28 13 80 	movw   $0xffff,-0x7fecd7c8(%eax)
80105ff1:	ff ff 
80105ff3:	66 c7 80 3a 28 13 80 	movw   $0x0,-0x7fecd7c6(%eax)
80105ffa:	00 00 
80105ffc:	c6 80 3c 28 13 80 00 	movb   $0x0,-0x7fecd7c4(%eax)
80106003:	0f b6 88 3d 28 13 80 	movzbl -0x7fecd7c3(%eax),%ecx
8010600a:	83 e1 f0             	and    $0xfffffff0,%ecx
8010600d:	83 c9 1a             	or     $0x1a,%ecx
80106010:	83 e1 9f             	and    $0xffffff9f,%ecx
80106013:	83 c9 80             	or     $0xffffff80,%ecx
80106016:	88 88 3d 28 13 80    	mov    %cl,-0x7fecd7c3(%eax)
8010601c:	0f b6 88 3e 28 13 80 	movzbl -0x7fecd7c2(%eax),%ecx
80106023:	83 c9 0f             	or     $0xf,%ecx
80106026:	83 e1 cf             	and    $0xffffffcf,%ecx
80106029:	83 c9 c0             	or     $0xffffffc0,%ecx
8010602c:	88 88 3e 28 13 80    	mov    %cl,-0x7fecd7c2(%eax)
80106032:	c6 80 3f 28 13 80 00 	movb   $0x0,-0x7fecd7c1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80106039:	66 c7 80 40 28 13 80 	movw   $0xffff,-0x7fecd7c0(%eax)
80106040:	ff ff 
80106042:	66 c7 80 42 28 13 80 	movw   $0x0,-0x7fecd7be(%eax)
80106049:	00 00 
8010604b:	c6 80 44 28 13 80 00 	movb   $0x0,-0x7fecd7bc(%eax)
80106052:	0f b6 88 45 28 13 80 	movzbl -0x7fecd7bb(%eax),%ecx
80106059:	83 e1 f0             	and    $0xfffffff0,%ecx
8010605c:	83 c9 12             	or     $0x12,%ecx
8010605f:	83 e1 9f             	and    $0xffffff9f,%ecx
80106062:	83 c9 80             	or     $0xffffff80,%ecx
80106065:	88 88 45 28 13 80    	mov    %cl,-0x7fecd7bb(%eax)
8010606b:	0f b6 88 46 28 13 80 	movzbl -0x7fecd7ba(%eax),%ecx
80106072:	83 c9 0f             	or     $0xf,%ecx
80106075:	83 e1 cf             	and    $0xffffffcf,%ecx
80106078:	83 c9 c0             	or     $0xffffffc0,%ecx
8010607b:	88 88 46 28 13 80    	mov    %cl,-0x7fecd7ba(%eax)
80106081:	c6 80 47 28 13 80 00 	movb   $0x0,-0x7fecd7b9(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80106088:	66 c7 80 48 28 13 80 	movw   $0xffff,-0x7fecd7b8(%eax)
8010608f:	ff ff 
80106091:	66 c7 80 4a 28 13 80 	movw   $0x0,-0x7fecd7b6(%eax)
80106098:	00 00 
8010609a:	c6 80 4c 28 13 80 00 	movb   $0x0,-0x7fecd7b4(%eax)
801060a1:	c6 80 4d 28 13 80 fa 	movb   $0xfa,-0x7fecd7b3(%eax)
801060a8:	0f b6 88 4e 28 13 80 	movzbl -0x7fecd7b2(%eax),%ecx
801060af:	83 c9 0f             	or     $0xf,%ecx
801060b2:	83 e1 cf             	and    $0xffffffcf,%ecx
801060b5:	83 c9 c0             	or     $0xffffffc0,%ecx
801060b8:	88 88 4e 28 13 80    	mov    %cl,-0x7fecd7b2(%eax)
801060be:	c6 80 4f 28 13 80 00 	movb   $0x0,-0x7fecd7b1(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
801060c5:	66 c7 80 50 28 13 80 	movw   $0xffff,-0x7fecd7b0(%eax)
801060cc:	ff ff 
801060ce:	66 c7 80 52 28 13 80 	movw   $0x0,-0x7fecd7ae(%eax)
801060d5:	00 00 
801060d7:	c6 80 54 28 13 80 00 	movb   $0x0,-0x7fecd7ac(%eax)
801060de:	c6 80 55 28 13 80 f2 	movb   $0xf2,-0x7fecd7ab(%eax)
801060e5:	0f b6 88 56 28 13 80 	movzbl -0x7fecd7aa(%eax),%ecx
801060ec:	83 c9 0f             	or     $0xf,%ecx
801060ef:	83 e1 cf             	and    $0xffffffcf,%ecx
801060f2:	83 c9 c0             	or     $0xffffffc0,%ecx
801060f5:	88 88 56 28 13 80    	mov    %cl,-0x7fecd7aa(%eax)
801060fb:	c6 80 57 28 13 80 00 	movb   $0x0,-0x7fecd7a9(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80106102:	05 30 28 13 80       	add    $0x80132830,%eax
  pd[0] = size-1;
80106107:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
8010610d:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80106111:	c1 e8 10             	shr    $0x10,%eax
80106114:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
80106118:	8d 45 f2             	lea    -0xe(%ebp),%eax
8010611b:	0f 01 10             	lgdtl  (%eax)
}
8010611e:	83 c4 14             	add    $0x14,%esp
80106121:	5b                   	pop    %ebx
80106122:	5d                   	pop    %ebp
80106123:	c3                   	ret    

80106124 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80106124:	55                   	push   %ebp
80106125:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80106127:	a1 e4 54 13 80       	mov    0x801354e4,%eax
8010612c:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80106131:	0f 22 d8             	mov    %eax,%cr3
}
80106134:	5d                   	pop    %ebp
80106135:	c3                   	ret    

80106136 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80106136:	55                   	push   %ebp
80106137:	89 e5                	mov    %esp,%ebp
80106139:	57                   	push   %edi
8010613a:	56                   	push   %esi
8010613b:	53                   	push   %ebx
8010613c:	83 ec 1c             	sub    $0x1c,%esp
8010613f:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
80106142:	85 f6                	test   %esi,%esi
80106144:	0f 84 dd 00 00 00    	je     80106227 <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
8010614a:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
8010614e:	0f 84 e0 00 00 00    	je     80106234 <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
80106154:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
80106158:	0f 84 e3 00 00 00    	je     80106241 <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
8010615e:	e8 55 dc ff ff       	call   80103db8 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80106163:	e8 14 d3 ff ff       	call   8010347c <mycpu>
80106168:	89 c3                	mov    %eax,%ebx
8010616a:	e8 0d d3 ff ff       	call   8010347c <mycpu>
8010616f:	8d 78 08             	lea    0x8(%eax),%edi
80106172:	e8 05 d3 ff ff       	call   8010347c <mycpu>
80106177:	83 c0 08             	add    $0x8,%eax
8010617a:	c1 e8 10             	shr    $0x10,%eax
8010617d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106180:	e8 f7 d2 ff ff       	call   8010347c <mycpu>
80106185:	83 c0 08             	add    $0x8,%eax
80106188:	c1 e8 18             	shr    $0x18,%eax
8010618b:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80106192:	67 00 
80106194:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
8010619b:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
8010619f:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
801061a5:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
801061ac:	83 e2 f0             	and    $0xfffffff0,%edx
801061af:	83 ca 19             	or     $0x19,%edx
801061b2:	83 e2 9f             	and    $0xffffff9f,%edx
801061b5:	83 ca 80             	or     $0xffffff80,%edx
801061b8:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
801061be:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
801061c5:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
801061cb:	e8 ac d2 ff ff       	call   8010347c <mycpu>
801061d0:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801061d7:	83 e2 ef             	and    $0xffffffef,%edx
801061da:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
801061e0:	e8 97 d2 ff ff       	call   8010347c <mycpu>
801061e5:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
801061eb:	8b 5e 08             	mov    0x8(%esi),%ebx
801061ee:	e8 89 d2 ff ff       	call   8010347c <mycpu>
801061f3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801061f9:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
801061fc:	e8 7b d2 ff ff       	call   8010347c <mycpu>
80106201:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
80106207:	b8 28 00 00 00       	mov    $0x28,%eax
8010620c:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
8010620f:	8b 46 04             	mov    0x4(%esi),%eax
80106212:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
80106217:	0f 22 d8             	mov    %eax,%cr3
  popcli();
8010621a:	e8 d6 db ff ff       	call   80103df5 <popcli>
}
8010621f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106222:	5b                   	pop    %ebx
80106223:	5e                   	pop    %esi
80106224:	5f                   	pop    %edi
80106225:	5d                   	pop    %ebp
80106226:	c3                   	ret    
    panic("switchuvm: no process");
80106227:	83 ec 0c             	sub    $0xc,%esp
8010622a:	68 92 70 10 80       	push   $0x80107092
8010622f:	e8 14 a1 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
80106234:	83 ec 0c             	sub    $0xc,%esp
80106237:	68 a8 70 10 80       	push   $0x801070a8
8010623c:	e8 07 a1 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
80106241:	83 ec 0c             	sub    $0xc,%esp
80106244:	68 bd 70 10 80       	push   $0x801070bd
80106249:	e8 fa a0 ff ff       	call   80100348 <panic>

8010624e <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
8010624e:	55                   	push   %ebp
8010624f:	89 e5                	mov    %esp,%ebp
80106251:	56                   	push   %esi
80106252:	53                   	push   %ebx
80106253:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
80106256:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
8010625c:	77 51                	ja     801062af <inituvm+0x61>
    panic("inituvm: more than a page");
  mem = kalloc2(-2);
8010625e:	83 ec 0c             	sub    $0xc,%esp
80106261:	6a fe                	push   $0xfffffffe
80106263:	e8 bd bf ff ff       	call   80102225 <kalloc2>
80106268:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
8010626a:	83 c4 0c             	add    $0xc,%esp
8010626d:	68 00 10 00 00       	push   $0x1000
80106272:	6a 00                	push   $0x0
80106274:	50                   	push   %eax
80106275:	e8 c7 dc ff ff       	call   80103f41 <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
8010627a:	83 c4 08             	add    $0x8,%esp
8010627d:	6a 06                	push   $0x6
8010627f:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106285:	50                   	push   %eax
80106286:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010628b:	ba 00 00 00 00       	mov    $0x0,%edx
80106290:	8b 45 08             	mov    0x8(%ebp),%eax
80106293:	e8 ca fc ff ff       	call   80105f62 <mappages>
  memmove(mem, init, sz);
80106298:	83 c4 0c             	add    $0xc,%esp
8010629b:	56                   	push   %esi
8010629c:	ff 75 0c             	pushl  0xc(%ebp)
8010629f:	53                   	push   %ebx
801062a0:	e8 17 dd ff ff       	call   80103fbc <memmove>
}
801062a5:	83 c4 10             	add    $0x10,%esp
801062a8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801062ab:	5b                   	pop    %ebx
801062ac:	5e                   	pop    %esi
801062ad:	5d                   	pop    %ebp
801062ae:	c3                   	ret    
    panic("inituvm: more than a page");
801062af:	83 ec 0c             	sub    $0xc,%esp
801062b2:	68 d1 70 10 80       	push   $0x801070d1
801062b7:	e8 8c a0 ff ff       	call   80100348 <panic>

801062bc <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
801062bc:	55                   	push   %ebp
801062bd:	89 e5                	mov    %esp,%ebp
801062bf:	57                   	push   %edi
801062c0:	56                   	push   %esi
801062c1:	53                   	push   %ebx
801062c2:	83 ec 0c             	sub    $0xc,%esp
801062c5:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
801062c8:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
801062cf:	75 07                	jne    801062d8 <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
801062d1:	bb 00 00 00 00       	mov    $0x0,%ebx
801062d6:	eb 3c                	jmp    80106314 <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
801062d8:	83 ec 0c             	sub    $0xc,%esp
801062db:	68 8c 71 10 80       	push   $0x8010718c
801062e0:	e8 63 a0 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
801062e5:	83 ec 0c             	sub    $0xc,%esp
801062e8:	68 eb 70 10 80       	push   $0x801070eb
801062ed:	e8 56 a0 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
801062f2:	05 00 00 00 80       	add    $0x80000000,%eax
801062f7:	56                   	push   %esi
801062f8:	89 da                	mov    %ebx,%edx
801062fa:	03 55 14             	add    0x14(%ebp),%edx
801062fd:	52                   	push   %edx
801062fe:	50                   	push   %eax
801062ff:	ff 75 10             	pushl  0x10(%ebp)
80106302:	e8 6c b4 ff ff       	call   80101773 <readi>
80106307:	83 c4 10             	add    $0x10,%esp
8010630a:	39 f0                	cmp    %esi,%eax
8010630c:	75 47                	jne    80106355 <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
8010630e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106314:	39 fb                	cmp    %edi,%ebx
80106316:	73 30                	jae    80106348 <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80106318:	89 da                	mov    %ebx,%edx
8010631a:	03 55 0c             	add    0xc(%ebp),%edx
8010631d:	b9 00 00 00 00       	mov    $0x0,%ecx
80106322:	8b 45 08             	mov    0x8(%ebp),%eax
80106325:	e8 c0 fb ff ff       	call   80105eea <walkpgdir>
8010632a:	85 c0                	test   %eax,%eax
8010632c:	74 b7                	je     801062e5 <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
8010632e:	8b 00                	mov    (%eax),%eax
80106330:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
80106335:	89 fe                	mov    %edi,%esi
80106337:	29 de                	sub    %ebx,%esi
80106339:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
8010633f:	76 b1                	jbe    801062f2 <loaduvm+0x36>
      n = PGSIZE;
80106341:	be 00 10 00 00       	mov    $0x1000,%esi
80106346:	eb aa                	jmp    801062f2 <loaduvm+0x36>
      return -1;
  }
  return 0;
80106348:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010634d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106350:	5b                   	pop    %ebx
80106351:	5e                   	pop    %esi
80106352:	5f                   	pop    %edi
80106353:	5d                   	pop    %ebp
80106354:	c3                   	ret    
      return -1;
80106355:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010635a:	eb f1                	jmp    8010634d <loaduvm+0x91>

8010635c <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010635c:	55                   	push   %ebp
8010635d:	89 e5                	mov    %esp,%ebp
8010635f:	57                   	push   %edi
80106360:	56                   	push   %esi
80106361:	53                   	push   %ebx
80106362:	83 ec 0c             	sub    $0xc,%esp
80106365:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80106368:	39 7d 10             	cmp    %edi,0x10(%ebp)
8010636b:	73 11                	jae    8010637e <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
8010636d:	8b 45 10             	mov    0x10(%ebp),%eax
80106370:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106376:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
8010637c:	eb 19                	jmp    80106397 <deallocuvm+0x3b>
    return oldsz;
8010637e:	89 f8                	mov    %edi,%eax
80106380:	eb 64                	jmp    801063e6 <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
80106382:	c1 eb 16             	shr    $0x16,%ebx
80106385:	83 c3 01             	add    $0x1,%ebx
80106388:	c1 e3 16             	shl    $0x16,%ebx
8010638b:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106391:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106397:	39 fb                	cmp    %edi,%ebx
80106399:	73 48                	jae    801063e3 <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
8010639b:	b9 00 00 00 00       	mov    $0x0,%ecx
801063a0:	89 da                	mov    %ebx,%edx
801063a2:	8b 45 08             	mov    0x8(%ebp),%eax
801063a5:	e8 40 fb ff ff       	call   80105eea <walkpgdir>
801063aa:	89 c6                	mov    %eax,%esi
    if(!pte)
801063ac:	85 c0                	test   %eax,%eax
801063ae:	74 d2                	je     80106382 <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
801063b0:	8b 00                	mov    (%eax),%eax
801063b2:	a8 01                	test   $0x1,%al
801063b4:	74 db                	je     80106391 <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
801063b6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801063bb:	74 19                	je     801063d6 <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
801063bd:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801063c2:	83 ec 0c             	sub    $0xc,%esp
801063c5:	50                   	push   %eax
801063c6:	e8 fa bc ff ff       	call   801020c5 <kfree>
      *pte = 0;
801063cb:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
801063d1:	83 c4 10             	add    $0x10,%esp
801063d4:	eb bb                	jmp    80106391 <deallocuvm+0x35>
        panic("kfree");
801063d6:	83 ec 0c             	sub    $0xc,%esp
801063d9:	68 26 6a 10 80       	push   $0x80106a26
801063de:	e8 65 9f ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
801063e3:	8b 45 10             	mov    0x10(%ebp),%eax
}
801063e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
801063e9:	5b                   	pop    %ebx
801063ea:	5e                   	pop    %esi
801063eb:	5f                   	pop    %edi
801063ec:	5d                   	pop    %ebp
801063ed:	c3                   	ret    

801063ee <allocuvm>:
{
801063ee:	55                   	push   %ebp
801063ef:	89 e5                	mov    %esp,%ebp
801063f1:	57                   	push   %edi
801063f2:	56                   	push   %esi
801063f3:	53                   	push   %ebx
801063f4:	83 ec 1c             	sub    $0x1c,%esp
801063f7:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
801063fa:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801063fd:	85 ff                	test   %edi,%edi
801063ff:	0f 88 cf 00 00 00    	js     801064d4 <allocuvm+0xe6>
  if(newsz < oldsz)
80106405:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106408:	72 6a                	jb     80106474 <allocuvm+0x86>
  a = PGROUNDUP(oldsz);
8010640a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010640d:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106413:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
80106419:	39 fb                	cmp    %edi,%ebx
8010641b:	0f 83 ba 00 00 00    	jae    801064db <allocuvm+0xed>
    mem = kalloc2(myproc()->pid);
80106421:	e8 cd d0 ff ff       	call   801034f3 <myproc>
80106426:	83 ec 0c             	sub    $0xc,%esp
80106429:	ff 70 10             	pushl  0x10(%eax)
8010642c:	e8 f4 bd ff ff       	call   80102225 <kalloc2>
80106431:	89 c6                	mov    %eax,%esi
    if(mem == 0){
80106433:	83 c4 10             	add    $0x10,%esp
80106436:	85 c0                	test   %eax,%eax
80106438:	74 42                	je     8010647c <allocuvm+0x8e>
    memset(mem, 0, PGSIZE);
8010643a:	83 ec 04             	sub    $0x4,%esp
8010643d:	68 00 10 00 00       	push   $0x1000
80106442:	6a 00                	push   $0x0
80106444:	50                   	push   %eax
80106445:	e8 f7 da ff ff       	call   80103f41 <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
8010644a:	83 c4 08             	add    $0x8,%esp
8010644d:	6a 06                	push   $0x6
8010644f:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
80106455:	50                   	push   %eax
80106456:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010645b:	89 da                	mov    %ebx,%edx
8010645d:	8b 45 08             	mov    0x8(%ebp),%eax
80106460:	e8 fd fa ff ff       	call   80105f62 <mappages>
80106465:	83 c4 10             	add    $0x10,%esp
80106468:	85 c0                	test   %eax,%eax
8010646a:	78 38                	js     801064a4 <allocuvm+0xb6>
  for(; a < newsz; a += PGSIZE){
8010646c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106472:	eb a5                	jmp    80106419 <allocuvm+0x2b>
    return oldsz;
80106474:	8b 45 0c             	mov    0xc(%ebp),%eax
80106477:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010647a:	eb 5f                	jmp    801064db <allocuvm+0xed>
      cprintf("allocuvm out of memory\n");
8010647c:	83 ec 0c             	sub    $0xc,%esp
8010647f:	68 09 71 10 80       	push   $0x80107109
80106484:	e8 82 a1 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106489:	83 c4 0c             	add    $0xc,%esp
8010648c:	ff 75 0c             	pushl  0xc(%ebp)
8010648f:	57                   	push   %edi
80106490:	ff 75 08             	pushl  0x8(%ebp)
80106493:	e8 c4 fe ff ff       	call   8010635c <deallocuvm>
      return 0;
80106498:	83 c4 10             	add    $0x10,%esp
8010649b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801064a2:	eb 37                	jmp    801064db <allocuvm+0xed>
      cprintf("allocuvm out of memory (2)\n");
801064a4:	83 ec 0c             	sub    $0xc,%esp
801064a7:	68 21 71 10 80       	push   $0x80107121
801064ac:	e8 5a a1 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801064b1:	83 c4 0c             	add    $0xc,%esp
801064b4:	ff 75 0c             	pushl  0xc(%ebp)
801064b7:	57                   	push   %edi
801064b8:	ff 75 08             	pushl  0x8(%ebp)
801064bb:	e8 9c fe ff ff       	call   8010635c <deallocuvm>
      kfree(mem);
801064c0:	89 34 24             	mov    %esi,(%esp)
801064c3:	e8 fd bb ff ff       	call   801020c5 <kfree>
      return 0;
801064c8:	83 c4 10             	add    $0x10,%esp
801064cb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801064d2:	eb 07                	jmp    801064db <allocuvm+0xed>
    return 0;
801064d4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
801064db:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801064de:	8d 65 f4             	lea    -0xc(%ebp),%esp
801064e1:	5b                   	pop    %ebx
801064e2:	5e                   	pop    %esi
801064e3:	5f                   	pop    %edi
801064e4:	5d                   	pop    %ebp
801064e5:	c3                   	ret    

801064e6 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801064e6:	55                   	push   %ebp
801064e7:	89 e5                	mov    %esp,%ebp
801064e9:	56                   	push   %esi
801064ea:	53                   	push   %ebx
801064eb:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
801064ee:	85 f6                	test   %esi,%esi
801064f0:	74 1a                	je     8010650c <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
801064f2:	83 ec 04             	sub    $0x4,%esp
801064f5:	6a 00                	push   $0x0
801064f7:	68 00 00 00 80       	push   $0x80000000
801064fc:	56                   	push   %esi
801064fd:	e8 5a fe ff ff       	call   8010635c <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80106502:	83 c4 10             	add    $0x10,%esp
80106505:	bb 00 00 00 00       	mov    $0x0,%ebx
8010650a:	eb 10                	jmp    8010651c <freevm+0x36>
    panic("freevm: no pgdir");
8010650c:	83 ec 0c             	sub    $0xc,%esp
8010650f:	68 3d 71 10 80       	push   $0x8010713d
80106514:	e8 2f 9e ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
80106519:	83 c3 01             	add    $0x1,%ebx
8010651c:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
80106522:	77 1f                	ja     80106543 <freevm+0x5d>
    if(pgdir[i] & PTE_P){
80106524:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
80106527:	a8 01                	test   $0x1,%al
80106529:	74 ee                	je     80106519 <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
8010652b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106530:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106535:	83 ec 0c             	sub    $0xc,%esp
80106538:	50                   	push   %eax
80106539:	e8 87 bb ff ff       	call   801020c5 <kfree>
8010653e:	83 c4 10             	add    $0x10,%esp
80106541:	eb d6                	jmp    80106519 <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
80106543:	83 ec 0c             	sub    $0xc,%esp
80106546:	56                   	push   %esi
80106547:	e8 79 bb ff ff       	call   801020c5 <kfree>
}
8010654c:	83 c4 10             	add    $0x10,%esp
8010654f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106552:	5b                   	pop    %ebx
80106553:	5e                   	pop    %esi
80106554:	5d                   	pop    %ebp
80106555:	c3                   	ret    

80106556 <setupkvm>:
{
80106556:	55                   	push   %ebp
80106557:	89 e5                	mov    %esp,%ebp
80106559:	56                   	push   %esi
8010655a:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc2(-2)) == 0)
8010655b:	83 ec 0c             	sub    $0xc,%esp
8010655e:	6a fe                	push   $0xfffffffe
80106560:	e8 c0 bc ff ff       	call   80102225 <kalloc2>
80106565:	89 c6                	mov    %eax,%esi
80106567:	83 c4 10             	add    $0x10,%esp
8010656a:	85 c0                	test   %eax,%eax
8010656c:	74 55                	je     801065c3 <setupkvm+0x6d>
  memset(pgdir, 0, PGSIZE);
8010656e:	83 ec 04             	sub    $0x4,%esp
80106571:	68 00 10 00 00       	push   $0x1000
80106576:	6a 00                	push   $0x0
80106578:	50                   	push   %eax
80106579:	e8 c3 d9 ff ff       	call   80103f41 <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010657e:	83 c4 10             	add    $0x10,%esp
80106581:	bb 20 a4 12 80       	mov    $0x8012a420,%ebx
80106586:	81 fb 60 a4 12 80    	cmp    $0x8012a460,%ebx
8010658c:	73 35                	jae    801065c3 <setupkvm+0x6d>
                (uint)k->phys_start, k->perm) < 0) {
8010658e:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
80106591:	8b 4b 08             	mov    0x8(%ebx),%ecx
80106594:	29 c1                	sub    %eax,%ecx
80106596:	83 ec 08             	sub    $0x8,%esp
80106599:	ff 73 0c             	pushl  0xc(%ebx)
8010659c:	50                   	push   %eax
8010659d:	8b 13                	mov    (%ebx),%edx
8010659f:	89 f0                	mov    %esi,%eax
801065a1:	e8 bc f9 ff ff       	call   80105f62 <mappages>
801065a6:	83 c4 10             	add    $0x10,%esp
801065a9:	85 c0                	test   %eax,%eax
801065ab:	78 05                	js     801065b2 <setupkvm+0x5c>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801065ad:	83 c3 10             	add    $0x10,%ebx
801065b0:	eb d4                	jmp    80106586 <setupkvm+0x30>
      freevm(pgdir);
801065b2:	83 ec 0c             	sub    $0xc,%esp
801065b5:	56                   	push   %esi
801065b6:	e8 2b ff ff ff       	call   801064e6 <freevm>
      return 0;
801065bb:	83 c4 10             	add    $0x10,%esp
801065be:	be 00 00 00 00       	mov    $0x0,%esi
}
801065c3:	89 f0                	mov    %esi,%eax
801065c5:	8d 65 f8             	lea    -0x8(%ebp),%esp
801065c8:	5b                   	pop    %ebx
801065c9:	5e                   	pop    %esi
801065ca:	5d                   	pop    %ebp
801065cb:	c3                   	ret    

801065cc <kvmalloc>:
{
801065cc:	55                   	push   %ebp
801065cd:	89 e5                	mov    %esp,%ebp
801065cf:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
801065d2:	e8 7f ff ff ff       	call   80106556 <setupkvm>
801065d7:	a3 e4 54 13 80       	mov    %eax,0x801354e4
  switchkvm();
801065dc:	e8 43 fb ff ff       	call   80106124 <switchkvm>
}
801065e1:	c9                   	leave  
801065e2:	c3                   	ret    

801065e3 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801065e3:	55                   	push   %ebp
801065e4:	89 e5                	mov    %esp,%ebp
801065e6:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801065e9:	b9 00 00 00 00       	mov    $0x0,%ecx
801065ee:	8b 55 0c             	mov    0xc(%ebp),%edx
801065f1:	8b 45 08             	mov    0x8(%ebp),%eax
801065f4:	e8 f1 f8 ff ff       	call   80105eea <walkpgdir>
  if(pte == 0)
801065f9:	85 c0                	test   %eax,%eax
801065fb:	74 05                	je     80106602 <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
801065fd:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
80106600:	c9                   	leave  
80106601:	c3                   	ret    
    panic("clearpteu");
80106602:	83 ec 0c             	sub    $0xc,%esp
80106605:	68 4e 71 10 80       	push   $0x8010714e
8010660a:	e8 39 9d ff ff       	call   80100348 <panic>

8010660f <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz, uint childPid)
{
8010660f:	55                   	push   %ebp
80106610:	89 e5                	mov    %esp,%ebp
80106612:	57                   	push   %edi
80106613:	56                   	push   %esi
80106614:	53                   	push   %ebx
80106615:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80106618:	e8 39 ff ff ff       	call   80106556 <setupkvm>
8010661d:	89 45 dc             	mov    %eax,-0x24(%ebp)
80106620:	85 c0                	test   %eax,%eax
80106622:	0f 84 d1 00 00 00    	je     801066f9 <copyuvm+0xea>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80106628:	bf 00 00 00 00       	mov    $0x0,%edi
8010662d:	89 fe                	mov    %edi,%esi
8010662f:	3b 75 0c             	cmp    0xc(%ebp),%esi
80106632:	0f 83 c1 00 00 00    	jae    801066f9 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80106638:	89 75 e4             	mov    %esi,-0x1c(%ebp)
8010663b:	b9 00 00 00 00       	mov    $0x0,%ecx
80106640:	89 f2                	mov    %esi,%edx
80106642:	8b 45 08             	mov    0x8(%ebp),%eax
80106645:	e8 a0 f8 ff ff       	call   80105eea <walkpgdir>
8010664a:	85 c0                	test   %eax,%eax
8010664c:	74 70                	je     801066be <copyuvm+0xaf>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
8010664e:	8b 18                	mov    (%eax),%ebx
80106650:	f6 c3 01             	test   $0x1,%bl
80106653:	74 76                	je     801066cb <copyuvm+0xbc>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
80106655:	89 df                	mov    %ebx,%edi
80106657:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
    flags = PTE_FLAGS(*pte);
8010665d:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
80106663:	89 5d e0             	mov    %ebx,-0x20(%ebp)
    if((mem = kalloc2(childPid)) == 0)
80106666:	83 ec 0c             	sub    $0xc,%esp
80106669:	ff 75 10             	pushl  0x10(%ebp)
8010666c:	e8 b4 bb ff ff       	call   80102225 <kalloc2>
80106671:	89 c3                	mov    %eax,%ebx
80106673:	83 c4 10             	add    $0x10,%esp
80106676:	85 c0                	test   %eax,%eax
80106678:	74 6a                	je     801066e4 <copyuvm+0xd5>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
8010667a:	81 c7 00 00 00 80    	add    $0x80000000,%edi
80106680:	83 ec 04             	sub    $0x4,%esp
80106683:	68 00 10 00 00       	push   $0x1000
80106688:	57                   	push   %edi
80106689:	50                   	push   %eax
8010668a:	e8 2d d9 ff ff       	call   80103fbc <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
8010668f:	83 c4 08             	add    $0x8,%esp
80106692:	ff 75 e0             	pushl  -0x20(%ebp)
80106695:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
8010669b:	50                   	push   %eax
8010669c:	b9 00 10 00 00       	mov    $0x1000,%ecx
801066a1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801066a4:	8b 45 dc             	mov    -0x24(%ebp),%eax
801066a7:	e8 b6 f8 ff ff       	call   80105f62 <mappages>
801066ac:	83 c4 10             	add    $0x10,%esp
801066af:	85 c0                	test   %eax,%eax
801066b1:	78 25                	js     801066d8 <copyuvm+0xc9>
  for(i = 0; i < sz; i += PGSIZE){
801066b3:	81 c6 00 10 00 00    	add    $0x1000,%esi
801066b9:	e9 71 ff ff ff       	jmp    8010662f <copyuvm+0x20>
      panic("copyuvm: pte should exist");
801066be:	83 ec 0c             	sub    $0xc,%esp
801066c1:	68 58 71 10 80       	push   $0x80107158
801066c6:	e8 7d 9c ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
801066cb:	83 ec 0c             	sub    $0xc,%esp
801066ce:	68 72 71 10 80       	push   $0x80107172
801066d3:	e8 70 9c ff ff       	call   80100348 <panic>
      kfree(mem);
801066d8:	83 ec 0c             	sub    $0xc,%esp
801066db:	53                   	push   %ebx
801066dc:	e8 e4 b9 ff ff       	call   801020c5 <kfree>
      goto bad;
801066e1:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
801066e4:	83 ec 0c             	sub    $0xc,%esp
801066e7:	ff 75 dc             	pushl  -0x24(%ebp)
801066ea:	e8 f7 fd ff ff       	call   801064e6 <freevm>
  return 0;
801066ef:	83 c4 10             	add    $0x10,%esp
801066f2:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
801066f9:	8b 45 dc             	mov    -0x24(%ebp),%eax
801066fc:	8d 65 f4             	lea    -0xc(%ebp),%esp
801066ff:	5b                   	pop    %ebx
80106700:	5e                   	pop    %esi
80106701:	5f                   	pop    %edi
80106702:	5d                   	pop    %ebp
80106703:	c3                   	ret    

80106704 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80106704:	55                   	push   %ebp
80106705:	89 e5                	mov    %esp,%ebp
80106707:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010670a:	b9 00 00 00 00       	mov    $0x0,%ecx
8010670f:	8b 55 0c             	mov    0xc(%ebp),%edx
80106712:	8b 45 08             	mov    0x8(%ebp),%eax
80106715:	e8 d0 f7 ff ff       	call   80105eea <walkpgdir>
  if((*pte & PTE_P) == 0)
8010671a:	8b 00                	mov    (%eax),%eax
8010671c:	a8 01                	test   $0x1,%al
8010671e:	74 10                	je     80106730 <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
80106720:	a8 04                	test   $0x4,%al
80106722:	74 13                	je     80106737 <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
80106724:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106729:	05 00 00 00 80       	add    $0x80000000,%eax
}
8010672e:	c9                   	leave  
8010672f:	c3                   	ret    
    return 0;
80106730:	b8 00 00 00 00       	mov    $0x0,%eax
80106735:	eb f7                	jmp    8010672e <uva2ka+0x2a>
    return 0;
80106737:	b8 00 00 00 00       	mov    $0x0,%eax
8010673c:	eb f0                	jmp    8010672e <uva2ka+0x2a>

8010673e <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
8010673e:	55                   	push   %ebp
8010673f:	89 e5                	mov    %esp,%ebp
80106741:	57                   	push   %edi
80106742:	56                   	push   %esi
80106743:	53                   	push   %ebx
80106744:	83 ec 0c             	sub    $0xc,%esp
80106747:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
8010674a:	eb 25                	jmp    80106771 <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
8010674c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010674f:	29 f2                	sub    %esi,%edx
80106751:	01 d0                	add    %edx,%eax
80106753:	83 ec 04             	sub    $0x4,%esp
80106756:	53                   	push   %ebx
80106757:	ff 75 10             	pushl  0x10(%ebp)
8010675a:	50                   	push   %eax
8010675b:	e8 5c d8 ff ff       	call   80103fbc <memmove>
    len -= n;
80106760:	29 df                	sub    %ebx,%edi
    buf += n;
80106762:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
80106765:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
8010676b:	89 45 0c             	mov    %eax,0xc(%ebp)
8010676e:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
80106771:	85 ff                	test   %edi,%edi
80106773:	74 2f                	je     801067a4 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
80106775:	8b 75 0c             	mov    0xc(%ebp),%esi
80106778:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
8010677e:	83 ec 08             	sub    $0x8,%esp
80106781:	56                   	push   %esi
80106782:	ff 75 08             	pushl  0x8(%ebp)
80106785:	e8 7a ff ff ff       	call   80106704 <uva2ka>
    if(pa0 == 0)
8010678a:	83 c4 10             	add    $0x10,%esp
8010678d:	85 c0                	test   %eax,%eax
8010678f:	74 20                	je     801067b1 <copyout+0x73>
    n = PGSIZE - (va - va0);
80106791:	89 f3                	mov    %esi,%ebx
80106793:	2b 5d 0c             	sub    0xc(%ebp),%ebx
80106796:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
8010679c:	39 df                	cmp    %ebx,%edi
8010679e:	73 ac                	jae    8010674c <copyout+0xe>
      n = len;
801067a0:	89 fb                	mov    %edi,%ebx
801067a2:	eb a8                	jmp    8010674c <copyout+0xe>
  }
  return 0;
801067a4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801067a9:	8d 65 f4             	lea    -0xc(%ebp),%esp
801067ac:	5b                   	pop    %ebx
801067ad:	5e                   	pop    %esi
801067ae:	5f                   	pop    %edi
801067af:	5d                   	pop    %ebp
801067b0:	c3                   	ret    
      return -1;
801067b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067b6:	eb f1                	jmp    801067a9 <copyout+0x6b>
