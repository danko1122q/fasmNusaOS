; flat assembler interface for nusaOS
; Ported from Unix/libc interface by danko1122q
; Copyright (c) 1999-2022, Tomasz Grysztar.
; All rights reserved.

format ELF
public main

macro ccall proc,[arg]
  { common
     local size
     size = 0
     mov ebp,esp
     if ~ arg eq
    forward
     size = size + 4
    common
     sub esp,size
     end if
     and esp,-16
     if ~ arg eq
     add esp,size
    reverse
     push dword arg
    common
     end if
     call proc
     mov esp,ebp }

extrn gettimeofday

include '../VERSION.INC'

section '.text' executable align 16

main:
        mov     ecx,[esp+4]
        mov     [argc],ecx
        mov     ebx,[esp+8]
        mov     [argv],ebx
        push    ebp
        mov     [stack_frame],esp

        mov     [con_handle],1
        mov     esi,_logo
        call    display_string

        call    get_params
        jc      information

        call    init_memory

        mov     esi,_memory_prefix
        call    display_string
        mov     eax,[memory_end]
        sub     eax,[memory_start]
        add     eax,[additional_memory_end]
        sub     eax,[additional_memory]
        shr     eax,10
        call    display_number
        mov     esi,_memory_suffix
        call    display_string

        ccall   gettimeofday,buffer,0
        mov     eax,dword [buffer]
        mov     ecx,1000
        mul     ecx
        mov     ebx,eax
        mov     eax,dword [buffer+4]
        div     ecx
        add     eax,ebx
        mov     [start_time],eax

        and     [preprocessing_done],0
        call    preprocessor
        or      [preprocessing_done],-1
        call    parser
        call    assembler
        call    formatter

        call    display_user_messages
        movzx   eax,[current_pass]
        inc     eax
        call    display_number
        mov     esi,_passes_suffix
        call    display_string
        ccall   gettimeofday,buffer,0
        mov     eax,dword [buffer]
        mov     ecx,1000
        mul     ecx
        mov     ebx,eax
        mov     eax,dword [buffer+4]
        div     ecx
        add     eax,ebx
        sub     eax,[start_time]
        jnc     time_ok
        add     eax,3600000
      time_ok:
        xor     edx,edx
        mov     ebx,100
        div     ebx
        or      eax,eax
        jz      display_bytes_count
        xor     edx,edx
        mov     ebx,10
        div     ebx
        push    edx
        call    display_number
        mov     dl,'.'
        call    display_character
        pop     eax
        call    display_number
        mov     esi,_seconds_suffix
        call    display_string
      display_bytes_count:
        mov     eax,[written_size]
        call    display_number
        mov     esi,_bytes_suffix
        call    display_string
        xor     al,al
        jmp     exit_program

information:
        mov     esi,_usage
        call    display_string
        mov     al,1
        jmp     exit_program

