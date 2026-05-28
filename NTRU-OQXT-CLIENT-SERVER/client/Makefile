CC = g++
CFLAGS = -I. -I./blake3/
CONFIG = -O3 -std=c++17 -msse2 -msse -mssse3 -march=native -ffast-math -mavx2 -mfma -maes -lcryptopp -lpthread -lgmpxx -lssl -lhiredis -lredis++ -lcrypto -lntl -lgmp -lm -lrt -fpermissive -fopenmp -Wl,./blake3/libblake3.so,-rpath,/sealusers/user3/redis-plus-plus/build -Wl,-rpath,/usr/local/lib
LD = g++
LDFLAGS = #-pg -no-pie
LIBS = #-lm

oqxt-falcon_setup_client:  rawdatautil.cpp  bloom_filter.cpp AES_256GCM.c ./falcon-round3/Extra/c/shake.c ./falcon-round3/Extra/c/common.c ./falcon-round3/Extra/c/keygen.c ./falcon-round3/Extra/c/fft.c ./falcon-round3/Extra/c/fpr.c  ./falcon-round3/Extra/c/vrfy.c ./falcon-round3/Extra/c/codec.c ./falcon-round3/Extra/c/sign.c ./falcon-round3/Extra/c/rng.c oqxt-falcon_setup_client.cpp
	$(CC) -g -o oqxt-falcon_setup_client  rawdatautil.cpp  bloom_filter.cpp AES_256GCM.c ./falcon-round3/Extra/c/shake.c ./falcon-round3/Extra/c/common.c ./falcon-round3/Extra/c/keygen.c ./falcon-round3/Extra/c/fft.c ./falcon-round3/Extra/c/fpr.c ./falcon-round3/Extra/c/vrfy.c ./falcon-round3/Extra/c/codec.c ./falcon-round3/Extra/c/sign.c ./falcon-round3/Extra/c/rng.c ./blake3/blake_hash.cpp oqxt-falcon_setup_client.cpp  $(CONFIG)

oqxt-falcon_search_client:  rawdatautil.cpp  bloom_filter.cpp AES_256GCM.c ./falcon-round3/Extra/c/shake.c ./falcon-round3/Extra/c/common.c ./falcon-round3/Extra/c/keygen.c ./falcon-round3/Extra/c/fft.c ./falcon-round3/Extra/c/fpr.c  ./falcon-round3/Extra/c/vrfy.c ./falcon-round3/Extra/c/codec.c ./falcon-round3/Extra/c/sign.c ./falcon-round3/Extra/c/rng.c oqxt-falcon_search_client.cpp
	$(CC) -g -o oqxt-falcon_search_client  rawdatautil.cpp  bloom_filter.cpp AES_256GCM.c ./falcon-round3/Extra/c/shake.c ./falcon-round3/Extra/c/common.c ./falcon-round3/Extra/c/keygen.c ./falcon-round3/Extra/c/fft.c ./falcon-round3/Extra/c/fpr.c ./falcon-round3/Extra/c/vrfy.c ./falcon-round3/Extra/c/codec.c ./falcon-round3/Extra/c/sign.c ./falcon-round3/Extra/c/rng.c ./blake3/blake_hash.cpp oqxt-falcon_search_client.cpp  $(CONFIG)


test: check_NTT.cpp check_NTT_bkp.cpp
	$(CC) -g -o test check_NTT.cpp -lntl
	$(CC) -g -o test_bkp check_NTT_bkp.cpp -lntl

clean_all:
	rm -rf *.o setup *.gch oqxt-falcon_setup_client oqxt-falcon_search_client EDB_test.csv bloom_filter.dat
	@redis-cli flushall
	@redis-cli save
