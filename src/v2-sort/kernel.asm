
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
8010002d:	b8 8e 2d 10 80       	mov    $0x80102d8e,%eax
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
80100046:	e8 85 3e 00 00       	call   80103ed0 <acquire>

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
8010007c:	e8 b4 3e 00 00       	call   80103f35 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 30 3c 00 00       	call   80103cbc <acquiresleep>
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
801000ca:	e8 66 3e 00 00       	call   80103f35 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 e2 3b 00 00       	call   80103cbc <acquiresleep>
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
801000ea:	68 e0 67 10 80       	push   $0x801067e0
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 f1 67 10 80       	push   $0x801067f1
80100100:	68 c0 b5 10 80       	push   $0x8010b5c0
80100105:	e8 8a 3c 00 00       	call   80103d94 <initlock>
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
8010013a:	68 f8 67 10 80       	push   $0x801067f8
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 41 3b 00 00       	call   80103c89 <initsleeplock>
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
801001a8:	e8 99 3b 00 00       	call   80103d46 <holdingsleep>
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
801001cb:	68 ff 67 10 80       	push   $0x801067ff
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
801001e4:	e8 5d 3b 00 00       	call   80103d46 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 12 3b 00 00       	call   80103d0b <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100200:	e8 cb 3c 00 00       	call   80103ed0 <acquire>
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
8010024c:	e8 e4 3c 00 00       	call   80103f35 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 06 68 10 80       	push   $0x80106806
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
8010028a:	e8 41 3c 00 00       	call   80103ed0 <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 a0 ff 10 80       	mov    0x8010ffa0,%eax
8010029f:	3b 05 a4 ff 10 80    	cmp    0x8010ffa4,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 82 32 00 00       	call   8010352e <myproc>
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
801002bf:	e8 11 37 00 00       	call   801039d5 <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 a5 10 80       	push   $0x8010a520
801002d1:	e8 5f 3c 00 00       	call   80103f35 <release>
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
80100331:	e8 ff 3b 00 00       	call   80103f35 <release>
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
8010035a:	e8 44 23 00 00       	call   801026a3 <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 0d 68 10 80       	push   $0x8010680d
80100368:	e8 9e 02 00 00       	call   8010060b <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	pushl  0x8(%ebp)
80100373:	e8 93 02 00 00       	call   8010060b <cprintf>
  cprintf("\n");
80100378:	c7 04 24 5b 71 10 80 	movl   $0x8010715b,(%esp)
8010037f:	e8 87 02 00 00       	call   8010060b <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 1b 3a 00 00       	call   80103daf <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	pushl  -0x30(%ebp,%ebx,4)
801003a5:	68 21 68 10 80       	push   $0x80106821
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
8010049e:	68 25 68 10 80       	push   $0x80106825
801004a3:	e8 a0 fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801004a8:	83 ec 04             	sub    $0x4,%esp
801004ab:	68 60 0e 00 00       	push   $0xe60
801004b0:	68 a0 80 0b 80       	push   $0x800b80a0
801004b5:	68 00 80 0b 80       	push   $0x800b8000
801004ba:	e8 38 3b 00 00       	call   80103ff7 <memmove>
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
801004d9:	e8 9e 3a 00 00       	call   80103f7c <memset>
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
80100506:	e8 ab 4e 00 00       	call   801053b6 <uartputc>
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
8010051f:	e8 92 4e 00 00       	call   801053b6 <uartputc>
80100524:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010052b:	e8 86 4e 00 00       	call   801053b6 <uartputc>
80100530:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100537:	e8 7a 4e 00 00       	call   801053b6 <uartputc>
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
80100576:	0f b6 92 50 68 10 80 	movzbl -0x7fef97b0(%edx),%edx
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
801005ca:	e8 01 39 00 00       	call   80103ed0 <acquire>
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
801005f1:	e8 3f 39 00 00       	call   80103f35 <release>
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
80100638:	e8 93 38 00 00       	call   80103ed0 <acquire>
8010063d:	83 c4 10             	add    $0x10,%esp
80100640:	eb de                	jmp    80100620 <cprintf+0x15>
    panic("null fmt");
80100642:	83 ec 0c             	sub    $0xc,%esp
80100645:	68 3f 68 10 80       	push   $0x8010683f
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
801006ee:	be 38 68 10 80       	mov    $0x80106838,%esi
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
80100734:	e8 fc 37 00 00       	call   80103f35 <release>
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
8010074f:	e8 7c 37 00 00       	call   80103ed0 <acquire>
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
801007de:	e8 57 33 00 00       	call   80103b3a <wakeup>
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
80100873:	e8 bd 36 00 00       	call   80103f35 <release>
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
80100887:	e8 4b 33 00 00       	call   80103bd7 <procdump>
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
80100894:	68 48 68 10 80       	push   $0x80106848
80100899:	68 20 a5 10 80       	push   $0x8010a520
8010089e:	e8 f1 34 00 00       	call   80103d94 <initlock>

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
801008de:	e8 4b 2c 00 00       	call   8010352e <myproc>
801008e3:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)

  begin_op();
801008e9:	e8 e5 21 00 00       	call   80102ad3 <begin_op>

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
80100935:	e8 13 22 00 00       	call   80102b4d <end_op>
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
8010094a:	e8 fe 21 00 00       	call   80102b4d <end_op>
    cprintf("exec: fail\n");
8010094f:	83 ec 0c             	sub    $0xc,%esp
80100952:	68 61 68 10 80       	push   $0x80106861
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
80100972:	e8 08 5c 00 00       	call   8010657f <setupkvm>
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
80100a0c:	e8 0b 5a 00 00       	call   8010641c <allocuvm>
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
80100a3e:	e8 a7 58 00 00       	call   801062ea <loaduvm>
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
80100a59:	e8 ef 20 00 00       	call   80102b4d <end_op>
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
80100a80:	e8 97 59 00 00       	call   8010641c <allocuvm>
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
80100aa9:	e8 61 5a 00 00       	call   8010650f <freevm>
80100aae:	83 c4 10             	add    $0x10,%esp
80100ab1:	e9 6e fe ff ff       	jmp    80100924 <exec+0x52>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100ab6:	89 c7                	mov    %eax,%edi
80100ab8:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100abe:	83 ec 08             	sub    $0x8,%esp
80100ac1:	50                   	push   %eax
80100ac2:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100ac8:	e8 37 5b 00 00       	call   80106604 <clearpteu>
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
80100aee:	e8 2b 36 00 00       	call   8010411e <strlen>
80100af3:	29 c7                	sub    %eax,%edi
80100af5:	83 ef 01             	sub    $0x1,%edi
80100af8:	83 e7 fc             	and    $0xfffffffc,%edi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100afb:	83 c4 04             	add    $0x4,%esp
80100afe:	ff 33                	pushl  (%ebx)
80100b00:	e8 19 36 00 00       	call   8010411e <strlen>
80100b05:	83 c0 01             	add    $0x1,%eax
80100b08:	50                   	push   %eax
80100b09:	ff 33                	pushl  (%ebx)
80100b0b:	57                   	push   %edi
80100b0c:	ff b5 ec fe ff ff    	pushl  -0x114(%ebp)
80100b12:	e8 48 5c 00 00       	call   8010675f <copyout>
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
80100b72:	e8 e8 5b 00 00       	call   8010675f <copyout>
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
80100baf:	e8 2f 35 00 00       	call   801040e3 <safestrcpy>
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
80100bdd:	e8 87 55 00 00       	call   80106169 <switchuvm>
  freevm(oldpgdir);
80100be2:	89 1c 24             	mov    %ebx,(%esp)
80100be5:	e8 25 59 00 00       	call   8010650f <freevm>
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
80100c25:	68 6d 68 10 80       	push   $0x8010686d
80100c2a:	68 c0 ff 10 80       	push   $0x8010ffc0
80100c2f:	e8 60 31 00 00       	call   80103d94 <initlock>
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
80100c45:	e8 86 32 00 00       	call   80103ed0 <acquire>
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
80100c74:	e8 bc 32 00 00       	call   80103f35 <release>
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
80100c8b:	e8 a5 32 00 00       	call   80103f35 <release>
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
80100ca9:	e8 22 32 00 00       	call   80103ed0 <acquire>
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
80100cc6:	e8 6a 32 00 00       	call   80103f35 <release>
  return f;
}
80100ccb:	89 d8                	mov    %ebx,%eax
80100ccd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cd0:	c9                   	leave  
80100cd1:	c3                   	ret    
    panic("filedup");
80100cd2:	83 ec 0c             	sub    $0xc,%esp
80100cd5:	68 74 68 10 80       	push   $0x80106874
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
80100cee:	e8 dd 31 00 00       	call   80103ed0 <acquire>
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
80100d0f:	e8 21 32 00 00       	call   80103f35 <release>
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
80100d1f:	68 7c 68 10 80       	push   $0x8010687c
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
80100d55:	e8 db 31 00 00       	call   80103f35 <release>
  if(ff.type == FD_PIPE)
80100d5a:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d5d:	83 c4 10             	add    $0x10,%esp
80100d60:	83 f8 01             	cmp    $0x1,%eax
80100d63:	74 1f                	je     80100d84 <fileclose+0xa5>
  else if(ff.type == FD_INODE){
80100d65:	83 f8 02             	cmp    $0x2,%eax
80100d68:	75 ad                	jne    80100d17 <fileclose+0x38>
    begin_op();
80100d6a:	e8 64 1d 00 00       	call   80102ad3 <begin_op>
    iput(ff.ip);
80100d6f:	83 ec 0c             	sub    $0xc,%esp
80100d72:	ff 75 f0             	pushl  -0x10(%ebp)
80100d75:	e8 1a 09 00 00       	call   80101694 <iput>
    end_op();
80100d7a:	e8 ce 1d 00 00       	call   80102b4d <end_op>
80100d7f:	83 c4 10             	add    $0x10,%esp
80100d82:	eb 93                	jmp    80100d17 <fileclose+0x38>
    pipeclose(ff.pipe, ff.writable);
80100d84:	83 ec 08             	sub    $0x8,%esp
80100d87:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d8b:	50                   	push   %eax
80100d8c:	ff 75 ec             	pushl  -0x14(%ebp)
80100d8f:	e8 c0 23 00 00       	call   80103154 <pipeclose>
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
80100e48:	e8 5f 24 00 00       	call   801032ac <piperead>
80100e4d:	89 c6                	mov    %eax,%esi
80100e4f:	83 c4 10             	add    $0x10,%esp
80100e52:	eb df                	jmp    80100e33 <fileread+0x50>
  panic("fileread");
80100e54:	83 ec 0c             	sub    $0xc,%esp
80100e57:	68 86 68 10 80       	push   $0x80106886
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
80100ea1:	e8 3a 23 00 00       	call   801031e0 <pipewrite>
80100ea6:	83 c4 10             	add    $0x10,%esp
80100ea9:	e9 80 00 00 00       	jmp    80100f2e <filewrite+0xc6>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100eae:	e8 20 1c 00 00       	call   80102ad3 <begin_op>
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
80100ee9:	e8 5f 1c 00 00       	call   80102b4d <end_op>

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
80100f1c:	68 8f 68 10 80       	push   $0x8010688f
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
80100f39:	68 95 68 10 80       	push   $0x80106895
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
80100f96:	e8 5c 30 00 00       	call   80103ff7 <memmove>
80100f9b:	83 c4 10             	add    $0x10,%esp
80100f9e:	eb 17                	jmp    80100fb7 <skipelem+0x66>
  else {
    memmove(name, s, len);
80100fa0:	83 ec 04             	sub    $0x4,%esp
80100fa3:	56                   	push   %esi
80100fa4:	50                   	push   %eax
80100fa5:	57                   	push   %edi
80100fa6:	e8 4c 30 00 00       	call   80103ff7 <memmove>
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
80100feb:	e8 8c 2f 00 00       	call   80103f7c <memset>
  log_write(bp);
80100ff0:	89 1c 24             	mov    %ebx,(%esp)
80100ff3:	e8 04 1c 00 00       	call   80102bfc <log_write>
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
801010af:	68 9f 68 10 80       	push   $0x8010689f
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
801010cb:	e8 2c 1b 00 00       	call   80102bfc <log_write>
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
8010117c:	e8 7b 1a 00 00       	call   80102bfc <log_write>
80101181:	83 c4 10             	add    $0x10,%esp
80101184:	eb bf                	jmp    80101145 <bmap+0x58>
  panic("bmap: out of range");
80101186:	83 ec 0c             	sub    $0xc,%esp
80101189:	68 b5 68 10 80       	push   $0x801068b5
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
801011a6:	e8 25 2d 00 00       	call   80103ed0 <acquire>
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
801011ed:	e8 43 2d 00 00       	call   80103f35 <release>
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
80101223:	e8 0d 2d 00 00       	call   80103f35 <release>
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
80101238:	68 c8 68 10 80       	push   $0x801068c8
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
80101261:	e8 91 2d 00 00       	call   80103ff7 <memmove>
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
801012d4:	e8 23 19 00 00       	call   80102bfc <log_write>
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
801012ee:	68 d8 68 10 80       	push   $0x801068d8
801012f3:	e8 50 f0 ff ff       	call   80100348 <panic>

801012f8 <iinit>:
{
801012f8:	55                   	push   %ebp
801012f9:	89 e5                	mov    %esp,%ebp
801012fb:	53                   	push   %ebx
801012fc:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012ff:	68 eb 68 10 80       	push   $0x801068eb
80101304:	68 e0 09 11 80       	push   $0x801109e0
80101309:	e8 86 2a 00 00       	call   80103d94 <initlock>
  for(i = 0; i < NINODE; i++) {
8010130e:	83 c4 10             	add    $0x10,%esp
80101311:	bb 00 00 00 00       	mov    $0x0,%ebx
80101316:	eb 21                	jmp    80101339 <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
80101318:	83 ec 08             	sub    $0x8,%esp
8010131b:	68 f2 68 10 80       	push   $0x801068f2
80101320:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101323:	89 d0                	mov    %edx,%eax
80101325:	c1 e0 04             	shl    $0x4,%eax
80101328:	05 20 0a 11 80       	add    $0x80110a20,%eax
8010132d:	50                   	push   %eax
8010132e:	e8 56 29 00 00       	call   80103c89 <initsleeplock>
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
80101378:	68 58 69 10 80       	push   $0x80106958
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
801013eb:	68 f8 68 10 80       	push   $0x801068f8
801013f0:	e8 53 ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013f5:	83 ec 04             	sub    $0x4,%esp
801013f8:	6a 40                	push   $0x40
801013fa:	6a 00                	push   $0x0
801013fc:	57                   	push   %edi
801013fd:	e8 7a 2b 00 00       	call   80103f7c <memset>
      dip->type = type;
80101402:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80101406:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
80101409:	89 34 24             	mov    %esi,(%esp)
8010140c:	e8 eb 17 00 00       	call   80102bfc <log_write>
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
8010148c:	e8 66 2b 00 00       	call   80103ff7 <memmove>
  log_write(bp);
80101491:	89 34 24             	mov    %esi,(%esp)
80101494:	e8 63 17 00 00       	call   80102bfc <log_write>
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
8010156c:	e8 5f 29 00 00       	call   80103ed0 <acquire>
  ip->ref++;
80101571:	8b 43 08             	mov    0x8(%ebx),%eax
80101574:	83 c0 01             	add    $0x1,%eax
80101577:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010157a:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
80101581:	e8 af 29 00 00       	call   80103f35 <release>
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
801015a6:	e8 11 27 00 00       	call   80103cbc <acquiresleep>
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
801015be:	68 0a 69 10 80       	push   $0x8010690a
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
80101620:	e8 d2 29 00 00       	call   80103ff7 <memmove>
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
80101645:	68 10 69 10 80       	push   $0x80106910
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
80101662:	e8 df 26 00 00       	call   80103d46 <holdingsleep>
80101667:	83 c4 10             	add    $0x10,%esp
8010166a:	85 c0                	test   %eax,%eax
8010166c:	74 19                	je     80101687 <iunlock+0x38>
8010166e:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101672:	7e 13                	jle    80101687 <iunlock+0x38>
  releasesleep(&ip->lock);
80101674:	83 ec 0c             	sub    $0xc,%esp
80101677:	56                   	push   %esi
80101678:	e8 8e 26 00 00       	call   80103d0b <releasesleep>
}
8010167d:	83 c4 10             	add    $0x10,%esp
80101680:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101683:	5b                   	pop    %ebx
80101684:	5e                   	pop    %esi
80101685:	5d                   	pop    %ebp
80101686:	c3                   	ret    
    panic("iunlock");
80101687:	83 ec 0c             	sub    $0xc,%esp
8010168a:	68 1f 69 10 80       	push   $0x8010691f
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
801016a4:	e8 13 26 00 00       	call   80103cbc <acquiresleep>
  if(ip->valid && ip->nlink == 0){
801016a9:	83 c4 10             	add    $0x10,%esp
801016ac:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801016b0:	74 07                	je     801016b9 <iput+0x25>
801016b2:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801016b7:	74 35                	je     801016ee <iput+0x5a>
  releasesleep(&ip->lock);
801016b9:	83 ec 0c             	sub    $0xc,%esp
801016bc:	56                   	push   %esi
801016bd:	e8 49 26 00 00       	call   80103d0b <releasesleep>
  acquire(&icache.lock);
801016c2:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016c9:	e8 02 28 00 00       	call   80103ed0 <acquire>
  ip->ref--;
801016ce:	8b 43 08             	mov    0x8(%ebx),%eax
801016d1:	83 e8 01             	sub    $0x1,%eax
801016d4:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016d7:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
801016de:	e8 52 28 00 00       	call   80103f35 <release>
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
801016f6:	e8 d5 27 00 00       	call   80103ed0 <acquire>
    int r = ip->ref;
801016fb:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016fe:	c7 04 24 e0 09 11 80 	movl   $0x801109e0,(%esp)
80101705:	e8 2b 28 00 00       	call   80103f35 <release>
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
80101836:	e8 bc 27 00 00       	call   80103ff7 <memmove>
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
80101932:	e8 c0 26 00 00       	call   80103ff7 <memmove>
    log_write(bp);
80101937:	89 3c 24             	mov    %edi,(%esp)
8010193a:	e8 bd 12 00 00       	call   80102bfc <log_write>
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
801019b5:	e8 a4 26 00 00       	call   8010405e <strncmp>
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
801019dc:	68 27 69 10 80       	push   $0x80106927
801019e1:	e8 62 e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019e6:	83 ec 0c             	sub    $0xc,%esp
801019e9:	68 39 69 10 80       	push   $0x80106939
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
80101a66:	e8 c3 1a 00 00       	call   8010352e <myproc>
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
80101b9e:	68 48 69 10 80       	push   $0x80106948
80101ba3:	e8 a0 e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101ba8:	83 ec 04             	sub    $0x4,%esp
80101bab:	6a 0e                	push   $0xe
80101bad:	57                   	push   %edi
80101bae:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101bb1:	8d 45 da             	lea    -0x26(%ebp),%eax
80101bb4:	50                   	push   %eax
80101bb5:	e8 e1 24 00 00       	call   8010409b <strncpy>
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
80101be3:	68 54 6f 10 80       	push   $0x80106f54
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
80101cd8:	68 ab 69 10 80       	push   $0x801069ab
80101cdd:	e8 66 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101ce2:	83 ec 0c             	sub    $0xc,%esp
80101ce5:	68 b4 69 10 80       	push   $0x801069b4
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
80101d12:	68 c6 69 10 80       	push   $0x801069c6
80101d17:	68 80 a5 10 80       	push   $0x8010a580
80101d1c:	e8 73 20 00 00       	call   80103d94 <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101d21:	83 c4 08             	add    $0x8,%esp
80101d24:	a1 00 4a 14 80       	mov    0x80144a00,%eax
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
80101d8c:	e8 3f 21 00 00       	call   80103ed0 <acquire>

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
80101db9:	e8 7c 1d 00 00       	call   80103b3a <wakeup>

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
80101dd7:	e8 59 21 00 00       	call   80103f35 <release>
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
80101dee:	e8 42 21 00 00       	call   80103f35 <release>
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
80101e26:	e8 1b 1f 00 00       	call   80103d46 <holdingsleep>
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
80101e53:	e8 78 20 00 00       	call   80103ed0 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e58:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e5f:	83 c4 10             	add    $0x10,%esp
80101e62:	ba 64 a5 10 80       	mov    $0x8010a564,%edx
80101e67:	eb 2a                	jmp    80101e93 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e69:	83 ec 0c             	sub    $0xc,%esp
80101e6c:	68 ca 69 10 80       	push   $0x801069ca
80101e71:	e8 d2 e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e76:	83 ec 0c             	sub    $0xc,%esp
80101e79:	68 e0 69 10 80       	push   $0x801069e0
80101e7e:	e8 c5 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e83:	83 ec 0c             	sub    $0xc,%esp
80101e86:	68 f5 69 10 80       	push   $0x801069f5
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
80101eb5:	e8 1b 1b 00 00       	call   801039d5 <sleep>
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
80101ecf:	e8 61 20 00 00       	call   80103f35 <release>
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
80101f36:	0f b6 15 60 44 14 80 	movzbl 0x80144460,%edx
80101f3d:	39 c2                	cmp    %eax,%edx
80101f3f:	75 07                	jne    80101f48 <ioapicinit+0x42>
{
80101f41:	bb 00 00 00 00       	mov    $0x0,%ebx
80101f46:	eb 36                	jmp    80101f7e <ioapicinit+0x78>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80101f48:	83 ec 0c             	sub    $0xc,%esp
80101f4b:	68 14 6a 10 80       	push   $0x80106a14
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

80101fb0 <kfree>:

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(char *v) {
80101fb0:	55                   	push   %ebp
80101fb1:	89 e5                	mov    %esp,%ebp
80101fb3:	53                   	push   %ebx
80101fb4:	83 ec 04             	sub    $0x4,%esp
80101fb7:	8b 5d 08             	mov    0x8(%ebp),%ebx

    if ((uint) v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80101fba:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80101fc0:	75 56                	jne    80102018 <kfree+0x68>
80101fc2:	81 fb a8 71 14 80    	cmp    $0x801471a8,%ebx
80101fc8:	72 4e                	jb     80102018 <kfree+0x68>
80101fca:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80101fd0:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80101fd5:	77 41                	ja     80102018 <kfree+0x68>
        panic("kfree");

    // Fill with junk to catch dangling refs.
    memset(v, 1, PGSIZE);
80101fd7:	83 ec 04             	sub    $0x4,%esp
80101fda:	68 00 10 00 00       	push   $0x1000
80101fdf:	6a 01                	push   $0x1
80101fe1:	53                   	push   %ebx
80101fe2:	e8 95 1f 00 00       	call   80103f7c <memset>

    if (kmem.use_lock)
80101fe7:	83 c4 10             	add    $0x10,%esp
80101fea:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80101ff1:	75 32                	jne    80102025 <kfree+0x75>
        acquire(&kmem.lock);
    
    // Find the pid with the junk pfn and set it to -1
    for (int i = 0; i < 17000; i++) {
80101ff3:	b8 00 00 00 00       	mov    $0x0,%eax
80101ff8:	3d 67 42 00 00       	cmp    $0x4267,%eax
80101ffd:	7f 42                	jg     80102041 <kfree+0x91>
        if (frames[i].pfn == (struct run *) v) {
80101fff:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
80102002:	8d 14 8d 00 00 00 00 	lea    0x0(,%ecx,4),%edx
80102009:	89 d1                	mov    %edx,%ecx
8010200b:	39 9a 88 26 11 80    	cmp    %ebx,-0x7feed978(%edx)
80102011:	74 24                	je     80102037 <kfree+0x87>
    for (int i = 0; i < 17000; i++) {
80102013:	83 c0 01             	add    $0x1,%eax
80102016:	eb e0                	jmp    80101ff8 <kfree+0x48>
        panic("kfree");
80102018:	83 ec 0c             	sub    $0xc,%esp
8010201b:	68 46 6a 10 80       	push   $0x80106a46
80102020:	e8 23 e3 ff ff       	call   80100348 <panic>
        acquire(&kmem.lock);
80102025:	83 ec 0c             	sub    $0xc,%esp
80102028:	68 40 26 11 80       	push   $0x80112640
8010202d:	e8 9e 1e 00 00       	call   80103ed0 <acquire>
80102032:	83 c4 10             	add    $0x10,%esp
80102035:	eb bc                	jmp    80101ff3 <kfree+0x43>
            frames[i].pid = -1;
80102037:	c7 81 84 26 11 80 ff 	movl   $0xffffffff,-0x7feed97c(%ecx)
8010203e:	ff ff ff 
            break;
        }
    }

    if (kmem.use_lock)
80102041:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80102048:	75 05                	jne    8010204f <kfree+0x9f>
        release(&kmem.lock);
}
8010204a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010204d:	c9                   	leave  
8010204e:	c3                   	ret    
        release(&kmem.lock);
8010204f:	83 ec 0c             	sub    $0xc,%esp
80102052:	68 40 26 11 80       	push   $0x80112640
80102057:	e8 d9 1e 00 00       	call   80103f35 <release>
8010205c:	83 c4 10             	add    $0x10,%esp
}
8010205f:	eb e9                	jmp    8010204a <kfree+0x9a>

80102061 <kfree2>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
//
// Only for freerange because slow without it.
void kfree2(char *v) {
80102061:	55                   	push   %ebp
80102062:	89 e5                	mov    %esp,%ebp
80102064:	53                   	push   %ebx
80102065:	83 ec 04             	sub    $0x4,%esp
80102068:	8b 5d 08             	mov    0x8(%ebp),%ebx
    struct run *r;

    if ((uint) v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
8010206b:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80102071:	75 4c                	jne    801020bf <kfree2+0x5e>
80102073:	81 fb a8 71 14 80    	cmp    $0x801471a8,%ebx
80102079:	72 44                	jb     801020bf <kfree2+0x5e>
8010207b:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80102081:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102086:	77 37                	ja     801020bf <kfree2+0x5e>
        panic("kfree");

    // Fill with junk to catch dangling refs.
    memset(v, 1, PGSIZE);
80102088:	83 ec 04             	sub    $0x4,%esp
8010208b:	68 00 10 00 00       	push   $0x1000
80102090:	6a 01                	push   $0x1
80102092:	53                   	push   %ebx
80102093:	e8 e4 1e 00 00       	call   80103f7c <memset>

    if (kmem.use_lock){
80102098:	83 c4 10             	add    $0x10,%esp
8010209b:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801020a2:	75 28                	jne    801020cc <kfree2+0x6b>
        acquire(&kmem.lock);
    }

    r = (struct run *) v;

    r->next = kmem.freelist;
801020a4:	a1 78 26 11 80       	mov    0x80112678,%eax
801020a9:	89 03                	mov    %eax,(%ebx)
    kmem.freelist = r;
801020ab:	89 1d 78 26 11 80    	mov    %ebx,0x80112678

    if (kmem.use_lock){
801020b1:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801020b8:	75 24                	jne    801020de <kfree2+0x7d>
        release(&kmem.lock);
    }
}
801020ba:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801020bd:	c9                   	leave  
801020be:	c3                   	ret    
        panic("kfree");
801020bf:	83 ec 0c             	sub    $0xc,%esp
801020c2:	68 46 6a 10 80       	push   $0x80106a46
801020c7:	e8 7c e2 ff ff       	call   80100348 <panic>
        acquire(&kmem.lock);
801020cc:	83 ec 0c             	sub    $0xc,%esp
801020cf:	68 40 26 11 80       	push   $0x80112640
801020d4:	e8 f7 1d 00 00       	call   80103ed0 <acquire>
801020d9:	83 c4 10             	add    $0x10,%esp
801020dc:	eb c6                	jmp    801020a4 <kfree2+0x43>
        release(&kmem.lock);
801020de:	83 ec 0c             	sub    $0xc,%esp
801020e1:	68 40 26 11 80       	push   $0x80112640
801020e6:	e8 4a 1e 00 00       	call   80103f35 <release>
801020eb:	83 c4 10             	add    $0x10,%esp
}
801020ee:	eb ca                	jmp    801020ba <kfree2+0x59>

801020f0 <freerange>:
void freerange(void *vstart, void *vend) {
801020f0:	55                   	push   %ebp
801020f1:	89 e5                	mov    %esp,%ebp
801020f3:	56                   	push   %esi
801020f4:	53                   	push   %ebx
801020f5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
    p = (char *) PGROUNDUP((uint) vstart);
801020f8:	8b 45 08             	mov    0x8(%ebp),%eax
801020fb:	05 ff 0f 00 00       	add    $0xfff,%eax
80102100:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    for (; p + PGSIZE <= (char *) vend; p += PGSIZE) {
80102105:	eb 0e                	jmp    80102115 <freerange+0x25>
        kfree2(p);
80102107:	83 ec 0c             	sub    $0xc,%esp
8010210a:	50                   	push   %eax
8010210b:	e8 51 ff ff ff       	call   80102061 <kfree2>
    for (; p + PGSIZE <= (char *) vend; p += PGSIZE) {
80102110:	83 c4 10             	add    $0x10,%esp
80102113:	89 f0                	mov    %esi,%eax
80102115:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
8010211b:	39 de                	cmp    %ebx,%esi
8010211d:	76 e8                	jbe    80102107 <freerange+0x17>
}
8010211f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102122:	5b                   	pop    %ebx
80102123:	5e                   	pop    %esi
80102124:	5d                   	pop    %ebp
80102125:	c3                   	ret    

80102126 <kinit1>:
void kinit1(void *vstart, void *vend) {
80102126:	55                   	push   %ebp
80102127:	89 e5                	mov    %esp,%ebp
80102129:	83 ec 10             	sub    $0x10,%esp
    initlock(&kmem.lock, "kmem");
8010212c:	68 4c 6a 10 80       	push   $0x80106a4c
80102131:	68 40 26 11 80       	push   $0x80112640
80102136:	e8 59 1c 00 00       	call   80103d94 <initlock>
    kmem.use_lock = 0;
8010213b:	c7 05 74 26 11 80 00 	movl   $0x0,0x80112674
80102142:	00 00 00 
    freerange(vstart, vend);
80102145:	83 c4 08             	add    $0x8,%esp
80102148:	ff 75 0c             	pushl  0xc(%ebp)
8010214b:	ff 75 08             	pushl  0x8(%ebp)
8010214e:	e8 9d ff ff ff       	call   801020f0 <freerange>
}
80102153:	83 c4 10             	add    $0x10,%esp
80102156:	c9                   	leave  
80102157:	c3                   	ret    

80102158 <kinit2>:
void kinit2(void *vstart, void *vend) {
80102158:	55                   	push   %ebp
80102159:	89 e5                	mov    %esp,%ebp
8010215b:	53                   	push   %ebx
8010215c:	83 ec 0c             	sub    $0xc,%esp
    freerange(vstart, vend);
8010215f:	ff 75 0c             	pushl  0xc(%ebp)
80102162:	ff 75 08             	pushl  0x8(%ebp)
80102165:	e8 86 ff ff ff       	call   801020f0 <freerange>
    p = kmem.freelist;
8010216a:	8b 1d 78 26 11 80    	mov    0x80112678,%ebx
    for (int i = 0; i < 17000; i++) {
80102170:	83 c4 10             	add    $0x10,%esp
80102173:	ba 00 00 00 00       	mov    $0x0,%edx
80102178:	eb 21                	jmp    8010219b <kinit2+0x43>
        frames[i].pid = -1;
8010217a:	8d 0c 12             	lea    (%edx,%edx,1),%ecx
8010217d:	01 d1                	add    %edx,%ecx
8010217f:	8d 04 8d 00 00 00 00 	lea    0x0(,%ecx,4),%eax
80102186:	c7 80 84 26 11 80 ff 	movl   $0xffffffff,-0x7feed97c(%eax)
8010218d:	ff ff ff 
        frames[i].pfn = p;
80102190:	89 98 88 26 11 80    	mov    %ebx,-0x7feed978(%eax)
        p = p->next;
80102196:	8b 1b                	mov    (%ebx),%ebx
    for (int i = 0; i < 17000; i++) {
80102198:	83 c2 01             	add    $0x1,%edx
8010219b:	81 fa 67 42 00 00    	cmp    $0x4267,%edx
801021a1:	7e d7                	jle    8010217a <kinit2+0x22>
    kmem.use_lock = 1;
801021a3:	c7 05 74 26 11 80 01 	movl   $0x1,0x80112674
801021aa:	00 00 00 
}
801021ad:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801021b0:	c9                   	leave  
801021b1:	c3                   	ret    

801021b2 <kalloc>:

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char *
kalloc(void) {
801021b2:	55                   	push   %ebp
801021b3:	89 e5                	mov    %esp,%ebp
801021b5:	56                   	push   %esi
801021b6:	53                   	push   %ebx
    struct run *r;

    if (kmem.use_lock) {
801021b7:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
801021be:	75 21                	jne    801021e1 <kalloc+0x2f>
        acquire(&kmem.lock);
    }

    r = kmem.freelist;
801021c0:	8b 1d 78 26 11 80    	mov    0x80112678,%ebx

    if (!kmem.use_lock){
801021c6:	8b 35 74 26 11 80    	mov    0x80112674,%esi
801021cc:	85 f6                	test   %esi,%esi
801021ce:	75 23                	jne    801021f3 <kalloc+0x41>
        if (r) {
801021d0:	85 db                	test   %ebx,%ebx
801021d2:	0f 84 87 00 00 00    	je     8010225f <kalloc+0xad>
            kmem.freelist = r->next;
801021d8:	8b 03                	mov    (%ebx),%eax
801021da:	a3 78 26 11 80       	mov    %eax,0x80112678
801021df:	eb 7e                	jmp    8010225f <kalloc+0xad>
        acquire(&kmem.lock);
801021e1:	83 ec 0c             	sub    $0xc,%esp
801021e4:	68 40 26 11 80       	push   $0x80112640
801021e9:	e8 e2 1c 00 00       	call   80103ed0 <acquire>
801021ee:	83 c4 10             	add    $0x10,%esp
801021f1:	eb cd                	jmp    801021c0 <kalloc+0xe>
        }
    } else {
        // SECURITY CHECKS
        if (frames[0].pid == -1 && frames[1].pid == -1) {
801021f3:	83 3d 84 26 11 80 ff 	cmpl   $0xffffffff,0x80112684
801021fa:	74 24                	je     80102220 <kalloc+0x6e>
801021fc:	b8 01 00 00 00       	mov    $0x1,%eax
            frames[0].pid = -2;
            r = frames[0].pfn;
        } else {
            int c = 1;
            while (c < 17000) {
80102201:	3d 67 42 00 00       	cmp    $0x4267,%eax
80102206:	7f 57                	jg     8010225f <kalloc+0xad>
                if ((frames[c].pid == -1) ||
80102208:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
8010220b:	8d 14 8d 00 00 00 00 	lea    0x0(,%ecx,4),%edx
80102212:	83 ba 84 26 11 80 ff 	cmpl   $0xffffffff,-0x7feed97c(%edx)
80102219:	74 27                	je     80102242 <kalloc+0x90>
                    (frames[c+1].pid == -2 || frames[c+1].pid == -1 || frames[c+1].pid == -2) && frames[c].pid == -1)) {
                    frames[c].pid = -2;
                    r = frames[c].pfn;
                    break;
                }
                c++;
8010221b:	83 c0 01             	add    $0x1,%eax
8010221e:	eb e1                	jmp    80102201 <kalloc+0x4f>
        if (frames[0].pid == -1 && frames[1].pid == -1) {
80102220:	83 3d 90 26 11 80 ff 	cmpl   $0xffffffff,0x80112690
80102227:	74 07                	je     80102230 <kalloc+0x7e>
80102229:	b8 01 00 00 00       	mov    $0x1,%eax
8010222e:	eb d1                	jmp    80102201 <kalloc+0x4f>
            frames[0].pid = -2;
80102230:	c7 05 84 26 11 80 fe 	movl   $0xfffffffe,0x80112684
80102237:	ff ff ff 
            r = frames[0].pfn;
8010223a:	8b 1d 88 26 11 80    	mov    0x80112688,%ebx
80102240:	eb 1d                	jmp    8010225f <kalloc+0xad>
                    frames[c].pid = -2;
80102242:	8d 14 00             	lea    (%eax,%eax,1),%edx
80102245:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80102248:	8d 0c 9d 00 00 00 00 	lea    0x0(,%ebx,4),%ecx
8010224f:	c7 81 84 26 11 80 fe 	movl   $0xfffffffe,-0x7feed97c(%ecx)
80102256:	ff ff ff 
                    r = frames[c].pfn;
80102259:	8b 99 88 26 11 80    	mov    -0x7feed978(%ecx),%ebx
            }
        }
    }

    if (kmem.use_lock) {
8010225f:	85 f6                	test   %esi,%esi
80102261:	75 09                	jne    8010226c <kalloc+0xba>
        release(&kmem.lock);
    }
    return (char *) r;
}
80102263:	89 d8                	mov    %ebx,%eax
80102265:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102268:	5b                   	pop    %ebx
80102269:	5e                   	pop    %esi
8010226a:	5d                   	pop    %ebp
8010226b:	c3                   	ret    
        release(&kmem.lock);
8010226c:	83 ec 0c             	sub    $0xc,%esp
8010226f:	68 40 26 11 80       	push   $0x80112640
80102274:	e8 bc 1c 00 00       	call   80103f35 <release>
80102279:	83 c4 10             	add    $0x10,%esp
    return (char *) r;
8010227c:	eb e5                	jmp    80102263 <kalloc+0xb1>

8010227e <kalloc2>:

// Same as kalloc but takes in pid as a parameter
char *
kalloc2(int pid) {
8010227e:	55                   	push   %ebp
8010227f:	89 e5                	mov    %esp,%ebp
80102281:	57                   	push   %edi
80102282:	56                   	push   %esi
80102283:	53                   	push   %ebx
80102284:	83 ec 1c             	sub    $0x1c,%esp
80102287:	8b 5d 08             	mov    0x8(%ebp),%ebx
    struct run *r;

    if (kmem.use_lock) {
8010228a:	83 3d 74 26 11 80 00 	cmpl   $0x0,0x80112674
80102291:	75 31                	jne    801022c4 <kalloc2+0x46>
        acquire(&kmem.lock);
    }

    r = kmem.freelist;
80102293:	8b 35 78 26 11 80    	mov    0x80112678,%esi

    if (!kmem.use_lock){
80102299:	a1 74 26 11 80       	mov    0x80112674,%eax
8010229e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801022a1:	85 c0                	test   %eax,%eax
801022a3:	75 31                	jne    801022d6 <kalloc2+0x58>
        if (r) {
801022a5:	85 f6                	test   %esi,%esi
801022a7:	74 07                	je     801022b0 <kalloc2+0x32>
            kmem.freelist = r->next;
801022a9:	8b 06                	mov    (%esi),%eax
801022ab:	a3 78 26 11 80       	mov    %eax,0x80112678
                c++;
            }
        }
    }

    if (kmem.use_lock) {
801022b0:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
801022b4:	0f 85 cd 00 00 00    	jne    80102387 <kalloc2+0x109>
        release(&kmem.lock);
    }
    return (char *) r;
}
801022ba:	89 f0                	mov    %esi,%eax
801022bc:	8d 65 f4             	lea    -0xc(%ebp),%esp
801022bf:	5b                   	pop    %ebx
801022c0:	5e                   	pop    %esi
801022c1:	5f                   	pop    %edi
801022c2:	5d                   	pop    %ebp
801022c3:	c3                   	ret    
        acquire(&kmem.lock);
801022c4:	83 ec 0c             	sub    $0xc,%esp
801022c7:	68 40 26 11 80       	push   $0x80112640
801022cc:	e8 ff 1b 00 00       	call   80103ed0 <acquire>
801022d1:	83 c4 10             	add    $0x10,%esp
801022d4:	eb bd                	jmp    80102293 <kalloc2+0x15>
        if (frames[0].pid == -1 && frames[1].pid == -1) {
801022d6:	83 3d 84 26 11 80 ff 	cmpl   $0xffffffff,0x80112684
801022dd:	74 07                	je     801022e6 <kalloc2+0x68>
801022df:	b8 01 00 00 00       	mov    $0x1,%eax
801022e4:	eb 46                	jmp    8010232c <kalloc2+0xae>
801022e6:	83 3d 90 26 11 80 ff 	cmpl   $0xffffffff,0x80112690
801022ed:	74 07                	je     801022f6 <kalloc2+0x78>
801022ef:	b8 01 00 00 00       	mov    $0x1,%eax
801022f4:	eb 36                	jmp    8010232c <kalloc2+0xae>
            frames[0].pid = pid;
801022f6:	89 1d 84 26 11 80    	mov    %ebx,0x80112684
            r = frames[0].pfn;
801022fc:	8b 35 88 26 11 80    	mov    0x80112688,%esi
80102302:	eb ac                	jmp    801022b0 <kalloc2+0x32>
                if ((frames[c].pid == -1 && pid == -2) || 
80102304:	83 fb fe             	cmp    $0xfffffffe,%ebx
80102307:	75 43                	jne    8010234c <kalloc2+0xce>
                    frames[c].pid = pid;
80102309:	8d 14 00             	lea    (%eax,%eax,1),%edx
8010230c:	8d 34 02             	lea    (%edx,%eax,1),%esi
8010230f:	8d 0c b5 00 00 00 00 	lea    0x0(,%esi,4),%ecx
80102316:	89 99 84 26 11 80    	mov    %ebx,-0x7feed97c(%ecx)
                    r = frames[c].pfn;
8010231c:	8b b1 88 26 11 80    	mov    -0x7feed978(%ecx),%esi
                    break;
80102322:	eb 8c                	jmp    801022b0 <kalloc2+0x32>
                (frames[c+1].pid == pid || frames[c+1].pid == -1 || frames[c+1].pid == -2) && frames[c].pid == -1)) {
80102324:	83 ff ff             	cmp    $0xffffffff,%edi
80102327:	74 e0                	je     80102309 <kalloc2+0x8b>
                c++;
80102329:	83 c0 01             	add    $0x1,%eax
            while (c < 17000) {
8010232c:	3d 67 42 00 00       	cmp    $0x4267,%eax
80102331:	0f 8f 79 ff ff ff    	jg     801022b0 <kalloc2+0x32>
                if ((frames[c].pid == -1 && pid == -2) || 
80102337:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
8010233a:	8d 14 8d 00 00 00 00 	lea    0x0(,%ecx,4),%edx
80102341:	8b ba 84 26 11 80    	mov    -0x7feed97c(%edx),%edi
80102347:	83 ff ff             	cmp    $0xffffffff,%edi
8010234a:	74 b8                	je     80102304 <kalloc2+0x86>
                ((frames[c-1].pid == pid || frames[c-1].pid == -1) &&
8010234c:	8d 4c 40 fd          	lea    -0x3(%eax,%eax,2),%ecx
80102350:	8d 14 8d 00 00 00 00 	lea    0x0(,%ecx,4),%edx
80102357:	8b 92 84 26 11 80    	mov    -0x7feed97c(%edx),%edx
                if ((frames[c].pid == -1 && pid == -2) || 
8010235d:	39 da                	cmp    %ebx,%edx
8010235f:	74 05                	je     80102366 <kalloc2+0xe8>
                ((frames[c-1].pid == pid || frames[c-1].pid == -1) &&
80102361:	83 fa ff             	cmp    $0xffffffff,%edx
80102364:	75 c3                	jne    80102329 <kalloc2+0xab>
                (frames[c+1].pid == pid || frames[c+1].pid == -1 || frames[c+1].pid == -2) && frames[c].pid == -1)) {
80102366:	8d 4c 40 03          	lea    0x3(%eax,%eax,2),%ecx
8010236a:	8d 14 8d 00 00 00 00 	lea    0x0(,%ecx,4),%edx
80102371:	8b 92 84 26 11 80    	mov    -0x7feed97c(%edx),%edx
                ((frames[c-1].pid == pid || frames[c-1].pid == -1) &&
80102377:	39 da                	cmp    %ebx,%edx
80102379:	74 a9                	je     80102324 <kalloc2+0xa6>
                (frames[c+1].pid == pid || frames[c+1].pid == -1 || frames[c+1].pid == -2) && frames[c].pid == -1)) {
8010237b:	83 fa ff             	cmp    $0xffffffff,%edx
8010237e:	74 a4                	je     80102324 <kalloc2+0xa6>
80102380:	83 fa fe             	cmp    $0xfffffffe,%edx
80102383:	75 a4                	jne    80102329 <kalloc2+0xab>
80102385:	eb 9d                	jmp    80102324 <kalloc2+0xa6>
        release(&kmem.lock);
80102387:	83 ec 0c             	sub    $0xc,%esp
8010238a:	68 40 26 11 80       	push   $0x80112640
8010238f:	e8 a1 1b 00 00       	call   80103f35 <release>
80102394:	83 c4 10             	add    $0x10,%esp
    return (char *) r;
80102397:	e9 1e ff ff ff       	jmp    801022ba <kalloc2+0x3c>

8010239c <dump_physmem>:

// System Call dump_physmem
int
dump_physmem(int *frs, int *pds, int numframes)
{
8010239c:	55                   	push   %ebp
8010239d:	89 e5                	mov    %esp,%ebp
8010239f:	57                   	push   %edi
801023a0:	56                   	push   %esi
801023a1:	53                   	push   %ebx
801023a2:	8b 7d 10             	mov    0x10(%ebp),%edi
    // Check if needs to return -1 
    if(numframes <= 0 || frs == 0 || pds == 0) {
801023a5:	85 ff                	test   %edi,%edi
801023a7:	0f 9e c2             	setle  %dl
801023aa:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801023ae:	0f 94 c0             	sete   %al
801023b1:	08 c2                	or     %al,%dl
801023b3:	75 72                	jne    80102427 <dump_physmem+0x8b>
801023b5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801023b9:	74 73                	je     8010242e <dump_physmem+0x92>
        return -1;
    }

    int c = 0; // keep track of frame number and pid
    int i = 0; // keep track of current index
801023bb:	b8 00 00 00 00       	mov    $0x0,%eax
    int c = 0; // keep track of frame number and pid
801023c0:	ba 00 00 00 00       	mov    $0x0,%edx
801023c5:	eb 03                	jmp    801023ca <dump_physmem+0x2e>
        // Update frs[] and pds[]
        if (frames[i].pid != -1) {
            frs[c] = framenumber;
            pds[c++] = frames[i].pid;
        }
        i++;
801023c7:	83 c0 01             	add    $0x1,%eax
    while(c < numframes){
801023ca:	39 fa                	cmp    %edi,%edx
801023cc:	7d 4f                	jge    8010241d <dump_physmem+0x81>
        framenumber = (uint) (V2P(frames[i].pfn) >> 12);
801023ce:	8d 1c 00             	lea    (%eax,%eax,1),%ebx
801023d1:	01 c3                	add    %eax,%ebx
801023d3:	8d 0c 9d 00 00 00 00 	lea    0x0(,%ebx,4),%ecx
801023da:	8b b1 88 26 11 80    	mov    -0x7feed978(%ecx),%esi
801023e0:	81 c1 80 26 11 80    	add    $0x80112680,%ecx
801023e6:	8d 9e 00 00 00 80    	lea    -0x80000000(%esi),%ebx
801023ec:	c1 eb 0c             	shr    $0xc,%ebx
        if (frames[i].pid != -1) {
801023ef:	83 79 04 ff          	cmpl   $0xffffffff,0x4(%ecx)
801023f3:	74 d2                	je     801023c7 <dump_physmem+0x2b>
            frs[c] = framenumber;
801023f5:	8d 0c 95 00 00 00 00 	lea    0x0(,%edx,4),%ecx
801023fc:	8b 75 08             	mov    0x8(%ebp),%esi
801023ff:	89 1c 0e             	mov    %ebx,(%esi,%ecx,1)
            pds[c++] = frames[i].pid;
80102402:	83 c2 01             	add    $0x1,%edx
80102405:	8d 34 40             	lea    (%eax,%eax,2),%esi
80102408:	8d 1c b5 00 00 00 00 	lea    0x0(,%esi,4),%ebx
8010240f:	8b 9b 84 26 11 80    	mov    -0x7feed97c(%ebx),%ebx
80102415:	8b 75 0c             	mov    0xc(%ebp),%esi
80102418:	89 1c 0e             	mov    %ebx,(%esi,%ecx,1)
8010241b:	eb aa                	jmp    801023c7 <dump_physmem+0x2b>
    }

  return 0;
8010241d:	b8 00 00 00 00       	mov    $0x0,%eax
80102422:	5b                   	pop    %ebx
80102423:	5e                   	pop    %esi
80102424:	5f                   	pop    %edi
80102425:	5d                   	pop    %ebp
80102426:	c3                   	ret    
        return -1;
80102427:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010242c:	eb f4                	jmp    80102422 <dump_physmem+0x86>
8010242e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102433:	eb ed                	jmp    80102422 <dump_physmem+0x86>

80102435 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102435:	55                   	push   %ebp
80102436:	89 e5                	mov    %esp,%ebp
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102438:	ba 64 00 00 00       	mov    $0x64,%edx
8010243d:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
8010243e:	a8 01                	test   $0x1,%al
80102440:	0f 84 b5 00 00 00    	je     801024fb <kbdgetc+0xc6>
80102446:	ba 60 00 00 00       	mov    $0x60,%edx
8010244b:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
8010244c:	0f b6 d0             	movzbl %al,%edx

  if(data == 0xE0){
8010244f:	81 fa e0 00 00 00    	cmp    $0xe0,%edx
80102455:	74 5c                	je     801024b3 <kbdgetc+0x7e>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
80102457:	84 c0                	test   %al,%al
80102459:	78 66                	js     801024c1 <kbdgetc+0x8c>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
8010245b:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
80102461:	f6 c1 40             	test   $0x40,%cl
80102464:	74 0f                	je     80102475 <kbdgetc+0x40>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102466:	83 c8 80             	or     $0xffffff80,%eax
80102469:	0f b6 d0             	movzbl %al,%edx
    shift &= ~E0ESC;
8010246c:	83 e1 bf             	and    $0xffffffbf,%ecx
8010246f:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  }

  shift |= shiftcode[data];
80102475:	0f b6 8a 80 6b 10 80 	movzbl -0x7fef9480(%edx),%ecx
8010247c:	0b 0d b4 a5 10 80    	or     0x8010a5b4,%ecx
  shift ^= togglecode[data];
80102482:	0f b6 82 80 6a 10 80 	movzbl -0x7fef9580(%edx),%eax
80102489:	31 c1                	xor    %eax,%ecx
8010248b:	89 0d b4 a5 10 80    	mov    %ecx,0x8010a5b4
  c = charcode[shift & (CTL | SHIFT)][data];
80102491:	89 c8                	mov    %ecx,%eax
80102493:	83 e0 03             	and    $0x3,%eax
80102496:	8b 04 85 60 6a 10 80 	mov    -0x7fef95a0(,%eax,4),%eax
8010249d:	0f b6 04 10          	movzbl (%eax,%edx,1),%eax
  if(shift & CAPSLOCK){
801024a1:	f6 c1 08             	test   $0x8,%cl
801024a4:	74 19                	je     801024bf <kbdgetc+0x8a>
    if('a' <= c && c <= 'z')
801024a6:	8d 50 9f             	lea    -0x61(%eax),%edx
801024a9:	83 fa 19             	cmp    $0x19,%edx
801024ac:	77 40                	ja     801024ee <kbdgetc+0xb9>
      c += 'A' - 'a';
801024ae:	83 e8 20             	sub    $0x20,%eax
801024b1:	eb 0c                	jmp    801024bf <kbdgetc+0x8a>
    shift |= E0ESC;
801024b3:	83 0d b4 a5 10 80 40 	orl    $0x40,0x8010a5b4
    return 0;
801024ba:	b8 00 00 00 00       	mov    $0x0,%eax
    else if('A' <= c && c <= 'Z')
      c += 'a' - 'A';
  }
  return c;
}
801024bf:	5d                   	pop    %ebp
801024c0:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
801024c1:	8b 0d b4 a5 10 80    	mov    0x8010a5b4,%ecx
801024c7:	f6 c1 40             	test   $0x40,%cl
801024ca:	75 05                	jne    801024d1 <kbdgetc+0x9c>
801024cc:	89 c2                	mov    %eax,%edx
801024ce:	83 e2 7f             	and    $0x7f,%edx
    shift &= ~(shiftcode[data] | E0ESC);
801024d1:	0f b6 82 80 6b 10 80 	movzbl -0x7fef9480(%edx),%eax
801024d8:	83 c8 40             	or     $0x40,%eax
801024db:	0f b6 c0             	movzbl %al,%eax
801024de:	f7 d0                	not    %eax
801024e0:	21 c8                	and    %ecx,%eax
801024e2:	a3 b4 a5 10 80       	mov    %eax,0x8010a5b4
    return 0;
801024e7:	b8 00 00 00 00       	mov    $0x0,%eax
801024ec:	eb d1                	jmp    801024bf <kbdgetc+0x8a>
    else if('A' <= c && c <= 'Z')
801024ee:	8d 50 bf             	lea    -0x41(%eax),%edx
801024f1:	83 fa 19             	cmp    $0x19,%edx
801024f4:	77 c9                	ja     801024bf <kbdgetc+0x8a>
      c += 'a' - 'A';
801024f6:	83 c0 20             	add    $0x20,%eax
  return c;
801024f9:	eb c4                	jmp    801024bf <kbdgetc+0x8a>
    return -1;
801024fb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102500:	eb bd                	jmp    801024bf <kbdgetc+0x8a>

80102502 <kbdintr>:

void
kbdintr(void)
{
80102502:	55                   	push   %ebp
80102503:	89 e5                	mov    %esp,%ebp
80102505:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
80102508:	68 35 24 10 80       	push   $0x80102435
8010250d:	e8 2c e2 ff ff       	call   8010073e <consoleintr>
}
80102512:	83 c4 10             	add    $0x10,%esp
80102515:	c9                   	leave  
80102516:	c3                   	ret    

80102517 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102517:	55                   	push   %ebp
80102518:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
8010251a:	8b 0d 60 43 14 80    	mov    0x80144360,%ecx
80102520:	8d 04 81             	lea    (%ecx,%eax,4),%eax
80102523:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
80102525:	a1 60 43 14 80       	mov    0x80144360,%eax
8010252a:	8b 40 20             	mov    0x20(%eax),%eax
}
8010252d:	5d                   	pop    %ebp
8010252e:	c3                   	ret    

8010252f <cmos_read>:
#define MONTH   0x08
#define YEAR    0x09

static uint
cmos_read(uint reg)
{
8010252f:	55                   	push   %ebp
80102530:	89 e5                	mov    %esp,%ebp
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102532:	ba 70 00 00 00       	mov    $0x70,%edx
80102537:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102538:	ba 71 00 00 00       	mov    $0x71,%edx
8010253d:	ec                   	in     (%dx),%al
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
8010253e:	0f b6 c0             	movzbl %al,%eax
}
80102541:	5d                   	pop    %ebp
80102542:	c3                   	ret    

80102543 <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
80102543:	55                   	push   %ebp
80102544:	89 e5                	mov    %esp,%ebp
80102546:	53                   	push   %ebx
80102547:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
80102549:	b8 00 00 00 00       	mov    $0x0,%eax
8010254e:	e8 dc ff ff ff       	call   8010252f <cmos_read>
80102553:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
80102555:	b8 02 00 00 00       	mov    $0x2,%eax
8010255a:	e8 d0 ff ff ff       	call   8010252f <cmos_read>
8010255f:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
80102562:	b8 04 00 00 00       	mov    $0x4,%eax
80102567:	e8 c3 ff ff ff       	call   8010252f <cmos_read>
8010256c:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
8010256f:	b8 07 00 00 00       	mov    $0x7,%eax
80102574:	e8 b6 ff ff ff       	call   8010252f <cmos_read>
80102579:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
8010257c:	b8 08 00 00 00       	mov    $0x8,%eax
80102581:	e8 a9 ff ff ff       	call   8010252f <cmos_read>
80102586:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
80102589:	b8 09 00 00 00       	mov    $0x9,%eax
8010258e:	e8 9c ff ff ff       	call   8010252f <cmos_read>
80102593:	89 43 14             	mov    %eax,0x14(%ebx)
}
80102596:	5b                   	pop    %ebx
80102597:	5d                   	pop    %ebp
80102598:	c3                   	ret    

80102599 <lapicinit>:
  if(!lapic)
80102599:	83 3d 60 43 14 80 00 	cmpl   $0x0,0x80144360
801025a0:	0f 84 fb 00 00 00    	je     801026a1 <lapicinit+0x108>
{
801025a6:	55                   	push   %ebp
801025a7:	89 e5                	mov    %esp,%ebp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801025a9:	ba 3f 01 00 00       	mov    $0x13f,%edx
801025ae:	b8 3c 00 00 00       	mov    $0x3c,%eax
801025b3:	e8 5f ff ff ff       	call   80102517 <lapicw>
  lapicw(TDCR, X1);
801025b8:	ba 0b 00 00 00       	mov    $0xb,%edx
801025bd:	b8 f8 00 00 00       	mov    $0xf8,%eax
801025c2:	e8 50 ff ff ff       	call   80102517 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801025c7:	ba 20 00 02 00       	mov    $0x20020,%edx
801025cc:	b8 c8 00 00 00       	mov    $0xc8,%eax
801025d1:	e8 41 ff ff ff       	call   80102517 <lapicw>
  lapicw(TICR, 10000000);
801025d6:	ba 80 96 98 00       	mov    $0x989680,%edx
801025db:	b8 e0 00 00 00       	mov    $0xe0,%eax
801025e0:	e8 32 ff ff ff       	call   80102517 <lapicw>
  lapicw(LINT0, MASKED);
801025e5:	ba 00 00 01 00       	mov    $0x10000,%edx
801025ea:	b8 d4 00 00 00       	mov    $0xd4,%eax
801025ef:	e8 23 ff ff ff       	call   80102517 <lapicw>
  lapicw(LINT1, MASKED);
801025f4:	ba 00 00 01 00       	mov    $0x10000,%edx
801025f9:	b8 d8 00 00 00       	mov    $0xd8,%eax
801025fe:	e8 14 ff ff ff       	call   80102517 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102603:	a1 60 43 14 80       	mov    0x80144360,%eax
80102608:	8b 40 30             	mov    0x30(%eax),%eax
8010260b:	c1 e8 10             	shr    $0x10,%eax
8010260e:	3c 03                	cmp    $0x3,%al
80102610:	77 7b                	ja     8010268d <lapicinit+0xf4>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102612:	ba 33 00 00 00       	mov    $0x33,%edx
80102617:	b8 dc 00 00 00       	mov    $0xdc,%eax
8010261c:	e8 f6 fe ff ff       	call   80102517 <lapicw>
  lapicw(ESR, 0);
80102621:	ba 00 00 00 00       	mov    $0x0,%edx
80102626:	b8 a0 00 00 00       	mov    $0xa0,%eax
8010262b:	e8 e7 fe ff ff       	call   80102517 <lapicw>
  lapicw(ESR, 0);
80102630:	ba 00 00 00 00       	mov    $0x0,%edx
80102635:	b8 a0 00 00 00       	mov    $0xa0,%eax
8010263a:	e8 d8 fe ff ff       	call   80102517 <lapicw>
  lapicw(EOI, 0);
8010263f:	ba 00 00 00 00       	mov    $0x0,%edx
80102644:	b8 2c 00 00 00       	mov    $0x2c,%eax
80102649:	e8 c9 fe ff ff       	call   80102517 <lapicw>
  lapicw(ICRHI, 0);
8010264e:	ba 00 00 00 00       	mov    $0x0,%edx
80102653:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102658:	e8 ba fe ff ff       	call   80102517 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
8010265d:	ba 00 85 08 00       	mov    $0x88500,%edx
80102662:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102667:	e8 ab fe ff ff       	call   80102517 <lapicw>
  while(lapic[ICRLO] & DELIVS)
8010266c:	a1 60 43 14 80       	mov    0x80144360,%eax
80102671:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
80102677:	f6 c4 10             	test   $0x10,%ah
8010267a:	75 f0                	jne    8010266c <lapicinit+0xd3>
  lapicw(TPR, 0);
8010267c:	ba 00 00 00 00       	mov    $0x0,%edx
80102681:	b8 20 00 00 00       	mov    $0x20,%eax
80102686:	e8 8c fe ff ff       	call   80102517 <lapicw>
}
8010268b:	5d                   	pop    %ebp
8010268c:	c3                   	ret    
    lapicw(PCINT, MASKED);
8010268d:	ba 00 00 01 00       	mov    $0x10000,%edx
80102692:	b8 d0 00 00 00       	mov    $0xd0,%eax
80102697:	e8 7b fe ff ff       	call   80102517 <lapicw>
8010269c:	e9 71 ff ff ff       	jmp    80102612 <lapicinit+0x79>
801026a1:	f3 c3                	repz ret 

801026a3 <lapicid>:
{
801026a3:	55                   	push   %ebp
801026a4:	89 e5                	mov    %esp,%ebp
  if (!lapic)
801026a6:	a1 60 43 14 80       	mov    0x80144360,%eax
801026ab:	85 c0                	test   %eax,%eax
801026ad:	74 08                	je     801026b7 <lapicid+0x14>
  return lapic[ID] >> 24;
801026af:	8b 40 20             	mov    0x20(%eax),%eax
801026b2:	c1 e8 18             	shr    $0x18,%eax
}
801026b5:	5d                   	pop    %ebp
801026b6:	c3                   	ret    
    return 0;
801026b7:	b8 00 00 00 00       	mov    $0x0,%eax
801026bc:	eb f7                	jmp    801026b5 <lapicid+0x12>

801026be <lapiceoi>:
  if(lapic)
801026be:	83 3d 60 43 14 80 00 	cmpl   $0x0,0x80144360
801026c5:	74 14                	je     801026db <lapiceoi+0x1d>
{
801026c7:	55                   	push   %ebp
801026c8:	89 e5                	mov    %esp,%ebp
    lapicw(EOI, 0);
801026ca:	ba 00 00 00 00       	mov    $0x0,%edx
801026cf:	b8 2c 00 00 00       	mov    $0x2c,%eax
801026d4:	e8 3e fe ff ff       	call   80102517 <lapicw>
}
801026d9:	5d                   	pop    %ebp
801026da:	c3                   	ret    
801026db:	f3 c3                	repz ret 

801026dd <microdelay>:
{
801026dd:	55                   	push   %ebp
801026de:	89 e5                	mov    %esp,%ebp
}
801026e0:	5d                   	pop    %ebp
801026e1:	c3                   	ret    

801026e2 <lapicstartap>:
{
801026e2:	55                   	push   %ebp
801026e3:	89 e5                	mov    %esp,%ebp
801026e5:	57                   	push   %edi
801026e6:	56                   	push   %esi
801026e7:	53                   	push   %ebx
801026e8:	8b 75 08             	mov    0x8(%ebp),%esi
801026eb:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801026ee:	b8 0f 00 00 00       	mov    $0xf,%eax
801026f3:	ba 70 00 00 00       	mov    $0x70,%edx
801026f8:	ee                   	out    %al,(%dx)
801026f9:	b8 0a 00 00 00       	mov    $0xa,%eax
801026fe:	ba 71 00 00 00       	mov    $0x71,%edx
80102703:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
80102704:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
8010270b:	00 00 
  wrv[1] = addr >> 4;
8010270d:	89 f8                	mov    %edi,%eax
8010270f:	c1 e8 04             	shr    $0x4,%eax
80102712:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
80102718:	c1 e6 18             	shl    $0x18,%esi
8010271b:	89 f2                	mov    %esi,%edx
8010271d:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102722:	e8 f0 fd ff ff       	call   80102517 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102727:	ba 00 c5 00 00       	mov    $0xc500,%edx
8010272c:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102731:	e8 e1 fd ff ff       	call   80102517 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
80102736:	ba 00 85 00 00       	mov    $0x8500,%edx
8010273b:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102740:	e8 d2 fd ff ff       	call   80102517 <lapicw>
  for(i = 0; i < 2; i++){
80102745:	bb 00 00 00 00       	mov    $0x0,%ebx
8010274a:	eb 21                	jmp    8010276d <lapicstartap+0x8b>
    lapicw(ICRHI, apicid<<24);
8010274c:	89 f2                	mov    %esi,%edx
8010274e:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102753:	e8 bf fd ff ff       	call   80102517 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80102758:	89 fa                	mov    %edi,%edx
8010275a:	c1 ea 0c             	shr    $0xc,%edx
8010275d:	80 ce 06             	or     $0x6,%dh
80102760:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102765:	e8 ad fd ff ff       	call   80102517 <lapicw>
  for(i = 0; i < 2; i++){
8010276a:	83 c3 01             	add    $0x1,%ebx
8010276d:	83 fb 01             	cmp    $0x1,%ebx
80102770:	7e da                	jle    8010274c <lapicstartap+0x6a>
}
80102772:	5b                   	pop    %ebx
80102773:	5e                   	pop    %esi
80102774:	5f                   	pop    %edi
80102775:	5d                   	pop    %ebp
80102776:	c3                   	ret    

80102777 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
80102777:	55                   	push   %ebp
80102778:	89 e5                	mov    %esp,%ebp
8010277a:	57                   	push   %edi
8010277b:	56                   	push   %esi
8010277c:	53                   	push   %ebx
8010277d:	83 ec 3c             	sub    $0x3c,%esp
80102780:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
80102783:	b8 0b 00 00 00       	mov    $0xb,%eax
80102788:	e8 a2 fd ff ff       	call   8010252f <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
8010278d:	83 e0 04             	and    $0x4,%eax
80102790:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
80102792:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102795:	e8 a9 fd ff ff       	call   80102543 <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
8010279a:	b8 0a 00 00 00       	mov    $0xa,%eax
8010279f:	e8 8b fd ff ff       	call   8010252f <cmos_read>
801027a4:	a8 80                	test   $0x80,%al
801027a6:	75 ea                	jne    80102792 <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
801027a8:	8d 5d b8             	lea    -0x48(%ebp),%ebx
801027ab:	89 d8                	mov    %ebx,%eax
801027ad:	e8 91 fd ff ff       	call   80102543 <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
801027b2:	83 ec 04             	sub    $0x4,%esp
801027b5:	6a 18                	push   $0x18
801027b7:	53                   	push   %ebx
801027b8:	8d 45 d0             	lea    -0x30(%ebp),%eax
801027bb:	50                   	push   %eax
801027bc:	e8 01 18 00 00       	call   80103fc2 <memcmp>
801027c1:	83 c4 10             	add    $0x10,%esp
801027c4:	85 c0                	test   %eax,%eax
801027c6:	75 ca                	jne    80102792 <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
801027c8:	85 ff                	test   %edi,%edi
801027ca:	0f 85 84 00 00 00    	jne    80102854 <cmostime+0xdd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
801027d0:	8b 55 d0             	mov    -0x30(%ebp),%edx
801027d3:	89 d0                	mov    %edx,%eax
801027d5:	c1 e8 04             	shr    $0x4,%eax
801027d8:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801027db:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801027de:	83 e2 0f             	and    $0xf,%edx
801027e1:	01 d0                	add    %edx,%eax
801027e3:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
801027e6:	8b 55 d4             	mov    -0x2c(%ebp),%edx
801027e9:	89 d0                	mov    %edx,%eax
801027eb:	c1 e8 04             	shr    $0x4,%eax
801027ee:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801027f1:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
801027f4:	83 e2 0f             	and    $0xf,%edx
801027f7:	01 d0                	add    %edx,%eax
801027f9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
801027fc:	8b 55 d8             	mov    -0x28(%ebp),%edx
801027ff:	89 d0                	mov    %edx,%eax
80102801:	c1 e8 04             	shr    $0x4,%eax
80102804:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102807:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010280a:	83 e2 0f             	and    $0xf,%edx
8010280d:	01 d0                	add    %edx,%eax
8010280f:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
80102812:	8b 55 dc             	mov    -0x24(%ebp),%edx
80102815:	89 d0                	mov    %edx,%eax
80102817:	c1 e8 04             	shr    $0x4,%eax
8010281a:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
8010281d:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102820:	83 e2 0f             	and    $0xf,%edx
80102823:	01 d0                	add    %edx,%eax
80102825:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
80102828:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010282b:	89 d0                	mov    %edx,%eax
8010282d:	c1 e8 04             	shr    $0x4,%eax
80102830:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102833:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
80102836:	83 e2 0f             	and    $0xf,%edx
80102839:	01 d0                	add    %edx,%eax
8010283b:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
8010283e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80102841:	89 d0                	mov    %edx,%eax
80102843:	c1 e8 04             	shr    $0x4,%eax
80102846:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102849:	8d 04 09             	lea    (%ecx,%ecx,1),%eax
8010284c:	83 e2 0f             	and    $0xf,%edx
8010284f:	01 d0                	add    %edx,%eax
80102851:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
80102854:	8b 45 d0             	mov    -0x30(%ebp),%eax
80102857:	89 06                	mov    %eax,(%esi)
80102859:	8b 45 d4             	mov    -0x2c(%ebp),%eax
8010285c:	89 46 04             	mov    %eax,0x4(%esi)
8010285f:	8b 45 d8             	mov    -0x28(%ebp),%eax
80102862:	89 46 08             	mov    %eax,0x8(%esi)
80102865:	8b 45 dc             	mov    -0x24(%ebp),%eax
80102868:	89 46 0c             	mov    %eax,0xc(%esi)
8010286b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010286e:	89 46 10             	mov    %eax,0x10(%esi)
80102871:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102874:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
80102877:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
8010287e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102881:	5b                   	pop    %ebx
80102882:	5e                   	pop    %esi
80102883:	5f                   	pop    %edi
80102884:	5d                   	pop    %ebp
80102885:	c3                   	ret    

80102886 <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80102886:	55                   	push   %ebp
80102887:	89 e5                	mov    %esp,%ebp
80102889:	53                   	push   %ebx
8010288a:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
8010288d:	ff 35 b4 43 14 80    	pushl  0x801443b4
80102893:	ff 35 c4 43 14 80    	pushl  0x801443c4
80102899:	e8 ce d8 ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
8010289e:	8b 58 5c             	mov    0x5c(%eax),%ebx
801028a1:	89 1d c8 43 14 80    	mov    %ebx,0x801443c8
  for (i = 0; i < log.lh.n; i++) {
801028a7:	83 c4 10             	add    $0x10,%esp
801028aa:	ba 00 00 00 00       	mov    $0x0,%edx
801028af:	eb 0e                	jmp    801028bf <read_head+0x39>
    log.lh.block[i] = lh->block[i];
801028b1:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
801028b5:	89 0c 95 cc 43 14 80 	mov    %ecx,-0x7febbc34(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
801028bc:	83 c2 01             	add    $0x1,%edx
801028bf:	39 d3                	cmp    %edx,%ebx
801028c1:	7f ee                	jg     801028b1 <read_head+0x2b>
  }
  brelse(buf);
801028c3:	83 ec 0c             	sub    $0xc,%esp
801028c6:	50                   	push   %eax
801028c7:	e8 09 d9 ff ff       	call   801001d5 <brelse>
}
801028cc:	83 c4 10             	add    $0x10,%esp
801028cf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801028d2:	c9                   	leave  
801028d3:	c3                   	ret    

801028d4 <install_trans>:
{
801028d4:	55                   	push   %ebp
801028d5:	89 e5                	mov    %esp,%ebp
801028d7:	57                   	push   %edi
801028d8:	56                   	push   %esi
801028d9:	53                   	push   %ebx
801028da:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
801028dd:	bb 00 00 00 00       	mov    $0x0,%ebx
801028e2:	eb 66                	jmp    8010294a <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801028e4:	89 d8                	mov    %ebx,%eax
801028e6:	03 05 b4 43 14 80    	add    0x801443b4,%eax
801028ec:	83 c0 01             	add    $0x1,%eax
801028ef:	83 ec 08             	sub    $0x8,%esp
801028f2:	50                   	push   %eax
801028f3:	ff 35 c4 43 14 80    	pushl  0x801443c4
801028f9:	e8 6e d8 ff ff       	call   8010016c <bread>
801028fe:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
80102900:	83 c4 08             	add    $0x8,%esp
80102903:	ff 34 9d cc 43 14 80 	pushl  -0x7febbc34(,%ebx,4)
8010290a:	ff 35 c4 43 14 80    	pushl  0x801443c4
80102910:	e8 57 d8 ff ff       	call   8010016c <bread>
80102915:	89 c6                	mov    %eax,%esi
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80102917:	8d 57 5c             	lea    0x5c(%edi),%edx
8010291a:	8d 40 5c             	lea    0x5c(%eax),%eax
8010291d:	83 c4 0c             	add    $0xc,%esp
80102920:	68 00 02 00 00       	push   $0x200
80102925:	52                   	push   %edx
80102926:	50                   	push   %eax
80102927:	e8 cb 16 00 00       	call   80103ff7 <memmove>
    bwrite(dbuf);  // write dst to disk
8010292c:	89 34 24             	mov    %esi,(%esp)
8010292f:	e8 66 d8 ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
80102934:	89 3c 24             	mov    %edi,(%esp)
80102937:	e8 99 d8 ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
8010293c:	89 34 24             	mov    %esi,(%esp)
8010293f:	e8 91 d8 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102944:	83 c3 01             	add    $0x1,%ebx
80102947:	83 c4 10             	add    $0x10,%esp
8010294a:	39 1d c8 43 14 80    	cmp    %ebx,0x801443c8
80102950:	7f 92                	jg     801028e4 <install_trans+0x10>
}
80102952:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102955:	5b                   	pop    %ebx
80102956:	5e                   	pop    %esi
80102957:	5f                   	pop    %edi
80102958:	5d                   	pop    %ebp
80102959:	c3                   	ret    

8010295a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
8010295a:	55                   	push   %ebp
8010295b:	89 e5                	mov    %esp,%ebp
8010295d:	53                   	push   %ebx
8010295e:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102961:	ff 35 b4 43 14 80    	pushl  0x801443b4
80102967:	ff 35 c4 43 14 80    	pushl  0x801443c4
8010296d:	e8 fa d7 ff ff       	call   8010016c <bread>
80102972:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
80102974:	8b 0d c8 43 14 80    	mov    0x801443c8,%ecx
8010297a:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
8010297d:	83 c4 10             	add    $0x10,%esp
80102980:	b8 00 00 00 00       	mov    $0x0,%eax
80102985:	eb 0e                	jmp    80102995 <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
80102987:	8b 14 85 cc 43 14 80 	mov    -0x7febbc34(,%eax,4),%edx
8010298e:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
80102992:	83 c0 01             	add    $0x1,%eax
80102995:	39 c1                	cmp    %eax,%ecx
80102997:	7f ee                	jg     80102987 <write_head+0x2d>
  }
  bwrite(buf);
80102999:	83 ec 0c             	sub    $0xc,%esp
8010299c:	53                   	push   %ebx
8010299d:	e8 f8 d7 ff ff       	call   8010019a <bwrite>
  brelse(buf);
801029a2:	89 1c 24             	mov    %ebx,(%esp)
801029a5:	e8 2b d8 ff ff       	call   801001d5 <brelse>
}
801029aa:	83 c4 10             	add    $0x10,%esp
801029ad:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801029b0:	c9                   	leave  
801029b1:	c3                   	ret    

801029b2 <recover_from_log>:

static void
recover_from_log(void)
{
801029b2:	55                   	push   %ebp
801029b3:	89 e5                	mov    %esp,%ebp
801029b5:	83 ec 08             	sub    $0x8,%esp
  read_head();
801029b8:	e8 c9 fe ff ff       	call   80102886 <read_head>
  install_trans(); // if committed, copy from log to disk
801029bd:	e8 12 ff ff ff       	call   801028d4 <install_trans>
  log.lh.n = 0;
801029c2:	c7 05 c8 43 14 80 00 	movl   $0x0,0x801443c8
801029c9:	00 00 00 
  write_head(); // clear the log
801029cc:	e8 89 ff ff ff       	call   8010295a <write_head>
}
801029d1:	c9                   	leave  
801029d2:	c3                   	ret    

801029d3 <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
801029d3:	55                   	push   %ebp
801029d4:	89 e5                	mov    %esp,%ebp
801029d6:	57                   	push   %edi
801029d7:	56                   	push   %esi
801029d8:	53                   	push   %ebx
801029d9:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801029dc:	bb 00 00 00 00       	mov    $0x0,%ebx
801029e1:	eb 66                	jmp    80102a49 <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
801029e3:	89 d8                	mov    %ebx,%eax
801029e5:	03 05 b4 43 14 80    	add    0x801443b4,%eax
801029eb:	83 c0 01             	add    $0x1,%eax
801029ee:	83 ec 08             	sub    $0x8,%esp
801029f1:	50                   	push   %eax
801029f2:	ff 35 c4 43 14 80    	pushl  0x801443c4
801029f8:	e8 6f d7 ff ff       	call   8010016c <bread>
801029fd:	89 c6                	mov    %eax,%esi
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801029ff:	83 c4 08             	add    $0x8,%esp
80102a02:	ff 34 9d cc 43 14 80 	pushl  -0x7febbc34(,%ebx,4)
80102a09:	ff 35 c4 43 14 80    	pushl  0x801443c4
80102a0f:	e8 58 d7 ff ff       	call   8010016c <bread>
80102a14:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
80102a16:	8d 50 5c             	lea    0x5c(%eax),%edx
80102a19:	8d 46 5c             	lea    0x5c(%esi),%eax
80102a1c:	83 c4 0c             	add    $0xc,%esp
80102a1f:	68 00 02 00 00       	push   $0x200
80102a24:	52                   	push   %edx
80102a25:	50                   	push   %eax
80102a26:	e8 cc 15 00 00       	call   80103ff7 <memmove>
    bwrite(to);  // write the log
80102a2b:	89 34 24             	mov    %esi,(%esp)
80102a2e:	e8 67 d7 ff ff       	call   8010019a <bwrite>
    brelse(from);
80102a33:	89 3c 24             	mov    %edi,(%esp)
80102a36:	e8 9a d7 ff ff       	call   801001d5 <brelse>
    brelse(to);
80102a3b:	89 34 24             	mov    %esi,(%esp)
80102a3e:	e8 92 d7 ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
80102a43:	83 c3 01             	add    $0x1,%ebx
80102a46:	83 c4 10             	add    $0x10,%esp
80102a49:	39 1d c8 43 14 80    	cmp    %ebx,0x801443c8
80102a4f:	7f 92                	jg     801029e3 <write_log+0x10>
  }
}
80102a51:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102a54:	5b                   	pop    %ebx
80102a55:	5e                   	pop    %esi
80102a56:	5f                   	pop    %edi
80102a57:	5d                   	pop    %ebp
80102a58:	c3                   	ret    

80102a59 <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
80102a59:	83 3d c8 43 14 80 00 	cmpl   $0x0,0x801443c8
80102a60:	7e 26                	jle    80102a88 <commit+0x2f>
{
80102a62:	55                   	push   %ebp
80102a63:	89 e5                	mov    %esp,%ebp
80102a65:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
80102a68:	e8 66 ff ff ff       	call   801029d3 <write_log>
    write_head();    // Write header to disk -- the real commit
80102a6d:	e8 e8 fe ff ff       	call   8010295a <write_head>
    install_trans(); // Now install writes to home locations
80102a72:	e8 5d fe ff ff       	call   801028d4 <install_trans>
    log.lh.n = 0;
80102a77:	c7 05 c8 43 14 80 00 	movl   $0x0,0x801443c8
80102a7e:	00 00 00 
    write_head();    // Erase the transaction from the log
80102a81:	e8 d4 fe ff ff       	call   8010295a <write_head>
  }
}
80102a86:	c9                   	leave  
80102a87:	c3                   	ret    
80102a88:	f3 c3                	repz ret 

80102a8a <initlog>:
{
80102a8a:	55                   	push   %ebp
80102a8b:	89 e5                	mov    %esp,%ebp
80102a8d:	53                   	push   %ebx
80102a8e:	83 ec 2c             	sub    $0x2c,%esp
80102a91:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
80102a94:	68 80 6c 10 80       	push   $0x80106c80
80102a99:	68 80 43 14 80       	push   $0x80144380
80102a9e:	e8 f1 12 00 00       	call   80103d94 <initlock>
  readsb(dev, &sb);
80102aa3:	83 c4 08             	add    $0x8,%esp
80102aa6:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102aa9:	50                   	push   %eax
80102aaa:	53                   	push   %ebx
80102aab:	e8 92 e7 ff ff       	call   80101242 <readsb>
  log.start = sb.logstart;
80102ab0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102ab3:	a3 b4 43 14 80       	mov    %eax,0x801443b4
  log.size = sb.nlog;
80102ab8:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102abb:	a3 b8 43 14 80       	mov    %eax,0x801443b8
  log.dev = dev;
80102ac0:	89 1d c4 43 14 80    	mov    %ebx,0x801443c4
  recover_from_log();
80102ac6:	e8 e7 fe ff ff       	call   801029b2 <recover_from_log>
}
80102acb:	83 c4 10             	add    $0x10,%esp
80102ace:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102ad1:	c9                   	leave  
80102ad2:	c3                   	ret    

80102ad3 <begin_op>:
{
80102ad3:	55                   	push   %ebp
80102ad4:	89 e5                	mov    %esp,%ebp
80102ad6:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
80102ad9:	68 80 43 14 80       	push   $0x80144380
80102ade:	e8 ed 13 00 00       	call   80103ed0 <acquire>
80102ae3:	83 c4 10             	add    $0x10,%esp
80102ae6:	eb 15                	jmp    80102afd <begin_op+0x2a>
      sleep(&log, &log.lock);
80102ae8:	83 ec 08             	sub    $0x8,%esp
80102aeb:	68 80 43 14 80       	push   $0x80144380
80102af0:	68 80 43 14 80       	push   $0x80144380
80102af5:	e8 db 0e 00 00       	call   801039d5 <sleep>
80102afa:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
80102afd:	83 3d c0 43 14 80 00 	cmpl   $0x0,0x801443c0
80102b04:	75 e2                	jne    80102ae8 <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80102b06:	a1 bc 43 14 80       	mov    0x801443bc,%eax
80102b0b:	83 c0 01             	add    $0x1,%eax
80102b0e:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
80102b11:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
80102b14:	03 15 c8 43 14 80    	add    0x801443c8,%edx
80102b1a:	83 fa 1e             	cmp    $0x1e,%edx
80102b1d:	7e 17                	jle    80102b36 <begin_op+0x63>
      sleep(&log, &log.lock);
80102b1f:	83 ec 08             	sub    $0x8,%esp
80102b22:	68 80 43 14 80       	push   $0x80144380
80102b27:	68 80 43 14 80       	push   $0x80144380
80102b2c:	e8 a4 0e 00 00       	call   801039d5 <sleep>
80102b31:	83 c4 10             	add    $0x10,%esp
80102b34:	eb c7                	jmp    80102afd <begin_op+0x2a>
      log.outstanding += 1;
80102b36:	a3 bc 43 14 80       	mov    %eax,0x801443bc
      release(&log.lock);
80102b3b:	83 ec 0c             	sub    $0xc,%esp
80102b3e:	68 80 43 14 80       	push   $0x80144380
80102b43:	e8 ed 13 00 00       	call   80103f35 <release>
}
80102b48:	83 c4 10             	add    $0x10,%esp
80102b4b:	c9                   	leave  
80102b4c:	c3                   	ret    

80102b4d <end_op>:
{
80102b4d:	55                   	push   %ebp
80102b4e:	89 e5                	mov    %esp,%ebp
80102b50:	53                   	push   %ebx
80102b51:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
80102b54:	68 80 43 14 80       	push   $0x80144380
80102b59:	e8 72 13 00 00       	call   80103ed0 <acquire>
  log.outstanding -= 1;
80102b5e:	a1 bc 43 14 80       	mov    0x801443bc,%eax
80102b63:	83 e8 01             	sub    $0x1,%eax
80102b66:	a3 bc 43 14 80       	mov    %eax,0x801443bc
  if(log.committing)
80102b6b:	8b 1d c0 43 14 80    	mov    0x801443c0,%ebx
80102b71:	83 c4 10             	add    $0x10,%esp
80102b74:	85 db                	test   %ebx,%ebx
80102b76:	75 2c                	jne    80102ba4 <end_op+0x57>
  if(log.outstanding == 0){
80102b78:	85 c0                	test   %eax,%eax
80102b7a:	75 35                	jne    80102bb1 <end_op+0x64>
    log.committing = 1;
80102b7c:	c7 05 c0 43 14 80 01 	movl   $0x1,0x801443c0
80102b83:	00 00 00 
    do_commit = 1;
80102b86:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
80102b8b:	83 ec 0c             	sub    $0xc,%esp
80102b8e:	68 80 43 14 80       	push   $0x80144380
80102b93:	e8 9d 13 00 00       	call   80103f35 <release>
  if(do_commit){
80102b98:	83 c4 10             	add    $0x10,%esp
80102b9b:	85 db                	test   %ebx,%ebx
80102b9d:	75 24                	jne    80102bc3 <end_op+0x76>
}
80102b9f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102ba2:	c9                   	leave  
80102ba3:	c3                   	ret    
    panic("log.committing");
80102ba4:	83 ec 0c             	sub    $0xc,%esp
80102ba7:	68 84 6c 10 80       	push   $0x80106c84
80102bac:	e8 97 d7 ff ff       	call   80100348 <panic>
    wakeup(&log);
80102bb1:	83 ec 0c             	sub    $0xc,%esp
80102bb4:	68 80 43 14 80       	push   $0x80144380
80102bb9:	e8 7c 0f 00 00       	call   80103b3a <wakeup>
80102bbe:	83 c4 10             	add    $0x10,%esp
80102bc1:	eb c8                	jmp    80102b8b <end_op+0x3e>
    commit();
80102bc3:	e8 91 fe ff ff       	call   80102a59 <commit>
    acquire(&log.lock);
80102bc8:	83 ec 0c             	sub    $0xc,%esp
80102bcb:	68 80 43 14 80       	push   $0x80144380
80102bd0:	e8 fb 12 00 00       	call   80103ed0 <acquire>
    log.committing = 0;
80102bd5:	c7 05 c0 43 14 80 00 	movl   $0x0,0x801443c0
80102bdc:	00 00 00 
    wakeup(&log);
80102bdf:	c7 04 24 80 43 14 80 	movl   $0x80144380,(%esp)
80102be6:	e8 4f 0f 00 00       	call   80103b3a <wakeup>
    release(&log.lock);
80102beb:	c7 04 24 80 43 14 80 	movl   $0x80144380,(%esp)
80102bf2:	e8 3e 13 00 00       	call   80103f35 <release>
80102bf7:	83 c4 10             	add    $0x10,%esp
}
80102bfa:	eb a3                	jmp    80102b9f <end_op+0x52>

80102bfc <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80102bfc:	55                   	push   %ebp
80102bfd:	89 e5                	mov    %esp,%ebp
80102bff:	53                   	push   %ebx
80102c00:	83 ec 04             	sub    $0x4,%esp
80102c03:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80102c06:	8b 15 c8 43 14 80    	mov    0x801443c8,%edx
80102c0c:	83 fa 1d             	cmp    $0x1d,%edx
80102c0f:	7f 45                	jg     80102c56 <log_write+0x5a>
80102c11:	a1 b8 43 14 80       	mov    0x801443b8,%eax
80102c16:	83 e8 01             	sub    $0x1,%eax
80102c19:	39 c2                	cmp    %eax,%edx
80102c1b:	7d 39                	jge    80102c56 <log_write+0x5a>
    panic("too big a transaction");
  if (log.outstanding < 1)
80102c1d:	83 3d bc 43 14 80 00 	cmpl   $0x0,0x801443bc
80102c24:	7e 3d                	jle    80102c63 <log_write+0x67>
    panic("log_write outside of trans");

  acquire(&log.lock);
80102c26:	83 ec 0c             	sub    $0xc,%esp
80102c29:	68 80 43 14 80       	push   $0x80144380
80102c2e:	e8 9d 12 00 00       	call   80103ed0 <acquire>
  for (i = 0; i < log.lh.n; i++) {
80102c33:	83 c4 10             	add    $0x10,%esp
80102c36:	b8 00 00 00 00       	mov    $0x0,%eax
80102c3b:	8b 15 c8 43 14 80    	mov    0x801443c8,%edx
80102c41:	39 c2                	cmp    %eax,%edx
80102c43:	7e 2b                	jle    80102c70 <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
80102c45:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102c48:	39 0c 85 cc 43 14 80 	cmp    %ecx,-0x7febbc34(,%eax,4)
80102c4f:	74 1f                	je     80102c70 <log_write+0x74>
  for (i = 0; i < log.lh.n; i++) {
80102c51:	83 c0 01             	add    $0x1,%eax
80102c54:	eb e5                	jmp    80102c3b <log_write+0x3f>
    panic("too big a transaction");
80102c56:	83 ec 0c             	sub    $0xc,%esp
80102c59:	68 93 6c 10 80       	push   $0x80106c93
80102c5e:	e8 e5 d6 ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
80102c63:	83 ec 0c             	sub    $0xc,%esp
80102c66:	68 a9 6c 10 80       	push   $0x80106ca9
80102c6b:	e8 d8 d6 ff ff       	call   80100348 <panic>
      break;
  }
  log.lh.block[i] = b->blockno;
80102c70:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102c73:	89 0c 85 cc 43 14 80 	mov    %ecx,-0x7febbc34(,%eax,4)
  if (i == log.lh.n)
80102c7a:	39 c2                	cmp    %eax,%edx
80102c7c:	74 18                	je     80102c96 <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102c7e:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
80102c81:	83 ec 0c             	sub    $0xc,%esp
80102c84:	68 80 43 14 80       	push   $0x80144380
80102c89:	e8 a7 12 00 00       	call   80103f35 <release>
}
80102c8e:	83 c4 10             	add    $0x10,%esp
80102c91:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102c94:	c9                   	leave  
80102c95:	c3                   	ret    
    log.lh.n++;
80102c96:	83 c2 01             	add    $0x1,%edx
80102c99:	89 15 c8 43 14 80    	mov    %edx,0x801443c8
80102c9f:	eb dd                	jmp    80102c7e <log_write+0x82>

80102ca1 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80102ca1:	55                   	push   %ebp
80102ca2:	89 e5                	mov    %esp,%ebp
80102ca4:	53                   	push   %ebx
80102ca5:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102ca8:	68 8a 00 00 00       	push   $0x8a
80102cad:	68 8c a4 10 80       	push   $0x8010a48c
80102cb2:	68 00 70 00 80       	push   $0x80007000
80102cb7:	e8 3b 13 00 00       	call   80103ff7 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102cbc:	83 c4 10             	add    $0x10,%esp
80102cbf:	bb 80 44 14 80       	mov    $0x80144480,%ebx
80102cc4:	eb 06                	jmp    80102ccc <startothers+0x2b>
80102cc6:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102ccc:	69 05 00 4a 14 80 b0 	imul   $0xb0,0x80144a00,%eax
80102cd3:	00 00 00 
80102cd6:	05 80 44 14 80       	add    $0x80144480,%eax
80102cdb:	39 d8                	cmp    %ebx,%eax
80102cdd:	76 51                	jbe    80102d30 <startothers+0x8f>
    if(c == mycpu())  // We've started already.
80102cdf:	e8 d3 07 00 00       	call   801034b7 <mycpu>
80102ce4:	39 d8                	cmp    %ebx,%eax
80102ce6:	74 de                	je     80102cc6 <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc2(-2);
80102ce8:	83 ec 0c             	sub    $0xc,%esp
80102ceb:	6a fe                	push   $0xfffffffe
80102ced:	e8 8c f5 ff ff       	call   8010227e <kalloc2>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102cf2:	05 00 10 00 00       	add    $0x1000,%eax
80102cf7:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
80102cfc:	c7 05 f8 6f 00 80 74 	movl   $0x80102d74,0x80006ff8
80102d03:	2d 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
80102d06:	c7 05 f4 6f 00 80 00 	movl   $0x109000,0x80006ff4
80102d0d:	90 10 00 

    lapicstartap(c->apicid, V2P(code));
80102d10:	83 c4 08             	add    $0x8,%esp
80102d13:	68 00 70 00 00       	push   $0x7000
80102d18:	0f b6 03             	movzbl (%ebx),%eax
80102d1b:	50                   	push   %eax
80102d1c:	e8 c1 f9 ff ff       	call   801026e2 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80102d21:	83 c4 10             	add    $0x10,%esp
80102d24:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
80102d2a:	85 c0                	test   %eax,%eax
80102d2c:	74 f6                	je     80102d24 <startothers+0x83>
80102d2e:	eb 96                	jmp    80102cc6 <startothers+0x25>
      ;
  }
}
80102d30:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102d33:	c9                   	leave  
80102d34:	c3                   	ret    

80102d35 <mpmain>:
{
80102d35:	55                   	push   %ebp
80102d36:	89 e5                	mov    %esp,%ebp
80102d38:	53                   	push   %ebx
80102d39:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80102d3c:	e8 d2 07 00 00       	call   80103513 <cpuid>
80102d41:	89 c3                	mov    %eax,%ebx
80102d43:	e8 cb 07 00 00       	call   80103513 <cpuid>
80102d48:	83 ec 04             	sub    $0x4,%esp
80102d4b:	53                   	push   %ebx
80102d4c:	50                   	push   %eax
80102d4d:	68 c4 6c 10 80       	push   $0x80106cc4
80102d52:	e8 b4 d8 ff ff       	call   8010060b <cprintf>
  idtinit();       // load idt register
80102d57:	e8 f2 23 00 00       	call   8010514e <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102d5c:	e8 56 07 00 00       	call   801034b7 <mycpu>
80102d61:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102d63:	b8 01 00 00 00       	mov    $0x1,%eax
80102d68:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102d6f:	e8 3c 0a 00 00       	call   801037b0 <scheduler>

80102d74 <mpenter>:
{
80102d74:	55                   	push   %ebp
80102d75:	89 e5                	mov    %esp,%ebp
80102d77:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102d7a:	e8 d8 33 00 00       	call   80106157 <switchkvm>
  seginit();
80102d7f:	e8 87 32 00 00       	call   8010600b <seginit>
  lapicinit();
80102d84:	e8 10 f8 ff ff       	call   80102599 <lapicinit>
  mpmain();
80102d89:	e8 a7 ff ff ff       	call   80102d35 <mpmain>

80102d8e <main>:
{
80102d8e:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102d92:	83 e4 f0             	and    $0xfffffff0,%esp
80102d95:	ff 71 fc             	pushl  -0x4(%ecx)
80102d98:	55                   	push   %ebp
80102d99:	89 e5                	mov    %esp,%ebp
80102d9b:	51                   	push   %ecx
80102d9c:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102d9f:	68 00 00 40 80       	push   $0x80400000
80102da4:	68 a8 71 14 80       	push   $0x801471a8
80102da9:	e8 78 f3 ff ff       	call   80102126 <kinit1>
  kvmalloc();      // kernel page table
80102dae:	e8 3a 38 00 00       	call   801065ed <kvmalloc>
  mpinit();        // detect other processors
80102db3:	e8 c9 01 00 00       	call   80102f81 <mpinit>
  lapicinit();     // interrupt controller
80102db8:	e8 dc f7 ff ff       	call   80102599 <lapicinit>
  seginit();       // segment descriptors
80102dbd:	e8 49 32 00 00       	call   8010600b <seginit>
  picinit();       // disable pic
80102dc2:	e8 82 02 00 00       	call   80103049 <picinit>
  ioapicinit();    // another interrupt controller
80102dc7:	e8 3a f1 ff ff       	call   80101f06 <ioapicinit>
  consoleinit();   // console hardware
80102dcc:	e8 bd da ff ff       	call   8010088e <consoleinit>
  uartinit();      // serial port
80102dd1:	e8 26 26 00 00       	call   801053fc <uartinit>
  pinit();         // process table
80102dd6:	e8 c2 06 00 00       	call   8010349d <pinit>
  tvinit();        // trap vectors
80102ddb:	e8 bd 22 00 00       	call   8010509d <tvinit>
  binit();         // buffer cache
80102de0:	e8 0f d3 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102de5:	e8 35 de ff ff       	call   80100c1f <fileinit>
  ideinit();       // disk 
80102dea:	e8 1d ef ff ff       	call   80101d0c <ideinit>
  startothers();   // start other processors
80102def:	e8 ad fe ff ff       	call   80102ca1 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102df4:	83 c4 08             	add    $0x8,%esp
80102df7:	68 00 00 00 8e       	push   $0x8e000000
80102dfc:	68 00 00 40 80       	push   $0x80400000
80102e01:	e8 52 f3 ff ff       	call   80102158 <kinit2>
  userinit();      // first user process
80102e06:	e8 47 07 00 00       	call   80103552 <userinit>
  mpmain();        // finish this processor's setup
80102e0b:	e8 25 ff ff ff       	call   80102d35 <mpmain>

80102e10 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102e10:	55                   	push   %ebp
80102e11:	89 e5                	mov    %esp,%ebp
80102e13:	56                   	push   %esi
80102e14:	53                   	push   %ebx
  int i, sum;

  sum = 0;
80102e15:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(i=0; i<len; i++)
80102e1a:	b9 00 00 00 00       	mov    $0x0,%ecx
80102e1f:	eb 09                	jmp    80102e2a <sum+0x1a>
    sum += addr[i];
80102e21:	0f b6 34 08          	movzbl (%eax,%ecx,1),%esi
80102e25:	01 f3                	add    %esi,%ebx
  for(i=0; i<len; i++)
80102e27:	83 c1 01             	add    $0x1,%ecx
80102e2a:	39 d1                	cmp    %edx,%ecx
80102e2c:	7c f3                	jl     80102e21 <sum+0x11>
  return sum;
}
80102e2e:	89 d8                	mov    %ebx,%eax
80102e30:	5b                   	pop    %ebx
80102e31:	5e                   	pop    %esi
80102e32:	5d                   	pop    %ebp
80102e33:	c3                   	ret    

80102e34 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102e34:	55                   	push   %ebp
80102e35:	89 e5                	mov    %esp,%ebp
80102e37:	56                   	push   %esi
80102e38:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102e39:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102e3f:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102e41:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102e43:	eb 03                	jmp    80102e48 <mpsearch1+0x14>
80102e45:	83 c3 10             	add    $0x10,%ebx
80102e48:	39 f3                	cmp    %esi,%ebx
80102e4a:	73 29                	jae    80102e75 <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102e4c:	83 ec 04             	sub    $0x4,%esp
80102e4f:	6a 04                	push   $0x4
80102e51:	68 d8 6c 10 80       	push   $0x80106cd8
80102e56:	53                   	push   %ebx
80102e57:	e8 66 11 00 00       	call   80103fc2 <memcmp>
80102e5c:	83 c4 10             	add    $0x10,%esp
80102e5f:	85 c0                	test   %eax,%eax
80102e61:	75 e2                	jne    80102e45 <mpsearch1+0x11>
80102e63:	ba 10 00 00 00       	mov    $0x10,%edx
80102e68:	89 d8                	mov    %ebx,%eax
80102e6a:	e8 a1 ff ff ff       	call   80102e10 <sum>
80102e6f:	84 c0                	test   %al,%al
80102e71:	75 d2                	jne    80102e45 <mpsearch1+0x11>
80102e73:	eb 05                	jmp    80102e7a <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102e75:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102e7a:	89 d8                	mov    %ebx,%eax
80102e7c:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102e7f:	5b                   	pop    %ebx
80102e80:	5e                   	pop    %esi
80102e81:	5d                   	pop    %ebp
80102e82:	c3                   	ret    

80102e83 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102e83:	55                   	push   %ebp
80102e84:	89 e5                	mov    %esp,%ebp
80102e86:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102e89:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102e90:	c1 e0 08             	shl    $0x8,%eax
80102e93:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102e9a:	09 d0                	or     %edx,%eax
80102e9c:	c1 e0 04             	shl    $0x4,%eax
80102e9f:	85 c0                	test   %eax,%eax
80102ea1:	74 1f                	je     80102ec2 <mpsearch+0x3f>
    if((mp = mpsearch1(p, 1024)))
80102ea3:	ba 00 04 00 00       	mov    $0x400,%edx
80102ea8:	e8 87 ff ff ff       	call   80102e34 <mpsearch1>
80102ead:	85 c0                	test   %eax,%eax
80102eaf:	75 0f                	jne    80102ec0 <mpsearch+0x3d>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102eb1:	ba 00 00 01 00       	mov    $0x10000,%edx
80102eb6:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102ebb:	e8 74 ff ff ff       	call   80102e34 <mpsearch1>
}
80102ec0:	c9                   	leave  
80102ec1:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102ec2:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102ec9:	c1 e0 08             	shl    $0x8,%eax
80102ecc:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102ed3:	09 d0                	or     %edx,%eax
80102ed5:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102ed8:	2d 00 04 00 00       	sub    $0x400,%eax
80102edd:	ba 00 04 00 00       	mov    $0x400,%edx
80102ee2:	e8 4d ff ff ff       	call   80102e34 <mpsearch1>
80102ee7:	85 c0                	test   %eax,%eax
80102ee9:	75 d5                	jne    80102ec0 <mpsearch+0x3d>
80102eeb:	eb c4                	jmp    80102eb1 <mpsearch+0x2e>

80102eed <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102eed:	55                   	push   %ebp
80102eee:	89 e5                	mov    %esp,%ebp
80102ef0:	57                   	push   %edi
80102ef1:	56                   	push   %esi
80102ef2:	53                   	push   %ebx
80102ef3:	83 ec 1c             	sub    $0x1c,%esp
80102ef6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102ef9:	e8 85 ff ff ff       	call   80102e83 <mpsearch>
80102efe:	85 c0                	test   %eax,%eax
80102f00:	74 5c                	je     80102f5e <mpconfig+0x71>
80102f02:	89 c7                	mov    %eax,%edi
80102f04:	8b 58 04             	mov    0x4(%eax),%ebx
80102f07:	85 db                	test   %ebx,%ebx
80102f09:	74 5a                	je     80102f65 <mpconfig+0x78>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102f0b:	8d b3 00 00 00 80    	lea    -0x80000000(%ebx),%esi
  if(memcmp(conf, "PCMP", 4) != 0)
80102f11:	83 ec 04             	sub    $0x4,%esp
80102f14:	6a 04                	push   $0x4
80102f16:	68 dd 6c 10 80       	push   $0x80106cdd
80102f1b:	56                   	push   %esi
80102f1c:	e8 a1 10 00 00       	call   80103fc2 <memcmp>
80102f21:	83 c4 10             	add    $0x10,%esp
80102f24:	85 c0                	test   %eax,%eax
80102f26:	75 44                	jne    80102f6c <mpconfig+0x7f>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102f28:	0f b6 83 06 00 00 80 	movzbl -0x7ffffffa(%ebx),%eax
80102f2f:	3c 01                	cmp    $0x1,%al
80102f31:	0f 95 c2             	setne  %dl
80102f34:	3c 04                	cmp    $0x4,%al
80102f36:	0f 95 c0             	setne  %al
80102f39:	84 c2                	test   %al,%dl
80102f3b:	75 36                	jne    80102f73 <mpconfig+0x86>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102f3d:	0f b7 93 04 00 00 80 	movzwl -0x7ffffffc(%ebx),%edx
80102f44:	89 f0                	mov    %esi,%eax
80102f46:	e8 c5 fe ff ff       	call   80102e10 <sum>
80102f4b:	84 c0                	test   %al,%al
80102f4d:	75 2b                	jne    80102f7a <mpconfig+0x8d>
    return 0;
  *pmp = mp;
80102f4f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102f52:	89 38                	mov    %edi,(%eax)
  return conf;
}
80102f54:	89 f0                	mov    %esi,%eax
80102f56:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102f59:	5b                   	pop    %ebx
80102f5a:	5e                   	pop    %esi
80102f5b:	5f                   	pop    %edi
80102f5c:	5d                   	pop    %ebp
80102f5d:	c3                   	ret    
    return 0;
80102f5e:	be 00 00 00 00       	mov    $0x0,%esi
80102f63:	eb ef                	jmp    80102f54 <mpconfig+0x67>
80102f65:	be 00 00 00 00       	mov    $0x0,%esi
80102f6a:	eb e8                	jmp    80102f54 <mpconfig+0x67>
    return 0;
80102f6c:	be 00 00 00 00       	mov    $0x0,%esi
80102f71:	eb e1                	jmp    80102f54 <mpconfig+0x67>
    return 0;
80102f73:	be 00 00 00 00       	mov    $0x0,%esi
80102f78:	eb da                	jmp    80102f54 <mpconfig+0x67>
    return 0;
80102f7a:	be 00 00 00 00       	mov    $0x0,%esi
80102f7f:	eb d3                	jmp    80102f54 <mpconfig+0x67>

80102f81 <mpinit>:

void
mpinit(void)
{
80102f81:	55                   	push   %ebp
80102f82:	89 e5                	mov    %esp,%ebp
80102f84:	57                   	push   %edi
80102f85:	56                   	push   %esi
80102f86:	53                   	push   %ebx
80102f87:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102f8a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102f8d:	e8 5b ff ff ff       	call   80102eed <mpconfig>
80102f92:	85 c0                	test   %eax,%eax
80102f94:	74 19                	je     80102faf <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102f96:	8b 50 24             	mov    0x24(%eax),%edx
80102f99:	89 15 60 43 14 80    	mov    %edx,0x80144360
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102f9f:	8d 50 2c             	lea    0x2c(%eax),%edx
80102fa2:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102fa6:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102fa8:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102fad:	eb 34                	jmp    80102fe3 <mpinit+0x62>
    panic("Expect to run on an SMP");
80102faf:	83 ec 0c             	sub    $0xc,%esp
80102fb2:	68 e2 6c 10 80       	push   $0x80106ce2
80102fb7:	e8 8c d3 ff ff       	call   80100348 <panic>
    switch(*p){
    case MPPROC:
      proc = (struct mpproc*)p;
      if(ncpu < NCPU) {
80102fbc:	8b 35 00 4a 14 80    	mov    0x80144a00,%esi
80102fc2:	83 fe 07             	cmp    $0x7,%esi
80102fc5:	7f 19                	jg     80102fe0 <mpinit+0x5f>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102fc7:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102fcb:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102fd1:	88 87 80 44 14 80    	mov    %al,-0x7febbb80(%edi)
        ncpu++;
80102fd7:	83 c6 01             	add    $0x1,%esi
80102fda:	89 35 00 4a 14 80    	mov    %esi,0x80144a00
      }
      p += sizeof(struct mpproc);
80102fe0:	83 c2 14             	add    $0x14,%edx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102fe3:	39 ca                	cmp    %ecx,%edx
80102fe5:	73 2b                	jae    80103012 <mpinit+0x91>
    switch(*p){
80102fe7:	0f b6 02             	movzbl (%edx),%eax
80102fea:	3c 04                	cmp    $0x4,%al
80102fec:	77 1d                	ja     8010300b <mpinit+0x8a>
80102fee:	0f b6 c0             	movzbl %al,%eax
80102ff1:	ff 24 85 1c 6d 10 80 	jmp    *-0x7fef92e4(,%eax,4)
      continue;
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
      ioapicid = ioapic->apicno;
80102ff8:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102ffc:	a2 60 44 14 80       	mov    %al,0x80144460
      p += sizeof(struct mpioapic);
80103001:	83 c2 08             	add    $0x8,%edx
      continue;
80103004:	eb dd                	jmp    80102fe3 <mpinit+0x62>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103006:	83 c2 08             	add    $0x8,%edx
      continue;
80103009:	eb d8                	jmp    80102fe3 <mpinit+0x62>
    default:
      ismp = 0;
8010300b:	bb 00 00 00 00       	mov    $0x0,%ebx
80103010:	eb d1                	jmp    80102fe3 <mpinit+0x62>
      break;
    }
  }
  if(!ismp)
80103012:	85 db                	test   %ebx,%ebx
80103014:	74 26                	je     8010303c <mpinit+0xbb>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80103016:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103019:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
8010301d:	74 15                	je     80103034 <mpinit+0xb3>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010301f:	b8 70 00 00 00       	mov    $0x70,%eax
80103024:	ba 22 00 00 00       	mov    $0x22,%edx
80103029:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010302a:	ba 23 00 00 00       	mov    $0x23,%edx
8010302f:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103030:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103033:	ee                   	out    %al,(%dx)
  }
}
80103034:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103037:	5b                   	pop    %ebx
80103038:	5e                   	pop    %esi
80103039:	5f                   	pop    %edi
8010303a:	5d                   	pop    %ebp
8010303b:	c3                   	ret    
    panic("Didn't find a suitable machine");
8010303c:	83 ec 0c             	sub    $0xc,%esp
8010303f:	68 fc 6c 10 80       	push   $0x80106cfc
80103044:	e8 ff d2 ff ff       	call   80100348 <panic>

80103049 <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80103049:	55                   	push   %ebp
8010304a:	89 e5                	mov    %esp,%ebp
8010304c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103051:	ba 21 00 00 00       	mov    $0x21,%edx
80103056:	ee                   	out    %al,(%dx)
80103057:	ba a1 00 00 00       	mov    $0xa1,%edx
8010305c:	ee                   	out    %al,(%dx)
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
8010305d:	5d                   	pop    %ebp
8010305e:	c3                   	ret    

8010305f <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
8010305f:	55                   	push   %ebp
80103060:	89 e5                	mov    %esp,%ebp
80103062:	57                   	push   %edi
80103063:	56                   	push   %esi
80103064:	53                   	push   %ebx
80103065:	83 ec 0c             	sub    $0xc,%esp
80103068:	8b 5d 08             	mov    0x8(%ebp),%ebx
8010306b:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
8010306e:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80103074:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
8010307a:	e8 ba db ff ff       	call   80100c39 <filealloc>
8010307f:	89 03                	mov    %eax,(%ebx)
80103081:	85 c0                	test   %eax,%eax
80103083:	74 1e                	je     801030a3 <pipealloc+0x44>
80103085:	e8 af db ff ff       	call   80100c39 <filealloc>
8010308a:	89 06                	mov    %eax,(%esi)
8010308c:	85 c0                	test   %eax,%eax
8010308e:	74 13                	je     801030a3 <pipealloc+0x44>
    goto bad;
  if((p = (struct pipe*)kalloc2(-2)) == 0)
80103090:	83 ec 0c             	sub    $0xc,%esp
80103093:	6a fe                	push   $0xfffffffe
80103095:	e8 e4 f1 ff ff       	call   8010227e <kalloc2>
8010309a:	89 c7                	mov    %eax,%edi
8010309c:	83 c4 10             	add    $0x10,%esp
8010309f:	85 c0                	test   %eax,%eax
801030a1:	75 35                	jne    801030d8 <pipealloc+0x79>
  return 0;

 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
801030a3:	8b 03                	mov    (%ebx),%eax
801030a5:	85 c0                	test   %eax,%eax
801030a7:	74 0c                	je     801030b5 <pipealloc+0x56>
    fileclose(*f0);
801030a9:	83 ec 0c             	sub    $0xc,%esp
801030ac:	50                   	push   %eax
801030ad:	e8 2d dc ff ff       	call   80100cdf <fileclose>
801030b2:	83 c4 10             	add    $0x10,%esp
  if(*f1)
801030b5:	8b 06                	mov    (%esi),%eax
801030b7:	85 c0                	test   %eax,%eax
801030b9:	0f 84 8b 00 00 00    	je     8010314a <pipealloc+0xeb>
    fileclose(*f1);
801030bf:	83 ec 0c             	sub    $0xc,%esp
801030c2:	50                   	push   %eax
801030c3:	e8 17 dc ff ff       	call   80100cdf <fileclose>
801030c8:	83 c4 10             	add    $0x10,%esp
  return -1;
801030cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801030d0:	8d 65 f4             	lea    -0xc(%ebp),%esp
801030d3:	5b                   	pop    %ebx
801030d4:	5e                   	pop    %esi
801030d5:	5f                   	pop    %edi
801030d6:	5d                   	pop    %ebp
801030d7:	c3                   	ret    
  p->readopen = 1;
801030d8:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
801030df:	00 00 00 
  p->writeopen = 1;
801030e2:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
801030e9:	00 00 00 
  p->nwrite = 0;
801030ec:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
801030f3:	00 00 00 
  p->nread = 0;
801030f6:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
801030fd:	00 00 00 
  initlock(&p->lock, "pipe");
80103100:	83 ec 08             	sub    $0x8,%esp
80103103:	68 30 6d 10 80       	push   $0x80106d30
80103108:	50                   	push   %eax
80103109:	e8 86 0c 00 00       	call   80103d94 <initlock>
  (*f0)->type = FD_PIPE;
8010310e:	8b 03                	mov    (%ebx),%eax
80103110:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103116:	8b 03                	mov    (%ebx),%eax
80103118:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
8010311c:	8b 03                	mov    (%ebx),%eax
8010311e:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103122:	8b 03                	mov    (%ebx),%eax
80103124:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103127:	8b 06                	mov    (%esi),%eax
80103129:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
8010312f:	8b 06                	mov    (%esi),%eax
80103131:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103135:	8b 06                	mov    (%esi),%eax
80103137:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
8010313b:	8b 06                	mov    (%esi),%eax
8010313d:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80103140:	83 c4 10             	add    $0x10,%esp
80103143:	b8 00 00 00 00       	mov    $0x0,%eax
80103148:	eb 86                	jmp    801030d0 <pipealloc+0x71>
  return -1;
8010314a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010314f:	e9 7c ff ff ff       	jmp    801030d0 <pipealloc+0x71>

80103154 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103154:	55                   	push   %ebp
80103155:	89 e5                	mov    %esp,%ebp
80103157:	53                   	push   %ebx
80103158:	83 ec 10             	sub    $0x10,%esp
8010315b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
8010315e:	53                   	push   %ebx
8010315f:	e8 6c 0d 00 00       	call   80103ed0 <acquire>
  if(writable){
80103164:	83 c4 10             	add    $0x10,%esp
80103167:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010316b:	74 3f                	je     801031ac <pipeclose+0x58>
    p->writeopen = 0;
8010316d:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80103174:	00 00 00 
    wakeup(&p->nread);
80103177:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
8010317d:	83 ec 0c             	sub    $0xc,%esp
80103180:	50                   	push   %eax
80103181:	e8 b4 09 00 00       	call   80103b3a <wakeup>
80103186:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80103189:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80103190:	75 09                	jne    8010319b <pipeclose+0x47>
80103192:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80103199:	74 2f                	je     801031ca <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
8010319b:	83 ec 0c             	sub    $0xc,%esp
8010319e:	53                   	push   %ebx
8010319f:	e8 91 0d 00 00       	call   80103f35 <release>
801031a4:	83 c4 10             	add    $0x10,%esp
}
801031a7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801031aa:	c9                   	leave  
801031ab:	c3                   	ret    
    p->readopen = 0;
801031ac:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
801031b3:	00 00 00 
    wakeup(&p->nwrite);
801031b6:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
801031bc:	83 ec 0c             	sub    $0xc,%esp
801031bf:	50                   	push   %eax
801031c0:	e8 75 09 00 00       	call   80103b3a <wakeup>
801031c5:	83 c4 10             	add    $0x10,%esp
801031c8:	eb bf                	jmp    80103189 <pipeclose+0x35>
    release(&p->lock);
801031ca:	83 ec 0c             	sub    $0xc,%esp
801031cd:	53                   	push   %ebx
801031ce:	e8 62 0d 00 00       	call   80103f35 <release>
    kfree((char*)p);
801031d3:	89 1c 24             	mov    %ebx,(%esp)
801031d6:	e8 d5 ed ff ff       	call   80101fb0 <kfree>
801031db:	83 c4 10             	add    $0x10,%esp
801031de:	eb c7                	jmp    801031a7 <pipeclose+0x53>

801031e0 <pipewrite>:

int
pipewrite(struct pipe *p, char *addr, int n)
{
801031e0:	55                   	push   %ebp
801031e1:	89 e5                	mov    %esp,%ebp
801031e3:	57                   	push   %edi
801031e4:	56                   	push   %esi
801031e5:	53                   	push   %ebx
801031e6:	83 ec 18             	sub    $0x18,%esp
801031e9:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
801031ec:	89 de                	mov    %ebx,%esi
801031ee:	53                   	push   %ebx
801031ef:	e8 dc 0c 00 00       	call   80103ed0 <acquire>
  for(i = 0; i < n; i++){
801031f4:	83 c4 10             	add    $0x10,%esp
801031f7:	bf 00 00 00 00       	mov    $0x0,%edi
801031fc:	3b 7d 10             	cmp    0x10(%ebp),%edi
801031ff:	0f 8d 88 00 00 00    	jge    8010328d <pipewrite+0xad>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80103205:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
8010320b:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80103211:	05 00 02 00 00       	add    $0x200,%eax
80103216:	39 c2                	cmp    %eax,%edx
80103218:	75 51                	jne    8010326b <pipewrite+0x8b>
      if(p->readopen == 0 || myproc()->killed){
8010321a:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80103221:	74 2f                	je     80103252 <pipewrite+0x72>
80103223:	e8 06 03 00 00       	call   8010352e <myproc>
80103228:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010322c:	75 24                	jne    80103252 <pipewrite+0x72>
        release(&p->lock);
        return -1;
      }
      wakeup(&p->nread);
8010322e:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103234:	83 ec 0c             	sub    $0xc,%esp
80103237:	50                   	push   %eax
80103238:	e8 fd 08 00 00       	call   80103b3a <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
8010323d:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80103243:	83 c4 08             	add    $0x8,%esp
80103246:	56                   	push   %esi
80103247:	50                   	push   %eax
80103248:	e8 88 07 00 00       	call   801039d5 <sleep>
8010324d:	83 c4 10             	add    $0x10,%esp
80103250:	eb b3                	jmp    80103205 <pipewrite+0x25>
        release(&p->lock);
80103252:	83 ec 0c             	sub    $0xc,%esp
80103255:	53                   	push   %ebx
80103256:	e8 da 0c 00 00       	call   80103f35 <release>
        return -1;
8010325b:	83 c4 10             	add    $0x10,%esp
8010325e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
  release(&p->lock);
  return n;
}
80103263:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103266:	5b                   	pop    %ebx
80103267:	5e                   	pop    %esi
80103268:	5f                   	pop    %edi
80103269:	5d                   	pop    %ebp
8010326a:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
8010326b:	8d 42 01             	lea    0x1(%edx),%eax
8010326e:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80103274:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
8010327a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010327d:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
80103281:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
80103285:	83 c7 01             	add    $0x1,%edi
80103288:	e9 6f ff ff ff       	jmp    801031fc <pipewrite+0x1c>
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
8010328d:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80103293:	83 ec 0c             	sub    $0xc,%esp
80103296:	50                   	push   %eax
80103297:	e8 9e 08 00 00       	call   80103b3a <wakeup>
  release(&p->lock);
8010329c:	89 1c 24             	mov    %ebx,(%esp)
8010329f:	e8 91 0c 00 00       	call   80103f35 <release>
  return n;
801032a4:	83 c4 10             	add    $0x10,%esp
801032a7:	8b 45 10             	mov    0x10(%ebp),%eax
801032aa:	eb b7                	jmp    80103263 <pipewrite+0x83>

801032ac <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801032ac:	55                   	push   %ebp
801032ad:	89 e5                	mov    %esp,%ebp
801032af:	57                   	push   %edi
801032b0:	56                   	push   %esi
801032b1:	53                   	push   %ebx
801032b2:	83 ec 18             	sub    $0x18,%esp
801032b5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  acquire(&p->lock);
801032b8:	89 df                	mov    %ebx,%edi
801032ba:	53                   	push   %ebx
801032bb:	e8 10 0c 00 00       	call   80103ed0 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801032c0:	83 c4 10             	add    $0x10,%esp
801032c3:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
801032c9:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
801032cf:	75 3d                	jne    8010330e <piperead+0x62>
801032d1:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
801032d7:	85 f6                	test   %esi,%esi
801032d9:	74 38                	je     80103313 <piperead+0x67>
    if(myproc()->killed){
801032db:	e8 4e 02 00 00       	call   8010352e <myproc>
801032e0:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801032e4:	75 15                	jne    801032fb <piperead+0x4f>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801032e6:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
801032ec:	83 ec 08             	sub    $0x8,%esp
801032ef:	57                   	push   %edi
801032f0:	50                   	push   %eax
801032f1:	e8 df 06 00 00       	call   801039d5 <sleep>
801032f6:	83 c4 10             	add    $0x10,%esp
801032f9:	eb c8                	jmp    801032c3 <piperead+0x17>
      release(&p->lock);
801032fb:	83 ec 0c             	sub    $0xc,%esp
801032fe:	53                   	push   %ebx
801032ff:	e8 31 0c 00 00       	call   80103f35 <release>
      return -1;
80103304:	83 c4 10             	add    $0x10,%esp
80103307:	be ff ff ff ff       	mov    $0xffffffff,%esi
8010330c:	eb 50                	jmp    8010335e <piperead+0xb2>
8010330e:	be 00 00 00 00       	mov    $0x0,%esi
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103313:	3b 75 10             	cmp    0x10(%ebp),%esi
80103316:	7d 2c                	jge    80103344 <piperead+0x98>
    if(p->nread == p->nwrite)
80103318:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
8010331e:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
80103324:	74 1e                	je     80103344 <piperead+0x98>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80103326:	8d 50 01             	lea    0x1(%eax),%edx
80103329:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
8010332f:	25 ff 01 00 00       	and    $0x1ff,%eax
80103334:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
80103339:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010333c:	88 04 31             	mov    %al,(%ecx,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010333f:	83 c6 01             	add    $0x1,%esi
80103342:	eb cf                	jmp    80103313 <piperead+0x67>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80103344:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
8010334a:	83 ec 0c             	sub    $0xc,%esp
8010334d:	50                   	push   %eax
8010334e:	e8 e7 07 00 00       	call   80103b3a <wakeup>
  release(&p->lock);
80103353:	89 1c 24             	mov    %ebx,(%esp)
80103356:	e8 da 0b 00 00       	call   80103f35 <release>
  return i;
8010335b:	83 c4 10             	add    $0x10,%esp
}
8010335e:	89 f0                	mov    %esi,%eax
80103360:	8d 65 f4             	lea    -0xc(%ebp),%esp
80103363:	5b                   	pop    %ebx
80103364:	5e                   	pop    %esi
80103365:	5f                   	pop    %edi
80103366:	5d                   	pop    %ebp
80103367:	c3                   	ret    

80103368 <wakeup1>:

// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80103368:	55                   	push   %ebp
80103369:	89 e5                	mov    %esp,%ebp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
8010336b:	ba 54 4a 14 80       	mov    $0x80144a54,%edx
80103370:	eb 03                	jmp    80103375 <wakeup1+0xd>
80103372:	83 c2 7c             	add    $0x7c,%edx
80103375:	81 fa 54 69 14 80    	cmp    $0x80146954,%edx
8010337b:	73 14                	jae    80103391 <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
8010337d:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
80103381:	75 ef                	jne    80103372 <wakeup1+0xa>
80103383:	39 42 20             	cmp    %eax,0x20(%edx)
80103386:	75 ea                	jne    80103372 <wakeup1+0xa>
      p->state = RUNNABLE;
80103388:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
8010338f:	eb e1                	jmp    80103372 <wakeup1+0xa>
}
80103391:	5d                   	pop    %ebp
80103392:	c3                   	ret    

80103393 <allocproc>:
{
80103393:	55                   	push   %ebp
80103394:	89 e5                	mov    %esp,%ebp
80103396:	53                   	push   %ebx
80103397:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
8010339a:	68 20 4a 14 80       	push   $0x80144a20
8010339f:	e8 2c 0b 00 00       	call   80103ed0 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801033a4:	83 c4 10             	add    $0x10,%esp
801033a7:	bb 54 4a 14 80       	mov    $0x80144a54,%ebx
801033ac:	81 fb 54 69 14 80    	cmp    $0x80146954,%ebx
801033b2:	73 0b                	jae    801033bf <allocproc+0x2c>
    if(p->state == UNUSED)
801033b4:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
801033b8:	74 1c                	je     801033d6 <allocproc+0x43>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801033ba:	83 c3 7c             	add    $0x7c,%ebx
801033bd:	eb ed                	jmp    801033ac <allocproc+0x19>
  release(&ptable.lock);
801033bf:	83 ec 0c             	sub    $0xc,%esp
801033c2:	68 20 4a 14 80       	push   $0x80144a20
801033c7:	e8 69 0b 00 00       	call   80103f35 <release>
  return 0;
801033cc:	83 c4 10             	add    $0x10,%esp
801033cf:	bb 00 00 00 00       	mov    $0x0,%ebx
801033d4:	eb 6f                	jmp    80103445 <allocproc+0xb2>
  p->state = EMBRYO;
801033d6:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
801033dd:	a1 04 a0 10 80       	mov    0x8010a004,%eax
801033e2:	8d 50 01             	lea    0x1(%eax),%edx
801033e5:	89 15 04 a0 10 80    	mov    %edx,0x8010a004
801033eb:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
801033ee:	83 ec 0c             	sub    $0xc,%esp
801033f1:	68 20 4a 14 80       	push   $0x80144a20
801033f6:	e8 3a 0b 00 00       	call   80103f35 <release>
  if((p->kstack = kalloc2(p->pid)) == 0){
801033fb:	83 c4 04             	add    $0x4,%esp
801033fe:	ff 73 10             	pushl  0x10(%ebx)
80103401:	e8 78 ee ff ff       	call   8010227e <kalloc2>
80103406:	89 43 08             	mov    %eax,0x8(%ebx)
80103409:	83 c4 10             	add    $0x10,%esp
8010340c:	85 c0                	test   %eax,%eax
8010340e:	74 3c                	je     8010344c <allocproc+0xb9>
  sp -= sizeof *p->tf;
80103410:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
80103416:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
80103419:	c7 80 b0 0f 00 00 92 	movl   $0x80105092,0xfb0(%eax)
80103420:	50 10 80 
  sp -= sizeof *p->context;
80103423:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
80103428:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
8010342b:	83 ec 04             	sub    $0x4,%esp
8010342e:	6a 14                	push   $0x14
80103430:	6a 00                	push   $0x0
80103432:	50                   	push   %eax
80103433:	e8 44 0b 00 00       	call   80103f7c <memset>
  p->context->eip = (uint)forkret;
80103438:	8b 43 1c             	mov    0x1c(%ebx),%eax
8010343b:	c7 40 10 5a 34 10 80 	movl   $0x8010345a,0x10(%eax)
  return p;
80103442:	83 c4 10             	add    $0x10,%esp
}
80103445:	89 d8                	mov    %ebx,%eax
80103447:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010344a:	c9                   	leave  
8010344b:	c3                   	ret    
    p->state = UNUSED;
8010344c:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
80103453:	bb 00 00 00 00       	mov    $0x0,%ebx
80103458:	eb eb                	jmp    80103445 <allocproc+0xb2>

8010345a <forkret>:
{
8010345a:	55                   	push   %ebp
8010345b:	89 e5                	mov    %esp,%ebp
8010345d:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
80103460:	68 20 4a 14 80       	push   $0x80144a20
80103465:	e8 cb 0a 00 00       	call   80103f35 <release>
  if (first) {
8010346a:	83 c4 10             	add    $0x10,%esp
8010346d:	83 3d 00 a0 10 80 00 	cmpl   $0x0,0x8010a000
80103474:	75 02                	jne    80103478 <forkret+0x1e>
}
80103476:	c9                   	leave  
80103477:	c3                   	ret    
    first = 0;
80103478:	c7 05 00 a0 10 80 00 	movl   $0x0,0x8010a000
8010347f:	00 00 00 
    iinit(ROOTDEV);
80103482:	83 ec 0c             	sub    $0xc,%esp
80103485:	6a 01                	push   $0x1
80103487:	e8 6c de ff ff       	call   801012f8 <iinit>
    initlog(ROOTDEV);
8010348c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103493:	e8 f2 f5 ff ff       	call   80102a8a <initlog>
80103498:	83 c4 10             	add    $0x10,%esp
}
8010349b:	eb d9                	jmp    80103476 <forkret+0x1c>

8010349d <pinit>:
{
8010349d:	55                   	push   %ebp
8010349e:	89 e5                	mov    %esp,%ebp
801034a0:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
801034a3:	68 35 6d 10 80       	push   $0x80106d35
801034a8:	68 20 4a 14 80       	push   $0x80144a20
801034ad:	e8 e2 08 00 00       	call   80103d94 <initlock>
}
801034b2:	83 c4 10             	add    $0x10,%esp
801034b5:	c9                   	leave  
801034b6:	c3                   	ret    

801034b7 <mycpu>:
{
801034b7:	55                   	push   %ebp
801034b8:	89 e5                	mov    %esp,%ebp
801034ba:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801034bd:	9c                   	pushf  
801034be:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801034bf:	f6 c4 02             	test   $0x2,%ah
801034c2:	75 28                	jne    801034ec <mycpu+0x35>
  apicid = lapicid();
801034c4:	e8 da f1 ff ff       	call   801026a3 <lapicid>
  for (i = 0; i < ncpu; ++i) {
801034c9:	ba 00 00 00 00       	mov    $0x0,%edx
801034ce:	39 15 00 4a 14 80    	cmp    %edx,0x80144a00
801034d4:	7e 23                	jle    801034f9 <mycpu+0x42>
    if (cpus[i].apicid == apicid)
801034d6:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
801034dc:	0f b6 89 80 44 14 80 	movzbl -0x7febbb80(%ecx),%ecx
801034e3:	39 c1                	cmp    %eax,%ecx
801034e5:	74 1f                	je     80103506 <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
801034e7:	83 c2 01             	add    $0x1,%edx
801034ea:	eb e2                	jmp    801034ce <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
801034ec:	83 ec 0c             	sub    $0xc,%esp
801034ef:	68 18 6e 10 80       	push   $0x80106e18
801034f4:	e8 4f ce ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
801034f9:	83 ec 0c             	sub    $0xc,%esp
801034fc:	68 3c 6d 10 80       	push   $0x80106d3c
80103501:	e8 42 ce ff ff       	call   80100348 <panic>
      return &cpus[i];
80103506:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
8010350c:	05 80 44 14 80       	add    $0x80144480,%eax
}
80103511:	c9                   	leave  
80103512:	c3                   	ret    

80103513 <cpuid>:
cpuid() {
80103513:	55                   	push   %ebp
80103514:	89 e5                	mov    %esp,%ebp
80103516:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
80103519:	e8 99 ff ff ff       	call   801034b7 <mycpu>
8010351e:	2d 80 44 14 80       	sub    $0x80144480,%eax
80103523:	c1 f8 04             	sar    $0x4,%eax
80103526:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
8010352c:	c9                   	leave  
8010352d:	c3                   	ret    

8010352e <myproc>:
myproc(void) {
8010352e:	55                   	push   %ebp
8010352f:	89 e5                	mov    %esp,%ebp
80103531:	53                   	push   %ebx
80103532:	83 ec 04             	sub    $0x4,%esp
  pushcli();
80103535:	e8 b9 08 00 00       	call   80103df3 <pushcli>
  c = mycpu();
8010353a:	e8 78 ff ff ff       	call   801034b7 <mycpu>
  p = c->proc;
8010353f:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103545:	e8 e6 08 00 00       	call   80103e30 <popcli>
}
8010354a:	89 d8                	mov    %ebx,%eax
8010354c:	83 c4 04             	add    $0x4,%esp
8010354f:	5b                   	pop    %ebx
80103550:	5d                   	pop    %ebp
80103551:	c3                   	ret    

80103552 <userinit>:
{
80103552:	55                   	push   %ebp
80103553:	89 e5                	mov    %esp,%ebp
80103555:	53                   	push   %ebx
80103556:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
80103559:	e8 35 fe ff ff       	call   80103393 <allocproc>
8010355e:	89 c3                	mov    %eax,%ebx
  initproc = p;
80103560:	a3 b8 a5 10 80       	mov    %eax,0x8010a5b8
  if((p->pgdir = setupkvm()) == 0)
80103565:	e8 15 30 00 00       	call   8010657f <setupkvm>
8010356a:	89 43 04             	mov    %eax,0x4(%ebx)
8010356d:	85 c0                	test   %eax,%eax
8010356f:	0f 84 b7 00 00 00    	je     8010362c <userinit+0xda>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80103575:	83 ec 04             	sub    $0x4,%esp
80103578:	68 2c 00 00 00       	push   $0x2c
8010357d:	68 60 a4 10 80       	push   $0x8010a460
80103582:	50                   	push   %eax
80103583:	e8 f9 2c 00 00       	call   80106281 <inituvm>
  p->sz = PGSIZE;
80103588:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
8010358e:	83 c4 0c             	add    $0xc,%esp
80103591:	6a 4c                	push   $0x4c
80103593:	6a 00                	push   $0x0
80103595:	ff 73 18             	pushl  0x18(%ebx)
80103598:	e8 df 09 00 00       	call   80103f7c <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
8010359d:	8b 43 18             	mov    0x18(%ebx),%eax
801035a0:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801035a6:	8b 43 18             	mov    0x18(%ebx),%eax
801035a9:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
801035af:	8b 43 18             	mov    0x18(%ebx),%eax
801035b2:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801035b6:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801035ba:	8b 43 18             	mov    0x18(%ebx),%eax
801035bd:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801035c1:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801035c5:	8b 43 18             	mov    0x18(%ebx),%eax
801035c8:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801035cf:	8b 43 18             	mov    0x18(%ebx),%eax
801035d2:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801035d9:	8b 43 18             	mov    0x18(%ebx),%eax
801035dc:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
801035e3:	8d 43 6c             	lea    0x6c(%ebx),%eax
801035e6:	83 c4 0c             	add    $0xc,%esp
801035e9:	6a 10                	push   $0x10
801035eb:	68 65 6d 10 80       	push   $0x80106d65
801035f0:	50                   	push   %eax
801035f1:	e8 ed 0a 00 00       	call   801040e3 <safestrcpy>
  p->cwd = namei("/");
801035f6:	c7 04 24 6e 6d 10 80 	movl   $0x80106d6e,(%esp)
801035fd:	e8 eb e5 ff ff       	call   80101bed <namei>
80103602:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
80103605:	c7 04 24 20 4a 14 80 	movl   $0x80144a20,(%esp)
8010360c:	e8 bf 08 00 00       	call   80103ed0 <acquire>
  p->state = RUNNABLE;
80103611:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
80103618:	c7 04 24 20 4a 14 80 	movl   $0x80144a20,(%esp)
8010361f:	e8 11 09 00 00       	call   80103f35 <release>
}
80103624:	83 c4 10             	add    $0x10,%esp
80103627:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010362a:	c9                   	leave  
8010362b:	c3                   	ret    
    panic("userinit: out of memory?");
8010362c:	83 ec 0c             	sub    $0xc,%esp
8010362f:	68 4c 6d 10 80       	push   $0x80106d4c
80103634:	e8 0f cd ff ff       	call   80100348 <panic>

80103639 <growproc>:
{
80103639:	55                   	push   %ebp
8010363a:	89 e5                	mov    %esp,%ebp
8010363c:	56                   	push   %esi
8010363d:	53                   	push   %ebx
8010363e:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
80103641:	e8 e8 fe ff ff       	call   8010352e <myproc>
80103646:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
80103648:	8b 00                	mov    (%eax),%eax
  if(n > 0){
8010364a:	85 f6                	test   %esi,%esi
8010364c:	7f 21                	jg     8010366f <growproc+0x36>
  } else if(n < 0){
8010364e:	85 f6                	test   %esi,%esi
80103650:	79 33                	jns    80103685 <growproc+0x4c>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103652:	83 ec 04             	sub    $0x4,%esp
80103655:	01 c6                	add    %eax,%esi
80103657:	56                   	push   %esi
80103658:	50                   	push   %eax
80103659:	ff 73 04             	pushl  0x4(%ebx)
8010365c:	e8 29 2d 00 00       	call   8010638a <deallocuvm>
80103661:	83 c4 10             	add    $0x10,%esp
80103664:	85 c0                	test   %eax,%eax
80103666:	75 1d                	jne    80103685 <growproc+0x4c>
      return -1;
80103668:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010366d:	eb 29                	jmp    80103698 <growproc+0x5f>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n, curproc->pid)) == 0)
8010366f:	ff 73 10             	pushl  0x10(%ebx)
80103672:	01 c6                	add    %eax,%esi
80103674:	56                   	push   %esi
80103675:	50                   	push   %eax
80103676:	ff 73 04             	pushl  0x4(%ebx)
80103679:	e8 9e 2d 00 00       	call   8010641c <allocuvm>
8010367e:	83 c4 10             	add    $0x10,%esp
80103681:	85 c0                	test   %eax,%eax
80103683:	74 1a                	je     8010369f <growproc+0x66>
  curproc->sz = sz;
80103685:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
80103687:	83 ec 0c             	sub    $0xc,%esp
8010368a:	53                   	push   %ebx
8010368b:	e8 d9 2a 00 00       	call   80106169 <switchuvm>
  return 0;
80103690:	83 c4 10             	add    $0x10,%esp
80103693:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103698:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010369b:	5b                   	pop    %ebx
8010369c:	5e                   	pop    %esi
8010369d:	5d                   	pop    %ebp
8010369e:	c3                   	ret    
      return -1;
8010369f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801036a4:	eb f2                	jmp    80103698 <growproc+0x5f>

801036a6 <fork>:
{
801036a6:	55                   	push   %ebp
801036a7:	89 e5                	mov    %esp,%ebp
801036a9:	57                   	push   %edi
801036aa:	56                   	push   %esi
801036ab:	53                   	push   %ebx
801036ac:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
801036af:	e8 7a fe ff ff       	call   8010352e <myproc>
801036b4:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
801036b6:	e8 d8 fc ff ff       	call   80103393 <allocproc>
801036bb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801036be:	85 c0                	test   %eax,%eax
801036c0:	0f 84 e3 00 00 00    	je     801037a9 <fork+0x103>
801036c6:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz, np->pid)) == 0){
801036c8:	83 ec 04             	sub    $0x4,%esp
801036cb:	ff 70 10             	pushl  0x10(%eax)
801036ce:	ff 33                	pushl  (%ebx)
801036d0:	ff 73 04             	pushl  0x4(%ebx)
801036d3:	e8 58 2f 00 00       	call   80106630 <copyuvm>
801036d8:	89 47 04             	mov    %eax,0x4(%edi)
801036db:	83 c4 10             	add    $0x10,%esp
801036de:	85 c0                	test   %eax,%eax
801036e0:	74 2a                	je     8010370c <fork+0x66>
  np->sz = curproc->sz;
801036e2:	8b 03                	mov    (%ebx),%eax
801036e4:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801036e7:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
801036e9:	89 c8                	mov    %ecx,%eax
801036eb:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
801036ee:	8b 73 18             	mov    0x18(%ebx),%esi
801036f1:	8b 79 18             	mov    0x18(%ecx),%edi
801036f4:	b9 13 00 00 00       	mov    $0x13,%ecx
801036f9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
801036fb:	8b 40 18             	mov    0x18(%eax),%eax
801036fe:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
80103705:	be 00 00 00 00       	mov    $0x0,%esi
8010370a:	eb 29                	jmp    80103735 <fork+0x8f>
    kfree(np->kstack);
8010370c:	83 ec 0c             	sub    $0xc,%esp
8010370f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
80103712:	ff 73 08             	pushl  0x8(%ebx)
80103715:	e8 96 e8 ff ff       	call   80101fb0 <kfree>
    np->kstack = 0;
8010371a:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
80103721:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
80103728:	83 c4 10             	add    $0x10,%esp
8010372b:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103730:	eb 6d                	jmp    8010379f <fork+0xf9>
  for(i = 0; i < NOFILE; i++)
80103732:	83 c6 01             	add    $0x1,%esi
80103735:	83 fe 0f             	cmp    $0xf,%esi
80103738:	7f 1d                	jg     80103757 <fork+0xb1>
    if(curproc->ofile[i])
8010373a:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
8010373e:	85 c0                	test   %eax,%eax
80103740:	74 f0                	je     80103732 <fork+0x8c>
      np->ofile[i] = filedup(curproc->ofile[i]);
80103742:	83 ec 0c             	sub    $0xc,%esp
80103745:	50                   	push   %eax
80103746:	e8 4f d5 ff ff       	call   80100c9a <filedup>
8010374b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010374e:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
80103752:	83 c4 10             	add    $0x10,%esp
80103755:	eb db                	jmp    80103732 <fork+0x8c>
  np->cwd = idup(curproc->cwd);
80103757:	83 ec 0c             	sub    $0xc,%esp
8010375a:	ff 73 68             	pushl  0x68(%ebx)
8010375d:	e8 fb dd ff ff       	call   8010155d <idup>
80103762:	8b 7d e4             	mov    -0x1c(%ebp),%edi
80103765:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103768:	83 c3 6c             	add    $0x6c,%ebx
8010376b:	8d 47 6c             	lea    0x6c(%edi),%eax
8010376e:	83 c4 0c             	add    $0xc,%esp
80103771:	6a 10                	push   $0x10
80103773:	53                   	push   %ebx
80103774:	50                   	push   %eax
80103775:	e8 69 09 00 00       	call   801040e3 <safestrcpy>
  pid = np->pid;
8010377a:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
8010377d:	c7 04 24 20 4a 14 80 	movl   $0x80144a20,(%esp)
80103784:	e8 47 07 00 00       	call   80103ed0 <acquire>
  np->state = RUNNABLE;
80103789:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
80103790:	c7 04 24 20 4a 14 80 	movl   $0x80144a20,(%esp)
80103797:	e8 99 07 00 00       	call   80103f35 <release>
  return pid;
8010379c:	83 c4 10             	add    $0x10,%esp
}
8010379f:	89 d8                	mov    %ebx,%eax
801037a1:	8d 65 f4             	lea    -0xc(%ebp),%esp
801037a4:	5b                   	pop    %ebx
801037a5:	5e                   	pop    %esi
801037a6:	5f                   	pop    %edi
801037a7:	5d                   	pop    %ebp
801037a8:	c3                   	ret    
    return -1;
801037a9:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
801037ae:	eb ef                	jmp    8010379f <fork+0xf9>

801037b0 <scheduler>:
{
801037b0:	55                   	push   %ebp
801037b1:	89 e5                	mov    %esp,%ebp
801037b3:	56                   	push   %esi
801037b4:	53                   	push   %ebx
  struct cpu *c = mycpu();
801037b5:	e8 fd fc ff ff       	call   801034b7 <mycpu>
801037ba:	89 c6                	mov    %eax,%esi
  c->proc = 0;
801037bc:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
801037c3:	00 00 00 
801037c6:	eb 5a                	jmp    80103822 <scheduler+0x72>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801037c8:	83 c3 7c             	add    $0x7c,%ebx
801037cb:	81 fb 54 69 14 80    	cmp    $0x80146954,%ebx
801037d1:	73 3f                	jae    80103812 <scheduler+0x62>
      if(p->state != RUNNABLE)
801037d3:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
801037d7:	75 ef                	jne    801037c8 <scheduler+0x18>
      c->proc = p;
801037d9:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
801037df:	83 ec 0c             	sub    $0xc,%esp
801037e2:	53                   	push   %ebx
801037e3:	e8 81 29 00 00       	call   80106169 <switchuvm>
      p->state = RUNNING;
801037e8:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      swtch(&(c->scheduler), p->context);
801037ef:	83 c4 08             	add    $0x8,%esp
801037f2:	ff 73 1c             	pushl  0x1c(%ebx)
801037f5:	8d 46 04             	lea    0x4(%esi),%eax
801037f8:	50                   	push   %eax
801037f9:	e8 38 09 00 00       	call   80104136 <swtch>
      switchkvm();
801037fe:	e8 54 29 00 00       	call   80106157 <switchkvm>
      c->proc = 0;
80103803:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
8010380a:	00 00 00 
8010380d:	83 c4 10             	add    $0x10,%esp
80103810:	eb b6                	jmp    801037c8 <scheduler+0x18>
    release(&ptable.lock);
80103812:	83 ec 0c             	sub    $0xc,%esp
80103815:	68 20 4a 14 80       	push   $0x80144a20
8010381a:	e8 16 07 00 00       	call   80103f35 <release>
    sti();
8010381f:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
80103822:	fb                   	sti    
    acquire(&ptable.lock);
80103823:	83 ec 0c             	sub    $0xc,%esp
80103826:	68 20 4a 14 80       	push   $0x80144a20
8010382b:	e8 a0 06 00 00       	call   80103ed0 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103830:	83 c4 10             	add    $0x10,%esp
80103833:	bb 54 4a 14 80       	mov    $0x80144a54,%ebx
80103838:	eb 91                	jmp    801037cb <scheduler+0x1b>

8010383a <sched>:
{
8010383a:	55                   	push   %ebp
8010383b:	89 e5                	mov    %esp,%ebp
8010383d:	56                   	push   %esi
8010383e:	53                   	push   %ebx
  struct proc *p = myproc();
8010383f:	e8 ea fc ff ff       	call   8010352e <myproc>
80103844:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
80103846:	83 ec 0c             	sub    $0xc,%esp
80103849:	68 20 4a 14 80       	push   $0x80144a20
8010384e:	e8 3d 06 00 00       	call   80103e90 <holding>
80103853:	83 c4 10             	add    $0x10,%esp
80103856:	85 c0                	test   %eax,%eax
80103858:	74 4f                	je     801038a9 <sched+0x6f>
  if(mycpu()->ncli != 1)
8010385a:	e8 58 fc ff ff       	call   801034b7 <mycpu>
8010385f:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
80103866:	75 4e                	jne    801038b6 <sched+0x7c>
  if(p->state == RUNNING)
80103868:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
8010386c:	74 55                	je     801038c3 <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010386e:	9c                   	pushf  
8010386f:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103870:	f6 c4 02             	test   $0x2,%ah
80103873:	75 5b                	jne    801038d0 <sched+0x96>
  intena = mycpu()->intena;
80103875:	e8 3d fc ff ff       	call   801034b7 <mycpu>
8010387a:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
80103880:	e8 32 fc ff ff       	call   801034b7 <mycpu>
80103885:	83 ec 08             	sub    $0x8,%esp
80103888:	ff 70 04             	pushl  0x4(%eax)
8010388b:	83 c3 1c             	add    $0x1c,%ebx
8010388e:	53                   	push   %ebx
8010388f:	e8 a2 08 00 00       	call   80104136 <swtch>
  mycpu()->intena = intena;
80103894:	e8 1e fc ff ff       	call   801034b7 <mycpu>
80103899:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
8010389f:	83 c4 10             	add    $0x10,%esp
801038a2:	8d 65 f8             	lea    -0x8(%ebp),%esp
801038a5:	5b                   	pop    %ebx
801038a6:	5e                   	pop    %esi
801038a7:	5d                   	pop    %ebp
801038a8:	c3                   	ret    
    panic("sched ptable.lock");
801038a9:	83 ec 0c             	sub    $0xc,%esp
801038ac:	68 70 6d 10 80       	push   $0x80106d70
801038b1:	e8 92 ca ff ff       	call   80100348 <panic>
    panic("sched locks");
801038b6:	83 ec 0c             	sub    $0xc,%esp
801038b9:	68 82 6d 10 80       	push   $0x80106d82
801038be:	e8 85 ca ff ff       	call   80100348 <panic>
    panic("sched running");
801038c3:	83 ec 0c             	sub    $0xc,%esp
801038c6:	68 8e 6d 10 80       	push   $0x80106d8e
801038cb:	e8 78 ca ff ff       	call   80100348 <panic>
    panic("sched interruptible");
801038d0:	83 ec 0c             	sub    $0xc,%esp
801038d3:	68 9c 6d 10 80       	push   $0x80106d9c
801038d8:	e8 6b ca ff ff       	call   80100348 <panic>

801038dd <exit>:
{
801038dd:	55                   	push   %ebp
801038de:	89 e5                	mov    %esp,%ebp
801038e0:	56                   	push   %esi
801038e1:	53                   	push   %ebx
  struct proc *curproc = myproc();
801038e2:	e8 47 fc ff ff       	call   8010352e <myproc>
  if(curproc == initproc)
801038e7:	39 05 b8 a5 10 80    	cmp    %eax,0x8010a5b8
801038ed:	74 09                	je     801038f8 <exit+0x1b>
801038ef:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
801038f1:	bb 00 00 00 00       	mov    $0x0,%ebx
801038f6:	eb 10                	jmp    80103908 <exit+0x2b>
    panic("init exiting");
801038f8:	83 ec 0c             	sub    $0xc,%esp
801038fb:	68 b0 6d 10 80       	push   $0x80106db0
80103900:	e8 43 ca ff ff       	call   80100348 <panic>
  for(fd = 0; fd < NOFILE; fd++){
80103905:	83 c3 01             	add    $0x1,%ebx
80103908:	83 fb 0f             	cmp    $0xf,%ebx
8010390b:	7f 1e                	jg     8010392b <exit+0x4e>
    if(curproc->ofile[fd]){
8010390d:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
80103911:	85 c0                	test   %eax,%eax
80103913:	74 f0                	je     80103905 <exit+0x28>
      fileclose(curproc->ofile[fd]);
80103915:	83 ec 0c             	sub    $0xc,%esp
80103918:	50                   	push   %eax
80103919:	e8 c1 d3 ff ff       	call   80100cdf <fileclose>
      curproc->ofile[fd] = 0;
8010391e:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
80103925:	00 
80103926:	83 c4 10             	add    $0x10,%esp
80103929:	eb da                	jmp    80103905 <exit+0x28>
  begin_op();
8010392b:	e8 a3 f1 ff ff       	call   80102ad3 <begin_op>
  iput(curproc->cwd);
80103930:	83 ec 0c             	sub    $0xc,%esp
80103933:	ff 76 68             	pushl  0x68(%esi)
80103936:	e8 59 dd ff ff       	call   80101694 <iput>
  end_op();
8010393b:	e8 0d f2 ff ff       	call   80102b4d <end_op>
  curproc->cwd = 0;
80103940:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
80103947:	c7 04 24 20 4a 14 80 	movl   $0x80144a20,(%esp)
8010394e:	e8 7d 05 00 00       	call   80103ed0 <acquire>
  wakeup1(curproc->parent);
80103953:	8b 46 14             	mov    0x14(%esi),%eax
80103956:	e8 0d fa ff ff       	call   80103368 <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010395b:	83 c4 10             	add    $0x10,%esp
8010395e:	bb 54 4a 14 80       	mov    $0x80144a54,%ebx
80103963:	eb 03                	jmp    80103968 <exit+0x8b>
80103965:	83 c3 7c             	add    $0x7c,%ebx
80103968:	81 fb 54 69 14 80    	cmp    $0x80146954,%ebx
8010396e:	73 1a                	jae    8010398a <exit+0xad>
    if(p->parent == curproc){
80103970:	39 73 14             	cmp    %esi,0x14(%ebx)
80103973:	75 f0                	jne    80103965 <exit+0x88>
      p->parent = initproc;
80103975:	a1 b8 a5 10 80       	mov    0x8010a5b8,%eax
8010397a:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
8010397d:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103981:	75 e2                	jne    80103965 <exit+0x88>
        wakeup1(initproc);
80103983:	e8 e0 f9 ff ff       	call   80103368 <wakeup1>
80103988:	eb db                	jmp    80103965 <exit+0x88>
  curproc->state = ZOMBIE;
8010398a:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
80103991:	e8 a4 fe ff ff       	call   8010383a <sched>
  panic("zombie exit");
80103996:	83 ec 0c             	sub    $0xc,%esp
80103999:	68 bd 6d 10 80       	push   $0x80106dbd
8010399e:	e8 a5 c9 ff ff       	call   80100348 <panic>

801039a3 <yield>:
{
801039a3:	55                   	push   %ebp
801039a4:	89 e5                	mov    %esp,%ebp
801039a6:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
801039a9:	68 20 4a 14 80       	push   $0x80144a20
801039ae:	e8 1d 05 00 00       	call   80103ed0 <acquire>
  myproc()->state = RUNNABLE;
801039b3:	e8 76 fb ff ff       	call   8010352e <myproc>
801039b8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
801039bf:	e8 76 fe ff ff       	call   8010383a <sched>
  release(&ptable.lock);
801039c4:	c7 04 24 20 4a 14 80 	movl   $0x80144a20,(%esp)
801039cb:	e8 65 05 00 00       	call   80103f35 <release>
}
801039d0:	83 c4 10             	add    $0x10,%esp
801039d3:	c9                   	leave  
801039d4:	c3                   	ret    

801039d5 <sleep>:
{
801039d5:	55                   	push   %ebp
801039d6:	89 e5                	mov    %esp,%ebp
801039d8:	56                   	push   %esi
801039d9:	53                   	push   %ebx
801039da:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  struct proc *p = myproc();
801039dd:	e8 4c fb ff ff       	call   8010352e <myproc>
  if(p == 0)
801039e2:	85 c0                	test   %eax,%eax
801039e4:	74 66                	je     80103a4c <sleep+0x77>
801039e6:	89 c6                	mov    %eax,%esi
  if(lk == 0)
801039e8:	85 db                	test   %ebx,%ebx
801039ea:	74 6d                	je     80103a59 <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
801039ec:	81 fb 20 4a 14 80    	cmp    $0x80144a20,%ebx
801039f2:	74 18                	je     80103a0c <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
801039f4:	83 ec 0c             	sub    $0xc,%esp
801039f7:	68 20 4a 14 80       	push   $0x80144a20
801039fc:	e8 cf 04 00 00       	call   80103ed0 <acquire>
    release(lk);
80103a01:	89 1c 24             	mov    %ebx,(%esp)
80103a04:	e8 2c 05 00 00       	call   80103f35 <release>
80103a09:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
80103a0c:	8b 45 08             	mov    0x8(%ebp),%eax
80103a0f:	89 46 20             	mov    %eax,0x20(%esi)
  p->state = SLEEPING;
80103a12:	c7 46 0c 02 00 00 00 	movl   $0x2,0xc(%esi)
  sched();
80103a19:	e8 1c fe ff ff       	call   8010383a <sched>
  p->chan = 0;
80103a1e:	c7 46 20 00 00 00 00 	movl   $0x0,0x20(%esi)
  if(lk != &ptable.lock){  //DOC: sleeplock2
80103a25:	81 fb 20 4a 14 80    	cmp    $0x80144a20,%ebx
80103a2b:	74 18                	je     80103a45 <sleep+0x70>
    release(&ptable.lock);
80103a2d:	83 ec 0c             	sub    $0xc,%esp
80103a30:	68 20 4a 14 80       	push   $0x80144a20
80103a35:	e8 fb 04 00 00       	call   80103f35 <release>
    acquire(lk);
80103a3a:	89 1c 24             	mov    %ebx,(%esp)
80103a3d:	e8 8e 04 00 00       	call   80103ed0 <acquire>
80103a42:	83 c4 10             	add    $0x10,%esp
}
80103a45:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a48:	5b                   	pop    %ebx
80103a49:	5e                   	pop    %esi
80103a4a:	5d                   	pop    %ebp
80103a4b:	c3                   	ret    
    panic("sleep");
80103a4c:	83 ec 0c             	sub    $0xc,%esp
80103a4f:	68 c9 6d 10 80       	push   $0x80106dc9
80103a54:	e8 ef c8 ff ff       	call   80100348 <panic>
    panic("sleep without lk");
80103a59:	83 ec 0c             	sub    $0xc,%esp
80103a5c:	68 cf 6d 10 80       	push   $0x80106dcf
80103a61:	e8 e2 c8 ff ff       	call   80100348 <panic>

80103a66 <wait>:
{
80103a66:	55                   	push   %ebp
80103a67:	89 e5                	mov    %esp,%ebp
80103a69:	56                   	push   %esi
80103a6a:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103a6b:	e8 be fa ff ff       	call   8010352e <myproc>
80103a70:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
80103a72:	83 ec 0c             	sub    $0xc,%esp
80103a75:	68 20 4a 14 80       	push   $0x80144a20
80103a7a:	e8 51 04 00 00       	call   80103ed0 <acquire>
80103a7f:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
80103a82:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103a87:	bb 54 4a 14 80       	mov    $0x80144a54,%ebx
80103a8c:	eb 5b                	jmp    80103ae9 <wait+0x83>
        pid = p->pid;
80103a8e:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
80103a91:	83 ec 0c             	sub    $0xc,%esp
80103a94:	ff 73 08             	pushl  0x8(%ebx)
80103a97:	e8 14 e5 ff ff       	call   80101fb0 <kfree>
        p->kstack = 0;
80103a9c:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
80103aa3:	83 c4 04             	add    $0x4,%esp
80103aa6:	ff 73 04             	pushl  0x4(%ebx)
80103aa9:	e8 61 2a 00 00       	call   8010650f <freevm>
        p->pid = 0;
80103aae:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
80103ab5:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
80103abc:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
80103ac0:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
80103ac7:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
80103ace:	c7 04 24 20 4a 14 80 	movl   $0x80144a20,(%esp)
80103ad5:	e8 5b 04 00 00       	call   80103f35 <release>
        return pid;
80103ada:	83 c4 10             	add    $0x10,%esp
}
80103add:	89 f0                	mov    %esi,%eax
80103adf:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103ae2:	5b                   	pop    %ebx
80103ae3:	5e                   	pop    %esi
80103ae4:	5d                   	pop    %ebp
80103ae5:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103ae6:	83 c3 7c             	add    $0x7c,%ebx
80103ae9:	81 fb 54 69 14 80    	cmp    $0x80146954,%ebx
80103aef:	73 12                	jae    80103b03 <wait+0x9d>
      if(p->parent != curproc)
80103af1:	39 73 14             	cmp    %esi,0x14(%ebx)
80103af4:	75 f0                	jne    80103ae6 <wait+0x80>
      if(p->state == ZOMBIE){
80103af6:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103afa:	74 92                	je     80103a8e <wait+0x28>
      havekids = 1;
80103afc:	b8 01 00 00 00       	mov    $0x1,%eax
80103b01:	eb e3                	jmp    80103ae6 <wait+0x80>
    if(!havekids || curproc->killed){
80103b03:	85 c0                	test   %eax,%eax
80103b05:	74 06                	je     80103b0d <wait+0xa7>
80103b07:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
80103b0b:	74 17                	je     80103b24 <wait+0xbe>
      release(&ptable.lock);
80103b0d:	83 ec 0c             	sub    $0xc,%esp
80103b10:	68 20 4a 14 80       	push   $0x80144a20
80103b15:	e8 1b 04 00 00       	call   80103f35 <release>
      return -1;
80103b1a:	83 c4 10             	add    $0x10,%esp
80103b1d:	be ff ff ff ff       	mov    $0xffffffff,%esi
80103b22:	eb b9                	jmp    80103add <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80103b24:	83 ec 08             	sub    $0x8,%esp
80103b27:	68 20 4a 14 80       	push   $0x80144a20
80103b2c:	56                   	push   %esi
80103b2d:	e8 a3 fe ff ff       	call   801039d5 <sleep>
    havekids = 0;
80103b32:	83 c4 10             	add    $0x10,%esp
80103b35:	e9 48 ff ff ff       	jmp    80103a82 <wait+0x1c>

80103b3a <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80103b3a:	55                   	push   %ebp
80103b3b:	89 e5                	mov    %esp,%ebp
80103b3d:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
80103b40:	68 20 4a 14 80       	push   $0x80144a20
80103b45:	e8 86 03 00 00       	call   80103ed0 <acquire>
  wakeup1(chan);
80103b4a:	8b 45 08             	mov    0x8(%ebp),%eax
80103b4d:	e8 16 f8 ff ff       	call   80103368 <wakeup1>
  release(&ptable.lock);
80103b52:	c7 04 24 20 4a 14 80 	movl   $0x80144a20,(%esp)
80103b59:	e8 d7 03 00 00       	call   80103f35 <release>
}
80103b5e:	83 c4 10             	add    $0x10,%esp
80103b61:	c9                   	leave  
80103b62:	c3                   	ret    

80103b63 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80103b63:	55                   	push   %ebp
80103b64:	89 e5                	mov    %esp,%ebp
80103b66:	53                   	push   %ebx
80103b67:	83 ec 10             	sub    $0x10,%esp
80103b6a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
80103b6d:	68 20 4a 14 80       	push   $0x80144a20
80103b72:	e8 59 03 00 00       	call   80103ed0 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103b77:	83 c4 10             	add    $0x10,%esp
80103b7a:	b8 54 4a 14 80       	mov    $0x80144a54,%eax
80103b7f:	3d 54 69 14 80       	cmp    $0x80146954,%eax
80103b84:	73 3a                	jae    80103bc0 <kill+0x5d>
    if(p->pid == pid){
80103b86:	39 58 10             	cmp    %ebx,0x10(%eax)
80103b89:	74 05                	je     80103b90 <kill+0x2d>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103b8b:	83 c0 7c             	add    $0x7c,%eax
80103b8e:	eb ef                	jmp    80103b7f <kill+0x1c>
      p->killed = 1;
80103b90:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80103b97:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
80103b9b:	74 1a                	je     80103bb7 <kill+0x54>
        p->state = RUNNABLE;
      release(&ptable.lock);
80103b9d:	83 ec 0c             	sub    $0xc,%esp
80103ba0:	68 20 4a 14 80       	push   $0x80144a20
80103ba5:	e8 8b 03 00 00       	call   80103f35 <release>
      return 0;
80103baa:	83 c4 10             	add    $0x10,%esp
80103bad:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
80103bb2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103bb5:	c9                   	leave  
80103bb6:	c3                   	ret    
        p->state = RUNNABLE;
80103bb7:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80103bbe:	eb dd                	jmp    80103b9d <kill+0x3a>
  release(&ptable.lock);
80103bc0:	83 ec 0c             	sub    $0xc,%esp
80103bc3:	68 20 4a 14 80       	push   $0x80144a20
80103bc8:	e8 68 03 00 00       	call   80103f35 <release>
  return -1;
80103bcd:	83 c4 10             	add    $0x10,%esp
80103bd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103bd5:	eb db                	jmp    80103bb2 <kill+0x4f>

80103bd7 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80103bd7:	55                   	push   %ebp
80103bd8:	89 e5                	mov    %esp,%ebp
80103bda:	56                   	push   %esi
80103bdb:	53                   	push   %ebx
80103bdc:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103bdf:	bb 54 4a 14 80       	mov    $0x80144a54,%ebx
80103be4:	eb 33                	jmp    80103c19 <procdump+0x42>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103be6:	b8 e0 6d 10 80       	mov    $0x80106de0,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
80103beb:	8d 53 6c             	lea    0x6c(%ebx),%edx
80103bee:	52                   	push   %edx
80103bef:	50                   	push   %eax
80103bf0:	ff 73 10             	pushl  0x10(%ebx)
80103bf3:	68 e4 6d 10 80       	push   $0x80106de4
80103bf8:	e8 0e ca ff ff       	call   8010060b <cprintf>
    if(p->state == SLEEPING){
80103bfd:	83 c4 10             	add    $0x10,%esp
80103c00:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
80103c04:	74 39                	je     80103c3f <procdump+0x68>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80103c06:	83 ec 0c             	sub    $0xc,%esp
80103c09:	68 5b 71 10 80       	push   $0x8010715b
80103c0e:	e8 f8 c9 ff ff       	call   8010060b <cprintf>
80103c13:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103c16:	83 c3 7c             	add    $0x7c,%ebx
80103c19:	81 fb 54 69 14 80    	cmp    $0x80146954,%ebx
80103c1f:	73 61                	jae    80103c82 <procdump+0xab>
    if(p->state == UNUSED)
80103c21:	8b 43 0c             	mov    0xc(%ebx),%eax
80103c24:	85 c0                	test   %eax,%eax
80103c26:	74 ee                	je     80103c16 <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80103c28:	83 f8 05             	cmp    $0x5,%eax
80103c2b:	77 b9                	ja     80103be6 <procdump+0xf>
80103c2d:	8b 04 85 40 6e 10 80 	mov    -0x7fef91c0(,%eax,4),%eax
80103c34:	85 c0                	test   %eax,%eax
80103c36:	75 b3                	jne    80103beb <procdump+0x14>
      state = "???";
80103c38:	b8 e0 6d 10 80       	mov    $0x80106de0,%eax
80103c3d:	eb ac                	jmp    80103beb <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80103c3f:	8b 43 1c             	mov    0x1c(%ebx),%eax
80103c42:	8b 40 0c             	mov    0xc(%eax),%eax
80103c45:	83 c0 08             	add    $0x8,%eax
80103c48:	83 ec 08             	sub    $0x8,%esp
80103c4b:	8d 55 d0             	lea    -0x30(%ebp),%edx
80103c4e:	52                   	push   %edx
80103c4f:	50                   	push   %eax
80103c50:	e8 5a 01 00 00       	call   80103daf <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103c55:	83 c4 10             	add    $0x10,%esp
80103c58:	be 00 00 00 00       	mov    $0x0,%esi
80103c5d:	eb 14                	jmp    80103c73 <procdump+0x9c>
        cprintf(" %p", pc[i]);
80103c5f:	83 ec 08             	sub    $0x8,%esp
80103c62:	50                   	push   %eax
80103c63:	68 21 68 10 80       	push   $0x80106821
80103c68:	e8 9e c9 ff ff       	call   8010060b <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103c6d:	83 c6 01             	add    $0x1,%esi
80103c70:	83 c4 10             	add    $0x10,%esp
80103c73:	83 fe 09             	cmp    $0x9,%esi
80103c76:	7f 8e                	jg     80103c06 <procdump+0x2f>
80103c78:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103c7c:	85 c0                	test   %eax,%eax
80103c7e:	75 df                	jne    80103c5f <procdump+0x88>
80103c80:	eb 84                	jmp    80103c06 <procdump+0x2f>
  }
80103c82:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103c85:	5b                   	pop    %ebx
80103c86:	5e                   	pop    %esi
80103c87:	5d                   	pop    %ebp
80103c88:	c3                   	ret    

80103c89 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103c89:	55                   	push   %ebp
80103c8a:	89 e5                	mov    %esp,%ebp
80103c8c:	53                   	push   %ebx
80103c8d:	83 ec 0c             	sub    $0xc,%esp
80103c90:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103c93:	68 58 6e 10 80       	push   $0x80106e58
80103c98:	8d 43 04             	lea    0x4(%ebx),%eax
80103c9b:	50                   	push   %eax
80103c9c:	e8 f3 00 00 00       	call   80103d94 <initlock>
  lk->name = name;
80103ca1:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ca4:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103ca7:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103cad:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103cb4:	83 c4 10             	add    $0x10,%esp
80103cb7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103cba:	c9                   	leave  
80103cbb:	c3                   	ret    

80103cbc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103cbc:	55                   	push   %ebp
80103cbd:	89 e5                	mov    %esp,%ebp
80103cbf:	56                   	push   %esi
80103cc0:	53                   	push   %ebx
80103cc1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103cc4:	8d 73 04             	lea    0x4(%ebx),%esi
80103cc7:	83 ec 0c             	sub    $0xc,%esp
80103cca:	56                   	push   %esi
80103ccb:	e8 00 02 00 00       	call   80103ed0 <acquire>
  while (lk->locked) {
80103cd0:	83 c4 10             	add    $0x10,%esp
80103cd3:	eb 0d                	jmp    80103ce2 <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103cd5:	83 ec 08             	sub    $0x8,%esp
80103cd8:	56                   	push   %esi
80103cd9:	53                   	push   %ebx
80103cda:	e8 f6 fc ff ff       	call   801039d5 <sleep>
80103cdf:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103ce2:	83 3b 00             	cmpl   $0x0,(%ebx)
80103ce5:	75 ee                	jne    80103cd5 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103ce7:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103ced:	e8 3c f8 ff ff       	call   8010352e <myproc>
80103cf2:	8b 40 10             	mov    0x10(%eax),%eax
80103cf5:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103cf8:	83 ec 0c             	sub    $0xc,%esp
80103cfb:	56                   	push   %esi
80103cfc:	e8 34 02 00 00       	call   80103f35 <release>
}
80103d01:	83 c4 10             	add    $0x10,%esp
80103d04:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103d07:	5b                   	pop    %ebx
80103d08:	5e                   	pop    %esi
80103d09:	5d                   	pop    %ebp
80103d0a:	c3                   	ret    

80103d0b <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103d0b:	55                   	push   %ebp
80103d0c:	89 e5                	mov    %esp,%ebp
80103d0e:	56                   	push   %esi
80103d0f:	53                   	push   %ebx
80103d10:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103d13:	8d 73 04             	lea    0x4(%ebx),%esi
80103d16:	83 ec 0c             	sub    $0xc,%esp
80103d19:	56                   	push   %esi
80103d1a:	e8 b1 01 00 00       	call   80103ed0 <acquire>
  lk->locked = 0;
80103d1f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103d25:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103d2c:	89 1c 24             	mov    %ebx,(%esp)
80103d2f:	e8 06 fe ff ff       	call   80103b3a <wakeup>
  release(&lk->lk);
80103d34:	89 34 24             	mov    %esi,(%esp)
80103d37:	e8 f9 01 00 00       	call   80103f35 <release>
}
80103d3c:	83 c4 10             	add    $0x10,%esp
80103d3f:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103d42:	5b                   	pop    %ebx
80103d43:	5e                   	pop    %esi
80103d44:	5d                   	pop    %ebp
80103d45:	c3                   	ret    

80103d46 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103d46:	55                   	push   %ebp
80103d47:	89 e5                	mov    %esp,%ebp
80103d49:	56                   	push   %esi
80103d4a:	53                   	push   %ebx
80103d4b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103d4e:	8d 73 04             	lea    0x4(%ebx),%esi
80103d51:	83 ec 0c             	sub    $0xc,%esp
80103d54:	56                   	push   %esi
80103d55:	e8 76 01 00 00       	call   80103ed0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103d5a:	83 c4 10             	add    $0x10,%esp
80103d5d:	83 3b 00             	cmpl   $0x0,(%ebx)
80103d60:	75 17                	jne    80103d79 <holdingsleep+0x33>
80103d62:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103d67:	83 ec 0c             	sub    $0xc,%esp
80103d6a:	56                   	push   %esi
80103d6b:	e8 c5 01 00 00       	call   80103f35 <release>
  return r;
}
80103d70:	89 d8                	mov    %ebx,%eax
80103d72:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103d75:	5b                   	pop    %ebx
80103d76:	5e                   	pop    %esi
80103d77:	5d                   	pop    %ebp
80103d78:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103d79:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103d7c:	e8 ad f7 ff ff       	call   8010352e <myproc>
80103d81:	3b 58 10             	cmp    0x10(%eax),%ebx
80103d84:	74 07                	je     80103d8d <holdingsleep+0x47>
80103d86:	bb 00 00 00 00       	mov    $0x0,%ebx
80103d8b:	eb da                	jmp    80103d67 <holdingsleep+0x21>
80103d8d:	bb 01 00 00 00       	mov    $0x1,%ebx
80103d92:	eb d3                	jmp    80103d67 <holdingsleep+0x21>

80103d94 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103d94:	55                   	push   %ebp
80103d95:	89 e5                	mov    %esp,%ebp
80103d97:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103d9a:	8b 55 0c             	mov    0xc(%ebp),%edx
80103d9d:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103da0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103da6:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103dad:	5d                   	pop    %ebp
80103dae:	c3                   	ret    

80103daf <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103daf:	55                   	push   %ebp
80103db0:	89 e5                	mov    %esp,%ebp
80103db2:	53                   	push   %ebx
80103db3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103db6:	8b 45 08             	mov    0x8(%ebp),%eax
80103db9:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103dbc:	b8 00 00 00 00       	mov    $0x0,%eax
80103dc1:	83 f8 09             	cmp    $0x9,%eax
80103dc4:	7f 25                	jg     80103deb <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103dc6:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103dcc:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103dd2:	77 17                	ja     80103deb <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103dd4:	8b 5a 04             	mov    0x4(%edx),%ebx
80103dd7:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103dda:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103ddc:	83 c0 01             	add    $0x1,%eax
80103ddf:	eb e0                	jmp    80103dc1 <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103de1:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103de8:	83 c0 01             	add    $0x1,%eax
80103deb:	83 f8 09             	cmp    $0x9,%eax
80103dee:	7e f1                	jle    80103de1 <getcallerpcs+0x32>
}
80103df0:	5b                   	pop    %ebx
80103df1:	5d                   	pop    %ebp
80103df2:	c3                   	ret    

80103df3 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103df3:	55                   	push   %ebp
80103df4:	89 e5                	mov    %esp,%ebp
80103df6:	53                   	push   %ebx
80103df7:	83 ec 04             	sub    $0x4,%esp
80103dfa:	9c                   	pushf  
80103dfb:	5b                   	pop    %ebx
  asm volatile("cli");
80103dfc:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103dfd:	e8 b5 f6 ff ff       	call   801034b7 <mycpu>
80103e02:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103e09:	74 12                	je     80103e1d <pushcli+0x2a>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103e0b:	e8 a7 f6 ff ff       	call   801034b7 <mycpu>
80103e10:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103e17:	83 c4 04             	add    $0x4,%esp
80103e1a:	5b                   	pop    %ebx
80103e1b:	5d                   	pop    %ebp
80103e1c:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103e1d:	e8 95 f6 ff ff       	call   801034b7 <mycpu>
80103e22:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103e28:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103e2e:	eb db                	jmp    80103e0b <pushcli+0x18>

80103e30 <popcli>:

void
popcli(void)
{
80103e30:	55                   	push   %ebp
80103e31:	89 e5                	mov    %esp,%ebp
80103e33:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103e36:	9c                   	pushf  
80103e37:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103e38:	f6 c4 02             	test   $0x2,%ah
80103e3b:	75 28                	jne    80103e65 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103e3d:	e8 75 f6 ff ff       	call   801034b7 <mycpu>
80103e42:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103e48:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103e4b:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103e51:	85 d2                	test   %edx,%edx
80103e53:	78 1d                	js     80103e72 <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103e55:	e8 5d f6 ff ff       	call   801034b7 <mycpu>
80103e5a:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103e61:	74 1c                	je     80103e7f <popcli+0x4f>
    sti();
}
80103e63:	c9                   	leave  
80103e64:	c3                   	ret    
    panic("popcli - interruptible");
80103e65:	83 ec 0c             	sub    $0xc,%esp
80103e68:	68 63 6e 10 80       	push   $0x80106e63
80103e6d:	e8 d6 c4 ff ff       	call   80100348 <panic>
    panic("popcli");
80103e72:	83 ec 0c             	sub    $0xc,%esp
80103e75:	68 7a 6e 10 80       	push   $0x80106e7a
80103e7a:	e8 c9 c4 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103e7f:	e8 33 f6 ff ff       	call   801034b7 <mycpu>
80103e84:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103e8b:	74 d6                	je     80103e63 <popcli+0x33>
  asm volatile("sti");
80103e8d:	fb                   	sti    
}
80103e8e:	eb d3                	jmp    80103e63 <popcli+0x33>

80103e90 <holding>:
{
80103e90:	55                   	push   %ebp
80103e91:	89 e5                	mov    %esp,%ebp
80103e93:	53                   	push   %ebx
80103e94:	83 ec 04             	sub    $0x4,%esp
80103e97:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103e9a:	e8 54 ff ff ff       	call   80103df3 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103e9f:	83 3b 00             	cmpl   $0x0,(%ebx)
80103ea2:	75 12                	jne    80103eb6 <holding+0x26>
80103ea4:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103ea9:	e8 82 ff ff ff       	call   80103e30 <popcli>
}
80103eae:	89 d8                	mov    %ebx,%eax
80103eb0:	83 c4 04             	add    $0x4,%esp
80103eb3:	5b                   	pop    %ebx
80103eb4:	5d                   	pop    %ebp
80103eb5:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103eb6:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103eb9:	e8 f9 f5 ff ff       	call   801034b7 <mycpu>
80103ebe:	39 c3                	cmp    %eax,%ebx
80103ec0:	74 07                	je     80103ec9 <holding+0x39>
80103ec2:	bb 00 00 00 00       	mov    $0x0,%ebx
80103ec7:	eb e0                	jmp    80103ea9 <holding+0x19>
80103ec9:	bb 01 00 00 00       	mov    $0x1,%ebx
80103ece:	eb d9                	jmp    80103ea9 <holding+0x19>

80103ed0 <acquire>:
{
80103ed0:	55                   	push   %ebp
80103ed1:	89 e5                	mov    %esp,%ebp
80103ed3:	53                   	push   %ebx
80103ed4:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103ed7:	e8 17 ff ff ff       	call   80103df3 <pushcli>
  if(holding(lk))
80103edc:	83 ec 0c             	sub    $0xc,%esp
80103edf:	ff 75 08             	pushl  0x8(%ebp)
80103ee2:	e8 a9 ff ff ff       	call   80103e90 <holding>
80103ee7:	83 c4 10             	add    $0x10,%esp
80103eea:	85 c0                	test   %eax,%eax
80103eec:	75 3a                	jne    80103f28 <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103eee:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103ef1:	b8 01 00 00 00       	mov    $0x1,%eax
80103ef6:	f0 87 02             	lock xchg %eax,(%edx)
80103ef9:	85 c0                	test   %eax,%eax
80103efb:	75 f1                	jne    80103eee <acquire+0x1e>
  __sync_synchronize();
80103efd:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103f02:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103f05:	e8 ad f5 ff ff       	call   801034b7 <mycpu>
80103f0a:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103f0d:	8b 45 08             	mov    0x8(%ebp),%eax
80103f10:	83 c0 0c             	add    $0xc,%eax
80103f13:	83 ec 08             	sub    $0x8,%esp
80103f16:	50                   	push   %eax
80103f17:	8d 45 08             	lea    0x8(%ebp),%eax
80103f1a:	50                   	push   %eax
80103f1b:	e8 8f fe ff ff       	call   80103daf <getcallerpcs>
}
80103f20:	83 c4 10             	add    $0x10,%esp
80103f23:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103f26:	c9                   	leave  
80103f27:	c3                   	ret    
    panic("acquire");
80103f28:	83 ec 0c             	sub    $0xc,%esp
80103f2b:	68 81 6e 10 80       	push   $0x80106e81
80103f30:	e8 13 c4 ff ff       	call   80100348 <panic>

80103f35 <release>:
{
80103f35:	55                   	push   %ebp
80103f36:	89 e5                	mov    %esp,%ebp
80103f38:	53                   	push   %ebx
80103f39:	83 ec 10             	sub    $0x10,%esp
80103f3c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103f3f:	53                   	push   %ebx
80103f40:	e8 4b ff ff ff       	call   80103e90 <holding>
80103f45:	83 c4 10             	add    $0x10,%esp
80103f48:	85 c0                	test   %eax,%eax
80103f4a:	74 23                	je     80103f6f <release+0x3a>
  lk->pcs[0] = 0;
80103f4c:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103f53:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103f5a:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103f5f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103f65:	e8 c6 fe ff ff       	call   80103e30 <popcli>
}
80103f6a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103f6d:	c9                   	leave  
80103f6e:	c3                   	ret    
    panic("release");
80103f6f:	83 ec 0c             	sub    $0xc,%esp
80103f72:	68 89 6e 10 80       	push   $0x80106e89
80103f77:	e8 cc c3 ff ff       	call   80100348 <panic>

80103f7c <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103f7c:	55                   	push   %ebp
80103f7d:	89 e5                	mov    %esp,%ebp
80103f7f:	57                   	push   %edi
80103f80:	53                   	push   %ebx
80103f81:	8b 55 08             	mov    0x8(%ebp),%edx
80103f84:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103f87:	f6 c2 03             	test   $0x3,%dl
80103f8a:	75 05                	jne    80103f91 <memset+0x15>
80103f8c:	f6 c1 03             	test   $0x3,%cl
80103f8f:	74 0e                	je     80103f9f <memset+0x23>
  asm volatile("cld; rep stosb" :
80103f91:	89 d7                	mov    %edx,%edi
80103f93:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f96:	fc                   	cld    
80103f97:	f3 aa                	rep stos %al,%es:(%edi)
    c &= 0xFF;
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
  } else
    stosb(dst, c, n);
  return dst;
}
80103f99:	89 d0                	mov    %edx,%eax
80103f9b:	5b                   	pop    %ebx
80103f9c:	5f                   	pop    %edi
80103f9d:	5d                   	pop    %ebp
80103f9e:	c3                   	ret    
    c &= 0xFF;
80103f9f:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103fa3:	c1 e9 02             	shr    $0x2,%ecx
80103fa6:	89 f8                	mov    %edi,%eax
80103fa8:	c1 e0 18             	shl    $0x18,%eax
80103fab:	89 fb                	mov    %edi,%ebx
80103fad:	c1 e3 10             	shl    $0x10,%ebx
80103fb0:	09 d8                	or     %ebx,%eax
80103fb2:	89 fb                	mov    %edi,%ebx
80103fb4:	c1 e3 08             	shl    $0x8,%ebx
80103fb7:	09 d8                	or     %ebx,%eax
80103fb9:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103fbb:	89 d7                	mov    %edx,%edi
80103fbd:	fc                   	cld    
80103fbe:	f3 ab                	rep stos %eax,%es:(%edi)
80103fc0:	eb d7                	jmp    80103f99 <memset+0x1d>

80103fc2 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103fc2:	55                   	push   %ebp
80103fc3:	89 e5                	mov    %esp,%ebp
80103fc5:	56                   	push   %esi
80103fc6:	53                   	push   %ebx
80103fc7:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103fca:	8b 55 0c             	mov    0xc(%ebp),%edx
80103fcd:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103fd0:	8d 70 ff             	lea    -0x1(%eax),%esi
80103fd3:	85 c0                	test   %eax,%eax
80103fd5:	74 1c                	je     80103ff3 <memcmp+0x31>
    if(*s1 != *s2)
80103fd7:	0f b6 01             	movzbl (%ecx),%eax
80103fda:	0f b6 1a             	movzbl (%edx),%ebx
80103fdd:	38 d8                	cmp    %bl,%al
80103fdf:	75 0a                	jne    80103feb <memcmp+0x29>
      return *s1 - *s2;
    s1++, s2++;
80103fe1:	83 c1 01             	add    $0x1,%ecx
80103fe4:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103fe7:	89 f0                	mov    %esi,%eax
80103fe9:	eb e5                	jmp    80103fd0 <memcmp+0xe>
      return *s1 - *s2;
80103feb:	0f b6 c0             	movzbl %al,%eax
80103fee:	0f b6 db             	movzbl %bl,%ebx
80103ff1:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103ff3:	5b                   	pop    %ebx
80103ff4:	5e                   	pop    %esi
80103ff5:	5d                   	pop    %ebp
80103ff6:	c3                   	ret    

80103ff7 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103ff7:	55                   	push   %ebp
80103ff8:	89 e5                	mov    %esp,%ebp
80103ffa:	56                   	push   %esi
80103ffb:	53                   	push   %ebx
80103ffc:	8b 45 08             	mov    0x8(%ebp),%eax
80103fff:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80104002:	8b 55 10             	mov    0x10(%ebp),%edx
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80104005:	39 c1                	cmp    %eax,%ecx
80104007:	73 3a                	jae    80104043 <memmove+0x4c>
80104009:	8d 1c 11             	lea    (%ecx,%edx,1),%ebx
8010400c:	39 c3                	cmp    %eax,%ebx
8010400e:	76 37                	jbe    80104047 <memmove+0x50>
    s += n;
    d += n;
80104010:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
    while(n-- > 0)
80104013:	eb 0d                	jmp    80104022 <memmove+0x2b>
      *--d = *--s;
80104015:	83 eb 01             	sub    $0x1,%ebx
80104018:	83 e9 01             	sub    $0x1,%ecx
8010401b:	0f b6 13             	movzbl (%ebx),%edx
8010401e:	88 11                	mov    %dl,(%ecx)
    while(n-- > 0)
80104020:	89 f2                	mov    %esi,%edx
80104022:	8d 72 ff             	lea    -0x1(%edx),%esi
80104025:	85 d2                	test   %edx,%edx
80104027:	75 ec                	jne    80104015 <memmove+0x1e>
80104029:	eb 14                	jmp    8010403f <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
8010402b:	0f b6 11             	movzbl (%ecx),%edx
8010402e:	88 13                	mov    %dl,(%ebx)
80104030:	8d 5b 01             	lea    0x1(%ebx),%ebx
80104033:	8d 49 01             	lea    0x1(%ecx),%ecx
    while(n-- > 0)
80104036:	89 f2                	mov    %esi,%edx
80104038:	8d 72 ff             	lea    -0x1(%edx),%esi
8010403b:	85 d2                	test   %edx,%edx
8010403d:	75 ec                	jne    8010402b <memmove+0x34>

  return dst;
}
8010403f:	5b                   	pop    %ebx
80104040:	5e                   	pop    %esi
80104041:	5d                   	pop    %ebp
80104042:	c3                   	ret    
80104043:	89 c3                	mov    %eax,%ebx
80104045:	eb f1                	jmp    80104038 <memmove+0x41>
80104047:	89 c3                	mov    %eax,%ebx
80104049:	eb ed                	jmp    80104038 <memmove+0x41>

8010404b <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
8010404b:	55                   	push   %ebp
8010404c:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
8010404e:	ff 75 10             	pushl  0x10(%ebp)
80104051:	ff 75 0c             	pushl  0xc(%ebp)
80104054:	ff 75 08             	pushl  0x8(%ebp)
80104057:	e8 9b ff ff ff       	call   80103ff7 <memmove>
}
8010405c:	c9                   	leave  
8010405d:	c3                   	ret    

8010405e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
8010405e:	55                   	push   %ebp
8010405f:	89 e5                	mov    %esp,%ebp
80104061:	53                   	push   %ebx
80104062:	8b 55 08             	mov    0x8(%ebp),%edx
80104065:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80104068:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
8010406b:	eb 09                	jmp    80104076 <strncmp+0x18>
    n--, p++, q++;
8010406d:	83 e8 01             	sub    $0x1,%eax
80104070:	83 c2 01             	add    $0x1,%edx
80104073:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80104076:	85 c0                	test   %eax,%eax
80104078:	74 0b                	je     80104085 <strncmp+0x27>
8010407a:	0f b6 1a             	movzbl (%edx),%ebx
8010407d:	84 db                	test   %bl,%bl
8010407f:	74 04                	je     80104085 <strncmp+0x27>
80104081:	3a 19                	cmp    (%ecx),%bl
80104083:	74 e8                	je     8010406d <strncmp+0xf>
  if(n == 0)
80104085:	85 c0                	test   %eax,%eax
80104087:	74 0b                	je     80104094 <strncmp+0x36>
    return 0;
  return (uchar)*p - (uchar)*q;
80104089:	0f b6 02             	movzbl (%edx),%eax
8010408c:	0f b6 11             	movzbl (%ecx),%edx
8010408f:	29 d0                	sub    %edx,%eax
}
80104091:	5b                   	pop    %ebx
80104092:	5d                   	pop    %ebp
80104093:	c3                   	ret    
    return 0;
80104094:	b8 00 00 00 00       	mov    $0x0,%eax
80104099:	eb f6                	jmp    80104091 <strncmp+0x33>

8010409b <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
8010409b:	55                   	push   %ebp
8010409c:	89 e5                	mov    %esp,%ebp
8010409e:	57                   	push   %edi
8010409f:	56                   	push   %esi
801040a0:	53                   	push   %ebx
801040a1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
801040a4:	8b 4d 10             	mov    0x10(%ebp),%ecx
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
801040a7:	8b 45 08             	mov    0x8(%ebp),%eax
801040aa:	eb 04                	jmp    801040b0 <strncpy+0x15>
801040ac:	89 fb                	mov    %edi,%ebx
801040ae:	89 f0                	mov    %esi,%eax
801040b0:	8d 51 ff             	lea    -0x1(%ecx),%edx
801040b3:	85 c9                	test   %ecx,%ecx
801040b5:	7e 1d                	jle    801040d4 <strncpy+0x39>
801040b7:	8d 7b 01             	lea    0x1(%ebx),%edi
801040ba:	8d 70 01             	lea    0x1(%eax),%esi
801040bd:	0f b6 1b             	movzbl (%ebx),%ebx
801040c0:	88 18                	mov    %bl,(%eax)
801040c2:	89 d1                	mov    %edx,%ecx
801040c4:	84 db                	test   %bl,%bl
801040c6:	75 e4                	jne    801040ac <strncpy+0x11>
801040c8:	89 f0                	mov    %esi,%eax
801040ca:	eb 08                	jmp    801040d4 <strncpy+0x39>
    ;
  while(n-- > 0)
    *s++ = 0;
801040cc:	c6 00 00             	movb   $0x0,(%eax)
  while(n-- > 0)
801040cf:	89 ca                	mov    %ecx,%edx
    *s++ = 0;
801040d1:	8d 40 01             	lea    0x1(%eax),%eax
  while(n-- > 0)
801040d4:	8d 4a ff             	lea    -0x1(%edx),%ecx
801040d7:	85 d2                	test   %edx,%edx
801040d9:	7f f1                	jg     801040cc <strncpy+0x31>
  return os;
}
801040db:	8b 45 08             	mov    0x8(%ebp),%eax
801040de:	5b                   	pop    %ebx
801040df:	5e                   	pop    %esi
801040e0:	5f                   	pop    %edi
801040e1:	5d                   	pop    %ebp
801040e2:	c3                   	ret    

801040e3 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801040e3:	55                   	push   %ebp
801040e4:	89 e5                	mov    %esp,%ebp
801040e6:	57                   	push   %edi
801040e7:	56                   	push   %esi
801040e8:	53                   	push   %ebx
801040e9:	8b 45 08             	mov    0x8(%ebp),%eax
801040ec:	8b 5d 0c             	mov    0xc(%ebp),%ebx
801040ef:	8b 55 10             	mov    0x10(%ebp),%edx
  char *os;

  os = s;
  if(n <= 0)
801040f2:	85 d2                	test   %edx,%edx
801040f4:	7e 23                	jle    80104119 <safestrcpy+0x36>
801040f6:	89 c1                	mov    %eax,%ecx
801040f8:	eb 04                	jmp    801040fe <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
801040fa:	89 fb                	mov    %edi,%ebx
801040fc:	89 f1                	mov    %esi,%ecx
801040fe:	83 ea 01             	sub    $0x1,%edx
80104101:	85 d2                	test   %edx,%edx
80104103:	7e 11                	jle    80104116 <safestrcpy+0x33>
80104105:	8d 7b 01             	lea    0x1(%ebx),%edi
80104108:	8d 71 01             	lea    0x1(%ecx),%esi
8010410b:	0f b6 1b             	movzbl (%ebx),%ebx
8010410e:	88 19                	mov    %bl,(%ecx)
80104110:	84 db                	test   %bl,%bl
80104112:	75 e6                	jne    801040fa <safestrcpy+0x17>
80104114:	89 f1                	mov    %esi,%ecx
    ;
  *s = 0;
80104116:	c6 01 00             	movb   $0x0,(%ecx)
  return os;
}
80104119:	5b                   	pop    %ebx
8010411a:	5e                   	pop    %esi
8010411b:	5f                   	pop    %edi
8010411c:	5d                   	pop    %ebp
8010411d:	c3                   	ret    

8010411e <strlen>:

int
strlen(const char *s)
{
8010411e:	55                   	push   %ebp
8010411f:	89 e5                	mov    %esp,%ebp
80104121:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80104124:	b8 00 00 00 00       	mov    $0x0,%eax
80104129:	eb 03                	jmp    8010412e <strlen+0x10>
8010412b:	83 c0 01             	add    $0x1,%eax
8010412e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80104132:	75 f7                	jne    8010412b <strlen+0xd>
    ;
  return n;
}
80104134:	5d                   	pop    %ebp
80104135:	c3                   	ret    

80104136 <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80104136:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
8010413a:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
8010413e:	55                   	push   %ebp
  pushl %ebx
8010413f:	53                   	push   %ebx
  pushl %esi
80104140:	56                   	push   %esi
  pushl %edi
80104141:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80104142:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80104144:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80104146:	5f                   	pop    %edi
  popl %esi
80104147:	5e                   	pop    %esi
  popl %ebx
80104148:	5b                   	pop    %ebx
  popl %ebp
80104149:	5d                   	pop    %ebp
  ret
8010414a:	c3                   	ret    

8010414b <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
8010414b:	55                   	push   %ebp
8010414c:	89 e5                	mov    %esp,%ebp
8010414e:	53                   	push   %ebx
8010414f:	83 ec 04             	sub    $0x4,%esp
80104152:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80104155:	e8 d4 f3 ff ff       	call   8010352e <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
8010415a:	8b 00                	mov    (%eax),%eax
8010415c:	39 d8                	cmp    %ebx,%eax
8010415e:	76 19                	jbe    80104179 <fetchint+0x2e>
80104160:	8d 53 04             	lea    0x4(%ebx),%edx
80104163:	39 d0                	cmp    %edx,%eax
80104165:	72 19                	jb     80104180 <fetchint+0x35>
    return -1;
  *ip = *(int*)(addr);
80104167:	8b 13                	mov    (%ebx),%edx
80104169:	8b 45 0c             	mov    0xc(%ebp),%eax
8010416c:	89 10                	mov    %edx,(%eax)
  return 0;
8010416e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104173:	83 c4 04             	add    $0x4,%esp
80104176:	5b                   	pop    %ebx
80104177:	5d                   	pop    %ebp
80104178:	c3                   	ret    
    return -1;
80104179:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010417e:	eb f3                	jmp    80104173 <fetchint+0x28>
80104180:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104185:	eb ec                	jmp    80104173 <fetchint+0x28>

80104187 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80104187:	55                   	push   %ebp
80104188:	89 e5                	mov    %esp,%ebp
8010418a:	53                   	push   %ebx
8010418b:	83 ec 04             	sub    $0x4,%esp
8010418e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
80104191:	e8 98 f3 ff ff       	call   8010352e <myproc>

  if(addr >= curproc->sz)
80104196:	39 18                	cmp    %ebx,(%eax)
80104198:	76 26                	jbe    801041c0 <fetchstr+0x39>
    return -1;
  *pp = (char*)addr;
8010419a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010419d:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
8010419f:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
801041a1:	89 d8                	mov    %ebx,%eax
801041a3:	39 d0                	cmp    %edx,%eax
801041a5:	73 0e                	jae    801041b5 <fetchstr+0x2e>
    if(*s == 0)
801041a7:	80 38 00             	cmpb   $0x0,(%eax)
801041aa:	74 05                	je     801041b1 <fetchstr+0x2a>
  for(s = *pp; s < ep; s++){
801041ac:	83 c0 01             	add    $0x1,%eax
801041af:	eb f2                	jmp    801041a3 <fetchstr+0x1c>
      return s - *pp;
801041b1:	29 d8                	sub    %ebx,%eax
801041b3:	eb 05                	jmp    801041ba <fetchstr+0x33>
  }
  return -1;
801041b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801041ba:	83 c4 04             	add    $0x4,%esp
801041bd:	5b                   	pop    %ebx
801041be:	5d                   	pop    %ebp
801041bf:	c3                   	ret    
    return -1;
801041c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801041c5:	eb f3                	jmp    801041ba <fetchstr+0x33>

801041c7 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801041c7:	55                   	push   %ebp
801041c8:	89 e5                	mov    %esp,%ebp
801041ca:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
801041cd:	e8 5c f3 ff ff       	call   8010352e <myproc>
801041d2:	8b 50 18             	mov    0x18(%eax),%edx
801041d5:	8b 45 08             	mov    0x8(%ebp),%eax
801041d8:	c1 e0 02             	shl    $0x2,%eax
801041db:	03 42 44             	add    0x44(%edx),%eax
801041de:	83 ec 08             	sub    $0x8,%esp
801041e1:	ff 75 0c             	pushl  0xc(%ebp)
801041e4:	83 c0 04             	add    $0x4,%eax
801041e7:	50                   	push   %eax
801041e8:	e8 5e ff ff ff       	call   8010414b <fetchint>
}
801041ed:	c9                   	leave  
801041ee:	c3                   	ret    

801041ef <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801041ef:	55                   	push   %ebp
801041f0:	89 e5                	mov    %esp,%ebp
801041f2:	56                   	push   %esi
801041f3:	53                   	push   %ebx
801041f4:	83 ec 10             	sub    $0x10,%esp
801041f7:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
801041fa:	e8 2f f3 ff ff       	call   8010352e <myproc>
801041ff:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
80104201:	83 ec 08             	sub    $0x8,%esp
80104204:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104207:	50                   	push   %eax
80104208:	ff 75 08             	pushl  0x8(%ebp)
8010420b:	e8 b7 ff ff ff       	call   801041c7 <argint>
80104210:	83 c4 10             	add    $0x10,%esp
80104213:	85 c0                	test   %eax,%eax
80104215:	78 24                	js     8010423b <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80104217:	85 db                	test   %ebx,%ebx
80104219:	78 27                	js     80104242 <argptr+0x53>
8010421b:	8b 16                	mov    (%esi),%edx
8010421d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104220:	39 c2                	cmp    %eax,%edx
80104222:	76 25                	jbe    80104249 <argptr+0x5a>
80104224:	01 c3                	add    %eax,%ebx
80104226:	39 da                	cmp    %ebx,%edx
80104228:	72 26                	jb     80104250 <argptr+0x61>
    return -1;
  *pp = (char*)i;
8010422a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010422d:	89 02                	mov    %eax,(%edx)
  return 0;
8010422f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104234:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104237:	5b                   	pop    %ebx
80104238:	5e                   	pop    %esi
80104239:	5d                   	pop    %ebp
8010423a:	c3                   	ret    
    return -1;
8010423b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104240:	eb f2                	jmp    80104234 <argptr+0x45>
    return -1;
80104242:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104247:	eb eb                	jmp    80104234 <argptr+0x45>
80104249:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010424e:	eb e4                	jmp    80104234 <argptr+0x45>
80104250:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104255:	eb dd                	jmp    80104234 <argptr+0x45>

80104257 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80104257:	55                   	push   %ebp
80104258:	89 e5                	mov    %esp,%ebp
8010425a:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010425d:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104260:	50                   	push   %eax
80104261:	ff 75 08             	pushl  0x8(%ebp)
80104264:	e8 5e ff ff ff       	call   801041c7 <argint>
80104269:	83 c4 10             	add    $0x10,%esp
8010426c:	85 c0                	test   %eax,%eax
8010426e:	78 13                	js     80104283 <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
80104270:	83 ec 08             	sub    $0x8,%esp
80104273:	ff 75 0c             	pushl  0xc(%ebp)
80104276:	ff 75 f4             	pushl  -0xc(%ebp)
80104279:	e8 09 ff ff ff       	call   80104187 <fetchstr>
8010427e:	83 c4 10             	add    $0x10,%esp
}
80104281:	c9                   	leave  
80104282:	c3                   	ret    
    return -1;
80104283:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104288:	eb f7                	jmp    80104281 <argstr+0x2a>

8010428a <syscall>:
[SYS_dump_physmem]   sys_dump_physmem,
};

void
syscall(void)
{
8010428a:	55                   	push   %ebp
8010428b:	89 e5                	mov    %esp,%ebp
8010428d:	53                   	push   %ebx
8010428e:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
80104291:	e8 98 f2 ff ff       	call   8010352e <myproc>
80104296:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
80104298:	8b 40 18             	mov    0x18(%eax),%eax
8010429b:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
8010429e:	8d 50 ff             	lea    -0x1(%eax),%edx
801042a1:	83 fa 15             	cmp    $0x15,%edx
801042a4:	77 18                	ja     801042be <syscall+0x34>
801042a6:	8b 14 85 c0 6e 10 80 	mov    -0x7fef9140(,%eax,4),%edx
801042ad:	85 d2                	test   %edx,%edx
801042af:	74 0d                	je     801042be <syscall+0x34>
    curproc->tf->eax = syscalls[num]();
801042b1:	ff d2                	call   *%edx
801042b3:	8b 53 18             	mov    0x18(%ebx),%edx
801042b6:	89 42 1c             	mov    %eax,0x1c(%edx)
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}
801042b9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801042bc:	c9                   	leave  
801042bd:	c3                   	ret    
            curproc->pid, curproc->name, num);
801042be:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
801042c1:	50                   	push   %eax
801042c2:	52                   	push   %edx
801042c3:	ff 73 10             	pushl  0x10(%ebx)
801042c6:	68 91 6e 10 80       	push   $0x80106e91
801042cb:	e8 3b c3 ff ff       	call   8010060b <cprintf>
    curproc->tf->eax = -1;
801042d0:	8b 43 18             	mov    0x18(%ebx),%eax
801042d3:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
801042da:	83 c4 10             	add    $0x10,%esp
}
801042dd:	eb da                	jmp    801042b9 <syscall+0x2f>

801042df <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801042df:	55                   	push   %ebp
801042e0:	89 e5                	mov    %esp,%ebp
801042e2:	56                   	push   %esi
801042e3:	53                   	push   %ebx
801042e4:	83 ec 18             	sub    $0x18,%esp
801042e7:	89 d6                	mov    %edx,%esi
801042e9:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801042eb:	8d 55 f4             	lea    -0xc(%ebp),%edx
801042ee:	52                   	push   %edx
801042ef:	50                   	push   %eax
801042f0:	e8 d2 fe ff ff       	call   801041c7 <argint>
801042f5:	83 c4 10             	add    $0x10,%esp
801042f8:	85 c0                	test   %eax,%eax
801042fa:	78 2e                	js     8010432a <argfd+0x4b>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
801042fc:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
80104300:	77 2f                	ja     80104331 <argfd+0x52>
80104302:	e8 27 f2 ff ff       	call   8010352e <myproc>
80104307:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010430a:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
8010430e:	85 c0                	test   %eax,%eax
80104310:	74 26                	je     80104338 <argfd+0x59>
    return -1;
  if(pfd)
80104312:	85 f6                	test   %esi,%esi
80104314:	74 02                	je     80104318 <argfd+0x39>
    *pfd = fd;
80104316:	89 16                	mov    %edx,(%esi)
  if(pf)
80104318:	85 db                	test   %ebx,%ebx
8010431a:	74 23                	je     8010433f <argfd+0x60>
    *pf = f;
8010431c:	89 03                	mov    %eax,(%ebx)
  return 0;
8010431e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104323:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104326:	5b                   	pop    %ebx
80104327:	5e                   	pop    %esi
80104328:	5d                   	pop    %ebp
80104329:	c3                   	ret    
    return -1;
8010432a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010432f:	eb f2                	jmp    80104323 <argfd+0x44>
    return -1;
80104331:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104336:	eb eb                	jmp    80104323 <argfd+0x44>
80104338:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010433d:	eb e4                	jmp    80104323 <argfd+0x44>
  return 0;
8010433f:	b8 00 00 00 00       	mov    $0x0,%eax
80104344:	eb dd                	jmp    80104323 <argfd+0x44>

80104346 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80104346:	55                   	push   %ebp
80104347:	89 e5                	mov    %esp,%ebp
80104349:	53                   	push   %ebx
8010434a:	83 ec 04             	sub    $0x4,%esp
8010434d:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
8010434f:	e8 da f1 ff ff       	call   8010352e <myproc>

  for(fd = 0; fd < NOFILE; fd++){
80104354:	ba 00 00 00 00       	mov    $0x0,%edx
80104359:	83 fa 0f             	cmp    $0xf,%edx
8010435c:	7f 18                	jg     80104376 <fdalloc+0x30>
    if(curproc->ofile[fd] == 0){
8010435e:	83 7c 90 28 00       	cmpl   $0x0,0x28(%eax,%edx,4)
80104363:	74 05                	je     8010436a <fdalloc+0x24>
  for(fd = 0; fd < NOFILE; fd++){
80104365:	83 c2 01             	add    $0x1,%edx
80104368:	eb ef                	jmp    80104359 <fdalloc+0x13>
      curproc->ofile[fd] = f;
8010436a:	89 5c 90 28          	mov    %ebx,0x28(%eax,%edx,4)
      return fd;
    }
  }
  return -1;
}
8010436e:	89 d0                	mov    %edx,%eax
80104370:	83 c4 04             	add    $0x4,%esp
80104373:	5b                   	pop    %ebx
80104374:	5d                   	pop    %ebp
80104375:	c3                   	ret    
  return -1;
80104376:	ba ff ff ff ff       	mov    $0xffffffff,%edx
8010437b:	eb f1                	jmp    8010436e <fdalloc+0x28>

8010437d <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
8010437d:	55                   	push   %ebp
8010437e:	89 e5                	mov    %esp,%ebp
80104380:	56                   	push   %esi
80104381:	53                   	push   %ebx
80104382:	83 ec 10             	sub    $0x10,%esp
80104385:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104387:	b8 20 00 00 00       	mov    $0x20,%eax
8010438c:	89 c6                	mov    %eax,%esi
8010438e:	39 43 58             	cmp    %eax,0x58(%ebx)
80104391:	76 2e                	jbe    801043c1 <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104393:	6a 10                	push   $0x10
80104395:	50                   	push   %eax
80104396:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104399:	50                   	push   %eax
8010439a:	53                   	push   %ebx
8010439b:	e8 df d3 ff ff       	call   8010177f <readi>
801043a0:	83 c4 10             	add    $0x10,%esp
801043a3:	83 f8 10             	cmp    $0x10,%eax
801043a6:	75 0c                	jne    801043b4 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
801043a8:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
801043ad:	75 1e                	jne    801043cd <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801043af:	8d 46 10             	lea    0x10(%esi),%eax
801043b2:	eb d8                	jmp    8010438c <isdirempty+0xf>
      panic("isdirempty: readi");
801043b4:	83 ec 0c             	sub    $0xc,%esp
801043b7:	68 1c 6f 10 80       	push   $0x80106f1c
801043bc:	e8 87 bf ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
801043c1:	b8 01 00 00 00       	mov    $0x1,%eax
}
801043c6:	8d 65 f8             	lea    -0x8(%ebp),%esp
801043c9:	5b                   	pop    %ebx
801043ca:	5e                   	pop    %esi
801043cb:	5d                   	pop    %ebp
801043cc:	c3                   	ret    
      return 0;
801043cd:	b8 00 00 00 00       	mov    $0x0,%eax
801043d2:	eb f2                	jmp    801043c6 <isdirempty+0x49>

801043d4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
801043d4:	55                   	push   %ebp
801043d5:	89 e5                	mov    %esp,%ebp
801043d7:	57                   	push   %edi
801043d8:	56                   	push   %esi
801043d9:	53                   	push   %ebx
801043da:	83 ec 44             	sub    $0x44,%esp
801043dd:	89 55 c4             	mov    %edx,-0x3c(%ebp)
801043e0:	89 4d c0             	mov    %ecx,-0x40(%ebp)
801043e3:	8b 7d 08             	mov    0x8(%ebp),%edi
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
801043e6:	8d 55 d6             	lea    -0x2a(%ebp),%edx
801043e9:	52                   	push   %edx
801043ea:	50                   	push   %eax
801043eb:	e8 15 d8 ff ff       	call   80101c05 <nameiparent>
801043f0:	89 c6                	mov    %eax,%esi
801043f2:	83 c4 10             	add    $0x10,%esp
801043f5:	85 c0                	test   %eax,%eax
801043f7:	0f 84 3a 01 00 00    	je     80104537 <create+0x163>
    return 0;
  ilock(dp);
801043fd:	83 ec 0c             	sub    $0xc,%esp
80104400:	50                   	push   %eax
80104401:	e8 87 d1 ff ff       	call   8010158d <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80104406:	83 c4 0c             	add    $0xc,%esp
80104409:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010440c:	50                   	push   %eax
8010440d:	8d 45 d6             	lea    -0x2a(%ebp),%eax
80104410:	50                   	push   %eax
80104411:	56                   	push   %esi
80104412:	e8 a5 d5 ff ff       	call   801019bc <dirlookup>
80104417:	89 c3                	mov    %eax,%ebx
80104419:	83 c4 10             	add    $0x10,%esp
8010441c:	85 c0                	test   %eax,%eax
8010441e:	74 3f                	je     8010445f <create+0x8b>
    iunlockput(dp);
80104420:	83 ec 0c             	sub    $0xc,%esp
80104423:	56                   	push   %esi
80104424:	e8 0b d3 ff ff       	call   80101734 <iunlockput>
    ilock(ip);
80104429:	89 1c 24             	mov    %ebx,(%esp)
8010442c:	e8 5c d1 ff ff       	call   8010158d <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80104431:	83 c4 10             	add    $0x10,%esp
80104434:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%ebp)
80104439:	75 11                	jne    8010444c <create+0x78>
8010443b:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
80104440:	75 0a                	jne    8010444c <create+0x78>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
80104442:	89 d8                	mov    %ebx,%eax
80104444:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104447:	5b                   	pop    %ebx
80104448:	5e                   	pop    %esi
80104449:	5f                   	pop    %edi
8010444a:	5d                   	pop    %ebp
8010444b:	c3                   	ret    
    iunlockput(ip);
8010444c:	83 ec 0c             	sub    $0xc,%esp
8010444f:	53                   	push   %ebx
80104450:	e8 df d2 ff ff       	call   80101734 <iunlockput>
    return 0;
80104455:	83 c4 10             	add    $0x10,%esp
80104458:	bb 00 00 00 00       	mov    $0x0,%ebx
8010445d:	eb e3                	jmp    80104442 <create+0x6e>
  if((ip = ialloc(dp->dev, type)) == 0)
8010445f:	0f bf 45 c4          	movswl -0x3c(%ebp),%eax
80104463:	83 ec 08             	sub    $0x8,%esp
80104466:	50                   	push   %eax
80104467:	ff 36                	pushl  (%esi)
80104469:	e8 1c cf ff ff       	call   8010138a <ialloc>
8010446e:	89 c3                	mov    %eax,%ebx
80104470:	83 c4 10             	add    $0x10,%esp
80104473:	85 c0                	test   %eax,%eax
80104475:	74 55                	je     801044cc <create+0xf8>
  ilock(ip);
80104477:	83 ec 0c             	sub    $0xc,%esp
8010447a:	50                   	push   %eax
8010447b:	e8 0d d1 ff ff       	call   8010158d <ilock>
  ip->major = major;
80104480:	0f b7 45 c0          	movzwl -0x40(%ebp),%eax
80104484:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
80104488:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
8010448c:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
80104492:	89 1c 24             	mov    %ebx,(%esp)
80104495:	e8 92 cf ff ff       	call   8010142c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
8010449a:	83 c4 10             	add    $0x10,%esp
8010449d:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%ebp)
801044a2:	74 35                	je     801044d9 <create+0x105>
  if(dirlink(dp, name, ip->inum) < 0)
801044a4:	83 ec 04             	sub    $0x4,%esp
801044a7:	ff 73 04             	pushl  0x4(%ebx)
801044aa:	8d 45 d6             	lea    -0x2a(%ebp),%eax
801044ad:	50                   	push   %eax
801044ae:	56                   	push   %esi
801044af:	e8 88 d6 ff ff       	call   80101b3c <dirlink>
801044b4:	83 c4 10             	add    $0x10,%esp
801044b7:	85 c0                	test   %eax,%eax
801044b9:	78 6f                	js     8010452a <create+0x156>
  iunlockput(dp);
801044bb:	83 ec 0c             	sub    $0xc,%esp
801044be:	56                   	push   %esi
801044bf:	e8 70 d2 ff ff       	call   80101734 <iunlockput>
  return ip;
801044c4:	83 c4 10             	add    $0x10,%esp
801044c7:	e9 76 ff ff ff       	jmp    80104442 <create+0x6e>
    panic("create: ialloc");
801044cc:	83 ec 0c             	sub    $0xc,%esp
801044cf:	68 2e 6f 10 80       	push   $0x80106f2e
801044d4:	e8 6f be ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
801044d9:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801044dd:	83 c0 01             	add    $0x1,%eax
801044e0:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801044e4:	83 ec 0c             	sub    $0xc,%esp
801044e7:	56                   	push   %esi
801044e8:	e8 3f cf ff ff       	call   8010142c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
801044ed:	83 c4 0c             	add    $0xc,%esp
801044f0:	ff 73 04             	pushl  0x4(%ebx)
801044f3:	68 3e 6f 10 80       	push   $0x80106f3e
801044f8:	53                   	push   %ebx
801044f9:	e8 3e d6 ff ff       	call   80101b3c <dirlink>
801044fe:	83 c4 10             	add    $0x10,%esp
80104501:	85 c0                	test   %eax,%eax
80104503:	78 18                	js     8010451d <create+0x149>
80104505:	83 ec 04             	sub    $0x4,%esp
80104508:	ff 76 04             	pushl  0x4(%esi)
8010450b:	68 3d 6f 10 80       	push   $0x80106f3d
80104510:	53                   	push   %ebx
80104511:	e8 26 d6 ff ff       	call   80101b3c <dirlink>
80104516:	83 c4 10             	add    $0x10,%esp
80104519:	85 c0                	test   %eax,%eax
8010451b:	79 87                	jns    801044a4 <create+0xd0>
      panic("create dots");
8010451d:	83 ec 0c             	sub    $0xc,%esp
80104520:	68 40 6f 10 80       	push   $0x80106f40
80104525:	e8 1e be ff ff       	call   80100348 <panic>
    panic("create: dirlink");
8010452a:	83 ec 0c             	sub    $0xc,%esp
8010452d:	68 4c 6f 10 80       	push   $0x80106f4c
80104532:	e8 11 be ff ff       	call   80100348 <panic>
    return 0;
80104537:	89 c3                	mov    %eax,%ebx
80104539:	e9 04 ff ff ff       	jmp    80104442 <create+0x6e>

8010453e <sys_dup>:
{
8010453e:	55                   	push   %ebp
8010453f:	89 e5                	mov    %esp,%ebp
80104541:	53                   	push   %ebx
80104542:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
80104545:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104548:	ba 00 00 00 00       	mov    $0x0,%edx
8010454d:	b8 00 00 00 00       	mov    $0x0,%eax
80104552:	e8 88 fd ff ff       	call   801042df <argfd>
80104557:	85 c0                	test   %eax,%eax
80104559:	78 23                	js     8010457e <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
8010455b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010455e:	e8 e3 fd ff ff       	call   80104346 <fdalloc>
80104563:	89 c3                	mov    %eax,%ebx
80104565:	85 c0                	test   %eax,%eax
80104567:	78 1c                	js     80104585 <sys_dup+0x47>
  filedup(f);
80104569:	83 ec 0c             	sub    $0xc,%esp
8010456c:	ff 75 f4             	pushl  -0xc(%ebp)
8010456f:	e8 26 c7 ff ff       	call   80100c9a <filedup>
  return fd;
80104574:	83 c4 10             	add    $0x10,%esp
}
80104577:	89 d8                	mov    %ebx,%eax
80104579:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010457c:	c9                   	leave  
8010457d:	c3                   	ret    
    return -1;
8010457e:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104583:	eb f2                	jmp    80104577 <sys_dup+0x39>
    return -1;
80104585:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
8010458a:	eb eb                	jmp    80104577 <sys_dup+0x39>

8010458c <sys_read>:
{
8010458c:	55                   	push   %ebp
8010458d:	89 e5                	mov    %esp,%ebp
8010458f:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104592:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104595:	ba 00 00 00 00       	mov    $0x0,%edx
8010459a:	b8 00 00 00 00       	mov    $0x0,%eax
8010459f:	e8 3b fd ff ff       	call   801042df <argfd>
801045a4:	85 c0                	test   %eax,%eax
801045a6:	78 43                	js     801045eb <sys_read+0x5f>
801045a8:	83 ec 08             	sub    $0x8,%esp
801045ab:	8d 45 f0             	lea    -0x10(%ebp),%eax
801045ae:	50                   	push   %eax
801045af:	6a 02                	push   $0x2
801045b1:	e8 11 fc ff ff       	call   801041c7 <argint>
801045b6:	83 c4 10             	add    $0x10,%esp
801045b9:	85 c0                	test   %eax,%eax
801045bb:	78 35                	js     801045f2 <sys_read+0x66>
801045bd:	83 ec 04             	sub    $0x4,%esp
801045c0:	ff 75 f0             	pushl  -0x10(%ebp)
801045c3:	8d 45 ec             	lea    -0x14(%ebp),%eax
801045c6:	50                   	push   %eax
801045c7:	6a 01                	push   $0x1
801045c9:	e8 21 fc ff ff       	call   801041ef <argptr>
801045ce:	83 c4 10             	add    $0x10,%esp
801045d1:	85 c0                	test   %eax,%eax
801045d3:	78 24                	js     801045f9 <sys_read+0x6d>
  return fileread(f, p, n);
801045d5:	83 ec 04             	sub    $0x4,%esp
801045d8:	ff 75 f0             	pushl  -0x10(%ebp)
801045db:	ff 75 ec             	pushl  -0x14(%ebp)
801045de:	ff 75 f4             	pushl  -0xc(%ebp)
801045e1:	e8 fd c7 ff ff       	call   80100de3 <fileread>
801045e6:	83 c4 10             	add    $0x10,%esp
}
801045e9:	c9                   	leave  
801045ea:	c3                   	ret    
    return -1;
801045eb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045f0:	eb f7                	jmp    801045e9 <sys_read+0x5d>
801045f2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045f7:	eb f0                	jmp    801045e9 <sys_read+0x5d>
801045f9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045fe:	eb e9                	jmp    801045e9 <sys_read+0x5d>

80104600 <sys_write>:
{
80104600:	55                   	push   %ebp
80104601:	89 e5                	mov    %esp,%ebp
80104603:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104606:	8d 4d f4             	lea    -0xc(%ebp),%ecx
80104609:	ba 00 00 00 00       	mov    $0x0,%edx
8010460e:	b8 00 00 00 00       	mov    $0x0,%eax
80104613:	e8 c7 fc ff ff       	call   801042df <argfd>
80104618:	85 c0                	test   %eax,%eax
8010461a:	78 43                	js     8010465f <sys_write+0x5f>
8010461c:	83 ec 08             	sub    $0x8,%esp
8010461f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104622:	50                   	push   %eax
80104623:	6a 02                	push   $0x2
80104625:	e8 9d fb ff ff       	call   801041c7 <argint>
8010462a:	83 c4 10             	add    $0x10,%esp
8010462d:	85 c0                	test   %eax,%eax
8010462f:	78 35                	js     80104666 <sys_write+0x66>
80104631:	83 ec 04             	sub    $0x4,%esp
80104634:	ff 75 f0             	pushl  -0x10(%ebp)
80104637:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010463a:	50                   	push   %eax
8010463b:	6a 01                	push   $0x1
8010463d:	e8 ad fb ff ff       	call   801041ef <argptr>
80104642:	83 c4 10             	add    $0x10,%esp
80104645:	85 c0                	test   %eax,%eax
80104647:	78 24                	js     8010466d <sys_write+0x6d>
  return filewrite(f, p, n);
80104649:	83 ec 04             	sub    $0x4,%esp
8010464c:	ff 75 f0             	pushl  -0x10(%ebp)
8010464f:	ff 75 ec             	pushl  -0x14(%ebp)
80104652:	ff 75 f4             	pushl  -0xc(%ebp)
80104655:	e8 0e c8 ff ff       	call   80100e68 <filewrite>
8010465a:	83 c4 10             	add    $0x10,%esp
}
8010465d:	c9                   	leave  
8010465e:	c3                   	ret    
    return -1;
8010465f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104664:	eb f7                	jmp    8010465d <sys_write+0x5d>
80104666:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010466b:	eb f0                	jmp    8010465d <sys_write+0x5d>
8010466d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104672:	eb e9                	jmp    8010465d <sys_write+0x5d>

80104674 <sys_close>:
{
80104674:	55                   	push   %ebp
80104675:	89 e5                	mov    %esp,%ebp
80104677:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
8010467a:	8d 4d f0             	lea    -0x10(%ebp),%ecx
8010467d:	8d 55 f4             	lea    -0xc(%ebp),%edx
80104680:	b8 00 00 00 00       	mov    $0x0,%eax
80104685:	e8 55 fc ff ff       	call   801042df <argfd>
8010468a:	85 c0                	test   %eax,%eax
8010468c:	78 25                	js     801046b3 <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
8010468e:	e8 9b ee ff ff       	call   8010352e <myproc>
80104693:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104696:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
8010469d:	00 
  fileclose(f);
8010469e:	83 ec 0c             	sub    $0xc,%esp
801046a1:	ff 75 f0             	pushl  -0x10(%ebp)
801046a4:	e8 36 c6 ff ff       	call   80100cdf <fileclose>
  return 0;
801046a9:	83 c4 10             	add    $0x10,%esp
801046ac:	b8 00 00 00 00       	mov    $0x0,%eax
}
801046b1:	c9                   	leave  
801046b2:	c3                   	ret    
    return -1;
801046b3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046b8:	eb f7                	jmp    801046b1 <sys_close+0x3d>

801046ba <sys_fstat>:
{
801046ba:	55                   	push   %ebp
801046bb:	89 e5                	mov    %esp,%ebp
801046bd:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
801046c0:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801046c3:	ba 00 00 00 00       	mov    $0x0,%edx
801046c8:	b8 00 00 00 00       	mov    $0x0,%eax
801046cd:	e8 0d fc ff ff       	call   801042df <argfd>
801046d2:	85 c0                	test   %eax,%eax
801046d4:	78 2a                	js     80104700 <sys_fstat+0x46>
801046d6:	83 ec 04             	sub    $0x4,%esp
801046d9:	6a 14                	push   $0x14
801046db:	8d 45 f0             	lea    -0x10(%ebp),%eax
801046de:	50                   	push   %eax
801046df:	6a 01                	push   $0x1
801046e1:	e8 09 fb ff ff       	call   801041ef <argptr>
801046e6:	83 c4 10             	add    $0x10,%esp
801046e9:	85 c0                	test   %eax,%eax
801046eb:	78 1a                	js     80104707 <sys_fstat+0x4d>
  return filestat(f, st);
801046ed:	83 ec 08             	sub    $0x8,%esp
801046f0:	ff 75 f0             	pushl  -0x10(%ebp)
801046f3:	ff 75 f4             	pushl  -0xc(%ebp)
801046f6:	e8 a1 c6 ff ff       	call   80100d9c <filestat>
801046fb:	83 c4 10             	add    $0x10,%esp
}
801046fe:	c9                   	leave  
801046ff:	c3                   	ret    
    return -1;
80104700:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104705:	eb f7                	jmp    801046fe <sys_fstat+0x44>
80104707:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010470c:	eb f0                	jmp    801046fe <sys_fstat+0x44>

8010470e <sys_link>:
{
8010470e:	55                   	push   %ebp
8010470f:	89 e5                	mov    %esp,%ebp
80104711:	56                   	push   %esi
80104712:	53                   	push   %ebx
80104713:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80104716:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104719:	50                   	push   %eax
8010471a:	6a 00                	push   $0x0
8010471c:	e8 36 fb ff ff       	call   80104257 <argstr>
80104721:	83 c4 10             	add    $0x10,%esp
80104724:	85 c0                	test   %eax,%eax
80104726:	0f 88 32 01 00 00    	js     8010485e <sys_link+0x150>
8010472c:	83 ec 08             	sub    $0x8,%esp
8010472f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104732:	50                   	push   %eax
80104733:	6a 01                	push   $0x1
80104735:	e8 1d fb ff ff       	call   80104257 <argstr>
8010473a:	83 c4 10             	add    $0x10,%esp
8010473d:	85 c0                	test   %eax,%eax
8010473f:	0f 88 20 01 00 00    	js     80104865 <sys_link+0x157>
  begin_op();
80104745:	e8 89 e3 ff ff       	call   80102ad3 <begin_op>
  if((ip = namei(old)) == 0){
8010474a:	83 ec 0c             	sub    $0xc,%esp
8010474d:	ff 75 e0             	pushl  -0x20(%ebp)
80104750:	e8 98 d4 ff ff       	call   80101bed <namei>
80104755:	89 c3                	mov    %eax,%ebx
80104757:	83 c4 10             	add    $0x10,%esp
8010475a:	85 c0                	test   %eax,%eax
8010475c:	0f 84 99 00 00 00    	je     801047fb <sys_link+0xed>
  ilock(ip);
80104762:	83 ec 0c             	sub    $0xc,%esp
80104765:	50                   	push   %eax
80104766:	e8 22 ce ff ff       	call   8010158d <ilock>
  if(ip->type == T_DIR){
8010476b:	83 c4 10             	add    $0x10,%esp
8010476e:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104773:	0f 84 8e 00 00 00    	je     80104807 <sys_link+0xf9>
  ip->nlink++;
80104779:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010477d:	83 c0 01             	add    $0x1,%eax
80104780:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104784:	83 ec 0c             	sub    $0xc,%esp
80104787:	53                   	push   %ebx
80104788:	e8 9f cc ff ff       	call   8010142c <iupdate>
  iunlock(ip);
8010478d:	89 1c 24             	mov    %ebx,(%esp)
80104790:	e8 ba ce ff ff       	call   8010164f <iunlock>
  if((dp = nameiparent(new, name)) == 0)
80104795:	83 c4 08             	add    $0x8,%esp
80104798:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010479b:	50                   	push   %eax
8010479c:	ff 75 e4             	pushl  -0x1c(%ebp)
8010479f:	e8 61 d4 ff ff       	call   80101c05 <nameiparent>
801047a4:	89 c6                	mov    %eax,%esi
801047a6:	83 c4 10             	add    $0x10,%esp
801047a9:	85 c0                	test   %eax,%eax
801047ab:	74 7e                	je     8010482b <sys_link+0x11d>
  ilock(dp);
801047ad:	83 ec 0c             	sub    $0xc,%esp
801047b0:	50                   	push   %eax
801047b1:	e8 d7 cd ff ff       	call   8010158d <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801047b6:	83 c4 10             	add    $0x10,%esp
801047b9:	8b 03                	mov    (%ebx),%eax
801047bb:	39 06                	cmp    %eax,(%esi)
801047bd:	75 60                	jne    8010481f <sys_link+0x111>
801047bf:	83 ec 04             	sub    $0x4,%esp
801047c2:	ff 73 04             	pushl  0x4(%ebx)
801047c5:	8d 45 ea             	lea    -0x16(%ebp),%eax
801047c8:	50                   	push   %eax
801047c9:	56                   	push   %esi
801047ca:	e8 6d d3 ff ff       	call   80101b3c <dirlink>
801047cf:	83 c4 10             	add    $0x10,%esp
801047d2:	85 c0                	test   %eax,%eax
801047d4:	78 49                	js     8010481f <sys_link+0x111>
  iunlockput(dp);
801047d6:	83 ec 0c             	sub    $0xc,%esp
801047d9:	56                   	push   %esi
801047da:	e8 55 cf ff ff       	call   80101734 <iunlockput>
  iput(ip);
801047df:	89 1c 24             	mov    %ebx,(%esp)
801047e2:	e8 ad ce ff ff       	call   80101694 <iput>
  end_op();
801047e7:	e8 61 e3 ff ff       	call   80102b4d <end_op>
  return 0;
801047ec:	83 c4 10             	add    $0x10,%esp
801047ef:	b8 00 00 00 00       	mov    $0x0,%eax
}
801047f4:	8d 65 f8             	lea    -0x8(%ebp),%esp
801047f7:	5b                   	pop    %ebx
801047f8:	5e                   	pop    %esi
801047f9:	5d                   	pop    %ebp
801047fa:	c3                   	ret    
    end_op();
801047fb:	e8 4d e3 ff ff       	call   80102b4d <end_op>
    return -1;
80104800:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104805:	eb ed                	jmp    801047f4 <sys_link+0xe6>
    iunlockput(ip);
80104807:	83 ec 0c             	sub    $0xc,%esp
8010480a:	53                   	push   %ebx
8010480b:	e8 24 cf ff ff       	call   80101734 <iunlockput>
    end_op();
80104810:	e8 38 e3 ff ff       	call   80102b4d <end_op>
    return -1;
80104815:	83 c4 10             	add    $0x10,%esp
80104818:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010481d:	eb d5                	jmp    801047f4 <sys_link+0xe6>
    iunlockput(dp);
8010481f:	83 ec 0c             	sub    $0xc,%esp
80104822:	56                   	push   %esi
80104823:	e8 0c cf ff ff       	call   80101734 <iunlockput>
    goto bad;
80104828:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
8010482b:	83 ec 0c             	sub    $0xc,%esp
8010482e:	53                   	push   %ebx
8010482f:	e8 59 cd ff ff       	call   8010158d <ilock>
  ip->nlink--;
80104834:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104838:	83 e8 01             	sub    $0x1,%eax
8010483b:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
8010483f:	89 1c 24             	mov    %ebx,(%esp)
80104842:	e8 e5 cb ff ff       	call   8010142c <iupdate>
  iunlockput(ip);
80104847:	89 1c 24             	mov    %ebx,(%esp)
8010484a:	e8 e5 ce ff ff       	call   80101734 <iunlockput>
  end_op();
8010484f:	e8 f9 e2 ff ff       	call   80102b4d <end_op>
  return -1;
80104854:	83 c4 10             	add    $0x10,%esp
80104857:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010485c:	eb 96                	jmp    801047f4 <sys_link+0xe6>
    return -1;
8010485e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104863:	eb 8f                	jmp    801047f4 <sys_link+0xe6>
80104865:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010486a:	eb 88                	jmp    801047f4 <sys_link+0xe6>

8010486c <sys_unlink>:
{
8010486c:	55                   	push   %ebp
8010486d:	89 e5                	mov    %esp,%ebp
8010486f:	57                   	push   %edi
80104870:	56                   	push   %esi
80104871:	53                   	push   %ebx
80104872:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
80104875:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104878:	50                   	push   %eax
80104879:	6a 00                	push   $0x0
8010487b:	e8 d7 f9 ff ff       	call   80104257 <argstr>
80104880:	83 c4 10             	add    $0x10,%esp
80104883:	85 c0                	test   %eax,%eax
80104885:	0f 88 83 01 00 00    	js     80104a0e <sys_unlink+0x1a2>
  begin_op();
8010488b:	e8 43 e2 ff ff       	call   80102ad3 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80104890:	83 ec 08             	sub    $0x8,%esp
80104893:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104896:	50                   	push   %eax
80104897:	ff 75 c4             	pushl  -0x3c(%ebp)
8010489a:	e8 66 d3 ff ff       	call   80101c05 <nameiparent>
8010489f:	89 c6                	mov    %eax,%esi
801048a1:	83 c4 10             	add    $0x10,%esp
801048a4:	85 c0                	test   %eax,%eax
801048a6:	0f 84 ed 00 00 00    	je     80104999 <sys_unlink+0x12d>
  ilock(dp);
801048ac:	83 ec 0c             	sub    $0xc,%esp
801048af:	50                   	push   %eax
801048b0:	e8 d8 cc ff ff       	call   8010158d <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801048b5:	83 c4 08             	add    $0x8,%esp
801048b8:	68 3e 6f 10 80       	push   $0x80106f3e
801048bd:	8d 45 ca             	lea    -0x36(%ebp),%eax
801048c0:	50                   	push   %eax
801048c1:	e8 e1 d0 ff ff       	call   801019a7 <namecmp>
801048c6:	83 c4 10             	add    $0x10,%esp
801048c9:	85 c0                	test   %eax,%eax
801048cb:	0f 84 fc 00 00 00    	je     801049cd <sys_unlink+0x161>
801048d1:	83 ec 08             	sub    $0x8,%esp
801048d4:	68 3d 6f 10 80       	push   $0x80106f3d
801048d9:	8d 45 ca             	lea    -0x36(%ebp),%eax
801048dc:	50                   	push   %eax
801048dd:	e8 c5 d0 ff ff       	call   801019a7 <namecmp>
801048e2:	83 c4 10             	add    $0x10,%esp
801048e5:	85 c0                	test   %eax,%eax
801048e7:	0f 84 e0 00 00 00    	je     801049cd <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
801048ed:	83 ec 04             	sub    $0x4,%esp
801048f0:	8d 45 c0             	lea    -0x40(%ebp),%eax
801048f3:	50                   	push   %eax
801048f4:	8d 45 ca             	lea    -0x36(%ebp),%eax
801048f7:	50                   	push   %eax
801048f8:	56                   	push   %esi
801048f9:	e8 be d0 ff ff       	call   801019bc <dirlookup>
801048fe:	89 c3                	mov    %eax,%ebx
80104900:	83 c4 10             	add    $0x10,%esp
80104903:	85 c0                	test   %eax,%eax
80104905:	0f 84 c2 00 00 00    	je     801049cd <sys_unlink+0x161>
  ilock(ip);
8010490b:	83 ec 0c             	sub    $0xc,%esp
8010490e:	50                   	push   %eax
8010490f:	e8 79 cc ff ff       	call   8010158d <ilock>
  if(ip->nlink < 1)
80104914:	83 c4 10             	add    $0x10,%esp
80104917:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
8010491c:	0f 8e 83 00 00 00    	jle    801049a5 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104922:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104927:	0f 84 85 00 00 00    	je     801049b2 <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
8010492d:	83 ec 04             	sub    $0x4,%esp
80104930:	6a 10                	push   $0x10
80104932:	6a 00                	push   $0x0
80104934:	8d 7d d8             	lea    -0x28(%ebp),%edi
80104937:	57                   	push   %edi
80104938:	e8 3f f6 ff ff       	call   80103f7c <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010493d:	6a 10                	push   $0x10
8010493f:	ff 75 c0             	pushl  -0x40(%ebp)
80104942:	57                   	push   %edi
80104943:	56                   	push   %esi
80104944:	e8 33 cf ff ff       	call   8010187c <writei>
80104949:	83 c4 20             	add    $0x20,%esp
8010494c:	83 f8 10             	cmp    $0x10,%eax
8010494f:	0f 85 90 00 00 00    	jne    801049e5 <sys_unlink+0x179>
  if(ip->type == T_DIR){
80104955:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
8010495a:	0f 84 92 00 00 00    	je     801049f2 <sys_unlink+0x186>
  iunlockput(dp);
80104960:	83 ec 0c             	sub    $0xc,%esp
80104963:	56                   	push   %esi
80104964:	e8 cb cd ff ff       	call   80101734 <iunlockput>
  ip->nlink--;
80104969:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010496d:	83 e8 01             	sub    $0x1,%eax
80104970:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104974:	89 1c 24             	mov    %ebx,(%esp)
80104977:	e8 b0 ca ff ff       	call   8010142c <iupdate>
  iunlockput(ip);
8010497c:	89 1c 24             	mov    %ebx,(%esp)
8010497f:	e8 b0 cd ff ff       	call   80101734 <iunlockput>
  end_op();
80104984:	e8 c4 e1 ff ff       	call   80102b4d <end_op>
  return 0;
80104989:	83 c4 10             	add    $0x10,%esp
8010498c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104991:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104994:	5b                   	pop    %ebx
80104995:	5e                   	pop    %esi
80104996:	5f                   	pop    %edi
80104997:	5d                   	pop    %ebp
80104998:	c3                   	ret    
    end_op();
80104999:	e8 af e1 ff ff       	call   80102b4d <end_op>
    return -1;
8010499e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049a3:	eb ec                	jmp    80104991 <sys_unlink+0x125>
    panic("unlink: nlink < 1");
801049a5:	83 ec 0c             	sub    $0xc,%esp
801049a8:	68 5c 6f 10 80       	push   $0x80106f5c
801049ad:	e8 96 b9 ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
801049b2:	89 d8                	mov    %ebx,%eax
801049b4:	e8 c4 f9 ff ff       	call   8010437d <isdirempty>
801049b9:	85 c0                	test   %eax,%eax
801049bb:	0f 85 6c ff ff ff    	jne    8010492d <sys_unlink+0xc1>
    iunlockput(ip);
801049c1:	83 ec 0c             	sub    $0xc,%esp
801049c4:	53                   	push   %ebx
801049c5:	e8 6a cd ff ff       	call   80101734 <iunlockput>
    goto bad;
801049ca:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
801049cd:	83 ec 0c             	sub    $0xc,%esp
801049d0:	56                   	push   %esi
801049d1:	e8 5e cd ff ff       	call   80101734 <iunlockput>
  end_op();
801049d6:	e8 72 e1 ff ff       	call   80102b4d <end_op>
  return -1;
801049db:	83 c4 10             	add    $0x10,%esp
801049de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049e3:	eb ac                	jmp    80104991 <sys_unlink+0x125>
    panic("unlink: writei");
801049e5:	83 ec 0c             	sub    $0xc,%esp
801049e8:	68 6e 6f 10 80       	push   $0x80106f6e
801049ed:	e8 56 b9 ff ff       	call   80100348 <panic>
    dp->nlink--;
801049f2:	0f b7 46 56          	movzwl 0x56(%esi),%eax
801049f6:	83 e8 01             	sub    $0x1,%eax
801049f9:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
801049fd:	83 ec 0c             	sub    $0xc,%esp
80104a00:	56                   	push   %esi
80104a01:	e8 26 ca ff ff       	call   8010142c <iupdate>
80104a06:	83 c4 10             	add    $0x10,%esp
80104a09:	e9 52 ff ff ff       	jmp    80104960 <sys_unlink+0xf4>
    return -1;
80104a0e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a13:	e9 79 ff ff ff       	jmp    80104991 <sys_unlink+0x125>

80104a18 <sys_open>:

int
sys_open(void)
{
80104a18:	55                   	push   %ebp
80104a19:	89 e5                	mov    %esp,%ebp
80104a1b:	57                   	push   %edi
80104a1c:	56                   	push   %esi
80104a1d:	53                   	push   %ebx
80104a1e:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80104a21:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80104a24:	50                   	push   %eax
80104a25:	6a 00                	push   $0x0
80104a27:	e8 2b f8 ff ff       	call   80104257 <argstr>
80104a2c:	83 c4 10             	add    $0x10,%esp
80104a2f:	85 c0                	test   %eax,%eax
80104a31:	0f 88 30 01 00 00    	js     80104b67 <sys_open+0x14f>
80104a37:	83 ec 08             	sub    $0x8,%esp
80104a3a:	8d 45 e0             	lea    -0x20(%ebp),%eax
80104a3d:	50                   	push   %eax
80104a3e:	6a 01                	push   $0x1
80104a40:	e8 82 f7 ff ff       	call   801041c7 <argint>
80104a45:	83 c4 10             	add    $0x10,%esp
80104a48:	85 c0                	test   %eax,%eax
80104a4a:	0f 88 21 01 00 00    	js     80104b71 <sys_open+0x159>
    return -1;

  begin_op();
80104a50:	e8 7e e0 ff ff       	call   80102ad3 <begin_op>

  if(omode & O_CREATE){
80104a55:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
80104a59:	0f 84 84 00 00 00    	je     80104ae3 <sys_open+0xcb>
    ip = create(path, T_FILE, 0, 0);
80104a5f:	83 ec 0c             	sub    $0xc,%esp
80104a62:	6a 00                	push   $0x0
80104a64:	b9 00 00 00 00       	mov    $0x0,%ecx
80104a69:	ba 02 00 00 00       	mov    $0x2,%edx
80104a6e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104a71:	e8 5e f9 ff ff       	call   801043d4 <create>
80104a76:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104a78:	83 c4 10             	add    $0x10,%esp
80104a7b:	85 c0                	test   %eax,%eax
80104a7d:	74 58                	je     80104ad7 <sys_open+0xbf>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80104a7f:	e8 b5 c1 ff ff       	call   80100c39 <filealloc>
80104a84:	89 c3                	mov    %eax,%ebx
80104a86:	85 c0                	test   %eax,%eax
80104a88:	0f 84 ae 00 00 00    	je     80104b3c <sys_open+0x124>
80104a8e:	e8 b3 f8 ff ff       	call   80104346 <fdalloc>
80104a93:	89 c7                	mov    %eax,%edi
80104a95:	85 c0                	test   %eax,%eax
80104a97:	0f 88 9f 00 00 00    	js     80104b3c <sys_open+0x124>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104a9d:	83 ec 0c             	sub    $0xc,%esp
80104aa0:	56                   	push   %esi
80104aa1:	e8 a9 cb ff ff       	call   8010164f <iunlock>
  end_op();
80104aa6:	e8 a2 e0 ff ff       	call   80102b4d <end_op>

  f->type = FD_INODE;
80104aab:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
80104ab1:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104ab4:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
80104abb:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104abe:	83 c4 10             	add    $0x10,%esp
80104ac1:	a8 01                	test   $0x1,%al
80104ac3:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80104ac7:	a8 03                	test   $0x3,%al
80104ac9:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
80104acd:	89 f8                	mov    %edi,%eax
80104acf:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104ad2:	5b                   	pop    %ebx
80104ad3:	5e                   	pop    %esi
80104ad4:	5f                   	pop    %edi
80104ad5:	5d                   	pop    %ebp
80104ad6:	c3                   	ret    
      end_op();
80104ad7:	e8 71 e0 ff ff       	call   80102b4d <end_op>
      return -1;
80104adc:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104ae1:	eb ea                	jmp    80104acd <sys_open+0xb5>
    if((ip = namei(path)) == 0){
80104ae3:	83 ec 0c             	sub    $0xc,%esp
80104ae6:	ff 75 e4             	pushl  -0x1c(%ebp)
80104ae9:	e8 ff d0 ff ff       	call   80101bed <namei>
80104aee:	89 c6                	mov    %eax,%esi
80104af0:	83 c4 10             	add    $0x10,%esp
80104af3:	85 c0                	test   %eax,%eax
80104af5:	74 39                	je     80104b30 <sys_open+0x118>
    ilock(ip);
80104af7:	83 ec 0c             	sub    $0xc,%esp
80104afa:	50                   	push   %eax
80104afb:	e8 8d ca ff ff       	call   8010158d <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80104b00:	83 c4 10             	add    $0x10,%esp
80104b03:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80104b08:	0f 85 71 ff ff ff    	jne    80104a7f <sys_open+0x67>
80104b0e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104b12:	0f 84 67 ff ff ff    	je     80104a7f <sys_open+0x67>
      iunlockput(ip);
80104b18:	83 ec 0c             	sub    $0xc,%esp
80104b1b:	56                   	push   %esi
80104b1c:	e8 13 cc ff ff       	call   80101734 <iunlockput>
      end_op();
80104b21:	e8 27 e0 ff ff       	call   80102b4d <end_op>
      return -1;
80104b26:	83 c4 10             	add    $0x10,%esp
80104b29:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104b2e:	eb 9d                	jmp    80104acd <sys_open+0xb5>
      end_op();
80104b30:	e8 18 e0 ff ff       	call   80102b4d <end_op>
      return -1;
80104b35:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104b3a:	eb 91                	jmp    80104acd <sys_open+0xb5>
    if(f)
80104b3c:	85 db                	test   %ebx,%ebx
80104b3e:	74 0c                	je     80104b4c <sys_open+0x134>
      fileclose(f);
80104b40:	83 ec 0c             	sub    $0xc,%esp
80104b43:	53                   	push   %ebx
80104b44:	e8 96 c1 ff ff       	call   80100cdf <fileclose>
80104b49:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80104b4c:	83 ec 0c             	sub    $0xc,%esp
80104b4f:	56                   	push   %esi
80104b50:	e8 df cb ff ff       	call   80101734 <iunlockput>
    end_op();
80104b55:	e8 f3 df ff ff       	call   80102b4d <end_op>
    return -1;
80104b5a:	83 c4 10             	add    $0x10,%esp
80104b5d:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104b62:	e9 66 ff ff ff       	jmp    80104acd <sys_open+0xb5>
    return -1;
80104b67:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104b6c:	e9 5c ff ff ff       	jmp    80104acd <sys_open+0xb5>
80104b71:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104b76:	e9 52 ff ff ff       	jmp    80104acd <sys_open+0xb5>

80104b7b <sys_mkdir>:

int
sys_mkdir(void)
{
80104b7b:	55                   	push   %ebp
80104b7c:	89 e5                	mov    %esp,%ebp
80104b7e:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104b81:	e8 4d df ff ff       	call   80102ad3 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104b86:	83 ec 08             	sub    $0x8,%esp
80104b89:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b8c:	50                   	push   %eax
80104b8d:	6a 00                	push   $0x0
80104b8f:	e8 c3 f6 ff ff       	call   80104257 <argstr>
80104b94:	83 c4 10             	add    $0x10,%esp
80104b97:	85 c0                	test   %eax,%eax
80104b99:	78 36                	js     80104bd1 <sys_mkdir+0x56>
80104b9b:	83 ec 0c             	sub    $0xc,%esp
80104b9e:	6a 00                	push   $0x0
80104ba0:	b9 00 00 00 00       	mov    $0x0,%ecx
80104ba5:	ba 01 00 00 00       	mov    $0x1,%edx
80104baa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bad:	e8 22 f8 ff ff       	call   801043d4 <create>
80104bb2:	83 c4 10             	add    $0x10,%esp
80104bb5:	85 c0                	test   %eax,%eax
80104bb7:	74 18                	je     80104bd1 <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104bb9:	83 ec 0c             	sub    $0xc,%esp
80104bbc:	50                   	push   %eax
80104bbd:	e8 72 cb ff ff       	call   80101734 <iunlockput>
  end_op();
80104bc2:	e8 86 df ff ff       	call   80102b4d <end_op>
  return 0;
80104bc7:	83 c4 10             	add    $0x10,%esp
80104bca:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104bcf:	c9                   	leave  
80104bd0:	c3                   	ret    
    end_op();
80104bd1:	e8 77 df ff ff       	call   80102b4d <end_op>
    return -1;
80104bd6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bdb:	eb f2                	jmp    80104bcf <sys_mkdir+0x54>

80104bdd <sys_mknod>:

int
sys_mknod(void)
{
80104bdd:	55                   	push   %ebp
80104bde:	89 e5                	mov    %esp,%ebp
80104be0:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104be3:	e8 eb de ff ff       	call   80102ad3 <begin_op>
  if((argstr(0, &path)) < 0 ||
80104be8:	83 ec 08             	sub    $0x8,%esp
80104beb:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104bee:	50                   	push   %eax
80104bef:	6a 00                	push   $0x0
80104bf1:	e8 61 f6 ff ff       	call   80104257 <argstr>
80104bf6:	83 c4 10             	add    $0x10,%esp
80104bf9:	85 c0                	test   %eax,%eax
80104bfb:	78 62                	js     80104c5f <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104bfd:	83 ec 08             	sub    $0x8,%esp
80104c00:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104c03:	50                   	push   %eax
80104c04:	6a 01                	push   $0x1
80104c06:	e8 bc f5 ff ff       	call   801041c7 <argint>
  if((argstr(0, &path)) < 0 ||
80104c0b:	83 c4 10             	add    $0x10,%esp
80104c0e:	85 c0                	test   %eax,%eax
80104c10:	78 4d                	js     80104c5f <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104c12:	83 ec 08             	sub    $0x8,%esp
80104c15:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104c18:	50                   	push   %eax
80104c19:	6a 02                	push   $0x2
80104c1b:	e8 a7 f5 ff ff       	call   801041c7 <argint>
     argint(1, &major) < 0 ||
80104c20:	83 c4 10             	add    $0x10,%esp
80104c23:	85 c0                	test   %eax,%eax
80104c25:	78 38                	js     80104c5f <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104c27:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104c2b:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
     argint(2, &minor) < 0 ||
80104c2f:	83 ec 0c             	sub    $0xc,%esp
80104c32:	50                   	push   %eax
80104c33:	ba 03 00 00 00       	mov    $0x3,%edx
80104c38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c3b:	e8 94 f7 ff ff       	call   801043d4 <create>
80104c40:	83 c4 10             	add    $0x10,%esp
80104c43:	85 c0                	test   %eax,%eax
80104c45:	74 18                	je     80104c5f <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104c47:	83 ec 0c             	sub    $0xc,%esp
80104c4a:	50                   	push   %eax
80104c4b:	e8 e4 ca ff ff       	call   80101734 <iunlockput>
  end_op();
80104c50:	e8 f8 de ff ff       	call   80102b4d <end_op>
  return 0;
80104c55:	83 c4 10             	add    $0x10,%esp
80104c58:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104c5d:	c9                   	leave  
80104c5e:	c3                   	ret    
    end_op();
80104c5f:	e8 e9 de ff ff       	call   80102b4d <end_op>
    return -1;
80104c64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c69:	eb f2                	jmp    80104c5d <sys_mknod+0x80>

80104c6b <sys_chdir>:

int
sys_chdir(void)
{
80104c6b:	55                   	push   %ebp
80104c6c:	89 e5                	mov    %esp,%ebp
80104c6e:	56                   	push   %esi
80104c6f:	53                   	push   %ebx
80104c70:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104c73:	e8 b6 e8 ff ff       	call   8010352e <myproc>
80104c78:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104c7a:	e8 54 de ff ff       	call   80102ad3 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104c7f:	83 ec 08             	sub    $0x8,%esp
80104c82:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c85:	50                   	push   %eax
80104c86:	6a 00                	push   $0x0
80104c88:	e8 ca f5 ff ff       	call   80104257 <argstr>
80104c8d:	83 c4 10             	add    $0x10,%esp
80104c90:	85 c0                	test   %eax,%eax
80104c92:	78 52                	js     80104ce6 <sys_chdir+0x7b>
80104c94:	83 ec 0c             	sub    $0xc,%esp
80104c97:	ff 75 f4             	pushl  -0xc(%ebp)
80104c9a:	e8 4e cf ff ff       	call   80101bed <namei>
80104c9f:	89 c3                	mov    %eax,%ebx
80104ca1:	83 c4 10             	add    $0x10,%esp
80104ca4:	85 c0                	test   %eax,%eax
80104ca6:	74 3e                	je     80104ce6 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104ca8:	83 ec 0c             	sub    $0xc,%esp
80104cab:	50                   	push   %eax
80104cac:	e8 dc c8 ff ff       	call   8010158d <ilock>
  if(ip->type != T_DIR){
80104cb1:	83 c4 10             	add    $0x10,%esp
80104cb4:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104cb9:	75 37                	jne    80104cf2 <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104cbb:	83 ec 0c             	sub    $0xc,%esp
80104cbe:	53                   	push   %ebx
80104cbf:	e8 8b c9 ff ff       	call   8010164f <iunlock>
  iput(curproc->cwd);
80104cc4:	83 c4 04             	add    $0x4,%esp
80104cc7:	ff 76 68             	pushl  0x68(%esi)
80104cca:	e8 c5 c9 ff ff       	call   80101694 <iput>
  end_op();
80104ccf:	e8 79 de ff ff       	call   80102b4d <end_op>
  curproc->cwd = ip;
80104cd4:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104cd7:	83 c4 10             	add    $0x10,%esp
80104cda:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104cdf:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104ce2:	5b                   	pop    %ebx
80104ce3:	5e                   	pop    %esi
80104ce4:	5d                   	pop    %ebp
80104ce5:	c3                   	ret    
    end_op();
80104ce6:	e8 62 de ff ff       	call   80102b4d <end_op>
    return -1;
80104ceb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cf0:	eb ed                	jmp    80104cdf <sys_chdir+0x74>
    iunlockput(ip);
80104cf2:	83 ec 0c             	sub    $0xc,%esp
80104cf5:	53                   	push   %ebx
80104cf6:	e8 39 ca ff ff       	call   80101734 <iunlockput>
    end_op();
80104cfb:	e8 4d de ff ff       	call   80102b4d <end_op>
    return -1;
80104d00:	83 c4 10             	add    $0x10,%esp
80104d03:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d08:	eb d5                	jmp    80104cdf <sys_chdir+0x74>

80104d0a <sys_exec>:

int
sys_exec(void)
{
80104d0a:	55                   	push   %ebp
80104d0b:	89 e5                	mov    %esp,%ebp
80104d0d:	53                   	push   %ebx
80104d0e:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104d14:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d17:	50                   	push   %eax
80104d18:	6a 00                	push   $0x0
80104d1a:	e8 38 f5 ff ff       	call   80104257 <argstr>
80104d1f:	83 c4 10             	add    $0x10,%esp
80104d22:	85 c0                	test   %eax,%eax
80104d24:	0f 88 a8 00 00 00    	js     80104dd2 <sys_exec+0xc8>
80104d2a:	83 ec 08             	sub    $0x8,%esp
80104d2d:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104d33:	50                   	push   %eax
80104d34:	6a 01                	push   $0x1
80104d36:	e8 8c f4 ff ff       	call   801041c7 <argint>
80104d3b:	83 c4 10             	add    $0x10,%esp
80104d3e:	85 c0                	test   %eax,%eax
80104d40:	0f 88 93 00 00 00    	js     80104dd9 <sys_exec+0xcf>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104d46:	83 ec 04             	sub    $0x4,%esp
80104d49:	68 80 00 00 00       	push   $0x80
80104d4e:	6a 00                	push   $0x0
80104d50:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104d56:	50                   	push   %eax
80104d57:	e8 20 f2 ff ff       	call   80103f7c <memset>
80104d5c:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104d5f:	bb 00 00 00 00       	mov    $0x0,%ebx
    if(i >= NELEM(argv))
80104d64:	83 fb 1f             	cmp    $0x1f,%ebx
80104d67:	77 77                	ja     80104de0 <sys_exec+0xd6>
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104d69:	83 ec 08             	sub    $0x8,%esp
80104d6c:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104d72:	50                   	push   %eax
80104d73:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104d79:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104d7c:	50                   	push   %eax
80104d7d:	e8 c9 f3 ff ff       	call   8010414b <fetchint>
80104d82:	83 c4 10             	add    $0x10,%esp
80104d85:	85 c0                	test   %eax,%eax
80104d87:	78 5e                	js     80104de7 <sys_exec+0xdd>
      return -1;
    if(uarg == 0){
80104d89:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104d8f:	85 c0                	test   %eax,%eax
80104d91:	74 1d                	je     80104db0 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
80104d93:	83 ec 08             	sub    $0x8,%esp
80104d96:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104d9d:	52                   	push   %edx
80104d9e:	50                   	push   %eax
80104d9f:	e8 e3 f3 ff ff       	call   80104187 <fetchstr>
80104da4:	83 c4 10             	add    $0x10,%esp
80104da7:	85 c0                	test   %eax,%eax
80104da9:	78 46                	js     80104df1 <sys_exec+0xe7>
  for(i=0;; i++){
80104dab:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104dae:	eb b4                	jmp    80104d64 <sys_exec+0x5a>
      argv[i] = 0;
80104db0:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104db7:	00 00 00 00 
      return -1;
  }
  return exec(path, argv);
80104dbb:	83 ec 08             	sub    $0x8,%esp
80104dbe:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104dc4:	50                   	push   %eax
80104dc5:	ff 75 f4             	pushl  -0xc(%ebp)
80104dc8:	e8 05 bb ff ff       	call   801008d2 <exec>
80104dcd:	83 c4 10             	add    $0x10,%esp
80104dd0:	eb 1a                	jmp    80104dec <sys_exec+0xe2>
    return -1;
80104dd2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dd7:	eb 13                	jmp    80104dec <sys_exec+0xe2>
80104dd9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104dde:	eb 0c                	jmp    80104dec <sys_exec+0xe2>
      return -1;
80104de0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104de5:	eb 05                	jmp    80104dec <sys_exec+0xe2>
      return -1;
80104de7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104dec:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104def:	c9                   	leave  
80104df0:	c3                   	ret    
      return -1;
80104df1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104df6:	eb f4                	jmp    80104dec <sys_exec+0xe2>

80104df8 <sys_pipe>:

int
sys_pipe(void)
{
80104df8:	55                   	push   %ebp
80104df9:	89 e5                	mov    %esp,%ebp
80104dfb:	53                   	push   %ebx
80104dfc:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104dff:	6a 08                	push   $0x8
80104e01:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104e04:	50                   	push   %eax
80104e05:	6a 00                	push   $0x0
80104e07:	e8 e3 f3 ff ff       	call   801041ef <argptr>
80104e0c:	83 c4 10             	add    $0x10,%esp
80104e0f:	85 c0                	test   %eax,%eax
80104e11:	78 77                	js     80104e8a <sys_pipe+0x92>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104e13:	83 ec 08             	sub    $0x8,%esp
80104e16:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104e19:	50                   	push   %eax
80104e1a:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104e1d:	50                   	push   %eax
80104e1e:	e8 3c e2 ff ff       	call   8010305f <pipealloc>
80104e23:	83 c4 10             	add    $0x10,%esp
80104e26:	85 c0                	test   %eax,%eax
80104e28:	78 67                	js     80104e91 <sys_pipe+0x99>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104e2a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e2d:	e8 14 f5 ff ff       	call   80104346 <fdalloc>
80104e32:	89 c3                	mov    %eax,%ebx
80104e34:	85 c0                	test   %eax,%eax
80104e36:	78 21                	js     80104e59 <sys_pipe+0x61>
80104e38:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104e3b:	e8 06 f5 ff ff       	call   80104346 <fdalloc>
80104e40:	85 c0                	test   %eax,%eax
80104e42:	78 15                	js     80104e59 <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104e44:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e47:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104e49:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104e4c:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104e4f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e54:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e57:	c9                   	leave  
80104e58:	c3                   	ret    
    if(fd0 >= 0)
80104e59:	85 db                	test   %ebx,%ebx
80104e5b:	78 0d                	js     80104e6a <sys_pipe+0x72>
      myproc()->ofile[fd0] = 0;
80104e5d:	e8 cc e6 ff ff       	call   8010352e <myproc>
80104e62:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104e69:	00 
    fileclose(rf);
80104e6a:	83 ec 0c             	sub    $0xc,%esp
80104e6d:	ff 75 f0             	pushl  -0x10(%ebp)
80104e70:	e8 6a be ff ff       	call   80100cdf <fileclose>
    fileclose(wf);
80104e75:	83 c4 04             	add    $0x4,%esp
80104e78:	ff 75 ec             	pushl  -0x14(%ebp)
80104e7b:	e8 5f be ff ff       	call   80100cdf <fileclose>
    return -1;
80104e80:	83 c4 10             	add    $0x10,%esp
80104e83:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e88:	eb ca                	jmp    80104e54 <sys_pipe+0x5c>
    return -1;
80104e8a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e8f:	eb c3                	jmp    80104e54 <sys_pipe+0x5c>
    return -1;
80104e91:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e96:	eb bc                	jmp    80104e54 <sys_pipe+0x5c>

80104e98 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104e98:	55                   	push   %ebp
80104e99:	89 e5                	mov    %esp,%ebp
80104e9b:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104e9e:	e8 03 e8 ff ff       	call   801036a6 <fork>
}
80104ea3:	c9                   	leave  
80104ea4:	c3                   	ret    

80104ea5 <sys_exit>:

int
sys_exit(void)
{
80104ea5:	55                   	push   %ebp
80104ea6:	89 e5                	mov    %esp,%ebp
80104ea8:	83 ec 08             	sub    $0x8,%esp
  exit();
80104eab:	e8 2d ea ff ff       	call   801038dd <exit>
  return 0;  // not reached
}
80104eb0:	b8 00 00 00 00       	mov    $0x0,%eax
80104eb5:	c9                   	leave  
80104eb6:	c3                   	ret    

80104eb7 <sys_wait>:

int
sys_wait(void)
{
80104eb7:	55                   	push   %ebp
80104eb8:	89 e5                	mov    %esp,%ebp
80104eba:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104ebd:	e8 a4 eb ff ff       	call   80103a66 <wait>
}
80104ec2:	c9                   	leave  
80104ec3:	c3                   	ret    

80104ec4 <sys_kill>:

int
sys_kill(void)
{
80104ec4:	55                   	push   %ebp
80104ec5:	89 e5                	mov    %esp,%ebp
80104ec7:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104eca:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104ecd:	50                   	push   %eax
80104ece:	6a 00                	push   $0x0
80104ed0:	e8 f2 f2 ff ff       	call   801041c7 <argint>
80104ed5:	83 c4 10             	add    $0x10,%esp
80104ed8:	85 c0                	test   %eax,%eax
80104eda:	78 10                	js     80104eec <sys_kill+0x28>
    return -1;
  return kill(pid);
80104edc:	83 ec 0c             	sub    $0xc,%esp
80104edf:	ff 75 f4             	pushl  -0xc(%ebp)
80104ee2:	e8 7c ec ff ff       	call   80103b63 <kill>
80104ee7:	83 c4 10             	add    $0x10,%esp
}
80104eea:	c9                   	leave  
80104eeb:	c3                   	ret    
    return -1;
80104eec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104ef1:	eb f7                	jmp    80104eea <sys_kill+0x26>

80104ef3 <sys_getpid>:

int
sys_getpid(void)
{
80104ef3:	55                   	push   %ebp
80104ef4:	89 e5                	mov    %esp,%ebp
80104ef6:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104ef9:	e8 30 e6 ff ff       	call   8010352e <myproc>
80104efe:	8b 40 10             	mov    0x10(%eax),%eax
}
80104f01:	c9                   	leave  
80104f02:	c3                   	ret    

80104f03 <sys_sbrk>:

int
sys_sbrk(void)
{
80104f03:	55                   	push   %ebp
80104f04:	89 e5                	mov    %esp,%ebp
80104f06:	53                   	push   %ebx
80104f07:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104f0a:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104f0d:	50                   	push   %eax
80104f0e:	6a 00                	push   $0x0
80104f10:	e8 b2 f2 ff ff       	call   801041c7 <argint>
80104f15:	83 c4 10             	add    $0x10,%esp
80104f18:	85 c0                	test   %eax,%eax
80104f1a:	78 27                	js     80104f43 <sys_sbrk+0x40>
    return -1;
  addr = myproc()->sz;
80104f1c:	e8 0d e6 ff ff       	call   8010352e <myproc>
80104f21:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104f23:	83 ec 0c             	sub    $0xc,%esp
80104f26:	ff 75 f4             	pushl  -0xc(%ebp)
80104f29:	e8 0b e7 ff ff       	call   80103639 <growproc>
80104f2e:	83 c4 10             	add    $0x10,%esp
80104f31:	85 c0                	test   %eax,%eax
80104f33:	78 07                	js     80104f3c <sys_sbrk+0x39>
    return -1;
  return addr;
}
80104f35:	89 d8                	mov    %ebx,%eax
80104f37:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104f3a:	c9                   	leave  
80104f3b:	c3                   	ret    
    return -1;
80104f3c:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104f41:	eb f2                	jmp    80104f35 <sys_sbrk+0x32>
    return -1;
80104f43:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104f48:	eb eb                	jmp    80104f35 <sys_sbrk+0x32>

80104f4a <sys_sleep>:

int
sys_sleep(void)
{
80104f4a:	55                   	push   %ebp
80104f4b:	89 e5                	mov    %esp,%ebp
80104f4d:	53                   	push   %ebx
80104f4e:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104f51:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104f54:	50                   	push   %eax
80104f55:	6a 00                	push   $0x0
80104f57:	e8 6b f2 ff ff       	call   801041c7 <argint>
80104f5c:	83 c4 10             	add    $0x10,%esp
80104f5f:	85 c0                	test   %eax,%eax
80104f61:	78 75                	js     80104fd8 <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104f63:	83 ec 0c             	sub    $0xc,%esp
80104f66:	68 60 69 14 80       	push   $0x80146960
80104f6b:	e8 60 ef ff ff       	call   80103ed0 <acquire>
  ticks0 = ticks;
80104f70:	8b 1d a0 71 14 80    	mov    0x801471a0,%ebx
  while(ticks - ticks0 < n){
80104f76:	83 c4 10             	add    $0x10,%esp
80104f79:	a1 a0 71 14 80       	mov    0x801471a0,%eax
80104f7e:	29 d8                	sub    %ebx,%eax
80104f80:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104f83:	73 39                	jae    80104fbe <sys_sleep+0x74>
    if(myproc()->killed){
80104f85:	e8 a4 e5 ff ff       	call   8010352e <myproc>
80104f8a:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104f8e:	75 17                	jne    80104fa7 <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104f90:	83 ec 08             	sub    $0x8,%esp
80104f93:	68 60 69 14 80       	push   $0x80146960
80104f98:	68 a0 71 14 80       	push   $0x801471a0
80104f9d:	e8 33 ea ff ff       	call   801039d5 <sleep>
80104fa2:	83 c4 10             	add    $0x10,%esp
80104fa5:	eb d2                	jmp    80104f79 <sys_sleep+0x2f>
      release(&tickslock);
80104fa7:	83 ec 0c             	sub    $0xc,%esp
80104faa:	68 60 69 14 80       	push   $0x80146960
80104faf:	e8 81 ef ff ff       	call   80103f35 <release>
      return -1;
80104fb4:	83 c4 10             	add    $0x10,%esp
80104fb7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fbc:	eb 15                	jmp    80104fd3 <sys_sleep+0x89>
  }
  release(&tickslock);
80104fbe:	83 ec 0c             	sub    $0xc,%esp
80104fc1:	68 60 69 14 80       	push   $0x80146960
80104fc6:	e8 6a ef ff ff       	call   80103f35 <release>
  return 0;
80104fcb:	83 c4 10             	add    $0x10,%esp
80104fce:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104fd3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104fd6:	c9                   	leave  
80104fd7:	c3                   	ret    
    return -1;
80104fd8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104fdd:	eb f4                	jmp    80104fd3 <sys_sleep+0x89>

80104fdf <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104fdf:	55                   	push   %ebp
80104fe0:	89 e5                	mov    %esp,%ebp
80104fe2:	53                   	push   %ebx
80104fe3:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104fe6:	68 60 69 14 80       	push   $0x80146960
80104feb:	e8 e0 ee ff ff       	call   80103ed0 <acquire>
  xticks = ticks;
80104ff0:	8b 1d a0 71 14 80    	mov    0x801471a0,%ebx
  release(&tickslock);
80104ff6:	c7 04 24 60 69 14 80 	movl   $0x80146960,(%esp)
80104ffd:	e8 33 ef ff ff       	call   80103f35 <release>
  return xticks;
}
80105002:	89 d8                	mov    %ebx,%eax
80105004:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105007:	c9                   	leave  
80105008:	c3                   	ret    

80105009 <sys_dump_physmem>:

int
sys_dump_physmem(void)
{
80105009:	55                   	push   %ebp
8010500a:	89 e5                	mov    %esp,%ebp
8010500c:	83 ec 1c             	sub    $0x1c,%esp
  int *frames;
  int *pids;
  int numframes;
  if(argptr(0, (char**)(&frames), sizeof(*frames)) < 0)
8010500f:	6a 04                	push   $0x4
80105011:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105014:	50                   	push   %eax
80105015:	6a 00                	push   $0x0
80105017:	e8 d3 f1 ff ff       	call   801041ef <argptr>
8010501c:	83 c4 10             	add    $0x10,%esp
8010501f:	85 c0                	test   %eax,%eax
80105021:	78 42                	js     80105065 <sys_dump_physmem+0x5c>
    return -1;
  if(argptr(1, (char**)(&pids), sizeof(*pids)) < 0)
80105023:	83 ec 04             	sub    $0x4,%esp
80105026:	6a 04                	push   $0x4
80105028:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010502b:	50                   	push   %eax
8010502c:	6a 01                	push   $0x1
8010502e:	e8 bc f1 ff ff       	call   801041ef <argptr>
80105033:	83 c4 10             	add    $0x10,%esp
80105036:	85 c0                	test   %eax,%eax
80105038:	78 32                	js     8010506c <sys_dump_physmem+0x63>
    return -1;
  if(argint(2, &numframes) < 0)
8010503a:	83 ec 08             	sub    $0x8,%esp
8010503d:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105040:	50                   	push   %eax
80105041:	6a 02                	push   $0x2
80105043:	e8 7f f1 ff ff       	call   801041c7 <argint>
80105048:	83 c4 10             	add    $0x10,%esp
8010504b:	85 c0                	test   %eax,%eax
8010504d:	78 24                	js     80105073 <sys_dump_physmem+0x6a>
    return -1;

  return dump_physmem(frames, pids, numframes);
8010504f:	83 ec 04             	sub    $0x4,%esp
80105052:	ff 75 ec             	pushl  -0x14(%ebp)
80105055:	ff 75 f0             	pushl  -0x10(%ebp)
80105058:	ff 75 f4             	pushl  -0xc(%ebp)
8010505b:	e8 3c d3 ff ff       	call   8010239c <dump_physmem>
80105060:	83 c4 10             	add    $0x10,%esp
80105063:	c9                   	leave  
80105064:	c3                   	ret    
    return -1;
80105065:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010506a:	eb f7                	jmp    80105063 <sys_dump_physmem+0x5a>
    return -1;
8010506c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105071:	eb f0                	jmp    80105063 <sys_dump_physmem+0x5a>
    return -1;
80105073:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105078:	eb e9                	jmp    80105063 <sys_dump_physmem+0x5a>

8010507a <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
8010507a:	1e                   	push   %ds
  pushl %es
8010507b:	06                   	push   %es
  pushl %fs
8010507c:	0f a0                	push   %fs
  pushl %gs
8010507e:	0f a8                	push   %gs
  pushal
80105080:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80105081:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80105085:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80105087:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80105089:	54                   	push   %esp
  call trap
8010508a:	e8 e3 00 00 00       	call   80105172 <trap>
  addl $4, %esp
8010508f:	83 c4 04             	add    $0x4,%esp

80105092 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80105092:	61                   	popa   
  popl %gs
80105093:	0f a9                	pop    %gs
  popl %fs
80105095:	0f a1                	pop    %fs
  popl %es
80105097:	07                   	pop    %es
  popl %ds
80105098:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80105099:	83 c4 08             	add    $0x8,%esp
  iret
8010509c:	cf                   	iret   

8010509d <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
8010509d:	55                   	push   %ebp
8010509e:	89 e5                	mov    %esp,%ebp
801050a0:	83 ec 08             	sub    $0x8,%esp
  int i;

  for(i = 0; i < 256; i++)
801050a3:	b8 00 00 00 00       	mov    $0x0,%eax
801050a8:	eb 4a                	jmp    801050f4 <tvinit+0x57>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801050aa:	8b 0c 85 08 a0 10 80 	mov    -0x7fef5ff8(,%eax,4),%ecx
801050b1:	66 89 0c c5 a0 69 14 	mov    %cx,-0x7feb9660(,%eax,8)
801050b8:	80 
801050b9:	66 c7 04 c5 a2 69 14 	movw   $0x8,-0x7feb965e(,%eax,8)
801050c0:	80 08 00 
801050c3:	c6 04 c5 a4 69 14 80 	movb   $0x0,-0x7feb965c(,%eax,8)
801050ca:	00 
801050cb:	0f b6 14 c5 a5 69 14 	movzbl -0x7feb965b(,%eax,8),%edx
801050d2:	80 
801050d3:	83 e2 f0             	and    $0xfffffff0,%edx
801050d6:	83 ca 0e             	or     $0xe,%edx
801050d9:	83 e2 8f             	and    $0xffffff8f,%edx
801050dc:	83 ca 80             	or     $0xffffff80,%edx
801050df:	88 14 c5 a5 69 14 80 	mov    %dl,-0x7feb965b(,%eax,8)
801050e6:	c1 e9 10             	shr    $0x10,%ecx
801050e9:	66 89 0c c5 a6 69 14 	mov    %cx,-0x7feb965a(,%eax,8)
801050f0:	80 
  for(i = 0; i < 256; i++)
801050f1:	83 c0 01             	add    $0x1,%eax
801050f4:	3d ff 00 00 00       	cmp    $0xff,%eax
801050f9:	7e af                	jle    801050aa <tvinit+0xd>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
801050fb:	8b 15 08 a1 10 80    	mov    0x8010a108,%edx
80105101:	66 89 15 a0 6b 14 80 	mov    %dx,0x80146ba0
80105108:	66 c7 05 a2 6b 14 80 	movw   $0x8,0x80146ba2
8010510f:	08 00 
80105111:	c6 05 a4 6b 14 80 00 	movb   $0x0,0x80146ba4
80105118:	0f b6 05 a5 6b 14 80 	movzbl 0x80146ba5,%eax
8010511f:	83 c8 0f             	or     $0xf,%eax
80105122:	83 e0 ef             	and    $0xffffffef,%eax
80105125:	83 c8 e0             	or     $0xffffffe0,%eax
80105128:	a2 a5 6b 14 80       	mov    %al,0x80146ba5
8010512d:	c1 ea 10             	shr    $0x10,%edx
80105130:	66 89 15 a6 6b 14 80 	mov    %dx,0x80146ba6

  initlock(&tickslock, "time");
80105137:	83 ec 08             	sub    $0x8,%esp
8010513a:	68 7d 6f 10 80       	push   $0x80106f7d
8010513f:	68 60 69 14 80       	push   $0x80146960
80105144:	e8 4b ec ff ff       	call   80103d94 <initlock>
}
80105149:	83 c4 10             	add    $0x10,%esp
8010514c:	c9                   	leave  
8010514d:	c3                   	ret    

8010514e <idtinit>:

void
idtinit(void)
{
8010514e:	55                   	push   %ebp
8010514f:	89 e5                	mov    %esp,%ebp
80105151:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80105154:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
8010515a:	b8 a0 69 14 80       	mov    $0x801469a0,%eax
8010515f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80105163:	c1 e8 10             	shr    $0x10,%eax
80105166:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
8010516a:	8d 45 fa             	lea    -0x6(%ebp),%eax
8010516d:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80105170:	c9                   	leave  
80105171:	c3                   	ret    

80105172 <trap>:

void
trap(struct trapframe *tf)
{
80105172:	55                   	push   %ebp
80105173:	89 e5                	mov    %esp,%ebp
80105175:	57                   	push   %edi
80105176:	56                   	push   %esi
80105177:	53                   	push   %ebx
80105178:	83 ec 1c             	sub    $0x1c,%esp
8010517b:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
8010517e:	8b 43 30             	mov    0x30(%ebx),%eax
80105181:	83 f8 40             	cmp    $0x40,%eax
80105184:	74 13                	je     80105199 <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
80105186:	83 e8 20             	sub    $0x20,%eax
80105189:	83 f8 1f             	cmp    $0x1f,%eax
8010518c:	0f 87 3a 01 00 00    	ja     801052cc <trap+0x15a>
80105192:	ff 24 85 24 70 10 80 	jmp    *-0x7fef8fdc(,%eax,4)
    if(myproc()->killed)
80105199:	e8 90 e3 ff ff       	call   8010352e <myproc>
8010519e:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801051a2:	75 1f                	jne    801051c3 <trap+0x51>
    myproc()->tf = tf;
801051a4:	e8 85 e3 ff ff       	call   8010352e <myproc>
801051a9:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
801051ac:	e8 d9 f0 ff ff       	call   8010428a <syscall>
    if(myproc()->killed)
801051b1:	e8 78 e3 ff ff       	call   8010352e <myproc>
801051b6:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801051ba:	74 7e                	je     8010523a <trap+0xc8>
      exit();
801051bc:	e8 1c e7 ff ff       	call   801038dd <exit>
801051c1:	eb 77                	jmp    8010523a <trap+0xc8>
      exit();
801051c3:	e8 15 e7 ff ff       	call   801038dd <exit>
801051c8:	eb da                	jmp    801051a4 <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
801051ca:	e8 44 e3 ff ff       	call   80103513 <cpuid>
801051cf:	85 c0                	test   %eax,%eax
801051d1:	74 6f                	je     80105242 <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
801051d3:	e8 e6 d4 ff ff       	call   801026be <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
801051d8:	e8 51 e3 ff ff       	call   8010352e <myproc>
801051dd:	85 c0                	test   %eax,%eax
801051df:	74 1c                	je     801051fd <trap+0x8b>
801051e1:	e8 48 e3 ff ff       	call   8010352e <myproc>
801051e6:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801051ea:	74 11                	je     801051fd <trap+0x8b>
801051ec:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
801051f0:	83 e0 03             	and    $0x3,%eax
801051f3:	66 83 f8 03          	cmp    $0x3,%ax
801051f7:	0f 84 62 01 00 00    	je     8010535f <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
801051fd:	e8 2c e3 ff ff       	call   8010352e <myproc>
80105202:	85 c0                	test   %eax,%eax
80105204:	74 0f                	je     80105215 <trap+0xa3>
80105206:	e8 23 e3 ff ff       	call   8010352e <myproc>
8010520b:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
8010520f:	0f 84 54 01 00 00    	je     80105369 <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105215:	e8 14 e3 ff ff       	call   8010352e <myproc>
8010521a:	85 c0                	test   %eax,%eax
8010521c:	74 1c                	je     8010523a <trap+0xc8>
8010521e:	e8 0b e3 ff ff       	call   8010352e <myproc>
80105223:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105227:	74 11                	je     8010523a <trap+0xc8>
80105229:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
8010522d:	83 e0 03             	and    $0x3,%eax
80105230:	66 83 f8 03          	cmp    $0x3,%ax
80105234:	0f 84 43 01 00 00    	je     8010537d <trap+0x20b>
    exit();
}
8010523a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010523d:	5b                   	pop    %ebx
8010523e:	5e                   	pop    %esi
8010523f:	5f                   	pop    %edi
80105240:	5d                   	pop    %ebp
80105241:	c3                   	ret    
      acquire(&tickslock);
80105242:	83 ec 0c             	sub    $0xc,%esp
80105245:	68 60 69 14 80       	push   $0x80146960
8010524a:	e8 81 ec ff ff       	call   80103ed0 <acquire>
      ticks++;
8010524f:	83 05 a0 71 14 80 01 	addl   $0x1,0x801471a0
      wakeup(&ticks);
80105256:	c7 04 24 a0 71 14 80 	movl   $0x801471a0,(%esp)
8010525d:	e8 d8 e8 ff ff       	call   80103b3a <wakeup>
      release(&tickslock);
80105262:	c7 04 24 60 69 14 80 	movl   $0x80146960,(%esp)
80105269:	e8 c7 ec ff ff       	call   80103f35 <release>
8010526e:	83 c4 10             	add    $0x10,%esp
80105271:	e9 5d ff ff ff       	jmp    801051d3 <trap+0x61>
    ideintr();
80105276:	e8 04 cb ff ff       	call   80101d7f <ideintr>
    lapiceoi();
8010527b:	e8 3e d4 ff ff       	call   801026be <lapiceoi>
    break;
80105280:	e9 53 ff ff ff       	jmp    801051d8 <trap+0x66>
    kbdintr();
80105285:	e8 78 d2 ff ff       	call   80102502 <kbdintr>
    lapiceoi();
8010528a:	e8 2f d4 ff ff       	call   801026be <lapiceoi>
    break;
8010528f:	e9 44 ff ff ff       	jmp    801051d8 <trap+0x66>
    uartintr();
80105294:	e8 05 02 00 00       	call   8010549e <uartintr>
    lapiceoi();
80105299:	e8 20 d4 ff ff       	call   801026be <lapiceoi>
    break;
8010529e:	e9 35 ff ff ff       	jmp    801051d8 <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801052a3:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
801052a6:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801052aa:	e8 64 e2 ff ff       	call   80103513 <cpuid>
801052af:	57                   	push   %edi
801052b0:	0f b7 f6             	movzwl %si,%esi
801052b3:	56                   	push   %esi
801052b4:	50                   	push   %eax
801052b5:	68 88 6f 10 80       	push   $0x80106f88
801052ba:	e8 4c b3 ff ff       	call   8010060b <cprintf>
    lapiceoi();
801052bf:	e8 fa d3 ff ff       	call   801026be <lapiceoi>
    break;
801052c4:	83 c4 10             	add    $0x10,%esp
801052c7:	e9 0c ff ff ff       	jmp    801051d8 <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
801052cc:	e8 5d e2 ff ff       	call   8010352e <myproc>
801052d1:	85 c0                	test   %eax,%eax
801052d3:	74 5f                	je     80105334 <trap+0x1c2>
801052d5:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
801052d9:	74 59                	je     80105334 <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801052db:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801052de:	8b 43 38             	mov    0x38(%ebx),%eax
801052e1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801052e4:	e8 2a e2 ff ff       	call   80103513 <cpuid>
801052e9:	89 45 e0             	mov    %eax,-0x20(%ebp)
801052ec:	8b 53 34             	mov    0x34(%ebx),%edx
801052ef:	89 55 dc             	mov    %edx,-0x24(%ebp)
801052f2:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
801052f5:	e8 34 e2 ff ff       	call   8010352e <myproc>
801052fa:	8d 48 6c             	lea    0x6c(%eax),%ecx
801052fd:	89 4d d8             	mov    %ecx,-0x28(%ebp)
80105300:	e8 29 e2 ff ff       	call   8010352e <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105305:	57                   	push   %edi
80105306:	ff 75 e4             	pushl  -0x1c(%ebp)
80105309:	ff 75 e0             	pushl  -0x20(%ebp)
8010530c:	ff 75 dc             	pushl  -0x24(%ebp)
8010530f:	56                   	push   %esi
80105310:	ff 75 d8             	pushl  -0x28(%ebp)
80105313:	ff 70 10             	pushl  0x10(%eax)
80105316:	68 e0 6f 10 80       	push   $0x80106fe0
8010531b:	e8 eb b2 ff ff       	call   8010060b <cprintf>
    myproc()->killed = 1;
80105320:	83 c4 20             	add    $0x20,%esp
80105323:	e8 06 e2 ff ff       	call   8010352e <myproc>
80105328:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
8010532f:	e9 a4 fe ff ff       	jmp    801051d8 <trap+0x66>
80105334:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80105337:	8b 73 38             	mov    0x38(%ebx),%esi
8010533a:	e8 d4 e1 ff ff       	call   80103513 <cpuid>
8010533f:	83 ec 0c             	sub    $0xc,%esp
80105342:	57                   	push   %edi
80105343:	56                   	push   %esi
80105344:	50                   	push   %eax
80105345:	ff 73 30             	pushl  0x30(%ebx)
80105348:	68 ac 6f 10 80       	push   $0x80106fac
8010534d:	e8 b9 b2 ff ff       	call   8010060b <cprintf>
      panic("trap");
80105352:	83 c4 14             	add    $0x14,%esp
80105355:	68 82 6f 10 80       	push   $0x80106f82
8010535a:	e8 e9 af ff ff       	call   80100348 <panic>
    exit();
8010535f:	e8 79 e5 ff ff       	call   801038dd <exit>
80105364:	e9 94 fe ff ff       	jmp    801051fd <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
80105369:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
8010536d:	0f 85 a2 fe ff ff    	jne    80105215 <trap+0xa3>
    yield();
80105373:	e8 2b e6 ff ff       	call   801039a3 <yield>
80105378:	e9 98 fe ff ff       	jmp    80105215 <trap+0xa3>
    exit();
8010537d:	e8 5b e5 ff ff       	call   801038dd <exit>
80105382:	e9 b3 fe ff ff       	jmp    8010523a <trap+0xc8>

80105387 <uartgetc>:
  outb(COM1+0, c);
}

static int
uartgetc(void)
{
80105387:	55                   	push   %ebp
80105388:	89 e5                	mov    %esp,%ebp
  if(!uart)
8010538a:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
80105391:	74 15                	je     801053a8 <uartgetc+0x21>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105393:	ba fd 03 00 00       	mov    $0x3fd,%edx
80105398:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
80105399:	a8 01                	test   $0x1,%al
8010539b:	74 12                	je     801053af <uartgetc+0x28>
8010539d:	ba f8 03 00 00       	mov    $0x3f8,%edx
801053a2:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
801053a3:	0f b6 c0             	movzbl %al,%eax
}
801053a6:	5d                   	pop    %ebp
801053a7:	c3                   	ret    
    return -1;
801053a8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801053ad:	eb f7                	jmp    801053a6 <uartgetc+0x1f>
    return -1;
801053af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801053b4:	eb f0                	jmp    801053a6 <uartgetc+0x1f>

801053b6 <uartputc>:
  if(!uart)
801053b6:	83 3d bc a5 10 80 00 	cmpl   $0x0,0x8010a5bc
801053bd:	74 3b                	je     801053fa <uartputc+0x44>
{
801053bf:	55                   	push   %ebp
801053c0:	89 e5                	mov    %esp,%ebp
801053c2:	53                   	push   %ebx
801053c3:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801053c6:	bb 00 00 00 00       	mov    $0x0,%ebx
801053cb:	eb 10                	jmp    801053dd <uartputc+0x27>
    microdelay(10);
801053cd:	83 ec 0c             	sub    $0xc,%esp
801053d0:	6a 0a                	push   $0xa
801053d2:	e8 06 d3 ff ff       	call   801026dd <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801053d7:	83 c3 01             	add    $0x1,%ebx
801053da:	83 c4 10             	add    $0x10,%esp
801053dd:	83 fb 7f             	cmp    $0x7f,%ebx
801053e0:	7f 0a                	jg     801053ec <uartputc+0x36>
801053e2:	ba fd 03 00 00       	mov    $0x3fd,%edx
801053e7:	ec                   	in     (%dx),%al
801053e8:	a8 20                	test   $0x20,%al
801053ea:	74 e1                	je     801053cd <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801053ec:	8b 45 08             	mov    0x8(%ebp),%eax
801053ef:	ba f8 03 00 00       	mov    $0x3f8,%edx
801053f4:	ee                   	out    %al,(%dx)
}
801053f5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801053f8:	c9                   	leave  
801053f9:	c3                   	ret    
801053fa:	f3 c3                	repz ret 

801053fc <uartinit>:
{
801053fc:	55                   	push   %ebp
801053fd:	89 e5                	mov    %esp,%ebp
801053ff:	56                   	push   %esi
80105400:	53                   	push   %ebx
80105401:	b9 00 00 00 00       	mov    $0x0,%ecx
80105406:	ba fa 03 00 00       	mov    $0x3fa,%edx
8010540b:	89 c8                	mov    %ecx,%eax
8010540d:	ee                   	out    %al,(%dx)
8010540e:	be fb 03 00 00       	mov    $0x3fb,%esi
80105413:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
80105418:	89 f2                	mov    %esi,%edx
8010541a:	ee                   	out    %al,(%dx)
8010541b:	b8 0c 00 00 00       	mov    $0xc,%eax
80105420:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105425:	ee                   	out    %al,(%dx)
80105426:	bb f9 03 00 00       	mov    $0x3f9,%ebx
8010542b:	89 c8                	mov    %ecx,%eax
8010542d:	89 da                	mov    %ebx,%edx
8010542f:	ee                   	out    %al,(%dx)
80105430:	b8 03 00 00 00       	mov    $0x3,%eax
80105435:	89 f2                	mov    %esi,%edx
80105437:	ee                   	out    %al,(%dx)
80105438:	ba fc 03 00 00       	mov    $0x3fc,%edx
8010543d:	89 c8                	mov    %ecx,%eax
8010543f:	ee                   	out    %al,(%dx)
80105440:	b8 01 00 00 00       	mov    $0x1,%eax
80105445:	89 da                	mov    %ebx,%edx
80105447:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80105448:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010544d:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
8010544e:	3c ff                	cmp    $0xff,%al
80105450:	74 45                	je     80105497 <uartinit+0x9b>
  uart = 1;
80105452:	c7 05 bc a5 10 80 01 	movl   $0x1,0x8010a5bc
80105459:	00 00 00 
8010545c:	ba fa 03 00 00       	mov    $0x3fa,%edx
80105461:	ec                   	in     (%dx),%al
80105462:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105467:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
80105468:	83 ec 08             	sub    $0x8,%esp
8010546b:	6a 00                	push   $0x0
8010546d:	6a 04                	push   $0x4
8010546f:	e8 16 cb ff ff       	call   80101f8a <ioapicenable>
  for(p="xv6...\n"; *p; p++)
80105474:	83 c4 10             	add    $0x10,%esp
80105477:	bb a4 70 10 80       	mov    $0x801070a4,%ebx
8010547c:	eb 12                	jmp    80105490 <uartinit+0x94>
    uartputc(*p);
8010547e:	83 ec 0c             	sub    $0xc,%esp
80105481:	0f be c0             	movsbl %al,%eax
80105484:	50                   	push   %eax
80105485:	e8 2c ff ff ff       	call   801053b6 <uartputc>
  for(p="xv6...\n"; *p; p++)
8010548a:	83 c3 01             	add    $0x1,%ebx
8010548d:	83 c4 10             	add    $0x10,%esp
80105490:	0f b6 03             	movzbl (%ebx),%eax
80105493:	84 c0                	test   %al,%al
80105495:	75 e7                	jne    8010547e <uartinit+0x82>
}
80105497:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010549a:	5b                   	pop    %ebx
8010549b:	5e                   	pop    %esi
8010549c:	5d                   	pop    %ebp
8010549d:	c3                   	ret    

8010549e <uartintr>:

void
uartintr(void)
{
8010549e:	55                   	push   %ebp
8010549f:	89 e5                	mov    %esp,%ebp
801054a1:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
801054a4:	68 87 53 10 80       	push   $0x80105387
801054a9:	e8 90 b2 ff ff       	call   8010073e <consoleintr>
}
801054ae:	83 c4 10             	add    $0x10,%esp
801054b1:	c9                   	leave  
801054b2:	c3                   	ret    

801054b3 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801054b3:	6a 00                	push   $0x0
  pushl $0
801054b5:	6a 00                	push   $0x0
  jmp alltraps
801054b7:	e9 be fb ff ff       	jmp    8010507a <alltraps>

801054bc <vector1>:
.globl vector1
vector1:
  pushl $0
801054bc:	6a 00                	push   $0x0
  pushl $1
801054be:	6a 01                	push   $0x1
  jmp alltraps
801054c0:	e9 b5 fb ff ff       	jmp    8010507a <alltraps>

801054c5 <vector2>:
.globl vector2
vector2:
  pushl $0
801054c5:	6a 00                	push   $0x0
  pushl $2
801054c7:	6a 02                	push   $0x2
  jmp alltraps
801054c9:	e9 ac fb ff ff       	jmp    8010507a <alltraps>

801054ce <vector3>:
.globl vector3
vector3:
  pushl $0
801054ce:	6a 00                	push   $0x0
  pushl $3
801054d0:	6a 03                	push   $0x3
  jmp alltraps
801054d2:	e9 a3 fb ff ff       	jmp    8010507a <alltraps>

801054d7 <vector4>:
.globl vector4
vector4:
  pushl $0
801054d7:	6a 00                	push   $0x0
  pushl $4
801054d9:	6a 04                	push   $0x4
  jmp alltraps
801054db:	e9 9a fb ff ff       	jmp    8010507a <alltraps>

801054e0 <vector5>:
.globl vector5
vector5:
  pushl $0
801054e0:	6a 00                	push   $0x0
  pushl $5
801054e2:	6a 05                	push   $0x5
  jmp alltraps
801054e4:	e9 91 fb ff ff       	jmp    8010507a <alltraps>

801054e9 <vector6>:
.globl vector6
vector6:
  pushl $0
801054e9:	6a 00                	push   $0x0
  pushl $6
801054eb:	6a 06                	push   $0x6
  jmp alltraps
801054ed:	e9 88 fb ff ff       	jmp    8010507a <alltraps>

801054f2 <vector7>:
.globl vector7
vector7:
  pushl $0
801054f2:	6a 00                	push   $0x0
  pushl $7
801054f4:	6a 07                	push   $0x7
  jmp alltraps
801054f6:	e9 7f fb ff ff       	jmp    8010507a <alltraps>

801054fb <vector8>:
.globl vector8
vector8:
  pushl $8
801054fb:	6a 08                	push   $0x8
  jmp alltraps
801054fd:	e9 78 fb ff ff       	jmp    8010507a <alltraps>

80105502 <vector9>:
.globl vector9
vector9:
  pushl $0
80105502:	6a 00                	push   $0x0
  pushl $9
80105504:	6a 09                	push   $0x9
  jmp alltraps
80105506:	e9 6f fb ff ff       	jmp    8010507a <alltraps>

8010550b <vector10>:
.globl vector10
vector10:
  pushl $10
8010550b:	6a 0a                	push   $0xa
  jmp alltraps
8010550d:	e9 68 fb ff ff       	jmp    8010507a <alltraps>

80105512 <vector11>:
.globl vector11
vector11:
  pushl $11
80105512:	6a 0b                	push   $0xb
  jmp alltraps
80105514:	e9 61 fb ff ff       	jmp    8010507a <alltraps>

80105519 <vector12>:
.globl vector12
vector12:
  pushl $12
80105519:	6a 0c                	push   $0xc
  jmp alltraps
8010551b:	e9 5a fb ff ff       	jmp    8010507a <alltraps>

80105520 <vector13>:
.globl vector13
vector13:
  pushl $13
80105520:	6a 0d                	push   $0xd
  jmp alltraps
80105522:	e9 53 fb ff ff       	jmp    8010507a <alltraps>

80105527 <vector14>:
.globl vector14
vector14:
  pushl $14
80105527:	6a 0e                	push   $0xe
  jmp alltraps
80105529:	e9 4c fb ff ff       	jmp    8010507a <alltraps>

8010552e <vector15>:
.globl vector15
vector15:
  pushl $0
8010552e:	6a 00                	push   $0x0
  pushl $15
80105530:	6a 0f                	push   $0xf
  jmp alltraps
80105532:	e9 43 fb ff ff       	jmp    8010507a <alltraps>

80105537 <vector16>:
.globl vector16
vector16:
  pushl $0
80105537:	6a 00                	push   $0x0
  pushl $16
80105539:	6a 10                	push   $0x10
  jmp alltraps
8010553b:	e9 3a fb ff ff       	jmp    8010507a <alltraps>

80105540 <vector17>:
.globl vector17
vector17:
  pushl $17
80105540:	6a 11                	push   $0x11
  jmp alltraps
80105542:	e9 33 fb ff ff       	jmp    8010507a <alltraps>

80105547 <vector18>:
.globl vector18
vector18:
  pushl $0
80105547:	6a 00                	push   $0x0
  pushl $18
80105549:	6a 12                	push   $0x12
  jmp alltraps
8010554b:	e9 2a fb ff ff       	jmp    8010507a <alltraps>

80105550 <vector19>:
.globl vector19
vector19:
  pushl $0
80105550:	6a 00                	push   $0x0
  pushl $19
80105552:	6a 13                	push   $0x13
  jmp alltraps
80105554:	e9 21 fb ff ff       	jmp    8010507a <alltraps>

80105559 <vector20>:
.globl vector20
vector20:
  pushl $0
80105559:	6a 00                	push   $0x0
  pushl $20
8010555b:	6a 14                	push   $0x14
  jmp alltraps
8010555d:	e9 18 fb ff ff       	jmp    8010507a <alltraps>

80105562 <vector21>:
.globl vector21
vector21:
  pushl $0
80105562:	6a 00                	push   $0x0
  pushl $21
80105564:	6a 15                	push   $0x15
  jmp alltraps
80105566:	e9 0f fb ff ff       	jmp    8010507a <alltraps>

8010556b <vector22>:
.globl vector22
vector22:
  pushl $0
8010556b:	6a 00                	push   $0x0
  pushl $22
8010556d:	6a 16                	push   $0x16
  jmp alltraps
8010556f:	e9 06 fb ff ff       	jmp    8010507a <alltraps>

80105574 <vector23>:
.globl vector23
vector23:
  pushl $0
80105574:	6a 00                	push   $0x0
  pushl $23
80105576:	6a 17                	push   $0x17
  jmp alltraps
80105578:	e9 fd fa ff ff       	jmp    8010507a <alltraps>

8010557d <vector24>:
.globl vector24
vector24:
  pushl $0
8010557d:	6a 00                	push   $0x0
  pushl $24
8010557f:	6a 18                	push   $0x18
  jmp alltraps
80105581:	e9 f4 fa ff ff       	jmp    8010507a <alltraps>

80105586 <vector25>:
.globl vector25
vector25:
  pushl $0
80105586:	6a 00                	push   $0x0
  pushl $25
80105588:	6a 19                	push   $0x19
  jmp alltraps
8010558a:	e9 eb fa ff ff       	jmp    8010507a <alltraps>

8010558f <vector26>:
.globl vector26
vector26:
  pushl $0
8010558f:	6a 00                	push   $0x0
  pushl $26
80105591:	6a 1a                	push   $0x1a
  jmp alltraps
80105593:	e9 e2 fa ff ff       	jmp    8010507a <alltraps>

80105598 <vector27>:
.globl vector27
vector27:
  pushl $0
80105598:	6a 00                	push   $0x0
  pushl $27
8010559a:	6a 1b                	push   $0x1b
  jmp alltraps
8010559c:	e9 d9 fa ff ff       	jmp    8010507a <alltraps>

801055a1 <vector28>:
.globl vector28
vector28:
  pushl $0
801055a1:	6a 00                	push   $0x0
  pushl $28
801055a3:	6a 1c                	push   $0x1c
  jmp alltraps
801055a5:	e9 d0 fa ff ff       	jmp    8010507a <alltraps>

801055aa <vector29>:
.globl vector29
vector29:
  pushl $0
801055aa:	6a 00                	push   $0x0
  pushl $29
801055ac:	6a 1d                	push   $0x1d
  jmp alltraps
801055ae:	e9 c7 fa ff ff       	jmp    8010507a <alltraps>

801055b3 <vector30>:
.globl vector30
vector30:
  pushl $0
801055b3:	6a 00                	push   $0x0
  pushl $30
801055b5:	6a 1e                	push   $0x1e
  jmp alltraps
801055b7:	e9 be fa ff ff       	jmp    8010507a <alltraps>

801055bc <vector31>:
.globl vector31
vector31:
  pushl $0
801055bc:	6a 00                	push   $0x0
  pushl $31
801055be:	6a 1f                	push   $0x1f
  jmp alltraps
801055c0:	e9 b5 fa ff ff       	jmp    8010507a <alltraps>

801055c5 <vector32>:
.globl vector32
vector32:
  pushl $0
801055c5:	6a 00                	push   $0x0
  pushl $32
801055c7:	6a 20                	push   $0x20
  jmp alltraps
801055c9:	e9 ac fa ff ff       	jmp    8010507a <alltraps>

801055ce <vector33>:
.globl vector33
vector33:
  pushl $0
801055ce:	6a 00                	push   $0x0
  pushl $33
801055d0:	6a 21                	push   $0x21
  jmp alltraps
801055d2:	e9 a3 fa ff ff       	jmp    8010507a <alltraps>

801055d7 <vector34>:
.globl vector34
vector34:
  pushl $0
801055d7:	6a 00                	push   $0x0
  pushl $34
801055d9:	6a 22                	push   $0x22
  jmp alltraps
801055db:	e9 9a fa ff ff       	jmp    8010507a <alltraps>

801055e0 <vector35>:
.globl vector35
vector35:
  pushl $0
801055e0:	6a 00                	push   $0x0
  pushl $35
801055e2:	6a 23                	push   $0x23
  jmp alltraps
801055e4:	e9 91 fa ff ff       	jmp    8010507a <alltraps>

801055e9 <vector36>:
.globl vector36
vector36:
  pushl $0
801055e9:	6a 00                	push   $0x0
  pushl $36
801055eb:	6a 24                	push   $0x24
  jmp alltraps
801055ed:	e9 88 fa ff ff       	jmp    8010507a <alltraps>

801055f2 <vector37>:
.globl vector37
vector37:
  pushl $0
801055f2:	6a 00                	push   $0x0
  pushl $37
801055f4:	6a 25                	push   $0x25
  jmp alltraps
801055f6:	e9 7f fa ff ff       	jmp    8010507a <alltraps>

801055fb <vector38>:
.globl vector38
vector38:
  pushl $0
801055fb:	6a 00                	push   $0x0
  pushl $38
801055fd:	6a 26                	push   $0x26
  jmp alltraps
801055ff:	e9 76 fa ff ff       	jmp    8010507a <alltraps>

80105604 <vector39>:
.globl vector39
vector39:
  pushl $0
80105604:	6a 00                	push   $0x0
  pushl $39
80105606:	6a 27                	push   $0x27
  jmp alltraps
80105608:	e9 6d fa ff ff       	jmp    8010507a <alltraps>

8010560d <vector40>:
.globl vector40
vector40:
  pushl $0
8010560d:	6a 00                	push   $0x0
  pushl $40
8010560f:	6a 28                	push   $0x28
  jmp alltraps
80105611:	e9 64 fa ff ff       	jmp    8010507a <alltraps>

80105616 <vector41>:
.globl vector41
vector41:
  pushl $0
80105616:	6a 00                	push   $0x0
  pushl $41
80105618:	6a 29                	push   $0x29
  jmp alltraps
8010561a:	e9 5b fa ff ff       	jmp    8010507a <alltraps>

8010561f <vector42>:
.globl vector42
vector42:
  pushl $0
8010561f:	6a 00                	push   $0x0
  pushl $42
80105621:	6a 2a                	push   $0x2a
  jmp alltraps
80105623:	e9 52 fa ff ff       	jmp    8010507a <alltraps>

80105628 <vector43>:
.globl vector43
vector43:
  pushl $0
80105628:	6a 00                	push   $0x0
  pushl $43
8010562a:	6a 2b                	push   $0x2b
  jmp alltraps
8010562c:	e9 49 fa ff ff       	jmp    8010507a <alltraps>

80105631 <vector44>:
.globl vector44
vector44:
  pushl $0
80105631:	6a 00                	push   $0x0
  pushl $44
80105633:	6a 2c                	push   $0x2c
  jmp alltraps
80105635:	e9 40 fa ff ff       	jmp    8010507a <alltraps>

8010563a <vector45>:
.globl vector45
vector45:
  pushl $0
8010563a:	6a 00                	push   $0x0
  pushl $45
8010563c:	6a 2d                	push   $0x2d
  jmp alltraps
8010563e:	e9 37 fa ff ff       	jmp    8010507a <alltraps>

80105643 <vector46>:
.globl vector46
vector46:
  pushl $0
80105643:	6a 00                	push   $0x0
  pushl $46
80105645:	6a 2e                	push   $0x2e
  jmp alltraps
80105647:	e9 2e fa ff ff       	jmp    8010507a <alltraps>

8010564c <vector47>:
.globl vector47
vector47:
  pushl $0
8010564c:	6a 00                	push   $0x0
  pushl $47
8010564e:	6a 2f                	push   $0x2f
  jmp alltraps
80105650:	e9 25 fa ff ff       	jmp    8010507a <alltraps>

80105655 <vector48>:
.globl vector48
vector48:
  pushl $0
80105655:	6a 00                	push   $0x0
  pushl $48
80105657:	6a 30                	push   $0x30
  jmp alltraps
80105659:	e9 1c fa ff ff       	jmp    8010507a <alltraps>

8010565e <vector49>:
.globl vector49
vector49:
  pushl $0
8010565e:	6a 00                	push   $0x0
  pushl $49
80105660:	6a 31                	push   $0x31
  jmp alltraps
80105662:	e9 13 fa ff ff       	jmp    8010507a <alltraps>

80105667 <vector50>:
.globl vector50
vector50:
  pushl $0
80105667:	6a 00                	push   $0x0
  pushl $50
80105669:	6a 32                	push   $0x32
  jmp alltraps
8010566b:	e9 0a fa ff ff       	jmp    8010507a <alltraps>

80105670 <vector51>:
.globl vector51
vector51:
  pushl $0
80105670:	6a 00                	push   $0x0
  pushl $51
80105672:	6a 33                	push   $0x33
  jmp alltraps
80105674:	e9 01 fa ff ff       	jmp    8010507a <alltraps>

80105679 <vector52>:
.globl vector52
vector52:
  pushl $0
80105679:	6a 00                	push   $0x0
  pushl $52
8010567b:	6a 34                	push   $0x34
  jmp alltraps
8010567d:	e9 f8 f9 ff ff       	jmp    8010507a <alltraps>

80105682 <vector53>:
.globl vector53
vector53:
  pushl $0
80105682:	6a 00                	push   $0x0
  pushl $53
80105684:	6a 35                	push   $0x35
  jmp alltraps
80105686:	e9 ef f9 ff ff       	jmp    8010507a <alltraps>

8010568b <vector54>:
.globl vector54
vector54:
  pushl $0
8010568b:	6a 00                	push   $0x0
  pushl $54
8010568d:	6a 36                	push   $0x36
  jmp alltraps
8010568f:	e9 e6 f9 ff ff       	jmp    8010507a <alltraps>

80105694 <vector55>:
.globl vector55
vector55:
  pushl $0
80105694:	6a 00                	push   $0x0
  pushl $55
80105696:	6a 37                	push   $0x37
  jmp alltraps
80105698:	e9 dd f9 ff ff       	jmp    8010507a <alltraps>

8010569d <vector56>:
.globl vector56
vector56:
  pushl $0
8010569d:	6a 00                	push   $0x0
  pushl $56
8010569f:	6a 38                	push   $0x38
  jmp alltraps
801056a1:	e9 d4 f9 ff ff       	jmp    8010507a <alltraps>

801056a6 <vector57>:
.globl vector57
vector57:
  pushl $0
801056a6:	6a 00                	push   $0x0
  pushl $57
801056a8:	6a 39                	push   $0x39
  jmp alltraps
801056aa:	e9 cb f9 ff ff       	jmp    8010507a <alltraps>

801056af <vector58>:
.globl vector58
vector58:
  pushl $0
801056af:	6a 00                	push   $0x0
  pushl $58
801056b1:	6a 3a                	push   $0x3a
  jmp alltraps
801056b3:	e9 c2 f9 ff ff       	jmp    8010507a <alltraps>

801056b8 <vector59>:
.globl vector59
vector59:
  pushl $0
801056b8:	6a 00                	push   $0x0
  pushl $59
801056ba:	6a 3b                	push   $0x3b
  jmp alltraps
801056bc:	e9 b9 f9 ff ff       	jmp    8010507a <alltraps>

801056c1 <vector60>:
.globl vector60
vector60:
  pushl $0
801056c1:	6a 00                	push   $0x0
  pushl $60
801056c3:	6a 3c                	push   $0x3c
  jmp alltraps
801056c5:	e9 b0 f9 ff ff       	jmp    8010507a <alltraps>

801056ca <vector61>:
.globl vector61
vector61:
  pushl $0
801056ca:	6a 00                	push   $0x0
  pushl $61
801056cc:	6a 3d                	push   $0x3d
  jmp alltraps
801056ce:	e9 a7 f9 ff ff       	jmp    8010507a <alltraps>

801056d3 <vector62>:
.globl vector62
vector62:
  pushl $0
801056d3:	6a 00                	push   $0x0
  pushl $62
801056d5:	6a 3e                	push   $0x3e
  jmp alltraps
801056d7:	e9 9e f9 ff ff       	jmp    8010507a <alltraps>

801056dc <vector63>:
.globl vector63
vector63:
  pushl $0
801056dc:	6a 00                	push   $0x0
  pushl $63
801056de:	6a 3f                	push   $0x3f
  jmp alltraps
801056e0:	e9 95 f9 ff ff       	jmp    8010507a <alltraps>

801056e5 <vector64>:
.globl vector64
vector64:
  pushl $0
801056e5:	6a 00                	push   $0x0
  pushl $64
801056e7:	6a 40                	push   $0x40
  jmp alltraps
801056e9:	e9 8c f9 ff ff       	jmp    8010507a <alltraps>

801056ee <vector65>:
.globl vector65
vector65:
  pushl $0
801056ee:	6a 00                	push   $0x0
  pushl $65
801056f0:	6a 41                	push   $0x41
  jmp alltraps
801056f2:	e9 83 f9 ff ff       	jmp    8010507a <alltraps>

801056f7 <vector66>:
.globl vector66
vector66:
  pushl $0
801056f7:	6a 00                	push   $0x0
  pushl $66
801056f9:	6a 42                	push   $0x42
  jmp alltraps
801056fb:	e9 7a f9 ff ff       	jmp    8010507a <alltraps>

80105700 <vector67>:
.globl vector67
vector67:
  pushl $0
80105700:	6a 00                	push   $0x0
  pushl $67
80105702:	6a 43                	push   $0x43
  jmp alltraps
80105704:	e9 71 f9 ff ff       	jmp    8010507a <alltraps>

80105709 <vector68>:
.globl vector68
vector68:
  pushl $0
80105709:	6a 00                	push   $0x0
  pushl $68
8010570b:	6a 44                	push   $0x44
  jmp alltraps
8010570d:	e9 68 f9 ff ff       	jmp    8010507a <alltraps>

80105712 <vector69>:
.globl vector69
vector69:
  pushl $0
80105712:	6a 00                	push   $0x0
  pushl $69
80105714:	6a 45                	push   $0x45
  jmp alltraps
80105716:	e9 5f f9 ff ff       	jmp    8010507a <alltraps>

8010571b <vector70>:
.globl vector70
vector70:
  pushl $0
8010571b:	6a 00                	push   $0x0
  pushl $70
8010571d:	6a 46                	push   $0x46
  jmp alltraps
8010571f:	e9 56 f9 ff ff       	jmp    8010507a <alltraps>

80105724 <vector71>:
.globl vector71
vector71:
  pushl $0
80105724:	6a 00                	push   $0x0
  pushl $71
80105726:	6a 47                	push   $0x47
  jmp alltraps
80105728:	e9 4d f9 ff ff       	jmp    8010507a <alltraps>

8010572d <vector72>:
.globl vector72
vector72:
  pushl $0
8010572d:	6a 00                	push   $0x0
  pushl $72
8010572f:	6a 48                	push   $0x48
  jmp alltraps
80105731:	e9 44 f9 ff ff       	jmp    8010507a <alltraps>

80105736 <vector73>:
.globl vector73
vector73:
  pushl $0
80105736:	6a 00                	push   $0x0
  pushl $73
80105738:	6a 49                	push   $0x49
  jmp alltraps
8010573a:	e9 3b f9 ff ff       	jmp    8010507a <alltraps>

8010573f <vector74>:
.globl vector74
vector74:
  pushl $0
8010573f:	6a 00                	push   $0x0
  pushl $74
80105741:	6a 4a                	push   $0x4a
  jmp alltraps
80105743:	e9 32 f9 ff ff       	jmp    8010507a <alltraps>

80105748 <vector75>:
.globl vector75
vector75:
  pushl $0
80105748:	6a 00                	push   $0x0
  pushl $75
8010574a:	6a 4b                	push   $0x4b
  jmp alltraps
8010574c:	e9 29 f9 ff ff       	jmp    8010507a <alltraps>

80105751 <vector76>:
.globl vector76
vector76:
  pushl $0
80105751:	6a 00                	push   $0x0
  pushl $76
80105753:	6a 4c                	push   $0x4c
  jmp alltraps
80105755:	e9 20 f9 ff ff       	jmp    8010507a <alltraps>

8010575a <vector77>:
.globl vector77
vector77:
  pushl $0
8010575a:	6a 00                	push   $0x0
  pushl $77
8010575c:	6a 4d                	push   $0x4d
  jmp alltraps
8010575e:	e9 17 f9 ff ff       	jmp    8010507a <alltraps>

80105763 <vector78>:
.globl vector78
vector78:
  pushl $0
80105763:	6a 00                	push   $0x0
  pushl $78
80105765:	6a 4e                	push   $0x4e
  jmp alltraps
80105767:	e9 0e f9 ff ff       	jmp    8010507a <alltraps>

8010576c <vector79>:
.globl vector79
vector79:
  pushl $0
8010576c:	6a 00                	push   $0x0
  pushl $79
8010576e:	6a 4f                	push   $0x4f
  jmp alltraps
80105770:	e9 05 f9 ff ff       	jmp    8010507a <alltraps>

80105775 <vector80>:
.globl vector80
vector80:
  pushl $0
80105775:	6a 00                	push   $0x0
  pushl $80
80105777:	6a 50                	push   $0x50
  jmp alltraps
80105779:	e9 fc f8 ff ff       	jmp    8010507a <alltraps>

8010577e <vector81>:
.globl vector81
vector81:
  pushl $0
8010577e:	6a 00                	push   $0x0
  pushl $81
80105780:	6a 51                	push   $0x51
  jmp alltraps
80105782:	e9 f3 f8 ff ff       	jmp    8010507a <alltraps>

80105787 <vector82>:
.globl vector82
vector82:
  pushl $0
80105787:	6a 00                	push   $0x0
  pushl $82
80105789:	6a 52                	push   $0x52
  jmp alltraps
8010578b:	e9 ea f8 ff ff       	jmp    8010507a <alltraps>

80105790 <vector83>:
.globl vector83
vector83:
  pushl $0
80105790:	6a 00                	push   $0x0
  pushl $83
80105792:	6a 53                	push   $0x53
  jmp alltraps
80105794:	e9 e1 f8 ff ff       	jmp    8010507a <alltraps>

80105799 <vector84>:
.globl vector84
vector84:
  pushl $0
80105799:	6a 00                	push   $0x0
  pushl $84
8010579b:	6a 54                	push   $0x54
  jmp alltraps
8010579d:	e9 d8 f8 ff ff       	jmp    8010507a <alltraps>

801057a2 <vector85>:
.globl vector85
vector85:
  pushl $0
801057a2:	6a 00                	push   $0x0
  pushl $85
801057a4:	6a 55                	push   $0x55
  jmp alltraps
801057a6:	e9 cf f8 ff ff       	jmp    8010507a <alltraps>

801057ab <vector86>:
.globl vector86
vector86:
  pushl $0
801057ab:	6a 00                	push   $0x0
  pushl $86
801057ad:	6a 56                	push   $0x56
  jmp alltraps
801057af:	e9 c6 f8 ff ff       	jmp    8010507a <alltraps>

801057b4 <vector87>:
.globl vector87
vector87:
  pushl $0
801057b4:	6a 00                	push   $0x0
  pushl $87
801057b6:	6a 57                	push   $0x57
  jmp alltraps
801057b8:	e9 bd f8 ff ff       	jmp    8010507a <alltraps>

801057bd <vector88>:
.globl vector88
vector88:
  pushl $0
801057bd:	6a 00                	push   $0x0
  pushl $88
801057bf:	6a 58                	push   $0x58
  jmp alltraps
801057c1:	e9 b4 f8 ff ff       	jmp    8010507a <alltraps>

801057c6 <vector89>:
.globl vector89
vector89:
  pushl $0
801057c6:	6a 00                	push   $0x0
  pushl $89
801057c8:	6a 59                	push   $0x59
  jmp alltraps
801057ca:	e9 ab f8 ff ff       	jmp    8010507a <alltraps>

801057cf <vector90>:
.globl vector90
vector90:
  pushl $0
801057cf:	6a 00                	push   $0x0
  pushl $90
801057d1:	6a 5a                	push   $0x5a
  jmp alltraps
801057d3:	e9 a2 f8 ff ff       	jmp    8010507a <alltraps>

801057d8 <vector91>:
.globl vector91
vector91:
  pushl $0
801057d8:	6a 00                	push   $0x0
  pushl $91
801057da:	6a 5b                	push   $0x5b
  jmp alltraps
801057dc:	e9 99 f8 ff ff       	jmp    8010507a <alltraps>

801057e1 <vector92>:
.globl vector92
vector92:
  pushl $0
801057e1:	6a 00                	push   $0x0
  pushl $92
801057e3:	6a 5c                	push   $0x5c
  jmp alltraps
801057e5:	e9 90 f8 ff ff       	jmp    8010507a <alltraps>

801057ea <vector93>:
.globl vector93
vector93:
  pushl $0
801057ea:	6a 00                	push   $0x0
  pushl $93
801057ec:	6a 5d                	push   $0x5d
  jmp alltraps
801057ee:	e9 87 f8 ff ff       	jmp    8010507a <alltraps>

801057f3 <vector94>:
.globl vector94
vector94:
  pushl $0
801057f3:	6a 00                	push   $0x0
  pushl $94
801057f5:	6a 5e                	push   $0x5e
  jmp alltraps
801057f7:	e9 7e f8 ff ff       	jmp    8010507a <alltraps>

801057fc <vector95>:
.globl vector95
vector95:
  pushl $0
801057fc:	6a 00                	push   $0x0
  pushl $95
801057fe:	6a 5f                	push   $0x5f
  jmp alltraps
80105800:	e9 75 f8 ff ff       	jmp    8010507a <alltraps>

80105805 <vector96>:
.globl vector96
vector96:
  pushl $0
80105805:	6a 00                	push   $0x0
  pushl $96
80105807:	6a 60                	push   $0x60
  jmp alltraps
80105809:	e9 6c f8 ff ff       	jmp    8010507a <alltraps>

8010580e <vector97>:
.globl vector97
vector97:
  pushl $0
8010580e:	6a 00                	push   $0x0
  pushl $97
80105810:	6a 61                	push   $0x61
  jmp alltraps
80105812:	e9 63 f8 ff ff       	jmp    8010507a <alltraps>

80105817 <vector98>:
.globl vector98
vector98:
  pushl $0
80105817:	6a 00                	push   $0x0
  pushl $98
80105819:	6a 62                	push   $0x62
  jmp alltraps
8010581b:	e9 5a f8 ff ff       	jmp    8010507a <alltraps>

80105820 <vector99>:
.globl vector99
vector99:
  pushl $0
80105820:	6a 00                	push   $0x0
  pushl $99
80105822:	6a 63                	push   $0x63
  jmp alltraps
80105824:	e9 51 f8 ff ff       	jmp    8010507a <alltraps>

80105829 <vector100>:
.globl vector100
vector100:
  pushl $0
80105829:	6a 00                	push   $0x0
  pushl $100
8010582b:	6a 64                	push   $0x64
  jmp alltraps
8010582d:	e9 48 f8 ff ff       	jmp    8010507a <alltraps>

80105832 <vector101>:
.globl vector101
vector101:
  pushl $0
80105832:	6a 00                	push   $0x0
  pushl $101
80105834:	6a 65                	push   $0x65
  jmp alltraps
80105836:	e9 3f f8 ff ff       	jmp    8010507a <alltraps>

8010583b <vector102>:
.globl vector102
vector102:
  pushl $0
8010583b:	6a 00                	push   $0x0
  pushl $102
8010583d:	6a 66                	push   $0x66
  jmp alltraps
8010583f:	e9 36 f8 ff ff       	jmp    8010507a <alltraps>

80105844 <vector103>:
.globl vector103
vector103:
  pushl $0
80105844:	6a 00                	push   $0x0
  pushl $103
80105846:	6a 67                	push   $0x67
  jmp alltraps
80105848:	e9 2d f8 ff ff       	jmp    8010507a <alltraps>

8010584d <vector104>:
.globl vector104
vector104:
  pushl $0
8010584d:	6a 00                	push   $0x0
  pushl $104
8010584f:	6a 68                	push   $0x68
  jmp alltraps
80105851:	e9 24 f8 ff ff       	jmp    8010507a <alltraps>

80105856 <vector105>:
.globl vector105
vector105:
  pushl $0
80105856:	6a 00                	push   $0x0
  pushl $105
80105858:	6a 69                	push   $0x69
  jmp alltraps
8010585a:	e9 1b f8 ff ff       	jmp    8010507a <alltraps>

8010585f <vector106>:
.globl vector106
vector106:
  pushl $0
8010585f:	6a 00                	push   $0x0
  pushl $106
80105861:	6a 6a                	push   $0x6a
  jmp alltraps
80105863:	e9 12 f8 ff ff       	jmp    8010507a <alltraps>

80105868 <vector107>:
.globl vector107
vector107:
  pushl $0
80105868:	6a 00                	push   $0x0
  pushl $107
8010586a:	6a 6b                	push   $0x6b
  jmp alltraps
8010586c:	e9 09 f8 ff ff       	jmp    8010507a <alltraps>

80105871 <vector108>:
.globl vector108
vector108:
  pushl $0
80105871:	6a 00                	push   $0x0
  pushl $108
80105873:	6a 6c                	push   $0x6c
  jmp alltraps
80105875:	e9 00 f8 ff ff       	jmp    8010507a <alltraps>

8010587a <vector109>:
.globl vector109
vector109:
  pushl $0
8010587a:	6a 00                	push   $0x0
  pushl $109
8010587c:	6a 6d                	push   $0x6d
  jmp alltraps
8010587e:	e9 f7 f7 ff ff       	jmp    8010507a <alltraps>

80105883 <vector110>:
.globl vector110
vector110:
  pushl $0
80105883:	6a 00                	push   $0x0
  pushl $110
80105885:	6a 6e                	push   $0x6e
  jmp alltraps
80105887:	e9 ee f7 ff ff       	jmp    8010507a <alltraps>

8010588c <vector111>:
.globl vector111
vector111:
  pushl $0
8010588c:	6a 00                	push   $0x0
  pushl $111
8010588e:	6a 6f                	push   $0x6f
  jmp alltraps
80105890:	e9 e5 f7 ff ff       	jmp    8010507a <alltraps>

80105895 <vector112>:
.globl vector112
vector112:
  pushl $0
80105895:	6a 00                	push   $0x0
  pushl $112
80105897:	6a 70                	push   $0x70
  jmp alltraps
80105899:	e9 dc f7 ff ff       	jmp    8010507a <alltraps>

8010589e <vector113>:
.globl vector113
vector113:
  pushl $0
8010589e:	6a 00                	push   $0x0
  pushl $113
801058a0:	6a 71                	push   $0x71
  jmp alltraps
801058a2:	e9 d3 f7 ff ff       	jmp    8010507a <alltraps>

801058a7 <vector114>:
.globl vector114
vector114:
  pushl $0
801058a7:	6a 00                	push   $0x0
  pushl $114
801058a9:	6a 72                	push   $0x72
  jmp alltraps
801058ab:	e9 ca f7 ff ff       	jmp    8010507a <alltraps>

801058b0 <vector115>:
.globl vector115
vector115:
  pushl $0
801058b0:	6a 00                	push   $0x0
  pushl $115
801058b2:	6a 73                	push   $0x73
  jmp alltraps
801058b4:	e9 c1 f7 ff ff       	jmp    8010507a <alltraps>

801058b9 <vector116>:
.globl vector116
vector116:
  pushl $0
801058b9:	6a 00                	push   $0x0
  pushl $116
801058bb:	6a 74                	push   $0x74
  jmp alltraps
801058bd:	e9 b8 f7 ff ff       	jmp    8010507a <alltraps>

801058c2 <vector117>:
.globl vector117
vector117:
  pushl $0
801058c2:	6a 00                	push   $0x0
  pushl $117
801058c4:	6a 75                	push   $0x75
  jmp alltraps
801058c6:	e9 af f7 ff ff       	jmp    8010507a <alltraps>

801058cb <vector118>:
.globl vector118
vector118:
  pushl $0
801058cb:	6a 00                	push   $0x0
  pushl $118
801058cd:	6a 76                	push   $0x76
  jmp alltraps
801058cf:	e9 a6 f7 ff ff       	jmp    8010507a <alltraps>

801058d4 <vector119>:
.globl vector119
vector119:
  pushl $0
801058d4:	6a 00                	push   $0x0
  pushl $119
801058d6:	6a 77                	push   $0x77
  jmp alltraps
801058d8:	e9 9d f7 ff ff       	jmp    8010507a <alltraps>

801058dd <vector120>:
.globl vector120
vector120:
  pushl $0
801058dd:	6a 00                	push   $0x0
  pushl $120
801058df:	6a 78                	push   $0x78
  jmp alltraps
801058e1:	e9 94 f7 ff ff       	jmp    8010507a <alltraps>

801058e6 <vector121>:
.globl vector121
vector121:
  pushl $0
801058e6:	6a 00                	push   $0x0
  pushl $121
801058e8:	6a 79                	push   $0x79
  jmp alltraps
801058ea:	e9 8b f7 ff ff       	jmp    8010507a <alltraps>

801058ef <vector122>:
.globl vector122
vector122:
  pushl $0
801058ef:	6a 00                	push   $0x0
  pushl $122
801058f1:	6a 7a                	push   $0x7a
  jmp alltraps
801058f3:	e9 82 f7 ff ff       	jmp    8010507a <alltraps>

801058f8 <vector123>:
.globl vector123
vector123:
  pushl $0
801058f8:	6a 00                	push   $0x0
  pushl $123
801058fa:	6a 7b                	push   $0x7b
  jmp alltraps
801058fc:	e9 79 f7 ff ff       	jmp    8010507a <alltraps>

80105901 <vector124>:
.globl vector124
vector124:
  pushl $0
80105901:	6a 00                	push   $0x0
  pushl $124
80105903:	6a 7c                	push   $0x7c
  jmp alltraps
80105905:	e9 70 f7 ff ff       	jmp    8010507a <alltraps>

8010590a <vector125>:
.globl vector125
vector125:
  pushl $0
8010590a:	6a 00                	push   $0x0
  pushl $125
8010590c:	6a 7d                	push   $0x7d
  jmp alltraps
8010590e:	e9 67 f7 ff ff       	jmp    8010507a <alltraps>

80105913 <vector126>:
.globl vector126
vector126:
  pushl $0
80105913:	6a 00                	push   $0x0
  pushl $126
80105915:	6a 7e                	push   $0x7e
  jmp alltraps
80105917:	e9 5e f7 ff ff       	jmp    8010507a <alltraps>

8010591c <vector127>:
.globl vector127
vector127:
  pushl $0
8010591c:	6a 00                	push   $0x0
  pushl $127
8010591e:	6a 7f                	push   $0x7f
  jmp alltraps
80105920:	e9 55 f7 ff ff       	jmp    8010507a <alltraps>

80105925 <vector128>:
.globl vector128
vector128:
  pushl $0
80105925:	6a 00                	push   $0x0
  pushl $128
80105927:	68 80 00 00 00       	push   $0x80
  jmp alltraps
8010592c:	e9 49 f7 ff ff       	jmp    8010507a <alltraps>

80105931 <vector129>:
.globl vector129
vector129:
  pushl $0
80105931:	6a 00                	push   $0x0
  pushl $129
80105933:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80105938:	e9 3d f7 ff ff       	jmp    8010507a <alltraps>

8010593d <vector130>:
.globl vector130
vector130:
  pushl $0
8010593d:	6a 00                	push   $0x0
  pushl $130
8010593f:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80105944:	e9 31 f7 ff ff       	jmp    8010507a <alltraps>

80105949 <vector131>:
.globl vector131
vector131:
  pushl $0
80105949:	6a 00                	push   $0x0
  pushl $131
8010594b:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80105950:	e9 25 f7 ff ff       	jmp    8010507a <alltraps>

80105955 <vector132>:
.globl vector132
vector132:
  pushl $0
80105955:	6a 00                	push   $0x0
  pushl $132
80105957:	68 84 00 00 00       	push   $0x84
  jmp alltraps
8010595c:	e9 19 f7 ff ff       	jmp    8010507a <alltraps>

80105961 <vector133>:
.globl vector133
vector133:
  pushl $0
80105961:	6a 00                	push   $0x0
  pushl $133
80105963:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80105968:	e9 0d f7 ff ff       	jmp    8010507a <alltraps>

8010596d <vector134>:
.globl vector134
vector134:
  pushl $0
8010596d:	6a 00                	push   $0x0
  pushl $134
8010596f:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80105974:	e9 01 f7 ff ff       	jmp    8010507a <alltraps>

80105979 <vector135>:
.globl vector135
vector135:
  pushl $0
80105979:	6a 00                	push   $0x0
  pushl $135
8010597b:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80105980:	e9 f5 f6 ff ff       	jmp    8010507a <alltraps>

80105985 <vector136>:
.globl vector136
vector136:
  pushl $0
80105985:	6a 00                	push   $0x0
  pushl $136
80105987:	68 88 00 00 00       	push   $0x88
  jmp alltraps
8010598c:	e9 e9 f6 ff ff       	jmp    8010507a <alltraps>

80105991 <vector137>:
.globl vector137
vector137:
  pushl $0
80105991:	6a 00                	push   $0x0
  pushl $137
80105993:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80105998:	e9 dd f6 ff ff       	jmp    8010507a <alltraps>

8010599d <vector138>:
.globl vector138
vector138:
  pushl $0
8010599d:	6a 00                	push   $0x0
  pushl $138
8010599f:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801059a4:	e9 d1 f6 ff ff       	jmp    8010507a <alltraps>

801059a9 <vector139>:
.globl vector139
vector139:
  pushl $0
801059a9:	6a 00                	push   $0x0
  pushl $139
801059ab:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801059b0:	e9 c5 f6 ff ff       	jmp    8010507a <alltraps>

801059b5 <vector140>:
.globl vector140
vector140:
  pushl $0
801059b5:	6a 00                	push   $0x0
  pushl $140
801059b7:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801059bc:	e9 b9 f6 ff ff       	jmp    8010507a <alltraps>

801059c1 <vector141>:
.globl vector141
vector141:
  pushl $0
801059c1:	6a 00                	push   $0x0
  pushl $141
801059c3:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801059c8:	e9 ad f6 ff ff       	jmp    8010507a <alltraps>

801059cd <vector142>:
.globl vector142
vector142:
  pushl $0
801059cd:	6a 00                	push   $0x0
  pushl $142
801059cf:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
801059d4:	e9 a1 f6 ff ff       	jmp    8010507a <alltraps>

801059d9 <vector143>:
.globl vector143
vector143:
  pushl $0
801059d9:	6a 00                	push   $0x0
  pushl $143
801059db:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
801059e0:	e9 95 f6 ff ff       	jmp    8010507a <alltraps>

801059e5 <vector144>:
.globl vector144
vector144:
  pushl $0
801059e5:	6a 00                	push   $0x0
  pushl $144
801059e7:	68 90 00 00 00       	push   $0x90
  jmp alltraps
801059ec:	e9 89 f6 ff ff       	jmp    8010507a <alltraps>

801059f1 <vector145>:
.globl vector145
vector145:
  pushl $0
801059f1:	6a 00                	push   $0x0
  pushl $145
801059f3:	68 91 00 00 00       	push   $0x91
  jmp alltraps
801059f8:	e9 7d f6 ff ff       	jmp    8010507a <alltraps>

801059fd <vector146>:
.globl vector146
vector146:
  pushl $0
801059fd:	6a 00                	push   $0x0
  pushl $146
801059ff:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80105a04:	e9 71 f6 ff ff       	jmp    8010507a <alltraps>

80105a09 <vector147>:
.globl vector147
vector147:
  pushl $0
80105a09:	6a 00                	push   $0x0
  pushl $147
80105a0b:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80105a10:	e9 65 f6 ff ff       	jmp    8010507a <alltraps>

80105a15 <vector148>:
.globl vector148
vector148:
  pushl $0
80105a15:	6a 00                	push   $0x0
  pushl $148
80105a17:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80105a1c:	e9 59 f6 ff ff       	jmp    8010507a <alltraps>

80105a21 <vector149>:
.globl vector149
vector149:
  pushl $0
80105a21:	6a 00                	push   $0x0
  pushl $149
80105a23:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80105a28:	e9 4d f6 ff ff       	jmp    8010507a <alltraps>

80105a2d <vector150>:
.globl vector150
vector150:
  pushl $0
80105a2d:	6a 00                	push   $0x0
  pushl $150
80105a2f:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80105a34:	e9 41 f6 ff ff       	jmp    8010507a <alltraps>

80105a39 <vector151>:
.globl vector151
vector151:
  pushl $0
80105a39:	6a 00                	push   $0x0
  pushl $151
80105a3b:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80105a40:	e9 35 f6 ff ff       	jmp    8010507a <alltraps>

80105a45 <vector152>:
.globl vector152
vector152:
  pushl $0
80105a45:	6a 00                	push   $0x0
  pushl $152
80105a47:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80105a4c:	e9 29 f6 ff ff       	jmp    8010507a <alltraps>

80105a51 <vector153>:
.globl vector153
vector153:
  pushl $0
80105a51:	6a 00                	push   $0x0
  pushl $153
80105a53:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80105a58:	e9 1d f6 ff ff       	jmp    8010507a <alltraps>

80105a5d <vector154>:
.globl vector154
vector154:
  pushl $0
80105a5d:	6a 00                	push   $0x0
  pushl $154
80105a5f:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80105a64:	e9 11 f6 ff ff       	jmp    8010507a <alltraps>

80105a69 <vector155>:
.globl vector155
vector155:
  pushl $0
80105a69:	6a 00                	push   $0x0
  pushl $155
80105a6b:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80105a70:	e9 05 f6 ff ff       	jmp    8010507a <alltraps>

80105a75 <vector156>:
.globl vector156
vector156:
  pushl $0
80105a75:	6a 00                	push   $0x0
  pushl $156
80105a77:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80105a7c:	e9 f9 f5 ff ff       	jmp    8010507a <alltraps>

80105a81 <vector157>:
.globl vector157
vector157:
  pushl $0
80105a81:	6a 00                	push   $0x0
  pushl $157
80105a83:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80105a88:	e9 ed f5 ff ff       	jmp    8010507a <alltraps>

80105a8d <vector158>:
.globl vector158
vector158:
  pushl $0
80105a8d:	6a 00                	push   $0x0
  pushl $158
80105a8f:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80105a94:	e9 e1 f5 ff ff       	jmp    8010507a <alltraps>

80105a99 <vector159>:
.globl vector159
vector159:
  pushl $0
80105a99:	6a 00                	push   $0x0
  pushl $159
80105a9b:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80105aa0:	e9 d5 f5 ff ff       	jmp    8010507a <alltraps>

80105aa5 <vector160>:
.globl vector160
vector160:
  pushl $0
80105aa5:	6a 00                	push   $0x0
  pushl $160
80105aa7:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80105aac:	e9 c9 f5 ff ff       	jmp    8010507a <alltraps>

80105ab1 <vector161>:
.globl vector161
vector161:
  pushl $0
80105ab1:	6a 00                	push   $0x0
  pushl $161
80105ab3:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80105ab8:	e9 bd f5 ff ff       	jmp    8010507a <alltraps>

80105abd <vector162>:
.globl vector162
vector162:
  pushl $0
80105abd:	6a 00                	push   $0x0
  pushl $162
80105abf:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105ac4:	e9 b1 f5 ff ff       	jmp    8010507a <alltraps>

80105ac9 <vector163>:
.globl vector163
vector163:
  pushl $0
80105ac9:	6a 00                	push   $0x0
  pushl $163
80105acb:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105ad0:	e9 a5 f5 ff ff       	jmp    8010507a <alltraps>

80105ad5 <vector164>:
.globl vector164
vector164:
  pushl $0
80105ad5:	6a 00                	push   $0x0
  pushl $164
80105ad7:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80105adc:	e9 99 f5 ff ff       	jmp    8010507a <alltraps>

80105ae1 <vector165>:
.globl vector165
vector165:
  pushl $0
80105ae1:	6a 00                	push   $0x0
  pushl $165
80105ae3:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80105ae8:	e9 8d f5 ff ff       	jmp    8010507a <alltraps>

80105aed <vector166>:
.globl vector166
vector166:
  pushl $0
80105aed:	6a 00                	push   $0x0
  pushl $166
80105aef:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105af4:	e9 81 f5 ff ff       	jmp    8010507a <alltraps>

80105af9 <vector167>:
.globl vector167
vector167:
  pushl $0
80105af9:	6a 00                	push   $0x0
  pushl $167
80105afb:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105b00:	e9 75 f5 ff ff       	jmp    8010507a <alltraps>

80105b05 <vector168>:
.globl vector168
vector168:
  pushl $0
80105b05:	6a 00                	push   $0x0
  pushl $168
80105b07:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80105b0c:	e9 69 f5 ff ff       	jmp    8010507a <alltraps>

80105b11 <vector169>:
.globl vector169
vector169:
  pushl $0
80105b11:	6a 00                	push   $0x0
  pushl $169
80105b13:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80105b18:	e9 5d f5 ff ff       	jmp    8010507a <alltraps>

80105b1d <vector170>:
.globl vector170
vector170:
  pushl $0
80105b1d:	6a 00                	push   $0x0
  pushl $170
80105b1f:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105b24:	e9 51 f5 ff ff       	jmp    8010507a <alltraps>

80105b29 <vector171>:
.globl vector171
vector171:
  pushl $0
80105b29:	6a 00                	push   $0x0
  pushl $171
80105b2b:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105b30:	e9 45 f5 ff ff       	jmp    8010507a <alltraps>

80105b35 <vector172>:
.globl vector172
vector172:
  pushl $0
80105b35:	6a 00                	push   $0x0
  pushl $172
80105b37:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80105b3c:	e9 39 f5 ff ff       	jmp    8010507a <alltraps>

80105b41 <vector173>:
.globl vector173
vector173:
  pushl $0
80105b41:	6a 00                	push   $0x0
  pushl $173
80105b43:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80105b48:	e9 2d f5 ff ff       	jmp    8010507a <alltraps>

80105b4d <vector174>:
.globl vector174
vector174:
  pushl $0
80105b4d:	6a 00                	push   $0x0
  pushl $174
80105b4f:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80105b54:	e9 21 f5 ff ff       	jmp    8010507a <alltraps>

80105b59 <vector175>:
.globl vector175
vector175:
  pushl $0
80105b59:	6a 00                	push   $0x0
  pushl $175
80105b5b:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80105b60:	e9 15 f5 ff ff       	jmp    8010507a <alltraps>

80105b65 <vector176>:
.globl vector176
vector176:
  pushl $0
80105b65:	6a 00                	push   $0x0
  pushl $176
80105b67:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80105b6c:	e9 09 f5 ff ff       	jmp    8010507a <alltraps>

80105b71 <vector177>:
.globl vector177
vector177:
  pushl $0
80105b71:	6a 00                	push   $0x0
  pushl $177
80105b73:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80105b78:	e9 fd f4 ff ff       	jmp    8010507a <alltraps>

80105b7d <vector178>:
.globl vector178
vector178:
  pushl $0
80105b7d:	6a 00                	push   $0x0
  pushl $178
80105b7f:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80105b84:	e9 f1 f4 ff ff       	jmp    8010507a <alltraps>

80105b89 <vector179>:
.globl vector179
vector179:
  pushl $0
80105b89:	6a 00                	push   $0x0
  pushl $179
80105b8b:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80105b90:	e9 e5 f4 ff ff       	jmp    8010507a <alltraps>

80105b95 <vector180>:
.globl vector180
vector180:
  pushl $0
80105b95:	6a 00                	push   $0x0
  pushl $180
80105b97:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80105b9c:	e9 d9 f4 ff ff       	jmp    8010507a <alltraps>

80105ba1 <vector181>:
.globl vector181
vector181:
  pushl $0
80105ba1:	6a 00                	push   $0x0
  pushl $181
80105ba3:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105ba8:	e9 cd f4 ff ff       	jmp    8010507a <alltraps>

80105bad <vector182>:
.globl vector182
vector182:
  pushl $0
80105bad:	6a 00                	push   $0x0
  pushl $182
80105baf:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105bb4:	e9 c1 f4 ff ff       	jmp    8010507a <alltraps>

80105bb9 <vector183>:
.globl vector183
vector183:
  pushl $0
80105bb9:	6a 00                	push   $0x0
  pushl $183
80105bbb:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105bc0:	e9 b5 f4 ff ff       	jmp    8010507a <alltraps>

80105bc5 <vector184>:
.globl vector184
vector184:
  pushl $0
80105bc5:	6a 00                	push   $0x0
  pushl $184
80105bc7:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105bcc:	e9 a9 f4 ff ff       	jmp    8010507a <alltraps>

80105bd1 <vector185>:
.globl vector185
vector185:
  pushl $0
80105bd1:	6a 00                	push   $0x0
  pushl $185
80105bd3:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105bd8:	e9 9d f4 ff ff       	jmp    8010507a <alltraps>

80105bdd <vector186>:
.globl vector186
vector186:
  pushl $0
80105bdd:	6a 00                	push   $0x0
  pushl $186
80105bdf:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105be4:	e9 91 f4 ff ff       	jmp    8010507a <alltraps>

80105be9 <vector187>:
.globl vector187
vector187:
  pushl $0
80105be9:	6a 00                	push   $0x0
  pushl $187
80105beb:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105bf0:	e9 85 f4 ff ff       	jmp    8010507a <alltraps>

80105bf5 <vector188>:
.globl vector188
vector188:
  pushl $0
80105bf5:	6a 00                	push   $0x0
  pushl $188
80105bf7:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105bfc:	e9 79 f4 ff ff       	jmp    8010507a <alltraps>

80105c01 <vector189>:
.globl vector189
vector189:
  pushl $0
80105c01:	6a 00                	push   $0x0
  pushl $189
80105c03:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105c08:	e9 6d f4 ff ff       	jmp    8010507a <alltraps>

80105c0d <vector190>:
.globl vector190
vector190:
  pushl $0
80105c0d:	6a 00                	push   $0x0
  pushl $190
80105c0f:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105c14:	e9 61 f4 ff ff       	jmp    8010507a <alltraps>

80105c19 <vector191>:
.globl vector191
vector191:
  pushl $0
80105c19:	6a 00                	push   $0x0
  pushl $191
80105c1b:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105c20:	e9 55 f4 ff ff       	jmp    8010507a <alltraps>

80105c25 <vector192>:
.globl vector192
vector192:
  pushl $0
80105c25:	6a 00                	push   $0x0
  pushl $192
80105c27:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105c2c:	e9 49 f4 ff ff       	jmp    8010507a <alltraps>

80105c31 <vector193>:
.globl vector193
vector193:
  pushl $0
80105c31:	6a 00                	push   $0x0
  pushl $193
80105c33:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105c38:	e9 3d f4 ff ff       	jmp    8010507a <alltraps>

80105c3d <vector194>:
.globl vector194
vector194:
  pushl $0
80105c3d:	6a 00                	push   $0x0
  pushl $194
80105c3f:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105c44:	e9 31 f4 ff ff       	jmp    8010507a <alltraps>

80105c49 <vector195>:
.globl vector195
vector195:
  pushl $0
80105c49:	6a 00                	push   $0x0
  pushl $195
80105c4b:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105c50:	e9 25 f4 ff ff       	jmp    8010507a <alltraps>

80105c55 <vector196>:
.globl vector196
vector196:
  pushl $0
80105c55:	6a 00                	push   $0x0
  pushl $196
80105c57:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105c5c:	e9 19 f4 ff ff       	jmp    8010507a <alltraps>

80105c61 <vector197>:
.globl vector197
vector197:
  pushl $0
80105c61:	6a 00                	push   $0x0
  pushl $197
80105c63:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105c68:	e9 0d f4 ff ff       	jmp    8010507a <alltraps>

80105c6d <vector198>:
.globl vector198
vector198:
  pushl $0
80105c6d:	6a 00                	push   $0x0
  pushl $198
80105c6f:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105c74:	e9 01 f4 ff ff       	jmp    8010507a <alltraps>

80105c79 <vector199>:
.globl vector199
vector199:
  pushl $0
80105c79:	6a 00                	push   $0x0
  pushl $199
80105c7b:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105c80:	e9 f5 f3 ff ff       	jmp    8010507a <alltraps>

80105c85 <vector200>:
.globl vector200
vector200:
  pushl $0
80105c85:	6a 00                	push   $0x0
  pushl $200
80105c87:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105c8c:	e9 e9 f3 ff ff       	jmp    8010507a <alltraps>

80105c91 <vector201>:
.globl vector201
vector201:
  pushl $0
80105c91:	6a 00                	push   $0x0
  pushl $201
80105c93:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105c98:	e9 dd f3 ff ff       	jmp    8010507a <alltraps>

80105c9d <vector202>:
.globl vector202
vector202:
  pushl $0
80105c9d:	6a 00                	push   $0x0
  pushl $202
80105c9f:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105ca4:	e9 d1 f3 ff ff       	jmp    8010507a <alltraps>

80105ca9 <vector203>:
.globl vector203
vector203:
  pushl $0
80105ca9:	6a 00                	push   $0x0
  pushl $203
80105cab:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105cb0:	e9 c5 f3 ff ff       	jmp    8010507a <alltraps>

80105cb5 <vector204>:
.globl vector204
vector204:
  pushl $0
80105cb5:	6a 00                	push   $0x0
  pushl $204
80105cb7:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105cbc:	e9 b9 f3 ff ff       	jmp    8010507a <alltraps>

80105cc1 <vector205>:
.globl vector205
vector205:
  pushl $0
80105cc1:	6a 00                	push   $0x0
  pushl $205
80105cc3:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105cc8:	e9 ad f3 ff ff       	jmp    8010507a <alltraps>

80105ccd <vector206>:
.globl vector206
vector206:
  pushl $0
80105ccd:	6a 00                	push   $0x0
  pushl $206
80105ccf:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105cd4:	e9 a1 f3 ff ff       	jmp    8010507a <alltraps>

80105cd9 <vector207>:
.globl vector207
vector207:
  pushl $0
80105cd9:	6a 00                	push   $0x0
  pushl $207
80105cdb:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105ce0:	e9 95 f3 ff ff       	jmp    8010507a <alltraps>

80105ce5 <vector208>:
.globl vector208
vector208:
  pushl $0
80105ce5:	6a 00                	push   $0x0
  pushl $208
80105ce7:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105cec:	e9 89 f3 ff ff       	jmp    8010507a <alltraps>

80105cf1 <vector209>:
.globl vector209
vector209:
  pushl $0
80105cf1:	6a 00                	push   $0x0
  pushl $209
80105cf3:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105cf8:	e9 7d f3 ff ff       	jmp    8010507a <alltraps>

80105cfd <vector210>:
.globl vector210
vector210:
  pushl $0
80105cfd:	6a 00                	push   $0x0
  pushl $210
80105cff:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105d04:	e9 71 f3 ff ff       	jmp    8010507a <alltraps>

80105d09 <vector211>:
.globl vector211
vector211:
  pushl $0
80105d09:	6a 00                	push   $0x0
  pushl $211
80105d0b:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105d10:	e9 65 f3 ff ff       	jmp    8010507a <alltraps>

80105d15 <vector212>:
.globl vector212
vector212:
  pushl $0
80105d15:	6a 00                	push   $0x0
  pushl $212
80105d17:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105d1c:	e9 59 f3 ff ff       	jmp    8010507a <alltraps>

80105d21 <vector213>:
.globl vector213
vector213:
  pushl $0
80105d21:	6a 00                	push   $0x0
  pushl $213
80105d23:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105d28:	e9 4d f3 ff ff       	jmp    8010507a <alltraps>

80105d2d <vector214>:
.globl vector214
vector214:
  pushl $0
80105d2d:	6a 00                	push   $0x0
  pushl $214
80105d2f:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105d34:	e9 41 f3 ff ff       	jmp    8010507a <alltraps>

80105d39 <vector215>:
.globl vector215
vector215:
  pushl $0
80105d39:	6a 00                	push   $0x0
  pushl $215
80105d3b:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105d40:	e9 35 f3 ff ff       	jmp    8010507a <alltraps>

80105d45 <vector216>:
.globl vector216
vector216:
  pushl $0
80105d45:	6a 00                	push   $0x0
  pushl $216
80105d47:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105d4c:	e9 29 f3 ff ff       	jmp    8010507a <alltraps>

80105d51 <vector217>:
.globl vector217
vector217:
  pushl $0
80105d51:	6a 00                	push   $0x0
  pushl $217
80105d53:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105d58:	e9 1d f3 ff ff       	jmp    8010507a <alltraps>

80105d5d <vector218>:
.globl vector218
vector218:
  pushl $0
80105d5d:	6a 00                	push   $0x0
  pushl $218
80105d5f:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105d64:	e9 11 f3 ff ff       	jmp    8010507a <alltraps>

80105d69 <vector219>:
.globl vector219
vector219:
  pushl $0
80105d69:	6a 00                	push   $0x0
  pushl $219
80105d6b:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105d70:	e9 05 f3 ff ff       	jmp    8010507a <alltraps>

80105d75 <vector220>:
.globl vector220
vector220:
  pushl $0
80105d75:	6a 00                	push   $0x0
  pushl $220
80105d77:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105d7c:	e9 f9 f2 ff ff       	jmp    8010507a <alltraps>

80105d81 <vector221>:
.globl vector221
vector221:
  pushl $0
80105d81:	6a 00                	push   $0x0
  pushl $221
80105d83:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105d88:	e9 ed f2 ff ff       	jmp    8010507a <alltraps>

80105d8d <vector222>:
.globl vector222
vector222:
  pushl $0
80105d8d:	6a 00                	push   $0x0
  pushl $222
80105d8f:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105d94:	e9 e1 f2 ff ff       	jmp    8010507a <alltraps>

80105d99 <vector223>:
.globl vector223
vector223:
  pushl $0
80105d99:	6a 00                	push   $0x0
  pushl $223
80105d9b:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105da0:	e9 d5 f2 ff ff       	jmp    8010507a <alltraps>

80105da5 <vector224>:
.globl vector224
vector224:
  pushl $0
80105da5:	6a 00                	push   $0x0
  pushl $224
80105da7:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105dac:	e9 c9 f2 ff ff       	jmp    8010507a <alltraps>

80105db1 <vector225>:
.globl vector225
vector225:
  pushl $0
80105db1:	6a 00                	push   $0x0
  pushl $225
80105db3:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105db8:	e9 bd f2 ff ff       	jmp    8010507a <alltraps>

80105dbd <vector226>:
.globl vector226
vector226:
  pushl $0
80105dbd:	6a 00                	push   $0x0
  pushl $226
80105dbf:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105dc4:	e9 b1 f2 ff ff       	jmp    8010507a <alltraps>

80105dc9 <vector227>:
.globl vector227
vector227:
  pushl $0
80105dc9:	6a 00                	push   $0x0
  pushl $227
80105dcb:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105dd0:	e9 a5 f2 ff ff       	jmp    8010507a <alltraps>

80105dd5 <vector228>:
.globl vector228
vector228:
  pushl $0
80105dd5:	6a 00                	push   $0x0
  pushl $228
80105dd7:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105ddc:	e9 99 f2 ff ff       	jmp    8010507a <alltraps>

80105de1 <vector229>:
.globl vector229
vector229:
  pushl $0
80105de1:	6a 00                	push   $0x0
  pushl $229
80105de3:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105de8:	e9 8d f2 ff ff       	jmp    8010507a <alltraps>

80105ded <vector230>:
.globl vector230
vector230:
  pushl $0
80105ded:	6a 00                	push   $0x0
  pushl $230
80105def:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105df4:	e9 81 f2 ff ff       	jmp    8010507a <alltraps>

80105df9 <vector231>:
.globl vector231
vector231:
  pushl $0
80105df9:	6a 00                	push   $0x0
  pushl $231
80105dfb:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105e00:	e9 75 f2 ff ff       	jmp    8010507a <alltraps>

80105e05 <vector232>:
.globl vector232
vector232:
  pushl $0
80105e05:	6a 00                	push   $0x0
  pushl $232
80105e07:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105e0c:	e9 69 f2 ff ff       	jmp    8010507a <alltraps>

80105e11 <vector233>:
.globl vector233
vector233:
  pushl $0
80105e11:	6a 00                	push   $0x0
  pushl $233
80105e13:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105e18:	e9 5d f2 ff ff       	jmp    8010507a <alltraps>

80105e1d <vector234>:
.globl vector234
vector234:
  pushl $0
80105e1d:	6a 00                	push   $0x0
  pushl $234
80105e1f:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105e24:	e9 51 f2 ff ff       	jmp    8010507a <alltraps>

80105e29 <vector235>:
.globl vector235
vector235:
  pushl $0
80105e29:	6a 00                	push   $0x0
  pushl $235
80105e2b:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105e30:	e9 45 f2 ff ff       	jmp    8010507a <alltraps>

80105e35 <vector236>:
.globl vector236
vector236:
  pushl $0
80105e35:	6a 00                	push   $0x0
  pushl $236
80105e37:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105e3c:	e9 39 f2 ff ff       	jmp    8010507a <alltraps>

80105e41 <vector237>:
.globl vector237
vector237:
  pushl $0
80105e41:	6a 00                	push   $0x0
  pushl $237
80105e43:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105e48:	e9 2d f2 ff ff       	jmp    8010507a <alltraps>

80105e4d <vector238>:
.globl vector238
vector238:
  pushl $0
80105e4d:	6a 00                	push   $0x0
  pushl $238
80105e4f:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105e54:	e9 21 f2 ff ff       	jmp    8010507a <alltraps>

80105e59 <vector239>:
.globl vector239
vector239:
  pushl $0
80105e59:	6a 00                	push   $0x0
  pushl $239
80105e5b:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105e60:	e9 15 f2 ff ff       	jmp    8010507a <alltraps>

80105e65 <vector240>:
.globl vector240
vector240:
  pushl $0
80105e65:	6a 00                	push   $0x0
  pushl $240
80105e67:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105e6c:	e9 09 f2 ff ff       	jmp    8010507a <alltraps>

80105e71 <vector241>:
.globl vector241
vector241:
  pushl $0
80105e71:	6a 00                	push   $0x0
  pushl $241
80105e73:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105e78:	e9 fd f1 ff ff       	jmp    8010507a <alltraps>

80105e7d <vector242>:
.globl vector242
vector242:
  pushl $0
80105e7d:	6a 00                	push   $0x0
  pushl $242
80105e7f:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105e84:	e9 f1 f1 ff ff       	jmp    8010507a <alltraps>

80105e89 <vector243>:
.globl vector243
vector243:
  pushl $0
80105e89:	6a 00                	push   $0x0
  pushl $243
80105e8b:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105e90:	e9 e5 f1 ff ff       	jmp    8010507a <alltraps>

80105e95 <vector244>:
.globl vector244
vector244:
  pushl $0
80105e95:	6a 00                	push   $0x0
  pushl $244
80105e97:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105e9c:	e9 d9 f1 ff ff       	jmp    8010507a <alltraps>

80105ea1 <vector245>:
.globl vector245
vector245:
  pushl $0
80105ea1:	6a 00                	push   $0x0
  pushl $245
80105ea3:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105ea8:	e9 cd f1 ff ff       	jmp    8010507a <alltraps>

80105ead <vector246>:
.globl vector246
vector246:
  pushl $0
80105ead:	6a 00                	push   $0x0
  pushl $246
80105eaf:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105eb4:	e9 c1 f1 ff ff       	jmp    8010507a <alltraps>

80105eb9 <vector247>:
.globl vector247
vector247:
  pushl $0
80105eb9:	6a 00                	push   $0x0
  pushl $247
80105ebb:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105ec0:	e9 b5 f1 ff ff       	jmp    8010507a <alltraps>

80105ec5 <vector248>:
.globl vector248
vector248:
  pushl $0
80105ec5:	6a 00                	push   $0x0
  pushl $248
80105ec7:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105ecc:	e9 a9 f1 ff ff       	jmp    8010507a <alltraps>

80105ed1 <vector249>:
.globl vector249
vector249:
  pushl $0
80105ed1:	6a 00                	push   $0x0
  pushl $249
80105ed3:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105ed8:	e9 9d f1 ff ff       	jmp    8010507a <alltraps>

80105edd <vector250>:
.globl vector250
vector250:
  pushl $0
80105edd:	6a 00                	push   $0x0
  pushl $250
80105edf:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105ee4:	e9 91 f1 ff ff       	jmp    8010507a <alltraps>

80105ee9 <vector251>:
.globl vector251
vector251:
  pushl $0
80105ee9:	6a 00                	push   $0x0
  pushl $251
80105eeb:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105ef0:	e9 85 f1 ff ff       	jmp    8010507a <alltraps>

80105ef5 <vector252>:
.globl vector252
vector252:
  pushl $0
80105ef5:	6a 00                	push   $0x0
  pushl $252
80105ef7:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105efc:	e9 79 f1 ff ff       	jmp    8010507a <alltraps>

80105f01 <vector253>:
.globl vector253
vector253:
  pushl $0
80105f01:	6a 00                	push   $0x0
  pushl $253
80105f03:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105f08:	e9 6d f1 ff ff       	jmp    8010507a <alltraps>

80105f0d <vector254>:
.globl vector254
vector254:
  pushl $0
80105f0d:	6a 00                	push   $0x0
  pushl $254
80105f0f:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105f14:	e9 61 f1 ff ff       	jmp    8010507a <alltraps>

80105f19 <vector255>:
.globl vector255
vector255:
  pushl $0
80105f19:	6a 00                	push   $0x0
  pushl $255
80105f1b:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105f20:	e9 55 f1 ff ff       	jmp    8010507a <alltraps>

80105f25 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105f25:	55                   	push   %ebp
80105f26:	89 e5                	mov    %esp,%ebp
80105f28:	57                   	push   %edi
80105f29:	56                   	push   %esi
80105f2a:	53                   	push   %ebx
80105f2b:	83 ec 0c             	sub    $0xc,%esp
80105f2e:	89 d6                	mov    %edx,%esi
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105f30:	c1 ea 16             	shr    $0x16,%edx
80105f33:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105f36:	8b 1f                	mov    (%edi),%ebx
80105f38:	f6 c3 01             	test   $0x1,%bl
80105f3b:	74 22                	je     80105f5f <walkpgdir+0x3a>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105f3d:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
80105f43:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105f49:	c1 ee 0c             	shr    $0xc,%esi
80105f4c:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
80105f52:	8d 1c b3             	lea    (%ebx,%esi,4),%ebx
}
80105f55:	89 d8                	mov    %ebx,%eax
80105f57:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105f5a:	5b                   	pop    %ebx
80105f5b:	5e                   	pop    %esi
80105f5c:	5f                   	pop    %edi
80105f5d:	5d                   	pop    %ebp
80105f5e:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80105f5f:	85 c9                	test   %ecx,%ecx
80105f61:	74 2b                	je     80105f8e <walkpgdir+0x69>
80105f63:	e8 4a c2 ff ff       	call   801021b2 <kalloc>
80105f68:	89 c3                	mov    %eax,%ebx
80105f6a:	85 c0                	test   %eax,%eax
80105f6c:	74 e7                	je     80105f55 <walkpgdir+0x30>
    memset(pgtab, 0, PGSIZE);
80105f6e:	83 ec 04             	sub    $0x4,%esp
80105f71:	68 00 10 00 00       	push   $0x1000
80105f76:	6a 00                	push   $0x0
80105f78:	50                   	push   %eax
80105f79:	e8 fe df ff ff       	call   80103f7c <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105f7e:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80105f84:	83 c8 07             	or     $0x7,%eax
80105f87:	89 07                	mov    %eax,(%edi)
80105f89:	83 c4 10             	add    $0x10,%esp
80105f8c:	eb bb                	jmp    80105f49 <walkpgdir+0x24>
      return 0;
80105f8e:	bb 00 00 00 00       	mov    $0x0,%ebx
80105f93:	eb c0                	jmp    80105f55 <walkpgdir+0x30>

80105f95 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105f95:	55                   	push   %ebp
80105f96:	89 e5                	mov    %esp,%ebp
80105f98:	57                   	push   %edi
80105f99:	56                   	push   %esi
80105f9a:	53                   	push   %ebx
80105f9b:	83 ec 1c             	sub    $0x1c,%esp
80105f9e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105fa1:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105fa4:	89 d3                	mov    %edx,%ebx
80105fa6:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105fac:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105fb0:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105fb6:	b9 01 00 00 00       	mov    $0x1,%ecx
80105fbb:	89 da                	mov    %ebx,%edx
80105fbd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105fc0:	e8 60 ff ff ff       	call   80105f25 <walkpgdir>
80105fc5:	85 c0                	test   %eax,%eax
80105fc7:	74 2e                	je     80105ff7 <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105fc9:	f6 00 01             	testb  $0x1,(%eax)
80105fcc:	75 1c                	jne    80105fea <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105fce:	89 f2                	mov    %esi,%edx
80105fd0:	0b 55 0c             	or     0xc(%ebp),%edx
80105fd3:	83 ca 01             	or     $0x1,%edx
80105fd6:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105fd8:	39 fb                	cmp    %edi,%ebx
80105fda:	74 28                	je     80106004 <mappages+0x6f>
      break;
    a += PGSIZE;
80105fdc:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105fe2:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105fe8:	eb cc                	jmp    80105fb6 <mappages+0x21>
      panic("remap");
80105fea:	83 ec 0c             	sub    $0xc,%esp
80105fed:	68 ac 70 10 80       	push   $0x801070ac
80105ff2:	e8 51 a3 ff ff       	call   80100348 <panic>
      return -1;
80105ff7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105ffc:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105fff:	5b                   	pop    %ebx
80106000:	5e                   	pop    %esi
80106001:	5f                   	pop    %edi
80106002:	5d                   	pop    %ebp
80106003:	c3                   	ret    
  return 0;
80106004:	b8 00 00 00 00       	mov    $0x0,%eax
80106009:	eb f1                	jmp    80105ffc <mappages+0x67>

8010600b <seginit>:
{
8010600b:	55                   	push   %ebp
8010600c:	89 e5                	mov    %esp,%ebp
8010600e:	53                   	push   %ebx
8010600f:	83 ec 14             	sub    $0x14,%esp
  c = &cpus[cpuid()];
80106012:	e8 fc d4 ff ff       	call   80103513 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80106017:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
8010601d:	66 c7 80 f8 44 14 80 	movw   $0xffff,-0x7febbb08(%eax)
80106024:	ff ff 
80106026:	66 c7 80 fa 44 14 80 	movw   $0x0,-0x7febbb06(%eax)
8010602d:	00 00 
8010602f:	c6 80 fc 44 14 80 00 	movb   $0x0,-0x7febbb04(%eax)
80106036:	0f b6 88 fd 44 14 80 	movzbl -0x7febbb03(%eax),%ecx
8010603d:	83 e1 f0             	and    $0xfffffff0,%ecx
80106040:	83 c9 1a             	or     $0x1a,%ecx
80106043:	83 e1 9f             	and    $0xffffff9f,%ecx
80106046:	83 c9 80             	or     $0xffffff80,%ecx
80106049:	88 88 fd 44 14 80    	mov    %cl,-0x7febbb03(%eax)
8010604f:	0f b6 88 fe 44 14 80 	movzbl -0x7febbb02(%eax),%ecx
80106056:	83 c9 0f             	or     $0xf,%ecx
80106059:	83 e1 cf             	and    $0xffffffcf,%ecx
8010605c:	83 c9 c0             	or     $0xffffffc0,%ecx
8010605f:	88 88 fe 44 14 80    	mov    %cl,-0x7febbb02(%eax)
80106065:	c6 80 ff 44 14 80 00 	movb   $0x0,-0x7febbb01(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
8010606c:	66 c7 80 00 45 14 80 	movw   $0xffff,-0x7febbb00(%eax)
80106073:	ff ff 
80106075:	66 c7 80 02 45 14 80 	movw   $0x0,-0x7febbafe(%eax)
8010607c:	00 00 
8010607e:	c6 80 04 45 14 80 00 	movb   $0x0,-0x7febbafc(%eax)
80106085:	0f b6 88 05 45 14 80 	movzbl -0x7febbafb(%eax),%ecx
8010608c:	83 e1 f0             	and    $0xfffffff0,%ecx
8010608f:	83 c9 12             	or     $0x12,%ecx
80106092:	83 e1 9f             	and    $0xffffff9f,%ecx
80106095:	83 c9 80             	or     $0xffffff80,%ecx
80106098:	88 88 05 45 14 80    	mov    %cl,-0x7febbafb(%eax)
8010609e:	0f b6 88 06 45 14 80 	movzbl -0x7febbafa(%eax),%ecx
801060a5:	83 c9 0f             	or     $0xf,%ecx
801060a8:	83 e1 cf             	and    $0xffffffcf,%ecx
801060ab:	83 c9 c0             	or     $0xffffffc0,%ecx
801060ae:	88 88 06 45 14 80    	mov    %cl,-0x7febbafa(%eax)
801060b4:	c6 80 07 45 14 80 00 	movb   $0x0,-0x7febbaf9(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
801060bb:	66 c7 80 08 45 14 80 	movw   $0xffff,-0x7febbaf8(%eax)
801060c2:	ff ff 
801060c4:	66 c7 80 0a 45 14 80 	movw   $0x0,-0x7febbaf6(%eax)
801060cb:	00 00 
801060cd:	c6 80 0c 45 14 80 00 	movb   $0x0,-0x7febbaf4(%eax)
801060d4:	c6 80 0d 45 14 80 fa 	movb   $0xfa,-0x7febbaf3(%eax)
801060db:	0f b6 88 0e 45 14 80 	movzbl -0x7febbaf2(%eax),%ecx
801060e2:	83 c9 0f             	or     $0xf,%ecx
801060e5:	83 e1 cf             	and    $0xffffffcf,%ecx
801060e8:	83 c9 c0             	or     $0xffffffc0,%ecx
801060eb:	88 88 0e 45 14 80    	mov    %cl,-0x7febbaf2(%eax)
801060f1:	c6 80 0f 45 14 80 00 	movb   $0x0,-0x7febbaf1(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
801060f8:	66 c7 80 10 45 14 80 	movw   $0xffff,-0x7febbaf0(%eax)
801060ff:	ff ff 
80106101:	66 c7 80 12 45 14 80 	movw   $0x0,-0x7febbaee(%eax)
80106108:	00 00 
8010610a:	c6 80 14 45 14 80 00 	movb   $0x0,-0x7febbaec(%eax)
80106111:	c6 80 15 45 14 80 f2 	movb   $0xf2,-0x7febbaeb(%eax)
80106118:	0f b6 88 16 45 14 80 	movzbl -0x7febbaea(%eax),%ecx
8010611f:	83 c9 0f             	or     $0xf,%ecx
80106122:	83 e1 cf             	and    $0xffffffcf,%ecx
80106125:	83 c9 c0             	or     $0xffffffc0,%ecx
80106128:	88 88 16 45 14 80    	mov    %cl,-0x7febbaea(%eax)
8010612e:	c6 80 17 45 14 80 00 	movb   $0x0,-0x7febbae9(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80106135:	05 f0 44 14 80       	add    $0x801444f0,%eax
  pd[0] = size-1;
8010613a:	66 c7 45 f2 2f 00    	movw   $0x2f,-0xe(%ebp)
  pd[1] = (uint)p;
80106140:	66 89 45 f4          	mov    %ax,-0xc(%ebp)
  pd[2] = (uint)p >> 16;
80106144:	c1 e8 10             	shr    $0x10,%eax
80106147:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
8010614b:	8d 45 f2             	lea    -0xe(%ebp),%eax
8010614e:	0f 01 10             	lgdtl  (%eax)
}
80106151:	83 c4 14             	add    $0x14,%esp
80106154:	5b                   	pop    %ebx
80106155:	5d                   	pop    %ebp
80106156:	c3                   	ret    

80106157 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80106157:	55                   	push   %ebp
80106158:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
8010615a:	a1 a4 71 14 80       	mov    0x801471a4,%eax
8010615f:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80106164:	0f 22 d8             	mov    %eax,%cr3
}
80106167:	5d                   	pop    %ebp
80106168:	c3                   	ret    

80106169 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80106169:	55                   	push   %ebp
8010616a:	89 e5                	mov    %esp,%ebp
8010616c:	57                   	push   %edi
8010616d:	56                   	push   %esi
8010616e:	53                   	push   %ebx
8010616f:	83 ec 1c             	sub    $0x1c,%esp
80106172:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
80106175:	85 f6                	test   %esi,%esi
80106177:	0f 84 dd 00 00 00    	je     8010625a <switchuvm+0xf1>
    panic("switchuvm: no process");
  if(p->kstack == 0)
8010617d:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
80106181:	0f 84 e0 00 00 00    	je     80106267 <switchuvm+0xfe>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
80106187:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
8010618b:	0f 84 e3 00 00 00    	je     80106274 <switchuvm+0x10b>
    panic("switchuvm: no pgdir");

  pushcli();
80106191:	e8 5d dc ff ff       	call   80103df3 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80106196:	e8 1c d3 ff ff       	call   801034b7 <mycpu>
8010619b:	89 c3                	mov    %eax,%ebx
8010619d:	e8 15 d3 ff ff       	call   801034b7 <mycpu>
801061a2:	8d 78 08             	lea    0x8(%eax),%edi
801061a5:	e8 0d d3 ff ff       	call   801034b7 <mycpu>
801061aa:	83 c0 08             	add    $0x8,%eax
801061ad:	c1 e8 10             	shr    $0x10,%eax
801061b0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801061b3:	e8 ff d2 ff ff       	call   801034b7 <mycpu>
801061b8:	83 c0 08             	add    $0x8,%eax
801061bb:	c1 e8 18             	shr    $0x18,%eax
801061be:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
801061c5:	67 00 
801061c7:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
801061ce:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
801061d2:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
801061d8:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
801061df:	83 e2 f0             	and    $0xfffffff0,%edx
801061e2:	83 ca 19             	or     $0x19,%edx
801061e5:	83 e2 9f             	and    $0xffffff9f,%edx
801061e8:	83 ca 80             	or     $0xffffff80,%edx
801061eb:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
801061f1:	c6 83 9e 00 00 00 40 	movb   $0x40,0x9e(%ebx)
801061f8:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
801061fe:	e8 b4 d2 ff ff       	call   801034b7 <mycpu>
80106203:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010620a:	83 e2 ef             	and    $0xffffffef,%edx
8010620d:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80106213:	e8 9f d2 ff ff       	call   801034b7 <mycpu>
80106218:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
8010621e:	8b 5e 08             	mov    0x8(%esi),%ebx
80106221:	e8 91 d2 ff ff       	call   801034b7 <mycpu>
80106226:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010622c:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
8010622f:	e8 83 d2 ff ff       	call   801034b7 <mycpu>
80106234:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
8010623a:	b8 28 00 00 00       	mov    $0x28,%eax
8010623f:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
80106242:	8b 46 04             	mov    0x4(%esi),%eax
80106245:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010624a:	0f 22 d8             	mov    %eax,%cr3
  popcli();
8010624d:	e8 de db ff ff       	call   80103e30 <popcli>
}
80106252:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106255:	5b                   	pop    %ebx
80106256:	5e                   	pop    %esi
80106257:	5f                   	pop    %edi
80106258:	5d                   	pop    %ebp
80106259:	c3                   	ret    
    panic("switchuvm: no process");
8010625a:	83 ec 0c             	sub    $0xc,%esp
8010625d:	68 b2 70 10 80       	push   $0x801070b2
80106262:	e8 e1 a0 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
80106267:	83 ec 0c             	sub    $0xc,%esp
8010626a:	68 c8 70 10 80       	push   $0x801070c8
8010626f:	e8 d4 a0 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
80106274:	83 ec 0c             	sub    $0xc,%esp
80106277:	68 dd 70 10 80       	push   $0x801070dd
8010627c:	e8 c7 a0 ff ff       	call   80100348 <panic>

80106281 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80106281:	55                   	push   %ebp
80106282:	89 e5                	mov    %esp,%ebp
80106284:	56                   	push   %esi
80106285:	53                   	push   %ebx
80106286:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
80106289:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
8010628f:	77 4c                	ja     801062dd <inituvm+0x5c>
    panic("inituvm: more than a page");
  mem = kalloc();
80106291:	e8 1c bf ff ff       	call   801021b2 <kalloc>
80106296:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
80106298:	83 ec 04             	sub    $0x4,%esp
8010629b:	68 00 10 00 00       	push   $0x1000
801062a0:	6a 00                	push   $0x0
801062a2:	50                   	push   %eax
801062a3:	e8 d4 dc ff ff       	call   80103f7c <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
801062a8:	83 c4 08             	add    $0x8,%esp
801062ab:	6a 06                	push   $0x6
801062ad:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801062b3:	50                   	push   %eax
801062b4:	b9 00 10 00 00       	mov    $0x1000,%ecx
801062b9:	ba 00 00 00 00       	mov    $0x0,%edx
801062be:	8b 45 08             	mov    0x8(%ebp),%eax
801062c1:	e8 cf fc ff ff       	call   80105f95 <mappages>
  memmove(mem, init, sz);
801062c6:	83 c4 0c             	add    $0xc,%esp
801062c9:	56                   	push   %esi
801062ca:	ff 75 0c             	pushl  0xc(%ebp)
801062cd:	53                   	push   %ebx
801062ce:	e8 24 dd ff ff       	call   80103ff7 <memmove>
}
801062d3:	83 c4 10             	add    $0x10,%esp
801062d6:	8d 65 f8             	lea    -0x8(%ebp),%esp
801062d9:	5b                   	pop    %ebx
801062da:	5e                   	pop    %esi
801062db:	5d                   	pop    %ebp
801062dc:	c3                   	ret    
    panic("inituvm: more than a page");
801062dd:	83 ec 0c             	sub    $0xc,%esp
801062e0:	68 f1 70 10 80       	push   $0x801070f1
801062e5:	e8 5e a0 ff ff       	call   80100348 <panic>

801062ea <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
801062ea:	55                   	push   %ebp
801062eb:	89 e5                	mov    %esp,%ebp
801062ed:	57                   	push   %edi
801062ee:	56                   	push   %esi
801062ef:	53                   	push   %ebx
801062f0:	83 ec 0c             	sub    $0xc,%esp
801062f3:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
801062f6:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
801062fd:	75 07                	jne    80106306 <loaduvm+0x1c>
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
801062ff:	bb 00 00 00 00       	mov    $0x0,%ebx
80106304:	eb 3c                	jmp    80106342 <loaduvm+0x58>
    panic("loaduvm: addr must be page aligned");
80106306:	83 ec 0c             	sub    $0xc,%esp
80106309:	68 ac 71 10 80       	push   $0x801071ac
8010630e:	e8 35 a0 ff ff       	call   80100348 <panic>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
80106313:	83 ec 0c             	sub    $0xc,%esp
80106316:	68 0b 71 10 80       	push   $0x8010710b
8010631b:	e8 28 a0 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
80106320:	05 00 00 00 80       	add    $0x80000000,%eax
80106325:	56                   	push   %esi
80106326:	89 da                	mov    %ebx,%edx
80106328:	03 55 14             	add    0x14(%ebp),%edx
8010632b:	52                   	push   %edx
8010632c:	50                   	push   %eax
8010632d:	ff 75 10             	pushl  0x10(%ebp)
80106330:	e8 4a b4 ff ff       	call   8010177f <readi>
80106335:	83 c4 10             	add    $0x10,%esp
80106338:	39 f0                	cmp    %esi,%eax
8010633a:	75 47                	jne    80106383 <loaduvm+0x99>
  for(i = 0; i < sz; i += PGSIZE){
8010633c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106342:	39 fb                	cmp    %edi,%ebx
80106344:	73 30                	jae    80106376 <loaduvm+0x8c>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80106346:	89 da                	mov    %ebx,%edx
80106348:	03 55 0c             	add    0xc(%ebp),%edx
8010634b:	b9 00 00 00 00       	mov    $0x0,%ecx
80106350:	8b 45 08             	mov    0x8(%ebp),%eax
80106353:	e8 cd fb ff ff       	call   80105f25 <walkpgdir>
80106358:	85 c0                	test   %eax,%eax
8010635a:	74 b7                	je     80106313 <loaduvm+0x29>
    pa = PTE_ADDR(*pte);
8010635c:	8b 00                	mov    (%eax),%eax
8010635e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
80106363:	89 fe                	mov    %edi,%esi
80106365:	29 de                	sub    %ebx,%esi
80106367:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
8010636d:	76 b1                	jbe    80106320 <loaduvm+0x36>
      n = PGSIZE;
8010636f:	be 00 10 00 00       	mov    $0x1000,%esi
80106374:	eb aa                	jmp    80106320 <loaduvm+0x36>
      return -1;
  }
  return 0;
80106376:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010637b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010637e:	5b                   	pop    %ebx
8010637f:	5e                   	pop    %esi
80106380:	5f                   	pop    %edi
80106381:	5d                   	pop    %ebp
80106382:	c3                   	ret    
      return -1;
80106383:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106388:	eb f1                	jmp    8010637b <loaduvm+0x91>

8010638a <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010638a:	55                   	push   %ebp
8010638b:	89 e5                	mov    %esp,%ebp
8010638d:	57                   	push   %edi
8010638e:	56                   	push   %esi
8010638f:	53                   	push   %ebx
80106390:	83 ec 0c             	sub    $0xc,%esp
80106393:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80106396:	39 7d 10             	cmp    %edi,0x10(%ebp)
80106399:	73 11                	jae    801063ac <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
8010639b:	8b 45 10             	mov    0x10(%ebp),%eax
8010639e:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
801063a4:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801063aa:	eb 19                	jmp    801063c5 <deallocuvm+0x3b>
    return oldsz;
801063ac:	89 f8                	mov    %edi,%eax
801063ae:	eb 64                	jmp    80106414 <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
801063b0:	c1 eb 16             	shr    $0x16,%ebx
801063b3:	83 c3 01             	add    $0x1,%ebx
801063b6:	c1 e3 16             	shl    $0x16,%ebx
801063b9:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
801063bf:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801063c5:	39 fb                	cmp    %edi,%ebx
801063c7:	73 48                	jae    80106411 <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
801063c9:	b9 00 00 00 00       	mov    $0x0,%ecx
801063ce:	89 da                	mov    %ebx,%edx
801063d0:	8b 45 08             	mov    0x8(%ebp),%eax
801063d3:	e8 4d fb ff ff       	call   80105f25 <walkpgdir>
801063d8:	89 c6                	mov    %eax,%esi
    if(!pte)
801063da:	85 c0                	test   %eax,%eax
801063dc:	74 d2                	je     801063b0 <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
801063de:	8b 00                	mov    (%eax),%eax
801063e0:	a8 01                	test   $0x1,%al
801063e2:	74 db                	je     801063bf <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
801063e4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801063e9:	74 19                	je     80106404 <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
801063eb:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801063f0:	83 ec 0c             	sub    $0xc,%esp
801063f3:	50                   	push   %eax
801063f4:	e8 b7 bb ff ff       	call   80101fb0 <kfree>
      *pte = 0;
801063f9:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
801063ff:	83 c4 10             	add    $0x10,%esp
80106402:	eb bb                	jmp    801063bf <deallocuvm+0x35>
        panic("kfree");
80106404:	83 ec 0c             	sub    $0xc,%esp
80106407:	68 46 6a 10 80       	push   $0x80106a46
8010640c:	e8 37 9f ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
80106411:	8b 45 10             	mov    0x10(%ebp),%eax
}
80106414:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106417:	5b                   	pop    %ebx
80106418:	5e                   	pop    %esi
80106419:	5f                   	pop    %edi
8010641a:	5d                   	pop    %ebp
8010641b:	c3                   	ret    

8010641c <allocuvm>:
{
8010641c:	55                   	push   %ebp
8010641d:	89 e5                	mov    %esp,%ebp
8010641f:	57                   	push   %edi
80106420:	56                   	push   %esi
80106421:	53                   	push   %ebx
80106422:	83 ec 1c             	sub    $0x1c,%esp
80106425:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
80106428:	89 7d e4             	mov    %edi,-0x1c(%ebp)
8010642b:	85 ff                	test   %edi,%edi
8010642d:	0f 88 ca 00 00 00    	js     801064fd <allocuvm+0xe1>
  if(newsz < oldsz)
80106433:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106436:	72 65                	jb     8010649d <allocuvm+0x81>
  a = PGROUNDUP(oldsz);
80106438:	8b 45 0c             	mov    0xc(%ebp),%eax
8010643b:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
80106441:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a < newsz; a += PGSIZE){
80106447:	39 fb                	cmp    %edi,%ebx
80106449:	0f 83 b5 00 00 00    	jae    80106504 <allocuvm+0xe8>
    mem = kalloc2(pid);
8010644f:	83 ec 0c             	sub    $0xc,%esp
80106452:	ff 75 14             	pushl  0x14(%ebp)
80106455:	e8 24 be ff ff       	call   8010227e <kalloc2>
8010645a:	89 c6                	mov    %eax,%esi
    if(mem == 0){
8010645c:	83 c4 10             	add    $0x10,%esp
8010645f:	85 c0                	test   %eax,%eax
80106461:	74 42                	je     801064a5 <allocuvm+0x89>
    memset(mem, 0, PGSIZE);
80106463:	83 ec 04             	sub    $0x4,%esp
80106466:	68 00 10 00 00       	push   $0x1000
8010646b:	6a 00                	push   $0x0
8010646d:	50                   	push   %eax
8010646e:	e8 09 db ff ff       	call   80103f7c <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
80106473:	83 c4 08             	add    $0x8,%esp
80106476:	6a 06                	push   $0x6
80106478:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
8010647e:	50                   	push   %eax
8010647f:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106484:	89 da                	mov    %ebx,%edx
80106486:	8b 45 08             	mov    0x8(%ebp),%eax
80106489:	e8 07 fb ff ff       	call   80105f95 <mappages>
8010648e:	83 c4 10             	add    $0x10,%esp
80106491:	85 c0                	test   %eax,%eax
80106493:	78 38                	js     801064cd <allocuvm+0xb1>
  for(; a < newsz; a += PGSIZE){
80106495:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010649b:	eb aa                	jmp    80106447 <allocuvm+0x2b>
    return oldsz;
8010649d:	8b 45 0c             	mov    0xc(%ebp),%eax
801064a0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801064a3:	eb 5f                	jmp    80106504 <allocuvm+0xe8>
      cprintf("allocuvm out of memory\n");
801064a5:	83 ec 0c             	sub    $0xc,%esp
801064a8:	68 29 71 10 80       	push   $0x80107129
801064ad:	e8 59 a1 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801064b2:	83 c4 0c             	add    $0xc,%esp
801064b5:	ff 75 0c             	pushl  0xc(%ebp)
801064b8:	57                   	push   %edi
801064b9:	ff 75 08             	pushl  0x8(%ebp)
801064bc:	e8 c9 fe ff ff       	call   8010638a <deallocuvm>
      return 0;
801064c1:	83 c4 10             	add    $0x10,%esp
801064c4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801064cb:	eb 37                	jmp    80106504 <allocuvm+0xe8>
      cprintf("allocuvm out of memory (2)\n");
801064cd:	83 ec 0c             	sub    $0xc,%esp
801064d0:	68 41 71 10 80       	push   $0x80107141
801064d5:	e8 31 a1 ff ff       	call   8010060b <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801064da:	83 c4 0c             	add    $0xc,%esp
801064dd:	ff 75 0c             	pushl  0xc(%ebp)
801064e0:	57                   	push   %edi
801064e1:	ff 75 08             	pushl  0x8(%ebp)
801064e4:	e8 a1 fe ff ff       	call   8010638a <deallocuvm>
      kfree(mem);
801064e9:	89 34 24             	mov    %esi,(%esp)
801064ec:	e8 bf ba ff ff       	call   80101fb0 <kfree>
      return 0;
801064f1:	83 c4 10             	add    $0x10,%esp
801064f4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801064fb:	eb 07                	jmp    80106504 <allocuvm+0xe8>
    return 0;
801064fd:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
80106504:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106507:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010650a:	5b                   	pop    %ebx
8010650b:	5e                   	pop    %esi
8010650c:	5f                   	pop    %edi
8010650d:	5d                   	pop    %ebp
8010650e:	c3                   	ret    

8010650f <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
8010650f:	55                   	push   %ebp
80106510:	89 e5                	mov    %esp,%ebp
80106512:	56                   	push   %esi
80106513:	53                   	push   %ebx
80106514:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
80106517:	85 f6                	test   %esi,%esi
80106519:	74 1a                	je     80106535 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
8010651b:	83 ec 04             	sub    $0x4,%esp
8010651e:	6a 00                	push   $0x0
80106520:	68 00 00 00 80       	push   $0x80000000
80106525:	56                   	push   %esi
80106526:	e8 5f fe ff ff       	call   8010638a <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
8010652b:	83 c4 10             	add    $0x10,%esp
8010652e:	bb 00 00 00 00       	mov    $0x0,%ebx
80106533:	eb 10                	jmp    80106545 <freevm+0x36>
    panic("freevm: no pgdir");
80106535:	83 ec 0c             	sub    $0xc,%esp
80106538:	68 5d 71 10 80       	push   $0x8010715d
8010653d:	e8 06 9e ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
80106542:	83 c3 01             	add    $0x1,%ebx
80106545:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
8010654b:	77 1f                	ja     8010656c <freevm+0x5d>
    if(pgdir[i] & PTE_P){
8010654d:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
80106550:	a8 01                	test   $0x1,%al
80106552:	74 ee                	je     80106542 <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
80106554:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80106559:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
8010655e:	83 ec 0c             	sub    $0xc,%esp
80106561:	50                   	push   %eax
80106562:	e8 49 ba ff ff       	call   80101fb0 <kfree>
80106567:	83 c4 10             	add    $0x10,%esp
8010656a:	eb d6                	jmp    80106542 <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
8010656c:	83 ec 0c             	sub    $0xc,%esp
8010656f:	56                   	push   %esi
80106570:	e8 3b ba ff ff       	call   80101fb0 <kfree>
}
80106575:	83 c4 10             	add    $0x10,%esp
80106578:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010657b:	5b                   	pop    %ebx
8010657c:	5e                   	pop    %esi
8010657d:	5d                   	pop    %ebp
8010657e:	c3                   	ret    

8010657f <setupkvm>:
{
8010657f:	55                   	push   %ebp
80106580:	89 e5                	mov    %esp,%ebp
80106582:	56                   	push   %esi
80106583:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc()) == 0)
80106584:	e8 29 bc ff ff       	call   801021b2 <kalloc>
80106589:	89 c6                	mov    %eax,%esi
8010658b:	85 c0                	test   %eax,%eax
8010658d:	74 55                	je     801065e4 <setupkvm+0x65>
  memset(pgdir, 0, PGSIZE);
8010658f:	83 ec 04             	sub    $0x4,%esp
80106592:	68 00 10 00 00       	push   $0x1000
80106597:	6a 00                	push   $0x0
80106599:	50                   	push   %eax
8010659a:	e8 dd d9 ff ff       	call   80103f7c <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010659f:	83 c4 10             	add    $0x10,%esp
801065a2:	bb 20 a4 10 80       	mov    $0x8010a420,%ebx
801065a7:	81 fb 60 a4 10 80    	cmp    $0x8010a460,%ebx
801065ad:	73 35                	jae    801065e4 <setupkvm+0x65>
                (uint)k->phys_start, k->perm) < 0) {
801065af:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
801065b2:	8b 4b 08             	mov    0x8(%ebx),%ecx
801065b5:	29 c1                	sub    %eax,%ecx
801065b7:	83 ec 08             	sub    $0x8,%esp
801065ba:	ff 73 0c             	pushl  0xc(%ebx)
801065bd:	50                   	push   %eax
801065be:	8b 13                	mov    (%ebx),%edx
801065c0:	89 f0                	mov    %esi,%eax
801065c2:	e8 ce f9 ff ff       	call   80105f95 <mappages>
801065c7:	83 c4 10             	add    $0x10,%esp
801065ca:	85 c0                	test   %eax,%eax
801065cc:	78 05                	js     801065d3 <setupkvm+0x54>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801065ce:	83 c3 10             	add    $0x10,%ebx
801065d1:	eb d4                	jmp    801065a7 <setupkvm+0x28>
      freevm(pgdir);
801065d3:	83 ec 0c             	sub    $0xc,%esp
801065d6:	56                   	push   %esi
801065d7:	e8 33 ff ff ff       	call   8010650f <freevm>
      return 0;
801065dc:	83 c4 10             	add    $0x10,%esp
801065df:	be 00 00 00 00       	mov    $0x0,%esi
}
801065e4:	89 f0                	mov    %esi,%eax
801065e6:	8d 65 f8             	lea    -0x8(%ebp),%esp
801065e9:	5b                   	pop    %ebx
801065ea:	5e                   	pop    %esi
801065eb:	5d                   	pop    %ebp
801065ec:	c3                   	ret    

801065ed <kvmalloc>:
{
801065ed:	55                   	push   %ebp
801065ee:	89 e5                	mov    %esp,%ebp
801065f0:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
801065f3:	e8 87 ff ff ff       	call   8010657f <setupkvm>
801065f8:	a3 a4 71 14 80       	mov    %eax,0x801471a4
  switchkvm();
801065fd:	e8 55 fb ff ff       	call   80106157 <switchkvm>
}
80106602:	c9                   	leave  
80106603:	c3                   	ret    

80106604 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80106604:	55                   	push   %ebp
80106605:	89 e5                	mov    %esp,%ebp
80106607:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010660a:	b9 00 00 00 00       	mov    $0x0,%ecx
8010660f:	8b 55 0c             	mov    0xc(%ebp),%edx
80106612:	8b 45 08             	mov    0x8(%ebp),%eax
80106615:	e8 0b f9 ff ff       	call   80105f25 <walkpgdir>
  if(pte == 0)
8010661a:	85 c0                	test   %eax,%eax
8010661c:	74 05                	je     80106623 <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
8010661e:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
80106621:	c9                   	leave  
80106622:	c3                   	ret    
    panic("clearpteu");
80106623:	83 ec 0c             	sub    $0xc,%esp
80106626:	68 6e 71 10 80       	push   $0x8010716e
8010662b:	e8 18 9d ff ff       	call   80100348 <panic>

80106630 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz, int pid)
{
80106630:	55                   	push   %ebp
80106631:	89 e5                	mov    %esp,%ebp
80106633:	57                   	push   %edi
80106634:	56                   	push   %esi
80106635:	53                   	push   %ebx
80106636:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
80106639:	e8 41 ff ff ff       	call   8010657f <setupkvm>
8010663e:	89 45 dc             	mov    %eax,-0x24(%ebp)
80106641:	85 c0                	test   %eax,%eax
80106643:	0f 84 d1 00 00 00    	je     8010671a <copyuvm+0xea>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80106649:	bf 00 00 00 00       	mov    $0x0,%edi
8010664e:	89 fe                	mov    %edi,%esi
80106650:	3b 75 0c             	cmp    0xc(%ebp),%esi
80106653:	0f 83 c1 00 00 00    	jae    8010671a <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80106659:	89 75 e4             	mov    %esi,-0x1c(%ebp)
8010665c:	b9 00 00 00 00       	mov    $0x0,%ecx
80106661:	89 f2                	mov    %esi,%edx
80106663:	8b 45 08             	mov    0x8(%ebp),%eax
80106666:	e8 ba f8 ff ff       	call   80105f25 <walkpgdir>
8010666b:	85 c0                	test   %eax,%eax
8010666d:	74 70                	je     801066df <copyuvm+0xaf>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
8010666f:	8b 18                	mov    (%eax),%ebx
80106671:	f6 c3 01             	test   $0x1,%bl
80106674:	74 76                	je     801066ec <copyuvm+0xbc>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
80106676:	89 df                	mov    %ebx,%edi
80106678:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
    flags = PTE_FLAGS(*pte);
8010667e:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
80106684:	89 5d e0             	mov    %ebx,-0x20(%ebp)
    if((mem = kalloc2(pid)) == 0)
80106687:	83 ec 0c             	sub    $0xc,%esp
8010668a:	ff 75 10             	pushl  0x10(%ebp)
8010668d:	e8 ec bb ff ff       	call   8010227e <kalloc2>
80106692:	89 c3                	mov    %eax,%ebx
80106694:	83 c4 10             	add    $0x10,%esp
80106697:	85 c0                	test   %eax,%eax
80106699:	74 6a                	je     80106705 <copyuvm+0xd5>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
8010669b:	81 c7 00 00 00 80    	add    $0x80000000,%edi
801066a1:	83 ec 04             	sub    $0x4,%esp
801066a4:	68 00 10 00 00       	push   $0x1000
801066a9:	57                   	push   %edi
801066aa:	50                   	push   %eax
801066ab:	e8 47 d9 ff ff       	call   80103ff7 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
801066b0:	83 c4 08             	add    $0x8,%esp
801066b3:	ff 75 e0             	pushl  -0x20(%ebp)
801066b6:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801066bc:	50                   	push   %eax
801066bd:	b9 00 10 00 00       	mov    $0x1000,%ecx
801066c2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801066c5:	8b 45 dc             	mov    -0x24(%ebp),%eax
801066c8:	e8 c8 f8 ff ff       	call   80105f95 <mappages>
801066cd:	83 c4 10             	add    $0x10,%esp
801066d0:	85 c0                	test   %eax,%eax
801066d2:	78 25                	js     801066f9 <copyuvm+0xc9>
  for(i = 0; i < sz; i += PGSIZE){
801066d4:	81 c6 00 10 00 00    	add    $0x1000,%esi
801066da:	e9 71 ff ff ff       	jmp    80106650 <copyuvm+0x20>
      panic("copyuvm: pte should exist");
801066df:	83 ec 0c             	sub    $0xc,%esp
801066e2:	68 78 71 10 80       	push   $0x80107178
801066e7:	e8 5c 9c ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
801066ec:	83 ec 0c             	sub    $0xc,%esp
801066ef:	68 92 71 10 80       	push   $0x80107192
801066f4:	e8 4f 9c ff ff       	call   80100348 <panic>
      kfree(mem);
801066f9:	83 ec 0c             	sub    $0xc,%esp
801066fc:	53                   	push   %ebx
801066fd:	e8 ae b8 ff ff       	call   80101fb0 <kfree>
      goto bad;
80106702:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
80106705:	83 ec 0c             	sub    $0xc,%esp
80106708:	ff 75 dc             	pushl  -0x24(%ebp)
8010670b:	e8 ff fd ff ff       	call   8010650f <freevm>
  return 0;
80106710:	83 c4 10             	add    $0x10,%esp
80106713:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
8010671a:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010671d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106720:	5b                   	pop    %ebx
80106721:	5e                   	pop    %esi
80106722:	5f                   	pop    %edi
80106723:	5d                   	pop    %ebp
80106724:	c3                   	ret    

80106725 <uva2ka>:

// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80106725:	55                   	push   %ebp
80106726:	89 e5                	mov    %esp,%ebp
80106728:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010672b:	b9 00 00 00 00       	mov    $0x0,%ecx
80106730:	8b 55 0c             	mov    0xc(%ebp),%edx
80106733:	8b 45 08             	mov    0x8(%ebp),%eax
80106736:	e8 ea f7 ff ff       	call   80105f25 <walkpgdir>
  if((*pte & PTE_P) == 0)
8010673b:	8b 00                	mov    (%eax),%eax
8010673d:	a8 01                	test   $0x1,%al
8010673f:	74 10                	je     80106751 <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
80106741:	a8 04                	test   $0x4,%al
80106743:	74 13                	je     80106758 <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
80106745:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010674a:	05 00 00 00 80       	add    $0x80000000,%eax
}
8010674f:	c9                   	leave  
80106750:	c3                   	ret    
    return 0;
80106751:	b8 00 00 00 00       	mov    $0x0,%eax
80106756:	eb f7                	jmp    8010674f <uva2ka+0x2a>
    return 0;
80106758:	b8 00 00 00 00       	mov    $0x0,%eax
8010675d:	eb f0                	jmp    8010674f <uva2ka+0x2a>

8010675f <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
8010675f:	55                   	push   %ebp
80106760:	89 e5                	mov    %esp,%ebp
80106762:	57                   	push   %edi
80106763:	56                   	push   %esi
80106764:	53                   	push   %ebx
80106765:	83 ec 0c             	sub    $0xc,%esp
80106768:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
8010676b:	eb 25                	jmp    80106792 <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
8010676d:	8b 55 0c             	mov    0xc(%ebp),%edx
80106770:	29 f2                	sub    %esi,%edx
80106772:	01 d0                	add    %edx,%eax
80106774:	83 ec 04             	sub    $0x4,%esp
80106777:	53                   	push   %ebx
80106778:	ff 75 10             	pushl  0x10(%ebp)
8010677b:	50                   	push   %eax
8010677c:	e8 76 d8 ff ff       	call   80103ff7 <memmove>
    len -= n;
80106781:	29 df                	sub    %ebx,%edi
    buf += n;
80106783:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
80106786:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
8010678c:	89 45 0c             	mov    %eax,0xc(%ebp)
8010678f:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
80106792:	85 ff                	test   %edi,%edi
80106794:	74 2f                	je     801067c5 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
80106796:	8b 75 0c             	mov    0xc(%ebp),%esi
80106799:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
8010679f:	83 ec 08             	sub    $0x8,%esp
801067a2:	56                   	push   %esi
801067a3:	ff 75 08             	pushl  0x8(%ebp)
801067a6:	e8 7a ff ff ff       	call   80106725 <uva2ka>
    if(pa0 == 0)
801067ab:	83 c4 10             	add    $0x10,%esp
801067ae:	85 c0                	test   %eax,%eax
801067b0:	74 20                	je     801067d2 <copyout+0x73>
    n = PGSIZE - (va - va0);
801067b2:	89 f3                	mov    %esi,%ebx
801067b4:	2b 5d 0c             	sub    0xc(%ebp),%ebx
801067b7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
801067bd:	39 df                	cmp    %ebx,%edi
801067bf:	73 ac                	jae    8010676d <copyout+0xe>
      n = len;
801067c1:	89 fb                	mov    %edi,%ebx
801067c3:	eb a8                	jmp    8010676d <copyout+0xe>
  }
  return 0;
801067c5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801067ca:	8d 65 f4             	lea    -0xc(%ebp),%esp
801067cd:	5b                   	pop    %ebx
801067ce:	5e                   	pop    %esi
801067cf:	5f                   	pop    %edi
801067d0:	5d                   	pop    %ebp
801067d1:	c3                   	ret    
      return -1;
801067d2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067d7:	eb f1                	jmp    801067ca <copyout+0x6b>
