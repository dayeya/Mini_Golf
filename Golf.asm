; Assembly Project - Mini Golf. 
; creator - Daniel sapojnikov, ID - 215673369
; Date of submission - 12.06.2022
; School - De Shalit High School
; Teacher - Guy Shenhav 

; Thanks to the educational team, friends and family.
 

.386 ; .386 in order to use far jumps
IDEAL
MODEL small
STACK 100h
DATASEG
	;gravity equ 0100111001110b ;9.807m/s^2
	Clock equ es:6Ch
	
	subPixel equ 0
	maxVelocity equ 22
	minVelocity equ 1
	frictionFactor equ 2
	
	
	filename_start db 'start.bmp',0 ; picture
	filename_rules db 'rules.bmp',0 
	filename_back_menu db 'backMenu.bmp',0
	filename_game db 'game.bmp',0
	filehandle dw 0 
	Header db 54 dup (0)
	Palette db 256*4 dup (0)
	ScrLine db 320 dup (0) ; picture

	endMsg db 'Thank you for playing the game',13,10,'$'
	ErrorMsg db 'Error in loading', 13, 10 ,'$'
	strokes db 'Strokes: ' 
	nameGame db 'Mini Golf'
	
	range dw 0
	released dw 0
	
	; music
	note dw 1750h
	; music
	pointX dw 0
	pointY dw 0
	virX dw 0 
	virY dw 0
	color dw 15
	
	holeX dw 300
	holeY dw 100
	colorHole dw 8
	;line db "Physics$"
	msgFix db "Click the left button for execution$"
	
	;Draw ball offsets
	xOffsets dw 1, 2, 0, 1, 2, 3, 0, 1, 2, 3, 1, 2
	yOffsets dw 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3
	;Draw ball offsets
	
	;Draw hole offsets
	;xHoleOffsets dw 1,2,3,4,5,6, 0,1,2,3,4,5,6,7 ,0,1,2,3,4,5,6,7 ,0,1,2,3,4,5,6,7 ,0,1,2,3,4,5,6,7 ,0,1,2,3,4,5,6,7 ,0,1,2,3,4,5,6,7 ,1,2,3,4,5,6
	;yHoleOffsets dw 0,0,0,0,0,0, 1,1,1,1,1,1,1,1 ,2,2,2,2,2,2,2,2 ,3,3,3,3,3,3,3,3 ,4,4,4,4,4,4,4,4 ,5,5,5,5,5,5,5,5 ,6,6,6,6,6,6,6,6 ,7,7,7,7,7,7
	;Draw hole offsets
	
	twoWord dw 2 
	
	; boolean variable
	mouseDown db 0 
	hitWall db 0 
	hitWallGeneral db 0
	; boolean variable
	
	velocity dw 0
	velX dw 0
	velY dw 0
	newVelX dw 0
	newVelY dw 0
;IN: nothing
;OUT: prints 'Mini Golf'
macro strShowName
	;y
	mov bp, seg nameGame
	mov es, bp
	mov bp, offset nameGame
	mov al, 0
	mov bh, 2h
	mov bl, 15
	mov cx, 9
	mov dh, 23
	mov dl, 30
	mov ah, 13h
	int 10h
endm
	
;IN: nothing
;OUT: prints 'Strokes'
macro strShowStrokes
	;a
	mov bp, seg strokes
	mov es, bp
	mov bp, offset strokes
	mov al, 0
	mov bh, 2h
	mov bl, 15
	mov cx, 9
	mov dh, 23
	mov dl, 1
	mov ah, 13h
	int 10h
endm

;IN: nothing
;OUT: updates the strokes number
macro strChange 
	;i
	mov dl, 10
    mov dh, 23
    mov bh, 0
    mov ah, 02h
    int 10h
	
    mov dl, ' ' 
    mov bl, 0   
    mov bh, 0
    mov ah, 02h
	
	;clearing the last digit
    mov cx, 9
	loopForClear:
    int 10h
    loop loopForClear
	;clearing the last digit
	mov dl, 10
    mov dh, 23
    mov bh, 0
    mov ah, 02h
    int 10h
	
	mov ax,[released]
	call printNum
endm