get_params:
        mov     [input_file],0
        mov     [output_file],0
        mov     [symbols_file],0
        mov     [memory_setting],0
        mov     [passes_limit],100

        mov     ecx,[argc]
        mov     ebx,[argv]
        add     ebx,4
        dec     ecx
        jz      bad_params
        mov     [definitions_pointer],predefinitions
      get_param:
        mov     esi,[ebx]
        mov     al,[esi]
        cmp     al,'-'
        je      option_param
        cmp     [input_file],0
        jne     get_output_file
        mov     [input_file],esi
        jmp     next_param
      get_output_file:
        cmp     [output_file],0
        jne     bad_params
        mov     [output_file],esi
        jmp     next_param
      option_param:
        inc     esi
        lodsb
        cmp     al,'m'
        je      memory_option
        cmp     al,'M'
        je      memory_option
        cmp     al,'p'
        je      passes_option
        cmp     al,'P'
        je      passes_option
        cmp     al,'d'
        je      definition_option
        cmp     al,'D'
        je      definition_option
        cmp     al,'s'
        je      symbols_option
        cmp     al,'S'
        je      symbols_option
        jmp     bad_params
      memory_option:
        lodsb
        or      al,al
        jz      get_memory_option
        cmp     al,' '
        je      get_memory_option
        jmp     bad_params
      get_memory_option:
        add     ebx,4
        dec     ecx
        jz      bad_params
        mov     esi,[ebx]
        xor     eax,eax
        xor     edx,edx
      convert_memory_setting:
        lodsb
        or      al,al
        jz      memory_option_ok
        sub     al,'0'
        jc      bad_params
        cmp     al,9
        ja      bad_params
        imul    edx,10
        add     edx,eax
        jmp     convert_memory_setting
      memory_option_ok:
        mov     [memory_setting],edx
        jmp     next_param
      passes_option:
        lodsb
        or      al,al
        jz      get_passes_option
        cmp     al,' '
        je      get_passes_option
        jmp     bad_params
      get_passes_option:
        add     ebx,4
        dec     ecx
        jz      bad_params
        mov     esi,[ebx]
        xor     eax,eax
        xor     edx,edx
      convert_passes_setting:
        lodsb
        or      al,al
        jz      passes_option_ok
        sub     al,'0'
        jc      bad_params
        cmp     al,9
        ja      bad_params
        imul    edx,10
        add     edx,eax
        jmp     convert_passes_setting
      passes_option_ok:
        mov     [passes_limit],dx
        jmp     next_param
      definition_option:
        lodsb
        or      al,al
        jz      get_definition_option
        cmp     al,' '
        je      get_definition_option
        jmp     bad_params
      get_definition_option:
        add     ebx,4
        dec     ecx
        jz      bad_params
        mov     esi,[ebx]
        mov     edi,[definitions_pointer]
        push    ecx ebx
      copy_definition:
        lodsb
        stosb
        or      al,al
        jnz     copy_definition
        pop     ebx ecx
        mov     [definitions_pointer],edi
        jmp     next_param
      symbols_option:
        lodsb
        or      al,al
        jz      get_symbols_option
        cmp     al,' '
        je      get_symbols_option
        jmp     bad_params
      get_symbols_option:
        add     ebx,4
        dec     ecx
        jz      bad_params
        mov     esi,[ebx]
        mov     [symbols_file],esi
        jmp     next_param
      bad_params:
        stc
        ret
      next_param:
        add     ebx,4
        dec     ecx
        jnz     get_param
        cmp     [input_file],0
        je      bad_params
        clc
        ret

_copyright db 'Copyright (c) 1999-2022, Tomasz Grysztar',0xA,0

_logo db 'flat assembler  version ',VERSION_STRING,' (nusaOS)',0xA,0
_usage db 0xA
       db 'usage: fasm <source> [output]',0xA
       db 'optional settings:',0xA
       db ' -m <limit>         set the limit in kilobytes for the available memory',0xA
       db ' -p <limit>         set the maximum allowed number of passes',0xA
       db ' -d <name>=<value>  define symbolic variable',0xA
       db ' -s <file>          dump symbolic information for debugging',0xA
       db 0
_memory_prefix db '  (',0
_memory_suffix db ' kilobytes memory)',0xA,0
_passes_suffix db ' passes, ',0
_seconds_suffix db ' seconds, ',0
_bytes_suffix db ' bytes.',0xA,0

include '../ERRORS.INC'
include '../SYMBDUMP.INC'
include '../PREPROCE.INC'
include '../PARSER.INC'
include '../EXPRPARS.INC'
include '../ASSEMBLE.INC'
include '../EXPRCALC.INC'
include '../FORMATS.INC'
include '../X86_64.INC'
include '../AVX.INC'

include '../TABLES.INC'
include '../MESSAGES.INC'

include 'SYSTEM.INC'

section '.bss' writeable align 4

include '../VARIABLE.INC'

argc                dd ?
argv                dd ?
stack_frame         dd ?
memory_setting      dd ?
definitions_pointer dd ?
start_time          dd ?
timestamp           dq ?
con_handle          dd ?
displayed_count     dd ?
last_displayed      db ?
character           db ?
preprocessing_done  db ?

predefinitions rb 1000h
buffer         rb 1000h
