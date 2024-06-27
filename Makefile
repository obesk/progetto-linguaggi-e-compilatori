.PHONY: clean all

LLVM_CONFIG = llvm-config-17
LLVM_CXXFLAGS = -I/usr/lib/llvm-17/include -std=c++17 -funwind-tables -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS
LLVM_LDFLAGS = -L/usr/lib/llvm-17/lib -lLLVM-17

all: kcomp

kcomp: driver.o parser.o scanner.o kcomp.o
	clang++ -o kcomp driver.o parser.o scanner.o kcomp.o $(LLVM_LDFLAGS)

kcomp.o: kcomp.cpp
	clang++ -c kcomp.cpp $(LLVM_CXXFLAGS)

parser.o: parser.cpp
	clang++ -c parser.cpp $(LLVM_CXXFLAGS)

scanner.o: scanner.cpp parser.hpp
	clang++ -c scanner.cpp $(LLVM_CXXFLAGS)

driver.o: driver.cpp parser.hpp driver.hpp
	clang++ -c driver.cpp $(LLVM_CXXFLAGS)

parser.cpp parser.hpp: parser.yy
	bison -o parser.cpp parser.yy

scanner.cpp: scanner.ll
	flex -o scanner.cpp scanner.ll

clean:
	rm -f *~ *.o kcomp scanner.cpp parser.cpp parser.hpp

