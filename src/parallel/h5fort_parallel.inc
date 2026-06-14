#if !defined MAX_RANK
#define MAX_RANK 4
#endif

#if MAX_RANK < 1
#error "MAX_RANK must be defined as a positive integer, e.g. -DMAX_RANK=4"
#endif
