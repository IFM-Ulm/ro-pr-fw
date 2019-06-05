
COMPILER=
ARCHIVER=
CP=cp
COMPILER_FLAGS=
EXTRA_COMPILER_FLAGS=
LIB=libah.a

ifeq ($(notdir $(COMPILER)) , iccarm)
	EXTRA_ARCHIVE_FLAGS=--create
else
ifeq ($(notdir $(COMPILER)) , armcc)
	EXTRA_ARCHIVE_FLAGS=--create
else
	EXTRA_ARCHIVE_FLAGS=rc
endif
endif

RELEASEDIR=../../../lib
INCLUDEDIR=../../../include
INCLUDES=-I./. -I${INCLUDEDIR}

AHLIB_DIR = .
OUTS = *.o
OBJECTS =	$(addsuffix .o, $(basename $(wildcard *.c)))
AH_SRCS := $(wildcard *.c)
AH_OBJS = $(addprefix $(AHLIB_DIR)/, $(AH_SRCS:%.c=%.o))

INCLUDEFILES=$(AHLIB_DIR)/include/ah_gpio.h \
			$(AHLIB_DIR)/include/ah_scugic.h \
			$(AHLIB_DIR)/include/ah_tcpip.h \
			$(AHLIB_DIR)/include/ah_timer.h \
			$(AHLIB_DIR)/include/ah_pcap.h \
			$(AHLIB_DIR)/include/ah_sd.h \
			$(AHLIB_DIR)/include/ah_xadc.h \
			$(AHLIB_DIR)/include/ah_pmod.h \
			$(AHLIB_DIR)/include/ah_amp.h \
			$(AHLIB_DIR)/include/ah_uart.h

libs: print_msg_ahlib $(AH_OBJS)
	$(ARCHIVER) $(EXTRA_ARCHIVE_FLAGS) ${RELEASEDIR}/${LIB} ${AH_OBJS}

print_msg_ahlib:
	@echo "Compiling AH Library"

.PHONY: include
include: libah_includes

libah_includes:
	${CP} ${INCLUDEFILES} ${INCLUDEDIR}

object_clean:
	rm -rf $(AHLIB_DIR)/${OBJECTS}
	
clean:
	rm -rf $(AHLIB_DIR)/${OBJECTS}
	rm -rf ${RELEASEDIR}/${LIB}

$(AHLIB_DIR)/%.o: $(AHLIB_DIR)/%.c $(INCLUDEFILES)
	$(COMPILER) $(COMPILER_FLAGS) $(EXTRA_COMPILER_FLAGS) $(INCLUDES) -c $< -o $@
