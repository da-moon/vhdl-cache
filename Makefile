# OS specific part
# -----------------
ifeq ($(OS),Windows_NT)
    CLEAR = cls
    LS = dir
    TOUCH =>>
    RM = del /F /Q
    CPF = copy /y
    RMDIR = -RMDIR /S /Q
    MKDIR = -mkdir
    CMDSEP = &
    ERRIGNORE = 2>NUL || (exit 0)
    SEP=\\
else
    CLEAR = clear
    LS = ls
    TOUCH = touch
    CPF = cp -f
    RM = rm -rf
    RMDIR = rm -rf
    CMDSEP = ;
    MKDIR = mkdir -p
    ERRIGNORE = 2>/dev/null
    SEP=/
endif

GHDLC=ghdl
VCDFILE=out.vcd
FLAGS=--warn-error --work=work 
TB_OPTION=--assert-level=error

VHDS=$(addsuffix .vhd, ${MODULES})
TESTS=$(addsuffix _test, ${MODULES})
VHDLS=$(addsuffix .vhdl, $(TESTS))
PACKAGES = cache_primitives.vhd
MODULES= mux2 mux8 cache_decoder 
.PHONY: all clean pre-build build

clean:
	- $(CLEAR)
	- $(RM) work-obj93.cf *.o *.vcd

pre-build: clean
	- $(CLEAR)
	- $(GHDLC) -a --std=00 $(FLAGS) ${PACKAGES} $(VHDS) cache.vhd
	- $(GHDLC) -a --std=00 $(FLAGS) $(VHDLS) 

build: pre-build
	for target in $(TESTS); do \
			$(GHDLC) -e $(FLAGS) $$target && \
			$(GHDLC) -r $(FLAGS) $$target; \
	done