CODESEG
proc printNum 
	;r
    ;initialize count
    mov cx,0
    mov dx,0
    label1:
        ; if ax is zero
        cmp ax,0
        je print1     
        
        ;initialize bx to 10
        mov bx,10       
        
        ; extract the last digit
        div bx                 
         
        ;push it in the stack
        push dx             
         
        ;increment the count
        inc cx             
         
        ;set dx to 0
        xor dx,dx
        jmp label1
    print1:
        ;check if count
        ;is greater than zero
        cmp cx,0
        je exitProc
         
        ;pop the top of stack
        pop dx
         
        ;add 48 so that it
        ;represents the ASCII
        ;value of digits
        add dx,48
        
        ;interrupt to print a
        ;character
        mov ah,02h
        int 21h
         
        ;decrease the count
        dec cx
        jmp print1
exitProc:
ret
endp printNum 
; -------------GUI functions-------------

proc releaseNote
	;m
	; open speaker
	in al, 61h
	or al, 00000011b
	out 61h, al
	; send control word to change frequency
	mov al, 0B6h
	out 43h, al
	; play frequency 131Hz
	mov ax, [note]
	out 42h, al ; Sending lower byte
	mov al, ah
	out 42h, al ; Sending upper byte
	call delay_ball
	in al, 61h
	and al, 11111100b
	out 61h, al
	
endp releaseNote

proc CloseFileBMP ;proc to close the bmp file before printing another one
;a
  mov ah, 3Eh
  mov bx, [filehandle]
  int 21h
  ret
endp CloseFileBMP

proc OpenFile_start
;o
	; Open file
	mov ah, 3Dh
	xor al, al
	mov dx, offset filename_start
	int 21h
	jc openerror
	mov [filehandle], ax
	ret
	openerror:
		mov dx, offset ErrorMsg
		mov ah, 9h
		int 21h
	ret
endp OpenFile_start

proc OpenFile_rules
;z
	; Open file
	mov ah, 3Dh
	xor al, al
	mov dx, offset filename_rules
	int 21h
	jc openerror_rules
	mov [filehandle], ax
	ret
	openerror_rules:
		mov dx, offset ErrorMsg
		mov ah, 9h
		int 21h
	ret
endp OpenFile_rules

proc OpenFile_back_menu
	; Open file
	mov ah, 3Dh
	xor al, al
	mov dx, offset filename_back_menu
	int 21h
	jc openerror_back_menu
	mov [filehandle], ax
	ret
	openerror_back_menu:
		mov dx, offset ErrorMsg
		mov ah, 9h
		int 21h
	ret
endp OpenFile_back_menu

proc OpenFile_game
	; Open file
	mov ah, 3Dh
	xor al, al
	mov dx, offset filename_game
	int 21h
	jc openerror_game
	mov [filehandle], ax
	ret
	openerror_game:
		mov dx, offset ErrorMsg
		mov ah, 9h
		int 21h
	ret
endp OpenFile_game

proc ReadHeader 
	; Read BMP file header, 54 bytes
	mov ah,3fh
	mov bx, [filehandle]
	mov cx,54
	mov dx,offset Header
	int 21h
	ret
endp ReadHeader

proc ReadPalette
	; Read BMP file color palette, 256 colors * 4 bytes (400h)
	mov ah,3fh
	mov cx,400h 
	mov dx,offset Palette
	int 21h 
	ret
endp ReadPalette

proc CopyPal 
	; Copy the colors palette to the video memory 
	; The number of the first color should be sent to port 3C8h
	; The palette is sent to port 3C9h
	mov si,offset Palette 
	mov cx,256 
	mov dx,3C8h
	mov al,0 
	; Copy starting color to port 3C8h
	out dx,al
	; Copy palette itself to port 3C9h 
	inc dx 
	PalLoop:
	; Note: Colors in a BMP file are saved as BGR values rather than RGB 
	mov al,[si + 2] ; Get red value 
	shr al,2 ; Max. is 255, but video palette maximal
	; value is 63. Therefore dividing by 4
	out dx,al ; Send it 
	mov al,[si+1] ; Get green value 
	shr al,2
	out dx,al ; Send it 
	mov al,[si] ; Get blue value 
	shr al,2
	out dx,al ; Send it 
	add si,4 ; Point to next color 
	; (There is a null chr. after every color.)
	loop PalLoop
	ret
endp CopyPal

