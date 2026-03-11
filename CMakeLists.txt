find_program(FASM_HOST_EXECUTABLE fasm)

if(NOT FASM_HOST_EXECUTABLE)
    message(WARNING "Host 'fasm' binary not found - skipping fasm build. Install fasm on the build host to enable it.")
    return()
endif()

set(FASM_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/SOURCE)
set(FASM_ENTRY     ${FASM_SOURCE_DIR}/NUSAOS/FASM.ASM)
set(FASM_OBJECT    ${CMAKE_CURRENT_BINARY_DIR}/fasm_asm.o)

file(GLOB_RECURSE FASM_INC_FILES
    ${FASM_SOURCE_DIR}/*.INC
    ${FASM_SOURCE_DIR}/*.inc
)

# Step 1: Assemble FASM source → ELF32 relocatable object using host fasm binary
add_custom_command(
    OUTPUT  ${FASM_OBJECT}
    COMMAND ${FASM_HOST_EXECUTABLE} ${FASM_ENTRY} ${FASM_OBJECT}
    DEPENDS ${FASM_ENTRY} ${FASM_INC_FILES}
    COMMENT "Assembling fasm for nusaOS (${FASM_HOST_EXECUTABLE})"
    VERBATIM
)

# Mark the pre-assembled object as external (don't try to compile it again)
set_source_files_properties(${FASM_OBJECT} PROPERTIES
    EXTERNAL_OBJECT TRUE
    GENERATED       TRUE
)

# Step 2: Link using CMake's normal mechanism so it respects the toolchain sysroot.
# stub.c gives CMake a C-language context (so it picks the right cross-linker).
# fasm_asm.o provides main() and all the assembler code.
add_executable(fasm
    ${CMAKE_CURRENT_SOURCE_DIR}/stub.c
    ${FASM_OBJECT}
)

# Wait for libc to be built + copied into the sysroot before linking
add_dependencies(fasm libc)

install(TARGETS fasm RUNTIME DESTINATION bin)
