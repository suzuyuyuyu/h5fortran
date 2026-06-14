#define CHECK_SHAPE_AND_COPY(mode, tmp, array) \
    if (any(shape(tmp) /= shape(array))) then; \
      write(*,*) "[h5fort/mode/read_fixed] ERROR: shape mismatch: dataset=", shape(tmp), " array=", shape(array); \
      hdferr = -1; return; \
    end if; \
    array = tmp