proc CopyBitmap
	; BMP graphics are saved upside-down .
	; Read the graphic line by line (200 lines in VGA format),
	; displaying the lines from bottom to top. 
	mov ax, 0A000h
	mov es, ax
	mov cx,200 
	PrintBMPLoop :
	push cx
	; di = cx*320, point to the correct screen line
	mov di,cx 
	shl cx,6 
	shl di,8 
	add di,cx
	; Read one line
	mov ah,3fh
	mov cx,320
	mov dx,offset ScrLine
	int 21h 
	; Copy one line into video memory
	cld ; Clear direction flag, for movsb
	mov cx,320
	mov si,offset ScrLine
	rep movsb ; Copy line to the screen 
	 ;rep movsb is same as the following code :
	 ;mov es:di, ds:si
	 ;inc si
	 ;inc di
	 ;dec cx
	;loop until cx=0
	pop cx
	loop PrintBMPLoop
	ret
endp CopyBitmap

proc msg_holding_point
	mov dx, offset msgFix
	mov ah, 9h
	int 21h
	ret
endp msg_holding_point

proc textMode
	mov ah, 0h ; text mode
	mov al,2h
	int 10h
	ret
endp textMode

proc graphicsMode
	mov ax,13h ; graphics mode
	int 10h
	ret
endp graphicsMode

proc game_screen
	call OpenFile_game
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
	call CloseFileBMP
	ret
endp game_screen

proc start_screen ; printing the menu
	call OpenFile_start
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
	call CloseFileBMP
	ret
endp start_screen

proc rules_screen ; printing the rules 
	call OpenFile_rules
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
	call CloseFileBMP
	ret
endp rules_screen

proc back_menu_screen ; printing the game screen
	call OpenFile_back_menu
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
	call CloseFileBMP
	ret
endp back_menu_screen

; -------------GUI functions-------------

; -------------object functions-------------

proc checkBall
	cmp [mouseDown], 0
	jne nextFrame
	cmp [pointY],43
	jle checkUpperBound
	jmp nextFrame
	checkUpperBound: 
		cmp [pointY],31
		jge checkOther
		jmp nextFrame
		checkOther:
			cmp [pointX],286
			jge checkRightBound
			jmp nextFrame
			checkRightBound:
				cmp [pointX],300
				jge nextFrame 
				;call game_screen
				call delay_ball
				jmp backMenu
endp checkBall

proc clearingRec
	mov bx,170
	push [color]
outerLoop:
	inc bx 
	mov cx, 320
	rec:
		mov dx, bx
		mov [color], 0
		push cx
		push dx
		push [color]
		call drawPixel
		dec cx
		cmp cx, 0
		jge rec
		cmp bx,180
		jle outerLoop
	pop [color]
		ret
endp clearingRec

proc drawPixel
	pop bp
	pop ax ;color
	pop dx ;Y position
	pop cx ;X position
	mov bh, 0h
	mov ah,0ch
	int 10h
	push bp
	ret
endp drawPixel


proc drawball
	mov bl,0
	drawBallLoop:
		;push bx
		xor ah, ah ; reseting ah
		mov al, bl ; keeping the counters value
		mul [twoWord] ; ax * 2, 2 is the size of every element of the list
		add ax, offset xOffsets ; adding the base address of the array
		push bx ; pushing bx in order to keep the value of bl
		mov bx, ax ; moving the address of the x-offset to bx
		mov ax, [word ptr bx] ; saving the x-offset to ax because you can only use word prt on bx
		pop bx ; getting the counters value back
		push bx
		mov bx,[pointX]
		shr bx,subPixel
		add ax,bx
		pop bx
		;add ax, [pointX] ; adding the base x-value to the x-offset
		push ax ; pushing as a parameter the final x-value
		
		; same thing for the y
		xor ah, ah
		mov al, bl
		mul [twoWord]
		add ax, offset yOffsets
		push bx
		mov bx, ax
		mov ax, [word ptr bx]
		pop bx
		push bx
		mov bx,[pointY]
		shr bx,subPixel
		add ax,bx
		pop bx
		;add ax, [pointY]
		push ax
		;same thing for the y
		
		push [color] ; pushing as a parameter the color
		call drawPixel ; drawing the pixel
		
		inc bx
		cmp bl,12
		jnz drawBallLoop ; looping 12 times for the ball
	ret
endp drawball

proc deleteBall
	push [color]
	mov [word ptr color], 2
	call drawBall
	pop [color]
	ret
endp deleteBall

; -------------object functions-------------

; -------------mouse functions-------------


