CXX=clang++
CXXFLAGS=-Wall -Wextra -Werror --std=c++20
CPPFLAGS=-I./opt/include
LDFLAGS=-L./opt/lib
LDLIBS=-lspot
TARGET=equivltl

all:
	${CXX} ${CXXFLAGS} ${CPPFLAGS} ${LDFLAGS} ${LDLIBS} main.cpp \
		-o bin/${TARGET}


.PHONY: all
