TWEETS_FOLDER="tweets"
UNAME_S := $(shell uname -s)
ENTRY_POINT=main.ozf

ifeq ($(UNAME_S),Darwin)
	OZC = /Applications/Mozart2.app/Contents/Resources/bin/ozc
	OZENGINE = /Applications/Mozart2.app/Contents/Resources/bin/ozengine
else
	OZC = ozc
	OZENGINE = ozengine
endif

all : $(ENTRY_POINT)

%.ozf: %.oz
	$(OZC) -c $< -o "$@"

run: $(ENTRY_POINT)
	$(OZENGINE) $(ENTRY_POINT) --folder $(TWEETS_FOLDER)

clean :
	rm -f *.ozf

test: $(ENTRY_POINT)
	$(OZENGINE) $(ENTRY_POINT) --folder test_folder

extension: main_ext.ozf
	$(OZENGINE) main_ext.ozf --folder test_folder

auto_complete: main_auto_complete.ozf
	$(OZENGINE) main_auto_complete.ozf --folder test_folder

generalization: main_generalization.ozf
	$(OZENGINE) main_generalization.ozf --folder $(TWEETS_FOLDER)

add: add_file.ozf
	$(OZENGINE) add_file.ozf --folder $(TWEETS_FOLDER)

improve: main_improve.ozf
	$(OZENGINE) main_improve.ozf --folder $(TWEETS_FOLDER)
