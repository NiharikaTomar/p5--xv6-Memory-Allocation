
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
8010002d:	b8 4d 2d 10 80       	mov    $0x80102d4d,%eax
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
80100046:	e8 3e 3e 00 00       	call   80103e89 <acquire>

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
8010007c:	e8 6d 3e 00 00       	call   80103eee <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 e9 3b 00 00       	call   80103c75 <acquiresleep>
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
801000ca:	e8 1f 3e 00 00       	call   80103eee <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 9b 3b 00 00       	call   80103c75 <acquiresleep>
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
80100105:	e8 43 3c 00 00       	call   80103d4d <initlock>
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
80100143:	e8 fa 3a 00 00       	call   80103c42 <initsleeplock>
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
801001a8:	e8 52 3b 00 00       	call   80103cff <holdingsleep>
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
801001e4:	e8 16 3b 00 00       	call   80103cff <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 cb 3a 00 00       	call   80103cc4 <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 e0 b5 12 80 	movl   $0x8012b5e0,(%esp)
80100200:	e8 84 3c 00 00       	call   80103e89 <acquire>
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
8010024c:	e8 9d 3c 00 00       	call   80103eee <release>
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
8010028a:	e8 fa 3b 00 00       	call   80103e89 <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 c0 ff 12 80       	mov    0x8012ffc0,%eax
8010029f:	3b 05 c4 ff 12 80    	cmp    0x8012ffc4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 3b 32 00 00       	call   801034e7 <myproc>
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
801002bf:	e8 ca 36 00 00       	call   8010398e <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 a5 12 80       	push   $0x8012a520
801002d1:	e8 18 3c 00 00       	call   80103eee <release>
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
80100331:	e8 b8 3b 00 00       	call   80103eee <release>
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
8010035a:	e8 08 23 00 00       	call   80102667 <lapicid>
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
8010038f:	e8 d4 39 00 00       	call   80103d68 <getcallerpcs>
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
801004ba:	e8 f1 3a 00 00       	call   80103fb0 <memmove>
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
801004d9:	e8 57 3a 00 00       	call   80103f35 <memset>
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
80100506:	e8 64 4e 00 00       	call   8010536f <uartputc>
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
8010051f:	e8 4b 4e 00 00       	call   8010536f <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 3f 4e 00 00       	call   8010536f <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 33 4e 00 00       	call   8010536f <uartputc>
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
801005ca:	e8 ba 38 00 00       	call   80103e89 <acquire>
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
801005f1:	e8 f8 38 00 00       	call   80103eee <release>
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
80100638:	e8 4c 38 00 00       	call   80103e89 <acquire>
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
80100734:	e8 b5 37 00 00       	call   80103eee <release>
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
8010074f:	e8 35 37 00 00       	call   80103e89 <acquire>
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
801007de:	e8 10 33 00 00       	call   80103af3 <wakeup>
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
80100873:	e8 76 36 00 00       	call   80103eee <release>
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
80100887:	e8 04 33 00 00       	call   80103b90 <procdump>
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
8010089e:	e8 aa 34 00 00       	call   80103d4d <initlock>

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
801008de:	e8 04 2c 00 00       	call   801034e7 <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 a9 21 00 00       	call   80102a97 <begin_op>

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
80100935:	e8 d7 21 00 00       	call   80102b11 <end_op>
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
8010094a:	e8 c2 21 00 00       	call   80102b11 <end_op>
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
80100972:	e8 d3 5b 00 00       	call   8010654a <setupkvm>
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
80100a06:	e8 d7 59 00 00       	call   801063e2 <allocuvm>
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
80100a38:	e8 73 58 00 00       	call   801062b0 <loaduvm>
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
80100a53:	e8 b9 20 00 00       	call   80102b11 <end_op>
  sz = PGROUNDUP(sz);
80100a58:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a63:	83 c4 0c             	add    $0xc,%esp
80100a66:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a6c:	52                   	push   %edx
80100a6d:	50                   	push   %eax
80100a6e:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100a74:	e8 69 59 00 00       	call   801063e2 <allocuvm>
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
80100a9d:	e8 38 5a 00 00       	call   801064da <freevm>
80100aa2:	83 c4 10             	add    $0x10,%esp
80100aa5:	e9 7a fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aaa:	89 c7                	mov    %eax,%edi
80100aac:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100ab2:	83 ec 08             	sub    $0x8,%esp
80100ab5:	50                   	push   %eax
80100ab6:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100abc:	e8 16 5b 00 00       	call   801065d7 <clearpteu>
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
80100ae2:	e8 f0 35 00 00       	call   801040d7 <strlen>
80100ae7:	29 c7                	sub    %eax,%edi
80100ae9:	83 ef 01             	sub    $0x1,%edi
80100aec:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100aef:	83 c4 04             	add    $0x4,%esp
80100af2:	ff 36                	pushl  (%esi)
80100af4:	e8 de 35 00 00       	call   801040d7 <strlen>
80100af9:	83 c0 01             	add    $0x1,%eax
80100afc:	50                   	push   %eax
80100afd:	ff 36                	pushl  (%esi)
80100aff:	57                   	push   %edi
80100b00:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b06:	e8 27 5c 00 00       	call   80106732 <copyout>
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
80100b66:	e8 c7 5b 00 00       	call   80106732 <copyout>
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
80100ba3:	e8 f4 34 00 00       	call   8010409c <safestrcpy>
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
80100bd1:	e8 54 55 00 00       	call   8010612a <switchuvm>
  freevm(oldpgdir);
80100bd6:	89 1c 24             	mov    %ebx,(%esp)
80100bd9:	e8 fc 58 00 00       	call   801064da <freevm>
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
80100c23:	e8 25 31 00 00       	call   80103d4d <initlock>
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
80100c39:	e8 4b 32 00 00       	call   80103e89 <acquire>
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
80100c68:	e8 81 32 00 00       	call   80103eee <release>
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
80100c7f:	e8 6a 32 00 00       	call   80103eee <release>
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
80100c9d:	e8 e7 31 00 00       	call   80103e89 <acquire>
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
80100cba:	e8 2f 32 00 00       	call   80103eee <release>
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
80100ce2:	e8 a2 31 00 00       	call   80103e89 <acquire>
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
80100d03:	e8 e6 31 00 00       	call   80103eee <release>
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
80100d49:	e8 a0 31 00 00       	call   80103eee <release>
  if(ff.type == FD_PIPE)
80100d4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d51:	83 c4 10             	add    $0x10,%esp
80100d54:	83 f8 01             	cmp    $0x1,%eax
80100d57:	74 1f                	je     80100d78 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d59:	83 f8 02             	cmp    $0x2,%eax
80100d5c:	75 ad                	jne    80100d0b <fileclose+0x38>
    begin_op();
80100d5e:	e8 34 1d 00 00       	call   80102a97 <begin_op>
    iput(ff.ip);
80100d63:	83 ec 0c             	sub    $0xc,%esp
80100d66:	ff 75 f0             	pushl  -0x10(%ebp)
80100d69:	e8 1a 09 00 00       	call   80101688 <iput>
    end_op();
80100d6e:	e8 9e 1d 00 00       	call   80102b11 <end_op>
80100d73:	83 c4 10             	add    $0x10,%esp
80100d76:	eb 93                	jmp    80100d0b <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d78:	83 ec 08             	sub    $0x8,%esp
80100d7b:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7f:	50                   	push   %eax
80100d80:	ff 75 ec             	pushl  -0x14(%ebp)
80100d83:	e8 8b 23 00 00       	call   80103113 <pipeclose>
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
80100e3c:	e8 2a 24 00 00       	call   8010326b <piperead>
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
80100e95:	e8 05 23 00 00       	call   8010319f <pipewrite>
80100e9a:	83 c4 10             	add    $0x10,%esp
80100e9d:	e9 80 00 00 00       	jmp    80100f22 <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100ea2:	e8 f0 1b 00 00       	call   80102a97 <begin_op>
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
80100edd:	e8 2f 1c 00 00       	call   80102b11 <end_op>

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
80100f8a:	e8 21 30 00 00       	call   80103fb0 <memmove>
80100f8f:	83 c4 10             	add    $0x10,%esp
80100f92:	eb 17                	jmp    80100fab <skipelem+0x66>
  else {
    memmove(name, s, len);
80100f94:	83 ec 04             	sub    $0x4,%esp
80100f97:	56                   	push   %esi
80100f98:	50                   	push   %eax
80100f99:	57                   	push   %edi
80100f9a:	e8 11 30 00 00       	call   80103fb0 <memmove>
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
80100fdf:	e8 51 2f 00 00       	call   80103f35 <memset>
  log_write(bp);
80100fe4:	89 1c 24             	mov    %ebx,(%esp)
80100fe7:	e8 d4 1b 00 00       	call   80102bc0 <log_write>
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
801010bf:	e8 fc 1a 00 00       	call   80102bc0 <log_write>
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
80101170:	e8 4b 1a 00 00       	call   80102bc0 <log_write>
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
8010119a:	e8 ea 2c 00 00       	call   80103e89 <acquire>
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
801011e1:	e8 08 2d 00 00       	call   80103eee <release>
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
80101217:	e8 d2 2c 00 00       	call   80103eee <release>
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
80101255:	e8 56 2d 00 00       	call   80103fb0 <memmove>
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
801012c8:	e8 f3 18 00 00       	call   80102bc0 <log_write>
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
801012fd:	e8 4b 2a 00 00       	call   80103d4d <initlock>
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
80101322:	e8 1b 29 00 00       	call   80103c42 <initsleeplock>
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
801013f1:	e8 3f 2b 00 00       	call   80103f35 <memset>
      dip->type = type;
801013f6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013fa:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013fd:	89 34 24             	mov    %esi,(%esp)
80101400:	e8 bb 17 00 00       	call   80102bc0 <log_write>
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
80101480:	e8 2b 2b 00 00       	call   80103fb0 <memmove>
  log_write(bp);
80101485:	89 34 24             	mov    %esi,(%esp)
80101488:	e8 33 17 00 00       	call   80102bc0 <log_write>
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
80101560:	e8 24 29 00 00       	call   80103e89 <acquire>
  ip->ref++;
80101565:	8b 43 08             	mov    0x8(%ebx),%eax
80101568:	83 c0 01             	add    $0x1,%eax
8010156b:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010156e:	c7 04 24 00 0a 13 80 	movl   $0x80130a00,(%esp)
80101575:	e8 74 29 00 00       	call   80103eee <release>
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
8010159a:	e8 d6 26 00 00       	call   80103c75 <acquiresleep>
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
80101614:	e8 97 29 00 00       	call   80103fb0 <memmove>
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
80101656:	e8 a4 26 00 00       	call   80103cff <holdingsleep>
8010165b:	83 c4 10             	add    $0x10,%esp
8010165e:	85 c0                	test   %eax,%eax
80101660:	74 19                	je     8010167b <iunlock+0x38>
80101662:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101666:	7e 13                	jle    8010167b <iunlock+0x38>
  releasesleep(&ip->lock);
80101668:	83 ec 0c             	sub    $0xc,%esp
8010166b:	56                   	push   %esi
8010166c:	e8 53 26 00 00       	call   80103cc4 <releasesleep>
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
80101698:	e8 d8 25 00 00       	call   80103c75 <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010169d:	83 c4 10             	add    $0x10,%esp
801016a0:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016a4:	74 07                	je     801016ad <iput+0x25>
801016a6:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016ab:	74 35                	je     801016e2 <iput+0x5a>
  releasesleep(&ip->lock);
801016ad:	83 ec 0c             	sub    $0xc,%esp
801016b0:	56                   	push   %esi
801016b1:	e8 0e 26 00 00       	call   80103cc4 <releasesleep>
  acquire(&icache.lock);
801016b6:	c7 04 24 00 0a 13 80 	movl   $0x80130a00,(%esp)
801016bd:	e8 c7 27 00 00       	call   80103e89 <acquire>
  ip->ref--;
801016c2:	8b 43 08             	mov    0x8(%ebx),%eax
801016c5:	83 e8 01             	sub    $0x1,%eax
801016c8:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016cb:	c7 04 24 00 0a 13 80 	movl   $0x80130a00,(%esp)
801016d2:	e8 17 28 00 00       	call   80103eee <release>
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
801016ea:	e8 9a 27 00 00       	call   80103e89 <acquire>
    int r = ip->ref;
801016ef:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016f2:	c7 04 24 00 0a 13 80 	movl   $0x80130a00,(%esp)
801016f9:	e8 f0 27 00 00       	call   80103eee <release>
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
8010182a:	e8 81 27 00 00       	call   80103fb0 <memmove>
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
80101926:	e8 85 26 00 00       	call   80103fb0 <memmove>
    log_write(bp);
8010192b:	89 3c 24             	mov    %edi,(%esp)
8010192e:	e8 8d 12 00 00       	call   80102bc0 <log_write>
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
801019a9:	e8 69 26 00 00       	call   80104017 <strncmp>
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
80101a5a:	e8 88 1a 00 00       	call   801034e7 <myproc>
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
80101ba9:	e8 a6 24 00 00       	call   80104054 <strncpy>
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
80101d10:	e8 38 20 00 00       	call   80103d4d <initlock>
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
80101d80:	e8 04 21 00 00       	call   80103e89 <acquire>

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
80101dad:	e8 41 1d 00 00       	call   80103af3 <wakeup>

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
80101dcb:	e8 1e 21 00 00       	call   80103eee <release>
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
80101de2:	e8 07 21 00 00       	call   80103eee <release>
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
80101e1a:	e8 e0 1e 00 00       	call   80103cff <holdingsleep>
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
80101e47:	e8 3d 20 00 00       	call   80103e89 <acquire>

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
80101ea9:	e8 e0 1a 00 00       	call   8010398e <sleep>
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
80101ec3:	e8 26 20 00 00       	call   80103eee <release>
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
80101fd6:	e8 5a 1f 00 00       	call   80103f35 <memset>

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
80102017:	e8 6d 1e 00 00       	call   80103e89 <acquire>
8010201c:	83 c4 10             	add    $0x10,%esp
8010201f:	eb c6                	jmp    80101fe7 <kfree2+0x43>
    release(&kmem.lock);
80102021:	83 ec 0c             	sub    $0xc,%esp
80102024:	68 60 26 13 80       	push   $0x80132660
80102029:	e8 c0 1e 00 00       	call   80103eee <release>
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
80102079:	e8 cf 1c 00 00       	call   80103d4d <initlock>
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
801020c8:	53                   	push   %ebx
801020c9:	83 ec 04             	sub    $0x4,%esp
801020cc:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
801020cf:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
801020d5:	75 4c                	jne    80102123 <kfree+0x5e>
801020d7:	81 fb e8 54 13 80    	cmp    $0x801354e8,%ebx
801020dd:	72 44                	jb     80102123 <kfree+0x5e>
801020df:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801020e5:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
801020ea:	77 37                	ja     80102123 <kfree+0x5e>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
801020ec:	83 ec 04             	sub    $0x4,%esp
801020ef:	68 00 10 00 00       	push   $0x1000
801020f4:	6a 01                	push   $0x1
801020f6:	53                   	push   %ebx
801020f7:	e8 39 1e 00 00       	call   80103f35 <memset>

  if(kmem.use_lock)
801020fc:	83 c4 10             	add    $0x10,%esp
801020ff:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
80102106:	75 28                	jne    80102130 <kfree+0x6b>
    acquire(&kmem.lock);
  r = (struct run*)v;

  //add to free list
  r->next = kmem.freelist;
80102108:	a1 98 26 13 80       	mov    0x80132698,%eax
8010210d:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
8010210f:	89 1d 98 26 13 80    	mov    %ebx,0x80132698
  // }

  // frames[16384] = -1;
  // pids[16384] = -1;

  if(kmem.use_lock)
80102115:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
8010211c:	75 24                	jne    80102142 <kfree+0x7d>
    release(&kmem.lock);
}
8010211e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102121:	c9                   	leave  
80102122:	c3                   	ret    
    panic("kfree");
80102123:	83 ec 0c             	sub    $0xc,%esp
80102126:	68 26 6a 10 80       	push   $0x80106a26
8010212b:	e8 18 e2 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
80102130:	83 ec 0c             	sub    $0xc,%esp
80102133:	68 60 26 13 80       	push   $0x80132660
80102138:	e8 4c 1d 00 00       	call   80103e89 <acquire>
8010213d:	83 c4 10             	add    $0x10,%esp
80102140:	eb c6                	jmp    80102108 <kfree+0x43>
    release(&kmem.lock);
80102142:	83 ec 0c             	sub    $0xc,%esp
80102145:	68 60 26 13 80       	push   $0x80132660
8010214a:	e8 9f 1d 00 00       	call   80103eee <release>
8010214f:	83 c4 10             	add    $0x10,%esp
}
80102152:	eb ca                	jmp    8010211e <kfree+0x59>

80102154 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102154:	55                   	push   %ebp
80102155:	89 e5                	mov    %esp,%ebp
80102157:	53                   	push   %ebx
80102158:	83 ec 04             	sub    $0x4,%esp
  struct run *r;

  if(kmem.use_lock)
8010215b:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
80102162:	75 33                	jne    80102197 <kalloc+0x43>
    acquire(&kmem.lock);
  r = kmem.freelist;
80102164:	8b 1d 98 26 13 80    	mov    0x80132698,%ebx
  
  // V2P and shift, and mask off
  framenumber = (uint)(V2P(r) >> 12 & 0xffff);
8010216a:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80102170:	c1 e8 0c             	shr    $0xc,%eax
80102173:	0f b7 c0             	movzwl %ax,%eax
80102176:	a3 a0 26 13 80       	mov    %eax,0x801326a0

  if(r){
8010217b:	85 db                	test   %ebx,%ebx
8010217d:	74 08                	je     80102187 <kalloc+0x33>
    kmem.freelist = r->next;
8010217f:	8b 13                	mov    (%ebx),%edx
80102181:	89 15 98 26 13 80    	mov    %edx,0x80132698
  }

  if(kmem.use_lock) {    
80102187:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
8010218e:	75 19                	jne    801021a9 <kalloc+0x55>
    pids[index] = 1;
    index++;
    release(&kmem.lock);
  }
  return (char*)r;
}
80102190:	89 d8                	mov    %ebx,%eax
80102192:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102195:	c9                   	leave  
80102196:	c3                   	ret    
    acquire(&kmem.lock);
80102197:	83 ec 0c             	sub    $0xc,%esp
8010219a:	68 60 26 13 80       	push   $0x80132660
8010219f:	e8 e5 1c 00 00       	call   80103e89 <acquire>
801021a4:	83 c4 10             	add    $0x10,%esp
801021a7:	eb bb                	jmp    80102164 <kalloc+0x10>
    frames[index] = framenumber;
801021a9:	8b 15 b8 a5 12 80    	mov    0x8012a5b8,%edx
801021af:	89 04 95 20 80 11 80 	mov    %eax,-0x7fee7fe0(,%edx,4)
    pids[index] = 1;
801021b6:	c7 04 95 00 80 10 80 	movl   $0x1,-0x7fef8000(,%edx,4)
801021bd:	01 00 00 00 
    index++;
801021c1:	83 c2 01             	add    $0x1,%edx
801021c4:	89 15 b8 a5 12 80    	mov    %edx,0x8012a5b8
    release(&kmem.lock);
801021ca:	83 ec 0c             	sub    $0xc,%esp
801021cd:	68 60 26 13 80       	push   $0x80132660
801021d2:	e8 17 1d 00 00       	call   80103eee <release>
801021d7:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
801021da:	eb b4                	jmp    80102190 <kalloc+0x3c>

801021dc <kalloc2>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc2(uint pid)
{
801021dc:	55                   	push   %ebp
801021dd:	89 e5                	mov    %esp,%ebp
801021df:	57                   	push   %edi
801021e0:	56                   	push   %esi
801021e1:	53                   	push   %ebx
801021e2:	83 ec 1c             	sub    $0x1c,%esp
  struct run *prev; // previous head of the freelist
  struct run *store_head; // stores current head of the freelist
  uint nextPid = -1;
  uint prevPid = -1;

  if(kmem.use_lock)
801021e5:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
801021ec:	75 1d                	jne    8010220b <kalloc2+0x2f>
    acquire(&kmem.lock);
  r = kmem.freelist; // head which acts as a current pointer
801021ee:	8b 1d 98 26 13 80    	mov    0x80132698,%ebx
801021f4:	89 5d dc             	mov    %ebx,-0x24(%ebp)

  store_head = r;
  prev = r;
801021f7:	89 5d e0             	mov    %ebx,-0x20(%ebp)
  uint prevPid = -1;
801021fa:	be ff ff ff ff       	mov    $0xffffffff,%esi
  uint nextPid = -1;
801021ff:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
  while(r){
80102206:	e9 b2 00 00 00       	jmp    801022bd <kalloc2+0xe1>
    acquire(&kmem.lock);
8010220b:	83 ec 0c             	sub    $0xc,%esp
8010220e:	68 60 26 13 80       	push   $0x80132660
80102213:	e8 71 1c 00 00       	call   80103e89 <acquire>
80102218:	83 c4 10             	add    $0x10,%esp
8010221b:	eb d1                	jmp    801021ee <kalloc2+0x12>
      if (frames[i] == -1) {
        prevPid = -1;
        break;
      }
      if (frames[i] == framenumber - 1) {
        prevPid = pids[i];
8010221d:	8b 34 85 00 80 10 80 	mov    -0x7fef8000(,%eax,4),%esi
        break;
80102224:	eb 05                	jmp    8010222b <kalloc2+0x4f>
        prevPid = -1;
80102226:	be ff ff ff ff       	mov    $0xffffffff,%esi
      }
    }
    // looking at 1 frame after current to check for same process
    for(int j = 0; j < 16385; j++){
8010222b:	b8 00 00 00 00       	mov    $0x0,%eax
80102230:	3d 00 40 00 00       	cmp    $0x4000,%eax
80102235:	7f 2b                	jg     80102262 <kalloc2+0x86>
      if (frames[j] == -1) {
80102237:	8b 14 85 20 80 11 80 	mov    -0x7fee7fe0(,%eax,4),%edx
8010223e:	83 fa ff             	cmp    $0xffffffff,%edx
80102241:	74 18                	je     8010225b <kalloc2+0x7f>
        nextPid = -1;
        break;
      }
      if(frames[j] == framenumber + 1){
80102243:	8d 79 01             	lea    0x1(%ecx),%edi
80102246:	39 fa                	cmp    %edi,%edx
80102248:	74 05                	je     8010224f <kalloc2+0x73>
    for(int j = 0; j < 16385; j++){
8010224a:	83 c0 01             	add    $0x1,%eax
8010224d:	eb e1                	jmp    80102230 <kalloc2+0x54>
        nextPid = pids[j];
8010224f:	8b 04 85 00 80 10 80 	mov    -0x7fef8000(,%eax,4),%eax
80102256:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        break;
80102259:	eb 07                	jmp    80102262 <kalloc2+0x86>
        nextPid = -1;
8010225b:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
      }
    }

    if(((prevPid == pid || prevPid == -2) && (nextPid == pid || nextPid == -2)) // if both are not free
80102262:	3b 75 08             	cmp    0x8(%ebp),%esi
80102265:	0f 94 c2             	sete   %dl
80102268:	83 fe fe             	cmp    $0xfffffffe,%esi
8010226b:	0f 94 c0             	sete   %al
8010226e:	08 d0                	or     %dl,%al
80102270:	74 17                	je     80102289 <kalloc2+0xad>
80102272:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80102275:	3b 7d 08             	cmp    0x8(%ebp),%edi
80102278:	0f 94 c1             	sete   %cl
8010227b:	83 ff fe             	cmp    $0xfffffffe,%edi
8010227e:	0f 94 c2             	sete   %dl
80102281:	08 d1                	or     %dl,%cl
80102283:	0f 85 8d 00 00 00    	jne    80102316 <kalloc2+0x13a>
      || (prevPid == -1 && nextPid == -1) // if both are free
80102289:	83 fe ff             	cmp    $0xffffffff,%esi
8010228c:	0f 94 c1             	sete   %cl
8010228f:	83 7d e4 ff          	cmpl   $0xffffffff,-0x1c(%ebp)
80102293:	0f 94 c2             	sete   %dl
80102296:	84 d1                	test   %dl,%cl
80102298:	75 7c                	jne    80102316 <kalloc2+0x13a>
      || ((pid == prevPid || prevPid == -2 || prevPid != -1)  && nextPid == -1) // if left is not free
8010229a:	84 c0                	test   %al,%al
8010229c:	75 05                	jne    801022a3 <kalloc2+0xc7>
8010229e:	83 fe ff             	cmp    $0xffffffff,%esi
801022a1:	74 06                	je     801022a9 <kalloc2+0xcd>
801022a3:	83 7d e4 ff          	cmpl   $0xffffffff,-0x1c(%ebp)
801022a7:	74 6d                	je     80102316 <kalloc2+0x13a>
      || ((prevPid == -1 && (pid == nextPid || nextPid == -2)))
801022a9:	83 fe ff             	cmp    $0xffffffff,%esi
801022ac:	74 55                	je     80102303 <kalloc2+0x127>
      || (pid == -2 && (nextPid == 1 || prevPid == 1))) { // if right is not free
801022ae:	83 7d 08 fe          	cmpl   $0xfffffffe,0x8(%ebp)
801022b2:	0f 84 87 00 00 00    	je     8010233f <kalloc2+0x163>
          prev->next = r->next;
          break;
        }
      }

      prev = r;
801022b8:	89 5d e0             	mov    %ebx,-0x20(%ebp)
      r = r->next;  
801022bb:	8b 1b                	mov    (%ebx),%ebx
  while(r){
801022bd:	85 db                	test   %ebx,%ebx
801022bf:	74 62                	je     80102323 <kalloc2+0x147>
    framenumber = (uint)(V2P(r) >> 12 & 0xffff);
801022c1:	8d 8b 00 00 00 80    	lea    -0x80000000(%ebx),%ecx
801022c7:	c1 e9 0c             	shr    $0xc,%ecx
801022ca:	0f b7 c9             	movzwl %cx,%ecx
801022cd:	89 0d a0 26 13 80    	mov    %ecx,0x801326a0
    for(int i = 0; i < 16385; i++){
801022d3:	b8 00 00 00 00       	mov    $0x0,%eax
801022d8:	3d 00 40 00 00       	cmp    $0x4000,%eax
801022dd:	0f 8f 48 ff ff ff    	jg     8010222b <kalloc2+0x4f>
      if (frames[i] == -1) {
801022e3:	8b 14 85 20 80 11 80 	mov    -0x7fee7fe0(,%eax,4),%edx
801022ea:	83 fa ff             	cmp    $0xffffffff,%edx
801022ed:	0f 84 33 ff ff ff    	je     80102226 <kalloc2+0x4a>
      if (frames[i] == framenumber - 1) {
801022f3:	8d 79 ff             	lea    -0x1(%ecx),%edi
801022f6:	39 fa                	cmp    %edi,%edx
801022f8:	0f 84 1f ff ff ff    	je     8010221d <kalloc2+0x41>
    for(int i = 0; i < 16385; i++){
801022fe:	83 c0 01             	add    $0x1,%eax
80102301:	eb d5                	jmp    801022d8 <kalloc2+0xfc>
      || ((prevPid == -1 && (pid == nextPid || nextPid == -2)))
80102303:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102306:	3b 45 08             	cmp    0x8(%ebp),%eax
80102309:	0f 94 c2             	sete   %dl
8010230c:	83 f8 fe             	cmp    $0xfffffffe,%eax
8010230f:	0f 94 c0             	sete   %al
80102312:	08 c2                	or     %al,%dl
80102314:	74 98                	je     801022ae <kalloc2+0xd2>
        if(store_head){ // check if head of the freelist
80102316:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
8010231a:	74 3a                	je     80102356 <kalloc2+0x17a>
          kmem.freelist = r->next;
8010231c:	8b 03                	mov    (%ebx),%eax
8010231e:	a3 98 26 13 80       	mov    %eax,0x80132698
    }

  if (flag == 1){
80102323:	83 3d b4 a5 12 80 01 	cmpl   $0x1,0x8012a5b4
8010232a:	74 33                	je     8010235f <kalloc2+0x183>
    frames[index] = framenumber;
    pids[index] = pid;
    index++;
  }

  if(kmem.use_lock) {
8010232c:	83 3d 94 26 13 80 00 	cmpl   $0x0,0x80132694
80102333:	75 50                	jne    80102385 <kalloc2+0x1a9>
    release(&kmem.lock);
  }
  return (char*)r;
}
80102335:	89 d8                	mov    %ebx,%eax
80102337:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010233a:	5b                   	pop    %ebx
8010233b:	5e                   	pop    %esi
8010233c:	5f                   	pop    %edi
8010233d:	5d                   	pop    %ebp
8010233e:	c3                   	ret    
      || (pid == -2 && (nextPid == 1 || prevPid == 1))) { // if right is not free
8010233f:	83 7d e4 01          	cmpl   $0x1,-0x1c(%ebp)
80102343:	0f 94 c2             	sete   %dl
80102346:	83 fe 01             	cmp    $0x1,%esi
80102349:	0f 94 c0             	sete   %al
8010234c:	08 c2                	or     %al,%dl
8010234e:	0f 84 64 ff ff ff    	je     801022b8 <kalloc2+0xdc>
80102354:	eb c0                	jmp    80102316 <kalloc2+0x13a>
          prev->next = r->next;
80102356:	8b 03                	mov    (%ebx),%eax
80102358:	8b 75 e0             	mov    -0x20(%ebp),%esi
8010235b:	89 06                	mov    %eax,(%esi)
          break;
8010235d:	eb c4                	jmp    80102323 <kalloc2+0x147>
    frames[index] = framenumber;
8010235f:	a1 b8 a5 12 80       	mov    0x8012a5b8,%eax
80102364:	8b 15 a0 26 13 80    	mov    0x801326a0,%edx
8010236a:	89 14 85 20 80 11 80 	mov    %edx,-0x7fee7fe0(,%eax,4)
    pids[index] = pid;
80102371:	8b 75 08             	mov    0x8(%ebp),%esi
80102374:	89 34 85 00 80 10 80 	mov    %esi,-0x7fef8000(,%eax,4)
    index++;
8010237b:	83 c0 01             	add    $0x1,%eax
8010237e:	a3 b8 a5 12 80       	mov    %eax,0x8012a5b8
80102383:	eb a7                	jmp    8010232c <kalloc2+0x150>
    release(&kmem.lock);
80102385:	83 ec 0c             	sub    $0xc,%esp
80102388:	68 60 26 13 80       	push   $0x80132660
8010238d:	e8 5c 1b 00 00       	call   80103eee <release>
80102392:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
80102395:	eb 9e                	jmp    80102335 <kalloc2+0x159>

80102397 <dump_physmem>:

int
dump_physmem(int *frs, int *pds, int numframes)
{
80102397:	55                   	push   %ebp
80102398:	89 e5                	mov    %esp,%ebp
8010239a:	57                   	push   %edi
8010239b:	56                   	push   %esi
8010239c:	53                   	push   %ebx
8010239d:	8b 75 08             	mov    0x8(%ebp),%esi
801023a0:	8b 7d 0c             	mov    0xc(%ebp),%edi
801023a3:	8b 5d 10             	mov    0x10(%ebp),%ebx
  if(numframes <= 0 || frs == 0 || pds == 0)
801023a6:	85 db                	test   %ebx,%ebx
801023a8:	0f 9e c2             	setle  %dl
801023ab:	85 f6                	test   %esi,%esi
801023ad:	0f 94 c0             	sete   %al
801023b0:	08 c2                	or     %al,%dl
801023b2:	75 37                	jne    801023eb <dump_physmem+0x54>
801023b4:	85 ff                	test   %edi,%edi
801023b6:	74 3a                	je     801023f2 <dump_physmem+0x5b>
    return -1;
  for (int i = 0; i < numframes; i++) {
801023b8:	b8 00 00 00 00       	mov    $0x0,%eax
801023bd:	eb 1e                	jmp    801023dd <dump_physmem+0x46>
    frs[i] = frames[i];
801023bf:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801023c6:	8b 0c 85 20 80 11 80 	mov    -0x7fee7fe0(,%eax,4),%ecx
801023cd:	89 0c 16             	mov    %ecx,(%esi,%edx,1)
    pds[i] = pids[i];
801023d0:	8b 0c 85 00 80 10 80 	mov    -0x7fef8000(,%eax,4),%ecx
801023d7:	89 0c 17             	mov    %ecx,(%edi,%edx,1)
  for (int i = 0; i < numframes; i++) {
801023da:	83 c0 01             	add    $0x1,%eax
801023dd:	39 d8                	cmp    %ebx,%eax
801023df:	7c de                	jl     801023bf <dump_physmem+0x28>
  }
  return 0;
801023e1:	b8 00 00 00 00       	mov    $0x0,%eax
801023e6:	5b                   	pop    %ebx
801023e7:	5e                   	pop    %esi
801023e8:	5f                   	pop    %edi
801023e9:	5d                   	pop    %ebp
801023ea:	c3                   	ret    
    return -1;
801023eb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801023f0:	eb f4                	jmp    801023e6 <dump_physmem+0x4f>
801023f2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801023f7:	eb ed                	jmp    801023e6 <dump_physmem+0x4f>

801023f9 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
801023f9:	55                   	push   %ebp
801023fa:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801023fc:	ba 64 00 00 00       	mov    $0x64,%edx
80102401:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
80102402:	a8 01                	test   $0x1,%al
80102404:	0f 84 b5 00 00 00    	je     801024bf <kbdgetc+0xc6>
8010240a:	ba 60 00 00 00       	mov    $0x60,%edx
8010240f:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
80102410:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
80102413:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
80102419:	74 5c                	je     80102477 <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
8010241b:	84 c0                	test   %al,%al
8010241d:	78 66                	js     80102485 <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
8010241f:	8b 0d bc a5 12 80    	mov    0x8012a5bc,%ecx
80102425:	f6 c1 40             	test   $0x40,%cl
80102428:	74 0f                	je     80102439 <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
8010242a:	83 c8 80             	or     $0xffffff80,%eax
8010242d:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
80102430:	83 e1 bf             	and    $0xffffffbf,%ecx
80102433:	89 0d bc a5 12 80    	mov    %ecx,0x8012a5bc
  }

  shift |= shiftcode[data];
80102439:	0f b6 8a 60 6b 10 80 	movzbl -0x7fef94a0(%edx),%ecx
80102440:	0b 0d bc a5 12 80    	or     0x8012a5bc,%ecx
  shift ^= togglecode[data];
80102446:	0f b6 82 60 6a 10 80 	movzbl -0x7fef95a0(%edx),%eax
8010244d:	31 c1                	xor    %eax,%ecx
8010244f:	89 0d bc a5 12 80    	mov    %ecx,0x8012a5bc
  c = charcode[shift & (CTL | SHIFT)][data];
80102455:	89 c8                	mov    %ecx,%eax
80102457:	83 e0 03             	and    $0x3,%eax
8010245a:	8b 04 85 40 6a 10 80 	mov    -0x7fef95c0(,%eax,4),%eax
80102461:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
80102465:	f6 c1 08             	test   $0x8,%cl
80102468:	74 19                	je     80102483 <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
8010246a:	8d 50 9f             	lea    -0x61(%eax),%edx
8010246d:	83 fa 19             	cmp    $0x19,%edx
80102470:	77 40                	ja     801024b2 <kbdgetc+0xb9>
      c += 'A' - 'a';
80102472:	83 e8 20             	sub    $0x20,%eax
80102475:	eb 0c                	jmp    80102483 <kbdgetc+0x8a>
    shift |= E0ESC;
80102477:	83 0d bc a5 12 80 40 	orl    $0x40,0x8012a5bc
    return 0;
8010247e:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
80102483:	5d                   	pop    %ebp
80102484:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
80102485:	8b 0d bc a5 12 80    	mov    0x8012a5bc,%ecx
8010248b:	f6 c1 40             	test   $0x40,%cl
8010248e:	75 05                	jne    80102495 <kbdgetc+0x9c>
80102490:	89 c2                	mov    %eax,%edx
80102492:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
80102495:	0f b6 82 60 6b 10 80 	movzbl -0x7fef94a0(%edx),%eax
8010249c:	83 c8 40             	or     $0x40,%eax
8010249f:	0f b6 c0             	movzbl %al,%eax
801024a2:	f7 d0                	not    %eax
801024a4:	21 c8                	and    %ecx,%eax
801024a6:	a3 bc a5 12 80       	mov    %eax,0x8012a5bc
    return 0;
801024ab:	b8 00 00 00 00       	mov    $0x0,%eax
801024b0:	eb d1                	jmp    80102483 <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
801024b2:	8d 50 bf             	lea    -0x41(%eax),%edx
801024b5:	83 fa 19             	cmp    $0x19,%edx
801024b8:	77 c9                	ja     80102483 <kbdgetc+0x8a>
      c += 'a' - 'A';
801024ba:	83 c0 20             	add    $0x20,%eax
  return c;
801024bd:	eb c4                	jmp    80102483 <kbdgetc+0x8a>
    return -1;
801024bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801024c4:	eb bd                	jmp    80102483 <kbdgetc+0x8a>

801024c6 <kbdintr>:

void
kbdintr(void)
{
801024c6:	55                   	push   %ebp
801024c7:	89 e5                	mov    %esp,%ebp
801024c9:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
801024cc:	68 f9 23 10 80       	push   $0x801023f9
801024d1:	e8 68 e2 ff ff       	call   8010073e <consoleintr>
}
801024d6:	83 c4 10             	add    $0x10,%esp
801024d9:	c9                   	leave  
801024da:	c3                   	ret    

801024db <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
801024db:	55                   	push   %ebp
801024dc:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
801024de:	8b 0d a4 26 13 80    	mov    0x801326a4,%ecx
801024e4:	8d 04 81             	lea    (%ecx,%eax,4),%eax
801024e7:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
801024e9:	a1 a4 26 13 80       	mov    0x801326a4,%eax
801024ee:	8b 40 20             	mov    0x20(%eax),%eax
}
801024f1:	5d                   	pop    %ebp
801024f2:	c3                   	ret    

801024f3 <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
801024f3:	55                   	push   %ebp
801024f4:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801024f6:	ba 70 00 00 00       	mov    $0x70,%edx
801024fb:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801024fc:	ba 71 00 00 00       	mov    $0x71,%edx
80102501:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
80102502:	0f b6 c0             	movzbl %al,%eax
}
80102505:	5d                   	pop    %ebp
80102506:	c3                   	ret    

80102507 <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
80102507:	55                   	push   %ebp
80102508:	89 e5                	mov    %esp,%ebp
8010250a:	53                   	push   %ebx
8010250b:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
8010250d:	b8 00 00 00 00       	mov    $0x0,%eax
80102512:	e8 dc ff ff ff       	call   801024f3 <cmos_read>
80102517:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
80102519:	b8 02 00 00 00       	mov    $0x2,%eax
8010251e:	e8 d0 ff ff ff       	call   801024f3 <cmos_read>
80102523:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
80102526:	b8 04 00 00 00       	mov    $0x4,%eax
8010252b:	e8 c3 ff ff ff       	call   801024f3 <cmos_read>
80102530:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
80102533:	b8 07 00 00 00       	mov    $0x7,%eax
80102538:	e8 b6 ff ff ff       	call   801024f3 <cmos_read>
8010253d:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
80102540:	b8 08 00 00 00       	mov    $0x8,%eax
80102545:	e8 a9 ff ff ff       	call   801024f3 <cmos_read>
8010254a:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
8010254d:	b8 09 00 00 00       	mov    $0x9,%eax
80102552:	e8 9c ff ff ff       	call   801024f3 <cmos_read>
80102557:	89 43 14             	mov    %eax,0x14(%ebx)
}
8010255a:	5b                   	pop    %ebx
8010255b:	5d                   	pop    %ebp
8010255c:	c3                   	ret    

8010255d <lapicinit>:
  if(!lapic)
8010255d:	83 3d a4 26 13 80 00 	cmpl   $0x0,0x801326a4
80102564:	0f 84 fb 00 00 00    	je     80102665 <lapicinit+0x108>
{
8010256a:	55                   	push   %ebp
8010256b:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
8010256d:	ba 3f 01 00 00       	mov    $0x13f,%edx
80102572:	b8 3c 00 00 00       	mov    $0x3c,%eax
80102577:	e8 5f ff ff ff       	call   801024db <lapicw>
  lapicw(TDCR, X1);
8010257c:	ba 0b 00 00 00       	mov    $0xb,%edx
80102581:	b8 f8 00 00 00       	mov    $0xf8,%eax
80102586:	e8 50 ff ff ff       	call   801024db <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
8010258b:	ba 20 00 02 00       	mov    $0x20020,%edx
80102590:	b8 c8 00 00 00       	mov    $0xc8,%eax
80102595:	e8 41 ff ff ff       	call   801024db <lapicw>
  lapicw(TICR, 10000000);
8010259a:	ba 80 96 98 00       	mov    $0x989680,%edx
8010259f:	b8 e0 00 00 00       	mov    $0xe0,%eax
801025a4:	e8 32 ff ff ff       	call   801024db <lapicw>
  lapicw(LINT0, MASKED);
801025a9:	ba 00 00 01 00       	mov    $0x10000,%edx
801025ae:	b8 d4 00 00 00       	mov    $0xd4,%eax
801025b3:	e8 23 ff ff ff       	call   801024db <lapicw>
  lapicw(LINT1, MASKED);
801025b8:	ba 00 00 01 00       	mov    $0x10000,%edx
801025bd:	b8 d8 00 00 00       	mov    $0xd8,%eax
801025c2:	e8 14 ff ff ff       	call   801024db <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801025c7:	a1 a4 26 13 80       	mov    0x801326a4,%eax
801025cc:	8b 40 30             	mov    0x30(%eax),%eax
801025cf:	c1 e8 10             	shr    $0x10,%eax
801025d2:	3c 03                	cmp    $0x3,%al
801025d4:	77 7b                	ja     80102651 <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
801025d6:	ba 33 00 00 00       	mov    $0x33,%edx
801025db:	b8 dc 00 00 00       	mov    $0xdc,%eax
801025e0:	e8 f6 fe ff ff       	call   801024db <lapicw>
  lapicw(ESR, 0);
801025e5:	ba 00 00 00 00       	mov    $0x0,%edx
801025ea:	b8 a0 00 00 00       	mov    $0xa0,%eax
801025ef:	e8 e7 fe ff ff       	call   801024db <lapicw>
  lapicw(ESR, 0);
801025f4:	ba 00 00 00 00       	mov    $0x0,%edx
801025f9:	b8 a0 00 00 00       	mov    $0xa0,%eax
801025fe:	e8 d8 fe ff ff       	call   801024db <lapicw>
  lapicw(EOI, 0);
80102603:	ba 00 00 00 00       	mov    $0x0,%edx
80102608:	b8 2c 00 00 00       	mov    $0x2c,%eax
8010260d:	e8 c9 fe ff ff       	call   801024db <lapicw>
  lapicw(ICRHI, 0);
80102612:	ba 00 00 00 00       	mov    $0x0,%edx
80102617:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010261c:	e8 ba fe ff ff       	call   801024db <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102621:	ba 00 85 08 00       	mov    $0x88500,%edx
80102626:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010262b:	e8 ab fe ff ff       	call   801024db <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102630:	a1 a4 26 13 80       	mov    0x801326a4,%eax
80102635:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
8010263b:	f6 c4 10             	test   $0x10,%ah
8010263e:	75 f0                	jne    80102630 <lapicinit+0xd3>
  lapicw(TPR, 0);
80102640:	ba 00 00 00 00       	mov    $0x0,%edx
80102645:	b8 20 00 00 00       	mov    $0x20,%eax
8010264a:	e8 8c fe ff ff       	call   801024db <lapicw>
}
8010264f:	5d                   	pop    %ebp
80102650:	c3                   	ret    
    lapicw(PCINT, MASKED);
80102651:	ba 00 00 01 00       	mov    $0x10000,%edx
80102656:	b8 d0 00 00 00       	mov    $0xd0,%eax
8010265b:	e8 7b fe ff ff       	call   801024db <lapicw>
80102660:	e9 71 ff ff ff       	jmp    801025d6 <lapicinit+0x79>
80102665:	f3 c3                	repz ret 

80102667 <lapicid>:
{
80102667:	55                   	push   %ebp
80102668:	89 e5                	mov    %esp,%ebp
  if (!lapic)
8010266a:	a1 a4 26 13 80       	mov    0x801326a4,%eax
8010266f:	85 c0                	test   %eax,%eax
80102671:	74 08                	je     8010267b <lapicid+0x14>
  return lapic[ID] >> 24;
80102673:	8b 40 20             	mov    0x20(%eax),%eax
80102676:	c1 e8 18             	shr    $0x18,%eax
}
80102679:	5d                   	pop    %ebp
8010267a:	c3                   	ret    
    return 0;
8010267b:	b8 00 00 00 00       	mov    $0x0,%eax
80102680:	eb f7                	jmp    80102679 <lapicid+0x12>

80102682 <lapiceoi>:
  if(lapic)
80102682:	83 3d a4 26 13 80 00 	cmpl   $0x0,0x801326a4
80102689:	74 14                	je     8010269f <lapiceoi+0x1d>
{
8010268b:	55                   	push   %ebp
8010268c:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
8010268e:	ba 00 00 00 00       	mov    $0x0,%edx
80102693:	b8 2c 00 00 00       	mov    $0x2c,%eax
80102698:	e8 3e fe ff ff       	call   801024db <lapicw>
}
8010269d:	5d                   	pop    %ebp
8010269e:	c3                   	ret    
8010269f:	f3 c3                	repz ret 

801026a1 <microdelay>:
{
801026a1:	55                   	push   %ebp
801026a2:	89 e5                	mov    %esp,%ebp
}
801026a4:	5d                   	pop    %ebp
801026a5:	c3                   	ret    

801026a6 <lapicstartap>:
{
801026a6:	55                   	push   %ebp
801026a7:	89 e5                	mov    %esp,%ebp
801026a9:	57                   	push   %edi
801026aa:	56                   	push   %esi
801026ab:	53                   	push   %ebx
801026ac:	8b 75 08             	mov    0x8(%ebp),%esi
801026af:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801026b2:	b8 0f 00 00 00       	mov    $0xf,%eax
801026b7:	ba 70 00 00 00       	mov    $0x70,%edx
801026bc:	ee                   	out    %al,(%dx)
801026bd:	b8 0a 00 00 00       	mov    $0xa,%eax
801026c2:	ba 71 00 00 00       	mov    $0x71,%edx
801026c7:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
801026c8:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
801026cf:	00 00 
  wrv[1] = addr >> 4;
801026d1:	89 f8                	mov    %edi,%eax
801026d3:	c1 e8 04             	shr    $0x4,%eax
801026d6:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
801026dc:	c1 e6 18             	shl    $0x18,%esi
801026df:	89 f2                	mov    %esi,%edx
801026e1:	b8 c4 00 00 00       	mov    $0xc4,%eax
801026e6:	e8 f0 fd ff ff       	call   801024db <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801026eb:	ba 00 c5 00 00       	mov    $0xc500,%edx
801026f0:	b8 c0 00 00 00       	mov    $0xc0,%eax
801026f5:	e8 e1 fd ff ff       	call   801024db <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
801026fa:	ba 00 85 00 00       	mov    $0x8500,%edx
801026ff:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102704:	e8 d2 fd ff ff       	call   801024db <lapicw>
  for(i = 0; i < 2; i++){
80102709:	bb 00 00 00 00       	mov    $0x0,%ebx
8010270e:	eb 21                	jmp    80102731 <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
80102710:	89 f2                	mov    %esi,%edx
80102712:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102717:	e8 bf fd ff ff       	call   801024db <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
8010271c:	89 fa                	mov    %edi,%edx
8010271e:	c1 ea 0c             	shr    $0xc,%edx
80102721:	80 ce 06             	or     $0x6,%dh
80102724:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102729:	e8 ad fd ff ff       	call   801024db <lapicw>
  for(i = 0; i < 2; i++){
8010272e:	83 c3 01             	add    $0x1,%ebx
80102731:	83 fb 01             	cmp    $0x1,%ebx
80102734:	7e da                	jle    80102710 <lapicstartap+0x6a>
}
80102736:	5b                   	pop    %ebx
80102737:	5e                   	pop    %esi
80102738:	5f                   	pop    %edi
80102739:	5d                   	pop    %ebp
8010273a:	c3                   	ret    

8010273b <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
8010273b:	55                   	push   %ebp
8010273c:	89 e5                	mov    %esp,%ebp
8010273e:	57                   	push   %edi
8010273f:	56                   	push   %esi
80102740:	53                   	push   %ebx
80102741:	83 ec 3c             	sub    $0x3c,%esp
80102744:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
80102747:	b8 0b 00 00 00       	mov    $0xb,%eax
8010274c:	e8 a2 fd ff ff       	call   801024f3 <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
80102751:	83 e0 04             	and    $0x4,%eax
80102754:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
80102756:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102759:	e8 a9 fd ff ff       	call   80102507 <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
8010275e:	b8 0a 00 00 00       	mov    $0xa,%eax
80102763:	e8 8b fd ff ff       	call   801024f3 <cmos_read>
80102768:	a8 80                	test   $0x80,%al
8010276a:	75 ea                	jne    80102756 <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
8010276c:	8d 5d b8             	lea    -0x48(%ebp),%ebx
8010276f:	89 d8                	mov    %ebx,%eax
80102771:	e8 91 fd ff ff       	call   80102507 <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
80102776:	83 ec 04             	sub    $0x4,%esp
80102779:	6a 18                	push   $0x18
8010277b:	53                   	push   %ebx
8010277c:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010277f:	50                   	push   %eax
80102780:	e8 f6 17 00 00       	call   80103f7b <memcmp>
80102785:	83 c4 10             	add    $0x10,%esp
80102788:	85 c0                	test   %eax,%eax
8010278a:	75 ca                	jne    80102756 <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
8010278c:	85 ff                	test   %edi,%edi
8010278e:	0f 85 84 00 00 00    	jne    80102818 <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80102794:	8b 55 d0             	mov    -0x30(%ebp),%edx
80102797:	89 d0                	mov    %edx,%eax
80102799:	c1 e8 04             	shr    $0x4,%eax
8010279c:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010279f:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801027a2:	83 e2 0f             	and    $0xf,%edx
801027a5:	01 d0                	add    %edx,%eax
801027a7:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
801027aa:	8b 55 d4             	mov    -0x2c(%ebp),%edx
801027ad:	89 d0                	mov    %edx,%eax
801027af:	c1 e8 04             	shr    $0x4,%eax
801027b2:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801027b5:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801027b8:	83 e2 0f             	and    $0xf,%edx
801027bb:	01 d0                	add    %edx,%eax
801027bd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
801027c0:	8b 55 d8             	mov    -0x28(%ebp),%edx
801027c3:	89 d0                	mov    %edx,%eax
801027c5:	c1 e8 04             	shr    $0x4,%eax
801027c8:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801027cb:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801027ce:	83 e2 0f             	and    $0xf,%edx
801027d1:	01 d0                	add    %edx,%eax
801027d3:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
801027d6:	8b 55 dc             	mov    -0x24(%ebp),%edx
801027d9:	89 d0                	mov    %edx,%eax
801027db:	c1 e8 04             	shr    $0x4,%eax
801027de:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801027e1:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801027e4:	83 e2 0f             	and    $0xf,%edx
801027e7:	01 d0                	add    %edx,%eax
801027e9:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
801027ec:	8b 55 e0             	mov    -0x20(%ebp),%edx
801027ef:	89 d0                	mov    %edx,%eax
801027f1:	c1 e8 04             	shr    $0x4,%eax
801027f4:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801027f7:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801027fa:	83 e2 0f             	and    $0xf,%edx
801027fd:	01 d0                	add    %edx,%eax
801027ff:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
80102802:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80102805:	89 d0                	mov    %edx,%eax
80102807:	c1 e8 04             	shr    $0x4,%eax
8010280a:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010280d:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102810:	83 e2 0f             	and    $0xf,%edx
80102813:	01 d0                	add    %edx,%eax
80102815:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
80102818:	8b 45 d0             	mov    -0x30(%ebp),%eax
8010281b:	89 06                	mov    %eax,(%esi)
8010281d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102820:	89 46 04             	mov    %eax,0x4(%esi)
80102823:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102826:	89 46 08             	mov    %eax,0x8(%esi)
80102829:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010282c:	89 46 0c             	mov    %eax,0xc(%esi)
8010282f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80102832:	89 46 10             	mov    %eax,0x10(%esi)
80102835:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102838:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
8010283b:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
80102842:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102845:	5b                   	pop    %ebx
80102846:	5e                   	pop    %esi
80102847:	5f                   	pop    %edi
80102848:	5d                   	pop    %ebp
80102849:	c3                   	ret    

8010284a <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010284a:	55                   	push   %ebp
8010284b:	89 e5                	mov    %esp,%ebp
8010284d:	53                   	push   %ebx
8010284e:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102851:	ff 35 f4 26 13 80    	pushl  0x801326f4
80102857:	ff 35 04 27 13 80    	pushl  0x80132704
8010285d:	e8 0a d9 ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
80102862:	8b 58 5c             	mov    0x5c(%eax),%ebx
80102865:	89 1d 08 27 13 80    	mov    %ebx,0x80132708
  for (i = 0; i < log.lh.n; i++) {
8010286b:	83 c4 10             	add    $0x10,%esp
8010286e:	ba 00 00 00 00       	mov    $0x0,%edx
80102873:	eb 0e                	jmp    80102883 <read_head+0x39>
    log.lh.block[i] = lh->block[i];
80102875:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
80102879:	89 0c 95 0c 27 13 80 	mov    %ecx,-0x7fecd8f4(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
80102880:	83 c2 01             	add    $0x1,%edx
80102883:	39 d3                	cmp    %edx,%ebx
80102885:	7f ee                	jg     80102875 <read_head+0x2b>
  }
  brelse(buf);
80102887:	83 ec 0c             	sub    $0xc,%esp
8010288a:	50                   	push   %eax
8010288b:	e8 45 d9 ff ff       	call   801001d5 <brelse>
}
80102890:	83 c4 10             	add    $0x10,%esp
80102893:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102896:	c9                   	leave  
80102897:	c3                   	ret    

80102898 <install_trans>:
{
80102898:	55                   	push   %ebp
80102899:	89 e5                	mov    %esp,%ebp
8010289b:	57                   	push   %edi
8010289c:	56                   	push   %esi
8010289d:	53                   	push   %ebx
8010289e:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
801028a1:	bb 00 00 00 00       	mov    $0x0,%ebx
801028a6:	eb 66                	jmp    8010290e <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801028a8:	89 d8                	mov    %ebx,%eax
801028aa:	03 05 f4 26 13 80    	add    0x801326f4,%eax
801028b0:	83 c0 01             	add    $0x1,%eax
801028b3:	83 ec 08             	sub    $0x8,%esp
801028b6:	50                   	push   %eax
801028b7:	ff 35 04 27 13 80    	pushl  0x80132704
801028bd:	e8 aa d8 ff ff       	call   8010016c <bread>
801028c2:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
801028c4:	83 c4 08             	add    $0x8,%esp
801028c7:	ff 34 9d 0c 27 13 80 	pushl  -0x7fecd8f4(,%ebx,4)
801028ce:	ff 35 04 27 13 80    	pushl  0x80132704
801028d4:	e8 93 d8 ff ff       	call   8010016c <bread>
801028d9:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801028db:	8d 57 5c             	lea    0x5c(%edi),%edx
801028de:	8d 40 5c             	lea    0x5c(%eax),%eax
801028e1:	83 c4 0c             	add    $0xc,%esp
801028e4:	68 00 02 00 00       	push   $0x200
801028e9:	52                   	push   %edx
801028ea:	50                   	push   %eax
801028eb:	e8 c0 16 00 00       	call   80103fb0 <memmove>
    bwrite(dbuf);  // write dst to disk
801028f0:	89 34 24             	mov    %esi,(%esp)
801028f3:	e8 a2 d8 ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
801028f8:	89 3c 24             	mov    %edi,(%esp)
801028fb:	e8 d5 d8 ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
80102900:	89 34 24             	mov    %esi,(%esp)
80102903:	e8 cd d8 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102908:	83 c3 01             	add    $0x1,%ebx
8010290b:	83 c4 10             	add    $0x10,%esp
8010290e:	39 1d 08 27 13 80    	cmp    %ebx,0x80132708
80102914:	7f 92                	jg     801028a8 <install_trans+0x10>
}
80102916:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102919:	5b                   	pop    %ebx
8010291a:	5e                   	pop    %esi
8010291b:	5f                   	pop    %edi
8010291c:	5d                   	pop    %ebp
8010291d:	c3                   	ret    

8010291e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
8010291e:	55                   	push   %ebp
8010291f:	89 e5                	mov    %esp,%ebp
80102921:	53                   	push   %ebx
80102922:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102925:	ff 35 f4 26 13 80    	pushl  0x801326f4
8010292b:	ff 35 04 27 13 80    	pushl  0x80132704
80102931:	e8 36 d8 ff ff       	call   8010016c <bread>
80102936:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
80102938:	8b 0d 08 27 13 80    	mov    0x80132708,%ecx
8010293e:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
80102941:	83 c4 10             	add    $0x10,%esp
80102944:	b8 00 00 00 00       	mov    $0x0,%eax
80102949:	eb 0e                	jmp    80102959 <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
8010294b:	8b 14 85 0c 27 13 80 	mov    -0x7fecd8f4(,%eax,4),%edx
80102952:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
80102956:	83 c0 01             	add    $0x1,%eax
80102959:	39 c1                	cmp    %eax,%ecx
8010295b:	7f ee                	jg     8010294b <write_head+0x2d>
  }
  bwrite(buf);
8010295d:	83 ec 0c             	sub    $0xc,%esp
80102960:	53                   	push   %ebx
80102961:	e8 34 d8 ff ff       	call   8010019a <bwrite>
  brelse(buf);
80102966:	89 1c 24             	mov    %ebx,(%esp)
80102969:	e8 67 d8 ff ff       	call   801001d5 <brelse>
}
8010296e:	83 c4 10             	add    $0x10,%esp
80102971:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102974:	c9                   	leave  
80102975:	c3                   	ret    

80102976 <recover_from_log>:

static void
recover_from_log(void)
{
80102976:	55                   	push   %ebp
80102977:	89 e5                	mov    %esp,%ebp
80102979:	83 ec 08             	sub    $0x8,%esp
  read_head();
8010297c:	e8 c9 fe ff ff       	call   8010284a <read_head>
  install_trans(); // if committed, copy from log to disk
80102981:	e8 12 ff ff ff       	call   80102898 <install_trans>
  log.lh.n = 0;
80102986:	c7 05 08 27 13 80 00 	movl   $0x0,0x80132708
8010298d:	00 00 00 
  write_head(); // clear the log
80102990:	e8 89 ff ff ff       	call   8010291e <write_head>
}
80102995:	c9                   	leave  
80102996:	c3                   	ret    

80102997 <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
80102997:	55                   	push   %ebp
80102998:	89 e5                	mov    %esp,%ebp
8010299a:	57                   	push   %edi
8010299b:	56                   	push   %esi
8010299c:	53                   	push   %ebx
8010299d:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801029a0:	bb 00 00 00 00       	mov    $0x0,%ebx
801029a5:	eb 66                	jmp    80102a0d <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
801029a7:	89 d8                	mov    %ebx,%eax
801029a9:	03 05 f4 26 13 80    	add    0x801326f4,%eax
801029af:	83 c0 01             	add    $0x1,%eax
801029b2:	83 ec 08             	sub    $0x8,%esp
801029b5:	50                   	push   %eax
801029b6:	ff 35 04 27 13 80    	pushl  0x80132704
801029bc:	e8 ab d7 ff ff       	call   8010016c <bread>
801029c1:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801029c3:	83 c4 08             	add    $0x8,%esp
801029c6:	ff 34 9d 0c 27 13 80 	pushl  -0x7fecd8f4(,%ebx,4)
801029cd:	ff 35 04 27 13 80    	pushl  0x80132704
801029d3:	e8 94 d7 ff ff       	call   8010016c <bread>
801029d8:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
801029da:	8d 50 5c             	lea    0x5c(%eax),%edx
801029dd:	8d 46 5c             	lea    0x5c(%esi),%eax
801029e0:	83 c4 0c             	add    $0xc,%esp
801029e3:	68 00 02 00 00       	push   $0x200
801029e8:	52                   	push   %edx
801029e9:	50                   	push   %eax
801029ea:	e8 c1 15 00 00       	call   80103fb0 <memmove>
    bwrite(to);  // write the log
801029ef:	89 34 24             	mov    %esi,(%esp)
801029f2:	e8 a3 d7 ff ff       	call   8010019a <bwrite>
    brelse(from);
801029f7:	89 3c 24             	mov    %edi,(%esp)
801029fa:	e8 d6 d7 ff ff       	call   801001d5 <brelse>
    brelse(to);
801029ff:	89 34 24             	mov    %esi,(%esp)
80102a02:	e8 ce d7 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102a07:	83 c3 01             	add    $0x1,%ebx
80102a0a:	83 c4 10             	add    $0x10,%esp
80102a0d:	39 1d 08 27 13 80    	cmp    %ebx,0x80132708
80102a13:	7f 92                	jg     801029a7 <write_log+0x10>
  }
}
80102a15:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102a18:	5b                   	pop    %ebx
80102a19:	5e                   	pop    %esi
80102a1a:	5f                   	pop    %edi
80102a1b:	5d                   	pop    %ebp
80102a1c:	c3                   	ret    

80102a1d <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
80102a1d:	83 3d 08 27 13 80 00 	cmpl   $0x0,0x80132708
80102a24:	7e 26                	jle    80102a4c <commit+0x2f>
{
80102a26:	55                   	push   %ebp
80102a27:	89 e5                	mov    %esp,%ebp
80102a29:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
80102a2c:	e8 66 ff ff ff       	call   80102997 <write_log>
    write_head();    // Write header to disk -- the real commit
80102a31:	e8 e8 fe ff ff       	call   8010291e <write_head>
    install_trans(); // Now install writes to home locations
80102a36:	e8 5d fe ff ff       	call   80102898 <install_trans>
    log.lh.n = 0;
80102a3b:	c7 05 08 27 13 80 00 	movl   $0x0,0x80132708
80102a42:	00 00 00 
    write_head();    // Erase the transaction from the log
80102a45:	e8 d4 fe ff ff       	call   8010291e <write_head>
  }
}
80102a4a:	c9                   	leave  
80102a4b:	c3                   	ret    
80102a4c:	f3 c3                	repz ret 

80102a4e <initlog>:
{
80102a4e:	55                   	push   %ebp
80102a4f:	89 e5                	mov    %esp,%ebp
80102a51:	53                   	push   %ebx
80102a52:	83 ec 2c             	sub    $0x2c,%esp
80102a55:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
80102a58:	68 60 6c 10 80       	push   $0x80106c60
80102a5d:	68 c0 26 13 80       	push   $0x801326c0
80102a62:	e8 e6 12 00 00       	call   80103d4d <initlock>
  readsb(dev, &sb);
80102a67:	83 c4 08             	add    $0x8,%esp
80102a6a:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102a6d:	50                   	push   %eax
80102a6e:	53                   	push   %ebx
80102a6f:	e8 c2 e7 ff ff       	call   80101236 <readsb>
  log.start = sb.logstart;
80102a74:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102a77:	a3 f4 26 13 80       	mov    %eax,0x801326f4
  log.size = sb.nlog;
80102a7c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102a7f:	a3 f8 26 13 80       	mov    %eax,0x801326f8
  log.dev = dev;
80102a84:	89 1d 04 27 13 80    	mov    %ebx,0x80132704
  recover_from_log();
80102a8a:	e8 e7 fe ff ff       	call   80102976 <recover_from_log>
}
80102a8f:	83 c4 10             	add    $0x10,%esp
80102a92:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102a95:	c9                   	leave  
80102a96:	c3                   	ret    

80102a97 <begin_op>:
{
80102a97:	55                   	push   %ebp
80102a98:	89 e5                	mov    %esp,%ebp
80102a9a:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
80102a9d:	68 c0 26 13 80       	push   $0x801326c0
80102aa2:	e8 e2 13 00 00       	call   80103e89 <acquire>
80102aa7:	83 c4 10             	add    $0x10,%esp
80102aaa:	eb 15                	jmp    80102ac1 <begin_op+0x2a>
      sleep(&log, &log.lock);
80102aac:	83 ec 08             	sub    $0x8,%esp
80102aaf:	68 c0 26 13 80       	push   $0x801326c0
80102ab4:	68 c0 26 13 80       	push   $0x801326c0
80102ab9:	e8 d0 0e 00 00       	call   8010398e <sleep>
80102abe:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
80102ac1:	83 3d 00 27 13 80 00 	cmpl   $0x0,0x80132700
80102ac8:	75 e2                	jne    80102aac <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80102aca:	a1 fc 26 13 80       	mov    0x801326fc,%eax
80102acf:	83 c0 01             	add    $0x1,%eax
80102ad2:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102ad5:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
80102ad8:	03 15 08 27 13 80    	add    0x80132708,%edx
80102ade:	83 fa 1e             	cmp    $0x1e,%edx
80102ae1:	7e 17                	jle    80102afa <begin_op+0x63>
      sleep(&log, &log.lock);
80102ae3:	83 ec 08             	sub    $0x8,%esp
80102ae6:	68 c0 26 13 80       	push   $0x801326c0
80102aeb:	68 c0 26 13 80       	push   $0x801326c0
80102af0:	e8 99 0e 00 00       	call   8010398e <sleep>
80102af5:	83 c4 10             	add    $0x10,%esp
80102af8:	eb c7                	jmp    80102ac1 <begin_op+0x2a>
      log.outstanding += 1;
80102afa:	a3 fc 26 13 80       	mov    %eax,0x801326fc
      release(&log.lock);
80102aff:	83 ec 0c             	sub    $0xc,%esp
80102b02:	68 c0 26 13 80       	push   $0x801326c0
80102b07:	e8 e2 13 00 00       	call   80103eee <release>
}
80102b0c:	83 c4 10             	add    $0x10,%esp
80102b0f:	c9                   	leave  
80102b10:	c3                   	ret    

80102b11 <end_op>:
{
80102b11:	55                   	push   %ebp
80102b12:	89 e5                	mov    %esp,%ebp
80102b14:	53                   	push   %ebx
80102b15:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
80102b18:	68 c0 26 13 80       	push   $0x801326c0
80102b1d:	e8 67 13 00 00       	call   80103e89 <acquire>
  log.outstanding -= 1;
80102b22:	a1 fc 26 13 80       	mov    0x801326fc,%eax
80102b27:	83 e8 01             	sub    $0x1,%eax
80102b2a:	a3 fc 26 13 80       	mov    %eax,0x801326fc
  if(log.committing)
80102b2f:	8b 1d 00 27 13 80    	mov    0x80132700,%ebx
80102b35:	83 c4 10             	add    $0x10,%esp
80102b38:	85 db                	test   %ebx,%ebx
80102b3a:	75 2c                	jne    80102b68 <end_op+0x57>
  if(log.outstanding == 0){
80102b3c:	85 c0                	test   %eax,%eax
80102b3e:	75 35                	jne    80102b75 <end_op+0x64>
    log.committing = 1;
80102b40:	c7 05 00 27 13 80 01 	movl   $0x1,0x80132700
80102b47:	00 00 00 
    do_commit = 1;
80102b4a:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
80102b4f:	83 ec 0c             	sub    $0xc,%esp
80102b52:	68 c0 26 13 80       	push   $0x801326c0
80102b57:	e8 92 13 00 00       	call   80103eee <release>
  if(do_commit){
80102b5c:	83 c4 10             	add    $0x10,%esp
80102b5f:	85 db                	test   %ebx,%ebx
80102b61:	75 24                	jne    80102b87 <end_op+0x76>
}
80102b63:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102b66:	c9                   	leave  
80102b67:	c3                   	ret    
    panic("log.committing");
80102b68:	83 ec 0c             	sub    $0xc,%esp
80102b6b:	68 64 6c 10 80       	push   $0x80106c64
80102b70:	e8 d3 d7 ff ff       	call   80100348 <panic>
    wakeup(&log);
80102b75:	83 ec 0c             	sub    $0xc,%esp
80102b78:	68 c0 26 13 80       	push   $0x801326c0
80102b7d:	e8 71 0f 00 00       	call   80103af3 <wakeup>
80102b82:	83 c4 10             	add    $0x10,%esp
80102b85:	eb c8                	jmp    80102b4f <end_op+0x3e>
    commit();
80102b87:	e8 91 fe ff ff       	call   80102a1d <commit>
    acquire(&log.lock);
80102b8c:	83 ec 0c             	sub    $0xc,%esp
80102b8f:	68 c0 26 13 80       	push   $0x801326c0
80102b94:	e8 f0 12 00 00       	call   80103e89 <acquire>
    log.committing = 0;
80102b99:	c7 05 00 27 13 80 00 	movl   $0x0,0x80132700
80102ba0:	00 00 00 
    wakeup(&log);
80102ba3:	c7 04 24 c0 26 13 80 	movl   $0x801326c0,(%esp)
80102baa:	e8 44 0f 00 00       	call   80103af3 <wakeup>
    release(&log.lock);
80102baf:	c7 04 24 c0 26 13 80 	movl   $0x801326c0,(%esp)
80102bb6:	e8 33 13 00 00       	call   80103eee <release>
80102bbb:	83 c4 10             	add    $0x10,%esp
}
80102bbe:	eb a3                	jmp    80102b63 <end_op+0x52>

80102bc0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80102bc0:	55                   	push   %ebp
80102bc1:	89 e5                	mov    %esp,%ebp
80102bc3:	53                   	push   %ebx
80102bc4:	83 ec 04             	sub    $0x4,%esp
80102bc7:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80102bca:	8b 15 08 27 13 80    	mov    0x80132708,%edx
80102bd0:	83 fa 1d             	cmp    $0x1d,%edx
80102bd3:	7f 45                	jg     80102c1a <log_write+0x5a>
80102bd5:	a1 f8 26 13 80       	mov    0x801326f8,%eax
80102bda:	83 e8 01             	sub    $0x1,%eax
80102bdd:	39 c2                	cmp    %eax,%edx
80102bdf:	7d 39                	jge    80102c1a <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102be1:	83 3d fc 26 13 80 00 	cmpl   $0x0,0x801326fc
80102be8:	7e 3d                	jle    80102c27 <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102bea:	83 ec 0c             	sub    $0xc,%esp
80102bed:	68 c0 26 13 80       	push   $0x801326c0
80102bf2:	e8 92 12 00 00       	call   80103e89 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80102bf7:	83 c4 10             	add    $0x10,%esp
80102bfa:	b8 00 00 00 00       	mov    $0x0,%eax
80102bff:	8b 15 08 27 13 80    	mov    0x80132708,%edx
80102c05:	39 c2                	cmp    %eax,%edx
80102c07:	7e 2b                	jle    80102c34 <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102c09:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102c0c:	39 0c 85 0c 27 13 80 	cmp    %ecx,-0x7fecd8f4(,%eax,4)
80102c13:	74 1f                	je     80102c34 <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
80102c15:	83 c0 01             	add    $0x1,%eax
80102c18:	eb e5                	jmp    80102bff <log_write+0x3f>
    panic("too big a transaction");
80102c1a:	83 ec 0c             	sub    $0xc,%esp
80102c1d:	68 73 6c 10 80       	push   $0x80106c73
80102c22:	e8 21 d7 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102c27:	83 ec 0c             	sub    $0xc,%esp
80102c2a:	68 89 6c 10 80       	push   $0x80106c89
80102c2f:	e8 14 d7 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102c34:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102c37:	89 0c 85 0c 27 13 80 	mov    %ecx,-0x7fecd8f4(,%eax,4)
  if (i == log.lh.n)
80102c3e:	39 c2                	cmp    %eax,%edx
80102c40:	74 18                	je     80102c5a <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102c42:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102c45:	83 ec 0c             	sub    $0xc,%esp
80102c48:	68 c0 26 13 80       	push   $0x801326c0
80102c4d:	e8 9c 12 00 00       	call   80103eee <release>
}
80102c52:	83 c4 10             	add    $0x10,%esp
80102c55:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102c58:	c9                   	leave  
80102c59:	c3                   	ret    
    log.lh.n++;
80102c5a:	83 c2 01             	add    $0x1,%edx
80102c5d:	89 15 08 27 13 80    	mov    %edx,0x80132708
80102c63:	eb dd                	jmp    80102c42 <log_write+0x82>

80102c65 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102c65:	55                   	push   %ebp
80102c66:	89 e5                	mov    %esp,%ebp
80102c68:	53                   	push   %ebx
80102c69:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102c6c:	68 8a 00 00 00       	push   $0x8a
80102c71:	68 8c a4 12 80       	push   $0x8012a48c
80102c76:	68 00 70 00 80       	push   $0x80007000
80102c7b:	e8 30 13 00 00       	call   80103fb0 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102c80:	83 c4 10             	add    $0x10,%esp
80102c83:	bb c0 27 13 80       	mov    $0x801327c0,%ebx
80102c88:	eb 06                	jmp    80102c90 <startothers+0x2b>
80102c8a:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102c90:	69 05 40 2d 13 80 b0 	imul   $0xb0,0x80132d40,%eax
80102c97:	00 00 00 
80102c9a:	05 c0 27 13 80       	add    $0x801327c0,%eax
80102c9f:	39 d8                	cmp    %ebx,%eax
80102ca1:	76 4c                	jbe    80102cef <startothers+0x8a>
    if(c == mycpu())  // We've started already.
80102ca3:	e8 c8 07 00 00       	call   80103470 <mycpu>
80102ca8:	39 d8                	cmp    %ebx,%eax
80102caa:	74 de                	je     80102c8a <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80102cac:	e8 a3 f4 ff ff       	call   80102154 <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102cb1:	05 00 10 00 00       	add    $0x1000,%eax
80102cb6:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102cbb:	c7 05 f8 6f 00 80 33 	movl   $0x80102d33,0x80006ff8
80102cc2:	2d 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102cc5:	c7 05 f4 6f 00 80 00 	movl   $0x129000,0x80006ff4
80102ccc:	90 12 00 

    lapicstartap(c->apicid, V2P(code));
80102ccf:	83 ec 08             	sub    $0x8,%esp
80102cd2:	68 00 70 00 00       	push   $0x7000
80102cd7:	0f b6 03             	movzbl (%ebx),%eax
80102cda:	50                   	push   %eax
80102cdb:	e8 c6 f9 ff ff       	call   801026a6 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102ce0:	83 c4 10             	add    $0x10,%esp
80102ce3:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102ce9:	85 c0                	test   %eax,%eax
80102ceb:	74 f6                	je     80102ce3 <startothers+0x7e>
80102ced:	eb 9b                	jmp    80102c8a <startothers+0x25>
      ;
  }
}
80102cef:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102cf2:	c9                   	leave  
80102cf3:	c3                   	ret    

80102cf4 <mpmain>:
{
80102cf4:	55                   	push   %ebp
80102cf5:	89 e5                	mov    %esp,%ebp
80102cf7:	53                   	push   %ebx
80102cf8:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102cfb:	e8 cc 07 00 00       	call   801034cc <cpuid>
80102d00:	89 c3                	mov    %eax,%ebx
80102d02:	e8 c5 07 00 00       	call   801034cc <cpuid>
80102d07:	83 ec 04             	sub    $0x4,%esp
80102d0a:	53                   	push   %ebx
80102d0b:	50                   	push   %eax
80102d0c:	68 a4 6c 10 80       	push   $0x80106ca4
80102d11:	e8 f5 d8 ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102d16:	e8 ec 23 00 00       	call   80105107 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102d1b:	e8 50 07 00 00       	call   80103470 <mycpu>
80102d20:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102d22:	b8 01 00 00 00       	mov    $0x1,%eax
80102d27:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102d2e:	e8 36 0a 00 00       	call   80103769 <scheduler>

80102d33 <mpenter>:
{
80102d33:	55                   	push   %ebp
80102d34:	89 e5                	mov    %esp,%ebp
80102d36:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102d39:	e8 da 33 00 00       	call   80106118 <switchkvm>
  seginit();
80102d3e:	e8 89 32 00 00       	call   80105fcc <seginit>
  lapicinit();
80102d43:	e8 15 f8 ff ff       	call   8010255d <lapicinit>
  mpmain();
80102d48:	e8 a7 ff ff ff       	call   80102cf4 <mpmain>

80102d4d <main>:
{
80102d4d:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102d51:	83 e4 f0             	and    $0xfffffff0,%esp
80102d54:	ff 71 fc             	pushl  -0x4(%ecx)
80102d57:	55                   	push   %ebp
80102d58:	89 e5                	mov    %esp,%ebp
80102d5a:	51                   	push   %ecx
80102d5b:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102d5e:	68 00 00 40 80       	push   $0x80400000
80102d63:	68 e8 54 13 80       	push   $0x801354e8
80102d68:	e8 fc f2 ff ff       	call   80102069 <kinit1>
  kvmalloc();      // kernel page table
80102d6d:	e8 4e 38 00 00       	call   801065c0 <kvmalloc>
  mpinit();        // detect other processors
80102d72:	e8 c9 01 00 00       	call   80102f40 <mpinit>
  lapicinit();     // interrupt controller
80102d77:	e8 e1 f7 ff ff       	call   8010255d <lapicinit>
  seginit();       // segment descriptors
80102d7c:	e8 4b 32 00 00       	call   80105fcc <seginit>
  picinit();       // disable pic
80102d81:	e8 82 02 00 00       	call   80103008 <picinit>
  ioapicinit();    // another interrupt controller
80102d86:	e8 6f f1 ff ff       	call   80101efa <ioapicinit>
  consoleinit();   // console hardware
80102d8b:	e8 fe da ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102d90:	e8 20 26 00 00       	call   801053b5 <uartinit>
  pinit();         // process table
80102d95:	e8 bc 06 00 00       	call   80103456 <pinit>
  tvinit();        // trap vectors
80102d9a:	e8 b7 22 00 00       	call   80105056 <tvinit>
  binit();         // buffer cache
80102d9f:	e8 50 d3 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102da4:	e8 6a de ff ff       	call   80100c13 <fileinit>
  ideinit();       // disk 
80102da9:	e8 52 ef ff ff       	call   80101d00 <ideinit>
  startothers();   // start other processors
80102dae:	e8 b2 fe ff ff       	call   80102c65 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102db3:	83 c4 08             	add    $0x8,%esp
80102db6:	68 00 00 00 8e       	push   $0x8e000000
80102dbb:	68 00 00 40 80       	push   $0x80400000
80102dc0:	e8 d6 f2 ff ff       	call   8010209b <kinit2>
  userinit();      // first user process
80102dc5:	e8 41 07 00 00       	call   8010350b <userinit>
  mpmain();        // finish this processor's setup
80102dca:	e8 25 ff ff ff       	call   80102cf4 <mpmain>

80102dcf <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102dcf:	55                   	push   %ebp
80102dd0:	89 e5                	mov    %esp,%ebp
80102dd2:	56                   	push   %esi
80102dd3:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102dd4:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102dd9:	b9 00 00 00 00       	mov    $0x0,%ecx
80102dde:	eb 09                	jmp    80102de9 <sum+0x1a>
    sum += addr[i];
80102de0:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102de4:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102de6:	83 c1 01             	add    $0x1,%ecx
80102de9:	39 d1                	cmp    %edx,%ecx
80102deb:	7c f3                	jl     80102de0 <sum+0x11>
  return sum;
}
80102ded:	89 d8                	mov    %ebx,%eax
80102def:	5b                   	pop    %ebx
80102df0:	5e                   	pop    %esi
80102df1:	5d                   	pop    %ebp
80102df2:	c3                   	ret    

80102df3 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102df3:	55                   	push   %ebp
80102df4:	89 e5                	mov    %esp,%ebp
80102df6:	56                   	push   %esi
80102df7:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102df8:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102dfe:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102e00:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102e02:	eb 03                	jmp    80102e07 <mpsearch1+0x14>
80102e04:	83 c3 10             	add    $0x10,%ebx
80102e07:	39 f3                	cmp    %esi,%ebx
80102e09:	73 29                	jae    80102e34 <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102e0b:	83 ec 04             	sub    $0x4,%esp
80102e0e:	6a 04                	push   $0x4
80102e10:	68 b8 6c 10 80       	push   $0x80106cb8
80102e15:	53                   	push   %ebx
80102e16:	e8 60 11 00 00       	call   80103f7b <memcmp>
80102e1b:	83 c4 10             	add    $0x10,%esp
80102e1e:	85 c0                	test   %eax,%eax
80102e20:	75 e2                	jne    80102e04 <mpsearch1+0x11>
80102e22:	ba 10 00 00 00       	mov    $0x10,%edx
80102e27:	89 d8                	mov    %ebx,%eax
80102e29:	e8 a1 ff ff ff       	call   80102dcf <sum>
80102e2e:	84 c0                	test   %al,%al
80102e30:	75 d2                	jne    80102e04 <mpsearch1+0x11>
80102e32:	eb 05                	jmp    80102e39 <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102e34:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102e39:	89 d8                	mov    %ebx,%eax
80102e3b:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102e3e:	5b                   	pop    %ebx
80102e3f:	5e                   	pop    %esi
80102e40:	5d                   	pop    %ebp
80102e41:	c3                   	ret    

80102e42 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102e42:	55                   	push   %ebp
80102e43:	89 e5                	mov    %esp,%ebp
80102e45:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102e48:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102e4f:	c1 e0 08             	shl    $0x8,%eax
80102e52:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102e59:	09 d0                	or     %edx,%eax
80102e5b:	c1 e0 04             	shl    $0x4,%eax
80102e5e:	85 c0                	test   %eax,%eax
80102e60:	74 1f                	je     80102e81 <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102e62:	ba 00 04 00 00       	mov    $0x400,%edx
80102e67:	e8 87 ff ff ff       	call   80102df3 <mpsearch1>
80102e6c:	85 c0                	test   %eax,%eax
80102e6e:	75 0f                	jne    80102e7f <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102e70:	ba 00 00 01 00       	mov    $0x10000,%edx
80102e75:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102e7a:	e8 74 ff ff ff       	call   80102df3 <mpsearch1>
}
80102e7f:	c9                   	leave  
80102e80:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102e81:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102e88:	c1 e0 08             	shl    $0x8,%eax
80102e8b:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102e92:	09 d0                	or     %edx,%eax
80102e94:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102e97:	2d 00 04 00 00       	sub    $0x400,%eax
80102e9c:	ba 00 04 00 00       	mov    $0x400,%edx
80102ea1:	e8 4d ff ff ff       	call   80102df3 <mpsearch1>
80102ea6:	85 c0                	test   %eax,%eax
80102ea8:	75 d5                	jne    80102e7f <mpsearch+0x3d>
80102eaa:	eb c4                	jmp    80102e70 <mpsearch+0x2e>

80102eac <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102eac:	55                   	push   %ebp
80102ead:	89 e5                	mov    %esp,%ebp
80102eaf:	57                   	push   %edi
80102eb0:	56                   	push   %esi
80102eb1:	53                   	push   %ebx
80102eb2:	83 ec 1c             	sub    $0x1c,%esp
80102eb5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102eb8:	e8 85 ff ff ff       	call   80102e42 <mpsearch>
80102ebd:	85 c0                	test   %eax,%eax
80102ebf:	74 5c                	je     80102f1d <mpconfig+0x71>
80102ec1:	89 c7                	mov    %eax,%edi
80102ec3:	8b 58 04             	mov    0x4(%eax),%ebx
80102ec6:	85 db                	test   %ebx,%ebx
80102ec8:	74 5a                	je     80102f24 <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102eca:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102ed0:	83 ec 04             	sub    $0x4,%esp
80102ed3:	6a 04                	push   $0x4
80102ed5:	68 bd 6c 10 80       	push   $0x80106cbd
80102eda:	56                   	push   %esi
80102edb:	e8 9b 10 00 00       	call   80103f7b <memcmp>
80102ee0:	83 c4 10             	add    $0x10,%esp
80102ee3:	85 c0                	test   %eax,%eax
80102ee5:	75 44                	jne    80102f2b <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102ee7:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102eee:	3c 01                	cmp    $0x1,%al
80102ef0:	0f 95 c2             	setne  %dl
80102ef3:	3c 04                	cmp    $0x4,%al
80102ef5:	0f 95 c0             	setne  %al
80102ef8:	84 c2                	test   %al,%dl
80102efa:	75 36                	jne    80102f32 <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102efc:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102f03:	89 f0                	mov    %esi,%eax
80102f05:	e8 c5 fe ff ff       	call   80102dcf <sum>
80102f0a:	84 c0                	test   %al,%al
80102f0c:	75 2b                	jne    80102f39 <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102f0e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102f11:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102f13:	89 f0                	mov    %esi,%eax
80102f15:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102f18:	5b                   	pop    %ebx
80102f19:	5e                   	pop    %esi
80102f1a:	5f                   	pop    %edi
80102f1b:	5d                   	pop    %ebp
80102f1c:	c3                   	ret    
    return 0;
80102f1d:	be 00 00 00 00       	mov    $0x0,%esi
80102f22:	eb ef                	jmp    80102f13 <mpconfig+0x67>
80102f24:	be 00 00 00 00       	mov    $0x0,%esi
80102f29:	eb e8                	jmp    80102f13 <mpconfig+0x67>
    return 0;
80102f2b:	be 00 00 00 00       	mov    $0x0,%esi
80102f30:	eb e1                	jmp    80102f13 <mpconfig+0x67>
    return 0;
80102f32:	be 00 00 00 00       	mov    $0x0,%esi
80102f37:	eb da                	jmp    80102f13 <mpconfig+0x67>
    return 0;
80102f39:	be 00 00 00 00       	mov    $0x0,%esi
80102f3e:	eb d3                	jmp    80102f13 <mpconfig+0x67>

80102f40 <mpinit>:

void
mpinit(void)
{
80102f40:	55                   	push   %ebp
80102f41:	89 e5                	mov    %esp,%ebp
80102f43:	57                   	push   %edi
80102f44:	56                   	push   %esi
80102f45:	53                   	push   %ebx
80102f46:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102f49:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102f4c:	e8 5b ff ff ff       	call   80102eac <mpconfig>
80102f51:	85 c0                	test   %eax,%eax
80102f53:	74 19                	je     80102f6e <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102f55:	8b 50 24             	mov    0x24(%eax),%edx
80102f58:	89 15 a4 26 13 80    	mov    %edx,0x801326a4
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102f5e:	8d 50 2c             	lea    0x2c(%eax),%edx
80102f61:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102f65:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102f67:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102f6c:	eb 34                	jmp    80102fa2 <mpinit+0x62>
    panic("Expect to run on an SMP");
80102f6e:	83 ec 0c             	sub    $0xc,%esp
80102f71:	68 c2 6c 10 80       	push   $0x80106cc2
80102f76:	e8 cd d3 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102f7b:	8b 35 40 2d 13 80    	mov    0x80132d40,%esi
80102f81:	83 fe 07             	cmp    $0x7,%esi
80102f84:	7f 19                	jg     80102f9f <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102f86:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102f8a:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102f90:	88 87 c0 27 13 80    	mov    %al,-0x7fecd840(%edi)
        ncpu++;
80102f96:	83 c6 01             	add    $0x1,%esi
80102f99:	89 35 40 2d 13 80    	mov    %esi,0x80132d40
      }
      p += sizeof(struct mpproc);
80102f9f:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102fa2:	39 ca                	cmp    %ecx,%edx
80102fa4:	73 2b                	jae    80102fd1 <mpinit+0x91>
    switch(*p){
80102fa6:	0f b6 02             	movzbl (%edx),%eax
80102fa9:	3c 04                	cmp    $0x4,%al
80102fab:	77 1d                	ja     80102fca <mpinit+0x8a>
80102fad:	0f b6 c0             	movzbl %al,%eax
80102fb0:	ff 24 85 fc 6c 10 80 	jmp    *-0x7fef9304(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102fb7:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102fbb:	a2 a0 27 13 80       	mov    %al,0x801327a0
      p += sizeof(struct mpioapic);
80102fc0:	83 c2 08             	add    $0x8,%edx
      continue;
80102fc3:	eb dd                	jmp    80102fa2 <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102fc5:	83 c2 08             	add    $0x8,%edx
      continue;
80102fc8:	eb d8                	jmp    80102fa2 <mpinit+0x62>
    default:
      ismp = 0;
80102fca:	bb 00 00 00 00       	mov    $0x0,%ebx
80102fcf:	eb d1                	jmp    80102fa2 <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80102fd1:	85 db                	test   %ebx,%ebx
80102fd3:	74 26                	je     80102ffb <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102fd5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102fd8:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102fdc:	74 15                	je     80102ff3 <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102fde:	b8 70 00 00 00       	mov    $0x70,%eax
80102fe3:	ba 22 00 00 00       	mov    $0x22,%edx
80102fe8:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102fe9:	ba 23 00 00 00       	mov    $0x23,%edx
80102fee:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102fef:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102ff2:	ee                   	out    %al,(%dx)
  }
}
80102ff3:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102ff6:	5b                   	pop    %ebx
80102ff7:	5e                   	pop    %esi
80102ff8:	5f                   	pop    %edi
80102ff9:	5d                   	pop    %ebp
80102ffa:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102ffb:	83 ec 0c             	sub    $0xc,%esp
80102ffe:	68 dc 6c 10 80       	push   $0x80106cdc
80103003:	e8 40 d3 ff ff       	call   80100348 <panic>

80103008 <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80103008:	55                   	push   %ebp
80103009:	89 e5                	mov    %esp,%ebp
8010300b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103010:	ba 21 00 00 00       	mov    $0x21,%edx
80103015:	ee                   	out    %al,(%dx)
80103016:	ba a1 00 00 00       	mov    $0xa1,%edx
8010301b:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
8010301c:	5d                   	pop    %ebp
8010301d:	c3                   	ret    

8010301e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
8010301e:	55                   	push   %ebp
8010301f:	89 e5                	mov    %esp,%ebp
80103021:	57                   	push   %edi
80103022:	56                   	push   %esi
80103023:	53                   	push   %ebx
80103024:	83 ec 0c             	sub    $0xc,%esp
80103027:	8b 5d 08             	mov    0x8(%ebp),%ebx
8010302a:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
8010302d:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80103033:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103039:	e8 ef db ff ff       	call   80100c2d <filealloc>
8010303e:	89 03                	mov    %eax,(%ebx)
80103040:	85 c0                	test   %eax,%eax
80103042:	74 1e                	je     80103062 <pipealloc+0x44>
80103044:	e8 e4 db ff ff       	call   80100c2d <filealloc>
80103049:	89 06                	mov    %eax,(%esi)
8010304b:	85 c0                	test   %eax,%eax
8010304d:	74 13                	je     80103062 <pipealloc+0x44>
    goto bad;
  if((p = (struct pipe*)kalloc2(-2)) == 0)
8010304f:	83 ec 0c             	sub    $0xc,%esp
80103052:	6a fe                	push   $0xfffffffe
80103054:	e8 83 f1 ff ff       	call   801021dc <kalloc2>
80103059:	89 c7                	mov    %eax,%edi
8010305b:	83 c4 10             	add    $0x10,%esp
8010305e:	85 c0                	test   %eax,%eax
80103060:	75 35                	jne    80103097 <pipealloc+0x79>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80103062:	8b 03                	mov    (%ebx),%eax
80103064:	85 c0                	test   %eax,%eax
80103066:	74 0c                	je     80103074 <pipealloc+0x56>
    fileclose(*f0);
80103068:	83 ec 0c             	sub    $0xc,%esp
8010306b:	50                   	push   %eax
8010306c:	e8 62 dc ff ff       	call   80100cd3 <fileclose>
80103071:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80103074:	8b 06                	mov    (%esi),%eax
80103076:	85 c0                	test   %eax,%eax
80103078:	0f 84 8b 00 00 00    	je     80103109 <pipealloc+0xeb>
    fileclose(*f1);
8010307e:	83 ec 0c             	sub    $0xc,%esp
80103081:	50                   	push   %eax
80103082:	e8 4c dc ff ff       	call   80100cd3 <fileclose>
80103087:	83 c4 10             	add    $0x10,%esp
  return -1;
8010308a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010308f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103092:	5b                   	pop    %ebx
80103093:	5e                   	pop    %esi
80103094:	5f                   	pop    %edi
80103095:	5d                   	pop    %ebp
80103096:	c3                   	ret    
  p->readopen = 1;
80103097:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
8010309e:	00 00 00 
  p->writeopen = 1;
801030a1:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
801030a8:	00 00 00 
  p->nwrite = 0;
801030ab:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
801030b2:	00 00 00 
  p->nread = 0;
801030b5:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
801030bc:	00 00 00 
  initlock(&p->lock, "pipe");
801030bf:	83 ec 08             	sub    $0x8,%esp
801030c2:	68 10 6d 10 80       	push   $0x80106d10
801030c7:	50                   	push   %eax
801030c8:	e8 80 0c 00 00       	call   80103d4d <initlock>
  (*f0)->type = FD_PIPE;
801030cd:	8b 03                	mov    (%ebx),%eax
801030cf:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
801030d5:	8b 03                	mov    (%ebx),%eax
801030d7:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
801030db:	8b 03                	mov    (%ebx),%eax
801030dd:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
801030e1:	8b 03                	mov    (%ebx),%eax
801030e3:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
801030e6:	8b 06                	mov    (%esi),%eax
801030e8:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
801030ee:	8b 06                	mov    (%esi),%eax
801030f0:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
801030f4:	8b 06                	mov    (%esi),%eax
801030f6:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
801030fa:	8b 06                	mov    (%esi),%eax
801030fc:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
801030ff:	83 c4 10             	add    $0x10,%esp
80103102:	b8 00 00 00 00       	mov    $0x0,%eax
80103107:	eb 86                	jmp    8010308f <pipealloc+0x71>
  return -1;
80103109:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010310e:	e9 7c ff ff ff       	jmp    8010308f <pipealloc+0x71>

80103113 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103113:	55                   	push   %ebp
80103114:	89 e5                	mov    %esp,%ebp
80103116:	53                   	push   %ebx
80103117:	83 ec 10             	sub    $0x10,%esp
8010311a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
8010311d:	53                   	push   %ebx
8010311e:	e8 66 0d 00 00       	call   80103e89 <acquire>
  if(writable){
80103123:	83 c4 10             	add    $0x10,%esp
80103126:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010312a:	74 3f                	je     8010316b <pipeclose+0x58>
    p->writeopen = 0;
8010312c:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80103133:	00 00 00 
    wakeup(&p->nread);
80103136:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
8010313c:	83 ec 0c             	sub    $0xc,%esp
8010313f:	50                   	push   %eax
80103140:	e8 ae 09 00 00       	call   80103af3 <wakeup>
80103145:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80103148:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
8010314f:	75 09                	jne    8010315a <pipeclose+0x47>
80103151:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80103158:	74 2f                	je     80103189 <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
8010315a:	83 ec 0c             	sub    $0xc,%esp
8010315d:	53                   	push   %ebx
8010315e:	e8 8b 0d 00 00       	call   80103eee <release>
80103163:	83 c4 10             	add    $0x10,%esp
}
80103166:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103169:	c9                   	leave  
8010316a:	c3                   	ret    
    p->readopen = 0;
8010316b:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
80103172:	00 00 00 
    wakeup(&p->nwrite);
80103175:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
8010317b:	83 ec 0c             	sub    $0xc,%esp
8010317e:	50                   	push   %eax
8010317f:	e8 6f 09 00 00       	call   80103af3 <wakeup>
80103184:	83 c4 10             	add    $0x10,%esp
80103187:	eb bf                	jmp    80103148 <pipeclose+0x35>
    release(&p->lock);
80103189:	83 ec 0c             	sub    $0xc,%esp
8010318c:	53                   	push   %ebx
8010318d:	e8 5c 0d 00 00       	call   80103eee <release>
    kfree((char*)p);
80103192:	89 1c 24             	mov    %ebx,(%esp)
80103195:	e8 2b ef ff ff       	call   801020c5 <kfree>
8010319a:	83 c4 10             	add    $0x10,%esp
8010319d:	eb c7                	jmp    80103166 <pipeclose+0x53>

8010319f <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
8010319f:	55                   	push   %ebp
801031a0:	89 e5                	mov    %esp,%ebp
801031a2:	57                   	push   %edi
801031a3:	56                   	push   %esi
801031a4:	53                   	push   %ebx
801031a5:	83 ec 18             	sub    $0x18,%esp
801031a8:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
801031ab:	89 de                	mov    %ebx,%esi
801031ad:	53                   	push   %ebx
801031ae:	e8 d6 0c 00 00       	call   80103e89 <acquire>
  for(i = 0; i < n; i++){
801031b3:	83 c4 10             	add    $0x10,%esp
801031b6:	bf 00 00 00 00       	mov    $0x0,%edi
801031bb:	3b 7d 10             	cmp    0x10(%ebp),%edi
801031be:	0f 8d 88 00 00 00    	jge    8010324c <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801031c4:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
801031ca:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
801031d0:	05 00 02 00 00       	add    $0x200,%eax
801031d5:	39 c2                	cmp    %eax,%edx
801031d7:	75 51                	jne    8010322a <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
801031d9:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
801031e0:	74 2f                	je     80103211 <pipewrite+0x72>
801031e2:	e8 00 03 00 00       	call   801034e7 <myproc>
801031e7:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801031eb:	75 24                	jne    80103211 <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
801031ed:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801031f3:	83 ec 0c             	sub    $0xc,%esp
801031f6:	50                   	push   %eax
801031f7:	e8 f7 08 00 00       	call   80103af3 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801031fc:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103202:	83 c4 08             	add    $0x8,%esp
80103205:	56                   	push   %esi
80103206:	50                   	push   %eax
80103207:	e8 82 07 00 00       	call   8010398e <sleep>
8010320c:	83 c4 10             	add    $0x10,%esp
8010320f:	eb b3                	jmp    801031c4 <pipewrite+0x25>
        release(&p->lock);
80103211:	83 ec 0c             	sub    $0xc,%esp
80103214:	53                   	push   %ebx
80103215:	e8 d4 0c 00 00       	call   80103eee <release>
        return -1;
8010321a:	83 c4 10             	add    $0x10,%esp
8010321d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
80103222:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103225:	5b                   	pop    %ebx
80103226:	5e                   	pop    %esi
80103227:	5f                   	pop    %edi
80103228:	5d                   	pop    %ebp
80103229:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
8010322a:	8d 42 01             	lea    0x1(%edx),%eax
8010322d:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80103233:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80103239:	8b 45 0c             	mov    0xc(%ebp),%eax
8010323c:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
80103240:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
80103244:	83 c7 01             	add    $0x1,%edi
80103247:	e9 6f ff ff ff       	jmp    801031bb <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
8010324c:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103252:	83 ec 0c             	sub    $0xc,%esp
80103255:	50                   	push   %eax
80103256:	e8 98 08 00 00       	call   80103af3 <wakeup>
  release(&p->lock);
8010325b:	89 1c 24             	mov    %ebx,(%esp)
8010325e:	e8 8b 0c 00 00       	call   80103eee <release>
  return n;
80103263:	83 c4 10             	add    $0x10,%esp
80103266:	8b 45 10             	mov    0x10(%ebp),%eax
80103269:	eb b7                	jmp    80103222 <pipewrite+0x83>

8010326b <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
8010326b:	55                   	push   %ebp
8010326c:	89 e5                	mov    %esp,%ebp
8010326e:	57                   	push   %edi
8010326f:	56                   	push   %esi
80103270:	53                   	push   %ebx
80103271:	83 ec 18             	sub    $0x18,%esp
80103274:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
80103277:	89 df                	mov    %ebx,%edi
80103279:	53                   	push   %ebx
8010327a:	e8 0a 0c 00 00       	call   80103e89 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010327f:	83 c4 10             	add    $0x10,%esp
80103282:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
80103288:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
8010328e:	75 3d                	jne    801032cd <piperead+0x62>
80103290:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
80103296:	85 f6                	test   %esi,%esi
80103298:	74 38                	je     801032d2 <piperead+0x67>
    if(myproc()->killed){
8010329a:	e8 48 02 00 00       	call   801034e7 <myproc>
8010329f:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801032a3:	75 15                	jne    801032ba <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801032a5:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801032ab:	83 ec 08             	sub    $0x8,%esp
801032ae:	57                   	push   %edi
801032af:	50                   	push   %eax
801032b0:	e8 d9 06 00 00       	call   8010398e <sleep>
801032b5:	83 c4 10             	add    $0x10,%esp
801032b8:	eb c8                	jmp    80103282 <piperead+0x17>
      release(&p->lock);
801032ba:	83 ec 0c             	sub    $0xc,%esp
801032bd:	53                   	push   %ebx
801032be:	e8 2b 0c 00 00       	call   80103eee <release>
      return -1;
801032c3:	83 c4 10             	add    $0x10,%esp
801032c6:	be ff ff ff ff       	mov    $0xffffffff,%esi
801032cb:	eb 50                	jmp    8010331d <piperead+0xb2>
801032cd:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801032d2:	3b 75 10             	cmp    0x10(%ebp),%esi
801032d5:	7d 2c                	jge    80103303 <piperead+0x98>
    if(p->nread == p->nwrite)
801032d7:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
801032dd:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
801032e3:	74 1e                	je     80103303 <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
801032e5:	8d 50 01             	lea    0x1(%eax),%edx
801032e8:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
801032ee:	25 ff 01 00 00       	and    $0x1ff,%eax
801032f3:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
801032f8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801032fb:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801032fe:	83 c6 01             	add    $0x1,%esi
80103301:	eb cf                	jmp    801032d2 <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80103303:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103309:	83 ec 0c             	sub    $0xc,%esp
8010330c:	50                   	push   %eax
8010330d:	e8 e1 07 00 00       	call   80103af3 <wakeup>
  release(&p->lock);
80103312:	89 1c 24             	mov    %ebx,(%esp)
80103315:	e8 d4 0b 00 00       	call   80103eee <release>
  return i;
8010331a:	83 c4 10             	add    $0x10,%esp
}
8010331d:	89 f0                	mov    %esi,%eax
8010331f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103322:	5b                   	pop    %ebx
80103323:	5e                   	pop    %esi
80103324:	5f                   	pop    %edi
80103325:	5d                   	pop    %ebp
80103326:	c3                   	ret    

80103327 <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80103327:	55                   	push   %ebp
80103328:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010332a:	ba 94 2d 13 80       	mov    $0x80132d94,%edx
8010332f:	eb 03                	jmp    80103334 <wakeup1+0xd>
80103331:	83 c2 7c             	add    $0x7c,%edx
80103334:	81 fa 94 4c 13 80    	cmp    $0x80134c94,%edx
8010333a:	73 14                	jae    80103350 <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
8010333c:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
80103340:	75 ef                	jne    80103331 <wakeup1+0xa>
80103342:	39 42 20             	cmp    %eax,0x20(%edx)
80103345:	75 ea                	jne    80103331 <wakeup1+0xa>
      p->state = RUNNABLE;
80103347:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
8010334e:	eb e1                	jmp    80103331 <wakeup1+0xa>
}
80103350:	5d                   	pop    %ebp
80103351:	c3                   	ret    

80103352 <allocproc>:
{
80103352:	55                   	push   %ebp
80103353:	89 e5                	mov    %esp,%ebp
80103355:	53                   	push   %ebx
80103356:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
80103359:	68 60 2d 13 80       	push   $0x80132d60
8010335e:	e8 26 0b 00 00       	call   80103e89 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103363:	83 c4 10             	add    $0x10,%esp
80103366:	bb 94 2d 13 80       	mov    $0x80132d94,%ebx
8010336b:	81 fb 94 4c 13 80    	cmp    $0x80134c94,%ebx
80103371:	73 0b                	jae    8010337e <allocproc+0x2c>
    if(p->state == UNUSED)
80103373:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
80103377:	74 1c                	je     80103395 <allocproc+0x43>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103379:	83 c3 7c             	add    $0x7c,%ebx
8010337c:	eb ed                	jmp    8010336b <allocproc+0x19>
  release(&ptable.lock);
8010337e:	83 ec 0c             	sub    $0xc,%esp
80103381:	68 60 2d 13 80       	push   $0x80132d60
80103386:	e8 63 0b 00 00       	call   80103eee <release>
  return 0;
8010338b:	83 c4 10             	add    $0x10,%esp
8010338e:	bb 00 00 00 00       	mov    $0x0,%ebx
80103393:	eb 69                	jmp    801033fe <allocproc+0xac>
  p->state = EMBRYO;
80103395:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
8010339c:	a1 04 a0 12 80       	mov    0x8012a004,%eax
801033a1:	8d 50 01             	lea    0x1(%eax),%edx
801033a4:	89 15 04 a0 12 80    	mov    %edx,0x8012a004
801033aa:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
801033ad:	83 ec 0c             	sub    $0xc,%esp
801033b0:	68 60 2d 13 80       	push   $0x80132d60
801033b5:	e8 34 0b 00 00       	call   80103eee <release>
  if((p->kstack = kalloc()) == 0){
801033ba:	e8 95 ed ff ff       	call   80102154 <kalloc>
801033bf:	89 43 08             	mov    %eax,0x8(%ebx)
801033c2:	83 c4 10             	add    $0x10,%esp
801033c5:	85 c0                	test   %eax,%eax
801033c7:	74 3c                	je     80103405 <allocproc+0xb3>
  sp -= sizeof *p->tf;
801033c9:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
801033cf:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
801033d2:	c7 80 b0 0f 00 00 4b 	movl   $0x8010504b,0xfb0(%eax)
801033d9:	50 10 80 
  sp -= sizeof *p->context;
801033dc:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
801033e1:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
801033e4:	83 ec 04             	sub    $0x4,%esp
801033e7:	6a 14                	push   $0x14
801033e9:	6a 00                	push   $0x0
801033eb:	50                   	push   %eax
801033ec:	e8 44 0b 00 00       	call   80103f35 <memset>
  p->context->eip = (uint)forkret;
801033f1:	8b 43 1c             	mov    0x1c(%ebx),%eax
801033f4:	c7 40 10 13 34 10 80 	movl   $0x80103413,0x10(%eax)
  return p;
801033fb:	83 c4 10             	add    $0x10,%esp
}
801033fe:	89 d8                	mov    %ebx,%eax
80103400:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103403:	c9                   	leave  
80103404:	c3                   	ret    
    p->state = UNUSED;
80103405:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
8010340c:	bb 00 00 00 00       	mov    $0x0,%ebx
80103411:	eb eb                	jmp    801033fe <allocproc+0xac>

80103413 <forkret>:
{
80103413:	55                   	push   %ebp
80103414:	89 e5                	mov    %esp,%ebp
80103416:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
80103419:	68 60 2d 13 80       	push   $0x80132d60
8010341e:	e8 cb 0a 00 00       	call   80103eee <release>
  if (first) {
80103423:	83 c4 10             	add    $0x10,%esp
80103426:	83 3d 00 a0 12 80 00 	cmpl   $0x0,0x8012a000
8010342d:	75 02                	jne    80103431 <forkret+0x1e>
}
8010342f:	c9                   	leave  
80103430:	c3                   	ret    
    first = 0;
80103431:	c7 05 00 a0 12 80 00 	movl   $0x0,0x8012a000
80103438:	00 00 00 
    iinit(ROOTDEV);
8010343b:	83 ec 0c             	sub    $0xc,%esp
8010343e:	6a 01                	push   $0x1
80103440:	e8 a7 de ff ff       	call   801012ec <iinit>
    initlog(ROOTDEV);
80103445:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010344c:	e8 fd f5 ff ff       	call   80102a4e <initlog>
80103451:	83 c4 10             	add    $0x10,%esp
}
80103454:	eb d9                	jmp    8010342f <forkret+0x1c>

80103456 <pinit>:
{
80103456:	55                   	push   %ebp
80103457:	89 e5                	mov    %esp,%ebp
80103459:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
8010345c:	68 15 6d 10 80       	push   $0x80106d15
80103461:	68 60 2d 13 80       	push   $0x80132d60
80103466:	e8 e2 08 00 00       	call   80103d4d <initlock>
}
8010346b:	83 c4 10             	add    $0x10,%esp
8010346e:	c9                   	leave  
8010346f:	c3                   	ret    

80103470 <mycpu>:
{
80103470:	55                   	push   %ebp
80103471:	89 e5                	mov    %esp,%ebp
80103473:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103476:	9c                   	pushf  
80103477:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103478:	f6 c4 02             	test   $0x2,%ah
8010347b:	75 28                	jne    801034a5 <mycpu+0x35>
  apicid = lapicid();
8010347d:	e8 e5 f1 ff ff       	call   80102667 <lapicid>
  for (i = 0; i < ncpu; ++i) {
80103482:	ba 00 00 00 00       	mov    $0x0,%edx
80103487:	39 15 40 2d 13 80    	cmp    %edx,0x80132d40
8010348d:	7e 23                	jle    801034b2 <mycpu+0x42>
    if (cpus[i].apicid == apicid)
8010348f:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
80103495:	0f b6 89 c0 27 13 80 	movzbl -0x7fecd840(%ecx),%ecx
8010349c:	39 c1                	cmp    %eax,%ecx
8010349e:	74 1f                	je     801034bf <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
801034a0:	83 c2 01             	add    $0x1,%edx
801034a3:	eb e2                	jmp    80103487 <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
801034a5:	83 ec 0c             	sub    $0xc,%esp
801034a8:	68 f8 6d 10 80       	push   $0x80106df8
801034ad:	e8 96 ce ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
801034b2:	83 ec 0c             	sub    $0xc,%esp
801034b5:	68 1c 6d 10 80       	push   $0x80106d1c
801034ba:	e8 89 ce ff ff       	call   80100348 <panic>
      return &cpus[i];
801034bf:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
801034c5:	05 c0 27 13 80       	add    $0x801327c0,%eax
}
801034ca:	c9                   	leave  
801034cb:	c3                   	ret    

801034cc <cpuid>:
cpuid() {
801034cc:	55                   	push   %ebp
801034cd:	89 e5                	mov    %esp,%ebp
801034cf:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
801034d2:	e8 99 ff ff ff       	call   80103470 <mycpu>
801034d7:	2d c0 27 13 80       	sub    $0x801327c0,%eax
801034dc:	c1 f8 04             	sar    $0x4,%eax
801034df:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
801034e5:	c9                   	leave  
801034e6:	c3                   	ret    

801034e7 <myproc>:
myproc(void) {
801034e7:	55                   	push   %ebp
801034e8:	89 e5                	mov    %esp,%ebp
801034ea:	53                   	push   %ebx
801034eb:	83 ec 04             	sub    $0x4,%esp
  pushcli();
801034ee:	e8 b9 08 00 00       	call   80103dac <pushcli>
  c = mycpu();
801034f3:	e8 78 ff ff ff       	call   80103470 <mycpu>
  p = c->proc;
801034f8:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
801034fe:	e8 e6 08 00 00       	call   80103de9 <popcli>
}
80103503:	89 d8                	mov    %ebx,%eax
80103505:	83 c4 04             	add    $0x4,%esp
80103508:	5b                   	pop    %ebx
80103509:	5d                   	pop    %ebp
8010350a:	c3                   	ret    

8010350b <userinit>:
{
8010350b:	55                   	push   %ebp
8010350c:	89 e5                	mov    %esp,%ebp
8010350e:	53                   	push   %ebx
8010350f:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
80103512:	e8 3b fe ff ff       	call   80103352 <allocproc>
80103517:	89 c3                	mov    %eax,%ebx
  initproc = p;
80103519:	a3 c0 a5 12 80       	mov    %eax,0x8012a5c0
  if((p->pgdir = setupkvm()) == 0)
8010351e:	e8 27 30 00 00       	call   8010654a <setupkvm>
80103523:	89 43 04             	mov    %eax,0x4(%ebx)
80103526:	85 c0                	test   %eax,%eax
80103528:	0f 84 b7 00 00 00    	je     801035e5 <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
8010352e:	83 ec 04             	sub    $0x4,%esp
80103531:	68 2c 00 00 00       	push   $0x2c
80103536:	68 60 a4 12 80       	push   $0x8012a460
8010353b:	50                   	push   %eax
8010353c:	e8 01 2d 00 00       	call   80106242 <inituvm>
  p->sz = PGSIZE;
80103541:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
80103547:	83 c4 0c             	add    $0xc,%esp
8010354a:	6a 4c                	push   $0x4c
8010354c:	6a 00                	push   $0x0
8010354e:	ff 73 18             	pushl  0x18(%ebx)
80103551:	e8 df 09 00 00       	call   80103f35 <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80103556:	8b 43 18             	mov    0x18(%ebx),%eax
80103559:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
8010355f:	8b 43 18             	mov    0x18(%ebx),%eax
80103562:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
80103568:	8b 43 18             	mov    0x18(%ebx),%eax
8010356b:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
8010356f:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80103573:	8b 43 18             	mov    0x18(%ebx),%eax
80103576:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
8010357a:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
8010357e:	8b 43 18             	mov    0x18(%ebx),%eax
80103581:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80103588:	8b 43 18             	mov    0x18(%ebx),%eax
8010358b:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80103592:	8b 43 18             	mov    0x18(%ebx),%eax
80103595:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
8010359c:	8d 43 6c             	lea    0x6c(%ebx),%eax
8010359f:	83 c4 0c             	add    $0xc,%esp
801035a2:	6a 10                	push   $0x10
801035a4:	68 45 6d 10 80       	push   $0x80106d45
801035a9:	50                   	push   %eax
801035aa:	e8 ed 0a 00 00       	call   8010409c <safestrcpy>
  p->cwd = namei("/");
801035af:	c7 04 24 4e 6d 10 80 	movl   $0x80106d4e,(%esp)
801035b6:	e8 26 e6 ff ff       	call   80101be1 <namei>
801035bb:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
801035be:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
801035c5:	e8 bf 08 00 00       	call   80103e89 <acquire>
  p->state = RUNNABLE;
801035ca:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
801035d1:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
801035d8:	e8 11 09 00 00       	call   80103eee <release>
}
801035dd:	83 c4 10             	add    $0x10,%esp
801035e0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801035e3:	c9                   	leave  
801035e4:	c3                   	ret    
    panic("userinit: out of memory?");
801035e5:	83 ec 0c             	sub    $0xc,%esp
801035e8:	68 2c 6d 10 80       	push   $0x80106d2c
801035ed:	e8 56 cd ff ff       	call   80100348 <panic>

801035f2 <growproc>:
{
801035f2:	55                   	push   %ebp
801035f3:	89 e5                	mov    %esp,%ebp
801035f5:	56                   	push   %esi
801035f6:	53                   	push   %ebx
801035f7:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
801035fa:	e8 e8 fe ff ff       	call   801034e7 <myproc>
801035ff:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
80103601:	8b 00                	mov    (%eax),%eax
  if(n > 0){
80103603:	85 f6                	test   %esi,%esi
80103605:	7f 21                	jg     80103628 <growproc+0x36>
  } else if(n < 0){
80103607:	85 f6                	test   %esi,%esi
80103609:	79 33                	jns    8010363e <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
8010360b:	83 ec 04             	sub    $0x4,%esp
8010360e:	01 c6                	add    %eax,%esi
80103610:	56                   	push   %esi
80103611:	50                   	push   %eax
80103612:	ff 73 04             	pushl  0x4(%ebx)
80103615:	e8 36 2d 00 00       	call   80106350 <deallocuvm>
8010361a:	83 c4 10             	add    $0x10,%esp
8010361d:	85 c0                	test   %eax,%eax
8010361f:	75 1d                	jne    8010363e <growproc+0x4c>
      return -1;
80103621:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103626:	eb 29                	jmp    80103651 <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103628:	83 ec 04             	sub    $0x4,%esp
8010362b:	01 c6                	add    %eax,%esi
8010362d:	56                   	push   %esi
8010362e:	50                   	push   %eax
8010362f:	ff 73 04             	pushl  0x4(%ebx)
80103632:	e8 ab 2d 00 00       	call   801063e2 <allocuvm>
80103637:	83 c4 10             	add    $0x10,%esp
8010363a:	85 c0                	test   %eax,%eax
8010363c:	74 1a                	je     80103658 <growproc+0x66>
  curproc->sz = sz;
8010363e:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
80103640:	83 ec 0c             	sub    $0xc,%esp
80103643:	53                   	push   %ebx
80103644:	e8 e1 2a 00 00       	call   8010612a <switchuvm>
  return 0;
80103649:	83 c4 10             	add    $0x10,%esp
8010364c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103651:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103654:	5b                   	pop    %ebx
80103655:	5e                   	pop    %esi
80103656:	5d                   	pop    %ebp
80103657:	c3                   	ret    
      return -1;
80103658:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010365d:	eb f2                	jmp    80103651 <growproc+0x5f>

8010365f <fork>:
{
8010365f:	55                   	push   %ebp
80103660:	89 e5                	mov    %esp,%ebp
80103662:	57                   	push   %edi
80103663:	56                   	push   %esi
80103664:	53                   	push   %ebx
80103665:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
80103668:	e8 7a fe ff ff       	call   801034e7 <myproc>
8010366d:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
8010366f:	e8 de fc ff ff       	call   80103352 <allocproc>
80103674:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80103677:	85 c0                	test   %eax,%eax
80103679:	0f 84 e3 00 00 00    	je     80103762 <fork+0x103>
8010367f:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz, np->pid)) == 0){
80103681:	83 ec 04             	sub    $0x4,%esp
80103684:	ff 70 10             	pushl  0x10(%eax)
80103687:	ff 33                	pushl  (%ebx)
80103689:	ff 73 04             	pushl  0x4(%ebx)
8010368c:	e8 72 2f 00 00       	call   80106603 <copyuvm>
80103691:	89 47 04             	mov    %eax,0x4(%edi)
80103694:	83 c4 10             	add    $0x10,%esp
80103697:	85 c0                	test   %eax,%eax
80103699:	74 2a                	je     801036c5 <fork+0x66>
  np->sz = curproc->sz;
8010369b:	8b 03                	mov    (%ebx),%eax
8010369d:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801036a0:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
801036a2:	89 c8                	mov    %ecx,%eax
801036a4:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
801036a7:	8b 73 18             	mov    0x18(%ebx),%esi
801036aa:	8b 79 18             	mov    0x18(%ecx),%edi
801036ad:	b9 13 00 00 00       	mov    $0x13,%ecx
801036b2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
801036b4:	8b 40 18             	mov    0x18(%eax),%eax
801036b7:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
801036be:	be 00 00 00 00       	mov    $0x0,%esi
801036c3:	eb 29                	jmp    801036ee <fork+0x8f>
    kfree(np->kstack);
801036c5:	83 ec 0c             	sub    $0xc,%esp
801036c8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
801036cb:	ff 73 08             	pushl  0x8(%ebx)
801036ce:	e8 f2 e9 ff ff       	call   801020c5 <kfree>
    np->kstack = 0;
801036d3:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
801036da:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
801036e1:	83 c4 10             	add    $0x10,%esp
801036e4:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801036e9:	eb 6d                	jmp    80103758 <fork+0xf9>
  for(i = 0; i < NOFILE; i++)
801036eb:	83 c6 01             	add    $0x1,%esi
801036ee:	83 fe 0f             	cmp    $0xf,%esi
801036f1:	7f 1d                	jg     80103710 <fork+0xb1>
    if(curproc->ofile[i])
801036f3:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
801036f7:	85 c0                	test   %eax,%eax
801036f9:	74 f0                	je     801036eb <fork+0x8c>
      np->ofile[i] = filedup(curproc->ofile[i]);
801036fb:	83 ec 0c             	sub    $0xc,%esp
801036fe:	50                   	push   %eax
801036ff:	e8 8a d5 ff ff       	call   80100c8e <filedup>
80103704:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103707:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
8010370b:	83 c4 10             	add    $0x10,%esp
8010370e:	eb db                	jmp    801036eb <fork+0x8c>
  np->cwd = idup(curproc->cwd);
80103710:	83 ec 0c             	sub    $0xc,%esp
80103713:	ff 73 68             	pushl  0x68(%ebx)
80103716:	e8 36 de ff ff       	call   80101551 <idup>
8010371b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010371e:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103721:	83 c3 6c             	add    $0x6c,%ebx
80103724:	8d 47 6c             	lea    0x6c(%edi),%eax
80103727:	83 c4 0c             	add    $0xc,%esp
8010372a:	6a 10                	push   $0x10
8010372c:	53                   	push   %ebx
8010372d:	50                   	push   %eax
8010372e:	e8 69 09 00 00       	call   8010409c <safestrcpy>
  pid = np->pid;
80103733:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
80103736:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
8010373d:	e8 47 07 00 00       	call   80103e89 <acquire>
  np->state = RUNNABLE;
80103742:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
80103749:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
80103750:	e8 99 07 00 00       	call   80103eee <release>
  return pid;
80103755:	83 c4 10             	add    $0x10,%esp
}
80103758:	89 d8                	mov    %ebx,%eax
8010375a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010375d:	5b                   	pop    %ebx
8010375e:	5e                   	pop    %esi
8010375f:	5f                   	pop    %edi
80103760:	5d                   	pop    %ebp
80103761:	c3                   	ret    
    return -1;
80103762:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103767:	eb ef                	jmp    80103758 <fork+0xf9>

80103769 <scheduler>:
{
80103769:	55                   	push   %ebp
8010376a:	89 e5                	mov    %esp,%ebp
8010376c:	56                   	push   %esi
8010376d:	53                   	push   %ebx
  struct cpu *c = mycpu();
8010376e:	e8 fd fc ff ff       	call   80103470 <mycpu>
80103773:	89 c6                	mov    %eax,%esi
  c->proc = 0;
80103775:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
8010377c:	00 00 00 
8010377f:	eb 5a                	jmp    801037db <scheduler+0x72>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103781:	83 c3 7c             	add    $0x7c,%ebx
80103784:	81 fb 94 4c 13 80    	cmp    $0x80134c94,%ebx
8010378a:	73 3f                	jae    801037cb <scheduler+0x62>
      if(p->state != RUNNABLE)
8010378c:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
80103790:	75 ef                	jne    80103781 <scheduler+0x18>
      c->proc = p;
80103792:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
80103798:	83 ec 0c             	sub    $0xc,%esp
8010379b:	53                   	push   %ebx
8010379c:	e8 89 29 00 00       	call   8010612a <switchuvm>
      p->state = RUNNING;
801037a1:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
801037a8:	83 c4 08             	add    $0x8,%esp
801037ab:	ff 73 1c             	pushl  0x1c(%ebx)
801037ae:	8d 46 04             	lea    0x4(%esi),%eax
801037b1:	50                   	push   %eax
801037b2:	e8 38 09 00 00       	call   801040ef <swtch>
      switchkvm();
801037b7:	e8 5c 29 00 00       	call   80106118 <switchkvm>
      c->proc = 0;
801037bc:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
801037c3:	00 00 00 
801037c6:	83 c4 10             	add    $0x10,%esp
801037c9:	eb b6                	jmp    80103781 <scheduler+0x18>
    release(&ptable.lock);
801037cb:	83 ec 0c             	sub    $0xc,%esp
801037ce:	68 60 2d 13 80       	push   $0x80132d60
801037d3:	e8 16 07 00 00       	call   80103eee <release>
    sti();
801037d8:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
801037db:	fb                   	sti    
    acquire(&ptable.lock);
801037dc:	83 ec 0c             	sub    $0xc,%esp
801037df:	68 60 2d 13 80       	push   $0x80132d60
801037e4:	e8 a0 06 00 00       	call   80103e89 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801037e9:	83 c4 10             	add    $0x10,%esp
801037ec:	bb 94 2d 13 80       	mov    $0x80132d94,%ebx
801037f1:	eb 91                	jmp    80103784 <scheduler+0x1b>

801037f3 <sched>:
{
801037f3:	55                   	push   %ebp
801037f4:	89 e5                	mov    %esp,%ebp
801037f6:	56                   	push   %esi
801037f7:	53                   	push   %ebx
  struct proc *p = myproc();
801037f8:	e8 ea fc ff ff       	call   801034e7 <myproc>
801037fd:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
801037ff:	83 ec 0c             	sub    $0xc,%esp
80103802:	68 60 2d 13 80       	push   $0x80132d60
80103807:	e8 3d 06 00 00       	call   80103e49 <holding>
8010380c:	83 c4 10             	add    $0x10,%esp
8010380f:	85 c0                	test   %eax,%eax
80103811:	74 4f                	je     80103862 <sched+0x6f>
  if(mycpu()->ncli != 1)
80103813:	e8 58 fc ff ff       	call   80103470 <mycpu>
80103818:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
8010381f:	75 4e                	jne    8010386f <sched+0x7c>
  if(p->state == RUNNING)
80103821:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
80103825:	74 55                	je     8010387c <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103827:	9c                   	pushf  
80103828:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103829:	f6 c4 02             	test   $0x2,%ah
8010382c:	75 5b                	jne    80103889 <sched+0x96>
  intena = mycpu()->intena;
8010382e:	e8 3d fc ff ff       	call   80103470 <mycpu>
80103833:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
80103839:	e8 32 fc ff ff       	call   80103470 <mycpu>
8010383e:	83 ec 08             	sub    $0x8,%esp
80103841:	ff 70 04             	pushl  0x4(%eax)
80103844:	83 c3 1c             	add    $0x1c,%ebx
80103847:	53                   	push   %ebx
80103848:	e8 a2 08 00 00       	call   801040ef <swtch>
  mycpu()->intena = intena;
8010384d:	e8 1e fc ff ff       	call   80103470 <mycpu>
80103852:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
80103858:	83 c4 10             	add    $0x10,%esp
8010385b:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010385e:	5b                   	pop    %ebx
8010385f:	5e                   	pop    %esi
80103860:	5d                   	pop    %ebp
80103861:	c3                   	ret    
    panic("sched ptable.lock");
80103862:	83 ec 0c             	sub    $0xc,%esp
80103865:	68 50 6d 10 80       	push   $0x80106d50
8010386a:	e8 d9 ca ff ff       	call   80100348 <panic>
    panic("sched locks");
8010386f:	83 ec 0c             	sub    $0xc,%esp
80103872:	68 62 6d 10 80       	push   $0x80106d62
80103877:	e8 cc ca ff ff       	call   80100348 <panic>
    panic("sched running");
8010387c:	83 ec 0c             	sub    $0xc,%esp
8010387f:	68 6e 6d 10 80       	push   $0x80106d6e
80103884:	e8 bf ca ff ff       	call   80100348 <panic>
    panic("sched interruptible");
80103889:	83 ec 0c             	sub    $0xc,%esp
8010388c:	68 7c 6d 10 80       	push   $0x80106d7c
80103891:	e8 b2 ca ff ff       	call   80100348 <panic>

80103896 <exit>:
{
80103896:	55                   	push   %ebp
80103897:	89 e5                	mov    %esp,%ebp
80103899:	56                   	push   %esi
8010389a:	53                   	push   %ebx
  struct proc *curproc = myproc();
8010389b:	e8 47 fc ff ff       	call   801034e7 <myproc>
  if(curproc == initproc)
801038a0:	39 05 c0 a5 12 80    	cmp    %eax,0x8012a5c0
801038a6:	74 09                	je     801038b1 <exit+0x1b>
801038a8:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
801038aa:	bb 00 00 00 00       	mov    $0x0,%ebx
801038af:	eb 10                	jmp    801038c1 <exit+0x2b>
    panic("init exiting");
801038b1:	83 ec 0c             	sub    $0xc,%esp
801038b4:	68 90 6d 10 80       	push   $0x80106d90
801038b9:	e8 8a ca ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
801038be:	83 c3 01             	add    $0x1,%ebx
801038c1:	83 fb 0f             	cmp    $0xf,%ebx
801038c4:	7f 1e                	jg     801038e4 <exit+0x4e>
    if(curproc->ofile[fd]){
801038c6:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
801038ca:	85 c0                	test   %eax,%eax
801038cc:	74 f0                	je     801038be <exit+0x28>
      fileclose(curproc->ofile[fd]);
801038ce:	83 ec 0c             	sub    $0xc,%esp
801038d1:	50                   	push   %eax
801038d2:	e8 fc d3 ff ff       	call   80100cd3 <fileclose>
      curproc->ofile[fd] = 0;
801038d7:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
801038de:	00 
801038df:	83 c4 10             	add    $0x10,%esp
801038e2:	eb da                	jmp    801038be <exit+0x28>
  begin_op();
801038e4:	e8 ae f1 ff ff       	call   80102a97 <begin_op>
  iput(curproc->cwd);
801038e9:	83 ec 0c             	sub    $0xc,%esp
801038ec:	ff 76 68             	pushl  0x68(%esi)
801038ef:	e8 94 dd ff ff       	call   80101688 <iput>
  end_op();
801038f4:	e8 18 f2 ff ff       	call   80102b11 <end_op>
  curproc->cwd = 0;
801038f9:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
80103900:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
80103907:	e8 7d 05 00 00       	call   80103e89 <acquire>
  wakeup1(curproc->parent);
8010390c:	8b 46 14             	mov    0x14(%esi),%eax
8010390f:	e8 13 fa ff ff       	call   80103327 <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103914:	83 c4 10             	add    $0x10,%esp
80103917:	bb 94 2d 13 80       	mov    $0x80132d94,%ebx
8010391c:	eb 03                	jmp    80103921 <exit+0x8b>
8010391e:	83 c3 7c             	add    $0x7c,%ebx
80103921:	81 fb 94 4c 13 80    	cmp    $0x80134c94,%ebx
80103927:	73 1a                	jae    80103943 <exit+0xad>
    if(p->parent == curproc){
80103929:	39 73 14             	cmp    %esi,0x14(%ebx)
8010392c:	75 f0                	jne    8010391e <exit+0x88>
      p->parent = initproc;
8010392e:	a1 c0 a5 12 80       	mov    0x8012a5c0,%eax
80103933:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
80103936:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
8010393a:	75 e2                	jne    8010391e <exit+0x88>
        wakeup1(initproc);
8010393c:	e8 e6 f9 ff ff       	call   80103327 <wakeup1>
80103941:	eb db                	jmp    8010391e <exit+0x88>
  curproc->state = ZOMBIE;
80103943:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
8010394a:	e8 a4 fe ff ff       	call   801037f3 <sched>
  panic("zombie exit");
8010394f:	83 ec 0c             	sub    $0xc,%esp
80103952:	68 9d 6d 10 80       	push   $0x80106d9d
80103957:	e8 ec c9 ff ff       	call   80100348 <panic>

8010395c <yield>:
{
8010395c:	55                   	push   %ebp
8010395d:	89 e5                	mov    %esp,%ebp
8010395f:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80103962:	68 60 2d 13 80       	push   $0x80132d60
80103967:	e8 1d 05 00 00       	call   80103e89 <acquire>
  myproc()->state = RUNNABLE;
8010396c:	e8 76 fb ff ff       	call   801034e7 <myproc>
80103971:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80103978:	e8 76 fe ff ff       	call   801037f3 <sched>
  release(&ptable.lock);
8010397d:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
80103984:	e8 65 05 00 00       	call   80103eee <release>
}
80103989:	83 c4 10             	add    $0x10,%esp
8010398c:	c9                   	leave  
8010398d:	c3                   	ret    

8010398e <sleep>:
{
8010398e:	55                   	push   %ebp
8010398f:	89 e5                	mov    %esp,%ebp
80103991:	56                   	push   %esi
80103992:	53                   	push   %ebx
80103993:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
80103996:	e8 4c fb ff ff       	call   801034e7 <myproc>
  if(p == 0)
8010399b:	85 c0                	test   %eax,%eax
8010399d:	74 66                	je     80103a05 <sleep+0x77>
8010399f:	89 c6                	mov    %eax,%esi
  if(lk == 0)
801039a1:	85 db                	test   %ebx,%ebx
801039a3:	74 6d                	je     80103a12 <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
801039a5:	81 fb 60 2d 13 80    	cmp    $0x80132d60,%ebx
801039ab:	74 18                	je     801039c5 <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
801039ad:	83 ec 0c             	sub    $0xc,%esp
801039b0:	68 60 2d 13 80       	push   $0x80132d60
801039b5:	e8 cf 04 00 00       	call   80103e89 <acquire>
    release(lk);
801039ba:	89 1c 24             	mov    %ebx,(%esp)
801039bd:	e8 2c 05 00 00       	call   80103eee <release>
801039c2:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
801039c5:	8b 45 08             	mov    0x8(%ebp),%eax
801039c8:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
801039cb:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
801039d2:	e8 1c fe ff ff       	call   801037f3 <sched>
  p->chan = 0;
801039d7:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
801039de:	81 fb 60 2d 13 80    	cmp    $0x80132d60,%ebx
801039e4:	74 18                	je     801039fe <sleep+0x70>
    release(&ptable.lock);
801039e6:	83 ec 0c             	sub    $0xc,%esp
801039e9:	68 60 2d 13 80       	push   $0x80132d60
801039ee:	e8 fb 04 00 00       	call   80103eee <release>
    acquire(lk);
801039f3:	89 1c 24             	mov    %ebx,(%esp)
801039f6:	e8 8e 04 00 00       	call   80103e89 <acquire>
801039fb:	83 c4 10             	add    $0x10,%esp
}
801039fe:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a01:	5b                   	pop    %ebx
80103a02:	5e                   	pop    %esi
80103a03:	5d                   	pop    %ebp
80103a04:	c3                   	ret    
    panic("sleep");
80103a05:	83 ec 0c             	sub    $0xc,%esp
80103a08:	68 a9 6d 10 80       	push   $0x80106da9
80103a0d:	e8 36 c9 ff ff       	call   80100348 <panic>
    panic("sleep without lk");
80103a12:	83 ec 0c             	sub    $0xc,%esp
80103a15:	68 af 6d 10 80       	push   $0x80106daf
80103a1a:	e8 29 c9 ff ff       	call   80100348 <panic>

80103a1f <wait>:
{
80103a1f:	55                   	push   %ebp
80103a20:	89 e5                	mov    %esp,%ebp
80103a22:	56                   	push   %esi
80103a23:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103a24:	e8 be fa ff ff       	call   801034e7 <myproc>
80103a29:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
80103a2b:	83 ec 0c             	sub    $0xc,%esp
80103a2e:	68 60 2d 13 80       	push   $0x80132d60
80103a33:	e8 51 04 00 00       	call   80103e89 <acquire>
80103a38:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
80103a3b:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103a40:	bb 94 2d 13 80       	mov    $0x80132d94,%ebx
80103a45:	eb 5b                	jmp    80103aa2 <wait+0x83>
        pid = p->pid;
80103a47:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
80103a4a:	83 ec 0c             	sub    $0xc,%esp
80103a4d:	ff 73 08             	pushl  0x8(%ebx)
80103a50:	e8 70 e6 ff ff       	call   801020c5 <kfree>
        p->kstack = 0;
80103a55:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
80103a5c:	83 c4 04             	add    $0x4,%esp
80103a5f:	ff 73 04             	pushl  0x4(%ebx)
80103a62:	e8 73 2a 00 00       	call   801064da <freevm>
        p->pid = 0;
80103a67:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
80103a6e:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
80103a75:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
80103a79:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
80103a80:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
80103a87:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
80103a8e:	e8 5b 04 00 00       	call   80103eee <release>
        return pid;
80103a93:	83 c4 10             	add    $0x10,%esp
}
80103a96:	89 f0                	mov    %esi,%eax
80103a98:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a9b:	5b                   	pop    %ebx
80103a9c:	5e                   	pop    %esi
80103a9d:	5d                   	pop    %ebp
80103a9e:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103a9f:	83 c3 7c             	add    $0x7c,%ebx
80103aa2:	81 fb 94 4c 13 80    	cmp    $0x80134c94,%ebx
80103aa8:	73 12                	jae    80103abc <wait+0x9d>
      if(p->parent != curproc)
80103aaa:	39 73 14             	cmp    %esi,0x14(%ebx)
80103aad:	75 f0                	jne    80103a9f <wait+0x80>
      if(p->state == ZOMBIE){
80103aaf:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103ab3:	74 92                	je     80103a47 <wait+0x28>
      havekids = 1;
80103ab5:	b8 01 00 00 00       	mov    $0x1,%eax
80103aba:	eb e3                	jmp    80103a9f <wait+0x80>
    if(!havekids || curproc->killed){
80103abc:	85 c0                	test   %eax,%eax
80103abe:	74 06                	je     80103ac6 <wait+0xa7>
80103ac0:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
80103ac4:	74 17                	je     80103add <wait+0xbe>
      release(&ptable.lock);
80103ac6:	83 ec 0c             	sub    $0xc,%esp
80103ac9:	68 60 2d 13 80       	push   $0x80132d60
80103ace:	e8 1b 04 00 00       	call   80103eee <release>
      return -1;
80103ad3:	83 c4 10             	add    $0x10,%esp
80103ad6:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103adb:	eb b9                	jmp    80103a96 <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80103add:	83 ec 08             	sub    $0x8,%esp
80103ae0:	68 60 2d 13 80       	push   $0x80132d60
80103ae5:	56                   	push   %esi
80103ae6:	e8 a3 fe ff ff       	call   8010398e <sleep>
    havekids = 0;
80103aeb:	83 c4 10             	add    $0x10,%esp
80103aee:	e9 48 ff ff ff       	jmp    80103a3b <wait+0x1c>

80103af3 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80103af3:	55                   	push   %ebp
80103af4:	89 e5                	mov    %esp,%ebp
80103af6:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
80103af9:	68 60 2d 13 80       	push   $0x80132d60
80103afe:	e8 86 03 00 00       	call   80103e89 <acquire>
  wakeup1(chan);
80103b03:	8b 45 08             	mov    0x8(%ebp),%eax
80103b06:	e8 1c f8 ff ff       	call   80103327 <wakeup1>
  release(&ptable.lock);
80103b0b:	c7 04 24 60 2d 13 80 	movl   $0x80132d60,(%esp)
80103b12:	e8 d7 03 00 00       	call   80103eee <release>
}
80103b17:	83 c4 10             	add    $0x10,%esp
80103b1a:	c9                   	leave  
80103b1b:	c3                   	ret    

80103b1c <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80103b1c:	55                   	push   %ebp
80103b1d:	89 e5                	mov    %esp,%ebp
80103b1f:	53                   	push   %ebx
80103b20:	83 ec 10             	sub    $0x10,%esp
80103b23:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
80103b26:	68 60 2d 13 80       	push   $0x80132d60
80103b2b:	e8 59 03 00 00       	call   80103e89 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103b30:	83 c4 10             	add    $0x10,%esp
80103b33:	b8 94 2d 13 80       	mov    $0x80132d94,%eax
80103b38:	3d 94 4c 13 80       	cmp    $0x80134c94,%eax
80103b3d:	73 3a                	jae    80103b79 <kill+0x5d>
    if(p->pid == pid){
80103b3f:	39 58 10             	cmp    %ebx,0x10(%eax)
80103b42:	74 05                	je     80103b49 <kill+0x2d>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103b44:	83 c0 7c             	add    $0x7c,%eax
80103b47:	eb ef                	jmp    80103b38 <kill+0x1c>
      p->killed = 1;
80103b49:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80103b50:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
80103b54:	74 1a                	je     80103b70 <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
80103b56:	83 ec 0c             	sub    $0xc,%esp
80103b59:	68 60 2d 13 80       	push   $0x80132d60
80103b5e:	e8 8b 03 00 00       	call   80103eee <release>
      return 0;
80103b63:	83 c4 10             	add    $0x10,%esp
80103b66:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
80103b6b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103b6e:	c9                   	leave  
80103b6f:	c3                   	ret    
        p->state = RUNNABLE;
80103b70:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80103b77:	eb dd                	jmp    80103b56 <kill+0x3a>
  release(&ptable.lock);
80103b79:	83 ec 0c             	sub    $0xc,%esp
80103b7c:	68 60 2d 13 80       	push   $0x80132d60
80103b81:	e8 68 03 00 00       	call   80103eee <release>
  return -1;
80103b86:	83 c4 10             	add    $0x10,%esp
80103b89:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103b8e:	eb db                	jmp    80103b6b <kill+0x4f>

80103b90 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80103b90:	55                   	push   %ebp
80103b91:	89 e5                	mov    %esp,%ebp
80103b93:	56                   	push   %esi
80103b94:	53                   	push   %ebx
80103b95:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103b98:	bb 94 2d 13 80       	mov    $0x80132d94,%ebx
80103b9d:	eb 33                	jmp    80103bd2 <procdump+0x42>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103b9f:	b8 c0 6d 10 80       	mov    $0x80106dc0,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
80103ba4:	8d 53 6c             	lea    0x6c(%ebx),%edx
80103ba7:	52                   	push   %edx
80103ba8:	50                   	push   %eax
80103ba9:	ff 73 10             	pushl  0x10(%ebx)
80103bac:	68 c4 6d 10 80       	push   $0x80106dc4
80103bb1:	e8 55 ca ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
80103bb6:	83 c4 10             	add    $0x10,%esp
80103bb9:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103bbd:	74 39                	je     80103bf8 <procdump+0x68>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103bbf:	83 ec 0c             	sub    $0xc,%esp
80103bc2:	68 3b 71 10 80       	push   $0x8010713b
80103bc7:	e8 3f ca ff ff       	call   8010060b <cprintf>
80103bcc:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103bcf:	83 c3 7c             	add    $0x7c,%ebx
80103bd2:	81 fb 94 4c 13 80    	cmp    $0x80134c94,%ebx
80103bd8:	73 61                	jae    80103c3b <procdump+0xab>
    if(p->state == UNUSED)
80103bda:	8b 43 0c             	mov    0xc(%ebx),%eax
80103bdd:	85 c0                	test   %eax,%eax
80103bdf:	74 ee                	je     80103bcf <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103be1:	83 f8 05             	cmp    $0x5,%eax
80103be4:	77 b9                	ja     80103b9f <procdump+0xf>
80103be6:	8b 04 85 20 6e 10 80 	mov    -0x7fef91e0(,%eax,4),%eax
80103bed:	85 c0                	test   %eax,%eax
80103bef:	75 b3                	jne    80103ba4 <procdump+0x14>
      state = "???";
80103bf1:	b8 c0 6d 10 80       	mov    $0x80106dc0,%eax
80103bf6:	eb ac                	jmp    80103ba4 <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80103bf8:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103bfb:	8b 40 0c             	mov    0xc(%eax),%eax
80103bfe:	83 c0 08             	add    $0x8,%eax
80103c01:	83 ec 08             	sub    $0x8,%esp
80103c04:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103c07:	52                   	push   %edx
80103c08:	50                   	push   %eax
80103c09:	e8 5a 01 00 00       	call   80103d68 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103c0e:	83 c4 10             	add    $0x10,%esp
80103c11:	be 00 00 00 00       	mov    $0x0,%esi
80103c16:	eb 14                	jmp    80103c2c <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103c18:	83 ec 08             	sub    $0x8,%esp
80103c1b:	50                   	push   %eax
80103c1c:	68 01 68 10 80       	push   $0x80106801
80103c21:	e8 e5 c9 ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103c26:	83 c6 01             	add    $0x1,%esi
80103c29:	83 c4 10             	add    $0x10,%esp
80103c2c:	83 fe 09             	cmp    $0x9,%esi
80103c2f:	7f 8e                	jg     80103bbf <procdump+0x2f>
80103c31:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103c35:	85 c0                	test   %eax,%eax
80103c37:	75 df                	jne    80103c18 <procdump+0x88>
80103c39:	eb 84                	jmp    80103bbf <procdump+0x2f>
  }
80103c3b:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103c3e:	5b                   	pop    %ebx
80103c3f:	5e                   	pop    %esi
80103c40:	5d                   	pop    %ebp
80103c41:	c3                   	ret    

80103c42 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103c42:	55                   	push   %ebp
80103c43:	89 e5                	mov    %esp,%ebp
80103c45:	53                   	push   %ebx
80103c46:	83 ec 0c             	sub    $0xc,%esp
80103c49:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103c4c:	68 38 6e 10 80       	push   $0x80106e38
80103c51:	8d 43 04             	lea    0x4(%ebx),%eax
80103c54:	50                   	push   %eax
80103c55:	e8 f3 00 00 00       	call   80103d4d <initlock>
  lk->name = name;
80103c5a:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c5d:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103c60:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103c66:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103c6d:	83 c4 10             	add    $0x10,%esp
80103c70:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103c73:	c9                   	leave  
80103c74:	c3                   	ret    

80103c75 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103c75:	55                   	push   %ebp
80103c76:	89 e5                	mov    %esp,%ebp
80103c78:	56                   	push   %esi
80103c79:	53                   	push   %ebx
80103c7a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103c7d:	8d 73 04             	lea    0x4(%ebx),%esi
80103c80:	83 ec 0c             	sub    $0xc,%esp
80103c83:	56                   	push   %esi
80103c84:	e8 00 02 00 00       	call   80103e89 <acquire>
  while (lk->locked) {
80103c89:	83 c4 10             	add    $0x10,%esp
80103c8c:	eb 0d                	jmp    80103c9b <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103c8e:	83 ec 08             	sub    $0x8,%esp
80103c91:	56                   	push   %esi
80103c92:	53                   	push   %ebx
80103c93:	e8 f6 fc ff ff       	call   8010398e <sleep>
80103c98:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103c9b:	83 3b 00             	cmpl   $0x0,(%ebx)
80103c9e:	75 ee                	jne    80103c8e <acquiresleep+0x19>
  }
  lk->locked = 1;
80103ca0:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103ca6:	e8 3c f8 ff ff       	call   801034e7 <myproc>
80103cab:	8b 40 10             	mov    0x10(%eax),%eax
80103cae:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103cb1:	83 ec 0c             	sub    $0xc,%esp
80103cb4:	56                   	push   %esi
80103cb5:	e8 34 02 00 00       	call   80103eee <release>
}
80103cba:	83 c4 10             	add    $0x10,%esp
80103cbd:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103cc0:	5b                   	pop    %ebx
80103cc1:	5e                   	pop    %esi
80103cc2:	5d                   	pop    %ebp
80103cc3:	c3                   	ret    

80103cc4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103cc4:	55                   	push   %ebp
80103cc5:	89 e5                	mov    %esp,%ebp
80103cc7:	56                   	push   %esi
80103cc8:	53                   	push   %ebx
80103cc9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103ccc:	8d 73 04             	lea    0x4(%ebx),%esi
80103ccf:	83 ec 0c             	sub    $0xc,%esp
80103cd2:	56                   	push   %esi
80103cd3:	e8 b1 01 00 00       	call   80103e89 <acquire>
  lk->locked = 0;
80103cd8:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103cde:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103ce5:	89 1c 24             	mov    %ebx,(%esp)
80103ce8:	e8 06 fe ff ff       	call   80103af3 <wakeup>
  release(&lk->lk);
80103ced:	89 34 24             	mov    %esi,(%esp)
80103cf0:	e8 f9 01 00 00       	call   80103eee <release>
}
80103cf5:	83 c4 10             	add    $0x10,%esp
80103cf8:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103cfb:	5b                   	pop    %ebx
80103cfc:	5e                   	pop    %esi
80103cfd:	5d                   	pop    %ebp
80103cfe:	c3                   	ret    

80103cff <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103cff:	55                   	push   %ebp
80103d00:	89 e5                	mov    %esp,%ebp
80103d02:	56                   	push   %esi
80103d03:	53                   	push   %ebx
80103d04:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103d07:	8d 73 04             	lea    0x4(%ebx),%esi
80103d0a:	83 ec 0c             	sub    $0xc,%esp
80103d0d:	56                   	push   %esi
80103d0e:	e8 76 01 00 00       	call   80103e89 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103d13:	83 c4 10             	add    $0x10,%esp
80103d16:	83 3b 00             	cmpl   $0x0,(%ebx)
80103d19:	75 17                	jne    80103d32 <holdingsleep+0x33>
80103d1b:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103d20:	83 ec 0c             	sub    $0xc,%esp
80103d23:	56                   	push   %esi
80103d24:	e8 c5 01 00 00       	call   80103eee <release>
  return r;
}
80103d29:	89 d8                	mov    %ebx,%eax
80103d2b:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103d2e:	5b                   	pop    %ebx
80103d2f:	5e                   	pop    %esi
80103d30:	5d                   	pop    %ebp
80103d31:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103d32:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103d35:	e8 ad f7 ff ff       	call   801034e7 <myproc>
80103d3a:	3b 58 10             	cmp    0x10(%eax),%ebx
80103d3d:	74 07                	je     80103d46 <holdingsleep+0x47>
80103d3f:	bb 00 00 00 00       	mov    $0x0,%ebx
80103d44:	eb da                	jmp    80103d20 <holdingsleep+0x21>
80103d46:	bb 01 00 00 00       	mov    $0x1,%ebx
80103d4b:	eb d3                	jmp    80103d20 <holdingsleep+0x21>

80103d4d <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103d4d:	55                   	push   %ebp
80103d4e:	89 e5                	mov    %esp,%ebp
80103d50:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103d53:	8b 55 0c             	mov    0xc(%ebp),%edx
80103d56:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103d59:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103d5f:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103d66:	5d                   	pop    %ebp
80103d67:	c3                   	ret    

80103d68 <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103d68:	55                   	push   %ebp
80103d69:	89 e5                	mov    %esp,%ebp
80103d6b:	53                   	push   %ebx
80103d6c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103d6f:	8b 45 08             	mov    0x8(%ebp),%eax
80103d72:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103d75:	b8 00 00 00 00       	mov    $0x0,%eax
80103d7a:	83 f8 09             	cmp    $0x9,%eax
80103d7d:	7f 25                	jg     80103da4 <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103d7f:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103d85:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103d8b:	77 17                	ja     80103da4 <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103d8d:	8b 5a 04             	mov    0x4(%edx),%ebx
80103d90:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103d93:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103d95:	83 c0 01             	add    $0x1,%eax
80103d98:	eb e0                	jmp    80103d7a <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103d9a:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103da1:	83 c0 01             	add    $0x1,%eax
80103da4:	83 f8 09             	cmp    $0x9,%eax
80103da7:	7e f1                	jle    80103d9a <getcallerpcs+0x32>
}
80103da9:	5b                   	pop    %ebx
80103daa:	5d                   	pop    %ebp
80103dab:	c3                   	ret    

80103dac <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103dac:	55                   	push   %ebp
80103dad:	89 e5                	mov    %esp,%ebp
80103daf:	53                   	push   %ebx
80103db0:	83 ec 04             	sub    $0x4,%esp
80103db3:	9c                   	pushf  
80103db4:	5b                   	pop    %ebx
  asm volatile("cli");
80103db5:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103db6:	e8 b5 f6 ff ff       	call   80103470 <mycpu>
80103dbb:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103dc2:	74 12                	je     80103dd6 <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103dc4:	e8 a7 f6 ff ff       	call   80103470 <mycpu>
80103dc9:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103dd0:	83 c4 04             	add    $0x4,%esp
80103dd3:	5b                   	pop    %ebx
80103dd4:	5d                   	pop    %ebp
80103dd5:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103dd6:	e8 95 f6 ff ff       	call   80103470 <mycpu>
80103ddb:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103de1:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103de7:	eb db                	jmp    80103dc4 <pushcli+0x18>

80103de9 <popcli>:

void
popcli(void)
{
80103de9:	55                   	push   %ebp
80103dea:	89 e5                	mov    %esp,%ebp
80103dec:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103def:	9c                   	pushf  
80103df0:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103df1:	f6 c4 02             	test   $0x2,%ah
80103df4:	75 28                	jne    80103e1e <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103df6:	e8 75 f6 ff ff       	call   80103470 <mycpu>
80103dfb:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103e01:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103e04:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103e0a:	85 d2                	test   %edx,%edx
80103e0c:	78 1d                	js     80103e2b <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103e0e:	e8 5d f6 ff ff       	call   80103470 <mycpu>
80103e13:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103e1a:	74 1c                	je     80103e38 <popcli+0x4f>
    sti();
}
80103e1c:	c9                   	leave  
80103e1d:	c3                   	ret    
    panic("popcli - interruptible");
80103e1e:	83 ec 0c             	sub    $0xc,%esp
80103e21:	68 43 6e 10 80       	push   $0x80106e43
80103e26:	e8 1d c5 ff ff       	call   80100348 <panic>
    panic("popcli");
80103e2b:	83 ec 0c             	sub    $0xc,%esp
80103e2e:	68 5a 6e 10 80       	push   $0x80106e5a
80103e33:	e8 10 c5 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103e38:	e8 33 f6 ff ff       	call   80103470 <mycpu>
80103e3d:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103e44:	74 d6                	je     80103e1c <popcli+0x33>
  asm volatile("sti");
80103e46:	fb                   	sti    
}
80103e47:	eb d3                	jmp    80103e1c <popcli+0x33>

80103e49 <holding>:
{
80103e49:	55                   	push   %ebp
80103e4a:	89 e5                	mov    %esp,%ebp
80103e4c:	53                   	push   %ebx
80103e4d:	83 ec 04             	sub    $0x4,%esp
80103e50:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103e53:	e8 54 ff ff ff       	call   80103dac <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103e58:	83 3b 00             	cmpl   $0x0,(%ebx)
80103e5b:	75 12                	jne    80103e6f <holding+0x26>
80103e5d:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103e62:	e8 82 ff ff ff       	call   80103de9 <popcli>
}
80103e67:	89 d8                	mov    %ebx,%eax
80103e69:	83 c4 04             	add    $0x4,%esp
80103e6c:	5b                   	pop    %ebx
80103e6d:	5d                   	pop    %ebp
80103e6e:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103e6f:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103e72:	e8 f9 f5 ff ff       	call   80103470 <mycpu>
80103e77:	39 c3                	cmp    %eax,%ebx
80103e79:	74 07                	je     80103e82 <holding+0x39>
80103e7b:	bb 00 00 00 00       	mov    $0x0,%ebx
80103e80:	eb e0                	jmp    80103e62 <holding+0x19>
80103e82:	bb 01 00 00 00       	mov    $0x1,%ebx
80103e87:	eb d9                	jmp    80103e62 <holding+0x19>

80103e89 <acquire>:
{
80103e89:	55                   	push   %ebp
80103e8a:	89 e5                	mov    %esp,%ebp
80103e8c:	53                   	push   %ebx
80103e8d:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103e90:	e8 17 ff ff ff       	call   80103dac <pushcli>
  if(holding(lk))
80103e95:	83 ec 0c             	sub    $0xc,%esp
80103e98:	ff 75 08             	pushl  0x8(%ebp)
80103e9b:	e8 a9 ff ff ff       	call   80103e49 <holding>
80103ea0:	83 c4 10             	add    $0x10,%esp
80103ea3:	85 c0                	test   %eax,%eax
80103ea5:	75 3a                	jne    80103ee1 <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103ea7:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103eaa:	b8 01 00 00 00       	mov    $0x1,%eax
80103eaf:	f0 87 02             	lock xchg %eax,(%edx)
80103eb2:	85 c0                	test   %eax,%eax
80103eb4:	75 f1                	jne    80103ea7 <acquire+0x1e>
  __sync_synchronize();
80103eb6:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103ebb:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103ebe:	e8 ad f5 ff ff       	call   80103470 <mycpu>
80103ec3:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103ec6:	8b 45 08             	mov    0x8(%ebp),%eax
80103ec9:	83 c0 0c             	add    $0xc,%eax
80103ecc:	83 ec 08             	sub    $0x8,%esp
80103ecf:	50                   	push   %eax
80103ed0:	8d 45 08             	lea    0x8(%ebp),%eax
80103ed3:	50                   	push   %eax
80103ed4:	e8 8f fe ff ff       	call   80103d68 <getcallerpcs>
}
80103ed9:	83 c4 10             	add    $0x10,%esp
80103edc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103edf:	c9                   	leave  
80103ee0:	c3                   	ret    
    panic("acquire");
80103ee1:	83 ec 0c             	sub    $0xc,%esp
80103ee4:	68 61 6e 10 80       	push   $0x80106e61
80103ee9:	e8 5a c4 ff ff       	call   80100348 <panic>

80103eee <release>:
{
80103eee:	55                   	push   %ebp
80103eef:	89 e5                	mov    %esp,%ebp
80103ef1:	53                   	push   %ebx
80103ef2:	83 ec 10             	sub    $0x10,%esp
80103ef5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103ef8:	53                   	push   %ebx
80103ef9:	e8 4b ff ff ff       	call   80103e49 <holding>
80103efe:	83 c4 10             	add    $0x10,%esp
80103f01:	85 c0                	test   %eax,%eax
80103f03:	74 23                	je     80103f28 <release+0x3a>
  lk->pcs[0] = 0;
80103f05:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103f0c:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103f13:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103f18:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103f1e:	e8 c6 fe ff ff       	call   80103de9 <popcli>
}
80103f23:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103f26:	c9                   	leave  
80103f27:	c3                   	ret    
    panic("release");
80103f28:	83 ec 0c             	sub    $0xc,%esp
80103f2b:	68 69 6e 10 80       	push   $0x80106e69
80103f30:	e8 13 c4 ff ff       	call   80100348 <panic>

80103f35 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103f35:	55                   	push   %ebp
80103f36:	89 e5                	mov    %esp,%ebp
80103f38:	57                   	push   %edi
80103f39:	53                   	push   %ebx
80103f3a:	8b 55 08             	mov    0x8(%ebp),%edx
80103f3d:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103f40:	f6 c2 03             	test   $0x3,%dl
80103f43:	75 05                	jne    80103f4a <memset+0x15>
80103f45:	f6 c1 03             	test   $0x3,%cl
80103f48:	74 0e                	je     80103f58 <memset+0x23>
  asm volatile("cld; rep stosb" :
80103f4a:	89 d7                	mov    %edx,%edi
80103f4c:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f4f:	fc                   	cld    
80103f50:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103f52:	89 d0                	mov    %edx,%eax
80103f54:	5b                   	pop    %ebx
80103f55:	5f                   	pop    %edi
80103f56:	5d                   	pop    %ebp
80103f57:	c3                   	ret    
    c &= 0xFF;
80103f58:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103f5c:	c1 e9 02             	shr    $0x2,%ecx
80103f5f:	89 f8                	mov    %edi,%eax
80103f61:	c1 e0 18             	shl    $0x18,%eax
80103f64:	89 fb                	mov    %edi,%ebx
80103f66:	c1 e3 10             	shl    $0x10,%ebx
80103f69:	09 d8                	or     %ebx,%eax
80103f6b:	89 fb                	mov    %edi,%ebx
80103f6d:	c1 e3 08             	shl    $0x8,%ebx
80103f70:	09 d8                	or     %ebx,%eax
80103f72:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103f74:	89 d7                	mov    %edx,%edi
80103f76:	fc                   	cld    
80103f77:	f3 ab                	rep stos %eax,%es:(%edi)
80103f79:	eb d7                	jmp    80103f52 <memset+0x1d>

80103f7b <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103f7b:	55                   	push   %ebp
80103f7c:	89 e5                	mov    %esp,%ebp
80103f7e:	56                   	push   %esi
80103f7f:	53                   	push   %ebx
80103f80:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103f83:	8b 55 0c             	mov    0xc(%ebp),%edx
80103f86:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103f89:	8d 70 ff             	lea    -0x1(%eax),%esi
80103f8c:	85 c0                	test   %eax,%eax
80103f8e:	74 1c                	je     80103fac <memcmp+0x31>
    if(*s1 != *s2)
80103f90:	0f b6 01             	movzbl (%ecx),%eax
80103f93:	0f b6 1a             	movzbl (%edx),%ebx
80103f96:	38 d8                	cmp    %bl,%al
80103f98:	75 0a                	jne    80103fa4 <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103f9a:	83 c1 01             	add    $0x1,%ecx
80103f9d:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103fa0:	89 f0                	mov    %esi,%eax
80103fa2:	eb e5                	jmp    80103f89 <memcmp+0xe>
      return *s1 - *s2;
80103fa4:	0f b6 c0             	movzbl %al,%eax
80103fa7:	0f b6 db             	movzbl %bl,%ebx
80103faa:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103fac:	5b                   	pop    %ebx
80103fad:	5e                   	pop    %esi
80103fae:	5d                   	pop    %ebp
80103faf:	c3                   	ret    

80103fb0 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103fb0:	55                   	push   %ebp
80103fb1:	89 e5                	mov    %esp,%ebp
80103fb3:	56                   	push   %esi
80103fb4:	53                   	push   %ebx
80103fb5:	8b 45 08             	mov    0x8(%ebp),%eax
80103fb8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103fbb:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103fbe:	39 c1                	cmp    %eax,%ecx
80103fc0:	73 3a                	jae    80103ffc <memmove+0x4c>
80103fc2:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
80103fc5:	39 c3                	cmp    %eax,%ebx
80103fc7:	76 37                	jbe    80104000 <memmove+0x50>
    s += n;
    d += n;
80103fc9:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80103fcc:	eb 0d                	jmp    80103fdb <memmove+0x2b>
      *--d = *--s;
80103fce:	83 eb 01             	sub    $0x1,%ebx
80103fd1:	83 e9 01             	sub    $0x1,%ecx
80103fd4:	0f b6 13             	movzbl (%ebx),%edx
80103fd7:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80103fd9:	89 f2                	mov    %esi,%edx
80103fdb:	8d 72 ff             	lea    -0x1(%edx),%esi
80103fde:	85 d2                	test   %edx,%edx
80103fe0:	75 ec                	jne    80103fce <memmove+0x1e>
80103fe2:	eb 14                	jmp    80103ff8 <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103fe4:	0f b6 11             	movzbl (%ecx),%edx
80103fe7:	88 13                	mov    %dl,(%ebx)
80103fe9:	8d 5b 01             	lea    0x1(%ebx),%ebx
80103fec:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80103fef:	89 f2                	mov    %esi,%edx
80103ff1:	8d 72 ff             	lea    -0x1(%edx),%esi
80103ff4:	85 d2                	test   %edx,%edx
80103ff6:	75 ec                	jne    80103fe4 <memmove+0x34>

  return dst;
}
80103ff8:	5b                   	pop    %ebx
80103ff9:	5e                   	pop    %esi
80103ffa:	5d                   	pop    %ebp
80103ffb:	c3                   	ret    
80103ffc:	89 c3                	mov    %eax,%ebx
80103ffe:	eb f1                	jmp    80103ff1 <memmove+0x41>
80104000:	89 c3                	mov    %eax,%ebx
80104002:	eb ed                	jmp    80103ff1 <memmove+0x41>

80104004 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80104004:	55                   	push   %ebp
80104005:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
80104007:	ff 75 10             	pushl  0x10(%ebp)
8010400a:	ff 75 0c             	pushl  0xc(%ebp)
8010400d:	ff 75 08             	pushl  0x8(%ebp)
80104010:	e8 9b ff ff ff       	call   80103fb0 <memmove>
}
80104015:	c9                   	leave  
80104016:	c3                   	ret    

80104017 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80104017:	55                   	push   %ebp
80104018:	89 e5                	mov    %esp,%ebp
8010401a:	53                   	push   %ebx
8010401b:	8b 55 08             	mov    0x8(%ebp),%edx
8010401e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80104021:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80104024:	eb 09                	jmp    8010402f <strncmp+0x18>
    n--, p++, q++;
80104026:	83 e8 01             	sub    $0x1,%eax
80104029:	83 c2 01             	add    $0x1,%edx
8010402c:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
8010402f:	85 c0                	test   %eax,%eax
80104031:	74 0b                	je     8010403e <strncmp+0x27>
80104033:	0f b6 1a             	movzbl (%edx),%ebx
80104036:	84 db                	test   %bl,%bl
80104038:	74 04                	je     8010403e <strncmp+0x27>
8010403a:	3a 19                	cmp    (%ecx),%bl
8010403c:	74 e8                	je     80104026 <strncmp+0xf>
  if(n == 0)
8010403e:	85 c0                	test   %eax,%eax
80104040:	74 0b                	je     8010404d <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80104042:	0f b6 02             	movzbl (%edx),%eax
80104045:	0f b6 11             	movzbl (%ecx),%edx
80104048:	29 d0                	sub    %edx,%eax
}
8010404a:	5b                   	pop    %ebx
8010404b:	5d                   	pop    %ebp
8010404c:	c3                   	ret    
    return 0;
8010404d:	b8 00 00 00 00       	mov    $0x0,%eax
80104052:	eb f6                	jmp    8010404a <strncmp+0x33>

80104054 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80104054:	55                   	push   %ebp
80104055:	89 e5                	mov    %esp,%ebp
80104057:	57                   	push   %edi
80104058:	56                   	push   %esi
80104059:	53                   	push   %ebx
8010405a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
8010405d:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80104060:	8b 45 08             	mov    0x8(%ebp),%eax
80104063:	eb 04                	jmp    80104069 <strncpy+0x15>
80104065:	89 fb                	mov    %edi,%ebx
80104067:	89 f0                	mov    %esi,%eax
80104069:	8d 51 ff             	lea    -0x1(%ecx),%edx
8010406c:	85 c9                	test   %ecx,%ecx
8010406e:	7e 1d                	jle    8010408d <strncpy+0x39>
80104070:	8d 7b 01             	lea    0x1(%ebx),%edi
80104073:	8d 70 01             	lea    0x1(%eax),%esi
80104076:	0f b6 1b             	movzbl (%ebx),%ebx
80104079:	88 18                	mov    %bl,(%eax)
8010407b:	89 d1                	mov    %edx,%ecx
8010407d:	84 db                	test   %bl,%bl
8010407f:	75 e4                	jne    80104065 <strncpy+0x11>
80104081:	89 f0                	mov    %esi,%eax
80104083:	eb 08                	jmp    8010408d <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
80104085:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
80104088:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
8010408a:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
8010408d:	8d 4a ff             	lea    -0x1(%edx),%ecx
80104090:	85 d2                	test   %edx,%edx
80104092:	7f f1                	jg     80104085 <strncpy+0x31>
  return os;
}
80104094:	8b 45 08             	mov    0x8(%ebp),%eax
80104097:	5b                   	pop    %ebx
80104098:	5e                   	pop    %esi
80104099:	5f                   	pop    %edi
8010409a:	5d                   	pop    %ebp
8010409b:	c3                   	ret    

8010409c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
8010409c:	55                   	push   %ebp
8010409d:	89 e5                	mov    %esp,%ebp
8010409f:	57                   	push   %edi
801040a0:	56                   	push   %esi
801040a1:	53                   	push   %ebx
801040a2:	8b 45 08             	mov    0x8(%ebp),%eax
801040a5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
801040a8:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
801040ab:	85 d2                	test   %edx,%edx
801040ad:	7e 23                	jle    801040d2 <safestrcpy+0x36>
801040af:	89 c1                	mov    %eax,%ecx
801040b1:	eb 04                	jmp    801040b7 <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
801040b3:	89 fb                	mov    %edi,%ebx
801040b5:	89 f1                	mov    %esi,%ecx
801040b7:	83 ea 01             	sub    $0x1,%edx
801040ba:	85 d2                	test   %edx,%edx
801040bc:	7e 11                	jle    801040cf <safestrcpy+0x33>
801040be:	8d 7b 01             	lea    0x1(%ebx),%edi
801040c1:	8d 71 01             	lea    0x1(%ecx),%esi
801040c4:	0f b6 1b             	movzbl (%ebx),%ebx
801040c7:	88 19                	mov    %bl,(%ecx)
801040c9:	84 db                	test   %bl,%bl
801040cb:	75 e6                	jne    801040b3 <safestrcpy+0x17>
801040cd:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
801040cf:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
801040d2:	5b                   	pop    %ebx
801040d3:	5e                   	pop    %esi
801040d4:	5f                   	pop    %edi
801040d5:	5d                   	pop    %ebp
801040d6:	c3                   	ret    

801040d7 <strlen>:

int
strlen(const char *s)
{
801040d7:	55                   	push   %ebp
801040d8:	89 e5                	mov    %esp,%ebp
801040da:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
801040dd:	b8 00 00 00 00       	mov    $0x0,%eax
801040e2:	eb 03                	jmp    801040e7 <strlen+0x10>
801040e4:	83 c0 01             	add    $0x1,%eax
801040e7:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
801040eb:	75 f7                	jne    801040e4 <strlen+0xd>
    ;
  return n;
}
801040ed:	5d                   	pop    %ebp
801040ee:	c3                   	ret    

801040ef <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
801040ef:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
801040f3:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
801040f7:	55                   	push   %ebp
  pushl %ebx
801040f8:	53                   	push   %ebx
  pushl %esi
801040f9:	56                   	push   %esi
  pushl %edi
801040fa:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
801040fb:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
801040fd:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
801040ff:	5f                   	pop    %edi
  popl %esi
80104100:	5e                   	pop    %esi
  popl %ebx
80104101:	5b                   	pop    %ebx
  popl %ebp
80104102:	5d                   	pop    %ebp
  ret
80104103:	c3                   	ret    

80104104 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80104104:	55                   	push   %ebp
80104105:	89 e5                	mov    %esp,%ebp
80104107:	53                   	push   %ebx
80104108:	83 ec 04             	sub    $0x4,%esp
8010410b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
8010410e:	e8 d4 f3 ff ff       	call   801034e7 <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80104113:	8b 00                	mov    (%eax),%eax
80104115:	39 d8                	cmp    %ebx,%eax
80104117:	76 19                	jbe    80104132 <fetchint+0x2e>
80104119:	8d 53 04             	lea    0x4(%ebx),%edx
8010411c:	39 d0                	cmp    %edx,%eax
8010411e:	72 19                	jb     80104139 <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80104120:	8b 13                	mov    (%ebx),%edx
80104122:	8b 45 0c             	mov    0xc(%ebp),%eax
80104125:	89 10                	mov    %edx,(%eax)
  return 0;
80104127:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010412c:	83 c4 04             	add    $0x4,%esp
8010412f:	5b                   	pop    %ebx
80104130:	5d                   	pop    %ebp
80104131:	c3                   	ret    
    return -1;
80104132:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104137:	eb f3                	jmp    8010412c <fetchint+0x28>
80104139:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010413e:	eb ec                	jmp    8010412c <fetchint+0x28>

80104140 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80104140:	55                   	push   %ebp
80104141:	89 e5                	mov    %esp,%ebp
80104143:	53                   	push   %ebx
80104144:	83 ec 04             	sub    $0x4,%esp
80104147:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
8010414a:	e8 98 f3 ff ff       	call   801034e7 <myproc>

  if(addr >= curproc->sz)
8010414f:	39 18                	cmp    %ebx,(%eax)
80104151:	76 26                	jbe    80104179 <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
80104153:	8b 55 0c             	mov    0xc(%ebp),%edx
80104156:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
80104158:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
8010415a:	89 d8                	mov    %ebx,%eax
8010415c:	39 d0                	cmp    %edx,%eax
8010415e:	73 0e                	jae    8010416e <fetchstr+0x2e>
    if(*s == 0)
80104160:	80 38 00             	cmpb   $0x0,(%eax)
80104163:	74 05                	je     8010416a <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
80104165:	83 c0 01             	add    $0x1,%eax
80104168:	eb f2                	jmp    8010415c <fetchstr+0x1c>
      return s - *pp;
8010416a:	29 d8                	sub    %ebx,%eax
8010416c:	eb 05                	jmp    80104173 <fetchstr+0x33>
  }
  return -1;
8010416e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104173:	83 c4 04             	add    $0x4,%esp
80104176:	5b                   	pop    %ebx
80104177:	5d                   	pop    %ebp
80104178:	c3                   	ret    
    return -1;
80104179:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010417e:	eb f3                	jmp    80104173 <fetchstr+0x33>

80104180 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80104180:	55                   	push   %ebp
80104181:	89 e5                	mov    %esp,%ebp
80104183:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80104186:	e8 5c f3 ff ff       	call   801034e7 <myproc>
8010418b:	8b 50 18             	mov    0x18(%eax),%edx
8010418e:	8b 45 08             	mov    0x8(%ebp),%eax
80104191:	c1 e0 02             	shl    $0x2,%eax
80104194:	03 42 44             	add    0x44(%edx),%eax
80104197:	83 ec 08             	sub    $0x8,%esp
8010419a:	ff 75 0c             	pushl  0xc(%ebp)
8010419d:	83 c0 04             	add    $0x4,%eax
801041a0:	50                   	push   %eax
801041a1:	e8 5e ff ff ff       	call   80104104 <fetchint>
}
801041a6:	c9                   	leave  
801041a7:	c3                   	ret    

801041a8 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801041a8:	55                   	push   %ebp
801041a9:	89 e5                	mov    %esp,%ebp
801041ab:	56                   	push   %esi
801041ac:	53                   	push   %ebx
801041ad:	83 ec 10             	sub    $0x10,%esp
801041b0:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
801041b3:	e8 2f f3 ff ff       	call   801034e7 <myproc>
801041b8:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
801041ba:	83 ec 08             	sub    $0x8,%esp
801041bd:	8d 45 f4             	lea    -0xc(%ebp),%eax
801041c0:	50                   	push   %eax
801041c1:	ff 75 08             	pushl  0x8(%ebp)
801041c4:	e8 b7 ff ff ff       	call   80104180 <argint>
801041c9:	83 c4 10             	add    $0x10,%esp
801041cc:	85 c0                	test   %eax,%eax
801041ce:	78 24                	js     801041f4 <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
801041d0:	85 db                	test   %ebx,%ebx
801041d2:	78 27                	js     801041fb <argptr+0x53>
801041d4:	8b 16                	mov    (%esi),%edx
801041d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041d9:	39 c2                	cmp    %eax,%edx
801041db:	76 25                	jbe    80104202 <argptr+0x5a>
801041dd:	01 c3                	add    %eax,%ebx
801041df:	39 da                	cmp    %ebx,%edx
801041e1:	72 26                	jb     80104209 <argptr+0x61>
    return -1;
  *pp = (char*)i;
801041e3:	8b 55 0c             	mov    0xc(%ebp),%edx
801041e6:	89 02                	mov    %eax,(%edx)
  return 0;
801041e8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801041ed:	8d 65 f8             	lea    -0x8(%ebp),%esp
801041f0:	5b                   	pop    %ebx
801041f1:	5e                   	pop    %esi
801041f2:	5d                   	pop    %ebp
801041f3:	c3                   	ret    
    return -1;
801041f4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801041f9:	eb f2                	jmp    801041ed <argptr+0x45>
    return -1;
801041fb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104200:	eb eb                	jmp    801041ed <argptr+0x45>
80104202:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104207:	eb e4                	jmp    801041ed <argptr+0x45>
80104209:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010420e:	eb dd                	jmp    801041ed <argptr+0x45>

80104210 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80104210:	55                   	push   %ebp
80104211:	89 e5                	mov    %esp,%ebp
80104213:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
80104216:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104219:	50                   	push   %eax
8010421a:	ff 75 08             	pushl  0x8(%ebp)
8010421d:	e8 5e ff ff ff       	call   80104180 <argint>
80104222:	83 c4 10             	add    $0x10,%esp
80104225:	85 c0                	test   %eax,%eax
80104227:	78 13                	js     8010423c <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
80104229:	83 ec 08             	sub    $0x8,%esp
8010422c:	ff 75 0c             	pushl  0xc(%ebp)
8010422f:	ff 75 f4             	pushl  -0xc(%ebp)
80104232:	e8 09 ff ff ff       	call   80104140 <fetchstr>
80104237:	83 c4 10             	add    $0x10,%esp
}
8010423a:	c9                   	leave  
8010423b:	c3                   	ret    
    return -1;
8010423c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104241:	eb f7                	jmp    8010423a <argstr+0x2a>

80104243 <syscall>:
[SYS_dump_physmem]   sys_dump_physmem,
};

void
syscall(void)
{
80104243:	55                   	push   %ebp
80104244:	89 e5                	mov    %esp,%ebp
80104246:	53                   	push   %ebx
80104247:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
8010424a:	e8 98 f2 ff ff       	call   801034e7 <myproc>
8010424f:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
80104251:	8b 40 18             	mov    0x18(%eax),%eax
80104254:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80104257:	8d 50 ff             	lea    -0x1(%eax),%edx
8010425a:	83 fa 15             	cmp    $0x15,%edx
8010425d:	77 18                	ja     80104277 <syscall+0x34>
8010425f:	8b 14 85 a0 6e 10 80 	mov    -0x7fef9160(,%eax,4),%edx
80104266:	85 d2                	test   %edx,%edx
80104268:	74 0d                	je     80104277 <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
8010426a:	ff d2                	call   *%edx
8010426c:	8b 53 18             	mov    0x18(%ebx),%edx
8010426f:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
80104272:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104275:	c9                   	leave  
80104276:	c3                   	ret    
            curproc->pid, curproc->name, num);
80104277:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
8010427a:	50                   	push   %eax
8010427b:	52                   	push   %edx
8010427c:	ff 73 10             	pushl  0x10(%ebx)
8010427f:	68 71 6e 10 80       	push   $0x80106e71
80104284:	e8 82 c3 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
80104289:	8b 43 18             	mov    0x18(%ebx),%eax
8010428c:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
80104293:	83 c4 10             	add    $0x10,%esp
}
80104296:	eb da                	jmp    80104272 <syscall+0x2f>

80104298 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80104298:	55                   	push   %ebp
80104299:	89 e5                	mov    %esp,%ebp
8010429b:	56                   	push   %esi
8010429c:	53                   	push   %ebx
8010429d:	83 ec 18             	sub    $0x18,%esp
801042a0:	89 d6                	mov    %edx,%esi
801042a2:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801042a4:	8d 55 f4             	lea    -0xc(%ebp),%edx
801042a7:	52                   	push   %edx
801042a8:	50                   	push   %eax
801042a9:	e8 d2 fe ff ff       	call   80104180 <argint>
801042ae:	83 c4 10             	add    $0x10,%esp
801042b1:	85 c0                	test   %eax,%eax
801042b3:	78 2e                	js     801042e3 <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
801042b5:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
801042b9:	77 2f                	ja     801042ea <argfd+0x52>
801042bb:	e8 27 f2 ff ff       	call   801034e7 <myproc>
801042c0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042c3:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
801042c7:	85 c0                	test   %eax,%eax
801042c9:	74 26                	je     801042f1 <argfd+0x59>
    return -1;
  if(pfd)
801042cb:	85 f6                	test   %esi,%esi
801042cd:	74 02                	je     801042d1 <argfd+0x39>
    *pfd = fd;
801042cf:	89 16                	mov    %edx,(%esi)
  if(pf)
801042d1:	85 db                	test   %ebx,%ebx
801042d3:	74 23                	je     801042f8 <argfd+0x60>
    *pf = f;
801042d5:	89 03                	mov    %eax,(%ebx)
  return 0;
801042d7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801042dc:	8d 65 f8             	lea    -0x8(%ebp),%esp
801042df:	5b                   	pop    %ebx
801042e0:	5e                   	pop    %esi
801042e1:	5d                   	pop    %ebp
801042e2:	c3                   	ret    
    return -1;
801042e3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042e8:	eb f2                	jmp    801042dc <argfd+0x44>
    return -1;
801042ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042ef:	eb eb                	jmp    801042dc <argfd+0x44>
801042f1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801042f6:	eb e4                	jmp    801042dc <argfd+0x44>
  return 0;
801042f8:	b8 00 00 00 00       	mov    $0x0,%eax
801042fd:	eb dd                	jmp    801042dc <argfd+0x44>

801042ff <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801042ff:	55                   	push   %ebp
80104300:	89 e5                	mov    %esp,%ebp
80104302:	53                   	push   %ebx
80104303:	83 ec 04             	sub    $0x4,%esp
80104306:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
80104308:	e8 da f1 ff ff       	call   801034e7 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
8010430d:	ba 00 00 00 00       	mov    $0x0,%edx
80104312:	83 fa 0f             	cmp    $0xf,%edx
80104315:	7f 18                	jg     8010432f <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
80104317:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
8010431c:	74 05                	je     80104323 <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
8010431e:	83 c2 01             	add    $0x1,%edx
80104321:	eb ef                	jmp    80104312 <fdalloc+0x13>
      curproc->ofile[fd] = f;
80104323:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
80104327:	89 d0                	mov    %edx,%eax
80104329:	83 c4 04             	add    $0x4,%esp
8010432c:	5b                   	pop    %ebx
8010432d:	5d                   	pop    %ebp
8010432e:	c3                   	ret    
  return -1;
8010432f:	ba ff ff ff ff       	mov    $0xffffffff,%edx
80104334:	eb f1                	jmp    80104327 <fdalloc+0x28>

80104336 <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80104336:	55                   	push   %ebp
80104337:	89 e5                	mov    %esp,%ebp
80104339:	56                   	push   %esi
8010433a:	53                   	push   %ebx
8010433b:	83 ec 10             	sub    $0x10,%esp
8010433e:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104340:	b8 20 00 00 00       	mov    $0x20,%eax
80104345:	89 c6                	mov    %eax,%esi
80104347:	39 43 58             	cmp    %eax,0x58(%ebx)
8010434a:	76 2e                	jbe    8010437a <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010434c:	6a 10                	push   $0x10
8010434e:	50                   	push   %eax
8010434f:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104352:	50                   	push   %eax
80104353:	53                   	push   %ebx
80104354:	e8 1a d4 ff ff       	call   80101773 <readi>
80104359:	83 c4 10             	add    $0x10,%esp
8010435c:	83 f8 10             	cmp    $0x10,%eax
8010435f:	75 0c                	jne    8010436d <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
80104361:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
80104366:	75 1e                	jne    80104386 <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104368:	8d 46 10             	lea    0x10(%esi),%eax
8010436b:	eb d8                	jmp    80104345 <isdirempty+0xf>
      panic("isdirempty: readi");
8010436d:	83 ec 0c             	sub    $0xc,%esp
80104370:	68 fc 6e 10 80       	push   $0x80106efc
80104375:	e8 ce bf ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
8010437a:	b8 01 00 00 00       	mov    $0x1,%eax
}
8010437f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104382:	5b                   	pop    %ebx
80104383:	5e                   	pop    %esi
80104384:	5d                   	pop    %ebp
80104385:	c3                   	ret    
      return 0;
80104386:	b8 00 00 00 00       	mov    $0x0,%eax
8010438b:	eb f2                	jmp    8010437f <isdirempty+0x49>

8010438d <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
8010438d:	55                   	push   %ebp
8010438e:	89 e5                	mov    %esp,%ebp
80104390:	57                   	push   %edi
80104391:	56                   	push   %esi
80104392:	53                   	push   %ebx
80104393:	83 ec 44             	sub    $0x44,%esp
80104396:	89 55 c4             	mov    %edx,-0x3c(%ebp)
80104399:	89 4d c0             	mov    %ecx,-0x40(%ebp)
8010439c:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
8010439f:	8d 55 d6             	lea    -0x2a(%ebp),%edx
801043a2:	52                   	push   %edx
801043a3:	50                   	push   %eax
801043a4:	e8 50 d8 ff ff       	call   80101bf9 <nameiparent>
801043a9:	89 c6                	mov    %eax,%esi
801043ab:	83 c4 10             	add    $0x10,%esp
801043ae:	85 c0                	test   %eax,%eax
801043b0:	0f 84 3a 01 00 00    	je     801044f0 <create+0x163>
    return 0;
  ilock(dp);
801043b6:	83 ec 0c             	sub    $0xc,%esp
801043b9:	50                   	push   %eax
801043ba:	e8 c2 d1 ff ff       	call   80101581 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
801043bf:	83 c4 0c             	add    $0xc,%esp
801043c2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801043c5:	50                   	push   %eax
801043c6:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801043c9:	50                   	push   %eax
801043ca:	56                   	push   %esi
801043cb:	e8 e0 d5 ff ff       	call   801019b0 <dirlookup>
801043d0:	89 c3                	mov    %eax,%ebx
801043d2:	83 c4 10             	add    $0x10,%esp
801043d5:	85 c0                	test   %eax,%eax
801043d7:	74 3f                	je     80104418 <create+0x8b>
    iunlockput(dp);
801043d9:	83 ec 0c             	sub    $0xc,%esp
801043dc:	56                   	push   %esi
801043dd:	e8 46 d3 ff ff       	call   80101728 <iunlockput>
    ilock(ip);
801043e2:	89 1c 24             	mov    %ebx,(%esp)
801043e5:	e8 97 d1 ff ff       	call   80101581 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
801043ea:	83 c4 10             	add    $0x10,%esp
801043ed:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
801043f2:	75 11                	jne    80104405 <create+0x78>
801043f4:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
801043f9:	75 0a                	jne    80104405 <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
801043fb:	89 d8                	mov    %ebx,%eax
801043fd:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104400:	5b                   	pop    %ebx
80104401:	5e                   	pop    %esi
80104402:	5f                   	pop    %edi
80104403:	5d                   	pop    %ebp
80104404:	c3                   	ret    
    iunlockput(ip);
80104405:	83 ec 0c             	sub    $0xc,%esp
80104408:	53                   	push   %ebx
80104409:	e8 1a d3 ff ff       	call   80101728 <iunlockput>
    return 0;
8010440e:	83 c4 10             	add    $0x10,%esp
80104411:	bb 00 00 00 00       	mov    $0x0,%ebx
80104416:	eb e3                	jmp    801043fb <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
80104418:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
8010441c:	83 ec 08             	sub    $0x8,%esp
8010441f:	50                   	push   %eax
80104420:	ff 36                	pushl  (%esi)
80104422:	e8 57 cf ff ff       	call   8010137e <ialloc>
80104427:	89 c3                	mov    %eax,%ebx
80104429:	83 c4 10             	add    $0x10,%esp
8010442c:	85 c0                	test   %eax,%eax
8010442e:	74 55                	je     80104485 <create+0xf8>
  ilock(ip);
80104430:	83 ec 0c             	sub    $0xc,%esp
80104433:	50                   	push   %eax
80104434:	e8 48 d1 ff ff       	call   80101581 <ilock>
  ip->major = major;
80104439:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
8010443d:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
80104441:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
80104445:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
8010444b:	89 1c 24             	mov    %ebx,(%esp)
8010444e:	e8 cd cf ff ff       	call   80101420 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
80104453:	83 c4 10             	add    $0x10,%esp
80104456:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
8010445b:	74 35                	je     80104492 <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
8010445d:	83 ec 04             	sub    $0x4,%esp
80104460:	ff 73 04             	pushl  0x4(%ebx)
80104463:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104466:	50                   	push   %eax
80104467:	56                   	push   %esi
80104468:	e8 c3 d6 ff ff       	call   80101b30 <dirlink>
8010446d:	83 c4 10             	add    $0x10,%esp
80104470:	85 c0                	test   %eax,%eax
80104472:	78 6f                	js     801044e3 <create+0x156>
  iunlockput(dp);
80104474:	83 ec 0c             	sub    $0xc,%esp
80104477:	56                   	push   %esi
80104478:	e8 ab d2 ff ff       	call   80101728 <iunlockput>
  return ip;
8010447d:	83 c4 10             	add    $0x10,%esp
80104480:	e9 76 ff ff ff       	jmp    801043fb <create+0x6e>
    panic("create: ialloc");
80104485:	83 ec 0c             	sub    $0xc,%esp
80104488:	68 0e 6f 10 80       	push   $0x80106f0e
8010448d:	e8 b6 be ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
80104492:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104496:	83 c0 01             	add    $0x1,%eax
80104499:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
8010449d:	83 ec 0c             	sub    $0xc,%esp
801044a0:	56                   	push   %esi
801044a1:	e8 7a cf ff ff       	call   80101420 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
801044a6:	83 c4 0c             	add    $0xc,%esp
801044a9:	ff 73 04             	pushl  0x4(%ebx)
801044ac:	68 1e 6f 10 80       	push   $0x80106f1e
801044b1:	53                   	push   %ebx
801044b2:	e8 79 d6 ff ff       	call   80101b30 <dirlink>
801044b7:	83 c4 10             	add    $0x10,%esp
801044ba:	85 c0                	test   %eax,%eax
801044bc:	78 18                	js     801044d6 <create+0x149>
801044be:	83 ec 04             	sub    $0x4,%esp
801044c1:	ff 76 04             	pushl  0x4(%esi)
801044c4:	68 1d 6f 10 80       	push   $0x80106f1d
801044c9:	53                   	push   %ebx
801044ca:	e8 61 d6 ff ff       	call   80101b30 <dirlink>
801044cf:	83 c4 10             	add    $0x10,%esp
801044d2:	85 c0                	test   %eax,%eax
801044d4:	79 87                	jns    8010445d <create+0xd0>
      panic("create dots");
801044d6:	83 ec 0c             	sub    $0xc,%esp
801044d9:	68 20 6f 10 80       	push   $0x80106f20
801044de:	e8 65 be ff ff       	call   80100348 <panic>
    panic("create: dirlink");
801044e3:	83 ec 0c             	sub    $0xc,%esp
801044e6:	68 2c 6f 10 80       	push   $0x80106f2c
801044eb:	e8 58 be ff ff       	call   80100348 <panic>
    return 0;
801044f0:	89 c3                	mov    %eax,%ebx
801044f2:	e9 04 ff ff ff       	jmp    801043fb <create+0x6e>

801044f7 <sys_dup>:
{
801044f7:	55                   	push   %ebp
801044f8:	89 e5                	mov    %esp,%ebp
801044fa:	53                   	push   %ebx
801044fb:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
801044fe:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104501:	ba 00 00 00 00       	mov    $0x0,%edx
80104506:	b8 00 00 00 00       	mov    $0x0,%eax
8010450b:	e8 88 fd ff ff       	call   80104298 <argfd>
80104510:	85 c0                	test   %eax,%eax
80104512:	78 23                	js     80104537 <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
80104514:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104517:	e8 e3 fd ff ff       	call   801042ff <fdalloc>
8010451c:	89 c3                	mov    %eax,%ebx
8010451e:	85 c0                	test   %eax,%eax
80104520:	78 1c                	js     8010453e <sys_dup+0x47>
  filedup(f);
80104522:	83 ec 0c             	sub    $0xc,%esp
80104525:	ff 75 f4             	pushl  -0xc(%ebp)
80104528:	e8 61 c7 ff ff       	call   80100c8e <filedup>
  return fd;
8010452d:	83 c4 10             	add    $0x10,%esp
}
80104530:	89 d8                	mov    %ebx,%eax
80104532:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104535:	c9                   	leave  
80104536:	c3                   	ret    
    return -1;
80104537:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010453c:	eb f2                	jmp    80104530 <sys_dup+0x39>
    return -1;
8010453e:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104543:	eb eb                	jmp    80104530 <sys_dup+0x39>

80104545 <sys_read>:
{
80104545:	55                   	push   %ebp
80104546:	89 e5                	mov    %esp,%ebp
80104548:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010454b:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010454e:	ba 00 00 00 00       	mov    $0x0,%edx
80104553:	b8 00 00 00 00       	mov    $0x0,%eax
80104558:	e8 3b fd ff ff       	call   80104298 <argfd>
8010455d:	85 c0                	test   %eax,%eax
8010455f:	78 43                	js     801045a4 <sys_read+0x5f>
80104561:	83 ec 08             	sub    $0x8,%esp
80104564:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104567:	50                   	push   %eax
80104568:	6a 02                	push   $0x2
8010456a:	e8 11 fc ff ff       	call   80104180 <argint>
8010456f:	83 c4 10             	add    $0x10,%esp
80104572:	85 c0                	test   %eax,%eax
80104574:	78 35                	js     801045ab <sys_read+0x66>
80104576:	83 ec 04             	sub    $0x4,%esp
80104579:	ff 75 f0             	pushl  -0x10(%ebp)
8010457c:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010457f:	50                   	push   %eax
80104580:	6a 01                	push   $0x1
80104582:	e8 21 fc ff ff       	call   801041a8 <argptr>
80104587:	83 c4 10             	add    $0x10,%esp
8010458a:	85 c0                	test   %eax,%eax
8010458c:	78 24                	js     801045b2 <sys_read+0x6d>
  return fileread(f, p, n);
8010458e:	83 ec 04             	sub    $0x4,%esp
80104591:	ff 75 f0             	pushl  -0x10(%ebp)
80104594:	ff 75 ec             	pushl  -0x14(%ebp)
80104597:	ff 75 f4             	pushl  -0xc(%ebp)
8010459a:	e8 38 c8 ff ff       	call   80100dd7 <fileread>
8010459f:	83 c4 10             	add    $0x10,%esp
}
801045a2:	c9                   	leave  
801045a3:	c3                   	ret    
    return -1;
801045a4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045a9:	eb f7                	jmp    801045a2 <sys_read+0x5d>
801045ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045b0:	eb f0                	jmp    801045a2 <sys_read+0x5d>
801045b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045b7:	eb e9                	jmp    801045a2 <sys_read+0x5d>

801045b9 <sys_write>:
{
801045b9:	55                   	push   %ebp
801045ba:	89 e5                	mov    %esp,%ebp
801045bc:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801045bf:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801045c2:	ba 00 00 00 00       	mov    $0x0,%edx
801045c7:	b8 00 00 00 00       	mov    $0x0,%eax
801045cc:	e8 c7 fc ff ff       	call   80104298 <argfd>
801045d1:	85 c0                	test   %eax,%eax
801045d3:	78 43                	js     80104618 <sys_write+0x5f>
801045d5:	83 ec 08             	sub    $0x8,%esp
801045d8:	8d 45 f0             	lea    -0x10(%ebp),%eax
801045db:	50                   	push   %eax
801045dc:	6a 02                	push   $0x2
801045de:	e8 9d fb ff ff       	call   80104180 <argint>
801045e3:	83 c4 10             	add    $0x10,%esp
801045e6:	85 c0                	test   %eax,%eax
801045e8:	78 35                	js     8010461f <sys_write+0x66>
801045ea:	83 ec 04             	sub    $0x4,%esp
801045ed:	ff 75 f0             	pushl  -0x10(%ebp)
801045f0:	8d 45 ec             	lea    -0x14(%ebp),%eax
801045f3:	50                   	push   %eax
801045f4:	6a 01                	push   $0x1
801045f6:	e8 ad fb ff ff       	call   801041a8 <argptr>
801045fb:	83 c4 10             	add    $0x10,%esp
801045fe:	85 c0                	test   %eax,%eax
80104600:	78 24                	js     80104626 <sys_write+0x6d>
  return filewrite(f, p, n);
80104602:	83 ec 04             	sub    $0x4,%esp
80104605:	ff 75 f0             	pushl  -0x10(%ebp)
80104608:	ff 75 ec             	pushl  -0x14(%ebp)
8010460b:	ff 75 f4             	pushl  -0xc(%ebp)
8010460e:	e8 49 c8 ff ff       	call   80100e5c <filewrite>
80104613:	83 c4 10             	add    $0x10,%esp
}
80104616:	c9                   	leave  
80104617:	c3                   	ret    
    return -1;
80104618:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010461d:	eb f7                	jmp    80104616 <sys_write+0x5d>
8010461f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104624:	eb f0                	jmp    80104616 <sys_write+0x5d>
80104626:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010462b:	eb e9                	jmp    80104616 <sys_write+0x5d>

8010462d <sys_close>:
{
8010462d:	55                   	push   %ebp
8010462e:	89 e5                	mov    %esp,%ebp
80104630:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
80104633:	8d 4d f0             	lea    -0x10(%ebp),%ecx
80104636:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104639:	b8 00 00 00 00       	mov    $0x0,%eax
8010463e:	e8 55 fc ff ff       	call   80104298 <argfd>
80104643:	85 c0                	test   %eax,%eax
80104645:	78 25                	js     8010466c <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
80104647:	e8 9b ee ff ff       	call   801034e7 <myproc>
8010464c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010464f:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
80104656:	00 
  fileclose(f);
80104657:	83 ec 0c             	sub    $0xc,%esp
8010465a:	ff 75 f0             	pushl  -0x10(%ebp)
8010465d:	e8 71 c6 ff ff       	call   80100cd3 <fileclose>
  return 0;
80104662:	83 c4 10             	add    $0x10,%esp
80104665:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010466a:	c9                   	leave  
8010466b:	c3                   	ret    
    return -1;
8010466c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104671:	eb f7                	jmp    8010466a <sys_close+0x3d>

80104673 <sys_fstat>:
{
80104673:	55                   	push   %ebp
80104674:	89 e5                	mov    %esp,%ebp
80104676:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80104679:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010467c:	ba 00 00 00 00       	mov    $0x0,%edx
80104681:	b8 00 00 00 00       	mov    $0x0,%eax
80104686:	e8 0d fc ff ff       	call   80104298 <argfd>
8010468b:	85 c0                	test   %eax,%eax
8010468d:	78 2a                	js     801046b9 <sys_fstat+0x46>
8010468f:	83 ec 04             	sub    $0x4,%esp
80104692:	6a 14                	push   $0x14
80104694:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104697:	50                   	push   %eax
80104698:	6a 01                	push   $0x1
8010469a:	e8 09 fb ff ff       	call   801041a8 <argptr>
8010469f:	83 c4 10             	add    $0x10,%esp
801046a2:	85 c0                	test   %eax,%eax
801046a4:	78 1a                	js     801046c0 <sys_fstat+0x4d>
  return filestat(f, st);
801046a6:	83 ec 08             	sub    $0x8,%esp
801046a9:	ff 75 f0             	pushl  -0x10(%ebp)
801046ac:	ff 75 f4             	pushl  -0xc(%ebp)
801046af:	e8 dc c6 ff ff       	call   80100d90 <filestat>
801046b4:	83 c4 10             	add    $0x10,%esp
}
801046b7:	c9                   	leave  
801046b8:	c3                   	ret    
    return -1;
801046b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046be:	eb f7                	jmp    801046b7 <sys_fstat+0x44>
801046c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046c5:	eb f0                	jmp    801046b7 <sys_fstat+0x44>

801046c7 <sys_link>:
{
801046c7:	55                   	push   %ebp
801046c8:	89 e5                	mov    %esp,%ebp
801046ca:	56                   	push   %esi
801046cb:	53                   	push   %ebx
801046cc:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801046cf:	8d 45 e0             	lea    -0x20(%ebp),%eax
801046d2:	50                   	push   %eax
801046d3:	6a 00                	push   $0x0
801046d5:	e8 36 fb ff ff       	call   80104210 <argstr>
801046da:	83 c4 10             	add    $0x10,%esp
801046dd:	85 c0                	test   %eax,%eax
801046df:	0f 88 32 01 00 00    	js     80104817 <sys_link+0x150>
801046e5:	83 ec 08             	sub    $0x8,%esp
801046e8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801046eb:	50                   	push   %eax
801046ec:	6a 01                	push   $0x1
801046ee:	e8 1d fb ff ff       	call   80104210 <argstr>
801046f3:	83 c4 10             	add    $0x10,%esp
801046f6:	85 c0                	test   %eax,%eax
801046f8:	0f 88 20 01 00 00    	js     8010481e <sys_link+0x157>
  begin_op();
801046fe:	e8 94 e3 ff ff       	call   80102a97 <begin_op>
  if((ip = namei(old)) == 0){
80104703:	83 ec 0c             	sub    $0xc,%esp
80104706:	ff 75 e0             	pushl  -0x20(%ebp)
80104709:	e8 d3 d4 ff ff       	call   80101be1 <namei>
8010470e:	89 c3                	mov    %eax,%ebx
80104710:	83 c4 10             	add    $0x10,%esp
80104713:	85 c0                	test   %eax,%eax
80104715:	0f 84 99 00 00 00    	je     801047b4 <sys_link+0xed>
  ilock(ip);
8010471b:	83 ec 0c             	sub    $0xc,%esp
8010471e:	50                   	push   %eax
8010471f:	e8 5d ce ff ff       	call   80101581 <ilock>
  if(ip->type == T_DIR){
80104724:	83 c4 10             	add    $0x10,%esp
80104727:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010472c:	0f 84 8e 00 00 00    	je     801047c0 <sys_link+0xf9>
  ip->nlink++;
80104732:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104736:	83 c0 01             	add    $0x1,%eax
80104739:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
8010473d:	83 ec 0c             	sub    $0xc,%esp
80104740:	53                   	push   %ebx
80104741:	e8 da cc ff ff       	call   80101420 <iupdate>
  iunlock(ip);
80104746:	89 1c 24             	mov    %ebx,(%esp)
80104749:	e8 f5 ce ff ff       	call   80101643 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
8010474e:	83 c4 08             	add    $0x8,%esp
80104751:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104754:	50                   	push   %eax
80104755:	ff 75 e4             	pushl  -0x1c(%ebp)
80104758:	e8 9c d4 ff ff       	call   80101bf9 <nameiparent>
8010475d:	89 c6                	mov    %eax,%esi
8010475f:	83 c4 10             	add    $0x10,%esp
80104762:	85 c0                	test   %eax,%eax
80104764:	74 7e                	je     801047e4 <sys_link+0x11d>
  ilock(dp);
80104766:	83 ec 0c             	sub    $0xc,%esp
80104769:	50                   	push   %eax
8010476a:	e8 12 ce ff ff       	call   80101581 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
8010476f:	83 c4 10             	add    $0x10,%esp
80104772:	8b 03                	mov    (%ebx),%eax
80104774:	39 06                	cmp    %eax,(%esi)
80104776:	75 60                	jne    801047d8 <sys_link+0x111>
80104778:	83 ec 04             	sub    $0x4,%esp
8010477b:	ff 73 04             	pushl  0x4(%ebx)
8010477e:	8d 45 ea             	lea    -0x16(%ebp),%eax
80104781:	50                   	push   %eax
80104782:	56                   	push   %esi
80104783:	e8 a8 d3 ff ff       	call   80101b30 <dirlink>
80104788:	83 c4 10             	add    $0x10,%esp
8010478b:	85 c0                	test   %eax,%eax
8010478d:	78 49                	js     801047d8 <sys_link+0x111>
  iunlockput(dp);
8010478f:	83 ec 0c             	sub    $0xc,%esp
80104792:	56                   	push   %esi
80104793:	e8 90 cf ff ff       	call   80101728 <iunlockput>
  iput(ip);
80104798:	89 1c 24             	mov    %ebx,(%esp)
8010479b:	e8 e8 ce ff ff       	call   80101688 <iput>
  end_op();
801047a0:	e8 6c e3 ff ff       	call   80102b11 <end_op>
  return 0;
801047a5:	83 c4 10             	add    $0x10,%esp
801047a8:	b8 00 00 00 00       	mov    $0x0,%eax
}
801047ad:	8d 65 f8             	lea    -0x8(%ebp),%esp
801047b0:	5b                   	pop    %ebx
801047b1:	5e                   	pop    %esi
801047b2:	5d                   	pop    %ebp
801047b3:	c3                   	ret    
    end_op();
801047b4:	e8 58 e3 ff ff       	call   80102b11 <end_op>
    return -1;
801047b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047be:	eb ed                	jmp    801047ad <sys_link+0xe6>
    iunlockput(ip);
801047c0:	83 ec 0c             	sub    $0xc,%esp
801047c3:	53                   	push   %ebx
801047c4:	e8 5f cf ff ff       	call   80101728 <iunlockput>
    end_op();
801047c9:	e8 43 e3 ff ff       	call   80102b11 <end_op>
    return -1;
801047ce:	83 c4 10             	add    $0x10,%esp
801047d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801047d6:	eb d5                	jmp    801047ad <sys_link+0xe6>
    iunlockput(dp);
801047d8:	83 ec 0c             	sub    $0xc,%esp
801047db:	56                   	push   %esi
801047dc:	e8 47 cf ff ff       	call   80101728 <iunlockput>
    goto bad;
801047e1:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
801047e4:	83 ec 0c             	sub    $0xc,%esp
801047e7:	53                   	push   %ebx
801047e8:	e8 94 cd ff ff       	call   80101581 <ilock>
  ip->nlink--;
801047ed:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801047f1:	83 e8 01             	sub    $0x1,%eax
801047f4:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801047f8:	89 1c 24             	mov    %ebx,(%esp)
801047fb:	e8 20 cc ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104800:	89 1c 24             	mov    %ebx,(%esp)
80104803:	e8 20 cf ff ff       	call   80101728 <iunlockput>
  end_op();
80104808:	e8 04 e3 ff ff       	call   80102b11 <end_op>
  return -1;
8010480d:	83 c4 10             	add    $0x10,%esp
80104810:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104815:	eb 96                	jmp    801047ad <sys_link+0xe6>
    return -1;
80104817:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010481c:	eb 8f                	jmp    801047ad <sys_link+0xe6>
8010481e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104823:	eb 88                	jmp    801047ad <sys_link+0xe6>

80104825 <sys_unlink>:
{
80104825:	55                   	push   %ebp
80104826:	89 e5                	mov    %esp,%ebp
80104828:	57                   	push   %edi
80104829:	56                   	push   %esi
8010482a:	53                   	push   %ebx
8010482b:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
8010482e:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104831:	50                   	push   %eax
80104832:	6a 00                	push   $0x0
80104834:	e8 d7 f9 ff ff       	call   80104210 <argstr>
80104839:	83 c4 10             	add    $0x10,%esp
8010483c:	85 c0                	test   %eax,%eax
8010483e:	0f 88 83 01 00 00    	js     801049c7 <sys_unlink+0x1a2>
  begin_op();
80104844:	e8 4e e2 ff ff       	call   80102a97 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80104849:	83 ec 08             	sub    $0x8,%esp
8010484c:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010484f:	50                   	push   %eax
80104850:	ff 75 c4             	pushl  -0x3c(%ebp)
80104853:	e8 a1 d3 ff ff       	call   80101bf9 <nameiparent>
80104858:	89 c6                	mov    %eax,%esi
8010485a:	83 c4 10             	add    $0x10,%esp
8010485d:	85 c0                	test   %eax,%eax
8010485f:	0f 84 ed 00 00 00    	je     80104952 <sys_unlink+0x12d>
  ilock(dp);
80104865:	83 ec 0c             	sub    $0xc,%esp
80104868:	50                   	push   %eax
80104869:	e8 13 cd ff ff       	call   80101581 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
8010486e:	83 c4 08             	add    $0x8,%esp
80104871:	68 1e 6f 10 80       	push   $0x80106f1e
80104876:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104879:	50                   	push   %eax
8010487a:	e8 1c d1 ff ff       	call   8010199b <namecmp>
8010487f:	83 c4 10             	add    $0x10,%esp
80104882:	85 c0                	test   %eax,%eax
80104884:	0f 84 fc 00 00 00    	je     80104986 <sys_unlink+0x161>
8010488a:	83 ec 08             	sub    $0x8,%esp
8010488d:	68 1d 6f 10 80       	push   $0x80106f1d
80104892:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104895:	50                   	push   %eax
80104896:	e8 00 d1 ff ff       	call   8010199b <namecmp>
8010489b:	83 c4 10             	add    $0x10,%esp
8010489e:	85 c0                	test   %eax,%eax
801048a0:	0f 84 e0 00 00 00    	je     80104986 <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
801048a6:	83 ec 04             	sub    $0x4,%esp
801048a9:	8d 45 c0             	lea    -0x40(%ebp),%eax
801048ac:	50                   	push   %eax
801048ad:	8d 45 ca             	lea    -0x36(%ebp),%eax
801048b0:	50                   	push   %eax
801048b1:	56                   	push   %esi
801048b2:	e8 f9 d0 ff ff       	call   801019b0 <dirlookup>
801048b7:	89 c3                	mov    %eax,%ebx
801048b9:	83 c4 10             	add    $0x10,%esp
801048bc:	85 c0                	test   %eax,%eax
801048be:	0f 84 c2 00 00 00    	je     80104986 <sys_unlink+0x161>
  ilock(ip);
801048c4:	83 ec 0c             	sub    $0xc,%esp
801048c7:	50                   	push   %eax
801048c8:	e8 b4 cc ff ff       	call   80101581 <ilock>
  if(ip->nlink < 1)
801048cd:	83 c4 10             	add    $0x10,%esp
801048d0:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801048d5:	0f 8e 83 00 00 00    	jle    8010495e <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
801048db:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801048e0:	0f 84 85 00 00 00    	je     8010496b <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
801048e6:	83 ec 04             	sub    $0x4,%esp
801048e9:	6a 10                	push   $0x10
801048eb:	6a 00                	push   $0x0
801048ed:	8d 7d d8             	lea    -0x28(%ebp),%edi
801048f0:	57                   	push   %edi
801048f1:	e8 3f f6 ff ff       	call   80103f35 <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801048f6:	6a 10                	push   $0x10
801048f8:	ff 75 c0             	pushl  -0x40(%ebp)
801048fb:	57                   	push   %edi
801048fc:	56                   	push   %esi
801048fd:	e8 6e cf ff ff       	call   80101870 <writei>
80104902:	83 c4 20             	add    $0x20,%esp
80104905:	83 f8 10             	cmp    $0x10,%eax
80104908:	0f 85 90 00 00 00    	jne    8010499e <sys_unlink+0x179>
  if(ip->type == T_DIR){
8010490e:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104913:	0f 84 92 00 00 00    	je     801049ab <sys_unlink+0x186>
  iunlockput(dp);
80104919:	83 ec 0c             	sub    $0xc,%esp
8010491c:	56                   	push   %esi
8010491d:	e8 06 ce ff ff       	call   80101728 <iunlockput>
  ip->nlink--;
80104922:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104926:	83 e8 01             	sub    $0x1,%eax
80104929:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
8010492d:	89 1c 24             	mov    %ebx,(%esp)
80104930:	e8 eb ca ff ff       	call   80101420 <iupdate>
  iunlockput(ip);
80104935:	89 1c 24             	mov    %ebx,(%esp)
80104938:	e8 eb cd ff ff       	call   80101728 <iunlockput>
  end_op();
8010493d:	e8 cf e1 ff ff       	call   80102b11 <end_op>
  return 0;
80104942:	83 c4 10             	add    $0x10,%esp
80104945:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010494a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010494d:	5b                   	pop    %ebx
8010494e:	5e                   	pop    %esi
8010494f:	5f                   	pop    %edi
80104950:	5d                   	pop    %ebp
80104951:	c3                   	ret    
    end_op();
80104952:	e8 ba e1 ff ff       	call   80102b11 <end_op>
    return -1;
80104957:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010495c:	eb ec                	jmp    8010494a <sys_unlink+0x125>
    panic("unlink: nlink < 1");
8010495e:	83 ec 0c             	sub    $0xc,%esp
80104961:	68 3c 6f 10 80       	push   $0x80106f3c
80104966:	e8 dd b9 ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
8010496b:	89 d8                	mov    %ebx,%eax
8010496d:	e8 c4 f9 ff ff       	call   80104336 <isdirempty>
80104972:	85 c0                	test   %eax,%eax
80104974:	0f 85 6c ff ff ff    	jne    801048e6 <sys_unlink+0xc1>
    iunlockput(ip);
8010497a:	83 ec 0c             	sub    $0xc,%esp
8010497d:	53                   	push   %ebx
8010497e:	e8 a5 cd ff ff       	call   80101728 <iunlockput>
    goto bad;
80104983:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
80104986:	83 ec 0c             	sub    $0xc,%esp
80104989:	56                   	push   %esi
8010498a:	e8 99 cd ff ff       	call   80101728 <iunlockput>
  end_op();
8010498f:	e8 7d e1 ff ff       	call   80102b11 <end_op>
  return -1;
80104994:	83 c4 10             	add    $0x10,%esp
80104997:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010499c:	eb ac                	jmp    8010494a <sys_unlink+0x125>
    panic("unlink: writei");
8010499e:	83 ec 0c             	sub    $0xc,%esp
801049a1:	68 4e 6f 10 80       	push   $0x80106f4e
801049a6:	e8 9d b9 ff ff       	call   80100348 <panic>
    dp->nlink--;
801049ab:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801049af:	83 e8 01             	sub    $0x1,%eax
801049b2:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801049b6:	83 ec 0c             	sub    $0xc,%esp
801049b9:	56                   	push   %esi
801049ba:	e8 61 ca ff ff       	call   80101420 <iupdate>
801049bf:	83 c4 10             	add    $0x10,%esp
801049c2:	e9 52 ff ff ff       	jmp    80104919 <sys_unlink+0xf4>
    return -1;
801049c7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049cc:	e9 79 ff ff ff       	jmp    8010494a <sys_unlink+0x125>

801049d1 <sys_open>:

int
sys_open(void)
{
801049d1:	55                   	push   %ebp
801049d2:	89 e5                	mov    %esp,%ebp
801049d4:	57                   	push   %edi
801049d5:	56                   	push   %esi
801049d6:	53                   	push   %ebx
801049d7:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801049da:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801049dd:	50                   	push   %eax
801049de:	6a 00                	push   $0x0
801049e0:	e8 2b f8 ff ff       	call   80104210 <argstr>
801049e5:	83 c4 10             	add    $0x10,%esp
801049e8:	85 c0                	test   %eax,%eax
801049ea:	0f 88 30 01 00 00    	js     80104b20 <sys_open+0x14f>
801049f0:	83 ec 08             	sub    $0x8,%esp
801049f3:	8d 45 e0             	lea    -0x20(%ebp),%eax
801049f6:	50                   	push   %eax
801049f7:	6a 01                	push   $0x1
801049f9:	e8 82 f7 ff ff       	call   80104180 <argint>
801049fe:	83 c4 10             	add    $0x10,%esp
80104a01:	85 c0                	test   %eax,%eax
80104a03:	0f 88 21 01 00 00    	js     80104b2a <sys_open+0x159>
    return -1;

  begin_op();
80104a09:	e8 89 e0 ff ff       	call   80102a97 <begin_op>

  if(omode & O_CREATE){
80104a0e:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
80104a12:	0f 84 84 00 00 00    	je     80104a9c <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
80104a18:	83 ec 0c             	sub    $0xc,%esp
80104a1b:	6a 00                	push   $0x0
80104a1d:	b9 00 00 00 00       	mov    $0x0,%ecx
80104a22:	ba 02 00 00 00       	mov    $0x2,%edx
80104a27:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104a2a:	e8 5e f9 ff ff       	call   8010438d <create>
80104a2f:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104a31:	83 c4 10             	add    $0x10,%esp
80104a34:	85 c0                	test   %eax,%eax
80104a36:	74 58                	je     80104a90 <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80104a38:	e8 f0 c1 ff ff       	call   80100c2d <filealloc>
80104a3d:	89 c3                	mov    %eax,%ebx
80104a3f:	85 c0                	test   %eax,%eax
80104a41:	0f 84 ae 00 00 00    	je     80104af5 <sys_open+0x124>
80104a47:	e8 b3 f8 ff ff       	call   801042ff <fdalloc>
80104a4c:	89 c7                	mov    %eax,%edi
80104a4e:	85 c0                	test   %eax,%eax
80104a50:	0f 88 9f 00 00 00    	js     80104af5 <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104a56:	83 ec 0c             	sub    $0xc,%esp
80104a59:	56                   	push   %esi
80104a5a:	e8 e4 cb ff ff       	call   80101643 <iunlock>
  end_op();
80104a5f:	e8 ad e0 ff ff       	call   80102b11 <end_op>

  f->type = FD_INODE;
80104a64:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
80104a6a:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104a6d:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
80104a74:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104a77:	83 c4 10             	add    $0x10,%esp
80104a7a:	a8 01                	test   $0x1,%al
80104a7c:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80104a80:	a8 03                	test   $0x3,%al
80104a82:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
80104a86:	89 f8                	mov    %edi,%eax
80104a88:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104a8b:	5b                   	pop    %ebx
80104a8c:	5e                   	pop    %esi
80104a8d:	5f                   	pop    %edi
80104a8e:	5d                   	pop    %ebp
80104a8f:	c3                   	ret    
      end_op();
80104a90:	e8 7c e0 ff ff       	call   80102b11 <end_op>
      return -1;
80104a95:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a9a:	eb ea                	jmp    80104a86 <sys_open+0xb5>
    if((ip = namei(path)) == 0){
80104a9c:	83 ec 0c             	sub    $0xc,%esp
80104a9f:	ff 75 e4             	pushl  -0x1c(%ebp)
80104aa2:	e8 3a d1 ff ff       	call   80101be1 <namei>
80104aa7:	89 c6                	mov    %eax,%esi
80104aa9:	83 c4 10             	add    $0x10,%esp
80104aac:	85 c0                	test   %eax,%eax
80104aae:	74 39                	je     80104ae9 <sys_open+0x118>
    ilock(ip);
80104ab0:	83 ec 0c             	sub    $0xc,%esp
80104ab3:	50                   	push   %eax
80104ab4:	e8 c8 ca ff ff       	call   80101581 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80104ab9:	83 c4 10             	add    $0x10,%esp
80104abc:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104ac1:	0f 85 71 ff ff ff    	jne    80104a38 <sys_open+0x67>
80104ac7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104acb:	0f 84 67 ff ff ff    	je     80104a38 <sys_open+0x67>
      iunlockput(ip);
80104ad1:	83 ec 0c             	sub    $0xc,%esp
80104ad4:	56                   	push   %esi
80104ad5:	e8 4e cc ff ff       	call   80101728 <iunlockput>
      end_op();
80104ada:	e8 32 e0 ff ff       	call   80102b11 <end_op>
      return -1;
80104adf:	83 c4 10             	add    $0x10,%esp
80104ae2:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104ae7:	eb 9d                	jmp    80104a86 <sys_open+0xb5>
      end_op();
80104ae9:	e8 23 e0 ff ff       	call   80102b11 <end_op>
      return -1;
80104aee:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104af3:	eb 91                	jmp    80104a86 <sys_open+0xb5>
    if(f)
80104af5:	85 db                	test   %ebx,%ebx
80104af7:	74 0c                	je     80104b05 <sys_open+0x134>
      fileclose(f);
80104af9:	83 ec 0c             	sub    $0xc,%esp
80104afc:	53                   	push   %ebx
80104afd:	e8 d1 c1 ff ff       	call   80100cd3 <fileclose>
80104b02:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104b05:	83 ec 0c             	sub    $0xc,%esp
80104b08:	56                   	push   %esi
80104b09:	e8 1a cc ff ff       	call   80101728 <iunlockput>
    end_op();
80104b0e:	e8 fe df ff ff       	call   80102b11 <end_op>
    return -1;
80104b13:	83 c4 10             	add    $0x10,%esp
80104b16:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104b1b:	e9 66 ff ff ff       	jmp    80104a86 <sys_open+0xb5>
    return -1;
80104b20:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104b25:	e9 5c ff ff ff       	jmp    80104a86 <sys_open+0xb5>
80104b2a:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104b2f:	e9 52 ff ff ff       	jmp    80104a86 <sys_open+0xb5>

80104b34 <sys_mkdir>:

int
sys_mkdir(void)
{
80104b34:	55                   	push   %ebp
80104b35:	89 e5                	mov    %esp,%ebp
80104b37:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104b3a:	e8 58 df ff ff       	call   80102a97 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104b3f:	83 ec 08             	sub    $0x8,%esp
80104b42:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b45:	50                   	push   %eax
80104b46:	6a 00                	push   $0x0
80104b48:	e8 c3 f6 ff ff       	call   80104210 <argstr>
80104b4d:	83 c4 10             	add    $0x10,%esp
80104b50:	85 c0                	test   %eax,%eax
80104b52:	78 36                	js     80104b8a <sys_mkdir+0x56>
80104b54:	83 ec 0c             	sub    $0xc,%esp
80104b57:	6a 00                	push   $0x0
80104b59:	b9 00 00 00 00       	mov    $0x0,%ecx
80104b5e:	ba 01 00 00 00       	mov    $0x1,%edx
80104b63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b66:	e8 22 f8 ff ff       	call   8010438d <create>
80104b6b:	83 c4 10             	add    $0x10,%esp
80104b6e:	85 c0                	test   %eax,%eax
80104b70:	74 18                	je     80104b8a <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104b72:	83 ec 0c             	sub    $0xc,%esp
80104b75:	50                   	push   %eax
80104b76:	e8 ad cb ff ff       	call   80101728 <iunlockput>
  end_op();
80104b7b:	e8 91 df ff ff       	call   80102b11 <end_op>
  return 0;
80104b80:	83 c4 10             	add    $0x10,%esp
80104b83:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104b88:	c9                   	leave  
80104b89:	c3                   	ret    
    end_op();
80104b8a:	e8 82 df ff ff       	call   80102b11 <end_op>
    return -1;
80104b8f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b94:	eb f2                	jmp    80104b88 <sys_mkdir+0x54>

80104b96 <sys_mknod>:

int
sys_mknod(void)
{
80104b96:	55                   	push   %ebp
80104b97:	89 e5                	mov    %esp,%ebp
80104b99:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104b9c:	e8 f6 de ff ff       	call   80102a97 <begin_op>
  if((argstr(0, &path)) < 0 ||
80104ba1:	83 ec 08             	sub    $0x8,%esp
80104ba4:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ba7:	50                   	push   %eax
80104ba8:	6a 00                	push   $0x0
80104baa:	e8 61 f6 ff ff       	call   80104210 <argstr>
80104baf:	83 c4 10             	add    $0x10,%esp
80104bb2:	85 c0                	test   %eax,%eax
80104bb4:	78 62                	js     80104c18 <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104bb6:	83 ec 08             	sub    $0x8,%esp
80104bb9:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104bbc:	50                   	push   %eax
80104bbd:	6a 01                	push   $0x1
80104bbf:	e8 bc f5 ff ff       	call   80104180 <argint>
  if((argstr(0, &path)) < 0 ||
80104bc4:	83 c4 10             	add    $0x10,%esp
80104bc7:	85 c0                	test   %eax,%eax
80104bc9:	78 4d                	js     80104c18 <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104bcb:	83 ec 08             	sub    $0x8,%esp
80104bce:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104bd1:	50                   	push   %eax
80104bd2:	6a 02                	push   $0x2
80104bd4:	e8 a7 f5 ff ff       	call   80104180 <argint>
     argint(1, &major) < 0 ||
80104bd9:	83 c4 10             	add    $0x10,%esp
80104bdc:	85 c0                	test   %eax,%eax
80104bde:	78 38                	js     80104c18 <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104be0:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104be4:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104be8:	83 ec 0c             	sub    $0xc,%esp
80104beb:	50                   	push   %eax
80104bec:	ba 03 00 00 00       	mov    $0x3,%edx
80104bf1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bf4:	e8 94 f7 ff ff       	call   8010438d <create>
80104bf9:	83 c4 10             	add    $0x10,%esp
80104bfc:	85 c0                	test   %eax,%eax
80104bfe:	74 18                	je     80104c18 <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104c00:	83 ec 0c             	sub    $0xc,%esp
80104c03:	50                   	push   %eax
80104c04:	e8 1f cb ff ff       	call   80101728 <iunlockput>
  end_op();
80104c09:	e8 03 df ff ff       	call   80102b11 <end_op>
  return 0;
80104c0e:	83 c4 10             	add    $0x10,%esp
80104c11:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104c16:	c9                   	leave  
80104c17:	c3                   	ret    
    end_op();
80104c18:	e8 f4 de ff ff       	call   80102b11 <end_op>
    return -1;
80104c1d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c22:	eb f2                	jmp    80104c16 <sys_mknod+0x80>

80104c24 <sys_chdir>:

int
sys_chdir(void)
{
80104c24:	55                   	push   %ebp
80104c25:	89 e5                	mov    %esp,%ebp
80104c27:	56                   	push   %esi
80104c28:	53                   	push   %ebx
80104c29:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104c2c:	e8 b6 e8 ff ff       	call   801034e7 <myproc>
80104c31:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104c33:	e8 5f de ff ff       	call   80102a97 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104c38:	83 ec 08             	sub    $0x8,%esp
80104c3b:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c3e:	50                   	push   %eax
80104c3f:	6a 00                	push   $0x0
80104c41:	e8 ca f5 ff ff       	call   80104210 <argstr>
80104c46:	83 c4 10             	add    $0x10,%esp
80104c49:	85 c0                	test   %eax,%eax
80104c4b:	78 52                	js     80104c9f <sys_chdir+0x7b>
80104c4d:	83 ec 0c             	sub    $0xc,%esp
80104c50:	ff 75 f4             	pushl  -0xc(%ebp)
80104c53:	e8 89 cf ff ff       	call   80101be1 <namei>
80104c58:	89 c3                	mov    %eax,%ebx
80104c5a:	83 c4 10             	add    $0x10,%esp
80104c5d:	85 c0                	test   %eax,%eax
80104c5f:	74 3e                	je     80104c9f <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104c61:	83 ec 0c             	sub    $0xc,%esp
80104c64:	50                   	push   %eax
80104c65:	e8 17 c9 ff ff       	call   80101581 <ilock>
  if(ip->type != T_DIR){
80104c6a:	83 c4 10             	add    $0x10,%esp
80104c6d:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104c72:	75 37                	jne    80104cab <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104c74:	83 ec 0c             	sub    $0xc,%esp
80104c77:	53                   	push   %ebx
80104c78:	e8 c6 c9 ff ff       	call   80101643 <iunlock>
  iput(curproc->cwd);
80104c7d:	83 c4 04             	add    $0x4,%esp
80104c80:	ff 76 68             	pushl  0x68(%esi)
80104c83:	e8 00 ca ff ff       	call   80101688 <iput>
  end_op();
80104c88:	e8 84 de ff ff       	call   80102b11 <end_op>
  curproc->cwd = ip;
80104c8d:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104c90:	83 c4 10             	add    $0x10,%esp
80104c93:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104c98:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104c9b:	5b                   	pop    %ebx
80104c9c:	5e                   	pop    %esi
80104c9d:	5d                   	pop    %ebp
80104c9e:	c3                   	ret    
    end_op();
80104c9f:	e8 6d de ff ff       	call   80102b11 <end_op>
    return -1;
80104ca4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ca9:	eb ed                	jmp    80104c98 <sys_chdir+0x74>
    iunlockput(ip);
80104cab:	83 ec 0c             	sub    $0xc,%esp
80104cae:	53                   	push   %ebx
80104caf:	e8 74 ca ff ff       	call   80101728 <iunlockput>
    end_op();
80104cb4:	e8 58 de ff ff       	call   80102b11 <end_op>
    return -1;
80104cb9:	83 c4 10             	add    $0x10,%esp
80104cbc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cc1:	eb d5                	jmp    80104c98 <sys_chdir+0x74>

80104cc3 <sys_exec>:

int
sys_exec(void)
{
80104cc3:	55                   	push   %ebp
80104cc4:	89 e5                	mov    %esp,%ebp
80104cc6:	53                   	push   %ebx
80104cc7:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104ccd:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104cd0:	50                   	push   %eax
80104cd1:	6a 00                	push   $0x0
80104cd3:	e8 38 f5 ff ff       	call   80104210 <argstr>
80104cd8:	83 c4 10             	add    $0x10,%esp
80104cdb:	85 c0                	test   %eax,%eax
80104cdd:	0f 88 a8 00 00 00    	js     80104d8b <sys_exec+0xc8>
80104ce3:	83 ec 08             	sub    $0x8,%esp
80104ce6:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104cec:	50                   	push   %eax
80104ced:	6a 01                	push   $0x1
80104cef:	e8 8c f4 ff ff       	call   80104180 <argint>
80104cf4:	83 c4 10             	add    $0x10,%esp
80104cf7:	85 c0                	test   %eax,%eax
80104cf9:	0f 88 93 00 00 00    	js     80104d92 <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104cff:	83 ec 04             	sub    $0x4,%esp
80104d02:	68 80 00 00 00       	push   $0x80
80104d07:	6a 00                	push   $0x0
80104d09:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104d0f:	50                   	push   %eax
80104d10:	e8 20 f2 ff ff       	call   80103f35 <memset>
80104d15:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104d18:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104d1d:	83 fb 1f             	cmp    $0x1f,%ebx
80104d20:	77 77                	ja     80104d99 <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104d22:	83 ec 08             	sub    $0x8,%esp
80104d25:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104d2b:	50                   	push   %eax
80104d2c:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104d32:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104d35:	50                   	push   %eax
80104d36:	e8 c9 f3 ff ff       	call   80104104 <fetchint>
80104d3b:	83 c4 10             	add    $0x10,%esp
80104d3e:	85 c0                	test   %eax,%eax
80104d40:	78 5e                	js     80104da0 <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104d42:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104d48:	85 c0                	test   %eax,%eax
80104d4a:	74 1d                	je     80104d69 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104d4c:	83 ec 08             	sub    $0x8,%esp
80104d4f:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104d56:	52                   	push   %edx
80104d57:	50                   	push   %eax
80104d58:	e8 e3 f3 ff ff       	call   80104140 <fetchstr>
80104d5d:	83 c4 10             	add    $0x10,%esp
80104d60:	85 c0                	test   %eax,%eax
80104d62:	78 46                	js     80104daa <sys_exec+0xe7>
  for(i=0;; i++){
80104d64:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104d67:	eb b4                	jmp    80104d1d <sys_exec+0x5a>
      argv[i] = 0;
80104d69:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104d70:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104d74:	83 ec 08             	sub    $0x8,%esp
80104d77:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104d7d:	50                   	push   %eax
80104d7e:	ff 75 f4             	pushl  -0xc(%ebp)
80104d81:	e8 4c bb ff ff       	call   801008d2 <exec>
80104d86:	83 c4 10             	add    $0x10,%esp
80104d89:	eb 1a                	jmp    80104da5 <sys_exec+0xe2>
    return -1;
80104d8b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d90:	eb 13                	jmp    80104da5 <sys_exec+0xe2>
80104d92:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d97:	eb 0c                	jmp    80104da5 <sys_exec+0xe2>
      return -1;
80104d99:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d9e:	eb 05                	jmp    80104da5 <sys_exec+0xe2>
      return -1;
80104da0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104da5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104da8:	c9                   	leave  
80104da9:	c3                   	ret    
      return -1;
80104daa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104daf:	eb f4                	jmp    80104da5 <sys_exec+0xe2>

80104db1 <sys_pipe>:

int
sys_pipe(void)
{
80104db1:	55                   	push   %ebp
80104db2:	89 e5                	mov    %esp,%ebp
80104db4:	53                   	push   %ebx
80104db5:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104db8:	6a 08                	push   $0x8
80104dba:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104dbd:	50                   	push   %eax
80104dbe:	6a 00                	push   $0x0
80104dc0:	e8 e3 f3 ff ff       	call   801041a8 <argptr>
80104dc5:	83 c4 10             	add    $0x10,%esp
80104dc8:	85 c0                	test   %eax,%eax
80104dca:	78 77                	js     80104e43 <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104dcc:	83 ec 08             	sub    $0x8,%esp
80104dcf:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104dd2:	50                   	push   %eax
80104dd3:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104dd6:	50                   	push   %eax
80104dd7:	e8 42 e2 ff ff       	call   8010301e <pipealloc>
80104ddc:	83 c4 10             	add    $0x10,%esp
80104ddf:	85 c0                	test   %eax,%eax
80104de1:	78 67                	js     80104e4a <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104de3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104de6:	e8 14 f5 ff ff       	call   801042ff <fdalloc>
80104deb:	89 c3                	mov    %eax,%ebx
80104ded:	85 c0                	test   %eax,%eax
80104def:	78 21                	js     80104e12 <sys_pipe+0x61>
80104df1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104df4:	e8 06 f5 ff ff       	call   801042ff <fdalloc>
80104df9:	85 c0                	test   %eax,%eax
80104dfb:	78 15                	js     80104e12 <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104dfd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e00:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104e02:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e05:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104e08:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e0d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e10:	c9                   	leave  
80104e11:	c3                   	ret    
    if(fd0 >= 0)
80104e12:	85 db                	test   %ebx,%ebx
80104e14:	78 0d                	js     80104e23 <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104e16:	e8 cc e6 ff ff       	call   801034e7 <myproc>
80104e1b:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104e22:	00 
    fileclose(rf);
80104e23:	83 ec 0c             	sub    $0xc,%esp
80104e26:	ff 75 f0             	pushl  -0x10(%ebp)
80104e29:	e8 a5 be ff ff       	call   80100cd3 <fileclose>
    fileclose(wf);
80104e2e:	83 c4 04             	add    $0x4,%esp
80104e31:	ff 75 ec             	pushl  -0x14(%ebp)
80104e34:	e8 9a be ff ff       	call   80100cd3 <fileclose>
    return -1;
80104e39:	83 c4 10             	add    $0x10,%esp
80104e3c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e41:	eb ca                	jmp    80104e0d <sys_pipe+0x5c>
    return -1;
80104e43:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e48:	eb c3                	jmp    80104e0d <sys_pipe+0x5c>
    return -1;
80104e4a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e4f:	eb bc                	jmp    80104e0d <sys_pipe+0x5c>

80104e51 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104e51:	55                   	push   %ebp
80104e52:	89 e5                	mov    %esp,%ebp
80104e54:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104e57:	e8 03 e8 ff ff       	call   8010365f <fork>
}
80104e5c:	c9                   	leave  
80104e5d:	c3                   	ret    

80104e5e <sys_exit>:

int
sys_exit(void)
{
80104e5e:	55                   	push   %ebp
80104e5f:	89 e5                	mov    %esp,%ebp
80104e61:	83 ec 08             	sub    $0x8,%esp
  exit();
80104e64:	e8 2d ea ff ff       	call   80103896 <exit>
  return 0;  // not reached
}
80104e69:	b8 00 00 00 00       	mov    $0x0,%eax
80104e6e:	c9                   	leave  
80104e6f:	c3                   	ret    

80104e70 <sys_wait>:

int
sys_wait(void)
{
80104e70:	55                   	push   %ebp
80104e71:	89 e5                	mov    %esp,%ebp
80104e73:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104e76:	e8 a4 eb ff ff       	call   80103a1f <wait>
}
80104e7b:	c9                   	leave  
80104e7c:	c3                   	ret    

80104e7d <sys_kill>:

int
sys_kill(void)
{
80104e7d:	55                   	push   %ebp
80104e7e:	89 e5                	mov    %esp,%ebp
80104e80:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104e83:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e86:	50                   	push   %eax
80104e87:	6a 00                	push   $0x0
80104e89:	e8 f2 f2 ff ff       	call   80104180 <argint>
80104e8e:	83 c4 10             	add    $0x10,%esp
80104e91:	85 c0                	test   %eax,%eax
80104e93:	78 10                	js     80104ea5 <sys_kill+0x28>
    return -1;
  return kill(pid);
80104e95:	83 ec 0c             	sub    $0xc,%esp
80104e98:	ff 75 f4             	pushl  -0xc(%ebp)
80104e9b:	e8 7c ec ff ff       	call   80103b1c <kill>
80104ea0:	83 c4 10             	add    $0x10,%esp
}
80104ea3:	c9                   	leave  
80104ea4:	c3                   	ret    
    return -1;
80104ea5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104eaa:	eb f7                	jmp    80104ea3 <sys_kill+0x26>

80104eac <sys_getpid>:

int
sys_getpid(void)
{
80104eac:	55                   	push   %ebp
80104ead:	89 e5                	mov    %esp,%ebp
80104eaf:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104eb2:	e8 30 e6 ff ff       	call   801034e7 <myproc>
80104eb7:	8b 40 10             	mov    0x10(%eax),%eax
}
80104eba:	c9                   	leave  
80104ebb:	c3                   	ret    

80104ebc <sys_sbrk>:

int
sys_sbrk(void)
{
80104ebc:	55                   	push   %ebp
80104ebd:	89 e5                	mov    %esp,%ebp
80104ebf:	53                   	push   %ebx
80104ec0:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104ec3:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ec6:	50                   	push   %eax
80104ec7:	6a 00                	push   $0x0
80104ec9:	e8 b2 f2 ff ff       	call   80104180 <argint>
80104ece:	83 c4 10             	add    $0x10,%esp
80104ed1:	85 c0                	test   %eax,%eax
80104ed3:	78 27                	js     80104efc <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104ed5:	e8 0d e6 ff ff       	call   801034e7 <myproc>
80104eda:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104edc:	83 ec 0c             	sub    $0xc,%esp
80104edf:	ff 75 f4             	pushl  -0xc(%ebp)
80104ee2:	e8 0b e7 ff ff       	call   801035f2 <growproc>
80104ee7:	83 c4 10             	add    $0x10,%esp
80104eea:	85 c0                	test   %eax,%eax
80104eec:	78 07                	js     80104ef5 <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104eee:	89 d8                	mov    %ebx,%eax
80104ef0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104ef3:	c9                   	leave  
80104ef4:	c3                   	ret    
    return -1;
80104ef5:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104efa:	eb f2                	jmp    80104eee <sys_sbrk+0x32>
    return -1;
80104efc:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104f01:	eb eb                	jmp    80104eee <sys_sbrk+0x32>

80104f03 <sys_sleep>:

int
sys_sleep(void)
{
80104f03:	55                   	push   %ebp
80104f04:	89 e5                	mov    %esp,%ebp
80104f06:	53                   	push   %ebx
80104f07:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104f0a:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104f0d:	50                   	push   %eax
80104f0e:	6a 00                	push   $0x0
80104f10:	e8 6b f2 ff ff       	call   80104180 <argint>
80104f15:	83 c4 10             	add    $0x10,%esp
80104f18:	85 c0                	test   %eax,%eax
80104f1a:	78 75                	js     80104f91 <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104f1c:	83 ec 0c             	sub    $0xc,%esp
80104f1f:	68 a0 4c 13 80       	push   $0x80134ca0
80104f24:	e8 60 ef ff ff       	call   80103e89 <acquire>
  ticks0 = ticks;
80104f29:	8b 1d e0 54 13 80    	mov    0x801354e0,%ebx
  while(ticks - ticks0 < n){
80104f2f:	83 c4 10             	add    $0x10,%esp
80104f32:	a1 e0 54 13 80       	mov    0x801354e0,%eax
80104f37:	29 d8                	sub    %ebx,%eax
80104f39:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104f3c:	73 39                	jae    80104f77 <sys_sleep+0x74>
    if(myproc()->killed){
80104f3e:	e8 a4 e5 ff ff       	call   801034e7 <myproc>
80104f43:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f47:	75 17                	jne    80104f60 <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104f49:	83 ec 08             	sub    $0x8,%esp
80104f4c:	68 a0 4c 13 80       	push   $0x80134ca0
80104f51:	68 e0 54 13 80       	push   $0x801354e0
80104f56:	e8 33 ea ff ff       	call   8010398e <sleep>
80104f5b:	83 c4 10             	add    $0x10,%esp
80104f5e:	eb d2                	jmp    80104f32 <sys_sleep+0x2f>
      release(&tickslock);
80104f60:	83 ec 0c             	sub    $0xc,%esp
80104f63:	68 a0 4c 13 80       	push   $0x80134ca0
80104f68:	e8 81 ef ff ff       	call   80103eee <release>
      return -1;
80104f6d:	83 c4 10             	add    $0x10,%esp
80104f70:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f75:	eb 15                	jmp    80104f8c <sys_sleep+0x89>
  }
  release(&tickslock);
80104f77:	83 ec 0c             	sub    $0xc,%esp
80104f7a:	68 a0 4c 13 80       	push   $0x80134ca0
80104f7f:	e8 6a ef ff ff       	call   80103eee <release>
  return 0;
80104f84:	83 c4 10             	add    $0x10,%esp
80104f87:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104f8c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104f8f:	c9                   	leave  
80104f90:	c3                   	ret    
    return -1;
80104f91:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104f96:	eb f4                	jmp    80104f8c <sys_sleep+0x89>

80104f98 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104f98:	55                   	push   %ebp
80104f99:	89 e5                	mov    %esp,%ebp
80104f9b:	53                   	push   %ebx
80104f9c:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104f9f:	68 a0 4c 13 80       	push   $0x80134ca0
80104fa4:	e8 e0 ee ff ff       	call   80103e89 <acquire>
  xticks = ticks;
80104fa9:	8b 1d e0 54 13 80    	mov    0x801354e0,%ebx
  release(&tickslock);
80104faf:	c7 04 24 a0 4c 13 80 	movl   $0x80134ca0,(%esp)
80104fb6:	e8 33 ef ff ff       	call   80103eee <release>
  return xticks;
}
80104fbb:	89 d8                	mov    %ebx,%eax
80104fbd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104fc0:	c9                   	leave  
80104fc1:	c3                   	ret    

80104fc2 <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80104fc2:	55                   	push   %ebp
80104fc3:	89 e5                	mov    %esp,%ebp
80104fc5:	83 ec 1c             	sub    $0x1c,%esp
  int *frames;
  int *pids;
  int numframes;
  if(argptr(0, (char**)(&frames), sizeof(*frames)) < 0)
80104fc8:	6a 04                	push   $0x4
80104fca:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104fcd:	50                   	push   %eax
80104fce:	6a 00                	push   $0x0
80104fd0:	e8 d3 f1 ff ff       	call   801041a8 <argptr>
80104fd5:	83 c4 10             	add    $0x10,%esp
80104fd8:	85 c0                	test   %eax,%eax
80104fda:	78 42                	js     8010501e <sys_dump_physmem+0x5c>
    return -1;
  if(argptr(1, (char**)(&pids), sizeof(*pids)) < 0)
80104fdc:	83 ec 04             	sub    $0x4,%esp
80104fdf:	6a 04                	push   $0x4
80104fe1:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104fe4:	50                   	push   %eax
80104fe5:	6a 01                	push   $0x1
80104fe7:	e8 bc f1 ff ff       	call   801041a8 <argptr>
80104fec:	83 c4 10             	add    $0x10,%esp
80104fef:	85 c0                	test   %eax,%eax
80104ff1:	78 32                	js     80105025 <sys_dump_physmem+0x63>
    return -1;
  if(argint(2, &numframes) < 0)
80104ff3:	83 ec 08             	sub    $0x8,%esp
80104ff6:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104ff9:	50                   	push   %eax
80104ffa:	6a 02                	push   $0x2
80104ffc:	e8 7f f1 ff ff       	call   80104180 <argint>
80105001:	83 c4 10             	add    $0x10,%esp
80105004:	85 c0                	test   %eax,%eax
80105006:	78 24                	js     8010502c <sys_dump_physmem+0x6a>
    return -1;

  return dump_physmem(frames, pids, numframes);
80105008:	83 ec 04             	sub    $0x4,%esp
8010500b:	ff 75 ec             	pushl  -0x14(%ebp)
8010500e:	ff 75 f0             	pushl  -0x10(%ebp)
80105011:	ff 75 f4             	pushl  -0xc(%ebp)
80105014:	e8 7e d3 ff ff       	call   80102397 <dump_physmem>
80105019:	83 c4 10             	add    $0x10,%esp
8010501c:	c9                   	leave  
8010501d:	c3                   	ret    
    return -1;
8010501e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105023:	eb f7                	jmp    8010501c <sys_dump_physmem+0x5a>
    return -1;
80105025:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010502a:	eb f0                	jmp    8010501c <sys_dump_physmem+0x5a>
    return -1;
8010502c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105031:	eb e9                	jmp    8010501c <sys_dump_physmem+0x5a>

80105033 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80105033:	1e                   	push   %ds
  pushl %es
80105034:	06                   	push   %es
  pushl %fs
80105035:	0f a0                	push   %fs
  pushl %gs
80105037:	0f a8                	push   %gs
  pushal
80105039:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
8010503a:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
8010503e:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80105040:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80105042:	54                   	push   %esp
  call trap
80105043:	e8 e3 00 00 00       	call   8010512b <trap>
  addl $4, %esp
80105048:	83 c4 04             	add    $0x4,%esp

8010504b <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
8010504b:	61                   	popa   
  popl %gs
8010504c:	0f a9                	pop    %gs
  popl %fs
8010504e:	0f a1                	pop    %fs
  popl %es
80105050:	07                   	pop    %es
  popl %ds
80105051:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80105052:	83 c4 08             	add    $0x8,%esp
  iret
80105055:	cf                   	iret   

80105056 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80105056:	55                   	push   %ebp
80105057:	89 e5                	mov    %esp,%ebp
80105059:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
8010505c:	b8 00 00 00 00       	mov    $0x0,%eax
80105061:	eb 4a                	jmp    801050ad <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80105063:	8b 0c 85 08 a0 12 80 	mov    -0x7fed5ff8(,%eax,4),%ecx
8010506a:	66 89 0c c5 e0 4c 13 	mov    %cx,-0x7fecb320(,%eax,8)
80105071:	80 
80105072:	66 c7 04 c5 e2 4c 13 	movw   $0x8,-0x7fecb31e(,%eax,8)
80105079:	80 08 00 
8010507c:	c6 04 c5 e4 4c 13 80 	movb   $0x0,-0x7fecb31c(,%eax,8)
80105083:	00 
80105084:	0f b6 14 c5 e5 4c 13 	movzbl -0x7fecb31b(,%eax,8),%edx
8010508b:	80 
8010508c:	83 e2 f0             	and    $0xfffffff0,%edx
8010508f:	83 ca 0e             	or     $0xe,%edx
80105092:	83 e2 8f             	and    $0xffffff8f,%edx
80105095:	83 ca 80             	or     $0xffffff80,%edx
80105098:	88 14 c5 e5 4c 13 80 	mov    %dl,-0x7fecb31b(,%eax,8)
8010509f:	c1 e9 10             	shr    $0x10,%ecx
801050a2:	66 89 0c c5 e6 4c 13 	mov    %cx,-0x7fecb31a(,%eax,8)
801050a9:	80 
  for(i = 0; i < 256; i++)
801050aa:	83 c0 01             	add    $0x1,%eax
801050ad:	3d ff 00 00 00       	cmp    $0xff,%eax
801050b2:	7e af                	jle    80105063 <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
801050b4:	8b 15 08 a1 12 80    	mov    0x8012a108,%edx
801050ba:	66 89 15 e0 4e 13 80 	mov    %dx,0x80134ee0
801050c1:	66 c7 05 e2 4e 13 80 	movw   $0x8,0x80134ee2
801050c8:	08 00 
801050ca:	c6 05 e4 4e 13 80 00 	movb   $0x0,0x80134ee4
801050d1:	0f b6 05 e5 4e 13 80 	movzbl 0x80134ee5,%eax
801050d8:	83 c8 0f             	or     $0xf,%eax
801050db:	83 e0 ef             	and    $0xffffffef,%eax
801050de:	83 c8 e0             	or     $0xffffffe0,%eax
801050e1:	a2 e5 4e 13 80       	mov    %al,0x80134ee5
801050e6:	c1 ea 10             	shr    $0x10,%edx
801050e9:	66 89 15 e6 4e 13 80 	mov    %dx,0x80134ee6

  initlock(&tickslock, "time");
801050f0:	83 ec 08             	sub    $0x8,%esp
801050f3:	68 5d 6f 10 80       	push   $0x80106f5d
801050f8:	68 a0 4c 13 80       	push   $0x80134ca0
801050fd:	e8 4b ec ff ff       	call   80103d4d <initlock>
}
80105102:	83 c4 10             	add    $0x10,%esp
80105105:	c9                   	leave  
80105106:	c3                   	ret    

80105107 <idtinit>:

void
idtinit(void)
{
80105107:	55                   	push   %ebp
80105108:	89 e5                	mov    %esp,%ebp
8010510a:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
8010510d:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80105113:	b8 e0 4c 13 80       	mov    $0x80134ce0,%eax
80105118:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010511c:	c1 e8 10             	shr    $0x10,%eax
8010511f:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
80105123:	8d 45 fa             	lea    -0x6(%ebp),%eax
80105126:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80105129:	c9                   	leave  
8010512a:	c3                   	ret    

8010512b <trap>:

void
trap(struct trapframe *tf)
{
8010512b:	55                   	push   %ebp
8010512c:	89 e5                	mov    %esp,%ebp
8010512e:	57                   	push   %edi
8010512f:	56                   	push   %esi
80105130:	53                   	push   %ebx
80105131:	83 ec 1c             	sub    $0x1c,%esp
80105134:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80105137:	8b 43 30             	mov    0x30(%ebx),%eax
8010513a:	83 f8 40             	cmp    $0x40,%eax
8010513d:	74 13                	je     80105152 <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
8010513f:	83 e8 20             	sub    $0x20,%eax
80105142:	83 f8 1f             	cmp    $0x1f,%eax
80105145:	0f 87 3a 01 00 00    	ja     80105285 <trap+0x15a>
8010514b:	ff 24 85 04 70 10 80 	jmp    *-0x7fef8ffc(,%eax,4)
    if(myproc()->killed)
80105152:	e8 90 e3 ff ff       	call   801034e7 <myproc>
80105157:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010515b:	75 1f                	jne    8010517c <trap+0x51>
    myproc()->tf = tf;
8010515d:	e8 85 e3 ff ff       	call   801034e7 <myproc>
80105162:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80105165:	e8 d9 f0 ff ff       	call   80104243 <syscall>
    if(myproc()->killed)
8010516a:	e8 78 e3 ff ff       	call   801034e7 <myproc>
8010516f:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105173:	74 7e                	je     801051f3 <trap+0xc8>
      exit();
80105175:	e8 1c e7 ff ff       	call   80103896 <exit>
8010517a:	eb 77                	jmp    801051f3 <trap+0xc8>
      exit();
8010517c:	e8 15 e7 ff ff       	call   80103896 <exit>
80105181:	eb da                	jmp    8010515d <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80105183:	e8 44 e3 ff ff       	call   801034cc <cpuid>
80105188:	85 c0                	test   %eax,%eax
8010518a:	74 6f                	je     801051fb <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
8010518c:	e8 f1 d4 ff ff       	call   80102682 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105191:	e8 51 e3 ff ff       	call   801034e7 <myproc>
80105196:	85 c0                	test   %eax,%eax
80105198:	74 1c                	je     801051b6 <trap+0x8b>
8010519a:	e8 48 e3 ff ff       	call   801034e7 <myproc>
8010519f:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801051a3:	74 11                	je     801051b6 <trap+0x8b>
801051a5:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
801051a9:	83 e0 03             	and    $0x3,%eax
801051ac:	66 83 f8 03          	cmp    $0x3,%ax
801051b0:	0f 84 62 01 00 00    	je     80105318 <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
801051b6:	e8 2c e3 ff ff       	call   801034e7 <myproc>
801051bb:	85 c0                	test   %eax,%eax
801051bd:	74 0f                	je     801051ce <trap+0xa3>
801051bf:	e8 23 e3 ff ff       	call   801034e7 <myproc>
801051c4:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
801051c8:	0f 84 54 01 00 00    	je     80105322 <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
801051ce:	e8 14 e3 ff ff       	call   801034e7 <myproc>
801051d3:	85 c0                	test   %eax,%eax
801051d5:	74 1c                	je     801051f3 <trap+0xc8>
801051d7:	e8 0b e3 ff ff       	call   801034e7 <myproc>
801051dc:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801051e0:	74 11                	je     801051f3 <trap+0xc8>
801051e2:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
801051e6:	83 e0 03             	and    $0x3,%eax
801051e9:	66 83 f8 03          	cmp    $0x3,%ax
801051ed:	0f 84 43 01 00 00    	je     80105336 <trap+0x20b>
    exit();
}
801051f3:	8d 65 f4             	lea    -0xc(%ebp),%esp
801051f6:	5b                   	pop    %ebx
801051f7:	5e                   	pop    %esi
801051f8:	5f                   	pop    %edi
801051f9:	5d                   	pop    %ebp
801051fa:	c3                   	ret    
      acquire(&tickslock);
801051fb:	83 ec 0c             	sub    $0xc,%esp
801051fe:	68 a0 4c 13 80       	push   $0x80134ca0
80105203:	e8 81 ec ff ff       	call   80103e89 <acquire>
      ticks++;
80105208:	83 05 e0 54 13 80 01 	addl   $0x1,0x801354e0
      wakeup(&ticks);
8010520f:	c7 04 24 e0 54 13 80 	movl   $0x801354e0,(%esp)
80105216:	e8 d8 e8 ff ff       	call   80103af3 <wakeup>
      release(&tickslock);
8010521b:	c7 04 24 a0 4c 13 80 	movl   $0x80134ca0,(%esp)
80105222:	e8 c7 ec ff ff       	call   80103eee <release>
80105227:	83 c4 10             	add    $0x10,%esp
8010522a:	e9 5d ff ff ff       	jmp    8010518c <trap+0x61>
    ideintr();
8010522f:	e8 3f cb ff ff       	call   80101d73 <ideintr>
    lapiceoi();
80105234:	e8 49 d4 ff ff       	call   80102682 <lapiceoi>
    break;
80105239:	e9 53 ff ff ff       	jmp    80105191 <trap+0x66>
    kbdintr();
8010523e:	e8 83 d2 ff ff       	call   801024c6 <kbdintr>
    lapiceoi();
80105243:	e8 3a d4 ff ff       	call   80102682 <lapiceoi>
    break;
80105248:	e9 44 ff ff ff       	jmp    80105191 <trap+0x66>
    uartintr();
8010524d:	e8 05 02 00 00       	call   80105457 <uartintr>
    lapiceoi();
80105252:	e8 2b d4 ff ff       	call   80102682 <lapiceoi>
    break;
80105257:	e9 35 ff ff ff       	jmp    80105191 <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010525c:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
8010525f:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105263:	e8 64 e2 ff ff       	call   801034cc <cpuid>
80105268:	57                   	push   %edi
80105269:	0f b7 f6             	movzwl %si,%esi
8010526c:	56                   	push   %esi
8010526d:	50                   	push   %eax
8010526e:	68 68 6f 10 80       	push   $0x80106f68
80105273:	e8 93 b3 ff ff       	call   8010060b <cprintf>
    lapiceoi();
80105278:	e8 05 d4 ff ff       	call   80102682 <lapiceoi>
    break;
8010527d:	83 c4 10             	add    $0x10,%esp
80105280:	e9 0c ff ff ff       	jmp    80105191 <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
80105285:	e8 5d e2 ff ff       	call   801034e7 <myproc>
8010528a:	85 c0                	test   %eax,%eax
8010528c:	74 5f                	je     801052ed <trap+0x1c2>
8010528e:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
80105292:	74 59                	je     801052ed <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80105294:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105297:	8b 43 38             	mov    0x38(%ebx),%eax
8010529a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010529d:	e8 2a e2 ff ff       	call   801034cc <cpuid>
801052a2:	89 45 e0             	mov    %eax,-0x20(%ebp)
801052a5:	8b 53 34             	mov    0x34(%ebx),%edx
801052a8:	89 55 dc             	mov    %edx,-0x24(%ebp)
801052ab:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
801052ae:	e8 34 e2 ff ff       	call   801034e7 <myproc>
801052b3:	8d 48 6c             	lea    0x6c(%eax),%ecx
801052b6:	89 4d d8             	mov    %ecx,-0x28(%ebp)
801052b9:	e8 29 e2 ff ff       	call   801034e7 <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801052be:	57                   	push   %edi
801052bf:	ff 75 e4             	pushl  -0x1c(%ebp)
801052c2:	ff 75 e0             	pushl  -0x20(%ebp)
801052c5:	ff 75 dc             	pushl  -0x24(%ebp)
801052c8:	56                   	push   %esi
801052c9:	ff 75 d8             	pushl  -0x28(%ebp)
801052cc:	ff 70 10             	pushl  0x10(%eax)
801052cf:	68 c0 6f 10 80       	push   $0x80106fc0
801052d4:	e8 32 b3 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
801052d9:	83 c4 20             	add    $0x20,%esp
801052dc:	e8 06 e2 ff ff       	call   801034e7 <myproc>
801052e1:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801052e8:	e9 a4 fe ff ff       	jmp    80105191 <trap+0x66>
801052ed:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801052f0:	8b 73 38             	mov    0x38(%ebx),%esi
801052f3:	e8 d4 e1 ff ff       	call   801034cc <cpuid>
801052f8:	83 ec 0c             	sub    $0xc,%esp
801052fb:	57                   	push   %edi
801052fc:	56                   	push   %esi
801052fd:	50                   	push   %eax
801052fe:	ff 73 30             	pushl  0x30(%ebx)
80105301:	68 8c 6f 10 80       	push   $0x80106f8c
80105306:	e8 00 b3 ff ff       	call   8010060b <cprintf>
      panic("trap");
8010530b:	83 c4 14             	add    $0x14,%esp
8010530e:	68 62 6f 10 80       	push   $0x80106f62
80105313:	e8 30 b0 ff ff       	call   80100348 <panic>
    exit();
80105318:	e8 79 e5 ff ff       	call   80103896 <exit>
8010531d:	e9 94 fe ff ff       	jmp    801051b6 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
80105322:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
80105326:	0f 85 a2 fe ff ff    	jne    801051ce <trap+0xa3>
    yield();
8010532c:	e8 2b e6 ff ff       	call   8010395c <yield>
80105331:	e9 98 fe ff ff       	jmp    801051ce <trap+0xa3>
    exit();
80105336:	e8 5b e5 ff ff       	call   80103896 <exit>
8010533b:	e9 b3 fe ff ff       	jmp    801051f3 <trap+0xc8>

80105340 <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
80105340:	55                   	push   %ebp
80105341:	89 e5                	mov    %esp,%ebp
  if(!uart)
80105343:	83 3d c4 a5 12 80 00 	cmpl   $0x0,0x8012a5c4
8010534a:	74 15                	je     80105361 <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010534c:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105351:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
80105352:	a8 01                	test   $0x1,%al
80105354:	74 12                	je     80105368 <uartgetc+0x28>
80105356:	ba f8 03 00 00       	mov    $0x3f8,%edx
8010535b:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
8010535c:	0f b6 c0             	movzbl %al,%eax
}
8010535f:	5d                   	pop    %ebp
80105360:	c3                   	ret    
    return -1;
80105361:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105366:	eb f7                	jmp    8010535f <uartgetc+0x1f>
    return -1;
80105368:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010536d:	eb f0                	jmp    8010535f <uartgetc+0x1f>

8010536f <uartputc>:
  if(!uart)
8010536f:	83 3d c4 a5 12 80 00 	cmpl   $0x0,0x8012a5c4
80105376:	74 3b                	je     801053b3 <uartputc+0x44>
{
80105378:	55                   	push   %ebp
80105379:	89 e5                	mov    %esp,%ebp
8010537b:	53                   	push   %ebx
8010537c:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010537f:	bb 00 00 00 00       	mov    $0x0,%ebx
80105384:	eb 10                	jmp    80105396 <uartputc+0x27>
    microdelay(10);
80105386:	83 ec 0c             	sub    $0xc,%esp
80105389:	6a 0a                	push   $0xa
8010538b:	e8 11 d3 ff ff       	call   801026a1 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105390:	83 c3 01             	add    $0x1,%ebx
80105393:	83 c4 10             	add    $0x10,%esp
80105396:	83 fb 7f             	cmp    $0x7f,%ebx
80105399:	7f 0a                	jg     801053a5 <uartputc+0x36>
8010539b:	ba fd 03 00 00       	mov    $0x3fd,%edx
801053a0:	ec                   	in     (%dx),%al
801053a1:	a8 20                	test   $0x20,%al
801053a3:	74 e1                	je     80105386 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801053a5:	8b 45 08             	mov    0x8(%ebp),%eax
801053a8:	ba f8 03 00 00       	mov    $0x3f8,%edx
801053ad:	ee                   	out    %al,(%dx)
}
801053ae:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801053b1:	c9                   	leave  
801053b2:	c3                   	ret    
801053b3:	f3 c3                	repz ret 

801053b5 <uartinit>:
{
801053b5:	55                   	push   %ebp
801053b6:	89 e5                	mov    %esp,%ebp
801053b8:	56                   	push   %esi
801053b9:	53                   	push   %ebx
801053ba:	b9 00 00 00 00       	mov    $0x0,%ecx
801053bf:	ba fa 03 00 00       	mov    $0x3fa,%edx
801053c4:	89 c8                	mov    %ecx,%eax
801053c6:	ee                   	out    %al,(%dx)
801053c7:	be fb 03 00 00       	mov    $0x3fb,%esi
801053cc:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
801053d1:	89 f2                	mov    %esi,%edx
801053d3:	ee                   	out    %al,(%dx)
801053d4:	b8 0c 00 00 00       	mov    $0xc,%eax
801053d9:	ba f8 03 00 00       	mov    $0x3f8,%edx
801053de:	ee                   	out    %al,(%dx)
801053df:	bb f9 03 00 00       	mov    $0x3f9,%ebx
801053e4:	89 c8                	mov    %ecx,%eax
801053e6:	89 da                	mov    %ebx,%edx
801053e8:	ee                   	out    %al,(%dx)
801053e9:	b8 03 00 00 00       	mov    $0x3,%eax
801053ee:	89 f2                	mov    %esi,%edx
801053f0:	ee                   	out    %al,(%dx)
801053f1:	ba fc 03 00 00       	mov    $0x3fc,%edx
801053f6:	89 c8                	mov    %ecx,%eax
801053f8:	ee                   	out    %al,(%dx)
801053f9:	b8 01 00 00 00       	mov    $0x1,%eax
801053fe:	89 da                	mov    %ebx,%edx
80105400:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105401:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105406:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
80105407:	3c ff                	cmp    $0xff,%al
80105409:	74 45                	je     80105450 <uartinit+0x9b>
  uart = 1;
8010540b:	c7 05 c4 a5 12 80 01 	movl   $0x1,0x8012a5c4
80105412:	00 00 00 
80105415:	ba fa 03 00 00       	mov    $0x3fa,%edx
8010541a:	ec                   	in     (%dx),%al
8010541b:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105420:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
80105421:	83 ec 08             	sub    $0x8,%esp
80105424:	6a 00                	push   $0x0
80105426:	6a 04                	push   $0x4
80105428:	e8 51 cb ff ff       	call   80101f7e <ioapicenable>
  for(p="xv6...\n"; *p; p++)
8010542d:	83 c4 10             	add    $0x10,%esp
80105430:	bb 84 70 10 80       	mov    $0x80107084,%ebx
80105435:	eb 12                	jmp    80105449 <uartinit+0x94>
    uartputc(*p);
80105437:	83 ec 0c             	sub    $0xc,%esp
8010543a:	0f be c0             	movsbl %al,%eax
8010543d:	50                   	push   %eax
8010543e:	e8 2c ff ff ff       	call   8010536f <uartputc>
  for(p="xv6...\n"; *p; p++)
80105443:	83 c3 01             	add    $0x1,%ebx
80105446:	83 c4 10             	add    $0x10,%esp
80105449:	0f b6 03             	movzbl (%ebx),%eax
8010544c:	84 c0                	test   %al,%al
8010544e:	75 e7                	jne    80105437 <uartinit+0x82>
}
80105450:	8d 65 f8             	lea    -0x8(%ebp),%esp
80105453:	5b                   	pop    %ebx
80105454:	5e                   	pop    %esi
80105455:	5d                   	pop    %ebp
80105456:	c3                   	ret    

80105457 <uartintr>:

void
uartintr(void)
{
80105457:	55                   	push   %ebp
80105458:	89 e5                	mov    %esp,%ebp
8010545a:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
8010545d:	68 40 53 10 80       	push   $0x80105340
80105462:	e8 d7 b2 ff ff       	call   8010073e <consoleintr>
}
80105467:	83 c4 10             	add    $0x10,%esp
8010546a:	c9                   	leave  
8010546b:	c3                   	ret    

8010546c <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
8010546c:	6a 00                	push   $0x0
  pushl $0
8010546e:	6a 00                	push   $0x0
  jmp alltraps
80105470:	e9 be fb ff ff       	jmp    80105033 <alltraps>

80105475 <vector1>:
.globl vector1
vector1:
  pushl $0
80105475:	6a 00                	push   $0x0
  pushl $1
80105477:	6a 01                	push   $0x1
  jmp alltraps
80105479:	e9 b5 fb ff ff       	jmp    80105033 <alltraps>

8010547e <vector2>:
.globl vector2
vector2:
  pushl $0
8010547e:	6a 00                	push   $0x0
  pushl $2
80105480:	6a 02                	push   $0x2
  jmp alltraps
80105482:	e9 ac fb ff ff       	jmp    80105033 <alltraps>

80105487 <vector3>:
.globl vector3
vector3:
  pushl $0
80105487:	6a 00                	push   $0x0
  pushl $3
80105489:	6a 03                	push   $0x3
  jmp alltraps
8010548b:	e9 a3 fb ff ff       	jmp    80105033 <alltraps>

80105490 <vector4>:
.globl vector4
vector4:
  pushl $0
80105490:	6a 00                	push   $0x0
  pushl $4
80105492:	6a 04                	push   $0x4
  jmp alltraps
80105494:	e9 9a fb ff ff       	jmp    80105033 <alltraps>

80105499 <vector5>:
.globl vector5
vector5:
  pushl $0
80105499:	6a 00                	push   $0x0
  pushl $5
8010549b:	6a 05                	push   $0x5
  jmp alltraps
8010549d:	e9 91 fb ff ff       	jmp    80105033 <alltraps>

801054a2 <vector6>:
.globl vector6
vector6:
  pushl $0
801054a2:	6a 00                	push   $0x0
  pushl $6
801054a4:	6a 06                	push   $0x6
  jmp alltraps
801054a6:	e9 88 fb ff ff       	jmp    80105033 <alltraps>

801054ab <vector7>:
.globl vector7
vector7:
  pushl $0
801054ab:	6a 00                	push   $0x0
  pushl $7
801054ad:	6a 07                	push   $0x7
  jmp alltraps
801054af:	e9 7f fb ff ff       	jmp    80105033 <alltraps>

801054b4 <vector8>:
.globl vector8
vector8:
  pushl $8
801054b4:	6a 08                	push   $0x8
  jmp alltraps
801054b6:	e9 78 fb ff ff       	jmp    80105033 <alltraps>

801054bb <vector9>:
.globl vector9
vector9:
  pushl $0
801054bb:	6a 00                	push   $0x0
  pushl $9
801054bd:	6a 09                	push   $0x9
  jmp alltraps
801054bf:	e9 6f fb ff ff       	jmp    80105033 <alltraps>

801054c4 <vector10>:
.globl vector10
vector10:
  pushl $10
801054c4:	6a 0a                	push   $0xa
  jmp alltraps
801054c6:	e9 68 fb ff ff       	jmp    80105033 <alltraps>

801054cb <vector11>:
.globl vector11
vector11:
  pushl $11
801054cb:	6a 0b                	push   $0xb
  jmp alltraps
801054cd:	e9 61 fb ff ff       	jmp    80105033 <alltraps>

801054d2 <vector12>:
.globl vector12
vector12:
  pushl $12
801054d2:	6a 0c                	push   $0xc
  jmp alltraps
801054d4:	e9 5a fb ff ff       	jmp    80105033 <alltraps>

801054d9 <vector13>:
.globl vector13
vector13:
  pushl $13
801054d9:	6a 0d                	push   $0xd
  jmp alltraps
801054db:	e9 53 fb ff ff       	jmp    80105033 <alltraps>

801054e0 <vector14>:
.globl vector14
vector14:
  pushl $14
801054e0:	6a 0e                	push   $0xe
  jmp alltraps
801054e2:	e9 4c fb ff ff       	jmp    80105033 <alltraps>

801054e7 <vector15>:
.globl vector15
vector15:
  pushl $0
801054e7:	6a 00                	push   $0x0
  pushl $15
801054e9:	6a 0f                	push   $0xf
  jmp alltraps
801054eb:	e9 43 fb ff ff       	jmp    80105033 <alltraps>

801054f0 <vector16>:
.globl vector16
vector16:
  pushl $0
801054f0:	6a 00                	push   $0x0
  pushl $16
801054f2:	6a 10                	push   $0x10
  jmp alltraps
801054f4:	e9 3a fb ff ff       	jmp    80105033 <alltraps>

801054f9 <vector17>:
.globl vector17
vector17:
  pushl $17
801054f9:	6a 11                	push   $0x11
  jmp alltraps
801054fb:	e9 33 fb ff ff       	jmp    80105033 <alltraps>

80105500 <vector18>:
.globl vector18
vector18:
  pushl $0
80105500:	6a 00                	push   $0x0
  pushl $18
80105502:	6a 12                	push   $0x12
  jmp alltraps
80105504:	e9 2a fb ff ff       	jmp    80105033 <alltraps>

80105509 <vector19>:
.globl vector19
vector19:
  pushl $0
80105509:	6a 00                	push   $0x0
  pushl $19
8010550b:	6a 13                	push   $0x13
  jmp alltraps
8010550d:	e9 21 fb ff ff       	jmp    80105033 <alltraps>

80105512 <vector20>:
.globl vector20
vector20:
  pushl $0
80105512:	6a 00                	push   $0x0
  pushl $20
80105514:	6a 14                	push   $0x14
  jmp alltraps
80105516:	e9 18 fb ff ff       	jmp    80105033 <alltraps>

8010551b <vector21>:
.globl vector21
vector21:
  pushl $0
8010551b:	6a 00                	push   $0x0
  pushl $21
8010551d:	6a 15                	push   $0x15
  jmp alltraps
8010551f:	e9 0f fb ff ff       	jmp    80105033 <alltraps>

80105524 <vector22>:
.globl vector22
vector22:
  pushl $0
80105524:	6a 00                	push   $0x0
  pushl $22
80105526:	6a 16                	push   $0x16
  jmp alltraps
80105528:	e9 06 fb ff ff       	jmp    80105033 <alltraps>

8010552d <vector23>:
.globl vector23
vector23:
  pushl $0
8010552d:	6a 00                	push   $0x0
  pushl $23
8010552f:	6a 17                	push   $0x17
  jmp alltraps
80105531:	e9 fd fa ff ff       	jmp    80105033 <alltraps>

80105536 <vector24>:
.globl vector24
vector24:
  pushl $0
80105536:	6a 00                	push   $0x0
  pushl $24
80105538:	6a 18                	push   $0x18
  jmp alltraps
8010553a:	e9 f4 fa ff ff       	jmp    80105033 <alltraps>

8010553f <vector25>:
.globl vector25
vector25:
  pushl $0
8010553f:	6a 00                	push   $0x0
  pushl $25
80105541:	6a 19                	push   $0x19
  jmp alltraps
80105543:	e9 eb fa ff ff       	jmp    80105033 <alltraps>

80105548 <vector26>:
.globl vector26
vector26:
  pushl $0
80105548:	6a 00                	push   $0x0
  pushl $26
8010554a:	6a 1a                	push   $0x1a
  jmp alltraps
8010554c:	e9 e2 fa ff ff       	jmp    80105033 <alltraps>

80105551 <vector27>:
.globl vector27
vector27:
  pushl $0
80105551:	6a 00                	push   $0x0
  pushl $27
80105553:	6a 1b                	push   $0x1b
  jmp alltraps
80105555:	e9 d9 fa ff ff       	jmp    80105033 <alltraps>

8010555a <vector28>:
.globl vector28
vector28:
  pushl $0
8010555a:	6a 00                	push   $0x0
  pushl $28
8010555c:	6a 1c                	push   $0x1c
  jmp alltraps
8010555e:	e9 d0 fa ff ff       	jmp    80105033 <alltraps>

80105563 <vector29>:
.globl vector29
vector29:
  pushl $0
80105563:	6a 00                	push   $0x0
  pushl $29
80105565:	6a 1d                	push   $0x1d
  jmp alltraps
80105567:	e9 c7 fa ff ff       	jmp    80105033 <alltraps>

8010556c <vector30>:
.globl vector30
vector30:
  pushl $0
8010556c:	6a 00                	push   $0x0
  pushl $30
8010556e:	6a 1e                	push   $0x1e
  jmp alltraps
80105570:	e9 be fa ff ff       	jmp    80105033 <alltraps>

80105575 <vector31>:
.globl vector31
vector31:
  pushl $0
80105575:	6a 00                	push   $0x0
  pushl $31
80105577:	6a 1f                	push   $0x1f
  jmp alltraps
80105579:	e9 b5 fa ff ff       	jmp    80105033 <alltraps>

8010557e <vector32>:
.globl vector32
vector32:
  pushl $0
8010557e:	6a 00                	push   $0x0
  pushl $32
80105580:	6a 20                	push   $0x20
  jmp alltraps
80105582:	e9 ac fa ff ff       	jmp    80105033 <alltraps>

80105587 <vector33>:
.globl vector33
vector33:
  pushl $0
80105587:	6a 00                	push   $0x0
  pushl $33
80105589:	6a 21                	push   $0x21
  jmp alltraps
8010558b:	e9 a3 fa ff ff       	jmp    80105033 <alltraps>

80105590 <vector34>:
.globl vector34
vector34:
  pushl $0
80105590:	6a 00                	push   $0x0
  pushl $34
80105592:	6a 22                	push   $0x22
  jmp alltraps
80105594:	e9 9a fa ff ff       	jmp    80105033 <alltraps>

80105599 <vector35>:
.globl vector35
vector35:
  pushl $0
80105599:	6a 00                	push   $0x0
  pushl $35
8010559b:	6a 23                	push   $0x23
  jmp alltraps
8010559d:	e9 91 fa ff ff       	jmp    80105033 <alltraps>

801055a2 <vector36>:
.globl vector36
vector36:
  pushl $0
801055a2:	6a 00                	push   $0x0
  pushl $36
801055a4:	6a 24                	push   $0x24
  jmp alltraps
801055a6:	e9 88 fa ff ff       	jmp    80105033 <alltraps>

801055ab <vector37>:
.globl vector37
vector37:
  pushl $0
801055ab:	6a 00                	push   $0x0
  pushl $37
801055ad:	6a 25                	push   $0x25
  jmp alltraps
801055af:	e9 7f fa ff ff       	jmp    80105033 <alltraps>

801055b4 <vector38>:
.globl vector38
vector38:
  pushl $0
801055b4:	6a 00                	push   $0x0
  pushl $38
801055b6:	6a 26                	push   $0x26
  jmp alltraps
801055b8:	e9 76 fa ff ff       	jmp    80105033 <alltraps>

801055bd <vector39>:
.globl vector39
vector39:
  pushl $0
801055bd:	6a 00                	push   $0x0
  pushl $39
801055bf:	6a 27                	push   $0x27
  jmp alltraps
801055c1:	e9 6d fa ff ff       	jmp    80105033 <alltraps>

801055c6 <vector40>:
.globl vector40
vector40:
  pushl $0
801055c6:	6a 00                	push   $0x0
  pushl $40
801055c8:	6a 28                	push   $0x28
  jmp alltraps
801055ca:	e9 64 fa ff ff       	jmp    80105033 <alltraps>

801055cf <vector41>:
.globl vector41
vector41:
  pushl $0
801055cf:	6a 00                	push   $0x0
  pushl $41
801055d1:	6a 29                	push   $0x29
  jmp alltraps
801055d3:	e9 5b fa ff ff       	jmp    80105033 <alltraps>

801055d8 <vector42>:
.globl vector42
vector42:
  pushl $0
801055d8:	6a 00                	push   $0x0
  pushl $42
801055da:	6a 2a                	push   $0x2a
  jmp alltraps
801055dc:	e9 52 fa ff ff       	jmp    80105033 <alltraps>

801055e1 <vector43>:
.globl vector43
vector43:
  pushl $0
801055e1:	6a 00                	push   $0x0
  pushl $43
801055e3:	6a 2b                	push   $0x2b
  jmp alltraps
801055e5:	e9 49 fa ff ff       	jmp    80105033 <alltraps>

801055ea <vector44>:
.globl vector44
vector44:
  pushl $0
801055ea:	6a 00                	push   $0x0
  pushl $44
801055ec:	6a 2c                	push   $0x2c
  jmp alltraps
801055ee:	e9 40 fa ff ff       	jmp    80105033 <alltraps>

801055f3 <vector45>:
.globl vector45
vector45:
  pushl $0
801055f3:	6a 00                	push   $0x0
  pushl $45
801055f5:	6a 2d                	push   $0x2d
  jmp alltraps
801055f7:	e9 37 fa ff ff       	jmp    80105033 <alltraps>

801055fc <vector46>:
.globl vector46
vector46:
  pushl $0
801055fc:	6a 00                	push   $0x0
  pushl $46
801055fe:	6a 2e                	push   $0x2e
  jmp alltraps
80105600:	e9 2e fa ff ff       	jmp    80105033 <alltraps>

80105605 <vector47>:
.globl vector47
vector47:
  pushl $0
80105605:	6a 00                	push   $0x0
  pushl $47
80105607:	6a 2f                	push   $0x2f
  jmp alltraps
80105609:	e9 25 fa ff ff       	jmp    80105033 <alltraps>

8010560e <vector48>:
.globl vector48
vector48:
  pushl $0
8010560e:	6a 00                	push   $0x0
  pushl $48
80105610:	6a 30                	push   $0x30
  jmp alltraps
80105612:	e9 1c fa ff ff       	jmp    80105033 <alltraps>

80105617 <vector49>:
.globl vector49
vector49:
  pushl $0
80105617:	6a 00                	push   $0x0
  pushl $49
80105619:	6a 31                	push   $0x31
  jmp alltraps
8010561b:	e9 13 fa ff ff       	jmp    80105033 <alltraps>

80105620 <vector50>:
.globl vector50
vector50:
  pushl $0
80105620:	6a 00                	push   $0x0
  pushl $50
80105622:	6a 32                	push   $0x32
  jmp alltraps
80105624:	e9 0a fa ff ff       	jmp    80105033 <alltraps>

80105629 <vector51>:
.globl vector51
vector51:
  pushl $0
80105629:	6a 00                	push   $0x0
  pushl $51
8010562b:	6a 33                	push   $0x33
  jmp alltraps
8010562d:	e9 01 fa ff ff       	jmp    80105033 <alltraps>

80105632 <vector52>:
.globl vector52
vector52:
  pushl $0
80105632:	6a 00                	push   $0x0
  pushl $52
80105634:	6a 34                	push   $0x34
  jmp alltraps
80105636:	e9 f8 f9 ff ff       	jmp    80105033 <alltraps>

8010563b <vector53>:
.globl vector53
vector53:
  pushl $0
8010563b:	6a 00                	push   $0x0
  pushl $53
8010563d:	6a 35                	push   $0x35
  jmp alltraps
8010563f:	e9 ef f9 ff ff       	jmp    80105033 <alltraps>

80105644 <vector54>:
.globl vector54
vector54:
  pushl $0
80105644:	6a 00                	push   $0x0
  pushl $54
80105646:	6a 36                	push   $0x36
  jmp alltraps
80105648:	e9 e6 f9 ff ff       	jmp    80105033 <alltraps>

8010564d <vector55>:
.globl vector55
vector55:
  pushl $0
8010564d:	6a 00                	push   $0x0
  pushl $55
8010564f:	6a 37                	push   $0x37
  jmp alltraps
80105651:	e9 dd f9 ff ff       	jmp    80105033 <alltraps>

80105656 <vector56>:
.globl vector56
vector56:
  pushl $0
80105656:	6a 00                	push   $0x0
  pushl $56
80105658:	6a 38                	push   $0x38
  jmp alltraps
8010565a:	e9 d4 f9 ff ff       	jmp    80105033 <alltraps>

8010565f <vector57>:
.globl vector57
vector57:
  pushl $0
8010565f:	6a 00                	push   $0x0
  pushl $57
80105661:	6a 39                	push   $0x39
  jmp alltraps
80105663:	e9 cb f9 ff ff       	jmp    80105033 <alltraps>

80105668 <vector58>:
.globl vector58
vector58:
  pushl $0
80105668:	6a 00                	push   $0x0
  pushl $58
8010566a:	6a 3a                	push   $0x3a
  jmp alltraps
8010566c:	e9 c2 f9 ff ff       	jmp    80105033 <alltraps>

80105671 <vector59>:
.globl vector59
vector59:
  pushl $0
80105671:	6a 00                	push   $0x0
  pushl $59
80105673:	6a 3b                	push   $0x3b
  jmp alltraps
80105675:	e9 b9 f9 ff ff       	jmp    80105033 <alltraps>

8010567a <vector60>:
.globl vector60
vector60:
  pushl $0
8010567a:	6a 00                	push   $0x0
  pushl $60
8010567c:	6a 3c                	push   $0x3c
  jmp alltraps
8010567e:	e9 b0 f9 ff ff       	jmp    80105033 <alltraps>

80105683 <vector61>:
.globl vector61
vector61:
  pushl $0
80105683:	6a 00                	push   $0x0
  pushl $61
80105685:	6a 3d                	push   $0x3d
  jmp alltraps
80105687:	e9 a7 f9 ff ff       	jmp    80105033 <alltraps>

8010568c <vector62>:
.globl vector62
vector62:
  pushl $0
8010568c:	6a 00                	push   $0x0
  pushl $62
8010568e:	6a 3e                	push   $0x3e
  jmp alltraps
80105690:	e9 9e f9 ff ff       	jmp    80105033 <alltraps>

80105695 <vector63>:
.globl vector63
vector63:
  pushl $0
80105695:	6a 00                	push   $0x0
  pushl $63
80105697:	6a 3f                	push   $0x3f
  jmp alltraps
80105699:	e9 95 f9 ff ff       	jmp    80105033 <alltraps>

8010569e <vector64>:
.globl vector64
vector64:
  pushl $0
8010569e:	6a 00                	push   $0x0
  pushl $64
801056a0:	6a 40                	push   $0x40
  jmp alltraps
801056a2:	e9 8c f9 ff ff       	jmp    80105033 <alltraps>

801056a7 <vector65>:
.globl vector65
vector65:
  pushl $0
801056a7:	6a 00                	push   $0x0
  pushl $65
801056a9:	6a 41                	push   $0x41
  jmp alltraps
801056ab:	e9 83 f9 ff ff       	jmp    80105033 <alltraps>

801056b0 <vector66>:
.globl vector66
vector66:
  pushl $0
801056b0:	6a 00                	push   $0x0
  pushl $66
801056b2:	6a 42                	push   $0x42
  jmp alltraps
801056b4:	e9 7a f9 ff ff       	jmp    80105033 <alltraps>

801056b9 <vector67>:
.globl vector67
vector67:
  pushl $0
801056b9:	6a 00                	push   $0x0
  pushl $67
801056bb:	6a 43                	push   $0x43
  jmp alltraps
801056bd:	e9 71 f9 ff ff       	jmp    80105033 <alltraps>

801056c2 <vector68>:
.globl vector68
vector68:
  pushl $0
801056c2:	6a 00                	push   $0x0
  pushl $68
801056c4:	6a 44                	push   $0x44
  jmp alltraps
801056c6:	e9 68 f9 ff ff       	jmp    80105033 <alltraps>

801056cb <vector69>:
.globl vector69
vector69:
  pushl $0
801056cb:	6a 00                	push   $0x0
  pushl $69
801056cd:	6a 45                	push   $0x45
  jmp alltraps
801056cf:	e9 5f f9 ff ff       	jmp    80105033 <alltraps>

801056d4 <vector70>:
.globl vector70
vector70:
  pushl $0
801056d4:	6a 00                	push   $0x0
  pushl $70
801056d6:	6a 46                	push   $0x46
  jmp alltraps
801056d8:	e9 56 f9 ff ff       	jmp    80105033 <alltraps>

801056dd <vector71>:
.globl vector71
vector71:
  pushl $0
801056dd:	6a 00                	push   $0x0
  pushl $71
801056df:	6a 47                	push   $0x47
  jmp alltraps
801056e1:	e9 4d f9 ff ff       	jmp    80105033 <alltraps>

801056e6 <vector72>:
.globl vector72
vector72:
  pushl $0
801056e6:	6a 00                	push   $0x0
  pushl $72
801056e8:	6a 48                	push   $0x48
  jmp alltraps
801056ea:	e9 44 f9 ff ff       	jmp    80105033 <alltraps>

801056ef <vector73>:
.globl vector73
vector73:
  pushl $0
801056ef:	6a 00                	push   $0x0
  pushl $73
801056f1:	6a 49                	push   $0x49
  jmp alltraps
801056f3:	e9 3b f9 ff ff       	jmp    80105033 <alltraps>

801056f8 <vector74>:
.globl vector74
vector74:
  pushl $0
801056f8:	6a 00                	push   $0x0
  pushl $74
801056fa:	6a 4a                	push   $0x4a
  jmp alltraps
801056fc:	e9 32 f9 ff ff       	jmp    80105033 <alltraps>

80105701 <vector75>:
.globl vector75
vector75:
  pushl $0
80105701:	6a 00                	push   $0x0
  pushl $75
80105703:	6a 4b                	push   $0x4b
  jmp alltraps
80105705:	e9 29 f9 ff ff       	jmp    80105033 <alltraps>

8010570a <vector76>:
.globl vector76
vector76:
  pushl $0
8010570a:	6a 00                	push   $0x0
  pushl $76
8010570c:	6a 4c                	push   $0x4c
  jmp alltraps
8010570e:	e9 20 f9 ff ff       	jmp    80105033 <alltraps>

80105713 <vector77>:
.globl vector77
vector77:
  pushl $0
80105713:	6a 00                	push   $0x0
  pushl $77
80105715:	6a 4d                	push   $0x4d
  jmp alltraps
80105717:	e9 17 f9 ff ff       	jmp    80105033 <alltraps>

8010571c <vector78>:
.globl vector78
vector78:
  pushl $0
8010571c:	6a 00                	push   $0x0
  pushl $78
8010571e:	6a 4e                	push   $0x4e
  jmp alltraps
80105720:	e9 0e f9 ff ff       	jmp    80105033 <alltraps>

80105725 <vector79>:
.globl vector79
vector79:
  pushl $0
80105725:	6a 00                	push   $0x0
  pushl $79
80105727:	6a 4f                	push   $0x4f
  jmp alltraps
80105729:	e9 05 f9 ff ff       	jmp    80105033 <alltraps>

8010572e <vector80>:
.globl vector80
vector80:
  pushl $0
8010572e:	6a 00                	push   $0x0
  pushl $80
80105730:	6a 50                	push   $0x50
  jmp alltraps
80105732:	e9 fc f8 ff ff       	jmp    80105033 <alltraps>

80105737 <vector81>:
.globl vector81
vector81:
  pushl $0
80105737:	6a 00                	push   $0x0
  pushl $81
80105739:	6a 51                	push   $0x51
  jmp alltraps
8010573b:	e9 f3 f8 ff ff       	jmp    80105033 <alltraps>

80105740 <vector82>:
.globl vector82
vector82:
  pushl $0
80105740:	6a 00                	push   $0x0
  pushl $82
80105742:	6a 52                	push   $0x52
  jmp alltraps
80105744:	e9 ea f8 ff ff       	jmp    80105033 <alltraps>

80105749 <vector83>:
.globl vector83
vector83:
  pushl $0
80105749:	6a 00                	push   $0x0
  pushl $83
8010574b:	6a 53                	push   $0x53
  jmp alltraps
8010574d:	e9 e1 f8 ff ff       	jmp    80105033 <alltraps>

80105752 <vector84>:
.globl vector84
vector84:
  pushl $0
80105752:	6a 00                	push   $0x0
  pushl $84
80105754:	6a 54                	push   $0x54
  jmp alltraps
80105756:	e9 d8 f8 ff ff       	jmp    80105033 <alltraps>

8010575b <vector85>:
.globl vector85
vector85:
  pushl $0
8010575b:	6a 00                	push   $0x0
  pushl $85
8010575d:	6a 55                	push   $0x55
  jmp alltraps
8010575f:	e9 cf f8 ff ff       	jmp    80105033 <alltraps>

80105764 <vector86>:
.globl vector86
vector86:
  pushl $0
80105764:	6a 00                	push   $0x0
  pushl $86
80105766:	6a 56                	push   $0x56
  jmp alltraps
80105768:	e9 c6 f8 ff ff       	jmp    80105033 <alltraps>

8010576d <vector87>:
.globl vector87
vector87:
  pushl $0
8010576d:	6a 00                	push   $0x0
  pushl $87
8010576f:	6a 57                	push   $0x57
  jmp alltraps
80105771:	e9 bd f8 ff ff       	jmp    80105033 <alltraps>

80105776 <vector88>:
.globl vector88
vector88:
  pushl $0
80105776:	6a 00                	push   $0x0
  pushl $88
80105778:	6a 58                	push   $0x58
  jmp alltraps
8010577a:	e9 b4 f8 ff ff       	jmp    80105033 <alltraps>

8010577f <vector89>:
.globl vector89
vector89:
  pushl $0
8010577f:	6a 00                	push   $0x0
  pushl $89
80105781:	6a 59                	push   $0x59
  jmp alltraps
80105783:	e9 ab f8 ff ff       	jmp    80105033 <alltraps>

80105788 <vector90>:
.globl vector90
vector90:
  pushl $0
80105788:	6a 00                	push   $0x0
  pushl $90
8010578a:	6a 5a                	push   $0x5a
  jmp alltraps
8010578c:	e9 a2 f8 ff ff       	jmp    80105033 <alltraps>

80105791 <vector91>:
.globl vector91
vector91:
  pushl $0
80105791:	6a 00                	push   $0x0
  pushl $91
80105793:	6a 5b                	push   $0x5b
  jmp alltraps
80105795:	e9 99 f8 ff ff       	jmp    80105033 <alltraps>

8010579a <vector92>:
.globl vector92
vector92:
  pushl $0
8010579a:	6a 00                	push   $0x0
  pushl $92
8010579c:	6a 5c                	push   $0x5c
  jmp alltraps
8010579e:	e9 90 f8 ff ff       	jmp    80105033 <alltraps>

801057a3 <vector93>:
.globl vector93
vector93:
  pushl $0
801057a3:	6a 00                	push   $0x0
  pushl $93
801057a5:	6a 5d                	push   $0x5d
  jmp alltraps
801057a7:	e9 87 f8 ff ff       	jmp    80105033 <alltraps>

801057ac <vector94>:
.globl vector94
vector94:
  pushl $0
801057ac:	6a 00                	push   $0x0
  pushl $94
801057ae:	6a 5e                	push   $0x5e
  jmp alltraps
801057b0:	e9 7e f8 ff ff       	jmp    80105033 <alltraps>

801057b5 <vector95>:
.globl vector95
vector95:
  pushl $0
801057b5:	6a 00                	push   $0x0
  pushl $95
801057b7:	6a 5f                	push   $0x5f
  jmp alltraps
801057b9:	e9 75 f8 ff ff       	jmp    80105033 <alltraps>

801057be <vector96>:
.globl vector96
vector96:
  pushl $0
801057be:	6a 00                	push   $0x0
  pushl $96
801057c0:	6a 60                	push   $0x60
  jmp alltraps
801057c2:	e9 6c f8 ff ff       	jmp    80105033 <alltraps>

801057c7 <vector97>:
.globl vector97
vector97:
  pushl $0
801057c7:	6a 00                	push   $0x0
  pushl $97
801057c9:	6a 61                	push   $0x61
  jmp alltraps
801057cb:	e9 63 f8 ff ff       	jmp    80105033 <alltraps>

801057d0 <vector98>:
.globl vector98
vector98:
  pushl $0
801057d0:	6a 00                	push   $0x0
  pushl $98
801057d2:	6a 62                	push   $0x62
  jmp alltraps
801057d4:	e9 5a f8 ff ff       	jmp    80105033 <alltraps>

801057d9 <vector99>:
.globl vector99
vector99:
  pushl $0
801057d9:	6a 00                	push   $0x0
  pushl $99
801057db:	6a 63                	push   $0x63
  jmp alltraps
801057dd:	e9 51 f8 ff ff       	jmp    80105033 <alltraps>

801057e2 <vector100>:
.globl vector100
vector100:
  pushl $0
801057e2:	6a 00                	push   $0x0
  pushl $100
801057e4:	6a 64                	push   $0x64
  jmp alltraps
801057e6:	e9 48 f8 ff ff       	jmp    80105033 <alltraps>

801057eb <vector101>:
.globl vector101
vector101:
  pushl $0
801057eb:	6a 00                	push   $0x0
  pushl $101
801057ed:	6a 65                	push   $0x65
  jmp alltraps
801057ef:	e9 3f f8 ff ff       	jmp    80105033 <alltraps>

801057f4 <vector102>:
.globl vector102
vector102:
  pushl $0
801057f4:	6a 00                	push   $0x0
  pushl $102
801057f6:	6a 66                	push   $0x66
  jmp alltraps
801057f8:	e9 36 f8 ff ff       	jmp    80105033 <alltraps>

801057fd <vector103>:
.globl vector103
vector103:
  pushl $0
801057fd:	6a 00                	push   $0x0
  pushl $103
801057ff:	6a 67                	push   $0x67
  jmp alltraps
80105801:	e9 2d f8 ff ff       	jmp    80105033 <alltraps>

80105806 <vector104>:
.globl vector104
vector104:
  pushl $0
80105806:	6a 00                	push   $0x0
  pushl $104
80105808:	6a 68                	push   $0x68
  jmp alltraps
8010580a:	e9 24 f8 ff ff       	jmp    80105033 <alltraps>

8010580f <vector105>:
.globl vector105
vector105:
  pushl $0
8010580f:	6a 00                	push   $0x0
  pushl $105
80105811:	6a 69                	push   $0x69
  jmp alltraps
80105813:	e9 1b f8 ff ff       	jmp    80105033 <alltraps>

80105818 <vector106>:
.globl vector106
vector106:
  pushl $0
80105818:	6a 00                	push   $0x0
  pushl $106
8010581a:	6a 6a                	push   $0x6a
  jmp alltraps
8010581c:	e9 12 f8 ff ff       	jmp    80105033 <alltraps>

80105821 <vector107>:
.globl vector107
vector107:
  pushl $0
80105821:	6a 00                	push   $0x0
  pushl $107
80105823:	6a 6b                	push   $0x6b
  jmp alltraps
80105825:	e9 09 f8 ff ff       	jmp    80105033 <alltraps>

8010582a <vector108>:
.globl vector108
vector108:
  pushl $0
8010582a:	6a 00                	push   $0x0
  pushl $108
8010582c:	6a 6c                	push   $0x6c
  jmp alltraps
8010582e:	e9 00 f8 ff ff       	jmp    80105033 <alltraps>

80105833 <vector109>:
.globl vector109
vector109:
  pushl $0
80105833:	6a 00                	push   $0x0
  pushl $109
80105835:	6a 6d                	push   $0x6d
  jmp alltraps
80105837:	e9 f7 f7 ff ff       	jmp    80105033 <alltraps>

8010583c <vector110>:
.globl vector110
vector110:
  pushl $0
8010583c:	6a 00                	push   $0x0
  pushl $110
8010583e:	6a 6e                	push   $0x6e
  jmp alltraps
80105840:	e9 ee f7 ff ff       	jmp    80105033 <alltraps>

80105845 <vector111>:
.globl vector111
vector111:
  pushl $0
80105845:	6a 00                	push   $0x0
  pushl $111
80105847:	6a 6f                	push   $0x6f
  jmp alltraps
80105849:	e9 e5 f7 ff ff       	jmp    80105033 <alltraps>

8010584e <vector112>:
.globl vector112
vector112:
  pushl $0
8010584e:	6a 00                	push   $0x0
  pushl $112
80105850:	6a 70                	push   $0x70
  jmp alltraps
80105852:	e9 dc f7 ff ff       	jmp    80105033 <alltraps>

80105857 <vector113>:
.globl vector113
vector113:
  pushl $0
80105857:	6a 00                	push   $0x0
  pushl $113
80105859:	6a 71                	push   $0x71
  jmp alltraps
8010585b:	e9 d3 f7 ff ff       	jmp    80105033 <alltraps>

80105860 <vector114>:
.globl vector114
vector114:
  pushl $0
80105860:	6a 00                	push   $0x0
  pushl $114
80105862:	6a 72                	push   $0x72
  jmp alltraps
80105864:	e9 ca f7 ff ff       	jmp    80105033 <alltraps>

80105869 <vector115>:
.globl vector115
vector115:
  pushl $0
80105869:	6a 00                	push   $0x0
  pushl $115
8010586b:	6a 73                	push   $0x73
  jmp alltraps
8010586d:	e9 c1 f7 ff ff       	jmp    80105033 <alltraps>

80105872 <vector116>:
.globl vector116
vector116:
  pushl $0
80105872:	6a 00                	push   $0x0
  pushl $116
80105874:	6a 74                	push   $0x74
  jmp alltraps
80105876:	e9 b8 f7 ff ff       	jmp    80105033 <alltraps>

8010587b <vector117>:
.globl vector117
vector117:
  pushl $0
8010587b:	6a 00                	push   $0x0
  pushl $117
8010587d:	6a 75                	push   $0x75
  jmp alltraps
8010587f:	e9 af f7 ff ff       	jmp    80105033 <alltraps>

80105884 <vector118>:
.globl vector118
vector118:
  pushl $0
80105884:	6a 00                	push   $0x0
  pushl $118
80105886:	6a 76                	push   $0x76
  jmp alltraps
80105888:	e9 a6 f7 ff ff       	jmp    80105033 <alltraps>

8010588d <vector119>:
.globl vector119
vector119:
  pushl $0
8010588d:	6a 00                	push   $0x0
  pushl $119
8010588f:	6a 77                	push   $0x77
  jmp alltraps
80105891:	e9 9d f7 ff ff       	jmp    80105033 <alltraps>

80105896 <vector120>:
.globl vector120
vector120:
  pushl $0
80105896:	6a 00                	push   $0x0
  pushl $120
80105898:	6a 78                	push   $0x78
  jmp alltraps
8010589a:	e9 94 f7 ff ff       	jmp    80105033 <alltraps>

8010589f <vector121>:
.globl vector121
vector121:
  pushl $0
8010589f:	6a 00                	push   $0x0
  pushl $121
801058a1:	6a 79                	push   $0x79
  jmp alltraps
801058a3:	e9 8b f7 ff ff       	jmp    80105033 <alltraps>

801058a8 <vector122>:
.globl vector122
vector122:
  pushl $0
801058a8:	6a 00                	push   $0x0
  pushl $122
801058aa:	6a 7a                	push   $0x7a
  jmp alltraps
801058ac:	e9 82 f7 ff ff       	jmp    80105033 <alltraps>

801058b1 <vector123>:
.globl vector123
vector123:
  pushl $0
801058b1:	6a 00                	push   $0x0
  pushl $123
801058b3:	6a 7b                	push   $0x7b
  jmp alltraps
801058b5:	e9 79 f7 ff ff       	jmp    80105033 <alltraps>

801058ba <vector124>:
.globl vector124
vector124:
  pushl $0
801058ba:	6a 00                	push   $0x0
  pushl $124
801058bc:	6a 7c                	push   $0x7c
  jmp alltraps
801058be:	e9 70 f7 ff ff       	jmp    80105033 <alltraps>

801058c3 <vector125>:
.globl vector125
vector125:
  pushl $0
801058c3:	6a 00                	push   $0x0
  pushl $125
801058c5:	6a 7d                	push   $0x7d
  jmp alltraps
801058c7:	e9 67 f7 ff ff       	jmp    80105033 <alltraps>

801058cc <vector126>:
.globl vector126
vector126:
  pushl $0
801058cc:	6a 00                	push   $0x0
  pushl $126
801058ce:	6a 7e                	push   $0x7e
  jmp alltraps
801058d0:	e9 5e f7 ff ff       	jmp    80105033 <alltraps>

801058d5 <vector127>:
.globl vector127
vector127:
  pushl $0
801058d5:	6a 00                	push   $0x0
  pushl $127
801058d7:	6a 7f                	push   $0x7f
  jmp alltraps
801058d9:	e9 55 f7 ff ff       	jmp    80105033 <alltraps>

801058de <vector128>:
.globl vector128
vector128:
  pushl $0
801058de:	6a 00                	push   $0x0
  pushl $128
801058e0:	68 80 00 00 00       	push   $0x80
  jmp alltraps
801058e5:	e9 49 f7 ff ff       	jmp    80105033 <alltraps>

801058ea <vector129>:
.globl vector129
vector129:
  pushl $0
801058ea:	6a 00                	push   $0x0
  pushl $129
801058ec:	68 81 00 00 00       	push   $0x81
  jmp alltraps
801058f1:	e9 3d f7 ff ff       	jmp    80105033 <alltraps>

801058f6 <vector130>:
.globl vector130
vector130:
  pushl $0
801058f6:	6a 00                	push   $0x0
  pushl $130
801058f8:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801058fd:	e9 31 f7 ff ff       	jmp    80105033 <alltraps>

80105902 <vector131>:
.globl vector131
vector131:
  pushl $0
80105902:	6a 00                	push   $0x0
  pushl $131
80105904:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80105909:	e9 25 f7 ff ff       	jmp    80105033 <alltraps>

8010590e <vector132>:
.globl vector132
vector132:
  pushl $0
8010590e:	6a 00                	push   $0x0
  pushl $132
80105910:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80105915:	e9 19 f7 ff ff       	jmp    80105033 <alltraps>

8010591a <vector133>:
.globl vector133
vector133:
  pushl $0
8010591a:	6a 00                	push   $0x0
  pushl $133
8010591c:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80105921:	e9 0d f7 ff ff       	jmp    80105033 <alltraps>

80105926 <vector134>:
.globl vector134
vector134:
  pushl $0
80105926:	6a 00                	push   $0x0
  pushl $134
80105928:	68 86 00 00 00       	push   $0x86
  jmp alltraps
8010592d:	e9 01 f7 ff ff       	jmp    80105033 <alltraps>

80105932 <vector135>:
.globl vector135
vector135:
  pushl $0
80105932:	6a 00                	push   $0x0
  pushl $135
80105934:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80105939:	e9 f5 f6 ff ff       	jmp    80105033 <alltraps>

8010593e <vector136>:
.globl vector136
vector136:
  pushl $0
8010593e:	6a 00                	push   $0x0
  pushl $136
80105940:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80105945:	e9 e9 f6 ff ff       	jmp    80105033 <alltraps>

8010594a <vector137>:
.globl vector137
vector137:
  pushl $0
8010594a:	6a 00                	push   $0x0
  pushl $137
8010594c:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80105951:	e9 dd f6 ff ff       	jmp    80105033 <alltraps>

80105956 <vector138>:
.globl vector138
vector138:
  pushl $0
80105956:	6a 00                	push   $0x0
  pushl $138
80105958:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
8010595d:	e9 d1 f6 ff ff       	jmp    80105033 <alltraps>

80105962 <vector139>:
.globl vector139
vector139:
  pushl $0
80105962:	6a 00                	push   $0x0
  pushl $139
80105964:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80105969:	e9 c5 f6 ff ff       	jmp    80105033 <alltraps>

8010596e <vector140>:
.globl vector140
vector140:
  pushl $0
8010596e:	6a 00                	push   $0x0
  pushl $140
80105970:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80105975:	e9 b9 f6 ff ff       	jmp    80105033 <alltraps>

8010597a <vector141>:
.globl vector141
vector141:
  pushl $0
8010597a:	6a 00                	push   $0x0
  pushl $141
8010597c:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80105981:	e9 ad f6 ff ff       	jmp    80105033 <alltraps>

80105986 <vector142>:
.globl vector142
vector142:
  pushl $0
80105986:	6a 00                	push   $0x0
  pushl $142
80105988:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
8010598d:	e9 a1 f6 ff ff       	jmp    80105033 <alltraps>

80105992 <vector143>:
.globl vector143
vector143:
  pushl $0
80105992:	6a 00                	push   $0x0
  pushl $143
80105994:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80105999:	e9 95 f6 ff ff       	jmp    80105033 <alltraps>

8010599e <vector144>:
.globl vector144
vector144:
  pushl $0
8010599e:	6a 00                	push   $0x0
  pushl $144
801059a0:	68 90 00 00 00       	push   $0x90
  jmp alltraps
801059a5:	e9 89 f6 ff ff       	jmp    80105033 <alltraps>

801059aa <vector145>:
.globl vector145
vector145:
  pushl $0
801059aa:	6a 00                	push   $0x0
  pushl $145
801059ac:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801059b1:	e9 7d f6 ff ff       	jmp    80105033 <alltraps>

801059b6 <vector146>:
.globl vector146
vector146:
  pushl $0
801059b6:	6a 00                	push   $0x0
  pushl $146
801059b8:	68 92 00 00 00       	push   $0x92
  jmp alltraps
801059bd:	e9 71 f6 ff ff       	jmp    80105033 <alltraps>

801059c2 <vector147>:
.globl vector147
vector147:
  pushl $0
801059c2:	6a 00                	push   $0x0
  pushl $147
801059c4:	68 93 00 00 00       	push   $0x93
  jmp alltraps
801059c9:	e9 65 f6 ff ff       	jmp    80105033 <alltraps>

801059ce <vector148>:
.globl vector148
vector148:
  pushl $0
801059ce:	6a 00                	push   $0x0
  pushl $148
801059d0:	68 94 00 00 00       	push   $0x94
  jmp alltraps
801059d5:	e9 59 f6 ff ff       	jmp    80105033 <alltraps>

801059da <vector149>:
.globl vector149
vector149:
  pushl $0
801059da:	6a 00                	push   $0x0
  pushl $149
801059dc:	68 95 00 00 00       	push   $0x95
  jmp alltraps
801059e1:	e9 4d f6 ff ff       	jmp    80105033 <alltraps>

801059e6 <vector150>:
.globl vector150
vector150:
  pushl $0
801059e6:	6a 00                	push   $0x0
  pushl $150
801059e8:	68 96 00 00 00       	push   $0x96
  jmp alltraps
801059ed:	e9 41 f6 ff ff       	jmp    80105033 <alltraps>

801059f2 <vector151>:
.globl vector151
vector151:
  pushl $0
801059f2:	6a 00                	push   $0x0
  pushl $151
801059f4:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801059f9:	e9 35 f6 ff ff       	jmp    80105033 <alltraps>

801059fe <vector152>:
.globl vector152
vector152:
  pushl $0
801059fe:	6a 00                	push   $0x0
  pushl $152
80105a00:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80105a05:	e9 29 f6 ff ff       	jmp    80105033 <alltraps>

80105a0a <vector153>:
.globl vector153
vector153:
  pushl $0
80105a0a:	6a 00                	push   $0x0
  pushl $153
80105a0c:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80105a11:	e9 1d f6 ff ff       	jmp    80105033 <alltraps>

80105a16 <vector154>:
.globl vector154
vector154:
  pushl $0
80105a16:	6a 00                	push   $0x0
  pushl $154
80105a18:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80105a1d:	e9 11 f6 ff ff       	jmp    80105033 <alltraps>

80105a22 <vector155>:
.globl vector155
vector155:
  pushl $0
80105a22:	6a 00                	push   $0x0
  pushl $155
80105a24:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80105a29:	e9 05 f6 ff ff       	jmp    80105033 <alltraps>

80105a2e <vector156>:
.globl vector156
vector156:
  pushl $0
80105a2e:	6a 00                	push   $0x0
  pushl $156
80105a30:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80105a35:	e9 f9 f5 ff ff       	jmp    80105033 <alltraps>

80105a3a <vector157>:
.globl vector157
vector157:
  pushl $0
80105a3a:	6a 00                	push   $0x0
  pushl $157
80105a3c:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80105a41:	e9 ed f5 ff ff       	jmp    80105033 <alltraps>

80105a46 <vector158>:
.globl vector158
vector158:
  pushl $0
80105a46:	6a 00                	push   $0x0
  pushl $158
80105a48:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80105a4d:	e9 e1 f5 ff ff       	jmp    80105033 <alltraps>

80105a52 <vector159>:
.globl vector159
vector159:
  pushl $0
80105a52:	6a 00                	push   $0x0
  pushl $159
80105a54:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80105a59:	e9 d5 f5 ff ff       	jmp    80105033 <alltraps>

80105a5e <vector160>:
.globl vector160
vector160:
  pushl $0
80105a5e:	6a 00                	push   $0x0
  pushl $160
80105a60:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80105a65:	e9 c9 f5 ff ff       	jmp    80105033 <alltraps>

80105a6a <vector161>:
.globl vector161
vector161:
  pushl $0
80105a6a:	6a 00                	push   $0x0
  pushl $161
80105a6c:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80105a71:	e9 bd f5 ff ff       	jmp    80105033 <alltraps>

80105a76 <vector162>:
.globl vector162
vector162:
  pushl $0
80105a76:	6a 00                	push   $0x0
  pushl $162
80105a78:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105a7d:	e9 b1 f5 ff ff       	jmp    80105033 <alltraps>

80105a82 <vector163>:
.globl vector163
vector163:
  pushl $0
80105a82:	6a 00                	push   $0x0
  pushl $163
80105a84:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105a89:	e9 a5 f5 ff ff       	jmp    80105033 <alltraps>

80105a8e <vector164>:
.globl vector164
vector164:
  pushl $0
80105a8e:	6a 00                	push   $0x0
  pushl $164
80105a90:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80105a95:	e9 99 f5 ff ff       	jmp    80105033 <alltraps>

80105a9a <vector165>:
.globl vector165
vector165:
  pushl $0
80105a9a:	6a 00                	push   $0x0
  pushl $165
80105a9c:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80105aa1:	e9 8d f5 ff ff       	jmp    80105033 <alltraps>

80105aa6 <vector166>:
.globl vector166
vector166:
  pushl $0
80105aa6:	6a 00                	push   $0x0
  pushl $166
80105aa8:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105aad:	e9 81 f5 ff ff       	jmp    80105033 <alltraps>

80105ab2 <vector167>:
.globl vector167
vector167:
  pushl $0
80105ab2:	6a 00                	push   $0x0
  pushl $167
80105ab4:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105ab9:	e9 75 f5 ff ff       	jmp    80105033 <alltraps>

80105abe <vector168>:
.globl vector168
vector168:
  pushl $0
80105abe:	6a 00                	push   $0x0
  pushl $168
80105ac0:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105ac5:	e9 69 f5 ff ff       	jmp    80105033 <alltraps>

80105aca <vector169>:
.globl vector169
vector169:
  pushl $0
80105aca:	6a 00                	push   $0x0
  pushl $169
80105acc:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80105ad1:	e9 5d f5 ff ff       	jmp    80105033 <alltraps>

80105ad6 <vector170>:
.globl vector170
vector170:
  pushl $0
80105ad6:	6a 00                	push   $0x0
  pushl $170
80105ad8:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105add:	e9 51 f5 ff ff       	jmp    80105033 <alltraps>

80105ae2 <vector171>:
.globl vector171
vector171:
  pushl $0
80105ae2:	6a 00                	push   $0x0
  pushl $171
80105ae4:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105ae9:	e9 45 f5 ff ff       	jmp    80105033 <alltraps>

80105aee <vector172>:
.globl vector172
vector172:
  pushl $0
80105aee:	6a 00                	push   $0x0
  pushl $172
80105af0:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105af5:	e9 39 f5 ff ff       	jmp    80105033 <alltraps>

80105afa <vector173>:
.globl vector173
vector173:
  pushl $0
80105afa:	6a 00                	push   $0x0
  pushl $173
80105afc:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80105b01:	e9 2d f5 ff ff       	jmp    80105033 <alltraps>

80105b06 <vector174>:
.globl vector174
vector174:
  pushl $0
80105b06:	6a 00                	push   $0x0
  pushl $174
80105b08:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105b0d:	e9 21 f5 ff ff       	jmp    80105033 <alltraps>

80105b12 <vector175>:
.globl vector175
vector175:
  pushl $0
80105b12:	6a 00                	push   $0x0
  pushl $175
80105b14:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105b19:	e9 15 f5 ff ff       	jmp    80105033 <alltraps>

80105b1e <vector176>:
.globl vector176
vector176:
  pushl $0
80105b1e:	6a 00                	push   $0x0
  pushl $176
80105b20:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105b25:	e9 09 f5 ff ff       	jmp    80105033 <alltraps>

80105b2a <vector177>:
.globl vector177
vector177:
  pushl $0
80105b2a:	6a 00                	push   $0x0
  pushl $177
80105b2c:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105b31:	e9 fd f4 ff ff       	jmp    80105033 <alltraps>

80105b36 <vector178>:
.globl vector178
vector178:
  pushl $0
80105b36:	6a 00                	push   $0x0
  pushl $178
80105b38:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105b3d:	e9 f1 f4 ff ff       	jmp    80105033 <alltraps>

80105b42 <vector179>:
.globl vector179
vector179:
  pushl $0
80105b42:	6a 00                	push   $0x0
  pushl $179
80105b44:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105b49:	e9 e5 f4 ff ff       	jmp    80105033 <alltraps>

80105b4e <vector180>:
.globl vector180
vector180:
  pushl $0
80105b4e:	6a 00                	push   $0x0
  pushl $180
80105b50:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105b55:	e9 d9 f4 ff ff       	jmp    80105033 <alltraps>

80105b5a <vector181>:
.globl vector181
vector181:
  pushl $0
80105b5a:	6a 00                	push   $0x0
  pushl $181
80105b5c:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105b61:	e9 cd f4 ff ff       	jmp    80105033 <alltraps>

80105b66 <vector182>:
.globl vector182
vector182:
  pushl $0
80105b66:	6a 00                	push   $0x0
  pushl $182
80105b68:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105b6d:	e9 c1 f4 ff ff       	jmp    80105033 <alltraps>

80105b72 <vector183>:
.globl vector183
vector183:
  pushl $0
80105b72:	6a 00                	push   $0x0
  pushl $183
80105b74:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105b79:	e9 b5 f4 ff ff       	jmp    80105033 <alltraps>

80105b7e <vector184>:
.globl vector184
vector184:
  pushl $0
80105b7e:	6a 00                	push   $0x0
  pushl $184
80105b80:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105b85:	e9 a9 f4 ff ff       	jmp    80105033 <alltraps>

80105b8a <vector185>:
.globl vector185
vector185:
  pushl $0
80105b8a:	6a 00                	push   $0x0
  pushl $185
80105b8c:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105b91:	e9 9d f4 ff ff       	jmp    80105033 <alltraps>

80105b96 <vector186>:
.globl vector186
vector186:
  pushl $0
80105b96:	6a 00                	push   $0x0
  pushl $186
80105b98:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105b9d:	e9 91 f4 ff ff       	jmp    80105033 <alltraps>

80105ba2 <vector187>:
.globl vector187
vector187:
  pushl $0
80105ba2:	6a 00                	push   $0x0
  pushl $187
80105ba4:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105ba9:	e9 85 f4 ff ff       	jmp    80105033 <alltraps>

80105bae <vector188>:
.globl vector188
vector188:
  pushl $0
80105bae:	6a 00                	push   $0x0
  pushl $188
80105bb0:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105bb5:	e9 79 f4 ff ff       	jmp    80105033 <alltraps>

80105bba <vector189>:
.globl vector189
vector189:
  pushl $0
80105bba:	6a 00                	push   $0x0
  pushl $189
80105bbc:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105bc1:	e9 6d f4 ff ff       	jmp    80105033 <alltraps>

80105bc6 <vector190>:
.globl vector190
vector190:
  pushl $0
80105bc6:	6a 00                	push   $0x0
  pushl $190
80105bc8:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105bcd:	e9 61 f4 ff ff       	jmp    80105033 <alltraps>

80105bd2 <vector191>:
.globl vector191
vector191:
  pushl $0
80105bd2:	6a 00                	push   $0x0
  pushl $191
80105bd4:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105bd9:	e9 55 f4 ff ff       	jmp    80105033 <alltraps>

80105bde <vector192>:
.globl vector192
vector192:
  pushl $0
80105bde:	6a 00                	push   $0x0
  pushl $192
80105be0:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105be5:	e9 49 f4 ff ff       	jmp    80105033 <alltraps>

80105bea <vector193>:
.globl vector193
vector193:
  pushl $0
80105bea:	6a 00                	push   $0x0
  pushl $193
80105bec:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105bf1:	e9 3d f4 ff ff       	jmp    80105033 <alltraps>

80105bf6 <vector194>:
.globl vector194
vector194:
  pushl $0
80105bf6:	6a 00                	push   $0x0
  pushl $194
80105bf8:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105bfd:	e9 31 f4 ff ff       	jmp    80105033 <alltraps>

80105c02 <vector195>:
.globl vector195
vector195:
  pushl $0
80105c02:	6a 00                	push   $0x0
  pushl $195
80105c04:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105c09:	e9 25 f4 ff ff       	jmp    80105033 <alltraps>

80105c0e <vector196>:
.globl vector196
vector196:
  pushl $0
80105c0e:	6a 00                	push   $0x0
  pushl $196
80105c10:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105c15:	e9 19 f4 ff ff       	jmp    80105033 <alltraps>

80105c1a <vector197>:
.globl vector197
vector197:
  pushl $0
80105c1a:	6a 00                	push   $0x0
  pushl $197
80105c1c:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105c21:	e9 0d f4 ff ff       	jmp    80105033 <alltraps>

80105c26 <vector198>:
.globl vector198
vector198:
  pushl $0
80105c26:	6a 00                	push   $0x0
  pushl $198
80105c28:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105c2d:	e9 01 f4 ff ff       	jmp    80105033 <alltraps>

80105c32 <vector199>:
.globl vector199
vector199:
  pushl $0
80105c32:	6a 00                	push   $0x0
  pushl $199
80105c34:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105c39:	e9 f5 f3 ff ff       	jmp    80105033 <alltraps>

80105c3e <vector200>:
.globl vector200
vector200:
  pushl $0
80105c3e:	6a 00                	push   $0x0
  pushl $200
80105c40:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105c45:	e9 e9 f3 ff ff       	jmp    80105033 <alltraps>

80105c4a <vector201>:
.globl vector201
vector201:
  pushl $0
80105c4a:	6a 00                	push   $0x0
  pushl $201
80105c4c:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105c51:	e9 dd f3 ff ff       	jmp    80105033 <alltraps>

80105c56 <vector202>:
.globl vector202
vector202:
  pushl $0
80105c56:	6a 00                	push   $0x0
  pushl $202
80105c58:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105c5d:	e9 d1 f3 ff ff       	jmp    80105033 <alltraps>

80105c62 <vector203>:
.globl vector203
vector203:
  pushl $0
80105c62:	6a 00                	push   $0x0
  pushl $203
80105c64:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105c69:	e9 c5 f3 ff ff       	jmp    80105033 <alltraps>

80105c6e <vector204>:
.globl vector204
vector204:
  pushl $0
80105c6e:	6a 00                	push   $0x0
  pushl $204
80105c70:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105c75:	e9 b9 f3 ff ff       	jmp    80105033 <alltraps>

80105c7a <vector205>:
.globl vector205
vector205:
  pushl $0
80105c7a:	6a 00                	push   $0x0
  pushl $205
80105c7c:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105c81:	e9 ad f3 ff ff       	jmp    80105033 <alltraps>

80105c86 <vector206>:
.globl vector206
vector206:
  pushl $0
80105c86:	6a 00                	push   $0x0
  pushl $206
80105c88:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105c8d:	e9 a1 f3 ff ff       	jmp    80105033 <alltraps>

80105c92 <vector207>:
.globl vector207
vector207:
  pushl $0
80105c92:	6a 00                	push   $0x0
  pushl $207
80105c94:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105c99:	e9 95 f3 ff ff       	jmp    80105033 <alltraps>

80105c9e <vector208>:
.globl vector208
vector208:
  pushl $0
80105c9e:	6a 00                	push   $0x0
  pushl $208
80105ca0:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105ca5:	e9 89 f3 ff ff       	jmp    80105033 <alltraps>

80105caa <vector209>:
.globl vector209
vector209:
  pushl $0
80105caa:	6a 00                	push   $0x0
  pushl $209
80105cac:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105cb1:	e9 7d f3 ff ff       	jmp    80105033 <alltraps>

80105cb6 <vector210>:
.globl vector210
vector210:
  pushl $0
80105cb6:	6a 00                	push   $0x0
  pushl $210
80105cb8:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105cbd:	e9 71 f3 ff ff       	jmp    80105033 <alltraps>

80105cc2 <vector211>:
.globl vector211
vector211:
  pushl $0
80105cc2:	6a 00                	push   $0x0
  pushl $211
80105cc4:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105cc9:	e9 65 f3 ff ff       	jmp    80105033 <alltraps>

80105cce <vector212>:
.globl vector212
vector212:
  pushl $0
80105cce:	6a 00                	push   $0x0
  pushl $212
80105cd0:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105cd5:	e9 59 f3 ff ff       	jmp    80105033 <alltraps>

80105cda <vector213>:
.globl vector213
vector213:
  pushl $0
80105cda:	6a 00                	push   $0x0
  pushl $213
80105cdc:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105ce1:	e9 4d f3 ff ff       	jmp    80105033 <alltraps>

80105ce6 <vector214>:
.globl vector214
vector214:
  pushl $0
80105ce6:	6a 00                	push   $0x0
  pushl $214
80105ce8:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105ced:	e9 41 f3 ff ff       	jmp    80105033 <alltraps>

80105cf2 <vector215>:
.globl vector215
vector215:
  pushl $0
80105cf2:	6a 00                	push   $0x0
  pushl $215
80105cf4:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105cf9:	e9 35 f3 ff ff       	jmp    80105033 <alltraps>

80105cfe <vector216>:
.globl vector216
vector216:
  pushl $0
80105cfe:	6a 00                	push   $0x0
  pushl $216
80105d00:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105d05:	e9 29 f3 ff ff       	jmp    80105033 <alltraps>

80105d0a <vector217>:
.globl vector217
vector217:
  pushl $0
80105d0a:	6a 00                	push   $0x0
  pushl $217
80105d0c:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105d11:	e9 1d f3 ff ff       	jmp    80105033 <alltraps>

80105d16 <vector218>:
.globl vector218
vector218:
  pushl $0
80105d16:	6a 00                	push   $0x0
  pushl $218
80105d18:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105d1d:	e9 11 f3 ff ff       	jmp    80105033 <alltraps>

80105d22 <vector219>:
.globl vector219
vector219:
  pushl $0
80105d22:	6a 00                	push   $0x0
  pushl $219
80105d24:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105d29:	e9 05 f3 ff ff       	jmp    80105033 <alltraps>

80105d2e <vector220>:
.globl vector220
vector220:
  pushl $0
80105d2e:	6a 00                	push   $0x0
  pushl $220
80105d30:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105d35:	e9 f9 f2 ff ff       	jmp    80105033 <alltraps>

80105d3a <vector221>:
.globl vector221
vector221:
  pushl $0
80105d3a:	6a 00                	push   $0x0
  pushl $221
80105d3c:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105d41:	e9 ed f2 ff ff       	jmp    80105033 <alltraps>

80105d46 <vector222>:
.globl vector222
vector222:
  pushl $0
80105d46:	6a 00                	push   $0x0
  pushl $222
80105d48:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105d4d:	e9 e1 f2 ff ff       	jmp    80105033 <alltraps>

80105d52 <vector223>:
.globl vector223
vector223:
  pushl $0
80105d52:	6a 00                	push   $0x0
  pushl $223
80105d54:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105d59:	e9 d5 f2 ff ff       	jmp    80105033 <alltraps>

80105d5e <vector224>:
.globl vector224
vector224:
  pushl $0
80105d5e:	6a 00                	push   $0x0
  pushl $224
80105d60:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105d65:	e9 c9 f2 ff ff       	jmp    80105033 <alltraps>

80105d6a <vector225>:
.globl vector225
vector225:
  pushl $0
80105d6a:	6a 00                	push   $0x0
  pushl $225
80105d6c:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105d71:	e9 bd f2 ff ff       	jmp    80105033 <alltraps>

80105d76 <vector226>:
.globl vector226
vector226:
  pushl $0
80105d76:	6a 00                	push   $0x0
  pushl $226
80105d78:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105d7d:	e9 b1 f2 ff ff       	jmp    80105033 <alltraps>

80105d82 <vector227>:
.globl vector227
vector227:
  pushl $0
80105d82:	6a 00                	push   $0x0
  pushl $227
80105d84:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105d89:	e9 a5 f2 ff ff       	jmp    80105033 <alltraps>

80105d8e <vector228>:
.globl vector228
vector228:
  pushl $0
80105d8e:	6a 00                	push   $0x0
  pushl $228
80105d90:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105d95:	e9 99 f2 ff ff       	jmp    80105033 <alltraps>

80105d9a <vector229>:
.globl vector229
vector229:
  pushl $0
80105d9a:	6a 00                	push   $0x0
  pushl $229
80105d9c:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105da1:	e9 8d f2 ff ff       	jmp    80105033 <alltraps>

80105da6 <vector230>:
.globl vector230
vector230:
  pushl $0
80105da6:	6a 00                	push   $0x0
  pushl $230
80105da8:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105dad:	e9 81 f2 ff ff       	jmp    80105033 <alltraps>

80105db2 <vector231>:
.globl vector231
vector231:
  pushl $0
80105db2:	6a 00                	push   $0x0
  pushl $231
80105db4:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105db9:	e9 75 f2 ff ff       	jmp    80105033 <alltraps>

80105dbe <vector232>:
.globl vector232
vector232:
  pushl $0
80105dbe:	6a 00                	push   $0x0
  pushl $232
80105dc0:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105dc5:	e9 69 f2 ff ff       	jmp    80105033 <alltraps>

80105dca <vector233>:
.globl vector233
vector233:
  pushl $0
80105dca:	6a 00                	push   $0x0
  pushl $233
80105dcc:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105dd1:	e9 5d f2 ff ff       	jmp    80105033 <alltraps>

80105dd6 <vector234>:
.globl vector234
vector234:
  pushl $0
80105dd6:	6a 00                	push   $0x0
  pushl $234
80105dd8:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105ddd:	e9 51 f2 ff ff       	jmp    80105033 <alltraps>

80105de2 <vector235>:
.globl vector235
vector235:
  pushl $0
80105de2:	6a 00                	push   $0x0
  pushl $235
80105de4:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105de9:	e9 45 f2 ff ff       	jmp    80105033 <alltraps>

80105dee <vector236>:
.globl vector236
vector236:
  pushl $0
80105dee:	6a 00                	push   $0x0
  pushl $236
80105df0:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105df5:	e9 39 f2 ff ff       	jmp    80105033 <alltraps>

80105dfa <vector237>:
.globl vector237
vector237:
  pushl $0
80105dfa:	6a 00                	push   $0x0
  pushl $237
80105dfc:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105e01:	e9 2d f2 ff ff       	jmp    80105033 <alltraps>

80105e06 <vector238>:
.globl vector238
vector238:
  pushl $0
80105e06:	6a 00                	push   $0x0
  pushl $238
80105e08:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105e0d:	e9 21 f2 ff ff       	jmp    80105033 <alltraps>

80105e12 <vector239>:
.globl vector239
vector239:
  pushl $0
80105e12:	6a 00                	push   $0x0
  pushl $239
80105e14:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105e19:	e9 15 f2 ff ff       	jmp    80105033 <alltraps>

80105e1e <vector240>:
.globl vector240
vector240:
  pushl $0
80105e1e:	6a 00                	push   $0x0
  pushl $240
80105e20:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105e25:	e9 09 f2 ff ff       	jmp    80105033 <alltraps>

80105e2a <vector241>:
.globl vector241
vector241:
  pushl $0
80105e2a:	6a 00                	push   $0x0
  pushl $241
80105e2c:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105e31:	e9 fd f1 ff ff       	jmp    80105033 <alltraps>

80105e36 <vector242>:
.globl vector242
vector242:
  pushl $0
80105e36:	6a 00                	push   $0x0
  pushl $242
80105e38:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105e3d:	e9 f1 f1 ff ff       	jmp    80105033 <alltraps>

80105e42 <vector243>:
.globl vector243
vector243:
  pushl $0
80105e42:	6a 00                	push   $0x0
  pushl $243
80105e44:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105e49:	e9 e5 f1 ff ff       	jmp    80105033 <alltraps>

80105e4e <vector244>:
.globl vector244
vector244:
  pushl $0
80105e4e:	6a 00                	push   $0x0
  pushl $244
80105e50:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105e55:	e9 d9 f1 ff ff       	jmp    80105033 <alltraps>

80105e5a <vector245>:
.globl vector245
vector245:
  pushl $0
80105e5a:	6a 00                	push   $0x0
  pushl $245
80105e5c:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105e61:	e9 cd f1 ff ff       	jmp    80105033 <alltraps>

80105e66 <vector246>:
.globl vector246
vector246:
  pushl $0
80105e66:	6a 00                	push   $0x0
  pushl $246
80105e68:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105e6d:	e9 c1 f1 ff ff       	jmp    80105033 <alltraps>

80105e72 <vector247>:
.globl vector247
vector247:
  pushl $0
80105e72:	6a 00                	push   $0x0
  pushl $247
80105e74:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105e79:	e9 b5 f1 ff ff       	jmp    80105033 <alltraps>

80105e7e <vector248>:
.globl vector248
vector248:
  pushl $0
80105e7e:	6a 00                	push   $0x0
  pushl $248
80105e80:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105e85:	e9 a9 f1 ff ff       	jmp    80105033 <alltraps>

80105e8a <vector249>:
.globl vector249
vector249:
  pushl $0
80105e8a:	6a 00                	push   $0x0
  pushl $249
80105e8c:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105e91:	e9 9d f1 ff ff       	jmp    80105033 <alltraps>

80105e96 <vector250>:
.globl vector250
vector250:
  pushl $0
80105e96:	6a 00                	push   $0x0
  pushl $250
80105e98:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105e9d:	e9 91 f1 ff ff       	jmp    80105033 <alltraps>

80105ea2 <vector251>:
.globl vector251
vector251:
  pushl $0
80105ea2:	6a 00                	push   $0x0
  pushl $251
80105ea4:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105ea9:	e9 85 f1 ff ff       	jmp    80105033 <alltraps>

80105eae <vector252>:
.globl vector252
vector252:
  pushl $0
80105eae:	6a 00                	push   $0x0
  pushl $252
80105eb0:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105eb5:	e9 79 f1 ff ff       	jmp    80105033 <alltraps>

80105eba <vector253>:
.globl vector253
vector253:
  pushl $0
80105eba:	6a 00                	push   $0x0
  pushl $253
80105ebc:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105ec1:	e9 6d f1 ff ff       	jmp    80105033 <alltraps>

80105ec6 <vector254>:
.globl vector254
vector254:
  pushl $0
80105ec6:	6a 00                	push   $0x0
  pushl $254
80105ec8:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105ecd:	e9 61 f1 ff ff       	jmp    80105033 <alltraps>

80105ed2 <vector255>:
.globl vector255
vector255:
  pushl $0
80105ed2:	6a 00                	push   $0x0
  pushl $255
80105ed4:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105ed9:	e9 55 f1 ff ff       	jmp    80105033 <alltraps>

80105ede <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105ede:	55                   	push   %ebp
80105edf:	89 e5                	mov    %esp,%ebp
80105ee1:	57                   	push   %edi
80105ee2:	56                   	push   %esi
80105ee3:	53                   	push   %ebx
80105ee4:	83 ec 0c             	sub    $0xc,%esp
80105ee7:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105ee9:	c1 ea 16             	shr    $0x16,%edx
80105eec:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105eef:	8b 1f                	mov    (%edi),%ebx
80105ef1:	f6 c3 01             	test   $0x1,%bl
80105ef4:	74 22                	je     80105f18 <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105ef6:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105efc:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105f02:	c1 ee 0c             	shr    $0xc,%esi
80105f05:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105f0b:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105f0e:	89 d8                	mov    %ebx,%eax
80105f10:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105f13:	5b                   	pop    %ebx
80105f14:	5e                   	pop    %esi
80105f15:	5f                   	pop    %edi
80105f16:	5d                   	pop    %ebp
80105f17:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc2(-2)) == 0)
80105f18:	85 c9                	test   %ecx,%ecx
80105f1a:	74 33                	je     80105f4f <walkpgdir+0x71>
80105f1c:	83 ec 0c             	sub    $0xc,%esp
80105f1f:	6a fe                	push   $0xfffffffe
80105f21:	e8 b6 c2 ff ff       	call   801021dc <kalloc2>
80105f26:	89 c3                	mov    %eax,%ebx
80105f28:	83 c4 10             	add    $0x10,%esp
80105f2b:	85 c0                	test   %eax,%eax
80105f2d:	74 df                	je     80105f0e <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105f2f:	83 ec 04             	sub    $0x4,%esp
80105f32:	68 00 10 00 00       	push   $0x1000
80105f37:	6a 00                	push   $0x0
80105f39:	50                   	push   %eax
80105f3a:	e8 f6 df ff ff       	call   80103f35 <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105f3f:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105f45:	83 c8 07             	or     $0x7,%eax
80105f48:	89 07                	mov    %eax,(%edi)
80105f4a:	83 c4 10             	add    $0x10,%esp
80105f4d:	eb b3                	jmp    80105f02 <walkpgdir+0x24>
      return 0;
80105f4f:	bb 00 00 00 00       	mov    $0x0,%ebx
80105f54:	eb b8                	jmp    80105f0e <walkpgdir+0x30>

80105f56 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105f56:	55                   	push   %ebp
80105f57:	89 e5                	mov    %esp,%ebp
80105f59:	57                   	push   %edi
80105f5a:	56                   	push   %esi
80105f5b:	53                   	push   %ebx
80105f5c:	83 ec 1c             	sub    $0x1c,%esp
80105f5f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105f62:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105f65:	89 d3                	mov    %edx,%ebx
80105f67:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105f6d:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105f71:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105f77:	b9 01 00 00 00       	mov    $0x1,%ecx
80105f7c:	89 da                	mov    %ebx,%edx
80105f7e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105f81:	e8 58 ff ff ff       	call   80105ede <walkpgdir>
80105f86:	85 c0                	test   %eax,%eax
80105f88:	74 2e                	je     80105fb8 <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105f8a:	f6 00 01             	testb  $0x1,(%eax)
80105f8d:	75 1c                	jne    80105fab <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105f8f:	89 f2                	mov    %esi,%edx
80105f91:	0b 55 0c             	or     0xc(%ebp),%edx
80105f94:	83 ca 01             	or     $0x1,%edx
80105f97:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105f99:	39 fb                	cmp    %edi,%ebx
80105f9b:	74 28                	je     80105fc5 <mappages+0x6f>
      break;
    a += PGSIZE;
80105f9d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105fa3:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105fa9:	eb cc                	jmp    80105f77 <mappages+0x21>
      panic("remap");
80105fab:	83 ec 0c             	sub    $0xc,%esp
80105fae:	68 8c 70 10 80       	push   $0x8010708c
80105fb3:	e8 90 a3 ff ff       	call   80100348 <panic>
      return -1;
80105fb8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105fbd:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105fc0:	5b                   	pop    %ebx
80105fc1:	5e                   	pop    %esi
80105fc2:	5f                   	pop    %edi
80105fc3:	5d                   	pop    %ebp
80105fc4:	c3                   	ret    
  return 0;
80105fc5:	b8 00 00 00 00       	mov    $0x0,%eax
80105fca:	eb f1                	jmp    80105fbd <mappages+0x67>

80105fcc <seginit>:
{
80105fcc:	55                   	push   %ebp
80105fcd:	89 e5                	mov    %esp,%ebp
80105fcf:	53                   	push   %ebx
80105fd0:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80105fd3:	e8 f4 d4 ff ff       	call   801034cc <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105fd8:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80105fde:	66 c7 80 38 28 13 80 	movw   $0xffff,-0x7fecd7c8(%eax)
80105fe5:	ff ff 
80105fe7:	66 c7 80 3a 28 13 80 	movw   $0x0,-0x7fecd7c6(%eax)
80105fee:	00 00 
80105ff0:	c6 80 3c 28 13 80 00 	movb   $0x0,-0x7fecd7c4(%eax)
80105ff7:	0f b6 88 3d 28 13 80 	movzbl -0x7fecd7c3(%eax),%ecx
80105ffe:	83 e1 f0             	and    $0xfffffff0,%ecx
80106001:	83 c9 1a             	or     $0x1a,%ecx
80106004:	83 e1 9f             	and    $0xffffff9f,%ecx
80106007:	83 c9 80             	or     $0xffffff80,%ecx
8010600a:	88 88 3d 28 13 80    	mov    %cl,-0x7fecd7c3(%eax)
80106010:	0f b6 88 3e 28 13 80 	movzbl -0x7fecd7c2(%eax),%ecx
80106017:	83 c9 0f             	or     $0xf,%ecx
8010601a:	83 e1 cf             	and    $0xffffffcf,%ecx
8010601d:	83 c9 c0             	or     $0xffffffc0,%ecx
80106020:	88 88 3e 28 13 80    	mov    %cl,-0x7fecd7c2(%eax)
80106026:	c6 80 3f 28 13 80 00 	movb   $0x0,-0x7fecd7c1(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
8010602d:	66 c7 80 40 28 13 80 	movw   $0xffff,-0x7fecd7c0(%eax)
80106034:	ff ff 
80106036:	66 c7 80 42 28 13 80 	movw   $0x0,-0x7fecd7be(%eax)
8010603d:	00 00 
8010603f:	c6 80 44 28 13 80 00 	movb   $0x0,-0x7fecd7bc(%eax)
80106046:	0f b6 88 45 28 13 80 	movzbl -0x7fecd7bb(%eax),%ecx
8010604d:	83 e1 f0             	and    $0xfffffff0,%ecx
80106050:	83 c9 12             	or     $0x12,%ecx
80106053:	83 e1 9f             	and    $0xffffff9f,%ecx
80106056:	83 c9 80             	or     $0xffffff80,%ecx
80106059:	88 88 45 28 13 80    	mov    %cl,-0x7fecd7bb(%eax)
8010605f:	0f b6 88 46 28 13 80 	movzbl -0x7fecd7ba(%eax),%ecx
80106066:	83 c9 0f             	or     $0xf,%ecx
80106069:	83 e1 cf             	and    $0xffffffcf,%ecx
8010606c:	83 c9 c0             	or     $0xffffffc0,%ecx
8010606f:	88 88 46 28 13 80    	mov    %cl,-0x7fecd7ba(%eax)
80106075:	c6 80 47 28 13 80 00 	movb   $0x0,-0x7fecd7b9(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
8010607c:	66 c7 80 48 28 13 80 	movw   $0xffff,-0x7fecd7b8(%eax)
80106083:	ff ff 
80106085:	66 c7 80 4a 28 13 80 	movw   $0x0,-0x7fecd7b6(%eax)
8010608c:	00 00 
8010608e:	c6 80 4c 28 13 80 00 	movb   $0x0,-0x7fecd7b4(%eax)
80106095:	c6 80 4d 28 13 80 fa 	movb   $0xfa,-0x7fecd7b3(%eax)
8010609c:	0f b6 88 4e 28 13 80 	movzbl -0x7fecd7b2(%eax),%ecx
801060a3:	83 c9 0f             	or     $0xf,%ecx
801060a6:	83 e1 cf             	and    $0xffffffcf,%ecx
801060a9:	83 c9 c0             	or     $0xffffffc0,%ecx
801060ac:	88 88 4e 28 13 80    	mov    %cl,-0x7fecd7b2(%eax)
801060b2:	c6 80 4f 28 13 80 00 	movb   $0x0,-0x7fecd7b1(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
801060b9:	66 c7 80 50 28 13 80 	movw   $0xffff,-0x7fecd7b0(%eax)
801060c0:	ff ff 
801060c2:	66 c7 80 52 28 13 80 	movw   $0x0,-0x7fecd7ae(%eax)
801060c9:	00 00 
801060cb:	c6 80 54 28 13 80 00 	movb   $0x0,-0x7fecd7ac(%eax)
801060d2:	c6 80 55 28 13 80 f2 	movb   $0xf2,-0x7fecd7ab(%eax)
801060d9:	0f b6 88 56 28 13 80 	movzbl -0x7fecd7aa(%eax),%ecx
801060e0:	83 c9 0f             	or     $0xf,%ecx
801060e3:	83 e1 cf             	and    $0xffffffcf,%ecx
801060e6:	83 c9 c0             	or     $0xffffffc0,%ecx
801060e9:	88 88 56 28 13 80    	mov    %cl,-0x7fecd7aa(%eax)
801060ef:	c6 80 57 28 13 80 00 	movb   $0x0,-0x7fecd7a9(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
801060f6:	05 30 28 13 80       	add    $0x80132830,%eax
  pd[0] = size-1;
801060fb:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80106101:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80106105:	c1 e8 10             	shr    $0x10,%eax
80106108:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
8010610c:	8d 45 f2             	lea    -0xe(%ebp),%eax
8010610f:	0f 01 10             	lgdtl  (%eax)
}
80106112:	83 c4 14             	add    $0x14,%esp
80106115:	5b                   	pop    %ebx
80106116:	5d                   	pop    %ebp
80106117:	c3                   	ret    

80106118 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80106118:	55                   	push   %ebp
80106119:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
8010611b:	a1 e4 54 13 80       	mov    0x801354e4,%eax
80106120:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80106125:	0f 22 d8             	mov    %eax,%cr3
}
80106128:	5d                   	pop    %ebp
80106129:	c3                   	ret    

8010612a <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
8010612a:	55                   	push   %ebp
8010612b:	89 e5                	mov    %esp,%ebp
8010612d:	57                   	push   %edi
8010612e:	56                   	push   %esi
8010612f:	53                   	push   %ebx
80106130:	83 ec 1c             	sub    $0x1c,%esp
80106133:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
80106136:	85 f6                	test   %esi,%esi
80106138:	0f 84 dd 00 00 00    	je     8010621b <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
8010613e:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
80106142:	0f 84 e0 00 00 00    	je     80106228 <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
80106148:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
8010614c:	0f 84 e3 00 00 00    	je     80106235 <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
80106152:	e8 55 dc ff ff       	call   80103dac <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80106157:	e8 14 d3 ff ff       	call   80103470 <mycpu>
8010615c:	89 c3                	mov    %eax,%ebx
8010615e:	e8 0d d3 ff ff       	call   80103470 <mycpu>
80106163:	8d 78 08             	lea    0x8(%eax),%edi
80106166:	e8 05 d3 ff ff       	call   80103470 <mycpu>
8010616b:	83 c0 08             	add    $0x8,%eax
8010616e:	c1 e8 10             	shr    $0x10,%eax
80106171:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106174:	e8 f7 d2 ff ff       	call   80103470 <mycpu>
80106179:	83 c0 08             	add    $0x8,%eax
8010617c:	c1 e8 18             	shr    $0x18,%eax
8010617f:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80106186:	67 00 
80106188:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
8010618f:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
80106193:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80106199:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
801061a0:	83 e2 f0             	and    $0xfffffff0,%edx
801061a3:	83 ca 19             	or     $0x19,%edx
801061a6:	83 e2 9f             	and    $0xffffff9f,%edx
801061a9:	83 ca 80             	or     $0xffffff80,%edx
801061ac:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
801061b2:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
801061b9:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
801061bf:	e8 ac d2 ff ff       	call   80103470 <mycpu>
801061c4:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801061cb:	83 e2 ef             	and    $0xffffffef,%edx
801061ce:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
801061d4:	e8 97 d2 ff ff       	call   80103470 <mycpu>
801061d9:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
801061df:	8b 5e 08             	mov    0x8(%esi),%ebx
801061e2:	e8 89 d2 ff ff       	call   80103470 <mycpu>
801061e7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801061ed:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
801061f0:	e8 7b d2 ff ff       	call   80103470 <mycpu>
801061f5:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
801061fb:	b8 28 00 00 00       	mov    $0x28,%eax
80106200:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
80106203:	8b 46 04             	mov    0x4(%esi),%eax
80106206:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010620b:	0f 22 d8             	mov    %eax,%cr3
  popcli();
8010620e:	e8 d6 db ff ff       	call   80103de9 <popcli>
}
80106213:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106216:	5b                   	pop    %ebx
80106217:	5e                   	pop    %esi
80106218:	5f                   	pop    %edi
80106219:	5d                   	pop    %ebp
8010621a:	c3                   	ret    
    panic("switchuvm: no process");
8010621b:	83 ec 0c             	sub    $0xc,%esp
8010621e:	68 92 70 10 80       	push   $0x80107092
80106223:	e8 20 a1 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
80106228:	83 ec 0c             	sub    $0xc,%esp
8010622b:	68 a8 70 10 80       	push   $0x801070a8
80106230:	e8 13 a1 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
80106235:	83 ec 0c             	sub    $0xc,%esp
80106238:	68 bd 70 10 80       	push   $0x801070bd
8010623d:	e8 06 a1 ff ff       	call   80100348 <panic>

80106242 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80106242:	55                   	push   %ebp
80106243:	89 e5                	mov    %esp,%ebp
80106245:	56                   	push   %esi
80106246:	53                   	push   %ebx
80106247:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
8010624a:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106250:	77 51                	ja     801062a3 <inituvm+0x61>
    panic("inituvm: more than a page");
  mem = kalloc2(-2);
80106252:	83 ec 0c             	sub    $0xc,%esp
80106255:	6a fe                	push   $0xfffffffe
80106257:	e8 80 bf ff ff       	call   801021dc <kalloc2>
8010625c:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
8010625e:	83 c4 0c             	add    $0xc,%esp
80106261:	68 00 10 00 00       	push   $0x1000
80106266:	6a 00                	push   $0x0
80106268:	50                   	push   %eax
80106269:	e8 c7 dc ff ff       	call   80103f35 <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
8010626e:	83 c4 08             	add    $0x8,%esp
80106271:	6a 06                	push   $0x6
80106273:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106279:	50                   	push   %eax
8010627a:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010627f:	ba 00 00 00 00       	mov    $0x0,%edx
80106284:	8b 45 08             	mov    0x8(%ebp),%eax
80106287:	e8 ca fc ff ff       	call   80105f56 <mappages>
  memmove(mem, init, sz);
8010628c:	83 c4 0c             	add    $0xc,%esp
8010628f:	56                   	push   %esi
80106290:	ff 75 0c             	pushl  0xc(%ebp)
80106293:	53                   	push   %ebx
80106294:	e8 17 dd ff ff       	call   80103fb0 <memmove>
}
80106299:	83 c4 10             	add    $0x10,%esp
8010629c:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010629f:	5b                   	pop    %ebx
801062a0:	5e                   	pop    %esi
801062a1:	5d                   	pop    %ebp
801062a2:	c3                   	ret    
    panic("inituvm: more than a page");
801062a3:	83 ec 0c             	sub    $0xc,%esp
801062a6:	68 d1 70 10 80       	push   $0x801070d1
801062ab:	e8 98 a0 ff ff       	call   80100348 <panic>

801062b0 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
801062b0:	55                   	push   %ebp
801062b1:	89 e5                	mov    %esp,%ebp
801062b3:	57                   	push   %edi
801062b4:	56                   	push   %esi
801062b5:	53                   	push   %ebx
801062b6:	83 ec 0c             	sub    $0xc,%esp
801062b9:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
801062bc:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
801062c3:	75 07                	jne    801062cc <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
801062c5:	bb 00 00 00 00       	mov    $0x0,%ebx
801062ca:	eb 3c                	jmp    80106308 <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
801062cc:	83 ec 0c             	sub    $0xc,%esp
801062cf:	68 8c 71 10 80       	push   $0x8010718c
801062d4:	e8 6f a0 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
801062d9:	83 ec 0c             	sub    $0xc,%esp
801062dc:	68 eb 70 10 80       	push   $0x801070eb
801062e1:	e8 62 a0 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
801062e6:	05 00 00 00 80       	add    $0x80000000,%eax
801062eb:	56                   	push   %esi
801062ec:	89 da                	mov    %ebx,%edx
801062ee:	03 55 14             	add    0x14(%ebp),%edx
801062f1:	52                   	push   %edx
801062f2:	50                   	push   %eax
801062f3:	ff 75 10             	pushl  0x10(%ebp)
801062f6:	e8 78 b4 ff ff       	call   80101773 <readi>
801062fb:	83 c4 10             	add    $0x10,%esp
801062fe:	39 f0                	cmp    %esi,%eax
80106300:	75 47                	jne    80106349 <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
80106302:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106308:	39 fb                	cmp    %edi,%ebx
8010630a:	73 30                	jae    8010633c <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
8010630c:	89 da                	mov    %ebx,%edx
8010630e:	03 55 0c             	add    0xc(%ebp),%edx
80106311:	b9 00 00 00 00       	mov    $0x0,%ecx
80106316:	8b 45 08             	mov    0x8(%ebp),%eax
80106319:	e8 c0 fb ff ff       	call   80105ede <walkpgdir>
8010631e:	85 c0                	test   %eax,%eax
80106320:	74 b7                	je     801062d9 <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
80106322:	8b 00                	mov    (%eax),%eax
80106324:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
80106329:	89 fe                	mov    %edi,%esi
8010632b:	29 de                	sub    %ebx,%esi
8010632d:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106333:	76 b1                	jbe    801062e6 <loaduvm+0x36>
      n = PGSIZE;
80106335:	be 00 10 00 00       	mov    $0x1000,%esi
8010633a:	eb aa                	jmp    801062e6 <loaduvm+0x36>
      return -1;
  }
  return 0;
8010633c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106341:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106344:	5b                   	pop    %ebx
80106345:	5e                   	pop    %esi
80106346:	5f                   	pop    %edi
80106347:	5d                   	pop    %ebp
80106348:	c3                   	ret    
      return -1;
80106349:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010634e:	eb f1                	jmp    80106341 <loaduvm+0x91>

80106350 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80106350:	55                   	push   %ebp
80106351:	89 e5                	mov    %esp,%ebp
80106353:	57                   	push   %edi
80106354:	56                   	push   %esi
80106355:	53                   	push   %ebx
80106356:	83 ec 0c             	sub    $0xc,%esp
80106359:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
8010635c:	39 7d 10             	cmp    %edi,0x10(%ebp)
8010635f:	73 11                	jae    80106372 <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
80106361:	8b 45 10             	mov    0x10(%ebp),%eax
80106364:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
8010636a:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106370:	eb 19                	jmp    8010638b <deallocuvm+0x3b>
    return oldsz;
80106372:	89 f8                	mov    %edi,%eax
80106374:	eb 64                	jmp    801063da <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
80106376:	c1 eb 16             	shr    $0x16,%ebx
80106379:	83 c3 01             	add    $0x1,%ebx
8010637c:	c1 e3 16             	shl    $0x16,%ebx
8010637f:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106385:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010638b:	39 fb                	cmp    %edi,%ebx
8010638d:	73 48                	jae    801063d7 <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
8010638f:	b9 00 00 00 00       	mov    $0x0,%ecx
80106394:	89 da                	mov    %ebx,%edx
80106396:	8b 45 08             	mov    0x8(%ebp),%eax
80106399:	e8 40 fb ff ff       	call   80105ede <walkpgdir>
8010639e:	89 c6                	mov    %eax,%esi
    if(!pte)
801063a0:	85 c0                	test   %eax,%eax
801063a2:	74 d2                	je     80106376 <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
801063a4:	8b 00                	mov    (%eax),%eax
801063a6:	a8 01                	test   $0x1,%al
801063a8:	74 db                	je     80106385 <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
801063aa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801063af:	74 19                	je     801063ca <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
801063b1:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801063b6:	83 ec 0c             	sub    $0xc,%esp
801063b9:	50                   	push   %eax
801063ba:	e8 06 bd ff ff       	call   801020c5 <kfree>
      *pte = 0;
801063bf:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
801063c5:	83 c4 10             	add    $0x10,%esp
801063c8:	eb bb                	jmp    80106385 <deallocuvm+0x35>
        panic("kfree");
801063ca:	83 ec 0c             	sub    $0xc,%esp
801063cd:	68 26 6a 10 80       	push   $0x80106a26
801063d2:	e8 71 9f ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
801063d7:	8b 45 10             	mov    0x10(%ebp),%eax
}
801063da:	8d 65 f4             	lea    -0xc(%ebp),%esp
801063dd:	5b                   	pop    %ebx
801063de:	5e                   	pop    %esi
801063df:	5f                   	pop    %edi
801063e0:	5d                   	pop    %ebp
801063e1:	c3                   	ret    

801063e2 <allocuvm>:
{
801063e2:	55                   	push   %ebp
801063e3:	89 e5                	mov    %esp,%ebp
801063e5:	57                   	push   %edi
801063e6:	56                   	push   %esi
801063e7:	53                   	push   %ebx
801063e8:	83 ec 1c             	sub    $0x1c,%esp
801063eb:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
801063ee:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801063f1:	85 ff                	test   %edi,%edi
801063f3:	0f 88 cf 00 00 00    	js     801064c8 <allocuvm+0xe6>
  if(newsz < oldsz)
801063f9:	3b 7d 0c             	cmp    0xc(%ebp),%edi
801063fc:	72 6a                	jb     80106468 <allocuvm+0x86>
  a = PGROUNDUP(oldsz);
801063fe:	8b 45 0c             	mov    0xc(%ebp),%eax
80106401:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106407:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
8010640d:	39 fb                	cmp    %edi,%ebx
8010640f:	0f 83 ba 00 00 00    	jae    801064cf <allocuvm+0xed>
    mem = kalloc2(myproc()->pid);
80106415:	e8 cd d0 ff ff       	call   801034e7 <myproc>
8010641a:	83 ec 0c             	sub    $0xc,%esp
8010641d:	ff 70 10             	pushl  0x10(%eax)
80106420:	e8 b7 bd ff ff       	call   801021dc <kalloc2>
80106425:	89 c6                	mov    %eax,%esi
    if(mem == 0){
80106427:	83 c4 10             	add    $0x10,%esp
8010642a:	85 c0                	test   %eax,%eax
8010642c:	74 42                	je     80106470 <allocuvm+0x8e>
    memset(mem, 0, PGSIZE);
8010642e:	83 ec 04             	sub    $0x4,%esp
80106431:	68 00 10 00 00       	push   $0x1000
80106436:	6a 00                	push   $0x0
80106438:	50                   	push   %eax
80106439:	e8 f7 da ff ff       	call   80103f35 <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
8010643e:	83 c4 08             	add    $0x8,%esp
80106441:	6a 06                	push   $0x6
80106443:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
80106449:	50                   	push   %eax
8010644a:	b9 00 10 00 00       	mov    $0x1000,%ecx
8010644f:	89 da                	mov    %ebx,%edx
80106451:	8b 45 08             	mov    0x8(%ebp),%eax
80106454:	e8 fd fa ff ff       	call   80105f56 <mappages>
80106459:	83 c4 10             	add    $0x10,%esp
8010645c:	85 c0                	test   %eax,%eax
8010645e:	78 38                	js     80106498 <allocuvm+0xb6>
  for(; a < newsz; a += PGSIZE){
80106460:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106466:	eb a5                	jmp    8010640d <allocuvm+0x2b>
    return oldsz;
80106468:	8b 45 0c             	mov    0xc(%ebp),%eax
8010646b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010646e:	eb 5f                	jmp    801064cf <allocuvm+0xed>
      cprintf("allocuvm out of memory\n");
80106470:	83 ec 0c             	sub    $0xc,%esp
80106473:	68 09 71 10 80       	push   $0x80107109
80106478:	e8 8e a1 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010647d:	83 c4 0c             	add    $0xc,%esp
80106480:	ff 75 0c             	pushl  0xc(%ebp)
80106483:	57                   	push   %edi
80106484:	ff 75 08             	pushl  0x8(%ebp)
80106487:	e8 c4 fe ff ff       	call   80106350 <deallocuvm>
      return 0;
8010648c:	83 c4 10             	add    $0x10,%esp
8010648f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80106496:	eb 37                	jmp    801064cf <allocuvm+0xed>
      cprintf("allocuvm out of memory (2)\n");
80106498:	83 ec 0c             	sub    $0xc,%esp
8010649b:	68 21 71 10 80       	push   $0x80107121
801064a0:	e8 66 a1 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801064a5:	83 c4 0c             	add    $0xc,%esp
801064a8:	ff 75 0c             	pushl  0xc(%ebp)
801064ab:	57                   	push   %edi
801064ac:	ff 75 08             	pushl  0x8(%ebp)
801064af:	e8 9c fe ff ff       	call   80106350 <deallocuvm>
      kfree(mem);
801064b4:	89 34 24             	mov    %esi,(%esp)
801064b7:	e8 09 bc ff ff       	call   801020c5 <kfree>
      return 0;
801064bc:	83 c4 10             	add    $0x10,%esp
801064bf:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801064c6:	eb 07                	jmp    801064cf <allocuvm+0xed>
    return 0;
801064c8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
801064cf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801064d2:	8d 65 f4             	lea    -0xc(%ebp),%esp
801064d5:	5b                   	pop    %ebx
801064d6:	5e                   	pop    %esi
801064d7:	5f                   	pop    %edi
801064d8:	5d                   	pop    %ebp
801064d9:	c3                   	ret    

801064da <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801064da:	55                   	push   %ebp
801064db:	89 e5                	mov    %esp,%ebp
801064dd:	56                   	push   %esi
801064de:	53                   	push   %ebx
801064df:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
801064e2:	85 f6                	test   %esi,%esi
801064e4:	74 1a                	je     80106500 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
801064e6:	83 ec 04             	sub    $0x4,%esp
801064e9:	6a 00                	push   $0x0
801064eb:	68 00 00 00 80       	push   $0x80000000
801064f0:	56                   	push   %esi
801064f1:	e8 5a fe ff ff       	call   80106350 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
801064f6:	83 c4 10             	add    $0x10,%esp
801064f9:	bb 00 00 00 00       	mov    $0x0,%ebx
801064fe:	eb 10                	jmp    80106510 <freevm+0x36>
    panic("freevm: no pgdir");
80106500:	83 ec 0c             	sub    $0xc,%esp
80106503:	68 3d 71 10 80       	push   $0x8010713d
80106508:	e8 3b 9e ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
8010650d:	83 c3 01             	add    $0x1,%ebx
80106510:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
80106516:	77 1f                	ja     80106537 <freevm+0x5d>
    if(pgdir[i] & PTE_P){
80106518:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
8010651b:	a8 01                	test   $0x1,%al
8010651d:	74 ee                	je     8010650d <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
8010651f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106524:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106529:	83 ec 0c             	sub    $0xc,%esp
8010652c:	50                   	push   %eax
8010652d:	e8 93 bb ff ff       	call   801020c5 <kfree>
80106532:	83 c4 10             	add    $0x10,%esp
80106535:	eb d6                	jmp    8010650d <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
80106537:	83 ec 0c             	sub    $0xc,%esp
8010653a:	56                   	push   %esi
8010653b:	e8 85 bb ff ff       	call   801020c5 <kfree>
}
80106540:	83 c4 10             	add    $0x10,%esp
80106543:	8d 65 f8             	lea    -0x8(%ebp),%esp
80106546:	5b                   	pop    %ebx
80106547:	5e                   	pop    %esi
80106548:	5d                   	pop    %ebp
80106549:	c3                   	ret    

8010654a <setupkvm>:
{
8010654a:	55                   	push   %ebp
8010654b:	89 e5                	mov    %esp,%ebp
8010654d:	56                   	push   %esi
8010654e:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc2(-2)) == 0)
8010654f:	83 ec 0c             	sub    $0xc,%esp
80106552:	6a fe                	push   $0xfffffffe
80106554:	e8 83 bc ff ff       	call   801021dc <kalloc2>
80106559:	89 c6                	mov    %eax,%esi
8010655b:	83 c4 10             	add    $0x10,%esp
8010655e:	85 c0                	test   %eax,%eax
80106560:	74 55                	je     801065b7 <setupkvm+0x6d>
  memset(pgdir, 0, PGSIZE);
80106562:	83 ec 04             	sub    $0x4,%esp
80106565:	68 00 10 00 00       	push   $0x1000
8010656a:	6a 00                	push   $0x0
8010656c:	50                   	push   %eax
8010656d:	e8 c3 d9 ff ff       	call   80103f35 <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106572:	83 c4 10             	add    $0x10,%esp
80106575:	bb 20 a4 12 80       	mov    $0x8012a420,%ebx
8010657a:	81 fb 60 a4 12 80    	cmp    $0x8012a460,%ebx
80106580:	73 35                	jae    801065b7 <setupkvm+0x6d>
                (uint)k->phys_start, k->perm) < 0) {
80106582:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
80106585:	8b 4b 08             	mov    0x8(%ebx),%ecx
80106588:	29 c1                	sub    %eax,%ecx
8010658a:	83 ec 08             	sub    $0x8,%esp
8010658d:	ff 73 0c             	pushl  0xc(%ebx)
80106590:	50                   	push   %eax
80106591:	8b 13                	mov    (%ebx),%edx
80106593:	89 f0                	mov    %esi,%eax
80106595:	e8 bc f9 ff ff       	call   80105f56 <mappages>
8010659a:	83 c4 10             	add    $0x10,%esp
8010659d:	85 c0                	test   %eax,%eax
8010659f:	78 05                	js     801065a6 <setupkvm+0x5c>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801065a1:	83 c3 10             	add    $0x10,%ebx
801065a4:	eb d4                	jmp    8010657a <setupkvm+0x30>
      freevm(pgdir);
801065a6:	83 ec 0c             	sub    $0xc,%esp
801065a9:	56                   	push   %esi
801065aa:	e8 2b ff ff ff       	call   801064da <freevm>
      return 0;
801065af:	83 c4 10             	add    $0x10,%esp
801065b2:	be 00 00 00 00       	mov    $0x0,%esi
}
801065b7:	89 f0                	mov    %esi,%eax
801065b9:	8d 65 f8             	lea    -0x8(%ebp),%esp
801065bc:	5b                   	pop    %ebx
801065bd:	5e                   	pop    %esi
801065be:	5d                   	pop    %ebp
801065bf:	c3                   	ret    

801065c0 <kvmalloc>:
{
801065c0:	55                   	push   %ebp
801065c1:	89 e5                	mov    %esp,%ebp
801065c3:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
801065c6:	e8 7f ff ff ff       	call   8010654a <setupkvm>
801065cb:	a3 e4 54 13 80       	mov    %eax,0x801354e4
  switchkvm();
801065d0:	e8 43 fb ff ff       	call   80106118 <switchkvm>
}
801065d5:	c9                   	leave  
801065d6:	c3                   	ret    

801065d7 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801065d7:	55                   	push   %ebp
801065d8:	89 e5                	mov    %esp,%ebp
801065da:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801065dd:	b9 00 00 00 00       	mov    $0x0,%ecx
801065e2:	8b 55 0c             	mov    0xc(%ebp),%edx
801065e5:	8b 45 08             	mov    0x8(%ebp),%eax
801065e8:	e8 f1 f8 ff ff       	call   80105ede <walkpgdir>
  if(pte == 0)
801065ed:	85 c0                	test   %eax,%eax
801065ef:	74 05                	je     801065f6 <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
801065f1:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
801065f4:	c9                   	leave  
801065f5:	c3                   	ret    
    panic("clearpteu");
801065f6:	83 ec 0c             	sub    $0xc,%esp
801065f9:	68 4e 71 10 80       	push   $0x8010714e
801065fe:	e8 45 9d ff ff       	call   80100348 <panic>

80106603 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz, uint childPid)
{
80106603:	55                   	push   %ebp
80106604:	89 e5                	mov    %esp,%ebp
80106606:	57                   	push   %edi
80106607:	56                   	push   %esi
80106608:	53                   	push   %ebx
80106609:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
8010660c:	e8 39 ff ff ff       	call   8010654a <setupkvm>
80106611:	89 45 dc             	mov    %eax,-0x24(%ebp)
80106614:	85 c0                	test   %eax,%eax
80106616:	0f 84 d1 00 00 00    	je     801066ed <copyuvm+0xea>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
8010661c:	bf 00 00 00 00       	mov    $0x0,%edi
80106621:	89 fe                	mov    %edi,%esi
80106623:	3b 75 0c             	cmp    0xc(%ebp),%esi
80106626:	0f 83 c1 00 00 00    	jae    801066ed <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
8010662c:	89 75 e4             	mov    %esi,-0x1c(%ebp)
8010662f:	b9 00 00 00 00       	mov    $0x0,%ecx
80106634:	89 f2                	mov    %esi,%edx
80106636:	8b 45 08             	mov    0x8(%ebp),%eax
80106639:	e8 a0 f8 ff ff       	call   80105ede <walkpgdir>
8010663e:	85 c0                	test   %eax,%eax
80106640:	74 70                	je     801066b2 <copyuvm+0xaf>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
80106642:	8b 18                	mov    (%eax),%ebx
80106644:	f6 c3 01             	test   $0x1,%bl
80106647:	74 76                	je     801066bf <copyuvm+0xbc>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
80106649:	89 df                	mov    %ebx,%edi
8010664b:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
    flags = PTE_FLAGS(*pte);
80106651:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
80106657:	89 5d e0             	mov    %ebx,-0x20(%ebp)
    if((mem = kalloc2(childPid)) == 0)
8010665a:	83 ec 0c             	sub    $0xc,%esp
8010665d:	ff 75 10             	pushl  0x10(%ebp)
80106660:	e8 77 bb ff ff       	call   801021dc <kalloc2>
80106665:	89 c3                	mov    %eax,%ebx
80106667:	83 c4 10             	add    $0x10,%esp
8010666a:	85 c0                	test   %eax,%eax
8010666c:	74 6a                	je     801066d8 <copyuvm+0xd5>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
8010666e:	81 c7 00 00 00 80    	add    $0x80000000,%edi
80106674:	83 ec 04             	sub    $0x4,%esp
80106677:	68 00 10 00 00       	push   $0x1000
8010667c:	57                   	push   %edi
8010667d:	50                   	push   %eax
8010667e:	e8 2d d9 ff ff       	call   80103fb0 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
80106683:	83 c4 08             	add    $0x8,%esp
80106686:	ff 75 e0             	pushl  -0x20(%ebp)
80106689:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
8010668f:	50                   	push   %eax
80106690:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106695:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106698:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010669b:	e8 b6 f8 ff ff       	call   80105f56 <mappages>
801066a0:	83 c4 10             	add    $0x10,%esp
801066a3:	85 c0                	test   %eax,%eax
801066a5:	78 25                	js     801066cc <copyuvm+0xc9>
  for(i = 0; i < sz; i += PGSIZE){
801066a7:	81 c6 00 10 00 00    	add    $0x1000,%esi
801066ad:	e9 71 ff ff ff       	jmp    80106623 <copyuvm+0x20>
      panic("copyuvm: pte should exist");
801066b2:	83 ec 0c             	sub    $0xc,%esp
801066b5:	68 58 71 10 80       	push   $0x80107158
801066ba:	e8 89 9c ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
801066bf:	83 ec 0c             	sub    $0xc,%esp
801066c2:	68 72 71 10 80       	push   $0x80107172
801066c7:	e8 7c 9c ff ff       	call   80100348 <panic>
      kfree(mem);
801066cc:	83 ec 0c             	sub    $0xc,%esp
801066cf:	53                   	push   %ebx
801066d0:	e8 f0 b9 ff ff       	call   801020c5 <kfree>
      goto bad;
801066d5:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
801066d8:	83 ec 0c             	sub    $0xc,%esp
801066db:	ff 75 dc             	pushl  -0x24(%ebp)
801066de:	e8 f7 fd ff ff       	call   801064da <freevm>
  return 0;
801066e3:	83 c4 10             	add    $0x10,%esp
801066e6:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
801066ed:	8b 45 dc             	mov    -0x24(%ebp),%eax
801066f0:	8d 65 f4             	lea    -0xc(%ebp),%esp
801066f3:	5b                   	pop    %ebx
801066f4:	5e                   	pop    %esi
801066f5:	5f                   	pop    %edi
801066f6:	5d                   	pop    %ebp
801066f7:	c3                   	ret    

801066f8 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801066f8:	55                   	push   %ebp
801066f9:	89 e5                	mov    %esp,%ebp
801066fb:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801066fe:	b9 00 00 00 00       	mov    $0x0,%ecx
80106703:	8b 55 0c             	mov    0xc(%ebp),%edx
80106706:	8b 45 08             	mov    0x8(%ebp),%eax
80106709:	e8 d0 f7 ff ff       	call   80105ede <walkpgdir>
  if((*pte & PTE_P) == 0)
8010670e:	8b 00                	mov    (%eax),%eax
80106710:	a8 01                	test   $0x1,%al
80106712:	74 10                	je     80106724 <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
80106714:	a8 04                	test   $0x4,%al
80106716:	74 13                	je     8010672b <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
80106718:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010671d:	05 00 00 00 80       	add    $0x80000000,%eax
}
80106722:	c9                   	leave  
80106723:	c3                   	ret    
    return 0;
80106724:	b8 00 00 00 00       	mov    $0x0,%eax
80106729:	eb f7                	jmp    80106722 <uva2ka+0x2a>
    return 0;
8010672b:	b8 00 00 00 00       	mov    $0x0,%eax
80106730:	eb f0                	jmp    80106722 <uva2ka+0x2a>

80106732 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80106732:	55                   	push   %ebp
80106733:	89 e5                	mov    %esp,%ebp
80106735:	57                   	push   %edi
80106736:	56                   	push   %esi
80106737:	53                   	push   %ebx
80106738:	83 ec 0c             	sub    $0xc,%esp
8010673b:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
8010673e:	eb 25                	jmp    80106765 <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
80106740:	8b 55 0c             	mov    0xc(%ebp),%edx
80106743:	29 f2                	sub    %esi,%edx
80106745:	01 d0                	add    %edx,%eax
80106747:	83 ec 04             	sub    $0x4,%esp
8010674a:	53                   	push   %ebx
8010674b:	ff 75 10             	pushl  0x10(%ebp)
8010674e:	50                   	push   %eax
8010674f:	e8 5c d8 ff ff       	call   80103fb0 <memmove>
    len -= n;
80106754:	29 df                	sub    %ebx,%edi
    buf += n;
80106756:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
80106759:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
8010675f:	89 45 0c             	mov    %eax,0xc(%ebp)
80106762:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
80106765:	85 ff                	test   %edi,%edi
80106767:	74 2f                	je     80106798 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
80106769:	8b 75 0c             	mov    0xc(%ebp),%esi
8010676c:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
80106772:	83 ec 08             	sub    $0x8,%esp
80106775:	56                   	push   %esi
80106776:	ff 75 08             	pushl  0x8(%ebp)
80106779:	e8 7a ff ff ff       	call   801066f8 <uva2ka>
    if(pa0 == 0)
8010677e:	83 c4 10             	add    $0x10,%esp
80106781:	85 c0                	test   %eax,%eax
80106783:	74 20                	je     801067a5 <copyout+0x73>
    n = PGSIZE - (va - va0);
80106785:	89 f3                	mov    %esi,%ebx
80106787:	2b 5d 0c             	sub    0xc(%ebp),%ebx
8010678a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
80106790:	39 df                	cmp    %ebx,%edi
80106792:	73 ac                	jae    80106740 <copyout+0xe>
      n = len;
80106794:	89 fb                	mov    %edi,%ebx
80106796:	eb a8                	jmp    80106740 <copyout+0xe>
  }
  return 0;
80106798:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010679d:	8d 65 f4             	lea    -0xc(%ebp),%esp
801067a0:	5b                   	pop    %ebx
801067a1:	5e                   	pop    %esi
801067a2:	5f                   	pop    %edi
801067a3:	5d                   	pop    %ebp
801067a4:	c3                   	ret    
      return -1;
801067a5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067aa:	eb f1                	jmp    8010679d <copyout+0x6b>