proc mouseInitialization
	push ax
	mov ax,0h
	int 33h
	pop ax 
	ret
endp mouseInitialization

proc showMouse
	push ax
	mov ax,01
	int 33h
	pop ax
	ret
endp showMouse

proc hideMouse
	push ax
	mov ax,02h
	int 33h
	pop ax
	ret
endp hideMouse


; -------------mouse functions-------------


; -------------math & physics functions-------------

;generates a random number between 0 - range

proc generateRandom
	pop bp
	pop [word ptr range]
randLoop:
	;getting the random
	mov ax, 40h
    mov es, ax
	mov ax, [Clock] ; get the timer counter
	mov ah, [byte cs:si]  ; read one bye from memory 
	xor al, ah ; xor the memory and counter 
	and ax,11111111b ; limit the result 
	inc si ; si += 1, in order it to be more randomised
	
	xor ah,ah
	cmp ax,[range] ; if the number is not in the range, keep randomising until we get a random number
	ja randLoop
	
	push ax
	push bp 
	ret
endp generateRandom

proc delay_ball
	mov ax, 40h
	mov es, ax
	mov ax, [Clock]
	FirstTick:
		cmp ax, [Clock]
		je FirstTick
	mov cx, 1 ; 1x0.055sec = ~1.65
	DelayLoop:
		mov ax, [Clock]
		Tick:
			cmp ax, [Clock]
			je Tick
		loop DelayLoop
	ret
endp delay_ball

proc pow2
	pop bp 
	pop ax ; value for squaring
	push dx
	imul ax
	and ax, 0111111111111111b
	pop dx  ;keeping dx clear
	push ax ; squared value
	push bp
	ret
endp pow2

proc sqrt
	pop bp
	pop bx ;v^2 - the velocity squared 
	mov dx,0 ;check variable
	sqrtLoop:
		push bp
		push bx
		push dx
		call pow2
		pop ax 
		pop bx 
		pop bp
		cmp ax,bx
		jl incNum
		jg takePreviousNum
		
		;returning the number
		push dx
		push bp
		ret
		;returning the number
		
		incNum:
			inc dx
			jmp sqrtLoop
			
		takePreviousNum: 
			dec dx 
			push dx
			push bp
			ret 
		jmp sqrtLoop
	push bp
	ret 
endp sqrt

proc vectorMultiplication
	pop bp
	;when called - push [N_Y]
	;			   push [N_X]
	;              push [V1_Y]
	;			   push [V1_X]
	
	pop ax ;    V1_X
	pop bx ;    V1_Y
	pop cx ;    N_X
	pop dx ;    N_Y
	
	push dx
	imul cx ; ax * bx --> can be interpreted as V1_X * V2_X
	pop dx
	mov cx,ax
	mov ax,bx
	imul dx; ax * dx --> can be interpreted as V1_Y * V2_Y
	add ax,cx
	push ax
	push bp
	ret
endp vectorMultiplication

;proc taylorSin
	;pop [angle]
	;ret
;endp taylorSin

;proc calc_cos
	
	;ret
;endp calc_cos 

