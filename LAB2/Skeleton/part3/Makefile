PROG=main
RM=rm -f

.PHONY: all clean

all: $(PROG).adb
	@gnatmake $(PROG).adb -o $(PROG)
	./$(PROG)
	
clean:
	$(RM) $(PROG)
	$(RM) *.o *.ali