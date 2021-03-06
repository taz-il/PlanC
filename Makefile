.PHONY: all clean release

SOURCE = planc.cpp adb.cpp common.cpp backup.cpp blocks.cpp crypto.cpp
SUBMODULES = cryptopp/Readme.txt zstr/README.org zlib/README boost/README.md leveldb/README.md snappy/README.md
BOOST_LIBS = boost/stage/lib/libboost_iostreams.a boost/stage/lib/libboost_program_options.a boost/stage/lib/libboost_filesystem.a boost/stage/lib/libboost_system.a boost/stage/lib/libboost_date_time.a
STATIC_LIBS = leveldb/out-static/libleveldb.a cryptopp/libcryptopp.a snappy/libsnappy.a $(BOOST_LIBS) zlib/libz.a
all : plan-c

# Remove these options if you don't need a static build:
STATIC_OPTIONS = # -static -static-libgcc -static-libstdc++

ZLIB_PATH = $(abspath zlib)

$(SUBMODULES) :
	git submodule update --init

cryptopp/libcryptopp.a :
	cd cryptopp && make

leveldb/out-static/libleveldb.a :
	cd leveldb && make

snappy/libsnappy.a :
	cd snappy && cmake . && make

zlib/libz.a :
	cd zlib && ./configure && make

boost/boost/ :
	cd boost && git submodule update --init && ./bootstrap.sh
	cd boost && ./b2 headers

$(BOOST_LIBS) : boost/boost/ zlib/libz.a
	echo "using zlib : 1.2.11 : <include>$(ZLIB_PATH) <search>$(ZLIB_PATH) <name>libz ;" > project-config.jam
	cd boost && ./b2 stage --with-program_options --with-filesystem --with-iostreams --with-date_time --with-system -s NO_BZIP2=1

release : plan-c
	gpg2 --local-user "n.sherlock@gmail.com" --detach-sign -o plan-c.sig plan-c
	tar -zcf plan-c.tar.gz plan-c plan-c.sig

plan-c : $(SOURCE) $(SUBMODULES) $(STATIC_LIBS) boost/boost/
	$(CXX) $(STATIC_OPTIONS) -Wall --std=c++11 -O3 -g3 -o $@ -Iboost -Ileveldb/include -Izlib $(SOURCE) $(STATIC_LIBS) -lpthread

clean :
	rm -f plan-c
