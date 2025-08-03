# Minimal Makefile (no install)
CXX       := g++
CXXFLAGS  := -std=c++17 -O2 -fPIC -Wall -Wextra -DKXVER=3 -Ic
LDFLAGS   := -shared
LDLIBS    := -lcrypto

TARGET    := authcrypto.so
SRCDIR    := src
SRCS      := $(SRCDIR)/tokenverify.cpp $(SRCDIR)/b64decode.cpp
OBJS      := $(SRCS:.cpp=.o)

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)
	rm -f $(OBJS)

$(SRCDIR)/%.o: $(SRCDIR)/%.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)