; -------------math & physics functions-------------
proc initializeGame
	menu:
		call textMode 
		call graphicsMode 
		call start_screen
		;keyboard input
		mov ah,1h
		int 21h 
		
		cmp al,70h; if user pressed 'p' then start the game
		je startGame
		cmp al,72h; if user pressed 'r' then move to the rules page, r ascii is 72
		je rules
		cmp al,65h; if user pressed 'e' then close the game
		je exit; in order to close the game, we need to move to text mode
		jmp menu
	startGame:
			call textMode
			call graphicsMode
			call game_screen
			call mouseInitialization
			call showMouse
			
			mov [released], 0
			
			;randomising the balls position every round
			mov [range],170
			push [range]
			call generateRandom
			pop ax
			mov [pointY],ax
			
			xor ax,ax
			
			mov [range],320
			push [range]
			call generateRandom
			pop ax
			mov [pointX],ax
			strShowStrokes
			strShowName
			;randomising the balls position every round
			
			gameLoop:
				push ax
				call deleteBall
				mov ax, 3h ; getting the status of the mouse
				int 33h ; ^
				shr bx,1 ; shifting bx one bit so we can use the carry flag 
				jc checkIfMouseDown ; jump if the left button is down
				;shr bx,1
				;jc printMsg
				jmp mouseNotDown ; jump if the left button is not down
				
				checkIfMouseDown:
					cmp [mouseDown],1
					jz mouseHold
					;this code will run at the first frame of the click
					
					push bx
					
					mov bx,[pointY]
					mov [virY],bx 
					mov bx,[pointX]
					mov [virX],bx 
					
					pop bx
					call drawBall
					mouseHold:
						mov [mouseDown], 1 ; mouseDown = True
						mov [word ptr color],15
					;dragCheck:
						;mov bh,0h
						;mov ah, 0Dh 
						;int 10h
						;cmp al,3
						;jne dragCheck
					shr cx,1 ; cx /= 2, to fit screen
					mov [pointX],cx
					mov [pointY],dx
					call drawball
					;dragging
					jmp afterMouseCheck ; after the mouse click
				mouseNotDown:
					cmp [mouseDown], 1 ; checking if the mouse if pressed (mouseDown == True)
					jnz afterLeftClickReleasedCheck ; mouseDown != 1, we change the balls position,	left click was released this frame
 													; we move the ball if the user dragged the ball	
					; velocityY = pointY - mouseY
					mov bx, [virY]
					sub bx, [pointY]
					mov [velY],bx
					
					mov bx,[virY]
					mov [pointY],bx
					
					; velocityX = pointX - mouseX
					
					mov bx, [virX]
					sub bx, [pointX]
					mov [velX],bx
					
					mov bx,[virX]
					mov [pointX],bx
					
					;calc velocity 
					push [word ptr velX]
					call pow2
					pop bx
					push [word ptr velY] 
					call pow2 
					pop ax
					add ax,bx
					push ax
					call sqrt
					;calc velocity
					
					pop ax ; ax keeps the velocity of the ball : |v| = sqrt(Vx^2 + Vy^2)
					mov [velocity], ax
					
					cmp ax, maxVelocity 
					jle afterLeftClickReleasedCheck
					
					;set velocity for normal physics
					mov bx,maxVelocity
					
					mov ax, [velX]
					imul bx
					idiv [velocity]
					mov [velX],ax
					
					mov ax, [velY]
					imul bx
					idiv [velocity]
					mov [velY],ax
					
					inc [released]
					strChange 
					call hideMouse	
					call releaseNote	
					
					afterLeftClickReleasedCheck:
						mov [mouseDown], 0
						mov [word ptr color],15
				
					
				afterMouseCheck: ; if the mouse was clicked we move the ball, for the first time.
					; move ball
					call deleteBall
					push [word ptr velX]
					call pow2
					pop bx ;taking ax as bx
					push [word ptr velY] 
					call pow2 
					pop ax
					add ax,bx
					push ax
					call sqrt
					
					pop ax ; getting the velocity
					cmp ax,frictionFactor
					jle stopBall
					
					mov [velocity] , ax
					sub ax, frictionFactor
					
					push ax ; keeping the old velocity for the x calc
					imul [word ptr velX]
					idiv [word ptr velocity]
					mov [velX], ax
					pop ax
					
					imul [word ptr velY]
					idiv [word ptr velocity]
					mov [velY], ax
					jmp moveBall
					
					stopBall:
						mov [velX],0
						mov [velY],0
						call showMouse
						
					moveBall:
						; wall check
						mov [word ptr hitWallGeneral] ,0 
						cmp [pointY],165
						jge reflectPositionOnLowerWall
						
					notReflectPositionOnLowerWall: 
							
						cmp [pointY], 5
						jle reflectPositionOnUpperWall
							
					notReflectPositionOnUpperWall:
					
						cmp [pointX], 315 
						jge reflectPositionOnRightWall
					
					notReflectPositionOnRightWall:
					
						cmp [pointX],5
						jle reflectPositionOnLeftWall
						
					afterHit: 
							
						mov bx,[word ptr hitWallGeneral]
						mov [word ptr hitWall] ,bx
						
						mov bx, [velX]
						add bx, [pointX]
						mov [pointX], bx
							
						mov bx, [velY] 
						add bx, [pointY]
						mov [pointY], bx
						
						; checking if the ball is inside the hole
						call checkBall
						; checking if thee ball is inside the hole
						reflectPositionOnLowerWall:
							mov [word ptr hitWallGeneral], 1
							cmp [word ptr hitWall], 1
							je notReflectPositionOnLowerWall
							;the length of the normal vector of W1 - 20
							push 20 ; N_Y
							push 0 ; N_X
							push [word ptr velY]
							push [word ptr velX]
							
							;pushing the components of two vectors
							call vectorMultiplication
							pop ax
							
							shl ax,1
							
							;newVelY
							push [word ptr velY]
							mov bx,20
							imul bx
							mov bx,ax
							push 20
							call pow2 
							pop ax 
							xchg bx,ax; switchs betweem the registers
							idiv bx
							sub [velY],ax
							mov bx,[velY]
							mov [newVelY],bx
							;getting the reflection Y value
							
							mov bx, [pointX]
							add bx, [VelX]
							mov [pointX], bx
						
							mov bx, [pointY] 
							add bx, [newVelY]
							mov [pointY], bx
							
							jmp afterHit
						reflectPositionOnUpperWall:
							mov [word ptr hitWallGeneral], 1
							cmp [word ptr hitWall], 1
							je notReflectPositionOnUpperWall
							push 20 ; N_Y
							push 0 ; N_X
							push [word ptr velY]
							push [word ptr velX]
							
							;pushing the components of two vectors
							call vectorMultiplication
							pop ax
							shl ax,1
							
							;newVelY
							;push [word ptr velY]
							mov bx,20
							imul bx
							mov bx,ax
							push 20
							call pow2 
							pop ax 
							xchg bx,ax; switchs betweem the registers
							idiv bx
							sub [velY],ax
							mov bx,[velY]
							mov [newVelY],bx
							
							mov bx, [pointX]
							add bx, [VelX]
							mov [pointX], bx
						
							mov bx, [pointY] 
							add bx, [newVelY]
							mov [pointY], bx
							
							jmp afterHit
						reflectPositionOnRightWall:
							mov [word ptr hitWallGeneral], 1
							cmp [word ptr hitWall], 1
							je notReflectPositionOnRightWall
							push 0 ; N_Y
							push 20 ; N_X
							push [word ptr velY]
							push [word ptr velX]
							
							;pushing the components of two vectors
							call vectorMultiplication
							pop ax
							shl ax,1
							
							;newVelX
							;push [word ptr velY]
							mov bx,20
							imul bx
							mov bx,ax
							push 20
							call pow2 
							pop ax 
							xchg bx,ax; switchs betweem the registers
							idiv bx
							sub [velX],ax
							mov bx,[velX]
							mov [newVelX],bx
							
							mov bx, [pointX]
							add bx, [newVelX]
							mov [pointX], bx
						
							mov bx, [pointY] 
							add bx, [velY]
							mov [pointY], bx
							
							jmp afterHit
							
						reflectPositionOnLeftWall:
							mov [word ptr hitWallGeneral], 1
							cmp [word ptr hitWall], 1
							je afterHit
							push 0 ; N_Y
							push 20 ; N_X
							push [word ptr velY]
							push [word ptr velX]
							
							;pushing the components of two vectors
							call vectorMultiplication
							pop ax
							shl ax,1
							
							;newVelX
							;push [word ptr velY]
							mov bx,20
							imul bx
							mov bx,ax
							push 20
							call pow2 
							pop ax 
							xchg bx,ax; switchs between the registers
							idiv bx
							sub [velX],ax
							mov bx,[velX]
							mov [newVelX],bx
							
							mov bx, [pointX]
							add bx, [newVelX]
							mov [pointX], bx
						
							mov bx, [pointY] 
							add bx, [velY]
							mov [pointY], bx
							 
							jmp afterHit
					nextFrame:
						call clearingRec
						call drawball
						call delay_ball
						jmp gameLoop
						pop ax
	rules: ; r was pressed
		call rules_screen
		mov ah,1h ; getting the keyboard input
		int 21h
		cmp al,1Bh ; 'ESC'
		jz start
		jmp rules
		
	backMenu:
		;call delay_ball
		call back_menu_screen
		mov ah,1h
		int 21h 
		cmp al, 6Dh ; 'M'
		je menu

		cmp al,63h ; 'C'
		je startGame
		jmp backMenu
	
	exit: ; e was pressed
		call textMode
		mov dx, offset endMsg
		mov ah, 9h
		int 21h
		mov ax, 4c00h
		int 21h
endp initializeGame
start:
	mov ax, @data
	mov ds, ax
	;starting the game - Daniel Sapojnikov
	call initializeGame
END start