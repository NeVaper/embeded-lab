cmake_minimum_required(VERSION 3.7)
SET(CMAKE_SYSTEM_NAME Generic)
SET(CMAKE_SYSTEM_VERSION 1)

# Enable logging messages
#set(CMAKE_VERBOSE_MAKEFILE ON)

# Project name
set(PROJECT_NAME FixtureTACO)
PROJECT(${PROJECT_NAME} C CXX ASM)
SET(CMAKE_CXX_STANDARD 17)

###################### CHIP CONFIGURATION ##########################
SET(ROOT_PROJ   ${CMAKE_CURRENT_SOURCE_DIR})
SET(CPU         "cortex-m4")
SET(ARCH_NAME   "arm")
SET(ARCH_VER    "v7e-m")
SET(FAMILY      "stm32f3")
SET(CHIP        "STM32F303xC")
SET(ARCH        "${ARCH_NAME}${ARCH_VER}")
####################################################################

# MCU Config
set(FPU         "-mfpu=fpv4-sp-d16")
set(FLOAT_ABI   "-mfloat-abi=hard")

# Toolchain path
set(TOOLCHAIN_PATH  "/usr/bin/")
set(ARM_LIB         "/usr/lib/arm-none-eabi/lib/${ARCH}")
# Specify C, C++ and ASM compilers
SET(CMAKE_C_COMPILER    ${TOOLCHAIN_PATH}arm-none-eabi-gcc)
SET(CMAKE_CXX_COMPILER  ${TOOLCHAIN_PATH}arm-none-eabi-g++)
set(CMAKE_ASM_COMPILER  ${TOOLCHAIN_PATH}arm-none-eabi-gcc)
set(AR                  ${TOOLCHAIN_PATH}arm-none-eabi-ar)
set(OBJCOPY             ${TOOLCHAIN_PATH}arm-none-eabi-objcopy)
set(OBJDUMP             ${TOOLCHAIN_PATH}arm-none-eabi-objdump)
set(SIZE                ${TOOLCHAIN_PATH}arm-none-eabi-size)
set(GDB                 ${TOOLCHAIN_PATH}arm-none-eabi-gdb)
set(SIZE                ${TOOLCHAIN_PATH}arm-none-eabi-size)

# Definitions passed at compile time (#defines)
add_definitions(-DFAMILY=${FAMILY})
add_definitions(-DCHIP=${CHIP})
add_definitions(-D${CHIP})
add_definitions(-DUSE_FULL_LL_DRIVER)
add_definitions(-USE_HAL_DRIVER)
add_definitions(-DHSE_VALUE=8000000)
add_definitions(-DHSE_STARTUP_TIMEOUT=100)
add_definitions(-DLSE_STARTUP_TIMEOUT=5000)
add_definitions(-DLSE_VALUE=32768)
add_definitions(-DHSI_VALUE=8000000)
add_definitions(-DLSI_VALUE=40000)
add_definitions(-DDD_VALUE=3300)
add_definitions(-DPREFETCH_ENABLE=1)

# Compilation flags
add_compile_options(-mcpu=${CPU})
add_compile_options(-march=${ARCH})
add_compile_options(-mthumb)
add_compile_options(${FPU})
add_compile_options(${FLOAT_ABI})
add_compile_options(-Og)
add_compile_options(-Wall)
add_compile_options(-fdata-sections)
add_compile_options(-ffunction-sections)
# Only for debugging
add_compile_options(-g -gdwarf-2)


# Linker script path
file(GLOB_RECURSE LINKER_SCRIPT ${ROOT_PROJ}/src/*.ld)

# Variables initialized first time
SET(CMAKE_CXX_FLAGS_INIT "-std=c++11")
SET(CMAKE_C_FLAGS_INIT "-std=gnu99")

################################## Source code ###############################################################
file(GLOB SOURCES 
  "3rd/CMSIS/*.c" 
  "3rd/CMSIS/*.cpp" 
  "3rd/CMSIS/*.s"
  "3rd/SPL/src/*.c"
  "src/*.c"
  "src/*.cpp"
  "src/*.s")

#Retrieve all locations of headers
file(GLOB_RECURSE HEADERS
  "3rd/SPL/inc/*.h"
  "3rd/CMSIS/Include/*.h"
  "src/*.h"
  "3rd/*.h"
  "3rd/CMSIS/Device/ST/STM32F30x/Include/*.h")

set (INCLUDE_DIRS "")
foreach (_headerFile ${HEADERS})
    get_filename_component(_dir ${_headerFile} PATH)
    list (APPEND INCLUDE_DIRS ${_dir})
endforeach()
list(REMOVE_DUPLICATES INCLUDE_DIRS)
include_directories(${INCLUDE_DIRS})
link_directories(${ARM_LIB})
################################## Source code END ###########################################################

set(EXE_NAME "firmware")
add_executable(${EXE_NAME}.elf ${SOURCES} ${LINKER_SCRIPT})
set(CMAKE_EXE_LINKER_FLAGS "-mcpu=${CPU} -mthumb ${FPU} ${FLOAT_ABI} --specs=nano.specs -T${LINKER_SCRIPT} -Wl,-Map=${PROJECT_BINARY_DIR}/${PROJECT_NAME}.map,--cref -Wl,--gc-sections")

# Libs and external dependencies
target_link_libraries(${EXE_NAME}.elf -lc -lm -lnosys)

# Outputs
set(ELF_FILE ${PROJECT_BINARY_DIR}/${EXE_NAME}.elf)
set(HEX_FILE ${PROJECT_BINARY_DIR}/${EXE_NAME}.hex)
set(BIN_FILE ${PROJECT_BINARY_DIR}/${EXE_NAME}.bin)

add_custom_command(TARGET "${EXE_NAME}.elf" POST_BUILD
        # Build .hex and .bin files
        COMMAND ${OBJCOPY} -Obinary ${ELF_FILE} ${BIN_FILE}
        COMMAND ${OBJCOPY} -Oihex  ${ELF_FILE} ${HEX_FILE}
        COMMENT "Building ${PROJECT_NAME}.bin and ${PROJECT_NAME}.hex"

        # Display sizes
        COMMAND ${SIZE} --format=berkeley ${EXE_NAME}.elf ${EXE_NAME}.hex
        COMMENT "Invoking: Cross ARM GNU Print Size"
        )