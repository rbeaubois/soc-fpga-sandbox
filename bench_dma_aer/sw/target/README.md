# C++ Software Layer

To reuse as template:
* Rename `BENCHDMAAER` by `YOURAPPNAME` (Case sensitive 'Find and Replace')
* Rename `bench_dma_aer` by `your_app_name` (Case sensitive 'Find and Replace' and _ separated)
* Rename firmware folders `bench_dma_aer` by `your_app_name`
* Update `launch_app.sh` and `run.sh`
* Rename `bench_dma_aer.cpp` and `bench_dma_aer.h`
* Update application args parser `app/src/swconfig/ArgParse.cpp`
* Update software configuration parser `app/src/swconfig/SwConfigParser.cpp`